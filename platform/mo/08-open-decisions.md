# 8. Open decisions, and what Mo forces on Wall-E

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-12

This page is the two lists a reviewer needs before agreeing that Mo can be built.

The first is the **ten decisions this design does not settle**: what each one is, why it
matters, what this design recommends, the gate past which building without an answer means
building something that has to be unbuilt, and where the answer gets recorded. None of them
blocks *writing* Mo's design — it is written. Several block *building* it, and three of them
(**44**, **45**, **47**) are about people and volumes rather than about code, which means
their lead time is measured in weeks of other people's calendars, not in engineering days.

The second is the **eighteen changes Mo forces on Wall-E's set**. Three of them are
blocking: without them Mo computes almost nothing, reports `not computable`, and no cell is
ever reported ready. They belong to Wall-E's schedule rather than to Mo's, which is why
[README.md](README.md) sends a builder to this page first.

Neither list is a decision a program may take. Mo proposes; it neither decides nor acts, and
it can neither raise nor lower a level. Every row below is closed by a human, in writing.

## Numbering, and where an answer is recorded

**Numbering is provisional.** [`../wall-e/09-open-decisions.md`](../wall-e/09-open-decisions.md)
currently ends at decision 41, and these ten continue that sequence as **42–51**. Eve's set
numbers its own twenty decisions `E-1` to `E-20`
([`../eve/09-open-decisions.md`](../eve/09-open-decisions.md)) and claims none of 42–51, so
the numbers below are unclaimed as of 2026-09-12 — but they are only fixed once both sets are
merged into Wall-E's decision list, and any further Wall-E decision taken before that
displaces them. Until then, a bare number in this set means a Wall-E decision, `C…` means a
challenge item in [`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md), and 42–51
mean the rows below. The set-local index `M-1` … `M-10` in the first column is there so a
reviewer can cite a row without depending on the global number holding.

**Where each is recorded — two places, doing different jobs.**

1. **The reasoning lives in this set**, on the page named in the last column. That page is
   what has to be edited when the answer lands; the row here is an index, not the argument.
2. **The answer lives in [`../../decisions/`](../../decisions/)** as a dated file,
   `YYYY-MM-DD-<title>.md`, carrying its number in the first line. That directory is
   append-only: a later decision supersedes an earlier one and never rewrites it. **Nothing
   is in it yet** — none of Wall-E's forty-one, none of Eve's twenty and none of these ten
   has been written down.

Four of the ten are not Mo's decisions at all. 44 is a sub-question of Wall-E's decision 35
inside decision 8; 46 is Wall-E's decisions 17 and 31; 47 is Wall-E's decision 5; 45 is the
grader half of Wall-E's decision 11b. They appear here because Mo is the component that
breaks first when they stay open, and because Mo's scorecard is where their absence becomes
visible as a number instead of a feeling.

## What comes due when

Gate order, earliest first. The two due before Stage 1 are the cheap ones today and the
expensive ones later.

| When | Decisions |
|---|---|
| Before Stage 1 | **46** (the retention-floor half — Wall-E decision 17) |
| Before Mo's onboarding phase is written | **42** |
| Before the first reader is onboarded (S1) | **44** |
| Before S2 entry | **45**, **47** |
| Before the first L4 promotion is argued | **43**, **48** |
| Before S4 | **46** (the off-project-copy half — Wall-E decision 31) |
| S4 entry | **49** |
| S5 review | **50** |
| At each stage decision | **51** |

## The ten open decisions

| # | Decision | Why it matters | Recommendation | Gate | Recorded in |
|---|---|---|---|---|---|
| **M-1** · 42 | **Does [08](../wall-e/08-team-eve-mo.md)'s "no write path of any kind" permit `mo-metrics@` writing `walle_metrics`?** | A strict reading of [ARCHITECTURE](../wall-e/ARCHITECTURE.md) §7.5 forbids Mo writing anything, which leaves the scorecard, the cost report and the regression explanation with no home — while the same contract demands Mo publish them. This design reads it as **no byte Mo writes is read by anything that enforces**. | Accept the narrower reading, and make it true by mechanism rather than by prose: **change 15** below adds a denial-suite row asserting that no enforcement identity holds read on `walle_metrics`. The fallback if the narrower reading is refused — artefacts into a Cloud Storage bucket with the same read exclusions — is the same interpretation in different storage, so refusing it changes nothing except cost. | Before Mo's onboarding phase is written | [02-identity-and-access.md](02-identity-and-access.md), [06-failure-modes.md](06-failure-modes.md) |
| **M-2** · 43 | **Strict fingerprint scoping, or a coarser *material* subset?** | [C15](../wall-e/14-hld-challenge.md) says any change to the platform tuple is material, and a promotion sample scoped to the current `fingerprint_sha` resets every time a prompt, a model id, the ADK version or a Model Armor filter version moves. Taken strictly it may make L4 practically unreachable at a realistic change cadence. A coarser subset reopens the gaming path C15 closed. | Default **strict**, because that is what C15 binds. Mo publishes **both** counts from S2 — the strict count and the count under a proposed material subset of selection hash, `prompt_hash` and `model_id` — so the choice is made on data rather than on frustration. A coarser subset needs its own decision record and the security reviewer, never a quiet parameter edit. **The question is about the promotion side only**: the demotion denominator is unscoped under either answer, so no settlement of this decision can turn a fingerprint bump into a way of clearing demotion evidence. | Before the first L4 promotion is argued | [03-metrics-contract.md](03-metrics-contract.md); the parameter in `config/metrics/gates.yaml` |
| **M-3** · 44 | **Who may read `walle_metrics` and its artefacts, and is the wiki's Drive sync an acceptable surface for aggregate admin-activity data about a small pilot OU?** | Wall-E's decision 35, inside decision 8, is unanswered, and `walle_metrics` has a **wider reader set than `walle_audit`** — which is precisely why suppression is a mechanism here and not a promise. | Until decision 35 lands: readers are `walle-operators@` and the ladder owner only; minimum reporting cell size 5 (`Assumption:`); and **no Mo artefact is synced to Drive**. Record Mo as a processor in the data-protection assessment — T0 reads per-person rows, and change 11 below corrects the document that says otherwise. | Before the first reader is onboarded | [02-identity-and-access.md](02-identity-and-access.md), [06-failure-modes.md](06-failure-modes.md); the data-protection assessment under Wall-E [decision 8](../wall-e/09-open-decisions.md) |
| **M-4** · 45 | **Who is the second grader, and when?** | [C17](../wall-e/14-hld-challenge.md) makes 20 % blind double-grading by someone other than the playbook owner a condition for a `WRITE_HIGH` cell to pass **L2** — which happens at **S2**. Wall-E's decision 11b puts a second *operator* before S1 and a second *approver* at S3. Three different roles, three different dates, and they do not line up. Mo cannot supply a person. | Name the second grader before S2 entry. Mo's contribution is the early warning and nothing else: `no_second_grader` is a reported scorecard state from **S0**, months before it bites, rather than a block discovered at S3 when the first promotion is argued. Change 16 below asks [05](../wall-e/05-autonomy-ladder.md) §7 to say so in its own text. | Before S2 entry | [05-staging.md](05-staging.md), [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md); Wall-E [decision 11](../wall-e/09-open-decisions.md) |
| **M-5** · 46 | **The retention floor (Wall-E decision 17) and the owner of the off-project evidence copy (Wall-E decision 31).** | Mo clamps every metric window to the declared retention floor and cannot choose the number; a window that predates the floor is unverifiable, and a teardown-and-recreate of `walle_audit` destroys the evidence series a promotion is argued from. | Answer decision 17 as a minimum **and** a maximum before Stage 1, as Eve's set also requires. Name decision 31's owner before S4, when Mo should read the **off-project copy** rather than the live dataset, so Wall-E's deployers cannot rewrite the evidence Mo argues from. | 17 before Stage 1; 31 before S4 | [03-metrics-contract.md](03-metrics-contract.md) (window clamping), [06-failure-modes.md](06-failure-modes.md); Wall-E [decisions 17 and 31](../wall-e/09-open-decisions.md) |
| **M-6** · 47 | **The pilot OU account count (Wall-E decision 5).** | Mo's scorecard has no denominator. The blind rate is `max(10 %, 5 items/week)` **per cell**, so below ~50 executing items a week in a cell the floor of five binds and a 30-day calendar window caps the sample at ~21 — permanently under the floor of 35, however long the cell runs perfectly. | Size it before S2. The window question is **answered** rather than left open: the promotion sample accumulates under one fingerprint until `n` reaches 35, bounded by `retention_floor_days`, and the 30-day rolling window governs the nine rate metrics only ([03-metrics-contract.md](03-metrics-contract.md) §4). That makes **46 a hard prerequisite for L4** — decision 17's floor and decision 31's off-project copy — rather than merely a clamp on it. Write down the honest consequence before it is argued about: at 5 decided items a week the floor takes seven weeks against a four-week dwell, some cells sit at L2 or L3 permanently, and the scorecard says `floor_unreachable_at_current_volume` rather than pretending. | Before S2 | [05-staging.md](05-staging.md), [03-metrics-contract.md](03-metrics-contract.md); Wall-E [decision 5](../wall-e/09-open-decisions.md) |
| **M-7** · 48 | **The git host and its admin-bypass setting.** | [C17](../wall-e/14-hld-challenge.md) records the host `tbd`, and the two-distinct-authenticated-reviewer rule at L4 and L5 is decoration if an administrator can bypass branch protection. Every gate in this design terminates in a merge. | Disable and audit admin bypass. The validator **reports the setting it observes and cannot enforce it** — that asymmetry is the point, and it should be in the artefact rather than in someone's memory. | Before the first L4 promotion | [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md), [06-failure-modes.md](06-failure-modes.md) |
| **M-8** · 49 | **Is T2 (`mo-narrator`) built at all, and against which pinned model id?** | Denying the narrator every free-text string is what makes it safe and is also what makes its prose thin. Cutting T2 entirely is a defensible reading of this design — and the model-family comparison [08](../wall-e/08-team-eve-mo.md) invites would then have no home anywhere in the team. | Build it at S4 or not at all; decide on the S4 entry record. If it is built, the pinned model id lives in `config/metrics/gates.yaml`'s sibling deploy config, and changing it is a configuration change with no safety review — which is the whole claim being tested. | S4 entry | [05-staging.md](05-staging.md), [01-hld.md](01-hld.md), [02-identity-and-access.md](02-identity-and-access.md) |
| **M-9** · 50 | **Does the metric SQL move to Dataform?** | Git-committed SQL under BigQuery scheduled queries gives versioning and review. Dataform additionally gives dependency ordering, native assertions and unit tests — at the cost of a product, a repository region that must match the dataset's processing region, and a service-agent `actAs` relationship. | Stay on scheduled queries for the pilot: [05](../wall-e/05-autonomy-ladder.md) §8 names them, and one assertion query plus git covers what Dataform would buy. Revisit if `config/metrics/` passes ~15 files or if the assertion queries become unmanageable. | S5 review | [07-build-runbook.md](07-build-runbook.md), [01-hld.md](01-hld.md) |
| **M-10** · 51 | **The `unsure` cap (0.10) and the Europe/Paris business-day calendar.** | Both are numbers this design chose, not numbers anyone measured. The cap decides when a cell is `not_ready` regardless of its precision; the calendar decides the five-business-day ratchet and the p50 approval-latency clock. The cap is set exactly wide enough to matter on the promote side, which is why that side also clears `wilson_lower_conservative` ([03-metrics-contract.md](03-metrics-contract.md) §4) — the second bound reduces what rests on the cap but does **not** settle it. | Put both in `config/metrics/gates.yaml` so changing either is a reviewed pull request, and revisit them with Wall-E's [decision 16](../wall-e/09-open-decisions.md) at each stage decision rather than now. | At each stage decision | [03-metrics-contract.md](03-metrics-contract.md); `config/metrics/gates.yaml` |

### Three rows that are not bookkeeping

- **45 is the load-bearing one.** The blind human sample is the only admissible input to
  precision at L4 and L5, and the second grade is a condition for a `WRITE_HIGH` cell to pass
  L2. If nobody is named before S2 entry, every `WRITE_HIGH` cell is hard-blocked at L2 for
  the whole of S2 and S3 however good its precision is, and the block is discovered at S3
  when the first promotion is argued rather than at S0 when it could have been scheduled.
  Mo can report the gap from S0; it cannot close it.
- **43 decides whether L4 exists in practice, on the promotion side.** Strict scoping is
  correct and brutal: the promotion sample resets on any fingerprint change, `n` falls below
  35, and the scorecard says not ready with the reason `evidence earned under fingerprint X,
  current Y, n=4`. The demotion denominator is unscoped either way, so neither answer turns a
  prompt edit into an escape from a demotion. That is an
  honest answer rather than a defect, and the reason Mo publishes both counts from S2 is so
  the decision is taken on the measured reset rate rather than on frustration in month six.
- **42 is the whole question of whether Mo may publish anything.** Everything else in this
  set assumes the narrow reading. If it is refused outright rather than moved to a bucket,
  Mo has no artefacts, and what remains is a set of hand-run queries — which is where S0
  starts and is a working fallback, but is not this design.

## What this design forces on Wall-E's set

Eighteen changes, ordered by whether they block Mo entirely. Each row names the file to edit
and the challenge or contract reference that already decided it, where one exists. Most of
these are **not new decisions**: they are things the adversarial review already settled and
that have not landed in the documents yet.

Reference key: `C…` are challenge items in
[`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md); `M…` and `E…` are the Mo
and Eve obligations the design was scored against, drawn from
[`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md) and Wall-E's review set; `B…`
are facts in the platform ground truth compiled on 2026-09-12. `Assumption:` the `M…`/`E…`
obligation ids are not yet reproduced as numbered lists in this wiki, so a reviewer resolves
them through the challenge item cited beside them.

### Blocking — Mo computes almost nothing without these

| # | Change | Target file | Reference | Why |
|---|---|---|---|---|
| **1** | Write-ahead `walle_audit.grades`, `proposal_verdicts` and `drills` as **first-class BigQuery tables**, with Firestore as a cache rather than the record. `grades` must carry `run_id`, `item_index`, `verdict ∈ {accept, reject, unsure}`, `grader_id`, `is_playbook_owner`, `blind`, `saw_eve_verdict`, `graded_at`, `second_grader`, `adjudicated_by`, `adjudication`, `playbook_version` | [`../wall-e/03-lld.md`](../wall-e/03-lld.md) storage; [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phase 7 | C46 / M60 / E28 | Already decided and not yet landed. Without these tables **plan precision and drill freshness are not computable at all**, and the design does not route around it by granting Mo Firestore access — that would put Mo inside the control plane's read surface for no artefact's sake. Those rows render `not computable — C46 schema decision outstanding` and no cell is reported ready |
| **2** | New table `walle_audit.ladder_events`: one row per effective-level transition, with `ts`, `family`, `trigger`, `from_level`, `to_level`, `origin ∈ {human, operator, eve, breaker}`, `reason_code`, `incident_ref`, `decision_ref`, `config_version`, `override_epoch`, `review_verdict ∈ {pending, upheld, false_positive}`, `review_ref`, `decided_block_id` | [`../wall-e/03-lld.md`](../wall-e/03-lld.md) storage; [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phase 7 | C45 / C46 | This is what C45/C46's "halts, overrides and breaker demotions logged as rows" has to become. Automatic demotions deliberately write no decision file, and `config_versions` is not stated to gain a row for them, so **dwell, the ratchet, two-demotions-in-90-days, more-than-three-demotions-in-an-hour and the false-positive review are all uncomputable today** by anything that reads BigQuery. `decided_block_id` is the block of 20 decided items the demotion was computed from ([03-metrics-contract.md](03-metrics-contract.md) §4); without it, assertion A9 cannot tell a second demotion on fresh evidence from a retired block firing twice, which is the difference between a working ratchet and a loop into `redesign_required`. Extending `config_versions` was considered and rejected: a ladder event is not a config version, and the review verdict has no home there |
| **3** | BigQuery grants for Mo's three service accounts, plus **four** datasets — `walle_metrics`, `walle_metrics_archive`, `walle_metrics_private` (the surrogate mapping alone, one writer, no reader) and `walle_metrics_views` (views only, no tables) — and the authorised-view registration on **`walle_metrics`**'s access list, never on `walle_audit`'s | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phases 7 and 13b; [`../wall-e/setup/walle_setup.py`](../wall-e/setup/walle_setup.py) `add_dataset_access` | B1 | The shared data plane [08](../wall-e/08-team-eve-mo.md) promises is **entirely unbuilt**. `add_dataset_access` is called exactly twice today, for `walle-actions@` and the `walle-audit-bq` sink writer, and for neither Eve nor Mo. Every grant in [02-identity-and-access.md](02-identity-and-access.md) is a build task, not a check |

### Required — a metric is wrong or absent without these

| # | Change | Target file | Reference | Why |
|---|---|---|---|---|
| **4** | `actions` gains `noop BOOL NOT NULL` | [`../wall-e/03-lld.md`](../wall-e/03-lld.md), `actions` schema | [05](../wall-e/05-autonomy-ladder.md) §8 | §8 says a no-op is "recorded and excluded" and no column records it. `error_class` is the wrong home — a no-op is not an error. Until it lands, breaker-trip counts carry `noop_exclusion_unavailable` and are used in **no verdict** |
| **5** | `actions` gains `selection_hash`, `adk_version`, `ma_filter_version` and `engine_resource`, plus a computed `fingerprint_sha` over the full ten-field tuple | [`../wall-e/03-lld.md`](../wall-e/03-lld.md), `actions` schema | C15 / E38 / M26 | Six of the ten fingerprint fields are on the row today; these four are not. Until they land, `fingerprint_sha` is computed over the available subset and the scorecard labels attribution `partial_fingerprint` — which is honest, and is also weaker than C15 requires |
| **6** | `approvals` gains the **per-item accept/reject vector bound to `plan_hash`**, with rejections recorded as `skipped_by_operator` | [`../wall-e/03-lld.md`](../wall-e/03-lld.md), `approvals` schema | C16 / M24 | Decided and not landed. Until it does, batch precision is `not computable` rather than approximated — counting a whole-plan approval as N accepts is exactly the inflation C16 found, and approximating it would put the inflation inside Mo instead of inside the argument |
| **7** | Define the `capability_gap` closed-enum intent class | [`../wall-e/03-lld.md`](../wall-e/03-lld.md) | C22 / M44 / E42 | Until the enum exists, `agg_capability_gap` returns empty, the demand ranking behind the S5 catalogue review is `tbd`, and the one signal that says which catalogue additions are actually being asked for does not exist |
| **8** | Write the **canonical plan serialisation** — RFC 8785 canonical JSON, SHA-256 — and the signed field list, **before** the approve endpoint and its stub caller are built | [`../wall-e/03-lld.md`](../wall-e/03-lld.md) | C39 / E23 / M74 | Mo recomputes `plan_hash` the same way on its weekly sample. If the spec is not written, the weekly plan/audit agreement check is dropped — and at that point `GET /v1/plans/{id}` and `GET /v1/runs/{id}` lose their only justification, so **Mo should hold no action-service access at all** and change 9 below should be reversed rather than made |

### Corrections to the contract and architecture documents

| # | Change | Target file | Reference | Why |
|---|---|---|---|---|
| **9** | Correct the Mo identities row and item 6 from "never call the action service" to "**the two read endpoints only**" | [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md) | C39 / E24 / M2 | Decided and not landed. 08's own interfaces table already lists Mo as a caller of `GET /v1/plans/{id}` and `GET /v1/runs/{id}`, and [ARCHITECTURE](../wall-e/ARCHITECTURE.md) §7.5's allowlist already names `mo-analyst@` on that row. The identities table and item 6 are the only places that still say never, and a reviewer reading them literally would refuse the design's one non-BigQuery dependency |
| **10** | Remove `walle-events` "subscribe" for Mo from the shared data plane, and mark the topic as added with Eve's design | [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md), [`../wall-e/01-hld.md`](../wall-e/01-hld.md), [`../wall-e/ARCHITECTURE.md`](../wall-e/ARCHITECTURE.md) | C30 / E26 / B3 | Mo takes no subscription: its tightest need is hourly, BigQuery default-stream writes are queryable immediately, and a subscription buys latency no artefact uses. The `PS --> MO` edge leaves the map. **Reconcile before editing:** Eve's set declines the topic as well and records the schema as the obligation of whoever later asks for it ([`../eve/09-open-decisions.md`](../eve/09-open-decisions.md), E-20), so if neither agent subscribes, the topic's owner and its schema are `tbd` and the edit should say that rather than reassigning it |
| **11** | Correct weakness 11's characterisation of the read-only stage's processing as "aggregated per organisational unit" where it concerns Mo | [`../wall-e/ARCHITECTURE.md`](../wall-e/ARCHITECTURE.md) §11 | — | **False at the pipeline layer.** T0 reads per-person rows from `walle_audit` and `walle_workspace_logs`; the aggregation and the minimum cell size happen downstream, in what Mo *publishes*. The data-protection assessment needs the true version, and Mo belongs in it as a processor. This is the one place the design corrects a claim in Wall-E's set rather than extending it |
| **12** | Record `MO_PRINCIPAL = serviceAccount:mo-analyst@${PROJECT}.iam.gserviceaccount.com` | [`../wall-e/setup/walle.env.example`](../wall-e/setup/walle.env.example); [`../wall-e/PREREQUISITES.md`](../wall-e/PREREQUISITES.md) items 11 and 13 | M47 | Settles the SETUP / `walle_setup.py` / prose divergence by **resolution rather than deletion**. Dropping `roles/agentregistry.viewer` and deleting `MO_PRINCIPAL` is correct by the artefact test and wrong on balance: M47 binds `strong`, the grant is already built in Phase 13b, and it is read-only on a registry. No edit to `walle_setup.py` is required, and the scorecard records the grant as granted-and-unused |
| **13** | Extend §10's "the gate cannot be part of what it gates" so that **one pull request may not touch more than one** of `config/ladder.yaml`, `config/metrics/*.sql`, `config/metrics/fixtures/**`, `config/metrics/gates.yaml`, the ceiling module, the policy chain, the catalogue risk tiers and the validator | [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) §10 | M29 | The measurement is now part of the gate. A metric change must cost its own reviewed pull request and cannot promote anything in the same breath. Enforced twice in this design — at drop-box ingestion, before CI sees the bundle, and again in CI. `config/metrics/fixtures/**` is a **separate group** from `config/metrics/*.sql` because the golden fixtures are the oracle for that SQL, and an oracle that travels with the code it tests is not a control |
| **14** | Add a Phase 16 monitoring row for the `walle_metrics` freshness watermark, written as an **absence** condition (`EVALUATION_MISSING_DATA_ACTIVE`) | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phase 16; [`../wall-e/06-security-guardrails.md`](../wall-e/06-security-guardrails.md), Monitoring | B10 | A threshold-only policy is silent exactly when the metric stops being written, which is the failure it exists to catch. The alert must never depend on Mo publishing its own liveness signal |
| **15** | Add a denial-suite row asserting that **no enforcement identity holds read on `walle_metrics`** — the action service, the dispatcher, the ladder deploy tool, Eve, and the CI gate validator | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) §4 denial suite, run again at Phase 17 | — | Turns Mo's containment from a claim into a test, and it is the **only mechanism behind decision 42**. Without it, "nothing Mo writes is read by anything that enforces" is a convention that survives exactly as long as nobody is in a hurry |
| **16** | Note in §7 that a second **grader** is needed by **S2**, not S3 | [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) §7; Wall-E [decision 11b](../wall-e/09-open-decisions.md) | C17 | C17 makes a second grader a condition for a `WRITE_HIGH` cell to pass **L2**, which happens at S2, while decision 11b puts the second person at S3. §7 names operators per stage and does not name a grader at all. Three roles — operator, approver, grader — are being carried as one, and only the third gates a cell |
| **17** | Add a new SETUP phase, **"Mo — metrics"**, at Stage 0, and **"Mo — reporting"** at S1 | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) | — | No Mo phase exists at all today. Both are drafted in the runbook's own shape — prerequisites, steps, exact command shapes, verify blocks, rollback, denial tests — in [07-build-runbook.md](07-build-runbook.md) |
| **18** | State in §8 that the demote predicate is evaluated over **disjoint blocks of 20 decided items, once per closed grading week**, and that a demotion **retires** the block that triggered it | [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) §8 | C18 | §8 says "thirty-day rolling window, evaluated hourly", which re-tests an overlapping window on every new grade. C18's whole argument is stated *per window* and its interval form cuts the per-evaluation false-demote rate from ~26 % to ~7.5 %; multiplying the evaluations gives the rate back. Worse, without retirement the `DM → RH → NR` path re-fires **deterministically**: five business days adds ~5 decided items at the per-cell blind rate, the same three errors stay inside the trailing twenty, and one cluster of three errors reaches `demotions_90d = 2` and `redesign_required`. This **cannot** be fixed in `gates.yaml` alone: the predicate is enforced by the action service's breakers and by Eve, neither of which reads anything Mo writes, so a Mo-side parameter would leave the two computing different predicates. Mo may not author this diff — it raises an `incident_note` bundle and a human opens the pull request |

### Who owns these

Changes **1**, **2** and **3** are Wall-E's schedule, not Mo's: they are schema and IAM work
in Wall-E's own runbook, and Mo cannot start S0 usefully without 3 or exit S0 usefully
without 1 and 2. Changes **4** to **8** can land alongside the metric they unblock, and each
one has a stated degraded behaviour in the meantime — `noop_exclusion_unavailable`,
`partial_fingerprint`, `not computable`, an empty `agg_capability_gap` — so a missing change
shows up in the scorecard rather than as a quietly wrong number. Changes **9** to **18** are
document and runbook edits, cheap individually, and **15** is the one that a security
reviewer should refuse to sign without. **18** is the one a *statistician* should refuse to
sign without: until it lands, this contract and the components that actually demote compute
different predicates, and the divergence favours demoting a good playbook.

## Reopen when

This design should be re-read, in whole or in part, when any of these becomes true. It is
written in the format of [`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md)'s
own reopen table, because that is the review whose findings this set inherits.

| Trigger | Re-read |
|---|---|
| **An Eve design record exists.** It does, as of 2026-09-12: [`../eve/README.md`](../eve/README.md). **This trigger is already true and the re-read is outstanding.** A first pass on 2026-09-12 found two direct conflicts, neither of which either set may settle alone — see the row below | Everything in this set that was judged against an Eve with no design: the exclusion of Eve's verdicts from precision at S3, `agg_eve_latency` becoming computable at S4 and reporting `not_applicable` before, change 10's disposal of the `walle-events` subscription, and every statement in [01-hld.md](01-hld.md) about what Mo deliberately does not consume |
| **Two sets claim the same component.** Both are open as of 2026-09-12 and both need a dated decision record before either set is built | **(a) "Eve v0".** [`../eve/05-stages.md`](../eve/05-stages.md) and [`../eve/01-hld.md`](../eve/01-hld.md) build it at S0 as scheduled queries in **Eve's own project**, pinned to `eve-v0@`, writing `eve.findings`; [05-staging.md](05-staging.md) says T0 **is** that step, in Wall-E's project, pinned to `mo-metrics@`. One query set or two, and whose account pins it, is undecided. **(b) The blind-sample draw.** [`../eve/04-flows.md`](../eve/04-flows.md) flow 7 has `eve-reconciler` draw it daily as `eve-verifier@` from S3 entry, and [`../eve/05-stages.md`](../eve/05-stages.md) starts the review at S1; [§13 of 03-metrics-contract.md](03-metrics-contract.md) has T0 draw it weekly from a CI-published seed nobody chooses, from S3. A draw made by an enforcing identity is choosable by it, which is the property the seed protocol exists to remove |
| Wall-E's [decision 5](../wall-e/09-open-decisions.md) records an absolute pilot-OU account count and expected monthly items per family | Decision **47**, the floor of 35 against a per-cell blind rate of 5 decided items a week, the accumulating promotion window that makes the floor reachable at all, and every S2 and S3 exit criterion that depends on volume. Until it lands, whether any cell can ever reach the floor is unknown rather than assumed |
| Wall-E's [decision 35](../wall-e/09-open-decisions.md), inside [decision 8](../wall-e/09-open-decisions.md), is answered | Decision **44**: the reader set for `walle_metrics`, the minimum reporting cell size of 5, whether any Mo artefact may be synced to Drive, and Mo's entry in the data-protection assessment as a processor |
| The second grader is named | Decision **45**, the `WRITE_HIGH` block at L2, the S2 conflict in [05-staging.md](05-staging.md), change 16, and the weekly human cost line in the cost report — which is where the second grader's hour appears once the person exists |
| The fingerprint-scoping decision is taken, either way | Decision **43**, the scoping rule in [03-metrics-contract.md](03-metrics-contract.md), the dual counts Mo publishes from S2, and whether L4 is reachable at all at the observed change cadence |
| `walle_audit.grades`, `proposal_verdicts`, `drills` or `ladder_events` land, or are refused | Changes **1** and **2**, every `not computable` row that depends on them, and the readiness of every cell. A refusal is not a schedule slip — it removes plan precision, drill freshness, dwell and the ratchet from the design entirely |
| The pinned model is retired, the ADK line has a breaking release, or the Model Armor filter version changes | [C15](../wall-e/14-hld-challenge.md) and decision **43**. Every affected cell's sample resets under strict scoping, and the scorecard should be read before anyone concludes the ladder has stalled |
| The first automatic demotion is later judged a false positive | The ratchet's no-exception rule, the `review_verdict = false_positive` path, the published breaker false-positive rate, and whether Mo's proposal correctly targets the **metric definition** or an Eve finding rather than the ladder |
| `config/metrics/` passes roughly 15 files, or the assertion queries become unmanageable | Decision **50**, the Dataform question, and with it the repository/processing-region match and the service-agent `actAs` relationship that were the reasons to decline it for the pilot |
| Cost exceeds the estimate by a factor, or the S1 stop-or-continue review comes due | [C28](../wall-e/14-hld-challenge.md), the machine estimate of €25–60 a month (`Assumption:`, `tbd` until the first billing cycle), and the human hour a week that decides whether the programme survives. `config/metrics/toil_baseline.csv` must already exist by then; its denominator cannot be reconstructed afterwards |
| Anyone builds an Agent Runtime reasoning engine for Mo | The rejection of the second project and the reasoning engine, and the obligations that bind unchanged the moment an engine exists — the immutable `identity_type=AGENT_IDENTITY` choice at creation time and the `discoveryengine.serviceAgent` blast radius. Both were recorded rather than pre-empted, and neither is optional afterwards |
| Mo is ever put behind Agent Gateway | The egress hostnames that must then be registered — `bigquery.googleapis.com`, `aiplatform.googleapis.com` and their regional and mTLS variants. Mo v1 is not behind a gateway; its egress control is the absence of any HTTP tool in T0 and a two-entry allowlist in T1 |

## Related

- [README.md](README.md) — the index and the one-sentence claim
- [01-hld.md](01-hld.md) — what was cut and why, which is the other half of this page
- [05-staging.md](05-staging.md) — the stage each gate above lands in
- [06-failure-modes.md](06-failure-modes.md) — what happens while these stay open
- [`../wall-e/09-open-decisions.md`](../wall-e/09-open-decisions.md) — decisions 1–41
- [`../eve/09-open-decisions.md`](../eve/09-open-decisions.md) — Eve's E-1 to E-20
- [`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md) — the challenge whose findings these rows inherit
