# phases/14-central-logging-and-billing-export.sh: setup/14, central logging, the Data Access audit
# configuration and the billing export (step prefix CL).
#
# How the page maps onto the classes:
# - Section 1 (Workspace sharing) is the organisation's Cloud Logging owner's and a super admin's:
#   HUMAN, with CL-1.2's read of the Admin console as CONSOLE and CL-1.3's toggle witnessed.
# - The PAM requests (CL-2.1) and every step the second human approves, reads or signs while the
#   platform owner acts (CL-3.5, CL-5.1, CL-6.2, CL-6.3, CL-6.5, CL-6.6, CL-8.1, CL-8.4, CL-11.2) are
#   HUMAN: the script cannot wait for an approval in the middle of a step. CL-6.3's enabling of
#   interception is not replayable, so it stays a person's line, with the confirmation table walked.
# - The billing administrator's steps (CL-6.4, CL-9.3) are HUMAN.
# - Everything the platform owner runs under the CL-2.1 grants is AUTO: buckets, views, view readers,
#   datasets, fan-out sinks, the _Default exclusion, the audit-configuration merges, the temporary
#   BigQuery User, the locks. CL-2.2, CL-6.1 and CL-11.1 (the grant tables) are AUTO-READ.
# - Run order: CL-2.5 (the throwaway probe) is registered before CL-2.3 and CL-2.4, as the page runs it.
# - IRREVERSIBLE: CL-2.5 (the lock on the throwaway), CL-2.3 and CL-2.4 (location, CMEK, analytics),
#   CL-4.1 (a key handle cannot be deleted and its id names the dataset), CL-4.2, CL-4.3 and CL-9.1
#   (dataset names and location), CL-10.2 and CL-10.3 (the locks, second human present).
# - The six filter files and logging/sinks-expected.yaml (CL-5.1) and the two audit-configuration files
#   (CL-8.1) are here-documents on the page, written, committed and merged by a person under the second
#   human's review, as phases 03, 16, 18 and 21 treat pull-request steps: the script never retypes them,
#   and every step that uses them reads the committed file, never a copy.
# - A filter is substituted with sed exactly as the page does, and only with the names its sink uses.
# - Verifications prefer a filtered list that prints something (rule 4). A filter stored by Logging is
#   compared with the committed file and a difference is shown, not failed on: Logging may normalise
#   the text it stores. A BigQuery read-back (bq show) that contradicts the page's VERIFY is a STOP; a
#   field it does not show at all is reported for the person to compare, since the step's own flags set it.
# - Deviation rows are the page's: BD-14-01 (CL-4.1 branch (b)) and BD-14-02 (CL-9.2), inserted with
#   01's bd_insert, and CL-9.4 closes BD-14-02 with bd_close. CL-9.4 runs in three parts: the 48 hours read
#   from export_time, the removal with its time recorded, then appends after the removal; until one
#   exists the step stops for a later resume (98), and only then is BD-14-02 closed.
# - No `requires`: after 12 PA-9.3 the platform owner holds no standing organisation role, and every
#   change here runs under a PAM grant requested in CL-2.1 or CL-6.2, which preflight cannot see.
#
# Helpers private to this file start with cl14_. They read, compute or format; every change goes
# through x, xw, pset, ev or api.

phase 14 "Central logging, audit configuration and the billing export" "14-central-logging-and-billing-export.md"

# ------------------------------------------------------------------ helpers
cl14_today() { date -u +%F; }

cl14_rec() {    # cl14_rec NAME: the path of today's record under BUILD_LOG_DIR/records
  printf '%s/records/%s-%s' "$(v BUILD_LOG_DIR)" "$(cl14_today)" "$1"
}

cl14_last() {   # cl14_last SUFFIX: the newest record of any date whose name ends -SUFFIX
  local f last=""
  for f in "$(_penv_get BUILD_LOG_DIR)"/records/*-"$1"; do [ -f "$f" ] && last="$f"; done
  [ -n "$last" ] || return 1
  printf '%s' "$last"
}

cl14_keep() {   # cl14_keep STEP SLUG E-ID TISAX EXT < content: write today's record and register it
  local f; f="$(cl14_rec "$1-$2-v1.$5")"
  xw "$f" || return 1
  ev "$1" "$2" "$3" "$4" "build-log:records/${f##*/}" "$f"
}

cl14_planok() { [ "$AGP_MODE" != apply ]; }

cl14_under() { agp_say "      under: $1"; }   # the PAM grant the step's commands run under (setup/14 WHO)

# An existence probe made by a step's check is kept for the apply that follows it, so the apply does not
# read the same resource twice. Only the status of a read is kept; nothing is changed.
cl14_probe() {  # cl14_probe KEY CMD...: exists CMD; its status kept under KEY
  local k="$1" rc; shift
  exists "$@"; rc=$?
  eval "CL14_P_$k=$rc"
  return $rc
}
cl14_probed() { # cl14_probed KEY CMD...: the status the check kept under KEY (used once), else a live probe
  local k="$1" st; shift
  eval "st=\${CL14_P_$k-}"
  if [ -n "$st" ]; then eval "unset CL14_P_$k"; return "$st"; fi
  exists "$@"
}   # a read that fed a record failed: fatal in apply only

cl14_stop() {   # cl14_stop WHY REQUIREMENT: in apply mode say STOP WHY and fail; in plan mode show the REQUIREMENT
  if [ "$AGP_MODE" = apply ]; then agp_say "      STOP: $1"; return 1; fi
  agp_say "      requires: ${2:-$1}"; return 0
}

cl14_r() {      # cl14_r CMD...: a read whose output the step records; shown in plan mode, then run as r
  [ "$AGP_MODE" = apply ] || printf '      read: %s\n' "$(agp_quote "$@")" >&3
  r "$@"
}

cl14_worst() {  # cl14_worst RC...: 2 if any is 2, else 3 if any is 3, else 1 if any is 1, else 0
  local w=0 c
  for c in "$@"; do
    case "$c" in 2) w=2;; 3) [ $w = 2 ] || w=3;; 0) ;; *) [ $w != 0 ] || w=1;; esac
  done
  return $w
}

cl14_ckpt_age_h() { # cl14_ckpt_age_h STEP: hours since the last DONE line of STEP (nothing when none)
  local t
  t="$(awk -F'\t' -v s="$1" '$2 == s && $3 == "DONE" {t = $1} END {print t}' "$(_penv_get BUILD_LOG_DIR)/checkpoints.tsv" 2>/dev/null)"
  [ -n "$t" ] || return 1
  python3 -c 'import sys, datetime as d
t = d.datetime.strptime(sys.argv[1], "%Y-%m-%dT%H:%M:%SZ")
print(int((d.datetime.utcnow() - t).total_seconds() // 3600))' "$t"
}

cl14_ckpt_has() {   # cl14_ckpt_has STEP STATUS: checkpoints.tsv has a line of STEP with STATUS
  [ -f "$(_penv_get BUILD_LOG_DIR)/checkpoints.tsv" ] || return 1
  awk -F'\t' -v s="$1" -v st="$2" '$2 == s && $3 == st {f = 1} END {exit f ? 0 : 1}' "$(_penv_get BUILD_LOG_DIR)/checkpoints.tsv"
}

cl14_rerun_has() {  # cl14_rerun_has STEP MEMBER: the re-run index has a PENDING line for STEP and MEMBER
  [ -f "$(_penv_get BUILD_LOG_DIR)/rerun-index.tsv" ] || return 1
  awk -F'\t' -v s="$1" -v m="$2" '$2 == s && $3 == m && $5 == "PENDING" {f = 1} END {exit f ? 0 : 1}' "$(_penv_get BUILD_LOG_DIR)/rerun-index.tsv"
}

cl14_pending() {    # cl14_pending MEMBER STEP WHAT: 01's exists_or_pending --pending; 0 when the line is written
  exists_or_pending --pending "$@"
  [ $? -eq 1 ]
}
cl14_xpending() {   # cl14_xpending MEMBER STEP WHAT: the PENDING row through x, shown in plan as the page writes it
  if [ "$AGP_MODE" != apply ]; then printf '      $ %s\n' "$(agp_quote exists_or_pending --pending "$@")" >&3; return 0; fi
  x cl14_pending "$@"
}

cl14_pam_flag() {   # cl14_pam_flag ENTITLEMENT_NAME: the scope flag of a full entitlement name (pam_req's case)
  local s="${1%%/locations/*}"
  case "$s" in
    organizations/?*) printf -- '--organization=%s' "${s#organizations/}";;
    folders/?*) printf -- '--folder=%s' "${s#folders/}";;
    projects/?*) printf -- '--project=%s' "${s#projects/}";;
    *) printf -- '--<organization|folder|project>=<from %s>' "$1"; return 1;;
  esac
}

cl14_filter_file() { printf '%s/logging/filters/%s.txt' "$(v PLATFORM_REPO_DIR)" "$1"; }

cl14_filter() {     # cl14_filter NAME [VAR...]: the committed filter with VARs substituted, as one line
  local f n e=""; f="$(cl14_filter_file "$1")"; shift
  if [ ! -f "$f" ]; then
    if [ "$AGP_MODE" = apply ]; then agp_say "      STOP: $f is missing: CL-5.1 writes and merges it"; return 1; fi
    printf '<the filter in logging/filters/%s>' "${f##*/}"; return 0
  fi
  for n in "$@"; do e="$e -e s/$n/$(v "$n")/g"; done
  # shellcheck disable=SC2086
  sed $e "$f" | grep -v '^#' | tr '\n' ' '
}

cl14_vcond() {      # cl14_vcond BUCKET VIEW: the conditioned viewAccessor binding of CL-3.2
  printf 'expression=resource.name == "projects/%s/locations/%s/buckets/%s/views/%s",title=view-%s' \
    "$(v LOGGING_PROJECT)" "$(v REGION)" "$1" "$2" "$2"
}

cl14_view_bound() { # cl14_view_bound MEMBER BUCKET VIEW: MEMBER holds viewAccessor conditioned on that view
  nonempty r gcloud projects get-iam-policy "$(v LOGGING_PROJECT)" --flatten="bindings[].members" \
    --filter="bindings.role=roles/logging.viewAccessor AND bindings.members=\"$1\" AND bindings.condition.expression~\"buckets/$2/views/$3.\$\"" \
    --format="value(bindings.members)"
}

cl14_bucket_ok() {  # cl14_bucket_ok BUCKET FILTER: the bucket is listed in REGION, ACTIVE, and matches FILTER
  nonempty r gcloud logging buckets list --location="$(v REGION)" --project="$(v LOGGING_PROJECT)" \
    --filter="name~\"/buckets/$1\$\" AND lifecycleState=ACTIVE${2:+ AND $2}" --format="value(name)"
}

cl14_sink_ok() {    # cl14_sink_ok SCOPE_FLAG SINK DESTINATION [FILTER]: the sink exists, enabled, to DESTINATION
  nonempty r gcloud logging sinks list "$1" \
    --filter="name=\"$2\" AND destination=\"$3\" AND NOT disabled=true${4:+ AND $4}" --format="value(name)"
}

cl14_sink_filter_cmp() {    # cl14_sink_filter_cmp SCOPE_FLAG SINK WANT: show a difference between the stored and committed filter
  local got
  [ "$AGP_MODE" = apply ] || return 0
  got="$(r gcloud logging sinks describe "$2" "$1" --format='value(filter)')" || return 0
  if [ "$(printf '%s' "$got" | sed 's/ *$//')" = "$(printf '%s' "$3" | sed 's/ *$//')" ]; then
    echo "      $2: the stored filter equals the committed file"
  else
    echo "      $2: the stored filter differs from the committed file; read both before CL-6:"
    printf '        stored:    %s\n        committed: %s\n' "$got" "$3"
  fi
}

cl14_py_src() {
  cat <<'PY'
import json, sys, difflib
op, a = sys.argv[1], sys.argv[2:]
def load(f=None):
    raw = open(f).read() if f else sys.stdin.read()
    return json.loads(raw) if raw.strip() else {}
def binds(p):
    return (p or {}).get('bindings', []) or []
def merge(pol, want):           # setup/14 CL-8.2's jq: group by service, unique by logType
    cur = list(pol.get('auditConfigs') or []) + list(want)
    out = {}
    for c in cur:
        out.setdefault(c['service'], []).extend(c.get('auditLogConfigs', []))
    res = []
    for svc in sorted(out):
        seen = {}
        for l in out[svc]:
            seen.setdefault(l['logType'], l)
        res.append({'service': svc, 'auditLogConfigs': [seen[k] for k in sorted(seen)]})
    pol['auditConfigs'] = res
    return pol
if op == 'want':                # want FILE [KEY]: the wanted auditConfigs of the folder file, or of KEY in the projects file
    d = load(a[0])
    print(json.dumps(d[a[1]] if len(a) > 1 else d['auditConfigs'])); sys.exit(0)
if op == 'pairs':               # pairs < auditConfigs: service and logType, one pair per line
    for c in load():
        for l in c.get('auditLogConfigs', []):
            print('%s|%s' % (c['service'], l['logType']))
    sys.exit(0)
if op == 'exempt':              # exempt < policy or auditConfigs file: every exemptedMembers entry
    d = load(); cs = d if isinstance(d, list) else d.get('auditConfigs', []) or []
    if isinstance(d, dict) and 'auditConfigs' not in d and 'bindings' not in d:
        cs = [c for v in d.values() for c in v]
    for c in cs:
        for l in c.get('auditLogConfigs', []):
            for m in l.get('exemptedMembers', []):
                print('%s %s %s' % (c['service'], l['logType'], m))
    sys.exit(0)
if op == 'merge':               # merge WANT_JSON < policy: the policy with the wanted auditConfigs merged in
    print(json.dumps(merge(load(), json.loads(a[0])), indent=2, sort_keys=True)); sys.exit(0)
if op == 'only-audit':          # only-audit BEFORE AFTER: bindings and etag identical, an etag present
    b, f = load(a[0]), load(a[1])
    ok = b.get('etag') and b.get('etag') == f.get('etag') and json.dumps(binds(b), sort_keys=True) == json.dumps(binds(f), sort_keys=True)
    sys.exit(0 if ok else 1)
if op == 'diff':                # diff BEFORE AFTER: a unified diff of the two JSON files, sorted
    x = json.dumps(load(a[0]), indent=2, sort_keys=True).splitlines()
    y = json.dumps(load(a[1]), indent=2, sort_keys=True).splitlines()
    for l in difflib.unified_diff(x, y, 'before', 'after', lineterm=''):
        print(l)
    sys.exit(0)
if op == 'roles-of':            # roles-of MEMBER < policy: the roles bound to MEMBER
    for b in binds(load()):
        if a[0] in b.get('members', []):
            print(b.get('role'))
    sys.exit(0)
if op == 'key-others':          # key-others MEMBER < key policy: other members on a role that can encrypt or decrypt
    can = ('roles/cloudkms.cryptoKeyEncrypterDecrypter', 'roles/cloudkms.cryptoKeyEncrypter', 'roles/cloudkms.cryptoKeyDecrypter',
           'roles/cloudkms.cryptoKeyEncrypterDecrypterViaDelegation', 'roles/cloudkms.cryptoKeyEncrypterViaDelegation',
           'roles/cloudkms.cryptoKeyDecrypterViaDelegation', 'roles/cloudkms.cryptoOperator', 'roles/owner', 'roles/editor')
    for b in binds(load()):
        if b.get('role') in can:
            for m in b.get('members', []):
                if m != a[0]:
                    print('%s %s' % (b.get('role'), m))
    sys.exit(0)
if op == 'ak-project':          # ak-project < autokey config: its keyProject
    print(load().get('keyProject', '')); sys.exit(0)
if op == 'access-has':          # access-has ENTRY_JSON < dataset: an access entry holds every field of ENTRY
    e = json.loads(a[0])
    sys.exit(0 if any(all(x.get(k) == v for k, v in e.items()) for x in load().get('access', [])) else 1)
if op == 'access-add':          # access-add ENTRY_JSON < dataset: the dataset with ENTRY appended once
    d = load(); e = json.loads(a[0]); acc = d.get('access', [])
    if not any(json.dumps(x, sort_keys=True) == json.dumps(e, sort_keys=True) for x in acc):
        acc.append(e)
    d['access'] = acc; print(json.dumps(d, indent=2)); sys.exit(0)
if op == 'access-diff':         # access-diff BEFORE AFTER ENTRY_JSON: AFTER is BEFORE plus ENTRY, nothing removed
    # exit 3 when AFTER shows no access array at all (a read-back that cannot tell)
    if 'access' not in load(a[1]): sys.exit(3)
    def ent(f): return sorted(json.dumps(x, sort_keys=True) for x in load(f).get('access', []))
    bf, af = ent(a[0]), ent(a[1]); new = json.dumps(json.loads(a[2]), sort_keys=True)
    sys.exit(0 if af == sorted(set(bf + [new])) else 1)
if op == 'shows':               # shows FIELD < json: the read-back carries FIELD
    sys.exit(0 if a[0] in load() else 1)
if op == 'access-other':        # access-other < dataset: entries other than the three project special groups
    for x in load().get('access', []):
        if x.get('specialGroup') not in ('projectOwners', 'projectWriters', 'projectReaders'):
            print(json.dumps(x, sort_keys=True))
    sys.exit(0)
if op == 'dataset':             # dataset LOCATION PART_MS|none|- KEY|- < dataset: the page's dataset VERIFY
    # A value the read-back contradicts is a STOP (exit 1); a value it does not show is reported (exit 0),
    # because location, partition expiry and key were set by this step's own bq mk flags.
    d = load(); bad = []; unshown = []
    loc = d.get('location')
    if loc is None: unshown.append('location (wanted %s)' % a[0])
    elif loc != a[0]: bad.append('location is %s, not %s' % (loc, a[0]))
    if 'defaultTableExpirationMs' in d: bad.append('a default table expiration is set')
    p = d.get('defaultPartitionExpirationMs')
    if a[1] == 'none' and p: bad.append('a default partition expiration is set')
    if a[1] not in ('none', '-'):
        if p is None: unshown.append('defaultPartitionExpirationMs (wanted %s)' % a[1])
        elif str(p) != a[1]: bad.append('defaultPartitionExpirationMs is %s, not %s' % (p, a[1]))
    k = (d.get('defaultEncryptionConfiguration') or {}).get('kmsKeyName')
    if a[2] == '-' and k: bad.append('a default key is set (%s) in branch (b)' % k)
    if a[2] != '-':
        if k is None: unshown.append('defaultEncryptionConfiguration.kmsKeyName (wanted %s)' % a[2])
        elif k != a[2]: bad.append('the default key is %s, not %s' % (k, a[2]))
    for b in bad: print('STOP: ' + b)
    for u in unshown: print('not shown by the read-back, compare the record by hand: ' + u)
    sys.exit(1 if bad else 0)
if op == 'view':                # view < table: a VIEW whose query names no principalEmail; 3 when the read-back shows neither
    d = load(); q = (d.get('view') or {}).get('query')
    if 'type' not in d and q is None: sys.exit(3)
    sys.exit(0 if d.get('type') == 'VIEW' and q and 'principalEmail' not in q else 1)
if op == 'excl-filter':         # excl-filter NAME < sink: the filter of the exclusion NAME
    for e in load().get('exclusions', []) or []:
        if e.get('name') == a[0]: print(e.get('filter', ''))
    sys.exit(0)
if op == 'one-line':            # one-line FILE: the file holds exactly one non-comment line
    n = [l for l in open(a[0]).read().splitlines() if not l.startswith('#')]
    sys.exit(0 if len(n) == 1 else 1)
sys.exit(2)
PY
}

cl14_py() { python3 -c "$(cl14_py_src)" "$@"; }

cl14_dsref() { printf '%s:%s' "$(v LOGGING_PROJECT)" "$1"; }   # PROJECT:DATASET

CL14_KEY=""
cl14_kh() {     # cl14_kh DATASET: CL-4.1's kms_key_for_dataset; the key handle kh-DATASET, its kmsKey in CL14_KEY
  local h="kh-$1" lp k n=0 rc
  lp="$(v LOGGING_PROJECT)"; CL14_KEY=""
  exists gcloud kms key-handles describe "$h" --location=europe --project="$lp" --format='value(name)'; rc=$?
  case $rc in
    0) [ "$AGP_MODE" = apply ] && echo "      key handle $h exists: not created again";;
    1|3) x gcloud kms key-handles create --key-handle-id="$h" --location=europe --resource-type=bigquery.googleapis.com/Dataset --project="$lp" \
           || agp_say "      key-handle create returned non-zero (already exists, or still provisioning); polling";;
    *) return 1;;
  esac
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      then poll: gcloud kms key-handles describe $h --location=europe --project=$lp --format='value(kmsKey)' (30 x 10 s, until it names locations/europe/)"
    CL14_KEY="<kmsKey of $h>"; return 0
  fi
  while [ $n -lt 30 ]; do
    k="$(r gcloud kms key-handles describe "$h" --location=europe --project="$lp" --format='value(kmsKey)' 2>/dev/null)"
    case "$k" in *locations/europe/*) CL14_KEY="$k"; return 0;; esac
    n=$((n + 1)); sleep 10
  done
  agp_say "      STOP: key handle $h has no kmsKey in locations/europe after 5 minutes; no dataset is created"; return 1
}

cl14_key_enabled() {    # cl14_key_enabled KEY: the Autokey key is ENABLED (CL-4.1 VERIFY)
  nonempty r gcloud kms keys list --keyring="${1%/cryptoKeys/*}" --project="$(v KMS_PROJECT)" \
    --filter="name=\"$1\" AND primary.state=ENABLED" --format="value(name)"
}

cl14_dataset() {    # cl14_dataset STEP SLUG E-ID TISAX DATASET PART KEY|-: read back, keep and verify a dataset
  local out
  out="$(r bq show --format=prettyjson "$(cl14_dsref "$5")")" || cl14_planok || { echo "$out"; return 1; }
  printf '%s\n' "$out" | cl14_keep "$1" "$2" "$3" "$4" json || return 1
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s' "$out" | cl14_py dataset "$(v BQ_LOCATION)" "$6" "$7" | sed 's/^/      /'
  [ "${PIPESTATUS[1]}" = 0 ] || { echo "      STOP: $5 contradicts the page's VERIFY (above)"; return 1; }
  if [ -n "$(printf '%s' "$out" | cl14_py access-other)" ]; then
    echo "      access entries beyond the three project special groups (BigQuery adds the creator as OWNER by default):"
    printf '%s' "$out" | cl14_py access-other | sed 's/^/        /'
    echo "      record them with the evidence; the page expects the special groups only"
  fi
}

cl14_access_add() {     # cl14_access_add STEP DATASET ENTRY_JSON [TAG]: the 01 access-array edit, read back, one entry added
  # TAG names the records when one step adds several entries to the same dataset (CL-7.3), so none overwrites another
  local ds="$2" e="$3" b bf ed af
  b="$1-$ds${4:+-$4}"
  bf="$(cl14_rec "$b-access-before.json")"; ed="$(cl14_rec "$b-access-edit.json")"; af="$(cl14_rec "$b-access-after.json")"
  r bq show --format=prettyjson "$(cl14_dsref "$ds")" | xw "$bf" || cl14_planok || return 1
  if [ "$AGP_MODE" = apply ]; then
    if cl14_py access-has "$e" < "$bf"; then echo "      $ds already holds $e: no update"; return 0; fi
    cl14_py access-add "$e" < "$bf" | xw "$ed" || return 1
    cl14_py diff "$bf" "$ed" | sed 's/^/        /'
  else
    echo "the before file with $e appended to access" | xw "$ed"
  fi
  x bq update --source="$ed" "$(cl14_dsref "$ds")" || return 1
  r bq show --format=prettyjson "$(cl14_dsref "$ds")" | xw "$af" || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  cl14_py access-diff "$bf" "$af" "$e"
  case $? in
    0) echo "      read back: $ds holds $e and nothing else changed";;
    3) echo "      the read-back shows no access array: compare $af with $bf by hand";;
    *) echo "      STOP: the access array of $ds changed by more than $e; restore with: bq update --source=$bf $(cl14_dsref "$ds")"; return 1;;
  esac
}

cl14_bd_has() {     # cl14_bd_has ID: the first table of DEVIATION_REGISTER holds the row ID
  local reg; reg="$(_penv_get DEVIATION_REGISTER)"
  [ -n "$reg" ] && [ -f "$reg" ] || return 1
  awk -F' *[|] *' -v id="$1" '$2 == id && NF == 15 {f = 1} END {exit !f}' "$reg"
}

cl14_bd_closed() {  # cl14_bd_closed ID: the Closures table of DEVIATION_REGISTER holds a line for ID (01's bd_close)
  local reg; reg="$(_penv_get DEVIATION_REGISTER)"
  [ -n "$reg" ] && [ -f "$reg" ] || return 1
  awk -F' *[|] *' -v id="$1" '$2 == id && NF == 6 {f = 1} END {exit !f}' "$reg"
}

cl14_bd_insert() {  # cl14_bd_insert ID ROW: the page's bd_insert line, once (bd_insert itself prints exists: on a re-run)
  if [ "$AGP_MODE" = apply ] && cl14_bd_has "$1"; then echo "      $1 is in DEVIATION_REGISTER: not inserted again"; return 0; fi
  x bd_insert "$2"
}

cl14_audit_pairs_ok() { # cl14_audit_pairs_ok KIND RESOURCE WANT_JSON: every wanted service and logType is in the live policy
  local p s t rcs="" pairs
  pairs="$(printf '%s' "$3" | cl14_py pairs)" || return 2
  [ -n "$pairs" ] || return 1
  for p in $pairs; do
    s="${p%%|*}"; t="${p#*|}"
    if [ "$1" = folder ]; then
      nonempty r gcloud resource-manager folders get-iam-policy "$2" --flatten="auditConfigs[].auditLogConfigs" \
        --filter="auditConfigs.service=$s AND auditConfigs.auditLogConfigs.logType=$t" --format="value(auditConfigs.service)"
    else
      nonempty r gcloud projects get-iam-policy "$2" --flatten="auditConfigs[].auditLogConfigs" \
        --filter="auditConfigs.service=$s AND auditConfigs.auditLogConfigs.logType=$t" --format="value(auditConfigs.service)"
    fi
    rcs="$rcs $?"
  done
  # shellcheck disable=SC2086
  cl14_worst $rcs
}

cl14_audit_merge() {    # cl14_audit_merge STEP KIND RESOURCE WANT_JSON TAG: CL-8.2's get, merge, diff, set
  local st="$1" kind="$2" res="$3" want="$4" tag="$5" p0 p1 ex
  p0="$(cl14_rec "$st-$tag-policy-before.json")"; p1="$(cl14_rec "$st-$tag-policy-proposed.json")"
  if [ "$kind" = folder ]; then
    r gcloud resource-manager folders get-iam-policy "$res" --format=json | xw "$p0" || cl14_planok || return 1
  else
    r gcloud projects get-iam-policy "$res" --format=json | xw "$p0" || cl14_planok || return 1
  fi
  if [ "$AGP_MODE" = apply ]; then
    jget etag < "$p0" >/dev/null || { echo "      STOP: the policy of $res has no etag"; return 1; }
    ex="$(cl14_py exempt < "$p0")"
    [ -z "$ex" ] || { echo "      STOP: an existing exemption is a finding to the second human, not something to merge:"; printf '%s\n' "$ex" | sed 's/^/        /'; return 1; }
    cl14_py merge "$want" < "$p0" | xw "$p1" || return 1
    echo "      == $res"; cl14_py diff "$p0" "$p1" | sed 's/^/        /'
    cl14_py only-audit "$p0" "$p1" || { echo "      STOP: the merge changes more than auditConfigs"; return 1; }
  else
    echo "the before policy with the committed auditConfigs merged in (group by service, unique by logType)" | xw "$p1"
  fi
  ev "$st" "$tag-policy-before" E-06 "5.2.4, 4.2.1" "build-log:records/${p0##*/}" "$p0" || return 1
  if [ "$kind" = folder ]; then
    x gcloud resource-manager folders set-iam-policy "$res" "$p1" --format="value(etag)" || return 1
  else
    x gcloud projects set-iam-policy "$res" "$p1" --format="value(etag)" || return 1
  fi
}

# ------------------------------------------------------------------ 1. Workspace audit-log sharing
step CL-1.1 HUMAN "Consult the organisation's Cloud Logging owner and record the organisation's logging state" --needs "ORG_ID EVIDENCE_INTERIM_LOCATION"
s_CL_1_1_check() { ckpt_done CL-1.1; }
s_CL_1_1_manual() {
  echo "WHO: the platform owner asks; the organisation's Cloud Logging owner answers and runs the reads. Not a witness step."
  echo "WHERE: a dated meeting note; the Cloud Logging owner's shell."
  echo "ASK: what consumes Workspace logs today (SIEM, organisation sinks); organisation _Default exclusions; who pays ingestion;"
  echo "     may sharing be turned on, and what would make them turn it off. Their reads:"
  echo "  gcloud logging sinks list --organization=$(v ORG_ID) --format=\"table(name,destination,includeChildren,interceptChildren,disabled,filter)\""
  echo "  gcloud logging sinks describe _Default --organization=$(v ORG_ID) --format=\"yaml(filter,exclusions,disabled)\""
  echo "  gcloud logging buckets list --organization=$(v ORG_ID) --location=global --format=\"table(name,retentionDays,locked)\""
  echo "VERIFY: a table of every pre-existing organisation sink (owner, purpose) and the _Default exclusions; any includeChildren sink"
  echo "        that copies fld-agentic-platform elsewhere named with its owner; the written consent to CL-1.3 attached."
  echo "RECORD: evidence_add CL-1.1 org-logging-consultation E-05 5.2.4 \"$(v EVIDENCE_INTERIM_LOCATION)\". Then: agp-platform done CL-1.1"
}

step CL-1.2 CONSOLE "Read the sharing setting before touching it"
s_CL_1_2_check() { ckpt_done CL-1.2; }
s_CL_1_2_manual() {
  echo "WHO: a super admin (setup/14 People). Solo, in the super-admin browser profile (01 PR-1.3)."
  echo "WHERE: Admin console > Account > Account settings > Legal and compliance > Sharing options."
  echo "DO: read the state. If it is already Enabled, do not touch it: Reporting > Audit and investigation > Admin log events,"
  echo "    find who enabled it and when (or record 'enabler not found in the audit log' and the range searched); CL-1.3 is then N/A."
  echo "RECORD: a dated screenshot as <date>-CL-1.2-sharing-state-v1; the state (and actor, date) in the build log."
  echo "Then: agp-platform done CL-1.2"
}

step CL-1.3 HUMAN "Turn on \"Share data with Google Cloud services\"" --witness
s_CL_1_3_check() { ckpt_done CL-1.3; }
s_CL_1_3_manual() {
  echo "WHO: a super admin, the second human as sa-2-admin@ (Assumption of the page); if sa-1-admin@ does it, the second human witnesses."
  echo "SKIP: if CL-1.2 found it Enabled, record N/A: agp-platform done CL-1.3 --witness <second human> --note 'already enabled (CL-1.2)'."
  echo "WHERE: Admin console > Account > Account settings > Legal and compliance."
  echo "DO: Sharing options > Enabled > Save. Write the UTC time in the build log: the start of every Workspace copy kept."
  echo "VERIFY: Enabled after a reload; Admin log events show the change and actor (or the absence, as in CL-1.2)."
  echo "RECORD: screenshot <date>-CL-1.3-sharing-enabled-v1; the DPO adds 'Workspace logs, region not selectable' to the records of"
  echo "        processing (08 section 7.2). Rolling it back silences every Workspace stream: never without both written agreements."
  echo "Then: agp-platform done CL-1.3 --witness <second human email>"
}

step CL-1.4 HUMAN "Prove the Admin Activity streams at organisation scope" --needs "ORG_ID"
s_CL_1_4_check() { ckpt_done CL-1.4; }
s_CL_1_4_manual() {
  echo "WHO: the organisation's Cloud Logging owner (roles/logging.viewer at the organisation); the platform owner records."
  echo "WHERE: their shell, or Logs Explorer with the organisation as scope. Wait 24 h after CL-1.3 if the first try is empty."
  echo "  gcloud logging read 'logName:\"organizations/$(v ORG_ID)/logs/\" AND protoPayload.serviceName=\"admin.googleapis.com\"' --organization=$(v ORG_ID) --freshness=1d --limit=3 --format=\"table(timestamp,protoPayload.methodName,logName)\""
  echo "  gcloud logging read 'logName:\"organizations/$(v ORG_ID)/logs/\" AND protoPayload.serviceName=\"cloudidentity.googleapis.com\"' --organization=$(v ORG_ID) --freshness=7d --limit=3 --format=\"table(timestamp,protoPayload.methodName)\""
  echo "VERIFY: an Admin row after CL-1.3; a Groups row (else a super admin adds and removes a test member on a non-control group)."
  echo "        Empty after 24 h: sharing off, project scope, or another Cloud organisation: stop and resolve before CL-6."
  echo "RECORD: counts and method names only (no actor emails) as <date>-CL-1.4-admin-streams-v1. Then: agp-platform done CL-1.4"
}

step CL-1.5 HUMAN "Prove the Data Access streams with the right role (S181)" --needs "ORG_ID ENT_ORG_SINK CICD_PROJECT"
s_CL_1_5_check() { ckpt_done CL-1.5; }
s_CL_1_5_manual() {
  echo "WHO: the Cloud Logging owner with roles/logging.privateLogViewer at the organisation; or the platform owner under ENT_ORG_SINK only"
  echo "     if 12's committed bundle lists that role:"
  echo "  gcloud pam entitlements describe $(v ENT_ORG_SINK | sed 's#.*/##') --location=global --organization=$(v ORG_ID) --billing-project=$(v CICD_PROJECT) --format=\"value(privilegedAccess.gcpIamAccess.roleBindings[].role)\""
  echo "  gcloud logging read 'logName:\"organizations/$(v ORG_ID)/logs/cloudaudit.googleapis.com%2Fdata_access\" AND protoPayload.serviceName=\"login.googleapis.com\"' --organization=$(v ORG_ID) --freshness=1d --limit=3 --format=\"table(timestamp,protoPayload.methodName)\""
  echo "  the same read with protoPayload.serviceName=\"oauth2.googleapis.com\" (setup/14 CL-1.5)."
  echo "VERIFY: Login rows present; OAuth token rows present or WORKSPACE_EDITION outside the table (written down); SAML 'not exercised'"
  echo "        when absent. An empty Login result is never an edition problem until the reader's privateLogViewer is confirmed."
  echo "RECORD: counts and the reader's role as <date>-CL-1.5-data-access-streams-v1. Then: agp-platform done CL-1.5"
}

step CL-1.6 HUMAN "Measure one day of Workspace log volume (re-run of 04 PU-5.2)"
s_CL_1_6_check() { ckpt_done CL-1.6; }
s_CL_1_6_manual() {
  echo "WHO: the organisation's Cloud Logging owner; the platform owner records. WHERE: their shell, 24 h or more after CL-1.3."
  echo "DO: run the five commands of setup/04 PU-5.2 unchanged (counts piped to wc, nothing stored)."
  echo "VERIFY: four counts and one byte figure recorded with the date; the estimate sent to finance (LOGGING_PROJECT budget line)"
  echo "        and to the DPO (size of the identity store); PU-5.2's 'not measurable' line, if any, closed in the re-run index."
  echo "RECORD: <date>-CL-1.6-workspace-log-volume-v1 (numbers only). Then: agp-platform done CL-1.6"
}

# ------------------------------------------------------------------ 2. The sitting, the key and the log buckets
step CL-2.1 HUMAN "Open the sitting and request the project and folder grants" --needs "ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CORE CICD_PROJECT LOGGING_PROJECT BILLING_ACCOUNT_ID"
s_CL_2_1_check() { ckpt_done CL-2.1; }
s_CL_2_1_manual() {
  local fa pr
  fa="$(v ENT_FOLDER_ADMIN)"; pr="$(v ENT_PROJECT_REPAIR_CORE)"
  echo "WHO: the platform owner requests (agp-platform sitting start); each approver as file 12 recorded approves in PAM."
  echo "DO: the two requests of setup/14 CL-2.1 (pam_req is defined for the sitting only):"
  echo "  gcloud pam grants create --entitlement=${fa##*/} --requested-duration=3600s --justification=\"14 CL-2 to CL-5: log buckets, views, fan-out sinks in LOGGING_PROJECT\" --location=global $(cl14_pam_flag "$fa") --billing-project=$(v CICD_PROJECT) --format=\"value(name,state)\""
  echo "  gcloud pam grants create --entitlement=${pr##*/} --requested-duration=7200s --justification=\"14 CL-2 to CL-5: BigQuery datasets and dataset grants in LOGGING_PROJECT\" --location=global $(cl14_pam_flag "$pr") --billing-project=$(v CICD_PROJECT) --format=\"value(name,state)\""
  echo "  gcloud services list --enabled --project=$(v LOGGING_PROJECT) --format=\"value(config.name)\" | grep -E '^(logging|bigquery|cloudkms)\\.googleapis\\.com\$'"
  echo "  gcloud billing projects describe $(v LOGGING_PROJECT) --format=\"value(billingAccountName,billingEnabled)\""
  echo "VERIFY: gcloud pam grants describe <grant> --billing-project=$(v CICD_PROJECT) --format=\"value(state)\" prints ACTIVE for both;"
  echo "        the three APIs listed (note whether 13 OP-8.4 has run); billingAccounts/$(v BILLING_ACCOUNT_ID) True. A grant left"
  echo "        APPROVAL_AWAITED past the sitting is withdrawn and the sitting rescheduled; nothing below runs on a standing role."
  echo "RECORD: grant names and states in the build log. Then: agp-platform done CL-2.1"
}

step CL-2.2 AUTO-READ "Check that Logging's key service account can use KEY_PLATFORM_LOGS" \
  --needs "LOGGING_PROJECT KEY_PLATFORM_LOGS KMS_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_2_2_check() { ckpt_done CL-2.2; }
s_CL_2_2_apply() {
  local lp key kp sa pol others rc bad=0
  lp="$(v LOGGING_PROJECT)"; key="$(v KEY_PLATFORM_LOGS)"; kp="$(v KMS_PROJECT)"
  sa="$(cl14_r gcloud logging settings describe --project="$lp" --format='value(kmsServiceAccountId)')" || cl14_planok || { echo "      STOP: cannot read the Logging settings of $lp"; return 1; }
  [ "$AGP_MODE" = apply ] || sa="<LOG_KMS_SA>"
  echo "      LOG_KMS_SA=$sa"
  { echo "LOG_KMS_SA=$sa"
    cl14_r gcloud kms keys describe "$key" --project="$kp" --format="yaml(name,primary.state,primary.protectionLevel)"
    cl14_r gcloud kms keys get-iam-policy "$key" --project="$kp" --flatten="bindings[].members" --format="table(bindings.role,bindings.members)"
  } | cl14_keep CL-2.2 logging-key E-05 5.1 txt || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  [ -n "$sa" ] || { echo "      STOP: kmsServiceAccountId is empty"; return 1; }
  case "$key" in */locations/europe-west1/keyRings/logging/cryptoKeys/*) ;; *) echo "      key name does not contain locations/europe-west1/keyRings/logging"; bad=1;; esac
  cl14_key_enabled_hsm "$key" || { echo "      $key is not ENABLED with protection level HSM"; bad=1; }
  nonempty r gcloud kms keys get-iam-policy "$key" --project="$kp" --flatten="bindings[].members" \
    --filter="bindings.role=roles/cloudkms.cryptoKeyEncrypterDecrypter AND bindings.members=\"serviceAccount:$sa\"" --format="value(bindings.members)"; rc=$?
  if [ $rc -ne 0 ]; then
    echo "      serviceAccount:$sa does not hold roles/cloudkms.cryptoKeyEncrypterDecrypter on the key: the key's owner adds it (11's re-run):"
    echo "        gcloud kms keys add-iam-policy-binding $key --member=\"serviceAccount:$sa\" --role=\"roles/cloudkms.cryptoKeyEncrypterDecrypter\" --project=$kp"
    bad=1
  fi
  pol="$(r gcloud kms keys get-iam-policy "$key" --project="$kp" --format=json)" || return 1
  others="$(printf '%s' "$pol" | cl14_py key-others "serviceAccount:$sa")"
  [ -z "$others" ] || { echo "      other members can encrypt or decrypt with the key:"; printf '%s\n' "$others" | sed 's/^/        /'; bad=1; }
  [ $bad = 0 ] || echo "      CL-2.3 does not start until this step passes"
  return $bad
}

cl14_key_enabled_hsm() {    # cl14_key_enabled_hsm KEY: ENABLED and HSM (CL-2.2 VERIFY), as a filtered list of its ring
  nonempty r gcloud kms keys list --keyring="${1%/cryptoKeys/*}" --project="$(v KMS_PROJECT)" \
    --filter="name=\"$1\" AND primary.state=ENABLED AND primary.protectionLevel=HSM" --format="value(name)"
}

step CL-2.5 AUTO "Prove what a locked bucket still allows, and that CMEK with Log Analytics is accepted, on a throwaway bucket" \
  --irreversible --removes --needs "LOGGING_PROJECT REGION KEY_PLATFORM_LOGS BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_2_5_check() {
  local f; f="$(cl14_last 'CL-2.5-lock-and-cmek-behaviour-v1.txt')" || return 1
  grep -q '^CMEK+analytics accepted' "$f"
}
s_CL_2_5_apply() {
  cl14_under "the ENT_FOLDER_ADMIN grant of CL-2.1 (request it again if it has expired)"
  local t lp rg key f desc ok=0 rc_c rc_l=- rc_v=- rc_r=- rc_d
  lp="$(v LOGGING_PROJECT)"; rg="$(v REGION)"; key="$(v KEY_PLATFORM_LOGS)"
  if [ "$AGP_MODE" = apply ] && f="$(cl14_last 'CL-2.5-lock-and-cmek-behaviour-v1.txt')" && grep -q '^REFUSED' "$f"; then
    echo "      STOP: $f records a refusal: the second human signs the choice of CL-2.5's VERIFY before CL-2.3; no new probe"; return 1
  fi
  if cl14_ckpt_has CL-5.2 DONE || cl14_ckpt_has CL-6.2 DONE; then cl14_stop "a sink of CL-5 or CL-6 exists: the throwaway must run before them" "no sink of CL-5 or CL-6 exists yet" || return 1; fi
  t="cl-lock-test-$(date -u +%Y%m%d)"
  x gcloud logging buckets create "$t" --location="$rg" --retention-days=1 --cmek-kms-key-name="$key" --enable-analytics \
    --description="Throwaway probe of CMEK + Log Analytics + locking (14 CL-2.5); delete same day" --project="$lp"; rc_c=$?
  desc="$(r gcloud logging buckets describe "$t" --location="$rg" --project="$lp" --format="yaml(name,retentionDays,analyticsEnabled,cmekSettings.kmsKeyName,lifecycleState)" 2>&1)"
  if [ "$AGP_MODE" = apply ] && [ $rc_c -eq 0 ] \
    && nonempty r gcloud logging buckets list --location="$rg" --project="$lp" --filter="name~\"/buckets/$t\$\" AND analyticsEnabled=true AND cmekSettings.kmsKeyName=\"$key\"" --format="value(name)"; then
    ok=1
  fi
  if [ "$AGP_MODE" != apply ] || [ $ok = 1 ]; then
    agp_say "      before the lock line: the name starts cl-lock-test-, retention 1 day, project $lp, no sink names it (CL-5 and CL-6 not run)"
    x gcloud logging buckets update "$t" --location="$rg" --locked --project="$lp"; rc_l=$?
    x gcloud logging views create probe --bucket="$t" --location="$rg" --log-filter='LOG_ID("cloudaudit.googleapis.com/activity")' --project="$lp"; rc_v=$?
    x gcloud logging buckets update "$t" --location="$rg" --retention-days=2 --project="$lp"; rc_r=$?
  fi
  agp_say "      no --quiet on the delete: if gcloud asks for confirmation, read the bucket name ($t) in the prompt and answer it"
  x gcloud logging buckets delete "$t" --location="$rg" --project="$lp"; rc_d=$?
  { echo "bucket: $t"
    echo "create exit $rc_c"; echo "lock exit $rc_l"; echo "view create exit $rc_v"; echo "retention increase exit $rc_r"; echo "delete exit $rc_d"
    echo "describe:"; printf '%s\n' "$desc"
    if [ $ok = 1 ]; then echo "CMEK+analytics accepted"
    else echo "REFUSED: the throwaway was not created with analyticsEnabled true and the key; CL-2.3 does not run as written"; fi
    [ "$rc_v" = 0 ] || echo "views after a lock: refused or not tried: CL-3.1 creates every view before CL-10; 17's per-agent views move to per-tier unlocked buckets"
    [ "$rc_d" = 0 ] || echo "the delete was refused: the bucket persists for its 1-day retention and is deleted the next day (build-log line, not a finding)"
  } | cl14_keep CL-2.5 lock-and-cmek-behaviour E-05 "5.2.4, 5.1" txt || return 1
  [ "$AGP_MODE" = apply ] || return 0
  if [ $ok = 0 ]; then
    echo "      STOP: record which of CMEK or analytics the tenant refuses and raise it with the second human; the signed choice is the"
    echo "      CMEK-only bucket (drop --enable-analytics, a DEVIATION_REGISTER line against 08 S12), never the analytics-only bucket"
    return 1
  fi
  [ "$rc_v" = 0 ] || echo "      write into the re-run index: views after a lock refused (CL-3.1 before CL-10; 17 per-tier buckets)"
  echo "      tell the second human the result before CL-2.3, and again before CL-10"
}

step CL-2.3 AUTO "Create platform-evidence-logs" --irreversible --gate "NAMES KEYS" \
  --needs "LOGGING_PROJECT REGION KEY_PLATFORM_LOGS BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "LOG_BUCKET_EVIDENCE"
cl14_evb_filter() { printf 'analyticsEnabled=true AND cmekSettings.kmsKeyName="%s" AND NOT locked=true' "$(v KEY_PLATFORM_LOGS)"; }
s_CL_2_3_check() {   # every read runs, so the probe the apply uses and the verification are taken together
  local a b
  cl14_probe EVB gcloud logging buckets describe platform-evidence-logs --location="$(v REGION)" --project="$(v LOGGING_PROJECT)" --format="value(name)"; a=$?
  cl14_bucket_ok platform-evidence-logs "$(cl14_evb_filter)"; b=$?
  has_value LOG_BUCKET_EVIDENCE || b=$(( b > 1 ? b : 1 ))
  cl14_worst $a $b
}
cl14_bucket_pre() {     # the confirmations of CL-2.3 and CL-2.4 that the script can read
  local f
  [ "$(v REGION)" = europe-west1 ] || { cl14_stop "REGION is $(v REGION), not europe-west1" "REGION is europe-west1" || return 1; }
  ckpt_done CL-2.2 || { cl14_stop "CL-2.2 (the key policy table) is not DONE" "CL-2.2 DONE (the key policy table)" || return 1; }
  if f="$(cl14_last 'CL-2.5-lock-and-cmek-behaviour-v1.txt')" && grep -q '^CMEK+analytics accepted' "$f"; then
    [ "$AGP_MODE" = apply ] && echo "      $f: CMEK+analytics accepted"
  else
    cl14_stop "CL-2.5 did not record \"CMEK+analytics accepted\" on the throwaway" "CL-2.5 recorded \"CMEK+analytics accepted\" on the throwaway" || return 1
  fi
  return 0
}
s_CL_2_3_apply() {
  cl14_under "the ENT_FOLDER_ADMIN grant of CL-2.1 (request it again if it has expired)"
  local lp rg key rc made=0
  lp="$(v LOGGING_PROJECT)"; rg="$(v REGION)"; key="$(v KEY_PLATFORM_LOGS)"
  cl14_bucket_pre || return 1
  cl14_probed EVB gcloud logging buckets describe platform-evidence-logs --location="$rg" --project="$lp" --format="value(name)"; rc=$?
  case $rc in
    0) [ "$AGP_MODE" = apply ] && echo "      platform-evidence-logs exists: not created again";;
    1|3) x gcloud logging buckets create platform-evidence-logs --location="$rg" --retention-days=400 --cmek-kms-key-name="$key" --enable-analytics \
           --description="Platform evidence: folder audit families, organisation-level entries, billing-account audit log (08 S12)" --project="$lp" || return 1
         made=1;;
    *) return 1;;
  esac
  pset LOG_BUCKET_EVIDENCE "projects/${lp}/locations/${rg}/buckets/platform-evidence-logs" || return 1
  r gcloud logging buckets describe platform-evidence-logs --location="$rg" --project="$lp" --format="yaml(name,retentionDays,locked,analyticsEnabled,cmekSettings.kmsKeyName,lifecycleState)" \
    | cl14_keep CL-2.3 evidence-bucket E-06 "5.2.4, 5.1" yaml || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  cl14_bucket_ok platform-evidence-logs "$(cl14_evb_filter)" || { echo "      STOP: not ACTIVE in $rg with analytics, the key and unlocked"; return 1; }
  if [ $made = 1 ]; then cl14_bucket_ok platform-evidence-logs "retentionDays=400" || { echo "      STOP: retentionDays is not 400"; return 1; }; fi
}

cl14_id_days() {    # the identity bucket's creation retention: 400, or P13's signed value if already set
  local d; d="$(_penv_get IDENTITY_RETENTION_DAYS 2>/dev/null)"
  case "$d" in ''|'*tbd*'|*'<'*) echo 400;; *[!0-9]*) return 1;; *) echo "$d";; esac
}

step CL-2.4 AUTO "Create platform-identity-logs" --irreversible --gate "NAMES KEYS" \
  --needs "LOGGING_PROJECT REGION KEY_PLATFORM_LOGS BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "LOG_BUCKET_IDENTITY"
cl14_idb_filter() { printf 'NOT analyticsEnabled=true AND cmekSettings.kmsKeyName="%s" AND NOT locked=true' "$(v KEY_PLATFORM_LOGS)"; }
s_CL_2_4_check() {
  local a b
  cl14_probe IDB gcloud logging buckets describe platform-identity-logs --location="$(v REGION)" --project="$(v LOGGING_PROJECT)" --format="value(name)"; a=$?
  cl14_bucket_ok platform-identity-logs "$(cl14_idb_filter)"; b=$?
  has_value LOG_BUCKET_IDENTITY || b=$(( b > 1 ? b : 1 ))
  cl14_worst $a $b
}
s_CL_2_4_apply() {
  cl14_under "the ENT_FOLDER_ADMIN grant of CL-2.1 (request it again if it has expired)"
  local lp rg key rc made=0 days
  lp="$(v LOGGING_PROJECT)"; rg="$(v REGION)"; key="$(v KEY_PLATFORM_LOGS)"
  days="$(cl14_id_days)" || { echo "      STOP: IDENTITY_RETENTION_DAYS is not an integer"; return 1; }
  cl14_bucket_pre || return 1
  cl14_probed IDB gcloud logging buckets describe platform-identity-logs --location="$rg" --project="$lp" --format="value(name)"; rc=$?
  case $rc in
    0) [ "$AGP_MODE" = apply ] && echo "      platform-identity-logs exists: not created again";;
    1|3) x gcloud logging buckets create platform-identity-logs --location="$rg" --retention-days="$days" --cmek-kms-key-name="$key" \
           --description="Login, SAML and OAuth-token Data Access entries of every tenant account (08 S13); readers through the identity view only" --project="$lp" || return 1
         made=1;;
    *) return 1;;
  esac
  pset LOG_BUCKET_IDENTITY "projects/${lp}/locations/${rg}/buckets/platform-identity-logs" || return 1
  r gcloud logging buckets describe platform-identity-logs --location="$rg" --project="$lp" --format="yaml(name,retentionDays,locked,analyticsEnabled,cmekSettings.kmsKeyName,lifecycleState)" \
    | cl14_keep CL-2.4 identity-bucket E-06 "5.2.4, 7.1" yaml || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  cl14_bucket_ok platform-identity-logs "$(cl14_idb_filter)" || { echo "      STOP: not ACTIVE in $rg on the key, without analytics, unlocked"; return 1; }
  if [ $made = 1 ]; then cl14_bucket_ok platform-identity-logs "retentionDays=$days" || { echo "      STOP: retentionDays is not $days"; return 1; }; fi
}

# ------------------------------------------------------------------ 3. Log views and their readers
cl14_views() { echo "platform-evidence-logs:security platform-evidence-logs:siem platform-evidence-logs:ge-requests platform-identity-logs:identity"; }

step CL-3.1 AUTO "Create the four views" --needs "LOGGING_PROJECT REGION GEMINI_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_3_1_check() {
  local t rcs=""
  for t in $(cl14_views); do
    cl14_probe "V_$(printf '%s' "${t#*:}" | tr '-' '_')" gcloud logging views describe "${t#*:}" --bucket="${t%%:*}" --location="$(v REGION)" --project="$(v LOGGING_PROJECT)" --format="value(name)"
    rcs="$rcs $?"
  done
  # shellcheck disable=SC2086
  cl14_worst $rcs
}
cl14_view_create() {    # cl14_view_create BUCKET VIEW: the page's create line for VIEW
  local lp rg; lp="$(v LOGGING_PROJECT)"; rg="$(v REGION)"
  case "$2" in
    security) x gcloud logging views create security --bucket="$1" --location="$rg" --description="Everything; platform-security@ (08 §3.3)" --project="$lp";;
    siem) x gcloud logging views create siem --bucket="$1" --location="$rg" --description="Everything; the SIEM ingestion principal (P10)" --project="$lp";;
    ge-requests) x gcloud logging views create ge-requests --bucket="$1" --location="$rg" \
      --log-filter='SOURCE("projects/'"$(v GEMINI_PROJECT)"'") AND LOG_ID("cloudaudit.googleapis.com/data_access")' --description="Gemini Enterprise Data Access entries (03 §13)" --project="$lp";;
    identity) x gcloud logging views create identity --bucket="$1" --location="$rg" --description="Login, SAML, OAuth-token Data Access; security reviewer, eve-verifier@, SIEM; no agent owner" --project="$lp";;
  esac
}
s_CL_3_1_apply() {
  cl14_under "the ENT_FOLDER_ADMIN grant of CL-2.1 (request it again if it has expired)"
  local t b w rc lp rg
  lp="$(v LOGGING_PROJECT)"; rg="$(v REGION)"
  for t in $(cl14_views); do
    b="${t%%:*}"; w="${t#*:}"
    cl14_probed "V_$(printf '%s' "$w" | tr '-' '_')" gcloud logging views describe "$w" --bucket="$b" --location="$rg" --project="$lp" --format="value(name)"; rc=$?
    case $rc in
      0) [ "$AGP_MODE" = apply ] && echo "      view $w on $b exists: not created again";;
      1|3) cl14_view_create "$b" "$w" || return 1;;
      *) return 1;;
    esac
  done
  { r gcloud logging views list --bucket=platform-evidence-logs --location="$rg" --project="$lp" --format="table(name,filter)"
    r gcloud logging views list --bucket=platform-identity-logs --location="$rg" --project="$lp" --format="table(name,filter)"
  } | cl14_keep CL-3.1 log-views E-06 "4.2.1, 5.2.4" txt || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] && echo "      the evidence bucket lists _AllLogs, security, siem, ge-requests; the identity bucket _AllLogs and identity; nobody is bound to _AllLogs"
  return 0
}

cl14_id_reader() {  # the identity view's reader: the security reviewer when appointed, else the second human
  if has_value SECURITY_REVIEWER_EMAIL; then printf 'user:%s' "$(v SECURITY_REVIEWER_EMAIL)"; else printf 'user:%s' "$(v SECOND_HUMAN_EMAIL)"; fi
}
cl14_readers() {     # MEMBER|BUCKET|VIEW tokens, one per reader of CL-3.2
  echo "group:$(v GRP_PLATFORM_SECURITY)|platform-evidence-logs|security group:$(v GRP_PLATFORM_SECURITY)|platform-evidence-logs|ge-requests group:$(v GRP_GE_ADMINS)|platform-evidence-logs|ge-requests $(cl14_id_reader)|platform-identity-logs|identity"
}
cl14_tok() { echo "$1" | cut -d'|' -f"$2"; }   # cl14_tok TOKEN N: field N of a MEMBER|BUCKET|VIEW token

step CL-3.2 AUTO "Bind the readers that exist" --needs "LOGGING_PROJECT REGION GRP_PLATFORM_SECURITY GRP_GE_ADMINS SECOND_HUMAN_EMAIL BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_3_2_check() {
  local t rcs=""
  for t in $(cl14_readers); do cl14_view_bound "$(cl14_tok "$t" 1)" "$(cl14_tok "$t" 2)" "$(cl14_tok "$t" 3)"; rcs="$rcs $?"; done
  # shellcheck disable=SC2086
  cl14_worst $rcs
}
s_CL_3_2_apply() {
  cl14_under "the ENT_FOLDER_ADMIN grant of CL-2.1 (request it again if it has expired)"
  local t m b w lp un
  lp="$(v LOGGING_PROJECT)"
  for t in $(cl14_readers); do
    m="$(cl14_tok "$t" 1)"; b="$(cl14_tok "$t" 2)"; w="$(cl14_tok "$t" 3)"
    if [ "$AGP_MODE" != apply ] || ! cl14_view_bound "$m" "$b" "$w"; then
      x gcloud projects add-iam-policy-binding "$lp" --member="$m" --role="roles/logging.viewAccessor" --condition="$(cl14_vcond "$b" "$w")" || return 1
    fi
  done
  r gcloud projects get-iam-policy "$lp" --flatten="bindings[].members" --filter="bindings.role=roles/logging.viewAccessor" \
    --format="table(bindings.members,bindings.condition.expression)" | cl14_keep CL-3.2 view-readers E-06 "4.2.1, 7.1" txt || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  # VERIFY "no unconditioned roles/logging.viewAccessor", as a filtered list that must print nothing (rule 4)
  un="$(r gcloud projects get-iam-policy "$lp" --flatten="bindings[].members" \
    --filter="bindings.role=roles/logging.viewAccessor AND NOT bindings.condition:*" --format="value(bindings.members)")" \
    || { echo "      STOP: the policy of $lp could not be read"; return 1; }
  [ -z "$un" ] || { echo "      STOP: unconditioned roles/logging.viewAccessor on $lp: $un"; return 1; }
  has_value SECURITY_REVIEWER_EMAIL || echo "      the second human is the interim identity reader: tell them; CL-3.4 records the re-run"
}

cl14_sa_exists() {  # cl14_sa_exists EMAIL: the service account exists (in the project its address names)
  local p="${1#*@}"; p="${p%.iam.gserviceaccount.com}"
  exists gcloud iam service-accounts describe "$1" --project="$p" --format="value(email)"
}

CL14_EVE_PH="serviceAccount:eve-verifier@EVE_PROJECT.iam.gserviceaccount.com"
CL14_SIEM_PH="serviceAccount:SIEM_INGEST_PRINCIPAL"
CL14_MO_PH="serviceAccount:mo-metrics@MO_PROJECT.iam.gserviceaccount.com"

step CL-3.3 AUTO "Record the readers that do not exist yet as PENDING" --needs "LOGGING_PROJECT REGION BUILD_LOG_DIR"
s_CL_3_3_check() {
  local a=0 b=0
  if has_value SA_EVE_VERIFIER; then
    cl14_view_bound "serviceAccount:$(v SA_EVE_VERIFIER)" platform-identity-logs identity; a=$?
    [ $a -eq 0 ] || ! cl14_rerun_has CL-3.3 "serviceAccount:$(v SA_EVE_VERIFIER)" || a=0
  else cl14_rerun_has CL-3.3 "$CL14_EVE_PH"; a=$?; fi
  if has_value SIEM_INGEST_PRINCIPAL; then
    cl14_view_bound "serviceAccount:$(v SIEM_INGEST_PRINCIPAL)" platform-identity-logs identity; b=$?
    [ $b -ne 0 ] || { cl14_view_bound "serviceAccount:$(v SIEM_INGEST_PRINCIPAL)" platform-evidence-logs siem; b=$?; }
    [ $b -eq 0 ] || ! cl14_rerun_has CL-3.3 "serviceAccount:$(v SIEM_INGEST_PRINCIPAL)" || b=0
  else cl14_rerun_has CL-3.3 "$CL14_SIEM_PH"; b=$?; fi
  cl14_worst $a $b
}
cl14_grant_view() { # cl14_grant_view MEMBER BUCKET VIEW: the CL-3.2 form for a principal that exists now
  [ "$AGP_MODE" = apply ] && cl14_view_bound "$1" "$2" "$3" && return 0
  x gcloud projects add-iam-policy-binding "$(v LOGGING_PROJECT)" --member="$1" --role="roles/logging.viewAccessor" --condition="$(cl14_vcond "$2" "$3")"
}
cl14_principal() {  # cl14_principal VAR PLACEHOLDER STEP WHAT_WHEN_EXISTS WHAT_PENDING: 0 exists, 1 recorded PENDING, 2 stop
  local rc
  if has_value "$1"; then
    cl14_sa_exists "$(v "$1")"; rc=$?
    case $rc in
      0|3) return 0;;
      1) cl14_rerun_has "$3" "serviceAccount:$(v "$1")" || cl14_xpending "serviceAccount:$(v "$1")" "$3" "$4" || return 2; return 1;;
      *) return 2;;
    esac
  fi
  cl14_rerun_has "$3" "$2" || cl14_xpending "$2" "$3" "$5" || return 2
  return 1
}
s_CL_3_3_apply() {
  local rc
  cl14_principal SA_EVE_VERIFIER "$CL14_EVE_PH" CL-3.3 "14 CL-3.3: viewAccessor on identity view" "14 CL-3.3: viewAccessor on identity view (after 24)"; rc=$?
  case $rc in 0) cl14_grant_view "serviceAccount:$(v SA_EVE_VERIFIER)" platform-identity-logs identity || return 1;; 2) return 1;; esac
  cl14_principal SIEM_INGEST_PRINCIPAL "$CL14_SIEM_PH" CL-3.3 "14 CL-3.3: viewAccessor on siem and identity views" "14 CL-3.3: viewAccessor on siem and identity views (after 15 part B)"; rc=$?
  case $rc in
    0) cl14_grant_view "serviceAccount:$(v SIEM_INGEST_PRINCIPAL)" platform-identity-logs identity || return 1
       cl14_grant_view "serviceAccount:$(v SIEM_INGEST_PRINCIPAL)" platform-evidence-logs siem || return 1;;
    2) return 1;;
  esac
  return 0
}

step CL-3.4 AUTO "Record the security reviewer's identity binding as a re-run" --needs "BUILD_LOG_DIR"
s_CL_3_4_check() { cl14_ckpt_has CL-3.4 PENDING || cl14_ckpt_has CL-3.4 N/A; }
s_CL_3_4_apply() {
  if has_value SECURITY_REVIEWER_EMAIL; then
    x checkpoint CL-3.4 N/A - - "CL-3.2 bound the security reviewer to the identity view"
    return
  fi
  x checkpoint CL-3.4 PENDING - - "security reviewer to identity view; interim second human to be unbound" || return 1
  cl14_rerun_has CL-3.4 "user:SECURITY_REVIEWER_EMAIL" \
    || cl14_xpending "user:SECURITY_REVIEWER_EMAIL" CL-3.4 "14 CL-3.2: bind the security reviewer to identity, then unbind the interim second human (DPO informed)"
}

step CL-3.5 HUMAN "Prove that nobody reads every view" --witness --needs "LOGGING_PROJECT FLD_AGENTIC_PLATFORM ORG_ID BUILD_LOG_DIR"
s_CL_3_5_check() { ckpt_done CL-3.5; }
s_CL_3_5_manual() {
  echo "WHO: the platform owner runs the three reads; the second human reads the three files and signs the folder and organisation ones."
  echo "WHERE: shell; the folder read under CL-2.1's ENT_FOLDER_ADMIN grant, the organisation read the second human's (or ENT_ORG_SINK's"
  echo "       if 12's committed bundle carries resourcemanager.organizations.getIamPolicy: read it first and record which)."
  echo "DO: setup/14 CL-3.5's block as written: D=\"$(v BUILD_LOG_DIR)/records/\$(date -u +%Y-%m-%d)-CL-3.5\", then"
  echo "  gcloud projects get-iam-policy $(v LOGGING_PROJECT) / gcloud resource-manager folders get-iam-policy $(v FLD_AGENTIC_PLATFORM) /"
  echo "  gcloud organizations get-iam-policy $(v ORG_ID), each --flatten=\"bindings[].members\" --format=\"table(bindings.role,bindings.members,bindings.condition.title)\","
  echo "  into \${D}-project.txt, -folder.txt, -org.txt, and the grep of R for owner, editor, viewer and the four logging roles."
  echo "VERIFY: on the project only CL-3.2's conditioned viewAccessor rows; on folder and organisation 'matching rows: 0' (any standing"
  echo "        holder but gcp-organization-admins@ is a finding to the second human the same day)."
  echo "RECORD: the three files as <date>-CL-3.5-no-standing-log-readers-v1, signed; then: agp-platform done CL-3.5 --witness <second human>"
}

# ------------------------------------------------------------------ 4. The BigQuery datasets
step CL-4.1 AUTO "Decide the datasets' encryption from what exists, not from the design alone" --irreversible \
  --needs "FLD_PLATFORM_CORE FLD_AGENTIC_PLATFORM LOGGING_PROJECT KMS_PROJECT DEVIATION_REGISTER BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "KMS_KEY_BQ_LOGS"
s_CL_4_1_check() {
  local f; f="$(cl14_last 'CL-4.1-dataset-encryption-v1.txt')" || return 1
  if grep -q '^branch: a' "$f"; then has_value KMS_KEY_BQ_LOGS; return; fi
  grep -q '^branch: b' "$f" && cl14_bd_has BD-14-01
}
cl14_ak_names_kms() {   # cl14_ak_names_kms JSON: the Autokey configuration names KMS_PROJECT as its key project
  local kp; kp="$(printf '%s' "$1" | cl14_py ak-project 2>/dev/null)"
  [ "$kp" = "projects/$(v KMS_PROJECT)" ] && return 0
  has_value KMS_PROJECT_NUMBER && [ "$kp" = "projects/$(v KMS_PROJECT_NUMBER)" ]
}
s_CL_4_1_apply() {
  local fpc fap br=b
  fpc="$(cl14_r gcloud kms autokey-config describe --folder="$(v FLD_PLATFORM_CORE)" --billing-project="$(v KMS_PROJECT)" --format=json 2>&1)"
  fap="$(cl14_r gcloud kms autokey-config describe --folder="$(v FLD_AGENTIC_PLATFORM)" --billing-project="$(v KMS_PROJECT)" --format=json 2>&1)"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      branch (a) when either configuration names KMS_PROJECT as its key project (expected: 11 KV-6.3); then:"
    cl14_kh platform_logs; pset KMS_KEY_BQ_LOGS "$CL14_KEY"
    agp_say "      branch (b) otherwise (not expected): no key, and the deviation row BD-14-01 of setup/14 CL-4.1 (b):"
    cl14_dev_b_row
    echo "both autokey-config describe outputs and the branch" | cl14_keep CL-4.1 dataset-encryption E-05 5.1 txt
    return 0
  fi
  if cl14_ak_names_kms "$fpc" || cl14_ak_names_kms "$fap"; then br=a; fi
  if [ $br = a ]; then
    cl14_kh platform_logs || return 1
    cl14_key_enabled "$CL14_KEY" || { echo "      STOP: $CL14_KEY is not ENABLED; no dataset is created"; return 1; }
    pset KMS_KEY_BQ_LOGS "$CL14_KEY" || return 1
  fi
  { echo "== fld-platform-core ($(v FLD_PLATFORM_CORE))"; printf '%s\n' "$fpc"
    echo "== fld-agentic-platform ($(v FLD_AGENTIC_PLATFORM))"; printf '%s\n' "$fap"
    echo "branch: $br"
    if [ $br = a ]; then echo "key kh-platform_logs: $CL14_KEY"; fi
  } | cl14_keep CL-4.1 dataset-encryption E-05 5.1 txt || return 1
  [ $br = a ] && return 0
  echo "      branch (b), not expected: 11 KV-6.3 did not configure fld-platform-core; recorded with the deviation (setup/14 CL-4.1 (b))."
  echo "      CL-4.2, CL-4.3 and CL-9.1 will create Google-managed datasets: if that is not wanted, do not confirm CL-4.2 and"
  echo "      raise 11 KV-6.3 with the second human before any dataset exists."
  cl14_dev_b_row || return 1
  cl14_bd_has BD-14-01 || { echo "      STOP: BD-14-01 is not in DEVIATION_REGISTER"; return 1; }
}
cl14_dev_b_row() {  # setup/14 CL-4.1 (b): the BD-14-01 row, cell for cell
  cl14_bd_insert BD-14-01 "$(printf '| BD-14-01 | %s | 14 CL-4.1 | DEV | platform_logs, platform_logs_views and BILLING_EXPORT_DS Google-managed, against 09 §2.2; reason: no Autokey on fld-platform-core, and the default key must exist before the sink creates its tables; owner platform owner | %s | CL-4.1 record (both autokey-config describe outputs) | three datasets with Google-managed encryption (CL-4.2, CL-4.3, CL-9.1) | n/a | n/a | platform owner; raised with the second human before CL-4.2 (11 KV-6.3 not run) | closed by recreating under a signed change only if the key table is amended | open |' "$(date -u +%F)" "projects/$(v LOGGING_PROJECT)")"
}

cl14_kms_branch() { has_value KMS_KEY_BQ_LOGS; }   # branch (a) of CL-4.1; *tbd* or empty is branch (b)

step CL-4.2 AUTO "Create platform_logs with its 400-day partition expiry, before any sink" --irreversible --gate "NAMES" \
  --needs "LOGGING_PROJECT BQ_LOCATION BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "PLATFORM_LOGS_DS"
s_CL_4_2_check() {
  cl14_probe PL bq show --format=prettyjson "$(cl14_dsref platform_logs)" || return $?
  has_value PLATFORM_LOGS_DS
}
s_CL_4_2_apply() {
  cl14_under "the ENT_PROJECT_REPAIR_CORE grant of CL-2.1 (request it again if it has expired)"
  local rc key=- kf=""
  ckpt_done CL-4.1 || { cl14_stop "CL-4.1's branch is not recorded" "CL-4.1 DONE (the encryption branch recorded)" || return 1; }
  [ "$(v BQ_LOCATION)" = EU ] || { cl14_stop "BQ_LOCATION is $(v BQ_LOCATION), not EU" "BQ_LOCATION is EU" || return 1; }
  if cl14_kms_branch; then key="$(v KMS_KEY_BQ_LOGS)"; kf="--default_kms_key=$key"; fi
  cl14_probed PL bq show --format=prettyjson "$(cl14_dsref platform_logs)"; rc=$?
  case $rc in
    0) [ "$AGP_MODE" = apply ] && echo "      platform_logs exists: not created again";;
    1|3) # shellcheck disable=SC2086
         x bq --location="$(v BQ_LOCATION)" mk --dataset --default_partition_expiration=34560000 \
           --description="Central audit copy for SQL: folder audit families and organisation-level entries, identity services excluded (08 S14)" \
           --label=agp-store:s14 $kf "$(cl14_dsref platform_logs)" || return 1;;
    *) return 1;;
  esac
  pset PLATFORM_LOGS_DS platform_logs || return 1
  cl14_dataset CL-4.2 platform-logs-dataset E-06 "5.2.4, 1.3.1" platform_logs 34560000000 "$key"
}

step CL-4.3 AUTO "Create platform_logs_views" --irreversible --gate "NAMES" \
  --needs "LOGGING_PROJECT BQ_LOCATION BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "PLATFORM_LOGS_VIEWS_DS KMS_KEY_BQ_VIEWS"
s_CL_4_3_check() {
  cl14_probe PLV bq show --format=prettyjson "$(cl14_dsref platform_logs_views)" || return $?
  has_value PLATFORM_LOGS_VIEWS_DS
}
s_CL_4_3_apply() {
  cl14_under "the ENT_PROJECT_REPAIR_CORE grant of CL-2.1 (request it again if it has expired)"
  local rc key=- kf=""
  ckpt_done CL-4.1 || { cl14_stop "CL-4.1's branch is not recorded" "CL-4.1 DONE (the encryption branch recorded)" || return 1; }
  [ "$(v BQ_LOCATION)" = EU ] || { cl14_stop "BQ_LOCATION is $(v BQ_LOCATION), not EU" "BQ_LOCATION is EU" || return 1; }
  cl14_probed PLV bq show --format=prettyjson "$(cl14_dsref platform_logs_views)"; rc=$?
  case $rc in
    0) [ "$AGP_MODE" = apply ] && echo "      platform_logs_views exists: not created again"
       has_value KMS_KEY_BQ_VIEWS && key="$(v KMS_KEY_BQ_VIEWS)";;
    1|3) if cl14_kms_branch; then
           cl14_kh platform_logs_views || return 1
           key="$CL14_KEY"; kf="--default_kms_key=$key"
           pset KMS_KEY_BQ_VIEWS "$key" || return 1
         fi
         # shellcheck disable=SC2086
         x bq --location="$(v BQ_LOCATION)" mk --dataset --description="Authorised views over platform_logs, one per agent; readers dataset-level (topology row 40)" \
           --label=agp-store:s14-views $kf "$(cl14_dsref platform_logs_views)" || return 1;;
    *) return 1;;
  esac
  pset PLATFORM_LOGS_VIEWS_DS platform_logs_views || return 1
  cl14_dataset CL-4.3 platform-logs-views-dataset E-06 "1.3.1, 4.2.1" platform_logs_views - "$key"
}

# ------------------------------------------------------------------ 5. The fan-out sinks in LOGGING_PROJECT
CL14_FILTERS="audit-families s-org identity evidence default-exclusion billing-account"

step CL-5.1 HUMAN "Commit the filters and the expected-sink inventory" --witness --needs "PLATFORM_REPO_DIR"
s_CL_5_1_check() {
  local f bad=""
  ckpt_done CL-5.1 || return 1
  for f in $CL14_FILTERS; do cl14_py one-line "$(cl14_filter_file "$f")" 2>/dev/null || bad="$bad $f.txt"; done
  [ -f "$(v PLATFORM_REPO_DIR)/logging/sinks-expected.yaml" ] || bad="$bad sinks-expected.yaml"
  # PHASES.md 2026-10-01 rule 1: the person's done is the attestation; a missing file is a warning here,
  # and every sink step stops on it before it builds anything
  [ -z "$bad" ] || agp_say "      WARNING: CL-5.1 is DONE but logging/ lacks, or holds more than one filter in:$bad; CL-5.2 to CL-6.4 stop until it is merged"
  return 0
}
s_CL_5_1_manual() {
  echo "WHO: the platform owner writes; the second human is a required reviewer. WHERE: $(v PLATFORM_REPO_DIR), branch cl-logging-sinks."
  echo "DO: run setup/14 CL-5.1's blocks as written: the six cat > logging/filters/*.txt <<'EOF' here-documents and the"
  echo "    cat > logging/sinks-expected.yaml <<'EOF' one (never by hand), then switch -c, add, commit, push -u origin cl-logging-sinks;"
  echo "    open the pull request and add logging/ to CODEOWNERS with the second human as required reviewer in the same pull request."
  echo "VERIFY: each of the six files holds exactly one filter (the page's loop prints lines:1 six times); the merge on origin/main;"
  echo "        the second human's approval; grep -n 'logging/' CODEOWNERS names them."
  echo "RECORD: the page's EVIDENCE block: records/<date>-CL-5.1-sink-inventory-v1.txt (merge commit, pull request address, ls-tree),"
  echo "        then evidence_add CL-5.1 sink-inventory E-05 \"5.2.1, 5.2.4\" \"build-log:records/<that file>\" \"<that file>\" (hashed)."
  echo "Then: agp-platform done CL-5.1 --witness <second human email>"
}

cl14_dest_bucket() { printf 'logging.googleapis.com/projects/%s/locations/%s/buckets/%s' "$(v LOGGING_PROJECT)" "$(v REGION)" "$1"; }
cl14_dest_project() { printf 'logging.googleapis.com/projects/%s' "$(v LOGGING_PROJECT)"; }
cl14_dest_bq() { printf 'bigquery.googleapis.com/projects/%s/datasets/%s' "$(v LOGGING_PROJECT)" "$(v PLATFORM_LOGS_DS)"; }

cl14_fanout() {     # cl14_fanout STEP SINK BUCKET FILTERNAME SLUG E-ID TISAX DESCRIPTION VAR...: CL-5.2 and CL-5.3
  local st="$1" sk="$2" bk="$3" fn="$4" sl="$5" e="$6" ts="$7" ds="$8" lp f rc; shift 8
  lp="$(v LOGGING_PROJECT)"
  ckpt_done CL-5.1 || { cl14_stop "CL-5.1 is not DONE: the sink is built from the merged filter file" "CL-5.1 DONE (the filter files merged)" || return 1; }
  f="$(cl14_filter "$fn" "$@")" || return 1
  cl14_probed "S_$(printf '%s' "$sk" | tr '-' '_')" gcloud logging sinks describe "$sk" --project="$lp" --format="value(name)"; rc=$?
  case $rc in
    0) [ "$AGP_MODE" = apply ] && echo "      $sk exists: not created again";;
    1|3) x gcloud logging sinks create "$sk" "$(cl14_dest_bucket "$bk")" --log-filter="$f" --description="$ds" --project="$lp" || return 1;;
    *) return 1;;
  esac
  r gcloud logging sinks describe "$sk" --project="$lp" --format="yaml(destination,filter,disabled)" | cl14_keep "$st" "$sl" "$e" "$ts" yaml || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  cl14_sink_ok "--project=$lp" "$sk" "$(cl14_dest_bucket "$bk")" || { echo "      STOP: $sk is not enabled to $bk"; return 1; }
  cl14_sink_filter_cmp "--project=$lp" "$sk" "$f"
}

step CL-5.2 AUTO "Create to-evidence-bucket" --needs "LOGGING_PROJECT REGION ORG_ID BILLING_ACCOUNT_ID PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_5_2_check() {
  local a b
  cl14_probe S_to_evidence_bucket gcloud logging sinks describe to-evidence-bucket --project="$(v LOGGING_PROJECT)" --format="value(name)"; a=$?
  cl14_sink_ok "--project=$(v LOGGING_PROJECT)" to-evidence-bucket "$(cl14_dest_bucket platform-evidence-logs)"; b=$?
  cl14_worst $a $b
}
s_CL_5_2_apply() {
  cl14_under "the ENT_FOLDER_ADMIN grant of CL-2.1 (request it again if it has expired)"
  cl14_fanout CL-5.2 to-evidence-bucket platform-evidence-logs evidence to-evidence-bucket E-06 5.2.4 "Fan-out: evidence copy (08 §3.2)" ORG_ID BILLING_ACCOUNT_ID
}

step CL-5.3 AUTO "Create to-identity-bucket" --needs "LOGGING_PROJECT REGION ORG_ID PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_5_3_check() {
  local a b
  cl14_probe S_to_identity_bucket gcloud logging sinks describe to-identity-bucket --project="$(v LOGGING_PROJECT)" --format="value(name)"; a=$?
  cl14_sink_ok "--project=$(v LOGGING_PROJECT)" to-identity-bucket "$(cl14_dest_bucket platform-identity-logs)"; b=$?
  cl14_worst $a $b
}
s_CL_5_3_apply() {
  cl14_under "the ENT_FOLDER_ADMIN grant of CL-2.1 (request it again if it has expired)"
  local f
  if [ "$AGP_MODE" = apply ]; then
    f="$(cl14_filter identity ORG_ID)" || return 1
    case "$f" in *login.googleapis.com*oauth2.googleapis.com*) ;; *) echo "      STOP: identity.txt does not name login.googleapis.com and oauth2.googleapis.com"; return 1;; esac
    case "$f" in *token.googleapis.com*|*saml.googleapis.com*) echo "      STOP: identity.txt names token.googleapis.com or saml.googleapis.com (08's old names)"; return 1;; esac
  fi
  cl14_fanout CL-5.3 to-identity-bucket platform-identity-logs identity to-identity-bucket E-06 "5.2.4, 7.1" "Fan-out: Login, SAML, OAuth-token Data Access (08 §5.3)" ORG_ID
}

cl14_access_done() {    # cl14_access_done STEP DATASET ENTRY_JSON [TAG]: the dataset's access array holds ENTRY. When the read-back
  # shows no access array at all, STEP's own edit (cl14_access_add) decides, and the person is told to compare by hand.
  local out f
  [ "$AGP_OFFLINE" = 1 ] && return 3
  out="$(bq show --format=prettyjson "$(cl14_dsref "$2")" 2>/dev/null)" || return 1
  if printf '%s' "$out" | cl14_py shows access; then printf '%s' "$out" | cl14_py access-has "$3"; return; fi
  f="$(cl14_last "$1-$2${4:+-$4}-access-edit.json")" || return 1
  cl14_py access-has "$3" < "$f" || return 1
  agp_say "      $2: the read-back shows no access array; ${f##*/} holds the entry (compare the records by hand)"
}

step CL-5.4 AUTO "Create to-bigquery with partitioned tables, then grant its writer on the dataset only" --removes \
  --needs "LOGGING_PROJECT ORG_ID BILLING_ACCOUNT_ID PLATFORM_LOGS_DS PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
# Done when the sink is enabled: the apply enables it only after the WRITER entry is read back.
s_CL_5_4_check() {
  local a b
  cl14_probe S_to_bigquery gcloud logging sinks describe to-bigquery --project="$(v LOGGING_PROJECT)" --format="value(name)"; a=$?
  cl14_sink_ok "--project=$(v LOGGING_PROJECT)" to-bigquery "$(cl14_dest_bq)" "bigqueryOptions.usePartitionedTables=true"; b=$?
  cl14_worst $a $b
}
s_CL_5_4_apply() {
  cl14_under "the ENT_FOLDER_ADMIN (sink) and ENT_PROJECT_REPAIR_CORE (dataset access) grants of CL-2.1 (request again if expired)"
  local lp f rc w pol
  lp="$(v LOGGING_PROJECT)"
  ckpt_done CL-5.1 || { cl14_stop "CL-5.1 is not DONE: the sink is built from the merged filter file" "CL-5.1 DONE (the filter files merged)" || return 1; }
  ckpt_done CL-4.2 || { cl14_stop "CL-4.2 (platform_logs with its partition expiry) is not DONE" "CL-4.2 DONE (platform_logs with its partition expiry)" || return 1; }
  f="$(cl14_filter evidence ORG_ID BILLING_ACCOUNT_ID)" || return 1
  cl14_probed S_to_bigquery gcloud logging sinks describe to-bigquery --project="$lp" --format="value(name)"; rc=$?
  case $rc in
    0) [ "$AGP_MODE" = apply ] && echo "      to-bigquery exists: not created again";;
    1|3) x gcloud logging sinks create to-bigquery "$(cl14_dest_bq)" --use-partitioned-tables --disabled --log-filter="$f" \
           --description="Fan-out: SQL copy, identity services excluded (08 §3.2)" --project="$lp" || return 1;;
    *) return 1;;
  esac
  w="$(cl14_r gcloud logging sinks describe to-bigquery --project="$lp" --format='value(writerIdentity)')" || cl14_planok || return 1
  w="${w#serviceAccount:}"; [ "$AGP_MODE" = apply ] || w="<writer identity of to-bigquery>"
  [ -n "$w" ] || { echo "      STOP: to-bigquery has no writer identity"; return 1; }
  echo "      W=$w"
  cl14_access_add CL-5.4 "$(v PLATFORM_LOGS_DS)" "{\"role\":\"WRITER\",\"userByEmail\":\"$w\"}" || return 1
  x gcloud logging sinks update to-bigquery --no-disabled --project="$lp" || return 1
  r gcloud logging sinks describe to-bigquery --project="$lp" --format="yaml(destination,bigqueryOptions,disabled,filter)" \
    | cl14_keep CL-5.4 to-bigquery E-06 "5.2.4, 4.2.1" yaml || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  s_CL_5_4_check || { echo "      STOP: to-bigquery is not enabled, partitioned, to $(cl14_dest_bq)"; return 1; }
  cl14_sink_filter_cmp "--project=$lp" to-bigquery "$f"
  pol="$(r gcloud projects get-iam-policy "$lp" --format=json)" || return 1
  [ -z "$(printf '%s' "$pol" | cl14_py roles-of "serviceAccount:$w")" ] || { echo "      STOP: the writer holds a project-level role on $lp"; return 1; }
}

step CL-5.5 AUTO "Exclude rerouted entries from LOGGING_PROJECT's own _Default sink" \
  --needs "LOGGING_PROJECT REGION PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_5_5_check() {
  nonempty r gcloud logging sinks list --project="$(v LOGGING_PROJECT)" --filter="name=_Default AND exclusions.name=rerouted-entries" --format="value(name)"
}
s_CL_5_5_apply() {
  cl14_under "the ENT_FOLDER_ADMIN grant of CL-2.1 (request it again if it has expired)"
  local lp f got
  lp="$(v LOGGING_PROJECT)"
  ckpt_done CL-5.1 || { cl14_stop "CL-5.1 is not DONE: the exclusion is the merged default-exclusion.txt" "CL-5.1 DONE (default-exclusion.txt merged)" || return 1; }
  f="$(cl14_filter default-exclusion LOGGING_PROJECT)" || return 1
  r gcloud logging sinks describe _Default --project="$lp" --format="yaml(destination,filter,exclusions)" \
    | cl14_keep CL-5.5 default-sink-before E-05 5.2.4 yaml || cl14_planok || return 1
  # the runner calls apply only when the check found no rerouted-entries exclusion
  x gcloud logging sinks update _Default --add-exclusion=name=rerouted-entries,filter="$f" --project="$lp" || return 1
  r gcloud logging sinks describe _Default --project="$lp" --format="yaml(destination,filter,exclusions)" \
    | cl14_keep CL-5.5 default-exclusion E-05 5.2.4 yaml || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  s_CL_5_5_check || { echo "      STOP: _Default has no exclusion rerouted-entries"; return 1; }
  nonempty r gcloud logging sinks list --project="$lp" --filter="name=_Default AND destination~\"/locations/$(v REGION)/buckets/\"" --format="value(name)" \
    || { echo "      STOP: _Default no longer routes to file 10's regional bucket"; return 1; }
  got="$(r gcloud logging sinks describe _Default --project="$lp" --format=json | cl14_py excl-filter rerouted-entries)"
  if [ "$(printf '%s' "$got" | sed 's/ *$//')" = "$(printf '%s' "$f" | sed 's/ *$//')" ]; then echo "      the exclusion filter equals the committed file"
  else printf '      the exclusion filter differs from the committed file; read both:\n        stored:    %s\n        committed: %s\n' "$got" "$f"; fi
  echo "      after CL-6.5: _Default's bucket holds nothing newer than the exclusion for logName:\"organizations/\" (or storage metrics stay flat)"
}

# ------------------------------------------------------------------ 6. The aggregated sinks, the billing-account sink and the proofs
cl14_fld_ids() {    # every FLD_* value in ~/.platform-env that is a folder number (CL-6.1's env | sed)
  local n val
  if command -v _penv_names >/dev/null 2>&1 && [ -f "${PLATFORM_ENV_FILE-}" ]; then
    for n in $(_penv_names | grep '^FLD_'); do
      val="$(_penv_get "$n")"
      case "$val" in ''|*[!0-9]*) ;; *) echo "$val";; esac
    done | sort -u
  else
    v FLD_AGENTIC_PLATFORM; echo
  fi
}

step CL-6.1 AUTO-READ "Check what interception will take from child projects" \
  --needs "FLD_AGENTIC_PLATFORM LOGGING_PROJECT GEMINI_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_6_1_check() { ckpt_done CL-6.1; }
s_CL_6_1_apply() {
  local f p n others="" lp ph
  lp="$(v LOGGING_PROJECT)"
  { for f in $(cl14_fld_ids); do
      for p in $(cl14_r gcloud projects list --filter="parent.type=folder AND parent.id=${f}" --format="value(projectId)"); do
        echo "== ${p} (folder ${f})"
        r gcloud logging sinks list --project="$p" --format="table(name,destination,filter)"
      done
    done
  } | cl14_keep CL-6.1 child-sinks E-05 "5.2.4, 1.3.1" txt || cl14_planok || return 1
  ph="project:GEMINI_PROJECT"
  cl14_rerun_has CL-6.1 "$ph" || cl14_xpending "$ph" CL-6.1 "19 GE-3 move: re-run 14 CL-6.1 for GEMINI_PROJECT before the move" || return 1
  [ "$AGP_MODE" = apply ] || return 0
  for f in $(cl14_fld_ids); do
    for p in $(r gcloud projects list --filter="parent.type=folder AND parent.id=${f}" --format="value(projectId)"); do
      for n in $(r gcloud logging sinks list --project="$p" --format="value(name)"); do
        case "$n" in _Default|_Required) continue;; esac
        if [ "$p" = "$lp" ]; then case "$n" in to-evidence-bucket|to-identity-bucket|to-bigquery) continue;; esac; fi
        others="$others $p/$n"
      done
    done
  done
  if [ -n "$others" ]; then
    echo "      sinks interception may starve; each matches none of the five audit log ids, or is recorded with its owner's agreement:"
    # shellcheck disable=SC2086
    printf '        %s\n' $others
  fi
  echo "      every project listed must be expected; the second human reads the record before CL-6.3"
}

step CL-6.2 HUMAN "Create S-org" --witness --gate "SD-18 SD-40" \
  --needs "ORG_ID LOGGING_PROJECT ENT_ORG_SINK CICD_PROJECT PLATFORM_REPO_DIR" --sets "SINK_S_ORG"
s_CL_6_2_check() {
  local rc
  cl14_sink_ok "--organization=$(v ORG_ID)" S-org "$(cl14_dest_project)" "NOT includeChildren=true"; rc=$?
  ckpt_done CL-6.2 || return 1
  case $rc in 0) has_value SINK_S_ORG || agp_say "      SINK_S_ORG has no value: penv_set SINK_S_ORG \"organizations/$(v ORG_ID)/sinks/S-org\""; return 0;; 1) agp_say "      CL-6.2 is DONE but S-org is not enabled to $(cl14_dest_project)"; return 2;; *) return $rc;; esac
}
s_CL_6_2_manual() {
  local e; e="$(v ENT_ORG_SINK)"
  echo "WHO: the platform owner through ENT_ORG_SINK; approver the second human (SD-18), after reading logging/filters/s-org.txt at the merge."
  echo "  gcloud pam grants create --entitlement=${e##*/} --requested-duration=3600s --justification=\"14 CL-6.2 to CL-6.6: S-org at the organisation, merged filter logging/filters/s-org.txt\" --location=global $(cl14_pam_flag "$e") --billing-project=$(v CICD_PROJECT)"
  echo "ONCE ACTIVE: setup/14 CL-6.2's second block as written (F from s-org.txt with sed): sinks create S-org $(cl14_dest_project)"
  echo "  --organization=$(v ORG_ID) --disabled --log-filter=\"\$(cat \"\$F\")\"; read its writerIdentity; projects add-iam-policy-binding"
  echo "  $(v LOGGING_PROJECT) --member=<writer> --role=roles/logging.logWriter --condition=None (under ENT_FOLDER_ADMIN, re-requested if expired);"
  echo "  sinks update S-org --organization=$(v ORG_ID) --no-disabled; penv_set SINK_S_ORG \"organizations/$(v ORG_ID)/sinks/S-org\"."
  echo "  If 13's member constraint refuses the writer: stop; 13's owner resolves it under ENT_PLATFORM_POLICY, never relaxed here."
  echo "VERIFY: the page's describe (destination the project, filter as the file, includeChildren false, enabled) and the logWriter table."
  echo "RECORD: both outputs and the grant name as <date>-CL-6.2-s-org-v1 (topology row 41, organisation half)."
  echo "Then: agp-platform done CL-6.2 --witness <second human email>"
}

step CL-6.3 HUMAN "Create S-folder, intercepting" --witness --gate "SD-40" \
  --needs "FLD_AGENTIC_PLATFORM LOGGING_PROJECT SECOND_HUMAN_EMAIL PLATFORM_REPO_DIR" --sets "SINK_S_FOLDER"
s_CL_6_3_check() {
  local rc
  cl14_sink_ok "--folder=$(v FLD_AGENTIC_PLATFORM)" S-folder "$(cl14_dest_project)" "includeChildren=true AND interceptChildren=true"; rc=$?
  ckpt_done CL-6.3 || return 1
  case $rc in 0) has_value SINK_S_FOLDER || agp_say "      SINK_S_FOLDER has no value: penv_set SINK_S_FOLDER \"folders/$(v FLD_AGENTIC_PLATFORM)/sinks/S-folder\""; return 0;; 1) agp_say "      CL-6.3 is DONE but S-folder is not enabled and intercepting"; return 2;; *) return $rc;; esac
}
s_CL_6_3_manual() {
  echo "WHO: the platform owner under ENT_FOLDER_ADMIN; approver the second human, beside the operator for the enabling line."
  echo "DO 1: setup/14 CL-6.3's first block as written: sinks create S-folder $(cl14_dest_project) --folder=$(v FLD_AGENTIC_PLATFORM)"
  echo "  --include-children --intercept-children --disabled --log-filter=<audit-families.txt>; the writer gets roles/logging.logWriter"
  echo "  on $(v LOGGING_PROJECT) (--condition=None); the describe. The sink is disabled and harmless. STOP here."
  echo "CONFIRM aloud, ticked in the build log: destination is LOGGING_PROJECT as in sinks-expected.yaml (CL-5.1); platform_logs and the three"
  echo "  fan-out sinks enabled (CL-4.2, CL-5.2 to CL-5.4); the writer read back under logWriter; CL-6.1's owners agreed; the filter is the file."
  echo "DO 2 (second human present): checkpoint CL-6.3 START \"$(v SECOND_HUMAN_EMAIL)\" - \"enable interception on fld-agentic-platform\";"
  echo "  gcloud logging sinks update S-folder --folder=$(v FLD_AGENTIC_PLATFORM) --no-disabled;"
  echo "  penv_set SINK_S_FOLDER \"folders/$(v FLD_AGENTIC_PLATFORM)/sinks/S-folder\". Write the UTC minute: CL-6.5 proves it in this sitting."
  echo "LOST, NOT DELAYED: entries intercepted while the sink is wrong are never replayed. Rollback: --disabled, same command."
  echo "RECORD: both describes, the ticked table, the checkpoint line as <date>-CL-6.3-s-folder-v1."
  echo "Then: agp-platform done CL-6.3 --witness <second human email>"
}

step CL-6.4 HUMAN "Create billing-account-audit (07's source B)" --needs "BILLING_ACCOUNT_ID BILLING_ADMIN_EMAIL LOGGING_PROJECT"
s_CL_6_4_check() {
  local rc
  cl14_sink_ok "--billing-account=$(v BILLING_ACCOUNT_ID)" billing-account-audit "$(cl14_dest_project)"; rc=$?
  ckpt_done CL-6.4 || return 1
  case $rc in 1) agp_say "      CL-6.4 is DONE but billing-account-audit is not enabled to $(cl14_dest_project)"; return 2;; *) return $rc;; esac
}
s_CL_6_4_manual() {
  local b; b="$(v BILLING_ACCOUNT_ID)"
  echo "WHO: the billing administrator ($(v BILLING_ADMIN_EMAIL)) in their own shell; the platform owner grants the writer on LOGGING_PROJECT."
  echo "  gcloud billing accounts add-iam-policy-binding $b --member=\"user:$(v BILLING_ADMIN_EMAIL)\" --role=\"roles/logging.configWriter\""
  echo "  IF REFUSED: stop; no other principal; record the refusal text, open a Google support case under 04's row; 07 BA-4.3 stays the control."
  echo "  gcloud logging sinks create billing-account-audit $(cl14_dest_project) --billing-account=$b --disabled --log-filter='logName:\"billingAccounts/$b/logs/\"' --description=\"Billing account audit log to the platform evidence path (07 BA-4, source B)\""
  echo "  gcloud logging sinks describe billing-account-audit --billing-account=$b --format='value(writerIdentity)'"
  echo "PLATFORM OWNER: gcloud projects add-iam-policy-binding $(v LOGGING_PROJECT) --member=<writer> --role=roles/logging.logWriter --condition=None"
  echo "  gcloud logging sinks update billing-account-audit --billing-account=$b --no-disabled"
  echo "  gcloud billing accounts remove-iam-policy-binding $b --member=\"user:$(v BILLING_ADMIN_EMAIL)\" --role=\"roles/logging.configWriter\""
  echo "VERIFY: enabled with the filter; no logging.configWriter left on the account; after CL-6.5 a billing SetIamPolicy shows in 'security'."
  echo "RECORD: outputs as <date>-CL-6.4-billing-account-sink-v1; close 07's re-run row. Then: agp-platform done CL-6.4"
}

step CL-6.5 HUMAN "Prove the path end to end with seeded events, read by the second human" --witness \
  --needs "LOGGING_PROJECT REGION BQ_LOCATION ORG_ID EVIDENCE_INTERIM_LOCATION"
s_CL_6_5_check() { ckpt_done CL-6.5; }
s_CL_6_5_manual() {
  echo "WHO: the platform owner seeds; the second human reads and signs (the platform owner never proves their own evidence path)."
  echo "SEEDS, each with its UTC time: (1) a super admin creates and deletes the OU /cl-seed-<YYYYMMDD>; (2) the ENT_ORG_SINK grant's"
  echo "  SetIamPolicy; (3) gcloud logging buckets update platform-evidence-logs --location=$(v REGION) --description=\"Platform evidence (seed <YYYYMMDD>)\" --project=$(v LOGGING_PROJECT);"
  echo "  (4) the second human signs in to the Admin console as sa-2-admin@; (5) 07 BA-4.2's add and remove of roles/billing.viewer."
  echo "READS after 15 minutes: the six gcloud logging read lines of setup/14 CL-6.5 (security view, then identity view), and the"
  echo "  platform owner's two bq queries under ENT_PROJECT_REPAIR_CORE (--project_id=$(v LOGGING_PROJECT), --location=$(v BQ_LOCATION))."
  echo "VERIFY: seeds 1, 2, 3, 5 in 'security'; no Login row there; the sign-in in 'identity'; in BigQuery admin and logging rows and"
  echo "        identity_rows 0. Any miss: stop, the sinks stay enabled, the cause is found before CL-7. Reset the bucket description at once."
  echo "RECORD: timestamps and method names, signed, as <date>-CL-6.5-end-to-end-proof-v1 in $(v EVIDENCE_INTERIM_LOCATION)."
  echo "Then: agp-platform done CL-6.5 --witness <second human email>"
}

step CL-6.6 HUMAN "Take the sink census: no interim or agent organisation sink (S094, S157)" --witness \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM LOGGING_PROJECT"
s_CL_6_6_check() { ckpt_done CL-6.6; }
s_CL_6_6_manual() {
  echo "WHO: the platform owner runs (the organisation list under ENT_ORG_SINK); the second human compares with logging/sinks-expected.yaml and signs."
  echo "  gcloud logging sinks list --organization=$(v ORG_ID) --format=\"table(name,destination,includeChildren,interceptChildren,disabled)\""
  echo "  gcloud logging sinks list --folder=$(v FLD_AGENTIC_PLATFORM) --format=\"table(name,destination,includeChildren,interceptChildren,disabled)\""
  echo "  gcloud logging sinks list --project=$(v LOGGING_PROJECT) --format=\"table(name,destination,disabled)\""
  echo "  gcloud logging sinks list --organization=$(v ORG_ID) --format=\"value(name)\" | grep -E '^(walle-workspace-audit|walle-audit-bq)\$' && echo \"FINDING: retired sink present\" || echo \"no retired sink\""
  echo "VERIFY: every row in the inventory; 'no retired sink'; no organisation or folder sink into an agent project; any other sink is"
  echo "        a finding to the second human the same day. Weekly by the second human until file 25's rule is live."
  echo "RECORD: the three tables, signed, as <date>-CL-6.6-sink-census-v<n>. Then: agp-platform done CL-6.6 --witness <second human email>"
}

# ------------------------------------------------------------------ 7. The authorised view and topology row 40
cl14_view_ref() { printf '%s:%s.walle_workspace_logs' "$(v LOGGING_PROJECT)" "$(v PLATFORM_LOGS_VIEWS_DS)"; }

step CL-7.1 AUTO "Create platform_logs_views.walle_workspace_logs" \
  --needs "LOGGING_PROJECT BQ_LOCATION PLATFORM_LOGS_DS PLATFORM_LOGS_VIEWS_DS BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_7_1_check() { exists bq show --format=prettyjson "$(cl14_view_ref)"; }
s_CL_7_1_apply() {
  cl14_under "the ENT_PROJECT_REPAIR_CORE grant of CL-2.1 (request it again if it has expired)"
  local out
  ckpt_done CL-6.5 || { cl14_stop "CL-6.5 is not DONE: it proves cloudaudit_googleapis_com_activity exists" "CL-6.5 DONE (the activity table exists)" || return 1; }
  # the check is the view's existence: apply runs only when it is absent
  x bq --location="$(v BQ_LOCATION)" mk --use_legacy_sql=false --description="Workspace Admin events over platform_logs; no actor exclusion (topology row 40)" \
    --view='SELECT * FROM `'"$(v LOGGING_PROJECT)"'.'"$(v PLATFORM_LOGS_DS)"'.cloudaudit_googleapis_com_activity` WHERE protopayload_auditlog.serviceName = "admin.googleapis.com"' \
    "$(cl14_view_ref)" || return 1
  out="$(r bq show --format=prettyjson "$(cl14_view_ref)")" || cl14_planok || return 1
  printf '%s\n' "$out" | cl14_keep CL-7.1 walle-workspace-logs-view E-09 5.2.4 json || return 1
  [ "$AGP_MODE" = apply ] || return 0
  printf '%s' "$out" | cl14_py view
  case $? in
    0) echo "      read back: a VIEW, no principalEmail in its query";;
    3) echo "      the read-back shows neither type nor query: compare the record with the page's VERIFY by hand";;
    *) echo "      STOP: not a VIEW, or its query names principalEmail"; return 1;;
  esac
}

cl14_authview() { printf '{"view":{"projectId":"%s","datasetId":"%s","tableId":"walle_workspace_logs"}}' "$(v LOGGING_PROJECT)" "$(v PLATFORM_LOGS_VIEWS_DS)"; }

step CL-7.2 AUTO "Authorise the view on platform_logs" --removes --needs "LOGGING_PROJECT PLATFORM_LOGS_DS PLATFORM_LOGS_VIEWS_DS BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_7_2_check() { cl14_access_done CL-7.2 "$(v PLATFORM_LOGS_DS)" "$(cl14_authview)"; }
s_CL_7_2_apply() {
  cl14_under "the ENT_PROJECT_REPAIR_CORE grant of CL-2.1 (request it again if it has expired)"
  local af w
  cl14_access_add CL-7.2 "$(v PLATFORM_LOGS_DS)" "$(cl14_authview)" || return 1
  af="$(cl14_rec "CL-7.2-$(v PLATFORM_LOGS_DS)-access-after.json")"
  [ "$AGP_MODE" = apply ] || { ev CL-7.2 authorised-view E-09 4.2.1 "build-log:records/${af##*/}"; return 0; }
  [ -f "$af" ] || af="$(cl14_rec "CL-7.2-$(v PLATFORM_LOGS_DS)-access-before.json")"
  ev CL-7.2 authorised-view E-09 4.2.1 "build-log:records/${af##*/}" "$af" || return 1
  w="$(r gcloud logging sinks describe to-bigquery --project="$(v LOGGING_PROJECT)" --format='value(writerIdentity)')"; w="${w#serviceAccount:}"
  if cl14_py shows access < "$af"; then
    cl14_py access-has "{\"role\":\"WRITER\",\"userByEmail\":\"$w\"}" < "$af" || { echo "      STOP: CL-5.4's WRITER entry is no longer on $(v PLATFORM_LOGS_DS)"; return 1; }
  else
    echo "      the read-back shows no access array: check CL-5.4's WRITER entry in $af by hand"
  fi
}

step CL-7.3 AUTO "Grant the row 40 readers, or record them PENDING" --removes --needs "LOGGING_PROJECT PLATFORM_LOGS_VIEWS_DS BUILD_LOG_DIR"
cl14_views_reader() {   # cl14_views_reader VAR PLACEHOLDER TAG: 0 done (READER present, or PENDING recorded while VAR is unset)
  if has_value "$1"; then
    cl14_access_done CL-7.3 "$(v PLATFORM_LOGS_VIEWS_DS)" "{\"role\":\"READER\",\"userByEmail\":\"$(v "$1")\"}" "$3"
    case $? in 0) return 0;; 3) return 3;; esac
    cl14_rerun_has CL-7.3 "serviceAccount:$(v "$1")"; return
  fi
  cl14_rerun_has CL-7.3 "$2"
}
s_CL_7_3_check() {
  local a b
  cl14_views_reader SA_MO_METRICS "$CL14_MO_PH" mo-metrics; a=$?
  cl14_views_reader SA_EVE_VERIFIER "$CL14_EVE_PH" eve-verifier; b=$?
  cl14_worst $a $b
}
s_CL_7_3_apply() {
  cl14_under "the ENT_PROJECT_REPAIR_CORE grant of CL-2.1 (request it again if it has expired)"
  local rc
  cl14_principal SA_MO_METRICS "$CL14_MO_PH" CL-7.3 "14 CL-7.3: READER on platform_logs_views (row 40)" "14 CL-7.3: READER on platform_logs_views (row 40), after 22"; rc=$?
  case $rc in 0) cl14_access_add CL-7.3 "$(v PLATFORM_LOGS_VIEWS_DS)" "{\"role\":\"READER\",\"userByEmail\":\"$(v SA_MO_METRICS)\"}" mo-metrics || return 1;; 2) return 1;; esac
  cl14_principal SA_EVE_VERIFIER "$CL14_EVE_PH" CL-7.3 "14 CL-7.3: READER on platform_logs_views (row 40)" "14 CL-7.3: READER on platform_logs_views (row 40), after 24"; rc=$?
  case $rc in 0) cl14_access_add CL-7.3 "$(v PLATFORM_LOGS_VIEWS_DS)" "{\"role\":\"READER\",\"userByEmail\":\"$(v SA_EVE_VERIFIER)\"}" eve-verifier || return 1;; 2) return 1;; esac
  return 0
}

# ------------------------------------------------------------------ 8. Data Access audit configuration
cl14_ac_folder() { printf '%s/logging/audit-config-fld-agentic-platform.json' "$(v PLATFORM_REPO_DIR)"; }
cl14_ac_projects() { printf '%s/logging/audit-config-projects.json' "$(v PLATFORM_REPO_DIR)"; }

step CL-8.1 HUMAN "Commit the desired configuration" --witness --needs "PLATFORM_REPO_DIR"
s_CL_8_1_check() {
  ckpt_done CL-8.1 || return 1
  if cl14_py want "$(cl14_ac_folder)" >/dev/null 2>&1 && cl14_py want "$(cl14_ac_projects)" LOGGING_PROJECT >/dev/null 2>&1 \
    && cl14_py want "$(cl14_ac_projects)" CORE_PROJECT >/dev/null 2>&1 && [ -z "$(cl14_py exempt < "$(cl14_ac_folder)")" ]; then return 0; fi
  agp_say "      WARNING: CL-8.1 is DONE but logging/audit-config-*.json is missing, does not parse, or carries exemptedMembers; CL-8.2 and CL-8.3 stop on it"
  return 0
}
s_CL_8_1_manual() {
  echo "WHO: the platform owner writes; the second human reviews (CODEOWNERS logging/). WHERE: $(v PLATFORM_REPO_DIR), branch cl-audit-config."
  echo "DO: setup/14 CL-8.1's block as written: switch main and pull --ff-only, switch -c cl-audit-config, the two"
  echo "    cat > logging/audit-config-*.json <<'EOF' here-documents (never by hand), add, commit, push -u origin cl-audit-config;"
  echo "    open the pull request; merge after the second human's review, as CL-5.1."
  echo "VERIFY: the merge commit exists; no exemptedMembers anywhere (the page's jq -e prints true)."
  echo "RECORD: records/<date>-CL-8.1-audit-config-committed-v1.txt (merge commit, pull request address, ls-tree), registered with its"
  echo "        hash: evidence_add CL-8.1 audit-config-committed E-05 \"5.2.1, 5.2.4\" \"build-log:records/<that file>\" \"<that file>\"."
  echo "Then: agp-platform done CL-8.1 --witness <second human email>"
}

step CL-8.2 AUTO "Merge the configuration into the folder policy with its etag and a diff" --witness --removes \
  --needs "FLD_AGENTIC_PLATFORM PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_8_2_check() {
  local want; want="$(cl14_py want "$(cl14_ac_folder)" 2>/dev/null)" || return 1
  cl14_audit_pairs_ok folder "$(v FLD_AGENTIC_PLATFORM)" "$want"
}
s_CL_8_2_apply() {
  cl14_under "the ENT_FOLDER_ADMIN grant of CL-2.1 (request it again if it has expired)"
  local want f
  ckpt_done CL-8.1 || { cl14_stop "CL-8.1 is not DONE: the configuration is the merged file" "CL-8.1 DONE (the audit configuration merged)" || return 1; }
  if [ -f "$(cl14_ac_folder)" ]; then want="$(cl14_py want "$(cl14_ac_folder)")" || return 1
  else cl14_stop "$(cl14_ac_folder) is missing" "logging/audit-config-fld-agentic-platform.json in PLATFORM_REPO_DIR" || return 1; want="[]"; fi
  [ "$AGP_MODE" = apply ] && echo "      the second human reads the diff below; set-iam-policy runs only if it changes auditConfigs alone"
  cl14_audit_merge CL-8.2 folder "$(v FLD_AGENTIC_PLATFORM)" "$want" folder || return 1
  f="$(cl14_rec CL-8.2-folder-audit-config-v1.json)"
  r gcloud resource-manager folders get-iam-policy "$(v FLD_AGENTIC_PLATFORM)" --format=json \
    | cl14_keep CL-8.2 folder-audit-config E-06 "5.2.4, 4.2.1" json || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  cl14_audit_pairs_ok folder "$(v FLD_AGENTIC_PLATFORM)" "$want" || { echo "      STOP: the read-back lacks a wanted service and log type ($f)"; return 1; }
}

step CL-8.3 AUTO "Merge the project-level configurations" --removes \
  --needs "LOGGING_PROJECT CORE_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_8_3_check() {
  local k want rcs=""
  for k in LOGGING_PROJECT CORE_PROJECT; do
    want="$(cl14_py want "$(cl14_ac_projects)" "$k" 2>/dev/null)" || return 1
    cl14_audit_pairs_ok project "$(v "$k")" "$want"; rcs="$rcs $?"
  done
  # shellcheck disable=SC2086
  cl14_worst $rcs
}
s_CL_8_3_apply() {
  cl14_under "the ENT_PROJECT_REPAIR_CORE grant of CL-2.1 (request it again if it has expired)"
  local k want
  ckpt_done CL-8.1 || { cl14_stop "CL-8.1 is not DONE: the configuration is the merged file" "CL-8.1 DONE (the audit configuration merged)" || return 1; }
  [ -f "$(cl14_ac_projects)" ] || { cl14_stop "$(cl14_ac_projects) is missing" "logging/audit-config-projects.json in PLATFORM_REPO_DIR" || return 1; }
  for k in LOGGING_PROJECT CORE_PROJECT; do
    if [ -f "$(cl14_ac_projects)" ]; then want="$(cl14_py want "$(cl14_ac_projects)" "$k")" || return 1; else want="[]"; fi
    cl14_audit_merge CL-8.3 project "$(v "$k")" "$want" "$k" || return 1
  done
  { for k in LOGGING_PROJECT CORE_PROJECT; do echo "== $k"; r gcloud projects get-iam-policy "$(v "$k")" --format=json; done; } \
    | cl14_keep CL-8.3 project-audit-config E-06 5.2.4 txt || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  s_CL_8_3_check || { echo "      STOP: a project read-back lacks a wanted service and log type"; return 1; }
}

step CL-8.4 HUMAN "Prove one Data Access entry arrives centrally (the hand canary)" --witness --needs "CORE_PROJECT LOGGING_PROJECT REGION"
s_CL_8_4_check() { ckpt_done CL-8.4; }
s_CL_8_4_manual() {
  echo "WHO: the platform owner makes the calls under ENT_PROJECT_REPAIR_CORE; the second human reads through the security view."
  echo "  gcloud logging buckets list --project=$(v CORE_PROJECT) --location=$(v REGION) --format=\"value(name)\""
  echo "  gcloud iam service-accounts get-iam-policy \"k7-executor@$(v CORE_PROJECT).iam.gserviceaccount.com\" --project=$(v CORE_PROJECT) --format=\"value(etag)\""
  echo "AFTER 15 MINUTES, the second human:"
  echo "  gcloud logging read 'logName:\"projects/$(v CORE_PROJECT)/logs/cloudaudit.googleapis.com%2Fdata_access\" AND protoPayload.serviceName=(\"logging.googleapis.com\" OR \"iam.googleapis.com\")' --bucket=platform-evidence-logs --location=$(v REGION) --view=security --project=$(v LOGGING_PROJECT) --freshness=1h --limit=5 --format=\"table(timestamp,protoPayload.serviceName,protoPayload.methodName)\""
  echo "VERIFY: a logging and an iam Data Access row from CORE_PROJECT centrally (if ListBuckets is absent, record which arrived and repeat"
  echo "        with gcloud logging read in CORE_PROJECT); CORE_PROJECT's own _Default holds no copy (interception)."
  echo "RECORD: output as <date>-CL-8.4-hand-canary-v1; a DRILL_CALENDAR row 'hand Data Access canary, weekly, second human, until CL-8.5'."
  echo "Then: agp-platform done CL-8.4 --witness <second human email>"
}

step CL-8.5 BLOCKED "Deploy the daily Data Access canary job" --note "B-02 (the canary job code of 08 §4.3, jobs/logging-canary/)"
s_CL_8_5_check() { ckpt_done CL-8.5; }
s_CL_8_5_manual() {
  echo "BLOCKED on README B-02: the canary job of 08 §4.3 is not committed in PLATFORM_REPO_REMOTE jobs/logging-canary/ with green CI."
  echo "Until then CL-8.4 runs weekly. When the commit exists: setup/14 CL-8.5's ACTION, commands written with the code and reviewed by"
  echo "the second human; then checkpoint CL-8.5 DONE. The run continues."
}

# ------------------------------------------------------------------ 9. The billing export
cl14_bds() {    # the billing export dataset name: the value already recorded, else NAMES through decision-value.sh (a read)
  local n rc
  if has_value BILLING_EXPORT_DS; then v BILLING_EXPORT_DS; return 0; fi
  n="$(r "$(agp_tool decision-value.sh)" NAMES BILLING_EXPORT_DS 2>/dev/null)"; rc=$?
  if [ $rc -eq 0 ] && [ -n "$n" ]; then printf '%s' "$n"; return 0; fi
  [ "$AGP_MODE" = apply ] && return 1
  printf '<BILLING_EXPORT_DS from NAMES>'; return "$rc"
}

step CL-9.1 AUTO "Create BILLING_EXPORT_DS" --irreversible --gate "NAMES SD-16" \
  --needs "LOGGING_PROJECT BQ_LOCATION BILLING_ACCOUNT_ID PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "BILLING_EXPORT_DS KMS_KEY_BQ_BILLING"
s_CL_9_1_check() {
  local bds rc
  bds="$(cl14_bds)"; rc=$?
  case $rc in 0) ;; 3) return 3;; *) return 1;; esac
  cl14_probe BDS bq show --format=prettyjson "$(cl14_dsref "$bds")" || return $?
  has_value BILLING_EXPORT_DS
}
s_CL_9_1_apply() {
  cl14_under "the ENT_PROJECT_REPAIR_CORE grant of CL-2.1 (request it again if it has expired)"
  local bds rc key=- kf=""
  ckpt_done CL-4.1 || { cl14_stop "CL-4.1's branch is not recorded" "CL-4.1 DONE (the encryption branch recorded)" || return 1; }
  [ "$(v BQ_LOCATION)" = EU ] || { cl14_stop "BQ_LOCATION is $(v BQ_LOCATION), not EU" "BQ_LOCATION is EU" || return 1; }
  bds="$(cl14_bds)" || [ "$AGP_MODE" != apply ] || { echo "      STOP: no BILLING_EXPORT_DS in the signed NAMES record"; return 1; }
  # the page's billing-link test, as a filtered list of the billing account's projects (PHASES.md rule 4)
  [ "$AGP_MODE" = apply ] || printf '      read: %s\n' "gcloud billing projects list --billing-account=$(v BILLING_ACCOUNT_ID) --filter=\"projectId=$(v LOGGING_PROJECT)\" --format=\"value(projectId)\" (prints the project, else STOP)" >&3
  if [ "$AGP_MODE" = apply ]; then
    nonempty r gcloud billing projects list --billing-account="$(v BILLING_ACCOUNT_ID)" --filter="projectId=$(v LOGGING_PROJECT)" --format="value(projectId)" \
      || { echo "      STOP: LOGGING_PROJECT not on BILLING_ACCOUNT_ID"; return 1; }
  fi
  cl14_probed BDS bq show --format=prettyjson "$(cl14_dsref "$bds")"; rc=$?
  case $rc in
    0) [ "$AGP_MODE" = apply ] && echo "      $bds exists: not created again"
       has_value KMS_KEY_BQ_BILLING && key="$(v KMS_KEY_BQ_BILLING)";;
    1|3) if cl14_kms_branch; then
           cl14_kh "$bds" || return 1
           key="$CL14_KEY"; kf="--default_kms_key=$key"
           pset KMS_KEY_BQ_BILLING "$key" || return 1
         fi
         # shellcheck disable=SC2086
         x bq --location="$(v BQ_LOCATION)" mk --dataset --description="Cloud Billing standard and detailed usage cost export for BILLING_ACCOUNT_ID (08 S26); no table or partition expiry" \
           --label=agp-store:s26 $kf "$(cl14_dsref "$bds")" || return 1;;
    *) return 1;;
  esac
  pset BILLING_EXPORT_DS "$bds" || return 1
  cl14_dataset CL-9.1 billing-export-dataset E-05 1.3.1 "$bds" none "$key"
}

step CL-9.2 AUTO "Give the billing administrator BigQuery User on LOGGING_PROJECT for the sitting" --witness \
  --needs "LOGGING_PROJECT BILLING_ADMIN_EMAIL BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER"
s_CL_9_2_check() {   # done while the binding and BD-14-02 stand, and for good once CL-9.4 has removed the binding
  ckpt_done CL-9.4 && return 0
  cl14_last 'CL-9.4-role-removed.txt' >/dev/null && return 0
  has_binding "user:$(v BILLING_ADMIN_EMAIL)" roles/bigquery.user gcloud projects get-iam-policy "$(v LOGGING_PROJECT)" || return $?
  cl14_bd_has BD-14-02
}
s_CL_9_2_apply() {
  cl14_under "the ENT_PROJECT_REPAIR_CORE grant of CL-2.1 (request it again if it has expired)"
  local lp m roles
  lp="$(v LOGGING_PROJECT)"; m="user:$(v BILLING_ADMIN_EMAIL)"
  x gcloud projects add-iam-policy-binding "$lp" --member="$m" --role="roles/bigquery.user" --condition=None || return 1
  cl14_dev_92_row || return 1
  [ "$AGP_MODE" != apply ] || cl14_bd_has BD-14-02 || { echo "      STOP: BD-14-02 is not in DEVIATION_REGISTER"; return 1; }
  r gcloud projects get-iam-policy "$lp" --flatten="bindings[].members" --filter="bindings.members:$(v BILLING_ADMIN_EMAIL)" --format="table(bindings.role)" \
    | cl14_keep CL-9.2 billing-admin-bq-user E-05 4.1.3 txt || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  roles="$(r gcloud projects get-iam-policy "$lp" --format=json | cl14_py roles-of "$m" | sort -u | tr '\n' ' ')"
  [ "$roles" = "roles/bigquery.user " ] || { echo "      STOP: $m holds more than roles/bigquery.user on $lp: $roles"; return 1; }
}
cl14_dev_92_row() { # setup/14 CL-9.2: the BD-14-02 row, cell for cell
  cl14_bd_insert BD-14-02 "$(printf '| BD-14-02 | %s | 14 CL-9.2 | DEV | temporary bigquery.user to billing administrator on LOGGING_PROJECT, removed in CL-9.4 | %s | setup/14 CL-9.2 | roles/bigquery.user to user:%s, unconditioned | n/a | n/a | SD-16 (signed record) | removed in 14 CL-9.4 | open |' "$(date -u +%F)" "projects/$(v LOGGING_PROJECT)" "$(v BILLING_ADMIN_EMAIL)")"
}

step CL-9.3 HUMAN "Enable the standard and detailed usage cost export" \
  --needs "BILLING_ACCOUNT_ID BILLING_ADMIN_EMAIL LOGGING_PROJECT BILLING_EXPORT_DS"
s_CL_9_3_check() { ckpt_done CL-9.3; }
s_CL_9_3_manual() {
  echo "WHO: the billing administrator ($(v BILLING_ADMIN_EMAIL)); the platform owner watches and records."
  echo "WHERE: Cloud console > Billing export, account $(v BILLING_ACCOUNT_ID), tab BigQuery export."
  echo "DO: Standard usage cost > Enable (an existing export: stop and record it first; a move does not backfill) > project"
  echo "    $(v LOGGING_PROJECT), dataset $(v BILLING_EXPORT_DS) > Save. Repeat for Detailed usage cost. Pricing export stays off."
  echo "VERIFY: both Enabled on the tab; bq show --format=prettyjson $(v LOGGING_PROJECT):$(v BILLING_EXPORT_DS) lists"
  echo "        billing-export-bigquery@system.gserviceaccount.com as owner; within 24 h bq ls lists the standard and detailed tables."
  echo "RECORD: tab screenshot and bq ls as <date>-CL-9.3-billing-export-enabled-v1; the minute of Save searched in 'security'."
  echo "Then: agp-platform done CL-9.3 (CL-9.4 waits 48 hours from this line)"
}

step CL-9.4 AUTO "Remove the temporary role, prove the export keeps running, and read the SCC SKUs" --removes --witness \
  --needs "LOGGING_PROJECT BQ_LOCATION BILLING_ADMIN_EMAIL BILLING_EXPORT_DS BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER"
# The page's three parts: (1) an append 48 hours old exists, (2) the removal, its time recorded in
# records/<date>-CL-9.4-role-removed.txt, the rows per day and the SCC SKUs, (3) an append made after
# the removal, and only then bd_close BD-14-02. A resumed run skips (1) and (2) once the removal record exists.
s_CL_9_4_check() {
  cl14_last 'CL-9.4-role-removed.txt' >/dev/null || return 1
  cl14_bd_closed BD-14-02
}
cl14_export_tbl() { printf '`%s.%s.gcp_billing_export_v1_*`' "$(v LOGGING_PROJECT)" "$(v BILLING_EXPORT_DS)"; }
cl14_bq_rows() {    # cl14_bq_rows SQL: the page's bq query (csv there, json here so an empty result reads as []); 0 a row, 1 none
  [ "$AGP_MODE" = apply ] || printf '      read: %s\n' "$(agp_quote bq --location="$(v BQ_LOCATION)" --project_id="$(v LOGGING_PROJECT)" query --use_legacy_sql=false --format=json "$1")" >&3
  nonempty r bq --location="$(v BQ_LOCATION)" --project_id="$(v LOGGING_PROJECT)" query --use_legacy_sql=false --format=json "$1"
}
s_CL_9_4_apply() {
  cl14_under "a fresh ENT_PROJECT_REPAIR_CORE grant (CL-2.1's request): the removal needs project IAM on LOGGING_PROJECT"
  local lp m rc pol rm at tbl
  lp="$(v LOGGING_PROJECT)"; m="user:$(v BILLING_ADMIN_EMAIL)"; tbl="$(cl14_export_tbl)"
  ckpt_done CL-9.3 || { cl14_stop "CL-9.3 is not DONE" "CL-9.3 DONE" || return 1; }
  cl14_bd_has BD-14-02 || { cl14_stop "BD-14-02 (CL-9.2) is not in DEVIATION_REGISTER: nothing to close" "BD-14-02 in DEVIATION_REGISTER (CL-9.2)" || return 1; }
  if [ "$AGP_MODE" != apply ] || ! rm="$(cl14_last 'CL-9.4-role-removed.txt')"; then
    # part 1: an append made 48 hours ago or more
    cl14_bq_rows "SELECT 1 AS running FROM $tbl WHERE export_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 48 HOUR) LIMIT 1"
    case $? in
      0|3) ;;
      1) if [ "$AGP_MODE" = apply ]; then
           agp_say "      STOP: no append is 48 hours old yet; CL-9.3 was less than 48 hours ago (or its export has not started). Nothing changed: resume later"
           return 98
         fi;;
      *) cl14_stop "the standard usage cost export table is not readable (CL-9.3: within 24 hours bq ls lists it)" "the standard usage cost export table readable" || return 1;;
    esac
    [ "$AGP_MODE" = apply ] || agp_say "      requires: an append 48 hours old (the query above returns a row), else STOP and resume later"
    # part 2: the removal, read back from the policy it returns, and its time recorded
    if [ "$AGP_MODE" != apply ]; then
      x gcloud projects remove-iam-policy-binding "$lp" --member="$m" --role="roles/bigquery.user" --condition=None --format=json
      agp_say "      requires: the policy it returns binds no roles/bigquery.user to $m"
    else
      has_binding "$m" roles/bigquery.user gcloud projects get-iam-policy "$lp"; rc=$?
      case $rc in
        0) pol="$(x gcloud projects remove-iam-policy-binding "$lp" --member="$m" --role="roles/bigquery.user" --condition=None --format=json)" || return 1
           if printf '%s' "$pol" | cl14_py shows etag 2>/dev/null; then
             if printf '%s' "$pol" | cl14_py roles-of "$m" | grep -qx 'roles/bigquery.user'; then
               echo "      STOP: the policy returned still binds roles/bigquery.user to $m"; return 1
             fi
             echo "      the policy returned binds no roles/bigquery.user to $m"
           else
             echo "      the removal printed no policy: compare CL-9.2's policy table by hand (it must be empty)"
           fi;;
        1) echo "      $m holds no roles/bigquery.user on $lp: nothing to remove";;
        *) return 1;;
      esac
    fi
    rm="$(cl14_rec CL-9.4-role-removed.txt)"
    date -u +%Y-%m-%dT%H:%M:%SZ | xw "$rm" || return 1
    { echo "== role removed at"; [ "$AGP_MODE" = apply ] && cat "$rm"
      echo "== rows per day, last 3 days"
      cl14_r bq --location="$(v BQ_LOCATION)" --project_id="$lp" query --use_legacy_sql=false --format=pretty \
        "SELECT DATE(usage_start_time) AS d, COUNT(*) AS n FROM $tbl WHERE usage_start_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 DAY) GROUP BY d ORDER BY d"
      echo "== Security Command Center SKUs, last 35 days"
      cl14_r bq --location="$(v BQ_LOCATION)" --project_id="$lp" query --use_legacy_sql=false --format=pretty \
        "SELECT service.description AS service, sku.description AS sku, ROUND(SUM(cost),2) AS cost FROM $tbl WHERE service.description LIKE '%Security Command Center%' AND usage_start_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 35 DAY) GROUP BY 1,2 ORDER BY cost DESC"
    } | cl14_keep CL-9.4 billing-export-running E-05 "4.1.3, 6.1" txt || cl14_planok || return 1
    [ "$AGP_MODE" != apply ] || echo "      the billing administrator ($(v BILLING_ADMIN_EMAIL)) confirms the rows above; the SCC result (possibly empty under P11's subscription branch) goes to SD-15"
  else
    echo "      $rm: the role was removed at $(tail -n 1 "$rm"); parts 1 and 2 are not repeated"
  fi
  # part 3: an append made after the removal, then the closure of BD-14-02
  if [ "$AGP_MODE" = apply ]; then at="$(tail -n 1 "$rm")"; else at="<REMOVED_AT>"; fi
  cl14_bq_rows "SELECT 1 AS arrived FROM $tbl WHERE export_time > TIMESTAMP('$at') LIMIT 1"
  case $? in
    0|3) ;;
    1) if [ "$AGP_MODE" = apply ]; then
         agp_say "      STOP: no append since the removal at $at yet: resume later the same day or the next. If none has arrived 48 hours"
         agp_say "      after the removal, the role is restored under a signed SD-16 note, BD-14-02 stays open, and the finding is recorded"
         return 98
       fi;;
    *) return 1;;
  esac
  [ "$AGP_MODE" = apply ] || agp_say "      requires: an append after the removal (the query above returns a row), else STOP and resume later"
  x bd_close BD-14-02 "roles/bigquery.user removed by 14 CL-9.4; export rows arriving after the removal" "14 CL-9.4" || return 1
  [ "$AGP_MODE" = apply ] || return 0
  cl14_bd_closed BD-14-02 || { echo "      STOP: bd_close wrote no closure of BD-14-02"; return 1; }
  echo "      shared account (07 BA-1.2 branch b): the authorised view platform_logs_views.billing_platform of setup/14 CL-9.4, by hand"
}

# ------------------------------------------------------------------ 10. The locks
cl14_days_ok() {    # cl14_days_ok VALUE LOW: an integer within LOW..3650
  case "$1" in ''|*[!0-9]*) return 1;; esac
  [ "$1" -ge "$2" ] && [ "$1" -le 3650 ]
}

step CL-10.1 AUTO "Set the signed retention values and read everything back before locking" --witness --gate "P13" --on-unmet skip \
  --needs "LOGGING_PROJECT REGION KEY_PLATFORM_LOGS EVIDENCE_RETENTION_DAYS IDENTITY_RETENTION_DAYS BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_10_1_check() {
  local a b
  cl14_bucket_ok platform-evidence-logs "retentionDays=$(v EVIDENCE_RETENTION_DAYS)"; a=$?
  cl14_bucket_ok platform-identity-logs "retentionDays=$(v IDENTITY_RETENTION_DAYS)"; b=$?
  cl14_worst $a $b
}
s_CL_10_1_apply() {
  cl14_under "a fresh ENT_FOLDER_ADMIN grant for this sitting (CL-2.1's request); the second human present"
  local lp rg ed idd h b w bad=0
  lp="$(v LOGGING_PROJECT)"; rg="$(v REGION)"; ed="$(v EVIDENCE_RETENTION_DAYS)"; idd="$(v IDENTITY_RETENTION_DAYS)"
  if [ "$AGP_MODE" = apply ]; then
    cl14_days_ok "$ed" 400 || { echo "      STOP: EVIDENCE_RETENTION_DAYS '$ed' is not an integer in 400..3650"; return 1; }
    cl14_days_ok "$idd" 183 || { echo "      STOP: IDENTITY_RETENTION_DAYS '$idd' is not an integer in 183..3650"; return 1; }
    [ "$idd" -ge 400 ] || echo "      the identity value is below 400: the second human reads aloud the P13 line that says so"
  fi
  h="$(cl14_ckpt_age_h CL-6.5)" || { cl14_stop "CL-6.5 is not DONE" "CL-6.5 DONE less than 7 days ago" || return 1; h=0; }
  [ "$h" -lt 168 ] || { cl14_stop "CL-6.5's proof is $h hours old: repeat it (less than 7 days) before the locks" "CL-6.5 DONE less than 7 days ago" || return 1; }
  x gcloud logging buckets update platform-evidence-logs --location="$rg" --retention-days="$ed" \
    --description="Platform evidence: folder audit families, organisation-level entries, billing-account audit log (08 S12)" --project="$lp" || return 1
  x gcloud logging buckets update platform-identity-logs --location="$rg" --retention-days="$idd" --project="$lp" || return 1
  { for b in platform-evidence-logs platform-identity-logs; do
      r gcloud logging buckets describe "$b" --location="$rg" --project="$lp" --format="yaml(name,retentionDays,locked,cmekSettings.kmsKeyName,analyticsEnabled)"
      r gcloud logging views list --bucket="$b" --location="$rg" --project="$lp" --format="value(name)"
    done
    r gcloud logging sinks list --project="$lp" --format="table(name,destination,disabled)"
  } | cl14_keep CL-10.1 pre-lock-readback E-06 "5.2.4, 7.1" txt || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  cl14_bucket_ok platform-evidence-logs "retentionDays=$ed AND NOT locked=true AND cmekSettings.kmsKeyName=\"$(v KEY_PLATFORM_LOGS)\"" || { echo "      platform-evidence-logs: not $ed days, unlocked, on the key"; bad=1; }
  cl14_bucket_ok platform-identity-logs "retentionDays=$idd AND NOT locked=true AND cmekSettings.kmsKeyName=\"$(v KEY_PLATFORM_LOGS)\"" || { echo "      platform-identity-logs: not $idd days, unlocked, on the key"; bad=1; }
  for b in $(cl14_views); do
    w="${b#*:}"; b="${b%%:*}"
    exists gcloud logging views describe "$w" --bucket="$b" --location="$rg" --project="$lp" --format="value(name)" || { echo "      view $w missing on $b"; bad=1; }
  done
  cl14_sink_ok "--project=$lp" to-evidence-bucket "$(cl14_dest_bucket platform-evidence-logs)" || { echo "      to-evidence-bucket is not enabled"; bad=1; }
  cl14_sink_ok "--project=$lp" to-identity-bucket "$(cl14_dest_bucket platform-identity-logs)" || { echo "      to-identity-bucket is not enabled"; bad=1; }
  [ $bad = 0 ] && echo "      write the P13 record's commit id in the build log"
  return $bad
}

cl14_lock() {   # cl14_lock STEP BUCKET VAR SLUG TISAX: CL-10.2 and CL-10.3
  local st="$1" bk="$2" days lp rg
  days="$(v "$3")"; lp="$(v LOGGING_PROJECT)"; rg="$(v REGION)"
  ckpt_done CL-10.1 || { cl14_stop "CL-10.1 has no DONE line" "CL-10.1 DONE" || return 1; }
  if [ "$AGP_MODE" = apply ]; then
    cl14_bucket_ok "$bk" "retentionDays=$days" || { echo "      STOP: the retention of $bk differs from P13 ($days)"; return 1; }
  fi
  agp_say "      confirm: CL-10.1's read-back (europe-west1, the key, the views); retention $days equals P13; the second human present"
  x checkpoint "$st" START "$(v SECOND_HUMAN_EMAIL)" - "lock ${bk%-logs} bucket at ${days} days" || return 1
  x gcloud logging buckets update "$bk" --location="$rg" --locked --project="$lp" || return 1
  r gcloud logging buckets describe "$bk" --location="$rg" --project="$lp" --format="value(locked,retentionDays)" \
    | cl14_keep "$st" "$4" E-06 "$5" txt || cl14_planok || return 1
  [ "$AGP_MODE" = apply ] || return 0
  cl14_bucket_ok "$bk" "locked=true AND retentionDays=$days" || { echo "      STOP: $bk does not read back locked at $days days"; return 1; }
  echo "      the second human now tries one retention change of their choice, which must be refused; its error goes in the record,"
  echo "      signed by both (copied to the platform evidence bucket under SD-38)"
}

step CL-10.2 AUTO "Lock platform-evidence-logs" --irreversible --witness --gate "P13" --on-unmet skip \
  --needs "LOGGING_PROJECT REGION EVIDENCE_RETENTION_DAYS SECOND_HUMAN_EMAIL BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_10_2_check() { cl14_bucket_ok platform-evidence-logs "locked=true"; }
s_CL_10_2_apply() { cl14_lock CL-10.2 platform-evidence-logs EVIDENCE_RETENTION_DAYS evidence-bucket-locked 5.2.4; }

step CL-10.3 AUTO "Lock platform-identity-logs" --irreversible --witness --gate "P13" --on-unmet skip \
  --needs "LOGGING_PROJECT REGION IDENTITY_RETENTION_DAYS SECOND_HUMAN_EMAIL BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_10_3_check() { cl14_bucket_ok platform-identity-logs "locked=true"; }
s_CL_10_3_apply() {
  agp_say "      confirm also: the DPO's signature on the identity value in P13 (a locked identity bucket answers erasure by disclosure)"
  cl14_lock CL-10.3 platform-identity-logs IDENTITY_RETENTION_DAYS identity-bucket-locked "5.2.4, 7.1"
}

# ------------------------------------------------------------------ 11. Closing the sitting
CL14_ENTS="ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CORE ENT_ORG_SINK"

# The page's block ends with sitting_end, which revokes every credential. The script never runs it: a
# multi-phase apply would carry on in a credential-less shell, and sitting_end passes --quiet. What the
# script does is the read: the three grant tables, written as the record once no grant is ACTIVE, so the
# step is AUTO-READ. The operator then ends the sitting with agp-platform sitting end, which runs
# sitting_end (SITTING-END OK) and writes the sitting's DONE line.
step CL-11.1 AUTO-READ "End every grant and every credential" \
  --needs "ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CORE ENT_ORG_SINK CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_CL_11_1_check() { ckpt_done CL-11.1; }
s_CL_11_1_apply() {
  # The page's form: --entitlement is the full resource name, which names the scope (organizations/,
  # folders/ or projects/.../locations/global/entitlements/ID), so no --location or scope flag is added.
  local n e tables="" active="" a
  for n in $CL14_ENTS; do
    e="$(v "$n")"
    tables="$tables== $e
$(cl14_r gcloud pam grants search --entitlement="$e" --caller-relationship=had-created --billing-project="$(v CICD_PROJECT)" --format="table(name,state)")
"
    a="$(r gcloud pam grants search --entitlement="$e" --caller-relationship=had-created --billing-project="$(v CICD_PROJECT)" --filter="state=ACTIVE" --format="value(name)")" \
      || cl14_planok || { echo "      STOP: the grants of $n could not be read (is it the full entitlement name?)"; return 1; }
    [ -z "$a" ] || active="$active $a"
  done
  if [ "$AGP_MODE" = apply ]; then
    printf '%s' "$tables" | sed 's/^/      /'
    if [ -n "$active" ]; then
      echo "      STOP: grants still ACTIVE:$active"
      echo "      an approver revokes each: gcloud pam grants revoke <grant name> --billing-project=$(v CICD_PROJECT) (the full grant name carries"
      echo "      its scope), or lets it expire"
      return 1
    fi
  fi
  printf '%s' "$tables" | cl14_keep CL-11.1 grants-ended E-08 4.1.3 txt || return 1
  if [ "$AGP_MODE" = apply ]; then agp_say "      no grant created by this sitting is ACTIVE"; else agp_say "      requires: no grant created by this sitting ACTIVE"; fi
  agp_say "      then end the sitting: agp-platform sitting end (SITTING-END OK)"
  agp_say "      the SITTING-END OK line and the sitting's DONE line in checkpoints.tsv complete this step's evidence"
  agp_say "      the platform owner then holds no role on LOGGING_PROJECT, the folder or the organisation from this file"
}

step CL-11.2 HUMAN "Write the Tier R \"central logging\" record and the handoffs" --witness --needs "BUILD_LOG_DIR"
s_CL_11_2_check() { ckpt_done CL-11.2; }
s_CL_11_2_manual() {
  echo "WHO: the platform owner writes; the second human co-signs the watch list."
  echo "WHERE: $(v BUILD_LOG_DIR)/records/<date>-CL-11.2-tier-r-central-logging.md; the re-run index."
  echo "DO: record CL-1.1 to CL-9.4 DONE, CL-8.5 BLOCKED, CL-10.x DONE or PENDING on P13, the evidence ids of CL-6.5 and CL-8.4 and the"
  echo "    variables produced; copy setup/14 CL-11.2's watch-list table (15 part A now, 25 later)."
  echo "RE-RUN ROWS: CL-3.3, CL-3.4, CL-7.3 (written by this run when PENDING), CL-6.1 before 19's move, CL-10.1 to CL-10.3 on P13"
  echo "    (P13 unsigned kept CL-10 from running: checkpoint CL-10.1 PENDING - - \"P13 unsigned\" and the row \"P13 signed -> 14 CL-10.1"
  echo "    to CL-10.3\", unless already there), CL-8.5 on B-02, CL-6.6 weekly until 25."
  echo "VERIFY: the record commits; the co-signature is on the watch list; grep -c 'CL-' \"\$BUILD_LOG_DIR/rerun-index.tsv\" counts every open row."
  echo "RECORD: <date>-CL-11.2-tier-r-central-logging-v1, cited by 17's TIER_R_RECORD. Then: agp-platform done CL-11.2 --witness <second human email>"
}
