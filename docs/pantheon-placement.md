# Pantheon placement

## Service name

**Epoptes**

## Role

Epoptes is the observability service for agent execution.

It does not command agents. It does not remember conclusions. It records what actually happened.

## Relationship to existing Pantheon/Cerberos names

| Component | Role |
|---|---|
| Zeus | Orchestrates agents |
| Metis | Plans from ideas |
| Hephaestus | Implements code |
| Hermes | Publishes output |
| Mnemosyne | Remembers durable knowledge |
| Charon | Bridges messaging |
| Cassandra | Predicts likely future events |
| Pheme | Produces news digest |
| Aletheia | Verifies truth and tests outcomes |
| Argus | Vision and camera intelligence |
| Epoptes | Reveals agent execution truth |

## Canonical sentence

```text
Epoptes observes what the agents actually did so Mnemosyne can remember what worked and Zeus can make better decisions next time.
```

## Server placement

Chosen runtime: **San** (`192.168.1.124`).

Reasons:

- San is the Pantheon integration bridge and already hosts MQTT plus kiosk/dashboard workflows.
- Epoptes receives LAN-only OTLP traffic and should be close to always-on infrastructure.
- GHOST remains the build host, matching the Pantheon deployment rule.
- San already has Docker and passwordless sudo available.

Port choices avoid existing San services: PostgreSQL stays internal to Docker, Grafana uses `3030` instead of San's occupied `3000`, and the API uses `8180` instead of common app ports.

## Suggested DNS/local names

```text
epoptes.local
epoptes.lan
pantheon-epoptes
cerberos-epoptes
```

## Suggested service path

```text
C:\source\epoptes
```

or on Linux:

```text
/home/admin/epoptes
```
