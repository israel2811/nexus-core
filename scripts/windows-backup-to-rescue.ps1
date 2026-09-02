param(
  [ValidateSet('core','downloads','media','all')]
  [string]$Mode='core',
  [string]$RelayHost='bore.pub',
  [int]$RelayPort=22208,
  [string]$RemoteRoot='/mnt/NEXUS_SAFE_BACKUP/DESKTOP-BU2SSJM'
)
$ErrorActionPreference='Stop'
$Ssh='C:\Program Files\Git\usr\bin\ssh.exe'
$Tar="$env:SystemRoot\System32\tar.exe"
$Key=Join-Path $HOME '.ssh\id_ed25519_nexus_offload'
$VerifyMarker='/run/nexus-storage-verified-ok'
if(!(Test-Path $Ssh) -or !(Test-Path $Tar) -or !(Test-Path $Key)){ throw 'Falta ssh, tar o la clave NEXUS.' }

$sets=[ordered]@{
  core=@('Desktop','Documents','nexus_work','.codex','.claude','.gemini')
  downloads=@('Downloads')
  media=@('Pictures','Videos','Music')
}
# Nunca copiar cookies/historial/perfiles de navegador ni claves privadas SSH.
$extra=@()
foreach($f in @('.gitconfig','.ssh\config','.ssh\authorized_keys')){
  if(Test-Path (Join-Path $HOME $f)){ $extra += $f }
}
$sets.core += $extra

function Invoke-Ssh([string]$Remote){
  & $Ssh -F NUL -o ControlMaster=no -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -p $RelayPort -i $Key "root@$RelayHost" $Remote
  if($LASTEXITCODE -ne 0){ throw "SSH fallo rc=$LASTEXITCODE" }
}

# Fail closed: Linux creates this marker only after verifying a healthy persistent target.
# The backup script itself never creates the destination or the marker.
Invoke-Ssh "test -f '$VerifyMarker' || { echo 'NEXUS backup blocked: storage not verified' >&2; exit 70; }; test -d '$RemoteRoot' || { echo 'Backup root missing' >&2; exit 71; }; test -w '$RemoteRoot' || { echo 'Backup root not writable' >&2; exit 72; }; df -h '$RemoteRoot'"

function Send-Set([string]$Name,[string[]]$Items){
  $present=@($Items | Where-Object { Test-Path (Join-Path $HOME $_) })
  if(!$present){ Write-Host "[SKIP] $Name vacio"; return }
  $list=Join-Path $env:TEMP "nexus-backup-$Name.txt"
  [IO.File]::WriteAllLines($list,$present,(New-Object Text.UTF8Encoding($false)))
  $remotePart="$RemoteRoot/$Name.tar.zst.part"
  $remoteFinal="$RemoteRoot/$Name.tar.zst"
  $sshArgs="-F NUL -o ControlMaster=no -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -p $RelayPort -i `"$Key`" root@$RelayHost"
  $remote="zstd -T0 -3 -q -o '$remotePart' && mv -f '$remotePart' '$remoteFinal' && sha256sum '$remoteFinal'"
  $cmd="`"$Tar`" -cf - -C `"$HOME`" -T `"$list`" | `"$Ssh`" $sshArgs `"$remote`""
  Write-Host "[SEND] $Name -> $remoteFinal"
  & $env:ComSpec /d /s /c $cmd
  $rc=$LASTEXITCODE
  Remove-Item $list -Force -ErrorAction SilentlyContinue
  if($rc -ne 0){ throw "Transferencia $Name fallo rc=$rc" }
}

if($Mode -in @('core','all')){ Send-Set core $sets.core }
if($Mode -in @('downloads','all')){ Send-Set downloads $sets.downloads }
if($Mode -in @('media','all')){ Send-Set media $sets.media }
Write-Host '[DONE] Backup por categorias completado en almacenamiento previamente verificado.'
