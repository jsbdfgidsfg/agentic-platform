# POV 04. The contract: register rows, `agent_id` as the join key, `audit.schema` and `ladder.schema`

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-17
- Last executed: never
- Stage: POV-1, week 2 (after [03](03-foundation-folders-logging-and-floors.md), before [05](05-gemini-enterprise-and-tier-c.md)). Hands-on about 2 days; elapsed about 4 days (reviews, the two-signer parse, and the two reviewed pull requests of the template and the checker). `Assumption:` both figures.
- Step prefix: `PC`, never `PR`, which is setup/01's prefix in the same `checkpoints.tsv` (README §6.2); a bare `PR-` id in this file is setup/01's, never this file's. Checkpoint lines are written from this file like every other, under file 01's convention: each step writes `checkpoint <id> START` before its ACTION and `checkpoint <id> DONE` after its VERIFY passes. The irreversible merges (the contract in PC-2.3, the register rows in PC-3.5, the Tier R record in PC-4.3) carry both lines inside their blocks, with the second person as witness, so a resumed sitting knows whether the merge happened. File 01 PP-1.5's prefix refusal must print `prefix refusal clean` before the first of them. Steps: 24 (PC-4.2a to PC-4.2d, the run-spec template and the zero-diff checker of setup/17 FM-1.1 to FM-1.4, are lettered so that no existing id moves). BLOCKED: PC-2.4 (PB-01, eight of the doer's nine audit tables), PC-2.6 (PB-02, Eve's three schemas), PC-1.4's code half (B-03, replaced by the signed manual parse, [PV-D-13](09-the-demonstration-deviations-and-the-hand-over.md)). May record `PENDING`: PC-4.2d's register-fixture run, on the one check of the unchanged checker that cannot pass on a project naming services Google's constraint does not govern (PC-4.2d).
- Full-set counterpart: [setup/16](../setup/16-register-and-shared-registry.md) (register, schemas, rules, registry), the schema halves of [setup/22](../setup/22-mo-foundations.md) (MO-1.1, MO-1.3, MO-6.3, MO-8.1), [setup/23](../setup/23-eve-project-and-evidence-stores.md) (EP-1.1, EP-1.3) and [setup/31](../setup/31-wall-e-project-and-data-plane.md) (WD-1.1, WD-1.3, WD-4.5), the run-spec template and zero-diff checker of [setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md) §1 (FM-1.1 to FM-1.4, run unchanged), and the Tier R record of setup/17 §10.
- Applies decisions: PV-01, PV-02, PV-03 (with NAMES), PV-09, PV-11, PV-12; full-set SD-02, SD-09, SD-36, SD-48 inherited unchanged.

## What this part builds

This is the file that makes the POV scale. The design's thesis is that "a read-only assistant
costs a register row and a factory run" ([../01-hld.md](../01-hld.md) lines 90 to 92). That is
only true if `agent_id`, the register row, `audit.schema` and `ladder.schema` are right for the
first agent, because every later table, metric, ladder file, factory run spec
(`factory/runs/<agent_id>-<env>.json`) and Mo bundle (`mo-bundle-<agent_id>-<YYYY-Www>.json`) is
keyed on them ([../05-registry-and-autonomy-contract.md](../05-registry-and-autonomy-contract.md) §9.1, §9.3, §9.4).

1. **The register schemas, exactly as the full build has them.** setup/16 RG-1 and RG-2 run as
   written (no POV copy of the JSON), then one amendment pull request carries the three
   amendments the full set makes later anyway: the improver tier `IMP` (22 MO-1.1), the
   controller tier `CTL` (23 EP-1.1, with the `owner_group` pattern corrected to 22's value), and
   the family-id widening plus rule R-13 (31 WD-1.1). Nothing is invented: the POV only runs them
   earlier.
2. **The rule table `ci/register-rules.md`** (R-01 to R-13), committed as specification. Its code
   is B-03 and does not exist; the signed two-person manual parse of setup/16 RG-3.6 is the control
   in force ([PV-D-13](09-the-demonstration-deviations-and-the-hand-over.md)).
3. **`contract/1.0.0/audit.schema.json` and `contract/1.0.0/ladder.schema.json`**, at the paths
   05 §9.1 names. The full set names these files and never writes them; the POV writes them once,
   so the full build inherits them. `audit.schema` carries every contract column of 05 §9.4 from
   the first row, including `ws_insert_ids`, `tainted`, `halt_epoch`, the `fp_*` tuple and
   `approver_surrogates`: a column contract is free to create empty and expensive to retrofit once
   Eve's and Mo's SQL is written against it. `ladder.schema` fixes the `SUPER` and `WRITE_GENERIC`
   rows as a constant no agent can edit.
4. **Table definitions, committed here and applied where the project is made**: the doer's
   `actions` table (fully specified by 05 §9.4) and the list of nine tables, with the other eight
   BLOCKED on PB-01; Mo's four dataset definitions and the two toil-baseline table schemas of
   22 MO-8.1. A dataset cannot exist before its project, so file [07](07-the-doer-tier-w-and-the-optional-tier-p.md) applies the doer's and file
   [08](08-mo-and-the-value-report.md) applies Mo's.
5. **Four register rows, each before any project exists**: the doer's `env=prod` and `env=nonprod`
   rows at Tier W (nonprod is mandatory from Tier W, [../02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §3.5),
   Eve's `env=prod` row at `CTL`, Mo's `env=prod` row at `IMP`, with their manifests.
6. **The reservation** of `walle`, `WALLE_PROJECT`, `walle_audit`, `EVE_WITNESS_PROJECT` and the
   contents of `fld-agents-p-sa-prod` and `fld-agents-p-sa-nonprod`, as a committed file naming the
   setup file that will create each ([PV-D-08](09-the-demonstration-deviations-and-the-hand-over.md), PV-02).
7. **`AGENT_REGISTRY`** recorded in `CORE_PROJECT` and **`POV_TIER_R_RECORD`** written. It is a POV-grade record and never sets the full set's `TIER_R_RECORD`, which setup/17 FM-10.3 produces, so no POV record satisfies the `need TIER_R_RECORD` of setup/22, 23 or 31 (README §7.3).
8. **The run-spec template and the zero-diff checker**, before any agent project exists: `factory/runs/_template.json` (setup/17 FM-1.1) and `tools/fm-zero-diff.py` (FM-1.2), both extracted from setup/17 byte for byte and merged by two reviewers; a platform-core run spec for `CICD_PROJECT` (FM-1.3); and the checker's proof (FM-1.4): the register fixture, zero difference on `CICD_PROJECT`, and a deliberate difference. The factory does not exist ([PV-D-01](09-the-demonstration-deviations-and-the-hand-over.md)), so files [06](06-eve-over-the-human-super-admins.md), [07](07-the-doer-tier-w-and-the-optional-tier-p.md) and [08](08-mo-and-the-value-report.md) build their agent projects by hand; each writes `factory/runs/<agent_id>-<env>.json` from this template and merges it **before** its project exists, then runs `fm-zero-diff.py live` against the project. That is what lets the full build import the hand-built projects: the factory's module equivalents read the same template and the same checker, and the full build's FM-1.1 and FM-1.2 become reads of files already merged. The checker is never edited in the POV.

What the schema says about tier and privilege, quoted from setup/16 RG-2.2's
`register-row.schema.json` (lines 326 to 339 of that file), because it decides what the POV may
call each agent:

| Schema clause (verbatim) | Consequence for the POV |
|---|---|
| `{"if": {"properties": {"tier": {"enum": ["C", "R"]}}}, "then": {"properties": {"verifier": {"const": "none"}, "metric_pack": {"const": "light"}, "privilege": {"const": "none"}, "risk_class": {"const": "READ"}}}}` | Tier C and R rows (file 05) hold no privilege and only read |
| `{"if": {"properties": {"tier": {"const": "W"}}}, "then": {"properties": {"verifier": {"const": "platform-verifier"}, "metric_pack": {"const": "full"}, "privilege": {"const": "none"}}}}` | **The doer at Tier W holds no Workspace admin role.** Any admin role makes it a Tier P row |
| `{"if": {"properties": {"tier": {"const": "P"}}}, "then": {"properties": {"privilege": {"pattern": "^(none\|workspace_role:[a-z_]+)$"}}}}` with `{"if": {"properties": {"tier": {"enum": ["P", "P-SA"]}}}, "then": {"properties": {"verifier": {"const": "eve"}, ...}}}` | The optional delegated-role step of file 07 is a **new** Tier P row, a new `agent_id` and a new project, with Eve as verifier |
| `{"if": {"properties": {"tier": {"const": "P-SA"}, "env": {"const": "prod"}}, ...}, "then": {"required": ["gate_checklist"], "properties": {"privilege": {"enum": ["super_admin_pending", "super_admin"]}}}}` | Nothing in the POV is P-SA; the name `walle` is reserved for the row setup/31 WD-1.3 writes |

**The POV labels a row by what the schema allows and never relabels a row to escape a rule**
(PV-01). A row the schema refuses is a design question for a decision record, not a value to edit.

## Preconditions

- [ ] File [01](01-conventions-and-variables.md): `PLATFORM_ENV_FILE`, `PLATFORM_REPO_DIR`, `PLATFORM_REPO_REMOTE`, `BUILD_LOG_DIR`, `EVIDENCE_REGISTER`, `DEVIATION_REGISTER`, `REGION` (`europe-west1`), `BQ_LOCATION` (`EU`), `RETIRED_NAMES_CHECK`; plus `WIKI_DIR` (01 PP-1.4's `penv_set`). `DOMAIN` comes from file 03 PF-1.1. `GIT_HOST` is not a variable this file reads: it is a Values row of the setup/03 DC-4.3 record that file 02 signs unchanged, read with `decision-value.sh` where a step needs it. The three decision tools are merged. `PLATFORM_REPO_SLUG` set once by 01 PP-5.1 from `GIT_ORG` and PV-03's name; this file only reads it. 01 PP-1.5 printed `prefix refusal clean` (README §6.2; this file's prefix is `PC`).
- [ ] File [02](02-decisions-people-and-the-retrospective-baseline.md): PV-01, PV-02, PV-03 (with the signed `NAMES` and `KEYS` records), PV-09, PV-11 and PV-12 signed; `AGENT_ID_DOER`, `AGENT_ID_EVE`, `AGENT_ID_MO`, `RESERVED_NAMES_RECORD`, `MODEL_ID`, `SECOND_HUMAN_EMAIL`, `SECURITY_REVIEWER_EMAIL`, `BLIND_GRADER_EMAIL` set. **Values this file reads from those records** (Assumption: file 02's Values tables carry these rows; if not, the `need` guard stops the step and file 02 adds them by a superseding record): PV-11 `AI_ACT_CLASS_DOER`, `PURPOSE_SHA256_DOER`, `PURPOSE_SHA256_EVE`, `PURPOSE_SHA256_MO`; PV-09 `VERIFIER_OWNER_GROUP` (the group that owns the platform verifier's recomputation while none is deployed); NAMES `DOER_PROJECT`, `DOER_NONPROD_PROJECT`, `DOER_AUDIT_DS`, `EVE_PROJECT`, `MO_PROJECT`.
- [ ] File [03](03-foundation-folders-logging-and-floors.md): `ORG_ID`, `DIRECTORY_CUSTOMER_ID` (the full-set name; README §7.2), `CORE_PROJECT`, `LOGGING_PROJECT`, `FLD_AGENTIC_PLATFORM`, `FLD_AGENTS_W_PROD`, `FLD_AGENTS_W_NONPROD`, `FLD_CONTROLLERS_PROD`, `FLD_IMPROVERS_PROD`, `FLD_AGENTS_P_SA_PROD` and `FLD_AGENTS_P_SA_NONPROD` (PF-3.1), `NOTIF_CH_EMAIL_CORE`, `PAM_ENTITLEMENTS` (PF-5.1, a path relative to `PLATFORM_REPO_DIR`), `GATES_DIR` (PF-10.1). Three further preconditions that file 03 produces only through the full-set steps it runs, each checked by a command in PC-0.1 or PC-4.1 that stops this file when it is absent, never assumed:
  - `register/folders.yaml` merged: file 03 PF-3.1a runs setup/09 FS-4.1 and FS-4.2 unchanged.
  - `agentregistry.googleapis.com` enabled on `CORE_PROJECT`. File 03 PF-4.1 runs setup/10 CP-1.1 to CP-1.10 per row with exactly the row's APIs, and setup/10 enables this API; PC-0.1 reads the enabled service rather than trusting that.
  - An entitlement carrying `roles/agentregistry.admin`: setup/12's `ent-project-repair-core` carries it, and file 03 PF-5.1's subset sets `ENT_PROJECT_REPAIR_CORE`. PC-4.1 reads the catalogue; without it file 05 registers nothing.
- [ ] For PC-4.2a to PC-4.2d, from file 03: `CICD_PROJECT` built by PF-4.1 (setup/10 CP-1.1 to CP-1.10) with its records; `SA_FACTORY_APPLY` (PF-4.2); `FLD_PLATFORM_CORE`, `GRP_PLATFORM_OWNERS`, `GRP_PLATFORM_SECURITY`, `BILLING_ACCOUNT_ID`, `BOOTSTRAP_BILLING_EXPIRY`; **PF-10.3 `DONE`**, so the creator's Owner is gone from `CICD_PROJECT` and FM-1.4's live proof can read an IAM policy with no human member. From PC-1.1: setup/16 RG-2.1's PyYAML interpreter (`~/platform/venv-register/bin/python`, or `REGISTER_VENV_PYTHON`), which the checker reads register files with. From file 01: `tools/pov-lib.sh` with `pov_extract` (PP-1.3). The register-fixture half of PC-4.2d reads `fld-platform-core`'s **enforced** allow-list, which file 03 PF-5.3 leaves in dry run for 14 days; PC-4.2d says what that half records before 03's dated enforcement line is `DONE`.
- [ ] **Person 3 is named** as security reviewer, and was appointed **before file 01 Part B** (README §5.1a): 01 PP-5.1 runs `need` on `SECOND_OPERATOR_EMAIL`, and the protected repository needs two human reviewers who are not the author, so person 3 exists before any pull request of this file is opened. PC-0.1's `need SECURITY_REVIEWER_EMAIL BLIND_GRADER_EMAIL` stops the sitting otherwise; nothing here defers the appointment to POV-2. setup/16 RG-3.6 requires the security reviewer *and* the second person on any pull request touching `contract/`, so this file cannot merge PC-2.3 without person 3.
- [ ] Workstation: `gh` signed in as a repository administrator; `pipx`, `jq`, `python3.12`.

## People

| Role | Does | Present at |
|---|---|---|
| Platform owner (person 1) | Writes every file; opens every pull request; never approves or parses their own | all |
| Second person (person 2, `SECOND_HUMAN_EMAIL`) | Code owner of `/identity/`; co-signs every manual parse; one of two human reviewers, including of the template and the checker | PC-1.1, PC-1.2, PC-2.3, PC-3.5, PC-4.2a, PC-4.2b, PC-4.3 |
| Security reviewer (person 3, `SECURITY_REVIEWER_EMAIL`) | Code owner of `/register/schema/`, `/contract/`, `/ci/`; co-signs the parse of every contract or schema change; the security reviewer among the checker's two approvers (setup/17 FM-1.2); reads the checker's four proof reports, which the platform owner does not verify alone | PC-1.2, PC-1.4, PC-2.3, PC-3.5, PC-4.2a, PC-4.2b, PC-4.2d |
| Billing administrator (`BILLING_ADMIN_EMAIL`) | Performs PC-4.2c's budget repair on `CICD_PROJECT`, if one is needed, once `BOOTSTRAP_BILLING_EXPIRY` has passed | PC-4.2c (only in that case) |
| Mo owner | Writes Mo's row and manifest (Assumption: PV-09 names the platform owner as Mo owner in the POV; if so, person 2 and person 3 review) | PC-2.5, PC-3.4 |

Separation: nobody approves their own pull request; no service account, bot or Mo identity counts as
an approver (setup/16 R-08, R-10; SD-48). Conventions of file 01 apply: `checkpoint <id> START|DONE`,
`evidence_add`, records `<date>-<step>-<slug>-v<n>` under `$BUILD_LOG_DIR/records/`.

## 0. The sitting

### PC-0.1 Open the sitting and check every gate

- **Id:** PC-0.1
- **WHO:** Platform owner.
- **WHERE:** Shell, `~/.platform-env` sourced.
- **ACTION:**

```bash
source ~/.platform-env
penv_guard
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-01 PV-02 PV-03 PV-09 PV-11 PV-12 NAMES
need PLATFORM_REPO_DIR PLATFORM_REPO_REMOTE BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER WIKI_DIR DOMAIN ORG_ID REGION BQ_LOCATION
need AGENT_ID_DOER AGENT_ID_EVE AGENT_ID_MO RESERVED_NAMES_RECORD MODEL_ID SECOND_HUMAN_EMAIL SECURITY_REVIEWER_EMAIL BLIND_GRADER_EMAIL
need CORE_PROJECT LOGGING_PROJECT FLD_AGENTIC_PLATFORM FLD_AGENTS_W_PROD FLD_AGENTS_W_NONPROD FLD_CONTROLLERS_PROD FLD_IMPROVERS_PROD FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD DIRECTORY_CUSTOMER_ID PAM_ENTITLEMENTS GATES_DIR
need PLATFORM_REPO_SLUG
checkpoint PC-0.1 START - - "sitting opened; gates read"
printf '%s\n' "$AGENT_ID_DOER" "$AGENT_ID_EVE" "$AGENT_ID_MO" | grep -Evx '[a-z][a-z0-9-]{1,30}' && echo "STOP: an agent_id breaks the pattern" || echo "agent_id pattern ok"
# names-check: off PV-02
case "$AGENT_ID_DOER" in walle|wall-e|eve|mo) echo "STOP: the doer may not take a reserved or controller id (PV-02)";; *) echo "doer id not reserved";; esac
# names-check: on
test "$AGENT_ID_EVE" = eve && test "$AGENT_ID_MO" = mo && echo "eve and mo ids are the full set's"
test "$REGION" = europe-west1 && test "$BQ_LOCATION" = EU && echo "locations ok"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
test -s "$PLATFORM_REPO_DIR/register/folders.yaml" && echo "folders.yaml present" || echo "STOP: register/folders.yaml is not merged (run file 03 PF-3.1a)"
test "$(gcloud services list --enabled --project="$CORE_PROJECT" --filter="config.name=agentregistry.googleapis.com" --format="value(config.name)")" = agentregistry.googleapis.com && echo "agent registry API enabled" || echo "STOP: agentregistry.googleapis.com is not enabled on CORE_PROJECT (file 03 PF-4.1, setup/10)"
git -C "$WIKI_DIR" rev-parse HEAD | tee "$BUILD_LOG_DIR/records/$(date -u +%F)-PC-0.1-wiki-commit-v1.txt"
```

  Only when no `STOP` line printed: `checkpoint PC-0.1 DONE - "build-log:records/$(date -u +%F)-PC-0.1-wiki-commit-v1.txt" "gates read"`. `PLATFORM_REPO_SLUG` is read, never set here: 01 PP-5.1 set it from `GIT_ORG` and PV-03's name, `penv_set` writes once, and a slug re-derived from the remote URL breaks on an SSH or non-GitHub remote (setup/03 §12).
- **VERIFY:** `penv_guard` prints nothing; `decision-need.sh` exits 0; every `need` is silent; the six lines `agent_id pattern ok`, `doer id not reserved`, `eve and mo ids are the full set's`, `locations ok`, `folders.yaml present`, `agent registry API enabled` all print, and no `STOP` line prints. Any `STOP` ends the sitting before a pull request is opened. The wiki commit is recorded because PC-1.1 and PC-1.2 copy procedure text from that commit.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Output as `<date>-PC-0.1-gates-v1` in `$BUILD_LOG_DIR/records/`; `evidence_add PC-0.1 gates E-05 5.2.1 build-log:records/<file> <file>`. E-05. TISAX 5.2.1.

## 1. The register schemas and rules

### PC-1.1 Run setup/16 RG-1.1 to RG-2.6 as written

- **Id:** PC-1.1
- **WHO:** Platform owner; person 2 approves as code owner of `/identity/` and `/.github/`; person 3 approves `/register/schema/` and `/contract/` (RG-2.6).
- **WHERE:** Shell and the git host, as setup/16 names.
- **ACTION:** Execute [setup/16](../setup/16-register-and-shared-registry.md) RG-1.1, RG-1.2, RG-1.3, RG-1.4, RG-2.1, RG-2.2, RG-2.3, RG-2.4, RG-2.5 and RG-2.6 **unchanged**, at the wiki commit recorded in PC-0.1. They install `check-jsonschema` 0.38.0 (version re-read on PyPI 2026-09-16), write `register/schema/register-row.schema.json`, `contract/1.0.0/manifest.schema.json`, the folders, operators and models schemas, `register/models.yaml`, the 18 fixtures, and set `REGISTER_PATH` and `MANIFEST_SCHEMA_PATH`. Three substitutions only, each because the POV's people differ ([PV-D-14](09-the-demonstration-deviations-and-the-hand-over.md)): "second human" reads person 2; "security reviewer" reads person 3 (so RG-1.2's `SR_LOGIN` is person 3's login, and BD-16-5 is not needed); RG-1.4's `humans[]` lists persons 1, 2 and 3 with their PV-09 appointment records. RG-2.4's `MODEL_ID` row is written from PV-12. Then record the one path setup/16 leaves implicit:

```bash
source ~/.platform-env
need REGISTER_PATH MANIFEST_SCHEMA_PATH
test -f "$PLATFORM_REPO_DIR/$REGISTER_PATH/schema/register-row.schema.json" && penv_set REGISTER_SCHEMA_PATH "$REGISTER_PATH/schema/register-row.schema.json"
```

- **VERIFY:** Every setup/16 VERIFY from RG-1.1 to RG-2.6 passes as written, in particular RG-2.5's run printing 18 lines, all `PASS-OK` or `FAIL-OK`; `need REGISTER_PATH REGISTER_SCHEMA_PATH MANIFEST_SCHEMA_PATH` is silent.
- **ROLLBACK:** As each setup/16 step states (reverting pull requests; `pipx uninstall`).
- **EVIDENCE:** setup/16's records under their own `RG-` names (they are the full build's evidence and are not renamed); `evidence_add PC-1.1 register-schemas E-05 1.3.1 repo:register/schema@<merge sha>`. E-05. TISAX 1.3.1, 1.3.2, 5.2.1.

### PC-1.2 One amendment pull request: `IMP`, `CTL`, family ids and R-13

- **Id:** PC-1.2
- **WHO:** Platform owner writes; person 3 approves as code owner; person 2 is the second human reviewer and co-signs the parse.
- **WHERE:** Shell, branch `pc-1-2-tier-amendments`, then the git host.
- **ACTION:** The full set amends the schemas three times (22 MO-1.1, 23 EP-1.1, 31 WD-1.1). The POV applies all three at once, so the full build's later steps find them merged and their own VERIFY lines pass. The `owner_group.not.pattern` value is `^platform-owners@`, the value both 22 MO-1.1 and 23 EP-1.1 set, so the two full-build steps and this one compose in any order.

```bash
source ~/.platform-env
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c pc-1-2-tier-amendments
S="$PLATFORM_REPO_DIR/register/schema/register-row.schema.json"
M="$PLATFORM_REPO_DIR/contract/1.0.0/manifest.schema.json"
jq '(.["$defs"].row.properties.tier.enum) |= ((. + ["IMP","CTL"]) | unique)
  | (.properties.agent_id.pattern) = "^[a-z][a-z0-9-]{1,30}$"
  | (.["$defs"].row.properties.owner_group.not.pattern) = "^platform-owners@"' "$S" > "$S.new" && mv "$S.new" "$S"
```

  The two `allOf` blocks are copied, not retyped: open 22 MO-1.1 and 23 EP-1.1 at the PC-0.1 wiki commit and append each `{"if":{"properties":{"tier":{"const":"IMP"}}...}` and `{"if":{"properties":{"tier":{"const":"CTL"}}...}` object to `.["$defs"].row.allOf` with the same `jq '(.["$defs"].row.allOf) += [ ... ]'` form those steps use. Write `contract/1.0.0/improver-manifest.schema.json` from 22 MO-1.1 and `contract/1.0.0/controller-manifest.schema.json` from 23 EP-1.1, verbatim. Apply 31 WD-1.1 item 1 (family ids `^F[0-9]+[a-z]?$` in `$M`) and item 2 (append R-13 to `ci/register-rules.md` in PC-1.4, not here). Add the five fixtures those steps name: `pass-imp-mo.yaml`, `fail-imp-with-gateway-tier-r.yaml`, `fail-owner-group-platform-owners.yaml`, `pass-ctl-eve.yaml`, `fail-ctl-with-model-pin.yaml`, plus two POV fixtures that prove the tier rule quoted above: `fail-tier-w-workspace-role.yaml` (setup/16's `pass-canary-r.yaml` parent changed to `tier: W` with every W field and `privilege: workspace_role:pilot_writer`) and `fail-tier-w-verifier-eve.yaml` (the same with `privilege: none`, `verifier: eve`).

```bash
jq -r '[.properties.agent_id.pattern, .["$defs"].row.properties.owner_group.not.pattern, (.["$defs"].row.properties.tier.enum|join(","))] | @tsv' "$S"
jq -r '.properties.families.items.properties.id.pattern' "$M"
for f in "$S" "$M" "$PLATFORM_REPO_DIR"/contract/1.0.0/improver-manifest.schema.json "$PLATFORM_REPO_DIR"/contract/1.0.0/controller-manifest.schema.json; do check-jsonschema --check-metaschema "$f"; done
git -C "$PLATFORM_REPO_DIR" add register/schema contract/1.0.0 register/fixtures/schema
git -C "$PLATFORM_REPO_DIR" commit -m "register: IMP (setup 22 MO-1.1), CTL (setup 23 EP-1.1, owner_group per 22), family ids (setup 31 WD-1.1); POV 04 PC-1.2"
git -C "$PLATFORM_REPO_DIR" push -u origin pc-1-2-tier-amendments
gh pr create --repo "$PLATFORM_REPO_SLUG" --head pc-1-2-tier-amendments --title "PC-1.2 tier amendments IMP, CTL, family ids" --body "Applies setup 22 MO-1.1, 23 EP-1.1 (owner_group corrected to 22's value), 31 WD-1.1 early. Parse: decisions/register-parses/"
```

  setup/16 RG-2.2 keeps `agent_id` and its pattern at the top level (`.properties.agent_id`), not under `$defs.row`, and 22 MO-1.1 writes and reads that same top-level path, which is the one validation reads.
- **VERIFY:** The first read prints `^[a-z][a-z0-9-]{1,30}$`, `^platform-owners@` and a tier list containing `C,CTL,IMP,P,P-SA,R,W,X`; the second prints `^F[0-9]+[a-z]?$`; four metaschema passes. setup/16 RG-2.5's loop, re-run with the count assertion raised to 21 register fixtures, prints `PASS-OK` for every `pass-*` and `FAIL-OK` for every `fail-*`, and no `WRONG`. Merged with person 3's code-owner approval and a parse file (PC-3.5's form) signed by persons 2 and 3.
- **ROLLBACK:** A reverting pull request before PC-3.2 merges; afterwards a superseding schema change.
- **EVIDENCE:** Merge commit and the fixture run as `<date>-PC-1.2-tier-amendments-v1`. E-05. TISAX 1.3.1, 5.2.1.

### PC-1.3 Reserve the full build's names

- **Id:** PC-1.3
- **WHO:** Platform owner writes; person 2 approves (code owner of `/identity/`); person 3 reviews.
- **WHERE:** Shell, branch `pc-1-3-reserved-names`, then the git host.
- **ACTION:** Project ids are never reusable, a dataset cannot be renamed, and a project never moves between tier folders ([../02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §1.5). The POV must therefore spend none of these names ([PV-D-08](09-the-demonstration-deviations-and-the-hand-over.md), PV-02). The reservation lives in a subdirectory, because setup/16 RG-3.6's reading aid treats every `register/*.yaml` as an agent file. This file and the one below are the only places the POV writes these names; file 01's `RETIRED_NAMES_CHECK` must allow-list `register/reserved/names.yaml` and this step's text (reported to file 01's owner).

```bash
source ~/.platform-env
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c pc-1-3-reserved-names
mkdir -p "$PLATFORM_REPO_DIR/register/reserved"
# names-check: off PV-02
cat > "$PLATFORM_REPO_DIR/register/reserved/names.yaml" <<'EOF'
# Names the POV reserves and never creates (POV 04 PC-1.3; PV-02; PV-D-08). Changed only by a superseding PV-02.
reserved:
  - {name: walle, kind: agent_id, created_by: "setup/31 WD-1.3 (register/walle.yaml, tier P-SA)"}
  - {name: WALLE_PROJECT, kind: project variable, created_by: "setup/31 WD-2.3 in fld-agents-p-sa-prod"}
  - {name: walle_audit, kind: dataset, created_by: "setup/31 WD-4.4"}
  - {name: EVE_WITNESS_PROJECT, kind: project variable, created_by: "setup/08 (witness organisation)"}
  - {name: "any project in fld-agents-p-sa-prod or fld-agents-p-sa-nonprod", kind: folder contents, created_by: "setup/31, setup/37"}
EOF
# names-check: on
git -C "$PLATFORM_REPO_DIR" add register/reserved/names.yaml
git -C "$PLATFORM_REPO_DIR" commit -m "register: reserved names (POV 04 PC-1.3, PV-02)"
git -C "$PLATFORM_REPO_DIR" push -u origin pc-1-3-reserved-names
gh pr create --repo "$PLATFORM_REPO_SLUG" --head pc-1-3-reserved-names --title "PC-1.3 reserve the full build's names" --body "PV-02. RESERVED_NAMES_RECORD: see body of the PV-02 record."
```

- **VERIFY:** After the merge: `grep -rlE '(^|[^a-z_])walle([^a-z_-]|$)|walle_audit|WALLE_PROJECT' "$PLATFORM_REPO_DIR/register" "$PLATFORM_REPO_DIR/factory" 2>/dev/null` lists only `register/reserved/names.yaml`; `need FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD` is silent, then `for f in "$FLD_AGENTS_P_SA_PROD" "$FLD_AGENTS_P_SA_NONPROD"; do gcloud projects list --filter="parent.type=folder AND parent.id=${f#folders/}" --format="value(projectId)"; done` prints nothing. The folder ids come from file 03 PF-3.1 and are used directly: `fld-agents-p-sa-prod` sits three levels below `fld-agentic-platform`, and a folder listing returns only the direct children of its parent (Resource Manager `folders.list`, read 2026-09-16), so a display-name lookup under `FLD_AGENTIC_PLATFORM` would find nothing and the empty project list would prove nothing. `parent.type` and `parent.id` are the project fields a parent filter reads (Resource Manager `projects.search`, read 2026-09-16). The five reserved lines match `RESERVED_NAMES_RECORD` word for word.
- **ROLLBACK:** A superseding PV-02 and a pull request; never a deletion while any POV step runs.
- **EVIDENCE:** Merge commit and the two reads as `<date>-PC-1.3-reserved-names-v1`. E-05. TISAX 1.3.1.

### PC-1.4 Commit the rule specification; its code stays BLOCKED

- **Id:** PC-1.4
- **WHO:** Platform owner writes; person 3 approves as code owner of `/ci/`; person 2 reviews.
- **WHERE:** Shell, branch `pc-1-4-rules`, then the git host.
- **ACTION:** Copy setup/16 RG-3.1's table of R-01 to R-12 verbatim into `ci/register-rules.md` and append 31 WD-1.1's R-13 row verbatim. setup/16 RG-3.2 (the 24 rule fixtures) is recorded PENDING: its only consumer is the B-03 code, which does not exist, and a fixture set nobody runs proves nothing. RG-3.3, RG-3.4, RG-3.5 and RG-9.2 are **BLOCKED** exactly as setup/16 writes them: **Needs:** the implementation of R-01 to R-13 (register CI, G1 to G21 parser, bot-approval and ladder-raise rules; README B-03). **Repository:** `PLATFORM_REPO_REMOTE`, `ci/register/`. **Gate that waits:** nothing in the POV; the manual parse of PC-3.5 stands in (SD-36, [PV-D-13](09-the-demonstration-deviations-and-the-hand-over.md)). **Estimate:** Assumption: not needed for the POV; the full set leaves B-03 unestimated.

```bash
source ~/.platform-env
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c pc-1-4-rules
mkdir -p "$PLATFORM_REPO_DIR/ci"
"${EDITOR:-vi}" "$PLATFORM_REPO_DIR/ci/register-rules.md"
grep -c '^| R-' "$PLATFORM_REPO_DIR/ci/register-rules.md"
git -C "$PLATFORM_REPO_DIR" add ci/register-rules.md
git -C "$PLATFORM_REPO_DIR" commit -m "ci: register rules R-01 to R-13 as specification; code B-03 BLOCKED (POV 04 PC-1.4)"
git -C "$PLATFORM_REPO_DIR" push -u origin pc-1-4-rules
printf '%s\tPC-1.4\tsetup/16 RG-3.2 rule fixtures\trun before B-03 code is merged\tPENDING\t-\n' "$(date -u +%F)" >> "$BUILD_LOG_DIR/rerun-index.tsv"
```

- **VERIFY:** The count prints `13`; `diff <(grep '^| R-' ci/register-rules.md | head -12) <(awk '/^### RG-3.1/,/^### RG-3.2/' "$WIKI_DIR/platform/agentic-platform/setup/16-register-and-shared-registry.md" | grep '^| R-')` prints nothing; the re-run line exists; merged with person 3's approval.
- **ROLLBACK:** A reverting pull request.
- **EVIDENCE:** Merge commit as `<date>-PC-1.4-rules-spec-v1`. E-05. TISAX 5.2.1, 1.4.1.

## 2. The contract files and the table definitions

### PC-2.1 Write `audit.schema.json`: every contract column from the first row

- **Id:** PC-2.1
- **WHO:** Platform owner writes; person 3 reviews in PC-2.3.
- **WHERE:** Shell, branch `pc-2-contract`.
- **ACTION:** One source of truth: a JSON Schema for one `actions` row whose property order and `x-bq-*` annotations generate the BigQuery table schema, so the row check and the table can never disagree. Columns, types and rules are 05 §9.4's table, one property per column, none omitted. **Reading of "the `p_` namespace"**: 05 §9.4 calls the contract-owned columns the `p_` namespace but lists them without a `p_` prefix, and denial reasons as `p:<reason>`; the POV keeps 05's column names exactly (renaming would break every design page) and enforces the other half of the rule, that an agent's own columns start with `a_`. `audit_unavailable` joins 05's denial vocabulary (absolute 8: no evidence, no action). `armor_findings` is a RECORD whose fields are Model Armor's response names (`filterMatchState`, `invocationResult`, `filterResults`, sanitize page read 2026-09-16). BigQuery column names allow letters, digits and underscores, up to 300 characters, none of the reserved prefixes (schemas page, read 2026-09-16).

```bash
source ~/.platform-env
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c pc-2-contract
mkdir -p "$PLATFORM_REPO_DIR/contract/1.0.0/fixtures/audit" "$PLATFORM_REPO_DIR/contract/1.0.0/fixtures/ladder"
cat > "$PLATFORM_REPO_DIR/contract/1.0.0/audit.schema.json" <<'JSON'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "audit/1.0.0",
  "title": "<agent_id>_audit on audit.schema (05 section 9.4). Insert-only; every table partitioned by DAY on ts; additive column changes only.",
  "x-contract-tables": ["actions", "runs", "plans", "approvals", "verifications", "config_versions", "ladder_events", "grades"],
  "x-partition": {"field": "ts", "type": "DAY"},
  "x-denial-vocabulary": ["p:level_off", "p:level_no_execute", "p:actor_not_authorised", "p:protected_principal", "p:hard_denied", "p:tainted_ceiling", "p:halted", "p:fingerprint_requalify", "p:profiling_boundary_denied", "p:disclosure_missing", "p:audit_unavailable"],
  "type": "object",
  "required": ["contract_version", "agent_id", "env", "ts", "principal_type", "decision"],
  "patternProperties": {"^a_[a-z0-9_]+$": {}},
  "additionalProperties": false,
  "properties": {
    "contract_version": {"type": "string", "pattern": "^1\\.[0-9]+\\.[0-9]+$", "x-bq-type": "STRING", "x-bq-mode": "REQUIRED"},
    "agent_id": {"type": "string", "pattern": "^[a-z][a-z0-9-]{1,30}$", "x-bq-type": "STRING", "x-bq-mode": "REQUIRED"},
    "env": {"enum": ["prod", "nonprod"], "x-bq-type": "STRING", "x-bq-mode": "REQUIRED"},
    "ts": {"type": "string", "format": "date-time", "x-bq-type": "TIMESTAMP", "x-bq-mode": "REQUIRED"},
    "run_id": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "invocation_id": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "trace_id": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "plan_id": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "principal_type": {"enum": ["human", "job", "event", "inbox", "agent", "eve", "breaker", "platform"], "x-bq-type": "STRING", "x-bq-mode": "REQUIRED"},
    "principal_surrogate": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "on_behalf_of_surrogate": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "trigger_class": {"enum": ["T0", "T1", "T2", "T3", null], "x-bq-type": "STRING"},
    "family": {"type": ["string", "null"], "pattern": "^F[0-9]+[a-z]?$", "x-bq-type": "STRING"},
    "operation": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "risk_tier": {"enum": ["READ", "WRITE_LOW", "WRITE_HIGH", "SUPER", "WRITE_GENERIC", null], "x-bq-type": "STRING"},
    "request_hash": {"type": ["string", "null"], "pattern": "^[0-9a-f]{64}$", "x-bq-type": "STRING"},
    "decision": {"enum": ["ok", "shadow", "proposal", "approval_required", "pending_eve", "denied", "drift", "skipped", "heartbeat"], "x-bq-type": "STRING", "x-bq-mode": "REQUIRED"},
    "denial_reason": {"type": ["string", "null"], "pattern": "^(p|a):[a-z_]+$", "x-bq-type": "STRING"},
    "level": {"enum": ["L0", "L1", "L2", "L3", "L4", "L5", null], "x-bq-type": "STRING"},
    "config_version": {"type": ["integer", "null"], "x-bq-type": "INT64"},
    "ceilings_sha": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "fp_prompt_sha256": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "fp_model_pin": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "fp_framework_version": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "fp_armor_template_version": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "pre_state_hash": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "post_state_hash": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "verification": {"enum": ["verified", "verified_partial", "drift", "not_verified", null], "x-bq-type": "STRING"},
    "approval_id": {"type": ["string", "null"], "x-bq-type": "STRING"},
    "approver_surrogates": {"type": "array", "items": {"type": "string"}, "x-bq-type": "STRING", "x-bq-mode": "REPEATED"},
    "tainted": {"type": ["boolean", "null"], "x-bq-type": "BOOL"},
    "halt_epoch": {"type": ["integer", "null"], "x-bq-type": "INT64"},
    "override_epoch": {"type": ["integer", "null"], "x-bq-type": "INT64"},
    "armor_findings": {"type": ["object", "null"], "x-bq-type": "RECORD",
      "x-bq-fields": [{"name": "filter_match_state", "type": "STRING"}, {"name": "invocation_result", "type": "STRING"}, {"name": "filter_results", "type": "JSON"}]},
    "ws_insert_ids": {"type": "array", "items": {"type": "string"}, "x-bq-type": "STRING", "x-bq-mode": "REPEATED"},
    "cost_micros": {"type": ["integer", "null"], "x-bq-type": "INT64"},
    "latency_ms": {"type": ["integer", "null"], "x-bq-type": "INT64"},
    "error_class": {"type": ["string", "null"], "x-bq-type": "STRING"}
  },
  "allOf": [
    {"if": {"properties": {"decision": {"const": "denied"}}}, "then": {"required": ["denial_reason"], "properties": {"denial_reason": {"type": "string"}}}},
    {"if": {"properties": {"principal_type": {"const": "agent"}}}, "then": {"required": ["trigger_class"]}}
  ]
}
JSON
jq '[.properties | to_entries[] | {name: .key, type: .value["x-bq-type"], mode: (.value["x-bq-mode"] // "NULLABLE")} + (if .value["x-bq-fields"] then {fields: .value["x-bq-fields"]} else {} end)]' "$PLATFORM_REPO_DIR/contract/1.0.0/audit.schema.json" > "$PLATFORM_REPO_DIR/contract/1.0.0/audit-actions.bq.json"
check-jsonschema --check-metaschema "$PLATFORM_REPO_DIR/contract/1.0.0/audit.schema.json"
jq 'length' "$PLATFORM_REPO_DIR/contract/1.0.0/audit-actions.bq.json"
```

  Three fixtures under `contract/1.0.0/fixtures/audit/`: `pass-heartbeat.json` (`decision: heartbeat`, no operation), `pass-denied-halted.json` (`decision: denied`, `denial_reason: p:halted`, `a_ticket: "x"`), `fail-unprefixed-extension.json` (the same with `ticket` instead of `a_ticket`).
- **VERIFY:** The metaschema check passes; the column count prints `38`; `jq -r '.[].name' audit-actions.bq.json` lists 05 §9.4's columns in its order (compare by eye against 05 lines 582 to 598, person 3 in PC-2.3); the three fixtures give `PASS-OK`, `PASS-OK`, `FAIL-OK` with setup/16 RG-2.5's loop form. **Assumption:** `check-jsonschema` ignores unknown `x-` keywords, as Draft 2020-12 permits unknown keywords as annotations; if it refuses them, stop and record it, do not strip them.
- **ROLLBACK:** Delete the uncommitted files.
- **EVIDENCE:** Through PC-2.3. E-06 (the Art. 12 log's shape). TISAX 5.2.4, 1.3.1.

### PC-2.2 Write `ladder.schema.json`, with the `SUPER` and `WRITE_GENERIC` rows fixed

- **Id:** PC-2.2
- **WHO:** Platform owner writes; person 3 reviews in PC-2.3.
- **WHERE:** Shell, branch `pc-2-contract`.
- **ACTION:** 05 §9.3's shape. Two statements that 05 §9.5 calls code are made a schema constant, `code_rows`, which every ladder file must carry byte for byte: `SUPER` is L3 two-person on chat and L0 on every other trigger and in the agent column, never in a playbook; `WRITE_GENERIC` is L3 on chat and L0 elsewhere. A ladder file cannot express a `SUPER` cell differently without failing the schema, whatever its author wants. No cell may exist for the `agent` trigger (05 §9.3 "code"). The POV's own cap at L3 is **not** written into the schema, which the full build uses up to L5; it lives in the doer's manifest ceilings (PC-3.2), as 31 WD-1.3 caps Wall-E's. `defaults` is an open object so file 07's `ou_allowlist` fits without a contract change.

```bash
cat > "$PLATFORM_REPO_DIR/contract/1.0.0/ladder.schema.json" <<'JSON'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "ladder/1.0.0",
  "title": "ladder.yaml on ladder.schema (05 sections 9.3 and 9.5). Humans raise by pull request; machines lower through POST /v1/ladder/lower; no raise API.",
  "type": "object",
  "required": ["contract_version", "agent_id", "config_version", "ceilings_sha", "cells", "overrides", "code_rows"],
  "additionalProperties": false,
  "properties": {
    "contract_version": {"type": "string", "pattern": "^1\\.[0-9]+\\.[0-9]+$"},
    "agent_id": {"type": "string", "pattern": "^[a-z][a-z0-9-]{1,30}$"},
    "config_version": {"type": "integer", "minimum": 1},
    "ceilings_sha": {"type": "string", "pattern": "^[0-9a-f]{64}$"},
    "defaults": {"type": "object"},
    "cells": {"type": "array", "items": {"type": "object", "required": ["family", "trigger", "level"], "additionalProperties": false,
      "properties": {
        "family": {"type": "string", "pattern": "^F[0-9]+[a-z]?$"},
        "trigger": {"enum": ["T0", "T1", "T2", "T3"]},
        "level": {"enum": ["L0", "L1", "L2", "L3", "L4", "L5"]},
        "hold_minutes": {"type": ["integer", "null"], "minimum": 0},
        "notify": {"type": "string", "pattern": "^[a-z_]+$"}}}},
    "overrides": {"type": "array", "items": {"type": "object"}},
    "decision_record": {"type": ["string", "null"], "pattern": "^decisions/"},
    "evidence": {"type": ["object", "null"], "required": ["graded_items", "wilson_lower_95", "window", "dwell_days_at_previous_level"],
      "properties": {
        "graded_items": {"type": "integer", "minimum": 0},
        "wilson_lower_95": {"type": "number", "minimum": 0, "maximum": 1},
        "window": {"type": "object", "required": ["from", "to"], "properties": {"from": {"type": "string", "format": "date"}, "to": {"type": "string", "format": "date"}}},
        "dwell_days_at_previous_level": {"type": "integer", "minimum": 0}}},
    "code_rows": {"const": [
      {"risk_tier": "SUPER", "T0": "L3", "T0_two_person": true, "T1": "L0", "T2": "L0", "T3": "L0", "agent": "L0", "in_playbook": false},
      {"risk_tier": "WRITE_GENERIC", "T0": "L3", "T1": "L0", "T2": "L0", "T3": "L0", "agent": "L0"}
    ]}
  }
}
JSON
check-jsonschema --check-metaschema "$PLATFORM_REPO_DIR/contract/1.0.0/ladder.schema.json"
```

  Four fixtures under `contract/1.0.0/fixtures/ladder/`: `pass-05-9-3-example.yaml` (05 §9.3's example verbatim plus the `code_rows` block, with its `ceilings_sha: "…"` placeholder replaced by 64 hexadecimal zeros), `fail-agent-trigger-cell.yaml` (a cell with `trigger: agent`), `fail-code-row-edited.yaml` (the `SUPER` row with `T1: L3`), and `fail-ceilings-sha-placeholder.yaml` (the pass fixture with `ceilings_sha: "…"`). The schema accepts no placeholder hash: a ladder file with no compiled ceiling artefact behind it is refused by the schema itself, not left for R-13's check at `status: prod`, because the contract holds for every later agent.
- **VERIFY:** Metaschema passes; the fixtures give `PASS-OK`, `FAIL-OK`, `FAIL-OK`, `FAIL-OK`, and each failure message names the field the fixture changed.
- **ROLLBACK:** Delete the uncommitted file.
- **EVIDENCE:** Through PC-2.3. E-08 (humans raise, machines lower). TISAX 5.2.1.

### PC-2.3 Merge the contract; record `AUDIT_SCHEMA_COMMIT` and `LADDER_SCHEMA_COMMIT`

- **Id:** PC-2.3
- **WHO:** Platform owner opens; person 3 approves as code owner of `/contract/`; person 2 reviews; persons 2 and 3 sign the parse (setup/16 RG-3.6: a `contract/` change needs both).
- **WHERE:** Shell, then the git host.
- **ACTION:**

```bash
source ~/.platform-env
need SECOND_HUMAN_EMAIL PLATFORM_REPO_SLUG
checkpoint PC-2.3 START "$SECOND_HUMAN_EMAIL" - "irreversible once a table exists: contract 1.0.0 pull request opened"
git -C "$PLATFORM_REPO_DIR" add contract/1.0.0/audit.schema.json contract/1.0.0/audit-actions.bq.json contract/1.0.0/ladder.schema.json contract/1.0.0/fixtures
git -C "$PLATFORM_REPO_DIR" commit -m "contract 1.0.0: audit.schema and ladder.schema, keyed on agent_id (05 sections 9.3, 9.4; POV 04 PC-2.1, PC-2.2)"
git -C "$PLATFORM_REPO_DIR" push -u origin pc-2-contract
gh pr create --repo "$PLATFORM_REPO_SLUG" --head pc-2-contract --title "PC-2 contract 1.0.0: audit.schema, ladder.schema" --body "Reviewer checks: every 05 9.4 column present; code_rows equal 05 9.5; no POV cap in the schema. Parse file in decisions/register-parses/."
```

  After the merge:

```bash
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
C="$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%H -- contract/1.0.0/audit.schema.json)" && penv_set AUDIT_SCHEMA_COMMIT "$C"
C="$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%H -- contract/1.0.0/ladder.schema.json)" && penv_set LADDER_SCHEMA_COMMIT "$C"
need AUDIT_SCHEMA_COMMIT LADDER_SCHEMA_COMMIT && checkpoint PC-2.3 DONE "$SECOND_HUMAN_EMAIL" "repo:contract/1.0.0@$AUDIT_SCHEMA_COMMIT" "contract 1.0.0 merged"
```

- **VERIFY:** `need AUDIT_SCHEMA_COMMIT LADDER_SCHEMA_COMMIT` is silent and both are 40-character shas on `origin/main`; the pull request shows two human approvals, one of them person 3; the parse file exists and `tools/decision-check.sh` prints `OK` for it.
- **ROLLBACK:** Before any table is created from it: a reverting pull request and `penv_set --force` with a build-log line. After file 07 creates a table: **additive changes only**, as a new minor version; a column is never dropped (05 §9.1), even though BigQuery would allow it (schemas page, read 2026-09-16).
- **EVIDENCE:** Merge commit and parse as `<date>-PC-2.3-contract-merge-v1`; `evidence_add PC-2.3 contract-1-0-0 E-05 5.2.1 repo:contract/1.0.0@<sha>`. E-05, E-06. TISAX 5.2.1, 5.2.4.

### PC-2.4 The doer's nine audit tables: `actions` committed, eight **BLOCKED** (PB-01)

- **Id:** PC-2.4
- **WHO:** Platform owner writes; the second operator (person 3) reviews, as setup/31 WD-4.5 names.
- **WHERE:** Shell, branch `pc-2-4-doer-tables`, then the git host.
- **ACTION:** setup/31 WD-4.5 creates nine tables for Wall-E from nine committed schema files and one committed list; the POV does the same for the doer, in the platform repository beside Mo's `mo/schemas/` (22 MO-5.1's layout), so file 07 applies them unchanged. `actions` is fully specified by the contract and is written now. The list names the eight contract tables plus the band-B extension `generic_requests` ([../../wall-e/03-lld.md](../../wall-e/03-lld.md) "Storage"), because the doer's band-B lane exists at L0 (file 07).

```bash
source ~/.platform-env
need AGENT_ID_DOER AUDIT_SCHEMA_COMMIT
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c pc-2-4-doer-tables
D="$PLATFORM_REPO_DIR/$AGENT_ID_DOER"
mkdir -p "$D/schemas"
printf '%s\n' actions runs plans approvals verifications config_versions ladder_events grades generic_requests > "$D/AUDIT_TABLES"
cp "$PLATFORM_REPO_DIR/contract/1.0.0/audit-actions.bq.json" "$D/schemas/actions.json"
git -C "$PLATFORM_REPO_DIR" add "$AGENT_ID_DOER/AUDIT_TABLES" "$AGENT_ID_DOER/schemas/actions.json"
git -C "$PLATFORM_REPO_DIR" commit -m "$AGENT_ID_DOER: AUDIT_TABLES (nine) and actions schema from contract 1.0.0 (POV 04 PC-2.4)"
git -C "$PLATFORM_REPO_DIR" push -u origin pc-2-4-doer-tables
```

  **BLOCKED (PB-01)**: **Needs:** the eight schema files `runs.json`, `plans.json`, `approvals.json`, `verifications.json`, `config_versions.json`, `ladder_events.json`, `grades.json`, `generic_requests.json`, each with `ts` TIMESTAMP REQUIRED (the partition column), `contract_version`, `agent_id` and `env`, the correlation keys `run_id` and `trace_id` where the table carries a run, and the key columns Wall-E's LLD "Storage" table names; every agent-only column prefixed `a_`. **Repository:** `PLATFORM_REPO_REMOTE`, `<AGENT_ID_DOER>/schemas/`, reviewed by person 3. **Unblocked by:** the merge commit in which `ls <AGENT_ID_DOER>/schemas/*.json | wc -l` is `9` and every name in `AUDIT_TABLES` has its file; then `penv_set AUDIT_DDL_COMMIT <that sha>`. **Gate that waits:** file 07 part 2 (tables), file 06 §11 (Eve v0 queries), file 08 (Mo's pack). **Estimate:** Assumption: 2 to 3 engineer-days. Until then: `checkpoint PC-2.4 BLOCKED - - "PB-01 doer audit schemas"`.
- **VERIFY:** Now: `wc -l < "$D/AUDIT_TABLES"` prints `9`; `diff <(jq -S . "$D/schemas/actions.json") <(git -C "$PLATFORM_REPO_DIR" show "$AUDIT_SCHEMA_COMMIT":contract/1.0.0/audit-actions.bq.json | jq -S .)` prints nothing. Once unblocked: nine files; `jq -e 'map(select(.name=="ts" and .type=="TIMESTAMP")) | length == 1'` succeeds on each; `need AUDIT_DDL_COMMIT` is silent.
- **ROLLBACK:** A reverting pull request, only while file 07 has created no table.
- **EVIDENCE:** Merge commit as `<date>-PC-2.4-doer-tables-v1`; the unblocking commit as `-v2`. E-06. TISAX 5.2.4, 1.3.1.

### PC-2.5 Mo's dataset definitions and toil-baseline schemas: `MO_DDL_COMMIT`

- **Id:** PC-2.5
- **WHO:** Mo owner writes; person 3 reviews (22 MO-8.1's second operator).
- **WHERE:** Shell, branch `pc-2-5-mo-ddl`, then the git host.
- **ACTION:** Run setup/22 MO-8.1 **as written** (the two schemas `mo/schemas/toil_baseline_csv.json` and `mo/schemas/mo_toil_baseline.json` from setup/02's nine-column CSV contract, which file 02 kept unchanged under PV-05). One substitution: the rows are loaded in file 08 under `AGENT_ID_DOER`, not `walle`; 22 MO-8.1's own note provides for "rows added under that agent's id by a new load". Then commit the four dataset definitions that 22 MO-6.3 creates, with its labels and descriptions verbatim, as data file 08 reads:

```bash
source ~/.platform-env
cat > "$PLATFORM_REPO_DIR/mo/datasets.json" <<'JSON'
[
  {"variable": "MO_METRICS_DS", "name": "platform_metrics", "location": "EU", "labels": {"agent": "mo", "env": "prod", "data_class": "record"}, "default_table_expiration": null, "description": "Mo's computed metrics and the scorecard, every table keyed on agent_id. Written only by mo-metrics@. Read by nothing on any enforcement path (M-1)."},
  {"variable": "MO_ARCHIVE_DS", "name": "platform_metrics_archive", "location": "EU", "labels": {"agent": "mo", "env": "prod", "data_class": "evidence"}, "default_table_expiration": null, "description": "Dated scorecard snapshots and the commit-named toil baseline copies. The citable object a promotion points at (E-07)."},
  {"variable": "MO_PRIVATE_DS", "name": "platform_metrics_private", "location": "EU", "labels": {"agent": "mo", "env": "prod", "data_class": "record"}, "default_table_expiration": null, "description": "The surrogate mapping (principal_surrogates), alone. Written only by mo-metrics@. No reader, ever, to any principal."},
  {"variable": "MO_VIEWS_DS", "name": "platform_metrics_views", "location": "EU", "labels": {"agent": "mo", "env": "prod", "data_class": "record"}, "default_table_expiration": null, "description": "Agent-facing authorised views over platform_metrics. Views only, no tables; created as mo-metrics@ in setup 36."}
]
JSON
for n in MO_METRICS_DS MO_ARCHIVE_DS MO_PRIVATE_DS MO_VIEWS_DS; do v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES "$n") && jq -e --arg n "$n" --arg v "$v" 'map(select(.variable==$n and .name==$v)) | length == 1' "$PLATFORM_REPO_DIR/mo/datasets.json" >/dev/null && echo "$n matches NAMES"; done
# names-check: off PV-02
grep -c 'walle_metrics' "$PLATFORM_REPO_DIR/mo/datasets.json" "$PLATFORM_REPO_DIR"/mo/schemas/*.json
# names-check: on
git -C "$PLATFORM_REPO_DIR" add mo/datasets.json mo/schemas/toil_baseline_csv.json mo/schemas/mo_toil_baseline.json
git -C "$PLATFORM_REPO_DIR" commit -m "mo: dataset definitions (setup 22 MO-6.3) and toil schemas (MO-8.1), applied in POV 08 (POV 04 PC-2.5)"
git -C "$PLATFORM_REPO_DIR" push -u origin pc-2-5-mo-ddl
```

  After the merge: `C="$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%H origin/main -- mo/datasets.json)" && penv_set MO_DDL_COMMIT "$C"`. Mo's metric-pack tables are not here: they are PB-06, in file 08.
- **VERIFY:** Four `matches NAMES` lines (SD-33: every name starts `platform_metrics`); every `walle_metrics` count is `0`; 22 MO-8.1's VERIFY passes (`9` and `12` columns); `need MO_DDL_COMMIT` is silent.
- **ROLLBACK:** A reverting pull request before file 08 creates a dataset. After that, **IRREVERSIBLE** for the name and location (BigQuery datasets page, read 2026-09-16).
- **EVIDENCE:** Merge commit as `<date>-PC-2.5-mo-ddl-v1`. E-09. TISAX 5.3.1, 1.3.1.

### PC-2.6 Eve's `findings`, `incidents` and `pages` schemas: **BLOCKED** (PB-02)

- **Id:** PC-2.6
- **WHO:** Eve owner (person 2's group `eve-owners@`) writes; person 3 reviews.
- **WHERE:** Eve's repository.
- **ACTION:** **BLOCKED (PB-02)**: **Needs:** the three schema files of B-07's set that the POV's Eve writes (`findings`, `incidents`, `pages`), each keyed on `agent_id` where a row concerns an agent and on a principal surrogate where it concerns a human, `ts` TIMESTAMP REQUIRED. **Repository:** the Eve repository, commit recorded as `EVE_SCHEMAS_COMMIT` by file [06](06-eve-over-the-human-super-admins.md). **Gate that waits:** file 06's dataset tables and `POV_EVE_FIRST_RUN_RECORD`. **Estimate:** Assumption: 1 to 2 engineer-days. The schemas are written after PC-2.3 so that any column naming an agent row reuses `audit.schema`'s names.
- **VERIFY:** Once unblocked, file 06 verifies the three files at `EVE_SCHEMAS_COMMIT`.
- **ROLLBACK:** None needed while BLOCKED.
- **EVIDENCE:** The BLOCKED line in README's index. E-05. TISAX 5.2.4.

## 3. The register rows

Every row is merged **before** its project exists (setup/16 R-12; S057). Each purpose paragraph
below is a draft that must equal PV-11's signed text: the VERIFY compares SHA-256 values, and a
mismatch is corrected here, never in PV-11. Values that are neither in the schema nor in a record
are marked Assumption and confirmed by person 3 in the parse. `pending-07` markers are allowed
while a row is `poc` and refused at `status: prod` by R-13 (31 WD-1.1).

### PC-3.1 The doer's manifest

- **Id:** PC-3.1
- **WHO:** Platform owner writes; person 3 reviews in PC-3.5.
- **WHERE:** Shell, branch `pc-3-register-rows`.
- **ACTION:** The manifest follows 05 §9.2 and 31 WD-1.3's form. **The manifest does not yet carry the catalogue that README PB-04 and file 07 PW-4.1 promise.** Those promise six catalogued operations, each with an exact inverse, which is three reversible pairs; this manifest carries two (`F3` add and remove, `F9` create and delete), one read family whose `inverse: none` makes it no pair, and the band-B lane, which is irreversible. The third pair is not invented here: it is fixed by PV-01's catalogue values and PB-04 (Assumption: a pair on resources the robot owns or on synthetic pilot accounts), and file 07 adds it to this manifest by pull request, which changes `manifest_sha` and needs a new two-signer parse (re-run line in PC-5.1). Until that pull request merges, the doer's catalogue is two pairs, and nothing in files 07 to 09 may claim six operations on the strength of this manifest. Family ids reuse Wall-E's where the operation is the same (`F1`, `F3`, `F9`, `F11`), so the full build's ladder history reads across. Ceilings cap the POV at L3 on chat and L0 on every other trigger; `F11` is the `WRITE_GENERIC` band-B lane, whose ceiling is the code row and whose ladder cell stays absent (L0).

```bash
source ~/.platform-env
need AGENT_ID_DOER ORG_ID REGION DOMAIN MODEL_ID
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c pc-3-register-rows
A="$AGENT_ID_DOER"; AUD="$(printf '%s' "$A" | tr '-' '_')_audit"
test "$AUD" = "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES DOER_AUDIT_DS)" && echo "audit dataset name matches NAMES"
AI_CLASS="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-11 AI_ACT_CLASS_DOER)"
need AI_CLASS
cat > "$PLATFORM_REPO_DIR/$A/agent-manifest.yaml" <<EOF
contract_version: 1.0.0
identity:
  agent_id: ${A}
  tier: W
  owner_group: ${A}-owners@${DOMAIN}
  env: prod
  principal: "principal://agents.global.org-${ORG_ID}.system.id.goog/resources/aiplatform/projects/pending-07/locations/${REGION}/reasoningEngines/pending-07"
families:
  - {id: F1, description: "reads of the pilot groups, their members and the robot's own mailbox labels", risk_tier: READ, reversible: true, inverse: none, pre_state: none, taint_fields: []}
  - {id: F3, description: "group membership add and remove on groups the robot owns, members from PILOT_OU only", risk_tier: WRITE_LOW, reversible: true, inverse: group.member.remove, pre_state: snapshot, taint_fields: [member]}
  - {id: F9, description: "labels on the robot's own mailbox, create and delete", risk_tier: WRITE_LOW, reversible: true, inverse: gmail.label.delete, pre_state: snapshot, taint_fields: [label]}
  - {id: F11, description: "generic request, band B, always two humans; built and left at L0", risk_tier: WRITE_GENERIC, reversible: false, inverse: none, pre_state: "predicate:request_hash_bound", taint_fields: [request]}
trigger_classes: [{id: T0, name: chat}, {id: T1, name: scheduled}, {id: T2, name: event}, {id: T3, name: inbox}]
ceilings:
  F1:  {T0: L3, T1: L0, T2: L0, T3: L0, agent: L5}
  F3:  {T0: L3, T1: L0, T2: L0, T3: L0, agent: L0}
  F9:  {T0: L3, T1: L0, T2: L0, T3: L0, agent: L0}
  F11: {T0: L3, T1: L0, T2: L0, T3: L0, agent: L0}
protected_principals: ["group:${A}-protected@${DOMAIN}", "role:super_admin", "role:delegated_admin"]
hard_denied: ["domain-wide delegation in any form", "admin role assignment or removal", "users.makeAdmin", "any operation whose target is a super admin", "any operation on a protected principal", "any target outside PILOT_OU or the groups the robot owns", "Google Cloud IAM or settings of any platform project, folder or the organisation", "Gemini Enterprise configuration"]
egress: []
capabilities: {code_execution: false}
peers: []
invokers: {}
stores:
  - {name: ${AUD}, kind: bigquery, class: evidence, retention_row: R13}
  - {name: firestore-default, kind: firestore, class: control, retention_row: R14}
  - {name: ${A}-content-logs, kind: log_bucket, class: content, retention_row: R6}
  - {name: ${A}-oauth-client, kind: gcs, class: secret, retention_row: R15}
data_classes: [evidence, content, control, secret]
recovery_class: R-K
compliance:
  ai_act_entry: "10-eu-ai-act.md#${A}"
  ai_act_class: ${AI_CLASS}
  purpose_sha256: "…"
  art_50: {template_ids: ["pending-07"], header_value: "pending-07", text_sha256: "…"}
  tisax_class: confidential
  register_row: register/${A}.yaml
fingerprint: {prompt_sha256: "…", model_pin: "${MODEL_ID}", framework_version: "pending-07", armor_template_version: "pending-07"}
verifier: platform-verifier
metric_pack: full
EOF
```

  `purpose_sha256` is filled in PC-3.2 from the signed purpose. `invokers` is empty until file 07 names the control callers of K0 and K1; retention rows R6, R13, R14, R15 and `recovery_class: R-K` are copied from 31 WD-1.3 because the stores are of the same class (Assumption, confirmed against [../08-data-logging-retention-sovereignty.md](../08-data-logging-retention-sovereignty.md) by person 3). The literal `…` is the manifest schema's own placeholder (setup/16 RG-2.3) and is refused at `status: prod` by R-13.
- **VERIFY:** `audit dataset name matches NAMES` prints; `check-jsonschema --schemafile "$PLATFORM_REPO_DIR/$MANIFEST_SCHEMA_PATH" "$PLATFORM_REPO_DIR/$A/agent-manifest.yaml"` succeeds; `grep -c walle "$PLATFORM_REPO_DIR/$A/agent-manifest.yaml"` prints `0`.
- **ROLLBACK:** Delete the uncommitted file.
- **EVIDENCE:** Through PC-3.5. E-05. TISAX 1.3.1.

### PC-3.2 The doer's `env=prod` and `env=nonprod` rows

- **Id:** PC-3.2
- **WHO:** Platform owner writes; person 3 reviews in PC-3.5.
- **WHERE:** Shell, branch `pc-3-register-rows`.
- **ACTION:** Tier W: `privilege: none`, `verifier: platform-verifier`, `metric_pack: full` are what the schema forces. No platform verifier is deployed in the POV; its recomputation is signed by two people ([PV-D-13](09-the-demonstration-deviations-and-the-hand-over.md)), and its owner group comes from PV-09. `grader` is person 3 ([PV-D-16](09-the-demonstration-deviations-and-the-hand-over.md)). `risk_class` is `WRITE_HIGH` (Assumption: the schema's enum has no `WRITE_GENERIC`, and the band-B lane, always two humans, is treated as the highest write class). The nonprod row is never published and targets `NONPROD_OU` in file 07 ([../02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §3.5: Tier W nonprod uses a nonprod system of record). Both rows carry the prod manifest's hash, as 23 EP-1.3 does for Eve's two rows.

```bash
PURPOSE="The doer carries out a catalogued set of reversible Workspace operations on groups the robot owns, whose members are synthetic pilot accounts, when an authorised operator asks in chat; every request is written ahead to an insert-only audit, executes only at the level the ladder allows and with a human approval where the level requires one, and the model holds no credential and cannot approve."
PURPOSE_SHA="$(printf '%s' "$PURPOSE" | shasum -a 256 | cut -d' ' -f1)"
test "$PURPOSE_SHA" = "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-11 PURPOSE_SHA256_DOER)" && echo "purpose equals PV-11"
sed -i '' "s/^  purpose_sha256: \"…\"$/  purpose_sha256: ${PURPOSE_SHA}/" "$PLATFORM_REPO_DIR/$A/agent-manifest.yaml"
MANIFEST_SHA="$(shasum -a 256 "$PLATFORM_REPO_DIR/$A/agent-manifest.yaml" | cut -d' ' -f1)"
V_OWNER="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-09 VERIFIER_OWNER_GROUP)"
need V_OWNER BLIND_GRADER_EMAIL
test "$V_OWNER" != "${A}-owners@${DOMAIN}" && echo "verifier owner is not the agent owner (RP-1)"
REVIEW="$(python3.12 -c 'import datetime;print(datetime.date.today()+datetime.timedelta(days=90))')"
row() { cat <<EOF
  - display_name: "${A} (doer, $1)"
    purpose: "${PURPOSE}"
    owner_group: ${A}-owners@${DOMAIN}
    cost_centre: "*tbd*"
    tier: W
    env: $1
    folder: $2
    risk_class: WRITE_HIGH
    autonomy_ceiling: F1-T0-L3
    data_classes: [evidence, content, control, secret]
    tisax_class: confidential
    ai_act_class: ${AI_CLASS}
    ai_act_role: deployer
    model_pin: "${MODEL_ID}"
    framework_version: "pending-07"
    armor_template: "pending-07"
    gateway_id: "pending-07"
    principal: "principal://agents.global.org-${ORG_ID}.system.id.goog/resources/aiplatform/projects/pending-07/locations/${REGION}/reasoningEngines/pending-07"
    verifier: platform-verifier
    verifier_owner: ${V_OWNER}
    metric_pack: full
    privilege: none
    supplier_rows: [google-workspace, google-cloud-run, google-cloud-bigquery, google-vertex-ai]
    publish_to_gemini: $3
    audience_groups: $4
    grader: "${BLIND_GRADER_EMAIL}"
    recovery_class: R-K
    manifest_sha: ${MANIFEST_SHA}
    contract_version: "1.0.0"
    review_date: "${REVIEW}"
    status: poc
EOF
}
{ printf 'agent_id: %s\nrows:\n' "$A"; row prod FLD_AGENTS_W_PROD true "[${A}-operators@${DOMAIN}, ${A}-readers@${DOMAIN}]"; row nonprod FLD_AGENTS_W_NONPROD false "[]"; } > "$PLATFORM_REPO_DIR/register/${A}.yaml"
check-jsonschema --schemafile "$PLATFORM_REPO_DIR/$REGISTER_SCHEMA_PATH" "$PLATFORM_REPO_DIR/register/${A}.yaml"
grep -E '^    (folder|tier|privilege|verifier|metric_pack):' "$PLATFORM_REPO_DIR/register/${A}.yaml"
```

  `ai_act_role: deployer` and `supplier_rows` are Assumptions to confirm against PV-11 and the supplier file; `sed -i ''` is the macOS form. If `AI_CLASS` is `annex_iii_adjacent`, the schema requires `art_6_4_assessment` and `art_49_registration` on both rows: add them from PV-11 before the check, never as empty strings.
- **VERIFY:** `purpose equals PV-11` and `verifier owner is not the agent owner (RP-1)` print; `check-jsonschema` succeeds; the `grep` shows both rows at `tier: W`, `privilege: none`, `verifier: platform-verifier`, `metric_pack: full`, with folders `FLD_AGENTS_W_PROD` and `FLD_AGENTS_W_NONPROD`; both folder variables appear in `register/folders.yaml`.
- **ROLLBACK:** Delete the uncommitted file.
- **EVIDENCE:** Through PC-3.5. E-05, E-02 (the AI Act class). TISAX 1.3.1, 1.3.2.

### PC-3.3 Eve's `env=prod` row and controller manifest

- **Id:** PC-3.3
- **WHO:** Platform owner writes; person 2 reviews as the owner of `eve-owners@`; person 3 reviews in PC-3.5.
- **WHERE:** Shell, branch `pc-3-register-rows`.
- **ACTION:** 23 EP-1.3's row and manifest, with three POV differences. (1) **No nonprod row**: Eve's nonprod is the sandbox tenant's twin (setup/21), which Track A does not build ([PV-D-04](09-the-demonstration-deviations-and-the-hand-over.md)); [../02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §3.5 makes controller nonprod mandatory, so this is a named gap, closed by setup/21 and 23. (2) **Reads**: no Reports API poll and no Workspace credential ([PV-D-07](09-the-demonstration-deviations-and-the-hand-over.md)), so no `EVE_WS_REPORTS_DS`. (3) **Purpose**: agent-neutral and without the witness copy the POV does not have ([PV-D-03](09-the-demonstration-deviations-and-the-hand-over.md)), and never the word independent. `made_in` keeps the setup file that owns each grant in the full build, so the manifest survives the hand-over.

```bash
source ~/.platform-env
EP="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES EVE_PROJECT)"
need EP DIRECTORY_CUSTOMER_ID
mkdir -p "$PLATFORM_REPO_DIR/eve"
PURPOSE="Eve observes the tenant's human super administrators and the platform's privileged agents from Google-written audit streams and the agents' own audit datasets, recomputes what the design says must be true, and reports what is wrong to a named human who is not the subject of the report; Eve holds no credential of any other principal, calls no model, and can approve nothing."
PURPOSE_SHA="$(printf '%s' "$PURPOSE" | shasum -a 256 | cut -d' ' -f1)"
test "$PURPOSE_SHA" = "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-11 PURPOSE_SHA256_EVE)" && echo "purpose equals PV-11"
cat > "$PLATFORM_REPO_DIR/eve/agent-manifest.yaml" <<EOF
contract_version: 1.0.0
identity: {agent_id: eve, kind: controller, tier: CTL, owner_group: eve-owners@${DOMAIN}, env: prod}
reads:
  - {source: "organisation Workspace audit streams shared to Cloud Logging", kind: logging, topology_row: 30, made_in: "24"}
  - {source: "\${LOGGING_PROJECT}:platform_logs_views", kind: bigquery, topology_row: 40, made_in: "14"}
  - {source: "\${DOER_PROJECT}:$(printf '%s' "$AGENT_ID_DOER" | tr '-' '_')_audit", kind: bigquery, topology_row: 34, made_in: "31"}
writes: [EVE_DS, EVE_WS_LOGS_DS, EVE_QUALITY_DS, EVE_EVIDENCE_BUCKET]
stores:
  - {name: eve, kind: bigquery, class: evidence, retention_row: R14}
  - {name: eve_workspace_logs, kind: bigquery, class: record, retention_row: R15}
  - {name: eve_quality, kind: bigquery, class: record, retention_row: R14}
  - {name: eve-evidence-bucket, kind: gcs, class: evidence, retention_row: R14}
  - {name: eve-evidence-keys, kind: kms, class: secret, retention_row: R14}
egress: []
invokers: {}
capabilities: {code_execution: false, may_approve: false, holds_credential_of_another_principal: false}
model_pin: none
data_classes: [evidence, record, control]
recovery_class: R-K
compliance: {ai_act_entry: "10-eu-ai-act.md#eve", ai_act_class: minimal, purpose_sha256: ${PURPOSE_SHA}, tisax_class: strictly-confidential, register_row: register/eve.yaml}
EOF
MANIFEST_SHA="$(shasum -a 256 "$PLATFORM_REPO_DIR/eve/agent-manifest.yaml" | cut -d' ' -f1)"
cat > "$PLATFORM_REPO_DIR/register/eve.yaml" <<EOF
agent_id: eve
rows:
  - display_name: "Eve (controller, prod)"
    purpose: "${PURPOSE}"
    owner_group: eve-owners@${DOMAIN}
    cost_centre: "*tbd*"
    tier: CTL
    env: prod
    folder: FLD_CONTROLLERS_PROD
    project_id: ${EP}
    acts_on_customer: ${DIRECTORY_CUSTOMER_ID}
    risk_class: READ
    data_classes: [evidence, record, control]
    tisax_class: strictly-confidential
    ai_act_class: minimal
    ai_act_role: deployer
    model_pin: none
    supplier_rows: ["google-workspace", "google-cloud"]
    publish_to_gemini: false
    audience_groups: []
    review_date: "$(python3.12 -c 'import datetime;print(datetime.date.today()+datetime.timedelta(days=90))')"
    status: poc
    privilege: none
    metric_pack: light
    verifier: none
    verifier_owner: eve-owners@${DOMAIN}
    recovery_class: R-K
    manifest_sha: ${MANIFEST_SHA}
    contract_version: 1.0.0
EOF
check-jsonschema --schemafile "$PLATFORM_REPO_DIR/contract/1.0.0/controller-manifest.schema.json" "$PLATFORM_REPO_DIR/eve/agent-manifest.yaml"
check-jsonschema --schemafile "$PLATFORM_REPO_DIR/$REGISTER_SCHEMA_PATH" "$PLATFORM_REPO_DIR/register/eve.yaml"
grep -ci 'independent\|witness' "$PLATFORM_REPO_DIR/register/eve.yaml" "$PLATFORM_REPO_DIR/eve/agent-manifest.yaml"
```

  The doer-audit read's `topology_row: 34` is an Assumption (the row for `eve-export@` over `walle_audit` in [../../project-topology.md](../../project-topology.md)); person 3 confirms it or corrects it before the parse.
- **VERIFY:** `purpose equals PV-11`; both `check-jsonschema` runs succeed; the last `grep` prints `0` for both files; `eve-owners@` is the row's owner group and `verifier_owner`, as 23 EP-1.3 has it.
- **ROLLBACK:** Delete the uncommitted files.
- **EVIDENCE:** Through PC-3.5. E-05. TISAX 1.3.1, 1.3.2.

### PC-3.4 Mo's `env=prod` row and improver manifest

- **Id:** PC-3.4
- **WHO:** Mo owner writes; person 3 reviews in PC-3.5.
- **WHERE:** Shell, branch `pc-3-register-rows`.
- **ACTION:** Run the fence of setup/22 MO-1.3 **as written**, except for two lines. (1) Mo's purpose is agent-neutral: "Mo measures the platform's agents from committed SQL over their audit and quality datasets, publishes scorecards and proposes configuration changes only as pull requests that humans merge; nothing Mo writes is read by anything that enforces (M-1)." (2) The `reads` list replaces `${WALLE_PROJECT}:walle_audit` with `${DOER_PROJECT}:<AGENT_ID_DOER with underscores>_audit` (same `topology_row: 6`, `made_in: "31"`) and drops the `eve_grades` read, which the POV does not create (Assumption: file 08's blind grading records its grades elsewhere; file 08 confirms). No nonprod row: 22 MO-2.4 writes one only if P40 requires Mo's twin, which Track A does not build.

```bash
source ~/.platform-env
PURPOSE="Mo measures the platform's agents from committed SQL over their audit and quality datasets, publishes scorecards and proposes configuration changes only as pull requests that humans merge; nothing Mo writes is read by anything that enforces (M-1)."
test "$(printf '%s' "$PURPOSE" | shasum -a 256 | cut -d' ' -f1)" = "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-11 PURPOSE_SHA256_MO)" && echo "purpose equals PV-11"
check-jsonschema --schemafile "$PLATFORM_REPO_DIR/contract/1.0.0/improver-manifest.schema.json" "$PLATFORM_REPO_DIR/mo/agent-manifest.yaml"
check-jsonschema --schemafile "$PLATFORM_REPO_DIR/$REGISTER_SCHEMA_PATH" "$PLATFORM_REPO_DIR/register/mo.yaml"
# names-check: off PV-02
grep -c 'walle' "$PLATFORM_REPO_DIR/register/mo.yaml" "$PLATFORM_REPO_DIR/mo/agent-manifest.yaml"
# names-check: on
```

- **VERIFY:** `purpose equals PV-11`; both checks succeed; both `walle` counts print `0`; the row is `tier: IMP`, `folder: FLD_IMPROVERS_PROD`, `privilege: none`, `verifier: none`, `publish_to_gemini: false`, as 22 MO-1.1's rules force.
- **ROLLBACK:** Delete the uncommitted files.
- **EVIDENCE:** Through PC-3.5. E-05. TISAX 1.3.1.

### PC-3.5 The signed manual parse, the merge, and the row variables

- **Id:** PC-3.5
- **WHO:** Platform owner opens; **person 2 and person 3 each parse separately and sign**; the platform owner never signs ([PV-D-13](09-the-demonstration-deviations-and-the-hand-over.md); setup/16 RG-3.6). Two human approvals merge.
- **WHERE:** The git host, and a clone of `main` plus the branch.
- **ACTION:** Commit, open the pull request, then both signers run setup/16 RG-3.6 **as written** (its reading aid and its `gh pr view` read) and write `decisions/register-parses/<date>-pr<number>-parse.md` with every rule R-01 to R-13 marked `pass`, `fail` or `n/a` and a reason. For this pull request the rules that carry weight are: R-01 (each `manifest_sha` equals the manifest's SHA-256 on the branch; each `folder` in `folders.yaml`; `review_date` within 90 days); R-02 (no `env=prod` P-SA row exists: `n/a` with the count `0`); R-06 (`MODEL_ID` has a `models.yaml` row more than 90 days from retirement); R-07 (group names match 04 §2.4's patterns); R-12 (no project for any of the three agents exists yet); R-13 (the `pending-07` and `…` markers are allowed because every row is `poc`). Both signers also confirm by reading that the tier clauses quoted in "What this part builds" hold on every row.

```bash
source ~/.platform-env
need SECOND_HUMAN_EMAIL PLATFORM_REPO_SLUG
checkpoint PC-3.5 START "$SECOND_HUMAN_EMAIL" - "irreversible once a project exists: register rows pull request opened"
git -C "$PLATFORM_REPO_DIR" add "register/${AGENT_ID_DOER}.yaml" "${AGENT_ID_DOER}/agent-manifest.yaml" register/eve.yaml eve/agent-manifest.yaml register/mo.yaml mo/agent-manifest.yaml
git -C "$PLATFORM_REPO_DIR" commit -m "register: doer (W prod, nonprod), eve (CTL prod), mo (IMP prod) rows before any project (POV 04 PC-3; R-12)"
git -C "$PLATFORM_REPO_DIR" push -u origin pc-3-register-rows
gh pr create --repo "$PLATFORM_REPO_SLUG" --head pc-3-register-rows --title "PC-3 register rows: doer, eve, mo" --body "Parse by person 2 and person 3 in decisions/register-parses/. No project exists for any row (R-12)."
for m in "${AGENT_ID_DOER}" eve mo; do git -C "$PLATFORM_REPO_DIR" show "HEAD:$m/agent-manifest.yaml" | shasum -a 256 | cut -d' ' -f1; grep -m1 'manifest_sha' "$PLATFORM_REPO_DIR/register/$m.yaml"; done
```

  After the merge:

```bash
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
RC="$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%H -- register/)"
penv_set DOER_REGISTER_ROW "register/${AGENT_ID_DOER}.yaml@${RC}:prod"
penv_set DOER_REGISTER_ROW_NONPROD "register/${AGENT_ID_DOER}.yaml@${RC}:nonprod"
penv_set EVE_REGISTER_ROW "register/eve.yaml@${RC}:prod"
penv_set MO_REGISTER_ROW "register/mo.yaml@${RC}:prod"
P="$(git -C "$PLATFORM_REPO_DIR" log -1 --name-only --format= -- decisions/register-parses/ | grep -- '-parse\.md$' | head -1)"
need P
"$PLATFORM_REPO_DIR/tools/decision-check.sh" "$PLATFORM_REPO_DIR/$P" && penv_set MANUAL_PARSE_RECORD "$P"
need DOER_REGISTER_ROW DOER_REGISTER_ROW_NONPROD EVE_REGISTER_ROW MO_REGISTER_ROW MANUAL_PARSE_RECORD && checkpoint PC-3.5 DONE "$SECOND_HUMAN_EMAIL" "repo:register@$RC" "register rows merged; parse $P"
```

- **VERIFY:** Each manifest hash printed equals its row's `manifest_sha` (the doer's twice); `decision-check.sh` prints `OK`; the parse file carries two signatures, neither the platform owner's, and 13 rule lines; `need DOER_REGISTER_ROW DOER_REGISTER_ROW_NONPROD EVE_REGISTER_ROW MO_REGISTER_ROW MANUAL_PARSE_RECORD` is silent. A parse by one person, or one that marks a rule without a reason, is refused at review.
- **ROLLBACK:** A reverting pull request, only while no project exists. After a project is made from a row, the row stays and is retired only through setup/17 FM-REVOKE's path.
- **EVIDENCE:** Merge commit and parse as `<date>-PC-3.5-register-rows-v1`; `evidence_add PC-3.5 register-rows E-05 1.3.1 repo:register@<sha>`. E-05, E-02. TISAX 1.3.1, 1.3.2, 5.2.1.

## 4. The shared registry and the Tier R record

### PC-4.1 Record `AGENT_REGISTRY` and prove nobody writes it standing

- **Id:** PC-4.1
- **WHO:** Platform owner; person 2 reads the output.
- **WHERE:** Shell, `~/.platform-env` sourced.
- **ACTION:** setup/16 RG-5.1 as written: the registry exists once the API is enabled in the project (Agent Registry setup page, read 2026-09-16: enabling `agentregistry.googleapis.com` is the only prerequisite named); manual registration works in single regions such as `europe-west1`, not in the `us` and `eu` multi-regions (locations page, read 2026-09-16). setup/16 RG-5.3 binds `roles/agentregistry.admin` to `factory-apply@`, which the POV does not have ([PV-D-01](09-the-demonstration-deviations-and-the-hand-over.md)): in the POV **no principal holds a standing registry role**, and each registration write in files 05 and 07 is a human act under a PAM grant person 2 approves. Google advises to "avoid granting these roles directly to agents" (roles page, read 2026-09-16).

```bash
source ~/.platform-env
need CORE_PROJECT REGION
test "$REGION" = europe-west1 || { echo "STOP: REGION is not europe-west1"; false; }
gcloud services list --enabled --project="$CORE_PROJECT" --filter="config.name=agentregistry.googleapis.com" --format="value(config.name)"
gcloud agent-registry agents list --location="$REGION" --project="$CORE_PROJECT" --format="table(name)"
gcloud agent-registry services list --location="$REGION" --project="$CORE_PROJECT" --format="table(name,displayName)"
gcloud projects get-iam-policy "$CORE_PROJECT" --flatten="bindings[].members" --filter="bindings.role:roles/agentregistry." --format="table(bindings.role,bindings.members)" | tee "$BUILD_LOG_DIR/records/$(date -u +%F)-PC-4.1-registry-iam-v1.txt"
need PLATFORM_REPO_DIR PAM_ENTITLEMENTS
test -s "$PLATFORM_REPO_DIR/$PAM_ENTITLEMENTS" || echo "STOP: the PAM catalogue index $PAM_ENTITLEMENTS is not in the platform repository (file 03 PF-5.1)"
grep -l 'agentregistry.admin' "$PLATFORM_REPO_DIR/$PAM_ENTITLEMENTS" "$PLATFORM_REPO_DIR"/pam/*.json 2>/dev/null || echo "PENDING: no entitlement carries agentregistry.admin; file 03 PF-5.1 must carry ent-project-repair-core (setup/12) before file 05 registers"
penv_set AGENT_REGISTRY "projects/${CORE_PROJECT}/locations/${REGION}"
```

  `PAM_ENTITLEMENTS` is set by file 03 PF-5.1 as a path relative to the platform repository (`pam/index.tsv`), so it is read under `PLATFORM_REPO_DIR`; a bare relative path from the shell would never find the file and would always print PENDING. Assumption: the entitlement definitions sit beside the index as `pam/*.json` (setup/12's layout); if not, person 2 reads the entitlement list with file 03 PF-5.1's own live-compare.
- **VERIFY:** The service line prints `agentregistry.googleapis.com`; both lists are empty; the IAM table has no row, or only `roles/agentregistry.viewer` rows for groups (never an agent principal, never `editor` or `user`); an entitlement carrying `agentregistry.admin` exists or the PENDING line is copied to `$BUILD_LOG_DIR/rerun-index.tsv`; `need AGENT_REGISTRY` is silent.
- **ROLLBACK:** Read only; `penv_set --force` only for a typing error.
- **EVIDENCE:** The IAM file and the lists as `<date>-PC-4.1-registry-v1`; `evidence_add PC-4.1 registry-iam E-05 4.2.1 build-log:records/<file> <file>`. E-05. TISAX 1.3.1, 4.2.1.

### PC-4.2 The registry write alert: the policy here, the drill in file 05

- **Id:** PC-4.2
- **WHO:** Platform owner under a PAM grant person 2 approves; person 2 confirms the page.
- **WHERE:** Shell.
- **ACTION:** Run setup/16 RG-5.6 as written with `NOTIF_CH_EMAIL_CORE` (and the pager channel if file 03 made one). setup/16 RG-5.7's drill write is not run here: [05](05-gemini-enterprise-and-tier-c.md) PG-7.1a runs it, one marked repair write in `AGENT_REGISTRY` that must page within five minutes, and a write with no page is a stop for file 05, not a note. [07](07-the-doer-tier-w-and-the-optional-tier-p.md) PW-5.4a registers the doer's engine in `AGENT_REGISTRY`, and [05](05-gemini-enterprise-and-tier-c.md) PG-6.3a records why the two no-code Tier C agents are not registered. Until PG-7.1a writes its `DONE` line for PC-4.2 in `rerun-index.tsv`, the alert is **unproven**, and no later file may cite it as a working detection.
- **VERIFY:** setup/16 RG-5.6's VERIFY passes; a re-run line "`PC-4.2` → file 05 PG-7.1a: the drill write must page within 5 minutes (RG-5.7)" is in `rerun-index.tsv`.
- **ROLLBACK:** As setup/16 RG-5.6.
- **EVIDENCE:** As setup/16 RG-5.6, recorded as `<date>-PC-4.2-registry-alert-v1`. E-08. TISAX 5.2.4.

### PC-4.2a Commit the run-spec template: setup/17 FM-1.1, unchanged

Steps PC-4.2a to PC-4.2d are setup/17 §1 run unchanged. They sit here, after the register rows merge and before the Tier R record, because the factory item of that record carries the checker's proof (setup/17 FM-10.1), and because no agent project may be created before its run spec can be written from this template (files 06, 07 and 08).

- **Id:** PC-4.2a
- **WHO:** Platform owner writes; **two human reviewers who are not the platform owner merge** (person 2 and person 3, branch protection of 01 PP-5.3).
- **WHERE:** Shell, branch `fm-1-runspec-template` (FM-1.1's name), then the git host.
- **ACTION:** Execute [setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md) FM-1.1 **unchanged**, at the wiki commit recorded in PC-0.1. The template is extracted from setup/17 with 01 PP-1.3's `pov_extract`, never retyped, so the full build's FM-1.1 finds the same bytes on `main`. The one reading FM-1.1 asks for, the spelling of the label keys, is settled by the core projects file 03 PF-4.1 already labelled: underscores, which is the template's spelling, so nothing in the extracted file changes.

```bash
source ~/.platform-env
. "$PLATFORM_REPO_DIR/tools/pov-lib.sh"
need WIKI_DIR PLATFORM_REPO_DIR PLATFORM_REPO_SLUG BUILD_LOG_DIR
checkpoint PC-4.2a START - - "setup/17 FM-1.1 run-spec template, extracted unchanged"
S17="$WIKI_DIR/platform/agentic-platform/setup/17-factory-module-equivalents-and-tier-r-gate.md"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c fm-1-runspec-template
mkdir -p "$PLATFORM_REPO_DIR/factory/runs"
pov_extract "$S17" "cat > \"\$PLATFORM_REPO_DIR/factory/runs/_template.json\" <<'JSON'" JSON > "$PLATFORM_REPO_DIR/factory/runs/_template.json" || { echo "STOP: FM-1.1's opener not found in setup/17; the template is never retyped"; false; }
python3.12 -m json.tool "$PLATFORM_REPO_DIR/factory/runs/_template.json" >/dev/null && echo JSON-OK
jq -r 'keys | length' "$PLATFORM_REPO_DIR/factory/runs/_template.json"
shasum -a 256 "$S17" "$PLATFORM_REPO_DIR/factory/runs/_template.json" | tee "$BUILD_LOG_DIR/records/$(date -u +%F)-PC-4.2a-template-extraction-v1.txt"
git -C "$PLATFORM_REPO_DIR" add factory/runs/_template.json
git -C "$PLATFORM_REPO_DIR" commit -m "factory: run-spec template for hand module equivalents (setup 17 FM-1.1, SD-01; POV 04 PC-4.2a)"
git -C "$PLATFORM_REPO_DIR" push -u origin fm-1-runspec-template
gh pr create --repo "$PLATFORM_REPO_SLUG" --head fm-1-runspec-template --title "PC-4.2a setup/17 FM-1.1 run-spec template" --body "Extracted unchanged from setup/17 FM-1.1 at the PC-0.1 wiki commit (hashes in the build log). Two human approvals, neither the author."
```

  After the merge: `git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only && checkpoint PC-4.2a DONE - "repo:factory/runs/_template.json@$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%h -- factory/runs/_template.json)" "template merged"`.
- **VERIFY:** `JSON-OK`; the key count prints `35` (read from setup/17 on 2026-09-16, when the extraction gave 37 lines); `diff <(pov_extract "$S17" "cat > \"\$PLATFORM_REPO_DIR/factory/runs/_template.json\" <<'JSON'" JSON) <(git -C "$PLATFORM_REPO_DIR" show origin/main:factory/runs/_template.json)` prints nothing; setup/17 FM-1.1's VERIFY holds as written: the pull request is merged with two human approvals, neither the platform owner's, and `git -C "$PLATFORM_REPO_DIR" log --oneline -1 origin/main -- factory/runs/_template.json` shows the merge. An empty extraction means setup/17's opener changed: stop, do not retype.
- **ROLLBACK:** A reverting pull request, while no run spec has been written from the template.
- **EVIDENCE:** Merge commit and the extraction hashes as `<date>-PC-4.2a-runspec-template-v1`; `evidence_add PC-4.2a runspec-template E-05 5.2.1 "repo:factory/runs/_template.json@<merge sha>" "$PLATFORM_REPO_DIR/factory/runs/_template.json"`. E-05. TISAX 5.2.1.

### PC-4.2b Commit the zero-diff checker: setup/17 FM-1.2, unchanged

- **Id:** PC-4.2b
- **WHO:** Platform owner writes; **two human reviewers merge, one of them the security reviewer** (person 3), the other person 2 (setup/17 FM-1.2). The platform owner approves nothing.
- **WHERE:** Shell, branch `fm-1-zero-diff-checker` (FM-1.2's name), then the git host.
- **ACTION:** Execute setup/17 FM-1.2 **unchanged**: extract `tools/fm-zero-diff.py` byte for byte, make it executable, compile it, commit it, open the pull request. The checker only reads (`describe`, `list`, `get`), never reads a secret payload, writes a JSON report, and exits 0 only when every check is `PASS`, or `PENDING` with `--accept-pending`, which the report records. **What `live` compares**, so that a run spec states each of them: the project's parent folder, `ACTIVE` state and labels (exactly); the effective tags, and no tag bound directly; the billing link; the enabled services, which must equal `services` once `service_dependencies` are removed; `_Default` routed to the spec's regional bucket and its retention; `_Required` global; `_Trace` in `REGION` when `trace_bucket` is true; exactly one budget of the spec's display name and amount, filtered to this project alone, with four threshold rules; the Essential Contacts and their categories (exactly); the service accounts (exactly) and that none has a user-managed key; that no user, group or domain member and no `roles/owner` or `roles/editor` holder is outside `allowed_human_members`; that no service account outside `project_bindings` holds a project role, Google's service agents excepted; that every `project_bindings` entry is present; a delete lien; the spec's notification channels (at least); the trigger sink; each deny-policy rule and exception; each PAB binding; each project organisation policy and project deny policy; the spec's PAM entitlements (at least); and the Model Armor project floor. `inputs` checks the spec against the register row, NAMES, `register/folders.yaml`, the parent folder's enforced service allow-list and the tier budget table.

  **The checker is never edited in the POV.** A check that cannot pass on a POV project is written into that project's run spec as a `pending` line with its reason, owner and re-run point, as the template allows, or is recorded against setup/17's owner; it is never removed from the code.

```bash
source ~/.platform-env
. "$PLATFORM_REPO_DIR/tools/pov-lib.sh"
need WIKI_DIR PLATFORM_REPO_DIR PLATFORM_REPO_SLUG BUILD_LOG_DIR
checkpoint PC-4.2b START - - "setup/17 FM-1.2 zero-diff checker, extracted unchanged"
S17="$WIKI_DIR/platform/agentic-platform/setup/17-factory-module-equivalents-and-tier-r-gate.md"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c fm-1-zero-diff-checker
mkdir -p "$PLATFORM_REPO_DIR/tools"
pov_extract "$S17" "cat > \"\$PLATFORM_REPO_DIR/tools/fm-zero-diff.py\" <<'PY'" PY > "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" || { echo "STOP: FM-1.2's opener not found in setup/17; the checker is never retyped"; false; }
chmod +x "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py"
python3.12 -m py_compile "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py"
if python3.12 "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" >/dev/null; then echo "exit=0"; else echo "exit=$?"; fi
"${REGISTER_VENV_PYTHON:-$HOME/platform/venv-register/bin/python}" -c 'import yaml; print(yaml.__version__)'
shasum -a 256 "$S17" "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py" | tee "$BUILD_LOG_DIR/records/$(date -u +%F)-PC-4.2b-checker-extraction-v1.txt"
git -C "$PLATFORM_REPO_DIR" add tools/fm-zero-diff.py
git -C "$PLATFORM_REPO_DIR" commit -m "tools: fm-zero-diff checker for hand module equivalents (setup 17 FM-1.2; POV 04 PC-4.2b)"
git -C "$PLATFORM_REPO_DIR" push -u origin fm-1-zero-diff-checker
gh pr create --repo "$PLATFORM_REPO_SLUG" --head fm-1-zero-diff-checker --title "PC-4.2b setup/17 FM-1.2 zero-diff checker" --body "Extracted unchanged from setup/17 FM-1.2 at the PC-0.1 wiki commit. Approvers: the security reviewer and the second person, neither the author."
```

  After the merge: `git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only && checkpoint PC-4.2b DONE "$SECURITY_REVIEWER_EMAIL" "repo:tools/fm-zero-diff.py@$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%h -- tools/fm-zero-diff.py)" "checker merged"`.
- **VERIFY:** setup/17 FM-1.2's VERIFY as written: `py_compile` prints nothing; the run without arguments prints the usage and `exit=2`; the register interpreter prints `6.0.3` (if it is missing, re-run setup/16 RG-2.1 through PC-1.1, never edit the checker to parse YAML by hand); the pull request is merged with two human approvals, person 3's among them. Also: `diff <(pov_extract "$S17" "cat > \"\$PLATFORM_REPO_DIR/tools/fm-zero-diff.py\" <<'PY'" PY) <(git -C "$PLATFORM_REPO_DIR" show origin/main:tools/fm-zero-diff.py)` prints nothing (the extraction gave 303 lines on 2026-09-16).
- **ROLLBACK:** A reverting pull request. The checker writes nothing to Google Cloud.
- **EVIDENCE:** Merge commit and hashes as `<date>-PC-4.2b-checker-v1`; `evidence_add PC-4.2b zero-diff-checker E-05 5.2.4 "repo:tools/fm-zero-diff.py@<merge sha>" "$PLATFORM_REPO_DIR/tools/fm-zero-diff.py"`. E-05 (the verification method of the technical documentation). TISAX 5.2.1, 5.2.4.

### PC-4.2c Write the platform-core run spec for `CICD_PROJECT`: setup/17 FM-1.3

- **Id:** PC-4.2c
- **WHO:** Platform owner writes; person 3 reads the transcription against file 03's records in PC-4.2d's review. The budget repair below: the platform owner while today is before `BOOTSTRAP_BILLING_EXPIRY`, otherwise the billing administrator.
- **WHERE:** `PLATFORM_REPO_DIR`; shell.
- **ACTION:** Execute setup/17 FM-1.3 as written: transcribe `CICD_PROJECT`'s row into `factory/runs/platform-core-cicd.json` with `"module": "platform-core"`, `"create": false`, `allowed_human_members: []`, `lien: true`, `entitlements: []`, FM-1.3's `project_floor` and its `made_elsewhere` line. The reads are for transcription, not a source of truth: **a value that differs between file 03's record and the live read is written to the build log and resolved before PC-4.2d, never silently copied from the live side.** Four readings, each because the POV built `CICD_PROJECT` in file 03 rather than setup/10:
  1. **The record is file 03's.** PF-4.1 ran setup/10 CP-1.1 to CP-1.10 for the row (labels, services, `_Default`, `_Trace`, budget, contacts, lien), PF-4.2 created `factory-apply@` as an identity only, PF-5.1 enabled `privilegedaccessmanager.googleapis.com` here (the PAM quota project), and PF-10.3 removed the creator's Owner.
  2. **Service accounts.** Only `factory-apply` exists (03 PF-4.2). setup/10 CP-8.1's other three accounts are not built in the POV (B-01), so `service_accounts` is `["factory-apply"]` and a `made_elsewhere` line names setup/10.
  3. **`run_id`.** FM-1.3 fixes `run_id` as "the label 10 wrote". setup/10 CP-1.1 and 03 PF-4.1 write `factory_run=dev-10-cicd`, while FM-1.3's VERIFY prints `dev-10-core-cicd`. The spec follows the rule, `dev-10-cicd`, because `inputs` compares `labels.factory_run` with `run_id` and `live` compares the labels exactly; the literal is recorded in "Unverified" for setup/17's owner.
  4. **The register row.** setup/16 as run in PC-1.1 commits no platform-core row file, so `register_row` says so and `register_commit` is the merge commit of `register/schema/register-row.schema.json` (PC-1.1), which is on `main`; FM-1.4's fixture replaces the row path and reads that commit.

  The one difference file 03's own text makes likely: PF-4.1 says it ran CP-1.9 unchanged, but the create line it prints gives the budget the display name `agp cicd monthly` and three threshold rules, where CP-1.9 gives `<project id>-budget` and four (the fourth at 100 per cent of forecasted spend). The checker requires four. The spec records the display name as it is, and the missing rule is **repaired** to CP-1.9's contract below, not written away.

```bash
source ~/.platform-env
need CICD_PROJECT FLD_PLATFORM_CORE GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY BILLING_ACCOUNT_ID BOOTSTRAP_BILLING_EXPIRY BUILD_LOG_DIR PLATFORM_REPO_DIR
checkpoint PC-4.2c START - - "setup/17 FM-1.3 platform-core spec for CICD_PROJECT"
R="$BUILD_LOG_DIR/records/$(date -u +%F)-PC-4.2c"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
cp "$PLATFORM_REPO_DIR/factory/runs/_template.json" "$PLATFORM_REPO_DIR/factory/runs/platform-core-cicd.json"
# FM-1.3's three reads, then the reads for budget, contacts, accounts, lien and tags
gcloud services list --enabled --project="$CICD_PROJECT" --format="value(config.name)" | sort | tee "${R}-services-v1.txt"
gcloud projects get-iam-policy "$CICD_PROJECT" --flatten="bindings[].members" --format="table(bindings.role,bindings.members)" | tee "${R}-iam-v1.txt"
gcloud projects describe "$CICD_PROJECT" --format="json(labels)" | tee "${R}-labels-v1.json"
P_NUM="$(gcloud projects describe "$CICD_PROJECT" --format='value(projectNumber)')"
gcloud billing budgets list --billing-account="$BILLING_ACCOUNT_ID" --billing-project="$CICD_PROJECT" --format=json | jq --arg a "projects/${CICD_PROJECT}" --arg b "projects/${P_NUM}" '[.[] | select((.budgetFilter.projects // []) == [$a] or (.budgetFilter.projects // []) == [$b]) | {name, displayName, units: .amount.specifiedAmount.units, rules: (.thresholdRules | length)}]' | tee "${R}-budget-v1.json"
gcloud essential-contacts list --project="$CICD_PROJECT" --billing-project="$CICD_PROJECT" --format="table(email,notificationCategorySubscriptions)" | tee "${R}-contacts-v1.txt"
gcloud iam service-accounts list --project="$CICD_PROJECT" --format="value(email)" | tee "${R}-accounts-v1.txt"
gcloud alpha resource-manager liens list --project="$CICD_PROJECT" --format="table(name,restrictions,origin)" | tee "${R}-lien-v1.txt"
TAGS="$(gcloud resource-manager tags bindings list --parent="//cloudresourcemanager.googleapis.com/projects/${P_NUM}" --effective --format=json | jq -c '[.[] | .namespacedTagValue | split("/") | {(.[-2]): .[-1]}] | add // {}')"; echo "$TAGS" | tee "${R}-tags-v1.json"
RC0="$(git -C "$PLATFORM_REPO_DIR" log -1 --format=%H origin/main -- register/schema/register-row.schema.json)"; need RC0
BUDGET_DN="$(jq -r 'if length == 1 then .[0].displayName else empty end' "${R}-budget-v1.json")"; need BUDGET_DN
jq --arg id "$CICD_PROJECT" --arg rc "$RC0" --arg po "$GRP_PLATFORM_OWNERS" --arg ps "$GRP_PLATFORM_SECURITY" --arg dn "$BUDGET_DN" --argjson tags "$TAGS" '
  .module="platform-core" | .run_id="dev-10-cicd" | .calling_file_step="POV 04 PC-4.2c (setup 17 FM-1.3)"
  | .register_row="none: setup/16 RG-1.1 to RG-2.6 commit no platform-core row" | .register_commit=$rc | .manifest=null
  | .agent_id="platform-cicd" | .env="prod" | .register_tier="none: platform-core has no register row"
  | .project_variable="CICD_PROJECT" | .project_id=$id | .create=false | .parent_folder_variable="FLD_PLATFORM_CORE"
  | .labels={"agent":"platform-cicd","owner":"platform-owners","tier":"core","env":"prod","data_class":"confidential","ai_act_class":"not_ai_system","recovery_class":"r-d","cost_centre":"tbd","created_by":"bootstrap-hand","factory_run":"dev-10-cicd"}
  | .tags_effective=$tags
  | .services=["serviceusage.googleapis.com","cloudresourcemanager.googleapis.com","iam.googleapis.com","iamcredentials.googleapis.com","sts.googleapis.com","logging.googleapis.com","monitoring.googleapis.com","storage.googleapis.com","cloudbuild.googleapis.com","artifactregistry.googleapis.com","containeranalysis.googleapis.com","containerscanning.googleapis.com","binaryauthorization.googleapis.com","cloudkms.googleapis.com","billingbudgets.googleapis.com","essentialcontacts.googleapis.com","observability.googleapis.com","privilegedaccessmanager.googleapis.com"]
  | .service_dependencies=[]
  | .log_routing={"default_bucket":"default-europe-west1","location":"europe-west1","retention_days":30,"trace_bucket":true}
  | .budget={"display_name":$dn,"amount":300,"reason_if_not_tier_default":null}
  | .essential_contacts=[{"email":$po,"categories":["SECURITY","SUSPENSION","TECHNICAL","TECHNICAL_INCIDENTS"]},{"email":$ps,"categories":["SECURITY"]}]
  | .service_accounts=["factory-apply"] | .project_bindings=[] | .allowed_human_members=[]
  | .notification_channels=[] | .trigger_sink=null
  | .project_floor={"applies":false,"tier":null,"pi_confidence":"HIGH","rai_min":"MEDIUM_AND_ABOVE","vertex_ai":false,"vertex_enforcement":null,"floors_file":"model-armor/floors.json","reason":"core project; no aiplatform, no generateContent call (02 §3.3)"}
  | .deny_entries=[] | .pab_bindings=[] | .project_org_policies=[] | .project_deny_policies=[]
  | .entitlements=[] | .lien=true
  | .made_elsewhere=[{"item":"Model Armor project floor","file":"n/a","step":"not applicable: no model call in a core project"},
                     {"item":"ENT_PROJECT_REPAIR_CORE, the core repair entitlement, scoped at fld-platform-core","file":"POV 03","step":"PF-5.1"},
                     {"item":"NOTIF_CH_EMAIL_CORE and NOTIF_CH_PAGER_CORE, created in CORE_PROJECT","file":"POV 03","step":"PF-7.3"},
                     {"item":"the other three service accounts of setup/10 CP-8.1 and the build federation (B-01)","file":"setup/10","step":"CP-3 to CP-8"}]
  | .pending=[]' "$PLATFORM_REPO_DIR/factory/runs/_template.json" > "$PLATFORM_REPO_DIR/factory/runs/platform-core-cicd.json"
python3.12 -m json.tool "$PLATFORM_REPO_DIR/factory/runs/platform-core-cicd.json" >/dev/null && echo JSON-OK
jq -r '.module, .create, .run_id' "$PLATFORM_REPO_DIR/factory/runs/platform-core-cicd.json"
diff <(jq -r 'keys[]' "$PLATFORM_REPO_DIR/factory/runs/_template.json") <(jq -r 'keys[]' "$PLATFORM_REPO_DIR/factory/runs/platform-core-cicd.json") && echo "KEY-SET EQUALS TEMPLATE"
comm -3 <(jq -r '.services[]' "$PLATFORM_REPO_DIR/factory/runs/platform-core-cicd.json" | sort) "${R}-services-v1.txt"
```

  Then resolve each difference the reads show, in the build log, one line each. `comm -3` lists the services on one side only: a name enabled but not in the spec is either a dependency file 03's CP-1.6 record classified (b), added to `service_dependencies` with that record's parent, or a service a named 03 step enabled, added to `services` with the step; anything else is disabled under `ENT_PROJECT_REPAIR_CORE` as setup/10 CP-1.6 rules. A non-agent service account holding a project role in the IAM read is added to `project_bindings` with the step that made it, or removed. If the budget read shows `rules` `3`, repair the missing rule to setup/10 CP-1.9's four:

```bash
test "$(date -u +%F)" \< "$BOOTSTRAP_BILLING_EXPIRY" || echo "billing roles expired: the billing administrator runs the next line"
gcloud billing budgets update "$(jq -r '.[0].name' "${R}-budget-v1.json")" --billing-account="$BILLING_ACCOUNT_ID" --add-threshold-rule=percent=100,basis=forecasted-spend --billing-project="$CICD_PROJECT"
```

  `update` takes the budget's id or fully qualified name as its positional argument and `--add-threshold-rule` with `percent` as an **integer between 0 and 100** (unlike `create`, whose `--threshold-rule` percent is 0.0 to 1.0) and `basis` `current-spend` or `forecasted-spend` ([billing budgets update](https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/update), updated 2026-05-27, read 2026-09-16). The repair is `BD-P04-1` (PC-5.1).
- **VERIFY:** setup/17 FM-1.3's VERIFY: `JSON-OK`; the `jq -r` line prints `platform-core`, `false` and `dev-10-cicd` (not FM-1.3's literal, reading 3 above); `KEY-SET EQUALS TEMPLATE`; the build log lists every difference between file 03's records and the live reads with its resolution. The tag read holds `agp-tier` `core` and `agp-tisax-scope` `in`, and `agp-env` `prod` where file 03 created that key (PF-3.3); the labels read equals the spec's ten labels; the accounts read prints only `factory-apply@`; one delete lien; the contacts table shows the two groups and their categories; after a repair, `gcloud billing budgets list --billing-account="$BILLING_ACCOUNT_ID" --billing-project="$CICD_PROJECT" --filter="displayName=\"${BUDGET_DN}\"" --format="yaml(amount,budgetFilter.projects,thresholdRules)"` shows 300, one project and four rules.
- **ROLLBACK:** Delete the uncommitted spec. The budget rule, if added: `gcloud billing budgets update <budget name> --billing-account="$BILLING_ACCOUNT_ID" --threshold-rules-from-file=<the three rules saved from the read> --billing-project="$CICD_PROJECT"` (same reference: the file's rules replace the budget's).
- **EVIDENCE:** The reads and the resolution lines as `<date>-PC-4.2c-cicd-spec-reads-v1`; the spec itself is committed in PC-4.2d. E-05. TISAX 1.3.1.

### PC-4.2d Prove the checker: the register fixture, zero diff on `CICD_PROJECT`, then a deliberate diff (setup/17 FM-1.4)

- **Id:** PC-4.2d
- **WHO:** Platform owner runs; **person 3 reads the four reports and signs them**; the platform owner does not verify their own proof. The commit is merged by two reviewers, neither the platform owner.
- **WHERE:** Shell, `~/.platform-env` sourced; no PAM grant active on `CICD_PROJECT` (an active grant appears in the project policy as a conditional `user:` binding, which `iam.no_human_or_basic_role` counts, as setup/17 FM-2.19 notes for its own probe).
- **ACTION:** Execute setup/17 FM-1.4 **unchanged**. Its block, compressed only by naming the record prefix after this step:

```bash
source ~/.platform-env
need CICD_PROJECT BUILD_LOG_DIR PLATFORM_REPO_DIR PLATFORM_REPO_SLUG REGION BILLING_ACCOUNT_ID LOGGING_PROJECT
checkpoint PC-4.2d START - - "setup/17 FM-1.4 checker proof"
cd "$PLATFORM_REPO_DIR"
git switch -c fm-1-checker-proof
R="$BUILD_LOG_DIR/records/$(date -u +%F)-PC-4.2d"
fmzd() { if python3.12 tools/fm-zero-diff.py "$@"; then echo "exit=0"; else echo "exit=$?"; fi; }
# a) the register fixture: the checker must read 16 RG-2.2's shape and must notice a wrong row
mkdir -p register/fixtures
cat > register/fixtures/fm-zero-diff-row.yaml <<'YAML'
agent_id: fm-fixture
rows:
  - env: prod
    tier: R
    manifest_sha: "0000000000000000000000000000000000000000000000000000000000000000"
    status: draft
    privilege: none
  - env: nonprod
    tier: R
    manifest_sha: "1111111111111111111111111111111111111111111111111111111111111111"
    status: draft
    privilege: none
YAML
jq '.agent_id="fm-fixture" | .env="prod" | .register_tier="R" | .register_row="register/fixtures/fm-zero-diff-row.yaml"' \
  factory/runs/platform-core-cicd.json > "${R}-fixture-spec.json"
fmzd inputs "${R}-fixture-spec.json" --report "${R}-fixture-ok-v1.json"
jq -r '.results[] | select(.check | startswith("row.")) | "\(.status) \(.check) \(.actual)"' "${R}-fixture-ok-v1.json"
jq -r '.results[] | select(.status != "PASS") | "\(.status) \(.check) \(.actual)"' "${R}-fixture-ok-v1.json"
jq '.register_tier="W"' "${R}-fixture-spec.json" > "${R}-fixture-bad.json"
fmzd inputs "${R}-fixture-bad.json" --report "${R}-fixture-bad-v1.json"
jq -r '.results[] | select(.status=="FAIL") | .check' "${R}-fixture-bad-v1.json"
# b) the live proof on CICD_PROJECT, then a deliberate diff
fmzd live factory/runs/platform-core-cicd.json --report "${R}-cicd-live-v1.json"
jq '.labels.env = "nonprod" | .services += ["compute.googleapis.com"]' factory/runs/platform-core-cicd.json > "${R}-negative-spec.json"
fmzd live "${R}-negative-spec.json" --report "${R}-cicd-negative-v1.json"
git add factory/runs/platform-core-cicd.json register/fixtures/fm-zero-diff-row.yaml && git commit -m "factory: platform-core run spec for CICD_PROJECT and the checker's register fixture (setup 17 FM-1.4; POV 04 PC-4.2d)" && git push -u origin fm-1-checker-proof
gh pr create --repo "$PLATFORM_REPO_SLUG" --head fm-1-checker-proof --title "PC-4.2d checker proof: CICD_PROJECT spec and register fixture" --body "setup/17 FM-1.3 and FM-1.4. Reports in the build log under PC-4.2d, signed by person 3."
cd - >/dev/null
```

  setup/17 commits straight to `main` here; the POV's protected branch takes the same two files through a pull request. `inputs` skips the NAMES and project-id form checks when `create` is `false`; `live` is the proof that matters. The `fmzd` wrapper prints the exit code from inside an `if`, so a run that is meant to exit 1 does not end the sitting.

  **What the fixture run can and cannot show in the POV.** Its purpose is the four `row.` checks: the checker reads setup/16 RG-2.2's shape. Beside them it runs every other `inputs` check on the `CICD_PROJECT` spec, including `services.subset_of_folder_allowlist`, which allows a service only if it is on the parent folder's enforced allow-list or is `iam`, `logging` or `monitoring`. `CICD_PROJECT` enables services Google's `gcp.restrictServiceUsage` does not govern, so no allow-list can hold them: Google's supported-services list names neither `cloudresourcemanager.googleapis.com` nor `essentialcontacts.googleapis.com`, `billingbudgets.googleapis.com` or `observability.googleapis.com` ([supported services](https://docs.cloud.google.com/resource-manager/docs/organization-policy/restricting-resources-supported-services), updated 2026-09-09, read 2026-09-16), and setup/13's allow-list table marks the others of the row not governed. That check therefore prints `FAIL` on the unchanged checker, and the fixture run exits 1 where FM-1.4 expects 0. It is a limit of setup/17's code, not a difference on `CICD_PROJECT` and not a register defect: recorded `PENDING` against setup/17's owner with the re-run point "setup/17 FM-1.2 amended", and **the checker is not edited here**. `live` has no allow-list check, so the live proof is unaffected. While file 03 PF-5.3's `fld-platform-core` allow-list is still in dry run, the same check also lists the governed services (the effective policy has no enforced list); the fixture half is then re-run after 03's dated enforcement line is `DONE`.

```bash
printf '%s\tPC-4.2d\tsetup/17 FM-1.2 inputs: services.subset_of_folder_allowlist cannot pass on services gcp.restrictServiceUsage does not govern\tre-run PC-4.2d (a) when setup/17 amends ALWAYS_ALLOWED\tPENDING\tsetup/17 owner\n' "$(date -u +%F)" >> "$BUILD_LOG_DIR/rerun-index.tsv"
```

- **VERIFY:** Four results, read by person 3. (a) The fixture run prints `PASS` on `row.found`, `row.agent_id`, `row.env`, `row.tier` and `row.commit_on_main`; if `row.found` prints `FAIL` with a message about `rows[]`, the checker is not reading setup/16 RG-2.2's format: stop, nothing later trusts it. Its non-`PASS` list holds exactly one line, `FAIL services.subset_of_folder_allowlist`, whose `actual` names only services outside Google's supported list (after 03's core enforcement line), so `exit=1` and the `PENDING` line above is in `rerun-index.tsv`. The bad fixture adds exactly one `FAIL`, `row.tier`, and prints `exit=1`. (b) The `CICD_PROJECT` live run prints `ZERO-DIFF` and `exit=0` **without `--accept-pending`**: every check `PASS`, including `iam.no_human_or_basic_role` (file 03 PF-10.3 removed the creator's Owner) and `logging.default_route`. The negative run prints `DIFF`, `exit=1`, and exactly two `FAIL` lines, `project.labels` and `services.exact`. Any other `FAIL` in (b) is a real difference on `CICD_PROJECT`, repaired under `ENT_PROJECT_REPAIR_CORE` (or by the billing role holder, for a budget) and recorded as a `BD-P04` row, then (b) is re-run; it is never resolved by editing the spec away from file 03's record or by editing the checker. `iam.no_human_or_basic_role` also counts `roles/editor` on the Google APIs Service Agent; Google grants it that role only on a project "created before April 2026" or where the Cloud Deployment Manager API is enabled ([service account types](https://docs.cloud.google.com/iam/docs/service-account-types), updated 2026-09-16, read 2026-09-16), neither of which holds for file 03's projects. Only when (a)'s row checks and both (b) runs behave as stated do files 06, 07 and 08 use the checker. The pull request is merged with two approvals, neither the platform owner's; then `checkpoint PC-4.2d DONE "$SECURITY_REVIEWER_EMAIL" "build-log:records/$(date -u +%F)-PC-4.2d-*" "checker proven: CICD_PROJECT ZERO-DIFF; fixture services check PENDING on setup/17"`.
- **ROLLBACK:** None needed for Google Cloud: nothing was written there. The fixture and spec commit is reverted by pull request.
- **EVIDENCE:** The four reports, signed by person 3, registered with `evidence_add PC-4.2d checker-proof E-05 5.2.4 build-log:records/<file> <file>` once per report. E-05. TISAX 5.2.4 (verification of controls). This is the checker's proof carried into `POV_TIER_R_RECORD` (PC-4.3).

### PC-4.3 Write and merge `POV_TIER_R_RECORD`

- **Id:** PC-4.3
- **WHO:** Platform owner writes and signs; person 2 co-signs; person 3 co-signs.
- **WHERE:** `PLATFORM_REPO_DIR`, `GATES_DIR` (file 03 PF-10.1, the full set's `gates/` home of setup/42 GD-1.1), then the git host.
- **ACTION:** HLD §0.4's Tier R items are factory, folder baseline, central logging and shared registry. Collect the live reads with setup/17 FM-10.1's commands (verified there on 2026-09-15), then write the record with setup/17 FM-10.2's sections. **Differences, stated in the record itself:** the factory item is the hand-built foundation of file 03 under SD-01 and [PV-D-01](09-the-demonstration-deviations-and-the-hand-over.md), with the run-spec template and the zero-diff checker of setup/17 FM-1.1 and FM-1.2 merged unchanged (PC-4.2a, PC-4.2b) and **the checker's proof of PC-4.2d**: `ZERO-DIFF` on `CICD_PROJECT` and the deliberate diff, and the register-fixture run with its `PENDING` line on the allow-list check of the unchanged checker, named in the record; the other four core projects are not checked (setup/17 FM-8.1 is not run in the POV), and no module equivalent has run; the shared-registry item has no standing writer (PC-4.1) and its CI half is the manual parse (PC-3.5); the drift and reconciliation jobs (B-02) are PENDING, with file 03's weekly hand check standing in. **What this record does not satisfy**, written in bold in its first section: setup/17 FM-2.1's precondition for the full build's factory runs (README §7.3: a POV record never satisfies a full-set gate whose conditions it lacks). The record is `POV_TIER_R_RECORD` and never the bare `TIER_R_RECORD`: setup/22, 23 and 31 open with `need TIER_R_RECORD`, and a POV-grade record under that name would let them start without a factory proof. setup/17 FM-10.3 writes the full record and sets `TIER_R_RECORD` itself, with no `--force`, because this file never set it; the full build re-derives the record and does not promote this one by renaming it.

```bash
source ~/.platform-env
need FLD_AGENTIC_PLATFORM LOGGING_PROJECT REGION AGENT_REGISTRY ORG_ID GATES_DIR SECOND_HUMAN_EMAIL
checkpoint PC-4.3 START "$SECOND_HUMAN_EMAIL" - "POV Tier R record: reads and pull request"
R="$BUILD_LOG_DIR/records/$(date -u +%F)-PC-4.3"
gcloud org-policies list --folder="$FLD_AGENTIC_PLATFORM" --format="value(constraint)" | sort > "${R}-org-policies.txt"
gcloud iam policies list --attachment-point="cloudresourcemanager.googleapis.com/folders/${FLD_AGENTIC_PLATFORM}" --kind=denypolicies --format="value(name)" > "${R}-deny.txt"
gcloud logging sinks list --folder="$FLD_AGENTIC_PLATFORM" --format="value(name,destination,includeChildren)" > "${R}-folder-sinks.txt"
gcloud logging buckets list --location="$REGION" --project="$LOGGING_PROJECT" --format="value(name,retentionDays,locked)" > "${R}-buckets.txt"
grep -E '\| [0-9-]+-(PF|PC)-' "$EVIDENCE_REGISTER" | cut -d'|' -f2,4,7 > "${R}-evidence-index.txt"
test -d "$PLATFORM_REPO_DIR/$GATES_DIR" || echo "STOP: $GATES_DIR is not in the platform repository (file 03 PF-10.1)"
F="$GATES_DIR/$(date -u +%F)-pov-tier-r-record-v1.md"
git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only
git -C "$PLATFORM_REPO_DIR" switch -c "pc-4-3-tier-r-record"
"${EDITOR:-vi}" "$PLATFORM_REPO_DIR/$F"
"$PLATFORM_REPO_DIR/tools/decision-check.sh" "$PLATFORM_REPO_DIR/$F"
git -C "$PLATFORM_REPO_DIR" add "$F" && git -C "$PLATFORM_REPO_DIR" commit -m "gates: Tier R record, POV grade (POV 04 PC-4.3; PV-D-01)" && git -C "$PLATFORM_REPO_DIR" push -u origin HEAD
```

  After the merge: `git -C "$PLATFORM_REPO_DIR" switch main && git -C "$PLATFORM_REPO_DIR" pull --ff-only && penv_set POV_TIER_R_RECORD "$F" && checkpoint PC-4.3 DONE "$SECOND_HUMAN_EMAIL" "repo:$F" "POV Tier R record merged"`. `F` is recomputed as above if the merge falls in a later sitting.
- **VERIFY:** Every "Evidence" cell of FM-10.1's table names a record id; the deny read lists `deny-agents-platform`; the folder sink points at `LOGGING_PROJECT`; the buckets `platform-evidence-logs` and `platform-identity-logs` show file 03's retention and lock state; `decision-check.sh` prints `OK` with three signatures; the record's first section carries the "does not satisfy" statement; `need POV_TIER_R_RECORD` is silent; `grep -c '^export TIER_R_RECORD=' "$PLATFORM_ENV_FILE"` prints `0`.
- **ROLLBACK:** A superseding record, never an edit.
- **EVIDENCE:** The reads and the record as `<date>-PC-4.3-tier-r-record-v1`; `evidence_add PC-4.3 tier-r-record E-05 1.4.1 repo:<F>@<sha>`. E-05. TISAX 1.4.1, 5.2.4.

## 5. Close

### PC-5.1 Deviation rows, re-run lines and the end of the sitting

- **Id:** PC-5.1
- **WHO:** Platform owner writes; person 2 initials the build-log commit.
- **WHERE:** Shell; `DEVIATION_REGISTER`; `rerun-index.tsv`.
- **ACTION:** Append one row per deviation this file used, each naming its PV-D id, so file 09's register can cite the step: PC-1.4 and PC-3.5 → PV-D-13; PC-3.3 → PV-D-03, PV-D-04, PV-D-07; PC-1.3 and PC-3.1 → PV-D-08; PC-4.1 and PC-4.3 → PV-D-01; PC-4.2a to PC-4.2d → PV-D-01 (the checker stands in for the factory's plan), and `BD-P04-1` → PV-D-01 only if PC-4.2c repaired `CICD_PROJECT`'s budget rule (repair, date, the rule added, who ran it); PC-1.1 → PV-D-14; PC-3.2 → PV-D-16. Confirm PC-4.2d's `PENDING` line is in `rerun-index.tsv`. Append the re-run lines: B-03 lands → setup/16 RG-3.2 to RG-3.5 and a re-parse of PC-3.5's rows by CI; PB-01 lands → PC-2.4 sets `AUDIT_DDL_COMMIT`; file 07 names control invokers, the third reversible operation pair (PB-04's catalogue), `principal`, `gateway_id`, `armor_template` and `framework_version` → amend PC-3.1 and PC-3.2 by pull request and re-parse; Track B starts → Eve's nonprod row (setup/21, 23 EP-1.3).

```bash
source ~/.platform-env
need DEVIATION_REGISTER BUILD_LOG_DIR
"${EDITOR:-vi}" "$DEVIATION_REGISTER"
git -C "$BUILD_LOG_DIR" add -A && git -C "$BUILD_LOG_DIR" commit -m "registers: POV 04 deviation rows and re-run lines"
for v in REGISTER_PATH REGISTER_SCHEMA_PATH MANIFEST_SCHEMA_PATH AUDIT_SCHEMA_COMMIT LADDER_SCHEMA_COMMIT MO_DDL_COMMIT DOER_REGISTER_ROW DOER_REGISTER_ROW_NONPROD EVE_REGISTER_ROW MO_REGISTER_ROW MANUAL_PARSE_RECORD AGENT_REGISTRY POV_TIER_R_RECORD; do need "$v" && echo "set $v"; done
grep -c '^export AUDIT_DDL_COMMIT=' "$PLATFORM_ENV_FILE"
penv_guard
sitting_end
```

- **VERIFY:** Thirteen `set` lines; `AUDIT_DDL_COMMIT` count is `1` only if PB-01 has landed, otherwise `0` with PC-2.4's BLOCKED line; `sitting_end` prints `SITTING-END OK`.
- **ROLLBACK:** Append-only registers: a superseding row.
- **EVIDENCE:** The build-log commit. E-05. TISAX 1.4.1, 5.2.1.

## Verification checklist for the whole part

- [ ] setup/16 RG-1.1 to RG-2.6 ran unchanged; 18 fixtures green; `REGISTER_PATH`, `REGISTER_SCHEMA_PATH`, `MANIFEST_SCHEMA_PATH` set (PC-1.1).
- [ ] `IMP`, `CTL`, family ids `^F[0-9]+[a-z]?$`, `agent_id` `{1,30}` and `owner_group` `^platform-owners@` merged; the two POV tier fixtures fail as expected (PC-1.2).
- [ ] The reserved names file merged; no `walle`, `WALLE_PROJECT` or `walle_audit` anywhere else in `register/` or `factory/`; `fld-agents-p-sa-prod` holds no project (PC-1.3).
- [ ] `ci/register-rules.md` holds R-01 to R-13; B-03 BLOCKED; RG-3.2 PENDING (PC-1.4).
- [ ] `audit.schema.json` with 38 contract columns, `a_` extension rule and `p:audit_unavailable`; `ladder.schema.json` with the constant `SUPER` and `WRITE_GENERIC` rows and no POV cap; both merged with person 3's approval and a two-signer parse (PC-2.1 to PC-2.3).
- [ ] The doer's `AUDIT_TABLES` (nine) and `actions.json` committed; eight schemas BLOCKED on PB-01 (PC-2.4).
- [ ] Mo's four dataset definitions match NAMES; toil schemas of 22 MO-8.1 merged; `MO_DDL_COMMIT` set (PC-2.5). Eve's schemas BLOCKED on PB-02 (PC-2.6).
- [ ] Four rows merged before any project: the doer's W prod and nonprod with `privilege: none`, Eve's CTL prod, Mo's IMP prod; purposes equal PV-11; manifest hashes match; parse signed by persons 2 and 3 (PC-3.1 to PC-3.5).
- [ ] `AGENT_REGISTRY` set; no standing registry role; the write alert exists; its drill handed to file 05 (PC-4.1, PC-4.2).
- [ ] `factory/runs/_template.json` and `tools/fm-zero-diff.py` on `main`, each byte-equal to its setup/17 extraction and merged by two reviewers who are not the platform owner, person 3 among the checker's (PC-4.2a, PC-4.2b); `factory/runs/platform-core-cicd.json` transcribed from file 03's records with every difference resolved in the build log (PC-4.2c); `live` on `CICD_PROJECT` `ZERO-DIFF` without `--accept-pending`, the deliberate diff exactly two `FAIL`s, the fixture's row checks `PASS` and its allow-list check `PENDING` in `rerun-index.tsv`, all read and signed by person 3 (PC-4.2d).
- [ ] `POV_TIER_R_RECORD` merged in `GATES_DIR` with three signatures and the statement of what it does not satisfy; the bare `TIER_R_RECORD` unset (PC-4.3).
- [ ] Deviation rows and re-run lines committed; `SITTING-END OK` (PC-5.1).

## What the next file needs from this one

| File | Needs | From |
|---|---|---|
| [05](05-gemini-enterprise-and-tier-c.md) | `REGISTER_PATH`, `REGISTER_SCHEMA_PATH`, `MANUAL_PARSE_RECORD` (the parse form for each Tier C row), `AGENT_REGISTRY`, the registry write-alert policy and its re-run line, an entitlement carrying `agentregistry.admin` or the PENDING line, `POV_TIER_R_RECORD` (file 05's Tier C comes after Tier R, SD-13). File 05 PG-7.1a runs the setup/16 RG-5.7 drill and closes PC-4.2's re-run line; file 07 PW-5.4a registers the doer's engine in `AGENT_REGISTRY`; file 05 PG-6.3a records why the two no-code Tier C agents are not registered | PC-1.1, PC-3.5, PC-4.1, PC-4.2, PC-4.3 |
| [06](06-eve-over-the-human-super-admins.md) | `EVE_REGISTER_ROW`; `AUDIT_DDL_COMMIT` and the doer's `AUDIT_TABLES` for §11; PB-02 (Eve's three schemas) as `EVE_SCHEMAS_COMMIT`; the doer-audit topology row confirmed; **the run-spec template `factory/runs/_template.json` and the checker `tools/fm-zero-diff.py`, proven**, from which 06 PE-1.1a writes and merges `factory/runs/eve-prod.json` before `EVE_PROJECT` exists and PE-1.6 runs `live` | PC-2.4, PC-2.6, PC-3.3, PC-4.2a, PC-4.2b, PC-4.2d |
| [07](07-the-doer-tier-w-and-the-optional-tier-p.md) | `DOER_REGISTER_ROW`, `DOER_REGISTER_ROW_NONPROD`, the manifest to amend with invokers, operations and the `pending-07` values; `AUDIT_SCHEMA_COMMIT`, `LADDER_SCHEMA_COMMIT` (the doer's `ladder.yaml` carries `code_rows`); `AUDIT_DDL_COMMIT` once PB-01 lands; the reserved-names file re-asserted as 07's first verification; a Tier P step is a new row and a new `agent_id` through this file's PC-3 form; **the run-spec template and the checker, proven**, from which 07 PW-1.7a writes and merges `factory/runs/<agent_id>-prod.json` and `-nonprod.json` before either project exists and PW-2.2a runs `live` | PC-1.3, PC-2.3, PC-2.4, PC-3.1, PC-3.2, PC-4.2a, PC-4.2b, PC-4.2d |
| [08](08-mo-and-the-value-report.md) | `MO_REGISTER_ROW`, `MO_DDL_COMMIT` (`mo/datasets.json`, toil schemas), `AUDIT_SCHEMA_COMMIT` (Mo's SQL reads 05 §9.4's column names), the two-signer parse form for Mo's first proposal; **the run-spec template and the checker, proven**, from which 08 PM-1.1a writes and merges `factory/runs/mo-prod.json` before `MO_PROJECT` exists and PM-1.5 runs `live` | PC-2.3, PC-2.5, PC-3.4, PC-3.5, PC-4.2a, PC-4.2b, PC-4.2d |
| [09](09-the-demonstration-deviations-and-the-hand-over.md) | The deviation rows of PC-5.1; the fourth-agent test starts from PC-3's form; the hand-over note that setup/31 WD-4.5 reads Wall-E's schemas from its own repository while the POV's live in `<AGENT_ID_DOER>/schemas/` of the platform repository; the checker's proof and its `PENDING` line (PC-4.2d), which 09's run-spec precondition and §6 row 17 cite | PC-2.4, PC-4.2d, PC-5.1 |
| [01](01-conventions-and-variables.md) | this file's reservation and assertion lines between `# names-check: off PV-02` and `# names-check: on`, so `pov-names-check.sh` exits 0 over PC-0.1, PC-1.3, PC-2.5 and PC-3.4 | PC-0.1, PC-1.3, PC-2.5, PC-3.4 |

## Checked against Google's documentation on 2026-09-16

| Fact used | Page |
|---|---|
| Dataset names: up to 1,024 letters, digits and underscores, no hyphens; case-sensitive; location set only at creation; a dataset cannot be renamed | [BigQuery: create datasets](https://docs.cloud.google.com/bigquery/docs/datasets) |
| Column names: letters, digits, underscores, start with a letter or underscore, 300 characters, reserved prefixes `_TABLE_`, `_FILE_`, `_PARTITION` and others; JSON schema fields `name`, `type`, `mode` (NULLABLE, REQUIRED, REPEATED), `fields`; types STRING, TIMESTAMP, INT64, BOOL, JSON, RECORD; columns can later be added or removed (so "never dropped" is a contract rule, not a BigQuery one) | [BigQuery: specify a schema](https://docs.cloud.google.com/bigquery/docs/schemas) |
| Time-unit column partitioning on a TIMESTAMP column with daily granularity | [BigQuery: partitioned tables](https://docs.cloud.google.com/bigquery/docs/partitioned-tables) |
| `--time_partitioning_expiration` in seconds | [Managing partitioned tables](https://docs.cloud.google.com/bigquery/docs/managing-partitioned-tables); [bq reference](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference) |
| Enabling `agentregistry.googleapis.com` is the stated prerequisite; no separate registry resource is described | [Agent Registry setup](https://docs.cloud.google.com/agent-registry/setup) |
| `europe-west1` supported; no manual registration in `us` or `eu` multi-regions | [Agent Registry locations](https://docs.cloud.google.com/agent-registry/locations) |
| `roles/agentregistry.admin`, `.editor`, `.viewer`, `.user`; "avoid granting these roles directly to agents" | [Agent Registry roles and permissions](https://docs.cloud.google.com/agent-registry/roles-permissions) |
| `gcloud agent-registry agents list --location`, GA | [gcloud agent-registry agents list](https://docs.cloud.google.com/sdk/gcloud/reference/agent-registry/agents/list) |
| Model Armor response fields `sanitizationResult.filterMatchState` (`MATCH_FOUND`, `NO_MATCH_FOUND`), `invocationResult`, `filterResults` | [Model Armor: sanitize prompts and responses](https://docs.cloud.google.com/model-armor/sanitize-prompts-responses) |
| `folders.list` returns only the direct children of the parent, never deeper descendants; `projects.list` likewise lists only direct children | [Resource Manager v3 `folders.list`](https://docs.cloud.google.com/resource-manager/reference/rest/v3/folders/list); [Resource Manager v3 `projects.list`](https://docs.cloud.google.com/resource-manager/reference/rest/v3/projects/list) (both updated 2025-06-11) |
| A project's parent is filtered by `parent.type` (`folder` or `organization`) and `parent.id` (the numeric id) | [Resource Manager v3 `projects.search`](https://docs.cloud.google.com/resource-manager/reference/rest/v3/projects/search) (updated 2025-06-11); [gcloud projects list](https://docs.cloud.google.com/sdk/gcloud/reference/projects/list) (updated 2026-05-27) documents `--filter` but gives no parent example |
| `check-jsonschema` latest version 0.38.0 | [PyPI JSON for check-jsonschema](https://pypi.org/pypi/check-jsonschema/json) |
| `gcloud billing budgets update BUDGET --billing-account --add-threshold-rule=[basis=BASIS],[percent=PERCENT]`: `percent` an integer between 0 and 100, `basis` `current-spend` or `forecasted-spend`; `--threshold-rules-from-file` replaces the budget's rules (PC-4.2c) | [gcloud billing budgets update](https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/update) (updated 2026-05-27) |
| `gcp.restrictServiceUsage` supports `bigquery`, `bigquerydatatransfer`, `privilegedaccessmanager`, `firestore`, `cloudtasks`, and does not list `observability`, `cloudresourcemanager`, `essentialcontacts`, `billingbudgets`, `admin` or `agentidentity` (PC-4.2d) | [Supported services for restrict resource usage](https://docs.cloud.google.com/resource-manager/docs/organization-policy/restricting-resources-supported-services) (updated 2026-09-09) |
| The Google APIs Service Agent (`PROJECT_NUMBER@cloudservices.gserviceaccount.com`) holds `roles/compute.instanceGroupManagerServiceAgent` by default; `roles/editor` only if the project "was created before April 2026" or the Cloud Deployment Manager API is enabled (PC-4.2d) | [Types of service accounts](https://docs.cloud.google.com/iam/docs/service-account-types) (updated 2026-09-16) |
| `gcloud beta observability buckets` holds only `describe`, `list` and the `datasets` group: no `create` (the `_Trace` create is REST, setup/10 CP-1.8; files 06, 07 and 08) | [gcloud beta observability buckets](https://docs.cloud.google.com/sdk/gcloud/reference/beta/observability/buckets) (updated 2026-05-27) |

Relied on through the full set, not re-read today: the GitHub REST and CODEOWNERS facts of setup/16
RG-1; `gcloud services list`, `gcloud projects get-iam-policy` and the PAM commands of setup/16
RG-5; `gcloud org-policies list`, `gcloud iam policies list`, `gcloud logging sinks list` and
`gcloud logging buckets list` of setup/17 FM-10.1.

## Unverified, to settle at the step

- Whether `check-jsonschema --check-metaschema` accepts the `x-` annotation keywords of PC-2.1. Writer's check, not evidence: on 2026-09-16 both contract schemas passed the Draft 2020-12 metaschema under the Python `jsonschema` library, and the audit and ladder fixtures of PC-2.1 and PC-2.2 gave the expected results; `check-jsonschema` itself was not run. The PyPI page did not render, so the release date of 0.38.0 was not read.
- The `invocationResult` values beyond `SUCCESS`; the page read documents only `SUCCESS`. The column is STRING, so no enum is committed.
- Whether the `gcloud agent-registry services list` subcommand is still GA under that name (setup/16 read it on 2026-09-15; only `agents list` was re-read today).
- **Design readings, not Google facts**: that 05 §9.4's "`p_` namespace" means its unprefixed column names (PC-2.1); `risk_class: WRITE_HIGH` for a row whose highest family is `WRITE_GENERIC` (PC-3.2); Eve's doer-audit `topology_row: 34` (PC-3.3); retention rows copied from 31 WD-1.3 (PC-3.1); the doer's third operation pair, not yet in the manifest (PC-3.1). Each is marked Assumption at its step and settled by person 3 in the parse.
- **setup/17 as run unchanged in PC-4.2a to PC-4.2d, where its text and its code disagree with each other or with Google**, each left for setup/17's owner and not corrected in the POV: (1) FM-1.3's VERIFY prints `run_id` `dev-10-core-cicd`, while its own rule ("the label 10 wrote") and setup/10 CP-1.1 give `dev-10-cicd`; PC-4.2c follows the rule. (2) The checker's `ALWAYS_ALLOWED` holds `iam`, `logging` and `monitoring` only, so `inputs` prints `FAIL` on `services.subset_of_folder_allowlist` for every service the constraint does not govern, and FM-1.4's fixture run and FM-2.1's `inputs` VERIFY cannot print `ZERO-DIFF` on a project that enables one; PC-4.2d records it `PENDING`, and files 06 to 08 read that one check by its `actual` value. (3) FM-2.9 creates `_Trace` with `gcloud beta observability buckets create`, a command Google's reference does not have; files 06 to 08 use setup/10 CP-1.8's REST call. (4) setup/22 MO-2.1 and setup/23 EP-2.1 write `service_accounts` as `{id, why}` objects, add keys the template lacks, and setup/23 names a project organisation policy's values `denied_values`, while FM-1.1's template and FM-1.2's checker read `service_accounts` as plain strings and the policy's values as `denied`; the POV's specs use FM-1.1's shape, which the unchanged checker reads.
- Evidence ids for this file's register work: PC-1.2 records E-05 because its evidence is the merge commit of a schema amendment, which is contract documentation; a fixture run on its own carries no E-xx id, following setup/01 §7.2's rule that a CI result carries E-15 only when it is an Article 50 content test ([../10-eu-ai-act.md](../10-eu-ai-act.md) §5). setup/16 RG-2.5 and RG-3 follow the same rule.

## Sources

- Full set: [setup/16](../setup/16-register-and-shared-registry.md) RG-1 to RG-3, RG-5, RG-9; [setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md) §1 (FM-1.1 to FM-1.4), FM-2.9, FM-2.21, §10; [setup/10](../setup/10-core-projects-and-ci-identities.md) CP-1.1, CP-1.6, CP-1.8, CP-1.9, CP-1.10; [setup/13](../setup/13-organisation-policies-deny-and-pab.md) "The allow-lists" table; [setup/22](../setup/22-mo-foundations.md) MO-1.1, MO-1.3, MO-6.3, MO-8.1; [setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-1.1, EP-1.3; [setup/31](../setup/31-wall-e-project-and-data-plane.md) WD-1.1, WD-1.3, WD-4.4, WD-4.5; [setup/03](../setup/03-decisions-and-people.md) DC-5.1 (NAMES); [setup/README](../setup/README.md) §5.
- Design: [../01-hld.md](../01-hld.md) lines 90 to 92, §0.4, §12.3; [../02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §1.5, §3.5; [../05-registry-and-autonomy-contract.md](../05-registry-and-autonomy-contract.md) §3.2, §4, §9.1 to §9.6; [../07-monitoring-detection-incident-response.md](../07-monitoring-detection-incident-response.md) §8 RP-1; [../10-eu-ai-act.md](../10-eu-ai-act.md) §5; [../11-tisax.md](../11-tisax.md) §13; [../../wall-e/03-lld.md](../../wall-e/03-lld.md) "Storage"; [../../project-topology.md](../../project-topology.md).
- POV: [README](README.md) §6.2 (step prefixes), §7.2 (full-set names), §7.3 (a POV record never satisfies a full-set gate), §8 (PB-01, PB-02); [09](09-the-demonstration-deviations-and-the-hand-over.md) (PV-D-01, 03, 04, 07, 08, 13, 14, 16).
- Google pages as listed in the table above, all read 2026-09-16.
