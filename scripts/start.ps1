Copy-Item .env.example .env -ErrorAction SilentlyContinue

docker compose up -d --build

docker ps --filter "name=epoptes"

Write-Host ""
Write-Host "Epoptes started."
Write-Host "Grafana: http://localhost:3030"
Write-Host "API:     http://localhost:8180/health"
Write-Host "Web:     http://localhost:5174"
Write-Host "OTLP:    http://localhost:4318"
