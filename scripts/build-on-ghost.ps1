param(
    [string]$Tag = "latest",
    [string]$Platform = "linux/arm64",
    [string]$Builder = ""
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$artifacts = Join-Path $root "artifacts"
$dockerConfig = Join-Path $root ".docker-config"
$apiImage = "epoptes-api:$Tag"
$webImage = "epoptes-web:$Tag"
$apiArchive = Join-Path $artifacts "epoptes-api-$Tag-arm64.tar"
$webArchive = Join-Path $artifacts "epoptes-web-$Tag-arm64.tar"

function Write-Step($Message) {
    Write-Host ""
    Write-Host "--- $Message ---" -ForegroundColor Cyan
}

Set-Location $root
New-Item -ItemType Directory -Force -Path $artifacts | Out-Null
New-Item -ItemType Directory -Force -Path $dockerConfig | Out-Null
Set-Content -Path (Join-Path $dockerConfig "config.json") -Value '{"auths":{}}' -Encoding Ascii
$env:DOCKER_CONFIG = $dockerConfig

Write-Step "Building API image on GHOST for $Platform"
$apiBuildArgs = @("build", "--platform", $Platform, "-t", $apiImage, "--load", "./api")
if ($Builder) { $apiBuildArgs = @("build", "--builder", $Builder, "--platform", $Platform, "-t", $apiImage, "--load", "./api") }
docker buildx @apiBuildArgs
if ($LASTEXITCODE -ne 0) { throw "API image build failed" }

Write-Step "Building web image on GHOST for $Platform"
$webBuildArgs = @("build", "--platform", $Platform, "-t", $webImage, "--load", "./web")
if ($Builder) { $webBuildArgs = @("build", "--builder", $Builder, "--platform", $Platform, "-t", $webImage, "--load", "./web") }
docker buildx @webBuildArgs
if ($LASTEXITCODE -ne 0) { throw "Web image build failed" }

Write-Step "Saving Docker image archives"
docker save $apiImage -o $apiArchive
if ($LASTEXITCODE -ne 0) { throw "API image save failed" }

docker save $webImage -o $webArchive
if ($LASTEXITCODE -ne 0) { throw "Web image save failed" }

Write-Host ""
Write-Host "Build artifacts:" -ForegroundColor Green
Write-Host "  $apiArchive"
Write-Host "  $webArchive"
