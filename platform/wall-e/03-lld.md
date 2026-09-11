# 3. Low-level design

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-09

Written so that someone other than you could build it. Where this contradicts an earlier
draft, this document wins and the reason is stated.

## GCP resource inventory

| Resource | Name | Notes |
|---|---|---|
| Project | `<project-id>` (tbd) | Dedicated. Never shared with another workload. |
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

**Ingress note.** A common assumption is that the action service should use internal-only
ingress. The verified fact, as of September 2026, is that Agent Runtime egresses from
a Google-managed tenant project, and Cloud Run counts that as **external**, so
internal-only ingress blocks the agent. Making it work needs one of: a shared VPC Service
Controls perimeter covering both, an internal Application Load Balancer in front of Cloud
Run, or a Private Service Connect endpoint. A PSC *interface* on the agent is not the
answer on its own — `run.app` traffic keeps taking the Google network path unless you add
private DNS peering, and enabling it also removes the agent's internet egress.

**So IAM is the enforced boundary**, and it has to do more work than an earlier draft
assumed. `run.invoker` is granted **per service, not per path**, so granting it to the
agent, the dispatcher and Eve gives all three the right to call *every* endpoint,
including `/v1/control/demote`. The claim that the agent "has no IAM on the control
endpoints" was therefore false as built. Two mechanisms, both required:

1. **A per-endpoint caller allowlist inside the service**, keyed on the verified `email`
   claim of the caller's ID token. Execute and plan endpoints: `walle-agent@` only.
   Control and approval endpoints: `eve-controller@` and members of `walle-operators@`,
   never the agent.
2. **Operators need a binding at all.** Grant `roles/run.invoker` to `walle-operators@`
   so a human can present `gcloud auth print-identity-token`, or the andon cord has no
   handle.

Splitting the control plane onto a second Cloud Run service with its own IAM is the
stronger version of the same idea, and is [decision 18](09-open-decisions.md).

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
| POST | `/v1/plans/{id}/approve` | **out-of-band human surface, or Eve. Never the agent** | Release a frozen plan; returns 202, executes asynchronously |
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
  "params": { "user_key": "<user>@<domain>", "suspended": true },
  "principal": {
    "type": "human",              // human | scheduler | event | inbox | eve | agent
    "id": "<operator email>",     // asserted by the front door, re-checked here
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
  "result": { "user_key": "<user>@<domain>", "suspended": true },
  "pre_state": { "suspended": false, "orgUnitPath": "<pilot OU>" },
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
  "plan": "Suspend <user> (active, <pilot OU>, not an admin, 3 groups).",
  "expires_at": "2026-09-08T14:32:00Z"
}
```

Refused: `{ "status": "denied", "reason": "level_off", "detail": "...", "audit_id": "..." }`

### Why an approval id, and why the agent can never carry it

A common first design returns an HMAC token **to the agent**, which then decides whether
the human has said yes. The control is therefore "the model asserts a human approved", which
is exactly what an injection produces. An earlier draft of this document fixed half of it —
the service mints the approval — and left the other half broken, because the agent still
posted the approval and named the approver. The service could verify that the named person
was an operator. It had no way to verify that they had said anything.

Three rules, and the first is the one that matters:

1. **`walle-agent@` is refused on the approval endpoints, by caller identity.** Not by
   convention, not by prompt: a caller allowlist that contains the human approval surface
   and Eve, and does not contain the agent. Denial reason `approver_is_agent`, a hard
   invariant that trips the breaker. If the agent can reach the approval endpoint at all,
   every other control in this document is decoration.
2. **Human approval arrives out of band**, on a surface that authenticates the human
   itself: a Google Chat card whose interaction event carries a Chat-verified identity, or
   a one-time approval URL behind Identity-Aware Proxy, bound to `plan_hash`. The model is
   not in the path and never sees the approval.
3. **Eve approves with its own key**, and the service verifies with the public half — see
   below.

The approval binds `(operation, canonical params, principal, plan_hash, pre_state_hash,
expiry, nonce)`. The nonce is **consumed before the Workspace call**, not after and not
"in the same transaction" — no transaction spans Firestore and an Admin SDK call, and
claiming one was unbuildable. Consuming first means a crash can leave an operation whose
outcome is unknown, so the service writes an `in_flight` record before the call and a
reconciler resolves any orphan against the **Workspace audit log**, which is Google's
independent record of whether the call landed.

### Eve's signature must be asymmetric

Eve signs with a **Cloud KMS asymmetric key** (`EC_SIGN_P256_SHA256`). `eve-controller@`
holds `roles/cloudkms.signer`; `walle-actions@` holds only `publicKeyViewer` and verifies
locally.

This is not a preference. A shared symmetric secret cannot express "Eve approved this":
either the action service cannot verify Eve's signature, or it can also mint one. An
earlier draft specified a random symmetric secret readable only by Eve, which makes the
Eve-gated level unbuildable, and the obvious fix at build time would have quietly
destroyed the property the whole controller role rests on.

Eve signs over a `plan_hash` **it computed itself** from the plan body and its own
Workspace reads — never over a hash the action service reported to it. Frozen plans live
in a Firestore collection where the action service can create but not update, so a signed
plan cannot be rewritten between signature and execution.

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
    levels:   { chat: L1, scheduled: L1, event: L0, inbox: L0 }   # stage 0: nothing executes
    max_objects_per_run: 10
    ou_allowlist: ["tbd"]
    group_classes_allowed: ["low"]
    hold_minutes: 30
    notify: per_step
```

The effective level for one item is:

```
trigger_for_ceiling = "inbox" if (run.tainted and principal.type != "human") else trigger
# a human's chat request that is tainted keeps L3, not the inbox ceiling: see 11-prompt-security.md
# a principal of type "agent" (a peer calling over A2A) has its own ceiling column: L5 for READ,
# L0 for every write tier. A peer can obtain reads and narration and never a proposal. See 13.

effective = min( ceiling[risk_tier][trigger_for_ceiling],   # code, never raised by config
                 config.families[f].levels[t],              # the ladder
                 playbook.level,                            # a playbook may cap itself
                 override[f][t] )                           # live, demote-only
```

evaluated **after** the policy chain and before execution, logged on every row along with
`tainted`, `config_version` and `ceilings_sha`.

### The taint bit, and why trigger class is not enough

An earlier draft attached trust to *how a run started*. Injection arrives with *what a run
reads*. Those are independent axes, and conflating them left the largest hole in the
design: a **scheduled** run that reads a hostile group name, display name or audit-log
parameter had a WRITE_HIGH ceiling of L4, while the same text arriving by mail was capped
at L0.

So every catalogue operation declares which of its returned fields are **attacker
writable**: user `name.*`, `organizations`, `locations`, `relations`; group `name` and
`description`; organisational-unit `description`; calendar `summary`, `description`,
`location`; Chat `text`; mail headers and bodies; the `parameters` values of audit rows;
and every upstream error string. When any such field is non-empty and reaches the model,
the run is marked `tainted` and **takes the inbox ceiling for the rest of its life**.

A playbook that must show names to a human declares `taints: true` and is permanently
capped at proposals, by construction rather than by care.

### The control plane fails closed, including the parts that used to fail open

Halt flags, overrides, counters, nonces, idempotency and dedup all live in Firestore.
An earlier draft specified fail-closed behaviour for the audit sink and the
protected-principal cache and said nothing about the rest, which in practice means
fail-open:

- **Any** Firestore read or write error anywhere in the chain denies with
  `control_plane_unavailable`, and that is a hard invariant.
- The sentinel for "no override" is **L0, not L5**. A failed read of the overrides
  collection must not silently restore every demoted family to its configured level. The
  andon cord cannot un-pull itself during an outage.
- Halt and override reads are strongly consistent and never cached. Monotone
  `halt_epoch` and `override_epoch` counters are stamped on every audit row, so a later
  query can prove no decision used a stale view.
- If Firestore has been unreachable for more than 30 seconds, the process self-halts
  writes without waiting to be told.

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
| `notify.operators` | WRITE_LOW | no | **F2** | **Recipients come from config, never from the model.** Template id plus typed params |
| `chat.message.send` | WRITE_LOW | no | **F2b** | Free text |
| `gmail.send` | WRITE_LOW | no | **F2b** | Free text. External recipients force approval, always |
| `calendar.event.create` | WRITE_LOW | no | **F2b** | Treated as irreversible: an invite that was seen cannot be unseen |
| `calendar.events.list`, `gmail.list`, `gmail.get` | READ | — | F1 | Robot's own mailbox and calendar only |
| `gmail.label` | WRITE_LOW | yes | **F9** | The robot's own mailbox. Its own resource, so its own family |
| `directory.group.member.add` / `.remove` | WRITE_HIGH | yes | **F3** (class `low`) / **F3b** (class `access`) | Inverse is exact. The family follows the group's class |
| `directory.user.update` | WRITE_HIGH | yes | F4 | Bounded by `SAFE_USER_FIELDS`, which no longer contains `orgUnitPath` |
| `directory.user.move_ou` | WRITE_HIGH | yes | **F4b** | Its own operation, with its own destination allowlist. See below |
| `directory.user.suspend` (true) | WRITE_HIGH | yes | F5 | |
| `directory.user.suspend` (false) | WRITE_HIGH | yes | **F6** | Restoring access is its own family, capped lower |
| `licensing.assignment.delete` / `.insert` / `.patch` | WRITE_HIGH | yes | F7 | Pre-state records the SKU so re-insert is exact |
| `run.rollback` | WRITE_HIGH | — | **F10** | Always a **fresh** human approval against **fresh** pre-state, at every stage. A whole run's inverse is released by one approval, so recovery is not slower than the failure |

`SAFE_USER_FIELDS` is a hard allowlist in code: name, organizations, phones, locations,
relations. It can never touch password, `isAdmin`, 2SV, aliases, `recoveryEmail` or
`recoveryPhone`. Recovery fields are account-takeover vectors and are excluded even though
they look like profile data.

**`orgUnitPath` was removed from that list.** In Workspace the organisational unit *is*
the carrier of policy — 2-step verification, context-aware access, sharing, app access,
Gemini availability. Moving a user between units changes their security posture without
touching a single security setting, which walks straight through the rule that Wall-E may
never alter posture. Worse, the policy chain only ever checked the target's **current**
unit, so a move could land someone outside Wall-E's own allowlist, where even the inverse
could not reach them: a "reversible" operation that moves its own target beyond its reach.

So `directory.user.move_ou` is its own operation, with typed `from_ou` and `to_ou`, a
pre-state assertion that `from_ou` matches what is observed, and a **separate**
`ou_destination_allowlist`. A destination outside it is a hard invariant, not a refusal.
CI asserts `ou_destination_allowlist` is a subset of every family's `ou_allowlist`.

Risk tiers are static properties of an operation. Rate limits per tier: READ 120/min,
WRITE_LOW 20/min, WRITE_HIGH 5/min, **enforced durably** (see below).

## Playbooks

A playbook is what an autonomous run executes. It is not a prompt.

```yaml
leaver-checklist:
  version: 4
  owner: <named operator>             # must be in walle-operators@ at run time
  trigger: { event: "admin.USER_SUSPENDED" }
  selection: directory.user.list      # deterministic query, not model-chosen
  uses: [directory.user.get, directory.group.members.list,
         directory.group.member.remove, notify.operators]
  level: L2                            # a playbook may cap itself below the family level
  max_objects_per_run: 10
  expects: "user is in no group except the baseline; user in the leavers OU (tbd)"
```

Rules the service enforces, not the prompt:

- An operation the agent names that is **not in `playbook.uses`** aborts the whole run
  with `playbook_violation`. The model plans within the playbook, never outside it.
- Targets are **explicit and enumerated**. There is no query-shaped write.
- **The selection query is pinned too**, and hashed into the playbook version. Pinning
  only the selection *operation* was not enough: `directory.user.list` takes a free-form
  query string, so a model steered by injected text could select an entire organisational
  unit and emit explicit per-target writes for all of it. Caps then turn a mass action
  into a drip of 25 a day rather than a refusal. Any read in an autonomous run whose
  parameters do not match the playbook's declared selection is denied with
  `selection_not_declared`.
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
5. **Principal check.** Humans must be in the operators group, or in `walle-readers@` for
   READ operations, verified through the Directory API, failing closed. The readers group
   exists so that reporting can be widened — someone who may ask "what changed last week"
   without being able to cause any write. Note that widening it means also sharing the
   agent with it in Gemini Enterprise, which is a separate act; membership alone grants
   nothing if the person cannot reach the agent. Machine principals must match the
   trigger class the request claims.
6. **Scope.** Target's `orgUnitPath` must be in the family's OU allowlist. Group targets
   must be in an allowed class.
7. **Budgets.** Per-run object cap, per-family daily write budget, tenant-wide daily cap,
   and novelty caps over rolling **7-day and 30-day** windows, not just per hour — a
   per-hour cap does nothing against a slow drip. Durable counters.

   **Shadow items evaluate budgets but never consume them.** At the shadow level the
   cap is checked and the would-be verdict recorded, and the counter is left alone.
   Otherwise Stage 0, whose daily write budget is zero, denies every shadow item with
   `budget_exceeded` before the level can force a dry run — and the evidence engine the
   entire ladder is argued from produces nothing.
8. **Business hours and freeze windows**, for machine principals.
9. **Rate limit**, per principal per tier, durable.
10. **Effective level** → execute, shadow, propose, or require an approval.
11. **Approval verification**, if one was supplied: signature, binding, expiry, nonce not
    yet consumed.
12. **Idempotency**, on the caller-supplied key.
13. Execute → **verify by re-reading** → audit.

Steps 1 to 4 are hard invariants: failing one is not a refusal, it is a breaker trip.

**Execution never happens inside the approve request.** Approving marks the plan
`released` and returns immediately; a Cloud Tasks worker executes one item at a time, each
as its own durable unit with its own halt check and its own full pass through this chain.
An earlier draft ran the item loop inside the request, which at 25 items and a five-per-
minute rate limit exceeds Cloud Run's default 300-second timeout — leaving a half-applied
plan, a consumed nonce, and no terminal state. Deploy the service with an explicit
`--timeout=60s` so that shape becomes impossible rather than merely unlikely.

**Re-run the chain, do not compare fields.** Before each item the worker repeats the whole
policy chain, including a forced protected-principal refresh. Comparing a stored pre-state
hash is not enough: a human restoring a suspended user between plan and execution leaves
the *membership* pre-state untouched, so group removals execute on an active account and
then verify perfectly clean. The write was correct; the premise was stale.

### Protected principals

Refuse any write whose target is a super admin, a delegated admin, the robot itself, the
robot's OU, a member of `walle-protected@`, or a **group** that grants an admin role or
controls Wall-E, Eve or Mo.

Defects seen in a first implementation of this check, all of which matter:

- It ran on **reads** too, so "who is the super admin?" was denied. Apply to writes only.
- It matched `isAdmin=true`, missing **delegated admins**. Include `isDelegatedAdmin`.
- It paginated at 200 with no continuation, silently truncating on a large tenant.
- The protected-group lookup swallowed exceptions, so it failed **open** while the design
  document said it failed closed.
- It never checked `group_key`, so "add me to `walle-operators@`" was an escalation path
  gated only by a model-mediated confirmation.
- It made two uncached Admin SDK calls on every directory operation. Cache with a short
  TTL, refreshed in the background, and fail closed if the cache cannot be filled.
- It resolved group members **non-transitively**, so adding `super-admins@` to the
  protected group protected that group's address and not one actual admin. Expand with
  `includeDerivedMembership`, paginate explicitly, and deny on truncation.
- It ran the admin enumeration under an **organisational-unit-scoped role**, which
  returns only admins inside the pilot unit — often none — and an empty result read as
  success. The read must be customer-scoped.

**The floor assertion.** A static list of known super-admin addresses is committed to git.
The computed protected set must be a **superset** of it, or every directory write is
denied with `protection_incomplete`, as a hard invariant. This is what turns a silent
truncation into a loud refusal, and it is the difference between a control and a hope. A
daily job reconciles the computed set against the floor list and alerts on divergence.

### Group classification

Every group is `low` (distribution, collaboration), `access` (grants Drive, app, licence
or GCP access) or `security` (grants an admin role, or controls Wall-E, Eve or Mo).
**Unclassified is treated as `security`** — fail closed. Membership writes are allowed on
`low` at higher levels, `access` only at lower ones, and `security` never.

**The classification is computed, not declared.** A hand-maintained file cannot be trusted
here, because nesting is invisible in the console: a small team distribution list that
happens to be a member of `walle-operators@` looks like an ordinary `low` group, and one
membership write into it would grant an attacker approval authority. A job resolves every
group's transitive ancestors and every admin role attached to them; any group whose
closure reaches a security-class group or an admin role is marked `security`
automatically. CI fails if the human file contradicts the computed closure. A group write
resolves ancestors **live** and fails closed on a lookup error.

That check needs `admin.directory.rolemanagement.readonly`, which is why it appears in the
scope list that freezes at consent — [02](02-identity-and-auth.md).

### Durable counters, not in-memory

A first implementation kept rate limits and idempotency in a Python dict, while its
Dockerfile ran two uvicorn workers and Cloud Run scales instances. The documented "5 WRITE_HIGH per minute"
was therefore 10 × instance count, and budgets meant nothing. For an autonomous doer,
every budget is a **transactional Firestore counter**, so the cap is global and honest.
Idempotency also moves to Firestore, applies to **writes only** (a cached read for ten
minutes would break post-execution verification), and keys on the caller's explicit
`idempotency_key` rather than a hash of parameters.

## Storage

### BigQuery `walle_audit`, partitioned by `ts`, clustered by `operation`

| Table | Purpose | Key columns beyond the obvious |
|---|---|---|
| `actions` | One row per request | `principal_type`, `principal_id`, `on_behalf_of`, `run_id`, `plan_id`, `trigger_id`, `family`, `risk`, `level`, `tainted`, `content_flags` (list of `filter:confidence` from the content screen), `screen_state` (`screened` / `skipped`), `config_version`, `ceilings_sha`, `catalogue_version`, `playbook_version`, `prompt_hash`, `model_id`, `decision`, `denial_reason`, `dry_run`, `pre_state_hash`, `post_state_hash`, `verification`, `approval_id`, `approver`, `approval_latency_ms`, `params_redacted`, `result_summary`, `latency_ms`, `error_class` |
| `runs` | One row per run | terminal state, counts, budget consumed, tokens, cost, `trace_id` from the dispatcher's `traceparent` so a Model Armor finding joins to the run |
| `plans` | Frozen plans with per-item pre-state | `plan_hash`, `rollback_hash` |
| `approvals` | Every approval and refusal | who, when, how long they took, verdict, reason code |
| `verifications` | Post-execution comparison | `verified` / `drift` / `unverifiable` |
| `config_versions` | Every ladder change | version, sha, decision file, deployer, origin `human`/`eve`/`breaker` |

Retention: 400 days by default, subject to your retention policy — [decision 17](09-open-decisions.md).

Three rules about the audit trail:

- **Write-ahead and fail-closed for writes.** A first implementation logged insert failures
  and carried on, so "audited before the response returns" was best-effort. If the audit sink
  is down, writes are refused. No evidence, no action.
- **Never store payloads.** `result_summary` in a first implementation was `str(result)[:500]`,
  which put email body excerpts into BigQuery. Store ids and counts. Redact query strings
  and the `fields` map of a user update.
- The action service's service account gets **insert-only** rights on the dataset. It must
  not be able to delete its own evidence.

### Firestore

| Collection | Holds |
|---|---|
| `control/mode`, `control/freeze` | Halt state, with `halt_epoch` |
| `overrides/{family}/{trigger}` | Live demotions, with `override_epoch`. Absent reads as **L0** |
| `ladder/current` | Deployed config, its version and `ceilings_sha` |
| `plans/{id}` | **Frozen plan and its lifecycle**: `pending_human`, `pending_eve`, `held_until`, `released`, `vetoed`, `expired`, `done`. Create-only for the action service, so a signed plan cannot be rewritten |
| `approvals/{id}` | Nonce, binding, consumer, timestamps |
| `in_flight/{run_id}#{item}` | Written before a Workspace call, resolved after. The reconciler's input |
| `proposals/{id}` | Proposal queue with **verdict and reason code**, and the operator's grade |
| `grades/{run_id}#{item}` | Shadow gradings — the input to the precision metric every promotion cites |
| `leases/{principal}` | One active run per target, plan freeze to terminal state |
| `cooldown/{principal}` | No autonomous write to a principal written to in the last 24 h |
| `counters/{scope}/{window}` | Budgets, rate limits, novelty |
| `idempotency/{key}`, `dedup/{trigger_id}` | Replay suppression |
| `drills/{date}` | Kill-switch drill results and measured times — what CI reads to refuse a stale promotion |
| `canary/{family}/{trigger}` | Run counter and target sample for a newly promoted cell |

An earlier draft listed only the first, second, fifth and last few. Everything else was a
control named in the enablement plan with nowhere to live: plan states, proposal verdicts,
shadow grades, drill dates, leases and the canary sampler all had no storage, which meant
the metrics that gate every promotion had nothing to read.

## Denial reasons

Metrics, alerts, breakers and CI gates all key on these strings, so they are a closed
vocabulary defined here and nowhere else.

| Reason | Hard invariant | Meaning |
|---|---|---|
| `operation_not_allowed` | yes | Not in the catalogue |
| `protected_principal` | yes (autonomous only) | Target is an admin, the robot, a control group |
| `protection_incomplete` | yes | The protected set failed its floor assertion |
| `bad_approval`, `approval_already_used`, `approver_is_agent` | yes | Approval forged, replayed, or posted by the model |
| `level_bypass` | yes | A request tried to act above its effective level |
| `control_plane_unavailable` | yes | Firestore unreadable — fail closed |
| `selection_not_declared` | yes | An autonomous read outside the playbook's pinned query |
| `ou_destination_not_allowed` | yes | An organisational-unit move to an unlisted destination |
| `level_off`, `level_no_execute` | no | The level forbids execution |
| `invalid_parameters`, `playbook_violation` | no | Malformed or out-of-playbook request |
| `actor_not_authorised`, `foreign_actor` | no | Caller is not an operator |
| `halted`, `budget_exceeded`, `rate_limited`, `outside_window` | no | A gate did its job |
| `state_changed`, `lease_held` | no | Someone else got there first |
| `audit_unavailable` | no | No evidence, no action |

A hard invariant denies, writes an audit row, **and trips the breaker** for that family —
except `protected_principal` arising from a **human chat request**, which is an ordinary,
correct refusal. An operator asking about someone who turns out to be a delegated admin
must not halt the programme.

## Errors never carry upstream text

The service returns `{error_class, audit_id}` from a closed set: `not_found`, `conflict`,
`quota`, `forbidden`, `invalid`, `backend`. Full detail goes to Cloud Logging.

This is not tidiness. Google's error bodies echo the request, so a failed membership call
echoes an address and a failed update can echo submitted field values — and an attacker
who sets their own display name to instruction-shaped text gets that text delivered into
the model's context as a **tool error**, which reads as the system speaking rather than as
content. Denial details are service-authored sentences with no parameters interpolated.

Every attacker-writable string is canonicalised before it reaches a model **or an approval
card**: strip control characters, bidirectional overrides and zero-width characters,
collapse whitespace, cap the length, escape markdown. The approval card matters as much as
the model, because a hostile display name could otherwise make one item of a batch render
as though it were something else.

## The agent

- ADK 2.8.x on Agent Runtime, `google-adk~=2.8` with the `a2a`, `gcp` and `agent-identity`
  extras. Deployed with `vertexai.Client(...).agent_engines.create(...)`, service account
  `walle-agent@`, `min_instances=0`, tracing on.
- **Tools are generated from `/v1/operations`**, not hand-written. A hand-written tool set in a
  first implementation exposed 12 of 16 catalogue operations and never sent `dry_run`, so a
  flow the design depended on could not happen. Generation makes drift impossible.
- Two entry modes in one deployment: interactive (`user_id` = the human's email) and job
  (`user_id` = `job:<playbook>`, message = a structured envelope carrying `run_id`,
  playbook version and budget).
- **The dispatcher invokes the agent with `streamQuery`, never `query` or `asyncQuery`.**
  Model Armor on the ingress gateway screens only `reasoningEngines.streamQuery` for ADK
  agents; every other method passes unscreened. A dispatcher that calls `query` silently
  removes the prompt-screening layer. CI forbids the other two methods, and the dispatcher
  sends a `traceparent` header and stores the trace id on the run record so a Model Armor
  finding can be walked to the exact tool result. See [11-prompt-security.md](11-prompt-security.md).
- Sessions: managed, EU. **Memory Bank off** — an admin agent should not accumulate
  long-term memories about employees, and it keeps the DPIA simpler.
- A `WallEPolicyPlugin` registered on the runner mirrors the catalogue and level in
  `before_tool`, injects `run_id` and principal into every call, and emits structured
  events. It is **defence in depth, not the trust boundary** — a code change can bypass a
  plugin, and nothing in the model's process is authoritative.
- The Gemini Enterprise console's Model Armor setting does **not** cover custom ADK
  agents — that part is documented and true. But it does not follow that screening has to
  live in agent code, as an earlier draft said. Prefer the two that Wall-E's own code
  cannot switch off: **Model Armor on Agent Gateway**, generally available since
  2026-06-24 and covering ADK-on-Agent-Runtime ingress, and project-level **floor
  settings**, which apply to the agent's model calls with no code change. The first-party
  `ModelArmorPlugin` in `google-adk` 2.8 is a third option, weakest of the three because
  it is in the process it protects. Two failure modes, and they differ. On the **Agent Gateway** path Model Armor is attached through a Service Extensions authorization extension whose `failOpen` is false in Google's own sample and defaults to false, so a Model Armor timeout or error **stops the request**: fail-closed. On the **floor-settings** path, which screens the agent's own `generateContent` calls, an error **skips sanitisation and continues**: fail-open. Detail in [11-prompt-security.md](11-prompt-security.md).
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
