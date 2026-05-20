# Changelog

All notable changes to Epoptes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Grafana dashboard `Copilot Cost` (`grafana/dashboards/copilot-cost.json`) showing estimated USD spend and AI Credit consumption from emitted token metrics
- Prometheus recording rules at `prometheus/rules/copilot-pricing.yml` encoding per-model GitHub Copilot pricing under the June 2026 usage-based billing model
- `LICENSE` (MIT)
- `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`
- Roadmap to public release in `README.md`
- API `TEMPO_BASE_URL` / `TEMPO_QUERY_LIMIT` env-var configuration
- Postgres healthcheck and `service_healthy` dependency for the API container
- Reference VS Code client integration under `client/vscode/` and `scripts/install-vscode-integration.ps1`

### Changed

- API now queries Grafana Tempo for live agent sessions (no more seed data)
- Renamed `docker-compose.san.yml` to `docker-compose.prod.yml` and parameterised host-specific values via env vars
- `docker-compose.prod.yml` now requires `GRAFANA_ADMIN_PASSWORD` and `POSTGRES_PASSWORD` to be set (no insecure defaults)
- API CORS hardened: `allow_origins=["*"]` retained but `allow_credentials=False` and `allow_methods=["GET"]` only
- API `/health` now returns `{"status": "healthy"}` (was `"ok"`)
- API Dockerfile runs as non-root `appuser` and includes a `HEALTHCHECK`
- Web dependencies pinned to specific semver ranges instead of `latest`
- Generalised `scripts/build-and-deploy.ps1` so build/runtime hosts and paths are configurable

### Removed

- Internal narrative documents (`AFTERNOON-RUNBOOK.md`, `docs/pantheon-placement.md`, `docs/implementation-plan.md`, `agent-prompts/`)
- Hardcoded LAN IP `192.168.1.124` and personal hostnames from documentation, scripts, and compose files

### Fixed

- `DATABASE_URL` no longer hardcoded; uses env-var substitution

## [0.1.0] - 2026-04-30

Initial private release: OTLP -> Tempo / Prometheus / Grafana stack with FastAPI and React scaffolds.
