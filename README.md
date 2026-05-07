# Epoptes

**Epoptes** is a local telemetry service for VS Code 1.119+ agent sessions.

It is designed for a home-lab/Pantheon environment where development machines send OpenTelemetry data from VS Code agents to a local server. The first version uses standard observability tools instead of building a custom trace viewer too early.

## Why the name?

Epoptes means watcher or one who has seen. In Pantheon terms, Epoptes is the observer that reveals what the agents actually did: which model was used, which tools ran, where time went, and where tokens were spent.

The name is intentionally not Aletheia. Local Pantheon files already use Aletheia for the truth verification service on Ni, and Argus is already used for the Cerberos vision system.

## MVP goal

A working local stack that can:

- receive OTLP telemetry from VS Code agent sessions
- store traces in Grafana Tempo
- expose metrics through Prometheus
- visualize sessions in Grafana
- provide a small FastAPI service with seed data for a future curated dashboard
- provide a React dashboard scaffold for the next development step

## Ports

| Service | Port | Purpose |
|---|---:|---|
| OpenTelemetry Collector HTTP | 4318 | VS Code OTLP endpoint |
| OpenTelemetry Collector gRPC | 4317 | OTLP gRPC endpoint |
| Grafana | 3030 | Dashboards |
| Prometheus | 9190 | Metrics |
| Tempo | 3320 | Trace backend |
| Epoptes API | 8180 | Curated telemetry API |
| Epoptes Web | 5174 | Local React dashboard |

## Quick start

```bash
cp .env.example .env
docker compose up -d
```

Open:

- Grafana: <http://localhost:3030>
- API health: <http://localhost:8180/health>
- Web dashboard: <http://localhost:5174>

Default Grafana login:

```text
admin / admin
```

## VS Code settings

Use the LAN address of the server running Epoptes.

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://<EPOPTES_HOST>:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

Example for San:

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://192.168.1.124:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

## Build and deployment

The Pantheon rule still applies: code may be edited on Korsair, but production builds happen on GHOST. Epoptes builds ARM64 API and web images on GHOST, transfers those image archives to San, and starts `docker-compose.san.yml` on San.

```powershell
.\scripts\build-and-deploy.ps1
```

San was selected because it is the integration bridge and kiosk host, already owns MQTT, has Docker available, and is the closest machine to dashboard consumption. The compose ports avoid San's existing PostgreSQL `5432` and existing web service on `3000`.

## MVP done means

- Docker Compose starts cleanly
- VS Code can send OTLP data to `http://<host>:4318`
- Collector logs show incoming telemetry
- Grafana has Prometheus and Tempo datasources
- A trace with `invoke_agent` appears in Grafana Explore
- README and docs explain how to reproduce it

## Recommended first implementation session

1. Start the stack.
2. Add the VS Code settings.
3. Run one small Copilot/Claude agent task.
4. Check collector logs.
5. Open Grafana Explore.
6. Verify traces in Tempo.
7. Commit the working baseline.
8. Let agents implement curated ingestion and dashboard features next.
