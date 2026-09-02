$ErrorActionPreference = 'Stop'
$root = 'C:\NEXUS_AGENT\keyboard'
New-Item -ItemType Directory -Force $root | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$log = Join-Path $root "normalize_$stamp.log"
$kp = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'

# Remove only legacy driver-level remaps; preserve an exact binary backup first.
$map = (Get-ItemProperty $kp -Name 'Scancode Map' -ErrorAction SilentlyContinue).'Scancode Map'
if ($map) {
  [IO.File]::WriteAllBytes((Join-Path $root "ScancodeMap_$stamp.bin"), [byte[]]$map)
  Remove-ItemProperty $kp -Name 'Scancode Map' -ErrorAction Stop
  'Removed legacy Scancode Map.' | Add-Content $log
} else {
  'No Scancode Map present.' | Add-Content $log
}

# Old BLOQUEO_ALT must never compete with the normal keyboard stack again.
$t = Get-ScheduledTask -TaskName 'BLOQUEO_ALT' -ErrorAction SilentlyContinue
if ($t) {
  Disable-ScheduledTask -TaskName 'BLOQUEO_ALT' | Out-Null
  'Disabled legacy task: BLOQUEO_ALT' | Add-Content $log
}

# Disable accessibility activation hotkeys while leaving accessibility components installed.
$flags = @{
  'HKCU:\Control Panel\Accessibility\StickyKeys'='506'
  'HKCU:\Control Panel\Accessibility\Keyboard Response'='122'
  'HKCU:\Control Panel\Accessibility\ToggleKeys'='58'
}
foreach($path in $flags.Keys){
  if(Test-Path $path){ Set-ItemProperty $path -Name Flags -Value $flags[$path] }
}
'Accessibility keyboard hotkeys normalized.' | Add-Content $log

# Preserve old worker for forensics, but never execute it.
$legacy = "$env:LOCALAPPDATA\AltKeyboardFix\FixAltKeyboardWorker.ps1"
if (Test-Path $legacy) {
  $bak="$legacy.bak_$stamp"
  Copy-Item $legacy $bak -Force
  "Legacy worker preserved: $bak" | Add-Content $log
}

Get-PnpDevice -Class Keyboard -ErrorAction SilentlyContinue |
  Select-Object Status,FriendlyName,InstanceId |
  Out-String | Add-Content $log
Get-Content $log
