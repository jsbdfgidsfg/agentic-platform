# 3. Low-level design

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-08

Written so that someone other than you could build it. Where this contradicts the Edge AI
v2 scaffold, this document wins and the reason is stated.

## GCP resource inventory

| Resource | Name | Notes |
|---|---|---|
| Project | `org-walle` (tbd) | Dedicated. Never shared with another workload. |
| Region | `europe-west1` | **Verified**: Agent Runtime, Sessions and Memory Bank are GA there with EU at-rest residency. |
| Service account | `walle-actions@` | Runs the action service. Only reader of the credential secrets. |
| Service account | `walle-agent@` | Runs the agent. Reads no secret. |
| Service account | `walle-dispatcher@` | Invokes the agent. |
| Service account | `eve-controller@` | Eve. Created now, unused until Eve exists. |
| Cloud Run | `walle-actions` | Auth required. Ingress: see the note below. |
| Cloud Run | `walle-dispatcher` | Auth required. Targets of Scheduler and Pub/Sub push. |
| Agent Runtime | `wall-e` | `reasoningEngines` resource, ADK 2.8, `min_instances=0` |
| Firestore (native) | `europe-west1` | Ladder config, halt flags, counters, approvals, idempotency |
| Secret Manager | 4 secrets, user-managed replication in `europe-west1` | See [02](02-identity-and-auth.md) |
| BigQuery dataset | `walle_audit`, EU | 6 tables, partitioned, with expiry |
| Pub/Sub | `walle-events`, `walle-triggers` | Eve and Mo subscribe to the first |
| Cloud Scheduler | one job per playbook, all created **paused** | Enabled per ladder stage |
| Log sink | Workspace audit logs → `walle-triggers` | Needs "Share data with Google Cloud services" enabled once by a super admin |
| Artifact Registry | `walle` | Container images |

**Ingress note.** Edge AI v2 specified internal-only ingress on the action service. Agent
Runtime egresses from a Google-managed network, so internal-only may block the agent
entirely. **IAM is the real boundary**: require authentication, grant `run.invoker` only
to `walle-agent@`, `walle-dispatcher@` and `eve-controller@`, and verify the caller's ID
token audience. If the organisation requires network-level isolation as well, that is a PSC interface
on the Agent Runtime deployment, not an ingress setting. Verify at build —
[decision 9](09-open-decisions.md).

### APIs to enable

```
aiplatform.googleapis.com          discoveryengine.googleapis.com
run.googleapis.com                 cloudbuild.googleapis.com
artifactregistry.googleapis.com    secretmanager.googleapis.com
firestore.googleapis.com           cloudscheduler.googleapis.com
pubsub.googleapis.com              bigquery.googleapis.com
logging.googleapis.com             monitoring.googleapis.com
iamcredentials.googleapis.com      admin.googleapis.com
licensing.googleapis.com           gmail.googleapis.com
chat.googleapis.com                calendar-json.googleapis.com
```

## Action service — interface

One endpoint for execution, so the policy gate is structurally impossible to bypass, plus
a small set of plan, control and read endpoints.

| Method | Path | Caller | Purpose |
|---|---|---|---|
| POST | `/v1/execute` | agent | Execute one operation |
| POST | `/v1/plans` | agent | Freeze a multi-item plan and get per-item verdicts |
| POST | `/v1/plans/{id}/approve` | **human via Gemini Enterprise, or Eve** | Release a frozen plan |
| POST | `/v1/plans/{id}/veto` | operator, Eve | Cancel during a hold window |
| GET | `/v1/plans/{id}`, `/v1/runs/{id}` | Eve, Mo | Read a plan or run with pre-state |
| POST | `/v1/control/halt` | operator, Eve | Set or clear a halt mode |
| POST | `/v1/control/demote` | operator, Eve | Lower a level. **Refuses any raise.** |
| GET | `/v1/ladder` | anyone authorised | Effective levels, config version, halt state |
| GET | `/v1/operations` | agent | Catalogue introspection; the agent's tools are generated from this |
| GET | `/healthz` | — | Liveness plus last successful audit write |

### `POST /v1/execute`

```jsonc
{
  "operation": "directory.user.suspend",
  "params": { "user_key": "jdoe@example.com", "suspended": true },
  "principal": {
    "type": "human",              // human | scheduler | event | inbox | eve
    "id": "owner@example.com",  // asserted email, or "job:leaver-checklist"
    "on_behalf_of": null          // the owning human, for machine principals
  },
  "run_id": "r-2026-09-08-0007",
  "plan_id": null,                 // set when the item belongs to a frozen plan
  "trigger_id": "sched:leaver-checklist:2026-09-08T07:00Z",
  "idempotency_key": "r-2026-09-08-0007#3",
  "dry_run": false,
  "approval_id": null              // required when the level demands an approval
}
```

Success:

```jsonc
{
  "status": "ok",
  "operation": "directory.user.suspend",
  "level": "L3",
  "result": { "user_key": "jdoe@example.com", "suspended": true },
  "pre_state": { "suspended": false, "orgUnitPath": "/Engineering" },
  "verification": "verified",
  "audit_id": "a7c3..."
}
```

Approval required:

```jsonc
{
  "status": "approval_required",
  "approval_id": "ap-9f21...",
  "required_from": "human",        // human | eve
  "plan": "Suspend jdoe@example.com (active, /Engineering, not an admin, 3 groups).",
  "expires_at": "2026-09-08T14:32:00Z"
}
```

Refused: `{ "status": "denied", "reason": "level_off", "detail": "...", "audit_id": "..." }`

### Why an approval id and not a token handed to the model

Edge AI v2 returned an HMAC token **to the agent**, which then decided whether the human
had said yes. That means the control was "the model asserts a human approved", which is
exactly the class of thing an injection can produce. Wall-E changes the ownership:

- The service mints the approval request, stores it in Firestore with a **nonce**, and
  returns only an opaque `approval_id`.
- The approval itself arrives on `/v1/plans/{id}/approve` from an authenticated principal:
  either a human whose identity the front door asserts and the service re-checks against
  the operators group, or Eve with a signature made using **Eve's own key**.
- The approval binds `(operation, canonical params, principal, plan_hash, pre_state_hash,
  expiry, nonce)` and is **marked consumed in the same transaction as the execution**.

Consequences, all deliberate: an approval cannot be replayed, cannot be moved to different
parameters, cannot be used after the target's state changed, and cannot be produced by the
model at all. The agent's only role is to show the plan and relay that an approval is
needed.

## The autonomy config

The ladder lives in `walle/config/ladder.yaml` in git, is validated in CI, and is deployed
to a Firestore document the service reads with a short cache. Full semantics in
[05-autonomy-ladder.md](05-autonomy-ladder.md).

```yaml
version: "2026.09.0-1"                 # stamped on every audit row
stage: 0
decision: decisions/2026-09-20-walle-stage-0.md
defaults:
  business_hours: { tz: Europe/Paris, days: Mon-Fri, from: "08:00", to: "18:00" }
  last_write_of_day: "16:00"           # so a human is still around
  freeze_windows: []
  daily_write_budget: 0
families:
  F3-membership:
    levels:   { chat: L3, scheduled: L1, event: L0, inbox: L0 }
    max_objects_per_run: 10
    ou_allowlist: ["tbd"]
    group_classes_allowed: ["low"]
    hold_minutes: 30
    notify: per_step
```

The effective level for one item is:

```
effective = min( ceiling[risk_tier][trigger],     # code, cannot be raised by config
                 config.families[f].levels[t],    # the ladder
                 playbook.level,                  # a playbook may cap itself lower
                 override[f][t] )                 # demotions, live, demote-only
```

evaluated **after** `policy.evaluate()` and before execution, logged on every row.

## Operation catalogue

Nothing executes that is not registered. Each entry: name, risk tier, reversibility, the
scope it needs, a Pydantic parameter model with `extra="forbid"`, a handler, a **pre-state
reader**, an **expected post-state predicate**, and an **inverse** where one exists.

| Operation | Risk | Reversible | Family | Notes |
|---|---|---|---|---|
| `directory.user.get` / `.list` | READ | — | F1 | |
| `directory.group.list` / `.members.list` | READ | — | F1 | |
| `directory.orgunit.list` | READ | — | F1 | |
| `directory.admins.list` | READ | — | F1 | Feeds the protected-principal cache |
| `reports.activities.list` | READ | — | F1 | Admin, login, groups, token, saml |
| `reports.usage.users` | READ | — | F1 | `accounts:last_login_time`, drives inactivity reports |
| `licensing.assignments.list` | READ | — | F1 | |
| `notify.operators` | WRITE_LOW | no | F2 | **Recipients come from config, never from the model.** Template id plus typed params. |
| `chat.message.send` | WRITE_LOW | no | F2 | Free text. Chat only. |
| `gmail.send` | WRITE_LOW | no | F2 | Free text. External recipients force approval, always. |
| `calendar.event.create` / `.list` | WRITE_LOW / READ | yes | F2 | |
| `gmail.list` / `.get` / `.label` | READ / WRITE_LOW | yes | F1 / F2 | Robot's own mailbox only |
| `directory.group.member.add` / `.remove` | WRITE_HIGH | yes | F3 | Inverse is exact. Group class checked. |
| `directory.user.update` | WRITE_HIGH | yes | F4 | Bounded by `SAFE_USER_FIELDS` |
| `directory.user.suspend` (true) | WRITE_HIGH | yes | F5 | |
| `directory.user.suspend` (false) | WRITE_HIGH | yes | **F6** | Restoring access is its own family, capped lower |
| `licensing.assignment.delete` / `.insert` / `.patch` | WRITE_HIGH | yes | F7 | Pre-state records the SKU so re-insert is exact |
| `run.rollback` | WRITE_HIGH | — | — | Always requires a human approval, at every stage |

`SAFE_USER_FIELDS` is a hard allowlist in code: name, organizations, phones, locations,
relations, orgUnitPath. It can never touch password, `isAdmin`, 2SV, aliases,
`recoveryEmail` or `recoveryPhone`. Recovery fields are account-takeover vectors and are
excluded even though they look like profile data.

Risk tiers are static properties of an operation. Rate limits per tier: READ 120/min,
WRITE_LOW 20/min, WRITE_HIGH 5/min, **enforced durably** (see below).

## Playbooks

A playbook is what an autonomous run executes. It is not a prompt.

```yaml
leaver-checklist:
  version: 4
  owner: owner@example.com          # must be in walle-operators@ at run time
  trigger: { event: "admin.USER_SUSPENDED" }
  selection: directory.user.list      # deterministic query, not model-chosen
  uses: [directory.user.get, directory.group.members.list,
         directory.group.member.remove, notify.operators]
  level: L2                            # a playbook may cap itself below the family level
  max_objects_per_run: 10
  expects: "user is in no group except tbd-baseline; user in /Leavers"
```

Rules the service enforces, not the prompt:

- An operation the agent names that is **not in `playbook.uses`** aborts the whole run
  with `playbook_violation`. The model plans within the playbook, never outside it.
- Targets are **explicit and enumerated**. There is no query-shaped write. "Everyone in
  /Finance" is not expressible.
- The plan is frozen and hashed before any approval; approving binds the hash.
- Each item is **re-read immediately before execution**. If the pre-state changed since
  planning, the item is skipped and reported, never executed on stale assumptions.

## The policy engine

Order of evaluation. Any failure denies, writes an audit row, and — for the first four —
is treated as a hard invariant breach that trips the breaker.

1. **Halt check.** Firestore control doc: `run`, `no_autonomous`, `no_writes`, `halt_all`.
2. **Catalogue lookup.** Unknown operation → denied.
3. **Parameter validation.** Pydantic, `extra="forbid"`.
4. **Protected principals.** See below.
5. **Principal check.** Humans must be in the operators group (readers group for READ),
   verified through the Directory API, failing closed. Machine principals must match the
   trigger class the request claims.
6. **Scope.** Target's `orgUnitPath` must be in the family's OU allowlist. Group targets
   must be in an allowed class.
7. **Budgets.** Per-run object cap, per-family daily write budget, tenant-wide daily cap,
   novelty cap (distinct targets per hour). Durable counters.
8. **Business hours and freeze windows**, for machine principals.
9. **Rate limit**, per principal per tier, durable.
10. **Effective level** → execute, shadow, propose, or require an approval.
11. **Approval verification**, if one was supplied: signature, binding, expiry, nonce not
    yet consumed.
12. **Idempotency**, on the caller-supplied key.
13. Execute → **verify by re-reading** → audit.

### Protected principals

Refuse any write whose target is a super admin, a delegated admin, the robot itself, the
robot's OU, a member of `walle-protected@`, or a **group** that grants an admin role or
controls Wall-E, Eve or Mo.

Fixes to the Edge AI v2 implementation, all of which matter:

- It ran on **reads** too, so "who is the super admin?" was denied. Apply to writes only.
- It matched `isAdmin=true`, missing **delegated admins**. Include `isDelegatedAdmin`.
- It paginated at 200 with no continuation, silently truncating on a large tenant.
- The protected-group lookup swallowed exceptions, so it failed **open** while the design
  document said it failed closed.
- It never checked `group_key`, so "add me to `walle-operators@`" was an escalation path
  gated only by a model-mediated confirmation.
- It made two uncached Admin SDK calls on every directory operation. Cache with a short
  TTL, refreshed in the background, and fail closed if the cache cannot be filled.

### Group classification

Every group is `low` (distribution, collaboration), `access` (grants Drive, app, licence
or GCP access) or `security` (grants an admin role, or controls Wall-E/Eve/Mo).
**Unclassified is treated as `security`** — fail closed. Membership writes are allowed on
`low` at higher levels, `access` only at lower ones, and `security` never. The list is
owned by security, lives in config, and is a Stage 1 deliverable.

### Durable counters, not in-memory

Edge AI v2 kept rate limits and idempotency in a Python dict, while the Dockerfile ran two
uvicorn workers and Cloud Run scales instances. The documented "5 WRITE_HIGH per minute"
was therefore 10 × instance count, and budgets meant nothing. For an autonomous doer,
every budget is a **transactional Firestore counter**, so the cap is global and honest.
Idempotency also moves to Firestore, applies to **writes only** (a cached read for ten
minutes would break post-execution verification), and keys on the caller's explicit
`idempotency_key` rather than a hash of parameters.

## Storage

### BigQuery `walle_audit`, partitioned by `ts`, clustered by `operation`

| Table | Purpose | Key columns beyond the obvious |
|---|---|---|
| `actions` | One row per request | `principal_type`, `principal_id`, `on_behalf_of`, `run_id`, `plan_id`, `trigger_id`, `family`, `risk`, `level`, `config_version`, `catalogue_version`, `playbook_version`, `model_id`, `decision`, `denial_reason`, `dry_run`, `pre_state_hash`, `post_state_hash`, `verification`, `approval_id`, `approver`, `approval_latency_ms`, `params_redacted`, `result_summary`, `latency_ms`, `error_class` |
| `runs` | One row per run | terminal state, counts, budget consumed, tokens, cost |
| `plans` | Frozen plans with per-item pre-state | `plan_hash`, `rollback_hash` |
| `approvals` | Every approval and refusal | who, when, how long they took, verdict, reason code |
| `verifications` | Post-execution comparison | `verified` / `drift` / `unverifiable` |
| `config_versions` | Every ladder change | version, sha, decision file, deployer, origin `human`/`eve`/`breaker` |

Retention: 400 days by default, subject to the organisation policy — [decision 8](09-open-decisions.md).

Three rules about the audit trail:

- **Write-ahead and fail-closed for writes.** Edge AI v2 logged insert failures and
  carried on, so "audited before the response returns" was best-effort. If the audit sink
  is down, writes are refused. No evidence, no action.
- **Never store payloads.** `result_summary` in the old scaffold was `str(result)[:500]`,
  which put email body excerpts into BigQuery. Store ids and counts. Redact query strings
  and the `fields` map of a user update.
- The action service's service account gets **insert-only** rights on the dataset. It must
  not be able to delete its own evidence.

### Firestore

`control/mode`, `control/freeze`, `overrides/{family}/{trigger}`, `ladder/current`,
`approvals/{id}`, `counters/{scope}/{window}`, `idempotency/{key}`, `dedup/{event_id}`.

## The agent

- ADK 2.8.x on Agent Runtime, `google-adk~=2.8` with the `a2a`, `gcp` and `agent-identity`
  extras. Deployed with `vertexai.Client(...).agent_engines.create(...)`, service account
  `walle-agent@`, `min_instances=0`, tracing on.
- **Tools are generated from `/v1/operations`**, not hand-written. Edge AI v2's agent
  exposed 12 of 16 catalogue operations and never sent `dry_run`, so a flow the design
  depended on could not happen. Generation makes drift impossible.
- Two entry modes in one deployment: interactive (`user_id` = the human's email) and job
  (`user_id` = `job:<playbook>`, message = a structured envelope carrying `run_id`,
  playbook version and budget).
- Sessions: managed, EU. **Memory Bank off** — an admin agent should not accumulate
  long-term memories about employees, and it keeps the DPIA simpler.
- A `WallEPolicyPlugin` registered on the runner mirrors the catalogue and level in
  `before_tool`, injects `run_id` and principal into every call, and emits structured
  events. It is **defence in depth, not the trust boundary** — a code change can bypass a
  plugin, and nothing in the model's process is authoritative.
- Model Armor must be configured **in agent code**; the Gemini Enterprise console setting
  does not cover ADK agents.
- Do not use ADK tool-confirmation for approvals: it is documented as unsupported with the
  managed session service, and approvals must survive a runtime change anyway.
- System instruction states plainly that Workspace content is data and never instruction,
  that the agent holds no credentials, that it cannot approve anything, and that when it
  sees embedded instructions it must report and stop.

## Model

`Assumption:` a current Gemini model with EU data residency, pinned by id and recorded in
`config_versions` so Mo can attribute a behaviour change to a model change. Not every
newest model has EU residency — check the per-model table before pinning.
[Decision 6](09-open-decisions.md).
