[CmdletBinding()]
param()
$ErrorActionPreference='SilentlyContinue'

$cpuSamples=(Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
$cpuAvg=[math]::Round((($cpuSamples|Measure-Object -Average).Average),1)
$avail=(Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$cpu=Get-CimInstance Win32_Processor | Select-Object -First 1 Name,LoadPercentage,CurrentClockSpeed,MaxClockSpeed
$cs=Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model,TotalPhysicalMemory
$bios=Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion,ReleaseDate
$battery=Get-CimInstance Win32_Battery | Select-Object Name,BatteryStatus,EstimatedChargeRemaining
$scheme=(powercfg /getactivescheme 2>$null) -join ' '

$thermal=@()
Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature | ForEach-Object {
    $c=($_.CurrentTemperature/10)-273.15
    $thermal += [pscustomobject]@{Instance=$_.InstanceName;Celsius=[math]::Round($c,1)}
}

$event37=Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-Kernel-Processor-Power';Id=37} -MaxEvents 12 | ForEach-Object {
    [pscustomobject]@{Time=$_.TimeCreated.ToString('o');Message=$_.Message}
}

$interesting=@('brave','ChatGPT','codex','node','powershell','pwsh','WmiPrvSE','sshd','conhost','csc','msedgewebview2')
$procs=Get-Process | Where-Object { $interesting -contains $_.ProcessName } | Sort-Object WorkingSet64 -Descending | ForEach-Object {
    [pscustomobject]@{Name=$_.ProcessName;Id=$_.Id;Session=$_.SessionId;MB=[math]::Round($_.WorkingSet64/1MB,1);CPU_s=[math]::Round($_.CPU,1);Window=$_.MainWindowTitle}
}

[pscustomobject]@{
    Time=(Get-Date).ToString('o')
    CpuAveragePct=$cpuAvg
    AvailableMemoryMB=[math]::Round($avail,0)
    Computer=$cs
    BIOS=$bios
    CPU=$cpu
    Battery=$battery
    ActivePowerScheme=$scheme
    Thermal=$thermal
    Event37=$event37
    Processes=$procs
} | ConvertTo-Json -Depth 8
