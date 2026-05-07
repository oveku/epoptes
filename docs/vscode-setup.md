# VS Code setup for Epoptes

## Required VS Code version

Use VS Code 1.119+ for OpenTelemetry tracing from Copilot Chat agent sessions.

## User settings

Install from this project (Windows):

```powershell
.\scripts\install-vscode-integration.ps1 -Endpoint http://<EPOPTES_HOST>:4318
```

The installer backs up and updates:

```text
%APPDATA%\Code\User\settings.json
```

Manual setup is also possible. Open the Command Palette:

```text
Preferences: Open User Settings (JSON)
```

Add (replace `<EPOPTES_HOST>` with `localhost` or your server's address):

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://<EPOPTES_HOST>:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

## Optional sandbox setting

For trusted local development environments only:

```json
{
  "chat.agent.sandbox.enabled": "allowNetwork"
}
```

This keeps filesystem restrictions but removes network domain blocking. Do not enable this casually for untrusted repositories.

## Verification task

First send a synthetic client trace:

```powershell
.\scripts\send-smoke-trace.ps1 -Endpoint http://<EPOPTES_HOST>:4318
```

Then ask an agent to do a tiny task in a harmless repo, for example:

```text
Create a README section that explains how to run tests. Do not change code.
```

Then check the collector logs (locally or via SSH to your runtime host):

```bash
docker logs epoptes-otel-collector --tail 200
```

Open Grafana:

```text
http://<EPOPTES_HOST>:3030
```

Use Explore -> Tempo -> Search.
