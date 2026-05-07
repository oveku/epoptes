import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import './styles.css';

type Session = {
  trace_id: string;
  agent_name: string;
  model_name: string;
  repository: string;
  duration_ms: number;
  total_input_tokens: number;
  total_output_tokens: number;
  tool_call_count: number;
  error_count: number;
};

type Stats = {
  sessions_today: number;
  total_tokens_today: number;
  failed_tool_calls: number;
  average_session_duration_ms: number;
};

const currentHost = window.location.hostname || 'localhost';
const apiBase = import.meta.env.VITE_API_BASE_URL ?? `${window.location.protocol}//${currentHost}:8180`;
const grafanaUrl = `${window.location.protocol}//${currentHost}:3030`;

function formatDuration(ms: number) {
  return `${Math.round(ms / 1000)}s`;
}

function App() {
  const [sessions, setSessions] = useState<Session[]>([]);
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    fetch(`${apiBase}/sessions`).then(r => r.json()).then(setSessions).catch(console.error);
    fetch(`${apiBase}/stats/today`).then(r => r.json()).then(setStats).catch(console.error);
  }, []);

  return (
    <main className="shell">
      <header className="hero">
        <div>
          <p className="eyebrow">Pantheon Observability</p>
          <h1>Epoptes</h1>
          <p className="subtitle">Local telemetry for VS Code agent sessions.</p>
        </div>
        <a className="button" href={grafanaUrl} target="_blank">Open Grafana</a>
      </header>

      <section className="cards">
        <Card title="Sessions today" value={stats?.sessions_today ?? '-'} />
        <Card title="Tokens today" value={stats?.total_tokens_today?.toLocaleString() ?? '-'} />
        <Card title="Failed tools" value={stats?.failed_tool_calls ?? '-'} />
        <Card title="Avg duration" value={stats ? formatDuration(stats.average_session_duration_ms) : '-'} />
      </section>

      <section className="panel">
        <h2>Recent agent sessions</h2>
        <table>
          <thead>
            <tr>
              <th>Trace</th>
              <th>Agent</th>
              <th>Model</th>
              <th>Repo</th>
              <th>Duration</th>
              <th>Tokens</th>
              <th>Tools</th>
              <th>Errors</th>
            </tr>
          </thead>
          <tbody>
            {sessions.map(s => (
              <tr key={s.trace_id}>
                <td>{s.trace_id}</td>
                <td>{s.agent_name}</td>
                <td>{s.model_name}</td>
                <td>{s.repository}</td>
                <td>{formatDuration(s.duration_ms)}</td>
                <td>{(s.total_input_tokens + s.total_output_tokens).toLocaleString()}</td>
                <td>{s.tool_call_count}</td>
                <td className={s.error_count > 0 ? 'warn' : ''}>{s.error_count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </main>
  );
}

function Card({ title, value }: { title: string; value: string | number }) {
  return <article className="card"><p>{title}</p><strong>{value}</strong></article>;
}

createRoot(document.getElementById('root')!).render(<App />);
