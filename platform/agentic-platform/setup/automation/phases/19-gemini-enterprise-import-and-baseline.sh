# phases/19-gemini-enterprise-import-and-baseline.sh: setup/19, the import of the live Gemini Enterprise
# app into the platform: the tenant-app record, the union allow-list and its 14-day dry run, the move,
# the connector constraints, access (fill, bind, test, remove), engine and assistant settings, the
# CmekConfig, the console Model Armor setting, quota and close.
#
# How the page maps onto the classes:
# - The app location is eu only (SD-21). Every check of this phase reads GE_LOCATION and
#   GEMINI_APP_LOCATION first: any other value (a global app) is a STOP, so the phase cannot run on
#   another app whatever step it is started from.
# - Deterministic Cloud work under a PAM grant is AUTO: the grant is requested, awaited until ACTIVE
#   (the approver named on the entitlement acts where one is named) and revoked in the same step, so
#   every step that revokes its grant declares --removes. A grant's name and end state, and an
#   entitlement's settings, are read with filtered lists (`grants search`, `entitlements list
#   --filter`), not by parsing a describe.
# - Pull requests with two reviewers, decisions and signatures (DPO, drops, populations, CmekConfig),
#   member lists (personal data: the script never prints or logs them), the colleague's own tests and
#   the operator-question corpus are HUMAN. Clicks in the Gemini Enterprise console are CONSOLE.
# - GE-0.3 writes the page's helper file with a heredoc. A phase never retypes a page's heredoc
#   (lib/PHASES.md) and no asset for it exists yet, so the person runs that block: HUMAN.
# - GE-2.6 and GE-6.7 are BLOCKED; GE-8.3's standing part is BLOCKED on B-02 and noted.
# - 17's zero-diff checker decides GE-2.7, GE-3.11 and GE-8.4 by its exit status with --accept-pending: the import's
#   expected differences are pending lines of the run spec (GE-2.1, revised in GE-5.9). A FAIL line is the page's STOP
#   (98): a person repairs it or adds a pending line by pull request, then the step is resumed; nothing is accepted by eye.
# - The colleague's steps (GE-3.9, GE-3.11, GE-6.13) run with --witness GE_TEST_USER, the address GE-0.2 saved.
# - Steps the page allows to be N/A (GE-6.3, GE-6.6, GE-6.8, GE-6.11 to GE-6.13) read an N/A line in
#   checkpoints.tsv as done; GE-6.11 to GE-6.13 also read decision (a) from GE-6.10's checkpoint note and
#   then return 5 (not applicable).
# - Every gcloud command names its scope: --project, --folder or --billing-project, a positional
#   project id, or a fully specified resource name (PAM entitlements and grants, KMS keys); the policy
#   files given to `org-policies set-policy` carry their own projects/ or folders/ name.
#
# Helpers are prefixed _p19_ because every phase file is loaded into the same shell.

phase 19 "Gemini Enterprise: import, move and live-app-safe baseline" "19-gemini-enterprise-import-and-baseline.md" "GE-[0-9]+\\."
requires org "resourcemanager.projects.get resourcemanager.folders.get"

P19_GRANT=""
P19_TAB=$'\t'
P19_EU_HOST="https://eu-discoveryengine.googleapis.com/v1"
P19_MA_EU="CLOUDSDK_API_ENDPOINT_OVERRIDES_MODELARMOR=https://modelarmor.eu.rep.googleapis.com/"
P19_RSU_REL="policies/folders/fld-gemini-enterprise/gcp.restrictServiceUsage.yaml"
P19_ADS_REL="policies/folders/fld-gemini-enterprise/discoveryengine.managed.allowedDataSources.yaml"
P19_AEF_REL="policies/folders/fld-gemini-enterprise/discoveryengine.managed.allowedEgressFqdns.yaml"
P19_SPEC_REL="factory/runs/gemini-prod.json"

# ---------------------------------------------------------------- helpers
_p19_live() { [ "$AGP_MODE" = apply ]; }
_p19_plan() { _p19_live || printf '      %s\n' "$*" >&3; }
_p19_show() { _p19_live || printf '      read: %s\n' "$(agp_quote "$@")" >&3; }
_p19_gedir() { printf '%s/ge-baseline' "$(v BUILD_LOG_DIR)"; }
_p19_bucket() { local b; b="$(v LOG_BUCKET_EVIDENCE)"; printf '%s' "${b##*/}"; }   # logging read --bucket takes the id (GE-3.11)
_p19_ckpt() { printf '%s/checkpoints.tsv' "$(v BUILD_LOG_DIR)"; }

_p19_colleague() {  # the page's checkpoint names GE_TEST_USER as witness: --witness must be that address
  _p19_live || { _p19_plan "the non-admin colleague $(v GE_TEST_USER) takes part: apply with --witness $(v GE_TEST_USER)"; return 0; }
  [ "$AGP_WITNESS" = "$(v GE_TEST_USER)" ] && return 0
  echo "STOP: --witness is '$AGP_WITNESS', but the colleague of this step is GE_TEST_USER ($(v GE_TEST_USER), GE-0.2)"; return 1
}
_p19_api_base() { printf '%s/projects/%s/locations/eu' "$P19_EU_HOST" "$(v GEMINI_PROJECT)"; }
_p19_app() { printf '%s/collections/default_collection/engines/%s' "$(_p19_api_base)" "$(v GEMINI_APP_ID)"; }
_p19_asst() { printf '%s/assistants/default_assistant' "$(_p19_app)"; }

_p19_eu() {     # 2 (and a STOP line) when GE_LOCATION or GEMINI_APP_LOCATION holds anything but eu (SD-21)
  local n val
  for n in GE_LOCATION GEMINI_APP_LOCATION; do
    has_value "$n" || continue
    val="$(_penv_get "$n" | tr 'A-Z' 'a-z')"
    [ "$val" = eu ] && continue
    agp_say "      STOP: $n is '$(_penv_get "$n")', not eu. setup/19 serves only the eu app (SD-21); a global or other app stops the phase"
    return 2
  done
  return 0
}

_p19_na() {     # ID: checkpoints.tsv holds an N/A line for the step (the page allows N/A for it)
  [ -n "${BUILD_LOG_DIR-}" ] && [ -f "$BUILD_LOG_DIR/checkpoints.tsv" ] || return 1
  awk -F'\t' -v s="$1" '$2 == s && $3 == "N/A" {f=1} END {exit f ? 0 : 1}' "$BUILD_LOG_DIR/checkpoints.tsv"
}

_p19_pre() {    # ID: 0 done (checkpoint DONE or N/A), 2 stop (not eu), 1 carry on with the state read
  _p19_eu || return 2
  ckpt_done "$1" && return 0
  _p19_na "$1" && return 0
  return 1
}

_p19_ck() { _p19_pre "$1"; }   # the check of a manual step

_p19_cmek_letter() {    # the decision letter recorded on GE-6.10's DONE checkpoint ("decision a|b|c")
  [ -n "${BUILD_LOG_DIR-}" ] && [ -f "$BUILD_LOG_DIR/checkpoints.tsv" ] || return 1
  awk -F'\t' '$2 == "GE-6.10" && $3 == "DONE" {n=$0} END {print n}' "$BUILD_LOG_DIR/checkpoints.tsv" \
    | grep -oE 'decision \(?[abc]\)?' | tail -1 | sed -E 's/^decision \(?([abc]).*/\1/'
}

_p19_file() {   # STEP REC EXT: the next unused <date>-STEP-REC-v<n>.EXT under ge-baseline (never overwritten)
  local d day n=1
  d="$(_p19_gedir)"; day="$(date -u +%F)"
  while [ -e "$d/$day-$1-$2-v$n.$3" ]; do n=$((n + 1)); done
  printf '%s/%s-%s-%s-v%s.%s' "$d" "$day" "$1" "$2" "$n" "$3"
}

_p19_latest() { # STEP-REC EXT: the newest such file under ge-baseline, or return 1
  local f
  # shellcheck disable=SC2012
  f="$(ls -t "$(_p19_gedir)"/*-"$1"-v*."$2" 2>/dev/null | head -1)"
  [ -n "$f" ] || return 1
  printf '%s' "$f"
}

_p19_mkdir() {  # the working directory of GE-0.3, made if a step runs before the person ran GE-0.3
  local d; d="$(_p19_gedir)"
  if [ -d "$d" ] || ! _p19_live; then return 0; fi
  x mkdir -p "$d"
}

_p19_get() {    # CMD...: a read that prints its output; 0 ok, 1 not found, 2 another error (shown), 3 offline
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local err rc; err="$(mktemp "${TMPDIR:-/tmp}/agp-p19.XXXXXX")" || return 2
  "$@" 2>"$err"; rc=$?
  if [ $rc -ne 0 ]; then
    if grep -qiE 'NOT_FOUND|not found|does not exist|was not found|404' "$err"; then rc=1
    else sed 's/^/        /' "$err" >&3; rc=2; fi
  fi
  rm -f "$err"; return $rc
}

_p19_out() {    # FILE CMD...: the read's output saved to FILE (xw); returns the read's status
  local f="$1" o rc; shift
  if ! _p19_live; then _p19_show "$@"; printf '      would write %s\n' "$f" >&3; return 0; fi
  o="$(r "$@")"; rc=$?
  printf '%s\n' "$o" | xw "$f" 644 || return 1
  return $rc
}

_p19_api() {    # METHOD URL [BODY]: a call on the eu app host, quota project GEMINI_PROJECT (ge_call's header)
  if [ "$1" = GET ] && ! _p19_live && [ "$AGP_CALL_CONTEXT" != check ]; then printf '      read: api GET %s\n' "$2" >&3; return 0; fi
  AGP_API_PROJECT="$(v GEMINI_PROJECT)" api "$@"
}

_p19_apiout() { # FILE URL: GET saved to FILE
  local f="$1" o rc
  if ! _p19_live; then printf '      read: api GET %s\n      would write %s\n' "$2" "$f" >&3; return 0; fi
  o="$(_p19_api GET "$2")"; rc=$?
  printf '%s\n' "$o" | xw "$f" 644 || return 1
  return $rc
}

_p19_acc() {    # RC: a check that reads every item: 0 and 1 are folded into the caller's miss (1 when any item
                # is missing); any other status is returned for the caller to pass through (2 cannot tell, 3 offline)
  case "$1" in 0) return 0;; 1) miss=1; return 0;; esac
  return "$1"
}

_p19_jtest() {  # JSON FILTER [jq args...]: jq -e on a string; 0 true, 1 anything else
  local j="$1" flt="$2"; shift 2
  printf '%s' "$j" | jq -e "$@" "$flt" >/dev/null 2>&1
}

_p19_epoch() {  # ISO-8601 UTC timestamp -> epoch seconds (BSD and GNU date, as the page writes it)
  date -u -j -f %Y-%m-%dT%H:%M:%SZ "$1" +%s 2>/dev/null || date -u -d "$1" +%s
}

_p19_ago() {    # BSD_OFFSET GNU_OFFSET: an ISO timestamp in the past (-v-30d / '-30 days')
  date -u -v"$1" +%FT%TZ 2>/dev/null || date -u -d "$2" +%FT%TZ
}

_p19_fq_ok() {  # NAME: a fully specified entitlement name
  case "$1" in
    projects/*/locations/*/entitlements/*|folders/*/locations/*/entitlements/*|organizations/*/locations/*/entitlements/*) return 0;;
  esac
  return 1
}

_p19_fq() {     # NAME: the page's pam_fq; a short entitlement id is a stop, never a silent default
  _p19_fq_ok "$1" && return 0
  agp_say "      STOP: entitlement '$1' is not a fully specified name (setup/19 section 4, GE-0.3's pam_fq)"
  return 1
}

_p19_scope() {      # ENTITLEMENT_NAME: the scope flag of its parent (--project=, --folder= or --organization=)
  case "$1" in
    projects/*) printf -- '--project=%s' "$(printf '%s' "${1#projects/}" | cut -d/ -f1)";;
    folders/*) printf -- '--folder=%s' "$(printf '%s' "${1#folders/}" | cut -d/ -f1)";;
    organizations/*) printf -- '--organization=%s' "$(printf '%s' "${1#organizations/}" | cut -d/ -f1)";;
    *) return 1;;
  esac
}

_p19_ent_has() {    # ENTITLEMENT_NAME FILTER: the entitlement is listed on its parent and matches FILTER
                    # (a filtered list, not a parse of describe: 0 yes, 1 no, 2 error, 3 offline)
  local sc; sc="$(_p19_scope "$1")" || return 2
  nonempty r gcloud pam entitlements list "$sc" --location=global --billing-project="$(v CICD_PROJECT)" \
    --filter="name=$1${2:+ AND ($2)}" --format='value(name)'
}

_p19_open() {       # ENTITLEMENT_NAME: the newest grant the caller created on it that is not finished
  r gcloud pam grants search --entitlement="$1" --caller-relationship=had-created \
    --filter='state=ACTIVE OR state=APPROVAL_AWAITED OR state=ACTIVATING OR state=SCHEDULED' \
    --billing-project="$(v CICD_PROJECT)" --format='value(name)' | head -1
}

_p19_gname_ok() {   # GRANT: one resource name (a path, no space); Google's are .../entitlements/ID/grants/ID
  case "$1" in ''|*' '*|*"$P19_TAB"*) return 1;; */*) return 0;; esac
  return 1
}
_p19_request() {    # ENT_VAR DURATION JUSTIFICATION: prints the name of the caller's open grant, requesting one if none
  local ent bp g
  ent="$(v "$1")"; bp="$(v CICD_PROJECT)"
  if ! _p19_live; then
    if has_value "$1" && ! _p19_fq_ok "$ent"; then _p19_plan "STOP at apply: $1 is not a fully specified entitlement name (GE-0.3's pam_fq)"; fi
    x gcloud pam grants create --entitlement="$ent" --requested-duration="$2" --justification="$3" --billing-project="$bp" --format='value(name)'
    printf '<grant on %s>' "$1"; return 0
  fi
  _p19_fq "$ent" || return 1
  g="$(_p19_open "$ent")"
  if [ -n "$g" ]; then agp_say "      the caller's open grant on $1 is reused: $g"
  else
    g="$(x gcloud pam grants create --entitlement="$ent" --requested-duration="$2" --justification="$3" \
          --billing-project="$bp" --format='value(name)' | tail -1)" || return 1
    # the name is read back by a filtered search when the create printed anything else
    _p19_gname_ok "$g" || g="$(_p19_open "$ent")"
  fi
  _p19_gname_ok "$g" || { agp_say "      STOP: no open grant of the caller on $1 after the request ('$g')"; return 1; }
  printf '%s' "$g"
}

_p19_ended() {      # ENT_VAR GRANT: the grant reads REVOKED or ENDED (a filtered search; 0 yes, 1 no, 2 error)
  nonempty r gcloud pam grants search --entitlement="$(v "$1")" --caller-relationship=had-created \
    --filter="name=$2 AND (state=REVOKED OR state=ENDED)" --billing-project="$(v CICD_PROJECT)" --format='value(name)'
}

_p19_wait() {   # GRANT: the page's pam_active, bounded: polls until ACTIVE (one hour at most)
  local st i=0
  if ! _p19_live; then _p19_plan "then waits until $1 reads ACTIVE (APPROVAL_AWAITED until the approver acts); nothing privileged runs before"; return 0; fi
  while :; do
    st="$(r gcloud pam grants describe "$1" --billing-project="$(v CICD_PROJECT)" --format='value(state)')"
    agp_say "      grant state: $st"
    case "$st" in
      ACTIVE) return 0;;
      APPROVAL_AWAITED|ACTIVATING|SCHEDULED) ;;
      *) agp_say "      STOP: grant $1 is '$st', not ACTIVE"; return 1;;
    esac
    i=$((i + 1))
    [ $i -lt 180 ] || { agp_say "      STOP: $1 is not ACTIVE after an hour; when the approver has acted, resume from this step"; return 1; }
    _p19_sleep 20
  done
}

_p19_scaled() { # N: a wait the page prescribes (seconds or days), times AGP_WAIT_SCALE (a whole number, 1 when
                # unset; the offline tests set 0)
  local s="${AGP_WAIT_SCALE:-1}"
  case "$s" in ''|*[!0-9]*) s=1;; esac
  [ "$s" = 1 ] || agp_say "      AGP_WAIT_SCALE=$s: the page's wait of $1 becomes $(($1 * s)) (offline tests only)"
  printf '%s' $(($1 * s))
}

_p19_sleep() {  # SECONDS: a poll interval, scaled
  sleep "$(_p19_scaled "$1")"
}

_p19_grant() {  # ENT_VAR DURATION JUSTIFICATION: an ACTIVE grant, its name in P19_GRANT
  P19_GRANT="$(_p19_request "$1" "$2" "$3")" || { P19_GRANT=""; return 1; }
  _p19_wait "$P19_GRANT"
}

_p19_revoke() { # REASON [GRANT]: every grant is revoked in its own step (setup/19 section 4, PAM)
  local g="${2:-$P19_GRANT}"
  [ -n "$g" ] || return 0
  x gcloud pam grants revoke "$g" --reason="$1" --billing-project="$(v CICD_PROJECT)"
}

_p19_committed() {  # REL: the policy or spec file is on main and the working copy equals it; prints the short commit
  local repo c; repo="$(v PLATFORM_REPO_DIR)"
  [ -f "$repo/$1" ] || { agp_say "      STOP: $1 does not exist in PLATFORM_REPO_DIR"; return 1; }
  c="$(git -C "$repo" log -1 --first-parent --format=%h main -- "$1" 2>/dev/null)"
  [ -n "$c" ] || { agp_say "      STOP: $1 has no commit on main: merge its pull request (two reviewers), git pull, then resume"; return 1; }
  git -C "$repo" diff --quiet main -- "$1" 2>/dev/null || { agp_say "      STOP: the working copy of $1 differs from main"; return 1; }
  printf '%s' "$c"
}

_p19_pending() {    # STEP MEMBER WHAT: exists_or_pending's PENDING row in rerun-index.tsv, written once
  local f; f="$(v BUILD_LOG_DIR)/rerun-index.tsv"
  if [ -f "$f" ] && awk -F'\t' -v s="$1" -v m="$2" '$2 == s && $3 == m && $5 == "PENDING" {f=1} END {exit f ? 0 : 1}' "$f"; then
    agp_say "      PENDING $2 already recorded for $1"; return 0
  fi
  { [ -f "$f" ] && cat "$f"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%d)" "$1" "$2" "$3" PENDING "group not found; recorded by agp-platform"; } | xw "$f" 644
}

_p19_zero_diff() {  # STEP REC: 17's checker in live mode on the run spec; the report saved as a ge-baseline record.
                    # 0 ZERO-DIFF; 4 a FAIL line (or a PENDING without --accept-pending): the non-PASS lines are printed;
                    # 98 the checker is not merged (17 FM-1.2, a precondition the page stops on); 1 it could not run
  local f tool spec tmp rc
  f="$(_p19_file "$1" "$2" json)"; tool="$(v PLATFORM_REPO_DIR)/tools/fm-zero-diff.py"; spec="$(v PLATFORM_REPO_DIR)/$P19_SPEC_REL"
  if ! _p19_live; then
    _p19_show python3.12 "$tool" live "$spec" --report "$f" --accept-pending; return 0
  fi
  command -v python3.12 >/dev/null 2>&1 || { agp_say "      STOP: python3.12 is not on PATH (17 FM-1.2's checker needs it)"; return 1; }
  if [ ! -f "$tool" ]; then   # the page's STOP: the checker is 17 FM-1.2's, a precondition of setup/19 (section 2)
    agp_say "      STOP: $tool is not on main: 17 FM-1.2 merges it (setup/19 section 2); then resume from $1"
    return 98
  fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/agp-p19.XXXXXX")" || return 1
  r env PLATFORM_REPO_DIR="$(v PLATFORM_REPO_DIR)" python3.12 "$tool" live "$spec" --report "$tmp" --accept-pending | tail -n 3; rc=$?
  agp_say "      exit $rc"
  if ! jq -e 'has("zero_diff")' "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"; agp_say "      STOP: the checker wrote no report"; return 1
  fi
  xw "$f" 644 < "$tmp" || { rm -f "$tmp"; return 1; }
  rm -f "$tmp"
  jq -r '.results[] | select(.status != "PASS") | "        \(.status) \(.check) \(.pending.owner // "") \(.pending.rerun_in // "")" + (if .status == "FAIL" then ": expected \(.expected | tostring), read \(.actual | tostring)" else "" end)' "$f" 2>/dev/null | head -40
  jq -e '.zero_diff == true' "$f" >/dev/null 2>&1 && return 0
  return 4
}

_p19_zero_stop() {  # STEP: the page's STOP on a FAIL line (repair, or a pending line by pull request; never by eye)
  agp_say "      STOP: the checker reports a FAIL (above). Repair it (ENT_PROJECT_REPAIR_TENANT_APP for an in-project item), or, for an"
  agp_say "        expected difference, add a pending line {check, reason, owner, rerun_in} to $P19_SPEC_REL by pull request (two"
  agp_say "        reviewers, GE-2.1's shape); git pull on main; then resume from $1. A difference is never accepted by eye."
  return 98
}

_p19_zero_ok() {    # STEP-REC: the newest such report says zero_diff true
  local f; f="$(_p19_latest "$1" json)" || return 1
  jq -e '.zero_diff == true' "$f" >/dev/null 2>&1
}

_p19_rsu_yaml() {   # NAME_PREFIX SPEC_KEY FINAL: a restrictServiceUsage policy file carrying FINAL's services
  printf 'name: %s/policies/gcp.restrictServiceUsage\n%s:\n  rules:\n  - values:\n      allowedValues:\n' "$1" "$2"
  [ -f "$3" ] && sed 's/^/      - /' "$3"
  return 0
}

_p19_final() {      # the newest GE-3.1 allow-list-final, asserted as GE-3.1's gate does (non-empty, discoveryengine in it)
  local f
  if ! _p19_live; then printf '<newest ge-baseline/*-GE-3.1-allow-list-final-v*.txt>'; return 0; fi
  f="$(_p19_latest GE-3.1-allow-list-final txt)" || { agp_say "      STOP: no GE-3.1 allow-list-final in ge-baseline: finish GE-3.1"; return 1; }
  [ "$(grep -c . "$f")" -gt 5 ] || { agp_say "      STOP: $f has $(grep -c . "$f") entries (GE-3.1's gate wants more than 5)"; return 1; }
  grep -qx discoveryengine.googleapis.com "$f" || { agp_say "      STOP: discoveryengine.googleapis.com is not in $f; the live app would be refused"; return 1; }
  printf '%s' "$f"
}

_p19_under() {  # PARENT [EXTRA_FILTER]: GEMINI_PROJECT sits under PARENT (organizations/N or folders/N), as a filtered list
                # (gcloud projects list takes no scope flag; the filter names the project and its parent)
  local t i
  case "$1" in organizations/*) t=organization; i="${1#organizations/}";; folders/*) t=folder; i="${1#folders/}";; *) return 2;; esac
  nonempty r gcloud projects list --filter="projectId=$(v GEMINI_PROJECT) AND parent.type=$t AND parent.id=$i${2:+ AND $2}" --format='value(projectId)'
}

_p19_label_filter() {   # the manifest's labels as a projects list filter (labels.k=v AND ...); 1 when there are none
  local f; f="$(_p19_labels 2>/dev/null)" || return 1
  [ -n "$f" ] || return 1
  printf '%s' "$f" | tr ',' '\n' | sed 's/^/labels./' | paste -sd'#' - | sed 's/#/ AND /g'
}

_p19_people() { echo "  Helpers: source ~/.platform-env; source \"\$BUILD_LOG_DIR/ge-baseline/ge-helpers.sh\" (GE-0.3)."; }

# ---------------------------------------------------------------- GE-0 The sitting and the entry gate

step GE-0.1 AUTO-READ "Open the shell under the guard" \
  --needs "GCLOUD_CONFIG_NAME BUILD_LOG_DIR PLATFORM_REPO_DIR EVIDENCE_REGISTER DEVIATION_REGISTER DOMAIN ORG_ID GE_LOCATION REGION SA_1_ADMIN"
s_GE_0_1_check() { _p19_ck GE-0.1; }
s_GE_0_1_apply() {
  if ! _p19_live; then
    _p19_plan "reads: penv_guard; GE_LOCATION is eu (SD-21: any other value stops the phase); jq on PATH;"
    _p19_plan "  gcloud auth list --filter=status:ACTIVE --format='value(account)' prints exactly $(v SA_1_ADMIN)"
    _p19_plan "before apply: gcloud auth login $(v SA_1_ADMIN) (the operator, interactive), then: agp-platform sitting start"
    return 0
  fi
  local bad=0 acct
  if penv_guard; then echo "guard clean"; else echo "STOP: penv_guard failed (above)"; bad=1; fi
  _p19_eu || bad=1
  command -v jq >/dev/null 2>&1 || { echo "STOP: jq is not on PATH (setup/19 section 2, workstation)"; bad=1; }
  command -v yq >/dev/null 2>&1 || echo "REVIEW: yq is not on PATH; GE-4.2, GE-4.3, GE-4.7, GE-6.4 and GE-6.8's hand blocks need it"
  acct="$(r gcloud auth list --filter=status:ACTIVE --format='value(account)')"
  if [ "$acct" = "$(v SA_1_ADMIN)" ]; then echo "active account: $acct"
  else echo "STOP: the active account is '$acct', not SA_1_ADMIN: gcloud auth login $(v SA_1_ADMIN)"; bad=1; fi
  if ! awk -F'\t' '$2 ~ /^SITTING-/ {s[$2]=$3} END {for (k in s) if (s[k] == "START") f=1; exit f ? 0 : 1}' "$(v BUILD_LOG_DIR)/checkpoints.tsv" 2>/dev/null; then
    echo "REVIEW: no open sitting in checkpoints.tsv: agp-platform sitting start (setup/19 GE-0.1's SITTING checkpoint)"
  fi
  return $bad
}

step GE-0.2 HUMAN "Check the entry gate and name the colleague" \
  --needs "GEMINI_PROJECT GEMINI_PROJECT_NUMBER GEMINI_APP_ID GEMINI_APP_LOCATION GE_EDITION GE_CURRENT_PARENT GE_RETENTION_CURRENT_DAYS GE_INVENTORY_DIR FLD_GEMINI_ENTERPRISE GRP_GE_ADMINS GRP_GE_USERS KEY_GEMINI_CMEK ENT_GE_ADMIN ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST ENT_PLATFORM_POLICY ENT_FOLDER_ADMIN LOGGING_PROJECT CORE_PROJECT CICD_PROJECT TIER_R_RECORD REGISTER_PATH DPO_CONTACT LOG_BUCKET_EVIDENCE SA_1_ADMIN SECOND_HUMAN_EMAIL" \
  --sets "GE_TEST_USER GE_WITNESS GE_ROLLBACK_OPERATOR"
s_GE_0_2_check() { _p19_ck GE-0.2; }
s_GE_0_2_manual() {
  echo "WHO: the platform owner, from the colleague's, the witness's and the rollback operator's agreement mails."
  echo "WHERE: the tenant shell, ~/.platform-env sourced."
  echo "DO: GE-0.2's block of setup/19: app location eu (anything else is a stop), the GI-10.2 fact sheet gate lines read"
  echo "  clear, no PENDING GI-1.5/5.3/6.2, Tier R record present, a GI-2.2 engine read under 30 days old (else re-run 05's"
  echo "  GI-2.2, 3.1, 3.2, 5.1, 5.2); the colleague holds no project role and hasMembership in ge-admins@ is False."
  echo "RECORD: penv_set GE_TEST_USER \"<the colleague's email>\" (later sittings and every colleague checkpoint read it);"
  echo "  penv_set GE_WITNESS \"<security reviewer, or SECOND_HUMAN_EMAIL>\"; penv_set GE_ROLLBACK_OPERATOR \"<a second ge-admins@"
  echo "  member>\"; none is SA_1_ADMIN, the last two differ. Name, team, date in records/19-people.md. GE-3.8 sets"
  echo "  GE_CHANGE_NOTICE_DATE when the notice is sent (penv_set refuses an empty value)."
  echo "EVIDENCE: evidence_add GE-0.2 entry-gate E-05 5.2.1 \"build-log:checkpoints.tsv\" \"\$BUILD_LOG_DIR/checkpoints.tsv\""
  echo "Then: agp-platform done GE-0.2 --note \"colleague named in records/19-people.md\""
}

step GE-0.3 HUMAN "Create the working directory and helpers" \
  --needs "BUILD_LOG_DIR GEMINI_PROJECT GEMINI_APP_ID CICD_PROJECT ENT_GE_ADMIN ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST ENT_PLATFORM_POLICY ENT_FOLDER_ADMIN"
s_GE_0_3_check() { _p19_ck GE-0.3; }
s_GE_0_3_manual() {
  echo "WHO: the platform owner. WHERE: the tenant shell, ~/.platform-env sourced."
  echo "DO: GE-0.3's two blocks of setup/19 as written: ge-baseline/restricted/, its .gitignore line, the ge-helpers.sh heredoc"
  echo "  (the script does not retype a page's heredoc), then the pam_fq loop over the five ENT_* variables."
  echo "  The script's own grants follow the same rule: a short entitlement id stops the step."
  echo "VERIFY: type ge_file ge_latest ge_call pam_fq pam_grant pam_active pam_revoke ma_eu names eight functions; the loop"
  echo "  prints 'fully specified' five times and no STOP; git -C \"\$BUILD_LOG_DIR\" check-ignore \"\$GE_DIR/restricted/x\" prints"
  echo "  the path; echo \"\$GE_APP\" ends with /engines/$(v GEMINI_APP_ID)."
  echo "Then: agp-platform done GE-0.3"
}

# ---------------------------------------------------------------- GE-2 The tenant-app module run (by hand)

step GE-2.1 HUMAN "Write the manifest from the merged register row" \
  --needs "PLATFORM_REPO_DIR REGISTER_PATH GEMINI_PROJECT GEMINI_PROJECT_NUMBER FLD_GEMINI_ENTERPRISE DOMAIN" --sets "GE_MANIFEST_COMMIT"
s_GE_2_1_check() { _p19_ck GE-2.1; }
s_GE_2_1_manual() {
  echo "WHO: the platform owner; the second operator reviews the pull request (two human reviewers merge)."
  echo "WHERE: the tenant shell; $(v PLATFORM_REPO_DIR)."
  echo "DO: GE-2.1's block of setup/19 (jq on factory/runs/_template.json into $P19_SPEC_REL, branch"
  echo "  setup-19-tenant-app-manifest, commit, push); the block writes made_elsewhere {item, file, step} and the import's"
  echo "  pending lines {check, reason, owner, rerun_in}. Then fill the remaining keys as 17 FM-6.1 lists them (services: the"
  echo "  inventory's plus GE-2.4's four) and replace every <from register row> with the row's value. Typed by a person: HUMAN."
  echo "VERIFY: merged by two reviewers; grep -c '<' $P19_SPEC_REL prints 0; python3.12 tools/fm-zero-diff.py inputs"
  echo "  $P19_SPEC_REL --accept-pending exits 0. git pull on main afterwards."
  echo "RECORD: penv_set GE_MANIFEST_COMMIT <the merge commit>   (GE-2.2 writes it into BD-19-1, the page's <commit>)"
  echo "EVIDENCE: evidence_add GE-2.1 tenant-app-manifest E-05 1.3.1 \"repo:$P19_SPEC_REL@<commit>\" \"\$PLATFORM_REPO_DIR/$P19_SPEC_REL\""
  echo "Then: agp-platform done GE-2.1"
}

step GE-2.2 AUTO "Open the deviation-register row" --needs "DEVIATION_REGISTER BUILD_LOG_DIR GEMINI_PROJECT PLATFORM_REPO_DIR GE_MANIFEST_COMMIT"
s_GE_2_2_check() {
  _p19_eu || return 2
  local reg ln cl; reg="$(v DEVIATION_REGISTER)"
  [ -f "$reg" ] || return 1
  [ "$(grep -c '^| BD-19-1 |' "$reg")" = 1 ] || return 1
  ln="$(grep -n '^| BD-19-1 |' "$reg" | cut -d: -f1)"; cl="$(awk '/^## Closures$/ {print NR; exit}' "$reg")"
  [ -n "$cl" ] && [ "$ln" -lt "$cl" ]
}
s_GE_2_2_apply() {
  local reg repo commit row
  reg="$(v DEVIATION_REGISTER)"; repo="$(v PLATFORM_REPO_DIR)"; commit="$(v GE_MANIFEST_COMMIT)"
  if _p19_live; then
    [ -f "$reg" ] || { echo "STOP: DEVIATION_REGISTER ($reg) is not a file (01 PR-4.1)"; return 1; }
    # the page's guard is the placeholder; when the local clone has the commit, its spec is read too
    if git -C "$repo" cat-file -e "$commit^{commit}" 2>/dev/null; then
      git -C "$repo" show "$commit:$P19_SPEC_REL" >/dev/null 2>&1 || { echo "STOP: GE_MANIFEST_COMMIT $commit holds no $P19_SPEC_REL"; return 1; }
      [ "$(git -C "$repo" show "$commit:$P19_SPEC_REL" | grep -c '<')" = 0 ] || { echo "STOP: $P19_SPEC_REL at $commit still holds a <placeholder> (GE-2.1 VERIFY)"; return 1; }
      echo "manifest commit $commit holds $P19_SPEC_REL with no placeholder"
    else
      echo "REVIEW: GE_MANIFEST_COMMIT $commit is not in the local clone (git pull): check it is the manifest's merge commit"
    fi
  fi
  row="$(printf '| BD-19-1 | %s | 19 GE-2 | MOD | tenant-app (import) | %s | register row tenant-app; manifest @%s | labels, contacts, additive services, ent-project-repair-tenant-app; move (GE-3), policies (GE-3, GE-4), audit config (GE-4.8), IAM (GE-5) | pending GE-2.7 | n/a: existing project, basic roles removed in GE-5.8 | pending | superseded by terraform import and empty plan (GE-2.6) | open |' \
    "$(date -u +%F)" "$(v GEMINI_PROJECT)" "$commit")"
  _p19_plan "row: $row"
  x bd_insert "$row"
}

step GE-2.3 AUTO "Create the per-project repair entitlement, or read back the one FM-6.2 made" --removes \
  --needs "GEMINI_PROJECT GRP_PLATFORM_OWNERS SA_2_ADMIN SECOND_HUMAN_EMAIL CICD_PROJECT BUILD_LOG_DIR" --sets "ENT_PROJECT_REPAIR_TENANT_APP"
_p19_repair_ids() {   # the ent-project-repair-* ids on GEMINI_PROJECT, one per line
  r gcloud pam entitlements list --billing-project="$(v CICD_PROJECT)" --project="$(v GEMINI_PROJECT)" --location=global \
    --format='value(name)' | sed 's|.*/||' | grep -E '^ent-project-repair-'
}
P19_REPAIR_ROLES="roles/resourcemanager.projectIamAdmin roles/serviceusage.serviceUsageAdmin roles/essentialcontacts.admin roles/logging.configWriter roles/modelarmor.admin"
_p19_repair_filter() {  # GE-2.3's VERIFY as a list filter: the five roles, one hour, the second human as approver
  local f="" role
  for role in $P19_REPAIR_ROLES; do f="${f}privilegedAccess.gcpIamAccess.roleBindings.role:$role AND "; done
  printf '%smaxRequestDuration=3600s AND approvalWorkflow.manualApprovals.steps.approvers.principals:"user:%s"' "$f" "$(v SA_2_ADMIN)"
}
s_GE_2_3_check() {
  _p19_pre GE-2.3; local rc=$?; [ $rc -eq 1 ] || return $rc
  has_value ENT_PROJECT_REPAIR_TENANT_APP || return 1
  local ent n
  ent="$(v ENT_PROJECT_REPAIR_TENANT_APP)"
  case "$ent" in "projects/$(v GEMINI_PROJECT)/locations/global/entitlements/"*) ;; *) return 1;; esac
  _p19_ent_has "$ent" "$(_p19_repair_filter)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  # one entitlement, one name: a second ent-project-repair-* on the project is never done (R2-19-01)
  n="$(_p19_repair_ids | grep -c .)"
  [ "$n" -le 1 ]
}
_p19_ent_yaml() {   # the page's heredoc (assets/ge-2.3-tenant-app-entitlement.yaml), its four names rendered
  local a="$AGP_HOME/assets/ge-2.3-tenant-app-entitlement.yaml" t n k val out
  [ -f "$a" ] || { echo "STOP: $a is missing" >&2; return 1; }
  t="$(cat "$a")"
  for n in GEMINI_PROJECT GRP_PLATFORM_OWNERS SA_2_ADMIN SECOND_HUMAN_EMAIL; do
    k="\${$n}"; val="$(v "$n")"; out=""
    # literal split and join: no pattern or replacement syntax, the same in bash 3.2 and 5
    while case "$t" in *"$k"*) true;; *) false;; esac; do out="$out${t%%"$k"*}$val"; t="${t#*"$k"}"; done
    t="$out$t"
  done
  case "$t" in *'${'*) echo "STOP: $a holds a name this step does not render" >&2; return 1;; esac
  printf '%s\n' "$t"
}
s_GE_2_3_apply() {
  local p bp ids f full y
  p="$(v GEMINI_PROJECT)"; bp="$(v CICD_PROJECT)"
  _p19_show gcloud pam entitlements list --billing-project="$bp" --project="$p" --location=global --format='value(name)'
  if _p19_live; then ids="$(_p19_repair_ids)"; echo "${ids:-none yet}"; else ids=""; fi
  if [ "$(printf '%s\n' "$ids" | grep -c .)" -gt 1 ]; then echo "STOP: more than one ent-project-repair-* on $p: one entitlement, one name (R2-19-01)"; return 1; fi
  case "$ids" in
    ent-project-repair-gemini)
      echo "FM-6.2 ran first under its heading's name: no second entitlement is created. Raise the rename against file 17 (section 8)"
      echo "and note the deviation in BD-19-1."
      pset ENT_PROJECT_REPAIR_TENANT_APP "projects/$p/locations/global/entitlements/ent-project-repair-gemini"; return $?;;
    ent-project-repair-tenant-app)
      echo "ent-project-repair-tenant-app exists: read back, not created"
      pset ENT_PROJECT_REPAIR_TENANT_APP "projects/$p/locations/global/entitlements/ent-project-repair-tenant-app"; return $?;;
  esac
  full="projects/$p/locations/global/entitlements/ent-project-repair-tenant-app"
  if _p19_live && has_value ENT_PROJECT_REPAIR_TENANT_APP && [ "$(v ENT_PROJECT_REPAIR_TENANT_APP)" != "$full" ]; then
    echo "STOP: ENT_PROJECT_REPAIR_TENANT_APP already holds '$(v ENT_PROJECT_REPAIR_TENANT_APP)', which the list above does not show on $p."
    echo "  Nothing is created: correct the value (penv_set --force with a build-log line) or find the entitlement it names (17 FM-6.2)"
    return 1
  fi
  _p19_mkdir || return 1
  f="$(_p19_file GE-2.3 ent-project-repair-tenant-app yaml)"
  y="$(_p19_ent_yaml)" || return 1
  printf '%s\n' "$y" | xw "$f" 644 || return 1
  x gcloud pam entitlements create ent-project-repair-tenant-app --billing-project="$bp" --project="$p" --location=global --entitlement-file="$f" || return 1
  pset ENT_PROJECT_REPAIR_TENANT_APP "$full" || return 1
  _p19_grant ENT_PROJECT_REPAIR_TENANT_APP 1800s "setup 19 GE-2.3 one-grant test" || return 1
  _p19_revoke "GE-2.3 test done" || return 1
  _p19_show gcloud pam grants search --entitlement="$full" --caller-relationship=had-created --filter="name=<grant> AND (state=REVOKED OR state=ENDED)" --billing-project="$bp" --format='value(name)'
  if _p19_live; then
    _p19_ended ENT_PROJECT_REPAIR_TENANT_APP "$P19_GRANT" && echo "test grant REVOKED or ENDED" \
      || { echo "STOP: the test grant $P19_GRANT does not read REVOKED or ENDED"; return 1; }
  fi
  ev GE-2.3 ent-project-repair-tenant-app E-06 4.1.3 "build-log:ge-baseline/$(basename "$f")" "$f"
}

step GE-2.4 AUTO "Enable the additive services, never disable" --removes --needs "GEMINI_PROJECT ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR"
P19_ADDITIVE="modelarmor.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudquotas.googleapis.com"
s_GE_2_4_check() {
  _p19_pre GE-2.4; local rc=$?; [ $rc -eq 1 ] || return $rc
  local s miss=0
  for s in $P19_ADDITIVE; do    # every service is read, so the answer covers all four
    nonempty r gcloud services list --enabled --project="$(v GEMINI_PROJECT)" --filter="config.name=$s" --format='value(config.name)'; rc=$?
    _p19_acc $rc || return $?
  done
  return $miss
}
s_GE_2_4_apply() {
  local p before after gone rc=0
  p="$(v GEMINI_PROJECT)"
  _p19_mkdir || return 1
  _p19_grant ENT_PROJECT_REPAIR_TENANT_APP 3600s "setup 19 GE-2.4 additive services" || return 1
  before="$(_p19_file GE-2.4 services-before json)"
  _p19_out "$before" gcloud services list --enabled --project="$p" --format=json || rc=1
  if [ $rc -eq 0 ]; then
    # shellcheck disable=SC2086
    x gcloud services enable $P19_ADDITIVE --project="$p" || rc=1
  fi
  if [ $rc -eq 0 ]; then
    after="$(_p19_file GE-2.4 services-after json)"
    _p19_out "$after" gcloud services list --enabled --project="$p" --format=json || rc=1
  fi
  _p19_revoke "GE-2.4 done" || rc=1
  [ $rc -eq 0 ] || return 1
  if _p19_live; then
    echo "added:"; comm -13 <(jq -r '.[].config.name' "$before" | sort) <(jq -r '.[].config.name' "$after" | sort)
    gone="$(comm -23 <(jq -r '.[].config.name' "$before" | sort) <(jq -r '.[].config.name' "$after" | sort))"
    [ -z "$gone" ] || { echo "STOP: a service went away: $gone"; return 1; }
  fi
  ev GE-2.4 services-diff E-05 5.2.1 "build-log:ge-baseline/$(basename "$after")" "$after"
}

step GE-2.5 AUTO "Set Essential Contacts" --removes --needs "GEMINI_PROJECT DOMAIN ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR"
_p19_contact() { nonempty r gcloud essential-contacts list --project="$(v GEMINI_PROJECT)" --filter="email=$1" --format='value(name)'; }
s_GE_2_5_check() {
  _p19_pre GE-2.5; local rc=$?; [ $rc -eq 1 ] || return $rc
  local miss=0 c
  for c in platform-security platform-owners; do
    _p19_contact "$c@$(v DOMAIN)"; _p19_acc $? || return $?
  done
  return $miss
}
s_GE_2_5_apply() {
  local p d before rc=0
  p="$(v GEMINI_PROJECT)"; d="$(v DOMAIN)"
  _p19_mkdir || return 1
  _p19_grant ENT_PROJECT_REPAIR_TENANT_APP 1800s "setup 19 GE-2.5 essential contacts" || return 1
  before="$(_p19_file GE-2.5 contacts-before json)"
  _p19_out "$before" gcloud essential-contacts list --project="$p" --format=json || rc=1
  if [ $rc -eq 0 ]; then
    if _p19_live && _p19_contact "platform-security@$d"; then echo "platform-security@$d is already a contact"
    else x gcloud essential-contacts create --email="platform-security@$d" --notification-categories=security,technical --language=en --project="$p" || rc=1; fi
  fi
  if [ $rc -eq 0 ]; then
    if _p19_live && _p19_contact "platform-owners@$d"; then echo "platform-owners@$d is already a contact"
    else x gcloud essential-contacts create --email="platform-owners@$d" --notification-categories=technical --language=en --project="$p" || rc=1; fi
  fi
  _p19_revoke "GE-2.5 done" || rc=1
  [ $rc -eq 0 ] || return 1
  _p19_show gcloud essential-contacts list --project="$p" --format='value(email,notificationCategorySubscriptions)'
  _p19_live && r gcloud essential-contacts list --project="$p" --format='value(email,notificationCategorySubscriptions)'
  ev GE-2.5 essential-contacts E-05 1.3.1 "build-log:ge-baseline/$(basename "$before")" "$before"
}

step GE-2.6 BLOCKED "Import the project into Terraform state" --note "B-01: the factory tenant-app module is not committed (FACTORY_COMMIT, file 17)"
s_GE_2_6_check() { _p19_ck GE-2.6; }
s_GE_2_6_manual() {
  echo "BLOCKED on README B-01: the factory repository's factory/modules/tenant-app (project data or import block, the engine"
  echo "  import, non-authoritative project and engine IAM) and TF_STATE_BUCKET. The run records it BLOCKED and continues."
  echo "When unblocked (CI, factory-apply@): terraform import of the project and the app, prevent_destroy on the app, a plan"
  echo "  that prints 'No changes'; then bd_close BD-19-1 \"terraform import and an empty plan: <plan record>\" \"19 GE-2.6 VERIFY\"."
}

step GE-2.7 AUTO-READ "Run the zero-diff check before the move" --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_GE_2_7_check() { _p19_ck GE-2.7; }
s_GE_2_7_apply() {
  local f rc
  _p19_mkdir || return 1
  _p19_plan "passes on exit 0: the only non-PASS lines are GE-2.1's pending ones (project.parent, project.labels, tags.effective,"
  _p19_plan "  iam.no_human_or_basic_role, budget); a FAIL is a stop, repaired or made a pending line by pull request"
  _p19_zero_diff GE-2.7 zero-diff-before-move; rc=$?
  case $rc in 0) ;; 4) _p19_zero_stop GE-2.7; return $?;; 98) return 98;; *) return 1;; esac
  f="$(_p19_latest GE-2.7-zero-diff-before-move json || printf '<report>')"
  ev GE-2.7 zero-diff-before-move E-05 5.2.1 "build-log:ge-baseline/$(basename "$f")" "$f"
}

# ---------------------------------------------------------------- GE-3 Before and during the move

step GE-3.1 HUMAN "Build the union allow-list of governed services" --needs "GE_INVENTORY_DIR GEMINI_PROJECT CORE_PROJECT BUILD_LOG_DIR"
s_GE_3_1_check() { _p19_ck GE-3.1; }
s_GE_3_1_manual() {
  echo "WHO: the platform owner; the platform owner as Gemini Enterprise admin signs any drop; a second human approves a fallback."
  echo "WHERE: the tenant shell (helpers loaded); the supported-services page in the browser."
  echo "DO: GE-3.1's blocks of setup/19 in order: the governed list and its three terminal assertions (on a STOP, the committed"
  echo "  fallback register/org-policy-governed-services.txt, two humans); enabled, design, union, not-governed lists; the browser"
  echo "  check; keep or drop each enabled governed service outside the design list (30-day assets and request count; a drop is"
  echo "  signed in decisions/<date>-ge-restrict-service-usage-drops.md); allow-list-final with its three assertions."
  echo "  A STOP from any assertion stops the whole of GE-3. GE-3.3 and GE-3.5 read the newest *-GE-3.1-allow-list-final-v*.txt."
  echo "EVIDENCE: evidence_add GE-3.1 allow-list-union E-05 5.2.1 \"build-log:ge-baseline/<final>\" \"\$final\""
  echo "Then: agp-platform done GE-3.1 --note \"final <n> of governed <n>\""
}

step GE-3.2 HUMAN "Commit the union as the folder's allow-list file" --needs "PLATFORM_REPO_DIR FLD_GEMINI_ENTERPRISE BUILD_LOG_DIR"
s_GE_3_2_check() { _p19_ck GE-3.2; }
s_GE_3_2_manual() {
  echo "WHO: the platform owner; the security reviewer (or the second human) reviews: two human reviewers."
  echo "WHERE: the tenant shell; $(v PLATFORM_REPO_DIR)."
  echo "DO: GE-3.2's block of setup/19: save the predecessor, rewrite $P19_RSU_REL from allow-list-final"
  echo "  (name folders/$(v FLD_GEMINI_ENTERPRISE)/policies/gcp.restrictServiceUsage, spec only), branch setup-19-rsu-union, commit,"
  echo "  push, pull request; merge after both reviews; git pull on main (GE-3.5 applies the merged file)."
  echo "VERIFY: the merged file lists exactly allow-list-final; the diff against the predecessor shows only additions and signed drops."
  echo "EVIDENCE: evidence_add GE-3.2 folder-rsu-file E-05 5.2.1 \"repo:$P19_RSU_REL@<commit>\" \"\$p\""
  echo "Then: agp-platform done GE-3.2"
}

# --removes: set-policy with --update-mask=policy.dry_run_spec replaces the whole dry-run spec on the project
step GE-3.3 AUTO "Apply the union as a project-level dry run" --removes --needs "ENT_PLATFORM_POLICY GEMINI_PROJECT CICD_PROJECT BUILD_LOG_DIR"
s_GE_3_3_check() {
  # done when this step's record holds exactly allow-list-final, its 14 days have a start, and the project holds a
  # restrictServiceUsage policy (describe's exit status; the dry-run values are GE-3.3's own record, not a parse)
  _p19_pre GE-3.3; local rc=$?; [ $rc -eq 1 ] || return $rc
  local final y
  exists gcloud org-policies describe gcp.restrictServiceUsage --project="$(v GEMINI_PROJECT)"; rc=$?
  case $rc in 0|1) ;; *) return $rc;; esac
  final="$(_p19_latest GE-3.1-allow-list-final txt)" || return 1
  y="$(_p19_latest GE-3.3-project-rsu-dryrun yaml)" || return 1
  [ -s "$(_p19_gedir)/dryrun-start.txt" ] || return 1
  grep -q '^dryRunSpec:' "$y" || return 1
  [ "$(sed -n 's/^      - //p' "$y" | sort)" = "$(sort "$final")" ] || return 1
  return $rc
}
s_GE_3_3_apply() {
  local p final y before rc=0
  p="$(v GEMINI_PROJECT)"
  final="$(_p19_final)" || return 1
  _p19_mkdir || return 1
  _p19_grant ENT_PLATFORM_POLICY 3600s "setup 19 GE-3.3 project dry run of restrictServiceUsage union" || return 1
  before="$(_p19_file GE-3.3 project-rsu-before json)"
  _p19_out "$before" gcloud org-policies describe gcp.restrictServiceUsage --project="$p" --format=json
  y="$(_p19_file GE-3.3 project-rsu-dryrun yaml)"
  _p19_rsu_yaml "projects/$p" dryRunSpec "$final" | xw "$y" 644 || rc=1
  # the policy file names projects/<GEMINI_PROJECT>; a dry run is written only with --update-mask=policy.dry_run_spec (section 4)
  [ $rc -ne 0 ] || x gcloud org-policies set-policy "$y" --update-mask=policy.dry_run_spec || rc=1
  _p19_revoke "GE-3.3 done" || rc=1
  [ $rc -eq 0 ] || return 1
  date -u +%FT%TZ | xw "$(_p19_gedir)/dryrun-start.txt" 644 || return 1
  _p19_plan "the 14 days of GE-3.4 start now (ge-baseline/dryrun-start.txt); the colleague's test question must still be answered"
  ev GE-3.3 project-rsu-dryrun E-05 5.2.1 "build-log:ge-baseline/$(basename "$y")" "$y"
}

step GE-3.4 AUTO-READ "Wait 14 days and prove zero dry-run denials" --needs "GEMINI_PROJECT BUILD_LOG_DIR"
s_GE_3_4_check() { _p19_ck GE-3.4; }
s_GE_3_4_apply() {
  local p start log f pf days need n c rc=0
  p="$(v GEMINI_PROJECT)"; log="projects/$p/logs/cloudaudit.googleapis.com%2Fpolicy"
  f="$(_p19_file GE-3.4 dryrun-denials json)"
  if ! _p19_live; then
    start="<ge-baseline/dryrun-start.txt>"
    _p19_show gcloud logging read "logName=\"$log\" AND protoPayload.metadata.dryRunResult=\"DENIED\" AND protoPayload.metadata.liveResult=\"ALLOWED\" AND timestamp>=\"$start\"" --project="$p" --format=json
    _p19_show gcloud logging read "logName=\"$log\" AND timestamp>=\"$start\"" --project="$p" --limit=20 --format=json
    _p19_plan "passes only when 14 days or more have elapsed, the positive control holds an entry, and the denial read is empty"
    return 0
  fi
  start="$(cat "$(_p19_gedir)/dryrun-start.txt" 2>/dev/null)" || true
  [ -n "$start" ] || { echo "STOP: ge-baseline/dryrun-start.txt is missing (GE-3.3)"; return 1; }
  days=$(( ( $(date -u +%s) - $(_p19_epoch "$start") ) / 86400 ))
  need=$(_p19_scaled 14)
  echo "days elapsed since $start: $days"
  [ "$days" -ge "$need" ] || { echo "STOP: $days of $need days; read again on day $need or later (resume from GE-3.4)"; return 1; }
  _p19_out "$f" gcloud logging read "logName=\"$log\" AND protoPayload.metadata.dryRunResult=\"DENIED\" AND protoPayload.metadata.liveResult=\"ALLOWED\" AND timestamp>=\"$start\"" --project="$p" --format=json || rc=1
  pf="$(_p19_file GE-3.4 policy-log-positive-control json)"
  _p19_out "$pf" gcloud logging read "logName=\"$log\" AND timestamp>=\"$start\"" --project="$p" --limit=20 --format=json || rc=1
  [ $rc -eq 0 ] || return 1
  n="$(jq 'length' "$f")"; c="$(jq 'length' "$pf")"
  jq -r '.[] | [.timestamp, .protoPayload.serviceName, .protoPayload.methodName, (.protoPayload.authenticationInfo.principalEmail // "-")] | @tsv' "$f" | sort | uniq -c | head -50
  jq -r '.[] | [.timestamp, (.protoPayload.metadata.dryRunResult // "-"), (.protoPayload.metadata.liveResult // "-"), (.protoPayload.metadata.checkedValue // "-")] | @tsv' "$pf"
  echo "denials: $n; positive control entries: $c"
  if [ "$c" -lt 1 ]; then
    echo "STOP: the positive control is empty; a zero means nothing yet. Seed one violation as GE-3.4 says (a governed service"
    echo "  not on allow-list-final, e.g. gcloud services list --available --project=$p --filter=<that service>), wait 10 minutes,"
    echo "  confirm exactly one DENIED/ALLOWED pair for it, record it, then resume from GE-3.4"
    return 1
  fi
  [ "$n" = 0 ] || { echo "STOP: $n dry-run denials: add the service (GE-3.1 new version, GE-3.2), set the dry run again (GE-3.3), restart the 14 days"; return 1; }
  ev GE-3.4 dryrun-zero-denials E-06 5.2.6 "build-log:ge-baseline/$(basename "$f")" "$f" || return 1
  ev GE-3.4 policy-log-positive-control E-06 5.2.6 "build-log:ge-baseline/$(basename "$pf")" "$pf"
}

step GE-3.5 AUTO "Make the folder's live allow-list the union, while the folder is empty" --removes \
  --needs "ENT_PLATFORM_POLICY FLD_GEMINI_ENTERPRISE PLATFORM_REPO_DIR CICD_PROJECT BUILD_LOG_DIR"
s_GE_3_5_check() {
  # done when the merged file applied is exactly allow-list-final, this step recorded the folder's policies after
  # set-policy, and the folder holds a restrictServiceUsage policy (describe's exit status)
  _p19_pre GE-3.5; local rc=$?; [ $rc -eq 1 ] || return $rc
  local final pol
  exists gcloud org-policies describe gcp.restrictServiceUsage --folder="$(v FLD_GEMINI_ENTERPRISE)"; rc=$?
  case $rc in 0|1) ;; *) return $rc;; esac
  final="$(_p19_latest GE-3.1-allow-list-final txt)" || return 1
  pol="$(v PLATFORM_REPO_DIR)/$P19_RSU_REL"
  [ -f "$pol" ] && [ "$(sed -n 's/^      - //p' "$pol" | sort)" = "$(sort "$final")" ] || return 1
  _p19_latest GE-3.5-folder-policies json >/dev/null || return 1
  return $rc
}
s_GE_3_5_apply() {
  local fld pol n final projs rc=0
  fld="$(v FLD_GEMINI_ENTERPRISE)"; pol="$(v PLATFORM_REPO_DIR)/$P19_RSU_REL"
  _p19_mkdir || return 1
  if _p19_live; then
    _p19_committed "$P19_RSU_REL" >/dev/null || return 1
    n="$(grep -cE '^      - ' "$pol")"
    echo "allowedValues in the file to apply: $n"
    if [ "${n:-0}" -lt 20 ] || ! grep -qx '      - discoveryengine.googleapis.com' "$pol"; then
      echo "STOP: GE-3.5 refuses to apply this file (fewer than 20 entries, or discoveryengine.googleapis.com absent); re-run GE-3.1 and GE-3.2"; return 1
    fi
    final="$(_p19_final)" || return 1
    [ "$(sed -n 's/^      - //p' "$pol" | sort)" = "$(sort "$final")" ] || { echo "STOP: the merged file is not exactly $final (GE-3.2)"; return 1; }
    echo "guard OK"
    r gcloud resource-manager folders describe "$fld" --format='value(displayName)' || return 1
    # gcloud projects list takes no scope flag; the filter names the folder
    # the emptiness read decides whether the step may run at all: it is the step's own precondition, so it runs in
    # the check context, as phases 09, 10, 15 and 42 do (gcloud ignores the variable; the offline fakes read it)
    projs="$(AGP_CALL_CONTEXT=check r gcloud projects list --filter="parent.id=$fld" --format='value(projectId)')" || return 1
    [ -z "$projs" ] || { echo "STOP: the folder is not empty ($projs): the live allow-list is set only while it is empty"; return 1; }
  else
    _p19_plan "guard: $P19_RSU_REL merged on main, 20 entries or more, discoveryengine.googleapis.com in it, equal to allow-list-final"
    _p19_show gcloud projects list --filter="parent.id=$fld" --format='value(projectId)'
    _p19_plan "(must print nothing: the folder is empty)"
  fi
  _p19_grant ENT_PLATFORM_POLICY 3600s "setup 19 GE-3.5 folder restrictServiceUsage union" || return 1
  _p19_out "$(_p19_file GE-3.5 folder-rsu-live-before yaml)" gcloud org-policies describe gcp.restrictServiceUsage --folder="$fld" --format=yaml
  # the committed file names folders/<FLD_GEMINI_ENTERPRISE> and carries only spec: no --update-mask (section 4)
  x gcloud org-policies set-policy "$pol" || rc=1
  local lst; lst="$(_p19_file GE-3.5 folder-policies json)"
  [ $rc -ne 0 ] || _p19_out "$lst" gcloud org-policies list --folder="$fld" --format=json || rc=1
  _p19_revoke "GE-3.5 done" || rc=1
  [ $rc -eq 0 ] || return 1
  ev GE-3.5 folder-rsu-live E-05 5.2.1 "build-log:ge-baseline/$(basename "$lst")" "$lst"
}

step GE-3.6 AUTO-READ "Analyse the move" --needs "GEMINI_PROJECT FLD_GEMINI_ENTERPRISE CORE_PROJECT GE_CURRENT_PARENT BUILD_LOG_DIR"
s_GE_3_6_check() { _p19_ck GE-3.6; }
s_GE_3_6_apply() {
  local p fld f g b rc=0
  p="$(v GEMINI_PROJECT)"; fld="$(v FLD_GEMINI_ENTERPRISE)"
  _p19_mkdir || return 1
  f="$(_p19_file GE-3.6 analyze-move json)"
  _p19_out "$f" gcloud asset analyze-move --project="$p" --destination-folder="$fld" --billing-project="$(v CORE_PROJECT)" --format=json || rc=1
  g="$(_p19_file GE-3.6 ancestors-iam json)"
  _p19_out "$g" gcloud projects get-ancestors-iam-policy "$p" --include-deny --format=json || rc=1
  _p19_out "$(_p19_file GE-3.6 dst-deny json)" gcloud iam policies list --attachment-point="cloudresourcemanager.googleapis.com/folders/$fld" --kind=denypolicies --format=json || rc=1
  _p19_show gcloud org-policies list --folder="$fld" --format='value(name)'
  if ! _p19_live; then _p19_plan "passes when analyze-move reports no blocker; every warning and lost binding goes into GE-3.7's table"; return 0; fi
  r gcloud org-policies list --folder="$fld" --format='value(name)' || rc=1
  [ $rc -eq 0 ] || return 1
  b="$(jq '[.. | objects | .blockers? // empty] | flatten | length' "$f")"
  echo "blockers: $b"; echo "warnings:"; jq -r '.. | objects | select(has("warnings")) | .warnings[]?' "$f"
  echo "bindings on the current parent folder chain (lost by the move; GE-3.7's table):"
  jq -r '.[] | select(.type=="folder") | .id as $id | (.policy.bindings // [])[] | .role as $r | .members[] | "folders/\($id)\t\($r)\t\(.)"' "$g"
  case "$(v GE_CURRENT_PARENT)" in organizations/*) echo "GE_CURRENT_PARENT is the organisation: no organisation-level role is lost";; esac
  [ "$b" = 0 ] || { echo "STOP: analyze-move reports $b blockers"; return 1; }
  ev GE-3.6 analyze-move E-06 4.1.3 "build-log:ge-baseline/$(basename "$f")" "$f"
}

step GE-3.7 HUMAN "Decide and make the re-grants for roles the move loses" --needs "GEMINI_PROJECT ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT"
s_GE_3_7_check() { _p19_ck GE-3.7; }
s_GE_3_7_manual() {
  echo "WHO: the platform owner under ENT_PROJECT_REPAIR_TENANT_APP (the second human approves the grant)."
  echo "WHERE: an editor for the table; the tenant shell (helpers loaded) for the grants."
  echo "DO: write ge-baseline/<date>-GE-3.7-lost-roles-v1.md, one row per binding GE-3.6 printed: needed today (GI-5.4), decision"
  echo "  (re-grant on the project / replaced by ent-ge-admin or ent-project-repair-tenant-app / dropped, signed). Re-grants go on"
  echo "  the project, never on the folder: GE-3.7's block of setup/19 per row (grant, save project-iam-before, add-iam-policy-binding"
  echo "  --condition=None, revoke). The decision per binding is a person's: HUMAN."
  echo "VERIFY: every row has a decision; each re-grant reads true in get-iam-policy; every drop is signed."
  echo "EVIDENCE: evidence_add GE-3.7 lost-roles E-06 4.1.3 \"build-log:ge-baseline/<table>\" \"<the table file>\""
  echo "Then: agp-platform done GE-3.7"
}

step GE-3.8 HUMAN "Announce the change window" --sets "GE_CHANGE_NOTICE_DATE"
s_GE_3_8_check() { _p19_ck GE-3.8; }
s_GE_3_8_manual() {
  echo "WHO: the platform owner writes and sends; the IT security desk acknowledges in writing."
  echo "WHERE: the internal channel for Gemini Enterprise users; the paging service's change calendar (file 15)."
  echo "DO: a 2-hour window outside business hours, five business days ahead or more: date and time, brief unavailability,"
  echo "  chats and data stay, whom to contact; to the GI-2.5 licence holders and the helpdesk. Tell the desk: MoveProject on"
  echo "  GEMINI_PROJECT, org-policy writes on fld-gemini-enterprise, projectMover grants, the rollback owner. Name GE-6.6's"
  echo "  grounding change and any GE-6.4 toggle that removes a feature, if already decided."
  echo "RECORD: penv_set --force GE_CHANGE_NOTICE_DATE \"\$(date -u +%F)\"   (on the day the notice is sent)"
  echo "EVIDENCE: notice and acknowledgement as PDF; evidence_add GE-3.8 change-notice E-12 7.1.2 \"interim:<file name>\""
  echo "Then: agp-platform done GE-3.8 --note \"window <date> <time> UTC, notice <date>\""
}

step GE-3.9 AUTO-READ "Re-read the before state at the start of the window" --witness \
  --needs "GEMINI_PROJECT GEMINI_APP_ID GE_CURRENT_PARENT GE_TEST_USER BUILD_LOG_DIR"
s_GE_3_9_check() { _p19_ck GE-3.9; }
s_GE_3_9_apply() {
  local p e a i f rc=0
  p="$(v GEMINI_PROJECT)"
  _p19_mkdir || return 1
  _p19_colleague || return 1
  _p19_plan "the colleague is on the call and asks 'What is Gemini Enterprise?'"
  e="$(_p19_file GE-3.9 engine-before-move json)"; _p19_apiout "$e" "$(_p19_app)" || rc=1
  a="$(_p19_file GE-3.9 app-iam-before-move json)"; _p19_apiout "$a" "$(_p19_app):getIamPolicy" || rc=1
  i="$(_p19_file GE-3.9 project-iam-before-move json)"; _p19_out "$i" gcloud projects get-iam-policy "$p" --format=json || rc=1
  _p19_show gcloud projects describe "$p" --format='value(parent.type,parent.id)'
  _p19_live || return 0
  [ $rc -eq 0 ] || return 1
  r gcloud projects describe "$p" --format='value(parent.type,parent.id)'
  _p19_under "$(v GE_CURRENT_PARENT)" || { echo "STOP: the project is not under GE_CURRENT_PARENT ($(v GE_CURRENT_PARENT))"; return 1; }
  echo "parent: $(v GE_CURRENT_PARENT)"
  for f in "$e" "$a" "$i"; do jq -e '.etag // .name' "$f" >/dev/null 2>&1 || { echo "STOP: $f holds no etag or name"; return 1; }; done
  echo "REVIEW: the colleague ($(v GE_TEST_USER)) reports an answer, without sharing its text"
  ev GE-3.9 before-move-state E-06 4.1.3 "build-log:ge-baseline/$(basename "$e")" "$e"
}

step GE-3.10 AUTO "Move the project under the ent-project-move pair" \
  --needs "ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST FLD_GEMINI_ENTERPRISE GE_CURRENT_PARENT GEMINI_PROJECT PLATFORM_REPO_DIR CICD_PROJECT GE_CHANGE_NOTICE_DATE"
_p19_labels() { jq -r '.labels | to_entries | map("\(.key)=\(.value)") | join(",")' "$(v PLATFORM_REPO_DIR)/$P19_SPEC_REL"; }
s_GE_3_10_check() {
  # done when the project is listed under fld-gemini-enterprise with every label of the manifest (one filtered list)
  _p19_pre GE-3.10; local rc=$?; [ $rc -eq 1 ] || return $rc
  local lf
  lf="$(_p19_label_filter)" || return 1
  case "$lf" in *'<'*) return 1;; esac
  _p19_under "folders/$(v FLD_GEMINI_ENTERPRISE)" "$lf"
}
s_GE_3_10_apply() {
  local p fld labels gs gd rc=0
  p="$(v GEMINI_PROJECT)"; fld="$(v FLD_GEMINI_ENTERPRISE)"
  if _p19_live; then
    ckpt_done GE-3.9 || { echo "STOP: GE-3.9 (the before state, at the start of the announced window) is not done"; return 1; }
    labels="$(_p19_labels)" || { echo "STOP: no labels in $P19_SPEC_REL"; return 1; }
    case "$labels" in ''|*'<'*) echo "STOP: the manifest's labels are empty or hold a placeholder"; return 1;; esac
  else labels="<labels of $P19_SPEC_REL, key=value,...>"; fi
  gs="$(_p19_request ENT_PROJECT_MOVE_SRC 3600s "setup 19 GE-3.10 move GEMINI_PROJECT, announced window")" || return 1
  gd="$(_p19_request ENT_PROJECT_MOVE_DST 3600s "setup 19 GE-3.10 move GEMINI_PROJECT, announced window")" || return 1
  _p19_wait "$gs" || return 1
  _p19_wait "$gd" || return 1
  agp_say "      grants $gs $gd (GE-3.12 revokes them; rollback: a move back within the same grants)"
  x gcloud beta projects move "$p" --folder="$fld" || return 1
  _p19_show gcloud projects describe "$p" --format='value(parent.type,parent.id)'
  _p19_live && r gcloud projects describe "$p" --format='value(parent.type,parent.id)'
  x gcloud projects update "$p" --update-labels="$labels" || rc=1
  [ $rc -eq 0 ] || { agp_say "      the label update was refused: run it under ENT_PROJECT_REPAIR_TENANT_APP with a note (GE-3.10), then resume"; return 1; }
  ev GE-3.10 project-move E-06 4.1.3 "build-log:checkpoints.tsv" "$(_p19_ckpt)"
}

step GE-3.11 AUTO "Verify the app after the move" --witness --removes \
  --needs "GEMINI_PROJECT GEMINI_APP_ID LOGGING_PROJECT LOG_BUCKET_EVIDENCE REGION ENT_PLATFORM_POLICY PLATFORM_REPO_DIR CICD_PROJECT FLD_GEMINI_ENTERPRISE GE_TEST_USER BUILD_LOG_DIR"
_p19_own_rsu() {    # the project holds a restrictServiceUsage policy of its own (GE-3.3's dry run): a filtered list
  nonempty r gcloud org-policies list --project="$(v GEMINI_PROJECT)" --filter="name~/policies/gcp.restrictServiceUsage$" --format='value(name)'
}
s_GE_3_11_check() {
  # done when the after-move zero-diff report is recorded (written only after the delete) and the project holds no
  # restrictServiceUsage policy of its own any more (a filtered list that prints nothing)
  _p19_pre GE-3.11; local rc=$?; [ $rc -eq 1 ] || return $rc
  _p19_zero_ok GE-3.11-zero-diff-after-move || return 1
  _p19_own_rsu; rc=$?
  case $rc in 0) return 1;; 1) return 0;; *) return $rc;; esac
}
s_GE_3_11_apply() {
  local p e final eff before t0 seen own z rc=0
  p="$(v GEMINI_PROJECT)"
  _p19_mkdir || return 1
  _p19_colleague || return 1
  _p19_plan "the colleague asks the test question now and again 10 minutes later"
  final="$(_p19_final)" || return 1
  _p19_show gcloud org-policies describe gcp.restrictServiceUsage --project="$p" --effective --format=json
  e="$(_p19_file GE-3.11 engine-after-move json)"; _p19_apiout "$e" "$(_p19_app)" || return 1
  if _p19_live; then
    t0="$(_p19_ago -15M '-15 minutes')"
  else t0="<15 minutes ago>"; fi
  _p19_show gcloud logging read "protoPayload.serviceName=\"discoveryengine.googleapis.com\" AND protoPayload.methodName:\"StreamAssist\" AND resource.labels.project_id=\"$p\" AND timestamp>=\"$t0\"" \
    --project="$(v LOGGING_PROJECT)" --bucket="$(_p19_bucket)" --location="$(v REGION)" --view=_AllLogs --limit=5 --format='value(timestamp,protoPayload.methodName)'
  if _p19_live; then
    eff="$(r gcloud org-policies describe gcp.restrictServiceUsage --project="$p" --effective --format=json | jq '.spec.rules[0].values.allowedValues | if type == "array" then length else empty end' 2>/dev/null)"
    echo "effective allow-list: ${eff:-?} of $(grep -c . "$final")"
    case "$eff" in
      "$(grep -c . "$final")") ;;
      ''|null) # no list could be read: the folder's own policy (GE-3.5) is then the proof, by describe's exit status
        exists gcloud org-policies describe gcp.restrictServiceUsage --folder="$(v FLD_GEMINI_ENTERPRISE)" \
          || { echo "STOP: no effective allow-list, and fld-gemini-enterprise holds no restrictServiceUsage policy (GE-3.5)"; return 1; }
        echo "REVIEW: the effective allow-list printed no list; read it by hand (GE-3.11 VERIFY) before GE-4";;
      *) echo "STOP: the effective allow-list is not allow-list-final"; return 1;;
    esac
    before="$(_p19_latest GE-3.9-engine-before-move json)" || { echo "STOP: no GE-3.9 engine read"; return 1; }
    diff <(jq -S 'del(.updateTime)' "$before") <(jq -S 'del(.updateTime)' "$e") || { echo "STOP: the engine changed with the move"; return 1; }
    seen="$(r gcloud logging read "protoPayload.serviceName=\"discoveryengine.googleapis.com\" AND protoPayload.methodName:\"StreamAssist\" AND resource.labels.project_id=\"$p\" AND timestamp>=\"$t0\"" \
      --project="$(v LOGGING_PROJECT)" --bucket="$(_p19_bucket)" --location="$(v REGION)" --view=_AllLogs --limit=5 --format='value(timestamp,protoPayload.methodName)')"
    printf '%s\n' "$seen"
    [ -n "$seen" ] || { echo "STOP: no StreamAssist entry in LOGGING_PROJECT in 15 minutes: the colleague asks; resume from GE-3.11 in 10 minutes."; echo "  No answer for the colleague: GE-3.10's rollback move in the same window."; return 1; }
  fi
  # the project's own dry-run policy is deleted once: a resume after a repair (the checker's STOP) finds it gone
  own=1
  if _p19_live; then _p19_own_rsu; case $? in 0) own=1;; 1) own=0;; *) return 1;; esac; fi
  if [ $own = 1 ]; then
    _p19_grant ENT_PLATFORM_POLICY 1800s "setup 19 GE-3.11 remove project dry-run policy after move" || return 1
    x gcloud org-policies delete gcp.restrictServiceUsage --project="$p" || rc=1
    _p19_revoke "GE-3.11 done" || rc=1
    [ $rc -eq 0 ] || return 1
  else echo "the project's own restrictServiceUsage dry run is already deleted"; fi
  _p19_zero_diff GE-3.11 zero-diff-after-move; rc=$?
  case $rc in 0) ;; 4) _p19_zero_stop GE-3.11; return $?;; 98) return 98;; *) return 1;; esac
  z="$(_p19_latest GE-3.11-zero-diff-after-move json || printf '<report>')"
  ev GE-3.11 after-move-verify E-06 5.2.4 "build-log:ge-baseline/$(basename "$z")" "$z"
}

step GE-3.12 AUTO "Close the window and retire the move entitlements" --removes \
  --needs "ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST GE_CURRENT_PARENT FLD_GEMINI_ENTERPRISE CICD_PROJECT BUILD_LOG_DIR"
_p19_ent_state() { _p19_get gcloud pam entitlements describe "$1" --billing-project="$(v CICD_PROJECT)" --format='value(state)'; }
s_GE_3_12_check() {
  _p19_pre GE-3.12; local rc=$?; [ $rc -eq 1 ] || return $rc
  local n
  for n in ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST; do
    exists gcloud pam entitlements describe "$(v "$n")" --billing-project="$(v CICD_PROJECT)"; rc=$?
    case $rc in 1) ;; 0) return 1;; *) return $rc;; esac
  done
  return 0
}
s_GE_3_12_apply() {
  local bp n e g open st i gone vc line rc=0
  bp="$(v CICD_PROJECT)"
  for n in ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST; do
    e="$(v "$n")"
    # every grant on the entitlement (grants list), not GE-3.10's shell variables; only an ACTIVE grant can be revoked
    _p19_show gcloud pam grants list --billing-project="$bp" --entitlement="$e" --filter='state=ACTIVE' --format='value(name)'
    if _p19_live; then
      for g in $(r gcloud pam grants list --billing-project="$bp" --entitlement="$e" --filter='state=ACTIVE' --format='value(name)'); do
        _p19_revoke "GE-3 window closed" "$g" || return 1
      done
      open="$(r gcloud pam grants list --billing-project="$bp" --entitlement="$e" --filter='state=ACTIVE OR state=APPROVAL_AWAITED OR state=SCHEDULED OR state=ACTIVATING' --format='value(name)')"
      [ -z "$open" ] || { echo "STOP: non-terminal grants remain on $n: $open (entitlements delete fails while they exist;"
                          echo "  a grant awaiting approval or scheduled is withdrawn by its requester); then resume from GE-3.12"; return 98; }
    else
      _p19_revoke "GE-3 window closed" "<each ACTIVE grant on $n>"
    fi
  done
  for n in ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST; do
    e="$(v "$n")"
    if _p19_live; then
      st="$(_p19_ent_state "$e")"; rc=$?
      if [ $rc -eq 1 ]; then echo "$n: NOT_FOUND already"; continue; fi
      [ $rc -eq 0 ] || return 1
      if [ "$st" = DELETING ]; then echo "$n: DELETING already; the delete is not run again"; continue; fi
    fi
    x gcloud pam entitlements delete "$e" --billing-project="$bp" --async --format='value(name)' || return 1
  done
  vc="$(v BUILD_LOG_DIR)/variables-changes.tsv"
  line="$(printf '%s\tGEMINI_PROJECT parent\tmoved from %s to folders/%s by 19 GE-3.10; GE_CURRENT_PARENT keeps the pre-move value' "$(date -u +%F)" "$(v GE_CURRENT_PARENT)" "$(v FLD_GEMINI_ENTERPRISE)")"
  if [ -f "$vc" ] && grep -q 'GEMINI_PROJECT parent	moved from' "$vc"; then :
  else { [ -f "$vc" ] && cat "$vc"; printf '%s\n' "$line"; } | xw "$vc" 644 || return 1; fi
  _p19_plan "then reads both entitlements until NOT_FOUND (DELETING meanwhile; up to 10 minutes, else resume the next business day)"
  _p19_plan "send the 'window closed' note to users and the desk"
  if _p19_live; then
    i=0
    while :; do
      gone=0
      for n in ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST; do
        st="$(_p19_ent_state "$(v "$n")")"; rc=$?
        [ $rc -eq 1 ] && { gone=$((gone + 1)); st=NOT_FOUND; }
        echo "$n: $st"
      done
      [ $gone -eq 2 ] && break
      i=$((i + 1))
      if [ $i -ge 20 ]; then
        x checkpoint GE-3.12 PENDING - - "deletes in DELETING, re-read $(date -u +%F)" >/dev/null
        echo "STOP: still DELETING; do not delete again. Resume from GE-3.12 the next business day (the check reads NOT_FOUND)"; return 1
      fi
      _p19_sleep 30
    done
    echo "REVIEW: send the 'window closed' note to users and the desk"
  fi
  ev GE-3.12 move-window-closed E-05 5.2.1 "build-log:checkpoints.tsv" "$(_p19_ckpt)"
}

# ---------------------------------------------------------------- GE-4 Connector constraints, refused provisions, audit

step GE-4.1 CONSOLE "Act on existing data stores outside the future allow-list" --irreversible --witness --removes \
  --needs "GE_INVENTORY_DIR ENT_GE_ADMIN GE_WITNESS"
s_GE_4_1_check() { _p19_ck GE-4.1; }
s_GE_4_1_manual() {
  echo "WHO: the platform owner under ENT_GE_ADMIN (grant first), with GE_WITNESS ($(v GE_WITNESS)) at the screen for every Delete;"
  echo "  each data store's owner agrees in writing first. WHERE: Cloud console > Gemini Enterprise > Data stores."
  echo "DO: per the newest GE_INVENTORY_DIR/*-GI-7.3-datasource-decisions-v*.md row: 'keep' -> the allow-list pull request on"
  echo "  register/gemini-connectors.yaml now; 'remove' -> only with the agreement filed and no agent connected, the witness reads"
  echo "  the display name AND id aloud from the row about to be selected, against the GI-7.3 row; then Delete. One at a time,"
  echo "  the after-list re-read between deletions."
  echo "IRREVERSIBLE: a deleted data store and its index cannot be restored. Without the witness, no Delete is clicked."
  echo "VERIFY: GI-7.2's read into ge-baseline/<date>-GE-4.1-datastores-after-v1.json: every keep row, no remove row, nothing else."
  echo "EVIDENCE: names, ids, witness, times in records/19-people.md; evidence_add GE-4.1 datastore-decisions E-11 6.1.1 (the"
  echo "  datastores-after file as FILE) and GE-4.1 datastore-deletions-witnessed E-11 6.1.1 (records/19-people.md as FILE)."
  echo "Then: agp-platform done GE-4.1 --witness $(v GE_WITNESS)"
}

_p19_constraint_apply() {   # STEP REL CONSTRAINT SLUG: set a merged folder policy file under a fresh ENT_PLATFORM_POLICY grant
  local fld pol commit rc=0
  fld="$(v FLD_GEMINI_ENTERPRISE)"; pol="$(v PLATFORM_REPO_DIR)/$2"
  _p19_mkdir || return 1
  if _p19_live; then
    # the page's "After merge": the file block and its reviewed pull request are a person's; the set waits for them
    commit="$(_p19_committed "$2")" || { echo "  first run $1's file block of setup/19 (write, commit on setup-19-ge-constraints, push), merge, pull; then resume"; return 98; }
    grep -q 'enforcedProjects:' "$pol" || { echo "STOP: $2 has no enforcedProjects parameter"; return 1; }
    cat "$pol"
  else
    commit="<commit>"; _p19_plan "precondition: $2 merged on main (the page's file block and pull request come first)"
  fi
  _p19_grant ENT_PLATFORM_POLICY 3600s "setup 19 $1 $3" || return 1
  _p19_out "$(_p19_file "$1" "$4-live-before" yaml)" gcloud org-policies describe "discoveryengine.managed.$3" --folder="$fld" --format=yaml
  # the file names folders/<FLD_GEMINI_ENTERPRISE> and carries only spec: no --update-mask (section 4)
  x gcloud org-policies set-policy "$pol" || rc=1
  _p19_revoke "$1 done" || rc=1
  [ $rc -eq 0 ] || return 1
  ev "$1" "$5" E-11 6.1.1 "repo:$2@$commit" "$pol"
}

step GE-4.2 AUTO "Write allowedDataSources in its page's enforcedProjects form" --removes \
  --needs "ENT_PLATFORM_POLICY FLD_GEMINI_ENTERPRISE GEMINI_PROJECT GEMINI_PROJECT_NUMBER PLATFORM_REPO_DIR CICD_PROJECT BUILD_LOG_DIR"
_p19_constraint_done() {   # STEP REL CONSTRAINT SLUG PATTERN: the folder holds the constraint's policy (describe's exit status),
                          # the merged file names the project as PATTERN says, and this step recorded the policy it replaced
  local rc pol
  exists gcloud org-policies describe "discoveryengine.managed.$3" --folder="$(v FLD_GEMINI_ENTERPRISE)"; rc=$?
  case $rc in 0|1) ;; *) return $rc;; esac
  pol="$(v PLATFORM_REPO_DIR)/$2"
  [ -f "$pol" ] && grep -qE "$5" "$pol" || return 1
  _p19_latest "$1-$4-live-before" yaml >/dev/null || return 1
  return $rc
}
s_GE_4_2_check() {
  _p19_pre GE-4.2; local rc=$?; [ $rc -eq 1 ] || return $rc
  # the id form, or the number form GE-4.6 switches to when the refusal does not come
  _p19_constraint_done GE-4.2 "$P19_ADS_REL" allowedDataSources ads \
    "^      - projects/($(v GEMINI_PROJECT)|$(v GEMINI_PROJECT_NUMBER))/\$"
}
s_GE_4_2_apply() { _p19_constraint_apply GE-4.2 "$P19_ADS_REL" allowedDataSources ads allowed-data-sources; }

step GE-4.3 AUTO "Write allowedEgressFqdns in its page's enforcedProjects form" --removes \
  --needs "ENT_PLATFORM_POLICY FLD_GEMINI_ENTERPRISE GEMINI_PROJECT GEMINI_PROJECT_NUMBER PLATFORM_REPO_DIR CICD_PROJECT BUILD_LOG_DIR"
s_GE_4_3_check() {
  _p19_pre GE-4.3; local rc=$?; [ $rc -eq 1 ] || return $rc
  _p19_constraint_done GE-4.3 "$P19_AEF_REL" allowedEgressFqdns aef "^      - \"?$(v GEMINI_PROJECT_NUMBER)\"?\$"
}
s_GE_4_3_apply() { _p19_constraint_apply GE-4.3 "$P19_AEF_REL" allowedEgressFqdns aef allowed-egress-fqdns; }

step GE-4.4 AUTO-READ "Read the custom-MCP block and the ACL constraint" --needs "GEMINI_PROJECT FLD_GEMINI_ENTERPRISE BUILD_LOG_DIR"
s_GE_4_4_check() { _p19_ck GE-4.4; }
s_GE_4_4_apply() {
  local m a rc=0
  _p19_mkdir || return 1
  _p19_plan "console (optional, read only): IAM & Admin > Organization Policies, project $(v GEMINI_PROJECT), 'Disable custom MCP server"
  _p19_plan "  connector for Gemini Enterprise': Enforcement On (inherited). Do not click Manage policy."
  m="$(_p19_file GE-4.4 custom-mcp-effective json)"
  _p19_out "$m" gcloud org-policies describe discoveryengine.managed.disableCustomMcpServerConnector --project="$(v GEMINI_PROJECT)" --effective --format=json || rc=1
  a="$(_p19_file GE-4.4 acl-constraint json)"
  _p19_out "$a" gcloud org-policies describe custom.geDataStoreAclRequired --folder="$(v FLD_GEMINI_ENTERPRISE)" --format=json || rc=1
  _p19_live || return 0
  [ $rc -eq 0 ] || return 1
  jq '{live: .spec, dry: .dryRunSpec}' "$a"
  jq -e '[.spec.rules[]?.enforce] | any' "$m" >/dev/null || { echo "STOP: discoveryengine.managed.disableCustomMcpServerConnector is not enforced for the project"; return 1; }
  jq -e '(.dryRunSpec != null) and (([.spec.rules[]?.enforce] | any) | not)' "$a" >/dev/null \
    || { echo "STOP: custom.geDataStoreAclRequired must have a dryRunSpec and no enforcing spec (file 13, P48)"; return 1; }
  ev GE-4.4 mcp-and-acl-constraints E-11 6.1.1 "build-log:ge-baseline/$(basename "$m")" "$m"
}

step GE-4.5 CONSOLE "Create the throwaway app" --needs "ENT_GE_ADMIN GRP_GE_ADMINS GEMINI_PROJECT GEMINI_APP_ID LOGGING_PROJECT REGION" --sets "GE_THROWAWAY_APP_ID"
s_GE_4_5_check() { _p19_ck GE-4.5; }
s_GE_4_5_manual() {
  echo "WHO: the platform owner under ENT_GE_ADMIN (no approval, justification). The grant comes first."
  echo "WHERE: the tenant shell (helpers loaded); Cloud console > Gemini Enterprise > Apps > Create app."
  echo "DO: GE-4.5's first block (pam_grant, pam_active must print ACTIVE, T0). Only then, in the console: type Gemini Enterprise,"
  echo "  name ge-throwaway-<YYYYMMDD>, location eu, company name empty, no data store. Back in the shell, GE-4.5's second"
  echo "  block: the engine list, penv_set GE_THROWAWAY_APP_ID from it, ge-admins@ on agentspaceUser (getIamPolicy merge,"
  echo "  setIamPolicy), the CreateEngine audit read, the grant's createTime, pam_revoke."
  echo "VERIFY: exactly one ge-throwaway- engine; GE_THROWAWAY_APP_ID differs from $(v GEMINI_APP_ID); the CreateEngine entry"
  echo "  names SA_1_ADMIN and falls inside the grant window; the production engine GET is unchanged."
  echo "EVIDENCE: evidence_add GE-4.5 throwaway-app E-05 5.2.2 and GE-4.5 create-engine-under-grant E-06 4.1.3 (setup/19)."
  echo "Then: agp-platform done GE-4.5 --note \"grant <name>\""
}

step GE-4.6 CONSOLE "Prove allowedDataSources by a refused provision" --needs "GE_THROWAWAY_APP_ID ENT_GE_ADMIN"
s_GE_4_6_check() { _p19_ck GE-4.6; }
s_GE_4_6_manual() {
  echo "WHO: the platform owner under ENT_GE_ADMIN. WHERE: Cloud console > Gemini Enterprise > $(v GE_THROWAWAY_APP_ID) >"
  echo "  Connected data stores > New data store."
  echo "DO: a source not in allowedDataSources needing no third-party credential (a Google source not on the list, else the Cloud"
  echo "  Storage import); display name ge-refusal-test, test values only; Create. Record the exact message."
  echo "  If the store is created: delete it at once, switch GE-4.2's enforcedProjects to projects/<GEMINI_PROJECT_NUMBER>/ in a"
  echo "  new commit, re-run GE-4.2's apply under a new grant, retry. Both forms failing is a stop for Tier C (file 20)."
  echo "VERIFY: 'Operation denied by org policy' naming discoveryengine.managed.allowedDataSources; the working form in P48's row."
  echo "EVIDENCE: screencapture -i into ge-baseline/<date>-GE-4.6-refusal-data-source-v1.png;"
  echo "  evidence_add GE-4.6 refused-data-source E-15 5.2.6 \"build-log:ge-baseline/<png>\" \"<the png>\""
  echo "Then: agp-platform done GE-4.6 --note \"form: <id or number>\""
}

step GE-4.7 CONSOLE "Prove allowedEgressFqdns by a refused provision" --removes \
  --needs "GE_THROWAWAY_APP_ID ENT_GE_ADMIN ENT_PLATFORM_POLICY GEMINI_PROJECT PLATFORM_REPO_DIR"
s_GE_4_7_check() { _p19_ck GE-4.7; }
s_GE_4_7_manual() {
  echo "WHO: the platform owner under ENT_GE_ADMIN, plus an ENT_PLATFORM_POLICY grant (the approver named) for 30 minutes."
  echo "WHERE: the tenant shell (helpers loaded); Cloud console > Gemini Enterprise > the throwaway app > New data store."
  echo "DO: GE-4.7's first block: TEST_SOURCE from Google's third-party table on the day (typed), the temporary project policy"
  echo "  (GE-4.6's enforcedProjects form), set-policy with no --update-mask. In the console: a store for TEST_SOURCE with host"
  echo "  ge-egress-test.invalid and placeholder text only; no real credential is ever typed. Then, whatever the outcome, its second"
  echo "  block: delete the project policy, the effective read, revoke. A form that needs a supplier credential: record"
  echo "  'egress refusal not provable without a supplier credential' (section 9, X-GE-10)."
  echo "VERIFY: 'Operation denied by org policy' naming discoveryengine.managed.allowedEgressFqdns, or the not-provable line; the"
  echo "  project policy is gone and the effective list does not contain TEST_SOURCE (null)."
  echo "EVIDENCE: evidence_add GE-4.7 refused-egress E-15 5.2.6 \"build-log:ge-baseline/<png>\" \"<the png or the not-provable read>\"."
  echo "Then: agp-platform done GE-4.7"
}

step GE-4.8 AUTO "Add ADMIN_READ and DATA_READ for discoveryengine on the project" --removes \
  --needs "GEMINI_PROJECT ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR"
P19_AUDIT_JQ='(.auditConfigs // []) as $ac | ($ac | map(select(.service == "discoveryengine.googleapis.com")) | .[0] // {service: "discoveryengine.googleapis.com", auditLogConfigs: []}) as $de | .auditConfigs = ($ac | map(select(.service != "discoveryengine.googleapis.com"))) + [$de | .auditLogConfigs = ((.auditLogConfigs + [{logType: "ADMIN_READ"}, {logType: "DATA_READ"}]) | unique_by(.logType))]'
_p19_audit_ok() {  # discoveryengine's ADMIN_READ and DATA_READ are on the project's policy (filtered reads; both are read)
  local lt miss=0
  for lt in ADMIN_READ DATA_READ; do
    nonempty r gcloud projects get-iam-policy "$(v GEMINI_PROJECT)" --flatten='auditConfigs[].auditLogConfigs[]' \
      --filter="auditConfigs.service=discoveryengine.googleapis.com AND auditConfigs.auditLogConfigs.logType=$lt" \
      --format='value(auditConfigs.auditLogConfigs.logType)'
    _p19_acc $? || return $?
  done
  return $miss
}
s_GE_4_8_check() {
  _p19_pre GE-4.8; local rc=$?; [ $rc -eq 1 ] || return $rc
  _p19_audit_ok
}
s_GE_4_8_apply() {
  local p cur new after rc=0
  p="$(v GEMINI_PROJECT)"
  _p19_mkdir || return 1
  _p19_grant ENT_PROJECT_REPAIR_TENANT_APP 1800s "setup 19 GE-4.8 discoveryengine audit config" || return 1
  cur="$(_p19_file GE-4.8 project-iam-before json)"; new="$(_p19_file GE-4.8 project-iam-new json)"; after="$(_p19_file GE-4.8 project-iam-after json)"
  _p19_out "$cur" gcloud projects get-iam-policy "$p" --format=json || rc=1
  if [ $rc -eq 0 ]; then
    if _p19_live; then
      jq "$P19_AUDIT_JQ" "$cur" | xw "$new" 644 || rc=1
      diff <(jq -S . "$cur") <(jq -S . "$new")
      [ "$(jq -S '.bindings' "$cur")" = "$(jq -S '.bindings' "$new")" ] || { echo "STOP: the new policy's bindings differ from the read"; rc=1; }
    else _p19_plan "would write $new: the read policy, etag kept, discoveryengine ADMIN_READ and DATA_READ merged (jq of GE-4.8)"; fi
  fi
  [ $rc -ne 0 ] || x gcloud projects set-iam-policy "$p" "$new" --format=json >/dev/null || rc=1
  # the policy is read back, not taken from set-iam-policy's output
  [ $rc -ne 0 ] || _p19_out "$after" gcloud projects get-iam-policy "$p" --format=json || rc=1
  _p19_revoke "GE-4.8 done" || rc=1
  [ $rc -eq 0 ] || return 1
  if _p19_live; then
    [ "$(jq -S '.bindings' "$cur")" = "$(jq -S '.bindings' "$after")" ] || { echo "STOP: bindings changed: roll back from $cur (auditConfigs only)"; return 1; }
    _p19_audit_ok || { echo "STOP: the project's policy lacks discoveryengine ADMIN_READ or DATA_READ"; return 1; }
  fi
  ev GE-4.8 discoveryengine-audit-config E-06 5.2.4 "build-log:ge-baseline/$(basename "$after")" "$after"
}

step GE-4.9 AUTO-READ "Verify the admin-read and request entries reach LOGGING_PROJECT" \
  --needs "GEMINI_PROJECT GEMINI_APP_ID LOGGING_PROJECT LOG_BUCKET_EVIDENCE REGION BUILD_LOG_DIR"
s_GE_4_9_check() { _p19_ck GE-4.9; }
s_GE_4_9_apply() {   # two passes, as the page: t0 and the GET now, the colleague's question, the read after 10 minutes
  local p t0f t0 age f flt
  p="$(v GEMINI_PROJECT)"
  _p19_mkdir || return 1
  flt="protoPayload.serviceName=\"discoveryengine.googleapis.com\" AND resource.labels.project_id=\"$p\" AND timestamp>=\"<t0>\""
  if ! _p19_live; then
    _p19_plan "pass 1: t0 written to ge-baseline/<date>-GE-4.9-t0-v<n>.txt; api GET $(_p19_app) (a GetEngine, ADMIN_READ);"
    _p19_plan "  the colleague asks the test question; the step stops: resume from GE-4.9 10 minutes later"
    _p19_plan "pass 2 (10 to 60 minutes after t0):"
    _p19_show gcloud logging read "$flt" --project="$(v LOGGING_PROJECT)" --bucket="$(_p19_bucket)" --location="$(v REGION)" --view=_AllLogs --format=json
    _p19_plan "  passes when a data_access GetEngine entry and a StreamAssist entry are listed"
    return 0
  fi
  t0f="$(_p19_latest GE-4.9-t0 txt)"; t0="$(cat "$t0f" 2>/dev/null)"
  age=-1; [ -z "$t0" ] || age=$(( ( $(date -u +%s) - $(_p19_epoch "$t0") ) / 60 ))
  if [ -z "$t0" ] || [ "$age" -gt 60 ]; then
    t0="$(date -u +%FT%TZ)"
    printf '%s\n' "$t0" | xw "$(_p19_file GE-4.9 t0 txt)" 644 || return 1
    _p19_api GET "$(_p19_app)" >/dev/null || { echo "STOP: the engine GET failed"; return 1; }
    echo "t0 $t0; the engine GET is done. NOW: the colleague asks the test question."
    echo "STOP (expected): resume from GE-4.9 in 10 minutes (within the hour, else a new t0 and GET are taken)"
    return 98
  fi
  [ "$age" -ge "$(_p19_scaled 10)" ] || { echo "STOP: $age minutes since t0 $t0; resume from GE-4.9 when 10 have passed"; return 1; }
  f="$(_p19_file GE-4.9 audit-entries json)"
  flt="protoPayload.serviceName=\"discoveryengine.googleapis.com\" AND resource.labels.project_id=\"$p\" AND timestamp>=\"$t0\""
  _p19_out "$f" gcloud logging read "$flt" --project="$(v LOGGING_PROJECT)" --bucket="$(_p19_bucket)" --location="$(v REGION)" --view=_AllLogs --format=json || return 1
  jq -r '.[] | [.logName, .protoPayload.methodName] | @tsv' "$f" 2>/dev/null | sort | uniq -c
  jq -e '[.[] | select(((.logName // "") | endswith("data_access")) and ((.protoPayload.methodName // "") | endswith("GetEngine")))] | length > 0' "$f" >/dev/null 2>&1 \
    && jq -e '[.[] | select((.protoPayload.methodName // "") | contains("StreamAssist"))] | length > 0' "$f" >/dev/null 2>&1 \
    || { echo "STOP: no data_access GetEngine and StreamAssist pair since $t0: re-read later from GE-4.9 (after an hour, a new t0 and GET)"; return 1; }
  ev GE-4.9 audit-entries-seen E-06 5.2.4 "build-log:ge-baseline/$(basename "$f")" "$f"
}

# ---------------------------------------------------------------- GE-5 Access: grant first, fill, bind, test, then remove

step GE-5.1 AUTO "Prove ent-ge-admin before any standing admin is touched" --removes \
  --needs "ENT_GE_ADMIN GRP_GE_ADMINS SA_1_ADMIN GEMINI_PROJECT GEMINI_APP_ID CICD_PROJECT BUILD_LOG_DIR"
s_GE_5_1_check() {
  _p19_pre GE-5.1; local rc=$?; [ $rc -eq 1 ] || return $rc
  _p19_latest GE-5.1-standing-admins txt >/dev/null
}
s_GE_5_1_apply() {
  local bp j mem f st rc=0
  bp="$(v CICD_PROJECT)"
  _p19_mkdir || return 1
  _p19_show gcloud pam entitlements describe "$(v ENT_GE_ADMIN)" --billing-project="$bp" --format=json
  _p19_show gcloud identity groups memberships check-transitive-membership --group-email="$(v GRP_GE_ADMINS)" --member-email="$(v SA_1_ADMIN)" --format='value(hasMembership)'
  if _p19_live; then
    j="$(r gcloud pam entitlements describe "$(v ENT_GE_ADMIN)" --billing-project="$bp" --format=json)" || return 1
    printf '%s' "$j" | jq '{role: .privilegedAccess.gcpIamAccess.roleBindings[].role, requesters: .eligibleUsers[].principals, approval: (.approvalWorkflow // "none"), max: .maxRequestDuration, justification: (.requesterJustificationConfig != null)}' 2>/dev/null
    _p19_ent_has "$(v ENT_GE_ADMIN)" 'privilegedAccess.gcpIamAccess.roleBindings.role:roles/discoveryengine.agentspaceAdmin AND maxRequestDuration=3600s AND -approvalWorkflow:* AND requesterJustificationConfig:*' \
      || { echo "STOP: ent-ge-admin is not agentspaceAdmin, no approval, 3600s, justification required (SD-19)"; return 1; }
    mem="$(r gcloud identity groups memberships check-transitive-membership --group-email="$(v GRP_GE_ADMINS)" --member-email="$(v SA_1_ADMIN)" --format='value(hasMembership)')"
    case "$mem" in
      True) echo "SA_1_ADMIN is in ge-admins@";;
      False) echo "STOP: SA_1_ADMIN is not in ge-admins@ (hasMembership False)"; return 1;;
      *) echo "REVIEW: hasMembership read '$mem'; the grant request below is refused to anyone outside ge-admins@";;
    esac
  fi
  _p19_grant ENT_GE_ADMIN 3600s "setup 19 GE-5.1 prove ent-ge-admin before removal of standing admins" || return 1
  if _p19_live; then _p19_api GET "$(_p19_app):getIamPolicy" >/dev/null && echo "admin read OK under grant" || rc=1
  else printf '      read: api GET %s:getIamPolicy\n' "$(_p19_app)" >&3; fi
  f="$(_p19_file GE-5.1 standing-admins txt)"
  if _p19_live; then
    r gcloud projects get-iam-policy "$(v GEMINI_PROJECT)" --format=json \
      | jq -r '.bindings[] | select(.role=="roles/discoveryengine.agentspaceAdmin" or .role=="roles/discoveryengine.admin" or .role=="roles/owner" or .role=="roles/editor") | .role as $r | .members[] | "\($r)\t\(.)"' \
      | xw "$f" 644 || rc=1
    cat "$f" 2>/dev/null
  else _p19_show gcloud projects get-iam-policy "$(v GEMINI_PROJECT)" --format=json; _p19_plan "would write $f (standing admin and basic rows)"; fi
  _p19_revoke "GE-5.1 proof done" || rc=1
  if _p19_live && [ -n "$P19_GRANT" ]; then
    _p19_ended ENT_GE_ADMIN "$P19_GRANT" && echo "grant REVOKED or ENDED" \
      || { echo "STOP: the grant $P19_GRANT does not read REVOKED or ENDED; pam_revoke it before GE-5.2"; rc=1; }
  fi
  [ $rc -eq 0 ] || return 1
  ev GE-5.1 ent-ge-admin-proven E-06 4.1.3 "build-log:ge-baseline/$(basename "$f")" "$f"
}

step GE-5.2 HUMAN "Build the ge-users@ member list from its source" --needs "GE_INVENTORY_DIR GEMINI_PROJECT DOMAIN"
s_GE_5_2_check() { _p19_ck GE-5.2; }
s_GE_5_2_manual() {
  echo "WHO: the platform owner; the population decision for unlicensed members is signed as P55 owner."
  echo "WHERE: the tenant shell (helpers loaded). Member lists are personal data: they stay under ge-baseline/restricted/,"
  echo "  and the script never reads or prints them."
  echo "DO: GE-5.2's blocks of setup/19: population A (ASSIGNED licences of GI-2.5), population B (members of project-level"
  echo "  user-role groups and users), the in-B-not-licensed count; decide include (default) or exclude as a whole in"
  echo "  decisions/<date>-ge-users-population.md; the target list; the out-of-domain count."
  echo "VERIFY: target = |A| + the included part of B; out-of-domain 0 or each explained in the decision record."
  echo "EVIDENCE: counts and SHA-256 of the three restricted files in ge-baseline/<date>-GE-5.2-counts-v1.md;"
  echo "  evidence_add GE-5.2 ge-users-population E-06 4.1.3 \"build-log:ge-baseline/<counts>\" \"<the counts file>\""
  echo "Then: agp-platform done GE-5.2 --note \"target count <n>\""
}

step GE-5.3 HUMAN "Fill ge-users@ and count it" --needs "GRP_GE_USERS"
s_GE_5_3_check() { _p19_ck GE-5.3; }
s_GE_5_3_manual() {
  echo "WHO: the platform owner as sa-1-admin@ (a Groups administrator)."
  echo "WHERE: the tenant shell (helpers loaded). HUMAN because each add names a person: run through the script, every"
  echo "  member address would be printed and kept in the committed run log."
  echo "DO: GE-5.3's block of setup/19 on $(v GRP_GE_USERS): labels read, members-before, add the missing members of the GE-5.2"
  echo "  target (failures to restricted/), members-after, the four counts."
  echo "VERIFY: labels include cloudidentity.googleapis.com/groups.security; comm -23 target after prints 0; each failure is a"
  echo "  suspended or deleted account, written in the counts file."
  echo "EVIDENCE: counts and hashes appended to the GE-5.2 counts file; evidence_add GE-5.3 ge-users-filled E-06 4.1.3 with"
  echo "  the counts file as FILE (setup/19)."
  echo "Then: agp-platform done GE-5.3 --note \"members <n>\""
}

step GE-5.4 AUTO "Grant the Restricted User role to ge-users@ on the project" --removes \
  --needs "GEMINI_PROJECT GRP_GE_USERS ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR"
s_GE_5_4_check() {
  _p19_pre GE-5.4; local rc=$?; [ $rc -eq 1 ] || return $rc
  has_binding "group:$(v GRP_GE_USERS)" roles/discoveryengine.agentspaceRestrictedUser gcloud projects get-iam-policy "$(v GEMINI_PROJECT)"
}
s_GE_5_4_apply() {
  local p m before after norm rc=0
  p="$(v GEMINI_PROJECT)"; m="group:$(v GRP_GE_USERS)"
  _p19_mkdir || return 1
  _p19_grant ENT_PROJECT_REPAIR_TENANT_APP 1800s "setup 19 GE-5.4 agentspaceRestrictedUser to ge-users@" || return 1
  before="$(_p19_file GE-5.4 project-iam-before json)"; after="$(_p19_file GE-5.4 project-iam-after json)"
  _p19_out "$before" gcloud projects get-iam-policy "$p" --format=json || rc=1
  if [ $rc -eq 0 ]; then
    x gcloud projects add-iam-policy-binding "$p" --member="$m" --role=roles/discoveryengine.agentspaceRestrictedUser --condition=None --format=none || rc=1
    # the policy is read back, not taken from the command's output
    [ $rc -ne 0 ] || _p19_out "$after" gcloud projects get-iam-policy "$p" --format=json || rc=1
  fi
  _p19_revoke "GE-5.4 done" || rc=1
  [ $rc -eq 0 ] || return 1
  if _p19_live; then
    norm='[.bindings[] | .members -= [$m] | .members |= sort | select(.members | length > 0)] | sort_by(.role, (.condition.title // ""))'
    [ "$(jq -S --arg m "$m" "$norm" "$before")" = "$(jq -S --arg m "$m" "$norm" "$after")" ] || { echo "STOP: a binding other than the new one changed"; return 1; }
    has_binding "$m" roles/discoveryengine.agentspaceRestrictedUser gcloud projects get-iam-policy "$p" || { echo "STOP: the read-back policy lacks the new binding"; return 1; }
  fi
  ev GE-5.4 restricted-user-grant E-06 4.1.3 "build-log:ge-baseline/$(basename "$after")" "$after"
}

step GE-5.5 AUTO "Write the app-level policy, keeping every existing binding" --removes \
  --needs "ENT_GE_ADMIN GEMINI_PROJECT GEMINI_APP_ID GRP_GE_USERS DOMAIN CICD_PROJECT BUILD_LOG_DIR"
s_GE_5_5_check() {
  # done when the app's policy reads (GET's status), this step's posted policy carries ge-users@ on agentspaceUser, and
  # the write was recorded (app-binding-time.txt is written only after setIamPolicy answered 2xx)
  _p19_pre GE-5.5; local rc=$?; [ $rc -eq 1 ] || return $rc
  local new
  _p19_api GET "$(_p19_app):getIamPolicy" >/dev/null; rc=$?
  case $rc in 0|1) ;; *) return $rc;; esac
  [ $rc -eq 0 ] || return 1
  [ -s "$(_p19_gedir)/app-binding-time.txt" ] || return 1
  new="$(_p19_latest GE-5.5-app-iam-new json)" || return 1
  jq -e --arg u "group:$(v GRP_GE_USERS)" '[.policy.bindings[]? | select(.role == "roles/discoveryengine.agentspaceUser") | .members[]] | index($u) != null' "$new" >/dev/null 2>&1
}
s_GE_5_5_apply() {
  local cur new after b eb addb out lost rc=0
  b="ge-builders@$(v DOMAIN)"
  _p19_mkdir || return 1
  _p19_show gcloud identity groups describe "$b" --format='value(name)'
  if _p19_live; then
    _p19_get gcloud identity groups describe "$b" --format='value(name)' >/dev/null; eb=$?
    case $eb in
      0) addb=true;;
      1) addb=false; _p19_pending GE-5.5 "group:$b" "add ge-builders@ to app-level agentspaceUser when the group factory creates it" || return 1;;
      *) return 1;;
    esac
  else addb="<true if ge-builders@ exists, else a PENDING row in rerun-index.tsv>"; fi
  _p19_grant ENT_GE_ADMIN 3600s "setup 19 GE-5.5 app-level agentspaceUser to ge-users@" || return 1
  cur="$(_p19_file GE-5.5 app-iam-before json)"; new="$(_p19_file GE-5.5 app-iam-new json)"; after="$(_p19_file GE-5.5 app-iam-after json)"
  _p19_apiout "$cur" "$(_p19_app):getIamPolicy" || rc=1
  if [ $rc -eq 0 ]; then
    if _p19_live; then
      jq --arg u "group:$(v GRP_GE_USERS)" --arg b "group:$b" --argjson addb "$addb" '{policy: {etag: .etag, bindings: ((.bindings // []) as $bs | ($bs | map(select(.role != "roles/discoveryengine.agentspaceUser"))) + [{role: "roles/discoveryengine.agentspaceUser", members: ((($bs | map(select(.role == "roles/discoveryengine.agentspaceUser")) | .[0].members) // []) + [$u] + (if $addb then [$b] else [] end) | unique)}])}}' "$cur" \
        | xw "$new" 644 || rc=1
      diff <(jq -S '.bindings // []' "$cur") <(jq -S '.policy.bindings' "$new")
    else _p19_plan "would write $new: every existing binding kept, ge-users@ (and ge-builders@ if it exists) added on agentspaceUser, etag kept"; fi
  fi
  if [ $rc -eq 0 ]; then
    out="$(_p19_api POST "$(_p19_app):setIamPolicy" "$new")" || rc=1
    [ $rc -ne 0 ] || ! _p19_live || printf '%s\n' "$out" | xw "$after" 644 || rc=1
  fi
  [ $rc -ne 0 ] || date -u +%FT%TZ | xw "$(_p19_gedir)/app-binding-time.txt" 644 || rc=1
  _p19_revoke "GE-5.5 done" || rc=1
  [ $rc -eq 0 ] || return 1
  if _p19_live; then
    lost="$(comm -23 <(jq -r '(.bindings // [])[] | .role as $r | .members[] | "\($r) \(.)"' "$cur" | sort) <(jq -r '.bindings[] | .role as $r | .members[] | "\($r) \(.)"' "$after" | sort))"
    [ -z "$lost" ] || { echo "STOP: members lost by the write (roll back from $cur with the new etag): $lost"; return 1; }
    if jq -e '.bindings | type == "array"' "$after" >/dev/null 2>&1; then
      jq -e --arg u "group:$(v GRP_GE_USERS)" '[.bindings[] | select(.role == "roles/discoveryengine.agentspaceUser") | .members[]] | index($u) != null' "$after" >/dev/null \
        || { echo "STOP: the after policy does not show ge-users@ on agentspaceUser"; return 1; }
    else echo "REVIEW: setIamPolicy returned no bindings; read $(_p19_app):getIamPolicy by hand (GE-5.5 VERIFY)"; fi
  fi
  ev GE-5.5 app-level-binding E-06 4.1.3 "build-log:ge-baseline/$(basename "$after")" "$after"
}

step GE-5.6 HUMAN "Wait for propagation and run the non-admin user test" --needs "GRP_GE_USERS GE_TEST_USER"
s_GE_5_6_check() { _p19_ck GE-5.6; }
s_GE_5_6_manual() {
  echo "WHO: the platform owner; the non-admin colleague performs the test."
  echo "WHERE: the tenant shell (helpers loaded); the colleague's browser."
  echo "DO: GE-5.6's block of setup/19: the colleague's transitive membership of $(v GRP_GE_USERS) (True only if licensed),"
  echo "  minutes since ge-baseline/app-binding-time.txt (15 or more). The colleague signs out and in and asks the test question."
  echo "VERIFY: True; 15 minutes or more; an answer. If no answer and nothing removed yet: GE-5.5's rollback."
  echo "EVIDENCE: the colleague's 'answer received, <time>' in records/19-user-tests.md;"
  echo "  evidence_add GE-5.6 user-test-app-level E-15 5.2.6 \"build-log:records/19-user-tests.md\" \"\$BUILD_LOG_DIR/records/19-user-tests.md\""
  echo "Then: agp-platform done GE-5.6 --witness $(v GE_TEST_USER)"
}

step GE-5.7 AUTO "Grant the viewer role to ge-readers@, if it exists" --removes \
  --needs "GEMINI_PROJECT DOMAIN ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR"
s_GE_5_7_check() {
  _p19_pre GE-5.7; local rc=$?; [ $rc -eq 1 ] || return $rc
  local f; f="$(v BUILD_LOG_DIR)/rerun-index.tsv"
  if [ -f "$f" ] && awk -F'\t' '$2 == "GE-5.7" && $5 == "PENDING" {f=1} END {exit f ? 0 : 1}' "$f"; then return 0; fi
  has_binding "group:ge-readers@$(v DOMAIN)" roles/discoveryengine.viewer gcloud projects get-iam-policy "$(v GEMINI_PROJECT)"
}
s_GE_5_7_apply() {
  local g rc
  g="ge-readers@$(v DOMAIN)"
  _p19_show gcloud identity groups describe "$g" --format='value(name)'
  if _p19_live; then
    _p19_get gcloud identity groups describe "$g" --format='value(name)' >/dev/null; rc=$?
    case $rc in
      1) _p19_pending GE-5.7 "group:$g" "grant roles/discoveryengine.viewer on GEMINI_PROJECT to ge-readers@" || return 1
         ev GE-5.7 readers-grant E-06 4.1.3 "build-log:checkpoints.tsv" "$(_p19_ckpt)"; return $?;;
      0) ;;
      *) return 1;;
    esac
  else _p19_plan "if the group does not exist: a PENDING row in rerun-index.tsv, no grant"; fi
  _p19_grant ENT_PROJECT_REPAIR_TENANT_APP 1800s "setup 19 GE-5.7 viewer to ge-readers@" || return 1
  x gcloud projects add-iam-policy-binding "$(v GEMINI_PROJECT)" --member="group:$g" --role=roles/discoveryengine.viewer --condition=None --format=none; rc=$?
  _p19_revoke "GE-5.7 done" || rc=1
  [ $rc -eq 0 ] || return 1
  ev GE-5.7 readers-grant E-06 4.1.3 "build-log:checkpoints.tsv" "$(_p19_ckpt)"
}

step GE-5.8 HUMAN "Remove project-level user and basic roles, one binding at a time" --removes \
  --needs "GEMINI_PROJECT GEMINI_PROJECT_NUMBER GEMINI_APP_ID ENT_PROJECT_REPAIR_TENANT_APP"
s_GE_5_8_check() { _p19_ck GE-5.8; }
s_GE_5_8_manual() {
  echo "WHO: the platform owner under ENT_PROJECT_REPAIR_TENANT_APP; the non-admin colleague after each removal."
  echo "WHERE: the tenant shell (helpers loaded). Only after GE-5.1 proved the grant. One removal, one test, one wait: a person"
  echo "  paces this step, and the queue names people."
  echo "DO: GE-5.8's first block (the removal queue, Google service agents excluded); review it by eye, delete lines that stay"
  echo "  (reason in the build log). Per line: GE-5.8's second block (grant, project-iam-before-removal, remove-iam-policy-binding,"
  echo "  revoke); wait 15 minutes; the colleague's test question; 30 minutes of helpdesk watch after a user-role removal."
  echo "VERIFY: an answer after each removal and no lost-access ticket; after the last, no human admin or basic role on the project;"
  echo "  the analyze-iam-policy read on engines.setIamPolicy (project-level fallback if the engine name is refused)."
  echo "ROLLBACK: add-iam-policy-binding exactly as the saved before file shows it."
  echo "EVIDENCE: evidence_add GE-5.8 project-level-removals E-06 4.1.3 \"build-log:ge-baseline/<queue>\" \"<the queue file>\"."
  echo "Then: agp-platform done GE-5.8"
}

step GE-5.9 AUTO-READ "Read the final access state against 03 §4 as corrected" \
  --needs "GEMINI_PROJECT GEMINI_APP_ID GRP_GE_USERS GRP_PLATFORM_SECURITY PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_GE_5_9_check() { _p19_ck GE-5.9; }
s_GE_5_9_apply() {
  local p f pj aj bad
  p="$(v GEMINI_PROJECT)"
  _p19_mkdir || return 1
  f="$(_p19_file GE-5.9 access-final md)"
  if ! _p19_live; then
    _p19_show gcloud projects get-iam-policy "$p" --format=json
    printf '      read: api GET %s:getIamPolicy\n      would write %s\n' "$(_p19_app)" "$f" >&3
    _p19_plan "fails on any standing admin or basic role held by a human or group on the project"
    _p19_plan "then the run spec: allowed_human_members = the user/group/domain members on the project plus"
    _p19_plan "  group:$(v GRP_PLATFORM_SECURITY) (GE-7.1), no iam.no_human_or_basic_role pending line; else a STOP for the"
    _p19_plan "  person's pull request (two reviewers), then resume from GE-5.9"
    return 0
  fi
  pj="$(r gcloud projects get-iam-policy "$p" --format=json)" || return 1
  aj="$(_p19_api GET "$(_p19_app):getIamPolicy")" || return 1
  { echo "## project"; printf '%s' "$pj" | jq -r '.bindings[] | .role as $r | .members[] | "- \($r) \(.)"'
    echo "## app"; printf '%s' "$aj" | jq -r '.bindings[]? | .role as $r | .members[] | "- \($r) \(.)"'; } | xw "$f" 644 || return 1
  cat "$f"
  bad="$(printf '%s' "$pj" | jq -r '.bindings[] | select(.role|test("^roles/(discoveryengine\\.(agentspaceUser|user|agentspaceAdmin|admin)|owner|editor)$")) | .members[]' | grep -v 'gserviceaccount.com$')"
  [ -z "$bad" ] || { echo "STOP: standing admin, user or basic roles remain for: $bad"; return 1; }
  _p19_jtest "$pj" '[.bindings[] | select(.role == "roles/discoveryengine.agentspaceRestrictedUser") | .members[]] | index($u) != null' --arg u "group:$(v GRP_GE_USERS)" \
    || { echo "STOP: ge-users@ does not hold agentspaceRestrictedUser on the project (GE-5.4)"; return 1; }
  _p19_jtest "$aj" '[.bindings[]? | select(.role == "roles/discoveryengine.agentspaceUser") | .members[]] | index($u) != null' --arg u "group:$(v GRP_GE_USERS)" \
    || { echo "STOP: ge-users@ does not hold agentspaceUser on the app (GE-5.5)"; return 1; }
  echo "REVIEW: GE-3.7 re-grants carry review dates; the CI identity's discoveryengine.editor is absent (file 20)"
  # the run spec follows the access GE-5 left (17 FM-6.1); the revision is a person's pull request
  local h spec np
  h="$(_p19_file GE-5.9 human-members txt)"; spec="$(v PLATFORM_REPO_DIR)/$P19_SPEC_REL"
  { printf '%s' "$pj" | jq -r '.bindings[] | .members[] | select(test("^(user|group|domain):"))'; echo "group:$(v GRP_PLATFORM_SECURITY)"; } \
    | sort -u | xw "$h" 644 || return 1
  _p19_committed "$P19_SPEC_REL" >/dev/null || return 1
  np="$(jq '[.pending[]? | select(.check == "iam.no_human_or_basic_role")] | length' "$spec" 2>/dev/null)"
  if ! diff <(jq -r '.allowed_human_members[]?' "$spec" | sort -u) "$h" || [ "$np" != 0 ]; then
    echo "STOP: the run spec does not follow GE-5's access yet (diff above; pending iam lines: ${np:-?}). Run GE-5.9's spec block of"
    echo "  setup/19 (allowed_human_members from $h, the iam.no_human_or_basic_role pending line removed), pull request,"
    echo "  two reviewers, merge, git pull on main; then resume from GE-5.9"
    return 98
  fi
  ev GE-5.9 access-final E-06 4.1.3 "build-log:ge-baseline/$(basename "$f")" "$f" || return 1
  ev GE-5.9 spec-human-members E-05 1.3.1 "repo:$P19_SPEC_REL@$(_p19_committed "$P19_SPEC_REL")" "$spec"
}

# ---------------------------------------------------------------- GE-6 Engine and assistant settings, CMEK

step GE-6.1 AUTO-READ "Read the engine and the assistant before any change" --needs "GEMINI_PROJECT GEMINI_APP_ID GE_INVENTORY_DIR BUILD_LOG_DIR"
s_GE_6_1_check() { _p19_ck GE-6.1; }
s_GE_6_1_apply() {
  local e0 a0 inv rc=0
  _p19_mkdir || return 1
  e0="$(_p19_file GE-6.1 engine-before json)"; a0="$(_p19_file GE-6.1 assistant-before json)"
  _p19_apiout "$e0" "$(_p19_app)" || rc=1
  _p19_apiout "$a0" "$(_p19_asst)" || rc=1
  if ! _p19_live; then _p19_plan "diffs against file 05's newest GI-2.2 engine and GI-3.1 assistant reads; a difference is explained before GE-6.3"; return 0; fi
  [ $rc -eq 0 ] || return 1
  jq -e '.name' "$e0" >/dev/null && jq -e '.name' "$a0" >/dev/null || { echo "STOP: the engine or assistant read does not name the app"; return 1; }
  jq '{features, modelConfigs, observabilityConfig, sessionConfig, cmekConfig, agentGatewaySetting}' "$e0"
  # shellcheck disable=SC2012
  inv="$(ls -t "$(v GE_INVENTORY_DIR)"/*-GI-2.2-engine-v*.json 2>/dev/null | head -1)"
  if [ -n "$inv" ] && ! diff <(jq -S '{features, modelConfigs, observabilityConfig, sessionConfig}' "$inv") <(jq -S '{features, modelConfigs, observabilityConfig, sessionConfig}' "$e0"); then
    echo "REVIEW: the engine drifted since the inventory: write ge-baseline/<date>-GE-6.1-drift-since-inventory-v1.md with who changed it (UpdateEngine entries), before GE-6.3"
  fi
  # shellcheck disable=SC2012
  inv="$(ls -t "$(v GE_INVENTORY_DIR)"/*-GI-3.1-assistant-v*.json 2>/dev/null | head -1)"
  if [ -n "$inv" ] && ! diff <(jq -S '.customerPolicy' "$inv") <(jq -S '.customerPolicy' "$a0"); then
    echo "REVIEW: the assistant's customerPolicy drifted since the inventory: record and explain it (UpdateAssistant entries) before GE-6.3"
  fi
  ev GE-6.1 engine-assistant-before E-06 5.2.4 "build-log:ge-baseline/$(basename "$e0")" "$e0"
}

step GE-6.2 HUMAN "Obtain the DPO's signature on prompt and response logging" --needs "PLATFORM_REPO_DIR DPO_CONTACT"
s_GE_6_2_check() { _p19_ck GE-6.2; }
s_GE_6_2_manual() {
  echo "WHO: the platform owner writes; the DPO ($(v DPO_CONTACT)) signs yes or no."
  echo "WHERE: $(v PLATFORM_REPO_DIR)/decisions/; the DPO's signature process (the question was sent five business days ahead)."
  echo "DO: decisions/<date>-ge-sensitive-logging-off.md as GE-6.2 lists: Engine.observabilityConfig.sensitiveLoggingEnabled,"
  echo "  Google's text, the console name, today's value from GE-6.1, proposed false, the reason, the consequence."
  echo "VERIFY: merged with the DPO's signature line and date. If the DPO answers no: GE-6.3 is N/A:"
  echo "  source ~/.platform-env; checkpoint GE-6.3 N/A - - \"DPO refused: decisions/<file>\""
  echo "EVIDENCE: the record (E-12, 7.1.2)."
  echo "Then: agp-platform done GE-6.2 --witness $(v DPO_CONTACT) --note \"repo:decisions/<file>\""
}

step GE-6.3 AUTO "Set sensitiveLoggingEnabled to false" --removes --needs "PLATFORM_REPO_DIR ENT_GE_ADMIN GEMINI_PROJECT GEMINI_APP_ID CICD_PROJECT BUILD_LOG_DIR"
s_GE_6_3_check() {
  _p19_pre GE-6.3; local rc=$?; [ $rc -eq 1 ] || return $rc
  local j
  j="$(_p19_api GET "$(_p19_app)")"; rc=$?
  [ $rc -eq 0 ] || return $rc
  _p19_jtest "$j" '(.name != null) and ((.observabilityConfig.sensitiveLoggingEnabled // false) == false)'
}
s_GE_6_3_apply() {
  local rec b after out obs e0 rc=0
  _p19_mkdir || return 1
  if _p19_live; then
    # shellcheck disable=SC2012
    rec="$(ls -t "$(v PLATFORM_REPO_DIR)"/decisions/*-ge-sensitive-logging-off.md 2>/dev/null | head -1)"
    [ -s "$rec" ] && grep -qi 'signed' "$rec" || {
      echo "STOP: no signed decisions/*-ge-sensitive-logging-off.md (GE-6.2): the DPO signs first; on a no, GE-6.3 is N/A"; return 98; }
    echo "record present and signed: $rec"
    e0="$(_p19_latest GE-6.1-engine-before json)" || { echo "STOP: no GE-6.1 engine read"; return 1; }
    obs="$(jq -c '.observabilityConfig.observabilityEnabled // false' "$e0")"
  else _p19_plan "precondition: decisions/*-ge-sensitive-logging-off.md merged and signed by the DPO"; obs=false; fi
  _p19_grant ENT_GE_ADMIN 1800s "setup 19 GE-6.3 sensitiveLoggingEnabled false, DPO record" || return 1
  b="$(_p19_file GE-6.3 patch-body json)"; after="$(_p19_file GE-6.3 engine-after json)"
  jq -n '{observabilityConfig: {sensitiveLoggingEnabled: false}}' | xw "$b" 644 || rc=1
  if [ $rc -eq 0 ]; then
    out="$(_p19_api PATCH "$(_p19_app)?updateMask=observabilityConfig.sensitiveLoggingEnabled" "$b")" || {
      if _p19_live && printf '%s' "$out" | grep -q INVALID_ARGUMENT; then
        echo "the sub-field mask was refused: writing observabilityConfig whole with observabilityEnabled $obs from GE-6.1"
        b="$(_p19_file GE-6.3 patch-body json)"
        jq -n --argjson o "$obs" '{observabilityConfig: {observabilityEnabled: $o, sensitiveLoggingEnabled: false}}' | xw "$b" 644 || rc=1
        [ $rc -ne 0 ] || out="$(_p19_api PATCH "$(_p19_app)?updateMask=observabilityConfig" "$b")" || rc=1
      else rc=1; fi
    }
    if [ $rc -eq 0 ] && _p19_live; then printf '%s\n' "$out" | xw "$after" 644 || rc=1; fi
  fi
  _p19_revoke "GE-6.3 done" || rc=1
  [ $rc -eq 0 ] || return 1
  if _p19_live; then
    out="$(_p19_api GET "$(_p19_app)")" || return 1
    printf '%s' "$out" | jq '.observabilityConfig'
    _p19_jtest "$out" '(.observabilityConfig.observabilityEnabled // false) == $o' --argjson o "$obs" || { echo "STOP: observabilityEnabled changed"; return 1; }
  fi
  ev GE-6.3 sensitive-logging-off E-12 7.1.2 "build-log:ge-baseline/$(basename "$after")" "$after"
}

step GE-6.4 CONSOLE "Set the Feature Management toggles from the committed mapping" --needs "PLATFORM_REPO_DIR ENT_GE_ADMIN GEMINI_APP_ID"
s_GE_6_4_check() { _p19_ck GE-6.4; }
s_GE_6_4_manual() {
  echo "WHO: the platform owner under ENT_GE_ADMIN; the security reviewer (or the second human) reviews the pull request."
  echo "WHERE: $(v PLATFORM_REPO_DIR); Cloud console > Gemini Enterprise > the app > Configurations > Feature Management."
  echo "DO: commit register/gemini-features.yaml with one row per toggle of GE-6.4's table (value, Engine.features key or"
  echo "  'no API key: quarterly console check'); merge. Toggles removing a feature users have today were in the GE-3.8 notice,"
  echo "  or a new one five business days ahead. Then set each toggle to the file's value and save."
  echo "VERIFY: after 5 minutes, ge_call GET \"\$GE_APP\" | jq -S '.features' equals the file's keys (the yq | jq | diff of"
  echo "  GE-6.4); a dated screenshot per 'no key' row."
  echo "EVIDENCE: evidence_add GE-6.4 feature-toggles E-05 5.2.1 \"repo:register/gemini-features.yaml@<commit>\""
  echo "  \"\$PLATFORM_REPO_DIR/register/gemini-features.yaml\""
  echo "Then: agp-platform done GE-6.4"
}

step GE-6.5 CONSOLE "Branch on the edition" --needs "GE_EDITION"
s_GE_6_5_check() { _p19_ck GE-6.5; }
s_GE_6_5_manual() {
  echo "WHO: the platform owner. WHERE: Cloud console > Gemini Enterprise > the app > Configurations > Assistant tab."
  echo "DO: GE_EDITION is '$(v GE_EDITION)'. Note whether Enable web grounding, Banned phrases and Chat history retention period"
  echo "  are shown (assistant configuration requires the Plus edition)."
  echo "RECORD: Plus and shown: agp-platform done GE-6.5 --note \"Plus: GE-6.6 to GE-6.8 apply\"."
  echo "  Otherwise: decisions/<date>-ge-assistant-settings-unavailable.md (08 R8 fallback; Model Armor compensates), then"
  echo "  source ~/.platform-env; checkpoint GE-6.6 N/A - - \"not Plus\"; checkpoint GE-6.8 N/A - - \"not Plus\"; and"
  echo "  agp-platform done GE-6.5 --note \"not Plus: GE-6.6 and GE-6.8 N/A; R8 fallback\"."
  echo "EVIDENCE: a dated screenshot; evidence_add GE-6.5 edition-branch E-03 1.4.1 \"build-log:checkpoints.tsv\" \"\$BUILD_LOG_DIR/checkpoints.tsv\""
}

step GE-6.6 CONSOLE "Turn grounding off and keep or raise retention" --witness \
  --needs "GE_CHANGE_NOTICE_DATE GE_ROLLBACK_OPERATOR GE_WITNESS GE_RETENTION_CURRENT_DAYS ENT_GE_ADMIN" --sets "GE_RETENTION_TARGET"
s_GE_6_6_check() { _p19_ck GE-6.6; }
s_GE_6_6_manual() {
  echo "WHO: the platform owner under ENT_GE_ADMIN; GE_WITNESS ($(v GE_WITNESS)) at the screen; GE_ROLLBACK_OPERATOR"
  echo "  ($(v GE_ROLLBACK_OPERATOR)) reachable for the hour after. Users notified five business days ahead (GE_CHANGE_NOTICE_DATE)."
  echo "WHERE: the tenant shell; Cloud console > Gemini Enterprise > the app > Configurations > Assistant tab."
  echo "DO: GE-6.6's gate block, then its guard block with the DPO's signed P13 value typed (or none): the guard alone writes"
  echo "  GE_RETENTION_TARGET (--force, read back), today's $(v GE_RETENTION_CURRENT_DAYS) days or a larger P13 value. A STOP line"
  echo "  means nothing is written and nothing is changed in the console."
  echo "  In the tab: web grounding off; retention unchanged or GE_RETENTION_TARGET, no other value; the witness reads both aloud and"
  echo "  confirms nothing else differs from GE-6.1; then Save and publish, the witness watching."
  echo "VERIFY: after 5 minutes the tab shows both values; the assistant GET shows grounding disabled; sessionConfig not lower;"
  echo "  the colleague gets an answer. Witness, values, notice in records/19-people.md; evidence_add GE-6.6 grounding-retention and"
  echo "  GE-6.6 grounding-notice E-12 7.1.2 (setup/19). Then: agp-platform done GE-6.6 --witness $(v GE_WITNESS)"
}

step GE-6.7 BLOCKED "Reduce retention, only after P13 and a notice" --irreversible \
  --note "no signed lower retention: P13 record for R8, works council (HLD 14.1), a notice one retention period ahead"
s_GE_6_7_check() { _p19_ck GE-6.7; }
s_GE_6_7_manual() {
  echo "BLOCKED: needs decisions/<date>-ge-retention-reduction.md (DPO-signed P13 value lower than GE_RETENTION_CURRENT_DAYS),"
  echo "  the works-council path completed, and a user notice sent at least one retention period before. It may never run."
  echo "IRREVERSIBLE when it runs: every chat older than the new value is deleted without warning. Under ENT_GE_ADMIN, with"
  echo "  GE_WITNESS and GE_ROLLBACK_OPERATOR, in the Assistant tab; then penv_set --force GE_RETENTION_CURRENT_DAYS <value>."
}

# --removes: the production write replaces customerPolicy whole (section 4), as GE-7.3 does
step GE-6.8 HUMAN "Test banned phrases on real operator questions, then write them with the other two fields" --removes \
  --needs "PLATFORM_REPO_DIR ENT_GE_ADMIN GE_THROWAWAY_APP_ID"
s_GE_6_8_check() { _p19_ck GE-6.8; }
s_GE_6_8_manual() {
  echo "WHO: the platform owner under ENT_GE_ADMIN; two operator volunteers give at least 50 real questions, with consent."
  echo "WHERE: the tenant shell (helpers loaded); the throwaway app $(v GE_THROWAWAY_APP_ID)'s assistant for the live test."
  echo "  The corpus is personal working data under ge-baseline/restricted/: the script never handles it."
  echo "DO: GE-6.8's first block (the corpus, the per-phrase hit counts from register/gemini-banned-phrases.yaml); remove or"
  echo "  rewrite every phrase with a hit, re-run. The live test on the throwaway app (five corpus questions, one planted phrase)."
  echo "  Then its second block: GET the assistant, change bannedPhrases only (WORD_BOUNDARY_STRING_MATCH), PATCH customerPolicy"
  echo "  whole with update_mask=customerPolicy, revoke. An empty list is a valid outcome."
  echo "VERIFY: zero hits per phrase written; the throwaway app answered five and refused the planted one; the customerPolicy diff"
  echo "  without bannedPhrases prints nothing; the colleague's question is answered."
  echo "EVIDENCE: evidence_add GE-6.8 banned-phrases-tested E-15 5.2.6 \"build-log:ge-baseline/<hits>\" \"<the hits file>\"."
  echo "Then: agp-platform done GE-6.8"
}

step GE-6.9 AUTO-READ "Read the engine and assistant after, and check only intended fields changed" \
  --needs "GEMINI_PROJECT GEMINI_APP_ID BUILD_LOG_DIR"
s_GE_6_9_check() { _p19_ck GE-6.9; }
P19_CHANGED='[($a | keys[]), ($b | keys[])] | unique | map(select($a[.] != $b[.]))'
s_GE_6_9_apply() {
  local e0 a0 e1 a1 ce ca bad rc=0
  _p19_mkdir || return 1
  e1="$(_p19_file GE-6.9 engine-after json)"; a1="$(_p19_file GE-6.9 assistant-after json)"
  _p19_apiout "$e1" "$(_p19_app)" || rc=1
  _p19_apiout "$a1" "$(_p19_asst)" || rc=1
  if ! _p19_live; then _p19_plan "engine: only features, observabilityConfig.sensitiveLoggingEnabled, sessionConfig may differ from GE-6.1;"
    _p19_plan "  assistant: only grounding fields and customerPolicy.bannedPhrases; anything else fails the step"; return 0; fi
  [ $rc -eq 0 ] || return 1
  e0="$(_p19_latest GE-6.1-engine-before json)" && a0="$(_p19_latest GE-6.1-assistant-before json)" || { echo "STOP: no GE-6.1 reads"; return 1; }
  diff <(jq -S 'del(.updateTime)' "$e0") <(jq -S 'del(.updateTime)' "$e1")
  diff <(jq -S 'del(.updateTime)' "$a0") <(jq -S 'del(.updateTime)' "$a1")
  ce="$(jq -rn --slurpfile x "$e0" --slurpfile y "$e1" '$x[0] as $a | $y[0] as $b | '"$P19_CHANGED"' | .[]')"
  bad="$(printf '%s\n' "$ce" | grep -vxE 'updateTime|features|sessionConfig|observabilityConfig' | grep -v '^$' | tr '\n' ' ')"
  jq -en --slurpfile x "$e0" --slurpfile y "$e1" '($x[0].observabilityConfig // {} | del(.sensitiveLoggingEnabled)) == ($y[0].observabilityConfig // {} | del(.sensitiveLoggingEnabled))' >/dev/null \
    || bad="$bad observabilityConfig(other than sensitiveLoggingEnabled)"
  ca="$(jq -rn --slurpfile x "$a0" --slurpfile y "$a1" '$x[0] as $a | $y[0] as $b | '"$P19_CHANGED"' | .[]')"
  bad="$bad $(printf '%s\n' "$ca" | grep -vxE 'updateTime|customerPolicy|.*[Gg]rounding.*' | grep -v '^$' | tr '\n' ' ')"
  jq -en --slurpfile x "$a0" --slurpfile y "$a1" '($x[0].customerPolicy // {} | del(.bannedPhrases)) == ($y[0].customerPolicy // {} | del(.bannedPhrases))' >/dev/null \
    || bad="$bad customerPolicy(other than bannedPhrases)"
  bad="$(printf '%s' "$bad" | tr -s ' ' | sed 's/^ //; s/ $//')"
  [ -z "$bad" ] || { echo "STOP: unintended changes, investigate before GE-6.10: $bad"; return 1; }
  ev GE-6.9 engine-assistant-after E-06 5.2.4 "build-log:ge-baseline/$(basename "$e1")" "$e1"
}

step GE-6.10 HUMAN "Decide the CmekConfig" --needs "PLATFORM_REPO_DIR DPO_CONTACT SECOND_HUMAN_EMAIL KEY_GEMINI_CMEK"
s_GE_6_10_check() { _p19_ck GE-6.10; }
s_GE_6_10_manual() {
  echo "WHO: the platform owner writes; IT security and the DPO sign; the second human co-signs (the key is in KMS_PROJECT)."
  echo "WHERE: $(v PLATFORM_REPO_DIR)/decisions/."
  echo "DO: decisions/<date>-ge-cmekconfig.md with every row of GE-6.10's table (state today, options a/b/c, effect on the"
  echo "  imported app, on new apps, on end-user data, failure domain, no safe rollback, rotation, actor, decision)."
  echo "VERIFY: merged with three signatures and a decision letter."
  echo "RECORD: agp-platform done GE-6.10 --note \"decision <a|b|c>\"   (GE-6.11 to GE-6.13 read the letter from this note;"
  echo "  with (a) they are N/A and read as done)"
  echo "EVIDENCE: the record (E-03; 5.1.1, 1.4.1)."
}

step GE-6.11 AUTO-READ "Check the key, its grants and the notice before registration" \
  --needs "KEY_GEMINI_CMEK KMS_PROJECT GEMINI_PROJECT GEMINI_PROJECT_NUMBER BUILD_LOG_DIR"
s_GE_6_11_check() {
  _p19_pre GE-6.11; local rc=$?; [ $rc -eq 1 ] || return $rc
  [ "$(_p19_cmek_letter)" = a ] && return 5   # decision (a): not registered, the step is not applicable
  return 1
}
s_GE_6_11_apply() {
  local k j mem num d
  k="$(v KEY_GEMINI_CMEK)"; num="$(v GEMINI_PROJECT_NUMBER)"
  _p19_show gcloud kms keys describe "$k" --format=json
  _p19_show gcloud kms keys get-iam-policy "$k" --format=json
  if ! _p19_live; then printf '      read: api GET %s/cmekConfigs\n' "$(_p19_api_base)" >&3
    _p19_plan "decision letter from GE-6.10's checkpoint note; (a) makes GE-6.11 to GE-6.13 N/A"; return 0; fi
  d="$(_p19_cmek_letter)"
  case "$d" in b|c) echo "decision ($d)";; *) echo "STOP: no decision letter on GE-6.10's checkpoint (agp-platform done GE-6.10 --note \"decision <a|b|c>\")"; return 1;; esac
  j="$(r gcloud kms keys describe "$k" --format=json)" || return 1
  printf '%s' "$j" | jq '{purpose, protection: .versionTemplate.protectionLevel, rotationPeriod, primaryState: .primary.state}'
  _p19_jtest "$j" '.purpose == "ENCRYPT_DECRYPT" and .versionTemplate.protectionLevel == "HSM" and (.rotationPeriod == null) and .primary.state == "ENABLED"' \
    || { echo "STOP: the key is not ENCRYPT_DECRYPT, HSM, no rotation period, ENABLED"; return 1; }
  mem="$(r gcloud kms keys get-iam-policy "$k" --format=json | jq -r '.bindings[]? | select(.role=="roles/cloudkms.cryptoKeyEncrypterDecrypter") | .members[]')" || return 1
  printf '%s\n' "$mem"
  printf '%s\n' "$mem" | grep -qx "serviceAccount:service-$num@gcp-sa-discoveryengine.iam.gserviceaccount.com" \
    && printf '%s\n' "$mem" | grep -qx "serviceAccount:service-$num@gs-project-accounts.iam.gserviceaccount.com" \
    || { echo "STOP: a service agent lacks the role: GE-6.11's note (create the agent, then KV-4.3's grants by the key's owner)"; return 1; }
  grep -E 'KV-4\.3' "$(v BUILD_LOG_DIR)/pending.log" "$(v BUILD_LOG_DIR)/rerun-index.tsv" 2>/dev/null
  _p19_api GET "$(_p19_api_base)/cmekConfigs" | jq '.cmekConfigs // []'
  [ "$d" = c ] && echo "REVIEW: decision (c): the user notice is five business days old before GE-6.12"
  echo "REVIEW: file 11's severity 1 key-state alert (KV-7.1) exists"
  ev GE-6.11 cmek-prechecks - 5.1.1 "build-log:checkpoints.tsv" "$(_p19_ckpt)"
}

step GE-6.12 AUTO "Register the CmekConfig" --removes --irreversible \
  --needs "KEY_GEMINI_CMEK ENT_GE_ADMIN GEMINI_PROJECT PLATFORM_REPO_DIR CICD_PROJECT BUILD_LOG_DIR"
s_GE_6_12_check() {
  _p19_pre GE-6.12; local rc=$?; [ $rc -eq 1 ] || return $rc
  [ "$(_p19_cmek_letter)" = a ] && return 5   # decision (a): not registered, the step is not applicable
  local j
  j="$(_p19_api GET "$(_p19_api_base)/cmekConfigs")"; rc=$?
  [ $rc -eq 0 ] || return $rc
  _p19_jtest "$j" '[.cmekConfigs[]? | select(.kmsKey == $k)] | length > 0' --arg k "$(v KEY_GEMINI_CMEK)"
}
s_GE_6_12_apply() {
  local d dflag k b op name i j rc=0
  k="$(v KEY_GEMINI_CMEK)"
  if _p19_live; then
    d="$(_p19_cmek_letter)"
    case "$d" in b) dflag=false;; c) dflag=true;; *) echo "STOP: no decision (b) or (c) on GE-6.10's checkpoint"; return 1;; esac
    ls "$(v PLATFORM_REPO_DIR)"/decisions/*-ge-cmekconfig.md >/dev/null 2>&1 || { echo "STOP: no decisions/*-ge-cmekconfig.md (GE-6.10)"; return 1; }
    ckpt_done GE-6.11 || { echo "STOP: GE-6.11 is not done"; return 1; }
    case "$k" in */locations/europe/keyRings/gemini/cryptoKeys/gemini-cmek) ;; *) echo "STOP: KEY_GEMINI_CMEK does not end in /locations/europe/keyRings/gemini/cryptoKeys/gemini-cmek"; return 1;; esac
  else dflag="<true for decision c, false for b>"; fi
  _p19_mkdir || return 1
  _p19_grant ENT_GE_ADMIN 3600s "setup 19 GE-6.12 register gemini-cmek per decision record" || return 1
  b="$(_p19_file GE-6.12 cmek-body json)"; op="$(_p19_file GE-6.12 cmek-operation json)"
  jq -n --arg k "$k" '{kmsKey: $k}' | xw "$b" 644 || rc=1
  if [ $rc -eq 0 ]; then
    j="$(_p19_api PATCH "$(_p19_api_base)/cmekConfigs/default_cmek_config?set_default=$dflag" "$b")" || rc=1
    if [ $rc -eq 0 ] && _p19_live; then printf '%s\n' "$j" | xw "$op" 644 || rc=1; fi
  fi
  _p19_revoke "GE-6.12 submitted" || rc=1
  [ $rc -eq 0 ] || return 1
  _p19_plan "then reads the operation until done: true with no error (up to 15 minutes)"
  if _p19_live; then
    name="$(jq -r .name "$op")"; echo "operation: $name"; i=0
    while :; do
      j="$(_p19_api GET "$P19_EU_HOST/$name")" || return 1
      printf '%s' "$j" | jq -c '{done, error}'
      _p19_jtest "$j" '.done == true' && break
      i=$((i + 1)); [ $i -lt 30 ] || { echo "STOP: the operation is not done after 15 minutes; resume from GE-6.12 (the check reads the registered key)"; return 1; }
      _p19_sleep 30
    done
    _p19_jtest "$j" '.error == null' || { echo "STOP: the operation ended in error (no unset on the day: a new decision record)"; return 1; }
  fi
  ev GE-6.12 cmekconfig-registered - 5.1.1 "build-log:ge-baseline/$(basename "$op")" "$op"
}

step GE-6.13 AUTO-READ "Verify the key is ready and the app is unchanged" --witness \
  --needs "KEY_GEMINI_CMEK GEMINI_PROJECT GEMINI_APP_ID GE_TEST_USER BUILD_LOG_DIR"
s_GE_6_13_check() {
  _p19_pre GE-6.13; local rc=$?; [ $rc -eq 1 ] || return $rc
  [ "$(_p19_cmek_letter)" = a ] && return 5   # decision (a): not registered, the step is not applicable
  return 1
}
s_GE_6_13_apply() {
  local d j e e0 isdef
  if ! _p19_live; then
    printf '      read: api GET %s/cmekConfigs\n      read: api GET %s\n' "$(_p19_api_base)" "$(_p19_app)" >&3
    _p19_colleague
    _p19_plan "the colleague asks the test question and opens one existing chat; console Settings > CMEK shows the key for eu"
    return 0
  fi
  _p19_colleague || return 1
  d="$(_p19_cmek_letter)"; [ "$d" = c ] && isdef=true || isdef=false
  j="$(_p19_api GET "$(_p19_api_base)/cmekConfigs")" || return 1
  printf '%s' "$j" | jq '.cmekConfigs[]? | {name, kmsKey, state, isDefault}'
  _p19_jtest "$j" '[.cmekConfigs[]? | select(.kmsKey == $k and .state == "ACTIVE" and ((.isDefault // false) == $d))] | length > 0' \
    --arg k "$(v KEY_GEMINI_CMEK)" --argjson d "$isdef" || { echo "STOP: no ACTIVE config with KEY_GEMINI_CMEK and isDefault $isdef"; return 1; }
  e="$(_p19_api GET "$(_p19_app)")" || return 1
  e0="$(_p19_latest GE-6.1-engine-before json)" || { echo "STOP: no GE-6.1 engine read"; return 1; }
  [ "$(printf '%s' "$e" | jq -S '.cmekConfig // "absent"')" = "$(jq -S '.cmekConfig // "absent"' "$e0")" ] \
    || { echo "STOP: the engine's cmekConfig changed since GE-6.1"; return 1; }
  echo "REVIEW: the CMEK tab shows the key for eu; the colleague's answer and an old chat both load"
  ev GE-6.13 cmek-ready - 5.1.1 "build-log:checkpoints.tsv" "$(_p19_ckpt)"
}

# ---------------------------------------------------------------- GE-7 The console Model Armor setting

step GE-7.1 AUTO "Create the content-log bucket and route sanitize logs to it" --removes \
  --needs "GEMINI_PROJECT REGION GRP_PLATFORM_SECURITY ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT BUILD_LOG_DIR"
P19_SAN='resource.type="modelarmor.googleapis.com/SanitizeOperation"'
_p19_excl() {   # the _Default sink of GEMINI_PROJECT carries the exclusion ex-ge-sanitize (a filtered list)
  nonempty r gcloud logging sinks list --project="$(v GEMINI_PROJECT)" --filter="name=_Default AND exclusions.name=ex-ge-sanitize" --format='value(name)'
}
s_GE_7_1_check() {
  # every part is read (filtered lists and describe exit status), so the answer covers the bucket, view, sink and exclusion
  _p19_pre GE-7.1; local rc=$?; [ $rc -eq 1 ] || return $rc
  local p reg miss=0
  p="$(v GEMINI_PROJECT)"; reg="$(v REGION)"
  nonempty r gcloud logging buckets list --location="$reg" --project="$p" \
    --filter="name~/buckets/ge-content-logs$ AND retentionDays=30 AND lifecycleState=ACTIVE" --format='value(name)'
  _p19_acc $? || return $?
  exists gcloud logging views describe ge-sanitize-view --bucket=ge-content-logs --location="$reg" --project="$p"; _p19_acc $? || return $?
  exists gcloud logging sinks describe to-ge-content-logs --project="$p"; _p19_acc $? || return $?
  _p19_excl; _p19_acc $? || return $?
  return $miss
}
s_GE_7_1_apply() {
  local p reg bad rc=0
  p="$(v GEMINI_PROJECT)"; reg="$(v REGION)"
  _p19_grant ENT_PROJECT_REPAIR_TENANT_APP 3600s "setup 19 GE-7.1 ge-content-logs bucket and sink" || return 1
  if _p19_live && exists gcloud logging buckets describe ge-content-logs --location="$reg" --project="$p"; then echo "bucket ge-content-logs exists"
  else x gcloud logging buckets create ge-content-logs --location="$reg" --retention-days=30 --description="Gemini Enterprise Model Armor sanitize entries (content class, 30 days)" --project="$p" || rc=1; fi
  if [ $rc -eq 0 ]; then
    if _p19_live && exists gcloud logging sinks describe to-ge-content-logs --project="$p"; then echo "sink to-ge-content-logs exists"
    else x gcloud logging sinks create to-ge-content-logs "logging.googleapis.com/projects/$p/locations/$reg/buckets/ge-content-logs" --log-filter="$P19_SAN" --project="$p" || rc=1; fi
  fi
  if [ $rc -eq 0 ]; then
    if _p19_live && _p19_excl; then echo "exclusion ex-ge-sanitize exists"
    else x gcloud logging sinks update _Default --add-exclusion="name=ex-ge-sanitize,filter=$P19_SAN" --project="$p" || rc=1; fi
  fi
  if [ $rc -eq 0 ]; then
    if _p19_live && exists gcloud logging views describe ge-sanitize-view --bucket=ge-content-logs --location="$reg" --project="$p"; then echo "view ge-sanitize-view exists"
    else x gcloud logging views create ge-sanitize-view --bucket=ge-content-logs --location="$reg" --log-filter="$P19_SAN" --project="$p" || rc=1; fi
  fi
  [ $rc -ne 0 ] || x gcloud projects add-iam-policy-binding "$p" --member="group:$(v GRP_PLATFORM_SECURITY)" --role=roles/logging.viewAccessor \
    --condition="expression=resource.name == \"projects/$p/locations/$reg/buckets/ge-content-logs/views/ge-sanitize-view\",title=ge-sanitize-view-only" --format=none || rc=1
  _p19_revoke "GE-7.1 done" || rc=1
  [ $rc -eq 0 ] || return 1
  _p19_plan "verify: no logging.viewer, privateLogViewer, logging.admin, owner, editor or viewer binding on the project (BD-19-2's control)"
  if _p19_live; then
    bad="$(r gcloud projects get-iam-policy "$p" --format=json | jq -r '.bindings[] | select(.role | IN("roles/logging.viewer", "roles/logging.privateLogViewer", "roles/logging.admin", "roles/owner", "roles/editor", "roles/viewer")) | "\(.role) \(.members | join(","))"')"
    [ -z "$bad" ] || { echo "STOP: these bindings can read the content bucket around the view (BD-19-2): $bad"; return 1; }
  fi
  ev GE-7.1 ge-content-logs E-06 5.2.4 "build-log:checkpoints.tsv" "$(_p19_ckpt)"
}

step GE-7.2 AUTO "Create the template pair ge-console-standard in eu" --removes \
  --needs "GEMINI_PROJECT ENT_PROJECT_REPAIR_TENANT_APP CICD_PROJECT DEVIATION_REGISTER BUILD_LOG_DIR" --sets "GE_ARMOR_TEMPLATE"
P19_RAI='[{"filterType":"HATE_SPEECH","confidenceLevel":"MEDIUM_AND_ABOVE"},{"filterType":"HARASSMENT","confidenceLevel":"MEDIUM_AND_ABOVE"},{"filterType":"SEXUALLY_EXPLICIT","confidenceLevel":"MEDIUM_AND_ABOVE"},{"filterType":"DANGEROUS","confidenceLevel":"MEDIUM_AND_ABOVE"}]'
_p19_tpl() { exists env "$P19_MA_EU" gcloud model-armor templates describe "$1" --location=eu --project="$(v GEMINI_PROJECT)"; }
_p19_tpl_ok() { # TEMPLATE: GE-7.2's VERIFY as a filtered list: sanitize-logged, not INSPECT_ONLY, both filters enabled, in eu
  nonempty r env "$P19_MA_EU" gcloud model-armor templates list --location=eu --project="$(v GEMINI_PROJECT)" \
    --filter="name~/locations/eu/templates/$1$ AND templateMetadata.logSanitizeOperations=true AND -templateMetadata.enforcementType=INSPECT_ONLY AND filterConfig.piAndJailbreakFilterSettings.filterEnforcement=ENABLED AND filterConfig.maliciousUriFilterSettings.filterEnforcement=ENABLED" \
    --format='value(name)'
}
s_GE_7_2_check() {
  _p19_pre GE-7.2; local rc=$?; [ $rc -eq 1 ] || return $rc
  local t miss=0
  for t in ge-console-standard-prompt ge-console-standard-response; do _p19_tpl_ok "$t"; _p19_acc $? || return $?; done
  [ $miss -eq 0 ] || return 1
  has_value GE_ARMOR_TEMPLATE || return 1
  [ -f "$(v DEVIATION_REGISTER)" ] && grep -q '^| BD-19-2 |' "$(v DEVIATION_REGISTER)"
}
s_GE_7_2_apply() {
  local p t f j row rc=0
  p="$(v GEMINI_PROJECT)"
  _p19_mkdir || return 1
  _p19_grant ENT_PROJECT_REPAIR_TENANT_APP 3600s "setup 19 GE-7.2 ge-console-standard templates eu" || return 1
  for t in ge-console-standard-prompt ge-console-standard-response; do
    if _p19_live && _p19_tpl "$t"; then echo "$t exists"; continue; fi
    x env "$P19_MA_EU" gcloud model-armor templates create "$t" --location=eu --project="$p" \
      --pi-and-jailbreak-filter-settings-enforcement=enabled --pi-and-jailbreak-filter-settings-confidence-level=medium-and-above \
      --malicious-uri-filter-settings-enforcement=enabled --rai-settings-filters="$P19_RAI" --basic-config-filter-enforcement=enabled \
      --template-metadata-log-sanitize-operations || { rc=1; break; }
  done
  [ $rc -ne 0 ] || pset GE_ARMOR_TEMPLATE "projects/$p/locations/eu/templates/ge-console-standard" || rc=1
  _p19_revoke "GE-7.2 done" || rc=1
  [ $rc -eq 0 ] || { agp_say "      a refusal quoting the floor: record it, raise the template to the floor (never lower the floor)"; return 1; }
  row="$(printf '| BD-19-2 | %s | 19 GE-7.1, GE-7.2 | DEV | template sanitize logging on for the Gemini Enterprise pair, against Google advice (enable-model-armor, 2026-09-29: not recommended for Gemini Enterprise apps; exposes content to Private Logs Viewer holders) | %s | 06 section 3.3; 03 section 13 | --template-metadata-log-sanitize-operations on both templates; restricted bucket ge-content-logs, view ge-sanitize-view, viewAccessor for platform-security only | GE-7.1 IAM check: no logging.viewer, privateLogViewer, logging.admin, owner, editor or viewer binding on the project | n/a | second human; DPO informed | a dated decision adopting Google alternative (BigQuery routing or Data Access verdicts) | open |' \
    "$(date -u +%F)" "$p")"
  _p19_plan "row: $row"
  x bd_insert "$row" || return 1
  local fp=""
  for t in ge-console-standard-prompt ge-console-standard-response; do
    f="$(_p19_file GE-7.2 "$t" json)"; [ -n "$fp" ] || fp="$f"
    _p19_out "$f" env "$P19_MA_EU" gcloud model-armor templates describe "$t" --location=eu --project="$p" --format=json || return 1
    if _p19_live; then
      jq '{name, meta: .templateMetadata, et: (.templateMetadata.enforcementType // "absent"), pi: .filterConfig.piAndJailbreakFilterSettings, uri: .filterConfig.maliciousUriFilterSettings}' "$f" 2>/dev/null
      _p19_tpl_ok "$t" || { echo "STOP: $t is not sanitize-logged, INSPECT_AND_BLOCK, both filters enabled, under locations/eu"; return 1; }
    fi
  done
  ev GE-7.2 ge-console-templates E-15 5.2.6 "build-log:ge-baseline/$(basename "$fp")" "$fp"
}

step GE-7.3 AUTO "Turn Model Armor on for the assistant, FAIL_CLOSED" --removes \
  --needs "GE_ARMOR_TEMPLATE ENT_GE_ADMIN GEMINI_PROJECT GEMINI_APP_ID GE_CHANGE_NOTICE_DATE CICD_PROJECT BUILD_LOG_DIR"
P19_MA_OK='.customerPolicy.modelArmorConfig | .failureMode == "FAIL_CLOSED" and .userPromptTemplate == $p and .responseTemplate == $r'
_p19_ma_test() { _p19_jtest "$1" "$P19_MA_OK" --arg p "$(v GE_ARMOR_TEMPLATE)-prompt" --arg r "$(v GE_ARMOR_TEMPLATE)-response"; }
s_GE_7_3_check() {
  # done when the assistant reads (GET's status), this step's PATCH body carries the pair FAIL_CLOSED, and the switch-on
  # time was recorded (written only after the PATCH answered 2xx); GE-7.4 asserts the setting by GET
  _p19_pre GE-7.3; local rc=$?; [ $rc -eq 1 ] || return $rc
  local body
  _p19_api GET "$(_p19_asst)" >/dev/null; rc=$?
  case $rc in 0|1) ;; *) return $rc;; esac
  [ $rc -eq 0 ] || return 1
  [ -s "$(_p19_gedir)/armor-on-time.txt" ] || return 1
  body="$(_p19_latest GE-7.3-customer-policy-body json)" || return 1
  _p19_ma_test "$(cat "$body")"
}
s_GE_7_3_apply() {
  local cur body after out rc=0
  _p19_mkdir || return 1
  _p19_plan "users were told (GE-3.8 or a notice five business days ahead, GE_CHANGE_NOTICE_DATE $(v GE_CHANGE_NOTICE_DATE)) that"
  _p19_plan "  injection-like questions may be refused and an outage of the screen blocks the assistant"
  _p19_grant ENT_GE_ADMIN 1800s "setup 19 GE-7.3 Model Armor FAIL_CLOSED on assistant" || return 1
  cur="$(_p19_file GE-7.3 assistant-before json)"; body="$(_p19_file GE-7.3 customer-policy-body json)"; after="$(_p19_file GE-7.3 assistant-after json)"
  _p19_apiout "$cur" "$(_p19_asst)" || rc=1
  if [ $rc -eq 0 ]; then
    if _p19_live; then
      jq --arg p "$(v GE_ARMOR_TEMPLATE)-prompt" --arg r "$(v GE_ARMOR_TEMPLATE)-response" \
        '{customerPolicy: ((.customerPolicy // {}) | .modelArmorConfig = {userPromptTemplate: $p, responseTemplate: $r, failureMode: "FAIL_CLOSED"})}' "$cur" \
        | xw "$body" 644 || rc=1
    else _p19_plan "would write $body: the read customerPolicy whole, modelArmorConfig = the pair, FAIL_CLOSED"; fi
  fi
  if [ $rc -eq 0 ]; then
    out="$(_p19_api PATCH "$(_p19_asst)?update_mask=customerPolicy" "$body")" || rc=1
    [ $rc -ne 0 ] || ! _p19_live || printf '%s\n' "$out" | xw "$after" 644 || rc=1
  fi
  _p19_revoke "GE-7.3 done" || rc=1
  [ $rc -eq 0 ] || return 1
  date -u +%FT%TZ | xw "$(_p19_gedir)/armor-on-time.txt" 644 || return 1
  if _p19_live; then
    diff <(jq -S '.customerPolicy | del(.modelArmorConfig)' "$cur") <(jq -S '.customerPolicy | del(.modelArmorConfig)' "$after") \
      || { echo "STOP: banned phrases or the data protection policy changed (X-GE-17): GE-7.3's rollback"; return 1; }
    if jq -e '.customerPolicy.modelArmorConfig' "$after" >/dev/null 2>&1; then
      _p19_ma_test "$(cat "$after")" || { echo "STOP: the PATCH answer is not the pair, FAIL_CLOSED: GE-7.3's rollback"; return 1; }
    else echo "REVIEW: the PATCH answer shows no modelArmorConfig; GE-7.4 asserts it by GET"; fi
  fi
  ev GE-7.3 model-armor-on E-15 5.2.6 "build-log:ge-baseline/$(basename "$after")" "$after"
}

step GE-7.4 AUTO-READ "Assert the setting by GET" --needs "GE_ARMOR_TEMPLATE GEMINI_PROJECT GEMINI_APP_ID"
s_GE_7_4_check() { _p19_ck GE-7.4; }
s_GE_7_4_apply() {
  local j
  if ! _p19_live; then printf '      read: api GET %s\n' "$(_p19_asst)" >&3
    _p19_plan "asserts modelArmorConfig: FAIL_CLOSED, the -prompt and -response templates of GE_ARMOR_TEMPLATE"
    _p19_plan "console (read only): the app > Configurations > Assistant > Enable Model Armor on, Block all user interactions"
    return 0; fi
  j="$(_p19_api GET "$(_p19_asst)")" || return 1
  _p19_ma_test "$j" || { echo "STOP: the assistant is not FAIL_CLOSED on the ge-console-standard pair"; return 1; }
  echo "true"
  echo "REVIEW: the console shows the toggle on with Block all user interactions; the unreachable-template test is file 20's"
  ev GE-7.4 fail-closed-asserted E-15 5.2.6 "build-log:checkpoints.tsv" "$(_p19_ckpt)"
}

step GE-7.5 HUMAN "Verify on the sanitize log with three injection prompts" --needs "GEMINI_PROJECT REGION GE_TEST_USER"
s_GE_7_5_check() { _p19_ck GE-7.5; }
s_GE_7_5_manual() {
  echo "WHO: the non-admin colleague sends the prompts; the platform owner reads the log."
  echo "WHERE: the colleague's web app; the tenant shell (helpers loaded). The entries carry prompt text: they go to"
  echo "  ge-baseline/restricted/ and the script never reads them."
  echo "DO: 10 minutes after ge-baseline/armor-on-time.txt, the colleague sends the three Tier C assistant prompts of the"
  echo "  injection suite (wall-e/11 section 6) and one benign question, noting the times. Then GE-7.5's block of setup/19 (the"
  echo "  ge-content-logs read through ge-sanitize-view, the summary, the _Default read)."
  echo "VERIFY: three injection prompts refused, the benign one answered; three MATCH_FOUND rows with an AS| prefix at those"
  echo "  times; the _Default read prints nothing. A refused benign question: GE-7.3's rollback and a template review."
  echo "EVIDENCE: the summary (no payload) and the restricted entries' hash; evidence_add GE-7.5 sanitize-log-verify E-15 5.2.6"
  echo "  \"build-log:ge-baseline/<summary>\" \"<the summary file>\"."
  echo "Then: agp-platform done GE-7.5 --witness $(v GE_TEST_USER)"
}

step GE-7.6 HUMAN "Restrict the payload fields after the first real entries" --needs "GEMINI_PROJECT REGION ENT_PROJECT_REPAIR_TENANT_APP"
s_GE_7_6_check() { _p19_ck GE-7.6; }
s_GE_7_6_manual() {
  echo "WHO: the platform owner under ENT_PROJECT_REPAIR_TENANT_APP (the second human approves the grant)."
  echo "WHERE: the tenant shell (helpers loaded)."
  echo "DO: GE-7.6's block of setup/19: list the jsonPayload paths of the newest restricted GE-7.5 entries; choose the paths that"
  echo "  hold user or model text (a person reads real entries, never guesses: HUMAN); FIELDS typed; then grant, logging buckets"
  echo "  update ge-content-logs --restricted-fields=\"\$FIELDS\" --location=$(v REGION) --project=$(v GEMINI_PROJECT), revoke."
  echo "VERIFY: gcloud logging buckets describe ge-content-logs --location=$(v REGION) --project=$(v GEMINI_PROJECT)"
  echo "  --format='value(restrictedFields)' lists the fields."
  echo "EVIDENCE: evidence_add GE-7.6 restricted-fields E-06 5.2.4 \"build-log:checkpoints.tsv\" \"\$BUILD_LOG_DIR/checkpoints.tsv\"."
  echo "Then: agp-platform done GE-7.6"
}

# ---------------------------------------------------------------- GE-8 Quota, usage and close

step GE-8.1 AUTO-READ "Read the quota values from Cloud Quotas" --needs "GEMINI_PROJECT BUILD_LOG_DIR"
s_GE_8_1_check() { _p19_ck GE-8.1; }
s_GE_8_1_apply() {
  local f g rc=0
  _p19_mkdir || return 1
  f="$(_p19_file GE-8.1 quota-modelarmor json)"; g="$(_p19_file GE-8.1 quota-discoveryengine json)"
  _p19_out "$f" gcloud quotas info list --service=modelarmor.googleapis.com --project="$(v GEMINI_PROJECT)" --format=json || rc=1
  _p19_out "$g" gcloud quotas info list --service=discoveryengine.googleapis.com --project="$(v GEMINI_PROJECT)" --format=json || rc=1
  _p19_live || return 0
  [ $rc -eq 0 ] || return 1
  jq -r '.[] | [.quotaId, .metric, .refreshInterval, (.dimensionsInfos[0].details.value // "-")] | @tsv' "$f"
  jq -r '.[] | [.quotaId, .metric, .refreshInterval, (.dimensionsInfos[0].details.value // "-")] | @tsv' "$g" | head -60
  jq -e 'length > 0' "$f" >/dev/null 2>&1 || { echo "STOP: no Model Armor quota row was read"; return 1; }
  echo "REVIEW: record the 'API queries' per-minute value as read (Google's default is 1,200 QPM per project), and the GE rows"
  ev GE-8.1 quota-values - 5.2.8 "build-log:ge-baseline/$(basename "$f")" "$f"
}

step GE-8.2 AUTO-READ "Measure the consumed rate from Monitoring" --needs "GEMINI_PROJECT BUILD_LOG_DIR"
s_GE_8_2_check() { _p19_ck GE-8.2; }
s_GE_8_2_apply() {
  local p on start end svc flt f fm="" peaks="" rc=0
  p="$(v GEMINI_PROJECT)"
  _p19_mkdir || return 1
  if ! _p19_live; then
    _p19_plan "runs 7 days or more after GE-7.3 (ge-baseline/armor-on-time.txt); per service, a 7-day peak per minute of"
    _p19_plan "  serviceruntime.googleapis.com/quota/rate/net_usage on consumer_quota:"
    printf '      read: api GET https://monitoring.googleapis.com/v3/projects/%s/timeSeries?filter=<metric, consumer_quota, service>&interval...&aggregation.alignmentPeriod=60s&aggregation.perSeriesAligner=ALIGN_SUM\n' "$p" >&3
    return 0
  fi
  on="$(cat "$(_p19_gedir)/armor-on-time.txt" 2>/dev/null)" || true
  [ -n "$on" ] || { echo "STOP: no ge-baseline/armor-on-time.txt (GE-7.3)"; return 1; }
  [ $(( ( $(date -u +%s) - $(_p19_epoch "$on") ) / 86400 )) -ge "$(_p19_scaled 7)" ] || { echo "STOP: run 7 days after GE-7.3 ($on); resume from GE-8.2 then"; return 1; }
  start="$(_p19_ago -7d '-7 days')"; end="$(date -u +%FT%TZ)"
  for svc in modelarmor.googleapis.com discoveryengine.googleapis.com; do
    flt="$(jq -rn --arg s "$svc" '"metric.type=\"serviceruntime.googleapis.com/quota/rate/net_usage\" AND resource.type=\"consumer_quota\" AND resource.labels.service=\"" + $s + "\"" | @uri')"
    f="$(_p19_file GE-8.2 "usage-${svc%%.*}" json)"
    api GET "https://monitoring.googleapis.com/v3/projects/$p/timeSeries?filter=$flt&interval.startTime=$start&interval.endTime=$end&aggregation.alignmentPeriod=60s&aggregation.perSeriesAligner=ALIGN_SUM" | xw "$f" 644 || rc=1
    jq -r '.timeSeries[]? | [.metric.labels.quota_metric, ([.points[].value.int64Value | tonumber] | max)] | @tsv' "$f"
    [ "$svc" = modelarmor.googleapis.com ] && { fm="$f"; peaks="$(jq -r '.timeSeries[]?.metric.labels.quota_metric' "$f" 2>/dev/null)"; }
  done
  [ $rc -eq 0 ] || return 1
  [ -n "$peaks" ] || { echo "STOP: no Model Armor peak was read"; return 1; }
  echo "REVIEW: peak / the GE-8.1 value; above 70 % is a quota-increase request and an alert (HLD 3.4); the ratio goes into GE-8.3"
  ev GE-8.2 quota-usage - 5.2.8 "build-log:ge-baseline/$(basename "$fm")" "$fm"
}

step GE-8.3 HUMAN "Write the quota register row and the standing read" --needs "PLATFORM_REPO_DIR DRILL_CALENDAR BUILD_LOG_DIR" \
  --note "standing part BLOCKED on README B-02 (DRIFT_JOB): quarterly re-read meanwhile"
s_GE_8_3_check() { _p19_ck GE-8.3; }
s_GE_8_3_manual() {
  echo "WHO: the platform owner. WHERE: $(v PLATFORM_REPO_DIR)/register/quota-register.yaml (file 16's path for P31); the build log."
  echo "DO: the first quota row by pull request: GEMINI_PROJECT, Model Armor API queries (GE-8.1), the 7-day peak (GE-8.2), the"
  echo "  Gemini Enterprise rows beside it, alert at 70 %, quarterly review; latency *tbd* (file 20's probe). Then GE-8.3's block"
  echo "  with <first business day of next quarter> typed: row DR-19-1 in DRILL_CALENDAR, committed in the build log (once:"
  echo "  grep '^| DR-19-1 |' first)."
  echo "BLOCKED part: until DRIFT_JOB (B-02), re-run GE-6.9, GE-7.4, GE-5.9 and GE-8.1 on the first business day of each quarter"
  echo "  and on any UpdateEngine, UpdateAssistant or SetIamPolicy alert; checkpoint GE-8.3 BLOCKED - - \"drift job\"."
  echo "VERIFY: the register row merged; grep -c '^| DR-19-1 |' DRILL_CALENDAR prints 1."
  echo "EVIDENCE: evidence_add GE-8.3 quota-register-row E-05 5.2.8 \"repo:register/quota-register.yaml@<commit>\""
  echo "  \"\$PLATFORM_REPO_DIR/register/quota-register.yaml\""
  echo "Then: agp-platform done GE-8.3"
}

step GE-8.4 AUTO "Close the part" \
  --needs "GE_ARMOR_TEMPLATE GE_THROWAWAY_APP_ID ENT_PROJECT_REPAIR_TENANT_APP ENT_GE_ADMIN ENT_PLATFORM_POLICY CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_GE_8_4_check() {
  _p19_pre GE-8.4; local rc=$?; [ $rc -eq 1 ] || return $rc
  _p19_latest GE-8.4-manifest sha256 >/dev/null || return 1
  _p19_zero_ok GE-8.4-zero-diff-final || return 1
  [ "$(git -C "$(v BUILD_LOG_DIR)" ls-files ge-baseline 2>/dev/null | grep -c restricted)" = 0 ]
}
s_GE_8_4_apply() {
  local bld m n e open paths zd rc=0
  bld="$(v BUILD_LOG_DIR)"
  _p19_mkdir || return 1
  for n in ENT_GE_ADMIN ENT_PLATFORM_POLICY ENT_PROJECT_REPAIR_TENANT_APP; do
    e="$(v "$n")"
    _p19_show gcloud pam grants search --entitlement="$e" --caller-relationship=had-created --filter=state=ACTIVE --billing-project="$(v CICD_PROJECT)" --format='value(name)'
    if _p19_live; then
      # a precondition read that decides whether the step may run: the check context, as phases 09, 10, 15 and 42 do
      open="$(AGP_CALL_CONTEXT=check r gcloud pam grants search --entitlement="$e" --caller-relationship=had-created --filter=state=ACTIVE --billing-project="$(v CICD_PROJECT)" --format='value(name)')" || return 1
      [ -z "$open" ] || { echo "STOP: an ACTIVE grant remains on $n: $open (every grant is revoked in its own step)"; return 1; }
    fi
  done
  # the checker decides before anything is committed: a FAIL is the page's stop, never accepted by eye
  _p19_zero_diff GE-8.4 zero-diff-final; zd=$?
  case $zd in 0) ;; 4) _p19_zero_stop GE-8.4; return $?;; 98) return 98;; *) return 1;; esac
  m="$(_p19_file GE-8.4 manifest sha256)"
  if _p19_live; then
    ( cd "$(_p19_gedir)" && find . -type f ! -name '*-GE-8.4-manifest-*' -print0 | sort -z | xargs -0 shasum -a 256 ) | xw "$m" 644 || return 1
  else _p19_plan "would write $m (SHA-256 of every ge-baseline file, restricted ones included)"; fi
  paths=""
  for n in .gitignore ge-baseline records; do [ -e "$bld/$n" ] && paths="$paths $n"; done
  _p19_live || paths=" .gitignore ge-baseline records"
  # shellcheck disable=SC2086
  x git -C "$bld" add $paths || return 1
  if _p19_live && git -C "$bld" diff --cached --name-only | grep -q restricted; then echo "STOP: restricted file staged: git -C $bld reset; check .gitignore (GE-0.3)"; return 1; fi
  if ! _p19_live || ! git -C "$bld" diff --cached --quiet; then x git -C "$bld" commit -q -m "19 GE baseline $(date -u +%F)" || rc=1; fi
  [ $rc -eq 0 ] || return 1
  agp_say "      by hand: upload every file under ge-baseline/restricted/ to EVIDENCE_INTERIM_LOCATION, then delete the local corpus;"
  agp_say "      a build-log line under GE-8.4 names the zero-diff path for BD-19-1 (the row is never edited; it closes at GE-2.6);"
  agp_say "      then: agp-platform sitting end   (sitting_end must print SITTING-END OK)"
  ev GE-8.4 part-closed E-05 5.2.1 "build-log:ge-baseline/$(basename "$m")" "$m"
}
