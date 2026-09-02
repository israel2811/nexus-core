#!/usr/bin/env python3
import hashlib, json, os, threading, time, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path, PureWindowsPath
from urllib.parse import parse_qs, urlparse

STATE = Path('/var/lib/nexus-offload/state.json')
JOBS = Path('/var/lib/nexus-offload/jobs')
TOKEN_FILE = Path('/etc/nexus-offload.token')
WINDOWS_HOME = Path(os.environ.get('NEXUS_WINDOWS_HOME', '/mnt/windows-home'))
WIN = os.environ.get('NEXUS_WINDOWS_HOST', '')
KEY = os.environ.get('NEXUS_WINDOWS_KEY', '')
WIN_USER = os.environ.get('NEXUS_WINDOWS_USER', 'dell')
WIN_PROFILE = os.environ.get('NEXUS_WINDOWS_PROFILE', 'Dell')
BIND = os.environ.get('NEXUS_BROKER_BIND', '127.0.0.1')
PORT = int(os.environ.get('NEXUS_BROKER_PORT', '8765'))
ALLOWED_KINDS = {'repo-inventory', 'hash-tree', 'source-search', 'health-snapshot'}
MAX_JOB_SECONDS = 20
MAX_FILES = 2500
JOB_SLOTS = threading.BoundedSemaphore(2)
SENSITIVE_PARTS = {'.ssh', 'secrets', 'credentials', 'cookies', 'login data', 'user data', '.config', '.aws', '.azure', '.gnupg', '.kube'}
SENSITIVE_FILES = {'.env', 'auth.json', 'credentials.db', 'access_tokens.db', 'application_default_credentials.json', 'token', 'tokens.json', 'login data', 'cookies'}
state = {'windows': {}, 'updated': None, 'mode': 'automatic', 'version': 4}


def now():
    return time.strftime('%Y-%m-%dT%H:%M:%S%z')


def token():
    try:
        return TOKEN_FILE.read_text().strip()
    except Exception:
        return ''


def persist_state():
    STATE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE.with_suffix('.tmp')
    tmp.write_text(json.dumps(state, indent=2))
    os.replace(tmp, STATE)


def job_path(job_id):
    return JOBS / f'{job_id}.json'


def save_job(job):
    JOBS.mkdir(parents=True, exist_ok=True)
    tmp = JOBS / f"{job['id']}.tmp"
    tmp.write_text(json.dumps(job, indent=2))
    os.replace(tmp, job_path(job['id']))


def windows_path_to_local(value):
    p = PureWindowsPath(str(value))
    parts = p.parts
    if len(parts) < 3 or p.drive.upper() != 'C:':
        raise ValueError(f'path must be under C:\\Users\\{WIN_PROFILE}')
    if parts[1].lower() != 'users' or parts[2].lower() != WIN_PROFILE.lower():
        raise ValueError(f'path must be under C:\\Users\\{WIN_PROFILE}')
    local = WINDOWS_HOME.joinpath(*parts[3:])
    base = WINDOWS_HOME.resolve()
    resolved = local.resolve()
    if os.path.commonpath([str(base), str(resolved)]) != str(base):
        raise ValueError('path escaped allowed root')
    lowered = {part.lower() for part in resolved.parts}
    if lowered & SENSITIVE_PARTS:
        raise ValueError('sensitive path is not eligible for automatic offload')
    return resolved


def run_remote(remote):
    import subprocess
    if not WIN or not KEY:
        return '', 2
    p = subprocess.run([
        'ssh', '-i', KEY, '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=4',
        f'{WIN_USER}@{WIN}', remote
    ], capture_output=True, text=True, timeout=8)
    return p.stdout, p.returncode


def sample():
    cpu, rc1 = run_remote('cmd.exe /c wmic cpu get LoadPercentage,CurrentClockSpeed,MaxClockSpeed /value')
    mem, rc2 = run_remote('cmd.exe /c wmic os get FreePhysicalMemory,TotalVisibleMemorySize /value')
    if rc1 == 0 and rc2 == 0:
        data = {}
        for line in (cpu + '\n' + mem).replace('\r', '').splitlines():
            if '=' in line:
                key, value = line.split('=', 1)
                data[key.strip()] = value.strip()
        state['windows'] = {
            'reachable': True, 'cpu': int(data.get('LoadPercentage') or 0),
            'mhz': int(data.get('CurrentClockSpeed') or 0),
            'maxmhz': int(data.get('MaxClockSpeed') or 0),
            'ram_free_gb': round(int(data.get('FreePhysicalMemory') or 0) / 1048576, 2),
            'ram_total_gb': round(int(data.get('TotalVisibleMemorySize') or 0) / 1048576, 2),
        }
    else:
        state['windows'] = {'reachable': False, 'rc_cpu': rc1, 'rc_mem': rc2}
    state['updated'] = now()
    persist_state()


def choose(task):
    text = str(task).lower()
    w = state.get('windows', {})
    cpu = int(w.get('cpu', 0) or 0)
    free = float(w.get('ram_free_gb', 99) or 99)
    if any(x in text for x in ('gpu', 'ml', 'embedding', 'spectrogram', 'large-data')):
        return 'gpu-cloud'
    if any(x in text for x in ('build', 'test', 'lint', 'npm', 'compile')):
        return 'github-actions-or-codespace'
    if any(x in text for x in ('scrape', 'browser-automation', 'crawl')):
        return 'remote-browser'
    if cpu > 60 or free < 1.5:
        return 'linux-worker'
    return 'local'


def iter_files(root, max_files=MAX_FILES, deadline=None):
    count = 0
    for base, dirs, files in os.walk(root):
        if deadline and time.monotonic() > deadline:
            return
        dirs[:] = [d for d in dirs if d.lower() not in {'.git', 'node_modules', '.venv', '__pycache__'} | SENSITIVE_PARTS]
        for name in files:
            if name.lower() in SENSITIVE_FILES or name.lower().startswith('.env.'):
                continue
            count += 1
            if count > max_files:
                return
            path = Path(base) / name
            try:
                if path.is_file():
                    yield path
            except OSError:
                continue


def do_inventory(root, deadline):
    total = 0
    rows = []
    for path in iter_files(root, deadline=deadline):
        try:
            size = path.stat().st_size
        except OSError:
            continue
        total += size
        rows.append((size, str(path.relative_to(root))))
    rows.sort(reverse=True)
    return {'files': len(rows), 'bytes': total,
            'largest': [{'path': p, 'bytes': s} for s, p in rows[:100]]}


def do_hash_tree(root, deadline):
    hashes = []
    total = 0
    for path in iter_files(root, max_files=MAX_FILES, deadline=deadline):
        try:
            size = path.stat().st_size
            if size > 64 * 1024 * 1024 or total + size > 2 * 1024**3:
                continue
            h = hashlib.sha256()
            with path.open('rb') as f:
                for block in iter(lambda: f.read(1024 * 1024), b''):
                    h.update(block)
            total += size
            hashes.append({'path': str(path.relative_to(root)), 'bytes': size, 'sha256': h.hexdigest()})
        except (OSError, PermissionError):
            continue
    return {'files_hashed': len(hashes), 'bytes_hashed': total, 'items': hashes}


def do_source_search(root, query, deadline):
    needle = str(query)[:256].lower()
    if not needle:
        raise ValueError('query required')
    matches = []
    for path in iter_files(root, max_files=MAX_FILES, deadline=deadline):
        try:
            if path.stat().st_size > 2 * 1024 * 1024:
                continue
            text = path.read_text(errors='ignore')
        except (OSError, UnicodeError):
            continue
        for line_no, line in enumerate(text.splitlines(), 1):
            if needle in line.lower():
                matches.append({'path': str(path.relative_to(root)), 'line': line_no, 'text': line[:500]})
                if len(matches) >= 200:
                    return {'query': needle, 'matches': matches, 'truncated': True}
    return {'query': needle, 'matches': matches, 'truncated': False}


def execute_job(job):
    acquired = JOB_SLOTS.acquire(timeout=2)
    if not acquired:
        job['status'] = 'deferred-busy'
        job['finished'] = now()
        save_job(job)
        return
    try:
        deadline = time.monotonic() + MAX_JOB_SECONDS
        job['status'] = 'running'
        job['started'] = now()
        save_job(job)
        if job['kind'] == 'health-snapshot':
            result = {'state': state}
        else:
            root = windows_path_to_local(job['path'])
            if not root.exists():
                raise FileNotFoundError(str(root))
            if job['kind'] == 'repo-inventory':
                result = do_inventory(root, deadline)
            elif job['kind'] == 'hash-tree':
                result = do_hash_tree(root, deadline)
            elif job['kind'] == 'source-search':
                result = do_source_search(root, job.get('query', ''), deadline)
            else:
                raise ValueError('unsupported kind')
        job['result'] = result
        job['status'] = 'completed'
        job['finished'] = now()
    except Exception as exc:
        job['status'] = 'failed'
        job['finished'] = now()
        job['error'] = f'{type(exc).__name__}: {exc}'[:1000]
    finally:
        JOB_SLOTS.release()
    save_job(job)


class Handler(BaseHTTPRequestHandler):
    def sendj(self, obj, code=200):
        body = json.dumps(obj, separators=(',', ':')).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def authorized(self):
        supplied = self.headers.get('X-Nexus-Key', '')
        return bool(token()) and supplied == token()

    def do_GET(self):
        u = urlparse(self.path)
        if u.path == '/health':
            return self.sendj({'ok': True, 'mode': state['mode'], 'version': state['version']})
        if not self.authorized():
            return self.sendj({'error': 'unauthorized'}, 401)
        if u.path == '/state':
            return self.sendj(state)
        if u.path == '/route':
            task = parse_qs(u.query).get('task', [''])[0][:256]
            return self.sendj({'task': task, 'route': choose(task), 'windows': state.get('windows', {})})
        if u.path == '/job':
            job_id = parse_qs(u.query).get('id', [''])[0]
            if not job_id or '/' in job_id or '\\' in job_id:
                return self.sendj({'error': 'invalid-job-id'}, 400)
            path = job_path(job_id)
            if not path.exists():
                return self.sendj({'error': 'not-found'}, 404)
            try:
                return self.sendj(json.loads(path.read_text()))
            except Exception:
                return self.sendj({'error': 'corrupt-job'}, 500)
        return self.sendj({'error': 'not-found'}, 404)

    def do_POST(self):
        u = urlparse(self.path)
        if not self.authorized():
            return self.sendj({'error': 'unauthorized'}, 401)
        if u.path != '/submit':
            return self.sendj({'error': 'not-found'}, 404)
        length = min(int(self.headers.get('Content-Length', '0') or 0), 65536)
        try:
            body = json.loads(self.rfile.read(length) or b'{}')
        except Exception:
            return self.sendj({'error': 'invalid-json'}, 400)
        kind = str(body.get('kind', ''))[:64]
        if kind not in ALLOWED_KINDS:
            return self.sendj({'error': 'kind-not-allowed', 'allowed': sorted(ALLOWED_KINDS)}, 400)
        job = {
            'id': str(uuid.uuid4()), 'kind': kind, 'status': 'queued',
            'created': now(), 'path': str(body.get('path', ''))[:1024],
            'query': str(body.get('query', ''))[:256],
            'route': 'linux-worker',
        }
        save_job(job)
        threading.Thread(target=execute_job, args=(job,), daemon=True).start()
        return self.sendj({'ok': True, 'job': job}, 202)

    def log_message(self, *args):
        pass


def sampler():
    while True:
        try:
            sample()
        except Exception as exc:
            state['windows'] = {'reachable': False, 'error': type(exc).__name__}
            state['updated'] = now()
            persist_state()
        time.sleep(30)


if __name__ == '__main__':
    JOBS.mkdir(parents=True, exist_ok=True)
    threading.Thread(target=sampler, daemon=True).start()
    ThreadingHTTPServer((BIND, PORT), Handler).serve_forever()
