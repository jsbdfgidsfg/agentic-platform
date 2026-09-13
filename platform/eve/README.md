# Eve — the controller

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Maturity: **design — nothing built, nothing enabled.** Not one Eve resource exists today,
  in either Workspace or GCP.
- Codename: `eve`. Resource prefix `eve-`. It is the second of the three agents designed in
  [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md); Wall-E's set is
  [`../wall-e/README.md`](../wall-e/README.md).
- **Objective restated 2026-09-13; see the platform HLD**
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.2, and §18 items 11–18
  for the edits this set carries; owners and gates are platform decision P143 in
  [../agentic-platform/12-open-decisions.md](../agentic-platform/12-open-decisions.md)). This set
  was written against a narrowly privileged Wall-E. Since 2026-09-13 Wall-E holds **Super
  Admin** (P33), so Eve has two paths (a model-free control path in `EVE_PROJECT` and a
  report-only reporting path, `eve-advisor`, in `EVE_ADVISOR_PROJECT`), watches every ingested
  Workspace stream rather than catalogued plans only, reports through a witness organisation
  outside the tenant's reach, and its observe-and-report layer is live and drilled **before**
  the super-admin grant. Every line below that says otherwise carries a dated note.

## What Eve is

Eve is a body of SQL, two deterministic Cloud Run jobs, a console and a key, living in its
own GCP project, whose only privileged act is a Cloud KMS `EC_SIGN_P256_SHA256` signature
over a hash it computed itself. It treats everything Wall-E's action service says as a
**claim**, and recomputes five things from sources Wall-E cannot write: the plan hash, the
per-item pre-state, the effective level, the trigger's corroboration, and the typed
`expects` predicate — which Eve implements a second time from the same spec, because
otherwise the verification-success metric that unlocks L4 and L5 would be measuring itself.
It acquires its two authorities on opposite schedules, because they point in opposite
directions: halting and demoting can only ever make less happen, so Eve gets them the moment
it is a program at all, at S3 entry; signing can make more happen, so Eve gets the key only
at S4 entry, after a twelve-fault exercise it must pass at 100 %. It exposes no inbound
decision endpoint, speaks no agent protocol and contains no model client, so "Eve is down" is
an **absence** — and absence is handled by two deterministic sweepers inside `walle-actions`
that can lower on Eve's silence and have no code path that raises on Eve's return. Everything
Eve decides **on its authority path** — approve, refuse, veto, halt, demote, sign — is code:
the verdict is a pure function of six typed inputs, and no language model can produce an Eve
approval or signature, because the process cannot reach a model and its identity could not
authenticate to one.

**Qualified 2026-09-13 (platform HLD §13.2, P34).** The sentence above holds for the
**control path** (`eve-gate`, `eve-reconciler`, `eve-console` in `EVE_PROJECT`), and is a
compliance invariant: a model-free control path is outside the AI Act's Art. 3(1) definition
and serves as an Art. 14 oversight measure
([../agentic-platform/10-eu-ai-act.md](../agentic-platform/10-eu-ai-act.md) §3.2). The
objective asks Eve to report "anything wrong", which a closed vocabulary cannot enumerate, so
Eve also has a **reporting path**, `eve-advisor` in `EVE_ADVISOR_PROJECT`, which may reason and
is **report-only by construction**: it writes incident narratives and `eve.advice` and pages at
severity 2 inside a budget, and nothing it writes is read by `eve-gate`, `eve-reconciler` or
either Wall-E action service. Its AI Act class is open (P19). And Eve now watches a
**super-admin** robot: all six Cloud Logging Workspace streams plus a Reports API poll by
actor, a detection catalogue, a daily super-admin roster check and an evidence heartbeat, with
its evidence, incident record and pager mirrored to a witness organisation the tenant's super
admins do not administer. Inside the tenant's own organisation Eve's independence is
**detective, not structural**; what leaves the organisation is structural.

**Eve gates nothing in the pilot.** Through S2 the whole of Eve's *gate layer* is ten
BigQuery scheduled queries a human reads weekly; signing does not exist before S4 entry. And
**L3 with human approval is a legitimate permanent end state** — none of the signing half
should be built until an L3→L4 promotion can state in numbers how much approval burden it
actually avoids.

**Qualified 2026-09-13 (platform HLD §0.4, §13.2).** The stop rule applies to the gate layer
only. The **observe-and-report layer** — the six-stream sink, the Reports API poll, the
tenant-integrity rules, `eve.incidents` and paging, the witness mirror — is a precondition of
Wall-E's super-admin grant and is built and drilled before it, whatever the ladder stage
([05-stages.md](05-stages.md)).

## What Eve is deliberately not

| Not | Because |
|---|---|
| **Not an agent.** No HTTP decision endpoint, no Pub/Sub push subscription, no A2A surface, no agent card, no agent protocol of any kind. Eve is a client everywhere. | It removes an attack class, it makes "Eve is down" an absence rather than a silence nobody notices, and it makes it structurally impossible for a safety interlock to run through a conversation. |
| **Not a model on the authority path.** No model client in the control-path image, no `aiplatform.*` permission on either runtime identity, `reasoningEngines.query` removed per [C10](../wall-e/14-hld-challenge.md), and — since 2026-09-13 — a project-level `restrictServiceUsage` denylist on `aiplatform.googleapis.com` for `EVE_PROJECT` (platform HLD CP5). Narrowed 2026-09-13: the report-only `eve-advisor` in `EVE_ADVISOR_PROJECT` may reason (P34); it holds no signer, no invoker, no secret and nothing it writes reaches a verdict. | The boundary is enforced by dependency absence and permission absence, not by policy. A signature cannot be produced by a model the process cannot reach. |
| **Not a component of Wall-E.** Its project (`EVE_PROJECT`, one of the four under `FOLDER_ID` in [../project-topology.md](../project-topology.md)), dataset, secrets, key, evidence bucket and config repository are all outside Wall-E's project (`WALLE_PROJECT`) and outside its teardown blast radius. No Wall-E deployer holds a project-level role in Eve's project or on the folder; the only Wall-E principals in it are the three resource-level carve-outs of topology decision 48. | While Eve's key sits in Wall-E's project, a project owner can grant themselves `cloudkms.signer` and mint an Eve approval, and the only control is a detective one. [E-1](09-open-decisions.md), answered yes on 2026-09-13. **Qualified 2026-09-13:** the boundary is structural against Wall-E's project principals and deployers, and only **detective** against Wall-E's super-admin credential, which can reach Organization Administrator; the structural part is the witness organisation (platform HLD §13.2, [01-hld.md](01-hld.md) structural choice 1). |
| **Not sufficient.** An Eve signature is necessary, never sufficient: `walle-actions` re-runs its full policy chain, per item, after verifying the signature offline against a pinned PEM. | It bounds the compromised-Eve case to the blast radius of cells already marked `eve_authority: binding`. |
| **Not its own grader.** Eve's verdicts never feed the precision metric; a blind human sample, drawn from S1 and rendered without Eve's verdict columns, is the only input to precision at L4 and L5. Added 2026-09-13: Eve's own verdicts are graded in a separate `grades_eve` written by the platform approval surface, never by `eve-console`, and Mo — which improves Eve — is never Eve's grader (platform HLD §13.3). | Otherwise the controller both decides and grades, and the metric that unlocks autonomy measures itself. |
| **Not a Workspace writer, at any stage, ever, and never a super admin.** The custom role `Eve — Verifier` carries read privileges only; there is no domain-wide delegation anywhere. Its read privilege and scope set are widened before the one-sitting consent to watch a super admin (E-16), still with **no content scope**. | Wall-E's action services are the only holders of a Workspace write credential. The objective requires Eve to control without super admin. |

## The three constraints Eve exists to serve

Straight from [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md), and every design
choice in this set traces to one of them:

1. **No agent both decides and acts.** Wall-E acts and never approves; Eve approves and never
   acts on Workspace; Mo proposes and does neither.
2. **No agent grades its own work.** Wall-E's re-read after write is a sanity check, not
   evidence. Eve verifies independently, with its own read-only credential and against its
   own organisation-level copy of Google's admin audit log — and Eve in turn is graded by the
   blind human sample, not by itself.
3. **Only humans loosen anything.** Eve can lower a level, halt, refuse and veto, instantly
   and alone. It can never raise one, clear an override or change a ceiling. The raise path is
   a pull request, CI validation and a dated decision record with a named human — two of them
   above L3.

## The contract, and what this design changes in it

[`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md) is **the contract**: the
responsibilities split, the identities, the shared data plane and the eight endpoints
`walle-actions` exposes. This set builds against it rather than renegotiating it.

It does not survive contact unamended. Every edit Eve forces back on Wall-E's set — the
`items_hash` in the signed field list, the per-cell `eve_authority` field, the ownership of
the "Eve down" timer, the BigQuery grant that exists nowhere in the runbook, item 5's
"its own judgement" — is listed in one place, [08-contract-changes.md](08-contract-changes.md),
file by file with its reason and its gate. Read that before building either side.

## Documents

| # | Document | What it answers |
|---|---|---|
| 1 | [High-level design](01-hld.md) | What Eve is and is not, the two paths, the witness, the component table, the five structural choices, the deterministic boundary and its mechanical enforcements, what the design does not close, and the cost |
| 2 | [Identities, credentials and the key](02-identity-and-auth.md) | Every principal, what it holds, the project-boundary argument, the Workspace robot's hardening, the frozen scope list, the two secrets, and the signing key with its manual rotation and PEM archive |
| 3 | [The verifier](03-lld.md) | How a verdict is produced byte by byte: the five recomputations, the envelope contract, the closed reason vocabulary, `thresholds.yaml`, the evidence perimeter, the detection catalogue, the reporting contract, the data plane, the dataset schemas and the replay bundle |
| 4 | [Flows](04-flows.md) | The seven things Eve does end to end — pre-approval, post-hoc verification, reconciliation, drift, halt and demote, attestation, the blind sample — each with its trigger, reason codes and failure branch |
| 5 | [**Stages and gates**](05-stages.md) | What exists at S0 to S5, what Eve is trusted with at each, what is deliberately absent, and the S3 exit gate of twelve seeded faults and two negative controls |
| 6 | [Failure modes and the limits of independence](06-failure-modes.md) | What happens when each part of this is wrong, missing or hostile; the compromised-Eve bound and its residual; the five named limits on Eve's independence; the page budget |
| 7 | [Eve onboarding](07-build-runbook.md) | The ordered, runnable steps to bring each stage into existence, with verification per step and what to do when one half-fails |
| 8 | [**What this design changes in Wall-E's set**](08-contract-changes.md) | Every edit Eve forces back on Wall-E: file, edit, reason, gate |
| 9 | [Open decisions](09-open-decisions.md) | The twenty decisions this design does not settle, each with its gate, plus the Wall-E decisions it depends on and the challenge items it re-opens |

## Reading order

Start with [01-hld.md](01-hld.md), then [05-stages.md](05-stages.md) — together they are the
whole argument, and the staging is where the disagreements will be.

- **Deciding whether to build this at all:** 01, 05, then the cost section of 01 and
  [09-open-decisions.md](09-open-decisions.md).
- **Reviewing it for security:** 01, [02-identity-and-auth.md](02-identity-and-auth.md),
  [06-failure-modes.md](06-failure-modes.md), then [03-lld.md](03-lld.md). Section
  "What this design does not close" in 01 and the five named limits in 06 are the honest
  parts; read them before the flows.
- **Building it:** 05, [08-contract-changes.md](08-contract-changes.md) — because Wall-E's
  side must be scheduled with Wall-E, not with Eve — then 03,
  [04-flows.md](04-flows.md) and [07-build-runbook.md](07-build-runbook.md).

## Maturity

| Item | State |
|---|---|
| Eve v0 — the scheduled query set | Designed, not built. Twelve transfer configs: the ten [../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §8 metrics plus reconciliation and drift. It is the whole of Eve through S2. |
| Eve's GCP project, dataset, mirror | Designed, not created. [E-1](09-open-decisions.md) answered yes 2026-09-13 (four projects — `GEMINI_PROJECT`, `WALLE_PROJECT`, `EVE_PROJECT`, `MO_PROJECT` — under `FOLDER_ID`, [../project-topology.md](../project-topology.md); decision file *tbd*); [E-2](09-open-decisions.md) is open: the boundary is right, the ownership group behind it does not exist yet with one administrator. |
| `eve@<domain>`, its role, key, client and token | Not created, and deliberately not created at Stage 0 — a refresh token unused for six months expires, and consent freezes the scope list. Was: S3 entry, in one sitting. **Moved 2026-09-13:** in one sitting with the observe-and-report layer, **before the super-admin grant** (platform HLD §13.2), with the widened read set fixed first (E-16). |
| Observe-and-report layer (six-stream sink, Reports API poll by actor, detection catalogue, roster check, evidence heartbeat, `eve.incidents`, paging, witness mirror) | Designed 2026-09-13 in the platform HLD §13.2; not built. A precondition of the super-admin grant ([05-stages.md](05-stages.md)). |
| `eve-advisor` (reporting path, `EVE_ADVISOR_PROJECT`) | Decided in principle 2026-09-13 (P34, *proposed*); not built; AI Act class open (P19). |
| Witness organisation `org-witness` / `EVE_WITNESS_PROJECT` | Designed 2026-09-13; not created. Domain, edition and billing are P14 (IT security). A gate item of the super-admin grant. |
| Halting and demoting | S3 entry, live immediately for the invariant class. Rate-based triggers stay observe-only until their thresholds are calibrated on S2 data. |
| Signing | S4 entry at the earliest, and only for cells whose ladder entry explicitly sets `eve_authority: binding`. Absent reads as advisory. |
| Wall-E's side of this design | Roughly five days inside `walle-actions`, scheduled with Wall-E rather than with Eve. Not started. See [08-contract-changes.md](08-contract-changes.md). |
| Cost, if it is built | 8–10 engineer-weeks across two stage transitions six to eight weeks apart; under €50 a month on GCP plus one Workspace licence; under half an hour a week of human time in steady state. **Added 2026-09-13:** the objective adds the observe-and-report layer, `eve-advisor`, the witness organisation (one more tenant, two more hardware keys) and a second human outside the Wall-E line as Eve owner; amounts *tbd* (platform HLD §0.5). |

Nothing in this set has been attacked yet the way Wall-E's set has
([`../wall-e/10-adversarial-review.md`](../wall-e/10-adversarial-review.md),
[`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md)). The existence of this
design record is itself the trigger to re-run nine of those challenge items against it;
[09-open-decisions.md](09-open-decisions.md) names which, and which this design changes.
