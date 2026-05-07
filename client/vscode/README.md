# Epoptes VS Code client integration

This directory contains the client-side settings used by VS Code / Copilot Chat to send agent-session telemetry to your Epoptes server.

Install into the current Windows user profile:

```powershell
.\scripts\install-vscode-integration.ps1 -Endpoint http://<EPOPTES_HOST>:4318
```

Replace `<EPOPTES_HOST>` with `localhost` if you run Epoptes on the same machine, or the LAN address / hostname of your Epoptes server.

The installer updates your VS Code user settings to include:

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://<EPOPTES_HOST>:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

Restart VS Code and run a small agent task. Traces should land in Grafana Tempo through Epoptes.
