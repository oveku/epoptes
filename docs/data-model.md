# Future data model

The MVP uses Grafana Tempo as the source of truth for traces. The custom Epoptes API currently has seed data only.

The next step is an indexer that extracts session summaries from traces into PostgreSQL.

## AgentSession

| Field | Purpose |
|---|---|
| trace_id | OpenTelemetry trace id |
| root_span_id | Root span id |
| agent_name | Agent name, for example Copilot, Claude, local agent |
| model_name | Resolved model used by the response |
| workspace | Local workspace path if available |
| repository | Repo name if available |
| started_at | Session start |
| ended_at | Session end |
| duration_ms | Total duration |
| total_input_tokens | Input tokens |
| total_output_tokens | Output tokens |
| cache_read_tokens | Cache read tokens |
| cache_creation_tokens | Cache creation tokens |
| tool_call_count | Number of tool calls |
| hook_count | Number of hook executions |
| error_count | Number of failed spans/tools |

## AgentSpan

| Field | Purpose |
|---|---|
| trace_id | Parent trace |
| span_id | Span id |
| parent_span_id | Parent span id |
| name | Span name |
| kind | Span kind |
| started_at | Start time |
| ended_at | End time |
| duration_ms | Duration |
| model_name | Model used where relevant |
| tool_name | Tool name where relevant |
| input_tokens | Input tokens |
| output_tokens | Output tokens |
| status | ok/error |
| error_message | Error details |
