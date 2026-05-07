# API agent task

Extend the FastAPI service for Epoptes.

Current API uses seed data. Improve it without over-engineering.

Tasks:

1. Add SQLAlchemy models for AgentSession and AgentSpan.
2. Add database initialization on startup.
3. Keep seed data available if database is empty.
4. Keep endpoints:
   - GET /health
   - GET /sessions
   - GET /sessions/{trace_id}
   - GET /stats/today
5. Add tests if practical.

Do not build Tempo ingestion yet unless the base API is stable.
