param(
    [string]$Endpoint = "http://192.168.1.124:4318",
    [ValidateSet("Code", "Code - Insiders")]
    [string]$Target = "Code",
    [switch]$EnableNetworkSandbox,
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"

if ($Endpoint.EndsWith("/")) {
    $Endpoint = $Endpoint.TrimEnd("/")
}

$settingsDir = Join-Path $env:APPDATA "$Target\User"
$settingsPath = Join-Path $settingsDir "settings.json"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Set-JsonProperty($Object, [string]$Name, $Value) {
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    } else {
        $property.Value = $Value
    }
}

New-Item -ItemType Directory -Force -Path $settingsDir | Out-Null

if (Test-Path -LiteralPath $settingsPath) {
    $raw = [System.IO.File]::ReadAllText($settingsPath)
    if ([string]::IsNullOrWhiteSpace($raw)) {
        $settings = [pscustomobject]@{}
    } else {
        $settings = $raw | ConvertFrom-Json
    }

    if (-not $NoBackup) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "$settingsPath.epoptes-backup-$stamp"
        Copy-Item -LiteralPath $settingsPath -Destination $backupPath
    }
} else {
    $settings = [pscustomobject]@{}
}

Set-JsonProperty $settings "github.copilot.chat.otel.enabled" $true
Set-JsonProperty $settings "github.copilot.chat.otel.otlpEndpoint" $Endpoint
Set-JsonProperty $settings "github.copilot.chat.agent.modelDetails.enabled" $true
Set-JsonProperty $settings "github.copilot.chat.agent.backgroundTodoAgent.enabled" $true

if ($EnableNetworkSandbox) {
    Set-JsonProperty $settings "chat.agent.sandbox.enabled" "allowNetwork"
}

$json = $settings | ConvertTo-Json -Depth 64
[System.IO.File]::WriteAllText($settingsPath, $json + [Environment]::NewLine, $utf8NoBom)

Write-Host "Installed Epoptes VS Code integration." -ForegroundColor Green
Write-Host "Settings: $settingsPath"
Write-Host "OTLP:     $Endpoint"
Write-Host ""
Write-Host "Restart VS Code, then run an agent task to produce telemetry."
