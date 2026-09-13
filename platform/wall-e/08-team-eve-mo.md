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
  edited in here. ~~This page has not yet been reconciled with them.~~ *Rewritten 2026-09-13:*
  reconciled for Mo's remit over Eve, rule 3, Eve's item 5 and Mo's changes 9 and 10
  ([../mo/08-open-decisions.md](../mo/08-open-decisions.md)). Eve's other contract changes in
  [../eve/08-contract-changes.md](../eve/08-contract-changes.md) are still listed there, not
  here.
- **Objective restated 2026-09-13; see the platform HLD**
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.2, §13.3; §18 item 6).
  The objective says Mo "work on continuous improvements of both Wall-E & Eve". The
  responsibility table, the shared data plane and "What Mo must do" gain Eve rows, and rule 3
  reads "Eve can lower; Mo can only propose". Eve "should work independantly & autonomous" and
  "report to the human anything wrong", so item 5's "own judgement" is narrowed to Eve's
  reporting path. Halts stay on declared thresholds, and no model sits on the path that
  approves, halts, demotes or vetoes. Eve's independence inside the organisation is detective,
  not structural; the witness organisation is its structural part (platform HLD §13.2). Wall-E
  holds Super Admin (P33). The separation rules, identities, the eight interfaces and the
  team failure modes are otherwise unchanged.

~~Eve and Mo are designed separately, after this.~~ *Rewritten 2026-09-13: Eve and Mo were
designed on 2026-09-12 against this contract, and since 2026-09-13 the platform HLD owns the
interfaces all three attach to.* This document exists so those two designs
have a fixed contract to attach to, and so Wall-E is built with the right seams from the
first commit rather than retrofitted. It was written to be handed to whoever designed them.

## The separation that makes a team worth having

Three agents are only safer than one if they cannot collapse into one. Three rules:

1. **No agent both decides and acts.** Wall-E acts and never approves. Eve approves and
   never acts on Workspace. Mo proposes and does neither.
2. **No agent grades its own work.** Wall-E's verification (re-read after write) is a
   sanity check, not evidence. Eve verifies **independently**, with its own read-only
   credential and against the Workspace audit log, which is written by Google rather than
   by Wall-E.
3. **Only humans loosen anything. Eve can lower; Mo can only propose.** *(Reworded
   2026-09-13, platform HLD §13.3; was "Eve and Mo can lower a level, halt, and propose", which
   gave Mo a lowering power no Mo design holds.)* Eve can lower a level and halt. Mo holds no
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
| Report misbehaviour of Wall-E, or of a human prompting it (added 2026-09-13) | — | **Does**: deterministic detection catalogue at severity 1–3; the reporting path `eve-advisor` narrates and may page at severity 2 only | — | The second human outside the Wall-E line receives it; halts or demotes through the human path |
| Measure Eve's detection quality and time-to-report (added 2026-09-13) | — | Keeps its own fast drop to advisory on its own number | **Does**: the Eve quality pack, from `grades_eve`, `seeded_fault_runs`, golden replays and Wall-E's `eve_last_seen`, never from `eve.verdicts` alone | Grades Eve's verdicts on the approval surface |
| Explain an Eve regression (added 2026-09-13) | — | — | **Does**, keyed on `eve_config_version` | Reviews |
| Change Eve's thresholds or seeded faults (added 2026-09-13) | — | Never edits its own rules | Proposes a PR from the closed set `eve_threshold_tighten`, `eve_threshold_loosen`, `seeded_fault_addition`, `eve_incident_note` | Merges: one reviewer to tighten, two (one the security reviewer) to loosen |
| Grade Eve (added 2026-09-13) | — | — | **Never** — Mo is not Eve's grader | Grades |

**Shared responsibility, concretely.** All three own the outcome "Workspace admin work is
done correctly and safely". They own different halves of it: Wall-E owns *doing the work*,
Eve owns *nothing bad getting through and stopping it fast when it does*, Mo owns *the
system getting better rather than merely older*. The place they meet is the audit dataset
and the `walle-events` topic, both in `WALLE_PROJECT`, reached from `EVE_PROJECT` and
`MO_PROJECT` through dataset-level `roles/bigquery.dataViewer` and, once a consumer names
a duty for the topic, a subscription in the reader's own project — one shared set of
facts, three different readings. No agent's identity is homed in another agent's project
([../project-topology.md](../project-topology.md)). *Added 2026-09-13:* since Mo improves Eve
too, a second meeting place exists: `eve_quality` in `EVE_PROJECT`, which Eve owns and Mo
reads (platform HLD §13.3). Mo owns the outcome "Wall-E **and Eve** getting better", and
"stopping it fast" includes reporting it to a human outside the Wall-E line.

## Identities

| Agent | Home project | Runtime identity | Workspace credential | Secrets it may read | Can it call the action service? |
|---|---|---|---|---|---|
| Wall-E | `WALLE_PROJECT` | `walle-agent@` on Agent Runtime, or the agent principal ([12](12-agent-identity.md)) | none | none | Yes, execute and plan endpoints |
| Eve | `EVE_PROJECT` | `eve-controller@EVE_PROJECT` (Eve's design adds `eve-v0@`, `eve-verifier@`, `eve-console@`, all in `EVE_PROJECT`) | **Its own read-only robot account** — [decision 10](09-open-decisions.md) says yes; its OAuth client and refresh token live in `EVE_PROJECT`'s Secret Manager, provisioned by [../eve/07-build-runbook.md](../eve/07-build-runbook.md), never in Wall-E's project | `roles/cloudkms.signer` on its own asymmetric key `eve-approval`, in `EVE_PROJECT`; Wall-E verifies with the pinned public PEM | Yes, control and read endpoints only: `roles/run.invoker` on `walle-actions` in `WALLE_PROJECT`, a cross-project **resource-level** binding made by Wall-E's owner |
| Mo | `MO_PROJECT` | `mo-metrics@`, `mo-analyst@`, `mo-narrator@` (designed 2026-09-12, [../mo/02-identity-and-access.md](../mo/02-identity-and-access.md)) | none | none | Only `mo-analyst@MO_PROJECT`, on the two read endpoints (`roles/run.invoker` on `walle-actions`, cross-project). `mo-metrics@MO_PROJECT` holds dataset-level `dataViewer` on `walle_audit` and `walle_workspace_logs` and, added 2026-09-13, dataset-level `READER` on `eve_quality` in `EVE_PROJECT`, made by Eve's runbook. Nothing of Mo's lives in `WALLE_PROJECT` or `EVE_PROJECT` |

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
| Band-B audit rows on `walle-actions-super` (added 2026-09-13) | the full canonical request, the Discovery revision, requester and approver, both human super admins | read | read | `WALLE_PROJECT`, on the platform `audit.schema` (platform HLD §12.3); the same dataset-level grant form |
| BigQuery `eve_quality` (added 2026-09-13) | `findings`, `verdicts`, `attestations`, `pages`, `incidents` minus narrative, `seeded_fault_runs`, through authorised views with no free-text columns; never `grades_blind` or `review_queue_blind` | owns | read | `EVE_PROJECT`. Dataset-level `READER` to `mo-metrics@MO_PROJECT` and to the validator custodian, made by Eve's runbook, with no binding in `MO_PROJECT` (platform HLD §13.3, P30; topology rows per HLD §18 item 25). Eve reads nothing Mo writes |
| `grades_eve` (added 2026-09-13) | human grades of Eve's verdicts, written by the platform approval surface, not by `eve-console` | — | read | per platform HLD §13.3 |
| Pub/Sub `walle-events` | `run.started`, `plan.ready`, `step.pending`, `step.executed`, `run.verified`, `override.applied`, `halt.set`, `content.flagged` (payload: `run_id`, `audit_id`, `source: gateway\|actions`, the `filter:confidence` list, `trigger_id`; emitted for dispatcher-invoked runs only, see [11](11-prompt-security.md) section 6) | ~~subscribe~~ none *(2026-09-13, Eve CC-13)* | ~~subscribe~~ none *(2026-09-13, Mo change 10)* | `WALLE_PROJECT`. Target state ([14](14-hld-challenge.md) C30): a subscription created in the reader's project with `roles/pubsub.subscriber` bound on the topic. *2026-09-13:* neither Eve nor Mo subscribes, so the topic stays, and its owner and schema are *tbd* — the obligation of whoever later asks for it (Eve E-20) |
| Workspace audit logs in Cloud Logging | what the robot account actually did, **written by Google, not by Wall-E** | read | read | Organisation level. Eve reads its own organisation-level sink into `EVE_PROJECT`; Mo reads Wall-E's copy `walle_workspace_logs` in `WALLE_PROJECT` through dataset-level `dataViewer`. *Widened 2026-09-13 (platform HLD §13.2):* Eve's sink covers all six Workspace streams with no actor exclusion, plus a Reports API poll by actor |
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
   halting when uncertain. *Narrowed 2026-09-13 (platform HLD §13.2; C12 in
   [14](14-hld-challenge.md); Eve E-7).* The halt is taken on **declared thresholds** with a
   reason code, by Eve's control path, which contains no model; the bias toward halting when
   uncertain stays. "Its own judgement" survives only on Eve's **reporting path**
   (`eve-advisor` in `EVE_ADVISOR_PROJECT`, register row P34). That path may reason about
   "anything wrong" and write `eve.incidents` narratives and `eve.advice`. It may page a human
   at severity 2, within the page budget, citing the deterministic findings that triggered it.
   It holds no signer, no invoker and no secret, and nothing it writes is read by `eve-gate`,
   `eve-reconciler`, `walle-actions` or `walle-actions-super`. A human who agrees halts or
   demotes through the existing human path.
6. **Attestation.** For a promotion, produce a dated, signed evidence bundle. It attests;
   it never promotes.
7. **Fail closed in every direction.** Eve down means L4 items wait and L5 cells demote to
   L4. Eve must never be a thing whose absence lets more happen.
8. **Report misbehaviour to a human, independently** (added 2026-09-13, platform HLD §13.2).
   Reconcile every robot-attributed event in every ingested stream, not only catalogued
   plans. Run the detection catalogue in the reconciler limb, including prompt-to-action
   divergence on the human's prompt. Run a daily super-admin roster check from Eve's own
   credential, and emit an evidence heartbeat. Push a daily export to the witness
   organisation. Page under the reporting contract: severity 1 from the witness to the second
   human outside the Wall-E line and to the desk. Reports about the administrator's own
   actions go to the second human alone.

Eve's own progression mirrors Wall-E's: it runs in observe mode through Stage 3, graded
against human verdicts, and only becomes load-bearing at Stage 4 once it has passed a
seeded-fault exercise. *Qualified 2026-09-13:* that is the gate layer. Item 8's
observe-and-report layer is live and drilled **before** Super Admin is granted
([05](05-autonomy-ladder.md) §7, "The super-admin grant — a gate, not a stage").

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
6. Never hold a credential, never call the action service, never write to config. *Corrected
   2026-09-13 (Mo change 9, [../mo/08-open-decisions.md](../mo/08-open-decisions.md)):* the
   action-service rule reads "the two read endpoints only, as `mo-analyst@MO_PROJECT`", as the
   Identities table already says; no credential and no write to config stand.
7. **Improve Eve too** (added 2026-09-13, platform HLD §13.3). Measure Eve's detection
   quality and time-to-report. The Eve quality pack is: false-refusal Wilson bounds,
   wrong-accept count, agreement, pages against budget, time-to-verdict, time-to-acknowledge,
   and availability from Wall-E's stamp. Numbers about Eve come from `grades_eve`,
   `seeded_fault_runs`, golden replays and Wall-E's `eve_last_seen`, never from `eve.verdicts`
   alone, and an assertion query checks that.
8. Explain Eve regressions keyed on `eve_config_version`, and report a divergence between Mo's
   number and Eve's own as an Eve finding.
9. Propose Eve changes only from the closed set `eve_threshold_tighten`,
   `eve_threshold_loosen`, `seeded_fault_addition` and `eve_incident_note`, against
   `eve/config` paths `thresholds.yaml` and `seeded_faults` only. Never propose against
   `predicates/`, `ceilings.py`, `reasons.yaml`, `oncall.yaml` or `eve_authority`. The
   validator refuses an Eve loosening within 30 days of a Wall-E promotion on the same cell,
   in either order. Until the validator custodian reads `eve_quality` (P30), Eve-targeting
   bundles are advisory `incident_note` only.
10. Publish the misbehaviour taxonomy and its detector coverage map as the first Eve
    artefact and the Eve-improvement backlog. Never grade Eve, and never reach Eve's control
    path except through a merged pull request.

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
