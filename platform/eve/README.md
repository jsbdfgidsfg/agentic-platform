# Eve — the controller

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Maturity: **design — nothing built, nothing enabled.** Not one Eve resource exists today,
  in either Workspace or GCP.
- Codename: `eve`. Resource prefix `eve-`. It is the second of the three agents designed in
  [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md); Wall-E's set is
  [`../wall-e/README.md`](../wall-e/README.md).
- 2026-09-13: objective restated for a super-admin Wall-E (P33) — see the platform HLD
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.2; owners and gates are
  P143 in [../agentic-platform/12-open-decisions.md](../agentic-platform/12-open-decisions.md)).

## What Eve is

Eve is a body of SQL, two deterministic Cloud Run jobs, a console and a key in its own GCP
project, whose only privileged act is a Cloud KMS signature over a hash it computed itself; it
treats everything Wall-E's action service says as a claim and recomputes five things from
sources Wall-E cannot write. Its control path contains no model and exposes no inbound surface,
so "Eve is down" is an absence; it gets halting and demoting at S3 entry and signing only at S4
entry, while a report-only reporting path, `eve-advisor`, may reason, and a witness
organisation outside the tenant holds its evidence and alarms
([01-hld.md §1](01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness)).
Eve gates nothing in the pilot and L3 with human approval is a legitimate permanent end state,
but the observe-and-report layer is built and drilled before Wall-E's super-admin grant — the
full argument is [01-hld.md Thesis](01-hld.md#thesis) and
[§3](01-hld.md#3-deterministic-by-absence-not-by-discipline).

## What Eve is deliberately not

Eve is not an agent (no inbound surface of any kind), not a model on its authority path, and
not a component of Wall-E (its own project, outside Wall-E's teardown blast radius). Its
signature is necessary but never sufficient, it is never its own grader, and it is never a
Workspace writer or a super admin. Each negative and its reason is in
[01-hld.md "What Eve is not"](01-hld.md#what-eve-is-not).

## The three constraints Eve exists to serve

Every design choice in this set traces to the three separation rules of
[`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md#the-separation-that-makes-a-team-worth-having)
— no agent both decides and acts, no agent grades its own work (Eve is graded by the blind
human sample), and only humans loosen anything (Eve can lower, halt, refuse and veto, but never
raise a level, clear an override or change a ceiling).

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
  [06-failure-modes.md](06-failure-modes.md), then [03-lld.md](03-lld.md). The five named
  limits and the declared limits of watching a super admin in 06 are the honest parts; read
  them before the flows.
- **Building it:** 05, [08-contract-changes.md](08-contract-changes.md) — because Wall-E's
  side must be scheduled with Wall-E, not with Eve — then 03,
  [04-flows.md](04-flows.md) and [07-build-runbook.md](07-build-runbook.md).

## Maturity

Nothing is built. When each part comes into existence is
[05-stages.md "The stage table"](05-stages.md#the-stage-table); in digest:

| Item | Stage |
|---|---|
| Eve v0 — the scheduled query set | S0; the whole of Eve through S2 |
| Observe-and-report layer, with `eve@<domain>` and its credential, `eve-export@` and the witness organisation | Before Wall-E's super-admin grant, whatever the ladder stage |
| Halting and demoting (`eve-reconciler`, `eve-console`) | S3 entry |
| Signing (`eve-approval`, `eve-gate`) | S4 entry, only for cells marked `eve_authority: binding` |
| `eve-advisor`, the reporting path | Decided in principle (P34, *proposed*); AI Act class open (P19) |

If it is built, Eve costs 8–10 engineer-weeks including Wall-E's roughly five days, under €50 a
month on GCP plus one Workspace licence, and under half an hour a week of human time, with the
observe-and-report layer, `eve-advisor` and the witness not yet priced
([01-hld.md "Cost"](01-hld.md#cost)).

Nothing in this set has been attacked yet the way Wall-E's set has
([`../wall-e/10-adversarial-review.md`](../wall-e/10-adversarial-review.md),
[`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md)). The existence of this
design record is itself the trigger to re-run nine of those challenge items against it;
[09-open-decisions.md](09-open-decisions.md) names which, and which this design changes.
