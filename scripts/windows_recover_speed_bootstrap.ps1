$ErrorActionPreference='Stop'
$base='https://raw.githubusercontent.com/israel2811/nexus-core/main/scripts'
$tmp=Join-Path $env:TEMP 'NEXUS-RECOVER-SPEED'
New-Item -ItemType Directory -Force $tmp | Out-Null
$files=@('windows_speed_now.ps1','desktop_commander_singleton.ps1')
foreach($f in $files){
 $dst=Join-Path $tmp $f
 Invoke-WebRequest -UseBasicParsing "$base/$f" -OutFile $dst
 if(!(Test-Path $dst)){ throw "No se pudo descargar $f" }
}
Write-Host '=== NEXUS SPEED + ALT ==='
& (Join-Path $tmp 'windows_speed_now.ps1') -Aggressive
Write-Host '=== NEXUS DESKTOP COMMANDER SINGLETON ==='
& (Join-Path $tmp 'desktop_commander_singleton.ps1')
Write-Host '=== FINAL ==='
$os=Get-CimInstance Win32_OperatingSystem
$cpu=(Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
Write-Host "CPU=$cpu RAM_FREE_GB=$([math]::Round($os.FreePhysicalMemory/1MB,2))"
Write-Host 'Deja esta ventana abierta 15 segundos mientras Desktop Commander se registra.'
Start-Sleep 15
Get-ScheduledTask -TaskName 'NEXUS Desktop Commander Singleton' -ErrorAction SilentlyContinue | Select-Object TaskName,State
