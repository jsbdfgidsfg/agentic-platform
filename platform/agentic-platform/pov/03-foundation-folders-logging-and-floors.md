# POV 3. The platform foundation: roster, billing, the folder tree, core projects, keys, logging, floors and K7

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-17
- Last executed: never
- Step prefix: `PF`. Steps: 40. BLOCKED: PF-9.4 (the `k7-executor` job, B-04). PENDING by design: PF-10.2's drift and reconciliation line (B-02). IRREVERSIBLE: PF-1.7 (group label), PF-3.3 (tag keys), PF-4.1 (project ids), PF-4.3 (key rings and the HSM key name), PF-6.2 and PF-6.3 (bucket and dataset names, locations, CMEK), PF-6.6 (log bucket locks), PF-7.1 and PF-7.2 (evidence bucket name, location and lock), PF-7.4 (SCC residency choice), PF-10.3 (withdrawal of the bootstrap exception).
- Stage: POV-1, week 1 to week 2. Hands-on about 3 person-days; elapsed about 1.5 to 2 weeks, because a new security key may take up to 7 days to work at sign-in, the allow-list dry run on empty folders lasts at least 7 days (PF-5.3), and the first shared Workspace logs take up to 24 hours. `Assumption:` all three figures. Part 6 does not start before PV-08, SD-11 and PV-10 are signed, and PF-1.5 action 4 and PF-2.2 wait for the `G3-ROSTER` and `ORG-CREATOR-DEFAULTS` records (Preconditions), so either can lengthen the elapsed time.
- Gates in this file stop: every gated block is a function whose first line returns on an unsigned record (see the note at the head of Steps).
- Full-set counterparts, for depth: [setup/06](../setup/06-organisation-bootstrap-and-roster.md), [07](../setup/07-billing-account.md), [09](../setup/09-folders-and-security-command-center.md), [10](../setup/10-core-projects-and-ci-identities.md), [11](../setup/11-keys-and-validator-custodian.md), [12](../setup/12-privileged-access-catalogue.md), [13](../setup/13-organisation-policies-deny-and-pab.md), [14](../setup/14-central-logging-and-billing-export.md), [17](../setup/17-factory-module-equivalents-and-tier-r-gate.md), [18](../setup/18-model-armor-floor-spikes-and-kill-switch.md), and [42](../setup/42-gates-drills-and-evidence.md) §3 for the evidence bucket.
- Deviations used: PV-D-01, PV-D-02, PV-D-03, PV-D-10, PV-D-12, PV-D-14, all written out in [09](09-the-demonstration-deviations-and-the-hand-over.md).

## What this part builds

Everything below is the full build's artefact with the full build's name. Nothing here is torn down when the full build starts; the full set's files 06 to 18 re-read what this file made and continue.

| Built | Where | Variables set here |
|---|---|---|
| The human super-admin roster: `ADMIN_OU`, `sa-1-admin@` and `sa-2-admin@` (both Super Admin, two keys each, sealed backup codes), daily accounts demoted, the G3 reduction, interim activity rules | Workspace tenant | `ORG_ID`, `DIRECTORY_CUSTOMER_ID`, `DOMAIN`, `WORKSPACE_EDITION`, `OWNER_DAILY_ACCOUNT`, `ADMIN_OU`, `SA_1_ADMIN`, `SA_2_ADMIN` |
| Break-glass: `BREAK_GLASS_OU`, `brk-gcp-1@`, `brk-gcp-2@`, `gcp-organization-admins@` | Workspace, organisation | `BREAK_GLASS_OU`, `BRK_GCP_1`, `BRK_GCP_2` |
| The committed roster and control groups `platform-owners@`, `platform-security@`, `platform-approvers@`, `gcp-organization-admins@` | platform repository, Cloud Identity | `ROSTER_FILE`, `CONTROL_GROUPS_FILE`, `GRP_PLATFORM_OWNERS`, `GRP_PLATFORM_SECURITY`, `GRP_PLATFORM_APPROVERS`, `GRP_GCP_ORG_ADMINS` |
| The dated organisation exception (SD-01), domain-wide creator defaults removed | organisation IAM | `BOOTSTRAP_EXCEPTION_EXPIRY` |
| The dedicated EUR billing account, bootstrap roles, a budget per project | billing | `BILLING_ACCOUNT_ID`, `BILLING_CURRENCY` |
| The **whole** folder tree of [02 §2.1](../02-landing-zone-and-tiers.md): 22 folders including the empty `fld-agents-p-sa-prod`, `fld-agents-p-sa-nonprod` and `fld-agents-x` | organisation; `register/folders.yaml` in the repository (PF-3.1a) | `FLD_AGENTIC_PLATFORM` and the 21 other `FLD_*` ids |
| Tag keys `agp-tier`, `agp-env`, `agp-tisax-scope`, their values and bindings | organisation, folders | `TAG_KEY_TIER`, `TAG_KEY_ENV`, `TAG_KEY_TISAX` |
| Five core projects, `AR_PLATFORM`, `factory-apply@` as an identity only | `fld-platform-core` | `CICD_PROJECT`, `CORE_PROJECT`, `LOGGING_PROJECT`, `KMS_PROJECT`, `VALIDATOR_PROJECT` and each `_NUMBER`, `AR_PLATFORM`, `SA_FACTORY_APPLY` |
| Key rings `logging`, `engines`, `gemini` (in `europe`), `supply-chain`; the HSM key `platform-logs-europe-west1` | `KMS_PROJECT`, `CICD_PROJECT` | `KR_LOGGING`, `KR_ENGINES`, `KR_GEMINI`, `KR_SUPPLY_CHAIN`, `KEY_PLATFORM_LOGS` |
| A PAM catalogue subset; organisation policies; `deny-agents-platform`; `pab-agents` with no binding | organisation, folders | `PAM_ENTITLEMENTS`, `ENT_PLATFORM_POLICY`, `ENT_ORG_SINK`, `ENT_K7_HUMAN`, `ENT_K7_HUMAN_SCHEDULER`, `ENT_FOLDER_ADMIN`, `ENT_PROJECT_REPAIR_CORE`, `ENT_PAM_CATALOGUE_ORG`, `DENY_AGENTS_PLATFORM`, `PAB_AGENTS` |
| Workspace data sharing on, the arriving streams read, the edition limits recorded | Admin console, organisation logs | `WS_SHARING_RECORD` |
| Central logging: `platform-evidence-logs`, `platform-identity-logs`, `platform_logs`, `platform_logs_views`, fan-out sinks, `S-org`, `S-folder` | `LOGGING_PROJECT`, organisation, `fld-agentic-platform` | `LOG_BUCKET_EVIDENCE`, `LOG_BUCKET_IDENTITY`, `PLATFORM_LOGS_DS`, `PLATFORM_LOGS_VIEWS_DS`, `SINK_S_ORG`, `SINK_S_FOLDER` |
| `PLATFORM_EVIDENCE_BUCKET`, locked with the second person present | `LOGGING_PROJECT` | `PLATFORM_EVIDENCE_BUCKET` |
| Two notification channels | `CORE_PROJECT` | `NOTIF_CH_PAGER_CORE`, `NOTIF_CH_EMAIL_CORE` |
| SCC Standard with `eu` residency; the Premium gate row left open | organisation | `SCC_TIER` (the tier record is registered with `evidence_add`, not held in a variable) |
| Model Armor floors on the platform and tier folders, and the committed floor rule | folders, repository | `FLOOR_RECORD` |
| K7 lever files, the human entitlement, a drill; `gates/` | repository, nonprod tier folders | `K7_POLICY_DIR`, `POV_K7_FIRST_DRILL_RECORD`, `GATES_DIR` |

### The full-set names this file uses, never a POV shorthand

The variables file is shared with the full build, and `penv_set` writes a name once, so a POV-only spelling would leave the full build's `need` failing on its own name. This file therefore sets the **full-set name** wherever [setup/README.md §5.2](../setup/README.md) already has one, and never the shorthand in the left-hand column (README §7.2). The later POV files read these names.

| Old POV name | Name set here | Why |
|---|---|---|
| `CUSTOMER_ID` | `DIRECTORY_CUSTOMER_ID` | `CUSTOMER_ID` is a retired name, and `penv_set` refuses it ([setup/01](../setup/01-prerequisites-and-conventions.md) helper table) |
| `TAG_AGP_TIER`, `TAG_AGP_TISAX_SCOPE` | `TAG_KEY_TIER`, `TAG_KEY_TISAX` (plus `TAG_KEY_ENV`) | setup/09 FS-5.1 |
| `KEYRING_LOGGING`, `KEYRING_GEMINI`, `KEYRING_ENGINES` | `KR_LOGGING`, `KR_GEMINI`, `KR_ENGINES` | setup/11 KV-2.1, KV-4.1, KV-3.1 |
| `KEYRING_SUPPLY_CHAIN` | `KR_SUPPLY_CHAIN` | setup/11 KV-5.1, which creates ring `supply-chain` in `CICD_PROJECT` and records `KR_SUPPLY_CHAIN` with the value this file sets, so the full build's `penv_set` prints it unchanged |
| `MA_FLOOR_RECORD` | `FLOOR_RECORD` | setup/18 KS-2.10 |
| `K7_FILES` | `K7_POLICY_DIR` | setup/18 KS-4.1 |
| `K7_DRILL_RECORD` | `POV_K7_FIRST_DRILL_RECORD` (README §7.3, not §7.2) | setup/18 KS-6.5 sets `K7_FIRST_DRILL_RECORD` for a drill with KF-1 under 60 s, the KF-2 hold probe and KF-4. PF-9.3 measures no refusal and skips KF-2 and KF-4, so its record must not satisfy setup/18:1085's `need` |
| `ENT_ORG_SINK` (listed with logging) | `ENT_ORG_SINK` is the PAM entitlement; the sinks are `SINK_S_ORG`, `SINK_S_FOLDER` | setup/12 PA-3.3, setup/14 CL-6.2, CL-6.3 |
| `SCC_TIER_RECORD` | `SCC_TIER` (the tier value); the PF-7.4 record is registered with `evidence_add`, and no second variable is kept | setup/09 FS-7.5 sets `SCC_TIER` |

## Preconditions

- [ ] [01](01-conventions-and-variables.md) is complete: `~/.platform-env` exists with `PLATFORM_ENV_FILE`, `PLATFORM_REPO_DIR`, `PLATFORM_REPO_REMOTE`, `BUILD_LOG_DIR`, `EVIDENCE_REGISTER`, `DEVIATION_REGISTER`, `DRILL_CALENDAR`, `EVIDENCE_INTERIM_LOCATION`, `REGION` (`europe-west1`), `BQ_LOCATION` (`EU`), `GCLOUD_CONFIG_NAME`, and the helpers `penv_set`, `need`, `exists_or_pending`, `penv_guard`, `checkpoint`, `evidence_add`, `confirm_manual` and `sitting_end`. `penv_guard` prints nothing.
- [ ] [02](02-decisions-people-and-the-retrospective-baseline.md) has signed, and `tools/decision-need.sh` prints `SIGNED` for: `PV-02`, `PV-03`, `PV-09`, `PV-11`, `NAMES`, `KEYS`, `SD-01` (with the exception's expiry date), `SD-16` (the billing-account record of 02 PD-4.2, carrying `BOOTSTRAP_BILLING_EXPIRY` as an absolute date). `SECOND_HUMAN_EMAIL`, `BILLING_ADMIN_EMAIL`, `INCIDENT_COMMANDER_EMAIL` and `DPO_CONTACT` are set.
- [ ] **Before Part 6 (blocking), the personal-data gate:** `decision-need.sh PV-08 SD-11 PV-10` prints three `SIGNED` lines (02 PD-5.1 and PD-5.2), and `EVIDENCE_RETENTION_DAYS`, `IDENTITY_RETENTION_DAYS` and `RECORD_RETENTION_DAYS` are integers. Part 6 switches on Workspace data sharing and routes every employee's Login, SAML and OAuth-token Data Access entries into `platform-identity-logs` and organisation-level entries into `platform_logs`: the densest store of real employees' personal data in the build. It is never created before the DPO has signed the monitoring record and the retention values, and its retention is read from PV-10, never typed. This mirrors setup/14's own gate (`decision-need.sh NAMES KEYS SD-11 SD-16 SD-18 SD-40`). Parts 1 to 5 may run while PV-10 is still `*tbd*`.
- [ ] **Two production-tenant change records that 02 does not yet produce (gap, WAITING):**
  - `G3-ROSTER`: every current super admin other than `sa-1-admin@` and `sa-2-admin@`, **named by role**, each with the delegated role they move to, their line manager or change board, the notice date, and any hand-over exception with its expiry; signed by IT security (setup/06 preconditions and OB-1.6). 02 line 112 says "G3-ROSTER ... is signed in 03", but no step of 02 or 03 drafts or signs it. It must be added to 02 as a PD step and to [README](README.md) §5.1 (day one) and §9 (decision tracker) by the owner of those files. PF-1.5 action 4 refuses without it.
  - `ORG-CREATOR-DEFAULTS`: the change record for removing the domain-wide Project Creator and Billing Account Creator from the whole organisation (setup/06 OB-3.4 to OB-3.6), naming the owners of existing organisation-level roles by role and carrying their written confirmations. It is a day-one dependency of the same kind and belongs in 02, README §5.1 and §9 alongside `G3-ROSTER`. PF-2.2 refuses without it.
  Until both exist, `checkpoint PF-1.5 PENDING - - "WAITING G3-ROSTER record (02)"` and `checkpoint PF-2.2 PENDING - - "WAITING ORG-CREATOR-DEFAULTS record (02)"`; Parts 3 to 5 do not depend on either.
- [ ] Six hardware security keys, with two spares for resealing, are in hand (ordered in file 02), plus four tamper-evident envelopes, a safe with a sign-out log, and a named envelope witness from the other administration line (the `PPL-EW` rule of setup/06 preconditions).
- [ ] The NAMES record carries the five core project ids and the evidence bucket name. **Every name below is permanent** ([setup/03 §8](../setup/03-decisions-and-people.md)). None of the names PV-02 reserves is created in this file, and no project is created in either `fld-agents-p-sa-*` folder.
- [ ] Two sittings with the second person, at least 8 calendar days apart (PF-1.4 and PF-1.5).

## People

| Role | Does | Present at |
|---|---|---|
| The operator (the platform owner; daily account until PF-1.5, then `sa-1-admin@`) | Runs every step. Never approves their own grant, never verifies their own evidence | every step |
| The second person (IT security; `sa-2-admin@`) | Creates and keys `sa-2-admin@` alone; custodian of `sa-1-admin@`'s spare key; **makes every Cloud IAM grant to `sa-1-admin@` under SD-01** (PF-2.1, PF-3.2, PF-3.3, PF-3.4), so the operator never grants to themselves, and signs `BD-P03-2`; runs the daily PAM Admin watch from PF-5.1 to PF-10.3; approves every PAM grant the operator requests; required reviewer on `identity/`, `logging/`, `k7/` and `model-armor/`; witness of every lock and of the enforced K7 drill; receives the interim rules about the operator | PF-1.3 to PF-1.7, PF-2.1, PF-5.2, PF-6.5, PF-6.6, PF-7.2, PF-8.1, PF-9.3, PF-10.3 |
| The third person (named in PV-09; second reviewer, and recipient of reports about the second person) | Second pull-request approval; recipient of interim rule B until the incident commander takes it | PF-1.3, PF-1.7 |
| The envelope witness (other administration line) | Signs every envelope record | PF-1.4, PF-1.5, PF-1.6 |
| The billing administrator | Confirms the billing account, grants the bootstrap billing roles | PF-2.3 |
| IT security (the P11 and SCC owner; may be the second person) | Confirms SCC's state and performs or witnesses its activation; owns the organisation Model Armor floor | PF-7.4, PF-8.1 |
| The data protection officer | Has signed PV-08, SD-11 and PV-10 in 02 before Part 6 starts; adds the residency exception to the records of processing | before PF-6.1; PF-6.1 evidence |
| IT security and the affected administrators' line managers or change board | Sign `G3-ROSTER` and `ORG-CREATOR-DEFAULTS` (Preconditions); the owners of organisation-level roles give written confirmations | before PF-1.5 and PF-2.2 |
| The organisation's Cloud Logging owner | Consents to Workspace sharing and reads Data Access streams with `roles/logging.privateLogViewer` | PF-6.1 |

A missing person is a checkpoint line `WAITING <role>`. The operator never stands in (PV-D-14 keeps the two-person rules intact).

## Steps

Every step opens with `checkpoint <id> START` and closes with `checkpoint <id> DONE <witness> <evidence>`. Every gcloud command passes `--project`, `--folder`, `--organization` or a full resource name; none carries `--quiet` or `--yes`.

**Gates stop; they do not warn.** A bare `decision-need.sh` line, or `|| echo "STOP"`, inside a pasted block exits 1 and lets the next line run anyway, which would spend an irreversible name on an unsigned record. So every gated ACTION block in this file is written as a shell function named after its step and called at once, and its gate is its first line:

```bash
pf_x_y() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" NAMES KEYS || { echo "STOP PF-x.y: record unsigned" >&2; return 1; }
  # ... the step's commands ...
}; pf_x_y
```

`return 1` leaves the function before any later line; variables set by `penv_set` inside it persist in the shell. A value comparison stops the same way: `[ a = b ] || { echo "STOP: ..." >&2; return 1; }`. A value is read from a record in the two-step form of setup/01 (`v=$(decision-value.sh ID NAME) && [ -n "$v" ] || return 1`), never inline inside `penv_set`, because `decision-value.sh` prints nothing on failure and `penv_set` would write the empty value once and for all.

### Part 1: The roster (compresses setup/06)

### PF-1.1 Preflight and the tenant identifiers

- **WHO:** The operator.
- **WHERE:** Shell, `~/.platform-env` sourced; Admin console > Account > Account settings (the customer ID); Cloud console organisation selector.
- **ACTION:**

```bash
pf_1_1() {
  checkpoint PF-1.1 START
  penv_guard || { echo "STOP PF-1.1: a default gcloud project is set" >&2; return 1; }
  echo "guard clean"
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-02 PV-03 PV-09 PV-11 NAMES KEYS SD-01 || { echo "STOP PF-1.1: records unsigned" >&2; return 1; }
  penv_set DOMAIN "<primary domain, read from Account settings>"
  penv_set DIRECTORY_CUSTOMER_ID "<customer ID, read from Account settings>"
  penv_set WORKSPACE_EDITION "<edition, read from Billing > Subscriptions>"
  penv_set OWNER_DAILY_ACCOUNT "<the operator's daily address>"
  o="$(gcloud organizations list --filter="displayName=${DOMAIN}" --format='value(name.basename())')"
  case "$o" in ''|*[!0-9]*) echo "STOP PF-1.1: organisation id not found or not digits" >&2; return 1;; esac
  penv_set ORG_ID "$o"
  need DOMAIN DIRECTORY_CUSTOMER_ID WORKSPACE_EDITION OWNER_DAILY_ACCOUNT ORG_ID SECOND_HUMAN_EMAIL INCIDENT_COMMANDER_EMAIL || return 1
}; pf_1_1
```

  Replace each `<...>` by the value read on screen before running; `penv_set` refuses a placeholder at the next `need`.
- **VERIFY:** `guard clean`; the decision tool prints `SIGNED` for every id; `need` prints nothing; `ORG_ID` is digits only. If the variable was already set by file 01, `penv_set` prints `unchanged`.
- **ROLLBACK:** `penv_set --force NAME ""` with a build-log line, only for a mistyped value.
- **EVIDENCE:** Build-log line `PF-1.1` with the decision tool's output. E-05. TISAX 1.1.

### PF-1.2 Read-only inventory: super admins, admin-role holders, domain-wide delegation

- **WHO:** The operator as super admin; the second person reads the result.
- **WHERE:** Admin console > Account > Admin roles; Security > Access and data control > API controls > Manage domain-wide delegation ([setup/06 OB-1.3, OB-1.4](../setup/06-organisation-bootstrap-and-roster.md)).
- **ACTION:** Nothing is changed. Record every Super Admin and every holder of another admin role, and **every domain-wide delegation client with its scopes**. Record the current values of super-admin self-recovery and multi-party approval without changing them (SD-30). Save as `records/<date>-PF-1.2-inventory-v1.md`.
- **VERIFY:** The second person signs the record. Absolute 1 is read here: the record lists every existing delegation client by client id. None of them belongs to the platform, and none ever will; any new client appearing later is a finding for Eve (file 06).
- **ROLLBACK:** Read only.
- **EVIDENCE:** `evidence_add PF-1.2 inventory E-08 4.2.1 "build-log:records/<file>"`. TISAX 4.2.1.

### PF-1.3 `ADMIN_OU`, its 2-Step Verification and sessions, and the interim rules

- **WHO:** The operator as super admin; the second person watches the rules being saved and receives the test mail.
- **WHERE:** Admin console > Directory > Organizational units; Security > Authentication > 2-step verification; Security > Access and data control > Google session control and Google Cloud session control; Rules > Create rule > Activity. Paths verified by setup/06 OB-2.1 to OB-2.6 against Google's pages updated 2026-09-10.
- **ACTION:**
  1. Create `/Admins`; License settings: Workspace subscription Off (Cloud Identity Free only; add that subscription first if absent, OB-2.0).
  2. On `Admins`: enforcement On, method **Only security key**, trust device off, security codes not allowed, enrolment period at least 8 days.
  3. On `Admins`: shortest web session offered; Google Cloud reauthentication every 1 hour with security key.
  4. Rule A: User log events, actor `sa-1-admin@` (later also the break-glass accounts), email to `SECOND_HUMAN_EMAIL` only. Rule B: actor `sa-2-admin@`, email to `INCIDENT_COMMANDER_EMAIL` (or the third person once PV-09 names that route). Rule C: Admin log events, role assignment events, email to both.

```bash
penv_set ADMIN_OU "/Admins"
```

- **VERIFY:** The pages, re-opened on `Admins`, show the values; the top organisational unit is unchanged. Rules A, B and C are listed. They are proven in PF-1.4 and PF-1.5.
- **ROLLBACK:** Inherit on each page; delete the empty OU and the rules. **Only the second person may retire the rules, never before `POV_EVE_H_LIVE_RECORD`** (file 06).
- **EVIDENCE:** Screenshots as `<date>-PF-1.3-admin-ou-v1` in `EVIDENCE_INTERIM_LOCATION`. E-08. TISAX 4.1.2.

### PF-1.4 First sitting: the two admin accounts, their keys, sealed codes and Super Admin

- **WHO:** The operator creates both accounts; **the second person sets `sa-2-admin@`'s password alone**, the operator not looking; the envelope witness signs each envelope; the second person is present throughout.
- **WHERE:** Admin console > Directory > Users > Add new user; each account's clean browser profile; Google Account > Security > 2-Step Verification; Directory > Users > user > Security > Get backup verification codes; Account > Admin roles > Super Admin.
- **ACTION:** First, before any account is created:

```bash
pf_1_4_gate() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-09 SD-01 || { echo "STOP PF-1.4: PV-09 or SD-01 unsigned" >&2; return 1; }
  checkpoint PF-1.4 START "$SECOND_HUMAN_EMAIL" - "first sitting: admin accounts"
}; pf_1_4_gate
```

  Then, as setup/06 OB-2.4 to OB-2.10a, in that order, with nothing removed:
  1. Create `sa-1-admin@` and `sa-2-admin@` in `/Admins`, no recovery email or phone, no Workspace licence, vault-generated passwords set at first sign-in by each holder.
  2. Enrol two keys on each (labels `sa-1 primary`, `sa-1 spare`, `sa-2 primary`, `sa-2 spare`); serials on paper only.
  3. Generate backup codes for each account, copy them by hand, seal them with the spare key. Custodian of `sa-1-admin@`'s envelope: the second person. Custodian of `sa-2-admin@`'s: someone outside the operator's line, never the operator. Scan the outer custody record only, the same day.
  4. Assign Super Admin to both. The second person, alone and in the operator's absence, regenerates `sa-2-admin@`'s codes and reseals as `v2`, so the monitored administrator does not hold both factors of the approver's account.

```bash
penv_set SA_1_ADMIN "sa-1-admin@${DOMAIN}"
penv_set SA_2_ADMIN "sa-2-admin@${DOMAIN}"
```

- **VERIFY:** Account > Admin roles > Super Admin lists both accounts; rule C mailed both recipients for each assignment; the safe log lists the envelopes with no generator who is also custodian; the `v2` custody scan exists. `DEV-06-03`'s shape of exposure is opened and closed the same day in `DEVIATION_REGISTER` as `BD-P03-1`.
- **ROLLBACK:** Unassign the role and delete the user; a mis-sealed envelope is regenerated as the next version, never overwritten.
- **EVIDENCE:** Custody scans and screenshots as `<date>-PF-1.4-admin-accounts-v1`. The custody records stay interim: no witness organisation exists to receive them (PV-D-03). E-08. TISAX 3.1, 4.1.2.

### PF-1.5 Second sitting, at least 7 days later: prove, demote the daily accounts, reduce

- **WHO:** The operator for `sa-1-admin@`, the second person for `sa-2-admin@`, each watching the other; each reduced super admin tests their new role.
- **WHERE:** Clean browser profiles; the APIs Explorer on `users.list`; Account > Admin roles.
- **ACTION:** Google: "You may need to wait 7 days before a newly added security key is available at sign-in" ([use a security key](https://support.google.com/accounts/answer/6103523), read 2026-09-16). The sitting opens with its gate; nothing below runs if it stops:

```bash
pf_1_5_gate() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" G3-ROSTER PV-09 SD-01 || { echo "STOP PF-1.5: G3-ROSTER, PV-09 or SD-01 unsigned (see Preconditions)" >&2; return 1; }
  checkpoint PF-1.5 START "$SECOND_HUMAN_EMAIL" - "second sitting: prove, demote, reduce"
}; pf_1_5_gate
```

  1. Sign in to each admin account with the primary key, then with the spare taken from its envelope in front of the witness; reseal as the next version.
  2. Run the two `users.list` queries of setup/06 OB-2.14 (`isAdmin=true`, then `isDelegatedAdmin=true`, `viewType=admin_view`) and paste each immediately after running it; run OB-2.14's guard and check script unchanged.
  3. Unassign Super Admin from `OWNER_DAILY_ACCOUNT` (and from the second person's daily account if it holds it).
  4. For every row `<n>` of the signed `G3-ROSTER` record, in the record's order, one row at a time: `checkpoint PF-1.5-<n> START "$SECOND_HUMAN_EMAIL" - "G3 row <n>: <role named in the record>"`; assign the delegated role; have the admin confirm a routine task; unassign Super Admin; `checkpoint PF-1.5-<n> DONE "$SECOND_HUMAN_EMAIL" <screenshot> "G3 row <n> reduced"`. A row that takes the hand-over exception instead closes as `checkpoint PF-1.5-<n> DONE ... "exception until <date>"`, with the exception signed by the second person.
  **Resume rule for a partly applied reduction:** an interrupted sitting resumes from `checkpoints.tsv`. A row with `DONE` is not touched again. A row with `START` and no `DONE` is re-read in Account > Admin roles before anything else: if the delegated role is assigned and Super Admin still held, continue from the admin's confirmation; if Super Admin is already removed but the delegated role is missing, assign the delegated role first, before any other row, because that administrator is locked out of their routine work. No new row starts while an earlier row is open. The sitting does not close with an open row; if it must, the second person records a dated hand-over exception for that row.
- **VERIFY:** OB-2.11's script prints `ADMIN ACCOUNTS PROVEN`; OB-2.14's prints `QUERIES DISTINCT` and `G3 STATE OK`; every other super admin has a signed, unexpired exception; `admin.google.com` no longer opens for the daily account; rules A, B and C fired; `awk -F'\t' '$2 ~ /^PF-1\.5-/' "$BUILD_LOG_DIR/checkpoints.tsv"` shows a `DONE` for every `START`, and the count of `PF-1.5-<n>` rows equals the `G3-ROSTER` record's row count.
- **ROLLBACK:** Re-assign Super Admin to a daily account only if both admin accounts fail, with a written reason. A G3 reversal needs a new signed IT security record (append-only; its Supersedes line names `G3-ROSTER`). Confirm first, before action 4: every administrator in the record has received the OB-1.6 notice, and each delegated role exists.
- **EVIDENCE:** The JSON files, script outputs and mails as `<date>-PF-1.5-roster-proven-v1`. E-08. TISAX 4.2.1.

### PF-1.6 Break-glass: the OU, the two accounts, their keys and standing roles

- **WHO:** The operator as `sa-1-admin@`; password custodian of `brk-gcp-1@` is the second person and of `brk-gcp-2@` the operator; key custodians crossed; the envelope witness.
- **WHERE:** Admin console as PF-1.3 and PF-1.4; shell for the roles.
- **ACTION:** As setup/06 OB-4.1 to OB-4.4 and OB-7.1 to OB-7.3: `/Automation/Break-Glass` with the `Admins` settings; two accounts with no licence, no recovery information and no admin role; one key each; both added to rule A; after the 7-day wait, each signs in with its key and the `users.list` check prints `BREAK-GLASS KEYS PROVEN`. Then, only after PF-1.7 has created `gcp-organization-admins@` with the two accounts as its only members:

```bash
pf_1_6() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-09 SD-01 || { echo "STOP PF-1.6: PV-09 or SD-01 unsigned" >&2; return 1; }
  need ORG_ID DOMAIN GRP_GCP_ORG_ADMINS || { echo "STOP PF-1.6: PF-1.7 has not created gcp-organization-admins@" >&2; return 1; }
  checkpoint PF-1.6 START "$SECOND_HUMAN_EMAIL" - "break-glass standing roles"
  penv_set BREAK_GLASS_OU "/Automation/Break-Glass"
  penv_set BRK_GCP_1 "brk-gcp-1@${DOMAIN}"
  penv_set BRK_GCP_2 "brk-gcp-2@${DOMAIN}"
  gcloud organizations add-iam-policy-binding "$ORG_ID" --member="group:$GRP_GCP_ORG_ADMINS" --role="roles/resourcemanager.organizationAdmin" --condition=None || return 1
  gcloud organizations add-iam-policy-binding "$ORG_ID" --member="group:$GRP_GCP_ORG_ADMINS" --role="roles/privilegedaccessmanager.admin" --condition=None
}; pf_1_6
```

- **VERIFY:** OB-7.1's check prints `BREAK-GLASS ROLES EXACT`; one break-glass account reaches the organisation's IAM page, its password is rotated, and its key is sealed with a cross-line custodian.
- **ROLLBACK:** `gcloud organizations remove-iam-policy-binding` with the same member, role and `--condition=None`; delete the users.
- **EVIDENCE:** As `<date>-PF-1.6-break-glass-v1`. E-08. TISAX 3.1, 4.2.1.

### PF-1.7 The roster file, the control-group list, and the groups

- **WHO:** The operator writes; **the second person is required reviewer** and the third person the second approval; the operator never merges.
- **WHERE:** `PLATFORM_REPO_DIR`, branch and pull request; then Cloud Identity groups.
- **ACTION:** Write `identity/super-admin-roster.json` with setup/06 OB-5.1's generator unchanged (its `expected_later` rows name robot addresses that later files create; nothing is created from them here). Write `identity/control-groups.yaml` for `gcp-organization-admins@`, `platform-owners@` (the operator's admin account), `platform-security@` (the second person), `platform-approvers@` (both admin accounts). `eve-owners@` is file 06's and `ge-admins@` file 05's. Merge, then create each group as a security group with members from the merged file:

```bash
pf_1_7() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" NAMES PV-09 || { echo "STOP PF-1.7: NAMES or PV-09 unsigned" >&2; return 1; }
  need ORG_ID DOMAIN || return 1
  checkpoint PF-1.7 START "$SECOND_HUMAN_EMAIL" - "control groups: security label permanent"
  penv_set ROSTER_FILE "identity/super-admin-roster.json"
  penv_set CONTROL_GROUPS_FILE "identity/control-groups.yaml"
  for g in gcp-organization-admins platform-owners platform-security platform-approvers; do
    gcloud identity groups create "${g}@${DOMAIN}" --organization="$ORG_ID" --group-type=security --with-initial-owner=empty --display-name="$g" --description="POV 03 PF-1.7; setup/06 control group" || return 1
  done
  penv_set GRP_GCP_ORG_ADMINS "gcp-organization-admins@${DOMAIN}"
  penv_set GRP_PLATFORM_OWNERS "platform-owners@${DOMAIN}"
  penv_set GRP_PLATFORM_SECURITY "platform-security@${DOMAIN}"
  penv_set GRP_PLATFORM_APPROVERS "platform-approvers@${DOMAIN}"
}; pf_1_7
```

  `--with-initial-owner=empty` is required: without it "the user making the request will be added as the initial owner of the group", which is the default for non-dynamic groups ([identity groups create](https://docs.cloud.google.com/sdk/gcloud/reference/identity/groups/create), updated 2026-05-27, read 2026-09-16). Otherwise the operator's `sa-1-admin@` would own `platform-security@`, `platform-approvers@` and `gcp-organization-admins@`, and OB-6.4's check could not print `GROUPS MATCH LIST`. `--group-type=security` is on the same page (values `discussion`, `dynamic`, `security`). Members are added with `gcloud identity groups memberships add --group-email --member-email` from the merged list only.
- **VERIFY:** OB-5.3's roster-against-tenant check passes; OB-6.4's check prints `GROUPS MATCH LIST`; `gcloud identity groups memberships list --group-email=<group>` on each of the four groups, read back by the second person, lists exactly the merged members and no `OWNER` role for any account not in the merged list; the pull request shows both approvals.
- **ROLLBACK:** **IRREVERSIBLE** as to the security label: a group's security label cannot be removed. Confirm first: the address is exactly as `CONTROL_GROUPS_FILE` at the merged commit, and the address is not already taken (OB-6.1). A wrong membership is corrected by a new merged list.
- **EVIDENCE:** Merge commit and check outputs as `<date>-PF-1.7-roster-and-groups-v1`. E-08. TISAX 4.2.1.

### Part 2: Organisation IAM and billing (compresses setup/06 Part 3 and setup/07)

### PF-2.1 The dated bootstrap exception

- **WHO:** **The second person, as `sa-2-admin@`, makes every grant to `sa-1-admin@`**; the operator watches and never grants to themselves. This keeps absolute 9 (the operator never approves their own grant) inside SD-01's dated exception.
- **WHERE:** Cloud console > IAM & Admin > IAM at the organisation, signed in as `sa-2-admin@`, for the first grant; the second person's shell (`~/.platform-env` sourced, `gcloud` authenticated as `sa-2-admin@`) for the rest.
- **ACTION:** As setup/06 OB-3.2, OB-3.3 and OB-3.7, with the granter changed: the expiry comes from the signed SD-01 record; one condition file; Organization Administrator granted in the console with that condition, then the three other roles. Google: "As a super admin, you can grant the Organization Administrator role to the appropriate user" ([super admin best practices](https://docs.cloud.google.com/resource-manager/docs/super-admin-best-practices), updated 2026-09-09, read 2026-09-16). If the console requires `sa-2-admin@` to hold Organization Administrator before it can grant, the second person takes it with a condition expiring at the end of this sitting, the operator watching, and removes it in this step's VERIFY (see Unverified).

```bash
pf_2_1() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" SD-01 || { echo "STOP PF-2.1: SD-01 unsigned" >&2; return 1; }
  checkpoint PF-2.1 START "$OWNER_DAILY_ACCOUNT" - "second person grants the dated exception to sa-1-admin@"
  v="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" SD-01 BOOTSTRAP_EXCEPTION_EXPIRY)" && [ -n "$v" ] || { echo "STOP PF-2.1: no expiry in SD-01" >&2; return 1; }
  penv_set BOOTSTRAP_EXCEPTION_EXPIRY "$v"
  [ "$(gcloud config get-value account 2>/dev/null)" = "$SA_2_ADMIN" ] || { echo "STOP PF-2.1: gcloud is not signed in as sa-2-admin@" >&2; return 1; }
  c="$PLATFORM_REPO_DIR/identity/bootstrap-exception-condition.yaml"
  printf 'expression: request.time < timestamp("%sT00:00:00Z")\ntitle: bootstrap-exception-sd-01\ndescription: SD-01 dated organisation exception for %s; withdrawn in POV 03 PF-10.3\n' "$BOOTSTRAP_EXCEPTION_EXPIRY" "$SA_1_ADMIN" > "$c"
  gcloud organizations add-iam-policy-binding "$ORG_ID" --member="user:$SA_1_ADMIN" --role="roles/resourcemanager.folderCreator" --condition-from-file="$c"
  gcloud organizations add-iam-policy-binding "$ORG_ID" --member="user:$SA_1_ADMIN" --role="roles/resourcemanager.projectCreator" --condition-from-file="$c"
  gcloud organizations add-iam-policy-binding "$ORG_ID" --member="user:$SA_1_ADMIN" --role="roles/privilegedaccessmanager.admin" --condition-from-file="$c"
}; pf_2_1
```

  No other role. `orgpolicy.policyAdmin`, `iam.denyAdmin`, `iam.principalAccessBoundaryAdmin` and `logging.configWriter` are never standing; they come from PAM in Part 5. The later time-bound grants of this file (`roles/logging.admin` in PF-3.2, Tag Administrator and Tag User in PF-3.3 and PF-3.4) are made the same way: **by the second person to `sa-1-admin@`**, conditioned, never by the operator to themselves.

  **The PAM Admin watch.** `roles/privilegedaccessmanager.admin` lets its holder edit any entitlement, including removing its approval workflow, so until PF-10.3 "the second person approves every PAM grant" would rest on the operator's restraint. From PF-5.1 until PF-10.3, the second person runs this read-only check at the start of each working day and before approving any grant, and records the output:

```bash
for s in "--organization=$ORG_ID" "--folder=$FLD_AGENTIC_PLATFORM" "--folder=$FLD_PLATFORM_CORE"; do
  gcloud logging read 'protoPayload.serviceName="privilegedaccessmanager.googleapis.com" AND (protoPayload.methodName="google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.UpdateEntitlement" OR protoPayload.methodName="google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.DeleteEntitlement")' "$s" --freshness=2d --format="table(timestamp,protoPayload.authenticationInfo.principalEmail,protoPayload.methodName,protoPayload.resourceName)"
done
```

  Both methods are Admin Activity entries of `privilegedaccessmanager.googleapis.com` ([PAM audit logging](https://docs.cloud.google.com/iam/docs/audit-logging/audit-logging-pam), updated 2026-09-16). Any row whose principal is `sa-1-admin@` and that has no merged pull request under `pam/` is an incident: the second person revokes the exception with PF-10.3's removal loop the same day and reports it to the third person. `Assumption:` a daily hand read, not an alert, because a log-based alerting policy is a project-level object ([log-based alerts](https://docs.cloud.google.com/logging/docs/alerting/log-based-alerts), updated 2026-09-09) and whether it fires on organisation- and folder-level entries routed in by `S-org` is not settled here; Eve (file 06) takes the watch over.
- **VERIFY:** OB-3.7's check prints `EXCEPTION EXACT`: four roles, each once, each carrying the condition. The Admin Activity entries for the four `SetIamPolicy` calls name `sa-2-admin@` as principal, never `sa-1-admin@`. If the second person took a sitting-long Organization Administrator, `gcloud organizations get-iam-policy "$ORG_ID" --flatten="bindings[].members" --filter="bindings.members:user:$SA_2_ADMIN" --format="value(bindings.role)"` prints nothing after its removal. `DEV-06-01`'s entry is written to `DEVIATION_REGISTER` as `BD-P03-2` with the expiry, PF-10.3 as the withdrawal step, the PAM Admin watch above, and **the second person's written acceptance of the exception and of the watch**, signed and dated in the row.
- **ROLLBACK:** The second person runs `gcloud organizations remove-iam-policy-binding` with the same member, role and `--condition-from-file`.
- **EVIDENCE:** Policy JSON, the audit entries naming the granter, and the signed `BD-P03-2` row as `<date>-PF-2.1-org-exception-v1`; the daily watch outputs as `<date>-PF-2.1-pam-watch-v<n>`. E-05. TISAX 1.4, 4.2.1.

### PF-2.2 Remove the domain-wide Project Creator and Billing Account Creator

- **WHO:** The operator; the second person present.
- **WHERE:** Shell.
- **ACTION:** As setup/06 OB-3.4 to OB-3.6, unchanged, because it is a production-tenant change with other owners: save the organisation policy, collect the owners' written confirmations between sittings, preview with Policy Simulator, then generate one `remove-iam-policy-binding ... --condition=None` per `domain:` binding from the saved policy, never typed from `$DOMAIN`. The removal sitting opens with its gate, and the generated commands run only inside it:

```bash
pf_2_2_gate() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" ORG-CREATOR-DEFAULTS SD-01 || { echo "STOP PF-2.2: ORG-CREATOR-DEFAULTS unsigned or owners' confirmations missing (see Preconditions)" >&2; return 1; }
  checkpoint PF-2.2 START "$SECOND_HUMAN_EMAIL" - "remove domain-wide Project Creator and Billing Account Creator"
}; pf_2_2_gate
```
- **VERIFY:** The after-policy has no `domain:` binding of either role; OB-3.5a's preview named every principal who lost access, each answered in the `ORG-CREATOR-DEFAULTS` record; every owner the record names by role has a written confirmation filed before the checkpoint `START`.
- **ROLLBACK:** OB-3.6's restore script generated from `OB-3.6-removed-domain-bindings.json`, under a new signed change record.
- **EVIDENCE:** Before and after JSON and the generated commands as `<date>-PF-2.2-defaults-removed-v1`. E-05. TISAX 4.2.1.

### PF-2.3 The dedicated EUR billing account and its bootstrap roles

- **WHO:** The billing administrator confirms and grants; the operator records.
- **WHERE:** Shell; Billing console.
- **ACTION:** As setup/07 BA-1.1 to BA-2.2: the account is standard, open, owned by the organisation and used by nothing else; the currency is read, never assumed.

```bash
penv_set BILLING_ACCOUNT_ID "<id confirmed by the billing administrator>"
pf_2_3() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" SD-16 || { echo "STOP PF-2.3: SD-16 (02 PD-4.2) unsigned" >&2; return 1; }
  checkpoint PF-2.3 START "$BILLING_ADMIN_EMAIL" - "billing account and bootstrap billing roles"
  BA_CUR="$(gcloud billing accounts describe "$BILLING_ACCOUNT_ID" --format='value(currencyCode)')"
  [ "$BA_CUR" = EUR ] || { echo "STOP PF-2.3: currency is $BA_CUR, not EUR; SD-16 requires a new account" >&2; return 1; }
  penv_set BILLING_CURRENCY EUR
  v="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" SD-16 BOOTSTRAP_BILLING_EXPIRY)" && [ -n "$v" ] || { echo "STOP PF-2.3: no BOOTSTRAP_BILLING_EXPIRY in the signed SD-16 record" >&2; return 1; }
  case "$v" in [0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]) ;; *) echo "STOP PF-2.3: expiry $v is not an absolute YYYY-MM-DD date" >&2; return 1;; esac
  [ "$v" \> "$(date -u +%Y-%m-%d)" ] || { echo "STOP PF-2.3: expiry $v is not after today" >&2; return 1; }
  penv_set BOOTSTRAP_BILLING_EXPIRY "$v"
}; pf_2_3
```

  `BOOTSTRAP_BILLING_EXPIRY` is read from the signed SD-16 record, never typed, as setup/07 BA-2.1 sets it. `Assumption:` 02 PD-4.2's billing-account record carries that name; if it does not, the function stops and the record is amended in 02, never filled in here. Only after the function prints no `STOP`, the billing administrator grants `roles/billing.user` and `roles/billing.costsManager` to `sa-1-admin@` on this account only, until `BOOTSTRAP_BILLING_EXPIRY`, and puts a reminder on that date (setup/07 BA-2.2); removal on that date is setup/07 BA-7.1, handed over.
- **VERIFY:** `BILLING_CURRENCY=EUR`; `BOOTSTRAP_BILLING_EXPIRY` equals `decision-value.sh SD-16 BOOTSTRAP_BILLING_EXPIRY` and is after today; `BILLING_ADMIN_EMAIL` differs from `SA_1_ADMIN`, `SA_2_ADMIN` and `OWNER_DAILY_ACCOUNT`; setup/07 BA-2.3's `testIamPermissions` returns the two permissions present and `billing.accounts.close` absent.
- **ROLLBACK:** The billing administrator removes the two bindings; `penv_set --force` for a wrong id before any link.
- **EVIDENCE:** As `<date>-PF-2.3-billing-account-v1`. E-05. TISAX 1.3.3.

### Part 3: The folder tree and the tags (compresses setup/09)

The whole tree is built, empty folders included. Folders cost nothing, and projects never move between tier folders ([02 §2.2](../02-landing-zone-and-tiers.md)), so a tier added later must find its folder already in place.

### PF-3.1 Create the 22 folders

- **WHO:** The operator (Folder Creator from PF-2.1).
- **WHERE:** Shell.
- **ACTION:** Paste setup/09 FS-1.1's `mkfld` helper unchanged. It looks up the display name first, so a resumed sitting never makes a duplicate. Then:

```bash
mkfld FLD_AGENTIC_PLATFORM fld-agentic-platform organization "$ORG_ID"
for p in "FLD_PLATFORM_CORE fld-platform-core" "FLD_GEMINI_ENTERPRISE fld-gemini-enterprise" "FLD_AGENTS_R fld-agents-r" "FLD_AGENTS_W fld-agents-w" "FLD_AGENTS_P fld-agents-p" "FLD_AGENTS_X fld-agents-x" "FLD_CONTROLLERS fld-controllers" "FLD_IMPROVERS fld-improvers"; do set -- $p; mkfld "$1" "$2" folder "$FLD_AGENTIC_PLATFORM"; done
for p in "FLD_AGENTS_R_PROD fld-agents-r-prod $FLD_AGENTS_R" "FLD_AGENTS_R_NONPROD fld-agents-r-nonprod $FLD_AGENTS_R" "FLD_AGENTS_W_PROD fld-agents-w-prod $FLD_AGENTS_W" "FLD_AGENTS_W_NONPROD fld-agents-w-nonprod $FLD_AGENTS_W" "FLD_AGENTS_P_PROD fld-agents-p-prod $FLD_AGENTS_P" "FLD_AGENTS_P_NONPROD fld-agents-p-nonprod $FLD_AGENTS_P" "FLD_AGENTS_P_SA fld-agents-p-sa $FLD_AGENTS_P" "FLD_CONTROLLERS_PROD fld-controllers-prod $FLD_CONTROLLERS" "FLD_CONTROLLERS_NONPROD fld-controllers-nonprod $FLD_CONTROLLERS" "FLD_IMPROVERS_PROD fld-improvers-prod $FLD_IMPROVERS" "FLD_IMPROVERS_NONPROD fld-improvers-nonprod $FLD_IMPROVERS"; do set -- $p; mkfld "$1" "$2" folder "$3"; done
mkfld FLD_AGENTS_P_SA_PROD fld-agents-p-sa-prod folder "$FLD_AGENTS_P_SA"
mkfld FLD_AGENTS_P_SA_NONPROD fld-agents-p-sa-nonprod folder "$FLD_AGENTS_P_SA"
```

- **VERIFY:** Run setup/09 FS-3.4's tree-diff script unchanged; it prints `zero diff: 22 folders, 0 projects`.
- **ROLLBACK:** An empty folder is deleted children first with `gcloud resource-manager folders delete <id>` under a time-bound Folder Admin; it stays soft-deleted for about 30 days.
- **EVIDENCE:** The diff output as `<date>-PF-3.1-tree-diff-v1`. Deviation row `BD-P03-3` (hand-built, not Terraform; PV-D-01). E-05. TISAX 1.3.1.

### PF-3.1a Generate and commit `register/folders.yaml`

- **WHO:** The operator generates and commits. Two reviewers named by CODEOWNERS approve, neither the operator: the second person and person 3 (PV-09).
- **WHERE:** Shell, in `PLATFORM_REPO_DIR`; then the git host.
- **ACTION:** Run [setup/09](../setup/09-folders-and-security-command-center.md) FS-4.1 and FS-4.2 **unchanged**. FS-4.1 writes the 22 folder ids from the variables PF-3.1 has just proven, never by hand; FS-4.2 commits them under review. The file is the full build's own register artefact, so the full build finds it already merged and does not regenerate it ([02](../02-landing-zone-and-tiers.md) §2.1: the numeric ids are "published to the register as `folders.yaml`"). File 04 PC-0.1 stops without it.

```bash
source ~/.platform-env; penv_guard
checkpoint PF-3.1a START - - "register/folders.yaml from the live tree"
# FS-4.1's generator, unchanged: it reads FLD_* and ORG_ID from the environment and raises KeyError on any unset one.
# FS-4.2, unchanged: add, commit, push, open the pull request that links PF-3.1's tree-diff record.
```

- **VERIFY:** FS-4.1 prints `22 folders written`; `grep -c 'variable: FLD_' "$PLATFORM_REPO_DIR/register/folders.yaml"` and `grep -cE 'id: "[0-9]+"$' "$PLATFORM_REPO_DIR/register/folders.yaml"` both print `22`; the pull request is merged under branch protection with two approvals, neither the operator's; `git -C "$PLATFORM_REPO_DIR" log --oneline -1 -- register/folders.yaml` shows the merge.
- **ROLLBACK:** Before merge, FS-4.1's rollback (delete the file and the branch). After merge, a revert commit through the same review; a merged register file is never rewritten.
- **EVIDENCE:** The merge commit id as `<date>-PF-3.1a-folders-yaml-v1`; `checkpoint PF-3.1a DONE`. Deviation row `BD-P03-3` covers it (the file says `made_by: hand`, SD-01). E-05. TISAX 1.3.1, 5.2.1.

### PF-3.2 Observability location default set; Cloud Logging folder default left unset

- **WHO:** The operator, holding a time-bound `roles/logging.admin` on `fld-agentic-platform`, **granted to `sa-1-admin@` by the second person** as `sa-2-admin@` with an expiry condition (setup/09 FS-1.2's conditioned grant, with the granter changed as in PF-2.1; never a self-grant).
- **WHERE:** Shell. **Before any project exists in the tree.**
- **ACTION:**

```bash
gcloud beta observability settings update --default-storage-location="$REGION" --update-mask=default-storage-location --location=global --folder="$FLD_AGENTIC_PLATFORM"
gcloud logging settings describe --folder="$FLD_AGENTIC_PLATFORM"
```

  The mask is spelled as Google's example spells it, `--update-mask=default-storage-location` ([beta observability settings update](https://docs.cloud.google.com/sdk/gcloud/reference/beta/observability/settings/update), updated 2026-05-27, read 2026-09-16). Never set the Cloud Logging folder storage location or a folder CMEK: either blinds SCC's Sensitive Actions scanning of `_Required` (setup/09 FS-2.2).
- **VERIFY:** `gcloud beta observability settings describe --location=global --folder="$FLD_AGENTIC_PLATFORM" --format="value(defaultStorageLocation)"` prints `europe-west1`; the logging describe shows no `storageLocation` other than `global` and no `kmsKeyName`.
- **ROLLBACK:** Re-run the update with the previous value; the logging read changes nothing.
- **EVIDENCE:** Both outputs as `<date>-PF-3.2-location-defaults-v1`. E-06. TISAX 5.2.4.

### PF-3.3 Tag keys and values

- **WHO:** The operator, with a time-bound Tag Administrator at the organisation **granted to `sa-1-admin@` by the second person** (setup/09 FS-0.5; granter as PF-2.1).
- **WHERE:** Shell.
- **ACTION:** The two keys the brief fixes, `agp-tier` and `agp-tisax-scope`, are created under the NAMES and PV-03 gate. `agp-env` is **not** among the fixed tag keys, so it is created only when the signed NAMES record carries a `TAG_KEY_ENV` value, checked by the tool, not by reading the prose:

```bash
pf_3_3() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" NAMES PV-03 || { echo "STOP PF-3.3: NAMES or PV-03 unsigned" >&2; return 1; }
  checkpoint PF-3.3 START "$SECOND_HUMAN_EMAIL" - "tag keys: short names are permanent"
  gcloud resource-manager tags keys create agp-tier --parent="organizations/$ORG_ID" --description="Platform tier of the folder (02 3.6, P38): c r w p p-sa x ctl imp core ge"
  gcloud resource-manager tags keys create agp-tisax-scope --parent="organizations/$ORG_ID" --description="TISAX scope (02 3.6, P38): in out"
  k="$(gcloud resource-manager tags keys describe "$ORG_ID/agp-tier" --format='value(name)')" && [ -n "$k" ] || return 1
  penv_set TAG_KEY_TIER "$k"
  k="$(gcloud resource-manager tags keys describe "$ORG_ID/agp-tisax-scope" --format='value(name)')" && [ -n "$k" ] || return 1
  penv_set TAG_KEY_TISAX "$k"
  for v in c r w p p-sa x ctl imp core ge; do gcloud resource-manager tags values create "$v" --parent="$TAG_KEY_TIER" --description="agp-tier=$v"; done
  for v in in out; do gcloud resource-manager tags values create "$v" --parent="$TAG_KEY_TISAX" --description="agp-tisax-scope=$v"; done
  if e="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES TAG_KEY_ENV 2>/dev/null)" && [ "$e" = agp-env ]; then
    gcloud resource-manager tags keys create agp-env --parent="organizations/$ORG_ID" --description="Environment of the folder (02 3.6, P38): prod nonprod"
    k="$(gcloud resource-manager tags keys describe "$ORG_ID/agp-env" --format='value(name)')" && [ -n "$k" ] || return 1
    penv_set TAG_KEY_ENV "$k"
    for v in prod nonprod; do gcloud resource-manager tags values create "$v" --parent="$TAG_KEY_ENV" --description="agp-env=$v"; done
  else
    checkpoint PF-3.3 PENDING - - "agp-env not in the signed NAMES record; not created"
  fi
}; pf_3_3
```

  The NAMES row is the short name `agp-env`, as setup/09 FS-0.2 names it; any other value, or no row, leaves the key uncreated and PF-3.4 skips its `agp-env` bindings.
- **VERIFY:** Two `tagKeys/<digits>` values (three with `agp-env`); the values lists print `c core ctl ge imp p p-sa r w x` and `in out` (and `nonprod prod` with `agp-env`); when `agp-env` was not created, `checkpoints.tsv` has the `PENDING` line and `gcloud resource-manager tags keys list --parent="organizations/$ORG_ID" --format="value(shortName)"` does not print `agp-env`.
- **ROLLBACK:** **IRREVERSIBLE as a name**: "After the `shortName` has been created, it cannot be changed" ([create and manage tags](https://docs.cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing), updated 2026-09-09). Confirm first: `decision-need.sh NAMES` printed `SIGNED` and each short name matches the record character for character. Gated on NAMES and PV-03.
- **EVIDENCE:** Build-log line with the key names. E-05. TISAX 1.3.1.

### PF-3.4 Bind the tags and verify all 22 folders

- **WHO:** The operator (Tag User from the same conditioned grant made by the second person).
- **WHERE:** Shell.
- **ACTION:** Run setup/09 FS-5.3, FS-5.4 and FS-5.5 unchanged: `agp-tier` on the nine tier-level folders (`p-sa` overriding `p`), `agp-env` on the twelve environment folders only if PF-3.3 created it (`need TAG_KEY_ENV` passes; otherwise those bindings are skipped and FS-5.6's `agp-env` column is recorded PENDING), `agp-tisax-scope=in` on `fld-agentic-platform` and `out` on `fld-agents-x`. Each is one `gcloud resource-manager tags bindings create --tag-value="$ORG_ID/<key>/<value>" --parent="//cloudresourcemanager.googleapis.com/folders/<id>"`.
- **VERIFY:** setup/09 FS-5.6's script prints `tags: 22 folders match`. Then remove every time-bound self-grant made for Part 3 (setup/09 FS-8.1) and read the organisation and folder policies back.
- **ROLLBACK:** `gcloud resource-manager tags bindings delete` per binding.
- **EVIDENCE:** Script output as `<date>-PF-3.4-effective-tags-v1`. E-05. TISAX 1.3.1, 1.3.2.

### Part 4: Core projects and keys (compresses setup/10 and setup/11)

### PF-4.1 The five core projects

- **WHO:** The operator (Project Creator from PF-2.1).
- **WHERE:** Shell, one pass per row in the order `CICD_PROJECT`, `CORE_PROJECT`, `LOGGING_PROJECT`, `KMS_PROJECT`, `VALIDATOR_PROJECT`.
- **ACTION:** Run setup/10 CP-1.1 to CP-1.10 per row unchanged: the id read from NAMES, the ten labels, `--no-enable-cloud-apis`, a deletion lien, the billing link, exactly the row's APIs, the `_Default` redirect and `_Trace` bucket in `europe-west1`, a monthly budget at the row's amount with thresholds at 50, 90 and 100 per cent. The create and record lines of each pass, with `P_VAR`, `P_NAME`, `P_PURPOSE`, `P_OWNER_LABEL` and `P_RECOVERY` set from setup/10's row table:

```bash
pf_4_1() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" NAMES PV-03 || { echo "STOP PF-4.1: NAMES or PV-03 unsigned" >&2; return 1; }
  P_ID="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES "$P_VAR")" && [ -n "$P_ID" ] || { echo "STOP PF-4.1: no NAMES value for $P_VAR" >&2; return 1; }
  checkpoint "PF-4.1-$P_VAR" START "$SECOND_HUMAN_EMAIL" - "create project $P_ID (id permanent)"
  gcloud projects create "$P_ID" --folder="$FLD_PLATFORM_CORE" --name="$P_NAME" --no-enable-cloud-apis --labels="agent=platform-${P_PURPOSE},owner=${P_OWNER_LABEL},tier=core,env=prod,data_class=confidential,ai_act_class=not_ai_system,recovery_class=${P_RECOVERY},cost_centre=tbd,created_by=bootstrap-hand,factory_run=dev-10-${P_PURPOSE}" || return 1
  penv_set "$P_VAR" "$P_ID"
  penv_set "${P_VAR}_NUMBER" "$(gcloud projects describe "$P_ID" --format='value(projectNumber)')"
  gcloud billing projects link "$P_ID" --billing-account="$BILLING_ACCOUNT_ID"
  gcloud billing budgets create --billing-account="$BILLING_ACCOUNT_ID" --display-name="agp ${P_PURPOSE} monthly" --budget-amount="300EUR" --calendar-period=MONTH --filter-projects="projects/${P_ID}" --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0 --billing-project="$CICD_PROJECT"
}; pf_4_1
```

  `ai_act_class=not_ai_system` is PV-11's classification for platform-core projects, spelled as the register schema's enum value so a join from labels to register rows matches; label values may contain "lowercase letters, numeric characters, underscores, and dashes" ([labels overview](https://docs.cloud.google.com/resource-manager/docs/labels-overview), updated 2026-09-09, read 2026-09-16). Budget flags checked against the [budgets create reference](https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/create) (updated 2026-05-27).
- **VERIFY:** Per row, setup/10 CP-1.1's describe shows the parent, the labels and `ACTIVE`; CP-1.5's effective tags show `core` and `in` inherited and nothing bound directly; `gcloud billing projects describe` prints the account and `True`; `gcloud billing budgets list --billing-account="$BILLING_ACCOUNT_ID"` lists the budget.
- **ROLLBACK:** **IRREVERSIBLE** as a name: a project id "cannot be in use or previously used; this includes deleted projects" (setup/10 CP-1.1, read 2026-09-15). Confirm first: the id equals the NAMES value; `FLD_PLATFORM_CORE` is the id of `fld-platform-core`. Gated on NAMES and PV-03. A wrong parent is fixed by a project move, never delete and re-create.
- **EVIDENCE:** Describe YAML per row as `<date>-PF-4.1-<var>-v1`. Deviation row `BD-P03-4` (projects made by hand; PV-D-01). E-05. TISAX 1.3.1.

### PF-4.2 `AR_PLATFORM` and the `factory-apply@` identity

- **WHO:** The operator.
- **WHERE:** Shell.
- **ACTION:**

```bash
gcloud artifacts repositories create platform --repository-format=docker --location="$REGION" --project="$CICD_PROJECT" --description="Platform images (setup/10 CP-2.3)"
penv_set AR_PLATFORM "${REGION}-docker.pkg.dev/${CICD_PROJECT}/platform"
gcloud iam service-accounts create factory-apply --project="$CICD_PROJECT" --display-name="factory-apply" --description="Identity only in the POV: no key, no role, no federation (B-01)"
penv_set SA_FACTORY_APPLY "factory-apply@${CICD_PROJECT}.iam.gserviceaccount.com"
```

  `factory-apply@` exists only so that `deny-agents-platform` (PF-5.4) names the same principal as the full build's policy. Workload Identity Federation, its roles and the factory stay with B-01.
- **VERIFY:** `gcloud artifacts repositories describe platform --location="$REGION" --project="$CICD_PROJECT"` shows `DOCKER`; `gcloud iam service-accounts keys list --iam-account="$SA_FACTORY_APPLY" --project="$CICD_PROJECT" --managed-by=user` is empty; the account holds no binding anywhere (`gcloud projects get-iam-policy "$CICD_PROJECT"` does not name it).
- **ROLLBACK:** Delete the repository while empty; disable the service account.
- **EVIDENCE:** As `<date>-PF-4.2-registry-and-factory-identity-v1`. E-05. TISAX 5.3.1.

### PF-4.3 The four signed key rings and the logging key

- **WHO:** The operator; the second person reads the key table aloud before each create.
- **WHERE:** Shell.
- **ACTION:** KEYS record rows, unchanged ([setup/03 DC-5.2](../setup/03-decisions-and-people.md)). Eve's rings `eve` and `eve-eu` are file 06's.

```bash
pf_4_3() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" KEYS NAMES || { echo "STOP PF-4.3: KEYS or NAMES unsigned" >&2; return 1; }
  need KMS_PROJECT CICD_PROJECT || return 1
  checkpoint PF-4.3 START "$SECOND_HUMAN_EMAIL" - "key rings and HSM key: names permanent"
  gcloud kms keyrings create logging --location=europe-west1 --project="$KMS_PROJECT"
  penv_set KR_LOGGING "projects/${KMS_PROJECT}/locations/europe-west1/keyRings/logging"
  gcloud kms keyrings create engines --location=europe-west1 --project="$KMS_PROJECT"
  penv_set KR_ENGINES "projects/${KMS_PROJECT}/locations/europe-west1/keyRings/engines"
  gcloud kms keyrings create gemini --location=europe --project="$KMS_PROJECT"
  penv_set KR_GEMINI "projects/${KMS_PROJECT}/locations/europe/keyRings/gemini"
  gcloud kms keyrings create supply-chain --location=europe-west1 --project="$CICD_PROJECT"
  penv_set KR_SUPPLY_CHAIN "projects/${CICD_PROJECT}/locations/europe-west1/keyRings/supply-chain"
  gcloud kms keys create platform-logs-europe-west1 --keyring=logging --location=europe-west1 --purpose=encryption --protection-level=hsm --rotation-period=90d --next-rotation-time="$(date -u -v+90d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '+90 days' +%Y-%m-%dT%H:%M:%SZ)" --destroy-scheduled-duration=30d --project="$KMS_PROJECT"
  penv_set KEY_PLATFORM_LOGS "${KR_LOGGING}/cryptoKeys/platform-logs-europe-west1"
}; pf_4_3
```

  The `gemini-cmek` key, the attestor keys and Autokey are not made here: Gemini Enterprise CMEK is file 05's decision, and Binary Authorization is not used in the POV (PV-D-12). The rings exist now because their names are signed and permanent. `Assumption:` the key flags are setup/11 KV-2.2's; this file re-read only the ring command on 2026-09-16.
- **VERIFY:** `gcloud kms keyrings describe <ring> --location=<loc> --project=<project> --format="value(name)"` equals each `KR_*`; `gcloud kms keys describe platform-logs-europe-west1 --keyring=logging --location=europe-west1 --project="$KMS_PROJECT" --format="value(versionTemplate.protectionLevel)"` prints `HSM`.
- **ROLLBACK:** **IRREVERSIBLE**: "Key rings can't be deleted" and "Names of deleted keys can't be reused" ([Cloud KMS resources](https://docs.cloud.google.com/kms/docs/resource-hierarchy), updated 2026-09-03). Confirm first: ring name, location and project equal the KEYS row; `europe` is used only for `gemini`. Gated on KEYS. A wrong ring is left empty and recorded retired in the key table.
- **EVIDENCE:** The describes as `<date>-PF-4.3-key-rings-v1`. E-05. TISAX 5.1.1.

### Part 5: PAM, organisation policies, deny and PAB (compresses setup/12 and setup/13)

### PF-5.1 Set up PAM and create the POV catalogue subset

- **WHO:** The operator (PAM Admin from PF-2.1); the second person reviews the pull request.
- **WHERE:** Shell; `PLATFORM_REPO_DIR/pam/`.
- **ACTION:** Enable `privilegedaccessmanager.googleapis.com` on `CICD_PROJECT` (the quota project) and grant the PAM service agent its organisation role as setup/12 PA-1.1 and PA-1.2. Run setup/12 PA-2.1's `catalogue.py` with the rows the POV needs and no others: `ent-platform-policy`, `ent-org-sink`, `ent-k7-human`, `ent-k7-human-scheduler`, `ent-pam-catalogue-org`, `ent-folder-admin`, `ent-project-repair-core`. The file format is Google's documented entitlement YAML ([create entitlements](https://docs.cloud.google.com/iam/docs/pam-create-entitlements), updated 2026-09-16). The other rows are file 05's (`ent-ge-admin`), file 06's (`ent-factory-singleton-ctl-*`), file 08's (`ent-bootstrap-module-improvers-*`) or deferred with their tier. Merge, then per row:

```bash
need ORG_ID CICD_PROJECT FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE PLATFORM_REPO_DIR
# One create and one penv_set per entitlement. The scope flag is the row's own (setup/12 PA-2.1):
# the same flag must be passed to describe, or describe finds nothing and penv_set would get an empty value.
mk_ent() {  # mk_ent <entitlement id> <variable> <scope flag>
  gcloud pam entitlements create "$1" "$3" --location=global --entitlement-file="$PLATFORM_REPO_DIR/pam/entitlements/$1.json" --billing-project="$CICD_PROJECT" || return 1
  v="$(gcloud pam entitlements describe "$1" "$3" --location=global --billing-project="$CICD_PROJECT" --format='value(name)')" && [ -n "$v" ] || { echo "STOP PF-5.1: $1 not readable" >&2; return 1; }
  penv_set "$2" "$v"
}
mk_ent ent-platform-policy     ENT_PLATFORM_POLICY     --organization="$ORG_ID"
mk_ent ent-org-sink            ENT_ORG_SINK            --organization="$ORG_ID"
mk_ent ent-k7-human            ENT_K7_HUMAN            --organization="$ORG_ID"
mk_ent ent-k7-human-scheduler  ENT_K7_HUMAN_SCHEDULER  --folder="$FLD_AGENTIC_PLATFORM"
mk_ent ent-pam-catalogue-org   ENT_PAM_CATALOGUE_ORG   --organization="$ORG_ID"
mk_ent ent-folder-admin        ENT_FOLDER_ADMIN        --folder="$FLD_AGENTIC_PLATFORM"
mk_ent ent-project-repair-core ENT_PROJECT_REPAIR_CORE --folder="$FLD_PLATFORM_CORE"
penv_set PAM_ENTITLEMENTS "pam/index.tsv"
```

  `ent-project-repair-core` carries `roles/agentregistry.admin` (setup/12 PA-4.2), which is the only lawful human path to write the Agent Registry: files 05 and 07 use it for their witnessed registry writes.
- **VERIFY:** setup/12 PA-6.1's live-compare prints no difference for the seven entitlements; `need ENT_PLATFORM_POLICY ENT_ORG_SINK ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER ENT_PAM_CATALOGUE_ORG ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CORE` is silent; `ent-k7-human` and its scheduler pair are the only rows without an approval workflow, and that is recorded in `pam/no-approval.json`.
- **ROLLBACK:** `gcloud pam entitlements delete <id> --organization|--folder ... --location=global` while no grant is active.
- **EVIDENCE:** Merge commit and compare output as `<date>-PF-5.1-pam-catalogue-v1`. E-08. TISAX 4.1.3.

### PF-5.2 One grant per entitlement, approved by the second person

- **WHO:** The operator requests; **the second person approves** as `sa-2-admin@`; for `ent-k7-human`, no approver by design, and the second person confirms the activation mail.
- **WHERE:** Shell; the PAM console for the approver.
- **ACTION:** For each approval entitlement, one short grant with a justification that names this step, then revoke:

```bash
gcloud pam grants create --entitlement="$ENT_FOLDER_ADMIN" --requested-duration=900s --justification="POV 03 PF-5.2 one-grant test" --additional-email-recipients="$SECOND_HUMAN_EMAIL" --billing-project="$CICD_PROJECT"
gcloud pam grants search --entitlement="$ENT_FOLDER_ADMIN" --caller-relationship=had-created --billing-project="$CICD_PROJECT" --format="table(name,state)"
```

  `ent-k7-human` is tested exactly as setup/18 KS-4.2.
- **VERIFY:** Each grant reaches `ACTIVE` only after the second person's approval, which names `sa-2-admin@`; the `ent-k7-human` pair reaches `ACTIVE` with no approval and the second person confirms the mail from PAM with its time. No grant stays active.
- **ROLLBACK:** `gcloud pam grants revoke <grant> --reason="PF-5.2 test complete" --billing-project="$CICD_PROJECT"`.
- **EVIDENCE:** Grant names and approvals as `<date>-PF-5.2-grant-tests-v1`. E-08. TISAX 4.1.3.

### PF-5.3 The organisation-policy baseline and the allow-lists

- **WHO:** The operator under an `ENT_PLATFORM_POLICY` grant approved by the second person against the merged policy pull request.
- **WHERE:** Shell; `PLATFORM_REPO_DIR/policies/`.
- **ACTION:** Write the policy files with setup/13 OP-2.1 to OP-2.4 unchanged, for B1, B2, B3, B4, B5, B8, B9, B12, B21 and the B15 allow-lists of setup/13's allow-list table (every tier folder, `fld-agents-x` with an empty list, `fld-platform-core`, `KMS_PROJECT` at project level). Merge under two reviewers. Apply each with `gcloud org-policies set-policy <file> --update-mask=policy.spec` (or `policy.dry_run_spec`); the mask values are `policy.spec`, `policy.dry_run_spec` or `*` ([set-policy reference](https://docs.cloud.google.com/sdk/gcloud/reference/org-policies/set-policy), updated 2026-05-27).

  **Dry run first, everywhere, shortened on empty folders.** setup/13 runs a 14-day dry run before enforcing. Every policy that supports dry run is first applied with `--update-mask=policy.dry_run_spec`. Google supports dry run for custom constraints, managed constraints and three legacy managed constraints, restrict service usage among them, and shows violations in the policy audit log with `protoPayload.metadata.dryRunResult = "DENIED" AND protoPayload.metadata.liveResult = "ALLOWED"` ([dry-run organisation policy](https://docs.cloud.google.com/resource-manager/docs/organization-policy/dry-run-policy), updated 2026-09-09, read 2026-09-16); a legacy constraint without dry-run support is enforced directly and named as such in the record.
  - On the tier, controller, improver and `fld-agents-x` folders, which hold no project on the day, the dry run lasts **at least 7 days** (`Assumption:` one weekly audit cycle, the POV's shortened value against setup/13's 14), the violation filter above is read at the end at `--organization` and at each folder, and the allow-lists are then enforced with `--update-mask=policy.spec`. K7 (PF-9.1) generates its lever files from the **enforced** lists, so PF-9.1 waits for this. The shortening is recorded as its own deviation row, **`BD-P03-5`**: "dry run shortened from 14 to at least 7 days on folders that hold no project; justification: an empty folder generates no call a dry run could log; closes when the first project is created in any of these folders, at which point setup/13's 14-day dry run applies to any new constraint". `BD-P03-5` is not covered by PV-D-01 (which covers building by hand, not a shortened dry run); [09](09-the-demonstration-deviations-and-the-hand-over.md) must carry it as a PV-D row, and until it does the row cites none.
  - On `fld-platform-core` and `KMS_PROJECT`, where the five projects already run, B15 stays in `dry_run_spec` for the full 14 days and is enforced by a dated re-run line.
  - B1 goes on `fld-improvers-nonprod` first, with SCC read before and after (setup/13 OP-4.1, OP-4.2), then widens to `fld-agentic-platform` as setup/13 orders it.
- **VERIFY:** `gcloud org-policies describe <constraint> --folder=<id>` on each folder shows `dryRunSpec` equal to the committed file during the dry run, then `gcloud org-policies describe <constraint> --folder=<id> --effective` matches the committed `spec` after enforcement; the dated violation read is empty on every empty folder, or each row is explained in the record. **B1 probe, against a project under a folder where B1 is actually enforced:** while B1 is enforced only on `fld-improvers-nonprod`, no project exists under it and the probe is recorded `PENDING (no project under the enforced folder)`; once B1 is enforced at `fld-agentic-platform`, first `gcloud org-policies describe gcp.resourceLocations --project="$CORE_PROJECT" --effective` shows the EU-only list inherited, then a probe `gcloud storage buckets create gs://<probe> --location=us-central1 --project="$CORE_PROJECT"` is refused and the probe is not created. `Assumption:` B1 is `gcp.resourceLocations`, as the probe's region test implies; the constraint name is read from setup/13's B-row table on the day.
- **ROLLBACK:** `gcloud org-policies delete <constraint> --folder=<id>`, or re-apply the saved predecessor from setup/13 OP-1.1's snapshot.
- **EVIDENCE:** Dry-run describes, the dated violation reads and the effective reads as `<date>-PF-5.3-policy-baseline-v1`; deviation row `BD-P03-5` (dry run shortened on empty folders) in `DEVIATION_REGISTER`. E-05. TISAX 4.2.1, 5.2.1.

### PF-5.4 `deny-agents-platform` and `pab-agents`

- **WHO:** The operator under the same `ENT_PLATFORM_POLICY` grant.
- **WHERE:** Shell.
- **ACTION:** Write `policies/deny/deny-agents-platform.json` and `policies/pab/pab-agents.rules.json` with setup/13 OP-2.5 unchanged (rule R6 on `factory-apply@`; the PAB rule allowing only `fld-agentic-platform`), check every permission against Google's deny-support list (OP-2.6), merge, then:

```bash
AP="cloudresourcemanager.googleapis.com/folders/$FLD_AGENTIC_PLATFORM"
gcloud iam policies create deny-agents-platform --attachment-point="$AP" --kind=denypolicies --policy-file="$PLATFORM_REPO_DIR/policies/deny/deny-agents-platform.json"
penv_set DENY_AGENTS_PLATFORM "$(gcloud iam policies get deny-agents-platform --attachment-point="$AP" --kind=denypolicies --format='value(name)')"
gcloud iam principal-access-boundary-policies create pab-agents --organization="$ORG_ID" --location=global --display-name="pab-agents" --details-rules="$PLATFORM_REPO_DIR/policies/pab/pab-agents.rules.json" --details-enforcement-version=4
penv_set PAB_AGENTS "organizations/${ORG_ID}/locations/global/principalAccessBoundaryPolicies/pab-agents"
```

  Flags checked on 2026-09-16 against the [iam policies create](https://docs.cloud.google.com/sdk/gcloud/reference/iam/policies/create) and [principal-access-boundary-policies create](https://docs.cloud.google.com/sdk/gcloud/reference/iam/principal-access-boundary-policies/create) references (both updated 2026-05-27). **No POV file creates a per-agent deny entry, a `pab-agents` binding, `deny-core-agents` or `deny-improvers`** (no step in 04 to 08 does, read 2026-09-16). `pab-agents` therefore stays unbound for the whole POV, and `deny-agents-platform` carries only R6 on `factory-apply@`. All four are handed over: setup/13 OP-7.5 (`deny-core-agents`), OP-7.6 (`deny-improvers`), OP-7.8 (`pab-agents` and its bindings) and setup/17's module equivalents for the per-agent entries. Any later POV step that reasons from a `pab-agents` binding (for example a K7 drill's KF-4 skip) first runs `gcloud iam principal-access-boundary-policies search-policy-bindings pab-agents --organization="$ORG_ID" --location=global` and cites the binding it finds; an empty result means the reason does not hold.
- **VERIFY:** The live rules equal the committed rules (`diff` of `jq -S .rules`); `details.enforcementVersion` is `4`; `search-policy-bindings pab-agents` prints nothing.
- **ROLLBACK:** `gcloud iam policies delete deny-agents-platform --attachment-point="$AP" --kind=denypolicies`; `gcloud iam principal-access-boundary-policies delete pab-agents --organization="$ORG_ID" --location=global` while unbound.
- **EVIDENCE:** Read-backs as `<date>-PF-5.4-deny-and-pab-v1`. E-05. TISAX 4.2.1.

### Part 6: Workspace sharing and central logging (compresses setup/14)

### PF-6.1 Turn on Workspace data sharing and read what actually arrives

- **WHO:** A super admin (`sa-2-admin@`, so that the operator does not both enable and verify); the organisation's Cloud Logging owner consents beforehand and reads the Data Access streams.
- **WHERE:** Admin console > Account > Account settings > Legal and compliance > Sharing options; then the Cloud Logging owner's shell.
- **ACTION:** **The personal-data gate first, run by the operator with the second person watching, before anyone opens the sharing page:**

```bash
pf_6_1_gate() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-08 SD-11 PV-10 || { echo "STOP PF-6.1: the DPO's monitoring record (PV-08, SD-11) or retention (PV-10) is unsigned; do not enable sharing" >&2; return 1; }
  for n in EVIDENCE_RETENTION_DAYS IDENTITY_RETENTION_DAYS; do
    v="$(printenv "$n")"; case "$v" in ''|*[!0-9]*) echo "STOP PF-6.1: $n is not an integer" >&2; return 1;; esac
    [ "$v" = "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-10 "$n")" ] || { echo "STOP PF-6.1: $n differs from PV-10" >&2; return 1; }
  done
  checkpoint PF-6.1 START "$SECOND_HUMAN_EMAIL" - "Workspace data sharing under PV-08, SD-11, PV-10"
}; pf_6_1_gate
```

  Only when that prints no `STOP`: read the state; if already Enabled, record who enabled it and when and change nothing (the record then also says that employee data was already being shared before PV-08, for the DPO). Otherwise select Enabled, Save, and write the UTC time. "You must be signed in as a super administrator for this task" ([share data with Google Cloud services](https://knowledge.workspace.google.com/admin/getting-started/share-data-with-google-cloud-services), updated 2026-09-10, read 2026-09-16). After 24 hours, as setup/14 CL-1.4 and CL-1.5:

```bash
gcloud logging read 'logName:"organizations/'"$ORG_ID"'/logs/" AND protoPayload.serviceName="admin.googleapis.com"' --organization="$ORG_ID" --freshness=1d --limit=3 --format="table(timestamp,protoPayload.methodName,logName)"
gcloud logging read 'logName:"organizations/'"$ORG_ID"'/logs/" AND protoPayload.serviceName="cloudidentity.googleapis.com"' --organization="$ORG_ID" --freshness=7d --limit=3 --format="table(timestamp,protoPayload.methodName)"
gcloud logging read 'logName:"organizations/'"$ORG_ID"'/logs/cloudaudit.googleapis.com%2Fdata_access" AND protoPayload.serviceName="login.googleapis.com"' --organization="$ORG_ID" --freshness=1d --limit=3 --format="table(timestamp,protoPayload.methodName)"
gcloud logging read 'logName:"organizations/'"$ORG_ID"'/logs/cloudaudit.googleapis.com%2Fdata_access" AND protoPayload.serviceName="oauth2.googleapis.com"' --organization="$ORG_ID" --freshness=1d --limit=3 --format="table(timestamp,protoPayload.methodName)"
```

  Then write `records/<date>-PF-6.1-ws-sharing-v1.md` with a row per stream: arrived yes or no, and the edition condition as Google's page reads on the day. On 2026-09-16 it read: Groups Enterprise, Admin and User log events on every edition; OAuth and SAML log events on Enterprise Standard or Plus, Education Standard or Plus, Voice Premier and Cloud Identity Premium; Access Transparency on Enterprise Plus and Education editions only. This is the limit of [08-data-logging-retention-sovereignty.md:387](../08-data-logging-retention-sovereignty.md). Record also that Workspace entries are organisation-level, their region is not selectable, and they are outside the Workspace Data Region Policy (setup/14 §1). File 06 reads this record again before writing any detection.

```bash
penv_set WS_SHARING_RECORD "records/<date>-PF-6.1-ws-sharing-v1.md"
```

- **VERIFY:** Admin rows dated after the switch; Login rows present, read by someone holding `roles/logging.privateLogViewer` (never concluded "edition problem" without that role); the OAuth row is present or `WORKSPACE_EDITION` is outside the editions above and the record says so. The second person signs the record.
- **ROLLBACK:** Select Disabled only with the second person's and the Cloud Logging owner's written agreement: it silences every Workspace copy at once, and Google deletes existing shared data on its own schedule.
- **EVIDENCE:** Screenshot and record. The DPO adds the residency exception to the records of processing. E-06. TISAX 5.2.4, 7.1.

### PF-6.2 The two log buckets

- **WHO:** The operator under an `ENT_FOLDER_ADMIN` grant approved by the second person.
- **WHERE:** Shell.
- **ACTION:** First grant the Cloud Logging service account of `LOGGING_PROJECT` Encrypter/Decrypter on `KEY_PLATFORM_LOGS` (setup/14 CL-2.2), and run CL-2.5's throwaway-bucket proof. Then, with retention read from the signed PV-10 record, never typed:

```bash
pf_6_2() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" NAMES KEYS PV-08 SD-11 PV-10 || { echo "STOP PF-6.2: NAMES, KEYS, PV-08, SD-11 or PV-10 unsigned" >&2; return 1; }
  ev="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-10 EVIDENCE_RETENTION_DAYS)" && [ "$ev" = "$EVIDENCE_RETENTION_DAYS" ] || { echo "STOP PF-6.2: EVIDENCE_RETENTION_DAYS absent or differs from PV-10" >&2; return 1; }
  id="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-10 IDENTITY_RETENTION_DAYS)" && [ "$id" = "$IDENTITY_RETENTION_DAYS" ] || { echo "STOP PF-6.2: IDENTITY_RETENTION_DAYS absent or differs from PV-10" >&2; return 1; }
  [ "$ev" -ge 400 ] && [ "$ev" -le 3650 ] && [ "$id" -ge 183 ] && [ "$id" -le 3650 ] || { echo "STOP PF-6.2: a value is outside setup/14 CL-10.1's ranges" >&2; return 1; }
  [ "$REGION" = europe-west1 ] || { echo "STOP PF-6.2: REGION is not europe-west1" >&2; return 1; }
  checkpoint PF-6.2 START "$SECOND_HUMAN_EMAIL" - "log buckets: location and CMEK permanent"
  gcloud logging buckets create platform-evidence-logs --location="$REGION" --retention-days="$ev" --cmek-kms-key-name="$KEY_PLATFORM_LOGS" --enable-analytics --description="Platform evidence (08 S12)" --project="$LOGGING_PROJECT" || return 1
  penv_set LOG_BUCKET_EVIDENCE "projects/${LOGGING_PROJECT}/locations/${REGION}/buckets/platform-evidence-logs"
  gcloud logging buckets create platform-identity-logs --location="$REGION" --retention-days="$id" --cmek-kms-key-name="$KEY_PLATFORM_LOGS" --description="Login, SAML and OAuth-token Data Access entries (08 S13)" --project="$LOGGING_PROJECT" || return 1
  penv_set LOG_BUCKET_IDENTITY "projects/${LOGGING_PROJECT}/locations/${REGION}/buckets/platform-identity-logs"
}; pf_6_2
```

  The four log views and their readers are created by setup/14 CL-3.1 to CL-3.3 in the same sitting; readers who do not exist yet (Eve, Mo) are recorded with `exists_or_pending`.
- **VERIFY:** Each describe shows `retentionDays` equal to its PV-10 value (`EVIDENCE_RETENTION_DAYS` on `platform-evidence-logs`, `IDENTITY_RETENTION_DAYS` on `platform-identity-logs`), not locked, the key, `europe-west1`; `analyticsEnabled: true` on the evidence bucket only.
- **ROLLBACK:** **IRREVERSIBLE** as to location and CMEK: "After you create your log bucket, you can't change your bucket's region" ([log buckets](https://docs.cloud.google.com/logging/docs/buckets), updated 2026-09-09). Confirm first: CL-2.5's proof passed, `REGION` is `europe-west1`, the names match NAMES, the DPO's PV-08 and SD-11 record is signed. Gated on NAMES, KEYS, PV-08, SD-11 and PV-10. Before any sink writes, a wrong bucket may be deleted, and its name stays reserved while pending deletion.
- **EVIDENCE:** Describes as `<date>-PF-6.2-log-buckets-v1`. E-06. TISAX 5.2.4.

### PF-6.3 The two datasets

- **WHO:** The operator under an `ENT_PROJECT_REPAIR_CORE` grant approved by the second person.
- **WHERE:** Shell.
- **ACTION:** Google-managed encryption, which is setup/14 CL-4.1's branch (b) for a dataset without an Autokey handle; the choice is recorded.

```bash
pf_6_3() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" NAMES PV-08 SD-11 PV-10 || { echo "STOP PF-6.3: NAMES, PV-08, SD-11 or PV-10 unsigned" >&2; return 1; }
  ev="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-10 EVIDENCE_RETENTION_DAYS)" && [ "$ev" = "$EVIDENCE_RETENTION_DAYS" ] || { echo "STOP PF-6.3: EVIDENCE_RETENTION_DAYS absent or differs from PV-10" >&2; return 1; }
  [ "$BQ_LOCATION" = EU ] || { echo "STOP PF-6.3: BQ_LOCATION is not EU" >&2; return 1; }
  checkpoint PF-6.3 START "$SECOND_HUMAN_EMAIL" - "datasets: name and location permanent"
  bq --location="$BQ_LOCATION" mk --dataset --default_partition_expiration=$(( ev * 86400 )) --description="Central audit copy for SQL (08 S14)" --label=agp-store:s14 "${LOGGING_PROJECT}:platform_logs" || return 1
  penv_set PLATFORM_LOGS_DS platform_logs
  bq --location="$BQ_LOCATION" mk --dataset --description="Authorised views over platform_logs, one per agent_id" --label=agp-store:s14-views "${LOGGING_PROJECT}:platform_logs_views" || return 1
  penv_set PLATFORM_LOGS_VIEWS_DS platform_logs_views
}; pf_6_3
```

  `--default_partition_expiration` is in seconds; the value is PV-10's evidence retention, as file 06 does for its own datasets (`IDENTITY_RETENTION_DAYS * 86400` in PE-6.2). The dataset names are the fixed NAMES values `platform_logs` and `platform_logs_views`; the operator reads them against the record before the checkpoint.
- **VERIFY:** `bq show --format=prettyjson "${LOGGING_PROJECT}:platform_logs" | jq '{location, defaultPartitionExpirationMs}'` prints `EU` and `EVIDENCE_RETENTION_DAYS * 86400000`; `platform_logs_views` is in `EU` with no expiry.
- **ROLLBACK:** **IRREVERSIBLE** as a name and location. Confirm first: `BQ_LOCATION` is `EU`, the names are the NAMES values, PV-08, SD-11 and PV-10 are signed. Gated on NAMES, PV-08, SD-11 and PV-10. A wrong dataset is removed before any sink with `bq rm -d`, and the name is not reused without a NAMES amendment.
- **EVIDENCE:** JSON as `<date>-PF-6.3-datasets-v1`. E-06. TISAX 5.2.4.

### PF-6.4 Commit the filters, then create the fan-out sinks in `LOGGING_PROJECT`

- **WHO:** The operator writes; the second person is required reviewer on `logging/`; creates under `ENT_FOLDER_ADMIN` and `ENT_PROJECT_REPAIR_CORE`.
- **WHERE:** `PLATFORM_REPO_DIR/logging/`; shell.
- **ACTION:** setup/14 CL-5.1 unchanged: the six filter files, one filter each, and `logging/sinks-expected.yaml`, including its `never:` list. Merge. The create sitting opens with `pf_6_4_gate() { "$PLATFORM_REPO_DIR/tools/decision-need.sh" NAMES PV-08 SD-11 PV-10 || { echo "STOP PF-6.4" >&2; return 1; }; checkpoint PF-6.4 START "$SECOND_HUMAN_EMAIL" - "fan-out sinks"; }; pf_6_4_gate`, because `to-identity-bucket` carries employees' sign-in data. Then CL-5.2 to CL-5.5 unchanged: `to-evidence-bucket`, `to-identity-bucket`, `to-bigquery` created disabled with `--use-partitioned-tables`, its writer added to the `platform_logs` access list only, then enabled, and the `_Default` exclusion. Each filter is substituted from its file by `sed`, never retyped.
- **VERIFY:** CL-5.1's one-filter check prints `lines:1` six times; each sink's describe filter `diff`s clean against its substituted file; the `to-bigquery` writer holds `WRITER` on the dataset and no project role.
- **ROLLBACK:** Revert pull request; `gcloud logging sinks delete <sink> --project="$LOGGING_PROJECT"` before PF-6.5.
- **EVIDENCE:** Merge commit and describes as `<date>-PF-6.4-fan-out-sinks-v1`. E-06. TISAX 5.2.1, 5.2.4.

### PF-6.5 `S-org` and the intercepting `S-folder`, proven end to end

- **WHO:** The operator through `ENT_ORG_SINK` and `ENT_FOLDER_ADMIN`; **the second person approves both grants and is present for the `--no-disabled` line of `S-folder`**.
- **WHERE:** Shell.
- **ACTION:** setup/14 CL-6.1 (list the child sinks interception will affect), then CL-6.2 and CL-6.3 unchanged. `S-org` starts copying every employee's organisation-level Workspace entries the moment it is enabled, so the gate is the first line and nothing is created without it. Their core lines:

```bash
pf_6_5() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-08 SD-11 PV-10 || { echo "STOP PF-6.5: the DPO's record (PV-08, SD-11) or PV-10 unsigned; no organisation sink" >&2; return 1; }
  need LOG_BUCKET_EVIDENCE LOG_BUCKET_IDENTITY PLATFORM_LOGS_DS || { echo "STOP PF-6.5: PF-6.2 or PF-6.3 not done" >&2; return 1; }
  checkpoint PF-6.5 START "$SECOND_HUMAN_EMAIL" - "S-org and S-folder, created disabled"
  gcloud logging sinks create S-org "logging.googleapis.com/projects/${LOGGING_PROJECT}" --organization="$ORG_ID" --disabled --log-filter='logName:"organizations/'"$ORG_ID"'/logs/"' --description="Organisation-level entries only (08 3.2)"
gcloud logging sinks create S-folder "logging.googleapis.com/projects/${LOGGING_PROJECT}" --folder="$FLD_AGENTIC_PLATFORM" --include-children --intercept-children --disabled --log-filter="$(grep -v '^#' "$PLATFORM_REPO_DIR/logging/filters/audit-families.txt" | tr '\n' ' ')" --description="Audit families under fld-agentic-platform, intercepting (08 3.2)"
}; pf_6_5
```

  Each writer identity gets `roles/logging.logWriter` on `LOGGING_PROJECT` before its sink is enabled with `gcloud logging sinks update <sink> --organization|--folder ... --no-disabled`; each enable line runs inside a function whose first line is the same `decision-need.sh PV-08 SD-11 PV-10 || return 1` gate, so a record withdrawn between sittings stops the enable. Flags checked against the [sinks create reference](https://docs.cloud.google.com/sdk/gcloud/reference/logging/sinks/create) (updated 2026-09-15). Then CL-6.5's seeded-event proof, read by the second person.

```bash
penv_set SINK_S_ORG "organizations/${ORG_ID}/sinks/S-org"
penv_set SINK_S_FOLDER "folders/${FLD_AGENTIC_PLATFORM}/sinks/S-folder"
```

  The billing-account sink (CL-6.4) and the billing export (CL-9) are not needed to prove value and are handed over (setup/14 part 9).
- **VERIFY:** `S-folder` describes with `includeChildren: true`, `interceptChildren: true`, not disabled; the checkpoint for the enable line carries the second person's address; CL-6.5's seeded events appear in `platform-evidence-logs` and in `platform_logs` within the same sitting; CL-6.6's census finds no sink outside `sinks-expected.yaml`.
- **ROLLBACK:** Under a new approved grant: `gcloud logging sinks update S-folder --folder="$FLD_AGENTIC_PLATFORM" --disabled`. **Entries intercepted while a sink was misrouted are lost, not delayed**, which is why the enable is a two-person line.
- **EVIDENCE:** Describes, the seeded-event proof and the grant names as `<date>-PF-6.5-aggregated-sinks-v1`. E-06. TISAX 5.2.4, 4.1.3.

### PF-6.6 Lock the two log buckets at PV-10's values (before file 07)

- **WHO:** The operator under `ENT_FOLDER_ADMIN`; **witness: the second person**, named in each checkpoint.
- **WHERE:** Shell. Two separate sittings, one per bucket, as setup/14 CL-10.2 and CL-10.3. Not needed for POV-1; required before file 07's Tier W work (08 §5.1).
- **ACTION:**

```bash
pf_6_6_evidence() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-10 || { echo "STOP PF-6.6: PV-10 unsigned" >&2; return 1; }
  need EVIDENCE_RETENTION_DAYS || return 1
  v="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-10 EVIDENCE_RETENTION_DAYS)" && [ "$v" = "$EVIDENCE_RETENTION_DAYS" ] || { echo "STOP PF-6.6: variable differs from PV-10" >&2; return 1; }
  [ "$v" -ge 400 ] && [ "$v" -le 3650 ] || { echo "STOP PF-6.6: evidence value outside 400..3650" >&2; return 1; }
  gcloud logging buckets update platform-evidence-logs --location="$REGION" --retention-days="$v" --project="$LOGGING_PROJECT" || return 1
  [ "$(gcloud logging buckets describe platform-evidence-logs --location="$REGION" --project="$LOGGING_PROJECT" --format='value(retentionDays)')" = "$v" ] || { echo "STOP PF-6.6: read-back differs; do not lock" >&2; return 1; }
  checkpoint PF-6.6 START "$SECOND_HUMAN_EMAIL" - "lock platform-evidence-logs at ${v} days"
  gcloud logging buckets update platform-evidence-logs --location="$REGION" --locked --project="$LOGGING_PROJECT"
}; pf_6_6_evidence
```

  The same function for `platform-identity-logs` with `IDENTITY_RETENTION_DAYS` and setup/14 CL-10.1's identity range (183 to 3650), at the next sitting.
- **VERIFY:** `describe ... --format="value(locked,retentionDays)"` prints `True` and the signed value; a retention change the second person chooses is refused and its error recorded.
- **ROLLBACK:** **IRREVERSIBLE**: "Locking a log bucket is irreversible" ([log buckets](https://docs.cloud.google.com/logging/docs/buckets), updated 2026-09-09). Confirm first: the value equals PV-10's signed value; the bucket is in `europe-west1` with the key; every view the platform needs exists; the second person is present. Gated on PV-10.
- **EVIDENCE:** Describe and the refused change, signed by both, as `<date>-PF-6.6-log-bucket-locks-v1`. E-06. TISAX 5.2.4.

### Part 7: The evidence bucket, the channels and SCC (compresses setup/42 §3, setup/15 part A, setup/09 §7)

`PLATFORM_EVIDENCE_BUCKET` is made here, not at the end as in the full set: [01](01-conventions-and-variables.md) moved it forward, because an evidence backlog rebuilt afterwards is what an assessor refuses.

### PF-7.1 Create `PLATFORM_EVIDENCE_BUCKET`

- **WHO:** The operator under `ENT_PROJECT_REPAIR_CORE`; the second person present.
- **WHERE:** Shell.
- **ACTION:** setup/42 GD-3.1 unchanged:

```bash
pf_7_1() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" NAMES PV-10 || { echo "STOP PF-7.1: NAMES or PV-10 unsigned" >&2; return 1; }
  b="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES PLATFORM_EVIDENCE_BUCKET)" && [ -n "$b" ] || { echo "STOP PF-7.1: no PLATFORM_EVIDENCE_BUCKET in NAMES (02 PD-3.2)" >&2; return 1; }
  [ "$b" = "gs://${LOGGING_PROJECT}-platform-evidence" ] || { echo "STOP PF-7.1: NAMES value $b differs from the setup/42 GD-3.1 form; resolve in NAMES before creating" >&2; return 1; }
  [ "$REGION" = europe-west1 ] || { echo "STOP PF-7.1: REGION is not europe-west1" >&2; return 1; }
  checkpoint PF-7.1 START "$SECOND_HUMAN_EMAIL" - "create the platform evidence bucket $b (name and location permanent)"
  penv_set PLATFORM_EVIDENCE_BUCKET "$b"
  gcloud kms keys add-iam-policy-binding "$KEY_PLATFORM_LOGS" --member="serviceAccount:$(gcloud storage service-agent --project="$LOGGING_PROJECT")" --role=roles/cloudkms.cryptoKeyEncrypterDecrypter || return 1
  gcloud storage buckets create "$PLATFORM_EVIDENCE_BUCKET" --project="$LOGGING_PROJECT" --location="$REGION" --default-storage-class=STANDARD --uniform-bucket-level-access --public-access-prevention --default-encryption-key="$KEY_PLATFORM_LOGS" --soft-delete-duration=30d || return 1
  gcloud storage buckets update "$PLATFORM_EVIDENCE_BUCKET" --versioning
}; pf_7_1
```

- **VERIFY:** `gcloud storage buckets describe "$PLATFORM_EVIDENCE_BUCKET" --format="value(location,default_storage_class,uniform_bucket_level_access,public_access_prevention)"` prints `EUROPE-WEST1 STANDARD True enforced`; the full YAML dump shows versioning, the key and 30-day soft delete, recorded by key name; `PLATFORM_EVIDENCE_BUCKET` equals `decision-value.sh NAMES PLATFORM_EVIDENCE_BUCKET`.
- **ROLLBACK:** **IRREVERSIBLE** as to name and location. Confirm first: the function compared the NAMES value with the constructed form and both matched; `REGION` is `europe-west1`. Gated on NAMES. Before PF-7.2's lock only, an empty bucket may be deleted.
- **EVIDENCE:** The dump as `<date>-PF-7.1-evidence-bucket-v1`, signed by the second person. E-05. TISAX 5.2.4.

### PF-7.2 Set the retention, then lock it at a separate sitting

- **WHO:** The operator runs; **the second person is present and countersigns**.
- **WHERE:** Shell.
- **ACTION:** setup/42 GD-3.2 unchanged: two sittings.

```bash
pf_7_2_check() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-10 || { echo "STOP PF-7.2: PV-10 unsigned" >&2; return 1; }
  need PLATFORM_EVIDENCE_BUCKET RECORD_RETENTION_DAYS || return 1
  v="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-10 RECORD_RETENTION_DAYS)" && [ "$v" = "$RECORD_RETENTION_DAYS" ] || { echo "STOP PF-7.2: variable differs from PV-10" >&2; return 1; }
  [ "$v" -ge 400 ] && [ "$v" -le 3650 ] || { echo "STOP PF-7.2: record value outside setup/42's 400..3650" >&2; return 1; }
}
pf_7_2_set() {
  pf_7_2_check || return 1
  gcloud storage buckets update "$PLATFORM_EVIDENCE_BUCKET" --retention-period="P${RECORD_RETENTION_DAYS}D" || return 1
  gcloud storage buckets describe "$PLATFORM_EVIDENCE_BUCKET" --format="default(location,retention_policy)"
}; pf_7_2_set
# next sitting, after the read-back is recorded:
pf_7_2_lock() {
  pf_7_2_check || return 1
  checkpoint PF-7.2 START "$SECOND_HUMAN_EMAIL" - "lock retention at ${RECORD_RETENTION_DAYS} days"
  gcloud storage buckets update "$PLATFORM_EVIDENCE_BUCKET" --lock-retention-period
}; pf_7_2_lock
```

  At the second sitting, paste `pf_7_2_check` again and then the `pf_7_2_lock` block only (a new shell does not keep the first sitting's definitions); `pf_7_2_set` is not re-run there.

  Then copy every record made since file 01 from `EVIDENCE_INTERIM_LOCATION` (setup/42 GD-3.4) and grant writers and readers as GD-3.3: nobody holds delete.
- **VERIFY:** `describe --format="default(retention_policy)"` shows the period and `isLocked: true`; the backlog copy count equals the evidence register's row count.
- **ROLLBACK:** **IRREVERSIBLE**: "A locked retention policy cannot be removed from a bucket or reduced in duration" ([storage buckets update](https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/update), updated 2026-05-27). Confirm first: PV-10's value; PF-7.1's VERIFY recorded `EUROPE-WEST1`; the second person is present. Gated on PV-10.
- **EVIDENCE:** Describe and backlog count as `<date>-PF-7.2-evidence-bucket-locked-v1`. E-05, E-06. TISAX 5.2.4.

### PF-7.3 The two core notification channels

- **WHO:** The operator; the second person confirms the test notification.
- **WHERE:** Shell; `CORE_PROJECT`.
- **ACTION:** Email channel to the second person, and the paging channel. No SIEM and no 24x7 retainer exist (PV-D-10), so `NOTIF_CH_PAGER_CORE` is the organisation's existing paging service if it has one, created as setup/15 PS-4.3 with the key piped from the vault and never stored; `Assumption:` otherwise it is an SMS channel to the incident commander's on-call number, and the record says business hours only.

```bash
gcloud beta monitoring channels create --project="$CORE_PROJECT" --display-name="email second human" --description="POV 03 PF-7.3" --type=email --channel-labels=email_address="$SECOND_HUMAN_EMAIL"
penv_set NOTIF_CH_EMAIL_CORE "$(gcloud beta monitoring channels list --project="$CORE_PROJECT" --filter='displayName="email second human"' --format='value(name)')"
penv_set NOTIF_CH_PAGER_CORE "<the channel name printed by setup/15 PS-4.3's create, or by the SMS create>"
```

- **VERIFY:** `gcloud beta monitoring channels describe "$NOTIF_CH_EMAIL_CORE" --project="$CORE_PROJECT" --format='value(type,enabled)'` prints `email True`; the same for the pager channel, never printing its labels; a test notification from the console reaches each recipient.
- **ROLLBACK:** `gcloud beta monitoring channels delete <name> --project="$CORE_PROJECT"`.
- **EVIDENCE:** Channel names and the recipients' confirmations as `<date>-PF-7.3-channels-v1`. E-08. TISAX 1.6.

### PF-7.4 SCC Standard at organisation level with `eu` residency; the Premium row left open

- **WHO:** IT security activates or witnesses; the operator records (setup/09 FS-7.1 path A or B).
- **WHERE:** The EU jurisdictional console `https://console.eu.cloud.google.com`, Security Command Center, organisation selected, Settings > Tier details and Setup details.
- **ACTION:** Read the state first (setup/09 FS-7.2). If not activated, activate **Standard**, not Premium, with data residency enabled at `eu` and Google-managed keys. Standard is "offered at no additional charge"; what it lacks is exactly detection: Event Threat Detection over Cloud Logging and Workspace, Sensitive Actions, and full Security Health Analytics, which Google says is "unavailable for new activations" of Standard ([SCC service tiers](https://docs.cloud.google.com/security-command-center/docs/service-tiers), updated 2026-09-16). If the organisation already runs Premium, record it and change nothing.

```bash
penv_set SCC_TIER "STANDARD/eu"
evidence_add PF-7.4 scc-tier E-05 1.5.1 "build-log:records/<date>-PF-7.4-scc-tier-v1.md"
mkdir -p "$PLATFORM_REPO_DIR/gates" && printf '| Gate row | State | Why | Unwind |\n|---|---|---|---|\n| Tier C: SCC Premium at organisation level (01-hld 0.4; SD-15) | OPEN | POV runs Standard (PV-D-02) | before a Tier P row touches a real account |\n' > "$PLATFORM_REPO_DIR/gates/tier-c-open-rows.md"
```

- **VERIFY:** Tier details shows Standard (or the pre-existing tier), Setup details shows `eu`; the gate file carries the row as `OPEN`, never green.
- **ROLLBACK:** **IRREVERSIBLE in effect** for the residency choice: it can be modified at most once a week, with 4 to 24 hours of SCC API downtime (setup/09 FS-7.3). Confirm first: the console host is the EU one and the location shown is `eu`; IT security has signed the sitting record.
- **EVIDENCE:** Screenshots and the record as `<date>-PF-7.4-scc-tier-v1`. Deviation row `BD-P03-7` (PV-D-02). E-05. TISAX 1.5.1.

### Part 8: Model Armor floors (compresses setup/18 §2)

Stated once and binding on every later POV file: organisation and folder floors are **template conformance**; they screen no traffic. Inline screening of model calls exists only through a project floor, and Google documents that integration as failing open when Model Armor is unavailable (setup/18 facts table). **A probabilistic content screen is never a trust boundary, whatever its grade. It produces evidence, not a boundary.**

### PF-8.1 Commit the floor file and the POV floor rule

- **WHO:** The operator writes; the second person and one other reviewer approve; IT security confirms or sets the organisation floor (setup/18 KS-2.2).
- **WHERE:** `PLATFORM_REPO_DIR/model-armor/floors.json`.
- **ACTION:** Run setup/18 KS-2.3's generator unchanged (platform floor and tier floors `tier-w`, `tier-p`, `tier-p-sa`, `controllers`; prompt injection and jailbreak `HIGH`, malicious URI enabled, four Responsible AI filters at `MEDIUM_AND_ABOVE`, multi-language on, enforcement `TRUE`; both spellings). Then add the POV floor rule in the same pull request:

```bash
F="$PLATFORM_REPO_DIR/model-armor/floors.json"
jq '.pov_floor_rule = {console_failure_mode: "Block (Gemini Enterprise app setting; applied in POV 05)", machine_ingress_fail_open: false, applies_to: "every gateway or service that calls Model Armor (POV 05 and 07)", grade: "detection-grade evidence, never a boundary", source: "01-hld 0.2; POV 03 PF-8.1"}' "$F" > "$F.new" && mv "$F.new" "$F"
```

- **VERIFY:** `jq '.floors | length' "$F"` prints `5`; `jq -e '.pov_floor_rule.machine_ingress_fail_open == false' "$F"` exits 0; two approvals, the second person's among them.
- **ROLLBACK:** Revert pull request before PF-8.2.
- **EVIDENCE:** Merge commit as `<date>-PF-8.1-floor-file-v1`. E-05. TISAX 5.2.1.

### PF-8.2 Write and read back the platform and tier floors

- **WHO:** The operator under an `ENT_FOLDER_ADMIN` grant (it carries `roles/modelarmor.floorSettingsAdmin`), approved by the second person.
- **WHERE:** Shell.
- **ACTION:** Save every floor first (setup/18 KS-2.1: the rollback source). Then KS-2.5 and KS-2.6 with the `ma_write` helper unchanged; its core call:

```bash
CLOUDSDK_API_ENDPOINT_OVERRIDES_MODELARMOR="https://modelarmor.googleapis.com/" gcloud model-armor floorsettings update --full-uri="folders/${FLD_AGENTIC_PLATFORM}/locations/global/floorSetting" --pi-and-jailbreak-filter-settings-enforcement=enable --pi-and-jailbreak-filter-settings-confidence-level=high --malicious-uri-filter-settings-enforcement=enabled --rai-settings-filters="$RAI_G" --enable-multi-language-detection --enable-floor-setting-enforcement=TRUE
```

  Values checked against the [floorsettings update reference](https://docs.cloud.google.com/sdk/gcloud/reference/model-armor/floorsettings/update) (updated 2026-05-27): `enable|disable`, `high|medium-and-above|low-and-above`, `TRUE|FALSE`. The full set passes `--billing-project` naming its `canary-r` project, which the POV does not build. **POV rule:** run without `--billing-project`; if Google refuses for want of a quota project, stop, do not enable `modelarmor.googleapis.com` on a core project (it is outside the core allow-list), and add a re-run line so that file 05 runs this step with `--billing-project="$GEMINI_PROJECT"` once that project is imported.

```bash
penv_set FLOOR_RECORD "records/<date>-PF-8.2-floor-record-v1.md"
```

- **VERIFY:** setup/18 KS-2.5's `describe | jq` on each of the five folders prints `enforce: true`, PI `ENABLED` at `HIGH`, URI `ENABLED`, four RAI types at `MEDIUM_AND_ABOVE`, `ml: true`; KS-2.7's audit read finds one floor-write entry per folder with one `methodName`, recorded for Eve. The conformance-ordering test (KS-2.8) needs a project and is a re-run line for file 05.
- **ROLLBACK:** Re-apply the saved values per folder; a floor that did not exist is set back to `--enable-floor-setting-enforcement=FALSE`.
- **EVIDENCE:** Describes, the `methodName` and the accepted spelling in `FLOOR_RECORD`. E-05. TISAX 5.2.1, 5.2.6.

### Part 9: K7, the fleet lever (compresses setup/18 §4 to §6)

K7 stops every agent in the selected tier folders at Google's API layer, from outside every agent project, pulled by a human, never by a model. It never touches `fld-controllers`, `fld-platform-core` or `fld-gemini-enterprise`. Lever order: KF-1 allow-list without `aiplatform` and `run`; KF-3 pause schedulers; KF-4 clear `pab-agents`; KF-2 attach `deny-agents-halt`. A token already minted stays valid for up to 60 minutes: K7 and K0 stop work at the API now, and K4 in file 07 stops the credential.

### PF-9.1 Generate and commit the `k7/` files

- **WHO:** The operator writes; **the second person is required reviewer** on `k7/`.
- **WHERE:** Shell; `PLATFORM_REPO_DIR/k7/`.
- **ACTION:** setup/18 KS-4.1 unchanged: the eight KF-1 files generated from the live effective allow-lists of PF-5.3, `scheduler-pause.txt`, `pab-empty.json`, `deny-agents-halt.template.json` with each permission checked against Google's deny-support list on the day, the `k7/README.md`, and CODEOWNERS for `/k7/`. Merge, then:

```bash
penv_set K7_POLICY_DIR "k7"
```

- **VERIFY:** KS-4.1's VERIFY: 8 files, each a non-zero count with `false false`; no `*` in any permission; template and permission list agree; `pab-agents` binding count `0`.
- **ROLLBACK:** Revert pull request; the files change nothing live.
- **EVIDENCE:** Merge commit and VERIFY output as `<date>-PF-9.1-k7-files-v1`. E-08. TISAX 5.2.1, 1.6.2.

### PF-9.2 Announce and prepare the drill

- **WHO:** The operator; the incident commander's desk and the second person acknowledge one business day ahead.
- **WHERE:** Shell; mail.
- **ACTION:** setup/18 KS-6.1 with `SEL` set to the four nonprod tier folders (`fld-agents-r-nonprod`, `-w-nonprod`, `-p-nonprod`, `-p-sa-nonprod`) and the `before-*` predecessors saved. **No probe project exists in the POV at this point** (the full set's `canary-r` is not built), so the probe lines are skipped and the record says so; the refused call is measured in file 07 against the doer's nonprod project and in file 09.
- **VERIFY:** Four `before-rsu-*` files, `before-pab-agents.json`, a deny list without `deny-agents-halt`, both acknowledgements.
- **ROLLBACK:** Nothing changed.
- **EVIDENCE:** As `<date>-PF-9.2-drill-prep-v1`. E-08. TISAX 5.2.6.

### PF-9.3 The enforced drill on the empty nonprod tier folders, and the two-person lift

- **WHO:** The operator pulls; **the second person is present throughout** and approves the lift grants; the desk is on the line.
- **WHERE:** The same shell, screen shared.
- **ACTION:** Dry run as setup/18 KS-6.2 (KF-1 as `policy.dry_run_spec`), then enforced as KS-6.3: activate the `ent-k7-human` pair with no approval, stamp every lever on `timeline.tsv`, apply KF-1 to the four folders, run the KF-3 inventory and pause loop. **KF-4 is skipped** (no binding on `pab-agents`; eligibility is a union, so clearing it is fleet-wide) and **KF-2 is not attached** (no project, so the principal list is empty), each stamped with its reason. Then the lift exactly as KS-6.4: a lift pull request approved by the second person, `ENT_PLATFORM_POLICY` and `ENT_FOLDER_ADMIN` grants approved by the second person, each folder restored from its saved predecessor with etags stripped, and the zero-diff read-back. Then KS-6.5's record:

```bash
penv_set POV_K7_FIRST_DRILL_RECORD "records/<date>-PF-9.3-k7-first-drill-v1.md"
evidence_add PF-9.3 k7-first-drill E-08 5.2.6 "build-log:$POV_K7_FIRST_DRILL_RECORD" "$BUILD_LOG_DIR/$POV_K7_FIRST_DRILL_RECORD"
```

- **VERIFY:** The timeline shows trigger, grants effective without approval, four `KF-1 set` stamps, the `effective` describe on each folder equal to its `k7/` file, the KF-4 and KF-2 skip stamps; trigger to last lever is under 900 s (the human-path target); after the lift, each folder's policy equals its predecessor and the deny list equals `before-deny-list.txt`. The record says plainly: "Refusal not measured: no agent project exists. Job path BLOCKED (B-04)." A `DRILL_CALENDAR` row schedules the next drill after file 07.
- **ROLLBACK:** The lift is the rollback; if a restore fails, KS-6.4's manual repair, and no folder is left on the KF-1 list at the end of the sitting.
- **EVIDENCE:** `timeline.tsv`, describes, the lift pull request and the record signed by both. E-08. TISAX 5.2.6, 1.6.3.

### PF-9.4 The `k7-executor` job: BLOCKED

- **WHO:** The operator, when the code exists.
- **WHERE:** `CORE_PROJECT`, `europe-west1`.
- **ACTION:** **BLOCKED.** Needs: the `k7-executor` source (the four levers in fixed order, idempotent, timing rows, PAM self-activation), in `PLATFORM_REPO_REMOTE` under `k7/executor/`, plus its identity `k7-executor@` and the `ent-k7-executor` pair. Repository: the platform repository. Gate that waits: G20 (full set only). `Assumption:` 3 to 5 engineer-days, outside the POV's PB-01 to PB-06 total because the POV does not need it: K7 is pulled by a person, and that is what the drill records. `checkpoint PF-9.4 BLOCKED - - "k7-executor code, B-04"`.
- **VERIFY:** The checkpoint line exists and README's BLOCKED index cites B-04 as inherited, not opened.
- **ROLLBACK:** None.
- **EVIDENCE:** The checkpoint line. E-08. TISAX 1.6.2.

### Part 10: Close

### PF-10.1 Open `gates/`

- **WHO:** The operator.
- **WHERE:** `PLATFORM_REPO_DIR`.
- **ACTION:** Commit `gates/README.md` naming the gate records the POV will write (Tier R in 04, Tier C in 05, Tier W in 07) and the open rows file from PF-7.4.

```bash
penv_set GATES_DIR "gates"
```

- **VERIFY:** `git -C "$PLATFORM_REPO_DIR" log --oneline -- gates/` shows the merge with two approvals.
- **ROLLBACK:** Revert pull request.
- **EVIDENCE:** Merge commit. E-05. TISAX 1.2.

### PF-10.2 The weekly hand check that stands in for drift detection

- **WHO:** The second person, weekly, from PF-10.3 until B-02 lands.
- **WHERE:** Shell as `sa-2-admin@`.
- **ACTION:** B-02 (drift and reconciliation jobs) is **PENDING**, not replaced. The weekly check re-runs, read-only: setup/09 FS-3.4's tree diff; FS-5.6's tag check; setup/14 CL-6.6's sink census against `sinks-expected.yaml`; the `describe` of the two locked buckets and the evidence bucket; a floor `describe` per folder compared with `floors.json`; `gcloud iam policies list` at `fld-agentic-platform`; and `gcloud organizations get-iam-policy "$ORG_ID"` compared with the last saved copy. Add one `DRILL_CALENDAR` row per week.
- **VERIFY:** A dated line per week in the build log with each check's pass or diff; a diff is raised the same day to the operator and, if it concerns the operator's own change, to the third person.
- **ROLLBACK:** Read only.
- **EVIDENCE:** The weekly lines as `<date>-PF-10.2-weekly-drift-v<n>`. E-05. TISAX 5.2.1.

### PF-10.3 Remove the creator's Owner and withdraw the bootstrap exception

- **WHO:** The operator; **the second person present** and confirming each removal.
- **WHERE:** Shell.
- **ACTION:** setup/12 PA-9.1 (sweep: no active grant, no standing `user:` or `group:` actAs on core accounts), PA-9.2 (remove the creator's `roles/owner` from each of the five core projects, after one `ENT_PROJECT_REPAIR_CORE` grant is proven), then PA-9.3:

```bash
pf_10_3() {
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" SD-01 || { echo "STOP PF-10.3: SD-01 unsigned" >&2; return 1; }
  need ENT_PAM_CATALOGUE_ORG ENT_PROJECT_REPAIR_CORE ENT_FOLDER_ADMIN BRK_GCP_1 || { echo "STOP PF-10.3: PF-5.2 or PF-1.6 not proven" >&2; return 1; }
  checkpoint PF-10.3 START "$SECOND_HUMAN_EMAIL" - "withdraw the SD-01 bootstrap exception"
  c="$PLATFORM_REPO_DIR/identity/bootstrap-exception-condition.yaml"
  for r in resourcemanager.folderCreator resourcemanager.projectCreator privilegedaccessmanager.admin resourcemanager.organizationAdmin; do
    gcloud organizations remove-iam-policy-binding "$ORG_ID" --member="user:$SA_1_ADMIN" --role="roles/$r" --condition-from-file="$c"
  done
}; pf_10_3
```

  `sitting_end` is **not** run yet: the read-back below comes first. The PAM Admin watch of PF-2.1 ends when this step's VERIFY passes; its last output is filed with this step's evidence.

- **VERIFY:** **Run by the second person, from their own session as `sa-2-admin@`**, never by the operator: the operator has just removed their own organisation rights and cannot read the policy, and never verifies their own evidence. If `sa-2-admin@` cannot read the organisation policy, the read runs under a short grant of an entitlement from PF-5.1's catalogue that carries `resourcemanager.organizations.getIamPolicy`, approved by the operator (a grant to the second person, never to the operator); if no entitlement carries it, the step stops and the gap is recorded, and the operator never reads it instead. `gcloud organizations get-iam-policy "$ORG_ID" --flatten="bindings[].members" --filter="bindings.members:user:$SA_1_ADMIN" --format="value(bindings.role)"` prints nothing; each core project's `gcloud projects get-iam-policy` names no `user:` owner; `BD-P03-2` is closed with the date. Only then the operator runs `sitting_end`, which prints `SITTING-END OK`, and writes `checkpoint PF-10.3 DONE "$SECOND_HUMAN_EMAIL" <read-back> "exception withdrawn"`.
- **ROLLBACK:** **IRREVERSIBLE** as a standing path: afterwards only an approved PAM grant or break-glass restores organisation rights. Confirm first: PF-5.2 proved `ENT_PAM_CATALOGUE_ORG`, `ENT_PROJECT_REPAIR_CORE` and `ENT_FOLDER_ADMIN` with a real approval; PF-1.6 proved a break-glass sign-in. Gated on SD-01.
- **EVIDENCE:** Policy reads as `<date>-PF-10.3-exception-withdrawn-v1`. E-08. TISAX 4.2.1, 1.4.

## Verification checklist for the whole part

- [ ] Exactly two human super admins (`sa-1-admin@`, `sa-2-admin@`), both key-only, both proven with both keys; daily accounts demoted; G3 done or excepted with dates under the signed `G3-ROSTER` record, one `PF-1.5-<n>` `DONE` per row (PF-1.5).
- [ ] Every Cloud IAM grant to `sa-1-admin@` names `sa-2-admin@` as granter in Admin Activity; `BD-P03-2` carries the second person's written acceptance; the PAM Admin watch has a dated output per working day to PF-10.3 (PF-2.1).
- [ ] No gated block ran past a `STOP`: `checkpoints.tsv` has no `START` for a gated step dated before the signature of its records.
- [ ] `decision-need.sh PV-08 SD-11 PV-10` was `SIGNED` before PF-6.1's checkpoint `START`; bucket and partition retention equal PV-10's values (PF-6.1 to PF-6.5).
- [ ] The inventory lists every domain-wide delegation client, and none belongs to the platform (PF-1.2).
- [ ] Break-glass proven; `gcp-organization-admins@` holds exactly two roles (PF-1.6).
- [ ] `ROSTER_FILE` and `CONTROL_GROUPS_FILE` merged by the second person; groups match (PF-1.7).
- [ ] Billing currency `EUR`; a budget per core project (PF-2.3, PF-4.1).
- [ ] `zero diff: 22 folders, 0 projects` before Part 4, and `tags: 22 folders match` (PF-3.1, PF-3.4). Nothing in `fld-agents-p-sa-*` or `fld-agents-x`.
- [ ] Five core projects with liens; four key rings and the HSM logging key (PF-4.1, PF-4.3).
- [ ] Seven entitlements live; each approval entitlement approved by the second person once; `ent-k7-human` activated without approval and paged (PF-5.1, PF-5.2).
- [ ] Allow-lists enforced on the tier folders after at least 7 days of dry run with an empty violation read, recorded as `BD-P03-5`; core allow-list in dry run with a dated enforcement line; `deny-agents-platform` and `pab-agents` read back (PF-5.3, PF-5.4).
- [ ] Workspace sharing record signed, each stream marked arrived or not with its edition condition (PF-6.1).
- [ ] Seeded events reach `platform-evidence-logs` and `platform_logs`; the sink census is clean (PF-6.5).
- [ ] `PLATFORM_EVIDENCE_BUCKET` locked at PV-10's value with the backlog copied (PF-7.2); the log buckets locked before file 07 (PF-6.6).
- [ ] `SCC_TIER=STANDARD/eu` (or the pre-existing tier recorded) and the Premium row `OPEN` (PF-7.4).
- [ ] Five folder floors read back with enforcement `TRUE`; `pov_floor_rule.machine_ingress_fail_open` is `false` (PF-8.1, PF-8.2).
- [ ] K7 drill record signed by both, with the refusal marked not measured (PF-9.3); PF-9.4 BLOCKED on B-04.
- [ ] Bootstrap exception withdrawn; `SITTING-END OK` (PF-10.3).

## What the next file needs from this one

| Needed by | Name | Set in |
|---|---|---|
| [04](04-the-contract-register-agent-ids-and-schemas.md) | `FLD_AGENTS_W_PROD`, `FLD_AGENTS_W_NONPROD`, `FLD_CONTROLLERS_PROD`, `FLD_IMPROVERS_PROD`; `register/folders.yaml` merged (PC-0.1 stops without it); `PLATFORM_REPO_REMOTE` merged with CODEOWNERS on `identity/`, `logging/`, `k7/`, `model-armor/` | PF-3.1, PF-3.1a, PF-1.7, PF-6.4, PF-8.1, PF-9.1 |
| [05](05-gemini-enterprise-and-tier-c.md) | `FLD_GEMINI_ENTERPRISE`, `TAG_KEY_TIER`, `PLATFORM_EVIDENCE_BUCKET`, `FLOOR_RECORD` and `model-armor/floors.json`'s `pov_floor_rule`, `K7_POLICY_DIR`, `PAM_ENTITLEMENTS`, `KR_GEMINI`, `GATES_DIR`, `SCC_TIER` and the PF-7.4 `scc-tier` evidence row; re-run lines for PF-8.2 (quota project) and KS-2.8 (conformance test) against `GEMINI_PROJECT`; `ent-ge-admin` to add to the catalogue | PF-3.1 to PF-10.1 |
| [06](06-eve-over-the-human-super-admins.md) | `WS_SHARING_RECORD`, `PLATFORM_LOGS_VIEWS_DS`, `ROSTER_FILE`, `SA_1_ADMIN`, `SA_2_ADMIN`, `BRK_GCP_1`, `BRK_GCP_2`, `FLD_CONTROLLERS_PROD`, the floor-write `methodName` from PF-8.2, the interim rules to retire only after `POV_EVE_H_LIVE_RECORD`; no `deny-core-agents` (handed over to setup/13 OP-7.5) | PF-1.3 to PF-6.5 |
| [07](07-the-doer-tier-w-and-the-optional-tier-p.md) | `FLD_AGENTS_W_PROD`, `FLD_AGENTS_W_NONPROD`, `FLD_AGENTS_P_PROD`, `DENY_AGENTS_PLATFORM`, `PAB_AGENTS`, `KR_ENGINES`, `AR_PLATFORM`, `NOTIF_CH_PAGER_CORE`, `NOTIF_CH_EMAIL_CORE`, both log bucket locks (PF-6.6), and the K7 re-drill with a refused call against the doer's nonprod project | PF-3.1 to PF-9.3 |
| [08](08-mo-and-the-value-report.md) | `FLD_IMPROVERS_PROD`, `BQ_LOCATION` datasets pattern; no `deny-improvers` (handed over to setup/13 OP-7.6) | PF-3.1, PF-5.4 |
| [02](02-decisions-people-and-the-retrospective-baseline.md) and [README](README.md) (gaps found here, for their owners to close) | A PD step that drafts and signs `G3-ROSTER` and one that signs `ORG-CREATOR-DEFAULTS` with the owners' confirmations; both listed in README §5.1 (day one) and §9 (decision tracker) | Preconditions |
| [09](09-the-demonstration-deviations-and-the-hand-over.md) | Deviation rows `BD-P03-1` to `BD-P03-7`; the fact that `pab-agents` has no binding in the POV (PF-5.4), so a KF-4 skip justified by a production binding must first find that binding with `search-policy-bindings`; `BD-P03-5` (dry run shortened to at least 7 days on empty folders), a build-time row that closes itself when the first agent project is created, and so needs no PV-D row; PV-D-01, PV-D-02, PV-D-03, PV-D-10, PV-D-12, PV-D-14 as used here; the hand-over of setup/10 CP-3 to CP-7 (build identity, federation, `factory-groups@`), setup/11 Autokey, attestors and the validator custodian, setup/12's other rows, setup/13's custom constraints and remaining B-rows, setup/14 CL-6.4 and CL-9 (billing sink and export), setup/15 SIEM, and setup/18 `canary-r` | all |

## Facts checked against Google's documentation on 2026-09-16

| Fact | Page (last updated as shown on the page) |
|---|---|
| Sharing path Menu > Account > Account settings > Legal and compliance > Sharing options; super admin required; Groups Enterprise, Admin and User log events on all editions; OAuth and SAML on Enterprise Standard or Plus, Education Standard or Plus, Voice Premier, Cloud Identity Premium; Access Transparency on Enterprise Plus and Education only | [Share data with Google Cloud services](https://knowledge.workspace.google.com/admin/getting-started/share-data-with-google-cloud-services) (2026-09-10) |
| Admin, User and OAuth Token log events retained 6 months; administrators cannot delete log event data or change its retention | [Data retention and lag times](https://knowledge.workspace.google.com/admin/reports/data-retention-and-lag-times) (2026-09-10) |
| "You may need to wait 7 days before a newly added security key is available at sign-in" | [Use a security key for 2-Step Verification](https://support.google.com/accounts/answer/6103523) |
| Tag key short name cannot be changed; bindings create form | [Create and manage tags](https://docs.cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) (2026-09-09); [tags keys create](https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/tags/keys/create) (2026-05-27) |
| `gcloud kms keyrings create KEY_RING --location`; "Key rings can't be deleted"; deleted key names cannot be reused | [Create a key ring](https://docs.cloud.google.com/kms/docs/create-key-ring) (2026-09-01); [Cloud KMS resources](https://docs.cloud.google.com/kms/docs/resource-hierarchy) (2026-09-03) |
| Budget flags `--billing-account`, `--display-name`, `--budget-amount`, `--calendar-period`, `--filter-projects`, `--threshold-rule` | [billing budgets create](https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/create) (2026-05-27) |
| PAM entitlement YAML fields; `gcloud pam entitlements create --entitlement-file --location` with an organisation, folder or project | [Create entitlements](https://docs.cloud.google.com/iam/docs/pam-create-entitlements) (2026-09-16); [pam entitlements create](https://docs.cloud.google.com/sdk/gcloud/reference/pam/entitlements/create) (2026-05-27) |
| `--update-mask` values `policy.spec`, `policy.dry_run_spec`, `*` | [org-policies set-policy](https://docs.cloud.google.com/sdk/gcloud/reference/org-policies/set-policy) (2026-05-27) |
| `gcloud iam policies create --attachment-point --kind=denypolicies --policy-file`; PAB create flags | [iam policies create](https://docs.cloud.google.com/sdk/gcloud/reference/iam/policies/create); [principal-access-boundary-policies create](https://docs.cloud.google.com/sdk/gcloud/reference/iam/principal-access-boundary-policies/create) (both 2026-05-27) |
| Sink flags `--organization`, `--folder`, `--include-children`, `--intercept-children`, `--disabled`, `--log-filter`, `--use-partitioned-tables` | [logging sinks create](https://docs.cloud.google.com/sdk/gcloud/reference/logging/sinks/create) (2026-09-15) |
| `gcloud identity groups create`: `--group-type` values `discussion`, `dynamic`, `security`; `--with-initial-owner` values `empty` and `with-initial-owner`, the creator becoming owner by default for non-dynamic groups | [identity groups create](https://docs.cloud.google.com/sdk/gcloud/reference/identity/groups/create) (2026-05-27) |
| `gcloud beta observability settings update --location=global --update-mask=default-storage-location --default-storage-location` (Google's example spelling) | [beta observability settings update](https://docs.cloud.google.com/sdk/gcloud/reference/beta/observability/settings/update) (2026-05-27) |
| Label keys and values "can contain only lowercase letters, numeric characters, underscores, and dashes" | [Labels overview](https://docs.cloud.google.com/resource-manager/docs/labels-overview) (2026-09-09) |
| A super admin can grant Organization Administrator | [Super admin best practices](https://docs.cloud.google.com/resource-manager/docs/super-admin-best-practices) (2026-09-09) |
| PAM `UpdateEntitlement` and `DeleteEntitlement` are Admin Activity entries of `privilegedaccessmanager.googleapis.com` with the full `google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.*` method names | [PAM audit logging](https://docs.cloud.google.com/iam/docs/audit-logging/audit-logging-pam) (2026-09-16) |
| Log-based alerting policies are created in a project with `gcloud monitoring policies create --policy-from-file` | [Log-based alerts](https://docs.cloud.google.com/logging/docs/alerting/log-based-alerts) (2026-09-09) |
| Dry run supported for custom, managed and three legacy managed constraints including restrict service usage; violation filter `dryRunResult = "DENIED" AND liveResult = "ALLOWED"` | [Dry-run organisation policy](https://docs.cloud.google.com/resource-manager/docs/organization-policy/dry-run-policy) (2026-09-09) |
| Locking a log bucket is irreversible; region fixed at creation; `--locked` and `--location` on update | [Log buckets](https://docs.cloud.google.com/logging/docs/buckets) (2026-09-09); [logging buckets update](https://docs.cloud.google.com/sdk/gcloud/reference/logging/buckets/update) (2026-09-15) |
| `--retention-period` in ISO 8601; `--lock-retention-period`; "A locked retention policy cannot be removed from a bucket or reduced in duration" | [storage buckets update](https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/update) (2026-05-27) |
| SCC Standard at no additional charge, activatable at organisation level; Premium adds Event Threat Detection, Sensitive Actions, full Security Health Analytics | [SCC service tiers](https://docs.cloud.google.com/security-command-center/docs/service-tiers) (2026-09-16) |
| Floor settings need `roles/modelarmor.floorSettingsAdmin`; lower-in-hierarchy settings take precedence; folder floors check template conformance | [Configure floor settings](https://docs.cloud.google.com/model-armor/configure-floor-settings) (2026-09-15) |
| Floor update flag values `enable\|disable`, `high\|medium-and-above\|low-and-above`, `--enable-floor-setting-enforcement=TRUE\|FALSE`, `--vertex-ai-enforcement-type` | [model-armor floorsettings update](https://docs.cloud.google.com/sdk/gcloud/reference/model-armor/floorsettings/update) (2026-05-27) |

Everything else in this file rests on the full set's verifications of 2026-09-15 and 2026-09-16, cited at each step by step id.

## Unverified on 2026-09-16

- **`failOpen`.** No Model Armor page or the floor-settings gcloud reference read on 2026-09-16 names a `failOpen` field, and a search of Google's documentation found none. The floor file records `machine_ingress_fail_open: false` as a requirement. Files 05 and 07 must find the documented field on the gateway or service they configure, or record that the setting does not exist and what stands in for it. Until then this file claims nothing about fail-closed behaviour.
- **Quota project for folder floor calls.** The floor-settings page does not say whether a folder-level call from user credentials needs a quota project. PF-8.2 tries without one and has a written fallback.
- **SCC Standard with data residency on a new activation.** The tiers page lists data residency among Standard's data-management features but does not give the activation steps for Standard. PF-7.4 relies on setup/09 FS-7.3's console path.
- **The `kms keys create` flag set** was not re-read on 2026-09-16. It is taken from setup/11 KV-2.2. (`gcloud identity groups create --group-type=security --with-initial-owner=empty` was read on 2026-09-16; see Facts checked.)
- **KF-2 permissions.** Whether `aiplatform.googleapis.com/reasoningEngines.query` can be denied is checked at PF-9.1 on the day, as setup/18 KS-4.1 requires. It does not matter to this file's drill, because KF-2 is not attached.
- **The second person's grant path.** Google says a super admin "can grant the Organization Administrator role" but does not say whether `sa-2-admin@` can set organisation IAM without first holding a Cloud IAM role itself. PF-2.1 allows a sitting-long, conditioned Organization Administrator for `sa-2-admin@`, removed in the same sitting.
- **Dry-run update mask spelling.** The dry-run page shows `--update-mask=dryRunSpec`; the `set-policy` reference lists `policy.dry_run_spec`. This file uses the reference's form; if Google refuses it on the day, the page's form is used and recorded.
- **Automatic alert on entitlement edits.** Whether a project-level log-based alert fires on organisation- and folder-level PAM entries routed by `S-org` and `S-folder` was not settled; PF-2.1's watch is a daily hand read until Eve takes it over.
- **The paging channel.** The organisation's paging service is not known to this set (`Assumption:`). PF-7.3's SMS branch is a stand-in, not a pager.

## Sources

- The full set: [setup/README.md](../setup/README.md) §4, §5, §5.2; [setup/01](../setup/01-prerequisites-and-conventions.md) helpers; [setup/03](../setup/03-decisions-and-people.md) DC-4.8, §8 NAMES and KEYS; setup/06, 07, 09, 10, 11, 12, 13, 14, 15 (part A), 17, 18, 42 §3 as linked in Status.
- The design: [01-hld.md](../01-hld.md) §0.2 and §0.4; [02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §2.1 and §2.2; [08-data-logging-retention-sovereignty.md](../08-data-logging-retention-sovereignty.md) line 387 and §5; [10-eu-ai-act.md](../10-eu-ai-act.md) §5; [11-tisax.md](../11-tisax.md) §13.
- The POV set: [README](README.md), [01](01-conventions-and-variables.md), [02](02-decisions-people-and-the-retrospective-baseline.md), [09](09-the-demonstration-deviations-and-the-hand-over.md).
- Google's pages as listed under "Facts checked".
