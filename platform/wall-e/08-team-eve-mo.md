# 8. The team — Wall-E, Eve and Mo

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Placement, 2026-09-13: the three agents and the Gemini Enterprise app live in four
  separate GCP projects. [../project-topology.md](../project-topology.md) is the authority
  for which project each identity, key, secret, dataset and topic sits in and for the exact
  form of every grant that crosses; this page names the home project on each row and
  points there rather than restating the grants. The contract itself is unchanged.
- Eve and Mo are now designed: [../eve/README.md](../eve/README.md) and
  [../mo/README.md](../mo/README.md), written 2026-09-12 against this contract. Where they
  depart from it, or where this page contradicts another Wall-E page, the departures are
  listed in [../eve/08-contract-changes.md](../eve/08-contract-changes.md) rather than
  edited in here. **This page has not yet been reconciled with them.**

Eve and Mo are designed separately, after this. This document exists so those two designs
have a fixed contract to attach to, and so Wall-E is built with the right seams from the
first commit rather than retrofitted. It is written to be handed to whoever designs them.

## The separation that makes a team worth having

Three agents are only safer than one if they cannot collapse into one. Three rules:

1. **No agent both decides and acts.** Wall-E acts and never approves. Eve approves and
   never acts on Workspace. Mo proposes and does neither.
2. **No agent grades its own work.** Wall-E's verification (re-read after write) is a
   sanity check, not evidence. Eve verifies **independently**, with its own read-only
   credential and against the Workspace audit log, which is written by Google rather than
   by Wall-E.
3. **Only humans loosen anything.** Eve and Mo can lower a level, halt, and propose. The
   raise path goes through a pull request, CI validation and a dated decision record with
   a named human — two of them above L3.

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

**Shared responsibility, concretely.** All three own the outcome "Workspace admin work is
done correctly and safely". They own different halves of it: Wall-E owns *doing the work*,
Eve owns *nothing bad getting through and stopping it fast when it does*, Mo owns *the
system getting better rather than merely older*. The place they meet is the audit dataset
and the `walle-events` topic, both in `WALLE_PROJECT`, reached from `EVE_PROJECT` and
`MO_PROJECT` through dataset-level `roles/bigquery.dataViewer` and, once a consumer names
a duty for the topic, a subscription in the reader's own project — one shared set of
facts, three different readings. No agent's identity is homed in another agent's project
([../project-topology.md](../project-topology.md)).

## Identities

| Agent | Home project | Runtime identity | Workspace credential | Secrets it may read | Can it call the action service? |
|---|---|---|---|---|---|
| Wall-E | `WALLE_PROJECT` | `walle-agent@` on Agent Runtime, or the agent principal ([12](12-agent-identity.md)) | none | none | Yes, execute and plan endpoints |
| Eve | `EVE_PROJECT` | `eve-controller@EVE_PROJECT` (Eve's design adds `eve-v0@`, `eve-verifier@`, `eve-console@`, all in `EVE_PROJECT`) | **Its own read-only robot account** — [decision 10](09-open-decisions.md) says yes; its OAuth client and refresh token live in `EVE_PROJECT`'s Secret Manager, provisioned by [../eve/07-build-runbook.md](../eve/07-build-runbook.md), never in Wall-E's project | `roles/cloudkms.signer` on its own asymmetric key `eve-approval`, in `EVE_PROJECT`; Wall-E verifies with the pinned public PEM | Yes, control and read endpoints only: `roles/run.invoker` on `walle-actions` in `WALLE_PROJECT`, a cross-project **resource-level** binding made by Wall-E's owner |
| Mo | `MO_PROJECT` | `mo-metrics@`, `mo-analyst@`, `mo-narrator@` (designed 2026-09-12, [../mo/02-identity-and-access.md](../mo/02-identity-and-access.md)) | none | none | Only `mo-analyst@MO_PROJECT`, on the two read endpoints (`roles/run.invoker` on `walle-actions`, cross-project). `mo-metrics@MO_PROJECT` holds dataset-level `dataViewer` on `walle_audit` and `walle_workspace_logs`. Nothing of Mo's lives in `WALLE_PROJECT` |

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
| Pub/Sub `walle-events` | `run.started`, `plan.ready`, `step.pending`, `step.executed`, `run.verified`, `override.applied`, `halt.set`, `content.flagged` (payload: `run_id`, `audit_id`, `source: gateway\|actions`, the `filter:confidence` list, `trigger_id`; emitted for dispatcher-invoked runs only, see [11](11-prompt-security.md) section 6) | subscribe | subscribe | `WALLE_PROJECT`. Target state ([14](14-hld-challenge.md) C30): a subscription created in the reader's project with `roles/pubsub.subscriber` bound on the topic |
| Workspace audit logs in Cloud Logging | what the robot account actually did, **written by Google, not by Wall-E** | read | read | Organisation level. Eve reads its own organisation-level sink into `EVE_PROJECT`; Mo reads Wall-E's copy `walle_workspace_logs` in `WALLE_PROJECT` through dataset-level `dataViewer` |
| Agent Runtime traces and OTel metrics | token spend, tool-call counts, latency per run | — | read | `WALLE_PROJECT`. Mo's cross-project read is *tbd* — `Assumption:` a dataset-level `READER` on the linked `walle_spans` dataset, never a project-level viewer role (decision 49) |
| `ladder.yaml` in git | what the level *should* be | read | read | The repository; crosses no project |

Join key: `run_id` throughout, plus the ADK `invocation_id` linking traces to audit rows.

## Interfaces Wall-E must expose

These are the endpoints to build in the action service from the start, even before Eve
exists. Until then they are exercised by a stub caller in the test suite.

Machine callers are named by their full cross-project service-account email. Each holds
`roles/run.invoker` on `walle-actions` in `WALLE_PROJECT` — a resource-level binding made by
Wall-E's owner — and appears in the in-app allowlist by that email, compared byte for byte.

| Interface | Caller | Contract |
|---|---|---|
| `GET /v1/plans/{id}` | Eve (`eve-controller@EVE_PROJECT`), Mo (`mo-analyst@MO_PROJECT`) | Frozen plan, `plan_hash`, per-item pre-state, `expects`, rollback plan, per-item policy verdict, effective level, config version |
| `GET /v1/runs/{id}` | Eve (`eve-controller@EVE_PROJECT`), Mo (`mo-analyst@MO_PROJECT`) | Run record with terminal state, budgets consumed, per-item outcomes |
| `POST /v1/plans/{id}/approve` | Eve (`eve-controller@EVE_PROJECT`), or the out-of-band human surface. **Never the agent** | Signed with Eve's **Cloud KMS asymmetric key** in `EVE_PROJECT`, verified by the service with the public half pinned as PEM in Wall-E's repository. Carries `plan_hash` and `config_version`, rejected if either differs. Eve signs a hash **it computed itself** |
| `POST /v1/plans/{id}/veto` | operator, Eve | During a hold window |
| `POST /v1/control/halt` | operator, Eve | `{mode: run \| no_autonomous \| no_writes \| halt_all, reason}` |
| `POST /v1/control/demote` | operator, Eve | `{family, trigger, to_level, reason}`. **Refuses any value higher than the configured level.** There is no raise endpoint at all. |
| `GET /v1/ladder` | any authorised | Effective matrix, ceilings, overrides, halt state, config version, last drill date |
| `GET /healthz` | Eve | Liveness plus **last successful audit write**, so Eve can halt when evidence stops flowing |

Two hard requirements on these:

- **They are plain authenticated REST, not agent-to-agent messages.** Eve must be able to
  stop Wall-E when the model layer is wedged, hallucinating, or looping. A safety interlock
  that runs through an LLM is not an interlock. Agent-to-agent protocol is fine for
  delegating conversational work later; it is not fine for halt and approve.
- **`walle-agent@` is excluded from all of them — but not by `run.invoker`.** That grant
  is per *service*, not per path, so IAM alone cannot express this and an earlier draft
  was simply wrong to claim it did. The exclusion is a per-endpoint caller allowlist
  inside the service, keyed on the verified identity token — whose allowed values now
  include service-account emails from `EVE_PROJECT` and `MO_PROJECT` — and ideally a second Cloud Run
  service for the control plane ([decision 18](09-open-decisions.md)). Test it: the agent
  calling `/v1/control/demote` must get a 403.

## What Eve must do (input to its design)

Not a design, a requirements list:

1. **Pre-approval at L4.** Read the frozen plan, verify independently that the pre-state is
   what Wall-E claims, check the plan against the playbook's `expects`, and sign or refuse.
2. **Post-hoc verification at L5**, within 60 minutes, by reading Workspace directly and
   cross-checking the Workspace audit log for events attributed to the robot.
   **Independence has a limit worth naming:** at the pre-approval step Eve reads the plan
   from the very service it is checking. Computing the hash itself and re-reading
   Workspace with its own credential narrows that, but does not close it.
3. **Reconciliation.** Every admin-audit event by the robot must have a matching Wall-E
   audit row, and vice versa. A gap in either direction halts writes.
4. **Drift detection.** Rows whose `config_version` does not match the deployed ladder, or
   levels in Firestore that do not match `ladder.yaml`.
5. **Halting**, on its own judgement, with a reason code, and a documented bias toward
   halting when uncertain.
6. **Attestation.** For a promotion, produce a dated, signed evidence bundle. It attests;
   it never promotes.
7. **Fail closed in every direction.** Eve down means L4 items wait and L5 cells demote to
   L4. Eve must never be a thing whose absence lets more happen.

Eve's own progression mirrors Wall-E's: it runs in observe mode through Stage 3, graded
against human verdicts, and only becomes load-bearing at Stage 4 once it has passed a
seeded-fault exercise.

## What Mo must do (input to its design)

1. Compute the ladder metrics from [05](05-autonomy-ladder.md) §8 and publish them where a
   promotion decision can cite them.
2. Produce a **promotion-readiness scorecard** per (family, trigger): current level, dwell
   elapsed, every exit criterion with its measured value, and a verdict of ready or not,
   with the reason.
3. Explain regressions: which playbook version, prompt version, model id or config version
   a change in precision or drift coincides with. This is why those four fields are on
   every audit row.
4. Propose improvements as **pull requests** — playbook selection queries, prompt changes,
   catalogue additions, cap changes, promotions and demotions — each with evidence
   attached and each requiring a human merge.
5. Report cost per operation and per playbook, from token spend and runtime metering.
6. Never hold a credential, never call the action service, never write to config.

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
