# Networking

## Local machine

Use:

```text
http://localhost:4318
```

## Remote (LAN) host

Use:

```text
http://<server-ip-or-hostname>:4318
```

Example with a placeholder LAN IP:

```text
http://10.0.0.42:4318
```

Define `EPOPTES_HOST` in your client `.env` or set it directly in the VS Code OTLP endpoint setting.

## Firewall

The host must allow inbound traffic on:

- 4318 TCP for OTLP HTTP
- 4317 TCP for OTLP gRPC, optional
- 3030 TCP for Grafana, optional from workstations
- 8180 TCP for Epoptes API, optional from workstations
- 5174 TCP for Epoptes Web, optional from workstations

## Windows PowerShell firewall example

Run as Administrator:

```powershell
New-NetFirewallRule -DisplayName "Epoptes OTLP HTTP" -Direction Inbound -Protocol TCP -LocalPort 4318 -Action Allow
New-NetFirewallRule -DisplayName "Epoptes Grafana" -Direction Inbound -Protocol TCP -LocalPort 3030 -Action Allow
New-NetFirewallRule -DisplayName "Epoptes API" -Direction Inbound -Protocol TCP -LocalPort 8180 -Action Allow
New-NetFirewallRule -DisplayName "Epoptes Web" -Direction Inbound -Protocol TCP -LocalPort 5174 -Action Allow
```

## Linux firewall example

```bash
sudo ufw allow 4318/tcp
sudo ufw allow 3030/tcp
sudo ufw allow 8180/tcp
sudo ufw allow 5174/tcp
```

## Do not expose publicly

Do not route this through public DNS or a reverse proxy until authentication, TLS, and retention have been designed properly. See [SECURITY.md](../SECURITY.md).
