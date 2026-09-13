# 5. Stages and gates

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13

## What the staging is for

Eve acquires its two authorities on opposite schedules, because they point in opposite
directions. **Halting and demoting can only ever make less happen**, so Eve gets them the
moment it is a program at all, at S3 entry. **Signing can make more happen**, so Eve gets
the key only at S4 entry, after a twelve-fault exercise it must pass at 100 %. Everything
between those two points is deliberate: the stage a control arrives in is an argument, not
a convenience.

Before S3 entry, "Eve v0" is ten BigQuery scheduled queries pinned to their own service
account and read by a human, and nothing else exists — no robot account, no OAuth client,
no token, no secret, no KMS key, no allowlist entry, no process. That is the whole point of
the staging: **the pilot carries no dormant credential, no unused key and no allowlist
entry** for a consumer that does not yet exist.

Stage names, floors and levels are Wall-E's, from
[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §7. Eve does not define
its own stages; it declares what exists inside each of Wall-E's, and what it is trusted
with there. Wall-E's floors are S0 3–4 weeks, S1 4–6, S2 6–8, S3 6–8, S4 8–12, S5 ongoing.

## The stage table

| Stage | What exists | What Eve is trusted with |
|---|---|---|
| **S0 — Eyes** | Eve's GCP project (`EVE_PROJECT`, created under `FOLDER_ID` per [../project-topology.md](../project-topology.md)); `eve-v0@` with two dataset grants — `WRITER` on `eve`, made by Eve, and dataset-level `READER` on `walle_audit` in `WALLE_PROJECT`, made by Wall-E's runbook; the `eve` dataset; ten scheduled queries plus reconciliation and drift, pinned to that account, scheduled off the hour; the daily `walle_audit` mirror; one Cloud Monitoring absence alert on the metric series. In Wall-E's code: the eight endpoint contracts, `contracts/plan-body.v1.json`, the envelope schema, the `approvals` columns, the pinned-PEM verification path with a CI-only test key, the reason-code validator, the three sweeper/stamp mechanisms (inert), and a CI-only stub caller with denial tests 4, 5, 6 and 52. `thresholds.yaml` numbers stubbed. **Deliberately absent:** `eve@<domain>`, the OAuth client, the token, the secrets, the KMS key, the allowlist entry, `run.invoker`, `datastore.viewer`, `agentregistry.viewer`, any Pub/Sub subscription, and any Eve process. | **Nothing.** Eve v0 is queries a human reads. Daily write budget is 0; there is no autonomous write to gate or verify. |
| **S1 — Hands held** | Unchanged, now with real rows. **The blind sampled human review starts here**, at `max(10 %, 5 items/week)`, graded without sight of any machine verdict, written write-ahead to `walle_audit.grades`. It must exist before Eve does: it is the thing that will later grade Eve, and the only bound on the compromised-Eve risk. | **Nothing.** An audit gap is a human's finding. At ten human-approved writes a day a machine halt would add latency, not safety. |
| **S2 — Proposals** | **Eve's organisation-level admin-log sink into Eve's project is created here**, early, so the first enforcing window has history. Eve v0 gains the Google-side contract drift check against a committed privilege- and event-name snapshot. Reconciliation has now run ~10 weeks against real writes and its false-positive rate is measured — the numbers that will become halt thresholds are calibrated here, on data, before anything is wired to them. **Scheduled F2 sits at L3 here, not L4** — CC-32 in [08-contract-changes.md](08-contract-changes.md), because L4 means an Eve signature and Eve has no key for two more stages. | **Nothing.** This is the last stage at which that is true. |
| **S3 entry — Eve onboarding** | The step [decision 36](../wall-e/09-open-decisions.md) opens, in one sitting: `eve@<domain>` with role, hardware key, Trusted client, consented token (minus `apps.licensing`) and regional secrets in Eve's project; `eve-controller@`, `eve-verifier@`, `eve-console@`; the cross-project grants — in `WALLE_PROJECT`, made by Wall-E's runbook: `run.invoker` on `walle-actions` (three identities), dataset-level `READER` on `walle_audit` (the two runtime identities), the two project-level read roles of E-12 (pending topology decisions 43 and 44), and `CONTROL_CALLER_ALLOWLIST` with the cross-project emails `${SA_EVE},${SA_EVE_VERIFIER},${OPERATORS}`; in `EVE_PROJECT`, made by Eve: `CI_DEPLOYER`'s `objectCreator` on the `ladder/` prefix; the locked evidence bucket; the CI ladder-artefact publisher; `eve/config` and its external validator; `eve-reconciler`, `eve-console` and their schedules; the twelve seeded-fault fixtures. [Decision 18](../wall-e/09-open-decisions.md)'s control-plane split lands with this step. **Still absent:** the KMS key, the signer role, `eve-gate`, any cell with `eve_authority: binding`. | **Halting and demoting, immediately and for real** — the safe direction, which can only make less happen. Also verifying, reconciling, drift detection, and the daily operator-list reconciliation. Its verdicts on plans are observe-mode: logged, graded blind, enforcing nothing. Halt and demote are **live for the invariant class only**; rate-based triggers stay observe-only until their thresholds are calibrated. |
| **S3 — Batch approval** | As at S3 entry, running ≥ 30 days against L3 batch executions. | Halt and demote. **Not approval.** Exit gate: **100 % catch** of the twelve seeded invariant-class faults, plus both negative controls not firing. Agreement with human verdicts is reported for information only — a 95 % agreement rate is not a gate for a deterministic checker. |
| **S4 entry — Eve gates** | Adds, and only now: the `eve` key ring and `eve-approval` with its first PEM exported **before first use** and committed under CODEOWNERS; Data Access logging on `AsymmetricSign` and IAP; `eve-gate` and its 2-minute schedule; signature verification, the per-item vector and `eve_authority` in `walle-actions`; the `verdict_receipts` read; the blind sample wired as the only input to L4/L5 precision. **Scheduled F2 reaches L4 here** and not before, which makes it the first autonomous write in the programme (CC-32). | **Signing an approval** — but only for cells whose ladder entry explicitly sets `eve_authority: binding`, which is a pull request with two distinct authenticated approving reviewers, neither the author. Absent reads as advisory, and an Eve signature for an advisory cell is refused with `eve_authority_advisory`. That one field is the per-cell load-bearing switch, the fail-closed default, and the demotion target when an approval is overturned. |
| **S5 — Steady state** | No new Eve component. F5 reaches L4 with a two-hour hold, so the **two-phase envelope** applies: `envelope_gate` at freeze opens the hold window, `envelope_release` re-verified against freshly re-read pre-state with a 15-minute TTL is required at release. More cells carry `eve_authority: binding`. Annual manual key rotation with a 30-day overlap, each new PEM exported at creation. | The same two authorities on more cells. `WRITE_HIGH` never reaches L5 on any trigger at any stage, so Eve's post-hoc path only ever covers reversible `WRITE_LOW` and `READ`, and pre-approval is permanently the `WRITE_HIGH` mechanism. |

## S0 — Eyes

Eve v0 is a body of SQL a human reads. Ten scheduled queries compute the ten
[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §8 metrics on a 30-day
rolling window, hourly, each result carrying its measured value, its threshold, its verdict
and the hash of the query that produced it, with **Wilson interval bounds rather than point
estimates**. Those ten include hard-invariant denials (with the T0-human
`protected_principal` exclusion) and audit completeness. Two more queries are Eve v0's own:
two-direction reconciliation, and config and ladder drift — twelve transfer configs in all,
listed in [07-build-runbook.md](07-build-runbook.md) Phase 4. Results land in
`eve.findings`. A human reads them weekly — about 30 minutes.

Two operational facts shape how those queries are created, both verified 2026-09-12:

- Scheduled queries run in the BigQuery Data Transfer Service and **by default use the
  credentials of the user who created them**; a service account is set with
  `--service_account_name`. Every Eve transfer config is created with an explicit
  `--service_account_name=eve-v0@<eve-project>`, and CI asserts it. An evidence series that
  runs as the person who administers Wall-E is not independent, and dies when they leave.
  ([Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries))
- "Scheduled queries running exactly on the hour (for example, 09:00) might trigger
  multiple times, which can cause unintended results like data duplication from `INSERT`
  operations." Every Eve query is therefore scheduled **off the hour**. The minimum
  duration between scheduled queries is 5 minutes. (same source)

### Deliberately absent at S0

This list is the design, not an omission. Nothing here exists until S3 entry:

| Absent at S0 | Why |
|---|---|
| `eve@<domain>`, the Workspace robot | A standing tenant-wide admin read credential with no consumer. See the consent timing section below. |
| The separate Trusted Desktop OAuth client | Minted in the same sitting as the consent, not before. |
| The consented refresh token and `EVE_TOKEN_VERSION` | Google expires a refresh token unused for six months. |
| The two regional secrets, `eve-oauth-client` and `eve-refresh-token` | There is nothing to store. |
| The `eve-approval` KMS key and `roles/cloudkms.signer` | A signing key that gates nothing is an asset an attacker can reach and a key version that ages inside the evidence horizon. |
| The `CONTROL_CALLER_ALLOWLIST` entry for Eve | An allowlisted principal with no process behind it. |
| `roles/run.invoker` on `walle-actions` | Nothing to invoke. |
| Any project-level role in `WALLE_PROJECT` — at S0 and at every later stage. `agentregistry.viewer` is dropped (topology decision 43); `datastore.viewer` is not granted, and Eve's Firestore discovery read exists only once decision 44 names a resource-scoped form (an IAM Condition on the database, or the CC-33 list endpoint) | No Eve process reads Firestore or the registry, and none may reach them through a project-level role. |
| Any Pub/Sub subscription on `walle-events` | Declined outright at every stage — see [01-hld.md](01-hld.md) and [09-open-decisions.md](09-open-decisions.md) E-20. |
| Any Eve process — job, service or console | S0 has no autonomous write to gate or verify. |

What **does** exist at S0 on Wall-E's side is code, not infrastructure: the eight endpoint
contracts of [../wall-e/08-team-eve-mo.md](../wall-e/08-team-eve-mo.md),
`contracts/plan-body.v1.json`, the envelope schema, the `approvals` columns, the pinned-PEM
verification path exercised with a CI-only test key, the reason-code validator, the three
sweeper and stamp mechanisms in an inert state, and a CI-only stub caller standing in for
`eve-controller@` that exercises all eight interfaces and proves denial tests 4, 5, 6 and
52 — including Eve refused 403 on `POST /v1/execute` and an operator token accepted on
halt. This is exactly what [decision 36](../wall-e/09-open-decisions.md) leaves at Stage 0:
seams in code, nothing provisioned.

There is **no fault-injection or test-mode path reachable in a deployed Eve or Wall-E
image**, at any stage. The stub caller exists in the test suite only, and a CI import test
asserts it is absent from any admitted image.

## S1 — Hands held

Eve is still nothing but queries, now reading real rows. One thing starts here and it is
not Eve: **the blind sampled human review**, at `max(10 %, 5 items/week)` of executing
items, graded without sight of any machine verdict, written write-ahead to
`walle_audit.grades`.

It starts two stages before Eve exists on purpose. It is the thing that will later grade
Eve, and it is the only bound on the compromised-Eve risk — a bound that must already be
running, with a habit and a rota behind it, before the component it bounds is built.
[C16](../wall-e/14-hld-challenge.md) placed it at S1 for that reason, and it is the only
input to precision at L4 and L5.

The rate is `max(10 %, 5 items/week)` everywhere except one cell: **F7 at L4 takes 20 %**,
because Eve cannot read licence state at all and its F7 verdicts are `verified_partial`
with reason `licence_event_only` ([06-failure-modes.md](06-failure-modes.md)). A vetoed
item enters the pool at the next draw regardless of rate.

Eve is trusted with nothing at S1. An audit gap is a human's finding. At ten
human-approved writes a day a machine halt would add latency, not safety.

## S2 — Proposals

Two things happen here, both early on purpose.

**Eve's own organisation-level admin-log sink is created.** `eve-workspace-audit`,
org-level, `--include-children`, `--use-partitioned-tables`, filter
`protoPayload.serviceName="admin.googleapis.com"`, **no actor exclusion**, routed to
`eve_workspace_logs` in Eve's project. Verified
2026-09-12: an aggregated organisation-level sink may route to a destination in another
project — "When the destination is a Google Cloud project, the project can be in any
organization" — and its writer identity must be granted `roles/bigquery.dataEditor` on that
BigQuery dataset
([Aggregated sinks](https://docs.cloud.google.com/logging/docs/export/aggregated_sinks)).
Creating it at S2 rather than at S3 entry means Eve's **first enforcing window has months
of history rather than zero rows**. It also moves Eve's evidence out of Wall-E's teardown
blast radius: Eve reconciles against this copy, never against `walle_workspace_logs` in
Wall-E's project. Org-level sink creation needs org-level permission, so the runbook allows
calendar time for that approval — see [07-build-runbook.md](07-build-runbook.md).

Two flags on that command are the difference between a usable copy and a mess nobody
notices for months, and both are once-only. `--use-partitioned-tables` gives one
`cloudaudit_googleapis_com_activity` table; without it Logging writes a date-sharded series
`..._YYYYMMDD`, because "The default selection is a date-sharded table" ([Route logs to
BigQuery](https://docs.cloud.google.com/logging/docs/export/bigquery), verified 2026-09-12).
And `bq update --default_partition_expiration` must be set on the dataset **before** the
sink first writes, because it sets the lifetime "for partitions in newly created
partitioned tables" ([Updating
datasets](https://docs.cloud.google.com/bigquery/docs/updating-datasets), verified
2026-09-12) — miss it and Eve's org-wide admin-log copy has no retention bound at all.
Neither is retrofittable to rows already written, which is the same non-backfill property
as the actor exclusion.

**The thresholds are calibrated.** By the end of S2 reconciliation has run roughly ten
weeks against real writes and its false-positive rate is measured. Every number that will
later trip a halt or a demotion is set here, on data, before anything is wired to it —
[09-open-decisions.md](09-open-decisions.md) E-18. `thresholds.yaml`'s numbers are stubbed
from S0 so that Eve v0 and the later controller read the same values from the same file;
S2 replaces the stubs with measurements.

Eve v0 also gains the Google-side contract drift check at S2, against a committed snapshot
of privilege names and admin event names, so a change on Google's side is a finding rather
than a silent reconciliation gap.

**And one thing has to move out of S2 for that to be true.**
[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §7 puts scheduled **F2 at
L4 in S2**, and calls it "the first autonomous write in the whole programme". §2 of the same
page defines L4 as the level at which "Eve approves with **its own signing key**". Eve has no
key at S2, no signer role and no `eve-gate` — by this design's own ordering, and by
[07-build-runbook.md](07-build-runbook.md) Phase 11's precondition that the key is not built
until the S3 exit gate has passed at 100 %. An F2 plan at L4 in S2 would therefore sit at
`pending_eve` until `walle-actions`' `eve_silence` sweeper sets `no_autonomous` four business
hours later, every time.

The resolution is **CC-32** in [08-contract-changes.md](08-contract-changes.md): scheduled F2
is **L3 at S2 and S3** and rises to **L4 at S4 entry**, with the rest of the Eve-gated set.
The phrase "the first autonomous write in the whole programme" moves to S4 with it. Only
humans raise a level, so the level that moves is the one written down, not the date Eve gets
a key. This is the joint **C26/C27** residual in
[../wall-e/14-hld-challenge.md](../wall-e/14-hld-challenge.md), which found the same
contradiction, recorded that it "belongs to nobody today", and assigned the fix to
[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md).

Two consequences worth naming rather than leaving to be discovered:

- **S2's exit criterion is weaker than it reads.** "Zero drift on the F2 notifications
  actually executed" now has *human-approved* L3 notifications as its subject, not autonomous
  ones. It is still a real criterion — the notification path, its templating and its
  config-fixed recipients are all exercised — but it is no longer evidence that an
  unattended write behaves, because at S2 there is no unattended write.
- **CI refuses the L4 config from the first commit, not from S4.** CC-6's validator already
  "refuses any config placing a cell at L4 while its authority is advisory", and no cell
  carries `eve_authority: binding` before S4 by construction. Pulling that one existing rule
  forward to the first commit makes an S2 F2-at-L4 config fail the build rather than strand a
  plan at runtime. No new rule is added for this.

S2 is the last stage at which Eve is trusted with nothing.

## Why the Workspace credential is minted at S3 entry, not at Stage 0

The runbook as written provisions Eve's robot account, its custom role, its hardening, its
Trusted OAuth client, its consented refresh token and its regional secret in Phase 15, at
Stage 0. This design moves all of it into the **Eve onboarding** step at S3 entry. Two
reasons, and neither of them is the cost of repeating the consent:

1. **The six-month unused-token expiry.** Google lists "The refresh token has not been used
   for six months" among the reasons a refresh token stops working
   ([OAuth 2.0](https://developers.google.com/identity/protocols/oauth2), re-verified
   2026-09-12). Wall-E's own stage floors for S0–S2 total 13–18 weeks, which is under six
   months — so a Stage-0 token dies only if the stages overrun, or if Eve's design and
   build lag S3 entry. Both are plausible for a one-person team. The alternative, refreshing
   the token monthly from a status command, keeps a **tenant-wide admin read credential warm
   for a consumer that does not exist**, which is the wrong trade.
2. **The scope freeze.** Scopes are frozen at the moment of consent. Consenting at Stage 0
   freezes a scope list drafted before the verifier was designed. Consenting at S3 entry
   freezes the list this design actually needs — and in particular drops `apps.licensing`
   per [C13](../wall-e/14-hld-challenge.md), which a Stage-0 consent would have carried for
   months. The cost of that drop is a permanent, declared limit on independence for F7,
   recorded in [06-failure-modes.md](06-failure-modes.md) and carried in every F7
   attestation.

The same argument moves the KMS key and the allowlist entry out of Stage 0, and it is what
[decision 36](../wall-e/09-open-decisions.md) and [C14](../wall-e/14-hld-challenge.md)
settle. The seams stay in code from the first commit; only the provisioning moves.

**Contingency.** Eve's whole credential chapter is contingent on
[decision 26](../wall-e/09-open-decisions.md) — whether a keyless service account may hold a
custom admin role with no domain-wide delegation. If it may, then Eve's robot user, its
consent, its hardware key, its refresh token and the six-month clock all disappear, and the
onboarding step shrinks accordingly. Re-examine before onboarding rather than building the
chapter as specified ([09-open-decisions.md](09-open-decisions.md) E-16). There is no
domain-wide delegation in either variant.

## S3 entry — what Eve is trusted with, and the observe-mode split

At S3 entry Eve becomes a program: two runtime identities, a reconciler job on four
schedules, a console behind IAP, an evidence bucket with a locked retention policy, a
config repository with an external validator, and its own Workspace read credential. It
still has **no key and no gate**.

The `eve.review_queue_blind` view lands with the console, and it must exist **before the S3
exit gate**, not before S4: it is what the grader reads, and the gate is argued from grades
taken through it. The `verdict_receipts` view (in the receipts dataset, separate from `eve` —
topology decision 48) is the opposite case — it is created at S4 entry
and not before, because nothing reads it until `walle-actions` does
([03-lld.md](03-lld.md) section 9).

Two statements in the inherited set cannot both hold literally. Wall-E's ladder puts Eve in
observe mode through Stage 3; the contract also requires Eve to fail closed in every
direction. Taken together they would forbid the only component watching Google's audit log
from acting on what it sees, for the whole stage in which the programme is trying to prove
itself. The split, recorded as [09-open-decisions.md](09-open-decisions.md) E-6:

| Authority | At S3 entry | Why |
|---|---|---|
| **Signing an approval** | Observe-only, through the whole of S3. Eve's verdicts are logged and graded blind and enforce nothing. | Signing can make more happen. It waits for the S3 exit gate. |
| **Halt and demote on the invariant class** | **Live, immediately and for real.** | Halting can only make less happen, and a human undoes it in seconds with one authenticated call. |
| **Halt and demote on rate-based triggers** | Observe-only until the thresholds are calibrated. | A rate threshold set from a guess would fire on noise. Calibration happened at S2; the wiring happens when the numbers are trusted. |
| **Verification, reconciliation, drift, the daily operator-list reconciliation** | Live. | These produce findings, not effects. |

The cost of this reading is named rather than narrowed away: **a buggy Eve can halt the
programme during the stage the programme is trying to prove itself in.** That is accepted
because the reverse — an Eve that watches a hard-invariant violation go past because it is
in observe mode — is worse, and because halting is the direction a human can undo in
seconds. What is *not* accepted is discretionary halting: halt is reserved for the closed
invariant-trigger list and is never a judgement call. At the approval point the conservative
act is **refuse**, which costs an operator an approval; see
[06-failure-modes.md](06-failure-modes.md).

## The S3 exit gate: twelve seeded faults and two negative controls

The gate is **100 % catch of the twelve seeded invariant-class faults, with both negative
controls not firing**. Nothing less passes: a deterministic checker that misses one of
twelve constructed invariant violations is not a deterministic checker.

**How the faults are injected.** By serving Eve doctored plans and doctored log rows from a
harness, against a **separate sandbox deployment and a separate dataset** — never through a
test-mode path in an admitted image, which is separately banned and checked by a CI import
test. Where that sandbox lives is [09-open-decisions.md](09-open-decisions.md) E-15: a
sandbox deployment against a sandbox dataset is the fallback, and if
[decision 29](../wall-e/09-open-decisions.md) yields an identity-only sandbox tenant the
exercise moves there and this gate becomes meaningfully stronger. A synthetic fixture set
tests Eve against plans someone constructed; it cannot surprise Eve the way a tenant can.

| # | Fault | Required verdict |
|---|---|---|
| 1 | Plan body altered after hashing | `plan_hash_mismatch` |
| 2 | `pre_state` contradicted by Workspace | `pre_state_mismatch` |
| 3 | Plan claims L4 for a cell the ladder puts at L2 | `level_overclaim` |
| 4 | `config_version` not in the artefact store | `config_version_unknown` |
| 5 | `ceilings_sha` ≠ the running service's | `ceilings_sha_mismatch` |
| 6 | Item targets a `walle-protected@` member | `target_protected` |
| 7 | Item targets outside the OU allowlist | `target_out_of_scope` |
| 8 | T2 plan whose trigger has no corroborating row in Eve's own log copy | `trigger_uncorroborated` |
| 9 | Robot admin event with no `walle_audit` row | `audit_row_missing` |
| 10 | `walle_audit` row with no admin event past its lag budget | `admin_event_unmatched` |
| 11 | Firestore level ≠ ladder artefact | `ladder_drift` |
| 12 | `/healthz` fresh over a stale table | `audit_claim_divergence` |
| N1 | Group write verified from current state 20 min after execution, Groups event not yet landed | `verification_deferred_lag` — re-checked, **not** a fault |
| N2 | `protected_principal` denial arising from a human chat request | an ordinary correct refusal; must **not** enter Eve's hard-invariant count |

**An always-approving Eve fails 1–8. An always-refusing Eve fails both negative controls.**
That is what the two negative controls are for: without them, the cheapest way to pass a
twelve-fault gate is to refuse everything, and an over-eager Eve would walk through.

**Agreement with human verdicts is reported for information only.** Wall-E's S3 exit
criteria currently read "Eve observed ≥ 30 days, agreed with human verdicts ≥ 95 %, and
caught ≥ 95 % of deliberately seeded faults". [C12](../wall-e/14-hld-challenge.md) raised
the seeded-fault figure to 100 % and made agreement informational — a 95 % agreement rate
is a sensible gate for a model and a meaningless one for a deterministic checker, which
either implements the rule or does not. The ≥ 30 days of observation stands. The wording in
[../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) still says 95 %/95 % at
the time of writing and is on the edit list in
[08-contract-changes.md](08-contract-changes.md).

**One more thing must be true before S3 exit: the second grader.** Without a grader who is
not the ladder owner, the blind sample is blind in form only, and the compromised-Eve bound
is weaker than this design claims. Name one under
[decision 11](../wall-e/09-open-decisions.md) by S3, not S4 — and no `WRITE_HIGH` cell
reaches `eve_authority: binding` without them
([09-open-decisions.md](09-open-decisions.md) E-13).

## S4 entry — controls first

Wall-E's ladder names six controls that must be live before S4. Read through this design
they resolve as follows; each is a build step in [07-build-runbook.md](07-build-runbook.md)
and a mechanism in [02-identity-and-auth.md](02-identity-and-auth.md) or
[03-lld.md](03-lld.md).

| Control required before S4 | What it is in this design |
|---|---|
| Eve's approval key, readable only by `eve-controller@` | Key ring `eve`, key `eve-approval`, `ASYMMETRIC_SIGN` / `EC_SIGN_P256_SHA256`, **in Eve's project**. `roles/cloudkms.signer` to `eve-controller@` only; `eve-verifier@` holds everything `eve-controller@` holds *except* the signer role. `walle-actions@<WALLE_PROJECT>` holds `roles/cloudkms.publicKeyViewer` on that one key in `EVE_PROJECT` — key-level, cross-project, fallback only — and nothing more; never `signerVerifier` or `cryptoOperator`, both of which carry `useToSign`. Data Access audit logging on `AsymmetricSign`. |
| Signature verification | **Offline pinned-PEM verification in `walle-actions` as the primary path**, KMS `getPublicKey` as fallback. Each key version's PEM is exported at creation, **before first use**, to `gs://<eve-project>-eve-evidence/keys/` — the `keys/` prefix of the **locked** evidence bucket, not a bucket of its own — **and** committed to `contracts/eve-public-keys/<version>.pem` in Wall-E's repository under `ladder.yaml`'s CODEOWNERS. No IAM grant inside Wall-E's project can substitute a key; a KMS outage does not stop verification; a destroyed key version never orphans a stored approval. |
| Hold window and veto surface | The hold window is Wall-E's; Eve's side is `POST .../veto` when a threshold fires after signing, and the operator veto surface in `eve-console`. A veto wins unconditionally, and the vetoed item enters the blind sample pool at the next draw regardless of rate. |
| **Eve-unreachable degrades to waiting, never to executing**, tested | Plans sit at `pending_eve` and never fall through. `walle-actions`' own `eve_silence` sweeper sets `no_autonomous` after four business hours; the `eve_evidence_stale` sweeper freezes promotions at 60 minutes and drops the cell to L4 at four hours; the `eve_last_seen` absence alert pages at 15 minutes. **Eve returning clears nothing** — only an operator clears `no_autonomous`. Tested as a denial-suite case, not asserted. |
| Eve's independent read credential | Already live since S3 entry in this design, which is a change from the inherited ordering: the credential arrives a stage earlier than the key, because reconciliation needs it and signing does not. |
| Post-hoc verification SLA measured | Measured through S3 in observe mode, against the primary-evidence split: current state proves the write inside 60 minutes, the audit event proves attribution on a slower per-application clock. Lag alone is never reported as `unverifiable`. |

S4 entry adds, and only now: the key ring and key with its first PEM exported before first
use; Data Access logging on `AsymmetricSign` and on IAP; `eve-gate` and its 2-minute
schedule; signature verification, the per-item accept/reject vector and `eve_authority` in
`walle-actions`; the `verdict_receipts` read from the receipts dataset; and the blind sample wired as the only
input to L4 and L5 precision.

It is also where **scheduled F2 arrives at L4**, moved here from S2 by CC-32, which makes the
templated notification the programme's first autonomous write at the stage where something
can actually approve it. F2 is the cheapest possible first L4 cell — a templated message to a
config-fixed recipient — and that is the argument for it going first, not for it going early.

**`eve_authority` is the switch.** An Eve signature binds only for a cell whose ladder entry
explicitly sets `eve_authority: binding` — a pull request with two distinct authenticated
approving reviewers, neither the author. Absent reads as advisory; a signature for an
advisory cell is refused with `eve_authority_advisory`. The same field is the demotion
target when an Eve approval is later overturned, and the CI validator refuses any config
placing a cell at L4 while its authority is advisory
([09-open-decisions.md](09-open-decisions.md) E-4).

## S4 exit criteria

Wall-E's criteria, with what each means for Eve and where the number comes from:

| Criterion | Reading |
|---|---|
| ≥ 100 Eve-gated executions, human vetoes ≤ 1 %, zero drift | Counted from `walle_audit` and reconciled against Eve's own copy of Google's log. A veto is also a precision signal: every vetoed item enters the blind sample pool. |
| **Eve availability ≥ 99 % in business hours** | Defined here, because nothing in the inherited set defines it and Cloud Run's SLA is not a proof of it: **the fraction of scheduled business-hour passes that completed**, computed by `walle-actions` from the passively stamped `eve_last_seen`, and **never self-reported by Eve** ([09-open-decisions.md](09-open-decisions.md) E-10). `eve_last_seen` is stamped from any successfully authenticated `eve-controller@` or `eve-verifier@` call — there is no endpoint Eve can call to assert its own health, and a liveness signal Eve publishes could not prove Eve is alive in any case. |
| Eve verdicts still agreeing with a sampled human review ≥ 98 % | The sample is the blind one running since S1, drawn from `eve.review_queue_blind`, whose verdict and reason columns are absent **by construction** rather than hidden by the console. Blindness for refusals is structural — Eve's verdicts never enter Wall-E's project; blindness for accepts rests on an allowlisted column set and a CI test. |
| Zero severity-1 or severity-2 events | An Eve approval later overturned is severity 2 by Wall-E's own table, so this criterion is also the measure of Eve being wrong in the approving direction. |
| A rollback drill passed at this level | Monthly from S5, and once at this level before exit: Eve proposes, a human executes. |
| Decision record, two humans plus **Eve's attestation** | The attestation is a dated, deterministic, KMS-signed bundle in `eve.attestations` and the evidence bucket, under domain tag `eve-attestation/1`, carrying every exit criterion with its measured value, window and query hash, the observed decision-file approvers, and every named limit on Eve's independence applying to that cell. **A promotion cites one URL.** |

Two standing rules apply to every one of these numbers. Metrics are reported as **Wilson
interval bounds, not point estimates**, so a promotion is not argued from a lucky window.
And no exit criterion Eve measures about itself may be self-reported: availability comes
from Wall-E's passive stamp, precision comes from the human blind sample, and neither is a
number Eve computes about its own work.

## S5 — steady state

No new Eve component is built at S5. What changes is rhythm and reach.

| | |
|---|---|
| **Reach** | More cells carry `eve_authority: binding`, each by its own pull request with two reviewers. F5 reaches L4 with a two-hour hold. `WRITE_HIGH` **never reaches L5** on any trigger at any stage, so Eve's post-hoc path only ever covers reversible `WRITE_LOW` and `READ`, and pre-approval is permanently the `WRITE_HIGH` mechanism. |
| **The two-phase envelope** | Because F5's hold is two hours, a single envelope signed at freeze would authorise a write against a pre-state read two hours earlier. So: `envelope_gate` at freeze opens the hold window, and `envelope_release` — re-verified against freshly re-read pre-state, with a 15-minute TTL — is required at release. Any hold beyond 30 minutes uses this shape; see [03-lld.md](03-lld.md). |
| **Monthly** | A K0 drill issued from Eve, timed into `drills/{date}`. A rollback drill in which Eve proposes and a human executes. |
| **Quarterly** | The threshold review: every number in `thresholds.yaml` re-argued against the window that has passed, as a reviewed and versioned change, never a quiet one. |
| **Annually and on suspicion** | Key rotation. Verified 2026-09-12: Cloud KMS does **not** support automatic rotation for asymmetric signing keys, so rotation is a **dated manual procedure** with a 30-day overlap, each new PEM exported at creation to both places — `gs://<eve-project>-eve-evidence/keys/` and `contracts/eve-public-keys/<version>.pem` under CODEOWNERS. Old versions are **disabled, never destroyed** inside the 400-day evidence horizon ([Key rotation](https://docs.cloud.google.com/kms/docs/key-rotation)). |
| **Weekly, and this is the one that must stay true** | Under half an hour of human time: the blind sample at `max(10 %, 5 items/week)`, five to fifteen items, roughly 20 minutes, plus the digest. If Eve costs more than that in steady state it will be ignored rather than used, which is a worse outcome than not building it. |

## What the staging does not promise

**L3 with human approval is a legitimate permanent end state.** Nothing in this table
obliges the programme to reach S4. Eve's signing half — the key, the gate, the envelope, the
second predicate implementation — should not be built until an L3→L4 promotion can state in
numbers how much approval burden it avoids. The halting half is worth building at S3 entry
regardless, because it is the only thing watching Google's log.

**The stage boundaries are Wall-E's, and Eve does not move them.** If a stage exit fails,
Eve's answer is that the stage continues; there is no path in this design by which Eve
raises anything, shortens a dwell, or clears a halt. Only humans raise a level, and above
L3 it takes two of them.

## Related

- [README.md](README.md) — index and reading order
- [01-hld.md](01-hld.md) — what Eve is, the components, the deterministic boundary
- [02-identity-and-auth.md](02-identity-and-auth.md) — the principals, the credential and the key
- [03-lld.md](03-lld.md) — the five recomputations and the envelope
- [04-flows.md](04-flows.md) — the seven flows, including the blind sample draw
- [06-failure-modes.md](06-failure-modes.md) — what happens when each part of this is wrong
- [07-build-runbook.md](07-build-runbook.md) — the ordered steps that bring each stage into existence
- [08-contract-changes.md](08-contract-changes.md) — the edits this design forces on Wall-E's set
- [09-open-decisions.md](09-open-decisions.md) — E-4, E-6, E-10, E-13, E-15, E-16, E-18, E-20
- [../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) — the six stages, the levels, the metrics
- [../wall-e/08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) — the contract
- [../wall-e/09-open-decisions.md](../wall-e/09-open-decisions.md) — decisions 11, 18, 26, 29, 36
- [../wall-e/14-hld-challenge.md](../wall-e/14-hld-challenge.md) — C12, C13, C14, C16
