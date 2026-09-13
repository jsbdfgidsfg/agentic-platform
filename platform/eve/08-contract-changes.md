# 8. What this design changes in Wall-E's set

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- **Objective restated 2026-09-13; see the platform HLD**
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.2 and §18; owner the Eve
  owner for the rows added here, the Wall-E agent owner for their landing, P143). The table
  below is a dated edit list and stays as written; rows CC-34 to CC-37 are appended for the
  edits the platform HLD's Eve items (11–17) force back on Wall-E, and CC-10 carries a dated
  pointer. Wall-E's own super-admin edits are §18 items 1–10 and are not repeated here.

[`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md) is the contract, and this set
builds against it rather than renegotiating it. It does not survive contact unamended. This
page is every edit Eve forces back on Wall-E's set, in one place, so nobody discovers one at
build time — when the discovery is a half-built approve endpoint that cannot verify a
signature, or a `CONTROL_CALLER_ALLOWLIST` that locks the only human out of the halt path.

Two kinds of edit are mixed here and the Reason column says which is which:

- **Already binding.** Decided by the 2026-09-11 challenge in
  [`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md) — C10, C12, C13, C14,
  C16, C30, C39, C48 — and not yet landed in the pages or the code. These are not proposals.
  The built artefact and the decision currently disagree, which is the worst of the two
  states to be in.
- **New from this design**, carrying an E-number from [09-open-decisions.md](09-open-decisions.md).

Since 2026-09-13 the placement half of these rows — which of the four projects each
resource lives in, and the form of every grant that crosses — is fixed by
[../project-topology.md](../project-topology.md); rows below that name a project or a
cross-project grant are worded to match it and point there rather than restating it.

Nothing on this page adds an endpoint, a credential, or a capability to Wall-E. Every edit
either records a decision already taken, moves a resource out of Wall-E's project, narrows
something, or names an owner for an outcome four documents assert and none assigns.

---

## 1. The contract-change table

| # | File | Edit | Reason | Gate |
|---|---|---|---|---|
| CC-1 | [`../wall-e/03-lld.md`](../wall-e/03-lld.md) | Add `items_hash = SHA-256(RFC8785(vector))` to the signed field list — exactly one field, alongside C39's `plan_id`, `plan_hash`, `config_version`, expiry, nonce and key version | C39's field list and C16's per-item accept/reject vector are incompatible as written: a signature over `plan_hash` alone cannot authorise a *subset*, so a tamperer could flip an accept bit outside the signature and the service would verify it happily. New, [E-3](09-open-decisions.md) | **Before the approve endpoint is built** |
| CC-2 | [`../wall-e/03-lld.md`](../wall-e/03-lld.md) | Add `eve_key_version` to the `approvals` table's key columns, carrying the **full KMS key-version resource name** | A KMS signature carries no identifier of the version that produced it, so a destroyed or rotated version makes every stored approval unverifiable. With the version recorded, verification is offline against the archived PEM and survives key destruction. Already binding, C48 | Before the approve endpoint is built; the column at first commit |
| CC-3 | [`../wall-e/03-lld.md`](../wall-e/03-lld.md) | An Eve-rejected item in a batch stays `skipped_by_operator`, with `approver_type: eve` recorded on the row. No new outcome state | 03's outcome vocabulary is declared closed and defined in one place; metrics nonetheless have to separate an Eve rejection from a human one. A field is a one-line edit; a state is a fork in every consumer. New, [E-11](09-open-decisions.md) | Before S4 |
| CC-4 | [`../wall-e/03-lld.md`](../wall-e/03-lld.md) | Add one **non-invariant** denial reason, `eve_authority_advisory`, to the denial-reason table | The per-cell `eve_authority` switch (CC-6) has to be enforceable, and a denial with no reason string is invisible to every metric, alert, breaker and CI gate that keys on those strings. Adding it anywhere but 03 would break the "defined here and nowhere else" property. New, [E-4](09-open-decisions.md) | Before S4; the schema before the approve endpoint |
| CC-5 | [`../wall-e/03-lld.md`](../wall-e/03-lld.md) | "the service verifies with the public half" becomes: **offline verification against a pinned, committed PEM as the primary path**, Cloud KMS `getPublicKey` cross-project as fallback only | See section 5. Strictly stronger than a live public-key fetch, and the only version that holds once Eve's key leaves Wall-E's project. New, from [E-1](09-open-decisions.md) | Before the approve endpoint is built |
| CC-6 | `config/ladder.yaml` schema, its CI validator, and [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) | Add `eve_authority: advisory \| binding` as a per-cell field and as a field on the override document. Absent reads as **advisory**. An override may only ever lower it. The CI validator refuses any config placing a cell at L4 while its authority is advisory | C12 and E58 demote *Eve's authority* as a control, and that control has no storage and no enforcement anywhere in Wall-E's set. One field carries both jobs — the observe/enforce switch and the demotion target when an Eve approval is overturned. Two fields (`eve_gate` and `eve_authority`) would drift. New, [E-4](09-open-decisions.md) | The schema and the **validator rule** at the **first commit** — see CC-32: since no cell carries `eve_authority: binding` before S4 by construction, that one rule already refuses every L4 cell from S0 to S3, and it is the rule this design already owns. The enforcement in `walle-actions` before S4 |
| CC-7 | [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) §7, Stage 3 exit criteria | Replace "agreed with human verdicts ≥ 95 %, and caught ≥ 95 % of deliberately seeded faults" with: **100 % catch of the twelve named invariant-class seeded faults**, both negative controls not firing, and **agreement with human verdicts reported for information only** | Two defects in one line. A 95 % catch rate over twelve invariant classes permits one class to be missed entirely and still pass the gate — and each of those classes is a hard invariant. And an agreement *rate* is not a gate for a deterministic checker: where Eve and a human disagree, one of them is wrong, and the finding is the disagreement, not the percentage. Already binding, C12 | **Before S3 exit**; the wording now |
| CC-8 | [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) §6 | State that Eve's "lower to any level, including halt" is exercised as **one `demote` call per cell**, each with its own reason and its own audit row; a genuinely tenant-wide condition uses `halt`, which is atomic | §6 grants Eve a tenant-wide-sounding power; the `demote` contract in 08 takes one `(family, trigger)`. The seam between the first call and the last is milliseconds wide and it is better named than claimed away. New, [E-8](09-open-decisions.md) | With the design record |
| CC-9 | [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) §8 | Define how Eve's verdict states count into **Verification success** and **Eve post-hoc latency**: latency is measured on the **current-state** check, not on the audit event; `verified_state_only` counts as verified for the SLA and is upgraded to `verified` when the event lands; `verified_partial` is declared per cell and carries its named limit; F7's `unverifiable` is a hard stop rather than part of the budgeted 2 %; and a **permanent** `verified_state_only` with `no_audit_stream` counts as verified for the SLA and never escalates, for a family Google writes no Cloud Logging audit stream for at all | §8 was written against a two-valued world (`verified` / `drift` / `unverifiable`). Without this, a late admin event reports as `unverifiable` and demotes cells for being slow rather than wrong — and the calendar half of F2b, which has no audit stream in Cloud Logging to be late or early, demotes for being unloggable. See [06-failure-modes.md](06-failure-modes.md) for the primary-evidence split and [04-flows.md](04-flows.md) flow 2 for which stream each budget clocks. New, from this design | Before S4 |
| CC-10 | [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md), item 5 | "Halting, on its own judgement, with a reason code, and a documented bias toward halting when uncertain" becomes: at the **approval** point the conservative act is **refuse**; **halt** is reserved for the closed invariant-trigger list and is never discretionary. **Dated pointer 2026-09-13:** the objective reopens the *reporting* half of item 5 — Eve's report-only reporting path may reason (platform HLD §13.2, P34); the halting half of this row stands, and `wall-e/08` item 5 narrows to Eve's reporting path per §18 item 6 | "Its own judgement" is void under C12 and [decision 34](../wall-e/09-open-decisions.md) — there is no judgement in Eve, only declared thresholds with reason codes. And the bias as written is backwards: a degraded Eve that halts turns every hiccup into a programme outage; a degraded Eve that refuses costs an operator one approval. Already binding (C12) plus new, [E-7](09-open-decisions.md) | With the design record |
| CC-11 | [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md), failure-mode table, "Eve down" | Name the owner: two deterministic sweepers **inside `walle-actions`** plus one passive stamp — `eve_silence`, `eve_evidence_stale`, `eve_last_seen`. No new endpoint, and **no code path that raises on Eve's return** | Four documents state the outcome ("over four business hours, `no_autonomous` is set automatically") and none assigns it, so it would have been built by nobody. It cannot be Eve's: a liveness signal Eve publishes cannot prove Eve is alive, and a wedged Eve that still heartbeats keeps autonomy alive. New, [E-5](09-open-decisions.md) | **First commit**, inert; wired at S4 |
| CC-12 | [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md), shared data plane | Specify the BigQuery grant that exists nowhere: dataset-level `roles/bigquery.dataViewer` on `walle_audit` for Eve's identities, and `roles/bigquery.jobUser` **in Eve's own project**. Never project-level `dataViewer` | Every "Eve and Mo read BigQuery" line in the contract was unbuilt as of 2026-09-12 — `add_dataset_access` was called exactly twice in the runbook and neither call was for Eve or Mo. The 2026-09-13 topology has Wall-E's runbook grant dataset-level `READER` on `walle_audit` to `eve-v0@`, `eve-controller@`, `eve-verifier@` of `EVE_PROJECT` (topology §3 row 4) and to Mo's metrics identity of `MO_PROJECT` (row 6, Mo's set). Dataset-level keeps the grant to the six tables; project-level would be a lateral path into Wall-E's project; `jobUser` in Eve's project keeps job creation and query cost off Wall-E's bill. New, [E-9](09-open-decisions.md) | S3 entry |
| CC-13 | [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md), shared data plane, `walle-events` row | Eve's cell changes from `subscribe` to **none**. The topic stays; Eve takes no subscription at any stage. The schema C39 asks for becomes the obligation of whoever later asks for the topic | The only latency-sensitive duty is L5 post-hoc within 60 minutes, and a 5-minute poll of the day-partitioned `actions` table meets it twelvefold. A topic Wall-E publishes to is also a channel Wall-E controls, which is the wrong shape for the evidence path. Already binding (C30) plus new, [E-20](09-open-decisions.md) | With the design record |
| CC-14 | [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md), identity table | Eve's row splits into three principals — `eve-controller@` (signs), `eve-verifier@` (reconciles, holds **no** `cloudkms.signer`), `eve-console@` (read-only) — all in **Eve's own GCP project**, `EVE_PROJECT`, with the key and both secrets there too; the three principals' `run.invoker` on `walle-actions` is Wall-E's runbook's grant against their `@${EVE_PROJECT}` emails | The process that parses attacker-writable strings out of Google's audit log must not be able to reach the signing key. And while the key sits in Wall-E's project, a project owner can grant themselves `cloudkms.signer` and mint an Eve approval, with a daily drift row as the only control. New, [E-1](09-open-decisions.md); see [02-identity-and-auth.md](02-identity-and-auth.md) | The project boundary before Eve onboarding; the dataset half before Stage 1 |
| CC-15 | [`../wall-e/ARCHITECTURE.md`](../wall-e/ARCHITECTURE.md) §4.2 | **Delete the paragraph "Why Eve may invoke the agent"** and remove `aiplatform.reasoningEngines.query` from `eve-controller@` in the principal table. The defence-in-depth row that reads "granted to exactly three principals: the Gemini Enterprise service agent, the dispatcher and Eve. Section 4.2 says why Eve is one of them" becomes **two principals** — the Gemini project's Discovery Engine service agent, `service-<GEMINI_PROJECT_NUMBER>@gcp-sa-discoveryengine.iam.gserviceaccount.com`, and `walle-dispatcher@` — and the cross-reference goes | C10 removed the grant. The paragraph is still there at the time of writing and it argues the opposite case — that Eve may run verification playbooks through the agent. A verifier that reaches its subject through a model has no independence left to defend. Already binding, C10 | Before S3 entry; the wording now |
| CC-16 | [`../wall-e/ARCHITECTURE.md`](../wall-e/ARCHITECTURE.md), component map | Remove the `PE --> EVE` edge; redraw `WSB -.-> EVE` as Eve's **own third organisation-level sink** into Eve's project; draw `BQ --> EVE` as a cross-project read plus the daily append-only mirror. Four project boundaries — `GEMINI_PROJECT`, `WALLE_PROJECT`, `EVE_PROJECT`, `MO_PROJECT`, all under `FOLDER_ID` — and no inbound arrow to Eve | The map is the first thing a reviewer reads and it currently shows Eve subscribing to a Wall-E topic and reconciling against a copy of Google's log that lives inside Wall-E's teardown blast radius. Already binding (C30) plus new, [E-1](09-open-decisions.md) | With the design record |
| CC-17 | [`../wall-e/ARCHITECTURE.md`](../wall-e/ARCHITECTURE.md) §4.2, `eve-controller@` and `walle-actions@` rows | `eve-controller@` "per an open decision, its own read-only Workspace credential" becomes settled ([decision 10](../wall-e/09-open-decisions.md) is answered yes); `walle-actions@` "reads … KMS public key" becomes "verifies against a pinned committed PEM, KMS `publicKeyViewer` cross-project as fallback" | Both rows describe a world where Eve's credential is undecided and Eve's key is local. Neither is true after this design. New, from [E-1](09-open-decisions.md) | With the design record |
| CC-18 | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phase 15 | **The whole phase moves** out of Stage 0 into an **Eve onboarding** step at S3 entry, opened by the S3 entry decision record | Google expires a refresh token unused for six months, and a token exchange rather than an API call resets the clock. Stage 0 as written provisions a dormant, tenant-wide admin **read** credential six to eight weeks before anything can use it, and scopes freeze at consent, so a credential minted early is also a scope list frozen early. The seams stay in code: contracts, audit columns and a CI-only stub caller. Already binding, C14 / [decision 36](../wall-e/09-open-decisions.md) | **Before Phase 1** for the decision; the step itself at S3 entry |
| CC-19 | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phase 15, scope table | Drop `apps.licensing` from Eve's consented scopes | C13 decided it. Eve verifies licence changes from Google-written licence events instead and records them `verified_partial` with reason `licence_event_only` — a declared, permanent limit on independence for F7 at L4, not a gap to be closed later. Already binding, C13 | With the onboarding step |
| CC-20 | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phases 6, 8, 10, 12, 13b, 15 and §6.1 | Eve's project, service accounts, secrets and key **leave `${PROJECT}`**. Key ring `walle` / key `eve-approval` becomes key ring `eve` / key `eve-approval` in Eve's project; `eve-oauth-client` and `eve-refresh-token` become regional secrets in Eve's project; `CONTROL_CALLER_ALLOWLIST` becomes `${SA_EVE},${SA_EVE_VERIFIER},${OPERATORS}`; `EVE_KMS_KEY` points cross-project; the Stage-0 exit checklist items about Eve's key move to the S4 gate | The separation invariant the runbook already asserts — `walle-actions@` must never mint an Eve approval — is IAM hygiene while both live in one project, and structural once they do not, because Wall-E's principals have no presence in Eve's project to be granted anything. New, [E-1](09-open-decisions.md) | Project boundary before Eve onboarding; the key at S4 entry |
| CC-21 | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phase 8 and the teardown guard | Export **every** `eve-approval` key version's PEM at creation, **before first use**, to Eve's locked evidence bucket **and** to `contracts/eve-public-keys/<version>.pem` in Wall-E's repository under `ladder.yaml`'s CODEOWNERS. The teardown guard is a precondition check, not a warning: if either copy is missing it **refuses `--destroy-key-versions` and exits non-zero**, naming the version and both expected paths — `gs://<eve-project>-eve-evidence/keys/eve-approval-v<n>.pem` and `contracts/eve-public-keys/<n>.pem` | C48 recorded the decision and no phase writes the export, no teardown check reads it. A PEM exported after first use leaves a window in which a signature exists that nothing can verify later. Already binding, C48 | S4 entry; the teardown guard with it |
| CC-22 | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phase 7 | Add the two dataset grants of CC-12 — dataset-level `READER` on `walle_audit` for `eve-v0@` (S0) and for `eve-controller@`, `eve-verifier@` (S3 entry), all of `EVE_PROJECT`, `add_dataset_access` gaining a project argument — and note that query jobs run in Eve's project so no `bigquery.jobUser` is needed in Wall-E's. The same call grants Mo's metrics identity of `MO_PROJECT` in Mo's Stage-0 phase | Same gap as CC-12, expressed as a runbook step rather than a contract sentence. New, [E-9](09-open-decisions.md) | S3 entry |
| CC-23 | [`../wall-e/SETUP.md`](../wall-e/SETUP.md) Phase 17, denial suite | Denial tests 4, 5, 6 and 52 are exercised from the **first commit** by a CI-only stub caller standing in for `eve-controller@`, and test 6's `POST /v1/execute` → 403 is asserted for **Eve's identity** as well as for a human operator token | The interfaces exist from commit one and nothing exercises them until Eve does, which is six to eight weeks of an unexercised approval path. Test 52 — an operator token accepted on halt — is the one that catches an allowlist holding Eve alone, which would mean no human can halt. The stub caller exists **in code only**: there is no fault-injection or test-mode path reachable in any admitted image. Already binding, [decision 36](../wall-e/09-open-decisions.md) | **S0**, in code |
| CC-24 | [`../wall-e/setup/walle_setup.py`](../wall-e/setup/walle_setup.py) | New required config keys **`EVE_PROJECT`**, **`MO_PROJECT`**, **`GEMINI_PROJECT`** and **`GEMINI_PROJECT_NUMBER`**, distinct from `PROJECT` — which stays Wall-E's own project, documented once as "`PROJECT` is Wall-E's project, `WALLE_PROJECT` elsewhere" — threaded through `configure()`, the required-key lists and the registry keys. Eve's set needs `EVE_PROJECT`; the other three land with it ([../project-topology.md](../project-topology.md) §6) | Every Eve resource name in the script is currently `…@${PROJECT}` or a ring inside `${PROJECT}`. Without the key the boundary of CC-14 and CC-20 cannot be expressed at all. New, [E-1](09-open-decisions.md) | Before Eve onboarding |
| CC-25 | [`../wall-e/setup/walle_setup.py`](../wall-e/setup/walle_setup.py) | `SA_EVE` default becomes `eve-controller@${EVE_PROJECT}`; add `SA_EVE_VERIFIER` and `SA_EVE_CONSOLE` | Three identities, three jobs, one of them deliberately without `cloudkms.signer`. New, [E-1](09-open-decisions.md) | Before Eve onboarding |
| CC-26 | [`../wall-e/setup/walle_setup.py`](../wall-e/setup/walle_setup.py) | **Superseded on 2026-09-13 by topology decisions 43 and 44.** As first written this row made `EVE_PROJECT_ROLES` the full list of Eve's project-level roles in Wall-E's project (`datastore.viewer`, `agentregistry.viewer`, for `eve-controller@` and `eve-verifier@`) and kept `lock_agent_registry`'s `agentregistry.viewer` for Mo. The target is now the opposite: **`EVE_PROJECT_ROLES = ()`**, no `agentregistry.viewer` for anyone (decision 43, done in `registry` and SETUP Phase 13b), no `datastore.viewer` (decision 44 open; nothing granted meanwhile), and `check_project_roles` failing on any project-level role for any `@EVE_PROJECT` or `@MO_PROJECT` principal. The dataset grants of CC-12/CC-22 are not project roles and stand. Eve's Firestore discovery read is absent until decision 44 lands as an IAM Condition on the database or as CC-33 | The set asserted in one place that Eve's only project-level role in Wall-E's project was `datastore.viewer`, and granted `agentregistry.viewer` in another. Rather than reword the exception, the topology's rule (row 26) removed both. [E-12](09-open-decisions.md), settled by removal | Done in the script on 2026-09-13; decision 44 before S3 entry |
| CC-27 | [`../wall-e/setup/walle_setup.py`](../wall-e/setup/walle_setup.py) | Remove `apps.licensing` from `EVE_SCOPES` | The code and the decision currently disagree, and the code is what gets consented. Already binding, C13 | Before Eve onboarding |
| CC-28 | [`../wall-e/setup/walle_setup.py`](../wall-e/setup/walle_setup.py) | Remove `SA_EVE` from `lock_engine_iam()`'s member list for the custom `walleEngineQuery` role | Same disagreement as CC-15, in code. Two query principals remain: the Gemini project's Discovery Engine service agent, `service-<GEMINI_PROJECT_NUMBER>@gcp-sa-discoveryengine.iam.gserviceaccount.com` (the app project's number, never `PROJECT_NUMBER`), and `walle-dispatcher@`. Whether the engine-scoped custom role `walleEngineQuery` suffices for a cross-project service agent is a Wall-E spike; `roles/discoveryengine.serviceAgent` on `WALLE_PROJECT` is the documented fallback (topology decision 42). Already binding, C10 | Before S3 entry |
| CC-29 | [`../wall-e/setup/walle_setup.py`](../wall-e/setup/walle_setup.py) | `ensure_kms()` creates ring `eve` in `EVE_PROJECT`; the existing assertion that `walle-actions@` holds only `publicKeyViewer` becomes a **cross-project** assertion; `ensure_eve_secrets()` creates in `EVE_PROJECT`; the secret separation sweep spans both projects and **runs as the human operator** (it needs `getIamPolicy` on Eve's secrets in `EVE_PROJECT`, which Wall-E's identities do not hold; the script asserts only the `WALLE_PROJECT` half); add an assertion, run by Eve's drift job, that **no Wall-E principal holds a project-level role in `EVE_PROJECT` nor any role on `FOLDER_ID`**, and that the only resource-level grants to Wall-E principals in `EVE_PROJECT` are CI `objectCreator` on the `ladder/` prefix, `walle-actions@` `publicKeyViewer` on `eve-approval`, and `walle-actions@` `dataViewer` on the `verdict_receipts` authorized view (topology decision 48) | The build already fails on a project- or keyring-level signer grant to `walle-actions@` because "it could mint an Eve approval". That check has to follow the key, and gains a stronger sibling once the project boundary exists. New, [E-1](09-open-decisions.md) | Before Eve onboarding |
| CC-30 | [`../wall-e/setup/walle_setup.py`](../wall-e/setup/walle_setup.py) | The `CONTROL_CALLER_ALLOWLIST` assertion accepts **three** members and still FAILs when `${OPERATORS}` is absent. The three members are cross-project emails (`@${EVE_PROJECT}.iam.gserviceaccount.com`); the read-endpoint allowlist that admits `mo-analyst@<MO_PROJECT>` to `GET /v1/plans` and `GET /v1/runs` is a separate list and never part of the control-caller list | The assertion exists precisely because an allowlist holding Eve alone means no human can halt or demote. Adding `eve-verifier@` must not weaken it into a length check. New, from [E-1](09-open-decisions.md) | With the allowlist change, S3 entry |
| CC-31 | [`../wall-e/setup/walle.env.example`](../wall-e/setup/walle.env.example) | `walle.env.example` gains `GEMINI_PROJECT`, `GEMINI_PROJECT_NUMBER`, `EVE_PROJECT` and `MO_PROJECT` in one edit; `FOLDER_ID` (already present) becomes required for `gcp` as well as `armor`. `EVE_ROBOT` and `EVE_TOKEN_VERSION` stay as they are. `MO_PRINCIPAL` is re-homed to `@${MO_PROJECT}` by Mo's set | The example env file is what anyone copies. New, [E-1](09-open-decisions.md) | With CC-24 |
| CC-32 | [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md) §7, **S2 Levels**, and the stage-overview table | Scheduled **F2 is L3 at S2 and at S3**, rising to **L4 at S4 entry** with the rest of the Eve-gated set. Strike "templated notification is the first autonomous write in the whole programme" from S2's Levels row and move that phrase to S4. Add scheduled F2 L4 to the S4 row of the stage overview. §7's **S0** row carries the same phrase in its "the reporting channel is not on the ladder" cell — "Stage 2's 'first autonomous write' is F2 to a *space or list*" — and becomes "Stage 4's", with the distinction it draws left intact. S2's exit criterion "zero drift on the F2 notifications actually executed" keeps its wording but now has **L3 human-approved notifications** as its subject — a weaker criterion than it reads as, and one that should say so | §7's S2 row puts scheduled F2 at **L4**, two stages before Eve has a signing key: §2 defines L4 as "Policy passes → `pending_eve`. Eve approves with **its own signing key**", and this design dates the key, the signer role and `eve-gate` to S4 entry ([05-stages.md](05-stages.md)). Left as written, the pilot's first autonomous write is a plan that sits at `pending_eve` until `eve_silence` sets `no_autonomous` after four business hours — or, once CC-6's validator exists, a config CI refuses to accept at all. Resolved downwards because the alternatives are all closed: moving the key to S2 breaks [07-build-runbook.md](07-build-runbook.md) Phase 11's own precondition ("do not execute this phase until the S3 exit gate has passed at 100 %") and would let Eve make *more* happen before the blind-graded evidence that bounds a compromised Eve exists; and re-tiering `notify.operators` outside the ladder is already taken — §7's S0 row puts the reporting channel outside the ladder and expressly distinguishes it from S2's F2-to-a-space-or-list. Only humans raise a level, so the level that moves is the one on paper. Already binding, the joint **C26/C27** residual in [`../wall-e/14-hld-challenge.md`](../wall-e/14-hld-challenge.md), which names this contradiction, says it "belongs to nobody today" and assigns the fix to 05 | **Now, as wording**; the S4 half with CC-6's validator |
| CC-33 | [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md) endpoint table; [`../wall-e/03-lld.md`](../wall-e/03-lld.md); `walle-actions` | **Proposed, conditional on topology decision 44 option (b) — not slipped in.** A list endpoint `GET /v1/plans?state=pending_eve` on `walle-actions`, returning plan ids (and nothing else: no body, no hash) for plans at `pending_eve`, admitted by `READ_CALLER_ALLOWLIST` to `eve-controller@` and `eve-verifier@` only, refused to `eve-console@`, `mo-analyst@` and any operator token (a new denial test). Every id returned is still fetched through `GET /v1/plans/{id}` and treated as a claim. If decision 44 option (a) — `datastore.viewer` under an IAM Condition scoped to Wall-E's `(default)` database — binds and reads, this row is withdrawn unexecuted | Since 2026-09-13 Wall-E's runbook grants no project-level `datastore.viewer` to any Eve identity, so `eve-gate`'s discovery of work ([04-flows.md](04-flows.md) Discovery) has no grant behind it. Decision 44 named two resource-scoped forms and said the endpoint form is a contract change, recorded here rather than assumed. New, from topology decision 44 | Decision 44 before S3 entry; the endpoint, if chosen, before Eve 07 Phase 10 |
| CC-34 | Wall-E's runbook; the in-app control list of `walle-actions-super` | Added 2026-09-13. `roles/run.invoker` on the Cloud Run service `walle-actions-super` for Eve's halt identity, service-level; that service's control list admits it to the halt endpoint and to nothing else; `halt_all` for `log_pipeline_silent` and severity-1 detection rules applies to both lanes | Platform HLD §18 item 25 (the grant, named for `eve-controller@`) and page 07 §7 (the halt, issued by `eve-reconciler`, identity `eve-verifier@`). Which Eve identity holds it is *tbd* for the reconcile pass; the allowlist rule of CC-30 (operators always present) applies to this list too. **Resolved 2026-09-13 (review-findings pass):** Eve's halt identity on `walle-actions-super` is both `eve-controller@` and `eve-verifier@`, halt path only ([../project-topology.md](../project-topology.md) row 27). | The super-admin grant |
| CC-35 | Wall-E's runbook, `walle_audit` dataset access | Added 2026-09-13. Dataset-level `READER` on `walle_audit` for `eve-export@${EVE_PROJECT}` | The daily newline-JSON export with SHA-256 manifests into Eve's locked bucket and the witness (P107) | Wall-E's Stage 1; the witness push before the super-admin grant |
| CC-36 | Wall-E's band-B audit rows | Added 2026-09-13. The audit rows `walle-actions-super` writes for `/v1/execute-generic` and `/v1/handoff` are readable by `eve-verifier@` and `eve-export@` in the same dataset-level form as `walle_audit` (dataset *tbd* on Wall-E's side; `audit.schema`) | Reconciliation over every stream matches robot-attributed events against `walle_audit` **and** the band-B rows; a robot event with neither is `reconciliation_gap` (platform HLD §13.2) | The super-admin grant |
| CC-37 | [`../wall-e/06-security-guardrails.md`](../wall-e/06-security-guardrails.md) Monitoring; the approval surface | Added 2026-09-13. The approval surface emits the signed human assertion Eve's prompt-to-action divergence rule reads ([decision 14](../wall-e/09-open-decisions.md)), and writes `grades_eve` (Eve's verdicts graded) and draws the blind sample for it — never `eve-console` | Detection catalogue ([03-lld.md](03-lld.md) §14); Mo's source rule for Eve quality (platform HLD §13.3) | Wall-E's Stage 1 |

---

## 2. Why the 95 %/95 % line in 05 is the most dangerous row on this page

CC-7 is a two-word edit with the largest consequence, so it gets its own paragraph.

The Stage 3 exit criteria in [`../wall-e/05-autonomy-ladder.md`](../wall-e/05-autonomy-ladder.md)
§7 read, today: *Eve observed ≥ 30 days, agreed with human verdicts ≥ 95 %, and caught ≥ 95 %
of deliberately seeded faults in a chaos exercise.* Both halves were written before anyone
knew what Eve was.

**The seeded-fault half.** The twelve faults in [05-stages.md](05-stages.md) are one per
invariant class: a plan altered after hashing, a pre-state contradicted by Workspace, a level
overclaim, an unknown `config_version`, a `ceilings_sha` mismatch, a protected target, an
out-of-scope target, an uncorroborated T2 trigger, a robot event with no audit row, an audit
row with no admin event, Firestore diverging from the ladder artefact, and a fresh `/healthz`
over a stale table. At 95 % over twelve, one whole class may be undetected and the gate still
passes — and every one of those classes is a hard invariant whose error budget is zero.
Eleven of twelve is not a grade, it is a hole. C12 raised it to 100 % and this design keeps
it there, with **two negative controls** that an always-refusing Eve fails: a group write
verified from current state 20 minutes after execution whose Groups event has not landed
(`verification_deferred_lag`, re-checked, not a fault), and a `protected_principal` denial
arising from a human chat request (an ordinary correct refusal that must not enter Eve's
hard-invariant count). An always-approving Eve fails faults 1 to 8; an always-refusing Eve
fails both negative controls. That pair is what the gate actually measures.

**The agreement half.** Eve is deterministic code. An agreement *rate* against human verdicts
measures neither Eve's correctness nor the human's — where they disagree, exactly one of them
is wrong, and the useful artefact is the root cause of that one case, not a percentage over a
window. Agreement stays in the exit criteria as an **informational** figure, and the rate that
does gate anything is the false-refusal rate in [06-failure-modes.md](06-failure-modes.md),
which is a demotion trigger rather than a promotion gate.

---

## 3. Wall-E's side of this design

Not Eve's to build, and Eve is unbuildable without it. Roughly five engineer-days inside
`walle-actions`, scheduled with Wall-E rather than with Eve, because every one of them is code
in Wall-E's repository:

1. **The two absence sweepers and the passive `eve_last_seen` stamp** (CC-11). `eve_silence`:
   any plan at `pending_eve` for more than four business hours sets `no_autonomous`, origin
   `breaker`, with an incident note. `eve_evidence_stale`: any executed L5 item with no row in
   the `verdict_receipts` view (receipts dataset, separate from `eve` — topology decision 48)
   after 60 minutes freezes promotions, and after four hours drops that
   cell to L4. `eve_last_seen` is stamped from any successfully authenticated `eve-controller@`
   or `eve-verifier@` call — nothing Eve asserts — and published as a metric with a Cloud
   Monitoring **absence** policy at 15 minutes. None of the three has a code path that raises
   anything on Eve's return; only an operator clears `no_autonomous`.
2. **`eve_authority` on the ladder cell and on the override document, and the denial reason
   `eve_authority_advisory`** (CC-4, CC-6).
3. **`items_hash` in the signed field list and per-item vector verification** (CC-1).
4. **Offline pinned-PEM verification as the primary path** (CC-5, section 5).
5. **The `verdict_receipts` read and the plan-lifecycle timer** (CC-11), the read narrowed
   to an existence-only authorised view in the receipts dataset, separate from `eve`
   (topology decision 48).

Items 1 to 4 are in code from the **first commit**, inert. Only item 5's read is wired at S4
entry, and it is the one edit on this page that points a dependency in the direction the set
has otherwise avoided — Wall-E reading something of Eve's. It is kept, narrowed, and
re-argued at S4 entry under [E-17](09-open-decisions.md); the alternative, a new POST endpoint
for Eve's post-hoc verdicts, would amend a contract described as fixed.

---

## 4. What deliberately does not change

Listing these matters as much as listing the edits: a reader who sees thirty-two changes
should be able to see what survived them.

| Unchanged | Why it stays |
|---|---|
| **The eight endpoints** in [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md) | No new endpoint anywhere in this design. A `POST /v1/control/heartbeat` was considered and rejected: it amends a fixed contract, and a liveness signal Eve publishes cannot prove Eve is alive — a wedged Eve that still heartbeats keeps autonomy alive. The replacement is an **absence** shape, CC-11. |
| **Plain authenticated REST, never agent-to-agent** | Eve must be able to stop Wall-E when the model layer is wedged. A safety interlock that runs through a conversation is not an interlock. Eve additionally exposes no inbound surface of its own, so there is no second place this could go wrong. |
| **The three separation rules** | No agent both decides and acts; no agent grades its own work; only humans loosen anything. Every edit above traces to one of them. |
| **03's denial vocabulary stays closed and stays Wall-E's** | CC-4 adds exactly one string to it. Eve's own reason vocabulary (`reasons.yaml`) is a separate, closed vocabulary living in Eve's config repository, and the two never merge — see [03-lld.md](03-lld.md). |
| **[`../wall-e/06-security-guardrails.md`](../wall-e/06-security-guardrails.md)'s CI grep** for forbidden engine methods on "the dispatcher and Eve's caller" | After CC-15 and CC-28 there is no Eve caller of the engine for it to police. The grep stays as a regression guard and finds nothing, which is the correct steady state — a check that would notice the grant coming back. |
| **The `walle-events` topic itself** | Only Eve's subscription goes (CC-13). The topic is not deleted, and the schema C39 asks for is recorded as belonging to whoever later asks for the topic rather than left looking like a gap. |
| **`walle_workspace_logs` and its no-actor-exclusion property** | Eve stops reconciling against it and reconciles against its own sink instead. The standing check that Wall-E's copy still carries no actor exclusion — a drift check on Wall-E, in the direction that has no other watcher — needs a grant no set makes today; topology decision 47 gives it a form (dataset-level `READER` on `walle_workspace_logs` in `WALLE_PROJECT` for `eve-verifier@`, made by Wall-E's runbook, and a data-level comparison against Eve's copy). Until that lands the check is not run. |
| **`walle-protected@`, the committed floor list, and `eve@<domain>`'s membership of both** | Eve's robot is a protected principal and stays one. Its custom role carries read privileges only, at every stage, forever, and there is **no domain-wide delegation anywhere** in either agent. |

---

## 5. The pinned-PEM verification path

CC-5 is small in the table and load-bearing in practice, so it is spelled out here.

`walle-actions` verifies an Eve approval **offline, against a PEM committed in Wall-E's own
repository** at `contracts/eve-public-keys/<version>.pem`, under the same CODEOWNERS as
`ladder.yaml`. Cloud KMS `getPublicKey` cross-project, using `roles/cloudkms.publicKeyViewer`,
is the **fallback** only. The envelope names the full KMS key-version resource name (CC-2),
because a KMS signature carries no version identifier of its own, and the verifier selects the
pinned PEM by that name.

Three properties follow, and none of them holds with a live public-key fetch as the primary
path:

- **No IAM grant inside Wall-E's project can substitute a key.** Changing which key verifies
  an approval requires a merged pull request against a CODEOWNERS-protected path, not a
  binding.
- **A KMS outage does not stop verification.** Verification is a local signature check over
  bytes the service already holds.
- **A destroyed or disabled key version never orphans a stored approval.** Rotation is
  manual — verified 2026-09-12: "Cloud KMS does not support automatic rotation for asymmetric
  keys, because additional steps are required before you can use the new asymmetric key
  version" ([key rotation](https://docs.cloud.google.com/kms/docs/key-rotation)) —
  so it is a dated annual procedure with a 30-day overlap, and old versions are **disabled,
  never destroyed**, inside the 400-day evidence horizon. The archived PEM plus the stored
  signature is the only artefact that proves `walle-actions` did not mint the approval itself.

At S0 the path is exercised with a **CI-only test key**, so the verification code is real and
tested six to eight weeks before a real key exists.

---

## 6. When each edit must land

| Gate | Edits | Why this gate |
|---|---|---|
| **First commit / S0, in code** | CC-2 (column), CC-6 (schema and validator rule), CC-11 (inert), CC-23 | The seams, the audit columns and the stub caller are what let Stage 0 pass without provisioning anything of Eve's. CC-6's validator rule comes forward with them: it is what makes CC-32's resolution enforceable rather than a note in a table. |
| **Before the approve endpoint is built** | CC-1, CC-2, CC-4 (schema), CC-5, CC-6 (enforcement in `walle-actions`; its schema and validator rule land earlier, at the first commit) | Each one changes the bytes that are signed or the strings that are denied. Retrofitting any of them invalidates every approval produced before the retrofit. |
| **Now, as wording** | CC-7, CC-8, CC-10, CC-13, CC-15, CC-16, CC-17, CC-26, CC-32 | Decisions already taken, or readings this design fixes. They cost nothing to land and they are what the next reader inherits. |
| **Before Phase 1** | CC-18 (the decision, not the step) | [Decision 36](../wall-e/09-open-decisions.md) determines what Stage 0 provisions, and Phase 1 is where the provisioning starts. |
| **Before Eve onboarding (S3 entry)** | CC-12, CC-14, CC-19, CC-20, CC-22, CC-24, CC-25, CC-27, CC-28, CC-29, CC-30, CC-31 | The onboarding step is one sitting. Every name, project and scope it uses has to be settled before it opens, because the consent inside it freezes the scope list. |
| **Before S3 exit** | CC-7 | The gate cannot be rewritten while it is being walked through. |
| **S4 entry** | CC-3, CC-9, CC-21, and CC-11's `verdict_receipts` read | Everything that only matters once Eve signs. |
| **Before the super-admin grant** (added 2026-09-13) | CC-34, CC-36, and CC-35's witness half | The observe-and-report layer must halt both lanes and reconcile band B before Wall-E holds Super Admin (platform HLD §0.4, §13.2). |
| **Wall-E's Stage 1** (added 2026-09-13) | CC-35, CC-37 | The daily export and the Eve quality inputs Mo reads (P143 gate for §18 item 17). |

---

## 7. Decisions

Numbered within this set, in the same shape as
[`../wall-e/09-open-decisions.md`](../wall-e/09-open-decisions.md). These are the ones this
page depends on; the full set of twenty is in [09-open-decisions.md](09-open-decisions.md),
which is where each is recorded, and each must also end up as a dated file in
[`../../decisions/`](../../decisions/) the way Wall-E's are.

| # | Decision | Why it matters | Recommendation | Gate | Recorded in |
|---|---|---|---|---|---|
| **E-1** | **Does Eve get its own GCP project?** Answered yes 2026-09-13 as part of the four-project topology ([../project-topology.md](../project-topology.md)); decision file *tbd*. The runbook fixed `SA_EVE = eve-controller@${PROJECT}` until then | While Eve's key lives in Wall-E's project, a project owner can grant themselves `cloudkms.signer` and mint an Eve approval, and the only control is a daily drift row — a detective control on the artefact the whole controller role rests on. It is the root cause of CC-14, CC-16, CC-17, CC-20, CC-24, CC-25, CC-29, CC-30 and CC-31 | **Yes**, extending [decision 18](../wall-e/09-open-decisions.md) and [decision 31](../wall-e/09-open-decisions.md). If the answer is no, the single-project variant still works and pinned-PEM verification still prevents key substitution, but "`walle-actions@` must never mint an Eve approval" reverts to IAM hygiene | **Before Eve onboarding**; the dataset half before Stage 1 | [09-open-decisions.md](09-open-decisions.md) |
| **E-3** | **`items_hash` in the signed field list** | C39's list (`plan_id`, `plan_hash`, `config_version`, expiry, nonce, key version) and C16's per-item vector are incompatible: a signature over `plan_hash` alone cannot authorise a subset, so a tamperer could flip an accept bit outside the signature | Add exactly one field, `items_hash = SHA-256(RFC8785(vector))`, to the signed payload, under `ladder.yaml`'s reviewers | **Before the approve endpoint is built** | [09-open-decisions.md](09-open-decisions.md) |
| **E-4** | **`eve_authority` as a ladder-cell and override field, and the denial reason `eve_authority_advisory`** | E58's demotion of Eve's authority has no storage and no enforcement anywhere in the set, and [03](../wall-e/03-lld.md)'s denial vocabulary is declared closed and defined in one place | One field, `advisory \| binding`, absent reading as advisory; the override may only lower it; the CI validator refuses any config placing a cell at L4 while its authority is advisory. One new non-invariant denial reason | **Before S4**; the schema before the approve endpoint | [09-open-decisions.md](09-open-decisions.md) |
| **E-5** | **Who owns the "Eve down → `no_autonomous`" timer, and the L5 post-hoc demotion?** | Four documents state the outcome; none assigns it | Two deterministic sweepers inside `walle-actions`, keying on the **absence** of work (a plan aged at `pending_eve`; a missing verdict receipt), plus a passively stamped `eve_last_seen` metric with an absence alert. No new endpoint, and no code path that raises on Eve's return. Reject a heartbeat endpoint: a liveness signal Eve publishes cannot prove Eve is alive | **First commit** (inert), wired at S4 | [09-open-decisions.md](09-open-decisions.md) |
| **E-7** | **Eve's halting bias, restated** | 08 item 5's "own judgement" is void under C12; "bias toward halting when uncertain" would make a degraded Eve the outage | At the approval point the conservative act is **refuse** (the plan waits, costing minutes); **halt** is reserved for the closed invariant-trigger list and is never discretionary. Record as an amendment to 08 item 5. 2026-09-13: stands for halting; reporting reopened for the report-only path (P34) — the dated line is on [09-open-decisions.md](09-open-decisions.md) E-7 | With the design record | [09-open-decisions.md](09-open-decisions.md) |
| **E-8** | **Eve's demotion granularity** | 05 §6 says Eve may lower "to any level, including halt"; the `demote` contract takes one `(family, trigger)` | One call per cell, each with its own reason and audit row. A genuinely tenant-wide condition uses `halt`, which is atomic. Name the millisecond-wide seam rather than claiming atomicity that does not exist | With the design record | [09-open-decisions.md](09-open-decisions.md) |
| **E-9** | **Eve's BigQuery grant, which does not exist anywhere in the runbook** | The entire shared data plane of [08](../wall-e/08-team-eve-mo.md) is unbuilt for both Eve and Mo | Dataset-level `bigquery.dataViewer` on `walle_audit` for Eve's identities; `bigquery.jobUser` in **Eve's own** project so job creation and query cost never touch Wall-E's. Never project-level `dataViewer`, which would be a lateral path into Wall-E's project | S3 entry | [09-open-decisions.md](09-open-decisions.md) |
| **E-11** | **The outcome code for an Eve-rejected item** | The contract says rejected items become `skipped_by_operator`; 03's vocabulary is closed; metrics may need to separate Eve rejections from human ones | `skipped_by_operator` with `approver_type: eve`, rather than a new state. A one-line edit to 03, made deliberately | Before S4 | [09-open-decisions.md](09-open-decisions.md) |
| **E-12** | **E18's wording versus E19** | E18 says Eve's only project-level role in Wall-E's project is `datastore.viewer`; E19 grants `agentregistry.viewer`. Both are read-only and both are in the runbook; the wordings cannot both be literally satisfied | Reword E18 as "no project-level role beyond the two named read-only roles, and no write role" | With the design record | [09-open-decisions.md](09-open-decisions.md) |
| **E-17** | **`walle-actions` reading Eve's `verdict_receipts`** | A dependency in the direction the set has otherwise avoided, and a compromised Eve can suppress a demotion by writing false receipts. The alternative — a new POST endpoint for Eve's post-hoc verdicts — would change the 08 contract | Keep the read, narrowed to an existence-only authorized view exposing `(run_id, item, verdict_ts)`, so the service can never branch on content. Re-argue at S4 entry | S4 entry | [09-open-decisions.md](09-open-decisions.md) |
| **E-20** | **`walle-events` schema** | Eve declines the topic; C39 nonetheless asks for a schema with `contract_version` and at-least-once semantics keyed on `event_id` | The schema is the obligation of whoever later asks for the topic — most likely Mo. Record it as not-Eve's rather than leaving it looking like a gap | With Mo's design | [09-open-decisions.md](09-open-decisions.md) |

**Wall-E decisions this page depends on**, none of which it settles:
[5](../wall-e/09-open-decisions.md) (OU allowlist), [11](../wall-e/09-open-decisions.md)
(second operator, second approver, second grader),
[14](../wall-e/09-open-decisions.md) (approval surface — CC-3's `approver_type` is only as
meaningful as the human assertion that surface emits),
[17](../wall-e/09-open-decisions.md) and [31](../wall-e/09-open-decisions.md) (retention floor
and ceiling, and the off-project evidence copy),
[18](../wall-e/09-open-decisions.md) (control-plane split, which lands with the S3 entry step),
[26](../wall-e/09-open-decisions.md) (a keyless service account holding the custom admin role,
which would delete CC-19 and most of CC-18 outright),
[29](../wall-e/09-open-decisions.md) (where a change first executes, and where the seeded-fault
exercise runs), [33](../wall-e/09-open-decisions.md) (Wilson gates, which CC-9 assumes) and
[36](../wall-e/09-open-decisions.md) / [37](../wall-e/09-open-decisions.md) (what Stage 0
provisions; the second reviewer with code ownership, without whom CC-6's CI validator is
reviewed by the person it constrains).

---

## Where to go next

- [README.md](README.md) — the index and the reading order for this set.
- [01-hld.md](01-hld.md) — why the project boundary exists, which is the root of a third of
  this page.
- [03-lld.md](03-lld.md) — the envelope contract whose field list CC-1 and CC-2 amend.
- [05-stages.md](05-stages.md) — the twelve seeded faults and two negative controls CC-7 makes
  the gate.
- [07-build-runbook.md](07-build-runbook.md) — the onboarding step CC-18 moves Phase 15 into.
- [`../wall-e/08-team-eve-mo.md`](../wall-e/08-team-eve-mo.md) — the contract itself. Read it
  and this page together, or the contract reads as buildable and is not.
