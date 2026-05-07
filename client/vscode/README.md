# Epoptes VS Code client integration

This directory contains the client-side settings used by VS Code/Copilot Chat to send agent-session telemetry to Epoptes on San.

Install into the current Windows user profile:

```powershell
.\scripts\install-vscode-integration.ps1
```

The installer updates:

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://192.168.1.124:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

Then restart VS Code and run a small agent task. Traces should land in Grafana Tempo through Epoptes.
