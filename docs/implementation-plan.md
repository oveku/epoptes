# Epoptes implementation plan

## Purpose

Build a local, LAN-only telemetry service for VS Code agent usage in the home development environment.

Epoptes should answer these questions:

- What did the agent do?
- Which model was used?
- How long did each step take?
- Which tools were called?
- Where did the agent fail?
- How many tokens were used?
- Which repos generate the most agent work?

## Scope for this afternoon

The first session should create a working observability foundation, not a complete product.

### Must have

- Docker Compose stack starts cleanly
- OpenTelemetry Collector accepts OTLP HTTP on port 4318
- VS Code can send telemetry to the collector
- Tempo stores traces
- Prometheus scrapes collector metrics
- Grafana has Tempo and Prometheus datasources
- API and web dashboard run with seed data
- Documentation explains setup and verification

### Should have

- A small dashboard scaffold showing sessions, tokens, duration and errors
- A stable naming convention for future services
- Basic troubleshooting docs

### Not today

- Full custom trace viewer
- Authentication
- Public exposure through reverse proxy
- Long-term retention
- Automated cost calculation against real GitHub billing
- Mnemosyne integration

## Architecture

```text
VS Code 1.119+ agent session
        |
        | OTLP HTTP / gRPC
        v
OpenTelemetry Collector
        |
        +--> Tempo       traces
        +--> Prometheus  metrics
        +--> debug logs  validation
        |
        v
Grafana Explore / dashboards

Future:
Collector / Tempo -> Epoptes indexer -> PostgreSQL -> FastAPI -> React dashboard
```

## Implementation phases

### Phase 0: Create repo

```bash
mkdir epoptes
cd epoptes
git init
```

Copy this starter pack into the repo.

### Phase 1: Start stack

```bash
cp .env.example .env
docker compose up -d --build
```

Verify:

```bash
docker ps
docker logs epoptes-otel-collector --tail 100
curl http://localhost:8180/health
```

### Phase 2: Configure VS Code

Add the settings from `docs/vscode-setup.md`.

Run a small agent task in VS Code.

### Phase 3: Verify traces

Open Grafana:

```text
http://localhost:3030
```

Go to Explore, select Tempo, search for recent traces.

Look for root spans named like:

```text
invoke_agent
invoke_agent claude
```

Child spans may include:

```text
chat
execute_tool
execute_hook
```

### Phase 4: Commit working baseline

```bash
git add .
git commit -m "Initial Epoptes telemetry MVP"
```

### Phase 5: Give agents the next tasks

Use the files in `agent-prompts/`.

## Suggested server placement

Best first host: the machine that already runs observability or storage services.

Local files show these candidates:

- ICHI: agent and memory host
- GHOST: build server, Docker Desktop, registry and LLM
- SAN: MQTT/integration bridge, kiosk/dashboard host, Docker-capable ARM64 node

Chosen placement: **San** for runtime, **GHOST** for builds. San is best for LAN telemetry ingress and dashboard proximity, while GHOST remains the correct build origin.

## Security rules

- LAN only
- Do not expose port 4318 publicly
- Keep retention low at first
- Treat traces as sensitive developer activity logs
- Avoid sending client code telemetry into this until you know what metadata VS Code includes

## Definition of done

Epoptes MVP is done when:

- VS Code points to `http://<host>:4318`
- A local agent session produces an OTLP trace
- The trace is visible in Grafana/Tempo
- Collector logs confirm telemetry reception
- Documentation explains the exact steps
