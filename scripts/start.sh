#!/usr/bin/env bash
set -euo pipefail

[ -f .env ] || cp .env.example .env

docker compose up -d --build

docker ps --filter "name=epoptes"

echo ""
echo "Epoptes started."
echo "Grafana: http://localhost:3030"
echo "API:     http://localhost:8180/health"
echo "Web:     http://localhost:5174"
echo "OTLP:    http://localhost:4318"
