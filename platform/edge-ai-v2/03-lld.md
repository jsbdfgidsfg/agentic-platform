# 3. Low-level design

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-05

## GCP resource inventory

| Resource | Name (proposed) | Notes |
|---|---|---|
| Project | `org-edge-ai-v2` | Dedicated. Do not share with other workloads. |
| Region | `europe-west1` | Confirm against the organisation data-residency policy and Agent Engine availability. |
| Service account (agent) | `edge-agent@<proj>.iam.gserviceaccount.com` | Runs the Agent Engine agent. Only identity granted `run.invoker`. |
| Service account (action svc) | `edge-actions@<proj>.iam.gserviceaccount.com` | Runs Cloud Run. Only identity granted access to the secrets. |
| Cloud Run service | `workspace-actions` | Ingress: internal only. Auth: required. |
| Secret | `edge-oauth-client` | OAuth client id + secret (JSON). |
| Secret | `edge-refresh-token` | The robot account's refresh token. |
| Secret | `edge-confirm-hmac` | Key for signing confirmation tokens. |
| BigQuery dataset | `edge_audit` | Table `actions`. |
| Artifact Registry | `edge-ai` | Container images. |
| Log sink | `edge-audit-sink` | Structured logs → BigQuery. |

### APIs to enable

```
aiplatform.googleapis.com          discoveryengine.googleapis.com
run.googleapis.com                 cloudbuild.googleapis.com
artifactregistry.googleapis.com    secretmanager.googleapis.com
gmail.googleapis.com               chat.googleapis.com
calendar-json.googleapis.com       drive.googleapis.com
admin.googleapis.com               bigquery.googleapis.com
logging.googleapis.com             iamcredentials.googleapis.com
```

## Action service — interface

Single endpoint, typed envelope. One endpoint rather than one route per operation, so
the policy gate is structurally impossible to bypass.

### `POST /v1/execute`

```jsonc
{
  "operation": "gmail.send",         // must exist in the catalogue
  "params": { "to": ["a@b.com"], "subject": "…", "body": "…" },
  "actor": "owner@example.com",    // propagated end user
  "session_id": "ge-abc123",         // for correlation
  "dry_run": false,
  "confirmation_token": null          // required for HIGH-risk operations
}
```

Response, success:

```jsonc
{
  "status": "ok",
  "operation": "gmail.send",
  "result": { "message_id": "18f…" },
  "audit_id": "a7c3…"
}
```

Response, confirmation required:

```jsonc
{
  "status": "confirmation_required",
  "operation": "directory.user.suspend",
  "plan": "Suspend user jdoe@example.com (currently active, in /Engineering).",
  "confirmation_token": "eyJ…",     // HMAC-signed, 5-minute TTL, binds op+params
  "expires_at": "2026-09-05T14:32:00Z"
}
```

Response, refused:

```jsonc
{ "status": "denied", "reason": "operation_not_allowed", "detail": "…" }
```

### Why a confirmation token rather than a boolean

A boolean `confirmed: true` is a field the LLM can simply set. The token is an HMAC over
`(operation, canonical(params), actor, expiry)` produced *by the service*, so the agent
can only obtain one by making a first call and showing the plan to the human. The model
cannot forge it, and it cannot be replayed against different parameters. This is what
makes "the human confirms in chat" a real control rather than a suggestion.

## Operation catalogue

Every capability is a registry entry. Nothing executes that is not here.

| Operation | Risk | Scope needed | Params |
|---|---|---|---|
| `gmail.list` | READ | gmail.modify | `query`, `max_results` |
| `gmail.get` | READ | gmail.modify | `message_id` |
| `gmail.send` | WRITE_LOW | gmail.send | `to[]`, `cc[]`, `subject`, `body`, `reply_to_message_id?` |
| `gmail.label` | WRITE_LOW | gmail.modify | `message_id`, `add[]`, `remove[]` |
| `chat.spaces.list` | READ | chat.spaces | — |
| `chat.message.send` | WRITE_LOW | chat.messages | `space`, `text`, `thread_key?` |
| `calendar.events.list` | READ | calendar | `time_min`, `time_max`, `calendar_id` |
| `calendar.event.create` | WRITE_LOW | calendar | `summary`, `start`, `end`, `attendees[]` |
| `directory.user.get` | READ | admin.directory.user | `user_key` |
| `directory.user.list` | READ | admin.directory.user | `query`, `max_results` |
| `directory.user.update` | WRITE_HIGH | admin.directory.user | `user_key`, `fields{}` |
| `directory.user.suspend` | WRITE_HIGH | admin.directory.user | `user_key`, `suspended` |
| `directory.group.members.list` | READ | admin.directory.group | `group_key` |
| `directory.group.member.add` | WRITE_HIGH | admin.directory.group | `group_key`, `member`, `role` |
| `directory.group.member.remove` | WRITE_HIGH | admin.directory.group | `group_key`, `member` |
| `reports.activities.list` | READ | admin.reports.audit.readonly | `application`, `user_key?`, `start_time` |

Risk tiers:

| Tier | Requires | Rate limit |
|---|---|---|
| `READ` | actor in reader group | 120/min |
| `WRITE_LOW` | actor in operator group | 20/min |
| `WRITE_HIGH` | actor in operator group **and** valid confirmation token | 5/min |

`gmail.send` is WRITE_LOW rather than HIGH deliberately — it is outward-facing but not
destructive, and gating every email behind a confirmation would make the agent useless.
If you want outbound mail confirmed, flip it in `policy.py`; it is one line.

## Guard rails encoded in the service

| Guard | Implementation |
|---|---|
| Operation allowlist | Registry lookup; unknown → `denied` |
| Parameter validation | Pydantic model per operation; extra fields rejected |
| Recipient domain policy | `gmail.send` / `calendar.event.create`: external recipients require confirmation |
| Protected-principal list | Refuse any Directory write targeting a super admin, the robot itself, or a member of `edge-protected@` |
| Dry run | Every WRITE returns the resolved plan without executing when `dry_run=true` |
| Idempotency | `session_id + operation + hash(params)` cached 10 min; replays return the original result |
| Rate limit | Per actor, per tier, in-memory + Firestore for multi-instance |
| Audit | Every request/response written before the response returns |

## Agent design (ADK, on Agent Engine)

- One agent, tools = one Python function per catalogue operation, each a thin HTTP call
  to `/v1/execute` with an ID token.
- The agent's system instruction states plainly that it holds no credentials, that
  destructive operations return a plan for the human to approve, and that it must never
  attempt to construct or guess a confirmation token.
- **Injection posture:** content fetched from Workspace (email bodies, Chat messages,
  documents) is data, never instruction. The system prompt says so, and the policy engine
  assumes the prompt will sometimes fail — which is why the token exists.

## Audit schema (`edge_audit.actions`)

| Column | Type | Notes |
|---|---|---|
| `audit_id` | STRING | uuid |
| `ts` | TIMESTAMP | |
| `actor` | STRING | end user from Gemini Enterprise |
| `session_id` | STRING | |
| `operation` | STRING | |
| `risk` | STRING | |
| `params_redacted` | JSON | bodies truncated, no attachment content |
| `decision` | STRING | `allowed` / `denied` / `confirmation_required` |
| `denial_reason` | STRING | nullable |
| `dry_run` | BOOL | |
| `result_summary` | STRING | ids, counts — never full payloads |
| `latency_ms` | INT64 | |
| `error` | STRING | nullable |

Retain per the organisation policy; 400 days is a reasonable default. This table is the answer to
"what has the robot done", and it is the first thing an auditor will ask for.
