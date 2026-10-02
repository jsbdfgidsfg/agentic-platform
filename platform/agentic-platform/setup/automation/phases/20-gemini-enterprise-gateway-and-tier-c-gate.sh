# phases/20-gemini-enterprise-gateway-and-tier-c-gate.sh: setup/20, the Gemini Enterprise egress gateway
# (the throwaway-app spike, gemini-egress in DRY_RUN, the registry, the production binding), the Tier C
# detections and the Tier C gate record.
#
# How the page maps onto the classes:
# - The spike (GG-2) is an experiment: questions asked in the throwaway app, answers typed into the spike
#   record with 19's and GG-0.2's helpers (ge_call, pam_grant, gg_answer), console attempts, a colleague's
#   agents.create test. Those steps are HUMAN or CONSOLE; the script never sources the helper files and
#   never types an answer.
# - Files copied from the page (lib/PHASES.md): GG-0.2 (gg-helpers.sh), GG-1.2 (the throwaway gateway
#   YAML), GG-1.3 (the throwaway extension YAML), GG-1.4 (the throwaway authorisation policy), GG-3.1
#   (gemini-egress.yaml), GG-3.3 (gemini-egress's authorisation policy) and GG-4.5
#   (tools/ge-share-precheck.sh) write their heredoc bodies from assets/gg-*, named in assets/20.manifest,
#   so the tests fail when the page changes. These seven steps are AUTO: the page gives each to the
#   platform owner, in the shell. An unquoted heredoc's only expansion, ${GEMINI_PROJECT}, is substituted
#   by _p20_render, which refuses an asset holding any other `$`. GG-1.4 and GG-3.3 open their heredocs
#   with <<AUTHZ_POLICY, so their opening lines differ from GG-1.2's and GG-3.1's.
# - GG-3.4 stays HUMAN: it has no heredoc, and its rule names the principal a person read from spike Q2.
# - Where the page says "merged", the push and the review on the git host are the platform owner's
#   (phases/03 header): GG-4.5 commits locally and says so; GG-3.4's person commits factory/runs/gemini-prod.
# - GG-1.1, GG-2.6, GG-5.7 and GG-8.2 also write heredocs, but each is HUMAN for another reason (GG-1.1's N/A
#   reading and its stop-on-refusal rule inside an attended grant, GG-2.6's console CREATE and three-way
#   grading, GG-5.7's methodTypes from that grading, GG-8.2's Result cells and signatures), so they have no asset.
# - GG-5.3, the production binding, is HUMAN with the second human as witness at the screen: the page
#   gives it the largest blast radius in the file and no documented undo before spike Q7.
# - When GG-2.11 recorded the compensating control (decisions/*-ge-binding-compensating-control.md), the
#   page makes GG-3 to GG-5 N/A: every check of those steps returns 5 (not applicable), and the AUTO
#   applies refuse to run as well (_p20_go_guard).
# - The deterministic Cloud work with no heredoc is AUTO: GG-0.5 (enable the gateway APIs), GG-1.5 (the
#   spike access policy and its binding), GG-3.2 (the production IAP extension, which the page writes with
#   printf) and GG-7.2 (three log-based alert policies, which the page builds with jq).
# - Evidence: every build-log: row is registered with its file, so the register holds its SHA-256
#   (42 GD-4.1); the manual texts quote the page's lines.
# - Every PAM grant goes through the platform owner's own request (gcloud pam grants create) and waits for
#   the approver 12 or 19 named; nothing privileged is held standing, so the phase declares no `requires`.
#   GG-0.5 and GG-1.5 end with the page's `gcloud pam grants revoke`, so they declare --removes.
# - The imports (GG-1.2, GG-1.3, GG-1.4, GG-3.1, GG-3.2, GG-3.3) run only after the check read the object
#   as absent or not in the page's state; `import` creates it or updates it to the file, so no second read
#   guards it. GG-1.5
#   and GG-7.2 make several objects: their checks read every one and the apply makes only those the check
#   found absent (_p20_seen, _p20_absent), as the runner calls the apply right after the check.
# - Launch stage: the page records it on the day (GG-0.4's launch-stage.txt; on 2026-10-01 neither Google
#   page carried a Preview banner), so no step title here calls Agent Gateway Preview.
# - The page uses "### GG-0 The sitting and the preflight" and the like as section headings at the same
#   level as its steps; the scope "GG-[0-9]+\." keeps the registered ids to the 54 numbered steps.
#
# Helpers are prefixed _p20_ because every phase file is loaded into the same shell.

phase 20 "Gemini Enterprise: the egress gateway and the Tier C gate" "20-gemini-enterprise-gateway-and-tier-c-gate.md" "GG-[0-9]+\."

# ---------------------------------------------------------------- helpers
_p20_m()     { local l; for l in "$@"; do printf '%s\n' "$l"; done; }   # manual text, one argument per line
_p20_today() { date -u +%Y-%m-%d; }
_p20_dir()   { printf '%s/ge-gateway' "$(v BUILD_LOG_DIR)"; }
_p20_plan()  { [ "$AGP_MODE" = apply ] || printf '      %s\n' "$*" >&3; }

_p20_file() {   # STEP SLUG EXT [restricted]: GG-0.2's gg_file, the next free version of the file
  local d n=1
  d="$(_p20_dir)"; [ "${4-}" = restricted ] && d="$d/restricted"
  while [ -e "$d/$(_p20_today)-$1-$2-v${n}.$3" ]; do n=$((n + 1)); done
  printf '%s\n' "$d/$(_p20_today)-$1-$2-v${n}.$3"
}

_p20_mkdirs() { # the working directory of GG-0.2, made again if a step runs on its own
  local d; d="$(_p20_dir)"
  if [ "$AGP_MODE" = apply ] && [ -d "$d/restricted" ]; then return 0; fi
  x mkdir -p "$d/restricted"
}

_p20_asset() {  # NAME: 0 when assets/NAME exists; otherwise a STOP line naming the manifest
  [ -f "$AGP_HOME/assets/$1" ] && return 0
  echo "STOP: assets/$1 is absent: the script does not retype the page's heredoc (lib/PHASES.md); restore it with its assets/20.manifest line, or paste the page's block by hand"
  return 1
}

_p20_render() { # NAME: an asset from an unquoted heredoc, with ${GEMINI_PROJECT} expanded as the page's shell would
  local out
  _p20_asset "$1" >&2 || return 1
  out="$(sed "s|\${GEMINI_PROJECT}|$(v GEMINI_PROJECT)|g" "$AGP_HOME/assets/$1")" || return 1
  case "$out" in *'$'*) echo "STOP: assets/$1 holds an expansion other than \${GEMINI_PROJECT}; the page changed: update _p20_render" >&2; return 1;; esac
  printf '%s\n' "$out"
}

_p20_compensating() {   # 0 when GG-2.11 recorded the compensating control: the page makes GG-3 to GG-5 N/A
  local f
  has_value PLATFORM_REPO_DIR || return 1
  for f in "$(_penv_get PLATFORM_REPO_DIR)"/decisions/*-ge-binding-compensating-control.md; do
    [ -f "$f" ] && return 0
  done
  return 1
}
_p20_na() {         # the first line of every GG-3 to GG-5 check: 5 (not applicable) on the compensating-control outcome
  _p20_compensating || return 1
  echo "      N/A: GG-2.11 recorded the compensating control (decisions/*-ge-binding-compensating-control.md)" >&3
  return 0
}
_p20_go_guard() {   # the AUTO applies of GG-3 refuse as well, should one be run on its own
  _p20_compensating || return 0
  echo "STOP: GG-2.11 recorded the compensating control: GG-3 to GG-5 are N/A; nothing of gemini-egress is made"
  return 1
}

_p20_grant_has() {  # ENTITLEMENT FILTER: a grant the caller created on it matches FILTER (0 yes, 1 no, 2 error, 3 offline)
  nonempty r gcloud pam grants search --entitlement="$1" --caller-relationship=had-created \
    --filter="$2" --format='value(name)' --billing-project="$(v CICD_PROJECT)"
}

_p20_grant() {  # ENT_NAME SECONDS JUSTIFICATION: an ACTIVE grant of the caller, requested once and awaited
  local ent rc i=0
  ent="$(v "$1")"
  if [ "$AGP_MODE" != apply ]; then
    x gcloud pam grants create --entitlement="$ent" --requested-duration="${2}s" --justification="$3" \
      --billing-project="$(v CICD_PROJECT)" --format='value(name)'
    _p20_plan "then waits until the approver 12 or 19 named approves (state ACTIVE); nothing privileged runs before"
    return 0
  fi
  _p20_grant_has "$ent" 'state=ACTIVE'; rc=$?
  if [ $rc -eq 0 ]; then echo "an ACTIVE grant on $1 exists; not requested again"; return 0; fi
  [ $rc -eq 1 ] || return 2
  _p20_grant_has "$ent" 'state=APPROVAL_AWAITED OR state=SCHEDULED OR state=ACTIVATING'; rc=$?
  case $rc in
    0) echo "a grant on $1 is already waiting for approval; not requested again";;
    1) x gcloud pam grants create --entitlement="$ent" --requested-duration="${2}s" --justification="$3" \
         --billing-project="$(v CICD_PROJECT)" --format='value(name)' || return 1;;
    *) return 2;;
  esac
  echo "waiting for the approver (up to 15 minutes)"
  while [ $i -lt 30 ]; do
    if _p20_grant_has "$ent" 'state=ACTIVE'; then echo "STATE ACTIVE"; return 0; fi
    i=$((i + 1)); sleep 30
  done
  echo "STOP: the grant on $1 is not ACTIVE after 15 minutes; when the approver has approved, resume from this step"
  return 1
}

_p20_revoke() { # ENT_NAME REASON: the page's `gcloud pam grants revoke` for each ACTIVE grant the caller made on it
  local ent names g
  ent="$(v "$1")"
  if [ "$AGP_MODE" != apply ]; then
    x gcloud pam grants revoke --billing-project="$(v CICD_PROJECT)" "<ACTIVE-grant-on-$1>" --reason="$2"
    return 0
  fi
  names="$(r gcloud pam grants search --entitlement="$ent" --caller-relationship=had-created \
    --filter='state=ACTIVE' --format='value(name)' --billing-project="$(v CICD_PROJECT)")" || return 1
  for g in $names; do
    x gcloud pam grants revoke --billing-project="$(v CICD_PROJECT)" "$g" --reason="$2" || return 1
  done
  return 0
}

# What a multi-resource check read, kept for the apply the runner calls right after it in the same shell, so
# the apply creates only what the check found absent instead of reading everything a second time.
_P20_SEEN_STEP=""; _P20_SEEN_ABSENT=" "; _P20_SEEN_RC=0
_p20_seen_reset() { _P20_SEEN_STEP="$1"; _P20_SEEN_ABSENT=" "; _P20_SEEN_RC=0; }
_p20_seen() {       # LABEL CMD...: run the read (0 present, 1 absent, 2 error, 3 offline) and remember the label if not present
  local label="$1" rc
  shift; "$@"; rc=$?
  [ $rc -eq 0 ] && return 0
  _P20_SEEN_ABSENT="$_P20_SEEN_ABSENT$label "
  if [ $rc -eq 1 ]; then [ $_P20_SEEN_RC -ne 0 ] || _P20_SEEN_RC=1
  elif [ $_P20_SEEN_RC -le 1 ]; then _P20_SEEN_RC=$rc; fi
  return $rc
}
_p20_seen_result() { return $_P20_SEEN_RC; }   # 0 all present, 1 one absent, 2 or 3 the first other outcome
_p20_absent() {     # STEP LABEL CMD...: 0 create it, 1 present, 2 cannot tell. Uses STEP's check when it just ran
  local rc
  if [ "$_P20_SEEN_STEP" = "$1" ]; then case "$_P20_SEEN_ABSENT" in *" $2 "*) return 0;; *) return 1;; esac; fi
  [ "$AGP_MODE" = apply ] || return 0
  shift 2; "$@"; rc=$?
  case $rc in 0) return 1;; 1) return 0;; *) return 2;; esac
}

# ======================================================================== GG-0 The sitting and the preflight

step GG-0.1 HUMAN "Open the sitting and check the gate" \
  --needs "BUILD_LOG_DIR PLATFORM_REPO_DIR EVIDENCE_REGISTER DEVIATION_REGISTER DRILL_CALENDAR ORG_ID DOMAIN REGION GE_LOCATION SA_1_ADMIN GEMINI_PROJECT GEMINI_PROJECT_NUMBER GEMINI_APP_ID GEMINI_APP_LOCATION GE_INVENTORY_DIR GE_THROWAWAY_APP_ID GE_ARMOR_TEMPLATE ENT_GE_ADMIN ENT_PLATFORM_POLICY GRP_GE_ADMINS GRP_GE_USERS CORE_PROJECT LOGGING_PROJECT CICD_PROJECT AGENT_REGISTRY TIER_R_RECORD SCC_ROUTE_TEST_SOURCE SCC_TIER CANARY_R_PROJECT SECOND_HUMAN_EMAIL ENT_PROJECT_REPAIR_TENANT_APP"
s_GG_0_1_check() { ckpt_done GG-0.1; }
s_GG_0_1_manual() {
  _p20_m "WHY HUMAN: the sign-in (gcloud auth login, hardware key) and the opening of the sitting are a person's." \
    "WHO: the platform owner, solo. WHERE: the shell, ~/.platform-env sourced; the browser profile of sa-1-admin@." \
    "DO: agp-platform sitting start; then GG-0.1's block of setup/20 (penv_guard, need, the eu / SCC / repair-entitlement" \
    "  tests, gcloud auth login \"\$SA_1_ADMIN\", the GE checkpoint counts of 19, the PS-6.8 record listing)." \
    "VERIFY: no STOP; 19's BLOCKED list is exactly GE-2.6 and GE-6.7 (and GE-8.3's drift job); PS-6.8's record is listed;" \
    "  gcloud auth list --filter=status:ACTIVE --format='value(account)' prints SA_1_ADMIN. Evidence: checkpoint lines." \
    "Then: agp-platform done GG-0.1"
}

step GG-0.2 AUTO "Working directory and helpers" --needs "BUILD_LOG_DIR GEMINI_PROJECT_NUMBER"
s_GG_0_2_check() {  # restricted/ and records/ exist, the .gitignore line is there, gg-helpers.sh is the page's
  local b d
  b="$(v BUILD_LOG_DIR)"; d="$(_p20_dir)"
  [ -d "$d/restricted" ] && [ -d "$b/records" ] || return 1
  grep -qxF 'ge-gateway/restricted/' "$b/.gitignore" 2>/dev/null || return 1
  cmp -s "$AGP_HOME/assets/gg-0.2-gg-helpers.sh" "$d/gg-helpers.sh"
}
s_GG_0_2_apply() {
  local b d gi out
  b="$(v BUILD_LOG_DIR)"; d="$(_p20_dir)"; gi="$b/.gitignore"
  _p20_asset gg-0.2-gg-helpers.sh || return 1
  [ -f "$b/ge-baseline/ge-helpers.sh" ] \
    || echo "NOTE: $b/ge-baseline/ge-helpers.sh (19) is absent: every hand-run block of setup/20 sources it; finish 19 before GG-0.3"
  if [ "$AGP_MODE" != apply ] || [ ! -d "$d/restricted" ] || [ ! -d "$b/records" ]; then
    x mkdir -p "$d/restricted" "$b/records" || return 1
  fi
  if ! grep -qxF 'ge-gateway/restricted/' "$gi" 2>/dev/null; then   # the page appends the line once
    { if [ -f "$gi" ]; then cat "$gi"; fi; printf '%s\n' 'ge-gateway/restricted/'; } | xw "$gi" 644 || return 1
  fi
  xw "$d/gg-helpers.sh" 644 < "$AGP_HOME/assets/gg-0.2-gg-helpers.sh" || return 1
  if [ "$AGP_MODE" = apply ]; then   # the page's VERIFY for this file's four functions, in a child shell
    out="$(BUILD_LOG_DIR="$b" GEMINI_PROJECT_NUMBER="$(v GEMINI_PROJECT_NUMBER)" bash -c '
      . "$1" || exit 3
      type gg_file gg_answer gg_result gg_engine_view >/dev/null || exit 4
      case "$GG_ENGINES" in *"projects/${GEMINI_PROJECT_NUMBER}/locations/eu"*) ;; *) exit 5;; esac
      unset GG_SPIKE; gg_answer QTEST x maybe; exit 0' _ "$d/gg-helpers.sh" 2>&1)" \
      || { printf '%s\n' "$out"; echo "STOP: gg-helpers.sh does not load, define its four functions or name the project number"; return 1; }
    case "$out" in *"STOP: gg_answer result must be PASS, FAIL or RECORDED"*) echo "gg_answer QTEST x maybe: refused, as required";;
      *) printf '%s\n' "$out"; echo "STOP: gg_answer accepted the result word 'maybe'"; return 1;; esac
  fi
  echo "In every later sitting (the page's On resume line): source ~/.platform-env; source \"\$BUILD_LOG_DIR/ge-baseline/ge-helpers.sh\";"
  echo "  source \"\$BUILD_LOG_DIR/ge-gateway/gg-helpers.sh\"; then type ge_call pam_grant pam_active ma_eu names 19's four."
}

step GG-0.3 HUMAN "Extend the tenant-app repair entitlement with the gateway roles" \
  --needs "ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT GEMINI_PROJECT DEVIATION_REGISTER BUILD_LOG_DIR"
s_GG_0_3_check() { ckpt_done GG-0.3; }
s_GG_0_3_manual() {
  _p20_m "WHY HUMAN: the edit relies on yq (an Assumption of the page) and on the person removing any field" \
    "  'entitlements update' refuses, recording each refusal; the grant test needs the second human's approval." \
    "WHO: the platform owner as PAM administrator (platform-owners@). WHERE: the shell, gg-helpers.sh sourced." \
    "DO: GG-0.3's block of setup/20 (describe to entitlement-before, the six roles describe, yq to entitlement-after," \
    "  diff, gcloud pam entitlements update --billing-project=\"\$CICD_PROJECT\" ... --entitlement-file, bd_insert BD-20-1," \
    "  one 1800s grant, pam_active, revoke)." \
    "VERIFY: roleBindings list 19's five roles plus the six; approvalWorkflow still names the second human; pam_active" \
    "  printed ACTIVE. Evidence: evidence_add GG-0.3 repair-entitlement-gateway E-05 4.1.3 \"build-log:ge-gateway/\$(basename \"\$g\")\" \"\$g\"." \
    "Then: agp-platform done GG-0.3"
}

step GG-0.4 HUMAN "Read the before state and open the spike record" \
  --needs "GEMINI_PROJECT GEMINI_PROJECT_NUMBER GEMINI_APP_ID GE_THROWAWAY_APP_ID BUILD_LOG_DIR" --sets "GE_APB_CONSTRAINT GE_SPIKE_RECORD"
s_GG_0_4_check() { ckpt_done GG-0.4; }
s_GG_0_4_manual() {
  _p20_m "WHY HUMAN: the block opens the spike record from a heredoc, records the launch stage read by a person on" \
    "  Google's pages, and reads the console (Gemini Enterprise > production app > Security > Configuration)." \
    "WHO: the platform owner, solo. WHERE: the shell, both helper files sourced; the console, read only." \
    "DO: GG-0.4's block of setup/20. The constraint loop tries iam.managed.disableAccessPolicyBinding (singular, on the" \
    "  constraints reference updated 2026-09-30) first; the block writes the winner to \$GG_DIR/constraint-id.txt." \
    "RECORD (in the block): penv_set GE_APB_CONSTRAINT ...; penv_set GE_SPIKE_RECORD \"\$GG_SPIKE\". Fill launch-stage.txt" \
    "  with the stage read on the day and its page (a Pre-GA stage goes into GG-2.11's go record). Ends: checkpoint GG-0.4 DONE." \
    "VERIFY: the production engine has no agentGatewaySetting (bound is a stop); no gateway exists; modelarmor, logging," \
    "  monitoring and discoveryengine are enabled (else re-run 19 GE-2.4); RESOLVED printed and no STOP." \
    "Evidence: evidence_add GG-0.4 before-state E-05 5.2.7 \"build-log:ge-gateway/\$(basename \"\$E0\")\" \"\$E0\""
}

step GG-0.5 AUTO "Enable the Agent Gateway APIs on GEMINI_PROJECT" --removes \
  --needs "GEMINI_PROJECT ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR DEVIATION_REGISTER EVIDENCE_REGISTER"
_p20_svc_enabled() {    # SERVICE: 0 when it is enabled on GEMINI_PROJECT
  nonempty r gcloud services list --enabled --project="$(v GEMINI_PROJECT)" --filter="config.name=$1" --format='value(config.name)'
}
s_GG_0_5_check() {   # the page's VERIFY loop (the seven gateway APIs, modelarmor and discoveryengine enabled), and BD-20-2 written
  local s rc worst=0   # every service is read, so the result names all that are missing, not only the first
  for s in networkservices.googleapis.com networksecurity.googleapis.com iap.googleapis.com iam.googleapis.com \
           compute.googleapis.com dns.googleapis.com agentregistry.googleapis.com modelarmor.googleapis.com discoveryengine.googleapis.com; do
    _p20_svc_enabled "$s"; rc=$?
    case $rc in 0) ;; 1) [ $worst -ne 0 ] || worst=1;; *) worst=$rc;; esac
  done
  [ $worst -eq 0 ] || return $worst
  [ -f "$(v DEVIATION_REGISTER)" ] && grep -q '^| BD-20-2 |' "$(v DEVIATION_REGISTER)"
}
s_GG_0_5_apply() {
  local p before after a eff rc s off="" row gone stop=0 svc obs obs_on
  svc=(networkservices.googleapis.com networksecurity.googleapis.com iap.googleapis.com iam.googleapis.com compute.googleapis.com dns.googleapis.com agentregistry.googleapis.com)
  obs=(observability.googleapis.com telemetry.googleapis.com cloudtrace.googleapis.com)
  obs_on=()
  p="$(v GEMINI_PROJECT)"
  _p20_mkdirs || return 1
  if [ "$AGP_MODE" != apply ]; then
    _p20_plan "reads: gcloud services list --enabled --project=$p --format=json > <date>-GG-0.5-services-before-v1.json"
    _p20_plan "       gcloud org-policies describe gcp.restrictServiceUsage --project=$p --effective --format=json"
    _p20_plan "       each of the seven APIs must be on the allow-list (STOP otherwise: 19 GE-3.5 and 13 own the list);"
    _p20_plan "       observability, telemetry and cloudtrace are enabled only where the allow-list carries them"
    _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 1800 "setup 20 GG-0.5 enable the Agent Gateway APIs on the app project"
    x gcloud services enable "${svc[@]}" "<observability-APIs-on-the-allow-list>" --project="$p"
    _p20_plan "reads: services-after; comm against services-before (nothing may go away)"
    _p20_revoke ENT_PROJECT_REPAIR_TENANT_APP "GG-0.5 done"
    x bd_insert "<BD-20-2-row>"
    _p20_plan "  the row: | BD-20-2 | <date> | 20 GG-0.5 | MOD | tenant-app: the run spec services list (17 FM-6.1) is short by"
    _p20_plan "  <services>; observability APIs deliberately off: <off> | project $p | factory/runs/gemini-prod.json | services"
    _p20_plan "  enabled additively, none disabled | <services-after file> | n/a: existing project | ENT_PROJECT_REPAIR_TENANT_APP"
    _p20_plan "  grant, second human | superseded when the factory tenant-app module is written (B-01) | open |"
    ev GG-0.5 gateway-apis-enabled E-05 5.2.1 "build-log:ge-gateway/<after>"
    return 0
  fi
  [ -f "$(v DEVIATION_REGISTER)" ] || { echo "STOP: DEVIATION_REGISTER ($(v DEVIATION_REGISTER)) does not exist (01 PR-4.1); BD-20-2 could not be written, so nothing is enabled"; return 1; }
  before="$(_p20_file GG-0.5 services-before json)"
  r gcloud services list --enabled --project="$p" --format=json | xw "$before" 644 || return 1
  eff="$(r gcloud org-policies describe gcp.restrictServiceUsage --project="$p" --effective --format=json 2>&1)"; rc=$?
  if [ $rc -eq 0 ]; then
    a="$(_p20_file GG-0.5 restrict-service-usage-effective json)"
  else
    case "$eff" in
      *NOT_FOUND*|*"not found"*) echo "no effective gcp.restrictServiceUsage policy on $p: the constraint does not govern these services";;
      *) printf '%s\n' "$eff"; echo "STOP: the effective gcp.restrictServiceUsage read failed; nothing was enabled"; return 1;;
    esac
    a="$(_p20_file GG-0.5 restrict-service-usage-effective txt)"
  fi
  printf '%s\n' "$eff" | xw "$a" 644 || return 1
  if [ $rc -eq 0 ] && jq -e '.spec.rules[0].values.allowedValues // empty' "$a" >/dev/null 2>&1; then
    for s in "${svc[@]}"; do
      jq -e --arg s "$s" '[.spec.rules[0].values.allowedValues[]] | index($s) != null' "$a" >/dev/null \
        || { echo "STOP: $s not in the folder allow-list; owner: platform owner via 19 GE-3.5 and 13's fld-gemini-enterprise policy file. Do not start GG-1."; stop=1; }
    done
    [ $stop -eq 0 ] || return 1
    for s in "${obs[@]}"; do
      if jq -e --arg s "$s" '[.spec.rules[0].values.allowedValues[]] | index($s) != null' "$a" >/dev/null; then obs_on+=("$s")
      else echo "OFF $s: not on the fld-gemini-enterprise allow-list; recorded as deliberately off in BD-20-2 until 19 GE-3.5 adds it"; fi
    done
  else
    echo "gcp.restrictServiceUsage not in allow-list form on this project; record the effective read and continue"
    obs_on=("${obs[@]}")
  fi
  _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 1800 "setup 20 GG-0.5 enable the Agent Gateway APIs on the app project" || return 1
  x gcloud services enable "${svc[@]}" ${obs_on[@]+"${obs_on[@]}"} --project="$p" || return 1
  after="$(_p20_file GG-0.5 services-after json)"
  r gcloud services list --enabled --project="$p" --format=json | xw "$after" 644 || return 1
  echo "added by this step:"
  comm -13 <(jq -r '.[].config.name' "$before" | sort) <(jq -r '.[].config.name' "$after" | sort) | sed 's/^/  /'
  gone="$(comm -23 <(jq -r '.[].config.name' "$before" | sort) <(jq -r '.[].config.name' "$after" | sort))"
  [ -z "$gone" ] || { echo "STOP: these services were on before and are not now: $gone"; return 1; }
  _p20_revoke ENT_PROJECT_REPAIR_TENANT_APP "GG-0.5 done" || return 1
  for s in "${obs[@]}"; do case " ${obs_on[*]:-} " in *" $s "*) ;; *) off="$off$s ";; esac; done
  row=$(printf '| BD-20-2 | %s | 20 GG-0.5 | MOD | tenant-app: the run spec services list (17 FM-6.1) is short by %s; observability APIs deliberately off: %s | project %s | factory/runs/gemini-prod.json | services enabled additively, none disabled | %s | n/a: existing project | ENT_PROJECT_REPAIR_TENANT_APP grant, second human | superseded when the factory tenant-app module is written (B-01) | open |\n' \
    "$(date -u +%F)" "$(IFS=,; echo "${svc[*]} ${obs_on[*]:-}")" "$off" "$p" "$after")
  x bd_insert "$row" || return 1
  ev GG-0.5 gateway-apis-enabled E-05 5.2.1 "build-log:ge-gateway/$(basename "$after")" "$after"
}

# ======================================================================== GG-1 The throwaway gateway chain

step GG-1.1 HUMAN "Lift the access-policy binding constraint on GEMINI_PROJECT, if not already lifted" --witness \
  --needs "GE_APB_CONSTRAINT GEMINI_PROJECT PLATFORM_REPO_DIR ENT_PLATFORM_POLICY CICD_PROJECT FLD_GEMINI_ENTERPRISE"
s_GG_1_1_check() { ckpt_done GG-1.1; }
s_GG_1_1_manual() {
  _p20_m "WHY HUMAN: N/A is a person's reading of GG-0.4's effective read (enforce: false already); the VERIFY waits up to" \
    "  15 minutes; a refusal naming the id is a stop judged inside a grant the second human approves and attends." \
    "WHO: the platform owner under ENT_PLATFORM_POLICY; approver: the second human. WHERE: the shell, in PLATFORM_REPO_DIR." \
    "DO: GG-1.1's block of setup/20 with the id GG-0.4 resolved (\$GE_APB_CONSTRAINT; on 2026-10-01 the reference reads" \
    "  iam.managed.disableAccessPolicyBinding): the .before.yaml, the enforce: false file, commit, grant, set-policy, revoke." \
    "VERIFY: gcloud org-policies describe \"\$GE_APB_CONSTRAINT\" --project=\"\$GEMINI_PROJECT\" --effective" \
    "  --format='value(spec.rules[0].enforce)' prints False within 15 minutes; the folder's policy is unchanged (13 row B7)." \
    "  A set-policy refusal naming the id: revert, return to GG-0.4, never retry the other spelling inside this grant." \
    "Evidence: evidence_add GG-1.1 access-policy-binding-lift E-03 5.2.1 \"platform-repo:\$f\"." \
    "Then: agp-platform done GG-1.1 --witness <second human's email>"
}

step GG-1.2 AUTO "Import the throwaway gateway" \
  --needs "GEMINI_PROJECT ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_GG_1_2_check() {   # the gateway describes; after the teardown (GG-6.1) it is gone by design
  ckpt_done GG-6.1 && return 0
  exists r gcloud network-services agent-gateways describe gg-spike-egress --location=europe-west1 --project="$(v GEMINI_PROJECT)"
}
s_GG_1_2_apply() {
  local p w d body
  p="$(v GEMINI_PROJECT)"
  _p20_mkdirs || return 1
  body="$(_p20_render gg-1.2-spike-gateway.yaml)" || return 1
  _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 3600 "setup 20 GG-1 throwaway gateway chain (spike, P59)" || return 1
  w="$(_p20_file GG-1.2 gg-spike-egress yaml)"
  printf '%s\n' "$body" | xw "$w" 644 || return 1
  # the runner applies only after the check read the gateway as absent; import creates it, or updates it to the file
  x gcloud network-services agent-gateways import gg-spike-egress --source="$w" --location=europe-west1 --project="$p" || return 1
  d="$(_p20_file GG-1.2 gg-spike-egress-describe yaml)"
  if [ "$AGP_MODE" = apply ]; then
    r gcloud network-services agent-gateways describe gg-spike-egress --location=europe-west1 --project="$p" --format=yaml | xw "$d" 644 || return 1
    sed 's/^/  /' "$d"
    echo "REVIEW: governedAccessPath AGENT_TO_ANYWHERE, the europe-west1 registry of $p, protocols [MCP]."
    echo "  The grant stays open: GG-1.3 to GG-1.5 run under it, and GG-1.5 revokes it."
  else
    _p20_plan "reads: gcloud network-services agent-gateways describe gg-spike-egress --location=europe-west1 --project=$p --format=yaml > $d"
  fi
  ev GG-1.2 spike-gateway E-05 5.2.7 "build-log:ge-gateway/$(basename "$d")" "$d"
}

step GG-1.3 AUTO "Import the IAP authorisation extension in DRY_RUN" \
  --needs "GEMINI_PROJECT ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
_p20_spike_ext_dry_run() {  # the page's VERIFY as a filtered list: the extension exists in DRY_RUN
  nonempty r gcloud service-extensions authz-extensions list --location=europe-west1 --project="$(v GEMINI_PROJECT)" \
    --filter='name:gg-spike-iap-authz AND metadata.iamEnforcementMode=DRY_RUN' --format='value(name)'
}
s_GG_1_3_check() {   # after the teardown (GG-6.1) the extension is gone by design
  ckpt_done GG-6.1 && return 0
  _p20_spike_ext_dry_run
}
s_GG_1_3_apply() {
  local p w d
  p="$(v GEMINI_PROJECT)"
  _p20_mkdirs || return 1
  _p20_asset gg-1.3-spike-iap-authz.yaml || return 1
  _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 3600 "setup 20 GG-1 throwaway gateway chain (spike, P59)" || return 1
  w="$(_p20_file GG-1.3 gg-spike-iap-authz yaml)"
  xw "$w" 644 < "$AGP_HOME/assets/gg-1.3-spike-iap-authz.yaml" || return 1
  # the check read no DRY_RUN extension; import creates it, or puts an existing one back to the file (DRY_RUN)
  _p20_plan "(the GA group first; the beta group only if the GA import is refused, as the page writes it)"
  x gcloud service-extensions authz-extensions import gg-spike-iap-authz --source="$w" --location=europe-west1 --project="$p" \
    || x gcloud beta service-extensions authz-extensions import gg-spike-iap-authz --source="$w" --location=europe-west1 --project="$p" \
    || return 1
  d="$(_p20_file GG-1.3 gg-spike-iap-authz-describe yaml)"
  if [ "$AGP_MODE" = apply ]; then
    r gcloud service-extensions authz-extensions describe gg-spike-iap-authz --location=europe-west1 --project="$p" --format=yaml | xw "$d" 644 || return 1
    sed 's/^/  /' "$d"
    _p20_spike_ext_dry_run || { echo "STOP: gg-spike-iap-authz is not listed with metadata.iamEnforcementMode DRY_RUN"; return 1; }
    echo "REVIEW: the describe above shows failOpen: false (or no failOpen field, its default)."
  else
    _p20_plan "reads: gcloud service-extensions authz-extensions describe gg-spike-iap-authz --location=europe-west1 --project=$p --format=yaml > $d"
  fi
  ev GG-1.3 spike-authz-extension E-05 5.2.7 "build-log:ge-gateway/$(basename "$d")" "$d"
}

step GG-1.4 AUTO "Import the authorisation policy for the throwaway gateway" \
  --needs "GEMINI_PROJECT ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
_p20_authz_policy_ok() {    # NAME: the page's VERIFY as a filtered list: the authorisation policy exists with action CUSTOM
  nonempty r gcloud network-security authz-policies list --location=europe-west1 --project="$(v GEMINI_PROJECT)" \
    --filter="name:$1 AND action=CUSTOM" --format='value(name)'
}
s_GG_1_4_check() {   # after the teardown (GG-6.1) the policy is gone by design
  ckpt_done GG-6.1 && return 0
  _p20_authz_policy_ok gg-spike-authz-policy
}
s_GG_1_4_apply() {
  local p w d body
  p="$(v GEMINI_PROJECT)"
  _p20_mkdirs || return 1
  body="$(_p20_render gg-1.4-spike-authz-policy.yaml)" || return 1
  _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 3600 "setup 20 GG-1 throwaway gateway chain (spike, P59)" || return 1
  w="$(_p20_file GG-1.4 gg-spike-authz-policy yaml)"
  printf '%s\n' "$body" | xw "$w" 644 || return 1
  # the check read no CUSTOM policy of that name; import creates it, or updates it to the file
  x gcloud network-security authz-policies import gg-spike-authz-policy --source="$w" --location=europe-west1 --project="$p" || return 1
  d="$(_p20_file GG-1.4 gg-spike-authz-policy-describe yaml)"
  if [ "$AGP_MODE" = apply ]; then
    r gcloud network-security authz-policies describe gg-spike-authz-policy --location=europe-west1 --project="$p" --format=yaml | xw "$d" 644 || return 1
    sed 's/^/  /' "$d"
    _p20_authz_policy_ok gg-spike-authz-policy || { echo "STOP: gg-spike-authz-policy is not listed with action CUSTOM"; return 1; }
    echo "REVIEW: the describe above targets agentGateways/gg-spike-egress and names authzExtensions/gg-spike-iap-authz."
  else
    _p20_plan "reads: gcloud network-security authz-policies describe gg-spike-authz-policy --location=europe-west1 --project=$p --format=yaml > $d"
  fi
  ev GG-1.4 spike-authz-policy E-05 5.2.7 "build-log:ge-gateway/$(basename "$d")" "$d"
}

step GG-1.5 AUTO "A starter IAM access policy naming the throwaway app" --removes \
  --needs "ORG_ID GEMINI_PROJECT GEMINI_PROJECT_NUMBER GE_THROWAWAY_APP_ID ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_GG_1_5_check() {   # the policy and its binding describe; after the teardown (GG-6.1) they are gone by design
  local p
  _p20_seen_reset GG-1.5
  ckpt_done GG-6.1 && return 0
  p="$(v GEMINI_PROJECT)"
  _p20_seen access-policy exists r gcloud iam access-policies describe gg-spike-access --project="$p" --location=global
  _p20_seen policy-binding exists r gcloud iam policy-bindings describe gg-spike-access-binding --project="$p" --location=global
  _p20_seen_result
}
s_GG_1_5_apply() {
  local p pr w d rc
  p="$(v GEMINI_PROJECT)"
  pr="principal://agents.global.org-$(v ORG_ID).system.id.goog/resources/discoveryengine/projects/$(v GEMINI_PROJECT_NUMBER)/locations/eu/engines/$(v GE_THROWAWAY_APP_ID)/assistants/default_assistant/agents/default/core_assistant"
  _p20_mkdirs || return 1
  w="$(_p20_file GG-1.5 gg-spike-access-rules json)"
  jq -n --arg p "$pr" '[{description:"setup 20 spike: throwaway app egress, evaluated in DRY_RUN", effect:"ALLOW", principals:[$p], operation:{permissions:["iap.googleapis.com/resources.egressViaIAP"]}}]' | xw "$w" 644 || return 1
  _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 3600 "setup 20 GG-1 throwaway gateway chain (spike, P59)" || return 1
  _p20_absent GG-1.5 access-policy exists r gcloud iam access-policies describe gg-spike-access --project="$p" --location=global; rc=$?
  case $rc in
    1) echo "gg-spike-access exists; not created again";;
    0) x gcloud iam access-policies create gg-spike-access --details-rules="$w" --project="$p" --location=global \
         || { echo "STOP: create refused; record the error in the spike record and follow GG-1.5's Assumption (add the conditions block by hand)"; return 1; };;
    *) return 1;;
  esac
  _p20_absent GG-1.5 policy-binding exists r gcloud iam policy-bindings describe gg-spike-access-binding --project="$p" --location=global; rc=$?
  case $rc in
    1) echo "gg-spike-access-binding exists; not created again";;
    0) x gcloud iam policy-bindings create gg-spike-access-binding --policy="projects/${p}/locations/global/accessPolicies/gg-spike-access" \
         --target-resource="//cloudresourcemanager.googleapis.com/projects/${p}" --project="$p" --location=global || return 1;;
    *) return 1;;
  esac
  d="$(_p20_file GG-1.5 gg-spike-access-describe json)"
  if [ "$AGP_MODE" = apply ]; then
    r gcloud iam access-policies describe gg-spike-access --project="$p" --location=global --format=json | xw "$d" 644 || return 1
    r gcloud iam policy-bindings describe gg-spike-access-binding --project="$p" --location=global --format='value(target)'
  else
    _p20_plan "reads: gcloud iam access-policies describe gg-spike-access --project=$p --location=global --format=json > $d"
  fi
  _p20_revoke ENT_PROJECT_REPAIR_TENANT_APP "GG-1 chain done" || return 1
  ev GG-1.5 spike-access-policy E-05 4.1.3 "build-log:ge-gateway/$(basename "$d")" "$d"
}

# ======================================================================== GG-2 The spike questions

step GG-2.1 HUMAN "Register the pre-existing agent before binding" --witness \
  --needs "GE_THROWAWAY_APP_ID GE_INVENTORY_DIR GEMINI_PROJECT" --sets "GG_SPIKE_ENGINE" \
  --note "Agent Runtime path BLOCKED on B-04 (18 KS-1.5); the no-code path is a person's"
s_GG_2_1_check() { ckpt_done GG-2.1; }
s_GG_2_1_manual() {
  _p20_m "WHY HUMAN: the no-code agent is built in the throwaway app's web builder, questions are asked and 20 are timed" \
    "  with a stopwatch; the Agent Runtime path waits for 18's canary-r engine (README B-04)." \
    "WHO: the platform owner under ENT_GE_ADMIN (and, runtime path only, ENT_PROJECT_REPAIR_CANARY_R, approver the second human)." \
    "DO, no-code path (only when *-GI-8.5-ge10-import-list-v*.csv has no agent-runtime or a2a-endpoint line): build" \
    "  gg-spike-nocode, ask it one question, time 20 assistant questions for Q5. Record the builder path on the day." \
    "DO, runtime path (when 18 KS-1.5 is DONE): GG-2.1's block of setup/20 (penv_set GG_SPIKE_ENGINE, the serviceAgent" \
    "  grant, bd_insert BD-20-3, the agent POST), then the canary prompt and the 20 timings." \
    "Not deployed and import list holds a runtime or A2A agent: checkpoint GG-2.1 BLOCKED - - \"needs 18 canary-r engine\" and stop." \
    "Evidence: evidence_add GG-2.1 spike-agent-before-binding E-05 5.2.6 \"build-log:ge-gateway/\$(basename \"\$C\")\" \"\$C\" (\$C: the block's file)." \
    "Then: agp-platform done GG-2.1 --witness <second human's email> --note \"<runtime|nocode> path\" (the page's" \
    "  people table names the second human present for GG-2.1, as the approver of the runtime path's grant)"
}

step GG-2.2 HUMAN "Bind the throwaway app on the eu host, then GET" \
  --needs "GEMINI_PROJECT GEMINI_PROJECT_NUMBER GE_THROWAWAY_APP_ID ENT_GE_ADMIN" --sets "GE_GW_NAME_FORM GE_GW_NAME_RETURNED"
s_GG_2_2_check() { ckpt_done GG-2.2; }
s_GG_2_2_manual() {
  _p20_m "WHY HUMAN: spike Q8 is settled by a person: on a refusal the block is retried once with the project-id body," \
    "  and the accepted form is typed into GE_GW_NAME_FORM; gg_answer writes the spike record." \
    "WHO: the platform owner under ENT_GE_ADMIN. WHERE: the shell, both helper files sourced." \
    "DO: GG-2.2's first block (bind JSON, ge_call PATCH on \${GG_ENGINES}/<throwaway>?updateMask=agentGatewaySetting.default" \
    "  EgressAgentGateway.name, gg_engine_view, gg_answer Q8, spike-bind-time.txt), then its second block:" \
    "RECORD: penv_set GE_GW_NAME_FORM number|id; penv_set GE_GW_NAME_RETURNED \"<name the GET returns>\"." \
    "VERIFY: the after file's name ends with /agentGateways/gg-spike-egress; the production engine GET is unchanged" \
    "  against GG-0.4's file. Never fall back to the global host without recording it (X-GE-20)." \
    "Evidence: evidence_add GG-2.2 spike-bind E-05 5.2.7 \"build-log:ge-gateway/\$(basename \"\$AF\")\" \"\$AF\". Then: agp-platform done GG-2.2"
}

step GG-2.3 HUMAN "Read the dry-run decisions; test the pre-existing agent" \
  --needs "GEMINI_PROJECT LOGGING_PROJECT BUILD_LOG_DIR GE_SPIKE_RECORD"
s_GG_2_3_check() { ckpt_done GG-2.3; }
s_GG_2_3_manual() {
  _p20_m "WHY HUMAN: five questions, one canary prompt and 20 timed questions are asked in the throwaway app, and six" \
    "  answers (Q1 to Q6) are judged and typed; the second human reads the security view if the owner cannot." \
    "WHO: the platform owner (the second human for the security view). WHERE: the shell; the throwaway app's web URL." \
    "DO: from 15 minutes after the bind, the questions; then GG-2.3's blocks of setup/20 (gateway_requests read in" \
    "  GEMINI_PROJECT, the DRY_RUN IAP read in LOGGING_PROJECT's security view, the six gg_answer lines)." \
    "VERIFY: six answers committed; Q1 FAIL when no DRY_RUN entry within 60 minutes or a user request was refused;" \
    "  Q6 FAIL when neither the original nor a re-imported agent answers." \
    "Evidence: evidence_add GG-2.3 spike-dry-run-read E-06 5.2.4 \"build-log:ge-gateway/restricted (hashes)\" \"\$F\"." \
    "Then: agp-platform done GG-2.3"
}

step GG-2.4 CONSOLE "Prove the unbind and the rebind rule" --removes --needs "GE_THROWAWAY_APP_ID GEMINI_PROJECT_NUMBER"
s_GG_2_4_check() { ckpt_done GG-2.4; }
s_GG_2_4_manual() {
  _p20_m "WHY CONSOLE: attempt A is the console; Google documents no unbind, so what works is observed and recorded (Q7)." \
    "WHO: the platform owner under ENT_GE_ADMIN." \
    "WHERE: Cloud console > Gemini Enterprise > throwaway app > Security > Configuration > Agent Gateway configuration." \
    "DO: A: clear the gateway field, Save, then GET (GG-2.4's first block). Still bound: B, the PATCH" \
    "  updateMask=agentGatewaySetting with {}. Ask one question and the canary prompt unbound. Rebind with GG-2.2's call," \
    "  then PATCH a direct rebind to gg-spike-egress-2 and record the error text. Leave the app bound for GG-2.6." \
    "RECORD: gg_answer Q7 \"<method>; minutes to effect; direct rebind: <error text>\" PASS (FAIL if neither unbinds)." \
    "VERIFY: after the working attempt no defaultEgressAgentGateway.name; the unbound app answers; the name is back." \
    "Evidence: evidence_add GG-2.4 spike-unbind-proof E-05 5.2.6 \"build-log:ge-gateway/\$(basename \"\$U\")\" \"\$U\". Then: agp-platform done GG-2.4"
}

step GG-2.5 HUMAN "The unreachable-template test on a throwaway template pair" --removes \
  --needs "GEMINI_PROJECT GE_THROWAWAY_APP_ID GE_ARMOR_TEMPLATE ENT_PROJECT_REPAIR_TENANT_APP ENT_GE_ADMIN"
s_GG_2_5_check() { ckpt_done GG-2.5; }
s_GG_2_5_manual() {
  _p20_m "WHY HUMAN: questions are asked in the throwaway app and the block or answer, and its message, are read by a person." \
    "WHO: the platform owner under ENT_PROJECT_REPAIR_TENANT_APP (templates) and ENT_GE_ADMIN (assistant)." \
    "WHERE: the shell, both helper files sourced; the throwaway app. Never the production app or GE_ARMOR_TEMPLATE." \
    "DO: GG-2.5's block of setup/20 (two gg-spike templates through ma_eu, the throwaway assistant PATCH to FAIL_CLOSED);" \
    "  ask one question; ma_eu model-armor templates delete gg-spike-prompt --location=eu --project=\"\$GEMINI_PROJECT\";" \
    "  wait 10 minutes, ask again; PATCH a userPromptTemplate naming gg-spike-absent and record whether it is refused." \
    "RECORD: gg_answer Q9 ... RECORDED." \
    "VERIFY: the production assistant still names GE_ARMOR_TEMPLATE and FAIL_CLOSED." \
    "Evidence: evidence_add GG-2.5 unreachable-template-test E-15 5.2.6 \"build-log:ge-gateway/\$(basename \"\$AA\")\" \"\$AA\". Then: agp-platform done GG-2.5"
}

step GG-2.6 HUMAN "Test the gateway custom constraint: UPDATE name-scoped, CREATE unscoped" --witness --removes \
  --needs "ORG_ID GEMINI_PROJECT GEMINI_PROJECT_NUMBER GE_THROWAWAY_APP_ID PLATFORM_REPO_DIR ENT_PLATFORM_POLICY ENT_GE_ADMIN"
s_GG_2_6_check() { ckpt_done GG-2.6; }
s_GG_2_6_manual() {
  _p20_m "WHY HUMAN: two constraint and two policy files are heredocs of the page; the CREATE test is the console's" \
    "  Create app; the outcome is graded by a person into one of three rows; the policy grant has an approver." \
    "WHO: the platform owner under ENT_PLATFORM_POLICY (approver: the second human); ENT_GE_ADMIN for the app writes." \
    "DO: GG-2.6's blocks of setup/20 in order: the Upd constraint and policy; after 15 minutes (a) UPDATE unbind and" \
    "  (b) UPDATE rebind; then the New constraint and policy, wait 15 minutes, console Create app gg-cc-create-<YYYYMMDD>," \
    "  and at once the deletion block (policy, definition, timestamp). gg_answer Q10 ... RECORDED." \
    "VERIFY: Q10 graded into exactly one row of the page's outcome table; custom.geEngineGatewayRequiredNew is absent from" \
    "  gcloud org-policies list-custom-constraints --organization=\"\$ORG_ID\"; a created app is deleted." \
    "Evidence: evidence_add GG-2.6 gateway-constraint-test E-03 5.2.1 \"platform-repo:\$CU\"." \
    "Then: agp-platform done GG-2.6 --witness <second human's email>"
}

step GG-2.7 CONSOLE "What a share writes, and which roles the dialog offers" --removes \
  --needs "GEMINI_PROJECT LOGGING_PROJECT GRP_GE_ADMINS"
s_GG_2_7_check() { ckpt_done GG-2.7; }
s_GG_2_7_manual() {
  _p20_m "WHY CONSOLE: the share is made and removed in the console's User permissions tab; no API is documented for it." \
    "WHO: the platform owner under ENT_GE_ADMIN." \
    "WHERE: Cloud console > Gemini Enterprise > throwaway app > Agents > gg-spike-canary-r > User permissions > Add user." \
    "DO: record the Assign role names; share to Group ge-admins@ with the role mapping to agentspaceUser; 10 minutes;" \
    "  All users with the same role; 10 minutes; remove both. Then GG-2.7's read block with T0 = the first Save (UTC)." \
    "RECORD: gg_answer Q11 \"Group share: ...; All users: ...; Assign role offers: ...\" RECORDED." \
    "VERIFY: Q11 committed with exact method names or 'none in either stream'; User permissions lists only the creator." \
    "Evidence: evidence_add GG-2.7 share-audit-source E-06 5.2.4 \"build-log:ge-gateway/restricted (hashes)\" <the newest GG-2.7-activity file>." \
    "Then: agp-platform done GG-2.7"
}

step GG-2.8 HUMAN "agents.create by a holder of the user role" --removes \
  --needs "GEMINI_PROJECT GE_THROWAWAY_APP_ID ENT_GE_ADMIN ENT_PROJECT_REPAIR_TENANT_APP"
s_GG_2_8_check() { ckpt_done GG-2.8; }
s_GG_2_8_manual() {
  _p20_m "WHY HUMAN: the non-admin colleague performs the agents.create call from their own workstation." \
    "WHO: the colleague named in records/19-people.md; the platform owner under ENT_GE_ADMIN sets and removes the binding." \
    "DO: GG-2.8's block of setup/20: the merged setIamPolicy (never an appended binding; both jq -e print true); the" \
    "  colleague's create of gg-spike-user-agent 15 minutes later (serviceUsageConsumer only if refused, removed after);" \
    "  Request review if offered; gg_answer Q12 ... RECORDED; then the restore with a fresh etag and the agent DELETE." \
    "VERIFY: one binding per role in the returned policy; getIamPolicy equals iam-before except the etag; agent gone." \
    "  INVALID_ARGUMENT naming a duplicate role: re-run the jq merge, never an append." \
    "Evidence: evidence_add GG-2.8 user-agent-create-test E-05 4.1.3 \"build-log:ge-gateway/\$(basename \"\$IA\")\" \"\$IA\". Then: agp-platform done GG-2.8"
}

step GG-2.9 CONSOLE "Which read returns an agent's sharing" --removes --needs "GEMINI_PROJECT GRP_GE_ADMINS"
s_GG_2_9_check() { ckpt_done GG-2.9; }
s_GG_2_9_manual() {
  _p20_m "WHY CONSOLE: the share to ge-admins@ is made and removed in the console (GG-2.7's path); the reads are a probe." \
    "WHO: the platform owner under ENT_GE_ADMIN. WHERE: the console, then the shell, both helper files sourced." \
    "DO: share gg-spike-canary-r to ge-admins@ again; GG-2.9's block of setup/20 (agent GET with sharingConfig, the" \
    "  :getIamPolicy probe recorded as undocumented); remove the share; gg_answer Q13 ... RECORDED." \
    "VERIFY: Q13 committed; a probe returning the group means GG-7.5 and B-02 read by API, otherwise GG-7.5 is manual." \
    "Evidence: evidence_add GG-2.9 agent-sharing-read E-06 4.2.1 \"build-log:ge-gateway/\$(basename \"\$AGJ\")\" \"\$AGJ\". Then: agp-platform done GG-2.9"
}

step GG-2.10 HUMAN "Write the spike answers and carry them into 03" --needs "GE_SPIKE_RECORD WIKI_DIR"
s_GG_2_10_check() { ckpt_done GG-2.10; }
s_GG_2_10_manual() {
  _p20_m "WHY HUMAN: the answers are carried into the design page 03 as a wiki edit, with the owner's self-review." \
    "WHO: the platform owner, self-review recorded as security reviewer at Tier C (HLD 0.3). WHERE: build log; the wiki." \
    "DO: close the record with its summary table; edit 03 11.1, 11.2, 18 and 3's constraint row citing the record;" \
    "  gg_answer Q14 ... RECORDED; then the grep of GG-2.10's block." \
    "VERIFY: the grep prints at least 3; the record has a row for each of Q1 to Q14." \
    "  The page's own line is checkpoint GG-2.10 DONE - \"\$GE_SPIKE_RECORD\" (or: agp-platform done GG-2.10)." \
    "Evidence: evidence_add GG-2.10 spike-answers E-03 1.5.1 \"build-log:records/\$(basename \"\$GE_SPIKE_RECORD\")\" \"\$GE_SPIKE_RECORD\""
}

step GG-2.11 HUMAN "Decide: bind, or record the compensating control" --needs "GE_SPIKE_RECORD PLATFORM_REPO_DIR"
s_GG_2_11_check() { ckpt_done GG-2.11; }
s_GG_2_11_manual() {
  _p20_m "WHY HUMAN: a decision record, signed; the second human countersigns a no-bind outcome." \
    "WHO: the platform owner. WHERE: build log; PLATFORM_REPO_DIR/decisions/." \
    "DO: GG-2.11's block of setup/20 (cat the .results file; GO from gg_result Q1, Q6, Q7, never from grepping the word PASS)." \
    "  GO=yes: decisions/<date>-ge-binding-go.md (bind in a change window, rollback = Q7's method, the launch-stage line, and" \
    "  the signer's Pre-GA acceptance only if GG-0.4 read a Pre-GA stage). GO=no: decisions/<date>-ge-binding-compensating-" \
    "  control.md per 03 11.2; GG-3 to GG-5 are then N/A (checkpoint each N/A with the reason)." \
    "VERIFY: exactly one of the two records exists and is merged." \
    "Evidence: evidence_add GG-2.11 binding-decision E-03 1.4.1 \"platform-repo:decisions/\"." \
    "Then: agp-platform done GG-2.11 --note \"<go|compensating>\""
}

# ======================================================================== GG-3 gemini-egress in DRY_RUN

step GG-3.1 AUTO "Import gemini-egress" \
  --needs "GEMINI_PROJECT GEMINI_PROJECT_NUMBER GE_GW_NAME_FORM PLATFORM_REPO_DIR ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT EVIDENCE_REGISTER" \
  --sets "GE_REGISTRY GE_EGRESS_GATEWAY"
_p20_egress_gw_ok() {   # the page's VERIFY as a filtered list: gemini-egress exists with AGENT_TO_ANYWHERE
  nonempty r gcloud network-services agent-gateways list --location=europe-west1 --project="$(v GEMINI_PROJECT)" \
    --filter='name:gemini-egress AND googleManaged.governedAccessPath=AGENT_TO_ANYWHERE' --format='value(name)'
}
s_GG_3_1_check() {
  local rc
  _p20_na && return 5
  _p20_egress_gw_ok; rc=$?
  [ $rc -eq 0 ] || return $rc
  has_value GE_REGISTRY && has_value GE_EGRESS_GATEWAY
}
s_GG_3_1_apply() {
  local p d y gw reg body
  p="$(v GEMINI_PROJECT)"; reg="//agentregistry.googleapis.com/projects/${p}/locations/europe-west1"
  d="$(v PLATFORM_REPO_DIR)/factory/runs/gemini-prod"; y="$d/gemini-egress.yaml"
  _p20_go_guard || return 1
  # the page writes GE_EGRESS_GATEWAY in the form GG-2.2 proved (Q8); it is read before anything is imported
  case "$(v GE_GW_NAME_FORM)" in
    number) gw="projects/$(v GEMINI_PROJECT_NUMBER)/locations/europe-west1/agentGateways/gemini-egress";;
    id)     gw="projects/${p}/locations/europe-west1/agentGateways/gemini-egress";;
    *) if [ "$AGP_MODE" = apply ]; then echo "STOP: GE_GW_NAME_FORM is not number or id; GG-2.2 did not settle Q8. Nothing was imported"; return 1; fi
       gw="projects/<number or id, as GE_GW_NAME_FORM says>/locations/europe-west1/agentGateways/gemini-egress";;
  esac
  body="$(_p20_render gg-3.1-gemini-egress.yaml)" || return 1
  _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 3600 "setup 20 GG-3 gemini-egress chain in DRY_RUN" || return 1
  if [ "$AGP_MODE" != apply ] || [ ! -d "$d" ]; then x mkdir -p "$d" || return 1; fi
  printf '%s\n' "$body" | xw "$y" 644 || return 1
  # the check read no gemini-egress with AGENT_TO_ANYWHERE (or a value unset); import creates it, or updates it to the file
  x gcloud network-services agent-gateways import gemini-egress --source="$y" --location=europe-west1 --project="$p" || return 1
  pset GE_REGISTRY "$reg" || return 1
  pset GE_EGRESS_GATEWAY "$gw" || return 1
  if [ "$AGP_MODE" = apply ]; then
    r gcloud network-services agent-gateways describe gemini-egress --location=europe-west1 --project="$p" --format='value(googleManaged.governedAccessPath,registries)'
    _p20_egress_gw_ok || { echo "STOP: gemini-egress is not listed with governedAccessPath AGENT_TO_ANYWHERE"; return 1; }
    echo "REVIEW: the line above prints AGENT_TO_ANYWHERE and $reg. The grant stays open for GG-3.2 to GG-3.4;"
    echo "  the commit of factory/runs/gemini-prod is GG-3.4's, as the page writes it."
  fi
  ev GG-3.1 gemini-egress E-05 5.2.7 "platform-repo:factory/runs/gemini-prod/gemini-egress.yaml" "$y"
}

step GG-3.2 AUTO "The IAP extension in DRY_RUN" \
  --needs "GEMINI_PROJECT PLATFORM_REPO_DIR ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER" \
  --sets "GE_AUTHZ_EXTENSION"
s_GG_3_2_check() {   # the page's VERIFY as a filtered list: the extension exists in DRY_RUN; the value is recorded
  local rc
  _p20_na && return 5
  nonempty r gcloud service-extensions authz-extensions list --location=europe-west1 --project="$(v GEMINI_PROJECT)" \
    --filter='name:gemini-egress-iap-authz AND metadata.iamEnforcementMode=DRY_RUN' --format='value(name)'; rc=$?
  [ $rc -eq 0 ] || return $rc
  has_value GE_AUTHZ_EXTENSION
}
s_GG_3_2_apply() {
  local p y d
  p="$(v GEMINI_PROJECT)"
  d="$(v PLATFORM_REPO_DIR)/factory/runs/gemini-prod"; y="$d/gemini-egress-iap-authz.yaml"
  _p20_go_guard || return 1
  if [ "$AGP_MODE" != apply ] || [ ! -d "$d" ]; then x mkdir -p "$d" || return 1; fi
  printf 'name: gemini-egress-iap-authz\nservice: iap.googleapis.com\nfailOpen: false\ntimeout: 1s\nmetadata:\n  iapPolicyVersion: "V2"\n  iamEnforcementMode: "DRY_RUN"\n' | xw "$y" 644 || return 1
  _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 3600 "setup 20 GG-3 gemini-egress chain in DRY_RUN" || return 1
  # the check read no DRY_RUN extension (or the value unset); import creates it, or puts an existing one back to the file
  _p20_plan "(the GA group first; the beta group only if the GA import is refused, as the page writes it)"
  x gcloud service-extensions authz-extensions import gemini-egress-iap-authz --source="$y" --location=europe-west1 --project="$p" \
    || x gcloud beta service-extensions authz-extensions import gemini-egress-iap-authz --source="$y" --location=europe-west1 --project="$p" \
    || return 1
  if [ "$AGP_MODE" = apply ]; then
    r gcloud service-extensions authz-extensions describe gemini-egress-iap-authz --location=europe-west1 --project="$p" --format='value(metadata.iamEnforcementMode,failOpen)'
  fi
  pset GE_AUTHZ_EXTENSION "projects/${p}/locations/europe-west1/authzExtensions/gemini-egress-iap-authz" || return 1
  ev GG-3.2 gemini-egress-extension E-05 5.2.7 "platform-repo:factory/runs/gemini-prod/gemini-egress-iap-authz.yaml"
}

step GG-3.3 AUTO "The authorisation policy" \
  --needs "GEMINI_PROJECT PLATFORM_REPO_DIR ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT EVIDENCE_REGISTER"
s_GG_3_3_check() {
  _p20_na && return 5
  _p20_authz_policy_ok gemini-egress-authz-policy
}
s_GG_3_3_apply() {
  local p d y body
  p="$(v GEMINI_PROJECT)"
  d="$(v PLATFORM_REPO_DIR)/factory/runs/gemini-prod"; y="$d/gemini-egress-authz-policy.yaml"
  _p20_go_guard || return 1
  body="$(_p20_render gg-3.3-gemini-egress-authz-policy.yaml)" || return 1
  _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 3600 "setup 20 GG-3 gemini-egress chain in DRY_RUN" || return 1
  if [ "$AGP_MODE" != apply ] || [ ! -d "$d" ]; then x mkdir -p "$d" || return 1; fi
  printf '%s\n' "$body" | xw "$y" 644 || return 1
  # the check read no CUSTOM policy of that name; import creates it, or updates it to the file
  x gcloud network-security authz-policies import gemini-egress-authz-policy --source="$y" --location=europe-west1 --project="$p" || return 1
  if [ "$AGP_MODE" = apply ]; then
    r gcloud network-security authz-policies describe gemini-egress-authz-policy --location=europe-west1 --project="$p" --format='value(action,target.resources)'
    _p20_authz_policy_ok gemini-egress-authz-policy || { echo "STOP: gemini-egress-authz-policy is not listed with action CUSTOM"; return 1; }
    echo "REVIEW: the line above prints CUSTOM and agentGateways/gemini-egress. The commit of factory/runs/gemini-prod"
    echo "  is GG-3.4's, as the page writes it."
  fi
  ev GG-3.3 gemini-egress-authz-policy E-05 5.2.7 "platform-repo:factory/runs/gemini-prod/gemini-egress-authz-policy.yaml" "$y"
}

step GG-3.4 HUMAN "The access policy from the import list" \
  --needs "GEMINI_PROJECT PLATFORM_REPO_DIR CICD_PROJECT ENT_PROJECT_REPAIR_TENANT_APP" --sets "GE_ACCESS_POLICY"
s_GG_3_4_check() { _p20_na && return 5; ckpt_done GG-3.4; }
s_GG_3_4_manual() {
  _p20_m "WHY HUMAN: the rule names the principal string the person read from spike Q2 (PRINC in the block); the block" \
    "  has no heredoc, and no recorded value holds that string." \
    "WHO: the platform owner under the grant GG-3.1 requested. WHERE: the shell, in PLATFORM_REPO_DIR." \
    "DO: GG-3.4's block of setup/20 with PRINC typed from Q2 (rules JSON, gcloud iam access-policies create gemini-egress-access" \
    "  --details-rules --project --location=global, policy-bindings create gemini-egress-access-binding, commit" \
    "  factory/runs/gemini-prod, penv_set GE_ACCESS_POLICY, revoke the GG-3 grant)." \
    "VERIFY: access-policies describe gemini-egress-access ... | jq -r '.details.rules[0].principals[0]' equals PRINC; the" \
    "  binding describes with the project target." \
    "Evidence: evidence_add GG-3.4 gemini-egress-access-policy E-05 4.1.3 \"platform-repo:\$Y\". Then: agp-platform done GG-3.4"
}

# ======================================================================== GG-4 Inventory and registration of every destination

step GG-4.1 CONSOLE "Re-read the live app's agents, endpoints and MCP servers on the day" \
  --needs "GE_INVENTORY_DIR GEMINI_PROJECT GEMINI_APP_ID BUILD_LOG_DIR"
s_GG_4_1_check() { _p20_na && return 5; ckpt_done GG-4.1; }
s_GG_4_1_manual() {
  _p20_m "WHY CONSOLE: the console's Agents list is the authoritative count (agents.list returns the caller's agents only)." \
    "WHO: the platform owner, solo. WHERE: console > Gemini Enterprise > production app > Agents; the shell." \
    "DO: repeat 05 GI-8.1 to GI-8.3; GG-4.1's block of setup/20 (copy of GI-8.5's list, agent-registry agents, endpoints," \
    "  mcp-servers and services lists in europe-west1, the agents-api TSV); then write <date>-GG-4.1-import-list-today-v1.csv" \
    "  in GI-8.5's columns, each new agent marked new." \
    "VERIFY: today's list has at least the console's agent count; each new line has a register row or a named owner" \
    "  (a shadow agent is a severity 2 finding to platform-security@)." \
    "Evidence: evidence_add GG-4.1 import-list-today E-11 1.3.1 \"build-log:ge-gateway/\$(basename \"\$T\")\" \"\$T\" (T: today's list). Then: agp-platform done GG-4.1"
}

step GG-4.2 HUMAN "Register each destination in GE_REGISTRY" \
  --needs "GEMINI_PROJECT ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT DEVIATION_REGISTER"
s_GG_4_2_check() { _p20_na && return 5; ckpt_done GG-4.2; }
s_GG_4_2_manual() {
  _p20_m "WHY HUMAN: one command per line of today's list, with names, URLs and specs the person types from restricted/." \
    "WHO: the platform owner under ENT_PROJECT_REPAIR_TENANT_APP (bootstrap deviation: CI's writes, 17 FM-6.5 BLOCKED)." \
    "DO: gcloud agent-registry services create --help first (the spec flags take the JSON itself; \$(cat ...) works either" \
    "  way); then GG-4.2's commands per kind, all --location=europe-west1 --project=\"\$GEMINI_PROJECT\"; specs over 10 KB" \
    "  are registered no-spec and flagged spec-too-large; connectors are not registry entries. Add the registry_service" \
    "  column to today's list; one deviation-register row for the batch. Keep the grant for GG-4.3." \
    "VERIFY: services list count equals the non-connector lines; the spec loop of GG-4.2 prints no BAD line." \
    "Evidence: evidence_add GG-4.2 registry-entries E-11 1.3.1 \"build-log:ge-gateway/\$(basename \"\$T\")\" \"\$T\" (T: the completed list). Then: agp-platform done GG-4.2"
}

step GG-4.3 HUMAN "Check the list against the registry" --needs "GEMINI_PROJECT CICD_PROJECT BUILD_LOG_DIR"
s_GG_4_3_check() { _p20_na && return 5; ckpt_done GG-4.3; }
s_GG_4_3_manual() {
  _p20_m "WHY HUMAN: the comparison's input is the list the person wrote in GG-4.1 and GG-4.2, and the block ends the grant" \
    "  the person opened in GG-4.2." \
    "WHO: the platform owner, solo. WHERE: the shell, both helper files sourced." \
    "DO: GG-4.3's block of setup/20 (want.txt from today's list, have.txt from gcloud agent-registry services list" \
    "  --project=\"\$GEMINI_PROJECT\" --location=europe-west1, comm -3, revoke the GG-4 grant)." \
    "VERIFY: comm prints nothing (\$CM empty); GG-4.2's spec loop printed no BAD line. A have-only line is a spike leftover." \
    "Evidence: evidence_add GG-4.3 registry-complete E-11 1.3.1 \"build-log:ge-gateway/\$(basename \"\$CM\")\" \"\$CM\"." \
    "Then: agp-platform done GG-4.3 (the page's own line is checkpoint GG-4.3 DONE)"
}

step GG-4.4 HUMAN "Announce the change window" --needs "SA_1_ADMIN EVIDENCE_REGISTER EVIDENCE_INTERIM_LOCATION" --sets "GG_ROLLBACK_OPERATOR"
s_GG_4_4_check() { _p20_na && return 5; ckpt_done GG-4.4; }
s_GG_4_4_manual() {
  _p20_m "WHY HUMAN: a user notice five business days ahead, sent by the communications contact, and the desk's acknowledgement." \
    "WHO: the platform owner writes; the Gemini Enterprise administrators' communications contact sends." \
    "WHERE: the organisation's user communication channel; the paging tool's announced-change note." \
    "DO: the notice (date and hour outside peak, possible brief unavailability, helpdesk route, chats unchanged); to the" \
    "  desk: the window, the expected UpdateEngine alert, the rollback owner. Name the user-test colleague, a second tester" \
    "  and the rollback operator (a second ge-admins@ member, not the platform owner)." \
    "RECORD: penv_set GG_ROLLBACK_OPERATOR \"<that member's address>\"" \
    "VERIFY: notice and acknowledgement saved; the value is neither SA_1_ADMIN nor a placeholder (the page's case line)." \
    "Evidence: evidence_add GG-4.4 change-window-notice E-12 5.2.1 \"\$EVIDENCE_INTERIM_LOCATION\"." \
    "Then: agp-platform done GG-4.4 --note \"window <date time>\""
}

step GG-4.5 AUTO "Record the share containment check for 35" \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR GRP_GE_ADMINS SA_1_ADMIN EVIDENCE_REGISTER"
s_GG_4_5_check() {  # the page's script, executable, committed with no change since
  local r t
  _p20_na && return 5
  r="$(v PLATFORM_REPO_DIR)"; t="$r/tools/ge-share-precheck.sh"
  [ -x "$t" ] && cmp -s "$AGP_HOME/assets/gg-4.5-ge-share-precheck.sh" "$t" || return 1
  git -C "$r" ls-files --error-unmatch tools/ge-share-precheck.sh >/dev/null 2>&1 || return 1
  git -C "$r" diff --exit-code HEAD -- tools/ge-share-precheck.sh >/dev/null 2>&1 || return 1
}
s_GG_4_5_apply() {
  local r t out
  r="$(v PLATFORM_REPO_DIR)"; t="$r/tools/ge-share-precheck.sh"
  _p20_asset gg-4.5-ge-share-precheck.sh || return 1
  if [ "$AGP_MODE" != apply ] || [ ! -d "$r/tools" ]; then x mkdir -p "$r/tools" || return 1; fi
  xw "$t" 755 < "$AGP_HOME/assets/gg-4.5-ge-share-precheck.sh" || return 1   # the page's cat and chmod +x
  x git -C "$r" add tools/ge-share-precheck.sh || return 1
  if [ "$AGP_MODE" != apply ] || ! git -C "$r" diff --cached --exit-code -- tools/ge-share-precheck.sh >/dev/null 2>&1; then
    x git -C "$r" commit -m "GG-4.5 share precheck (X-GE-22)" -- tools/ge-share-precheck.sh || return 1
  fi
  if [ "$AGP_MODE" = apply ]; then   # the page's VERIFY: the script runs and prints one line per member
    if [ -f "$(v BUILD_LOG_DIR)/ge-baseline/ge-helpers.sh" ]; then
      out="$(r "$t" "$(v GRP_GE_ADMINS)" "$(v SA_1_ADMIN)" 2>&1)"
      printf '%s\n' "$out" | sed 's/^/  /'
      case "$out" in *"$(v SA_1_ADMIN) "*) ;;
        *) echo "STOP: tools/ge-share-precheck.sh printed no line for $(v SA_1_ADMIN); read its output above"; return 1;; esac
    else
      echo "NOTE: the VERIFY run needs 19's ge-baseline/ge-helpers.sh, which is absent; once 19 is done, run by hand:"
      echo "  \"\$PLATFORM_REPO_DIR/tools/ge-share-precheck.sh\" \"\$GRP_GE_ADMINS\" \"\$SA_1_ADMIN\"  (one line per member)"
    fi
  fi
  _p20_plan "then: the push and the review on the git host are the platform owner's (the page's 'merged'; phases/03 header)"
  [ "$AGP_MODE" != apply ] || echo "REVIEW: committed locally; the push and the review on the git host are yours (the page's 'merged')."
  ev GG-4.5 share-precheck E-15 4.1.3 "platform-repo:tools/ge-share-precheck.sh" "$t"
}

# ======================================================================== GG-5 The binding (GE-10), in the change window

step GG-5.1 HUMAN "Gate check at the window's start" \
  --needs "PLATFORM_REPO_DIR GE_SPIKE_RECORD BUILD_LOG_DIR GEMINI_PROJECT GEMINI_APP_ID GE_ARMOR_TEMPLATE"
s_GG_5_1_check() { _p20_na && return 5; ckpt_done GG-5.1; }
s_GG_5_1_manual() {
  _p20_m "WHY HUMAN: the gate reads the signed go record and the spike's RESULT lines the person wrote, at the window's" \
    "  start, with the colleague and the second tester present; a miss cancels the window (GG-4.4's rollback)." \
    "WHO: the platform owner; the colleague and the second tester present or reachable. WHERE: the shell, helpers sourced." \
    "DO: GG-5.1's block of setup/20 (the go record, gg_result Q1 Q6 Q7, the count of GG-3.1..3.4 and GG-4.1..4.5 DONE," \
    "  the production engine and assistant reads)." \
    "VERIFY: the go record exists; no STOP from the three gg_result checks; 9 DONE steps; production agentGatewaySetting" \
    "  null; the production assistant names GE_ARMOR_TEMPLATE's pair and FAIL_CLOSED, never a gg-spike template." \
    "Evidence: evidence_add GG-5.1 window-gate E-05 5.2.1 \"build-log:ge-gateway/\$(basename \"\$WS\")\" \"\$WS\". Then: agp-platform done GG-5.1"
}

step GG-5.2 HUMAN "User test before the change" --needs "BUILD_LOG_DIR"
s_GG_5_2_check() { _p20_na && return 5; ckpt_done GG-5.2; }
s_GG_5_2_manual() {
  _p20_m "WHY HUMAN: the non-admin colleague's user test in the production app." \
    "WHO: the colleague; the platform owner records. WHERE: the colleague's browser, the production app." \
    "DO: three assistant questions (one web-grounded), one question to each shared agent on today's list the colleague" \
    "  can see, one file upload if uploads are on (19 GE-6); time and outcome of each in records/20-user-tests.md." \
    "VERIFY: every item answered; otherwise stop, open a case and reschedule (a failure before the change is not its cause)." \
    "Evidence: evidence_add GG-5.2 user-test-before E-15 5.2.6 \"build-log:records/20-user-tests.md\" \"\$BUILD_LOG_DIR/records/20-user-tests.md\"." \
    "Then: agp-platform done GG-5.2"
}

step GG-5.2b HUMAN "Open the window: announce the cutover and confirm the room" --witness \
  --needs "GG_ROLLBACK_OPERATOR SECOND_HUMAN_EMAIL BUILD_LOG_DIR ENT_GE_ADMIN CICD_PROJECT" --sets "GG_WINDOW_RECORD"
s_GG_5_2b_check() { _p20_na && return 5; ckpt_done GG-5.2b; }
s_GG_5_2b_manual() {
  _p20_m "WHY HUMAN: four people answer, each with a time: the cutover note, the desk's reply, the rollback operator's" \
    "  stated Q7 method and active grant, the second human at the screen." \
    "WHO: the platform owner; the communications contact; the IT security desk; the second human; GG_ROLLBACK_OPERATOR." \
    "WHERE: the user channel; the paging tool's announced-change note; the call or room of GG-5.3." \
    "DO: GG-5.2b's block of setup/20 (the window record, penv_set GG_WINDOW_RECORD), then replace every *tbd* with the" \
    "  time and reference as each answer arrives, and commit. A silent desk is a stop: reschedule." \
    "VERIFY: grep -c tbd \"\$GG_WINDOW_RECORD\" prints 0; gcloud pam grants list --billing-project=\"\$CICD_PROJECT\"" \
    "  --entitlement=\"\$ENT_GE_ADMIN\" --filter='state=ACTIVE' --format='value(name,requester)' shows the operator's grant." \
    "Evidence: evidence_add GG-5.2b window-open E-12 5.2.1 \"build-log:records/\$(basename \"\$GG_WINDOW_RECORD\")\" \"\$W\"." \
    "Then: agp-platform done GG-5.2b --witness <second human's email>"
}

step GG-5.3 HUMAN "Bind the production app" --witness \
  --needs "GE_EGRESS_GATEWAY GE_GW_NAME_FORM GG_WINDOW_RECORD GE_SPIKE_RECORD GEMINI_PROJECT GEMINI_PROJECT_NUMBER GEMINI_APP_ID ENT_GE_ADMIN SECOND_HUMAN_EMAIL PLATFORM_REPO_DIR" \
  --note "HIGH CONSEQUENCE: routes all agent traffic at once; no documented undo before Q7; witness at the screen"
s_GG_5_3_check() { _p20_na && return 5; ckpt_done GG-5.3; }
s_GG_5_3_manual() {
  _p20_m "WHY HUMAN: the production binding, with the second human at the screen reading the body and engine aloud and the" \
    "  rollback operator on the call; the page treats it as an irreversible step would be." \
    "WHO: the platform owner under ENT_GE_ADMIN; witness: the second human; on the call: GG_ROLLBACK_OPERATOR." \
    "DO: GG-5.3's PRECONDITION block (no STOP, the go record listed, 0 tbd), then its ACTION block (grant, bind JSON, cat" \
    "  read aloud, prod-bind-time.txt, the PATCH on https://eu-discoveryengine.googleapis.com with updateMask and" \
    "  X-Goog-User-Project). Refused: the single retry block with the other name form (BD-20-4); a second refusal ends the" \
    "  window. Never the global host." \
    "VERIFY: the page's GET | jq -e prints true and one question in the production app is answered; else roll back now" \
    "  by Q7's method. The witness countersigns the VERIFY output in GG_WINDOW_RECORD." \
    "Evidence: evidence_add GG-5.3 prod-bind E-05 5.2.7 \"build-log:ge-gateway/\$(basename \"\$BR\")\" \"\$BR\" (the accepted call)." \
    "Then: agp-platform done GG-5.3 --witness <second human's email>"
}

step GG-5.4 HUMAN "GET and assert" --needs "GE_EGRESS_GATEWAY GEMINI_PROJECT GEMINI_PROJECT_NUMBER GEMINI_APP_ID BUILD_LOG_DIR"
s_GG_5_4_check() { _p20_na && return 5; ckpt_done GG-5.4; }
s_GG_5_4_manual() {
  _p20_m "WHY HUMAN: run inside the open window by the operator who holds the bind grant; the diff is against GG-5.1's" \
    "  window-start file that the person's shell wrote, and a failure is an immediate rollback decision." \
    "WHO: the platform owner. WHERE: the shell, helpers sourced." \
    "DO: GG-5.4's block of setup/20 (the GET on the eu host saved as prod-engine-bound, jq -e against GE_EGRESS_GATEWAY," \
    "  the diff against prod-engine-window-start without agentGatewaySetting and associatedAgentRegistry)." \
    "VERIFY: jq -e prints true; associatedAgentRegistry names GEMINI_PROJECT's europe-west1 registry; diff prints nothing." \
    "  Any miss: GG-5.3's ROLLBACK." \
    "Evidence: evidence_add GG-5.4 prod-engine-bound E-05 5.2.7 \"build-log:ge-gateway/\$(basename \"\$PB\")\" \"\$PB\". Then: agp-platform done GG-5.4"
}

step GG-5.5 HUMAN "Import the agents into the app and run the user test" --needs "BUILD_LOG_DIR"
s_GG_5_5_check() { _p20_na && return 5; ckpt_done GG-5.5; }
s_GG_5_5_manual() {
  _p20_m "WHY HUMAN: console imports per spike Q6 and the colleague's user test after the bind." \
    "WHO: the platform owner under ENT_GE_ADMIN; the colleague and the second tester." \
    "WHERE: console > Gemini Enterprise > production app > Agents > + Add agent > Custom agent via Agent Runtime." \
    "DO: import each line Q6 says needs it (none if 'keeps working'); 15 minutes after the bind the colleague repeats" \
    "  GG-5.2 item for item. An item that passed before and fails now: roll back (GG-5.3), re-test, record, end the window." \
    "VERIFY: every item that passed before passes after (after-rows in records/20-user-tests.md)." \
    "Evidence: evidence_add GG-5.5 user-test-after-bind E-15 5.2.6 \"build-log:records/20-user-tests.md\" \"\$BUILD_LOG_DIR/records/20-user-tests.md\"." \
    "Then: agp-platform done GG-5.5 --note \"<colleague>\""
}

step GG-5.6 HUMAN "First dry-run read and window close" --needs "GEMINI_PROJECT LOGGING_PROJECT CICD_PROJECT BUILD_LOG_DIR"
s_GG_5_6_check() { _p20_na && return 5; ckpt_done GG-5.6; }
s_GG_5_6_manual() {
  _p20_m "WHY HUMAN: the dry-run summary (destinations, principal, would-deny counts) is written by a person from restricted" \
    "  reads, the second human may read the security view, and 'window closed' is sent to users and the desk." \
    "WHO: the platform owner; the second human for the security view if needed. WHERE: the shell, helpers sourced." \
    "DO: GG-2.3's two reads with T0 from prod-bind-time.txt, saved under restricted/; the summary <date>-GG-5.6-dry-run-" \
    "  day0-v1.md (no personal data); GG-5.6's revoke of the window grant; the 'window closed' notes." \
    "VERIFY: DRY_RUN entries present with the Q2 principal; no user-reported denial." \
    "Evidence: evidence_add GG-5.6 dry-run-day0 E-06 5.2.4 \"build-log:ge-gateway/<summary file>\" \"\$GG_DIR/<summary file>\". Then: agp-platform done GG-5.6"
}

step GG-5.7 HUMAN "custom.geEngineGatewayRequired on the production condition, dry run" --witness --removes \
  --needs "ORG_ID GEMINI_PROJECT FLD_GEMINI_ENTERPRISE GE_EGRESS_GATEWAY GE_SPIKE_RECORD PLATFORM_REPO_DIR ENT_PLATFORM_POLICY CICD_PROJECT"
s_GG_5_7_check() { _p20_na && return 5; ckpt_done GG-5.7; }
s_GG_5_7_manual() {
  _p20_m "WHY HUMAN: the constraint file is a heredoc of the page; methodTypes follow Q10's graded row; the grant has an approver." \
    "  N/A only when Q10 was FAIL (the definition itself refused): checkpoint GG-5.7 N/A - - \"Q10 FAIL\"." \
    "WHO: the platform owner under ENT_PLATFORM_POLICY; approver: the second human. WHERE: the shell, in PLATFORM_REPO_DIR." \
    "DO: GG-5.7's block of setup/20 (custom.geEngineGatewayRequired with GE_EGRESS_GATEWAY as GET returned it, the folder" \
    "  dryRunSpec file, commit, grant, delete the Upd spike policy and definition, set-custom-constraint, set-policy" \
    "  --update-mask=policy.dry_run_spec, revoke)." \
    "VERIFY: describe --folder=\"\$FLD_GEMINI_ENTERPRISE\" shows dryRunSpec and no spec; list-custom-constraints shows only" \
    "  custom.geEngineGatewayRequired; no project-level spike policy; methodTypes match Q10's row." \
    "Evidence: evidence_add GG-5.7 gateway-constraint-dry-run E-03 5.2.1 \"platform-repo:\$P\"." \
    "Then: agp-platform done GG-5.7 --witness <second human's email>"
}

step GG-5.8 HUMAN "Dry-run reviews at day 7 and day 30" --on-unmet skip --needs "DRILL_CALENDAR BUILD_LOG_DIR"
s_GG_5_8_check() { _p20_na && return 5; ckpt_done GG-5.8; }
s_GG_5_8_manual() {
  _p20_m "WHY HUMAN: the reviews are a person's reading of seven and thirty days of dry-run log against the register." \
    "  The run goes on to GG-6 and GG-7 meanwhile; GG-8 waits for the day-7 record." \
    "WHO: the platform owner. WHERE: the shell; DRILL_CALENDAR." \
    "DO: GG-5.8's block of setup/20 now (row DR-20-1 in DRILL_CALENDAR with prod-bind-time.txt, commit); at day 7 and" \
    "  day 30, GG-5.6's reads over the period and a table of every destination against today's list and the register." \
    "VERIFY: <date>-GG-5.8-dry-run-day7-v1.md with zero unexplained destinations (day 30 is 39's, not this file's close)." \
    "Evidence: evidence_add GG-5.8 dry-run-day7 E-06 5.2.7 \"build-log:ge-gateway/<day-7 record>\" \"\$GG_DIR/<day-7 record>\"." \
    "Then, after the day-7 record: agp-platform done GG-5.8"
}

# ======================================================================== GG-6 Spike teardown

step GG-6.1 HUMAN "Remove the throwaway gateway chain and the spike policy" --removes \
  --needs "GEMINI_PROJECT ORG_ID FLD_GEMINI_ENTERPRISE BUILD_LOG_DIR"
s_GG_6_1_check() { ckpt_done GG-6.1; }
s_GG_6_1_manual() {
  _p20_m "WHY HUMAN: the throwaway app is unbound first by the method spike Q7 proved, which may be the console." \
    "WHO: the platform owner under ENT_PROJECT_REPAIR_TENANT_APP and ENT_GE_ADMIN. WHERE: the console or shell; the shell." \
    "DO: unbind the throwaway app by Q7's method; then GG-6.1's block of setup/20 in order (spike policy binding, access" \
    "  policy, authz policy, extension, gg-spike-egress and gg-spike-egress-2). Nothing about the custom constraint here." \
    "VERIFY: \$TD (the block's two lists) holds gemini-egress and gemini-egress-access-binding only; the page's" \
    "  survival loop prints no STOP." \
    "Evidence: evidence_add GG-6.1 spike-chain-removed E-05 5.2.7 \"build-log:ge-gateway/\$(basename \"\$TD\")\" \"\$TD\". Then: agp-platform done GG-6.1"
}

step GG-6.1b HUMAN "Delete the gateway custom constraint — only when Q10 was FAIL" --witness --removes --irreversible \
  --needs "ORG_ID GEMINI_PROJECT FLD_GEMINI_ENTERPRISE ENT_PLATFORM_POLICY CICD_PROJECT BUILD_LOG_DIR"
s_GG_6_1b_check() { ckpt_done GG-6.1b; }
s_GG_6_1b_manual() {
  _p20_m "WHY HUMAN: irreversible in the small, conditional on Q10 FAIL and GG-5.7 N/A, and confirmed aloud by the approver." \
    "WHO: the platform owner under ENT_PLATFORM_POLICY; approver: the second human, who confirms GG-5.7 is recorded N/A." \
    "DO: GG-6.1b's block of setup/20. It deletes custom.geEngineGatewayRequiredUpd (project policy and definition) only" \
    "  when checkpoints.tsv reads GG-5.7 N/A; otherwise it prints N/A and the constraint stays." \
    "Q10 PASS or PASS-UPDATE: checkpoint GG-6.1b N/A - - 'Q10 PASS or PASS-UPDATE' (never delete the control 39 needs)." \
    "VERIFY: ran: list-custom-constraints --organization=\"\$ORG_ID\" | grep geEngineGatewayRequired prints nothing and 39's" \
    "  entry in 7 is amended; did not run: it prints custom.geEngineGatewayRequired only." \
    "Evidence: evidence_add GG-6.1b spike-constraint-decision E-03 5.2.1 \"platform-repo:policies/custom-constraints/\"." \
    "Then (ran): agp-platform done GG-6.1b --witness <second human's email>"
}

step GG-6.2 HUMAN "Remove the spike grant, templates and agent" --witness --removes \
  --needs "GEMINI_PROJECT GEMINI_PROJECT_NUMBER CANARY_R_PROJECT GE_SPIKE_RECORD DEVIATION_REGISTER BUILD_LOG_DIR"
s_GG_6_2_check() { ckpt_done GG-6.2; }
s_GG_6_2_manual() {
  _p20_m "WHY HUMAN: the canary-r binding exists on the Agent Runtime path only, under a grant the second human approves," \
    "  and the agent and template are deleted through 19's ge_call and ma_eu helpers." \
    "WHO: the platform owner under ENT_PROJECT_REPAIR_CANARY_R (approver the second human), the tenant-app repair grant" \
    "  and ENT_GE_ADMIN. WHERE: the shell, both helper files sourced." \
    "DO: GG-6.2's block of setup/20 (the remove-iam-policy-binding on CANARY_R_PROJECT, runtime path only; the" \
    "  gg-spike-response template; the spike agent DELETE; bd_close BD-20-3 when BD-20-3 was opened)." \
    "VERIFY: \$CR (the block's get-iam-policy read of CANARY_R_PROJECT, --flatten='bindings[].members' quoted for zsh," \
    "  filtered on gcp-sa-discoveryengine) is empty; no gg-spike template is listed." \
    "Evidence: evidence_add GG-6.2 spike-grant-removed E-05 4.1.3 \"build-log:ge-gateway/\$(basename \"\$CR\")\" \"\$CR\"." \
    "Then: agp-platform done GG-6.2 --witness <second human's email>"
}

step GG-6.3 HUMAN "Delete the throwaway app (after GG-7.3)" --removes --irreversible \
  --needs "GEMINI_PROJECT_NUMBER GE_THROWAWAY_APP_ID GEMINI_APP_ID BUILD_LOG_DIR" --on-unmet skip
s_GG_6_3_check() { ckpt_done GG-6.3; }
s_GG_6_3_manual() {
  _p20_m "WHY HUMAN: it runs only after GG-7.3 has fired every alert on the throwaway app's fixtures, and it has no undo." \
    "  The run goes on to GG-7 meanwhile; come back here once GG-7.3 is DONE." \
    "WHO: the platform owner under ENT_GE_ADMIN. WHERE: the shell, both helper files sourced." \
    "DO: when GG-7.3 is DONE, GG-6.3's block of setup/20 (ge_call DELETE \${GG_ENGINES}/\${GE_THROWAWAY_APP_ID}, then the" \
    "  engines list saved as engines-after)." \
    "VERIFY: after the operation completes, the list contains GEMINI_APP_ID only." \
    "Evidence: evidence_add GG-6.3 throwaway-app-deleted E-05 5.2.2 \"build-log:ge-gateway/\$(basename \"\$EA\")\" \"\$EA\"." \
    "Then: agp-platform done GG-6.3"
}

# ======================================================================== GG-7 Tier C detections (GE-13)

step GG-7.1 HUMAN "Notification channels in GEMINI_PROJECT" --witness \
  --needs "GEMINI_PROJECT CORE_PROJECT GRP_PLATFORM_SECURITY NOTIF_CH_PAGER_CORE ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT" \
  --sets "NOTIF_CH_EMAIL_GEMINI NOTIF_CH_PAGER_GEMINI"
s_GG_7_1_check() { ckpt_done GG-7.1; }
s_GG_7_1_manual() {
  _p20_m "WHY HUMAN: a key-bearing paging channel is created by the IT security paging administrator (no key passes" \
    "  through this script); a console test notification is confirmed received by the second human." \
    "WHO: the platform owner under ENT_PROJECT_REPAIR_TENANT_APP; the paging administrator; the second human confirms." \
    "WHERE: the shell; for a key-bearing channel, Monitoring > Alerting > Edit notification channels in GEMINI_PROJECT." \
    "DO: GG-7.1's first block of setup/20 (grant kept for GG-7.2, the email channel, the type of NOTIF_CH_PAGER_CORE," \
    "  the list), then RECORD the two full resource names, never a placeholder: penv_set NOTIF_CH_EMAIL_GEMINI ...;" \
    "  penv_set NOTIF_CH_PAGER_GEMINI ... . No paging channel yet: checkpoint GG-7.1 BLOCKED - - \"paging channel ...\"." \
    "VERIFY: the page's guard loop prints no STOP; a console test notification reaches platform-security@ and the pager." \
    "Evidence: evidence_add GG-7.1 gemini-channels E-08 1.6.1 \"build-log:ge-gateway/\$(basename \"\$CL\")\" \"\$CL\"." \
    "Then: agp-platform done GG-7.1 --witness <second human's email>"
}

step GG-7.2 AUTO "Log-based alert policies for the PL-10 rows with a documented source" \
  --needs "GEMINI_PROJECT NOTIF_CH_PAGER_GEMINI NOTIF_CH_EMAIL_GEMINI ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
_p20_pl10_rows() {  # NAME<TAB>SEVERITY<TAB>FILTER: the three rows of the page's table that have a documented source
  printf '%s\t%s\t%s\n' \
    pl10-engine-update CRITICAL 'protoPayload.serviceName="discoveryengine.googleapis.com" AND protoPayload.methodName:"EngineService.UpdateEngine"' \
    pl10-assistant-update CRITICAL 'protoPayload.serviceName="discoveryengine.googleapis.com" AND protoPayload.methodName:"AssistantService.UpdateAssistant"' \
    pl10-agent-update ERROR 'protoPayload.serviceName="discoveryengine.googleapis.com" AND protoPayload.methodName:"AgentService.UpdateAgent"'
}
_p20_policy_has() { # DISPLAY_NAME: 0 when an alert policy of that display name exists in GEMINI_PROJECT
  nonempty r gcloud monitoring policies list --project="$(v GEMINI_PROJECT)" --filter="displayName=\"$1\"" --format='value(name)'
}
s_GG_7_2_check() {   # every policy is read, not only up to the first missing one; the apply creates only those absent
  local n
  _p20_seen_reset GG-7.2
  for n in pl10-engine-update pl10-assistant-update pl10-agent-update; do _p20_seen "$n" _p20_policy_has "$n"; done
  _p20_seen_result
}
s_GG_7_2_apply() {
  local p d repo m c n s f rc
  p="$(v GEMINI_PROJECT)"; d="$(_p20_dir)"; repo="$(v PLATFORM_REPO_DIR)/monitoring/gemini"
  _p20_mkdirs || return 1
  _p20_grant ENT_PROJECT_REPAIR_TENANT_APP 3600 "setup 20 GG-7 Tier C detections" || return 1
  for c in NOTIF_CH_PAGER_GEMINI NOTIF_CH_EMAIL_GEMINI; do
    case "$(v "$c")" in '<'*) [ "$AGP_MODE" = apply ] && { echo "STOP: GG-7.1 left a placeholder channel; no policy is created"; return 1; };; esac
    if [ "$AGP_MODE" = apply ]; then
      r gcloud beta monitoring channels describe "$(v "$c")" --project="$p" --format='value(name)' >/dev/null \
        || { echo "STOP: channel missing: $(v "$c")"; return 1; }
    else
      _p20_plan "reads: gcloud beta monitoring channels describe $(v "$c") --project=$p (STOP if missing)"
    fi
  done
  m="$(_p20_file GG-7.2 method-names txt)"
  if [ "$AGP_MODE" = apply ]; then
    r gcloud logging read 'LOG_ID("cloudaudit.googleapis.com/activity") AND protoPayload.serviceName=("networkservices.googleapis.com" OR "networksecurity.googleapis.com" OR "iam.googleapis.com" OR "discoveryengine.googleapis.com")' \
      --project="$p" --freshness=30d --format='value(protoPayload.serviceName,protoPayload.methodName)' | sort -u | xw "$m" 644 || return 1
    sed 's/^/  /' "$m"
  else
    _p20_plan "reads: gcloud logging read <Admin Activity of networkservices, networksecurity, iam, discoveryengine> --project=$p --freshness=30d > $m (GG-7.2b's input)"
  fi
  if [ "$AGP_MODE" != apply ] || [ ! -d "$repo" ]; then x mkdir -p "$repo" || return 1; fi
  while IFS='	' read -r n s f; do
    [ -n "$n" ] || continue
    jq -n --arg n "$n" --arg f "LOG_ID(\"cloudaudit.googleapis.com/activity\") AND $f" --arg s "$s" --arg c1 "$(v NOTIF_CH_PAGER_GEMINI)" --arg c2 "$(v NOTIF_CH_EMAIL_GEMINI)" \
      '{displayName:$n, documentation:{content:("PL-10 (07 §6.4). Check the change ticket and active ent-ge-admin grant; outside an announced window page the incident commander. setup 20 GG-7.2"), mimeType:"text/markdown"}, conditions:[{displayName:$n, conditionMatchedLog:{filter:$f}}], combiner:"OR", alertStrategy:{notificationRateLimit:{period:"300s"}, autoClose:"1800s"}, severity:$s, notificationChannels:[$c1,$c2]}' \
      | xw "$d/$n.json" 644 || return 1
    _p20_absent GG-7.2 "$n" _p20_policy_has "$n"; rc=$?
    case $rc in
      1) echo "$n exists; not created again";;
      0) x gcloud monitoring policies create --project="$p" --policy-from-file="$d/$n.json" || return 1;;
      *) return 1;;
    esac
    x cp "$d/$n.json" "$repo/$n.json" || return 1
  done <<EOF
$(_p20_pl10_rows)
EOF
  if [ "$AGP_MODE" = apply ]; then
    r gcloud monitoring policies list --project="$p" --format='value(displayName,enabled)'
    echo "REVIEW: three enabled pl10 policies; their notificationChannels are only the two GG-7.1 set. The commit of"
    echo "  monitoring/gemini is GG-7.2b's (its block defines mk again: paste GG-7.2's mk line first)."
  fi
  ev GG-7.2 pl10-alert-policies E-10 5.2.4 "platform-repo:monitoring/gemini/"
}

step GG-7.2b HUMAN "pl10-gateway-write, built from the method names actually seen" --on-unmet skip \
  --needs "GEMINI_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR NOTIF_CH_PAGER_GEMINI NOTIF_CH_EMAIL_GEMINI"
s_GG_7_2b_check() { ckpt_done GG-7.2b; }
s_GG_7_2b_manual() {
  _p20_m "WHY HUMAN: the filter is composed from the method names the project actually logged, and when there are none" \
    "  the step is PENDING until GG-7.3's gateway fixture writes one. The run goes on meanwhile." \
    "WHO: the platform owner under GG-7.1's grant. WHERE: the shell, both helper files sourced." \
    "DO: define mk by pasting the mk() line of GG-7.2's block (the script ran GG-7.2 in its own shell), then GG-7.2b's" \
    "  block of setup/20 (method-names file, NAMES, the filter file, mk pl10-gateway-write, copy, commit monitoring/gemini)." \
    "NAMES empty: checkpoint GG-7.2b PENDING - - \"no gateway write methods logged yet\"; re-run after GG-7.3's fixture." \
    "VERIFY: monitoring policies list --project=\"\$GEMINI_PROJECT\" shows four enabled policies; pl10-gateway-write's filter" \
    "  holds at least one networkservices method name." \
    "Evidence: evidence_add GG-7.2b pl10-gateway-write E-10 5.2.4 \"platform-repo:monitoring/gemini/\". Then: agp-platform done GG-7.2b"
}

step GG-7.3 HUMAN "Fire each alert on a throwaway fixture" --witness \
  --needs "GEMINI_PROJECT GEMINI_PROJECT_NUMBER GE_THROWAWAY_APP_ID BUILD_LOG_DIR"
s_GG_7_3_check() { ckpt_done GG-7.3; }
s_GG_7_3_manual() {
  _p20_m "WHY HUMAN: the share fixture is a console action, the gateway fixture reuses GG-1.2's heredoc, and the second" \
    "  human confirms each page and email." \
    "WHO: the platform owner under ENT_GE_ADMIN and the repair grant; the second human confirms receipt." \
    "DO: on the throwaway app only (before GG-6.3): GG-7.3's block (displayName PATCH, fixture-times.txt); UpdateAssistant" \
    "  by writing customerPolicy back unchanged; UpdateAgent by an All users share and removal on a fixture agent; gateway" \
    "  write by importing and deleting gg-fixture-egress (GG-1.2's YAML renamed). Record each time." \
    "VERIFY: within 10 minutes of each fixture an incident opens for the matching policy on both channels and closes after" \
    "  autoClose; a silent policy is fixed and re-fired before GG-8 (a placeholder channel is GG-7.1's error)." \
    "Evidence: evidence_add GG-7.3 pl10-fixtures-fired E-10 1.6.1 \"build-log:ge-gateway/fixture-times.txt\" \"\$GG_DIR/fixture-times.txt\"." \
    "Then: agp-platform done GG-7.3 --witness <second human's email>"
}

step GG-7.4 HUMAN "An SCC test finding on GEMINI_PROJECT through 15's route" --witness \
  --needs "ORG_ID SCC_ROUTE_TEST_SOURCE GEMINI_PROJECT_NUMBER CORE_PROJECT"
s_GG_7_4_check() { ckpt_done GG-7.4; }
s_GG_7_4_manual() {
  _p20_m "WHY HUMAN: the IT security SCC administrator raises the finding on their own workstation; the second human" \
    "  confirms the page." \
    "WHO: the IT security SCC administrator raises; the platform owner pulls; the second human confirms (witness)." \
    "WHERE: IT security's workstation; the platform owner's shell." \
    "DO: IT security runs GG-7.4's block of setup/20 (the eu endpoint override, gcloud scc findings create --organization" \
    "  --location=eu --source --category=AGP_ROUTE_TEST on the GEMINI_PROJECT_NUMBER resource); the owner pulls and acks on" \
    "  scc-findings-desk in CORE_PROJECT (15 PS-6.8); IT security sets the finding INACTIVE and unsets the override." \
    "VERIFY: the pulled message names the project number resource and AGP_ROUTE_TEST; L1 and the second human paged" \
    "  within 10 minutes; no second page on INACTIVE. Evidence: GG-7.4's evidence_add, with the saved message file." \
    "Then: agp-platform done GG-7.4 --witness <second human's email>"
}

step GG-7.5 HUMAN "Share detection by scheduled reads: the manual interim" --on-unmet skip \
  --needs "DRILL_CALENDAR BUILD_LOG_DIR"
s_GG_7_5_check() { ckpt_done GG-7.5; }
s_GG_7_5_manual() {
  _p20_m "WHY HUMAN: a weekly console read of every agent's User permissions against the register (no audit method is" \
    "  documented for a group share), read in turn by the second human. The run goes on meanwhile." \
    "WHO: the platform owner weekly; the second human reads the weekly record." \
    "WHERE: console > Gemini Enterprise > production app > Agents > each agent > User permissions; the shell." \
    "DO: GG-7.5's block of setup/20 now (row DR-20-2 in DRILL_CALENDAR, commit); then the first weekly read: members vs" \
    "  audience_groups, All users not in the row, agents without a row (each a severity 2 finding to platform-security@)." \
    "VERIFY: <date>-GG-7.5-share-read-v1.md with one line per agent." \
    "Evidence: evidence_add GG-7.5 share-read-weekly E-06 4.2.1 \"build-log:ge-gateway/<weekly record>\" \"\$GG_DIR/<weekly record>\"." \
    "Then, after the first weekly record: agp-platform done GG-7.5"
}

step GG-7.6 BLOCKED "Reconciliation and drift jobs extended to the app (BLOCKED)" --note "B-02: drift and reconciliation job code"
s_GG_7_6_check() { ckpt_done GG-7.6; }
s_GG_7_6_manual() {
  _p20_m "BLOCKED on README B-02: the reconciliation and drift jobs extended with the app's agents, per-agent sharing (Q13's" \
    "  method), gemini-egress's access policy and registry entries, feature toggles, modelArmorConfig, sessionConfig and IAM," \
    "  all by direct API reads. GG-7.5 runs meanwhile; nothing at Tier C waits for it. The run continues." \
    "When unblocked: deploy by digest, run once, compare with the last GG-7.5 record (E-06, TISAX 5.2.6)."
}

# ======================================================================== GG-8 The Tier C gate (GE-14)

step GG-8.1 HUMAN "Close the detection sitting" --removes --needs "ENT_PROJECT_REPAIR_TENANT_APP ENT_GE_ADMIN CICD_PROJECT BUILD_LOG_DIR"
s_GG_8_1_check() { ckpt_done GG-8.1; }
s_GG_8_1_manual() {
  _p20_m "WHY HUMAN: the close is a person's reading of every GG checkpoint (DONE, N/A with a reason, PENDING for GG-7.2b" \
    "  only, BLOCKED for GG-7.6 and GG-2.1's runtime path only) after the day-7 review." \
    "WHO: the platform owner. WHERE: the shell, ~/.platform-env sourced." \
    "DO: GG-8.1's block of setup/20 (revoke every ACTIVE grant on ENT_REPAIR and ENT_GE_ADMIN, then the checkpoint listing)." \
    "VERIFY: no active grant; every GG step before GG-8 in an accepted state; GG-6.3 DONE; GG-6.1b DONE or N/A, never both." \
    "Evidence: checkpoint lines (TISAX 4.1.3). Then: agp-platform done GG-8.1"
}

step GG-8.2 HUMAN "Write and sign TIER_C_RECORD" --witness \
  --needs "BUILD_LOG_DIR REGISTER_PATH AGENT_REGISTRY TIER_R_RECORD SCC_TIER GE_SPIKE_RECORD GE_EGRESS_GATEWAY GE_AUTHZ_EXTENSION GE_ACCESS_POLICY GE_REGISTRY EVIDENCE_INTERIM_LOCATION" \
  --sets "TIER_C_RECORD"
s_GG_8_2_check() { ckpt_done GG-8.2; }
s_GG_8_2_manual() {
  _p20_m "WHY HUMAN: the record is a heredoc of the page, each Result cell is filled with PASS and its evidence id by a" \
    "  person, the platform owner signs and the second human acknowledges the detection lines." \
    "WHO: the platform owner signs (self-review as security reviewer, HLD 0.4); the second human acknowledges." \
    "WHERE: build log records/." \
    "DO: GG-8.2's block of setup/20 (the record, commit, penv_set TIER_C_RECORD \"\$R\"); fill every Result cell (or the" \
    "  compensating-control decision for the binding lines); the second human's acknowledgement by reply mail." \
    "VERIFY: no empty Result cell; both signatures present (the reply saved to EVIDENCE_INTERIM_LOCATION)." \
    "Evidence: evidence_add GG-8.2 tier-c-record E-05 1.2.2 \"build-log:records/\$(basename \"\$R\")\" \"\$R\"." \
    "Then: agp-platform done GG-8.2 --witness <second human's email>"
}

step GG-8.3 HUMAN "Correct the design pages the review named" --needs "WIKI_DIR"
s_GG_8_3_check() { ckpt_done GG-8.3; }
s_GG_8_3_manual() {
  _p20_m "WHY HUMAN: a normal wiki edit, not a command of the procedure." \
    "WHO: the platform owner. WHERE: the wiki: ../03-gemini-enterprise-environment.md, ../README.md, ../01-hld.md 0.4." \
    "DO: the edits GG-8.3 lists (03 11.1 binding row, 3 constraint row per Q10, 13 share source per Q11, 4 and 10.2" \
    "  agentspaceUser, 16 GE-13 and GE-14; README step 7; HLD 0.4 C row linking TIER_C_RECORD); then its two greps." \
    "VERIFY: the first grep shows 11.1's row; the second prints 0." \
    "Evidence: the wiki commit id in the build log under GG-8.3 (E-05, TISAX 5.2.1). Then: agp-platform done GG-8.3"
}

step GG-8.4 HUMAN "End the sitting" --needs "TIER_C_RECORD"
s_GG_8_4_check() { ckpt_done GG-8.4; }
s_GG_8_4_manual() {
  _p20_m "WHY HUMAN: sitting_end revokes this shell's credentials, so it is the last thing a person runs." \
    "WHO: the platform owner. WHERE: the shell." \
    "DO: the page's block: checkpoint GG-8.4 DONE - \"\$TIER_C_RECORD\" (or: agp-platform done GG-8.4), then" \
    "  agp-platform sitting end (01's sitting_end)." \
    "VERIFY: SITTING-END OK. Evidence: the checkpoint line (TISAX 4.1.2)."
}
