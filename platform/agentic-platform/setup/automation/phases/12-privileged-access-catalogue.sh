# phases/12-privileged-access-catalogue.sh: setup/12, the Privileged Access Manager catalogue, and
# the end of the organisation bootstrap: the creator's Owner on the five core projects (PA-9.2) and
# the dated organisation exception of 06 OB-3.7 (PA-9.3) are removed once the entitlements that
# replace them are proven.
#
# How the page maps onto the classes:
# - The deterministic setup (API, PAM Admin to platform-owners@, the parser probe, the creates that
#   need no grant test, the registers and re-run lines) is AUTO; the sweeps and compares are AUTO-READ.
# - Every create that is proven by a one-grant test with an approver is HUMAN: the second human
#   approves (T2) in the console, and the test (T1 to T5 with pam/tools/pam.sh) runs in the approval
#   sitting with waits of minutes to hours. The no-approval tests (PA-4.5, PA-5.1) belong to that same
#   sitting and are HUMAN for the same reason.
# - PA-1.5 and PA-2.1 write the files the page carries as heredocs (pam.sh, compare.py, sweep.py,
#   catalogue.py). Their bodies are saved once in assets/ and listed in assets/12.manifest (lib/PHASES.md,
#   "Files copied from a page"); both steps are AUTO, write with xw on the branch setup-12-pam-catalogue,
#   and PA-2.1 runs catalogue.py. The commit, push, review and merge stay PA-2.2, the person's act.
# - A step whose WHO names a second person acting in it (an approver, a reviewer, a mail confirmation) is
#   registered --witness, so its checkpoint names that person; HUMAN where that person performs the step.
# - PA-9.2 and PA-9.3 remove standing privilege and are proven under a grant the second human
#   approves; PA-9.3 also needs the second human's merge of the roster pull request. Both are HUMAN,
#   registered --removes and --witness, and PA-9.3 --irreversible. They come after PA-4.2 and PA-3.6,
#   the steps that prove the entitlements replacing what they remove.
# - After PA-9.3 the platform owner can no longer read the organisation's IAM policy without a grant,
#   so an AUTO step with a DONE checkpoint is not read again.
#
# Helpers are prefixed _p12_ because every phase file is loaded into the same shell.

phase 12 "Privileged Access Manager catalogue" "12-privileged-access-catalogue.md"
requires org "resourcemanager.organizations.get resourcemanager.organizations.getIamPolicy resourcemanager.organizations.setIamPolicy"

# ---------------------------------------------------------------- helpers
_p12_ev_dir() { printf '%s/evidence/12' "$(v BUILD_LOG_DIR)"; }

_p12_mkev() {   # the evidence directory of PA-0.1, made again if a step runs on its own
  local d; d="$(_p12_ev_dir)"
  [ -d "$d" ] && return 0
  x mkdir -p "$d"
}

_p12_read() {   # a read whose output the step uses: shown in plan mode, run in apply mode (3 in plan)
  if [ "$AGP_MODE" != apply ]; then printf '      read: %s\n' "$(agp_quote "$@")" >&3; return 3; fi
  r "$@"
}

_p12_gate() {   # STEP WHY: the page's checkpoint gate; in apply mode a missing DONE stops the step
  ckpt_done "$1" && return 0
  if [ "$AGP_MODE" = apply ]; then agp_say "      STOP: $1 is not DONE - $2; nothing below runs"; return 1; fi
  agp_say "      gate: runs only when $1 is DONE ($2)"
  return 0
}

_p12_ent_desc() {   # ID SCOPE_FLAG: exists-style describe of an entitlement
  exists gcloud pam entitlements describe "$1" "$2" --location=global --billing-project="$(v CICD_PROJECT)" --format='value(name)'
}

_p12_ents_exist() { # ID SCOPE_FLAG [ID SCOPE_FLAG]...: every describe runs; 0 all present, else the worst of 2, 3, 1
  local worst=0 one
  while [ $# -ge 2 ]; do
    _p12_ent_desc "$1" "$2"; one=$?
    case $one in 2) worst=2;; 3) [ $worst = 2 ] || worst=3;; 1) [ $worst != 0 ] || worst=1;; esac
    shift 2
  done
  return $worst
}

_P12_CREATED=0      # set to 1 when _p12_ent_create ran a create in this run (PA-3.5 then waits for propagation)
_p12_sleep() {      # SECONDS: a wait the page prescribes, multiplied by AGP_WAIT_SCALE (a whole number, 1 when unset; 0 in the tests)
  local f="${AGP_WAIT_SCALE:-1}"
  case "$f" in ''|*[!0-9]*) agp_warn "AGP_WAIT_SCALE '$f' is not a whole number; the page's $1 s wait is kept"; f=1;; esac
  [ "$AGP_MODE" = apply ] || { agp_say "      wait: $1 s (the page's propagation wait)"; return 0; }
  [ $(( $1 * f )) -gt 0 ] || return 0
  agp_say "      waiting $(( $1 * f )) s (the page's propagation wait)"
  sleep $(( $1 * f ))
}

_p12_ent_create() { # ID SCOPE_FLAG: gcloud pam entitlements create from the committed file, unless it exists
  # the existence probe is the step's check read, made again just before the create (call context: check)
  if [ "$AGP_MODE" = apply ]; then
    AGP_CALL_CONTEXT=check _p12_ent_desc "$1" "$2"
    case $? in
      0) agp_say "      $1 exists; not created again"; return 0;;
      1) ;;
      *) return 1;;
    esac
  fi
  x gcloud pam entitlements create "$1" "$2" --location=global \
    --entitlement-file="$(v PLATFORM_REPO_DIR)/pam/entitlements/$1.json" --billing-project="$(v CICD_PROJECT)" || return $?
  _P12_CREATED=1
}

_p12_ent_pset() {   # VAR ID SCOPE_FLAG: penv_set VAR to the entitlement's full name
  local n
  if [ "$AGP_MODE" != apply ]; then pset "$1" "<name>"; return 0; fi
  n="$(r gcloud pam entitlements describe "$2" "$3" --location=global --billing-project="$(v CICD_PROJECT)" --format='value(name)')" || return 1
  [ -n "$n" ] || { agp_warn "$2: describe printed no name"; return 1; }
  pset "$1" "$n"
}

_p12_manual_check() {   # STEP [ID SCOPE_FLAG]...: DONE checkpoint, and every entitlement the step creates describes.
  # The reads run first, so a plan shows the state; their errors are shown only when the checkpoint says DONE.
  local step="$1" worst=0 one err msg=""; shift
  if [ "$AGP_OFFLINE" = 1 ]; then ckpt_done "$step"; return $?; fi
  while [ $# -ge 2 ]; do
    if [ -z "$2" ]; then shift 2; continue; fi   # no scope to read (a malformed GE_CURRENT_PARENT; the manual says stop)
    err="$(gcloud pam entitlements describe "$1" "$2" --location=global --billing-project="$(v CICD_PROJECT)" --format='value(name)' 2>&1 >/dev/null)"; one=$?
    if [ $one -ne 0 ]; then
      if printf '%s' "$err" | grep -qiE 'NOT_FOUND|not found|does not exist|404'; then [ $worst = 2 ] || worst=1
      else worst=2; msg="$msg$1: $(printf '%s' "$err" | head -2 | tr '\n' ' ') "; fi
    fi
    shift 2
  done
  ckpt_done "$step" || return 1
  case $worst in
    0) return 0;;
    1) agp_say "      $step has a DONE checkpoint, but an entitlement it creates was not found: run its VERIFY"; return 1;;
    *) agp_say "      $step: $msg"; return 2;;
  esac
}

_p12_say_create() { # ID SCOPE_FLAG [alpha]: the create line a person runs
  local track=""; [ "${3-}" = alpha ] && track="alpha "
  printf '$ gcloud %spam entitlements create %s %s --location=global --entitlement-file=%s --billing-project=%s\n' \
    "$track" "$1" "$2" "$(v PLATFORM_REPO_DIR)/pam/entitlements/$1.json" "$(v CICD_PROJECT)"
}

_p12_say_pset() {   # VAR ID SCOPE_FLAG: the penv_set line a person types
  printf "\$ penv_set %s \"\$(gcloud pam entitlements describe %s %s --location=global --billing-project=%s --format='value(name)')\"\n" \
    "$1" "$2" "$3" "$(v CICD_PROJECT)"
}

_p12_say_pamsh() { printf '$ source %s/pam/tools/pam.sh\n' "$(v PLATFORM_REPO_DIR)"; }

_p12_say_ev() {     # STEP SLUG E-ID TISAX [FILE]: the evidence_add line a person types
  if [ -n "${5-}" ]; then
    printf '$ evidence_add %s %s %s %s "build-log:evidence/12" "%s/%s"\n' "$1" "$2" "$3" "$4" "$(_p12_ev_dir)" "$5"
  else
    printf '$ evidence_add %s %s %s %s "build-log:evidence/12"\n' "$1" "$2" "$3" "$4"
  fi
}

_p12_flag() {       # KIND IDENT: the gcloud scope flag of an index row
  case "$1" in
    organizations) printf -- '--organization=%s' "$2";;
    folders) printf -- '--folder=%s' "$2";;
    projects) printf -- '--project=%s' "$2";;
    *) return 1;;
  esac
}

_p12_parent_flag() {    # the scope flag of GE_CURRENT_PARENT (PA-5.2), empty when it is malformed
  local p; p="$(v GE_CURRENT_PARENT)"
  case "$p" in
    organizations/?*) printf -- '--organization=%s' "${p#organizations/}";;
    folders/?*) printf -- '--folder=%s' "${p#folders/}";;
    '<'*) printf -- '--<organization|folder>=<id from GE_CURRENT_PARENT>';;
    *) return 1;;
  esac
}

_p12_tip() {    # NAME RESOURCE PERM...: testIamPermissions with CICD_PROJECT as the quota project; response to evidence
  local name="$1" res="$2" b out rc p first=1 miss; shift 2
  b="$(mktemp "${TMPDIR:-/tmp}/agp-p12.XXXXXX")" || return 1
  { printf '{"permissions":['
    for p in "$@"; do [ $first = 1 ] || printf ','; printf '"%s"' "$p"; first=0; done
    printf ']}'; } > "$b"
  out="$(AGP_API_PROJECT="$(v CICD_PROJECT)" api POST "https://cloudresourcemanager.googleapis.com/v3/$res:testIamPermissions" "$b")"; rc=$?
  rm -f "$b"
  [ "$AGP_MODE" = apply ] || return 0
  [ $rc -eq 0 ] || { agp_say "      testIamPermissions on $res failed ($rc)"; return 1; }
  printf '%s\n' "$out" | xw "$(_p12_ev_dir)/$name.json" || return 1
  miss="$(printf '%s' "$out" | python3 "$AGP_HOME/lib/agp_json.py" missing "$@" | tr '\n' ' ')"
  [ -z "$miss" ] && return 0
  agp_say "      $res: missing $miss"
  return 1
}

_p12_tip_ok() { # NAME PERM...: the evidence file of _p12_tip holds every permission
  local f; f="$(_p12_ev_dir)/$1.json"; shift
  [ -s "$f" ] || return 1
  [ -z "$(python3 "$AGP_HOME/lib/agp_json.py" missing "$@" < "$f")" ]
}

_p12_rerun_has() {  # STEP KEY: rerun-index.tsv has a line for STEP whose third field is KEY
  local f; f="$(v BUILD_LOG_DIR)/rerun-index.tsv"
  [ -f "$f" ] || return 1
  awk -F'\t' -v s="$1" -v k="$2" '$2 == s && $3 == k {f = 1} END {exit f ? 0 : 1}' "$f"
}

_p12_rerun_add() {  # STEP KEY WHAT STATE_NOTE: one re-run line, once (the page's printf >> rerun-index.tsv)
  local f; f="$(v BUILD_LOG_DIR)/rerun-index.tsv"
  if _p12_rerun_has "$1" "$2"; then agp_say "      re-run line $1 $2 present"; return 0; fi
  { [ -f "$f" ] && cat "$f"; printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%F)" "$1" "$2" "$3" "PENDING" "$4"; } | xw "$f"
}

_p12_bd_has() {     # ID: the deviation register's first table has the row
  local f; f="$(v DEVIATION_REGISTER)"
  [ -f "$f" ] || return 1
  awk -F' *[|] *' -v id="$1" '$2 == id && NF == 15 {f = 1} END {exit f ? 0 : 1}' "$f"
}

_p12_bd_count() {   # the number of BD-12-* rows in the first table (the page's id counter)
  local f; f="$(v DEVIATION_REGISTER)"
  [ -f "$f" ] || { echo 0; return 0; }
  awk -F' *[|] *' '$2 ~ /^BD-12-/ && NF == 15' "$f" | wc -l | tr -d ' '
}

_p12_bd_id() {      # N: BD-12-NN in apply mode; BD-12-<n> in a plan, where the register's count is not read
  if [ "$AGP_MODE" = apply ]; then printf 'BD-12-%02d' "$1"; else printf 'BD-12-<n>'; fi
}

_p12_noappr_tsv() { # id, scope, ends of every entry of pam/no-approval.json (the page's jq, without jq)
  python3 - "$(v PLATFORM_REPO_DIR)/pam/no-approval.json" <<'PY'
import json, sys
for e in json.load(open(sys.argv[1]))["entitlements"]:
    print("\t".join([e["id"], e["scope"], e["ends"]]))
PY
}

# ---------------------------------------------------------------- 0. The sitting and the rights it relies on
step PA-0.1 AUTO-READ "Open the sitting and check the gates" \
  --gate "SD-01 SD-12 SD-18 SD-19 SD-42 SD-46 PPL-SH" \
  --needs "ORG_ID DOMAIN SA_1_ADMIN SA_2_ADMIN SECOND_HUMAN_EMAIL GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY GRP_PLATFORM_APPROVERS GRP_GE_ADMINS GRP_EVE_OWNERS GRP_GCP_ORG_ADMINS BOOTSTRAP_EXCEPTION_EXPIRY FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE FLD_GEMINI_ENTERPRISE FLD_AGENTS_R_NONPROD FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_PROD FLD_CONTROLLERS_NONPROD FLD_IMPROVERS_PROD FLD_IMPROVERS_NONPROD CICD_PROJECT CORE_PROJECT CORE_PROJECT_NUMBER LOGGING_PROJECT KMS_PROJECT KMS_PROJECT_NUMBER VALIDATOR_PROJECT SA_FACTORY_APPLY SA_K7_EXECUTOR GEMINI_PROJECT GE_CURRENT_PARENT REGION PLATFORM_REPO_DIR BUILD_LOG_DIR DEVIATION_REGISTER EVIDENCE_REGISTER"
s_PA_0_1_check() { ckpt_done PA-0.1; }
s_PA_0_1_apply() {
  local bad=0 acct id
  if [ "$AGP_MODE" = apply ]; then
    penv_guard || { agp_say "      STOP: penv_guard failed (above)"; bad=1; }
  else
    agp_say "      read: penv_guard"
  fi
  acct="$(_p12_read gcloud auth list --filter=status:ACTIVE --format='value(account)')"
  for id in OB-3.7 CP-8.2 FS-7.5; do
    if ckpt_done "$id"; then agp_say "      $id	DONE"
    elif [ "$AGP_MODE" = apply ]; then agp_say "      STOP: not DONE: $id (its file's step runs first)"; bad=1
    else agp_say "      gate: $id must be DONE"; fi
  done
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      check: today is before BOOTSTRAP_EXCEPTION_EXPIRY with at least three working days to spare"
    _p12_mkev
    return 0
  fi
  [ "$acct" = "$(v SA_1_ADMIN)" ] || { agp_say "      STOP: the active account is '$acct', not SA_1_ADMIN"; bad=1; }
  python3 - "$(v BOOTSTRAP_EXCEPTION_EXPIRY)" >&3 <<'PY' || bad=1
import sys, datetime as d
try:
    e = d.date.fromisoformat(sys.argv[1])
except ValueError:
    print("      STOP: BOOTSTRAP_EXCEPTION_EXPIRY is not a YYYY-MM-DD date: " + sys.argv[1]); sys.exit(1)
t = d.datetime.now(d.timezone.utc).date()
left = sum(1 for i in range(1, (e - t).days) if (t + d.timedelta(days=i)).weekday() < 5)
if t >= e or left < 3:
    print("      STOP: the exception ends %s, %d working days from today; only a signed SD-01 extension continues" % (e, left)); sys.exit(1)
print("      exception valid until %s (%d working days to spare)" % (e, left))
PY
  [ $bad = 0 ] || return 1
  _p12_mkev
}

step PA-0.2 AUTO "Prove that the organisation exception carries the permissions PAM setup needs" \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM GEMINI_PROJECT_NUMBER CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
_p12_org_tip() {    # [ok]: PA-0.2's organisation test, or (with ok) the check of its evidence file
  if [ "${1-}" = ok ]; then
    _p12_tip_ok PA-0.2-org resourcemanager.organizations.get resourcemanager.organizations.setIamPolicy \
      resourcemanager.organizations.getIamPolicy privilegedaccessmanager.entitlements.create
  else
    _p12_tip PA-0.2-org "organizations/$(v ORG_ID)" resourcemanager.organizations.get resourcemanager.organizations.setIamPolicy \
      resourcemanager.organizations.getIamPolicy privilegedaccessmanager.entitlements.create
  fi
}
s_PA_0_2_check() {
  ckpt_done PA-0.2 && return 0
  nonempty r gcloud services list --enabled --project="$(v CICD_PROJECT)" --filter="config.name=privilegedaccessmanager.googleapis.com" --format="value(config.name)" || return $?
  _p12_org_tip ok \
    && _p12_tip_ok PA-0.2-folder resourcemanager.folders.get resourcemanager.folders.setIamPolicy \
    && _p12_tip_ok PA-0.2-gemini resourcemanager.projects.get resourcemanager.projects.setIamPolicy
}
s_PA_0_2_apply() {
  local rc=0
  _p12_mkev || return 1
  x gcloud services enable privilegedaccessmanager.googleapis.com --project="$(v CICD_PROJECT)" || return 1
  if [ "$AGP_MODE" = apply ] && ! nonempty r gcloud services list --enabled --project="$(v CICD_PROJECT)" \
       --filter="config.name=privilegedaccessmanager.googleapis.com" --format="value(config.name)"; then
    agp_say "      STOP: privilegedaccessmanager.googleapis.com is not listed as enabled in CICD_PROJECT; wait a minute and re-run"
    return 1
  fi
  _p12_org_tip || rc=1
  _p12_tip PA-0.2-folder "folders/$(v FLD_AGENTIC_PLATFORM)" resourcemanager.folders.get resourcemanager.folders.setIamPolicy || rc=1
  _p12_tip PA-0.2-gemini "projects/$(v GEMINI_PROJECT_NUMBER)" resourcemanager.projects.get resourcemanager.projects.setIamPolicy || rc=1
  if [ $rc -ne 0 ]; then
    agp_say "      STOP: read PA-0.2's branches in order: (1) the API not yet effective in the quota project (wait, re-run);"
    agp_say "      (2) the quota project header or serviceusage.services.use; (3) only then 06 OB-3.7's VERIFY (five roles)."
    return 1
  fi
  ev PA-0.2 exception-permissions E-05 4.2.1 "build-log:evidence/12" "$(_p12_ev_dir)/PA-0.2-org.json"
}

# ---------------------------------------------------------------- 1. Set up Privileged Access Manager
step PA-1.1 AUTO "Enable the PAM API in the quota project and let the requester group use it" \
  --needs "CICD_PROJECT GRP_PLATFORM_OWNERS DEVIATION_REGISTER BUILD_LOG_DIR EVIDENCE_REGISTER"
s_PA_1_1_check() {
  ckpt_done PA-1.1 && return 0
  nonempty r gcloud services list --enabled --project="$(v CICD_PROJECT)" --filter="config.name=privilegedaccessmanager.googleapis.com" --format="value(config.name)" || return $?
  has_binding "group:$(v GRP_PLATFORM_OWNERS)" roles/serviceusage.serviceUsageConsumer gcloud projects get-iam-policy "$(v CICD_PROJECT)" || return $?
  _p12_bd_has BD-12-01
}
s_PA_1_1_apply() {
  local a b
  x gcloud services enable privilegedaccessmanager.googleapis.com --project="$(v CICD_PROJECT)" || return 1
  x gcloud projects add-iam-policy-binding "$(v CICD_PROJECT)" --member="group:$(v GRP_PLATFORM_OWNERS)" \
    --role="roles/serviceusage.serviceUsageConsumer" --condition=None || return 1
  x bd_insert "$(printf '| BD-12-01 | %s | 12 PA-1.1 | DEV | privilegedaccessmanager API outside the core allow-list | %s | - | API enabled; serviceUsageConsumer to %s | n/a | n/a | second human (PA-2.2 review) | until 13 adds it to the fld-platform-core allow-list | open |' \
    "$(date -u +%F)" "projects/$(v CICD_PROJECT)" "$(v GRP_PLATFORM_OWNERS)")" || return 1
  # the page's VERIFY reads, kept in PA-1.1-verify.txt (the evidence file); the step's check proves their content
  _p12_mkev || return 1
  a="$(_p12_read gcloud services list --enabled --project="$(v CICD_PROJECT)" --filter="config.name=privilegedaccessmanager.googleapis.com" --format="value(config.name)")"
  b="$(_p12_read gcloud projects get-iam-policy "$(v CICD_PROJECT)" --flatten="bindings[].members" \
    --filter="bindings.role=roles/serviceusage.serviceUsageConsumer" --format="value(bindings.members)")"
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s\n%s\n' "$a" "$b" | xw "$(_p12_ev_dir)/PA-1.1-verify.txt" || return 1
  ev PA-1.1 pam-api E-05 5.2.1 "build-log:evidence/12" "$(_p12_ev_dir)/PA-1.1-verify.txt"
}

step PA-1.2 CONSOLE "Set up PAM at the organisation: the service agent's role" \
  --needs "ORG_ID CICD_PROJECT FLD_AGENTIC_PLATFORM GEMINI_PROJECT BUILD_LOG_DIR"
s_PA_1_2_check() { ckpt_done PA-1.2; }
s_PA_1_2_manual() {
  local d o; d="$(_p12_ev_dir)"; o="$(v ORG_ID)"
  echo "WHO: the platform owner as sa-1-admin@, in its browser profile (01 PR-1.3)."
  echo "WHERE: Cloud console > IAM & Admin > Privileged Access Manager > resource picker: the organisation > Set up PAM > Grant role. Grant nothing else there."
  echo "Then, in the shell:"
  printf '$ gcloud organizations get-iam-policy %s --format=json > %s/PA-1.2-org-policy.json\n' "$o" "$d"
  printf '$ jq -r --arg m "serviceAccount:service-org-%s@gcp-sa-pam.iam.gserviceaccount.com" %s %s/PA-1.2-org-policy.json\n' "$o" "'.bindings[] | select(.members | index(\$m)) | .role'" "$d"
  printf '$ gcloud pam check-onboarding-status --organization=%s --location=global --billing-project=%s | tee %s/PA-1.2-onboarding-org.txt\n' "$o" "$(v CICD_PROJECT)" "$d"
  printf '  and the same with --folder=%s (PA-1.2-onboarding-folder.txt) and --project=%s (PA-1.2-onboarding-gemini.txt)\n' "$(v FLD_AGENTIC_PLATFORM)" "$(v GEMINI_PROJECT)"
  echo "VERIFY: exactly one unconditioned role, roles/privilegedaccessmanager.serviceAgent or .organizationServiceAgent; no finding in the three outputs (any missing permission or unset agent is a stop)."
  _p12_say_ev PA-1.2 pam-service-agent E-05 4.1.3 PA-1.2-org-policy.json
  echo "Then: agp-platform done PA-1.2 --note \"<the service-agent role recorded>\""
}

step PA-1.3 AUTO "PAM Admin to platform-owners@, standing" \
  --needs "ORG_ID SA_1_ADMIN GRP_PLATFORM_OWNERS GRP_GCP_ORG_ADMINS BUILD_LOG_DIR EVIDENCE_REGISTER"
s_PA_1_3_check() {
  ckpt_done PA-1.3 && return 0
  has_binding "group:$(v GRP_PLATFORM_OWNERS)" roles/privilegedaccessmanager.admin gcloud organizations get-iam-policy "$(v ORG_ID)"
}
s_PA_1_3_apply() {
  local mem n rc pol out
  # the group address is the scope of this Cloud Identity read
  mem="$(_p12_read gcloud identity groups memberships list --group-email="$(v GRP_PLATFORM_OWNERS)" --format='value(preferredMemberKey.id)')"
  if [ $? -ne 0 ] && [ "$AGP_MODE" = apply ]; then
    agp_say "      STOP: the membership of platform-owners@ could not be read (above); nothing is granted"; return 1
  fi
  [ "$AGP_MODE" = apply ] || agp_say "      check: the members are exactly SA_1_ADMIN (CONTROL_GROUPS_FILE); a difference stops before the grant"
  if [ "$AGP_MODE" = apply ]; then
    printf '%s\n' "$mem" | xw "$(_p12_ev_dir)/PA-1.3-members.txt" || return 1
    # exactly SA_1_ADMIN: one member in the list, and the list filtered on SA_1_ADMIN prints it
    n="$(printf '%s\n' "$mem" | sed '/^$/d' | wc -l | tr -d ' ')"
    nonempty r gcloud identity groups memberships list --group-email="$(v GRP_PLATFORM_OWNERS)" \
      --filter="preferredMemberKey.id=\"$(v SA_1_ADMIN)\"" --format='value(preferredMemberKey.id)'; rc=$?
    if [ "$n" != 1 ] || [ $rc -ne 0 ]; then
      agp_say "      STOP: platform-owners@ holds '$(printf '%s\n' "$mem" | sed '/^$/d' | paste -sd, -)', not exactly SA_1_ADMIN as CONTROL_GROUPS_FILE says: severity 1 control-group drift"
      return 1
    fi
  fi
  x gcloud organizations add-iam-policy-binding "$(v ORG_ID)" --member="group:$(v GRP_PLATFORM_OWNERS)" \
    --role="roles/privilegedaccessmanager.admin" --condition=None || return 1
  pol="$(_p12_read gcloud organizations get-iam-policy "$(v ORG_ID)" --format=json)"
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s' "$pol" | xw "$(_p12_ev_dir)/PA-1.3-org-policy.json" || return 1
  # the page's table of PAM Admin members and condition titles, from the policy just read, kept in PA-1.3-pam-admin.txt
  out="$(python3 - "$(_p12_ev_dir)/PA-1.3-org-policy.json" "group:$(v GRP_PLATFORM_OWNERS)" "group:$(v GRP_GCP_ORG_ADMINS)" "user:$(v SA_1_ADMIN)" <<'PY'
import json, sys
owners, breakglass, sa1 = sys.argv[2:5]
raw = open(sys.argv[1]).read()
allowed = {(owners, ""), (breakglass, ""), (sa1, "bootstrap-exception-sd-01")}
held = set()
for b in (json.loads(raw) if raw.strip() else {}).get("bindings", []):
    if b.get("role") == "roles/privilegedaccessmanager.admin":
        for m in b.get("members", []):
            held.add((m, (b.get("condition") or {}).get("title", "")))
for m, c in sorted(held):
    print("      %s %s" % (m, c or "(no condition)"))
extra = sorted(h for h in held if h not in allowed)
if extra or (owners, "") not in held:
    print("      STOP: PAM Admin is held by %s, or platform-owners@ has no unconditioned binding" % extra); sys.exit(1)
for h in sorted(allowed - held):
    print("      WARN: %s %s does not hold PAM Admin; read 06 OB-3.7 and OB-7.1" % h)
PY
)"; rc=$?
  printf '%s\n' "$out" >&3
  [ $rc -eq 0 ] || return 1
  printf '%s\n' "$out" | sed 's/^ *//' | xw "$(_p12_ev_dir)/PA-1.3-pam-admin.txt" || return 1
  ev PA-1.3 pam-admin-group E-05 4.2.1 "build-log:evidence/12" "$(_p12_ev_dir)/PA-1.3-pam-admin.txt"
}

step PA-1.4 CONSOLE "Read the PAM settings and prove mail delivery" --witness --needs "BUILD_LOG_DIR DOMAIN"
s_PA_1_4_check() { ckpt_done PA-1.4; }
s_PA_1_4_manual() {
  echo "WHO: the platform owner; the second human confirms a mail later (PA-3.2)."
  echo "WHERE: Cloud console > IAM & Admin > Privileged Access Manager > the organisation > Settings tab. Change nothing."
  echo "1. Automated approvals must read disabled (Google's default). Screenshot it."
  echo "2. Every email notification row reads Inherit from parent, or is enabled as setup/12 PA-1.4 lists; a disabled row is a stop."
  printf '3. A Workspace super admin confirms mail from pam-noreply@google.com is not quarantined for %s.\n' "$(v DOMAIN)"
  printf '$ screencapture -i %s/PA-1.4-settings.png\n' "$(_p12_ev_dir)"
  _p12_say_ev PA-1.4 pam-settings E-05 4.1.3 PA-1.4-settings.png
  echo "Then: agp-platform done PA-1.4 --witness $(v SA_2_ADMIN)"
}

step PA-1.5 AUTO "Commit the PAM tools: the grant helpers, the live compare and the standing sweep" \
  --needs "PLATFORM_REPO_DIR SECOND_HUMAN_EMAIL"
_p12_tools() {      # NAME ASSET MODE: the three files of PA-1.5's block, saved from the page in assets/ (12.manifest)
  printf '%s\n' "pam.sh pa-1.5-pam.sh 644" "compare.py pa-1.5-compare.py 755" "sweep.py pa-1.5-sweep.py 755"
}
_p12_tools_ok() {   # the three tools are the page's bytes, and the two the page makes executable are
  local t name asset mode; t="$(v PLATFORM_REPO_DIR)/pam/tools"
  while read -r name asset mode; do
    cmp -s "$AGP_HOME/assets/$asset" "$t/$name" || return 1
    [ "$mode" = 644 ] || [ -x "$t/$name" ] || return 1
  done <<EOF_P12_TOOLS
$(_p12_tools)
EOF_P12_TOOLS
}
_p12_tools_compile() {  # the page's VERIFY: bash -n pam.sh and the two Python tools compile (compile() writes no __pycache__)
  local t; t="$(v PLATFORM_REPO_DIR)/pam/tools"
  bash -n "$t/pam.sh" && python3 -c 'import sys
for f in sys.argv[1:]:
    compile(open(f, encoding="utf-8").read(), f, "exec")' "$t/compare.py" "$t/sweep.py"
}
_p12_codeowners_n() { grep -c '^/pam/' "$(v PLATFORM_REPO_DIR)/.github/CODEOWNERS" 2>/dev/null; }
_p12_on_branch() {  # PA-2.2's branch, entered (or made) before the first file is written, so main never holds unreviewed files
  local p b cur; p="$(v PLATFORM_REPO_DIR)"; b=setup-12-pam-catalogue
  if [ "$AGP_MODE" = apply ]; then
    cur="$(git -C "$p" symbolic-ref --short HEAD 2>/dev/null)"
    [ "$cur" = "$b" ] && return 0
    if git -C "$p" rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then x git -C "$p" checkout "$b"; return $?; fi
  fi
  x git -C "$p" checkout -b "$b"
}
s_PA_1_5_check() {
  ckpt_done PA-1.5 && return 0
  _p12_tools_ok && [ "$(_p12_codeowners_n)" = 1 ] && _p12_tools_compile 2>/dev/null
}
s_PA_1_5_apply() {
  local p t cf name asset mode n
  p="$(v PLATFORM_REPO_DIR)"; t="$p/pam/tools"; cf="$p/.github/CODEOWNERS"
  _p12_on_branch || return 1
  x mkdir -p "$t" "$p/pam/entitlements" "$p/pam/templates" || return 1
  while read -r name asset mode; do
    xw "$t/$name" "$mode" < "$AGP_HOME/assets/$asset" || return 1
  done <<EOF_P12_TOOLS
$(_p12_tools)
EOF_P12_TOOLS
  # the page: grep -q '^/pam/' CODEOWNERS || printf '/pam/              %s\n' "$SECOND_HUMAN_EMAIL" >> CODEOWNERS
  if [ "$AGP_MODE" != apply ] || ! grep -q '^/pam/' "$cf" 2>/dev/null; then
    if [ "$AGP_MODE" = apply ] && [ ! -f "$cf" ]; then
      agp_warn "$cf does not exist (03 DC-9.4 commits it): PA-1.5 creates it with the /pam/ line alone, and PA-2.2's reviewer sees a new file"
      x mkdir -p "$p/.github" || return 1
    fi
    { [ -f "$cf" ] && cat "$cf"; printf '/pam/              %s\n' "$(v SECOND_HUMAN_EMAIL)"; } | xw "$cf" 644 || return 1
  fi
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      check: bash -n pam.sh; compare.py and sweep.py compile (TOOLS COMPILE); grep -c '^/pam/' CODEOWNERS prints 1"
    agp_say "      the files are committed in PA-2.2, with the catalogue, in one pull request"
    return 0
  fi
  _p12_tools_compile || { agp_say "      STOP: a PAM tool does not compile (above)"; return 1; }
  agp_say "      TOOLS COMPILE"
  n="$(_p12_codeowners_n)"
  [ "$n" = 1 ] || { agp_say "      STOP: $cf holds ${n:-no} /pam/ lines, not 1"; return 1; }
}

# ---------------------------------------------------------------- 2. The committed catalogue
step PA-2.1 AUTO "Write every entitlement file, the templates, the index and the role list" \
  --needs "PLATFORM_REPO_DIR SA_1_ADMIN SA_2_ADMIN SECOND_HUMAN_EMAIL GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY GRP_PLATFORM_APPROVERS GRP_EVE_OWNERS GRP_GE_ADMINS GRP_GCP_ORG_ADMINS ORG_ID FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_PROD FLD_CONTROLLERS_NONPROD FLD_AGENTS_R_NONPROD FLD_IMPROVERS_PROD FLD_IMPROVERS_NONPROD FLD_GEMINI_ENTERPRISE CORE_PROJECT CORE_PROJECT_NUMBER REGION SA_FACTORY_APPLY SA_K7_EXECUTOR GEMINI_PROJECT GEMINI_PROJECT_NUMBER GE_CURRENT_PARENT" \
  --sets "ENT_PROJECT_REPAIR_TEMPLATE ENT_DEPLOY_CREDENTIAL_HOLDER_TEMPLATE"
# The no-approval end date of ent-factory-singleton-psa-nonprod is not a variable of ~/.platform-env: the page reads it with
# decision-value.sh from the Values table of the signed SD-42 record and gives it to the generator for that command only. No
# row: stop, and SD-42 is amended by a superseding record. catalogue.py is the page's file, byte for byte; it reads every
# value from the environment.
_p12_psa_until() {  # the end date, or 1
  local u
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: $(agp_tool decision-value.sh) SD-42 PSA_NONPROD_NOAPPROVAL_UNTIL"
    printf '<PSA_NONPROD_NOAPPROVAL_UNTIL from SD-42>'; return 0
  fi
  u="$("$(agp_tool decision-value.sh)" SD-42 PSA_NONPROD_NOAPPROVAL_UNTIL)" || return 1
  case "$u" in ''|'*tbd*'|*'<'*'>'*) return 1;; esac
  printf '%s' "$u"
}
_p12_cat_verify() { # the page's VERIFY of PA-2.1 (its jq and grep lines, in Python): prints each failure, 0 when all pass
  python3 - "$(v PLATFORM_REPO_DIR)/pam" "user:$(v SA_1_ADMIN)" "group:$(v GRP_PLATFORM_OWNERS)" "group:$(v GRP_GCP_ORG_ADMINS)" "$(v ORG_ID)" <<'PY'
import json, os, sys
pam, sa1, owners, breakglass, org = sys.argv[1:6]
bad = []
def load(p):
    try:
        return json.load(open(os.path.join(pam, p)))
    except (OSError, ValueError) as e:
        bad.append("%s unreadable: %s" % (p, e)); return None
na = load("no-approval.json") or {"entitlements": []}
want = {"ent-k7-human", "ent-k7-human-scheduler", "ent-k7-executor", "ent-k7-executor-scheduler", "ent-factory-singleton-psa-nonprod", "ent-ge-admin"}
got = [e.get("id") for e in na.get("entitlements", [])]
if sorted(got) != sorted(want):
    bad.append("no-approval.json ids are %s, not the six of the page" % sorted(got))
for n in ("ent-factory-singleton-ctl-prod", "ent-factory-singleton-ctl-nonprod", "ent-witness-export-repair"):
    d = load("entitlements/%s.json" % n) or {}
    steps = ((d.get("approvalWorkflow") or {}).get("manualApprovals") or {}).get("steps", [])
    k = len([p for s in steps for a in s.get("approvers", []) for p in a.get("principals", []) if p in (sa1, owners)])
    if k != 0:
        bad.append("%s: %d approver principals are sa-1-admin@ or platform-owners@ (0 expected, SD-12)" % (n, k))
try:
    idx = [l for l in open(os.path.join(pam, "index.tsv")).read().splitlines() if l]
except OSError:
    idx = []
rows = [l.split("\t") for l in idx[1:]]
n_want = 23 if any(r[0] == "ent-factory-singleton-psa-prod" for r in rows) else 22
if len(idx) != n_want:
    bad.append("index.tsv has %d lines, not %d" % (len(idx), n_want))
for r in rows:
    if len(r) < 6 or not os.path.isfile(os.path.join(pam, r[5])):
        bad.append("index row without its file: %s" % "\t".join(r))
try:
    cols = set(open(os.path.join(pam, "role-columns.txt")).read().split())
except OSError:
    cols = set()
for r in ("roles/owner", "roles/editor", "roles/resourcemanager.folderCreator", "roles/privilegedaccessmanager.admin",
          "roles/iam.securityAdmin", "roles/iam.serviceAccountTokenCreator"):
    print("      %s %s" % (r, "swept" if r in cols else "MISSING"))
    if r not in cols:
        bad.append("role-columns.txt lacks " + r)
try:
    allow = [l.split("\t") for l in open(os.path.join(pam, "role-allow.tsv")).read().splitlines()[1:] if l]
except OSError:
    allow = []
want_allow = sorted([("roles/privilegedaccessmanager.admin", "organizations", org, owners),
                     ("roles/privilegedaccessmanager.admin", "organizations", org, breakglass)])
if sorted(tuple(a[:4]) for a in allow) != want_allow:
    bad.append("role-allow.tsv is not exactly the two PAM Admin rows of platform-owners@ and gcp-organization-admins@: %s" % allow)
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PY
}
_p12_cat_written() {    # catalogue.py is the page's file and the generated catalogue is on disk with both template variables
  local p; p="$(v PLATFORM_REPO_DIR)/pam"
  cmp -s "$AGP_HOME/assets/pa-2.1-catalogue.py" "$p/tools/catalogue.py" && [ -s "$p/index.tsv" ] && [ -s "$p/no-approval.json" ] || return 1
  has_value ENT_PROJECT_REPAIR_TEMPLATE && has_value ENT_DEPLOY_CREDENTIAL_HOLDER_TEMPLATE || return 1
  [ -f "$(v ENT_PROJECT_REPAIR_TEMPLATE)" ] && [ -f "$(v ENT_DEPLOY_CREDENTIAL_HOLDER_TEMPLATE)" ]
}
s_PA_2_1_check() {
  ckpt_done PA-2.1 && return 0
  _p12_cat_written && _p12_cat_verify >/dev/null
}
s_PA_2_1_apply() {
  local p until out
  p="$(v PLATFORM_REPO_DIR)"
  if [ "$AGP_MODE" = apply ]; then
    case "$(v GE_CURRENT_PARENT)" in
      organizations/[0-9]*|folders/[0-9]*) ;;
      *) agp_say "      STOP: GE_CURRENT_PARENT is '$(v GE_CURRENT_PARENT)'; catalogue.py needs organizations/<id> or folders/<id> (05 GI-1.4)"; return 1;;
    esac
  fi
  has_value SECURITY_REVIEWER_EMAIL || agp_say "      SR not named: ent-factory-singleton-psa-prod is written but not created (PA-4.7 BLOCKED)"
  until="$(_p12_psa_until)" || {
    agp_say "      STOP: SD-42 gives no PSA_NONPROD_NOAPPROVAL_UNTIL (decision-value.sh, above): the generator does not run."
    agp_say "      Have SD-42 amended by a superseding record that carries the Values row (03 DC-6.1), then resume from PA-2.1."
    return 1; }
  case "$until" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]|'<'*) ;; *) agp_warn "PA-2.1: SD-42's end date '$until' is not YYYY-MM-DD; the second human checks it in the PA-2.2 review";; esac
  _p12_on_branch || return 1
  x mkdir -p "$p/pam/tools" "$p/pam/entitlements" "$p/pam/templates" || return 1
  xw "$p/pam/tools/catalogue.py" 644 < "$AGP_HOME/assets/pa-2.1-catalogue.py" || return 1
  out="$(x env PSA_NONPROD_NOAPPROVAL_UNTIL="$until" python3 "$p/pam/tools/catalogue.py")" || {
    agp_say "      STOP: catalogue.py failed (a MISSING line names the variable); nothing is committed"; return 1; }
  [ "$AGP_MODE" != apply ] || printf '%s\n' "$out" | sed 's/^/        /' >&3
  pset ENT_PROJECT_REPAIR_TEMPLATE "$p/pam/templates/ent-project-repair.template.json" || return 1
  pset ENT_DEPLOY_CREDENTIAL_HOLDER_TEMPLATE "$p/pam/templates/ent-deploy-credential-holder.template.json" || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      check: no STOP line; '21 entitlement files; 4 templates; <n> roles; 2 allow rows; 6 no-approval' (22 files once SECURITY_REVIEWER_EMAIL is set);"
    agp_say "      six no-approval ids, 0 three times, 22 index lines, six 'swept', two role-allow.tsv rows"
    return 0
  fi
  _p12_cat_verify >&3 || { agp_say "      STOP: the catalogue fails the page's VERIFY (above); fix the inputs and run PA-2.1 again before PA-2.2"; return 1; }
}

step PA-2.2 HUMAN "Review and merge the catalogue" --witness --needs "PLATFORM_REPO_DIR PLATFORM_REPO_REMOTE SA_2_ADMIN"
s_PA_2_2_check() { ckpt_done PA-2.2; }
s_PA_2_2_manual() {
  local p; p="$(v PLATFORM_REPO_DIR)"
  echo "WHO: the platform owner opens the pull request; the second human reviews and approves it (CODEOWNERS on /pam/ and /.github/)."
  echo "PA-1.5 and PA-2.1 wrote the files on the branch setup-12-pam-catalogue (the page's checkout -b, made before the first file)."
  printf '$ git -C %s checkout setup-12-pam-catalogue      (if not on it)\n' "$p"
  printf '$ git -C %s add pam .github/CODEOWNERS\n' "$p"
  printf '$ git -C %s commit -m "setup 12: PAM catalogue, templates, tools (04 section 5.2; SD-18, SD-19, SD-42, SD-46)"\n' "$p"
  printf '$ git -C %s push -u origin setup-12-pam-catalogue\n' "$p"
  echo "The second human approves only if no approver set holds sa-1-admin@ or platform-owners@, no-approval.json has six entries"
  echo "(the ends of ent-factory-singleton-psa-nonprod a YYYY-MM-DD date after the review, as SD-42 signed it),"
  echo "role-columns.txt carries the six extra roles and role-allow.tsv exactly the two PAM Admin rows. Merge, then pull main."
  printf "VERIFY: git -C %s log -1 --format=%%H origin/main -- pam prints the catalogue commit; git status --porcelain pam prints nothing.\n" "$p"
  printf '$ evidence_add PA-2.2 pam-catalogue-merge E-05 5.2.1 "%s"\n' "$(v PLATFORM_REPO_REMOTE)"
  echo "Then: agp-platform done PA-2.2 --witness $(v SA_2_ADMIN)"
}

step PA-2.3 AUTO "Prove that gcloud's --entitlement-file parser accepts the committed JSON, on a throwaway scope" \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER FLD_IMPROVERS_NONPROD CICD_PROJECT GRP_PLATFORM_OWNERS" --removes
_p12_pa23_miss() {  # READBACK_TEXT: the page's VERIFY items the read-back lacks, as " [item]..."; empty when all are there
  local r miss=""
  for r in "state: AVAILABLE" "maxRequestDuration: 3600s" "roles/resourcemanager.projectCreator" "roles/serviceusage.serviceUsageAdmin" \
           "roles/iam.serviceAccountCreator" "roles/resourcemanager.projectIamAdmin" "group:$(v GRP_PLATFORM_OWNERS)"; do
    printf '%s' "$1" | grep -qF -- "$r" || miss="$miss [$r]"
  done
  printf '%s' "$miss"
}
_p12_pa23_filter() { # the page's VERIFY as a list filter: the probe with every field the committed file gives it
  local r f="name~/entitlements/ent-parser-probe$ AND state=AVAILABLE AND maxRequestDuration=3600s"
  for r in roles/resourcemanager.projectCreator roles/serviceusage.serviceUsageAdmin roles/iam.serviceAccountCreator roles/resourcemanager.projectIamAdmin; do
    f="$f AND privilegedAccess.gcpIamAccess.roleBindings.role=$r"
  done
  printf '%s AND eligibleUsers.principals="group:%s"' "$f" "$(v GRP_PLATFORM_OWNERS)"
}
s_PA_2_3_check() {
  local rc
  ckpt_done PA-2.3 && return 0
  # done when the read-back was verified (PA-2.3-verified.txt, written only then) and the probe no longer exists
  # (the list after the delete prints nothing)
  [ -s "$(_p12_ev_dir)/PA-2.3-verified.txt" ] || return 1
  nonempty r gcloud pam entitlements list --folder="$(v FLD_IMPROVERS_NONPROD)" --location=global --billing-project="$(v CICD_PROJECT)" \
    --filter="name~/entitlements/ent-parser-probe$" --format="value(name)"; rc=$?
  case $rc in 0) return 1;; 1) return 0;; *) return $rc;; esac
}
s_PA_2_3_apply() {
  local d f bp out rb ok miss=""
  d="$(_p12_ev_dir)"; f="$(v FLD_IMPROVERS_NONPROD)"; bp="$(v CICD_PROJECT)"
  if [ "$AGP_MODE" = apply ] && [ -n "$(git -C "$(v PLATFORM_REPO_DIR)" status --porcelain -- pam 2>/dev/null)" ]; then
    agp_warn "PA-2.3: pam/ has uncommitted changes; the page probes the catalogue on the merged main (PA-2.2)"
  fi
  if [ "$AGP_MODE" = apply ] && [ ! -f "$(v PLATFORM_REPO_DIR)/pam/entitlements/ent-bootstrap-module-improvers-nonprod.json" ]; then
    agp_say "      STOP: $(v PLATFORM_REPO_DIR)/pam/entitlements/ent-bootstrap-module-improvers-nonprod.json is missing: PA-2.1 and PA-2.2 come first"
    return 1
  fi
  _p12_mkev || return 1
  x cp "$(v PLATFORM_REPO_DIR)/pam/entitlements/ent-bootstrap-module-improvers-nonprod.json" "$d/PA-2.3-probe.json" || return 1
  if [ "$AGP_MODE" = apply ] && AGP_CALL_CONTEXT=check _p12_ent_desc ent-parser-probe "--folder=$f"; then
    agp_say "      ent-parser-probe exists from an earlier run; not created again, deleted below"
  else
    out="$(x gcloud pam entitlements create ent-parser-probe --folder="$f" --location=global --entitlement-file="$d/PA-2.3-probe.json" --billing-project="$bp")" || {
      agp_say "      STOP before PA-3.1: the parser refused the file. Record the exact error; follow PA-2.3's recovery (YAML writer, PA-2.1 and PA-2.2 again)."
      return 1; }
    printf '%s\n' "$out" | xw "$d/PA-2.3-create.txt" || return 1
  fi
  rb="$(_p12_read gcloud pam entitlements describe ent-parser-probe --folder="$f" --location=global --billing-project="$bp" \
    --format="yaml(state,maxRequestDuration,eligibleUsers,privilegedAccess.gcpIamAccess.roleBindings)")"
  if [ "$AGP_MODE" = apply ]; then
    printf '%s\n' "$rb" | xw "$d/PA-2.3-readback.txt" || return 1
    miss="$(_p12_pa23_miss "$rb")"
    # the same VERIFY asked of gcloud as a list filter; either form proves the parser produced the document the file describes
    ok="$(r gcloud pam entitlements list --folder="$f" --location=global --billing-project="$bp" --filter="$(_p12_pa23_filter)" --format="value(name)")" \
      && [ -n "$ok" ] && miss=""
  else
    agp_say "      read: gcloud pam entitlements list --folder=$f --location=global --billing-project=$bp --filter='$(_p12_pa23_filter)' --format='value(name)'"
    agp_say "      check: the read-back holds every VERIFY item, or that filtered list prints the probe; otherwise stop before PA-3.1"
  fi
  x gcloud pam entitlements delete ent-parser-probe --folder="$f" --location=global --billing-project="$bp" || return 1
  out="$(_p12_read gcloud pam entitlements list --folder="$f" --location=global --billing-project="$bp" --format="value(name)")"
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s\n' "$out" | xw "$d/PA-2.3-list.txt" || return 1
  if [ -n "$miss" ]; then
    agp_say "      STOP before PA-3.1: the read-back lacks$miss; the parser did not produce the document the file describes"
    return 1
  fi
  printf 'PA-2.3 %s: the read-back of ent-parser-probe holds AVAILABLE, 3600s, the four singleton roles and platform-owners@\n' "$(date -u +%FT%TZ)" \
    | xw "$d/PA-2.3-verified.txt" || return 1
  ev PA-2.3 entitlement-file-parser E-05 5.2.1 "build-log:evidence/12" "$d/PA-2.3-readback.txt"
}

# ---------------------------------------------------------------- 3. Organisation entitlements
step PA-3.1 AUTO "Create ent-platform-policy" --gate "SD-18" \
  --needs "ORG_ID CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "ENT_PLATFORM_POLICY"
s_PA_3_1_check() {
  ckpt_done PA-3.1 && return 0
  _p12_ent_desc ent-platform-policy "--organization=$(v ORG_ID)" || return $?
  has_value ENT_PLATFORM_POLICY
}
s_PA_3_1_apply() {
  local o out; o="--organization=$(v ORG_ID)"
  _p12_gate PA-2.3 "the parser probe runs before any organisation-scoped create" || return 1
  _p12_mkev || return 1
  _p12_ent_create ent-platform-policy "$o" || return 1
  _p12_ent_pset ENT_PLATFORM_POLICY ent-platform-policy "$o" || return 1
  out="$(_p12_read gcloud pam entitlements describe ent-platform-policy "$o" --location=global --billing-project="$(v CICD_PROJECT)" \
    --format="yaml(state,maxRequestDuration,approvalWorkflow,eligibleUsers,privilegedAccess)")"
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s\n' "$out" | xw "$(_p12_ev_dir)/PA-3.1-describe.txt" || return 1
  printf '%s\n' "$out" | sed 's/^/        /' >&3
  ev PA-3.1 ent-platform-policy E-05 4.1.3 "build-log:evidence/12" "$(_p12_ev_dir)/PA-3.1-describe.txt"
}

step PA-3.2 HUMAN "One-grant test of ent-platform-policy, and the first proof of mail delivery" --witness \
  --needs "ENT_PLATFORM_POLICY ORG_ID PLATFORM_REPO_DIR BUILD_LOG_DIR SECOND_HUMAN_EMAIL"
s_PA_3_2_check() { ckpt_done PA-3.2; }
s_PA_3_2_manual() {
  local o; o="$(v ORG_ID)"
  echo "WHO: the platform owner requests; the second human, as sa-2-admin@, approves (T2). WHERE: shell; the second human's console."
  _p12_say_pamsh
  printf "\$ tip \"organizations/%s\" '\"orgpolicy.policies.update\",\"iam.denypolicies.create\"'      (baseline: {})\n" "$o"
  printf '$ g="$(pam_request "%s" "setup-12 PA-3.2 one-grant test")"; echo "$g"\n' "$(v ENT_PLATFORM_POLICY)"
  printf 'T2 by the second human, who first confirms the approval mail at %s from pam-noreply@google.com;\n' "$(v SECOND_HUMAN_EMAIL)"
  printf 'T3 on organizations %s for the three policy roles; tip again (both permissions); T4; T5 with <step>=PA-3.2 (approved present).\n' "$o"
  echo "platform-security@ receives the Grants activated mail (the second human confirms, as a member)."
  _p12_say_ev PA-3.2 ent-platform-policy-test E-08 4.1.3 PA-3.2-grant.json
  echo "Then: agp-platform done PA-3.2 --witness $(v SA_2_ADMIN)"
}

step PA-3.3 HUMAN "Create and test ent-org-sink" --witness \
  --needs "ORG_ID CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" --sets "ENT_ORG_SINK"
s_PA_3_3_check() { _p12_manual_check PA-3.3 ent-org-sink "--organization=$(v ORG_ID)"; }
s_PA_3_3_manual() {
  local o; o="--organization=$(v ORG_ID)"
  echo "WHO: the platform owner requests; the second human approves (T2). WHERE: shell; the second human's console."
  _p12_say_create ent-org-sink "$o"
  _p12_say_pset ENT_ORG_SINK ent-org-sink "$o"
  _p12_say_pamsh
  printf "\$ tip \"organizations/%s\" '\"logging.sinks.create\"'      (baseline: {})\n" "$(v ORG_ID)"
  echo "Five minutes after the create: T1 (g=\"\$(pam_request \"\$ENT_ORG_SINK\" \"setup-12 PA-3.3 one-grant test\")\"), T2, T3 for"
  echo "roles/logging.configWriter on the organisation, tip again (lists logging.sinks.create), T4, T5 (approved present). No sink is created."
  _p12_say_ev PA-3.3 ent-org-sink E-08 4.1.3 PA-3.3-grant.json
  echo "Then: agp-platform done PA-3.3 --witness $(v SA_2_ADMIN)"
}

step PA-3.4 HUMAN "Create and test the ent-k7-human pair (no approval)" --witness \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR SECOND_HUMAN_EMAIL" \
  --sets "ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER"
s_PA_3_4_check() {
  _p12_manual_check PA-3.4 ent-k7-human "--organization=$(v ORG_ID)" ent-k7-human-scheduler "--folder=$(v FLD_AGENTIC_PLATFORM)"
}
s_PA_3_4_manual() {
  local o f; o="--organization=$(v ORG_ID)"; f="--folder=$(v FLD_AGENTIC_PLATFORM)"
  echo "WHO: the platform owner, as a member of platform-approvers@; the second human confirms the activation mails (no approver exists)."
  _p12_say_create ent-k7-human "$o"
  _p12_say_create ent-k7-human-scheduler "$f"
  _p12_say_pset ENT_K7_HUMAN ent-k7-human "$o"
  _p12_say_pset ENT_K7_HUMAN_SCHEDULER ent-k7-human-scheduler "$f"
  echo "Then, with pam.sh sourced, the page's request of g1 and g2 together; T3 for g1 on the organisation (three roles) and g2 on the"
  printf "folder (cloudscheduler.admin); tip \"folders/%s\" '\"cloudscheduler.jobs.pause\"' while active; T4 and T5 for both (no approved event).\n" "$(v FLD_AGENTIC_PLATFORM)"
  printf 'The second human confirms two Grants activated mails at %s within five minutes; a request without --justification is refused.\n' "$(v SECOND_HUMAN_EMAIL)"
  _p12_say_ev PA-3.4 ent-k7-human E-08 4.1.3 PA-3.4-grant.json
  echo "Then: agp-platform done PA-3.4 --witness $(v SA_2_ADMIN)"
}

step PA-3.5 AUTO "Create the ent-k7-executor pair; its test is file 18's" \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER SA_K7_EXECUTOR" \
  --sets "ENT_K7_EXECUTOR ENT_K7_EXECUTOR_SCHEDULER"
# The page's negative test is a read: the entitlements the caller may request on each scope (`gcloud pam entitlements
# search --caller-access-type=grant-requester`, GA) must not include either id of the pair, and each search must print at
# least one name (the entitlements sa-1-admin@ may request through platform-owners@ and platform-approvers@), or it proved
# nothing. It runs five minutes after a create (the propagation wait of the page's section 3).
_p12_k7x_search() { # SCOPE_FLAG FILE: the page's search on one scope, kept in FILE; 0 when it answered and lists neither id
  local out
  out="$(r gcloud pam entitlements search --caller-access-type=grant-requester "$1" --location=global \
    --billing-project="$(v CICD_PROJECT)" --format="value(name)")" || { agp_say "      STOP: the search on $1 failed (above)"; return 1; }
  printf '%s\n' "$out" | xw "$2" || return 1
  printf '%s\n' "$out" | sed '/^$/d; s/^/        /' >&3
  if [ -z "$(printf '%s' "$out" | sed '/^$/d')" ]; then
    agp_say "      STOP: the search on $1 printed nothing, so it proves nothing: wait and run PA-3.5 again"; return 1
  fi
  if printf '%s\n' "$out" | grep -qE '/entitlements/ent-k7-executor(-scheduler)?$'; then
    agp_say "      STOP: sa-1-admin@ may request the k7-executor pair on $1: delete both, correct the file through PA-2.1 and PA-2.2"; return 1
  fi
}
s_PA_3_5_check() {
  ckpt_done PA-3.5 && return 0
  _p12_ents_exist ent-k7-executor "--organization=$(v ORG_ID)" ent-k7-executor-scheduler "--folder=$(v FLD_AGENTIC_PLATFORM)" || return $?
  has_value ENT_K7_EXECUTOR && has_value ENT_K7_EXECUTOR_SCHEDULER && _p12_rerun_has PA-3.5 "serviceAccount:$(v SA_K7_EXECUTOR)"
}
s_PA_3_5_apply() {
  local o f g d
  o="--organization=$(v ORG_ID)"; f="--folder=$(v FLD_AGENTIC_PLATFORM)"; d="$(_p12_ev_dir)"
  _p12_mkev || return 1
  _P12_CREATED=0
  _p12_ent_create ent-k7-executor "$o" || return 1
  _p12_ent_create ent-k7-executor-scheduler "$f" || return 1
  _p12_ent_pset ENT_K7_EXECUTOR ent-k7-executor "$o" || return 1
  _p12_ent_pset ENT_K7_EXECUTOR_SCHEDULER ent-k7-executor-scheduler "$f" || return 1
  # the two describes are the page's evidence; their fields (AVAILABLE, 1800s, the one requester, no approvalWorkflow)
  # are proven equal to the committed files by PA-6.1's compare, which reads every field
  g="$(_p12_read gcloud pam entitlements describe ent-k7-executor "$o" --location=global --billing-project="$(v CICD_PROJECT)" \
    --format="yaml(state,maxRequestDuration,approvalWorkflow,eligibleUsers)")"
  g="$g
$(_p12_read gcloud pam entitlements describe ent-k7-executor-scheduler "$f" --location=global --billing-project="$(v CICD_PROJECT)" \
    --format="yaml(state,maxRequestDuration,approvalWorkflow,eligibleUsers)")"
  if [ "$AGP_MODE" = apply ]; then
    printf '%s\n' "$g" | xw "$d/PA-3.5-describe.txt" || return 1
    printf '%s\n' "$g" | sed 's/^/        /' >&3
  fi
  _p12_rerun_add PA-3.5 "serviceAccount:$(v SA_K7_EXECUTOR)" \
    "one-grant test of ENT_K7_EXECUTOR and ENT_K7_EXECUTOR_SCHEDULER from the k7-executor job (18)" "job image BLOCKED B-04" || return 1
  if [ "$AGP_MODE" != apply ]; then
    _p12_sleep 300
    agp_say "      read: gcloud pam entitlements search --caller-access-type=grant-requester $o --location=global --billing-project=$(v CICD_PROJECT) '--format=value(name)' > PA-3.5-requestable-org.txt"
    agp_say "      read: the same with $f > PA-3.5-requestable-folder.txt"
    agp_say "      check: each prints a name; neither lists ent-k7-executor or ent-k7-executor-scheduler (NOT ELIGIBLE)"
    return 0
  fi
  [ "$_P12_CREATED" = 0 ] || _p12_sleep 300
  _p12_k7x_search "$o" "$d/PA-3.5-requestable-org.txt" || return 1
  _p12_k7x_search "$f" "$d/PA-3.5-requestable-folder.txt" || return 1
  agp_say "      NOT ELIGIBLE"
  ev PA-3.5 ent-k7-executor E-05 4.1.3 "build-log:evidence/12" "$d/PA-3.5-describe.txt" || return 1
  ev PA-3.5 ent-k7-executor-not-requestable E-05 4.1.3 "build-log:evidence/12" "$d/PA-3.5-requestable-org.txt" || return 1
  ev PA-3.5 ent-k7-executor-scheduler-not-requestable E-05 4.1.3 "build-log:evidence/12" "$d/PA-3.5-requestable-folder.txt"
}

step PA-3.6 HUMAN "Create and test ent-pam-catalogue-org" --witness \
  --needs "ORG_ID CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR SA_1_ADMIN" --sets "ENT_PAM_CATALOGUE_ORG"
s_PA_3_6_check() { _p12_manual_check PA-3.6 ent-pam-catalogue-org "--organization=$(v ORG_ID)"; }
s_PA_3_6_manual() {
  local o; o="--organization=$(v ORG_ID)"
  echo "WHO: the platform owner requests; the second human approves (T2). WHERE: shell; the second human's console."
  _p12_say_create ent-pam-catalogue-org "$o"
  _p12_say_pset ENT_PAM_CATALOGUE_ORG ent-pam-catalogue-org "$o"
  echo "Five minutes later, with pam.sh sourced: T1 (\"setup-12 PA-3.6 one-grant test\"), T2, T3 for roles/resourcemanager.organizationAdmin"
  printf 'on the organisation: a request.time condition for user:%s beside its bootstrap-exception-sd-01 binding. T4, T5.\n' "$(v SA_1_ADMIN)"
  echo "VERIFY after T4: the page's jq on PA-3.6-policy.json prints only bootstrap-exception-sd-01. PA-9.3 relies on this entitlement."
  _p12_say_ev PA-3.6 ent-pam-catalogue-org E-08 4.1.3 PA-3.6-grant.json
  echo "Then: agp-platform done PA-3.6 --witness $(v SA_2_ADMIN)"
}

# ---------------------------------------------------------------- 4. Folder and project entitlements
step PA-4.0 HUMAN "Check every folder-entitlement role for launch stage and lowest grant level, before any folder create" \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_PA_4_0_check() { ckpt_done PA-4.0; }
s_PA_4_0_manual() {
  echo "WHO: the platform owner as sa-1-admin@. WHERE: shell, ~/.platform-env sourced."
  printf 'Paste setup/12 PA-4.0'"'"'s block: it lists every role of %s/pam/entitlements and templates into PA-4.0-roles.txt,\n' "$(v PLATFORM_REPO_DIR)"
  echo "reads each role's stage with gcloud iam roles describe into PA-4.0-role-stages.tsv, prints NON-GA rows and the"
  echo "role count of ent-project-repair-core (19 unless a role moves). Then, by hand, read the lowest grant level of every"
  echo "NON-GA role and of roles/resourcemanager.lienModifier in the IAM roles reference, and decide with the page's table."
  echo "A role to move or remove goes back through PA-2.1 and PA-2.2 now, before the approval sitting."
  echo "VERIFY: one stage row per role, no empty stage; a decision per NON-GA row; git status --porcelain pam prints nothing."
  _p12_say_ev PA-4.0 role-launch-stages E-05 4.1.3 PA-4.0-role-stages.tsv
  echo "Then: agp-platform done PA-4.0 --note \"<the role count carried into PA-4.2>\""
}

step PA-4.1 HUMAN "Create and test ent-folder-admin on fld-agentic-platform" --witness \
  --needs "FLD_AGENTIC_PLATFORM CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" --sets "ENT_FOLDER_ADMIN"
s_PA_4_1_check() { _p12_manual_check PA-4.1 ent-folder-admin "--folder=$(v FLD_AGENTIC_PLATFORM)"; }
s_PA_4_1_manual() {
  local f; f="--folder=$(v FLD_AGENTIC_PLATFORM)"
  echo "WHO: the platform owner requests; the second human approves (T2). WHERE: shell; the second human's console."
  _p12_say_create ent-folder-admin "$f"
  _p12_say_pset ENT_FOLDER_ADMIN ent-folder-admin "$f"
  _p12_say_pamsh
  printf "\$ tip \"folders/%s\" '\"logging.sinks.create\",\"resourcemanager.folders.update\"'      (baseline: {})\n" "$(v FLD_AGENTIC_PLATFORM)"
  echo "Five minutes after the create: T1 (\"setup-12 PA-4.1 one-grant test\"), T2, T3 on the folder for the four roles,"
  echo "tip again (both listed), T4 (NO-BINDING four times), T5 (approved)."
  _p12_say_ev PA-4.1 ent-folder-admin E-08 4.1.3 PA-4.1-grant.json
  echo "Then: agp-platform done PA-4.1 --witness $(v SA_2_ADMIN)"
}

step PA-4.2 HUMAN "Create and test ent-project-repair-core on fld-platform-core" --witness \
  --needs "FLD_PLATFORM_CORE CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR SA_1_ADMIN" --sets "ENT_PROJECT_REPAIR_CORE"
s_PA_4_2_check() { _p12_manual_check PA-4.2 ent-project-repair-core "--folder=$(v FLD_PLATFORM_CORE)"; }
s_PA_4_2_manual() {
  local f; f="--folder=$(v FLD_PLATFORM_CORE)"
  echo "WHO: the platform owner requests; the second human approves (T2). Gate: PA-4.0 DONE (agp-platform status); otherwise stop."
  _p12_say_create ent-project-repair-core "$f"
  _p12_say_pset ENT_PROJECT_REPAIR_CORE ent-project-repair-core "$f"
  echo "Or paste the page's block, whose gate_pa40 runs the create only when PA-4.0 is DONE. With pam.sh sourced:"
  echo "\$ g=\"\$(pam_request \"\$ENT_PROJECT_REPAIR_CORE\" \"setup-12 PA-4.2 one-grant test\" 1800)\" && echo \"\$g\""
  printf 'T2; T3 on folders %s with the page'"'"'s loop over the roles of ent-project-repair-core.json; T4 with the same loop; T5.\n' "$(v FLD_PLATFORM_CORE)"
  echo "VERIFY: describe shows 7200s and the role count PA-4.0 recorded; a condition per role at T3, NO-BINDING per role at T4."
  _p12_say_ev PA-4.2 ent-project-repair-core E-08 4.1.3 PA-4.2-grant.json
  echo "Then: agp-platform done PA-4.2 --witness $(v SA_2_ADMIN)      (PA-9.2's Owner removal depends on this step)"
}

step PA-4.3 HUMAN "Create and test ent-deploy-credential-holder-core in CORE_PROJECT" --witness \
  --needs "CORE_PROJECT CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" --sets "ENT_DEPLOY_CREDENTIAL_HOLDER_CORE"
s_PA_4_3_check() { _p12_manual_check PA-4.3 ent-deploy-credential-holder-core "--project=$(v CORE_PROJECT)"; }
s_PA_4_3_manual() {
  local p; p="--project=$(v CORE_PROJECT)"
  echo "WHO: the platform owner requests; the second human approves (T2). WHERE: shell; the second human's console."
  _p12_say_create ent-deploy-credential-holder-core "$p"
  _p12_say_pset ENT_DEPLOY_CREDENTIAL_HOLDER_CORE ent-deploy-credential-holder-core "$p"
  echo "Five minutes later, with pam.sh sourced: T1 (\"setup-12 PA-4.3 one-grant test\"), T2, T3 on projects $(v CORE_PROJECT)"
  echo "for roles/run.developer and roles/iam.serviceAccountUser, T4 (NO-BINDING twice), T5 (approved). Nothing is deployed."
  _p12_say_ev PA-4.3 ent-deploy-credential-holder-core E-08 5.2.1 PA-4.3-grant.json
  echo "Then: agp-platform done PA-4.3 --witness $(v SA_2_ADMIN)"
}

step PA-4.4 HUMAN "Create ent-secret-read-platform-pager-key and test its binding" --witness \
  --needs "CORE_PROJECT CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" --sets "ENT_SECRET_READ"
s_PA_4_4_check() { _p12_manual_check PA-4.4 ent-secret-read-platform-pager-key "--project=$(v CORE_PROJECT)"; }
s_PA_4_4_manual() {
  local p; p="--project=$(v CORE_PROJECT)"
  echo "WHO: the platform owner requests; the second human approves (T2). WHERE: shell; the second human's console."
  _p12_say_create ent-secret-read-platform-pager-key "$p"
  _p12_say_pset ENT_SECRET_READ ent-secret-read-platform-pager-key "$p"
  echo "Five minutes later, with pam.sh sourced: T1 (\"setup-12 PA-4.4 one-grant test\"), T2, T3 for roles/secretmanager.secretAccessor:"
  echo "one expression with request.time and platform-pager-key (two bindings: record the form). T4, T5."
  echo "Then the page's guarded printf line adds PA-8.4's condition test to $(v BUILD_LOG_DIR)/rerun-index.tsv, once."
  _p12_say_ev PA-4.4 ent-secret-read E-08 4.1.3 PA-4.4-grant.json
  echo "Then: agp-platform done PA-4.4 --witness $(v SA_2_ADMIN)"
}

step PA-4.5 HUMAN "Create and test ent-factory-singleton-psa-nonprod (dated, no approval)" --gate "SD-42" \
  --needs "FLD_AGENTS_P_SA_NONPROD CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" --sets "ENT_FACTORY_SINGLETON_PSA_NONPROD"
s_PA_4_5_check() { _p12_manual_check PA-4.5 ent-factory-singleton-psa-nonprod "--folder=$(v FLD_AGENTS_P_SA_NONPROD)"; }
s_PA_4_5_manual() {
  local f; f="--folder=$(v FLD_AGENTS_P_SA_NONPROD)"
  echo "WHO: the platform owner, alone (no approver: SD-42's dated variant), in the approval sitting. WHERE: shell."
  _p12_say_create ent-factory-singleton-psa-nonprod "$f"
  _p12_say_pset ENT_FACTORY_SINGLETON_PSA_NONPROD ent-factory-singleton-psa-nonprod "$f"
  echo "Five minutes later, with pam.sh sourced: T1 (\"setup-12 PA-4.5 one-grant test, no register row, no project created\"),"
  echo "T3 on the folder for the four singleton roles, T4, T5 (no approved event). No project is created."
  echo "VERIFY: no approvalWorkflow; requesters exactly factory-apply@ and platform-owners@; no-approval.json gives this id an end date."
  _p12_say_ev PA-4.5 ent-factory-singleton-psa-nonprod E-08 1.4.1 PA-4.5-grant.json
  echo "Then: agp-platform done PA-4.5"
}

step PA-4.6 HUMAN "Create and test ent-factory-singleton-ctl-prod and -ctl-nonprod" --witness --gate "SD-12" \
  --needs "FLD_CONTROLLERS_PROD FLD_CONTROLLERS_NONPROD CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" \
  --sets "ENT_FACTORY_SINGLETON_CTL_PROD ENT_FACTORY_SINGLETON_CTL_NONPROD"
s_PA_4_6_check() {
  _p12_manual_check PA-4.6 ent-factory-singleton-ctl-prod "--folder=$(v FLD_CONTROLLERS_PROD)" \
    ent-factory-singleton-ctl-nonprod "--folder=$(v FLD_CONTROLLERS_NONPROD)"
}
s_PA_4_6_manual() {
  local a b; a="--folder=$(v FLD_CONTROLLERS_PROD)"; b="--folder=$(v FLD_CONTROLLERS_NONPROD)"
  echo "WHO: the platform owner requests; the second human approves, never the platform owner (SD-12 item 2)."
  _p12_say_create ent-factory-singleton-ctl-prod "$a"
  _p12_say_create ent-factory-singleton-ctl-nonprod "$b"
  _p12_say_pset ENT_FACTORY_SINGLETON_CTL_PROD ent-factory-singleton-ctl-prod "$a"
  _p12_say_pset ENT_FACTORY_SINGLETON_CTL_NONPROD ent-factory-singleton-ctl-nonprod "$b"
  echo "Five minutes later, with pam.sh sourced: T1 for both (\"setup-12 PA-4.6 one-grant test\"), T2 for both, T3 on each folder"
  echo "for the four roles, T4, T5. VERIFY: the only approver principal in both describes is user:sa-2-admin@."
  _p12_say_ev PA-4.6 ent-factory-singleton-ctl E-08 4.2.1 PA-4.6-grant.json
  echo "Then: agp-platform done PA-4.6 --witness $(v SA_2_ADMIN)"
}

step PA-4.7 BLOCKED "Create and test ent-factory-singleton-psa-prod (two named approvers)" --witness --gate "PPL-SR SD-42" \
  --sets "ENT_FACTORY_SINGLETON_PSA_PROD" --note "B-20: security reviewer not named"
s_PA_4_7_check() { ckpt_done PA-4.7; }
s_PA_4_7_manual() {
  echo "BLOCKED on B-20: PPL-SR unsigned and SECURITY_REVIEWER_EMAIL unset. The run continues; nothing may create WALLE_PROJECT before it."
  echo "When tools/decision-need.sh PPL-SR prints SIGNED: re-run PA-2.1 and PA-2.2 (the generator adds the file), check SCC_TIER is"
  echo "PREMIUM/eu, then run the page's block (gate_scc, gcloud alpha pam entitlements create on fld-agents-p-sa-prod,"
  echo "penv_set ENT_FACTORY_SINGLETON_PSA_PROD); approvalsNeeded must read 2; both approvers approve; T3 to T5."
  echo "Record it in the sourced shell with: checkpoint PA-4.7 DONE <both approvers> build-log:evidence/12/PA-4.7-grant.json"
}

step PA-4.8 HUMAN "Create and test the three ent-bootstrap-module-* entitlements" --witness --gate "SD-46" \
  --needs "FLD_AGENTS_R_NONPROD FLD_IMPROVERS_PROD FLD_IMPROVERS_NONPROD CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" \
  --sets "ENT_BOOTSTRAP_MODULE_R_NONPROD ENT_BOOTSTRAP_MODULE_IMPROVERS_PROD ENT_BOOTSTRAP_MODULE_IMPROVERS_NONPROD"
s_PA_4_8_check() {
  _p12_manual_check PA-4.8 ent-bootstrap-module-r-nonprod "--folder=$(v FLD_AGENTS_R_NONPROD)" \
    ent-bootstrap-module-improvers-prod "--folder=$(v FLD_IMPROVERS_PROD)" \
    ent-bootstrap-module-improvers-nonprod "--folder=$(v FLD_IMPROVERS_NONPROD)"
}
s_PA_4_8_manual() {
  local a b c; a="--folder=$(v FLD_AGENTS_R_NONPROD)"; b="--folder=$(v FLD_IMPROVERS_PROD)"; c="--folder=$(v FLD_IMPROVERS_NONPROD)"
  echo "WHO: the platform owner requests; the second human approves (T2)."
  _p12_say_create ent-bootstrap-module-r-nonprod "$a"
  _p12_say_create ent-bootstrap-module-improvers-prod "$b"
  _p12_say_create ent-bootstrap-module-improvers-nonprod "$c"
  echo "Then the page's three penv_set lines (ENT_BOOTSTRAP_MODULE_R_NONPROD, _IMPROVERS_PROD, _IMPROVERS_NONPROD) from the describes."
  echo "Five minutes later, with pam.sh sourced: one full test (T1 to T5) on ent-bootstrap-module-improvers-prod; T1 to T4 for the other two."
  echo "VERIFY: each T3 shows four conditions on its own folder and NO-BINDING on the other two; each T4 NO-BINDING."
  _p12_say_ev PA-4.8 ent-bootstrap-module E-08 1.4.1 PA-4.8-grant.json
  echo "Then: agp-platform done PA-4.8 --witness $(v SA_2_ADMIN)"
}

step PA-4.9 HUMAN "Create and test ent-witness-export-repair (interim scope)" --witness \
  --needs "FLD_CONTROLLERS_PROD CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" --sets "ENT_WITNESS_EXPORT_REPAIR"
s_PA_4_9_check() { _p12_manual_check PA-4.9 ent-witness-export-repair "--folder=$(v FLD_CONTROLLERS_PROD)"; }
s_PA_4_9_manual() {
  local f; f="--folder=$(v FLD_CONTROLLERS_PROD)"
  echo "WHO: the platform owner requests (not the second human, who could not then be approved); the second human approves (T2)."
  _p12_say_create ent-witness-export-repair "$f"
  _p12_say_pset ENT_WITNESS_EXPORT_REPAIR ent-witness-export-repair "$f"
  echo "Five minutes later, with pam.sh sourced: T1 (\"setup-12 PA-4.9 one-grant test\"), T2, T3 for roles/iam.serviceAccountAdmin"
  echo "on the folder (one condition), T4, T5 (approved). Then the page's guarded printf line adds PA-8.3's re-scope to rerun-index.tsv, once."
  _p12_say_ev PA-4.9 ent-witness-export-repair E-08 4.2.1 PA-4.9-grant.json
  echo "Then: agp-platform done PA-4.9 --witness $(v SA_2_ADMIN)"
}

# ---------------------------------------------------------------- 5. Gemini Enterprise entitlements
step PA-5.1 HUMAN "Create and test ent-ge-admin (Tier C, no approval)" --gate "SD-19" \
  --needs "GEMINI_PROJECT CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" --sets "ENT_GE_ADMIN"
s_PA_5_1_check() { _p12_manual_check PA-5.1 ent-ge-admin "--project=$(v GEMINI_PROJECT)"; }
s_PA_5_1_manual() {
  local p; p="--project=$(v GEMINI_PROJECT)"
  echo "WHO: the platform owner, as a member of ge-admins@, alone (no approval at Tier C, SD-19), in the approval sitting."
  _p12_say_create ent-ge-admin "$p"
  _p12_say_pset ENT_GE_ADMIN ent-ge-admin "$p"
  echo "Five minutes later, with pam.sh sourced: T1 (\"setup-12 PA-5.1 one-grant test, no app change\"), T3 on projects $(v GEMINI_PROJECT)"
  echo "for roles/discoveryengine.agentspaceAdmin, T4, T5 (no approved). A standing agentspaceAdmin is recorded for 19, not removed."
  _p12_say_ev PA-5.1 ent-ge-admin E-08 4.1.3 PA-5.1-grant.json
  echo "Then: agp-platform done PA-5.1"
}

step PA-5.2 HUMAN "Create and test the ent-project-move pair" --witness \
  --needs "GE_CURRENT_PARENT FLD_GEMINI_ENTERPRISE CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR" \
  --sets "ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST"
s_PA_5_2_check() {
  _p12_manual_check PA-5.2 ent-project-move-src "$(_p12_parent_flag)" ent-project-move-dst "--folder=$(v FLD_GEMINI_ENTERPRISE)"
}
s_PA_5_2_manual() {
  local s d; d="--folder=$(v FLD_GEMINI_ENTERPRISE)"
  s="$(_p12_parent_flag)" || { echo "STOP: bad GE_CURRENT_PARENT '$(v GE_CURRENT_PARENT)' (05 sets organizations/<id> or folders/<id>)"; return 0; }
  echo "WHO: the platform owner requests; the second human approves both (T2). Nothing is moved here (19 GE-3)."
  _p12_say_create ent-project-move-src "$s"
  _p12_say_create ent-project-move-dst "$d"
  _p12_say_pset ENT_PROJECT_MOVE_SRC ent-project-move-src "$s"
  _p12_say_pset ENT_PROJECT_MOVE_DST ent-project-move-dst "$d"
  echo "Five minutes later, with pam.sh sourced: T1 for both (\"setup-12 PA-5.2 one-grant test, no move\"), T2 for both, T3 on"
  echo "$(v GE_CURRENT_PARENT) and on folders $(v FLD_GEMINI_ENTERPRISE) for roles/resourcemanager.projectMover, T4, T5 (both approved)."
  _p12_say_ev PA-5.2 ent-project-move E-08 4.2.1 PA-5.2-grant.json
  echo "Then: agp-platform done PA-5.2 --witness $(v SA_2_ADMIN)"
}

# ---------------------------------------------------------------- 6. Live catalogue, no-approval register, deviation rows
step PA-6.1 AUTO-READ "Prove the live catalogue equals the committed files" \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER CICD_PROJECT"
s_PA_6_1_check() { ckpt_done PA-6.1; }
s_PA_6_1_apply() {
  local out d; d="$(_p12_ev_dir)"
  _p12_mkev || return 1
  out="$(_p12_read python3 "$(v PLATFORM_REPO_DIR)/pam/tools/compare.py")"
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s\n' "$out" | xw "$d/PA-6.1-compare.txt" || return 1
  printf '%s\n' "$out" | sed 's/^/        /' >&3
  if printf '%s\n' "$out" | grep -qE '^(DIFF|EXTRA) ' || [ "$(printf '%s\n' "$out" | sed '/^$/d' | tail -n 1)" != "CATALOGUE ZERO DIFF" ]; then
    agp_say "      STOP: a DIFF is fixed on the live side from the committed file (export, update with the etag); an EXTRA goes to the second human"
    return 1
  fi
  ev PA-6.1 catalogue-zero-diff E-05 4.2.1 "build-log:evidence/12" "$d/PA-6.1-compare.txt"
}

step PA-6.2 AUTO "Record every no-approval entitlement" --witness \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER CICD_PROJECT"
_p12_matrix_ok() {  # the approval matrix shows NO-APPROVAL on exactly the ids of no-approval.json
  local m; m="$(_p12_ev_dir)/PA-6.2-approval-matrix.txt"
  [ -s "$m" ] || return 1
  [ "$(awk '$2 == "NO-APPROVAL" {print $1}' "$m" | sort | paste -sd, -)" = "$(_p12_noappr_tsv | cut -f1 | sort | paste -sd, -)" ]
}
s_PA_6_2_check() {
  local want got
  ckpt_done PA-6.2 && return 0
  [ -f "$(v PLATFORM_REPO_DIR)/pam/no-approval.json" ] && [ -f "$(v DEVIATION_REGISTER)" ] || return 1
  want="$(_p12_noappr_tsv | wc -l | tr -d ' ')"
  got="$(grep -c 'no-approval PAM entitlement' "$(v DEVIATION_REGISTER)")"
  [ "$want" = 6 ] && [ "$got" = "$want" ] && _p12_matrix_ok
}
s_PA_6_2_apply() {
  local reg na n id scope ends kind ident alt var file a fl list out m
  reg="$(v DEVIATION_REGISTER)"; na="$(v PLATFORM_REPO_DIR)/pam/no-approval.json"; m="$(_p12_ev_dir)/PA-6.2-approval-matrix.txt"
  _p12_mkev || return 1
  if [ ! -f "$na" ]; then
    [ "$AGP_MODE" = apply ] && { agp_say "      STOP: $na is missing (PA-2.1, PA-2.2)"; return 1; }
    agp_say "      would insert one BD-12-<n> row per entry of pam/no-approval.json (six) with bd_insert, then read the approval matrix"
    return 0
  fi
  list="$(mktemp "${TMPDIR:-/tmp}/agp-p12.XXXXXX")" || return 1
  _p12_noappr_tsv > "$list" || { rm -f "$list"; return 1; }
  n=$(( $(_p12_bd_count) + 1 ))
  while IFS="$(printf '\t')" read -r id scope ends; do
    if [ -f "$reg" ] && grep -qF "| no-approval PAM entitlement $id |" "$reg"; then agp_say "      row for $id present"; continue; fi
    x bd_insert "$(printf '| %s | %s | 12 PA-6.2 | DEV | no-approval PAM entitlement %s | %s | pam/no-approval.json | activation without approver; justification mandatory; platform-security@ notified | n/a | n/a | second human (PA-2.2) | %s | open |' \
      "$(_p12_bd_id "$n")" "$(date -u +%F)" "$id" "$scope" "$ends")" || { rm -f "$list"; return 1; }
    n=$((n + 1))
  done < "$list"
  rm -f "$list"
  if [ "$AGP_MODE" = apply ]; then
    a="$(grep -c 'no-approval PAM entitlement' "$reg")"
    [ "$a" = 6 ] || { agp_say "      STOP: $a no-approval rows in the deviation register, not 6"; return 1; }
  fi
  # the approval matrix: one line per entitlement of the committed index
  list="$(mktemp "${TMPDIR:-/tmp}/agp-p12.XXXXXX")" || return 1
  tail -n +2 "$(v PLATFORM_REPO_DIR)/pam/index.tsv" > "$list" 2>/dev/null
  out=""
  while IFS="$(printf '\t')" read -r id kind ident alt var file; do
    [ -n "$id" ] || continue
    fl="$(_p12_flag "$kind" "$ident")" || { rm -f "$list"; agp_say "      index row $id: unknown kind $kind"; return 1; }
    # the page's describe of approvalsNeeded, as filtered lists that print something: an id of no-approval.json must list
    # with no approvalWorkflow, every other id with one; a list that prints nothing is the opposite state (or no entitlement)
    if _p12_noappr_tsv | cut -f1 | grep -qx -- "$id"; then
      a="$(_p12_read gcloud pam entitlements list "$fl" --location=global --billing-project="$(v CICD_PROJECT)" \
        --filter="name~/entitlements/$id\$ AND -approvalWorkflow:*" --format='value(name)' < /dev/null)"
      [ -n "$a" ] && a=NO-APPROVAL || a=APPROVAL-OR-ABSENT
    else
      a="$(_p12_read gcloud pam entitlements list "$fl" --location=global --billing-project="$(v CICD_PROJECT)" \
        --filter="name~/entitlements/$id\$ AND approvalWorkflow:*" --format='value(approvalWorkflow.manualApprovals.steps[0].approvalsNeeded)' < /dev/null)"
      a="$(printf '%s' "$a" | head -n 1)"
    fi
    out="$out$id ${a:-NO-APPROVAL}
"
  done < "$list"
  rm -f "$list"
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s' "$out" | xw "$m" || return 1
  printf '%s' "$out" | sed 's/^/        /' >&3
  _p12_matrix_ok || { agp_say "      STOP: NO-APPROVAL is not on exactly the six ids of no-approval.json"; return 1; }
  ev PA-6.2 no-approval-register E-05 1.4.1 "build-log:evidence/12" "$m"
}

step PA-6.3 AUTO "Record the catalogue deviations and commit the registers" --witness \
  --needs "DEVIATION_REGISTER BUILD_LOG_DIR EVIDENCE_REGISTER FLD_PLATFORM_CORE CORE_PROJECT FLD_CONTROLLERS_PROD ORG_ID"
# As the page does, a row whose description is already in the register is not inserted again (bd_insert itself refuses only
# an existing id), so a resumed run adds no duplicate under a new id.
_p12_pa63_rows() {  # what|scope|ends, one per line: the six deviations of PA-2.1's table, as the page writes them
  printf '%s\n' \
    "approver second human where 04 names the security reviewer|all entitlements with approvalWorkflow|PA-8.1" \
    "ent-project-repair-core: one folder entitlement, 04 bundle plus eight core roles|folders/$(v FLD_PLATFORM_CORE)|04 amendment; 42 quarterly review" \
    "ent-deploy-credential-holder: serviceAccountUser unconditioned on the project|template and projects/$(v CORE_PROJECT)|Google documents a service-account resource attribute" \
    "ent-factory-singleton-*: platform-owners@ as bootstrap requester|fld-agents-p-sa-*, fld-controllers-*|PA-8.5 at supersession, Tier W at the latest" \
    "ent-witness-export-repair on fld-controllers-prod|folders/$(v FLD_CONTROLLERS_PROD)|PA-8.3 when EVE_PROJECT exists" \
    "ent-pam-catalogue-org added to 04 section 5.2|organizations/$(v ORG_ID)|04 amendment ratifies"
}
_p12_pa63_has() {   # WHAT: the register's first table has a PA-6.3 row with this description
  local f; f="$(v DEVIATION_REGISTER)"
  [ -f "$f" ] && grep -qF "| 12 PA-6.3 | DEV | $1 |" "$f"
}
_p12_pa63_verify() {    # the page's VERIFY: 13 BD-12 rows, each above the Closures heading
  local f n c bad
  f="$(v DEVIATION_REGISTER)"
  n="$(grep -c '^| BD-12-' "$f")"
  c="$(awk '/^## Closures$/{print NR; exit}' "$f")"
  bad="$(awk -F' *[|] *' -v c="${c:-0}" '$2 ~ /^BD-12-/ && NF == 15 && (c == 0 || NR > c) {print NR, $2}' "$f")"
  [ "$n" = 13 ] && [ -n "$c" ] && [ -z "$bad" ] && return 0
  agp_say "      $n BD-12 rows (13 expected: BD-12-01, six no-approval rows, six deviation rows); Closures heading at line ${c:-none}"
  [ -z "$bad" ] || agp_say "      rows not above the Closures heading: $(printf '%s' "$bad" | tr '\n' ' ')"
  return 1
}
s_PA_6_3_check() {
  local what scope ends
  ckpt_done PA-6.3 && return 0
  [ -f "$(v DEVIATION_REGISTER)" ] || return 1
  while IFS='|' read -r what scope ends; do
    _p12_pa63_has "$what" || return 1
  done <<EOF_PA63
$(_p12_pa63_rows)
EOF_PA63
  _p12_pa63_verify >/dev/null 3>&1 || return 1
  [ -z "$(git -C "$(v BUILD_LOG_DIR)" status --porcelain -- rerun-index.tsv 2>/dev/null)" ]
}
s_PA_6_3_apply() {
  local what scope ends n log
  log="$(v BUILD_LOG_DIR)"
  n=$(( $(_p12_bd_count) + 1 ))
  while IFS='|' read -r what scope ends; do
    if [ "$AGP_MODE" = apply ] && _p12_pa63_has "$what"; then agp_say "      row present: $what"; continue; fi
    x bd_insert "$(printf '| %s | %s | 12 PA-6.3 | DEV | %s | %s | catalogue commit | see setup/12 PA-2.1 | n/a | n/a | second human (PA-2.2) | %s | open |' \
      "$(_p12_bd_id "$n")" "$(date -u +%F)" "$what" "$scope" "$ends")" || return 1
    n=$((n + 1))
  done <<EOF_PA63
$(_p12_pa63_rows)
EOF_PA63
  if [ -f "$log/rerun-index.tsv" ] || [ "$AGP_MODE" != apply ]; then
    x git -C "$log" add rerun-index.tsv || return 1
    if [ "$AGP_MODE" != apply ] || ! git -C "$log" diff --cached --quiet -- rerun-index.tsv; then
      x git -C "$log" commit -m "setup 12: re-run index at PA-6.3" -- rerun-index.tsv || return 1
    fi
  fi
  [ "$AGP_MODE" = apply ] || { agp_say "      check: 13 BD-12 rows in the register, each above its Closures heading"; return 0; }
  _p12_pa63_verify || { agp_say "      STOP: the register does not hold the thirteen BD-12 rows the page expects (PA-1.1, PA-6.2, PA-6.3)"; return 1; }
  _p12_mkev || return 1
  awk -F' *[|] *' '$2 ~ /^BD-12-/ && NF == 15 {print NR, $2}' "$(v DEVIATION_REGISTER)" | xw "$(_p12_ev_dir)/PA-6.3-bd12-rows.txt" || return 1
  agp_say "      the second human signs the review record of the BD-12-<n> opened commits of PA-6.2 and PA-6.3 (01 convention)"
  ev PA-6.3 pam-deviations E-05 1.4.1 "build-log:evidence/12" "$(_p12_ev_dir)/PA-6.3-bd12-rows.txt"
}

# ---------------------------------------------------------------- 7. Handover to logging and detection
step PA-7.1 AUTO "Record what the audit trail and the detections must watch" --needs "BUILD_LOG_DIR"
s_PA_7_1_check() {
  local f; f="$(v BUILD_LOG_DIR)/rerun-index.tsv"
  ckpt_done PA-7.1 && return 0
  [ -f "$f" ] || return 1
  [ "$(awk -F'\t' '$2 == "PA-7.1"' "$f" | wc -l | tr -d ' ')" = 4 ]
}
s_PA_7_1_apply() {
  _p12_rerun_add PA-7.1 "file 14" "S-org carries privilegedaccessmanager.googleapis.com Admin Activity entries; verify one PA-8 grant arrives in platform-evidence-logs" "file not yet run" || return 1
  _p12_rerun_add PA-7.1 "file 15" "page the second human and the desk on any activation of ENT_K7_HUMAN or ENT_K7_HUMAN_SCHEDULER; severity 2 on ENT_PAM_CATALOGUE_ORG or ENT_FOLDER_ADMIN use outside a change window; severity 1 on CreateEntitlement, UpdateEntitlement or DeleteEntitlement not matching a merged pam/ commit" "file not yet run" || return 1
  _p12_rerun_add PA-7.1 "file 16" "drift job runs pam/tools/compare.py and pam/tools/sweep.py daily; register imports pam/no-approval.json" "file not yet run" || return 1
  _p12_rerun_add PA-7.1 "file 25" "Eve self-integrity: any entitlement change on EVE_PROJECT or fld-controllers-* scopes, and any grant whose externallyModified is true" "file not yet run"
}

# ---------------------------------------------------------------- 8. Re-run steps (not part of this sitting)
step PA-8.1 BLOCKED "When the security reviewer is appointed: add them to the approver sets" --witness --note "B-20: security reviewer not named"
s_PA_8_1_check() { ckpt_done PA-8.1; }
s_PA_8_1_manual() {
  echo "BLOCKED on B-20 until tools/decision-need.sh PPL-SR prints SIGNED; gate waiting: G19, file 31, the dated end of the"
  echo "no-approval variant of ent-factory-singleton-psa-nonprod. Runs after PA-9.3, under ent-pam-catalogue-org or ent-folder-admin"
  echo "grants approved by the second human: PA-4.7, then catalogue.py by reviewed pull request, then export, etag and update of each"
  echo "live entitlement (setup/12 PA-8.1), compare.py at zero diff, and bd_close of the two no-approval rows it ends."
}

step PA-8.2 HUMAN "After the Gemini Enterprise import (19 GE-3): delete the move pair" --witness --on-unmet skip --removes \
  --needs "FLD_GEMINI_ENTERPRISE CICD_PROJECT PLATFORM_REPO_DIR"
s_PA_8_2_check() { ckpt_done PA-8.2; }
s_PA_8_2_manual() {
  echo "A re-run step: only after 19 GE-3 has moved GEMINI_PROJECT. The run continues past it."
  echo "WHO: the platform owner, under an ent-pam-catalogue-org grant (organisation-scoped source) or ent-folder-admin (a source"
  echo "under the tree), approved by the second human. Revoke any active grant of the pair first."
  echo "\$ gcloud pam entitlements delete ent-project-move-src $(_p12_parent_flag || echo '<scope of GE_CURRENT_PARENT>') --location=global --billing-project=$(v CICD_PROJECT)"
  echo "\$ gcloud pam entitlements delete ent-project-move-dst --folder=$(v FLD_GEMINI_ENTERPRISE) --location=global --billing-project=$(v CICD_PROJECT)"
  echo "Remove both files and both rows of catalogue.py in one reviewed pull request; VERIFY: compare.py at zero diff without them."
  echo "Then: agp-platform done PA-8.2 --witness $(v SA_2_ADMIN)"
}

step PA-8.3 HUMAN "When EVE_PROJECT exists (23): re-scope ent-witness-export-repair" --witness --on-unmet skip --removes \
  --needs "FLD_CONTROLLERS_PROD CICD_PROJECT" --sets "ENT_WITNESS_EXPORT_REPAIR"
s_PA_8_3_check() { ckpt_done PA-8.3; }
s_PA_8_3_manual() {
  echo "A re-run step: only once 23 has created EVE_PROJECT. The run continues past it."
  echo "WHO: the platform owner under an ent-folder-admin grant approved by the second human. Change the row in catalogue.py to"
  echo "(\"projects\", EVE_PROJECT), merge after review, create it with --project=\"\$EVE_PROJECT\", penv_set --force ENT_WITNESS_EXPORT_REPAIR"
  echo "with a build-log line, test it (T1 to T5), delete the folder-scoped one with --folder=$(v FLD_CONTROLLERS_PROD), close its BD-12 row."
  echo "VERIFY: compare.py zero diff; gcloud pam entitlements list --folder=$(v FLD_CONTROLLERS_PROD) --location=global no longer lists it."
  echo "Then: agp-platform done PA-8.3 --witness $(v SA_2_ADMIN)"
}

step PA-8.4 HUMAN "When a secret, an agent project or a folder needs its entitlement" --witness --on-unmet skip
s_PA_8_4_check() { ckpt_done PA-8.4; }
s_PA_8_4_manual() {
  echo "A re-run step, run by the file that creates the resource (15, 17, 22, 23, 24, 31, 32). The run continues past it."
  echo "Instantiate the template with setup/12 PA-8.4's python block (never by hand-editing JSON), create it under the scope's"
  echo "IAM-admin grant, test it (T1 to T5), add the row to pam/index.tsv; the approver is never a member of the requester group."
  echo "15's case is a test of ENT_SECRET_READ with testIamPermissions on the secret; never versions access."
  echo "Then: agp-platform done PA-8.4 --witness <the approver that file's row names>"
}

step PA-8.5 BLOCKED "When the factory exists: supersede the bootstrap entitlements" --witness --removes --note "B-01: factory not committed"
s_PA_8_5_check() { ckpt_done PA-8.5; }
s_PA_8_5_manual() {
  echo "BLOCKED on B-01 until the factory modules and 17's empty-plan record exist. Then: terraform import of each entitlement and"
  echo "an empty plan, delete ent-bootstrap-module-*, remove platform-owners@ from the ent-factory-singleton-* requesters, and"
  echo "bd_close each BD-12 row it supersedes (setup/12 PA-8.5)."
}

# ---------------------------------------------------------------- 9. Withdrawal
step PA-9.1 AUTO-READ "Sweep before the withdrawal" --witness \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER ORG_ID SA_1_ADMIN GRP_PLATFORM_OWNERS GRP_GCP_ORG_ADMINS CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT GEMINI_PROJECT ENT_PLATFORM_POLICY ENT_ORG_SINK ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER ENT_K7_EXECUTOR ENT_K7_EXECUTOR_SCHEDULER ENT_PAM_CATALOGUE_ORG ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CORE ENT_DEPLOY_CREDENTIAL_HOLDER_CORE ENT_SECRET_READ ENT_FACTORY_SINGLETON_PSA_NONPROD ENT_FACTORY_SINGLETON_CTL_PROD ENT_FACTORY_SINGLETON_CTL_NONPROD ENT_BOOTSTRAP_MODULE_R_NONPROD ENT_BOOTSTRAP_MODULE_IMPROVERS_PROD ENT_BOOTSTRAP_MODULE_IMPROVERS_NONPROD ENT_WITNESS_EXPORT_REPAIR ENT_GE_ADMIN ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST"
s_PA_9_1_check() { ckpt_done PA-9.1; }
_p12_actas() {  # LABEL RESOURCE: user:, group: or domain: members of the two actAs roles in the policy on stdin
  python3 -c '
import json, sys
label, res = sys.argv[1], sys.argv[2]
raw = sys.stdin.read()
for b in (json.loads(raw) if raw.strip() else {}).get("bindings", []) or []:
    if b.get("role") in ("roles/iam.serviceAccountUser", "roles/iam.serviceAccountTokenCreator"):
        for m in b.get("members", []):
            if m.split(":", 1)[0] in ("user", "group", "domain"):
                print(label, res, b["role"], m, (b.get("condition") or {}).get("title", "no-condition"))
' "$1" "$2"
}
s_PA_9_1_apply() {
  local d p pr cmp list eid kind ident alt var file fl out g grants="" sweep actas="" pol sa bad=0 porc
  d="$(_p12_ev_dir)"; p="$(v PLATFORM_REPO_DIR)"
  _p12_mkev || return 1
  # 1. the live catalogue
  cmp="$(_p12_read python3 "$p/pam/tools/compare.py")"
  # 2. every entitlement of the index searched for a grant still ACTIVE
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read, per row of pam/index.tsv: gcloud pam grants search --entitlement=<id> --location=global --<scope>=<id> --caller-relationship=had-created --billing-project=$(v CICD_PROJECT) --filter=state=ACTIVE --format=value(name)"
  else
    list="$(mktemp "${TMPDIR:-/tmp}/agp-p12.XXXXXX")" || return 1
    tail -n +2 "$p/pam/index.tsv" > "$list" || { rm -f "$list"; agp_say "      STOP: cannot read $p/pam/index.tsv"; return 1; }
    while IFS="$(printf '\t')" read -r eid kind ident alt var file; do
      [ -n "$eid" ] || continue
      if ! has_value "$var"; then grants="${grants}SKIP $eid ($var unset)
"; continue; fi
      fl="$(_p12_flag "$kind" "$ident")" || { grants="${grants}UNREADABLE $eid (kind $kind)
"; continue; }
      if out="$(r gcloud pam grants search --entitlement="$eid" --location=global "$fl" --caller-relationship=had-created \
                --billing-project="$(v CICD_PROJECT)" --filter="state=ACTIVE" --format="value(name)")"; then
        for g in $out; do grants="${grants}ACTIVE GRANT $eid $g
"; done
        grants="${grants}SEARCHED $eid
"
      else
        grants="${grants}UNREADABLE $eid
"
      fi
    done < "$list"
    rm -f "$list"
  fi
  # 3. the standing-role sweep
  sweep="$(_p12_read python3 "$p/pam/tools/sweep.py")"
  # 4. actAs, project-level and account-level, on the five core projects
  for pr in "$(v CICD_PROJECT)" "$(v CORE_PROJECT)" "$(v LOGGING_PROJECT)" "$(v KMS_PROJECT)" "$(v VALIDATOR_PROJECT)"; do
    pol="$(_p12_read gcloud projects get-iam-policy "$pr" --format=json)"
    if [ "$AGP_MODE" != apply ]; then
      agp_say "      read, per service account of $pr: gcloud iam service-accounts get-iam-policy <email> --project=$pr --format=json"
      continue
    fi
    actas="$actas$(printf '%s' "$pol" | _p12_actas ACTAS-PROJECT "$pr")"
    for sa in $(r gcloud iam service-accounts list --project="$pr" --format="value(email)"); do
      actas="$actas$(r gcloud iam service-accounts get-iam-policy "$sa" --project="$pr" --format=json | _p12_actas ACTAS-ACCOUNT "$sa")"
    done
  done
  porc="$(_p12_read git -C "$p" status --porcelain pam)"
  [ "$AGP_MODE" = apply ] || return 0

  printf '%s' "$grants" | xw "$d/PA-9.1-active-grants.txt" || return 1
  printf '%s\n' "$sweep" | xw "$d/PA-9.1-sweep.txt" || return 1
  printf '%s' "$actas" | xw "$d/PA-9.1-actas.txt" || return 1
  printf '%s\n' "$grants" "$sweep" "$actas" | sed '/^$/d; s/^/        /' >&3

  [ "$(printf '%s\n' "$cmp" | sed '/^$/d' | tail -n 1)" = "CATALOGUE ZERO DIFF" ] || { agp_say "      STOP: compare.py does not print CATALOGUE ZERO DIFF"; bad=1; }
  if printf '%s' "$grants" | grep -q '^ACTIVE GRANT '; then
    agp_say "      STOP: a grant is still ACTIVE: pam_revoke it with the second human watching, record why, re-run this step"; bad=1
  fi
  if printf '%s' "$grants" | grep -q '^UNREADABLE '; then agp_say "      STOP: a grant search failed (UNREADABLE above)"; bad=1; fi
  if printf '%s' "$grants" | grep '^SKIP ' | grep -qv '^SKIP ent-factory-singleton-psa-prod '; then
    agp_say "      STOP: a SKIP for an entitlement this sitting created: a variable was lost and the search did not happen"; bad=1
  fi
  python3 - "$d/PA-9.1-sweep.txt" "$(v ORG_ID)" "$(v SA_1_ADMIN)" "group:$(v GRP_PLATFORM_OWNERS)" "group:$(v GRP_GCP_ORG_ADMINS)" \
    "$(v CICD_PROJECT)" "$(v CORE_PROJECT)" "$(v LOGGING_PROJECT)" "$(v KMS_PROJECT)" "$(v VALIDATOR_PROJECT)" >&3 <<'PY' || bad=1
import sys
org, sa1, owners, breakglass = sys.argv[2:6]
core = {"projects/" + p for p in sys.argv[6:11]}
five = {"roles/resourcemanager.organizationAdmin", "roles/resourcemanager.projectCreator", "roles/resourcemanager.folderCreator",
        "roles/privilegedaccessmanager.admin", "roles/iam.securityAdmin"}
lines = [l for l in open(sys.argv[1]).read().splitlines() if l.strip()]
viol, owner, allowed, bad = set(), set(), [], []
for l in lines:
    p = l.split()
    tag = p[0]
    if tag == "VIOLATION" and len(p) >= 5 and p[1] == "organizations/" + org and p[2] in five and p[3] == "user:" + sa1 \
            and " ".join(p[4:]) == "bootstrap-exception-sd-01":
        viol.add(p[2])
    elif tag == "OWNER" and len(p) >= 4 and p[1] in core and p[2] == "roles/owner" and p[3] == "user:" + sa1:
        owner.add(p[1])
    elif tag == "ALLOWED" and len(p) >= 4:
        allowed.append((p[1], p[2], p[3]))
    elif tag == "ALLOWED-BREAKGLASS":
        print("      read against 06 OB-7.1: " + l)
    elif tag == "OWNER-TOLERATED" or l in ("SWEEP CLEAN", "SWEEP NOT CLEAN"):
        pass
    else:
        bad.append(l)
want_allowed = sorted([("organizations/" + org, "roles/privilegedaccessmanager.admin", owners),
                       ("organizations/" + org, "roles/privilegedaccessmanager.admin", breakglass)])
ok = True
if bad:
    ok = False; print("      STOP: unexpected sweep lines:"); [print("        " + b) for b in bad]
if viol != five:
    ok = False; print("      STOP: the five bootstrap-exception VIOLATION lines are not all there: missing %s" % sorted(five - viol))
if owner != core:
    ok = False; print("      STOP: an OWNER line of a core project is missing: %s" % sorted(core - owner))
if sorted(allowed) != want_allowed:
    ok = False; print("      STOP: the ALLOWED lines are not exactly the two PAM Admin rows of role-allow.tsv: %s" % allowed)
if not lines or lines[-1] != "SWEEP NOT CLEAN":
    ok = False; print("      STOP: the sweep's last line is not SWEEP NOT CLEAN, which is expected before the withdrawal")
sys.exit(0 if ok else 1)
PY
  [ -z "$actas" ] || { agp_say "      STOP: PA-9.1-actas.txt is not empty: a standing actAs path exists (S143)"; bad=1; }
  [ -z "$porc" ] || { agp_say "      STOP: git status --porcelain pam prints: $porc"; bad=1; }
  [ $bad = 0 ] || return 1
  ev PA-9.1 sweep-before-withdrawal E-05 4.2.1 "build-log:evidence/12" "$d/PA-9.1-sweep.txt" || return 1
  ev PA-9.1 active-grant-search E-05 4.2.1 "build-log:evidence/12" "$d/PA-9.1-active-grants.txt"
}

step PA-9.2 HUMAN "Remove the creator's Owner from the five core projects, and prove the repair path" --witness --removes \
  --needs "SA_1_ADMIN SA_2_ADMIN CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT KMS_PROJECT_NUMBER VALIDATOR_PROJECT ENT_PROJECT_REPAIR_CORE PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_PA_9_2_check() { ckpt_done PA-9.2; }
s_PA_9_2_manual() {
  echo "WHO: the platform owner removes and requests; the second human ($(v SA_2_ADMIN)) witnesses and approves the proof grant."
  echo "Gate: PA-4.2 DONE (agp-platform status; the repair path is proven) and the kept-Owner entry of 10 CP-8.2 still open."
  echo "WHERE: shell, ~/.platform-env sourced. Paste setup/12 PA-9.2's first block: gate_pa42 guards a set -e subshell that saves each"
  echo "policy to PA-9.2-before-<p>.json and removes user:$(v SA_1_ADMIN) roles/owner (--condition=None) from $(v CICD_PROJECT),"
  echo "$(v CORE_PROJECT), $(v LOGGING_PROJECT), $(v KMS_PROJECT), $(v VALIDATOR_PROJECT); then tip on projects/$(v KMS_PROJECT_NUMBER) and the ENT_PROJECT_REPAIR_CORE request."
  echo "The second human approves; pam_wait \"\$g\" ACTIVE; the same tip again; T4 and T5 with <step>=PA-9.2."
  echo "VERIFY: no user:, group: or domain: roles/owner on the five; the first tip lacks cloudkms.keyRings.create, the second lists it."
  echo "\$ bd_close BD-10-6 \"withdrawal: 12 PA-9.2\" \"12 PA-9.3\""
  _p12_say_ev PA-9.2 core-owner-removed E-05 4.2.1 PA-9.2-grant.json
  echo "Then: agp-platform done PA-9.2 --witness $(v SA_2_ADMIN)"
}

step PA-9.3 HUMAN "Withdraw the organisation exception from sa-1-admin@" --gate "SD-01" --witness --removes --irreversible \
  --needs "ORG_ID SA_1_ADMIN SA_2_ADMIN ENT_PAM_CATALOGUE_ORG PLATFORM_REPO_DIR ROSTER_FILE BUILD_LOG_DIR DEVIATION_REGISTER FLD_AGENTS_R_NONPROD"
s_PA_9_3_check() { ckpt_done PA-9.3; }
s_PA_9_3_manual() {
  echo "IRREVERSIBLE for the platform owner alone. WHO: the platform owner; witness: the second human ($(v SA_2_ADMIN)), who approves"
  echo "the verification grant and merges the roster pull request. Before: PA-9.1, PA-9.2 and PA-3.6 DONE; no ACTIVE GRANT in"
  echo "PA-9.1-active-grants.txt; the second human able to approve within the hour. Paste setup/12 PA-9.3's first block: gate_pa92 guards"
  echo "the five removals from user:$(v SA_1_ADMIN) on organizations/$(v ORG_ID), each with --condition-from-file=$(v PLATFORM_REPO_DIR)/identity/bootstrap-exception-condition.yaml,"
  echo "folderCreator, projectCreator, PAM Admin, Security Admin, then Organization Administrator last. Then request ENT_PAM_CATALOGUE_ORG;"
  echo "after approval run the page's sweep, policy read, revoke, record, and the roster branch on $(v PLATFORM_REPO_DIR)/$(v ROSTER_FILE)."
  echo "VERIFY: SWEEP CLEAN with exactly two ALLOWED lines; no bootstrap-exception-sd-01 in PA-9.3-after.json; the roster pull request"
  echo "merged and gcp_org_roles of sa-1-admin@ of length 0; the negative folder create under $(v FLD_AGENTS_R_NONPROD) refused."
  echo "\$ bd_close BD-06-1 \"withdrawal: 12 PA-9.3 (five roles); Owner on core projects: 12 PA-9.2\" \"12 PA-9.3 VERIFY (sweep clean)\""
  _p12_say_ev PA-9.3 exception-withdrawn E-05 4.2.1 PA-9.3-sweep.txt
  echo "Then: agp-platform done PA-9.3 --witness $(v SA_2_ADMIN) --note \"organisation exception withdrawn\" (it writes the page's checkpoint)"
}
