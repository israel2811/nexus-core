param(
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$Command,
  [ValidateSet('auto','linux','codespace','local')]
  [string]$Backend='auto',
  [switch]$ForceLocal
)
$ErrorActionPreference='Stop'
$GitSsh='C:\Program Files\Git\usr\bin\ssh.exe'
$Key=Join-Path $HOME '.ssh\id_ed25519_nexus_offload'
$RelayHost='bore.pub'
$RelayPort=22208
$Codespace='glowing-couscous-q7pwv9xxq647c65x4'
$IpState=Join-Path $env:LOCALAPPDATA 'NEXUS\linux-current-ip.txt'

function Get-LinuxCandidates {
  $ips=@()
  if(Test-Path $IpState){ $ips += (Get-Content $IpState -ErrorAction SilentlyContinue | Select-Object -First 1) }
  $ips += @('10.76.153.122','10.237.226.122','10.129.36.122')
  $ips | Where-Object {$_ -match '^\d{1,3}(\.\d{1,3}){3}$'} | Select-Object -Unique
}
function Resolve-RelayIPv4 {
  try {
    $r=Resolve-DnsName $RelayHost -Server 1.1.1.1 -Type A -DnsOnly -ErrorAction Stop |
      Where-Object {$_.IPAddress -match '^\d+\.'} | Select-Object -First 1 -ExpandProperty IPAddress
    if($r){ return $r }
  } catch {}
  return $RelayHost
}
function Invoke-NexusSsh([string]$HostName,[int]$Port,[string]$RemoteCommand,[string]$Alias=''){
  if(!(Test-Path $GitSsh) -or !(Test-Path $Key)){ return 127 }
  $args=@('-F','NUL','-o','ControlMaster=no','-o','BatchMode=yes','-o','StrictHostKeyChecking=accept-new','-o','ConnectTimeout=2','-o','ConnectionAttempts=1')
  if($Alias){ $args += @('-o',"HostKeyAlias=$Alias") }
  $args += @('-p',$Port,'-i',$Key,"root@$HostName",$RemoteCommand)
  & $GitSsh @args
  return $LASTEXITCODE
}
function Invoke-NexusCodespace([string]$RemoteCommand){
  if(!(Get-Command gh -ErrorAction SilentlyContinue)){ return 127 }
  $job=Start-Job -ScriptBlock { param($c,$n) & gh codespace ssh -c $n -- $c; exit $LASTEXITCODE } -ArgumentList $RemoteCommand,$Codespace
  if(Wait-Job $job -Timeout 6){
    Receive-Job $job
    $rc=if($job.State -eq 'Completed'){0}else{1}
    Remove-Job $job -Force
    return $rc
  }
  Stop-Job $job -ErrorAction SilentlyContinue
  Remove-Job $job -Force
  return 124
}
function Test-LocalCapacity {
  $os=Get-CimInstance Win32_OperatingSystem
  $cpus=Get-CimInstance Win32_Processor
  $cpu=($cpus | Measure-Object LoadPercentage -Average).Average
  $freeGB=[math]::Round($os.FreePhysicalMemory/1MB,2)
  $clock=($cpus | Measure-Object CurrentClockSpeed -Average).Average
  $max=($cpus | Measure-Object MaxClockSpeed -Average).Average
  $ratio=if($max -gt 0){[math]::Round($clock/$max,2)}else{1}
  $ok=($cpu -lt 30 -and $freeGB -ge 3.0 -and $ratio -ge 0.70)
  [pscustomobject]@{CPU=[double]$cpu;FreeGB=$freeGB;ClockMHz=[int]$clock;MaxMHz=[int]$max;ClockRatio=$ratio;OK=$ok}
}
if(!$Command){
  Write-Host 'Uso: nexus-run [-Backend auto|linux|codespace|local] [-ForceLocal] <comando>'
  Write-Host 'Auto: Linux LAN -> Linux relay IPv4 -> Codespace -> Windows solo si CPU/RAM/frecuencia son sanas.'
  exit 0
}
$cmd=$Command -join ' '
$remote="mkdir -p /dev/shm/nexus-offload 2>/dev/null || true; cd /dev/shm/nexus-offload 2>/dev/null || cd /tmp; export TMPDIR=/dev/shm/nexus-offload; $cmd"
if($Backend -in @('auto','linux')){
  foreach($ip in Get-LinuxCandidates){
    Write-Host "[NEXUS] Linux LAN $ip"
    $rc=Invoke-NexusSsh $ip 22 $remote
    if($rc -eq 0){ Write-Host "[NEXUS] backend=LINUX_LAN ip=$ip"; exit 0 }
  }
  $relay=Resolve-RelayIPv4
  Write-Host "[NEXUS] Linux relay ${relay}:$RelayPort"
  $rc=Invoke-NexusSsh $relay $RelayPort $remote $RelayHost
  if($rc -eq 0){ Write-Host '[NEXUS] backend=LINUX_RELAY'; exit 0 }
  if($Backend -eq 'linux'){ exit 69 }
}
if($Backend -in @('auto','codespace')){
  Write-Host '[NEXUS] Codespace'
  $rc=Invoke-NexusCodespace "cd /workspaces/nexus-core 2>/dev/null || cd /workspaces; $cmd"
  if($rc -eq 0){ Write-Host '[NEXUS] backend=CODESPACE'; exit 0 }
  if($Backend -eq 'codespace'){ exit $rc }
}
$cap=Test-LocalCapacity
Write-Host "[NEXUS] local CPU=$($cap.CPU)% freeRAM=$($cap.FreeGB)GB clock=$($cap.ClockMHz)/$($cap.MaxMHz)MHz ratio=$($cap.ClockRatio)"
if($Backend -eq 'local' -or $ForceLocal -or $cap.OK){
  Write-Host '[NEXUS] backend=WINDOWS_LOCAL'
  Invoke-Expression $cmd
  exit $LASTEXITCODE
}
Write-Error 'Remotos no disponibles y Windows no tiene capacidad segura. Usa -ForceLocal solo si aceptas ejecutar aqui.'
exit 75
