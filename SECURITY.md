# Security Policy

## Supported versions

Epoptes is in active development and only the `master` branch is supported. Pull from `master` for the latest fixes.

## Reporting a vulnerability

**Do not open a public GitHub issue for security problems.**

Report security issues privately via GitHub Security Advisories:

1. Go to <https://github.com/oveku/epoptes/security/advisories/new>
2. Describe the vulnerability, the affected version, and reproduction steps
3. Allow up to 14 days for an initial response

If GitHub Security Advisories are not available to you, open a minimal public issue saying "I have a security report — please contact me" and we will arrange a private channel.

## Scope

In scope:

- Code in this repository (API, web, scripts, configuration)
- Default container images and configurations as shipped

Out of scope:

- Vulnerabilities in upstream dependencies (Tempo, Prometheus, Grafana, OpenTelemetry Collector, Postgres) — report those upstream first
- Self-inflicted misconfiguration (e.g. running with `GRAFANA_ADMIN_PASSWORD=admin`, exposing the stack to the public internet without auth/TLS)

## Hardening recommendations for operators

Epoptes is designed for a trusted LAN. Before running it anywhere reachable from the public internet:

1. Set strong, unique values for `GRAFANA_ADMIN_PASSWORD` and `POSTGRES_PASSWORD` in `.env`.
2. Put the stack behind an authenticating reverse proxy with TLS.
3. Restrict the OTLP receiver (`4317`/`4318`) to trusted source IPs at the firewall.
4. Use Grafana's built-in user management or external SSO; do not share the admin account.
5. Consider mounting Tempo / Prometheus volumes on encrypted storage if traces may contain sensitive prompts.

OTLP traces from VS Code can include workspace paths, repository names, and tool arguments. Treat the trace store as sensitive.
