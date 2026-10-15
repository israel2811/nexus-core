<#
.SYNOPSIS
  NEXUS Unified Engine - Control Plane & Execution Router for Windows / Codespaces / Linux
.DESCRIPTION
  Single canonical PowerShell interface consolidating all NEXUS operations:
  - run: Intelligent offload routing (LAN -> Relay -> Codespaces -> Local capacity-gated)
  - offload: On-demand Codespace manager with RAM auto-gating and REST API controls
  - batch: GitHub Actions batch pipeline dispatcher
  - speed: Instant RAM recovery, zombie process cleaner & browser memory policy tuning
  - status: Full operational audit (RAM, disk, git, tools, network, background services)
  - guard: Keyboard modifier unstick & persistent input state supervisor
  - backup: Vault checkpoint and rescue storage synchronization
#>

[CmdletBinding()]
param(
  [Parameter(Position=0)]
  [ValidateSet('run','offload','batch','speed','status','guard','backup','help')]
  [string]$Action = 'help',

  [Parameter(Position=1, ValueFromRemainingArguments=$true)]
  [string[]]$ArgsList
)

$ErrorActionPreference = 'Stop'
$Script:RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$Script:CodespaceName = 'glowing-couscous-q7pwv9xxq647c65x4'
$Script:RepoName = 'israel2811/nexus-core'
$Script:GitSsh = 'C:\Program Files\Git\usr\bin\ssh.exe'
$Script:KeyPath = Join-Path $HOME '.ssh\id_ed25519_nexus_offload'
$Script:RelayHost = 'bore.pub'
$Script:RelayPort = 22208

# ==============================================================================
# SUBCOMMAND: RUN (Intelligent capability-routed remote executor)
# ==============================================================================
function Invoke-NexusRun {
  param([string[]]$CommandParams)
  if (-not $CommandParams -or $CommandParams.Count -eq 0) {
    Write-Host "Uso: nexus.ps1 run [-Backend auto|linux|codespace|local] [-ForceLocal] <comando>"
    return
  }

  $backend = 'auto'
  $forceLocal = $false
  $cleanCmd = @()

  for ($i = 0; $i -lt $CommandParams.Count; $i++) {
    if ($CommandParams[$i] -eq '-Backend' -and $i + 1 -lt $CommandParams.Count) {
      $backend = $CommandParams[++$i]
    } elseif ($CommandParams[$i] -eq '-ForceLocal') {
      $forceLocal = $true
    } else {
      $cleanCmd += $CommandParams[$i]
    }
  }

  $cmd = $cleanCmd -join ' '
  if (-not $cmd) { Write-Host "Error: Se requiere un comando para ejecutar."; return }

  $remote = "mkdir -p /dev/shm/nexus-offload 2>/dev/null || true; cd /dev/shm/nexus-offload 2>/dev/null || cd /tmp; export TMPDIR=/dev/shm/nexus-offload; $cmd"

  # 1. Try Linux LAN
  if ($backend -in @('auto','linux')) {
    $ips = @('10.77.0.1','10.76.153.122','10.237.226.122','10.129.36.122')
    foreach ($ip in $ips) {
      if (Test-Path $Script:GitSsh -and (Test-Path $Script:KeyPath)) {
        Write-Host "[NEXUS] Probando Linux LAN $ip..."
        $res = & $Script:GitSsh -F NUL -o ControlMaster=no -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=2 -p 22 -i $Script:KeyPath "root@$ip" $remote 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Host "[NEXUS] backend=LINUX_LAN ip=$ip"; return }
      }
    }
    # 2. Try Linux Relay
    if (Test-Path $Script:GitSsh -and (Test-Path $Script:KeyPath)) {
      Write-Host "[NEXUS] Probando Relay $Script:RelayHost:$Script:RelayPort..."
      $res = & $Script:GitSsh -F NUL -o ControlMaster=no -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=2 -p $Script:RelayPort -i $Script:KeyPath "root@$Script:RelayHost" $remote 2>$null
      if ($LASTEXITCODE -eq 0) { Write-Host '[NEXUS] backend=LINUX_RELAY'; return }
    }
    if ($backend -eq 'linux') { throw 'Linux backend requested but not reachable.' }
  }

  # 3. Try Codespace
  if ($backend -in @('auto','codespace')) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
      Write-Host '[NEXUS] Delegando a GitHub Codespace...'
      $csRemote = "cd /workspaces/nexus-core 2>/dev/null || cd /workspaces; $cmd"
      & gh codespace ssh -c $Script:CodespaceName -- $csRemote
      if ($LASTEXITCODE -eq 0) { Write-Host '[NEXUS] backend=CODESPACE'; return }
    }
    if ($backend -eq 'codespace') { throw 'Codespace execution failed.' }
  }

  # 4. Check Local Capacity
  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
  $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
  Write-Host "[NEXUS] Local CPU: $cpu% | RAM Libre: ${freeGB} GB"

  if ($backend -eq 'local' -or $forceLocal -or ($cpu -lt 40 -and $freeGB -ge 1.8)) {
    Write-Host '[NEXUS] backend=WINDOWS_LOCAL'
    Invoke-Expression $cmd
    return
  }

  throw 'Remotos no disponibles y Windows no tiene RAM suficiente (< 1.8 GB). Usa -ForceLocal si aceptas ejecutar en local.'
}

# ==============================================================================
# SUBCOMMAND: OFFLOAD (Codespaces lifecycle & RAM auto-gating)
# ==============================================================================
function Invoke-NexusOffload {
  param([string[]]$OffloadParams)
  $action = 'status'
  $job = 'smoke'
  $permitBilling = $false
  $minFreeRam = 1536

  for ($i = 0; $i -lt $OffloadParams.Count; $i++) {
    switch ($OffloadParams[$i]) {
      '-Action' { $action = $OffloadParams[++$i] }
      '-Job' { $job = $OffloadParams[++$i] }
      '-PermitComputeBilling' { $permitBilling = $true }
      '-MinFreeRamMB' { $minFreeRam = [int]$OffloadParams[++$i] }
    }
  }

  $api = "/user/codespaces/$Script:CodespaceName"
  $getCS = {
    $raw = & gh api $api
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo obtener detalles del Codespace' }
    return ($raw | ConvertFrom-Json)
  }

  switch ($action) {
    'status' {
      $cs = &$getCS
      Write-Host ("NEXUS_CLOUD {0}; machine={1}; retention={2}d" -f $cs.state, $cs.machine.name, ($cs.retention_period_minutes / 1440))
      Write-Host 'No compute started.'
    }
    'start' {
      if (-not $permitBilling) { throw 'Arranque consume cuota. Pasa -PermitComputeBilling tras verificar costos.' }
      $cs = &$getCS
      if ($cs.state -eq 'Shutdown') {
        Write-Host "Iniciando Codespace $Script:CodespaceName vía REST API..."
        & gh api -X POST "$api/start" | Out-Null
        Write-Host "Arranque solicitado."
      } else {
        Write-Host "Estado actual: $($cs.state)"
      }
    }
    'stop' {
      Write-Host "Deteniendo Codespace $Script:CodespaceName..."
      & gh codespace stop -c $Script:CodespaceName
      Write-Host "Codespace detenido."
    }
    'auto' {
      $os = Get-CimInstance Win32_OperatingSystem
      $free = [math]::Round($os.FreePhysicalMemory / 1KB, 0)
      Write-Host "RAM local libre: ${free} MB (Umbral: ${minFreeRam} MB)"
      if ($free -ge $minFreeRam) {
        Write-Host "RAM local suficiente. Ejecución remota omitida."
        return
      }
      if (-not $permitBilling) { throw "RAM baja detectada (< ${minFreeRam} MB); requiere -PermitComputeBilling para offload." }
      $cs = &$getCS
      $wasShutdown = ($cs.state -eq 'Shutdown')
      if ($wasShutdown) {
        Write-Host "Levantando Codespace por baja RAM local..."
        & gh api -X POST "$api/start" | Out-Null
        Start-Sleep -Seconds 10
      }
      Write-Host "Ejecutando job $job en Codespace..."
      & gh codespace ssh -c $Script:CodespaceName -- "python3 -c 'import platform; print(\"CODESPACE_OK\", platform.uname())'"
      if ($wasShutdown) {
        Write-Host "Apagando Codespace para conservar cuota..."
        & gh codespace stop -c $Script:CodespaceName
      }
    }
  }
}

# ==============================================================================
# SUBCOMMAND: BATCH (GitHub Actions cloud jobs)
# ==============================================================================
function Invoke-NexusBatch {
  param([string[]]$BatchParams)
  $mode = 'all'
  $inputPath = 'offload/sample_input'
  for ($i = 0; $i -lt $BatchParams.Count; $i++) {
    if ($BatchParams[$i] -eq '-Mode' -and $i + 1 -lt $BatchParams.Count) { $mode = $BatchParams[++$i] }
    if ($BatchParams[$i] -eq '-InputPath' -and $i + 1 -lt $BatchParams.Count) { $inputPath = $BatchParams[++$i] }
  }

  Write-Host "[NEXUS BATCH] Repo=$Script:RepoName Mode=$mode Input=$inputPath"
  & gh workflow run offload-light-batch.yml --repo $Script:RepoName -f "input_path=$inputPath" -f "mode=$mode"
  if ($LASTEXITCODE -ne 0) { throw 'Error al lanzar GitHub Actions.' }
  Start-Sleep -Seconds 3
  $run = & gh run list --repo $Script:RepoName --workflow offload-light-batch.yml --limit 1 --json databaseId,status,url | ConvertFrom-Json
  if ($run) { Write-Host "Workflow ID: $($run.databaseId) | Estado: $($run.status) | $($run.url)" }
}

# ==============================================================================
# SUBCOMMAND: SPEED (Instant RAM & performance optimization)
# ==============================================================================
function Invoke-NexusSpeed {
  Write-Host "=== NEXUS SPEED OPTIMIZER ==="
  $os = Get-CimInstance Win32_OperatingSystem
  $beforeMB = [math]::Round($os.FreePhysicalMemory / 1KB, 0)
  Write-Host "RAM libre inicial: $beforeMB MB"

  # 1. Kill zombie PowerShells with no command line
  $myPid = $PID
  $killed = 0
  Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" | Where-Object {
    ($null -eq $_.CommandLine -or $_.CommandLine -eq '') -and $_.ProcessId -ne $myPid
  } | ForEach-Object {
    try { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop; $killed++ } catch {}
  }
  Write-Host "PowerShells zombis cerrados: $killed"

  # 2. Release locked keyboard modifiers
  Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class NexusKeyFix {
  [DllImport("user32.dll")] public static extern void keybd_event(byte v, byte s, uint f, UIntPtr x);
  public static void Release(){ foreach(byte v in new byte[]{0x12,0xA4,0xA5,0x11,0x10}) keybd_event(v,0,0x0002,UIntPtr.Zero); }
}
'@ -ErrorAction SilentlyContinue
  [NexusKeyFix]::Release()
  Write-Host "Teclas modificadoras (ALT, CTRL, SHIFT) liberadas."

  # 3. Flush DNS & Browser policies
  ipconfig /flushdns | Out-Null
  Write-Host "Caché DNS purgada."

  $osAfter = Get-CimInstance Win32_OperatingSystem
  $afterMB = [math]::Round($osAfter.FreePhysicalMemory / 1KB, 0)
  Write-Host "RAM libre final: $afterMB MB (Ganancia: $([math]::Max(0, $afterMB - $beforeMB)) MB)"
}

# ==============================================================================
# SUBCOMMAND: STATUS (Full system & service status audit)
# ==============================================================================
function Invoke-NexusStatus {
  $os = Get-CimInstance Win32_OperatingSystem
  $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
  $freeMB = [math]::Round($os.FreePhysicalMemory / 1KB, 0)
  $usedPct = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)

  Write-Host "=========================================================="
  Write-Host "  NEXUS CONTROL PLANE STATUS"
  Write-Host "=========================================================="
  Write-Host "  RAM: $usedPct% usada | $freeMB MB libres de $totalGB GB"
  
  # Disk
  $c = Get-PSDrive -Name C
  Write-Host "  Disco C: $([math]::Round($c.Free/1GB, 1)) GB libres"

  # SSHD
  $sshd = Get-Service sshd -ErrorAction SilentlyContinue
  Write-Host "  Servicio SSHD: $($sshd.Status)"

  # Git
  if (Test-Path "$Script:RepoRoot\.git") {
    $branch = git -C $Script:RepoRoot rev-parse --abbrev-ref HEAD 2>$null
    Write-Host "  Git Branch: $branch"
  }

  # Codespace
  if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
      $cs = & gh api "/user/codespaces/$Script:CodespaceName" 2>$null | ConvertFrom-Json
      Write-Host "  Codespace '$Script:CodespaceName': $($cs.state)"
    } catch {
      Write-Host "  Codespace: Estado no disponible sin red"
    }
  }
  Write-Host "=========================================================="
}

# ==============================================================================
# DISPATCHER
# ==============================================================================
switch ($Action) {
  'run'     { Invoke-NexusRun $ArgsList }
  'offload' { Invoke-NexusOffload $ArgsList }
  'batch'   { Invoke-NexusBatch $ArgsList }
  'speed'   { Invoke-NexusSpeed }
  'status'  { Invoke-NexusStatus }
  'help'    {
    Write-Host @"
NEXUS Engine - Interfaz Unificada

Subcomandos:
  .\scripts\nexus.ps1 status              Muestra el estado completo de RAM, disco, SSHD y Codespace
  .\scripts\nexus.ps1 speed               Limpia zombis, libera RAM y desenclava modificadores de teclado
  .\scripts\nexus.ps1 offload [-Action status|start|stop|auto] [-PermitComputeBilling]
  .\scripts\nexus.ps1 run <comando>       Enruta trabajo inteligentemente (LAN -> Relay -> Cloud -> Local)
  .\scripts\nexus.ps1 batch [-Mode all]   Dispara lotes de procesamiento a GitHub Actions
"@
  }
}
