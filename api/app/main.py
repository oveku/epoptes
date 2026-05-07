import os
import re
from datetime import datetime, timezone
from typing import Any, Dict, Iterable, List, Optional, Tuple

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from pydantic import BaseModel, Field
from starlette.responses import Response

app = FastAPI(title="Epoptes API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["*"],
)

REQUESTS = Counter("epoptes_api_requests_total", "Total API requests", ["endpoint"])

TEMPO_BASE_URL = os.getenv("TEMPO_BASE_URL", "http://localhost:3320").rstrip("/")
TEMPO_QUERY_LIMIT = int(os.getenv("TEMPO_QUERY_LIMIT", "50"))
TEMPO_TIMEOUT_SECONDS = float(os.getenv("TEMPO_TIMEOUT_SECONDS", "8"))
TEMPO_SEARCH_TAGS = os.getenv("TEMPO_SEARCH_TAGS", "").strip()

INPUT_TOKEN_KEYS = (
    "input_tokens",
    "prompt_tokens",
    "total_input_tokens",
    "gen_ai.usage.input_tokens",
    "gen_ai.usage.prompt_tokens",
    "llm.usage.prompt_tokens",
    "usage.prompt_tokens",
    "usage.input_tokens",
)
OUTPUT_TOKEN_KEYS = (
    "output_tokens",
    "completion_tokens",
    "total_output_tokens",
    "gen_ai.usage.output_tokens",
    "gen_ai.usage.completion_tokens",
    "llm.usage.completion_tokens",
    "usage.completion_tokens",
    "usage.output_tokens",
)
CACHE_READ_TOKEN_KEYS = (
    "cache_read_tokens",
    "gen_ai.usage.cache_read_tokens",
    "llm.usage.cache_read_tokens",
    "usage.cache_read_tokens",
)
CACHE_CREATION_TOKEN_KEYS = (
    "cache_creation_tokens",
    "gen_ai.usage.cache_creation_tokens",
    "llm.usage.cache_creation_tokens",
    "usage.cache_creation_tokens",
)
MODEL_KEYS = (
    "model",
    "model.name",
    "model_name",
    "gen_ai.request.model",
    "gen_ai.response.model",
    "llm.request.model",
    "llm.response.model",
    "llm.model_name",
    "github.copilot.chat.model",
)
AGENT_KEYS = (
    "gen_ai.agent.name",
    "agent.name",
    "agent_name",
    "service.name",
)
WORKSPACE_KEYS = (
    "workspace.path",
    "workspace",
    "code.workspace",
    "vscode.workspace",
    "vscode.workspace.path",
)
REPOSITORY_KEYS = (
    "repository",
    "repository.name",
    "repo",
    "repo.name",
    "git.repository",
)
TOOL_KEYS = (
    "tool.name",
    "tool_name",
    "gen_ai.tool.name",
    "function.name",
    "command",
)


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
    spans: List[Span] = Field(default_factory=list)


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def ns_to_iso(value: Any) -> str:
    try:
        timestamp = int(value) / 1_000_000_000
    except (TypeError, ValueError):
        return now_iso()
    return datetime.fromtimestamp(timestamp, timezone.utc).isoformat().replace("+00:00", "Z")


def ns_to_int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def duration_from_ns(start_ns: Any, end_ns: Any, fallback_ms: Any = 0) -> int:
    start = ns_to_int(start_ns)
    end = ns_to_int(end_ns)
    if start and end and end >= start:
        return int((end - start) / 1_000_000)
    try:
        return int(float(fallback_ms))
    except (TypeError, ValueError):
        return 0


def parse_powershell_any_value(value: str) -> Any:
    match = re.fullmatch(r"@\{([A-Za-z]+)Value=(.*)\}", value, flags=re.DOTALL)
    if not match:
        return value

    kind = match.group(1)
    raw = match.group(2)
    if kind in ("int", "double"):
        try:
            parsed = float(raw)
            return int(parsed) if parsed.is_integer() else parsed
        except ValueError:
            return raw
    if kind == "bool":
        return raw.lower() == "true"
    if kind == "array" and raw == "":
        return []
    return raw


def any_value_to_python(value: Any) -> Any:
    if value is None:
        return None
    if isinstance(value, str):
        return parse_powershell_any_value(value)
    if not isinstance(value, dict):
        return value

    scalar_keys = ("stringValue", "intValue", "doubleValue", "boolValue", "bytesValue")
    for key in scalar_keys:
        if key in value:
            parsed = value[key]
            if key == "intValue":
                return int(parsed)
            if key == "doubleValue":
                return float(parsed)
            return parsed

    if "arrayValue" in value:
        values = value.get("arrayValue", {}).get("values", [])
        return [any_value_to_python(item) for item in values]

    if "kvlistValue" in value:
        entries = value.get("kvlistValue", {}).get("values", [])
        return {
            entry.get("key"): any_value_to_python(entry.get("value"))
            for entry in entries
            if entry.get("key")
        }

    return value


def attributes_to_dict(attributes: Iterable[Dict[str, Any]]) -> Dict[str, Any]:
    parsed: Dict[str, Any] = {}
    for attribute in attributes or []:
        key = attribute.get("key")
        if key:
            parsed[key] = any_value_to_python(attribute.get("value"))
    return parsed


def first_attr(attribute_sets: Iterable[Dict[str, Any]], keys: Iterable[str]) -> Optional[str]:
    for attributes in attribute_sets:
        for key in keys:
            value = attributes.get(key)
            if value not in (None, "", []):
                return str(value)
    return None


def int_attr(attributes: Dict[str, Any], keys: Iterable[str]) -> int:
    for key in keys:
        value = attributes.get(key)
        if value in (None, ""):
            continue
        try:
            return int(float(value))
        except (TypeError, ValueError):
            continue
    return 0


def repository_from_workspace(workspace: str) -> str:
    normalized = workspace.replace("\\", "/").rstrip("/")
    if not normalized or normalized == "unknown":
        return "unknown"
    return normalized.rsplit("/", 1)[-1] or "unknown"


def root_service_name(value: Any) -> Optional[str]:
    if value in (None, ""):
        return None
    name = str(value)
    if name.startswith("<"):
        return None
    return name


def status_from_tempo(span: Dict[str, Any], attributes: Dict[str, Any]) -> Tuple[str, Optional[str]]:
    status = span.get("status") or {}
    code = str(status.get("code") or attributes.get("otel.status_code") or "").upper()
    message = status.get("message") or attributes.get("exception.message") or attributes.get("error.message")
    if code in ("STATUS_CODE_ERROR", "ERROR", "2") or attributes.get("error") is True:
        return "error", str(message) if message else None
    return "ok", str(message) if message else None


def tool_name_from_span(span_name: str, attributes: Dict[str, Any]) -> Optional[str]:
    value = first_attr([attributes], TOOL_KEYS)
    if value:
        return value

    lowered = span_name.lower()
    for prefix in ("execute_tool ", "tool ", "tool."):
        if lowered.startswith(prefix):
            return span_name[len(prefix) :].strip() or None
    if " tool " in lowered:
        return span_name
    return None


def tempo_get(path: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    url = f"{TEMPO_BASE_URL}{path}"
    try:
        with httpx.Client(timeout=TEMPO_TIMEOUT_SECONDS) as client:
            response = client.get(url, params=params)
    except httpx.TimeoutException as exc:
        raise HTTPException(status_code=504, detail=f"Tempo timed out at {TEMPO_BASE_URL}") from exc
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Tempo is unavailable at {TEMPO_BASE_URL}: {exc}") from exc

    if response.status_code == 404:
        raise HTTPException(status_code=404, detail="Trace not found")
    if response.is_error:
        raise HTTPException(status_code=502, detail=f"Tempo returned HTTP {response.status_code}")

    try:
        return response.json()
    except ValueError as exc:
        raise HTTPException(status_code=502, detail="Tempo returned invalid JSON") from exc


def collect_tempo_spans(payload: Dict[str, Any]) -> List[Tuple[Dict[str, Any], Dict[str, Any]]]:
    collected: List[Tuple[Dict[str, Any], Dict[str, Any]]] = []
    for batch in payload.get("batches", []):
        resource = batch.get("resource") or {}
        resource_attrs = attributes_to_dict(resource.get("attributes", []))
        scope_spans = batch.get("scopeSpans") or batch.get("instrumentationLibrarySpans") or []

        for scope_entry in scope_spans:
            scope = scope_entry.get("scope") or scope_entry.get("instrumentationLibrary") or {}
            scope_attrs = {
                "scope.name": scope.get("name"),
                "scope.version": scope.get("version"),
            }
            for span in scope_entry.get("spans", []):
                span_attrs = attributes_to_dict(span.get("attributes", []))
                attributes = {**resource_attrs, **scope_attrs, **span_attrs}
                collected.append((span, attributes))

    return sorted(collected, key=lambda item: ns_to_int(item[0].get("startTimeUnixNano")))


def build_span(span: Dict[str, Any], attributes: Dict[str, Any]) -> Span:
    name = span.get("name") or "unnamed span"
    status, error_message = status_from_tempo(span, attributes)
    return Span(
        span_id=str(span.get("spanId") or ""),
        parent_span_id=str(span.get("parentSpanId")) if span.get("parentSpanId") else None,
        name=name,
        started_at=ns_to_iso(span.get("startTimeUnixNano")),
        ended_at=ns_to_iso(span.get("endTimeUnixNano") or span.get("startTimeUnixNano")),
        duration_ms=duration_from_ns(span.get("startTimeUnixNano"), span.get("endTimeUnixNano")),
        tool_name=tool_name_from_span(name, attributes),
        model_name=first_attr([attributes], MODEL_KEYS),
        input_tokens=int_attr(attributes, INPUT_TOKEN_KEYS),
        output_tokens=int_attr(attributes, OUTPUT_TOKEN_KEYS),
        status=status,
        error_message=error_message,
    )


def session_from_search(trace: Dict[str, Any]) -> Session:
    trace_id = str(trace.get("traceID") or "")
    start_ns = trace.get("startTimeUnixNano")
    duration_ms = duration_from_ns(None, None, trace.get("durationMs", 0))
    end_ns = ns_to_int(start_ns) + (duration_ms * 1_000_000)
    agent_name = root_service_name(trace.get("rootServiceName")) or "unknown"

    return Session(
        trace_id=trace_id,
        agent_name=str(agent_name),
        model_name="unknown",
        workspace="unknown",
        repository="unknown",
        started_at=ns_to_iso(start_ns),
        ended_at=ns_to_iso(end_ns),
        duration_ms=duration_ms,
        total_input_tokens=0,
        total_output_tokens=0,
        cache_read_tokens=0,
        cache_creation_tokens=0,
        tool_call_count=0,
        error_count=0,
        spans=[],
    )


def session_from_tempo(trace: Dict[str, Any], payload: Dict[str, Any]) -> Session:
    collected = collect_tempo_spans(payload)
    if not collected:
        return session_from_search(trace)

    spans = [build_span(span, attributes) for span, attributes in collected]
    attribute_sets = [attributes for _, attributes in collected]
    start_ns = min(ns_to_int(span.get("startTimeUnixNano")) for span, _ in collected)
    end_ns = max(ns_to_int(span.get("endTimeUnixNano")) for span, _ in collected)
    duration_ms = duration_from_ns(start_ns, end_ns, trace.get("durationMs", 0))
    workspace = first_attr(attribute_sets, WORKSPACE_KEYS) or "unknown"
    repository = first_attr(attribute_sets, REPOSITORY_KEYS) or repository_from_workspace(workspace)
    root_service = root_service_name(trace.get("rootServiceName"))

    return Session(
        trace_id=str(trace.get("traceID") or ""),
        agent_name=str(root_service or first_attr(attribute_sets, AGENT_KEYS) or "unknown"),
        model_name=first_attr(attribute_sets, MODEL_KEYS) or "unknown",
        workspace=workspace,
        repository=repository,
        started_at=ns_to_iso(start_ns),
        ended_at=ns_to_iso(end_ns or start_ns),
        duration_ms=duration_ms,
        total_input_tokens=sum(span.input_tokens for span in spans),
        total_output_tokens=sum(span.output_tokens for span in spans),
        cache_read_tokens=sum(int_attr(attributes, CACHE_READ_TOKEN_KEYS) for attributes in attribute_sets),
        cache_creation_tokens=sum(int_attr(attributes, CACHE_CREATION_TOKEN_KEYS) for attributes in attribute_sets),
        tool_call_count=sum(1 for span in spans if span.tool_name),
        error_count=sum(1 for span in spans if span.status == "error"),
        spans=spans,
    )


def tempo_trace_detail(trace: Dict[str, Any]) -> Session:
    trace_id = trace.get("traceID")
    if not trace_id:
        return session_from_search(trace)
    try:
        payload = tempo_get(f"/api/traces/{trace_id}")
    except HTTPException as exc:
        if exc.status_code == 404:
            return session_from_search(trace)
        raise
    return session_from_tempo(trace, payload)


def get_tempo_sessions() -> List[Session]:
    params: Dict[str, Any] = {"limit": TEMPO_QUERY_LIMIT}
    if TEMPO_SEARCH_TAGS:
        params["tags"] = TEMPO_SEARCH_TAGS

    search = tempo_get("/api/search", params=params)
    sessions = [tempo_trace_detail(trace) for trace in search.get("traces", []) if trace.get("traceID")]
    return sorted(sessions, key=lambda session: session.started_at, reverse=True)


def session_started_today(session: Session) -> bool:
    try:
        started_at = datetime.fromisoformat(session.started_at.replace("Z", "+00:00"))
    except ValueError:
        return False
    return started_at.astimezone(timezone.utc).date() == datetime.now(timezone.utc).date()


@app.get("/health")
def health():
    REQUESTS.labels(endpoint="/health").inc()
    return {"status": "healthy", "service": "epoptes-api", "time": now_iso()}


@app.get("/sessions", response_model=List[Session])
def get_sessions():
    REQUESTS.labels(endpoint="/sessions").inc()
    return get_tempo_sessions()


@app.get("/sessions/{trace_id}", response_model=Session)
def get_session(trace_id: str):
    REQUESTS.labels(endpoint="/sessions/{trace_id}").inc()
    payload = tempo_get(f"/api/traces/{trace_id}")
    return session_from_tempo({"traceID": trace_id}, payload)


@app.get("/stats/today")
def stats_today():
    REQUESTS.labels(endpoint="/stats/today").inc()
    sessions = [session for session in get_tempo_sessions() if session_started_today(session)]
    total_tokens = sum(session.total_input_tokens + session.total_output_tokens for session in sessions)
    return {
        "sessions_today": len(sessions),
        "total_tokens_today": total_tokens,
        "failed_tool_calls": sum(session.error_count for session in sessions),
        "average_session_duration_ms": int(
            sum(session.duration_ms for session in sessions) / max(len(sessions), 1)
        ),
    }


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
