# Troubleshooting

## Collector does not start

Check config syntax:

```bash
docker logs epoptes-otel-collector --tail 200
```

## VS Code sends nothing

Check:

- VS Code is 1.119+
- `github.copilot.chat.otel.enabled` is `true`
- endpoint is `http://<host>:4318`
- the agent task actually ran after settings were changed
- firewall allows inbound port 4318

## No traces in Grafana

Check collector logs:

```bash
docker logs epoptes-otel-collector --tail 200
```

Check Tempo:

```bash
curl http://localhost:3320/ready
```

Check Grafana datasource provisioning:

```bash
docker logs epoptes-grafana --tail 200
```

## Prometheus has no metrics

Open:

```text
http://localhost:9090/targets
```

The `otel-collector` target should be UP.

## Web dashboard cannot reach API

Check:

```bash
curl http://localhost:8180/health
```

The web dashboard derives the API host from the browser URL and expects the API on port `8180`.

## Reset all data

This removes all volumes:

```bash
docker compose down -v
```
