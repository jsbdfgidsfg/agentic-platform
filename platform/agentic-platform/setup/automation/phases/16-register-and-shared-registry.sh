# phases/16-register-and-shared-registry.sh: setup/16, the register as files with schemas, its CI
# rules (specified; the code is BLOCKED), the git host set so machines cannot approve, the shared
# Agent Registry in CORE_PROJECT, the row-36 drift identity and the job contract.
#
# How the page maps onto the classes:
# - Every step whose substance is a file the page writes with a heredoc (CODEOWNERS lines, the named-
#   human list, the five schemas, the registry write alert, the expected-principal file, the job
#   contract) is HUMAN: the script does not retype a page's heredoc (lib/PHASES.md, "Files copied from
#   a page"), and each of those steps also ends in a pull request two humans approve. With assets/ and
#   a 16.manifest for those bodies, RG-5.6 in particular could become AUTO.
# - Every pull request, review, signature and hand-written fixture is HUMAN.
# - The Cloud work (the repair grants, the registry IAM, the dataset and its WRITER, the row-36
#   bindings) and the deviation rows are AUTO. RG-5.2 and RG-7.2 request a grant whose approver the
#   page's WHO names as the second human, so they are --witness; RG-6.2 replaces the dataset's whole
#   access list (bq update --source), so --removes. The gate reads, the folder comparison, the registry
#   IAM and audit reads and the row-36 role read are AUTO-READ, and change nothing but their own
#   record and its evidence line (records/ exists from setup/01).
# - The git host and the package index, phase 03's rule: a step that runs `gh` or a git network
#   command is HUMAN, run by the platform owner signed in to `gh` as themselves (RG-1.1, RG-1.3,
#   RG-9.3). RG-2.1's pipx and pip installs fetch from PyPI and are HUMAN for the same reason. The
#   offline tests (tests/run-tests.sh) have no `gh`, `pipx` or `pip` fake: as AUTO these steps would
#   reach github.com and PyPI during the tests. Once tests/fake-bin has those fakes and preflight
#   checks for `gh`, RG-1.3 (--witness) and RG-2.1 can become AUTO again.
# - RG-0.1 is a pure verification, as the page now writes it: PLATFORM_REPO_SLUG is 03 DC-9.2's value and
#   PLATFORM_REPO_REMOTE must be https://github.com/<slug>.git; the securitycenter re-run line is RG-10.1's.
#   The page's `checkpoint RG-0.1 START` is the sitting's own line (agp-platform sitting start); its
#   `git switch main` and `git pull --ff-only` are the owner's (a git network command), and RG-0.1 stops
#   unless the clone is on main and not behind origin/main.
# - The rule code (B-03), the jobs (B-02) and row 44 (B-23) are BLOCKED.
# - The page's own helpers exists_or_pending and bd_insert write the re-run index and the deviation
#   register; they run through `x` like every other change. RG-10.1 removes nothing and is not --removes:
#   the runner's guard reads a removal verb only as a whole argument, so BD-16-4's row text passes.
# - RG-10.1's README re-run and BLOCKED index edits are hand edits to the wiki, RG-10.2's first action on the page.
#
# Helpers are prefixed _p16_ because every phase file is loaded into the same shell.

phase 16 "The register, its CI rules and the shared registry" "16-register-and-shared-registry.md"

P16_REPAIR_WHY="setup 16 RG-5.3 to RG-7.3: registry IAM on CORE_PROJECT (P71) and row 36 project roles"

# ---------------------------------------------------------------- helpers
_p16_today() { date -u +%Y-%m-%d; }
_p16_plan()  { [ "$AGP_MODE" = apply ] || printf '      %s\n' "$*" >&3; }
_p16_recs()  { printf '%s/records' "$(v BUILD_LOG_DIR)"; }
_p16_venvpy() { printf '%s/platform/venv-register/bin/python' "$HOME"; }

_p16_record() { # STEP SLUG E-ID TISAX EXT: standard input saved as records/<date>-STEP-SLUG-v1.EXT and registered
  local d f; d="$(_p16_recs)"; f="$d/$(_p16_today)-$1-$2-v1.$5"
  if [ "$AGP_MODE" = apply ] && [ ! -d "$d" ]; then echo "STOP: $d does not exist (setup/01 creates it)"; cat > /dev/null; return 1; fi
  xw "$f" 644 || return 1
  [ "$3" = - ] || ev "$1" "$2" "$3" "$4" "build-log:records/$(basename "$f")" "$f"
}

_p16_eop_rc() {  # exists_or_pending ARGS...: run under x; keeps its answer in P16_EOP_RC and returns 0 for EXISTS (0) and
  # PENDING (1, a line recorded in rerun-index.tsv), so that x logs a recorded PENDING as the success it is; 2 stays a failure
  "$@"; P16_EOP_RC=$?
  [ $P16_EOP_RC -le 1 ]
}

_p16_pending() { # STEP MEMBER WHAT: the page's exists_or_pending --pending (a principal made later), through x
  x _p16_eop_rc exists_or_pending --pending "$2" "$1" "$3"
}

_p16_py() { python3 -c "$1" "${@:2}"; }

_p16_sleep() {  # SECONDS: a poll interval, multiplied by AGP_WAIT_SCALE (a whole number, 1 when unset; 0 in the tests)
  local f="${AGP_WAIT_SCALE:-1}"
  case "$f" in ''|*[!0-9]*) f=1;; esac
  sleep $(($1 * f))
}

# _p16_pre CMD...: a read inside _apply that decides whether to create (the step's own check, repeated).
# It is marked as a check for the offline fakes, which otherwise answer every read inside apply as "present".
_p16_pre() { AGP_CALL_CONTEXT=check "$@"; }

_p16_grant_has() {  # ENTITLEMENT FILTER: a grant the caller created on it matches FILTER
  nonempty r gcloud pam grants search --entitlement="$1" --caller-relationship=had-created \
    --filter="$2" --format='value(name)' --billing-project="$(v CICD_PROJECT)"
}

_p16_grant() {  # ENT_NAME SECONDS JUSTIFICATION: an ACTIVE grant of the caller (12's pam_request form), requested once and awaited
  local ent rc i=0
  ent="$(v "$1")"
  if [ "$AGP_MODE" != apply ]; then
    x gcloud pam grants create --entitlement="$ent" --requested-duration="${2}s" --justification="$3" \
      --billing-project="$(v CICD_PROJECT)" --format='value(name)'
    _p16_plan "then waits until the second human approves (state ACTIVE); nothing privileged runs before"
    return 0
  fi
  _p16_pre _p16_grant_has "$ent" 'state=ACTIVE'; rc=$?
  if [ $rc -eq 0 ]; then echo "an ACTIVE grant on $1 exists; not requested again"; return 0; fi
  [ $rc -eq 1 ] || return 2
  _p16_pre _p16_grant_has "$ent" 'state=APPROVAL_AWAITED OR state=SCHEDULED OR state=ACTIVATING'; rc=$?
  case $rc in
    0) echo "a grant on $1 is already waiting for approval; not requested again";;
    1) x gcloud pam grants create --entitlement="$ent" --requested-duration="${2}s" --justification="$3" \
         --billing-project="$(v CICD_PROJECT)" --format='value(name)' || return 1;;
    *) return 2;;
  esac
  echo "waiting for the second human's approval (up to 15 minutes)"
  while [ $i -lt 30 ]; do
    if _p16_grant_has "$ent" 'state=ACTIVE'; then echo "STATE ACTIVE"; return 0; fi
    i=$((i + 1)); _p16_sleep 30
  done
  echo "STOP: the grant on $1 is not ACTIVE after 15 minutes; when it is approved, resume from this step"
  return 1
}

_p16_under_grant() {   # the steps after RG-5.2: reuse its ACTIVE grant; request one only when none is active (a fresh one, RG-6.1)
  if [ "$AGP_MODE" != apply ]; then _p16_plan "under the ACTIVE ENT_PROJECT_REPAIR_CORE grant of RG-5.2 (requested again, in RG-5.2's form, only when none is active)"; return 0; fi
  _p16_grant ENT_PROJECT_REPAIR_CORE 3600 "$P16_REPAIR_WHY"
}

_p16_pending_has() {    # STEP MEMBER: a PENDING line for MEMBER written by STEP in the re-run index
  [ -f "$(v BUILD_LOG_DIR)/rerun-index.tsv" ] && grep -qF "	$1	$2	" "$(v BUILD_LOG_DIR)/rerun-index.tsv"
}

_p16_bound_or_pending() {   # STEP MEMBER ROLE CMD...: the binding exists, or exists_or_pending recorded MEMBER as PENDING
  local st="$1" m="$2" role="$3" rc; shift 3
  has_binding "$m" "$role" "$@"; rc=$?
  [ $rc -eq 1 ] || return $rc
  _p16_pending_has "$st" "$m"
}

_p16_core_policy() { gcloud projects get-iam-policy "$(v CORE_PROJECT)"; }

_p16_eop_bind() {   # STEP MEMBER WHAT -- CMD...: exists_or_pending, then the grant only when the member exists
  local st="$1" m="$2" w="$3" rc; shift 4
  P16_EOP_RC=0      # plan mode: x prints and runs nothing, so the grant is printed too
  x _p16_eop_rc exists_or_pending "$m" "$st" "$w" || P16_EOP_RC=2
  rc=$P16_EOP_RC
  case $rc in
    0) x "$@";;
    1) return 0;;
    *) echo "STOP: exists_or_pending could not tell whether $m exists; read the error above"; return 1;;
  esac
}

# ---------------------------------------------------------------- 0. The sitting

step RG-0.1 AUTO-READ "Open the sitting and check the gates" --gate "SD-02 SD-09 SD-14 SD-18 SD-34 SD-36 NAMES" \
  --needs "SA_1_ADMIN GIT_HOST PLATFORM_REPO_REMOTE PLATFORM_REPO_SLUG PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER DRILL_CALENDAR SECOND_HUMAN_EMAIL ORG_ID REGION BQ_LOCATION DOMAIN CORE_PROJECT CORE_PROJECT_NUMBER CICD_PROJECT SA_FACTORY_APPLY SA_PLATFORM_DRIFT SA_WALLE_DEPLOYER FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE ROSTER_FILE CONTROL_GROUPS_FILE GRP_PLATFORM_READERS GRP_EVE_OWNERS ENT_PROJECT_REPAIR_CORE ENT_FOLDER_ADMIN ENT_DEPLOY_CREDENTIAL_HOLDER_CORE"
_p16_svc_on() {   # API: 0 when API.googleapis.com is enabled on CORE_PROJECT (a filtered list), 1 not, 2 error, 3 offline
  nonempty r gcloud services list --enabled --project="$(v CORE_PROJECT)" --filter="config.name=$1.googleapis.com" --format="value(config.name)"
}
s_RG_0_1_check() { ckpt_done RG-0.1; }
s_RG_0_1_apply() {
  local repo slug acct list n users sr br behind api rc bad=0
  repo="$(v PLATFORM_REPO_DIR)"
  if [ "$AGP_MODE" != apply ]; then
    _p16_plan "reads (nothing is changed: the sitting's START line is agp-platform sitting start's): penv_guard;"
    _p16_plan "PLATFORM_REPO_SLUG (03 DC-9.2) is owner/name and PLATFORM_REPO_REMOTE is https://github.com/<slug>.git;"
    _p16_plan "GIT_HOST is GitHub; the active account is SA_1_ADMIN; the clone is on main and not behind origin/main"
    _p16_plan "(the page's 'git switch main && git pull --ff-only' is yours to run before this apply: the script runs no git"
    _p16_plan "network command); register/folders.yaml is not empty;"
    _p16_plan "the eight core APIs enabled on CORE_PROJECT (securitycenter: RG-10.1 writes the re-run line when absent); no user"
    _p16_plan "member on CORE_PROJECT; whether SECURITY_REVIEWER_EMAIL is set"
    _p16_record RG-0.1 core-apis E-05 5.2.1 txt < /dev/null
    return 0
  fi
  # every read runs, so that one sitting shows every stop at once
  penv_guard || { echo "STOP: penv_guard failed"; bad=1; }
  slug="$(v PLATFORM_REPO_SLUG)"
  case "$slug" in
    */*/*|*:*|*@*|/*|*' '*) echo "STOP: PLATFORM_REPO_SLUG is '$slug', not owner/name: re-read 03 DC-9.2"; bad=1;;
    */*) if [ "$(v PLATFORM_REPO_REMOTE)" = "https://github.com/$slug.git" ]; then echo "PLATFORM_REPO_SLUG=$slug (03 DC-9.2); the remote matches"
         else echo "STOP: PLATFORM_REPO_REMOTE is '$(v PLATFORM_REPO_REMOTE)', not https://github.com/$slug.git (03 DC-9.5's form): settle which is right in 03"; bad=1; fi;;
    *) echo "STOP: PLATFORM_REPO_SLUG is '$slug', not owner/name: re-read 03 DC-9.2"; bad=1;;
  esac
  case "$(v GIT_HOST)" in github.com|GitHub|github) ;; *) echo "STOP: git host '$(v GIT_HOST)' is not GitHub: 03 section 12.1 re-issue"; bad=1;; esac
  acct="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)"
  [ "$acct" = "$(v SA_1_ADMIN)" ] || { echo "STOP: signed in as '$acct', not sa-1-admin@"; bad=1; }
  br="$(r git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  if [ "$br" != main ]; then
    echo "STOP: the clone is on '$br', not main. Run the page's: git -C \"$repo\" switch main && git -C \"$repo\" pull --ff-only"
    echo "  (yours, signed in as yourself: the script runs no git network command); then resume"; bad=1
  elif behind="$(r git -C "$repo" rev-list --count HEAD..origin/main 2>/dev/null)"; then
    [ "$behind" = 0 ] || { echo "STOP: main is $behind commits behind origin/main: run git -C \"$repo\" pull --ff-only, then resume"; bad=1; }
    echo "REVIEW: origin/main is as of your last fetch; the page pulls here, so pull before this apply if you have not"
  else
    echo "REVIEW: no origin/main in the clone to compare with: run git -C \"$repo\" pull --ff-only before this apply"
  fi
  [ -s "$repo/register/folders.yaml" ] || { echo "STOP: register/folders.yaml missing: 09 FS-4.2 first"; bad=1; }
  # The page greps one unfiltered listing; the script asks for each service with a filtered list (lib/PHASES.md rule 4),
  # and records the names it found, as the page's tee does.
  list=""; n=0
  for api in agentregistry apphub bigquery run cloudscheduler cloudasset policyanalyzer monitoring; do
    _p16_svc_on "$api"; rc=$?
    case $rc in
      0) list="$list$api.googleapis.com
"; n=$((n + 1));;
      1) echo "STOP: $api.googleapis.com is not enabled on CORE_PROJECT: re-run 10 CP-1.6 for that project"; bad=1;;
      *) echo "STOP: cannot list CORE_PROJECT's services"; bad=1;;
    esac
  done
  printf '%s' "$list" | sort | _p16_record RG-0.1 core-apis E-05 5.2.1 txt || return 1
  echo "core APIs enabled: $n of 8"
  _p16_svc_on securitycenter \
    || echo "NOTE: securitycenter.googleapis.com is not enabled on CORE_PROJECT (needed from RG-8.2): RG-10.1 writes the page's re-run line for 10 CP-1.6"
  # the page's --flatten/--filter read, made on the whole policy as JSON so the answer does not rest on gcloud's filter
  users="$(r gcloud projects get-iam-policy "$(v CORE_PROJECT)" --format=json | _p16_py 'import json,sys
for b in json.load(sys.stdin).get("bindings", []) or []:
    for m in b.get("members", []):
        if m.startswith("user:"): print("%s\t%s" % (b.get("role"), m))')" || { echo "STOP: CORE_PROJECT's IAM policy does not read"; bad=1; }
  [ -z "$users" ] || { printf '%s\n' "$users"; echo "STOP: a user member holds a role on CORE_PROJECT (12 removes the creator's Owner)"; bad=1; }
  sr="$(_penv_get SECURITY_REVIEWER_EMAIL)"
  printf 'SECURITY_REVIEWER_EMAIL=%s   (write it in the build-log note: it decides the reviewer of RG-1.2 and RG-3.6)\n' "${sr:-*tbd*}"
  return $bad
}

# ---------------------------------------------------------------- 1. The repository

step RG-1.1 HUMAN "Read the control paths against CODEOWNERS" \
  --needs "ROSTER_FILE CONTROL_GROUPS_FILE PLATFORM_REPO_SLUG PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_RG_1_1_check() { ckpt_done RG-1.1; }
s_RG_1_1_manual() {
  echo "WHO: the platform owner, signed in to gh as themselves (a git-host read: HUMAN under phase 03's rule)."
  echo "WHERE: a shell in $(v PLATFORM_REPO_DIR) with ~/.platform-env sourced."
  echo "DO: run RG-1.1's block of setup/16 as written: CODEOWNERS, the two control files, gh api codeowners/errors, the"
  echo "  collaborator listing tee'd to records/<date>-RG-1.1-collaborators-v1.tsv (the only source of a login for RG-1.2"
  echo "  and RG-1.4), the organisation read, the tree."
  echo "VERIFY: codeowners/errors prints 0; identity/super-admin-roster.json and identity/control-groups.json are covered only"
  echo "  by '*' (add any other uncovered control file to RG-1.2's list); User rows for the platform owner, the second human"
  echo "  and the second operator; write whether the organisation uses Enterprise Managed Users in the note."
  echo "Evidence: <date>-RG-1.1-codeowners-gap-v1. Then: agp-platform done RG-1.1 --note \"EMU: yes|no\""
}

step RG-1.2 HUMAN "Extend CODEOWNERS" --needs "SECOND_HUMAN_EMAIL PLATFORM_REPO_SLUG PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_RG_1_2_check() { ckpt_done RG-1.2; }
s_RG_1_2_manual() {
  echo "WHO: the platform owner writes; the second human approves as code owner of /.github/; a second human reviewer."
  echo "WHERE: the tenant shell, then the git host."
  echo "DO: run RG-1.2's block of setup/16 with SH_LOGIN and SR_LOGIN replaced by logins from RG-1.1's collaborator file"
  echo "  (never an email address); it appends five CODEOWNERS lines on branch rg-1-2-codeowners, reads codeowners/errors on"
  echo "  the branch, and opens the pull request. The script does not retype the page's heredoc."
  echo "VERIFY: the branch errors read prints []; after the merge the errors length is 0 and the approvals include SH_LOGIN."
  echo "  RG-1.2 reads RG-1.1's file under today's date: run both on the same day, or point it at RG-1.1's dated file."
  echo "Evidence: <date>-RG-1.2-codeowners-merge-v1. Then: agp-platform done RG-1.2"
}

step RG-1.3 HUMAN "GitHub Actions may not approve pull requests" --witness --note "the second human confirms the organisation setting" \
  --needs "PLATFORM_REPO_SLUG BUILD_LOG_DIR"
s_RG_1_3_check() { ckpt_done RG-1.3; }
s_RG_1_3_manual() {
  echo "WHO: the platform owner as repository administrator, signed in to gh as themselves; the second human confirms the"
  echo "  organisation setting. HUMAN under phase 03's rule (a gh write; the offline tests have no gh fake)."
  echo "WHERE: a shell with gh and ~/.platform-env sourced."
  echo "DO: run RG-1.3's block of setup/16 as written: the before read of repos/$(v PLATFORM_REPO_SLUG)/actions/permissions/workflow"
  echo "  (kept for the rollback), the PUT with default_workflow_permissions=read and can_approve_pull_request_reviews=false,"
  echo "  and the organisation read. If the organisation prints true, the second human asks its owner to set it to false."
  echo "VERIFY: the repository read prints 'read<TAB>false'; the organisation read prints false."
  echo "Evidence: both reads as <date>-RG-1.3-actions-cannot-approve-v1."
  echo "Then: agp-platform done RG-1.3 --witness <second human's email>"
}

step RG-1.4 HUMAN "Commit the named-human list and the machine-account list" --needs "PLATFORM_REPO_DIR PLATFORM_REPO_SLUG BUILD_LOG_DIR"
s_RG_1_4_check() { ckpt_done RG-1.4; }
s_RG_1_4_manual() {
  echo "WHO: the platform owner writes; the second human approves (code owner of /identity/)."
  echo "WHERE: the tenant shell, then the git host."
  echo "DO: run RG-1.4's block of setup/16 (branch rg-1-4-git-humans, the collaborator listing, identity/git-humans.yaml);"
  echo "  replace every <...> known today from its record (logins from the listing, appointment records); principals not yet"
  echo "  created stay as written (re-run by 22 and 40). Commit, push and open the pull request as in RG-1.2."
  echo "VERIFY: every humans[].login is a User collaborator with its appointment record; no machine_accounts login holds more"
  echo "  than read; merged with the second human's approval. Evidence: <date>-RG-1.4-git-humans-v1 (E-08)."
  echo "Then: agp-platform done RG-1.4"
}

# ---------------------------------------------------------------- 2. The schemas

step RG-2.1 HUMAN "Install the schema checker" --needs "BUILD_LOG_DIR"
s_RG_2_1_check() { ckpt_done RG-2.1; }
s_RG_2_1_manual() {
  echo "WHO: the platform owner. WHERE: the macOS terminal."
  echo "DO: run RG-2.1's block of setup/16 as written: pipx install check-jsonschema==0.38.0; python3.12 -m venv"
  echo "  \"\$HOME/platform/venv-register\"; its pip install PyYAML==6.0.3; the two version lines appended to"
  echo "  $(v BUILD_LOG_DIR)/records/tools.txt. HUMAN because both installs fetch from PyPI and the offline tests have no"
  echo "  pipx or pip fake; RG-4.1 reads register/folders.yaml with this venv's python."
  echo "VERIFY: the two lines print 0.38.0 and 'PyYAML 6.0.3'."
  echo "Evidence: the appended tools.txt lines (E-05). Then: agp-platform done RG-2.1"
}

step RG-2.2 HUMAN "Write the register-row schema" --needs "PLATFORM_REPO_DIR"
s_RG_2_2_check() { ckpt_done RG-2.2; }
s_RG_2_2_manual() {
  echo "WHO: the platform owner writes; the security reviewer (the second human until appointed) reviews in RG-2.6."
  echo "WHERE: the tenant shell, $(v PLATFORM_REPO_DIR), branch rg-2-schemas."
  echo "DO: run RG-2.2's block of setup/16 as written (switch -c rg-2-schemas, the directories, the"
  echo "  register/schema/register-row.schema.json heredoc, json.tool, check-jsonschema --check-metaschema)."
  echo "  The script does not retype the page's heredoc."
  echo "VERIFY: 'schema parses'; the metaschema check passes. Evidence: through RG-2.6."
  echo "Then: agp-platform done RG-2.2"
}

step RG-2.3 HUMAN "Write the agent-manifest schema" --needs "PLATFORM_REPO_DIR"
s_RG_2_3_check() { ckpt_done RG-2.3; }
s_RG_2_3_manual() {
  echo "WHO: the platform owner writes; the security reviewer (or the second human) reviews in RG-2.6."
  echo "WHERE: the tenant shell, branch rg-2-schemas."
  echo "DO: run RG-2.3's block of setup/16 as written (contract/1.0.0/manifest.schema.json heredoc; check-jsonschema"
  echo "  --check-metaschema). The script does not retype the page's heredoc."
  echo "VERIFY: the metaschema check passes; 05 section 9.2's example validates in RG-2.5. Evidence: through RG-2.6."
  echo "Then: agp-platform done RG-2.3"
}

step RG-2.4 HUMAN "Write the folders, operators and models schemas, and register/models.yaml" --needs "PLATFORM_REPO_DIR"
s_RG_2_4_check() { ckpt_done RG-2.4; }
s_RG_2_4_manual() {
  echo "WHO: the platform owner writes; the security reviewer (or the second human) reviews in RG-2.6."
  echo "WHERE: the tenant shell, branch rg-2-schemas."
  echo "DO: run RG-2.4's block of setup/16 as written (three schema heredocs and register/models.yaml); then add one row per"
  echo "  location for MODEL_ID from 03's signed WDEC-6 / SD-09 record, copied by hand from Google's page with its read date"
  echo "  (no row while MODEL_ID is *tbd*)."
  echo "VERIFY: RG-2.4's VERIFY block: three metaschema passes; folders.yaml and models.yaml validate. Evidence: through RG-2.6."
  echo "Then: agp-platform done RG-2.4"
}

step RG-2.5 HUMAN "Write the schema fixtures and prove each one" --needs "PLATFORM_REPO_DIR"
s_RG_2_5_check() { ckpt_done RG-2.5; }
s_RG_2_5_manual() {
  echo "WHO: the platform owner."
  echo "WHERE: the tenant shell, branch rg-2-schemas, an editor."
  echo "DO: write the 18 fixture files of RG-2.5's table by hand (three pass-* from 05 section 3.2 and SD-02, the 9.2 example"
  echo "  verbatim; each fail-* a copy of its parent with exactly one change); git status lists 18 new files and nothing else."
  echo "  Then run RG-2.5's check block (the 14/3/1 count assertion and the loops)."
  echo "VERIFY: 18 lines, each PASS-OK or FAIL-OK, four PASS-OK, no WRONG; each failure names the field the table names."
  echo "Evidence: the run output as <date>-RG-2.5-schema-fixtures-v1. Then: agp-platform done RG-2.5"
}

step RG-2.6 HUMAN "Merge the schemas and record the paths" --needs "PLATFORM_REPO_DIR PLATFORM_REPO_SLUG" --sets "REGISTER_PATH MANIFEST_SCHEMA_PATH"
s_RG_2_6_check() { ckpt_done RG-2.6; }
s_RG_2_6_manual() {
  echo "WHO: the platform owner opens; the security reviewer approves as code owner (the second human until appointed); a second"
  echo "  human reviewer as protection requires."
  echo "DO: RG-2.6's first block of setup/16 (add, commit, push rg-2-schemas, gh pr create with RG-2.5's record id); after the"
  echo "  merge, its second block: switch main, pull --ff-only, and"
  echo "RECORD: penv_set REGISTER_PATH \"register\"; penv_set MANIFEST_SCHEMA_PATH \"contract/1.0.0/manifest.schema.json\""
  echo "VERIFY: need REGISTER_PATH MANIFEST_SCHEMA_PATH; paths-ok; two human approvals including the code owner."
  echo "Evidence: <date>-RG-2.6-schemas-merge-v1 (E-05). Then: agp-platform done RG-2.6"
}

# ---------------------------------------------------------------- 3. The CI rules

step RG-3.1 HUMAN "Commit the rule specification" --needs "PLATFORM_REPO_DIR PLATFORM_REPO_SLUG"
s_RG_3_1_check() { ckpt_done RG-3.1; }
s_RG_3_1_manual() {
  echo "WHO: the platform owner writes; the security reviewer approves as code owner of /ci/ (the second human until appointed)."
  echo "DO: RG-3.1's block of setup/16 (branch rg-3-rules; ci/register-rules.md holding exactly the table R-01 to R-12; commit,"
  echo "  push, gh pr create)."
  echo "VERIFY: grep -c '^| R-' ci/register-rules.md prints 12; the code owner approved; the reviewer states that R-02, R-03"
  echo "  and R-04 read SD-02 exactly. Evidence: <date>-RG-3.1-rules-spec-v1."
  echo "Then: agp-platform done RG-3.1"
}

step RG-3.2 HUMAN "Write the rule fixtures" --needs "PLATFORM_REPO_DIR"
s_RG_3_2_check() { ckpt_done RG-3.2; }
s_RG_3_2_manual() {
  echo "WHO: the platform owner writes; the same reviewers as RG-3.1."
  echo "WHERE: branch rg-3-fixtures."
  echo "DO: one directory register/fixtures/rules/<fixture>/ per fixture named in RG-3.1 (24), with the files the rule reads"
  echo "  and expect.txt (pass, or fail: <rule id>); every register file in a fixture passes the schema."
  echo "VERIFY: 24 directories; grep -L . register/fixtures/rules/*/expect.txt prints nothing; the schema loop prints only PASS-OK."
  echo "Evidence: <date>-RG-3.2-rule-fixtures-v1. Then: agp-platform done RG-3.2"
}

step RG-3.3 BLOCKED "Implement the register CI" --note "B-03: register CI code"
s_RG_3_3_check() { ckpt_done RG-3.3; }
s_RG_3_3_manual() {
  echo "BLOCKED on README B-03: R-01 to R-10 and R-12 in ci/register/ with .github/workflows/register-ci.yml (pull_request and"
  echo "  pull_request_review; permissions contents: read, pull-requests: read; actions pinned by SHA; every fixture first)."
  echo "  RG-3.6's signed manual parse is in force meanwhile. Unblocked by REGISTER_CI_COMMIT with green CI."
}

step RG-3.4 BLOCKED "Make the checks required" --note "B-03: needs RG-3.3"
s_RG_3_4_check() { ckpt_done RG-3.4; }
s_RG_3_4_manual() {
  echo "BLOCKED on README B-03 (needs RG-3.3's check names). When unblocked: RG-3.4's block of setup/16 reads the current"
  echo "  required checks into a record, merges the three new contexts and PATCHes the merged list (the PATCH replaces the"
  echo "  stored list); the second human witnesses; the diff against the before file prints nothing."
}

step RG-3.5 BLOCKED "Negative tests on the git host" --note "B-03: needs RG-3.3, RG-3.4"
s_RG_3_5_check() { ckpt_done RG-3.5; }
s_RG_3_5_manual() {
  echo "BLOCKED on README B-03 (needs RG-3.3 and RG-3.4). When unblocked: the six negative pull requests and the one positive"
  echo "  test of RG-3.5, each closed unmerged with its branch deleted; each negative one shows its check failed and BLOCKED."
}

step RG-3.6 HUMAN "The signed manual parse while the rules are BLOCKED" --needs "PLATFORM_REPO_DIR PLATFORM_REPO_SLUG"
s_RG_3_6_check() { ckpt_done RG-3.6; }
s_RG_3_6_manual() {
  echo "WHO: for a P-SA row, a gate checklist, a stage-0 record, a ladder raise or contract/: the security reviewer and the"
  echo "  second human, each separately; otherwise the second human until the security reviewer is appointed. Never the owner."
  echo "DO: RG-3.6's reading aid of setup/16 (venv python over register/*.yaml) and its gh pr view block with PR set first;"
  echo "  compare every line with RG-3.1's table; write decisions/register-parses/<date>-pr<number>-parse.md, signed."
  echo "VERIFY: decision-check.sh prints OK for the parse; every rule has a result; no '<' in anything run. This is the control"
  echo "  in force (BD-16-2) for this file's own pull requests under register/ and identity/."
  echo "Evidence: <date>-RG-3.6-parse-pr<number>-v1 (E-03). Then: agp-platform done RG-3.6"
}

# ---------------------------------------------------------------- 4. Folders, operators, control groups

step RG-4.1 AUTO-READ "Prove folders.yaml equals the live organisation" \
  --needs "FLD_AGENTIC_PLATFORM ORG_ID PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
s_RG_4_1_check() { ckpt_done RG-4.1; }
s_RG_4_1_apply() {
  local committed live id py d
  py="$(_p16_venvpy)"
  if [ "$AGP_MODE" != apply ]; then
    _p16_plan "reads: register/folders.yaml (venv python); gcloud resource-manager folders list --organization and --folder per"
    _p16_plan "committed id; both saved as records and compared; 22 lines each"
    _p16_record RG-4.1 folders-committed E-05 1.3.1 tsv < /dev/null
    _p16_record RG-4.1 folders-live E-05 1.3.1 tsv < /dev/null
    return 0
  fi
  [ -x "$py" ] || { echo "STOP: the venv of RG-2.1 is missing"; return 1; }
  committed="$("$py" - "$(v PLATFORM_REPO_DIR)/register/folders.yaml" <<'PY'
import sys, yaml
for f in yaml.safe_load(open(sys.argv[1]))["folders"]: print(f"{f['id']}\t{f['display_name']}\t{f['parent']}")
PY
)" || { echo "STOP: register/folders.yaml does not read"; return 1; }
  committed="$(printf '%s\n' "$committed" | sort)"
  live="$( { r gcloud resource-manager folders list --organization="$(v ORG_ID)" --format="value(name.basename(),displayName,parent)"
    for id in $(printf '%s\n' "$committed" | cut -f1); do
      r gcloud resource-manager folders list --folder="$id" --format="value(name.basename(),displayName,parent)"
    done; } | grep -E "$(printf '\t')fld-" | sort -u)"
  printf '%s\n' "$committed" | _p16_record RG-4.1 folders-committed E-05 1.3.1 tsv || return 1
  printf '%s\n' "$live" | _p16_record RG-4.1 folders-live E-05 1.3.1 tsv || return 1
  d="$(diff <(printf '%s\n' "$committed") <(printf '%s\n' "$live"))"
  if [ -z "$d" ]; then echo "FOLDERS MATCH ($(printf '%s\n' "$live" | grep -c .) lines)"; else printf '%s\n' "$d"; echo "STOP: folders.yaml differs from the organisation: fix in 09 (live) or regenerate with FS-4.1 by pull request"; return 1; fi
  [ "$(printf '%s\n' "$live" | grep -c .)" = 22 ] || { echo "STOP: not 22 folders"; return 1; }
}

step RG-4.2 HUMAN "Place the operators convention" --needs "PLATFORM_REPO_DIR"
s_RG_4_2_check() { ckpt_done RG-4.2; }
s_RG_4_2_manual() {
  echo "WHO: the platform owner. WHERE: branch rg-4-operators, then the git host."
  echo "DO: commit register/operators/README.md with RG-4.2's four lines (the file per agent; the schema; members are named"
  echo "  humans on DOMAIN, never service accounts; the group factory creates <agent>-operators@ from this file only, control"
  echo "  groups refused by R-07). No operators/<agent_id>.yaml yet."
  echo "VERIFY: the README is merged; check-jsonschema --schemafile register/schema/operators.schema.json"
  echo "  register/operators/fixtures/fail-control-group.yaml still refuses. Evidence: <date>-RG-4.2-operators-convention-v1."
  echo "Then: agp-platform done RG-4.2"
}

step RG-4.3 HUMAN "Prove the control-group list needs the second human and a second human reviewer" --needs "CONTROL_GROUPS_FILE PLATFORM_REPO_REMOTE PLATFORM_REPO_SLUG"
s_RG_4_3_check() { ckpt_done RG-4.3; }
s_RG_4_3_manual() {
  echo "WHO: the platform owner opens; the second operator approves once; the second human observes and does not approve."
  echo "WHERE: a scratch clone, then the git host."
  echo "DO: RG-4.3's first block of setup/16 (clone, branch rg-4-3-negative-test, as_of changed, push, gh pr create); the second"
  echo "  operator approves; then its second block (gh pr view, then close with --delete-branch, scratch clone removed)."
  echo "VERIFY: before closing: BLOCKED, REVIEW_REQUIRED, and the review requests include the second human's login."
  echo "Evidence: <date>-RG-4.3-control-groups-two-humans-v1. Then: agp-platform done RG-4.3"
}

# ---------------------------------------------------------------- 5. The shared Agent Registry

step RG-5.1 AUTO "Read the registry's state and record its name" --needs "CORE_PROJECT REGION BUILD_LOG_DIR" --sets "AGENT_REGISTRY"
s_RG_5_1_check() { [ "$(_penv_get AGENT_REGISTRY)" = "projects/$(v CORE_PROJECT)/locations/$(v REGION)" ]; }
s_RG_5_1_apply() {
  local p reg s a t api
  p="$(v CORE_PROJECT)"; reg="$(v REGION)"
  if [ "$AGP_MODE" != apply ]; then
    _p16_plan "reads: REGION is europe-west1; agentregistry and apphub enabled on CORE_PROJECT; agent-registry services and"
    _p16_plan "agents lists in REGION, both empty"
    pset AGENT_REGISTRY "projects/$p/locations/$reg"
    _p16_record RG-5.1 registry-empty E-05 1.3.1 txt < /dev/null
    return 0
  fi
  [ "$reg" = europe-west1 ] || { echo "STOP: REGION is not europe-west1 (P71)"; return 1; }
  for api in agentregistry.googleapis.com apphub.googleapis.com; do
    nonempty r gcloud services list --enabled --project="$p" --filter="config.name=$api" --format="value(config.name)" \
      || { echo "STOP: $api is not enabled on CORE_PROJECT: re-run 10 CP-1.6"; return 1; }
  done
  # the two lists read the state before anything registers (the page's VERIFY: both empty), so they are reads of a check
  s="$(_p16_pre r gcloud agent-registry services list --location="$reg" --project="$p" --format="value(name)")" || return 1
  a="$(_p16_pre r gcloud agent-registry agents list --location="$reg" --project="$p" --format="value(name)")" || return 1
  t="$(printf 'services:\n%s\nagents:\n%s\n' "$s" "$a")"; printf '%s\n' "$t"
  printf '%s\n' "$t" | _p16_record RG-5.1 registry-empty E-05 1.3.1 txt || return 1
  [ -z "$s$a" ] || { echo "STOP: the registry is not empty before the factory's first registration: investigate and record"; return 1; }
  pset AGENT_REGISTRY "projects/$p/locations/$reg"
}

step RG-5.2 AUTO "Obtain a repair grant on CORE_PROJECT" --witness --note "approver: the second human, as 12 configured ENT_PROJECT_REPAIR_CORE" \
  --needs "ENT_PROJECT_REPAIR_CORE CICD_PROJECT"
s_RG_5_2_check() {   # an ACTIVE grant; once RG-7.3 (the last step it serves) is DONE, no grant is needed again
  ckpt_done RG-7.3 && return 0
  _p16_grant_has "$(v ENT_PROJECT_REPAIR_CORE)" 'state=ACTIVE'
}
s_RG_5_2_apply() { _p16_grant ENT_PROJECT_REPAIR_CORE 3600 "$P16_REPAIR_WHY"; }

step RG-5.3 AUTO "Bind the registry roles" \
  --needs "CORE_PROJECT SA_FACTORY_APPLY SA_PLATFORM_DRIFT GRP_PLATFORM_READERS GRP_EVE_OWNERS ENT_PROJECT_REPAIR_CORE CICD_PROJECT BUILD_LOG_DIR"
s_RG_5_3_check() {
  local rc
  _p16_bound_or_pending RG-5.3 "serviceAccount:$(v SA_FACTORY_APPLY)" roles/agentregistry.admin _p16_core_policy; rc=$?; [ $rc -eq 0 ] || return $rc
  _p16_bound_or_pending RG-5.3 "serviceAccount:$(v SA_PLATFORM_DRIFT)" roles/agentregistry.viewer _p16_core_policy; rc=$?; [ $rc -eq 0 ] || return $rc
  _p16_bound_or_pending RG-5.3 "group:$(v GRP_PLATFORM_READERS)" roles/agentregistry.viewer _p16_core_policy; rc=$?; [ $rc -eq 0 ] || return $rc
  _p16_bound_or_pending RG-5.3 "group:$(v GRP_EVE_OWNERS)" roles/agentregistry.viewer _p16_core_policy; rc=$?; [ $rc -eq 0 ] || return $rc
  _p16_pending_has RG-5.3 "SIEM detection desk principal" && _p16_pending_has RG-5.3 "gemini-egress policy generator"
}
s_RG_5_3_apply() {
  local p m role w line
  p="$(v CORE_PROJECT)"
  _p16_under_grant || return 1
  for line in "serviceAccount:$(v SA_FACTORY_APPLY)|roles/agentregistry.admin|16 RG-5.3 agentregistry.admin for factory-apply@" \
              "serviceAccount:$(v SA_PLATFORM_DRIFT)|roles/agentregistry.viewer|16 RG-5.3 agentregistry.viewer for platform-drift@" \
              "group:$(v GRP_PLATFORM_READERS)|roles/agentregistry.viewer|16 RG-5.3 agentregistry.viewer for platform-readers@" \
              "group:$(v GRP_EVE_OWNERS)|roles/agentregistry.viewer|16 RG-5.3 agentregistry.viewer for eve-owners@"; do
    m="${line%%|*}"; role="${line#*|}"; w="${role#*|}"; role="${role%%|*}"
    if [ "$AGP_MODE" = apply ] && _p16_pre _p16_bound_or_pending RG-5.3 "$m" "$role" _p16_core_policy; then echo "$m holds $role (or is PENDING)"; continue; fi
    _p16_eop_bind RG-5.3 "$m" "$w" -- gcloud projects add-iam-policy-binding "$p" --member="$m" --role="$role" --condition=None || return 1
  done
  _p16_pending_has RG-5.3 "SIEM detection desk principal" \
    || _p16_pending RG-5.3 "SIEM detection desk principal" "15 part B: agentregistry.viewer on CORE_PROJECT for the detection desk principal" || return 1
  _p16_pending_has RG-5.3 "gemini-egress policy generator" \
    || _p16_pending RG-5.3 "gemini-egress policy generator" "20: agentregistry.viewer on CORE_PROJECT for the gemini-egress policy generator" || return 1
  return 0
}

step RG-5.4 AUTO-READ "Verify that only factory-apply@ can write the registry" --witness --note "the second human reads the output before the grant ends" \
  --needs "CORE_PROJECT SA_FACTORY_APPLY SA_PLATFORM_DRIFT GRP_PLATFORM_READERS GRP_EVE_OWNERS BUILD_LOG_DIR EVIDENCE_REGISTER"
s_RG_5_4_check() { ckpt_done RG-5.4; }
s_RG_5_4_apply() {
  local j out rc
  if [ "$AGP_MODE" != apply ]; then
    _p16_plan "reads: CORE_PROJECT's IAM policy: the agentregistry rows are exactly admin factory-apply@ and viewer platform-drift@,"
    _p16_plan "platform-readers@, eve-owners@; no editor or user; no owner, editor, admin or writer basic role"
    _p16_record RG-5.4 registry-iam E-06 4.2.1 txt < /dev/null
    return 0
  fi
  j="$(r gcloud projects get-iam-policy "$(v CORE_PROJECT)" --format=json)" || return 1
  out="$(printf '%s' "$j" | _p16_py 'import json,sys
want = {("roles/agentregistry.admin", "serviceAccount:"+sys.argv[1]), ("roles/agentregistry.viewer", "serviceAccount:"+sys.argv[2]),
        ("roles/agentregistry.viewer", "group:"+sys.argv[3]), ("roles/agentregistry.viewer", "group:"+sys.argv[4])}
have = set(); bad = []
for b in json.load(sys.stdin).get("bindings", []):
    for m in b.get("members", []):
        if b["role"].startswith("roles/agentregistry."): have.add((b["role"], m)); print("%s\t%s" % (b["role"], m))
        if b["role"] in ("roles/owner", "roles/editor", "roles/admin", "roles/writer"): bad.append("basic role %s on %s" % (b["role"], m))
for r, m in sorted(have - want): bad.append("unexpected %s for %s" % (r, m))
for r, m in sorted(want - have): bad.append("missing %s for %s" % (r, m))
for x in bad: print("STOP: " + x)' "$(v SA_FACTORY_APPLY)" "$(v SA_PLATFORM_DRIFT)" "$(v GRP_PLATFORM_READERS)" "$(v GRP_EVE_OWNERS)")"; rc=$?
  printf '%s\n' "$out"
  printf '%s\n' "$out" | grep -v '^STOP' | _p16_record RG-5.4 registry-iam E-06 4.2.1 txt || return 1
  [ $rc -eq 0 ] || return 1
  printf '%s\n' "$out" | grep -q '^STOP' && return 1
  echo "REVIEW: the second human reads the table before the grant ends; the only other writer is an active ENT_PROJECT_REPAIR_CORE grant (RG-5.7)"
}

step RG-5.5 AUTO-READ "Confirm registry reads are logged (P80)" --needs "CORE_PROJECT FLD_AGENTIC_PLATFORM REGION BUILD_LOG_DIR"
s_RG_5_5_check() { ckpt_done RG-5.5; }
_p16_audit_has() { _p16_py 'import json,sys
for c in json.load(sys.stdin).get("auditConfigs", []) or []:
    if c.get("service") in ("agentregistry.googleapis.com", "allServices"):
        if any(l.get("logType") == "ADMIN_READ" for l in c.get("auditLogConfigs", [])): print("ADMIN_READ for %s" % c["service"])'; }
s_RG_5_5_apply() {
  local p f a b i=0 log t
  p="$(v CORE_PROJECT)"
  if [ "$AGP_MODE" != apply ]; then
    _p16_plan "reads: auditConfigs of CORE_PROJECT and fld-agentic-platform (ADMIN_READ for agentregistry or allServices);"
    _p16_plan "one agent-registry services list; then polls gcloud logging read for its Data Access entry for up to 10 minutes"
    _p16_record RG-5.5 registry-read-audit E-06 5.2.4 txt < /dev/null
    return 0
  fi
  a="$(r gcloud projects get-iam-policy "$p" --format=json | _p16_audit_has)"
  b="$(r gcloud resource-manager folders get-iam-policy "$(v FLD_AGENTIC_PLATFORM)" --format=json | _p16_audit_has)"
  printf 'project: %s\nfolder: %s\n' "${a:-none}" "${b:-none}"
  [ -n "$a$b" ] || { echo "STOP: no ADMIN_READ Data Access configuration for agentregistry: re-run 14's Data Access step, do not add it here"; return 1; }
  r gcloud agent-registry services list --location="$(v REGION)" --project="$p" --format="value(name)" >/dev/null || return 1
  echo "waiting for the Data Access entry (log ingestion is not immediate; up to 10 minutes)"
  while [ $i -lt 10 ]; do
    _p16_sleep 60; i=$((i + 1))
    log="$(r gcloud logging read 'protoPayload.serviceName="agentregistry.googleapis.com" AND logName:"cloudaudit.googleapis.com%2Fdata_access"' \
      --project="$p" --freshness=15m --limit=5 --format="table(timestamp,protoPayload.methodName,protoPayload.authenticationInfo.principalEmail)")" || return 1
    [ -n "$log" ] && break
  done
  t="$(printf 'project: %s\nfolder: %s\n%s\n' "${a:-none}" "${b:-none}" "${log:-no Data Access entry after 10 minutes}")"
  printf '%s\n' "$t" | _p16_record RG-5.5 registry-read-audit E-06 5.2.4 txt || return 1
  if [ -n "$log" ]; then printf '%s\n' "$log"; echo "REVIEW: the ListServices call by sa-1-admin@ is listed"
  else echo "REVIEW: configured but no entry arrived: record \"registry reads unlogged\" in EVIDENCE_REGISTER (05 section 4; 08 section 8 lists it)"; fi
}

step RG-5.6 HUMAN "Create the registry write alert" --needs "CORE_PROJECT SA_FACTORY_APPLY BUILD_LOG_DIR"
s_RG_5_6_check() { ckpt_done RG-5.6; }
s_RG_5_6_manual() {
  echo "WHO: the platform owner, under the RG-5.2 grant (its bundle carries roles/monitoring.admin)."
  echo "WHERE: the tenant shell, ~/.platform-env sourced."
  echo "DO: run RG-5.6's block of setup/16 as written. Without NOTIF_CH_PAGER_CORE and NOTIF_CH_EMAIL_CORE (15 part A) it writes"
  echo "  checkpoint RG-5.6 PENDING and a re-run line, and this step stays open; otherwise it writes the policy.json heredoc and"
  echo "  runs gcloud monitoring policies create --project=\"\$CORE_PROJECT\". The script does not retype the heredoc."
  echo "VERIFY: gcloud monitoring policies list --project=\"\$CORE_PROJECT\" --filter='displayName:\"agentregistry write\"' \\"
  echo "  --format=\"value(name,enabled)\" prints one policy, True. A permission refusal: PENDING and a re-run of 12."
  echo "Evidence: the policy JSON in records (E-06). Then: agp-platform done RG-5.6"
}

step RG-5.7 HUMAN "Prove the alert with one witnessed repair write" --witness \
  --needs "ENT_PROJECT_REPAIR_CORE CORE_PROJECT REGION FLD_PLATFORM_CORE CICD_PROJECT PLATFORM_REPO_DIR DRILL_CALENDAR"
s_RG_5_7_check() { ckpt_done RG-5.7; }
s_RG_5_7_manual() {
  echo "WHO: the platform owner under a fresh ENT_PROJECT_REPAIR_CORE grant; the second human approves, witnesses and times the page."
  echo "WHERE: the tenant shell; the second human's paging application. Waits for RG-5.6's policy (15 part A)."
  echo "DO: RG-5.7's first block of setup/16 (entitlement read, pam_request, pam_wait, services create rg-drill-<date> on"
  echo "  drill.invalid); after the page, its second block (the delete, answering its prompt; the list; the audit read); then"
  echo "  the DR-16-1 row with absolute dates; revoke the grant once the page is confirmed."
  echo "VERIFY: page and email within 5 minutes; CreateService and DeleteService by sa-1-admin@; the services list empty again."
  echo "Evidence: <date>-RG-5.7-registry-alert-drill-v1, the DR-16-1 row (E-08)."
  echo "Then: agp-platform done RG-5.7 --witness <second human's email>"
}

# ---------------------------------------------------------------- 6. The platform_registry dataset

step RG-6.1 AUTO "Create platform_registry in CORE_PROJECT" --irreversible --gate "NAMES" \
  --needs "CORE_PROJECT BQ_LOCATION PLATFORM_REPO_DIR ENT_PROJECT_REPAIR_CORE CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
_p16_ds_show() { r bq --project_id="$(v CORE_PROJECT)" show --format=prettyjson "$(v CORE_PROJECT):platform_registry"; }
s_RG_6_1_check() { exists _p16_ds_show; }
s_RG_6_1_apply() {
  local tool ds j out
  tool="$(agp_tool decision-value.sh)"
  _p16_under_grant || return 1
  if [ "$AGP_MODE" = apply ]; then
    # the page's own stops: the NAMES record is 03's, amended and signed by people; nothing here can change it (98)
    [ -x "$tool" ] || { echo "STOP: $tool is not installed (03 DC-1.2)"; return 1; }
    ds="$("$tool" NAMES PLATFORM_REGISTRY_DS)" || { echo "STOP: no signed PLATFORM_REGISTRY_DS in NAMES: 03's owner adds it and the signatories sign; then resume"; return 98; }
    [ "$ds" = platform_registry ] || { echo "STOP: NAMES holds PLATFORM_REGISTRY_DS=$ds, not platform_registry: amend NAMES in 03 first (the name cannot be changed after creation); then resume"; return 98; }
    [ "$(v BQ_LOCATION)" = EU ] || { echo "STOP: BQ_LOCATION is $(v BQ_LOCATION), not EU"; return 1; }
  else
    _p16_plan "reads: decision-value.sh NAMES PLATFORM_REGISTRY_DS must print platform_registry; BQ_LOCATION must be EU"
    ds=platform_registry
  fi
  x bq --project_id="$(v CORE_PROJECT)" mk --dataset --location="$(v BQ_LOCATION)" \
    --description="Register copy, CAI export and reconciliation results (05 section 6; topology row 36). Setup 16 RG-6.1." \
    --label=tier:core --label=data_class:evidence "$(v CORE_PROJECT):$ds" || return 1
  [ "$AGP_MODE" = apply ] || { _p16_record RG-6.1 platform-registry E-06 1.3.1 json < /dev/null; return 0; }
  j="$(_p16_ds_show)" || return 1
  out="$(printf '%s' "$j" | _p16_py 'import json,sys
d=json.load(sys.stdin); l=d.get("labels") or {}
print(json.dumps({"location": d.get("location"), "labels": l, "access": [sorted(a.keys())[0] for a in d.get("access", [])]}))
if d.get("location") != "EU": print("STOP: location is %s" % d.get("location"))
if l.get("tier") != "core" or l.get("data_class") != "evidence": print("STOP: labels are %s" % l)')"
  printf '%s\n' "$out"
  printf '%s\n' "$out" | grep -v '^STOP' | _p16_record RG-6.1 platform-registry E-06 1.3.1 json || return 1
  ! printf '%s\n' "$out" | grep -q '^STOP'
}

step RG-6.2 AUTO "Give platform-drift@ WRITER on platform_registry" --removes \
  --needs "CORE_PROJECT SA_PLATFORM_DRIFT ENT_PROJECT_REPAIR_CORE CICD_PROJECT BUILD_LOG_DIR"
_p16_writer_in() { _p16_py 'import json,sys
a=json.load(sys.stdin).get("access", [])
sys.exit(0 if {"role": "WRITER", "userByEmail": sys.argv[1]} in a else 1)' "$(v SA_PLATFORM_DRIFT)"; }
s_RG_6_2_check() {
  local j
  j="$(_p16_ds_show 2>/dev/null)" || { [ "$AGP_OFFLINE" = 1 ] && return 3; return 1; }
  printf '%s' "$j" | _p16_writer_in
}
s_RG_6_2_apply() {
  local p w ds e1 e2 diffs
  p="$(v CORE_PROJECT)"; ds="$p:platform_registry"
  _p16_under_grant || return 1
  if [ "$AGP_MODE" != apply ]; then
    _p16_plan "reads: bq show of $ds into before.json; after.json = datasetReference plus access with WRITER for platform-drift@"
    x bq --project_id="$p" update --source "<after.json>" "$ds"
    _p16_record RG-6.2 access-before - - json < /dev/null
    return 0
  fi
  w="$(mktemp -d "${TMPDIR:-/tmp}/agp-p16.XXXXXX")" || return 1
  _p16_ds_show > "$w/before.json" || { rm -rf "$w"; return 1; }
  _p16_py 'import json,sys
d=json.load(open(sys.argv[1])); e={"role": "WRITER", "userByEmail": sys.argv[2]}
acc=[]
for a in d.get("access", []) + [e]:
    if a not in acc: acc.append(a)
json.dump({"datasetReference": d["datasetReference"], "access": acc}, open(sys.argv[3], "w"), indent=2)
json.dump(sorted(json.dumps(a, sort_keys=True) for a in acc), open(sys.argv[4], "w"))' "$w/before.json" "$(v SA_PLATFORM_DRIFT)" "$w/after.json" "$w/expected.json" \
    || { echo "STOP: the dataset read has no datasetReference or access"; rm -rf "$w"; return 1; }
  e1="$(_p16_py 'import json,sys; print(json.load(open(sys.argv[1])).get("etag"))' "$w/before.json")"
  e2="$(_p16_ds_show | _p16_py 'import json,sys; print(json.load(sys.stdin).get("etag"))')"
  [ "$e1" = "$e2" ] || { echo "STOP: the dataset changed since it was read (an advisory test, not a lock): re-read and start the step again"; rm -rf "$w"; return 1; }
  x bq --project_id="$p" update --source "$w/after.json" "$ds" || { rm -rf "$w"; return 1; }
  diffs="$(_p16_ds_show | _p16_py 'import json,sys
d=json.load(sys.stdin); b=json.load(open(sys.argv[1])); want=json.load(open(sys.argv[2]))
have=sorted(json.dumps(a, sort_keys=True) for a in d.get("access", []))
if have != want: print("STOP: the access array differs from the expected one")
for k in ("location", "labels", "description"):
    if d.get(k) != b.get(k): print("STOP: %s changed in the update" % k)
sas=[a.get("userByEmail") for a in d.get("access", []) if str(a.get("userByEmail","")).endswith("gserviceaccount.com")]
if sas != [sys.argv[3]]: print("STOP: service accounts in the access array: %s" % sas)' "$w/before.json" "$w/expected.json" "$(v SA_PLATFORM_DRIFT)")"
  _p16_record RG-6.2 access-before - - json < "$w/before.json" || { rm -rf "$w"; return 1; }
  rm -rf "$w"
  [ -z "$diffs" ] || { printf '%s\n' "$diffs"; return 1; }
  echo "ACCESS MATCHES"
  echo "REVIEW: WRITER can delete rows and nothing mitigates it until B-02's export runs (BD-16-4, open)"
}

# ---------------------------------------------------------------- 7. Topology row 36

step RG-7.1 HUMAN "Sign the row-36 exception record" --needs "SA_PLATFORM_DRIFT PLATFORM_REPO_DIR"
s_RG_7_1_check() { ckpt_done RG-7.1; }
s_RG_7_1_manual() {
  echo "WHO: the platform owner drafts; IT security (the second human) and ISMS sign; the security reviewer ratifies (RATIFY-SR)."
  echo "WHERE: decisions/ through 03's decision-record tooling."
  echo "DO: decisions/<date>-row-36-platform-drift-exception.md (id ROW36-EXC) with SA_PLATFORM_DRIFT, the bindings of RG-7.2"
  echo "  and RG-7.3, the two corrections RG-7.1 states (feeds by a human under ENT_FOLDER_ADMIN; findingsViewer on the folder),"
  echo "  Eve's expected foreign principal, and cai_access: search (default) or export with its consequences."
  echo "VERIFY: tools/decision-need.sh ROW36-EXC prints SIGNED; the record lists exactly the bindings RG-7.4 reads."
  echo "  If export is signed, RG-7.2, RG-7.4, RG-7.5 and RG-8.1 change in the same sitting. Evidence: the record (E-03)."
  echo "Then: agp-platform done RG-7.1"
}

step RG-7.2 AUTO "Bind the folder-level roles" --gate "ROW36-EXC" --witness --note "approver of the ENT_FOLDER_ADMIN grant: the second human" \
  --needs "FLD_AGENTIC_PLATFORM SA_PLATFORM_DRIFT ENT_FOLDER_ADMIN CICD_PROJECT BUILD_LOG_DIR"
P16_ROW36_FOLDER="roles/iam.securityReviewer roles/cloudasset.viewer roles/securitycenter.findingsViewer"
_p16_fld_policy() { gcloud resource-manager folders get-iam-policy "$(v FLD_AGENTIC_PLATFORM)"; }
s_RG_7_2_check() {
  local role rc
  for role in $P16_ROW36_FOLDER; do
    has_binding "serviceAccount:$(v SA_PLATFORM_DRIFT)" "$role" _p16_fld_policy; rc=$?
    [ $rc -eq 0 ] || return $rc
  done
}
s_RG_7_2_apply() {
  local role
  _p16_grant ENT_FOLDER_ADMIN 3600 "setup 16 RG-7.2: topology row 36 folder roles for platform-drift@ (ROW36-EXC)" || return 1
  for role in $P16_ROW36_FOLDER; do
    if [ "$AGP_MODE" = apply ] && _p16_pre has_binding "serviceAccount:$(v SA_PLATFORM_DRIFT)" "$role" _p16_fld_policy; then echo "$role is bound"; continue; fi
    x gcloud resource-manager folders add-iam-policy-binding "$(v FLD_AGENTIC_PLATFORM)" --member="serviceAccount:$(v SA_PLATFORM_DRIFT)" \
      --role="$role" --condition=None --format="value(etag)" || return 1
  done
  if [ "$AGP_MODE" != apply ]; then
    _p16_plan "reads: gcloud iam roles describe roles/cloudasset.viewer (searchAllResources, not exportResource) and"
    _p16_plan "roles/iam.securityReviewer (saved, attached to ROW36-EXC)"
    _p16_record RG-7.2 securityreviewer-permissions - - yaml < /dev/null
    return 0
  fi
  r gcloud iam roles describe roles/cloudasset.viewer --format="value(includedPermissions)" | tr ',;' '\n\n' | grep -E 'searchAllResources|exportResource' || true
  r gcloud iam roles describe roles/iam.securityReviewer --format="yaml(includedPermissions)" | _p16_record RG-7.2 securityreviewer-permissions - - yaml || return 1
  echo "REVIEW: if ROW36-EXC signed cai_access: export, bind its custom role in this sitting and add it to RG-7.4's expected set"
}

step RG-7.3 AUTO "Bind the project-level roles in CORE_PROJECT" --witness --note "approver of the ENT_PROJECT_REPAIR_CORE grant: the second human" \
  --needs "CORE_PROJECT SA_PLATFORM_DRIFT ENT_PROJECT_REPAIR_CORE CICD_PROJECT BUILD_LOG_DIR"
P16_ROW36_PROJECT="roles/bigquery.jobUser roles/serviceusage.serviceUsageConsumer"
P16_RUN_INVOKER="run.invoker on each Tier W+ action service for platform-drift@"
s_RG_7_3_check() {
  local role rc
  for role in $P16_ROW36_PROJECT; do
    has_binding "serviceAccount:$(v SA_PLATFORM_DRIFT)" "$role" _p16_core_policy; rc=$?
    [ $rc -eq 0 ] || return $rc
  done
  _p16_pending_has RG-7.3 "$P16_RUN_INVOKER"
}
s_RG_7_3_apply() {
  local role
  _p16_under_grant || return 1
  for role in $P16_ROW36_PROJECT; do
    if [ "$AGP_MODE" = apply ] && _p16_pre has_binding "serviceAccount:$(v SA_PLATFORM_DRIFT)" "$role" _p16_core_policy; then echo "$role is bound"; continue; fi
    x gcloud projects add-iam-policy-binding "$(v CORE_PROJECT)" --member="serviceAccount:$(v SA_PLATFORM_DRIFT)" --role="$role" \
      --condition=None --format="value(etag)" || return 1
  done
  _p16_pending_has RG-7.3 "$P16_RUN_INVOKER" \
    || _p16_pending RG-7.3 "$P16_RUN_INVOKER" "17 FM-AGENT per agent: resource-level run.invoker on <agent>-actions for platform-drift@ from the manifest's invokers.halt" || return 1
  return 0
}

step RG-7.4 AUTO-READ "Verify platform-drift@'s exact role set" --witness --note "the second human reads" \
  --needs "FLD_AGENTIC_PLATFORM CORE_PROJECT ORG_ID SA_PLATFORM_DRIFT BUILD_LOG_DIR EVIDENCE_REGISTER"
_p16_roles_of() {   # MEMBER: the roles MEMBER holds in the IAM policy JSON on standard input, sorted
  _p16_py 'import json,sys
print("\n".join(sorted({b["role"] for b in json.load(sys.stdin).get("bindings", []) if sys.argv[1] in b.get("members", [])})))' "$1"
}
s_RG_7_4_apply() {
  local m sa fld prj org keys act t bad=0
  sa="$(v SA_PLATFORM_DRIFT)"; m="serviceAccount:$sa"
  if [ "$AGP_MODE" != apply ]; then
    _p16_plan "reads: platform-drift@'s roles on fld-agentic-platform (exactly cloudasset.viewer, iam.securityReviewer,"
    _p16_plan "securitycenter.findingsViewer), on CORE_PROJECT (exactly agentregistry.viewer, bigquery.jobUser,"
    _p16_plan "serviceusage.serviceUsageConsumer), on the organisation (none); no user-managed key; no binding on the account"
    _p16_record RG-7.4 platform-drift-roles E-06 4.2.1 txt < /dev/null
    return 0
  fi
  fld="$(r gcloud resource-manager folders get-iam-policy "$(v FLD_AGENTIC_PLATFORM)" --format=json | _p16_roles_of "$m")" || return 1
  prj="$(r gcloud projects get-iam-policy "$(v CORE_PROJECT)" --format=json | _p16_roles_of "$m")" || return 1
  org="$(r gcloud organizations get-iam-policy "$(v ORG_ID)" --format=json | _p16_roles_of "$m")" \
    || { echo "STOP: the organisation policy read was refused or failed"; return 1; }
  keys="$(_p16_pre r gcloud iam service-accounts keys list --iam-account="$sa" --managed-by=user --project="$(v CORE_PROJECT)" --format="value(name)")" || return 1
  act="$(r gcloud iam service-accounts get-iam-policy "$sa" --project="$(v CORE_PROJECT)" --format=json | _p16_py 'import json,sys
print(json.dumps(json.load(sys.stdin).get("bindings", []) or []))')" || return 1
  t="$(printf '== folder\n%s\n== CORE_PROJECT\n%s\n== organisation\n%s\n== keys\n%s\n== who can act as it\n%s\n' "$fld" "$prj" "$org" "$keys" "$act")"
  printf '%s\n' "$t"; printf '%s\n' "$t" | _p16_record RG-7.4 platform-drift-roles E-06 4.2.1 txt || return 1
  [ "$fld" = "$(printf '%s\n' roles/cloudasset.viewer roles/iam.securityReviewer roles/securitycenter.findingsViewer)" ] \
    || { echo "STOP: the folder roles are not exactly the three of ROW36-EXC (plus the export custom role only if signed: then compare by hand)"; bad=1; }
  [ "$prj" = "$(printf '%s\n' roles/agentregistry.viewer roles/bigquery.jobUser roles/serviceusage.serviceUsageConsumer)" ] \
    || { echo "STOP: the CORE_PROJECT roles are not exactly agentregistry.viewer, bigquery.jobUser, serviceusage.serviceUsageConsumer"; bad=1; }
  [ -z "$org" ] || { echo "STOP: platform-drift@ holds a role on the organisation"; bad=1; }
  [ -z "$keys" ] || { echo "STOP: platform-drift@ has a user-managed key"; bad=1; }
  [ "$act" = "[]" ] || { echo "STOP: a binding on platform-drift@ itself (a drift finding; remove it)"; bad=1; }
  return $bad
}
s_RG_7_4_check() { ckpt_done RG-7.4; }

step RG-7.5 HUMAN "Read row 41 back into the drift job's expected set" \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM LOGGING_PROJECT SINK_S_ORG SINK_S_FOLDER SA_FACTORY_APPLY SA_PLATFORM_DRIFT PLATFORM_REPO_DIR PLATFORM_REPO_SLUG"
s_RG_7_5_check() { ckpt_done RG-7.5; }
s_RG_7_5_manual() {
  echo "WHO: the platform owner; the code owner of /ci/ reviews as RG-2.6."
  echo "WHERE: the tenant shell, branch rg-7-expected."
  echo "DO: run RG-7.5's block of setup/16 as written (the two sinks' writerIdentity, their roles on LOGGING_PROJECT, the"
  echo "  ci/drift/expected-principals.yaml heredoc with cai_access as ROW36-EXC signed, commit, push, gh pr create)."
  echo "  The script does not retype the page's heredoc."
  echo "VERIFY: both writer identities hold roles/logging.logWriter on LOGGING_PROJECT (else stop: a 14 re-run); row_36 equals"
  echo "  RG-7.4's read; merged with the code owner's approval. This file is the lock on platform-drift@'s roles."
  echo "Evidence: <date>-RG-7.5-row-41-readback-v1 (E-06). Then: agp-platform done RG-7.5"
}

step RG-7.6 BLOCKED "Row 44: the SDP discovery configurations" --note "B-23: entitlement, SDP pricing record, reconcile job"
s_RG_7_6_check() { ckpt_done RG-7.6; }
s_RG_7_6_manual() {
  echo "BLOCKED on README B-23: (1) no entitlement in 12 carries Organization Administrator or Security Admin, which a folder"
  echo "  discovery configuration needs; (2) the SDP pricing record (P11's SCC payer) is unsigned; (3) platform-class-reconcile"
  echo "  has no code. When unblocked: two configurations at fld-agentic-platform (BigQuery, Cloud Storage), europe-west1."
}

# ---------------------------------------------------------------- 8. The jobs

step RG-8.1 HUMAN "Commit the job contract and record the names" --needs "PLATFORM_REPO_DIR PLATFORM_REPO_SLUG" --sets "DRIFT_JOB RECONCILE_JOB"
s_RG_8_1_check() { ckpt_done RG-8.1; }
s_RG_8_1_manual() {
  echo "WHO: the platform owner writes; the security reviewer (or the second human) approves as code owner of /ci/."
  echo "WHERE: the tenant shell, branch rg-8-jobs, then the git host."
  echo "DO: run RG-8.1's block of setup/16 as written (ci/jobs/platform-jobs.yaml heredoc, commit, push, gh pr create); it ends"
  echo "  with: penv_set DRIFT_JOB \"platform-drift\"; penv_set RECONCILE_JOB \"platform-reconcile\". The script does not retype it."
  echo "VERIFY: merged with the code owner's approval; need DRIFT_JOB RECONCILE_JOB; gcloud run jobs list --region=\"\$REGION\" \\"
  echo "  --project=\"\$CORE_PROJECT\" --format=\"value(name)\" prints nothing yet."
  echo "Evidence: <date>-RG-8.1-job-contract-v1 (E-05). Then: agp-platform done RG-8.1"
}

step RG-8.2 BLOCKED "Deploy the two jobs" --note "B-02: drift and reconciliation code"
s_RG_8_2_check() { ckpt_done RG-8.2; }
s_RG_8_2_manual() {
  echo "BLOCKED on README B-02: the drift and reconciliation code, their platform_registry table schemas and attested images."
  echo "  When unblocked: RG-8.2's two gcloud run jobs deploy --project=\"\$CORE_PROJECT\" lines under ENT_DEPLOY_CREDENTIAL_HOLDER_CORE"
  echo "  (actAs from its project-level serviceAccountUser, never a binding on platform-drift@); securitycenter enabled first."
}

step RG-8.3 BLOCKED "Schedules, invoker, folder feed and absence alarm" --note "B-02: needs RG-8.2"
s_RG_8_3_check() { ckpt_done RG-8.3; }
s_RG_8_3_manual() {
  echo "BLOCKED on README B-02 (needs RG-8.2). When unblocked: RG-8.3's invoker bindings, the two scheduler jobs, the"
  echo "  platform-cai-feed topic and the folder feed (under ENT_PROJECT_REPAIR_CORE, ENT_DEPLOY_CREDENTIAL_HOLDER_CORE and"
  echo "  ENT_FOLDER_ADMIN), after checking the Cloud Scheduler service agent keeps roles/cloudscheduler.serviceAgent."
}

# ---------------------------------------------------------------- 9. Humans raise, machines lower

step RG-9.1 HUMAN "Commit the ladder publication contract" --needs "PLATFORM_REPO_DIR PLATFORM_REPO_SLUG"
s_RG_9_1_check() { ckpt_done RG-9.1; }
s_RG_9_1_manual() {
  echo "WHO: the platform owner writes; the second human approves as code owner of /ladder/; the security reviewer (or the"
  echo "  second human) of /ci/."
  echo "WHERE: branch rg-9-ladder, then the git host."
  echo "DO: commit ci/ladder-publish.md holding RG-9.1's five-point contract (where ladder files live, raise, publish by"
  echo "  walle-deployer@ only from main, lower, no machine approves) and an empty ladder/README.md."
  echo "VERIFY: merged with both code owners; grep -c 'walle-deployer@' ci/ladder-publish.md is at least 1."
  echo "Evidence: <date>-RG-9.1-ladder-contract-v1 (E-08). Then: agp-platform done RG-9.1"
}

step RG-9.2 BLOCKED "The ladder-publish workflow and its identity binding" --note "B-03: R-09, R-11 code; 23 grant; 31 binding"
s_RG_9_2_check() { ckpt_done RG-9.2; }
s_RG_9_2_manual() {
  echo "BLOCKED on README B-03: the ladder-raise rule, .github/workflows/ladder-publish.yml implementing R-11, 23's objectCreator"
  echo "  grant and 31's workflow-conditioned binding for walle-deployer@. No ladder file is published by any other path."
}

step RG-9.3 HUMAN "Prove no machine and no Mo identity holds write on the repository" --witness \
  --note "the second human (an organisation owner) runs the organisation read" \
  --needs "PLATFORM_REPO_SLUG PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_RG_9_3_check() { ckpt_done RG-9.3; }
s_RG_9_3_manual() {
  echo "WHO: the platform owner, signed in to gh as themselves; the second human (an organisation owner) runs the"
  echo "  installations read. HUMAN under phase 03's rule (git-host reads; the offline tests have no gh fake)."
  echo "WHERE: a shell with gh and ~/.platform-env sourced."
  echo "DO: run RG-9.3's three gh api reads of setup/16 for $(v PLATFORM_REPO_SLUG) (collaborators that are not User or hold"
  echo "  write and above; orgs/<org>/installations; actions/permissions/workflow) and save them together."
  echo "VERIFY: every login listed is in identity/git-humans.yaml humans[] and of type User; no installed app holds"
  echo "  pull_requests or contents write (no allow-list exists); can_approve_pull_request_reviews prints false."
  echo "Evidence: <date>-RG-9.3-no-machine-write-v1 (E-08); the weekly repeat joins 03 DC-9.8's DRILL_CALENDAR entry."
  echo "Then: agp-platform done RG-9.3 --witness <second human's email>"
}

# ---------------------------------------------------------------- 10. Close the part

step RG-10.1 AUTO "Deviation rows, the re-run index and the BLOCKED index" --witness \
  --note "the second human reads BD-16-2 and initials the build-log line" \
  --needs "DEVIATION_REGISTER BUILD_LOG_DIR CORE_PROJECT FLD_AGENTIC_PLATFORM"
P16_SCC_RERUN="securitycenter.googleapis.com on CORE_PROJECT"
_p16_scc_enabled() { _p16_svc_on securitycenter; }   # 0 enabled, 1 not enabled, 2 error, 3 offline
_p16_scc_line() { [ -f "$(v BUILD_LOG_DIR)/rerun-index.tsv" ] && grep -qF "	RG-0.1	$P16_SCC_RERUN	" "$(v BUILD_LOG_DIR)/rerun-index.tsv"; }
s_RG_10_1_check() {
  local id f rc; f="$(v DEVIATION_REGISTER)"
  [ -f "$f" ] || return 1
  for id in BD-16-1 BD-16-2 BD-16-3 BD-16-4 BD-16-5; do
    awk -F' *[|] *' -v id="$id" '$2 == id && NF == 15 {f = 1} END {exit !f}' "$f" || return 1
  done
  _p16_scc_enabled; rc=$?          # RG-0.1's re-run line, needed only while securitycenter is not enabled
  case $rc in 0) return 0;; 1) _p16_scc_line;; *) return $rc;; esac
}
s_RG_10_1_apply() {
  local d c f id l idx rc
  d="$(_p16_today)"; c="$(v CORE_PROJECT)"; f="$(v FLD_AGENTIC_PLATFORM)"
  x bd_insert "$(printf '| BD-16-1 | %s | 16 RG-5.3 to RG-7.5 | MOD | platform-core by hand: registry IAM, write alert, platform_registry, row 36 roles, expected principals | project %s; folder %s | RG-2.6, RG-3.1, RG-8.1 merge commits; ROW36-EXC | registry admin factory-apply@ only; viewers platform-readers@, eve-owners@, platform-drift@; alert policy; dataset platform_registry EU; row 36 folder and project roles | BLOCKED: zero-diff checker is 17 | n/a (no project created) | PAM grants RG-5.2, RG-5.7, RG-7.2 | superseded by terraform import and an empty plan (B-01) | open |' "$d" "$c" "$f")" || return 1
  x bd_insert "$(printf '| BD-16-2 | %s | 16 RG-3.6 | DEV | register CI rules R-01 to R-12 not implemented (B-03); signed manual parse by the security reviewer and the second human in force | platform repository | RG-3.1 | parse files under decisions/register-parses/ | n/a | n/a | second human; security reviewer when appointed | closed by RG-3.5 passing | open |' "$d")" || return 1
  x bd_insert "$(printf '| BD-16-3 | %s | 16 RG-5.6 | DEV | registry write alert in CORE_PROJECT, not LOGGING_PROJECT as 05 section 4 writes; pipeline_run_id half missing | project %s | log-based alert page read 2026-09-15 | one policy | n/a | n/a | none: SD-01 | 17 adds the CI half; 05 section 4 corrected | open |' "$d" "$c")" || return 1
  x bd_insert "$(printf '| BD-16-4 | %s | 16 RG-6.2, RG-7.1 | DEV | open limits: WRITER on platform_registry can delete rows and NOTHING mitigates it yet (the daily export to the evidence lake is inside B-02, BLOCKED: this row closes only when that export runs); platform-drift@ reads folder resources by searchAllResources, not by export, because cloudasset.viewer does not carry cloudasset.assets.exportResource (ROW36-EXC cai_access); findingsViewer at folder not organisation; CAI feed created by a human under ENT_FOLDER_ADMIN, not by platform-drift@ | %s | ROW36-EXC | as RG-7.4 | n/a | n/a | ROW36-EXC signatories | B-02 export live, then security reviewer ratification (RATIFY-SR) | open |' "$d" "$f")" || return 1
  x bd_insert "$(printf '| BD-16-5 | %s | 16 RG-1.2 | DEV | CODEOWNERS for /ci/, /contract/, /register/schema/ name the second human until the security reviewer is appointed | platform repository | RG-1.2 merge | CODEOWNERS lines | n/a | n/a | second human | security reviewer appointed: CODEOWNERS pull request | open |' "$d")" || return 1
  if [ "$AGP_MODE" != apply ]; then
    _p16_plan "then: the five rows sit above '## Closures'; reads whether securitycenter.googleapis.com is enabled on CORE_PROJECT and,"
    _p16_plan "when it is not, appends RG-0.1's re-run line (10 CP-1.6, before RG-8.2) to rerun-index.tsv, once."
    _p16_plan "the README re-run and BLOCKED index edits are RG-10.2's (hand edits to the wiki)"
    return 0
  fi
  idx="$(v BUILD_LOG_DIR)/rerun-index.tsv"
  _p16_pre _p16_scc_enabled; rc=$?
  case $rc in
    0) echo "securitycenter.googleapis.com is enabled on CORE_PROJECT: no re-run line";;
    1) if _p16_scc_line; then echo "the securitycenter re-run line exists"
       else
         { [ ! -f "$idx" ] || cat "$idx"; printf '%s\tRG-0.1\t%s\t10 CP-1.6 enables it (row 2): re-run before 16 RG-8.2\tPENDING\t-\n' "$d" "$P16_SCC_RERUN"; } \
           | xw "$idx" 644 || return 1
       fi;;
    *) echo "STOP: cannot read CORE_PROJECT's services"; return 1;;
  esac
  c="$(awk '/^## Closures$/{print NR; exit}' "$(v DEVIATION_REGISTER)")"
  for id in BD-16-1 BD-16-2 BD-16-3 BD-16-4 BD-16-5; do
    l="$(awk -F' *[|] *' -v id="$id" '$2 == id && NF == 15 {print NR; exit}' "$(v DEVIATION_REGISTER)")"
    [ -n "$l" ] && [ -n "$c" ] && [ "$l" -lt "$c" ] || { echo "STOP: $id is not a row above '## Closures'"; return 1; }
  done
  echo "REVIEW: the second human reads BD-16-2 and initials the build-log line"
}

step RG-10.2 HUMAN "End the sitting" --needs "BUILD_LOG_DIR"
s_RG_10_2_check() { ckpt_done RG-10.2; }
s_RG_10_2_manual() {
  echo "WHO: the platform owner, at the end of the sitting (never in the middle of a multi-phase apply: it revokes every credential)."
  echo "DO: RG-10.2's README edits by hand, if absent: the seven re-run index lines it quotes (security reviewer appointed;"
  echo "  15 part A channels; Mo bot and identities; each Tier W+ agent; SIEM desk and gemini-egress; REGISTER_CI_COMMIT; B-02),"
  echo "  and check README section 8 rows B-02, B-03 and B-23 name 16. Then: agp-platform sitting end   (SITTING-END OK)."
  echo "VERIFY: README holds the seven lines; checkpoints.tsv holds DONE for every RG step except RG-3.3, RG-3.4, RG-3.5,"
  echo "  RG-7.6, RG-8.2, RG-8.3, RG-9.2 (BLOCKED); RG-5.6 and RG-5.7 may be PENDING on 15."
  echo "Then: agp-platform done RG-10.2 --note \"file 16 complete except RG-3.3, RG-3.4, RG-3.5, RG-7.6, RG-8.2, RG-8.3, RG-9.2 BLOCKED\""
}
