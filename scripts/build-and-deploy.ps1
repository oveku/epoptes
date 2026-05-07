# Build Epoptes images on a remote ARM64 build host and deploy them to a runtime host.
#
# Usage:
#   .\scripts\build-and-deploy.ps1 -BuildHost build.example.local -RuntimeHost runtime.example.local -RuntimePath /opt/epoptes
#
# All host parameters can also be set via environment variables:
#   $env:EPOPTES_BUILD_HOST, $env:EPOPTES_RUNTIME_HOST, $env:EPOPTES_RUNTIME_PATH

param(
    [string]$BuildHost     = $env:EPOPTES_BUILD_HOST,
    [string]$RuntimeHost   = $env:EPOPTES_RUNTIME_HOST,
    [string]$BuildPath     = $env:EPOPTES_BUILD_PATH,
    [string]$RuntimePath   = $env:EPOPTES_RUNTIME_PATH,
    [string]$Tag           = "latest",
    [switch]$BuildOnly,
    [switch]$DeployOnly
)

$ErrorActionPreference = "Stop"

function Require-Param($Name, $Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Parameter -$Name (or env EPOPTES_$($Name.ToUpper())) is required."
    }
}

if (-not $DeployOnly) {
    Require-Param "BuildHost" $BuildHost
    if ([string]::IsNullOrWhiteSpace($BuildPath)) {
        # Default to a temp directory on the build host
        $BuildPath = "/tmp/epoptes-build"
    }
}
if (-not $BuildOnly) {
    Require-Param "RuntimeHost" $RuntimeHost
    Require-Param "RuntimePath" $RuntimePath
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$localArtifacts = Join-Path $root "artifacts"
$bundle = Join-Path $env:TEMP "epoptes-source.zip"
$apiArchiveName = "epoptes-api-$Tag-arm64.tar"
$webArchiveName = "epoptes-web-$Tag-arm64.tar"
$apiArchive = Join-Path $localArtifacts $apiArchiveName
$webArchive = Join-Path $localArtifacts $webArchiveName

function Write-Step($Message) {
    Write-Host ""
    Write-Host "--- $Message ---" -ForegroundColor Cyan
}

function Invoke-RemotePowerShell($Host, $ScriptText) {
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptText))
    ssh $Host "powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
    if ($LASTEXITCODE -ne 0) { throw "Remote command on $Host failed" }
}

Set-Location $root
New-Item -ItemType Directory -Force -Path $localArtifacts | Out-Null

if (-not $DeployOnly) {
    Write-Step "Packaging local source for build host"
    $items = Get-ChildItem -Force | Where-Object { $_.Name -notin @(".git", "artifacts", "node_modules", "dist", ".docker-config", ".venv") }
    if (Test-Path -LiteralPath $bundle) { Remove-Item -LiteralPath $bundle -Force }
    Compress-Archive -Path $items.FullName -DestinationPath $bundle -Force

    # The build host can be Windows or POSIX. We use scp for upload and PowerShell over ssh
    # for execution; if your build host is POSIX, replace this with the equivalent shell calls.
    $remoteBundle = "/tmp/epoptes-source.zip"
    Write-Step "Uploading source bundle to $BuildHost"
    scp $bundle "${BuildHost}:$remoteBundle"
    if ($LASTEXITCODE -ne 0) { throw "Failed to upload source bundle to $BuildHost" }

    Write-Step "Expanding source on $BuildHost"
    $prepare = @"
`$ErrorActionPreference = 'Stop'
`$ProgressPreference = 'SilentlyContinue'
`$target = '$BuildPath'
New-Item -ItemType Directory -Force -Path `$target | Out-Null
Expand-Archive -LiteralPath '$remoteBundle' -DestinationPath `$target -Force
"@
    Invoke-RemotePowerShell $BuildHost $prepare

    Write-Step "Building ARM64 images on $BuildHost"
    $build = @"
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$BuildPath'
& '.\scripts\build-on-builder.ps1' -Tag '$Tag'
"@
    Invoke-RemotePowerShell $BuildHost $build

    Write-Step "Downloading built image archives"
    $remotePath = $BuildPath.Replace("\", "/")
    scp "${BuildHost}:$remotePath/artifacts/$apiArchiveName" $apiArchive
    if ($LASTEXITCODE -ne 0) { throw "Failed to download API image archive" }
    scp "${BuildHost}:$remotePath/artifacts/$webArchiveName" $webArchive
    if ($LASTEXITCODE -ne 0) { throw "Failed to download web image archive" }
}

if ($BuildOnly) {
    Write-Host ""
    Write-Host "Build complete. Artifacts are in $localArtifacts" -ForegroundColor Green
    exit 0
}

if (-not (Test-Path -LiteralPath $apiArchive)) { throw "Missing $apiArchive" }
if (-not (Test-Path -LiteralPath $webArchive)) { throw "Missing $webArchive" }

Write-Step "Preparing project directory on $RuntimeHost"
ssh $RuntimeHost "mkdir -p '$RuntimePath'"
if ($LASTEXITCODE -ne 0) { throw "Failed to prepare project directory on $RuntimeHost" }

Write-Step "Uploading compose and config to $RuntimeHost"
scp -r docker-compose.prod.yml .env.example collector grafana prometheus tempo "${RuntimeHost}:$RuntimePath/"
if ($LASTEXITCODE -ne 0) { throw "Failed to upload Epoptes config to $RuntimeHost" }

Write-Step "Uploading image archives to $RuntimeHost"
scp $apiArchive "${RuntimeHost}:/tmp/$apiArchiveName"
if ($LASTEXITCODE -ne 0) { throw "Failed to upload API image archive" }
scp $webArchive "${RuntimeHost}:/tmp/$webArchiveName"
if ($LASTEXITCODE -ne 0) { throw "Failed to upload web image archive" }

Write-Step "Loading images and starting Epoptes on $RuntimeHost"
ssh $RuntimeHost "sudo docker load -i '/tmp/$apiArchiveName' && sudo docker load -i '/tmp/$webArchiveName' && cd '$RuntimePath' && test -f .env || cp .env.example .env && sudo docker compose -f docker-compose.prod.yml --env-file .env up -d --remove-orphans"
if ($LASTEXITCODE -ne 0) { throw "Deployment to $RuntimeHost failed" }

Write-Step "Verifying deployment"
ssh $RuntimeHost "sudo docker ps --filter name=epoptes --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
if ($LASTEXITCODE -ne 0) { throw "Could not list Epoptes containers on $RuntimeHost" }

Write-Host ""
Write-Host "Epoptes deployed to $RuntimeHost." -ForegroundColor Green
Write-Host "Set EPOPTES_HOST in .env on the runtime host so URLs print correctly:"
Write-Host "  Web:     http://`$EPOPTES_HOST:5174"
Write-Host "  API:     http://`$EPOPTES_HOST:8180/health"
Write-Host "  Grafana: http://`$EPOPTES_HOST:3030"
Write-Host "  OTLP:    http://`$EPOPTES_HOST:4318"
