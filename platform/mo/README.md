# Mo — continuous improvement

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-12
- Maturity: **design — nothing built.** No dataset, no scheduled query, no job, no bucket,
  no service account. Not one grant in this set exists in the runbook today.
- Codename: `mo`. Resource prefix `mo-`. It is one of the three agents designed in
  [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md); Wall-E's set is
  [`../wall-e/README.md`](../wall-e/README.md), Eve's is [`../eve/README.md`](../eve/README.md).

## What Mo is

Mo is about twelve BigQuery scheduled queries, a Cloud Run job that renders markdown, a
Cloud Storage bucket, and — optionally, from S4 — one small model that writes sentences
beside numbers it did not compute. It is built backwards from five artefacts and nothing
else, and its organising property is one sentence:

> **Every number Mo publishes is re-derivable from `walle_audit`, and the gate re-derives it
> rather than believing it.**

A promotion pull request carries a re-executable evidence block — the metric, the value, the
exact SQL at a pinned commit, the window, the fingerprint, the sample size, the sample seed —
and the external validator, owned outside the config repository and unreachable by Mo, runs
that SQL itself against `walle_audit` and refuses the merge if one value differs. It re-draws
the blind grading sample from a seed published after the week closed. That single decision is
what licenses a model in Mo at all: a compromised or hallucinating Mo can write a persuasive
paragraph and cannot produce a false number that survives CI.

Mo holds **no credential and no secret of any kind**. It does not push, merge or approve: it
drops a proposal bundle in a bucket, and CI turns that bundle into a pull request under a bot
identity that is not Mo. So the one component in the team that could forge a plausible
promotion does not exist.

And Mo's absence is strictly more restrictive than its presence. A `walle_metrics` watermark
older than 24 hours makes the validator refuse every promotion, while every §8 breach that
demotes or halts is enforced by the action service's breakers, by Eve and by CI — none of
which read anything Mo writes. Mo down means nothing rises. It does not mean anything
loosens.

### The three tiers, and the seam between them

The code/model boundary is an **IAM boundary**, not a coding convention. Each tier is
strictly weaker than the one before it, and the model tier cannot select a free-text string
because the views it reads do not carry one.

| Tier | Runs as | Reads | Does | Exists from |
|---|---|---|---|---|
| **T0 — the metric queries** (`config/metrics/*.sql`) | `mo-metrics@` | `walle_audit`, `walle_workspace_logs` — raw | Computes every number and every selection, including the `ready` / `not_ready` / `insufficient_data` verdict, as a SQL `CASE`. No model, no network egress, nothing to prompt | **S0** |
| **T1 — `mo-reporter`** | `mo-analyst@` | `walle_metrics` only — never `walle_audit` | Renders the five artefacts, recomputes `plan_hash` on a weekly sample against two read endpoints, writes proposal bundles to the drop box | **S1** (cost report), full set **S2** |
| **T2 — `mo-narrator`** (optional) | `mo-narrator@` | the agent-facing authorised views — ids, hashes, closed enums, counts, timestamps, surrogate keys | Writes prose beside numbers it did not compute. Computes nothing, selects nothing, ranks nothing, grades nothing. Its output never enters the evidence block | **S4**, and it is legitimate never to build it |

## What Mo is deliberately not

| Not | Because |
|---|---|
| **Not callable.** No REST API, no Pub/Sub event, no A2A endpoint, no agent card, no MCP server. Neither Wall-E nor Eve can reach it through any channel. | There is no path by which anything asks Mo for a decision, so there is nothing to prompt, steer or impersonate. |
| **Not a holder of anything.** No git credential, no Workspace credential, no Secret Manager grant, no key, no Firestore role, no Pub/Sub subscription. | The drop box removes the credential from Mo entirely at the cost of one bucket, and that is the sharpest edge the alternative designs carried. |
| **Not a decider.** Nothing Mo emits is an approval, a signature, a level, a halt, a sample or a gate input. It can neither raise nor lower a level. | This is the negative form of decision 34, and it is what licenses a model in Mo at all. The moment an artefact of Mo's became load-bearing without recomputation, that licence would be void. |
| **Not its own grader, and not the gate.** Mo's verdict is informational; the validator's recomputation is what gates. Precision at L4 and L5 comes from a blind human sample Mo cannot choose. | Per [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) §10 the gate cannot be part of what it gates — enforced twice here, at drop-box ingestion and in CI. |
| **Not an agent in the pilot.** Through S1 the whole of Mo is scheduled SQL, a dataset and a markdown renderer. | Nothing about Mo is on the critical path to S0 or S1, and building the reasoning engine the other design proposed buys an identity property that a Cloud Run job does not need. |
| **Not growing in authority.** There is no version of Mo whose output is not a proposal, at S5 or ever. | The one agent that may use a model freely is the one whose ceiling never rises. |

**Mo does not exist in the pilot, and nothing at Stage 0 depends on its verdicts.** What S0
buys is that the definitions are fixed and version-controlled before the first item is
graded. At S0 every cell reports `insufficient_data` — the write budget is zero and no sample
approaches the floor of 35 — and **no S0 or S1 exit criterion cites Mo's verdict**. A human
reads the numbers and signs the S1 decision record; nothing automatic consumes them. The
first promotion that may cite Mo is at S3, and only after Mo passes its acceptance test.

## The five artefacts

Everything else in this set exists to make these five true. Each is markdown, regenerated as
a pull request, never pushed. Contents, schedule and audience are in
[04-artefacts-and-proposals.md](04-artefacts-and-proposals.md).

| Artefact | Path | Schedule | Audience |
|---|---|---|---|
| The ladder state | `platform/wall-e/ladder-state.md` | *tbd* — regenerated as a pull request, never pushed; read at the weekly review | The ladder owner, the weekly review |
| The promotion-readiness scorecard | `platform/wall-e/mo/scorecard.md`, from `walle_metrics.scorecard` and its daily snapshot `walle_metrics_archive.scorecard_YYYYMMDD` | The view is per `as_of_hour`; the snapshot is daily; the page is regenerated on the weekly reporter run | The ladder owner |
| The weekly digest | `platform/wall-e/mo/digest-YYYY-Www.md` | Monday 08:00 Europe/Paris | `walle-operators@` |
| The regression explanation | `platform/wall-e/mo/regression-<cell>-<date>.md` | On a detected change point | The ladder owner |
| The cost report | `platform/wall-e/mo/cost-YYYY-MM.md` | Monthly | Decision 38's stop-or-continue review |

`Assumption:` those are paths in the config repository and in Wall-E's own wiki set; this
design set lives at `platform/mo/`, alongside Eve's.

## Documents

| # | Document | What it answers |
|---|---|---|
| 1 | [What Mo is](01-hld.md) | The five artefacts built backwards, the three tiers and the IAM seam, the recompute property and why it licenses a model, the drop box, and what was deliberately cut |
| 2 | [Identities and access](02-identity-and-access.md) | The three service accounts with their exact grants, the authorised-view column allowlist, surrogate keys, the containment assertion that no enforcement identity reads `walle_metrics`, and `MO_PRINCIPAL` |
| 3 | [The metrics contract](03-metrics-contract.md) | The gates, the Wilson and Newcombe arithmetic, the golden fixtures whose expected values are the constants [C18](../wall-e/14-hld-challenge.md) published, the assertion queries, the ten §8 metrics, dwell and the ratchet, grading, attribution, freshness |
| 4 | [The five artefacts, and how a proposal becomes a merge](04-artefacts-and-proposals.md) | Each artefact in full, the grading chapter and its weekly human cost, the proposal bundle contract, the closed proposal type set, the path allowlist, CI ingestion and the validator |
| 5 | [What exists at each stage](05-staging.md) | S0 to S5 and the pre-Phase-1 baseline, what Mo is trusted with at each, the six-criterion acceptance test, and the cost and effort tables |
| 6 | [Failure modes](06-failure-modes.md) | Mo down, Mo wrong, Mo compromised, the narrator hallucinating, the blocked upstream tables, and the residuals stated unsoftened |
| 7 | [Building Mo](07-build-runbook.md) | The two new SETUP phases in the runbook's own shape, with verify blocks, rollback and the denial tests authored from Mo's side |
| 8 | [Open decisions, and what Mo forces on Wall-E](08-open-decisions.md) | The ten open decisions with their gates, the seventeen changes this design forces on Wall-E's set, and the reopen-when table |

## Reading order

Start with [01-hld.md](01-hld.md), then [03-metrics-contract.md](03-metrics-contract.md) —
the shape and the arithmetic are the whole argument, and the arithmetic is where the
disagreements will be.

- **Deciding whether to build this at all:** 01, [05-staging.md](05-staging.md), then the
  cost and effort tables at the end of 05. The human line — roughly an hour a week of blind
  grading, indefinitely, from a named human who is not the playbook owner — is the number
  that decides it.
- **Reviewing it for security:** 01, [02-identity-and-access.md](02-identity-and-access.md),
  [06-failure-modes.md](06-failure-modes.md), then
  [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md). The deterministic boundary
  in 01 and the residual list in 06 are the honest parts; read them before the runbook.
- **Building it:** [08-open-decisions.md](08-open-decisions.md) first — three of its changes
  block Mo entirely and belong to Wall-E's schedule, not Mo's — then 05, 03 and
  [07-build-runbook.md](07-build-runbook.md).

## Maturity

| Item | State |
|---|---|
| `config/metrics/toil_baseline.csv` | Not started, and it is the only part of Mo that must exist **before Wall-E does**: four weeks of measured baseline toil for the top three admin tasks, plus monthly human operating hours. Decision 38's denominator cannot be reconstructed afterwards. |
| `walle_metrics`, `walle_metrics_archive`, the ~12 scheduled queries, `gates.yaml`, the golden fixtures | Designed, not built. This is S0, and it is the whole of Mo through S1. |
| Mo's three service accounts and their BigQuery grants | Not created. **No BigQuery read grant for Mo exists in the runbook today** — `add_dataset_access` is called exactly twice, for neither of these. Every grant is a build task. |
| `MO_PRINCIPAL` | Resolves to `serviceAccount:mo-analyst@${PROJECT}.iam.gserviceaccount.com`. No edit to `walle_setup.py` is required; [`../wall-e/PREREQUISITES.md`](../wall-e/PREREQUISITES.md) items 11 and 13 are settled by this resolution. |
| `walle_audit.grades`, `proposal_verdicts`, `drills`, and the new `ladder_events` table | **Blocking upstream dependencies.** Without them plan precision, drill freshness, dwell and the ratchet are not computable at all, and no cell can be reported ready. See [08-open-decisions.md](08-open-decisions.md) and [`../wall-e/03-lld.md`](../wall-e/03-lld.md). |
| The drop box, CI ingestion, the bot author, the validator's recompute check | S2 exit, and a **precondition** for the first promotion that cites Mo — not an improvement to add later. Roughly three of its days belong to the validator custodian rather than to Mo. |
| `mo-narrator` and the model-family comparison | S4 or never; that is an open decision with its gate at S4 entry. |
| Cost, if it is built | `Assumption:` 24–37 person-days in Mo's own budget, none on the critical path to S0 or S1. `Assumption:` €25–60 a month of machine cost at pilot scale, `tbd` until the first billing cycle. Plus the human hour a week, which Mo does not create and cannot do without. |

Mo's set has not been attacked yet the way Wall-E's has
([`../wall-e/10-adversarial-review.md`](../wall-e/10-adversarial-review.md),
[`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md)); the challenge items this
design answers, and the ones it reopens, are named in
[08-open-decisions.md](08-open-decisions.md). Its decision numbers are **provisional** —
[`../wall-e/09-open-decisions.md`](../wall-e/09-open-decisions.md) ends at 41 today and Eve's
set may claim the next numbers, so the final numbering is assigned when both sets land.
