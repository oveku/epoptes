# AGENTS.md

> Tool-agnostic agent roster for this workspace. Read by Claude Code, Cursor, Codex CLI, Aider, and other tools that look for `AGENTS.md`.

## Purpose

Epoptes is a self-hosted observability service. It receives OpenTelemetry data from VS Code (1.119+) agent sessions, stores traces in Grafana Tempo, exposes metrics through Prometheus, and serves a React dashboard backed by a FastAPI curated-data layer.

## Operating Mode

**Autonomous mode**: prefer execution over hesitation, document material assumptions, recover from partial failure, stay aligned to project conventions.

## Non-Negotiable Rules

1. Secrets via env vars -- never hardcoded. Use `.env` + `.env.example`.
2. Health endpoints -- every service exposes `GET /health` returning `{"status": "healthy"}`.
3. No private hostnames or IPs in tracked content -- use `<EPOPTES_HOST>` placeholders or env vars.
4. Use `docker-compose.yml` for local dev (builds from source) and `docker-compose.prod.yml` for remote runtime (pre-built images, no insecure defaults).
5. Do not expose publicly without auth, TLS, and retention design.

## Service Map

| Container | Image | Port | Purpose |
|-----------|-------|-----:|---------|
| `epoptes-otel-collector` | otel/opentelemetry-collector-contrib | 4317, 4318 | OTLP ingestion from VS Code |
| `epoptes-tempo` | grafana/tempo | 3320 | Trace backend |
| `epoptes-prometheus` | prom/prometheus | 9190 | Metrics scraping |
| `epoptes-grafana` | grafana/grafana | 3030 | Dashboards |
| `epoptes-postgres` | postgres:16-alpine | 15432 (local only) | API data store |
| `epoptes-api` | epoptes-api (built) | 8180 | Curated telemetry FastAPI service |
| `epoptes-web` | epoptes-web (built) | 5174 | React dashboard |

## Where Things Live

- **Collector config**: `collector/otel-collector-config.yaml`
- **Tempo config**: `tempo/tempo.yaml`
- **Prometheus config**: `prometheus/prometheus.yml`
- **Grafana provisioning**: `grafana/provisioning/`
- **API**: `api/app/main.py` (FastAPI, Python 3.12)
- **Web**: `web/src/main.tsx` (React 18, Vite 5)
- **Scripts**: `scripts/` (build, deploy, check, smoke-test, install-vscode-integration)
- **Docs**: `docs/` (data-model, networking, troubleshooting, vscode-setup)
- **Local compose**: `docker-compose.yml`
- **Production compose**: `docker-compose.prod.yml`

## Quick Commands

```powershell
# Start locally
cp .env.example .env
# Set GRAFANA_ADMIN_PASSWORD and POSTGRES_PASSWORD in .env first
docker compose up -d

# Verify stack health
.\scripts\check.ps1

# Send synthetic trace
.\scripts\send-smoke-trace.ps1 -Endpoint http://localhost:4318

# Build images on a remote ARM64 build host and deploy to a runtime host
.\scripts\build-and-deploy.ps1 -BuildHost <build-host> -RuntimeHost <runtime-host> -RuntimePath /opt/epoptes
```
