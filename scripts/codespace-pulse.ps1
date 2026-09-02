param(
  [Parameter(Mandatory=$true,ValueFromRemainingArguments=$true)]
  [string[]]$Command,
  [int]$ReadyTimeoutSeconds=90,
  [int]$CommandTimeoutSeconds=900,
  [switch]$KeepRunning
)
$ErrorActionPreference='Stop'
$Repo='israel2811/nexus-core'
$Codespace='glowing-couscous-q7pwv9xxq647c65x4'
if(!(Get-Command gh -ErrorAction SilentlyContinue)){ throw 'GitHub CLI no disponible.' }
$cmd=$Command -join ' '
Write-Host "[NEXUS PULSE] codespace=$Codespace"

function Get-State {
  $x=gh codespace list --repo $Repo --json name,state 2>$null | ConvertFrom-Json
  ($x | Where-Object name -eq $Codespace | Select-Object -First 1).state
}

$initial=Get-State
Write-Host "[NEXUS PULSE] initial=$initial"
if($initial -ne 'Available'){
  Write-Host '[NEXUS PULSE] starting...'
  gh codespace start -c $Codespace | Out-Null
  if($LASTEXITCODE -ne 0){ throw 'No se pudo iniciar Codespace.' }
}

$deadline=(Get-Date).AddSeconds($ReadyTimeoutSeconds)
$ready=$false
while((Get-Date) -lt $deadline){
  $job=Start-Job -ScriptBlock { param($n) & gh codespace ssh -c $n -- 'printf NEXUS_READY'; exit $LASTEXITCODE } -ArgumentList $Codespace
  if(Wait-Job $job -Timeout 6){
    $out=(Receive-Job $job -ErrorAction SilentlyContinue | Out-String)
    $ready=($out -match 'NEXUS_READY')
  }
  Stop-Job $job -ErrorAction SilentlyContinue
  Remove-Job $job -Force -ErrorAction SilentlyContinue
  if($ready){break}
  Start-Sleep 4
}
if(!$ready){ throw 'Codespace no alcanzó SSH listo dentro del timeout.' }

Write-Host '[NEXUS PULSE] executing remotely'
$remote="cd /workspaces/nexus-core 2>/dev/null || cd /workspaces; $cmd"
$job=Start-Job -ScriptBlock { param($n,$c) & gh codespace ssh -c $n -- $c; exit $LASTEXITCODE } -ArgumentList $Codespace,$remote
if(!(Wait-Job $job -Timeout $CommandTimeoutSeconds)){
  Stop-Job $job -ErrorAction SilentlyContinue
  Remove-Job $job -Force -ErrorAction SilentlyContinue
  throw 'Tarea remota excedió timeout.'
}
Receive-Job $job
$rc=if($job.State -eq 'Completed'){0}else{1}
Remove-Job $job -Force

if(!$KeepRunning){
  Write-Host '[NEXUS PULSE] stopping Codespace'
  gh codespace stop -c $Codespace | Out-Null
}
exit $rc
