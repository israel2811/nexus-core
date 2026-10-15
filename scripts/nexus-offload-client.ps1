# NEXUS: on-demand Codespace worker. No keepalive, no persistent process.
# The Codespace MUST be started deliberately; GitHub may bill active compute.
[CmdletBinding()]
param(
  [ValidateSet('status','start','test','stop')]
  [string]$Action='status',
  [switch]$PermitComputeBilling
)
$ErrorActionPreference='Stop'
$codespace='glowing-couscous-q7pwv9xxq647c65x4'
$repo='israel2811/nexus-core'

function Get-NexusCodespace {
  $raw = & gh codespace list --json name,state,machineName,repository --limit 30
  if ($LASTEXITCODE -ne 0) { throw 'GitHub CLI cannot list Codespaces' }
  $spaces = @($raw | ConvertFrom-Json)
  $item = $spaces | Where-Object { $_.name -eq $codespace } | Select-Object -First 1
  if (-not $item) { throw "Existing Codespace $codespace was not found" }
  if ($item.repository -ne $repo) { throw 'Codespace repo mismatch' }
  return $item
}

$cs = Get-NexusCodespace
Write-Host ("NEXUS Codespace: {0} ({1}, {2})" -f $cs.name,$cs.state,$cs.machineName)

switch ($Action) {
  'status' {
    Write-Host 'No compute was started and no tokens were exported.'
  }
  'start' {
    if ($cs.state -ne 'Shutdown') { Write-Host 'Already started; no action'; break }
    if (-not $PermitComputeBilling) {
      throw 'Starting a Codespace consumes GitHub compute quota and can incur charges. Re-run with -PermitComputeBilling after verifying billing.'
    }
    & gh codespace start -c $codespace
    if ($LASTEXITCODE -ne 0) { throw 'Codespace start failed' }
    Write-Host 'Codespace start requested; check status before submitting work.'
  }
  'test' {
    if ($cs.state -eq 'Shutdown') {
      throw 'Codespace is stopped. Start explicitly with -Action start -PermitComputeBilling.'
    }
    # Deliberately restrict to a tiny read-only job. Heavy tasks can be added after validating limits.
    & gh codespace ssh -c $codespace -- python3 -c 'import platform; print("NEXUS_OFFLOAD_OK",platform.system(),platform.python_version())'
    if ($LASTEXITCODE -ne 0) { throw 'Remote execution test failed' }
  }
  'stop' {
    if ($cs.state -eq 'Shutdown') { Write-Host 'Already stopped'; break }
    & gh codespace stop -c $codespace
    if ($LASTEXITCODE -ne 0) { throw 'Codespace stop failed' }
    Write-Host 'Stop requested; remote unsaved process state will not persist.'
  }
}
