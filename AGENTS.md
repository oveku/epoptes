# AGENTS.md

> Tool-agnostic agent roster for this workspace. Read by Claude Code, Cursor, Codex CLI, Aider, and other tools that look for `AGENTS.md`.

## Purpose

Epoptes is the observability service for Pantheon agent sessions. It receives OpenTelemetry data from VS Code (1.119+) agent sessions, stores traces in Grafana Tempo, exposes metrics through Prometheus, and serves a React dashboard with a FastAPI curated-data layer.

## Operating Mode

**Autonomous mode**: prefer execution over hesitation, document material assumptions, recover from partial failure, stay aligned to Pantheon conventions.

## Non-Negotiable Rules

1. Secrets via env vars -- never hardcoded. Use `.env` + `.env.example`.
2. Health endpoints -- every service exposes `GET /health` returning `{"status": "healthy"}`.
3. Builds on GHOST -- ARM64 images are built on GHOST, not on the dev machine. Run `scripts/build-and-deploy.ps1`.
4. San is the runtime host -- `192.168.1.124`. Use `docker-compose.san.yml` for production.
5. Do not expose publicly -- no public DNS or reverse proxy until auth, TLS, and retention are designed.

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
- **Docs**: `docs/` (data-model, networking, pantheon-placement, troubleshooting, vscode-setup)
- **Local compose**: `docker-compose.yml`
- **Production compose (San)**: `docker-compose.san.yml`

## Key Agents for This Project

| Agent | Use For |
|-------|---------|
| Architect | Adding new routes, models, Grafana dashboards, collector pipelines |
| Closer | Verifying the stack is up, smoke-testing OTLP ingestion |
| Reviewer | Auditing OWASP compliance, Docker conventions, FastAPI structure |
| Documenter | ADRs, release notes, dashboard guides |

## Quick Commands

```powershell
# Start locally
cp .env.example .env
scripts\start.ps1

# Verify stack health
scripts\check.ps1

# Send synthetic trace
scripts\send-smoke-trace.ps1

# Build ARM64 images on GHOST and deploy to San
scripts\build-and-deploy.ps1
```
