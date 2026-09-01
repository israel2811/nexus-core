$ErrorActionPreference='SilentlyContinue'
$base=Join-Path $env:LOCALAPPDATA 'NEXUS'
New-Item -ItemType Directory -Force $base | Out-Null
$runner=Join-Path $base 'desktop-commander-singleton.ps1'
$log=Join-Path $base 'desktop-commander-singleton.log'
@'
$ErrorActionPreference='Continue'
$mutex=New-Object System.Threading.Mutex($false,'Global\NEXUS-DesktopCommander-047')
try { if(-not $mutex.WaitOne(0,$false)){ exit 0 } } catch { exit 0 }
Remove-Item Env:NODE_TLS_REJECT_UNAUTHORIZED -ErrorAction SilentlyContinue
while($true){
 try {
   & "$env:ProgramFiles\nodejs\npx.cmd" -y '@wonderwhy-er/desktop-commander@0.2.47' remote *>> "$env:LOCALAPPDATA\NEXUS\desktop-commander-singleton.log"
 } catch { $_ | Out-String | Add-Content "$env:LOCALAPPDATA\NEXUS\desktop-commander-singleton.log" }
 Start-Sleep -Seconds 8
}
'@ | Set-Content $runner -Encoding UTF8
# Stop legacy wrappers first; their child processes are duplicate remote agents.
Get-CimInstance Win32_Process | Where-Object {
 $_.CommandLine -match 'dc-loop\.ps1|RemoteDC-Watchdog\.ps1|desktop-commander\.ps1' -and
 $_.CommandLine -notmatch 'desktop-commander-singleton\.ps1'
} | ForEach-Object { taskkill /PID $_.ProcessId /T /F | Out-Null }
foreach($t in @('NEXUS Remote Desktop Commander','NEXUS Desktop Commander','NEXUS Desktop Commander Singleton')){
 Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue
}
$action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$runner`""
$trigger=New-ScheduledTaskTrigger -AtLogOn
$settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 20 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
Register-ScheduledTask -TaskName 'NEXUS Desktop Commander Singleton' -Action $action -Trigger $trigger -Settings $settings -Description 'Single resilient Desktop Commander 0.2.47 agent' | Out-Null
Start-ScheduledTask -TaskName 'NEXUS Desktop Commander Singleton'
Write-Host 'DC_SINGLETON_INSTALLED'
Start-Sleep 5
Get-ScheduledTask -TaskName 'NEXUS Desktop Commander Singleton' | Select-Object TaskName,State
Get-Content $log -Tail 15 -ErrorAction SilentlyContinue
