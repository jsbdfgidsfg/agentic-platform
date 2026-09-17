# POV 06. Eve over the human super admins

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-17
- Last executed: never
- Stage: POV-1, week 3 (README of this set). Runs after POV [03](03-foundation-folders-logging-and-floors.md) (folders, logging, `ENT_ORG_SINK`, `PAM_ENTITLEMENTS`) and POV [04](04-the-contract-register-agent-ids-and-schemas.md) (`EVE_REGISTER_ROW`). It does **not** wait for POV 05, 07 or 08, except §11, which waits for POV [07](07-the-doer-tier-w-and-the-optional-tier-p.md).
- Step prefix: `PE`. Steps: 52 (PE-1.1a, PE-1.4a, PE-1.6 and PE-9.1a, the run spec and the zero-diff checker of [setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md), are lettered so that no existing id moves). BLOCKED steps: PE-3.4 (PB-02), PE-8.2, PE-9.2, PE-9.3 (with PE-9.2), PE-9.4, PE-9.5, PE-10.4, PE-10.5, PE-11.2 (PB-03). Steps that may record `PENDING`: PE-0.3 and PE-10.3 (reports about the second person, while the third person is not appointed), PE-6.3's self-integrity source, PE-11.1 (waits on POV 07), PE-1.6's two checker lines for the identities PE-9.1 creates (closed by PE-9.1a).
- Full-set counterparts, for depth: [setup/23](../setup/23-eve-project-and-evidence-stores.md) (with setup/17 FM-2.1 to FM-2.22 and FM-4, which EP-2.1 and EP-2.2 call for `EVE_PROJECT`), [setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md), [setup/25](../setup/25-eve-human-super-admin-detections.md), [setup/26](../setup/26-eve-reporting-and-witness-export.md), with the proof of [setup/28](../setup/28-eve-independent-proof-and-sandbox-drills.md) §1 to §3 and Eve v0 of [setup/36](../setup/36-wall-e-joins-to-eve-and-mo.md) §4. The witness organisation ([setup/08](../setup/08-witness-organisation.md), [27](../setup/27-witness-grants-and-alarms.md)) is **not built** (PV-D-03).
- Deviations applied: PV-D-01, PV-D-03, PV-D-04, PV-D-06, PV-D-07, PV-D-10, PV-D-13, PV-D-14. Each is stated in full in [09](09-the-demonstration-deviations-and-the-hand-over.md). Local deviation rows: BD-P06-1 (Login and OAuth streams copied for watched actors only, as the SD-11 record signs; PE-6.1); BD-P06-2 (only if SMS is unavailable: route po rests on email; PE-10.1); BD-P06-3 (`EVE_PROJECT` built by hand to a merged run spec and checked by setup/17's checker, PV-D-01; PE-1.6).
- Decisions applied: PV-08, PV-09, PV-10 (POV [02](02-decisions-people-and-the-retrospective-baseline.md)); inherited unchanged: NAMES, KEYS, SD-11, SD-12, SD-23, SD-43, SD-47.
- Commands checked against Google's documentation on 2026-09-16 (§Sources). What could not be settled is in §Unverified.

## What this part builds

Eve watches the people who hold the tenant's highest privilege, and the person who builds Eve is one of them. So every elevation in this file is approved by the second person, Eve's configuration cannot be changed by the platform owner alone, and Eve's reports about a person never reach that person.

In the POV, Eve is the design's own Eve v0 shape: **BigQuery scheduled queries pinned to a service account and read by a human** (PV-D-06), pointed at two things:

1. **Every human super admin** (the two admin accounts `sa-1-admin@` and `sa-2-admin@`, the break-glass accounts, and any live admin-role holder), from the Workspace audit streams Google itself writes into Cloud Logging. Eve holds **no Workspace credential**: no `eve@`, no OAuth client, no token, no Reports API poll (PV-D-07). What Eve can see is therefore exactly what the tenant's edition shares, and §5 reads that before any detection is written.
2. **The doer's audit** (§11 only), with the twelve Eve v0 queries, once POV 07 has created `DOER_AUDIT_DS`.

What it builds, in order:

| § | Result | Full-set name kept, or the POV record that stands in for it |
|---|---|---|
| 0 | The SD-11 DPO record checked first; nothing else runs without it | SD-11, B-11 |
| 1 | The run spec `factory/runs/eve-prod.json`, merged before the project exists; `EVE_PROJECT` in `fld-controllers-prod` built to it, Vertex AI denied at project level, repair only through a grant the second person approves; setup/17's checker reading `ZERO-DIFF` against it | `EVE_PROJECT`, `ENT_PROJECT_REPAIR_EVE`; the spec is the file setup/23 EP-2.1 names |
| 2 | Key rings `eve` (`europe-west1`) and `eve-eu` (`europe`) with keys `eve-evidence` and `eve-evidence-eu` | SD-47 |
| 3 | Datasets `eve`, `eve_workspace_logs`, `eve_quality` in `EU` with CMEK, one `OWNER` entry each | NAMES |
| 4 | `EVE_EVIDENCE_BUCKET` in `europe-west1`, retention locked with the second person present | SD-23 |
| 5 | The edition-and-coverage record: which streams actually arrive | `WORKSPACE_EDITION` |
| 6 | The organisation sink `eve-workspace-audit`, no actor exclusion | `EVE_SINK` |
| 7 | `eve/config`: thresholds, the detection catalogue as predicates, protected so the platform owner cannot merge alone | `EVE_CONFIG_REPO`, `EVE_CONFIG_COMMIT` |
| 8 | The roster seeded by hand, then diffed from `ASSIGN_ROLE` and `UNASSIGN_ROLE` | `ROSTER_FILE` |
| 9 | `eve-verifier@`, `eve-v0@`, the query set created **disabled**, the absence alarm on the data, the configuration fingerprint recomputed by the second person | `SA_EVE_VERIFIER`, `SA_EVE_V0` |
| 10 | Reporting routes, tested; then the schedules enabled | `NOTIF_CH_EVE_EMAIL_SECOND_HUMAN`; the record is `POV_EVE_FIRST_RUN_RECORD`, never setup/26's `EVE_FIRST_RUN_RECORD` (no witness, PV-D-03) |
| 11 | Eve v0's twelve queries over the doer's audit | `DOER_EVE_V0_CONFIGS` |
| 12 | The unannounced proof, the anti-silencing checks, `POV_EVE_H_LIVE_RECORD` | `POV_EVE_PROOF_RECORD`, `POV_ANTI_SILENCING_RECORD`, `POV_EVE_H_LIVE_RECORD`; never setup/28's `EVE_PROOF_RECORD`, `ANTI_SILENCING_RECORD` or `EVE_H_LIVE_RECORD`, which require the witness |

**What this Eve is not, in this file's own words, and repeated in `POV_EVE_H_LIVE_RECORD`:** detection-grade throughout, never enforcement; inside the reach of the administrators it watches (a super admin can turn off data sharing, and an organisation administrator can remove the project lien); limited to the streams the edition shares and no others; acknowledged in business hours only (PV-D-10); with no custody outside the tenant (PV-D-03). **The word "independent" may not appear in any POV report, record or page about Eve.** The design reserves it for the structural separation of a witness organisation, which the POV does not have (README of this set, forbidden sentence 2).

**Why this scales.** Every resource name here is the full build's: project, rings, keys, datasets, bucket, sink, service accounts, repository, variables. **The records are the exception, and deliberately so:** this file writes `POV_EVE_FIRST_RUN_RECORD`, `POV_EVE_PROOF_RECORD`, `POV_ANTI_SILENCING_RECORD` and `POV_EVE_H_LIVE_RECORD`, never the bare names, because the full set's G1 and G-2 gates (setup/28 EV-8.2, and setup/30 onwards, which start Wall-E only on `EVE_H_LIVE_RECORD`) require witness alarms, a witness copy and a witness fingerprint that the POV does not have (PV-D-03). A POV record never satisfies a full-set gate whose conditions it lacks. setup/26 and setup/28 set the bare names fresh; the hand-over of [09](09-the-demonstration-deviations-and-the-hand-over.md) re-derives them there and never promotes a `POV_` record by renaming it. When the full build reaches [setup/23](../setup/23-eve-project-and-evidence-stores.md), it reads these resources back instead of creating them, and adds what the POV left out: `eve_workspace_reports` and the Reports API poll ([setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md), [25](../setup/25-eve-human-super-admin-detections.md)), `eve@`, the reconciler jobs, the witness and the twin. Nothing here is torn down.

## Preconditions

- [ ] POV 01: `~/.platform-env` sourced, `penv_guard` silent; `BUILD_LOG_DIR`, `EVIDENCE_REGISTER`, `DEVIATION_REGISTER`, `DRILL_CALENDAR`, `EVIDENCE_INTERIM_LOCATION`, `REGION` (`europe-west1`), `BQ_LOCATION` (`EU`), `PLATFORM_REPO_DIR`, `PLATFORM_REPO_REMOTE`; the helpers `penv_set`, `need`, `exists_or_pending`, `checkpoint`, `evidence_add`, `confirm_manual`.
- [ ] POV 02 signed, each printing `SIGNED` from `tools/decision-need.sh`: PV-08, PV-09, PV-10, NAMES, KEYS, SD-11. Integers, never `*tbd*`: `EVIDENCE_RETENTION_DAYS`, `IDENTITY_RETENTION_DAYS`. Set: `SECOND_HUMAN_EMAIL`, `DPO_CONTACT`, `AGENT_ID_EVE`; `SECURITY_REVIEWER_EMAIL` set **or** `*tbd*` (PE-0.3 handles both).
- [ ] POV 03: `ORG_ID`, `SA_1_ADMIN`, `SA_2_ADMIN`, `BRK_GCP_1`, `BRK_GCP_2`, `ROSTER_FILE`, `WORKSPACE_EDITION` (PF-1.1), `BILLING_ACCOUNT_ID`, `FLD_CONTROLLERS_PROD`, `LOGGING_PROJECT`, `PLATFORM_LOGS_VIEWS_DS`, `ENT_ORG_SINK`, `PAM_ENTITLEMENTS`, `WS_SHARING_RECORD`, `KEYS_RECORD`, `NAMES_RECORD`; the effective `gcp.resourceLocations` policy admits both `europe-west1` and `europe`.
- [ ] POV 04: `EVE_REGISTER_ROW` merged (Eve's prod row, tier `CTL`, privilege `none`); `factory/runs/_template.json` and `tools/fm-zero-diff.py` merged (PC-4.2a, PC-4.2b) and the checker proven, `PC-4.2d DONE` in `checkpoints.tsv`; the schema files of PB-02 committed in Eve's repository (POV 04 PC-2.6), or PE-3.4 is BLOCKED.
- [ ] POV 03, for the run spec and the module shape (PE-1.1a, PE-1.4a): `CICD_PROJECT` (the quota project for budget and contact calls), `GRP_PLATFORM_SECURITY`, `BILLING_CURRENCY`, `BOOTSTRAP_BILLING_EXPIRY`, `REGION`; the `fld-controllers-prod` tag bindings of PF-3.4; `TAG_KEY_ENV` where PF-3.3 created `agp-env`. After `BOOTSTRAP_BILLING_EXPIRY`, the billing administrator (`BILLING_ADMIN_EMAIL`, 02) creates the budget. **Not** `AUDIT_DDL_COMMIT`: POV 04 PC-2.4 sets it only once PB-01 (the doer's audit schemas) merges, and Eve over the human super admins never waits on doer code (SD-10). §11 alone reads it, at PE-11.1.
- [ ] POV 03 PF-6.1: a reader of the organisation's Data Access streams holding `roles/logging.privateLogViewer` who is **not** the platform owner: the organisation's Cloud Logging owner, or the second person. POV 03 PF-5.1 defines no log-reading entitlement; if no such reader exists, PE-5.2 stops and POV 03 adds one (approver: the second person). It is never created here, and the platform owner is bound to no identity reader (setup/14 CL-3.2).
- [ ] POV 02's SD-11 record states the **login and OAuth scope** Eve may copy: `watched` (roster accounts and live admin-role holders only, the default) or `all` (every tenant user's sign-in and token metadata, which needs the Subjects field, the retention and the HR or works-council answer to say so explicitly). PE-0.2 reads it; PE-6.1 builds the filter from it.
- [ ] A git host that supports branch protection with code-owner review and no administrator bypass (PE-7.1). `Assumption:` the same host as `PLATFORM_REPO_REMOTE`.
- [ ] **Not** a precondition: any doer, Gemini Enterprise or Mo step. §11 alone waits for POV 07.

## People

| Role | Does | Present at |
|---|---|---|
| Platform owner, as `sa-1-admin@` (person 1) | Writes the files, runs the shell steps, requests every grant. **A subject** of everything built here: approves nothing, verifies nothing about Eve | every step except PE-5.2's stream read, PE-6.3's sign-in scope query and PE-12.2's checks |
| Second person, as `sa-2-admin@` (person 2) | Owns `eve-owners@`; approves every grant on `EVE_PROJECT` and `ENT_ORG_SINK`; required code owner on `eve/config`; present for the bucket lock and the sink creation; recomputes the fingerprint baseline from their own session; reads the Data Access streams (PE-5.2) and the sign-in scope query (PE-6.3) from their own session, because the platform owner is a subject; receives reports about person 1; leads the proof; one of the two approvers of Eve's run spec (SD-12) and the reader of the checker's reports on `EVE_PROJECT` | PE-0.2, PE-1.1, PE-1.1a, PE-1.4a, PE-1.5, PE-1.6, PE-4.4, PE-5.2, PE-6.1, PE-6.2, PE-6.3, PE-7.1 to PE-7.4, PE-9.1a, PE-9.5, PE-10.3, PE-12.1 to PE-12.4 |
| Third person, the security reviewer (person 3) | Receives reports about person 2; second approver on `eve/config` when person 2 is the author. Mandatory from the first Eve report about person 2 (PV-09). Until appointed, that route is `PENDING` | PE-0.3, PE-10.3 |
| DPO (`DPO_CONTACT`) | Holds and confirms the SD-11 record and the retention ceilings | PE-0.2, PE-4.1 |
| ISMS | Named in PV-09 as the owner of the separations; no step | none |

Hands-on: about 3.5 person-days of procedure (POV README). Elapsed: about 2 weeks, set by the DPO record, a 24-hour wait for the first sink tables, the route tests and a proof window that must be genuinely unannounced. The SQL of PB-03 sets the date of §9 onwards.

Conventions of POV [01](01-conventions-and-variables.md) apply unchanged. Deviation rows are `BD-P06-<n>`. Records go to `$BUILD_LOG_DIR/records/` as `<date>-PE-<step>-<slug>-v<n>`. Every shell block starts with:

```bash
source ~/.platform-env
penv_guard
R="$BUILD_LOG_DIR/records/$(date -u +%F)-PE"
```

`Assumption:` `confirm_manual STEP_ID "question"` is POV 01's signature: it refuses a non-interactive terminal and `--yes`, and records the typed identifier in the build log.

## 0. Gates

### PE-0.1 Open the sitting and check the inputs

- **WHO:** Platform owner.
- **WHERE:** Shell, `~/.platform-env` sourced, signed in as `sa-1-admin@`.
- **ACTION:**

```bash
checkpoint PE-0.1 START
need ORG_ID REGION BQ_LOCATION PLATFORM_REPO_DIR PLATFORM_REPO_REMOTE BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER DRILL_CALENDAR EVIDENCE_INTERIM_LOCATION
need SA_1_ADMIN SA_2_ADMIN BRK_GCP_1 BRK_GCP_2 ROSTER_FILE BILLING_ACCOUNT_ID FLD_CONTROLLERS_PROD LOGGING_PROJECT PLATFORM_LOGS_VIEWS_DS ENT_ORG_SINK PAM_ENTITLEMENTS WS_SHARING_RECORD KEYS_RECORD NAMES_RECORD
need WIKI_DIR PLATFORM_ENV_FILE RETIRED_NAMES_CHECK EVE_REGISTER_ROW SECOND_HUMAN_EMAIL DPO_CONTACT AGENT_ID_EVE EVIDENCE_RETENTION_DAYS IDENTITY_RETENTION_DAYS
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-08 PV-09 PV-10 NAMES KEYS SD-11
for v in EVIDENCE_RETENTION_DAYS IDENTITY_RETENTION_DAYS; do case "$(printenv "$v")" in *[!0-9]*|'') echo "STOP: $v not an integer";; *) echo "$v ok";; esac; done
[ "$AGENT_ID_EVE" = eve ] && echo "agent_id eve" || echo "STOP: AGENT_ID_EVE is not eve; the dataset and bucket names below assume it"
"$RETIRED_NAMES_CHECK" "$WIKI_DIR"/platform/agentic-platform/pov/06-*.md && echo "no retired name in this file"
grep -nE '^export (DPO_EMAIL|EVE_FIRST_RUN_RECORD|EVE_H_LIVE_RECORD|EVE_PROOF_RECORD|ANTI_SILENCING_RECORD)=' "$PLATFORM_ENV_FILE" && echo "STOP: a retired name, or a full-set Eve record the POV never sets, is in the variables file" || echo "no retired name in the variables file"
bq --project_id="$LOGGING_PROJECT" ls --format=json "${LOGGING_PROJECT}:${PLATFORM_LOGS_VIEWS_DS}" | jq -r '.[].tableReference.tableId'
```

- **VERIFY:** No `MISSING` and no `STOP` line; six `SIGNED`; two `ok`; `agent_id eve`; `no retired name in this file` and `no retired name in the variables file`. `RETIRED_NAMES_CHECK` already holds an absolute path (POV 01 PP-3.5) and scans the `bash` fences of the markdown files it is given, as POV 01 calls it; the variables file has no fences, so it is checked by the direct `grep` for the retired `DPO_EMAIL` and for the bare full-set Eve records, which the POV never sets (README §7.3). The last listing is recorded: if it holds no view named `eve_self_integrity`, the self-integrity rules of PE-7.3 are committed `blocked` (as [setup/25](../setup/25-eve-human-super-admin-detections.md) EH-2.3 does) and a `PENDING` line is written at PE-6.3.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Output as `${R}-0.1-inputs-v1.txt`; `evidence_add PE-0.1 inputs E-05 1.4.1 build-log:records/ "${R}-0.1-inputs-v1.txt"`. E-05. TISAX 1.4.1.

### PE-0.2 The SD-11 DPO record, before anything exists

- **WHO:** Platform owner reads aloud; **the DPO confirms in writing**; the second person confirms the record covers their own account too.
- **WHERE:** `$PLATFORM_REPO_DIR/decisions/`, the record POV 02 signed under SD-11 and PV-08.
- **ACTION:** Eve processes the activity metadata of **named administrators** from its first query. A personal-data store built before its legal record would have to be deleted, so this step is first and blocking (PV-08; full-set [setup/25](../setup/25-eve-human-super-admin-detections.md) EH-0.2, [setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) EW-0.2). The record must state, at least:

| Field | The POV value |
|---|---|
| Purpose | Detection of misuse of tenant-wide privilege; evidence for the EU AI Act technical documentation and the TISAX pack |
| Data | Admin, Groups Enterprise, Login and, where the edition shares them, OAuth token, SAML and Access Transparency **activity metadata**: actor, time, event name, target, result. **No content.** The subject's address may appear in a Cloud Logging entry of `EVE_PROJECT` when a query reports (§10) |
| Subjects | Every account on `ROSTER_FILE` and every live admin-role holder. **Login and OAuth scope**: `watched` (default: only those accounts' sign-in and token events are copied) or `all` (every tenant user's sign-in and token metadata; valid only when this field names all users, the retention row covers them, and the HR or works-council answer on monitoring ordinary staff is dated in the record) |
| Retention | `eve_workspace_logs` at `IDENTITY_RETENTION_DAYS`; `eve` findings and the locked bucket at `EVIDENCE_RETENTION_DAYS` (PV-10) |
| Recipients | The second person for reports about anyone but themself; the security reviewer for reports about the second person. **Never the subject** |
| Worker information | The date the works council or HR was informed (POV 02) |

```bash
"$PLATFORM_REPO_DIR/tools/decision-need.sh" SD-11 PV-08
REC="$(grep -l -E 'SD-11' "$PLATFORM_REPO_DIR"/decisions/*.md | head -1)"; test -s "$REC" && echo "record: $REC"
grep -n -i -E 'purpose|no content|subjects|retention|recipient|works council|HR' "$REC"
grep -q "$IDENTITY_RETENTION_DAYS" "$REC" && echo "identity retention matches the variable"
penv_set EVE_DPO_RECORD "${REC#"$PLATFORM_REPO_DIR"/}"
SCOPE="$(grep -o -i -E 'login and oauth scope[^a-z]*(watched|all)' "$REC" | grep -o -i -E '(watched|all)$' | tr 'A-Z' 'a-z' | head -1)"
case "$SCOPE" in watched|all) penv_set EVE_LOGIN_SCOPE "$SCOPE"; echo "login and oauth scope: $SCOPE";; *) echo "STOP: the record does not state the login and OAuth scope";; esac
```

- **VERIFY:** `SIGNED` twice; the six fields are present with a date and the DPO's signature; `identity retention matches the variable`; `login and oauth scope: watched` or `all`. Where it is `all`, the DPO confirms in writing that the Subjects field names every tenant user for login and OAuth metadata and that the HR or works-council answer is dated in the record; otherwise the scope is `watched`. The **filter-scope check** is made at PE-6.1 and repeated at PE-6.2: the filter's login and OAuth clauses must be restricted to watched actors unless `EVE_LOGIN_SCOPE` is `all` (`Assumption:` the record carries the scope as a line reading "Login and OAuth scope: watched" or "... all"; if phrased otherwise, the DPO confirms the value and it is typed through `confirm_manual PE-0.2`). Absent or silent on any field: **stop the file**. `checkpoint PE-0.2 BLOCKED - - "SD-11 DPO record (B-11)"`, and nothing in §1 onwards runs.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Record path and the DPO's written confirmation as `${R}-0.2-dpo-record-v1`; `evidence_add PE-0.2 dpo-record E-12 7.1.2 repo:"$EVE_DPO_RECORD"`. E-12. TISAX 7.1.2, 6.1.1.

### PE-0.3 Who receives a report about the second person

- **WHO:** Platform owner reads; the second person confirms.
- **WHERE:** Shell; POV 02's people record (PV-09).
- **ACTION:** Reports about person 1 go to person 2. Reports about person 2 go to person 3, the security reviewer, who must be neither person 1 nor person 2 and not a member of `platform-owners@`. Where person 3 is not yet appointed, the route is recorded `PENDING` with a dated owner, never dropped and never redirected to person 1 (PV-09; [setup/26](../setup/26-eve-reporting-and-witness-export.md) ER-0.2, B-12).

```bash
need SECOND_HUMAN_EMAIL SA_1_ADMIN SA_2_ADMIN
case "${SECURITY_REVIEWER_EMAIL:-}" in
  ''|'*tbd*') exists_or_pending --pending "role:security-reviewer" PE-0.3 "PV-09: appoint person 3; then run PE-10.1 part b, PE-10.2 policy sh and PE-10.3 test sh; until then reports about the second person are PENDING";;
  "$SECOND_HUMAN_EMAIL"|"$SA_1_ADMIN"|"$SA_2_ADMIN") echo "STOP: the security reviewer is a subject of the route";;
  *) echo "route sh -> ${SECURITY_REVIEWER_EMAIL}";;
esac
```

- **VERIFY:** Either `route sh -> <address>` and the second person confirms that address is not theirs, or one `PENDING` line in `rerun-index.tsv` naming PE-0.3 with the platform owner as the owner and a date. The file continues in both cases; PE-10.3 reads the result.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Output as `${R}-0.3-subject-route-v1.txt`. E-08. TISAX 1.6.1, 4.1.3.

## 1. `EVE_PROJECT`

Deviation note: the full set makes this project with the factory module FM-VERIFIER ([setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md)). The POV makes it by hand (**PV-D-01**, [09](09-the-demonstration-deviations-and-the-hand-over.md)), in setup/17's order: the run spec is written from the template and the merged register row and merged under review **before** the project exists (PE-1.1a, FM-2.1), the project is built to it (PE-1.2 to PE-1.5, with the module shape FM-2.3 to FM-2.11 add in PE-1.2, PE-1.4 and PE-1.4a), and `tools/fm-zero-diff.py live` must read `ZERO-DIFF` against it (PE-1.6, then PE-9.1a without `--accept-pending`). What the spec records as `made_elsewhere` is what the module would make that this file makes later or the full build makes; [setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-2.1 finds the spec merged and revises it by a new commit, and EP-2.3's read-back must find nothing the spec does not state.

### PE-1.1a Write and merge the run spec for `EVE_PROJECT`, before the project exists

- **WHO:** Platform owner writes; **two human reviewers who are not the platform owner approve the merge, the second person one of them** (setup/17 FM-2.1, Eve's row: SD-12).
- **WHERE:** Shell, branch `fm-spec-eve-prod`, then the git host.
- **ACTION:** setup/17 FM-2.1 with FM-4's `verifier-project` values, filled from the template (04 PC-4.2a), the merged row (`EVE_REGISTER_ROW`) and NAMES, in FM-1.1's key shape, which the unchanged checker reads. **Where this file builds something, the spec states exactly what this file builds**: the ten labels (PE-1.2), the services of PE-1.4, the project-level `aiplatform` denial of PE-1.3, the lien, `_Default` and `_Trace` routing, budget and contacts that PE-1.2 and PE-1.4a add from FM-2.3 and FM-2.8 to FM-2.11, the repair entitlement of PE-1.5, and the two identities with their one project role each that PE-9.1 creates. Where the POV deliberately does less than FM-VERIFIER, the spec records the POV's real state, never the full build's:

  | Key | Value in the POV | Why |
  |---|---|---|
  | `service_accounts`, `project_bindings` | `eve-verifier`, `eve-v0`, each `roles/bigquery.jobUser` | PE-9.1 creates them; until it runs, two `pending` lines (owner platform owner, re-run PE-9.1a) |
  | `notification_channels` | none | Eve reports only to named individuals (PE-10.1), never to an owners group; FM-2.13's baseline channels are `made_elsewhere` |
  | `project_floor` | `applies: false`, with its reason and a `made_elsewhere` line | `modelarmor.googleapis.com` is not enabled here (PE-1.4) and `aiplatform` is denied (PE-1.3), so no project floor can be written or read; POV 03 PF-8.2's `controllers` folder floor is in force |
  | `project_deny_policies` | none | `deny-eve-project-foreign` (setup/23 EP-1.4, FM-4.3) is not built in the POV: `made_elsewhere` |
  | `entitlements` | `ent-project-repair-eve` | the deploy entitlement and `ent-witness-export-repair` (FM-2.17, FM-4.4) are `made_elsewhere` |
  | `deny_entries`, `pab_bindings` | none | FM-4: no controller principal is in R1 to R5; FM-4.5's PAB belongs to `EVE_ADVISOR_PROJECT` |

  Labels: `data_class` `evidence` (the row's evidence class), `ai_act_class` `minimal` and `recovery_class` `r-k` (the row's `R-K`), `cost_centre` `tbd` (a label cannot hold `*tbd*`), the key spelling POV 03 PF-4.1 used. `run_id` follows setup/17's form with the POV file: `dev-p06-verifier-eve-prod`. The effective tags are read from the parent folder and must equal FM-4's `ctl`.

```bash
source ~/.platform-env
penv_guard
R="$BUILD_LOG_DIR/records/$(date -u +%F)-PE"
need PLATFORM_REPO_DIR PLATFORM_REPO_SLUG EVE_REGISTER_ROW GRP_EVE_OWNERS GRP_PLATFORM_SECURITY FLD_CONTROLLERS_PROD SECOND_HUMAN_EMAIL NAMES_RECORD
grep -qE 'PC-4\.2d[[:space:]]+DONE' "$BUILD_LOG_DIR/checkpoints.tsv" || { echo "STOP: POV 04 PC-4.2d is not DONE; the checker is not proven"; false; }
EP_ID="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES EVE_PROJECT)"; need EP_ID
gcloud projects describe "$EP_ID" --format='value(projectId)' 2>/dev/null && { echo "STOP: $EP_ID exists; the spec comes first (resume rule)"; false; }
checkpoint PE-1.1a START "$SECOND_HUMAN_EMAIL" - "run spec for EVE_PROJECT before the project exists"
RC="${EVE_REGISTER_ROW#*@}"; RC="${RC%%:*}"; need RC
TAGS="$(gcloud resource-manager tags bindings list --parent="//cloudresourcemanager.googleapis.com/folders/${FLD_CONTROLLERS_PROD}" --effective --format=json | jq -c '[.[] | .namespacedTagValue | split("/") | {(.[-2]): .[-1]}] | add // {}')"
echo "$TAGS" | tee "${R}-1.1a-folder-tags-v1.json"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c fm-spec-eve-prod
SPEC="$PLATFORM_REPO_DIR/factory/runs/eve-prod.json"
jq --arg id "$EP_ID" --arg rc "$RC" --arg own "$GRP_EVE_OWNERS" --arg sec "$GRP_PLATFORM_SECURITY" --argjson tags "$TAGS" '
  .module="verifier-project" | .run_id="dev-p06-verifier-eve-prod" | .calling_file_step="POV 06 PE-1.2"
  | .register_row="register/eve.yaml" | .register_commit=$rc | .manifest="eve/agent-manifest.yaml"
  | .agent_id="eve" | .env="prod" | .register_tier="CTL"
  | .project_variable="EVE_PROJECT" | .project_id=$id | .create=true | .parent_folder_variable="FLD_CONTROLLERS_PROD"
  | .labels={"agent":"eve","owner":"eve-owners","tier":"ctl","env":"prod","data_class":"evidence","ai_act_class":"minimal","recovery_class":"r-k","cost_centre":"tbd","created_by":"bootstrap-hand","factory_run":"dev-p06-verifier-eve-prod"}
  | .tags_effective=$tags
  | .services=["bigquery.googleapis.com","bigquerydatatransfer.googleapis.com","cloudkms.googleapis.com","storage.googleapis.com","logging.googleapis.com","monitoring.googleapis.com","iam.googleapis.com","privilegedaccessmanager.googleapis.com","cloudresourcemanager.googleapis.com","observability.googleapis.com"]
  | .service_dependencies=[]
  | .log_routing={"default_bucket":"default-europe-west1","location":"europe-west1","retention_days":30,"trace_bucket":true}
  | .budget={"display_name":($id + "-budget"),"amount":200,"reason_if_not_tier_default":null}
  | .essential_contacts=[{"email":$own,"categories":["SECURITY","SUSPENSION","TECHNICAL","TECHNICAL_INCIDENTS"]},{"email":$sec,"categories":["SECURITY"]}]
  | .service_accounts=["eve-verifier","eve-v0"]
  | .project_bindings=[{"role":"roles/bigquery.jobUser","member":("serviceAccount:eve-verifier@" + $id + ".iam.gserviceaccount.com")},{"role":"roles/bigquery.jobUser","member":("serviceAccount:eve-v0@" + $id + ".iam.gserviceaccount.com")}]
  | .allowed_human_members=[] | .notification_channels=[] | .trigger_sink=null
  | .project_floor={"applies":false,"tier":"controllers","pi_confidence":"HIGH","rai_min":"MEDIUM_AND_ABOVE","vertex_ai":false,"vertex_enforcement":null,"floors_file":"model-armor/floors.json","reason":"modelarmor.googleapis.com is not enabled on EVE_PROJECT (POV 06 PE-1.4) and aiplatform is denied there (PE-1.3), so no project floor can be written or read; the controllers folder floor of POV 03 PF-8.2 is in force"}
  | .deny_entries=[] | .pab_bindings=[]
  | .project_org_policies=[{"constraint":"gcp.restrictServiceUsage","denied":["aiplatform.googleapis.com"]}]
  | .project_deny_policies=[]
  | .entitlements=["ent-project-repair-eve"] | .lien=true
  | .made_elsewhere=[{"item":"key rings eve and eve-eu and their HSM keys","file":"POV 06","step":"PE-2.2, PE-2.3"},
                     {"item":"datasets eve, eve_workspace_logs, eve_quality and their access arrays","file":"POV 06","step":"PE-3.1, PE-3.3"},
                     {"item":"the locked evidence bucket and its retention lock","file":"POV 06","step":"PE-4.2 to PE-4.4"},
                     {"item":"the eve-workspace-audit organisation sink","file":"POV 06","step":"PE-6.2, PE-6.3"},
                     {"item":"Eve report channels to named individuals","file":"POV 06","step":"PE-10.1"},
                     {"item":"the baseline owners email and paging channels of FM-2.13","file":"setup/23","step":"EP-2.2 (setup/17 FM-2.13; PV-D-10)"},
                     {"item":"Model Armor project floor (PF, tier controllers, vertex_ai false)","file":"setup/23","step":"EP-2.2 (setup/17 FM-2.12a)"},
                     {"item":"deny-eve-project-foreign attached at EVE_PROJECT","file":"setup/23","step":"EP-1.4 writes it; EP-2.2 attaches it (setup/17 FM-4.3)"},
                     {"item":"ent-deploy-credential-holder-eve and ent-witness-export-repair","file":"setup/23","step":"EP-2.2 (setup/17 FM-2.17, FM-4.4)"},
                     {"item":"eve_workspace_reports, eve@ and the Reports API poll (PV-D-07)","file":"setup/23, setup/24","step":"EP-4.2; EW-*"},
                     {"item":"PAB for the reporting-path project EVE_ADVISOR_PROJECT","file":"41","step":"deferred with the Eve advisor path, owner Eve owner (setup/17 FM-4.5)"}]
  | .pending=[{"check":"service_accounts.exact","reason":"eve-verifier@ and eve-v0@ are created at PE-9.1, after the first checker run","owner":"platform owner","rerun_in":"POV 06 PE-9.1a"},
              {"check":"iam.spec_bindings_present","reason":"the two roles/bigquery.jobUser bindings are made at PE-9.1","owner":"platform owner","rerun_in":"POV 06 PE-9.1a"}]' \
  "$PLATFORM_REPO_DIR/factory/runs/_template.json" > "$SPEC"
python3.12 -m json.tool "$SPEC" >/dev/null && echo JSON-OK
diff <(jq -r 'keys[]' "$PLATFORM_REPO_DIR/factory/runs/_template.json") <(jq -r 'keys[]' "$SPEC") && echo "KEY-SET EQUALS TEMPLATE"
jq -r '.tags_effective | to_entries[] | "\(.key)=\(.value)"' "$SPEC"
if python3.12 "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" inputs "$SPEC" --report "${R}-1.1a-inputs-v1.json"; then echo "exit=0"; else echo "exit=$?"; fi
jq -r '.results[] | select(.status != "PASS") | "\(.status) \(.check) \(.actual)"' "${R}-1.1a-inputs-v1.json"
git -C "$PLATFORM_REPO_DIR" add factory/runs/eve-prod.json
git -C "$PLATFORM_REPO_DIR" commit -m "factory: run spec dev-p06-verifier-eve-prod before EVE_PROJECT exists (setup 17 FM-2.1; POV 06 PE-1.1a)"
git -C "$PLATFORM_REPO_DIR" push -u origin fm-spec-eve-prod
gh pr create --repo "$PLATFORM_REPO_SLUG" --head fm-spec-eve-prod --title "PE-1.1a run spec eve-prod" --body "setup/17 FM-2.1 and FM-4 values, the POV's real state recorded in made_elsewhere and pending. Inputs report in the build log. Approvers: the second person and one other reviewer, neither the author."
```

  After the merge: `git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only && checkpoint PE-1.1a DONE "$SECOND_HUMAN_EMAIL" "repo:factory/runs/eve-prod.json@$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%h -- factory/runs/eve-prod.json)" "spec merged before the project"`.
- **VERIFY:** `JSON-OK`; `KEY-SET EQUALS TEMPLATE`; the tag lines read `agp-tier=ctl` and `agp-tisax-scope=in`, and `agp-env=prod` where POV 03 created that key (any other value is a stop, repaired in POV 03). `inputs` prints `exit=1` with exactly one non-`PASS` line, `FAIL services.subset_of_folder_allowlist ["cloudresourcemanager.googleapis.com","observability.googleapis.com"]`: two services Google's constraint does not govern, which the unchanged checker's allow-list rule cannot pass (POV 04 PC-4.2d's `PENDING` line); every other check, the row, NAMES, `folders.yaml`, the budget table (200 for `ctl` prod), the label alphabet, `factory_run` and the floor's owner, is `PASS`. Any other non-`PASS` line stops the step. The pull request is merged with two human approvals, the second person's among them, neither the platform owner's, before PE-1.2 runs.
- **ROLLBACK:** Close the pull request; nothing exists in Google Cloud yet.
- **EVIDENCE:** The inputs report, the folder tag read and the merge commit as `${R}-1.1a-run-spec-v1`; `evidence_add PE-1.1a run-spec E-05 1.3.1 build-log:records/ "${R}-1.1a-inputs-v1.json"`. E-05. TISAX 1.3.1 (the asset has an owner and classification before it exists), 5.2.1.

### PE-1.1 `eve-owners@`, owned by the second person

- **WHO:** Platform owner creates; **the second person** becomes owner and confirms from their own session that the platform owner is not an owner.
- **WHERE:** Shell (`gcloud identity groups`).
- **ACTION:**

```bash
need ORG_ID SECOND_HUMAN_EMAIL SA_2_ADMIN
DOMAIN_ORG="$(gcloud organizations describe "$ORG_ID" --format='value(displayName)')"
gcloud identity groups create "eve-owners@${DOMAIN_ORG}" --organization="$ORG_ID" --group-type=security --display-name="eve-owners" --description="Owner of Eve's datasets and configuration. Owned by the second person; the platform owner is never an owner (POV 06 PE-1.1, SD-12)."
gcloud identity groups memberships add --group-email="eve-owners@${DOMAIN_ORG}" --member-email="$SA_2_ADMIN" --roles=OWNER,MEMBER
penv_set GRP_EVE_OWNERS "eve-owners@${DOMAIN_ORG}"
gcloud identity groups memberships list --group-email="$GRP_EVE_OWNERS" --format='table(preferredMemberKey.id,roles[].name)'
```

  If the creating account is added as a member by the create call, it is removed with `gcloud identity groups memberships delete --group-email="$GRP_EVE_OWNERS" --member-email="$SA_1_ADMIN"` after the second person's membership exists.
- **VERIFY:** The listing shows `sa-2-admin@` with `OWNER` and no entry for `sa-1-admin@`; the second person reads the same list from their own session. `Assumption:` the organisation's display name is the primary domain; if not, the domain is typed and recorded.
- **ROLLBACK:** `gcloud identity groups delete "$GRP_EVE_OWNERS"` while nothing references it.
- **EVIDENCE:** Listing as `${R}-1.1-eve-owners-v1.txt`. E-08. TISAX 4.1.1, 4.2.1.

### PE-1.2 Create `EVE_PROJECT` in `fld-controllers-prod`

- **WHO:** Platform owner, under the project-creation grant on `fld-controllers-prod` from `PAM_ENTITLEMENTS`, **approved by the second person**.
- **WHERE:** Shell.
- **ACTION:** The id is read from the signed NAMES record, never typed, and the labels from the merged run spec (PE-1.1a), never typed. Three things are added from setup/17 FM-2.3 and FM-2.6 so that the project is the spec's: `--no-enable-cloud-apis` (without it Google enables its default services, `cloudapis.googleapis.com` and the BigQuery, Dataform, Dataplex, Datastore, Cloud SQL and Trace families among them, which the spec does not name), the ten labels, and the delete lien; then the inherited tags are read, never bound on the project.

```bash
need NAMES_RECORD FLD_CONTROLLERS_PROD BILLING_ACCOUNT_ID EVE_REGISTER_ROW PLATFORM_REPO_DIR
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
SPEC="$PLATFORM_REPO_DIR/factory/runs/eve-prod.json"
git -C "$PLATFORM_REPO_DIR" log --oneline -1 origin/main -- factory/runs/eve-prod.json | grep -q . && echo "run spec merged" || echo "STOP: factory/runs/eve-prod.json is not on main (PE-1.1a)"
EP_ID="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES EVE_PROJECT)"; echo "$EP_ID"
[ "$(jq -r .project_id "$SPEC")" = "$EP_ID" ] && echo "spec id equals NAMES" || echo "STOP: the spec's project_id differs from NAMES"
test -s "$PLATFORM_REPO_DIR/$EVE_REGISTER_ROW" && echo "register row present"
gcloud projects describe "$EP_ID" --format='value(projectId)' 2>/dev/null && echo "STOP: exists; resume rule, verify only"
checkpoint PE-1.2 START "$SECOND_HUMAN_EMAIL" - "irreversible project id"
gcloud projects create "$EP_ID" --folder="$FLD_CONTROLLERS_PROD" --name="eve" --no-enable-cloud-apis --labels="$(jq -r '.labels | to_entries | map("\(.key)=\(.value)") | join(",")' "$SPEC")"
penv_set EVE_PROJECT "$EP_ID"
penv_set EVE_PROJECT_NUMBER "$(gcloud projects describe "$EVE_PROJECT" --format='value(projectNumber)')"
gcloud alpha resource-manager liens create --project="$EVE_PROJECT" --restrictions=resourcemanager.projects.delete --reason="Module-equivalent project $(jq -r .run_id "$SPEC"); deletion only through setup/17 FM-REVOKE" --origin="pov-06-$(jq -r .run_id "$SPEC")"
gcloud billing projects link "$EVE_PROJECT" --billing-account="$BILLING_ACCOUNT_ID"
gcloud resource-manager tags bindings list --parent="//cloudresourcemanager.googleapis.com/projects/${EVE_PROJECT_NUMBER}" --effective --format=json | jq -S '[.[] | .namespacedTagValue | split("/") | {(.[-2]): .[-1]}] | add // {}' > "${R}-1.2-tags-v1.json"
diff "${R}-1.2-tags-v1.json" <(jq -S .tags_effective "$SPEC") && echo "tags equal the spec"
gcloud resource-manager tags bindings list --parent="//cloudresourcemanager.googleapis.com/projects/${EVE_PROJECT_NUMBER}" --format="value(tagValue)"
```

  `--no-enable-cloud-apis` "Enable[s] `cloudapis.googleapis.com` during creation" when omitted ([gcloud projects create](https://docs.cloud.google.com/sdk/gcloud/reference/projects/create), updated 2026-05-27, read 2026-09-16); the services enabled by default on a new project are listed on [Enabled services](https://docs.cloud.google.com/service-usage/docs/enabled-service) (updated 2026-09-09, read 2026-09-16). The lien's flags are the [alpha liens create](https://docs.cloud.google.com/sdk/gcloud/reference/alpha/resource-manager/liens/create) reference's (updated 2026-05-27, read 2026-09-16); `--effective` "Show[s] all effective TagBindings on the resource" ([tags bindings list](https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/tags/bindings/list), updated 2026-05-27, read 2026-09-16).

  > **IRREVERSIBLE as a name.** A project id is never reusable, even after deletion (POV 03's names note; setup/03:584-634). Confirm first: the id equals `decision-value.sh NAMES EVE_PROJECT` and the merged spec's `project_id` (`spec id equals NAMES`); the parent is `fld-controllers-prod`, because a project never moves between tier folders (02-landing-zone-and-tiers.md:240-246); `EVE_REGISTER_ROW` is merged; `PE-1.1a DONE`. Gate: NAMES and PV-08 signed, PE-0.2 `DONE`.
- **VERIFY:** No `STOP`; `run spec merged`; `gcloud projects describe "$EVE_PROJECT" --format='value(parent.type,parent.id)'` prints `folder` and the number of `FLD_CONTROLLERS_PROD`; `diff <(gcloud projects describe "$EVE_PROJECT" --format=json | jq -S .labels) <(jq -S .labels "$SPEC")` prints nothing (exactly the spec's ten labels); `gcloud alpha resource-manager liens list --project="$EVE_PROJECT"` shows one lien restricting `resourcemanager.projects.delete`; `tags equal the spec`, and the direct tag list prints nothing; `gcloud billing projects describe "$EVE_PROJECT" --format='value(billingEnabled)'` prints `True`.
- **ROLLBACK:** **IRREVERSIBLE** as a name. A project created in error is left empty and recorded retired in NAMES by a superseding record.
- **EVIDENCE:** Both reads as `${R}-1.2-project-v1.txt`; `evidence_add PE-1.2 eve-project E-05 5.2.2 build-log:records/`. TISAX 5.2.2, 4.1.3.

### PE-1.3 Deny Vertex AI on the project itself

- **WHO:** Platform owner, under the organisation-policy grant from `PAM_ENTITLEMENTS`, approved by the second person.
- **WHERE:** Shell.
- **ACTION:** Eve holds no model. The denial is set on `EVE_PROJECT`, **never on the controllers folder**, so "Eve has no model" is graded by absence on the project a reviewer looks at ([setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-2.3). `aiplatform.googleapis.com` is on Google's supported list for `gcp.restrictServiceUsage` (read 2026-09-16).

```bash
need EVE_PROJECT
W="$(mktemp -d)"
cat > "$W/rsu.yaml" <<EOF
name: projects/${EVE_PROJECT}/policies/gcp.restrictServiceUsage
spec:
  inheritFromParent: true
  rules:
  - values:
      deniedValues:
      - aiplatform.googleapis.com
EOF
gcloud org-policies set-policy "$W/rsu.yaml"
cp "$W/rsu.yaml" "${R}-1.3-rsu-v1.yaml"; rm -rf "$W"
```

- **VERIFY:** `gcloud org-policies describe gcp.restrictServiceUsage --project="$EVE_PROJECT" --effective --format=yaml` lists `aiplatform.googleapis.com` as denied. Then one real read that must be refused: `gcloud ai models list --project="$EVE_PROJECT" --region="$REGION"`, and the refusal text is recorded. Google states the constraint "controls the runtime access to all in-scope resources" and names the refusal "Request is disallowed by organization's constraints/gcp.restrictServiceUsage constraint" (restricting resource usage, read 2026-09-16); it does not say the constraint blocks turning a service on. So **`gcloud services enable` is never used as the negative test**: if it were not refused, the test itself would enable Vertex AI on Eve's project. A refusal that names the constraint proves the denial; a refusal that says only that the API is not enabled proves the service is off (PE-1.4 checks the same) and the constraint half stays in §Unverified until a refusal naming the constraint is seen.
- **ROLLBACK:** `gcloud org-policies delete gcp.restrictServiceUsage --project="$EVE_PROJECT"`, only on a superseding PV-08.
- **EVIDENCE:** Policy file, effective read and the refused `ai models list` as `${R}-1.3-no-model-v1.txt`. E-05. TISAX 5.2.1.

### PE-1.4 Enable exactly the services Eve needs

- **WHO:** Platform owner, as project creator (the standing owner binding is removed in PE-1.5).
- **WHERE:** Shell.
- **ACTION:** No `admin` (Eve calls no Workspace API, PV-D-07), no `run`, `cloudscheduler`, `secretmanager`, `cloudbuild`, `artifactregistry` (no Eve code runs as a service in the POV, PV-D-06). The list is the merged run spec's, enabled one service per command so that a refusal names the service (setup/17 FM-2.7): the nine this file needs, plus `observability.googleapis.com`, which setup/17 FM-2.9's `_Trace` bucket needs (PE-1.4a). `observability` is not a service `gcp.restrictServiceUsage` governs ([supported services](https://docs.cloud.google.com/resource-manager/docs/organization-policy/restricting-resources-supported-services), updated 2026-09-09, read 2026-09-16), so the `fld-controllers` allow-list neither admits nor refuses it.

```bash
need EVE_PROJECT PLATFORM_REPO_DIR
SPEC="$PLATFORM_REPO_DIR/factory/runs/eve-prod.json"
for S in $(jq -r '.services[]' "$SPEC"); do gcloud services enable "$S" --project="$EVE_PROJECT" || { echo "REFUSED $S"; break; }; done
gcloud services list --enabled --project="$EVE_PROJECT" --format='value(config.name)' | sort | tee "${R}-1.4-services-v1.txt"
jq -r '.services[]' "$SPEC" | sort | comm -23 - "${R}-1.4-services-v1.txt" | tee "${R}-1.4-missing-v1.txt"
jq -r '.services[]' "$SPEC" | sort | comm -13 - "${R}-1.4-services-v1.txt" | tee "${R}-1.4-extra-v1.txt"
grep -E '^(aiplatform|run|cloudscheduler|secretmanager|cloudbuild|artifactregistry|admin)\.' "${R}-1.4-services-v1.txt" && echo "STOP: forbidden service" || echo "no forbidden service"
```

- **VERIFY:** No `REFUSED` line; `missing` is empty (the ten services of the spec are enabled); every name in `extra` is a dependency Google enabled with a spec service, its parent read from that service's page and written beside it in the record, and PE-1.4a adds each to the spec's `service_dependencies` by a reviewed revision (setup/17 FM-2.7); a name that is neither is disabled, never added to the spec; `no forbidden service`.
- **ROLLBACK:** `gcloud services disable <service> --project="$EVE_PROJECT"`.
- **EVIDENCE:** `${R}-1.4-services-v1.txt`. E-05. TISAX 5.2.1.

### PE-1.4a The module shape the spec states: `_Default`, `_Trace`, budget, contacts

- **WHO:** Platform owner, still holding the creator's Owner (removed in PE-1.5 part c). The budget: the platform owner while today is before `BOOTSTRAP_BILLING_EXPIRY`, otherwise the billing administrator. Two reviewers, the second person one of them, merge the dependency revision.
- **WHERE:** Shell; the git host for the revision.
- **ACTION:** setup/17 FM-2.8, FM-2.9, FM-2.10 and FM-2.11, which the run spec states and which PE-1.2 to PE-1.4 do not do, each read from the spec; then FM-2.7's dependencies written into the spec. `_Trace` is created with [setup/10](../setup/10-core-projects-and-ci-identities.md) CP-1.8's REST call, the one POV 03 PF-4.1 used on the core projects, because FM-2.9's `gcloud beta observability buckets create` is not a command: that group holds only `describe`, `list` and `datasets` ([gcloud beta observability buckets](https://docs.cloud.google.com/sdk/gcloud/reference/beta/observability/buckets), updated 2026-05-27, read 2026-09-16). The access token reaches `curl` on standard input, as PE-9.2 does, and is never printed or stored.

```bash
need EVE_PROJECT REGION BILLING_ACCOUNT_ID BILLING_CURRENCY CICD_PROJECT BOOTSTRAP_BILLING_EXPIRY PLATFORM_REPO_DIR PLATFORM_REPO_SLUG SECOND_HUMAN_EMAIL
SPEC="$PLATFORM_REPO_DIR/factory/runs/eve-prod.json"
checkpoint PE-1.4a START "$SECOND_HUMAN_EMAIL" - "module shape: _Default, _Trace, budget, contacts (setup/17 FM-2.8 to FM-2.11)"
RUN_ID="$(jq -r .run_id "$SPEC")"; B="$(jq -r .log_routing.default_bucket "$SPEC")"; L="$(jq -r .log_routing.location "$SPEC")"; D="$(jq -r .log_routing.retention_days "$SPEC")"
# FM-2.8: _Default to a regional bucket; _Required stays global
gcloud logging buckets create "$B" --location="$L" --retention-days="$D" --description="Regional destination of _Default (SD-17, ${RUN_ID})" --project="$EVE_PROJECT"
gcloud logging sinks update _Default "logging.googleapis.com/projects/${EVE_PROJECT}/locations/${L}/buckets/${B}" --log-filter='NOT LOG_ID("cloudaudit.googleapis.com/activity") AND NOT LOG_ID("externalaudit.googleapis.com/activity") AND NOT LOG_ID("cloudaudit.googleapis.com/system_event") AND NOT LOG_ID("externalaudit.googleapis.com/system_event") AND NOT LOG_ID("cloudaudit.googleapis.com/access_transparency") AND NOT LOG_ID("externalaudit.googleapis.com/access_transparency")' --description="Updated the _Default sink to route logs to the ${L} region" --project="$EVE_PROJECT"
# FM-2.9: _Trace in REGION, by setup/10 CP-1.8's REST call
curl -sS --fail-with-body -X POST -H @- -H "Content-Type: application/json" -H "x-goog-user-project: ${EVE_PROJECT}" -d '{}' "https://observability.googleapis.com/v1/projects/${EVE_PROJECT}/locations/${REGION}/buckets?bucketId=_Trace" <<<"Authorization: Bearer $(gcloud auth print-access-token)" | jq -r '.name // .error.message'
# FM-2.10: the project budget, four thresholds
test "$(date -u +%F)" \< "$BOOTSTRAP_BILLING_EXPIRY" || echo "billing roles expired: the billing administrator runs the next two lines"
test "$(gcloud billing accounts describe "$BILLING_ACCOUNT_ID" --format='value(currencyCode)')" = "$BILLING_CURRENCY" || echo "STOP: the billing account's currency changed"
gcloud billing budgets create --billing-account="$BILLING_ACCOUNT_ID" --display-name="$(jq -r .budget.display_name "$SPEC")" --budget-amount="$(jq -r .budget.amount "$SPEC")" --filter-projects="projects/${EVE_PROJECT}" --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0 --threshold-rule=percent=1.0,basis=forecasted-spend --billing-project="$CICD_PROJECT"
# FM-2.11: Essential Contacts
jq -c '.essential_contacts[]' "$SPEC" | while read -r C; do
  gcloud essential-contacts create --email="$(echo "$C" | jq -r .email)" --notification-categories="$(echo "$C" | jq -r '.categories | map(ascii_downcase | gsub("_"; "-")) | join(",")')" --language=en --project="$EVE_PROJECT" --billing-project="$CICD_PROJECT"
done
# FM-2.7: the dependencies PE-1.4 recorded, into the spec by a reviewed revision
X="$(ls -1 "$BUILD_LOG_DIR"/records/*-PE-1.4-extra-v1.txt | tail -n 1)"
if [ -s "$X" ]; then
  git -C "$PLATFORM_REPO_DIR" switch -c fm-spec-eve-prod-dependencies
  jq --rawfile x "$X" '.service_dependencies = ($x | split("\n") | map(select(length > 0)))' "$SPEC" > "$SPEC.new" && mv "$SPEC.new" "$SPEC"
  git -C "$PLATFORM_REPO_DIR" add factory/runs/eve-prod.json && git -C "$PLATFORM_REPO_DIR" commit -m "factory: eve-prod service_dependencies from PE-1.4 (setup 17 FM-2.7)" && git -C "$PLATFORM_REPO_DIR" push -u origin fm-spec-eve-prod-dependencies
  gh pr create --repo "$PLATFORM_REPO_SLUG" --head fm-spec-eve-prod-dependencies --title "PE-1.4a eve-prod service dependencies" --body "Each name with its parent service, from the PE-1.4 record."
fi
```

  Flags as Google's references read on 2026-09-16: [logging buckets create](https://docs.cloud.google.com/sdk/gcloud/reference/logging/buckets/create) and [logging sinks update](https://docs.cloud.google.com/sdk/gcloud/reference/logging/sinks/update) with the filter of [regionalised logs](https://docs.cloud.google.com/logging/docs/regionalized-logs) ("You can't change the `_Required` sink"; updated 2026-09-09); the create method `POST https://observability.googleapis.com/v1/{parent=projects/*/locations/*}/buckets` with the required `bucketId` ([projects.locations.buckets.create](https://docs.cloud.google.com/stackdriver/docs/reference/observability/api/rest/v1/projects.locations.buckets/create), updated 2026-08-24), the bucket id `_Trace` and a 30-day retention that is omitted ([create observability buckets](https://docs.cloud.google.com/trace/docs/create-observability-buckets), updated 2026-09-10); [billing budgets create](https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/create) (`--filter-projects` in the form `projects/{project_id}`, `--threshold-rule` percent 0.0 to 1.0, `basis` `forecasted-spend`; updated 2026-05-27); [essential-contacts create](https://docs.cloud.google.com/sdk/gcloud/reference/essential-contacts/create) (`--language` required; categories `security`, `suspension`, `technical`, `technical-incidents`; updated 2026-05-27). Google's contacts page says the Essential Contacts API must be enabled to manage contacts with gcloud but not on which project ([manage Essential Contacts](https://docs.cloud.google.com/resource-manager/docs/manage-essential-contacts), updated 2026-09-09): the calls name `CICD_PROJECT`, where POV 03 PF-4.1 enabled it, as the quota project. If a create is refused naming the API as disabled on `EVE_PROJECT`, stop: add `essentialcontacts.googleapis.com` to the spec's `services` by a reviewed revision, enable it, and retry, so the spec keeps stating what is enabled.
- **VERIFY:** `gcloud logging sinks describe _Default --project="$EVE_PROJECT" --format="value(destination)"` ends `/locations/europe-west1/buckets/default-europe-west1`, and `_Required`'s ends `/locations/global/buckets/_Required`; setup/10 CP-1.7's routing test (write one entry, read it back from `default-europe-west1`) prints the test text. The REST call prints an operation name, not an error, and `gcloud beta observability buckets list --location="$REGION" --project="$EVE_PROJECT"` lists `_Trace`. `gcloud billing budgets list --billing-account="$BILLING_ACCOUNT_ID" --billing-project="$CICD_PROJECT" --filter="displayName=$(jq -r .budget.display_name "$SPEC")" --format="yaml(amount,budgetFilter.projects,thresholdRules)"` shows one budget of 200, a filter naming only `EVE_PROJECT` (by id or number) and four rules. `gcloud essential-contacts list --project="$EVE_PROJECT" --billing-project="$CICD_PROJECT" --format="table(email,notificationCategorySubscriptions)"` shows exactly the spec's two contacts. The dependency revision is merged with two approvals, the second person's among them, or `extra` was empty.
- **ROLLBACK:** `_Default` pointed back with `gcloud logging sinks update _Default "logging.googleapis.com/projects/${EVE_PROJECT}/locations/global/buckets/_Default" --project="$EVE_PROJECT"`, then the regional bucket deleted; `gcloud billing budgets delete <budget id> --billing-account="$BILLING_ACCOUNT_ID" --billing-project="$CICD_PROJECT"`; `gcloud essential-contacts delete <contact id> --project="$EVE_PROJECT" --billing-project="$CICD_PROJECT"`; the revision reverted. **`_Trace` is IRREVERSIBLE**: no delete is documented and its location cannot be changed. Confirm first: `REGION` is `europe-west1` and the URL names `EVE_PROJECT`; a wrong location is recorded as a dated residency exception.
- **EVIDENCE:** The describes, the routing read-back, the operation name, the budget and contact reads and the revision's merge commit as `${R}-1.4a-module-shape-v1.txt`; `evidence_add PE-1.4a module-shape E-05 5.2.4 build-log:records/ "${R}-1.4a-module-shape-v1.txt"`. E-05, E-06. TISAX 5.2.4, 7.1, 1.3.3, 1.6.1. Then `checkpoint PE-1.4a DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-1.4a-module-shape-v1.txt")"`.

### PE-1.5 The repair entitlement, then no standing human access

- **WHO:** Platform owner writes and creates; **the second person is the only approver** and reads the file before it is created (SD-12).
- **WHERE:** Shell.
- **ACTION:** The full-set name `ENT_PROJECT_REPAIR_EVE` is kept. Every later step of this file runs inside a grant of it.

```bash
need EVE_PROJECT SA_1_ADMIN SECOND_HUMAN_EMAIL
W="$(mktemp -d)"
cat > "$W/ent.yaml" <<EOF
eligibleUsers:
- principals: ["user:${SA_1_ADMIN}"]
privilegedAccess:
  gcpIamAccess:
    resourceType: cloudresourcemanager.googleapis.com/Project
    resource: //cloudresourcemanager.googleapis.com/projects/${EVE_PROJECT}
    roleBindings:
    - role: roles/cloudkms.admin
    - role: roles/bigquery.admin
    - role: roles/storage.admin
    - role: roles/monitoring.editor
    - role: roles/logging.configWriter
    - role: roles/iam.serviceAccountAdmin
    - role: roles/resourcemanager.projectIamAdmin
maxRequestDuration: 7200s
requesterJustificationConfig:
  unstructured: {}
approvalWorkflow:
  manualApprovals:
    requireApproverJustification: true
    steps:
    - approvers:
      - principals: ["user:${SECOND_HUMAN_EMAIL}"]
      approvalsNeeded: 1
EOF
gcloud pam entitlements create ent-project-repair-eve --entitlement-file="$W/ent.yaml" --location=global --project="$EVE_PROJECT"
penv_set ENT_PROJECT_REPAIR_EVE "projects/${EVE_PROJECT}/locations/global/entitlements/ent-project-repair-eve"
cp "$W/ent.yaml" "${R}-1.5-entitlement-v1.yaml"; rm -rf "$W"
gcloud pam entitlements describe ent-project-repair-eve --location=global --project="$EVE_PROJECT" --format='value(state)'
checkpoint PE-1.5a DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-1.5-entitlement-v1.yaml")"
```

  **Part b, the grant proven before any standing access goes** (as POV 03 does for `ENT_PROJECT_REPAIR_CORE`). The platform owner requests; **the second person approves from their own session**; the platform owner confirms `ACTIVE` and that the grant's bindings are really in the project policy; then revokes. Resume point: if the file stops here, `roles/owner` is still present and part b is simply re-run.

```bash
checkpoint PE-1.5b START "$SECOND_HUMAN_EMAIL" - "prove ENT_PROJECT_REPAIR_EVE before removing roles/owner"
gcloud pam grants create --entitlement=ent-project-repair-eve --location=global --project="$EVE_PROJECT" --requested-duration=900s --justification="POV 06 PE-1.5 one-grant proof" --additional-email-recipients="$SECOND_HUMAN_EMAIL"
gcloud pam grants search --entitlement=ent-project-repair-eve --location=global --project="$EVE_PROJECT" --caller-relationship=had-created --format="table(name,state)"
# The second person, signed in as sa-2-admin@ in their own session:
#   gcloud pam grants approve <GRANT_ID> --entitlement=ent-project-repair-eve --location=global --project="$EVE_PROJECT" --reason="POV 06 PE-1.5 proof"
GRANT="$(gcloud pam grants search --entitlement=ent-project-repair-eve --location=global --project="$EVE_PROJECT" --caller-relationship=had-created --filter='state=ACTIVE' --format='value(name)' | head -1)"
test -n "$GRANT" && echo "grant ACTIVE: $GRANT" || echo "STOP: no ACTIVE grant; roles/owner stays"
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json | jq -r --arg m "user:${SA_1_ADMIN}" '.bindings[] | select(.condition != null and (.members|index($m))) | .role' | sort | tee "${R}-1.5-grant-bindings-v1.txt"
gcloud pam grants revoke "$GRANT" --reason="POV 06 PE-1.5 proof complete"
checkpoint PE-1.5b DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-1.5-grant-bindings-v1.txt")"
```

  **Part c, only after part b is `DONE`:**

  > **IRREVERSIBLE as a standing path.** Afterwards only an approved `ENT_PROJECT_REPAIR_EVE` grant, or the organisation-level break-glass path of POV 03, reaches this project. Confirm first: `checkpoints.tsv` holds `PE-1.5b DONE`; `${R}-1.5-grant-bindings-v1.txt` lists the seven roles; the grant's approval names the second person.

```bash
grep -q -E 'PE-1\.5b[[:space:]]+DONE' "$BUILD_LOG_DIR/checkpoints.tsv" && echo "part b done" || { echo "STOP: part b not DONE"; false; }
gcloud projects remove-iam-policy-binding "$EVE_PROJECT" --member="user:${SA_1_ADMIN}" --role=roles/owner
```

- **VERIFY:** Part a: `AVAILABLE`; the second person, from their own session, reads the approver list. Part b: `grant ACTIVE`; the conditional bindings file lists exactly the seven roles of the entitlement; `gcloud pam grants describe "$GRANT" --format='value(state)'` reads a revoked or ended state after the revoke; the Cloud Audit Logs `ApproveGrant` entry names the second person. Part c: `part b done`; `gcloud projects get-iam-policy "$EVE_PROJECT" --flatten='bindings[].members' --filter='bindings.members:user:' --format='value(bindings.role,bindings.members)'` prints nothing.
- **ROLLBACK:** Parts a and b: `gcloud pam entitlements delete ent-project-repair-eve --location=global --project="$EVE_PROJECT"` while `roles/owner` is still present. Part c: **IRREVERSIBLE** as above; restoring standing access needs the organisation-level grant of POV 03 and a deviation row.
- **EVIDENCE:** Entitlement file, the grant-bindings read, the `ApproveGrant` and revoke entries, and the final IAM read as `${R}-1.5-no-standing-access-v1`; `evidence_add PE-1.5 no-standing-access E-08 4.1.3 build-log:records/`. E-08. TISAX 4.1.3.

### PE-1.6 Run the zero-diff checker against `EVE_PROJECT`

- **WHO:** Platform owner runs; **the second person reads the report** and initials the build-log line; the platform owner does not verify their own project.
- **WHERE:** Shell. No `ENT_PROJECT_REPAIR_EVE` grant may be active: an active grant is a conditional `user:` binding in the project policy, which the checker counts as a human member (setup/17 FM-2.19's note).
- **ACTION:** setup/17 FM-2.21 against the merged spec, first without and then with `--accept-pending`, then the deviation row of FM-2.22 in the POV's grammar. This is the first run after PE-1.5 part c removed the creator's Owner; `eve-verifier@` and `eve-v0@` do not exist yet, so the spec's two `pending` lines are expected to print, and nothing else.

```bash
need EVE_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR SECOND_HUMAN_EMAIL SA_1_ADMIN
checkpoint PE-1.6 START "$SECOND_HUMAN_EMAIL" - "setup/17 FM-2.21 on EVE_PROJECT"
grep -q -E 'PE-1\.5b[[:space:]]+DONE' "$BUILD_LOG_DIR/checkpoints.tsv" && echo "PE-1.5 part b done" || echo "STOP: PE-1.5 has not run"
gcloud pam grants search --entitlement=ent-project-repair-eve --location=global --project="$EVE_PROJECT" --caller-relationship=had-created --filter='state=ACTIVE' --format='value(name)' | grep -q . && echo "STOP: an ENT_PROJECT_REPAIR_EVE grant is ACTIVE; revoke it first" || echo "no active repair grant"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
SPEC="$PLATFORM_REPO_DIR/factory/runs/eve-prod.json"
if python3.12 "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" live "$SPEC" --report "${R}-1.6-live-v1.json"; then echo "exit=0"; else echo "exit=$?"; fi
if python3.12 "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" live "$SPEC" --accept-pending --report "${R}-1.6-live-accept-pending-v1.json"; then echo "exit=0"; else echo "exit=$?"; fi
jq -r '.results[] | select(.status != "PASS") | "\(.status) \(.check) \(.pending.owner // "") \(.pending.rerun_in // "")"' "${R}-1.6-live-accept-pending-v1.json"
printf '%s\tPE-1.6\tfm-zero-diff live on EVE_PROJECT: service_accounts.exact and iam.spec_bindings_present PENDING until PE-9.1\tre-run as PE-9.1a without --accept-pending\tPENDING\tplatform owner\n' "$(date -u +%F)" >> "$BUILD_LOG_DIR/rerun-index.tsv"
```

  Then append `BD-P06-3` to `DEVIATION_REGISTER` in setup/17 FM-2.22's `MOD` form and 01 PP-3.1's columns: "verifier-project for `EVE_PROJECT` by hand to `factory/runs/eve-prod.json` (PV-D-01)", the folder and project, `register/eve.yaml` at the spec's `register_commit`, the spec's merge commit, the checker report `${R}-1.6-live-accept-pending-v1.json`, the date PE-1.5 part c removed the creator's Owner, the PAM grants approved by the second person, and the unwind "setup/17 FM-11: `terraform import` plans no change once the spec's `made_elsewhere` items are made by setup/23 and the spec is revised", status `open`.
- **VERIFY:** `PE-1.5 part b done`; `no active repair grant`. The first run prints `DIFF` and `exit=1`, and its only non-`PASS` lines are `PENDING service_accounts.exact` and `PENDING iam.spec_bindings_present`; the second prints `ZERO-DIFF` and `exit=0`, and the listing shows exactly those two lines with owner `platform owner` and re-run `POV 06 PE-9.1a`. In particular `project.labels`, `tags.none_direct`, `services.exact`, `logging.default_route`, `trace.bucket`, `budget`, `essential_contacts`, `iam.no_human_or_basic_role`, `lien`, `orgpolicy.gcp.restrictServiceUsage`, `entitlements` and `floor.not_applicable` read `PASS`. A `FAIL` is repaired under an `ENT_PROJECT_REPAIR_EVE` grant the second person approves, and the checker re-run; it is never resolved by writing the live value into the spec without the step that made it, or by editing the checker. The second person initials the report; `BD-P06-3` is the last row of `DEVIATION_REGISTER`; then `checkpoint PE-1.6 DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-1.6-live-accept-pending-v1.json")" "ZERO-DIFF with two PENDING lines for PE-9.1"`.
- **ROLLBACK:** Read only; the deviation register is append-only (a superseding row).
- **EVIDENCE:** Both reports as `${R}-1.6-live-v1`; `evidence_add PE-1.6 zero-diff E-05 5.2.4 build-log:records/ "${R}-1.6-live-accept-pending-v1.json"`. E-05. TISAX 5.2.4, 1.4.1.

## 2. Key rings and keys (SD-47)

Unchanged from [setup/23](../setup/23-eve-project-and-evidence-stores.md) §3, compressed. A dataset in `EU` "should be protected with a key ring from region `europe`" (BigQuery CMEK, read 2026-09-16), hence two rings. Cloud HSM in `europe` is "multi-tenant only" and in `europe-west1` available (Cloud KMS locations, read 2026-09-16).

### PE-2.1 Read the key table and the location policy

- **WHO:** Platform owner, inside an `ENT_PROJECT_REPAIR_EVE` grant.
- **WHERE:** Shell.
- **ACTION:**

```bash
need EVE_PROJECT KEYS_RECORD
"$PLATFORM_REPO_DIR/tools/decision-need.sh" KEYS SD-47
grep -n -E 'eve-eu|eve-evidence' "$PLATFORM_REPO_DIR/$KEYS_RECORD"
gcloud org-policies describe gcp.resourceLocations --project="$EVE_PROJECT" --effective --format=yaml | tee "${R}-2.1-locations-v1.yaml"
gcloud kms keyrings list --location=europe-west1 --project="$EVE_PROJECT" --format='value(name)'
gcloud kms keyrings list --location=europe --project="$EVE_PROJECT" --format='value(name)'
```

- **VERIFY:** `SIGNED` twice; the key table names `eve`/`europe-west1`/`eve-evidence` and `eve-eu`/`europe`/`eve-evidence-eu`; the location policy admits both locations (a policy admitting only `europe-west1` is a stop, repaired in POV 03, never here); both listings empty.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Outputs as `${R}-2.1-key-precheck-v1.txt`. E-05. TISAX 5.1.1.

### PE-2.2 Ring `eve` and key `eve-evidence` in `europe-west1`

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell.
- **ACTION:**

```bash
need EVE_PROJECT
gcloud kms keyrings create eve --location=europe-west1 --project="$EVE_PROJECT"
penv_set EVE_KEYRING "projects/${EVE_PROJECT}/locations/europe-west1/keyRings/eve"
NEXT_ROT="$(python3 -c "import datetime;print((datetime.datetime.now(datetime.timezone.utc)+datetime.timedelta(days=90)).strftime('%Y-%m-%dT%H:%M:%SZ'))")"
gcloud kms keys create eve-evidence --keyring=eve --location=europe-west1 --purpose=encryption --default-algorithm=google-symmetric-encryption --protection-level=hsm --rotation-period=90d --next-rotation-time="$NEXT_ROT" --destroy-scheduled-duration=30d --labels=class=a,owner-role=eve-owner,store=eve-evidence-bucket --project="$EVE_PROJECT"
penv_set EVE_EVIDENCE_KEY "${EVE_KEYRING}/cryptoKeys/eve-evidence"
```

  > **IRREVERSIBLE.** Key rings cannot be deleted and deleted key names cannot be reused (setup/03:584-634; setup/23 EP-3.3, EP-3.4). Confirm first: ring, key and location match the key table row read in PE-2.1. Gate: KEYS and SD-47 signed, PE-2.1 `DONE`.
- **VERIFY:** `gcloud kms keys describe eve-evidence --keyring=eve --location=europe-west1 --project="$EVE_PROJECT" --format='yaml(purpose,versionTemplate,rotationPeriod,destroyScheduledDuration)'` shows `ENCRYPT_DECRYPT`, `HSM`, `7776000s`, `2592000s`.
- **ROLLBACK:** **IRREVERSIBLE** as names; configuration corrected in place with `gcloud kms keys update`. No key version is ever destroyed while the bucket's retention stands.
- **EVIDENCE:** Describe as `${R}-2.2-eve-evidence-v1.txt`; `evidence_add PE-2.2 eve-evidence-key E-08 5.1.1 build-log:records/`. TISAX 5.1.1, 5.1.2.

### PE-2.3 Ring `eve-eu` and key `eve-evidence-eu` in `europe`

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell.
- **ACTION:** As PE-2.2, with `--location=europe`, ring `eve-eu`, key `eve-evidence-eu`, label `store=eve-datasets`; then `penv_set EVE_KEYRING_EU "projects/${EVE_PROJECT}/locations/europe/keyRings/eve-eu"` and `penv_set EVE_EVIDENCE_KEY_EU "${EVE_KEYRING_EU}/cryptoKeys/eve-evidence-eu"`. The retired pattern of using `EVE_EVIDENCE_KEY` for a dataset is refused (setup/README.md §5).

  > **IRREVERSIBLE.** Confirm first: `BQ_LOCATION` is `EU`; PE-2.1's location policy admitted `europe`. Gate: KEYS and SD-47, PE-2.2 `DONE`.
- **VERIFY:** The same describe as PE-2.2 on `eve-evidence-eu` in `europe`, showing `HSM`; the multi-tenant qualification is noted in the key table, not treated as a failure.
- **ROLLBACK:** **IRREVERSIBLE** as names.
- **EVIDENCE:** `${R}-2.3-eve-evidence-eu-v1.txt`; `evidence_add PE-2.3 eve-evidence-eu-key E-08 5.1.1 build-log:records/`. TISAX 5.1.1, 5.1.2.

### PE-2.4 Grant the two service agents, and nobody else

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell.
- **ACTION:** The BigQuery encryption agent is `bq-PROJECT_NUMBER@bigquery-encryption.iam.gserviceaccount.com`, and it "is not initially created when you create a project. To trigger the creation of your service account, enter a command that uses it", such as `bq show --encryption_service_account --project_id=PROJECT_ID` (BigQuery CMEK, read 2026-09-16). So the address is read from that command, which also creates the agent, and never composed from the project number.

```bash
need EVE_PROJECT EVE_PROJECT_NUMBER
GCS_SA="$(gcloud storage service-agent --project="$EVE_PROJECT")"
BQ_SA="$(bq show --encryption_service_account --project_id="$EVE_PROJECT" --format=json | jq -r '.ServiceAccountID // .serviceAccountId // empty')"
[ "$BQ_SA" = "bq-${EVE_PROJECT_NUMBER}@bigquery-encryption.iam.gserviceaccount.com" ] && echo "bigquery agent ok: $BQ_SA" || { echo "STOP: the encryption agent read back as '${BQ_SA}'"; false; }
gcloud kms keys add-iam-policy-binding eve-evidence --keyring=eve --location=europe-west1 --member="serviceAccount:${GCS_SA}" --role=roles/cloudkms.cryptoKeyEncrypterDecrypter --project="$EVE_PROJECT"
gcloud kms keys add-iam-policy-binding eve-evidence-eu --keyring=eve-eu --location=europe --member="serviceAccount:${BQ_SA}" --role=roles/cloudkms.cryptoKeyEncrypterDecrypter --project="$EVE_PROJECT"
```

- **VERIFY:** `gcloud kms keys get-iam-policy` on each key shows exactly one binding with one member: the Storage agent on `eve-evidence`, the BigQuery agent on `eve-evidence-eu`. No `user:` and no Eve service account. `bigquery agent ok` printed before the binding. `Assumption:` the JSON key of the `bq show --encryption_service_account` output; if neither key is present, the plain output is read and the address typed through `confirm_manual PE-2.4`, still compared with the project number.
- **ROLLBACK:** `remove-iam-policy-binding` with the same arguments, before §3 and §4 create anything.
- **EVIDENCE:** Both policies as `${R}-2.4-key-iam-v1.txt`. E-08. TISAX 5.1.2, 4.2.1.

## 3. Datasets

Three of the full set's four. `eve_workspace_reports` is **reserved and not created**: it holds the Reports API poll, which the POV does not run (PV-D-07). The full build creates it in [setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-4.2 as an addition to this project.

### PE-3.1 Create `eve`, `eve_workspace_logs`, `eve_quality`

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell.
- **ACTION:** Names read from NAMES. `eve_workspace_logs` gets its partition expiry **now**, because the sink in §6 creates its own tables and an expiry set later never binds them ([setup/23](../setup/23-eve-project-and-evidence-stores.md) §4).

```bash
need EVE_PROJECT BQ_LOCATION EVE_EVIDENCE_KEY_EU IDENTITY_RETENTION_DAYS
for v in EVE_DS EVE_WS_LOGS_DS EVE_QUALITY_DS; do penv_set "$v" "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES "$v")"; done
[ "$EVE_DS/$EVE_WS_LOGS_DS/$EVE_QUALITY_DS" = "eve/eve_workspace_logs/eve_quality" ] || echo "STOP: NAMES differs from the fixed names"
bq --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" mk --dataset --default_kms_key="$EVE_EVIDENCE_KEY_EU" --label=agent:eve --label=env:prod --label=data_class:evidence --description="Eve's own rows: findings, incidents, pages. Ids and event names only, no content (POV 06)." "${EVE_PROJECT}:${EVE_DS}"
bq --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" mk --dataset --default_kms_key="$EVE_EVIDENCE_KEY_EU" --default_partition_expiration=$(( IDENTITY_RETENTION_DAYS * 86400 )) --label=agent:eve --label=env:prod --label=data_class:record --description="Destination of the eve-workspace-audit organisation sink (POV 06 PE-6.2)." "${EVE_PROJECT}:${EVE_WS_LOGS_DS}"
bq --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" mk --dataset --default_kms_key="$EVE_EVIDENCE_KEY_EU" --label=agent:eve --label=env:prod --label=data_class:record --description="Authorised views over eve for Mo. Views only." "${EVE_PROJECT}:${EVE_QUALITY_DS}"
```

  > **IRREVERSIBLE** as names and locations: a dataset cannot be renamed or moved. Confirm first: no `STOP`; `EVE_EVIDENCE_KEY_EU` is the `europe` key. Gate: NAMES, PV-10, PE-2.3 `DONE`.
- **VERIFY:** For each dataset, `bq show --format=prettyjson` gives location `EU`, the `eve-evidence-eu` key, no default table expiry; `eve_workspace_logs` alone carries `defaultPartitionExpirationMs = IDENTITY_RETENTION_DAYS * 86400000`. `NO-CMEK` is a stop: drop while empty and re-create.
- **ROLLBACK:** `bq --project_id="$EVE_PROJECT" rm -d "${EVE_PROJECT}:<dataset>"` while empty (no `-r`).
- **EVIDENCE:** `${R}-3.1-datasets-v1.txt`; `evidence_add PE-3.1 eve-datasets E-07 7.1.2 build-log:records/`. TISAX 7.1.2, 5.1.2.

### PE-3.2 Prove the expiry and the key bind a table created later

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell.
- **ACTION:** [setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-4.3 unchanged: create `_expiry_probe` partitioned on `timestamp` in `eve_workspace_logs`, read `timePartitioning.expirationMs` and `encryptionConfiguration.kmsKeyName`, drop it, and list the dataset.
- **VERIFY:** The probe shows `IDENTITY_RETENTION_DAYS * 86400000` and the `eve-evidence-eu` key; the final listing is empty.
- **ROLLBACK:** The probe is dropped in the same block.
- **EVIDENCE:** `${R}-3.2-expiry-probe-v1.txt`. E-07. TISAX 7.1.2.

### PE-3.3 Cut every access array to one `OWNER` entry

- **WHO:** Platform owner, inside the grant; the second person reads the result.
- **WHERE:** Shell.
- **ACTION:** A new dataset carries the three `project*` special groups and **the creator as `OWNER`**, and the creator is the account Eve watches. BigQuery refuses a dataset with no `OWNER`, so each array becomes exactly `[{"role":"OWNER","groupByEmail":"<GRP_EVE_OWNERS>"}]`, written with the etag-checked `eve_ds_access` function of [setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-4.4, copied unchanged into `$PLATFORM_REPO_DIR/eve/tools/eve_ds_access.sh`, together with [setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) EW-1.6's additive, guarded form renamed `eve_ds_access_add DATASET MEMBER ROLE`, and merged under the second person's review before this step.

```bash
need EVE_PROJECT GRP_EVE_OWNERS
. "$PLATFORM_REPO_DIR/eve/tools/eve_ds_access.sh"
BASELINE="$(jq -nc --arg g "$GRP_EVE_OWNERS" '[{role:"OWNER", groupByEmail:$g}]')"
for DS in "$EVE_DS" "$EVE_WS_LOGS_DS" "$EVE_QUALITY_DS"; do eve_ds_access "$DS" "$BASELINE" || break; done
```

- **VERIFY:** Three `ACCESS MATCHES` lines; each array reads back as exactly one `OWNER` entry for `eve-owners@`: no `specialGroup`, no `userByEmail`.
- **ROLLBACK:** The same function with the recorded `before.json` array.
- **EVIDENCE:** Before and read-back files; `evidence_add PE-3.3 dataset-access E-08 4.2.1 build-log:records/`. TISAX 4.2.1.

### PE-3.4 Eve's three tables, from committed schemas (**BLOCKED on PB-02**)

- **WHO:** Platform owner, inside the grant; the second person reviewed the schema merge.
- **WHERE:** Shell; a clone of **Eve's repository** at `EVE_REPO_DIR` (a sitting-local path recorded in the build log, not a variable of `~/.platform-env`, as [setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-5.2 treats it), at `EVE_SCHEMAS_COMMIT`.
- **ACTION:** > **BLOCKED**: needs PB-02, Eve's `findings`, `incidents` and `pages` schema files, committed in **Eve's repository** under `schemas/` as `schemas/eve_findings.json`, `schemas/eve_incidents.json` and `schemas/eve_pages.json`, the paths setup/23 EP-5.3 reads and EP-5.2's gate list names, by POV 04 PC-2.6 (a subset of B-07; `Assumption:` 1 to 2 engineer-days). Gate that waits: PE-9.2, and so Eve's first run. Until then: `checkpoint PE-3.4 BLOCKED - - "PB-02 eve schemas"`.

  Precondition check, before anything: POV 04 PC-2.6 is `DONE` in `checkpoints.tsv` and Eve's repository exists; this file never creates the schema files or the repository. When unblocked, taking the commit from that repository's `origin/main`, as setup/23 EP-5.2 does, so the full build finds the same files and writes no second set:

```bash
need EVE_PROJECT EVE_DS BQ_LOCATION EVIDENCE_RETENTION_DAYS
test -d "${EVE_REPO_DIR:-}/.git" || { echo "STOP: EVE_REPO_DIR is not a clone of Eve's repository; PE-3.4 stays BLOCKED"; false; }
grep -q -E 'PC-2\.6[[:space:]]+DONE' "$BUILD_LOG_DIR/checkpoints.tsv" || { echo "STOP: POV 04 PC-2.6 not DONE"; false; }
git -C "$EVE_REPO_DIR" fetch origin
C="$(git -C "$EVE_REPO_DIR" rev-parse origin/main)"
T="$(mktemp -d)"; git -C "$EVE_REPO_DIR" archive "$C" schemas | tar -x -C "$T"
for TB in findings incidents pages; do test -s "$T/schemas/eve_${TB}.json" || { echo "STOP: schemas/eve_${TB}.json absent at $C"; false; }; done && penv_set EVE_SCHEMAS_COMMIT "$C"
for TB in findings incidents pages; do bq --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" mk --table --time_partitioning_field=ts --time_partitioning_type=DAY --time_partitioning_expiration=$(( EVIDENCE_RETENTION_DAYS * 86400 )) --require_partition_filter=false "${EVE_PROJECT}:${EVE_DS}.${TB}" "$T/schemas/eve_${TB}.json" || break; done
rm -rf "$T"
```

  `EVE_SCHEMAS_COMMIT` here covers the POV's three files only; setup/23 EP-5.2 re-derives it when all eight `eve23` files are present. Every schema carries `agent_id`, `subject`, `rule_id`, `eve_config_version` and `query_hash` (05-registry-and-autonomy-contract.md §9.3).
- **VERIFY:** When unblocked: three tables, each partitioned on `ts` with the evidence expiry and the inherited `eve-evidence-eu` key; `bq show --schema` equals the file at `EVE_SCHEMAS_COMMIT` in Eve's repository.
- **ROLLBACK:** `bq rm -t` while empty.
- **EVIDENCE:** The BLOCKED line; then `${R}-3.4-tables-v1.txt`. E-06. TISAX 5.2.4.

## 4. The locked evidence bucket

[setup/23](../setup/23-eve-project-and-evidence-stores.md) §7, compressed. The POV bucket holds Eve's weekly finding extracts and the recorded proof; the doer's `ladder/` prefix grant is made by POV 07 later, which a locked bucket still allows.

### PE-4.1 Refuse without the signed ceiling and the second person

- **WHO:** Platform owner; **the second person confirms in writing** they will be present for PE-4.4; the DPO's signature is read on the record.
- **WHERE:** Shell.
- **ACTION:** The lock value equals the evidence ceiling, because a locked policy can never be reduced (PV-10; setup/03:560-580).

```bash
need EVE_PROJECT EVIDENCE_RETENTION_DAYS EVE_EVIDENCE_KEY
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-10 SD-23
test "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-10 EVIDENCE_RETENTION_DAYS)" = "$EVIDENCE_RETENTION_DAYS" && echo "lock value matches the signed ceiling"
TPL="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES EVE_EVIDENCE_BUCKET)"
penv_set EVE_EVIDENCE_BUCKET "${TPL//<EVE_PROJECT>/$EVE_PROJECT}"
penv_set EVE_EVIDENCE_LOCATION europe-west1
```

- **VERIFY:** `SIGNED` twice; `lock value matches the signed ceiling`; the bucket name is the NAMES template expanded, beginning `gs://`; the second person's dated confirmation is in the build log. Any miss: §4 stops; §5 onwards may continue.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-4.1-retention-gate-v1.txt`. E-06. TISAX 7.1.1.

### PE-4.2 Create the bucket and read back every immutable property

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell.
- **ACTION:**

```bash
need EVE_PROJECT EVE_EVIDENCE_BUCKET EVE_EVIDENCE_LOCATION EVE_EVIDENCE_KEY
gcloud storage buckets create "$EVE_EVIDENCE_BUCKET" --project="$EVE_PROJECT" --location="$EVE_EVIDENCE_LOCATION" --default-encryption-key="$EVE_EVIDENCE_KEY" --uniform-bucket-level-access --public-access-prevention --default-storage-class=STANDARD
gcloud storage buckets describe "$EVE_EVIDENCE_BUCKET" --raw --format="json(location,encryption,iamConfiguration,retentionPolicy)" | tee "${R}-4.2-bucket-raw-v1.json"
```

  > **IRREVERSIBLE as a name and a location.** Confirm first: location `europe-west1` (SD-23); key `eve-evidence`, **not** `eve-evidence-eu`. Gate: NAMES, SD-23, PE-4.1 `DONE`.
- **VERIFY:** `EUROPE-WEST1`; the `eve-evidence` key; uniform access `true`; public access prevention `enforced`; no retention policy yet. Any miss: delete the empty bucket now, the last moment that is possible.
- **ROLLBACK:** `gcloud storage buckets delete "$EVE_EVIDENCE_BUCKET"` while empty and before PE-4.3 sets retention.
- **EVIDENCE:** `${R}-4.2-bucket-raw-v1.json`. E-07. TISAX 7.1.2, 5.1.2.

### PE-4.3 Prove create-only, empty the bucket, set retention unlocked

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell.
- **ACTION:** [setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-7.4 then EP-7.5: write one probe object, read its key, check that `roles/storage.objectCreator` holds `storage.objects.create` and neither `storage.objects.delete` nor `storage.objects.update`, remove the probe, confirm the bucket is empty, then:

```bash
gcloud storage buckets update "$EVE_EVIDENCE_BUCKET" --retention-period="P${EVIDENCE_RETENTION_DAYS}D"
gcloud storage buckets describe "$EVE_EVIDENCE_BUCKET" --raw --format="value(retentionPolicy.retentionPeriod,retentionPolicy.isLocked)"
```

- **VERIFY:** The probe carried the `eve-evidence` key; `objectCreator` cannot delete or overwrite; the bucket was empty before retention; the read-back is `EVIDENCE_RETENTION_DAYS * 86400` and not locked.
- **ROLLBACK:** `gcloud storage buckets update "$EVE_EVIDENCE_BUCKET" --clear-retention-period` while unlocked.
- **EVIDENCE:** `${R}-4.3-create-only-and-retention-v1.txt`. E-06, E-08. TISAX 7.1.1, 4.2.1.

### PE-4.4 Lock the retention policy (**IRREVERSIBLE**)

- **WHO:** Platform owner runs the command; **the second person is physically present**, reads the confirmation aloud, watches the bucket name, and countersigns. Last command of the sitting.
- **WHERE:** Shell, inside the grant.
- **ACTION:**

  > **IRREVERSIBLE.** "Locking a bucket is an irreversible action": the policy cannot be removed and the period cannot be decreased; "Cloud Storage automatically applies a lien on the project" (Bucket Lock, read 2026-09-16). Every object written cannot be deleted before `EVIDENCE_RETENTION_DAYS`. **Confirm aloud, with the second person watching:** (1) PE-4.1 printed `lock value matches the signed ceiling` and the DPO signed PV-10; (2) PE-4.2 read `EUROPE-WEST1` and the `eve-evidence` key; (3) PE-4.3 read the right period, unlocked; (4) the name on screen is `EVE_EVIDENCE_BUCKET`. **Gate:** PV-10 and SD-23 signed, PE-4.3 `DONE`, the second person's name in the checkpoint witness column.

```bash
need EVE_EVIDENCE_BUCKET EVIDENCE_RETENTION_DAYS SECOND_HUMAN_EMAIL
checkpoint PE-4.4 START "$SECOND_HUMAN_EMAIL" - "lock ${EVE_EVIDENCE_BUCKET} at ${EVIDENCE_RETENTION_DAYS}d; second person present"
gcloud storage buckets update "$EVE_EVIDENCE_BUCKET" --lock-retention-period
gcloud storage buckets describe "$EVE_EVIDENCE_BUCKET" --raw --format="value(retentionPolicy.isLocked,retentionPolicy.retentionPeriod)" | tee "${R}-4.4-lock-v1.txt"
gcloud alpha resource-manager liens list --project="$EVE_PROJECT" --format="table(name,origin,reason)" | tee -a "${R}-4.4-lock-v1.txt"
checkpoint PE-4.4 DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-4.4-lock-v1.txt")"
```

  The command prompts; the platform owner answers it with the second person watching. No `--quiet`, no `--yes`.
- **VERIFY:** `True` and `EVIDENCE_RETENTION_DAYS * 86400`; a lien whose origin names Cloud Storage. An empty read is **not** a reason to re-run: read the console at Cloud Storage > Buckets > the bucket > Protection.
- **ROLLBACK:** **IRREVERSIBLE. There is none.** The lien can still be removed by an owner or organisation administrator; that is a control failure, alerted by PE-4.5.
- **EVIDENCE:** `${R}-4.4-lock-v1.txt`; `evidence_add PE-4.4 retention-lock E-06 7.1.1 build-log:checkpoints.tsv`. TISAX 7.1.1, 1.4.1.

### PE-4.5 Alert on lien removal, bucket IAM and retention change

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell.
- **ACTION:** [setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-7.10's log-based policy, unchanged, created **with no channel** now and attached to the second person's channels at PE-10.2. Structure per Google's log-based alerts page (read 2026-09-16): `conditionMatchedLog`, `notificationRateLimit.period`, `autoClose` at least 1,800 s.
- **VERIFY:** The policy is listed and enabled; `gcloud logging read` over `protoPayload.methodName:"Lien"` in `EVE_PROJECT` returns PE-4.4's lien creation, proving the filter matches a real entry.
- **ROLLBACK:** `gcloud monitoring policies delete <policy> --project="$EVE_PROJECT"`.
- **EVIDENCE:** `${R}-4.5-protection-alert-v1.txt`. E-08. TISAX 1.6.1, 5.2.4.

## 5. Edition and coverage, before any detection

### PE-5.1 Read the edition and the sharing switch

- **WHO:** Platform owner reads; the second person reads the same two screens from their own session.
- **WHERE:** Admin console: Menu > Billing > Subscriptions (the edition); Menu > Account > Account settings > Legal and compliance > Sharing options (super administrators only; share data with Google Cloud services, read 2026-09-16).
- **ACTION:** Record the edition exactly as the console names it, and whether sharing is Enabled, with the UTC time. Compare with `WS_SHARING_RECORD` from POV 03.

```bash
confirm_manual PE-5.1 "Type the Workspace edition exactly as Menu > Billing > Subscriptions shows it"
need WORKSPACE_EDITION
printf 'Edition, as typed above: '; read -r WORKSPACE_EDITION_READ
[ "$WORKSPACE_EDITION" = "$WORKSPACE_EDITION_READ" ] && echo "edition matches the variable" || echo "STOP: WORKSPACE_EDITION differs from the console"
confirm_manual PE-5.1 "Type Enabled or Disabled for Share data with Google Cloud services"
```

- **VERIFY:** `WORKSPACE_EDITION`, set by POV 03 PF-1.1 and only compared here (this file never sets it), matches what both readers typed; sharing `Enabled`. `Disabled` stops the file: turning it on is POV 03's step and a super-admin act Eve then reports.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Two screenshots (no personal data beyond the edition) as `${R}-5.1-edition-and-sharing-v1` in `EVIDENCE_INTERIM_LOCATION`. E-06. TISAX 5.2.4.

### PE-5.2 Read which streams actually arrive, and write `EVE_EDITION_COVERAGE_RECORD`

- **WHO:** **The second person, from their own session** (or the organisation's Cloud Logging owner of POV 03 PF-6.1), holding `roles/logging.privateLogViewer`, which the Login and OAuth Data Access streams need. **Never the platform owner**: a subject must not be the one who reads sign-ins (setup/14 CL-3.2). The platform owner receives only the TSV below, which holds service and log names and no actor, and writes the coverage record from it; the second person countersigns.
- **WHERE:** Shell of the reader, not the platform owner's.
- **ACTION:** Google shares Groups Enterprise, Admin and User (login) events on every edition, OAuth and SAML events only on Enterprise Standard/Plus, Education Standard/Plus, Voice Premier or Cloud Identity Premium, and Access Transparency only on Enterprise Plus and Education (share data with Google Cloud services, updated 2026-09-10, read 2026-09-16; also 08-data-logging-retention-sovereignty.md:387). Workspace audit logs sit at the organisation level; their region cannot be chosen and they are not covered by the Workspace Data Region Policy (Google Workspace audit logs page, read 2026-09-16). **A stream is covered only when an entry has been seen.**

```bash
need ORG_ID WORKSPACE_EDITION SA_1_ADMIN
gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -qix "$SA_1_ADMIN" && { echo "STOP: the platform owner may not run this read"; false; }
gcloud organizations get-iam-policy "$ORG_ID" --flatten='bindings[].members' --filter='bindings.role=roles/logging.privateLogViewer' --format='value(bindings.members)' | tee "${R}-5.2-private-log-readers-v1.txt"
grep -qi "user:${SA_1_ADMIN}" "${R}-5.2-private-log-readers-v1.txt" && echo "STOP: the platform owner holds privateLogViewer at the organisation; POV 03 removes it" || echo "platform owner is no identity reader"
for S in admin.googleapis.com cloudidentity.googleapis.com login.googleapis.com oauth2.googleapis.com; do
  N="$(gcloud logging read "protoPayload.serviceName=\"${S}\"" --organization="$ORG_ID" --freshness=7d --limit=5 --format='value(logName)' | sort -u | tr '\n' ' ')"
  printf '%s\t%s\n' "$S" "${N:-NOT SEEN}"
done | tee "${R}-5.2-streams-v1.tsv"
gcloud logging read 'logName:"cloudaudit.googleapis.com%2Faccess_transparency"' --organization="$ORG_ID" --freshness=30d --limit=1 --format='value(logName)' | tee -a "${R}-5.2-streams-v1.tsv"
```

  Then write `$PLATFORM_REPO_DIR/eve/coverage/<date>-edition-coverage.md`: the edition; one row per stream with `seen`, `not shared by this edition` or `shared but not seen`; the consequence of each gap (no OAuth token stream: a new third-party grant to an admin account is invisible to Eve; no SAML: SSO sign-ins invisible; no Access Transparency: Google staff access invisible); and the unwind, which is PV-D-07's: add the Reports API poll to this project, reopening B-10. Merge it under the second person's review and `penv_set EVE_EDITION_COVERAGE_RECORD "eve/coverage/<date>-edition-coverage.md"`.
- **VERIFY:** No `STOP`; `platform owner is no identity reader`; the reader holds `roles/logging.privateLogViewer` directly or through a group (if nobody but the platform owner could run this read, **stop**: POV 03 PF-6.1 adds the reader, never this file). `admin`, `cloudidentity` and `login` are `seen` (on every edition these are shared; one not seen is a **stop**: sharing, or POV 03's logging, is broken). A stream the edition shares but that was not seen in 7 days is a stop until explained, never a residual. The record is merged and countersigned. **No rule in PE-7.3 may name a stream this record does not mark `seen`.**
- **ROLLBACK:** Read only; the record is superseded, not edited.
- **EVIDENCE:** `${R}-5.2-streams-v1.tsv` and the merged record; `evidence_add PE-5.2 edition-coverage E-06 5.2.4 repo:"$EVE_EDITION_COVERAGE_RECORD"`. TISAX 5.2.4.

## 6. The organisation sink

### PE-6.1 Merge the sink filter as a file

- **WHO:** Platform owner writes; **the second person is the required reviewer**.
- **WHERE:** `$PLATFORM_REPO_DIR/eve/workspace-audit-filter.txt`.
- **ACTION:** [setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) EW-1.2's filter, with the clauses cut to the services PE-5.2 marked `seen` or `shared`, and **scoped to what the SD-11 record signed** (PE-0.2, `EVE_LOGIN_SCOPE`):

  - `admin.googleapis.com`, `cloudidentity.googleapis.com` and Access Transparency stay **unrestricted**. No actor exclusion: the administrators' events, including a new role assignment to anyone, are what Eve exists to see.
  - `login.googleapis.com` and `oauth2.googleapis.com` are copied **only for watched actors** when `EVE_LOGIN_SCOPE=watched` (the default), because the record's Subjects are the roster and live admin-role holders, not every employee. Only when `EVE_LOGIN_SCOPE=all` does the filter take setup/24 EW-1.2's unrestricted form. This is deviation row **BD-P06-1** in `DEVIATION_REGISTER` (the full set's filter copies every user's sign-ins; the POV copies only what its DPO record covers); it unwinds when a superseding SD-11 record names all users, by `gcloud logging sinks update` under an `ENT_ORG_SINK` grant. It is not a PV-D row because it is a data-protection scope, not a demonstration shortcut; file 09's hand-over should carry it.

  The watched list `eve/watched-actors.txt` (one address per line, no other data) is `SA_1_ADMIN`, `SA_2_ADMIN`, `BRK_GCP_1`, `BRK_GCP_2`, every account on `ROSTER_FILE`, and every current admin-role holder **read by the second person** from their own session (Admin console > Account > Admin roles > each role > Admins, or the `users.list` queries of POV 03 PF-1.5 step 2). A field compared with a parenthesised OR list applies to each element (Logging query language, read 2026-09-16); a query "can't exceed 20,000 characters", which bounds the list at a few hundred addresses.

```bash
need ORG_ID SA_1_ADMIN SA_2_ADMIN BRK_GCP_1 BRK_GCP_2 EVE_LOGIN_SCOPE
F="$PLATFORM_REPO_DIR/eve/workspace-audit-filter.txt"; WL="$PLATFORM_REPO_DIR/eve/watched-actors.txt"
test -s "$WL" && for A in "$SA_1_ADMIN" "$SA_2_ADMIN" "$BRK_GCP_1" "$BRK_GCP_2"; do grep -qix "$A" "$WL" || echo "STOP: $A missing from the watched list"; done
case "$EVE_LOGIN_SCOPE" in
  watched)
    ACTORS="$(grep -v '^[[:space:]]*$' "$WL" | sort -u | sed 's/.*/"&"/' | paste -sd' ' - | sed 's/" "/" OR "/g')"
    printf '%s\n' "protoPayload.serviceName=(\"admin.googleapis.com\" OR \"cloudidentity.googleapis.com\") OR (protoPayload.serviceName=(\"login.googleapis.com\" OR \"oauth2.googleapis.com\") AND protoPayload.authenticationInfo.principalEmail=(${ACTORS})) OR logName:\"organizations/${ORG_ID}/logs/cloudaudit.googleapis.com%2Faccess_transparency\"" > "$F";;
  all)
    printf '%s\n' "protoPayload.serviceName=(\"admin.googleapis.com\" OR \"cloudidentity.googleapis.com\" OR \"login.googleapis.com\" OR \"oauth2.googleapis.com\") OR logName:\"organizations/${ORG_ID}/logs/cloudaudit.googleapis.com%2Faccess_transparency\"" > "$F";;
  *) echo "STOP: EVE_LOGIN_SCOPE unset";;
esac
wc -l -c < "$F"
grep -E 'principalEmail!=|NOT protoPayload.authenticationInfo' "$F" && echo "STOP: actor exclusion" || echo "no actor exclusion"
# Filter-scope check against the SD-11 record's Subjects field:
if [ "$EVE_LOGIN_SCOPE" = watched ]; then grep -q 'login.googleapis.com" OR "oauth2.googleapis.com") AND protoPayload.authenticationInfo.principalEmail=(' "$F" && echo "filter scope = record scope (watched)" || echo "STOP: login or OAuth unrestricted but the record signs only watched subjects"; fi
```

  Committed on a branch with `eve/watched-actors.txt` and merged by pull request. **Maintenance rule while `watched`:** a new admin-role holder found by PE-8.1 or the roster diff of PE-8.2 is added to the list by pull request (second person approves) and the sink is updated under an `ENT_ORG_SINK` grant, with `gcloud logging sinks update eve-workspace-audit --organization="$ORG_ID" --log-filter="$(cat "$F")"`. **Residual, stated:** that holder's sign-ins before the update are not copied (their role assignment is, through the unrestricted Admin clause).
- **VERIFY:** No `STOP`; `no actor exclusion`; when `watched`, `filter scope = record scope (watched)` and the second person confirms the list against their own read of admin-role holders; the file is one line and under 20,000 characters; the merge carries the second person's approval. `Assumption:` `protoPayload.authenticationInfo.principalEmail` carries the signing-in or token-granting user for Login and OAuth Token entries; PE-6.3 checks one real row of each and, if not, the clause is corrected before §9.
- **ROLLBACK:** Close the pull request.
- **EVIDENCE:** Merge commit in the build log. E-06. TISAX 5.2.4.

### PE-6.2 Create `eve-workspace-audit`, disabled (**IRREVERSIBLE as history** once PE-6.3 enables it)

- **WHO:** Platform owner under an `ENT_ORG_SINK` grant **approved by the second person**, who watches the command.
- **WHERE:** Shell.
- **ACTION:**

  The sink is created with `--disabled` ("Disabled sinks do not export logs", gcloud logging sinks create, read 2026-09-16), because its writer identity exists only after creation and cannot yet write to `eve_workspace_logs`; an enabled sink would fail every export until PE-6.3's grant, and those entries would be lost. The order is POV 03 PF-6.4 and PF-6.5's: create disabled, grant the writer, then enable.

  > **IRREVERSIBLE as history** from the moment PE-6.3 enables the sink. A filter corrected later does not backfill; whatever this filter omits is lost for the window. Confirm aloud: the filter file is the merged commit; `--disabled`, `--include-children` and `--use-partitioned-tables` are present; the destination is `eve_workspace_logs` in `EVE_PROJECT`; PE-3.2 proved the expiry binds and the dataset is empty. Gate: PE-6.1 merged and PE-3.2 `DONE`.

```bash
need ORG_ID EVE_PROJECT EVE_WS_LOGS_DS
checkpoint PE-6.2 START "$SECOND_HUMAN_EMAIL" - "irreversible as history"
gcloud logging sinks create eve-workspace-audit "bigquery.googleapis.com/projects/${EVE_PROJECT}/datasets/${EVE_WS_LOGS_DS}" --organization="$ORG_ID" --disabled --include-children --use-partitioned-tables --log-filter="$(cat "$PLATFORM_REPO_DIR/eve/workspace-audit-filter.txt")" --description="Eve's copy of the Workspace audit streams, no actor exclusion (POV 06 PE-6.2)"
penv_set EVE_SINK eve-workspace-audit
W_ID="$(gcloud logging sinks describe eve-workspace-audit --organization="$ORG_ID" --format='value(writerIdentity)')"
case "$W_ID" in serviceAccount:*gcp-sa-logging.iam.gserviceaccount.com) echo "writer ok";; *) echo "STOP: writer $W_ID";; esac
checkpoint PE-6.2 DONE "$SECOND_HUMAN_EMAIL"
```

- **VERIFY:** `writer ok`; `gcloud logging sinks describe eve-workspace-audit --organization="$ORG_ID" --format='value(disabled)'` prints `True`; `--format='value(filter)'` equals the merged file; the filter-scope check of PE-6.1 is re-run on that read-back and prints `filter scope = record scope (watched)` unless `EVE_LOGIN_SCOPE` is `all`.
- **ROLLBACK:** `gcloud logging sinks delete eve-workspace-audit --organization="$ORG_ID"` under a fresh grant. That does not recover a lost window. **Delete the sink before ever deleting a destination.**
- **EVIDENCE:** Command and writer identity as `${R}-6.2-sink-v1.txt`; `evidence_add PE-6.2 eve-sink E-06 5.2.4 build-log:records/`. TISAX 5.2.4.

### PE-6.3 Grant the writer on that dataset only, enable the sink, revoke the organisation grant, read the first tables

- **WHO:** Platform owner, still inside PE-6.2's `ENT_ORG_SINK` grant for the enable and inside an `ENT_PROJECT_REPAIR_EVE` grant for the dataset entry; the second person reads the output. Table read at least one hour later, after an admin change.
- **WHERE:** Shell.
- **ACTION:** `WRITER` (the legacy name of `bigquery.dataEditor`) on `eve_workspace_logs` only, added with [setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) EW-1.6's guarded `eve_ds_access` form, which refuses an empty member; **only then** enable the sink (`--no-disabled`: "Specify --no-disabled to enable a disabled sink", gcloud logging sinks update, read 2026-09-16); then revoke the `ENT_ORG_SINK` grant with a reason; then read the tables.

```bash
need ORG_ID EVE_PROJECT EVE_WS_LOGS_DS EVE_SINK SECOND_HUMAN_EMAIL
W_ID="$(gcloud logging sinks describe "$EVE_SINK" --organization="$ORG_ID" --format='value(writerIdentity)')"
. "$PLATFORM_REPO_DIR/eve/tools/eve_ds_access.sh"
eve_ds_access_add "$EVE_WS_LOGS_DS" "${W_ID#serviceAccount:}" WRITER || { echo "STOP: writer not granted; the sink stays disabled"; false; }
checkpoint PE-6.3a DONE "$SECOND_HUMAN_EMAIL" - "sink writer granted on eve_workspace_logs; sink still disabled"
gcloud logging sinks update "$EVE_SINK" --organization="$ORG_ID" --no-disabled
gcloud logging sinks describe "$EVE_SINK" --organization="$ORG_ID" --format='value(disabled)'
checkpoint PE-6.3b DONE "$SECOND_HUMAN_EMAIL" - "sink enabled"
# then: gcloud pam grants revoke <the ENT_ORG_SINK grant of PE-6.2> --reason="POV 06 PE-6.3 sink enabled"
bq --project_id="$EVE_PROJECT" ls --format=json "${EVE_PROJECT}:${EVE_WS_LOGS_DS}" | jq -r '.[].tableReference.tableId'
bq --project_id="$EVE_PROJECT" show --format=prettyjson "${EVE_PROJECT}:${EVE_WS_LOGS_DS}.cloudaudit_googleapis_com_activity" | jq '{type:.timePartitioning.type, field:.timePartitioning.field, expirationMs:.timePartitioning.expirationMs}'
gcloud organizations get-iam-policy "$ORG_ID" --format=json | jq '[.bindings[] | select(.role=="roles/logging.configWriter")]'
```

  If PE-0.1 found no `eve_self_integrity` view in `PLATFORM_LOGS_VIEWS_DS`: `exists_or_pending --pending "view:platform_logs_views.eve_self_integrity" PE-6.3 "POV 03 owner: create the authorised view over EVE_PROJECT's Cloud audit entries (setup/25 preconditions); then grant SA_EVE_VERIFIER READER and unblock SI rules"`.
- **VERIFY:** `PE-6.3a` is written before `PE-6.3b` in `checkpoints.tsv`; the enable read prints `False`; the access array holds exactly two entries (the `OWNER` group and the sink writer); partitioned tables `cloudaudit_googleapis_com_activity` and, after a sign-in, `cloudaudit_googleapis_com_data_access`, not date-sharded; `DAY` with `IDENTITY_RETENTION_DAYS * 86400000`; the partitioning field recorded for PB-03's SQL; no standing `logging.configWriter` at the organisation. When `EVE_LOGIN_SCOPE=watched`, **the second person** (never the platform owner, who reads no sign-in rows) runs `SELECT protoPayload.serviceName AS svc, COUNT(DISTINCT protoPayload.authenticationInfo.principalEmail) AS actors, LOGICAL_AND(protoPayload.authenticationInfo.principalEmail IN UNNEST(@watched)) AS all_watched FROM eve_workspace_logs.cloudaudit_googleapis_com_data_access GROUP BY svc` with `@watched` from `eve/watched-actors.txt`, and records only the counts and `all_watched = true` for each of `login` and `oauth2`: that proves both the principal field assumption of PE-6.1 and that no unwatched user's sign-in was copied.
- **ROLLBACK:** Before the enable: access array restored from the recorded `before.json`. After it: `gcloud logging sinks update "$EVE_SINK" --organization="$ORG_ID" --disabled` under a fresh `ENT_ORG_SINK` grant, then the array restored; the window already exported stays, as evidence.
- **EVIDENCE:** `${R}-6.3-sink-verify-v1.txt`, countersigned. E-06, E-08. TISAX 5.2.4, 4.2.1.

## 7. `eve/config`

The one place a rule or a number that governs Eve changes. The full-set repository name and layout are kept ([setup/25](../setup/25-eve-human-super-admin-detections.md) §2).

### PE-7.1 Create the repository so the platform owner cannot merge alone

- **WHO:** Platform owner creates; **the second person** holds the repository administrator role, sets the protection, and reads it back from their own account.
- **WHERE:** The git host; shell.
- **ACTION:** Private repository `eve-config`, directories `detections/`, `sql/`, `tools/`. `CODEOWNERS`: `* @<second-person-handle>` and `/detections/ /sql/ /tools/ @<second-person-handle> @<security-reviewer-handle>`. Protection on `main`: pull request required; one code-owner approval; stale approvals dismissed; force-push and deletion forbidden; **no administrator bypass**. The platform owner is not an administrator of the repository. Then `penv_set EVE_CONFIG_REPO "<remote URL>"`.
- **VERIFY:** The second person reads the settings and confirms in writing; the platform owner's `git push origin main` is refused with the host's protected-branch message, and the refusal is the evidence (the full negative test is PE-12.3).
- **ROLLBACK:** Delete the repository before anything is merged.
- **EVIDENCE:** Settings read-back and the refused push as `${R}-7.1-eve-config-protection-v1`. E-05. TISAX 5.3.1, 5.2.1.

### PE-7.2 `thresholds.yaml`

- **WHO:** Platform owner writes as Eve owner; the second person approves.
- **WHERE:** `eve-config`, branch `thresholds-pov`.
- **ACTION:** Only the budgets the POV uses, with Google's published lags read 2026-09-16 (data retention and lag times): Admin and Login "near real time (couple of minutes)", SAML the same, Groups "tens of minutes (can also go up to a couple of hours)", OAuth token "a couple of hours".

```yaml
version: "eve-pov-1"
evidence:
  lag_budget_minutes: {admin: 15, login: 15, saml: 15, groups_enterprise: 240, token: 240}
  query_period_minutes: 60          # scheduled queries, off the hour
  freshness:
    admin_silence_minutes_business_hours: 120   # Assumption: two hourly runs; reviewed at the first S review
    login_silence_minutes_business_hours: 120
roster:
  diff_period_minutes: 60
  residual_window_minutes: 60      # an admin created just after a diff is unseen by watched-only rules for up to this long
reporting:
  business_hours_only: true        # PV-D-10: no 24x7 desk
  severity_1_ack_business_hours: 4
  sole_recipient_rule: true
  detect_to_notice_minutes: 90     # lag (<=5) + query period (60) + alert (<=10) + margin; the number PE-12.2 waits
```

  Only streams marked `seen` in `EVE_EDITION_COVERAGE_RECORD` may carry a budget; the others are removed. Merge, then `penv_set EVE_THRESHOLDS_COMMIT "<merge sha>"`.
- **VERIFY:** A YAML parse asserts every budget is an integer; the merge carries the second person's approval; no budget names an unseen stream.
- **ROLLBACK:** A reverting pull request, reviewed by the second person.
- **EVIDENCE:** Merge commit as `${R}-7.2-thresholds-v1`. E-05. TISAX 5.2.1.

### PE-7.3 The detection catalogue, as predicates

- **WHO:** Platform owner writes; the second person approves; the security reviewer reads it when appointed.
- **WHERE:** `eve-config`, `detections/catalogue.yaml` and `detections/admin-method-allowlist.yaml`.
- **ACTION:** The POV catalogue is the subset of [setup/25](../setup/25-eve-human-super-admin-detections.md) EH-2.3 whose only source is the sink, with its event-name sets copied unchanged and `actors: watched` or `any` exactly as there: **SA-01, SA-02, SA-03, SA-06 (roster diff, §8), SA-09, SI-01 re-scoped to the admin accounts, SI-08, SI-09**, plus the freshness rule `log_pipeline_silent` and, where PE-6.3's view exists, SI-02, SI-03, SI-05, SI-06, SI-11 and SI-12 over `platform_logs_views.eve_self_integrity`; otherwise those six carry `blocked: pov_view_pending`. SA-04, SA-05, SA-10 and SI-10 are **not** committed: they need the poll, `eve@` or secrets that the POV does not have, and the catalogue says so in a `not_in_pov:` list with PV-D-07 as the reason. Each rule carries `subject: actor` and a `route:` computed at report time (`sh` when the actor is `SA_2_ADMIN`, else `po`).

  One change from the full set, stated: setup/25's CI refusal of "a severity-1 rule whose only source is the sink" cannot hold, because the POV has only the sink. The catalogue records that as the named limit of PV-D-07, and the absence rule of PE-9.3 is the control that notices the sink going quiet.
- **VERIFY:** The second person's approval; a parse lists the rule ids, the blocked ids and the `not_in_pov` ids; every source is a stream `seen` in the coverage record. `Assumption:` the event names in setup/25 EH-2.3 are current; `ASSIGN_ROLE`, `UNASSIGN_ROLE`, `CREATE_ROLE`, `ADD_PRIVILEGE`, `REMOVE_PRIVILEGE`, `RENAME_ROLE` were re-read on Google's delegated admin settings event page on 2026-09-16; the others are re-read on the day of the merge.
- **ROLLBACK:** A reverting pull request; a removed rule changes the fingerprint.
- **EVIDENCE:** Merge commit and parse as `${R}-7.3-catalogue-v1`. E-05. TISAX 5.2.4, 1.5.1.

### PE-7.4 Record the configuration commit and prove no Eve identity can write

- **WHO:** Platform owner; the second person reads the collaborator list from their own account.
- **WHERE:** Shell; the git host.
- **ACTION:** `penv_set EVE_CONFIG_COMMIT "$(git -C "$HOME/work/eve-config" rev-parse origin/main)"`; list collaborators and any automation with write scope.
- **VERIFY:** Collaborators are named humans only; no service account, no workload identity, no automation with write.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-7.4-eve-config-closed-v1`. E-05. TISAX 5.3.1, 4.2.1.

## 8. The roster

### PE-8.1 Seed the observed roster by hand

- **WHO:** Platform owner reads the console; **the second person reads the same screens from their own session and signs**.
- **WHERE:** Admin console: Menu > Account > Admin roles > Super Admin > Admins; each other role's Admins tab.
- **ACTION:** The watched set must exist before the first diff. Record every account holding Super Admin or any admin role, compare it with `ROSTER_FILE`, and commit the observation to `eve-config/roster/observed-<date>.yaml` (accounts and role names only), with the SHA-256 of `ROSTER_FILE` at its current commit. Then `penv_set EVE_ROSTER_FILE "roster/observed-<date>.yaml"`.
- **VERIFY:** Every observed Super Admin is on `ROSTER_FILE`, and every `ROSTER_FILE` super admin is observed. When `EVE_LOGIN_SCOPE=watched`, every observed admin-role holder is on `eve/watched-actors.txt`; one missing is added under PE-6.1's maintenance rule before §9. A difference is a finding reported to the second person now (or to the security reviewer when it concerns the second person), not after Eve runs. The seed is itself evidence of the state at a time.
- **ROLLBACK:** A reverting pull request.
- **EVIDENCE:** The merged file and both signatures as `${R}-8.1-roster-seed-v1`. E-08. TISAX 4.1.1, 4.2.1.

### PE-8.2 The roster diff from role events (**BLOCKED on PB-03**)

- **WHO:** Platform owner writes; the second person approves.
- **WHERE:** `eve-config/sql/roster_diff.sql`.
- **ACTION:** > **BLOCKED**: needs PB-03's roster-diff SQL: seed plus `ASSIGN_ROLE` minus `UNASSIGN_ROLE` (parameters `ROLE_NAME`, `USER_EMAIL`) from `eve_workspace_logs.cloudaudit_googleapis_com_activity` since the seed time, compared with `ROSTER_FILE`, writing `role_assignment_added` and `role_assignment_missing` findings (rule SA-06). Part of PB-03, `Assumption:` 7 to 10 engineer-days for the whole of PB-03. Gate that waits: PE-9.2. Until then: `checkpoint PE-8.2 BLOCKED - - "PB-03 roster diff"`.

  **Residual, stated:** a role granted between two hourly runs is seen by `actors: any` rules at once and by `watched` rules up to `roster.residual_window_minutes` later. A role change the Admin log does not record (none known) is invisible; a role held before the seed and missed by the reading is the reason PE-8.1 has two readers.
- **VERIFY:** When unblocked: two golden fixtures (one added, one removed) each produce exactly one finding.
- **ROLLBACK:** A reverting pull request.
- **EVIDENCE:** The BLOCKED line; then fixture output as `${R}-8.2-roster-diff-v1`. E-08. TISAX 4.2.1.

## 9. Identities, queries, absence alarm, fingerprint

### PE-9.1 `eve-verifier@` and `eve-v0@`, keyless

- **WHO:** Platform owner, inside the grant; the second person approved it.
- **WHERE:** Shell.
- **ACTION:** `eve-verifier@` runs the Eve-H queries over `eve_workspace_logs`; `eve-v0@` runs §11's queries over the doer's audit. Both full-set names ([setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) EW-7.1, [setup/36](../setup/36-wall-e-joins-to-eve-and-mo.md) WJ-1.1). A scheduled query runs as its creator unless a service account is named (scheduling queries, read 2026-09-16), and an evidence series that runs as the administrator it watches is worthless.

```bash
need EVE_PROJECT
gcloud iam service-accounts create eve-verifier --project="$EVE_PROJECT" --display-name="Eve verifier" --description="Eve-H scheduled queries. No key."
gcloud iam service-accounts create eve-v0 --project="$EVE_PROJECT" --display-name="Eve v0" --description="Eve v0 queries over the doer's audit. No key."
penv_set SA_EVE_VERIFIER "eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com"
penv_set SA_EVE_V0 "eve-v0@${EVE_PROJECT}.iam.gserviceaccount.com"
for SA in "$SA_EVE_VERIFIER" "$SA_EVE_V0"; do gcloud projects add-iam-policy-binding "$EVE_PROJECT" --member="serviceAccount:${SA}" --role=roles/bigquery.jobUser --condition=None; done
. "$PLATFORM_REPO_DIR/eve/tools/eve_ds_access.sh"   # the additive form of setup/24 EW-1.6
eve_ds_access_add "$EVE_WS_LOGS_DS" "$SA_EVE_VERIFIER" READER
eve_ds_access_add "$EVE_DS" "$SA_EVE_VERIFIER" WRITER
eve_ds_access_add "$EVE_DS" "$SA_EVE_V0" WRITER
gcloud storage buckets add-iam-policy-binding "$EVE_EVIDENCE_BUCKET" --member="serviceAccount:${SA_EVE_VERIFIER}" --role=roles/storage.objectCreator
```

  `WRITER` at dataset level is `dataEditor`, which can delete tables: row tampering is **detected, not prevented** (SD-43). The full set's table-level custom writer roles ([setup/23](../setup/23-eve-project-and-evidence-stores.md) §6) arrive with the full build; until then the fingerprint (PE-9.4) covers the access arrays and PB-03's SQL uses `INSERT` only.
- **VERIFY:** `gcloud iam service-accounts keys list --managed-by=user` is empty for both; each holds exactly `roles/bigquery.jobUser` at project level; the three dataset entries and the bucket binding read back; **no** `user:` holds `iam.serviceAccountUser` or `iam.serviceAccountTokenCreator` on either account. `Assumption:` creating a transfer config with `--service_account_name` needs the creator to hold `iam.serviceAccountUser` on that account; PE-9.2 grants it time-boxed and removes it.
- **ROLLBACK:** Delete the accounts while no transfer config names them.
- **EVIDENCE:** `${R}-9.1-identities-v1.txt`; `evidence_add PE-9.1 eve-identities E-08 4.2.1 build-log:records/`. TISAX 4.2.1, 4.1.1.

### PE-9.1a Re-run the zero-diff checker once the two identities exist, without `--accept-pending`

- **WHO:** Platform owner runs; **the second person reads the report** and initials it.
- **WHERE:** Shell, after PE-9.1's repair grant is revoked (an active grant reads as a human member).
- **ACTION:** PE-9.1 made what the spec's two `pending` lines wait for, and nothing else the checker reads: the dataset entries and the bucket binding are resource-level, not project-level. Run setup/17 FM-2.21 again, this time without `--accept-pending`, so a `PENDING` line prints `DIFF`. A later step of this file that changes anything the checker reads (a project role, a service, a project-level policy) revises the spec by a reviewed commit and re-runs this step.

```bash
need EVE_PROJECT SA_EVE_VERIFIER SA_EVE_V0 PLATFORM_REPO_DIR BUILD_LOG_DIR SECOND_HUMAN_EMAIL
checkpoint PE-9.1a START "$SECOND_HUMAN_EMAIL" - "setup/17 FM-2.21 on EVE_PROJECT after PE-9.1"
gcloud pam grants search --entitlement=ent-project-repair-eve --location=global --project="$EVE_PROJECT" --caller-relationship=had-created --filter='state=ACTIVE' --format='value(name)' | grep -q . && echo "STOP: an ENT_PROJECT_REPAIR_EVE grant is ACTIVE; revoke it first" || echo "no active repair grant"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
if python3.12 "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" live "$PLATFORM_REPO_DIR/factory/runs/eve-prod.json" --report "${R}-9.1a-live-v1.json"; then echo "exit=0"; else echo "exit=$?"; fi
jq -r '.results[] | select(.status != "PASS") | "\(.status) \(.check)"' "${R}-9.1a-live-v1.json"
```

- **VERIFY:** `no active repair grant`; `ZERO-DIFF` and `exit=0` without `--accept-pending`; the non-`PASS` listing is empty, so `service_accounts.exact`, both `service_account.*.no_user_keys` and `iam.spec_bindings_present` read `PASS` (the spec's two `pending` lines are now inert). PE-1.6's line in `rerun-index.tsv` is closed with this step's id. A `FAIL` is repaired as PE-1.6 says. Then `checkpoint PE-9.1a DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-9.1a-live-v1.json")" "EVE_PROJECT ZERO-DIFF against its run spec"`.
- **ROLLBACK:** Read only.
- **EVIDENCE:** The report, initialled by the second person; `evidence_add PE-9.1a zero-diff E-05 5.2.4 build-log:records/ "${R}-9.1a-live-v1.json"`. E-05. TISAX 5.2.4.

### PE-9.2 Create the Eve-H query set, pinned and **disabled** (**BLOCKED on PB-03**)

- **WHO:** Platform owner, inside the grant, with a two-hour conditional `iam.serviceAccountUser` on `eve-verifier@` approved by the second person.
- **WHERE:** Shell; clean clone of `EVE_CONFIG_REPO` at `EVE_CONFIG_COMMIT`.
- **ACTION:** > **BLOCKED**: needs PB-03's SQL files in `eve-config/sql/`: one per committed rule of PE-7.3 plus `roster_diff.sql` and `freshness.sql`, each a multi-statement script that `INSERT`s finding rows into `eve.findings` and then, when a new finding exists, calls `ERROR()` with the text `EVE-FINDING route=<po|sh> rule=<id>` and **no personal name**, so the run fails and Cloud Logging carries the route. `freshness.sql` ends without error only when every `seen` stream is inside its budget. `Assumption:` 7 to 10 engineer-days for PB-03 as a whole. Gate that waits: PE-9.3, PE-10.4 and so `POV_EVE_FIRST_RUN_RECORD`. Until then: `checkpoint PE-9.2 BLOCKED - - "PB-03 Eve-H SQL"`.

  When unblocked, one config per file, off the hour, then disabled immediately through the API's `disabled` field (manage transfers, read 2026-09-16):

```bash
M=7; for F in "$T"/sql/*.sql; do
  bq mk --transfer_config --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" --data_source=scheduled_query --display_name="eve-h-$(basename "$F" .sql)" --service_account_name="$SA_EVE_VERIFIER" --schedule="every 1 hours from 00:$(printf '%02d' "$M") to 23:59" --params="$(jq -n --arg q "$(cat "$F")" '{query:$q}')"
  M=$(( (M+4) % 55 + 2 )); done
penv_set POV_EVE_H_QUERY_SET "$(bq ls --transfer_config --transfer_location="$BQ_LOCATION" --project_id="$EVE_PROJECT" --format=json | jq -r '[.[]|select(.displayName|startswith("eve-h-"))|.name]|join(",")')"
echo "$POV_EVE_H_QUERY_SET" | tr ',' '\n' | while read -r C; do curl -sS --fail-with-body -X PATCH -H @- -H 'Content-Type: application/json' "https://bigquerydatatransfer.googleapis.com/v1/${C}?updateMask=disabled" -d '{"disabled":true}' <<<"Authorization: Bearer $(gcloud auth print-access-token)" | jq -r '.name,.disabled'; done
```

  The bearer token reaches curl on standard input (`-H @-`: "Using @- makes curl read the header file from stdin", curl manual, read 2026-09-16), never on the command line where other local processes can read it; nothing prints or stores it.

  Scheduled queries "running exactly on the hour ... might trigger multiple times"; the minimum interval is 5 minutes (scheduling queries, read 2026-09-16).
- **VERIFY:** When unblocked: `bq show --transfer_config` for each name prints `ownerInfo.email` equal to `SA_EVE_VERIFIER` ([setup/36](../setup/36-wall-e-joins-to-eve-and-mo.md) WJ-4.5's check), `disabled: true`, and a schedule not at minute `00`; the time-boxed `serviceAccountUser` binding is removed and a read shows no `user:` holder.
- **ROLLBACK:** `bq rm -f --transfer_config <name>`.
- **EVIDENCE:** The BLOCKED line; then `${R}-9.2-query-set-v1.tsv`. E-06. TISAX 5.2.4.

### PE-9.3 The absence alarm on the data (**BLOCKED with PE-9.2**)

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell.
- **ACTION:** The threat is the watched administrator turning the feed off quietly, so the alarm watches **fresh data**, not the log pipeline ([setup/25](../setup/25-eve-human-super-admin-detections.md) §6). A log-based metric counts successful runs of the `eve-h-freshness` config only, and that run succeeds only when every seen stream is fresh. A metric "comes only from log entries received after the metric is created" (log-based metrics, read 2026-09-16), so it is created after PE-9.2 has created the `eve-h-freshness` config and **before** PE-10.4 enables any schedule: the configs are disabled, so no run is missed.

  > **BLOCKED** with PE-9.2: the metric filter must name the freshness config's `resource.labels.config_id` (monitor transfers, read 2026-09-16: "For a specific transfer configuration, add: resource.labels.config_id"), and that id exists only once PE-9.2 has run. A filter over every `INFO` entry of every transfer config in the project would count other configs' runs and so would not prove fresh data. Until then: `checkpoint PE-9.3 BLOCKED - - "with PE-9.2: eve-h-freshness config id"`.

```bash
need EVE_PROJECT BQ_LOCATION POV_EVE_H_QUERY_SET
FRESH="$(bq ls --transfer_config --transfer_location="$BQ_LOCATION" --project_id="$EVE_PROJECT" --format=json | jq -r '.[] | select(.displayName=="eve-h-freshness") | .name')"
CFG_ID="${FRESH##*/}"; [ -n "$CFG_ID" ] && echo "freshness config id: $CFG_ID" || { echo "STOP: no eve-h-freshness config; PE-9.3 stays BLOCKED"; false; }
gcloud logging metrics create eve_freshness_ok --project="$EVE_PROJECT" --description="Successful runs of eve-h-freshness: every seen Workspace stream inside its budget (POV 06 PE-9.3)" --log-filter="resource.type=\"bigquery_dts_config\" AND resource.labels.config_id=\"${CFG_ID}\" AND severity=INFO AND logName=\"projects/${EVE_PROJECT}/logs/bigquerydatatransfer.googleapis.com%2Ftransfer_config\""
W="$(mktemp -d)"
jq -n '{displayName:"Eve H-1: fresh Workspace data absent", combiner:"OR", documentation:{content:"No successful eve-h-freshness run in 3 hours: the sink, sharing, or the query stopped. Report to the second person (POV 06).", mimeType:"text/markdown"}, conditions:[{displayName:"no fresh-data success in 3h", conditionAbsent:{filter:"metric.type=\"logging.googleapis.com/user/eve_freshness_ok\" AND resource.type=\"bigquery_dts_config\"", duration:"10800s", aggregations:[{alignmentPeriod:"600s", perSeriesAligner:"ALIGN_COUNT"}]}}], notificationChannels:[]}' > "$W/h1.json"
gcloud monitoring policies create --project="$EVE_PROJECT" --policy-from-file="$W/h1.json" --format='value(name)'
cp "$W/h1.json" "${R}-9.3-h1-v1.json"; rm -rf "$W"
```

  **Residual, stated:** monitor transfers (read 2026-09-16) names the resource type, the `config_id` label, the log name and the `INFO`/`WARNING`/`ERROR` severities, but not the text of a success message. `Assumption:` a run of `eve-h-freshness` that ends in `ERROR()` still writes `INFO` progress entries, which this metric would count; if so, the absence alarm does not fire on a freshness run that fails every hour. PE-10.5 proves the paused case only; the failing case is covered by the "Eve query broken" policy of PE-10.2, which notifies the second person on any Eve-H run error, and the metric is replaced by the documented "Completed run count" metric filtered to `succeeded` once its metric type string is read (§Unverified).
- **VERIFY:** When unblocked: `freshness config id` printed; `gcloud logging metrics describe eve_freshness_ok --project="$EVE_PROJECT" --format='value(filter)'` names that `config_id`; the policy is enabled with duration `10800s` and no channel yet, attached at PE-10.2. Then `penv_set EVE_ABSENCE_ALARM "<policy name>"`.
- **ROLLBACK:** Delete the policy and the metric.
- **EVIDENCE:** The BLOCKED line; then `${R}-9.3-h1-v1.json`. E-06. TISAX 5.2.4.

### PE-9.4 The configuration fingerprint: components and script (**BLOCKED on PB-03**)

- **WHO:** Platform owner writes; the second person approves as code owner of `/tools/`.
- **WHERE:** `eve-config/tools/fingerprint.sh`, `eve-config/fingerprint.yaml`.
- **ACTION:** > **BLOCKED**: needs PB-03's fingerprint script, adapted from [setup/25](../setup/25-eve-human-super-admin-detections.md) EH-8.1 to the POV's components: sink filter, destination and writer; each transfer config's name, schedule, `disabled`, `ownerInfo.email` and SHA-256 of its query; the three dataset access arrays; the bucket's retention, lock and IAM policy; `EVE_PROJECT`'s IAM policy and org-policy on `restrictServiceUsage`; Monitoring policies, log metrics and notification channels (type, display name, enabled, labels); project liens; the roster hash; `EVE_CONFIG_COMMIT` and the rule ids. Projected to named fields so no timestamp or etag enters; no secret is read. Until then: `checkpoint PE-9.4 BLOCKED - - "PB-03 fingerprint script"`.
- **VERIFY:** When unblocked: merged with the second person's approval; two consecutive runs by the platform owner print the same 64-character value.
- **ROLLBACK:** A reverting pull request.
- **EVIDENCE:** The BLOCKED line; then merge commit as `${R}-9.4-fingerprint-definition-v1`. E-06. TISAX 5.2.4.

### PE-9.5 The second person recomputes the baseline from their own session (**BLOCKED with PE-9.4**)

- **WHO:** **The second person**, on their own workstation and account, with the platform owner not at the keyboard; the platform owner reads out their own value.
- **WHERE:** The second person's shell and own clone of `EVE_CONFIG_REPO` at `EVE_CONFIG_COMMIT`.
- **ACTION:** > **BLOCKED** until PE-9.4 is `DONE` and PE-10.2 has attached the channels (the channels are a component). Then the second person runs the committed script, not a copy, and compares with the platform owner's value.
- **VERIFY:** The two values are identical, or the input files are diffed and the difference explained before anything is recorded. The second person stores the value outside the platform owner's reach (their own mailbox or a paper record), and only then: `penv_set EVE_FINGERPRINT_BASELINE "<64 hex>"`. The baseline attests continuity, not correctness.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Both values and the store reference, signed by the second person, as `${R}-9.5-fingerprint-baseline-v1`. E-06, E-08. TISAX 5.2.4.

## 10. Reporting, then the first run

POV reporting is Cloud Monitoring in `EVE_PROJECT`, **never in `CORE_PROJECT`**, so the person Eve reports on does not administer the channel. No pager service and no SIEM (PV-D-10).

### PE-10.1 The channels

- **WHO:** Platform owner creates the email channels; **the second person types their own phone number and verification code** for SMS. The security reviewer does the same for their channel.
- **WHERE:** Cloud console > Monitoring > Alerting > Edit notification channels > Add new, with `EVE_PROJECT` selected; shell for the read-back.
- **ACTION:** (a) Email `eve email second human` to `SECOND_HUMAN_EMAIL` (an individual address, not a group) and SMS `eve sms second human`. (b) If PE-0.3 named the security reviewer: email `eve email security reviewer` to `SECURITY_REVIEWER_EMAIL`. Google states SMS "isn't a fully reliable notification channel type" and may be unavailable in some regions (notification options, read 2026-09-16), which is why email is always paired with it.

```bash
need EVE_PROJECT
L() { gcloud beta monitoring channels list --project="$EVE_PROJECT" --filter="displayName=\"$1\"" --format='value(name)'; }
penv_set NOTIF_CH_EVE_EMAIL_SECOND_HUMAN "$(L 'eve email second human')"
penv_set NOTIF_CH_EVE_SMS_SECOND_HUMAN "$(L 'eve sms second human')"
[ -n "$(L 'eve email security reviewer')" ] && penv_set NOTIF_CH_EVE_EMAIL_SECURITY_REVIEWER "$(L 'eve email security reviewer')"
gcloud beta monitoring channels list --project="$EVE_PROJECT" --format='value(displayName,type,enabled,verificationStatus)'
```

- **VERIFY:** Each variable holds one name; SMS reads `VERIFIED`; the platform owner never saw the number. SMS unavailable: recorded as `BD-P06-2`, and route po rests on email.
- **ROLLBACK:** `gcloud beta monitoring channels delete <name> --project="$EVE_PROJECT"`.
- **EVIDENCE:** Channel names and types (no number) as `${R}-10.1-channels-v1.txt`. E-08. TISAX 1.6.1.

### PE-10.2 The routed policies

- **WHO:** Platform owner, inside the grant; the second person reads the two filters.
- **WHERE:** Shell.
- **ACTION:** Two log-based policies over failed runs of the Eve-H configs. **Route po** matches `route=po` and notifies the second person. **Route sh** matches `route=sh` and notifies **only** the security reviewer; with no security reviewer it is created with no channel and the `PENDING` of PE-0.3 stands. PE-4.5's policy, and PE-9.3's once it exists, are attached to route po's channels. A third policy catches any Eve-H run error that carries no route (a broken query) and notifies the second person.

```bash
mkpol() { jq -n --arg dn "$1" --arg f "$2" --argjson ch "$3" '{displayName:$dn, combiner:"OR", conditions:[{displayName:$dn, conditionMatchedLog:{filter:$f}}], alertStrategy:{notificationRateLimit:{period:"300s"}, autoClose:"86400s"}, notificationChannels:$ch}' > "$W/p.json"; gcloud monitoring policies create --project="$EVE_PROJECT" --policy-from-file="$W/p.json" --format='value(name)'; }
W="$(mktemp -d)"; BASE='resource.type="bigquery_dts_config" AND severity>=ERROR'
PO="$(jq -nc --arg a "$NOTIF_CH_EVE_EMAIL_SECOND_HUMAN" --arg b "$NOTIF_CH_EVE_SMS_SECOND_HUMAN" '[$a,$b]')"
SH="$(jq -nc --arg a "${NOTIF_CH_EVE_EMAIL_SECURITY_REVIEWER:-}" 'if $a=="" then [] else [$a] end')"
mkpol "Eve report route po" "$BASE AND \"EVE-FINDING route=po\"" "$PO"
mkpol "Eve report route sh" "$BASE AND \"EVE-FINDING route=sh\"" "$SH"
mkpol "Eve query broken" "$BASE AND NOT \"EVE-FINDING\"" "$PO"
rm -rf "$W"
```

- **VERIFY:** Three policies; route sh's channel list contains no channel of the second person or the platform owner; PE-4.5's and PE-9.3's policies now list route po's channels.
- **ROLLBACK:** Delete the policies.
- **EVIDENCE:** Policy listing as `${R}-10.2-policies-v1.txt`. E-08. TISAX 1.6.1, 5.2.4.

### PE-10.3 Test each route, received by the recipient alone

- **WHO:** Platform owner triggers; **the second person confirms route po alone**, once in and once out of business hours, from their own phone and mailbox; **the security reviewer confirms route sh**. Each types the notification's incident id.
- **WHERE:** Shell; the recipients' own devices.
- **ACTION:** Write a synthetic test entry into `EVE_PROJECT`'s logs for each route. `gcloud logging write` writes a `global` resource, and the real policies of PE-10.2 filter `resource.type="bigquery_dts_config"`, so they cannot match it. The step therefore creates two temporary policies, copies of route po and route sh over `resource.type="global"` on **the same channels**, and deletes them at the end of the step. The real filters are proven at PE-10.4.

```bash
need EVE_PROJECT NOTIF_CH_EVE_EMAIL_SECOND_HUMAN NOTIF_CH_EVE_SMS_SECOND_HUMAN
W="$(mktemp -d)"
mkpol() { jq -n --arg dn "$1" --arg f "$2" --argjson ch "$3" '{displayName:$dn, combiner:"OR", conditions:[{displayName:$dn, conditionMatchedLog:{filter:$f}}], alertStrategy:{notificationRateLimit:{period:"300s"}, autoClose:"1800s"}, notificationChannels:$ch}' > "$W/p.json"; gcloud monitoring policies create --project="$EVE_PROJECT" --policy-from-file="$W/p.json" --format='value(name)'; }
TBASE='resource.type="global" AND logName="projects/'"$EVE_PROJECT"'/logs/eve-route-test" AND severity>=ERROR'
PO="$(jq -nc --arg a "$NOTIF_CH_EVE_EMAIL_SECOND_HUMAN" --arg b "$NOTIF_CH_EVE_SMS_SECOND_HUMAN" '[$a,$b]')"
SH="$(jq -nc --arg a "${NOTIF_CH_EVE_EMAIL_SECURITY_REVIEWER:-}" 'if $a=="" then [] else [$a] end')"
TEST_PO="$(mkpol "Eve route test po (PE-10.3, temporary)" "$TBASE AND \"EVE-FINDING route=po\"" "$PO")"
TEST_SH="$(mkpol "Eve route test sh (PE-10.3, temporary)" "$TBASE AND \"EVE-FINDING route=sh\"" "$SH")"
printf '%s\n%s\n' "$TEST_PO" "$TEST_SH" | tee "${R}-10.3-test-policies-v1.txt"
gcloud logging write eve-route-test "EVE-FINDING route=po rule=TEST-PO" --severity=ERROR --project="$EVE_PROJECT"
confirm_manual PE-10.3 "Second person: type the incident id received for route po"
gcloud logging write eve-route-test "EVE-FINDING route=sh rule=TEST-SH" --severity=ERROR --project="$EVE_PROJECT"
confirm_manual PE-10.3 "Security reviewer: type the incident id received for route sh, or PENDING"
for P in "$TEST_PO" "$TEST_SH"; do gcloud monitoring policies delete "$P" --project="$EVE_PROJECT"; done
rm -rf "$W"
```

  The delete prompts; it is answered at the keyboard, never with `--quiet`.

- **VERIFY:** Route po: an incident id typed by the second person, with the delay; **the platform owner received nothing**. Route sh: an incident id typed by the security reviewer and nothing received by the second person; or `PENDING`, and route sh stays recorded against PV-09. The real filters are proven on a real failing run at PE-10.4.
- **ROLLBACK:** Delete the two test policies named in `${R}-10.3-test-policies-v1.txt`, if the block stopped before its own delete.
- **EVIDENCE:** Typed ids, times and non-receipt confirmations as `${R}-10.3-route-tests-v1`; drill row in `DRILL_CALENDAR`. E-08. TISAX 1.6.1.

### PE-10.4 Enable the schedules and write `POV_EVE_FIRST_RUN_RECORD` (**BLOCKED with PE-9.2**)

- **WHO:** Platform owner, inside the grant; the second person co-signs the record.
- **WHERE:** Shell.
- **ACTION:** > **BLOCKED** until PE-9.2 and PE-3.4 are `DONE` and PE-10.3 route po passed. **The schedules stay disabled until then** ([setup/25](../setup/25-eve-human-super-admin-detections.md) §5 rule). When unblocked: PATCH `disabled:false` on each name in `POV_EVE_H_QUERY_SET`; start one run of each with `bq mk --transfer_run --run_time=<now> <name>`; one rule is made to fire deliberately by the second person (a description edit on a fixture OU, which SA-01 matches), so the real route po filter is seen matching a real failure.
- **VERIFY:** When unblocked: every config ran; `eve.findings` holds the seeded finding with `subject`, `rule_id` and `query_hash`; the second person received it through route po; the freshness run succeeded. Record at `$PLATFORM_REPO_DIR/eve/records/<date>-eve-first-run.md` and `penv_set POV_EVE_FIRST_RUN_RECORD "<path>"`.
- **ROLLBACK:** PATCH `disabled:true`. Finding rows stay; they are evidence.
- **EVIDENCE:** The record, co-signed; `evidence_add PE-10.4 eve-first-run E-06 5.2.4 repo:"$POV_EVE_FIRST_RUN_RECORD"`. TISAX 5.2.4, 1.6.1.

### PE-10.5 See the absence alarm fire (**BLOCKED with PE-10.4**)

- **WHO:** Platform owner pauses under a grant **the second person approved for this purpose**; the second person receives.
- **WHERE:** Shell.
- **ACTION:** > **BLOCKED** until PE-10.4. Then PATCH `disabled:true` on `eve-h-freshness` only, record the time, wait out `10800s` plus alignment, confirm the incident, re-enable.
- **VERIFY:** The second person types the incident id and the observed delay (Eve's detection latency for a silenced feed, quoted in `POV_EVE_H_LIVE_RECORD`). No incident: H-1 is not a control and this file is not complete.
- **ROLLBACK:** Re-enable the config: the step's own last command.
- **EVIDENCE:** Times and incident id as `${R}-10.5-h1-observed-v1`; drill row. E-06, E-08. TISAX 5.2.4, 1.6.1.

## 11. Eve v0 over the doer's audit (waits on POV 07)

This part alone waits for the doer. Parts 0 to 10 and 12 never do (SD-10).

### PE-11.1 The inputs gate

- **WHO:** Platform owner.
- **WHERE:** Shell.
- **ACTION:** `need DOER_AUDIT_DS DOER_PROJECT AUDIT_DDL_COMMIT`; read `DOER_AUDIT_DS`'s access array in `DOER_PROJECT` for a `READER` entry for `SA_EVE_V0`. That grant is made by POV 07 in its own file, where the resource lives, never here.
- **VERIFY:** The entry is present. Absent or `DOER_AUDIT_DS` unset: `exists_or_pending --pending "serviceAccount:${SA_EVE_V0}" PE-11.1 "POV 07: READER on DOER_AUDIT_DS for eve-v0@; then PE-11.2"` and §11 stops without holding §12.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-11.1-v0-inputs-v1.txt`. E-09. TISAX 4.2.1.

### PE-11.2 The twelve v0 queries (**BLOCKED on PB-03**)

- **WHO:** Platform owner, inside the grant.
- **WHERE:** Shell; `eve-config/sql/v0/m01_*.sql` to `m12_*.sql`.
- **ACTION:** > **BLOCKED**: needs PB-03's twelve v0 SQL files over the doer's nine audit tables of PB-01: the ten ladder metrics (hard-invariant denials with the T0-human exclusion, audit completeness among them), two-direction reconciliation against `eve_workspace_logs`, **per operation, against the Google audit stream and event name catalogued for that operation** (the audit-stream catalogue that [09](09-the-demonstration-deviations-and-the-hand-over.md) Preconditions requires from file 07, read from a real event: a membership change made through the API may be recorded in Groups Enterprise log events, not Admin log events): the doer robot's events with no audit row, and audit rows with no Google event. An operation with audit rows whose match set in its catalogued stream is empty **fails** the reconciliation; an empty match is never read as agreement. And ladder drift. None names Firestore or any reserved Wall-E dataset ([setup/36](../setup/36-wall-e-joins-to-eve-and-mo.md) WJ-4.2, WJ-4.3). Gate that waits: POV 07's Tier W record and POV 08's value report. Until then: `checkpoint PE-11.2 BLOCKED - - "PB-03 v0 SQL"`.

  When unblocked: [setup/36](../setup/36-wall-e-joins-to-eve-and-mo.md) WJ-4.4's `v0_cfg` loop with `--service_account_name="$SA_EVE_V0"`, display names `eve-v0-agent-${AGENT_ID_DOER}-m01` to `eve-v0-agent-${AGENT_ID_DOER}-m12`, off the hour, **enabled** only because route po is already tested; `penv_set DOER_EVE_V0_CONFIGS "<comma-separated names>"`. **Not** `eve-v0-m01`: setup/36 WJ-4.4 later creates Wall-E's twelve configs in this same `EVE_PROJECT`, captures them with `startswith("eve-v0-m")` and requires exactly `12`, so a doer config named `eve-v0-m…` would be captured too and fail that check; and `EVE_V0_CONFIGS` is Wall-E's name (README §7.3); a failing reconciliation reports on route po.
- **VERIFY:** When unblocked: twelve configs whose display names start `eve-v0-agent-`, and `bq ls --transfer_config` shows **no** display name starting `eve-v0-m` in `EVE_PROJECT`; `ownerInfo.email` equals `SA_EVE_V0`, none at minute `00`; one run each; `eve.findings` has twelve metric names; the reconciliation's SQL names, for each catalogued operation, the stream and event name the catalogue gives, and a run in which an operation with audit rows has an empty match set in its catalogued stream is recorded as a failure.
- **ROLLBACK:** `bq rm -f --transfer_config <name>`; rows stay.
- **EVIDENCE:** The BLOCKED line; then `${R}-11.2-v0-configs-v1.tsv`. E-09. TISAX 1.4.1, 4.2.1.

## 12. The unannounced proof and `POV_EVE_H_LIVE_RECORD`

[setup/28](../setup/28-eve-independent-proof-and-sandbox-drills.md) §1 to §3 without the witness (PV-D-03) and without the sandbox (PV-D-04). The second person leads.

### PE-12.1 The seeded-action list, the fixtures, the note

- **WHO:** **The second person** writes the list and the note; a reviewer who is not the platform owner approves; the platform owner creates the fixtures with the second person watching.
- **WHERE:** `$PLATFORM_REPO_DIR/eve/seeded-actions.md`; Admin console.
- **ACTION:** Copy [setup/28](../setup/28-eve-independent-proof-and-sandbox-drills.md) EV-1.1's five reversible actions unchanged (role privilege add and remove, OU description edit, child OU create and remove, role rename, role create and delete). Create the fixtures `/Automation/Eve-Proof` and the role `zz-eve-proof-role`, assigned to nobody (`Assumption:` `/Automation` exists; if not, the second person names the parent and records it); `penv_set EVE_PROOF_OU` and `penv_set EVE_PROOF_ROLE`. Each action must print at least one rule id of PE-7.3 (EV-1.3's check); an action that does not may not be drawn. The note, initialled by both: a proof happens in the next 30 days; the platform owner is not told when or which; during the window they open no grant on `EVE_PROJECT`, query nothing about Eve and merge nothing to `eve/config`.
- **VERIFY:** List merged without the platform owner's review; fixtures visible to the second person; creation events seen in `eve_workspace_logs`; note initialled.
- **ROLLBACK:** Revert the list; delete the fixtures, role first.
- **EVIDENCE:** `${R}-12.1-proof-setup-v1` in `EVIDENCE_INTERIM_LOCATION`. E-08. TISAX 5.2.6.

### PE-12.2 The unannounced window (**waits on PE-10.4**)

- **WHO:** The second person opens it and verifies; the platform owner performs one action and **verifies nothing**.
- **WHERE:** Any channel the second person chooses; Admin console as `sa-1-admin@`; the second person's own session.
- **ACTION:** [setup/28](../setup/28-eve-independent-proof-and-sandbox-drills.md) EV-2.1 to EV-2.7 without EV-2.8: at an unannounced moment in business hours, the second person asks for action *k* with a drill token; the platform owner performs and reverses it and replies with the UTC minutes only. The second person waits `reporting.detect_to_notice_minutes`, then records alone: the route po notification on their own devices (with delay); the `eve_workspace_logs` rows carrying the token; the `eve.findings` row with `subject = sa-1-admin@`; that the platform owner received nothing; that no grant on `EVE_PROJECT` and no merge to `eve/config` happened in the window.
- **VERIFY:** All five present. A missing notification is not retried quietly: it is a finding against PE-7.3 or PE-10.2, and the proof is rerun in a new window. Record at `eve/records/<date>-eve-proof.md`, then `penv_set POV_EVE_PROOF_RECORD "<path>"`.
- **ROLLBACK:** Not applicable; a failed window is recorded as failed.
- **EVIDENCE:** The record, signed by the second person; `evidence_add PE-12.2 eve-proof E-08 5.2.6 repo:"$POV_EVE_PROOF_RECORD"`. TISAX 5.2.6, 1.6.1.

### PE-12.3 The anti-silencing checks

- **WHO:** The platform owner attempts; the second person observes and records.
- **WHERE:** The git host; shell; the second person's own session.
- **ACTION:** (1) [setup/28](../setup/28-eve-independent-proof-and-sandbox-drills.md) EV-3.1 and EV-3.2 unchanged: an unreviewed merge, a self-approved merge and a direct push to `eve-config` are each refused for the protection reason. (2) EV-3.3: no binding on `EVE_PROJECT` names `sa-1-admin@`; no human holds `serviceAccountUser` or `serviceAccountTokenCreator` on an Eve account. (3) EV-3.4 adapted: the sink is not disabled, its filter equals the merged file, the query set is enabled. (4) A **declared** silencing: the second person approves a grant under which the platform owner disables `eve-h-freshness`; the absence alarm must reach the second person (PE-10.5's path) and the fingerprint recomputed by the second person must differ from `EVE_FINGERPRINT_BASELINE` (while PE-9.4 is BLOCKED, (4) records the alarm half and the fingerprint half as BLOCKED). Re-enable; the fingerprint must return to baseline.
- **VERIFY:** Three refusals naming the protection; the IAM reads clean; the alarm received; the fingerprint changed and returned. Record at `eve/records/<date>-anti-silencing.md`; `penv_set POV_ANTI_SILENCING_RECORD "<path>"`.
- **ROLLBACK:** Close the test pull requests; re-enable the config.
- **EVIDENCE:** The record; `evidence_add PE-12.3 anti-silencing E-08 5.3.1 repo:"$POV_ANTI_SILENCING_RECORD"`. TISAX 5.3.1, 5.2.6, 4.2.1.

### PE-12.4 Write and sign `POV_EVE_H_LIVE_RECORD`

- **WHO:** **The second person** writes and signs; the security reviewer countersigns when appointed; the platform owner reads it and signs nothing.
- **WHERE:** `$PLATFORM_REPO_DIR/eve/records/<date>-eve-h-live.md`.
- **ACTION:** Sections: **What is live** (the rules, the streams from `EVE_EDITION_COVERAGE_RECORD`, the routes and their tested delays, the absence alarm's observed delay). **What is not live, and who owns it** (every BLOCKED and PENDING line of this file; the streams not shared; route sh if `PENDING`; the SI rules without their view; Eve v0 until §11). **The proof** (`POV_EVE_PROOF_RECORD`, `POV_ANTI_SILENCING_RECORD`, `EVE_FINGERPRINT_BASELINE`). **Residual risk, accepted**, in these words: Eve is detection-grade only; it sits inside the reach of the administrators it watches; a super admin can turn off sharing, and an organisation administrator can remove the project lien, and Eve's report of either depends on the absence alarm reaching the second person; the second person owns `eve-owners@` and so can read and alter Eve's findings about themself, which nothing in the POV prevents; acknowledgement is business hours only; nothing leaves the tenant. **Consequence**: Eve-H is live for the POV; super-admin containment is not claimed. The record is checked for the banned word before signing.

```bash
F="$PLATFORM_REPO_DIR/eve/records/<date>-eve-h-live.md"
grep -n -i 'independen' "$F" && echo "STOP: banned word in the record" || echo "banned word absent"
```

- **VERIFY:** `banned word absent`; the second person's signature; merged by pull request; `penv_set POV_EVE_H_LIVE_RECORD "eve/records/<date>-eve-h-live.md"`. While PE-10.4 is BLOCKED this step does not run, and POV 07's optional Tier P step cannot open.
- **ROLLBACK:** Superseded by a new record, never edited.
- **EVIDENCE:** `evidence_add PE-12.4 eve-h-live E-08 1.6.1 repo:"$POV_EVE_H_LIVE_RECORD"`. E-08, E-05. TISAX 1.6.1, 5.2.4.

## Verification checklist for the whole part

- [ ] SD-11 DPO record read and confirmed before any resource existed (PE-0.2); `EVE_DPO_RECORD` and `EVE_LOGIN_SCOPE` set.
- [ ] Route for reports about the second person: an address, or a dated `PENDING` (PE-0.3); never the second person or the platform owner.
- [ ] `factory/runs/eve-prod.json` merged with the second person's approval **before** `EVE_PROJECT` existed (PE-1.1a); the project created with `--no-enable-cloud-apis`, the spec's ten labels and a delete lien, tags inherited and none bound on it (PE-1.2); `_Default` regional, `_Trace` in `europe-west1`, a 200 budget with four rules, two Essential Contacts (PE-1.4a); `fm-zero-diff.py live` `ZERO-DIFF` with only the two PE-9.1 `PENDING` lines (PE-1.6), then `ZERO-DIFF` without `--accept-pending` (PE-9.1a), each report initialled by the second person; `BD-P06-3` written.
- [ ] `EVE_PROJECT` in `fld-controllers-prod`; `aiplatform` denied **on the project**, the effective read and a refused `ai models list` recorded (never a `services enable` test); no `admin`, `run`, `secretmanager`; no `user:` binding; `ENT_PROJECT_REPAIR_EVE` approved only by the second person, and one grant proven `ACTIVE` and revoked **before** `roles/owner` was removed (PE-1.5 parts b then c).
- [ ] Rings `eve`/`europe-west1` and `eve-eu`/`europe`; HSM keys; one service-agent binding per key.
- [ ] `eve`, `eve_workspace_logs`, `eve_quality` in `EU` with `eve-evidence-eu`; one `OWNER` entry each before any writer; expiry proven on a later table. `eve_workspace_reports` not created.
- [ ] Bucket in `europe-west1` with `eve-evidence`, locked at `EVIDENCE_RETENTION_DAYS` with the second person in the witness column; lien listed; protection alert matching a real entry.
- [ ] `EVE_EDITION_COVERAGE_RECORD` merged; no rule names an unseen stream; the streams were read by the second person or the Cloud Logging owner, never the platform owner, who holds no organisation `privateLogViewer`.
- [ ] `eve-workspace-audit` with no actor exclusion, Login and OAuth clauses restricted to `eve/watched-actors.txt` unless `EVE_LOGIN_SCOPE=all` (BD-P06-1), `all_watched = true` read by the second person, created disabled and enabled only after its writer held `WRITER` (PE-6.3a before PE-6.3b), partitioned tables, the identity expiry, no standing organisation `configWriter`.
- [ ] `eve-config` refuses the platform owner's unreviewed merge, self-approval and direct push.
- [ ] Roster seeded by two readers; diff BLOCKED or fixture-tested.
- [ ] No access token on any command line (PE-9.2 passes it on standard input).
- [ ] `eve-verifier@`, `eve-v0@` keyless; every transfer config `ownerInfo.email` is the service account; created disabled; none on the hour.
- [ ] Absence alarm and routed policies exist; route po received by the second person alone; route sh by the security reviewer or `PENDING`.
- [ ] Fingerprint baseline recomputed by the second person, or BLOCKED with PB-03.
- [ ] `POV_EVE_FIRST_RUN_RECORD`, `POV_EVE_PROOF_RECORD`, `POV_ANTI_SILENCING_RECORD`, `POV_EVE_H_LIVE_RECORD`, or their BLOCKED lines in the POV README index.
- [ ] The word "independent" appears in no Eve record (`grep -rni independen eve/records/` prints nothing).
- [ ] POV 01's `RETIRED_NAMES_CHECK` passes on this file: no reserved Wall-E name and no retired name in any command.

## What the next file needs from this one

- **POV 07** (the doer): `POV_EVE_H_LIVE_RECORD` before its optional Tier P step (the schema makes Eve the verifier); `SA_EVE_V0` for the `READER` entry on `DOER_AUDIT_DS` that POV 07 grants; `EVE_EVIDENCE_BUCKET` for the doer's `ladder/` prefix grant; `EVE_WS_LOGS_DS` for reconciliation; route po for K-drill reporting.
- **POV 08** (Mo): `EVE_QUALITY_DS` for `mo-metrics@`'s reader grant (made in POV 08); `EVE_DS` findings as an input to the value report.
- **POV 09** (closing): `POV_EVE_FIRST_RUN_RECORD`, `POV_EVE_PROOF_RECORD`, `POV_ANTI_SILENCING_RECORD`, `POV_EVE_H_LIVE_RECORD`, `EVE_EDITION_COVERAGE_RECORD`, `EVE_FINGERPRINT_BASELINE`, route delays and the absence alarm's delay for the evidence pack; this file's BLOCKED and PENDING lines for "what was not proved"; deviation row BD-P06-1 (Login and OAuth copied for watched actors only) for the hand-over table, so the full build's unrestricted filter of setup/24 EW-1.2 is applied only under a superseding SD-11 record; `factory/runs/eve-prod.json` and PE-9.1a's `ZERO-DIFF` report with `BD-P06-3`, for 09's run-spec precondition and §6 row 17.
- **The full build** ([setup/23](../setup/23-eve-project-and-evidence-stores.md) to [28](../setup/28-eve-independent-proof-and-sandbox-drills.md)): every resource here, read back not recreated; it adds `eve_workspace_reports`, `eve@`, the poll, the reconciler jobs, the writer custom roles, the twin and the witness.

## Sources

Read on 2026-09-16:

- Share data with Google Cloud services (console path; edition-conditional events; page updated 2026-09-10): https://knowledge.workspace.google.com/admin/getting-started/share-data-with-google-cloud-services
- Data retention and lag times (Admin, Login, SAML near real time; OAuth token a couple of hours; Groups tens of minutes; 6 months each): https://knowledge.workspace.google.com/admin/reports/data-retention-and-lag-times
- Google Workspace audit logs in Cloud Logging (service names; organisation level; region not selectable; not covered by the Data Region Policy): https://docs.cloud.google.com/logging/docs/audit/gsuite-audit-logging
- gcloud logging sinks create (`--disabled`, `--include-children`, `--use-partitioned-tables`, `--log-filter`): https://docs.cloud.google.com/sdk/gcloud/reference/logging/sinks/create
- gcloud logging sinks update (`--no-disabled` enables a disabled sink; `--organization`): https://docs.cloud.google.com/sdk/gcloud/reference/logging/sinks/update
- Configure sinks (writer identity, BigQuery Data Editor): https://docs.cloud.google.com/logging/docs/export/configure_export_v2
- Scheduling queries (service account, default credentials, on-the-hour warning, 5-minute minimum): https://docs.cloud.google.com/bigquery/docs/scheduling-queries
- Manage transfers (the `disabled` field and `updateMask`; `bq mk --transfer_run`; `ownerInfo`): https://docs.cloud.google.com/bigquery/docs/working-with-transfers
- Monitor transfers (resource `bigquery_dts_config`, label `config_id`, log name, severities, "Completed run count"): https://docs.cloud.google.com/bigquery/docs/dts-monitor
- Debugging functions (`ERROR`): https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/debugging_functions
- BigQuery CMEK (`EU` dataset needs a `europe` ring; encryption agent name; the agent is not created with the project, `bq show --encryption_service_account --project_id` triggers it): https://docs.cloud.google.com/bigquery/docs/customer-managed-encryption
- Cloud KMS locations (HSM in `europe` multi-tenant only; `europe-west1` available): https://docs.cloud.google.com/kms/docs/locations
- Bucket Lock, concept and use (irreversible; project lien): https://docs.cloud.google.com/storage/docs/bucket-lock and https://docs.cloud.google.com/storage/docs/using-bucket-lock
- Restricting resource usage and its supported services (`aiplatform.googleapis.com` listed; the constraint "controls the runtime access to all in-scope resources"; the refusal text): https://docs.cloud.google.com/resource-manager/docs/organization-policy/restricting-resources and https://docs.cloud.google.com/resource-manager/docs/organization-policy/restricting-resources-supported-services
- Log-based alerts (`conditionMatchedLog`, rate limit, `autoClose` minimum 1,800 s): https://docs.cloud.google.com/logging/docs/alerting/log-based-alerts
- gcloud ai models list (`--region`, `--project`): https://docs.cloud.google.com/sdk/gcloud/reference/ai/models/list
- Log-based metrics (no backfill): https://docs.cloud.google.com/logging/docs/logs-based-metrics
- Alerting concepts (metric-absence conditions): https://docs.cloud.google.com/monitoring/alerts/concepts-indepth
- Notification options (SMS reliability; email to a single address): https://docs.cloud.google.com/monitoring/support/notification-options
- gcloud projects create; gcloud identity groups create; gcloud identity groups memberships add; gcloud pam entitlements create: https://docs.cloud.google.com/sdk/gcloud/reference/projects/create, https://docs.cloud.google.com/sdk/gcloud/reference/identity/groups/create, https://docs.cloud.google.com/sdk/gcloud/reference/identity/groups/memberships/add, https://docs.cloud.google.com/sdk/gcloud/reference/pam/entitlements/create
- PAM entitlement file fields: https://docs.cloud.google.com/iam/docs/pam-create-entitlements
- For PE-1.2 and PE-1.4a: gcloud projects create (`--no-enable-cloud-apis`; updated 2026-05-27); Enabled services (the services enabled by default on a new project; updated 2026-09-09); gcloud alpha resource-manager liens create (`--restrictions`, `--reason`, `--origin`; updated 2026-05-27); gcloud resource-manager tags bindings list (`--parent`, `--effective`; updated 2026-05-27); gcloud logging buckets create (`--location`, `--retention-days`, `--description`; updated 2026-05-27); Regionalised logs (the `_Default` update and its filter; "You can't change the `_Required` sink"; updated 2026-09-09); gcloud beta observability buckets (only `describe`, `list`, `datasets`; updated 2026-05-27); Observability `projects.locations.buckets.create` (`POST .../v1/{parent}/buckets`, `bucketId` required; updated 2026-08-24); Create observability buckets (`_Trace`, 30-day retention omitted; updated 2026-09-10); gcloud billing budgets create (updated 2026-05-27); gcloud essential-contacts create (updated 2026-05-27); Manage Essential Contacts (the API must be enabled for gcloud use; the project is not named; updated 2026-09-09): https://docs.cloud.google.com/sdk/gcloud/reference/projects/create, https://docs.cloud.google.com/service-usage/docs/enabled-service, https://docs.cloud.google.com/sdk/gcloud/reference/alpha/resource-manager/liens/create, https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/tags/bindings/list, https://docs.cloud.google.com/sdk/gcloud/reference/logging/buckets/create, https://docs.cloud.google.com/logging/docs/regionalized-logs, https://docs.cloud.google.com/sdk/gcloud/reference/beta/observability/buckets, https://docs.cloud.google.com/stackdriver/docs/reference/observability/api/rest/v1/projects.locations.buckets/create, https://docs.cloud.google.com/trace/docs/create-observability-buckets, https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/create, https://docs.cloud.google.com/sdk/gcloud/reference/essential-contacts/create, https://docs.cloud.google.com/resource-manager/docs/manage-essential-contacts
- The run spec and the checker (PE-1.1a, PE-1.6, PE-9.1a): [setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md) FM-1.1, FM-1.2, FM-2.1, FM-2.3, FM-2.6 to FM-2.11, FM-2.21, FM-2.22 and §4; POV [04](04-the-contract-register-agent-ids-and-schemas.md) PC-4.2a to PC-4.2d.
- gcloud pam grants create, approve, revoke (`--entitlement`, `--location`, `--reason`; project scope through `--project`): https://docs.cloud.google.com/sdk/gcloud/reference/pam/grants/create, https://docs.cloud.google.com/sdk/gcloud/reference/pam/grants/approve, https://docs.cloud.google.com/sdk/gcloud/reference/pam/grants/revoke
- PAM overview (grants applied as role bindings with time-based IAM Conditions; `ACTIVE`; revoked grants deleted after 30 days): https://docs.cloud.google.com/iam/docs/pam-overview
- Logging query language (a field compared with a parenthesised OR list applies to each element; a query can't exceed 20,000 characters): https://docs.cloud.google.com/logging/docs/view/logging-query-language
- curl manual, `-H @-` reads headers from standard input: https://curl.se/docs/manpage.html
- Admin audit, delegated admin settings events (`ASSIGN_ROLE`, `UNASSIGN_ROLE`, parameters `ROLE_NAME`, `USER_EMAIL`): https://developers.google.com/workspace/admin/reports/v1/appendix/activity/admin-delegated-admin-settings

Full-set sources for commands reused unchanged, each verified by that file on 2026-09-15 or 2026-09-16: [setup/23](../setup/23-eve-project-and-evidence-stores.md) §3, §4, §7; [setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) §1; [setup/25](../setup/25-eve-human-super-admin-detections.md) §2, §6, §8; [setup/26](../setup/26-eve-reporting-and-witness-export.md) §0, §3; [setup/28](../setup/28-eve-independent-proof-and-sandbox-drills.md) §1 to §3; [setup/36](../setup/36-wall-e-joins-to-eve-and-mo.md) §1, §4.

## Unverified on 2026-09-16, and what settles each

| Item | Why unsettled | Settled at |
|---|---|---|
| A **successful** Data Transfer run writes an `INFO` entry that the metric of PE-9.3 can count, and a failed run's `INFO` entries do not mask its failure | The monitoring page names the severities and the `config_id` label, not the success message; it names a "Completed run count" metric with a `succeeded` state but not its metric type string | PE-10.5 (the alarm does not fire while runs succeed, and fires when paused); the failed-run case by PE-10.2's "Eve query broken" policy until the completed-run metric replaces the log-based one |
| An `ERROR()` raised in a scheduled script appears in the run's Cloud Logging entry with its text, so the route filters of PE-10.2 match | Not stated on the pages read | PE-10.4's seeded finding |
| The exact `logName` or service string of Workspace Access Transparency entries | The audit-log page summary did not quote it | PE-5.2 on an edition that shares it; otherwise not needed |
| `gcp.restrictServiceUsage` with `inheritFromParent: true` on the project merges with a folder allow-list as intended, and a Vertex AI call is refused **by the constraint** rather than only because the API is off | The restricting page shows the org-level deny form only and describes runtime access, not enablement | PE-1.3's effective read, and a refusal text naming `constraints/gcp.restrictServiceUsage` |
| Whether `bq mk --transfer_config` accepts a config created disabled in one call | The bq reference page could not be read; the PATCH form is documented | PE-9.2 uses create then PATCH |
| Whether the creator needs `iam.serviceAccountUser` on the pinned service account | Not read on the day | PE-9.2's time-boxed binding |
| The JSON field name in `bq show --encryption_service_account --format=json` | The CMEK page gives the command and the address pattern, not the JSON key | PE-2.4's `bigquery agent ok` line |
| Groups Enterprise log lag | The lag page gives none | PE-7.2 keeps 240 minutes as `Assumption:` |
| `protoPayload.authenticationInfo.principalEmail` names the signing-in user on Login entries and the granting user on OAuth Token entries | The audit-log page summary did not quote the field per stream | PE-6.3's `all_watched` query, run by the second person |
| The exact grant state string after `gcloud pam grants revoke` | The overview lists revoked as terminal without its enum spelling | PE-1.5 part b's describe |
| `confirm_manual`'s exact signature | POV 01 defines it | PE-5.1, PE-10.3 |
| GitHub-style branch protection read-back commands | Git host not named in the POV | PE-7.1 |
| Which project the Essential Contacts API must be enabled on when contacts are created with `--billing-project` naming another project | Google's page says only that the API must be enabled for gcloud use | PE-1.4a's first create: a refusal naming `EVE_PROJECT` adds the service to the spec by a reviewed revision before it is enabled |
| Which services Google enables as dependencies of PE-1.4's ten, and whether the checker's JSON field names (`notificationCategorySubscriptions`, `specifiedAmount.units`) are the ones the reads return | Dependencies are read from each service's page on the day; the field names are setup/17 FM-1.2's `Assumption`, proven on `CICD_PROJECT` by POV 04 PC-4.2d | PE-1.4's `extra` record and PE-1.6's report |
