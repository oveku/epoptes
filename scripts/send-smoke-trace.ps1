param(
    [string]$Endpoint = "http://192.168.1.124:4318",
    [string]$ServiceName = "epoptes-vscode-client",
    [string]$SpanName = "epoptes.vscode.integration.smoke"
)

$ErrorActionPreference = "Stop"

if ($Endpoint.EndsWith("/")) {
    $Endpoint = $Endpoint.TrimEnd("/")
}

function New-HexId([int]$ByteCount) {
    $bytes = New-Object byte[] $ByteCount
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }

    return ([BitConverter]::ToString($bytes)).Replace("-", "").ToLowerInvariant()
}

$start = [DateTimeOffset]::UtcNow
Start-Sleep -Milliseconds 25
$end = [DateTimeOffset]::UtcNow

$traceId = New-HexId 16
$spanId = New-HexId 8
$startNs = ([int64]$start.ToUnixTimeMilliseconds()) * 1000000
$endNs = ([int64]$end.ToUnixTimeMilliseconds()) * 1000000
$hostName = [System.Net.Dns]::GetHostName()

$payload = @{
    resourceSpans = @(
        @{
            resource = @{
                attributes = @(
                    @{ key = "service.name"; value = @{ stringValue = $ServiceName } },
                    @{ key = "service.namespace"; value = @{ stringValue = "pantheon" } },
                    @{ key = "deployment.environment"; value = @{ stringValue = "dev" } },
                    @{ key = "host.name"; value = @{ stringValue = $hostName } }
                )
            }
            scopeSpans = @(
                @{
                    scope = @{
                        name = "epoptes.vscode.integration"
                        version = "0.1.0"
                    }
                    spans = @(
                        @{
                            traceId = $traceId
                            spanId = $spanId
                            name = $SpanName
                            kind = 1
                            startTimeUnixNano = "$startNs"
                            endTimeUnixNano = "$endNs"
                            attributes = @(
                                @{ key = "epoptes.client"; value = @{ stringValue = "vscode" } },
                                @{ key = "epoptes.otlp_endpoint"; value = @{ stringValue = $Endpoint } },
                                @{ key = "workspace.path"; value = @{ stringValue = (Resolve-Path ".").Path } }
                            )
                            status = @{
                                code = 1
                            }
                        }
                    )
                }
            )
        }
    )
}

$json = $payload | ConvertTo-Json -Depth 32 -Compress
$uri = "$Endpoint/v1/traces"

Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $json | Out-Null

Write-Host "Sent Epoptes smoke trace." -ForegroundColor Green
Write-Host "TraceId: $traceId"
Write-Host "Endpoint: $uri"
