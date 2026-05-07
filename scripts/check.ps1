Write-Host "Checking Epoptes containers..."
docker ps --filter "name=epoptes"

Write-Host ""
Write-Host "API health:"
try { Invoke-RestMethod http://localhost:8180/health } catch { Write-Host $_ }

Write-Host ""
Write-Host "Tempo ready:"
try { Invoke-RestMethod http://localhost:3320/ready } catch { Write-Host $_ }

Write-Host ""
Write-Host "Collector logs tail:"
docker logs epoptes-otel-collector --tail 50
