# Infra agent task

Review and improve the Docker Compose based observability stack for Epoptes.

Focus on:

- OpenTelemetry Collector correctness
- Tempo compatibility
- Prometheus scraping
- Grafana datasource provisioning
- clean startup order
- useful container names
- restart policies
- LAN-friendly port exposure

Do not add Kubernetes, Helm, cloud dependencies, authentication or public reverse proxy. This is a home-lab MVP.

After changes, run:

```bash
docker compose config
docker compose up -d --build
docker ps
```

Document any manual steps in README.md.
