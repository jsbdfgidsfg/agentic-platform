# phases/15-pager-siem-and-detections.sh: setup/15, the paging escalations, the Cloud Monitoring
# channels, the acknowledgement tests, the SCC notification route (part A) and the SIEM (part B).
#
# How the page maps onto the classes:
# - Everything done in the paging tool, every test with a second person, and every step run by an
#   IT security administrator on their own workstation is HUMAN: the script never holds a paging-tool
#   role, never opens a subject service and never signs in as IT security.
# - PS-4.2, PS-4.3 and PS-4.4 handle the paging integration key (added by IT security, then read from
#   Secret Manager into two channels). No secret passes through the script, so all three are HUMAN.
# - PS-2.7, PS-3.1, PS-5.1, PS-5.5 and PS-6.5 write files the page carries as heredocs. The script does
#   not retype a page's heredoc (lib/PHASES.md, "Files copied from a page"); until those bodies are
#   saved in assets/ with a 15.manifest, the person runs the page's block, and the step is HUMAN.
# - The deterministic Cloud work (the PAM grant, the email channels, the topic and subscription, the
#   temporary topic grant and its removal, disabling the test policy) is AUTO; the preflight and the
#   channel inventory are AUTO-READ. PS-4.1's grant is approved by the second human (12 set that
#   approver on ENT_PROJECT_REPAIR_CORE), so the step is AUTO --witness, as 16 RG-5.2 and 18 KS-1.2.
# - Part B: every step PS-7.1 to PS-8.10 is BLOCKED, as the page and README section 8 (B-05, B-06) register
#   them: the SIEM contract (P10), the rule code, H-2 and the K7 job. A BLOCKED step does not hold the run
#   (nothing in files 16 to 37 waits for part B, README section 3) and the runner writes its BLOCKED line.
#   Each _manual says what people do once it is unblocked; the phase file then changes the step's class.
# - The page uses "### PS-1 Preflight" and the like as section headings at the same level as its
#   steps. The phase scope "PS-[0-9]+\." keeps the registered ids to the 54 numbered steps.
#
# Helpers are prefixed _p15_ because every phase file is loaded into the same shell.

phase 15 "Paging, SCC notifications, the SIEM and the detections" "15-pager-siem-and-detections.md" "PS-[0-9]+\."

P15_REPAIR_WHY="setup 15 PS-4 to PS-6: channels, topic, secret, alert policies in the core projects"

# ---------------------------------------------------------------- helpers
_p15_today()  { date -u +%Y-%m-%d; }
_p15_ev_dir() { printf '%s/evidence/15' "$(v BUILD_LOG_DIR)"; }
_p15_plan()   { [ "$AGP_MODE" = apply ] || printf '      %s\n' "$*" >&3; }

_p15_sleep() {  # SECONDS: a poll interval, multiplied by AGP_WAIT_SCALE (a whole number, 1 when unset; 0 in the tests)
  local f="${AGP_WAIT_SCALE:-1}"
  case "$f" in ''|*[!0-9]*) f=1;; esac
  sleep $(($1 * f))
}

_p15_mkev() {   # the evidence directory of PS-1.1, made again if a step runs on its own
  local d; d="$(_p15_ev_dir)"
  if [ "$AGP_MODE" = apply ] && [ -d "$d" ]; then return 0; fi
  x mkdir -p "$d"
}

_p15_record() { # STEP SLUG E-ID TISAX EXT: standard input saved as evidence/15/<date>-STEP-SLUG-v1.EXT and registered
  local f; f="$(_p15_ev_dir)/$(_p15_today)-$1-$2-v1.$5"
  _p15_mkev || return 1
  xw "$f" 644 || return 1
  ev "$1" "$2" "$3" "$4" "build-log:evidence/15/$(basename "$f")" "$f"
}

_p15_grant_has() {  # ENTITLEMENT FILTER: a grant the caller created on it matches FILTER (0 yes, 1 no, 2 error, 3 offline)
  nonempty r gcloud pam grants search --entitlement="$1" --caller-relationship=had-created \
    --filter="$2" --format='value(name)' --billing-project="$(v CICD_PROJECT)"
}

_p15_grant() {  # ENT_NAME SECONDS JUSTIFICATION [RECIPIENT_NAME]: an ACTIVE grant of the caller, requested once and awaited
  local ent rc i=0 extra=""
  ent="$(v "$1")"
  [ -z "${4-}" ] || extra="--additional-email-recipients=$(v "$4")"
  if [ "$AGP_MODE" != apply ]; then
    x gcloud pam grants create --entitlement="$ent" --requested-duration="${2}s" --justification="$3" ${extra:+"$extra"} \
      --billing-project="$(v CICD_PROJECT)" --format='value(name)'
    _p15_plan "then waits until the approver 12 named approves (state ACTIVE); nothing privileged runs before"
    return 0
  fi
  _p15_pre _p15_grant_has "$ent" 'state=ACTIVE'; rc=$?
  if [ $rc -eq 0 ]; then echo "an ACTIVE grant on $1 exists; not requested again"; return 0; fi
  [ $rc -eq 1 ] || return 2
  _p15_pre _p15_grant_has "$ent" 'state=APPROVAL_AWAITED OR state=SCHEDULED OR state=ACTIVATING'; rc=$?
  case $rc in
    0) echo "a grant on $1 is already waiting for approval; not requested again";;
    1) x gcloud pam grants create --entitlement="$ent" --requested-duration="${2}s" --justification="$3" ${extra:+"$extra"} \
         --billing-project="$(v CICD_PROJECT)" --format='value(name)' || return 1;;
    *) return 2;;
  esac
  echo "waiting for the approver (up to 15 minutes)"
  while [ $i -lt 30 ]; do
    if _p15_grant_has "$ent" 'state=ACTIVE'; then echo "STATE ACTIVE"; return 0; fi
    i=$((i + 1)); _p15_sleep 30
  done
  echo "STOP: the grant on $1 is not ACTIVE after 15 minutes; when the approver has approved, resume from this step"
  return 1
}

_p15_under_grant() {   # the steps after PS-4.1: reuse its ACTIVE grant; request one only when none is active
  if [ "$AGP_MODE" != apply ]; then _p15_plan "under the ACTIVE ENT_PROJECT_REPAIR_CORE grant of PS-4.1 (requested again, in PS-4.1's form, only when none is active)"; return 0; fi
  _p15_grant ENT_PROJECT_REPAIR_CORE 3600 "$P15_REPAIR_WHY" SECOND_HUMAN_EMAIL
}

_p15_cal_row() {    # ID ROW MESSAGE: one DRILL_CALENDAR row, added once, committed in the build log
  local cal; cal="$(v DRILL_CALENDAR)"
  if [ "$AGP_MODE" = apply ]; then
    [ -f "$cal" ] || { echo "STOP: DRILL_CALENDAR ($cal) is not a file (01 creates it)"; return 1; }
    if grep -q "^| $1 |" "$cal"; then echo "$1 is already in DRILL_CALENDAR; not added again"; return 0; fi
    { cat "$cal"; printf '%s\n' "$2"; } | xw "$cal" 644 || return 1
  else
    printf '      would append to DRILL_CALENDAR: %s\n' "$2" >&3
  fi
  x git -C "$(v BUILD_LOG_DIR)" add "$cal" && x git -C "$(v BUILD_LOG_DIR)" commit -q -m "$3"
}

_p15_cal_has() { [ -f "$(v DRILL_CALENDAR)" ] && grep -q "^| $1 |" "$(v DRILL_CALENDAR)"; }

_p15_date_plus() {  # BSD_OFFSET GNU_OFFSET: 13 OP-3.4's portable date form, YYYY-MM-DD
  date -u -v"$1" +%Y-%m-%d 2>/dev/null || date -u -d "$2" +%Y-%m-%d
}

_p15_one() {    # LABEL VALUE: exactly one non-empty line, or a stop
  local n; n="$(printf '%s\n' "$2" | grep -c .)"
  [ "$n" = 1 ] && return 0
  echo "STOP: $1 read $n lines, not one (a blank or two lines is a stop)"; return 1
}

_p15_py() { python3 -c "$1" "${@:2}"; }   # a small JSON test on standard input; prints what fails

# _p15_pre CMD...: a read inside _apply that decides whether to create (the step's own check, repeated).
# It is marked as a check for the offline fakes, which otherwise answer every read inside apply as "present".
_p15_pre() { AGP_CALL_CONTEXT=check "$@"; }

_p15_svc() {   # PROJECT_NAME API: the API's line when it is enabled in that project (a filtered list)
  r gcloud services list --enabled --project="$(v "$1")" --filter="config.name=$2.googleapis.com" --format='value(config.name)'
}

_p15_chan_list() {  # PROJECT_NAME TYPE DISPLAY: the channel names of that type and display name
  r gcloud beta monitoring channels list --project="$(v "$1")" \
    --filter="type=\"$2\" AND displayName=\"$3\"" --format='value(name)'
}

# ---------------------------------------------------------------- Part A: PS-1 Preflight

step PS-1.1 AUTO-READ "Preflight: variables, decisions, APIs and the PAM bundle" \
  --needs "ORG_ID DOMAIN REGION CICD_PROJECT CORE_PROJECT CORE_PROJECT_NUMBER LOGGING_PROJECT LOGGING_PROJECT_NUMBER SINK_S_ORG SINK_S_FOLDER PAGER_SERVICE_NAME PAGER_SUBJECT_SERVICE_NAME SIEM_KIND SECOND_HUMAN_EMAIL INCIDENT_COMMANDER_EMAIL OWNER_DAILY_ACCOUNT PLATFORM_REPO_DIR PLATFORM_REPO_REMOTE SA_1_ADMIN ENT_PROJECT_REPAIR_CORE ENT_SECRET_READ BUILD_LOG_DIR EVIDENCE_REGISTER DRILL_CALENDAR DEVIATION_REGISTER SCC_TIER"
s_PS_1_1_check() { ckpt_done PS-1.1; }
_p15_1_1_reads() {
  local bad=0 repo d f id p list a n rc
  repo="$(v PLATFORM_REPO_DIR)"
  if penv_guard; then echo "GUARD OK"; else echo "STOP: penv_guard failed"; bad=1; fi
  d="$repo/decisions"
  f="$(for a in "$d"/*; do [ -e "$a" ] && basename "$a"; done | grep -Ei 'sd-08|sd-10|sd-12|sd-13|eve-h-scope|billing-scc-and-siem')"
  if [ -n "$f" ]; then echo "decision files:"; printf '%s\n' "$f" | sed 's/^/  /'
  else echo "STOP: no decision file for SD-08, SD-10, SD-12 or SD-13 under decisions/ (03)"; bad=1; fi
  for id in sd-08 sd-10 sd-12 sd-13; do
    printf '%s\n' "$f" | grep -qi "$id" || echo "REVIEW: no file name mentions $id; confirm it is signed, or pending with the owner's note that part A may proceed"
  done
  if grep -E '^/oncall/' "$repo/.github/CODEOWNERS" 2>/dev/null; then echo "REVIEW: the /oncall/ line above must name the second human"
  else echo "STOP: no /oncall/ line in .github/CODEOWNERS (03 DC-9.4)"; bad=1; fi
  a="$(_penv_get BUSINESS_TZ)"; n="$(_penv_get BUSINESS_HOURS)"
  printf 'BUSINESS_TZ=%s BUSINESS_HOURS=%s\n' "${a:-*tbd*}" "${n:-*tbd*}"
  for n in PAGER_ADMIN_EMAIL SCC_ADMIN_EMAIL; do
    a="$(_penv_get "$n")"; printf '%s=%s\n' "$n" "${a:-UNSET}"
    case "$a" in "$(v SA_1_ADMIN)"|"$(v OWNER_DAILY_ACCOUNT)") echo "STOP: $n is the platform owner"; bad=1;; esac
  done
  echo "REVIEW: two named IT security people to book (03 PPL-PA and PPL-SCA, or the incident commander's written naming and its DEVIATION_REGISTER row)"
  # The page's grep of records/*-OP-5.3-* (13 keeps the record there as <date>-OP-5.3-storage-member-tests-vN.txt).
  # Its six commands test domain:example.com and allUsers only, so today it names no gcp-sa- principal and
  # this read prints the NO B5 line; a positive service-agent test 13's owner adds would be found here.
  if ! grep -l -i 'gcp-sa-\|service agent' "$(v BUILD_LOG_DIR)"/records/*-OP-5.3-* 2>/dev/null; then
    echo "NO B5 SERVICE-AGENT RECORD (13 OP-5.3): not a stop. 13's OP-5.3 record tests domain:example.com and allUsers only."
    echo "  Open the dated DEVIATION_REGISTER row addressed to 13's owner now; PS-6.3 cites Google's restricting-identities page"
    echo "  meanwhile, and PS-6.3's own automatic grant to the SCC notification service agent is the positive test"
  fi
  f="$repo/policies/org/FLD_AGENTIC_PLATFORM/iam.allowedPolicyMemberDomains.json"
  if [ -f "$f" ]; then
    echo "iam.allowedPolicyMemberDomains allowedValues on fld-agentic-platform (13 OP-2.1's file):"
    _p15_py 'import json,sys
for r in (json.load(open(sys.argv[1])).get("spec") or {}).get("rules", []) or []:
    for a in (r.get("values") or {}).get("allowedValues", []) or []: print("  " + a)' "$f" \
      || echo "REVIEW: $f does not parse as JSON (13 OP-2.1)"
  else
    echo "REVIEW: no $f (13 OP-2.1 writes it)"
  fi
  # The page lists every enabled service and greps; the script asks each question as a filtered list, so the answer
  # never depends on parsing an unfiltered listing. The secretmanager read is a precondition (it must print nothing
  # before PS-4.2), so it runs in the check context, as the decision reads of phases 09 and 10 do.
  for p in CORE_PROJECT LOGGING_PROJECT; do
    list=""
    for a in logging monitoring pubsub; do
      nonempty _p15_svc "$p" "$a"; rc=$?
      case $rc in
        0) list="$list$a.googleapis.com ";;
        1) echo "STOP: $a.googleapis.com is not enabled on $p: re-run 10 CP-1.6"; bad=1;;
        *) echo "STOP: cannot list the services of $p"; bad=1;;
      esac
    done
    _p15_pre nonempty _p15_svc "$p" secretmanager; rc=$?
    case $rc in
      0) list="${list}secretmanager.googleapis.com "
         if [ "$p" = LOGGING_PROJECT ] || ! ckpt_done PS-4.2; then echo "STOP: secretmanager.googleapis.com is enabled on $p before PS-4.2 (02 4.2)"; bad=1; fi;;
      1) ;;
      *) echo "STOP: cannot list the services of $p"; bad=1;;
    esac
    echo "$list<- $(v "$p")"
  done
  r gcloud pam entitlements describe "$(v ENT_PROJECT_REPAIR_CORE)" --billing-project="$(v CICD_PROJECT)" \
    --format='yaml(privilegedAccess.gcpIamAccess.roleBindings,approvalWorkflow)' || { echo "STOP: ENT_PROJECT_REPAIR_CORE does not describe: re-run 12"; bad=1; }
  echo "REVIEW: the role bindings above must grant monitoring.notificationChannels.create, monitoring.alertPolicies.create, pubsub.topics.create, pubsub.topics.setIamPolicy, secretmanager.secrets.create and logging.views.create; a missing role is a re-run of 12, never a grant here"
  if [ "$(v SCC_TIER)" = "PREMIUM/eu" ]; then echo "SCC OK"; else echo "STOP: SCC is not Premium with eu residency (09)"; bad=1; fi
  echo "REVIEW: open 09's FS-7.7 detector diff; a detector residency disables is carried into part B as a SIEM rule"
  return $bad
}
s_PS_1_1_apply() {
  if [ "$AGP_MODE" != apply ]; then
    _p15_plan "reads: penv_guard; the SD-08, SD-10, SD-12, SD-13 decision files; the /oncall/ CODEOWNERS line; BUSINESS_TZ and"
    _p15_plan "BUSINESS_HOURS; the two IT security addresses; 13's B5 service-agent record; logging, monitoring, pubsub enabled"
    _p15_plan "(and secretmanager absent) in CORE_PROJECT and LOGGING_PROJECT; ENT_PROJECT_REPAIR_CORE's roles; SCC_TIER is PREMIUM/eu"
    _p15_record PS-1.1 preflight E-05 1.1-1.2 txt < /dev/null
    return 0
  fi
  local t rc; t="$(mktemp "${TMPDIR:-/tmp}/agp-p15.XXXXXX")" || return 1
  _p15_1_1_reads > "$t" 2>&1; rc=$?
  cat "$t"
  _p15_record PS-1.1 preflight E-05 1.1-1.2 txt < "$t" || rc=1
  rm -f "$t"
  return $rc
}

step PS-1.2 HUMAN "Read the SCC state and the SCC administrator's roles" --needs "ORG_ID" --sets "SCC_ADMIN_EMAIL"
s_PS_1_2_check() { ckpt_done PS-1.2; }
s_PS_1_2_manual() {
  echo "WHO: the IT security SCC administrator, on their own workstation, signed in as themselves; the platform owner records."
  echo "WHERE: their shell; Cloud console > Security > Security Command Center > Settings (organisation selected)."
  echo "DO: PS-1.2's first block of setup/15 (organisation policy read for their address; scc notifications list in location eu"
  echo "  through the regional endpoint); read tier and residency in the console; screenshot."
  echo "RECORD (platform owner, tenant shell): penv_set SCC_ADMIN_EMAIL \"<the address the administrator signed in with>\""
  echo "VERIFY: securitycenter.admin, or notificationConfigEditor + sourcesAdmin + findingsEditor; no notification config"
  echo "  points at a platform project; Premium, location eu. Evidence: <date>-PS-1.2-scc-state-v1 (E-05)."
  echo "Then: agp-platform done PS-1.2"
}

step PS-1.3 HUMAN "Re-read the paging tool's role separation" --witness --sets "PAGER_ADMIN_EMAIL"
s_PS_1_3_check() { ckpt_done PS-1.3; }
s_PS_1_3_manual() {
  echo "WHO: the IT security paging administrator; the second human reads the export (witness)."
  echo "WHERE: the paging tool, administrator's own account (People > Users; People > Teams)."
  echo "DO: export users with base roles and teams to the second human; confirm role separation per team and the audit trail;"
  echo "  teams agp-platform (owns PAGER_SERVICE_NAME) and itsec-subject-reports (both subject services, IT security only)."
  echo "RECORD (platform owner, from the second human's report): penv_set PAGER_ADMIN_EMAIL \"<the paging administrator's address>\""
  echo "VERIFY: the platform owner is neither Account Owner nor Global Admin, is on agp-platform and not on itsec-subject-reports."
  echo "Evidence: <date>-PS-1.3-paging-roles-v1, signed by the second human (E-08)."
  echo "Then: agp-platform done PS-1.3 --witness <second human's email>"
}

# ---------------------------------------------------------------- PS-2 The escalations in the paging tool

step PS-2.1 HUMAN "Users, notification rules and the L1 desk schedule"
s_PS_2_1_check() { ckpt_done PS-2.1; }
s_PS_2_1_manual() {
  echo "WHO: the IT security paging administrator; each responder sets their own contact methods."
  echo "WHERE: the paging tool (People > Users > Contact Information and Notification Rules; People > Schedules)."
  echo "DO: accounts for the platform owner, the second human, the incident commander (and the security reviewer when appointed);"
  echo "  high urgency: push and phone at once, SMS after 2 minutes; schedule agp-l1-desk in BUSINESS_TZ (the tool's default"
  echo "  zone with a note while it is *tbd*), one layer: the platform owner, 24x7. No phone number is written anywhere here."
  echo "VERIFY: each responder sends themselves a test notification and initials the time; the schedule shows the owner on call."
  echo "Evidence: <date>-PS-2.1-responders-v1 (no phone numbers; E-08). Then: agp-platform done PS-2.1"
}

step PS-2.2 HUMAN "The platform escalation policy L1-L3" --witness
s_PS_2_2_check() { ckpt_done PS-2.2; }
s_PS_2_2_manual() {
  echo "WHO: the IT security paging administrator builds; the incident commander reviews on screen (witness)."
  echo "WHERE: the paging tool, People > Escalation Policies > New Escalation Policy."
  echo "DO: agp-platform-escalation, team agp-platform: L1 schedule agp-l1-desk AND the second human, 15 min; L2 the platform"
  echo "  owner, 15 min; L3 the incident commander. Repeat the policy 2 times."
  echo "VERIFY: three levels; the second human on level 1 beside the schedule. The incident commander initials a screenshot."
  echo "Evidence: <date>-PS-2.2-platform-escalation-v1 (E-08, E-10)."
  echo "Then: agp-platform done PS-2.2 --witness <incident commander's email>"
}

step PS-2.3 HUMAN "Attach the escalation to agentic-platform and add the Cloud Monitoring integration" --needs "PAGER_SERVICE_NAME"
s_PS_2_3_check() { ckpt_done PS-2.3; }
s_PS_2_3_manual() {
  echo "WHO: the IT security paging administrator."
  echo "WHERE: the paging tool, Services > Service Directory > PAGER_SERVICE_NAME > Settings, then Integrations."
  echo "DO: escalation agp-platform-escalation; urgency High for all incidents; acknowledgement timeout off; one integration"
  echo "  'cloud-monitoring' of type Events API v1. Do not copy the key (PS-4.2 moves it); no other integration or member."
  echo "VERIFY: the service shows the policy, urgency High and exactly one integration cloud-monitoring (Events API v1)."
  echo "Evidence: screenshot with the key cropped out, <date>-PS-2.3-service-wiring-v1 (E-08). Then: agp-platform done PS-2.3"
}

step PS-2.4 HUMAN "The subject-report escalations" --needs "PAGER_SUBJECT_SERVICE_NAME"
s_PS_2_4_check() { ckpt_done PS-2.4; }
s_PS_2_4_manual() {
  echo "WHO: the IT security paging administrator builds; the incident commander reviews; the second human verifies alone."
  echo "  The platform owner is not present and never opens either subject service."
  echo "WHERE: the paging tool, team itsec-subject-reports."
  echo "DO: PS-2.4 steps 1 to 4 of setup/15: agp-subject-po-escalation on PAGER_SUBJECT_SERVICE_NAME (second human, then the"
  echo "  incident commander); service agentic-platform-roster-subject-sh with agp-subject-sh-escalation (security reviewer, or the"
  echo "  incident commander until appointed); urgency High, no integration; the second human sends the service name in one message."
  echo "VERIFY: neither escalation reaches its subject. Evidence: <date>-PS-2.4-subject-escalations-v1 (E-08)."
  echo "Then: agp-platform done PS-2.4"
}

step PS-2.4b HUMAN "Record the second subject service's name in the variables file" --witness \
  --needs "INCIDENT_COMMANDER_EMAIL SECOND_HUMAN_EMAIL" --sets "PAGER_SUBJECT_SH_SERVICE_NAME"
s_PS_2_4b_check() { ckpt_done PS-2.4b; }
s_PS_2_4b_manual() {
  echo "WHO: the platform owner types, from the second human's message of PS-2.4 step 4; the second human watches (witness)."
  echo "WHERE: the tenant shell, ~/.platform-env sourced. Do not open either subject service to read the name."
  echo "RECORD: penv_set PAGER_SUBJECT_SH_SERVICE_NAME \"agentic-platform-roster-subject-sh\"   (or the name in the message,"
  echo "  character for character)"
  echo "VERIFY: need PAGER_SUBJECT_SH_SERVICE_NAME; the second human reads the stored value back and confirms it; the build log"
  echo "  names the message (date, sender, recipients). Evidence: <date>-PS-2.4b-subject-sh-name-v1 (E-08)."
  echo "Then: agp-platform done PS-2.4b --witness <second human's email>"
}

step PS-2.5 HUMAN "The configuration-change log to the second human (interim)" --needs "DRILL_CALENDAR SECOND_HUMAN_EMAIL BUILD_LOG_DIR"
s_PS_2_5_check() { ckpt_done PS-2.5; }
s_PS_2_5_manual() {
  echo "WHO: the IT security paging administrator grants read; the second human reviews weekly."
  echo "WHERE: the paging tool (audit trail reporting on the three services, their escalations, agp-l1-desk, both teams)."
  echo "DO: give the second human a non-administrator role that can view those audit trails; run PS-2.5's printf block of"
  echo "  setup/15 (row DR-15-1 in DRILL_CALENDAR, committed in the build log; add it once: grep '^| DR-15-1 |' first)."
  echo "  The second human performs the first review now."
  echo "VERIFY: the first review lists the creation events of PS-2.2 to PS-2.4 by IT security and none by the platform owner."
  echo "Evidence: <date>-PS-2.5-audit-review-v1, then one record per week (E-08). Then: agp-platform done PS-2.5"
}

step PS-2.6 BLOCKED "The configuration-change forwarder" --note "B-06: paging audit forwarder, IT security's own code"
s_PS_2_6_check() { ckpt_done PS-2.6; }
s_PS_2_6_manual() {
  echo "BLOCKED: a job owned by IT security that reads the paging tool's audit records hourly and mails every change to the"
  echo "  second human, with its own absence alarm, in IT security's environment (README B-06). PS-2.5's weekly review applies."
  echo "When unblocked: IT security deploys it, renames agp-l1-desk's description and reverts it; the second human gets two mails."
}

step PS-2.7 HUMAN "The incident commander signs the escalation record" \
  --needs "PLATFORM_REPO_DIR PAGER_SERVICE_NAME PAGER_SUBJECT_SERVICE_NAME PAGER_SUBJECT_SH_SERVICE_NAME INCIDENT_COMMANDER_EMAIL SECOND_HUMAN_EMAIL"
s_PS_2_7_check() { ckpt_done PS-2.7; }
s_PS_2_7_manual() {
  echo "WHO: the platform owner writes; the incident commander signs; the second human co-signs the subject-report part."
  echo "WHERE: the tenant shell; $(v PLATFORM_REPO_DIR)."
  echo "DO: run PS-2.7's block of setup/15 as written (oncall/escalation-record.md heredoc, branch ps-2.7-escalation-record,"
  echo "  add, commit). The script does not retype the page's heredoc."
  echo "VERIFY: part of PS-3.2's merge: both approvals on the merged commit."
  echo "Then: agp-platform done PS-2.7   (the merged commit id is PS-3.2's evidence, <date>-PS-2.7-escalation-signed-v1)"
}

# ---------------------------------------------------------------- PS-3 oncall.yaml

step PS-3.1 HUMAN "Write oncall.yaml" \
  --needs "PLATFORM_REPO_DIR PAGER_SERVICE_NAME PAGER_SUBJECT_SERVICE_NAME PAGER_SUBJECT_SH_SERVICE_NAME SECOND_HUMAN_EMAIL INCIDENT_COMMANDER_EMAIL OWNER_DAILY_ACCOUNT"
s_PS_3_1_check() { ckpt_done PS-3.1; }
s_PS_3_1_manual() {
  echo "WHO: the platform owner."
  echo "WHERE: the tenant shell, ~/.platform-env sourced, on branch ps-2.7-escalation-record."
  echo "DO: run PS-3.1's block of setup/15 as written (oncall/oncall.yaml heredoc, the five PyYAML assertions, add, commit)."
  echo "  The script does not retype the page's heredoc."
  echo "VERIFY: ONCALL OK; the platform owner's address appears once, in services.platform.levels[1] only. business_tz and"
  echo "  business_hours may read *tbd* (record it; PS-5.4 waits). Evidence: the commit id in the build log (E-08)."
  echo "Then: agp-platform done PS-3.1"
}

step PS-3.2 HUMAN "Merge with the second human as required reviewer" --needs "PLATFORM_REPO_DIR" --sets "ONCALL_FILE"
s_PS_3_2_check() { ckpt_done PS-3.2; }
s_PS_3_2_manual() {
  echo "WHO: the platform owner opens; the second human approves (CODEOWNERS); the incident commander approves (signature)."
  echo "WHERE: the tenant shell and the git host."
  echo "DO: PS-3.2's first block (push, gh pr create); after both approvals and the signature commit, merge through the host"
  echo "  (never an administrator bypass); then its second block (gh pr view, switch main, pull --ff-only), and:"
  echo "RECORD: penv_set ONCALL_FILE \"oncall/oncall.yaml\""
  echo "VERIFY: mergedAt set; approvers hold the second human's and the incident commander's logins; oncall.yaml on main."
  echo "Evidence: <date>-PS-3.2-oncall-merged-v1 (E-08). Then: agp-platform done PS-3.2"
}

# ---------------------------------------------------------------- PS-4 Cloud Monitoring channels

step PS-4.1 AUTO "Obtain the core-project grant" --witness --note "approver: the second human, as 12 set on ENT_PROJECT_REPAIR_CORE" \
  --needs "ENT_PROJECT_REPAIR_CORE SECOND_HUMAN_EMAIL CICD_PROJECT"
s_PS_4_1_check() {   # an ACTIVE grant; once part A is closed (PS-6.12), no grant is needed again
  ckpt_done PS-6.12 && return 0
  _p15_grant_has "$(v ENT_PROJECT_REPAIR_CORE)" 'state=ACTIVE'
}
s_PS_4_1_apply() { _p15_grant ENT_PROJECT_REPAIR_CORE 3600 "$P15_REPAIR_WHY" SECOND_HUMAN_EMAIL; }

step PS-4.2 HUMAN "The platform-pager-key secret, filled by IT security" --witness --removes \
  --needs "CORE_PROJECT REGION DEVIATION_REGISTER BUILD_LOG_DIR PAGER_ADMIN_EMAIL"
s_PS_4_2_check() { ckpt_done PS-4.2; }
s_PS_4_2_manual() {
  echo "WHO: the platform owner (API, secret, time-bound adder grant, its removal); the IT security paging administrator adds"
  echo "  the version on their own workstation; the second human watches the preflight (witness). The key never reaches the script."
  echo "WHERE: the tenant shell under the PS-4.1 grant; IT security's workstation; the integration page of cloud-monitoring."
  echo "DO: PS-4.2 of setup/15 in order: the workstation preflight (four confirmations); the platform owner's block (enable"
  echo "  secretmanager on CORE_PROJECT only, BD-15-1 once, secrets create --location, the conditioned adder binding); IT"
  echo "  security's read -s block (versions add --data-file=-); then the platform owner's removal block, same EXP, same sitting."
  echo "VERIFY: versions list shows version 1 ENABLED; get-iam-policy shows no secretVersionAdder and no user principal."
  echo "  A refused enable (gcp.restrictServiceUsage) is a stop and a re-run of 13. Evidence: <date>-PS-4.2-pager-key-secret-v1."
  echo "Then: agp-platform done PS-4.2 --witness <second human's email>"
}

step PS-4.3 HUMAN "The paging channel in CORE_PROJECT" \
  --needs "CORE_PROJECT REGION PAGER_SERVICE_NAME ENT_SECRET_READ CICD_PROJECT PLATFORM_REPO_DIR" --sets "NOTIF_CH_PAGER_CORE"
s_PS_4_3_check() { ckpt_done PS-4.3; }
s_PS_4_3_manual() {
  echo "WHO: the platform owner, under an ENT_SECRET_READ grant approved as 12 set. HUMAN because the integration key is read"
  echo "  from Secret Manager and piped into the channel: no secret passes through this script."
  echo "WHERE: the tenant shell, ~/.platform-env sourced."
  echo "DO: run PS-4.3's block of setup/15 as written (pam grant, pam_wait ACTIVE, versions access | jq | curl POST, penv_set"
  echo "  NOTIF_CH_PAGER_CORE from the response; unset RESP)."
  echo "VERIFY: gcloud beta monitoring channels describe \"\$NOTIF_CH_PAGER_CORE\" --project=\"\$CORE_PROJECT\" \\"
  echo "  --format='value(type,displayName,enabled)' prints pagerduty, the name, True. Never print the full resource."
  echo "Evidence: <date>-PS-4.3-channel-pager-core-v1 (E-08). Then: agp-platform done PS-4.3"
}

step PS-4.4 HUMAN "The paging channel in LOGGING_PROJECT" \
  --needs "CORE_PROJECT LOGGING_PROJECT REGION PAGER_SERVICE_NAME ENT_SECRET_READ CICD_PROJECT" --sets "NOTIF_CH_PAGER_LOGGING"
s_PS_4_4_check() { ckpt_done PS-4.4; }
s_PS_4_4_manual() {
  echo "WHO: the platform owner, same ENT_SECRET_READ grant. HUMAN for the same reason as PS-4.3 (the key is piped)."
  echo "WHERE: the tenant shell."
  echo "DO: run PS-4.4's block of setup/15 as written (the channel in LOGGING_PROJECT, penv_set NOTIF_CH_PAGER_LOGGING, then"
  echo "  the revocation of every active ENT_SECRET_READ grant)."
  echo "VERIFY: as PS-4.3 on NOTIF_CH_PAGER_LOGGING in LOGGING_PROJECT; gcloud pam grants search --entitlement=\"\$ENT_SECRET_READ\" \\"
  echo "  --caller-relationship=had-created --filter='state=ACTIVE' --billing-project=\"\$CICD_PROJECT\" prints nothing."
  echo "Evidence: <date>-PS-4.4-channel-pager-logging-v1 (E-08). Then: agp-platform done PS-4.4"
}

step PS-4.5 AUTO "Email channels to the second human" \
  --needs "CORE_PROJECT LOGGING_PROJECT SECOND_HUMAN_EMAIL ENT_PROJECT_REPAIR_CORE CICD_PROJECT" --sets "NOTIF_CH_EMAIL_CORE NOTIF_CH_EMAIL_LOGGING"
s_PS_4_5_check() {
  local rc
  has_value NOTIF_CH_EMAIL_CORE && has_value NOTIF_CH_EMAIL_LOGGING || return 1
  nonempty _p15_chan_list CORE_PROJECT email "email second human"; rc=$?; [ $rc -eq 0 ] || return $rc
  nonempty _p15_chan_list LOGGING_PROJECT email "email second human"
}
s_PS_4_5_apply() {
  local pv names rc
  _p15_under_grant || return 1
  for pv in CORE_PROJECT LOGGING_PROJECT; do
    if [ "$AGP_MODE" = apply ]; then
      _p15_pre nonempty _p15_chan_list "$pv" email "email second human"; rc=$?
      case $rc in 0) echo "the email channel exists in $pv; not created again"; continue;; 1) ;; *) return 1;; esac
    fi
    x gcloud beta monitoring channels create --project="$(v "$pv")" --display-name="email second human" \
      --description="setup 15 PS-4.5; route 1 secondary (SD-08)" --type=email --channel-labels=email_address="$(v SECOND_HUMAN_EMAIL)" || return 1
  done
  if [ "$AGP_MODE" != apply ]; then
    pset NOTIF_CH_EMAIL_CORE "<from the channel list>"; pset NOTIF_CH_EMAIL_LOGGING "<from the channel list>"; return 0
  fi
  names="$(_p15_chan_list CORE_PROJECT email "email second human")" || return 1
  _p15_one "the email channel of CORE_PROJECT" "$names" && pset NOTIF_CH_EMAIL_CORE "$names" || return 1
  names="$(_p15_chan_list LOGGING_PROJECT email "email second human")" || return 1
  _p15_one "the email channel of LOGGING_PROJECT" "$names" && pset NOTIF_CH_EMAIL_LOGGING "$names"
}

step PS-4.6 CONSOLE "SMS channels to the second human" --witness --needs "CORE_PROJECT LOGGING_PROJECT" \
  --sets "NOTIF_CH_SMS_SECOND_HUMAN NOTIF_CH_SMS_SECOND_HUMAN_LOGGING"
s_PS_4_6_check() { ckpt_done PS-4.6; }
s_PS_4_6_manual() {
  echo "WHO: the platform owner creates; the second human types their own number and reads the code from their phone (witness)."
  echo "WHERE: Cloud console > Monitoring > Alerting > Edit notification channels > SMS > Add new, once with CORE_PROJECT and"
  echo "  once with LOGGING_PROJECT selected. Display name 'sms second human'; the number is not recorded anywhere."
  echo "RECORD: PS-4.6's block of setup/15 (penv_set NOTIF_CH_SMS_SECOND_HUMAN and NOTIF_CH_SMS_SECOND_HUMAN_LOGGING from"
  echo "  gcloud beta monitoring channels list --filter='type=\"sms\" AND displayName=\"sms second human\"' per project)."
  echo "VERIFY: both lists print 'sms second human VERIFIED'. SMS not offered for the country: record it, and a dated deviation."
  echo "Evidence: <date>-PS-4.6-channels-sms-v1 (no number; E-08)."
  echo "Then: agp-platform done PS-4.6 --witness <second human's email>"
}

step PS-4.7 AUTO-READ "Channel inventory read-back" --witness --note "the second human reads the output" \
  --needs "CORE_PROJECT LOGGING_PROJECT NOTIF_CH_PAGER_CORE NOTIF_CH_EMAIL_CORE NOTIF_CH_SMS_SECOND_HUMAN NOTIF_CH_PAGER_LOGGING NOTIF_CH_EMAIL_LOGGING NOTIF_CH_SMS_SECOND_HUMAN_LOGGING BUILD_LOG_DIR EVIDENCE_REGISTER"
s_PS_4_7_check() { ckpt_done PS-4.7; }
_p15_4_7_project() {    # PROJECT_NAME PAGER_VAR EMAIL_VAR SMS_VAR: exactly the three channels, enabled, SMS verified
  # Each question is a filtered list (lib/PHASES.md rule 4), never a parse of the table above. "No other channel" is a
  # precondition of PS-5 that must print nothing, so it reads in the check context, as the decision reads of 09 and 10.
  local p bad=0 rc c t ex=""
  p="$(v "$1")"
  for c in "$2:pagerduty" "$3:email" "$4:sms"; do
    t="${c#*:}"; c="${c%%:*}"
    ex="$ex${ex:+ AND }name!=\"$(v "$c")\""
    if [ "$t" = sms ]; then
      nonempty r gcloud beta monitoring channels list --project="$p" \
        --filter="name=\"$(v "$c")\" AND type=\"$t\" AND enabled=true AND verificationStatus=VERIFIED" --format='value(name)'; rc=$?
    else
      nonempty r gcloud beta monitoring channels list --project="$p" \
        --filter="name=\"$(v "$c")\" AND type=\"$t\" AND enabled=true" --format='value(name)'; rc=$?
    fi
    case $rc in
      0) ;;
      1) if [ "$t" = sms ]; then echo "STOP: $c ($(v "$c")) is not an enabled, VERIFIED sms channel in $1 (PS-4.6)"
         else echo "STOP: $c ($(v "$c")) is not an enabled $t channel in $1"; fi; bad=1;;
      *) echo "STOP: cannot list the channels of $1"; bad=1;;
    esac
  done
  _p15_pre nonempty r gcloud beta monitoring channels list --project="$p" --filter="$ex" --format='value(name)'; rc=$?
  case $rc in
    0) echo "STOP: $1 holds a channel that is not one of the three (the table above names it): investigate and record it before PS-5"; bad=1;;
    1) ;;
    *) echo "STOP: cannot list the channels of $1"; bad=1;;
  esac
  return $bad
}
s_PS_4_7_apply() {
  local t rc=0 p
  if [ "$AGP_MODE" != apply ]; then
    _p15_plan "reads: gcloud beta monitoring channels list per core project; each project holds exactly its three channels"
    _p15_plan "(pagerduty, email, sms), all enabled, SMS VERIFIED, names equal to the six NOTIF_CH_* values"
    _p15_record PS-4.7 channel-inventory E-08 1.6 txt < /dev/null
    return 0
  fi
  t="$(mktemp "${TMPDIR:-/tmp}/agp-p15.XXXXXX")" || return 1
  for p in CORE_PROJECT LOGGING_PROJECT; do
    echo "== $(v "$p")"
    r gcloud beta monitoring channels list --project="$(v "$p")" --format='table(name.basename(),type,displayName,enabled,verificationStatus)'
  done > "$t" 2>&1
  cat "$t"
  _p15_record PS-4.7 channel-inventory E-08 1.6 txt < "$t" || rc=1
  rm -f "$t"
  _p15_4_7_project CORE_PROJECT NOTIF_CH_PAGER_CORE NOTIF_CH_EMAIL_CORE NOTIF_CH_SMS_SECOND_HUMAN || rc=1
  _p15_4_7_project LOGGING_PROJECT NOTIF_CH_PAGER_LOGGING NOTIF_CH_EMAIL_LOGGING NOTIF_CH_SMS_SECOND_HUMAN_LOGGING || rc=1
  echo "REVIEW: the second human reads the saved table"
  return $rc
}

# ---------------------------------------------------------------- PS-5 Acknowledgement tests

step PS-5.1 HUMAN "The acknowledgement-test policy in CORE_PROJECT" \
  --needs "CORE_PROJECT NOTIF_CH_PAGER_CORE NOTIF_CH_EMAIL_CORE NOTIF_CH_SMS_SECOND_HUMAN BUILD_LOG_DIR"
s_PS_5_1_check() { ckpt_done PS-5.1; }
s_PS_5_1_manual() {
  echo "WHO: the platform owner, under the PS-4.1 grant."
  echo "WHERE: the tenant shell, ~/.platform-env sourced."
  echo "DO: run PS-5.1's block of setup/15 as written (the ack-test.yaml heredoc, gcloud monitoring policies create"
  echo "  --project=\"\$CORE_PROJECT\" --policy-from-file, the copy into evidence/15). The script does not retype the heredoc."
  echo "VERIFY: gcloud monitoring policies list --project=\"\$CORE_PROJECT\" --filter='displayName=\"agp-ack-test (setup 15 PS-5)\"' \\"
  echo "  --format='value(name,enabled,notificationChannels.len())' prints one policy, True, 3."
  echo "Evidence: the policy file in the build log (E-08). Then: agp-platform done PS-5.1"
}

step PS-5.2 HUMAN "Business-hours acknowledgement test on the platform escalation" --witness --needs "CORE_PROJECT"
s_PS_5_2_check() { ckpt_done PS-5.2; }
s_PS_5_2_manual() {
  echo "WHO: the platform owner fires; nobody acknowledges at L1 or L2; the incident commander alone acknowledges, at L3;"
  echo "  the second human confirms receipt at L1 and records T0 to T5 (witness)."
  echo "WHERE: the tenant shell; the paging tool on each person's phone."
  echo "DO: announce the rule; then: gcloud logging write agp-page-test \"setup 15 PS-5.2 acknowledgement test \$(date -u +%Y%m%dT%H%M%SZ)\" \\"
  echo "  --severity=ERROR --project=\"\$CORE_PROJECT\"; record T0 to T5 as PS-5.2 lists them."
  echo "VERIFY: page, SMS and email at the second human; levels 1, 2, 3 in order; T1-T0 under 5 min; T4-T1 30 min +/- 2."
  echo "  An acknowledgement at L1 or L2 means the test is run again. Close the Monitoring incident afterwards."
  echo "Evidence: <date>-PS-5.2-ack-test-business-hours-v1, signed by the second human (E-08, E-10)."
  echo "Then: agp-platform done PS-5.2 --witness <second human's email>"
}

step PS-5.3 HUMAN "Subject-report escalation test and the platform owner's negative test" --witness \
  --needs "PAGER_SUBJECT_SERVICE_NAME PAGER_SUBJECT_SH_SERVICE_NAME"
s_PS_5_3_check() { ckpt_done PS-5.3; }
s_PS_5_3_manual() {
  echo "WHO: the IT security paging administrator creates the incidents; the second human and the incident commander receive;"
  echo "  the platform owner performs the negative test while the second human watches (witness)."
  echo "WHERE: the paging tool, Incidents > New Incident."
  echo "DO: PS-5.3 steps 1 to 3 of setup/15 (one incident on each subject service; the platform owner opens the incident list"
  echo "  and the service directory on their own device)."
  echo "VERIFY: (a) test 1 reached the second human only; (b) test 2 the incident commander (or security reviewer) only;"
  echo "  (c) the platform owner sees neither incident nor service, or no action on them; (d) they received nothing."
  echo "Evidence: <date>-PS-5.3-subject-escalation-test-v1 (E-08). Then: agp-platform done PS-5.3 --witness <second human's email>"
}

step PS-5.4 HUMAN "Out-of-hours acknowledgement test" --witness --on-unmet skip --needs "CORE_PROJECT" \
  --note "waits for BUSINESS_HOURS (03 DC-7.1, WDEC-15) and a time the second human chooses"
s_PS_5_4_check() { ckpt_done PS-5.4; }
s_PS_5_4_manual() {
  echo "WHO: as PS-5.2, the acknowledgement rule in full; the second human chooses a time outside BUSINESS_HOURS."
  echo "WHERE: as PS-5.2. While BUSINESS_HOURS is *tbd*: checkpoint PS-5.4 BLOCKED - - \"WAITING business hours (03)\"."
  echo "DO: at the second human's message, the platform owner runs PS-5.2's fire command; nobody acknowledges at L1 or L2."
  echo "VERIFY: as PS-5.2, with T5-T1 against the 60-minute target; the result is recorded whatever it is."
  echo "Evidence: <date>-PS-5.4-ack-test-out-of-hours-v1 (E-08, E-10). This step does not hold the run."
  echo "Then: agp-platform done PS-5.4 --witness <second human's email>"
}

step PS-5.5 HUMAN "A tamper policy and its test in LOGGING_PROJECT" --witness \
  --needs "LOGGING_PROJECT NOTIF_CH_PAGER_LOGGING NOTIF_CH_EMAIL_LOGGING NOTIF_CH_SMS_SECOND_HUMAN_LOGGING BUILD_LOG_DIR"
s_PS_5_5_check() { ckpt_done PS-5.5; }
s_PS_5_5_manual() {
  echo "WHO: the platform owner, under the PS-4.1 grant; the second human confirms receipt."
  echo "WHERE: the tenant shell."
  echo "DO: run PS-5.5's first block of setup/15 as written (logging-tamper.yaml heredoc, policies create in LOGGING_PROJECT);"
  echo "  then its test block (a throwaway view agp-alert-test on _Default, created, then deleted: answer the delete's prompt)."
  echo "  The script does not retype the heredoc."
  echo "VERIFY: PS-5.5's gcloud logging read prints the two methods (fix the filter if the spelling differs); the second human"
  echo "  receives page, SMS and email naming actor and method. No page in 15 minutes: record it, keep the policy, carry SG-02"
  echo "  as SIEM-only with a dated DEVIATION_REGISTER row. Evidence: <date>-PS-5.5-logging-tamper-test-v1 (E-06, E-08)."
  echo "Then: agp-platform done PS-5.5 --witness <second human's email>"
}

step PS-5.6 AUTO "Keep the test policy, disabled" --removes \
  --needs "CORE_PROJECT DRILL_CALENDAR BUILD_LOG_DIR ENT_PROJECT_REPAIR_CORE CICD_PROJECT SECOND_HUMAN_EMAIL"
_p15_ack_pol() { r gcloud monitoring policies list --project="$(v CORE_PROJECT)" --filter='displayName="agp-ack-test (setup 15 PS-5)"' --format='value(name)'; }
_p15_ack_off() { r gcloud monitoring policies list --project="$(v CORE_PROJECT)" --filter='displayName="agp-ack-test (setup 15 PS-5)" AND enabled=false' --format='value(name)'; }
s_PS_5_6_check() {   # the drill row is in DRILL_CALENDAR and the policy lists as disabled (a filtered list, not a parsed value)
  _p15_cal_has DR-15-2 || return 1
  nonempty _p15_ack_off
}
s_PS_5_6_apply() {
  local pol due rc
  _p15_under_grant || return 1
  if [ "$AGP_MODE" = apply ]; then
    pol="$(_p15_ack_pol)" || return 1
    _p15_one "the agp-ack-test policy (PS-5.1)" "$pol" || return 1
    _p15_pre nonempty _p15_ack_off; rc=$?
  else
    _p15_plan "reads: gcloud monitoring policies list --project=<CORE_PROJECT> --filter='displayName=\"agp-ack-test (setup 15 PS-5)\"' (exactly one name)"
    pol="<AGP_ACK_TEST_POLICY>"; rc=1
  fi
  case $rc in
    0) echo "agp-ack-test is already disabled; not updated again";;
    1) x gcloud monitoring policies update "$pol" --project="$(v CORE_PROJECT)" --no-enabled || return 1;;
    *) return 1;;
  esac
  due="$(_p15_date_plus +3m '+3 months')"
  [ -n "$due" ] || { echo "STOP: no due date computed; the calendar row would carry an empty date"; return 1; }
  _p15_cal_row DR-15-2 "$(printf '| DR-15-2 | Acknowledgement drill: enable agp-ack-test, fire, record T0-T5, disable | quarterly and after any change to the escalations | platform owner fires | second human confirms receipt | 15 | %s | | | P99; G2 |' "$due")" \
    "PS-5.6 acknowledgement drill row" || return 1
  [ "$AGP_MODE" = apply ] || return 0
  tail -1 "$(v DRILL_CALENDAR)"
  # the page's VERIFY (policies describe --format='value(enabled)' prints False) is the runner's re-check above
}

# ---------------------------------------------------------------- PS-6 SCC notifications and the Tier C route

step PS-6.1 AUTO "Topic scc-findings and the desk subscription" \
  --needs "CORE_PROJECT REGION ENT_PROJECT_REPAIR_CORE CICD_PROJECT SECOND_HUMAN_EMAIL" --sets "SCC_TOPIC"
_p15_topic()   { exists r gcloud pubsub topics describe scc-findings --project="$(v CORE_PROJECT)" --format='value(name)'; }
_p15_desksub() { exists r gcloud pubsub subscriptions describe scc-findings-desk --project="$(v CORE_PROJECT)" --format='value(name)'; }
_p15_topic_ok() {   # the page's VERIFY as a filtered list: REGION is the one allowed region, enforceInTransit is true
  nonempty r gcloud pubsub topics list --project="$(v CORE_PROJECT)" \
    --filter="name~\"/topics/scc-findings\$\" AND messageStoragePolicy.allowedPersistenceRegions:$(v REGION) AND messageStoragePolicy.enforceInTransit=true" \
    --format='value(name,messageStoragePolicy.allowedPersistenceRegions.list())'
}
_p15_desksub_ok() { # the desk subscription is on scc-findings and has no expiry
  nonempty r gcloud pubsub subscriptions list --project="$(v CORE_PROJECT)" \
    --filter="name~\"/subscriptions/scc-findings-desk\$\" AND topic~\"/topics/scc-findings\$\" AND -expirationPolicy.ttl:*" \
    --format='value(name,topic)'
}
s_PS_6_1_check() {   # both reads, always, before the variables file is trusted: a check reads Google first
  local rt rs
  _p15_topic_ok; rt=$?
  _p15_desksub_ok; rs=$?
  [ $rt -eq 0 ] || return $rt
  [ $rs -eq 0 ] || return $rs
  has_value SCC_TOPIC
}
s_PS_6_1_apply() {
  local rc
  _p15_under_grant || return 1
  rc=1; [ "$AGP_MODE" = apply ] && { _p15_pre _p15_topic; rc=$?; }
  case $rc in
    0) echo "scc-findings exists; not created again"
       _p15_pre _p15_topic_ok || { echo "STOP: scc-findings exists but its storage policy is not [$(v REGION)] with enforceInTransit; it is investigated, never edited here"; return 1; };;
    1) x gcloud pubsub topics create scc-findings --project="$(v CORE_PROJECT)" --message-storage-policy-allowed-regions="$(v REGION)" \
         --message-storage-policy-enforce-in-transit --message-retention-duration=7d --labels=owner=platform,purpose=scc-notifications \
         || { echo "a refusal naming a CMEK constraint is a 13 finding (B20 is held until P12): stop and record it"; return 1; };;
    *) return 1;;
  esac
  rc=1; [ "$AGP_MODE" = apply ] && { _p15_pre _p15_desksub; rc=$?; }
  case $rc in
    0) echo "scc-findings-desk exists; not created again";;
    1) x gcloud pubsub subscriptions create scc-findings-desk --project="$(v CORE_PROJECT)" --topic=scc-findings --ack-deadline=60 \
         --message-retention-duration=7d --expiration-period=never --labels=owner=platform,purpose=scc-desk || return 1;;
    *) return 1;;
  esac
  pset SCC_TOPIC "projects/$(v CORE_PROJECT)/topics/scc-findings" || return 1
  [ "$AGP_MODE" = apply ] || return 0
  r gcloud pubsub topics describe scc-findings --project="$(v CORE_PROJECT)" --format='yaml(messageStoragePolicy,messageRetentionDuration)'
  r gcloud pubsub subscriptions describe scc-findings-desk --project="$(v CORE_PROJECT)" --format='value(topic,expirationPolicy)'
  # the page's VERIFY (region, enforceInTransit, topic, no expiry) is the step's check, which the runner re-runs now
}

step PS-6.2 AUTO "A temporary topic grant for the SCC administrator" \
  --needs "CORE_PROJECT SCC_ADMIN_EMAIL ENT_PROJECT_REPAIR_CORE CICD_PROJECT SECOND_HUMAN_EMAIL BUILD_LOG_DIR"
_p15_topic_admin() { has_binding "user:$(v SCC_ADMIN_EMAIL)" roles/pubsub.admin gcloud pubsub topics get-iam-policy scc-findings --project="$(v CORE_PROJECT)"; }
s_PS_6_2_check() {   # the grant is only needed until the notification config exists (PS-6.3); PS-6.4 removes it
  ckpt_done PS-6.3 && return 0
  _p15_topic_admin
}
_p15_topic_pol() { r gcloud pubsub topics get-iam-policy scc-findings --project="$(v CORE_PROJECT)" --format=json; }
s_PS_6_2_apply() {
  local before after
  _p15_under_grant || return 1
  if [ "$AGP_MODE" = apply ]; then before="$(_p15_topic_pol)" || { echo "STOP: the topic policy of scc-findings does not read"; return 1; }; fi
  x gcloud pubsub topics add-iam-policy-binding scc-findings --project="$(v CORE_PROJECT)" --member="user:$(v SCC_ADMIN_EMAIL)" --role=roles/pubsub.admin \
    || { echo "a refusal naming constraints/iam.allowedPolicyMemberDomains is a 13 re-run, not a change here"; return 1; }
  # the page writes the PENDING line against PS-6.4, the step that owes the removal; PS-6.4's DONE line closes it
  x checkpoint PS-6.4 PENDING - - "temporary pubsub.admin on scc-findings granted in PS-6.2; PS-6.4 removes it today" || return 1
  if [ "$AGP_MODE" != apply ]; then _p15_record PS-6.2 topic-grant E-05 4.1-4.2 txt < /dev/null; return 0; fi
  after="$(_p15_topic_pol)" || { echo "STOP: the topic policy of scc-findings does not read"; return 1; }
  printf 'before:\n%s\nafter:\n%s\n' "$before" "$after" | _p15_record PS-6.2 topic-grant E-05 4.1-4.2 txt
  # the page's VERIFY (the one binding for the administrator) is the step's check, which the runner re-runs now
}

step PS-6.3 HUMAN "The organisation notification config" --needs "ORG_ID CORE_PROJECT" --sets "SCC_NOTIFICATION_CONFIG"
s_PS_6_3_check() { ckpt_done PS-6.3; }
s_PS_6_3_manual() {
  echo "WHO: the IT security SCC administrator performs, on their workstation, as themselves; the platform owner watches and records."
  echo "DO: PS-6.3's block of setup/15 (regional endpoint override; gcloud scc notifications create agp-scc-to-pager --organization"
  echo "  --location=eu --pubsub-topic=projects/<CORE_PROJECT>/topics/scc-findings and the bracketed filter; describe; unset)."
  echo "  The location of a notification config cannot be changed after creation."
  echo "RECORD (platform owner): penv_set SCC_NOTIFICATION_CONFIG \"organizations/<ORG_ID>/locations/eu/notificationConfigs/agp-scc-to-pager\""
  echo "VERIFY: the describe shows the topic, the filter as written and service-org-<ORG_ID>@gcp-sa-scc-notification...; the topic"
  echo "  policy holds that agent with roles/securitycenter.notificationServiceAgent. Cite 13 OP-5.3's B5 record, or Google's"
  echo "  restricting-identities page while it is missing; a refused automatic grant is a stop (13's B5 file, reviewed)."
  echo "Evidence: <date>-PS-6.3-scc-notification-config-v1 (E-05). Then: agp-platform done PS-6.3"
}

step PS-6.4 AUTO "Remove the temporary grant" --removes \
  --needs "CORE_PROJECT SCC_ADMIN_EMAIL ENT_PROJECT_REPAIR_CORE CICD_PROJECT SECOND_HUMAN_EMAIL"
s_PS_6_4_check() {
  local rc
  _p15_topic_admin; rc=$?
  case $rc in 0) return 1;; 1) return 0;; *) return $rc;; esac
}
s_PS_6_4_apply() {
  local j t
  _p15_under_grant || return 1
  x gcloud pubsub topics remove-iam-policy-binding scc-findings --project="$(v CORE_PROJECT)" --member="user:$(v SCC_ADMIN_EMAIL)" --role=roles/pubsub.admin || return 1
  [ "$AGP_MODE" = apply ] || { _p15_record PS-6.4 topic-grant-removed E-05 4.1-4.2 txt < /dev/null; return 0; }
  t="$(r gcloud pubsub topics get-iam-policy scc-findings --project="$(v CORE_PROJECT)" --format='table(bindings.role,bindings.members)')" || return 1
  printf '%s\n' "$t"
  printf '%s\n' "$t" | _p15_record PS-6.4 topic-grant-removed E-05 4.1-4.2 txt || return 1
  j="$(_p15_topic_pol)" || return 1
  printf '%s' "$j" | _p15_py 'import json,sys
for b in json.load(sys.stdin).get("bindings", []):
    for m in b.get("members", []):
        if m.startswith("user:"): print("STOP: %s still holds %s on scc-findings" % (m, b.get("role")))' | grep . && return 1
  echo "REVIEW: only the SCC notification service agent (and any binding 10 or 12 placed, named in the record) remains"
}

step PS-6.5 HUMAN "The page on a waiting finding" --needs "CORE_PROJECT NOTIF_CH_PAGER_CORE NOTIF_CH_EMAIL_CORE NOTIF_CH_SMS_SECOND_HUMAN BUILD_LOG_DIR"
s_PS_6_5_check() { ckpt_done PS-6.5; }
s_PS_6_5_manual() {
  echo "WHO: the platform owner, under the PS-4.1 grant."
  echo "WHERE: the tenant shell."
  echo "DO: run PS-6.5's block of setup/15 as written (scc-waiting.yaml heredoc: a threshold on"
  echo "  pubsub.googleapis.com/subscription/num_undelivered_messages of scc-findings-desk > 0, missing data inactive; policies"
  echo "  create --project=\"\$CORE_PROJECT\"; the copy into evidence/15). The script does not retype the heredoc. No absence"
  echo "  condition now (PS-6.9 decides after a week)."
  echo "VERIFY: the policy exists, enabled, three channels; in Metrics Explorer a series at 0 after 5 minutes."
  echo "Evidence: <date>-PS-6.5-scc-waiting-policy-v1 (E-05, E-10). Then: agp-platform done PS-6.5"
}

step PS-6.6 HUMAN "The route-test source" --irreversible --needs "ORG_ID" --sets "SCC_ROUTE_TEST_SOURCE"
s_PS_6_6_check() { ckpt_done PS-6.6; }
s_PS_6_6_manual() {
  echo "IRREVERSIBLE: a security source cannot be deleted or disabled. Gate: PS-6.3 DONE and the security reviewer's (or the"
  echo "  incident commander's) build-log note accepting one permanent test source."
  echo "WHO: the IT security SCC administrator, on their workstation; the platform owner records."
  echo "DO: PS-6.6's block of setup/15 (list sources first: no agp-route-test may exist; then the v2 sources POST, global"
  echo "  endpoint first, the eu endpoint only after the list proves the refused call created nothing)."
  echo "RECORD (platform owner): PS-6.6's second block (the case guard, penv_set SCC_ROUTE_TEST_SOURCE, SOURCE STORED OK)."
  echo "VERIFY: organizations/<ORG_ID>/sources/<numeric id>, not NONE; agp-route-test listed exactly once."
  echo "Evidence: <date>-PS-6.6-route-test-source-v1 (E-05). Then: agp-platform done PS-6.6"
}

step PS-6.7 HUMAN "Findings Editor for the route test"
s_PS_6_7_check() { ckpt_done PS-6.7; }
s_PS_6_7_manual() {
  echo "WHO: the IT security SCC administrator; the platform owner reads PS-1.2's record."
  echo "DO: nothing if PS-1.2's output showed roles/securitycenter.admin or roles/securitycenter.findingsEditor. Otherwise stop:"
  echo "  the organisation grant needs Organization Administrator (break-glass only after 12); re-run 09's SCC administration record."
  echo "VERIFY: PS-1.2's output. Evidence: a reference to PS-1.2's record (no E-xx)."
  echo "Then: agp-platform done PS-6.7"
}

step PS-6.8 HUMAN "Prove the Tier C detection route with an SCC test finding" --witness \
  --needs "ORG_ID CORE_PROJECT CORE_PROJECT_NUMBER SCC_ROUTE_TEST_SOURCE BUILD_LOG_DIR"
s_PS_6_8_check() { ckpt_done PS-6.8; }
s_PS_6_8_manual() {
  echo "WHO: the IT security SCC administrator raises the finding; the platform owner pulls and acks; the second human"
  echo "  confirms receipt (witness)."
  echo "DO: PS-6.8's three blocks of setup/15 in order: IT security's findings create (category AGP_ROUTE_TEST, location eu,"
  echo "  the source id from SCC_ROUTE_TEST_SOURCE); after the page, the platform owner's subscriptions pull, jq read and ack;"
  echo "  after the ack, IT security's findings update --state=INACTIVE."
  echo "VERIFY: (1) the pulled message is AGP_ROUTE_TEST, ACTIVE; (2) page, SMS and email within 10 minutes; (3) the incident"
  echo "  closes at backlog 0; (4) INACTIVE pages nothing. The second human signs (2)."
  echo "Evidence: <date>-PS-6.8-scc-route-test-v1, the Tier C route record 20 cites (E-05, E-10)."
  echo "Then: agp-platform done PS-6.8 --witness <second human's email>"
}

step PS-6.9 HUMAN "H-3 interim: the weekly manual synthetic finding" --needs "DRILL_CALENDAR BUILD_LOG_DIR CORE_PROJECT"
s_PS_6_9_check() { ckpt_done PS-6.9; }
s_PS_6_9_manual() {
  echo "WHO: the IT security SCC administrator raises; the second human confirms the page; the platform owner pulls and acks."
  echo "DO: PS-6.9's block of setup/15 (row DR-15-3 in DRILL_CALENDAR, due in 7 days, committed; add it once: grep"
  echo "  '^| DR-15-3 |' first); repeat PS-6.8 weekly until PS-6.10 is live."
  echo "  After the first week: if the desk subscription's num_undelivered_messages series is continuous, add a conditionAbsent"
  echo "  of 84600s to PS-6.5's policy (gcloud monitoring policies update --project=\"\$CORE_PROJECT\" --policy-from-file) and record it."
  echo "VERIFY: the row is committed with a date in its due column; the first weekly record exists 7 days later."
  echo "Evidence: <date>-PS-6.9-h3-weekly-v<n> (E-08). Then: agp-platform done PS-6.9"
}

step PS-6.10 BLOCKED "H-3: the automatic weekly synthetic finding" --note "B-05: H-3 synthetic finding code"
s_PS_6_10_check() { ckpt_done PS-6.10; }
s_PS_6_10_manual() {
  echo "BLOCKED on README B-05: the drift job's H-3 routine (raises a synthetic finding weekly in SCC_ROUTE_TEST_SOURCE and"
  echo "  records that the page reached the desk). PS-6.9 runs meanwhile."
  echo "When unblocked: deploy by digest under ENT_PROJECT_REPAIR_CORE; IT security grants findingsEditor; PS-6.8's checks pass."
}

step PS-6.11 BLOCKED "The SCC notifier with finding content" --note "B-05: SCC notifier code"
s_PS_6_11_check() { ckpt_done PS-6.11; }
s_PS_6_11_manual() {
  echo "BLOCKED on README B-05: a notifier that reads scc-findings-desk, opens an incident per finding (category, resource,"
  echo "  severity), routes roster-human principals to the subject service and acks. PS-6.5 pages without content meanwhile."
  echo "When unblocked: deploy by digest with roles/pubsub.subscriber on scc-findings-desk only; repeat PS-6.8."
}

step PS-6.12 HUMAN "Close part A" --witness \
  --needs "ENT_PROJECT_REPAIR_CORE CICD_PROJECT ONCALL_FILE NOTIF_CH_PAGER_CORE NOTIF_CH_EMAIL_CORE NOTIF_CH_SMS_SECOND_HUMAN NOTIF_CH_PAGER_LOGGING NOTIF_CH_EMAIL_LOGGING NOTIF_CH_SMS_SECOND_HUMAN_LOGGING SCC_TOPIC SCC_NOTIFICATION_CONFIG SCC_ROUTE_TEST_SOURCE PAGER_SUBJECT_SH_SERVICE_NAME BUILD_LOG_DIR"
s_PS_6_12_check() { ckpt_done PS-6.12; }
s_PS_6_12_manual() {
  echo "WHO: the platform owner; the second human signs. HUMAN because it ends the sitting (sitting_end revokes every credential),"
  echo "  so it is never run in the middle of a multi-phase apply."
  echo "DO: PS-6.12's block of setup/15 (SOURCE VALUE OK; the two awk counts on checkpoints.tsv; revoke each ACTIVE"
  echo "  ENT_PROJECT_REPAIR_CORE grant you created: gcloud pam grants search --caller-relationship=had-created), then:"
  echo "  agp-platform sitting end."
  echo "VERIFY: the count prints 34 (33 while PS-5.4 waits on BUSINESS_HOURS); PS-2.6, PS-6.10 and PS-6.11 listed BLOCKED;"
  echo "  SITTING-END OK."
  echo "Evidence: <date>-PS-6.12-part-a-record-v1, signed by the second human (E-05, E-08)."
  echo "Then: agp-platform done PS-6.12 --witness <second human's email>"
}

# ---------------------------------------------------------------- Part B: the SIEM (Tier P, P10)

step PS-7.1 BLOCKED "Gate check and instance facts" --note "B-06: P10 contract (SIEM order and MDR retainer)"
s_PS_7_1_check() { ckpt_done PS-7.1; }
s_PS_7_1_manual() {
  echo "BLOCKED on README B-06: P10's SIEM contract and PU-2.1's order and MDR retainer; nothing in files 16 to 37 waits"
  echo "  (README section 3). The runner writes the BLOCKED checkpoint. When unblocked, the step is done by people as below."
  echo "WHO: the IT security SIEM administrator; the platform owner records. WHERE: SecOps console; the evidence register."
  echo "DO: PS-7.1 steps 1 to 3 of setup/15 (order and retainer; instance location and bound project; who holds SecOps roles)."
  echo "VERIFY: retention at least 400 days and an EU location, else part B stops. Evidence: <date>-PS-7.1-siem-facts-v1 (E-11)."
}

step PS-7.2 BLOCKED "F2: Google Cloud ingestion at the organisation" --sets "SIEM_INGEST_PRINCIPAL" --note "B-06: P10 contract"
s_PS_7_2_check() { ckpt_done PS-7.2; }
s_PS_7_2_manual() {
  echo "BLOCKED on README B-06 (P10); the runner writes the BLOCKED checkpoint. When unblocked:"
  echo "WHO: the IT security SIEM administrator (Chronicle Service Admin at the organisation); the"
  echo "  platform owner watches. WHERE: Cloud console > Google SecOps > Ingestion Settings."
  echo "DO: PS-7.2 steps 1 to 3 of setup/15 (Google Cloud Logging on for the organisation; Google's filters unmodified; the four"
  echo "  audit log ids at least)."
  echo "RECORD: penv_set SIEM_INGEST_PRINCIPAL \"<feed service account email, or direct-ingestion-google-managed>\""
  echo "VERIFY: PS-7.6 observes an entry. Evidence: <date>-PS-7.2-f2-ingestion-v1 (E-06)."
}

step PS-7.3 BLOCKED "F3: SCC Premium findings into SecOps" --note "B-06: P10 contract"
s_PS_7_3_check() { ckpt_done PS-7.3; }
s_PS_7_3_manual() {
  echo "BLOCKED on README B-06 (P10); the runner writes the BLOCKED checkpoint. When unblocked:"
  echo "WHO: the IT security SIEM administrator. WHERE: the Ingestion Settings page of PS-7.2."
  echo "DO: select Security Center Premium findings; PS-6.3's notification config stays (two independent paths)."
  echo "VERIFY: PS-7.6 finds the next PS-6.9 AGP_ROUTE_TEST finding. Evidence: <date>-PS-7.3-f3-scc-ingestion-v1 (E-06)."
}

step PS-7.4 BLOCKED "Access groups on the instance" --note "B-06: P10 contract"
s_PS_7_4_check() { ckpt_done PS-7.4; }
s_PS_7_4_manual() {
  echo "BLOCKED on README B-06 (P10); the runner writes the BLOCKED checkpoint. When unblocked:"
  echo "WHO: the IT security SIEM administrator; the second human reads. WHERE: SecOps RBAC."
  echo "DO: siem-readers@ read, siem-content@ rule editing; nobody from the platform owner's line edits or deploys rules."
  echo "VERIFY: no platform-owner write role and no agent principal. Evidence: <date>-PS-7.4-siem-access-v1, signed (E-08)."
}

step PS-7.5 BLOCKED "F1: the Workspace native SecOps export, connected by a super admin" --note "B-06: P10 contract"
s_PS_7_5_check() { ckpt_done PS-7.5; }
s_PS_7_5_manual() {
  echo "BLOCKED on README B-06 (P10); the runner writes the BLOCKED checkpoint. When unblocked:"
  echo "WHO: the second human as sa-2-admin@ connects; the SIEM administrator generates the token;"
  echo "  the incident commander witnesses. The token is never written anywhere."
  echo "WHERE: Admin console > Reporting > Data integrations > Google Security Operations export; SecOps > Settings > Google Workspace."
  echo "DO: PS-7.5 steps 1 to 3 of setup/15 (customer ID, token, Connect, in one sitting)."
  echo "VERIFY: the export shows connected; after 24 hours PS-7.6 observes an Admin event; record the connection's event name."
  echo "Evidence: <date>-PS-7.5-f1-workspace-export-v1 (E-06)."
}

step PS-7.6 BLOCKED "Observe one event from each feed" --note "B-06: P10 contract"
s_PS_7_6_check() { ckpt_done PS-7.6; }
s_PS_7_6_manual() {
  echo "BLOCKED on README B-06 (P10); the runner writes the BLOCKED checkpoint. When unblocked:"
  echo "WHO: the SIEM administrator searches; the second human makes the Workspace change; the platform"
  echo "  owner re-runs PS-5.5's view create and delete under ENT_PROJECT_REPAIR_CORE."
  echo "DO: PS-7.6 steps 1 to 4 of setup/15 (F1 test group agp-siem-canary@, F2 view, F3 the next weekly finding)."
  echo "VERIFY: three results with ingestion and event times; the lags recorded as budgets. Evidence: <date>-PS-7.6-feed-observation-v1."
}

step PS-8.1 BLOCKED "Reference lists for the super-admin set" --note "B-06: IT security's rule repository and its CI"
s_PS_8_1_check() { ckpt_done PS-8.1; }
s_PS_8_1_manual() {
  echo "BLOCKED on README B-06: the six reference lists are generated and deployed by the rule repository's CI from committed"
  echo "  sources (agp_roster_humans, agp_robot_accounts, agp_twin_accounts, agp_oauth_clients, agp_control_groups,"
  echo "  agp_reports_privilege_holders). When unblocked: CI's zero diff; the second human reviews the roster list."
}

step PS-8.2 BLOCKED "Rule code for SA-01..SA-09 and SG-01..SG-07" --note "B-06: rule code"
s_PS_8_2_check() { ckpt_done PS-8.2; }
s_PS_8_2_manual() {
  echo "BLOCKED on README B-06: IT security writes the sixteen rules with fixtures; the security reviewer reviews; CI lints with"
  echo "  verifyRuleText and refuses a rule without a fixture."
}

step PS-8.3 BLOCKED "Fixtures with production values, imported and run with Test Rule" --note "B-06: rule code and fixtures"
s_PS_8_3_check() { ckpt_done PS-8.3; }
s_PS_8_3_manual() {
  echo "BLOCKED on README B-06: synthetic UDM fixtures with production values, imported with events:import, rules created with"
  echo "  alerting off, Test Rule and a retrohunt per rule; a negative fixture per rule. Results exported per rule."
}

step PS-8.4 BLOCKED "Deploy the rules live" --note "B-06: rule code"
s_PS_8_4_check() { ckpt_done PS-8.4; }
s_PS_8_4_manual() {
  echo "BLOCKED on README B-06: CI sets enabled and alerting for each rule that passed PS-8.3, from the merged commit only;"
  echo "  rules.deployments.list shows all 16 live at the tested revision."
}

step PS-8.5 BLOCKED "The SIEM's paging targets" --note "B-06: P10 contract and the rules of PS-8.4"
s_PS_8_5_check() { ckpt_done PS-8.5; }
s_PS_8_5_manual() {
  echo "BLOCKED on README B-06 (P10, PS-8.4); the runner writes the BLOCKED checkpoint. When unblocked:"
  echo "WHO: the SIEM and paging administrators; the incident commander signs the routing table; the"
  echo "  second human reviews. Keys stay in IT security's SecOps configuration, never in a platform project."
  echo "DO: PS-8.5 steps 1 to 3 of setup/15 (subject routing to the two subject services; the rest to PAGER_SERVICE_NAME;"
  echo "  oncall/siem-routing.yaml merged with the second human as required reviewer)."
  echo "VERIFY: the SA-06 and SG-02 fixture re-imports page as PS-5.3 (a) to (d). Evidence: <date>-PS-8.5-siem-routing-test-v1."
}

step PS-8.6 BLOCKED "H-2: the canary pair" --note "B-05: H-2 canary code"
s_PS_8_6_check() { ckpt_done PS-8.6; }
s_PS_8_6_manual() {
  echo "BLOCKED on README B-05: the canary producing an F1 and an F2 event every 15 minutes without domain-wide delegation,"
  echo "  the SIEM absence rule at 45 minutes and the receipt topic; the Monitoring absence policy only after the first receipt."
}

step PS-8.7 BLOCKED "MDR 24x7 acknowledgement test" --note "B-06: P10 contract and the MDR retainer"
s_PS_8_7_check() { ckpt_done PS-8.7; }
s_PS_8_7_manual() {
  echo "BLOCKED on README B-06 (P10, the retainer, PS-8.4); the runner writes the BLOCKED checkpoint. When unblocked:"
  echo "WHO: IT security and the MDR desk lead; the paging administrator changes L1;"
  echo "  the second human confirms (witness); the incident commander signs."
  echo "DO: PS-8.7 steps 1 and 2 of setup/15 (MDR desk on L1 beside the second human; ONCALL_FILE tier_now: P by pull request;"
  echo "  two unannounced drills in a week, one outside business hours)."
  echo "VERIFY: acknowledged within 15 / 60 minutes (or the retainer's figures); the second human paged in parallel both times."
  echo "Evidence: <date>-PS-8.7-mdr-ack-test-v1 (E-08, E-10)."
}

step PS-8.8 BLOCKED "Optional: the sandbox tenant's own export for live fixtures" --note "B-06: P10 contract; optional"
s_PS_8_8_check() { ckpt_done PS-8.8; }
s_PS_8_8_manual() {
  echo "BLOCKED on README B-06 (P10); optional; the runner writes the BLOCKED checkpoint. When unblocked:"
  echo "WHO: a sandbox super admin connects; IT security generates the token."
  echo "DO: only if live sandbox events are wanted: PS-8.8 of setup/15 (the sandbox's own export, 24 hours before any capture;"
  echo "  twin accounts stay in agp_twin_accounts)."
  echo "VERIFY: a sandbox event appears and matches no production-severity rule. Evidence: <date>-PS-8.8-sandbox-export-v1."
}

step PS-8.9 BLOCKED "The SIEM principal on the K7 job (re-run after 18)" --note "B-06: K7_JOB from 18 KS-5.2 and the SIEM outbound principal"
s_PS_8_9_check() { ckpt_done PS-8.9; }
s_PS_8_9_manual() {
  echo "BLOCKED on README B-06: 18 has not created K7_JOB and IT security has not proven the SIEM's outbound principal."
  echo "  Until then the auto-K7 subset stays dry-run. When unblocked: PS-8.9's exists_or_pending and gcloud run jobs"
  echo "  add-iam-policy-binding --project=\"\$CORE_PROJECT\" --region=\"\$REGION\" --role=roles/run.invoker."
}

step PS-8.10 BLOCKED "The G2 record" --note "B-06: P10 contract; PS-7.1 to PS-8.9"
s_PS_8_10_check() { ckpt_done PS-8.10; }
s_PS_8_10_manual() {
  echo "BLOCKED on README B-06 (PS-7.1 to PS-8.9); the runner writes the BLOCKED checkpoint. When unblocked:"
  echo "WHO: IT security writes; the security reviewer signs; the second human co-signs."
  echo "WHERE: the platform repository, gates/ as 42 keeps it."
  echo "DO: the G2 record citing PS-7.1 to PS-8.9 (location, retention, three feeds, 16 rules, routing test, H-2, MDR times, K7)."
  echo "VERIFY: 38's checklist parser (or the signed manual parse, SD-36) accepts G2 with a date and signer."
  echo "Evidence: <date>-PS-8.10-g2-record-v1 (E-05, E-10)."
}
