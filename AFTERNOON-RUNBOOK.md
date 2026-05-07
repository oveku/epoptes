# Epoptes afternoon runbook

This is the practical order for getting Epoptes running when you get home.

## 1. Create the repo

```powershell
cd C:\source
mkdir epoptes
cd epoptes
git init
```

Copy the contents of this package into the repo.

## 2. Start locally first

```powershell
copy .env.example .env
scripts\start.ps1
```

Or with bash:

```bash
cp .env.example .env
./scripts/start.sh
```

## 3. Verify the stack

```powershell
scripts\check.ps1
```

Expected:

- `epoptes-otel-collector` is running
- `epoptes-tempo` is running
- `epoptes-prometheus` is running
- `epoptes-grafana` is running
- `epoptes-api` is running
- `epoptes-web` is running

## 4. Configure VS Code

Open `settings.json` and add:

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://localhost:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

For a server host, use:

```json
{
  "github.copilot.chat.otel.enabled": true,
  "github.copilot.chat.otel.otlpEndpoint": "http://<SERVER_IP>:4318",
  "github.copilot.chat.agent.modelDetails.enabled": true,
  "github.copilot.chat.agent.backgroundTodoAgent.enabled": true
}
```

## 5. Run one tiny agent task

Use a harmless repo and ask:

```text
Inspect the README and suggest one small improvement. Do not edit files.
```

Then check collector logs:

```powershell
docker logs epoptes-otel-collector --tail 200
```

## 6. Check Grafana

Open:

```text
http://localhost:3030
```

Login:

```text
admin / admin
```

Go to:

```text
Explore -> Tempo
```

Search for recent traces.

## 7. Commit the baseline

```powershell
git add .
git commit -m "Initial Epoptes telemetry MVP"
```

## 8. Move to home server

When local test works, move to the server that should own this service.

Recommended order:

1. Local dev machine first
2. GHOST for Docker builds
3. SAN for runtime, because it is the integration bridge and dashboard host

## 9. Next agent work

Run the agents using:

- `agent-prompts/01-infra-agent.md`
- `agent-prompts/02-api-agent.md`
- `agent-prompts/03-web-agent.md`

Do infrastructure first. Then API. Then dashboard.
