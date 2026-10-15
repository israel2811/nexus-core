# NEXUS safe on-demand cloud offloading, Windows / GitHub CLI.
# No artificial keepalive. No secret export. Do not send private files to public repo.
[CmdletBinding()]
param(
  [ValidateSet('status','start','test','auto','stop')]
  [string]$Action = 'status',
  [ValidateSet('smoke','manifest','validate')]
  [string]$Job = 'smoke',
  [switch]$PermitComputeBilling,
  [switch]$KeepRunning,
  [ValidateRange(512,8192)][int]$MinFreeRamMB = 1536
)
$ErrorActionPreference = 'Stop'
$Name = 'glowing-couscous-q7pwv9xxq647c65x4'
$Repo = 'israel2811/nexus-core'
$Api = "/user/codespaces/$Name"
$env:GIT_TERMINAL_PROMPT = '0'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI is unavailable' }
function Get-CS {
  $raw = & gh api $Api
  if ($LASTEXITCODE -ne 0) { throw 'Cannot retrieve Codespace details' }
  $cs = $raw | ConvertFrom-Json
  if ($cs.name -ne $Name -or $cs.repository.full_name -ne $Repo) { throw 'Unexpected Codespace or repository' }
  return $cs
}
function Wait-CS {
  for ($i=0; $i -lt 30; $i++) {
    $cs = Get-CS
    if ($cs.state -eq 'Available') { return }
    Start-Sleep -Seconds 6
  }
  throw 'Codespace did not become available within 180 seconds'
}
function Start-CS {
  if (-not $PermitComputeBilling) { throw 'Use -PermitComputeBilling only after agreeing to potential compute charges' }
  $cs = Get-CS
  if ($cs.state -eq 'Shutdown') {
    Write-Host 'Starting the existing Codespace through the official GitHub REST API'
    $null = & gh api -X POST "$Api/start"
    if ($LASTEXITCODE -ne 0) { throw 'GitHub API rejected start request' }
    Wait-CS
  } elseif ($cs.state -ne 'Available') {
    throw "Codespace state is $($cs.state)"
  }
}
function Stop-CS {
  $cs = Get-CS
  if ($cs.state -eq 'Shutdown') { Write-Host 'Already stopped'; return }
  & gh codespace stop -c $Name
  if ($LASTEXITCODE -ne 0) { throw 'Could not stop Codespace' }
}
function Invoke-Job {
  # Only predefined, read-only remote commands are allowed.
  $commands = @{
    smoke = 'python3 --version'
    manifest = 'pwd; git rev-parse --short HEAD; df -h .; free -h'
    validate = 'python3 scripts/validate_nexus_capability_bus.py'
  }
  $cmd = $commands[$Job]
  if ($null -eq $cmd) { throw 'Unsupported job type' }
  Write-Host "Executing remote job: $Job"
  & gh codespace ssh -c $Name -- bash -lc $cmd
  if ($LASTEXITCODE -ne 0) { throw "Remote job failed: $Job" }
}
switch ($Action) {
  'status' {
    $cs = Get-CS
    Write-Host ("NEXUS_CLOUD {0}; machine={1}; idle_timeout={2}m; retention={3}d" -f $cs.state,$cs.machine.name,$cs.idle_timeout_minutes,($cs.retention_period_minutes/1440))
    Write-Host 'No compute started'
  }
  'start' { Start-CS; Write-Host 'NEXUS_CLOUD=Available; metered compute is now running' }
  'stop' { Stop-CS }
  'test' {
    if ((Get-CS).state -ne 'Available') { throw 'Codespace is offline. Start explicitly first.' }
    Invoke-Job
  }
  'auto' {
    $o = Get-CimInstance Win32_OperatingSystem
    $free = [math]::Round($o.FreePhysicalMemory/1024,0)
    Write-Host "RAM free (MiB): $free; threshold $MinFreeRamMB; remote job $Job"
    if ($free -ge $MinFreeRamMB) { Write-Host 'Local RAM sufficient: remote compute not started'; break }
    if (-not $PermitComputeBilling) { throw 'Low RAM detected; explicitly grant -PermitComputeBilling for remote work' }
    $wasShutdown = (Get-CS).state -eq 'Shutdown'
    try {
      Start-CS
      Invoke-Job
    } finally {
      if ($wasShutdown -and -not $KeepRunning) { Stop-CS }
    }
  }
}
