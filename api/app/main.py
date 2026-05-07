from datetime import datetime, timezone
from typing import List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
from pydantic import BaseModel

app = FastAPI(title="Epoptes API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

REQUESTS = Counter("epoptes_api_requests_total", "Total API requests", ["endpoint"])

class Span(BaseModel):
    span_id: str
    parent_span_id: Optional[str] = None
    name: str
    started_at: str
    ended_at: str
    duration_ms: int
    tool_name: Optional[str] = None
    model_name: Optional[str] = None
    input_tokens: int = 0
    output_tokens: int = 0
    status: str = "ok"
    error_message: Optional[str] = None

class Session(BaseModel):
    trace_id: str
    agent_name: str
    model_name: str
    workspace: str
    repository: str
    started_at: str
    ended_at: str
    duration_ms: int
    total_input_tokens: int
    total_output_tokens: int
    cache_read_tokens: int
    cache_creation_tokens: int
    tool_call_count: int
    error_count: int
    spans: List[Span] = []

SEED_SESSIONS = [
    Session(
        trace_id="demo-trace-001",
        agent_name="copilot-agent",
        model_name="Claude Sonnet 4.6",
        workspace="C:/source/epoptes",
        repository="epoptes",
        started_at="2026-05-07T14:00:00Z",
        ended_at="2026-05-07T14:03:21Z",
        duration_ms=201000,
        total_input_tokens=18240,
        total_output_tokens=4210,
        cache_read_tokens=3200,
        cache_creation_tokens=900,
        tool_call_count=7,
        error_count=1,
        spans=[
            Span(span_id="root", name="invoke_agent claude", started_at="2026-05-07T14:00:00Z", ended_at="2026-05-07T14:03:21Z", duration_ms=201000, model_name="Claude Sonnet 4.6", input_tokens=18240, output_tokens=4210),
            Span(span_id="tool-1", parent_span_id="root", name="execute_tool terminal", started_at="2026-05-07T14:01:10Z", ended_at="2026-05-07T14:01:24Z", duration_ms=14000, tool_name="terminal", status="ok"),
            Span(span_id="tool-2", parent_span_id="root", name="execute_tool test", started_at="2026-05-07T14:02:30Z", ended_at="2026-05-07T14:02:38Z", duration_ms=8000, tool_name="test", status="error", error_message="One failing assertion in dashboard spec"),
        ],
    )
]

@app.get("/health")
def health():
    REQUESTS.labels(endpoint="/health").inc()
    return {"status": "ok", "service": "epoptes-api", "time": datetime.now(timezone.utc).isoformat()}

@app.get("/sessions", response_model=List[Session])
def get_sessions():
    REQUESTS.labels(endpoint="/sessions").inc()
    return SEED_SESSIONS

@app.get("/sessions/{trace_id}", response_model=Session)
def get_session(trace_id: str):
    REQUESTS.labels(endpoint="/sessions/{trace_id}").inc()
    for session in SEED_SESSIONS:
        if session.trace_id == trace_id:
            return session
    raise HTTPException(status_code=404, detail="Session not found")

@app.get("/stats/today")
def stats_today():
    REQUESTS.labels(endpoint="/stats/today").inc()
    total_tokens = sum(s.total_input_tokens + s.total_output_tokens for s in SEED_SESSIONS)
    return {
        "sessions_today": len(SEED_SESSIONS),
        "total_tokens_today": total_tokens,
        "failed_tool_calls": sum(s.error_count for s in SEED_SESSIONS),
        "average_session_duration_ms": int(sum(s.duration_ms for s in SEED_SESSIONS) / max(len(SEED_SESSIONS), 1)),
    }

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
