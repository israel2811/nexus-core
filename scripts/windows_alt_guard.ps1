$ErrorActionPreference='SilentlyContinue'
$root='C:\NEXUS_AGENT\keyboard'
New-Item -ItemType Directory -Force $root | Out-Null
$log=Join-Path $root 'altguard.log'
$mutex=New-Object Threading.Mutex($false,'Local\NEXUS-AltGuard')
if(-not $mutex.WaitOne(0)){exit}

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class NexusKeys {
 [DllImport("user32.dll")] public static extern short GetKeyState(int vKey);
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
 [DllImport("user32.dll")] public static extern void keybd_event(byte vKey, byte scan, uint flags, UIntPtr extra);
}
'@
$KEYUP=2
$keys=@{
  18='ALT'; 164='LALT'; 165='RALT'; 115='F4'; 116='F5'
}
$stale=@{}
foreach($vk in $keys.Keys){$stale[$vk]=0}
function LogicalDown([int]$vk){(([NexusKeys]::GetKeyState($vk)-band 0x8000)-ne 0)}
function PhysicalDown([int]$vk){(([NexusKeys]::GetAsyncKeyState($vk)-band 0x8000)-ne 0)}
function ReleaseKey([int]$vk){[NexusKeys]::keybd_event([byte]$vk,0,$KEYUP,[UIntPtr]::Zero)}

"$(Get-Date -Format o) guard_start"|Add-Content $log
while($true){
  foreach($vk in $keys.Keys){
    $logical=LogicalDown $vk
    $physical=PhysicalDown $vk
    if($logical -and -not $physical){$stale[$vk]++}else{$stale[$vk]=0}
    if($stale[$vk] -ge 8){
      ReleaseKey $vk
      "$(Get-Date -Format o) corrected=$($keys[$vk])"|Add-Content $log
      $stale[$vk]=0
    }
  }
  Start-Sleep -Milliseconds 250
}
