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
$Codespace='glowing-couscous-q7pwv9xxq647c65x4'

function Invoke-NexusSsh($HostName,$Port,$RemoteCommand){
  if(!(Test-Path $GitSsh) -or !(Test-Path $Key)){ return 127 }
  & $GitSsh -F NUL -o ControlMaster=no -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=3 -p $Port -i $Key "root@$HostName" $RemoteCommand
  return $LASTEXITCODE
}

function Invoke-NexusCodespace($RemoteCommand){
  if(!(Get-Command gh -ErrorAction SilentlyContinue)){ return 127 }
  gh codespace ssh -c $Codespace -- $RemoteCommand
  return $LASTEXITCODE
}

if(!$Command){
  Write-Host 'Uso: nexus-run <comando>'
  Write-Host 'Orden: Linux LAN -> relay -> Codespace -> Windows local'
  exit 0
}

$cmd=$Command -join ' '
$remote="mkdir -p /dev/shm/nexus-offload 2>/dev/null || true; cd /dev/shm/nexus-offload 2>/dev/null || cd /tmp; export TMPDIR=/dev/shm/nexus-offload; $cmd"

Write-Host '[NEXUS] backend 1/4: Linux LAN'
$rc=Invoke-NexusSsh $LinuxLan 22 $remote
if($rc -eq 0){ Write-Host '[NEXUS] backend=LINUX_LAN'; exit 0 }

Write-Host '[NEXUS] backend 2/4: Linux relay'
$rc=Invoke-NexusSsh $RelayHost $RelayPort $remote
if($rc -eq 0){ Write-Host '[NEXUS] backend=LINUX_RELAY'; exit 0 }

Write-Host '[NEXUS] backend 3/4: GitHub Codespace 32GB'
$rc=Invoke-NexusCodespace "cd /workspaces/nexus-core 2>/dev/null || cd /workspaces; $cmd"
if($rc -eq 0){ Write-Host '[NEXUS] backend=CODESPACE'; exit 0 }

Write-Host '[NEXUS] backend 4/4: Windows local (fallback)'
Invoke-Expression $cmd
exit $LASTEXITCODE