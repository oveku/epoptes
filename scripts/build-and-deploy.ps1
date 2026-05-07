param(
    [string]$GhostHost = "cerberos-win-build",
    [string]$SanHost = "san",
    [string]$GhostProjectPath = "C:\source\epoptes",
    [string]$SanProjectPath = "/home/admin/epoptes",
    [string]$Tag = "latest",
    [switch]$BuildOnly,
    [switch]$DeployOnly
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$localArtifacts = Join-Path $root "artifacts"
$bundle = Join-Path $env:TEMP "epoptes-source.zip"
$remoteBundle = "C:/Windows/Temp/epoptes-source.zip"
$apiArchiveName = "epoptes-api-$Tag-arm64.tar"
$webArchiveName = "epoptes-web-$Tag-arm64.tar"
$apiArchive = Join-Path $localArtifacts $apiArchiveName
$webArchive = Join-Path $localArtifacts $webArchiveName

function Write-Step($Message) {
    Write-Host ""
    Write-Host "--- $Message ---" -ForegroundColor Cyan
}

function Invoke-GhostPowerShell($ScriptText) {
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptText))
    ssh $GhostHost "powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
    if ($LASTEXITCODE -ne 0) { throw "Remote GHOST command failed" }
}

function Assert-ChildPath($Path, $ExpectedPrefix) {
    if (-not $Path.StartsWith($ExpectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to use path outside ${ExpectedPrefix}: $Path"
    }
}

Set-Location $root
New-Item -ItemType Directory -Force -Path $localArtifacts | Out-Null

if (-not $DeployOnly) {
    Assert-ChildPath $GhostProjectPath "C:\source\"

    Write-Step "Packaging local source for GHOST"
    $items = Get-ChildItem -Force | Where-Object { $_.Name -notin @(".git", "artifacts", "node_modules", "dist", ".docker-config") }
    if (Test-Path -LiteralPath $bundle) { Remove-Item -LiteralPath $bundle -Force }
    Compress-Archive -Path $items.FullName -DestinationPath $bundle -Force

    Write-Step "Uploading source bundle to GHOST"
    scp $bundle "${GhostHost}:$remoteBundle"
    if ($LASTEXITCODE -ne 0) { throw "Failed to upload source bundle to GHOST" }

    Write-Step "Expanding source on GHOST"
    $prepareGhost = @"
`$ErrorActionPreference = 'Stop'
`$ProgressPreference = 'SilentlyContinue'
`$target = '$GhostProjectPath'
if (-not `$target.StartsWith('C:\source\', [System.StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe GHOST target: `$target" }
New-Item -ItemType Directory -Force -Path `$target | Out-Null
Expand-Archive -LiteralPath '$remoteBundle' -DestinationPath `$target -Force
"@
    Invoke-GhostPowerShell $prepareGhost

    Write-Step "Building ARM64 images on GHOST"
    $buildGhost = @"
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$GhostProjectPath'
& '.\scripts\build-on-ghost.ps1' -Tag '$Tag'
"@
    Invoke-GhostPowerShell $buildGhost

    Write-Step "Downloading GHOST-built image archives"
    $ghostPath = $GhostProjectPath.Replace("\", "/")
    scp "${GhostHost}:$ghostPath/artifacts/$apiArchiveName" $apiArchive
    if ($LASTEXITCODE -ne 0) { throw "Failed to download API image archive" }
    scp "${GhostHost}:$ghostPath/artifacts/$webArchiveName" $webArchive
    if ($LASTEXITCODE -ne 0) { throw "Failed to download web image archive" }
}

if ($BuildOnly) {
    Write-Host ""
    Write-Host "Build complete. Artifacts are in $localArtifacts" -ForegroundColor Green
    exit 0
}

Assert-ChildPath $SanProjectPath "/home/admin/epoptes"

if (-not (Test-Path -LiteralPath $apiArchive)) { throw "Missing $apiArchive" }
if (-not (Test-Path -LiteralPath $webArchive)) { throw "Missing $webArchive" }

Write-Step "Preparing San project directory"
ssh $SanHost "mkdir -p '$SanProjectPath'"
if ($LASTEXITCODE -ne 0) { throw "Failed to prepare San project directory" }

Write-Step "Uploading compose and config to San"
scp -r docker-compose.san.yml .env.example collector grafana prometheus tempo "${SanHost}:$SanProjectPath/"
if ($LASTEXITCODE -ne 0) { throw "Failed to upload Epoptes config to San" }

Write-Step "Uploading image archives to San"
scp $apiArchive "${SanHost}:/tmp/$apiArchiveName"
if ($LASTEXITCODE -ne 0) { throw "Failed to upload API image archive to San" }
scp $webArchive "${SanHost}:/tmp/$webArchiveName"
if ($LASTEXITCODE -ne 0) { throw "Failed to upload web image archive to San" }

Write-Step "Loading images and starting Epoptes on San"
ssh $SanHost "sudo docker load -i '/tmp/$apiArchiveName' && sudo docker load -i '/tmp/$webArchiveName' && cd '$SanProjectPath' && test -f .env || cp .env.example .env && sudo docker compose -f docker-compose.san.yml --env-file .env up -d --remove-orphans"
if ($LASTEXITCODE -ne 0) { throw "San deployment failed" }

Write-Step "Verifying San deployment"
ssh $SanHost "sudo docker ps --filter name=epoptes --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
if ($LASTEXITCODE -ne 0) { throw "Could not list Epoptes containers on San" }

Write-Host ""
Write-Host "Epoptes deployed to San." -ForegroundColor Green
Write-Host "Web:     http://192.168.1.124:5174"
Write-Host "API:     http://192.168.1.124:8180/health"
Write-Host "Grafana: http://192.168.1.124:3030"
Write-Host "OTLP:    http://192.168.1.124:4318"
