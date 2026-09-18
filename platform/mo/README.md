# Mo — continuous improvement

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-18
- Reviewed on 2026-09-18: the Documents row for 07, the "Building it" reading order and the
  Maturity rows no longer present Mo's runbook as the maker; 07 has been a pointer since
  2026-09-16 and the build is setup/ 02, 22, 29, 36 and 40, with Eve's grants made in 29 and
  36 and Wall-E's in 36.
- Objective restated 2026-09-13: Mo improves **both Wall-E and Eve**, one Mo per platform keyed
  on `agent_id` ([platform HLD](../agentic-platform/01-hld.md) §13.3; owners and gates in
  [§18](../agentic-platform/01-hld.md#18-what-this-hld-requires-of-the-wall-e-eve-and-mo-sets), P143).
- Maturity: **design — nothing built.** No project, no dataset, no scheduled query, no job,
  no bucket, no service account. Not one grant in this set exists in the runbook today.
- Placement: Mo lives in its own GCP project, `MO_PROJECT`, which does not exist yet; where each
  resource lives and every grant that crosses a project are in
  [`../project-topology.md` §2](../project-topology.md#2-the-four-projects) and
  [§3](../project-topology.md#3-cross-project-grants).
- Codename: `mo`. Resource prefix `mo-`. Wall-E, Eve and Mo are designed; nothing of the three
  is built. Mo is one of the three agents designed in
  [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md); Wall-E's set is
  [`../wall-e/README.md`](../wall-e/README.md), Eve's is [`../eve/README.md`](../eve/README.md).

## What Mo is

Mo is about twelve BigQuery scheduled queries, a Cloud Run job that renders markdown, a Cloud
Storage bucket and — optionally, from S4 — one small model that writes sentences beside numbers
it did not compute, all in `MO_PROJECT`, reaching Wall-E's and Eve's data only through
resource-level grants. Every number Mo publishes is re-derivable from the measured agent's
audit dataset — and, for numbers about Eve, from `eve_quality` under the source rule
([03-metrics-contract.md §7.3](03-metrics-contract.md#73-the-eve-quality-pack)) — and the
external validator re-derives it rather than believing it. Mo holds no credential, reaches
production only through a drop box that CI turns into a human-merged pull request, and its
absence is strictly more restrictive than its presence: the full thesis is
[01-hld.md § Thesis](01-hld.md#thesis).

### The three tiers, and the seam between them

The code/model boundary is an IAM boundary: T0 (`mo-metrics@`) runs committed SQL over the raw
audit rows with no model and no egress, T1 (`mo-reporter`, as `mo-analyst@`) renders artefacts
from computed aggregates only, and the optional T2 (`mo-narrator@`) writes prose from
authorised views that carry no free-text column. Each tier is strictly weaker than the one
before it. The tiers, their identities and what each can reach are in
[01-hld.md](01-hld.md#the-three-tiers-and-the-seam-between-them).

### One Mo per platform, improving Wall-E and Eve

There is one `MO_PROJECT` for the whole platform, keyed on `agent_id`: Mo measures Eve as well
as Wall-E, and Eve can lower while Mo can only propose. The rules are in
[01-hld.md § Thesis](01-hld.md#thesis); the metric pack each tier gets is in
[03-metrics-contract.md §7.1](03-metrics-contract.md#71-the-metric-pack-per-tier).

## What Mo is deliberately not

Mo is not callable, holds nothing, decides nothing, is not its own grader and never grows in
authority: nothing it emits is an approval, a level, a halt, a sample or a gate input, and the
validator's recomputation — not Mo's verdict — is what gates. The negatives and their reasons
are in [01-hld.md § What Mo is not](01-hld.md#what-mo-is-not) and
[§ The deterministic boundary](01-hld.md#the-deterministic-boundary-and-how-it-is-enforced);
why that never changes with age is
[05-staging.md § Trust does not grow with age](05-staging.md#trust-does-not-grow-with-age).
Nothing at S0 or S1 depends on Mo's verdicts, and the first promotion that may cite Mo is at
S3, after its acceptance test ([05-staging.md § The stage table](05-staging.md#the-stage-table)).

## The artefacts

Each is markdown, regenerated as a pull request and never pushed; contents, path, schedule and
audience are in [04-artefacts-and-proposals.md §1](04-artefacts-and-proposals.md#1-the-five-artefacts).

- Wall-E's five: the [promotion-readiness scorecard](04-artefacts-and-proposals.md#11-the-scorecard-page),
  the [ladder state](04-artefacts-and-proposals.md#12-ladder-statemd), the
  [weekly digest](04-artefacts-and-proposals.md#13-the-weekly-digest), the
  [regression explanation](04-artefacts-and-proposals.md#14-the-regression-explanation) and the
  [monthly cost report](04-artefacts-and-proposals.md#15-the-monthly-cost-report).
- For Eve: the [misbehaviour taxonomy and detector coverage map](04-artefacts-and-proposals.md#16-the-misbehaviour-taxonomy-and-coverage-map--the-first-eve-artefact)
  and the [Eve scorecard](04-artefacts-and-proposals.md#17-the-eve-scorecard).
- For compliance: the [Art. 72 post-market monitoring plan](04-artefacts-and-proposals.md#18-the-art-72-post-market-monitoring-plan-per-high-risk-system),
  one per high-risk system.

## Documents

| # | Document | What it answers |
|---|---|---|
| 1 | [What Mo is](01-hld.md) | The thesis and the one-Mo-per-platform rules, the three tiers and the IAM seam, the components, the recompute property and why it licenses a model, the drop box, and what was deliberately cut |
| 2 | [Identities and access](02-identity-and-access.md) | The three service accounts with their exact grants, the authorised-view column allowlist, surrogate keys, the containment assertion that no enforcement identity reads `walle_metrics`, and `MO_PRINCIPAL` |
| 3 | [The metrics contract](03-metrics-contract.md) | The gates, the Wilson and Newcombe arithmetic, the golden fixtures whose expected values are the constants [C18](../wall-e/14-hld-challenge.md) published, the assertion queries, the ten §8 metrics with audit completeness as the headline, the metric pack per tier and the Eve quality pack with its source rule, dwell and the ratchet, grading, attribution, freshness |
| 4 | [The artefacts, and how a proposal becomes a merge](04-artefacts-and-proposals.md) | Each artefact in full (Wall-E's five, the Eve coverage map and scorecard, the Art. 72 plan), the grading chapter and its weekly human cost, the proposal bundle contract, the closed proposal type sets for Wall-E and for Eve, the path allowlists, CI ingestion and the validator |
| 5 | [What exists at each stage](05-staging.md) | S0 to S5 and the pre-Phase-1 baseline, what Mo is trusted with at each, the six-criterion acceptance test, and the cost and effort tables |
| 6 | [Failure modes](06-failure-modes.md) | Mo down, Mo wrong, Mo compromised, the narrator hallucinating, the blocked upstream tables, and the residuals stated unsoftened |
| 7 | [Building Mo](07-build-runbook.md) | Pointer since 2026-09-16; the build is [setup/](../agentic-platform/setup/README.md) [02](../agentic-platform/setup/02-toil-baseline.md) (the toil baseline, day one), [22](../agentic-platform/setup/22-mo-foundations.md) (foundations), [29](../agentic-platform/setup/29-mo-eve-quality-pack.md) (the Eve quality pack), [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) (the Wall-E pack) and [40](../agentic-platform/setup/40-mo-after-stage-0.md) (after Stage 0); the page keeps the map from each retired phase to its new steps |
| 8 | [Open decisions, and what Mo forces on Wall-E](08-open-decisions.md) | The eleven open decisions with their gates, the twenty changes this design forces on the other sets (change 20 is Eve-side), and the reopen-when table |

## Reading order

Start with [01-hld.md](01-hld.md), then [03-metrics-contract.md](03-metrics-contract.md) —
the shape and the arithmetic are the whole argument, and the arithmetic is where the
disagreements will be.

- **Deciding whether to build this at all:** 01, [05-staging.md](05-staging.md), then the
  cost and effort tables at the end of 05. The human line — blind grading, indefinitely, from
  a named human who is not the playbook owner; at least two hours a week at S4 volume for
  Wall-E ([03-metrics-contract.md](03-metrics-contract.md) §13.3), against the platform's
  per-tier figure in [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §11.1 — is
  the number that decides it, and at platform scale it caps the number of Tier W agents (P25).
- **Reviewing it for security:** 01, [02-identity-and-access.md](02-identity-and-access.md),
  [06-failure-modes.md](06-failure-modes.md), then
  [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md). The deterministic boundary
  in 01 and the residual list in 06 are the honest parts; read them before the runbook.
- **Building it:** [08-open-decisions.md](08-open-decisions.md) first — three of its changes
  block Mo entirely and belong to Wall-E's schedule, not Mo's — then 05, 03 and the setup
  files that replaced [07-build-runbook.md](07-build-runbook.md) on 2026-09-16:
  [setup/02](../agentic-platform/setup/02-toil-baseline.md) (the toil baseline, day one),
  [22](../agentic-platform/setup/22-mo-foundations.md) (foundations),
  [29](../agentic-platform/setup/29-mo-eve-quality-pack.md) (the Eve quality pack, with Eve's
  side of its grants), [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) (the
  Wall-E pack, with the Wall-E and remaining Eve grants) and
  [40](../agentic-platform/setup/40-mo-after-stage-0.md) (after Stage 0).

## Maturity

A digest; what exists at each stage, and when each component arrives, is
[05-staging.md § The stage table](05-staging.md#the-stage-table).

| Item | State |
|---|---|
| `config/metrics/toil_baseline.csv` | Not started — and the only part of Mo that must exist **before Wall-E does**, because decision 38's denominator cannot be reconstructed afterwards |
| Datasets, scheduled queries, `gates.yaml`, fixtures, the three service accounts | Designed, not built; created in `MO_PROJECT` by [setup/22](../agentic-platform/setup/22-mo-foundations.md) (project, datasets, `mo-metrics@`), [29](../agentic-platform/setup/29-mo-eve-quality-pack.md) (the Eve pack), [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) (the Wall-E pack, `mo-analyst@`) and [40](../agentic-platform/setup/40-mo-after-stage-0.md) (reporter, narrator, ingest, validator); Mo's own runbook was retired to a pointer on 2026-09-16 |
| Cross-project grants | Not made: Eve's grants are made in [setup/29](../agentic-platform/setup/29-mo-eve-quality-pack.md) and [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md), Wall-E's in [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) ([02-identity-and-access.md §2](02-identity-and-access.md#2-the-grant-list-account-by-account)); `mo-analyst@` holds no invoker on `walle-actions` (SD-24); `MO_PRINCIPAL` resolves to `mo-analyst@${MO_PROJECT}` and its registry grant is dropped ([02-identity-and-access.md](02-identity-and-access.md) §6) |
| `walle_audit.grades`, `proposal_verdicts`, `drills`, `ladder_events` | **Blocking upstream dependencies**: without them no cell can be reported ready ([08-open-decisions.md](08-open-decisions.md#what-this-design-forces-on-wall-es-set) changes 1–2) |
| Drop box, CI ingestion, bot author, validator recompute check | S2 exit, and a **precondition** for the first promotion that cites Mo |

Cost, if built: `Assumption:` 24–37 person-days in Mo's own budget and €25–60 a month of
machine cost on `MO_PROJECT`'s billing line at pilot scale, plus at least two hours a week of
blind grading — see [05-staging.md § Cost and effort](05-staging.md#cost-and-effort).

Mo's set has not been attacked yet the way Wall-E's has
([`../wall-e/10-adversarial-review.md`](../wall-e/10-adversarial-review.md),
[`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md)); the challenge items this
design answers, and the ones it reopens, are named in
[08-open-decisions.md](08-open-decisions.md). Its decisions keep the set-local index
`M-1`…`M-11`; how that relates to Wall-E's and the platform's numbering is
[08-open-decisions.md § Numbering](08-open-decisions.md#numbering-and-where-an-answer-is-recorded).
