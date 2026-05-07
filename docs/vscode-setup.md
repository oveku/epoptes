# VS Code setup for Epoptes

## Required VS Code version

Use VS Code 1.119+ for OpenTelemetry tracing from Copilot Chat agent sessions.

## User settings

Open Command Palette:

```text
Preferences: Open User Settings (JSON)
```

Add:

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://localhost:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

For a server on the home LAN:

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://192.168.1.124:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

## Optional sandbox setting

For trusted home development environments only:

```json
{
  "chat.agent.sandbox.enabled": "allowNetwork"
}
```

This keeps filesystem restrictions but removes network domain blocking. Do not enable this casually for untrusted repositories.

## Verification task

Ask an agent to do a tiny task in a harmless repo, for example:

```text
Create a README section that explains how to run tests. Do not change code.
```

Then check:

```bash
docker logs epoptes-otel-collector --tail 200
```

Open Grafana:

```text
http://localhost:3030
```

Use Explore -> Tempo -> Search.
