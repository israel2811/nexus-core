#!/usr/bin/env python3
import hashlib, json, os, threading, time, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path, PureWindowsPath
from urllib.parse import parse_qs, urlparse

STATE = Path('/var/lib/nexus-offload/state.json')
JOBS = Path('/var/lib/nexus-offload/jobs')
TOKEN_FILE = Path('/etc/nexus-offload.token')
WINDOWS_HOME = Path(os.environ.get('NEXUS_WINDOWS_HOME', '/mnt/windows-home'))
WIN_PROFILE = os.environ.get('NEXUS_WINDOWS_PROFILE', 'Dell')
BIND = os.environ.get('NEXUS_BROKER_BIND', '127.0.0.1')
PORT = int(os.environ.get('NEXUS_BROKER_PORT', '8765'))
ALLOWED_KINDS = {'repo-inventory', 'hash-tree', 'source-search', 'health-snapshot'}
MAX_JOB_SECONDS = int(os.environ.get('NEXUS_MAX_JOB_SECONDS', '12'))
MAX_FILES = int(os.environ.get('NEXUS_MAX_FILES', '1200'))
JOB_SLOTS = threading.BoundedSemaphore(1)
SENSITIVE_PARTS = {'.ssh', 'secrets', 'credentials', 'cookies', 'login data', 'user data', '.config', '.aws', '.azure', '.gnupg', '.kube'}
SENSITIVE_FILES = {'.env', 'auth.json', 'credentials.db', 'access_tokens.db', 'application_default_credentials.json', 'token', 'tokens.json', 'login data', 'cookies'}
state = {'mode': 'automatic', 'version': 5, 'windows_polling': False, 'started': None, 'last_job': None}

def now(): return time.strftime('%Y-%m-%dT%H:%M:%S%z')
def token():
    try: return TOKEN_FILE.read_text().strip()
    except Exception: return ''
def persist_state():
    STATE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE.with_suffix('.tmp'); tmp.write_text(json.dumps(state, indent=2)); os.replace(tmp, STATE)
def job_path(job_id): return JOBS / f'{job_id}.json'
def save_job(job):
    JOBS.mkdir(parents=True, exist_ok=True)
    tmp = JOBS / f"{job['id']}.tmp"; tmp.write_text(json.dumps(job, indent=2)); os.replace(tmp, job_path(job['id']))

def choose(task):
    t = str(task).lower()
    if any(x in t for x in ('gpu','ml','embedding','spectrogram','large-data')): return 'gpu-cloud'
    if any(x in t for x in ('build','test','lint','npm','compile')): return 'github-actions-or-codespace'
    if any(x in t for x in ('scrape','browser-automation','crawl')): return 'remote-browser'
    if any(x in t for x in ('inventory','hash-tree','source-search','large-repo-read')): return 'linux-worker'
    return 'local'

def windows_path_to_local(value):
    p = PureWindowsPath(str(value)); parts = p.parts
    if len(parts) < 3 or p.drive.upper() != 'C:' or parts[1].lower() != 'users' or parts[2].lower() != WIN_PROFILE.lower():
        raise ValueError(f'path must be under C:\\Users\\{WIN_PROFILE}')
    local = WINDOWS_HOME.joinpath(*parts[3:]); base = WINDOWS_HOME.resolve(); resolved = local.resolve()
    if os.path.commonpath([str(base), str(resolved)]) != str(base): raise ValueError('path escaped allowed root')
    lowered = {part.lower() for part in resolved.parts}
    if lowered & SENSITIVE_PARTS: raise ValueError('sensitive path is not eligible for automatic offload')
    return resolved

def iter_files(root, deadline):
    count = 0
    for base, dirs, files in os.walk(root):
        if time.monotonic() > deadline: return
        dirs[:] = [d for d in dirs if d.lower() not in {'.git','node_modules','.venv','__pycache__'} | SENSITIVE_PARTS]
        for name in files:
            if time.monotonic() > deadline or count >= MAX_FILES: return
            if name.lower() in SENSITIVE_FILES or name.lower().startswith('.env.'): continue
            path = Path(base) / name
            try:
                if path.is_file(): count += 1; yield path
            except OSError: continue

def do_inventory(root, deadline):
    total = 0; rows = []
    for path in iter_files(root, deadline):
        try: size = path.stat().st_size
        except OSError: continue
        total += size; rows.append((size, str(path.relative_to(root))))
    rows.sort(reverse=True)
    return {'files':len(rows),'bytes':total,'largest':[{'path':p,'bytes':s} for s,p in rows[:50]]}

def do_hash_tree(root, deadline):
    items=[]; total=0
    for path in iter_files(root, deadline):
        try:
            size=path.stat().st_size
            if size > 32*1024*1024 or total+size > 512*1024*1024: continue
            h=hashlib.sha256()
            with path.open('rb') as f:
                for block in iter(lambda:f.read(1024*1024),b''):
                    if time.monotonic() > deadline: break
                    h.update(block)
            total += size; items.append({'path':str(path.relative_to(root)),'bytes':size,'sha256':h.hexdigest()})
        except (OSError,PermissionError): continue
    return {'files_hashed':len(items),'bytes_hashed':total,'items':items}

def do_source_search(root, query, deadline):
    needle=str(query)[:256].lower()
    if not needle: raise ValueError('query required')
    matches=[]
    for path in iter_files(root, deadline):
        try:
            if path.stat().st_size > 1024*1024: continue
            text=path.read_text(errors='ignore')
        except (OSError,UnicodeError): continue
        for line_no,line in enumerate(text.splitlines(),1):
            if needle in line.lower():
                matches.append({'path':str(path.relative_to(root)),'line':line_no,'text':line[:400]})
                if len(matches)>=100: return {'query':needle,'matches':matches,'truncated':True}
    return {'query':needle,'matches':matches,'truncated':False}

def execute_job(job):
    if not JOB_SLOTS.acquire(timeout=1):
        job.update(status='deferred-busy',finished=now()); save_job(job); return
    try:
        deadline=time.monotonic()+MAX_JOB_SECONDS; job.update(status='running',started=now()); save_job(job)
        if job['kind']=='health-snapshot': result={'state':state}
        else:
            root=windows_path_to_local(job['path'])
            if not root.exists(): raise FileNotFoundError(str(root))
            if job['kind']=='repo-inventory': result=do_inventory(root,deadline)
            elif job['kind']=='hash-tree': result=do_hash_tree(root,deadline)
            elif job['kind']=='source-search': result=do_source_search(root,job.get('query',''),deadline)
            else: raise ValueError('unsupported kind')
        job.update(result=result,status='completed',finished=now()); state['last_job']={'id':job['id'],'kind':job['kind'],'finished':job['finished']}; persist_state()
    except Exception as exc: job.update(status='failed',finished=now(),error=f'{type(exc).__name__}: {exc}'[:1000])
    finally: JOB_SLOTS.release(); save_job(job)

class Handler(BaseHTTPRequestHandler):
    def sendj(self,obj,code=200):
        body=json.dumps(obj,separators=(',',':')).encode(); self.send_response(code); self.send_header('Content-Type','application/json'); self.send_header('Cache-Control','no-store'); self.send_header('Content-Length',str(len(body))); self.end_headers(); self.wfile.write(body)
    def authorized(self): return bool(token()) and self.headers.get('X-Nexus-Key','') == token()
    def do_GET(self):
        u=urlparse(self.path)
        if u.path=='/health': return self.sendj({'ok':True,'mode':state['mode'],'version':state['version'],'windows_polling':False})
        if not self.authorized(): return self.sendj({'error':'unauthorized'},401)
        if u.path=='/state': return self.sendj(state)
        if u.path=='/route':
            task=parse_qs(u.query).get('task',[''])[0][:256]; return self.sendj({'task':task,'route':choose(task)})
        if u.path=='/job':
            job_id=parse_qs(u.query).get('id',[''])[0]
            if not job_id or '/' in job_id or '\\' in job_id: return self.sendj({'error':'invalid-job-id'},400)
            p=job_path(job_id)
            if not p.exists(): return self.sendj({'error':'not-found'},404)
            return self.sendj(json.loads(p.read_text()))
        return self.sendj({'error':'not-found'},404)
    def do_POST(self):
        u=urlparse(self.path)
        if not self.authorized(): return self.sendj({'error':'unauthorized'},401)
        if u.path!='/submit': return self.sendj({'error':'not-found'},404)
        length=min(int(self.headers.get('Content-Length','0') or 0),65536)
        try: body=json.loads(self.rfile.read(length) or b'{}')
        except Exception: return self.sendj({'error':'invalid-json'},400)
        kind=str(body.get('kind',''))[:64]
        if kind not in ALLOWED_KINDS: return self.sendj({'error':'kind-not-allowed','allowed':sorted(ALLOWED_KINDS)},400)
        job={'id':str(uuid.uuid4()),'kind':kind,'status':'queued','created':now(),'path':str(body.get('path',''))[:1024],'query':str(body.get('query',''))[:256],'route':'linux-worker'}
        save_job(job); threading.Thread(target=execute_job,args=(job,),daemon=True).start(); return self.sendj({'ok':True,'job':job},202)
    def log_message(self,*args): pass

if __name__=='__main__':
    JOBS.mkdir(parents=True,exist_ok=True); state['started']=now(); persist_state(); ThreadingHTTPServer((BIND,PORT),Handler).serve_forever()
