param(
  [ValidateSet('all','manifest','split')]
  [string]$Mode='all',
  [string]$InputPath='offload/sample_input'
)
$ErrorActionPreference='Stop'
$Repo='israel2811/nexus-core'
Write-Host "[NEXUS CLOUD] repo=$Repo mode=$Mode input=$InputPath"
gh workflow run offload-light-batch.yml `
  --repo $Repo `
  -f "input_path=$InputPath" `
  -f "mode=$Mode"
if($LASTEXITCODE -ne 0){ throw 'No se pudo lanzar GitHub Actions.' }
Start-Sleep 2
$run=gh run list --repo $Repo --workflow offload-light-batch.yml --limit 1 --json databaseId,status,url,createdAt | ConvertFrom-Json
if($run){
  Write-Host "Run=$($run.databaseId) Status=$($run.status)"
  Write-Host $run.url
}else{
  Write-Host 'Workflow enviado; todavía no aparece en la lista.'
}