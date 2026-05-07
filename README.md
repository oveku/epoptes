# Epoptes

**Epoptes** is a self-hosted observability service for VS Code 1.119+ agent sessions. It collects OpenTelemetry data emitted by GitHub Copilot Chat agents and surfaces it as traces, metrics, and a curated dashboard — so you can see which model ran, which tools were invoked, where time went, and where tokens were spent.

The project deliberately uses standard observability tools (OpenTelemetry Collector, Tempo, Prometheus, Grafana) rather than building a custom trace stack. A small FastAPI service maps raw traces into curated sessions for a React dashboard.

> **Status:** active development, single-operator home-lab grade. See [Roadmap to public release](#roadmap-to-public-release) before publishing.

## Why the name?

*Epoptes* (Greek: ἐπόπτης, "watcher / one who has seen") fits an observer that reveals what agents actually did.

## What it does

- Receives OTLP (HTTP + gRPC) telemetry from VS Code agent sessions
- Stores traces in Grafana Tempo with 7-day local retention
- Exposes metrics through Prometheus
- Visualises sessions in pre-provisioned Grafana dashboards
- Exposes a FastAPI service that reads real session traces from Tempo
- Serves a React dashboard with stats cards and a session table

## Architecture

```
VS Code (dev machine)
  │
  │  OTLP HTTP (4318) / gRPC (4317)
  ▼
epoptes-otel-collector
  ├── traces  ──► epoptes-tempo (3320)
  └── metrics ──► epoptes-prometheus (9190)
                          │
                          ▼
                epoptes-grafana (3030)

epoptes-api (8180)  ◄──► epoptes-tempo
       │
       └──► epoptes-postgres (reserved for future indexing)
       ▲
       │ REST
epoptes-web (5174)
```

| Service | Image | Description |
|---------|-------|-------------|
| `otel-collector` | `otel/opentelemetry-collector-contrib` | Receives OTLP, fans out to Tempo and Prometheus |
| `tempo` | `grafana/tempo` | Trace backend; 7-day local retention |
| `prometheus` | `prom/prometheus` | Metrics; 7-day TSDB retention |
| `grafana` | `grafana/grafana` | Dashboards; pre-provisioned Tempo + Prometheus datasources |
| `postgres` | `postgres:16-alpine` | Reserved API database for future indexing |
| `api` | `epoptes-api` (built locally) | FastAPI service; maps Tempo traces into curated sessions and stats |
| `web` | `epoptes-web` (built locally) | React dashboard with stats cards and session table |

## Compose files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Local development — builds images from source, exposes Postgres for inspection |
| `docker-compose.san.yml` | Remote runtime host — uses pre-built images, locked-down ports |

The remote compose file expects pre-built images and is parameterised through environment variables so the same file works on any host.

## Ports

| Service | Port | Purpose |
|---|---:|---|
| OpenTelemetry Collector HTTP | 4318 | VS Code OTLP endpoint |
| OpenTelemetry Collector gRPC | 4317 | OTLP gRPC endpoint |
| Grafana | 3030 | Dashboards |
| Prometheus | 9190 | Metrics |
| Tempo | 3320 | Trace backend |
| Epoptes API | 8180 | Curated telemetry API |
| Epoptes Web | 5174 | Dashboard |

Ports are deliberately offset to coexist with other services on a multi-tenant host (avoiding stock `5432`, `3000`, `9090`).

## Quick start

```bash
cp .env.example .env
# Edit .env and set strong values for GRAFANA_ADMIN_PASSWORD and POSTGRES_PASSWORD
docker compose up -d
```

Open:

- Grafana: <http://localhost:3030>
- API health: <http://localhost:8180/health>
- Web dashboard: <http://localhost:5174>

> **Set `GRAFANA_ADMIN_PASSWORD` in `.env` before first start.** The default in `.env.example` is a placeholder.

## VS Code settings

Send agent telemetry from a Windows / macOS / Linux dev machine to your Epoptes host:

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://<EPOPTES_HOST>:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

Replace `<EPOPTES_HOST>` with the LAN address or hostname where Epoptes is running (use `localhost` if the stack runs on the same machine).

A helper script is provided for Windows operators:

```powershell
.\scripts\install-vscode-integration.ps1 -Endpoint http://<EPOPTES_HOST>:4318
.\scripts\send-smoke-trace.ps1            -Endpoint http://<EPOPTES_HOST>:4318
```

## Build and deployment to a remote host

For multi-architecture / remote-runtime deployments the build pattern is:

1. Build API and web images on a build host that matches the target architecture
2. Save the images as tar archives
3. Transfer the archives to the runtime host
4. Load the images and start `docker-compose.san.yml`

A reference PowerShell script lives in [`scripts/build-and-deploy.ps1`](scripts/build-and-deploy.ps1). It is currently parameterised for the project author's hosts; adapt the `$GhostHost`, `$SanHost`, and path variables to your infrastructure or replace it with your own CI flow.

## Configuration

All runtime configuration is via environment variables — see [`.env.example`](.env.example). The API additionally honours:

- `TEMPO_BASE_URL` (default `http://tempo:3200`) — where the API queries Tempo
- `TEMPO_QUERY_LIMIT` (default `50`) — max traces returned by `/sessions`

## Health and smoke tests

```powershell
.\scripts\check.ps1                # check all containers + endpoints
.\scripts\send-smoke-trace.ps1     # push a synthetic trace through the collector
```

Each service exposes `GET /health` returning `{"status": "healthy"}`.

## Project layout

```
api/              FastAPI service (Python 3.12)
web/              React 18 + Vite 5 dashboard
collector/        OpenTelemetry Collector config
tempo/            Tempo config
prometheus/       Prometheus config
grafana/          Grafana provisioning (datasources, dashboards)
client/vscode/    Reference VS Code settings for dev machines
scripts/          Build, deploy, check, smoke-test scripts
docs/             Architecture, networking, troubleshooting, VS Code setup
```

## Roadmap to public release

This repo is currently **private**. Items to address before making it public:

- [ ] Add a `LICENSE` file (MIT recommended)
- [ ] Replace remaining personal hostnames / IPs in `docs/`, `AGENTS.md`, `docker-compose.san.yml`, and `scripts/` with placeholders
- [ ] Generalise `scripts/build-and-deploy.ps1` (or convert to `.example`)
- [ ] Strengthen `.env.example` placeholders and remove weak compose defaults (`${VAR:?...}` instead of `${VAR:-admin}`)
- [ ] Add `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`
- [ ] Expand `.gitignore` (IDE, OS, Python/Node caches, `.env.*`)
- [ ] Decide whether internal `agent-prompts/` and `AFTERNOON-RUNBOOK.md` stay or move
- [ ] Re-run `pip-audit` / `npm audit` and update pinned versions

See the open-source readiness audit (May 2026) for the full list and per-file findings.

## License

Not yet licensed for public use. All rights reserved by the author until a `LICENSE` file is added.
