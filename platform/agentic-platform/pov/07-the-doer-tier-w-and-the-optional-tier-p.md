# 07. The doer: Tier W with no admin role, and the optional Tier P step

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-17
- Last executed: never
- Stage: POV-2. Step prefix `PW`. Starts only on `POV_EVE_H_LIVE_RECORD` ([06](06-eve-over-the-human-super-admins.md)) and `POV_TIER_C_RECORD` ([05](05-gemini-enterprise-and-tier-c.md) PG-9.1). The full-set name `TIER_C_RECORD` is never set by the POV (README §7.3): a POV record must not satisfy the full build's G21 `need`. Sets `POV_TIER_W_RECORD` (PW-6.6), never the full-set `TIER_W_RECORD` (setup/42 GD-2.2), for the same reason: no Binary Authorization and no deployed verifier (PV-D-12, PV-D-13). Likewise every agent-specific value is `DOER_`-prefixed (README §7.3): the doer's shared-registry entry is `DOER_REGISTRY_ENTRY` (PW-5.4a), never setup/35's `WALLE_REGISTRY_ENTRY`.
- Full-set counterparts, for depth: [setup/30](../setup/30-wall-e-workspace-side.md) (Workspace side), [31](../setup/31-wall-e-project-and-data-plane.md) (project and data plane), [32](../setup/32-wall-e-consents.md) (consent), [33](../setup/33-wall-e-action-services-and-approval-surfaces.md) (action services), [34](../setup/34-wall-e-identity-spike-and-model-armor.md) (identity and Model Armor), [35](../setup/35-wall-e-engine-registration-and-gateways.md) (engine and gateways), and the kill-drill shape of [39](../setup/39-wall-e-stage-0.md) §8.
- BLOCKED on code: **PB-01** (the nine audit tables), **PB-04** (the action service), **PB-05** (the consent command). No manual step in this file replaces any of them.
- Run specs: PW-1.7a, PW-2.1a, PW-2.2a and PW-5.3a are the run specs, the module shape and the zero-diff checker of [setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md) for both projects, as file 06 does for Eve. The nonprod project is built to the same manifest as prod: same services, identities, entitlements and floor.
- Deviations used: PV-D-01, PV-D-03, PV-D-04, PV-D-07, PV-D-08, PV-D-09, PV-D-10, PV-D-11, PV-D-12, PV-D-13, PV-D-15, PV-D-16. Each is written out in [09](09-the-demonstration-deviations-and-the-hand-over.md).
- Decisions read: PV-01, PV-02, PV-06, PV-07, PV-12 (all [02](02-decisions-people-and-the-retrospective-baseline.md)).

## What this part builds

Wall-E's machinery, on an agent that is **not** Wall-E. PV-02 reserves `walle`, `WALLE_PROJECT` and `walle_audit` because [setup/31](../setup/31-wall-e-project-and-data-plane.md) creates `WALLE_PROJECT` in `fld-agents-p-sa-prod` (WD-2.1, `register_tier="P-SA"`), project ids are never reusable, and a project never moves between tier folders ([02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §1.5). So the doer carries its own permanent `agent_id` (`AGENT_ID_DOER`, `Assumption:` `steward`, signed in PV-02) and lands where [register-row.schema.json](../setup/16-register-and-shared-registry.md) (RG, lines 250-345) lets a robot with no admin role land: **Tier W, `privilege: none`, `verifier: platform-verifier`, `metric_pack: full`** (PV-D-08).

At the end of the mandatory part the tenant holds:

1. **Workspace side** (§1): the doer's robot account in `SERVICE_IDENTITY_OU`, holding no admin role, with two hardware keys and no recovery channel; four groups; `PILOT_OU` of synthetic accounts (PV-06) and an empty `NONPROD_OU`; a roster entry; and **a proof, signed by two people, that no domain-wide delegation client exists for anything this file creates**.
2. **Projects and data plane** (§2): `DOER_PROJECT` in `fld-agents-w-prod` and `DOER_NONPROD_PROJECT` in `fld-agents-w-nonprod` (nonprod is mandatory from Tier W, [02](../02-landing-zone-and-tiers.md) §2 table); `<agent_id>_audit` with the nine insert-only tables from [04](04-the-contract-register-agent-ids-and-schemas.md)'s DDL; Firestore with point-in-time recovery and a daily backup; **one restore drill**, which the Tier W gate requires ([01-hld.md](../01-hld.md) §0.4).
3. **The consent sitting** (§3): exactly two people, no screen share, no service identity as the second person (SD-48); one OAuth client; the token into Secret Manager by name and pinned version only.
4. **The action service and the ladder** (§4): the only credential holder, deployed under a grant a second person approves, image digest compared (PV-D-12). L1 forces `dry_run` and refuses even a valid approval; `audit_unavailable` is a denial reason; L3 checks nonce, expiry and self-approval; band B exists at L0 and refuses.
5. **Engine, identity, gateways, floor** (§5): Agent Identity, egress and ingress gateways with `failOpen: false`, Model Armor at the Tier W floor, **the engine's one entry in the shared Agent Registry (`AGENT_REGISTRY`), keyed on `agent_id` and written by a human under a grant the second person approves**, registration in Gemini Enterprise, and the Tier W register row green. With these, the doer passes the three elements every agent must go through: agent identity, agent registry, Model Armor.
6. **The ladder walk and the kill drill** (§6): L1, L2, L3 under the platform dwell times, **K0 pulled during a live L3 run**, then K1, K2, K3, K4 and K7 timed.
7. **Optional, separately gated: the Tier P step** (§7). A new agent, a new robot, a new project in `fld-agents-p-prod`; Pilot Reader and Pilot Writer (OU-scoped to `PILOT_OU`); `privilege: workspace_role:pilot_writer`, `verifier: eve`; a K6-analogue drill that **does not close G11** (PV-D-09).

**Model Armor produces evidence, not a boundary.** Nothing in this file is reported as "Model Armor blocked the injection". The boundary is that the model holds no credential.

**Nothing in this file is evidence about a super admin.** No agent here holds, or is tested as, Super Admin (PV-04, PV-D-04).

## Preconditions

- [ ] [06](06-eve-over-the-human-super-admins.md): `POV_EVE_H_LIVE_RECORD` merged and signed by the second person (the full-set `EVE_H_LIVE_RECORD` of setup/28 EV-8.2 stays unset: the POV's Eve has no witness alarms). Eve watches every human super admin, including the operator of this file, before the first doer object exists.
- [ ] [05](05-gemini-enterprise-and-tier-c.md): `POV_TIER_C_RECORD` exists with every open row named (PG-9.1); `GEMINI_PROJECT`, `GEMINI_APP_ID` set. `TIER_C_RECORD` is **unset** (PW-0.1 checks it); never set it by hand to pass a gate. PG-7.1a is `DONE` in `checkpoints.tsv`: the registry write alert has emailed the second person once, so PW-5.4a's write is a watched write.
- [ ] [04](04-the-contract-register-agent-ids-and-schemas.md): the run-spec template and the zero-diff checker merged and proven (PC-4.2a to PC-4.2d, `PC-4.2d DONE`); `GRP_PLATFORM_SECURITY` from 03 for the specs' contacts; `AGENT_REGISTRY` (PC-4.1, `projects/<CORE_PROJECT>/locations/europe-west1`, no standing writer) and the registry write alert policy in `CORE_PROJECT` (PC-4.2); `DOER_REGISTER_ROW`, `DOER_REGISTER_ROW_NONPROD`, `AUDIT_SCHEMA_COMMIT`, `LADDER_SCHEMA_COMMIT`, `MANUAL_PARSE_RECORD` merged; `register/reserved/names.yaml` merged (04 PC-1.3); the doer's tree at `<agent_id>/` of the platform repository (`<agent_id>/AUDIT_TABLES`, `<agent_id>/schemas/`, `<agent_id>/agent-manifest.yaml`, 04 PC-2.4, PC-3.1 and PC-3.5). `AUDIT_DDL_COMMIT` (PB-01) is needed by PW-2.5 only and is checked there, so its absence does not hold §1, §2 or §3.
- [ ] Repository layout, one for the whole file, matching 04 and the full set ([setup/31](../setup/31-wall-e-project-and-data-plane.md), [37](../setup/37-wall-e-sandbox-rehearsal.md), [39](../setup/39-wall-e-stage-0.md)): the doer's code, config and consent command under `<agent_id>/` (`<agent_id>/bin/consent`, `<agent_id>/config/scopes.txt`, `<agent_id>/config/hard_denied.yaml`, `<agent_id>/config/protected_floor.txt`); the ladder at `ladder/<agent_id>/ladder.yaml`, so the `/ladder/` CODEOWNERS line of [01](01-conventions-and-variables.md) PP-5.2 makes the second person a required reviewer of every raise; the rendered caller allowlist in the build log, `$BUILD_LOG_DIR/allowlists/`. **Check before PW-3.1:** [02](02-decisions-people-and-the-retrospective-baseline.md) PD-4.3's scope-hash VERIFY reads `<agent_id>/config/scopes.txt`, not `agents/<agent_id>/config/scopes.txt`; if 02 still names `agents/`, stop and have 02 amended, because the two hashes would then be of different files.
- [ ] [03](03-foundation-folders-logging-and-floors.md): `FLD_AGENTS_W_PROD`, `FLD_AGENTS_W_NONPROD`, `FLD_AGENTS_P_PROD`, `FLD_AGENTS_P_NONPROD`, `CICD_PROJECT`, `AR_PLATFORM`, `LOGGING_PROJECT`, `KMS_PROJECT`, `KR_ENGINES`, `BILLING_ACCOUNT_ID`, `TAG_KEY_TIER`, `PAM_ENTITLEMENTS`, `FLOOR_RECORD` (PF-8.2), `K7_POLICY_DIR` and `POV_K7_FIRST_DRILL_RECORD` (PF-9.1 to PF-9.3), `PLATFORM_EVIDENCE_BUCKET`, `SA_1_ADMIN`, `SA_2_ADMIN`, `ROSTER_FILE`, `DIRECTORY_CUSTOMER_ID`, `ORG_ID`, `FLD_AGENTS_P_SA_PROD`, `FLD_AGENTS_P_SA_NONPROD`, `CORE_PROJECT`, `NOTIF_CH_EMAIL_CORE` (PF-7.3, the email channel to the second person), and `ENT_PROJECT_REPAIR_CORE` (PF-5.1, folder-scoped at `fld-platform-core`, carrying `roles/agentregistry.admin` per setup/12 PA-4.2: the only lawful human path to write `AGENT_REGISTRY`). These are the full-set spellings file 03 sets with `penv_set` (03's name table); the retired `CUSTOMER_ID` is refused by `penv_set`.
- [ ] [02](02-decisions-people-and-the-retrospective-baseline.md): PV-01, PV-02, PV-06, PV-07 (for §7 only), PV-12 signed; `SECOND_HUMAN_EMAIL`, `SECOND_OPERATOR_EMAIL`, `BLIND_GRADER_EMAIL`, `SECURITY_REVIEWER_EMAIL`, `MODEL_ID`, `PILOT_POPULATION_COUNT`, `NAMES_RECORD`, `RESERVED_NAMES_RECORD` set. `decision-need.sh PV-01 PV-02 PV-06 PV-12` exits 0. The NAMES record ([02](02-decisions-people-and-the-retrospective-baseline.md) PD-3.2) carries the Values this file reads: `SERVICE_IDENTITY_OU`, `PILOT_OU`, `NONPROD_OU`, `DOER_ROBOT`, `DOER_PROJECT`, `DOER_NONPROD_PROJECT`, `DOER_AUDIT_DS` (and, for §7, `PILOT_ADMIN_ROBOT`, `PILOT_ADMIN_PROJECT`, `PILOT_ADMIN_NONPROD_PROJECT`). **Check:** `for n in SERVICE_IDENTITY_OU PILOT_OU NONPROD_OU DOER_ROBOT DOER_PROJECT DOER_NONPROD_PROJECT DOER_AUDIT_DS; do "$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES "$n" >/dev/null || echo "MISSING NAMES $n"; done` prints nothing; a missing row is added by a superseding NAMES record in 02, never typed here.
- [ ] Purchases ([02](02-decisions-people-and-the-retrospective-baseline.md)): one Gmail-bearing Workspace licence for the robot, `PILOT_POPULATION_COUNT` licences for the synthetic accounts, two hardware keys for the robot in the safe.
- [ ] Code: PB-01, PB-04, PB-05 each at a commit reviewed by someone other than its author. Until then, every step naming them stays BLOCKED and the file runs §1, §2 (except PW-2.5) and §3's refusals only.
- [ ] Workstation of [01](01-conventions-and-variables.md): `~/.platform-env` sourced, `penv_guard` silent, a new clean browser profile for the robot; `PLATFORM_REPO_REMOTE` (PP-5.3), `RETIRED_NAMES_CHECK` (PP-3.5) and `POV_STAGE` = `POV-1` (PP-1.3) set; `confirm_manual` of PP-1.3 sourced from `tools/pov-lib.sh`.

## People

| Role | Does | Present at |
|---|---|---|
| Person 1, the platform owner, as `sa-1-admin@` | Builds; requests every grant; never approves their own grant; never verifies their own evidence | every step |
| Person 2, the second person (`SECOND_HUMAN_EMAIL`, as `sa-2-admin@`) | Approves grants; second body at the consent sitting; custodian of robot key B; repeats the DWD proof on their own screen; approves the deploy grant; approves the `ENT_PROJECT_REPAIR_CORE` grant for the registry write, reads the entry's id aloud and confirms the registry write alert email; signs IRREVERSIBLE steps. **Never a member of any doer group** | PW-1.4, PW-1.6, PW-2.1, PW-3.x, PW-4.3, PW-5.4a, PW-8.1 |
| Person 3, second operator, blind grader, security reviewer (`SECOND_OPERATOR_EMAIL`, `BLIND_GRADER_EMAIL`, `SECURITY_REVIEWER_EMAIL`) | Member of `<agent_id>-operators@`; approves L3 requests person 1 makes; grades the L1 sample; signs the manual parses (PV-D-13) and the Tier W record; **mandatory from the first graded L3 promotion** (PV-09) | PW-4.8, PW-6.1 to PW-6.4, PW-6.7 |
| A colleague with no admin and no GCP role | Runs the negative tests a privileged account cannot run honestly | PW-4.6, PW-5.7 |

Hands-on for §0 to §6 and §8: about 5 person-days of procedure over 3 weeks elapsed, plus the code (`Assumption:` PB-01 2 to 3, PB-04 22 to 35 and PB-05 2 to 4 engineer-days, so 26 to 42 in all; README §8), plus the ladder dwell of PW-6.2 (two weeks at L1 and two at L2). The optional §7 is costed separately in its own introduction and is **not** in these figures. Conventions of [01](01-conventions-and-variables.md) apply. Deviation rows `BD-P07-<n>`; records `<date>-PW-<step>-<slug>-v<n>`. Every shell block starts with:

```bash
source ~/.platform-env
penv_guard
R="$BUILD_LOG_DIR/records/$(date -u +%F)-PW"
A="$AGENT_ID_DOER"; AU="${A//-/_}"          # agent_id, and its dataset spelling (05-registry lines 428, 501)
# The reserved names, one per line, read from 04 PC-1.3's register/reserved/names.yaml (RESERVED_NAMES_RECORD is the
# signed PV-02 decision record in markdown, not a name list). Descriptive entries containing a space are skipped.
reserved_names() { python3.12 -c 'import sys,yaml; [print(r["name"]) for r in yaml.safe_load(open(sys.argv[1]))["reserved"] if " " not in r["name"]]' "$PLATFORM_REPO_DIR/register/reserved/names.yaml"; }
```

`DOER_REPO_REMOTE` is the doer's code repository, the POV's counterpart of the full set's `WALLE_REPO_REMOTE` ([setup/30](../setup/30-wall-e-workspace-side.md) WW-1), `EVE_CONFIG_REPO` and `MO_REPO_REMOTE`. In the POV it is the platform repository itself, with the doer's tree under `<agent_id>/`, because that repository already carries the humans-only write, CODEOWNERS and two-reviewer protection of [01](01-conventions-and-variables.md) PP-5.1 to PP-5.5; its local clone is `PLATFORM_REPO_DIR`. It is set once, in PW-0.1, and every step that means the doer's code repository names `DOER_REPO_REMOTE`. The full build gives Wall-E its own repository; nothing here is promoted into it by renaming.

Service identities are derived, never typed: `${A}-actions@`, `${A}-agent@`, `${A}-operators-caller@`, `${A}-tasks@` in `DOER_PROJECT`, mirroring [setup/31](../setup/31-wall-e-project-and-data-plane.md) WD-2.5 with no `-super` account (band B shares the one service in the POV, §4).

---

## 0. The sitting

### PW-0.1 Open the sitting, check the gates, re-assert the reservation

- **WHO:** Platform owner; the second person reads the output.
- **WHERE:** shell, `~/.platform-env` sourced.
- **ACTION:**

```bash
pw01_open() {
  checkpoint PW-0.1 START || return 1
  need AGENT_ID_DOER POV_EVE_H_LIVE_RECORD POV_TIER_C_RECORD DOER_REGISTER_ROW DOER_REGISTER_ROW_NONPROD LADDER_SCHEMA_COMMIT \
       FLD_AGENTS_W_PROD FLD_AGENTS_W_NONPROD FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD DIRECTORY_CUSTOMER_ID KR_ENGINES TAG_KEY_TIER FLOOR_RECORD K7_POLICY_DIR \
       MODEL_ID PILOT_POPULATION_COUNT SECOND_HUMAN_EMAIL SECOND_OPERATOR_EMAIL BLIND_GRADER_EMAIL RESERVED_NAMES_RECORD \
       PLATFORM_REPO_REMOTE RETIRED_NAMES_CHECK POV_STAGE WIKI_DIR || return 1
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-01 PV-02 PV-06 PV-12 || return 1
  [ -z "${TIER_C_RECORD:-}" ] || { echo "STOP: TIER_C_RECORD is set; a POV record must not satisfy the full-set gate (README §7.3)"; return 1; }
  echo "TIER_C_RECORD unset (README §7.3)"
  [ "$(reserved_names | wc -l)" -ge 4 ] || { echo "STOP: register/reserved/names.yaml unreadable or short (04 PC-1.3)"; return 1; }
  reserved_names | grep -qxF "$A" && { echo "STOP: AGENT_ID_DOER is a reserved name (PV-02)"; return 1; }
  echo "agent_id $A is not reserved"
  grep -rnwFf <(reserved_names) "$PLATFORM_REPO_DIR/register/${A}.yaml" "$PLATFORM_REPO_DIR/${A}" && { echo "STOP: reserved name in the doer's row or tree"; return 1; }
  echo "no reserved name in the row or tree"
  "$RETIRED_NAMES_CHECK" "$WIKI_DIR/platform/agentic-platform/pov/07-the-doer-tier-w-and-the-optional-tier-p.md" || return 1
  [ -z "$(gcloud projects list --filter="parent.id=${FLD_AGENTS_P_SA_PROD} OR parent.id=${FLD_AGENTS_P_SA_NONPROD}" --format="value(projectId)")" ] || { echo "STOP: a project exists under fld-agents-p-sa-*"; return 1; }
  test -z "$(gcloud config get project 2>/dev/null)" || { echo "STOP: a default project is set"; return 1; }
  echo "no default project"
  penv_set DOER_REPO_REMOTE "$PLATFORM_REPO_REMOTE" || return 1
  [ "$POV_STAGE" = POV-1 ] && { penv_set --force POV_STAGE POV-2 || return 1; }
  source ~/.platform-env; [ "$POV_STAGE" = POV-2 ] || { echo "STOP: POV_STAGE is $POV_STAGE, not POV-2"; return 1; }
  checkpoint PW-0.1 DONE "$SECOND_HUMAN_EMAIL" "${R}-0.1-gates-v1.txt"
}
pw01_open 2>&1 | tee "${R}-0.1-gates-v1.txt"; [ "${PIPESTATUS[0]}" -eq 0 ] || echo "PW-0.1 STOPPED: nothing after the failing line ran; no doer object may be created"
```

- **VERIFY:** No `STOPPED` line; `need` silent (a failure names a file 01, 02, 03, 04 or 05 step still owed; never `penv_set` a missing name by hand; `AUDIT_DDL_COMMIT` is deliberately not needed here, PW-2.5 checks it); `decision-need.sh` exits 0; `TIER_C_RECORD unset (README §7.3)` (the tag in that printed line names README §7.3's rule); `agent_id ... is not reserved`; `no reserved name in the row or tree`; `RETIRED_NAMES_CHECK` (the [01](01-conventions-and-variables.md) PP-3.5 tool, which reads the bash fences of markdown files only) exits 0 over this file; the `fld-agents-p-sa-*` listing is empty; `no default project`; `DOER_REPO_REMOTE` equals `PLATFORM_REPO_REMOTE`; `POV_STAGE` reads `POV-2` and `variables-changes.tsv` holds the one `--force` line for it (the move [01](01-conventions-and-variables.md) promises happens exactly once, here). YAML files in the row and the tree are checked for reserved names by the `grep` above, not by `RETIRED_NAMES_CHECK`.
- **ROLLBACK:** Read only, except two variable writes: `penv_set --force POV_STAGE POV-1` and `penv_set --force DOER_REPO_REMOTE "*tbd*"`, each with a build-log line, if the stage must be reopened.
- **EVIDENCE:** Output as `${R}-0.1-gates-v1.txt`; `evidence_add PW-0.1 gates-and-reservation E-05 1.3.1 build-log:records <file>`. E-05. TISAX 1.3.1.

### PW-0.2 Announce the robot and the alerts

- **WHO:** Platform owner.
- **WHERE:** mail to the second person, person 3 and the incident commander.
- **ACTION:** Say, dated: the robot address from the NAMES record will be created; its sign-in during PW-1.4 and PW-3.3 will fire the robot-login rule (PW-1.7) and Eve's roster diff; no role will appear on it in §1 to §6; the engine's registration at PW-5.4a will fire the registry write alert of [04](04-the-contract-register-agent-ids-and-schemas.md) PC-4.2 once, expected.
- **VERIFY:** The mail is sent before PW-1.3 and filed.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** The mail as `${R}-0.2-announcement-v1.eml`. E-08. TISAX 1.6.1.

---

## 1. The Workspace side

Full-set depth: [setup/30](../setup/30-wall-e-workspace-side.md) §2 to §7. What differs: four groups not three, because the owner group is created here and not in a factory (PV-D-01); no witness uploads (PV-D-03); no `SANDBOX_OU` at all (PV-D-04).

### PW-1.1 Create the four doer groups as security groups

- **WHO:** Platform owner as `sa-1-admin@`; the second person reviews the control-group amendment as code owner.
- **WHERE:** `PLATFORM_REPO_DIR` pull request; then Admin console Menu > Directory > Groups > Create group.
- **ACTION:** Amend the control-group list with the NAMES addresses, merge, then create each group with **Labels: Security** ticked, "Who can join: Only invited users", no external members, exactly as [setup/30](../setup/30-wall-e-workspace-side.md) WW-2.1 to WW-2.4:

| Group | Purpose | Members at creation |
|---|---|---|
| `<agent_id>-operators@` | halt, demote, veto, approve, reach the doer in Gemini Enterprise | person 1's daily account, `SECOND_OPERATOR_EMAIL` |
| `<agent_id>-readers@` | ask read-only questions | person 1's daily account |
| `<agent_id>-protected@` | every principal the doer may never write to | filled in PW-1.5 |
| `<agent_id>-owners@` | the register row's `owner_group` | person 1's daily account |

```bash
for g in operators readers protected owners; do gcloud identity groups describe "${A}-${g}@${DOMAIN}" --format="value(name)" >/dev/null 2>&1 && echo "EXISTS ${A}-${g}@" || echo "free ${A}-${g}@"; done
# after creation, WW-2.5's comparison with the merged list, then:
penv_set GRP_DOER_OPERATORS "${A}-operators@${DOMAIN}"; penv_set GRP_DOER_READERS "${A}-readers@${DOMAIN}"
penv_set GRP_DOER_PROTECTED "${A}-protected@${DOMAIN}"; penv_set GRP_DOER_OWNERS "${A}-owners@${DOMAIN}"
```

- **VERIFY:** Four `free` lines before creation; WW-2.5's script, pointed at these four addresses, prints `GROUPS MATCH LIST`; the second person is in none of the four.
- **ROLLBACK:** **IRREVERSIBLE as a label:** a security group cannot become a plain group again. Confirm before each save: the merged list carries the address with `security_label: true`, the address was `free`, the spelling on screen equals the NAMES record. Gate: NAMES (PV-03) and the merged list. Membership is reversible (Members > Remove).
- **EVIDENCE:** Merge commit and the comparison output as `${R}-1.1-groups-v1`. E-08. TISAX 4.1.1, 4.2.1.

### PW-1.2 Create `SERVICE_IDENTITY_OU`, `PILOT_OU` with its synthetic accounts, and `NONPROD_OU`

- **WHO:** Platform owner as `sa-1-admin@`.
- **WHERE:** Admin console Menu > Directory > Organizational units > Create; Menu > Directory > Users > Add new user; Menu > Security > Authentication > 2-step verification.
- **ACTION:**
  1. `SERVICE_IDENTITY_OU` at the NAMES path (full set creates it in [setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) EW-3.2 for `eve@`; the POV's Eve holds no robot, PV-D-07, so it is created here with the same path and settings) and a staging OU beside it. On `SERVICE_IDENTITY_OU`: 2SV enforced, **Only security key**, no security codes, no trust-device, no enrolment period. On the staging OU: 2SV allowed with a security key and a one-week enrolment period.
  2. `PILOT_OU` at the PV-06 path, description "Synthetic accounts only (PV-06). No real person enters without PV-06's three conditions." Create exactly `PILOT_POPULATION_COUNT` accounts named so nobody mistakes them for staff (`<agent_id>-pilot-01@` onwards), no admin role.
  3. `NONPROD_OU`, empty, the value the nonprod ladder's `ou_allowlist` names, so a ladder file copied across environments refuses on scope.

```bash
# All three OU paths are NAMES Values (02 PD-3.2); PV-06 carries only PILOT_POPULATION_COUNT. A failed read writes nothing.
for n in SERVICE_IDENTITY_OU PILOT_OU NONPROD_OU; do
  v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES "$n") && [ -n "$v" ] && penv_set "$n" "$v" || { echo "STOP: no signed NAMES value for $n"; break; }
done
```

- **VERIFY:** The three OUs exist; `PILOT_OU` holds exactly `PILOT_POPULATION_COUNT` users, none in `<agent_id>-protected@`, none an admin (read `users.list` with `query=orgUnitPath='<PILOT_OU>'` in the APIs Explorer and count); `NONPROD_OU` holds none; the 2SV page on `SERVICE_IDENTITY_OU` shows Override with the values above.
- **ROLLBACK:** Delete the synthetic accounts, then the empty OUs. A 2SV Override returns to Inherit.
- **EVIDENCE:** OU list, account list and 2SV screenshot as `${R}-1.2-ous-v1`. E-05. TISAX 4.1.2.

### PW-1.3 Create the robot in the staging OU, with no recovery channel

- **WHO:** Platform owner as `sa-1-admin@`.
- **WHERE:** Admin console Menu > Directory > Users > Add new user; the clean robot browser profile.
- **ACTION:** As [setup/30](../setup/30-wall-e-workspace-side.md) WW-3.1 to WW-3.3: confirm a free Gmail-bearing seat; create the NAMES address in the staging OU; assign the licence; set the password from the corporate vault's generator so the value exists only in the vault; remove any recovery email or phone. Record the vault entry's **name** only.

```bash
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES DOER_ROBOT) && [ -n "$v" ] && penv_set DOER_ROBOT "$v" || echo "STOP: no signed NAMES value for DOER_ROBOT"
```

- **VERIFY:** The user page shows the staging OU, the licence, no admin role; Security > Recovery information is empty; nothing in `BUILD_LOG_DIR` or `~/.platform-env` holds the password (no step writes it).
- **ROLLBACK:** Delete the user while it holds nothing.
- **EVIDENCE:** Licence and recovery screenshots as `${R}-1.3-robot-v1`. E-08. TISAX 4.1.2.

### PW-1.4 Two keys, counted by eye, then the move into `SERVICE_IDENTITY_OU`

- **WHO:** Platform owner operates; **the second person is present** and takes key B.
- **WHERE:** the clean robot profile; Admin console Menu > Directory > Users > the robot > Security; the safe.
- **ACTION:** Exactly [setup/30](../setup/30-wall-e-workspace-side.md) WW-4.1, WW-4.2, WW-4.5 and WW-4.6, in that order: register key A and key B; count the keys **by eye** on the user's Security page and type the count back through WW-4.2's attestation block (never `isEnrolledIn2Sv`); seal key A (person 1) and key B (person 2) in separate envelopes with signed custody records; only then move the robot to `SERVICE_IDENTITY_OU`, sign out, sign in again and prove the key is forced and the Admin console refuses. Custody scans go to `EVIDENCE_INTERIM_LOCATION` the same day and to `PLATFORM_EVIDENCE_BUCKET` (no witness organisation, PV-D-03).
- **VERIFY:** `attestations.tsv` carries `security_keys_observed=2` for PW-1.4; the sign-in offers no code fallback; the Admin console refuses the robot.
- **ROLLBACK:** Before the move: remove and re-register a key. After the move, removing a key without replacing it first is a lock-out; move back to the staging OU first.
- **EVIDENCE:** Attestation line, two custody scans, forced-key screenshot countersigned by the second person, as `${R}-1.4-keys-v1`. E-08. TISAX 4.1.2, 3.1.

### PW-1.5 No admin role on the robot; the roster entry; the protected floor

- **WHO:** Platform owner writes; the second person reviews the roster pull request as code owner.
- **WHERE:** APIs Explorer on the Directory API reference pages in person 1's clean profile; `PLATFORM_REPO_DIR`.
- **ACTION:**
  1. Run `users.get` (`userKey` = `DOER_ROBOT`, `projection=full`, `viewType=admin_view`) and apply WW-3.4's assertions: `isAdmin` and `isDelegatedAdmin` not true, no recovery field.
  2. Run `roleAssignments.list` with `userKey` = `DOER_ROBOT`: the list is empty.
  3. Add the robot to `ROSTER_FILE` as `kind: robot`, `workspace_roles: []`, `rule: any role on this account before a signed PV-07 Tier P record is role_assignment_added, severity 1` (WW-3.5's shape), so Eve's roster diff ([06](06-eve-over-the-human-super-admins.md)) is quiet now and pages on any role.
  4. Inventory every super admin and delegated admin (WW-6.1's two separate `users.list` reads, `isAdmin=true` then `isDelegatedAdmin=true`, refusing a paginated or duplicated read), add them **plus the robot itself** to `<agent_id>-protected@`, and commit `<agent_id>/config/protected_floor.txt` by pull request (WW-6.3).
- **VERIFY:** Both assertions print; `roleAssignments.list` returns no `items`; the roster merge exists with two approvals; committed floor line count equals `gcloud identity groups memberships list --group-email="$GRP_DOER_PROTECTED" --format='value(preferredMemberKey.id)' | wc -l`.
- **ROLLBACK:** Read-only for 1 and 2; revert the pull requests for 3 and 4 (a removal from the protected group widens the doer's reach and is a two-person change).
- **EVIDENCE:** The JSON reads, merge commits and count as `${R}-1.5-no-role-roster-floor-v1`. E-08. TISAX 4.2.1.

### PW-1.6 Prove that no domain-wide delegation exists: `DWD_ABSENCE_PROOF`, first half

- **WHO:** Platform owner as `sa-1-admin@`; **the second person repeats the read independently as `sa-2-admin@`** on their own workstation.
- **WHERE:** Admin console Menu > Security > Access and data control > API controls > **Manage Domain Wide Delegation** (a super-admin page, read 2026-09-16).
- **ACTION:** Read the whole API clients list. Compare every row with the inventory [03](03-foundation-folders-logging-and-floors.md) took at the roster step. Then, in the shell, list every service account in both doer projects (after PW-2.2) and every OAuth client id created in §3, and search the DWD list for each numeric client id.

```bash
for P in "$DOER_PROJECT" "$DOER_NONPROD_PROJECT"; do
  gcloud iam service-accounts list --project="$P" --format="value(email,uniqueId)"
done | tee "${R}-1.6-client-ids-v1.tsv"
```

  Absence is proved per client id, not assumed from "we never created one". Google documents no API that lists delegation clients, so the list is read on screen by two people.
- **VERIFY:** No client id from the TSV, and later no OAuth client id from PW-3.2, appears in the DWD list; the list equals [03](03-foundation-folders-logging-and-floors.md)'s inventory. **A new entry is reported to the second person and the incident commander the same hour, never used, and never deleted by person 1 alone.** Both people sign the screenshot. This step is re-run in full at PW-8.1.
- **ROLLBACK:** Read only. No step of the POV creates a delegation entry.
- **EVIDENCE:** Countersigned screenshots and the TSV as `${R}-1.6-dwd-absence-v1`; `penv_set DWD_ABSENCE_PROOF "<record path>"`; `evidence_add PW-1.6 dwd-absence E-05 4.2.1 ...`. TISAX 4.2.1, 5.2.

### PW-1.7 The robot-login activity rule

- **WHO:** Platform owner; person 3 confirms receipt in writing.
- **WHERE:** Admin console Menu > Rules > Create rule > Activity rule; data source **User log events**.
- **ACTION:** As [setup/30](../setup/30-wall-e-workspace-side.md) WW-8.2 and WW-8.4: condition actor = `DOER_ROBOT`, event login success; severity high; recipients person 1's daily account and `SECOND_OPERATOR_EMAIL` as **named individuals**, never a group. If the edition offers no activity rules, use WW-8.6's log-based metric fallback and open `BD-P07-1`.
- **VERIFY:** PW-1.4's sign-in (or a fresh one) produced one alert that person 3 confirms with a latency, in writing. Allow up to 24 hours before calling the rule broken.
- **ROLLBACK:** Delete the rule.
- **EVIDENCE:** Rule screenshot and person 3's confirmation as `${R}-1.7-login-rule-v1`. E-08. TISAX 4.1.2, 1.6.1.

### PW-1.7a Write and merge the run specs for `DOER_PROJECT` and `DOER_NONPROD_PROJECT`, before either exists

- **WHO:** Platform owner writes; **two human reviewers who are not the platform owner approve the merge, the second person one of them**.
- **WHERE:** Shell, branch `fm-spec-<agent_id>`, then the git host.
- **ACTION:** [setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md) FM-2.1 with FM-AGENT's `agent-project` values, one spec per environment, filled from the template (04 PC-4.2a), `DOER_REGISTER_ROW`, `DOER_REGISTER_ROW_NONPROD` and NAMES, as file 06 PE-1.1a does for Eve. The two specs differ only in `env`, project id, parent folder, `run_id` and budget: a Tier W agent's nonprod project carries the same manifest ([02](../02-landing-zone-and-tiers.md) §1.3, control W9), so it gets the same services, identities, entitlements and floor. **Where this file builds something, the spec states exactly what this file builds**; where the POV deliberately does less than FM-AGENT, the spec records the POV's real state:

  | Key | Value in the POV | Why |
  |---|---|---|
  | `services` | the thirteen PW-2.1 enables, on both projects | `observability.googleapis.com` is there for PW-2.1a's `_Trace` call |
  | `service_accounts`, `project_bindings` | `${A}-actions`, `${A}-agent`, `${A}-operators-caller`, `${A}-tasks`; `${A}-actions@` holds exactly [setup/31](../setup/31-wall-e-project-and-data-plane.md) WD-2.5's four roles and the other three hold none | PW-2.2 creates them before the first checker run |
  | `project_floor` | `applies: true`, tier `W`, PI `HIGH`, Responsible AI `MEDIUM_AND_ABOVE`, `vertex_ai: true`, enforcement from `floors.json`'s `measured_flip.W` (`INSPECT_ONLY` unless measured) | PW-5.3 writes it after the first checker run, so the eight `floor.*` checks are `pending` until PW-5.3a |
  | `notification_channels` | none | FM-2.13's baseline channels are `made_elsewhere` (setup/31; PV-D-10) |
  | `deny_entries` | none | FM-3.2's per-agent deny entries are `made_elsewhere` (setup/31). In the POV the doer's principals are covered only as far as `deny-agents-platform` covers the Tier W folders (03 PF-5.4); that is stated, not claimed as FM-3.2 |
  | `pab_bindings` | none | `pab-agents` has no binding in the POV (03 PF-5.4) |
  | `entitlements` | `ent-project-repair-${A}`, `ent-deploy-credential-holder-${A}`, in each project | PW-2.2 |

  Labels: `agent`, `owner` `${A}-owners`, `tier` `w`, `env`, `data_class` `evidence`, `ai_act_class` and `recovery_class` read from the merged row in lower case, `cost_centre` `tbd` (a label cannot hold `*tbd*`), `created_by` `bootstrap-hand`, and `factory_run`, which equals `run_id` (`dev-p07-agent-<agent_id>-<env>`). Budgets are setup/17's tier table: 300 for prod, 150 for nonprod. Binary Authorization (FM-3.3) is PV-D-12's and `made_elsewhere`.

```bash
source ~/.platform-env
penv_guard
R="$BUILD_LOG_DIR/records/$(date -u +%F)-PW"
A="$AGENT_ID_DOER"
pw17a() {
  need PLATFORM_REPO_DIR PLATFORM_REPO_SLUG DOER_REGISTER_ROW DOER_REGISTER_ROW_NONPROD GRP_DOER_OWNERS GRP_PLATFORM_SECURITY FLD_AGENTS_W_PROD FLD_AGENTS_W_NONPROD SECOND_HUMAN_EMAIL NAMES_RECORD A || return 1
  grep -qE 'PC-4\.2d[[:space:]]+DONE' "$BUILD_LOG_DIR/checkpoints.tsv" || { echo "STOP: POV 04 PC-4.2d is not DONE; the checker is not proven"; return 1; }
  checkpoint PW-1.7a START "$SECOND_HUMAN_EMAIL" - "run specs for the doer's two projects before either exists" || return 1
  git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only || return 1
  git -C "$PLATFORM_REPO_DIR" switch -c "fm-spec-${A}" || return 1
  ET="$(jq -r '.measured_flip.W // "INSPECT_ONLY"' "$PLATFORM_REPO_DIR/model-armor/floors.json")"
  for E in prod nonprod; do
    if [ "$E" = prod ]; then VAR=DOER_PROJECT; FV=FLD_AGENTS_W_PROD; FID="$FLD_AGENTS_W_PROD"; ROW="$DOER_REGISTER_ROW"; AMT=300
    else VAR=DOER_NONPROD_PROJECT; FV=FLD_AGENTS_W_NONPROD; FID="$FLD_AGENTS_W_NONPROD"; ROW="$DOER_REGISTER_ROW_NONPROD"; AMT=150; fi
    PID="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES "$VAR")" && [ -n "$PID" ] || { echo "STOP: NAMES has no $VAR"; return 1; }
    gcloud projects describe "$PID" --format='value(projectId)' 2>/dev/null && { echo "STOP: $PID exists; the spec comes first (resume rule)"; return 1; }
    RC="${ROW#*@}"; RC="${RC%%:*}"; [ -n "$RC" ] || { echo "STOP: no register commit in $ROW"; return 1; }
    AIC="$(yq -r ".rows[] | select(.env == \"$E\") | .ai_act_class" "$PLATFORM_REPO_DIR/register/${A}.yaml" | tr 'A-Z' 'a-z')"
    RCL="$(yq -r ".rows[] | select(.env == \"$E\") | .recovery_class" "$PLATFORM_REPO_DIR/register/${A}.yaml" | tr 'A-Z' 'a-z')"
    TAGS="$(gcloud resource-manager tags bindings list --parent="//cloudresourcemanager.googleapis.com/folders/${FID}" --effective --format=json | jq -c '[.[] | .namespacedTagValue | split("/") | {(.[-2]): .[-1]}] | add // {}')"
    echo "$E $TAGS" | tee -a "${R}-1.7a-folder-tags-v1.txt"
    SPEC="$PLATFORM_REPO_DIR/factory/runs/${A}-${E}.json"
    jq --arg a "$A" --arg e "$E" --arg id "$PID" --arg rc "$RC" --arg var "$VAR" --arg fv "$FV" --arg aic "$AIC" --arg rcl "$RCL" \
       --arg own "$GRP_DOER_OWNERS" --arg sec "$GRP_PLATFORM_SECURITY" --arg et "$ET" --argjson amt "$AMT" --argjson tags "$TAGS" '
      ("dev-p07-agent-" + $a + "-" + $e) as $run
      | .module="agent-project" | .run_id=$run | .calling_file_step="POV 07 PW-2.1"
      | .register_row=("register/" + $a + ".yaml") | .register_commit=$rc | .manifest=($a + "/agent-manifest.yaml")
      | .agent_id=$a | .env=$e | .register_tier="W"
      | .project_variable=$var | .project_id=$id | .create=true | .parent_folder_variable=$fv
      | .labels={"agent":$a,"owner":($a + "-owners"),"tier":"w","env":$e,"data_class":"evidence","ai_act_class":$aic,"recovery_class":$rcl,"cost_centre":"tbd","created_by":"bootstrap-hand","factory_run":$run}
      | .tags_effective=$tags
      | .services=["iam.googleapis.com","firestore.googleapis.com","bigquery.googleapis.com","run.googleapis.com","secretmanager.googleapis.com","aiplatform.googleapis.com","modelarmor.googleapis.com","iap.googleapis.com","cloudtasks.googleapis.com","logging.googleapis.com","monitoring.googleapis.com","admin.googleapis.com","observability.googleapis.com"]
      | .service_dependencies=[]
      | .log_routing={"default_bucket":"default-europe-west1","location":"europe-west1","retention_days":30,"trace_bucket":true}
      | .budget={"display_name":($id + "-budget"),"amount":$amt,"reason_if_not_tier_default":null}
      | .essential_contacts=[{"email":$own,"categories":["SECURITY","SUSPENSION","TECHNICAL","TECHNICAL_INCIDENTS"]},{"email":$sec,"categories":["SECURITY"]}]
      | .service_accounts=[($a + "-actions"),($a + "-agent"),($a + "-operators-caller"),($a + "-tasks")]
      | .project_bindings=([ "roles/datastore.user","roles/cloudtasks.enqueuer","roles/logging.logWriter","roles/monitoring.metricWriter" ]
          | map({"role":.,"member":("serviceAccount:" + $a + "-actions@" + $id + ".iam.gserviceaccount.com")}))
      | .allowed_human_members=[] | .notification_channels=[] | .trigger_sink=null
      | .project_floor={"applies":true,"tier":"W","pi_confidence":"HIGH","rai_min":"MEDIUM_AND_ABOVE","vertex_ai":true,"vertex_enforcement":$et,"floors_file":"model-armor/floors.json"}
      | .deny_entries=[] | .pab_bindings=[] | .project_org_policies=[] | .project_deny_policies=[]
      | .entitlements=[("ent-project-repair-" + $a),("ent-deploy-credential-holder-" + $a)] | .lien=true
      | .made_elsewhere=[{"item":"Firestore (default) with point-in-time recovery and backups","file":"POV 07","step":"PW-2.3"},
                        {"item":"the audit dataset, its tables and its append-only rights","file":"POV 07","step":"PW-2.4 to PW-2.6"},
                        {"item":"regional secrets, one reader each","file":"POV 07","step":"PW-2.7"},
                        {"item":"the action service, the approval surface and their run.invoker lists","file":"POV 07","step":"part 4"},
                        {"item":"gateways, Model Armor templates, the engine, Agent Identity and the registry entry","file":"POV 07","step":"PW-5.1, PW-5.2, PW-5.4, PW-5.4a"},
                        {"item":"Binary Authorization verifier grants","file":"setup/31","step":"setup/17 FM-3.3 (PV-D-12)"},
                        {"item":"the baseline owners email and paging channels of FM-2.13","file":"setup/31","step":"setup/17 FM-2.13 (PV-D-10)"},
                        {"item":"per-agent deny entries for the doer principals","file":"setup/31","step":"setup/17 FM-3.2"},
                        {"item":"a pab-agents binding","file":"setup/13","step":"setup/17 FM-2.16"}]
      | .pending=([ "floor.read","floor.enforced","floor.pi","floor.malicious_uri","floor.rai","floor.integration","floor.vertex_enforcement","floor.service_agent_role" ]
          | map({"check":.,"reason":"the project floor is written at PW-5.3, after the first checker run","owner":"platform owner","rerun_in":"POV 07 PW-5.3a"}))' \
      "$PLATFORM_REPO_DIR/factory/runs/_template.json" > "$SPEC" || return 1
    python3.12 -m json.tool "$SPEC" >/dev/null && echo "$E JSON-OK"
    diff <(jq -r 'keys[]' "$PLATFORM_REPO_DIR/factory/runs/_template.json") <(jq -r 'keys[]' "$SPEC") && echo "$E KEY-SET EQUALS TEMPLATE"
    if python3.12 "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" inputs "$SPEC" --report "${R}-1.7a-inputs-${E}-v1.json"; then echo "$E exit=0"; else echo "$E exit=$?"; fi
    jq -r --arg e "$E" '.results[] | select(.status != "PASS") | "\($e) \(.status) \(.check) \(.actual)"' "${R}-1.7a-inputs-${E}-v1.json"
  done
  git -C "$PLATFORM_REPO_DIR" add "factory/runs/${A}-prod.json" "factory/runs/${A}-nonprod.json"
  git -C "$PLATFORM_REPO_DIR" commit -m "factory: run specs for ${A} prod and nonprod before either project exists (setup 17 FM-2.1; POV 07 PW-1.7a)"
  git -C "$PLATFORM_REPO_DIR" push -u origin "fm-spec-${A}"
  gh pr create --repo "$PLATFORM_REPO_SLUG" --head "fm-spec-${A}" --title "PW-1.7a run specs ${A} prod and nonprod" --body "setup/17 FM-2.1 with FM-AGENT values; the POV's real state in made_elsewhere and pending. Approvers: the second person and one other reviewer, neither the author."
}
pw17a || echo "PW-1.7a STOPPED: nothing after the failing line ran"
```

  After the merge: `git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only && checkpoint PW-1.7a DONE "$SECOND_HUMAN_EMAIL" "repo:factory/runs/${A}-prod.json@$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%h -- "factory/runs/${A}-prod.json")" "two specs merged before either project"`.
- **VERIFY:** No `STOPPED` line; for each environment `JSON-OK` and `KEY-SET EQUALS TEMPLATE`; the tag lines read `agp-tier=w` and `agp-tisax-scope=in`, and `agp-env` matching the environment where 03 created that key. `inputs` prints `exit=1` for each, and its only non-`PASS` lines are `FAIL services.subset_of_folder_allowlist` naming services that Google's `gcp.restrictServiceUsage` does not govern, which the unchanged checker's allow-list rule cannot pass (04 PC-4.2d's `PENDING` line): at least `observability.googleapis.com`. **A governed service in that list is a stop**, repaired in 03 PF-5.3's `fld-agents-w` allow-list, never by dropping it from the spec. Every other check reads `PASS`, in particular `row.*`, `manifest.sha`, `names.project_id`, `project_id.form` (`agp-w-<agent_id>-prod` and `-nonprod`, 02 PD-3.2), `parent.folders_yaml`, `budget.tier_default` (300 and 150), every label's alphabet, `labels.factory_run` and `floor.declared`. The pull request is merged with two human approvals, the second person's among them, neither the platform owner's, before PW-2.1 runs.
- **ROLLBACK:** Close the pull request; nothing exists in Google Cloud yet.
- **EVIDENCE:** The two inputs reports, the folder tag reads and the merge commit as `${R}-1.7a-run-specs-v1`; `evidence_add PW-1.7a run-specs E-05 1.3.1 build-log:records/ "${R}-1.7a-inputs-prod-v1.json"`. E-05. TISAX 1.3.1, 5.2.1.

---

## 2. Projects and data plane

Full-set depth: [setup/31](../setup/31-wall-e-project-and-data-plane.md). What differs: built by hand under SD-01's bootstrap exception with the factory's names and labels (PV-D-01); no Access Approval (not a Tier W gate line); no `-super` service account.

### PW-2.1 Create `DOER_PROJECT` and `DOER_NONPROD_PROJECT`

- **WHO:** Platform owner requests the folder-admin grant; **the second person approves** in their own console (Security > Privileged Access Manager > Approve grants).
- **WHERE:** shell.
- **ACTION:** Compare `fld-agents-w`'s `gcp.restrictServiceUsage` allow-list with the services the doer needs (WD-2.1's `comm` pattern) before creating anything. Then, for prod and nonprod:

```bash
pw21_create() {
  need FLD_AGENTS_W_PROD FLD_AGENTS_W_NONPROD BILLING_ACCOUNT_ID ORG_ID CICD_PROJECT SECOND_HUMAN_EMAIL RESERVED_NAMES_RECORD || return 1
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-02 PV-03 || { echo "STOP: PV-02 and PV-03 must be signed before a permanent project id is spent"; return 1; }
  for E in prod nonprod; do git -C "$PLATFORM_REPO_DIR" log --oneline -1 origin/main -- "factory/runs/${A}-${E}.json" | grep -q . || { echo "STOP: PW-1.7a's ${E} run spec is not merged"; return 1; }; done
  PID="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES DOER_PROJECT)"; NID="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES DOER_NONPROD_PROJECT)"
  [ "$(reserved_names | wc -l)" -ge 4 ] || { echo "STOP: register/reserved/names.yaml unreadable or short (04 PC-1.3)"; return 1; }
  for X in "$PID" "$NID"; do reserved_names | grep -qxF "$X" && { echo "STOP: $X is reserved (PV-02)"; return 1; }; done
  checkpoint PW-2.1 START "$SECOND_HUMAN_EMAIL" - "irreversible project ids" || return 1
  confirm_manual PW-2.1 "Type the production project id exactly as the NAMES record prints it" || return 1
  [ "$(tail -1 "$BUILD_LOG_DIR/confirmations.tsv" | cut -f5)" = "$PID" ] || { echo "STOP: typed id differs from NAMES ($PID)"; return 1; }
  confirm_manual PW-2.1 "Type the nonprod project id exactly as the NAMES record prints it" || return 1
  [ "$(tail -1 "$BUILD_LOG_DIR/confirmations.tsv" | cut -f5)" = "$NID" ] || { echo "STOP: typed id differs from NAMES ($NID)"; return 1; }
  lbl() { jq -r '.labels | to_entries | map("\(.key)=\(.value)") | join(",")' "$PLATFORM_REPO_DIR/factory/runs/${A}-$1.json"; }
  gcloud projects create "$PID" --folder="$FLD_AGENTS_W_PROD" --no-enable-cloud-apis --labels="$(lbl prod)" || return 1
  gcloud projects create "$NID" --folder="$FLD_AGENTS_W_NONPROD" --no-enable-cloud-apis --labels="$(lbl nonprod)" || return 1
  for P in "$PID" "$NID"; do
    gcloud billing projects link "$P" --billing-account="$BILLING_ACCOUNT_ID"
    gcloud resource-manager tags bindings create --tag-value="${ORG_ID}/agp-tier/w" --parent="//cloudresourcemanager.googleapis.com/projects/$(gcloud projects describe "$P" --format='value(projectNumber)')"
    gcloud alpha resource-manager liens create --project="$P" --restrictions=resourcemanager.projects.delete --reason="agent project; removed only by revoke (05 section 7.2)"
  done
  for E in prod nonprod; do
    P="$PID"; [ "$E" = nonprod ] && P="$NID"
    gcloud services enable $(jq -r '.services | join(" ")' "$PLATFORM_REPO_DIR/factory/runs/${A}-${E}.json") --project="$P" || return 1
    gcloud services list --enabled --project="$P" --format="value(config.name)" | sort > "${R}-2.1-services-${E}-v1.txt"
    comm -13 <(jq -r '.services[]' "$PLATFORM_REPO_DIR/factory/runs/${A}-${E}.json" | sort) "${R}-2.1-services-${E}-v1.txt" > "${R}-2.1-extra-${E}-v1.txt"
  done
  penv_set DOER_PROJECT "$PID"; penv_set DOER_NONPROD_PROJECT "$NID"
  penv_set DOER_PROJECT_NUMBER "$(gcloud projects describe "$PID" --format='value(projectNumber)')"
  penv_set DOER_NONPROD_PROJECT_NUMBER "$(gcloud projects describe "$NID" --format='value(projectNumber)')"
  checkpoint PW-2.1 DONE "$SECOND_HUMAN_EMAIL" "${R}-2.1-projects-v1.txt"
}
pw21_create || echo "PW-2.1 STOPPED: nothing after the failing line ran; resume from checkpoints.tsv"
```

  The labels and the services are read from PW-1.7a's merged specs, and `--no-enable-cloud-apis` keeps `cloudapis.googleapis.com` from switching on services the specs do not name (as file 06 PE-1.2 does), and both projects get the same services, because the nonprod project carries the same manifest. Budgets (300 and 150, setup/17's tier table), regional log routing, the trace bucket and contacts are PW-2.1a's.
- **VERIFY:** No `STOPPED` line; `confirmations.tsv` holds two PW-2.1 lines whose typed ids equal `PID` and `NID`; `checkpoints.tsv` holds PW-2.1 `START` before and `DONE` after the creates, both naming the second person; `gcloud projects describe "$DOER_PROJECT" --format="value(parent.type,parent.id)"` prints `folder <FLD_AGENTS_W_PROD>`, and nonprod its folder; one delete lien each; the tag binding lists `agp-tier/w`; `gcloud projects get-iam-policy` holds no `user:`, `group:` or `domain:` member once the creator's Owner is removed at PW-2.2 (S018's check, WD-2.4).
- **ROLLBACK:** **IRREVERSIBLE: a project id can never be reused, even after deletion.** Confirm first: the typed id equals the NAMES record; `PID` is not in `register/reserved/names.yaml` (PW-0.1); the parent is the `-w-` folder and not `-p-sa-`. Gate: PV-02 and PV-03 signed. A wrong project is revoked (lien lifted under the repair grant, deletion scheduled), never re-created under the same id.
- **EVIDENCE:** Describe output, lien and tag reads as `${R}-2.1-projects-v1.txt`; `evidence_add PW-2.1 doer-projects E-05 1.3.1 ...`. TISAX 1.3.1, 4.2.1.

### PW-2.1a The module shape the specs state, on both projects: `_Default`, `_Trace`, budget, contacts

- **WHO:** Platform owner, still holding the creator's Owner on each project (removed in PW-2.2). The budgets: the platform owner while today is before `BOOTSTRAP_BILLING_EXPIRY`, otherwise the billing administrator. Two reviewers, the second person one of them, merge any dependency revision.
- **WHERE:** Shell; the git host for the revision.
- **ACTION:** File 06 PE-1.4a's block **unchanged**, run once per project: first with `DOER_PROJECT` in place of `EVE_PROJECT` and `factory/runs/<agent_id>-prod.json` in place of `eve-prod.json`, then with `DOER_NONPROD_PROJECT` and `-nonprod.json`; checkpoint id `PW-2.1a` for both, with the environment named in each line's note; branch `fm-spec-<agent_id>-dependencies`; and PW-2.1's `extra` records (`*-PW-2.1-extra-prod-v1.txt`, `*-PW-2.1-extra-nonprod-v1.txt`). It runs setup/17 FM-2.8 (`_Default` to `default-europe-west1`; `_Required` stays global), FM-2.9 (`_Trace` in `REGION` by setup/10 CP-1.8's REST call, the token on standard input, never printed or stored), FM-2.10 (the budget the spec names, 300 or 150, with four thresholds) and FM-2.11 (the two Essential Contacts), each value read from the project's own spec. File 06 PE-1.4a cites Google's reference for every flag and call.
- **VERIFY:** File 06 PE-1.4a's VERIFY, for each project: `_Default` ends `/locations/europe-west1/buckets/default-europe-west1` and `_Required` ends `/locations/global/buckets/_Required`; the routing test reads its entry back; `_Trace` is listed; one budget naming only that project, of 300 for prod and 150 for nonprod, with four rules; exactly the spec's two contacts; any dependency revision merged with two approvals, the second person's among them.
- **ROLLBACK:** As file 06 PE-1.4a. **`_Trace` is IRREVERSIBLE** on each project: no delete is documented and its location cannot be changed. Confirm first: `REGION` is `europe-west1` and the URL names the intended project.
- **EVIDENCE:** `${R}-2.1a-module-shape-v1.txt`, both projects; `evidence_add PW-2.1a module-shape E-05 5.2.4 build-log:records/ "${R}-2.1a-module-shape-v1.txt"`. E-05, E-06. TISAX 5.2.4, 7.1, 1.3.3, 1.6.1. Then `checkpoint PW-2.1a DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-2.1a-module-shape-v1.txt")"`.

### PW-2.2 Service identities, per-project entitlements, and the creator's Owner removed, on both projects

- **WHO:** Platform owner under the PW-2.1 grant; the second person is the approver written into every entitlement, and approves the proof grant on each project from their own session.
- **WHERE:** shell.
- **ACTION:** In **each** project, prod and nonprod, since the nonprod project carries the same manifest: create `${A}-actions@`, `${A}-agent@`, `${A}-operators-caller@`, `${A}-tasks@`; bind only the credential holder's roles of [setup/31](../setup/31-wall-e-project-and-data-plane.md) WD-2.5 to `${A}-actions@` (`roles/datastore.user`, `roles/cloudtasks.enqueuer`, `roles/logging.logWriter`, `roles/monitoring.metricWriter`) and nothing to the other three; instantiate `ent-project-repair-${A}` and `ent-deploy-credential-holder-${A}` from [setup/12](../setup/12-privileged-access-catalogue.md)'s templates exactly as [setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md) FM-2.17 does, one pair of files per project (`pam/entitlements/<name>.json` for prod, `pam/entitlements/<name>-nonprod.json` for nonprod, merged by review first). Then, as file 06 PE-1.5 does, **prove one repair grant on each project before its creator's Owner goes**, so a mistake in an entitlement cannot lock the project out.

```bash
need DOER_PROJECT DOER_NONPROD_PROJECT A CICD_PROJECT SA_1_ADMIN SECOND_HUMAN_EMAIL PLATFORM_REPO_DIR
checkpoint PW-2.2 START "$SECOND_HUMAN_EMAIL" - "identities, entitlements, proof grants, Owner removed, both projects"
pw22() {
  for E in prod nonprod; do
    P="$DOER_PROJECT"; SUF=""; [ "$E" = nonprod ] && { P="$DOER_NONPROD_PROJECT"; SUF="-nonprod"; }
    for S in actions agent operators-caller tasks; do gcloud iam service-accounts create "${A}-${S}" --display-name="${A} ${S}" --project="$P" || return 1; done
    for ROLE in roles/datastore.user roles/cloudtasks.enqueuer roles/logging.logWriter roles/monitoring.metricWriter; do
      gcloud projects add-iam-policy-binding "$P" --member="serviceAccount:${A}-actions@${P}.iam.gserviceaccount.com" --role="$ROLE" --condition=None >/dev/null || return 1
    done
    gcloud pam entitlements create "ent-project-repair-${A}" --entitlement-file="$PLATFORM_REPO_DIR/pam/entitlements/ent-project-repair-${A}${SUF}.json" --location=global --project="$P" --billing-project="$CICD_PROJECT" || return 1
    gcloud pam entitlements create "ent-deploy-credential-holder-${A}" --entitlement-file="$PLATFORM_REPO_DIR/pam/entitlements/ent-deploy-credential-holder-${A}${SUF}.json" --location=global --project="$P" --billing-project="$CICD_PROJECT" || return 1
    gcloud pam grants create --entitlement="ent-project-repair-${A}" --requested-duration=900s --justification="POV 07 PW-2.2: one proof grant before the creator's Owner goes on ${P}" --location=global --project="$P" --billing-project="$CICD_PROJECT" || return 1
    confirm_manual PW-2.2 "Second person: approve the proof grant on ${P} in your own console, then type that project id" || return 1
    G="$(gcloud pam grants search --entitlement="ent-project-repair-${A}" --location=global --project="$P" --billing-project="$CICD_PROJECT" --caller-relationship=had-created --filter='state=ACTIVE' --format='value(name)' | head -1)"
    [ -n "$G" ] || { echo "STOP: no ACTIVE proof grant on ${P}; the creator's Owner stays"; return 1; }
    gcloud projects get-iam-policy "$P" --format=json | jq -r '.bindings[] | select(.condition != null) | .role' | sort | tee "${R}-2.2-proof-bindings-${E}-v1.txt"
    gcloud pam grants revoke "$G" --reason="POV 07 PW-2.2 proof complete" --location=global --project="$P" --billing-project="$CICD_PROJECT" || return 1
    gcloud projects remove-iam-policy-binding "$P" --member="user:${SA_1_ADMIN}" --role=roles/owner >/dev/null || return 1
    gcloud projects get-iam-policy "$P" --flatten="bindings[].members" --format="table(bindings.role,bindings.members)" | tee "${R}-2.2-iam-${E}-v1.txt"
  done
}
pw22 && checkpoint PW-2.2 DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-2.2-iam-nonprod-v1.txt")" || echo "PW-2.2 STOPPED: resume from the failing project; a project whose proof grant did not run keeps its creator's Owner"
```

  > **IRREVERSIBLE as a standing path**, per project, once the Owner binding is removed: afterwards only an approved `ent-project-repair-${A}` grant, or the organisation-level break-glass path of file 03, reaches the project. Confirm first: the proof grant on that project was `ACTIVE` and approved by the second person, and `${R}-2.2-proof-bindings-<env>-v1.txt` lists the entitlement's roles.
- **VERIFY:** No `STOPPED` line. For each project: four accounts and no user-managed key on any (`gcloud iam service-accounts keys list --managed-by=user`); `${A}-actions@` holds exactly the four roles and `${A}-agent@`, `${A}-operators-caller@` and `${A}-tasks@` hold no project role; both entitlements `AVAILABLE` with an approver list that does not contain person 1; the proof grant was `ACTIVE` and is now revoked; the IAM table has no human member.
- **ROLLBACK:** Before the Owner removal: delete an entitlement before its first grant; disable and delete a service account before anything binds it. After it: **IRREVERSIBLE** as above; repairs go through `ent-project-repair-${A}`.
- **EVIDENCE:** Identity tables, entitlement lists, proof bindings and IAM reads for both projects as `${R}-2.2-identities-v1.txt`. E-08. TISAX 4.1.1, 4.1.3.

### PW-2.2a Run the zero-diff checker against both projects

- **WHO:** Platform owner runs; **the second person reads both reports** and initials the build-log line; the platform owner does not verify their own projects.
- **WHERE:** Shell. No `ent-project-repair-${A}` grant may be active on either project: an active grant is a conditional `user:` binding, which the checker counts as a human member (setup/17 FM-2.19's note).
- **ACTION:** setup/17 FM-2.21 against each merged spec, first without and then with `--accept-pending`, then the deviation row of FM-2.22 in the POV's grammar. The project floor is not written until PW-5.3, so the eight `floor.*` lines are expected as `PENDING`, and nothing else.

```bash
need DOER_PROJECT DOER_NONPROD_PROJECT A CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR SECOND_HUMAN_EMAIL
checkpoint PW-2.2a START "$SECOND_HUMAN_EMAIL" - "setup/17 FM-2.21 on the doer's two projects"
grep -qE 'PW-2\.2[[:space:]]+DONE' "$BUILD_LOG_DIR/checkpoints.tsv" && echo "PW-2.2 done" || echo "STOP: PW-2.2 has not run"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
for E in prod nonprod; do
  P="$DOER_PROJECT"; [ "$E" = nonprod ] && P="$DOER_NONPROD_PROJECT"
  gcloud pam grants search --entitlement="ent-project-repair-${A}" --location=global --project="$P" --billing-project="$CICD_PROJECT" --caller-relationship=had-created --filter='state=ACTIVE' --format='value(name)' | grep -q . && echo "STOP: an active repair grant on $P; revoke it first" || echo "$E no active repair grant"
  SPEC="$PLATFORM_REPO_DIR/factory/runs/${A}-${E}.json"
  if python3.12 "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" live "$SPEC" --report "${R}-2.2a-live-${E}-v1.json"; then echo "$E exit=0"; else echo "$E exit=$?"; fi
  if python3.12 "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" live "$SPEC" --accept-pending --report "${R}-2.2a-live-accept-pending-${E}-v1.json"; then echo "$E exit=0"; else echo "$E exit=$?"; fi
  jq -r --arg e "$E" '.results[] | select(.status != "PASS") | "\($e) \(.status) \(.check) \(.pending.rerun_in // "")"' "${R}-2.2a-live-accept-pending-${E}-v1.json"
done
printf '%s\tPW-2.2a\tfm-zero-diff live on the doer projects: eight floor checks PENDING until PW-5.3\tre-run as PW-5.3a without --accept-pending\tPENDING\tplatform owner\n' "$(date -u +%F)" >> "$BUILD_LOG_DIR/rerun-index.tsv"
```

  Then append `BD-P07-2` to `DEVIATION_REGISTER` in setup/17 FM-2.22's `MOD` form and 01 PP-3.1's columns: "agent-project for `DOER_PROJECT` and `DOER_NONPROD_PROJECT` by hand to `factory/runs/<agent_id>-prod.json` and `-nonprod.json` (PV-D-01)", the folders and projects, `register/<agent_id>.yaml` at each spec's `register_commit`, the specs' merge commit, both checker reports, the date PW-2.2 removed the creators' Owner, the PAM grants approved by the second person, and the unwind "setup/17 FM-11: `terraform import` plans no change once the specs' `made_elsewhere` items are made by setup/31 and the specs are revised", status `open`.
- **VERIFY:** `PW-2.2 done`; `no active repair grant` for both. For each project the first run prints `DIFF` and `exit=1` and its only non-`PASS` lines are the eight `PENDING floor.*` lines; the second prints `ZERO-DIFF` and `exit=0` with exactly those eight lines, re-run `POV 07 PW-5.3a`. In particular `project.labels`, `tags.none_direct`, `services.exact`, `logging.default_route`, `trace.bucket`, `budget`, `essential_contacts`, `service_accounts.exact`, `iam.no_human_or_basic_role`, `iam.no_unexpected_service_account`, `iam.spec_bindings_present`, `lien` and `entitlements` read `PASS` on both. A `FAIL` is repaired under an `ent-project-repair-${A}` grant the second person approves, and the checker re-run; never by writing the live value into the spec without the step that made it, or by editing the checker. The second person initials both reports; `BD-P07-2` is the last row of `DEVIATION_REGISTER`; then `checkpoint PW-2.2a DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-2.2a-live-accept-pending-prod-v1.json")" "ZERO-DIFF on both with eight floor PENDING lines"`.
- **ROLLBACK:** Read only; the deviation register is append-only.
- **EVIDENCE:** The four reports as `${R}-2.2a-live-v1`; `evidence_add PW-2.2a zero-diff E-05 5.2.4 build-log:records/ "${R}-2.2a-live-accept-pending-prod-v1.json"`. E-05. TISAX 5.2.4, 1.4.1.

### PW-2.3 Firestore `(default)` with point-in-time recovery and a daily backup

- **WHO:** Platform owner inside a repair grant the second person approves.
- **WHERE:** shell.
- **ACTION:** Firestore holds halt flags, overrides, nonces and drill dates; everything fails closed, so it lives in the residency region.

```bash
gcloud firestore databases create --database='(default)' --location="$REGION" --type=firestore-native --delete-protection --enable-pitr --project="$DOER_PROJECT"
gcloud firestore backups schedules create --database='(default)' --recurrence=daily --retention=14d --project="$DOER_PROJECT"
gcloud firestore databases describe --database='(default)' --project="$DOER_PROJECT" --format="yaml(locationId,type,deleteProtectionState,pointInTimeRecoveryEnablement)"
```

  The same three commands for `DOER_NONPROD_PROJECT`. `Assumption:` 14 days' backup retention, recorded in PV-01's values.
- **VERIFY:** `locationId: europe-west1`, `FIRESTORE_NATIVE`, `DELETE_PROTECTION_ENABLED`, PITR enabled; `gcloud firestore backups schedules list --database='(default)' --project="$DOER_PROJECT"` lists one daily schedule.
- **ROLLBACK:** **IRREVERSIBLE as a location.** Confirm first that `REGION` is `europe-west1` and no default project is set. Before PB-04 deploys, `databases update --no-delete-protection` then `databases delete` (WD-4.3's rollback).
- **EVIDENCE:** Describe YAML as `${R}-2.3-firestore-v1.yaml`. E-05. TISAX 7.1.2, 5.2.4.

### PW-2.4 Create `<agent_id>_audit`

- **WHO:** Platform owner inside the grant; the second person present.
- **WHERE:** shell.
- **ACTION:**

```bash
pw24_create() {
  need DOER_PROJECT DOER_NONPROD_PROJECT BQ_LOCATION SECOND_HUMAN_EMAIL RESERVED_NAMES_RECORD || return 1
  "$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-03 || return 1
  [ "$BQ_LOCATION" = EU ] || { echo "STOP: BQ_LOCATION is $BQ_LOCATION, not EU"; return 1; }
  [ "$(reserved_names | wc -l)" -ge 4 ] || { echo "STOP: register/reserved/names.yaml unreadable or short (04 PC-1.3)"; return 1; }
  reserved_names | grep -qxF "${AU}_audit" && { echo "STOP: ${AU}_audit is reserved"; return 1; }
  [ "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES DOER_AUDIT_DS)" = "${AU}_audit" ] || { echo "STOP: NAMES record disagrees with ${AU}_audit"; return 1; }
  for P in "$DOER_PROJECT" "$DOER_NONPROD_PROJECT"; do
    bq --project_id="$P" show "${P}:${AU}_audit" >/dev/null 2>&1 && { echo "EXISTS in $P: resume rule, do not re-create"; return 1; }
  done
  checkpoint PW-2.4 START "$SECOND_HUMAN_EMAIL" - "irreversible dataset name and location" || return 1
  confirm_manual PW-2.4 "Type the audit dataset name as the NAMES record prints it" || return 1
  [ "$(tail -1 "$BUILD_LOG_DIR/confirmations.tsv" | cut -f5)" = "${AU}_audit" ] || { echo "STOP: typed name differs from ${AU}_audit"; return 1; }
  for P in "$DOER_PROJECT" "$DOER_NONPROD_PROJECT"; do
    bq --project_id="$P" --location="$BQ_LOCATION" mk --dataset --label=agent:"$A" --label=data_class:evidence --description="${A} audit trail; insert-only; keyed on agent_id (05 section 9.4)" "${P}:${AU}_audit" || return 1
  done
  penv_set DOER_AUDIT_DS "${AU}_audit"
  checkpoint PW-2.4 DONE "$SECOND_HUMAN_EMAIL" "${R}-2.4-dataset-v1.json"
}
pw24_create || echo "PW-2.4 STOPPED: nothing after the failing line ran"
```

- **VERIFY:** No `STOPPED` line; the PW-2.4 line in `confirmations.tsv` equals `${AU}_audit`; `checkpoints.tsv` holds PW-2.4 `START` and `DONE`; `bq show --format=prettyjson` prints `EU`, no default table expiry, `data_class: evidence`, in both projects.
- **ROLLBACK:** **IRREVERSIBLE as a name and a location.** Confirm first: the name equals NAMES and is not in `register/reserved/names.yaml`, `BQ_LOCATION` is `EU`. Gate: PV-03. Removal only through the audit-destruction guard of [setup/31](../setup/31-wall-e-project-and-data-plane.md) WD-10.1 with a dated decision record; no literal `bq rm` is written here.
- **EVIDENCE:** Both `show` outputs as `${R}-2.4-dataset-v1.json`; `evidence_add PW-2.4 audit-dataset E-06 1.3.1 ...`. TISAX 1.3.1, 7.1.2.

### PW-2.5 The nine audit tables - **BLOCKED on PB-01**

- **WHO:** Platform owner; person 3 reviews the schema commit.
- **WHERE:** shell, clean checkout at `AUDIT_DDL_COMMIT`.
- **ACTION:** **BLOCKED.** Needs: PB-01, the nine schema files `actions`, `runs`, `plans`, `approvals`, `verifications`, `config_versions`, `ladder_events`, `grades`, `generic_requests` on `audit.schema` ([05-registry](../05-registry-and-autonomy-contract.md) §9.4), **every `p_` column present from the first row** including `ws_insert_ids`, `tainted`, `halt_epoch`, `fp_*` and `approver_surrogates`, committed by [04](04-the-contract-register-agent-ids-and-schemas.md) at `AUDIT_DDL_COMMIT`. `Assumption:` 2 to 3 engineer-days. Once present, and only after `need AUDIT_DDL_COMMIT` is silent (this is the one step that needs it), run [setup/31](../setup/31-wall-e-project-and-data-plane.md) WD-4.5's `wd45_create_tables` function with its project and dataset variables replaced by `DOER_PROJECT` and `DOER_AUDIT_DS`, the list file at `<agent_id>/AUDIT_TABLES` (04 PC-2.4), partitioned by day on `ts` with expiry `EVIDENCE_RETENTION_DAYS`, `actions` clustered on `operation`; once for each project. Gate waiting: PW-4.3 (the first write), [06](06-eve-over-the-human-super-admins.md) §11, [08](08-mo-and-the-value-report.md). Until then `checkpoint PW-2.5 BLOCKED - - "PB-01"`.
- **VERIFY:** `bq ls` counts 9 tables in each dataset; `comm -3` against the list prints nothing; `actions` shows `DAY` on `ts` and clustering on `operation`.
- **ROLLBACK:** Only through the guard, one table per call, second person typing the confirmation.
- **EVIDENCE:** Listing and partition reads as `${R}-2.5-audit-tables-v1`. E-06. TISAX 1.3.1, 5.2.6.

### PW-2.6 Append-only rights, one writer, and the readers

- **WHO:** Platform owner inside the grant; the second person reads the probe.
- **WHERE:** shell.
- **ACTION:** BigQuery has no insert-only permission (SD-43). Create the custom role `<AU>AuditWriter` with exactly `bigquery.tables.updateData`, `bigquery.tables.get`, `bigquery.datasets.get` (WD-7.1's create-or-undelete guard), then set the dataset access array to **one** writer entry for `${A}-actions@` plus dataset `READER` entries, with WD-7.2's access function, renamed `doer_audit_access` and re-pointed at the doer's variables:

```bash
READERS=()
for M in "$SA_EVE_V0" "mo-metrics@${MO_PROJECT:-PENDING}.iam.gserviceaccount.com"; do
  exists_or_pending --pending "serviceAccount:${M}" PW-2.6 "re-run the access function with ${M} as READER on ${DOER_AUDIT_DS}" && READERS+=("$M")
done
doer_audit_access "${READERS[@]}"
```

  Then WD-7.3's `testIamPermissions` probe, **run now while no secret holds a version** (PW-2.7 creates them empty; PW-3.3 fills one), impersonating `${A}-actions@` and `${A}-agent@`, and the impersonation removed in the same block.
- **VERIFY:** Access array: one custom-role entry and the readers, no `OWNER`, no `projectOwners`, no view entry. Probe: `${A}-actions@` echoes `updateData` and `get` only; `${A}-agent@` echoes `{}`; no `serviceAccountTokenCreator` remains. `mo-metrics@` is `PENDING` until [08](08-mo-and-the-value-report.md) and appears in `rerun-index.tsv`.
- **ROLLBACK:** Re-apply the recorded `before.json` array. Do not delete the custom role (the id is blocked for up to 37 days, WD-7.1).
- **EVIDENCE:** Role JSON, access read-back and probe as `${R}-2.6-append-only-v1`; `evidence_add PW-2.6 audit-append-only E-06 4.2.1 ...`. TISAX 4.2.1, 5.2.6.

### PW-2.7 Regional secrets, created empty, one reader each

- **WHO:** Platform owner inside the grant.
- **WHERE:** shell.
- **ACTION:**

```bash
for S in "${A}-oauth-client" "${A}-refresh-token" "${A}-confirm-hmac"; do
  gcloud secrets create "$S" --location="$REGION" --project="$DOER_PROJECT" --labels="agent=${A},env=prod"
  gcloud secrets add-iam-policy-binding "$S" --location="$REGION" --project="$DOER_PROJECT" --member="serviceAccount:${A}-actions@${DOER_PROJECT}.iam.gserviceaccount.com" --role=roles/secretmanager.secretAccessor
done
penv_set DOER_SECRET_NAMES "${A}-oauth-client,${A}-refresh-token,${A}-confirm-hmac"
penv_set DOER_REFRESH_TOKEN_SECRET_NAME "${A}-refresh-token"
gcloud secrets list --project="$DOER_PROJECT" --format="value(name)"
```

  Nonprod gets **no** secret with a production value: [02](../02-landing-zone-and-tiers.md) §2 forbids a production credential in nonprod, and with no sandbox tenant (PV-D-04) the nonprod service runs credential-less and fails closed on any Workspace call.
- **VERIFY:** The regional listing prints three names and the global listing (the last command) prints nothing; each secret's policy names only `${A}-actions@`; `${A}-agent@` appears on none (WD-6.2's cross-read loop); no version exists on any.
- **ROLLBACK:** `gcloud secrets delete <name> --location="$REGION" --project="$DOER_PROJECT"` while no version exists.
- **EVIDENCE:** Listings and policies as `${R}-2.7-secrets-v1.txt`. E-08. TISAX 4.2.1, 5.1.

### PW-2.8 The restore drill - `DOER_RESTORE_DRILL_RECORD`

- **WHO:** Platform owner performs; **person 3 verifies** the restored data, not person 1.
- **WHERE:** shell, `DOER_NONPROD_PROJECT` first, then `DOER_PROJECT` once the service has written control documents.
- **ACTION:** After at least one scheduled backup exists:

```bash
B="$(gcloud firestore backups list --location="$REGION" --project="$DOER_PROJECT" --format='value(name)' --limit=1)"
T0="$(date -u +%s)"
gcloud firestore databases restore --source-backup="$B" --destination-database="restore-drill-$(date -u +%Y%m%d)" --project="$DOER_PROJECT"
echo "restore seconds: $(( $(date -u +%s) - T0 ))"
```

  Person 3 compares the halt, override and drill documents in the restored database with the source at the backup time, then the restored database is deleted. Also snapshot one audit table to prove the evidence path (`bq cp` of a partition into a scratch table in the same dataset is **not** used; a table snapshot is taken into `PLATFORM_EVIDENCE_BUCKET` by export).
- **VERIFY:** The restored database exists, its control documents match, the time is recorded; person 3 signs.
- **ROLLBACK:** Delete the `restore-drill-*` database (it has no delete protection).
- **EVIDENCE:** `penv_set DOER_RESTORE_DRILL_RECORD "<record path>"`; `evidence_add PW-2.8 restore-drill E-08 5.2.4 ...`. TISAX 5.2.4. Freshness 180 days ([setup/42](../setup/42-gates-drills-and-evidence.md) GD-2.1).

---

## 3. The consent sitting

Full-set depth: [setup/32](../setup/32-wall-e-consents.md). What differs: one client, not two, because the POV has no band-B credential; the attestations go to `PLATFORM_EVIDENCE_BUCKET`, not a witness (PV-D-03).

**The rule of the room, read aloud at the start:** exactly two people, person 1 and person 2; no screen share, no recording, no terminal logging, no `tee`; no service identity is the second person; both keys leave the safe on one signed line and neither person holds both.

### PW-3.1 Refuse to open without PB-05, the scope file, and a clean workstation

- **WHO:** Platform owner; the second person confirms the commit hash on their own screen.
- **WHERE:** shell.
- **ACTION:** Run [setup/32](../setup/32-wall-e-consents.md) WC-0.1 to WC-0.4 with the doer's variables (the repair grant approved by person 2; no cached operator token; no ADC file; one `gcloud auth` account). Then:

```bash
git -C "$PLATFORM_REPO_DIR" fetch -q origin && git -C "$PLATFORM_REPO_DIR" checkout -q origin/main
"$PLATFORM_REPO_DIR/${A}/bin/consent" --help 2>&1 | grep -E -- '--scopes-file|--scopes-sha256|--expect-account|--rotate|--no-browser|--verify' | sort
shasum -a 256 "$PLATFORM_REPO_DIR/${A}/config/scopes.txt"
"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 DOER_SCOPES_SHA256
```

- **VERIFY:** Six flags print. **If any is missing, the sitting does not open: BLOCKED on PB-05** (the consent bootstrap with `--scopes-file` and a comparison of the scopes actually granted; `Assumption:` 2 to 4 engineer-days); revoke the grant, `sitting_end`, keys stay in the safe. The scope file's hash equals the PV-01 value; every scope in it appears in the full set's narrow list (`config/scopes-narrow.txt`, [setup/32](../setup/32-wall-e-consents.md) WC-1.1) and none is `cloud-platform`.
- **ROLLBACK:** Read only; the grant is revoked with WC-0.3's rollback line.
- **EVIDENCE:** `${R}-3.1-refusals-v1.txt`. E-05. TISAX 5.2, 4.1.3.

### PW-3.2 The OAuth client: Internal, In production, one client

- **WHO:** Platform owner; the second person watches the dialog.
- **WHERE:** Console > Google Auth Platform > Branding, Audience, Clients, project `DOER_PROJECT`.
- **ACTION:** [setup/32](../setup/32-wall-e-consents.md) WC-3.1 to WC-3.4 once: the time-boxed conditioned `roles/oauthconfig.editor` binding; Audience **Internal**, **In production**; one **Desktop app** client `<agent_id>-<date>`. **Before the dialog opens**, prove the browser's download directory is outside every synced folder (iCloud Drive, Desktop and Documents sync, Google Drive, OneDrive), exactly as [01](01-conventions-and-variables.md) PP-1.2 proves it for the repositories, and that no backup tool is running on it for the sitting. Preferred path, which writes nothing to disk: copy the client JSON (or the id and secret) from the dialog and paste it on stdin:

```bash
gcloud secrets versions add "${A}-oauth-client" --data-file=- --location="$REGION" --project="$DOER_PROJECT"   # paste, then Ctrl-D; nothing echoed, no tee, no file
pbcopy </dev/null    # clear the clipboard
```

  Only if the dialog offers no copyable JSON: **Download JSON**, pipe the file into the same command, `rm -P` it. `rm -P` does not overwrite on APFS SSDs ([02](02-decisions-people-and-the-retrospective-baseline.md) unverified section), so the ciphertext may persist in free blocks until reused: the second person records that residual persistence as accepted, by name, in the step record, or the sitting takes the copy path.
- **VERIFY:** The Clients page lists one client; the download directory check printed no synced path; `Downloads clean` (no `client_secret*.json` anywhere under the home directory, `find ~ -name 'client_secret*' 2>/dev/null` prints nothing); the clipboard is empty; `${A}-oauth-client` has one version; its client id is added to PW-1.6's list and searched for in the DWD page by both people.
- **ROLLBACK:** **IRREVERSIBLE as a secret: the client secret is shown once.** Confirm first that WC-3.2's download rule was read aloud. A missed download means delete this client and create a new, newer-named one.
- **EVIDENCE:** Clients page screenshot (id visible, secret not), the download-directory check, the path taken (copy or download) and, on the download path, the second person's acceptance of residual persistence, as `${R}-3.2-client-v1`. E-05. TISAX 5.2.

### PW-3.3 The consent - **BLOCKED on PB-05**

- **WHO:** Platform owner types, with key A; the second person reads the printed scope list against the file before they confirm, with key B in hand.
- **WHERE:** the clean robot profile; shell.
- **ACTION:** Refuse a second live token first (WC-4.1). Sign in as `DOER_ROBOT` with the vault password and key A (WC-4.2). Then:

```bash
"$PLATFORM_REPO_DIR/${A}/bin/consent" --client-secret="${A}-oauth-client" --target-secret="$DOER_REFRESH_TOKEN_SECRET_NAME" \
  --scopes-file="$PLATFORM_REPO_DIR/${A}/config/scopes.txt" --scopes-sha256="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 DOER_SCOPES_SHA256)" \
  --expect-account="$DOER_ROBOT" --location="$REGION" --project="$DOER_PROJECT" --no-browser
```

  Copy the printed URL **by hand** into the clean profile; never let anything open a browser (it would take a signed-in admin profile). Add the confirmation HMAC piped in, never printed (WC-5.5). Sign the robot out for good; both keys back in the safe on one line.

```bash
penv_set DOER_TOKEN_VERSION "<the version number the command printed>"
gcloud secrets versions list "$DOER_REFRESH_TOKEN_SECRET_NAME" --location="$REGION" --project="$DOER_PROJECT" --format='value(name,state)'
```

- **VERIFY:** Exit 0; one version number printed, no token, no code, no secret; exactly one `ENABLED` version equal to `DOER_TOKEN_VERSION`; both people sign WC-4.5's five attestations after the event.
- **ROLLBACK:** **IRREVERSIBLE as a scope set:** widening later is a new consent, which is a robot sign-in. Undo is WC-8's order: announce, revoke the grant from an admin account (Directory > Users > the robot > Security > Connected applications), destroy the version, delete the client. Gate: PV-01's scope hash and PW-3.1 `DONE`.
- **EVIDENCE:** Command line, exit code, version number, signed attestations; `penv_set DOER_CONSENT_SITTING_RECORD "<record path>"`; `evidence_add PW-3.3 consent-sitting E-08 5.1 ...`. TISAX 5.1, 5.2, 4.1.

### PW-3.4 The morning after: granted scopes, one login, no delegation

- **WHO:** **The second person alone**, as `sa-2-admin@`, on their own workstation; person 3 confirms the login alert.
- **WHERE:** Admin console Menu > Reporting > Audit and investigation > OAuth log events, then Login log events; the DWD page.
- **ACTION:** OAuth log events lag "Up to a few hours" (Google's retention and lag page, row "OAuth", read 2026-09-16; the page's separate "Token" row says "A couple of hours"), so this runs next morning. Filter `Authorize` on the client id over the sitting's window; compare the `scope` parameter scope by scope with the committed file. Read the login events: exactly one robot login at PW-3.3's time (plus PW-1.4's). Repeat PW-1.6 with the client id.
- **VERIFY:** One `Authorize` event, actor `DOER_ROBOT`, scope set equal to the file; one login row per sign-in, each matching an alert person 3 received; the client id absent from the DWD list. A mismatch is §8 of [setup/32](../setup/32-wall-e-consents.md), never a widening.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Exported rows and the diff as `${R}-3.4-scopes-verified-v1`, signed by person 2. E-06. TISAX 5.2, 4.1.

---

## 4. The action service and the ladder

Full-set depth: [setup/33](../setup/33-wall-e-action-services-and-approval-surfaces.md). What differs: one service `<agent_id>-actions` that serves band A and holds the band-B lane at L0 (no `-super` service, because no broad credential exists); no Binary Authorization (PV-D-12); no deployed validator (PV-D-13).

### PW-4.1 The code commit - **BLOCKED on PB-04**

- **WHO:** The engineer writes; person 3 reviews; person 1 records.
- **WHERE:** `DOER_REPO_REMOTE`, `<agent_id>/`, under CODEOWNERS requiring person 3.
- **ACTION:** **BLOCKED.** PB-04 is the action service and the agent code: the ladder module compiled from the validated manifest; the write-ahead insert-only audit writer with `p:audit_unavailable` as a denial reason; the approval endpoint with a live group-membership check, a single-use nonce and a four-business-hour TTL ([05-registry](../05-registry-and-autonomy-contract.md) §9.5); the T0 chat trigger; **six catalogued operations, each with an exact inverse**; the band-B lane that denies; K0 `POST /v1/control/halt`, K1 `/v1/control/demote`, K4 `/v1/control/revoke-credential`; **a halt clear (`mode: clear`) and an override lift accepted only through the approval surface with two distinct human surrogates, requester and approver, both live members of the operators group; the control endpoint refuses `mode: clear` from `${A}-operators-caller@` (or any service identity) without a separate human approval id (`p:clear_needs_two_humans`)**, because clearing a halt raises autonomy and no service identity is the second person (SD-48); the engine's ADK agent holding no credential; and the negative-test suite named in PW-4.6 to PW-4.9. `Assumption:` 18 to 28 engineer-days. **No manual path replaces it.** `Assumption:` the six operations are three reversible pairs on resources the robot itself owns or manages (for example membership of pilot groups the robot manages), fixed in PV-01's catalogue values; a Workspace admin write is impossible here because the robot holds no role.

```bash
git -C "$PLATFORM_REPO_DIR" fetch -q origin
[ "$(git -C "$PLATFORM_REPO_DIR" remote get-url origin)" = "$DOER_REPO_REMOTE" ] || { echo "STOP: PLATFORM_REPO_DIR is not a clone of DOER_REPO_REMOTE"; false; } && \
penv_set DOER_CODE_COMMIT "$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%H origin/main -- "${A}")"
```

- **VERIFY:** The commit exists, is on `DOER_REPO_REMOTE`, touches `<agent_id>/`, carries person 3's approval, and CI's negative suite passed on it. Until then `checkpoint PW-4.1 BLOCKED - - "PB-04"`.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** The commit and approval as `${R}-4.1-code-commit-v1`. E-05. TISAX 5.2, 5.3.

### PW-4.2 The allowlist, the hard-denied list and ladder v1, committed and hashed

- **WHO:** Platform owner writes; person 3 and the second person review; person 3 and person 1 sign the manual parse (PV-D-13).
- **WHERE:** `PLATFORM_REPO_DIR` (the clone of `DOER_REPO_REMOTE`): `<agent_id>/config/`, `ladder/<agent_id>/`; the allowlist in `BUILD_LOG_DIR`.
- **ACTION:** Render the per-endpoint caller allowlist (WS-2.2's renderer, generated, never typed): `EXEC` = the agent principal (PW-5.4), `TASKS` = `${A}-tasks@`, `APPROVE` = the approval surface's identity, `CONTROL` = `${A}-operators-caller@` and `eve-verifier@` when it exists, `HALT` = `k7`'s and the drift identity. Commit the hard-denied list (every protected principal, every admin-role operation, every tenant setting). Write `ladder.yaml` on `ladder.schema` (`LADDER_SCHEMA_COMMIT`): every catalogued (family, T0) cell at **L1**; `defaults.ou_allowlist: [PILOT_OU]` (nonprod: `[NONPROD_OU]`); the two `code: true` rows `SUPER` and `WRITE_GENERIC` present at L0 everywhere; no cell for trigger `agent` above L0.

```bash
D="$PLATFORM_REPO_DIR/${A}"
penv_set DOER_ALLOWLIST_FILE "$BUILD_LOG_DIR/allowlists/${A}-actions.env"
penv_set DOER_HARD_DENIED_SHA "$(shasum -a 256 "$D/config/hard_denied.yaml" | cut -d' ' -f1)"
penv_set LADDER_FILE "ladder/${A}/ladder.yaml"
penv_set LADDER_SHA "$(shasum -a 256 "$PLATFORM_REPO_DIR/ladder/${A}/ladder.yaml" | cut -d' ' -f1)"
grep -E '^/ladder/[[:space:]]' "$PLATFORM_REPO_DIR/.github/CODEOWNERS" | grep -qF "$SECOND_HUMAN_EMAIL" && echo "ladder owned by the second person" || echo "STOP: /ladder/ has no second-person code owner (01 PP-5.2)"
python3.12 -c 'import yaml,sys; l=yaml.safe_load(open(sys.argv[1])); c={(x["family"],x["trigger"]):x["level"] for x in l["cells"]}; assert all(v in ("L0","L1") for v in c.values()), "a cell above L1 in v1"; print("ladder v1: all cells L0 or L1")' "$PLATFORM_REPO_DIR/ladder/${A}/ladder.yaml"
```

- **VERIFY:** The ladder check prints; `ladder owned by the second person` prints, so no raise merges without the second person's review; the signed manual parse (PV-D-13) records that the file validates against `ladder.schema`, `SUPER` and `WRITE_GENERIC` are L0, `ou_allowlist` equals `PILOT_OU`, and no raise exists; merge carries two human approvals.
- **ROLLBACK:** Revert the pull request.
- **EVIDENCE:** The three hashes and the signed parse as `${R}-4.2-ladder-v1`. E-03, E-05. TISAX 5.2.

### PW-4.3 Deploy `<agent_id>-actions` by digest, under a grant the second person approves - **BLOCKED on PB-04**

- **WHO:** Platform owner requests `ent-deploy-credential-holder-${A}`; **the second person approves it**; the second person reads the digest comparison.
- **WHERE:** shell.
- **ACTION:** Build in `CICD_PROJECT` into `AR_PLATFORM`; record the digest **before** the deploy; deploy by digest; read the running digest back **after** (PV-D-12 stands in for Binary Authorization).

```bash
GRANT_REQ="$(gcloud pam grants create --entitlement="ent-deploy-credential-holder-${A}" --requested-duration=3600s --justification="PW-4.3 deploy ${DOER_CODE_COMMIT}" --location=global --project="$DOER_PROJECT" --billing-project="$CICD_PROJECT" --format='value(name)')"
DIG="$(gcloud artifacts docker images describe "${AR_PLATFORM}/${A}-actions@sha256:<from the build record>" --format='value(image_summary.digest)')"
printf '%s\tbefore\t%s\n' "$(date -u +%FT%TZ)" "$DIG" >> "${R}-4.3-digest-v1.tsv"
set -a; . "$DOER_ALLOWLIST_FILE"; set +a
gcloud run deploy "${A}-actions" --image="${AR_PLATFORM}/${A}-actions@${DIG}" --region="$REGION" --project="$DOER_PROJECT" \
  --service-account="${A}-actions@${DOER_PROJECT}.iam.gserviceaccount.com" --no-allow-unauthenticated --ingress=all \
  --timeout=60s --min-instances=0 --max-instances=4 \
  --set-env-vars="^;^AGENT_ID=${A};ROBOT_ACCOUNT=${DOER_ROBOT};OPERATOR_GROUP=${GRP_DOER_OPERATORS};PROTECTED_GROUP=${GRP_DOER_PROTECTED};SECRET_LOCATION=${REGION};REFRESH_TOKEN_SECRET=${DOER_REFRESH_TOKEN_SECRET_NAME};REFRESH_TOKEN_VERSION=${DOER_TOKEN_VERSION};AUDIT_DATASET=${DOER_AUDIT_DS};LADDER_SHA=${LADDER_SHA};HARD_DENIED_SHA=${DOER_HARD_DENIED_SHA};EXEC_CALLER_ALLOWLIST=${EXEC_CALLER_ALLOWLIST};APPROVE_CALLER_ALLOWLIST=${APPROVE_CALLER_ALLOWLIST};CONTROL_CALLER_ALLOWLIST=${CONTROL_CALLER_ALLOWLIST};HALT_CALLER_ALLOWLIST=${HALT_CALLER_ALLOWLIST};TASKS_CALLER_ALLOWLIST=${TASKS_CALLER_ALLOWLIST}"
penv_set DOER_ACTIONS_URL "$(gcloud run services describe "${A}-actions" --region="$REGION" --project="$DOER_PROJECT" --format='value(status.url)')"
gcloud run services update "${A}-actions" --region="$REGION" --project="$DOER_PROJECT" --update-env-vars="AUDIENCE=${DOER_ACTIONS_URL}"
printf '%s\tafter\t%s\n' "$(date -u +%FT%TZ)" "$(gcloud run services describe "${A}-actions" --region="$REGION" --project="$DOER_PROJECT" --format='value(spec.template.spec.containers[0].image)' | sed 's/.*@//')" >> "${R}-4.3-digest-v1.tsv"
```

  Then WS-3.2's secret-looking-value grep over the environment read-back.
- **VERIFY:** The grant's approver is the second person, not person 1; the two digest lines are equal and the image reference is `@sha256:`, never a tag; env holds names and version numbers only (`no secret-looking value in env`); `AUDIENCE` equals `DOER_ACTIONS_URL`. The same deploy on `DOER_NONPROD_PROJECT` with no `REFRESH_TOKEN_*` value and `ou_allowlist` `NONPROD_OU`.
- **ROLLBACK:** `gcloud run services update-traffic` to the previous revision, or delete the service. The credential is untouched.
- **EVIDENCE:** Digest TSV, grant approval entry, env read-back as `${R}-4.3-deploy-v1`; `evidence_add PW-4.3 deploy-digest E-05 5.2.4 ...`. TISAX 5.2.4, 4.1.3.

### PW-4.4 `run.invoker`: service accounts only

- **WHO:** Platform owner under the repair grant.
- **WHERE:** shell.
- **ACTION:** Bind `roles/run.invoker` on `<agent_id>-actions` to `${A}-tasks@`, `${A}-operators-caller@`, the approval surface identity (after PW-4.5) and, after PW-5.4, `DOER_AGENT_PRINCIPAL`. Give each member of `GRP_DOER_OPERATORS` `roles/iam.serviceAccountTokenCreator` on `${A}-operators-caller@` only. This lets any operator pull the andon-cord levers (K0 halt, K1 demote) alone, which the design allows; it does **not** let one person lower a guard: PB-04 refuses a halt clear or override lift arriving through `${A}-operators-caller@` without a second human's approval id (PW-4.1, negative `N-SINGLE-CLEAR` in PW-4.8). Then WS-3.5's check.

```bash
gcloud run services get-iam-policy "${A}-actions" --region="$REGION" --project="$DOER_PROJECT" --format=json | jq -r '.bindings[]? | select(.role=="roles/run.invoker") | .members[]' | grep -vE '^(serviceAccount:|principal://)' && echo "FAIL: a human, group or domain invoker" || echo "invoker set clean"
```

- **VERIFY:** `invoker set clean`; `${A}-agent@` and any agent principal hold no role on the secrets and no invoker on the approval surface.
- **ROLLBACK:** `gcloud run services remove-iam-policy-binding` per member.
- **EVIDENCE:** Policy as `${R}-4.4-invokers-v1.json`. E-06. TISAX 4.2.1.

### PW-4.5 The approval surface behind IAP - **BLOCKED on PB-04**

- **WHO:** Platform owner; person 3 tests it.
- **WHERE:** shell; Console > Security > Identity-Aware Proxy.
- **ACTION:** **BLOCKED.** Deploy the surface from PB-04 as `${A}-approvals` with its own service account, behind IAP ([setup/33](../setup/33-wall-e-action-services-and-approval-surfaces.md) WS-5.1 to WS-5.7); IAP access policy: `GRP_DOER_OPERATORS` only; the IAP service agent `run.invoker` on the surface; the surface `run.invoker` on the action service. The surface renders the canonical request hash and the operator approves that hash, not a summary.

```bash
penv_set DOER_APPROVAL_A_URL "$(gcloud run services describe "${A}-approvals" --region="$REGION" --project="$DOER_PROJECT" --format='value(status.url)')"
```

- **VERIFY:** A member of the group reaches the page; the non-admin colleague is refused by IAP; the agent's identity is refused by IAP (WS-6.1).
- **ROLLBACK:** Delete the surface.
- **EVIDENCE:** IAP policy and the three results as `${R}-4.5-approval-surface-v1`. E-08. TISAX 4.2.1.

### PW-4.6 L1 is a forced dry run that refuses even a valid approval - **BLOCKED on PB-04**

- **WHO:** Platform owner runs; person 3 holds and presents a real, valid approval; the second person reads the audit rows.
- **WHERE:** shell and the approval surface, `DOER_PROJECT` with the cell at L1.
- **ACTION:** Named negative `N-L1-VALID-APPROVAL`. Ask the doer through Gemini Enterprise for one catalogued operation on a synthetic account in `PILOT_OU`. The service records `decision=shadow` with the would-be verdict. Person 3 then issues a valid, unexpired approval for that exact `request_hash` and posts it to the execute path.

```bash
bq query --project_id="$DOER_PROJECT" --use_legacy_sql=false --format=csv \
 "SELECT ts, level, decision, denial_reason, request_hash, approval_id FROM \`${DOER_PROJECT}.${DOER_AUDIT_DS}.actions\` WHERE ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR) ORDER BY ts" | tee "${R}-4.6-l1-rows-v1.csv"
```

  The Admin console's Admin log events and the synthetic account's own state are read by the second person for the same window.
- **VERIFY:** The first row is `shadow`; the approval attempt is `denied` with `p:level_no_execute`; the synthetic account is **unchanged**; no Workspace event attributable to `DOER_ROBOT` exists in the window. Any mutation is a severity-1 abort of the POV-2 stage, not a finding.
- **ROLLBACK:** Nothing changed, by construction. If something did, apply the operation's inverse and open an incident.
- **EVIDENCE:** CSV, the second person's Admin-log read, signed; part of `DOER_DENIALS_RECORD`. E-09. TISAX 1.5.1, 5.2.

### PW-4.7 `audit_unavailable` is a denial reason - **BLOCKED on PB-04**

- **WHO:** Platform owner; the second person observes.
- **WHERE:** shell, **`DOER_NONPROD_PROJECT` only**.
- **ACTION:** Named negative `N-AUDIT-UNAVAILABLE`. Remove the writer entry from the nonprod dataset access array (PW-2.6's function with no writer), send one request, restore the entry.
- **VERIFY:** The request is refused with `p:audit_unavailable` in the response and in Cloud Logging (the audit row cannot exist, which is the point); `/healthz` reports the last successful audit write as stale; after restoring, the next request writes a row. No evidence, no action.
- **ROLLBACK:** Re-apply the recorded access array; the step does it itself.
- **EVIDENCE:** Response bodies, log entries and the before/after arrays in `DOER_DENIALS_RECORD`. E-09. TISAX 5.2.6.

### PW-4.8 L3 approval negatives: nonce, expiry, self-approval, non-member, service identity, single-person clear - **BLOCKED on PB-04**

- **WHO:** Person 1 requests; person 3 approves; the second person reads.
- **WHERE:** nonprod first, then prod once PW-6.3 raises a cell to L3.
- **ACTION:** Five named negatives against one L3 cell: `N-NONCE-REPLAY` (the same approval posted twice); `N-EXPIRED` (an approval older than the TTL); `N-SELF-APPROVE` (person 1 approves their own request); `N-NOT-MEMBER` (the non-admin colleague, removed from the group, approves; the live group check must refuse); `N-SERVICE-APPROVER` (an approval asserted by `${A}-operators-caller@` or the agent principal, SD-48); `N-SINGLE-CLEAR` (with a halt set on nonprod, one operator posts `{"mode":"clear"}` through `${A}-operators-caller@` with no second human approval id, then requests a clear on the approval surface and approves it themselves). One positive: person 3 approves person 1's request once.
- **VERIFY:** Six refusals with their `p:` reasons (`N-SINGLE-CLEAR` twice refused, the halt still set afterwards) and one `ok` whose `approver_surrogates` differs from the requester's surrogate; the positive's inverse operation then returns the synthetic account to its pre-state (`pre_state_hash` equals the later `post_state_hash` of the inverse).
- **ROLLBACK:** The inverse operation.
- **EVIDENCE:** The six audit rows; with PW-4.6, PW-4.7 and PW-4.9: `penv_set DOER_DENIALS_RECORD "<record path>"`; `evidence_add PW-4.8 approval-negatives E-09 1.5.1 ...`. TISAX 1.5.1, 4.2.1.

### PW-4.9 Band B exists at L0 and refuses - **BLOCKED on PB-04**

- **WHO:** Platform owner; person 3 reads.
- **WHERE:** shell, both projects.
- **ACTION:** The generic lane is built so the full build **opens** a lane rather than adds one. Send, as each allowed caller in turn (operator caller, agent principal, approval surface with a valid approval), one request to the band-B path for a `WRITE_GENERIC` method and one for a `SUPER` method, targeting a synthetic account.
- **VERIFY:** Every request is `denied` with `p:level_off` and written to `generic_requests`; no Workspace call is made (the service log shows no outbound Admin SDK request); the ladder read shows `SUPER` and `WRITE_GENERIC` at L0 and no API exists to raise them.
- **ROLLBACK:** Nothing changed.
- **EVIDENCE:** The rows and log read; `penv_set BAND_B_DENIAL_RECORD "<record path>"`. E-09. TISAX 1.5.1. **This does not close G12 or G14**: band B has never run with a credential that could act.

---

## 5. Engine, identity, gateways and the floor

Full-set depth: [setup/34](../setup/34-wall-e-identity-spike-and-model-armor.md) and [setup/35](../setup/35-wall-e-engine-registration-and-gateways.md). The engine's code is part of PB-04. The order is the full set's, for the full set's reason: `identity_type` cannot be changed after the engine is created, and the gateway must exist before the engine names it.

### PW-5.1 Agent Identity preconditions and the identity mode

- **WHO:** Platform owner; the second person signs the mode.
- **WHERE:** shell.
- **ACTION:** Enable `agentidentity.googleapis.com` on both projects and prove `agentidentitycredentials` is not enabled ([setup/34](../setup/34-wall-e-identity-spike-and-model-armor.md) WI-1.1). Run WI-2's throwaway-engine spike once in `DOER_NONPROD_PROJECT` (not in prod), read the principal, test that it can obtain an ID token for `DOER_ACTIONS_URL`, delete the spike engine. Record the result.

```bash
penv_set DOER_AGENT_IDENTITY_MODE "AGENT_IDENTITY"    # or SERVICE_ACCOUNT, only on a failed spike, per WI-3.2
```

- **VERIFY:** The spike record shows the principal format `principal://agents.global.org-<ORG_ID>.system.id.goog/resources/aiplatform/projects/<number>/locations/<region>/reasoningEngines/<id>` (Google's Agent Identity page, read 2026-09-16) and a successful ID token; no spike engine remains. On `SERVICE_ACCOUNT`, the register row's `principal` field cannot satisfy the schema's pattern and the Tier W row cannot go green: stop and record.
- **ROLLBACK:** Delete the spike engine; the mode is `penv_set --force` with a build-log line.
- **EVIDENCE:** Spike record as `${R}-5.1-identity-mode-v1`. E-05. TISAX 4.1.1.

### PW-5.2 Gateways and the doer's Model Armor templates, `failOpen: false`

- **WHO:** Platform owner under the deploy grant, approved by the second person.
- **WHERE:** shell.
- **ACTION:** Egress gateway `${A}-egress` (`AGENT_TO_ANYWHERE`, registry in `CORE_PROJECT`) exactly as [setup/35](../setup/35-wall-e-engine-registration-and-gateways.md) WE-1.3 with its policy in dry run until PW-5.4. Model Armor prompt and response templates `${A}-ingress-prompt` and `${A}-ingress-response` in `europe-west1` at the Tier W standard of `FLOOR_RECORD` ([setup/34](../setup/34-wall-e-identity-spike-and-model-armor.md) WI-7.11 shape; basic or advanced SDP per [03](03-foundation-folders-logging-and-floors.md)'s floor file). Ingress gateway `${A}-ingress` (`CLIENT_TO_AGENT`) with the content authorisation extension (WI-7.15):

```bash
cat > "$R-5.2-ma-ext.yaml" <<EOF
name: ${A}-ma-content-authz-ext
service: modelarmor.${REGION}.rep.googleapis.com
metadata:
  model_armor_settings: '[{"request_template_id":"projects/${DOER_PROJECT}/locations/${REGION}/templates/${A}-ingress-prompt","response_template_id":"projects/${DOER_PROJECT}/locations/${REGION}/templates/${A}-ingress-response"}]'
failOpen: false
timeout: 1s
EOF
gcloud beta service-extensions authz-extensions import "${A}-ma-content-authz-ext" --source="$R-5.2-ma-ext.yaml" --location="$REGION" --project="$DOER_PROJECT"
penv_set MA_TEMPLATE_DOER "projects/${DOER_PROJECT}/locations/${REGION}/templates/${A}-ingress-prompt"
penv_set DOER_GATEWAY_ID "projects/${DOER_PROJECT}/locations/${REGION}/agentGateways/${A}-ingress"
```

- **VERIFY:** `gcloud beta service-extensions authz-extensions describe "${A}-ma-content-authz-ext" --location="$REGION" --project="$DOER_PROJECT"` shows `failOpen: false` (Google: "If the extension times out or fails, request processing stops", the default, read 2026-09-16); the authz policy shows `CONTENT_AUTHZ`, `CUSTOM` and the ingress gateway; both templates describe as created. **In bold in the record: the screen produces evidence, not a boundary.**
- **ROLLBACK:** Delete the policy, the extension, then the gateway, in that order, before any engine names them.
- **EVIDENCE:** The describes as `${R}-5.2-gateways-armor-v1`. E-15. TISAX 5.2.6.

### PW-5.3 The project floor at `PF_TIER=W`

- **WHO:** Platform owner under `ENT_FOLDER_ADMIN` and the repair grant.
- **WHERE:** shell.
- **ACTION:** Run [setup/18](../setup/18-model-armor-floor-spikes-and-kill-switch.md) KS-2.9's PF block unchanged **twice**: with `PF_PROJECT="$DOER_PROJECT"`, `PF_PROJECT_NUMBER="$DOER_PROJECT_NUMBER"`, `PF_TIER=W`, then with `PF_PROJECT="$DOER_NONPROD_PROJECT"`, `PF_PROJECT_NUMBER="$DOER_NONPROD_PROJECT_NUMBER"`, `PF_TIER=W`, because both projects enable `aiplatform.googleapis.com` and every project that can call a model carries a floor (the enforcement type is read from `floors.json`'s `measured_flip.W`, `INSPECT_ONLY` unless measured). A project floor overrides a conflicting folder floor (Google's floor-settings page, read 2026-09-16), so the floor is held by who may write it and by the weekly hand compare (B-02 PENDING), not by inheritance.
- **VERIFY:** KS-2.9's VERIFY with W's expectations; the floor is not looser than `FLOOR_RECORD`'s folder floor.
- **ROLLBACK:** KS-2.9's rollback.
- **EVIDENCE:** Floor describe as `${R}-5.3-project-floor-v1.json`. E-05. TISAX 5.2.6.

### PW-5.3a Re-run the zero-diff checker on both projects once their floors exist, without `--accept-pending`

- **WHO:** Platform owner runs; **the second person reads both reports** and initials them.
- **WHERE:** Shell, after PW-5.3's grants are revoked (an active grant reads as a human member).
- **ACTION:** PW-5.3 wrote what the eight `floor.*` `pending` lines wait for. Run setup/17 FM-2.21 again on each spec without `--accept-pending`. A later step of this file that changes anything the checker reads (a project role, a service, a project-level policy) revises the spec by a reviewed commit and re-runs this step.

```bash
need DOER_PROJECT DOER_NONPROD_PROJECT A CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR SECOND_HUMAN_EMAIL
checkpoint PW-5.3a START "$SECOND_HUMAN_EMAIL" - "setup/17 FM-2.21 on the doer's projects after PW-5.3"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
for E in prod nonprod; do
  P="$DOER_PROJECT"; [ "$E" = nonprod ] && P="$DOER_NONPROD_PROJECT"
  gcloud pam grants search --entitlement="ent-project-repair-${A}" --location=global --project="$P" --billing-project="$CICD_PROJECT" --caller-relationship=had-created --filter='state=ACTIVE' --format='value(name)' | grep -q . && echo "STOP: an active repair grant on $P; revoke it first" || echo "$E no active repair grant"
  if python3.12 "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" live "$PLATFORM_REPO_DIR/factory/runs/${A}-${E}.json" --report "${R}-5.3a-live-${E}-v1.json"; then echo "$E exit=0"; else echo "$E exit=$?"; fi
  jq -r --arg e "$E" '.results[] | select(.status != "PASS") | "\($e) \(.status) \(.check)"' "${R}-5.3a-live-${E}-v1.json"
done
```

- **VERIFY:** `no active repair grant` for both; `ZERO-DIFF` and `exit=0` for both without `--accept-pending`; the non-`PASS` listings are empty, so `floor.enforced`, `floor.pi`, `floor.malicious_uri`, `floor.rai`, `floor.integration`, `floor.vertex_enforcement` and `floor.service_agent_role` read `PASS` on both projects. PW-2.2a's line in `rerun-index.tsv` is closed with this step's id. A `FAIL` is repaired as PW-2.2a says. Then `checkpoint PW-5.3a DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$(basename "${R}-5.3a-live-prod-v1.json")" "both doer projects ZERO-DIFF against their run specs"`.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Both reports, initialled by the second person; `evidence_add PW-5.3a zero-diff E-05 5.2.4 build-log:records/ "${R}-5.3a-live-prod-v1.json"`. E-05. TISAX 5.2.4.

### PW-5.4 Create the engine once, then `DOER_AGENT_PRINCIPAL` - **BLOCKED on PB-04**

- **WHO:** Platform owner under the deploy grant approved by the second person.
- **WHERE:** shell.
- **ACTION:** **BLOCKED on PB-04** (the ADK agent source). One create, as [setup/35](../setup/35-wall-e-engine-registration-and-gateways.md) WE-2: `identity_type=AGENT_IDENTITY`; `agent_gateway_config` with both gateways; the model client on the `eu` endpoint at `MODEL_ID`; `env_vars` with no secret. Read `ENGINE_ID` from `api_resource.name`, the principal from `spec.effectiveIdentity`; apply the two-principal engine lock (WE-3); bind the principal `run.invoker` on `<agent_id>-actions`, add it to `EXEC_CALLER_ALLOWLIST`, redeploy under PW-4.3's procedure; switch the egress policy from dry run to enforce (WE-9).

```bash
penv_set DOER_ENGINE "projects/${DOER_PROJECT_NUMBER}/locations/${REGION}/reasoningEngines/<ENGINE_ID>"
penv_set DOER_AGENT_PRINCIPAL "principal://agents.global.org-${ORG_ID}.system.id.goog/resources/aiplatform/projects/${DOER_PROJECT_NUMBER}/locations/${REGION}/reasoningEngines/<ENGINE_ID>"
```

- **VERIFY:** Exactly one engine; its environment read-back holds no secret-looking value (WE-2.8); `DOER_AGENT_PRINCIPAL` holds no role on any secret, no invoker on the approval surface and no role on the audit tables (PW-2.6's probe via `gcloud policy-troubleshoot iam`, never by impersonating the credential holder now that a token exists).
- **ROLLBACK:** Delete the engine; the principal dies with it and every binding naming it is removed (a new engine is a new principal).
- **EVIDENCE:** Engine describe, lock read, IAM reads as `${R}-5.4-engine-v1`. E-05. TISAX 4.2.1.

### PW-5.4a Register the doer's engine in `AGENT_REGISTRY`, a witnessed repair write - **BLOCKED on PB-04**

- **WHO:** Platform owner under a **fresh `ENT_PROJECT_REPAIR_CORE` grant** requested for this write alone; **the second person approves it** in their own console (Security > Privileged Access Manager > Approve grants; never person 1, and PAM refuses self-approval), types the grant id and the entry id back from the operator's screen before the write, and confirms the registry write alert email.
- **WHERE:** shell; the second person's PAM console and own inbox (`NOTIF_CH_EMAIL_CORE`).
- **ACTION:** **BLOCKED on PB-04** only because the engine of PW-5.4 is; until then `checkpoint PW-5.4a BLOCKED - - "PB-04 (the engine of PW-5.4)"`. The shape is [setup/35](../setup/35-wall-e-engine-registration-and-gateways.md) WE-7.3's registration of Wall-E's engine: read the registry before, one `services create` whose interface URL is the engine's regional resource URL, read it after, describe the entry, then (as WE-9.7) read the write back from the audit log and confirm the alert. Four differences, each for a reason:
  1. **The registry is `AGENT_REGISTRY` in `CORE_PROJECT`** ([04](04-the-contract-register-agent-ids-and-schemas.md) PC-4.1), not setup/35's `GE_REGISTRY` in `GEMINI_PROJECT`: the POV builds no Gemini Enterprise gateway ([05](05-gemini-enterprise-and-tier-c.md) PG-9.1's open row), and the owner's objective is that every agent is in the shared registry. Google: automatic registration "only discovers resources deployed within the same Google Cloud project", and "To register agents deployed across different projects, see manual registration" (automatic-registration page, read 2026-09-16). `DOER_PROJECT` does not enable `agentregistry.googleapis.com` (PW-2.1), so this manual entry is the doer's only one.
  2. **The writer is a human under `ENT_PROJECT_REPAIR_CORE`**, approved by the second person, not setup/35's CI identity: in the POV nobody holds a standing registry role (04 PC-4.1, PV-D-01). The model never writes the registry, and no agent principal is ever granted a registry role (Google: "avoid granting these roles directly to agents", roles page, read 2026-09-16); the block stops if `DOER_AGENT_PRINCIPAL`, `${A}-agent@` or `${A}-actions@` holds one.
  3. **It is registered as an agent** (`--agent-spec-type=no-spec`), Google's documented form for a "standard REST agent" (manual-registration page, read 2026-09-16), so the registry projects it as a read-only `Agent`. setup/35 WE-7.3 registers the engine as an endpoint because there it is a gateway destination; here it is the agent's inventory entry.
  4. **It carries the doer's `agent_id`**: display name `AGENT_ID_DOER`, and the description's first line `meta: agent_id=<agent_id> tier=W env=prod project=... engine=... register_row=register/<agent_id>.yaml` (setup/35 WE-9.6's `meta:` rule, without `register_sha`, which PW-5.6 would make stale), so the entry joins the register row and every audit table on `agent_id` ([05-registry](../05-registry-and-autonomy-contract.md) §9.4). The service id is `<agent_id>-engine`; the variable is `DOER_REGISTRY_ENTRY`, never `WALLE_REGISTRY_ENTRY`, which setup/35 sets.

  `Assumption:` the interface is `url=https://europe-west1-aiplatform.googleapis.com/v1/projects/<DOER_PROJECT_NUMBER>/locations/europe-west1/reasoningEngines/<ENGINE_ID>` with `protocolBinding=http-json`, setup/35 WE-7.3's form. Google documents the engine's `:query` and `:streamQuery` calls on that host and path ("Use an Agent Development Kit agent", read 2026-09-16) and `http-json` as a valid binding (register-endpoints page, read 2026-09-16), but no page shows an Agent Runtime engine registered cross-project (setup/20 §9 records the same gap). Manual registration is refused in the `us` and `eu` multi-regions and works in `europe-west1` (locations page, read 2026-09-16).

```bash
pw54a_register() {
  need AGENT_ID_DOER AGENT_REGISTRY ENT_PROJECT_REPAIR_CORE CORE_PROJECT CICD_PROJECT REGION DOER_PROJECT DOER_PROJECT_NUMBER DOER_ENGINE DOER_AGENT_PRINCIPAL NOTIF_CH_EMAIL_CORE SECOND_HUMAN_EMAIL SA_1_ADMIN || return 1
  [ "$REGION" = europe-west1 ] || { echo "STOP: REGION is not europe-west1; the us and eu multi-regions refuse manual registration"; return 1; }
  [ "$AGENT_REGISTRY" = "projects/${CORE_PROJECT}/locations/${REGION}" ] || { echo "STOP: AGENT_REGISTRY is not CORE_PROJECT in REGION (04 PC-4.1)"; return 1; }
  case "$DOER_ENGINE" in *'<'*) echo "STOP: DOER_ENGINE still holds a placeholder (PW-5.4)"; return 1;; "projects/${DOER_PROJECT_NUMBER}/locations/${REGION}/reasoningEngines/"?*) : ;; *) echo "STOP: DOER_ENGINE is not an engine of DOER_PROJECT in REGION"; return 1;; esac
  awk -F'\t' '$2=="PG-7.1a" && $3=="DONE"' "$BUILD_LOG_DIR/checkpoints.tsv" | grep -q . || { echo "STOP: 05 PG-7.1a is not DONE; the registry write alert is unproven"; return 1; }
  gcloud pam entitlements describe "$ENT_PROJECT_REPAIR_CORE" --billing-project="$CICD_PROJECT" --format='yaml(privilegedAccess.gcpIamAccess.roleBindings)' | grep -q 'roles/agentregistry.admin' || { echo "STOP: ENT_PROJECT_REPAIR_CORE lacks agentregistry.admin (03 PF-5.1); substitute nothing"; return 1; }
  N="${A}-engine"
  checkpoint PW-5.4a START "$SECOND_HUMAN_EMAIL" - "AGENT_REGISTRY write under ENT_PROJECT_REPAIR_CORE" || return 1
  G="$(gcloud pam grants create --entitlement="$ENT_PROJECT_REPAIR_CORE" --requested-duration=3600s --justification="POV 07 PW-5.4a: register the ${A} engine as ${N} in AGENT_REGISTRY" --additional-email-recipients="$SECOND_HUMAN_EMAIL" --billing-project="$CICD_PROJECT" --format='value(name)')" && [ -n "$G" ] || return 1
  printf '%s\n' "$G" > "${R}-5.4a-grant-name-v1.txt"
  confirm_manual PW-5.4a "Second person: approve the grant in your own console, then type the last segment of its name as the operator's screen shows it" || return 1
  [ "$(tail -1 "$BUILD_LOG_DIR/confirmations.tsv" | cut -f5)" = "${G##*/}" ] || { echo "STOP: typed grant id differs from ${G##*/}"; return 1; }
  [ "$(gcloud pam grants describe "$G" --billing-project="$CICD_PROJECT" --format='value(state)')" = ACTIVE ] || { echo "STOP: grant ${G} is not ACTIVE"; return 1; }
  gcloud pam grants describe "$G" --billing-project="$CICD_PROJECT" --format=json > "${R}-5.4a-grant-v1.json"
  gcloud projects get-iam-policy "$CORE_PROJECT" --flatten="bindings[].members" --filter="bindings.role:roles/agentregistry." --format="table(bindings.role,bindings.members)" | tee "${R}-5.4a-registry-iam-v1.txt" | grep -F -e "$DOER_AGENT_PRINCIPAL" -e "${A}-agent@" -e "${A}-actions@" && { echo "STOP: a doer principal holds a registry role"; return 1; }
  gcloud agent-registry services list --location="$REGION" --project="$CORE_PROJECT" --format='value(name)' | tee "${R}-5.4a-registry-before-v1.txt" | grep -q "/services/${N}\$" && { echo "STOP: ${N} already exists; resume rule, do not re-create"; return 1; }
  confirm_manual PW-5.4a "Second person: type the service id shown on the operator's screen" || return 1
  [ "$(tail -1 "$BUILD_LOG_DIR/confirmations.tsv" | cut -f5)" = "$N" ] || { echo "STOP: typed id differs from ${N}"; return 1; }
  gcloud agent-registry services create "$N" --project="$CORE_PROJECT" --location="$REGION" \
    --display-name="$A" \
    --description="$(printf 'meta: agent_id=%s tier=W env=prod project=%s engine=%s register_row=register/%s.yaml\n\n%s' "$A" "$DOER_PROJECT" "$DOER_ENGINE" "$A" "The POV doer's Agent Runtime engine (POV 07 PW-5.4a), a Tier W agent with no Workspace admin role.")" \
    --agent-spec-type=no-spec \
    --interfaces="url=https://${REGION}-aiplatform.googleapis.com/v1/${DOER_ENGINE},protocolBinding=http-json" || return 1
  date -u +%FT%TZ | tee "${R}-5.4a-create-time-v1.txt"
  penv_set DOER_REGISTRY_ENTRY "${AGENT_REGISTRY}/services/${N}" || return 1
  gcloud agent-registry services list --location="$REGION" --project="$CORE_PROJECT" --format=json > "${R}-5.4a-registry-after-v1.json"
  gcloud agent-registry services describe "$N" --location="$REGION" --project="$CORE_PROJECT" --format=json > "${R}-5.4a-entry-v1.json"
  gcloud agent-registry agents list --location="$REGION" --project="$CORE_PROJECT" --format='table(name)' > "${R}-5.4a-agents-after-v1.txt"
  confirm_manual PW-5.4a "Second person: type the UTC arrival time (HH:MM) of the agentregistry write alert email for this write, or none after five minutes" || return 1
  gcloud logging read 'protoPayload.serviceName="agentregistry.googleapis.com" AND logName:"cloudaudit.googleapis.com%2Factivity"' --project="$CORE_PROJECT" --freshness=1h --format='table(timestamp,protoPayload.methodName,protoPayload.authenticationInfo.principalEmail,protoPayload.resourceName)' > "${R}-5.4a-registry-audit-v1.txt"
  gcloud services list --enabled --project="$DOER_PROJECT" --filter="config.name=agentregistry.googleapis.com" --format='value(config.name)' > "${R}-5.4a-doer-project-agentregistry-v1.txt"
  gcloud pam grants revoke "$G" --reason="POV 07 PW-5.4a registration written" --billing-project="$CICD_PROJECT" || return 1
  checkpoint PW-5.4a DONE "$SECOND_HUMAN_EMAIL" "${R}-5.4a-registry-v1.txt"
}
pw54a_register 2>&1 | tee "${R}-5.4a-registry-v1.txt"; [ "${PIPESTATUS[0]}" -eq 0 ] || echo "PW-5.4a STOPPED: nothing after the failing line ran; revoke any ACTIVE grant named in ${R}-5.4a-grant-name-v1.txt"
```

  The audit read runs inside the grant, after the second person has the email, so the entry has been ingested; Google names the write `google.cloud.agentregistry.v1.AgentRegistry.CreateService`, Admin Activity and long-running, usually two entries (audit-logging page, read 2026-09-16).
- **VERIFY:** the second person reads each file, and the operator does not sign it off alone:
  - no `STOPPED` line; `checkpoints.tsv` holds PW-5.4a `START` and `DONE`, both naming the second person; three `CONFIRMED PW-5.4a` lines, whose typed values are the grant id, `<agent_id>-engine` and an arrival time;
  - the grant JSON shows the second person as approver and `SA_1_ADMIN` as requester; `gcloud pam grants describe "$(cat "${R}-5.4a-grant-name-v1.txt")" --billing-project="$CICD_PROJECT" --format='value(state)'` now prints `REVOKED` or `ENDED`;
  - **the registry holds exactly the doer's entry** for this `agent_id`: `jq -r --arg a "$AGENT_ID_DOER" '[.[] | select((.description // "") | startswith("meta: agent_id=" + $a + " "))] | (length | tostring), .[].name' "${R}-5.4a-registry-after-v1.json"` prints `1` and one name ending in `/services/<agent_id>-engine`, and `diff <(sort "${R}-5.4a-registry-before-v1.txt") <(jq -r '.[].name' "${R}-5.4a-registry-after-v1.json" | sort)` shows that one name added and nothing removed. (`Assumption:` the returned name may carry the project number rather than the id, so names are compared on the `/services/<id>` suffix);
  - the entry file shows `displayName` equal to `AGENT_ID_DOER`, an interface URL ending in the `reasoningEngines/<ENGINE_ID>` of `DOER_ENGINE`, and a `registryResource` naming the projected agent, which `agents-after` also lists (`Assumption:` the form of `registryResource`, an output field of the Service resource); the `agent_id` in its `meta:` line equals `python3.12 -c 'import sys,yaml; print(yaml.safe_load(open(sys.argv[1]))["agent_id"])' "$PLATFORM_REPO_DIR/register/${A}.yaml"`;
  - `registry-iam` names no doer principal and no `roles/agentregistry.editor` or `.user` row; the audit file shows `CreateService` on the doer's service by `SA_1_ADMIN` and no other principal in the hour;
  - the arrival time is within five minutes of `create-time`; `none` is a severity 2 finding handled as [05](05-gemini-enterprise-and-tier-c.md) PG-7.1a's VERIFY says, and PW-5.6 does not merge until the alert is fixed and proven again;
  - `doer-project-agentregistry` is empty (`Assumption:` with the API off in `DOER_PROJECT`, Google's same-project automatic registration makes no second entry there).
- **ROLLBACK:** under a new `ENT_PROJECT_REPAIR_CORE` grant the second person approves, the second person reading the id aloud: `gcloud agent-registry services delete "${A}-engine" --project="$CORE_PROJECT" --location="$REGION"` (no `--quiet`); `gcloud agent-registry services list --location="$REGION" --project="$CORE_PROJECT" --format='value(name)'` no longer shows it; `penv_set --force DOER_REGISTRY_ENTRY "*tbd*"` with a build-log line; revoke the grant. The same rollback follows PW-5.4's engine deletion in the same sitting, because a new engine is a new id and the old entry would point at nothing. Deleting the entry stops nothing the engine does: it is inventory, not a kill lever.
- **EVIDENCE:** `${R}-5.4a-registry-v1.txt` with the grant, IAM, before and after, entry, agents and audit files as `${R}-5.4a-*`, signed by the second person; `evidence_add PW-5.4a registry-entry E-05 1.3.1 ...`. E-05. TISAX 1.3.1, 4.2.1.

### PW-5.5 Model proof, registration, share and the invisibility test - **BLOCKED on PB-04**

- **WHO:** Platform owner; the non-admin colleague runs the invisibility test.
- **WHERE:** Gemini Enterprise console (Agents > Add agent > Custom agent via Agent Runtime, [setup/35](../setup/35-wall-e-engine-registration-and-gateways.md) §7), app `GEMINI_APP_ID`.
- **ACTION:** One model call on the `eu` endpoint at `MODEL_ID` (WE-5); one known injection through the ingress gateway producing a Model Armor sanitize log entry with `AGENT_GATEWAY` as client (the hard pass of WI-7.15); register the engine; share to `GRP_DOER_OPERATORS` and `GRP_DOER_READERS` only.
- **VERIFY:** The model proof names `MODEL_ID`; the sanitize entry exists; the colleague, in no doer group, cannot see the agent; an operator can; the audit row for the operator's first question carries the operator's own identity surrogate (S0-3.1's shape).
- **ROLLBACK:** Remove the share, then the registration.
- **EVIDENCE:** As `${R}-5.5-admission-v1`. E-05, E-15. TISAX 5.2.6, 4.2.1.

### PW-5.6 The Tier W register row goes green, `privilege: none`

- **WHO:** Platform owner writes; **person 3 and the second person sign the manual parse** (PV-D-13; B-03 does not exist).
- **WHERE:** `PLATFORM_REPO_DIR/register/<agent_id>.yaml`.
- **ACTION:** Fill the prod and nonprod rows' deploy-time fields: `principal` = `DOER_AGENT_PRINCIPAL`, `gateway_id` = `DOER_GATEWAY_ID`, `armor_template` = `MA_TEMPLATE_DOER`, `model_pin` = `MODEL_ID`, `manifest_sha`, `grader` = the blind grader, `verifier_owner`, `autonomy_ceiling`, `status: pilot`. The row keeps `tier: W`, `privilege: none`, `verifier: platform-verifier`, `metric_pack: full`.

```bash
python3.12 -c 'import json,sys,yaml,jsonschema; s=json.load(open(sys.argv[1])); d=yaml.safe_load(open(sys.argv[2])); jsonschema.validate(d,s); r=[x for x in d["rows"] if x.get("env")=="prod"][0]; assert (r["tier"],r["privilege"],r["verifier"],r["metric_pack"])==("W","none","platform-verifier","full"); print("Tier W row valid, privilege none")' "$PLATFORM_REPO_DIR/register/schema/register-row.schema.json" "$PLATFORM_REPO_DIR/register/${A}.yaml"
```

- **VERIFY:** The line prints; the signed parse records that `platform-verifier` is served by the recomputation of PV-D-13 and that, with no seeded-fault verifier run, every L4 cell would demote to L3 ([05-registry](../05-registry-and-autonomy-contract.md) line 224), which costs nothing because the POV stops at L3.
- **ROLLBACK:** Revert; `status: suspended` if the row must come down after merge.
- **EVIDENCE:** Merge commit and signed parse as `${R}-5.6-tier-w-row-v1`. E-05. TISAX 1.3.1.

---

## 6. The ladder walk and the kill drill

### PW-6.1 L1 shadow runs and the blind grading - **BLOCKED on PB-04**

- **WHO:** Operators ask the doer for pilot work; **person 3 grades blind** from a sample drawn with a published seed; person 1 never grades.
- **WHERE:** Gemini Enterprise; the grades table.
- **ACTION:** Shadow runs over synthetic toil tasks from `TOIL_TASKS` shapes, at least `max(10 %, 5 a week)` per family sampled ([05-registry](../05-registry-and-autonomy-contract.md) §9.5).
- **VERIFY:** Every shadow row has a grade row by person 3; no execution exists at L1.
- **ROLLBACK:** Not applicable.
- **EVIDENCE:** Grades export. E-03, E-09. TISAX 1.5.1.

### PW-6.2 Raise to L2, then L3: humans raise, one notch, after the dwell

- **WHO:** Person 1 proposes; **person 3 and the second person approve**; the security reviewer (person 3) recomputes the evidence block by hand (PV-D-13).
- **WHERE:** pull request on `LADDER_FILE` with a decision record.
- **ACTION:** L1 to L2 after **two weeks** at L1; L2 to L3 after **two weeks** at L2, with the evidence block required above L2 (graded items, Wilson lower bound, window, dwell). The platform defaults are not loosened: a family without enough graded items stays at L2, and the demonstration then runs at the level the evidence allows. Redeploy under PW-4.3; update `LADDER_SHA`.
- **VERIFY:** `ladder_events` shows each raise with the decision record path; `config_version` increments; no raise skipped a level.
- **ROLLBACK:** `POST /v1/ladder/lower` (any operator).
- **EVIDENCE:** Decision records and recomputation as `${R}-6.2-raises-v1`. E-03. TISAX 5.2.

### PW-6.3 K0 pulled during a live L3 run - **BLOCKED on PB-04**

- **WHO:** Person 1 starts a multi-item L3 run that person 3 has approved; **person 3 pulls K0 without asking anyone** once the first item has executed; the second person times and reads.
- **WHERE:** shell through `${A}-operators-caller@`, or the approval surface's halt button.
- **ACTION:**

```bash
TOKEN="$(gcloud auth print-identity-token --impersonate-service-account="${A}-operators-caller@${DOER_PROJECT}.iam.gserviceaccount.com" --audiences="$DOER_ACTIONS_URL" --include-email)"
T0="$(date -u +%s)"
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "${DOER_ACTIONS_URL}/v1/control/halt" -d '{"mode":"no_writes","reason":"PW-6.3 K0 live drill"}'
echo "K0 endpoint seconds: $(( $(date -u +%s) - T0 ))"
```

  The token is never echoed or stored. Then read the audit rows for the run.
- **VERIFY:** K0 accepted under 5 s at the endpoint and containment under 60 s from the decision; the remaining items are `denied` with `p:halted` and carry the new `halt_epoch`; the run is marked `tainted`; the cell is demoted as the ladder's rule for a halted run states; the IAM Credentials Data Access log names the human behind the impersonation; the executed item is reversed by its inverse after the halt is cleared. The record states: **an access token already issued keeps working for the residue measured in PW-6.5, in seconds, never the design's 60-minute bound as fact; K0 stops work now, K4 stops the credential.**
- **ROLLBACK:** After the record is written, the **two-person clear** of [09](09-the-demonstration-deviations-and-the-hand-over.md) PX-1.4: person 1 requests the clear on the approval surface and the second person approves it on their own device; never a `{"mode":"clear"}` post through `${A}-operators-caller@` by one person (PB-04 refuses it, `N-SINGLE-CLEAR`). Then the inverse operation for the executed item.
- **EVIDENCE:** Timings, audit rows, IAM log entry. Part of `KILL_DRILL_RECORD_W`. E-08. TISAX 1.6.1, 5.2.4.

### PW-6.4 K1, K2, K3 and K7, timed - **K1 BLOCKED on PB-04**

- **WHO:** Person 3 pulls K1 and K2; person 1 pulls K3 under the repair grant (K3 opens an incident); K7 by `platform-approvers@` through `ent-k7-human` only (the `k7-executor` image, B-04, does not exist).
- **WHERE:** shell.
- **ACTION:** K1 `POST /v1/control/demote` for one (family, T0) cell. K2: pause every Cloud Scheduler job and detach every push subscription in `DOER_PROJECT` (`gcloud scheduler jobs pause <job> --location="$REGION" --project="$DOER_PROJECT"`). K3: `gcloud run services remove-iam-policy-binding "${A}-actions" --member="$DOER_AGENT_PRINCIPAL" --role=roles/run.invoker ...`, then ask the doer a question in Gemini Enterprise. K7: the levers under `K7_POLICY_DIR` applied to `fld-agents-w-nonprod` (monthly drill tier), timed per lever, then lifted by a two-human pull request.
- **VERIFY:** K1: only that cell drops. K2: no new run starts. K3: the agent's call is refused by Cloud Run IAM while operator control endpoints still work. K7: KF-1 under 60 s, under 5 min end to end; Eve keeps paging (controllers folder untouched). Every lever pulled with no approval where the design says none is needed.
- **ROLLBACK:** Re-promote only by pull request (K1); resume jobs (K2); re-bind (K3); the two-human lift (K7).
- **EVIDENCE:** Times and reads in `KILL_DRILL_RECORD_W`. E-08. TISAX 1.6.1.

### PW-6.5 K4 once, at commissioning, and the second consent sitting - **BLOCKED on PB-04 and PB-05**

- **WHO:** Person 1 pulls K4 (announced to person 3 first); the second person reads the tenant side; both then hold the second consent sitting.
- **WHERE:** shell; Admin console OAuth log events.
- **ACTION:** `POST /v1/control/revoke-credential`: the service revokes its own refresh token at `https://oauth2.googleapis.com/revoke` (the endpoint Google's OAuth web-server page documents, read 2026-09-16). First read the threshold with `"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 K4_RESIDUE_MAX_SECONDS`; with no value, K4 is not pulled. **Immediately** after the revoke, then every 60 seconds from the same warm instance, attempt a Workspace read on a synthetic account until one is refused with a credential error class or `K4_RESIDUE_MAX_SECONDS` has passed, and once more after 60 minutes. Then re-run §3 in full (PW-3.1 to PW-3.4) with `--rotate`, pin the new `DOER_TOKEN_VERSION` and redeploy.
- **VERIFY (one criterion, the same as [09](09-the-demonstration-deviations-and-the-hand-over.md) PX-1.7's):** The revoke returns success; the tenant's OAuth log shows the revocation; **the measured access-token residue**, in seconds from the revoke to the first read refused with a credential error class, is recorded, and the drill **passes when it is at or under PV-01's `K4_RESIDUE_MAX_SECONDS`**. A read that succeeds before the first refusal is part of the measured residue, not by itself a failed kill; a residue over the threshold, or no refusal by the 60-minute read, **fails** the drill. The new version is `ENABLED` and the old one destroyed.
- **ROLLBACK:** **IRREVERSIBLE: the credential is consumed.** Confirm first that both keys, both people and PB-05 are available the same day. Gate: PV-01's K4 line.
- **EVIDENCE:** Timings, every read with its time, the measured residue and the threshold, the new sitting's record; `penv_set KILL_DRILL_RECORD_W "<record path>"` once PW-6.3 to PW-6.5 are in it. E-08. TISAX 1.6.1, 5.1.

### PW-6.6 Write `POV_TIER_W_RECORD`

- **WHO:** Platform owner writes; **the security reviewer (person 3) and the ISMS sign**.
- **WHERE:** `GATES_DIR/TIER-W-<date>.md`, merged by pull request.
- **ACTION:** One evidence line per row of [setup/42](../setup/42-gates-drills-and-evidence.md) GD-2.1, with the POV's substitutions named, never hidden:

| W item | POV evidence | Status |
|---|---|---|
| Autonomy contract and CI | `REGISTER_PATH`, `MANUAL_PARSE_RECORD` | green by signed parse (PV-D-13) |
| Platform verifier live (Eve-H) | `POV_EVE_H_LIVE_RECORD` | green |
| Validator custodian with an identity | the security reviewer's hand recomputation | **open**, PV-D-13 |
| Nonprod folder and project | `FLD_AGENTS_W_NONPROD`, `DOER_NONPROD_PROJECT` | green |
| One restore drill | `DOER_RESTORE_DRILL_RECORD` | green |
| Binary Authorization | digest comparison under a two-person deploy | **open**, PV-D-12 |
| Second operator, security reviewer, blind grader named | `SECOND_OPERATOR_EMAIL`, `SECURITY_REVIEWER_EMAIL`, `BLIND_GRADER_EMAIL` (one person, PV-D-16) | green with deviation |
| K7 drilled on the nonprod tier folder | `KILL_DRILL_RECORD_W` | green |

```bash
penv_set POV_TIER_W_RECORD "$GATES_DIR/TIER-W-$(date -u +%F).md"
```

- **VERIFY:** Every line cites a record path; open rows are open, not green; two signatures in the merge.
- **ROLLBACK:** Revert the merge.
- **EVIDENCE:** `evidence_add PW-6.6 tier-w-record E-05 6.3 ...`. TISAX 1.2.

---

## 7. Optional, separately gated: the Tier P step

**Do not start this section** unless: `POV_EVE_H_LIVE_RECORD` is live (the schema pins `verifier: eve` at Tier P); `POV_TIER_W_RECORD` exists; PV-07 is signed by the platform owner, the second person, person 3 and the ISMS; and `PILOT_OU` holds **synthetic accounts only**. The Tier P purchases (SIEM and MDR, pentest) are deferred by PV-07 and PV-D-10 and PV-D-11, which is why a real account entering `PILOT_OU` ends this section (PV-D-09's unwind).

**What §7 costs, separately** (all `Assumption:`, to be re-estimated when PV-07 is signed): it re-runs §1 to §6 for a second agent (groups, robot and keys, two projects, a second two-person consent sitting, the service with a new manifest, engine, register row, ladder walk), plus two custom roles and the K6-analogue drill. Hands-on about 4 to 6 person-days (persons 1 and 2, with person 3 for grading, the parse and the drill); code about 3 to 5 engineer-days on top of PB-04 (the pilot-admin manifest, four operations and their inverses, the live OU and protected-group re-check); elapsed about 6 to 8 weeks from PV-07's signature, of which **four weeks are the L1 and L2 dwell** of PW-6.2 that cannot be shortened; calendar: it starts no earlier than `POV_TIER_W_RECORD`, so it lands after the Tier W demonstration, never inside it. Not running §7 is a valid POV outcome ([02](02-decisions-people-and-the-retrospective-baseline.md) PD-5.5 rollback).

Three things this section is not: it is not a promotion of the doer (a tier change is a new row and a new project, [02](../02-landing-zone-and-tiers.md) §1.5); it is not P-SA (no Super Admin, ever, on the production tenant); and its drill is **not** G11's K6.

### PW-7.1 Open the Tier P gate and name the new agent

- **WHO:** Platform owner; the second person reads.
- **WHERE:** shell.
- **ACTION:**

```bash
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-07 PV-06
need POV_EVE_H_LIVE_RECORD POV_TIER_W_RECORD FLD_AGENTS_P_PROD FLD_AGENTS_P_NONPROD
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-07 PILOT_ADMIN_AGENT_ID) && [ -n "$v" ] && penv_set PILOT_ADMIN_AGENT_ID "$v" || echo "STOP: no signed PV-07 PILOT_ADMIN_AGENT_ID"   # Assumption: pilot-admin
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES PILOT_ADMIN_ROBOT) && [ -n "$v" ] && penv_set PILOT_ADMIN_ROBOT "$v" || echo "STOP: no signed NAMES PILOT_ADMIN_ROBOT"
```

  **A separate robot account is mandatory.** An admin role applies to the account, not to a token, so assigning a role to `DOER_ROBOT` would widen the Tier W credential's reach through its existing consent and silently turn the Tier W row into a Tier P one.
- **VERIFY:** Both `decision-need.sh` ids signed; the new id is neither `AGENT_ID_DOER` nor reserved; `PILOT_OU` still holds only the PW-1.2 synthetic accounts.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-7.1-tier-p-gate-v1.txt`. E-05. TISAX 1.3.1.

### PW-7.2 The second robot, the projects and the Tier P register row

- **WHO:** Platform owner; the second person approves grants and signs IRREVERSIBLE steps; person 3 and the second person sign the manual parse.
- **WHERE:** as §1 to §2.
- **ACTION:** Re-run PW-1.1 (groups `<pilot-admin id>-*@`), PW-1.3 to PW-1.7 for `PILOT_ADMIN_ROBOT`, PW-2.1 to PW-2.8 with `A="$PILOT_ADMIN_AGENT_ID"`, the NAMES keys `PILOT_ADMIN_PROJECT` and `PILOT_ADMIN_NONPROD_PROJECT`, the parents `FLD_AGENTS_P_PROD` and `FLD_AGENTS_P_NONPROD`, label `tier=p` and tag `agp-tier/p` substituted in a copy of `pw21_create`, with `decision-need.sh PV-07` added to its gate line; the confirmations, START checkpoint and reserved-name checks stay unchanged. Write `register/<pilot-admin id>.yaml` with `tier: P`, `privilege: workspace_role:pilot_writer`, `verifier: eve`, `metric_pack: full+eve-quality`, ladder `ou_allowlist: [PILOT_OU]`.

```bash
for n in PILOT_ADMIN_PROJECT PILOT_ADMIN_NONPROD_PROJECT; do
  v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES "$n") && [ -n "$v" ] && penv_set "$n" "$v" || { echo "STOP: no signed NAMES value for $n"; break; }
done
penv_set PILOT_ADMIN_REGISTER_ROW "register/${PILOT_ADMIN_AGENT_ID}.yaml"
```

- **VERIFY:** PW-5.6's validation with `("P","workspace_role:pilot_writer","eve","full+eve-quality")`. The nonprod rule of [02](../02-landing-zone-and-tiers.md) §2 (Tier P nonprod is a **sandbox tenant**) is **not met**: the nonprod project exists credential-less and the record names PV-D-04 as the open row.
- **ROLLBACK:** As each re-run step; the project ids are **IRREVERSIBLE** (PW-2.1's confirmation, gate PV-07).
- **EVIDENCE:** The re-run records under `${R}-7.2-*`. E-05. TISAX 1.3.1, 4.2.1.

### PW-7.3 Create the two custom admin roles

- **WHO:** Platform owner as `sa-1-admin@`; the second person reads each privilege list on screen before Save.
- **WHERE:** Admin console Menu > Account > Admin roles > Create new role (read 2026-09-16).
- **ACTION:** Two roles, privileges ticked from the Admin console privileges list only:

| Role | Privileges | Deliberately absent |
|---|---|---|
| `Pilot Reader` | Users > Read; Organizational Units > Read | everything else |
| `Pilot Writer` | Users > Update > Move users, Suspend users, Rename users, Add/remove aliases; Organizational Units > Read | Users Create and Delete; Reset password and Force password change; **every Groups privilege** (Google: groups actions "can't be limited to specific organizational units"); Security, Domain, Admin roles, Data (Vault), Services settings |

```bash
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-07 PILOT_ADMIN_ROLE_READ_ID) && [ -n "$v" ] && penv_set PILOT_ADMIN_ROLE_READ "$v" || echo "STOP: no signed PV-07 PILOT_ADMIN_ROLE_READ_ID"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-07 PILOT_ADMIN_ROLE_WRITER_ID) && [ -n "$v" ] && penv_set PILOT_ADMIN_ROLE_WRITER "$v" || echo "STOP: no signed PV-07 PILOT_ADMIN_ROLE_WRITER_ID"
```

  The role ids are read back with `roles.list` in the APIs Explorer and written into PV-07's values by a superseding record if they differ.
- **VERIFY:** `roles.get` for each id returns exactly the privileges above and nothing else; the second person ticks the list.
- **ROLLBACK:** Delete the custom role while it has no assignment.
- **EVIDENCE:** Both `roles.get` JSONs as `${R}-7.3-custom-roles-v1`. E-08. TISAX 4.2.1.

### PW-7.4 Assign Pilot Reader and Pilot Writer, both scoped to `PILOT_OU`

- **WHO:** Platform owner as `sa-1-admin@` assigns; **the second person approves in writing before Save and re-reads the assignment themselves**.
- **WHERE:** Admin console Menu > Directory > Users > `PILOT_ADMIN_ROBOT` > Admin roles and privileges > Assign role; for **each** role, next to **All organizational units** click **Edit**, select `PILOT_OU` only, click **Done** (Google's "Assign specific admin roles" page, read 2026-09-16).
- **ACTION:** Assign Pilot Reader restricted to `PILOT_OU`, then Pilot Writer restricted to `PILOT_OU`. PV-07 ([02](02-decisions-people-and-the-retrospective-baseline.md) PD-5.5) allows exactly two delegated assignments, **both** scoped to `PILOT_OU`; a customer-scoped read would let the robot's consented token read every real employee's directory record, which PV-06, PV-D-09 and PV-D-15 (synthetic accounts only, DPIA not complete) do not cover. If Edit does not appear for either role, **stop**: Google says a role without Edit "cannot" be applied to organisational units (Users and Organizational Units privileges can be limited to organisational units per Google's privilege definitions page, read 2026-09-16). A customer-wide read is possible only by a superseding PV-07 record that names the read's reach, is signed by the DPO, and cites a completed DPIA; this file does not proceed on anything less.
- **VERIFY:** `roleAssignments.list` with `userKey` = `PILOT_ADMIN_ROBOT` returns exactly two items, **both** with `scopeType: ORG_UNIT` and `orgUnitId` equal to `PILOT_OU`'s id; any `scopeType: CUSTOMER` item fails the step and is unassigned the same hour. Eve's roster diff pages `role_assignment_added` for the robot and the second person acknowledges it against this step; the roster file is amended in the same hour. `users.get` on the robot shows `isDelegatedAdmin: true`, `isAdmin` not true.
- **ROLLBACK:** Remove the assignment (Admin roles and privileges > the role > Unassign). This is also PW-7.6's lever.
- **EVIDENCE:** The `roleAssignments.list` JSON and the acknowledged Eve page; `penv_set PILOT_ADMIN_ROLE_ASSIGNMENTS "<record path>"`. E-08. TISAX 4.2.1.

### PW-7.5 The pilot-admin credential and service, with Eve as verifier - **BLOCKED on PB-04 and PB-05**

- **WHO:** As §3 to §6.
- **WHERE:** `PILOT_ADMIN_PROJECT`.
- **ACTION:** Re-run §3 (a separate consent sitting for `PILOT_ADMIN_ROBOT`, two people), §4 (the same PB-04 code with the pilot-admin manifest: the operations Move, Suspend, Rename, Add/remove alias on `PILOT_OU` accounts, each with its inverse; every write re-checks the target's OU and protected-group membership live), §5 and PW-6.1 to PW-6.3. Eve's queries ([06](06-eve-over-the-human-super-admins.md) §11) read this agent's audit and reconcile `ws_insert_ids` with Admin log events.
- **VERIFY:** A `users.get` read by the robot's token on one account **outside** `PILOT_OU` is refused by Google (Unverified table); a write on an account **outside** `PILOT_OU` is refused twice: by the service (`p:protected_principal` or scope) and, on a deliberately forged request in nonprod-shaped test data, by Google (the Admin SDK's permission error), both recorded; Eve reconciles every executed write with a Google-written event.
- **ROLLBACK:** As each re-run step.
- **EVIDENCE:** Records under `${R}-7.5-*`. E-06, E-09. TISAX 4.2.1, 5.2.

### PW-7.6 The K6 analogue on a synthetic target - `K6_ANALOGUE_RECORD`

- **WHO:** **The second person pulls it** as `sa-2-admin@`, unannounced to person 1 within an agreed window; person 3 times.
- **WHERE:** Admin console, as PW-7.4's rollback; then the doer's service.
- **ACTION:** Remove Pilot Writer from `PILOT_ADMIN_ROBOT` while a pilot-admin L3 run is live. Then attempt one approved Suspend on a synthetic account.
- **VERIFY:** Time from decision to removal recorded; the next write fails at Google with a permission error and is audited `denied`; Eve pages the role removal. **The record states in its first line: this drill exercises the runbook on a delegated role scoped to a synthetic OU; it does not close G11, which needs a super-admin twin in a sandbox tenant (PV-D-04, [setup/37](../setup/37-wall-e-sandbox-rehearsal.md)).**
- **ROLLBACK:** Re-assign under PW-7.4 with the second person's written approval.
- **EVIDENCE:** `penv_set K6_ANALOGUE_RECORD "<record path>"`. E-08. TISAX 1.6.1.

### PW-7.7 Write `TIER_P_RECORD`

- **WHO:** Platform owner writes; person 3, the second person and the ISMS sign.
- **WHERE:** `GATES_DIR/TIER-P-<date>.md`.
- **ACTION:** Every Tier P line of [01-hld.md](../01-hld.md) §0.4 listed; the open ones named with their deviation: witness (PV-D-03), sandbox tenant nonprod (PV-D-04), SIEM and 24x7 (PV-D-10), pentest (PV-D-11), DPIA completion (PV-D-15). Scope stated: synthetic accounts only, two delegated assignments, no Super Admin.
- **VERIFY:** No open line is marked green.
- **ROLLBACK:** Revert.
- **EVIDENCE:** `penv_set TIER_P_RECORD "<path>"`; `evidence_add PW-7.7 tier-p-record E-05 1.2 ...`. TISAX 1.2, 4.2.1.

---

## 8. Close

### PW-8.1 Re-prove no delegation and no stray role: `DWD_ABSENCE_PROOF`, second half

- **WHO:** Platform owner; **the second person repeats every read independently**.
- **WHERE:** Admin console Manage Domain Wide Delegation; APIs Explorer.
- **ACTION:** Re-run PW-1.6 with every service account, OAuth client and engine created in this file (both agents if §7 ran). Re-run `roleAssignments.list` for `DOER_ROBOT` (empty) and, if §7 ran, `PILOT_ADMIN_ROBOT` (exactly two). Re-run PW-0.1's reservation checks.
- **VERIFY:** No client id in the DWD list; `DOER_ROBOT` holds no role; the pilot-admin robot holds exactly the two assignments; no reserved name was spent. Both signatures.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Countersigned `${R}-8.1-dwd-absence-close-v1`, appended to `DWD_ABSENCE_PROOF`. E-05. TISAX 4.2.1.

### PW-8.2 Variables, evidence, deviations, re-run points

- **WHO:** Platform owner; person 3 verifies the evidence register lines, not person 1.
- **WHERE:** shell.
- **ACTION:**

```bash
need DOER_PROJECT DOER_NONPROD_PROJECT DOER_PROJECT_NUMBER DOER_ROBOT DOER_AUDIT_DS SERVICE_IDENTITY_OU PILOT_OU NONPROD_OU \
     GRP_DOER_OPERATORS GRP_DOER_READERS GRP_DOER_PROTECTED GRP_DOER_OWNERS DOER_SECRET_NAMES DOER_REFRESH_TOKEN_SECRET_NAME \
     DWD_ABSENCE_PROOF DOER_RESTORE_DRILL_RECORD
for v in DOER_TOKEN_VERSION DOER_CONSENT_SITTING_RECORD DOER_ACTIONS_URL DOER_APPROVAL_A_URL DOER_ALLOWLIST_FILE DOER_HARD_DENIED_SHA LADDER_FILE LADDER_SHA \
         DOER_AGENT_IDENTITY_MODE DOER_AGENT_PRINCIPAL DOER_ENGINE DOER_REGISTRY_ENTRY DOER_GATEWAY_ID MA_TEMPLATE_DOER DOER_DENIALS_RECORD BAND_B_DENIAL_RECORD \
         DOER_CODE_COMMIT POV_TIER_W_RECORD KILL_DRILL_RECORD_W; do need "$v" || echo "BLOCKED-OR-PENDING $v"; done
awk -F'\t' '$2 ~ /^PW-/ && $3=="BLOCKED"' "$BUILD_LOG_DIR/checkpoints.tsv"
checkpoint PW-8.2 DONE
sitting_end
```

- **VERIFY:** The first `need` is silent; every `BLOCKED-OR-PENDING` name maps to a BLOCKED checkpoint naming PB-01, PB-04 or PB-05; the `PENDING` readers (`mo-metrics@`) are in `rerun-index.tsv`; the deviations used are listed in `DEVIATION_REGISTER` with their PV-D ids.
- **ROLLBACK:** Append-only.
- **EVIDENCE:** Output as `${R}-8.2-close-v1.txt`. E-05. TISAX 5.2.

---

## Verification checklist for the whole part

- [ ] Every name this file passes to `need` is set by some earlier file's `penv_set` or by this file, and `TIER_C_RECORD` is unset:
  `for v in $(grep -ho '^ *need [A-Z_ \\]*' "$WIKI_DIR/platform/agentic-platform/pov/07-the-doer-tier-w-and-the-optional-tier-p.md" | tr -d '\\' | sed 's/need//'); do grep -qh "penv_set \(--force \)\?\"\?$v\b" "$WIKI_DIR"/platform/agentic-platform/pov/0[1-7]-*.md || echo "NOT SET ANYWHERE: $v"; done` prints nothing except names that an earlier file sets through a loop variable (for example `CICD_PROJECT` in 03's `penv_set "$P_VAR"` loop), each of which the reviewer confirms by reading that loop (PW-0.1). This file sets no bare full-set gate name: it uses the `DOER_` and `POV_` forms of the README §7.3 table and the names files 03 and 05 set.
- [ ] No full-set gate name set by this file: `grep -nE 'penv_set +(TIER_W_RECORD|EVE_H_LIVE_RECORD|DENIALS_RECORD|RESTORE_DRILL_RECORD|CONSENT_SITTING_RECORD|ACTIONS_URL|APPROVAL_A_URL|AGENT_IDENTITY_MODE|AGENT_PRINCIPAL|HARD_DENIED_SHA|AGENT_REGISTRY|WALLE_REGISTRY_ENTRY|ENGINE_ID|ENGINE)\b'` on this file prints nothing; `POV_STAGE` moved to `POV-2` once, and `DOER_REPO_REMOTE` set once, in PW-0.1.
- [ ] No `walle`, `WALLE_PROJECT` or `walle_audit` created or named in any step; no project under `fld-agents-p-sa-*` (PW-0.1, PW-8.1).
- [ ] The robot holds no admin role, no recovery channel, two keys counted by eye, one key per custodian (PW-1.3 to PW-1.5).
- [ ] `DWD_ABSENCE_PROOF` holds two countersigned reads, first and last, covering every client id this file created (PW-1.6, PW-8.1).
- [ ] Both projects in the `-w-` folders with liens, no human IAM member, `<agent_id>_audit` in `EU`, nine tables with every `p_` column (PW-2.1 to PW-2.5).
- [ ] One writer on the audit dataset; the agent identity can do nothing to it (PW-2.6).
- [ ] Firestore PITR and daily backup; restore drill verified by person 3 (PW-2.3, PW-2.8).
- [ ] Consent sitting: two people, no share, pinned version, scopes verified next morning by the second person alone (PW-3.3, PW-3.4).
- [ ] Deploy approved by the second person, digest equal before and after, no secret in env (PW-4.3).
- [ ] No human, group or domain holds `run.invoker` (PW-4.4).
- [ ] L1 refused a valid approval and nothing mutated; `audit_unavailable` refused; nonce, expiry, self-approval, non-member, service approver and single-person halt clear refused; band B refused on every caller (PW-4.6 to PW-4.9).
- [ ] `failOpen: false` on the content extension; project floor at W; the record says evidence, not boundary (PW-5.2, PW-5.3).
- [ ] `AGENT_REGISTRY` holds exactly one entry whose `meta:` line names `AGENT_ID_DOER`, pointing at `DOER_ENGINE`; it was written under a fresh `ENT_PROJECT_REPAIR_CORE` grant the second person approved, never person 1, with the id read back by the second person; the write alert email arrived within five minutes; no doer principal and no agent principal holds an `agentregistry` role; `DOER_REGISTRY_ENTRY` is set and no unprefixed registry name is (PW-5.4a).
- [ ] Tier W row valid with `privilege: none`, signed parse by two people (PW-5.6).
- [ ] K0 pulled live by someone other than the requester, no approval; K1, K2, K3, K4, K7 timed; the K4 residue measured and compared with PV-01's `K4_RESIDUE_MAX_SECONDS`, not assumed (PW-6.3 to PW-6.5).
- [ ] `POV_TIER_W_RECORD` with open rows open (PW-6.6).
- [ ] If §7 ran: a separate robot; two assignments, **both** `ORG_UNIT`-scoped to `PILOT_OU`, none `CUSTOMER`; no Groups privilege; K6 analogue recorded as not closing G11; `TIER_P_RECORD` with open rows open.

## What the next file needs from this one

- **[08](08-mo-and-the-value-report.md):** `DOER_AUDIT_DS` in `DOER_PROJECT` with the nine tables (PB-01), the `mo-metrics@` READER re-run point of PW-2.6, `AGENT_ID_DOER` as the join key, the grades from PW-6.1, the six operations' audit counts, `KILL_DRILL_RECORD_W`, `POV_TIER_W_RECORD`.
- **[06](06-eve-over-the-human-super-admins.md) §11:** `DOER_AUDIT_DS` and `DOER_PROJECT` for Eve v0's twelve queries; `SA_EVE_V0` is granted READER at PW-2.6.
- **[09](09-the-demonstration-deviations-and-the-hand-over.md):** `DOER_REGISTRY_ENTRY` (the doer in the shared Agent Registry, for the demonstration's "identity, registry, Model Armor" walk-through and the hand-over map), `DOER_ACTIONS_URL`, `DOER_APPROVAL_A_URL`, `GRP_DOER_OPERATORS`, `DOER_DENIALS_RECORD`, `BAND_B_DENIAL_RECORD`, `KILL_DRILL_RECORD_W` (K4 was pulled once at commissioning in PW-6.5; a second K4 in the demonstration costs a third consent sitting), `DWD_ABSENCE_PROOF`, `DOER_CONSENT_SITTING_RECORD`, `DOER_RESTORE_DRILL_RECORD`, `POV_TIER_W_RECORD`, and if §7 ran `TIER_P_RECORD` and `K6_ANALOGUE_RECORD`. **Hand-over note for 09:** [setup/30](../setup/30-wall-e-workspace-side.md) to [39](../setup/39-wall-e-stage-0.md) create Wall-E fresh in `WALLE_PROJECT` reusing this file's code (`DOER_CODE_COMMIT`), `audit.schema`, `ladder.schema`, consent command and kill switch. This file sets none of the full set's Wall-E names: the doer's values are `DOER_AGENT_IDENTITY_MODE`, `DOER_AGENT_PRINCIPAL`, `DOER_ENGINE`, `DOER_REGISTRY_ENTRY`, `DOER_HARD_DENIED_SHA`, `DOER_DENIALS_RECORD`, `DOER_RESTORE_DRILL_RECORD`, `DOER_ACTIONS_URL`, `DOER_APPROVAL_A_URL` and `DOER_CONSENT_SITTING_RECORD`, and the gate record is `POV_TIER_W_RECORD`. The full set's `AGENT_IDENTITY_MODE`, `AGENT_PRINCIPAL` (setup/34), `ENGINE_ID`, `ENGINE`, `WALLE_REGISTRY_ENTRY` (setup/35), `HARD_DENIED_SHA`, `DENIALS_RECORD`, `RESTORE_DRILL_RECORD` (setup/37), `ACTIONS_URL`, `APPROVAL_A_URL` (setup/33), `CONSENT_SITTING_RECORD` (setup/32) and `TIER_W_RECORD` (setup/42 GD-2.2) stay unset by the POV, so each is **re-derived** by the full-set file that owns it and never promoted by renaming a `DOER_` or `POV_` value; a POV record lacks Binary Authorization, a deployed verifier and a witness, so it must not satisfy those gates. `PILOT_OU` and `SERVICE_IDENTITY_OU` carry over unchanged.

## Sources checked on 2026-09-16

- [Data retention and lag times](https://knowledge.workspace.google.com/admin/reports/data-retention-and-lag-times) (page updated 2026-09-10): Admin log events "Near real time (couple of minutes)", 6 months; lag row "OAuth" "Up to a few hours" (the separate "Token" row: "A couple of hours"); retention "OAuth Token log events data" 6 months. Re-read 2026-09-16.
- [Control API access with domain-wide delegation](https://knowledge.workspace.google.com/admin/apps/control-api-access-with-domain-wide-delegation): Menu > Security > Access and data control > API controls > Manage Domain Wide Delegation; super administrator only.
- [Create, edit and delete custom admin roles](https://knowledge.workspace.google.com/admin/users/create-edit-and-delete-custom-admin-roles): Menu > Account > Admin roles > Create new role.
- [Assign specific admin roles](https://knowledge.workspace.google.com/admin/users/assign-specific-admin-roles): "next to All organizational units, click Edit"; "If you don't see Edit, you cannot apply the role to organizational units".
- [Administrator privilege definitions](https://knowledge.workspace.google.com/admin/users/administrator-privilege-definitions): Users Update sub-privileges Move, Suspend, Rename, Reset password, Force password change, Add/remove aliases; Groups actions "can't be limited to specific organizational units"; "Only super admins can change another admin's settings".
- [Directory API roleAssignments](https://developers.google.com/workspace/admin/directory/reference/rest/v1/roleAssignments): `scopeType` `CUSTOMER` or `ORG_UNIT`, `orgUnitId`, `list` by `userKey`.
- [Firestore backups](https://docs.cloud.google.com/firestore/native/docs/backups): `gcloud firestore backups schedules create --database --recurrence=daily --retention`; `backups list --location`; `databases restore --source-backup --destination-database`.
- [Firestore point-in-time recovery](https://docs.cloud.google.com/firestore/native/docs/use-pitr): `--enable-pitr` at `databases create`; seven days' version retention when enabled.
- [gcloud run deploy](https://docs.cloud.google.com/sdk/gcloud/reference/run/deploy): `--image`, `--service-account`, `--no-allow-unauthenticated`, `--ingress`, `--set-env-vars`, `--min-instances`, `--max-instances`, `--timeout`.
- [gcloud pam entitlements create](https://docs.cloud.google.com/sdk/gcloud/reference/pam/entitlements/create) (`--entitlement-file`, `--location`, project/folder/organization scope) and [gcloud pam grants approve](https://docs.cloud.google.com/sdk/gcloud/reference/pam/grants/approve).
- [Agent Identity on Agent Runtime](https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/agent-identity): `identity_type` `AGENT_IDENTITY`; principal `principal://agents.global.org-ORGANIZATION_ID.system.id.goog/resources/aiplatform/projects/PROJECT_NUMBER/locations/LOCATION/reasoningEngines/AGENT_ENGINE_ID`; a redeployment is a new principal and "prior IAM permissions are not inherited".
- [Configure an authorization extension](https://docs.cloud.google.com/service-extensions/docs/configure-authorization-extensions): `failOpen` default false; "If the extension times out or fails, request processing stops".
- [Model Armor floor settings](https://docs.cloud.google.com/model-armor/configure-floor-settings): "project-level floor settings override conflicting folder-level floor settings".
- [OAuth 2.0 for web server applications](https://developers.google.com/identity/protocols/oauth2/web-server): revocation at `https://oauth2.googleapis.com/revoke`; `expires_in` is "the remaining lifetime of the access token in seconds" (example 3920).
- [Agent Registry: use automatic registration](https://docs.cloud.google.com/agent-registry/automatic-registration) (updated 2026-09-15): "If you develop and deploy agents with Agent Runtime on Gemini Enterprise Agent Platform, registration in Agent Registry is automatic"; "Automatic registration only discovers resources deployed within the same Google Cloud project"; "To register agents deployed across different projects, see manual registration" (PW-5.4a).
- [Agent Registry: register agents](https://docs.cloud.google.com/agent-registry/register-agents) (updated 2026-09-15): manual registration for cross-project deployments; with a central governance project, "automatic registration only discovers resources in the local project, so you must manually register the remote agents in the central governance project's registry" (PW-5.4a).
- [Agent Registry: manual registration](https://docs.cloud.google.com/agent-registry/manual-registration) and [register endpoints](https://docs.cloud.google.com/agent-registry/register-endpoints) (both updated 2026-09-15): a standard REST agent is `gcloud agent-registry services create AGENT_NAME --project --location --display-name --agent-spec-type=no-spec --interfaces=url=ENDPOINT_URL,protocolBinding=PROTOCOL`; `protocolBinding` `http-json`, `grpc`, `jsonrpc`; `roles/agentregistry.editor` to register; not supported in the `us` and `eu` multi-regions.
- [Agent Registry locations](https://docs.cloud.google.com/agent-registry/locations) (updated 2026-09-15): no manual registration in `us` and `eu`; `europe-west1` listed.
- [Agent Registry key concepts](https://docs.cloud.google.com/agent-registry/concepts) (updated 2026-09-15): a `Service` is projected as a read-only `Agent`, `McpServer` or `Endpoint`; the Agent Runtime agent identifier form `urn:agent:projects-PROJECT_NUMBER:projects:PROJECT_NUMBER:locations:REGION:reasoningEngines:AGENT_ID`.
- [Agent Registry roles and permissions](https://docs.cloud.google.com/agent-registry/roles-permissions) (updated 2026-09-15): `roles/agentregistry.admin`, `.editor`, `.viewer`, `.user`, project level; "avoid granting these roles directly to agents".
- [Agent Registry audit logging](https://docs.cloud.google.com/agent-registry/audit-logging) (updated 2026-09-15): `google.cloud.agentregistry.v1.AgentRegistry.CreateService` and `DeleteService`, Admin Activity, `ADMIN_WRITE`, long-running, "usually generate two audit log entries".
- [Agent Registry Service resource](https://docs.cloud.google.com/agent-registry/reference/rest/v1/projects.locations.services) (updated 2026-06-24): `name` `projects/{project}/locations/{location}/services/{service}`, `displayName` (63 characters), `description` (2,048), `interfaces[]`, output-only `registryResource`, `agentSpec`, `endpointSpec`, `mcpServerSpec`.
- gcloud reference (updated 2026-06-30, GA with an alpha variant): [agent-registry services create](https://docs.cloud.google.com/sdk/gcloud/reference/agent-registry/services/create) (`--location` required; `--interfaces` shorthand, JSON or file; `--agent-spec-type` `a2a-agent-card` or `no-spec`; `--endpoint-spec-type` `no-spec` only), [services delete](https://docs.cloud.google.com/sdk/gcloud/reference/agent-registry/services/delete) (no prompt documented), [services list](https://docs.cloud.google.com/sdk/gcloud/reference/agent-registry/services/list) (`--location` required), [services describe](https://docs.cloud.google.com/sdk/gcloud/reference/agent-registry/services/describe).
- [Use an Agent Development Kit agent](https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/use-an-adk-agent) (updated 2026-09-15): `POST https://LOCATION-aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/LOCATION/reasoningEngines/RESOURCE_ID:query` and `:streamQuery` (PW-5.4a's `Assumption:` on the interface URL).
- Cited through the full set and **not re-read today** (their files read them on 2026-09-15): `gcloud projects create`, `billing projects link`, `resource-manager tags bindings create`, `alpha resource-manager liens create` ([setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md)); `bq mk`, `bq update --source`, `tables.testIamPermissions`, `gcloud iam roles create` ([setup/31](../setup/31-wall-e-project-and-data-plane.md)); regional `gcloud secrets` ([setup/31](../setup/31-wall-e-project-and-data-plane.md) WD-6); Google Auth Platform pages and `roles/oauthconfig.editor` ([setup/32](../setup/32-wall-e-consents.md)); `gcloud auth print-identity-token --impersonate-service-account --audiences` ([setup/33](../setup/33-wall-e-action-services-and-approval-surfaces.md)); `network-services agent-gateways import`, `beta service-extensions authz-extensions import`, `network-security authz-policies import`, Model Armor template flags and the PF block ([setup/34](../setup/34-wall-e-identity-spike-and-model-armor.md), [18](../setup/18-model-armor-floor-spikes-and-kill-switch.md)); engine create and lock ([setup/35](../setup/35-wall-e-engine-registration-and-gateways.md)); activity rules and 2SV paths ([setup/30](../setup/30-wall-e-workspace-side.md)).

## Unverified on 2026-09-16, and what closes each

| Item | Why it matters | Closes when |
|---|---|---|
| Whether an OU-scoped **Move users** privilege lets the robot move an account out of `PILOT_OU` into an OU outside its scope, or only between OUs in scope | Pilot Writer's Move could otherwise carry an account out of the pilot | PW-7.5's refusal test on a synthetic account, recorded; if a move out succeeds, Move is removed from Pilot Writer by a superseding PV-07 |
| Whether an `ORG_UNIT`-scoped Users Read still returns any field of an account outside `PILOT_OU` (for example through `users.list` without an OU query) | Tier P read reach stays inside the synthetic population | PW-7.5: the robot's token reads `users.get` on one non-pilot account and must be refused; a success stops §7 and is reported to the DPO |
| The register schema's `privilege` field holds **one** `workspace_role:<name>`; the Tier P agent holds two assignments | The row under-describes the reader role | [04](04-the-contract-register-agent-ids-and-schemas.md) amends the schema (array, or a manifest field) by a superseding record; until then the reader role is in the manifest and PV-07 |
| The maximum lifetime of a Google access token: Google's page gives `expires_in` per response (example 3920 s), not a fixed maximum; the design's "up to 60 minutes" is the design's figure | K4's residue statement | PW-6.5 measures it and records the measured value |
| Whether a robot without an admin role can manage membership of groups it manages through the API, which the `Assumption:` about the six operations relies on | PB-04's catalogue at Tier W | PB-04's author proves one add and its inverse in nonprod-shaped data before PV-01's catalogue values are signed; otherwise PV-01 picks other owned-resource operations |
| Whether the Tier W standard requires a CMEK key on the doer's engine (no key under `KR_ENGINES` is created here) | Key names are irreversible | [04](04-the-contract-register-agent-ids-and-schemas.md)'s tier table; if yes, a key is created under the KEYS record before PW-5.4 |
| The `gcloud firestore backups list` scoping by `--project` together with `--location` (the page's example omits `--project`) | PW-2.8 | The first run; `--project` is a global flag |
| `confirm_manual` returns only an exit status; this file reads the typed identifier back from the last line of `confirmations.tsv` (field 5, as [01](01-conventions-and-variables.md) PP-1.3's definition writes it) | PW-2.1 and PW-2.4 compare it with the NAMES value | Settled against 01's definition (exactly two arguments, STEP_ID and QUESTION); re-check if 01 changes the column order |
| The tag value short name `w` and `p` under `agp-tier` | PW-2.1 and PW-7.2 bindings | [03](03-foundation-folders-logging-and-floors.md)'s tag record |
| The interface URL and protocol binding under which an Agent Runtime engine is registered cross-project (Google documents the engine's `:query` URL and `http-json` as a binding, but shows no Agent Runtime engine registered by hand; setup/20 §9 carries the same gap) | PW-5.4a's entry could point at a URL no registry client or gateway resolves | The first consumer that resolves the entry (a gateway dry-run log, setup/35 WE-9.5's shape, in the full build); until then the entry is an inventory record keyed on `agent_id`, not a routing target |
| Whether automatic registration needs `agentregistry.googleapis.com` enabled in the agent's own project (the setup page says the registry operates "within the specific project where the API is enabled"; the automatic-registration page names no prerequisite) | Whether a second, automatic entry for the doer can exist in `DOER_PROJECT` | PW-5.4a records that the API is off in `DOER_PROJECT`; if it is ever enabled, the drift read compares both entries |
| The allowed characters of a registry service id, the form of the output-only `registryResource`, whether `services list` returns the project id or number in `name`, and whether `services delete` prompts | PW-5.4a's id `<agent_id>-engine`, its VERIFY comparisons and its ROLLBACK | The first run: the create's error names the rule; the VERIFY compares on the `/services/<id>` suffix; the delete never carries `--quiet` |
| The field of `gcloud pam grants describe` that names the approver, and that `gcloud pam grants` calls on the folder-scoped `ENT_PROJECT_REPAIR_CORE` need `--billing-project` (copied from [03](03-foundation-folders-logging-and-floors.md) PF-5.2) | PW-5.4a's proof that the second person, not person 1, approved | The second person reads the saved grant JSON and signs; no field name is asserted |
