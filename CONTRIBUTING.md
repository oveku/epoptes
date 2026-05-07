# Contributing to Epoptes

Thanks for your interest in contributing. Epoptes is a small home-lab observability stack; the goal is to keep it focused, hackable, and easy to run on a single host.

## Ground rules

- **Keep it simple.** Prefer fewer moving parts. The stack already includes OpenTelemetry Collector, Tempo, Prometheus, Grafana, FastAPI, and a React app — that is a lot. New dependencies need a clear reason.
- **Convention over configuration.** Match existing patterns (env-var configuration, container naming, port offsets) before introducing new ones.
- **No hardcoded secrets.** All credentials and host-specific values come from environment variables. Use `.env.example` as the contract.
- **Tests define the contract.** When code and tests disagree, fix the code.

## Development setup

```bash
git clone https://github.com/oveku/epoptes.git
cd epoptes
cp .env.example .env
# Set strong values for GRAFANA_ADMIN_PASSWORD and POSTGRES_PASSWORD in .env
docker compose up -d
```

Send a synthetic trace to verify the pipeline end-to-end:

```powershell
.\scripts\send-smoke-trace.ps1 -Endpoint http://localhost:4318
```

## Running tests

```bash
# API
cd api
pip install -r requirements.txt
pytest

# Web
cd web
npm install
npm test
```

## Code style

- **Python**: PEP 8, type hints required on new code, no `Any` without justification. Format with `ruff`/`black`.
- **TypeScript**: strict mode on, no implicit `any`. Format with `prettier`.
- **YAML / Compose**: 2-space indent, no trailing whitespace.

## Commit messages

Conventional Commits style:

```
<type>: <short description>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`. Subject under 72 chars, imperative mood.

## Pull requests

1. Branch from `master`: `feature/<short-description>` or `fix/<short-description>`.
2. Keep PRs focused — one logical change per PR.
3. Include a short Why / What / How-to-test summary in the description.
4. Make sure `docker compose up -d` still produces a healthy stack on a clean clone.
5. Update `CHANGELOG.md` under "Unreleased" if the change is user-visible.

## Reporting bugs

Open an issue with:

- What you expected
- What happened (logs, screenshots)
- Reproduction steps
- Your environment (OS, docker version, VS Code version)

## Reporting security issues

See [SECURITY.md](SECURITY.md). Do not open public issues for security problems.

## License

By contributing, you agree that your contributions will be licensed under the MIT License (see [LICENSE](LICENSE)).
