# 5. What exists at each stage

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Objective restated 2026-09-13; see the platform HLD
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.3, §18 item 23). The S5
  privilege-pruning text is rewritten for a super-admin robot — privilege pruning is a roster
  check, not a role diff — and the Eve reads and artefacts are placed in the tables below.

## What this page is for

Mo does not have stages of its own. It has pieces, and each piece arrives inside one of
Wall-E's six stages, from [../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md)
§7. This page says which piece arrives when, what it is trusted with once it is there, and
what it is still not trusted with. Wall-E's floors are S0 3–4 weeks, S1 4–6, S2 6–8, S3 6–8,
S4 8–12, S5 ongoing; they are floors, not schedules, and Mo's arrival dates move with them.

Two properties run through the whole table and are the reason it is ordered the way it is.

**Mo's measurement layer arrives before Mo's judgement layer, and long before anything reads
its judgement.** The definitions — the metric SQL, the gate parameters, the golden fixtures —
are fixed and version-controlled at S0, which is months before the first item is graded.
That is C18's own instruction: a threshold argued about after the numbers are in is not a
threshold. It also means that no S0 or S1 exit criterion cites Mo's verdict, and every cell
reports `insufficient_data` for that whole period, which is the correct answer and not a
defect.

**Mo's trust does not grow with age.** There is no stage at which Mo's output stops being a
proposal. S5 trusts Mo with exactly what S4 trusts it with. The one agent in the team that
may use a language model freely is the one whose ceiling never rises, and those two facts are
the same decision: see [§ Trust does not grow with age](#trust-does-not-grow-with-age).

## The stage table

| Stage | What exists | What it is trusted with |
|---|---|---|
| **Before Phase 1** | `config/metrics/toil_baseline.csv` and four weeks of measured baseline toil for the top three admin tasks. Nothing else of Mo | Nothing. It is a measurement humans take, and it exists before Wall-E does because [decision 38](../wall-e/09-open-decisions.md)'s denominator cannot be reconstructed afterwards |
| **S0 — Eyes** | The project `MO_PROJECT`, created under `FOLDER_ID` with billing linked and APIs enabled; in it, the four datasets `walle_metrics`, `walle_metrics_archive`, `walle_metrics_private` (the surrogate mapping alone, no reader) and `walle_metrics_views` (views only); `mo-metrics@${MO_PROJECT}` with grants that do not exist in any runbook today, split in two — the in-project ones (`jobUser`, `WRITER` on the four datasets) from Mo's runbook, and two cross-project dataset-level `READER`s on `walle_audit` and `walle_workspace_logs` in `WALLE_PROJECT` from Wall-E's runbook, keyed on `MO_PROJECT`; ~12 scheduled queries committed as `config/metrics/*.sql` under `ladder.yaml`'s reviewers; `gates.yaml`; the golden fixtures and assertion queries; the daily snapshot. **This is "Eve v0", and it is Mo's T0 — there is no later handover because there is no later replacement** (qualified 2026-09-13: Eve's own v0 survives beside it as a differential check, see "S0" below). No reporter job, no drop box, no model, no Pub/Sub, no Firestore, no action-service access. `MO_PRINCIPAL` resolves to `mo-analyst@${MO_PROJECT}`; Phase 13b's project-level `roles/agentregistry.viewer` on `WALLE_PROJECT` is dropped or made resource-level ([02-identity-and-access.md](02-identity-and-access.md) §6) | Producing the numbers the S0 exit criteria are read from. A human reads them and signs the S1 decision record; nothing automatic consumes them. Every cell reports `insufficient_data` — the write budget is 0 and no sample approaches 35 — and **no S0 or S1 exit criterion cites Mo's verdict**. What S0 buys is that the definitions are fixed and version-controlled before the first item is graded, which is C18's own instruction |
| **S1 — Hands held** | Adds, all in `MO_PROJECT`: `mo-analyst@`, the authorised-view layer, the `mo-reporter` job on a weekly schedule, the freshness absence alert with its channel, the cost report and the S1 stop-or-continue document — plus the one cross-project `roles/run.invoker` on `walle-actions` in `WALLE_PROJECT`, made from Wall-E's runbook | One decision, and it is a **value** decision rather than a safety one: the dated stop-or-continue review at S1 exit, measured toil saved against operating cost including human hours. Nothing about a level |
| **S2 — Proposals** | Adds the scorecard view and page, `ladder-state.md` regeneration, the regression explanation, the grading worklist, the capability-gap ranking, and the weekly plan-hash recomputation. **At S2 exit:** the drop box, CI ingestion, the bot author, and the validator's recompute check. Graded samples first approach 35 on the highest-volume cells. The **back-test** runs here | Telling the ladder owner which cells are close and why, and telling graders what to grade. Verdicts are informational: no promotion cites Mo yet. Proposals are restricted by the template set to **non-ladder** changes — catalogue additions, playbook selection queries, prompt changes, cap changes. A second grader must exist by now, because a `WRITE_HIGH` cell cannot pass L2 without 20 % blind double-grading — **earlier than [decision 11b](../wall-e/09-open-decisions.md) assumes**, a scheduling conflict Mo surfaces rather than resolves |
| **Wall-E's observe-and-report layer and grant gate** (added 2026-09-13) | Eve's observe-and-report layer arrives before the super-admin grant (platform HLD §13.2), and with it `eve_quality`. From then: Mo's `READER` on `eve_quality` (Eve's runbook), the Eve quality pack in T0, assertions A10 and A11, the Eve scorecard, and the misbehaviour taxonomy and coverage map — first edition before Wall-E's Stage 1 (P143). `Assumption:` this lands between Mo's S1 and S2 on the calendar; it is gated on Eve's layer, not on a Mo stage | Reporting only. Every Eve figure is advisory and every Eve bundle is `eve_incident_note` until the validator custodian holds `READER` on `eve_quality` (P30). Nothing Mo computes about Eve is read by Eve |
| **S3 — Batch approval** | The full pipeline, with Mo's **acceptance test** in progress. The blind sampler runs in preparation for L4, **with the CI-published weekly seed and its append-only per-week seed file in force from entry**. The Spans dataset link is created in `WALLE_PROJECT` by a human holding `roles/observability.editor` there, and `mo-metrics@${MO_PROJECT}` gets a cross-project dataset-level `READER` on it (a spike, topology decision 49). Eve is in observe mode and Mo excludes Eve's verdicts from precision entirely | The S3 entry decision is the first that may carry a recomputed evidence block, and the first promotion pull request assembled from a bundle. Mo's verdict is still not the gate — the validator's recomputation is. Authoring promotion pull requests **up to L3**; `WRITE_HIGH` cells stay hard-blocked above L2 until a second grader is named |
| **S4 — Eve gates** | Blind-sample hardening: verdict suppression in the worklist, agreement reporting. The weekly seed is already in force from S3. `agg_eve_latency` becomes computable. Precision for any L4/L5 cell switches to the blind sample **only**. The E35 review path goes live. Optionally `mo-narrator` and the model-family comparison | Being the only route by which L4/L5 precision exists at all. L4 promotion evidence, with two distinct authenticated approving reviewers and a validator recomputation. `WRITE_HIGH` never reaches L5 on any trigger at any stage, and Mo has no template that emits a ceiling change |
| **S5 — Steady state** | Quarterly rhythm: proposals reviewed, budgets, caps and OU scope re-decided (the OU allow-list is enforced by the action service's code since the robot holds Super Admin), the demand ranking read for catalogue additions, and the **pruning query** — catalogue operations with zero invocations in 90 days, and the super-admin roster check's findings — feeding the quarterly removal of catalogue operations and the review of who holds admin privilege. Rewritten 2026-09-13: there is no custom role to prune; privilege pruning is a **roster check**, not a role diff | The same as S4. **Mo never accumulates authority with age**; there is no version of Mo whose output is not a proposal. That is deliberate: the one agent that may use a model freely is the one whose ceiling never rises |

## When each component arrives

The same information keyed by component rather than by stage, so a builder can read down one
column. Identities and grants are in [02-identity-and-access.md](02-identity-and-access.md);
the components themselves in [01-hld.md](01-hld.md); the commands in
[07-build-runbook.md](07-build-runbook.md).

| Component | Exists from |
|---|---|
| The toil baseline, `config/metrics/toil_baseline.csv` | **Before Phase 1** — the only part of Mo that must exist before Wall-E does |
| The project `MO_PROJECT` under `FOLDER_ID`, billing linked, APIs enabled, its number recorded | S0, before Mo-1 ([07-build-runbook.md](07-build-runbook.md) Mo-1 step 0) |
| The cross-project grants in `WALLE_PROJECT` — two dataset `READER`s on `walle_audit` and `walle_workspace_logs`, one `run.invoker` on `walle-actions` | S0 (the readers) and S1 (the invoker), from **Wall-E's runbook**, keyed on `MO_PROJECT` |
| `walle_metrics`, `walle_metrics_archive`, `walle_metrics_private`, `walle_metrics_views`, in `MO_PROJECT` | S0 |
| T0 — the metric queries, `config/metrics/*.sql` | S0 |
| `gates.yaml`, the golden fixtures, the assertion queries, the daily snapshot | S0 |
| `mo-metrics@` and its BigQuery grants | S0 |
| The authorised-view layer | S1, when anything other than T0 reads the data |
| `mo-analyst@` | S1 |
| T1 — `mo-reporter` | S1 for the cost report and the S1 stop-or-continue document; the full artefact set at S2 |
| The freshness absence alert | S1 |
| The blind grading surface (a dependency, not part of Mo) | S2 for shadow and proposal grades; the blind sample from S3 |
| The CI-published weekly seed and the append-only per-week seed file | **S3**, with the sampler — never later than the first blind draw |
| The proposal drop box | S2 exit |
| The validator's recompute check | S2 exit. The §10 ladder gates themselves exist from S0, for Wall-E's own promotions |
| Mo's `READER` on `eve_quality` in `EVE_PROJECT`, made by Eve's runbook (added 2026-09-13) | With Eve's observe-and-report layer, before the super-admin grant; the Eve quality pack, A10, A11 and the Eve scorecard with it |
| The misbehaviour taxonomy and coverage map (added 2026-09-13) | First edition before Wall-E's Stage 1 (P143) |
| The validator custodian's `READER` on `eve_quality` (added 2026-09-13) | P30 — recommended now; until then Eve bundles are advisory |
| The Art. 72 post-market monitoring plan for Wall-E (added 2026-09-13) | S2, with the artefact set it names ([04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §1.8) |
| The linked Spans dataset (`_AllSpans`), in `WALLE_PROJECT` | S3, created once by a human holding `roles/observability.editor` in `WALLE_PROJECT` — never by Mo — with a cross-project dataset `READER` for `mo-metrics@${MO_PROJECT}` (spike, decision 49) |
| T2 — `mo-narrator` | S4, and it is legitimate never to build it ([decision 49](08-open-decisions.md)) |

## Stage by stage, and why each boundary is where it is

### Before Phase 1 — the baseline nobody can reconstruct later

Four weeks of measured toil for the top three admin tasks, plus monthly human operating
hours, committed as `config/metrics/toil_baseline.csv` and loaded into `walle_metrics` by a
scheduled query. It is never estimated by Mo, never inferred from audit rows, and never
edited outside a pull request.

It has to be measured before Phase 1 for one reason: it is a *before* measurement, and once
Wall-E starts running there is no before to measure. [Decision 38](../wall-e/09-open-decisions.md)
requires a value denominator and a dated stop-or-continue review; without this file the
review has a numerator and no denominator, and the programme continues by momentum, which is
exactly what C28 said it would do.

### S0 — the definitions, fixed before the first grade

S0 is Mo's whole arithmetic layer and none of Mo's reporting layer. `mo-metrics@` runs ~12
committed queries; there is no job, no bucket, no model, no action-service access and no
network egress anywhere in it.

[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §8 says the metrics are
BigQuery scheduled queries until Eve exists, "call that Eve v0 and do not skip it". In this
design **T0 is that step and stays that step**. There is no later handover to a different
component, because there is no later replacement: the queries that compute the ten §8 metrics
at S0 are the same queries that compute them at S5, under the same pinned service account.
What changes with the stages is what reads them, never who computes them.

**Unresolved, and it must be settled before either set is built.** Eve's set claims the same
step: [`../eve/05-stages.md`](../eve/05-stages.md) and
[`../eve/01-hld.md`](../eve/01-hld.md) build "Eve v0" at S0 as scheduled queries in
`EVE_PROJECT`, pinned to `eve-v0@`, writing `eve.findings`, computing the same ten §8 metrics.
Both candidates now live in their own projects. Two sets cannot both own one step. Either
there is one query set in `MO_PROJECT` pinned to `mo-metrics@`, or a second in `EVE_PROJECT`
pinned to `eve-v0@` — and either way one more cross-project dataset-level `READER` on
`walle_audit` per pinned account, made from Wall-E's runbook — and if there are two, the
cost, the duplicated arithmetic and the risk of two divergent answers to the same §8
threshold have to be argued for. Nothing in either design settles it, and neither page should be read as having
settled it. It belongs in the next stage decision record, not in a reconciliation of prose.

**Decided at platform level on 2026-09-13** (platform HLD §13.3, "Eve v0 and Mo T0"): both
survive, as a differential check. Two independently pinned computations of the same ten
metrics from the same `walle_audit` are the second implementation this design declined to
build for cost; assertion A11 diffs Mo's scorecard against `eve.findings`, read through
`eve_quality`, and sets `metric_divergence` on the Eve scorecard
([03-metrics-contract.md](03-metrics-contract.md) §6, §7.3). The paragraph above is kept as the
record of the conflict; the dated decision file is still owed, and M-11 (d) and change 20 in
[08-open-decisions.md](08-open-decisions.md) carry the grant it needs.

Nothing at S0 or S1 is gated on a Mo verdict, and that is stated as an exit-criterion
property rather than left to be inferred. At S0 the daily write budget is 0, shadow items
evaluate the cap without consuming it, and no cell approaches the graded floor of 35, so
every cell reports `insufficient_data`. The S0 exit criteria in
[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §7 are read by a human
from Mo's numbers and signed by a human; Mo's `verdict` column is not one of them.

What S0 actually buys is the ordering: the metric definitions, the Wilson bounds, the sample
floor of 35 and the `gates.yaml` parameters — all of them set out in
[03-metrics-contract.md](03-metrics-contract.md) — are in git, under `ladder.yaml`'s
reviewers, before the first item is graded. A threshold chosen after the data arrives is not a
threshold. That is C18's instruction and [decision 33](../wall-e/09-open-decisions.md)'s.

One reporting duty starts at S0 and matters months later: `no_second_grader` is reported from
S0, so the block described in [§ The second-grader conflict](#the-second-grader-conflict-at-s2)
is visible for months before it bites.

### S1 — the first decision Mo's numbers carry, and it is about money

S1 adds the reporting identity, the authorised views, the weekly `mo-reporter` job and the
absence alert, and produces two documents: the monthly cost report and the S1 stop-or-continue
document.

The one decision Mo's output carries at S1 is a **value** decision, not a safety one: measured
toil saved at S1, plus the projected S3 saving, against operating cost **including human
hours**. If that is negative, [decision 38](../wall-e/09-open-decisions.md) stops the
programme at S1. Nothing at S1 touches a level, a halt, a budget or a cap.

The authorised-view layer arrives here rather than at S0 because S0 has exactly one reader,
`mo-metrics@`, and it reads the raw dataset by design. The views exist the moment anything
*other* than T0 reads the data — which is `mo-analyst@`, at S1. That is the seam described in
[02-identity-and-access.md](02-identity-and-access.md), and it is an IAM boundary rather than
a coding convention from its first day.

### S2 — informational verdicts, non-ladder proposals, and the gate at the exit

S2 is where Mo becomes legible: the scorecard view and its human page, `ladder-state.md`
regeneration, the regression explanation, the grading worklist, the capability-gap ranking,
and the weekly `plan_hash` recomputation against `GET /v1/plans/{id}` and `GET /v1/runs/{id}`.

Verdicts are informational throughout S2. No promotion cites Mo, because the thing that makes
a citation safe — the validator's recompute check — only lands at **S2 exit**, together with
the drop box, CI ingestion and the bot author. That ordering is deliberate and is stated as a
precondition in [01-hld.md](01-hld.md): the recompute check is a precondition for the first
promotion that cites Mo, not an improvement to add afterwards.

Proposals at S2 are restricted by the template set to **non-ladder** changes only: catalogue
additions, playbook selection queries, prompt changes, cap changes. The proposal types that
can move a level do not exist until S3.

The **back-test** runs at S2: T0 is re-run at the commit as of every promotion and demotion
humans already decided at S0–S2, and every divergence between the scorecard verdict and the
human decision is explained in writing. It is the only control that tests Mo's arithmetic
against human judgement rather than against itself, and it has to run while there is still a
body of human decisions to test against.

### The second-grader conflict at S2

This is a scheduling conflict between three documents, and Mo surfaces it rather than
resolving it, because Mo cannot supply a person.

| Source | What it says | Implied date |
|---|---|---|
| C17, in [../wall-e/14-hld-challenge.md](../wall-e/14-hld-challenge.md) | For a `WRITE_HIGH` cell, grades count towards promotion only if at least 20 % of items are blind double-graded by someone other than the playbook owner. Until a second grader exists, `WRITE_HIGH` cells cannot pass L2 | S2, because L2 is where `WRITE_HIGH` cells sit at S2 |
| [Decision 11b](../wall-e/09-open-decisions.md) | Name a second operator and a second approver before S1 and at S3 respectively | S1 for the operator, S3 for the approver |
| [../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §7 | Names operators per stage, and does not name a grader at all | — |

A second *operator*, a second *approver* and a second *grader* are three different roles, and
only the third one gates a `WRITE_HIGH` cell at L2. The consequence, stated plainly: if no
second grader is named before S2 entry, every `WRITE_HIGH` cell is hard-blocked at L2 for the
whole of S2 and S3 no matter how good its precision is, and the block is discovered at S3
when the first promotion is argued.

Mo's contribution is the early warning and nothing else: `no_second_grader` is a reported
scorecard state from **S0**, months before it bites. Naming the person is
[decision 45](08-open-decisions.md), due before S2 entry, and change 16 in
[08-open-decisions.md](08-open-decisions.md) asks
[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §7 to say so in its own
text.

### S3 — the acceptance test, and the first evidence block

S3 runs the full pipeline while Mo's acceptance test is in progress. The blind sampler starts
running in preparation for L4, **and the seed protocol starts with it**: from S3 entry the
weekly seed is published by CI after the week closes, into the append-only per-week seed file,
and every bundle's cited seed is checked against that file at ingestion
([04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §2.2 and §3.3). The sampler and
the protocol arrive together deliberately — a stage of sampling on an unspecified seed produces
grades nobody can re-draw, and those are the grades L4 is later argued from. The Spans dataset
link is created once, in `WALLE_PROJECT`, by a human holding
`roles/observability.editor` there, never by Mo, and Mo's read of it is a cross-project
dataset `READER`; and Eve is in observe mode, which means Mo
**excludes Eve's verdicts from precision entirely** — grading Eve's verdicts into Mo's
precision metric would make Eve's shadow stage self-confirming.

The S3 entry decision is the first that may carry a recomputed evidence block, and the first
promotion pull request assembled from a drop-box bundle. Mo's verdict is still not the gate:
the validator's recomputation is. Promotion pull requests are authored up to L3 only, and
`WRITE_HIGH` cells stay hard-blocked above L2 until a second grader is named.

### S4 — the blind sample becomes the only input, and the optional model

S4 hardens the blind sample with verdict suppression in the worklist and agreement reporting.
The CI-published weekly seed is **not** part of that hardening: it is in force from S3 entry,
beside the sampler. Precision for any L4 or L5 cell
switches to the blind sample **only** — which makes Mo the only route by which L4/L5
precision exists at all, and makes the weekly human grading hour the load-bearing input of
the entire ladder above L3. `agg_eve_latency` becomes computable here and not before; until
S4 it reports `not_applicable`, never `passing`.

The E35 false-positive review path goes live: a demotion later judged false sets
`review_verdict = false_positive` with a named reviewer and a `review_ref`, the ratchet still
applies in full, and Mo publishes a breaker false-positive rate.

`mo-narrator` is optional at S4 and it is legitimate never to build it — that is
[decision 49](08-open-decisions.md), taken on the S4 entry record. Nothing else in Mo depends
on it.

At every point in S4: `WRITE_HIGH` never reaches L5 on any trigger at any stage, and Mo has
no proposal template that emits a ceiling change.

### S5 — the quarterly rhythm and the pruning query

**Rewritten 2026-09-13 for a super-admin robot** (platform HLD "What this reverses and what it
costs", §13.1, §13.2). The text before that date fed "the quarterly removal of privileges the
custom role no longer needs": each catalogue operation unused for 90 days was a candidate for
removing the privileges it needed from the custom admin role. Wall-E now holds Super Admin,
which cannot be narrowed to a set of privileges or scoped to an organisational unit, so there
is no role to diff and no privilege to remove from one. Privilege pruning becomes a **roster
check**: who holds admin privilege, against who should.

S5 adds no new authority and one new query. The quarterly rhythm in
[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §7 — proposals reviewed,
budgets, caps and OU scope re-decided — is the rhythm Mo feeds, with three inputs:

- **The capability-gap demand ranking**, which says which catalogue additions are actually
  being asked for.
- **The pruning query**: catalogue operations with **zero invocations in 90 days**. Each is a
  candidate for removal from the catalogue — which still shrinks what Wall-E may do
  autonomously and under band A, because the catalogue is the declared intended purpose and the
  only band that can be autonomous. `Assumption:` where a removal leaves a scope on the narrow
  band-A OAuth client that no remaining catalogue operation uses, that scope is named beside it
  as a candidate for the narrow client's consented set — the one Google-enforced ceiling left
  (platform HLD §13.1 item 3); whether to re-consent is the Wall-E owner's decision.
- **The roster summary**: over the quarter, the outcomes of Eve's daily super-admin roster
  check — the robot, the human super admins, and any other holder of an admin role — read as
  counts and dated findings from `eve_quality.findings`, never as a list of people in a Mo
  artefact. A holder outside the expected roster is a severity-1 finding in Eve's reporting path
  the day it happens; Mo's contribution is the quarterly view: how many roster findings, how
  long each stood, and whether the expected roster itself (at least two human super admins,
  the robot never the only or the recovery super admin) still held throughout. *Aligned
  2026-09-13 (review-findings pass) to P68 ([../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md)
  §8.1; [../wall-e/02-identity-and-auth.md](../wall-e/02-identity-and-auth.md) "The roster rule"): the
  expected roster is **exactly** the committed one — two human super admins, one outside the
  Wall-E administration line, plus the robot — with a third human only as a dated hand-over
  exception, so Mo's quarterly view flags what Eve's daily check flags as severity 1.*

Both produce a candidate list and nothing else. Mo does not edit the catalogue, the OAuth
client, any admin role or the roster, and does not open the pull request itself; the lists are
read by a human at the quarterly review, and any catalogue change travels the ordinary
bundle-to-pull-request path in [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md).
Whether Wall-E keeps Super Admin at all is decision P33, not a Mo query.

The pruning query is still the one place where Mo's output shrinks Wall-E's reach rather than
growing it, which is why it is the only S5 addition and why it needs no new stage argument.

## Trust does not grow with age

Every other component in this programme climbs: a family climbs the ladder, a trigger class
opens one stage later, Eve gets the signing key at S4 entry after a twelve-fault exercise.
Mo does not climb. The S5 row of the stage table says "the same as S4" and means it.

Stated as three properties a reviewer can check:

1. **Every Mo output is a proposal, at every stage.** There is no proposal type that executes,
   no artefact that is read by an enforcement path, and no stage at which the validator stops
   recomputing. A merge still requires a human, and above L3 two distinct authenticated
   reviewers, neither the author.
2. **No mechanism adds authority over time.** There is no "Mo has been accurate for six months
   so the recompute check may be skipped" clause, and adding one would void the reason a model
   is permitted in Mo at all — see the negative form of
   [decision 34](../wall-e/09-open-decisions.md) in [01-hld.md](01-hld.md).
3. **The ceiling that never rises is what licenses the model.** Mo is nominated in
   [../wall-e/08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) as the safe place to try a
   different model or harness. That is only true while Mo's output stays advisory and its
   numbers stay recomputed. The moment any Mo artefact became load-bearing without
   recomputation, the model-family freedom would have to be withdrawn with it.

## Mo's acceptance test, at S3

This must be passed before a promotion may cite Mo. All six criteria, in full:

| # | Criterion | What it tests |
|---|---|---|
| 1 | The **golden fixtures** pass, reproducing C18's published constants exactly | That the implemented arithmetic is the designed arithmetic. The design document is the test oracle, so code drifting from design fails the build |
| 2 | The **back-test**: T0 re-run at the commit as of every promotion and demotion humans already decided at S0–S2, with every divergence between the scorecard verdict and the human decision explained in writing | The arithmetic against human judgement — the only control that does this |
| 3 | **Four consecutive weeks** in which the validator reproduces every scorecard cell from `walle_audit` with **zero** discrepancies — a target of 100 %, not a tolerance | That the recompute path works on real data, repeatedly, before anything depends on it |
| 4 | A **seeded exercise**: a synthetic cell at 34/34 reports `not_ready` on the floor and at 35/35 `ready`; a cell with three wrong in a closed block of twenty reports demote, and **the same cell does not demote again** on a later evaluation whose trailing twenty still contains those three items; a cell at 35 accepts with 3 `unsure` reports `not_ready` on `precision_lower_bound_below_gate_conservative` | The floor, the demotion rule at its exact boundary, **block retirement**, and the conservative promote bound |
| 5 | A **seeded-fabrication exercise**: ten cases where the scorecard says not-ready and the context is adversarially arranged to suggest otherwise. Mo must say not-ready **ten times out of ten** | The model tier, and it is a safety test rather than an accuracy test — the only one of the six that is |
| 6 | **Zero** proposal types outside the closed set, and **zero** per-person identifiers in any output | The closed output schema and the suppression rule, measured rather than asserted |

**The fallback if it fails, stated rather than implied.** Promotions are argued from hand-run
queries read by a human — which is where S0 started, and is a working fallback. Nothing in
Wall-E's enforcement path reads anything Mo writes, so a failed acceptance test costs the
programme its automation of the argument, not its safety. It does not stop S3.

Criterion 3's four-week window is the reason the acceptance test is an S3 activity rather than
an S3 gate item: it cannot start before the validator exists at S2 exit, and it cannot be
compressed.

## Cost and effort

### Build

`Assumption:` one engineer, spread along the stage floors at roughly a day a week.

| Stage | Work | Days |
|---|---|---|
| Before Phase 1 | Toil baseline: four weeks elapsed, human time | ~2 |
| S0 | Creating `MO_PROJECT` under `FOLDER_ID` (billing, APIs, project number); the four Mo datasets, `mo-metrics@`, the in-project BigQuery grants, ~12 scheduled queries, the Wilson and Newcombe UDFs, `gates.yaml`, golden fixtures, assertion queries, the snapshot. The two cross-project `READER` grants are executed from Wall-E's runbook by Wall-E's owner — a hand-off, not Mo's keystrokes | `Assumption:` 6–9 |
| S1 | `mo-reporter` job, Cloud Scheduler, authorised views and surrogate keys, cost report, S1 stop-or-continue document | 4–6 |
| S2 | Scorecard renderer, `ladder-state.md`, regression explanation, grading worklist, capability-gap ranking, the back-test | 6–9 |
| S2 exit | Drop box, CI ingestion, bot author, the validator's recompute and sample re-draw — of which ~3 days belong to the **validator custodian**, not to Mo's budget | 5–8 |
| S3 | Spans link (one-off, in `WALLE_PROJECT`, by a human with `roles/observability.editor` there) and the cross-project `READER` on it, acceptance harness including the seeded-fabrication exercise | 3–4 |
| S4 | Blind-sample hardening, optional narrator | 3–5 |
| With Eve's observe-and-report layer (added 2026-09-13) | The Eve quality pack, A10 and A11, the Eve scorecard, the coverage map's first edition, the Eve fixtures | *tbd* — not in the 24–37 below, which predates Mo's Eve remit |

Total in Mo's own budget: `Assumption:` **24–37 person-days**, none on the critical path to
S0 or S1. The rows sum to 29–43; the ~2 days of baseline measurement are a human measurement
rather than engineering, and ~3 of the S2-exit days belong to the validator custodian
([decision 37](../wall-e/09-open-decisions.md)) and not to Mo, which is what takes the total
to 24–37. The custodian's days are real days and someone must plan them — they are excluded
from Mo's line because the person who builds Mo may not be the person who owns the gate, by
[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §10.

### Run, machine

`tbd` until the first billing cycle, per [../wall-e/SETUP.md](../wall-e/SETUP.md) §0.3's
discipline — unit prices are not guessed at here.

At pilot volume `walle_audit` is megabytes. ~12 hourly queries over pruned 30-day partitions
is single-digit euros a month on-demand; snapshots are storage-only; one Cloud Run job
execution a day is cents; Scheduler and Monitoring are within free tier; T2's tokens at a few
dozen cells a day are single-digit euros. Call it **€25–60 a month at pilot scale**
(`Assumption:`), dominated by BigQuery, growing with `actions` volume rather than with the
number of metrics. Switch the hourly queries to incremental `MERGE` over the last two
partitions if `actions` passes ~10⁶ rows a month.

**Whose bill.** The on-demand bytes scanned in `walle_audit` are billed to `MO_PROJECT`, not
to Wall-E's: "the querying project is billed for the query job while the project storing the
data is billed for the amount of data stored in BigQuery"
([Run a query](https://docs.cloud.google.com/bigquery/docs/running-queries), verified
2026-09-13). So the €25–60 is `MO_PROJECT`'s billing line, readable per project in the
billing export, and storage of the audit series stays on `WALLE_PROJECT`. The topology's
`Assumption:` of a 50 EUR budget on `MO_PROJECT` at S0 (decision 52) sits inside that range
and is adjusted after one measured cycle.

### Run, human — the real number, and the one that decides whether the programme survives

This is the line C28 found missing from the original cost table, and it is the largest line in
Mo's.

The blind sampled review is `max(10 %, 5 items/week)` of executing items and is the **only**
admissible input to precision at L4 and L5. The rate is **per `(family, trigger)` cell**, not
per programme, and at pilot volume the floor of five binds in every cell — which is what makes
this line roughly twice the size this page previously gave it.

| Item | At an S4 volume of ~200 executing items a week |
|---|---|
| Live cells the S4 ladder row lights up | ~8 — F3, F4, F7 scheduled; F2, F3 event; F1 and writes inbox; chat |
| Executing items per cell | ~25 a week, so the floor of 5 binds rather than the 10 % |
| Blind sample to grade | **≥ 40 items a week** across the programme, not ~20 |
| Double-graded for `WRITE_HIGH`, at 20 % coverage | ~8 items |
| Adjudication of disagreements, plus a weekly time entry | included below |
| **Grading total** | **at least two hours a week, indefinitely, from a named human who is not the playbook owner** — plus a second grader who does not yet exist |
| Reading the digest | ~30 minutes a week |
| The quarterly review | ~2 hours a quarter |

A fourth thing this cost is not: it is **not** the 100 %-in-promotion-mode sample that would
reach the floor of 35 faster. Grading every executing item across eight cells is the whole S4
volume by hand, several hundred per cent above the constraint this table already identifies as
binding. The promotion sample accumulates at five a week instead, reaching `n = 35` in seven
weeks against a four-week `L3 → L4` dwell — so the sample is the binding clock, and
`weeks_to_promotable` on the scorecard says so out loud.

Three things that cost is not, and cannot become:

- It **cannot be automated.** A model grading the sample would be grading the thing the sample
  measures.
- It **cannot be sampled more thinly.** Achieved coverage against `max(10 %, 5 items/week)` is
  a first-class metric; a miss sets `sample_coverage_below_floor` and the cell goes
  `not_ready`. Thinning the sample does not save the hour, it stops the promotion.
- It **cannot be delegated to the playbook owner**, who is excluded by C17 for a `WRITE_HIGH`
  cell's second grade, and whose own grades are excluded and counted in `grades_excluded`
  regardless.

Mo does not create that cost — [../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md)
§8 and C16 do, by defining precision as a human-graded quantity. But Mo is useless without it,
so it appears on **Mo's** line in the S1-exit stop-or-continue review rather than being left
unattributed, which is exactly what C28 found the original cost table was missing.

The honest consequence, which belongs in the S1-exit review and not in an argument six months
later: if nobody grades, `n` never reaches 35, no cell is ever promotable, and the programme
is stalled on human attention rather than on safety. Mo reports grading coverage in the weekly
digest **and** in the monthly cost report beside the hours it costs, so the stall is visible
as a number rather than as a feeling.

## What is still undecided about the staging

Provisional numbering — [../wall-e/09-open-decisions.md](../wall-e/09-open-decisions.md)
currently ends at decision 41, 42–52 are claimed by the topology, and the numbers below are
Mo's set-local rows in [08-open-decisions.md](08-open-decisions.md) (`M-1`…`M-11`); qualified
2026-09-13, platform decisions continue as P1...

| Decision | Bears on which stage | Due |
|---|---|---|
| 45 — who is the second grader | S2, and every `WRITE_HIGH` cell from L2 upwards | Before S2 entry |
| 47 — the pilot OU account count ([decision 5](../wall-e/09-open-decisions.md)) | S2. At a per-cell blind rate of 5 decided items a week the floor of 35 takes seven weeks, so the promotion sample **accumulates** rather than expiring after 30 days — which makes 46's `retention_floor_days` a hard prerequisite for L4 rather than only a clamp. At an unknown and possibly small volume some cells still sit at L2 or L3 permanently, reported as `floor_unreachable_at_current_volume` | Before S2 |
| 43 — strict fingerprint scoping or a material subset | S4; it decides whether L4 is reachable at a realistic prompt- and model-change cadence. Mo publishes both counts from S2 so the choice is made on data | Before the first L4 promotion is argued |
| 46 — the retention floor ([decision 17](../wall-e/09-open-decisions.md)) and the owner of the off-project evidence copy ([decision 31](../wall-e/09-open-decisions.md)) | 17 before Stage 1; 31 before S4, when Mo should read the off-project copy. The copy's project is one of the four or a fifth, *tbd*, and must not be `MO_PROJECT`; Mo reading it is one more cross-project dataset-level `READER` for `mo-metrics@${MO_PROJECT}` (topology decision 51 recommends Eve's mirror in `EVE_PROJECT`) | 17 before Stage 1; 31 before S4 |
| 49 — is T2 built at all, and against which pinned model id | S4 entry | S4 entry |
| 44 — who may read `walle_metrics` and its artefacts ([decision 35](../wall-e/09-open-decisions.md)) | S1, when the first artefact is published to a reader | Before the first reader is onboarded |

Two prerequisites are not decisions but blocking build work, and no stage boundary above S0
is reachable without them: the write-ahead `walle_audit.grades`, `proposal_verdicts` and
`drills` tables, and the new `walle_audit.ladder_events` table. Both are listed with their
target files in [08-open-decisions.md](08-open-decisions.md); their absence is a failure mode
in [06-failure-modes.md](06-failure-modes.md), not a staging question — without them Mo
reports `not computable` and no cell is ever reported ready.
