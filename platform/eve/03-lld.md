# 3. The verifier

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-15
- 2026-09-15: §14 gains the super-admin and self-integrity detections the setup procedures
  configure, and [§14.1](#141-scope-from-the-first-run-the-human-super-admins-2026-09-15) the
  scope from the first run (P153–P155).
- 2026-09-13: objective restated for a super-admin Wall-E (P33) — see the platform HLD
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.2, §18 items 12–15; owners
  and gates P143).

This page is the inside of Eve. [01-hld.md](01-hld.md) says what Eve is and is not;
[02-identity-and-auth.md](02-identity-and-auth.md) says which principal holds which key.
This one says how a verdict is produced, byte by byte, what it is made of, where it is
stored, and what a signature over it actually covers.

Everything here is code. No part of this page describes a model, a prompt or a judgement.
That is a requirement, not a style: [C12](../wall-e/14-hld-challenge.md) and
[decision 34](../wall-e/09-open-decisions.md) settle that no language model may produce an
Eve approval or signature, and [01-hld.md](01-hld.md) lists the seven mechanical
enforcements that make it true by construction rather than by discipline.

"Everything here is code" covers the control path this page describes — `eve-gate` and
`eve-reconciler`, every verdict and every row they write. The report-only reporting path,
`eve-advisor`, is outside it, and nothing on this page reads what it writes
([01-hld.md §3](01-hld.md#3-deterministic-by-absence-not-by-discipline)).

---

## 1. What a verdict is

A verdict is a pure function of six inputs:

```
decide(plan, prestate, ladder, ceilings, thresholds) -> Verdict
```

| Input | Source | Why this source |
|---|---|---|
| `plan` | `GET /v1/plans/{id}` on `walle-actions` | The only place the frozen plan body exists. Treated as a **claim**, never as evidence |
| `prestate` | Admin SDK Directory API, read with `eve@<domain>`'s own consented token | Evidence. Written by Google, read with a credential `walle-actions@` cannot reach |
| `ladder` | The CI-published ladder artefact in Eve's locked bucket, plus Firestore `ladder/current` and `overrides/{family}/{trigger}` read strongly consistently | Evidence for what the level *should* be; Firestore is compared against it, not trusted over it |
| `ceilings` | `ceilings.py` in `eve/config`, compiled into Eve's image | Eve's own ceiling table, so a plan cannot claim a level the ladder does not grant |
| `thresholds` | `thresholds.yaml` in `eve/config`, version-stamped | Every number Eve acts on is a reviewed row, not a literal in code |
| Rows | BigQuery `walle_audit` (the subject), `eve_workspace_logs` (the evidence), `eve.walle_audit_mirror` | Reconciliation and trigger corroboration |

Three properties hold over that function, and each is tested in CI:

- **Typed in, typed out.** `decide` takes and returns typed structs. No free text crosses
  the boundary. Eve may emit only a reason code drawn from `reasons.yaml`, and a verdict
  carrying an unknown code is rejected before signing.
- **Deterministic.** Every verdict row carries the hashes of its inputs and a
  `replay_bundle` id. A golden-replay test recomputes archived verdicts offline and
  requires bit-identical output; a non-deterministic verdict fails the build (section 11).
- **Unreachable from a model.** `sign_envelope()` is reachable from exactly one function,
  `verdict_for_plan()`, enforced by a CI call-graph test. Eve's image lockfile is scanned
  against a denylist of model SDKs, and neither Eve identity holds any `aiplatform.*`
  permission. Detail in [01-hld.md](01-hld.md).

## 2. The pre-approval pass, end to end

`eve-gate` is a Cloud Run job on a 2-minute Cloud Scheduler trigger, running as
`eve-controller@<eve-project>` — the only identity that holds `roles/cloudkms.signer` on
`eve-approval`. It discovers work by polling Firestore `plans/{id}` for `state ==
pending_eve`. There is no topic, no push subscription and no inbound endpoint; Eve is a
client everywhere.

```mermaid
sequenceDiagram
    autonumber
    participant SCH as Cloud Scheduler
    participant GATE as eve-gate
    participant FS as "Firestore, WALLE_PROJECT"
    participant ACT as walle-actions
    participant WS as Admin SDK as eve robot
    participant EVD as Ladder artefact and ceiling table
    participant KMS as Cloud KMS eve-approval

    SCH->>GATE: run job every 2 minutes
    GATE->>FS: discover plans at pending_eve (grant absent; decision 44)
    FS-->>GATE: plan ids, hold window, epochs
    GATE->>FS: read control mode and overrides strongly consistently
    GATE->>ACT: GET /v1/plans/{id}
    ACT-->>GATE: frozen plan body as a claim
    GATE->>GATE: recompute plan hash over RFC 8785 JCS and discard the reported one
    GATE->>WS: re-read every target with Eve's own credential
    WS-->>GATE: current state as evidence
    GATE->>EVD: read ladder artefact for config_version
    EVD-->>GATE: levels, ceilings_sha, playbook caps
    GATE->>GATE: re-derive the effective level from artefact, compiled ceilings, playbook cap, override
    GATE->>GATE: run Eve's second implementation of the typed predicate
    GATE->>GATE: corroborate the trigger, protected and scope checks, caps, rollback, expiry
    GATE->>ACT: GET /v1/plans/{id} again immediately before signing
    ACT-->>GATE: body re-fetched
    GATE->>GATE: assert the recomputed hash has not moved
    GATE->>KMS: AsymmetricSign over the envelope digest
    KMS-->>GATE: DER signature with no key version in it
    GATE->>ACT: POST /v1/plans/{id}/approve with envelope, vector and key version
    GATE->>FS: nothing written, Eve holds no write path
```

The re-fetch at steps 14 to 16 is not belt and braces. Between the first read and the
signature, Eve does a dozen network round trips against Workspace and BigQuery; the plan
body is fetched from the service under audit; and the signature is what authorises
execution. Re-fetching and asserting the hash has not moved bounds the window in which a
substitution can survive to the few hundred milliseconds between the assertion and the
`AsymmetricSign` call.

If any step is inconclusive rather than contradicted, the item is **refused**, not halted —
the bias stated in [01-hld.md §4](01-hld.md#4-two-authorities-on-opposite-schedules) and
[06-failure-modes.md](06-failure-modes.md), recorded as E-7 in
[09-open-decisions.md](09-open-decisions.md) as an amendment to item 5 of
[../wall-e/08-team-eve-mo.md](../wall-e/08-team-eve-mo.md).

## 3. The five recomputations

Eve treats everything `walle-actions` says as a claim. Five values are recomputed from
sources Wall-E cannot write. A lie must be consistent across all five, and across the three
further comparisons in section 4, to survive to a signature.

One naming note, because two orderings of the same eight checks appear in this set.
[01-hld.md](01-hld.md)'s thesis names the five as the plan hash, the per-item pre-state,
the effective level, the trigger's corroboration and the typed predicate; this page counts
`ceilings_sha` as the fourth recomputation and carries trigger corroboration in section 4
with the other pre-approval comparisons. The checks are the same eight and the reason codes
are the same; only the grouping differs, and the grouping here follows the order of the
pass in section 2.

### 3.1 The plan hash

The frozen plan body is serialised with **RFC 8785 JSON Canonicalization Scheme** and
hashed with **SHA-256**, by Eve, from the body it received. The `plan_hash` the service
reported is read only to be compared and is otherwise discarded — it is never the value
signed. This is the canonicalisation [C39](../wall-e/14-hld-challenge.md) requires to be
defined before the approve endpoint is built, and it is defined here and in
[../wall-e/03-lld.md](../wall-e/03-lld.md) as the same algorithm, under the same required
reviewers as `ladder.yaml`.

Mismatch → `plan_hash_mismatch`, refuse.

Frozen plans live in a Firestore collection where the action service can create but not
update ([../wall-e/03-lld.md](../wall-e/03-lld.md)), so a signed plan cannot be rewritten
between signature and execution. The residual case — a service that shows Eve plan A and
executes plan B — is not closed by any recomputation and is bounded post hoc; see
[06-failure-modes.md](06-failure-modes.md).

### 3.2 The per-item pre-state

Every target named in the plan is re-read through the Admin SDK Directory API with
`eve@<domain>`'s own token: `users.get`, `groups`, `members.list`, `orgunits`,
`roles.list`. Current state is used, not the audit log, because current state is available
immediately where an event may be hours late; [04-flows.md](04-flows.md) carries the
per-application lag budgets.

Contradiction → `pre_state_mismatch`, refuse and raise a ticket. Unreadable →
`eve_read_failed`, refuse. Eve never halts on uncertainty about a single plan.

### 3.3 The effective level, re-derived independently

This is the recomputation that catches a lying **policy chain** rather than a lying plan
body. Eve evaluates the effective-level expression of
[../wall-e/03-lld.md](../wall-e/03-lld.md#the-autonomy-config) — the minimum of the code
ceiling, the ladder level, the playbook cap and the live, demote-only override — with its own
implementation, from four inputs none of which is the plan's own claim:

| Term | Eve's source |
|---|---|
| `ceiling[risk_tier][trigger]` | `ceilings.py`, Eve's **own** compiled ceiling table in `eve/config`, built independently from the same specification |
| `config.families[f].levels[t]` | The CI-published ladder artefact at `gs://<eve-project>-eve-evidence/ladder/<config_version>.yaml`, written append-only by Wall-E's CI identity into Eve's locked bucket |
| `playbook.level` | The playbook cap carried in the plan body, capped again by the artefact |
| `override[f][t]` | Firestore `overrides/{family}/{trigger}`, read strongly consistently, with `override_epoch` and `halt_epoch` stamped into the verdict |

Recomputing the hash and re-reading pre-state catches a lying plan body. Neither catches a
plan that claims L4 for a cell the ladder puts at L2. Reading the ladder from an artefact
Wall-E's deployers cannot rewrite, and compiling the ceiling table separately, is what makes
that claim checkable. If the plan's declared effective level exceeds Eve's re-derivation →
`level_overclaim`, refuse.

If `config_version` is not present in the artefact store at all → `config_version_unknown`,
refuse. Eve needs no git credential for any of this.

### 3.4 `ceilings_sha`

The running service publishes `ceilings_sha` on `GET /v1/ladder` and stamps it on every
audit row ([../wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §4). Eve
compares three values: the `ceilings_sha` in the plan body, the one on `GET /v1/ladder`,
and the one declared by the ladder artefact for that `config_version`. Any disagreement →
`ceilings_sha_mismatch`, refuse.

The gate cannot be part of what it gates. One pull request in Wall-E's repository could
otherwise move the ladder, the ceiling module and the validator together. Eve's copy of the
ceiling table lives in a different repository, with different required reviewers, validated
by a CI JSON-Schema check owned outside that repository — exactly as `ladder.yaml`'s is.

### 3.5 The typed predicate, implemented a second time

[Decision 32](../wall-e/09-open-decisions.md) replaces the playbook's prose `expects`
string with a typed predicate. Eve implements that predicate a **second time**, from the
same typed specification, in `eve/config/predicates/`, and CI differential-tests the two
implementations against each other over generated cases with no credential in the loop.

This is the single largest line in Eve's build — six of the twenty to twenty-four days at
S3 entry — and it is the one not to cut. Without it, Eve re-running Wall-E's own predicate
code would mean the verification-success metric that unlocks L4 and L5 is measuring itself:
the checker and the checked would share a bug by construction, and the number that gates
the whole ladder would be an identity. The same argument produced the independent ceiling
table in 3.3: Eve compiles its **own** table from the CI-published ladder artefact, because
recomputing the hash and re-reading pre-state catch a lying plan body, and only an
independent level re-derivation catches a lying policy chain. It is also the proportionate
answer to [C52](../wall-e/14-hld-challenge.md)'s finding that nothing in the set has ever run
against a harness, and it is the reason this design was chosen over the alternatives.

Predicate unmet → `predicate_unmet`, refuse.

**The platform's Tier W weakening does not apply to Eve.** The platform HLD §12.4
generalises Eve's shape into a **platform verifier** for Tier W agents whose predicates are
compiled from the same manifest the agent uses, and records that this weakens the "second
implementation" property, accepted for Tier W with four compensations (P79). That weakening
is a Tier W acceptance and does not reach Eve: Tier P and the P-SA singleton keep a dedicated,
hand-written Eve, and the second implementation written from the typed specification and
differentially tested stands unweakened for Wall-E.

**The limit, stated rather than narrowed away.** A second implementation is not a second
author. The differential test catches divergence from Wall-E's version; it does not catch
both being wrong the same way because both were written from the same spec by the same
person. The only real check on that is the blind human sample, which needs a grader who is
not the ladder owner — [decision 11](../wall-e/09-open-decisions.md), carried as E-13 in
[09-open-decisions.md](09-open-decisions.md). All five named limits are in
[06-failure-modes.md](06-failure-modes.md).

## 4. The rest of the pre-approval checks

Three further comparisons run in the same pass, and together with the five recomputations
they account for every pre-approval reason code in section 6.

| Check | What Eve does | Reason code on failure |
|---|---|---|
| Trigger corroboration | For an event-triggered (T2) item, the trigger must be corroborated against Google's own copy — the BigQuery row in `eve_workspace_logs` by `insertId`, or `activities.list` by a unique qualifier. This is what stops Eve co-signing a laundered suspension | `trigger_uncorroborated`, refuse, plus `no_autonomous` for that trigger class |
| Protected and scope | Every target re-checked against `walle-protected@` membership and the committed floor list, and against the family's OU allowlist, from Eve's own reads rather than the plan's assertion | `target_protected`, `target_out_of_scope`, refuse |
| Shape and freshness | Rollback plan present; item count within the cell's `max_objects_per_run`; the plan's hold window not elapsed; Eve's own config not stale against the artefact store | `rollback_absent`, `item_count_over_cap`, `plan_expired`, `eve_config_stale`, refuse |

Two rules bind the last row. Eve **never resumes a plan whose hold window elapsed during an
outage** — it is expired, not waiting. And Eve never approves a cell whose `eve_authority`
is `advisory`; an Eve signature for an advisory cell is refused by `walle-actions` itself
with the denial reason `eve_authority_advisory` (E-4 in
[09-open-decisions.md](09-open-decisions.md), and an edit to
[../wall-e/03-lld.md](../wall-e/03-lld.md)'s closed denial vocabulary listed in
[08-contract-changes.md](08-contract-changes.md)).

## 5. The approval envelope

The envelope is the only privileged artefact Eve produces. It is what a Cloud KMS
`EC_SIGN_P256_SHA256` signature covers, and it is the only thing that can authorise an L4
execution.

### 5.1 Construction

```
message   = domain_tag || 0x00 || RFC8785(envelope)
digest    = SHA-256(message)
signature = AsymmetricSign(key_version, digest)
```

- `domain_tag` is the ASCII string `eve-approval/1`. Attestation bundles use a different
  tag, `eve-attestation/1`, so a signature over one can never be replayed as the other.
- The separating byte is a single **NUL** (`0x00`), which cannot occur in the canonical
  JSON that follows, so tag and body cannot be confused by any choice of tag.
- The body is serialised with RFC 8785 JCS — the same canonicalisation as the plan hash, so
  there is exactly one serialisation rule in this design.
- Cloud KMS `AsymmetricSign` takes either a pre-computed `digest` or raw `data`, and the
  two are mutually exclusive; Eve passes `digest`. The signature returned is **DER-encoded**
  and the response carries optional CRC32C checksums, which Eve verifies before use.
  Verified 2026-09-12:
  [Create and validate signatures](https://docs.cloud.google.com/kms/docs/create-validate-signatures).

### 5.2 The signed field list

| Field | Type | Meaning |
|---|---|---|
| `plan_id` | string | The frozen plan |
| `plan_hash` | hex SHA-256 | **Eve's** hash over RFC 8785 of the plan body, never the reported one |
| `items_hash` | hex SHA-256 | `SHA-256(RFC8785(vector))` over the per-item accept/reject vector |
| `config_version` | string | Wall-E's ladder version the verdict was taken against |
| `eve_config_version` | string | The `eve/config` version — `thresholds.yaml`, `reasons.yaml`, predicates, ceiling table |
| `envelope_kind` | enum | `envelope_gate` or `envelope_release` (section 5.5). Single-phase approvals use `envelope_gate` |
| `issued_at` | RFC 3339 UTC | Checked by `walle-actions` with a ±120-second tolerance |
| `expires_at` | RFC 3339 UTC | Same tolerance. Beyond it the approval is refused as `bad_approval`, never silently accepted and never silently expired |
| `nonce` | string | Consumed once, before the Workspace call, per [../wall-e/03-lld.md](../wall-e/03-lld.md) |
| `eve_key_version` | string | The **full KMS key-version resource name**, `projects/<eve-project>/locations/europe-west1/keyRings/eve/cryptoKeys/eve-approval/cryptoKeyVersions/<n>` |

`plan_id`, `plan_hash`, `config_version`, expiry, nonce and the key version are
[C39](../wall-e/14-hld-challenge.md)'s list. `items_hash` is added by this design, as E-3 in
[09-open-decisions.md](09-open-decisions.md), and it is the field that makes batch approval
buildable at all: [C16](../wall-e/14-hld-challenge.md) requires a per-item accept/reject
vector bound to `plan_hash`, and a signature over `plan_hash` alone cannot authorise a
subset — a tamperer could flip one accept bit entirely outside the signature. Exactly one
field is added, and it goes under `ladder.yaml`'s required reviewers.

`eve_key_version` exists because **Cloud KMS signatures do not identify the key version
used** (verified 2026-09-12, same source as above). That is the root cause
[C48](../wall-e/14-hld-challenge.md) recorded, and the envelope carrying the version itself
is what makes an approval verifiable after a key version is disabled.

`envelope_kind` is this design's naming for the two-phase split; the two values are the ones
named in section 5.5. Its presence in the signed set is what stops a release envelope being
replayed as a gate envelope or the reverse.

### 5.3 The per-item vector

Eve emits a vector, not a verdict: one accept or reject per item, in plan order, with a
reason code on each reject. The vector is bound to the plan through `items_hash` and to the
plan body through `plan_hash`, both inside the signature.

Items Eve rejects become `skipped_by_operator` with `approver_type: eve`, rather than a new
outcome state — [../wall-e/03-lld.md](../wall-e/03-lld.md)'s outcome vocabulary is closed,
and separating Eve rejections from human ones is a column, not a state (E-11 in
[09-open-decisions.md](09-open-decisions.md)).

### 5.4 Verification, offline and pinned

`walle-actions` verifies **offline against a pinned PEM** as the primary path, with Cloud
KMS `GetPublicKey` as fallback only:

- Each key version's PEM is archived at creation, **before first use**, in the locked evidence
  bucket and in Wall-E's repository under `ladder.yaml`'s CODEOWNERS — the archive rule is
  [02-identity-and-auth.md](02-identity-and-auth.md#the-pem-archive-in-two-places-before-first-use).
  `GetPublicKey` returns PEM usable for exactly this offline verification (verified 2026-09-12,
  source above).
- No IAM grant inside Wall-E's project can substitute a key, because the trusted material is
  a committed file under code ownership rather than a live lookup.
- A KMS outage does not stop verification.
- A destroyed or disabled key version never orphans a stored approval: the `approvals` row
  carries `eve_key_version`, and the archived PEM for that version is still on disk.

`walle-actions@<WALLE_PROJECT>` holds `roles/cloudkms.publicKeyViewer` on that one key in
`EVE_PROJECT` — key-level, cross-project, for the fallback path only — and nothing more. That
role carries `cloudkms.cryptoKeyVersions.viewPublicKey` and no signing permission;
`roles/cloudkms.signerVerifier` and `roles/cloudkms.cryptoOperator` both carry
`useToSign` and are therefore forbidden on it (verified 2026-09-12,
[Permissions and roles](https://docs.cloud.google.com/kms/docs/reference/permissions-and-roles)).
The key is not in Wall-E's project at all, which makes that structural rather than a policy
sweep — see [02-identity-and-auth.md](02-identity-and-auth.md).

**The stored signature plus the archived PEM is the only artefact proving `walle-actions`
did not mint the approval itself.** That is why the PEM export is a teardown guard and not a
convenience.

### 5.5 The two-phase envelope, for holds beyond 30 minutes

A single envelope works while the hold window is short: the pre-state Eve read stays
plausibly current for the life of the approval. It stops working at F5's two-hour hold at
S5, where a two-hour-old pre-state read is not evidence of anything.

Where a cell's `hold_minutes` exceeds **30**, the approval is two-phase:

| Phase | When | What it asserts | TTL |
|---|---|---|---|
| `envelope_gate` | At plan freeze | Everything in section 3 against the pre-state as read at freeze. It **opens the hold window** and authorises nothing on its own | The hold window, from `thresholds.yaml`; value *tbd* |
| `envelope_release` | At release | The same checks re-run against **freshly re-read pre-state**, plus the halt, override and epoch state as at release | **15 minutes** |

Execution requires both. A release envelope is refused if its `plan_hash` or `items_hash`
differs from the gate envelope's, if the hold window elapsed, or if any epoch moved between
the two. Cells at 30 minutes or below use a single `envelope_gate` envelope whose expiry
must outlast the hold window; that expiry is a `thresholds.yaml` row and is *tbd*.

This matters most in exactly the case it was written for: a plan whose hold window elapsed
during an Eve outage is expired, and Eve does not resume it. The two-phase shape makes that
a property of the envelope rather than a rule someone has to remember.

## 6. The closed reason vocabulary

`reasons.yaml` in `eve/config` is Eve's vocabulary. It is defined here and nowhere else, and
it does **not** touch [../wall-e/03-lld.md](../wall-e/03-lld.md)'s denial reasons, which
stay Wall-E's. Each code maps to exactly one action in
{`refuse`, `veto`, `demote(to_level)`, `halt(mode)`}. A verdict carrying a code not in this
file is rejected before signing.

| Class | Codes |
|---|---|
| Pre-approval (→ refuse) | `plan_hash_mismatch`, `pre_state_mismatch`, `predicate_unmet`, `level_overclaim`, `config_version_unknown`, `ceilings_sha_mismatch`, `target_protected`, `target_out_of_scope`, `rollback_absent`, `item_count_over_cap`, `trigger_uncorroborated`, `plan_expired`, `eve_read_failed`, `canonicalisation_failed`, `eve_config_stale` |
| Post-hoc | `post_state_mismatch`, `unverified_within_sla`, `audit_row_missing`, `admin_event_unmatched`, `licence_event_only`, `no_audit_stream`, `verification_deferred_lag` (the last two explicitly **not** failures) |
| Control plane (→ demote or halt) | `control_plane_divergence`, `audit_claim_divergence`, `ladder_drift`, `epoch_regression`, `google_contract_drift`, `reconciliation_gap`, `evidence_stalled`, `eve_key_unavailable`, `disagreement_rate`, `false_refusal_rate`, `registry_mismatch`, `no_operator_window` |
| Evidence and roster (→ halt) | `log_pipeline_silent` — evidence silence (heartbeat H-1, Eve's token `invalid_grant`, the witness push missing): `no_autonomous` for every agent Eve verifies and `halt_all` on `walle-actions` and `walle-actions-super`, cleared by one human call, every clear a report about the administrator ([../agentic-platform/07-monitoring-detection-incident-response.md](../agentic-platform/07-monitoring-detection-incident-response.md) §7, P97); `role_assignment_added`, `role_assignment_missing` — the daily roster check in either direction (§14; [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §8.1, P68). `reconciliation_gap` keeps its code and widens to every ingested stream (§14) |
| Detection (→ per rule: `halt_all` on the P-SA lanes and a severity-1 page, or a page or ticket) | The rule ids of the detection catalogue (§14): the tenant-integrity rules mirror the SIEM's `SA-01`…`SA-09` and carry those ids; Eve's own baseline and divergence rules carry ids *tbd* at S2 calibration. Each rule row declares its one action, exactly as a reason code does |

Two codes deserve their reading spelled out. `verification_deferred_lag` is not a fault: it
is the verdict on a write that is confirmed from current state but whose audit event has not
landed yet, and it is one of the two negative controls in the S3 exit gate
([05-stages.md](05-stages.md)). `licence_event_only` is a permanent, declared limit: Eve's
role carries no License Management privilege and `apps.licensing` is dropped per
[C13](../wall-e/14-hld-challenge.md), so F7 is verified from Google-written licence events
and recorded `verified_partial`. `no_audit_stream` is the third: Google Workspace Calendar
has **no Cloud Logging audit stream at all**, so a calendar-family item can never be
attributed from `eve_workspace_logs`. Such an item is recorded `verified_state_only` with
`no_audit_stream` **permanently** — it never upgrades to `verified` and it never escalates
to `reconciliation_gap`, because there is nothing that could land. Like
`licence_event_only`, it is a named, declared limit carried in the attestation, not a gap
to be closed later.

## 7. `thresholds.yaml` and the rule about control calls

**No control-call site exists that is not parameterised by a row of `thresholds.yaml`.**
Every halt, demote, veto and refuse in Eve's code reads its trigger condition from a named
threshold row and emits the reason code that row declares. There is no literal comparison
against a constant anywhere on a control path, and a CI test asserts it by walking the call
sites. `eve_config_version` is stamped on every verdict row, every control call and every
attestation, so a later query can prove which numbers a given decision used.

The shape, with the values this design fixes and the ones it does not:

```yaml
version: "tbd"                      # eve_config_version, stamped everywhere
approval:
  envelope_ttl_minutes: tbd         # single-phase; must outlast the cell's hold window
  release_ttl_minutes: 15           # envelope_release
  clock_tolerance_seconds: 120      # +/- , checked by walle-actions
post_hoc:
  state_sla_minutes: 60             # primary evidence, current state
  deep_pass_hours: 6                # upgrade verified_state_only -> verified
  gap_after_hours: 6                # nothing landed -> reconciliation_gap
  lag_budget_minutes:
    # Every budget here clocks ONE stream: the Admin audit log, where Wall-E's catalogued
    # writes land. The sink carries all six Workspace streams (section 13); these two rows
    # clock the Admin stream for post-hoc verification, and the other streams' budgets are
    # under evidence.reports_poll.
    admin: 15                       # Assumption:
    groups: 15                      # Assumption: same stream, same number as admin.
                                    # Wall-E's F3 group-member writes go through the
                                    # Directory API and are read as GROUP_SETTINGS /
                                    # ADD_GROUP_MEMBER / REMOVE_GROUP_MEMBER under
                                    # applicationName=admin, NOT as Enterprise Groups
                                    # Audit events. The Groups *application's* slower
                                    # lag is not the lag of the stream Eve reads.
    # There is deliberately no `calendar` row. Google Workspace Calendar has no Cloud
    # Logging audit stream at all, so no calendar-family item can ever be attributed
    # from eve_workspace_logs, and a budget against it could never be satisfied.
    # See flow 2 in 04-flows.md for how calendar-family verification is recorded instead.
disagreement:
  window_days: 30
  min_paired_observations: 35
  false_refusal_wilson_lower_bound: 0.05   # exceeded -> cell to eve_authority advisory
sampling:
  blind_rate: "max(10%, 5 items/week)"
  f7_blind_rate: 0.20
paging:
  budget_per_week: tbd
  same_reason_pages_before_ticket: 3
  eve_demotions_per_hour_severity_2: 3
oncall:
  file: oncall.yaml                 # the no-operator window
# ---- super-admin evidence: platform HLD section 13.2 and page 07 sections 7-8 --------
evidence:
  reports_poll:
    actors: [robot, eve_robot, every_super_admin_on_roster]
    lag_budget_minutes:             # per Reports application; Assumption: all tbd, S2
      admin: tbd
      login: tbd
      token: tbd
      saml: tbd
      groups: tbd
      groups_enterprise: tbd
      user_accounts: tbd
      rules: tbd
      context_aware_access: tbd
      gcp: tbd
      drive: tbd
      vault: tbd
      takeout: tbd
      admin_data_action: tbd
      data_studio: tbd
  heartbeat:                        # H-1 and H-4 of page 07 section 7
    workspace_logs_silence_minutes_business_hours: 60
    workspace_logs_silence_minutes_outside_hours: 240
    eve_last_seen_absence_minutes: 15
    witness_push_absence_hours: 26
    on_silence: log_pipeline_silent
reconciliation:
  robot_event_without_audit_row: reconciliation_gap   # every ingested stream; halt
roster:
  cadence: daily
  file: roster                      # committed, signed by the security reviewer; name tbd
reporting:
  severity_1_ack_minutes: {business_hours: 15, outside: 60}   # Assumption:
  severity_2_ack_business_hours: 4                            # Assumption:
  repage_secondary_after: target
  repage_incident_commander_after: 2x_target
  same_reason_pages_per_week_before_ticket: 3                 # RP-6
```

Four notes on those numbers. The lag budgets are `Assumption:` and stay so — what is *not*
an assumption is which stream they clock, and that is the Admin audit log for both rows,
because that is where Wall-E's catalogued writes land, even though the sink carries six
streams. Verified 2026-09-12: only Access
Transparency, Admin Audit, Enterprise Groups Audit, Login Audit, OAuth Token Audit and SAML
Audit export to Cloud Logging, and Calendar is not among them ([Workspace audit
logs](https://docs.cloud.google.com/logging/docs/audit/gsuite-audit-logging)); group-member
adds and removes made through the Directory API are `GROUP_SETTINGS` events under
`applicationName=admin` ([Admin group settings
events](https://developers.google.com/workspace/admin/reports/v1/appendix/activity/admin-group-settings)).
The page budget is *tbd*. And every one of these is a first draft to be **calibrated at S2
on measured data before anything is wired to it**, then reviewed quarterly — E-18 in
[09-open-decisions.md](09-open-decisions.md). Reconciliation will have run about ten weeks
against real writes by then and its false-positive rate will be measured, which is the only
honest way to set a halt threshold.

The `evidence`, `reconciliation`, `roster` and `reporting` rows take their numbers from the platform: the heartbeat windows from
[../agentic-platform/07-monitoring-detection-incident-response.md](../agentic-platform/07-monitoring-detection-incident-response.md)
§7 (P97), the acknowledgement targets and re-page rule from §8–§9 of the same page (RP-5, P99,
both `Assumption:` until the detection-desk contract fixes them), the page rule from RP-6.
The per-application Reports lag budgets are *tbd* and calibrated at S2 like the rest (E-18);
"business hours" is the value already used by `eve_silence`.

The sweeper thresholds — the four business hours before `eve_silence` sets `no_autonomous`, and
the 60 minutes and four hours of `eve_evidence_stale` — belong to `walle-actions`, as specified
in [08-contract-changes.md §3](08-contract-changes.md#3-wall-es-side-of-this-design); Eve's
copy is the reference the two are asserted equal against.

## 8. The data plane

| Surface | Owner | Eve's access | Join key | Notes |
|---|---|---|---|---|
| `walle_audit.{actions,runs,plans,approvals,verifications,config_versions}` | Wall-E, `WALLE_PROJECT` | dataset-level `dataViewer` (`READER`) in `WALLE_PROJECT`, granted by Wall-E's runbook (CC-22) to `eve-v0@`, `eve-controller@`, `eve-verifier@` of `EVE_PROJECT`; jobs run in `EVE_PROJECT` | `run_id`, plus ADK `invocation_id` | Provided by Wall-E's runbook since 2026-09-13. Query jobs run in Eve's project, so no `bigquery.jobUser` is needed in Wall-E's |
| `walle_workspace_logs` | Wall-E, `WALLE_PROJECT` — since 2026-09-13 an authorised view `platform_logs_views.walle_workspace_logs` in `LOGGING_PROJECT` (P104, P107), with `eve-verifier@` holding dataset-level `READER` on `platform_logs_views` there | not used for reconciliation; dataset-level `READER` for `eve-verifier@` **proposed** (topology decision 47), no grant today | — | Superseded by Eve's own sink. The standing check that Wall-E's copy still carries no actor exclusion needs a mechanism: reading the organisation sink's filter would need organisation-level `logging.viewer`, refused. Decision 47's form is a data-level comparison — robot-actor admin events per day in `eve_workspace_logs` against `walle_workspace_logs`, a persistent deficit being the finding — which needs that dataset-level `READER` on `walle_workspace_logs` in `WALLE_PROJECT`, made by Wall-E's runbook. Until it lands the claim is not asserted by Eve |
| `eve_workspace_logs` | Eve | owner | `insertId`, robot actor | Eve's evidence. One DAY-partitioned `cloudaudit_googleapis_com_activity` table, 400-day partition expiry — the sink is created with `--use-partitioned-tables` and the dataset's default partition expiration is set before it, neither of which is the default and neither retrofittable. Since 2026-09-13 the sink carries all six Workspace streams (§13), so the dataset also holds the Data Access table the login, token and SAML entries land in (table name as Logging creates it, *tbd* until the first rows) |
| `eve_workspace_reports` | Eve | owner | `id.uniqueQualifier`, actor, application | The Reports API poll by actor (§13), DAY-partitioned, 400 days |
| `eve_quality` | Eve | owner; authorised views over `eve.*` | `run_id`, incident id | Dataset-level `READER` to `mo-metrics@MO_PROJECT` and the validator custodian, made by Eve's runbook; no free-text columns; never `grades_blind` or `review_queue_blind` (platform HLD §13.3) |
| Authorised-view dataset for the reporting path, and `eve_advice` | Eve | owner | incident id | `eve-advisor@` holds `READER` on the view dataset (name *tbd*) and `dataEditor` on `eve_advice`; **no control-path identity reads `eve_advice`** |
| `grades_eve` | the platform approval surface; **dataset proposed 2026-09-13: `eve_grades` in `VALIDATOR_PROJECT`**, owned by the validator custodian ([09-open-decisions.md](09-open-decisions.md) E-21; [../project-topology.md](../project-topology.md) rows 45–46) | **none** — no Eve identity writes it | `run_id`, item | Grades of Eve's verdicts, written by the approval surface and never by `eve-console`; the blind sample is drawn by the approval surface. The input Mo's Eve quality numbers come from, beside `seeded_fault_runs`, golden replay and `eve_last_seen` (platform HLD §13.3) |
| Witness `eve_mirror` and bucket, `EVE_WITNESS_PROJECT` | the witness administrators | `eve-export@`: `bigquery.dataEditor` on `eve_mirror`, `storage.objectCreator` on the retention-locked bucket | table, `dt` | The daily push; the absence alarm lives there (§14) |
| `eve.*` | Eve | owner | `run_id` | Wall-E's deployers hold no IAM |
| `eve.walle_audit_mirror` | Eve | owner | `run_id` | Daily append-only copy, outside Wall-E's teardown blast radius |
| Firestore (Wall-E) | Wall-E, `WALLE_PROJECT` | **none today.** The project-level `datastore.viewer` of the 2026-09-12 design is not granted by Wall-E's runbook (`EVE_PROJECT_ROLES = ()`, SETUP Phase 6); `eve-gate` has no Firestore read until topology decision 44 lands — `datastore.viewer` under an IAM Condition scoped to the `(default)` database (spike, expression unverified), or `GET /v1/plans?state=pending_eve` on `walle-actions` (CC-33, a contract change). Epochs and drills come through `GET /v1/plans/{id}` and `GET /v1/ladder` meanwhile, as claims | plan id, `(family, trigger)` | Epochs read strongly consistently and stamped into every verdict once the read exists |
| Ladder artefact | Wall-E's CI (`CI_DEPLOYER`, `WALLE_PROJECT`) | `objectViewer`; the writer holds `objectCreator` on the `ladder/` prefix only, a bucket-level cross-project grant made by Eve | `config_version` | Append-only into Eve's bucket |
| Pub/Sub `walle-events` | Wall-E | **none** | — | No Eve subscription at any stage |

The BigQuery grant is E-9 in [09-open-decisions.md](09-open-decisions.md): dataset-level
`bigquery.dataViewer` on `walle_audit` in `WALLE_PROJECT` for Eve's identities of
`EVE_PROJECT`, made by Wall-E's runbook, and `bigquery.jobUser` in **Eve's own** project so
job creation and query cost never touch Wall-E's. Never project-level `dataViewer`, which
would be a lateral path into Wall-E's project. The full cross-project table is
[../project-topology.md](../project-topology.md) §3.

The declined topic is deliberate. The only latency-sensitive duty is L5 post-hoc
verification within 60 minutes, and a 5-minute poll of the day-partitioned `actions` table
meets that twelvefold; a topic Wall-E publishes to is also a channel Wall-E controls. The
`walle-events` schema [C39](../wall-e/14-hld-challenge.md) asks for is the obligation of
whoever later asks for the topic, most likely Mo — E-20.

## 9. The `eve` dataset

BigQuery, location EU, in `EVE_PROJECT`. Every table DAY-partitioned with a 400-day
partition expiry, pending the retention floor and ceiling of
[decision 17](../wall-e/09-open-decisions.md) and
[decision 31](../wall-e/09-open-decisions.md) (E-14). No table holds a Workspace payload:
ids, counts and hashes only.

| Table | Kind | Columns | Exists from |
|---|---|---|---|
| `findings` | table | metric name, measured value, **Wilson 95 % interval bounds** rather than a point estimate, threshold, window, verdict, query hash, `ts` | S0 |
| `walle_audit_mirror` | table | The daily append-only copy of yesterday's `walle_audit` partitions, schema as Wall-E's | S0 |
| `verdicts` | table | `run_id`, item, verdict (section 10), reason code, `eve_config_version`, `config_version`, `ceilings_sha`, the epochs read, input hashes, `replay_bundle` id, `ts` | S3 entry |
| `verdict_receipts` | **authorized view** over `verdicts`, in a **separate dataset** of `EVE_PROJECT` (name *tbd*, `Assumption:` `eve_receipts`; EU; topology decision 48), authorized on `eve` | `(run_id, item, verdict_ts)` — **existence only** | S4 entry |
| `attestations` | table | promotion cell, every exit criterion with measured value, window and query hash, the observed decision-file approvers, every named limit on Eve's independence applying to that cell, bundle URL, signature over domain tag `eve-attestation/1` | S3 entry |
| `review_queue` | table | The sampled items drawn for blind grading, with Eve's verdict and reason columns present | S3 entry |
| `review_queue_blind` | **view** over `review_queue` | An allowlisted column set. Eve's verdict and reason columns are **absent by construction**, not hidden by the console | S3 entry, before the S3 exit gate |
| `grades_blind` | table | The grader's accept or reject per item, grader identity, `ts`, written by `eve-console` | S3 entry |
| `pages` | table | Every page Eve raised, its reason code, `ts` — the input to the page budget; plus recipient, channel, delivery result, acknowledgement (ts, by) | S3 entry; with the observe-and-report layer before the super-admin grant |
| `incidents` | table | severity, rule (reason code or catalogue rule id), actor, targets **as ids**, evidence pointers, narrative (sourced from `eve_advice`, written by `eve-advisor@`; empty when the reporting path is not built), recipients, acknowledgement ts and by, resolution, root-cause link, and the SIEM `case_id` it is reconciled against nightly (P100) | Before the super-admin grant |
| `seeded_fault_runs` | table | fault id, required verdict, observed verdict, pass or fail, `eve_config_version`, `ts`; other columns *tbd*. Written monthly and on every `eve_config_version` change (platform HLD §13.3) | S3 entry (the S3 exit gate is its first row set) |

Columns beyond those named are *tbd*.

**`verdict_receipts` cannot live in `eve`.** An authorized view must be in a different
dataset from the dataset its query reads, and the two must share a location
([Authorized views](https://docs.cloud.google.com/bigquery/docs/authorized-views), verified
2026-09-13). So the view sits in its own dataset in `EVE_PROJECT` (name *tbd*, decision 48),
is added to the `eve` dataset's access list as an authorized view, and
`walle-actions@<WALLE_PROJECT>` holds `dataViewer` on that dataset — and nothing on `eve`.
`review_queue_blind` stays in `eve`: its only reader, `eve-console@`, already holds
`dataViewer` on `eve`, and it is a plain view whose blindness is the column allowlist.
If `eve.walle_audit_mirror` is later read by Mo from S4 (topology decision 51), the mirror
moves to a dataset of its own first, because a dataset-level `READER` covers every table.
The same argument is why Mo's and the custodian's read of Eve's quality
data is a separate dataset of authorised views, `eve_quality`, and not a grant on `eve`:
`eve` holds `grades_blind` and `review_queue`, which Mo must never see.

**`verdict_receipts` is the only thing `walle-actions@` may read in Eve's project**, and it
exposes `(run_id, item, verdict_ts)` and nothing else. The service checks that evidence
arrived; it can never branch on what the evidence says. This is a dependency in the
direction the set has otherwise avoided, and it is kept narrowed rather than replaced by a
new POST endpoint because that would change the
[08](../wall-e/08-team-eve-mo.md) contract — E-17, to be re-argued at S4 entry. Its named
residual: a compromised Eve can write false receipts and so suppress the evidence-stale
sweeper, which is why that sweeper is absence-only and why the blind sample, not Eve, is the
precision input.

**Blindness is structural in one direction and enforced in the other.** For refusals it is
free — Eve's verdicts never enter Wall-E's project, so a grader looking at Wall-E's data
cannot see one. For accepts it rests on the allowlisted column set of `review_queue_blind`
and a CI test that fails if a verdict or reason column ever appears in it.

## 10. Verdict states

One row per verified item in `eve.verdicts`.

| State | Meaning | Typical reason code |
|---|---|---|
| `pending` | Drawn, not yet verified | — |
| `verified` | Current state matches **and** a matching admin event attributes the write to the robot | — |
| `verified_state_only` | Current state matches within the 60-minute SLA; the attributing event has not landed yet, or — for the calendar family — will never land | `verification_deferred_lag`, `no_audit_stream` |
| `verified_partial` | Verified as far as Eve's privileges allow, with the gap named | `licence_event_only` |
| `drift` | Post-state contradicts what the plan said would happen | `post_state_mismatch` |
| `reconciliation_gap` | A gap in either direction that has outlived its lag budget; also any robot-attributed event in **any** ingested stream with no matching `walle_audit` or band-B audit row (§14) — a halt | `audit_row_missing`, `admin_event_unmatched`, `reconciliation_gap` |
| `unverifiable` | Eve could not establish the outcome for a reason other than lag | `eve_read_failed`, `unverified_within_sla` |

The transitions and their timers are in [04-flows.md](04-flows.md). Two rules govern them
and both are load-bearing:

- **Current state is the primary evidence**, read immediately, so the 60-minute SLA is
  measured on the state check and is always meetable. The audit event is the *attribution*
  evidence on a slower, per-application clock.
- **Lag alone is never reported as `unverifiable`.** A verdict at T+60 minutes is
  `verified_state_only`; it is upgraded to `verified` when the event lands on the 6-hour deep
  pass; it escalates to `reconciliation_gap` only if nothing has landed by T+6 hours. A slow
  log is a wait; a missing event is still caught.

`WRITE_HIGH` never reaches L5 on any trigger at any stage, so this post-hoc path only ever
covers reversible `WRITE_LOW` and `READ` operations. Pre-approval is permanently the
`WRITE_HIGH` mechanism.

## 11. The replay bundle

Every verdict row carries the hashes of its six inputs and a `replay_bundle` id. The bundle
itself is written to the locked evidence bucket, `gs://<eve-project>-eve-evidence`, by
`eve-verifier@` with `roles/storage.objectCreator` — create only, no delete, no overwrite,
under a **locked** 400-day retention policy that cannot be shortened or removed and that
applies a lien preventing project deletion.

A bundle contains exactly what `decide` consumed: the canonical plan body, the pre-state
Eve read, the ladder artefact and Firestore epochs, the compiled ceiling table's hash, the
predicate implementation's hash, and the `thresholds.yaml` version. Nothing else, and no
Workspace payload.

Its job is a CI test, not an archive: a golden-replay job recomputes archived verdicts
offline from their bundles and requires **bit-identical** output. A verdict that cannot be
reproduced that way fails the build. This is the fourth of the seven enforcements of the
deterministic boundary in [01-hld.md](01-hld.md), and it is also what makes an attestation
worth citing — a promotion cites one URL, and everything behind that URL can be recomputed
by someone who does not trust the person who ran it.

## 12. Canonicalisation of attacker-writable strings

Two different canonicalisations run in Eve, for two different reasons, and they must not be
confused.

**RFC 8785 JCS**, for hashing. Used for the plan body (3.1), the per-item vector
(`items_hash`) and the signed envelope (5.1). It exists so that two implementations reading
the same object produce the same bytes.

**String canonicalisation**, for comparison and display. Every attacker-writable string —
group names, display names, OAuth application names, audit-log fields, anything Eve reads
out of Google's log or out of a plan body — is canonicalised **before it is compared and
before it is rendered**: strip control characters, bidirectional overrides and zero-width
characters, collapse whitespace, cap the length, escape markdown. Failure to canonicalise a
string is `canonicalisation_failed` and refuses the item.

This is the same rule [../wall-e/03-lld.md](../wall-e/03-lld.md) applies to anything
reaching a model or an approval card, applied here for two reasons of Eve's own. First,
comparison: a display name differing only in a zero-width character would otherwise make a
pre-state match look like a mismatch, or the reverse. Second, display: veto and halt
notifications to `walle-operators@`, and every `eve-console` page, are rendered from
canonicalised strings only, because the console is where a human decides whether to veto.

There is one more structural reason it belongs here rather than in Wall-E's document.
The process that parses attacker-writable strings out of Google's audit log is
`eve-reconciler`, running as `eve-verifier@`, which holds **no** `cloudkms.signer`. The
parsing job and the signing job are different identities on purpose: a parser bug cannot
reach the key. See [02-identity-and-auth.md](02-identity-and-auth.md).

## 13. The evidence perimeter for a super-admin Wall-E

(Platform HLD §13.2; §18 item 13.) Sections 1–12 describe how Eve
verifies a catalogued plan. Under the objective the robot holds Super Admin, so Eve must also
see what the robot did **outside** any plan, and must say plainly where it cannot see. The
perimeter below is a declared limit carried in every attestation.

| Route | Content | Independence | Owner |
|---|---|---|---|
| Eve's organisation-level sink `eve-workspace-audit`, **widened to all six** Cloud Logging Workspace streams — admin, enterprise groups, login, OAuth token, SAML, Access Transparency — no actor exclusion, kept independent of the platform's aggregated sinks by design ([../agentic-platform/08-data-logging-retention-sovereignty.md](../agentic-platform/08-data-logging-retention-sovereignty.md) §3.2) | `eve_workspace_logs` (400 days) and the locked bucket | off the "Share data with Google Cloud services" switch — which a super admin can turn off — hence the absence alarm of §14. OAuth token and SAML exist only on Enterprise Standard/Plus, Education Standard/Plus, Voice Premier or Cloud Identity Premium, Access Transparency only on Enterprise Plus and Education (page 07 §1.1 F2); tenant edition *tbd* | Eve owner |
| Eve-owned **Reports API poll by actor** — `activities.list` with `userKey` = `walle@`, `eve@` and every super admin on the committed roster, across applications `admin`, `login`, `token`, `saml`, `groups`, `groups_enterprise`, `user_accounts`, `rules`, `context_aware_access`, `gcp`, `drive`, `vault`, `takeout`, `admin_data_action`, `data_studio` and the rest of the documented list (verified 2026-09-13, [activities.list](https://developers.google.com/workspace/admin/reports/reference/rest/v1/activities/list)) | `eve_workspace_reports`, with per-application lag budgets in `thresholds.yaml` (§7) | uses `admin.reports.audit.readonly`, a scope Eve already consents to; **independent of the sharing switch** | Eve owner |
| Workspace **BigQuery export** (Enterprise Standard/Plus; activity within about 10 minutes) into a dataset in `EVE_WITNESS_PROJECT` | Gmail and other streams Cloud Logging never receives | *tbd* — **P17** (Eve owner, gate Eve S2); if used, its "turned off" event is severity 1 | Eve owner |
| The SecOps native export (page 07 §1.1 F1) | everything above plus Calendar, Meet, Devices, Chrome | organisation-owned; the detection desk's copy, not Eve's | IT security |
| **The "records nothing" list** | customer Takeout by a super admin; Admin console user-data views; Vault searches without export (`Assumption:` per capability, verified or refuted before the grant) | declared, not hidden; the input to band C's watch in Wall-E's `/v1/handoff` | Eve owner |

**The sink, specified.** `eve-workspace-audit` is a **third, Eve-owned organisation-level
sink**, created with `--include-children` and `--use-partitioned-tables`, based on the filter
`protoPayload.serviceName="admin.googleapis.com"` widened to the six streams above, with **no
actor exclusion**; the exact filter is in [07-build-runbook.md](07-build-runbook.md) Phase 7.
Its writer identity holds `roles/bigquery.dataEditor` on `eve_workspace_logs` only. Verified
2026-09-12: an aggregated organisation sink may route to a destination in another project,
its writer identity needing `roles/bigquery.dataEditor` there
([aggregated sinks](https://docs.cloud.google.com/logging/docs/export/aggregated_sinks)); a
BigQuery sink writes **date-sharded** tables unless `--use-partitioned-tables` is given
([route logs to BigQuery](https://docs.cloud.google.com/logging/docs/export/bigquery)); and
the dataset's `--default_partition_expiration` of 400 days must be set **before** the sink
first writes, because it binds only tables created after it
([updating datasets](https://docs.cloud.google.com/bigquery/docs/updating-datasets)). Eve
reconciles against **this** copy, never `walle_workspace_logs` in Wall-E's project; the sink
never carries an actor exclusion, never lives in Wall-E's project and is never merged into the
platform's aggregated sink. Its rows are the object of heartbeat H-1 (§14). It exists from
**S2** — early, deliberately, so Eve's first enforcing window has months of history rather
than zero rows — and in any case before the super-admin grant.

**The Reports poll, specified.** `eve-reconciler`, as `eve-verifier@` with `eve@`'s token,
calls `activities.list` per actor and application into `eve_workspace_reports`. Verified
2026-09-13: every application name in the table is an allowed `applicationName`, the scope is
`admin.reports.audit.readonly`, and `userKey` accepts a primary email. It is the only Eve route
for applications Cloud Logging never receives (Drive, Vault, Takeout, Data Studio …), it reads
activity metadata only, never content, and it exists before the super-admin grant.

**What Eve reads with it.** Eve's read privilege and scope set are **fixed before the
one-sitting consent** (E-16): domain and customer settings (`admin.directory.domain.readonly`,
`admin.directory.customer.readonly`), every Reports application above, the existing Directory
reads; **no content scope**; the privilege names resolved on the tenant with `privileges.list`.
Security and API-controls **state** is not readable by Eve: the Cloud Identity Policy API is
usable by a super administrator only (verified 2026-09-13,
[Policy API overview](https://docs.cloud.google.com/identity/docs/concepts/overview-policies)),
so Eve sees those settings change through their events. The set is on
[02-identity-and-auth.md](02-identity-and-auth.md).

**The daily export.** `eve-export@` exports yesterday's audit and Eve tables with SHA-256
manifests into `exports/` of Eve's locked bucket and pushes the day and a heartbeat row to the
witness, as specified in
[../agentic-platform/08-data-logging-retention-sovereignty.md §5.4](../agentic-platform/08-data-logging-retention-sovereignty.md#54-the-daily-export-to-the-evidence-bucket-closes-decision-31) (P107).

## 14. The detection catalogue, the roster check and the evidence heartbeat

(Platform HLD §13.1 item 5, §13.2; §18 item 14.) All three run in the
**reconciler limb** (`eve-reconciler`, identity `eve-verifier@`) and **never in the gate
limb**; every halt they cause goes through `POST /v1/control/halt` with a code from
`reasons.yaml` or a catalogue rule id, and nothing here raises anything.

**Reconciliation over every stream.** Flow 3's two-direction reconciliation extends from the
Admin stream to every ingested stream of §13: any event attributed to the robot in any stream
with no matching `walle_audit` row or band-B audit row within its lag budget is a
`reconciliation_gap` and **halts** — `no_writes`, as flow 3 already sets, and `halt_all` on the P-SA lanes, the K0
action page 07 §6.5 gives SA-07. The
headline completeness figure keeps a separate count of robot admin events with no matching
catalogue or band-B operation, target 0, severity 1 (platform HLD §13.3).

**The detection catalogue.** A versioned, human-merged rule file beside `reasons.yaml` in
`eve/config` (file name *tbd*), each rule with an id, severity, source stream, evidence fields
and one action:

| Class | Rules | Severity | Action |
|---|---|---|---|
| Tenant integrity | the SIEM's `SA-01`…`SA-09` of [../agentic-platform/07-monitoring-detection-incident-response.md §6.2](../agentic-platform/07-monitoring-detection-incident-response.md#62-the-super-admin-set-workspace-side--siem-hosted-severity-1-owned-by-it-security), mirrored so that the desk's evaluator and the verifier's are independent and their firing is compared; Eve's copy also targets `eve@` and Eve's role | 1 | `halt_all` on the P-SA lanes, page (§15); K5/K6 stay human |
| Writes outside the catalogue's families | any write by `walle@` in a stream or application no catalogue family or band-B method covers (SA-08's shape) | 1 | as above |
| Posture change by any actor, interactive robot login | SA-03 and SA-04 mirrored; they fill Eve's paging conditions 5 and 6 ([06-failure-modes.md](06-failure-modes.md)) | 1 | as above |
| Tenant integrity over the human super admins (from the first run, 2026-09-15) | `SA-01`…`SA-09` with the actor widened from `walle@` to **any watched human** — the committed roster, delegated administrators, break-glass accounts and live admin-role holders; `SA-03` and `SA-09` on any actor, an unrostered one included — plus `SA-10`, a watched human in a data-export application (a Vault or search export, a Takeout of another person's data, a Drive ownership transfer or bulk download, a Data Studio or `user_accounts` export, a `gcp` administrative action). `SA-01` reads a committed admin-method allow-list with a `never_allowlisted` set no merge can widen; every severity-1 rule carries two sources, the sink and the poll, because the sink dies with the sharing switch (§14.1; committed form [setup 25 EH-2.3](../agentic-platform/setup/25-eve-human-super-admin-detections.md#eh-23-the-detection-catalogue-sa-01sa-10-with-actor--any-roster-human-and-si-01si-13)) | 1 (`SA-10`: 1 for `vault` and `takeout`, 2 for the rest) | finding and page under §15 with the actor as subject; `halt_all` where a halt target exists, `halt_target_pending` before one does |
| Self-integrity (2026-09-15) | `SI-01`…`SI-13`, what a monitored administrator would have to touch to silence Eve: any change to `eve@` (password, 2SV, suspension, deletion, token, role); `EVE_SINK` updated or deleted, or its writer identity changed; `SetIamPolicy` or a dataset access change on `EVE_PROJECT`; any Cloud Run job or Cloud Scheduler write, or an image digest off the recorded one; a dataset, table, bucket, retention or lock change on Eve's stores; a key state change on either Eve key ring; DML `DELETE`, `UPDATE`, `MERGE` or `TRUNCATE` against Eve's tables (P186); "Share data with Google Cloud services" turned off or a domain-wide delegation client added — read from the poll, the route that survives the switch; multi-party approval or self-recovery settings changed, or an approval by a service identity (P191); a Secret Manager write on either Eve secret; a lien removal, delete or update on `EVE_PROJECT`; a notification-channel or alert-policy edit in `EVE_PROJECT`; the poll throttled (`quotaExceeded`, HTTP 429) | 1 | as above; a rule whose source is `platform_logs_views.eve_self_integrity` is parsed, fixture-tested and reported as blocked until that view exists, never evaluated silently |
| Baselines | volume, time-of-day and target-population per family | 2–3 | page or ticket; calibrated at S2 (E-18) |
| Prompt-to-action divergence | the action executed against the signed human assertion of [decision 14](../wall-e/09-open-decisions.md) — Eve reports on **human prompts** as well as robot actions, because under Super Admin the operator prompting is the escalation | 2 (1 when a tenant-integrity target is involved) | page |

The misbehaviour taxonomy and the detector coverage map are Mo's first Eve artefact; IT security
code-owns the SIEM's copy of the tenant-integrity rules (P96).

**The roster check.** Daily, from Eve's own credential: `roleAssignments.list` and `users.list`
with `isAdmin`, diffed against the committed roster (the accounts of
[../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md)
§8.1, signed by the security reviewer), plus the Reports-privilege holders who can switch the
SecOps export off. A fourth super admin, a role change on a roster account or a new admin role
holder is `role_assignment_added`; a roster account that lost its role is
`role_assignment_missing`; both are severity 1 and page in both directions (P68). The drift row
"`walle@` holds no organisation-level IAM role" is the platform drift job's, not Eve's.

**The evidence heartbeat.** Silence is what a super admin can manufacture, so the default state
of silence is a halt, not an alert about it (P97). Eve's reconciler raises `log_pipeline_silent`
— severity 1, `no_autonomous` for every agent Eve verifies and `halt_all` on `walle-actions` and
`walle-actions-super`, cleared by one authenticated human call that is itself a report about the
administrator (§15) — when H-1 finds no `eve_workspace_logs` rows for 60 minutes in business
hours (240 outside), and when Eve's token returns `invalid_grant`, which only a human
re-bootstrap restores; on H-4, a missing `eve_last_seen` stamp for 15 minutes follows runbook
RB-03 and a missing daily witness push for 26 hours pages severity 1 (the push cadence and the
windows are superseded by P150, §14.1). The windows, where each
alarm lives and why the witness holds it are canonical in
[../agentic-platform/07-monitoring-detection-incident-response.md §7](../agentic-platform/07-monitoring-detection-incident-response.md#7-pipeline-heartbeats-and-the-log_pipeline_silent-halt).

### 14.1 Scope from the first run: the human super admins (2026-09-15)

On 2026-09-15 the owner asked that Eve watch every human super admin from its first run, before
Wall-E exists. Nothing in §13–§15 changes shape; the actor set does. From the first run the poll
retrieves every application with `userKey=all`, the roster check and the catalogue's actor sets
cover the committed roster, delegated administrators, break-glass accounts, live admin-role
holders and unrostered accounts, and `walle@` joins the robot set only when it exists. Three
consequences the procedures fix:

- **No halt target.** Before `walle-actions` exists there is nothing to halt, so a halting rule
  pages severity 1 and records `halt_target_pending` in `eve.incidents`; the halt call joins at
  [setup 36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md). The roster check runs hourly
  ([setup 25 EH-5.2](../agentic-platform/setup/25-eve-human-super-admin-detections.md#eh-52-create-the-five-schedules-with-the-selftest-argument--blocked)),
  daily being the floor above.
- **The heartbeat and the export.** `eve-export@` writes an hourly heartbeat row to the witness
  carrying the last hour's row counts and cumulative per-table counts, plus an export every 6
  hours (`Assumption:`); the witness holds a heartbeat absence policy of about 90 minutes and an
  export absence policy of at most 23.5 hours, replacing the 26-hour window above (P150;
  [setup 27 WG-3.5](../agentic-platform/setup/27-witness-grants-and-alarms.md#wg-35-the-heartbeat-absence-policy-about-90-minutes)).
- **Severity 1 in minutes.** Route 1 is the organisation-owned paging service with the second
  human as a parallel recipient; route 2 is an incident-mode push to the witness and a policy
  there paging the second human and both witness administrators (P151); §15's "witness
  channels" reads as these two routes. A report whose subject is a human with authority over the
  platform, the platform owner included, goes to the second human only (the sole-recipient rule);
  who receives a report about the second human is decided before the routing is merged
  ([setup 26 ER-0.2](../agentic-platform/setup/26-eve-reporting-and-witness-export.md#er-02-the-b-12-gate-who-receives-a-report-about-the-second-human)).

Because the monitored administrator installs Eve, the second human proves the detection
independently on a seeded super-admin action before `EVE_H_LIVE_RECORD` is signed, and the
monitored administrator cannot pause it unnoticed: `eve-owners@` is owned by the second human,
`eve/config` requires their review, the platform owner holds no standing role that can edit Eve,
a configuration change that pauses a detection is itself reported, and the witness copy and the
absence alarms live outside the tenant (P155;
[setup 28](../agentic-platform/setup/28-eve-independent-proof-and-sandbox-drills.md) §2, §3 and §5). The jobs stay
BLOCKED until the DPO record for monitoring administrator accounts is signed (P154;
[setup 25 EH-0.2](../agentic-platform/setup/25-eve-human-super-admin-detections.md#eh-02-the-sd-11-gate-the-dpo-record-for-monitoring-named-administrators)).
The build is [setup 23–28](../agentic-platform/setup/README.md#3-the-order); the decisions are P153–P155 in
[../agentic-platform/12-open-decisions.md §6a](../agentic-platform/12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191).

## 15. The reporting contract

(Platform HLD §13.2 against decision 14; §18 item 15; the platform rule
RP-1…RP-6 of [../agentic-platform/07-monitoring-detection-incident-response.md](../agentic-platform/07-monitoring-detection-incident-response.md)
§8, of which this is the first instance, P98.)

| Severity | Examples | Channel | Recipients | Acknowledge within | Escalate to |
|---|---|---|---|---|---|
| 1 | tenant-integrity rule, robot login, roster change, uncatalogued admin write, evidence absence | witness channels: SMS + mobile app + PagerDuty; email and Chat as secondary copies only | the second human outside the Wall-E line **and** the on-duty desk in parallel; the Wall-E owner in copy unless the actor is the owner | 15 min / 60 min (`Assumption:`); "next business morning" below Tier P | incident commander; K5/K6 rota; automatic halt already applied |
| 2 | baseline deviation, wrong accept, `eve-advisor` finding | PagerDuty (business hours), email | Wall-E owner + second human | 4 business hours (`Assumption:`) | security reviewer; ticket |
| 3 | drift, threshold review due | `eve-console`, weekly digest | operators | next review | — |
| Reports about the administrator | level raises, halt clears, threshold edits, `eve_authority` promotions, any request on a protected principal whose requester is the ladder owner | out of band from the witness | **sole recipient: the second human** | as severity | — |

**The sole-recipient rule.** A report whose subject is a human with authority over Wall-E goes
to the second human only, out of band from the witness, never to the person it is about.

**`eve.incidents`** (§9) is Eve-owned, DAY-partitioned and kept 400 days; its row links to
the one incident record in the SIEM's case system and the case links back, reconciled nightly
(P100). The narrative column is sourced from `eve_advice`, the only dataset `eve-advisor@`
writes; the control path never reads it. **`eve.pages`** carries recipient, channel, delivery
result and acknowledgement for every page. A page unacknowledged past its target is re-paged to
the `oncall.yaml` secondary and, past twice the target, to the incident commander (RP-5). More
than three pages a week from one reason code raises `threshold suspect` (RP-6).

**`oncall.yaml`** gains a **primary**, a **secondary outside the Wall-E line** and
**per-severity timeouts**; it is the platform rota file, with the K5/K6 rota of human super
admins as a second section whose records are held in the witness (page 07 §9.2).

**`eve-console`'s IAP audience** becomes a dedicated group (name *tbd*) rather than
`walle-operators@`, and any membership change on it is a severity-1 rule (SA-09).

**The reporting path's limits.** `eve-advisor` pages at severity 2 only, inside the budget,
citing the deterministic finding that triggered it; it produces no finding about a named human
without that rule until P19 is answered; a change of its model pin resets its paging
thresholds and re-runs the seeded-fault set before it pages again (P123).

---

## What this page fixes for other documents

This page defines the canonical serialisation, the hash algorithm and the full signed field
list that [C39](../wall-e/14-hld-challenge.md) requires before the approve endpoint is built,
Eve's closed reason vocabulary (separate from Wall-E's denial vocabulary), and the evidence
perimeter, detection catalogue classes, roster codes, `log_pipeline_silent` and reporting
contract that Wall-E's `06-security-guardrails.md`, the platform pages 07 and 08 and Mo's Eve
quality pack read against; every edit they force back into Wall-E's set — `items_hash`,
`eve_key_version`, `approver_type`, `eve_authority_advisory` — is listed with its gate in
[08-contract-changes.md §1](08-contract-changes.md#1-the-contract-change-table).
