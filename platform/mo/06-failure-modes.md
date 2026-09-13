# 6. Failure modes

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13

This page states what happens when each part of Mo is wrong, absent or hostile, and what
this design does **not** close. It is the page a security reviewer should read first, and
the page to argue with.

Two properties carry the weight, and both are structural rather than behavioural.

**Mo's absence is strictly more restrictive than its presence.** Nothing rises when Mo
stops, and nothing that demotes, halts or refuses depends on Mo running. That is the mirror
of the requirement [08](../wall-e/08-team-eve-mo.md) item 7 puts on Eve — "Eve must never be
a thing whose absence lets more happen" — applied to the one member of the team that has no
enforcement duty at all.

**Every number Mo publishes is re-derivable from `walle_audit`, and the gate re-derives it
rather than believing it.** A compromised or hallucinating Mo can write a persuasive
paragraph; it cannot produce a false number that survives CI. That single property is what
licenses a model in Mo at all, and it is why most of the rows below end in "and nothing
moves" rather than in a compensating control.

Read with [03-metrics-contract.md](03-metrics-contract.md) for the arithmetic these rows
protect, [02-identity-and-access.md](02-identity-and-access.md) for the grants each threat
row assumes, and [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) for the
proposal path the compromise rows attack.

---

## 1. The fail-closed argument, in both directions

Fail-closed is usually stated once and left. It is stated here twice, because the two
directions rest on different mechanisms and only one of them is Mo's own.

### Direction 1 — when Mo stops, nothing rises

| What stops | Why nothing rises |
|---|---|
| The scheduled queries (T0) stop, or fail their assertion queries | No scorecard row is written, so no cell can be cited as `ready`. A failed assertion pages and **freezes promotions** in its own right |
| The `mo-reporter` job (T1) fails | No proposal bundle is assembled, so no promotion pull request is opened at all |
| Either stops silently | The validator refuses **every** promotion whose metrics watermark is older than **24 hours**. A promotion argued from stale evidence is refused for staleness, not merged on the last good number |
| The scorecard is stale but present | Every window carries `max_ts_seen` per source and the freshness bounds in [03-metrics-contract.md](03-metrics-contract.md) §Freshness set `stale_evidence`, which makes the cell `not_ready` before the validator is even reached |
| `platform/wall-e/ladder-state.md` stops being regenerated | It goes stale and **says so** — it carries the watermark, so a reader sees a date rather than a plausible-looking matrix |

Detection is a Cloud Monitoring **absence** condition on the `walle_metrics` watermark, a
policy and channel in `MO_PROJECT`,
written with `EVALUATION_MISSING_DATA_ACTIVE`, because a threshold-only policy is silent
exactly when the metric stops being written ([Alerting policies in
depth](https://docs.cloud.google.com/monitoring/alerts/concepts-indepth), verified
2026-09-12). The alert never depends on Mo publishing its own liveness signal, and it never
demotes anything. It is change 14 in [08-open-decisions.md](08-open-decisions.md): Wall-E's
SETUP Phase 16 and [06](../wall-e/06-security-guardrails.md) Monitoring record where the
alert lives and subscribe Wall-E's on-call channel; they do not create it.

### Direction 2 — when Mo stops, nothing else degrades

Nothing in Wall-E's enforcement path reads anything Mo writes. Every [05](../wall-e/05-autonomy-ladder.md)
§8 breach that demotes, halts or freezes is enforced by a component that has never heard of
`walle_metrics`:

| Enforcement | Who does it | Reads `walle_metrics`? |
|---|---|---|
| Breakers, budgets, caps, consecutive-failure demotion | The action service, from its own durable counters | No |
| Refusal at the approval point, halts on the closed invariant list, post-hoc demotion | Eve, from `walle_audit` and Workspace state | No |
| The [05](../wall-e/05-autonomy-ladder.md) §10 merge gates — dwell, ceiling, second approver, drill freshness, decision-file link | CI, from `ladder.yaml` and the repository | No |
| The §9 severity responses — halt writes at severity 1, family to L0 at severity 2, one level down at severity 3 | The action service and Eve | No |
| Ladder deploy, `ceilings_sha` match | The deploy tool | No |

This is asserted as a mechanism, not as a claim: **no identity in Wall-E's enforcement path
holds any binding in `MO_PROJECT`** — not the action service, not the dispatcher, not the
ladder deploy tool (all homed in `WALLE_PROJECT`), not Eve (`EVE_PROJECT`), not the CI gate
validator (the custodian's project) — `MO_PROJECT`'s IAM policy and its four datasets' access
lists name none of them, and that is tested as a row in the denial suite that now checks both
the 403 and the policy (change 15 in [08-open-decisions.md](08-open-decisions.md), authored in
[07-build-runbook.md](07-build-runbook.md) as MD-9 and MD-9b). It is also the only mechanism behind open
decision 42, which asks whether `mo-metrics@` may write anything at all: the reading this
design takes is that **no byte Mo writes is read by anything that enforces**, and the denial
row is what makes that true rather than argued.

The consequence, stated plainly: a total Mo outage costs the programme its ability to
*promote* and its weekly visibility. It costs nothing in safety, and it removes no brake.

---

## 2. The failure-mode table

| Scenario | Behaviour |
|---|---|
| **Mo is down** — scheduled queries stop, or the reporter job fails | Nothing rises. No bundle can be assembled, and the validator refuses every promotion whose watermark is older than **24 hours**. Nothing degrades in the other direction: every §8 breach that demotes or halts is enforced by the action service's breakers, by Eve and by CI, none of which read anything Mo writes. `ladder-state.md` goes stale and says so — it carries the watermark. Detection is a Cloud Monitoring **absence** condition (`EVALUATION_MISSING_DATA_ACTIVE`), because a threshold policy is silent exactly when the metric stops being written. **Mo's absence is strictly more restrictive than its presence** |
| **Mo's arithmetic is wrong** | The failure the validator structurally cannot catch, because it re-runs the same committed SQL and inherits the same defect. Four independent controls instead: golden fixtures whose expectations come from [14](../wall-e/14-hld-challenge.md) C18's published constants, so the design document is the oracle; the assertion queries, which hold regardless of the arithmetic; the metric SQL sitting under `ladder.yaml`'s reviewers with its own decision record; and the S2 back-test against human judgement. **Residual, stated plainly:** a subtle error in a metric no human has independent intuition for. The two named candidates — the Newcombe interval and the `Europe/Paris` business-day calculation — now carry a fixture each, and the fixtures live at their own path so the oracle cannot travel in the same pull request as the code it tests. The mitigation not taken, because it doubles the build and creates pressure to make the validator agree with Mo, is an independent second implementation |
| **Mo is compromised and opens a plausible but harmful pull request** | Bounded by path and by number. The drop box rejects any diff outside the allowlist before CI sees it, so the ceiling module, the policy chain, the catalogue's risk tiers and the validator are unreachable. Mo holds no git credential, so it cannot push, merge or approve. Numbers are recomputed by an identity Mo cannot reach, so a forged promotion has to be **true** to pass. Two distinct authenticated reviewers, neither the author, at L4 and L5. **Residual:** a truthful-but-tendentious argument that two tired humans rubber-stamp — [06](../wall-e/06-security-guardrails.md)'s accepted risk, now narrowed from "any change" to "a change whose numbers are true" |
| **T2 hallucinates or is compromised** | It writes a persuasive falsehood into a fenced, labelled, advisory block and changes nothing. It cannot alter a number (recomputation), cannot remove a `not_ready` reason (the array is a union; no subtraction path exists), cannot read `walle_audit`, cannot write a bundle, cannot call the action service, and holds no credential. This is the whole reason Mo is the one place a different model costs nothing in safety — and the reason that claim is only true while the three tiers stay separate |
| **Mo is used as a disclosure path for employee data** | `mo-analyst@` and `mo-narrator@` cannot select a person-identifying column: the authorised views do not carry one, and the raw dataset is reachable only by `mo-metrics@`, which runs committed SQL with no egress. Published artefacts are aggregate with a minimum cell size of 5 (`Assumption:`, [decision 35](../wall-e/09-open-decisions.md)). The grading worklist names `run_id#item_index` and family only — opaque ids, which is also what keeps the sample blind. **Mo is nonetheless inside the personal-data perimeter**: T0 reads per-person rows, and Mo belongs in the data-protection assessment as a processor. [ARCHITECTURE](../wall-e/ARCHITECTURE.md) weakness 11's claim that Mo's reads are aggregated per organisational unit is **wrong and should be corrected rather than inherited** |
| **The write-ahead `grades`, `proposal_verdicts` and `drills` tables never land** | Plan precision and drill freshness are uncomputable and four artefacts are blank where it matters. The design does **not** route around it by granting Mo Firestore access. Those rows render `not computable — C46 schema decision outstanding` and no cell is reported ready. A blocking upstream dependency, stated as one |
| **`ladder_events` is never created** | Dwell elapsed, days since last demotion and the ratchet are uncomputable by anything that reads BigQuery, because automatic demotions deliberately write no decision file. The dwell column reads `not computable` and no cell is reported ready. Second blocking prerequisite |
| **The fingerprint changes often** | Scoping to the current fingerprint is correct and brutal: the sample resets, `n` falls below 35, and the scorecard says not ready with the reason `evidence earned under fingerprint X, current Y, n=4`. At a realistic prompt- and model-change cadence this can make L4 unreachable in practice. That is an honest answer rather than a defect, and it forces a decision the set has not taken — Mo publishes **both** the strict count and a proposed material subset (selection hash, `prompt_hash`, `model_id`) so the choice is made on data |
| **The blind sample is quietly throttled, or graders see Eve's verdict** | Achieved coverage against `max(10 %, 5 items/week)` is a first-class metric; a miss sets `sample_coverage_below_floor` and the cell is `not_ready`. Grades with `blind = FALSE` or `saw_eve_verdict = TRUE` are excluded and counted, so unblinding makes a cell less promotable. Sample membership is a hash of stable ids over a seed CI publishes **after the week closes** into an append-only per-week file, so nobody can anticipate or choose the draw; ingestion refuses a bundle citing any other seed, and the validator re-draws it. The residual — whoever runs CI can re-roll a candidate seed before committing one — is R5 in [§5](#5-residuals-unsoftened) |
| **A grader grades their own playbook** | Excluded and counted. For a `WRITE_HIGH` cell the second grade must come from someone other than the playbook `owner:`. An unadjudicated disagreement makes the cell `not_ready` with reason `disagreement_unadjudicated` until the adjudication row lands — blocking, which is stricter than counting the item wrong and does not distort the ratio |
| **An automatic demotion turns out to be a false positive** | The ratchet applies in full, with no exception. The demotion is not silently absorbed: `review_verdict = false_positive` with a named reviewer and a `review_ref`, and a published breaker false-positive rate. When it rises, the finding is about Eve or the metric, and Mo's proposal targets the metric definition, never the ladder |
| **A scheduled query fires twice, or Cloud Scheduler double-triggers the job** | Every metric write is a `MERGE` keyed on `(as_of_hour, cell, fingerprint_sha)`; queries run at :07, not on the hour. The reporter is idempotent on `X-CloudScheduler-ScheduleTime`. `roles/storage.objectCreator` cannot overwrite, so a duplicate bundle **fails** rather than replacing |
| **`walle_audit` is torn down and recreated** | Mo does not solve this — [decision 31](../wall-e/09-open-decisions.md)'s off-project copy does — but Mo makes the loss loud: a window discontinuity is flagged and every cell falls below the floor at once, rather than quietly reporting a short window as if it were full |
| **Nobody reads the digest** | The worklist goes ungraded, `n` never reaches 35, and no cell is promotable. Mo cannot make anyone grade and does not pretend to: grading coverage is a first-class number in the digest **and in the monthly cost report, beside the hours it costs**, so the stop-or-continue review sees that the programme is stalled on human attention rather than on safety |

Two rows in that table are prerequisites rather than failure modes, and one is a decision in
disguise. They are expanded below.

---

## 3. Four rows that need more than a cell

### 3.1 Wrong arithmetic — the failure the gate cannot catch

The validator's recompute check is the strongest control in this design and it has one
structural blind spot: it re-executes **the same committed SQL at the same pinned commit**.
If that SQL computes the wrong thing, the validator computes the wrong thing identically and
agrees. Independence of *execution* is not independence of *definition*.

Four controls stand in for the independent implementation that is not being built:

| Control | What it catches | What it does not catch |
|---|---|---|
| **Golden fixtures** whose expected values are the constants [14](../wall-e/14-hld-challenge.md) C18 published — 30/30 → 0.8865, 35/35 → 0.9011, 39/40 → 0.8712, 52/53 → 0.9006, 18/20 upper → 0.9721, 17/20 upper → 0.9476, 16/20 upper → 0.9193, 15/20 upper → 0.8881 — committed at their **own path**, `config/metrics/fixtures/wilson.sql`, which change 13 treats as a group distinct from `config/metrics/*.sql` so the oracle cannot move in the same pull request as the code it tests | Code drifting from the design, because the design document is the test oracle and CI fails on any difference | An error present in C18's constants themselves |
| **Assertion queries** — `n_decided + n_unsure = n_graded`; precision ∈ [0,1]; no `ready` row with `n_decided < 35`; no `ready` with dwell unsatisfied or a drill older than 30 days; every grade row joins to an action row; a batch approval never contributing more accepts than its per-item vector has entries; no email-shaped string published; no group-by cell with a count of 1–4; **no cell carrying two demotion rows attributable to the same `decided_block_id`** (A9) | Whole classes of wrongness regardless of what the arithmetic computes. A failure pages and freezes promotions | A bound that is correctly formed and wrong |
| The metric SQL living under `ladder.yaml`'s **required reviewers**, with its own decision record, and — per change 13 — never in the same pull request as `ladder.yaml` itself | A metric change smuggled in beside the promotion it enables | A reviewed and agreed mistake |
| The **S2 back-test**: T0 re-run at the commit as of every promotion and demotion humans already decided, with every divergence explained in writing | Arithmetic that disagrees with accumulated human judgement | A cell nobody has judged yet |

**The mitigation not taken.** An independently written second implementation of the gate
arithmetic inside the validator does catch arithmetic error, which re-running the same SQL
cannot. It was rejected for two reasons, the second more important than the first: it
roughly doubles the build, and its characteristic failure — a false block on a legitimate
promotion — creates pressure to make the validator agree with Mo, which destroys the
independence the whole scheme rests on. The residual is carried in [§5](#5-residuals-unsoftened)
rather than engineered away.

### 3.2 The two blocking prerequisites

Neither is Mo's to fix, and Mo does not route around either.

| Prerequisite | Without it | Why routing around it is refused |
|---|---|---|
| Write-ahead `walle_audit.grades`, `proposal_verdicts` and `drills` ([14](../wall-e/14-hld-challenge.md) C46, decided and not landed) | Plan precision and drill freshness are **not computable at all**. Those rows render `not computable — C46 schema decision outstanding`, and no cell is reported ready | The available shortcut is granting Mo Firestore reads. That would put Mo inside the control plane's read surface for a metric's sake, and everything Mo needs is write-ahead in BigQuery by C46's own decision |
| `walle_audit.ladder_events`, one row per effective-level transition | Dwell elapsed, days since last demotion, the five-business-day ratchet, two-demotions-in-90-days, >3-demotions-in-an-hour and the false-positive review are all uncomputable by anything reading BigQuery, because automatic demotions deliberately write no decision file and `config_versions` is not stated to gain a row for them | There is no other source. A scorecard that guessed dwell from `config_versions` would be inventing the one number the §10 gate turns on |

Both are changes 1 and 2 in [08-open-decisions.md](08-open-decisions.md), against
[03](../wall-e/03-lld.md) storage and SETUP Phase 7. The correct behaviour while they are
missing is the one above: say `not computable`, report no cell ready, and let the gap be
visible in every weekly digest until someone builds the tables.

### 3.3 Fingerprint churn may make L4 unreachable, and that is a decision, not a bug

`fingerprint_sha` covers playbook version with selection hash, `prompt_hash`, `model_id`,
catalogue version, ADK version, Model Armor filter version, engine resource, `ceilings_sha`
and `config_version`. Promotion evidence is **scoped to the current fingerprint**, which is
what closes C15's gaming path at the measurement layer rather than only at CI: evidence
earned under a different configuration does not count.

**The demotion denominator is not scoped, and that asymmetry is the safety half of this
row.** Scoped both ways, a fingerprint bump would empty the demotion evidence as well as the
promotion evidence — and `prompt_change` is one of Mo's own eight proposal types, available
from S2, whose whole effect is to bump `prompt_hash`. A cell running at 80 % precision could
then never demote, because `wilson_upper(4, 5) = 0.9637` and `wilson_upper(8, 9) = 0.9801` are
both above the `0.95` threshold. So demotion evidence carries across a fingerprint change and
ages out only by time or by the block rule, and a prompt change serving a cell above L2 needs
a linked decision record and re-runs the canary at its current level or lower
([04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §3.4, C15). A fingerprint
change lowers or holds a level; it never clears accumulated demotion pressure. See
[03-metrics-contract.md](03-metrics-contract.md) §11.2.

Taken strictly, a prompt edit on a Tuesday resets the sample for that cell. At a realistic
change cadence a cell may never hold 35 decided items under one fingerprint, and L4 becomes
unreachable in practice. The design does not soften the rule and does not pretend the
problem away: Mo publishes **both** the strict count and the count under a proposed material
subset (selection hash, `prompt_hash`, `model_id`) from S2, so the choice is argued from
data rather than from frustration. It is open decision 43, due before the first L4 promotion
is argued, and a coarser subset needs its own decision record and the security reviewer,
because it reopens exactly what C15 closed.

### 3.4 A false-positive demotion is reviewed, never absorbed

The ratchet — five business days in Europe/Paris, a root-cause incident note that must exist
in git at the path `ladder_events.incident_ref` names, and a fresh decision record — applies
in full, with **no false-positive exception**. A demotion later judged wrong sets
`review_verdict = false_positive` with a named reviewer and a `review_ref`, and Mo publishes
a breaker false-positive rate.

When that rate rises, the finding is about Eve or about the metric definition, and Mo's pull
request targets the *metric definition* or opens an Eve finding — **never the ladder**. This
is the shape the Eve obligation E35 requires, and it matters because the alternative
(an exception path in the ratchet) converts every argued-about demotion into a negotiation.

The verdict does one thing besides being published: a demotion marked `false_positive` by a
named human with a `review_ref` **leaves the `demotions_90d` count** that sets
`redesign_required` ([03-metrics-contract.md](03-metrics-contract.md) §8). That is not the
exception the ratchet refuses — the hold, the incident note and the fresh decision record all
still apply in full, and the row stays in `ladder_events` forever. It stops the residual
false-demotion rate compounding unattended against a threshold of two, and the published
false-positive rate is the visibility control on anyone reaching for the verdict too often.

---

## 4. Threat model

These rows extend the threat-model table in [06](../wall-e/06-security-guardrails.md) and
are written in its format. They also narrow its existing row, "Mo proposes a harmful change
→ a rubber-stamped pull request": with the drop box and the recompute check in place the
residual is not a rubber-stamped pull request but a rubber-stamped pull request **whose
numbers are true**.

Each row assumes the attacker has full control of the named principal and its workload.

| Threat | Control | Residual risk |
|---|---|---|
| **`mo-metrics@` compromised** — the only identity that reads raw per-person rows | It is the pinned identity of BigQuery scheduled queries, never a human's user credentials. It has no key, no secret, no Cloud Run invoker binding, no Workspace credential, no git credential and **no network egress** — a scheduled query has no HTTP tool and cannot be prompted. Its writes land only in `walle_metrics`, `walle_metrics_archive` and `walle_metrics_private`, which no enforcement identity reads (denial-suite row, change 15). Compromising it means compromising the BigQuery Data Transfer Service configuration, which is itself an IAM-gated, logged change needing `bigquery.transfers.update` and Service Account User on the account. The transfer configs are in `MO_PROJECT`, so **`MO_PROJECT`'s own IAM is part of the confidentiality boundary**: anyone who can impersonate `mo-metrics@` there (`Assumption:` an owner or a `serviceAccountTokenCreator` holder in `MO_PROJECT`) reaches the cross-project read into `WALLE_PROJECT`. So `MO_PROJECT`'s owner set is no wider than `WALLE_PROJECT`'s (topology decision 52), and its IAM changes are audited | **Read disclosure of the whole `walle_audit` and `walle_workspace_logs` history**, which is per-person admin activity for the pilot OU. This is the real blast radius of Mo and it is a confidentiality loss, not an integrity one: falsified `walle_metrics` rows still have to survive the validator's recompute against `walle_audit`. Bounded by nothing except the retention floor ([decision 17](../wall-e/09-open-decisions.md)) |
| **`mo-analyst@` compromised** — the reporter job | No read on `walle_audit`; `dataViewer` on `walle_metrics` and the archive only — **never on `walle_metrics_private`**, which holds the surrogate mapping alone and has no reader — so the attacker sees ids, hashes, closed enums, counts, timestamps and **surrogate integers it cannot reverse**, and no free text. The mapping had to move to a fourth dataset because dataset-level `READER` covers every table in the dataset, including any added later (denial test MD-13). `roles/storage.objectCreator` on `walle-mo-proposals` "[a]llows users to create objects. Does not give permission to view, delete, or overwrite objects" ([Cloud Storage IAM roles](https://docs.cloud.google.com/storage/docs/access-control/iam-roles), verified 2026-09-12), so it cannot read back, replace or delete a bundle — and the bucket is in `MO_PROJECT`. A cross-project `run.invoker` on the `walle-actions` service in `WALLE_PROJECT`, admitted by the in-app allowlist entry `mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com`, reaches **`GET /v1/plans/{id}` and `GET /v1/runs/{id}` only**; `/v1/ladder`, `/v1/control/*`, `/approve` and `/veto` have no IAM, no allowlist entry and no code path. No git credential, so it cannot push, merge or approve | An attacker can drop **arbitrary bundles**, each of which must pass drop-box path filtering at ingestion, cite a `scorecard_sha256` `mo-metrics@` actually published, survive the validator's SQL recompute and sample re-draw, and be approved by two distinct authenticated humans. The realistic outcome is noise in the reviewers' queue, plus read access to aggregate metrics and to per-item plan pre-state on the weekly sample |
| **`mo-narrator@` compromised, or the model steered** | `dataViewer` on the **agent-facing authorised-view dataset `walle_metrics_views` only**, plus `aiplatform.user`. Those views are defined in their own dataset over `walle_metrics.scorecard` and registered on `walle_metrics` — **never on `walle_audit`**, because a view executes with its own authorization and `mo-metrics@` can redefine it. Those views expose no `params_redacted`, no `result_summary`, no `content_flags` free text, no display name, no group name, no Google error string and no principal email — so no attacker-writable string reaches the model context at all, and [06](../wall-e/06-security-guardrails.md) N5's canonicalisation requirement is met by there being nothing to canonicalise. Principals on an authorised view "can view the data you share and run queries on it, but they can't access the source dataset directly" ([Authorized views](https://docs.cloud.google.com/bigquery/docs/authorized-views), verified 2026-09-12). No drop-box write, no action-service invoker, no raw read, no credential. Its output is stripped before validation and rendered under a fixed advisory heading; the reason array is a **set union**, so there is a code path to add a `not_ready` reason and none to remove one | A persuasive falsehood in a labelled advisory block that a reviewer believes. It changes no number, no verdict and no level. This is the reason the model tier is safe, and the reason that claim holds **only while the three tiers stay separate** — a future convenience that gives the narrator a raw read or a bundle write voids it |
| **The drop box is compromised, or written to by something other than Mo** | Uniform bucket-level access; object versioning on; a 90-day lifecycle; `objectCreator` for `mo-analyst@` only, which cannot overwrite an existing object. Ingestion rejects any diff outside the path allowlist — `config/ladder.yaml`, `config/playbooks/**`, `config/prompts/**`, `config/catalogue/**`, `platform/wall-e/mo/**`, `platform/wall-e/ladder-state.md` — **before CI runs**, so a bundle touching the ceiling module, the policy chain, the catalogue's risk tiers or the validator dies at ingestion and [05](../wall-e/05-autonomy-ladder.md) §10's "the gate cannot be part of what it gates" is enforced twice. A bundle citing a `scorecard_sha256` that was never published, or a `seed` the append-only per-week seed file does not record for that window, is rejected at the same point. `mo_schema_violation` is counted and any occurrence disables the renderer until a human reviews it | A syntactically valid, path-legal, hash-citing bundle whose diff is a plausible playbook or prompt change — which then still has to survive recompute and two reviewers. The write itself is attributable — but the bucket is in `MO_PROJECT`, so attribution now depends on `MO_PROJECT` enabling Cloud Storage Data Access audit logs (`DATA_WRITE`) itself, a Mo-runbook step (Mo-9), not something inherited from Wall-E's project; bundle objects are versioned. One more named surface: the CI ingestion identity's cross-project read grant on the bucket (`Assumption:` `roles/storage.objectViewer`, identity *tbd*, topology decision 50) — a compromised bot reads bundles, which are proposals, not evidence |
| **The CI bot that opens the pull request is compromised** | The bot is **not Mo** and Mo holds none of its credentials — removing that credential from Mo is the whole reason the drop box exists. The bot authors; it does not approve or merge. The validator's recompute check is a required check owned **outside** the config repository, run by the validator custodian ([decision 37](../wall-e/09-open-decisions.md)) and deployed by image digest. The two-distinct-authenticated-reviewer rule stands above it, and no reviewer may be the author | A compromised bot is an authoring identity with the repository's write scope. The controls that survive it are the ones outside the repository — the external validator and the human reviewers. **If the git host permits administrator bypass of branch protection, this row has no floor**: the two-reviewer rule is decoration. That setting is open decision 48; the validator reports the setting it observes and cannot enforce it |

Two non-rows, stated so they are not looked for: Mo has **no** prompt-injection row of its
own at the T0/T1 tiers, because neither tier can read a free-text string or accept an
instruction from one; and Mo has **no** credential-exfiltration row, because Mo holds no
credential and no secret of any kind — there is no Secret Manager grant on any of the three
service accounts.

---

## 5. Residuals, unsoftened

Five things this design does not close. None of them is mitigated by another control listed
above; each is accepted, and each should be argued with before build rather than after.

**R1 — Mo grades its own arithmetic.** The validator re-executes Mo's SQL and therefore
inherits Mo's mistakes. Golden fixtures, assertion queries, reviewed metric SQL and the S2
back-test cover most of the space. The two metrics for which no human has independent
intuition — the Newcombe difference interval and the `Europe/Paris` business-day ratchet
calculation — now carry a golden fixture each ([03-metrics-contract.md](03-metrics-contract.md)
§5), so they are checked rather than only named; the residual is a subtle error in a metric
that is neither fixtured nor assertable. The fix that would close it,
an independently written second implementation, is not being built, for the reasons in
[§3.1](#31-wrong-arithmetic--the-failure-the-gate-cannot-catch). Nobody should describe the
recompute check as "independent verification of the metrics"; it is independent verification
that the published numbers match what the committed SQL produces.

**R2 — The truthful, tendentious pull request that two tired humans merge.** Every
structural control narrows the attack to this one. The numbers are true, the paths are
legal, the hash is real, the evidence re-executes — and the argument built on top of them is
selective. [06](../wall-e/06-security-guardrails.md) already accepts this risk for any
change; here it is narrowed to a change whose numbers are true, which is better and is not
closure. It rests entirely on two humans reading carefully, and it rests on branch
protection actually binding: with administrator bypass enabled on the git host, R2 degrades
to one human (open decision 48).

**R3 — The shared wrong mental model, which blind sampling cannot detect.** Blind sampling
measures whether graders agree with the plan. It does not measure whether graders are right.
If the playbook author and the graders hold the same wrong idea of what the correct outcome
is — the wrong OU convention, the wrong offboarding sequence, the wrong reading of a policy
— then precision reads near 1.0, agreement is high, Gwet's AC1 is high, the cell promotes,
and the cell is wrong. Every statistic Mo publishes about grading is a **consistency**
statistic; none of them is a correctness statistic, and no increase in sample size fixes
that. The only signals in the platform that are independent of what graders believe are the
`verifications` rows, which compare intended state against Workspace's actual state, and
incidents raised by people outside the programme. `Assumption:` neither is a designed
control against this residual, and the design does not claim one. The honest mitigations are
organisational — rotating who grades, having the second grader for `WRITE_HIGH` cells come
from outside the playbook's ownership (which [03-metrics-contract.md](03-metrics-contract.md)
already requires), and treating the first verification drift on a promoted cell as evidence
about the grading rubric rather than only about the run.

**R4 — Mo reads per-person data.** T0 selects per-person rows from `walle_audit` and
`walle_workspace_logs`. Aggregation and suppression happen *downstream* of that read, in
`walle_metrics` and the authorised views, which is a boundary that protects Mo's readers and
does not change what the pipeline processes. Consequences, all of which have to be written
down rather than inherited:

- [ARCHITECTURE](../wall-e/ARCHITECTURE.md) weakness 11 describes this processing as
  aggregated per organisational unit. That is **false at the pipeline layer** and should be
  corrected, not carried forward into the data-protection assessment (change 11).
- Mo belongs in that assessment as a processor in its own right, and `walle_metrics` has a
  **wider reader set** than `walle_audit`, which is why minimum cell size 5 (`Assumption:`)
  is a mechanism in the assertion queries rather than a promise in prose.
- Until [decision 35](../wall-e/09-open-decisions.md) is answered, readers are
  `walle-operators@` and the ladder owner only, and **no Mo artefact is synced to Drive**
  (open decision 44).

**R5 — Whoever controls the CI job can re-roll the week seed before committing it.** The draw
expression is `FARM_FINGERPRINT`, a keyless public hash, so a candidate seed's resulting
sample membership can be computed offline before anyone decides whether to commit it, and a
discarded candidate leaves no artefact anywhere. What the design does close is everything
downstream: the seed file is append-only and written only by the CI job, so a committed seed is
attributable and a rewrite of an existing week's entry is itself the detectable event; and a
bundle citing any other seed is refused at ingestion before the recompute runs
([04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §3.3). What stays open is the
**first** choice. The remedies that would close it are refused as disproportionate: a
commitment-and-reveal scheme is heavy machinery for a one-administrator pilot, and an Eve
signature over the seed drags the enforcing identity back into authoring the evidence it is
later graded against — the exact property [03-metrics-contract.md](03-metrics-contract.md)
§13.2 spends the protocol to remove. On a one-administrator pilot, nothing separates the
person who runs CI from the person who reviews the bundle, which is why this is recorded as an
audit-trail residual rather than treated as a live adversary path.

---

## 6. How each of these is noticed

Detection is worth its own short list, because several controls above are only as good as
the alert behind them.

| Failure | How it surfaces | Where it is built |
|---|---|---|
| Mo stopped producing | Cloud Monitoring absence condition on the `walle_metrics` watermark, `EVALUATION_MISSING_DATA_ACTIVE` — the policy and its channel live in `MO_PROJECT` | [07-build-runbook.md](07-build-runbook.md) Mo-7; SETUP Phase 16 only records where it is (change 14) |
| An invariant broke | Assertion queries run after every scheduled query; a failure pages **and freezes promotions** | [03-metrics-contract.md](03-metrics-contract.md) |
| A metric is stale rather than absent | `max_ts_seen` per source against the freshness bounds; `stale_evidence` sets the cell `not_ready`; the validator refuses at a 24-hour watermark | [03-metrics-contract.md](03-metrics-contract.md) |
| Mo emitted something outside its schema | `mo_schema_violation` is counted and any occurrence **disables the renderer** until a human reviews it | [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) |
| A bundle was tampered with, or cites evidence that does not exist | Ingestion rejects on the path allowlist and on an unpublished `scorecard_sha256`; the validator refuses on any recompute or re-draw difference | [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) |
| An enforcement identity gained any binding in `MO_PROJECT` | The denial-suite row fails — MD-9 on the read, MD-9b on `MO_PROJECT`'s IAM policy | [07-build-runbook.md](07-build-runbook.md); SETUP §4 (change 15) |
| Mo's own containment claims stopped holding | The denial tests authored from Mo's side: `mo-narrator@` selecting a raw column must fail; `mo-analyst@` reading `walle_audit` must fail; `mo-analyst@` calling `/v1/control/demote` must get 403 | [07-build-runbook.md](07-build-runbook.md) |

Grading coverage is deliberately **not** in that table. It is not an alert; it is a number in
the weekly digest and in the monthly cost report, sitting beside the hours it costs, because
"the programme has stalled on human attention" is a decision for the stop-or-continue review
([decision 38](../wall-e/09-open-decisions.md)) and not an incident.

---

## Related pages

- [README.md](README.md) — the index and the one-paragraph claim
- [01-hld.md](01-hld.md) — the three tiers, the IAM seam and what was deliberately cut
- [02-identity-and-access.md](02-identity-and-access.md) — the exact grants each threat row assumes
- [03-metrics-contract.md](03-metrics-contract.md) — the arithmetic, the fixtures and the assertion queries
- [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) — the bundle contract and the validator's gates
- [05-staging.md](05-staging.md) — what exists when, and Mo's acceptance test
- [07-build-runbook.md](07-build-runbook.md) — the denial tests named above
- [08-open-decisions.md](08-open-decisions.md) — changes 1, 2, 11, 13, 14 and 15, and open decisions 42–48
- [06-security-guardrails.md](../wall-e/06-security-guardrails.md) — the threat-model table these rows extend
- [08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) — the contract, including the team's own failure-mode table
- [06-failure-modes.md](../eve/06-failure-modes.md) — Eve's equivalent page, and the other half of the fail-closed argument
