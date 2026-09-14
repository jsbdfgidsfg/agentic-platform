# 4. The five artefacts, and how a proposal becomes a merge

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Objective restated 2026-09-13 (platform HLD
  [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.3): Mo also measures and
  proposes for Eve (§1.6, §1.7, §3.2, §3.5–§3.6), writes an Art. 72 plan per high-risk system
  (§1.8), and uses agent-neutral names (§3.7). The title keeps "five" for Wall-E's five.

Mo was built backwards from five things a human reads — Wall-E's five, plus the Eve and
compliance artefacts of §1.6–§1.8. Everything else in the design —
the metric queries, the authorised views, the three identities, the drop box — exists
because one of these five needs it. The design starts from what a human reads and ends at the
SQL, not the other way round: if an artefact would not change a decision someone actually
takes, the pipeline behind it is not built. This page says exactly what each one contains, on what
schedule, for whom, at which path; then it follows a proposal from the moment `mo-reporter`
writes a bundle to the moment two humans merge it, and names every place the path refuses.

[08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) item 4 asks Mo to propose improvements as
pull requests, each with evidence attached and each requiring a human merge, and item 6 says
Mo never holds a credential and never writes to config. This page is how those two are made
true at once.

The seam that runs through the whole page: **Mo holds no git credential.** It writes an
object to a bucket. Continuous integration turns that object into a pull request under a bot
identity that is not Mo, and an external validator — owned outside the configuration
repository, run by the validator custodian ([decision 37](../wall-e/09-open-decisions.md)) —
re-executes the evidence rather than reading it. So the one component in the team that could
forge a plausible promotion does not exist. Identities and grants are in
[02-identity-and-access.md](02-identity-and-access.md); the arithmetic behind every number
named here is in [03-metrics-contract.md](03-metrics-contract.md); what exists at each stage
is in [05-staging.md](05-staging.md).

`Assumption:` the generated artefacts keep the repository paths this design names —
`platform/wall-e/mo/**` and `platform/wall-e/ladder-state.md` — because those strings are
also the drop box's path allowlist. These design pages live at `platform/mo/`; the two are
different directories in different repositories and the distinction is deliberate. If the
artefact directory is ever moved, the allowlist string moves with it, in the same pull
request, and that pull request is not one Mo may author. The same `Assumption:` covers the
Eve and Art. 72 paths — `platform/eve/mo/**` for the Eve artefacts and
`platform/<agent>/mo/art72-plan.md` for each Art. 72 plan — which follow Wall-E's pattern and
are fixed when Mo-8 creates the directories.

---

## 1. The five artefacts

| # | Artefact | Path | Schedule | Audience | Exists from |
|---|---|---|---|---|---|
| 1 | Promotion-readiness scorecard | `platform/wall-e/mo/scorecard.md`, over `walle_metrics.scorecard` and its daily snapshot `walle_metrics_archive.scorecard_YYYYMMDD` | The view is per `as_of_hour`; the snapshot is daily; the page is regenerated on the weekly reporter run | The ladder owner | S2 |
| 2 | Ladder state | `platform/wall-e/ladder-state.md` | *tbd* — regenerated as a pull request, never pushed; read at the weekly review | The ladder owner, the weekly review | S2 |
| 3 | Weekly digest | `platform/wall-e/mo/digest-YYYY-Www.md` | Monday 08:00 Europe/Paris | `walle-operators@` | S2 |
| 4 | Regression explanation | `platform/wall-e/mo/regression-<cell>-<date>.md` | On a detected change point, not on a calendar | The ladder owner | S2 |
| 5 | Monthly cost report | `platform/wall-e/mo/cost-YYYY-MM.md` | Monthly | Decision 38's stop-or-continue review | **S1** |
| 6 | Misbehaviour taxonomy and detector coverage map — **the first Eve artefact** | `platform/eve/mo/coverage-map.md` (`Assumption:` path) | First edition before Wall-E's Stage 1 (P143); regenerated on every `eve_config_version` change and after every seeded-fault run; any calendar cadence beyond those triggers *tbd* | The Eve owner, the security reviewer | Before Wall-E's Stage 1 |
| 7 | Eve scorecard — the Eve quality pack | `platform/eve/mo/scorecard.md` (`Assumption:` path) | Weekly reporter run | The Eve owner | When `eve_quality` exists |
| 8 | Art. 72 post-market monitoring plan, one per high-risk system | `platform/<agent>/mo/art72-plan.md` (`Assumption:` path) | On every stage decision; re-cut when the Commission's Art. 72(3) template is adopted | The AI compliance owner | S2 for Wall-E |

The cost report is first because it is the artefact that answers whether any of this should
continue, and [decision 38](../wall-e/09-open-decisions.md) sets that review at S1 exit.
Every other artefact is about levels, and no level moves before S2.

Each artefact is markdown, regenerated as a pull request through the drop box of §3 and never
pushed. A further output is not an artefact but a contract: the **proposal bundle**, specified
field by field in [§3.1](#31-the-bundle-contract).

Four supporting outputs are not artefacts in this sense — nobody reads them as prose — but
the artefacts are assembled from them and the validator reads them directly:
`walle_metrics.scorecard`, the daily snapshot `walle_metrics_archive.scorecard_YYYYMMDD`,
the sixteen `agg_*` aggregates — each the sole source for one figure, ten of them for one of
the ten §8 metrics — and `walle_metrics.grading_worklist`. They are specified in
[03-metrics-contract.md](03-metrics-contract.md).

### 1.1 The scorecard page

The human face of `walle_metrics.scorecard`, one section per `(family, trigger)` cell.
Aggregate only, minimum reporting cell size 5 (`Assumption:`, pending
[decision 35](../wall-e/09-open-decisions.md)); a group-by cell with a count between 1 and 4
is suppressed rather than rounded, and the suppression is itself reported so a reader knows
a row was withheld rather than absent.

Per cell it prints: current level and target level; dwell elapsed against dwell required and
the event that last reset the clock; days since the last demotion and the ratchet state;
every [05](../wall-e/05-autonomy-ladder.md) §8 criterion with its measured value, its
threshold and its pass or fail; `n_decided`, `n_unsure` and `unsure_rate`; `wilson_lower`,
`wilson_upper` and `wilson_lower_conservative`; `window_length_days` and
`weeks_to_promotable`, so a long accumulation reads as a long accumulation; sample coverage
achieved against required; double-grade coverage, the double-graded and single-graded counts,
and agreement; `grades_excluded` with the reason each grade was excluded; error-budget state;
freeze state; the ceiling; one-notch eligibility; `max_ts_seen` per source; and the verdict,
one of `ready`, `not_ready`, `insufficient_data`, with `reasons` drawn from a closed enum.

The verdict is a SQL `CASE` over the columns beside it. It is **informational at every
stage**: no promotion is authorised by it, because the validator recomputes rather than
believes. At S0 and S1 every cell reads `insufficient_data` and no exit criterion cites it —
the write budget is zero and no sample approaches the floor of 35.

### 1.2 `ladder-state.md`

[05](../wall-e/05-autonomy-ladder.md) §10 already specifies this page and says Mo owns
regenerating it once Mo exists; until then it is a scheduled query pasted in weekly. It
carries the current matrix, active overrides, the deployed config version, the last drill
date, the `walle_metrics` freshness watermark, and one added column: per-cell readiness, from
the scorecard.

It is regenerated **as a pull request**, never pushed. This is the only artefact whose
content is also configuration-adjacent, and treating it like every other Mo output —
a bundle, an ingestion check, a bot author, a human merge — costs one review a week and
removes the only reason Mo would ever need write access to a branch.

When Mo is down the page goes stale and says so, because it carries the watermark. A stale
`ladder-state.md` is a visible fact rather than a silent one.

### 1.3 The weekly digest

Monday 08:00 Europe/Paris, to `walle-operators@`. Contents:

- what changed since the last digest — levels, config versions, overrides, freezes;
- what is frozen and why, naming the metric and the threshold that froze it;
- the grading worklist for the week, and the previous week's achieved coverage against
  `max(10 %, 5 items/week)`;
- the results of the weekly plan-hash recomputation: how many plans were sampled, how many
  audit rows agreed with the frozen plan, and every disagreement in full;
- grading coverage as a first-class number, beside the hours it costs;
- and a standing footnote, repeated every week rather than written once and forgotten:
  **Google's log proves the robot acted, never who asked** ([14](../wall-e/14-hld-challenge.md)
  C43). Human attribution comes from Wall-E's own rows, which is the half no independent
  source corroborates.

Nobody reading the digest is a failure mode with a name and no mitigation: see
[06-failure-modes.md](06-failure-modes.md). Mo cannot make anyone grade and does not pretend
to.

### 1.4 The regression explanation

Written when a change point is detected in a cell, not on a schedule. Contents:

- the change point, with the window either side;
- the **fingerprint diff**, naming every field of the fingerprint tuple that moved, together
  and individually;
- before and after values with the **Newcombe 95 % interval for the difference** in
  precision across the boundary;
- prose beside the numbers, which is the one place a model may write in this document set,
  and only from S4.

It says *coincides with*, never *caused by*, because deploys are not randomised. With fewer
than 12 decided items on either side of the boundary it reports `insufficient_data` and stops.
**Attribution never gates**: no level moves because of a regression page. The page is an
argument put to a human, and the human opens whatever follows.

### 1.5 The monthly cost report

The artefact decision 38's stop-or-continue review is read from. Contents:

- cost per operation and per playbook, from `agg_cost_operation` and `agg_cost_playbook`;
- infrastructure lines, with the shared half attributed pro rata by run count and
  **labelled an allocation, not a measurement**;
- **human operating hours**, against the four-week measured toil baseline in
  `config/metrics/toil_baseline.csv` — the denominator that cannot be reconstructed after the
  fact, which is why the baseline is the one part of Mo that exists before Wall-E does;
- approval burden in hours, computed the way [§6](#6-the-decision-file) computes the
  "Why worth it" line;
- the capability-gap demand ranking, from `agg_capability_gap`;
- and the toil-saved-versus-operating-cost figure, with the human line given the prominence
  [14](../wall-e/14-hld-challenge.md) C28 found the original cost table lacked.

Grading hours appear here as well as in the digest, deliberately: the review that decides
whether the programme continues should see that it is stalled on human attention rather than
on safety, if that is what is true.

### 1.6 The misbehaviour taxonomy and coverage map — the first Eve artefact

Platform HLD §13.2, §13.3. Improving Eve starts from knowing what Eve is
supposed to catch. With Wall-E holding Super Admin, the misbehaviour Eve must report is no
longer bounded by a role: role grants, security settings, DWD, API controls, data-region and
retention changes, sinks and audit-log sharing, the robot acting on itself or on Eve, and any
admin event outside the catalogue and band B are all reachable by the credential. This page is
the list of those classes and, per class, the detector that would see it.

| Column | Contents |
|---|---|
| Class | One misbehaviour class of a super-admin Wall-E, from the platform's hard-denied list and detection catalogue (platform HLD §13.1 item 2, §7.3) and the public agent-threat taxonomy the catalogue is scored against (P21, *tbd*) |
| Detector | Each that applies: an Eve seeded fault; a Wall-E breaker or policy-chain denial; Eve's reconciliation of Google's streams; the SIEM's super-admin detection set; or **none** |
| Evidence the detector fired | The last `seeded_fault_runs` row for that class and `eve_config_version`, or `never exercised` |
| Latency | The detector's lag budget as Eve's set declares it, and Mo's measured E5/E6 where computable ([03-metrics-contract.md](03-metrics-contract.md) §7.3) |
| Gap | `covered`, `covered, never exercised`, or `uncovered` |

Every `uncovered` or `never exercised` row is an item on the **Eve-improvement backlog**, and
the only proposals Mo may attach to it are the Eve types of §3.5 — a `seeded_fault_addition`
for a class with a detector but no fault, an `eve_incident_note` for a class with no detector.
Mo names the gap; a human designs the detector. A non-zero metric 9b count
([03-metrics-contract.md](03-metrics-contract.md) §7.2) is always an entry here. The map is
aggregate: class names and counts, never a person, and it follows the suppression rule.

### 1.7 The Eve scorecard

The human face of the Eve quality pack, per Wall-E cell — the metrics E1–E9 and their sources
are defined in [03-metrics-contract.md](03-metrics-contract.md#73-the-eve-quality-pack) §7.3.
Each figure carries its source and, where the source rule says so, the label `self_reported`. Until the validator custodian holds `READER` on `eve_quality`
(P30), the page opens with the fixed line "Advisory — not re-derivable by the validator yet".
Eve reads nothing on it.

### 1.8 The Art. 72 post-market monitoring plan, per high-risk system

[../agentic-platform/10-eu-ai-act.md](../agentic-platform/10-eu-ai-act.md) §4.4; platform HLD
§14.1. For each agent the register marks high-risk, Mo's artefacts **are**
the post-market monitoring plan, and this page is the plan's text: one paragraph naming the
artefacts (the scorecard with audit completeness first, `ladder-state.md`, the digest, the
regression explanation, the cost report, and for a Tier P agent the Eve scorecard and coverage
map), their cadence, their reader, and the two feeds the artefacts receive from outside Mo —
every Art. 73 assessment outcome and every Art. 86 explanation request. Owner: the Mo owner;
reader: the AI compliance owner. It is regenerated as a pull request like every other artefact,
and re-cut into the Commission's Art. 72(3) template when that is adopted (date unverified,
per page 10). A silent Mo is severity 2 on that page, which is why the plan names the
freshness alert as its liveness control. The plan's verification: the digest lands weekly, and
`metric_divergence` between Mo and Eve is watched.

The loop the plan describes: the agent's audit dataset (its Art. 12 log) feeds T0 and the blind
grading; they feed the artefacts; the artefacts feed a promotion record carrying its Art. 9
residual-risk statement; a human merges the level change, which is a pre-determined change in
the sense of Annex IV 2(f); and the changed agent writes back to its audit dataset. Three
inputs enter from outside that loop: the Art. 73 assessment outcomes, the Art. 86 explanation
requests, and Eve's findings and verdicts through `eve_quality`. The plan's text per system is
one paragraph in the agent's entry; whether that entry carries the paragraph itself or links
this page is unverified.

---

## 2. Grading

Grading is the only input to plan precision at L4 and L5 ([14](../wall-e/14-hld-challenge.md)
C16), it is produced entirely by humans, and it is the input Mo cannot replace, simulate or
degrade gracefully without. It gets its own chapter because everything above L3 rests on it.

### 2.1 The worklist

`walle_metrics.grading_worklist` holds the week's items. One row per item to grade:
`run_id#item_index` as an opaque identifier, plus the family. **Eve's verdict column is
absent by construction** — not filtered in the renderer, not hidden in the page, absent from
the view — so a grader cannot see it whatever they do with the artefact.

The grading surface itself is a dependency of Mo, not part of it
([decision 14](../wall-e/09-open-decisions.md) owns what it turns out to be). It writes
write-ahead to `${WALLE_PROJECT}.walle_audit.grades`, which Mo reads cross-project. Mo reads
no Firestore.

### 2.2 The draw, and the seed protocol

The weekly blind sample is `max(10 %, 5 items/week)` **per cell**, drawn by a published
`FARM_FINGERPRINT` ordering over a seed CI commits after the week closes into an append-only
per-week seed file, so nobody — Mo included — chooses or can anticipate it, and the validator,
or an auditor months later, re-draws it from the seed; the draw expression, the seed protocol
(in force from S3 entry) and the coverage metric are defined in
[03-metrics-contract.md](03-metrics-contract.md#13-the-blind-sample-and-the-seed-protocol) §13.
What the proposal path adds is the anchor: ingestion refuses a bundle whose cited seed is not
the one the seed file records for `week(window_end)` ([§3.3](#33-ingestion-and-the-bot-author)),
the way `scorecard_sha256` is anchored to a published scorecard. Without it, the validator's
re-draw proves only that a bundle agrees with itself, not *which* seed it used.

### 2.3 Who may grade, and what is excluded

Only human principals on the committed grader list may grade. Grades from a non-human, from
the author of the playbook version under test, or made unblinded are excluded and counted in
`grades_excluded`; a `WRITE_HIGH` cell needs a 20 % second grade by someone other than the
playbook owner and an unadjudicated disagreement blocks the cell — the full rules are in
[03-metrics-contract.md](03-metrics-contract.md#10-grading-rules) §10. `no_second_grader` is
reported from **S0** because [14](../wall-e/14-hld-challenge.md) C17 makes a second grader a
condition for passing **L2**, at S2, while [decision 11b](../wall-e/09-open-decisions.md) puts
the second person at S3; Mo surfaces that conflict and cannot supply a person
([M-4](08-open-decisions.md), [05-staging.md](05-staging.md#the-second-grader-conflict-at-s2)).

### 2.4 Agreement

Raw agreement and Gwet's AC1 are reported; Cohen's κ is reported and never gated on — see
[03-metrics-contract.md](03-metrics-contract.md#10-grading-rules) §10.

### 2.5 What the grading surface must write

These columns are a blocking prerequisite on Wall-E's side
([08-open-decisions.md](08-open-decisions.md) change 1); without them plan precision is not
computable at all.

| Column | Why Mo needs it |
|---|---|
| `run_id`, `item_index` | The join to the action row, and the identity of the sampled item |
| `verdict ∈ {accept, reject, unsure}` | The precision numerator and denominator; `unsure` excluded and capped |
| `grader_id`, `is_playbook_owner` | The grader-list and self-grading exclusions |
| `blind`, `saw_eve_verdict` | The L4/L5 admissibility exclusions |
| `graded_at` | Freshness, and the weekly window |
| `second_grader`, `adjudicated_by`, `adjudication` | Double-grade coverage, agreement, and the unadjudicated-disagreement rule |
| `playbook_version` | Scoping a grade to the fingerprint it was earned under |

### 2.6 The weekly human cost, stated plainly

Because the rate is per cell, at an S4 volume of about 200 executing items a week across ~8
live cells the floor of five binds everywhere: at least 40 graded items a week plus 20 %
double-grading and adjudication — **at least two hours a week, indefinitely, from a named human
who is not the playbook owner**, plus a second grader who does not yet exist
([03-metrics-contract.md](03-metrics-contract.md#133-coverage-is-itself-a-metric) §13.3; the
digest and quarterly-review hours are in
[05-staging.md](05-staging.md#run-human--the-real-number-and-the-one-that-decides-whether-the-programme-survives)).
It cannot be automated, sampled more thinly without the cell going `not_ready`, or delegated to
a model. Mo does not create this cost — [05](../wall-e/05-autonomy-ladder.md) §8 and C16 do —
but Mo is useless without it, so it appears on Mo's line in the S1-exit review rather than in a
footnote.

---

## 3. From bundle to merge

**Why a drop box rather than a credential.** The obvious design gives Mo a git credential — a
GitHub App installation, a deploy key — so it can open its own pull requests. That would make
Mo the one component whose compromise produces a plausible promotion pull request, and it
contradicts the plain reading of [08](../wall-e/08-team-eve-mo.md) item 6, "never hold a
credential"; so it is not built. Instead Mo writes one object to one bucket, and three
properties follow: Mo cannot push, merge, approve, re-open, or even read back what it wrote
([§3.1](#31-the-bundle-contract)); the blast radius of a compromised Mo is bounded by path
before CI ever runs ([§3.2](#32-the-path-allowlist)); and the numbers in a bundle are recomputed
by an identity Mo cannot reach ([§3.4](#34-what-the-validator-enforces)), so a forged promotion
has to be **true** to pass. The cost is one bucket. The residual, carried in
[06-failure-modes.md](06-failure-modes.md), is a truthful-but-tendentious argument that two
tired humans rubber-stamp — [06](../wall-e/06-security-guardrails.md)'s accepted risk, narrowed
from "any change" to "a change whose numbers are true".

```mermaid
sequenceDiagram
    autonumber
    participant T1 as "mo-reporter, as mo-analyst, in MO_PROJECT"
    participant BOX as "Drop box mo-proposals, in MO_PROJECT"
    participant CI as "CI ingestion"
    participant BOT as "Bot author, not Mo"
    participant VAL as "Validator, owned outside the repo, in its custodian's project"
    participant AUD as "walle_audit, in WALLE_PROJECT"
    participant HUM as "Two authenticated reviewers"

    T1->>BOX: write one bundle object - diff, evidence_block, decision_record_draft, narrative
    Note over BOX: objectCreator only - no read back, no overwrite, no delete
    BOX->>CI: ingest one object
    Note over BOX,CI: CI reads the bucket cross-project - objectViewer, bucket-level, identity tbd
    alt diff touches a path outside the allowlist
        CI-->>BOX: reject at ingestion, no pull request is opened
    else scorecard_sha256 was never published, or the snapshot does not exist
        CI-->>BOX: reject at ingestion
    else seed is not the one the per-week seed file records for this window
        CI-->>BOX: reject at ingestion, before the recompute
    else output fails the closed schema
        CI-->>BOX: reject, count mo_schema_violation, disable the renderer
    else accepted
        CI->>CI: strip narrative from the evidence path
        CI->>BOT: hand over the diff and the evidence block
        BOT->>VAL: open the pull request
    end
    VAL->>AUD: re-execute the evidence SQL at its pinned commit
    Note over VAL,AUD: cross-project, dataset-level read - no binding in MO_PROJECT
    VAL->>AUD: re-draw the blind sample from the published week seed
    alt any value differs, or the sample differs
        VAL-->>BOT: required check fails, merge refused
    else metrics watermark older than 24 hours
        VAL-->>BOT: merge refused, Mo is stale
    else a section 10 gate is unsatisfied
        VAL-->>BOT: merge refused, naming the gate
    else every gate passes
        VAL->>HUM: required check green
        HUM->>BOT: two distinct authenticated approvals, neither the author
        HUM->>VAL: merge
    end
```

### 3.1 The bundle contract

One object per bundle in `mo-proposals` (§3.7), a bucket in `MO_PROJECT`, written by
`mo-analyst@${MO_PROJECT}` with `roles/storage.objectCreator` and nothing else. Verified 2026-09-12: that role "Allows users
to create objects. Does not give permission to view, delete, or **overwrite** objects"
([IAM roles for Cloud Storage](https://docs.cloud.google.com/storage/docs/access-control/iam-roles)).
So Mo cannot read back, replace or delete a bundle it has written, and a duplicate write
**fails** rather than silently replacing — which is also how a double-triggered reporter run
is caught.

The bucket itself: location `EU` (`$BQ_LOCATION`), uniform bucket-level access, public access
prevention, object versioning on, and a 90-day lifecycle that deletes both live and
noncurrent objects at 90 days of age. Bundle writes must be attributable, and because the bucket is in `MO_PROJECT`
nothing is inherited from Wall-E's project: `MO_PROJECT` enables Cloud Storage Data Access audit
logs itself — `DATA_WRITE`, and `DATA_READ` so the CI bot's reads are attributable as well
(`Assumption:` for the `DATA_READ` half). The commands are in
[07-build-runbook.md](07-build-runbook.md) Phase Mo-9.

| Field | Contents | Who reads it |
|---|---|---|
| `diff` | The proposed change, confined to the path allowlist in [§3.2](#32-the-path-allowlist) | Ingestion, then the bot, then the reviewers |
| `evidence_block` | The re-executable claim, field by field below | Ingestion, then the validator |
| `decision_record_draft` | The decision file in the wiki template, with the five mandatory lines of [§6](#6-the-decision-file) filled in | The reviewers |
| `narrative` | Prose. **Stripped before validation.** Rendered into the pull-request body under the fixed heading "Mo's reading — advisory, not evidence; CI ignores this block" | Humans only |

The evidence block, field by field. Every field is present in every bundle; a missing or
empty field is a rejection at ingestion, not a warning.

| Field | Meaning | Why the validator needs it |
|---|---|---|
| `metric` | The metric name, from the closed set in [03-metrics-contract.md](03-metrics-contract.md) | Selects which aggregate is the sole source |
| `value` | The asserted value | The thing that must be reproduced exactly |
| `sql_commit_sha` | The commit of `config/metrics/*.sql` the value was computed at | The validator checks out that commit and runs that SQL, not today's |
| `sql_path` | The file inside that commit | As above |
| `window_start`, `window_end` | Absolute timestamps | A window is never "the last 30 days" at validation time |
| `fingerprint_sha` | The fingerprint the evidence was earned under | Evidence earned under a different fingerprint does not count — C15's gaming path, closed at the measurement layer |
| `n` | The sample size | Checked against the floor of 35 and against the recomputed count |
| `seed` | The `week_seed` CI published after the week closed | The validator re-draws the blind sample from it — **after** ingestion has checked it against the per-week seed file ([§3.3](#33-ingestion-and-the-bot-author)) |
| `double_grade_coverage` | The coverage the evidence was earned at | A precision figure earned at one coverage is not comparable with one earned at another; a bundle whose coverage moved mid-window is refused ([§3.4](#34-what-the-validator-enforces)) |
| `scorecard_sha256` | The SHA-256 of the scorecard row `mo-metrics@` published | A bundle citing a hash that was never published is rejected before the recompute even runs |
| `snapshot_name` | The `${MO_PROJECT}.walle_metrics_archive.scorecard_YYYYMMDD` snapshot the claim points at, project-qualified | The dated, citable object an auditor replays against, rather than a mutable table |

**For an Eve bundle** the same fields apply, with `metric` drawn from the
Eve quality pack, the SQL reading `eve_quality` and `walle_audit` fully qualified, and every
cited value `evidence_eligible` under assertion A10; `Assumption:` the bundle additionally
declares its target repository (`config` or `eve/config`), which ingestion checks against the
allowlist the diff falls under.

The whole block is re-executable by anyone holding dataset-level read on
`${WALLE_PROJECT}.walle_audit` (and, for an Eve bundle, on `${EVE_PROJECT}.eve_quality`) and job rights in a project of their own, holding no binding
of any kind in `MO_PROJECT`, and with no cooperation from Mo. The SQL names every table
fully qualified, and declares the two interval functions as `CREATE TEMP FUNCTION` from the
committed text ([03-metrics-contract.md](03-metrics-contract.md) §3), so it resolves from
any project.

### 3.2 The path allowlist

Ingestion rejects a bundle whose diff touches anything outside this set — **before CI runs,
before a pull request exists**:

| Allowed path | What Mo may change there |
|---|---|
| `config/ladder.yaml` | A level, and only in the direction and by the amount the scorecard's evidence supports |
| `config/playbooks/**` | Selection queries, `expects`, caps |
| `config/prompts/**` | Prompt text, which bumps `prompt_hash` and re-qualifies the cell |
| `config/catalogue/**` | Catalogue **additions**. Never the risk tiers — see [§7](#7-mo-may-not-propose-changes-to-its-own-gating-layer) |
| `platform/wall-e/mo/**` | Mo's own artefacts |
| `platform/wall-e/ladder-state.md` | The regenerated ladder-state page |
| `platform/eve/mo/**` | The Eve artefacts of §1.6 and §1.7, and `eve_incident_note` |
| `platform/<agent>/mo/art72-plan.md` | The Art. 72 plan of §1.8, one per high-risk system |

**In Eve's repository, `eve/config`** (platform HLD §13.3). Exactly two
paths, and only through the Eve proposal types of §3.5:

| Allowed path in `eve/config` | What Mo may change there |
|---|---|
| `thresholds.yaml` | A threshold row, through `eve_threshold_tighten` or `eve_threshold_loosen` only |
| `seeded_faults/**` | A new fault fixture, through `seeded_fault_addition` only — additions, never an edit or a removal |

**Never**, in any type, at any stage: `predicates/`, `ceilings.py`, `reasons.yaml`,
`oncall.yaml`, or the `eve_authority` field. Those are Eve's gating and reporting layer and stay
human-authored; a bundle touching one is refused at ingestion, before CI.

Anything else is refused at ingestion: the ceiling module, the policy chain, the catalogue's
risk tiers, the validator, `config/metrics/**` and `config/metrics/gates.yaml`, and every
`eve/config` path not in the second table. That makes
[05](../wall-e/05-autonomy-ladder.md) §10's "the gate cannot be part of what it gates"
enforced **twice** — once at the bucket, once in CI — and the two enforcements are owned by
different people.

### 3.3 Ingestion and the bot author

CI ingests one object at a time and, in order: checks the path allowlist; checks the closed
output schema; checks that `scorecard_sha256` names a scorecard `mo-metrics@` actually
published and that `snapshot_name` names a snapshot that exists; checks that
`evidence_block.seed` **equals the seed CI committed for `week(window_end)`** in the
append-only per-week seed file ([§2.2](#22-the-draw-and-the-seed-protocol)); strips
`narrative` from everything the validator will see; and only then opens the pull request under
a **bot identity that is not Mo**.

**Two of those checks read something in `MO_PROJECT` from outside it**, and the route has to
be named because "the validator never reads `walle_metrics`" and "ingestion checks the
snapshot exists" cannot both be literal across a project boundary unless different
identities do them. The route: the **CI ingestion identity** — the bot, not the validator —
holds a metadata-only read in `MO_PROJECT`: `Assumption:` `roles/bigquery.metadataViewer` at
dataset level on `${MO_PROJECT}:walle_metrics_archive` (enough to see that
`scorecard_YYYYMMDD` exists, not to read it) and on the published-hash register, plus
bucket-level `roles/storage.objectViewer` on the drop box. The validator holds nothing in
`MO_PROJECT`. Its reader binding is the only principal on the bucket besides `mo-analyst@`'s
`objectCreator`, and it is the bot's, never the validator's; a compromised bot reads bundles,
which are proposals, not evidence. The identity, its home and the exact roles are *tbd* with the
git host ([M-7](08-open-decisions.md)) — through a Workload Identity Federation pool in
`MO_PROJECT` if the host federates — and are recorded as [M-11](08-open-decisions.md) (c),
topology decision 50 ([`../project-topology.md`](../project-topology.md) §3 rows 19 and 20).

The seed check is there for the same reason as the `scorecard_sha256` check. Both
`scorecard_sha256` and `snapshot_name` are anchored to something published; the seed is the
one input that decides **which items are evidence at all**, and without an anchor the
validator's later re-draw compares a membership against a claim descending from the same
unverified value. A bundle citing a seed no week file records is rejected **before** the
recompute runs.

The bot holds the git credential. Mo does not, at any stage, in any component, for any
reason. That is the single structural difference between this design and every design in
which Mo could produce a pull request on its own authority — and it is why a compromised Mo
produces, at worst, an object in a bucket that fails a path check.

### 3.4 What the validator enforces

The recompute check is a **required** check in the configuration repository, owned outside
that repository, deployed **by image digest** rather than a mutable tag. It holds no binding
of any kind in `MO_PROJECT` — so it never reads `walle_metrics` — never trusts a number Mo
asserts, and never accepts prose as evidence: a validator that read Mo's own output would be
checking Mo against Mo, and that exclusion is denial test MD-9, with its IAM form MD-9b
([07-build-runbook.md](07-build-runbook.md) Phase Mo-12). Its identity holds dataset-level
`READER` on `${WALLE_PROJECT}:walle_audit`, made by Wall-E's owner, and — for Eve bundles, once
it exists (P30, made by Eve's runbook) — on `${EVE_PROJECT}.eve_quality`, plus
`roles/bigquery.jobUser` in the custodian's own project (*tbd*, decision 37); never a
project-level role in `WALLE_PROJECT` or `EVE_PROJECT`, and it appears nowhere in `MO_PROJECT`'s
IAM policy or dataset access lists ([`../project-topology.md`](../project-topology.md) §3 row 21).

| Gate | Source | Refusal |
|---|---|---|
| Re-execute the evidence SQL at `sql_commit_sha` against `${WALLE_PROJECT}.walle_audit`, cross-project from the custodian's project | This design | Any value differs → merge refused |
| `seed` is the seed the per-week file records for `week(window_end)` | This design, C16 | Any other seed → rejected at ingestion, before the recompute |
| Re-draw the blind sample from `seed` | This design, C16 | Sample membership differs → merge refused |
| `double_grade_coverage` moved during the promotion window | This design, C17 | Refused: the evidence mixes two measurement processes in an unrecorded proportion |
| `walle_metrics` watermark ≤ 24 hours old — reached **without a data read in `MO_PROJECT`**: the validator takes the watermark from the cited snapshot's own date in `snapshot_name` (a `scorecard_YYYYMMDD` older than 24 hours is stale by name) and, `Assumption:`, cross-checks it against the `custom.googleapis.com/mo/metrics_watermark_age_hours` metric that the ingestion identity, not the validator, reads in `MO_PROJECT` — the provisional route recorded in [M-11](08-open-decisions.md) (c) | This design | Stale Mo refuses **every** promotion — absence is restrictive |
| A level went up without a link to an `accepted` decision file | [05](../wall-e/05-autonomy-ladder.md) §10 | Refused |
| The level exceeds a ceiling | §10 | Refused |
| A `WRITE_HIGH` promotion lacks a second named approver | §10 | Refused |
| An override exists for that cell and the pull request does not reference its incident | §10 | Refused |
| The §6 dwell rule is unsatisfied | §10 | Refused |
| The last kill-switch drill is older than 30 days | §10 | Refused |
| **Two distinct authenticated approving reviewers**, neither of whom authored the pull request, matched against the `Approvers:` line | C17 | Refused |
| A change to a playbook's pinned selection query, `uses` list or scope, **or to `config/prompts/**`**, for a playbook serving a cell above L2, without a linked decision record | C15 | Refused; the changed playbook re-runs the canary at its current level or lower |
| `redesign_required` on the family — two demotions in 90 days, excluding those a named human has marked `false_positive` with a `review_ref` | This design, §8 error budgets | Refused until the redesign lands |
| One pull request touching more than one of `ladder.yaml`, `config/metrics/*.sql`, `config/metrics/fixtures/**`, `config/metrics/gates.yaml`, the ceiling module, the policy chain, the catalogue risk tiers, the validator | This design, change 13 | Refused |
| The "Why worth it" line, for any L3→L4 `WRITE_HIGH` promotion | C34 | Refused if absent |
| An Eve bundle other than `eve_incident_note` while the custodian holds no `READER` on `eve_quality` | Platform HLD §13.3, P30 | Refused: Eve bundles are advisory until the gate can re-derive them. [07-build-runbook.md](07-build-runbook.md) Mo-9 places this refusal at ingestion; whether ingestion, the validator or both enforce it is unverified |
| An Eve bundle citing a value that is not `evidence_eligible` under A10 | Platform HLD §13.3 | Refused: a number about Eve that only Eve vouches for is not evidence |
| An `eve_threshold_loosen` for a cell within 30 days after a `promote` on the same cell — or a `promote` within 30 days after a merged `eve_threshold_loosen` on that cell | Platform HLD §13.3; §3.6 | Refused; the validator reads both repositories' merge history |
| An `eve_threshold_loosen` without two distinct authenticated reviewers including the decision-37 security reviewer, a decision record, and five business days' cooling since the bundle was opened | Platform HLD §13.3; §3.6 | Refused |
| An `eve_threshold_tighten` whose diff moves any row in the loosening direction | §3.6 | Refused: it is a loosening and needs that type |

**Two of those rows need their reasoning stated.**

- **C15 covers `config/prompts/**`.** `prompt_change` is one of the eight proposal types in
  [§3.5](#35-the-closed-proposal-type-set), and a prompt edit bumps `prompt_hash` and therefore
  the fingerprint. With the demotion denominator unscoped
  ([03-metrics-contract.md](03-metrics-contract.md) §11.2) a fingerprint bump can no longer
  empty the demotion evidence; with this row, a fingerprint bump above L2 also costs a decision
  record and a canary at the current level or lower. Together they mean a fingerprint change
  **lowers or holds** a level and never clears accumulated demotion pressure. No new threshold
  and no new constant was needed for either half.
- **`config/metrics/fixtures/**` is a change-13 group of its own**, separate from
  `config/metrics/*.sql`. The golden fixtures are the design's only control on an arithmetic
  error the validator structurally cannot catch, and an oracle that can travel in the same pull
  request as the code it tests is a weaker control than
  [03-metrics-contract.md](03-metrics-contract.md) §5 claims. Splitting the group is the whole
  of the fix; CI does not read the wiki.

Two limits on the validator, stated rather than hidden. It **cannot** catch an arithmetic
error, because it re-runs the same committed SQL and inherits the same defect — that is what
the golden fixtures, the assertion queries and the S2 back-test are for
([06-failure-modes.md](06-failure-modes.md)). And it cannot enforce the git host's
admin-bypass setting: it reports the setting it observes, and a host where an administrator
can bypass branch protection makes the two-reviewer rule decoration. The branch
protection this design recommends, and Mo-9 configures, is two distinct authenticated
reviewers, neither the author, with admin bypass **disabled and audited**. The host and that
setting are `tbd` (C17), carried as [M-7](08-open-decisions.md).

### 3.5 The closed proposal type set

A bundle declares exactly one type, from this set and no other. A type outside it is rejected
at ingestion, and "zero proposal types outside the closed set" is one of the six criteria of
Mo's acceptance test.

| Type | What it changes | First available | Notes |
|---|---|---|---|
| `promote` | A level up in `config/ladder.yaml` | S3, up to L3; L4 from S4 | Needs the full evidence block, two authenticated reviewers above L3, and the "Why worth it" line for L3→L4 `WRITE_HIGH` |
| `demote_proposal` | A level down | S2 | A **proposal**, not a demotion. Machine demotions happen in the action service's breakers and in Eve, neither of which reads anything Mo writes |
| `cap_change` | A budget or rate cap in a playbook | S2 | |
| `playbook_selection_change` | A playbook's selection query | S2 | Re-qualifies the cell under C15; the canary re-runs |
| `catalogue_addition` | A new operation, entering at L0 | S2 | Ranked from `agg_capability_gap`. Never a risk-tier change |
| `prompt_change` | Prompt text | S2 | Bumps `prompt_hash`, which changes the fingerprint. It **resets the promotion sample** and **does not clear the demotion denominator**, which is unscoped ([03-metrics-contract.md](03-metrics-contract.md) §11.2). Above L2 it needs a linked decision record and re-runs the canary at the current level or lower ([§3.4](#34-what-the-validator-enforces), C15) |
| `ladder_state_regen` | `platform/wall-e/ladder-state.md` | S2 | The regenerated page, as a pull request |
| `incident_note` | A note under `platform/wall-e/mo/**` | S2 | How a finding Mo may not act on reaches a human — including the E35 breaker-false-positive route |

**The Eve proposal types — a closed set of their own** (platform HLD §13.3).
An Eve bundle declares exactly one of these and no other; a Wall-E type in an Eve bundle, or an
Eve type in a Wall-E bundle, is rejected at ingestion.

| Type | What it changes | Reviewers | First available | Notes |
|---|---|---|---|---|
| `eve_threshold_tighten` | A row of `eve/config/thresholds.yaml`, **monotone-restrictive** only — a change that can only produce more refusals, more pages or shorter lag budgets | One | S2 exit, and beyond advisory only once P30 lands | The validator refuses a diff that moves any row the other way. `Assumption:` the direction of each row is declared by Eve's set with the threshold numbers (E-18). `eve/config` otherwise requires two reviewers ([../eve/09-open-decisions.md](../eve/09-open-decisions.md), decision 37 row); whether branch protection admits one for this type is Eve's set's to reconcile, and until it does the stricter two apply |
| `eve_threshold_loosen` | A row of `thresholds.yaml` in the loosening direction | **Two**, distinct and authenticated, one of them the decision-37 security reviewer; Eve's second reviewer is neither the ladder owner nor Mo's CI operator | S2 exit, only once P30 lands | Full evidence block, a decision record, five business days' cooling, and the 30-day cross rule of §3.6 |
| `seeded_fault_addition` | A new fixture under `eve/config/seeded_faults/**` | The reviewers `eve/config` already requires | S2 exit | Additive only. Usually opened from a `covered, never exercised` row of the coverage map |
| `eve_incident_note` | A note under `platform/eve/mo/**` | — (a note, not a change) | When `eve_quality` exists | The only Eve type available before P30, stated in its heading as advisory. How a Mo finding about Eve — a divergence, an uncovered class, a threshold suspect — reaches a human |

Through S2 the template set is restricted to the **non-ladder** types: catalogue additions,
playbook selection queries, prompt changes, cap changes. `promote` and `demote_proposal`
become available at S3, which is the first stage whose entry decision may carry a recomputed
evidence block. Mo has no template that emits a ceiling change at any stage, and
`WRITE_HIGH` never reaches L5 on any trigger at any stage.

### 3.6 The Eve proposal path: reviewer rules and the 30-day cross rule

Platform HLD §13.3; Mo change 20 in [08-open-decisions.md](08-open-decisions.md).
Mo improving Eve must not become Mo steering the component that checks Wall-E, so the Eve path
is narrower than Wall-E's in four ways.

1. **Eve can lower; Mo can only propose.** Eve reads nothing Mo writes. A change to
   `thresholds.yaml` reaches Eve only as a Mo bundle, through ingestion, the validator and a
   human merge into `eve/config`. Eve's own fast drop to advisory stays Eve's, on Eve's number.
2. **Tighten is cheap, loosen is not.** A monotone-restrictive tightening needs one reviewer. A
   loosening needs the full evidence block, two distinct authenticated reviewers including the
   decision-37 security reviewer, a decision record
   (`wiki/decisions/YYYY-MM-DD-eve-threshold-loosen-<row>.md`, `Assumption:` name), and five
   business days' cooling on the `Europe/Paris` calendar — the mirror of Wall-E's ratchet.
3. **The 30-day cross rule.** The validator refuses an `eve_threshold_loosen` for a cell within
   30 days of a Wall-E `promote` on the same cell, **in either order** — a promote within 30 days
   after a merged Eve loosening on that cell is refused as well. A level that rises while the
   verifier of that level is being relaxed is exactly the combination neither repository sees
   alone, so the validator reads both repositories' merge history.
4. **Separation of the reviewers.** Eve's second reviewer is neither the ladder owner nor the
   person who runs Mo's CI, so the same hand cannot write a Wall-E promotion, author the Eve
   loosening beside it and wave both through (the one-administrator concentration Eve's own
   limit 5 names).

And Mo is **never Eve's grader**: grades of Eve's verdicts are human, in `grades_eve`, written by
the platform approval surface.

### 3.7 Agent-neutral names

There is one Mo per platform (platform HLD §13.3), so nothing of Mo's is named
for one agent. Resources that do not exist yet take agent-neutral names **before Stage 0**.

| Was | Is | State |
|---|---|---|
| bucket `walle-mo-proposals` | **`mo-proposals`** | Renamed in this set on 2026-09-13; [`../project-topology.md`](../project-topology.md) rows that still spell the old name are the platform owner's edit |
| datasets `walle_metrics`, `walle_metrics_archive`, `walle_metrics_private`, `walle_metrics_views` | agent-neutral names keyed on `agent_id`; the platform HLD §13.3 spells the scorecard `platform_metrics.scorecard` | *tbd* — the rename touches the topology, the platform data inventory and Wall-E's set, so it lands in one pass before Stage 0; until then this set keeps `walle_metrics*` and every table carries `agent_id` |
| artefact paths `platform/wall-e/mo/**` | `platform/<agent_id>/mo/**` per agent | Wall-E's paths are already that pattern; the Eve and Art. 72 paths above follow it |

---

## 4. `mo_schema_violation`

Every Mo output is produced against a **closed schema**: fixed field names, closed
vocabularies, no free-text field outside `narrative`. Anything that does not parse against
it is not dropped and not repaired. It is counted as `mo_schema_violation`, and **any
occurrence disables the renderer until a human has reviewed it**.

The reasoning is that a malformed output is the visible symptom of either a code defect or a
steered model, and the failure mode of silently discarding it is that a steered model gets
unlimited attempts at a parse the pipeline will accept. Loud and stopped is cheaper than
quiet and retried. The counter appears on the scorecard and in the digest, so a violation is
visible even to someone who never reads a log.

A violation blocks rendering. It does not block the metric queries, which are T0 and do not
go through the renderer, and it does not demote anything: Mo's outputs being absent is
restrictive in exactly one direction, and never in the other.

---

## 5. The reason array is a union

Where a model contributes at all — from S4, in `mo-narrator`, in prose — the composition rule
is that the scorecard's `reasons` array is a **set union**. There is a code path that adds a
`not_ready` reason and **no code path that removes one**. A model contribution is therefore
monotone-restrictive: the worst a compromised or hallucinating narrator can do to a verdict
is make it harder to promote.

This is the same property as the drop box and the watermark, applied to prose, and it is what
makes it defensible to put a model anywhere near a document that argues for a level.

---

## 6. The decision file

Every promotion carries one file, using the wiki decision template plus the five mandatory
lines [05](../wall-e/05-autonomy-ladder.md) §10 already requires:

```
wiki/decisions/YYYY-MM-DD-walle-promote-<family>-<trigger>-L<n>.md

- Config version: 2026.09.0-1 → 2026.10.0-1
- Evidence: <metric values, the query used, the window>
- Drill: <date of last kill-switch drill>
- Approvers: <ladder owner>; <second human, required for L4/L5>
- Demote if: <the thresholds from §8 that apply to this cell>
```

Mo's `decision_record_draft` fills these in from the scorecard: the `Evidence:` line becomes
the evidence block in human-readable form, citing `sql_path` at `sql_commit_sha`, the
absolute window, `n`, `fingerprint_sha`, the `scorecard_sha256` and the snapshot name. The
`Approvers:` line is the line the validator matches against two distinct authenticated
approving reviewers, so a name typed into it that does not correspond to an approval on the
pull request fails the check rather than passing unnoticed.

**The sixth line, "Why worth it"**, is required for any L3→L4 `WRITE_HIGH` promotion
([14](../wall-e/14-hld-challenge.md) C34). It quantifies the approval burden the promotion
avoids, and Mo computes it one way only:

> **approval events for the cell in the window × the measured median handling time for that
> cell** = approval burden avoided, in hours.

`approval_latency_ms` is reported **separately and explicitly labelled waiting time, not
effort**. The two are different quantities and conflating them inflates the benefit by the
length of the operator's lunch. Handling time is measured, not estimated; where it has not
been measured for a cell, the line reads `tbd` and the promotion is argued without it rather
than with a number nobody took.

Automatic demotions write **no decision file** — machines do not decide. They write an
incident note under `platform/wall-e/incidents/`, a row in `walle_audit.ladder_events`, and
the re-promotion decision references both.

---

## 7. Mo may not propose changes to its own gating layer

The measurement is now part of the gate, so the measurement is inside the rule that the gate
cannot be part of what it gates.

Mo may not author a diff to `config/metrics/*.sql`, `config/metrics/fixtures/**`,
`config/metrics/gates.yaml`, the ceiling module, the policy chain, the catalogue's risk tiers,
or the validator — nor to Eve's `predicates/`, `ceilings.py`, `reasons.yaml`,
`oncall.yaml` or `eve_authority`, which are the gating layer Eve applies to Wall-E. Those paths are
outside the drop box allowlist, so the refusal happens at ingestion, before CI, before a pull
request exists. And per change 13, one pull request may not touch more than one of them even
when a human authors it: a metric change costs its own reviewed pull request and cannot
promote anything in the same breath.

This has a consequence worth naming rather than leaving to be discovered. When the breaker
false-positive rate rises, [03-metrics-contract.md](03-metrics-contract.md) §6.6's rule is
that the finding targets the **metric definition** or Eve, never the ladder (E35) — and Mo
cannot author that diff. So the route is: Mo publishes the rate on the scorecard and in the
digest, and raises an `incident_note` bundle under `platform/wall-e/mo/**` setting out the
case. A human opens the metric pull request, which goes through `ladder.yaml`'s reviewers,
carries its own decision record, and touches nothing else. Mo's contribution is the evidence
and the argument; the change to Mo's own arithmetic is always somebody else's commit.

The same route applies to the one rule this set cannot install for itself. The demote
predicate's evaluation unit — disjoint blocks of 20 decided items, once per closed grading
week, with the triggering block retired — has to land in
[05](../wall-e/05-autonomy-ladder.md) §8, because the components that enforce it are the
action service's breakers and Eve, and neither reads anything Mo writes. That is change 18 in
[08-open-decisions.md](08-open-decisions.md), it is not a `gates.yaml` edit, and Mo may not
author the diff: Mo raises an `incident_note` bundle and a human opens the pull request.

---

## 8. What this page assumes from elsewhere

| Assumption | Where it is settled |
|---|---|
| `walle_audit.grades` exists with the columns in [§2.5](#25-what-the-grading-surface-must-write), write-ahead, Firestore a cache | [08-open-decisions.md](08-open-decisions.md) change 1; C46/M60/E28 |
| `approvals` carries the per-item accept/reject vector bound to `plan_hash` | [08-open-decisions.md](08-open-decisions.md) change 6; C16 |
| Canonical plan serialisation — RFC 8785 canonical JSON, SHA-256 — is specified before the approve endpoint is built | [08-open-decisions.md](08-open-decisions.md) change 8; C39. Without it the weekly plan-hash recomputation is dropped and Mo should hold no action-service access at all |
| The `capability_gap` closed-enum intent class is defined | [08-open-decisions.md](08-open-decisions.md) change 7; C22 |
| The approval surface, and therefore the grading surface, is chosen | [decision 14](../wall-e/09-open-decisions.md) |
| Who may read `walle_metrics` and its artefacts, and the minimum cell size | [decision 35](../wall-e/09-open-decisions.md), [M-3](08-open-decisions.md). Until it lands: `walle-operators@` and the ladder owner only, minimum cell size 5, and **no Mo artefact is synced to Drive** |
| The git host and its admin-bypass setting | C17 records it `tbd`; [M-7](08-open-decisions.md) |
| The second grader, by S2 entry | [M-4](08-open-decisions.md) |
| `eve_quality` exists with `mo-metrics@`'s dataset-level `READER`, made by Eve's runbook | Platform HLD §18 items 17 and 25; [08-open-decisions.md](08-open-decisions.md) change 20, M-11 (d) |
| The validator custodian's `READER` on `eve_quality` | Platform decision P30. Until it lands, Eve bundles are `eve_incident_note` only |
| `grades_eve`, written by the platform approval surface, and `eve.seeded_fault_runs` | Platform HLD §13.3, §18 item 17 |
| The direction of every `thresholds.yaml` row, so `eve_threshold_tighten` can be checked | Eve's set, with E-18; *tbd* |
