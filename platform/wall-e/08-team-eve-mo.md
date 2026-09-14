# 8. The team — Wall-E, Eve and Mo

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- The contract Eve's and Mo's designs attach to, written against the platform objective of
  2026-09-13 (Wall-E holds Super Admin, P33; [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md)
  §13.2, §13.3); where those designs depart from it, the departures are listed in
  [../eve/08-contract-changes.md](../eve/08-contract-changes.md) and
  [../mo/08-open-decisions.md](../mo/08-open-decisions.md), and placement is
  [../project-topology.md](../project-topology.md).

This document gives Eve's and Mo's designs ([../eve/README.md](../eve/README.md),
[../mo/README.md](../mo/README.md), both designed on 2026-09-12) a fixed contract to attach to,
so that Wall-E is built with the right seams from the first commit rather than retrofitted. Since
2026-09-13 the platform HLD owns the interfaces all three attach to.

## The separation that makes a team worth having

Three agents are only safer than one if they cannot collapse into one. Three rules:

1. **No agent both decides and acts.** Wall-E acts and never approves. Eve approves and
   never acts on Workspace. Mo proposes and does neither.
2. **No agent grades its own work.** Wall-E's verification (re-read after write) is a
   sanity check, not evidence. Eve verifies **independently**, with its own read-only
   credential and against the Workspace audit log, which is written by Google rather than
   by Wall-E.
3. **Only humans loosen anything. Eve can lower; Mo can only propose** (platform HLD §13.3).
   Eve can lower a level and halt. Mo holds no
   credential, no invoker and no signer, and reaches production only through a pull request a
   human merges, whether the change is Wall-E's or Eve's. The raise path goes through a pull
   request, CI validation and a dated decision record with a named human — two of them above
   L3. A loosening of Eve's thresholds needs two reviewers, including the decision-37 security
   reviewer.

If a single design change would let one agent do two of decide, act and grade, that change
is wrong regardless of how convenient it is.

## Responsibilities

| Event | Wall-E | Eve | Mo | Human |
|---|---|---|---|---|
| Plan an operation | **Does** | — | — | Asks (chat) |
| Decide it is permitted | — | — | — | The action service decides, deterministically |
| Approve a `WRITE_HIGH` at L3 | Relays | — | — | **Approves** |
| Approve at L4 | Relays | **Approves** | — | May veto |
| Execute | **Does** | Never | Never | Never |
| Verify the result | Self-check | **Independent verification** | — | Reads the digest |
| Halt or demote | Cannot | **Can, instantly** | Cannot | **Can, instantly** |
| Raise a level | Never | Never | Proposes | **Decides**, two humans above L3 |
| Detect drift between config and reality | — | **Does** | — | Reads the alert |
| Explain why precision fell | — | — | **Does** | Reviews |
| Change a playbook or prompt | — | — | Proposes a PR | Merges |
| Report misbehaviour of Wall-E, or of a human prompting it | — | **Does**: deterministic detection catalogue at severity 1–3; the reporting path `eve-advisor` narrates and may page at severity 2 only | — | The second human outside the Wall-E line receives it; halts or demotes through the human path |
| Measure Eve's detection quality and time-to-report | — | Keeps its own fast drop to advisory on its own number | **Does**: the Eve quality pack, from `grades_eve`, `seeded_fault_runs`, golden replays and Wall-E's `eve_last_seen`, never from `eve.verdicts` alone | Grades Eve's verdicts on the approval surface |
| Explain an Eve regression | — | — | **Does**, keyed on `eve_config_version` | Reviews |
| Change Eve's thresholds or seeded faults | — | Never edits its own rules | Proposes a PR from the closed set `eve_threshold_tighten`, `eve_threshold_loosen`, `seeded_fault_addition`, `eve_incident_note` | Merges: one reviewer to tighten, two (one the security reviewer) to loosen |
| Grade Eve | — | — | **Never** — Mo is not Eve's grader | Grades |

**Shared responsibility, concretely.** All three own the outcome "Workspace admin work is
done correctly and safely". They own different halves of it: Wall-E owns *doing the work*,
Eve owns *nothing bad getting through and stopping it fast when it does*, Mo owns *the
system getting better rather than merely older*. The place they meet is the audit dataset
and the `walle-events` topic, both in `WALLE_PROJECT`, reached from `EVE_PROJECT` and
`MO_PROJECT` through dataset-level `roles/bigquery.dataViewer` and, once a consumer names
a duty for the topic, a subscription in the reader's own project — one shared set of
facts, three different readings. No agent's identity is homed in another agent's project
([../project-topology.md](../project-topology.md)). Since Mo improves Eve
too, a second meeting place exists: `eve_quality` in `EVE_PROJECT`, which Eve owns and Mo
reads (platform HLD §13.3). Mo owns the outcome "Wall-E **and Eve** getting better", and
"stopping it fast" includes reporting it to a human outside the Wall-E line.

## Identities

No agent's identity is homed in another agent's project, and every grant that crosses a project
is a row of [../project-topology.md](../project-topology.md#3-cross-project-grants) §3.

| Agent | Home project | Identities, and credential | Reach into Wall-E's action service | Defined in |
|---|---|---|---|---|
| Wall-E | `WALLE_PROJECT` | `walle-agent@` on Agent Runtime, or the agent principal; no Workspace credential, no secrets | Execute and plan endpoints | [02](02-identity-and-auth.md), [12](12-agent-identity.md) |
| Eve | `EVE_PROJECT` | `eve-controller@`, `eve-v0@`, `eve-verifier@`, `eve-console@`; its own read-only robot account ([decision 10](09-open-decisions.md)) whose OAuth client and refresh token live in `EVE_PROJECT`, never in Wall-E's project; `roles/cloudkms.signer` on its own key `eve-approval`, verified by Wall-E with the pinned PEM | Control and read endpoints only (`roles/run.invoker` on `walle-actions`, made by Wall-E's owner) | [../eve/02-identity-and-auth.md](../eve/02-identity-and-auth.md) |
| Mo | `MO_PROJECT` | `mo-metrics@`, `mo-analyst@`, `mo-narrator@`; no credential, no secrets, nothing in `WALLE_PROJECT` or `EVE_PROJECT` | `mo-analyst@` on the two read endpoints only; `mo-metrics@` reads `walle_audit`, `walle_workspace_logs` and `eve_quality` at dataset level | [../mo/02-identity-and-access.md](../mo/02-identity-and-access.md) |

**Eve should get its own Workspace credential.** If Eve verifies through Wall-E's
credential, a compromised Wall-E path can make the world look however it wants to the
verifier. A second robot account with read-only privileges and its own consented refresh
token costs one more bootstrap and buys genuinely independent observation. Recommended;
[decision 10](09-open-decisions.md).

## The shared data plane

Everything Eve and Mo need already exists in Wall-E's design. Neither reads Wall-E's memory
or asks Wall-E questions about itself.

| Surface | Contents | Eve | Mo | Lives in / crossed by |
|---|---|---|---|---|
| BigQuery `walle_audit.actions` | every request with principal, level, config version, decision, pre/post hashes, verification | read | read | `WALLE_PROJECT`. Read through dataset-level `roles/bigquery.dataViewer` granted to Eve's and Mo's identities in `EVE_PROJECT` and `MO_PROJECT`; jobs run and are billed in the reader's project, never `jobUser` in Wall-E's |
| `walle_audit.runs`, `plans` | frozen plans, per-item pre-state, rollback plan, terminal state, budgets, cost | read | read | as above |
| `walle_audit.approvals` | who approved what, how long they took, verdicts and reason codes | read | read | as above |
| `walle_audit.verifications` | verified / drift / unverifiable | read | read | as above |
| `walle_audit.config_versions` | every ladder change, its decision file, its origin | read | read | as above |
| Band-B audit rows on `walle-actions-super` | the full canonical request, the Discovery revision, requester and approver, both human super admins | read | read | `WALLE_PROJECT`, on the platform `audit.schema` (platform HLD §12.3); the same dataset-level grant form |
| BigQuery `eve_quality` | `findings`, `verdicts`, `attestations`, `pages`, `incidents` minus narrative, `seeded_fault_runs`, through authorised views with no free-text columns; never `grades_blind` or `review_queue_blind` | owns | read | `EVE_PROJECT`. Dataset-level `READER` to `mo-metrics@MO_PROJECT` and to the validator custodian, made by Eve's runbook, with no binding in `MO_PROJECT` (platform HLD §13.3, P30; topology rows per HLD §18 item 25). Eve reads nothing Mo writes |
| `grades_eve` | human grades of Eve's verdicts, written by the platform approval surface, not by `eve-console` | — | read | per platform HLD §13.3 |
| Pub/Sub `walle-events` | `run.started`, `plan.ready`, `step.pending`, `step.executed`, `run.verified`, `override.applied`, `halt.set`, `content.flagged` (payload: `run_id`, `audit_id`, `source: gateway\|actions`, the `filter:confidence` list, `trigger_id`; emitted for dispatcher-invoked runs only, see [11](11-prompt-security.md) section 6) | none (Eve CC-13) | none (Mo change 10) | `WALLE_PROJECT`. Target state ([14](14-hld-challenge.md) C30): a subscription created in the reader's project with `roles/pubsub.subscriber` bound on the topic. Neither Eve nor Mo subscribes, so the topic stays, and its owner and schema are *tbd* — the obligation of whoever later asks for it (Eve E-20) |
| Workspace audit logs in Cloud Logging | what the robot account actually did, **written by Google, not by Wall-E** | read | read | Organisation level. Eve reads its own organisation-level sink into `EVE_PROJECT`; Mo reads Wall-E's copy `walle_workspace_logs` in `WALLE_PROJECT` through dataset-level `dataViewer`. Eve's sink covers all six Workspace streams with no actor exclusion, plus a Reports API poll by actor |
| Agent Runtime traces and OTel metrics | token spend, tool-call counts, latency per run | — | read | `WALLE_PROJECT`. Mo's cross-project read is *tbd* — `Assumption:` a dataset-level `READER` on the linked `walle_spans` dataset, never a project-level viewer role (decision 49) |
| `ladder.yaml` in git | what the level *should* be | read | read | The repository; crosses no project |

Join key: `run_id` throughout, plus the ADK `invocation_id` linking traces to audit rows.

## Interfaces Wall-E must expose

The action service exposes eight plain authenticated REST interfaces to Eve, Mo and operators —
`GET /v1/plans/{id}`, `GET /v1/runs/{id}`, `POST /v1/plans/{id}/approve`, `POST /v1/plans/{id}/veto`,
`POST /v1/control/halt`, `POST /v1/control/demote`, `GET /v1/ladder` and `GET /healthz` — built
from the first commit and exercised by a stub caller in the test suite until Eve exists. They are
plain REST, not agent-to-agent messages, because Eve must be able to stop Wall-E when the model
layer is wedged, hallucinating or looping, and a safety interlock that runs through an LLM is not an
interlock. `walle-agent@` is excluded from all of them by a per-endpoint caller allowlist inside the
service keyed on the verified identity token, because `run.invoker` is granted per service, not per
path; endpoints, callers, allowlists and their 403 tests are
[03-lld.md](03-lld.md#action-service--interface) §"Action service — interface".

The contract each interface carries:

| Interface | Contract |
|---|---|
| `GET /v1/plans/{id}`, `GET /v1/runs/{id}` | Plan: frozen plan, `plan_hash`, per-item pre-state, `expects`, rollback plan, per-item policy verdict, effective level, config version. Run: terminal state, budgets consumed, per-item outcomes |
| `POST /v1/plans/{id}/approve`, `.../veto` | Approve carries Eve's signature over a `plan_hash` Eve computed itself, and `config_version`; rejected if either differs. Veto during a hold window |
| `POST /v1/control/halt`, `POST /v1/control/demote` | Halt `{mode: run \| no_autonomous \| no_writes \| halt_all, reason}`. Demote `{family, trigger, to_level, reason}`, refusing any value higher than the configured level; there is no raise endpoint at all |
| `GET /v1/ladder` | Effective matrix, ceilings, overrides, halt state, config version, last drill date |
| `GET /healthz` | Liveness plus **last successful audit write**, so Eve can halt when evidence stops flowing |

## What Eve must do (input to its design)

These requirements are now met by Eve's design: pre-approval at L4 on a hash Eve computes itself,
post-hoc verification of L5 writes within 60 minutes, two-direction reconciliation that halts writes
on a gap, config and ladder drift detection, halts on declared thresholds with a reason code by a
control path that contains no model, signed attestations that never promote, failing closed in
every direction, and independent reporting of misbehaviour to a human outside the Wall-E line
through the witness and the `eve-advisor` reporting path (P34). The components that meet them are
[../eve/01-hld.md](../eve/01-hld.md#components) §"Components", the limits on Eve's independence are
§"What this design does not close" there, and every departure from the requirements as first
written is a row of [../eve/08-contract-changes.md](../eve/08-contract-changes.md#1-the-contract-change-table) §1.
Eve's gate layer runs in observe mode through Stage 3 and becomes load-bearing at Stage 4 after the
seeded-fault exercise, while its observe-and-report layer is live and drilled **before** Super Admin
is granted ([05](05-autonomy-ladder.md) §7, "The super-admin grant — a gate, not a stage").

## What Mo must do (input to its design)

These requirements are now met by Mo's design, which improves Wall-E and Eve from one Mo per
platform ([../mo/01-hld.md](../mo/01-hld.md#thesis) §"Thesis"): it computes the ladder metrics and
the Eve quality pack ([../mo/03-metrics-contract.md](../mo/03-metrics-contract.md#7-the-ten-metrics-the-ladder-is-argued-from) §7,
§7.3), publishes a promotion-readiness scorecard per (family, trigger), explains Wall-E and Eve
regressions, reports cost per operation and per playbook, and never grades Eve. It proposes changes
only as pull requests a human merges — Eve changes from a closed proposal set against
`thresholds.yaml` and `seeded_faults` only
([../mo/04-artefacts-and-proposals.md](../mo/04-artefacts-and-proposals.md#35-the-closed-proposal-type-set) §3.5–§3.6) —
and it holds no credential, never writes to config, and calls the action service only on the two
read endpoints as `mo-analyst@MO_PROJECT` (Mo change 9, [../mo/08-open-decisions.md](../mo/08-open-decisions.md)).

A pragmatic note for Mo's design: Mo is analysis over BigQuery with no Workspace access and
no write path, which makes it the one place in this team where trying a different model or
harness costs nothing in safety. If you ever want to compare model families on this
platform, do it in Mo.

## Failure modes of the team itself

| Scenario | What must happen |
|---|---|
| Eve down | L4 waits. Over four business hours, `no_autonomous` is set automatically. Never fall through to execute. |
| Eve compromised | It can approve within the current level's blast radius until the next sampled human review. Contained by hold windows, vetoes, caps, and the fact that it cannot raise a level. Revoking the `run.invoker` binding for `eve-controller@EVE_PROJECT` on `walle-actions` — made in `WALLE_PROJECT`, by Wall-E's owner — stalls every L4 step. |
| Eve and Wall-E disagree persistently | Neither wins automatically. Disagreement above threshold demotes the family and opens a root cause — the disagreement is the finding. |
| Mo proposes something harmful | Requires a human merge, CI validation, and a decision record. Two humans above L3. |
| All three unavailable | Nothing happens. The correct outcome. |
| A human bypasses all three and uses the Admin console | Legitimate and expected. It appears in the Workspace audit log; Eve sees a robot-attributable gap of zero and a human event, which is exactly right. Wall-E's pre-state re-read is what stops the two colliding. |
