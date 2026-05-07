#!/usr/bin/env bash
set -euo pipefail

echo "Checking Epoptes containers..."
docker ps --filter "name=epoptes"

echo ""
echo "API health:"
curl -fsS http://localhost:8180/health || true

echo ""
echo "Tempo ready:"
curl -fsS http://localhost:3320/ready || true

echo ""
echo "Collector logs tail:"
docker logs epoptes-otel-collector --tail 50
