param([switch]$Aggressive)
$ErrorActionPreference='SilentlyContinue'
$root=Join-Path $env:LOCALAPPDATA 'NEXUS\speed-now'
New-Item -ItemType Directory -Force $root | Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$log=Join-Path $root "speed_$stamp.log"
function Snap($tag){
  $os=Get-CimInstance Win32_OperatingSystem
  $cpu=(Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
  "$tag CPU=$cpu RAM_FREE_GB=$([math]::Round($os.FreePhysicalMemory/1MB,2))" | Tee-Object -FilePath $log -Append
}
Snap 'BEFORE'
# Release stuck ALT state without touching keyboard mappings.
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class NexusKeys {
 [DllImport("user32.dll")] public static extern void keybd_event(byte v, byte s, uint f, UIntPtr x);
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int v);
 public static void ReleaseAlt(){ foreach(byte v in new byte[]{0x12,0xA4,0xA5}) keybd_event(v,0,0x0002,UIntPtr.Zero); }
}
'@
[NexusKeys]::ReleaseAlt()
# Back up and disable accessibility latch/hotkeys that can lock modifiers.
$acc=Join-Path $root "accessibility_$stamp.json"
@{
 Sticky=(Get-ItemProperty 'HKCU:\Control Panel\Accessibility\StickyKeys' -Name Flags).Flags
 Filter=(Get-ItemProperty 'HKCU:\Control Panel\Accessibility\Keyboard Response' -Name Flags).Flags
 Toggle=(Get-ItemProperty 'HKCU:\Control Panel\Accessibility\ToggleKeys' -Name Flags).Flags
}|ConvertTo-Json|Set-Content $acc
Set-ItemProperty 'HKCU:\Control Panel\Accessibility\StickyKeys' -Name Flags -Value '506'
Set-ItemProperty 'HKCU:\Control Panel\Accessibility\Keyboard Response' -Name Flags -Value '122'
Set-ItemProperty 'HKCU:\Control Panel\Accessibility\ToggleKeys' -Name Flags -Value '58'
# Browser policies: reclaim background RAM, keep GPU acceleration, no closed-browser background apps.
foreach($p in @('HKCU:\Software\Policies\Google\Chrome','HKCU:\Software\Policies\BraveSoftware\Brave')){
 New-Item -Path $p -Force | Out-Null
 New-ItemProperty -Path $p -Name HighEfficiencyModeEnabled -Type DWord -Value 1 -Force | Out-Null
 New-ItemProperty -Path $p -Name MemorySaverModeSavings -Type DWord -Value 2 -Force | Out-Null
 New-ItemProperty -Path $p -Name BackgroundModeEnabled -Type DWord -Value 0 -Force | Out-Null
 New-ItemProperty -Path $p -Name HardwareAccelerationModeEnabled -Type DWord -Value 1 -Force | Out-Null
 if($Aggressive){ New-ItemProperty -Path $p -Name TotalMemoryLimitMb -Type DWord -Value 3072 -Force | Out-Null }
}
# Favor currently visible browser processes without creating a resident watchdog.
Get-Process chrome,brave -ErrorAction SilentlyContinue | ForEach-Object { try{$_.PriorityClass='AboveNormal'}catch{} }
ipconfig /flushdns | Out-Null
# Stop only known stale NEXUS loop wrappers; do not kill the active Desktop Commander agent itself.
Get-CimInstance Win32_Process | Where-Object {$_.CommandLine -match 'dc-loop\.ps1|RemoteDC-Watchdog\.ps1'} | ForEach-Object { taskkill /PID $_.ProcessId /T /F | Out-Null }
[NexusKeys]::ReleaseAlt()
$altDown=(([NexusKeys]::GetAsyncKeyState(0x12) -band 0x8000) -ne 0)
"ALT_STILL_DOWN=$altDown" | Tee-Object -FilePath $log -Append
Snap 'AFTER'
Write-Host "NEXUS_SPEED_DONE log=$log alt_still_down=$altDown"
Write-Host 'Chrome/Brave policies are reversible; browser restart is needed for GPU policy.'
