param(
  [ValidateSet('core','downloads','media','all')]
  [string]$Mode='core',
  [string]$RelayHost='bore.pub',
  [int]$RelayPort=22208
)
$ErrorActionPreference='Stop'
$Ssh='C:\Program Files\Git\usr\bin\ssh.exe'
$Tar="$env:SystemRoot\System32\tar.exe"
$Key=Join-Path $HOME '.ssh\id_ed25519_nexus_offload'
$RemoteRoot="/mnt/VENTOY_RW/NEXUS_WINDOWS_BACKUP/$env:COMPUTERNAME"
if(!(Test-Path $Ssh) -or !(Test-Path $Tar) -or !(Test-Path $Key)){ throw 'Falta ssh, tar o la clave NEXUS.' }

$sets=[ordered]@{
  core=@('Desktop','Documents','nexus_work','.codex','.claude','.gemini')
  downloads=@('Downloads')
  media=@('Pictures','Videos','Music')
}
# Intencionalmente NO se copian perfiles/cookies/historial de navegadores ni claves SSH privadas.
# Archivos publicos/configuracion SSH se guardan aparte si existen.
$extra=@()
foreach($f in @('.gitconfig','.ssh\config','.ssh\authorized_keys')){ if(Test-Path (Join-Path $HOME $f)){ $extra += $f } }
$sets.core += $extra

function Invoke-Ssh([string]$Remote){
  & $Ssh -F NUL -o ControlMaster=no -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -p $RelayPort -i $Key "root@$RelayHost" $Remote
  if($LASTEXITCODE -ne 0){ throw "SSH fallo rc=$LASTEXITCODE" }
}
function Send-Set([string]$Name,[string[]]$Items){
  $present=@($Items | Where-Object { Test-Path (Join-Path $HOME $_) })
  if(!$present){ Write-Host "[SKIP] $Name vacio"; return }
  $list=Join-Path $env:TEMP "nexus-backup-$Name.txt"
  [IO.File]::WriteAllLines($list,$present,(New-Object Text.UTF8Encoding($false)))
  $remotePart="$RemoteRoot/$Name.tar.zst.part"
  $remoteFinal="$RemoteRoot/$Name.tar.zst"
  Invoke-Ssh "mkdir -p '$RemoteRoot'; df -h '$RemoteRoot'; rm -f '$remotePart'"
  $sshArgs="-F NUL -o ControlMaster=no -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -p $RelayPort -i `"$Key`" root@$RelayHost"
  $remote="zstd -T0 -3 -q -o '$remotePart' && mv -f '$remotePart' '$remoteFinal' && sha256sum '$remoteFinal'"
  $cmd="`"$Tar`" -cf - -C `"$HOME`" -T `"$list`" | `"$Ssh`" $sshArgs `"$remote`""
  Write-Host "[SEND] $Name -> $remoteFinal"
  & $env:ComSpec /d /s /c $cmd
  $rc=$LASTEXITCODE
  Remove-Item $list -Force -ErrorAction SilentlyContinue
  if($rc -ne 0){ throw "Transferencia $Name fallo rc=$rc" }
}

Invoke-Ssh "mkdir -p '$RemoteRoot'; printf 'host=%s\ntime=%s\n' '$env:COMPUTERNAME' \"$(date -Is)\" > '$RemoteRoot/BACKUP_INFO.txt'; df -h '$RemoteRoot'"
if($Mode -in @('core','all')){ Send-Set core $sets.core }
if($Mode -in @('downloads','all')){ Send-Set downloads $sets.downloads }
if($Mode -in @('media','all')){ Send-Set media $sets.media }
Write-Host '[DONE] Backup por categorias completado.'
