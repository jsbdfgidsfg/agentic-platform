# POV 05. Gemini Enterprise and Tier C: inventory, baseline, Model Armor, two admitted agents, the first kill drills

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-17
- Last executed: never
- Step prefix: `PG`. 32 steps. Stage POV-1 (README §3), week 2 to week 3 or 4.
- BLOCKED: PG-3.1's Terraform import (B-01, PV-D-01) and PG-6.3's nightly reconciliation job
  (B-02). Both keep a hand-run interim that is executed here. No POV-only code block (PB-xx) is
  opened by this file.
- IRREVERSIBLE: PG-8.4 (deletion of the drill fixture agent, a throwaway made in the same step).
  **User-visible** and witnessed: PG-3.3 (the project move), PG-4.2 (the Feature Management
  baseline), PG-4.3 (the assistant publish), PG-5.3 (Model Armor on, and any switch-off),
  PG-8.3 (K2 at Tier C). Each has an announced window. PG-7.1's fixtures write the live assistant
  policy back unchanged and are witnessed with a before-and-after diff. Witnessed and not
  user-visible: PG-7.1a, one marked Agent Registry entry created and deleted under an
  `ENT_PROJECT_REPAIR_CORE` grant person 2 approves.
- Agent Registry: PG-7.1a runs setup/16 RG-5.7's write-alert drill and closes 04 PC-4.2's re-run
  line. No Tier C agent is registered: PG-6.3a records Google's reason
  (no manual registration is documented for a no-code agent) and PG-9.1 carries the row OPEN.
- DPO gates: PG-4.1 (prompt logging) and PG-5.1, PG-5.2 (sanitize logging, which writes raw prompts
  and responses) all wait on the one signed record `GE-CONTENT-LOGGING`.
- Full-set counterparts, for depth: [setup/05](../setup/05-gemini-enterprise-inventory.md) (run
  unchanged here), [setup/19](../setup/19-gemini-enterprise-import-and-baseline.md),
  [setup/20](../setup/20-gemini-enterprise-gateway-and-tier-c-gate.md) and the K7 half of
  [setup/18](../setup/18-model-armor-floor-spikes-and-kill-switch.md). Design:
  [../03-gemini-enterprise-environment.md](../03-gemini-enterprise-environment.md).
- Google facts: read on 2026-09-16, or cited from setup/19 and setup/20 (§Sources says which).
  Nothing was run against the tenant while writing.
- Consumes: `POV_TIER_R_RECORD` (04), because SD-13 (inherited) puts Tier C after Tier R; the
  names of 01, 02 and 03 listed in §Preconditions, including `ENT_PROJECT_REPAIR_CORE` and
  `NOTIF_CH_EMAIL_CORE` (03 PF-5.1, PF-7.3); `REGISTER_PATH`, `REGISTER_SCHEMA_PATH`,
  `MANUAL_PARSE_RECORD`, `RESERVED_NAMES_RECORD`, `AGENT_REGISTRY` and the registry write alert
  (04 PC-4.1, PC-4.2). The bare `TIER_R_RECORD` is never read here.
- Deviations: PV-D-01, PV-D-02, PV-D-10, PV-D-11, PV-D-13, PV-D-14, each written in full in
  [09](09-the-demonstration-deviations-and-the-hand-over.md).

---

## What this part builds

Tier C hires nobody new ([../01-hld.md](../01-hld.md) lines 153 to 165). This part is the fastest
honest result in the POV: the live Gemini Enterprise app brought under the platform, two no-code
agents admitted as register data rather than as clicks, and kill levers that have been pulled and
timed. Every artefact is the full build's artefact: the inventory files carry setup/05's names,
the working files carry setup/19's names, and the full build continues from them (§What the next
file needs).

| Result | Proven by | Step |
|---|---|---|
| A dated, read-only inventory of the live app before anything changes, with the retention floor | setup/05's fact sheet, gate lines `clear` | PG-1.1, PG-1.2 |
| `ge-admins@` and `ge-builders@`; admin work only through `ent-ge-admin`; no standing human admin on the project | a grant taken and revoked; the project policy read back | PG-2 |
| The project under `fld-gemini-enterprise` with the `agp-tier` tag inherited, after 14 clean dry-run days | parent and effective tag read back; the colleague's test question | PG-3 |
| Prompt logging off with the DPO's signature; agent sharing without admin approval **off**; grounding off; retention kept or raised, never lowered | GET diffs; the signed record; a witnessed publish | PG-4 |
| Sanitize logging (raw prompts and responses, 30 days, `platform-security@` readers) only under the DPO's signature | `GE-CONTENT-LOGGING` record | PG-4.1, PG-5.1 |
| Model Armor on, `eu` templates at the floor, the "Allow user interactions during Model Armor processing failure" toggle **off** | GET shows `FAIL_CLOSED`; sanitize entries | PG-5 |
| Two Tier C register rows, parsed by two people, shared only to named groups | `register/<agent_id>.yaml`; the parse file; the agents' `sharingConfig` | PG-6 |
| The Tier C agents' place in the Agent Registry, read from Google's documentation: no manual registration exists for a no-code agent, so none is made | the PG-6.3a record; an OPEN row of PG-9.1 | PG-6.3a |
| Three PL-10 alerts fired; the injection suite run with detection rate and false-block rate recorded | incidents; `INJECTION_SUITE_RECORD` | PG-7 |
| The registry write alert of 04 PC-4.2 proven: one marked repair write in `AGENT_REGISTRY` under a fresh `ent-project-repair-core` grant person 2 approves, the email within five minutes, the entry deleted, the audit log read | the drill record; `DR-P05-4` | PG-7.1a |
| K1, K2, K3 at Tier C and K7 on a tier folder, each timed; the token residual written as the one measured in 07 PW-6.5, never the design's 60 minutes | `KILL_DRILL_RECORD_C` | PG-8 |
| The POV's Tier C gate record with every open row named | `POV_TIER_C_RECORD` | PG-9 |

**Model Armor produces evidence, not a boundary.** It is a probabilistic screen; nothing here relies
on it to stop an action. What stops actions at Tier C is that its agents hold no credential and no
write path.

## Preconditions

- [ ] POV [01](01-conventions-and-variables.md): `~/.platform-env` and its helpers (`penv_set`,
  `need`, `exists_or_pending`, `penv_guard`, `checkpoint`, `evidence_add`, `confirm_manual`,
  `sitting_end`); `BUILD_LOG_DIR`, `EVIDENCE_REGISTER`, `DEVIATION_REGISTER`, `DRILL_CALENDAR`,
  `EVIDENCE_INTERIM_LOCATION`, `PLATFORM_REPO_DIR`, `REGION` (`europe-west1`), and the setup/01 names
  setup/05 reads: `GCLOUD_CONFIG_NAME`, `GE_LOCATION` (`eu`).
- [ ] POV [02](02-decisions-people-and-the-retrospective-baseline.md): PV-11 (AI Act class and
  purpose) and PV-12 (`MODEL_ID`) signed; `SECOND_HUMAN_EMAIL`; the DPO's address `DPO_CONTACT`
  (setup/03 DC-3.1's name).
- [ ] POV [03](03-foundation-folders-logging-and-floors.md): `DOMAIN` and `WORKSPACE_EDITION` (03 PF-1.1), `ORG_ID`, `SA_1_ADMIN`, `SA_2_ADMIN`,
  `FLD_GEMINI_ENTERPRISE`, `FLD_AGENTS_R_NONPROD`, `CORE_PROJECT`, `LOGGING_PROJECT`,
  `CICD_PROJECT`, `LOG_BUCKET_EVIDENCE`, the `agp-tier` tag bound on `fld-gemini-enterprise` with
  value `ge` (`TAG_KEY_TIER`), the floor record `FLOOR_RECORD`, the K7 files `K7_POLICY_DIR`,
  `POV_K7_FIRST_DRILL_RECORD` (03 PF-9.3), `GATES_DIR`, `PLATFORM_EVIDENCE_BUCKET`, the email
  channel to person 2 `NOTIF_CH_EMAIL_CORE` (03 PF-7.3), and the PAM
  catalogue `PAM_ENTITLEMENTS` holding at least `ENT_PLATFORM_POLICY`, `ENT_FOLDER_ADMIN`,
  `ENT_PAM_CATALOGUE_ORG`, `ENT_K7_HUMAN`, `ENT_K7_HUMAN_SCHEDULER` and `ENT_PROJECT_REPAIR_CORE`
  (setup/12 names; 03 PF-5.1). `ENT_PROJECT_REPAIR_CORE` is folder-scoped at `fld-platform-core`
  and carries `roles/agentregistry.admin` (setup/12 PA-4.2), the only lawful human path to write
  `AGENT_REGISTRY`; PG-7.1a reads that before it requests a grant.
  File 03's catalogue has no `ent-project-move` pair: this file creates it in PG-3.3 by setup/12
  PA-5.2 and retires it there by setup/19 GE-3.12. If 03 does not set these names, PG-0.1's `need`
  stops the sitting.
- [ ] POV [04](04-the-contract-register-agent-ids-and-schemas.md): `POV_TIER_R_RECORD` (SD-13:
  Tier C after Tier R), `REGISTER_PATH`, `REGISTER_SCHEMA_PATH`, `MANUAL_PARSE_RECORD` (the
  procedure of setup/16 RG-3.6 as the POV adopts it, PV-D-13), `RESERVED_NAMES_RECORD` (from 02),
  `AGENT_REGISTRY` (PC-4.1: `projects/<CORE_PROJECT>/locations/europe-west1`, no standing writer)
  and the registry write alert policy in `CORE_PROJECT` (PC-4.2, setup/16 RG-5.6), whose drill
  PC-4.2 hands to this file (PG-7.1a).
- [ ] `Assumption:` the app is live; if not, PG-1.1's stop rules open a decision record.
- [ ] A non-admin colleague (setup/19 §2 conditions) and two volunteer builders outside `ge-admins@`
  have agreed; the DPO has had both logging questions in writing for five business days: prompt
  and response logging on the engine (`sensitiveLoggingEnabled`), and Model Armor sanitize logging
  (`logSanitizeOperations`), which Google says "writes raw prompts and responses to Logging"
  (configure-logging page, read 2026-09-16).
- [ ] Workstation: `gcloud` (`beta`, for `gcloud beta projects move` in PG-3.3), `curl` 7.76+, `jq`, `yq`, `git`, `shasum`, `check-jsonschema`.

## People

| Role | Who (README §5) | Does | Present when |
|---|---|---|---|
| Operator | person 1, the platform owner, as `sa-1-admin@` in its own browser profile | every step; requests every grant | throughout |
| Second person | person 2, as `sa-2-admin@` | approves `ent-platform-policy`, the move pair and the `ent-project-repair-core` drill grant (PG-7.1a); witness at PG-3.3, PG-4.2, PG-4.3, PG-5.3, PG-7.1, PG-7.1a and PG-8.3 to PG-8.5; confirms the registry write alert email with its arrival time (PG-7.1a); approves and witnesses any Model Armor switch-off (PG-5.3 ROLLBACK); co-signs the manual parse (PG-6.1); reads the Tier C registry record (PG-6.3a); acknowledges the gate record | those steps |
| Person 3 | second operator and security reviewer | reads the weekly share record (PG-6.3); not mandatory in this file (PV-D-14) | weekly, 15 minutes |
| DPO | the address of `DPO_CONTACT` | signs `GE-CONTENT-LOGGING`, covering prompt logging and sanitize logging (PG-4.1) | PG-4.1 |
| Non-admin colleague | named in PG-0.2 | test questions; the injection suite; observes K1 and K2 | PG-2.3, PG-3.3, PG-4.3, PG-5.3, PG-7.2, PG-8 |
| Two volunteer builders | named in PG-0.2 | build the two agents and request their share | PG-6.2 |
| IT security desk | the business-hours contact (PV-D-10) | acknowledges the announced windows | PG-3.3, PG-4.2, PG-8.3 |

`Assumption:` hands-on about 2 days; elapsed 3 to 4 weeks, set by the 14-day dry run (PG-3.2, kept
because it protects today's users from the folder allow-list), the notices and the DPO.

## Rules for this file

- **The live app comes first** (setup/19 §4): grant before revoke, dry run before enforce, saved
  state and a colleague's test before any user-visible change, a five-business-day notice.
- **Names are the full build's**: setup/05's `GI` files, setup/19's `GE_DIR` and `ge_file` names,
  setup/README §5.2 variable spellings (README §7.2). The gate record is `POV_TIER_C_RECORD`, never
  `TIER_C_RECORD`: a POV record never satisfies a full-set gate whose conditions it lacks (README §7.3).
- **`CustomerPolicy` is written whole** and **every grant is revoked inside its step** (setup/19 §4);
  PAM refuses self-approval. No secret is printed; personal data stays under `restricted/`.
- **`ent-ge-admin` has no approval workflow** (SD-19, setup/12 PA-5.1), so it is not the second
  person's control. The POV keeps the entitlement exactly as the full build defines it, because the
  K1 and K2 levers must stay pullable by any operator without approval (absolute 6). Every other
  change made under it to the live app (PG-4.2, PG-4.3, PG-5.3, PG-7.1) is witnessed by person 2 at
  the screen, starts from a saved before-state, and is recorded with `confirm_manual`. Switching
  Model Armor off is a two-person act (PG-5.3 ROLLBACK). `Assumption:` a second, approval-gated
  entitlement for baseline changes is a design question for [12](../12-open-decisions.md), not a
  POV change, since it would add a name the full build does not have.
- **The Agent Registry is written by no model and no agent principal.** In the POV nobody holds a
  standing registry role (04 PC-4.1); a human write to `AGENT_REGISTRY` is lawful only as a repair
  under `ENT_PROJECT_REPAIR_CORE`, requested by the operator and approved by person 2 (setup/16
  RG-5.7). No agent principal is ever granted an `agentregistry` role: Google advises to "avoid
  granting these roles directly to agents" (roles page, read 2026-09-16).

---

## Steps

### PG-0 The sitting

#### PG-0.1 Open the sitting and check every input

- **WHO:** operator. Solo.
- **WHERE:** shell, `~/.platform-env` sourced; browser profile of `sa-1-admin@`.
- **ACTION:**
```bash
source ~/.platform-env
penv_guard
# consumed names, full-set spellings only (README §7.2); the move pair is created in PG-3.3
need BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER DRILL_CALENDAR EVIDENCE_INTERIM_LOCATION PLATFORM_REPO_DIR REGION DOMAIN GCLOUD_CONFIG_NAME WORKSPACE_EDITION ORG_ID SA_1_ADMIN SA_2_ADMIN SECOND_HUMAN_EMAIL DPO_CONTACT MODEL_ID FLD_GEMINI_ENTERPRISE FLD_AGENTS_R_NONPROD CORE_PROJECT LOGGING_PROJECT CICD_PROJECT LOG_BUCKET_EVIDENCE TAG_KEY_TIER FLOOR_RECORD K7_POLICY_DIR POV_K7_FIRST_DRILL_RECORD GATES_DIR PLATFORM_EVIDENCE_BUCKET PAM_ENTITLEMENTS POV_TIER_R_RECORD REGISTER_PATH REGISTER_SCHEMA_PATH MANUAL_PARSE_RECORD RESERVED_NAMES_RECORD ENT_PLATFORM_POLICY ENT_FOLDER_ADMIN ENT_PAM_CATALOGUE_ORG ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER ENT_PROJECT_REPAIR_CORE NOTIF_CH_EMAIL_CORE AGENT_REGISTRY
penv_set GE_LOCATION eu
test "$GE_LOCATION" = eu || echo "STOP: GE_LOCATION is not eu (SD-21)"
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-11 PV-12 && echo "PV-11 PV-12 signed"
gcloud auth login "$SA_1_ADMIN"
gcloud auth list --filter=status:ACTIVE --format='value(account)'
checkpoint "SITTING-$(date -u +%Y%m%d%H%M)" START - - "POV 05 Gemini Enterprise and Tier C"
checkpoint PG-0.1 DONE
```
- **VERIFY:** `penv_guard` silent; `need` returns 0; no `STOP`; `PV-11 PV-12 signed`; the active
  account is exactly `SA_1_ADMIN`. `penv_set GE_LOCATION eu` is a no-op if file 01 already set it,
  and setup/01 PR-2.3 later verifies the same value.
- **ROLLBACK:** none needed; `sitting_end` closes the sitting (PG-9.2).
- **EVIDENCE:** the checkpoint lines. E-xx: none. TISAX 4.1.2.

#### PG-0.2 Name the people and create the helpers

- **WHO:** operator. Solo.
- **WHERE:** shell.
- **ACTION:** run setup/19 GE-0.3's ACTION unchanged: it creates `$BUILD_LOG_DIR/ge-baseline`, its
  ignored `restricted/` directory and `ge-helpers.sh` (`ge_file`, `ge_latest`, `ge_call`, `pam_fq`,
  `pam_grant`, `pam_active`, `pam_revoke`, `ma_eu`). It runs after PG-1.1, because the helper file
  reads `GEMINI_PROJECT` and `GEMINI_APP_ID`; until then only the people are recorded:
```bash
penv_set GE_WITNESS "$SECOND_HUMAN_EMAIL"
test "$GE_WITNESS" != "$SA_1_ADMIN" || echo "STOP: the witness cannot be the operator"
mkdir -p "$BUILD_LOG_DIR/records"
printf '# POV 05 people, %s\n\n| Role | Name, team, remit | Agreed on |\n|---|---|---|\n| non-admin colleague | | |\n| builder 1 | | |\n| builder 2 | | |\n| witness (person 2) | | |\n' "$(date -u +%F)" > "$BUILD_LOG_DIR/records/$(date -u +%F)-PG-0.2-people-v1.md"
checkpoint PG-0.2 DONE
```
  Fill it by hand (name, team, remit). No `GE_ROLLBACK_OPERATOR`: the operator stays reachable for the
  hour after each publish, person 2 witnessing (PV-D-14).
- **VERIFY:** four filled rows; `need GE_WITNESS`; after PG-1.1, GE-0.3's own VERIFY for every `ENT_*`
  already set (`ENT_GE_ADMIN` and the repair entitlement come in PG-2.2).
- **ROLLBACK:** none needed.
- **EVIDENCE:** `evidence_add PG-0.2 people E-08 4.1.2 "build-log:records/$(date -u +%F)-PG-0.2-people-v1.md"`.

### PG-1 The read-only inventory

#### PG-1.1 Run setup/05 unchanged

- **WHO:** operator, with the account that holds the Gemini Enterprise Admin role today. Solo.
- **WHERE:** as each GI step says (shell, Cloud console, Admin console).
- **ACTION:** execute [setup/05](../setup/05-gemini-enterprise-inventory.md) GI-0.1 to GI-10.3 exactly
  as written: read-only, about three hours, no factory, its five stop rules applied. Then:
```bash
facts="$(ls -t "$GE_INVENTORY_DIR"/*-GI-10.2-facts-v*.md | head -1)"
grep -E '^(ORG|LOCATION|SECOND-APP|EDITION|IDP): ' "$facts"
grep -qE '^(ORG|LOCATION|SECOND-APP|EDITION): STOP' "$facts" && echo "STOP: inventory gate not clear" || echo "inventory gate clear"
need GEMINI_PROJECT GEMINI_PROJECT_NUMBER GE_CURRENT_PARENT GEMINI_APP_ID GEMINI_APP_LOCATION GE_EDITION GE_RETENTION_CURRENT_DAYS GE_INVENTORY_DIR
checkpoint PG-1.1 DONE - "build-log:$(basename "$facts")"
```
  Now run setup/19 GE-0.3 (PG-0.2).
- **VERIFY:** `inventory gate clear`; `need` passes; setup/05 §7 ticked; retention not touched.
- **ROLLBACK:** none needed; nothing was written to the cloud.
- **EVIDENCE:** setup/05's rows (E-11, E-05). The inventory is referenced only by the directory
  `GE_INVENTORY_DIR` (setup/05 GI-0.2); no file-path variable is kept beside it.

#### PG-1.2 EU-only data stores, and the connector allow-list committed

- **WHO:** operator writes; person 2 reviews the pull request.
- **WHERE:** shell; platform repository.
- **ACTION:** the data-store location check and the committed allow-list the design names
  ([../03-gemini-enterprise-environment.md](../03-gemini-enterprise-environment.md) §12:
  first-party Google Workspace sources only).
```bash
for loc in us global; do jq -r '.[].dataStores[]?.name' "$(ls -t "$GE_INVENTORY_DIR"/*-GI-7.2-datastores-$loc-v*.json | head -1)"; done | tee "$(ge_file PG-1.2 non-eu-datastores txt)"
mkdir -p "$PLATFORM_REPO_DIR/register"
printf '# Connector allow-list (03 section 12); one row per allowed dataSource id\nallowed: []\n# add rows only with a supplier row and a register row that names them\n' > "$PLATFORM_REPO_DIR/register/gemini-connectors.yaml"
git -C "$PLATFORM_REPO_DIR" switch -c pg-1-2-connectors && git -C "$PLATFORM_REPO_DIR" add register/gemini-connectors.yaml && git -C "$PLATFORM_REPO_DIR" commit -m "PG-1.2 connector allow-list (03 s12)" && git -C "$PLATFORM_REPO_DIR" push -u origin pg-1-2-connectors
```
  Fill `allowed:` from GI-7.3's keep decisions. A `us` or `global` store is a stop for PG-6 and a
  decision record (stores do not move, SD-21). Connectors outside the list keep running until setup/19
  GE-4.1; the managed constraints (GE-4.2 to GE-4.7) are an open row of PG-9.1.
- **VERIFY:** the `non-eu-datastores` file is empty, or the decision record exists and PG-6.1's rows
  name only `eu` stores; the pull request is merged by two humans.
- **ROLLBACK:** revert by pull request.
- **EVIDENCE:** `evidence_add PG-1.2 eu-datastores E-11 7.1.2 "repo:register/gemini-connectors.yaml@<commit>"`.

### PG-2 Groups and administration through PAM

#### PG-2.1 Create `ge-admins@` and `ge-builders@`

- **WHO:** operator as `sa-1-admin@` (Groups administrator). Solo.
- **WHERE:** shell.
- **ACTION:** both are security groups (full-set group names, setup/06 and
  [../03-gemini-enterprise-environment.md](../03-gemini-enterprise-environment.md) §4).
```bash
for g in ge-admins ge-builders; do gcloud identity groups create "${g}@${DOMAIN}" --organization="$DOMAIN" --group-type=security --display-name="$g" --description="agentic platform POV 05 PG-2.1"; done
penv_set GRP_GE_ADMINS "ge-admins@${DOMAIN}"
penv_set GRP_GE_BUILDERS "ge-builders@${DOMAIN}"
gcloud identity groups memberships add --group-email="$GRP_GE_ADMINS" --member-email="$SA_1_ADMIN" --roles=MEMBER
gcloud identity groups memberships add --group-email="$GRP_GE_ADMINS" --member-email="$SA_2_ADMIN" --roles=MEMBER
# builders: the two volunteers of PG-0.2, typed from the people file
gcloud identity groups memberships add --group-email="$GRP_GE_BUILDERS" --member-email="<builder 1>" --roles=MEMBER
gcloud identity groups memberships add --group-email="$GRP_GE_BUILDERS" --member-email="<builder 2>" --roles=MEMBER
```
- **VERIFY:** `gcloud identity groups describe "$GRP_GE_ADMINS" --format='value(labels)'` includes
  `cloudidentity.googleapis.com/groups.security`; `ge-admins@` lists exactly the two admin accounts;
  `ge-builders@` lists the two builders and neither admin account.
- **ROLLBACK:** `gcloud identity groups delete <group email>` while no binding names the group.
- **EVIDENCE:** `evidence_add PG-2.1 ge-groups E-08 4.1.3 "build-log:checkpoints.tsv"`.

#### PG-2.2 Create and prove `ent-ge-admin` and the tenant-app repair entitlement

- **WHO:** operator as PAM administrator (`platform-owners@`). Solo.
- **WHERE:** shell.
- **ACTION:** `ent-ge-admin` as setup/12 PA-5.1: `agentspaceAdmin` on `GEMINI_PROJECT`, one hour,
  requester `ge-admins@`, **no approval at Tier C, justification required** (SD-19). Then
  `ent-project-repair-tenant-app` by setup/19 GE-2.3 unchanged.
```bash
f="$(ge_file PG-2.2 ent-ge-admin yaml)"
printf 'privilegedAccess:\n  gcpIamAccess:\n    resourceType: cloudresourcemanager.googleapis.com/Project\n    resource: //cloudresourcemanager.googleapis.com/projects/%s\n    roleBindings:\n    - role: roles/discoveryengine.agentspaceAdmin\nmaxRequestDuration: 3600s\neligibleUsers:\n- principals:\n  - group:%s\nrequesterJustificationConfig:\n  unstructured: {}\n' "$GEMINI_PROJECT" "$GRP_GE_ADMINS" > "$f"
gcloud pam entitlements create ent-ge-admin --project="$GEMINI_PROJECT" --location=global --entitlement-file="$f"
penv_set ENT_GE_ADMIN "projects/${GEMINI_PROJECT}/locations/global/entitlements/ent-ge-admin"
GRANT="$(pam_grant "$ENT_GE_ADMIN" 1800s "POV 05 PG-2.2 one-grant test")"; pam_active "$GRANT"
ge_call GET "${GE_APP}:getIamPolicy" > /dev/null && echo "admin read OK under grant"
pam_revoke "$GRANT" "PG-2.2 test done"
```
- **VERIFY:** `gcloud pam entitlements describe "$ENT_GE_ADMIN" --format=json | jq '{approval: (.approvalWorkflow // "none"), max: .maxRequestDuration}'`
  prints `"none"` and `"3600s"`; `admin read OK under grant`; the grant then reads `REVOKED` or
  `ENDED`; setup/19 GE-2.3's VERIFY passes (exactly one `ent-project-repair-` entitlement).
- **ROLLBACK:** revoke non-terminal grants, then `gcloud pam entitlements delete "$ENT_GE_ADMIN" --async`
  (state `DELETING`, then `NOT_FOUND`; do not re-run the delete).
- **EVIDENCE:** `evidence_add PG-2.2 ent-ge-admin E-08 4.1.3 "build-log:ge-baseline/$(basename "$f")"`.
  Add both ids to `PAM_ENTITLEMENTS`.

#### PG-2.3 Remove standing admin and basic roles, one at a time

- **WHO:** operator under `ENT_PROJECT_REPAIR_TENANT_APP`; the non-admin colleague after each removal.
- **WHERE:** shell.
- **ACTION:** setup/19 GE-5.1 (prove `ent-ge-admin` and list standing admins) as written, then
  setup/19 GE-5.8 **restricted to** `agentspaceAdmin`, `discoveryengine.admin`, `owner` and `editor`
  held by humans or groups, one removal, 15 minutes and a colleague's question at a time. User roles
  stay: moving users to `ge-users@` (GE-5.2 to GE-5.9) is an open row of PG-9.1, the step most able
  to cut a user off and not needed to prove Tier C.
- **VERIFY:** after the last removal,
  `gcloud projects get-iam-policy "$GEMINI_PROJECT" --format=json | jq -r '.bindings[] | select(.role|test("^roles/(discoveryengine\\.(agentspaceAdmin|admin)|owner|editor)$")) | .members[]' | grep -v 'gserviceaccount.com$'`
  prints nothing; every removal has its saved `project-iam-before-removal` file and a colleague line.
- **ROLLBACK:** per removal, `gcloud projects add-iam-policy-binding "$GEMINI_PROJECT" --member=<member> --role=<role> --condition=None`
  from the saved file.
- **EVIDENCE:** `evidence_add PG-2.3 standing-admins-removed E-06 4.1.3 "build-log:ge-baseline/<queue file>"`.

### PG-3 The project under the platform

#### PG-3.1 Manifest, deviation row, additive services and contacts

- **WHO:** operator; person 2 reviews the manifest pull request.
- **WHERE:** shell; platform repository.
- **ACTION:** setup/19 GE-2.1, GE-2.2, GE-2.4, GE-2.5 and GE-2.7 as written, with two changes of
  identifier only: the deviation row id is `BD-P05-1` (not `BD-19-1`, which the full build still
  opens), and it cites PV-D-01. GE-2.6, the Terraform import, is BLOCKED:

> **BLOCKED**: Needs: the factory `tenant-app` module (B-01). Commit it in: `PLATFORM_REPO_REMOTE`,
> `factory/modules/tenant-app`. Unblocked by: a commit with green CI. Gate waiting: none in the POV;
> the full build's Tier W gate closes `BD-P05-1` with an import that plans no changes. Until then:
> `checkpoint PG-3.1 BLOCKED - - "B-01 tenant-app import (GE-2.6)"`. `Assumption:` 2 to 3
> engineer-days for this one module. The hand-built project keeps the manifest's names and labels,
> so the import should show no change (PV-D-01).

- **VERIFY:** setup/19's VERIFY lines for GE-2.1, GE-2.2 (with `BD-P05-1`), GE-2.4, GE-2.5 and GE-2.7
  pass; the register has one `| BD-P05-1 |` row.
- **ROLLBACK:** as each cited step.
- **EVIDENCE:** as each cited step (E-05, TISAX 5.2.1).

#### PG-3.2 The allow-list union and 14 days of project dry run

- **WHO:** operator; person 2 approves the `ent-platform-policy` grant.
- **WHERE:** shell.
- **ACTION:** setup/19 GE-3.1 to GE-3.4 as written: the governed-services union with its terminal
  assertions, the committed folder file, the project-level `dryRunSpec` with
  `--update-mask=policy.dry_run_spec`, and 14 days with a positive control before zero denials is
  accepted. Start this on the day PG-1.1 is clear; PG-4 and PG-5 do not wait for it.
- **VERIFY:** setup/19 GE-3.4's VERIFY: at least 14 days and 10 business days, a positive control
  with at least one policy audit entry, and zero `DENIED`/`ALLOWED` pairs.
- **ROLLBACK:** as setup/19 GE-3.3 (delete the project dry-run policy).
- **EVIDENCE:** the final read and the positive control, filed together (E-06, TISAX 5.2.6).

#### PG-3.3 Move into `fld-gemini-enterprise` in an announced window

- **WHO:** operator requests both move grants; **person 2 approves them and is on the call**; the
  colleague tests; the desk acknowledges.
- **WHERE:** shell; the colleague's web app.
- **ACTION:** first the move pair, which file 03's catalogue (PF-5.1) does not create. Run setup/12
  PA-2.1's `catalogue.py` for the two rows `ent-project-move-src` and `ent-project-move-dst` only
  (setup/12 §3 row: `roles/resourcemanager.projectMover`, one hour, requester `platform-owners@`,
  approver the second human), merged by two humans; then setup/12 PA-5.2 as written, the operator
  creating under an `ENT_FOLDER_ADMIN` grant (and `ENT_PAM_CATALOGUE_ORG` when `GE_CURRENT_PARENT`
  is `organizations/...`), each grant approved by person 2. `gcloud pam entitlements create` takes
  `--folder` or `--organization` for the parent it names (gcloud reference, updated 2026-05-27).
```bash
need GE_CURRENT_PARENT FLD_GEMINI_ENTERPRISE ENT_FOLDER_ADMIN ENT_PAM_CATALOGUE_ORG
# setup/12 PA-5.2's ACTION here, unchanged; then:
need ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST
for e in "$ENT_PROJECT_MOVE_SRC" "$ENT_PROJECT_MOVE_DST"; do gcloud pam entitlements describe "$e" --format=json | jq -r '[.name, (.approvalWorkflow != null), .maxRequestDuration] | @tsv'; done
```
  Then setup/19 GE-3.5 to GE-3.12 as written: the folder's live allow-list while the folder is
  empty (with its empty-list guard), `analyze-move`, re-grants, a five-business-day notice, the
  before state, `gcloud beta projects move`, labels from the manifest (`tier=ge`), the after checks,
  and the move entitlements retired. Name the K2 window of PG-8.3 in the same notice if its date is
  known. Then read the inherited tag:
```bash
gcloud resource-manager tags bindings list --parent="//cloudresourcemanager.googleapis.com/projects/${GEMINI_PROJECT_NUMBER}" --effective --format=json | tee "$(ge_file PG-3.3 effective-tags json)" | jq -r '.[] | [.namespacedTagKey, .namespacedTagValue] | @tsv'
```
- **VERIFY:** setup/12 PA-5.2's VERIFY before the move (both entitlements print `true` for an
  approval workflow and `3600s`; both one-grant tests `approved` by person 2, never by the operator);
  setup/19 GE-3.11's VERIFY (parent is the folder, empty engine diff, a `StreamAssist`
  entry in `LOGGING_PROJECT`, both colleague answers); the effective tags include the `agp-tier`
  key with value `ge`; the move entitlements read `NOT_FOUND` after their deletion completes.
- **ROLLBACK:** setup/19 GE-3.10's move back, within the same grants and window. Before the move,
  setup/12 PA-5.2's ROLLBACK (revoke both grants, delete both entitlements).
- **EVIDENCE:** as setup/19 GE-3.10 to GE-3.12 (E-06, TISAX 4.1.3); the tag read
  `evidence_add PG-3.3 effective-tags E-05 5.2.1 "build-log:ge-baseline/<file>"`.

#### PG-3.4 `discoveryengine` admin-read and data-read audit logs

- **WHO:** operator under `ENT_PROJECT_REPAIR_TENANT_APP`.
- **WHERE:** shell.
- **ACTION:** setup/19 GE-4.8 and GE-4.9 as written (etag-preserving `auditConfigs` merge, a `GetEngine`
  entry read in `LOGGING_PROJECT`). Eve (file 06) reads these to watch the app's human administrators.
- **VERIFY:** setup/19 GE-4.9's VERIFY.
- **ROLLBACK:** set the saved policy back with its new etag.
- **EVIDENCE:** as setup/19 GE-4.8 (E-06, TISAX 5.2.4).

### PG-4 Baseline settings

#### PG-4.1 The DPO's record for both content logs, and prompt logging off

- **WHO:** operator writes; the DPO signs; operator under `ENT_GE_ADMIN` applies.
- **WHERE:** platform repository `decisions/`; shell.
- **ACTION:** setup/19 GE-6.1 to GE-6.3 as written: before GETs; `decisions/<date>-ge-sensitive-logging-off.md`
  in the decision-record format, signed by the DPO; `sensitiveLoggingEnabled` set to `false`.
  **One addition to setup/19, not a POV deviation:** the full build owes the same signature, which
  setup/19 GE-6.2 does not ask for (raised in §Unverified). The same record carries a second decision, and its
  tracker row id is `GE-CONTENT-LOGGING`, because setup/19 GE-7.1 and GE-7.2 turn on Model Armor
  sanitize logging for every user of the live app, and Google states that this "writes raw prompts
  and responses to Logging. This data might include sensitive user data, personally identifiable
  information (PII), or confidential information" (configure-logging page, updated 2026-09-10). Add
  the row `| GE-CONTENT-LOGGING | Gemini Enterprise content logging | <record> | PG-4.1, PG-5.1, PG-5.2 | DPO, platform owner | |`
  to `decisions/TRACKER.md` in the setup/03 §4 format. The second decision's Values table names:

| Variable | Value the DPO signs |
|---|---|
| `GE_SANITIZE_LOGGING` | `on` or `off` |
| `GE_SANITIZE_LOG_BUCKET` | `ge-content-logs`, in `REGION`, project `GEMINI_PROJECT` |
| `GE_SANITIZE_LOG_RETENTION_DAYS` | `30` |
| `GE_SANITIZE_LOG_READERS` | `platform-security@` through the `ge-sanitize-view` log view only; the operator reads it only in PG-7.2 |
| `GE_SANITIZE_LOG_PURPOSE` | injection-suite evidence (PG-7.2) and incident triage; no per-user analysis |

```bash
rec="$(ls -t "$PLATFORM_REPO_DIR"/decisions/*-ge-sensitive-logging-off.md | head -1)"
"$PLATFORM_REPO_DIR/tools/decision-check.sh" "$rec"
"$PLATFORM_REPO_DIR/tools/decision-need.sh" GE-CONTENT-LOGGING
v="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" GE-CONTENT-LOGGING GE_SANITIZE_LOGGING)" && penv_set GE_SANITIZE_LOGGING "$v"
```
- **VERIFY:** `tools/decision-check.sh` prints `OK` for the record; `decision-need.sh` prints
  `SIGNED GE-CONTENT-LOGGING`; `GE_SANITIZE_LOGGING` is `on` or `off`; the engine GET shows
  `sensitiveLoggingEnabled` false or absent and `observabilityEnabled` unchanged. If the DPO says no
  to switching prompt logging off, that half is `N/A` with the record's path and the value stays as
  found.
- **ROLLBACK:** a superseding DPO record, then the PATCH with GE-6.1's value.
- **EVIDENCE:** the record (E-12, TISAX 7.1.2) and the engine GET;
  `evidence_add PG-4.1 ge-content-logging E-12 7.1.2 "repo:decisions/<file>@<commit>"`.

#### PG-4.2 Feature Management: admission by register, builders limited

- **WHO:** operator under `ENT_GE_ADMIN`; person 2 reviews the file **and witnesses the change at
  the screen**; the IT security desk acknowledged the window. **User-visible**: production users may
  be using features this step switches off.
- **WHERE:** platform repository; Google Cloud console → **Gemini Enterprise** → the app →
  **Configurations** → **Feature Management**.
- **ACTION:** preconditions, in order: setup/19 GE-6.1's before GETs exist (they are the rollback
  source); a notice named the window and each feature being switched off at least five business
  days ahead (the PG-3.3 notice may carry it), saved to `EVIDENCE_INTERIM_LOCATION`; person 2 is on
  the call.
```bash
E0="$(ge_latest "$GE_DIR" GE-6.1-engine-before json)"; test -s "$E0" || echo "STOP: GE-6.1 before-state missing"
jq -S '.features' "$E0" > "$(ge_file PG-4.2 features-before json)"
confirm_manual PG-4.2 "Person 2: type the notice's message id for this Feature Management window"
```
  Then setup/19 GE-6.4 as written, committing `register/gemini-features.yaml` with the
  values of [../03-gemini-enterprise-environment.md](../03-gemini-enterprise-environment.md) §8,
  person 2 reading each toggle's new state aloud before **Save**. The rows this POV depends on:

| Console toggle (Google's name) | Value | Why it matters here |
|---|---|---|
| **Enable agent sharing without admin approval** | **off** | "users on your team can share and use agents ... without administrator approval" when on; off, every share is a request an app administrator reviews, so admission is a register row, not a click |
| Enable agent sharing | on | builders request shares; nothing is shared without review |
| Enable End Users to share with Groups | on | shares go to groups, never to individuals |
| Enable chat agents / Enable workflows | on | the two Tier C agents; also the K2 lever of PG-8.3 |
| Enable model selector | off | the model is the register's `model_pin` |
| Enable session sharing, memory and customization, Canvas, projects, image and video generation, skills | off | as 03 §8 |

  **Builders are limited by review, not by a toggle.** The toggles are per app and `agentspaceUser` holds
  `agents.create` (setup/20 X-GE-16), so anyone licensed can build a private agent; only an agent with a
  merged row and a `ge-builders@` owner is ever shared (PG-6.2). Private agents are counted (PG-6.3).
- **VERIFY:** `STOP` not printed; `CONFIRMED PG-4.2`; setup/19 GE-6.4's GET diff equals the file;
  the two rows with no `features` key (including agent sharing without admin approval) have dated
  screenshots; the colleague's test question is answered after the save.
- **ROLLBACK:** set the toggles back to the saved `PG-4.2-features-before` map (GE-6.1's
  `features`), person 2 witnessing, and re-GET until it equals that file.
- **EVIDENCE:** as setup/19 GE-6.4 (E-05, TISAX 5.2.1), with the notice, the before file and person 2
  named as witness.

#### PG-4.3 Witnessed publish: grounding off, retention kept or raised

- **WHO:** operator under `ENT_GE_ADMIN`; **person 2 witnesses at the screen**; the operator stays
  reachable for the hour after (PV-D-14).
- **WHERE:** console → the app → **Configurations** → **Assistant**.
- **ACTION:** setup/19 GE-6.5 and GE-6.6 as written: notice gate, the terminal keep-or-raise guard that
  alone writes `GE_RETENTION_TARGET`, grounding off, both values read aloud, **Save and publish**.
  GE-6.6's `need GE_ROLLBACK_OPERATOR` becomes `confirm_manual PG-4.3 "$SA_1_ADMIN"` (PV-D-14).
  Retention is **never** reduced: GE-6.7 stays BLOCKED and is not reached. Not Plus: `N/A` under
  GE-6.5's decision record.
- **VERIFY:** setup/19 GE-6.6's VERIFY; `GE_RETENTION_TARGET` is at least `GE_RETENTION_CURRENT_DAYS`.
- **ROLLBACK:** grounding toggled back and published by the operator; a raised retention may be set
  back to its earlier value. A lower value is never set.
- **EVIDENCE:** as setup/19 GE-6.6 (E-12, TISAX 7.1.2), with person 2 named as witness.

### PG-5 Model Armor on the app

#### PG-5.1 The content-log bucket for sanitize entries

- **WHO:** operator under `ENT_PROJECT_REPAIR_TENANT_APP`.
- **WHERE:** shell.
- **ACTION:** gate first: sanitize logging writes raw prompts and responses of real employees, so
  nothing here runs without the DPO's signed record of PG-4.1.
```bash
"$PLATFORM_REPO_DIR/tools/decision-need.sh" GE-CONTENT-LOGGING || echo "STOP: GE-CONTENT-LOGGING unsigned"
test "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" GE-CONTENT-LOGGING GE_SANITIZE_LOG_RETENTION_DAYS)" = 30 || echo "STOP: signed retention is not 30"
need GE_SANITIZE_LOGGING
```
  If `GE_SANITIZE_LOGGING` is `off`, this step is `N/A` with the record's path. Otherwise setup/19
  GE-7.1 as written: `ge-content-logs` in `REGION`, 30 days, sink, `_Default` exclusion, view for
  `platform-security@`; it exists before sanitize logging, which carries prompts.
- **VERIFY:** no `STOP`; setup/19 GE-7.1's VERIFY (`30 ACTIVE`; the exclusion listed); the view's
  IAM names only the readers `GE_SANITIZE_LOG_READERS` signed.
- **ROLLBACK:** as setup/19 GE-7.1.
- **EVIDENCE:** as setup/19 GE-7.1 (E-06, TISAX 5.2.4).

#### PG-5.2 The template pair in `eu`, at the floor

- **WHO:** operator under `ENT_PROJECT_REPAIR_TENANT_APP` (`roles/modelarmor.admin`).
- **WHERE:** shell.
- **ACTION:** gate first:
```bash
"$PLATFORM_REPO_DIR/tools/decision-need.sh" GE-CONTENT-LOGGING || echo "STOP: GE-CONTENT-LOGGING unsigned"
need GE_SANITIZE_LOGGING
```
  setup/19 GE-7.2 as written: `ge-console-standard-prompt` and `-response` in `eu` (an EU
  app maps to the EU Model Armor multi-region; regions cannot change later), with sanitize logging
  **only when `GE_SANITIZE_LOGGING` is `on`**; when it is `off`, drop the flag
  `--template-metadata-log-sanitize-operations` from both creates, and PG-7.2 counts refusals from
  the colleague's notes instead of the sanitize log (recorded as such). It
  sets the one variable
  `penv_set GE_ARMOR_TEMPLATE "projects/${GEMINI_PROJECT}/locations/eu/templates/ge-console-standard"`;
  the two templates are `${GE_ARMOR_TEMPLATE}-prompt` and `${GE_ARMOR_TEMPLATE}-response`, and no
  second variable names either. Then compare with the floor:
```bash
ma_eu model-armor templates describe ge-console-standard-prompt --location=eu --project="$GEMINI_PROJECT" --format=json > "$(ge_file PG-5.2 prompt-template json)"
ma_eu model-armor templates describe ge-console-standard-response --location=eu --project="$GEMINI_PROJECT" --format=json > "$(ge_file PG-5.2 response-template json)"
grep -n 'ge\|Tier C\|fld-gemini-enterprise' "$FLOOR_RECORD" | head -20
```
- **VERIFY:** no `STOP`; both describes show `logSanitizeOperations` equal to the signed value
  (`true` for `on`; `false` or absent for `off`), both filters enabled and a name
  under `locations/eu`; every filter the floor record names for this folder is present at or above
  its level. A create refused by the floor is recorded and the template raised, never the floor
  lowered.
- **ROLLBACK:** delete both templates while no assistant names them.
- **EVIDENCE:** `evidence_add PG-5.2 ge-console-templates E-06 5.2.6 "build-log:ge-baseline/<files>"`.
  E-06 is the closest row of setup/01 §7.2 (logging configuration: the templates carry sanitize
  logging); E-15 is the Art. 50 block and does not apply.

#### PG-5.3 Model Armor on, failure toggle off

- **WHO:** operator under `ENT_GE_ADMIN`; **person 2 witnesses**; users told in the PG-3.3 notice,
  or a new one five business days ahead, that injection-like questions may be refused and that an
  outage of the screen blocks the assistant.
- **WHERE:** console → **Gemini Enterprise** → the app → **Configurations** → **Assistant**; shell.
- **ACTION:** in the console, click **Enable Model Armor**; enter the resource names
  `${GE_ARMOR_TEMPLATE}-prompt` and `${GE_ARMOR_TEMPLATE}-response`; turn **Allow user interactions
  during Model Armor processing failure** to the **off** position; person 2 reads the two names and
  the toggle state aloud; **Save and publish**. Then assert by GET (setup/19 GE-7.4):
```bash
date -u +%FT%TZ > "$GE_DIR/armor-on-time.txt"
ge_call GET "${GE_APP}/assistants/default_assistant" | tee "$(ge_file PG-5.3 assistant-after json)" | jq -e --arg p "${GE_ARMOR_TEMPLATE}-prompt" --arg r "${GE_ARMOR_TEMPLATE}-response" '.customerPolicy.modelArmorConfig | (.failureMode == "FAIL_CLOSED" or .failureMode == null) and .userPromptTemplate == $p and .responseTemplate == $r'
diff <(jq -S '.customerPolicy | del(.modelArmorConfig)' "$(ge_latest "$GE_DIR" GE-6.1-assistant-before json)") <(jq -S '.customerPolicy | del(.modelArmorConfig)' "$(ge_latest "$GE_DIR" PG-5.3-assistant-after json)")
```
  Google: "If the FAIL_MODE is not defined, FAIL_CLOSED is the default mode". The console replaces
  setup/19 GE-7.3's PATCH so the toggle itself is seen off; the GET asserts the same state.

  **This is evidence, not a boundary.** Model Armor is a probabilistic screen; a prompt it misses is
  not refused, and no control in this POV depends on it refusing one.
- **VERIFY:** `jq -e` prints `true`; the `diff` prints nothing (banned phrases and data protection
  policy untouched); the colleague's benign test question is answered. The unreachable-template
  test is never run on the production app (setup/20 GG-2.5 runs it on a throwaway app; open row).
- **ROLLBACK:** switching Model Armor off removes the tier's floor (absolute 5), so it is a
  **two-person act**, never the operator alone: an incident is open; person 2 approves in writing
  (a reply naming the incident id, the reason, the re-enable owner's role, and a dated re-enable deadline no later than the next business day) and witnesses at
  the screen; then the operator turns **Enable Model Armor** off in the same tab and publishes.
```bash
confirm_manual PG-5.3-ROLLBACK "Person 2: type the incident id your written approval names"
ge_call GET "${GE_APP}/assistants/default_assistant" > "$(ge_file PG-5.3 assistant-armor-off json)"
printf '| %s | Model Armor off | incident <id> | approved and witnessed: person 2 | re-enable owner <role> | by <date> |\n' "$(date -u +%FT%TZ)" >> "$BUILD_LOG_DIR/records/$(date -u +%F)-PG-5.3-armor-off-v1.md"
```
  `pl10-assistant-update` (PG-7.1) fires on the `UpdateAssistant` entry and its email must reach
  person 2 (PG-7.1 VERIFY); Eve (file 06) also reads that entry. Until PG-7.1 exists, person 2's
  presence is the only control, so PG-7.1 is built in the same week as this step. Turning the
  failure toggle on is never a rollback: it is a PAM act with an incident reference (06 §3.5), under
  the same two-person rule.
- **EVIDENCE:** `evidence_add PG-5.3 model-armor-fail-closed E-06 5.2.6 "build-log:ge-baseline/<assistant-after>"`;
  dated screenshots of the tab before and after. E-06 as PG-5.2, the closest row of setup/01 §7.2.

### PG-6 Two Tier C agents admitted through the register

#### PG-6.1 Two register rows and the signed manual parse

- **WHO:** each builder writes the purpose; operator writes the rows; **person 2 signs the parse**;
  the operator never signs it (setup/16 RG-3.6).
- **WHERE:** shell; platform repository; the pull request page.
- **ACTION:** `Assumption:` two read-only no-code helpers over first-party `eu` stores, chosen by the
  platform owner; ids are permanent join keys, checked against reserved names. One file, one row,
  `tier: C`; the schema forces `verifier: none`, `metric_pack: light`, `privilege: none`, `READ` (RG-2.2).
```bash
A1="<agent_id 1>"; A2="<agent_id 2>"
for a in "$A1" "$A2"; do case "$a" in *'<'*) echo "STOP: set the agent ids";; esac; grep -qiw -- "$a" "$RESERVED_NAMES_RECORD" && echo "STOP: $a is reserved"; done
AI_CLASS="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-11 AI_ACT_CLASS_TIER_C)"; AI_ROLE="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-11 AI_ACT_ROLE)"
for a in "$A1" "$A2"; do cat > "$PLATFORM_REPO_DIR/$REGISTER_PATH/$a.yaml" <<EOF
agent_id: $a
rows:
- display_name: "<display name>"
  purpose: "<the signed intended purpose, at least 40 characters, from PV-11>"
  owner_group: "$a-owners@$DOMAIN"
  cost_centre: "<cost centre>"
  tier: C
  risk_class: READ
  data_classes: [content]
  tisax_class: "<TISAX class, from the ISMS>"
  ai_act_class: $AI_CLASS
  ai_act_role: $AI_ROLE
  model_pin: "$MODEL_ID"
  armor_template: "${GE_ARMOR_TEMPLATE}-prompt"
  supplier_rows: ["google-gemini-enterprise"]
  publish_to_gemini: true
  audience_groups: ["$a-users@$DOMAIN"]
  review_date: "$(date -u -v+90d +%F)"
  status: pilot
  privilege: none
  metric_pack: light
  verifier: none
EOF
check-jsonschema --schemafile "$PLATFORM_REPO_DIR/$REGISTER_SCHEMA_PATH" "$PLATFORM_REPO_DIR/$REGISTER_PATH/$a.yaml"; done
git -C "$PLATFORM_REPO_DIR" switch -c pg-6-1-tier-c-rows && git -C "$PLATFORM_REPO_DIR" add "$REGISTER_PATH/$A1.yaml" "$REGISTER_PATH/$A2.yaml" && git -C "$PLATFORM_REPO_DIR" commit -m "PG-6.1 two Tier C register rows" && git -C "$PLATFORM_REPO_DIR" push -u origin pg-6-1-tier-c-rows
```
  Replace every `<...>` first. Person 2 runs `MANUAL_PARSE_RECORD` (setup/16 RG-3.6) and commits
  `decisions/register-parses/<date>-pr<number>-parse.md` to the same pull request.
- **VERIFY:** `check-jsonschema` prints `ok` for both files; the parse file names every rule with a
  result and person 2's signature, and `tools/decision-check.sh` prints `OK`; the pull request is
  merged by two humans; then `penv_set TIER_C_AGENT_ROWS "$REGISTER_PATH/$A1.yaml $REGISTER_PATH/$A2.yaml"`.
- **ROLLBACK:** a reverting pull request; no agent has been shared yet.
- **EVIDENCE:** `evidence_add PG-6.1 tier-c-rows E-05 5.2.1 "repo:$REGISTER_PATH@<merge commit>"`;
  the parse (E-03, TISAX 1.4.1). `Assumption:` PV-11 carries the variables `AI_ACT_CLASS_TIER_C` and
  `AI_ACT_ROLE`; if it names them otherwise, the record's names win.

#### PG-6.2 Audience groups, the build and the approved share

- **WHO:** operator creates groups and approves under `ENT_GE_ADMIN`; each builder builds and
  requests; the colleague is in one audience group only.
- **WHERE:** shell; the web app (builders); console → **Gemini Enterprise** → **Apps** → the app →
  **Agents** → **Review share request**.
- **ACTION:** for each agent: create `<agent_id>-owners@` (the builder) and `<agent_id>-users@`
  (a small named population, the colleague in the first only) as security groups (PG-2.1's command);
  give `<agent_id>-users@` the app-level `roles/discoveryengine.agentspaceUser`, because Google shares
  to a group only when it holds the right role, using setup/19 GE-5.5's merge (one binding per role,
  every existing member kept). The builder creates the agent in the web app, private, over the `eu`
  data stores the row names, and shares it with `<agent_id>-users@`. The operator opens **Review share
  request**, checks the three things aloud against the merged row (agent display name, the single
  audience group, the builder is in `ge-builders@`), and clicks **Approve and enable**; any mismatch
  is **Deny**.
```bash
AG="<agent resource name, projects/N/locations/eu/collections/default_collection/engines/APP/assistants/default_assistant/agents/ID>"
ge_call GET "https://eu-discoveryengine.googleapis.com/v1alpha/${AG}" | tee "$(ge_file PG-6.2 agent-$(basename "$AG") json)" | jq '{displayName, state, sharingConfig}'
gcloud identity groups memberships check-transitive-membership --group-email="$GRP_GE_BUILDERS" --member-email="<builder>" --format='value(hasMembership)'
```
- **VERIFY:** `state` is `ENABLED`; `sharingConfig.scope` is `RESTRICTED` or unset (Google: unset
  "Behaves as RESTRICTED"), never `ALL_USERS`; the **User permissions** tab lists the creator and the
  one audience group; the builder check prints `True`; the colleague sees the first agent and not
  the second.
- **ROLLBACK:** remove the group from **User permissions** (this is K1, PG-8.2); remove the app-level
  binding with GE-5.5's rollback.
- **EVIDENCE:** `evidence_add PG-6.2 tier-c-admission E-05 4.2.1 "build-log:ge-baseline/<agent files>"`;
  screenshots of both review decisions.

#### PG-6.3 The console-agent reconciliation, by hand

- **WHO:** operator weekly; person 3 reads the record.
- **WHERE:** console → the app → **Agents** → each agent → **User permissions**; shell.
- **ACTION:** setup/20 GG-7.5 as written: every agent's permitted members against its row's
  `audience_groups`; an agent shared beyond its row, an **All users** share, or a shared agent with no
  row is a severity 2 finding to `platform-security@`; private agents are counted. The first run is
  today. The calendar row is `DR-P05-2`: `DR-P05-1` is file 01's (PP-3.3) row for the timed K1, K2,
  K3 and K7 drills and is not appended again.
```bash
grep -q '^| DR-P05-2 |' "$DRILL_CALENDAR" && echo "STOP: DR-P05-2 already in the calendar" || \
printf '| DR-P05-2 | Gemini Enterprise share read: members vs audience_groups (manual until B-02) | weekly | platform owner | person 3 reads | POV 05 PG-6.3 | %s | | | X-GE-11 |\n' "$(date -u -v+7d +%F)" >> "$DRILL_CALENDAR"
git -C "$BUILD_LOG_DIR" add "$DRILL_CALENDAR" && git -C "$BUILD_LOG_DIR" commit -q -m "PG-6.3 weekly share read"
```

> **BLOCKED** (the automatic half): Needs: the reconciliation and drift jobs (B-02) extended with the
> app's agent list, per-agent sharing, toggles, `modelArmorConfig`, `sessionConfig` and IAM (setup/20
> GG-7.6). Commit it in: `PLATFORM_REPO_REMOTE`, drift job code. Unblocked by: a green commit
> deployed by digest. Gate waiting: none at Tier C; the manual read stands in. `Assumption:` 3 to 5
> engineer-days for the app-only reconciliation. Until then:
> `checkpoint PG-6.3 BLOCKED - - "B-02 app reconciliation; manual read running"`.

- **VERIFY:** the first record `<date>-PG-6.3-share-read-v1.md` has one line per console agent and
  zero unexplained findings; exactly one `| DR-P05-2 |` row and exactly one `| DR-P05-1 |` row
  (file 01's) exist in `DRILL_CALENDAR`.
- **ROLLBACK:** the row is removed only when the job's first automatic record exists.
- **EVIDENCE:** `evidence_add PG-6.3 share-read-weekly E-06 4.2.1 "build-log:ge-baseline/"`.

#### PG-6.3a The Tier C agents and the Agent Registry: no registration, the reason recorded

- **WHO:** operator writes the record; **person 2 reads it and countersigns**. No cloud write.
- **WHERE:** shell; build log.
- **ACTION:** the owner's objective puts every agent through the agent registry, so the two
  admitted agents are checked against what Google documents before anything is written. Read on
  2026-09-16, the documentation gives no registration to perform, for three reasons:
  1. **Manual registration needs something to point at.** A manually registered `Service` is an
     A2A agent described by its agent card, or a "standard REST agent", an endpoint or an MCP
     server described by `--interfaces` with a `url` and a `protocolBinding` (`http-json`, `grpc`
     or `jsonrpc`) (manual-registration and register-endpoints pages; `gcloud agent-registry
     services create` reference). A no-code agent built in the web app has no agent card and no invocation
     URL on any page read: the v1alpha `agents` resource lists `create`, `delete`, `deploy`, `get`,
     `list`, `patch`, `rejectAgent`, `requestAgentReview` and `withdrawAgent` (§Sources), none of
     them a call a registry client makes. A registration would need an invented URL, so none is made.
  2. **Automatic registration is per project and per app.** Google: "Built-in Google agents, such as
     Google Workspace and Gemini Enterprise agents, are automatically registered in Agent Registry",
     and "Automatic registration only discovers resources deployed within the same Google Cloud
     project" (automatic-registration page). The key-concepts page gives the Gemini Enterprise
     identifier as `urn:agent:projects-PROJECT_NUMBER:projects:PROJECT_NUMBER:locations:REGION:discoveryengine:INSTANCE_ID:root`,
     which names the app instance, not each agent. So the app would appear, if at all, in
     `GEMINI_PROJECT`'s own registry, never in `AGENT_REGISTRY` in `CORE_PROJECT`; whether each
     no-code agent appears there is not documented (§Unverified).
  3. **The full build does not register them either.** setup/20 GG-4.2 registers the destinations
     the app reaches (A2A agents, Agent Runtime engines, endpoints, MCP servers) in `GE_REGISTRY`,
     and setup/05 GI-8.5 writes a no-code agent over a data store as `none`. The POV builds no
     gateway and so no `GE_REGISTRY` (PG-9.1's gateway row is OPEN), and both agents reach only
     first-party `eu` stores (PG-1.2).

  What stands in for a registry entry at Tier C: the merged register row (PG-6.1) is the agent's
  inventory entry and its `agent_id` join key, and the weekly share read (PG-6.3) is its
  reconciliation. The only registry read the POV holds for `GEMINI_PROJECT` is PG-1.1's (setup/05
  GI-8.3, made before the agents existed, so it cannot show per-agent entries); no POV entitlement
  carries an `agentregistry` role on `GEMINI_PROJECT`, and none is created for a read.
```bash
checkpoint PG-6.3a START "$SECOND_HUMAN_EMAIL" - "Tier C registry position; no registry write"
need GE_INVENTORY_DIR TIER_C_AGENT_ROWS GEMINI_PROJECT AGENT_REGISTRY
for f in "$GE_INVENTORY_DIR"/*-GI-8.3-registry-agents-*.json; do printf '%s\t%s\n' "$(basename "$f")" "$(jq -r 'if type=="array" then "entries=\(length)" else "not a list" end' "$f" 2>/dev/null || echo "error text: read by case, setup/05 GI-8.3")"; done | tee "$(ge_file PG-6.3a gemini-project-registry-at-inventory tsv)"
R="$BUILD_LOG_DIR/records/$(date -u +%F)-PG-6.3a-tier-c-registry-position-v1.md"
cat > "$R" <<EOF
# Tier C agents and the Agent Registry (POV 05 PG-6.3a)
Rows: ${TIER_C_AGENT_ROWS}
Registry writes made for these agents: none.
Reason (Google, read 2026-09-16): manual registration needs an agent card or an interface URL, and a no-code agent has neither on any page read; built-in Gemini Enterprise agents register automatically in their own project only, under the app instance identifier.
GEMINI_PROJECT registry at inventory (setup/05 GI-8.3): $(ge_latest "$GE_DIR" PG-6.3a-gemini-project-registry-at-inventory tsv)
Shared registry: ${AGENT_REGISTRY} holds no Tier C entry.
Open: setup/20 GG-0.5 and GG-4 (GE_REGISTRY and the app's destinations); whether no-code agents appear as automatic entries.
Signed: platform owner <date>. Read: person 2 <date>.
EOF
checkpoint PG-6.3a DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "$R")"
```
- **VERIFY:** the record names both rows of `TIER_C_AGENT_ROWS`, cites the pages of §Sources with
  the read date, and carries person 2's countersignature (by reply mail saved to
  `EVIDENCE_INTERIM_LOCATION`); the `tsv` has one line per GI-8.3 agents file; this step ran no
  `gcloud agent-registry services create`; PG-9.1's row "Tier C agents in the Agent Registry" reads
  OPEN with this record's path. If Google later documents a registrable form for a no-code agent,
  a new step is written with its citation; nothing is typed here.
- **ROLLBACK:** none needed; a `v2` record with the reason.
- **EVIDENCE:** `evidence_add PG-6.3a tier-c-registry-position E-05 1.3.1 "build-log:records/<file>"`.

### PG-7 Detections and the injection suite

#### PG-7.1 Three PL-10 alerts, each fired on a harmless fixture

- **WHO:** operator under `ENT_PROJECT_REPAIR_TENANT_APP` and `ENT_GE_ADMIN`; **person 2 witnesses
  the two fixture PATCHes on the live app** and confirms receipt of each alert.
- **WHERE:** shell.
- **ACTION:** setup/20 GG-7.1 with the email channel only (no paging channel: business-hours
  acknowledgement, PV-D-10), which sets `NOTIF_CH_EMAIL_GEMINI`; then setup/20 GG-7.2's `mk`
  function for `pl10-engine-update`, `pl10-assistant-update` and `pl10-agent-update` with
  `notificationChannels` holding that one channel. The method names are on Google's audit-logging page
  (`EngineService.UpdateEngine`, `AssistantService.UpdateAssistant`, `v1alpha.AgentService.UpdateAgent`).
  Fixtures on the production app that change nothing a user sees: `UpdateAssistant` by writing
  `customerPolicy` back unchanged; `UpdateEngine` by PATCHing `displayName` to its current value;
  `UpdateAgent` by the K1 drill (PG-8.2).
  The assistant fixture rewrites the whole `customerPolicy`, which holds `modelArmorConfig`, so it
  starts from a full saved GET, compares it with PG-5.3's asserted state, and proves by a second GET
  that nothing changed.
```bash
ok=1
cur="$(ge_file PG-7.1 assistant-before json)"; ge_call GET "${GE_APP}/assistants/default_assistant" > "$cur"
diff <(jq -S '.customerPolicy' "$(ge_latest "$GE_DIR" PG-5.3-assistant-after json)") <(jq -S '.customerPolicy' "$cur") || { echo "STOP: live policy differs from PG-5.3; explain before any PATCH"; ok=0; }
jq -e '.customerPolicy.modelArmorConfig.userPromptTemplate and .customerPolicy.modelArmorConfig.responseTemplate' "$cur" > /dev/null || { echo "STOP: modelArmorConfig missing from the saved GET"; ok=0; }
jq '{customerPolicy: .customerPolicy}' "$cur" > "$GE_DIR/cp-same.json"
[ "$ok" = 1 ] && confirm_manual PG-7.1 "Person 2: type the userPromptTemplate name you read in cp-same.json" || ok=0
[ "$ok" = 1 ] && ge_call PATCH "${GE_APP}/assistants/default_assistant?update_mask=customerPolicy" "$GE_DIR/cp-same.json" > /dev/null && date -u +%FT%TZ | tee -a "$GE_DIR/fixture-times.txt"
aft="$(ge_file PG-7.1 assistant-after json)"; ge_call GET "${GE_APP}/assistants/default_assistant" > "$aft"
diff <(jq -S '.customerPolicy' "$cur") <(jq -S '.customerPolicy' "$aft") && echo "customerPolicy unchanged" || { echo "STOP: customerPolicy changed; ROLLBACK now"; ok=0; }
eng="$(ge_file PG-7.1 engine-before json)"; ge_call GET "$GE_APP" > "$eng"
jq '{displayName}' "$eng" > "$GE_DIR/dn-same.json"
[ "$ok" = 1 ] && ge_call PATCH "${GE_APP}?updateMask=displayName" "$GE_DIR/dn-same.json" > /dev/null && date -u +%FT%TZ | tee -a "$GE_DIR/fixture-times.txt"
diff <(jq -S 'del(.updateTime)' "$eng") <(ge_call GET "$GE_APP" | jq -S 'del(.updateTime)') && echo "engine unchanged"
```
  On any `STOP`, no PATCH is sent. `Assumption:` `updateTime` is the only field a no-op PATCH
  changes on the engine; any other diff line is investigated, not ignored.
- **VERIFY:** `gcloud monitoring policies list --project="$GEMINI_PROJECT" --format='value(displayName,enabled)'`
  lists three enabled policies; no `STOP`; `CONFIRMED PG-7.1`; `customerPolicy unchanged` and
  `engine unchanged` printed; within 10 minutes of each fixture an incident opens and the email
  reaches `platform-security@` **and person 2's own inbox** (person 2 is a member, or the channel
  names `SECOND_HUMAN_EMAIL`), confirmed by person 2 with the time (`Assumption:` latency; the
  measured value is recorded). A policy that stays silent is fixed and re-fired before PG-9. The
  gateway-write policy (GG-7.2b) is not built: no gateway exists (open row).
- **ROLLBACK:** if either post-PATCH diff is not empty, restore at once from the saved file, person 2
  witnessing, and re-GET until the diff is empty:
  `jq '{customerPolicy: .customerPolicy}' "$cur" > "$GE_DIR/cp-restore.json" && ge_call PATCH "${GE_APP}/assistants/default_assistant?update_mask=customerPolicy" "$GE_DIR/cp-restore.json"`
  (and the same with `engine-before` and `updateMask=displayName` for the engine); then re-run
  PG-5.3's `jq -e` assertion. The alert policies are removed with
  `gcloud monitoring policies delete <name> --project="$GEMINI_PROJECT"`.
- **EVIDENCE:** `evidence_add PG-7.1 pl10-fired E-10 1.6.1 "build-log:ge-baseline/fixture-times.txt"`;
  the before and after GET files and the two empty diffs, person 2 named as witness.

#### PG-7.1a The registry write-alert drill: one witnessed repair write (setup/16 RG-5.7)

- **WHO:** operator under a **fresh `ENT_PROJECT_REPAIR_CORE` grant**, requested for this drill
  alone so its write stands alone in the audit log; **person 2 approves it** in their own console
  (never the operator: PAM refuses self-approval), reads the drill id aloud before the create and
  the delete, and confirms the alert email with its arrival time. Business hours only (PV-D-10).
- **WHERE:** shell; person 2's console (**Privileged Access Manager** → **Approve grants**) and
  person 2's own inbox, which `NOTIF_CH_EMAIL_CORE` names (03 PF-7.3).
- **ACTION:** setup/16 RG-5.7 as written, with the POV's three changes: the grant is approved by
  person 2 and the id is read aloud by person 2 before each write; the delete carries no `--quiet`
  (a human confirms it); the calendar row is `DR-P05-4`, not setup/16's `DR-16-1`, which the full
  build opens itself (a POV value never occupies a full-build name, README §7.2). `DR-P05-1` is
  file 01's, `DR-P05-2` PG-6.3's and `DR-P05-3` PG-8.6's. The POV registers no Tier C agent
  (PG-6.3a), so the drill is RG-5.7's own marked write, and file 07's engine registration (07 PW-5.4a) is the first real entry.

  A human write is lawful only as registry repair under PAM, and `ENT_PROJECT_REPAIR_CORE` is the
  only POV entitlement carrying `roles/agentregistry.admin` (03 PF-5.1, setup/12 PA-4.2); if it
  does not carry it, stop and substitute nothing. The entry points at the `.invalid` top-level
  domain, so nothing resolves it, and is deleted in this step. Every command names `--project`
  and `--location`; manual registration is refused in the `us` and `eu` multi-regions and works
  in `europe-west1` (locations page, read 2026-09-16). Gate first:
```bash
source "$BUILD_LOG_DIR/ge-baseline/ge-helpers.sh"
checkpoint PG-7.1a START "$SECOND_HUMAN_EMAIL" - "registry write-alert drill (setup/16 RG-5.7)"
need AGENT_REGISTRY ENT_PROJECT_REPAIR_CORE CORE_PROJECT CICD_PROJECT REGION NOTIF_CH_EMAIL_CORE SECOND_HUMAN_EMAIL SA_1_ADMIN DRILL_CALENDAR
ok=1
test "$REGION" = europe-west1 || { echo "STOP: REGION is not europe-west1"; ok=0; }
test "$AGENT_REGISTRY" = "projects/${CORE_PROJECT}/locations/${REGION}" || { echo "STOP: AGENT_REGISTRY is not CORE_PROJECT in REGION (04 PC-4.1)"; ok=0; }
gcloud monitoring policies list --project="$CORE_PROJECT" --filter='displayName:"agentregistry write"' --format='value(name,enabled)' | tee "$(ge_file PG-7.1a registry-alert-policy txt)" | grep -q 'True' || { echo "STOP: no enabled registry write alert in CORE_PROJECT (04 PC-4.2)"; ok=0; }
gcloud pam entitlements describe "$ENT_PROJECT_REPAIR_CORE" --billing-project="$CICD_PROJECT" --format='yaml(privilegedAccess.gcpIamAccess.roleBindings)' | grep -q 'roles/agentregistry.admin' || { echo "STOP: ENT_PROJECT_REPAIR_CORE lacks agentregistry.admin (03 PF-5.1); substitute nothing"; ok=0; }
grep -q '^| DR-P05-4 |' "$DRILL_CALENDAR" && { echo "STOP: DR-P05-4 already in the calendar; this is a repeat, append its record to that row"; ok=0; }
D="pov-rg-drill-$(date -u +%Y%m%d)"
[ "$ok" = 1 ] && G="$(gcloud pam grants create --entitlement="$ENT_PROJECT_REPAIR_CORE" --requested-duration=3600s --justification="POV 05 PG-7.1a: registry write-alert drill (setup/16 RG-5.7), one marked service ${D} created and deleted" --additional-email-recipients="$SECOND_HUMAN_EMAIL" --billing-project="$CICD_PROJECT" --format='value(name)')" && echo "grant ${G}: person 2 approves it now in their own console"
```
  Person 2 approves; then the grant is read, the registry listed, and the entry created only
  after person 2 has typed the drill id the operator's screen shows:
```bash
[ "$ok" = 1 ] && [ "$(gcloud pam grants describe "$G" --billing-project="$CICD_PROJECT" --format='value(state)')" = ACTIVE ] || { echo "STOP: grant not ACTIVE; nothing is written"; ok=0; }
[ "$ok" = 1 ] && gcloud pam grants describe "$G" --billing-project="$CICD_PROJECT" --format=json > "$(ge_file PG-7.1a grant json)"
[ "$ok" = 1 ] && gcloud agent-registry services list --location="$REGION" --project="$CORE_PROJECT" --format='value(name)' | tee "$(ge_file PG-7.1a registry-before txt)"
[ "$ok" = 1 ] && confirm_manual PG-7.1a "Person 2: type the drill service id shown on the operator's screen"
[ "$ok" = 1 ] && [ "$(tail -1 "$BUILD_LOG_DIR/confirmations.tsv" | cut -f5)" = "$D" ] || { echo "STOP: typed id is not ${D}; create nothing"; ok=0; }
[ "$ok" = 1 ] && gcloud agent-registry services create "$D" --project="$CORE_PROJECT" --location="$REGION" --display-name="POV 05 PG-7.1a alert drill" --description="meta: drill=PG-7.1a setup=RG-5.7 not_an_agent=true" --endpoint-spec-type=no-spec --interfaces="url=https://drill.invalid/,protocolBinding=http-json" && date -u +%FT%TZ | tee "$GE_DIR/registry-drill-create-time.txt"
[ "$ok" = 1 ] && confirm_manual PG-7.1a "Person 2: type the UTC arrival time (HH:MM) of the agentregistry write alert email in your own inbox"
```
  Person 2 types the time only when the email is in their inbox; if none arrives within five
  minutes of the create time, person 2 types `none` and the drill has failed (VERIFY). Then the
  delete, with the id read aloud again, and the audit read inside the same grant:
```bash
[ "$ok" = 1 ] && confirm_manual PG-7.1a "Person 2: type the service id to delete, read from the list on the operator's screen"
[ "$ok" = 1 ] && [ "$(tail -1 "$BUILD_LOG_DIR/confirmations.tsv" | cut -f5)" = "$D" ] && gcloud agent-registry services delete "$D" --project="$CORE_PROJECT" --location="$REGION" || echo "STOP: typed id is not ${D} or the delete failed; see ROLLBACK"
gcloud agent-registry services list --location="$REGION" --project="$CORE_PROJECT" --format='value(name)' | tee "$(ge_file PG-7.1a registry-after txt)"
gcloud logging read 'protoPayload.serviceName="agentregistry.googleapis.com" AND logName:"cloudaudit.googleapis.com%2Factivity"' --project="$CORE_PROJECT" --freshness=1h --format='table(timestamp,protoPayload.methodName,protoPayload.authenticationInfo.principalEmail,protoPayload.resourceName)' | tee "$(ge_file PG-7.1a registry-audit txt)"
[ -n "${G:-}" ] && gcloud pam grants revoke "$G" --reason="POV 05 PG-7.1a drill finished" --billing-project="$CICD_PROJECT"
```
  Google names the writes `google.cloud.agentregistry.v1.AgentRegistry.CreateService` and
  `...DeleteService`, both Admin Activity and long-running, and says such methods "usually generate
  two audit log entries: one when the operation starts and another when it ends" (audit-logging
  page, read 2026-09-16); RG-5.6's 300-second rate limit keeps that to one email per write. Write
  `records/<date>-PG-7.1a-registry-alert-drill-v1.md`: the grant name and its approver as the
  grant JSON shows it, the create time, person 2's arrival time, the seconds between them, the audit
  lines, and person 2's signature. Then the calendar row, the closing line for 04 PC-4.2's re-run
  entry, and the commit:
```bash
REC="records/$(date -u +%F)-PG-7.1a-registry-alert-drill-v1.md"
printf '| DR-P05-4 | Registry write alert: one repair write in AGENT_REGISTRY under ENT_PROJECT_REPAIR_CORE emails person 2 within 5 minutes (setup/16 RG-5.7) | monthly (setup/16 RG-5.7) | platform owner | second person | POV 05 PG-7.1a | %s | %s | %s | POV_TIER_C_RECORD; 04 PC-4.2 |\n' "$(date -u +%F)" "$REC" "$(date -u -v+1m +%F)" >> "$DRILL_CALENDAR"
printf '%s\tPC-4.2\tAGENT_REGISTRY\tregistry write alert proven by POV 05 PG-7.1a (setup/16 RG-5.7)\tDONE\t%s\n' "$(date -u +%F)" "$REC" >> "$BUILD_LOG_DIR/rerun-index.tsv"
git -C "$BUILD_LOG_DIR" add "$DRILL_CALENDAR" "$BUILD_LOG_DIR/rerun-index.tsv" "$BUILD_LOG_DIR/$REC" "$GE_DIR" && git -C "$BUILD_LOG_DIR" commit -q -m "PG-7.1a registry write-alert drill"
checkpoint PG-7.1a DONE "$SECOND_HUMAN_EMAIL" "build-log:$REC"
```
- **VERIFY:** no `STOP`; the policy file shows one enabled policy; the grant JSON shows person 2's
  `sa-2-admin@` as the approver and `SA_1_ADMIN` as the requester (person 2 reads it; any other
  approver is a stop); three `CONFIRMED PG-7.1a` lines; person 2's arrival time is no more than
  five minutes after `registry-drill-create-time.txt`; the audit read shows `CreateService` and
  `DeleteService` on `.../services/pov-rg-drill-<date>` by `SA_1_ADMIN` and no other principal in
  the hour; `registry-after` equals `registry-before`; exactly one `| DR-P05-4 |` row in
  `DRILL_CALENDAR`; the grant then reads `REVOKED` or `ENDED`. No email within five minutes is a
  severity 2 finding on the monitoring baseline (setup/16 RG-5.7): fix the policy under a new
  grant (the bundle carries `roles/monitoring.admin`, setup/16 RG-5.6) and repeat before PG-9.1;
  until then the PG-9.1 row stays OPEN and no file cites the alert as working.
- **ROLLBACK:** the entry is deleted in the action. If the delete failed, delete it under the same
  grant (or a new one person 2 approves), person 2 reading the id aloud:
  `gcloud agent-registry services delete "$D" --project="$CORE_PROJECT" --location="$REGION"`, then
  list again until `registry-after` equals `registry-before`. The grant is revoked in the action and
  otherwise expires within the hour. The calendar row is removed only by `git revert` while no
  record cites it.
- **EVIDENCE:** `evidence_add PG-7.1a registry-alert-drill E-08 5.2.6 "build-log:records/<file>"`;
  the grant JSON, the before and after lists and the audit read, person 2 named as approver and
  witness. TISAX 5.2.6, 1.6.1.

#### PG-7.2 The injection suite, Tier C subset

- **WHO:** operator commits the corpus; person 2 reviews it; the colleague sends the prompts; the
  operator reads the sanitize log.
- **WHERE:** platform repository; the colleague's web app; shell.
- **ACTION:** the suite of [../../wall-e/11-prompt-security.md](../../wall-e/11-prompt-security.md) §6,
  cut to the surfaces Tier C has: `tests/injection/tier-c/hostile.yaml` with at least three cases per
  surface (the assistant, each of the two agents) each trying to override instructions, exfiltrate a
  link or reveal the system instruction, in English and the tenant's working languages; and
  `tests/injection/tier-c/benign.yaml` with at least ten real questions from the builders, with their
  consent and no other person's name. No hostile string is planted in any real mailbox or document.
  At least 10 minutes after `armor-on-time`, the colleague sends every case and notes the times; then:
```bash
t0="$(cat "$GE_DIR/armor-on-time.txt")"
f="$(ge_file PG-7.2 sanitize-entries json restricted)"
gcloud logging read "resource.type=\"modelarmor.googleapis.com/SanitizeOperation\" AND timestamp>=\"${t0}\"" --project="$GEMINI_PROJECT" --bucket=ge-content-logs --location="$REGION" --view=ge-sanitize-view --limit=200 --format=json > "$f"
jq -r '.[] | [.timestamp, (.labels["modelarmor.googleapis.com/client_correlation_id"] // "-" | split("|")[0]), (.jsonPayload.sanitizationResult.filterMatchState // "-"), (.jsonPayload.sanitizationResult.sanitizationVerdict // "-")] | @tsv' "$f" | tee "$(ge_file PG-7.2 sanitize-summary tsv)"
```
  Write `records/<date>-PG-7.2-injection-suite-v1.md`: per surface, hostile cases sent, `MATCH_FOUND`
  count, refused count, benign cases sent, benign refused; the template names, `MODEL_ID` and the date.
  **Detection rate is recorded, not gated**; a benign refusal is a finding against the template.
  Whether the app's Model Armor setting screens Workflow Builder agents as well as the assistant is
  not settled by Google's page (§Unverified); the per-surface counts settle it for this tenant.
- **VERIFY:** the record exists with `n` for every figure; when `GE_SANITIZE_LOGGING` is `off`, the
  `gcloud logging read` is not run and the record says the counts come from the colleague's notes
  only; when `on`, the summary holds at least one `MATCH_FOUND` row with an assistant-path correlation prefix at a hostile prompt time; then
  `penv_set INJECTION_SUITE_RECORD "$BUILD_LOG_DIR/records/<file>"`. SCC is not the verify source
  for assistant-path matches (setup/19 §5, X-GE-07), and SCC Standard is what the POV has (PV-D-02).
- **ROLLBACK:** none needed.
- **EVIDENCE:** `evidence_add PG-7.2 injection-suite E-08 5.2.6 "build-log:records/<file>"` (E-08,
  the closest row of setup/01 §7.2: a drill-like test record; E-15 is the Art. 50 block); the
  restricted entries by hash only. Re-run on every template, model pin or agent instruction change.

### PG-8 The kill drills at Tier C

#### PG-8.1 The Tier C lever table and the drill set-up

- **WHO:** operator writes; person 2 reads it before the drills.
- **WHERE:** build log.
- **ACTION:** the design's K0 to K7 are agent-code levers ([../../wall-e/ARCHITECTURE.md](../../wall-e/ARCHITECTURE.md)
  §4.6; [../04-identity-and-privileged-access.md](../04-identity-and-privileged-access.md) §9.7). A Tier C
  agent has no action service, no Scheduler job and no credential, and the design gives it one
  emergency lever, unsharing ([../03-gemini-enterprise-environment.md](../03-gemini-enterprise-environment.md)
  §10.1). `Assumption:` this POV mapping, written into the record so it is read as a mapping and not
  as the design:

| Lever | At Tier C | Who may pull | Target | What it does not stop |
|---|---|---|---|---|
| K0 halt writes, K4 kill the credential | **do not exist**: nothing writes and nothing holds a credential | | | first built in file 07 |
| K1 demote one agent | remove the audience group from the agent's **User permissions**; the agent returns to its creator only | any `ge-admins@` member through `ent-ge-admin`, no approval | seconds to click; access ends at IAM propagation, measured | the creator; a conversation already returned |
| K2 stop agents app-wide | **Enable chat agents** and **Enable workflows** off (Google: when enabled, "users can build and use custom chat agents") | same | minutes, measured | the assistant itself; agents of other types |
| K3 cut the agent off | DELETE the agent (IRREVERSIBLE), drilled on a fixture only | same | seconds, measured | nothing of that agent survives; the register row stays |
| K7 fleet | the tier-folder levers; **never** `fld-gemini-enterprise` (P70) | `ent-k7-human` pair, paged | trigger to last lever under 900 s (human path, 03 PF-9.3); refusal not measured, no agent project exists | Tier C agents, by design |

  **The token residual.** Google documents one hour for service-account access tokens ("By default,
  these tokens expire after 1 hour"); the design uses 60 minutes for every token. IAM and sharing levers act on the next authorised call after propagation (Google:
  an allow-policy change "typically 2 minutes, potentially 7 minutes or longer"; a group-membership
  change "typically several minutes, potentially hours or longer"), not when the token expires. So every
  drill measures time to the first refusal and never records a lever as effective when clicked. Where a
  credential is revoked rather than a permission removed (K4, file 07), a token already issued may
  keep working for a residue: the record states the residue as measured in
  [07](07-the-doer-tier-w-and-the-optional-tier-p.md) PW-6.5, never the design's 60-minute bound.
  **K0 is what stops work now, K4 is what stops the credential**, and at Tier C neither is needed.
```bash
DR="$BUILD_LOG_DIR/drills/$(date -u +%F)-PG-8"; mkdir -p "$DR"
stamp() { printf '%s\t%s\n' "$(date -u +%FT%TZ)" "$1" | tee -a "$DR/timeline.tsv"; }
{ printf 'DR=%q\n' "$DR"; declare -f stamp; } > "$DR/stamp.sh"
```
- **VERIFY:** the table is in `$DR/levers.md`, signed as read by person 2; `type stamp` is a function.
- **ROLLBACK:** none needed.
- **EVIDENCE:** `evidence_add PG-8.1 tier-c-levers E-08 1.6.2 "build-log:drills/<dir>/levers.md"`.

#### PG-8.2 K1: demote one agent

- **WHO:** person 2 pulls it (any operator may; no approval); the colleague observes.
- **WHERE:** console → the app → **Agents** → the first agent → **User permissions**; the colleague's
  web app; shell.
- **ACTION:** the colleague keeps the agent open and asks one question every 30 seconds. Person 2
  activates `ent-ge-admin` with justification `POV 05 K1 drill`, removes `<agent_id>-users@` from the
  tab and saves.
```bash
source "$DR/stamp.sh"; stamp "K1: removed audience group"
# the colleague calls out the first refused or missing-agent answer
stamp "K1: first refusal seen by colleague"
ge_call GET "https://eu-discoveryengine.googleapis.com/v1alpha/${AG}" | jq '{state, sharingConfig}' | tee "$DR/k1-agent-after.json"
```
  Restore: add the group back and wait for the colleague's first answer (`stamp "K1: restored, answer seen"`).
- **VERIFY:** the two stamps are recorded with the difference; `pl10-agent-update` fired, or the
  record says the group share wrote no `UpdateAgent` entry (setup/20 Q11 is unanswered in the POV);
  the restore stamp exists.
- **ROLLBACK:** the restore above.
- **EVIDENCE:** `timeline.tsv` and `k1-agent-after.json` (E-08, TISAX 1.6.3).

#### PG-8.3 K2: stop no-code agents app-wide, in an announced window

- **WHO:** operator pulls under `ENT_GE_ADMIN`; **person 2 witnesses**; the colleague observes; the desk
  acknowledged the window.
- **WHERE:** console → the app → **Configurations** → **Feature Management**; the colleague's web app.
- **ACTION:** the window was named in a notice at least five business days ahead: for up to 30
  minutes users cannot use custom agents. Stamp, switch **Enable chat agents** and **Enable workflows**
  off, save; the colleague retries both agents every 30 seconds.
```bash
source "$DR/stamp.sh"; stamp "K2: toggles off saved"
stamp "K2: both agents unavailable to colleague"
ge_call GET "$GE_APP" | jq -S '.features' > "$DR/k2-features-off.json"
```
  Restore both toggles from `register/gemini-features.yaml` and stamp the first answer again.
- **VERIFY:** both stamps and the restore stamp exist; `pl10-engine-update` fired if the toggles
  map to `features` keys; the GET after restore equals `register/gemini-features.yaml`. If the agents
  stayed usable after 30 minutes, the record says "K2 at Tier C does not stop existing agents" and
  the K2 row of the gate record is open.
- **ROLLBACK:** the restore; if the console refuses, the setup/19 GE-6.4 GET values set back by hand.
- **EVIDENCE:** timeline and features files (E-08, TISAX 1.6.3); the notice in `EVIDENCE_INTERIM_LOCATION`.

#### PG-8.4 K3: cut an agent off, on a fixture

- **WHO:** operator builds and deletes the fixture; person 2 witnesses the delete.
- **WHERE:** the operator's web app (as `sa-1-admin@`); console → the app → **Agents**.
- **ACTION:** the operator creates a private chat agent named `k3-drill-fixture-<date>` with no data
  store, opens a conversation with it, and keeps the tab open. It is never shared, so it needs no
  register row; the weekly read (PG-6.3) counts it.

> **IRREVERSIBLE**: a deleted agent cannot be restored. Confirm before running: the display name in
> the console row is `k3-drill-fixture-<date>`, its **User permissions** list only the operator, and
> person 2 reads the name aloud from the selected row. Gate: this step's own record; no decision is
> needed for a fixture that holds no data.

```bash
source "$DR/stamp.sh"
confirm_manual PG-8.4 "Type the display name of the selected console row exactly as person 2 reads it aloud"
typed="$(tail -1 "$BUILD_LOG_DIR/confirmations.tsv" | cut -f5)"
test "$typed" = "k3-drill-fixture-$(date -u +%F)" && echo "fixture name matches; click Delete" || echo "STOP: typed '$typed' is not today's fixture; do not delete"
# only after "fixture name matches":
stamp "K3: Delete clicked"
stamp "K3: first refusal in the open tab"
```
  In the console: **Agents** → **more_vert** next to the fixture → **Delete**.
- **VERIFY:** `CONFIRMED PG-8.4` and `fixture name matches` printed before the delete (a `STOP`
  means nothing is deleted); both stamps; the agent is absent from the **Agents** page; the open
  tab's next message is refused.
- **ROLLBACK:** **IRREVERSIBLE** for the fixture; nothing else is touched.
- **EVIDENCE:** timeline and a screenshot of the Agents page after (E-08, TISAX 1.6.3).

#### PG-8.5 K7 on a tier folder, the Tier C agents untouched

- **WHO:** operator pulls with the `ent-k7-human` pair; **person 2 present** and approves the lift.
- **WHERE:** the shell of file 03's K7 drill.
- **ACTION:** repeat file 03's K7 drill (the human path of setup/18 KS-6.3 and KS-6.4, KF-1 on
  `fld-agents-r-nonprod` only, then the two-human lift) with two additions: before the trigger and
  every 30 seconds until the lift, the colleague asks the first Tier C agent a question; and the app's
  effective allow-list is read before and during.
```bash
source "$DR/stamp.sh"
gcloud org-policies describe gcp.restrictServiceUsage --project="$GEMINI_PROJECT" --effective --format=json | jq -S . > "$DR/k7-ge-before.json"
stamp "K7: trigger"   # then file 03's KF-1 lines for fld-agents-r-nonprod
gcloud org-policies describe gcp.restrictServiceUsage --project="$GEMINI_PROJECT" --effective --format=json | jq -S . > "$DR/k7-ge-during.json"
diff "$DR/k7-ge-before.json" "$DR/k7-ge-during.json" && stamp "K7: Gemini project policy unchanged"
```
- **VERIFY:** file 03 PF-9.3's VERIFY (trigger to last lever under 900 s, or the miss recorded as a
  finding). Refusal is **not measured** here: `fld-agents-r-nonprod` holds no project in the POV, so
  the record says "Refusal not measured: no agent project exists", as PF-9.3 does; the refused call
  is first measured in file 07 against the doer's nonprod project. The `diff` is empty; every colleague question during the drill was answered; the lift is
  merged by two humans and the folder policy equals its saved predecessor.
- **ROLLBACK:** the two-human lift (setup/18 KS-6.4).
- **EVIDENCE:** timeline, both policy reads, file 03's drill files (E-08, TISAX 1.6.3).

#### PG-8.6 Write the drill record

- **WHO:** operator writes; person 2 countersigns the times.
- **WHERE:** build log.
- **ACTION:** `$DR/record.md`: one row per lever (K1, K2, K3, K7) with trigger stamp, effect stamp,
  measured seconds, target, met or missed, and the "does not stop" column of PG-8.1; the token-residual
  paragraph verbatim; K0 and K4 marked "not applicable at Tier C, first drilled in file 07"; a missed
  target is a finding, never a silent repeat. Add calendar rows: K1 at Tier C monthly (`DR-P05-3`; `DR-P05-1` is file
  01's drill row and `DR-P05-2` the weekly share read of PG-6.3), K7 per file 03's cadence. Fill
  `DR-P05-1`'s result columns from this record rather than appending a second `DR-P05-1`.
```bash
penv_set KILL_DRILL_RECORD_C "$DR/record.md"
git -C "$BUILD_LOG_DIR" add "$DR" "$DRILL_CALENDAR" && git -C "$BUILD_LOG_DIR" commit -q -m "PG-8 Tier C kill drills"
```
- **VERIFY:** four lever rows with numbers; person 2's countersignature; `need KILL_DRILL_RECORD_C`.
- **ROLLBACK:** a `v2` record with the reason.
- **EVIDENCE:** `evidence_add PG-8.6 kill-drill-c E-08 1.6.3 "build-log:drills/<dir>/record.md"`.

### PG-9 The POV Tier C gate record

#### PG-9.1 Write `POV_TIER_C_RECORD` with every open row named

- **WHO:** operator signs; person 2 acknowledges the detection and drill lines.
- **WHERE:** `GATES_DIR` in the platform repository.
- **ACTION:** the rows of setup/20 GG-8.2, plus the POV's own. A row is `PASS` with its evidence id,
  or `OPEN` with the file that closes it. The record is never marked green.
```bash
R="$PLATFORM_REPO_DIR/$GATES_DIR/$(date -u +%F)-PG-9.1-pov-tier-c-record-v1.md"
cat > "$R" <<'EOF'
# POV Tier C record (POV 05 PG-9.1). Not G21. Does not satisfy setup/20 GG-8.2.
| Line | Evidence | Result |
|---|---|---|
| Register rows and signed parse (two Tier C agents) | PG-6.1 | |
| Tier R record | POV 04 POV_TIER_R_RECORD | |
| Inventory before change; gate lines clear | PG-1.1 | |
| Standing admins removed; ent-ge-admin proven | PG-2.2, PG-2.3 | |
| Project moved after 14 clean dry-run days; tag inherited | PG-3.2, PG-3.3 | |
| Admin-read and data-read audit logs | PG-3.4 | |
| Prompt logging off, DPO signed | PG-4.1 | |
| Sanitize logging, bucket, readers and 30 days signed by the DPO (GE-CONTENT-LOGGING) | PG-4.1, PG-5.1, PG-5.2 | |
| Agent sharing without admin approval off; announced and witnessed | PG-4.2 | |
| Retention kept or raised; grounding off | PG-4.3 | |
| Model Armor on, failure toggle off (evidence, not a boundary) | PG-5.3 | |
| Shares only to audience groups, reviewed | PG-6.2 | |
| Tier C agents in the Agent Registry | PG-6.3a | OPEN, no manual registration documented for a no-code agent; setup/20 GG-0.5, GG-4 |
| PL-10 alerts fired (3 of 4) | PG-7.1 | |
| Registry write alert drill: email within 5 minutes, entry deleted, audit read (setup/16 RG-5.7) | PG-7.1a | |
| Injection suite with n and rates | PG-7.2 | |
| K1, K2, K3, K7 timed | PG-8.6 | |
| SCC Premium, eu; SCC test finding on the app project | PV-D-02 | OPEN, setup/09, setup/20 GG-7.4 |
| Gateway spike Q1-Q14, gemini-egress in DRY_RUN, binding, pl10-gateway-write | none built | OPEN, setup/20 GG-0 to GG-6, GG-7.2b |
| Unreachable-template test on a throwaway app | none | OPEN, setup/20 GG-2.5 |
| Managed connector constraints with refused provisions | none | OPEN, setup/19 GE-4.2 to GE-4.7 |
| Users moved to ge-users@, project-level user roles removed | none | OPEN, setup/19 GE-5.2 to GE-5.9 |
| Banned phrases tested; CMEK decision; quota register | none | OPEN, setup/19 GE-6.8, GE-6.10 to GE-6.13, GE-8 |
| Terraform import of the app | BD-P05-1 | OPEN, B-01 (PV-D-01) |
| Nightly reconciliation job | PG-6.3 manual | OPEN, B-02 |
| SIEM rules; 24x7 acknowledgement | PV-D-10 | OPEN, setup/15 part B |
| Penetration test of front door and share | PV-D-11 | OPEN, setup/37 |
Signed: platform owner <date>. Acknowledged: person 2 <date>.
EOF
git -C "$PLATFORM_REPO_DIR" add "$R" && git -C "$PLATFORM_REPO_DIR" commit -m "PG-9.1 POV Tier C record" && git -C "$PLATFORM_REPO_DIR" push
penv_set POV_TIER_C_RECORD "$R"
```
  Fill each empty Result with `PASS <evidence id>` or `OPEN <reason>`. The gateway, constraint,
  `ge-users@`, banned-phrase, CMEK and quota rows are work not yet done rather than work done
  differently: they carry no PV-D id and are handed over to the setup files named. The Agent
  Registry row stays OPEN because Google documents no manual registration for a no-code agent
  (PG-6.3a), not because a step was skipped.
- **VERIFY:** no empty Result cell; no line reads "green"; both signatures present (person 2's by
  reply mail saved to `EVIDENCE_INTERIM_LOCATION`); `need POV_TIER_C_RECORD`.
- **ROLLBACK:** a `v2` record with the reason.
- **EVIDENCE:** `evidence_add PG-9.1 pov-tier-c-record E-05 1.2.2 "repo:$GATES_DIR/<file>"`.

#### PG-9.2 Close the part

- **WHO:** operator. Solo.
- **WHERE:** shell.
- **ACTION:**
```bash
for e in "$ENT_GE_ADMIN" "$ENT_PROJECT_REPAIR_TENANT_APP" "$ENT_K7_HUMAN" "$ENT_K7_HUMAN_SCHEDULER"; do gcloud pam grants list --entitlement="$e" --filter='state=ACTIVE' --format='value(name)' | while read -r G; do gcloud pam grants revoke "$G" --reason="POV 05 closed"; done; done
gcloud pam grants list --entitlement="$ENT_PROJECT_REPAIR_CORE" --filter='state=ACTIVE' --billing-project="$CICD_PROJECT" --format='value(name)' | while read -r G; do gcloud pam grants revoke "$G" --reason="POV 05 closed" --billing-project="$CICD_PROJECT"; done
grep -E $'\tPG-[0-9.]+\t(DONE|BLOCKED|N/A)' "$BUILD_LOG_DIR/checkpoints.tsv" | cut -f2,3 | sort -u
printf '| BD-P05-1 | tenant-app built by hand | B-01 | PG-3.1 |\n' >> "$BUILD_LOG_DIR/rerun-index.tsv"
checkpoint PG-9.2 DONE - "$POV_TIER_C_RECORD"
sitting_end
```
- **VERIFY:** no active grant; every PG step is `DONE`, `N/A` with a reason, or `BLOCKED` (PG-3.1's
  import and PG-6.3's job only); `SITTING-END OK`.
- **ROLLBACK:** none needed.
- **EVIDENCE:** checkpoint lines. E-xx: none. TISAX 4.1.2.

---

## Verification checklist for the whole part

- [ ] setup/05 ran unchanged, gate lines `clear`, retention read not touched (PG-1.1); no non-`eu` data
  store named by any row; `register/gemini-connectors.yaml` merged (PG-1.2).
- [ ] `ge-admins@` holds only the two admin accounts; `ge-builders@` holds no admin account (PG-2.1).
- [ ] `ent-ge-admin` has no approval and a one-hour maximum; no human or group holds a standing
  admin, owner or editor role on `GEMINI_PROJECT` (PG-2.2, PG-2.3).
- [ ] The move followed 14 clean dry-run days with a positive control; the colleague answered before
  and after; `agp-tier` = `ge` is effective on the project (PG-3.2, PG-3.3).
- [ ] `sensitiveLoggingEnabled` false under a DPO-signed record, or `N/A` with the record (PG-4.1).
- [ ] `GE-CONTENT-LOGGING` signed before `ge-content-logs` or either template existed; the templates'
  `logSanitizeOperations` equals the signed value (PG-4.1, PG-5.1, PG-5.2).
- [ ] **Enable agent sharing without admin approval** is off, with a dated screenshot; the change
  was announced, witnessed by person 2 and has a saved before-state (PG-4.2).
- [ ] Retention is at least `GE_RETENTION_CURRENT_DAYS`; the publish was witnessed (PG-4.3).
- [ ] The assistant GET shows both `eu` templates and `FAIL_CLOSED`; the failure toggle is off on
  screen; the record says evidence, not boundary; no Model Armor switch-off without person 2's
  written approval, witness and a dated re-enable (PG-5.3).
- [ ] Two Tier C rows validate against the schema, carry `privilege: none`, and were parsed and
  signed by person 2, never by the operator (PG-6.1).
- [ ] Each agent is `ENABLED`, `RESTRICTED`, shared to one audience group through an approved
  request (PG-6.2); the weekly read is in `DRILL_CALENDAR` (PG-6.3).
- [ ] The Tier C registry record says no registry write was made, with Google's reason and the
  pages read on 2026-09-16, countersigned by person 2 (PG-6.3a).
- [ ] The registry write alert emailed person 2 within five minutes of one marked write in
  `AGENT_REGISTRY`, made under a fresh `ENT_PROJECT_REPAIR_CORE` grant that person 2 approved and
  never the operator; the entry was deleted; the audit read shows only `SA_1_ADMIN`; `DR-P05-4`
  opened once; 04 PC-4.2's re-run line closed (PG-7.1a). No agent principal holds an
  `agentregistry` role.
- [ ] Three PL-10 alerts fired with receipt confirmed by person 2; both fixture PATCHes witnessed with
  empty before-and-after diffs (PG-7.1); the injection suite record gives `n`,
  detection and false-block counts per surface (PG-7.2).
- [ ] K1, K2, K3 and K7 each have a trigger and an effect stamp; the K7 drill left the Gemini
  project's effective policy unchanged; the token residual is written as the one measured in 07
  PW-6.5, not the design's 60 minutes (PG-8).
- [ ] `POV_TIER_C_RECORD` has no empty cell, is not green, and names every open row; no
  `TIER_C_RECORD` was set (PG-9.1).
- [ ] No step text contains a reserved name; `RETIRED_NAMES_CHECK` from file 01 passes on this file.

## What the next file needs from this one

| Consumer | Needs | Rule |
|---|---|---|
| POV [06](06-eve-over-the-human-super-admins.md) | the `discoveryengine` admin-read and data-read entries (PG-3.4); the PL-10 method names (PG-7.1); `GRP_GE_ADMINS` members, so Eve watches every `ent-ge-admin` activation | Eve reads Google-written logs only |
| POV [04](04-the-contract-register-agent-ids-and-schemas.md) | the registry write-alert drill (PG-7.1a, with its `DONE` line for PC-4.2 in `rerun-index.tsv`) and the registration question for the Tier C agents (PG-6.3a: none, with Google's reason) | 04 PC-4.2's alert is cited as working only after PG-7.1a is `DONE` |
| POV [07](07-the-doer-tier-w-and-the-optional-tier-p.md) | `POV_TIER_C_RECORD` (never the full-set `TIER_C_RECORD`, README §7.3); `GEMINI_PROJECT`, `GEMINI_PROJECT_NUMBER`, `GEMINI_APP_ID`; `GE_ARMOR_TEMPLATE` and the floor comparison of PG-5.2 as the pattern for the doer's template; `ENT_GE_ADMIN` for the doer's share; the Tier C lever table, which file 07 extends with K0 and K4; PG-7.1a's proven registry write alert and its pattern (a fresh `ENT_PROJECT_REPAIR_CORE` grant person 2 approves, the id read aloud) for the doer's engine registration (07 PW-5.4a) | file 07 starts only when the record has no empty cell |
| POV [08](08-mo-and-the-value-report.md) | `TIER_C_AGENT_ROWS` (light metric pack); `INJECTION_SUITE_RECORD` counts | every rate with its `n` |
| POV [09](09-the-demonstration-deviations-and-the-hand-over.md) | `KILL_DRILL_RECORD_C`; `INJECTION_SUITE_RECORD`; the open rows of `POV_TIER_C_RECORD` for the hand-over map; `BD-P05-1`; the Tier C lever mapping to index; `DR-P05-4` and the PG-6.3a record | the fourth-agent test copies PG-6.1 and PG-6.2 |
| Full build | setup/05's inventory files as they are; setup/19 reads `ge-baseline/` and re-runs only what PG-9.1 lists OPEN; setup/20 runs whole and writes `TIER_C_RECORD` itself, and its GG-4 registers the app's destinations in `GE_REGISTRY`; setup/16 RG-5.7 runs its own drill and opens `DR-16-1` (`DR-P05-4` is not promoted); setup/12's catalogue gains nothing new (`ent-ge-admin` and `ent-project-repair-core` already have their rows) | a POV record never stands in for G21 |

## Sources

Read on 2026-09-16 by this file; Google's "last updated" date in brackets.

- https://docs.cloud.google.com/gemini/enterprise/docs/reference/rest/v1alpha/projects.locations.collections.engines.assistants.agents [2026-09-03]: methods `create`, `delete`, `deploy`, `get`, `list`, `patch`, `rejectAgent`, `requestAgentReview`, `withdrawAgent`; `state` values `PRIVATE`, `ENABLED`, `DISABLED`, `SUSPENDED`; `SharingConfig.scope` `RESTRICTED`, `ALL_USERS`, unspecified "Behaves as RESTRICTED".
- https://docs.cloud.google.com/gemini/enterprise/docs/reference/rest/v1alpha/projects.locations.collections.engines.assistants.agents/rejectAgent and `/withdrawAgent` [2026-04-21]: both leave the agent `PRIVATE`; reject only from `DISABLED`; withdraw only by the owner. Not used as levers for that reason.
- https://docs.cloud.google.com/gemini/enterprise/docs/agents-overview [2026-09-15]: agent states as administrators see them; delete from **Agents** → **more_vert** → **Delete**.
- https://docs.cloud.google.com/gemini/enterprise/docs/agent-designer/share-agent [2026-09-15]: default sharing without approval; **Review share request**; **Approve and enable**, **Deny**; only holders of the Gemini Enterprise Admin role review.
- https://docs.cloud.google.com/gemini/enterprise/docs/share-custom-agents [2026-09-15]: **Agents** → agent → **User permissions**.
- https://docs.cloud.google.com/gemini/enterprise/docs/manage-web-app-features [2026-09-15]: **Enable agent sharing without admin approval**, **Enable agent sharing**, **Enable End Users to share with Groups**, **Enable chat agents** ("users can build and use custom chat agents"), **Enable workflows**.
- https://docs.cloud.google.com/gemini/enterprise/docs/enable-model-armor [2026-09-15]: **Configurations** → **Assistant** → **Enable Model Armor**; the two template resource-name fields; **Allow user interactions during Model Armor processing failure**; "If the FAIL_MODE is not defined, FAIL_CLOSED is the default"; EU app to EU Model Armor multi-region; regions cannot change; cross-project `roles/modelarmor.user`.
- https://docs.cloud.google.com/gemini/enterprise/docs/configure-assistant [2026-09-15]: Plus edition; retention 1, 30, 60, 90, 120 or 180 days, default 60; chats deleted by creation date "without warning".
- https://docs.cloud.google.com/model-armor/configure-logging [2026-09-10]: sanitize logging "logs the full content of user prompts and model responses"; enabling it "writes raw prompts and responses to Logging", which "might include sensitive user data, personally identifiable information (PII), or confidential information".
- https://docs.cloud.google.com/model-armor/reference/rest/v1/projects.locations.templates: `logSanitizeOperations` "If true, log sanitize operations."
- https://docs.cloud.google.com/gemini/enterprise/docs/correlate-model-armor-logs: resource `modelarmor.googleapis.com/SanitizeOperation`.
- https://docs.cloud.google.com/gemini/enterprise/docs/audit-logging: `EngineService.UpdateEngine`, `AssistantService.UpdateAssistant`, `v1alpha.AgentService.UpdateAgent`.
- https://docs.cloud.google.com/gemini/enterprise/docs/locations [2026-09-15]: `eu-discoveryengine` host.
- https://docs.cloud.google.com/iam/docs/access-change-propagation [2026-09-16]: allow-policy changes "Typically 2 minutes, potentially 7 minutes or longer"; group membership "Typically several minutes, potentially hours or longer".
- https://docs.cloud.google.com/iam/docs/service-account-creds [2026-09-16]: OAuth 2.0 access tokens "By default, these tokens expire after 1 hour".
- https://developers.google.com/identity/protocols/oauth2 [2026-05-26]: "Access tokens have limited lifetimes".
- https://docs.cloud.google.com/agent-registry/setup [2026-09-15]: "Agent Registry operates at the project level"; enabling `agentregistry.googleapis.com` makes the registry available with no separate resource (PG-7.1a).
- https://docs.cloud.google.com/agent-registry/locations [2026-09-15]: "You can't manually register agents, MCP servers, and endpoints, or create bindings in the `us` and `eu` multi-region locations"; `europe-west1` listed (PG-7.1a).
- https://docs.cloud.google.com/agent-registry/manual-registration [2026-09-15]: A2A agents with `--agent-spec-type=a2a-agent-card`, standard REST agents with `--agent-spec-type=no-spec` and `--interfaces=url=ENDPOINT_URL,protocolBinding=PROTOCOL`; `protocolBinding` `http-json`, `grpc`, `jsonrpc`; `roles/agentregistry.editor` to register; not supported in `us` and `eu` (PG-6.3a).
- https://docs.cloud.google.com/agent-registry/register-endpoints [2026-09-15]: an endpoint "represents a target URL, typically a REST API"; `--endpoint-spec-type=no-spec` with `--interfaces` (PG-6.3a, PG-7.1a).
- https://docs.cloud.google.com/agent-registry/automatic-registration [2026-09-15]: "Built-in Google agents, such as Google Workspace and Gemini Enterprise agents, are automatically registered in Agent Registry"; "Automatic registration only discovers resources deployed within the same Google Cloud project"; cross-project agents go to manual registration (PG-6.3a).
- https://docs.cloud.google.com/agent-registry/concepts [2026-09-15]: a `Service` "represents an agent, an MCP server, or an endpoint that is manually added to your registry" and is projected as a read-only `Agent`, `McpServer` or `Endpoint`; the Gemini Enterprise identifier form `urn:agent:projects-PROJECT_NUMBER:projects:PROJECT_NUMBER:locations:REGION:discoveryengine:INSTANCE_ID:root` (PG-6.3a).
- https://docs.cloud.google.com/agent-registry/audit-logging [2026-09-15]: service `agentregistry.googleapis.com`; `google.cloud.agentregistry.v1.AgentRegistry.CreateService` and `...DeleteService` are Admin Activity (`ADMIN_WRITE`) and long-running; such methods "usually generate two audit log entries" (PG-7.1a).
- https://docs.cloud.google.com/agent-registry/roles-permissions [2026-09-15]: `roles/agentregistry.admin`, `.editor`, `.viewer`, `.user`, project level; "avoid granting these roles directly to agents" (§Rules).
- https://docs.cloud.google.com/gemini/enterprise/docs/import-govern-agent-registry [2026-09-15]: imports A2A agents **from** the registry into an app, behind an Agent Gateway; says nothing about no-code agents appearing in the registry (PG-6.3a).
- gcloud reference [2026-06-30], GA with an alpha variant: `agent-registry services create` (`SERVICE`, `--location` required, `--display-name` up to 63 characters, `--description` up to 2,048, `--interfaces` shorthand, JSON or file, `--agent-spec-type` `a2a-agent-card` or `no-spec`, `--endpoint-spec-type` `no-spec` only, `--async`, `--request-id`); `services delete` (`SERVICE`, `--location`, `--async`, `--request-id`; no prompt documented); `services list` (`--location` required); `services describe`. https://docs.cloud.google.com/sdk/gcloud/reference/agent-registry/services/create and `/delete`, `/list`, `/describe`, read 2026-09-16.
- gcloud reference [2026-05-27]: `model-armor templates create` (`--location`, the filter flags, `--template-metadata-log-sanitize-operations`); `pam grants create` (`--entitlement`, `--requested-duration`, `--justification`); `pam entitlements create` (`--entitlement-file`, `--location`, `--async`, and `--folder` or `--organization` for the parent, https://docs.cloud.google.com/sdk/gcloud/reference/pam/entitlements/create, re-read 2026-09-16); `identity groups create` (`--organization`, `--group-type=security`); `identity groups memberships add`; `resource-manager tags bindings list --parent --effective`; `monitoring policies create`; `beta monitoring channels create`; `logging buckets create`.

Relied on, not re-read here: setup/19 §10 (2026-09-15/16: `org-policies set-policy --update-mask`,
dry-run audit entries, `analyze-move`, `beta projects move`, app IAM, Data Access audit) and setup/20
§Sources (log-based alerts, SCC findings).

## Unverified

- Whether the app's Model Armor setting screens Workflow Builder agents as well as the assistant
  (PG-7.2 measures per surface); whether **Enable chat agents** off stops agents already shared
  (PG-8.3 measures); whether a group removed from **User permissions** writes `UpdateAgent`
  (setup/20 Q11; PG-8.2 records); log-based alert latency (PG-7.1 measures).
- Whether an administrator can set an agent to `SUSPENDED` or `DISABLED` from the console: no page
  read on 2026-09-16 documents it, so neither state is used as a lever.
- The lifetime of a user's (not a service account's) access token: Google documents one hour for
  service-account tokens and "limited lifetimes" for OAuth tokens; the 60-minute figure is the design's
  (`wall-e/ARCHITECTURE.md` §4.6) and is not re-proven here.
- Carried from the full set: the toggle-to-`features` key pairing (setup/19 GE-6.4), `sessionTtl` as the
  console retention (setup/05 GI-3.2).
- POV-internal: `confirm_manual`'s signature is `STEP_ID QUESTION` (POV 01); the
  PV-11 variable names of PG-6.1, and that POV 03 sets the `ENT_*` names and `POV_K7_FIRST_DRILL_RECORD`.
- Full-set inconsistency found: setup/19 §2 asks for a register row `tenant-app` with `tier: ge`, which
  setup/16's schema refuses (`C`, `R`, `W`, `P`, `P-SA`, `X`). No `tenant-app` row is created here;
  raised to the platform owner.
- Full-set gap found: setup/19 GE-6.2 obtains the DPO's signature for `sensitiveLoggingEnabled` only,
  while GE-7.1 and GE-7.2 turn on sanitize logging of raw prompts with no signature. This file adds
  the `GE-CONTENT-LOGGING` decision (PG-4.1) and gates PG-5.1 and PG-5.2 on it; setup/19 should do
  the same. Raised to the platform owner.
- Full-set design question: `ent-ge-admin` has no approval (SD-19), so baseline changes to the live
  app rest on a procedural witness here (§Rules). Whether the full build splits it into an
  approval-free lever entitlement and an approval-gated baseline entitlement is for
  [../12-open-decisions.md](../12-open-decisions.md).
- `confirm_manual` records the typed identifier but does not compare it with an expected value; PG-8.4
  and PG-7.1a compare it from `confirmations.tsv` field 5 (`Assumption:` the field order of POV 01's helper).
- Agent Registry, not settled by the pages read on 2026-09-16: whether a no-code agent built in the
  web app appears as its own automatic entry in `GEMINI_PROJECT`'s registry (the documented
  identifier names the app instance, `...:discoveryengine:INSTANCE_ID:root`; PG-6.3a registers
  nothing and PG-9.1 keeps the row OPEN; setup/20 GG-4.1's re-read after GG-0.5 settles it); the
  registry write alert's latency (PG-7.1a measures); whether `gcloud agent-registry services delete`
  prompts (no prompt is documented; PG-7.1a never passes `--quiet` and person 2 reads the id
  first); the service id's allowed characters (`Assumption:` lowercase letters, digits and hyphens,
  as setup/16's `rg-drill-<date>`); the field in `gcloud pam grants describe` that names the
  approver (person 2 reads the JSON; no field name is asserted); that `gcloud pam grants` calls on
  the folder-scoped `ENT_PROJECT_REPAIR_CORE` need `--billing-project` (copied from 03 PF-5.2).
- setup/16 RG-5.7 passes `--quiet` to `services delete`. That is within the full set's rules, which forbid `--yes`, not `--quiet`, and Google documents no prompt for that delete; PG-7.1a still omits it, so person 2 sees any prompt Google may add. setup/05 GI-8.3 reads the registry on the GA `gcloud agent-registry` track, which covers the four kinds it lists (reference updated 2026-06-23).
