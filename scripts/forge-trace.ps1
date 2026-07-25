# scripts/forge-trace.ps1
# Sends structured trace/span telemetry from Copilot Forge to the Langfuse ingestion API.
# Usage: .\forge-trace.ps1 -ReqId REQ-001 -Phase spec -Input "..." -Output "..." -TokensIn 1200 -TokensOut 900

param(
    [string]$ReqId        = "REQ-GENERAL",
    [string]$Phase        = "general",
    [string]$Event        = "trace",      # "trace" or "span"
    [string]$Input        = "",
    [string]$Output       = "",
    [int]   $TokensIn     = 0,
    [int]   $TokensOut    = 0,
    [string]$Status       = "success",    # "success" | "error"
    [string]$ErrorMessage = "",
    [string]$ParentTraceId = ""
)

# 1. Parse .env.local into a local hashtable (no SetEnvironmentVariable needed)
$config = @{}
$envFile = Join-Path $PSScriptRoot "..\\.env.local"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $parts = $line.Split("=", 2)
            $config[$parts[0].Trim()] = $parts[1].Trim().Trim('"').Trim("'")
        }
    }
}

# 2. Resolve config — env vars take precedence over .env.local
$hostUrl   = if ($env:LANGFUSE_HOST)       { $env:LANGFUSE_HOST }       else { $config["LANGFUSE_HOST"] }
$publicKey = if ($env:LANGFUSE_PUBLIC_KEY) { $env:LANGFUSE_PUBLIC_KEY } else { $config["LANGFUSE_PUBLIC_KEY"] }
$secretKey = if ($env:LANGFUSE_SECRET_KEY) { $env:LANGFUSE_SECRET_KEY } else { $config["LANGFUSE_SECRET_KEY"] }

# 3. Graceful degradation if unconfigured
if (-not $hostUrl -or -not $publicKey -or -not $secretKey -or $publicKey -like "pk-lf-your*") {
    Write-Host "[forge-trace] Langfuse unconfigured. Skipping trace ingestion." -ForegroundColor Yellow
    exit 0
}

# 4. Build ingestion payload
$now      = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$traceId  = if ($ParentTraceId) { $ParentTraceId } else { "$ReqId-$(Get-Date -Format 'yyyyMMddHHmmss')" }
$eventId  = [Guid]::NewGuid().ToString()
$spanType = if ($Event -eq "span") { "span-create" } else { "trace-create" }
$bodyId   = if ($Event -eq "span") { $eventId } else { $traceId }

$body = @{
    id       = $bodyId
    traceId  = $traceId
    name     = "forge-$Phase"
    input    = $Input
    output   = $Output
    metadata = @{
        reqId     = $ReqId
        phase     = $Phase
        status    = $Status
        error     = $ErrorMessage
        tokensIn  = $TokensIn
        tokensOut = $TokensOut
        host      = $env:COMPUTERNAME
    }
}

if ($TokensIn -gt 0 -or $TokensOut -gt 0) {
    $body["usage"] = @{ input = $TokensIn; output = $TokensOut; total = ($TokensIn + $TokensOut) }
}

$payload = @{ batch = @(@{ id = $eventId; timestamp = $now; type = $spanType; body = $body }) } `
           | ConvertTo-Json -Depth 6

# 5. Build Basic Auth header
$encodedAuth = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($publicKey):$($secretKey)"))
$headers = @{ "Authorization" = "Basic $encodedAuth"; "Content-Type" = "application/json" }

# 6. POST to Langfuse
try {
    $uri      = "$($hostUrl.TrimEnd('/'))/api/public/ingestion"
    $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $payload -TimeoutSec 8 -ErrorAction Stop
    $success  = $response.successes.Count -gt 0
    if ($success) {
        Write-Host "[forge-trace] [+] Trace emitted: forge-$Phase ($Status) -> $traceId" -ForegroundColor Green
    } else {
        Write-Host "[forge-trace] [-] Ingestion returned errors: $($response.errors | ConvertTo-Json)" -ForegroundColor Red
    }
} catch {
    Write-Host "[forge-trace] [!] Could not reach Langfuse at $hostUrl - $($_.Exception.Message)" -ForegroundColor Yellow
}
