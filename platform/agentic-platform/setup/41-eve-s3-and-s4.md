# 41. Eve S3 and S4: the gate limb and the signing key

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-16
- Last executed: never
- Review corrections applied on 2026-09-16, with the pages re-read that day: `E3-4.2` polls version 1 out of `PENDING_GENERATION` before anything reads it, and `E3-4.3` refuses unless that poll recorded `ENABLED`; every KMS command addresses the ring through `EVE_KEYRING` (as `EVE_KEYRING_NAME`, checked against `EVE_PROJECT` and `REGION` in the preamble) and both Policy Troubleshooter resource names are built from it; the three PEM digests are all taken from files, never from a pipe; the bucket-lock reads use the JSON field names `gcloud storage` actually renders; `E3-2.3` reads the Cloud Run v2 path `template.template.containers[0].image` and fails on an empty projection; §7.1 to §7.4 run **before** §6 because `E3-6.2` needs `EVE_RECEIPTS_DS`; `E3-7.6` maps SQL files to transfer configs by `displayName` and stops on a file that resolves to none; `E3-9.3` proves EVE-12 and EVE-22 by Policy Troubleshooter with no grant and no impersonation; values one step creates and a later step consumes (working directories, the grant name) are carried in `E3_VARS`; `pam_wait` waits for `ACTIVE`, the state PAM actually reports; the `keys/` condition derives the bucket name from `EVE_EVIDENCE_BUCKET`; `E3-1.5` derives the repository slug instead of relying on `gh`'s placeholders.
- Stage: review §2 stage 40. Two entries, not one sitting: **S3 entry** (verify the Eve-H and Eve-W halves, then make the invariant-class halt and demote live) and, after the S3 exit gate has passed at 100 %, **S4 entry** (the `eve-approval` key, the PEM archive, `eve-gate`, the receipt view, the denial suite). Between them sit at least thirty days of S3 running against real L3 batch executions. **Execution order of the S4 sitting: §4, §5, §7, §6, §8, §9, §10** — the receipts dataset of `E3-7.1` is an input to the `eve-gate` deploy of `E3-6.2`, so §7 runs first; the section numbers keep their ids.
- Step prefix: `E3`. Steps: 62. **BLOCKED:** `E3-6.1`, `E3-6.2`, `E3-6.3`, `E3-6.4`, `E3-6.5`, `E3-8.2`, `E3-8.3`, `E3-9.2`, `E3-9.4` — all on README **B-19** (Eve's `eve-gate` entrypoint, the signing path, the gate end-to-end test and the key-destruction guard tool). `E3-3.2` and `E3-3.3` refuse rather than block: they need the twelve seeded-fault fixtures of **B-09**, which [25](25-eve-human-super-admin-detections.md) already required. **IRREVERSIBLE-class:** `E3-4.2` (the key name, permanent inside a key ring that itself can never be deleted) and `E3-4.3` (the PEM object, written into a bucket whose retention policy is locked, so it can be neither replaced nor deleted before `EVIDENCE_RETENTION_DAYS` have passed).
- Replaces: [../../eve/07-build-runbook.md](../../eve/07-build-runbook.md) Phases 11 and 12 in full. Neither is executed again.
- Salvaged: Phase 11's key properties (HSM, `ASYMMETRIC_SIGN`, `EC_SIGN_P256_SHA256`, one signer), its **PEM before first use in two places** rule and the one-bucket argument, its `--max-retries=0` reasoning, its "Eve is a client everywhere" discovery shape, its three-column receipt view and the authorised-view placement argument, the `eve_authority: binding` pull-request rule, the manual-rotation rule with the 30-day overlap; Phase 12's two teardown facts, its rollback (disable, never destroy) and the EVE-1 to EVE-22 denial table; [../../eve/02-identity-and-auth.md](../../eve/02-identity-and-auth.md)'s signing-key table and its "The PEM archive, in two places, before first use"; [../../eve/05-stages.md](../../eve/05-stages.md)'s S3-entry observe-mode split and its S4-entry control list.
- Not copied: `SELECT run_id, item, verdict_ts FROM eve.verdicts`, which names a column the table does not have (S036); `gcloud kms asymmetric-sign --impersonate-service-account="$SA_EVE_VERIFIER"` as the proof that the verifier cannot sign (S137); `python setup/walle_setup.py teardown --destroy-key-versions --dry-run` as a verify, and `_pem_archive_present` as code that exists (S134); the signer binding before the audit configuration, and a whole-project-policy write from `/tmp/eve-policy.json` with no etag and no diff (S205); "retarget the transfer config's **destination dataset**" for a query whose destination is inside its own SQL (S204); `gcloud config get-value account` as a member string, and a **standing** `roles/iam.serviceAccountUser` for a human on `eve-controller@`; `${EVE_AR}` as an Eve-project image registry (S006: every Eve image is built and attested in `CICD_PROJECT`); a second bucket for the key archive.
- Applies decisions (signed in [03](03-decisions-and-people.md) before the step that needs them): E-2, E-4, E-6, E-10, E-13, E-15, E-17, E-18, E-20; **E-21**, recorded at `E3-8.1` by this file; CC-11, CC-21, CC-32; decision 11 (the blind grader), decision 36, decision 44; P13, P34, P19, P118, P143; SD-10, SD-12, SD-37, SD-44, SD-45, SD-47, SD-48.
- Closes: S036, S134, S137, S204, S205. **Defers S129** (the `eve-advisor` reporting path, M10) with a reason, an owner and the commands to be written — §14.
- Consumes: `EVE_PROJECT`, `EVE_KEYRING`, `EVE_DS`, `EVE_QUALITY_DS`, `EVE_EVIDENCE_BUCKET`, `EVE_EVIDENCE_KEY_EU`, `ENT_PROJECT_REPAIR_EVE`, `ENT_DEPLOY_CREDENTIAL_HOLDER_EVE` ([23](23-eve-project-and-evidence-stores.md)); `SA_EVE_VERIFIER`, `EVE_ROBOT`, `EVE_TOKEN_VERSION` ([24](24-eve-workspace-identity-and-audit-feeds.md)); `SA_EVE_CONSOLE`, `EVE_CONFIG_REPO`, `EVE_RECONCILER_IMAGE`, `EVE_JOB_DETECT`, `EVE_JOB_REPORTS_POLL`, `EVE_JOB_ROSTER`, `EVE_JOB_HEARTBEAT`, `EVE_CODE_COMMIT` ([25](25-eve-human-super-admin-detections.md)); `EVE_INCIDENTS_TABLE`, `EVE_PAGES_TABLE`, `NOTIF_CH_EVE_EMAIL_SECOND_HUMAN`, `NOTIF_CH_EVE_SMS_SECOND_HUMAN` ([26](26-eve-reporting-and-witness-export.md)); `WITNESS_BUCKET`, `WITNESS_ALERT_FINGERPRINT` ([27](27-witness-grants-and-alarms.md)); `EVE_H_LIVE_RECORD` ([28](28-eve-independent-proof-and-sandbox-drills.md)); `SA_EVE`, `SA_EVE_V0`, `EVE_MIRROR_DS`, `EVE_V0_CONFIGS` ([36](36-wall-e-joins-to-eve-and-mo.md)); `SA_ACTIONS`, `WALLE_PROJECT`, `WALLE_AUDIT_DS` ([31](31-wall-e-project-and-data-plane.md)); `ACTIONS_URL`, `SUPER_ACTIONS_URL` ([33](33-wall-e-action-services-and-approval-surfaces.md)); `SA_MO_METRICS`, `MO_PROJECT` ([22](22-mo-foundations.md)); `WALLE_REPO_REMOTE` ([30](30-wall-e-workspace-side.md)); `SA_WALLE_DEPLOYER`, `AR_PLATFORM`, `CICD_PROJECT` ([10](10-core-projects-and-ci-identities.md)); `BINAUTHZ_ATTESTOR`, `SA_VALIDATOR_CUSTODIAN` ([11](11-keys-and-validator-custodian.md)); `REGION`, `BQ_LOCATION`, `EVIDENCE_RETENTION_DAYS` ([01](01-prerequisites-and-conventions.md), [03](03-decisions-and-people.md)); Stage 0 itself.
- Produces: `EVE_KEY_VERSION`, `EVE_GATE_URL`, `EVE_RECEIPTS_DS`; the S3-entry record, the S3 exit-gate record and the S4-entry record; decision record **E-21**; the first cell at `eve_authority: binding`.
- Commands, flags, roles, APIs, constraints and console paths checked against Google's documentation on 2026-09-15 (§16). What could not be settled that day is in §15.

## What this part builds

Two authorities, on opposite schedules. That is the whole design of this file, and it is why one file carries two stage entries that are weeks apart.

**Halting and demoting can only make less happen.** They go live at S3 entry, for the closed invariant class only, and a human undoes either in seconds with one authenticated call. **Signing makes more happen.** It waits for the S3 exit gate — twelve seeded invariant-class faults caught at 100 %, both negative controls silent, at least thirty days of observation — and only then does a key exist at all.

Nothing here is built early "so it is ready". A signing key that gates nothing is an asset an attacker can reach and a key version ageing inside the evidence horizon.

| # | Thing | Where it ends up |
|---|---|---|
| 1 | The S3-entry verification of both halves: Eve-H (23 to 28) and Eve-W (36), read as records rather than rebuilt | `${R}-1.6` S3-entry record |
| 2 | The invariant class live, the rate-based class still observe-only, by one reviewed `eve/config` merge | `EVE_CONFIG_REPO`, a new `eve_config_version` |
| 3 | The S3 exit gate: twelve faults, two negative controls, the blind grader, thirty days | `${R}-3.5` S3 exit record, signed by the Eve owner and the security reviewer |
| 4 | `eve-approval`: HSM, `EC_SIGN_P256_SHA256`, in ring `EVE_KEYRING` in `EVE_PROJECT`, one signer | `EVE_KEY_VERSION` |
| 5 | The public key archived in two places **before the first signature**, one of them a locked bucket | `gs://…/keys/eve-approval-v1.pem`; `contracts/eve-public-keys/1.pem` |
| 6 | Data Access audit logging on `AsymmetricSign` **before** the signer binding exists | `EVE_PROJECT`'s `auditConfigs` |
| 7 | `eve-gate`: its own Cloud Run job, `--max-retries=0`, deterministic, no model call | `EVE_GATE_URL` |
| 8 | The three-column receipt view in its own dataset, authorised on `eve` | `EVE_RECEIPTS_DS` |
| 9 | The key-destruction guard, given one owner and a self-test | decision **E-21**; `eve/tools/destroy_key_version.py` |
| 10 | The denial suite EVE-1 to EVE-22, each with a runner named | `${R}-9.*` |

### The two sentences this file has to keep true

**No model produces an Eve approval.** `eve-gate` is deterministic code: it recomputes five predicates and signs or refuses. `aiplatform.googleapis.com` is denied at project level on `EVE_PROJECT` by [17](17-factory-module-equivalents-and-tier-r-gate.md) FM-4.2, neither Eve identity holds any `aiplatform.*` permission, and `modelarmor` is not enabled because nothing here calls a model. Verified at `E3-1.3` and again at `E3-6.4`.

**No single human produces an Eve approval either.** The key is usable only by `eve-controller@`. No human holds `roles/iam.serviceAccountTokenCreator` or a standing `roles/iam.serviceAccountUser` on that account, so no human can mint its token; the `actAs` needed to attach it to a job exists only for the life of a PAM grant the **second human** approves, and is proved gone at the end of the step. The platform owner builds the key and cannot use it; the Eve owner approves the grant and holds no signer role. Verified at `E3-5.8` by `gcloud asset analyze-iam-policy`, which is the check [38](38-super-admin-gate-and-grant.md) `${R}-7.6` set the precedent for on the Workspace side.

### Why the halt goes live here and not in 25 or 36

[25](25-eve-human-super-admin-detections.md) deployed the eighteen detection rules with `default_action.halt` set to the literal `halt_target_pending`, because no halt endpoint existed. [36](36-wall-e-joins-to-eve-and-mo.md) `WJ-5.4` wired the two real endpoints and proved one halt accepted on each service. What neither did — deliberately — is decide **which class of rule is allowed to pull that lever unattended**. That is a stage decision, it belongs to S3 entry, and it is §2 of this file.

```mermaid
flowchart TD
  A["E3-0 Refusals: records, decisions, people"] --> B["E3-1 S3 entry: verify Eve-H and Eve-W"]
  B --> C["E3-2 Invariant class live; rate-based still observe"]
  C --> D["30+ days of S3 against real L3 batch executions"]
  D --> E["E3-3 S3 exit gate: 12 faults, 2 negative controls, blind grader"]
  E --> F["E3-4 The key and the PEM archive"]
  F --> G["E3-5 Audit configuration, then the signer binding"]
  G --> I["E3-7 Receipt view, Mo carve-out, the S4 query changes"]
  I --> H["E3-6 eve-gate (BLOCKED on B-19); needs EVE_RECEIPTS_DS from E3-7.1"]
  H --> J["E3-8 The key-destruction guard (E-21)"]
  J --> K["E3-9 The denial suite; the first binding cell"]
  K --> L["E3-10 Close: S4 entry record"]
  F -.->|"a defect, a suspected compromise"| M["Rollback: disable the version, never destroy it"]
```

Conventions of [01](01-prerequisites-and-conventions.md) apply to every step: `checkpoint <id> START` before ACTION and `checkpoint <id> DONE <witness> <evidence>` after VERIFY; records named `<date>-<step>-<slug>-v<n>` under `BUILD_LOG_DIR/records/`, each registered with `evidence_add`. Deviation rows use ids `BD-41-<n>`. Every `gcloud` call passes `--project`, `--organization`, `--folder` or `--location`; there is no default project. No step prints, pastes or stores a secret value; the only key material this file handles is a **public** key, and it is handled as a file with a digest, never as a pasted string. Every shell block in this file, unless the step says otherwise, starts as:

```bash
source ~/.platform-env
penv_guard
source "$PLATFORM_REPO_DIR/pam/tools/pam.sh"
R="$BUILD_LOG_DIR/records/$(date -u +%F)-E3"
E3_VARS="$BUILD_LOG_DIR/work/41-sitting-vars.sh"; mkdir -p "$BUILD_LOG_DIR/work"; touch "$E3_VARS"; . "$E3_VARS"
e3_set() { printf 'export %s="%s"\n' "$1" "$2" >> "$E3_VARS"; export "$1=$2"; }
need EVE_PROJECT EVE_KEYRING REGION
EVE_KEYRING_NAME="${EVE_KEYRING##*/}"
[ "$EVE_KEYRING" = "projects/${EVE_PROJECT}/locations/${REGION}/keyRings/${EVE_KEYRING_NAME}" ] || { echo "STOP: EVE_KEYRING is not a ring in EVE_PROJECT at REGION: $EVE_KEYRING"; false; }
```

**Values that cross steps.** A working directory made by `mktemp -d`, a clone path or a PAM grant name is created in one step and consumed in a later one, sometimes a section away, and every block above starts from a fresh shell. Such a value is therefore written once with `e3_set NAME value` into `E3_VARS`, which the preamble sources, and every consuming step opens with `need NAME` so an empty value stops the block rather than sending `cp` to `/eve-approval-v1.pem` or `pam_revoke` to nothing. `E3_VARS` is a working file, not a record: it holds paths and grant names only, is never committed, and is emptied at the start of each sitting by `E3-0.3`. The three sittings and their sections: **S3 entry** is §0 to §2; **the S3 exit gate** is §3 (with §0 re-read); **S4 entry** is §4 to §10 in the order §4, §5, §7, §6, §8, §9, §10. Nothing in `E3_VARS` is ever needed across two sittings.

**The ring is addressed through `EVE_KEYRING`.** [23](23-eve-project-and-evidence-stores.md) `EP-3.3` recorded it as a full resource name, `projects/…/locations/europe-west1/keyRings/eve`. Every KMS command here passes `--keyring="$EVE_KEYRING_NAME"` (the last path segment) with `--location="$REGION"` and `--project="$EVE_PROJECT"`, and the preamble proves the three agree before any block runs; the full resource names for Policy Troubleshooter and `analyze-iam-policy` are built as `//cloudkms.googleapis.com/${EVE_KEYRING}/cryptoKeys/eve-approval`. No step spells the ring name as a literal.

## Preconditions

- [ ] [39](39-wall-e-stage-0.md) complete: `STAGE0_RECORD` exists. Wall-E is at Stage 0, the ladder is published, and there are real executions for Eve to observe. This file never opens earlier: there is nothing at S3 to verify if nothing has run.
- [ ] [28](28-eve-independent-proof-and-sandbox-drills.md) complete: `EVE_H_LIVE_RECORD` exists, and the monthly `DR-28-1` blind proof has been re-run at least once since. Eve has been watching the human super admins since before Wall-E's first project.
- [ ] [36](36-wall-e-joins-to-eve-and-mo.md) complete: `SA_EVE` and `SA_EVE_V0` exist, `EVE_MIRROR_DS` holds nine tables, the invoker bindings and the control allowlist are in place, and `WJ-5.5`'s halt proof on **both** action services is recorded.
- [ ] `EVE_CODE_COMMIT` set, with green CI, and the commit carries `tests/seeded_faults/` with twelve fixtures and two negative controls. Without them §3 cannot be run and S4 cannot be entered — README **B-09**.
- [ ] Wall-E has been running **L3 batch executions for at least thirty days** at the moment §3 opens, counted from `walle_audit` and not from a calendar note (`E3-3.1`).
- [ ] [03](03-decisions-and-people.md): **E-18** signed — `thresholds.yaml`'s numbers are measurements taken at S2, not guesses; **E-4** signed — `eve_authority` is the per-cell switch and absent reads as advisory; **E-13** signed and **decision 11** closed — a **blind grader who is not the ladder owner** is named and has been grading; **E-15** signed — where the seeded-fault harness runs; **CC-32** recorded — scheduled F2 is L3 at S2 and S3 and reaches L4 here; **P118** in force; **P13** signed, so `EVIDENCE_RETENTION_DAYS` is a number and not `*tbd*`.
- [ ] `B-20` cleared: the security reviewer is appointed and named. He signs the S3 exit gate; the platform owner signs neither gate in this file.
- [ ] The second human is the Eve owner of record, owner of `GRP_EVE_OWNERS` and a required reviewer on `eve/config` ([06](06-organisation-bootstrap-and-roster.md), [25](25-eve-human-super-admin-detections.md)). He approves every PAM grant used here (SD-12).
- [ ] `ENT_PROJECT_REPAIR_EVE` is `AVAILABLE` and its `CTL` override carries `roles/cloudkms.admin` ([23](23-eve-project-and-evidence-stores.md) `EP-1.5`). Without it the key cannot be created by anybody: [17](17-factory-module-equivalents-and-tier-r-gate.md) `FM-2.19` removed the creator's Owner.
- [ ] The Wall-E owner is available for the `contracts/eve-public-keys/1.pem` pull request, which needs **two distinct approving reviewers, neither the author**, and must merge **before** the first signature.
- [ ] Three sittings booked: **S3 entry** (half a day, Eve owner and platform owner), **the S3 exit gate** (two hours, Eve owner, security reviewer, blind grader), **S4 entry** (a full day, Eve owner, platform owner, Wall-E owner available). They are weeks apart and are never merged.
- [ ] A change ticket for each sitting, whose id every record quotes.

## People needed

| Role | Does | Present at |
|---|---|---|
| **Eve owner (the second human)** | Owns this file. Approves every PAM grant the platform owner uses here; reviews and merges every `eve/config` change; signs the S3-entry, S3-exit and S4-entry records; holds no signer role and no key material | all of it |
| Platform owner | Builds under PAM: creates the key, exports the PEM, deploys `eve-gate`, makes the bindings. Approves nothing, signs no gate, and cannot use what he builds | §1, §2, §4 to §9 |
| Security reviewer | Signs the S3 exit gate with the Eve owner; reads the key policy and the Policy Troubleshooter results himself; countersigns `E3-4.2` and `E3-4.3` | §3, §4, §5 |
| Blind grader (decision 11) | Has been grading through `eve.review_queue_blind` since S1; supplies the agreement figure, reported for information only | §3 |
| Wall-E owner | Raises and merges the `contracts/eve-public-keys/1.pem` pull request; confirms `walle-actions` verifies against the pinned PEM as the primary path | §4, §9 |
| Incident commander (IT security) | Witnesses the live halt and demote proof of `E3-2.4`; owns the page that a halt produces | §2 |
| Mo owner | Confirms the S4 carve-out reads what Mo expects and nothing more | §7 |
| Witness administrators | Receive the three records and the key-archive digest; confirm the push landed | §10 |
| Second operator | Confirms the halt was seen where operators read it, and clears it | §2 |

Nobody signs their own gate. The platform owner requests; the Eve owner approves; the security reviewer reads; the machine signs nothing until §6.

## Facts this file relies on, read on 2026-09-15

| Fact | Source | Consequence here |
|---|---|---|
| `gcloud kms keys create --purpose` takes `asymmetric-signing`; `--default-algorithm` takes `ec-sign-p256-sha256`; `--protection-level` takes `software`, `hsm`, `hsm-single-tenant`, `external`, `external-vpc` and defaults to `software` | `gcloud kms keys create` reference | `E3-4.2`'s three flags, each written out rather than defaulted |
| `--destroy-scheduled-duration` is "the amount of time that versions of the key should spend in the `DESTROY_SCHEDULED` state before transitioning to `DESTROYED`", in `INTEGER[UNIT]` form with `s`, `m`, `h` or `d` | same reference | `E3-4.2` sets `30d` explicitly, so the key does not depend on a default; the folder constraint then has nothing to refuse |
| "When you first create the key, the initial key version has a state of Pending generation. When the state changes to Enabled, you can use the key." `PENDING_GENERATION` "may not be used, enabled, disabled, or destroyed yet"; `GENERATION_FAILED` is terminal | *Creating asymmetric keys*; `CryptoKeyVersionState` in the REST reference | `E3-4.2` polls `versions describe 1 --format='value(state)'` until `ENABLED` before its readback, and `E3-4.3` refuses to export unless that poll recorded `ENABLED`: a `get-public-key` against a pending version fails, and a `versions list` read too early shows the wrong state |
| `gcloud storage buckets describe --format="default(retention_policy)"` prints `retention_policy:` with `effectiveTime`, `isLocked` and `retentionPeriod` beneath it; `uniform_bucket_level_access` and `public_access_prevention` are top-level snake_case fields | *Use and lock retention policies*; *Uniform bucket-level access*; *Public access prevention* | `E3-1.5` and `E3-4.5` read the JSON and assert with `jq -e '.retention_policy.isLocked == true'` rather than projecting camelCase names that render as blanks |
| A PAM grant's `state` values are `APPROVAL_AWAITED`, `SCHEDULED`, `ACTIVATING`, `ACTIVE`, `ACTIVATION_FAILED`, `DENIED`, `EXPIRED`, `REVOKING`, `REVOKED`, `ENDED`, `WITHDRAWING`, `WITHDRAWN` | *Request temporary elevated access* | `pam_wait "$g" ACTIVE`, as [12](12-privileged-access-catalogue.md) writes it; `ACTIVATED` is not a state and a wait on it never returns |
| Policy Troubleshooter takes a BigQuery table by full resource name `//bigquery.googleapis.com/projects/PROJECT/datasets/DATASET/tables/TABLE` and the permission `bigquery.tables.getData`; it "analyzes all relevant policies, memberships in Google Groups, and inheritance from parent resources" | *Troubleshoot IAM permissions in BigQuery* | `E3-9.3` proves EVE-12 and EVE-22 without opening a grant on any account, which the file's own rule at `E3-5.7` and `E3-9.2` forbids |
| The default scheduled-for-destruction duration is 30 days; a version can be restored during it; `constraints/cloudkms.minimumDestroyScheduledDuration` sets a floor and `constraints/cloudkms.disableBeforeDestroy` requires a disable first | *Destroy and restore key versions*; *Control key version destruction* | `E3-8.4`: the belt behind the guard. B21 of [13](13-organisation-policies-deny-and-pab.md) already sets both at `fld-agentic-platform` |
| Whether a **destroyed** version's public key stays retrievable is not documented | *Destroy and restore key versions* (silent on it) | Why the archive exists at all, and why `E3-4.3` precedes any signature |
| `AsymmetricSign` needs `cloudkms.cryptoKeyVersions.useToSign`, typed **`DATA_READ`**; `GetPublicKey` needs `viewPublicKey`, also `DATA_READ`; Data Access logs must be explicitly enabled | *Cloud KMS audit logging* | `E3-5.1` to `E3-5.3` run **before** `E3-5.4`, which is what S205 asked for |
| The `etag` field is optimistic concurrency control: it is returned by `getIamPolicy` and must be sent back in `setIamPolicy`; a stale etag fails with HTTP 409 | *Understanding allow policies* | `E3-5.2` keeps the etag and refuses to write without it; a whole-policy write from a hand-edited stale file is how bindings disappear |
| `gcloud policy-intelligence troubleshoot-policy iam RESOURCE --principal-email=… --permission=…` checks a principal's permission against the effective allow policy, deny policy and principal access boundary; the result is `overallAccessState`, values `CAN_ACCESS`, `CANNOT_ACCESS`, `UNKNOWN_INFO`, `UNKNOWN_CONDITIONAL` | `gcloud policy-intelligence troubleshoot-policy iam` reference; *Troubleshoot IAM permissions* | `E3-5.7` replaces the impersonation test of S137. It also covers inherited project and folder grants, which a key-level `get-iam-policy` does not |
| `roles/iam.serviceAccountTokenCreator` carries `getAccessToken`; impersonation needs it **even for a project Owner**. `roles/iam.serviceAccountUser` carries `actAs` and not `getAccessToken` | *Service account permissions*; *Use service account impersonation* | Why `--impersonate-service-account` can never be the proof of a key policy, and why `E3-5.8` looks for both roles |
| `gcloud asset analyze-iam-policy` takes `--organization\|--folder\|--project` as the scope, plus `--full-resource-name`, `--identity`, `--permissions`, `--roles`, `--analyze-service-account-impersonation`, `--expand-groups` | `gcloud asset analyze-iam-policy` reference | `E3-5.8`'s two reads, one for `actAs` on the account resource, one for impersonation reachability |
| An authorized view "must be a different dataset than the dataset used in the source query"; "the source data dataset and authorized view dataset must be in the same regional location"; the querying principal needs `roles/bigquery.dataViewer` on the **view's** dataset and no IAM permission on the source; the view is authorised through the source dataset's access list (console: Sharing → Authorize views) | *Authorized views* | `E3-7.1` to `E3-7.4`: the receipts dataset exists because the view may not sit in `eve` |
| `bq update --transfer_config` accepts `--params`, `--target_dataset`, `--display_name`, `--schedule`, `--service_account_name`, `--update_credentials`; the query text itself is changed with `--params='{"query":"…"}'` | *Scheduling queries*; bq CLI reference | `E3-7.6`, and the rule S204 asked for: a DML query's destination is inside its SQL, so `--target_dataset` moves nothing |
| Cloud Scheduler runs a Cloud Run job by `POST https://run.googleapis.com/v2/projects/PROJECT/locations/REGION/jobs/JOB:run` with an **OAuth** token (`--oauth-service-account-email`), not OIDC | *Run jobs on a schedule* | `E3-6.3`, and why `EVE_GATE_URL` holds a `:run` URI and not a service address |
| `gcloud run jobs deploy` takes `--image`, `--service-account`, `--args`, `--tasks`, `--max-retries` ("number of times a task is allowed to restart … per-task, not per-job"), `--task-timeout`, `--set-env-vars`, `--set-secrets` | `gcloud run jobs deploy` reference | `E3-6.2`: `--max-retries=0`, because a retried gate task re-signs, and a second envelope is a second authorisation |
| Cloud KMS does not support automatic rotation for asymmetric signing keys | *Key rotation* | There is no schedule to set and none to forget; `E3-10.2` puts the date in `DRILL_CALENDAR` instead |
| A locked retention policy cannot be removed or shortened, objects cannot be deleted or replaced before expiry even by a project owner, and locking applies a lien that blocks project deletion | *Bucket Lock*; *Object Retention Lock* | `E3-4.3` is **IRREVERSIBLE**: a wrong file written to `keys/` stays for `EVIDENCE_RETENTION_DAYS`. And the second teardown fact of `E3-8.5` |

## 0. The refusals, before anything is verified

### E3-0.1 Open the file and read the inputs

- **WHO:** Platform owner; the Eve owner reads the output with him.
- **WHERE:** Shell, `~/.platform-env` sourced.
- **ACTION:**

```bash
checkpoint E3-0.1 START
need EVE_PROJECT EVE_KEYRING EVE_DS EVE_WS_LOGS_DS EVE_QUALITY_DS EVE_EVIDENCE_BUCKET EVE_EVIDENCE_KEY_EU \
     SA_EVE SA_EVE_VERIFIER SA_EVE_V0 SA_EVE_CONSOLE EVE_MIRROR_DS EVE_V0_CONFIGS EVE_CONFIG_REPO \
     EVE_RECONCILER_IMAGE EVE_CODE_COMMIT EVE_TOKEN_VERSION GRP_EVE_OWNERS \
     EVE_JOB_REPORTS_POLL EVE_JOB_ROSTER EVE_JOB_DETECT EVE_JOB_HEARTBEAT \
     ENT_PROJECT_REPAIR_EVE ENT_DEPLOY_CREDENTIAL_HOLDER_EVE
need WALLE_PROJECT WALLE_AUDIT_DS SA_ACTIONS ACTIONS_URL SUPER_ACTIONS_URL WALLE_REPO_REMOTE \
     MO_PROJECT SA_MO_METRICS CICD_PROJECT AR_PLATFORM REGION BQ_LOCATION EVIDENCE_RETENTION_DAYS
need EVE_H_LIVE_RECORD STAGE0_RECORD SECOND_HUMAN_EMAIL SECURITY_REVIEWER_EMAIL BLIND_GRADER_EMAIL SA_VALIDATOR_CUSTODIAN OWNER_DAILY_ACCOUNT
awk -F'\t' '$3 == "BLOCKED" {print $2"\t"$7}' "$BUILD_LOG_DIR/checkpoints.tsv" | sort -u
grep -E '^(EP|EW|EH|ER|WG|EV|WJ)-' "$BUILD_LOG_DIR/rerun-index.tsv" | grep -i '41' || echo "no 41 re-run lines recorded"
```

- **VERIFY:** `need` is silent for all three lines and for the preamble's `EVE_KEYRING` check, which must print nothing (a `STOP` there means the ring 23 recorded is not in `EVE_PROJECT` at `REGION`, and no KMS step of this file may run). The `BLOCKED` list may contain `B-19` (this file's own, handled in §6 and §8) and must **not** contain `B-07`, `B-08` or `B-09`: Eve's schemas, its reconciler and its SQL are all prerequisites of an S3 that has already run. The re-run grep prints at least two lines — [23](23-eve-project-and-evidence-stores.md) `EP-7.7`'s `keys/` prefix grant and [36](36-wall-e-joins-to-eve-and-mo.md) `WJ-3.6`'s `mo-metrics@` grant at S4 — both closed in this file (`E3-4.3`, `E3-7.5`).
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-0.1-inputs-v1.txt`; `evidence_add E3-0.1 inputs E-05 1.4.1 build-log:records/<file> <file>`.

### E3-0.2 Refuse without the signed decisions

- **WHO:** Platform owner runs it; the Eve owner opens each record himself rather than taking an exit code on trust.
- **WHERE:** Shell; `PLATFORM_REPO_DIR/decisions/`.
- **ACTION:**

```bash
"$PLATFORM_REPO_DIR/tools/decision-need.sh" E-2 E-4 E-6 E-13 E-15 E-17 E-18 P13 P118 P143 \
    SD-10 SD-12 SD-44 SD-47 SD-48 DECISION-11 DECISION-36 CC-32
"$PLATFORM_REPO_DIR/tools/decision-check.sh" E-4 E-13 E-18
grep -c 'blind grader' "$(ls -1 "$PLATFORM_REPO_DIR"/decisions/*-blind-grader*.md | tail -n 1)"
```

- **VERIFY:** `decision-need.sh` exits `0` for every id. `E-18` names a dated window and the measured false-positive rate the thresholds came from — a record that says "to be calibrated" is not signed. `E-13` and decision 11 name the blind grader, and that name is **not** the Eve owner, the platform owner or the ladder owner. `CC-32` is recorded, so scheduled F2 is at L3 today and rises to L4 only in §9.
- **ROLLBACK:** Read only. A missing signature is not worked around; the sitting is rebooked.
- **EVIDENCE:** `${R}-0.2-decisions-v1.txt`. E-01, E-03. TISAX 1.4.1, 5.2.1.

### E3-0.3 The four standing rules of this file

- **WHO:** Eve owner reads them aloud at the start of each of the three sittings; platform owner records.
- **WHERE:** The sitting.
- **ACTION:** One command, run once at the start of each sitting so that no working directory or grant name carries over from the previous one:

```bash
: > "$E3_VARS"
wc -c "$E3_VARS"
```

  Then four rules, and each has a step that enforces it:

1. **No model produces an Eve approval.** `eve-gate` holds no model client, `aiplatform` is denied on `EVE_PROJECT`, and neither Eve identity holds any `aiplatform.*` permission (`E3-1.3`, `E3-6.4`, EVE-14).
2. **No single human produces one either.** No standing human `actAs` and no `tokenCreator` on `eve-controller@`, ever (`E3-5.8`).
3. **Humans raise autonomy, machines lower it.** Eve halts and demotes; nothing in this file lets Eve raise a level, shorten a dwell or clear its own halt. A cell becomes binding only by a merged pull request with two human approvals (`E3-9.5`).
4. **The PEM is archived before the key is used.** Not after the first signature, not at the end of the sitting (`E3-4.3`). If a signature is ever found to predate the archive, it is a severity 2 incident and the family goes to L0.

- **VERIFY:** `wc -c` prints `0`. The four rules are quoted in the sitting record with the step id that enforces each.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** `${R}-0.3-rules-v1.md`. E-13. TISAX 1.4.1.

### E3-0.4 The people, and the two that may not be the same person

- **WHO:** Eve owner confirms; ISMS is told of any doubling.
- **WHERE:** `PLATFORM_REPO_DIR/identity/people.yaml`.
- **ACTION:** Three roles carry a separation rule in this file, on top of [11](11-keys-and-validator-custodian.md) §7.1's forbidden pairs:

| Pair | Rule |
|---|---|
| Eve owner / platform owner | Never the same person. The Eve owner approves the grant under which the key is made; the platform owner makes it |
| Blind grader / ladder owner | Never the same person (E-13). Without this the blind sample is blind in form only and the compromised-Eve bound is weaker than claimed |
| Security reviewer / platform owner | Never the same person. He signs the S3 exit gate the platform owner's work is measured by |

- **VERIFY:** `people.yaml` names all three with dates and the three pairs are distinct people. A doubling anywhere needs a dated ISMS exception naming what compensates; without one, §3 does not open.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-0.4-people-v1.txt`. E-13. TISAX 1.2.1.

## 1. S3 entry: verifying the two halves

Nothing in this section builds. Everything in it was built in [23](23-eve-project-and-evidence-stores.md) to [28](28-eve-independent-proof-and-sandbox-drills.md) and [36](36-wall-e-joins-to-eve-and-mo.md). What S3 entry asks is a different question: **is it all still true on the day the halt goes live?**

### E3-1.1 Eve-H is still running, read from its own outputs

- **WHO:** Platform owner runs; Eve owner reads.
- **WHERE:** Shell.
- **ACTION:**

```bash
checkpoint E3-1.1 START
for j in "$EVE_JOB_REPORTS_POLL" "$EVE_JOB_ROSTER" "$EVE_JOB_DETECT" "$EVE_JOB_HEARTBEAT"; do
  gcloud scheduler jobs describe "${j##*/}" --project="$EVE_PROJECT" --location="$REGION" --format='value(name,state,schedule,lastAttemptTime)'
done
bq --project_id="$EVE_PROJECT" query --use_legacy_sql=false --format=csv \
  "$(cat "$PLATFORM_REPO_DIR/eve/checks/s3_entry_feeds.sql")"
gcloud logging read 'resource.type="cloud_run_job" AND severity>=ERROR' --project="$EVE_PROJECT" --freshness=7d --limit=20 --format='value(timestamp,jsonPayload.message)'
```

- **VERIFY:** All four scheduler jobs `ENABLED` with a `lastAttemptTime` inside their own period. The feeds query returns a row per Workspace stream with a non-zero seven-day count and a latest timestamp inside the lag budget; a stream at zero is a severity-1 evidence-perimeter finding and stops S3 entry. `eve.incidents` has no open severity 1. `eve.pages` shows the monthly `DR-28-1` proof page inside the last 31 days. No repeated job error in seven days.
- **ROLLBACK:** Read only. A failing feed is repaired in [24](24-eve-workspace-identity-and-audit-feeds.md) or [25](25-eve-human-super-admin-detections.md), not here.
- **EVIDENCE:** `${R}-1.1-eve-h-v1.json`. E-06, E-12. TISAX 5.2.4.

### E3-1.2 Eve-W: the identities, the reads and the halt path

- **WHO:** Platform owner.
- **WHERE:** Shell.
- **ACTION:**

```bash
for sa in "$SA_EVE" "$SA_EVE_VERIFIER" "$SA_EVE_V0" "$SA_EVE_CONSOLE"; do
  gcloud iam service-accounts describe "$sa" --project="$EVE_PROJECT" --format='value(email,disabled)'
done
bq show --format=prettyjson "${WALLE_PROJECT}:${WALLE_AUDIT_DS}" \
  | jq -r '[.access[] | select(.userByEmail != null) | {role, member: .userByEmail}] | .[] | select(.member | test("^eve-"))'
gcloud run services get-iam-policy walle-actions --project="$WALLE_PROJECT" --region="$REGION" --format=json \
  | jq -r '[.bindings[] | select(.role=="roles/run.invoker") | .members[]] | sort | .[]'
gcloud run services get-iam-policy walle-actions-super --project="$WALLE_PROJECT" --region="$REGION" --format=json \
  | jq -r '[.bindings[] | select(.role=="roles/run.invoker") | .members[]] | sort | .[]'
bq ls --format=prettyjson "${EVE_PROJECT}:${EVE_MIRROR_DS}" | jq -r '.[].tableReference.tableId' | sort | wc -l
```

- **VERIFY:** Four accounts exist and none is `disabled: true`. On `walle_audit`: `READER` for `eve-v0@`, `eve-controller@` and `eve-verifier@`, and nothing else beginning `eve-`; no `WRITER`, no `OWNER`. `run.invoker` on `walle-actions` lists exactly the three Eve identities plus Wall-E's own callers; on `walle-actions-super` exactly `eve-controller@` and `eve-verifier@`. The mirror holds **nine** tables. Any extra Eve principal anywhere is a drift failure and is removed before the halt goes live.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-1.2-eve-w-v1.json`. E-08. TISAX 4.2.1.

### E3-1.3 The deterministic boundary, proved rather than asserted

- **WHO:** Platform owner runs; security reviewer reads the output himself.
- **WHERE:** Shell.
- **ACTION:** Three reads and one deliberate failure. The failure is the pass.

```bash
gcloud org-policies describe gcp.restrictServiceUsage --project="$EVE_PROJECT" --effective --format=json \
  | jq -r '.spec.rules[].values.deniedValues[]?'
gcloud services list --enabled --project="$EVE_PROJECT" --format='value(config.name)' | grep -Ec '^(aiplatform|modelarmor|cloudbuild|artifactregistry)\.googleapis\.com$' || true
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json \
  | jq -r '[.bindings[] | select(.role | test("aiplatform"))] | length'
gcloud services enable aiplatform.googleapis.com --project="$EVE_PROJECT" 2>&1 | tail -3
```

- **VERIFY:** `aiplatform.googleapis.com` appears in the effective denied values; the forbidden-service count is `0`; no binding of any `aiplatform` role exists; and the deliberate `services enable` **fails** with an error naming `constraints/gcp.restrictServiceUsage`. If it succeeds, stop the sitting, disable the service at once and re-run [17](17-factory-module-equivalents-and-tier-r-gate.md) `FM-4.2`: the sentence "no model produces an Eve approval" is not true and nothing else in this file may proceed.
- **ROLLBACK:** The `services enable` is expected to fail and changes nothing. If it succeeded, `gcloud services disable aiplatform.googleapis.com --project="$EVE_PROJECT"` immediately and record a severity-1 finding.
- **EVIDENCE:** `${R}-1.3-no-model-v1.txt`, with the refusal message quoted in full. E-02, E-08. TISAX 1.5.1, 4.2.1.

### E3-1.4 The blind review queue exists, and has been read

- **WHO:** Eve owner; the blind grader confirms from his own session.
- **WHERE:** Shell and the `eve-console`.
- **ACTION:** `eve.review_queue_blind` lands with the console at S3 entry — **before** the S3 exit gate, not before S4 — because it is what the grader reads and the gate is argued from grades taken through it.

```bash
bq show --schema --format=prettyjson "${EVE_PROJECT}:${EVE_DS}.review_queue_blind" \
  | jq -r '[.[].name] | sort | join(",")'
bq --project_id="$EVE_PROJECT" query --use_legacy_sql=false --format=csv \
  'SELECT COUNT(*) AS graded, MIN(graded_at) AS first_grade, MAX(graded_at) AS last_grade FROM `'"$WALLE_PROJECT"'.'"$WALLE_AUDIT_DS"'.grades`'
```

- **VERIFY:** The blind view's column list contains **no** `verdict` and no `reason_code` column — blindness is structural, not a console setting. `grades` shows a first grade dated at or before Wall-E's S1 and a continuous series since, at `max(10 %, 5 items/week)`. The grader confirms he has never seen a machine verdict in that surface.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-1.4-blind-queue-v1.txt`. E-11. TISAX 5.2.4.

### E3-1.5 The evidence perimeter: bucket, ladder, config repository, validator

- **WHO:** Platform owner.
- **WHERE:** Shell and the git host.
- **ACTION:**

```bash
need EVE_EVIDENCE_BUCKET EVIDENCE_RETENTION_DAYS EVE_CONFIG_REPO
gcloud storage buckets describe "$EVE_EVIDENCE_BUCKET" --format=json > "${R}-1.5-bucket-v1.json"
jq -e '.retention_policy.isLocked == true' "${R}-1.5-bucket-v1.json" && echo "LOCKED"
[ "$(jq -r '.retention_policy.retentionPeriod' "${R}-1.5-bucket-v1.json")" = "$((EVIDENCE_RETENTION_DAYS * 86400))" ] && echo "RETENTION MATCHES"
jq -r '.uniform_bucket_level_access, .public_access_prevention' "${R}-1.5-bucket-v1.json"
gcloud storage ls "${EVE_EVIDENCE_BUCKET}/ladder/" | tail -3
git -C "$PLATFORM_REPO_DIR" ls-remote "$EVE_CONFIG_REPO" HEAD
erepo="$(printf '%s' "$EVE_CONFIG_REPO" | sed -E 's#^https://github.com/##; s#\.git$##')"
gh api "repos/${erepo}/branches/main/protection" --jq '{reviews: .required_pull_request_reviews, checks: .required_status_checks.contexts}'
```

  The bucket resource is read as JSON and asserted with `jq -e`: `gcloud storage` renders the retention policy under the snake_case key `retention_policy` with `isLocked` and `retentionPeriod` beneath it, and a `value(retentionPolicy.isLocked)` projection prints a blank line, which an operator can read as either answer. `jq -e` exits non-zero on `false` or `null`, so a missing policy fails loudly. The repository slug is derived from `EVE_CONFIG_REPO` because `gh`'s `{owner}/{repo}` placeholders resolve only inside a clone of that repository, which this shell is not.
- **VERIFY:** `LOCKED` and `RETENTION MATCHES` both print — if `jq -e` fails, the archive of §4 is deletable and the forgery argument does not hold, so §4 does not open; `true` and `enforced` for uniform access and public-access prevention. The `ladder/` prefix holds the artefact `walle-deployer@` published at Stage 0. `eve/config` requires **two** approving reviewers with the Eve owner among the required reviewers, and the external validator runs on every pull request.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-1.5-perimeter-v1.txt` and `${R}-1.5-bucket-v1.json`. E-07, E-08. TISAX 1.3.1, 4.2.1.

### E3-1.6 Write the S3-entry record

- **WHO:** Eve owner writes and signs; platform owner countersigns.
- **WHERE:** `BUILD_LOG_DIR/records/`, then the witness.
- **ACTION:** One page, naming for each of `E3-1.1` to `E3-1.5` what was read, its value and its date; the `eve_config_version` running today; the deliberately absent list (**no key, no `eve-gate`, no cell at `eve_authority: binding`**); and the sentence that S3 entry does not authorise a signature.
- **VERIFY:** The record opens, names both halves, carries two signatures and quotes the change ticket. The absent list is there in full: a reader six months later must be able to tell that no signing capability existed on this date.
- **ROLLBACK:** Not applicable; a record is superseded, never rewritten.
- **EVIDENCE:** `${R}-1.6-s3-entry-record-v1.md`, copied to `WITNESS_BUCKET`; `evidence_add E3-1.6 s3-entry-record E-13 5.2.4 witness:records/<file> <file>`.

## 2. S3 entry: the invariant class goes live

### E3-2.1 Name the two classes, in one table, before changing anything

- **WHO:** Eve owner decides; security reviewer reads.
- **WHERE:** The sitting; the table is committed with the pull request of `E3-2.2`.
- **ACTION:** Halting is reserved for a **closed list**. It is never a judgement call, and it is never extended by a code change alone.

| Class | Rules | At S3 entry | Why |
|---|---|---|---|
| **Invariant** | The twelve seeded-fault verdicts (`plan_hash_mismatch`, `pre_state_mismatch`, `level_overclaim`, `config_version_unknown`, `ceilings_sha_mismatch`, `target_protected`, `target_out_of_scope`, `trigger_uncorroborated`, `audit_row_missing`, `admin_event_unmatched`, `ladder_drift`, `audit_claim_divergence`); the tenant-integrity rules; `reconciliation_gap` over every stream; `log_pipeline_silent` | **Live: halt and demote, for real** | Each is a violation of a rule with a yes/no answer. Halting can only make less happen, and a human undoes it in seconds |
| **Rate-based** | Everything whose trigger is a threshold in `thresholds.yaml` | **Observe-only**, logged and graded, enforcing nothing | A rate threshold fires on noise until it is trusted. Calibration happened at S2 (E-18); the wiring happens when a measured window says the number holds |
| **Plan verdicts** | Eve's verdict on an individual plan at the approval point | **Observe-only through the whole of S3** | Signing waits for the exit gate. A verdict today is logged and graded and enforces nothing |

  The cost is named rather than narrowed away: a buggy Eve can halt the programme during the stage the programme is trying to prove itself in. That is accepted, because the reverse — watching a hard-invariant violation go past — is worse.
- **VERIFY:** The table is agreed and signed by the Eve owner and the security reviewer before any file is edited. No rule sits in two classes; no rule sits in neither.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** `${R}-2.1-classes-v1.md`. E-04, E-13. TISAX 1.5.1.

### E3-2.2 The `eve/config` merge that makes the class live

- **WHO:** Platform owner raises the pull request; **the Eve owner and one other reviewer approve**; no service account approval counts.
- **WHERE:** A clone of `EVE_CONFIG_REPO`.
- **ACTION:** [36](36-wall-e-joins-to-eve-and-mo.md) `WJ-5.4` already replaced `halt_target_pending` with the two real endpoints. What changes here is the per-rule `enforcement` field, and only for the invariant class.

```bash
checkpoint E3-2.2 START
T41="$(mktemp -d)"; e3_set T41 "$T41"; git clone "$EVE_CONFIG_REPO" "$T41/cfg"
git -C "$T41/cfg" checkout -b s3-entry-invariant-live
python3.12 - "$T41/cfg" <<'EOF'
import sys, pathlib, yaml
root = pathlib.Path(sys.argv[1])
cat = yaml.safe_load((root / "detections" / "catalogue.yaml").read_text())
invariant = set(yaml.safe_load((root / "detections" / "invariant_class.yaml").read_text())["rules"])
changed = []
for rule in cat["rules"]:
    want = "live" if rule["id"] in invariant else "observe"
    if rule.get("enforcement") != want:
        rule["enforcement"] = want
        changed.append((rule["id"], want))
(root / "detections" / "catalogue.yaml").write_text(yaml.safe_dump(cat, sort_keys=False))
for rid, want in changed:
    print(f"{rid}\t{want}")
print(f"TOTAL {len(changed)} changed, {len(invariant)} invariant, {len(cat['rules'])} rules")
EOF
git -C "$T41/cfg" commit -am "eve/config: invariant class enforcement live at S3 entry (setup 41 E3-2.2)"
git -C "$T41/cfg" push -u origin s3-entry-invariant-live
```

  `invariant_class.yaml` is the committed form of `E3-2.1`'s table, added by the same pull request so that the list and the switch are reviewed together. A rule that is in the catalogue and in neither class fails the external validator.
- **VERIFY:** The validator passes. The pull request shows **two distinct human approvers**, one of them the Eve owner, and neither is a service account or a bot user. After the merge, `enforcement: live` appears on exactly the invariant rules and `observe` on every other, counted by the script's own totals re-run on the merged branch. The `eve_config_version` increments.
- **ROLLBACK:** A reverting pull request returns every rule to `observe`, which is a safe state — Eve reports and halts nothing — and is recorded as a deliberate reduction with its reason, never left implicit.
- **EVIDENCE:** The merge commit, the two approvals and the totals as `${R}-2.2-invariant-live-v1.txt`; `evidence_add E3-2.2 invariant-live E-04 1.5.1 platform-repo:eve-config <file>`. E-04, E-12. TISAX 1.5.1.

### E3-2.3 Roll the reconciler onto the new configuration, and let the witness see it

- **WHO:** Platform owner, under `ENT_DEPLOY_CREDENTIAL_HOLDER_EVE` approved by the Eve owner.
- **WHERE:** Shell.
- **ACTION:** The four reconciler jobs read `eve/config` at start. Redeploy by digest — never by tag — so that what runs is what was attested.

```bash
need T41 EVE_RECONCILER_IMAGE ENT_DEPLOY_CREDENTIAL_HOLDER_EVE
git -C "$T41/cfg" fetch origin && CFGV="$(git -C "$T41/cfg" rev-parse --short origin/main)"; echo "EVE_CONFIG_VERSION=$CFGV"
g="$(pam_request "$ENT_DEPLOY_CREDENTIAL_HOLDER_EVE" "setup-41 E3-2.3: roll the reconciler jobs onto the S3-entry config version" 1800)"; echo "$g"
pam_wait "$g" ACTIVE
for j in eve-reconciler-detect eve-reconciler-poll eve-reconciler-roster eve-reconciler-heartbeat; do
  gcloud run jobs update "$j" --project="$EVE_PROJECT" --region="$REGION" \
    --image="$EVE_RECONCILER_IMAGE" --update-env-vars="EVE_CONFIG_VERSION=${CFGV}"
done
pam_revoke "$g"
```

  `T41` is the clone `E3-2.2` made and recorded in `E3_VARS`; the version is read from `origin/main` after the merge, not from the local branch. The Cloud Run v2 Job resource has no `spec` wrapper: the image sits at `template.template.containers[0].image` (Job → ExecutionTemplate → TaskTemplate → containers).
- **VERIFY:**

```bash
for j in eve-reconciler-detect eve-reconciler-poll eve-reconciler-roster eve-reconciler-heartbeat; do
  img="$(gcloud run jobs describe "$j" --project="$EVE_PROJECT" --region="$REGION" --format='value(template.template.containers[0].image)')"
  printf '%s\t%s\t' "$j" "$img"; printf '%s' "$img" | grep -q '@sha256:' && echo DIGEST || echo "NOT A DIGEST: STOP"
done
```

  Four `DIGEST` lines and no empty image column — an empty projection is a wrong field path, not a pass. The next scheduled execution of each job completes. Within the alarm's window, `WITNESS_ALERT_FINGERPRINT` fires on the configuration-fingerprint change and the witness administrators confirm receipt — a configuration change the witness did not see is exactly the silent edit [27](27-witness-grants-and-alarms.md) was built to catch, so an alarm that stays quiet here is a finding against the alarm, not a convenience. The grant reads `REVOKED`.
- **ROLLBACK:** Redeploy the previous digest with the previous `EVE_CONFIG_VERSION`; the alarm fires again and the record says why.
- **EVIDENCE:** `${R}-2.3-roll-v1.txt` and the witness acknowledgement. E-06, E-12. TISAX 1.5.1, 5.2.4.

### E3-2.4 Prove one invariant halt and one demote, live, with a witness

- **WHO:** Platform owner runs the seeded fault; **the incident commander witnesses**; the second operator clears the halt through the operators' own path.
- **WHERE:** `twin_shell` for the seeding, production for the halt's effect. The seeded fault is served to Eve from the harness against the sandbox deployment (E-15); the halt it raises is the real one.
- **ACTION:**

```bash
checkpoint E3-2.4 START
python3.12 "$PLATFORM_REPO_DIR/eve/tests/seed_fault.py" --fault target_protected --sandbox --record "${R}-2.4-seed.json"
sleep 180
bq --project_id="$EVE_PROJECT" query --use_legacy_sql=false --format=prettyjson \
  'SELECT incident_id, rule_id, severity, action_taken, ts FROM `'"$EVE_PROJECT"'.'"$EVE_DS"'.incidents` WHERE ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 15 MINUTE) ORDER BY ts DESC'
curl -s -H "Authorization: Bearer $(gcloud auth print-identity-token --include-email)" "${ACTIONS_URL}/v1/ladder" | jq -r '.effective_level, .halted, .halt_reason'
```

- **VERIFY:** An incident row with `action_taken: halt`, the severity the catalogue gives the rule, and the page delivered to the Eve owner through `NOTIF_CH_EVE_SMS_SECOND_HUMAN` inside its target. `walle-actions` reports `halted: true` with Eve's reason. The demote half is proved on the same pass: a cell whose rule demands demotion reads one level lower in `GET /v1/ladder` than the published ladder artefact, and **only** lower — a level above the merged value is a severity-1 finding, because machines lower and humans raise. Then the second operator clears the halt with one authenticated call and the clear is recorded with his name; Eve returning clears nothing.
- **ROLLBACK:** The clear is the rollback, and it is part of the test. If the halt cannot be cleared by an operator inside five minutes, that is the finding: revert `E3-2.2` and fix the clear path before the class goes live again.
- **EVIDENCE:** The seed record, the incident row, the ladder read before and after, the page and the clear as `${R}-2.4-halt-live-v1`; `evidence_add E3-2.4 halt-live E-12 1.5.1 build-log:records/<file> <file>`. E-08, E-12. TISAX 1.5.1, 4.2.1.

### E3-2.5 Prove a rate-based rule stays observe-only

- **WHO:** Platform owner; Eve owner reads.
- **WHERE:** `twin_shell`.
- **ACTION:** The negative half of `E3-2.2`. Seed a fault whose rule is rate-based and confirm that Eve writes a finding and pages nobody and halts nothing.

```bash
python3.12 "$PLATFORM_REPO_DIR/eve/tests/seed_fault.py" --fault rate_verification_lag --sandbox --record "${R}-2.5-seed.json"
sleep 180
bq --project_id="$EVE_PROJECT" query --use_legacy_sql=false --format=csv \
  'SELECT rule_id, action_taken FROM `'"$EVE_PROJECT"'.'"$EVE_DS"'.findings` WHERE ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 15 MINUTE)'
curl -s -H "Authorization: Bearer $(gcloud auth print-identity-token --include-email)" "${ACTIONS_URL}/v1/ladder" | jq -r '.halted'
```

- **VERIFY:** A `findings` row with `action_taken: observe`; **no** `incidents` row; `halted` is `false`; no page. A halt here means a rule is in the wrong class and `E3-2.2` is reverted before the sitting ends.
- **ROLLBACK:** None needed; nothing changed.
- **EVIDENCE:** `${R}-2.5-observe-only-v1.txt`. E-12. TISAX 1.5.1.

### E3-2.6 Record S3 entry, and set the recurrence

- **WHO:** Eve owner.
- **WHERE:** `DRILL_CALENDAR`, `${R}`.
- **ACTION:** Append to `DRILL_CALENDAR`: the seeded-fault exercise **monthly and on every `eve_config_version` change** (platform HLD §13.3), the `DR-28-1` blind proof monthly and after any Eve configuration change, and the live halt-and-clear rehearsal quarterly. Write the S3-entry closing line into the record of `E3-1.6` as a second dated section.
- **VERIFY:** Three rows in `DRILL_CALENDAR`, each with an owner and a next date; the record names the `eve_config_version` at which the class went live.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** `${R}-2.6-recurrence-v1.txt`. E-13. TISAX 5.2.4.

## 3. The S3 exit gate

At least thirty days after §2, in its own sitting. Nothing of §4 onwards may be prepared before this gate passes: not the key ring binding, not the image, not the receipts dataset.

### E3-3.1 Thirty days, counted from the data

- **WHO:** Platform owner runs; Eve owner and security reviewer read.
- **WHERE:** Shell.
- **ACTION:**

```bash
bq --project_id="$EVE_PROJECT" query --use_legacy_sql=false --format=prettyjson \
  'SELECT MIN(ts) AS first_verdict, MAX(ts) AS last_verdict, COUNT(*) AS verdicts,
          COUNT(DISTINCT DATE(ts)) AS days_with_verdicts
   FROM `'"$EVE_PROJECT"'.'"$EVE_DS"'.verdicts`'
bq --project_id="$EVE_PROJECT" query --use_legacy_sql=false --format=csv \
  'SELECT COUNT(*) AS l3_batch_executions FROM `'"$WALLE_PROJECT"'.'"$WALLE_AUDIT_DS"'.actions`
   WHERE level = "L3" AND trigger_kind = "batch" AND ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)'
```

- **VERIFY:** `first_verdict` is at least thirty days before today, `days_with_verdicts` shows no gap longer than Eve's own outage budget, and the L3 batch count is non-zero. A window with verdicts but no executions is not thirty days of observation; it is thirty days of quiet.
- **ROLLBACK:** Read only. Short of thirty days, the gate is rebooked; nothing is waived.
- **EVIDENCE:** `${R}-3.1-window-v1.json`. E-11. TISAX 5.2.4.

### E3-3.2 The twelve seeded faults, at 100 %

- **WHO:** Platform owner runs the harness; **the security reviewer chooses the run order and watches**; Eve owner records.
- **WHERE:** The separate sandbox deployment against the separate dataset (E-15). Never a test-mode path in an admitted image: a CI import test asserts the stub caller is absent from any admitted image, and that test is re-run here.
- **ACTION:** If `tests/seeded_faults/` is not in `EVE_CODE_COMMIT` with twelve fixtures, this step **refuses** and the gate is rebooked — README **B-09**. Otherwise:

```bash
checkpoint E3-3.2 START
python3.12 "$PLATFORM_REPO_DIR/eve/tests/run_seeded_faults.py" --sandbox --all --shuffle \
    --write-runs "${EVE_PROJECT}.${EVE_DS}.seeded_fault_runs" --record "${R}-3.2-faults.json"
bq --project_id="$EVE_PROJECT" query --use_legacy_sql=false --format=prettyjson \
  'SELECT fault_id, expected_verdict, observed_verdict, caught FROM `'"$EVE_PROJECT"'.'"$EVE_DS"'.seeded_fault_runs`
   WHERE run_date = CURRENT_DATE() ORDER BY fault_id'
```

- **VERIFY:** Twelve rows, `caught = true` on every one, and `observed_verdict` equal to the required reason code for each: `plan_hash_mismatch`, `pre_state_mismatch`, `level_overclaim`, `config_version_unknown`, `ceilings_sha_mismatch`, `target_protected`, `target_out_of_scope`, `trigger_uncorroborated`, `audit_row_missing`, `admin_event_unmatched`, `ladder_drift`, `audit_claim_divergence`. **Eleven of twelve is a fail.** A deterministic checker that misses one of twelve constructed violations is not a deterministic checker, and the gate is not negotiable at eleven.
- **ROLLBACK:** Not applicable: the harness writes to the sandbox dataset. A failed fault is a defect fixed in Eve's code, after which the whole twelve run again from the start.
- **EVIDENCE:** `${R}-3.2-faults-v1.json` plus the `seeded_fault_runs` rows. E-11, E-12. TISAX 5.2.4.

### E3-3.3 The two negative controls, silent

- **WHO:** As `E3-3.2`.
- **WHERE:** As `E3-3.2`.
- **ACTION:**

```bash
python3.12 "$PLATFORM_REPO_DIR/eve/tests/run_seeded_faults.py" --sandbox --negative-controls \
    --record "${R}-3.3-negatives.json"
```

- **VERIFY:** **N1** — a group write verified from current state twenty minutes after execution with the Groups event not yet landed — produces `verification_deferred_lag`, is re-checked, and is **not** counted as a fault. **N2** — a `protected_principal` denial arising from a human chat request — is an ordinary correct refusal and does not enter the hard-invariant count. Either firing is a fail: without these two controls the cheapest way to pass a twelve-fault gate is to refuse everything, and an over-eager Eve would walk through.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** `${R}-3.3-negatives-v1.json`. E-11. TISAX 5.2.4.

### E3-3.4 The agreement figure, reported for information only

- **WHO:** Blind grader supplies; Eve owner records.
- **WHERE:** Shell.
- **ACTION:**

```bash
bq --project_id="$EVE_PROJECT" query --use_legacy_sql=false --format=prettyjson \
  "$(cat "$PLATFORM_REPO_DIR/eve/checks/blind_agreement.sql")"
```

- **VERIFY:** The query reports agreement as a **Wilson interval bound**, not a point estimate, over the thirty-day window, with the sample size and the draw seed. It is written into the gate record explicitly **as information, not as a criterion** ([../../eve/05-stages.md](../../eve/05-stages.md), C12): a 95 % agreement rate is a sensible gate for a model and a meaningless one for a deterministic checker, which either implements the rule or does not. The grader confirms he graded blind and names the number of items.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-3.4-agreement-v1.json`. E-11. TISAX 5.2.4.

### E3-3.5 The S3 exit record — the gate for everything after it

- **WHO:** Eve owner and **security reviewer** sign; the platform owner signs neither.
- **WHERE:** `BUILD_LOG_DIR/records/`, then the witness.
- **ACTION:** One page: the thirty-day window with its dates and counts; the twelve faults with their observed verdicts; the two negative controls; the agreement figure marked informational; the blind grader's name and the date he was appointed; the `eve_config_version` under test; and one sentence — **"S4 entry may begin"** or **"it may not, and why"**.
- **VERIFY:** Two signatures, neither the platform owner's. The record is copied to the witness before §4 opens, so that the authority to build a signing key is recorded outside the administration line that will use it.
- **ROLLBACK:** Not applicable; superseded, never rewritten.
- **EVIDENCE:** `${R}-3.5-s3-exit-v1.md` in `WITNESS_BUCKET`; `evidence_add E3-3.5 s3-exit-gate E-13 5.2.4 witness:records/<file> <file>`. E-01, E-13. TISAX 1.4.1, 5.2.4.

## 4. S4 entry: the key, and the PEM before first use

### E3-4.1 Open the grant that makes the key possible

- **WHO:** Platform owner requests; **the Eve owner approves** (SD-12); the security reviewer is in the room for §4 and §5.
- **WHERE:** Shell.
- **ACTION:** After [17](17-factory-module-equivalents-and-tier-r-gate.md) `FM-2.19` removed the creator's Owner, no human holds `roles/cloudkms.admin` on `EVE_PROJECT` standing. `ENT_PROJECT_REPAIR_EVE`'s `CTL` override carries it for the life of a grant, and only with the Eve owner's approval.

```bash
checkpoint E3-4.1 START
need EVE_PROJECT EVE_KEYRING ENT_PROJECT_REPAIR_EVE
g_key="$(pam_request "$ENT_PROJECT_REPAIR_EVE" "setup-41 E3-4.2 to E3-5.6: create eve-approval, export the PEM, bind the signer after the audit config" 3600)"; echo "$g_key"
e3_set G_KEY "$g_key"
pam_wait "$G_KEY" ACTIVE
pam_record "$G_KEY" "${R}-4.1-grant.json"
```

  The grant name is written to `E3_VARS` as `G_KEY` because `E3-5.6` revokes it from a fresh shell five steps later; `pam_wait` waits for `ACTIVE`, which is the state PAM reports for a live grant.
- **VERIFY:** `pam_record` prints `ACTIVE`, the requester as the platform owner, an approver event whose principal is the Eve owner, and `externallyModified: false`. If the approver is the requester, stop: the whole separation argument of this file rests on that line. `grep G_KEY "$E3_VARS"` prints the grant name.
- **ROLLBACK:** `pam_revoke "$G_KEY"`. The grant is revoked at `E3-5.6` in any case, and the revocation time is recorded.
- **EVIDENCE:** `${R}-4.1-grant.json`. E-08. TISAX 4.1.1, 4.2.1.

### E3-4.2 Create `eve-approval` — **IRREVERSIBLE** as a name

- **WHO:** Platform owner runs; **the security reviewer reads the banner aloud and countersigns the build-log line**.
- **WHERE:** Shell, inside `g_key`.
- **ACTION:**

  > **IRREVERSIBLE.** A key ring cannot be deleted and a key name inside it cannot be reused. `eve-approval` in ring `EVE_KEYRING` is permanent: a typo here leaves a dead name in the ring for ever, and a wrong algorithm cannot be corrected in place — it can only be superseded by a second name, which every future reader then has to be told about. Confirm before running, reading the **values** aloud and not the variable names: `echo "$EVE_KEYRING"` prints `projects/<EVE_PROJECT>/locations/europe-west1/keyRings/<ring>` and `echo "$EVE_KEYRING_NAME"` prints its last segment, which is the ring the signed key table names; `echo "$REGION"` prints `europe-west1`; the gate of `E3-3.5` says "S4 entry may begin"; the algorithm is the one `walle-actions`' verification path implements.

```bash
need EVE_PROJECT EVE_KEYRING REGION G_KEY
echo "$EVE_KEYRING"; echo "$EVE_KEYRING_NAME"; echo "$REGION"
gcloud kms keys create eve-approval \
  --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" \
  --purpose=asymmetric-signing \
  --default-algorithm=ec-sign-p256-sha256 \
  --protection-level=hsm \
  --destroy-scheduled-duration=30d
KEY_STATE=""
for i in $(seq 1 30); do
  KEY_STATE="$(gcloud kms keys versions describe 1 --key=eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" --format='value(state)')"
  echo "$(date -u +%H:%M:%S) eve-approval version 1: ${KEY_STATE:-no state read}"
  case "$KEY_STATE" in ENABLED) break;; PENDING_GENERATION|'') sleep 10;; *) echo "STOP: unexpected state $KEY_STATE"; break;; esac
done
[ "$KEY_STATE" = ENABLED ] && e3_set EVE_APPROVAL_V1_STATE ENABLED || echo "STOP: version 1 is '${KEY_STATE}' after five minutes; E3-4.3 refuses until a re-run of this poll records ENABLED"
```

  `--protection-level=hsm` is written out because the flag defaults to `software`; P118's `constraints/cloudkms.allowedProtectionLevels = is:HSM` at `fld-agentic-platform` would refuse a software key anyway, and `E3-4.5` proves the level rather than trusting either. `--destroy-scheduled-duration=30d` is written out for the same reason: the default is 30 days today, B21 requires `in:30d`, and a value stated in the command is a value a reader can check against the record.

  **The poll is not optional.** An asymmetric key's initial version is generated asynchronously: "when you first create the key, the initial key version has a state of Pending generation. When the state changes to Enabled, you can use the key." A `versions list` run straight after `keys create` reads `PENDING_GENERATION`, and a `get-public-key` at that moment fails with a precondition error — on an HSM key the wait is normally seconds, and the loop allows five minutes. The loop records `EVE_APPROVAL_V1_STATE=ENABLED` in `E3_VARS` only when it has seen `ENABLED` itself, and `E3-4.3` needs that value. `GENERATION_FAILED` is terminal: the version cannot be enabled, and the name is spent — which is the case the banner warns about, and the reason the poll stops on any state that is neither pending nor enabled instead of looping past it.
- **VERIFY:** Only after the poll has printed `ENABLED`:

```bash
need EVE_APPROVAL_V1_STATE
gcloud kms keys describe eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" \
  --format='value(purpose,versionTemplate.algorithm,versionTemplate.protectionLevel,destroyScheduledDuration)'
gcloud kms keys versions list --key=eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" \
  --format='table(name,state,protectionLevel)'
```

  Expect `ASYMMETRIC_SIGN`, `EC_SIGN_P256_SHA256`, `HSM`, `2592000s`, and exactly one version, `ENABLED`, `HSM`. Anything else stops the sitting; a version still `PENDING_GENERATION` here means the readback was run before the poll finished, and the poll is re-run rather than the readback repeated until it looks right.
- **ROLLBACK:** **None for the name.** The version can be disabled (`E3-10.3`) and the key left unused; it cannot be removed, and it must not be destroyed.
- **EVIDENCE:** `${R}-4.2-key-v1.txt` with the poll's state lines, both readbacks and the countersignature; `evidence_add E3-4.2 eve-approval-key E-08 4.3.1 build-log:records/<file> <file>`. E-08. TISAX 4.3.1.

### E3-4.3 Export the public key and archive it — **IRREVERSIBLE** as an object

- **WHO:** Platform owner; security reviewer watches the digest comparison.
- **WHERE:** Shell, inside `G_KEY`, in a working directory that is not the wiki and not a synced folder (`mktemp -d`, recorded in `E3_VARS` as `W`).
- **ACTION:** Before the version is ever used to sign. Two copies, and the first lands in the locked bucket. **The step refuses to run unless `E3-4.2`'s poll recorded `ENABLED`**, and re-reads the state itself: an export against a `PENDING_GENERATION` version fails, and an export against anything else is not the key this file argues from.

  > **IRREVERSIBLE.** The evidence bucket's retention policy is locked: an object written to `keys/` cannot be deleted or replaced by anyone, including a project owner, until `EVIDENCE_RETENTION_DAYS` have passed. Confirm before uploading: the file is the **public** key of version 1 of `eve-approval` (a PEM beginning `-----BEGIN PUBLIC KEY-----`), the digest matches the live key, and the object name carries the version number.

```bash
need EVE_EVIDENCE_BUCKET GRP_EVE_OWNERS EVE_APPROVAL_V1_STATE G_KEY
[ "$EVE_APPROVAL_V1_STATE" = ENABLED ] || { echo "STOP: E3-4.2's poll did not record ENABLED"; false; }
[ "$(gcloud kms keys versions describe 1 --key=eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" --format='value(state)')" = ENABLED ] || { echo "STOP: version 1 is not ENABLED now"; false; }
penv_set EVE_KEY_VERSION "${EVE_KEYRING}/cryptoKeys/eve-approval/cryptoKeyVersions/1"

W="$(mktemp -d)"; e3_set W "$W"
gcloud kms keys versions get-public-key 1 \
  --key=eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" \
  --output-file="$W/eve-approval-v1.pem"
head -1 "$W/eve-approval-v1.pem"
shasum -a 256 "$W/eve-approval-v1.pem" | tee "$W/eve-approval-v1.sha256"

# the keys/ prefix grant 23 EP-7.7 recorded PENDING for this file
B="${EVE_EVIDENCE_BUCKET#gs://}"
gcloud storage buckets add-iam-policy-binding "$EVE_EVIDENCE_BUCKET" --project="$EVE_PROJECT" \
  --member="group:${GRP_EVE_OWNERS}" --role=roles/storage.objectCreator \
  --condition="expression=resource.name.startsWith(\"projects/_/buckets/${B}/objects/keys/\"),title=keys-prefix-only,description=41 E3-4.3: the eve-approval public-key archive, written by the Eve owner group at creation and at each rotation"

gcloud storage cp "$W/eve-approval-v1.pem" "${EVE_EVIDENCE_BUCKET}/keys/eve-approval-v1.pem"
```

  The condition's bucket name is derived from `EVE_EVIDENCE_BUCKET` (the signed NAMES value 23 `EP-2.5` expanded), never retyped: a condition on a bucket name that differs from the real one by a character is inert, and that would not show today, because this first object is written under the platform owner's own grant, but at the first rotation.

  **One bucket, not two.** A fresh bucket would be an ordinary bucket: every project owner and every `roles/storage.objectAdmin` could overwrite or delete the PEM, and per-object retention cannot be enabled from the command line after creation. The evidence bucket already carries the guarantee, locked.

  **A narrowing, recorded.** [23](23-eve-project-and-evidence-stores.md) `EP-7.7`'s pending line named `eve-controller@` for this grant. It is made to `GRP_EVE_OWNERS` instead: the export is a human act at creation and at each rotation, and the signer has no business writing evidence. `eve-controller@` gains nothing here.
- **VERIFY:**

```bash
need W
gcloud storage cp "${EVE_EVIDENCE_BUCKET}/keys/eve-approval-v1.pem" "$W/from-bucket.pem"
gcloud kms keys versions get-public-key 1 --key=eve-approval --keyring="$EVE_KEYRING_NAME" \
  --location="$REGION" --project="$EVE_PROJECT" --output-file="$W/from-kms-again.pem"
shasum -a 256 "$W/eve-approval-v1.pem" "$W/from-bucket.pem" "$W/from-kms-again.pem"
head -1 "$W/from-bucket.pem"
gcloud storage buckets get-iam-policy "$EVE_EVIDENCE_BUCKET" --format=json \
  | jq -c '[.bindings[] | {role, members, condition: (.condition.title // "-")}]'
```

  **Three digests, all from files, all identical**, and `from-bucket.pem` begins `-----BEGIN PUBLIC KEY-----`. Every copy is written with `--output-file` or `gcloud storage cp` and hashed on disk; nothing is piped from stdout into `shasum`, because the command's stdout rendering is not pinned to be byte-identical to the file it writes (a trailing newline is enough to break a digest), and a comparison that can fail on a correct archive is one an operator learns to work around. If the digests differ, read it as **the comparison is wrong before the archive is**: the two KMS exports are the same command, so a difference between them is a tooling fault, and a difference only on the bucket copy means the upload was not the file hashed — record it and re-upload under a `-v2` object name as ROLLBACK says. The bucket policy shows `objectCreator` for `group:eve-owners@` with condition title `keys-prefix-only`, alongside `eve-verifier@`'s unconditioned `objectCreator` and `walle-deployer@`'s `ladder-prefix-only` — **three** grants and no `objectAdmin`, `objectUser` or `storage.admin` for any principal. `BD-41-1` records the narrowing and closes `EP-7.7`'s pending line.
- **ROLLBACK:** The grant can be removed. **The object cannot.** If the wrong file was uploaded, it stays until retention expires: write the correct object under the same version number with a `-v2` record naming the mistake, and record a finding — never assume the wrong object can be cleaned up later.
- **EVIDENCE:** `${R}-4.3-pem-archive-v1.txt` with the three file paths, their digests and the policy; `evidence_add E3-4.3 pem-archive E-08 4.3.1 build-log:records/<file> <file>`. E-08. TISAX 4.3.1, 1.3.1.

### E3-4.4 The second copy, in Wall-E's repository, merged before any signature

- **WHO:** Platform owner hands the file over; **the Wall-E owner raises the pull request**; two distinct approving reviewers, neither the author.
- **WHERE:** A clone of `WALLE_REPO_REMOTE`.
- **ACTION:** The repository copy is what `walle-actions` compiles in for offline pinned-PEM verification as the **primary** path, with KMS `getPublicKey` as the fallback only. The file goes under the same CODEOWNERS entry that protects `ladder.yaml`.

```bash
need W WALLE_REPO_REMOTE
T41W="$(mktemp -d)"; e3_set T41W "$T41W"; git clone "$WALLE_REPO_REMOTE" "$T41W/wall-e"
cp "$W/eve-approval-v1.pem" "$T41W/wall-e/contracts/eve-public-keys/1.pem"
shasum -a 256 "$W/eve-approval-v1.pem" "$T41W/wall-e/contracts/eve-public-keys/1.pem"
git -C "$T41W/wall-e" checkout -b eve-approval-v1
git -C "$T41W/wall-e" add contracts/eve-public-keys/1.pem
git -C "$T41W/wall-e" commit -m "eve-approval public key, version 1, exported at creation (setup 41 E3-4.4)"
git -C "$T41W/wall-e" push -u origin eve-approval-v1
```

- **VERIFY:** The two digests printed before the push are identical. The pull request merges with two distinct authenticated approving reviewers, neither the author and neither a service account. `shasum -a 256` of the merged file, read back from `main` as `E3-4.5` does, equals the three digests of `E3-4.3`. **Do not sign until this is merged**: a signature that exists before the pinned copy does is one the primary path cannot verify, and no amount of later merging repairs it.
- **ROLLBACK:** Revert the merge only if the file is wrong; then re-export and re-merge. The bucket copy stays either way.
- **EVIDENCE:** The merge commit, the two approvals and the digest as `${R}-4.4-pinned-pem-v1.txt`. E-08, E-12. TISAX 4.3.1, 1.5.1.

### E3-4.5 Three digests, one lock, one version

- **WHO:** Security reviewer runs this one himself.
- **WHERE:** Shell. Nothing from the platform owner's working directory is reused: each of the three copies is fetched afresh from where it now lives — the locked bucket, the merged `main` of `WALLE_REPO_REMOTE`, and Cloud KMS — into a directory of the reviewer's own, and hashed as a file.
- **ACTION:**

```bash
need EVE_EVIDENCE_BUCKET WALLE_REPO_REMOTE
T="$(mktemp -d)"
gcloud storage cp "${EVE_EVIDENCE_BUCKET}/keys/eve-approval-v1.pem" "$T/from-bucket.pem"
wrepo="$(printf '%s' "$WALLE_REPO_REMOTE" | sed -E 's#^https://github.com/##; s#\.git$##')"
gh api -H 'Accept: application/vnd.github.raw' "repos/${wrepo}/contents/contracts/eve-public-keys/1.pem?ref=main" > "$T/from-repo.pem"
gcloud kms keys versions get-public-key 1 --key=eve-approval --keyring="$EVE_KEYRING_NAME" \
  --location="$REGION" --project="$EVE_PROJECT" --output-file="$T/from-kms.pem"
shasum -a 256 "$T/from-bucket.pem" "$T/from-repo.pem" "$T/from-kms.pem" | tee "${R}-4.5-three-digests-v1.txt"
head -1 "$T/from-bucket.pem" "$T/from-repo.pem" "$T/from-kms.pem"
gcloud storage objects describe "${EVE_EVIDENCE_BUCKET}/keys/eve-approval-v1.pem" --format='value(name,size)'
gcloud storage buckets describe "$EVE_EVIDENCE_BUCKET" --format=json | jq -e '.retention_policy.isLocked == true' && echo "LOCKED"
gcloud kms keys versions describe 1 --key=eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" \
  --format='value(state,protectionLevel,algorithm)'
```

- **VERIFY:** **Three identical digests**, from `$T/from-bucket.pem`, `$T/from-repo.pem` and `$T/from-kms.pem`, and all three first lines `-----BEGIN PUBLIC KEY-----`. The object is `keys/eve-approval-v1.pem`. `LOCKED` prints — if `jq -e` fails, the archive would be deletable and the argument that `walle-actions` did not mint its own approval would not hold; in that case nothing is signed and the bucket is repaired first. The version reads `ENABLED HSM EC_SIGN_P256_SHA256`. If `from-repo.pem` alone differs, check the repository's `.gitattributes` for end-of-line normalisation before anything else: the committed bytes must be the exported bytes, or the pinned-PEM path verifies against a file that is not the key.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-4.5-three-digests-v1.txt`, naming the three file paths, signed by the security reviewer. E-08. TISAX 4.3.1.

### E3-4.6 Record `EVE_KEY_VERSION`

- **WHO:** Platform owner.
- **WHERE:** Shell.
- **ACTION:** `EVE_KEY_VERSION` was set at `E3-4.3` so that the export and the variable could not disagree. Confirm it, and state why the **full resource name** is what is stored: KMS signatures do not identify the key version used, so the envelope must name the version itself and the `approvals` row carries `eve_key_version`.

```bash
grep '^export EVE_KEY_VERSION=' "$PLATFORM_ENV_FILE"
gcloud kms keys versions describe 1 --key=eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" \
  --project="$EVE_PROJECT" --format='value(name,state,algorithm,protectionLevel)'
```

- **VERIFY:** The variable equals the `name` field exactly, character for character, ending `/cryptoKeyVersions/1`. State `ENABLED`.
- **ROLLBACK:** `penv_set EVE_KEY_VERSION … --force` with a build-log line, if and only if the resource name was mistyped.
- **EVIDENCE:** `${R}-4.6-key-version-v1.txt`. E-08. TISAX 4.3.1.

## 5. Audit configuration first, then the signer

The order of this section is the whole of S205, and it is not negotiable: a signature made between the grant and the audit-configuration change leaves no record.

### E3-5.1 Read the project policy fresh, and keep the etag

- **WHO:** Platform owner, inside `G_KEY`.
- **WHERE:** Shell.
- **ACTION:**

```bash
checkpoint E3-5.1 START
need G_KEY
P="$(mktemp -d)"; e3_set P "$P"
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json > "$P/before.json"
jq -r '.etag' "$P/before.json"
jq -r '[.bindings[] | {role, members}] | length' "$P/before.json"
jq -r '[.auditConfigs[]? | .service] | sort | join(",")' "$P/before.json"
```

- **VERIFY:** A non-empty `etag`; a binding count recorded for the diff of `E3-5.2`; the current audit-config services listed. **A file older than this sitting is never used**: a whole-policy write from a stale read removes every binding made since.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-5.1-policy-before-v1.json` (the file itself, since it contains no secret — only principals and roles). E-08. TISAX 4.2.1.

### E3-5.2 Add the audit configuration, prove the bindings did not move, write with the etag

- **WHO:** Platform owner runs; **the security reviewer reads the diff before the write**.
- **WHERE:** Shell.
- **ACTION:**

```bash
need P
[ -s "$P/before.json" ] || { echo "STOP: $P/before.json is missing or empty; re-run E3-5.1 in this sitting"; false; }
python3.12 - "$P/before.json" "$P/after.json" <<'EOF'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
p = json.load(open(src))
cfgs = {c["service"]: c for c in p.get("auditConfigs", [])}
for svc in ("cloudkms.googleapis.com", "iap.googleapis.com"):
    c = cfgs.setdefault(svc, {"service": svc, "auditLogConfigs": []})
    have = {x["logType"] for x in c["auditLogConfigs"]}
    for t in ("DATA_READ", "DATA_WRITE"):
        if t not in have:
            c["auditLogConfigs"].append({"logType": t})
p["auditConfigs"] = sorted(cfgs.values(), key=lambda c: c["service"])
json.dump(p, open(dst, "w"), indent=2, sort_keys=True)
EOF

diff <(jq -S '.bindings' "$P/before.json") <(jq -S '.bindings' "$P/after.json") && echo "BINDINGS UNCHANGED"
diff <(jq -S '.etag' "$P/before.json") <(jq -S '.etag' "$P/after.json") && echo "ETAG CARRIED"
gcloud projects set-iam-policy "$EVE_PROJECT" "$P/after.json" --format=json > "$P/written.json"
```

- **VERIFY:** `BINDINGS UNCHANGED` and `ETAG CARRIED` both print **before** `set-iam-policy` runs; if either diff is non-empty the write does not happen. The etag travels in the file, which is what makes this a read-modify-write: a concurrent change elsewhere fails the call with a 409 rather than silently overwriting, and the answer to a 409 is to re-read and repeat the whole cycle, never to strip the etag.
- **ROLLBACK:** `gcloud projects set-iam-policy "$EVE_PROJECT" "$P/before.json"` — the exact file read at `E3-5.1`, and only inside the same sitting.
- **EVIDENCE:** `${R}-5.2-auditconfig-v1.json` with both diffs and the written policy. E-06, E-08. TISAX 1.5.1, 4.2.1.

### E3-5.3 Prove Data Access logging is in force **before** any signer exists

- **WHO:** Security reviewer.
- **WHERE:** Shell.
- **ACTION:**

```bash
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json \
  | jq -r '.auditConfigs[] | select(.service=="cloudkms.googleapis.com") | .auditLogConfigs[].logType'
gcloud kms keys get-iam-policy eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" \
  --format=json | jq -r '[.bindings[]?] | length'
```

- **VERIFY:** `DATA_READ` present for `cloudkms.googleapis.com` (`AsymmetricSign` needs `useToSign`, which is typed `DATA_READ`, and Data Access logs are off by default). The key's binding count is **`0`**: no signer exists yet. That pair of readings is the evidence that no signature could have gone unlogged, and it is the reason this step exists as its own checkpoint rather than as a line in `E3-5.4`'s verify.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-5.3-audit-before-signer-v1.txt`, signed by the security reviewer. E-06. TISAX 1.5.1.

### E3-5.4 Bind `roles/cloudkms.signer` to `eve-controller@`, and to nothing else

- **WHO:** Platform owner, inside `G_KEY`; Eve owner watches.
- **WHERE:** Shell.
- **ACTION:**

```bash
need G_KEY SA_EVE
gcloud kms keys add-iam-policy-binding eve-approval \
  --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" \
  --member="serviceAccount:${SA_EVE}" --role=roles/cloudkms.signer
```

  `roles/cloudkms.signer` carries exactly `cloudkms.cryptoKeyVersions.useToSign` plus three read permissions. `eve-verifier@` — the process that parses attacker-writable strings out of Google's audit log — appears in no binding on this key, at any level, ever. That is the containment argument: an attacker who reaches the reconciler reaches no key.
- **VERIFY:** `gcloud kms keys get-iam-policy` shows one binding, `roles/cloudkms.signer`, one member, `eve-controller@`. No `roles/cloudkms.signerVerifier` and no `roles/cloudkms.cryptoOperator` anywhere — both carry `useToSign`, and either on the wrong principal would let the action service mint the approval it is supposed to verify.
- **ROLLBACK:** `gcloud kms keys remove-iam-policy-binding` with the same arguments. Removing it stops every Eve approval, which stalls L4 plans **closed** at `pending_eve` — a safe state, recorded as a deliberate reduction.
- **EVIDENCE:** `${R}-5.4-signer-v1.json`. E-08. TISAX 4.2.1, 4.3.1.

### E3-5.5 `walle-actions@`: `publicKeyViewer` on this one key, or nothing at all

- **WHO:** Platform owner; Wall-E owner confirms which path Wall-E's code takes.
- **WHERE:** Shell.
- **ACTION:** The pinned PEM is the primary path and needs no cross-project KMS grant. This binding exists **only** for the live-fetch fallback, and may be omitted entirely if the fallback is not wanted.

```bash
exists_or_pending "serviceAccount:${SA_ACTIONS}" E3-5.5 "41 E3-5.5: publicKeyViewer on eve-approval for the fallback path" && \
gcloud kms keys add-iam-policy-binding eve-approval \
  --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" \
  --member="serviceAccount:${SA_ACTIONS}" --role=roles/cloudkms.publicKeyViewer
```

- **VERIFY:** If made: key-level, cross-project, `publicKeyViewer` and nothing else — one of exactly three resource-level grants to Wall-E principals in `EVE_PROJECT` (decision 48). Never ring-level, never project-level. If omitted: the omission is recorded with the reason, and Wall-E's fallback path is disabled in configuration so it cannot fail open to an unauthenticated fetch.
- **ROLLBACK:** `remove-iam-policy-binding`; the primary path is unaffected.
- **EVIDENCE:** `${R}-5.5-publickeyviewer-v1.json`. E-08. TISAX 4.2.1.

### E3-5.6 Close the grant, then read the key policy cold

- **WHO:** Platform owner revokes; security reviewer reads after the revocation.
- **WHERE:** Shell.
- **ACTION:**

```bash
need G_KEY
pam_revoke "$G_KEY"
pam_wait "$G_KEY" REVOKED
pam_record "$G_KEY" "${R}-5.6-grant-closed.json"
gcloud kms keys get-iam-policy eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" \
  --project="$EVE_PROJECT" --flatten='bindings[].members' --format='table(bindings.role,bindings.members)'
gcloud kms keyrings get-iam-policy "$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" --format=json \
  | jq -r '[.bindings[]?] | length'
```

  `G_KEY` is the grant name `E3-4.1` wrote to `E3_VARS`; `need` stops the block if it is absent, so a revoke can never silently address nothing.

- **VERIFY:** The grant reads `REVOKED` with its end time. The key policy shows **exactly** `eve-controller@ signer` and, if made, `walle-actions@ publicKeyViewer` — two lines, no more. The **ring** policy is empty: a grant at ring level would reach every key in it, including the evidence key.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** `${R}-5.6-key-policy-v1.txt`. E-08. TISAX 4.2.1.

### E3-5.7 The KMS negative test, by Policy Troubleshooter (S137)

- **WHO:** Security reviewer runs it himself.
- **WHERE:** Shell.
- **ACTION:** The superseded runbook proved this with `--impersonate-service-account="$SA_EVE_VERIFIER"` and expected `PERMISSION_DENIED`. That is a **false pass**: impersonation needs `roles/iam.serviceAccountTokenCreator` on the target account — which this design deliberately never grants, and which even a project Owner does not carry — so the command fails at the impersonation step with its own permission error that reads exactly like the expected one. Worse, an operator who grants token creator to make the test run has created a standing impersonation path into the reconciler. The policy proof needs no impersonation and also covers inherited project and folder grants, which a key-level `get-iam-policy` does not show.

```bash
need SA_EVE SA_EVE_VERIFIER SA_EVE_V0 SA_EVE_CONSOLE SA_ACTIONS SECOND_HUMAN_EMAIL OWNER_DAILY_ACCOUNT
KEY_RES="//cloudkms.googleapis.com/${EVE_KEYRING}/cryptoKeys/eve-approval"; echo "$KEY_RES"
for who in "$SA_EVE_VERIFIER" "$SA_EVE_V0" "$SA_EVE_CONSOLE" "$SA_ACTIONS" "$SECOND_HUMAN_EMAIL" "$OWNER_DAILY_ACCOUNT"; do
  printf '%s\t' "$who"
  gcloud policy-intelligence troubleshoot-policy iam "$KEY_RES" \
    --principal-email="$who" \
    --permission=cloudkms.cryptoKeyVersions.useToSign \
    --format='value(overallAccessState)'
done
printf '%s\t' "$SA_EVE"
gcloud policy-intelligence troubleshoot-policy iam "$KEY_RES" \
  --principal-email="$SA_EVE" --permission=cloudkms.cryptoKeyVersions.useToSign \
  --format='value(overallAccessState)'
```

  The resource name is built from `EVE_KEYRING`, and echoed first so the reviewer sees the key the seven reads are about: a resource name with a ring that does not exist returns `UNKNOWN_INFO` for everybody, which is a wrong resource, not a proof.

- **VERIFY:** `CANNOT_ACCESS` for all six of the first list — the verifier, the v0 account, the console, `walle-actions@`, the Eve owner and the platform owner's daily account. `CAN_ACCESS` for `eve-controller@` and for nothing else. `UNKNOWN_INFO` or `UNKNOWN_CONDITIONAL` is **not** a pass: it means the caller could not see enough policy, and the read is repeated with a principal that can. **Never grant `serviceAccountTokenCreator` to make a test run.** The real `AsymmetricSign` denial (EVE-3) is exercised at `E3-9.2`, where `eve-verifier@`'s own workload runs it.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-5.7-troubleshoot-v1.txt` with the echoed resource name and all seven principal lines (six `CANNOT_ACCESS`, one `CAN_ACCESS`); `evidence_add E3-5.7 kms-negative E-08 4.2.1 build-log:records/<file> <file>`. E-08. TISAX 4.2.1. Closes **S137**.

### E3-5.8 No human can become `eve-controller@`

- **WHO:** Security reviewer.
- **WHERE:** Shell.
- **ACTION:** The second of the two sentences this file must keep true. Two reads: one on the account resource for `actAs`, one for impersonation reachability across the whole project.

```bash
gcloud iam service-accounts get-iam-policy "$SA_EVE" --project="$EVE_PROJECT" --format=json \
  | jq -c '[.bindings[]? | {role, members, condition: (.condition.title // "-")}]'
gcloud asset analyze-iam-policy --project="$EVE_PROJECT" --billing-project="$CICD_PROJECT" \
  --full-resource-name="//iam.googleapis.com/projects/${EVE_PROJECT}/serviceAccounts/${SA_EVE}" \
  --permissions="iam.serviceAccounts.actAs,iam.serviceAccounts.getAccessToken,iam.serviceAccounts.getOpenIdToken,iam.serviceAccounts.signBlob,iam.serviceAccounts.signJwt" \
  --expand-groups --format=json > "${R}-5.8-actas.json"
jq -r '[.analysisResults[]?.iamBinding | {role, members}] | .[] | "\(.role)\t\(.members|join(","))"' "${R}-5.8-actas.json" | sort -u
gcloud asset analyze-iam-policy --project="$EVE_PROJECT" --billing-project="$CICD_PROJECT" \
  --full-resource-name="//cloudkms.googleapis.com/${EVE_KEYRING}/cryptoKeys/eve-approval" \
  --permissions="cloudkms.cryptoKeyVersions.useToSign" --analyze-service-account-impersonation \
  --expand-groups --format=json > "${R}-5.8-impersonation.json"
jq -r '[.serviceAccountImpersonationAnalysis[]?.analysisResult.analysisResults[]?.iamBinding | {role, members}] | .[] | "\(.role)\t\(.members|join(","))"' "${R}-5.8-impersonation.json" | sort -u
```

  If the `analyze-iam-policy` calls fail with `SERVICE_DISABLED`, enable `cloudasset.googleapis.com` in `CICD_PROJECT` — never in `EVE_PROJECT`, whose service list is closed — and record the enablement; the fallback, used only if the API cannot be enabled that day, is the account-level `get-iam-policy` above plus a project-level read filtered to `iam.serviceAccountTokenCreator` and `iam.serviceAccountUser`, with the gap recorded as a finding.
- **VERIFY:** The account policy holds **no** `roles/iam.serviceAccountTokenCreator` for any principal, and **no unconditioned** `roles/iam.serviceAccountUser` for a human. The only `actAs` path is the PAM entitlement's, which exists for the life of a grant the Eve owner approves — `E3-2.3` and `E3-6.2` show it appearing and going. The impersonation analysis returns **no human and no group** able to reach `useToSign` through impersonation. One line naming a person is a severity-1 finding and the signer binding is removed until it is gone.
- **ROLLBACK:** Read only. Any binding found is removed on the spot and recorded.
- **EVIDENCE:** Both JSON files and the two summaries; `evidence_add E3-5.8 no-human-signer E-08 4.2.1 build-log:records/<file> <file>`. E-02, E-08. TISAX 4.2.1, 1.5.1.

### E3-5.9 No standing `cloudkms.admin` on ring `EVE_KEYRING`

- **WHO:** Security reviewer.
- **WHERE:** Shell.
- **ACTION:** The other half of S134's fix: the guard of §8 is worth nothing if a human holds ring administration standing.

```bash
gcloud kms keyrings get-iam-policy "$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" --format=json | jq -c '.bindings // []'
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json \
  | jq -r '[.bindings[] | select(.role=="roles/cloudkms.admin" or .role=="roles/owner" or .role=="roles/editor")] | .[] | "\(.role)\t\(.members|join(","))\t\(.condition.title // "-")"'
"$PLATFORM_REPO_DIR/pam/tools/sweep.py" --project "$EVE_PROJECT" --role roles/cloudkms.admin
```

- **VERIFY:** The ring policy is `[]`. At project level, `roles/cloudkms.admin` appears **only** as a PAM-made conditioned binding, or not at all when no grant is live; no `roles/owner` and no `roles/editor` for anybody. `sweep.py` prints no standing human, group or domain holder.
- **ROLLBACK:** Read only. A standing holder is removed under [12](12-privileged-access-catalogue.md)'s rules and recorded.
- **EVIDENCE:** `${R}-5.9-no-standing-admin-v1.txt`. E-08. TISAX 4.2.1.

## 6. `eve-gate` — **BLOCKED on B-19**

`eve-gate` is the fourth entrypoint of the same image, deployed as **its own** Cloud Run job so that only its identity holds `signer`. Every step in this section is blocked until the code exists.

**Run §7.1 to §7.4 before this section.** `E3-6.2` passes `EVE_RECEIPTS_DS` into the job's environment, and that variable is written by `E3-7.1`; deployed in file order the gate would carry an empty receipts dataset and its receipt write — the one thing `walle-actions` reads from Eve — would go nowhere. The receipts dataset, the view and its two grants depend on nothing in §6, so they come first; `E3-6.2` opens with `need EVE_RECEIPTS_DS` and refuses otherwise. The execution order of the S4 sitting is §4, §5, §7, §6, §8, §9, §10, as the Status block and the flow diagram say.

> **BLOCKED**: Needs: the `gate` entrypoint in Eve's image — the plan fetch through `GET /v1/plans/{id}`, the five recomputations, `sign_envelope()` reachable **only** from `verdict_for_plan()`, the reason-code validator, the veto path and the receipt write. Commit it in: the Eve repository, reviewed by the second operator, built and attested in `CICD_PROJECT`, pushed to `AR_PLATFORM` by digest. Unblocked by: a re-run of `E3-6.1` printing the digest and the attestation. Gate waiting: S4 entry in full — `E3-6.*`, `E3-8.2`, `E3-8.3`, `E3-9.2`, `E3-9.4`, and the first `eve_authority: binding` cell at `E3-9.5`. README row: **B-19**.

### E3-6.1 Build and attest the image — **BLOCKED**

- **WHO:** Platform owner through CI; the attestor is the platform's.
- **WHERE:** `CICD_PROJECT`.
- **ACTION:** When unblocked: the image is built and attested in `CICD_PROJECT` and pushed to `AR_PLATFORM`; `EVE_PROJECT` has neither `cloudbuild` nor `artifactregistry` enabled, deliberately — a controller project that could build its own image would let a merge into `eve/config` change what Eve runs without the platform's attestation. Until then: `checkpoint E3-6.1 BLOCKED - - "B-19: eve-gate entrypoint"`.
- **VERIFY:** When unblocked: the digest is pinned in `EVE_RECONCILER_IMAGE`'s form, `gcloud artifacts docker images describe … --show-provenance` names `BINAUTHZ_ATTESTOR`, and the CI import test proves the stub caller and any fault-injection path are **absent** from the admitted image.
- **ROLLBACK:** Do not promote the digest.
- **EVIDENCE:** The BLOCKED line; then the digest and the provenance as `${R}-6.1-image-v1.txt`. E-09. TISAX 5.2.3.

### E3-6.2 Deploy `eve-gate`, `--max-retries=0` — **BLOCKED**

- **WHO:** Platform owner under `ENT_DEPLOY_CREDENTIAL_HOLDER_EVE`, approved by the Eve owner.
- **WHERE:** Shell.
- **ACTION:** When unblocked:

```bash
need EVE_RECEIPTS_DS EVE_KEY_VERSION EVE_TOKEN_VERSION SA_EVE EVE_RECONCILER_IMAGE ACTIONS_URL SUPER_ACTIONS_URL ENT_DEPLOY_CREDENTIAL_HOLDER_EVE
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_RECEIPTS_DS}" > /dev/null || { echo "STOP: the receipts dataset of E3-7.1 does not exist; run §7.1 to §7.4 first"; false; }
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_RECEIPTS_DS}" | jq -r '.location'
g_gate="$(pam_request "$ENT_DEPLOY_CREDENTIAL_HOLDER_EVE" "setup-41 E3-6.2: deploy eve-gate as eve-controller@" 1800)"; pam_wait "$g_gate" ACTIVE
gcloud run jobs deploy eve-gate \
  --project="$EVE_PROJECT" --region="$REGION" \
  --image="$EVE_RECONCILER_IMAGE" \
  --service-account="$SA_EVE" \
  --args=gate \
  --tasks=1 --max-retries=0 --task-timeout=300s \
  --set-env-vars="^;^EVE_PROJECT=${EVE_PROJECT};WALLE_PROJECT=${WALLE_PROJECT};ACTIONS_URL=${ACTIONS_URL};SUPER_ACTIONS_URL=${SUPER_ACTIONS_URL};EVE_KEY_VERSION=${EVE_KEY_VERSION};EVE_RECEIPTS_DS=${EVE_RECEIPTS_DS}" \
  --set-secrets="EVE_REFRESH_TOKEN=eve-refresh-token:${EVE_TOKEN_VERSION}"
pam_revoke "$g_gate"
```

  **`--max-retries=0`, not 1.** A retried gate task would re-sign, and a second envelope for the same plan is a second authorisation. The secret is referenced by name and pinned version; no value is read, printed or stored. The `need` line and the dataset read are the precondition on §7.1 to §7.4: an empty `EVE_RECEIPTS_DS` in `--set-env-vars` is not a deploy error, it is a gate that writes receipts nowhere.
- **VERIFY:** When unblocked: `gcloud run jobs describe eve-gate --project="$EVE_PROJECT" --region="$REGION" --format='yaml(template.template.containers[0].image,template.template.containers[0].env,template.template.serviceAccount,template.template.maxRetries)'` shows `maxRetries` `0`; the service account `eve-controller@`; the image as a digest; `EVE_RECEIPTS_DS` set to the value `E3-7.1` recorded; `SUPER_ACTIONS_URL` is present (its absence would leave the super lane running through an incident — the defect [36](36-wall-e-joins-to-eve-and-mo.md) `WJ-5.3` closed); the secret reference names version `EVE_TOKEN_VERSION` and not `latest`. The grant reads `REVOKED` and `E3-5.8`'s read is repeated to prove the `actAs` is gone.
- **ROLLBACK:** `gcloud run jobs delete eve-gate --project="$EVE_PROJECT" --region="$REGION"`. Plans then sit at `pending_eve` and `eve_silence` sets `no_autonomous` after four business hours — closed, never open.
- **EVIDENCE:** `${R}-6.2-eve-gate-v1.txt`. E-09, E-08. TISAX 5.2.3, 4.2.1.

### E3-6.3 The two-minute schedule, and `EVE_GATE_URL` — **BLOCKED**

- **WHO:** Platform owner.
- **WHERE:** Shell.
- **ACTION:** When unblocked:

```bash
penv_set EVE_GATE_URL "https://run.googleapis.com/v2/projects/${EVE_PROJECT}/locations/${REGION}/jobs/eve-gate:run"
gcloud scheduler jobs create http eve-gate-poll \
  --project="$EVE_PROJECT" --location="$REGION" --schedule="*/2 * * * *" \
  --uri="$EVE_GATE_URL" --http-method=POST \
  --oauth-service-account-email="$SA_EVE" \
  --attempt-deadline=30s --max-retry-attempts=0
```

  `EVE_GATE_URL` holds a **`:run` endpoint of the Cloud Run Admin API**, not a service address, because `eve-gate` is a job and exposes nothing. That is deliberate and is the same property throughout: Eve is a client everywhere. It has no topic, no subscription and no endpoint, which is what makes "Eve is down" an absence rather than a silence, and what makes it structurally impossible for a safety interlock to run through a conversation.
- **VERIFY:** When unblocked: the scheduler job is `ENABLED` at `*/2 * * * *` with `--oauth-service-account-email` (Cloud Scheduler invokes a Cloud Run job with an **OAuth** token against `run.googleapis.com`, not OIDC) and `maxRetryAttempts: 0`. One manual `gcloud scheduler jobs run eve-gate-poll` produces exactly one execution, and `gcloud run jobs executions list` shows no retry.
- **ROLLBACK:** `gcloud scheduler jobs delete eve-gate-poll --project="$EVE_PROJECT" --location="$REGION"`.
- **EVIDENCE:** `${R}-6.3-schedule-v1.txt`. E-09. TISAX 5.2.3.

### E3-6.4 `eve-gate` is deterministic: prove it three ways — **BLOCKED**

- **WHO:** Security reviewer.
- **WHERE:** Shell and CI.
- **ACTION:** When unblocked, three independent proofs, because one is an assertion and three are a control:

1. **The project cannot reach a model.** Re-run `E3-1.3` against the running deployment: `aiplatform` denied, not enabled, the deliberate enable refused.
2. **The image has no model dependency.** The CI denylist test (EVE-13) fails the build on any denylisted model client in the lockfile; re-run it against the admitted digest.
3. **The identity holds nothing.** The CI IAM assertion (EVE-14) fails if either Eve identity holds any `aiplatform.*` permission; re-run it after every IAM change in this file.

  Plus the egress control: the host allowlist has `aiplatform.googleapis.com` **never registered** (E-19), read from the deployed configuration rather than from the design.
- **VERIFY:** When unblocked: all three green, and the allowlist read shows no model host. A pass on two of three is a fail.
- **ROLLBACK:** Read only; a failure removes the signer binding until it is fixed.
- **EVIDENCE:** `${R}-6.4-deterministic-v1.txt`. E-02. TISAX 1.5.1.

### E3-6.5 How `eve-gate` finds work — **BLOCKED**, and **PENDING** on decision 44

- **WHO:** Platform owner; Wall-E owner confirms which discovery form is implemented.
- **WHERE:** Shell.
- **ACTION:** `eve-gate` discovers work by polling for plans at `state == pending_eve` and then fetching the body from `GET /v1/plans/{id}`. The polling half has an open dependency the design names rather than assumes: Eve holds **no project-level role** in `WALLE_PROJECT`, `agentregistry.viewer` is dropped and `datastore.viewer` is not granted, so the Firestore discovery read exists only in one of two resource-scoped forms — an IAM Condition scoped to Wall-E's `(default)` database, whose expression is **unverified**, or the list endpoint of CC-33. Until decision 44 lands, this step records `PENDING` with the form chosen and the date, and `eve-gate` discovers work through the CC-33 list endpoint over `run.invoker`, which needs no Firestore grant at all.
- **VERIFY:** When unblocked: whichever form is used, a project-level read of `WALLE_PROJECT`'s IAM policy shows **no** Eve principal; the discovery call succeeds; and a deliberate attempt to read a Firestore document outside the scoped form is refused.
- **ROLLBACK:** Fall back to the list endpoint, which is the form that grants nothing.
- **EVIDENCE:** `${R}-6.5-discovery-v1.txt` and the decision-44 reference. E-08. TISAX 4.2.1.

### E3-6.6 Record the gate's addresses

- **WHO:** Platform owner.
- **WHERE:** Shell.
- **ACTION:** `grep '^export EVE_GATE_URL=' "$PLATFORM_ENV_FILE"`, and add the job's resource name and the scheduler job name to the record so that a reader can find all three from one page.
- **VERIFY:** `EVE_GATE_URL` matches the deployed job's project, location and name exactly. While §6 is BLOCKED, `EVE_GATE_URL` stays `*tbd*` and README's variable list says so.
- **ROLLBACK:** `penv_set … --force` with a build-log line.
- **EVIDENCE:** `${R}-6.6-addresses-v1.txt`. E-09. TISAX 5.2.3.

## 7. The receipt view, the Mo carve-out, and the S4 query changes

### E7 preamble: three columns, and why the narrowing is re-argued rather than assumed

The receipt view is the one thing `walle-actions` may read from Eve. It exposes existence and nothing else: the service checks that evidence **arrived** and can never branch on what it says. A compromised Eve can still write false receipts and suppress the evidence-stale sweeper — which is exactly why that sweeper is absence-only and why the blind sample, not Eve, is the precision input.

### E3-7.1 Create the receipts dataset

- **WHO:** Platform owner under `ENT_PROJECT_REPAIR_EVE`, approved by the Eve owner.
- **WHERE:** Shell. **This step runs before §6**: `E3-6.2` consumes the `EVE_RECEIPTS_DS` it writes.
- **ACTION:** An authorized view must live in a **different dataset** from its source, in the same location, so it cannot sit in `eve`.

```bash
checkpoint E3-7.1 START
penv_set EVE_RECEIPTS_DS eve_receipts
bq --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" mk --dataset \
  --default_kms_key="$EVE_EVIDENCE_KEY_EU" \
  --label=agent:eve --label=env:prod --label=data_class:record \
  --description="Existence-only verdict receipts for walle-actions; authorised on eve. Three columns, no verdict content (E-17)." \
  "${EVE_PROJECT}:${EVE_RECEIPTS_DS}"
```

  The dataset carries the `europe` multi-region key, like every `EU` dataset in this project (SD-47): a dataset in region `EU` is protected with a key ring from region `europe`, which is why `EVE_EVIDENCE_KEY_EU` and not `EVE_EVIDENCE_KEY` appears here.
- **VERIFY:** `bq show --format=prettyjson` gives `location: EU`, the default key equal to `EVE_EVIDENCE_KEY_EU`, and an access list with no `userByEmail` entry yet.
- **ROLLBACK:** `bq rm -r -f -d "${EVE_PROJECT}:${EVE_RECEIPTS_DS}"`, before `E3-7.4` grants anything.
- **EVIDENCE:** `${R}-7.1-receipts-ds-v1.json`. E-07. TISAX 1.3.1.

### E3-7.2 The view, with `ts AS verdict_ts` (S036)

- **WHO:** Platform owner.
- **WHERE:** Shell.
- **ACTION:** The `verdicts` table's timestamp column is **`ts`**: it is the partitioning field the table was created with and the name the LLD gives it. `verdict_ts` is the **view's output name**, not a source column. The superseded text selected `verdict_ts` from the table, and BigQuery validates a view's query at creation, so `bq mk --view` failed with an unrecognised name and everything after it — the authorised-view entry, the `walle-actions@` grant, the verify — had nothing to point at. The alias is the whole fix; the table is not touched.

```bash
bq mk --use_legacy_sql=false --view \
  "SELECT run_id, item, ts AS verdict_ts FROM \`${EVE_PROJECT}.${EVE_DS}.verdicts\`" \
  --description="Existence-only receipts: a plan's item was verdicted and when. No verdict, no reason code (E-17, CC-11)." \
  "${EVE_PROJECT}:${EVE_RECEIPTS_DS}.verdict_receipts"
```

- **VERIFY:**

```bash
bq show --schema --format=prettyjson "${EVE_PROJECT}:${EVE_RECEIPTS_DS}.verdict_receipts" \
  | python3.12 -c "import json,sys;print([f['name'] for f in json.load(sys.stdin)])"
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_DS}.verdicts" | jq -r '.timePartitioning.field'
```

  Expect `['run_id', 'item', 'verdict_ts']` — three names, in that order — and the partitioning field still `ts`. A schema with four columns, or one containing `verdict` or `reason_code`, is rejected: the narrowing is the control.
- **ROLLBACK:** `bq rm -f -t "${EVE_PROJECT}:${EVE_RECEIPTS_DS}.verdict_receipts"`.
- **EVIDENCE:** `${R}-7.2-receipt-view-v1.txt`. E-07, E-11. TISAX 1.3.1. Closes **S036**.

### E3-7.3 Authorise the view on `eve`, with a read-back diff

- **WHO:** Platform owner; Eve owner watches the diff.
- **WHERE:** Shell.
- **ACTION:** Access-array edits follow [01](01-prerequisites-and-conventions.md)'s convention: `mktemp`, keep the etag, read back and diff. A `bq update --source` writes the **whole** dataset resource, so an edit built from a stale or hand-typed file silently drops entries.

```bash
A="$(mktemp -d)"; e3_set A "$A"
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_DS}" > "$A/eve-before.json"
jq -r '.etag, ([.access[]] | length)' "$A/eve-before.json"
P="$EVE_PROJECT" D="$EVE_RECEIPTS_DS" python3.12 - "$A/eve-before.json" "$A/eve-after.json" <<'EOF'
import json, os, sys
d = json.load(open(sys.argv[1]))
entry = {"view": {"projectId": os.environ["P"], "datasetId": os.environ["D"], "tableId": "verdict_receipts"}}
acc = d.setdefault("access", [])
if entry not in acc:
    acc.append(entry)
json.dump(d, open(sys.argv[2], "w"), indent=2, sort_keys=True)
EOF
diff <(jq -S '[.access[] | select(has("view") | not)]' "$A/eve-before.json") \
     <(jq -S '[.access[] | select(has("view") | not)]' "$A/eve-after.json") && echo "NON-VIEW ACCESS UNCHANGED"
bq update --source="$A/eve-after.json" "${EVE_PROJECT}:${EVE_DS}"
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_DS}" > "$A/eve-readback.json"
diff <(jq -S '.access' "$A/eve-after.json") <(jq -S '.access' "$A/eve-readback.json") && echo "READBACK MATCHES"
```

- **VERIFY:** `NON-VIEW ACCESS UNCHANGED` prints before the write; the access-entry count rises by exactly one; `READBACK MATCHES` prints after it. The `eve` dataset's access list holds the view entry and **no** `userByEmail` entry for `walle-actions@` — the service reads the view's dataset, never `eve`.
- **ROLLBACK:** `bq update --source="$A/eve-before.json" "${EVE_PROJECT}:${EVE_DS}"` within the sitting.
- **EVIDENCE:** All three files and the two diffs as `${R}-7.3-authorise-view-v1`. E-07, E-08. TISAX 1.3.1, 4.2.1.

### E3-7.4 `walle-actions@` reads the receipts dataset and nothing else

- **WHO:** Platform owner.
- **WHERE:** Shell.
- **ACTION:** Dataset-level `READER` on the view's dataset — carve-out 2 of decision 48. The query jobs for that read run and are billed in `WALLE_PROJECT` under `walle-actions@`'s own job-creation right there; nothing runs in `EVE_PROJECT` on Wall-E's behalf.

```bash
need A SA_ACTIONS EVE_RECEIPTS_DS
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_RECEIPTS_DS}" > "$A/receipts-before.json"
SA="$SA_ACTIONS" python3.12 - "$A/receipts-before.json" "$A/receipts-after.json" <<'EOF'
import json, os, sys
d = json.load(open(sys.argv[1]))
entry = {"role": "READER", "userByEmail": os.environ["SA"]}
acc = d.setdefault("access", [])
if entry not in acc:
    acc.append(entry)
json.dump(d, open(sys.argv[2], "w"), indent=2, sort_keys=True)
EOF
bq update --source="$A/receipts-after.json" "${EVE_PROJECT}:${EVE_RECEIPTS_DS}"
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_DS}" \
  | python3.12 -c "import json,sys;print([a for a in json.load(sys.stdin)['access'] if 'walle-' in json.dumps(a)])"
```

- **VERIFY:** The receipts dataset lists `READER` for `walle-actions@`; the `eve` dataset's Wall-E filter prints `[]`. The live proof — `walle-actions@` querying `eve.verdicts` and being refused — is EVE-12 at `E3-9.3`.
- **ROLLBACK:** Restore `receipts-before.json`.
- **EVIDENCE:** `${R}-7.4-receipts-grant-v1.txt`. E-08. TISAX 4.2.1.

### E3-7.5 The one Mo carve-out, from S4 (closes `WJ-3.6`)

- **WHO:** Platform owner makes it; Mo owner confirms what Mo reads; Eve owner records.
- **WHERE:** Shell.
- **ACTION:** Topology row 18 and decision 51 make Eve's mirror the off-project evidence copy Mo reads **from S4**, so Wall-E's deployers cannot rewrite the evidence Mo argues from. It is dataset-level `READER` on the mirror's dataset only — which is why the mirror has a dataset of its own and does not sit in `eve` next to `verdicts`, `findings` and the blind tables.

```bash
need A SA_MO_METRICS EVE_MIRROR_DS
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_MIRROR_DS}" > "$A/mirror-before.json"
exists_or_pending "serviceAccount:${SA_MO_METRICS}" E3-7.5 "41 E3-7.5: mo-metrics@ READER on the mirror dataset at S4 (topology row 18)" && {
  SA="$SA_MO_METRICS" python3.12 - "$A/mirror-before.json" "$A/mirror-after.json" <<'EOF'
import json, os, sys
d = json.load(open(sys.argv[1]))
entry = {"role": "READER", "userByEmail": os.environ["SA"]}
acc = d.setdefault("access", [])
if entry not in acc:
    acc.append(entry)
json.dump(d, open(sys.argv[2], "w"), indent=2, sort_keys=True)
EOF
  bq update --source="$A/mirror-after.json" "${EVE_PROJECT}:${EVE_MIRROR_DS}"
}
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_DS}" \
  | python3.12 -c "import json,sys;print([a for a in json.load(sys.stdin)['access'] if 'mo-' in json.dumps(a)])"
```

- **VERIFY:** `READER` for `mo-metrics@` on the mirror dataset; the `eve` filter prints `[]` — "ever" holds for `eve` and for every non-quality dataset, including the receipts dataset. `mo-metrics@` holds dataset-level `READER` on exactly **two** Eve datasets: this mirror from today, and `eve_quality` from Wall-E's Stage 1 ([29](29-mo-eve-quality-pack.md)). Eve's drift job expects exactly that pair from S4 and fails on any other Mo principal, or on this one before S4 — so the drift job is re-run in the same sitting and must now pass with the new entry.
- **ROLLBACK:** Restore `mirror-before.json`; Mo falls back to the live dataset, which is a weaker position and is recorded as such.
- **EVIDENCE:** `${R}-7.5-mo-carveout-v1.txt` and the drift run. E-08. TISAX 4.2.1.

### E3-7.6 The S4 query changes, by `--params` (S204)

- **WHO:** Platform owner; Eve owner reviews the committed SQL first.
- **WHERE:** Shell.
- **ACTION:** Two rules, written here because the superseded text got both wrong and the mistake is cheap to repeat.

1. **A scheduled query's destination lives where the query puts it.** For a DML or `INSERT … SELECT` config the destination table is inside the SQL text. `--target_dataset` sets the *destination dataset* used by a query with a destination-table template; changing it on a DML config moves nothing and the job keeps writing where the SQL says. The way to retarget is to rewrite the query: `bq update --transfer_config --params='{"query":"…"}'`.
2. **Never drop the old table on the strength of a successful run.** Run both, compare row counts **per partition**, and only then drop.

```bash
need EVE_V0_CONFIGS
Q="$(mktemp -d)"; : > "$Q/configs.tsv"
for cfg in $(printf '%s\n' "$EVE_V0_CONFIGS" | tr ',' '\n'); do
  bq show --transfer_config --format=prettyjson "$cfg" > "$Q/${cfg##*/}.json"
  jq -r '.displayName, .schedule, .ownerInfo.email, .params.query' "$Q/${cfg##*/}.json" > "${R}-7.6-before-${cfg##*/}.txt"
  printf '%s\t%s\n' "$(jq -r '.displayName' "$Q/${cfg##*/}.json")" "$cfg" >> "$Q/configs.tsv"
done
cat "$Q/configs.tsv"
for f in "$PLATFORM_REPO_DIR"/eve/sql/s4/*.sql; do
  dn="$(basename "$f" .sql)"
  cfg="$(awk -F'\t' -v d="$dn" '$1 == d {print $2}' "$Q/configs.tsv")"
  n="$(printf '%s' "$cfg" | grep -c .)"
  if [ "$n" -eq 1 ]; then
    bq update --transfer_config --params="$(jq -n --arg q "$(cat "$f")" '{query: $q}')" "$cfg" && echo "UPDATED ${dn} -> ${cfg}"
  else
    echo "STOP: ${dn}.sql resolved to ${n} transfer configs by displayName, expected exactly one; nothing updated for it"
  fi
done
for cfg in $(printf '%s\n' "$EVE_V0_CONFIGS" | tr ',' '\n'); do
  printf '%s\t' "${cfg##*/}"; bq show --transfer_config --format=prettyjson "$cfg" | jq -r '[.displayName, .ownerInfo.email, .schedule, (.params.query | length)] | @tsv'
done
```

  The query text comes from a committed file, never from a shell heredoc typed at the console: what a config runs must be reviewable in the repository afterwards. **A transfer config is addressed by its resource name, which ends in a server-generated id** (`projects/N/locations/eu/transferConfigs/<id>`), never in its display name, so a SQL file cannot be matched to a config by grepping `EVE_V0_CONFIGS` for the file's basename — that grep returns nothing and `bq update` runs with no config argument. The map above is built once per sitting from each config's `displayName`, read live, and a file that resolves to zero or several configs is reported and skipped. *Assumption:* [36](36-wall-e-joins-to-eve-and-mo.md) named each config's `displayName` after the basename of the SQL file it runs; if the names differ, the map is committed as `eve/sql/s4/configs.tsv` (`displayName<TAB>resource name`) and read in place of the live one, and the record says which.
- **VERIFY:** `cat "$Q/configs.tsv"` prints one line per config in `EVE_V0_CONFIGS`, each with a non-empty display name; the update loop prints an `UPDATED` line for **every** `.sql` file and no `STOP` — one `STOP` means one S4 change did not apply, and the step is not closed until it is resolved. For each config: `ownerInfo.email` is still `eve-v0@` (the pinning survived the update — a config whose owner reverts to a human credential is not independent evidence and dies when that person leaves); the schedule is unchanged and still off the hour; the new query length matches the committed file. One manual run of each, then the per-partition row-count comparison against the previous destination. Nothing is dropped in this sitting: a drop is its own dated step after a full retention period of agreement.
- **ROLLBACK:** `bq update --transfer_config --params` with the previous query text, which is in `${R}-7.6-before-*.txt`.
- **EVIDENCE:** The before and after files and the row-count comparison as `${R}-7.6-config-update-v1`. E-11. TISAX 5.2.4. Closes **S204**.

## 8. The key-destruction guard, given one owner

### E3-8.1 Decide the owner, and correct the four pages that name the other one (S134)

- **WHO:** Eve owner decides and signs; security reviewer countersigns; platform owner records.
- **WHERE:** `PLATFORM_REPO_DIR/decisions/`, and the wiki.
- **ACTION:** Two documents pointed at each other and neither held the guard. Wall-E's helper script says the flag is gone and that destroying a version is Eve's owner's act; Eve's runbook says the flag stays there "because the guard code is there" and verifies with a command `argparse` rejects. `_pem_archive_present` exists nowhere. Destroying a key version was therefore an unguarded manual `gcloud kms keys versions destroy` by whoever held `cloudkms.admin`.

  **Decision E-21, recorded today: the guard is Eve's, and it is a tool in Eve's repository.** The reasons: the key lives in `EVE_PROJECT`, so destruction is a cross-project act from Wall-E's script's point of view; no Wall-E service identity holds, or may ever hold, `cloudkms.admin` on Eve's key ring; and the two owner groups of E-2 are already different people, which is the condition the earlier text said would reopen the question.

  The same change corrects every page that still names the retired flag: [../../eve/07-build-runbook.md](../../eve/07-build-runbook.md) Phase 12, [../../eve/09-open-decisions.md](../../eve/09-open-decisions.md), [../../eve/02-identity-and-auth.md](../../eve/02-identity-and-auth.md), [../../eve/08-contract-changes.md](../../eve/08-contract-changes.md) CC-21 and [../09-supply-chain-secrets-recovery.md](../09-supply-chain-secrets-recovery.md) SK-5. Each keeps a one-line pointer here rather than a repaired copy of the command.
- **VERIFY:** `decisions/<date>-eve-key-destruction-owner.md` exists, dated, signed by the Eve owner and the security reviewer, and names the tool path. `grep -rn 'destroy-key-versions' wiki/platform/` returns only lines that say the flag is retired and point at E-21. The row is added to [03](03-decisions-and-people.md)'s tracker at its next review.
- **ROLLBACK:** A decision record is superseded, never rewritten.
- **EVIDENCE:** `${R}-8.1-e21-v1.md`; `evidence_add E3-8.1 key-destruction-owner E-01 4.3.1 platform-repo:decisions <file>`. E-01. TISAX 1.4.1, 4.3.1. Closes the ownership half of **S134**.

### E3-8.2 The tool, with a self-test — **BLOCKED on B-19**

- **WHO:** Eve owner specifies; platform owner reviews the code; second operator is the reviewer on the merge.
- **WHERE:** Eve's repository.
- **ACTION:** When unblocked, `eve/tools/destroy_key_version.py` refuses and exits non-zero, naming the version and **both** expected paths, unless all three hold:

1. `gs://${EVE_PROJECT}-eve-evidence/keys/eve-approval-v<N>.pem` exists;
2. `contracts/eve-public-keys/<N>.pem` is committed on the default branch of `WALLE_REPO_REMOTE`;
3. the version's last recorded use is **outside** the 400-day evidence horizon.

  It is a **precondition check, not a warning**: not prompt, not confirm — refuse. The operator running a teardown is by definition not thinking about evidence retention. It has a self-test in Eve's CI with three cases: archive intact and horizon passed (proceeds in `--dry-run`), bucket copy absent (refuses), repository copy absent (refuses). Until the tool exists: `checkpoint E3-8.2 BLOCKED - - "B-19: destroy_key_version.py"`, and the standing instruction is that **no key version is destroyed by any means**.
- **VERIFY:** When unblocked: the three self-test cases pass in CI; the merge has two reviewers; `--dry-run` against version 1 today refuses on rule 3 alone, because version 1 is one day old.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** The BLOCKED line; then the CI run as `${R}-8.2-guard-v1.txt`. E-09. TISAX 4.3.1.

### E3-8.3 Prove the refusal, both ways — **BLOCKED on B-19**

- **WHO:** Eve owner runs; security reviewer watches.
- **WHERE:** Shell, against a **sandbox** key ring in `EVE_TWIN_PROJECT`, never against `eve-approval`.
- **ACTION:** When unblocked: create a throwaway HSM signing key in the twin, archive its PEM in both places, run the tool `--dry-run` (expect: it lists the version it would destroy), remove the bucket copy's twin equivalent, run again (expect: refusal naming the missing path), restore, remove the repository copy, run again (expect: refusal naming the other path). The production key is never an input to this test.
- **VERIFY:** When unblocked: one proceed and two refusals, each refusal exiting non-zero and naming the exact missing path. A refusal that prints a warning and continues is a failed test.
- **ROLLBACK:** Disable and abandon the throwaway twin key; do not destroy it either — the twin follows the same rule.
- **EVIDENCE:** `${R}-8.3-guard-proof-v1.txt`. E-09, E-12. TISAX 4.3.1. Closes the enforcement half of **S134**.

### E3-8.4 The belt behind the guard

- **WHO:** Security reviewer.
- **WHERE:** Shell.
- **ACTION:** A tool can be bypassed by not using it. Three organisation-policy and IAM facts stand behind it, and each is read rather than assumed:

```bash
for c in cloudkms.allowedProtectionLevels cloudkms.disableBeforeDestroy cloudkms.minimumDestroyScheduledDuration; do
  printf '%s\t' "$c"
  gcloud org-policies describe "$c" --project="$EVE_PROJECT" --effective \
    --format='value(spec.rules[0].enforce,spec.rules[0].values.allowedValues)'
done
gcloud kms keys describe eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT" \
  --format='value(destroyScheduledDuration)'
```

- **VERIFY:** `allowedProtectionLevels` is `is:HSM`; `disableBeforeDestroy` is enforced, so a destroy of an enabled version is refused outright; `minimumDestroyScheduledDuration` is `in:30d`; the key's own duration is `2592000s`. Together with `E3-5.9`'s "no standing `cloudkms.admin`", that is four independent things a person would have to defeat, in order, to make a past approval unverifiable.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-8.4-belt-v1.txt`. E-08. TISAX 4.3.1.

### E3-8.5 The two teardown facts, written down before they are discovered

- **WHO:** Platform owner records; Eve owner reads.
- **WHERE:** The record, and `DEVIATION_REGISTER`'s notes column.
- **ACTION:** Neither is a bug to route around:

- **An organisation-level sink outlives the project.** `eve-workspace-audit` must be deleted **before** anything else in a teardown, or it keeps exporting to a destination that no longer exists.
- **The locked evidence bucket applies a lien preventing project deletion.** `gcloud projects delete` fails until the retention period expires, and removing the lien is a project-owner or organisation-administrator act that is itself an event Eve detects.

- **VERIFY:** Both sentences are in the S4-entry record and in the teardown section of the Eve owner's own notes, with the step ids that created each object ([24](24-eve-workspace-identity-and-audit-feeds.md) for the sink, [23](23-eve-project-and-evidence-stores.md) `EP-7.8` for the lock).
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** `${R}-8.5-teardown-facts-v1.md`. E-13. TISAX 4.3.1.

### E3-8.6 Rotation: a dated manual procedure, because there is no automatic one

- **WHO:** Eve owner owns the date; platform owner performs the rotation when it comes.
- **WHERE:** `DRILL_CALENDAR`.
- **ACTION:** Cloud KMS does not support automatic rotation for asymmetric signing keys — the new public key must be distributed before it can be used — so there is no rotation schedule to set and none to forget. The procedure: **annually, and immediately on suspicion of compromise**, with a **30-day overlap** during which `walle-actions` accepts both versions keyed on the `eve_key_version` in each envelope; the new version's PEM exported **at creation** into both places by `E3-4.3`'s steps; the old version **disabled, never destroyed** inside the 400-day evidence horizon.
- **VERIFY:** A `DRILL_CALENDAR` row dated one year from `E3-4.2`, owner the Eve owner, with a pointer to `E3-4.2` to `E3-4.5` as the procedure. Nothing will remind you; the calendar is the reminder.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** `${R}-8.6-rotation-v1.txt`. E-13. TISAX 4.3.1.

## 9. The denial suite, and the first binding cell

### E3-9.1 The suite, with a runner named for every row

- **WHO:** Eve owner assembles; security reviewer reads.
- **WHERE:** The record; the suite itself lives in Eve's CI.
- **ACTION:** Wall-E's own suite already carries tests 4, 5, 6 and 52. These are the rows Eve's build owns. The column the superseded text lacked is the last one: a test with no named runner is a sentence, not a control.

| # | Test | Expected | Runner |
|---|---|---|---|
| EVE-1 | `eve-controller@` calls `POST /v1/execute` | **403.** Eve never executes | `eve-gate` CI, sandbox |
| EVE-2 | `eve-verifier@` calls `POST /v1/plans/{id}/approve` | Denied; only the gate identity signs | Eve CI, sandbox |
| EVE-3 | `eve-verifier@` calls KMS `AsymmetricSign` on `eve-approval` | `PERMISSION_DENIED` at Google's end | `E3-9.2`, as `eve-verifier@`'s own job |
| EVE-4 | An operator ID token calls `POST /v1/control/halt` | **Accepted** | [36](36-wall-e-joins-to-eve-and-mo.md) `WJ-5.5`, re-run here |
| EVE-5 | An envelope signed over a `plan_hash` the service reported rather than one Eve recomputed | Rejected by the CI call-graph test: `sign_envelope()` is reachable only from `verdict_for_plan()` | Eve CI |
| EVE-6 | An envelope missing `items_hash` | `bad_approval` | `E3-9.4` |
| EVE-7 | A valid signature for a cell whose `eve_authority` is advisory or absent | `denied: eve_authority_advisory` | `E3-9.4` |
| EVE-8 | A valid signature whose `issued_at` is more than 120 seconds off | `bad_approval`; never silently accepted, never silently expired | `E3-9.4` |
| EVE-9 | A valid signature for a plan whose hold window elapsed during an outage | Refused; the plan is expired and Eve never resumes it | `E3-9.4` |
| EVE-10 | An approval replayed after the key version was disabled | Still **verifiable** against the archived PEM, and still refused as used | `E3-9.4` |
| EVE-11 | A verdict carrying a reason code absent from `reasons.yaml` | Rejected before signing | Eve CI |
| EVE-12 | `walle-actions@` reads `eve.verdicts`, or any table in `eve` | Denied; only the receipts dataset is granted | `E3-9.3` |
| EVE-13 | An Eve image with a denylisted model dependency in its lockfile | CI build fails | Eve CI, `E3-6.4` |
| EVE-14 | Either Eve identity holding any `aiplatform.*` permission | CI IAM assertion fails | Eve CI, `E3-6.4` |
| EVE-15 | Bidirectional overrides or zero-width characters in a display name reaching a veto notification | Canonicalised before comparison **and** before display | Eve CI |
| EVE-16 | `eve-advisor@` writes to `eve.verdicts`, `eve.incidents` or `eve/config`, or calls an action service | Denied | **Deferred with the advisor path** — §14 |
| EVE-17 | Any control-path identity reads `eve_advice` | Denied | **Deferred with the advisor path** — §14 |
| EVE-18 | `eve-approval` created or re-created without `--protection-level=hsm` | Refused by `cloudkms.allowedProtectionLevels`; `E3-4.2` verify 1 fails | `E3-8.4`, and [13](13-organisation-policies-deny-and-pab.md) `OP-5.5`'s probe |
| EVE-19 | The sink's rows withheld past the H-1 window, or Eve's token revoked | `log_pipeline_silent`: `no_autonomous` and `halt_all` on both action services; severity-1 page through the witness | [28](28-eve-independent-proof-and-sandbox-drills.md) drill, re-run monthly |
| EVE-20 | A robot-attributed event in a non-Admin stream with no `walle_audit` or band-B row | `reconciliation_gap`, halt | `E3-3.2` fault 9 |
| EVE-21 | A fourth super admin added, or a roster account's role removed | `role_assignment_added` / `role_assignment_missing`, severity 1, in both directions | [28](28-eve-independent-proof-and-sandbox-drills.md), monthly |
| EVE-22 | `mo-metrics@` or the validator custodian queries an Eve dataset other than `eve_quality` and, from S4, the mirror | Denied | `E3-9.3` |

  EVE-3, EVE-12, EVE-13 and EVE-14 are the four mechanical enforcements of the deterministic boundary expressed as tests. They are re-run after **every** IAM change and every dependency bump, because they are the ones that decay quietly.
- **VERIFY:** Every row has a runner and a location. No row says "by hand, once".
- **ROLLBACK:** Not applicable; these are tests.
- **EVIDENCE:** `${R}-9.1-suite-v1.md`. E-12. TISAX 1.5.1.

### E3-9.2 EVE-3, run by the identity it is about — **BLOCKED on B-19**

- **WHO:** Platform owner triggers; security reviewer reads the log.
- **WHERE:** A one-off execution of `eve-reconciler-detect` in the sandbox with the `selftest-kms` argument, which runs **as `eve-verifier@`**.
- **ACTION:** When unblocked: the denial is proved where the identity's own workload runs, not by a human borrowing its name. There is no impersonation anywhere in this step, and **no `serviceAccountTokenCreator` is granted to anybody to make it run** — that grant would create exactly the standing path into the reconciler this design exists to prevent.
- **VERIFY:** When unblocked: the execution logs a `PERMISSION_DENIED` from `cloudkms.googleapis.com` on `AsymmetricSign`, and the corresponding **denied** Data Access log entry appears in `EVE_PROJECT` with `eve-verifier@` as the principal — which also proves `E3-5.2`'s audit configuration is working on the path that matters.
- **ROLLBACK:** None; the attempt changes nothing.
- **EVIDENCE:** `${R}-9.2-eve3-v1.txt` with the log entry. E-06, E-12. TISAX 1.5.1.

### E3-9.3 EVE-12 and EVE-22: the reads that must fail, proved by Policy Troubleshooter

- **WHO:** Security reviewer runs; Eve owner witnesses. **No grant is opened on any account and nothing is impersonated**: the rule of `E3-5.7` and `E3-9.2` — `roles/iam.serviceAccountTokenCreator` is never granted to make a test run — holds here without exception, which is why the earlier form of this step (queries "under a time-boxed grant on the querying account") is gone.
- **WHERE:** Shell.
- **ACTION:** Eleven legs. Each asks whether one principal holds `bigquery.tables.getData` on one table, by the table's full resource name, against the effective allow, deny and principal-access-boundary policies — the form Google's own BigQuery access-troubleshooting page uses for datasets and tables. The dataset-level `READER` entries `E3-7.4` and `E3-7.5` wrote are what the reads must reflect.

```bash
need SA_ACTIONS SA_MO_METRICS SA_VALIDATOR_CUSTODIAN EVE_DS EVE_RECEIPTS_DS EVE_MIRROR_DS EVE_QUALITY_DS
MIRROR_T="$(bq ls --format=prettyjson "${EVE_PROJECT}:${EVE_MIRROR_DS}" | jq -r '.[0].tableReference.tableId')"
QUALITY_T="$(bq ls --format=prettyjson "${EVE_PROJECT}:${EVE_QUALITY_DS}" | jq -r '.[0].tableReference.tableId')"
echo "mirror table: $MIRROR_T; quality table: $QUALITY_T"
bqres() { printf '//bigquery.googleapis.com/projects/%s/datasets/%s/tables/%s' "$EVE_PROJECT" "$1" "$2"; }
leg() { # PRINCIPAL DATASET TABLE EXPECTED
  s="$(gcloud policy-intelligence troubleshoot-policy iam "$(bqres "$2" "$3")" --principal-email="$1" --permission=bigquery.tables.getData --format='value(overallAccessState)')"
  printf '%s\t%s.%s\t%s\texpected %s\t%s\n' "$1" "$2" "$3" "${s:-EMPTY}" "$4" "$([ "$s" = "$4" ] && echo OK || echo FAIL)"
}
{
leg "$SA_ACTIONS"             "$EVE_DS"          verdicts         CANNOT_ACCESS
leg "$SA_ACTIONS"             "$EVE_DS"          findings         CANNOT_ACCESS
leg "$SA_ACTIONS"             "$EVE_RECEIPTS_DS" verdict_receipts CAN_ACCESS
leg "$SA_MO_METRICS"          "$EVE_DS"          findings         CANNOT_ACCESS
leg "$SA_MO_METRICS"          "$EVE_RECEIPTS_DS" verdict_receipts CANNOT_ACCESS
leg "$SA_MO_METRICS"          "$EVE_MIRROR_DS"   "$MIRROR_T"      CAN_ACCESS
leg "$SA_MO_METRICS"          "$EVE_QUALITY_DS"  "$QUALITY_T"     CAN_ACCESS
leg "$SA_VALIDATOR_CUSTODIAN" "$EVE_QUALITY_DS"  "$QUALITY_T"     CAN_ACCESS
leg "$SA_VALIDATOR_CUSTODIAN" "$EVE_DS"          verdicts         CANNOT_ACCESS
leg "$SA_VALIDATOR_CUSTODIAN" "$EVE_MIRROR_DS"   "$MIRROR_T"      CANNOT_ACCESS
leg "$SA_VALIDATOR_CUSTODIAN" "$EVE_RECEIPTS_DS" verdict_receipts CANNOT_ACCESS
} | tee "${R}-9.3-reads-v1.txt"
grep -c 'OK$' "${R}-9.3-reads-v1.txt"
```

  The three `CAN_ACCESS` legs are the positive controls: without them a troubleshooter that answered `CANNOT_ACCESS` to everything — a wrong resource name, a caller who cannot read the policies — would pass the eight negative legs vacuously. If `E3-7.5` recorded `PENDING` rather than making the mirror grant, the `mo-metrics@` mirror leg reads `CANNOT_ACCESS`, is recorded as expected-pending, and is re-run with the grant.
- **VERIFY:** `grep -c` prints `11`: every leg `OK`, with the expected string named per leg — `CANNOT_ACCESS` for `walle-actions@` on `eve.verdicts` and `eve.findings`, for `mo-metrics@` on `eve.findings` and the receipts view, and for the validator custodian on `eve`, the mirror and the receipts; `CAN_ACCESS` for `walle-actions@` on the receipts view, for `mo-metrics@` on the mirror and on `eve_quality`, and for the custodian on `eve_quality`. `UNKNOWN_INFO`, `UNKNOWN_CONDITIONAL` or `EMPTY` on any leg is **not** a pass: the read is repeated with a principal that can see the policies, and never resolved by granting anything to the principal under test. The live-query form of the same proof runs where each principal's own workload runs: `walle-actions`' read of `verdict_receipts` in the end-to-end pass of `E3-9.4` (BLOCKED on B-19), and `mo-metrics@`'s reads in the drift job that `E3-7.5` re-ran in this sitting.
- **ROLLBACK:** Read only; nothing is granted and nothing is revoked.
- **EVIDENCE:** `${R}-9.3-reads-v1.txt` with each principal, resource, outcome and expectation; `evidence_add E3-9.3 eve-12-eve-22 E-08 4.2.1 build-log:records/<file> <file>`. E-08, E-12. TISAX 4.2.1.

### E3-9.4 The gate end to end: one approved, one refused, one vetoed — **BLOCKED on B-19**

- **WHO:** Platform owner runs; Eve owner and Wall-E owner watch; the operator veto is issued by the second operator.
- **WHERE:** The sandbox.
- **ACTION:** When unblocked: `python3.12 tests/eve_gate_e2e.py --sandbox`, covering EVE-6 to EVE-10 in one pass.
- **VERIFY:** When unblocked: a signed approval accepted by `walle-actions` **against the pinned PEM**, with the fallback path disabled for the run so that the primary path is what is proved; a refusal leaving the item waiting for a human; and an operator veto **beating a signature Eve already produced**. Veto wins unconditionally, and the vetoed item enters the blind sample pool at the next draw regardless of rate — a veto is the strongest available signal about Eve's precision.
- **ROLLBACK:** Sandbox only.
- **EVIDENCE:** `${R}-9.4-e2e-v1.json`. E-11, E-12. TISAX 1.5.1, 5.2.4.

### E3-9.5 The first cell at `eve_authority: binding`

- **WHO:** Platform owner raises; **two distinct authenticated approving reviewers, neither the author**, one of them the Eve owner.
- **WHERE:** Wall-E's ladder, in `WALLE_REPO_REMOTE`.
- **ACTION:** A signature binds only for a cell whose ladder entry explicitly sets `eve_authority: binding`. Absent reads as advisory. That one field is the per-cell load-bearing switch, the fail-closed default, and the demotion target when an Eve approval is later overturned. The first cell is **scheduled F2** — a templated notification to a config-fixed recipient, which CC-32 moved here from S2. It is the cheapest possible first L4 cell, and that is the argument for it going first, not for it going early.
- **VERIFY:** The merge shows two human approvals and no service-account approval. The CI validator refuses any configuration placing a cell at L4 while its authority is advisory — re-run it deliberately against a rejected branch to see the refusal, rather than trusting that the rule is live. The published ladder artefact's commit equals the merged commit; `GET /v1/ladder` reports the same level; a level above the merged value is a severity-1 finding, because **humans raise and machines lower**.
- **ROLLBACK:** A reverting pull request returns the cell to advisory. Eve's signature for it is then refused with `eve_authority_advisory`, which is the fail-closed default and needs no other change.
- **EVIDENCE:** The merge commit, the two approvals, the artefact commit and the refused branch as `${R}-9.5-first-binding-v1`. E-04, E-12. TISAX 1.5.1.

## 10. Close

### E3-10.1 The S4-entry record

- **WHO:** Eve owner signs; security reviewer countersigns; platform owner records; a copy goes to the witness.
- **WHERE:** `BUILD_LOG_DIR/records/`, `WITNESS_BUCKET`.
- **ACTION:** One page: the key with its four properties and `EVE_KEY_VERSION`; the three digests; the two merge commits (the PEM and the first binding cell); the audit-configuration change with its etag and its empty binding diff; the Policy Troubleshooter table; the `analyze-iam-policy` result; `EVE_GATE_URL` or its BLOCKED line; the receipts dataset and the three-column schema; the denial-suite results with every runner; decision E-21; and the sentence that **from today Eve can make more happen, for exactly the cells a merged pull request named**.
- **VERIFY:** Two signatures, the witness copy confirmed by a witness administrator, and no secret value anywhere in it — the only key material named is a public key, by digest.
- **ROLLBACK:** Superseded, never rewritten.
- **EVIDENCE:** `${R}-10.1-s4-entry-v1.md`; `evidence_add E3-10.1 s4-entry-record E-13 5.2.4 witness:records/<file> <file>`. E-01, E-13. TISAX 1.4.1, 5.2.4.

### E3-10.2 Variables, registers and the re-run index

- **WHO:** Platform owner.
- **WHERE:** Shell.
- **ACTION:**

```bash
grep -E '^export (EVE_KEY_VERSION|EVE_GATE_URL|EVE_RECEIPTS_DS)=' "$PLATFORM_ENV_FILE"
awk -F'\t' '$2 ~ /^E3-/ {print $2"\t"$3}' "$BUILD_LOG_DIR/checkpoints.tsv" | sort -u
```

  Then: add `BD-41-1` (the `keys/` prefix grant narrowed from `eve-controller@` to `GRP_EVE_OWNERS`) to `DEVIATION_REGISTER`; confirm README's **B-19** row lists `E3-6.1` to `E3-6.5`, `E3-8.2`, `E3-8.3`, `E3-9.2` and `E3-9.4`; close [23](23-eve-project-and-evidence-stores.md) `EP-7.7`'s and [36](36-wall-e-joins-to-eve-and-mo.md) `WJ-3.6`'s pending lines in the re-run index; add this file's own re-run lines — **EVE-3, EVE-12, EVE-13 and EVE-14 after every IAM change and every dependency bump**, the seeded-fault exercise monthly and on every `eve_config_version` change, the rotation date, and `E3-5.7`/`E3-5.8` after any new Eve identity appears.
- **VERIFY:** Three `export` lines, of which `EVE_GATE_URL` may be `*tbd*` while §6 is BLOCKED. Every `E3-` checkpoint is `DONE`, `BLOCKED` (only the nine B-19 steps) or `PENDING` (`E3-6.5` while decision 44 is open). Both consumed pending lines are closed.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** `${R}-10.2-close-v1.txt`. E-13. TISAX 1.4.1.

### E3-10.3 The rollback of the whole part, and the end of the sitting

- **WHO:** Eve owner decides; platform owner performs.
- **WHERE:** Shell.
- **ACTION:** If S4 has to be undone — a defect, or a suspected compromise — the order is fixed and the key is **never** destroyed:

```bash
gcloud scheduler jobs delete eve-gate-poll --project="$EVE_PROJECT" --location="$REGION"
gcloud run jobs delete eve-gate --project="$EVE_PROJECT" --region="$REGION"
gcloud kms keys versions disable 1 --key=eve-approval --keyring="$EVE_KEYRING_NAME" --location="$REGION" --project="$EVE_PROJECT"
sitting_end
```

  Every L4 step then stalls **closed**: plans sit at `pending_eve`, `eve_silence` sets `no_autonomous` after four business hours, and only an operator clears it. If the reason is a suspected compromise rather than a defect, revoking `run.invoker` from `eve-controller@` is the faster containment step and is done first.
- **VERIFY:** `sitting_end` prints `SITTING-END OK`. After a rollback: the key version reads `DISABLED`, never `DESTROY_SCHEDULED`; `GET /v1/ladder` reports the halt; and the archived PEM is untouched, so every approval signed before the rollback stays verifiable.
- **ROLLBACK:** Re-enabling the version is a dated decision of the Eve owner, not a step.
- **EVIDENCE:** `${R}-10.3-sitting-end-v1.txt`. E-13. TISAX 1.4.1.

## 11. What to confirm before each irreversible step

| Step | What it does | Confirm first | Who confirms |
|---|---|---|---|
| `E3-4.2` | Creates `eve-approval` in a ring that can never be deleted, under a name that can never be reused | `E3-3.5` says "S4 entry may begin"; the **values** of `EVE_KEYRING`, `EVE_KEYRING_NAME` and `REGION` are echoed and read aloud; the algorithm is the one `walle-actions` implements; the four flags are read aloud from the command before it is run; after the create, the poll has printed `ENABLED` before any readback | Security reviewer countersigns the build-log line |
| `E3-4.3` | Writes the PEM into a bucket whose retention policy is **locked**: the object can be neither deleted nor replaced for `EVIDENCE_RETENTION_DAYS` | `EVE_APPROVAL_V1_STATE` is `ENABLED` and the live state agrees; the file begins `-----BEGIN PUBLIC KEY-----`; its digest equals the live key's, file against file; the object name carries the version number; `jq -e '.retention_policy.isLocked == true'` passed at `E3-1.5` | Security reviewer watches the digest comparison |
| `E3-8.2`, `E3-8.3` | The only path that could ever destroy a version | The tool refuses on all three rules; the proof runs against a **twin** key, never `eve-approval` | Eve owner runs; security reviewer watches |

Nothing else here is irreversible. The signer binding, the receipts grants, `eve-gate` and the scheduler can all be removed, and removing any of them fails closed.

## 12. Verification checklist for the whole part

- [ ] `E3-0.1` to `E3-0.4`: inputs complete; every decision signed, including E-18 with a measured window; the blind grader named and not the ladder owner; the three separation pairs distinct.
- [ ] `E3-1.1`: four scheduler jobs enabled with recent attempts; every Workspace stream non-zero and inside its lag budget; no open severity 1.
- [ ] `E3-1.2`: four Eve accounts enabled; `READER` on `walle_audit` for exactly three; invoker lists exact on both action services; nine mirror tables.
- [ ] `E3-1.3`: `aiplatform` denied, not enabled, no role bound, and the deliberate enable **refused**.
- [ ] `E3-1.4`: `review_queue_blind` carries no verdict or reason column; grades run continuously from S1.
- [ ] `E3-1.5`: the evidence bucket's retention policy is **locked** (`jq -e` on `retention_policy.isLocked`, not a blank projection) and its period equals `EVIDENCE_RETENTION_DAYS`; `eve/config` needs two reviewers; the validator runs.
- [ ] `E3-2.1` to `E3-2.3`: the two classes agreed and committed; the merge has two human approvers; the jobs run the new digest, read at `template.template.containers[0].image` with four `DIGEST` lines; the witness fingerprint alarm fired and was acknowledged.
- [ ] `E3-2.4`: one invariant halt, one demote **downwards only**, one page delivered, one operator clear — all timed and recorded.
- [ ] `E3-2.5`: a rate-based rule wrote a finding, raised no incident, halted nothing.
- [ ] `E3-3.1`: thirty days of verdicts with real L3 batch executions in the same window.
- [ ] `E3-3.2`: **twelve of twelve** caught, each with its required reason code.
- [ ] `E3-3.3`: both negative controls silent.
- [ ] `E3-3.4`: agreement reported as a Wilson bound and marked informational.
- [ ] `E3-3.5`: the S3 exit record signed by the Eve owner and the security reviewer, copied to the witness, before §4 opened.
- [ ] `E3-4.1`: the grant's approver is the Eve owner and is not the requester.
- [ ] `E3-4.2`: the poll saw `PENDING_GENERATION` become `ENABLED`; `ASYMMETRIC_SIGN`, `EC_SIGN_P256_SHA256`, `HSM`, `2592000s`, one `ENABLED` version; the ring addressed as `EVE_KEYRING_NAME`.
- [ ] `E3-4.3` to `E3-4.5`: **three identical digests, all taken from files**; the object under a locked policy; the `keys/` condition names the bucket derived from `EVE_EVIDENCE_BUCKET`; the Wall-E merge with two approvers **before** any signature; three bucket grants and no `objectAdmin`.
- [ ] `E3-5.1` to `E3-5.3`: bindings unchanged, etag carried, `DATA_READ` on Cloud KMS in force while the key policy still had **zero** bindings.
- [ ] `E3-5.4` to `E3-5.6`: one signer, `eve-controller@`; no `signerVerifier`, no `cryptoOperator`; the ring policy empty; the grant `REVOKED`.
- [ ] `E3-5.7`: seven lines — `CANNOT_ACCESS` on `useToSign` for six principals, `CAN_ACCESS` for one — against a resource name built from `EVE_KEYRING`, and no `UNKNOWN_*` left unresolved.
- [ ] `E3-5.8`: no `tokenCreator`, no standing human `actAs`, no impersonation path to `useToSign`.
- [ ] `E3-5.9`: no standing `cloudkms.admin`, `owner` or `editor` on `EVE_PROJECT`.
- [ ] `E3-6.*`: BLOCKED on **B-19**, each with its own line and the gate it holds; `EVE_GATE_URL` is `*tbd*` until they clear; §7.1 to §7.4 were run **before** §6 and `E3-6.2`'s `need EVE_RECEIPTS_DS` passed.
- [ ] `E3-7.1` to `E3-7.4`: receipts dataset in `EU` with the `europe` key; the view's columns exactly `['run_id','item','verdict_ts']`; the `verdicts` partition field still `ts`; the read-back diff matches; `walle-actions@` holds nothing on `eve`.
- [ ] `E3-7.5`: `mo-metrics@` reads exactly two Eve datasets; the `eve` filter prints `[]`; the drift job passes with the new entry.
- [ ] `E3-7.6`: every SQL file resolved to exactly one transfer config by `displayName` (an `UPDATED` line each, no `STOP`); every updated config still owned by `eve-v0@`, still off the hour, with the committed query text; nothing dropped.
- [ ] `E3-8.1`: decision **E-21** signed; no page still names the retired flag.
- [ ] `E3-8.4`: three organisation policies in force and the key's own destroy duration `2592000s`.
- [ ] `E3-9.1` to `E3-9.5`: every suite row has a runner; EVE-3 proved by the identity itself; EVE-12 and EVE-22 proved by eleven Policy Troubleshooter legs, eight `CANNOT_ACCESS` and three `CAN_ACCESS`, with no grant opened and nothing impersonated; the first `eve_authority: binding` cell merged with two human approvals and the CI refusal observed.
- [ ] `E3-10.1` to `E3-10.3`: the S4-entry record signed and in the witness; three variables recorded; `BD-41-1` written; two consumed pending lines closed; `SITTING-END OK`.

## 13. What the next file needs from this one

| Needed by | What | Name |
|---|---|---|
| [42](42-gates-drills-and-evidence.md) | The S3-entry, S3-exit and S4-entry records, for the gate register | `${R}-1.6`, `${R}-3.5`, `${R}-10.1` |
| [42](42-gates-drills-and-evidence.md) | Four recurrences: the seeded-fault exercise monthly and on every config change; the four mechanical enforcements after every IAM change; the live halt-and-clear rehearsal quarterly; the annual key rotation | `DRILL_CALENDAR` rows of `E3-2.6` and `E3-8.6` |
| [42](42-gates-drills-and-evidence.md) | `BD-41-1`, to close when the factory imports the bucket policy | `DEVIATION_REGISTER` |
| [40](40-mo-after-stage-0.md) | That `mo-metrics@` reads the mirror from S4 and that `eve_quality` and the mirror are the **only** two Eve datasets Mo may read | `E3-7.5` |
| [16](16-register-and-shared-registry.md) | The ladder rule proved in production: the published artefact's commit equals a merged commit with two human approvals, and any level above it is severity 1 | `E3-9.5` |
| [03](03-decisions-and-people.md) | Decision **E-21** as a new row in the tracker at its next review | `decisions/<date>-eve-key-destruction-owner.md` |
| The Eve owner, standing | `EVE_KEY_VERSION` as the value every envelope and every `approvals` row must carry, because KMS signatures do not identify the key version used | `EVE_KEY_VERSION` |
| The witness | The three records and the PEM digest, so the authority to sign is recorded outside the line that uses it | `WITNESS_BUCKET` |

## 14. Review findings this file closes

| Id | Severity | Closed by |
|---|---|---|
| S036 | blocking | `E3-7.2` creates the view as `SELECT run_id, item, ts AS verdict_ts FROM eve.verdicts`. The `verdicts` table's `ts` column is **not** renamed — it is the partitioning field the table was created with and the name the LLD gives it — and the verify proves both: the view's three output names and the table's partition field. The steps that depend on the view (`E3-7.3`, `E3-7.4`, EVE-12 at `E3-9.3`) therefore have something to act on |
| S134 | major | The guard is given one owner by decision **E-21** at `E3-8.1`, and it is Eve's: `eve/tools/destroy_key_version.py`, refusing on three rules (bucket copy, committed copy, the 400-day horizon), with a three-case CI self-test at `E3-8.2` and a two-way proof against a **twin** key at `E3-8.3`. The dead `walle_setup.py teardown --destroy-key-versions --dry-run` verify is deleted and named in "not copied"; `E3-8.1` also corrects the five pages that still describe the flag as live. `E3-4.2` creates the key with an explicit `--destroy-scheduled-duration=30d`, `E3-8.4` reads back the three organisation policies behind it, and `E3-5.9` proves no principal holds standing `roles/cloudkms.admin` on ring `EVE_KEYRING` outside PAM |
| S137 | major | `E3-5.7` replaces the impersonation test with `gcloud policy-intelligence troubleshoot-policy iam` on the key resource for `cloudkms.cryptoKeyVersions.useToSign`, expecting `overallAccessState: CANNOT_ACCESS` for six principals and `CAN_ACCESS` for `eve-controller@` alone — which also covers inherited project and folder grants that a key-level `get-iam-policy` misses. The step says in terms that `serviceAccountTokenCreator` is never granted to make a test run, and the real `AsymmetricSign` denial (EVE-3) moves to `E3-9.2`, where `eve-verifier@`'s own job runs it and the denied Data Access entry is the evidence |
| S204 | minor | `E3-7.6` states the rule the superseded text got wrong — a DML config's destination lives inside its SQL, so `--target_dataset` moves nothing — and updates configs with `bq update --transfer_config --params='{"query":…}'` from committed files, verifying that `ownerInfo.email` is still `eve-v0@` and the schedule still off the hour. Nothing is dropped on the strength of one run: both destinations are compared per partition first, and the drop is a separate dated step. [36](36-wall-e-joins-to-eve-and-mo.md) had already removed the underlying defect by building the mirror in its own dataset with nine configs, so no retarget is needed here; the rule is written down so it is not reinvented |
| S205 | minor | §5's order is the fix: `E3-5.1` reads the policy fresh and keeps the etag; `E3-5.2` adds the Cloud KMS and IAP audit configuration, prints a **bindings diff that must be empty** before the write, and writes with the etag so a concurrent change fails with 409 rather than silently overwriting; `E3-5.3` proves `DATA_READ` is in force **while the key policy still has zero bindings**; only then does `E3-5.4` bind the signer. No signature can exist in an unlogged window, and no whole-policy write from a stale file can drop a binding |

**Deferred, with an owner:**

| Item | Why deferred | Owner | Where |
|---|---|---|---|
| **S129 — the `eve-advisor` reporting path (M10)**, and with it EVE-16 and EVE-17 | The whole build is gated on **P34**, which the register marks *proposed*, and on **P19**, open with legal. Following the procedures as written builds the control path and leaves the gated path unbuilt, which is what the HLD's gate requires; a one-path Eve is the stated interim state, not a defect. Building it now would create a project, an identity, a model access and a Model Armor floor for a duty nobody has yet authorised | Eve owner; DPO and legal for P19; platform owner for the factory call | A new section of this file, or its own file, written **when P34 is signed and P19 answered**. What it must contain, so that nothing has to be rediscovered: the factory verifier-project run for `EVE_ADVISOR_PROJECT` in `fld-controllers-prod`; `eve-advisor@` with `bigquery.jobUser` at home only; `aiplatform` enabled **there and nowhere else**, under the controllers' Model Armor floor (P84); `${EVE_ADVISOR_VIEWS_DS}` in `EVE_PROJECT` with authorised-view entries on `eve`, `eve_workspace_logs` and `eve_workspace_reports`, `READER` for `eve-advisor@` on the view dataset only and never on a source; `${EVE_ADVICE_DS}` with `dataEditor` for `eve-advisor@` alone; and the two denial tests — EVE-16 (the advisor writes nothing on the control path and calls no action service) and EVE-17 (no control-path identity reads `eve_advice`), the second as a CI assertion on the access list. Until then the advisor rows of the topology are marked "not buildable until P34 is signed" |
| The Firestore discovery read for `eve-gate` | Decision 44 has not named a resource-scoped form, and the per-database IAM Condition expression is unverified | Platform owner; Wall-E owner | `E3-6.5`, which records `PENDING` and uses the CC-33 list endpoint meanwhile — the form that grants nothing |
| Dropping the superseded destinations of `E3-7.6`'s configs | A drop on the strength of one comparison is how a window of evidence disappears | Eve owner | Its own dated step after a full retention period of agreement |
| Wiring the rate-based class to halt | The thresholds are measured but not yet trusted against a window that includes S4 traffic | Eve owner | The quarterly threshold review in [42](42-gates-drills-and-evidence.md), as a reviewed and versioned change |

## 15. What could not be verified on 2026-09-15

- **Whether a destroyed key version's public key stays retrievable.** Google's *Destroy and restore key versions* page is silent on it. That silence is the reason the archive exists; nothing in this file depends on the answer.
- **Whether `bq update --source` performs optimistic concurrency on a dataset's `etag`.** The bq reference does not say. `E3-7.3` and `E3-7.4` therefore read back and diff after every access-array write rather than relying on a conflict being raised, and the non-view access list is diffed before the write as well.
- **Whether `gcloud asset analyze-iam-policy` can be run with `--billing-project` pointing at `CICD_PROJECT` while the scope is `EVE_PROJECT` in this installed version.** `--billing-project` is a gcloud-wide flag, but the Cloud Asset API's quota-project behaviour for an analysis scoped elsewhere was not confirmed. `E3-5.8` names the fallback and requires the gap to be recorded if it is used.
- **The exact JSON path of the impersonation results in `analyze-iam-policy --analyze-service-account-impersonation`.** The reference documents the flag, not the response shape. `E3-5.8`'s `jq` expression is written against the documented `analysisResults` shape; if it returns nothing, the raw JSON is read by eye and the working expression is recorded for the next run rather than guessed.
- **Whether a pending `overallAccessState` of `UNKNOWN_CONDITIONAL` can arise on a key with no conditional bindings.** Not stated. `E3-5.7` treats any `UNKNOWN_*` as unresolved and repeats the read rather than reading it as a pass.
- **The minimum scheduled-destruction duration Cloud KMS accepts.** Secondary sources say 24 hours; Google's own page states only the 30-day default. Nothing here depends on the minimum: the constraint sets a 30-day floor and the key states 30 days explicitly.
- **Whether Cloud Scheduler's OAuth invocation of a Cloud Run job can be scoped narrowly enough to refuse anything but `:run`.** Not documented. `eve-controller@` holds `run.invoker` on its own job, which is the narrowest available form; the compensation is `--max-retries=0` and the single-task shape, so a repeated invocation cannot produce a second envelope for the same plan.
- **Whether the external validator of `eve/config` rejects a rule that is in the catalogue and in neither class.** Asserted by `E3-2.2`'s design and to be proved on the first deliberate bad branch; until that run, the count check in the script is the control and the gap is recorded.
- **Whether Policy Troubleshooter evaluates a BigQuery dataset's access entries (`READER`/`WRITER` in the dataset's `access[]` array) exactly as it evaluates IAM bindings.** Google's BigQuery troubleshooting page points at the troubleshooter with dataset and table resource names and `bigquery.tables.getData`, and BigQuery exposes dataset access as IAM, but the page does not say so in words. `E3-9.3` therefore carries three positive-control legs that must read `CAN_ACCESS` — a troubleshooter blind to dataset entries would fail those first — and names the live-query form (each principal's own workload) as the second leg.
- **How long an HSM asymmetric key version stays in `PENDING_GENERATION`.** The *Creating asymmetric keys* page states the states, not a duration. `E3-4.2`'s poll allows five minutes at ten-second intervals and stops on anything that is neither pending nor enabled; a version still pending after that is recorded and the sitting waits rather than the loop being lengthened blindly.
- **The exact JSON field names `gcloud storage buckets describe --format=json` renders for the retention policy in the installed version.** The *Use and lock retention policies* page shows `retention_policy` with `retentionPeriod` beneath it (top-level snake_case, nested camelCase) and the lock page shows `isLocked`; if the installed `gcloud` renders differently, `jq -e` fails loudly rather than printing a blank, and the operator reads the raw JSON and records the working path for the next run.

## 16. Sources read on 2026-09-15

- `gcloud kms keys create` (`--purpose=asymmetric-signing`; `--default-algorithm=ec-sign-p256-sha256`; `--protection-level` values with default `software`; `--destroy-scheduled-duration` "the amount of time that versions of the key should spend in the `DESTROY_SCHEDULED` state before transitioning to `DESTROYED`", `INTEGER[UNIT]`): https://docs.cloud.google.com/sdk/gcloud/reference/kms/keys/create
- `gcloud kms keys versions get-public-key` (`VERSION` positional, `--key`, `--keyring`, `--location`, `--output-file` "path to the output file to store public key"; without it the key "will be printed to stdout", which is why every digest here is taken from a file; `--public-key-format`): https://docs.cloud.google.com/sdk/gcloud/reference/kms/keys/versions/get-public-key
- Creating asymmetric keys, re-read 2026-09-16 ("When you first create the key, the initial key version has a state of Pending generation. When the state changes to Enabled, you can use the key."): https://docs.cloud.google.com/kms/docs/creating-asymmetric-keys
- `CryptoKeyVersionState` (`PENDING_GENERATION` "may not be used, enabled, disabled, or destroyed yet"; `GENERATION_FAILED`; `ENABLED`; `DISABLED`; `DESTROY_SCHEDULED`; `DESTROYED`), read 2026-09-16: https://docs.cloud.google.com/kms/docs/reference/rest/v1/projects.locations.keyRings.cryptoKeys.cryptoKeyVersions
- `gcloud kms keys versions describe` (`VERSION`, `--key`, `--keyring`, `--location`; "returns metadata for the given version", read with `--format='value(state)'`), read 2026-09-16: https://docs.cloud.google.com/sdk/gcloud/reference/kms/keys/versions/describe
- Use and lock retention policies (`gcloud storage buckets describe gs://BUCKET --format="default(retention_policy)"` printing `retention_policy:` with `effectiveTime` and `retentionPeriod`; `--lock-retention-period`), read 2026-09-16: https://docs.cloud.google.com/storage/docs/using-bucket-lock
- Uniform bucket-level access and Public access prevention (`--format="default(uniform_bucket_level_access)"`, `--format="default(public_access_prevention)"`), read 2026-09-16: https://docs.cloud.google.com/storage/docs/uniform-bucket-level-access and https://docs.cloud.google.com/storage/docs/using-public-access-prevention
- Cloud Run Admin API v2 `Job` (`template` is an `ExecutionTemplate`, whose `template` is a `TaskTemplate` with `containers[]`, `serviceAccount`, `maxRetries` — no `spec` wrapper), read 2026-09-16: https://docs.cloud.google.com/run/docs/reference/rest/v2/projects.locations.jobs
- Privileged Access Manager, request temporary elevated access (grant states `APPROVAL_AWAITED`, `SCHEDULED`, `ACTIVATING`, `ACTIVE`, `ACTIVATION_FAILED`, `DENIED`, `EXPIRED`, `REVOKING`, `REVOKED`, `ENDED`, `WITHDRAWING`, `WITHDRAWN`), read 2026-09-16: https://docs.cloud.google.com/iam/docs/pam-request-temporary-elevated-access
- Troubleshoot IAM permissions in BigQuery (dataset `//bigquery.googleapis.com/projects/PROJECT_ID/datasets/DATASET` and table `…/tables/TABLE` resource names; `bigquery.tables.getData`, `bigquery.jobs.create`, `bigquery.datasets.get`; "analyzes all relevant policies, memberships in Google Groups, and inheritance from parent resources"), read 2026-09-16: https://docs.cloud.google.com/bigquery/docs/troubleshoot-access-control
- Destroy and restore key versions (30-day default scheduled-destruction duration; restore inside the window; silent on a destroyed version's public key): https://docs.cloud.google.com/kms/docs/destroy-restore
- Control key version destruction (`constraints/cloudkms.disableBeforeDestroy`; `constraints/cloudkms.minimumDestroyScheduledDuration` as a floor against a duration "as low as 24 hours"): https://docs.cloud.google.com/kms/docs/control-key-destruction
- Organization policy constraints for Cloud KMS: https://docs.cloud.google.com/kms/docs/org-policy-constraints
- Cloud KMS audit logging (`AsymmetricSign` needs `cloudkms.cryptoKeyVersions.useToSign`, typed `DATA_READ`; `GetPublicKey` needs `viewPublicKey`, `DATA_READ`; Data Access logs must be enabled): https://docs.cloud.google.com/kms/docs/audit-logging
- Key rotation (no automatic rotation for asymmetric signing keys): https://docs.cloud.google.com/kms/docs/key-rotation
- Cloud KMS permissions and roles (`roles/cloudkms.signer`, `publicKeyViewer`, `signerVerifier`, `cryptoOperator` and which carry `useToSign`): https://docs.cloud.google.com/kms/docs/reference/permissions-and-roles
- `gcloud policy-intelligence troubleshoot-policy iam` (`RESOURCE --principal-email --permission`; full resource-name form): https://docs.cloud.google.com/sdk/gcloud/reference/policy-intelligence/troubleshoot-policy/iam
- Troubleshoot IAM permissions and `iam.troubleshoot` (`overallAccessState`: `CAN_ACCESS`, `CANNOT_ACCESS`, `UNKNOWN_INFO`, `UNKNOWN_CONDITIONAL`): https://docs.cloud.google.com/policy-intelligence/docs/troubleshoot-access and https://docs.cloud.google.com/policy-intelligence/docs/reference/policytroubleshooter/rest/v3beta/iam/troubleshoot
- `gcloud asset analyze-iam-policy` (`--organization|--folder|--project`, `--full-resource-name`, `--identity`, `--permissions`, `--roles`, `--analyze-service-account-impersonation`, `--expand-groups`): https://docs.cloud.google.com/sdk/gcloud/reference/asset/analyze-iam-policy
- Understanding allow policies (the `etag` as optimistic concurrency control; a stale etag returns HTTP 409; include the etag whenever conditions are used): https://docs.cloud.google.com/iam/docs/allow-policies
- Service account permissions and Use service account impersonation (`getAccessToken` is carried by `roles/iam.serviceAccountTokenCreator`, needed "even if you have the Owner role"; `actAs` is `roles/iam.serviceAccountUser`): https://docs.cloud.google.com/iam/docs/service-account-permissions
- BigQuery authorized views ("This must be a different dataset than the dataset used in the source query"; "the source data dataset and authorized view dataset must be in the same regional location"; `dataViewer` on the view's dataset and no permission on the source; Sharing → Authorize views): https://docs.cloud.google.com/bigquery/docs/authorized-views
- Scheduling queries (update with `bq update --transfer_config`; `--params='{"query":…}'` changes the query text; `--target_dataset`, `--display_name`, `--schedule`, `--service_account_name`, `--update_credentials`; scheduled queries run as the creating user unless `--service_account_name` is given; queries on the hour may trigger more than once): https://docs.cloud.google.com/bigquery/docs/scheduling-queries
- bq command-line tool reference (`mk --view`, `--use_legacy_sql`, `show --transfer_config`, `update --source`): https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference
- BigQuery customer-managed encryption ("a dataset in region `EU` should be protected with a key ring from region `europe`"): https://docs.cloud.google.com/bigquery/docs/customer-managed-encryption
- `gcloud run jobs deploy` (`--image`, `--service-account`, `--args`, `--tasks`, `--max-retries` "per-task, not per-job", `--task-timeout`, `--set-env-vars`, `--set-secrets`): https://docs.cloud.google.com/sdk/gcloud/reference/run/jobs/deploy
- Run jobs on a schedule (`POST https://run.googleapis.com/v2/projects/PROJECT/locations/REGION/jobs/JOB:run` with `--oauth-service-account-email`; OAuth, not OIDC): https://docs.cloud.google.com/run/docs/execute/jobs-on-schedule
- Bucket Lock and Object Retention Lock (a locked retention policy cannot be removed or shortened; objects cannot be deleted or replaced before expiry; locking applies a lien preventing project deletion; per-object retention cannot be enabled from the command line on an existing bucket): https://docs.cloud.google.com/storage/docs/bucket-lock and https://docs.cloud.google.com/storage/docs/object-lock
- Create and validate signatures (DER-encoded EC signature; signatures do not identify the key version used): https://docs.cloud.google.com/kms/docs/create-validate-signatures

## Related

- [README.md](README.md) — the entry point, the BLOCKED index (**B-19**) and the re-run index
- [28](28-eve-independent-proof-and-sandbox-drills.md) — `EVE_H_LIVE_RECORD`, and the monthly blind proof this file keeps running
- [36](36-wall-e-joins-to-eve-and-mo.md) — `eve-controller@`, the mirror, the invoker bindings and the halt path this file switches on
- [39](39-wall-e-stage-0.md) — Stage 0, without which there is nothing at S3 to observe
- [40](40-mo-after-stage-0.md) — Mo's side of the S4 carve-out
- [42](42-gates-drills-and-evidence.md) — where the three records, the four recurrences and `BD-41-1` are consolidated
- [../../eve/05-stages.md](../../eve/05-stages.md) — the two authorities on opposite schedules, and the S4-entry control list
- [../../eve/02-identity-and-auth.md](../../eve/02-identity-and-auth.md) — the signing-key table and the PEM archive rule
- [../../eve/07-build-runbook.md](../../eve/07-build-runbook.md) — **superseded** by this file for Phases 11 and 12
