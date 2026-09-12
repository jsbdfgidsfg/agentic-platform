# 9. Open decisions

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-12

This page lists the twenty decisions Eve's design does **not** settle. Each one is stated
with what it is, why it matters, the recommendation this design makes, and the gate — the
point at which the decision comes due and past which building without an answer means
building something that will have to be unbuilt.

None of them blocks *writing* the design; several block *building* it, and two of them
(**E-1** and **E-16**) are cheap now and expensive
after Eve onboarding, which is a one-sitting step containing an irreversible OAuth consent.

**Numbering.** Decisions in this set are numbered `E-1` to `E-20`. The `E-` prefix exists so
they never collide with Wall-E's decisions 1–41 in
[`../wall-e/09-open-decisions.md`](../wall-e/09-open-decisions.md), nor with the challenge
items `C1`–`C56` in [`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md), nor
with the Eve obligations `E1`–`E88` drawn from Wall-E's set that this design was scored
against. A bare number in this set always means a Wall-E decision; an `E-` number always
means one of the twenty below.

**Where each is recorded.** Two places, and they do different jobs.

1. **The reasoning lives in this set**, on the page named in the last column of the table.
   That page is what has to be edited when the answer lands; the row here is an index, not
   the argument.
2. **The answer lives in [`../../decisions/`](../../decisions/)** as a dated file,
   `YYYY-MM-DD-<title>.md`, carrying its `E-` number in the first line. That directory is
   append-only: a later decision supersedes an earlier one, it never rewrites it. **Nothing
   is in it yet** — no decision in this set and none of Wall-E's forty-one has been written
   down, so both sets start by closing them.

None of these twenty is a decision a program may take. Eve lowers and halts on thresholds;
raising a level, widening a scope, setting a cell to `eve_authority: binding` and answering
any row below are human acts, recorded by hand.

## What comes due when

Gate order, earliest first. Two decisions are due before anything is built, and the two
credential decisions are due before the consent that cannot be undone.

| When | Decisions |
|---|---|
| First commit, inert | **E-5** |
| Before the approve endpoint is built | **E-3**, and the schema half of **E-4** |
| Before Stage 1 | **E-14**; the dataset half of **E-1** |
| S2, on measured data | **E-18** |
| Before Eve onboarding | **E-1**, **E-16** |
| S3 entry | **E-6**, **E-9** |
| Before S3 exit | **E-13**, **E-15** |
| S4 entry | **E-17** |
| Before S4 | **E-2**, **E-4**, **E-11**, **E-19** |
| Before S4 exit | **E-10** |
| With this design record | **E-7**, **E-8**, **E-12** |
| With Mo's design | **E-20** |

## The twenty decisions

| # | Decision | Why | Recommendation | Gate | Recorded in |
|---|---|---|---|---|---|
| **E-1** | **Does Eve get its own GCP project?** All three designs said yes; the runbook fixes `SA_EVE = eve-controller@${PROJECT}`. | While Eve's key lives in Wall-E's project, a project owner can grant themselves `cloudkms.signer` and mint an Eve approval, and the only control is a daily drift row — a detective control on the artefact the whole controller role rests on. The set already requires the evidence copy to move at S3 (C11 residual). | **Yes**, extending [decision 18](../wall-e/09-open-decisions.md) and [decision 31](../wall-e/09-open-decisions.md). If the answer is no, the single-project variant still works and pinned-PEM verification still prevents key substitution, but "`walle-actions@` must never mint an Eve approval" reverts to IAM hygiene. | **Before Eve onboarding**; the dataset half before Stage 1 | [01-hld.md](01-hld.md), [02-identity-and-auth.md](02-identity-and-auth.md) |
| **E-2** | **Who owns Eve's project?** | The project boundary is only as real as the org chart. With one administrator it is notional. | Target an `eve-owners@` group containing IT security and not Wall-E's deployers. Build the boundary now, record in writing that it is notional until decision 11's second human exists, and pre-refuse the temptation to fold Eve back into Wall-E's project. | Before S4 | [02-identity-and-auth.md](02-identity-and-auth.md), [06-failure-modes.md](06-failure-modes.md) |
| **E-3** | **`items_hash` in the signed field list.** | C39's list (`plan_id`, `plan_hash`, `config_version`, expiry, nonce, key version) and C16's per-item vector are incompatible: a signature over `plan_hash` alone cannot authorise a subset, so a tamperer could flip an accept bit outside the signature. | Add exactly one field, `items_hash = SHA-256(RFC8785(vector))`, to the signed payload, under `ladder.yaml`'s reviewers. | **Before the approve endpoint is built** | [03-lld.md](03-lld.md), [08-contract-changes.md](08-contract-changes.md) |
| **E-4** | **`eve_authority` as a ladder-cell and override field, and the denial reason `eve_authority_advisory`.** | E58's demotion of Eve's authority has no storage and no enforcement anywhere in the set, and [03](../wall-e/03-lld.md)'s denial vocabulary is declared closed and defined in one place. | One field, `advisory \| binding`, absent reading as advisory; the override may only lower it; the CI validator refuses any config placing a cell at L4 while its authority is advisory. One new non-invariant denial reason. | **Before S4**; the schema before the approve endpoint | [05-stages.md](05-stages.md), [08-contract-changes.md](08-contract-changes.md) |
| **E-5** | **Who owns the "Eve down → `no_autonomous`" timer, and the L5 post-hoc demotion?** | Four documents state the outcome; none assigns it. | Two deterministic sweepers inside `walle-actions`, keying on the **absence** of work (a plan aged at `pending_eve`; a missing verdict receipt), plus a passively stamped `eve_last_seen` metric with an absence alert. No new endpoint, and no code path that raises on Eve's return. Reject a heartbeat endpoint: a liveness signal Eve publishes cannot prove Eve is alive. | **First commit** (inert), wired at S4 | [06-failure-modes.md](06-failure-modes.md), [08-contract-changes.md](08-contract-changes.md) |
| **E-6** | **Eve's observe mode, split.** | E63 says Eve is observe-mode through Stage 3; E53 says Eve must fail closed in every direction. Both cannot hold literally: the only component watching Google's log would be forbidden to act on what it sees. | Split: **signing** is observe-only through S3; **halt and demote on the invariant class** are live from Eve onboarding, with rate-based triggers observe-only until calibrated. Halting is the direction a human can undo in seconds. Record as a reading, with the cost named — a buggy Eve can halt the programme during the stage the programme is trying to prove itself. | **S3 entry** | [05-stages.md](05-stages.md), [06-failure-modes.md](06-failure-modes.md) |
| **E-7** | **Eve's halting bias, restated.** | 08 item 5's "own judgement" is void under C12; "bias toward halting when uncertain" would make a degraded Eve the outage. | At the approval point the conservative act is **refuse** (the plan waits, costing minutes); **halt** is reserved for the closed invariant-trigger list and is never discretionary. Record as an amendment to 08 item 5. | With the design record | [06-failure-modes.md](06-failure-modes.md), [08-contract-changes.md](08-contract-changes.md) |
| **E-8** | **Eve's demotion granularity.** | 05 §6 says Eve may lower "to any level, including halt"; the `demote` contract takes one `(family, trigger)`. | One call per cell, each with its own reason and audit row. A genuinely tenant-wide condition uses `halt`, which is atomic. Name the millisecond-wide seam rather than claiming atomicity that does not exist. | With the design record | [04-flows.md](04-flows.md), [08-contract-changes.md](08-contract-changes.md) |
| **E-9** | **Eve's BigQuery grant, which does not exist anywhere in the runbook.** | The entire shared data plane of [08](../wall-e/08-team-eve-mo.md) is unbuilt for both Eve and Mo. | Dataset-level `bigquery.dataViewer` on `walle_audit` for Eve's identities; `bigquery.jobUser` in **Eve's own** project so job creation and query cost never touch Wall-E's. Never project-level `dataViewer`, which would be a lateral path into Wall-E's project. | S3 entry | [02-identity-and-auth.md](02-identity-and-auth.md), [07-build-runbook.md](07-build-runbook.md) |
| **E-10** | **How is "Eve availability ≥ 99 % in business hours" measured?** | The S4 exit asserts it; nothing in the set defines it, and Cloud Run's SLA is not a proof of it. | The fraction of scheduled business-hour passes that completed, computed by `walle-actions` from the passively stamped `eve_last_seen`, never self-reported by Eve. | Before S4 exit | [05-stages.md](05-stages.md) |
| **E-11** | **The outcome code for an Eve-rejected item.** | The contract says rejected items become `skipped_by_operator`; 03's vocabulary is closed; metrics may need to separate Eve rejections from human ones. | `skipped_by_operator` with `approver_type: eve`, rather than a new state. A one-line edit to 03, made deliberately. | Before S4 | [03-lld.md](03-lld.md), [08-contract-changes.md](08-contract-changes.md) |
| **E-12** | **E18's wording versus E19.** | E18 says Eve's only project-level role in Wall-E's project is `datastore.viewer`; E19 grants `agentregistry.viewer`. Both are read-only and both are in the runbook; the wordings cannot both be literally satisfied. | Reword E18 as "no project-level role beyond the two named read-only roles, and no write role". | With the design record | [02-identity-and-auth.md](02-identity-and-auth.md), [08-contract-changes.md](08-contract-changes.md) |
| **E-13** | **The second grader.** | Without a grader who is not the ladder owner, the blind sample is blind in form only, and the compromised-Eve bound is weaker than stated. Blindness for *refusals* is structural (Eve's verdicts never enter Wall-E's project); for *accepts* it rests on an allowlisted column set and a CI test. | Name one under [decision 11](../wall-e/09-open-decisions.md) by S3, not S4. No `WRITE_HIGH` cell reaches `eve_authority: binding` without them. | Before S3 exit | [04-flows.md](04-flows.md), [06-failure-modes.md](06-failure-modes.md) |
| **E-14** | **Retention floor and ceiling** ([decision 17](../wall-e/09-open-decisions.md), [31](../wall-e/09-open-decisions.md)). | An attestation cites a window; if that window predates the retention floor the citation is unverifiable. The Workspace-side copy ages out at six months regardless. | Answer before Stage 1, as a minimum **and** a maximum. Eve's mirror and bucket are set to 400 days pending it. | Before Stage 1 | [03-lld.md](03-lld.md), [07-build-runbook.md](07-build-runbook.md) |
| **E-15** | **Where the seeded-fault exercise and the K6 rollback drills run** ([decision 29](../wall-e/09-open-decisions.md)). | A synthetic fixture set tests Eve against plans someone constructed; it cannot surprise it the way a tenant can. | A sandbox deployment against a sandbox dataset as the fallback; if decision 29 yields an identity-only tenant, the exercise moves there and the S3 gate becomes meaningfully stronger. | Before S3 exit | [05-stages.md](05-stages.md), [07-build-runbook.md](07-build-runbook.md) |
| **E-16** | **Eve's credential chapter is contingent on [decision 26](../wall-e/09-open-decisions.md).** | If a keyless service account can hold a custom admin role with no DWD, Eve's robot, consent, hardware key, refresh token and six-month clock all disappear. | Re-examine Eve's whole credential chapter before onboarding rather than building it as specified. | Before Eve onboarding | [02-identity-and-auth.md](02-identity-and-auth.md), [07-build-runbook.md](07-build-runbook.md) |
| **E-17** | **`walle-actions` reading Eve's `verdict_receipts`.** | A dependency in the direction the set has otherwise avoided, and a compromised Eve can suppress a demotion by writing false receipts. The alternative — a new POST endpoint for Eve's post-hoc verdicts — would change the 08 contract. | Keep the read, narrowed to an existence-only authorized view exposing `(run_id, item, verdict_ts)`, so the service can never branch on content. Re-argue at S4 entry. | S4 entry | [03-lld.md](03-lld.md), [06-failure-modes.md](06-failure-modes.md) |
| **E-18** | **Threshold numbers.** | Every number in `thresholds.yaml` is a first draft: lag budgets, the disagreement floor, evidence staleness, the page budget. | Calibrate at S2 on measured data before anything is wired to them; version them so tuning is a reviewed change and not a quiet one. Quarterly review thereafter. | S2, then quarterly | [03-lld.md](03-lld.md), [05-stages.md](05-stages.md) |
| **E-19** | **Agent Gateway egress for Eve** (E88's "through its own egress gateway"). | Agent Gateway availability in europe-west1 is unverified, and Gemini Enterprise is supported in egress mode only. | Until confirmed, Eve's egress control is VPC Service Controls plus a host allowlist — `walle-actions`, `admin.googleapis.com`, `cloudkms`, `secretmanager`, `bigquery`, `firestore`, `storage`. `aiplatform.googleapis.com` is deliberately never registered. Reopen when answered. | Before S4 | [02-identity-and-auth.md](02-identity-and-auth.md), [07-build-runbook.md](07-build-runbook.md) |
| **E-20** | **`walle-events` schema.** | Eve declines the topic; C39 nonetheless asks for a schema with `contract_version` and at-least-once semantics keyed on `event_id`. | The schema is the obligation of whoever later asks for the topic — most likely Mo. Record it as not-Eve's rather than leaving it looking like a gap. | With Mo's design | [01-hld.md](01-hld.md), [05-stages.md](05-stages.md) |

Two rows deserve a plain restatement, because they are the ones most likely to be read as
bookkeeping and are not.

- **E-1 and E-2 are one decision split in two.** E-1 buys a structural property: Eve's key
  cannot be reached by a Wall-E project owner, because there is no principal to grant. E-2
  is the observation that the property is only as strong as the group that owns the project,
  and that with one administrator that group is notional. The right response is to build the
  boundary anyway and write down that it is notional, not to skip it: the boundary is cheap
  to build now and expensive to introduce after the key exists.
- **E-13 is the load-bearing one.** The blind human sample is the only bound on the
  compromised-Eve risk and the only check on the design's biggest declared weakness — that
  Eve's second predicate implementation has a second implementation but not a second author.
  Without a grader who is not the ladder owner, several independence claims in
  [06-failure-modes.md](06-failure-modes.md) are weaker than they read.

## Settled by this design — do not reopen without new evidence

These were argued and closed while the design was judged. They are listed so nobody
re-litigates them from a blank page; the reasoning is in
[01-hld.md](01-hld.md).

| Settled | In one line |
|---|---|
| No `POST /v1/control/heartbeat` | It amends a contract described as fixed, and a liveness signal Eve publishes cannot prove Eve is alive. Replaced by the `eve_last_seen` absence shape (**E-5**). |
| No Pub/Sub subscription for Eve, at any stage | A 5-minute poll of the day-partitioned `actions` table meets the only latency-sensitive duty twelvefold, and a topic Wall-E publishes to is a channel Wall-E controls (**E-20**). |
| Cloud Run **jobs**, not a resident `min-instances=1` service | €30–45/month for a component that gates nothing before S4, with a restart as a coverage gap. Verified 2026-09-12: a job task may run up to 168 hours where a service request is capped at 60 minutes — [Cloud Run task timeout](https://docs.cloud.google.com/run/docs/configuring/task-timeout). |
| No model anywhere in Eve v1 or v2 | Required by [C12](../wall-e/14-hld-challenge.md) and [decision 34](../wall-e/09-open-decisions.md), and enforced by dependency absence and permission absence rather than by policy. |
| One field, `eve_authority`, not two | A separate `eve_gate` and `eve_authority` would drift. One field is the observe/enforce switch, the fail-closed default and the demotion target (**E-4**). |
| `eve-advisor` is not built | The slot is named and left empty so it cannot be smuggled in. If it is ever built, adding it is a decision record, not an implementation detail. |

## Re-open on this record

Per E55, the existence of an Eve design record is itself the trigger to re-run nine items of
the 2026-09-11 challenge — every one of which was judged against an Eve that had no design.
The trigger table in
[`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md) names them; this record
fires it.

| Challenge item | What it was | What this design does to it |
|---|---|---|
| **C10** — Eve's `streamQuery` channel can assert any operator's identity | Eve held `aiplatform.reasoningEngines.query` on Wall-E's engine | **Confirms and removes the premise.** Eve holds no `aiplatform.*` permission at all, so there is no Eve `streamQuery` caller. The CI grep stays as a regression guard and finds nothing, which is the correct steady state. The grant's removal from `ARCHITECTURE.md` §4.2 is an edit in [08-contract-changes.md](08-contract-changes.md). |
| **C11** — Eve's trust root is administered from inside Wall-E's project | Refuted at the time on the ground that it belonged to Eve's design and to [decision 18](../wall-e/09-open-decisions.md) | **Changed.** That design now exists and answers it: Eve's project, dataset, secrets, key, evidence bucket and config repository all sit outside Wall-E's project, and Wall-E's deployers hold no IAM in Eve's (**E-1**, **E-2**). The C11 residual — moving Eve's evidence copy out of Wall-E's reach by S3 — is met by the daily `walle_audit` mirror and the locked evidence bucket. |
| **C12** — Eve is drawn as an LLM controller and everything it must do is deterministic | Partially stood | **Confirms.** Every Eve decision is code, enforced five mechanical ways; 08 item 5's "own judgement" is void and replaced by **E-7**'s two rules. |
| **C13** — Eve's "read-only" credential is either blind to licences or can write them | Stood | **Confirms, and accepts the blindness.** `apps.licensing` is dropped; F7 is verified from Google-written licence events and recorded `verified_partial` with reason `licence_event_only`. A declared permanent limit, carried in every F7 attestation. |
| **C14** — Stage 0 provisions Stage 2–5 machinery, including a dormant Eve credential | Stood | **Changed.** The whole Eve credential set moves to a single Eve-onboarding step at S3 entry. The reason is the six-month unused-token expiry and the scope freeze, not the cost of repeating consent. Stage 0 keeps contracts, audit columns and a CI-only stub caller, and nothing else. |
| **C16** — Evidence for replacing the human is inflated at L3 and missing at L4 | Stood | **Changed twice.** The per-item accept/reject vector is signed, via `items_hash` (**E-3**); and the blind human sample moves to **S1**, before Eve exists, because it is the thing that will later grade Eve. |
| **C30** — the `walle-events` topic has no consumer BigQuery does not already serve | Stood | **Changed: declined outright.** Eve takes no subscription at any stage. The schema obligation moves to whoever later asks for the topic (**E-20**). |
| **C34** — nothing requires the higher levels to be worth their cost | Stood | **Confirms, and states the stop rule plainly.** L3 with human approval is a legitimate permanent end state, and none of Eve should be built until an L3→L4 promotion can state in numbers how much approval burden it avoids. |
| **C39** — the contract fixed for later teams is not precise enough to build against | Stood | **Changed.** The signed field list gains exactly one field, `items_hash` (**E-3**); the canonicalisation, hash algorithm, domain tag and full key-version resource name are pinned in [03-lld.md](03-lld.md); and Eve's row in the contract loses "subscribe". |

Five of the nine are changed by this design — C11, C14, C16, C30 and C39 — and each change
appears as a row in [08-contract-changes.md](08-contract-changes.md) with its file, its edit
and its gate. The other four are confirmed rather than altered.

## What Eve depends on in Wall-E's decisions

Ten of Wall-E's forty-one are load-bearing for Eve. None of them is Eve's to answer, and
each one changes something concrete here if it goes the other way.

| Wall-E decision | What Eve needs from it | If it goes the other way |
|---|---|---|
| [**5** — which OUs, and is a sandbox OU possible](../wall-e/09-open-decisions.md) | The OU allowlist that `target_out_of_scope` is evaluated against, and somewhere safe to point seeded fault 7 | With the allowlist still `tbd`, one of the twelve S3 exit faults cannot be constructed and the scope refusal has nothing to compare against. Without a sandbox OU, **E-15** falls back to a sandbox dataset alone. |
| [**11** — who else is an operator, and who is the second approver](../wall-e/09-open-decisions.md) | The second grader for the blind sample (**E-13**); `walle-operators@` membership, which is the whole of `eve-console`'s IAP audience; the second human behind **E-2**'s `eve-owners@` | With one administrator the blind sample is blind in form only, and Eve's independence from the ladder owner — as opposed to from Wall-E — does not exist. This is named limit 5 in [06-failure-modes.md](06-failure-modes.md), not a caveat. |
| [**14** — approval and notification surface](../wall-e/09-open-decisions.md) | A surface that emits a **signed human assertion Eve can verify independently** | Without it, human attribution for T0 chat requests rests on `walle_audit`, written by the component under audit — Google's log proves the robot acted, never who asked. IAP and KMS Data Access logs recover the L3 and L4 cases; the chat case stays unrecovered permanently. Named limit 2. |
| [**17** — audit retention](../wall-e/09-open-decisions.md) | A retention floor **and** ceiling, so an attestation's cited window is inside the horizon (**E-14**) | Eve's mirror and locked bucket stand at 400 days pending the answer. A floor below an attestation's window makes that attestation unverifiable; a ceiling below 400 days conflicts with the locked retention policy, which cannot be shortened once locked. |
| [**18** — split the control plane onto its own service](../wall-e/09-open-decisions.md) | The control-plane split, which lands with the Eve-onboarding step, and the argument **E-1** extends | Without it, `run.invoker` stays per-service rather than per-path and the in-app allowlist plus Eve's asymmetric key is the whole boundary — the minimum the decision already names. |
| [**26** — keyless service account holding the custom admin role](../wall-e/09-open-decisions.md) | The premise under Eve's entire credential chapter (**E-16**) | If a keyless service account can hold a customer-scoped read-only admin role with no domain-wide delegation, then `eve@<domain>`, its Workspace licence, its hardware key, the separate Trusted Desktop OAuth client, the consented refresh token, the two regional secrets and the six-month clock all disappear. Re-examine before onboarding rather than build and discard. |
| [**29** — where a change to the gate first executes](../wall-e/09-open-decisions.md) | Somewhere real to run the seeded-fault exercise and the K6 rollback drills (**E-15**); and, in its strongest form, the independent plan feed that would close named limit 1 | A synthetic fixture set tests Eve against plans someone constructed. If decision 29 yields an identity-only sandbox tenant, the S3 gate becomes meaningfully stronger. The "shows Eve plan A, executes plan B" case stays bounded at one batch detected in under half an hour, and should be reopened before any `WRITE_HIGH` cell goes to L4. |
| [**31** — evidence durability and retention](../wall-e/09-open-decisions.md) | The off-project evidence copy, which is the dataset half of **E-1** and the C11 residual | Without it Eve reconciles against tables inside Wall-E's teardown blast radius, and deleting `walle_workspace_logs` in Wall-E's project would silently make the audit-completeness metric perfect. |
| [**33** — promotion and demotion statistics](../wall-e/09-open-decisions.md) | Wilson interval gates with hysteresis, and the sample floor of ≥ 35 paired observations | Eve's own automatic demotion — the false-refusal rate, Wilson 95 % lower bound above 0.05 per cell over a 30-day window — is built on the same statistics, and `eve.findings` reports Wilson interval bounds rather than point estimates. Point thresholds on 20–30 items would make Eve's demotions as unreliable as the promotions decision 33 exists to fix. |
| [**37** — second pair of hands during the build](../wall-e/09-open-decisions.md) | The two required reviewers on `eve/config` — the ladder owner and a security reviewer — and the custodian of the external CI validator | With one reviewer, the same human can write `thresholds.yaml`, approve the pull request that sets a cell to `eve_authority: binding`, and grade the blind sample. That is named limit 5, and it is the assumption under every independence claim in this design. |

## Open questions that are not decisions

Four facts are unverified as of 2026-09-12 and must stay marked so. None of them blocks
Eve; all four change something if answered.

| Unverified | What it changes |
|---|---|
| Agent Gateway availability in `europe-west1` | **E-19**. Until it is confirmed, Eve's egress control is VPC Service Controls plus a host allowlist. |
| Whether group-management privileges honour OU scoping | Whether Workspace itself contains a group write, or only Wall-E's code does — which sets how much the OU allowlist is worth as containment for seeded fault 7. |
| Whether licence privileges are `isOuScopable` | F7's ceiling. If the check comes back negative, the honest recommendation is that F7 stays at L3 and never reaches an Eve-gated level at all. |
| Agent Runtime and Sessions unit prices | Nothing in Eve's own cost line — Eve runs no engine — but the L3→L4 benefit test of C34 that decides whether Eve is built. |

## Related pages

- [README.md](README.md) — the set index and reading order.
- [01-hld.md](01-hld.md) — the five structural choices and what the design does not close.
- [05-stages.md](05-stages.md) — the gates these decisions are dated against.
- [06-failure-modes.md](06-failure-modes.md) — the five named limits on Eve's independence.
- [08-contract-changes.md](08-contract-changes.md) — every edit this design forces back on
  Wall-E's set, with its own gate.
- [`../wall-e/09-open-decisions.md`](../wall-e/09-open-decisions.md) — Wall-E's forty-one.
- [`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md) — the 2026-09-11
  challenge, whose decisions bind this design.
