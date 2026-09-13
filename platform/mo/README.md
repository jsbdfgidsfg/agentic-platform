# Mo — continuous improvement

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Objective restated 2026-09-13; see the platform HLD
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.3 and §18 items 19–24).
  This set predates that objective: it was designed as Wall-E's improver. Since 2026-09-13 Mo
  improves **both Wall-E and Eve**, and there is **one Mo per platform**, keyed on `agent_id`
  (below). Owner of the propagation: the Mo owner; gate: Wall-E's Stage 1 (platform decision
  P143).
- Maturity: **design — nothing built.** No project, no dataset, no scheduled query, no job,
  no bucket, no service account. Not one grant in this set exists in the runbook today.
- Placement: Mo lives in **its own GCP project, `MO_PROJECT`**, under `FOLDER_ID` beside
  `WALLE_PROJECT`, `EVE_PROJECT` and `GEMINI_PROJECT` (decided 2026-09-13, for least
  privilege). `MO_PROJECT` does not exist yet. [`../project-topology.md`](../project-topology.md)
  is the single authority for where each resource lives and for every grant that crosses a
  project; this set points there rather than restating it.
- Codename: `mo`. Resource prefix `mo-`. Wall-E, Eve and Mo are designed; nothing of the three
  is built. Mo is one of the three agents designed in
  [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md); Wall-E's set is
  [`../wall-e/README.md`](../wall-e/README.md), Eve's is [`../eve/README.md`](../eve/README.md).

## What Mo is

Mo is about twelve BigQuery scheduled queries, a Cloud Run job that renders markdown, a
Cloud Storage bucket, and — optionally, from S4 — one small model that writes sentences
beside numbers it did not compute. All of it sits in `MO_PROJECT`. What Mo needs from
Wall-E's project arrives as resource-level grants and nothing else: T0's two raw reads are
cross-project, dataset-level `roles/bigquery.dataViewer` on `walle_audit` and
`walle_workspace_logs` in `WALLE_PROJECT`, with the jobs running (and billed) in
`MO_PROJECT`. **Added 2026-09-13:** what Mo needs from Eve's project arrives the same way — one
dataset-level `READER` for `mo-metrics@${MO_PROJECT}` on Eve's quality dataset `eve_quality` in
`EVE_PROJECT`, made by **Eve's** runbook, never by Mo's, with no binding of any kind in
`MO_PROJECT` in return (platform HLD §13.3). It is built backwards from its artefacts — five
for Wall-E, and since 2026-09-13 the Eve and compliance artefacts below — and its organising
property is one sentence:

> **Every number Mo publishes is re-derivable from the measured agent's audit dataset —
> `walle_audit` for Wall-E — and, for numbers about Eve, from `eve_quality` and the sources the
> source rule names; and the gate re-derives it rather than believing it.**

Qualified 2026-09-13 (platform HLD §13.3): the sentence read "re-derivable from `walle_audit`"
while Mo measured Wall-E only. Numbers **about Eve** never come from `eve.verdicts` alone: they
come from `grades_eve`, `seeded_fault_runs`, golden-replay results and Wall-E's passive
`eve_last_seen`, and that source rule is an assertion query
([03-metrics-contract.md](03-metrics-contract.md) §7.3). The validator re-derives them only
once the custodian holds `READER` on `eve_quality` (platform decision P30); until then every
Eve-targeting bundle is an advisory `eve_incident_note` only, stated in its heading.

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
loosens. The same holds for Eve since Mo improves it: **Eve reads nothing Mo writes**, Mo is
never Eve's grader, and a change to Eve's `thresholds.yaml` reaches Eve only as a Mo bundle
that a human merges ([04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §3.6).

### The three tiers, and the seam between them

The code/model boundary is an **IAM boundary**, not a coding convention. Each tier is
strictly weaker than the one before it, and the model tier cannot select a free-text string
because the views it reads do not carry one.

| Tier | Runs as | Reads | Does | Exists from |
|---|---|---|---|---|
| **T0 — the metric queries** (`config/metrics/*.sql`) | `mo-metrics@${MO_PROJECT}` | `walle_audit`, `walle_workspace_logs` — raw, in `WALLE_PROJECT`, read cross-project under a dataset-level `READER`; **since 2026-09-13** also `eve_quality` in `EVE_PROJECT` — Eve's Mo-readable surfaces through authorised views with no free-text column, never `grades_blind` or `review_queue_blind` — under a dataset-level `READER` made by Eve's runbook | Computes every number and every selection, including the `ready` / `not_ready` / `insufficient_data` verdict, as a SQL `CASE`. No model, no network egress, nothing to prompt | **S0** |
| **T1 — `mo-reporter`** | `mo-analyst@${MO_PROJECT}` | `walle_metrics` only — never `walle_audit` | Renders the five artefacts, recomputes `plan_hash` on a weekly sample against two read endpoints on `walle-actions` in `WALLE_PROJECT` (a cross-project `roles/run.invoker` on that service), writes proposal bundles to the drop box | **S1** (cost report), full set **S2** |
| **T2 — `mo-narrator`** (optional) | `mo-narrator@${MO_PROJECT}` | the agent-facing authorised views in `walle_metrics_views` — ids, hashes, closed enums, counts, timestamps, surrogate keys | Writes prose beside numbers it did not compute. Computes nothing, selects nothing, ranks nothing, grades nothing. Its output never enters the evidence block | **S4**, and it is legitimate never to build it |

### One Mo per platform, improving Wall-E and Eve

Added 2026-09-13 (platform HLD §13.3, §11.1; [../agentic-platform/05-registry-and-autonomy-contract.md](../agentic-platform/05-registry-and-autonomy-contract.md) §9.8).

| Rule | What it means here |
|---|---|
| Remit includes Eve | Mo measures Eve's detection quality and time-to-report, explains Eve regressions keyed on `eve_config_version`, proposes threshold and seeded-fault changes for a human to merge, and publishes the misbehaviour taxonomy and coverage map as the Eve-improvement backlog. **Eve can lower; Mo can only propose** |
| One Mo per platform | One `MO_PROJECT` for the whole platform, keyed on `agent_id` over the platform audit schema — not one Mo per agent. Every table, cell and artefact carries `agent_id` |
| Metric pack per tier | Tier C/R: cost, reliability, Model Armor `MATCH_FOUND` rate, drift, freshness — no grading hour. Tier W: the full pack with blind grading. Tier P: the full pack plus the Eve quality pack. Tier X: plus evaluation gates. Wall-E's ten metrics are the first pack; Eve's quality pack is the second ([03-metrics-contract.md](03-metrics-contract.md) §7.1) |
| Agent-neutral names before Stage 0 | The drop box is `mo-proposals` (was `walle-mo-proposals`); the metric datasets take agent-neutral names before Stage 0 ([04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §3.7). This set still spells the Wall-E pack's datasets `walle_metrics*` until that rename lands |
| Independence | Mo holds no credential, no invoker on Eve, no signer; Eve reads nothing Mo writes; Mo reaches production only through a pull request a human merges |

## What Mo is deliberately not

| Not | Because |
|---|---|
| **Not callable.** No REST API, no Pub/Sub event, no A2A endpoint, no agent card, no MCP server. Neither Wall-E nor Eve can reach it through any channel. Reading Eve's quality dataset (since 2026-09-13) gives Eve no channel into Mo. | There is no path by which anything asks Mo for a decision, so there is nothing to prompt, steer or impersonate. |
| **Not a holder of anything.** No git credential, no Workspace credential, no Secret Manager grant, no key, no Firestore role, no Pub/Sub subscription. | The drop box removes the credential from Mo entirely at the cost of one bucket, and that is the sharpest edge the alternative designs carried. |
| **Not a decider.** Nothing Mo emits is an approval, a signature, a level, a halt, a sample or a gate input. It can neither raise nor lower a level, and it neither sets nor loosens an Eve threshold — it proposes the diff. | This is the negative form of decision 34, and it is what licenses a model in Mo at all. The moment an artefact of Mo's became load-bearing without recomputation, that licence would be void. |
| **Not its own grader, and not the gate.** Mo's verdict is informational; the validator's recomputation is what gates. Precision at L4 and L5 comes from a blind human sample Mo cannot choose. | Per [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) §10 the gate cannot be part of what it gates — enforced twice here, at drop-box ingestion and in CI. |
| **Not an agent in the pilot.** Through S1 the whole of Mo is scheduled SQL, a dataset and a markdown renderer. | Nothing about Mo is on the critical path to S0 or S1, and building the reasoning engine the other design proposed buys an identity property that a Cloud Run job does not need. |
| **Not growing in authority.** There is no version of Mo whose output is not a proposal, at S5 or ever. | The one agent that may use a model freely is the one whose ceiling never rises. |

**Mo does not exist in the pilot, and nothing at Stage 0 depends on its verdicts.** What S0
buys is that the definitions are fixed and version-controlled before the first item is
graded. At S0 every cell reports `insufficient_data` — the write budget is zero and no sample
approaches the floor of 35 — and **no S0 or S1 exit criterion cites Mo's verdict**. A human
reads the numbers and signs the S1 decision record; nothing automatic consumes them. The
first promotion that may cite Mo is at S3, and only after Mo passes its acceptance test.

## The five artefacts, and the ones added on 2026-09-13

Everything else in this set exists to make these true. Each is markdown, regenerated as
a pull request, never pushed. Contents, schedule and audience are in
[04-artefacts-and-proposals.md](04-artefacts-and-proposals.md). The first five are Wall-E's
pack; the last three were added on 2026-09-13 (platform HLD §13.3) and are specified in
[04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §1.6–§1.8.

| Artefact | Path | Schedule | Audience |
|---|---|---|---|
| The ladder state | `platform/wall-e/ladder-state.md` | *tbd* — regenerated as a pull request, never pushed; read at the weekly review | The ladder owner, the weekly review |
| The promotion-readiness scorecard | `platform/wall-e/mo/scorecard.md`, from `walle_metrics.scorecard` and its daily snapshot `walle_metrics_archive.scorecard_YYYYMMDD` | The view is per `as_of_hour`; the snapshot is daily; the page is regenerated on the weekly reporter run | The ladder owner |
| The weekly digest | `platform/wall-e/mo/digest-YYYY-Www.md` | Monday 08:00 Europe/Paris | `walle-operators@` |
| The regression explanation | `platform/wall-e/mo/regression-<cell>-<date>.md` | On a detected change point | The ladder owner |
| The cost report | `platform/wall-e/mo/cost-YYYY-MM.md` | Monthly | Decision 38's stop-or-continue review |
| The misbehaviour taxonomy and detector coverage map — **the first Eve artefact** | `platform/eve/mo/coverage-map.md` (`Assumption:` path) | *tbd*; first edition before Wall-E's Stage 1 (P143), regenerated on every `eve_config_version` change | The Eve owner; the security reviewer |
| The Eve scorecard (the Eve quality pack) | `platform/eve/mo/scorecard.md` (`Assumption:` path) | Weekly reporter run | The Eve owner |
| The Art. 72 post-market monitoring plan, one per high-risk system | `platform/<agent>/mo/art72-plan.md` (`Assumption:` path) | On every stage decision and when the Commission's template is adopted | The AI compliance owner ([../agentic-platform/10-eu-ai-act.md](../agentic-platform/10-eu-ai-act.md) §4.4) |

`Assumption:` those are paths in the config repository and in Wall-E's own wiki set; this
design set lives at `platform/mo/`, alongside Eve's.

## Documents

| # | Document | What it answers |
|---|---|---|
| 1 | [What Mo is](01-hld.md) | The five artefacts built backwards, the three tiers and the IAM seam, the recompute property and why it licenses a model, the drop box, and what was deliberately cut |
| 2 | [Identities and access](02-identity-and-access.md) | The three service accounts with their exact grants, the authorised-view column allowlist, surrogate keys, the containment assertion that no enforcement identity reads `walle_metrics`, and `MO_PRINCIPAL` |
| 3 | [The metrics contract](03-metrics-contract.md) | The gates, the Wilson and Newcombe arithmetic, the golden fixtures whose expected values are the constants [C18](../wall-e/14-hld-challenge.md) published, the assertion queries, the ten §8 metrics with audit completeness as the headline, the metric pack per tier and the Eve quality pack with its source rule, dwell and the ratchet, grading, attribution, freshness |
| 4 | [The artefacts, and how a proposal becomes a merge](04-artefacts-and-proposals.md) | Each artefact in full (Wall-E's five, the Eve coverage map and scorecard, the Art. 72 plan), the grading chapter and its weekly human cost, the proposal bundle contract, the closed proposal type sets for Wall-E and for Eve, the path allowlists, CI ingestion and the validator |
| 5 | [What exists at each stage](05-staging.md) | S0 to S5 and the pre-Phase-1 baseline, what Mo is trusted with at each, the six-criterion acceptance test, and the cost and effort tables |
| 6 | [Failure modes](06-failure-modes.md) | Mo down, Mo wrong, Mo compromised, the narrator hallucinating, the blocked upstream tables, and the residuals stated unsoftened |
| 7 | [Building Mo](07-build-runbook.md) | Mo's phases against `MO_PROJECT` — the project itself first — in the runbook's own shape, with verify blocks, rollback and the denial tests authored from Mo's side; and the short cross-project steps Wall-E's runbook makes on Mo's behalf |
| 8 | [Open decisions, and what Mo forces on Wall-E](08-open-decisions.md) | The eleven open decisions with their gates, the twenty changes this design forces on the other sets (change 20, added 2026-09-13, is Eve-side), and the reopen-when table |

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
  block Mo entirely and belong to Wall-E's schedule, not Mo's — then 05, 03 and
  [07-build-runbook.md](07-build-runbook.md).

## Maturity

| Item | State |
|---|---|
| `config/metrics/toil_baseline.csv` | Not started, and it is the only part of Mo that must exist **before Wall-E does**: four weeks of measured baseline toil for the top three admin tasks, plus monthly human operating hours. Decision 38's denominator cannot be reconstructed afterwards. |
| `walle_metrics`, `walle_metrics_archive`, `walle_metrics_private`, `walle_metrics_views`, the ~12 scheduled queries, `gates.yaml`, the golden fixtures | Designed, not built. This is S0, and it is the whole of Mo through S1. |
| Mo's three service accounts and their in-project grants | Not created. They are created **in `MO_PROJECT` by Mo's own runbook** ([07-build-runbook.md](07-build-runbook.md)), never by Wall-E's. Every grant is a build task. |
| The cross-project grants on Wall-E's resources | Not made. Exactly three: dataset-level `READER` on `walle_audit` and on `walle_workspace_logs` for `mo-metrics@${MO_PROJECT}`, and `roles/run.invoker` on the `walle-actions` service for `mo-analyst@${MO_PROJECT}`. All three are made **from Wall-E's runbook**, in `WALLE_PROJECT`, which gains `MO_PROJECT` as a config key for them. **No BigQuery read grant for Mo exists in the runbook today** — `add_dataset_access` is called exactly twice, for neither of these. Rows 6 and 8 of [`../project-topology.md`](../project-topology.md) §3. |
| The cross-project grant on Eve's resources (added 2026-09-13) | Not made. Exactly one Mo grant: dataset-level `READER` on `eve_quality` in `EVE_PROJECT` for `mo-metrics@${MO_PROJECT}`, made **from Eve's runbook**, never Mo's, with no binding in `MO_PROJECT` (platform HLD §18 items 17, 20 and 25). A second `READER` on the same dataset belongs to the validator custodian, not to Mo, and is what lets the gate re-derive Mo's Eve numbers (P30). Change 20 in [08-open-decisions.md](08-open-decisions.md). |
| `MO_PRINCIPAL` | Resolves to `serviceAccount:mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com`. `walle_setup.py` and `walle.env.example` gain `MO_PROJECT` regardless; and the only use of `MO_PRINCIPAL` today — Phase 13b's `roles/agentregistry.viewer` at **project** level on Wall-E's project — is a project-level role in another project, which the topology forbids. That grant is dropped from Phase 13b unless a resource-level binding is verified (not verified as of 2026-09-13): see [02-identity-and-access.md](02-identity-and-access.md) §6 and [M-11 · 52](08-open-decisions.md). [`../wall-e/PREREQUISITES.md`](../wall-e/PREREQUISITES.md) items 11 and 13 are settled by the resolution. |
| `walle_audit.grades`, `proposal_verdicts`, `drills`, and the new `ladder_events` table | **Blocking upstream dependencies.** Without them plan precision, drill freshness, dwell and the ratchet are not computable at all, and no cell can be reported ready. See [08-open-decisions.md](08-open-decisions.md) and [`../wall-e/03-lld.md`](../wall-e/03-lld.md). |
| The drop box, CI ingestion, the bot author, the validator's recompute check | S2 exit, and a **precondition** for the first promotion that cites Mo — not an improvement to add later. Roughly three of its days belong to the validator custodian rather than to Mo. |
| `mo-narrator` and the model-family comparison | S4 or never; that is an open decision with its gate at S4 entry. |
| Cost, if it is built | `Assumption:` 24–37 person-days in Mo's own budget, none on the critical path to S0 or S1. `Assumption:` €25–60 a month of machine cost at pilot scale, `tbd` until the first billing cycle — and it is **`MO_PROJECT`'s billing line**: BigQuery bills the querying project for the job, so the scans of `walle_audit` — and of `eve_quality`, since 2026-09-13 — are Mo's cost, not Wall-E's or Eve's ("the querying project is billed for the query job while the project storing the data is billed for the amount of data stored", [Run a query](https://docs.cloud.google.com/bigquery/docs/running-queries), verified 2026-09-13). Mo's machine cost is now separable per project in the billing export. Plus the human hour a week, which Mo does not create and cannot do without. |

Mo's set has not been attacked yet the way Wall-E's has
([`../wall-e/10-adversarial-review.md`](../wall-e/10-adversarial-review.md),
[`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md)); the challenge items this
design answers, and the ones it reopens, are named in
[08-open-decisions.md](08-open-decisions.md). Its decision numbers are **provisional** —
[`../wall-e/09-open-decisions.md`](../wall-e/09-open-decisions.md) ends at 41, and 42–52 are
already claimed by [`../project-topology.md`](../project-topology.md) §8, so Mo's rows keep
their set-local `M-1`…`M-11` index. Qualified 2026-09-13: platform decisions continue as
P1.. in [../agentic-platform/12-open-decisions.md](../agentic-platform/12-open-decisions.md),
which cross-references M-1..M-11 in its §8.
