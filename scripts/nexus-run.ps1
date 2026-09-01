param(
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$Command
)
$ErrorActionPreference='Stop'
$GitSsh='C:\Program Files\Git\usr\bin\ssh.exe'
$Key=Join-Path $HOME '.ssh\id_ed25519_nexus_offload'
$LinuxLan='10.129.36.122'
$RelayHost='bore.pub'
$RelayPort=22208
function Invoke-NexusSsh($HostName,$Port,$RemoteCommand){
  & $GitSsh -F /dev/null -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=3 -p $Port -i $Key "root@$HostName" $RemoteCommand
  return $LASTEXITCODE
}
if(!$Command){
  Write-Host 'Uso: nexus-run <comando>'
  Write-Host 'Ejemplo: nexus-run python3 --version'
  exit 0
}
$cmd=$Command -join ' '
$remote="cd /dev/shm/nexus-offload && export TMPDIR=/dev/shm/nexus-offload && $cmd"
Write-Host '[NEXUS] Probando Linux LAN...'
$rc=Invoke-NexusSsh $LinuxLan 22 $remote
if($rc -eq 0){ Write-Host '[NEXUS] backend=LINUX_LAN'; exit 0 }
Write-Host '[NEXUS] LAN no disponible; probando relay...'
$rc=Invoke-NexusSsh $RelayHost $RelayPort $remote
if($rc -eq 0){ Write-Host '[NEXUS] backend=LINUX_RELAY'; exit 0 }
Write-Host '[NEXUS] Linux no disponible; ejecutando localmente.'
Invoke-Expression $cmd
exit $LASTEXITCODE