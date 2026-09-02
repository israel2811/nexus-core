[CmdletBinding()]
param(
    [ValidateSet('health','state','route','submit','wait')]
    [string]$Action = 'health',
    [string]$Task = '',
    [ValidateSet('repo-inventory','hash-tree','source-search','health-snapshot')]
    [string]$Kind = 'repo-inventory',
    [string]$Path = '',
    [string]$Query = '',
    [string]$JobId = '',
    [int]$TimeoutSec = 60
)

$ErrorActionPreference = 'Stop'
$BaseUri = 'http://127.0.0.1:8765'
$KeyPath = Join-Path $PSScriptRoot 'token'

function Get-NexusHeaders {
    if (-not (Test-Path -LiteralPath $KeyPath -PathType Leaf)) {
        throw "NEXUS offload token missing: $KeyPath"
    }
    $key = (Get-Content -LiteralPath $KeyPath -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($key)) { throw 'NEXUS offload token is empty.' }
    return @{ 'X-Nexus-Key' = $key }
}

function Write-ResultJson($Value) {
    $Value | ConvertTo-Json -Depth 20 -Compress
}

switch ($Action) {
    'health' {
        Write-ResultJson (Invoke-RestMethod -Uri "$BaseUri/health" -Method Get -TimeoutSec 5)
        break
    }
    'state' {
        Write-ResultJson (Invoke-RestMethod -Uri "$BaseUri/state" -Headers (Get-NexusHeaders) -Method Get -TimeoutSec 5)
        break
    }
    'route' {
        $encoded = [uri]::EscapeDataString($Task)
        Write-ResultJson (Invoke-RestMethod -Uri "$BaseUri/route?task=$encoded" -Headers (Get-NexusHeaders) -Method Get -TimeoutSec 5)
        break
    }
    'submit' {
        $payload = @{ kind = $Kind; path = $Path; query = $Query } | ConvertTo-Json -Compress
        Write-ResultJson (Invoke-RestMethod -Uri "$BaseUri/submit" -Headers (Get-NexusHeaders) -Method Post -ContentType 'application/json' -Body $payload -TimeoutSec 10)
        break
    }
    'wait' {
        if ([string]::IsNullOrWhiteSpace($JobId)) { throw 'JobId is required for wait.' }
        $deadline = [DateTime]::UtcNow.AddSeconds([Math]::Max(1, $TimeoutSec))
        $job = $null
        do {
            $encodedId = [uri]::EscapeDataString($JobId)
            $job = Invoke-RestMethod -Uri "$BaseUri/job?id=$encodedId" -Headers (Get-NexusHeaders) -Method Get -TimeoutSec 5
            if ($job.status -in @('completed','failed','cancelled-after-validation','deferred-busy')) {
                Write-ResultJson $job
                break
            }
            Start-Sleep -Milliseconds 500
        } while ([DateTime]::UtcNow -lt $deadline)
        if (-not $job -or $job.status -notin @('completed','failed','cancelled-after-validation','deferred-busy')) {
            throw "Timed out waiting for NEXUS job $JobId (last status: $($job.status))."
        }
        break
    }
}
