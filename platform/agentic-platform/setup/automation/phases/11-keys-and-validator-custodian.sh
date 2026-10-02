# phases/11-keys-and-validator-custodian.sh: setup/11, keys and the validator custodian (step prefix KV).
#
# Key rings, the four keys, the two attestors and their notes, Autokey on five folders, the key-state
# detection, and the validator custodian's home. Ring and key names are permanent: every ring and key
# create is IRREVERSIBLE and gated on the signed key table (03 DC-5.2, decision KEYS).
#
# Section 8 is BLOCKED as a whole: the page lists KV-8.1 to KV-8.12 as BLOCKED steps on B-13 (README
# section 8, a person: the security reviewer and the validator custodian named in 03), as 12 does for
# B-20. The runner writes their BLOCKED checkpoints and carries on to section 9, which is what the page's
# section 8 says a person does while the two names are MISSING (one `checkpoint KV-8.n BLOCKED` per step,
# then section 9). When B-13 is lifted, each step's text says what to run; this file is then re-classed.
#
# Checks of AUTO steps are existence and binding checks. Exact values (key purpose, protection level,
# rotation, the Logging service account's domain, the note policies, the Autokey key project, the zero
# Autokey Admin counts) are printed by the step that makes them, and enforced by KV-9.1, the page's
# live-state diff, which stops the sitting on any difference.
#
# Helpers private to this file start with kv_. They only read, compute or format; every change goes
# through x, xw, pset, ev or api.

phase 11 "Keys and the validator custodian" "11-keys-and-validator-custodian.md"
requires org "resourcemanager.folders.getIamPolicy resourcemanager.folders.setIamPolicy"

# ------------------------------------------------------------------ helpers
kv_today() { date -u +%F; }

kv_rec() {      # kv_rec NAME: the path of a record under BUILD_LOG_DIR/records, dated today
  printf '%s/records/%s-%s' "$(v BUILD_LOG_DIR)" "$(kv_today)" "$1"
}

kv_latest() {   # kv_latest SUFFIX: the latest non-empty BUILD_LOG_DIR/records/<date>-SUFFIX, whatever day it was written
  local f last=""
  for f in "$(v BUILD_LOG_DIR)"/records/*-"$1"; do [ -s "$f" ] && last="$f"; done
  [ -n "$last" ] && printf '%s' "$last"
}

kv_show() {     # a line of explanation in plan mode only
  [ "$AGP_MODE" = apply ] || agp_say "      $*"
}

kv_now() {      # kv_now CMD...: inside _apply, the read that decides whether a resource still has to be made.
  # It is the step's own check of that resource, so it runs in the check context, as the runner runs
  # _check; gcloud ignores the variable, the offline fakes read it.
  AGP_CALL_CONTEXT=check "$@"
}

kv_verify() {   # kv_verify WHAT EXPECTED READ: print the page's VERIFY comparison; 0 when equal
  if [ "$2" = "$3" ]; then echo "      VERIFY ok: $1"; return 0; fi
  echo "      VERIFY FAILED: $1: expected [$2], read [$3]"; return 1
}

kv_later() {    # after a failed kv_verify inside an AUTO step
  echo "      KV-9.1 re-reads this and stops the sitting while it differs: correct it before the next file uses it"
}

kv_done_today() {  # kv_done_today ID: checkpoints.tsv has a DONE line for ID written today (a guard runs once per sitting day)
  local f="${BUILD_LOG_DIR:-/nonexistent}/checkpoints.tsv"
  [ -f "$f" ] || return 1
  awk -F'\t' -v s="$1" -v d="$(kv_today)" '$2 == s && $3 == "DONE" && substr($1, 1, 10) == d {f=1} END {exit f ? 0 : 1}' "$f"
}

kv_keep() {     # kv_keep STEP SLUG E-ID TISAX EXT < content: write the record and register it as evidence
  local f; f="$(kv_rec "$1-$2-v1.$5")"
  xw "$f" || return 1
  ev "$1" "$2" "$3" "$4" "build-log:records/${f##*/}" "$f"
}

kv_read_keep() {   # kv_read_keep STEP SLUG E-ID TISAX EXT CMD...: run a read, keep its output as evidence
  local s="$1" sl="$2" e="$3" t="$4" ext="$5" out rc; shift 5
  out="$(r "$@" 2>&1)"; rc=$?
  if [ "$AGP_MODE" = apply ] && [ $rc -ne 0 ]; then printf '%s\n' "$out"; return 1; fi
  printf '%s\n' "$out" | kv_keep "$s" "$sl" "$e" "$t" "$ext"
}

kv_val() {      # kv_val CMD...: print what a read returns. 0 read, 1 not found, 2 another error, 3 offline
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local err out rc; err="$(mktemp "${TMPDIR:-/tmp}/agp-kv.XXXXXX")" || return 2
  out="$("$@" 2>"$err")"; rc=$?
  if [ $rc -ne 0 ]; then
    if grep -qiE 'NOT_FOUND|not found|does not exist|404' "$err"; then rm -f "$err"; return 1; fi
    sed 's/^/        /' "$err" >&3; rm -f "$err"; return 2
  fi
  rm -f "$err"; printf '%s' "$out"
}

kv_rerun_has() {   # kv_rerun_has STEP MEMBER: the re-run index holds a line for this step and member
  [ -f "$(v BUILD_LOG_DIR)/rerun-index.tsv" ] || return 1
  awk -F'\t' -v s="$1" -v m="$2" '$2 == s && $3 == m {f=1} END {exit f ? 0 : 1}' "$(v BUILD_LOG_DIR)/rerun-index.tsv"
}

kv_planok() { [ "$AGP_MODE" != apply ]; }   # a read that fed a record failed: fatal in apply only

kv_pending() {  # kv_pending MEMBER STEP WHAT: 01's exists_or_pending --pending; 0 when the PENDING line is written
  exists_or_pending --pending "$@"
  [ $? -eq 1 ]
}

kv_ak_folders() {  # the five Autokey folders, derived afresh every time (KV-6.2: never carried between steps)
  printf '%s %s %s %s %s' "$(v FLD_PLATFORM_CORE)" "$(v FLD_AGENTS_W)" "$(v FLD_AGENTS_P)" "$(v FLD_CONTROLLERS)" "$(v FLD_IMPROVERS)"
}

kv_ak_five() {     # kv_ak_five "LIST": exactly five entries, or stop (a loop over fewer would pass silently)
  # shellcheck disable=SC2086
  [ "$(printf '%s\n' $1 | wc -l | tr -d ' ')" -eq 5 ] && return 0
  agp_say "      AK_FOLDERS is not five folders: stop"; return 1
}

kv_json_src() {
  cat <<'PY'
import json, re, sys, datetime
op, a = sys.argv[1], sys.argv[2:]
def load(f=None):
    raw = open(f).read() if f else sys.stdin.read()
    return json.loads(raw) if raw.strip() else {}
def binds(p):
    return (p or {}).get('bindings', []) or []
def kv62(x, m):
    return x.get('role') == 'roles/cloudkms.autokeyAdmin' and m in x.get('members', []) and (x.get('condition') or {}).get('title') == 'kv-6-2-autokey-bootstrap'
if op == 'only':            # only ROLE MEMBER: the policy is exactly one binding, ROLE with MEMBER alone
    b = binds(load()); sys.exit(0 if len(b) == 1 and b[0].get('role') == a[0] and b[0].get('members') == [a[1]] else 1)
if op == 'role-members':    # role-members ROLE: the members of ROLE, one per line
    for x in binds(load()):
        if x.get('role') == a[0]:
            for m in x.get('members', []): print(m)
    sys.exit(0)
if op == 'count-role':      # count-role ROLE...: the number of bindings of any of these roles
    print(len([x for x in binds(load()) if x.get('role') in a])); sys.exit(0)
if op == 'only-role':       # only-role ROLE: every binding is ROLE (no other role on the resource)
    sys.exit(0 if all(x.get('role') == a[0] for x in binds(load())) else 1)
if op == 'ak-live':         # ak-live MEMBER: a KV-6.2 conditional binding exists and has not expired
    now = datetime.datetime.utcnow()
    for x in binds(load()):
        if kv62(x, a[0]):
            m = re.search(r"timestamp\('([0-9T:\-]+)Z?'\)", (x.get('condition') or {}).get('expression', ''))
            if m and datetime.datetime.strptime(m.group(1).rstrip('Z'), '%Y-%m-%dT%H:%M:%S') > now: sys.exit(0)
    sys.exit(1)
if op == 'ak-conds':        # ak-conds MEMBER: the KV-6.2 conditions bound to MEMBER, one JSON line each
    for x in binds(load()):
        if kv62(x, a[0]):
            c = x['condition']
            print(json.dumps({'title': c.get('title'), 'description': c.get('description'), 'expression': c.get('expression')}))
    sys.exit(0)
if op == 'ak-shape':        # ak-shape MEMBER: "conditional=N unconditional=M" for roles/cloudkms.autokeyAdmin
    b = [x for x in binds(load()) if x.get('role') == 'roles/cloudkms.autokeyAdmin']
    print('kv-6-2=%d unconditional=%d' % (len([x for x in b if kv62(x, a[0])]), len([x for x in b if not x.get('condition')]))); sys.exit(0)
if op == 'note-merge':      # note-merge RESOURCE MEMBER ROLE < getIamPolicy: the setIamPolicy body (01's access-array rule)
    p = load(); b = binds(p)
    if any(x.get('role') == a[2] for x in b):
        b = [dict(x, members=sorted(set(x.get('members', []) + [a[1]]))) if x.get('role') == a[2] else x for x in b]
    else:
        b = b + [{'role': a[2], 'members': [a[1]]}]
    p['bindings'] = b
    print(json.dumps({'resource': a[0], 'policy': p})); sys.exit(0)
if op == 'has':             # has ROLE MEMBER < policy
    sys.exit(0 if any(x.get('role') == a[0] and a[1] in x.get('members', []) for x in binds(load())) else 1)
if op == 'note-diff':       # note-diff BEFORE AFTER ROLE MEMBER: AFTER is BEFORE plus MEMBER on ROLE, and one ROLE binding
    def norm(p): return sorted((x.get('role'), m) for x in binds(p) for m in x.get('members', []))
    bf, af = norm(load(a[0])), norm(load(a[1]))
    want = sorted(set(bf + [(a[2], a[3])]))
    ok = af == want and len([x for x in binds(load(a[1])) if x.get('role') == a[2]]) == 1
    sys.exit(0 if ok else 1)
if op == 'count':           # count < policy: the number of bindings
    print(len(binds(load()))); sys.exit(0)
sys.exit(2)
PY
}

kv_json() { python3 -c "$(kv_json_src)" "$@"; }

kv_body() {     # kv_body OP ARGS...: a small JSON request body on standard output
  python3 - "$@" <<'PY'
import json, sys
op, a = sys.argv[1], sys.argv[2:]
if op == 'perms': print(json.dumps({'permissions': a}))
elif op == 'note': print(json.dumps({'name': a[0], 'attestation': {'hint': {'human_readable_name': a[1]}}}))
elif op == 'note-iam': print(json.dumps({'resource': a[0], 'policy': {'bindings': [{'role': 'roles/containeranalysis.notes.occurrences.viewer', 'members': [a[1]]}]}}))
PY
}

kv_policy() {   # kv_policy CMD...: an IAM policy as JSON, or nothing
  r "$@" --format=json 2>/dev/null
}

kv_key_read() { # kv_key_read PROJECT_NAME RING LOCATION KEY FIELDS: the describe values, joined by |
  r gcloud kms keys describe "$4" --keyring="$2" --location="$3" --project="$(v "$1")" --format="value($5)" | tr '\t' '|'
}

kv_ring() {     # kv_ring RING LOCATION PROJECT_NAME VAR STEP SLUG E-ID: create a ring once and record its name
  local ring="$1" loc="$2" pn="$3" var="$4" step="$5" slug="$6" eid="$7" p rc
  p="$(v "$pn")"
  kv_now exists gcloud kms keyrings describe "$ring" --location="$loc" --project="$p" --format="value(name)"; rc=$?
  case $rc in
    0) echo "      ring $ring exists: not created again (README section 4, resume rule 3)";;
    1|3) x gcloud kms keyrings create "$ring" --location="$loc" --project="$p" || return 1;;
    *) return 1;;
  esac
  pset "$var" "projects/${p}/locations/${loc}/keyRings/${ring}" || return 1
  kv_read_keep "$step" "$slug" "$eid" "5.1.1" txt gcloud kms keyrings describe "$ring" --location="$loc" --project="$p" --format="value(name)"
}

kv_ring_check() {   # kv_ring_check RING LOCATION PROJECT_NAME VAR: the ring exists and its variable names it
  local rc
  exists gcloud kms keyrings describe "$1" --location="$2" --project="$(v "$3")" --format="value(name)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  has_value "$4" || return 1
  [ "$(_penv_get "$4")" = "projects/$(v "$3")/locations/$2/keyRings/$1" ] || { agp_say "      $4 does not name ring $1"; return 2; }
}

# ------------------------------------------------------------------ 0. The sitting
step KV-0.1 AUTO-READ "Guard the shell and the exception" --gate "SD-01 KEYS" \
  --needs "KMS_PROJECT KMS_PROJECT_NUMBER CICD_PROJECT CICD_PROJECT_NUMBER VALIDATOR_PROJECT VALIDATOR_PROJECT_NUMBER LOGGING_PROJECT REGION BQ_LOCATION BOOTSTRAP_EXCEPTION_EXPIRY SA_1_ADMIN PLATFORM_REPO_DIR BUILD_LOG_DIR DEVIATION_REGISTER EVIDENCE_REGISTER FLD_PLATFORM_CORE FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS FLD_IMPROVERS FLD_AGENTS_R"
kv_key_table() {   # the signed key table's path: the Record column of the KEYS row of 03's tracker on origin/main
  local rec
  rec="$(r git -C "$(v PLATFORM_REPO_DIR)" show origin/main:decisions/TRACKER.md | awk -F'|' '{k=$2; gsub(/ /,"",k); if (k=="KEYS") {r=$4; gsub(/ /,"",r); print r}}' | head -n 1)"
  case "$rec" in ''|*tbd*) return 1;; esac
  printf 'decisions/%s' "$rec"
}
s_KV_0_1_check() { kv_done_today KV-0.1; }   # a guard: it runs again on every sitting day
s_KV_0_1_apply() {
  local bad=0 p a c k
  x mkdir -p "$(v BUILD_LOG_DIR)/records" || return 1
  if [ "$AGP_MODE" != apply ]; then
    kv_show "reads: gcloud config get project (must print nothing); gcloud config get account (must be $(v SA_1_ADMIN))"
    kv_show "       today before BOOTSTRAP_EXCEPTION_EXPIRY $(v BOOTSTRAP_EXCEPTION_EXPIRY); REGION europe-west1; BQ_LOCATION EU"
    kv_show "       git -C $(v PLATFORM_REPO_DIR) fetch origin; KEY_TABLE_RECORD = decisions/<Record of the KEYS row of decisions/TRACKER.md on origin/main>"
    kv_show "       git cat-file -e origin/main:<KEY_TABLE_RECORD> (never typed: read from 03's tracker at every sitting)"
    return 0
  fi
  p="$(r gcloud config get project 2>/dev/null)"
  case "$p" in ''|'(unset)') ;; *) echo "a default project is set: stop"; bad=1;; esac
  a="$(r gcloud config get account 2>/dev/null)"
  [ "$a" = "$(v SA_1_ADMIN)" ] || { echo "not signed in as SA_1_ADMIN (read '$a'): stop"; bad=1; }
  [ "$(kv_today)" \< "$(v BOOTSTRAP_EXCEPTION_EXPIRY)" ] || { echo "bootstrap exception expired: stop, re-sign SD-01 in 03"; bad=1; }
  [ "$(v REGION)" = europe-west1 ] || { echo "REGION is not europe-west1 (plan section 5): stop"; bad=1; }
  [ "$(v BQ_LOCATION)" = EU ] || { echo "BQ_LOCATION is not EU (plan section 5): stop"; bad=1; }
  r git -C "$(v PLATFORM_REPO_DIR)" fetch origin || { echo "git fetch origin failed: stop"; return 1; }
  k="$(kv_key_table)" || { echo "03's tracker names no signed KEYS record: stop"; return 1; }
  if r git -C "$(v PLATFORM_REPO_DIR)" cat-file -e "origin/main:$k"; then
    c="$(r git -C "$(v PLATFORM_REPO_DIR)" log -1 --format=%H origin/main -- "$k")"
    echo "key table merged ($k, commit $c): this is KV-0.1's evidence"
  else echo "the signed key table $k is not on origin/main: stop"; bad=1; fi
  return $bad
}

# ------------------------------------------------------------------ 1. Readiness in the three projects
kv_api_on() {   # kv_api_on PROJECT_NAME API: the API is enabled (filtered list; 10 CP-1.6 enables it, never this file)
  nonempty r gcloud services list --enabled --project="$(v "$1")" --filter="config.name=$2" --format="value(config.name)"
}

step KV-1.1 AUTO-READ "Confirm the APIs this file uses are enabled" --needs "KMS_PROJECT CICD_PROJECT VALIDATOR_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KV_1_1_check() { ckpt_done KV-1.1; }
s_KV_1_1_apply() {
  local bad=0 pa
  { for pa in KMS_PROJECT CICD_PROJECT VALIDATOR_PROJECT; do
      printf '## %s\n' "$(v "$pa")"; r gcloud services list --enabled --project="$(v "$pa")" --format="value(config.name)" | sort
    done; } | kv_keep KV-1.1 apis E-05 1.3.1 txt || kv_planok || return 1
  kv_show "then: cloudkms on KMS_PROJECT; cloudkms, binaryauthorization, containeranalysis on CICD_PROJECT; bigquery, iam on VALIDATOR_PROJECT"
  [ "$AGP_MODE" = apply ] || return 0
  for pa in KMS_PROJECT:cloudkms CICD_PROJECT:cloudkms CICD_PROJECT:binaryauthorization CICD_PROJECT:containeranalysis VALIDATOR_PROJECT:bigquery VALIDATOR_PROJECT:iam; do
    kv_api_on "${pa%%:*}" "${pa#*:}.googleapis.com" || { echo "${pa#*:}.googleapis.com is not enabled on ${pa%%:*}: stop and re-run 10 CP-1.6 for that row; never enable it here"; bad=1; }
  done
  [ $bad = 0 ] && echo "read the KMS_PROJECT list in the record: no API outside cloudkms and the defaults 10 recorded (P118)"
  return $bad
}

step KV-1.2 AUTO-READ "Prove the permissions before the first create" --needs "KMS_PROJECT CICD_PROJECT VALIDATOR_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KV_1_2_check() { ckpt_done KV-1.2; }
kv_probe() {    # kv_probe PROJECT_NAME SLUG PERM...: Resource Manager v3 projects.testIamPermissions, saved and checked
  local pn="$1" slug="$2" b out miss; shift 2
  b="$(mktemp "${TMPDIR:-/tmp}/agp-kv.XXXXXX")" || return 2
  kv_body perms "$@" > "$b"
  out="$(AGP_API_PROJECT="$(v "$pn")" api POST "https://cloudresourcemanager.googleapis.com/v3/projects/$(v "$pn"):testIamPermissions" "$b")" || { rm -f "$b"; return 1; }
  rm -f "$b"
  printf '%s\n' "$out" | kv_keep KV-1.2 "$slug" - 4.2.1 json || return 1
  [ "$AGP_MODE" = apply ] || return 0
  miss="$(printf '%s' "$out" | python3 "$AGP_HOME/lib/agp_json.py" missing "$@")"
  [ -z "$miss" ] && return 0
  echo "absent on $(v "$pn"): $miss"; return 1
}
s_KV_1_2_apply() {
  local bad=0
  kv_show "first: KV-1.1's three API facts again (an API that is off reads exactly like a missing role)"
  if [ "$AGP_MODE" = apply ]; then
    kv_api_on KMS_PROJECT cloudkms.googleapis.com || { echo "cloudkms not enabled on KMS_PROJECT: stop, close KV-1.1 first"; return 1; }
    kv_api_on CICD_PROJECT cloudkms.googleapis.com || { echo "cloudkms not enabled on CICD_PROJECT: stop, close KV-1.1 first"; return 1; }
    kv_api_on VALIDATOR_PROJECT bigquery.googleapis.com || { echo "bigquery not enabled on VALIDATOR_PROJECT: stop, close KV-1.1 first"; return 1; }
  fi
  kv_probe KMS_PROJECT kms-permissions cloudkms.keyRings.create cloudkms.cryptoKeys.create cloudkms.cryptoKeys.setIamPolicy resourcemanager.projects.setIamPolicy || bad=1
  kv_probe CICD_PROJECT cicd-permissions cloudkms.keyRings.create cloudkms.cryptoKeys.create binaryauthorization.attestors.create containeranalysis.notes.create containeranalysis.notes.setIamPolicy || bad=1
  kv_probe VALIDATOR_PROJECT validator-permissions iam.serviceAccounts.create iam.roles.create bigquery.datasets.create cloudkms.keyHandles.create || bad=1
  [ $bad = 0 ] || echo "a permission is absent: test the causes in the page's order (API not enabled, propagation, then a role); never conclude 'missing role' first"
  return $bad
}

step KV-1.3 HUMAN "Commit the expected state and open the deviation entry" --needs "KMS_PROJECT CICD_PROJECT VALIDATOR_PROJECT PLATFORM_REPO_DIR DEVIATION_REGISTER"
s_KV_1_3_check() { ckpt_done KV-1.3; }
s_KV_1_3_manual() {
  echo "WHO: platform owner writes and pushes; the second human reviews and merges the pull request (CODEOWNERS of 03)."
  echo "WHERE: the shell, ~/.platform-env sourced, in $(v PLATFORM_REPO_DIR)."
  echo "DO: run setup/11 KV-1.3's ACTION block as written: update main, read KEY_TABLE_RECORD from the KEYS row of 03's"
  echo "    tracker (never typed), branch bootstrap/11-keys,"
  echo "    write bootstrap/expected/11-keys.yaml with its here-document, commit, push -u origin bootstrap/11-keys,"
  echo "    then bd_insert the BD-11-1 row exactly as the page prints it; open the pull request on the git host."
  echo "VERIFY: merged with the second human's approval; grep -c '^| BD-11-1 |' \"\$DEVIATION_REGISTER\" prints 1, above '## Closures'."
  echo "RECORD: the merge commit id; then: agp-platform done KV-1.3"
}

# ------------------------------------------------------------------ 2. The logging key
step KV-2.1 AUTO "Create the key ring logging in europe-west1" --gate "KEYS" --irreversible \
  --needs "KMS_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "KR_LOGGING"
s_KV_2_1_check() { kv_ring_check logging europe-west1 KMS_PROJECT KR_LOGGING; }
s_KV_2_1_apply() { kv_ring logging europe-west1 KMS_PROJECT KR_LOGGING KV-2.1 kr-logging "E-05,E-06"; }

kv_logs_fields="purpose,versionTemplate.protectionLevel,versionTemplate.algorithm,rotationPeriod,destroyScheduledDuration,primary.state"
kv_logs_want="ENCRYPT_DECRYPT|HSM|GOOGLE_SYMMETRIC_ENCRYPTION|7776000s|2592000s|ENABLED"

step KV-2.2 AUTO "Create the HSM key platform-logs-europe-west1" --gate "KEYS" --irreversible \
  --needs "KMS_PROJECT KR_LOGGING BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "KEY_PLATFORM_LOGS"
s_KV_2_2_check() {
  local rc
  exists gcloud kms keys describe platform-logs-europe-west1 --keyring=logging --location=europe-west1 --project="$(v KMS_PROJECT)" --format="value(name)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  has_value KEY_PLATFORM_LOGS
}
s_KV_2_2_apply() {
  local rc nr
  kv_now exists gcloud kms keys describe platform-logs-europe-west1 --keyring=logging --location=europe-west1 --project="$(v KMS_PROJECT)" --format="value(name)"; rc=$?
  case $rc in
    0) echo "      key platform-logs-europe-west1 exists: not created again";;
    1|3) nr="$(python3 -c 'import datetime as d;print((d.datetime.now(d.timezone.utc)+d.timedelta(days=90)).strftime("%Y-%m-%dT%H:%M:%SZ"))')" || return 1
         x gcloud kms keys create platform-logs-europe-west1 --keyring=logging --location=europe-west1 --purpose=encryption --default-algorithm=google-symmetric-encryption --protection-level=hsm --rotation-period=90d --next-rotation-time="$nr" --destroy-scheduled-duration=30d --labels=class=c,owner-role=platform-owner,store=platform-logs --project="$(v KMS_PROJECT)" || return 1;;
    *) return 1;;
  esac
  pset KEY_PLATFORM_LOGS "$(v KR_LOGGING)/cryptoKeys/platform-logs-europe-west1" || return 1
  kv_read_keep KV-2.2 key-platform-logs E-06 5.1.1 yaml gcloud kms keys describe platform-logs-europe-west1 --keyring=logging --location=europe-west1 --project="$(v KMS_PROJECT)" --format="yaml(name,purpose,versionTemplate,rotationPeriod,nextRotationTime,destroyScheduledDuration,primary.state,labels)" || return 1
  kv_show "VERIFY ($kv_logs_fields): $kv_logs_want"
  [ "$AGP_MODE" = apply ] || return 0
  kv_verify "platform-logs-europe-west1 ($kv_logs_fields)" "$kv_logs_want" "$(kv_key_read KMS_PROJECT logging europe-west1 platform-logs-europe-west1 "$kv_logs_fields")" || kv_later
  return 0
}

kv_logsa() {    # the Logging service account of LOGGING_PROJECT (kmsServiceAccountId)
  kv_val gcloud logging settings describe --project="$(v LOGGING_PROJECT)" --format='value(kmsServiceAccountId)'
}

step KV-2.3 AUTO "Grant the logging service account of LOGGING_PROJECT on the key" \
  --needs "LOGGING_PROJECT KEY_PLATFORM_LOGS KMS_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KV_2_3_check() {
  local sa rc
  sa="$(kv_logsa)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  [ -n "$sa" ] || return 1
  has_binding "serviceAccount:$sa" roles/cloudkms.cryptoKeyEncrypterDecrypter gcloud kms keys get-iam-policy platform-logs-europe-west1 --keyring=logging --location=europe-west1 --project="$(v KMS_PROJECT)"
}
s_KV_2_3_apply() {
  local sa pol
  if [ "$AGP_MODE" = apply ]; then
    sa="$(kv_logsa)" || { echo "gcloud logging settings describe failed: stop"; return 1; }
    printf '      LOG_KMS_SA=%s\n' "$sa"
    [ -n "$sa" ] || { echo "kmsServiceAccountId is empty: stop"; return 1; }
    case "$sa" in *@gcp-sa-logging.iam.gserviceaccount.com) echo "      VERIFY ok: LOG_KMS_SA ends in @gcp-sa-logging.iam.gserviceaccount.com";;
      *) echo "      VERIFY FAILED: LOG_KMS_SA does not end in @gcp-sa-logging.iam.gserviceaccount.com"; kv_later;; esac
  else
    sa="<LOG_KMS_SA>"
    kv_show "LOG_KMS_SA = gcloud logging settings describe --project=$(v LOGGING_PROJECT) --format='value(kmsServiceAccountId)'"
  fi
  x gcloud kms keys add-iam-policy-binding platform-logs-europe-west1 --keyring=logging --location=europe-west1 --member="serviceAccount:${sa}" --role=roles/cloudkms.cryptoKeyEncrypterDecrypter --project="$(v KMS_PROJECT)" || return 1
  pol="$(kv_policy gcloud kms keys get-iam-policy platform-logs-europe-west1 --keyring=logging --location=europe-west1 --project="$(v KMS_PROJECT)")"
  printf '%s\n' "$pol" | kv_keep KV-2.3 key-platform-logs-iam E-06 "5.1.1,4.2.1" json || return 1
  kv_show "VERIFY: exactly one binding, roles/cloudkms.cryptoKeyEncrypterDecrypter with LOG_KMS_SA alone (09 section 2.4)"
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s' "$pol" | kv_json only roles/cloudkms.cryptoKeyEncrypterDecrypter "serviceAccount:${sa}" \
    || { echo "the key policy is not exactly one Encrypter/Decrypter binding for the Logging service account: stop (09 section 2.4)"; return 1; }
}

# ------------------------------------------------------------------ 3. The engines ring
step KV-3.1 AUTO "Create the key ring engines in europe-west1" --gate "KEYS" --irreversible \
  --needs "KMS_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "KR_ENGINES"
s_KV_3_1_check() { kv_ring_check engines europe-west1 KMS_PROJECT KR_ENGINES; }
s_KV_3_1_apply() {
  kv_ring engines europe-west1 KMS_PROJECT KR_ENGINES KV-3.1 kr-engines E-05 || return 1
  kv_show "VERIFY: the ring holds no key (17 creates each <agent>-engine-cmek)"
  [ "$AGP_MODE" = apply ] || return 0
  echo "      keys in ring engines (none until 17 creates each <agent>-engine-cmek):"
  r gcloud kms keys list --keyring=engines --location=europe-west1 --project="$(v KMS_PROJECT)" --format="value(name)" | sed 's/^/        /'
  return 0
}

# ------------------------------------------------------------------ 4. The Gemini Enterprise key
step KV-4.1 AUTO "Create the key ring gemini in the europe multi-region" --gate "KEYS" --irreversible \
  --needs "KMS_PROJECT GE_LOCATION BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "KR_GEMINI"
s_KV_4_1_check() { kv_ring_check gemini europe KMS_PROJECT KR_GEMINI; }
s_KV_4_1_apply() {
  kv_show "first (the page's ACTION): test GE_LOCATION = eu (an EU app needs a europe multi-region key, SD-21)"
  if [ "$AGP_MODE" = apply ] && [ "$(v GE_LOCATION)" != eu ]; then
    echo "GE_LOCATION is not eu: an EU app needs a europe multi-region key; stop (05, SD-21)"; return 1
  fi
  kv_ring gemini europe KMS_PROJECT KR_GEMINI KV-4.1 kr-gemini E-05
}

kv_gem_fields="purpose,versionTemplate.protectionLevel,versionTemplate.algorithm,rotationPeriod,nextRotationTime,primary.state"
kv_gem_want="ENCRYPT_DECRYPT|HSM|GOOGLE_SYMMETRIC_ENCRYPTION|||ENABLED"

step KV-4.2 AUTO "Create the HSM key gemini-cmek, manual rotation" --gate "KEYS" --irreversible \
  --needs "KMS_PROJECT KR_GEMINI BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "KEY_GEMINI_CMEK"
s_KV_4_2_check() {
  local rc
  exists gcloud kms keys describe gemini-cmek --keyring=gemini --location=europe --project="$(v KMS_PROJECT)" --format="value(name)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  has_value KEY_GEMINI_CMEK
}
s_KV_4_2_apply() {
  local rc
  kv_now exists gcloud kms keys describe gemini-cmek --keyring=gemini --location=europe --project="$(v KMS_PROJECT)" --format="value(name)"; rc=$?
  case $rc in
    0) echo "      key gemini-cmek exists: not created again";;
    1|3) x gcloud kms keys create gemini-cmek --keyring=gemini --location=europe --purpose=encryption --default-algorithm=google-symmetric-encryption --protection-level=hsm --destroy-scheduled-duration=30d --labels=class=c,owner-role=platform-owner,registrar-role=ge-admin,store=gemini-enterprise --project="$(v KMS_PROJECT)" || return 1;;
    *) return 1;;
  esac
  pset KEY_GEMINI_CMEK "$(v KR_GEMINI)/cryptoKeys/gemini-cmek" || return 1
  kv_read_keep KV-4.2 key-gemini-cmek E-05 5.1.1 json gcloud kms keys describe gemini-cmek --keyring=gemini --location=europe --project="$(v KMS_PROJECT)" --format=json || return 1
  kv_show "VERIFY ($kv_gem_fields): $kv_gem_want (no rotation period: Google requires manual rotation)"
  [ "$AGP_MODE" = apply ] || return 0
  kv_verify "gemini-cmek ($kv_gem_fields)" "$kv_gem_want" "$(kv_key_read KMS_PROJECT gemini europe gemini-cmek "$kv_gem_fields")" || kv_later
  return 0
}

step KV-4.3 AUTO "Grant the two Gemini Enterprise service agents on the key" \
  --needs "GEMINI_PROJECT GEMINI_PROJECT_NUMBER KEY_GEMINI_CMEK KMS_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
kv_ge_agents() {
  printf 'service-%s@gcp-sa-discoveryengine.iam.gserviceaccount.com service-%s@gs-project-accounts.iam.gserviceaccount.com' "$(v GEMINI_PROJECT_NUMBER)" "$(v GEMINI_PROJECT_NUMBER)"
}
s_KV_4_3_check() {
  local sa rc
  for sa in $(kv_ge_agents); do
    has_binding "serviceAccount:$sa" roles/cloudkms.cryptoKeyEncrypterDecrypter gcloud kms keys get-iam-policy gemini-cmek --keyring=gemini --location=europe --project="$(v KMS_PROJECT)"; rc=$?
    [ $rc -eq 0 ] && continue
    [ $rc -eq 1 ] && kv_rerun_has KV-4.3 "serviceAccount:$sa" && continue
    return $rc
  done
}
s_KV_4_3_apply() {
  local sa pol bad=0
  for sa in $(kv_ge_agents); do
    if [ "$AGP_MODE" = apply ] && has_binding "serviceAccount:$sa" roles/cloudkms.cryptoKeyEncrypterDecrypter gcloud kms keys get-iam-policy gemini-cmek --keyring=gemini --location=europe --project="$(v KMS_PROJECT)"; then continue; fi
    x gcloud kms keys add-iam-policy-binding gemini-cmek --keyring=gemini --location=europe --member="serviceAccount:${sa}" --role=roles/cloudkms.cryptoKeyEncrypterDecrypter --project="$(v KMS_PROJECT)" \
      || x kv_pending "serviceAccount:${sa}" KV-4.3 "11 KV-4.3 encrypterDecrypter on gemini-cmek (after 19)" || bad=1
  done
  kv_show "if a binding is refused (the agent does not exist yet): kv_pending, which is 01's exists_or_pending --pending (a PENDING line against 19)"
  [ $bad = 0 ] || return 1
  pol="$(kv_policy gcloud kms keys get-iam-policy gemini-cmek --keyring=gemini --location=europe --project="$(v KMS_PROJECT)")"
  printf '%s\n' "$pol" | kv_keep KV-4.3 key-gemini-iam E-05 "5.1.1,4.2.1" json || return 1
  kv_show "VERIFY: one Encrypter/Decrypter binding holding the two agents (or one plus a PENDING line); no other role or member"
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s' "$pol" | kv_json only-role roles/cloudkms.cryptoKeyEncrypterDecrypter || { echo "a role other than Encrypter/Decrypter is bound on gemini-cmek: stop"; return 1; }
  for sa in $(printf '%s' "$pol" | kv_json role-members roles/cloudkms.cryptoKeyEncrypterDecrypter); do
    case " $(kv_ge_agents | sed 's/[^ ]*/serviceAccount:&/g') " in *" $sa "*) ;; *) echo "unexpected member $sa on gemini-cmek: stop"; return 1;; esac
  done
  echo "      the three third-party connector keys are not created (03 section 12: first-party sources only)"
}

step KV-4.4 CONSOLE "Check the HSM quota headroom for europe" --needs "KMS_PROJECT EVIDENCE_INTERIM_LOCATION BUILD_LOG_DIR"
s_KV_4_4_check() { ckpt_done KV-4.4; }
s_KV_4_4_manual() {
  echo "WHO: platform owner, as sa-1-admin@ in the clean browser profile."
  echo "WHERE: Cloud console, project $(v KMS_PROJECT): IAM & Admin > Quotas & System Limits; filter Service ="
  echo "       'Cloud Key Management Service (KMS) API', then Metric = 'HSM symmetric cryptographic requests'."
  echo "DO: read the row whose Dimension is region: europe (or the default row) and note the limit, the current usage and"
  echo "    the dimension; take a screenshot of the filtered page. Headroom must leave at least 1,000 QPM for file 19."
  echo "RECORD: <date>-KV-4.4-hsm-quota-v1.png in $(v EVIDENCE_INTERIM_LOCATION); the three values, page URL and read time in"
  echo "        $(v BUILD_LOG_DIR)/records/<date>-KV-4.4-hsm-quota-v1.txt; book the re-checks in 19 and 42 (DRILL_CALENDAR)."
  echo "No gcloud path here: cloudquotas is not on KMS_PROJECT (P118). The optional shell path needs BD-11-2 (page KV-4.4)."
  echo "Then: agp-platform done KV-4.4"
}

# ------------------------------------------------------------------ 5. Binary Authorization in CICD_PROJECT
step KV-5.1 AUTO "Create the key ring supply-chain in europe-west1" --gate "KEYS" --irreversible \
  --needs "CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "KR_SUPPLY_CHAIN"
s_KV_5_1_check() { kv_ring_check supply-chain europe-west1 CICD_PROJECT KR_SUPPLY_CHAIN; }
s_KV_5_1_apply() { kv_ring supply-chain europe-west1 CICD_PROJECT KR_SUPPLY_CHAIN KV-5.1 kr-supply-chain E-05; }

kv_versions() {  # kv_versions KEY: the versions of an attestor key, one "name|state|protection|algorithm" line each
  r gcloud kms keys versions list --key="$1" --keyring=supply-chain --location=europe-west1 --project="$(v CICD_PROJECT)" --format="value(name,state,protectionLevel,algorithm)" | tr '\t' '|'
}
kv_versions_ok() {  # kv_versions_ok KEY: exactly one version, .../cryptoKeyVersions/1 ENABLED HSM EC_SIGN_P256_SHA256
  local out; out="$(kv_versions "$1")"
  case "$out" in */cryptoKeyVersions/1'|ENABLED|HSM|EC_SIGN_P256_SHA256') [ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = 1 ] && return 0;; esac
  echo "      VERIFY FAILED: $1 versions: expected one .../cryptoKeyVersions/1|ENABLED|HSM|EC_SIGN_P256_SHA256, read [$(printf '%s' "$out" | tr '\n' ' ')]"
  return 1
}

step KV-5.2 AUTO "Create the two attestor signing keys" --gate "KEYS" --irreversible \
  --needs "CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "KEY_BINAUTHZ KEY_BINAUTHZ_PROMOTED"
s_KV_5_2_check() {
  local k rc
  for k in binauthz-vuln-gated binauthz-promoted; do
    exists gcloud kms keys describe "$k" --keyring=supply-chain --location=europe-west1 --project="$(v CICD_PROJECT)" --format="value(name)"; rc=$?
    [ $rc -eq 0 ] || return $rc
  done
  has_value KEY_BINAUTHZ && has_value KEY_BINAUTHZ_PROMOTED
}
s_KV_5_2_apply() {
  local k att rc p
  p="$(v CICD_PROJECT)"
  for k in binauthz-vuln-gated:vuln-gated binauthz-promoted:promoted-to-prod; do
    att="${k#*:}"; k="${k%%:*}"
    kv_now exists gcloud kms keys describe "$k" --keyring=supply-chain --location=europe-west1 --project="$p" --format="value(name)"; rc=$?
    case $rc in
      0) echo "      key $k exists: not created again";;
      1|3) x gcloud kms keys create "$k" --keyring=supply-chain --location=europe-west1 --purpose=asymmetric-signing --default-algorithm=ec-sign-p256-sha256 --protection-level=hsm --destroy-scheduled-duration=30d --labels="class=b,owner-role=platform-owner,attestor=${att}" --project="$p" || return 1;;
      *) return 1;;
    esac
  done
  pset KEY_BINAUTHZ "projects/${p}/locations/europe-west1/keyRings/supply-chain/cryptoKeys/binauthz-vuln-gated/cryptoKeyVersions/1" || return 1
  pset KEY_BINAUTHZ_PROMOTED "projects/${p}/locations/europe-west1/keyRings/supply-chain/cryptoKeys/binauthz-promoted/cryptoKeyVersions/1" || return 1
  { for k in binauthz-vuln-gated binauthz-promoted; do kv_versions "$k"; done; } | kv_keep KV-5.2 attestor-keys E-05 5.1.1 txt || kv_planok || return 1
  kv_show "VERIFY: each key shows one version, .../cryptoKeyVersions/1 ENABLED HSM EC_SIGN_P256_SHA256"
  [ "$AGP_MODE" = apply ] || return 0
  for k in binauthz-vuln-gated binauthz-promoted; do kv_versions_ok "$k" && echo "      VERIFY ok: $k" || kv_later; done
  return 0
}

kv_note_url() { printf 'https://containeranalysis.googleapis.com/v1/projects/%s/notes/%s' "$(v CICD_PROJECT)" "$1"; }
kv_note_getpol() {   # kv_note_getpol NOTE_URL: notes.getIamPolicy, sent with an empty GetIamPolicyRequest ({})
  # A POST with no body carries no Content-Length, which the front end may refuse over HTTP/1.1 (411).
  local gb rc
  gb="$(mktemp "${TMPDIR:-/tmp}/agp-kv.XXXXXX")" || return 2
  printf '{}' > "$gb"
  AGP_API_PROJECT="$(v CICD_PROJECT)" api POST "$1:getIamPolicy" "$gb"; rc=$?
  rm -f "$gb"
  return $rc
}
kv_ba_sa() { printf 'serviceAccount:service-%s@gcp-sa-binaryauthorization.iam.gserviceaccount.com' "$(v CICD_PROJECT_NUMBER)"; }
kv_note_ok() {   # kv_note_ok N: the KV-5.3 read-back of N-note is exactly one occurrences.viewer binding for the agent
  local pf; pf="$(kv_latest "KV-5.3-$1-note-policy-v1.json")" || { echo "      VERIFY FAILED: no KV-5.3 read-back policy for $1-note (KV-5.5's rollback needs it)"; return 1; }
  kv_json only roles/containeranalysis.notes.occurrences.viewer "$(kv_ba_sa)" < "$pf" && return 0
  echo "      VERIFY FAILED: $pf is not exactly one occurrences.viewer binding for the Binary Authorization agent"; return 1
}

step KV-5.3 AUTO "Create the two Artifact Analysis notes and let the attestor project's agent read them" --removes \
  --needs "CICD_PROJECT CICD_PROJECT_NUMBER BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KV_5_3_check() {
  local n rc
  for n in vuln-gated promoted-to-prod; do
    AGP_API_PROJECT="$(v CICD_PROJECT)" api GET "$(kv_note_url "${n}-note")" >/dev/null; rc=$?
    [ $rc -eq 0 ] || return $rc
    kv_latest "KV-5.3-${n}-note-policy-v1.json" >/dev/null || return 1
  done
}
s_KV_5_3_apply() {
  local n ba nb ib pf cur rc nbj ibj
  ba="$(kv_ba_sa)"
  for n in vuln-gated promoted-to-prod; do
    nb="$(kv_rec "KV-5.3-${n}-note-body-v1.json")"; ib="$(kv_rec "KV-5.3-${n}-note-setiam-body-v1.json")"; pf="$(kv_rec "KV-5.3-${n}-note-policy-v1.json")"
    nbj="$(kv_body note "projects/$(v CICD_PROJECT)/notes/${n}-note" "${n} attestation authority (09 section 1.4)")" || return 1
    ibj="$(kv_body note-iam "projects/$(v CICD_PROJECT)/notes/${n}-note" "$ba")" || return 1
    printf '%s\n' "$nbj" | xw "$nb" || return 1
    kv_show "    $nbj"
    printf '%s\n' "$ibj" | xw "$ib" || return 1
    kv_show "    $ibj"
    rc=1; [ "$AGP_MODE" = apply ] && { AGP_API_PROJECT="$(v CICD_PROJECT)" kv_now api GET "$(kv_note_url "${n}-note")" >/dev/null; rc=$?; }
    case $rc in
      0) echo "      note ${n}-note exists: not created again";;
      1) AGP_API_PROJECT="$(v CICD_PROJECT)" api POST "https://containeranalysis.googleapis.com/v1/projects/$(v CICD_PROJECT)/notes/?noteId=${n}-note" "$nb" >/dev/null || return 1;;
      *) return 1;;
    esac
    if [ "$AGP_MODE" = apply ]; then   # never overwrite a note policy that already holds other bindings (KV-5.5 adds one)
      cur="$(kv_note_getpol "$(kv_note_url "${n}-note")")" || return 1
      if printf '%s' "$cur" | kv_json has roles/containeranalysis.notes.occurrences.viewer "$ba"; then
        echo "      ${n}-note already lets the Binary Authorization agent read it"
      elif [ "$(printf '%s' "$cur" | kv_json count)" != 0 ]; then
        echo "${n}-note already has an IAM policy without the viewer binding: stop and read it; this step does not overwrite it"; return 1
      else AGP_API_PROJECT="$(v CICD_PROJECT)" api POST "$(kv_note_url "${n}-note"):setIamPolicy" "$ib" >/dev/null || return 1; fi
    else
      kv_show "(the setIamPolicy is sent only when the note's policy is empty; a policy with other bindings stops the step)"
      AGP_API_PROJECT="$(v CICD_PROJECT)" api POST "$(kv_note_url "${n}-note"):setIamPolicy" "$ib" >/dev/null
    fi
    kv_note_getpol "$(kv_note_url "${n}-note")" | xw "$pf" || return 1
  done
  ev KV-5.3 notes E-05 5.3.1 "build-log:records/$(kv_today)-KV-5.3-(six note files)" || return 1
  kv_show "VERIFY: each read-back policy is exactly one occurrences.viewer binding for $ba"
  [ "$AGP_MODE" = apply ] || return 0
  for n in vuln-gated promoted-to-prod; do
    [ -s "$(kv_rec "KV-5.3-${n}-note-policy-v1.json")" ] || { echo "KV-5.5 has no policy to roll back to: stop and re-read the policy"; return 1; }
    kv_note_ok "$n" && echo "      VERIFY ok: ${n}-note" || kv_later
  done
  return 0
}

step KV-5.4 AUTO "Create the attestors and add their KMS public keys" \
  --needs "CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "BINAUTHZ_ATTESTOR BINAUTHZ_ATTESTOR_PROMOTED"
kv_attestor_key() {   # kv_attestor_key ATTESTOR: 0 it holds a public key, 1 it holds none (or is absent), 2 error, 3 offline
  local out rc
  out="$(kv_val gcloud container binauthz attestors describe "$1" --project="$(v CICD_PROJECT)" --format="value(userOwnedGrafeasNote.publicKeys[].id)")"; rc=$?
  [ $rc -eq 0 ] || return $rc
  [ -n "$out" ]
}
s_KV_5_4_check() {
  local a rc
  for a in vuln-gated promoted-to-prod; do
    exists gcloud container binauthz attestors describe "$a" --project="$(v CICD_PROJECT)" --format="value(name)"; rc=$?
    [ $rc -eq 0 ] || return $rc
    kv_attestor_key "$a"; rc=$?
    [ $rc -eq 0 ] || return $rc
  done
  has_value BINAUTHZ_ATTESTOR && has_value BINAUTHZ_ATTESTOR_PROMOTED
}
s_KV_5_4_apply() {
  local a k d rc p
  p="$(v CICD_PROJECT)"
  for a in "vuln-gated:binauthz-vuln-gated:In-build scan passed: no CRITICAL (09 section 1.4)" "promoted-to-prod:binauthz-promoted:Release promoted to prod (09 section 1.5)"; do
    d="${a#*:*:}"; k="${a#*:}"; k="${k%%:*}"; a="${a%%:*}"
    kv_now exists gcloud container binauthz attestors describe "$a" --project="$p" --format="value(name)"; rc=$?
    case $rc in
      0) echo "      attestor $a exists: not created again";;
      1|3) x gcloud container binauthz attestors create "$a" --attestation-authority-note="${a}-note" --attestation-authority-note-project="$p" --description="$d" --project="$p" || return 1;;
      *) return 1;;
    esac
    rc=1; [ "$AGP_MODE" = apply ] && { kv_now kv_attestor_key "$a"; rc=$?; }
    case $rc in
      0) echo "      attestor $a already holds a public key: not added again";;
      1) x gcloud container binauthz attestors public-keys add --attestor="$a" --keyversion-project="$p" --keyversion-location=europe-west1 --keyversion-keyring=supply-chain --keyversion-key="$k" --keyversion=1 --project="$p" || return 1;;
      *) return 1;;
    esac
  done
  pset BINAUTHZ_ATTESTOR "projects/${p}/attestors/vuln-gated" || return 1
  pset BINAUTHZ_ATTESTOR_PROMOTED "projects/${p}/attestors/promoted-to-prod" || return 1
  kv_read_keep KV-5.4 attestors "E-05,E-15" "5.3.1,5.2.3" txt gcloud container binauthz attestors list --project="$p" --format="table(name,userOwnedGrafeasNote.noteReference,userOwnedGrafeasNote.publicKeys[].id)" || return 1
  kv_show "VERIFY: two attestors, each with one public key, the //cloudkms.googleapis.com/v1/.../cryptoKeyVersions/1 path of its own key"
  return 0
}

step KV-5.5 AUTO "Grant signing on each key to its one signer" --removes \
  --needs "SA_CI_BUILD CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KV_5_5_check() {
  local rc
  has_binding "serviceAccount:$(v SA_CI_BUILD)" roles/cloudkms.signer gcloud kms keys get-iam-policy binauthz-vuln-gated --keyring=supply-chain --location=europe-west1 --project="$(v CICD_PROJECT)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  has_binding "serviceAccount:$(v SA_CI_BUILD)" roles/containeranalysis.occurrences.editor gcloud projects get-iam-policy "$(v CICD_PROJECT)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  kv_latest KV-5.5-vuln-gated-note-after.json >/dev/null || return 1
  kv_rerun_has KV-5.5 "serviceAccount:release account named in 17"
}
kv_note55_ok() {   # the KV-5.5 before/after diff: SA_CI_BUILD added on notes.attacher, nothing else, one attacher binding
  local bf af
  bf="$(kv_latest KV-5.5-vuln-gated-note-before.json)" && af="$(kv_latest KV-5.5-vuln-gated-note-after.json)" \
    || { echo "      VERIFY FAILED: the KV-5.5 -before.json or -after.json of vuln-gated-note is missing"; return 1; }
  kv_json note-diff "$bf" "$af" roles/containeranalysis.notes.attacher "serviceAccount:$(v SA_CI_BUILD)" && return 0
  echo "      VERIFY FAILED: vuln-gated-note changed by more than SA_CI_BUILD on notes.attacher, or holds two attacher bindings:"
  echo "      a concurrent edit? restore $bf as the page's KV-5.5 ROLLBACK shows, then repeat"
  return 1
}
s_KV_5_5_apply() {
  local p sa note bf body af pol
  p="$(v CICD_PROJECT)"; sa="serviceAccount:$(v SA_CI_BUILD)"; note="projects/${p}/notes/vuln-gated-note"
  bf="$(kv_rec KV-5.5-vuln-gated-note-before.json)"; body="$(kv_rec KV-5.5-vuln-gated-note-setiam-body-v1.json)"; af="$(kv_rec KV-5.5-vuln-gated-note-after.json)"
  x gcloud kms keys add-iam-policy-binding binauthz-vuln-gated --keyring=supply-chain --location=europe-west1 --member="$sa" --role=roles/cloudkms.signer --project="$p" || return 1
  kv_note_getpol "https://containeranalysis.googleapis.com/v1/${note}" | xw "$bf" || return 1
  if [ "$AGP_MODE" = apply ]; then
    kv_json note-merge "$note" "$sa" roles/containeranalysis.notes.attacher < "$bf" | xw "$body" || return 1
  else
    printf '{"resource": "%s", "policy": "<the -before.json policy, %s added to roles/containeranalysis.notes.attacher>"}\n' "$note" "$sa" | xw "$body"
    kv_show "    the -before.json policy (etag kept), $sa added to the existing notes.attacher binding, or one binding appended"
  fi
  AGP_API_PROJECT="$p" api POST "https://containeranalysis.googleapis.com/v1/${note}:setIamPolicy" "$body" >/dev/null || return 1
  kv_note_getpol "https://containeranalysis.googleapis.com/v1/${note}" | xw "$af" || return 1
  x gcloud projects add-iam-policy-binding "$p" --member="$sa" --role=roles/containeranalysis.occurrences.editor --condition=None || return 1
  if ! kv_rerun_has KV-5.5 "serviceAccount:release account named in 17"; then
    x kv_pending "serviceAccount:release account named in 17" KV-5.5 "11 KV-5.5 signer on binauthz-promoted, attacher on promoted-to-prod-note (after 17)" || return 1
  fi
  kv_show "(kv_pending is 01's exists_or_pending --pending: one PENDING line in $(v BUILD_LOG_DIR)/rerun-index.tsv, against 17)"
  { kv_policy gcloud kms keys get-iam-policy binauthz-vuln-gated --keyring=supply-chain --location=europe-west1 --project="$p"
    echo; kv_policy gcloud kms keys get-iam-policy binauthz-promoted --keyring=supply-chain --location=europe-west1 --project="$p"; } \
    | kv_keep KV-5.5 signers E-15 "5.3.1,1.2.2" txt || kv_planok || return 1
  kv_show "VERIFY: binauthz-vuln-gated one signer binding for SA_CI_BUILD; binauthz-promoted no binding; the note diff adds SA_CI_BUILD only"
  [ "$AGP_MODE" = apply ] || return 0
  pol="$(kv_policy gcloud kms keys get-iam-policy binauthz-vuln-gated --keyring=supply-chain --location=europe-west1 --project="$p")"
  printf '%s' "$pol" | kv_json only roles/cloudkms.signer "$sa" || { echo "binauthz-vuln-gated is not exactly one signer binding for SA_CI_BUILD: stop"; return 1; }
  pol="$(kv_policy gcloud kms keys get-iam-policy binauthz-promoted --keyring=supply-chain --location=europe-west1 --project="$p")"
  [ "$(printf '%s' "$pol" | kv_json count)" = 0 ] || { echo "binauthz-promoted has a binding before the release account exists: stop"; return 1; }
  kv_note55_ok && echo "      VERIFY ok: vuln-gated-note gained SA_CI_BUILD on notes.attacher only" || kv_later
  return 0
}

# ------------------------------------------------------------------ 6. Autokey with KMS_PROJECT as key project
step KV-6.1 AUTO "Let the Cloud KMS service agent of KMS_PROJECT administer its keys" \
  --needs "KMS_PROJECT KMS_PROJECT_NUMBER BUILD_LOG_DIR EVIDENCE_REGISTER"
kv_kms_agent() { printf 'serviceAccount:service-%s@gcp-sa-cloudkms.iam.gserviceaccount.com' "$(v KMS_PROJECT_NUMBER)"; }
s_KV_6_1_check() { has_binding "$(kv_kms_agent)" roles/cloudkms.admin gcloud projects get-iam-policy "$(v KMS_PROJECT_NUMBER)"; }
s_KV_6_1_apply() {
  local pol
  x gcloud beta services identity create --service=cloudkms.googleapis.com --project="$(v KMS_PROJECT_NUMBER)" || return 1
  x gcloud projects add-iam-policy-binding "$(v KMS_PROJECT_NUMBER)" --role=roles/cloudkms.admin --member="$(kv_kms_agent)" --condition=None || return 1
  pol="$(kv_policy gcloud projects get-iam-policy "$(v KMS_PROJECT_NUMBER)")"
  printf '%s' "$pol" | kv_json role-members roles/cloudkms.admin | kv_keep KV-6.1 kms-agent - "4.2.1,5.1.1" txt || return 1
  kv_show "VERIFY: the KMS service agent is the only member of roles/cloudkms.admin on KMS_PROJECT (a human member fails the step)"
  [ "$AGP_MODE" = apply ] || return 0
  [ "$(printf '%s' "$pol" | kv_json role-members roles/cloudkms.admin)" = "$(kv_kms_agent)" ] \
    || { echo "roles/cloudkms.admin on KMS_PROJECT has a member other than the KMS service agent: stop"; return 1; }
}

kv_bd3_open() {     # BD-11-3 is a row of the first table with no closure line
  [ -f "$(v DEVIATION_REGISTER)" ] || return 1
  awk -F' *[|] *' '$2 == "BD-11-3" && NF == 15 {o=1} $2 == "BD-11-3" && NF == 6 {c=1} END {exit (o && !c) ? 0 : 1}' "$(v DEVIATION_REGISTER)"
}
kv_bd3_until() {    # the expiry KV-6.2 wrote in the BD-11-3 row ("... until <time>"), or nothing
  [ -f "$(v DEVIATION_REGISTER)" ] || return 1
  awk -F' *[|] *' '$2 == "BD-11-3" && NF == 15' "$(v DEVIATION_REGISTER)" \
    | sed -n 's/.*kv-6-2-autokey-bootstrap until \([0-9T:-]*Z\).*/\1/p' | tail -n 1
}
kv_bd3_row() {   # the BD-11-3 row, in 01 PR-4.1's thirteen columns
  printf '| BD-11-3 | %s | 11 KV-6.2 | DEV | time-bound roles/cloudkms.autokeyAdmin to the platform owner instead of PAM (no entitlement before 12) | folders %s | KV-1.2 probe | user:%s roles/cloudkms.autokeyAdmin, condition kv-6-2-autokey-bootstrap until %s | KV-6.4 zero-count check | n/a | none: SD-01 bootstrap exception | removed in KV-6.4 | open |' \
    "$(kv_today)" "$1" "$(v SA_1_ADMIN)" "$2"
}

step KV-6.2 AUTO "Give sa-1-admin@ a four-hour Autokey Admin binding on the five folders" \
  --needs "FLD_PLATFORM_CORE FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS FLD_IMPROVERS SA_1_ADMIN KMS_PROJECT BUILD_LOG_DIR DEVIATION_REGISTER EVIDENCE_REGISTER"
s_KV_6_2_check() {   # done while the four-hour grant is live on all five folders, or once Autokey is configured
  # The grant is read first: it is what this step makes. Autokey configured (KV-6.3's check) means the
  # time-bound grant has done its work and KV-6.4 has removed it.
  local f fs pol live=0 held=0 until
  [ "$AGP_OFFLINE" = 1 ] && return 3
  fs="$(kv_ak_folders)"; kv_ak_five "$fs" || return 2
  for f in $fs; do
    pol="$(kv_policy gcloud resource-manager folders get-iam-policy "$f")" || return 2
    printf '%s' "$pol" | kv_json ak-live "user:$(v SA_1_ADMIN)" && live=$((live + 1))
    printf '%s' "$pol" | kv_json has roles/cloudkms.autokeyAdmin "user:$(v SA_1_ADMIN)" && held=$((held + 1))
  done
  [ $live -eq 5 ] && return 0
  # the expiry recorded in the open BD-11-3 row, for a policy read that does not return the condition
  until="$(kv_bd3_until)"
  [ $held -eq 5 ] && [ -n "$until" ] && [ "$until" \> "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ] && kv_bd3_open && return 0
  s_KV_6_3_check
}
s_KV_6_2_apply() {
  local fs f exp shape
  fs="$(kv_ak_folders)"; kv_ak_five "$fs" || return 1
  exp="$(python3 -c 'import datetime as d;print((d.datetime.now(d.timezone.utc)+d.timedelta(hours=4)).strftime("%Y-%m-%dT%H:%M:%SZ"))')" || return 1
  for f in $fs; do
    x gcloud resource-manager folders add-iam-policy-binding "$f" --member="user:$(v SA_1_ADMIN)" --role=roles/cloudkms.autokeyAdmin --condition="expression=request.time < timestamp('${exp}'),title=kv-6-2-autokey-bootstrap,description=KV-6.2 bootstrap exception" || return 1
  done
  x bd_insert "$(kv_bd3_row "$fs" "$exp")" || return 1
  { for f in $fs; do printf '## folders/%s\n' "$f"; kv_policy gcloud resource-manager folders get-iam-policy "$f"; echo; done; } \
    | kv_keep KV-6.2 autokey-admin - "4.1.3,4.2.1" txt || kv_planok || return 1
  kv_show "VERIFY: on each folder one conditional kv-6-2-autokey-bootstrap binding with the expiry; no unconditional autokeyAdmin binding"
  [ "$AGP_MODE" = apply ] || return 0
  for f in $fs; do
    shape="$(kv_policy gcloud resource-manager folders get-iam-policy "$f" | kv_json ak-shape "user:$(v SA_1_ADMIN)")"
    kv_verify "folders/$f roles/cloudkms.autokeyAdmin" "kv-6-2=1 unconditional=0" "$shape" \
      || echo "      an unconditional binding was not made here: record it and report it to the second human; KV-6.4 and KV-9.1 count it"
  done
  return 0
}

step KV-6.3 AUTO "Configure Autokey on each folder" \
  --needs "FLD_PLATFORM_CORE FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS FLD_IMPROVERS FLD_AGENTS_R KMS_PROJECT VALIDATOR_PROJECT LOGGING_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
kv_ak_kp() {    # kv_ak_kp FOLDER: the folder's Autokey key project, as describe prints it
  kv_val gcloud kms autokey-config describe --folder="$1" --billing-project="$(v KMS_PROJECT)" --format="value(keyProject)"
}
s_KV_6_3_check() {   # configured: each of the five folders names a key project (KV-9.1 asserts that it is KMS_PROJECT)
  # reads all five folders before deciding, and keeps the worst status: 2 (cannot tell) over 1 (not done) over 0
  local fs f kp rc worst=0
  fs="$(kv_ak_folders)"; kv_ak_five "$fs" || return 2
  for f in $fs; do
    kp="$(kv_ak_kp "$f")"; rc=$?
    [ $rc -eq 3 ] && return 3
    if [ $rc -eq 0 ] && [ -z "$kp" ]; then rc=1; fi
    [ $rc -gt 2 ] && rc=2
    [ $rc -gt $worst ] && worst=$rc
  done
  return $worst
}
kv_ak_verify() {    # the page's KV-6.3 VERIFY; prints each line; 0 when all hold
  local fs f n=0 bad=0 kp
  fs="$(kv_ak_folders)"
  for f in $fs; do
    kp="$(r gcloud kms autokey-config describe --folder="$f" --billing-project="$(v KMS_PROJECT)" --format="value(keyProject)")"
    [ "$kp" = "projects/$(v KMS_PROJECT)" ] && n=$((n + 1))
  done
  kv_verify "folders naming projects/$(v KMS_PROJECT) as Autokey key project" 5 "$n" || bad=1
  for f in VALIDATOR_PROJECT LOGGING_PROJECT; do
    if r gcloud kms autokey-config show-effective-config --project="$(v "$f")" --billing-project="$(v KMS_PROJECT)" | grep -q "projects/$(v KMS_PROJECT)\$"; then
      echo "      VERIFY ok: the effective Autokey configuration of $f names KMS_PROJECT"
    else echo "      VERIFY FAILED: the effective Autokey configuration of $f does not name KMS_PROJECT"; bad=1; fi
  done
  kp="$(r gcloud kms autokey-config describe --folder="$(v FLD_AGENTS_R)" --billing-project="$(v KMS_PROJECT)" --format="value(keyProject)")"
  kv_verify "fld-agents-r has no Autokey key project" "" "$kp" || bad=1
  return $bad
}
s_KV_6_3_apply() {
  local fs f cf
  fs="$(kv_ak_folders)"; kv_ak_five "$fs" || return 1
  for f in $fs; do
    cf="$(kv_rec "KV-6.3-autokey-config-folder-${f}.yaml")"
    printf 'name: folders/%s/autokeyConfig\nkeyProjectResolutionMode: DEDICATED_KEY_PROJECT\nkeyProject: projects/%s\n' "$f" "$(v KMS_PROJECT)" | xw "$cf" 600 || return 1
    kv_show "    name: folders/$f/autokeyConfig, keyProjectResolutionMode: DEDICATED_KEY_PROJECT, keyProject: projects/$(v KMS_PROJECT)"
    x gcloud kms autokey-config update "$cf" --billing-project="$(v KMS_PROJECT)" || return 1
  done
  { for f in $fs; do r gcloud kms autokey-config describe --folder="$f" --billing-project="$(v KMS_PROJECT)" --format="yaml(name,keyProject,keyProjectResolutionMode,state)"; done
    r gcloud kms autokey-config show-effective-config --project="$(v VALIDATOR_PROJECT)" --billing-project="$(v KMS_PROJECT)"
    r gcloud kms autokey-config show-effective-config --project="$(v LOGGING_PROJECT)" --billing-project="$(v KMS_PROJECT)"
    r gcloud kms autokey-config describe --folder="$(v FLD_AGENTS_R)" --billing-project="$(v KMS_PROJECT)" --format="yaml(name,keyProject,keyProjectResolutionMode,state)"
  } | kv_keep KV-6.3 autokey-config E-05 5.1.1 txt || kv_planok || return 1
  kv_show "VERIFY: exactly five folders name projects/$(v KMS_PROJECT); the effective configuration of VALIDATOR_PROJECT and LOGGING_PROJECT names it; fld-agents-r has none"
  [ "$AGP_MODE" = apply ] || return 0
  kv_ak_verify || kv_later
  return 0
}

kv_ak_counts() {    # one "<folder> <count>" line per folder: every autokeyAdmin binding left, whoever made it
  local f pol
  for f in $1; do
    pol="$(kv_policy gcloud resource-manager folders get-iam-policy "$f")" || return 2
    printf '%s %s\n' "$f" "$(printf '%s' "$pol" | kv_json count-role roles/cloudkms.autokeyAdmin)"
  done
}
kv_ak_mine() {      # kv_ak_mine FOLDER: the number of KV-6.2 (kv-6-2-autokey-bootstrap) bindings of SA_1_ADMIN left
  local pol
  pol="$(kv_policy gcloud resource-manager folders get-iam-policy "$1")" || return 2
  printf '%s' "$pol" | kv_json ak-conds "user:$(v SA_1_ADMIN)" | wc -l | tr -d ' '
}

step KV-6.4 AUTO "Remove the Autokey Admin bindings" --removes \
  --needs "FLD_PLATFORM_CORE FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS FLD_IMPROVERS SA_1_ADMIN KMS_PROJECT BUILD_LOG_DIR DEVIATION_REGISTER EVIDENCE_REGISTER"
s_KV_6_4_check() {   # done: Autokey configured, no KV-6.2 binding left on the five folders, BD-11-3 not open
  local fs f n rc
  [ "$AGP_OFFLINE" = 1 ] && return 3
  s_KV_6_3_check; rc=$?
  [ $rc -eq 0 ] || return $rc      # nothing to remove before Autokey is configured
  fs="$(kv_ak_folders)"; kv_ak_five "$fs" || return 2
  for f in $fs; do
    n="$(kv_ak_mine "$f")" || return 2
    [ "$n" = 0 ] || return 1
  done
  kv_bd3_open && return 1
  return 0
}
s_KV_6_4_apply() {
  local fs f c cf out i=0 n left=0
  fs="$(kv_ak_folders)"; kv_ak_five "$fs" || { echo "stop, the removal would be silently partial"; return 1; }
  for f in $fs; do
    if [ "$AGP_MODE" = apply ]; then
      for c in $(kv_policy gcloud resource-manager folders get-iam-policy "$f" | kv_json ak-conds "user:$(v SA_1_ADMIN)" | tr ' ' '\001'); do
        i=$((i + 1)); cf="$(kv_rec "KV-6.4-condition-${f}-${i}.json")"
        printf '%s\n' "$c" | tr '\001' ' ' | xw "$cf" 600 || return 1
        x gcloud resource-manager folders remove-iam-policy-binding "$f" --member="user:$(v SA_1_ADMIN)" --role=roles/cloudkms.autokeyAdmin --condition-from-file="$cf" || return 1
      done
    else
      x gcloud resource-manager folders remove-iam-policy-binding "$f" --member="user:$(v SA_1_ADMIN)" --role=roles/cloudkms.autokeyAdmin --condition-from-file="$(kv_rec "KV-6.4-condition-${f}-1.json")"
    fi
  done
  kv_show "each condition file holds {title, description, expression} of a kv-6-2-autokey-bootstrap binding read from that folder's policy;"
  kv_show "one removal per such binding; --all is never used (it would also strip a binding KV-6.2 did not make)"
  out="$(kv_ak_counts "$fs")"
  printf '%s\n' "$out" | kv_keep KV-6.4 autokey-admin-removed - 4.1.3 txt || return 1
  if [ "$AGP_MODE" != apply ]; then
    kv_show "VERIFY: five folders, each with a zero count of roles/cloudkms.autokeyAdmin bindings; then close BD-11-3"
    x bd_close BD-11-3 "removed in KV-6.4 at <time>" "11 KV-6.4 five zero counts"
    return 0
  fi
  printf '%s\n' "$out" | sed 's/^/        /'
  for f in $fs; do
    n="$(kv_ak_mine "$f")" || return 1
    [ "$n" = 0 ] || { echo "folders/$f still holds $n kv-6-2-autokey-bootstrap binding(s): re-run this step before closing the sitting"; left=1; }
  done
  [ $left = 0 ] || return 1
  if [ "$(printf '%s\n' "$out" | awk '$2 == "0"' | wc -l | tr -d ' ')" -ne 5 ]; then
    echo "      FINDING: an autokeyAdmin binding without the kv-6-2-autokey-bootstrap condition remains (counts above)."
    echo "      KV-6.2 did not make it, so it is not removed here: record it and report it to the second human. KV-9.1 stops on it."
  fi
  if kv_bd3_open; then x bd_close BD-11-3 "removed in KV-6.4 at $(date -u +%Y-%m-%dT%H:%M:%SZ)" "11 KV-6.4 five zero counts" || return 1; fi
  return 0
}

# ------------------------------------------------------------------ 7. Key availability and state-change detection
step KV-7.1 HUMAN "Commit the key-state detection specification" --needs "KMS_PROJECT CICD_PROJECT PLATFORM_REPO_DIR"
s_KV_7_1_check() { ckpt_done KV-7.1; }
s_KV_7_1_manual() {
  echo "WHO: platform owner writes and pushes; the second human reviews and merges (CODEOWNERS)."
  echo "WHERE: the shell, ~/.platform-env sourced, in $(v PLATFORM_REPO_DIR)."
  echo "DO: run setup/11 KV-7.1's ACTION block as written: branch kv-7-1-kms-key-state from an updated main, write"
  echo "    detections/kms-key-state.yaml with its here-document, commit, push -u origin kv-7-1-kms-key-state; open the pull request."
  echo "VERIFY: merged with the second human's approval, then the dry search (KV-7.1 VERIFY):"
  echo "    gcloud logging read 'protoPayload.serviceName=\"cloudkms.googleapis.com\" AND protoPayload.methodName=(\"SetIamPolicy\" OR \"CreateCryptoKey\")' --project=$(v KMS_PROJECT) --freshness=1d --limit=20"
  echo "    shows at least the KV-2.3 and KV-4.3 SetIamPolicy entries; correct the resource.type values if they differ."
  echo "RECORD: merge commit and search output as <date>-KV-7.1-kms-detection-v1; a re-run line for 15 part A."
  echo "Then: agp-platform done KV-7.1"
}

kv_kms_query() {
  printf '%s' 'protoPayload.serviceName="cloudkms.googleapis.com" AND protoPayload.methodName=("DestroyCryptoKeyVersion" OR "UpdateCryptoKeyVersion" OR "UpdateCryptoKey" OR "UpdateCryptoKeyPrimaryVersion" OR "DeleteCryptoKey" OR "DeleteCryptoKeyVersion" OR "SetIamPolicy" OR "google.cloud.kms.v1.AutokeyAdmin.UpdateAutokeyConfig")'
}

step KV-7.2 AUTO-READ "Run the interim key-state check weekly until file 15's alert is live" \
  --needs "KMS_PROJECT CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KV_7_2_check() {   # done when this week's read is on file; seven days later it is due again
  local since f d
  since="$(python3 -c 'import datetime as d;print((d.datetime.now(d.timezone.utc)-d.timedelta(days=6)).strftime("%Y-%m-%d"))')" || return 2
  for f in "$(v BUILD_LOG_DIR)"/records/*-KV-7.2-kms-weekly-v1.txt; do
    [ -f "$f" ] || continue
    d="${f##*/}"; d="${d%%-KV-7.2-*}"
    if [ "$d" \> "$since" ] || [ "$d" = "$since" ]; then return 0; fi
  done
  return 1
}
s_KV_7_2_apply() {
  local p
  kv_show "reads, for KMS_PROJECT and CICD_PROJECT: gcloud logging read '<the KV-7.2 query>' --project=<P> --freshness=8d"
  { for p in KMS_PROJECT CICD_PROJECT; do
      printf '## %s\n' "$(v "$p")"
      r gcloud logging read "$(kv_kms_query)" --project="$(v "$p")" --freshness=8d --format="table(timestamp,protoPayload.methodName,resource.labels,protoPayload.authenticationInfo.principalEmail)"
    done; } | kv_keep KV-7.2 kms-weekly - 5.2.4 txt || kv_planok || return 1
  kv_show "VERIFY: every entry matches a step of 11, 12, 17 or 23 with a build-log line; the record goes to the second human"
  [ "$AGP_MODE" = apply ] || return 0
  echo "      send the record to the second human; every entry must match a step of 11, 12, 17 or 23 with a build-log line."
  echo "      An unexplained entry opens a severity 1 incident with the incident commander. Due again in seven days (DRILL_CALENDAR)."
}

# ------------------------------------------------------------------ 8. The validator custodian (M8): BLOCKED on B-13
# Every step below is BLOCKED (person, B-13): the runner writes its BLOCKED checkpoint and the run goes on
# to section 9. When 03 has named SECURITY_REVIEWER_EMAIL and VALIDATOR_CUSTODIAN_EMAIL, the platform owner
# runs the page's section 8 in order and records each step with 01's `checkpoint KV-8.n DONE`. After 12 the
# creator's Owner is gone: section 8 then runs through ENT_PROJECT_REPAIR_CORE, approved by the second human.
kv_b13() { echo "BLOCKED on B-13 until 03 names SECURITY_REVIEWER_EMAIL and VALIDATOR_CUSTODIAN_EMAIL (neither *tbd*): the BLOCKED checkpoint is written and the run continues."; }

step KV-8.1 BLOCKED "Record the security reviewer's ownership of VALIDATOR_PROJECT and check separation" --witness --note "B-13: security reviewer and validator custodian not named (PPL-SR, PPL-VC)"
s_KV_8_1_check() { ckpt_done KV-8.1; }
s_KV_8_1_manual() {
  kv_b13
  echo "WHO: platform owner prepares; the security reviewer signs the ownership record; the validator custodian confirms."
  echo "DO: setup/11 KV-8.1: the two separation tests (custodian is neither MO_OWNER_EMAIL nor OWNER_DAILY_ACCOUNT), then"
  echo "    gcloud essential-contacts create --email=<each of the two> --notification-categories=security,technical --language=en"
  echo "    --project=$(v VALIDATOR_PROJECT) --billing-project=$(v CICD_PROJECT). If the API is refused as disabled, never enable it:"
  echo "    bd_insert the BD-11-4 row as the page prints it. Commit decisions/<date>-validator-project-ownership.md with the CODEOWNERS entry."
  echo "RECORD: contact list and merge commit as <date>-KV-8.1-validator-ownership-v1; then: checkpoint KV-8.1 DONE <witness>"
}

step KV-8.2 BLOCKED "Create the custodian identity with jobUser at home" --witness --sets "SA_VALIDATOR_CUSTODIAN" --note "B-13"
s_KV_8_2_check() { ckpt_done KV-8.2; }
s_KV_8_2_manual() {
  kv_b13
  echo "WHO: platform owner; the validator custodian confirms the identity name."
  echo "DO: setup/11 KV-8.2: gcloud iam service-accounts create validator-custodian ... --project=$(v VALIDATOR_PROJECT);"
  echo "    penv_set SA_VALIDATOR_CUSTODIAN validator-custodian@$(v VALIDATOR_PROJECT).iam.gserviceaccount.com;"
  echo "    gcloud projects add-iam-policy-binding $(v VALIDATOR_PROJECT) --member=serviceAccount:<it> --role=roles/bigquery.jobUser --condition=None"
  echo "VERIFY: its only project role is roles/bigquery.jobUser. RECORD: <date>-KV-8.2-custodian-identity-v1; checkpoint KV-8.2 DONE <witness>"
}

step KV-8.3 BLOCKED "Prove nobody can act as the custodian yet" --witness --note "B-13"
s_KV_8_3_check() { ckpt_done KV-8.3; }
s_KV_8_3_manual() {
  kv_b13
  echo "WHO: platform owner; the validator custodian confirms."
  echo "DO: setup/11 KV-8.3's three reads: the account's own IAM policy, its user-managed keys, and the project-level"
  echo "    serviceAccountUser and serviceAccountTokenCreator bindings on $(v VALIDATOR_PROJECT)."
  echo "VERIFY: no bindings, no keys, none. RECORD: <date>-KV-8.3-custodian-no-actas-v1; checkpoint KV-8.3 DONE <witness>"
}

step KV-8.4 BLOCKED "Create the grader role, append-capable and without delete, update or IAM permissions" --witness --sets "ROLE_GRADER_INSERT" --note "B-13"
s_KV_8_4_check() { ckpt_done KV-8.4; }
s_KV_8_4_manual() {
  kv_b13
  echo "WHO: platform owner; the security reviewer reviews the permission list."
  echo "DO: setup/11 KV-8.4: gcloud iam roles create gradesEveWriter --project=$(v VALIDATOR_PROJECT) with the page's --title and --description,"
  echo "    --permissions=bigquery.tables.updateData,bigquery.tables.getData,bigquery.tables.get,bigquery.datasets.get --stage=GA;"
  echo "    penv_set ROLE_GRADER_INSERT projects/$(v VALIDATOR_PROJECT)/roles/gradesEveWriter"
  echo "VERIFY: exactly those four permissions (the page's jq prints true). RECORD: <date>-KV-8.4-grader-role-v1; checkpoint KV-8.4 DONE <witness>"
}

step KV-8.5 BLOCKED "The security reviewer signs the accepted limit for grades_eve" --note "B-13; SD-43"
s_KV_8_5_check() { ckpt_done KV-8.5; }
s_KV_8_5_manual() {
  kv_b13
  echo "WHO: the security reviewer signs; the platform owner files decisions/<date>-sd-43-grades-eve-accepted-limit.md (03 DC-1.4)."
  echo "STATES: no insert-only permission in BigQuery; the grading identity can delete or rewrite grades with DML; detection only"
  echo "        (KV-8.12, Mo's A10); the residual until a locked off-tenant export of grades_eve exists (owner: security reviewer)."
  echo "VERIFY: merged with the security reviewer's approval; 03's tracker lists SD-43 signed for 11. Then: checkpoint KV-8.5 DONE"
}

step KV-8.6 BLOCKED "Request the Autokey key for eve_grades" --irreversible --note "B-13; and only on the day KV-8.7 can run (E-21)"
s_KV_8_6_check() { ckpt_done KV-8.6; }
s_KV_8_6_manual() {
  kv_b13
  echo "IRREVERSIBLE: a key handle cannot be deleted; run it only on the day KV-8.7 runs (E-21 signed)."
  echo "DO: setup/11 KV-8.6: POST https://cloudkms.googleapis.com/v1/projects/$(v VALIDATOR_PROJECT)/locations/europe/keyHandles"
  echo "    with {\"resource_type_selector\": \"bigquery.googleapis.com/Dataset\"}, then GET the operation until done; GRADES_KEY is its"
  echo "    response.kmsKey, projects/$(v KMS_PROJECT)/locations/europe/keyRings/autokey/cryptoKeys/<name>. A refusal: no dataset, a key-table amendment."
  echo "RECORD: <date>-KV-8.6-grades-keyhandle-v1; GRADES_KEY into bootstrap/expected/11-keys.yaml; checkpoint KV-8.6 DONE"
}

step KV-8.7 BLOCKED "Create the dataset eve_grades in EU with the Autokey key" --irreversible --sets "GRADES_EVE_DS" --note "B-13; E-21 (decision) unsigned"
s_KV_8_7_check() { ckpt_done KV-8.7; }
s_KV_8_7_manual() {
  kv_b13
  echo "Also BLOCKED until E-21 is signed (eve/09-open-decisions.md; 03 adds its tracker row). IRREVERSIBLE: name and location."
  echo "DO: setup/11 KV-8.7: bq --location=EU mk --dataset --default_kms_key=\"\$GRADES_KEY\" ... \"$(v VALIDATOR_PROJECT):eve_grades\";"
  echo "    penv_set GRADES_EVE_DS eve_grades"
  echo "VERIFY: location EU, kmsKeyName GRADES_KEY, no defaultTableExpirationMs; Autokey granted bq-<number>@bigquery-encryption on the key."
  echo "RECORD: <date>-KV-8.7-eve-grades-v1; checkpoint KV-8.7 DONE"
}

step KV-8.8 BLOCKED "Give the custodian its read on eve_grades" --witness --removes --note "B-13; after KV-8.7"
s_KV_8_8_check() { ckpt_done KV-8.8; }
s_KV_8_8_manual() {
  kv_b13
  echo "WHO: platform owner; the validator custodian confirms."
  echo "DO: setup/11 KV-8.8, 01's access-array rule: bq show --format=prettyjson to a before file, append"
  echo "    {\"role\":\"READER\",\"userByEmail\":\"\$SA_VALIDATOR_CUSTODIAN\"}, bq update --source, read back, diff."
  echo "VERIFY: exactly one added entry, nothing removed. RECORD: the diff as <date>-KV-8.8-custodian-reader-v1; checkpoint KV-8.8 DONE <witness>"
}

step KV-8.9 BLOCKED "Create the table grades_eve from its committed schema" --note "B-13; code: validator/schemas/grades_eve.json is not committed"
s_KV_8_9_check() { ckpt_done KV-8.9; }
s_KV_8_9_manual() {
  kv_b13
  echo "Also BLOCKED on code: validator/schemas/grades_eve.json, reviewed by the security reviewer and the approval surface's owner."
  echo "When it is committed: setup/11 KV-8.9's ACTION (bq mk --table --schema=... \"$(v VALIDATOR_PROJECT):eve_grades.grades_eve\"),"
  echo "with the partitioning and expiry flags taken from the schema file's header; then checkpoint KV-8.9 DONE."
}

step KV-8.10 BLOCKED "Row 45: the grading identity's writer entry (PENDING until file 33)" --witness --removes --note "B-13; then PENDING until 33"
s_KV_8_10_check() { ckpt_done KV-8.10; }
s_KV_8_10_manual() {
  kv_b13
  echo "WHO: platform owner on the custodian's resources; the security reviewer approves."
  echo "DO: exists_or_pending --pending \"serviceAccount:grading identity named in 33\" KV-8.10 \"11 KV-8.10 row 45 ROLE_GRADER_INSERT on eve_grades (after 33)\";"
  echo "    only once 33 has made the identity: set GRADER_SA to the email 33 records, then the page's second block"
  echo "    (need GRADER_SA ROLE_GRADER_INSERT ...) and the KV-8.8 edit with {\"role\":\"\$ROLE_GRADER_INSERT\",\"userByEmail\":\"\$GRADER_SA\"}."
  echo "VERIFY: one added entry with projects/<VALIDATOR_PROJECT>/roles/gradesEveWriter; no Eve, Mo or Wall-E enforcement identity in access."
}

step KV-8.11 BLOCKED "Row 46: mo-metrics@'s READER on eve_grades (PENDING until file 22)" --witness --removes --note "B-13; then PENDING until 22"
s_KV_8_11_check() { ckpt_done KV-8.11; }
s_KV_8_11_manual() {
  kv_b13
  echo "WHO: platform owner on the custodian's resources; the validator custodian confirms."
  echo "DO: setup/11 KV-8.11: exists_or_pending (with --pending while SA_MO_METRICS is unset) KV-8.11 \"11 KV-8.11 row 46 READER on eve_grades (after 22)\";"
  echo "    when SA_MO_METRICS exists (22): the KV-8.8 edit with {\"role\":\"READER\",\"userByEmail\":\"\$SA_MO_METRICS\"}."
  echo "VERIFY: one READER entry for SA_MO_METRICS; no project-level binding of mo-metrics@ in VALIDATOR_PROJECT."
}

step KV-8.12 BLOCKED "Commit the DML-tampering detection on eve_grades" --note "B-13"
s_KV_8_12_check() { ckpt_done KV-8.12; }
s_KV_8_12_manual() {
  kv_b13
  echo "WHO: platform owner writes and pushes; the security reviewer reviews and merges; file 15 deploys the rule."
  echo "DO: setup/11 KV-8.12's ACTION as written: branch kv-8-12-grades-dml from an updated main, detections/validator-grades-dml.yaml"
  echo "    with its here-document, commit, push -u origin kv-8-12-grades-dml; open the pull request."
  echo "VERIFY: merged with the security reviewer's approval. RECORD: <date>-KV-8.12-grades-dml-detection-v1; checkpoint KV-8.12 DONE"
}

# ------------------------------------------------------------------ 9. Close the part
step KV-9.1 AUTO-READ "Diff the live state against the expected state and record the variables" \
  --needs "FLD_PLATFORM_CORE FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS FLD_IMPROVERS FLD_AGENTS_R KMS_PROJECT CICD_PROJECT CICD_PROJECT_NUMBER VALIDATOR_PROJECT LOGGING_PROJECT SA_CI_BUILD BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KV_9_1_check() { ckpt_done KV-9.1; }
s_KV_9_1_apply() {
  local fs f n lf pol m k bad=0
  fs="$(kv_ak_folders)"; kv_ak_five "$fs" || return 1
  lf="$(v BUILD_LOG_DIR)/$(kv_today)-KV-9.1-live-state.txt"
  { r gcloud kms keys list --keyring=logging --location=europe-west1 --project="$(v KMS_PROJECT)" --format="value(name,purpose,versionTemplate.protectionLevel,rotationPeriod)"
    r gcloud kms keys list --keyring=engines --location=europe-west1 --project="$(v KMS_PROJECT)" --format="value(name)"
    r gcloud kms keys list --keyring=gemini --location=europe --project="$(v KMS_PROJECT)" --format="value(name,purpose,versionTemplate.protectionLevel,rotationPeriod)"
    r gcloud kms keys list --keyring=supply-chain --location=europe-west1 --project="$(v CICD_PROJECT)" --format="value(name,purpose,versionTemplate.protectionLevel,versionTemplate.algorithm)"
    r gcloud container binauthz attestors list --project="$(v CICD_PROJECT)" --format="value(name)"
    for f in $fs; do r gcloud kms autokey-config describe --folder="$f" --billing-project="$(v KMS_PROJECT)" --format="value(name,keyProject)"; done
  } | xw "$lf" || kv_planok || return 1
  ev KV-9.1 live-state E-05 "1.3.1,5.1.1" "build-log:${lf##*/}" "$lf" || return 1
  kv_show "then re-verifies every VERIFY of sections 2 to 6 that names a value (the steps there print it, this step stops on it):"
  kv_show "  the two symmetric keys' purpose, protection, algorithm, rotation, destroy duration and state; the attestor key versions;"
  kv_show "  platform-logs' sole Encrypter/Decrypter in @gcp-sa-logging; the KV-5.3 note policies and the KV-5.5 note diff;"
  kv_show "  Autokey on exactly five folders naming KMS_PROJECT, none on fld-agents-r; zero autokeyAdmin bindings on the five folders"
  [ "$AGP_MODE" = apply ] || return 0
  for n in KR_LOGGING KEY_PLATFORM_LOGS KR_GEMINI KEY_GEMINI_CMEK KR_ENGINES BINAUTHZ_ATTESTOR BINAUTHZ_ATTESTOR_PROMOTED KEY_BINAUTHZ KEY_BINAUTHZ_PROMOTED; do
    has_value "$n" || { echo "      VERIFY FAILED: $n has no value"; bad=1; }
  done
  for n in SA_VALIDATOR_CUSTODIAN GRADES_EVE_DS ROLE_GRADER_INSERT; do
    if has_value "$n"; then echo "      $n set"; else echo "      $n not set (section 8 BLOCKED on B-13)"; fi
  done
  kv_verify "platform-logs-europe-west1 ($kv_logs_fields)" "$kv_logs_want" "$(kv_key_read KMS_PROJECT logging europe-west1 platform-logs-europe-west1 "$kv_logs_fields")" || bad=1
  kv_verify "gemini-cmek ($kv_gem_fields)" "$kv_gem_want" "$(kv_key_read KMS_PROJECT gemini europe gemini-cmek "$kv_gem_fields")" || bad=1
  for k in binauthz-vuln-gated binauthz-promoted; do
    kv_verify "$k (purpose, protection, algorithm, destroy duration)" "ASYMMETRIC_SIGN|HSM|EC_SIGN_P256_SHA256|2592000s" \
      "$(kv_key_read CICD_PROJECT supply-chain europe-west1 "$k" "purpose,versionTemplate.protectionLevel,versionTemplate.algorithm,destroyScheduledDuration")" || bad=1
    kv_versions_ok "$k" || bad=1
  done
  pol="$(kv_policy gcloud kms keys get-iam-policy platform-logs-europe-west1 --keyring=logging --location=europe-west1 --project="$(v KMS_PROJECT)")"
  m="$(printf '%s' "$pol" | kv_json role-members roles/cloudkms.cryptoKeyEncrypterDecrypter)"
  if printf '%s' "$pol" | kv_json only roles/cloudkms.cryptoKeyEncrypterDecrypter "$m"; then
    case "$m" in serviceAccount:*@gcp-sa-logging.iam.gserviceaccount.com) echo "      VERIFY ok: platform-logs-europe-west1 sole Encrypter/Decrypter $m";;
      *) echo "      VERIFY FAILED: platform-logs-europe-west1's Encrypter/Decrypter $m is not a @gcp-sa-logging account"; bad=1;; esac
  else echo "      VERIFY FAILED: platform-logs-europe-west1 is not exactly one binding with one member"; bad=1; fi
  for n in vuln-gated promoted-to-prod; do kv_note_ok "$n" && echo "      VERIFY ok: ${n}-note policy" || bad=1; done
  kv_note55_ok && echo "      VERIFY ok: KV-5.5 note diff" || bad=1
  kv_ak_verify || bad=1
  kv_verify "folders with zero roles/cloudkms.autokeyAdmin bindings" 5 "$(kv_ak_counts "$fs" | awk '$2 == "0"' | wc -l | tr -d ' ')" || bad=1
  if [ $bad = 0 ]; then
    echo "      the second human compares $lf with bootstrap/expected/11-keys.yaml; write the result in the build log against BD-11-1"
  else
    echo "      FAIL: the live state differs from the page (lines above); correct it, then: agp-platform apply --phase 11 --from KV-9.1"
  fi
  return $bad
}

step KV-9.2 HUMAN "Write the index lines and close the sitting" --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_KV_9_2_check() { ckpt_done KV-9.2; }
s_KV_9_2_manual() {
  echo "WHO: platform owner. WHERE: the README re-run and BLOCKED indexes, by pull request."
  echo "DO: append this sitting's PENDING and BLOCKED lines: KV-4.3 (a Gemini agent absent, 19); KV-5.5 (release account, 17);"
  echo "    KV-8.1 to KV-8.12 (B-13 while people are unnamed); KV-8.7 (E-21); KV-8.9 (schema); KV-8.10 (33); KV-8.11 (22);"
  echo "    the 12 re-run: ENT_PROJECT_REPAIR_CORE with the security reviewer as approver on VALIDATOR_PROJECT."
  echo "    $(v BUILD_LOG_DIR)/rerun-index.tsv holds the PENDING lines this run wrote; checkpoints.tsv the BLOCKED ones."
  echo "VERIFY: the README pull request is merged."
  echo "Then: agp-platform done KV-9.2, and close the sitting: agp-platform sitting end (01's sitting_end prints SITTING-END OK)."
}
