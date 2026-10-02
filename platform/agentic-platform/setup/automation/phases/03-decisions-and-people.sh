# phases/03-decisions-and-people.sh: setup/03, decisions, people and the platform repository.
#
# Nothing on this page creates a Google Cloud or Workspace resource (setup/03 §2), so the phase declares
# no `requires`. The script does three things itself: it installs the decision mechanism byte for byte
# from the page (DC-1.1, DC-1.2: the template and the three tools the runner's gates call), and it proves
# the bootstrap commits and opens BD-03-1 before the push (DC-9.1). Every appointment and every signature
# is HUMAN: the script never drafts, signs or reads a decision value into ~/.platform-env; the person
# types the page's `decision-value.sh ... && penv_set` lines once the record is signed.
#
# The git host (§12, DC-9.2 to DC-9.11). The page's WHERE for these steps is a shell with `gh` or git,
# not a console, so none of them is CONSOLE. This phase's rule, which is not a rule of setup/03: a step
# that runs `gh` or a git network command against the git host is HUMAN. The platform owner runs the
# page's block in their own shell, signed in to `gh` and git as themselves, with the second person the
# page's WHO names (the witness, the confirmer or the approver) present; each block writes its own
# checkpoints, or `agp-platform done ID --witness EMAIL` records the step (the id typed to confirm).
# Why not AUTO, as phase 16 RG-1.3 is: these steps create the repository, push the history (DC-9.5,
# IRREVERSIBLE) and set the protection, and each also needs work only a person can do here (typing the
# organisation, a grant in the organisation settings, two mailed address proofs, a second approval).
# The offline tests now have a `gh` fake and local bare remotes, so testability is no longer the reason:
# the work only a person can do is. tests/standins/03.tsv stands in for what those people produce (the
# tracker, the records, CODEOWNERS, the push). DC-9.1 is AUTO: it reads and commits locally and contacts
# no host.
#
# A signing step reads as done when `agp-platform done ID` recorded it, or when tools/decision-need.sh
# prints SIGNED for its ids and every value it sets is in ~/.platform-env (setup/03 §4.2).

phase 03 "Decisions, people and the platform repository" "03-decisions-and-people.md"

# ---------------------------------------------------------------- helpers (prefixed: every phase shares one shell)
p03_log() {         # p03_log LINE...: append to the page's build-log file (DC-1.1, DC-1.2)
  local f; f="$(v BUILD_LOG_DIR)/03-decisions-and-people.log"
  { if [ -f "$f" ]; then cat "$f"; fi; printf '%s\n' "$@"; } | xw "$f" 644
}

p03_signed() {      # p03_signed ID...: 0 when tools/decision-need.sh prints SIGNED for every id
  local t; t="$(v PLATFORM_REPO_DIR)/tools/decision-need.sh"
  [ -x "$t" ] || return 1
  "$t" "$@" >/dev/null 2>&1
}

p03_set() {         # p03_set NAME...: 0 when every name holds a real value
  local n
  for n in "$@"; do has_value "$n" || return 1; done
  return 0
}

p03_distinct() {    # p03_distinct NAME...: 0 when the values that are set are pairwise different
  local n vals=""
  for n in "$@"; do
    if has_value "$n"; then vals="$vals$(_penv_get "$n")
"; fi
  done
  [ -z "$(printf '%s' "$vals" | sort | uniq -d)" ]
}

p03_decided() {     # p03_decided "IDS" "NAMES" ["DISTINCT NAMES"]: signed, recorded and distinct
  # shellcheck disable=SC2086
  p03_signed $1 && p03_set $2 && p03_distinct ${3-}
}

p03_record() {      # p03_record ID: the record file the tracker names for ID (setup/03 §4.2, idiom 2)
  awk -F'|' -v id="$1" '{k=$2; gsub(/ /,"",k); if (k==id) {r=$4; gsub(/ /,"",r); print r}}' \
    "$(v PLATFORM_REPO_DIR)/decisions/TRACKER.md" 2>/dev/null | head -n 1
}

p03_record_has() {  # p03_record_has ID PATTERN: the signed record of ID contains PATTERN (grep -E)
  local f; f="$(p03_record "$1")"
  case "$f" in ''|'*tbd*') return 1;; esac
  grep -Eq -- "$2" "$(v PLATFORM_REPO_DIR)/decisions/$f"
}

p03_value() {       # p03_value ID NAME: the Values cell of the signed record (decision-value.sh)
  "$(v PLATFORM_REPO_DIR)/tools/decision-value.sh" "$1" "$2" 2>/dev/null
}

p03_dv() {          # p03_dv ID NAME: the page's two-step line that reads a signed value (§4.2, idiom 1)
  printf '  v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" %s %s) && penv_set %s "$v"\n' "$1" "$2" "$2"
}

p03_sign() {        # p03_sign STEP "WHO" "record file" "IDS" "extra line or empty": the head of a signing step's manual
  echo "WHO: $2"
  echo "WHERE: decisions/$3 in $(v PLATFORM_REPO_DIR), drafted and signed as in DC-1.4 (each signatory replies"
  echo "  from their own account; each reply saved to EVIDENCE_INTERIM_LOCATION); tracker rows; commit with a review record."
  echo "DO: the record body setup/03 $1 states. This script never drafts, signs or records a decision."
  [ -z "$5" ] || echo "$5"
}

p03_end() {         # p03_end STEP "IDS": a signing step's check and how it is recorded
  echo "CHECK: \"\$PLATFORM_REPO_DIR/tools/decision-need.sh\" $2 prints SIGNED for each."
  p03_done_line "$1"
}

p03_done_line() {   # p03_done_line STEP [witness role]: how a person records the step
  if [ -n "${2-}" ]; then echo "THEN: agp-platform done $1 --witness <$2 email>"
  else echo "THEN: agp-platform done $1   (or re-run apply: the step reads as done once signed and recorded)"; fi
}

# ---------------------------------------------------------------- §4 how a record is made, signed and checked
step DC-1.1 AUTO "Create decisions/, tools/ and the record template" --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_DC_1_1_check() {
  local r; r="$(v PLATFORM_REPO_DIR)"
  [ -d "$r/decisions" ] && [ -d "$r/tools" ] && [ -f "$r/decisions/_template.md" ] || return 1
  [ "$(grep -c '^## ' "$r/decisions/_template.md")" = 7 ]
}
s_DC_1_1_apply() {
  local r; r="$(v PLATFORM_REPO_DIR)"
  # The page's `test -z "$(gcloud config get project)"` is the runner's preflight (penv_guard), run before every apply.
  x mkdir -p "$r/decisions" "$r/tools" || return 1
  xw "$r/decisions/_template.md" 644 < "$AGP_HOME/assets/decision-template.md" || return 1
  p03_log "$(date -u +%FT%TZ) DC-1.1 done"
}

p03_fixture() {     # setup/03 DC-1.2 VERIFY: a signed fixture must pass, a tampered copy must fail twice
  local r t h out1 out2 rc1 rc2
  r="$(v PLATFORM_REPO_DIR)"
  [ -x "$r/tools/decision-check.sh" ] && [ -f "$r/decisions/_template.md" ] || return 1
  t="$(mktemp -d "${TMPDIR:-/tmp}/agp-dc12.XXXXXX")" || return 1
  sed -e '1s/.*/# 2026-09-15 — Fixture/' -e 's/proposed/accepted/' "$r/decisions/_template.md" > "$t/2026-09-15-fixture.md"
  h=$(awk '/^## Context$/{p=1} /^## Signatures$/{p=0} p' "$t/2026-09-15-fixture.md" | shasum -a 256 | cut -d' ' -f1)
  printf '| PO | Fixture | 2026-09-15 | %s | fixture-po |\n| SH | Fixture | 2026-09-15 | %s | fixture-sh |\n' "$h" "$h" >> "$t/2026-09-15-fixture.md"
  out1="$("$r/tools/decision-check.sh" "$t/2026-09-15-fixture.md")"; rc1=$?
  sed 's/^What forced the choice.*/Changed after signing./' "$t/2026-09-15-fixture.md" > "$t/2026-09-15-tampered.md"
  out2="$("$r/tools/decision-check.sh" "$t/2026-09-15-tampered.md")"; rc2=$?
  rm -r -f "$t"
  printf '%s\n%s\nexit=%s\n' "$out1" "$out2" "$rc2"
  [ "$rc1" -eq 0 ] && [ "$out1" = "OK   2026-09-15-fixture.md $h" ] && [ "$rc2" -eq 1 ] \
    && [ "$(printf '%s\n' "$out2" | grep -cE '^FAIL 2026-09-15-tampered\.md: signature (PO|SH) signed a different body$')" = 2 ]
}

step DC-1.2 AUTO "Write the three decision tools and prove they refuse" --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR" \
  --note "reviewer, not a witness: the bootstrap reviewer (the named second human of 01 §2.1) reviews this commit in DC-1.3"
s_DC_1_2_check() {
  local r f; r="$(v PLATFORM_REPO_DIR)"
  for f in decision-check.sh decision-need.sh decision-value.sh; do
    [ -x "$r/tools/$f" ] && cmp -s "$AGP_HOME/assets/$f" "$r/tools/$f" || return 1
  done
  p03_fixture >/dev/null
}
s_DC_1_2_apply() {
  local r f out; r="$(v PLATFORM_REPO_DIR)"
  for f in decision-check.sh decision-need.sh decision-value.sh; do
    if [ -f "$r/tools/$f" ] && ! cmp -s "$AGP_HOME/assets/$f" "$r/tools/$f"; then
      printf '      %s differs from setup/03 DC-1.2: the page'"'"'s version is written over it\n' "$r/tools/$f" >&3
    fi
    xw "$r/tools/$f" 755 < "$AGP_HOME/assets/$f" || return 1
  done
  if [ "$AGP_MODE" != apply ]; then
    printf '      would run the DC-1.2 fixture: OK for the signed record, two FAIL lines and exit=1 for the tampered one\n' >&3
    p03_log "<UTC time> DC-1.2 verify output"
    return 0
  fi
  out="$(p03_fixture)"; local rc=$?
  printf '%s\n' "$out" | sed 's/^/        /' >&3
  if [ $rc -ne 0 ]; then printf '      the DC-1.2 fixture did not print what the page expects; the tools refuse nothing\n' >&3; return 1; fi
  p03_log "$(date -u +%FT%TZ) DC-1.2 verify:" "$out"
}

p03_tracker_ok() {  # DC-1.3 VERIFY on the committed tracker (the review-record half is for the person: HEAD moves on)
  local r t id; r="$(v PLATFORM_REPO_DIR)"; t="$r/decisions/TRACKER.md"
  [ -f "$t" ] && git -C "$r" ls-files --error-unmatch decisions/TRACKER.md >/dev/null 2>&1 || return 1
  [ -z "$(awk -F'|' 'NR>2 && NF>=7 {k=$2; gsub(/ /,"",k); print k}' "$t" | sort | uniq -d)" ] || return 1
  for id in SD-01 SD-24 SD-48 D8 D13 WDEC-6 WDEC-29 E-16 TD-44 M-1 P22 P63 P99 P137 NAMES KEYS SH-REPORTS PPL-SH; do
    grep -q "^| $id |" "$t" || return 1
  done
}

step DC-1.3 HUMAN "Create the tracker and commit with a review record" --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_DC_1_3_check() { ckpt_done DC-1.3 || p03_tracker_ok; }
s_DC_1_3_manual() {
  echo "WHO: the platform owner commits; the bootstrap reviewer (the named second human of 01 §2.1) signs the review record. Covered by BD-03-1 (DC-9.1)."
  echo "WHERE: $(v PLATFORM_REPO_DIR)/decisions/TRACKER.md, then a shell with ~/.platform-env sourced."
  echo "DO: write TRACKER.md: | Id | Title | Record | Gates | Signatories | Status |, one row per id of §5 and §11"
  echo "  (each appointment id its own row; Record *tbd*, Status open). Then export BOOTSTRAP_REVIEWER='<name>, <role>'"
  echo "  (a shell variable, never penv_set) and run setup/03 DC-1.3's git add, commit and reviews/<sha>.md block (dates UTC)."
  echo "SAVE: the reviewer's approval mail quoting the commit hash to EVIDENCE_INTERIM_LOCATION as <date>-DC-1.3-review-v1."
  echo "CHECK: DC-1.3's VERIFY prints no duplicate, no 'missing' line, 'reviewed', and no FAIL line."
  p03_done_line DC-1.3
}

p03_any_record_ok() {   # at least one record under decisions/ parses and matches its signatures
  local r f; r="$(v PLATFORM_REPO_DIR)"
  [ -x "$r/tools/decision-check.sh" ] || return 1
  for f in "$r"/decisions/20*.md; do
    [ -f "$f" ] && "$r/tools/decision-check.sh" "$f" >/dev/null 2>&1 && return 0
  done
  return 1
}

step DC-1.4 HUMAN "The signing procedure every record follows" --needs "PLATFORM_REPO_DIR" --on-unmet skip \
  --note "the procedure every signing step below follows; nothing later waits on this row itself"
s_DC_1_4_check() { ckpt_done DC-1.4 || p03_any_record_ok; }
s_DC_1_4_manual() {
  echo "WHO: the platform owner drafts and collects; each required signatory signs from their own account."
  echo "WHERE: $(v PLATFORM_REPO_DIR); mail from each signatory's own account."
  echo "DO: setup/03 DC-1.4's block copies decisions/_template.md to decisions/<UTC date>-<slug>.md; fill ids, signatories,"
  echo "  every body section, Values and Gates; hash the body (## Context to ## Signatures) and send it. Each reply:"
  echo "  \"I sign <file>, body SHA-256 <hash>, as <role id>\", saved as <date>-<step-id>-<slug>-<role>-v1. One row per reply;"
  echo "  then Status accepted, the tracker rows' Record and Status, a commit with a review record, one EVIDENCE_REGISTER line."
  echo "CHECK: tools/decision-check.sh <record> prints OK; tools/decision-need.sh <its ids> prints SIGNED for each."
  echo "This row reads as done once one record passes; to close it by hand: agp-platform done DC-1.4"
}

# ---------------------------------------------------------------- §5 people, appointed with dates
step DC-2.1 HUMAN "Appoint the second human (PPL-SH, E-2)" --needs "PLATFORM_REPO_DIR OWNER_DAILY_ACCOUNT" --sets "SECOND_HUMAN_EMAIL"
s_DC_2_1_check() {
  ckpt_done DC-2.1 && return 0
  p03_decided "PPL-SH E-2" "SECOND_HUMAN_EMAIL" "SECOND_HUMAN_EMAIL OWNER_DAILY_ACCOUNT" && p03_record_has PPL-SH 'DC-1\.2'
}
s_DC_2_1_manual() {
  p03_sign DC-2.1 "ISMS names; the appointee accepts; the platform owner drafts. Signatories ISMS, SH, PO." \
    "<date>-appointment-second-human.md" "PPL-SH E-2" \
    "  The record names the person who reviewed DC-1.2 and DC-1.3 as BOOTSTRAP_REVIEWER (it must contain 'DC-1.2')."
  echo "RECORD, once signed (typed by you):"; p03_dv PPL-SH SECOND_HUMAN_EMAIL
  echo "  The address differs from OWNER_DAILY_ACCOUNT."
  p03_end DC-2.1 "PPL-SH E-2"
}

step DC-2.2 HUMAN "Appoint the incident commander and fix the recipient of reports about the second human (PPL-IC, SH-REPORTS)" \
  --needs "PLATFORM_REPO_DIR OWNER_DAILY_ACCOUNT" --sets "INCIDENT_COMMANDER_EMAIL"
s_DC_2_2_check() { ckpt_done DC-2.2 || p03_decided "PPL-IC SH-REPORTS" "INCIDENT_COMMANDER_EMAIL" "INCIDENT_COMMANDER_EMAIL OWNER_DAILY_ACCOUNT"; }
s_DC_2_2_manual() {
  p03_sign DC-2.2 "ISMS names; the incident commander accepts; IT security signs SH-REPORTS. Two records." \
    "<date>-appointment-incident-commander.md and <date>-recipient-of-reports-about-second-human.md" "PPL-IC SH-REPORTS" \
    "  SH-REPORTS: reports about the second human go to the security reviewer, to the incident commander until PPL-SR is signed; never to SH or PO."
  echo "RECORD, once signed (typed by you):"; p03_dv PPL-IC INCIDENT_COMMANDER_EMAIL
  echo "  The address differs from OWNER_DAILY_ACCOUNT, and from SECOND_HUMAN_EMAIL unless the ISMS record says otherwise (then 26 stays BLOCKED until SR)."
  p03_end DC-2.2 "PPL-IC SH-REPORTS"
}

step DC-2.3 HUMAN "Appoint the security reviewer and the validator custodian (PPL-SR, PPL-VC)" \
  --needs "PLATFORM_REPO_DIR OWNER_DAILY_ACCOUNT" --sets "SECURITY_REVIEWER_EMAIL VALIDATOR_CUSTODIAN_EMAIL"
s_DC_2_3_check() {
  ckpt_done DC-2.3 || p03_decided "PPL-SR PPL-VC" "SECURITY_REVIEWER_EMAIL VALIDATOR_CUSTODIAN_EMAIL" "SECURITY_REVIEWER_EMAIL OWNER_DAILY_ACCOUNT"
}
s_DC_2_3_manual() {
  p03_sign DC-2.3 "ISMS; the appointees; the platform owner. The PPL-SR record also supersedes SH-REPORTS to point at SR." \
    "<date>-appointment-security-reviewer.md and <date>-appointment-validator-custodian.md" "PPL-SR PPL-VC" \
    "  Not available yet: commit the tracker rows as *tbd* with a dated note of whom ISMS asked; never sign a placeholder."
  echo "RECORD, once signed (typed by you):"; p03_dv PPL-SR SECURITY_REVIEWER_EMAIL; p03_dv PPL-VC VALIDATOR_CUSTODIAN_EMAIL
  echo "  Still *tbd*: agp-platform done DC-2.3 --note '<who ISMS asked, date>'; need SECURITY_REVIEWER_EMAIL then stops 11, 31 and 38."
  p03_end DC-2.3 "PPL-SR PPL-VC"
}

step DC-2.4 HUMAN "Appoint the second operator and the blind grader (PPL-SO, PPL-BG, D5)" \
  --needs "PLATFORM_REPO_DIR OWNER_DAILY_ACCOUNT" --sets "SECOND_OPERATOR_EMAIL BLIND_GRADER_EMAIL"
s_DC_2_4_check() {
  ckpt_done DC-2.4 || p03_decided "PPL-SO PPL-BG D5" "SECOND_OPERATOR_EMAIL BLIND_GRADER_EMAIL" "SECOND_OPERATOR_EMAIL OWNER_DAILY_ACCOUNT SECOND_HUMAN_EMAIL"
}
s_DC_2_4_manual() {
  p03_sign DC-2.4 "ISMS; the appointees; the platform owner; the Mo owner signs the grader's record." \
    "<date>-appointment-second-operator.md and <date>-appointment-blind-grader.md" "PPL-SO PPL-BG D5" \
    "  PPL-SO closes D5's first half; the grader's record names the playbooks the grader must not own."
  echo "RECORD, once signed (typed by you):"; p03_dv PPL-SO SECOND_OPERATOR_EMAIL; p03_dv PPL-BG BLIND_GRADER_EMAIL
  echo "  The second operator differs from the platform owner and the second human."
  p03_end DC-2.4 "PPL-SO PPL-BG D5"
}

step DC-2.5 HUMAN "Appoint the two witness administrators (PPL-WA1, PPL-WA2)" \
  --needs "PLATFORM_REPO_DIR OWNER_DAILY_ACCOUNT" --sets "WITNESS_ADMIN_1_EMAIL WITNESS_ADMIN_2_EMAIL"
s_DC_2_5_check() {
  ckpt_done DC-2.5 || p03_decided "PPL-WA1 PPL-WA2" "WITNESS_ADMIN_1_EMAIL WITNESS_ADMIN_2_EMAIL" \
    "WITNESS_ADMIN_1_EMAIL WITNESS_ADMIN_2_EMAIL OWNER_DAILY_ACCOUNT SECOND_HUMAN_EMAIL SECOND_OPERATOR_EMAIL"
}
s_DC_2_5_manual() {
  p03_sign DC-2.5 "ISMS names two IT security people; IT security co-signs; the appointees accept." \
    "<date>-appointment-witness-administrator-1.md and -2.md" "PPL-WA1 PPL-WA2" \
    "  Each: never a tenant super admin, not PO, SH or SO; the other's recovery path; two hardware keys (04)."
  echo "RECORD, once signed (typed by you):"; p03_dv PPL-WA1 WITNESS_ADMIN_1_EMAIL; p03_dv PPL-WA2 WITNESS_ADMIN_2_EMAIL
  echo "  DC-2.5's uniqueness check prints nothing (the two differ from each other, PO, SH and SO)."
  p03_end DC-2.5 "PPL-WA1 PPL-WA2"
}

step DC-2.6 HUMAN "Appoint the two sandbox super admins (PPL-SB1, PPL-SB2)" \
  --needs "PLATFORM_REPO_DIR" --sets "SANDBOX_SA_1_EMAIL SANDBOX_SA_2_EMAIL"
s_DC_2_6_check() {   # the page's VERIFY "now" half: two signed records; the addresses come after 04 PU-2.5
  ckpt_done DC-2.6 && return 0
  p03_signed PPL-SB1 PPL-SB2 && p03_distinct SANDBOX_SA_1_EMAIL SANDBOX_SA_2_EMAIL
}
s_DC_2_6_manual() {
  p03_sign DC-2.6 "ISMS; the appointees; the platform owner. Two distinct humans; requester and approver differ (SD-25)." \
    "<date>-appointment-sandbox-super-admin-1.md and -2.md" "PPL-SB1 PPL-SB2" \
    "  Now: each record names its person; the Values cell reads *tbd*, because SANDBOX_DOMAIN exists only from 04 PU-2.5."
  echo "CHECK NOW: \"\$PLATFORM_REPO_DIR/tools/decision-need.sh\" PPL-SB1 PPL-SB2 prints SIGNED twice, for two different people."
  echo "  need SANDBOX_SA_1_EMAIL fails until later; that is expected. 04 reads the two people from these records."
  p03_done_line DC-2.6
  echo "LATER, after 04 PU-2.5 and before 21: superseding records add the two @SANDBOX_DOMAIN addresses; then (typed by you):"
  p03_dv PPL-SB1 SANDBOX_SA_1_EMAIL; p03_dv PPL-SB2 SANDBOX_SA_2_EMAIL
  echo "  and need SANDBOX_SA_1_EMAIL SANDBOX_SA_2_EMAIL passes, the two differ, both end in @SANDBOX_DOMAIN."
}

step DC-2.7 HUMAN "Appoint the billing administrator and the Mo owner (PPL-BA, PPL-MO)" \
  --needs "PLATFORM_REPO_DIR OWNER_DAILY_ACCOUNT" --sets "BILLING_ADMIN_EMAIL MO_OWNER_EMAIL"
s_DC_2_7_check() { ckpt_done DC-2.7 || p03_decided "PPL-BA PPL-MO" "BILLING_ADMIN_EMAIL MO_OWNER_EMAIL" "BILLING_ADMIN_EMAIL OWNER_DAILY_ACCOUNT"; }
s_DC_2_7_manual() {
  p03_sign DC-2.7 "finance names the billing administrator; ISMS names the Mo owner (default: the platform owner, recorded as such)." \
    "<date>-appointment-billing-administrator.md and <date>-appointment-mo-owner.md" "PPL-BA PPL-MO" ""
  echo "RECORD, once signed (typed by you):"; p03_dv PPL-BA BILLING_ADMIN_EMAIL; p03_dv PPL-MO MO_OWNER_EMAIL
  echo "  The billing administrator is not the platform owner."
  p03_end DC-2.7 "PPL-BA PPL-MO"
}

step DC-2.8 HUMAN "Count the people and sign the separation (P137, SD-04 count)" --needs "PLATFORM_REPO_DIR" --on-unmet skip
s_DC_2_8_check() { ckpt_done DC-2.8 && return 0; p03_signed P137 && [ "$(p03_value P137 GRANT_MIN_HUMANS)" = 5 ]; }
s_DC_2_8_manual() {
  p03_sign DC-2.8 "ISMS signs; the platform owner drafts; IT security co-signs." "<date>-separation-and-count.md" "P137" \
    "  The ../11-tisax.md §7.1 table with a name in every filled cell; Values GRANT_MIN_HUMANS=5, TIER_W_MIN_HUMANS=3 (record values only)."
  echo "  \"\$PLATFORM_REPO_DIR/tools/decision-value.sh\" P137 GRANT_MIN_HUMANS prints 5."
  p03_end DC-2.8 "P137"
}

# ---------------------------------------------------------------- §6 week one: the data-protection letter
step DC-3.1 HUMAN "Send the D7 letter, covering Wall-E and the monitoring of named administrators (D7-LETTER)" \
  --needs "PLATFORM_REPO_DIR" --sets "DPO_CONTACT"
s_DC_3_1_check() { ckpt_done DC-3.1 || p03_decided "D7-LETTER" "DPO_CONTACT"; }
s_DC_3_1_manual() {
  echo "WHO: the platform owner sends from OWNER_DAILY_ACCOUNT; the DPO and HR receive; legal in copy."
  echo "WHEN: by 2026-09-21. If that date is past and the letter has not left, send it the day this step runs; the record's"
  echo "  Context states the planned date, the real date and the reason. A late letter delays 25 (SD-11) and 39's Stage 1 (D7), nothing else."
  echo "DO: the four questions of setup/03 DC-3.1 (Wall-E's processing; Eve's monitoring of named administrators, SD-11;"
  echo "  retention per store, P13, E-14, M-5, P52; works-council information). Save the sent mail as <date>-DC-3.1-d7-letter-v1."
  echo "RECORD: decisions/<date>-d7-letter.md per DC-1.4, required signatory PO only, Values DPO_CONTACT; then (typed by you):"
  p03_dv D7-LETTER DPO_CONTACT
  echo "CHECK: \"\$PLATFORM_REPO_DIR/tools/decision-need.sh\" D7-LETTER prints SIGNED; the record date is on or before 2026-09-21,"
  echo "  or its Context states the late date and the reason."
  p03_done_line DC-3.1
}

step DC-3.2 HUMAN "Record the DPO's answer on administrator monitoring (SD-11, D7)" --needs "PLATFORM_REPO_DIR" --on-unmet skip \
  --note "25's reconciler and poll jobs are BLOCKED until SD-11 is signed"
s_DC_3_2_check() { ckpt_done DC-3.2 || p03_signed SD-11; }
s_DC_3_2_manual() {
  p03_sign DC-3.2 "the DPO signs; SH and PO co-sign; HR signs the works-council half." "<date>-monitoring-of-administrators.md" "SD-11" \
    "  Legal basis, purpose, data, retention, recipients and the works-council answer. A later D7 answer for Wall-E gets its own record."
  p03_end DC-3.2 "SD-11"
}

# ---------------------------------------------------------------- §7 decisions before the organisation is touched
step DC-4.1 HUMAN "Sign the setup conventions and the bootstrap deviation" --needs "PLATFORM_REPO_DIR" --on-unmet skip
s_DC_4_1_check() {
  ckpt_done DC-4.1 && return 0
  p03_signed SD-01 SD-13 SD-17 SD-22 SD-35 SD-37 SD-38 SD-40 SD-41 SD-44 SD-45 || return 1
  p03_value SD-01 BOOTSTRAP_EXCEPTION_EXPIRY | grep -Eqx '[0-9]{4}-[0-9]{2}-[0-9]{2}'
}
s_DC_4_1_manual() {
  p03_sign DC-4.1 "the platform owner drafts; IT security and ISMS sign." "<date>-setup-conventions-and-bootstrap-deviation.md" \
    "SD-01 SD-13 SD-17 SD-22 SD-35 SD-37 SD-38 SD-40 SD-41 SD-44 SD-45" \
    "  Each resolution of the plan's §6 verbatim; Values BOOTSTRAP_EXCEPTION_EXPIRY (YYYY-MM-DD), which 06 OB-3.2 reads."
  echo "  \"\$PLATFORM_REPO_DIR/tools/decision-value.sh\" SD-01 BOOTSTRAP_EXCEPTION_EXPIRY prints a YYYY-MM-DD date."
  p03_end DC-4.1 "SD-01 SD-13 SD-17 SD-22 SD-35 SD-37 SD-38 SD-40 SD-41 SD-44 SD-45"
}

step DC-4.2 HUMAN "Sign the Gemini Enterprise app location: eu only (D8, SD-21)" --needs "PLATFORM_REPO_DIR" --on-unmet skip
s_DC_4_2_check() { ckpt_done DC-4.2 || p03_signed D8 SD-21; }
s_DC_4_2_manual() {
  p03_sign DC-4.2 "the platform owner. No second signatory." "<date>-gemini-app-location.md" "D8 SD-21" \
    "  Body: the app location must be eu; a global or us app stops the build at 05 (X-GE-13). 05 checks this record."
  p03_end DC-4.2 "D8 SD-21"
}

step DC-4.3 HUMAN "Sign the git host and admin-bypass rule (P22, SD-14, M-7)" --needs "PLATFORM_REPO_DIR" --sets "GIT_HOST GIT_OIDC_ISSUER"
s_DC_4_3_check() {
  ckpt_done DC-4.3 && return 0
  p03_decided "P22 SD-14 M-7" "GIT_HOST GIT_OIDC_ISSUER" || return 1
  case "$(_penv_get GIT_OIDC_ISSUER)" in https://*) return 0;; *) return 1;; esac
}
s_DC_4_3_manual() {
  p03_sign DC-4.3 "the platform owner; IT security." "<date>-git-host-and-repository.md" "P22 SD-14 M-7" \
    "  Values: GIT_HOST github.com or gitlab.com; GIT_OIDC_ISSUER https://token.actions.githubusercontent.com/ or https://gitlab.com."
  echo "RECORD, once signed (typed by you):"; p03_dv P22 GIT_HOST; p03_dv P22 GIT_OIDC_ISSUER
  echo "  DC-4.3's case line prints ok (the issuer is an https URL). A self-managed host is *tbd* and 10 stops."
  p03_end DC-4.3 "P22 SD-14 M-7"
}

step DC-4.4 HUMAN "Inventory the admin roles and sign the G3 roster reduction, custody and recovery timing (G3-ROSTER, SD-27, SD-30)" \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR" --witness --on-unmet skip
s_DC_4_4_check() { ckpt_done DC-4.4; }
s_DC_4_4_manual() {
  echo "WHO: the platform owner reads as a current super admin with the second human present (the witness); IT security signs; SH co-signs."
  echo "WHERE: Admin console, Menu > Account > Admin roles: Super Admin first, then every other role, View admins. Read only."
  echo "DO: write each account and role into $(v BUILD_LOG_DIR)/03-roster-inventory-<date>.md, never into the wiki."
  echo "  Then decisions/<date>-roster-reduction-and-custody.md per DC-1.4: one row per current super admin with its target"
  echo "  delegated role and owner (executed in 06); SD-27 paper custody until W-2; SD-30 self-recovery Off and multi-party approval in 38."
  echo "CHECK: \"\$PLATFORM_REPO_DIR/tools/decision-need.sh\" G3-ROSTER SD-27 SD-30 prints SIGNED for each; the inventory has a Super Admin row"
  echo "  and its line count matches the record's table. Re-read it if 06 runs more than 30 days later."
  p03_done_line DC-4.4 "second human"
}

step DC-4.5 HUMAN "Sign the billing account, the SCC payer and the SIEM (P31, SD-16, P11, SD-15, P10)" \
  --needs "PLATFORM_REPO_DIR" --sets "SCC_BILLING_MODEL SIEM_KIND"
s_DC_4_5_check() {
  ckpt_done DC-4.5 && return 0
  p03_decided "P31 SD-16 P11 SD-15 P10" "SCC_BILLING_MODEL SIEM_KIND" || return 1
  case "$(_penv_get SCC_BILLING_MODEL)" in payg-org|subscription) ;; *) return 1;; esac
  case "$(_penv_get SIEM_KIND)" in secops|existing) ;; *) return 1;; esac
  [ -n "$(p03_value SD-16 BILLING_ACCOUNT_ID)" ] && [ -n "$(p03_value SD-16 BOOTSTRAP_BILLING_EXPIRY)" ]
}
s_DC_4_5_manual() {
  echo "WHO: finance and the billing administrator (P31); IT security and finance (P11); IT security (P10); the platform owner drafts."
  echo "READ, by the billing administrator in their own shell (the platform owner holds no billing role yet):"
  echo "  gcloud billing accounts describe \"<candidate-billing-account-id>\" --format=\"value(open,currencyCode,masterBillingAccount,parent)\""
  echo "  Stop unless open is True, masterBillingAccount is empty, and the currency is EUR (or the record states the budgets' currency)."
  echo "RECORD: decisions/<date>-billing-scc-and-siem.md per DC-1.4. Values SCC_BILLING_MODEL (payg-org|subscription), SIEM_KIND"
  echo "  (secops|existing), and under SD-16 BILLING_ACCOUNT_ID and BOOTSTRAP_BILLING_EXPIRY (YYYY-MM-DD; 07 reads both). Then:"
  p03_dv P11 SCC_BILLING_MODEL; p03_dv P10 SIEM_KIND
  echo "CHECK: decision-need.sh P31 SD-16 P11 SD-15 P10 prints SIGNED for each; DC-4.5's two case lines print ok."
  p03_done_line DC-4.5
}

step DC-4.6 HUMAN "Sign the witness organisation (P14, SD-04, SD-28)" --needs "PLATFORM_REPO_DIR" --on-unmet skip
s_DC_4_6_check() { ckpt_done DC-4.6 && return 0; p03_signed P14 SD-04 SD-28 && p03_record_has P14 '^\| WA1 \|' && p03_record_has P14 '^\| WA2 \|'; }
s_DC_4_6_manual() {
  p03_sign DC-4.6 "IT security, ISMS, finance, WA1, WA2 and SH sign; the platform owner drafts." "<date>-witness-organisation.md" "P14 SD-04 SD-28" \
    "  Administrators, separately registered domain, edition, a billing account parented by the witness, Customer Care support (X-ORG-05, -08, -09)."
  echo "  The record's signature table has rows WA1 and WA2."
  p03_end DC-4.6 "P14 SD-04 SD-28"
}

step DC-4.7 HUMAN "Sign the sandbox tenant: timing and edition (decision 29, SD-29, D3)" --needs "PLATFORM_REPO_DIR" --on-unmet skip
s_DC_4_7_check() { ckpt_done DC-4.7 || p03_signed WDEC-29 SD-29 D3; }
s_DC_4_7_manual() {
  p03_sign DC-4.7 "the platform owner; IT security; finance." "<date>-sandbox-tenant.md" "WDEC-29 SD-29 D3" \
    "  Before the super-admin grant; edition equal to production, at least Enterprise Standard; domain, seats, P59, twin-robot 2SV keys."
  p03_end DC-4.7 "WDEC-29 SD-29 D3"
}

step DC-4.8 HUMAN "Sign retention: ceilings, locks and no reduction (P13, E-14, M-5, P52, SD-20)" \
  --needs "PLATFORM_REPO_DIR" --sets "EVIDENCE_RETENTION_DAYS IDENTITY_RETENTION_DAYS"
s_DC_4_8_check() {
  ckpt_done DC-4.8 && return 0
  p03_decided "P13 E-14 M-5 P52 SD-20" "EVIDENCE_RETENTION_DAYS IDENTITY_RETENTION_DAYS" || return 1
  case "$(_penv_get EVIDENCE_RETENTION_DAYS)" in ''|*[!0-9]*) return 1;; *) return 0;; esac
}
s_DC_4_8_manual() {
  p03_sign DC-4.8 "the DPO signs; the platform owner, the Mo owner and SH co-sign; HR for the user-notice rule." "<date>-retention.md" \
    "P13 E-14 M-5 P52 SD-20" "  Every lock value equals its ceiling; the baseline never lowers GE_RETENTION_CURRENT_DAYS; no value from P52's 30 days."
  echo "RECORD, once signed (typed by you):"; p03_dv P13 EVIDENCE_RETENTION_DAYS; p03_dv P13 IDENTITY_RETENTION_DAYS
  echo "  Integers, or *tbd* while the DPO has not answered: then agp-platform done DC-4.8 --note 'DPO answer pending'; every lock refuses."
  p03_end DC-4.8 "P13 E-14 M-5 P52 SD-20"
}

step DC-4.9 HUMAN "Sign the paging tool and the device-posture licence count (P99, P63)" --needs "PLATFORM_REPO_DIR" --on-unmet skip \
  --note "gates only 04's two purchase commitments (PU-2.6, PU-2.9); 04 quotes both meanwhile"
s_DC_4_9_check() { ckpt_done DC-4.9 || p03_signed P99 P63; }
s_DC_4_9_manual() {
  p03_sign DC-4.9 "IT security signs P99; the platform owner and IT security sign P63; the platform owner drafts." \
    "<date>-paging-tool-and-device-licences.md" "P99 P63" \
    "  P99: the organisation's 24x7 on-call tool, else PagerDuty; ../07 §9.2's ladder and targets. No Values.
  P63: one Chrome Enterprise Premium licence per operator and approver on the Tier W+ surfaces, with the names counted."
  echo "  A tracker written before 2026-10-01 first gets rows P63 and P99 under DC-1.3's rule, in a reviewed commit."
  p03_end DC-4.9 "P99 P63"
}

# ---------------------------------------------------------------- §8 names and keys: the permanent choices
step DC-5.1 HUMAN "Sign the names register (NAMES, D1, SD-23, SD-33)" --needs "PLATFORM_REPO_DIR" --irreversible \
  --sets "MO_METRICS_DS MO_ARCHIVE_DS MO_PRIVATE_DS MO_VIEWS_DS EVE_EVIDENCE_LOCATION"
s_DC_5_1_check() {
  local n
  ckpt_done DC-5.1 && return 0
  p03_decided "NAMES D1 SD-23 SD-33" "MO_METRICS_DS MO_ARCHIVE_DS MO_PRIVATE_DS MO_VIEWS_DS EVE_EVIDENCE_LOCATION" || return 1
  [ "$(_penv_get EVE_EVIDENCE_LOCATION)" = europe-west1 ] || return 1
  for n in MO_METRICS_DS MO_ARCHIVE_DS MO_PRIVATE_DS MO_VIEWS_DS; do
    _penv_get "$n" | grep -Eqx 'platform_metrics[A-Za-z0-9_]*' || return 1
  done
}
s_DC_5_1_manual() {
  p03_sign DC-5.1 "the platform owner drafts; SH (Eve and witness names), the Mo owner (Mo names), WA1 and WA2 (witness names), IT security sign." \
    "<date>-names-register.md" "NAMES D1 SD-23 SD-33" \
    "  IRREVERSIBLE once a create step uses a name: every project id, dataset, bucket, tag key, OU and app name of DC-5.1's table, PLATFORM_REPO_NAME, one fallback-suffix rule."
  echo "RECORD, once signed (typed by you): DC-5.1's loop over MO_METRICS_DS MO_ARCHIVE_DS MO_PRIVATE_DS MO_VIEWS_DS EVE_EVIDENCE_LOCATION, each as"
  p03_dv NAMES '<name>'
  echo "  EVE_EVIDENCE_LOCATION is europe-west1; the four MO_*_DS match ^platform_metrics (four ok lines)."
  p03_end DC-5.1 "NAMES D1 SD-23 SD-33"
}

step DC-5.2 HUMAN "Sign the key table (KEYS, SD-47)" --needs "PLATFORM_REPO_DIR" --irreversible --on-unmet skip
s_DC_5_2_check() { ckpt_done DC-5.2 && return 0; p03_signed KEYS SD-47 && p03_record_has KEYS 'eve-eu' && p03_record_has KEYS 'eve-evidence-eu'; }
s_DC_5_2_manual() {
  p03_sign DC-5.2 "the platform owner; SH (Eve's rings); IT security." "<date>-key-table.md" "KEYS SD-47" \
    "  IRREVERSIBLE once a ring exists. ../09 §2.4 with SD-47: ring eve (europe-west1) and ring eve-eu (europe, key eve-evidence-eu) in EVE_PROJECT."
  echo "  DC-5.2's VERIFY: the tracker names a record that exists and both grep counts (eve-eu, eve-evidence-eu) are at least 1."
  p03_end DC-5.2 "KEYS SD-47"
}

# ---------------------------------------------------------------- §9 platform model, privilege, Eve and Mo
step DC-6.1 HUMAN "Sign the platform model and privilege rows" --needs "PLATFORM_REPO_DIR" --on-unmet skip
s_DC_6_1_check() { ckpt_done DC-6.1 || p03_signed P1 P49 SD-19 SD-18 SD-42 SD-46 SD-02 SD-25 SD-05 SD-06 SD-34 SD-43; }
s_DC_6_1_manual() {
  p03_sign DC-6.1 "the platform owner; IT security; ISMS; SH for SD-34, SD-43 and SD-46." "<date>-platform-model-and-privilege.md" \
    "P1 P49 SD-19 SD-18 SD-42 SD-46 SD-02 SD-25 SD-05 SD-06 SD-34 SD-43" \
    "  Tier model; ent-ge-admin without approval at Tier C (SD-19); walle-deployer@ as ladder publisher (SD-34); SD-43's accepted limit."
  p03_end DC-6.1 "P1 P49 SD-19 SD-18 SD-42 SD-46 SD-02 SD-25 SD-05 SD-06 SD-34 SD-43"
}

step DC-7.1 HUMAN "Sign Eve-H: scope, independence and the consent prerequisites" --needs "PLATFORM_REPO_DIR" --sets "BUSINESS_TZ BUSINESS_HOURS"
s_DC_7_1_check() {
  ckpt_done DC-7.1 && return 0
  p03_decided "SD-10 SD-12 SD-03 SD-07 SD-08 SD-26 SD-31 SD-32 E-1 E-16 TD-44 CC-33 E-18 WDEC-15" "BUSINESS_TZ BUSINESS_HOURS" \
    && p03_record_has SD-10 '^\| SH \|' && p03_hours_ok
}
p03_hours_ok() {    # setup/03 DC-7.1 VERIFY: a tz database name, and <day>-<day> HH:MM-HH:MM
  local tz h
  tz="$(_penv_get BUSINESS_TZ)"; h="$(_penv_get BUSINESS_HOURS)"
  case "$tz" in */*|UTC) [ -f "/usr/share/zoneinfo/$tz" ] || return 1;; *) return 1;; esac
  printf '%s\n' "$h" | grep -Eqx '(Mon|Tue|Wed|Thu|Fri|Sat|Sun)-(Mon|Tue|Wed|Thu|Fri|Sat|Sun) ([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]'
}
s_DC_7_1_manual() {
  p03_sign DC-7.1 "the platform owner drafts; SH co-signs; IT security; the incident commander for SD-08." "<date>-eve-h-scope-and-independence.md" \
    "SD-10 SD-12 SD-03 SD-07 SD-08 SD-26 SD-31 SD-32 E-1 E-16 TD-44 CC-33 E-18 WDEC-15" \
    "  The signature table has a row SH. 23 refuses without SD-10 and SD-12; 24 without SD-31, E-16 and TD-44."
  echo "  Forms (DC-7.1's case lines print tz ok, hours ok): BUSINESS_TZ a tz database name (Europe/Paris); BUSINESS_HOURS <day>-<day> HH:MM-HH:MM in BUSINESS_TZ (Mon-Fri 08:00-18:00)."
  echo "RECORD, once signed (typed by you):"; p03_dv WDEC-15 BUSINESS_TZ; p03_dv WDEC-15 BUSINESS_HOURS
  echo "  *tbd* is allowed (H-1 then runs flat windows): agp-platform done DC-7.1 --note 'business hours tbd'."
  p03_end DC-7.1 "SD-10 SD-12 SD-03 SD-07 SD-08 SD-26 SD-31 SD-32 E-1 E-16 TD-44 CC-33 E-18 WDEC-15"
}

step DC-7.2 HUMAN "Sign the Mo rows (M-1, SD-24, SD-39)" --needs "PLATFORM_REPO_DIR" --on-unmet skip
s_DC_7_2_check() { ckpt_done DC-7.2 || p03_signed M-1 SD-24 SD-39 D12; }
s_DC_7_2_manual() {
  p03_sign DC-7.2 "the platform owner; the Mo owner; IT security for SD-24." "<date>-mo-decisions.md" "M-1 SD-24 SD-39 D12" \
    "  D12's own record is 02's; its tracker row points there."
  p03_end DC-7.2 "M-1 SD-24 SD-39 D12"
}

# ---------------------------------------------------------------- §10 Wall-E, the gate and the model
step DC-8.1 HUMAN "Sign Wall-E's scope rows (D2, D4, D6, D10, D11, P29, SD-48)" --needs "PLATFORM_REPO_DIR" --on-unmet skip
s_DC_8_1_check() { ckpt_done DC-8.1 || p03_signed D2 D4 D6 D10 D11 P29 SD-48; }
s_DC_8_1_manual() {
  p03_sign DC-8.1 "the platform owner decides; SR (or IT security until appointed) and ISMS sign; SH for SD-48." "<date>-wall-e-scope.md" \
    "D2 D4 D6 D10 D11 P29 SD-48" "  D2 may be signed twice: a first answer before 30 and a superseding final list before 32."
  p03_end DC-8.1 "D2 D4 D6 D10 D11 P29 SD-48"
}

step DC-8.2 HUMAN "Sign the gate, the penetration-test window and the tabletop date (D13, SD-36, G8-WINDOW, G17-DATE)" \
  --needs "PLATFORM_REPO_DIR" --on-unmet skip
s_DC_8_2_check() {
  ckpt_done DC-8.2 && return 0
  p03_signed D13 SD-36 G8-WINDOW G17-DATE && p03_record_has D13 'G21' && ! p03_record_has D13 'G1-G11'
}
s_DC_8_2_manual() {
  p03_sign DC-8.2 "the platform owner; SH; IT security (G8); the incident commander (G17); ISMS." "<date>-super-admin-gate.md" \
    "D13 SD-36 G8-WINDOW G17-DATE" "  Gate lines G1-G21, never G1-G11; dates may be *tbd* and are fixed by a superseding record before 37 and 38."
  p03_end DC-8.2 "D13 SD-36 G8-WINDOW G17-DATE"
}

step DC-8.3 HUMAN "Pin the model on the eu endpoint (decision 6, SD-09)" --needs "PLATFORM_REPO_DIR" --sets "MODEL_ID" \
  --on-unmet skip --note "due before 35 and 40's Mo-11, not before any platform phase: apply lists it and carries on"
s_DC_8_3_check() {
  ckpt_done DC-8.3 && return 0
  p03_decided "WDEC-6 SD-09" "MODEL_ID" || return 1
  case "$(_penv_get MODEL_ID)" in gemini-2.5*|gemini-2-5*) return 1;; *) return 0;; esac
}
s_DC_8_3_manual() {
  p03_sign DC-8.3 "the platform owner; IT security; the DPO (processing location)." "<date>-model-pin.md" "WDEC-6 SD-09" \
    "  On the pin date read the model page and 'Google model endpoint locations': GA on eu, retirement >= 6 months after Stage 1, no 2.5 model."
  echo "RECORD, once signed (typed by you):"; p03_dv WDEC-6 MODEL_ID
  echo "  The 2.5 family on europe-west1 retires on 2026-10-16. Until the pin, 04 PU-2.8 waits; no platform phase does."
  p03_end DC-8.3 "WDEC-6 SD-09"
}

step DC-8.4 HUMAN "Security reviewer ratification (RATIFY-SR)" --needs "PLATFORM_REPO_DIR" --on-unmet skip \
  --note "runs once PPL-SR is signed, before 30 (Tier W)"
s_DC_8_4_check() {
  local r f
  ckpt_done DC-8.4 && return 0
  p03_signed RATIFY-SR || return 1
  r="$(v PLATFORM_REPO_DIR)"
  for f in "$r"/decisions/20*.md; do "$r/tools/decision-check.sh" "$f" >/dev/null 2>&1 || return 1; done
}
s_DC_8_4_manual() {
  p03_sign DC-8.4 "the security reviewer, once PPL-SR is signed and before 30." "<date>-security-reviewer-ratification.md" "RATIFY-SR" \
    "  Lists every ITSEC-signed record (DC-4.1, DC-4.3, DC-6.1, DC-8.1) by file and body hash; ratifies or supersedes each; signs SD-43."
  echo "  DC-8.4's VERIFY: no FAIL, no 'missing', and the OK count equals the number of records in decisions/."
  p03_end DC-8.4 "RATIFY-SR"
}

# ---------------------------------------------------------------- §12 the platform repository
p03_reg_row_ok() {  # p03_reg_row_ok REGISTER ID: ID once, in PR-4.1's 13-column form, above '## Closures'
  local reg="$1" id="$2" ln cl
  [ -f "$reg" ] || return 1
  [ "$(grep -c "^| $id |" "$reg")" = 1 ] || return 1
  ln="$(awk -F'|' -v id="$id" 'index($0, "| " id " |") == 1 && NF == 15 {print NR; exit}' "$reg")"
  cl="$(awk '/^## Closures$/{print NR; exit}' "$reg")"
  [ -n "$ln" ] && [ -n "$cl" ] && [ "$ln" -lt "$cl" ]
}

step DC-9.1 AUTO "Prove every local commit has a review record, and open the bootstrap deviation for the ones that cannot" \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR GIT_HOST DEVIATION_REGISTER SECOND_HUMAN_EMAIL" --gate "P22 SD-14 M-7" --witness \
  --note "witness: the confirmer (second operator, or second human while PPL-SO is *tbd*), who approved by mail the exempt list that plan prints; the page's own checkpoint DC-9.1 DONE writes the confirmer in the witness column"
s_DC_9_1_check() {
  local b
  ckpt_done DC-9.1 && return 0
  b="$(v BUILD_LOG_DIR)"
  [ -f "$b/03-prepush-unreviewed.txt" ] && [ ! -s "$b/03-prepush-unreviewed.txt" ] || return 1
  p03_reg_row_ok "$(v DEVIATION_REGISTER)" BD-03-1
}
s_DC_9_1_apply() {
  # Plan mode reads and prints the two lists, so the confirmer reviews exactly what apply records; they approve by
  # mail (<date>-DC-9.1-exempt-commits-v1), then apply runs with them as --witness and opens BD-03-1.
  local r b reg confirmer commits c unrev="" exempt="" rc row
  r="$(v PLATFORM_REPO_DIR)"; b="$(v BUILD_LOG_DIR)"; reg="$(v DEVIATION_REGISTER)"
  if [ "$AGP_OFFLINE" != 1 ] && [ "$(grep -c '^| Id |' "$reg" 2>/dev/null)" != 2 ]; then
    printf '      STOP: %s is not in 01 PR-4.1'"'"'s form (two "| Id |" headers); 01 PR-4.1 has not run\n' "$reg" >&3
    [ "$AGP_MODE" = apply ] && return 1
  fi
  confirmer="$(v SECOND_HUMAN_EMAIL)"
  if has_value SECOND_OPERATOR_EMAIL; then confirmer="$(_penv_get SECOND_OPERATOR_EMAIL)"; fi
  printf '      confirmer %s\n' "$confirmer" >&3
  commits="$(r git -C "$r" rev-list --reverse HEAD)"; rc=$?
  if [ $rc -eq 3 ]; then
    printf '      offline: the commit lists are read in plan without --offline, for the confirmer to review\n' >&3
  elif [ $rc -ne 0 ]; then
    printf '      STOP: %s has no commit to list (git rev-list HEAD failed)\n' "$r" >&3; [ "$AGP_MODE" = apply ] && return 1
  else
    for c in $commits; do
      [ -f "$b/reviews/$c.md" ] && continue
      if git -C "$r" show --name-only --pretty=format: "$c" | sed '/^$/d' | grep -qvE '^(env/|metrics/)'; then
        unrev="$unrev$c
"
      else
        exempt="$exempt$c
"
      fi
    done
    printf '      %s commits; %s without a review record; %s exempt (env/ and metrics/ only):\n' \
      "$(printf '%s\n' "$commits" | sed '/^$/d' | wc -l | tr -d ' ')" "$(printf '%s' "$unrev" | wc -l | tr -d ' ')" \
      "$(printf '%s' "$exempt" | wc -l | tr -d ' ')" >&3
    for c in $exempt; do git -C "$r" show --stat --oneline --no-patch "$c" | sed 's/^/        /' >&3; done
  fi
  printf '%s\n' "$commits" | sed '/^$/d' | xw "$b/03-prepush-commits.txt" 644 || return 1
  printf '%s' "$unrev" | xw "$b/03-prepush-unreviewed.txt" 644 || return 1
  printf '%s' "$exempt" | xw "$b/03-prepush-exempt.txt" 644 || return 1
  if [ -n "$unrev" ]; then
    printf '      STOP: a commit has no reviews/<sha>.md record; record it (DC-1.3) or revert it before the push:\n' >&3
    printf '%s' "$unrev" | sed 's/^/        /' >&3
    [ "$AGP_MODE" = apply ] && return 1
  fi
  if [ "$AGP_MODE" = apply ] && [ "$AGP_WITNESS" != "$confirmer" ]; then
    printf '      note: the witness (%s) is not the confirmer named in the row (%s)\n' "$AGP_WITNESS" "$confirmer" >&3
  fi
  if p03_reg_row_ok "$reg" BD-03-1; then
    printf '      BD-03-1 is already in the register\n' >&3
  elif [ "$AGP_MODE" != apply ]; then
    printf '      would insert the BD-03-1 row (13 columns, approver %s) at the end of the first table of %s\n' "$confirmer" "$reg" >&3
  else
    row="| BD-03-1 | $(date -u +%F) | 03 DC-9.1 | DEV | commits made before a reviewer was named or reviewed inside the repository | repo $r | $b/03-prepush-exempt.txt | per-commit review records for every other commit; 02's signed metrics/reviews record for the metrics commits | BLOCKED: no factory | - | $confirmer | closed when 01 PR-2.2 and 02 write reviews/<sha>.md, at the Tier W gate at the latest | open |"
    # setup/03 DC-9.1's own insertion into the register's first table (01's bd_insert would refuse the row's literal reviews/<sha>.md).
    awk -v row="$row" '
      /^\|---\|/ && !seen { seen=1; print; next }
      seen && !done && $0 !~ /^\|/ { print row; done=1 }
      { print }
      END { if (seen && !done) print row }' "$reg" 2>/dev/null | xw "$reg" 644 || return 1
  fi
  x git -C "$b" add "$reg" "$b/03-prepush-commits.txt" "$b/03-prepush-exempt.txt" || return 1
  if [ "$AGP_MODE" != apply ] || ! git -C "$b" diff --cached --quiet; then
    x git -C "$b" commit -m "BD-03-1 bootstrap commits without a reviews/<sha>.md record" || return 1
  fi
  [ "$AGP_MODE" = apply ] || return 0
  p03_reg_row_ok "$reg" BD-03-1 || { printf '      BD-03-1 is not once, in 13 columns, above ## Closures; read the register\n' >&3; return 1; }
}

step DC-9.2 HUMAN "Create the repository on the git host" --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR GIT_HOST" \
  --gate "P22 SD-14 NAMES" --sets "GIT_ORG PLATFORM_REPO_SLUG"
s_DC_9_2_check() { ckpt_done DC-9.2; }
s_DC_9_2_manual() {
  echo "WHO: the platform owner, as organisation owner on $(v GIT_HOST). First: 04 PU-2.13's plan is in force and its four rule checks passed."
  echo "WHERE: your own shell, ~/.platform-env sourced, gh signed in as yourself (gh auth status). This phase runs no gh"
  echo "  and no git network command (header of phases/03): every git-host step is yours, in that shell."
  echo "DO: setup/03 DC-9.2's block: it types the organisation (penv_set GIT_ORG), stores PLATFORM_REPO_SLUG from the NAMES"
  echo "  record's PLATFORM_REPO_NAME, then:"
  echo "  gh repo create \"\$PLATFORM_REPO_SLUG\" --private --description \"Agentic platform: register, policies, rosters, decisions\" --disable-wiki"
  echo "CHECK: gh repo view \"\$PLATFORM_REPO_SLUG\" --json visibility --jq '.visibility' prints PRIVATE; the slug is <org>/<name>;"
  echo "  grep -c '^export GIT_ORG=' ~/.platform-env prints 1."
  p03_done_line DC-9.2
}

step DC-9.3 HUMAN "Write access for humans only" --needs "GIT_ORG PLATFORM_REPO_SLUG BUILD_LOG_DIR" --witness
s_DC_9_3_check() { ckpt_done DC-9.3; }
s_DC_9_3_manual() {
  echo "WHO: the platform owner grants; IT security confirms (the witness)."
  echo "WHERE: the git host's organisation settings for $(v PLATFORM_REPO_SLUG); then your own shell with gh signed in."
  echo "DO: write only to the named humans (owner, second human, second operator; security reviewer and Mo owner when appointed),"
  echo "  through one team. No bot account, machine user or app installation gets write or maintain."
  echo "LIST: setup/03 DC-9.3's block: the collaborators?affiliation=all listing into $(v BUILD_LOG_DIR)/03-DC-9.3-collaborators-<date>.tsv;"
  echo "  its awk prints nothing; every write, maintain or admin login is on an appointment record (checked with IT security)."
  echo "READ BY EYE: Your organisations > Settings > Third-party Access > GitHub Apps: no app with write on this repository; dated line in the build log."
  p03_done_line DC-9.3 "IT security"
}

step DC-9.4 HUMAN "Commit CODEOWNERS with the second human on the control files" \
  --needs "PLATFORM_REPO_DIR GIT_ORG PLATFORM_REPO_SLUG SECOND_HUMAN_EMAIL OWNER_DAILY_ACCOUNT" \
  --note "reviewer, not a witness: the second human signs the commit's review record"
s_DC_9_4_check() { ckpt_done DC-9.4; }
s_DC_9_4_manual() {
  echo "WHO: the platform owner writes and commits; the second human reviews the commit (review record)."
  echo "FIRST: both addresses proven: DC-9.4's search/users and collaborator reads, and a reply from each person's own account"
  echo "  ('<address> is a verified email on my GitHub account <login>, which has write access to <repo>'), saved as"
  echo "  <date>-DC-9.4-codeowner-<role>-v1. An address that cannot be verified is written as @<login>, noted in the review record."
  echo "DO: DC-9.4's CODEOWNERS heredoc in $(v PLATFORM_REPO_DIR)/.github/ (owner on *, the second human on the eight control paths),"
  echo "  git add, commit, then the review record as in DC-1.3, quoting both replies."
  echo "CHECK: grep -c \"\$SECOND_HUMAN_EMAIL\" \"\$PLATFORM_REPO_DIR/.github/CODEOWNERS\" prints 8. After DC-9.5, codeowners/errors?ref=main"
  echo "  has length 0 before DC-9.6 runs; a non-zero length stops DC-9.6."
  p03_done_line DC-9.4
}

step DC-9.5 HUMAN "Push the local history and set the remote" --irreversible --witness --gate "P22 SD-14 M-7" \
  --needs "PLATFORM_REPO_DIR GIT_ORG PLATFORM_REPO_SLUG BUILD_LOG_DIR DEVIATION_REGISTER SECOND_HUMAN_EMAIL" --sets "PLATFORM_REPO_REMOTE"
s_DC_9_5_check() { ckpt_done DC-9.5; }
s_DC_9_5_manual() {
  echo "IRREVERSIBLE: pushed history. Confirm first: 03-prepush-unreviewed.txt empty and BD-03-1 in the register (DC-9.1); PRIVATE (DC-9.2);"
  echo "  DC-9.4's commit is HEAD; git log --oneline read aloud against 03-prepush-commits.txt; grep -rIiE 'password|secret|token' shows prose only."
  echo "  The runner does not push, so it cannot ask for the id typed first: read these checks aloud with the witness before the push."
  echo "WHO: the platform owner pushes; the second human watches on screen (the witness)."
  echo "WHERE: your own shell, ~/.platform-env sourced; git authenticates with your own credential helper."
  echo "DO: setup/03 DC-9.5's two blocks: checkpoint DC-9.5 START, branch -M main, remote add origin https://github.com/$(v PLATFORM_REPO_SLUG).git,"
  echo "  push -u origin main, penv_set PLATFORM_REPO_REMOTE, then the BD-03-2 row in the first table and checkpoint DC-9.5 DONE."
  echo "CHECK: git rev-parse HEAD equals gh api \"repos/\$PLATFORM_REPO_SLUG/branches/main\" --jq .commit.sha; need PLATFORM_REPO_REMOTE;"
  echo "  BD-03-2 once, above ## Closures."
  echo "THEN: the block's own checkpoint DC-9.5 DONE line records it (or agp-platform done DC-9.5 --witness <second human email>)."
}

step DC-9.6 HUMAN "Branch protection: two human reviewers, code owners, administrators included" --needs "GIT_ORG PLATFORM_REPO_SLUG" --witness --removes
s_DC_9_6_check() { ckpt_done DC-9.6; }
s_DC_9_6_manual() {
  echo "WHO: the platform owner applies; IT security watches on screen (the witness)."
  echo "PRECONDITION: gh api \"repos/$(v PLATFORM_REPO_SLUG)/codeowners/errors?ref=main\" --jq '.errors | length' prints 0. Otherwise stop:"
  echo "  require_code_owner_reviews over an unknown owner requires nobody."
  echo "WHERE: your own shell, gh signed in."
  echo "DO: setup/03 DC-9.6's block: gh api -X PUT \"repos/\$repo/branches/main/protection\" --input <the page's JSON: 2 approvals,"
  echo "  code owners, dismiss stale reviews, last-push approval, enforce_admins, no force push, no deletion, linear history>."
  echo "CHECK: DC-9.6's VERIFY reads reviews 2, codeowners true, lastpush true, admins true, force false, deletions false; errors length still 0."
  p03_done_line DC-9.6 "IT security"
}

step DC-9.7 HUMAN "Negative tests: a direct push and a one-approval merge are refused" \
  --needs "GIT_ORG PLATFORM_REPO_SLUG PLATFORM_REPO_REMOTE" --witness --on-unmet skip --removes
s_DC_9_7_check() { ckpt_done DC-9.7; }
s_DC_9_7_manual() {
  echo "WHO: the platform owner attempts; the second human observes (the witness); the second operator approves once (not the second human)."
  echo "WHERE: your own shell, a scratch clone of $(v PLATFORM_REPO_REMOTE)."
  echo "DO: setup/03 DC-9.7's blocks: a direct push to main (expect a protected-branch refusal and a non-zero exit), then a roster/"
  echo "  change on branch dc-9-7-negative-test as a pull request, one approval, the state read, the pull request closed with its branch."
  echo "CHECK: the push is refused; gh pr view shows BLOCKED and REVIEW_REQUIRED after one approval. Both outputs go to the build log."
  p03_done_line DC-9.7 "second human"
}

step DC-9.8 HUMAN "Audit administrator bypass" --needs "GIT_ORG PLATFORM_REPO_SLUG BUILD_LOG_DIR" --on-unmet skip \
  --note "IT security, weekly, until 15 part B moves the query into the SIEM"
s_DC_9_8_check() {
  local f
  ckpt_done DC-9.8 && return 0
  for f in "$(v BUILD_LOG_DIR)"/03-DC-9.8-bypass-audit-*.tsv; do [ -f "$f" ] && return 0; done
  return 1
}
s_DC_9_8_manual() {
  echo "WHO: IT security, as a git-host organisation owner, from their own workstation; the platform owner never runs it alone."
  echo "WHERE: their shell with GIT_ORG=$(v GIT_ORG) and PLATFORM_REPO_SLUG=$(v PLATFORM_REPO_SLUG), from the variables file or"
  echo "  handed over in writing; never retyped by hand (a mistyped organisation returns an empty log that reads like a clean week)."
  echo "DO: setup/03 DC-9.8's block: gh api \"orgs/\$GIT_ORG\" --jq '.login' first, then the audit-log query for the six"
  echo "  protected_branch and repository_ruleset actions into $(v BUILD_LOG_DIR)/03-DC-9.8-bypass-audit-<date>.tsv, kept even when empty."
  echo "FINDING: any policy_override, update_admin_enforced or destroy line is severity 2 to the incident commander the same day."
  echo "THEN: agp-platform done DC-9.8 after the first run (the day of DC-9.6); later weeks are DRILL_CALENDAR entries."
}

step DC-9.9 BLOCKED "Refuse approvals by service accounts and bot users" --note "B-03"
s_DC_9_9_check() { ckpt_done DC-9.9; }
s_DC_9_9_manual() {
  echo "BLOCKED on B-03: the bot-approval CI rule, .github/workflows/bot-approval.yml, is file 16's code."
  echo "Interim control: DC-9.3's collaborator listing, repeated weekly by IT security with DC-9.8; a login not on an appointment"
  echo "  record is removed the same day. The run continues."
  echo "Unblocked by: penv_set BOT_APPROVAL_RULE_COMMIT <sha> after a green run on a test pull request; then DC-9.6's body is"
  echo "  re-sent with required_status_checks {\"strict\": true, \"contexts\": [\"bot-approval\"]} under a reviewed change."
}

step DC-9.10 HUMAN "Merge the bootstrap review records through the protected path" \
  --needs "GIT_ORG PLATFORM_REPO_SLUG PLATFORM_REPO_REMOTE BUILD_LOG_DIR" --on-unmet skip
s_DC_9_10_check() { ckpt_done DC-9.10; }
s_DC_9_10_manual() {
  echo "WHO: the platform owner opens the pull request; the second human (code owner of /decisions/) and the second operator approve."
  echo "WHERE: your own shell in a clone of $(v PLATFORM_REPO_REMOTE); the git host's interface for the merge."
  echo "DO: setup/03 DC-9.10's block: every reviews/<sha>.md of 03-prepush-commits.txt and the BD-03-1 exemption list under"
  echo "  decisions/bootstrap-reviews/ on branch dc-9-10-bootstrap-reviews, pushed, gh pr create. No STOP line may print."
  echo "  Merge after two approvals, one of them the second human's."
  echo "CHECK: gh pr view dc-9-10-bootstrap-reviews --repo \"\$PLATFORM_REPO_SLUG\" --json state --jq .state prints MERGED; the .md count"
  echo "  under decisions/bootstrap-reviews on main equals the commits pushed minus the BD-03-1 exemptions."
  p03_done_line DC-9.10
}

step DC-9.11 HUMAN "Create the build-log repository, protect it and set its remote" \
  --needs "PLATFORM_REPO_DIR GIT_ORG PLATFORM_REPO_SLUG BUILD_LOG_DIR SECOND_HUMAN_EMAIL" --witness --sets "BUILD_LOG_REMOTE" --removes
s_DC_9_11_check() { ckpt_done DC-9.11; }
s_DC_9_11_manual() {
  echo "PRECONDITION: DC-9.6 is DONE (agp-platform status)."
  echo "WHO: the platform owner, as organisation owner on the git host; the second human watches the protection (the witness)."
  echo "WHERE: your own shell, gh signed in, ~/.platform-env sourced."
  echo "DO: setup/03 DC-9.11's block: $(v GIT_ORG)/<name>-build-log (or NAMES' BUILD_LOG_REPO_NAME), private, wiki off; push main;"
  echo "  penv_set BUILD_LOG_REMOTE; protection with enforce_admins, no force push, no deletion; write for DC-9.3's team only."
  echo "CHECK: DC-9.11's VERIFY (PRIVATE and false; admins true, force false, deletions false; pushed; need BUILD_LOG_REMOTE silent);"
  echo "  a test force-push is refused. Then: bd_close BD-02-1 \"build-log remote created and protected: 03 DC-9.11\" \"03 DC-9.11 VERIFY\""
  echo "From now on every sitting ends with: git -C \"\$BUILD_LOG_DIR\" push origin main, before sitting_end."
  echo "THEN: the block's own checkpoint DC-9.11 DONE line records it (or agp-platform done DC-9.11 --witness <second human email>)."
}
