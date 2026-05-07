# Master agent prompt: Epoptes

We are building **Epoptes**, a local telemetry service for VS Code 1.119+ agent sessions.

Epoptes belongs in a Pantheon-style local agent ecosystem. Its role is to reveal what agents actually do: model usage, token usage, tool calls, duration, errors and trace relationships.

## Context

VS Code 1.119 can emit OpenTelemetry telemetry for Copilot Chat agent sessions when these settings are enabled:

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://<EPOPTES_HOST>:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

## MVP requirements

Create a working local stack that includes:

- OpenTelemetry Collector on 4317 and 4318
- Grafana Tempo for traces
- Prometheus for metrics
- Grafana for visualization
- FastAPI scaffold with seed session data
- React/Vite dashboard scaffold
- Documentation for local and LAN setup

## Important constraints

- Do not build a full custom trace viewer yet.
- Use Grafana Tempo first.
- Keep this LAN-only.
- Do not expose telemetry publicly.
- Keep the stack simple and reproducible.
- Commit working increments.

## Definition of done

- `docker compose up -d --build` works
- Grafana starts and datasources are provisioned
- API `/health` works
- Web dashboard loads
- VS Code can point to `http://<host>:4318`
- Documentation explains verification and troubleshooting
