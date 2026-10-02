# phases/42-gates-drills-and-evidence.sh: setup/42 sections 1 to 4, the platform's standing evidence
# home: the gate index (GD-1), the standing Tier W gate record (GD-2), the platform evidence bucket
# (GD-3) and the evidence register with its two mappings (GD-4). Sections 5 to 8 (the drill calendar,
# the model re-pin, the deviation review and the quarterly review) open after 38 and are not platform
# setup: they stay with the people who run them.
#
# How the page maps onto the classes:
# - GD-1.1, GD-1.2 and GD-1.3 write here-documents (gates/README.md, the record template, freshness.tsv,
#   tools/gate-index.sh). A phase does not retype a page's here-document (lib/PHASES.md); until their
#   bodies are saved in assets/ with a 42.manifest, the person runs the page's block: HUMAN.
# - GD-2 is Sitting B, which opens when 37 is done (RESTORE_DRILL_RECORD set). Its steps need that name
#   and are --on-unmet skip, so a Sitting A run passes over them. GD-2.1 is the page's read loop
#   (AUTO-READ); GD-2.2 and GD-2.3 are a signed record and README edits (HUMAN).
# - GD-3.1 (bucket and key handle, IRREVERSIBLE) and GD-3.3 (the four bindings) are AUTO under an
#   ENT_PROJECT_REPAIR_CORE grant the second human approves; every gcloud storage command names
#   --project=LOGGING_PROJECT, where the page's do not. GD-3.4 (the backlog copy) is HUMAN: the second
#   human copies the scans and a GRP_PLATFORM_SECURITY member runs its VERIFY. GD-3.2's lock is
#   IRREVERSIBLE, spans two sittings and rests on four written checks with the second human present:
#   HUMAN. GD-3.5 (a standing rule) and GD-3.6 (page corrections) are HUMAN.
# - GD-4.1 and GD-4.2 are reads of the register, and GD-4.3 exports it into the TISAX pack (AUTO-READ);
#   GD-4.4 is BLOCKED on B-03 (its hand half needs STAGE0_RECORD from 39); GD-4.5 belongs to the
#   witness administrators (HUMAN).
#
# Helpers are prefixed _gd_ because every phase file is loaded into the same shell.

phase 42 "Gates, drills and evidence, sections 1 to 4" "42-gates-drills-and-evidence.md" "GD-[1-4]\."

GD_TIERW_NAMES="VALIDATOR_CUSTODIAN_EMAIL SECOND_OPERATOR_EMAIL SECURITY_REVIEWER_EMAIL BLIND_GRADER_EMAIL SA_VALIDATOR_CUSTODIAN BINAUTHZ_ATTESTOR RESTORE_DRILL_RECORD K7_PSA_DRILL_RECORD EVE_H_LIVE_RECORD"
GD_KH="kh-platform-evidence"
GD_EIDS="E-01 E-02 E-03 E-04 E-05 E-06 E-07 E-08 E-09 E-10 E-11 E-12 E-13 E-15"
GD_TISAX_GROUPS="1.1 1.2 1.3 1.4 1.5 1.6 2.1 3.1 4.1 4.2 5.1 5.2 5.3 6.1 7.1"
GD_SITTING_B="Sitting B: opens when 37 is done (RESTORE_DRILL_RECORD set); a Sitting A run passes over it"

# ---------------------------------------------------------------- helpers

_gd_say() { printf '      %s\n' "$*" >&3; }
_gd_plan() { [ "$AGP_MODE" = apply ] || printf '      read: %s\n' "$*" >&3; }
_gd_pre() { AGP_CALL_CONTEXT=check "$@"; }      # a read inside _apply that decides; marked as a check for the fakes
_gd_rec() { printf '%s/records/%s-%s' "$(v BUILD_LOG_DIR)" "$(date -u +%F)" "$1"; }   # NAME: today's record path
_gd_bucket() { printf 'gs://%s-platform-evidence' "$(v LOGGING_PROJECT)"; }
_gd_py() { python3 -c "$1" "${@:2}"; }
_gd_sleep() {   # SECONDS: a wait the page prescribes, multiplied by AGP_WAIT_SCALE (a whole number, 1 when unset; 0 in the tests)
  local s="${AGP_WAIT_SCALE:-1}"
  case "$s" in ''|*[!0-9]*) s=1;; esac
  [ $(($1 * s)) -gt 0 ] || return 0
  sleep $(($1 * s))
}

_gd_save() {    # STEP SLUG E-ID TISAX NAME: standard input becomes today's record NAME, printed and registered
  local f; f="$(_gd_rec "$5")"
  if [ "$AGP_MODE" != apply ]; then cat >/dev/null; _gd_say "would write ${f##*/} and register it"; ev "$1" "$2" "$3" "$4" "build-log:records/${f##*/}"; return 0; fi
  local c; c="$(cat)"
  printf '%s\n' "$c" | sed 's/^/        /' >&3
  printf '%s\n' "$c" | xw "$f" 600 || return 1
  ev "$1" "$2" "$3" "$4" "build-log:records/${f##*/}" "$f"
}

# PAM: 12's pam_request and pam_wait, written with the gcloud commands they wrap.
_gd_grant_name() {  # ENTITLEMENT FILTER: the newest grant the caller created on it matching FILTER
  r gcloud pam grants search --entitlement="$1" --caller-relationship=had-created --filter="$2" \
    --format='value(name)' --billing-project="$(v CICD_PROJECT)" 2>/dev/null | head -n 1
}

GD_GRANT=""
_gd_grant() {   # ENT_VAR SECONDS JUSTIFICATION [FLAG...]: an ACTIVE grant of the caller in GD_GRANT; requested once, awaited
  local ent="$1" sec="$2" why="$3" n i=0 s; shift 3
  ent="$(v "$ent")"
  if [ "$AGP_MODE" != apply ]; then
    x gcloud pam grants create --entitlement="$ent" --requested-duration="${sec}s" --justification="$why" "$@" \
      --billing-project="$(v CICD_PROJECT)" --format='value(name)'
    _gd_say "then waits until the second human approves the grant (state ACTIVE); nothing privileged runs before"
    GD_GRANT="<grant>"; return 0
  fi
  n="$(_gd_pre _gd_grant_name "$ent" 'state=ACTIVE')"
  if [ -n "$n" ]; then GD_GRANT="$n"; _gd_say "an ACTIVE grant exists ($n); not requested again"; return 0; fi
  n="$(_gd_pre _gd_grant_name "$ent" 'state=APPROVAL_AWAITED OR state=SCHEDULED OR state=ACTIVATING')"
  if [ -n "$n" ]; then _gd_say "a grant is already waiting for approval ($n); not requested again"
  else
    n="$(x gcloud pam grants create --entitlement="$ent" --requested-duration="${sec}s" --justification="$why" "$@" \
      --billing-project="$(v CICD_PROJECT)" --format='value(name)')" || return 1
    n="$(printf '%s\n' "$n" | tail -n 1)"
  fi
  GD_GRANT="$n"
  _gd_say "waiting for the second human's approval of $n (polls every 20 s, up to 30 minutes)"
  while [ $i -lt 90 ]; do
    s="$(r gcloud pam grants describe "$n" --billing-project="$(v CICD_PROJECT)" --format='value(state)' 2>/dev/null)"
    [ "$s" = ACTIVE ] && { _gd_say "STATE ACTIVE"; return 0; }
    case "$s" in DENIED|REVOKED|ENDED|EXPIRED) _gd_say "STATE $s (terminal, not ACTIVE): request again by re-running this step"; return 1;; esac
    i=$((i + 1)); _gd_sleep 20
  done
  _gd_say "STOP: $n is not ACTIVE after 30 minutes; when it is approved, re-run this step (it will not request again)"
  return 1
}

# ======================================================================== 1. The gate index

step GD-1.1 HUMAN "Create gates/, its index and its record schema" --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR PLATFORM_REPO_SLUG" --sets "GATES_DIR"
s_GD_1_1_check() { ckpt_done GD-1.1; }
s_GD_1_1_manual() {
  echo "WHO: platform owner; the security reviewer is a required reviewer on the merge (CODEOWNERS)."
  echo "WHERE: shell, ~/.platform-env sourced, in PLATFORM_REPO_DIR."
  echo "DO: run GD-1.1's block of setup/42 as written: branch gd-1-1-gates, penv_set GATES_DIR \"gates\", the two"
  echo "  here-documents (gates/README.md, gates/record.template.md), commit, push, gh pr create --repo \"\$PLATFORM_REPO_SLUG\"."
  echo "VERIFY: ls gates lists both files; the pull request carries the security reviewer's and a second reviewer's"
  echo "  approval; git log --oneline -- gates shows the merge, not a direct push to main."
  echo "RECORD: evidence_add GD-1.1 gates-directory E-05 1.1.1 \"repo:gates/README.md@<commit>\"."
  echo "  The block's own 'checkpoint GD-1.1 DONE' records the step: no agp-platform done needed."
}

step GD-1.2 HUMAN "The freshness table" --witness --needs "PLATFORM_REPO_DIR GATES_DIR PLATFORM_REPO_SLUG SECURITY_REVIEWER_EMAIL"
s_GD_1_2_check() { ckpt_done GD-1.2; }
s_GD_1_2_manual() {
  echo "WHO: platform owner writes; the security reviewer signs (by approving the pull request)."
  echo "WHERE: PLATFORM_REPO_DIR, merged by pull request."
  echo "DO: run GD-1.2's block of setup/42 as written: it stops unless GD-1.1 is merged, then writes gates/freshness.tsv"
  echo "  (here-document), commits on gd-1-2-freshness, pushes and opens the pull request."
  echo "VERIFY: awk -F'\\t' 'NR>1 && NF<3 {print \"BAD ROW \" NR}' \"\$PLATFORM_REPO_DIR/\$GATES_DIR/freshness.tsv\" prints"
  echo "  nothing; every id is in 38 §3's table or 42 §1.1 (comm the two lists)."
  echo "RECORD: evidence_add GD-1.2 gate-freshness E-05 1.1.2 \"repo:gates/freshness.tsv@<commit>\". The block's own"
  echo "  'checkpoint GD-1.2 DONE \"\$SECURITY_REVIEWER_EMAIL\"' records the step."
}

step GD-1.3 HUMAN "The index generator and the first index" --needs "PLATFORM_REPO_DIR GATES_DIR BUILD_LOG_DIR"
s_GD_1_3_check() { ckpt_done GD-1.3; }
s_GD_1_3_manual() {
  echo "WHO: platform owner."
  echo "WHERE: shell in PLATFORM_REPO_DIR."
  echo "DO: run GD-1.3's block of setup/42 as written: tools/gate-index.sh (here-document), then its first run, saved as"
  echo "  \$BUILD_LOG_DIR/records/<date>-GD-1.3-gate-index-v1.tsv."
  echo "VERIFY: one row per row of freshness.tsv, every verdict MISSING at first. Prove the commit branch with a throwaway"
  echo "  gates/G10-1970-01-01.md (result: PASS, commit: deadbeef): deadbeef GREEN, cafe RED, no argument AMBER, the"
  echo "  commit: line deleted MISSING. Delete the throwaway afterwards."
  echo "RECORD: <date>-GD-1.3-gate-index-v1 (E-05, TISAX 1.1.1, 1.5.1); then: agp-platform done GD-1.3"
}

step GD-1.4 HUMAN "File the records that already exist" --needs "PLATFORM_REPO_DIR GATES_DIR"
s_GD_1_4_check() { ckpt_done GD-1.4; }
s_GD_1_4_manual() {
  echo "WHO: platform owner; the security reviewer checks each record against its producing step. Repeatable."
  echo "WHERE: PLATFORM_REPO_DIR/gates, branch gd-1-4-filing, pushed, gh pr create."
  echo "DO: one pointer record per existing gate record, under its gate id, from gates/record.template.md (front matter"
  echo "  filled, one evidence entry citing the original's path); never a copy of the original. TIER-R points at"
  echo "  repo:records/gates/<date>-tier-r-record-v1.md@<commit>; GATE_CHECKLIST_RECORD splits into G1..G21 files."
  echo "VERIFY: tools/gate-index.sh prints no MISSING and no MALFORMED for a gate whose producing file is DONE; any gate"
  echo "  still MISSING is listed in the sitting's note with the file it waits on."
  echo "RECORD: evidence_add GD-1.4 gate-index-first-fill E-05 6.3 \"repo:gates@<commit>\"; then: agp-platform done GD-1.4"
}

# ======================================================================== 2. The Tier W gate record (Sitting B)

step GD-2.1 AUTO-READ "Collect the Tier W rows" --on-unmet skip --note "$GD_SITTING_B" \
  --needs "PLATFORM_REPO_DIR GATES_DIR BUILD_LOG_DIR EVIDENCE_REGISTER RESTORE_DRILL_RECORD"
s_GD_2_1_check() { ckpt_done GD-2.1; }
s_GD_2_1_apply() {
  local n out=""
  if [ "$AGP_MODE" != apply ]; then
    _gd_plan "need $GD_TIERW_NAMES (each unset name prints TIER W NOT OPEN)"
    _gd_save GD-2.1 tier-w-inputs E-05 6.3 GD-2.1-tier-w-inputs-v1.txt < /dev/null
    return 0
  fi
  for n in $GD_TIERW_NAMES; do has_value "$n" || out="${out}TIER W NOT OPEN: $n
"; done
  printf '%s' "${out:-every Tier W input is set
}" | _gd_save GD-2.1 tier-w-inputs E-05 6.3 GD-2.1-tier-w-inputs-v1.txt || return 1
  # The page: a printed name is a red W line, and the record is still written (result: FAIL, the name in
  # actions), never left unwritten. So a printed name is GD-2.2's input, not a stop here.
  [ -z "$out" ] || _gd_say "red W lines above: GD-2.2 writes TIER_W_RECORD as a failing record (its result field), each printed name in actions."
  return 0
}

step GD-2.2 HUMAN "Write TIER_W_RECORD" --witness --on-unmet skip --note "$GD_SITTING_B" \
  --needs "PLATFORM_REPO_DIR GATES_DIR SECURITY_REVIEWER_EMAIL RESTORE_DRILL_RECORD" --sets "TIER_W_RECORD"
s_GD_2_2_check() { ckpt_done GD-2.2; }
s_GD_2_2_manual() {
  echo "WHO: platform owner writes; the security reviewer and the ISMS both sign."
  echo "WHERE: PLATFORM_REPO_DIR, merged by pull request."
  echo "DO: GD-2.2's block of setup/42: copy gates/record.template.md to gates/TIER-W-<date>.md; fill gate: TIER-W, one"
  echo "  evidence entry per row of GD-2.1, result (FAIL with the missing names in actions if GD-2.1 printed any),"
  echo "  freshness_days: none; penv_set TIER_W_RECORD; add; commit; open the pull request."
  echo "VERIFY: need TIER_W_RECORD; ten evidence entries; tools/gate-index.sh prints TIER-W ... GREEN; both signatures."
  echo "RECORD: evidence_add GD-2.2 tier-w-record E-05 6.3 \"repo:\$R@<commit>\". The block's own"
  echo "  'checkpoint GD-2.2 DONE \"\$SECURITY_REVIEWER_EMAIL\"' records the step."
}

step GD-2.3 HUMAN "Hand G19 and G20 to the gate" --witness --on-unmet skip --note "$GD_SITTING_B" \
  --needs "PLATFORM_REPO_DIR RESTORE_DRILL_RECORD"
s_GD_2_3_check() { ckpt_done GD-2.3; }
s_GD_2_3_manual() {
  echo "WHO: platform owner; the security reviewer confirms (the witness)."
  echo "WHERE: README's re-run index, §7 gate table and §5 variable list (wiki pull request); 16's register schema."
  echo "DO: the two re-run lines; §7's G19 row corrected ('grant day: parsed in 38 ...; standing: TIER_W_RECORD ...');"
  echo "  the six names of 42 in §5; then confirm the schema treats G19 and G20 as gate_checklist lines."
  echo "VERIFY: grep -c 'g19\\|g20' register/schema/*.json at least one each; grep -n 'rows in 42, parsed in 38' README.md"
  echo "  finds nothing; grep -c 'TIER_W_RECORD\\|PLATFORM_EVIDENCE_BUCKET' README.md at least 2."
  echo "RECORD: the two commits (E-05, TISAX 6.3); then: agp-platform done GD-2.3 --witness <security reviewer>"
}

# ======================================================================== 3. The platform evidence bucket

_gd_kh_key() {  # the Autokey key the handle returned, or nothing
  r gcloud kms key-handles describe "$GD_KH" --location="$(v REGION)" --project="$(v LOGGING_PROJECT)" --format='value(kmsKey)' 2>/dev/null
}

s_GD_3_1_check() {   # the bucket exists, both names are set, and the departure row BD-42-1 is in the register;
                     # or a person recorded the step (the page's own block ends with checkpoint GD-3.1 DONE)
  local rc
  ckpt_done GD-3.1 && return 0
  exists r gcloud storage buckets describe "$(_gd_bucket)" --project="$(v LOGGING_PROJECT)" --format='value(name)'; rc=$?
  [ $rc = 0 ] || return $rc
  has_value PLATFORM_EVIDENCE_BUCKET && has_value RECORD_RETENTION_DAYS || return 1
  grep -q '^| BD-42-1 |' "$(v DEVIATION_REGISTER)" 2>/dev/null
}
step GD-3.1 AUTO "Create the bucket" --irreversible --witness --gate "NAMES P13" \
  --needs "ENT_PROJECT_REPAIR_CORE SECOND_HUMAN_EMAIL CICD_PROJECT PLATFORM_REPO_DIR LOGGING_PROJECT REGION KEY_PLATFORM_LOGS EVIDENCE_RETENTION_DAYS DEVIATION_REGISTER BUILD_LOG_DIR EVIDENCE_REGISTER" \
  --sets "PLATFORM_EVIDENCE_BUCKET RECORD_RETENTION_DAYS"
s_GD_3_1_apply() {
  local t rd B key i row line f rc
  t="$(agp_tool decision-value.sh)"; B="$(_gd_bucket)"
  _gd_grant ENT_PROJECT_REPAIR_CORE 3600 "setup 42 GD-3.1 and GD-3.3: platform evidence bucket, its key handle and its IAM in LOGGING_PROJECT" \
    --additional-email-recipients="$(v SECOND_HUMAN_EMAIL)" || return 1
  x checkpoint GD-3.1 START "$(v SECOND_HUMAN_EMAIL)" - "create the platform evidence bucket" || return 1
  if [ "$AGP_MODE" = apply ]; then
    [ "$(v REGION)" = europe-west1 ] || { _gd_say "STOP: REGION is $(v REGION), not europe-west1"; return 1; }
    case "$(v EVIDENCE_RETENTION_DAYS)" in *[!0-9]*) _gd_say "STOP: EVIDENCE_RETENTION_DAYS is not an integer"; return 1;; esac
    [ -x "$t" ] || { _gd_say "STOP: $t is not installed (03 DC-1.2)"; return 1; }
    rd="$("$t" P13 RECORD_RETENTION_DAYS 2>/dev/null)"
    case "$rd" in ''|*[!0-9]*) _gd_say "STOP: P13 has no integer RECORD_RETENTION_DAYS; amend the record (03 DC-4.8) before this sitting"; return 1;; esac
    [ "$rd" -ge 400 ] && [ "$rd" -le 3650 ] || { _gd_say "STOP: record value $rd outside 400..3650"; return 1; }
  else
    _gd_plan "REGION is europe-west1; EVIDENCE_RETENTION_DAYS an integer; tools/decision-value.sh P13 RECORD_RETENTION_DAYS digits in 400..3650"
    rd="<from P13>"
  fi
  pset PLATFORM_EVIDENCE_BUCKET "$B" || return 1
  pset RECORD_RETENTION_DAYS "$rd" || return 1
  # the key handle: an explicit id, so a re-run is idempotent; a key handle cannot be deleted
  if [ "$AGP_MODE" != apply ] || ! _gd_pre exists r gcloud kms key-handles describe "$GD_KH" --location="$(v REGION)" --project="$(v LOGGING_PROJECT)" --format='value(name)'; then
    x gcloud kms key-handles create --key-handle-id="$GD_KH" --location="$(v REGION)" --resource-type=storage.googleapis.com/Bucket \
      --project="$(v LOGGING_PROJECT)" || _gd_say "key-handle create returned non-zero (already exists, or still provisioning); polling"
  fi
  if [ "$AGP_MODE" = apply ]; then
    key=""; i=0
    while [ $i -lt 12 ]; do key="$(_gd_kh_key)"; [ -n "$key" ] && break; i=$((i + 1)); _gd_sleep 10; done
    case "$key" in projects/*/locations/europe-west1/keyRings/*/cryptoKeys/*) _gd_say "Autokey key: $key";;
      *) _gd_say "STOP: no Autokey key for the evidence bucket (11 KV-6 on fld-platform-core); read: ${key:-nothing}"
         _gd_say "  The page ends the sitting here: Autokey on fld-platform-core is set right (11 KV-6), then this step is resumed."
         return 98;; esac
  else
    _gd_plan "$(agp_quote gcloud kms key-handles describe "$GD_KH" --location="$(v REGION)" --project="$(v LOGGING_PROJECT)" --format='value(kmsKey)') until set (12 x 10 s); a key in europe-west1"
    key="<the Autokey key of $GD_KH>"
  fi
  if [ "$AGP_MODE" != apply ] || ! _gd_pre exists r gcloud storage buckets describe "$B" --project="$(v LOGGING_PROJECT)" --format='value(name)'; then
    x gcloud storage buckets create "$B" --project="$(v LOGGING_PROJECT)" --location="$(v REGION)" --default-storage-class=STANDARD \
      --uniform-bucket-level-access --public-access-prevention --default-encryption-key="$key" --soft-delete-duration=30d || return 1
  else _gd_say "$B exists; not created again"; fi
  x gcloud storage buckets update "$B" --project="$(v LOGGING_PROJECT)" --versioning || return 1
  row="| BD-42-1 | $(date -u +%F) | 42 GD-3.1 | DEV | platform evidence bucket in LOGGING_PROJECT, where 08 section 2.2 S15, section 5.4 and 02 section 5 place it in CORE_PROJECT (reason: 42 section 3.1); encrypted by its own Autokey key handle kh-platform-evidence, never KEY_PLATFORM_LOGS (11 KV-2.3) | project $(v LOGGING_PROJECT) | GD-3.1 record | bucket $B; key handle kh-platform-evidence | BLOCKED: no factory | - | $(v SECOND_HUMAN_EMAIL) | superseded when 08 section 5.4 and 02 section 5 cite this departure as an amendment (GD-7.1) | open |"
  if [ "$AGP_MODE" != apply ] || ! grep -q '^| BD-42-1 |' "$(v DEVIATION_REGISTER)"; then x bd_insert "$row" || return 1; fi
  # VERIFY
  f="$(_gd_rec GD-3.1-evidence-bucket-v1.yaml)"
  if [ "$AGP_MODE" != apply ]; then
    _gd_plan "$(agp_quote gcloud storage buckets describe "$B" --project="$(v LOGGING_PROJECT)" --format=yaml) > ${f##*/}"
    _gd_plan "$(agp_quote gcloud storage buckets describe "$B" --project="$(v LOGGING_PROJECT)" --format="value(location,default_storage_class,uniform_bucket_level_access,public_access_prevention)") prints EUROPE-WEST1 STANDARD True enforced"
    _gd_plan "$(agp_quote gcloud kms keys get-iam-policy "$(v KEY_PLATFORM_LOGS)" --format=json): the Logging service account still the only Encrypter/Decrypter"
    ev GD-3.1 evidence-bucket E-05 "5.2.4, 8.1" "build-log:records/${f##*/}"
    return 0
  fi
  r gcloud storage buckets describe "$B" --project="$(v LOGGING_PROJECT)" --format=yaml | xw "$f" 600 || return 1
  line="$(r gcloud storage buckets describe "$B" --project="$(v LOGGING_PROJECT)" --format="value(location,default_storage_class,uniform_bucket_level_access,public_access_prevention)" | tr -s '\t ' '  ')"
  _gd_say "read: $line"
  r gcloud kms keys get-iam-policy "$(v KEY_PLATFORM_LOGS)" --format=json | sed 's/^/        /' >&3; rc=$?
  [ $rc = 0 ] || _gd_say "the KEY_PLATFORM_LOGS policy could not be read: read it by hand into the record"
  ev GD-3.1 evidence-bucket E-05 "5.2.4, 8.1" "build-log:records/${f##*/}" "$f" || return 1
  _gd_say "Read from ${f##*/} by eye into the record: versioning enabled, the default key is the handle's (KMS_PROJECT, europe-west1),"
  _gd_say "  soft delete 30 days; the second human signs it. GD-3.2 does not run until this VERIFY is recorded."
  [ "$line" = "EUROPE-WEST1 STANDARD True enforced" ] && return 0
  _gd_say "STOP: expected 'EUROPE-WEST1 STANDARD True enforced'. A wrong location: delete while empty and unlocked, and re-create."
  _gd_say "  The page stops here; a person reads the dump, decides with the second human, then resumes this step."
  return 98
}

step GD-3.2 HUMAN "Set the retention period, then lock it" --witness --irreversible --gate "P13" \
  --needs "PLATFORM_EVIDENCE_BUCKET RECORD_RETENTION_DAYS PLATFORM_REPO_DIR BUILD_LOG_DIR ENT_PROJECT_REPAIR_CORE SECOND_HUMAN_EMAIL CICD_PROJECT"
s_GD_3_2_check() { ckpt_done GD-3.2; }
s_GD_3_2_manual() {
  echo "IRREVERSIBLE: a locked retention policy cannot be removed or shortened, and it puts a lien on LOGGING_PROJECT."
  echo "WHO: platform owner runs under ENT_PROJECT_REPAIR_CORE; the second human is present, approves and countersigns."
  echo "WHERE: shell. Each block requests its own grant (gcloud pam grants create ... --billing-project=\"\$CICD_PROJECT\")."
  echo "DO, sitting 1: GD-3.2's first block of setup/42 (both assertions, the grant, buckets update --retention-period=P<days>D,"
  echo "  describe --format=\"default(retention_policy)\"). Then write the four checks into the record: the value equals"
  echo "  P13's record class; no test object in the bucket; the lien accepted in writing by the security reviewer; the"
  echo "  bucket's Autokey key has no destroy scheduled."
  echo "DO, a later sitting: the second block (assertions, the grant, describe read aloud by the second human, checkpoint START,"
  echo "  buckets update --lock-retention-period)."
  echo "VERIFY: retention_policy shows the lock and RECORD_RETENTION_DAYS x 86400 s; update --retention-period=P1D is REFUSED."
  echo "RECORD: <date>-GD-3.2-evidence-bucket-locked-v1, signed by both (E-06); then: agp-platform done GD-3.2 --witness <second human>"
}

_gd_m3() {  # the member of the third binding: the security group, or the second human when they are not in it
  if [ "$AGP_MODE" = apply ] && ! nonempty r gcloud identity groups memberships list --group-email="$(v GRP_PLATFORM_SECURITY)" \
       --filter="preferredMemberKey.id=$(v SECOND_HUMAN_EMAIL)" --format='value(name)'; then
    printf 'user:%s' "$(v SECOND_HUMAN_EMAIL)"; return 0
  fi
  printf 'group:%s' "$(v GRP_PLATFORM_SECURITY)"
}
_gd_bpol() { r gcloud storage buckets get-iam-policy "$(v PLATFORM_EVIDENCE_BUCKET)" --project="$(v LOGGING_PROJECT)" "$@"; }

s_GD_3_3_check() {
  local rc
  has_binding "group:$(v GRP_PLATFORM_OWNERS)" roles/storage.objectCreator _gd_bpol || return $?
  has_binding "group:$(v GRP_PLATFORM_SECURITY)" roles/storage.objectViewer _gd_bpol || return $?
  has_binding "group:$(v GRP_PLATFORM_SECURITY)" roles/storage.objectCreator _gd_bpol; rc=$?
  if [ $rc = 1 ]; then has_binding "user:$(v SECOND_HUMAN_EMAIL)" roles/storage.objectCreator _gd_bpol || return $?; elif [ $rc != 0 ]; then return $rc; fi
  has_binding "user:$(v INCIDENT_COMMANDER_EMAIL)" roles/storage.objectCreator _gd_bpol
}
step GD-3.3 AUTO "Access: who writes, who reads, nobody deletes" --witness \
  --needs "PLATFORM_EVIDENCE_BUCKET GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY INCIDENT_COMMANDER_EMAIL SECOND_HUMAN_EMAIL ENT_PROJECT_REPAIR_CORE CICD_PROJECT LOGGING_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_GD_3_3_apply() {
  local B m3 f out pf
  B="$(v PLATFORM_EVIDENCE_BUCKET)"
  _gd_grant ENT_PROJECT_REPAIR_CORE 3600 "setup 42 GD-3.3: platform evidence bucket IAM in LOGGING_PROJECT" \
    --additional-email-recipients="$(v SECOND_HUMAN_EMAIL)" || return 1
  _gd_plan "$(agp_quote gcloud identity groups memberships list --group-email="$(v GRP_PLATFORM_SECURITY)" --filter="preferredMemberKey.id=$(v SECOND_HUMAN_EMAIL)" --format='value(name)') (the second human must be a member; otherwise the third binding is user:SECOND_HUMAN_EMAIL)"
  m3="$(_gd_m3)"
  case "$m3" in user:*) _gd_say "the second human is not a member of GRP_PLATFORM_SECURITY: the third binding goes to $m3 (write the reason into the record)";; esac
  x gcloud storage buckets add-iam-policy-binding "$B" --project="$(v LOGGING_PROJECT)" --member="group:$(v GRP_PLATFORM_OWNERS)" --role=roles/storage.objectCreator || return 1
  x gcloud storage buckets add-iam-policy-binding "$B" --project="$(v LOGGING_PROJECT)" --member="group:$(v GRP_PLATFORM_SECURITY)" --role=roles/storage.objectViewer || return 1
  x gcloud storage buckets add-iam-policy-binding "$B" --project="$(v LOGGING_PROJECT)" --member="$m3" --role=roles/storage.objectCreator || return 1
  x gcloud storage buckets add-iam-policy-binding "$B" --project="$(v LOGGING_PROJECT)" --member="user:$(v INCIDENT_COMMANDER_EMAIL)" --role=roles/storage.objectCreator || return 1
  f="$(_gd_rec GD-3.3-evidence-bucket-iam-v1.json)"; pf="$(_gd_rec GD-3.3-logging-project-iam-v1.json)"
  if [ "$AGP_MODE" != apply ]; then
    _gd_plan "$(agp_quote gcloud storage buckets get-iam-policy "$B" --project="$(v LOGGING_PROJECT)" --format=json) > ${f##*/}: the four bindings, and only"
    _gd_plan "  the projectOwner:/projectEditor:/projectViewer: legacy-role bindings Google adds besides; no eve-, mo- or walle- account"
    _gd_plan "$(agp_quote gcloud projects get-iam-policy "$(v LOGGING_PROJECT)" --format=json): no user:, group: or domain: member holds roles/owner, editor or viewer"
    ev GD-3.3 evidence-bucket-iam - "4.1.3, 4.2.1" "build-log:records/${f##*/}"
    return 0
  fi
  _gd_bpol --format=json | xw "$f" 600 || return 1
  r gcloud projects get-iam-policy "$(v LOGGING_PROJECT)" --format=json | xw "$pf" 600 || return 1
  # The page's VERIFY: exactly the four bindings, plus the legacy roles Google gives the project's basic-role
  # holders on a uniform-access bucket (convenience members), and nobody holds a basic role on the project.
  out="$(_gd_py 'import json,sys
p=json.load(open(sys.argv[1]))
want={("roles/storage.objectCreator","group:"+sys.argv[2]),("roles/storage.objectViewer","group:"+sys.argv[3]),
      ("roles/storage.objectCreator",sys.argv[4]),("roles/storage.objectCreator","user:"+sys.argv[5])}
conv={"projectOwner:":("roles/storage.legacyBucketOwner","roles/storage.legacyObjectOwner"),
      "projectEditor:":("roles/storage.legacyBucketOwner","roles/storage.legacyObjectOwner"),
      "projectViewer:":("roles/storage.legacyBucketReader","roles/storage.legacyObjectReader")}
got=set()
for b in p.get("bindings", []):
    r=b.get("role",""); ms=b.get("members",[])
    print("%s %s" % (r, " ".join(ms)))
    if b.get("condition"): print("FAIL %s carries a condition: not one of the four bindings" % r)
    for m in ms:
        pre=m.split(":",1)[0]+":"
        if pre in conv:
            if r in conv[pre]: print("CONVENIENCE %s %s (Google adds it to a uniform-access bucket; recorded)" % (m, r))
            else: print("FAIL %s holds %s, which Google does not add" % (m, r))
        elif (r, m) in want: got.add((r, m))
        else: print("FAIL %s holds %s: not one of the four bindings" % (m, r))
        if any(k in m for k in ("eve-","mo-","walle-")): print("FAIL %s is an agent account" % m)
for r, m in sorted(want - got): print("FAIL missing %s %s" % (m, r))
pp=json.load(open(sys.argv[6])) if len(sys.argv) > 6 else {"bindings": []}
for b in pp.get("bindings", []):
    if b.get("role") in ("roles/owner","roles/editor","roles/viewer"):
        for m in b.get("members", []):
            if m.startswith(("user:","group:","domain:")): print("FAIL %s holds %s on the project" % (m, b.get("role")))
            else: print("PROJECT %s %s (not a person; recorded)" % (b.get("role"), m))' \
    "$f" "$(v GRP_PLATFORM_OWNERS)" "$(v GRP_PLATFORM_SECURITY)" "$m3" "$(v INCIDENT_COMMANDER_EMAIL)" "$pf" 2>&1)"
  printf '%s\n' "$out" | sed 's/^/        /' >&3
  ev GD-3.3 evidence-bucket-iam - "4.1.3, 4.2.1" "build-log:records/${f##*/}" "$f" || return 1
  _gd_say "The CONVENIENCE lines go into the record by name, with the reason the page gives (nobody holds a basic role there)."
  _gd_say "The two refusals, as a member of GRP_PLATFORM_OWNERS, once an object exists (GD-3.4): gcloud storage cat on a known"
  _gd_say "  object FAILS; a second gcloud storage cp over an existing object FAILS. Both go into the record."
  ! printf '%s\n' "$out" | grep -q '^FAIL'
}

# GD-3.4 is HUMAN: its WHO gives the scans to the second human and its VERIFY to a GRP_PLATFORM_SECURITY
# member (the platform owner holds neither storage.objects.list nor .get, and must not), and the copy rows
# are appended to the register by hand. A scripted copy would be recorded DONE without those halves.
step GD-3.4 HUMAN "Copy the backlog" --witness --needs "PLATFORM_EVIDENCE_BUCKET BUILD_LOG_DIR EVIDENCE_REGISTER LOGGING_PROJECT"
s_GD_3_4_check() { ckpt_done GD-3.4; }
s_GD_3_4_manual() {
  echo "Repeatable: Sitting A, then Sitting B, Sitting C and each quarterly review (re-run the block; already-copied rows are skipped)."
  echo "WHO: platform owner copies text records; the second human copies the scans (EVIDENCE_INTERIM_LOCATION);"
  echo "  a GRP_PLATFORM_SECURITY member (usually the security reviewer) runs the VERIFY. WHERE: shell; the shared drive."
  echo "DO: GD-3.4's ACTION block of setup/42 in the sitting shell, with --project=\"\$LOGGING_PROJECT\" on its gcloud storage cp;"
  echo "  then, by hand, for each COPIED line a register row with the same record id, its original date, step, E-xx, TISAX,"
  echo "  location and hash, and the object path in 'Copied to evidence bucket' (not evidence_add)."
  echo "  SHA MISMATCH and NO FILE are severity 2 findings, not retries."
  echo "VERIFY (the security member, never the platform owner): GD-3.4's three commands; the object count equals the"
  echo "  build-log: rows with a filled copy column; no SHA MISMATCH or NO FILE; three sha256 spot-checks match the register."
  echo "RECORD: <date>-GD-3.4-backlog-copy-v1 plus the three readings (E-05; TISAX 1.5.1, 5.2.4);"
  echo "  then: agp-platform done GD-3.4 --witness <the security member who ran the VERIFY>"
}

step GD-3.5 HUMAN "The standing copy rule"
s_GD_3_5_check() { ckpt_done GD-3.5; }
s_GD_3_5_manual() {
  echo "WHO: whoever made a record, the same day. WHERE: the step's own sitting."
  echo "DO: from now on each record's copy is made the same day and a second register row with the same record id and the"
  echo "  copy columns filled is appended by hand, per GD-3.5's table (text records: the operator; scans and custody"
  echo "  scans: the second human; decisions and gate records: the platform owner; tabletops: the incident commander)."
  echo "VERIFY (at the next quarterly review): GD-3.5's awk with cut=<GD-3.1's date> prints no UNCOPIED older than 7 days;"
  echo "  a record legitimately not copied carries n/a with a reason."
  echo "RECORD: the amended §7.1 table with GD-3.6's merge (E-05); then: agp-platform done GD-3.5"
}

step GD-3.6 HUMAN "Correct the three pages that promise a copy this file only now makes" --witness
s_GD_3_6_check() { ckpt_done GD-3.6; }
s_GD_3_6_manual() {
  echo "WHO: platform owner; the security reviewer approves the merge (the witness)."
  echo "WHERE: the setup pages, merged by pull request, at the end of Sitting A."
  echo "DO: 01 §7.1's 'Platform evidence bucket | After 14' row, README §4 'Evidence' and a README §9 re-run row, as GD-3.6 words them."
  echo "VERIFY: grep -n 'After 14' 01-prerequisites-and-conventions.md and grep -n 'copied to the platform evidence bucket after 14'"
  echo "  README.md find nothing; grep -c 'GD-3.4' finds at least 1 in each."
  echo "RECORD: <date>-GD-3.6-evidence-home-corrections-v1 (E-05); then: agp-platform done GD-3.6 --witness <security reviewer>"
}

# ======================================================================== 4. The evidence register and its two mappings

_gd_4_1_reads() {
  local reg="$1" ck="$2"
  echo "# rows"; grep -c '^| 20' "$reg"
  echo "# duplicate record ids"; awk -F' *\\| *' '/^\| 20/{print $2}' "$reg" | sort | uniq -d
  echo "# rows with no E-xx and no TISAX id"; awk -F' *\\| *' '/^\| 20/ && $5=="-" && $6=="-" {print $2}' "$reg"
  echo "# rows with no SHA-256 and a file-shaped location"
  awk -F' *\\| *' '/^\| 20/ { k=$2; sub(/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-/, "", k); sub(/-v[0-9]+$/, "", k)
    if ($8 != "-" && $8 != "") { h[k]=1; next }
    if ($7 ~ /^(build-log|repo|bucket|witness):/ && $7 !~ /^repo:[^ ]*@[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]+$/) { n++; id[n]=$2; key[n]=k } }
    END { for (i=1; i<=n; i++) if (!(key[i] in h)) print id[i] }' "$reg"
  echo "# steps with a DONE checkpoint and no evidence row"
  comm -23 <(awk -F'\t' '$3=="DONE"{print $2}' "$ck" | sort -u) <(awk -F' *\\| *' '/^\| 20/{print $4}' "$reg" | sort -u)
  echo "# steps whose newest checkpoint is BLOCKED or PENDING (not missing records)"
  awk -F'\t' '$3=="BLOCKED" || $3=="PENDING"{s[$2]=$3} END {for (k in s) print k"\t"s[k]}' "$ck" | sort
}
step GD-4.1 AUTO-READ "Consolidate" --needs "EVIDENCE_REGISTER BUILD_LOG_DIR"
s_GD_4_1_check() { ckpt_done GD-4.1; }
s_GD_4_1_apply() {
  local out bad
  if [ "$AGP_MODE" != apply ]; then
    _gd_plan "six sections over EVIDENCE_REGISTER and checkpoints.tsv: rows; duplicate ids; no E-xx and no TISAX; no SHA-256 with a file-shaped"
    _gd_plan "  location; DONE steps with no evidence row; BLOCKED and PENDING steps. Sections 2 to 4 must be empty"
    _gd_save GD-4.1 register-consolidation E-05 1.5.1 GD-4.1-register-consolidation-v1.txt < /dev/null
    return 0
  fi
  out="$(_gd_4_1_reads "$(v EVIDENCE_REGISTER)" "$(v BUILD_LOG_DIR)/checkpoints.tsv")"
  printf '%s\n' "$out" | _gd_save GD-4.1 register-consolidation E-05 1.5.1 GD-4.1-register-consolidation-v1.txt || return 1
  bad="$(printf '%s\n' "$out" | awk '/^# duplicate/{s=1; next} /^# steps with a DONE/{s=0} /^#/{next} s && NF {n++} END {print n+0}')"
  _gd_say "Section 5 names are missing records (an action with an owner and a date) unless their EVIDENCE line says none on purpose."
  [ "$bad" = 0 ] && return 0
  _gd_say "sections 2 to 4 are not empty ($bad lines): a duplicate id is a versioning error; a section 4 record is corrected by"
  _gd_say "  evidence_add again for its step and slug with the FILE argument (a directory: a summary file of its hashes); then re-run"
  return 1
}

step GD-4.2 AUTO-READ "The EU AI Act mapping: every E-xx has a producer" --witness --needs "EVIDENCE_REGISTER BUILD_LOG_DIR"
s_GD_4_2_check() { ckpt_done GD-4.2; }
s_GD_4_2_apply() {
  local e n out="" zero=""
  if [ "$AGP_MODE" != apply ]; then
    _gd_plan "for e in $GD_EIDS: grep -c \"| \$e |\" EVIDENCE_REGISTER; every id but E-14 at least 1"
    _gd_save GD-4.2 eu-ai-act-mapping E-05 7.1.1 GD-4.2-eu-ai-act-mapping-v1.txt < /dev/null
    return 0
  fi
  for e in $GD_EIDS; do
    n="$(grep -c "| $e |" "$(v EVIDENCE_REGISTER)")"
    out="$out$(printf '%s\t%s' "$e" "$n")
"
    [ "$n" -ge 1 ] || zero="$zero $e"
  done
  out="${out}E-14	not produced: the classification is not high-risk (10 §3)
"
  printf '%s' "$out" | _gd_save GD-4.2 eu-ai-act-mapping E-05 7.1.1 GD-4.2-eu-ai-act-mapping-v1.txt || return 1
  _gd_say "The AI compliance owner (the witness) signs the counts and GD-4.2's table."
  [ -z "$zero" ] && return 0
  _gd_say "count 0 for:$zero. A 0 for E-01, E-02, E-05, E-07, E-12 or E-13 blocks the stage it belongs to (10 §5);"
  _gd_say "  the producing step of each id is in GD-4.2's table."
  return 1
}

# GD-4.3 is an export of the register into a derived pack (its ROLLBACK: the pack is never a source); nothing
# in Google changes, so it is AUTO-READ, and its VERIFY (no group without evidence) fails the step.
step GD-4.3 AUTO-READ "The TISAX §13 pack" --needs "PLATFORM_EVIDENCE_BUCKET BUILD_LOG_DIR PLATFORM_REPO_DIR EVIDENCE_REGISTER" --sets "EVIDENCE_PACK_DIR"
s_GD_4_3_check() { ckpt_done GD-4.3; }
s_GD_4_3_apply() {     # the page's loop; then the pack's top-level index, which is the registered record
  local P D g empty reg top n
  P="$(v BUILD_LOG_DIR)/packs"; D="$P/tisax-$(date -u +%F)"; reg="$(v EVIDENCE_REGISTER)"; top="$D/index.txt"
  pset EVIDENCE_PACK_DIR "$P" || return 1
  for g in $GD_TISAX_GROUPS; do
    x mkdir -p "$D/$g" || return 1
    if [ -f "$reg" ]; then
      awk -F' *\\| *' -v g="$g" '/^\| 20/ { n=split($6, t, /[ ,]+/); for (i=1; i<=n; i++) if (t[i]==g || index(t[i], g".")==1) { print $2"\t"$7; break } }' "$reg" | xw "$D/$g/index.tsv" 600 || return 1
    else
      xw "$D/$g/index.tsv" 600 < /dev/null || return 1
    fi
  done
  if [ "$AGP_MODE" != apply ]; then
    _gd_plan "find <the pack> -name index.tsv -size -2c -print: a group with no evidence is a mapping gap"
    xw "$top" 600 < /dev/null
    ev GD-4.3 tisax-pack - "1.1.1, 1.5.1" "build-log:packs/tisax-$(date -u +%F)/index.txt"
    return 0
  fi
  empty="$(find "$D" -name index.tsv -size -2c -print)"
  { printf 'TISAX section 13 pack, %s, from %s\n' "$(date -u +%F)" "$reg"
    for g in $GD_TISAX_GROUPS; do n="$(wc -l < "$D/$g/index.tsv" | tr -d ' ')"; printf '%s\t%s rows\n' "$g" "$n"; done
    printf 'groups with no evidence (find -size -2c):\n%s\n' "${empty:-none}"
    printf 'hand cross-checks against 11-tisax section 13 (3.1, 4.1-4.2, 5.2): in the v2 of this record, never added here\n'; } | xw "$top" 600 || return 1
  sed 's/^/        /' "$top" >&3
  ev GD-4.3 tisax-pack - "1.1.1, 1.5.1" "build-log:packs/tisax-$(date -u +%F)/index.txt" "$top" || return 1
  _gd_say "The ISMS receives the pack. Cross-check groups 3.1, 4.1-4.2 and 5.2 by hand against 11-tisax §13's Artefacts; the"
  _gd_say "  index and the three readings become a v2 record (index.txt is registered with its SHA-256: do not edit it)."
  _gd_say "  Hand-running the export is a DEV row in DEVIATION_REGISTER (no CI, B-03), written at GD-7.1."
  [ -z "$empty" ] && return 0
  _gd_say "a group with an empty index is a gap in the mapping, not an empty control: map the missing rows, then re-run"
  return 1
}

step GD-4.4 BLOCKED "The stage snapshot tag, by hand (E-05)" --note "B-03: the CI that tags and freezes the Annex IV bundle; the hand tag needs STAGE0_RECORD (39)"
s_GD_4_4_check() { ckpt_done GD-4.4; }
s_GD_4_4_manual() {
  echo "BLOCKED on B-03 for the automatic half: no workflow tags compliance/<agent>/S<n>/<date> on a stage-record merge."
  echo "The hand half needs STAGE0_RECORD (39, outside the platform layer): GD-4.4's block reads the stage record's commit,"
  echo "  tags it (git tag -a) and pushes the tag; the Annex IV index compliance/annex-iv/<date>.md sits beside it; a DEV row"
  echo "  records the hand-made tag. The run writes the BLOCKED checkpoint and continues."
}

step GD-4.5 HUMAN "The witness copy of the gate and drill records"
s_GD_4_5_check() { ckpt_done GD-4.5; }
s_GD_4_5_manual() {
  echo "WHO: a witness administrator uploads; the other checks the manifest. The platform owner hands over files only."
  echo "WHERE: the witness organisation (08 WO-3.3, repeatable). The platform owner cannot write there, by design."
  echo "DO: gate, drill, custody and rota records to WITNESS_BUCKET under drills/, custody/, rota/ and gates/, the same day."
  echo "VERIFY: gcloud storage ls \"\${WITNESS_BUCKET}/gates/\" (by a witness administrator) lists one object per file in gates/;"
  echo "  the manifest's SHA-256 values match EVIDENCE_REGISTER's."
  echo "RECORD: <date>-GD-4.5-witness-gates-v1 in the witness (E-08); then: agp-platform done GD-4.5"
}
