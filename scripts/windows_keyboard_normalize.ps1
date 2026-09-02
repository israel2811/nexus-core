$ErrorActionPreference = 'Stop'
$root = 'C:\NEXUS_AGENT\keyboard'
New-Item -ItemType Directory -Force $root | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$log = Join-Path $root "normalize_$stamp.log"
$kp = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
$map = (Get-ItemProperty $kp -Name 'Scancode Map' -ErrorAction SilentlyContinue).'Scancode Map'
if ($map) {
  [IO.File]::WriteAllBytes((Join-Path $root "ScancodeMap_$stamp.bin"), [byte[]]$map)
  Remove-ItemProperty $kp -Name 'Scancode Map' -ErrorAction Stop
  'Removed Scancode Map; reboot required for driver-level remap to disappear.' | Add-Content $log
} else {
  'No Scancode Map present.' | Add-Content $log
}
foreach ($name in @('BLOQUEO_ALT')) {
  $t = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
  if ($t) { Disable-ScheduledTask -TaskName $name | Out-Null; "Disabled task: $name" | Add-Content $log }
}
$legacy = "$env:LOCALAPPDATA\AltKeyboardFix\FixAltKeyboardWorker.ps1"
if (Test-Path $legacy) {
  Copy-Item $legacy "$legacy.bak_$stamp" -Force
  "Legacy worker preserved at $legacy.bak_$stamp; not executed." | Add-Content $log
}
Get-PnpDevice -Class Keyboard -ErrorAction SilentlyContinue | Select-Object Status,FriendlyName,InstanceId | Out-String | Add-Content $log
Get-Content $log
