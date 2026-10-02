# phases/18-model-armor-floor-spikes-and-kill-switch.sh: setup/18, the Model Armor floors, the nonprod
# spikes and the fleet kill switch K7 (step prefix KS).
#
# How the page maps onto the classes:
# - Reads and gates (KS-0.1, KS-2.1, KS-2.7, KS-3.4, KS-7.3) are AUTO-READ: the reads, then the page's
#   VERIFY, non-zero when it fails. KS-1.4 is AUTO-READ too: it changes nothing in Google, records the two
#   canary-r values it reads (penv_set) and runs 17's zero-diff checker.
# - A PAM request whose approver is the second human (KS-1.2, KS-2.4) is AUTO: the script requests the
#   grant, then waits for ACTIVE while the second human approves in the console. PAM refuses a second
#   request while one is active or awaiting approval, so a resumed run waits for the first one instead.
#   An approver or a pull-request reviewer is not a witness present: the PAM grant or the merge record is
#   that evidence, so only steps whose WHO names a second person present or co-signing, or whose VERIFY
#   puts the second human in the checkpoint's witness field (KS-3.7, KS-4.2, KS-6.3 to KS-6.5, KS-7.1),
#   carry --witness. A grant step counts as done once the work it was requested for is done.
# - The floor writes, the project-floor rule PF and the code-free spikes P4 (KS-3.1) and P8 part a
#   (KS-3.2) are AUTO: each spike classifies its own outcome (passed, failed, not tested) and writes a
#   record; "not tested" stops for a person to read the error.
# - Where the page itself says STOP until a person acts (a grant to approve or re-request, a file to merge,
#   a read-back that differs and calls for the ROLLBACK, a spike result to read, 13's rule names to adjust),
#   _apply prints why and returns 98 (_ks_person). A failed command is any other non-zero status. The
#   read-back of each floor write compares every field with floors.json's rest block in _apply and writes the
#   result into the step's record; the check is the DONE line, or that record and a fresh matching read-back.
# - The steps that end in a pull request the second human approves (KS-2.3, KS-2.10, KS-4.1) are HUMAN,
#   as phases 03, 16 and 21 treat git-host steps: their blocks push and run gh. The AUTO steps that use
#   their files (KS-2.5, KS-2.6, KS-2.9 read model-armor/floors.json; KS-7.2 reads the KF-2 list) read
#   them on origin/main, as the last git pull left it, and stop until they are merged there.
# - Hand work is HUMAN: the register row (KS-1.1), FM-AGENT for canary-r (KS-1.3, 17's procedure,
#   IRREVERSIBLE project id), IT security's organisation floor (KS-2.2), the spike records (KS-3.7), the
#   activation-page proof (KS-4.2), and the whole drill of section 6, which runs in one /bin/bash
#   shell whose variables and functions (SEL, DR, stamp, probe_owner, probe_sa) carry from KS-6.1 to
#   KS-6.5. Pulling the levers (KS-6.3) and lifting them (KS-6.4) are HUMAN --witness.
# - Code that does not exist (README B-04) is BLOCKED: KS-1.5, KS-3.3, KS-3.5, KS-3.6, KS-5.1 to KS-5.3,
#   KS-6.6.
# - Run order of section 2 (the page's note): KS-2.1 reads with canary-r as the quota project, which
#   needs KS-2.4's repair grant. KS-2.1 is registered first, as the page numbers it; when no repair grant
#   is active it stops (98) and says to run KS-2.2 to KS-2.4 first, then resume from KS-2.1.
# - The page's waits (20 s grant polls, 120 s and 420 s propagation) are multiplied by AGP_WAIT_SCALE, a whole
#   number, 1 when unset (the offline tests set 0), as phase 13 does.
# - Every gcloud call names its scope: --project, --folder or --organization, the entitlement's own
#   scope for PAM, or the resource itself where the command takes no scope flag (--full-uri of a floor
#   setting, --attachment-point of a deny policy, --scope of an asset search, the name inside a policy
#   file). Model Armor calls set the endpoint override for that one command, through the environment.
#
# Helpers are prefixed _ks_. They only read, compute or format; every change goes through x, xw, pset,
# ev or api.

phase 18 "Model Armor floor, nonprod spikes and the fleet kill switch" "18-model-armor-floor-spikes-and-kill-switch.md"
requires org "orgpolicy.policy.get iam.denypolicies.get"

# ---------------------------------------------------------------- helpers
_ks_today() { date -u +%F; }
_ks_off() { [ "$AGP_OFFLINE" = 1 ]; }

_ks_rec() {     # NAME: BUILD_LOG_DIR/records/<today>-NAME
  printf '%s/records/%s-%s' "$(v BUILD_LOG_DIR)" "$(_ks_today)" "$1"
}

_ks_latest() {  # NAME: the newest records/<date>-NAME, or nothing
  local f last=""
  for f in "$(v BUILD_LOG_DIR)"/records/*-"$1"; do [ -f "$f" ] && last="$f"; done
  printf '%s' "$last"
}

_ks_keep() {    # STEP SLUG E-ID TISAX NAME < content: write records/<today>-NAME; register it unless E-ID is none
  local f d; f="$(_ks_rec "$5")"; d="${f%/*}"
  if [ "$AGP_MODE" = apply ] && [ ! -d "$d" ]; then x mkdir -p "$d" || return 1; fi
  xw "$f" || return 1
  [ "$3" = none ] && return 0
  ev "$1" "$2" "$3" "$4" "build-log:records/${f##*/}" "$f"
}

_ks_get() {     # CMD...: print what a read returns. 0 read, 1 not found, 2 another error (shown), 3 offline
  _ks_off && return 3
  local err out rc; err="$(mktemp "${TMPDIR:-/tmp}/agp-ks.XXXXXX")" || return 2
  out="$("$@" 2>"$err")"; rc=$?
  if [ $rc -ne 0 ]; then
    if grep -qiE 'NOT_FOUND|not found|does not exist|404' "$err"; then rm -f "$err"; return 1; fi
    sed 's/^/        /' "$err" >&3; rm -f "$err"; return 2
  fi
  rm -f "$err"; printf '%s' "$out"
}

_ks_stop() { agp_say "      STOP: $*"; return 1; }

# _ks_person WHY: the page's own STOP until a person acts (a merge, an approval, a rollback, reading an error);
# the runner stops with "a person must act first ... then resume" (PHASES.md, return 98). Never for a failed command.
_ks_person() { agp_say "      STOP: $*"; return 98; }

# _ks_pre CMD...: a read inside _apply that repeats a check (did the step's own clean-up remove it?). It is
# marked as a check for the offline fakes, which otherwise answer every read inside apply as "present", as
# phases 15, 21 and 42 do; gcloud ignores the variable.
_ks_pre() { AGP_CALL_CONTEXT=check "$@"; }

_ks_sleep() {   # SECONDS: a wait the page prescribes, multiplied by AGP_WAIT_SCALE (a whole number, 1 when unset)
  local s="${AGP_WAIT_SCALE:-1}"
  case "$s" in ''|*[!0-9]*) agp_warn "AGP_WAIT_SCALE '$s' is not a whole number; the page's $1 s wait is kept"; s=1;; esac
  sleep $(($1 * s))
}

_ks_says() {    # NAME PATTERN: the newest records/<date>-NAME holds a line matching PATTERN (grep -E)
  local f; f="$(_ks_latest "$1")"
  [ -n "$f" ] && grep -qE "$2" "$f"
}

_ks_ep() { printf 'CLOUDSDK_API_ENDPOINT_OVERRIDES_MODELARMOR=%s' "${1:-https://modelarmor.googleapis.com/}"; }

_ks_json_src() {
  cat <<'PY'
import json, re, sys
op, a = sys.argv[1], sys.argv[2:]
def load(f=None):
    raw = (open(f).read() if f else sys.stdin.read()).strip()
    return json.loads(raw) if raw else {}
def rai(lst):
    return sorted((x.get('filterType', '') + ':' + x.get('confidenceLevel', '')) for x in (lst or []))
def floor(f, level):
    for x in load(f).get('floors', []):
        if x.get('level') == level:
            return x
    sys.exit(1)
ORDER = {'LOW_AND_ABOVE': 0, 'MEDIUM_AND_ABOVE': 1, 'HIGH': 2}
TIGHT = (',', ':')
if op == 'allow-count':          # stdin effective policy: the number of allowed values
    s = load().get('spec') or {}
    print(sum(len((r.get('values') or {}).get('allowedValues') or []) for r in s.get('rules') or []))
elif op == 'allow-has':          # NAME, stdin effective policy: true|false
    s = load().get('spec') or {}
    print('true' if any(a[0] in ((r.get('values') or {}).get('allowedValues') or []) for r in s.get('rules') or []) else 'false')
elif op == 'floor-field':        # FLOORS LEVEL KEY: one value of floors.json, in the form the page's jq prints it
    fl = floor(a[0], a[1]); k = a[2]
    if k == 'full-uri': print(fl['full_uri'])
    elif k == 'gcloud-pi': print(fl['gcloud']['pi'])
    elif k == 'rest-pi': print(fl['rest']['pi'])
    elif k == 'rai-gcloud': print(json.dumps(fl['gcloud']['rai'], separators=TIGHT))
    elif k == 'rai-rest': print(json.dumps(fl['rest']['rai'], separators=TIGHT))
    elif k == 'rai-lower':
        print(json.dumps([dict(x, confidenceLevel=x['confidenceLevel'].lower().replace('_', '-')) for x in fl['gcloud']['rai']], separators=TIGHT))
    else: sys.exit(2)
elif op == 'floor-expect':       # FLOORS LEVEL: the canonical floor the rest block describes
    fl = floor(a[0], a[1]); r = fl['rest']
    print('enforce=%s pi=ENABLED:%s uri=%s rai=%s ml=%s' % (fl.get('enforce'), r['pi'], r['malicious_uri'], ','.join(rai(r['rai'])), fl.get('multi_language')))
elif op == 'floor-live':         # stdin describe JSON: the same canonical form
    d = load(); fc = d.get('filterConfig') or {}
    pi = fc.get('piAndJailbreakFilterSettings') or {}
    ml = ((d.get('floorSettingMetadata') or {}).get('multiLanguageDetection') or {}).get('enableMultiLanguageDetection')
    print('enforce=%s pi=%s:%s uri=%s rai=%s ml=%s' % (d.get('enableFloorSettingEnforcement'), pi.get('filterEnforcement'), pi.get('confidenceLevel'),
          (fc.get('maliciousUriFilterSettings') or {}).get('filterEnforcement'), ','.join(rai((fc.get('raiSettings') or {}).get('raiFilters'))), ml))
elif op == 'pf-check':           # TIER FLOORS, stdin project floor: the PF assertions of KS-2.9
    d = load(); fc = d.get('filterConfig') or {}; ai = d.get('aiPlatformFloorSetting') or {}; bad = []
    pi = fc.get('piAndJailbreakFilterSettings') or {}
    if d.get('enableFloorSettingEnforcement') is not True: bad.append('enforce is not true')
    if 'AI_PLATFORM' not in (d.get('integratedServices') or []): bad.append('integratedServices lacks AI_PLATFORM')
    if ai.get('enableCloudLogging') is not True: bad.append('aiPlatformFloorSetting.enableCloudLogging is not true')
    want = 'inspectAndBlock' if a[0] == 'P-SA' else 'inspectOnly'
    if ai.get(want) is not True: bad.append('aiPlatformFloorSetting.%s is not true' % want)
    if pi.get('filterEnforcement') != 'ENABLED': bad.append('PI is not ENABLED')
    if (fc.get('maliciousUriFilterSettings') or {}).get('filterEnforcement') != 'ENABLED': bad.append('malicious URI is not ENABLED')
    rf = (fc.get('raiSettings') or {}).get('raiFilters') or []
    if len(rf) != 4: bad.append('%d RAI filters, not 4' % len(rf))
    tier = floor(a[1], 'platform')
    if ORDER.get(pi.get('confidenceLevel'), 9) > ORDER.get(tier['rest']['pi'], -1): bad.append('PI level looser than the tier floor')
    for x in rf:
        if ORDER.get(x.get('confidenceLevel'), 9) > ORDER['MEDIUM_AND_ABOVE']: bad.append('RAI %s looser than MEDIUM_AND_ABOVE' % x.get('filterType'))
    if sorted(x.get('filterType') for x in rf) != ['DANGEROUS', 'HARASSMENT', 'HATE_SPEECH', 'SEXUALLY_EXPLICIT']: bad.append('RAI types are not the four')
    for b in bad: print('PF: ' + b)
    sys.exit(1 if bad else 0)
elif op == 'members-of':         # ROLE, stdin IAM policy: the role's members
    for b in load().get('bindings', []) or []:
        if b.get('role') == a[0]:
            for m in b.get('members', []): print(m)
elif op == 'deny-forms':         # AGENT_SET AGENT_PRINCIPAL SA_SET SA_ONE, stdin deny policy: "<agent form> <sa form>"
    rules = [r for r in load().get('rules', []) if re.match(r'^R[1-5] ', r.get('description') or '')]
    if not rules: print('norules norules'); sys.exit(0)
    def every(p): return all(p in ((r.get('denyRule') or {}).get('deniedPrincipals') or []) for r in rules)
    print(('set' if every(a[0]) else 'principal' if every(a[1]) else 'none') + ' ' + ('set' if every(a[2]) else 'single' if every(a[3]) else 'none'))
elif op == 'deny-add':           # AGENT SA, stdin deny policy: the page's ks32_update transform
    d = load()
    for r in d.get('rules', []):
        if re.match(r'^R[1-5] ', r.get('description') or ''):
            dr = r.setdefault('denyRule', {})
            dr['deniedPrincipals'] = sorted(set((dr.get('deniedPrincipals') or []) + [a[0], a[1]]))
    print(json.dumps({'displayName': d.get('displayName'), 'rules': d.get('rules'), 'etag': d.get('etag')}, indent=2))
elif op == 'cc1-mode':           # stdin CC-1 policy: enforced | dryrun | none
    d = load()
    if any(r.get('enforce') is True for r in (d.get('spec') or {}).get('rules') or []): print('enforced')
    elif d.get('dryRunSpec'): print('dryrun')
    else: print('none')
elif op == 'engine-name':        # stdin create response: the engine's resource name
    print(re.sub(r'/operations/.*$', '', load().get('name') or ''))
elif op == 'count-display':      # NAME, stdin reasoningEngines list
    print(len([e for e in load().get('reasoningEngines', []) or [] if e.get('displayName') == a[0]]))
elif op == 'k7-verify':          # K7_DIR: KS-4.1's VERIFY on the files
    import os; k = a[0]; bad = 0; d = os.path.join(k, 'restrict-service-usage')
    files = sorted(f for f in os.listdir(d) if f.endswith('.json')) if os.path.isdir(d) else []
    print('KF-1 files: %d' % len(files)); bad += len(files) != 8
    for f in files:
        av = (((load(os.path.join(d, f)).get('spec') or {}).get('rules') or [{}])[0].get('values') or {}).get('allowedValues') or []
        a1, r1 = 'aiplatform.googleapis.com' in av, 'run.googleapis.com' in av
        print('%s\t%d\t%s\t%s' % (f, len(av), str(a1).lower(), str(r1).lower())); bad += (len(av) == 0) or a1 or r1
    t = os.path.join(k, 'deny-agents-halt.template.json'); p = os.path.join(k, 'deny-agents-halt.permissions.txt')
    perms = (load(t).get('rules') or [{}])[0].get('denyRule', {}).get('deniedPermissions', []) if os.path.isfile(t) else []
    ok = bool(perms) and all('*' not in x and re.match(r'^[a-z0-9.-]+\.googleapis\.com/[A-Za-z]+\.[A-Za-z]+$', x) for x in perms)
    print('KF-2 permissions: %d, form %s' % (len(perms), 'ok' if ok else 'BAD')); bad += not ok
    listed = sorted(l.strip() for l in open(p)) if os.path.isfile(p) else []
    same = sorted(perms) == [l for l in listed if l]
    print('template and permissions.txt agree: %s' % same); bad += not same
    for f in ('scheduler-pause.txt', 'pab-empty.json', 'README.md'):
        e = os.path.isfile(os.path.join(k, f)); print('%s: %s' % (f, 'present' if e else 'MISSING')); bad += not e
    sys.exit(1 if bad else 0)
elif op == 'spelling':           # FLOORS: .spellings.accepted
    print((load(a[0]).get('spellings') or {}).get('accepted', ''))
else:
    sys.exit(2)
PY
}

_ks_json() { python3 -c "$(_ks_json_src)" "$@"; }

# ---- PAM: an entitlement's full name (organizations|folders|projects/X/locations/L/entitlements/ID) is
# passed as id, location and scope flag, so every gcloud pam call names its scope (gcloud reference).
_ks_ent_id() { local n; n="$(v "$1")"; case "$n" in */entitlements/*) printf '%s' "${n##*/}";; *) printf '%s' "$n";; esac; }
_ks_ent_loc() { local n; n="$(v "$1")"; case "$n" in */locations/*/entitlements/*) n="${n#*/locations/}"; printf '%s' "${n%%/*}";; *) printf 'global';; esac; }
_ks_ent_scope() {
  local n; n="$(v "$1")"
  case "$n" in
    organizations/*/entitlements/*) n="${n#organizations/}"; printf -- '--organization=%s' "${n%%/*}";;
    folders/*/entitlements/*) n="${n#folders/}"; printf -- '--folder=%s' "${n%%/*}";;
    projects/*/entitlements/*) n="${n#projects/}"; printf -- '--project=%s' "${n%%/*}";;
    *) _ks_ent_home "$1";;
  esac
}
_ks_ent_home() {   # VAR: the scope setup/12 (or 17 FM-2.17) creates the entitlement at, for a value that is a bare id
  case "$1" in
    ENT_PLATFORM_POLICY|ENT_K7_HUMAN|ENT_K7_EXECUTOR) printf -- '--organization=%s' "$(v ORG_ID)";;
    ENT_FOLDER_ADMIN|ENT_K7_HUMAN_SCHEDULER|ENT_K7_EXECUTOR_SCHEDULER) printf -- '--folder=%s' "$(v FLD_AGENTIC_PLATFORM)";;
    ENT_BOOTSTRAP_MODULE_R_NONPROD) printf -- '--folder=%s' "$(v FLD_AGENTS_R_NONPROD)";;
    ENT_PROJECT_REPAIR_CANARY_R|ENT_DEPLOY_CREDENTIAL_HOLDER_CANARY_R) printf -- '--project=%s' "$(v CANARY_R_PROJECT)";;
    *) agp_warn "$1: no known scope for the entitlement '$(v "$1")'"; return 1;;
  esac
}

_ks_grant_in() {    # VAR FILTER: 0 when the caller has a grant on the entitlement in that state (1 none, 2 error, 3 offline)
  local sc; sc="$(_ks_ent_scope "$1")" || return 2
  nonempty r gcloud pam grants search --entitlement="$(_ks_ent_id "$1")" --location="$(_ks_ent_loc "$1")" "$sc" \
    --caller-relationship=had-created --filter="$2" --billing-project="$(v CICD_PROJECT)" --format="value(name)"
}
_ks_active() { _ks_grant_in "$1" "state=ACTIVE"; }
_ks_both_active() { # VAR VAR: both grants ACTIVE. Both are read every time, so the answer is the same whichever is missing
  local a b; _ks_active "$1"; a=$?; _ks_active "$2"; b=$?
  [ $a = 0 ] && [ $b = 0 ] && return 0
  [ $a = 3 ] || [ $b = 3 ] && return 3
  [ $a = 2 ] || [ $b = 2 ] && return 2
  return 1
}

_ks_grant() {       # VAR DURATION JUSTIFICATION [--additional-email-recipients=...]: request once, then wait for ACTIVE
  local var="$1" dur="$2" just="$3" sc i; shift 3
  sc="$(_ks_ent_scope "$var")" || return 1
  if [ "$AGP_MODE" != apply ]; then
    x gcloud pam grants create --entitlement="$(_ks_ent_id "$var")" --location="$(_ks_ent_loc "$var")" "$sc" \
      --requested-duration="$dur" --justification="$just" "$@" --billing-project="$(v CICD_PROJECT)"
    agp_say "      then wait until the grant on $var is ACTIVE (the approver setup/12 names approves in the console)"
    return 0
  fi
  # The check found no ACTIVE grant, so the grant is requested. PAM refuses a request "with the same scope as
  # an existing grant in the Active, Scheduled, or Approval awaited state" (request page, read 2026-10-01): on a
  # resumed run that refusal is read as "already requested", and the step waits for that grant instead.
  if ! x gcloud pam grants create --entitlement="$(_ks_ent_id "$var")" --location="$(_ks_ent_loc "$var")" "$sc" \
      --requested-duration="$dur" --justification="$just" "$@" --billing-project="$(v CICD_PROJECT)"; then
    _ks_grant_in "$var" "state=APPROVAL_AWAITED OR state=ACTIVATING OR state=SCHEDULED OR state=ACTIVE" || return 1
    agp_say "      a grant on $var already exists (awaiting approval, scheduled or active); waiting for it, not requesting again"
  fi
  i=0
  while [ $i -lt 90 ]; do
    _ks_active "$var" && { agp_say "      $var: ACTIVE"; return 0; }
    [ $i = 0 ] && agp_say "      waiting for the approval of the grant on $var (polls every 20 s, up to 30 minutes)"
    _ks_sleep 20; i=$((i + 1))
  done
  _ks_person "the grant on $var is still not ACTIVE after 30 minutes: the approver acts in the PAM console; when it is approved, re-run this step (it will not request again)"
}

_ks_need_active() { # VAR WHY: the page's PRECONDITION. 98 (a person re-requests the grant) unless an ACTIVE grant exists
  [ "$AGP_MODE" = apply ] || { agp_say "      precondition: an ACTIVE grant on $1 ($2)"; return 0; }
  _ks_active "$1" && return 0
  _ks_person "no ACTIVE grant on $1 ($2). Grants last one hour: re-request it with agp-platform apply --phase 18 --from KS-2.4 (repair and folder-admin grants) or as the step's manual says (the second human approves), then resume here"
}

# ---- the platform repository: what is merged is read on origin/main, as the last git pull left it
_ks_repo() { v PLATFORM_REPO_DIR; }
_ks_on_main() { git -C "$(_ks_repo)" cat-file -e "origin/main:$1" 2>/dev/null; }
_ks_main_file() { git -C "$(_ks_repo)" show "origin/main:$1" 2>/dev/null; }

# ---- Model Armor
_ks_floor_uri() { printf '%s/locations/global/floorSetting' "$1"; }
_ks_floors() { printf '%s/model-armor/floors.json' "$(_ks_repo)"; }

_ks_spelling() {    # the accepted write form: floors.json once KS-2.10 merged it, else KS-2.5's record
  local s f
  s="$(_ks_json spelling "$(_ks_floors)" 2>/dev/null)"
  case "$s" in gcloud|gcloud-lower|rest) printf '%s' "$s"; return 0;; esac
  f="$(_ks_latest KS-2.5-platform-floor-v1.txt)"
  [ -n "$f" ] || return 1
  s="$(sed -n '1s/^accepted spelling: //p' "$f")"
  case "$s" in gcloud|gcloud-lower) printf '%s' "$s";; *) return 1;; esac
}

_ks_ma_write() {    # URI RAI PI PIE MU [FLAG...]: the page's ma_write, through x
  local u="$1" ra="$2" pi="$3" pie="$4" mu="$5"; shift 5
  x env "$(_ks_ep)" gcloud model-armor floorsettings update --full-uri="$u" --pi-and-jailbreak-filter-settings-enforcement="$pie" \
    --pi-and-jailbreak-filter-settings-confidence-level="$pi" --malicious-uri-filter-settings-enforcement="$mu" \
    --rai-settings-filters="$ra" --enable-multi-language-detection --enable-floor-setting-enforcement=TRUE \
    --billing-project="$(v CANARY_R_PROJECT)" "$@"
}

_ks_floor_ok() {    # LEVEL URI: the live floor equals the level's rest block (0), differs (1), or cannot be read
  _ks_off && return 3
  local j rc want got
  [ -f "$(_ks_floors)" ] || return 1
  j="$(_ks_get env "$(_ks_ep)" gcloud model-armor floorsettings describe --full-uri="$2" --billing-project="$(v CANARY_R_PROJECT)" --format=json)"; rc=$?
  [ $rc = 0 ] || return $rc
  want="$(_ks_json floor-expect "$(_ks_floors)" "$1")" || return 2
  got="$(printf '%s' "$j" | _ks_json floor-live)" || return 1
  [ "$want" = "$got" ] && return 0
  [ "$AGP_CALL_CONTEXT" != apply ] || agp_say "      $1: expected [$want], read [$got]"
  return 1
}

_ks_tier_uri() {    # LEVEL: the floor URI of a floors.json level, from the folder variables
  case "$1" in
    platform) _ks_floor_uri "folders/$(v FLD_AGENTIC_PLATFORM)";;
    tier-w) _ks_floor_uri "folders/$(v FLD_AGENTS_W)";;
    tier-p) _ks_floor_uri "folders/$(v FLD_AGENTS_P)";;
    tier-p-sa) _ks_floor_uri "folders/$(v FLD_AGENTS_P_SA)";;
    controllers) _ks_floor_uri "folders/$(v FLD_CONTROLLERS)";;
  esac
}

_ks_pf_ok() {       # [quiet]: PF's VERIFY on canary-r: the project floor and exactly one modelarmor.user member
  _ks_off && return 3
  local j rc m sa
  [ -f "$(_ks_floors)" ] || return 1
  j="$(_ks_get env "$(_ks_ep)" gcloud model-armor floorsettings describe --full-uri="$(_ks_floor_uri "projects/$(v CANARY_R_PROJECT)")" \
        --billing-project="$(v CANARY_R_PROJECT)" --format=json)"; rc=$?
  [ $rc = 0 ] || return $rc
  if [ "$AGP_CALL_CONTEXT" = apply ] && [ "${1-}" != quiet ]; then printf '%s' "$j" | _ks_json pf-check R "$(_ks_floors)" >&3 || return 1
  else printf '%s' "$j" | _ks_json pf-check R "$(_ks_floors)" >/dev/null || return 1; fi
  j="$(_ks_get gcloud projects get-iam-policy "$(v CANARY_R_PROJECT)" --format=json)"; rc=$?
  [ $rc = 0 ] || return $rc
  m="$(printf '%s' "$j" | _ks_json members-of roles/modelarmor.user)"
  sa="serviceAccount:service-$(v CANARY_R_PROJECT_NUMBER)@gcp-sa-aiplatform.iam.gserviceaccount.com"
  [ "$m" = "$sa" ] && return 0
  [ "$AGP_CALL_CONTEXT" != apply ] || [ "${1-}" = quiet ] || agp_say "      roles/modelarmor.user members are [$(printf '%s' "$m" | tr '\n' ' ')], not exactly $sa"
  return 1
}

# ---- a POST as an impersonated service account: the token goes to curl on standard input, as api does
_ks_sa_post() {     # SA URL BODY_FILE OUT_FILE: prints the HTTP code
  printf 'Authorization: Bearer %s\n' "$(gcloud auth print-access-token --impersonate-service-account="$1")" \
    | curl -sS -o "$4" -w '%{http_code}' -X POST -H @- -H 'Content-Type: application/json' --data-binary @"$3" "$2"
}

_ks_exp() {         # HOURS: an RFC 3339 time that many hours from now (BSD date, then GNU)
  date -u -v+"$1"H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "+$1 hours" +%Y-%m-%dT%H:%M:%SZ
}

_ks_ckpt_field() {  # STEP STATUS FIELD: a field of the step's last checkpoint line with that status
  [ -f "$(v BUILD_LOG_DIR)/checkpoints.tsv" ] || return 1
  awk -F'\t' -v s="$1" -v st="$2" -v f="$3" '$2 == s && $3 == st {v = $f} END {if (v == "") exit 1; print v}' "$(v BUILD_LOG_DIR)/checkpoints.tsv"
}

_ks_bd_has() {      # ID: the deviation register's first table holds the row
  [ -f "$(v DEVIATION_REGISTER)" ] || return 1
  awk -F' *[|] *' -v id="$1" '$2 == id && NF == 15 {f = 1} END {exit f ? 0 : 1}' "$(v DEVIATION_REGISTER)"
}

_ks_say_done() { printf 'Then: agp-platform done %s%s\n' "$1" "${2:+ --witness <$2>}"; }

# ---------------------------------------------------------------- 0. The sitting
step KS-0.1 AUTO-READ "Open the sitting and check the gates" --gate "NAMES SD-01 SD-22 SD-36 SD-41 SD-46 P67" \
  --needs "SA_1_ADMIN ORG_ID REGION FLD_AGENTIC_PLATFORM FLD_AGENTS_R FLD_AGENTS_R_NONPROD FLD_AGENTS_R_PROD FLD_AGENTS_W FLD_AGENTS_W_NONPROD FLD_AGENTS_W_PROD FLD_AGENTS_P FLD_AGENTS_P_NONPROD FLD_AGENTS_P_PROD FLD_AGENTS_P_SA FLD_AGENTS_P_SA_NONPROD FLD_AGENTS_P_SA_PROD FLD_CONTROLLERS FLD_PLATFORM_CORE FLD_GEMINI_ENTERPRISE CICD_PROJECT CORE_PROJECT AR_PLATFORM SA_CI_BUILD SA_K7_EXECUTOR BINAUTHZ_ATTESTOR KEY_BINAUTHZ ENT_FOLDER_ADMIN ENT_PLATFORM_POLICY ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER ENT_K7_EXECUTOR ENT_K7_EXECUTOR_SCHEDULER ENT_BOOTSTRAP_MODULE_R_NONPROD ENT_DEPLOY_CREDENTIAL_HOLDER_CORE DENY_AGENTS_PLATFORM PAB_AGENTS TIER_R_RECORD REGISTER_PATH GRP_PLATFORM_APPROVERS GRP_PLATFORM_OWNERS SECOND_HUMAN_EMAIL DRILL_CALENDAR DEVIATION_REGISTER EVIDENCE_REGISTER BUILD_LOG_DIR PLATFORM_REPO_DIR"
s_KS_0_1_check() { ckpt_done KS-0.1; }
s_KS_0_1_apply() {
  local bad=0 rep acct t n id j rc c sr
  x checkpoint KS-0.1 START || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: penv_guard; gcloud config get account (must be SA_1_ADMIN); TIER_R_RECORD non-empty; '| DR-18-1 |' in DRILL_CALENDAR"
    agp_say "      read, per nonprod tier folder: gcloud org-policies describe gcp.restrictServiceUsage --folder=<id> --effective --format=json (allow-list length > 0)"
    agp_say "      read: gcloud iam policies get $(basename "$(v DENY_AGENTS_PLATFORM)") --attachment-point=cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM) --kind=denypolicies"
    agp_say "      read: gcloud iam principal-access-boundary-policies describe $(basename "$(v PAB_AGENTS)") --organization=$(v ORG_ID) --location=global (enforcement version 4)"
    _ks_keep KS-0.1 gates E-05 1.3.1 KS-0.1-gates-v1.txt < /dev/null
    return 0
  fi
  penv_guard >&3 2>&1 || { agp_say "      penv_guard failed (above)"; bad=1; }
  acct="$(gcloud config get account 2>/dev/null)"
  rep="account: $acct"
  [ "$acct" = "$(v SA_1_ADMIN)" ] || { agp_say "      not sa-1-admin@ ($acct): stop"; bad=1; }
  t="$(v TIER_R_RECORD)"
  if [ -s "$(v PLATFORM_REPO_DIR)/$t" ] || [ -s "$t" ]; then rep="$rep
TIER_R_RECORD: $t present"; else agp_say "      TIER_R_RECORD missing: stop"; bad=1; fi
  if grep -q '^| DR-18-1 |' "$(v DRILL_CALENDAR)" 2>/dev/null; then rep="$rep
DR-18-1: present"; else agp_say "      DR-18-1 missing from DRILL_CALENDAR (01 PR-4.3): stop"; bad=1; fi
  for n in FLD_AGENTS_R_NONPROD FLD_AGENTS_W_NONPROD FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA_NONPROD; do
    id="$(v "$n")"
    j="$(_ks_get gcloud org-policies describe gcp.restrictServiceUsage --folder="$id" --effective --format=json)"; rc=$?
    c=0; [ $rc = 0 ] && c="$(printf '%s' "$j" | _ks_json allow-count)"
    rep="$rep
$id allow-list length: $c"
    [ "${c:-0}" -gt 0 ] 2>/dev/null || { agp_say "      $n ($id): no allow-list (13 applies them): stop"; bad=1; }
  done
  j="$(_ks_get gcloud iam policies get "$(basename "$(v DENY_AGENTS_PLATFORM)")" --attachment-point="cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)" \
        --kind=denypolicies --format="value(name,etag)")" || { agp_say "      deny-agents-platform does not describe: stop"; bad=1; }
  rep="$rep
deny: $j"
  j="$(_ks_get gcloud iam principal-access-boundary-policies describe "$(basename "$(v PAB_AGENTS)")" --organization="$(v ORG_ID)" --location=global \
        --format="value(name,details.enforcementVersion)")" || { agp_say "      pab-agents does not describe: stop"; bad=1; }
  rep="$rep
pab: $j"
  case "$j" in *"	4") ;; *) agp_say "      pab-agents enforcement version is not 4: stop"; bad=1;; esac
  sr="$(_penv_get SECURITY_REVIEWER_EMAIL)"
  if has_value SECURITY_REVIEWER_EMAIL; then rep="$rep
SECURITY_REVIEWER_EMAIL: $sr"; else rep="$rep
SECURITY_REVIEWER_EMAIL: *tbd* (KS-2.3 and KS-6.5 record the missing signature)"; agp_say "      SECURITY_REVIEWER_EMAIL is *tbd*: KS-2.3 and KS-6.5 record the missing signature"; fi
  if [ $bad != 0 ]; then printf '%s\n' "$rep" | _ks_keep KS-0.1 gates none - KS-0.1-gates-v1.txt; return 1; fi
  printf '%s\n' "$rep" | _ks_keep KS-0.1 gates E-05 1.3.1 KS-0.1-gates-v1.txt
}

# ---------------------------------------------------------------- 1. canary-r
step KS-1.1 HUMAN "Merge the canary-r register row and manifest" --needs "PLATFORM_REPO_DIR REGISTER_PATH"
s_KS_1_1_check() { ckpt_done KS-1.1; }
s_KS_1_1_manual() {
  echo "WHO: the platform owner writes; two human reviewers approve under branch protection, the second human one of them."
  printf 'WHERE: %s, branch ks-1-1-canary-r, a pull request to PLATFORM_REPO_REMOTE.\n' "$(v PLATFORM_REPO_DIR)"
  printf 'DO: the row in %s and the canary-r manifest in 16'"'"'s schema, with setup/18 KS-1.1'"'"'s table: tier R, env nonprod,\n' "$(v REGISTER_PATH)"
  echo "  owner platform-owners@, purpose K7 canary and spike host (not-ai-system), the Tier R API subset WITHOUT agentregistry,"
  echo "  service_accounts canary-probe, publish_to_gemini false, no machine callers, no model pin, project_floor Custom INSPECT_ONLY."
  echo "  Then the page's block: switch main, pull --ff-only, switch -c ks-1-1-canary-r, edit, add, commit, push -u origin."
  printf 'VERIFY: register CI passes (or its signed manual parse); merged with two approvals; git -C %s log --oneline -1 origin/main -- %s\n' "$(v PLATFORM_REPO_DIR)" "$(v REGISTER_PATH)"
  echo "EVIDENCE: the merge commit as <date>-KS-1.1-canary-r-row-v1 (E-05)."
  _ks_say_done KS-1.1
}

step KS-1.2 AUTO "Obtain the ent-bootstrap-module-r-nonprod and ent-platform-policy grants" \
  --needs "ORG_ID ENT_BOOTSTRAP_MODULE_R_NONPROD ENT_PLATFORM_POLICY FLD_AGENTS_R_NONPROD CICD_PROJECT SECOND_HUMAN_EMAIL PLATFORM_REPO_DIR REGISTER_PATH BUILD_LOG_DIR"
s_KS_1_2_check() {
  ckpt_done KS-1.3 && return 0          # FM-AGENT has run: the grants did their work
  _ks_off && return 3
  _ks_both_active ENT_BOOTSTRAP_MODULE_R_NONPROD ENT_PLATFORM_POLICY
}
s_KS_1_2_apply() {
  local c
  c="$(git -C "$(v PLATFORM_REPO_DIR)" log -1 --format=%h origin/main -- "$(v REGISTER_PATH)" 2>/dev/null)"
  [ -n "$c" ] || c="see KS-1.1"
  _ks_grant ENT_BOOTSTRAP_MODULE_R_NONPROD 3600s "register row canary-r (merge $c); setup 18 KS-1.3 FM-AGENT" \
    --additional-email-recipients="$(v SECOND_HUMAN_EMAIL)" || return $?
  _ks_grant ENT_PLATFORM_POLICY 3600s "register row canary-r (merge $c); setup 18 KS-1.3 FM-2.15 deny entries and FM-2.16 pab-agents binding" \
    --additional-email-recipients="$(v SECOND_HUMAN_EMAIL)" || return $?
  agp_say "      ent-platform-policy lasts one hour: if FM-AGENT reaches FM-2.15 after it ended, re-request it there"
  printf 'KS-1.2 grants requested by the platform owner, approved by the second human (the PAM grant records the approval)\nmerge: %s\n' "$c" \
    | _ks_keep KS-1.2 bootstrap-grant none - KS-1.2-bootstrap-grant-v1.txt
}

step KS-1.3 HUMAN "Run FM-AGENT for canary-r" --irreversible --gate "NAMES" \
  --needs "PLATFORM_REPO_DIR FLD_AGENTS_R_NONPROD ENT_BOOTSTRAP_MODULE_R_NONPROD ENT_PLATFORM_POLICY" \
  --sets "ENT_PROJECT_REPAIR_CANARY_R ENT_DEPLOY_CREDENTIAL_HOLDER_CANARY_R"
s_KS_1_3_check() { ckpt_done KS-1.3; }   # its --sets come from 17 FM-2.17; KS-1.4 stops on either one missing
s_KS_1_3_manual() {
  echo "IRREVERSIBLE: the canary-r project id is permanent. WHO: the platform owner, inside both KS-1.2 grants. WHERE: shell; setup/17 FM-AGENT."
  printf '$ CANARY_ID="$(%s/tools/decision-value.sh NAMES CANARY_R_PROJECT)"; echo "$CANARY_ID"   (empty: STOP, not in the signed NAMES record)\n' "$(v PLATFORM_REPO_DIR)"
  echo "Confirm: the id equals the NAMES record; gcloud projects describe \"\$CANARY_ID\" returns NOT_FOUND or permission denied; both grants ACTIVE."
  printf 'Then 17'"'"'s FM-AGENT steps in order: row canary-r, parent %s, tier R, env nonprod, checkpoint prefix KS-1.3/;\n' "$(v FLD_AGENTS_R_NONPROD)"
  echo "  ENT_BOOTSTRAP_MODULE_R_NONPROD for FM-2.1 to FM-2.14 and FM-2.17 onwards, ENT_PLATFORM_POLICY for FM-2.15 and FM-2.16."
  echo "VERIFY: FM-AGENT's own VERIFY lines; gcloud projects describe \"\$CANARY_ID\" --format=\"value(parent.id,lifecycleState,labels.tier,labels.env)\""
  echo "  prints the fld-agents-r-nonprod id, ACTIVE, r, nonprod. 17 FM-2.17 sets ENT_PROJECT_REPAIR_CANARY_R and ENT_DEPLOY_CREDENTIAL_HOLDER_CANARY_R."
  _ks_say_done KS-1.3
}

step KS-1.4 AUTO-READ "Record canary-r and run the zero-diff checker" \
  --needs "PLATFORM_REPO_DIR CICD_PROJECT ENT_PROJECT_REPAIR_CANARY_R ENT_DEPLOY_CREDENTIAL_HOLDER_CANARY_R BUILD_LOG_DIR EVIDENCE_REGISTER" \
  --sets "CANARY_R_PROJECT CANARY_R_PROJECT_NUMBER"
s_KS_1_4_check() { ckpt_done KS-1.4 && has_value CANARY_R_PROJECT && has_value CANARY_R_PROJECT_NUMBER; }
s_KS_1_4_apply() {
  local id num ents out rc o rg spec zrc
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: CANARY_ID=\"\$($(v PLATFORM_REPO_DIR)/tools/decision-value.sh NAMES CANARY_R_PROJECT)\"   (re-derived, so a resumed shell works)"
    pset CANARY_R_PROJECT "<CANARY_ID>"
    agp_say "      read: gcloud projects describe <CANARY_R_PROJECT> --format='value(projectNumber)'"
    pset CANARY_R_PROJECT_NUMBER "<number>"
    agp_say "      read: gcloud pam entitlements list --project=<CANARY_R_PROJECT> --location=global --format='value(name)' --billing-project=$(v CICD_PROJECT)"
    agp_say "      read: python3.12 tools/fm-zero-diff.py live factory/runs/canary-r-nonprod.json   (17's checker; ZERO-DIFF required)"
    agp_say "      read: owner bindings on canary-r (none); agentregistry.googleapis.com enabled on canary-r (no)"
    xw "$(_ks_rec KS-1.4-canary-r-zero-diff-v1.txt)" < /dev/null
    return 0
  fi
  id="$(r "$(agp_tool decision-value.sh)" NAMES CANARY_R_PROJECT)"
  [ -n "$id" ] || { _ks_stop "CANARY_R_PROJECT is not in the signed NAMES record"; return 1; }
  if has_value CANARY_R_PROJECT && [ "$(v CANARY_R_PROJECT)" != "$id" ]; then
    _ks_stop "CANARY_R_PROJECT is already '$(v CANARY_R_PROJECT)', not '$id' from NAMES; a change needs penv_set --force and a build-log line"; return 1
  fi
  pset CANARY_R_PROJECT "$id" || return 1
  num="$(_ks_get gcloud projects describe "$id" --format='value(projectNumber)')" || { _ks_stop "gcloud projects describe $id failed"; return 1; }
  pset CANARY_R_PROJECT_NUMBER "$num" || return 1
  ents="$(_ks_get gcloud pam entitlements list --project="$id" --location=global --format='value(name)' --billing-project="$(v CICD_PROJECT)")" \
    || { _ks_stop "the entitlement list of canary-r failed"; return 1; }
  rc=0
  for o in ENT_PROJECT_REPAIR_CANARY_R ENT_DEPLOY_CREDENTIAL_HOLDER_CANARY_R; do
    case "$(v "$o")" in *[[:space:]]*) agp_say "      $o holds more than one name"; rc=1; continue;; esac
    # each name is among the canary-r entitlements: a list filtered on that name prints it
    nonempty r gcloud pam entitlements list --project="$id" --location=global --filter="name=$(v "$o")" --format='value(name)' \
      --billing-project="$(v CICD_PROJECT)" || { agp_say "      $o ($(v "$o")) is not among the canary-r entitlements"; rc=1; }
  done
  [ "$(printf '%s\n' "$ents" | sed '/^$/d' | wc -l | tr -d ' ')" = 2 ] || { agp_say "      canary-r lists $(printf '%s\n' "$ents" | sed '/^$/d' | wc -l | tr -d ' ') entitlements, not exactly two"; rc=1; }
  spec="$(v PLATFORM_REPO_DIR)/factory/runs/canary-r-nonprod.json"
  out="$(cd "$(v PLATFORM_REPO_DIR)" && r python3.12 tools/fm-zero-diff.py live "$spec" 2>&1)"; zrc=$?
  printf '%s\nexit=%s\n' "$out" "$zrc" | _ks_keep KS-1.4 canary-r-zero-diff E-05 1.3.1 KS-1.4-canary-r-zero-diff-v1.txt || return 1
  printf '%s\n' "$out" | tail -n 3 >&3
  { [ "$zrc" = 0 ] && grep -q 'ZERO-DIFF' <<< "$out"; } || { agp_say "      the checker reports differences: a difference on FM-2.15 or FM-2.16 means ENT_PLATFORM_POLICY was missing or expired; re-request it and re-run those FM steps, never accept them as pending here"; rc=1; }
  # the page's --flatten/--filter read, done on the policy JSON (the members of roles/owner), as KS-2.9's PF read
  o="$(_ks_get gcloud projects get-iam-policy "$id" --format=json)" || { _ks_stop "the IAM policy of canary-r does not read"; return 1; }
  o="$(printf '%s' "$o" | _ks_json members-of roles/owner)"
  [ -z "$o" ] || { agp_say "      canary-r still has an Owner: $(printf '%s' "$o" | tr '\n' ' ')"; rc=1; }
  rg="$(_ks_get gcloud services list --enabled --project="$id" --filter="config.name=agentregistry.googleapis.com" --format="value(config.name)")"
  [ -z "$rg" ] || { agp_say "      agentregistry.googleapis.com is enabled on canary-r"; rc=1; }
  return $rc
}

step KS-1.5 BLOCKED "The canary engine" --note "B-04 (canary engine source, k7/canary/); gateway project held until P206 is signed"
s_KS_1_5_check() { ckpt_done KS-1.5; }
s_KS_1_5_manual() {
  echo "BLOCKED on README B-04, extended: the canary engine source, its gateway file and deploy configuration in k7/canary/, green CI;"
  echo "and on P206 (the gateway's project and registries line). Gate waiting: KS-3.5, KS-6.6. The run records BLOCKED and continues."
  echo "When unblocked: setup/18 KS-1.5's sequence (gateway import as P206 places it, CC-1 allowed list by pull request, engine deploy)."
}

# ---------------------------------------------------------------- 2. Model Armor floors
step KS-2.1 AUTO-READ "Read every floor before writing any" \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_P_SA FLD_CONTROLLERS FLD_AGENTS_R CANARY_R_PROJECT BUILD_LOG_DIR ENT_PROJECT_REPAIR_CANARY_R CICD_PROJECT EVIDENCE_REGISTER"
s_KS_2_1_check() { ckpt_done KS-2.1; }
s_KS_2_1_apply() {
  local res out rep=""
  if [ "$AGP_MODE" = apply ] && ! _ks_active ENT_PROJECT_REPAIR_CANARY_R; then
    _ks_person "KS-2.1 runs after KS-2.4 (the page's run order): no ACTIVE grant on ENT_PROJECT_REPAIR_CANARY_R, so the reads would fail on the quota project and KS-2.5 to KS-2.9 would have no rollback source. Run agp-platform apply --phase 18 --from KS-2.2 --to KS-2.4, then --from KS-2.1"; return $?
  fi
  for res in "organizations/$(v ORG_ID)" "folders/$(v FLD_AGENTIC_PLATFORM)" "folders/$(v FLD_AGENTS_R)" "folders/$(v FLD_AGENTS_W)" \
             "folders/$(v FLD_AGENTS_P)" "folders/$(v FLD_AGENTS_P_SA)" "folders/$(v FLD_CONTROLLERS)" "projects/$(v CANARY_R_PROJECT)"; do
    if [ "$AGP_MODE" != apply ]; then
      agp_say "      read: $(agp_quote env "$(_ks_ep)" gcloud model-armor floorsettings describe --full-uri="$(_ks_floor_uri "$res")" --billing-project="$(v CANARY_R_PROJECT)" --format=json)"
      continue
    fi
    out="$(r env "$(_ks_ep)" gcloud model-armor floorsettings describe --full-uri="$(_ks_floor_uri "$res")" --billing-project="$(v CANARY_R_PROJECT)" --format=json 2>&1)"
    rep="$rep== $res
$out
"
  done
  printf '%s' "$rep" | _ks_keep KS-2.1 floors-before E-05 5.2.1 KS-2.1-floors-before-v1.txt || return 1
  [ "$AGP_MODE" = apply ] || return 0
  if grep -qi 'PERMISSION_DENIED\|does not have permission\|serviceusage.services.use' <<< "$rep"; then
    _ks_stop "a permission error in a block: re-request the KS-2.4 grants and re-run; a floor write with no saved predecessor has no rollback"; return 1
  fi
  agp_say "      eight blocks saved; the canary-r block shows FM-AGENT's project floor, or nothing (KS-2.9 writes it)"
}

step KS-2.2 HUMAN "The organisation floor: IT security confirms or sets it" --on-unmet skip --needs "ORG_ID BUILD_LOG_DIR"
s_KS_2_2_check() { ckpt_done KS-2.2; }
s_KS_2_2_manual() {
  echo "WHO: IT security, the organisation floor's owner (06 section 3.2); the platform owner records. WHERE: IT security's own sitting and entitlement."
  printf 'DO: send IT security the organisation row of setup/18 section 2 (organizations/%s: PI and jailbreak enabled at HIGH, malicious URI\n' "$(v ORG_ID)"
  echo "  enabled, no RAI, multi-language on, enforcement TRUE) and KS-2.1's record. IT security confirms it, sets it, or names a date."
  echo "RECORD: their signed note as <date>-KS-2.2-org-floor-note-v1 in EVIDENCE_INTERIM_LOCATION (with the describe output if set)."
  echo "The floor writes do not wait for this answer: KS-2.5's platform floor carries the organisation content under fld-agentic-platform."
  echo 'Then: agp-platform done KS-2.2 --note "<confirmed | set | not before YYYY-MM-DD>"   (KS-2.10 copies the note into FLOOR_RECORD)'
}

# KS-2.3, KS-2.10 and KS-4.1 end in a pull request the second human and another reviewer approve, and their
# blocks push to the git host and run gh: HUMAN, as phases 03, 16 and 21 treat git-host steps. The reason is the
# work only people can do (two approvals, the security reviewer's signature, the KF-2 permissions checked by hand
# against Google's list), not testability. The person runs the page's block; the AUTO steps after them read the
# merged files on origin/main and stop (98, a person must act first) until they are there.
step KS-2.3 HUMAN "Commit the floor file" \
  --needs "PLATFORM_REPO_DIR FLD_AGENTIC_PLATFORM FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_P_SA FLD_CONTROLLERS"
_ks_floors_consistent() {   # the page's jq -e on both blocks, over standard input
  jq -e '(.floors | length) == 5 and (.floors | all((.rest.rai | length) == 4 and (.gcloud.rai | length) == 4 and (.gcloud.pi == (.rest.pi | ascii_downcase)) and (.gcloud.rai == .rest.rai)))' >/dev/null 2>&1
}
_ks_floors_ready() {        # floors.json is merged, passes the page's check, and the checkout holds the merged file
  _ks_on_main model-armor/floors.json || { agp_say "      model-armor/floors.json is not on origin/main (KS-2.3: merge its pull request, then git pull)"; return 1; }
  _ks_main_file model-armor/floors.json | _ks_floors_consistent || { agp_say "      floors.json on origin/main fails KS-2.3's check (5 floors, both blocks, RAI in REST spelling)"; return 1; }
  git -C "$(_ks_repo)" diff --quiet origin/main -- model-armor/floors.json 2>/dev/null \
    || { agp_say "      the checkout's model-armor/floors.json differs from origin/main: git -C $(_ks_repo) switch main && git pull --ff-only"; return 1; }
}
s_KS_2_3_check() {
  ckpt_done KS-2.3 || return 1
  _ks_main_file model-armor/floors.json | _ks_floors_consistent \
    || agp_warn "KS-2.3 is done but model-armor/floors.json is not on origin/main or fails the page's check; KS-2.5 stops on it"
  return 0
}
s_KS_2_3_manual() {
  echo "WHO: the platform owner writes; the second human and one other reviewer approve; the security reviewer signs the P-SA row when named."
  printf 'WHERE: %s, branch ks-2-3-floors, then a pull request.\n' "$(v PLATFORM_REPO_DIR)"
  echo "DO: paste setup/18 KS-2.3's block as it stands: it switches to an up-to-date main, writes model-armor/floors.json with jq"
  echo "  (five floor(level; uri) calls, ';' between the arguments), then branches, commits and pushes."
  echo "VERIFY: jq '.floors | length' prints 5; the page's jq -e consistency line exits 0; two human approvals, the second human's among them."
  has_value SECURITY_REVIEWER_EMAIL || echo "SECURITY_REVIEWER_EMAIL is *tbd*: the pull request carries the page's sentence 'P-SA floor content unsigned ...' (KS-7.2 opens BD-18-4)."
  echo "Then: git -C <repo> switch main && git -C <repo> pull --ff-only; EVIDENCE: the merge commit as <date>-KS-2.3-floors-file-v1 (E-05)."
  _ks_say_done KS-2.3
}

step KS-2.4 AUTO "Obtain the ent-folder-admin and canary-r repair grants" \
  --needs "ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CANARY_R FLD_AGENTIC_PLATFORM CANARY_R_PROJECT CICD_PROJECT SECOND_HUMAN_EMAIL PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_KS_2_4_check() {
  ckpt_done KS-2.10 && return 0         # section 2 is complete; later steps re-request as they need
  _ks_off && return 3
  _ks_both_active ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CANARY_R
}
s_KS_2_4_apply() {
  local c
  c="$(git -C "$(_ks_repo)" log -1 --format=%h origin/main -- model-armor/floors.json 2>/dev/null)"; [ -n "$c" ] || c="see KS-2.3"
  _ks_grant ENT_FOLDER_ADMIN 3600s "setup 18 KS-2.5/KS-2.6: floors per model-armor/floors.json merge $c" \
    --additional-email-recipients="$(v SECOND_HUMAN_EMAIL)" || return $?
  _ks_grant ENT_PROJECT_REPAIR_CANARY_R 3600s "setup 18 KS-2.1 to KS-2.9: quota project for Model Armor calls; roles/modelarmor.user and the service identity on canary-r" \
    --additional-email-recipients="$(v SECOND_HUMAN_EMAIL)" || return $?
  agp_say "      the second human confirms platform-security@ received the activation mail"
  printf 'KS-2.4: ENT_FOLDER_ADMIN and ENT_PROJECT_REPAIR_CANARY_R granted, approved by the second human\n' \
    | _ks_keep KS-2.4 floor-grants none - KS-2.4-floor-grants-v1.txt
}

step KS-2.5 AUTO "Write the platform floor on fld-agentic-platform" \
  --needs "FLD_AGENTIC_PLATFORM CANARY_R_PROJECT PLATFORM_REPO_DIR ENT_FOLDER_ADMIN CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
# The read-back of a floor write (KS-2.5, KS-2.6, KS-2.9) compares every field with floors.json's rest block, in
# _apply, and a difference is the page's "run the ROLLBACK and stop" (98: a person rolls back or corrects the file).
# The check then reads: a DONE line (the runner wrote it after a matching read-back; drift is 16's job), or the
# step's record saying the read-back matched and a fresh read-back matching too.
s_KS_2_5_check() {
  ckpt_done KS-2.5 && return 0
  _ks_says KS-2.5-platform-floor-v1.txt '^read-back: matches' || return 1
  _ks_floor_ok platform "$(_ks_tier_uri platform)"
}
s_KS_2_5_apply() {
  local f uri rg rl sp="" j rb
  f="$(_ks_floors)"; uri="$(_ks_tier_uri platform)"
  if [ "$AGP_MODE" != apply ]; then
    _ks_ma_write "$uri" "<platform .gcloud.rai of floors.json>" high enable enabled
    agp_say "      if refused: the same command with the RAI confidence lower-cased (medium-and-above), the all-gcloud form; neither: stop"
    agp_say "      read: the describe of $uri, compared with the platform floor's rest block"
    xw "$(_ks_rec KS-2.5-platform-floor-v1.txt)" < /dev/null
    return 0
  fi
  [ -n "$(_ks_latest KS-2.1-floors-before-v1.txt)" ] || { _ks_stop "no KS-2.1 record: the floor write would have no rollback source"; return 1; }
  _ks_floors_ready || { _ks_person "the merged floor file is the one source of the writes: KS-2.3's pull request is merged and pulled first"; return $?; }
  _ks_need_active ENT_FOLDER_ADMIN "roles/modelarmor.floorSettingsAdmin" || return $?
  _ks_need_active ENT_PROJECT_REPAIR_CANARY_R "canary-r is the quota project" || return $?
  [ "$(_ks_json floor-field "$f" platform full-uri)" = "$uri" ] || { _ks_person "floors.json's platform full_uri is not $uri"; return $?; }
  rg="$(_ks_json floor-field "$f" platform rai-gcloud)" || return 1
  rl="$(_ks_json floor-field "$f" platform rai-lower)" || return 1
  if _ks_ma_write "$uri" "$rg" high enable enabled; then sp=gcloud
  elif _ks_ma_write "$uri" "$rl" high enable enabled; then sp=gcloud-lower; fi
  agp_say "      accepted spelling: ${sp:-NONE}"
  [ -n "$sp" ] || { _ks_person "neither form accepted; read the error, do not guess a third"; return $?; }
  j="$(_ks_get env "$(_ks_ep)" gcloud model-armor floorsettings describe --full-uri="$uri" --billing-project="$(v CANARY_R_PROJECT)" --format=json)"
  if _ks_floor_ok platform "$uri"; then rb="matches floors.json's platform rest block"; else rb="DIFFERS from floors.json's platform rest block"; fi
  printf 'accepted spelling: %s\nread-back: %s\nexpected: %s\nread:     %s\n%s\n' "$sp" "$rb" "$(_ks_json floor-expect "$f" platform)" \
    "$(printf '%s' "$j" | _ks_json floor-live)" "$j" | _ks_keep KS-2.5 platform-floor E-05 5.2.1 KS-2.5-platform-floor-v1.txt || return 1
  case "$rb" in matches*) return 0;; esac
  _ks_person "the platform floor does not read back as floors.json's rest block (the record holds both): run the ROLLBACK (re-apply KS-2.1's values; a new floor goes to --enable-floor-setting-enforcement=FALSE). If describe prints another spelling, record it in FLOOR_RECORD and correct the rest block by pull request before KS-2.6"
}

step KS-2.6 AUTO "Write the four tier floors" \
  --needs "CANARY_R_PROJECT FLD_AGENTIC_PLATFORM PLATFORM_REPO_DIR FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_P_SA FLD_CONTROLLERS ENT_FOLDER_ADMIN CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KS_2_6_check() {   # as KS-2.5's check
  local l rc
  ckpt_done KS-2.6 && return 0
  _ks_says KS-2.6-tier-floors-v1.txt '^read-back: all four match' || return 1
  for l in tier-w tier-p tier-p-sa controllers; do _ks_floor_ok "$l" "$(_ks_tier_uri "$l")"; rc=$?; [ $rc = 0 ] || return $rc; done
}
s_KS_2_6_apply() {
  local f sp l uri pi ra rep="" bad=0 j
  f="$(_ks_floors)"
  if [ "$AGP_MODE" != apply ]; then
    for l in tier-w tier-p tier-p-sa controllers; do _ks_ma_write "$(_ks_tier_uri "$l")" "<$l .gcloud.rai, in the spelling KS-2.5 accepted>" high enable enabled; done
    agp_say "      read: each describe, compared field by field with the level's rest block"
    xw "$(_ks_rec KS-2.6-tier-floors-v1.txt)" < /dev/null
    return 0
  fi
  sp="$(_ks_spelling)" || { _ks_stop "KS-2.5 has not recorded the accepted spelling"; return 1; }
  _ks_floors_ready || { _ks_person "the merged floor file is the one source of the writes: KS-2.3's pull request is merged and pulled first"; return $?; }
  _ks_need_active ENT_FOLDER_ADMIN "roles/modelarmor.floorSettingsAdmin" || return $?
  _ks_need_active ENT_PROJECT_REPAIR_CANARY_R "canary-r is the quota project" || return $?
  for l in tier-w tier-p tier-p-sa controllers; do
    uri="$(_ks_tier_uri "$l")"
    [ "$(_ks_json floor-field "$f" "$l" full-uri)" = "$uri" ] || { _ks_person "floors.json's $l full_uri is not $uri"; return $?; }
    agp_say "      == $l $uri"
    pi="$(_ks_json floor-field "$f" "$l" gcloud-pi)" || return 1
    case "$sp" in
      gcloud) ra="$(_ks_json floor-field "$f" "$l" rai-gcloud)" || return 1; _ks_ma_write "$uri" "$ra" "$pi" enable enabled || return 1;;
      gcloud-lower) ra="$(_ks_json floor-field "$f" "$l" rai-lower)" || return 1; _ks_ma_write "$uri" "$ra" "$pi" enable enabled || return 1;;
      *) ra="$(_ks_json floor-field "$f" "$l" rai-rest)" || return 1; _ks_ma_write "$uri" "$ra" "$(_ks_json floor-field "$f" "$l" rest-pi)" ENABLED ENABLED || return 1;;
    esac
  done
  for l in tier-w tier-p tier-p-sa controllers; do
    uri="$(_ks_tier_uri "$l")"
    j="$(_ks_get env "$(_ks_ep)" gcloud model-armor floorsettings describe --full-uri="$uri" --billing-project="$(v CANARY_R_PROJECT)" --format=json)"
    rep="$rep== $l $uri
expected: $(_ks_json floor-expect "$f" "$l")
read:     $(printf '%s' "$j" | _ks_json floor-live)
$j
"
    _ks_floor_ok "$l" "$uri" || bad=1
  done
  if [ $bad = 0 ]; then rep="read-back: all four match their rest blocks
$rep"; else rep="read-back: a tier floor DIFFERS from its rest block
$rep"; fi
  printf '%s' "$rep" | _ks_keep KS-2.6 tier-floors E-05 5.2.1 KS-2.6-tier-floors-v1.txt || return 1
  [ $bad = 0 ] || _ks_person "a tier floor differs from its rest block (the record holds each comparison): ROLLBACK as KS-2.5, per tier, from KS-2.1's saved JSON"
}

step KS-2.7 AUTO-READ "Read the audit entry of a floor write" \
  --needs "LOGGING_PROJECT FLD_AGENTIC_PLATFORM FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_P_SA FLD_CONTROLLERS BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KS_2_7_check() { ckpt_done KS-2.7; }
s_KS_2_7_apply() {
  local filter fmt fld out rep="" n folders=0 central methods
  filter='protoPayload.serviceName="modelarmor.googleapis.com" AND logName:"cloudaudit.googleapis.com%2Factivity"'
  fmt="table(timestamp,protoPayload.methodName,protoPayload.resourceName,protoPayload.authenticationInfo.principalEmail)"
  for fld in FLD_AGENTIC_PLATFORM FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_P_SA FLD_CONTROLLERS; do
    if [ "$AGP_MODE" != apply ]; then agp_say "      read: $(agp_quote gcloud logging read "$filter" --folder="$(v "$fld")" --freshness=2h --limit=10 --format="$fmt")"; continue; fi
    out="$(r gcloud logging read "$filter" --folder="$(v "$fld")" --freshness=2h --limit=10 --format="$fmt" 2>&1)"
    rep="$rep== folder $(v "$fld")
$out
"
    n="$(printf '%s\n' "$out" | awk '$1 ~ /^[0-9][0-9][0-9][0-9]-/' | wc -l | tr -d ' ')"
    [ "$n" -gt 0 ] && folders=$((folders + 1))
  done
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: $(agp_quote gcloud logging read "$filter" --project="$(v LOGGING_PROJECT)" --freshness=2h --limit=20 --format="$fmt")   (S-folder aggregate)"
    xw "$(_ks_rec KS-2.7-floor-write-audit-v1.txt)" < /dev/null
    return 0
  fi
  out="$(r gcloud logging read "$filter" --project="$(v LOGGING_PROJECT)" --freshness=2h --limit=20 --format="$fmt" 2>&1)"
  central="$(printf '%s\n' "$out" | awk '$1 ~ /^[0-9][0-9][0-9][0-9]-/' | wc -l | tr -d ' ')"
  methods="$(printf '%s%s\n' "$rep" "$out" | awk '$1 ~ /^[0-9][0-9][0-9][0-9]-/ {print $2}' | sort -u)"
  rep="$rep== central destination $(v LOGGING_PROJECT) (S-folder aggregate)
$out
folders with an entry: $folders of 5; central entries: $central
methodName: $(printf '%s' "$methods" | tr '\n' ' ')
"
  printf '%s' "$rep" | _ks_keep KS-2.7 floor-write-audit E-06 5.2.4 KS-2.7-floor-write-audit-v1.txt || return 1
  agp_say "      folders with an entry: $folders of 5; central entries: $central; methodName: $(printf '%s' "$methods" | tr '\n' ' ')"
  [ "$(printf '%s\n' "$methods" | sed '/^$/d' | wc -l | tr -d ' ')" = 1 ] || { _ks_stop "not exactly one methodName across the entries"; return 1; }
  if [ "$central" -lt 5 ]; then
    _ks_stop "fewer than five floor-write entries centrally: re-read after the Admin Activity delay; still missing is a logging finding for 14"; return 1
  fi
  [ "$folders" = 5 ] || agp_say "      a folder read is empty while the central read holds its entry: write in the record that it was found centrally (S-folder interception)"
  agp_say "      add the methodName to README's re-run index for 15 (SG-03) and 25 (a wiki edit, by hand)"
}

step KS-2.8 AUTO "Prove the conformance ordering in canary-r" --removes \
  --needs "CANARY_R_PROJECT REGION ENT_PROJECT_REPAIR_CANARY_R CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KS_2_8_check() {   # the expected result recorded, or a DONE line after a person handled the page's STOP
  ckpt_done KS-2.8 && return 0
  _ks_says KS-2.8-conformance-order-v1.txt '^RESULT: loose refused, conforming accepted'
}
s_KS_2_8_apply() {
  local ep loose ok o1 r1 o2 r2 b which res
  ep="https://modelarmor.$(v REGION).rep.googleapis.com/"
  loose='[{"filterType":"HATE_SPEECH","confidenceLevel":"HIGH"},{"filterType":"HARASSMENT","confidenceLevel":"HIGH"},{"filterType":"DANGEROUS","confidenceLevel":"HIGH"},{"filterType":"SEXUALLY_EXPLICIT","confidenceLevel":"HIGH"}]'
  ok='[{"filterType":"HATE_SPEECH","confidenceLevel":"MEDIUM_AND_ABOVE"},{"filterType":"HARASSMENT","confidenceLevel":"MEDIUM_AND_ABOVE"},{"filterType":"DANGEROUS","confidenceLevel":"MEDIUM_AND_ABOVE"},{"filterType":"SEXUALLY_EXPLICIT","confidenceLevel":"MEDIUM_AND_ABOVE"}]'
  _ks_need_active ENT_PROJECT_REPAIR_CANARY_R "the conformance test runs in canary-r" || return $?
  o1="$(x env "$(_ks_ep "$ep")" gcloud model-armor templates create ks-conformance-loose --project="$(v CANARY_R_PROJECT)" --location="$(v REGION)" \
        --rai-settings-filters="$loose" --pi-and-jailbreak-filter-settings-enforcement=enabled --pi-and-jailbreak-filter-settings-confidence-level=high \
        --malicious-uri-filter-settings-enforcement=enabled 2>&1)"; r1=$?
  o2="$(x env "$(_ks_ep "$ep")" gcloud model-armor templates create ks-conformance-ok --project="$(v CANARY_R_PROJECT)" --location="$(v REGION)" \
        --rai-settings-filters="$ok" --pi-and-jailbreak-filter-settings-enforcement=enabled --pi-and-jailbreak-filter-settings-confidence-level=high \
        --malicious-uri-filter-settings-enforcement=enabled 2>&1)"; r2=$?
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      expected: the first create refused naming the floor setting, the second accepted; then the clean-up:"
    x env "$(_ks_ep "$ep")" gcloud model-armor templates delete ks-conformance-ok --project="$(v CANARY_R_PROJECT)" --location="$(v REGION)"
    xw "$(_ks_rec KS-2.8-conformance-order-v1.txt)" < /dev/null
    return 0
  fi
  # the step's own clean-up, whatever happened
  [ $r2 = 0 ] && { x env "$(_ks_ep "$ep")" gcloud model-armor templates delete ks-conformance-ok --project="$(v CANARY_R_PROJECT)" --location="$(v REGION)" || return 1; }
  [ $r1 = 0 ] && { x env "$(_ks_ep "$ep")" gcloud model-armor templates delete ks-conformance-loose --project="$(v CANARY_R_PROJECT)" --location="$(v REGION)" || return 1; }
  b="$(_ks_latest KS-2.1-floors-before-v1.txt)"
  if [ -n "$b" ] && awk '/^== projects\//{f=1} f && /filterConfig|integratedServices/ {m=1} END {exit !m}' "$b"; then
    which="canary-r's own project floor (folder ordering: not proven; canary-r carries its own floor)"
  else which="the folder floors through Inherit"; fi
  if [ $r1 != 0 ] && [ $r2 = 0 ]; then res="RESULT: loose refused, conforming accepted"
  elif [ $r1 = 0 ]; then res="RESULT: loose ACCEPTED: the floor does not enforce conformance"
  else res="RESULT: conforming template refused"; fi
  printf '%s\nfloor in force: %s\n== ks-conformance-loose (exit %s)\n%s\n== ks-conformance-ok (exit %s)\n%s\n' "$res" "$which" "$r1" "$o1" "$r2" "$o2" \
    | _ks_keep KS-2.8 conformance-order E-05 5.2.6 KS-2.8-conformance-order-v1.txt || return 1
  agp_say "      $res; floor in force: $which"
  case "$res" in
    *"loose refused, conforming accepted") return 0;;
    *ACCEPTED*) _ks_person "the loose template was accepted (now deleted): stop section 2 until the cause is understood; 06 section 3.2's ordering claim is then wrong and 34 must not rely on it"; return $?;;
    *) _ks_person "the conforming template was refused: read its error in the record before section 2 goes on"; return $?;;
  esac
}

step KS-2.9 AUTO "The project-floor rule (PF), first applied to canary-r" \
  --needs "CANARY_R_PROJECT FLD_AGENTIC_PLATFORM CANARY_R_PROJECT_NUMBER PLATFORM_REPO_DIR ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CANARY_R CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KS_2_9_check() {   # as KS-2.5's check; the record is the evidence, also when 17 ran PF
  ckpt_done KS-2.9 && return 0
  _ks_says KS-2.9-pf-canary-r-v1.txt '^read-back: PF holds' || return 1
  _ks_pf_ok quiet
}
s_KS_2_9_apply() {
  local p n f sp pi pie mu ra j m rb by="this step (KS-2.9)"
  p="$(v CANARY_R_PROJECT)"; n="$(v CANARY_R_PROJECT_NUMBER)"; f="$(_ks_floors)"
  _ks_need_active ENT_FOLDER_ADMIN "the floor write needs roles/modelarmor.floorSettingsAdmin" || return $?
  _ks_need_active ENT_PROJECT_REPAIR_CANARY_R "roles/modelarmor.user and the service identity on canary-r" || return $?
  if [ "$AGP_MODE" = apply ] && _ks_pre _ks_pf_ok quiet; then   # the check repeated: did 17 run PF in KS-1.3?
    by="17 FM-AGENT in KS-1.3 (this step ran the VERIFY only)"
    agp_say "      PF already applied by 17 in KS-1.3: VERIFY only, recorded DONE with the read-back as its record"
  else
    if [ "$AGP_MODE" = apply ]; then
      # the page reads .spellings.accepted, which KS-2.10 commits after this step; until then KS-2.5's record holds it
      sp="$(_ks_spelling)" || { _ks_stop "no accepted spelling: KS-2.5 records it and KS-2.10 commits it"; return 1; }
      _ks_floors_ready || { _ks_person "the merged floor file is the one source of the writes: KS-2.3's pull request is merged and pulled first"; return $?; }
      case "$sp" in
        gcloud) pi=high; pie=enable; mu=enabled; ra="$(_ks_json floor-field "$f" platform rai-gcloud)" || return 1;;
        gcloud-lower) pi=high; pie=enable; mu=enabled; ra="$(_ks_json floor-field "$f" platform rai-lower)" || return 1;;
        rest) pi=HIGH; pie=ENABLED; mu=ENABLED; ra="$(_ks_json floor-field "$f" platform rai-rest)" || return 1;;
      esac
      r gcloud services list --enabled --project="$p" --filter="config.name=(aiplatform.googleapis.com OR modelarmor.googleapis.com)" --format="value(config.name)" >&3
    else
      pi=high; pie=enable; mu=enabled; ra="<platform .gcloud.rai, in the spelling KS-2.5 accepted>"
      agp_say "      read: gcloud services list --enabled --project=$p --filter=\"config.name=(aiplatform.googleapis.com OR modelarmor.googleapis.com)\""
    fi
    x gcloud beta services identity create --service=aiplatform.googleapis.com --project="$p" || return 1
    x gcloud projects add-iam-policy-binding "$p" --member="serviceAccount:service-${n}@gcp-sa-aiplatform.iam.gserviceaccount.com" --role=roles/modelarmor.user --condition=None || return 1
    x env "$(_ks_ep)" gcloud model-armor floorsettings update --full-uri="$(_ks_floor_uri "projects/$p")" --pi-and-jailbreak-filter-settings-enforcement="$pie" \
      --pi-and-jailbreak-filter-settings-confidence-level="$pi" --malicious-uri-filter-settings-enforcement="$mu" --rai-settings-filters="$ra" \
      --enable-multi-language-detection --enable-floor-setting-enforcement=TRUE --add-integrated-services=VERTEX_AI --vertex-ai-enforcement-type=INSPECT_ONLY \
      --enable-vertex-ai-cloud-logging --billing-project="$p" || return 1
  fi
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: the project floor describe and the modelarmor.user members (PF's VERIFY)"
    xw "$(_ks_rec KS-2.9-pf-canary-r-v1.txt)" < /dev/null
    return 0
  fi
  j="$(_ks_get env "$(_ks_ep)" gcloud model-armor floorsettings describe --full-uri="$(_ks_floor_uri "projects/$p")" --billing-project="$p" --format=json)"
  m="$(_ks_get gcloud projects get-iam-policy "$p" --format=json | _ks_json members-of roles/modelarmor.user)"
  if _ks_pf_ok; then rb="PF holds (floor, AI_PLATFORM integration, inspectOnly, logging, one modelarmor.user member)"
  else rb="PF DOES NOT HOLD (the lines above say which assertion failed)"; fi
  printf 'read-back: %s\nPF written by: %s\n== floor\n%s\n== roles/modelarmor.user\n%s\nlive proof: a re-run point in 35 and 40 (canary-r calls no model)\n' "$rb" "$by" "$j" "$m" \
    | _ks_keep KS-2.9 pf-canary-r E-05 5.2.6 KS-2.9-pf-canary-r-v1.txt || return 1
  case "$rb" in "PF holds"*) return 0;; esac
  _ks_person "PF does not read back as required: run the page's ROLLBACK (remove VERTEX_AI, re-apply KS-2.1's values, remove the binding) or correct the cause, then re-run"
}

step KS-2.10 HUMAN "Record the floor state and the PF re-run points" \
  --needs "BUILD_LOG_DIR PLATFORM_REPO_DIR EVIDENCE_REGISTER" --sets "FLOOR_RECORD"
_ks_spelling_on_main() { _ks_main_file model-armor/floors.json | python3 -c 'import json,sys; print((json.load(sys.stdin).get("spellings") or {}).get("accepted",""))' 2>/dev/null; }
s_KS_2_10_check() {
  ckpt_done KS-2.10 && has_value FLOOR_RECORD || return 1
  case "$(_ks_spelling_on_main)" in gcloud|gcloud-lower) ;; *) agp_warn "KS-2.10 is done but floors.json on origin/main has no accepted spelling (gcloud or gcloud-lower)";; esac
  return 0
}
s_KS_2_10_manual() {   # the values the page's placeholders take, read from this run's records
  local f
  echo "WHO: the platform owner; the second human reviews the floors.json pull request. WHERE: shell; README's re-run index."
  echo "DO: paste setup/18 KS-2.10's block with every placeholder replaced; these are this run's values:"
  f="$(_ks_latest KS-2.5-platform-floor-v1.txt)"; printf '  accepted spelling (KS-2.5): %s\n' "$( [ -n "$f" ] && sed -n '1s/^accepted spelling: //p' "$f" || echo '<KS-2.5 record missing>')"
  printf '  organisation floor (KS-2.2): %s\n' "$(_ks_ckpt_field KS-2.2 DONE 7 2>/dev/null || echo '<KS-2.2 not recorded: pending IT security>')"
  f="$(_ks_latest KS-2.8-conformance-order-v1.txt)"
  if [ -n "$f" ]; then printf '  conformance (KS-2.8): %s; %s\n' "$(sed -n 's/^RESULT: //p' "$f")" "$(sed -n 's/^floor in force: //p' "$f")"
  else echo "  conformance (KS-2.8): <KS-2.8 record missing>"; fi
  f="$(_ks_latest KS-2.7-floor-write-audit-v1.txt)"
  if [ -n "$f" ]; then printf '  floor-write methodName (KS-2.7): %s\n' "$(sed -n 's/^methodName: //p' "$f")"
  else echo "  floor-write methodName (KS-2.7): <KS-2.7 record missing>"; fi
  echo "  It writes the record, penv_set FLOOR_RECORD, switches to an up-to-date main, commits .spellings.accepted on branch"
  echo "  ks-2-10-floor-spelling (push, pull request)"
  echo "  and registers the evidence. By hand: README's six re-run lines (34, 35, 40, 17, 15 and 25, 16)."
  echo "VERIFY: FLOOR_RECORD set; no placeholder left; the pull request merged, then git pull: .spellings.accepted on main is gcloud or gcloud-lower."
  _ks_say_done KS-2.10
}

# ---------------------------------------------------------------- 3. Nonprod spikes
step KS-3.1 AUTO "P4 / CC-1: a throwaway engine is refused by the custom constraint" --removes \
  --needs "FLD_AGENTIC_PLATFORM CANARY_R_PROJECT REGION ORG_ID ENT_PLATFORM_POLICY ENT_PROJECT_REPAIR_CANARY_R CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KS_3_1_check() {
  ckpt_done KS-3.1 && return 0   # a DONE line after a person handled a "not tested" STOP
  local f; f="$(_ks_latest KS-3.1-p4-result-v1.txt)"
  [ -n "$f" ] && grep -q '^P4: \(passed\|failed\)' "$f"
}
s_KS_3_1_apply() {
  local c p reg url pol rc mode set_proj=0 bf yf resp arc res grade en lst cnt
  c=custom.allowlistedEgressAgentGatewaysForAgentEngine; p="$(v CANARY_R_PROJECT)"; reg="$(v REGION)"
  url="https://${reg}-aiplatform.googleapis.com/v1/projects/${p}/locations/${reg}/reasoningEngines"
  _ks_need_active ENT_PROJECT_REPAIR_CANARY_R "the probe runs in canary-r" || return $?
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud org-policies describe $c --folder=$(v FLD_AGENTIC_PLATFORM) --format=json   (kept as evidence)"
    agp_say "      only when the folder policy is dry-run only: an ent-platform-policy grant (the second human approves), then"
    _ks_grant ENT_PLATFORM_POLICY 1800s "setup 18 KS-3.1 P4 spike: enforce CC-1 on canary-r only"
    printf 'name: projects/%s/policies/%s\nspec:\n  rules:\n  - enforce: true\n' "$p" "$c" | xw "$(_ks_rec KS-3.1-cc1-project-policy-v1.yaml)"
    x gcloud org-policies set-policy "$(_ks_rec KS-3.1-cc1-project-policy-v1.yaml)" --update-mask=policy.spec
    agp_say "      wait 120 s for propagation, then the probe (a code-less engine, which must be refused):"
    printf '{"displayName":"ks-p4-cc1-probe"}' | xw "$(_ks_rec KS-3.1-p4-create-request-v1.json)"
    api POST "$url" "$(_ks_rec KS-3.1-p4-create-request-v1.json)"
    agp_say "      read: api GET $url (no engine named ks-p4-cc1-probe); clean-up of the project copy:"
    x gcloud org-policies delete "$c" --project="$p"
    xw "$(_ks_rec KS-3.1-p4-result-v1.txt)" < /dev/null
    return 0
  fi
  pol="$(_ks_get gcloud org-policies describe "$c" --folder="$(v FLD_AGENTIC_PLATFORM)" --format=json)"; rc=$?
  [ $rc = 0 ] || { _ks_stop "CC-1 is not set at fld-agentic-platform (13 creates it): nothing to test"; return 1; }
  printf '%s\n' "$pol" | _ks_keep KS-3.1 p4-cc1-folder-policy E-05 5.2.6 KS-3.1-p4-cc1-folder-policy-v1.json || return 1
  mode="$(printf '%s' "$pol" | _ks_json cc1-mode)"
  agp_say "      CC-1 at the folder: $mode"
  case "$mode" in
    enforced) ;;
    *)   # dry run only (13's 14 days), or a spec that is not enforced: an enforced copy on canary-r alone, then deleted
      [ "$mode" = dryrun ] || agp_say "      CC-1 at the folder has no enforced spec and no dryRunSpec: tested, as for the dry run, with an enforced copy on canary-r"
      _ks_grant ENT_PLATFORM_POLICY 1800s "setup 18 KS-3.1 P4 spike: enforce CC-1 on canary-r only" || return $?
      yf="$(_ks_rec KS-3.1-cc1-project-policy-v1.yaml)"
      printf 'name: projects/%s/policies/%s\nspec:\n  rules:\n  - enforce: true\n' "$p" "$c" | xw "$yf" || return 1
      x gcloud org-policies set-policy "$yf" --update-mask=policy.spec || return 1
      set_proj=1
      agp_say "      waiting 120 s for propagation"; _ks_sleep 120;;
  esac
  bf="$(_ks_rec KS-3.1-p4-create-request-v1.json)"
  printf '{"displayName":"ks-p4-cc1-probe"}' | xw "$bf" || return 1
  resp="$(api POST "$url" "$bf")"; arc=$?
  printf '%s\n' "$resp" | _ks_keep KS-3.1 p4-create-response E-05 5.2.6 KS-3.1-p4-create-response-v1.json || return 1
  if [ $arc = 0 ]; then
    res="failed"; grade="detection"
    en="$(printf '%s' "$resp" | _ks_json engine-name)"
    if [ -n "$en" ]; then api DELETE "https://${reg}-aiplatform.googleapis.com/v1/${en}" >/dev/null || agp_say "      the delete of $en failed: delete it by hand"
    else agp_say "      the created engine's name is not in the response: find and delete ks-p4-cc1-probe by hand"; fi
  elif grep -q "constraints/$c" <<< "$resp"; then res="passed"; grade="enforcement"
  else res="not tested"; grade="unknown"; fi
  lst="$(api GET "$url")"; cnt="$(printf '%s' "$lst" | _ks_json count-display ks-p4-cc1-probe 2>/dev/null)"
  if [ $set_proj = 1 ]; then
    x gcloud org-policies delete "$c" --project="$p" || return 1
    _ks_pre _ks_get gcloud org-policies describe "$c" --project="$p" --format=json >/dev/null; rc=$?   # the clean-up read back
    [ $rc = 1 ] || agp_say "      the project copy of CC-1 still describes: delete it by hand"
  fi
  printf 'P4: %s\nCC-1 grade: %s\ncreate: %s\nengines named ks-p4-cc1-probe after the probe: %s\nproject copy used: %s\n' \
    "$res" "$grade" "$( [ $arc = 0 ] && echo 'an operation (the engine was created)' || echo 'refused')" "${cnt:-unread}" "$( [ $set_proj = 1 ] && echo yes || echo no)" \
    | _ks_keep KS-3.1 p4-result E-05 5.2.6 KS-3.1-p4-result-v1.txt || return 1
  agp_say "      P4 $res; CC-1 $grade-grade"
  case "$res" in
    passed) [ "${cnt:-1}" = 0 ] || agp_say "      the list count is not 0: read the record";;
    failed) agp_say "      hand the result to 13 and 35: the gateway binding rests on CI and the drift job";;
    *) _ks_person "refused for another reason than CC-1 (not tested): read the saved response, re-read the REST ReasoningEngine reference, repeat with a minimal body; never deploy code"; return $?;;
  esac
}

step KS-3.2 AUTO "P8 part a: the deny entries for canary-r, and a denied call from a service account" --removes \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM DENY_AGENTS_PLATFORM CANARY_R_PROJECT CANARY_R_PROJECT_NUMBER SA_1_ADMIN ENT_PLATFORM_POLICY ENT_PROJECT_REPAIR_CANARY_R CICD_PROJECT SECOND_HUMAN_EMAIL BUILD_LOG_DIR EVIDENCE_REGISTER" \
  --sets "DENY_AGENT_FORM DENY_SA_FORM"
s_KS_3_2_check() {
  has_value DENY_AGENT_FORM && has_value DENY_SA_FORM || return 1
  ckpt_done KS-3.2 && return 0   # a DONE line after a person handled one of the page's STOPs
  local f; f="$(_ks_latest KS-3.2-p8-result-v1.txt)"
  [ -n "$f" ] && grep -q '^P8 part a: passed' "$f"
}
_ks_32_update() {   # BEFORE AGENT SA: the page's ks32_update; 0 when the update was accepted
  local after; after="$(_ks_rec "KS-3.2-p8-deny-after-v1.json")"
  _ks_json deny-add "$2" "$3" < "$1" | xw "$after" || return 1
  [ "$AGP_MODE" = apply ] && { diff <(python3 -m json.tool --sort-keys "$1") <(python3 -m json.tool --sort-keys "$after") >&3; }
  x gcloud iam policies update "$(basename "$(v DENY_AGENTS_PLATFORM)")" --attachment-point="cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)" \
    --kind=denypolicies --policy-file="$after"
}
s_KS_3_2_apply() {
  local org num p dp ap agent_p agent_alt sa_set probe sa_one before j forms af sf exp body out code ts rolerc rc=0 res
  org="$(v ORG_ID)"; num="$(v CANARY_R_PROJECT_NUMBER)"; p="$(v CANARY_R_PROJECT)"
  dp="$(basename "$(v DENY_AGENTS_PLATFORM)")"; ap="cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)"
  agent_p="principalSet://agents.global.org-${org}.system.id.goog/attribute.platformContainer/aiplatform/projects/${num}"
  agent_alt="principal://agents.global.org-${org}.system.id.goog/resources/aiplatform/projects/${num}"
  sa_set="principalSet://cloudresourcemanager.googleapis.com/projects/${num}/type/ServiceAccount"
  probe="canary-probe@${p}.iam.gserviceaccount.com"; sa_one="principal://iam.googleapis.com/projects/-/serviceAccounts/${probe}"
  before="$(_ks_rec KS-3.2-p8-deny-before-v1.json)"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud iam policies get $dp --attachment-point=$ap --kind=denypolicies --format=json   (saved as the before file)"
    agp_say "      if R1 to R5 do not all list one agent form and the service-account set: an ent-platform-policy grant, then"
    _ks_grant ENT_PLATFORM_POLICY 3600s "setup 18 KS-3.2 P8: canary-r forms in R1 to R5 of deny-agents-platform" --additional-email-recipients="$(v SECOND_HUMAN_EMAIL)"
    x gcloud iam policies update "$dp" --attachment-point="$ap" --kind=denypolicies --policy-file="$(_ks_rec KS-3.2-p8-deny-after-v1.json)"
    agp_say "      (the set form first; SD-22's principal form only if the set form is refused)"
    pset DENY_AGENT_FORM "<set|principal>"; pset DENY_SA_FORM "<set|single>"
  else
    j="$(_ks_get gcloud iam policies get "$dp" --attachment-point="$ap" --kind=denypolicies --format=json)" || { _ks_stop "deny-agents-platform does not read"; return 1; }
    printf '%s\n' "$j" | xw "$before" || return 1
    forms="$(_ks_json deny-forms "$agent_p" "$agent_alt" "$sa_set" "$sa_one" < "$before")"
    af="${forms% *}"; sf="${forms#* }"
    agp_say "      R1 to R5 today: agent form $af, service-account form $sf"
    [ "$af" = norules ] && { _ks_person "no rule description starts 'R1 ' to 'R5 ': read the before file and adjust to what 13 wrote, never to a guess"; return $?; }
    if [ "$af" = none ] || [ "$sf" = none ]; then
      _ks_grant ENT_PLATFORM_POLICY 3600s "setup 18 KS-3.2 P8: canary-r forms in R1 to R5 of deny-agents-platform" --additional-email-recipients="$(v SECOND_HUMAN_EMAIL)" || return $?
      if _ks_32_update "$before" "$agent_p" "$sa_set"; then af="set"; sf="set"
      elif _ks_32_update "$before" "$agent_alt" "$sa_set"; then af="principal"; sf="set"
      else _ks_person "both agent forms refused alongside the service-account set: record the error and apply the page's single-account fallback by hand"; return $?; fi
    fi
    pset DENY_AGENT_FORM "$af" || return 1
    pset DENY_SA_FORM "$sf" || return 1
  fi
  # the probe, code-free
  _ks_need_active ENT_PROJECT_REPAIR_CANARY_R "the probe bindings on canary-r" || return $?
  exp="$(_ks_exp 1)"
  x gcloud projects add-iam-policy-binding "$p" --member="serviceAccount:${probe}" --role=roles/iam.roleAdmin --condition="expression=request.time < timestamp('${exp}'),title=ks-3-2-p8-probe" || return 1
  x gcloud iam service-accounts add-iam-policy-binding "$probe" --project="$p" --member="user:$(v SA_1_ADMIN)" --role=roles/iam.serviceAccountTokenCreator --condition="expression=request.time < timestamp('${exp}'),title=ks-3-2-p8-probe" || return 1
  body="$(_ks_rec KS-3.2-p8-sa-probe-request-v1.json)"; out="$(_ks_rec KS-3.2-p8-sa-probe-v1.json)"
  printf '{"roleId":"ksP8Probe","role":{"title":"ks p8 probe","includedPermissions":["resourcemanager.projects.get"],"stage":"ALPHA"}}' | xw "$body" || return 1
  if [ "$AGP_MODE" = apply ]; then agp_say "      waiting 420 s: deny policies can take 7 minutes or more"; _ks_sleep 420; else agp_say "      wait 420 s (deny propagation)"; fi
  if [ "$AGP_MODE" = apply ]; then
    code="$(x _ks_sa_post "$probe" "https://iam.googleapis.com/v1/projects/${p}/roles" "$body" "$out")"
  else   # _ks_sa_post, shown as the page writes it; the token goes to curl on standard input
    agp_say "      \$ curl -sS -o $out -w '%{http_code}' -X POST -H @- <<< \"Authorization: Bearer <token of $probe, impersonated>\" -H 'Content-Type: application/json' --data-binary @$body https://iam.googleapis.com/v1/projects/${p}/roles   (expect 403 naming a deny policy)"
    code=""
  fi
  if [ "$AGP_MODE" = apply ]; then
    ts="$(r gcloud policy-intelligence troubleshoot-policy iam "//cloudresourcemanager.googleapis.com/projects/${p}" --principal-email="$probe" --permission=iam.roles.create 2>&1)"
    printf '%s\n' "$ts" | _ks_keep KS-3.2 p8-troubleshooter E-05 5.2.6 KS-3.2-p8-troubleshooter-v1.txt || rc=1
    _ks_get gcloud iam roles describe ksP8Probe --project="$p" --format='value(name)' >/dev/null; rolerc=$?
  else
    agp_say "      read: gcloud policy-intelligence troubleshoot-policy iam //cloudresourcemanager.googleapis.com/projects/$p --principal-email=$probe --permission=iam.roles.create"
    rolerc=1
  fi
  case "$code" in 2??) [ "$AGP_MODE" = apply ] && x gcloud iam roles delete ksP8Probe --project="$p";; esac
  # the step's own clean-up
  x gcloud projects remove-iam-policy-binding "$p" --member="serviceAccount:${probe}" --role=roles/iam.roleAdmin --condition="expression=request.time < timestamp('${exp}'),title=ks-3-2-p8-probe" || rc=1
  x gcloud iam service-accounts remove-iam-policy-binding "$probe" --project="$p" --member="user:$(v SA_1_ADMIN)" --role=roles/iam.serviceAccountTokenCreator --condition="expression=request.time < timestamp('${exp}'),title=ks-3-2-p8-probe" || rc=1
  if [ "$AGP_MODE" != apply ]; then xw "$(_ks_rec KS-3.2-p8-result-v1.txt)" < /dev/null; return 0; fi
  if [ "$code" = 403 ] && grep -qi 'deny' "$out" && grep -q "$dp" <<< "$ts" && [ "$rolerc" = 1 ]; then res="passed"
  elif [ "${code#2}" != "$code" ]; then res="FAILED: the service-account form denies nothing (the role was created and deleted)"
  else res="not conclusive: code $code; read the probe body and the Troubleshooter output"; fi
  printf 'P8 part a: %s\nDENY_AGENT_FORM: %s\nDENY_SA_FORM: %s\nprobe HTTP code: %s\nTroubleshooter names %s: %s\n' "$res" "$(v DENY_AGENT_FORM)" "$(v DENY_SA_FORM)" "$code" "$dp" \
    "$(grep -q "$dp" <<< "$ts" && echo yes || echo no)" | _ks_keep KS-3.2 p8-result E-05 5.2.6 KS-3.2-p8-result-v1.txt || return 1
  agp_say "      P8 part a: $res"
  case "$res" in
    passed) return $rc;;
    FAILED*) _ks_person "record P8 part a as failed; KF-2 of section 6 stops until 13 corrects the form"; return $?;;
    *) _ks_person "the denial is not proven: read the saved body and the Troubleshooter output"; return $?;;
  esac
}

step KS-3.3 BLOCKED "P8 part b: a denied call from the agent principal" --note "B-04 (spike engine source, k7/spike/)"
s_KS_3_3_check() { ckpt_done KS-3.3; }
s_KS_3_3_manual() {
  echo "BLOCKED on README B-04, extended: the spike engine source and its deploy configuration in k7/spike/, green CI."
  echo "Gate waiting: KF-2 counted as enforcement for agent principals (04 section 9.3); 35's deny verify on Wall-E's principal."
  echo "When unblocked: setup/18 KS-3.3's protocol (control call 200, roles.create 403 naming the deny policy, clean-up)."
}

step KS-3.4 AUTO-READ "P71 part a: no local registry can exist in canary-r" --needs "CANARY_R_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_KS_3_4_check() { ckpt_done KS-3.4; }
s_KS_3_4_apply() {
  local p j cnt has en at bad=0
  p="$(v CANARY_R_PROJECT)"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud org-policies describe gcp.restrictServiceUsage --project=$p --effective --format=json (agentregistry listed: must be false)"
    agp_say "      read: gcloud services list --enabled --project=$p --format=\"value(config.name)\" (no agentregistry)"
    agp_say "      read: gcloud asset search-all-resources --scope=projects/$p --format=\"value(assetType)\" (no agentregistry type)"
    xw "$(_ks_rec KS-3.4-p71-part-a-v1.txt)" < /dev/null
    return 0
  fi
  j="$(_ks_get gcloud org-policies describe gcp.restrictServiceUsage --project="$p" --effective --format=json)"
  cnt="$(printf '%s' "$j" | _ks_json allow-count)"; has="$(printf '%s' "$j" | _ks_json allow-has agentregistry.googleapis.com)"
  en="$(_ks_get gcloud services list --enabled --project="$p" --format="value(config.name)" | grep -c '^agentregistry')"
  at="$(_ks_get gcloud asset search-all-resources --scope="projects/${p}" --format="value(assetType)" | sort -u)"
  printf 'allow-list count: %s; agentregistry: %s\nenabled agentregistry services: %s\nasset types:\n%s\n' "$cnt" "$has" "$en" "$at" \
    | _ks_keep KS-3.4 p71-part-a E-05 1.3.1 KS-3.4-p71-part-a-v1.txt || return 1
  [ "$has" = false ] || { agp_say "      agentregistry is on canary-r's allow-list"; bad=1; }
  [ "$en" = 0 ] || { agp_say "      agentregistry is enabled on canary-r"; bad=1; }
  grep -q '^agentregistry\.googleapis\.com' <<< "$at" && { agp_say "      an agentregistry asset exists in canary-r"; bad=1; }
  [ $bad = 0 ] && agp_say "      P71 part a passed (it rests on the enabled-services and asset reads; the allow-list cannot govern agentregistry)"
  return $bad
}

step KS-3.5 BLOCKED "P71 part b: engine and gateway with the API disabled; the cross-project registry" --note "needs KS-1.5 (B-04)"
s_KS_3_5_check() { ckpt_done KS-3.5; }
s_KS_3_5_manual() {
  echo "BLOCKED: needs KS-1.5 (the canary engine and its gateway). P71 stays an open Tier R gate item in TIER_R_RECORD's annex."
  echo "When unblocked: setup/18 KS-3.5's three assertions with agentregistry disabled on canary-r, and the same-project registry rule."
}

step KS-3.6 BLOCKED "P3 spike 1: engine reach to an internal-ingress stand-in" --note "B-04 (stand-in and spike code, spikes/p3/); 12 PA-4.8 for fld-agents-w-nonprod"
s_KS_3_6_check() { ckpt_done KS-3.6; }
s_KS_3_6_manual() {
  echo "BLOCKED on (a) an ent-bootstrap-module entitlement for fld-agents-w-nonprod (12 re-runs PA-4.8), (b) the stand-in action-service"
  echo "image built and attested, (c) the spike engine source of KS-3.3, committed under spikes/p3/ with green CI (README B-04)."
  echo "Gate waiting: G9 (38) and B16 run.allowedIngress (13, P90). When unblocked: setup/18 KS-3.6's six-part protocol in ks-p3."
}

step KS-3.7 HUMAN "Write the four spike records" --witness \
  --needs "BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "SPIKE_P3_RECORD SPIKE_P4_RECORD SPIKE_P8_RECORD SPIKE_P71_RECORD"
s_KS_3_7_check() {
  ckpt_done KS-3.7 && has_value SPIKE_P3_RECORD && has_value SPIKE_P4_RECORD && has_value SPIKE_P8_RECORD && has_value SPIKE_P71_RECORD
}
s_KS_3_7_manual() {
  echo "WHO: the platform owner writes; the second human reads and initials each record. WHERE: shell; $(v BUILD_LOG_DIR)/records."
  echo "DO: setup/18 KS-3.7's first block (four skeletons, five headings each), then fill every <fill> from the records:"
  printf '  P4 from %s; P8 from %s\n' "$(_ks_latest KS-3.1-p4-result-v1.txt | sed 's#.*/##')" "$(_ks_latest KS-3.2-p8-result-v1.txt | sed 's#.*/##')"
  echo "  (DENY_SA_FORM, the 403, agent half BLOCKED, KF-2's grade); P71 part a passed, part b BLOCKED; P3 BLOCKED with both dependencies."
  echo "Then the page's second block: four penv_set SPIKE_*_RECORD lines and the evidence_add loop (no UNFILLED line may print)."
  echo "A pull request against 12-open-decisions rows P4, P8 and P71 cites the records (a wiki edit, reviewed)."
  _ks_say_done KS-3.7 "second human's email"
}

# ---------------------------------------------------------------- 4. K7: the lever files and the human entitlement
step KS-4.1 HUMAN "Generate and commit the k7/ files" \
  --needs "PLATFORM_REPO_DIR ORG_ID FLD_AGENTIC_PLATFORM FLD_AGENTS_R_PROD FLD_AGENTS_R_NONPROD FLD_AGENTS_W_PROD FLD_AGENTS_W_NONPROD FLD_AGENTS_P_PROD FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD PAB_AGENTS" \
  --sets "K7_POLICY_DIR"
s_KS_4_1_check() {
  ckpt_done KS-4.1 && has_value K7_POLICY_DIR || return 1
  _ks_on_main k7/deny-agents-halt.template.json && _ks_json k7-verify "$(_ks_repo)/k7" >/dev/null 2>&1 \
    || agp_warn "KS-4.1 is done but k7/ is not on origin/main or the checkout fails KS-4.1's VERIFY (8 KF-1 files, KF-2 list, the three other files)"
  return 0
}
s_KS_4_1_manual() {
  echo "WHO: the platform owner writes; the second human is a required reviewer (CODEOWNERS for /k7/) and approves; a second reviewer too."
  printf 'WHERE: %s, branch ks-4-1-k7-files, a pull request (gh pr create, as the block does).\n' "$(v PLATFORM_REPO_DIR)"
  echo "DO: paste setup/18 KS-4.1's block: the eight KF-1 files from each tier folder's live effective allow-list, scheduler-pause.txt,"
  echo "  pab-empty.json, the KF-2 template and permissions list, README.md, the CODEOWNERS line with the login read from identity/git-humans.yaml."
  echo "BEFORE the pull request: check the ten KF-2 permissions against https://docs.cloud.google.com/iam/docs/deny-permissions-support,"
  echo "  record which reasoningEngines.* are listed, delete any absent one from both files; reasoningEngines.query absent: re-grade KF-2."
  echo "VERIFY: the page's block: 8 files, each non-zero and 'false false'; jq -e on the KF-2 list exits 0; the diff is empty; the PAB binding"
  echo "  count (1 today); after the merge codeowners/errors prints 0 and the second human's login is among the approvals."
  echo "Then: git pull on main; penv_set K7_POLICY_DIR k7; EVIDENCE: merge commit and the VERIFY output as <date>-KS-4.1-k7-files-v1 (E-08)."
  _ks_say_done KS-4.1
}

step KS-4.2 HUMAN "Prove ent-k7-human: activate the pair, see the page, end it" --witness \
  --needs "ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER ORG_ID FLD_AGENTIC_PLATFORM CICD_PROJECT SECOND_HUMAN_EMAIL SA_1_ADMIN"
s_KS_4_2_check() { ckpt_done KS-4.2; }
s_KS_4_2_manual() {
  echo "WHO: the platform owner, as a member of platform-approvers@ (no approver exists); the second human confirms the page; the desk its copy."
  printf '$ gcloud pam grants create --entitlement=%s --location=%s %s --requested-duration=900s --justification="DRILL-KS-4.2 test grant, no lever pulled" --additional-email-recipients=%s --billing-project=%s\n' \
    "$(_ks_ent_id ENT_K7_HUMAN)" "$(_ks_ent_loc ENT_K7_HUMAN)" "$(_ks_ent_scope ENT_K7_HUMAN)" "$(v SECOND_HUMAN_EMAIL)" "$(v CICD_PROJECT)"
  echo "  and the same for ENT_K7_HUMAN_SCHEDULER; sleep 90; then the page's two get-iam-policy reads (organisation, fld-agentic-platform)."
  echo "VERIFY: both ACTIVE with no approval; orgpolicy.policyAdmin, iam.denyAdmin, iam.principalAccessBoundaryAdmin on the organisation and"
  echo "  cloudscheduler.admin on the folder, each with a PAM condition; the second human confirms IN WRITING the activation mail and the"
  echo "  page (15 part A) with its time; the desk confirms. No page: the step fails, 15 is re-run before section 6."
  echo "CLEAN-UP: gcloud pam grants revoke <grant> --reason=\"DRILL-KS-4.2 complete\" (same scope flags) for both; read that no binding remains."
  echo "EVIDENCE: grant names, both binding tables, the confirmation as <date>-KS-4.2-k7-human-test-v1 (E-08)."
  _ks_say_done KS-4.2 "second human's email"
}

# ---------------------------------------------------------------- 5. The k7-executor job (BLOCKED on code)
step KS-5.1 BLOCKED "Build and attest the k7-executor image" --note "B-04 (k7-executor source, k7/executor/)"
s_KS_5_1_check() { ckpt_done KS-5.1; }
s_KS_5_1_manual() {
  echo "BLOCKED on README B-04: the k7-executor source with a cloudbuild.yaml under ci/BUILD-CONTRACT.md ending in an attestation step."
  echo "Gate waiting: G20 (37), KS-5.2. When unblocked: setup/18 KS-5.1's gcloud builds submit in CICD_PROJECT, attested by vuln-gated."
}

step KS-5.2 BLOCKED "Deploy K7_JOB and bind its invokers" --note "needs KS-5.1 (B-04)"
s_KS_5_2_check() { ckpt_done KS-5.2; }
s_KS_5_2_manual() {
  echo "BLOCKED: needs KS-5.1's attested digest. Gate waiting: KS-5.3, KS-6.6, G20."
  echo "When unblocked: setup/18 KS-5.2 under ENT_DEPLOY_CREDENTIAL_HOLDER_CORE (deploy, invokers, penv_set K7_JOB)."
}

step KS-5.3 BLOCKED "First ent-k7-executor grant: a dry-run job execution, and the contingency decision" --note "needs KS-5.2 (B-04)"
s_KS_5_3_check() { ckpt_done KS-5.3; }
s_KS_5_3_manual() {
  echo "BLOCKED: needs KS-5.2. Gate waiting: 12 PA-3.5's executor test (handed here), KS-6.6."
  echo "When unblocked: setup/18 KS-5.3's dry-run execution and, if the job cannot activate its grant, 04 section 9.4's contingency decision."
}

# ---------------------------------------------------------------- 6. The first K7 drills (one /bin/bash shell, by hand)
step KS-6.1 HUMAN "Prepare the drill" \
  --needs "ORG_ID REGION CANARY_R_PROJECT FLD_AGENTIC_PLATFORM FLD_AGENTS_R_NONPROD FLD_AGENTS_W_NONPROD FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA_NONPROD FLD_PLATFORM_CORE FLD_CONTROLLERS FLD_GEMINI_ENTERPRISE PAB_AGENTS PLATFORM_REPO_DIR BUILD_LOG_DIR SA_1_ADMIN DENY_SA_FORM DENY_AGENT_FORM K7_POLICY_DIR"
s_KS_6_1_check() { ckpt_done KS-6.1; }
s_KS_6_1_manual() {
  echo "WHO: the platform owner; the IT security desk acknowledges. WHERE: /bin/bash (never zsh), ~/.platform-env sourced; keep this shell"
  echo "  for all of section 6: KS-6.2 to KS-6.5 use its SEL, DR, DRILL, stamp, probe_owner and probe_sa."
  echo "One business day ahead: announce the window (date, start, end, scope, 'drill, no incident') to the desk and the second human."
  echo "In the sitting, with the canary-r repair grant ACTIVE: paste setup/18 KS-6.1's block (saves every predecessor, adds the two"
  echo "  four-hour k7-drill-probe bindings, defines the probes and stamp, waits 120 s)."
  echo "VERIFY: four before-rsu-* files, before-pab-agents-rules.json a non-empty array, before-deny-list.txt without deny-agents-halt,"
  echo "  'owner 200 sa 200', both acknowledgements. EVIDENCE: <date>-KS-6.1-drill-prep-v1 (E-08)."
  _ks_say_done KS-6.1
}

step KS-6.2 HUMAN "Dry-run drill" --removes \
  --needs "ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER CICD_PROJECT SECOND_HUMAN_EMAIL K7_POLICY_DIR CANARY_R_PROJECT ORG_ID PAB_AGENTS"
s_KS_6_2_check() { ckpt_done KS-6.2; }
s_KS_6_2_manual() {
  echo "WHO: the platform owner as a platform-approvers@ member. WHERE: the section 6 /bin/bash shell of KS-6.1."
  echo "DO: setup/18 KS-6.2's block: the ent-k7-human pair, KF-1 as dryRunSpec (--update-mask=policy.dry_run_spec) on the four"
  echo "  nonprod folders, 24 probes, the dry-run log read, the KF-3 inventory and the KF-4 bound principal sets; render KF-2 to"
  echo "  \$DR/dry-kf2.json without attaching it."
  echo "VERIFY: four 'KF-1 dryRunSpec set' stamps; probe_owner still 200; a DENIED dry-run entry for aiplatform and its delay;"
  echo "  dry-kf4-bound.txt lists only canary-r (else KS-6.3 skips KF-4). Then KS-6.4's KF-1 restore loop, read back that"
  echo "  dryRunSpec is absent on each folder, and revoke both grants. EVIDENCE: <date>-KS-6.2-k7-dry-run-v1 (E-08)."
  _ks_say_done KS-6.2
}

step KS-6.3 HUMAN "Enforced drill" --witness --removes \
  --needs "ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER CICD_PROJECT SECOND_HUMAN_EMAIL K7_POLICY_DIR ORG_ID FLD_AGENTIC_PLATFORM FLD_AGENTS_R_NONPROD FLD_PLATFORM_CORE FLD_CONTROLLERS FLD_GEMINI_ENTERPRISE PAB_AGENTS CANARY_R_PROJECT_NUMBER DENY_AGENT_FORM DENY_SA_FORM SA_1_ADMIN"
s_KS_6_3_check() { ckpt_done KS-6.3; }
s_KS_6_3_manual() {
  echo "Stops every agent in four folders. WHO: the platform owner pulls; the second human is present for KS-6.3 and KS-6.4 and"
  echo "  watches the timeline; the desk is on the line. WHERE: the section 6 /bin/bash shell, shared screen."
  echo "Confirm first: the scope is exactly \$SEL, no production folder id in it, KS-6.2 passed, and the second human says 'go'."
  echo "DO: setup/18 KS-6.3's block in full: KF-1, KF-3, KF-4 (only within the union rule), then KF-2 after its scope check and"
  echo "  the second human's read-back of the attachment point and every principal before typing GO. Never skip the scope check."
  echo "VERIFY: KF-1 first refused call under 60 s; trigger to last lever under 300 s (human path under 900 s); every folder"
  echo "  policy equals its k7/ file; kf2-scope-check.txt all 'ok'; the read-back equals kf2-principals.txt. A miss is a finding"
  echo "  for KS-6.5, and the drill continues to the lift. EVIDENCE: <date>-KS-6.3-k7-enforced-v1 (E-08)."
  _ks_say_done KS-6.3 "second human's email"
}

step KS-6.4 HUMAN "The two-human lift, with the KF-2 hold probe" --witness --removes \
  --needs "ENT_PLATFORM_POLICY ENT_FOLDER_ADMIN CICD_PROJECT ORG_ID FLD_AGENTIC_PLATFORM PAB_AGENTS"
s_KS_6_4_check() { ckpt_done KS-6.4; }
s_KS_6_4_manual() {
  echo "WHO: the platform owner applies; the second human approves ent-platform-policy and ent-folder-admin and is the required"
  echo "  reviewer of the lift pull request (k7/lifts/<date>-drill.md). WHERE: the section 6 /bin/bash shell; the git host."
  echo "DO: open and merge the lift pull request first; then setup/18 KS-6.4's block: both grants, KF-1 restores (etags stripped),"
  echo "  KF-3 resume, KF-4 restore if cleared, the KF-2 hold probe, the KF-2 detach, the 420 s wait and the last probe."
  echo "VERIFY: no restore refused on concurrency; hold probe owner=200 sa=403 naming the deny policy; after the detach 200 200;"
  echo "  zero diff on every folder policy, the pab-agents rules and the deny list; no job left paused. Remove the two"
  echo "  k7-drill-probe bindings and revoke every grant. Never leave a folder on the KF-1 list at the end of the sitting."
  echo "EVIDENCE: the merged lift pull request, timeline lines, zero-diff outputs as <date>-KS-6.4-k7-lift-v1 (E-08)."
  _ks_say_done KS-6.4 "second human's email"
}

step KS-6.5 HUMAN "Write and sign the first drill record" --witness --needs "BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "K7_FIRST_DRILL_RECORD"
s_KS_6_5_check() { ckpt_done KS-6.5 && has_value K7_FIRST_DRILL_RECORD; }
s_KS_6_5_manual() {
  echo "WHO: the platform owner writes; the second human co-signs; the security reviewer witnesses and signs when named (else the"
  echo "  record states the gap). WHERE: the section 6 shell; EVIDENCE_INTERIM_LOCATION; the witness drills/ prefix through 08."
  echo "DO: setup/18 KS-6.5's block (it sets K7_FIRST_DRILL_RECORD and registers the evidence), replace every <...> before signing,"
  echo "  export to PDF, both humans sign, upload to the interim location, send the file name to the witness administrators."
  echo "VERIFY: grep -c '<' on the record prints 0; the signed PDF's SHA-256 registered; the witness administrators confirm."
  _ks_say_done KS-6.5 "second human's email"
}

step KS-6.6 BLOCKED "Job-path drill" --note "needs KS-5.3 and KS-1.5 (B-04)"
s_KS_6_6_check() { ckpt_done KS-6.6; }
s_KS_6_6_manual() {
  echo "BLOCKED: needs KS-5.3 and KS-1.5 (a live canary engine). Gate waiting: G20 (37 repeats it on fld-agents-p-sa-nonprod), DR-18-1."
  echo "When unblocked: setup/18 KS-6.6, the job path with KS-6.1's preparation, KS-6.4's lift and KS-6.5's record."
}

# ---------------------------------------------------------------- 7. Close the part
step KS-7.1 AUTO "Open the K7 rows of the drill calendar" --witness \
  --needs "DRILL_CALENDAR K7_FIRST_DRILL_RECORD BUILD_LOG_DIR"
s_KS_7_1_check() { [ -f "$(v DRILL_CALENDAR)" ] && [ "$(grep -c '^| DR-18-' "$(v DRILL_CALENDAR)")" = 5 ]; }
s_KS_7_1_apply() {
  local d0 nx
  if [ "$AGP_MODE" = apply ]; then
    d0="$(_ks_ckpt_field KS-6.3 START 1 || _ks_ckpt_field KS-6.3 DONE 1)" || { _ks_stop "no KS-6.3 checkpoint: the enforced drill's date is unknown"; return 1; }
    d0="$(printf '%s' "$d0" | cut -c1-10)"
  else d0="<date of KS-6.3, from checkpoints.tsv>"; fi
  nx="$(date -u -j -v+30d -f %Y-%m-%d "$d0" +%F 2>/dev/null || date -u -d "$d0 +30 days" +%F 2>/dev/null || echo "<KS-6.3 date + 30 days>")"
  x python3 - "$(v DRILL_CALENDAR)" "$d0" "$nx" "$(v K7_FIRST_DRILL_RECORD)" <<'PY' || return 1
import sys
path, d0, nxt, rec = sys.argv[1:5]
rows = {
 "DR-18-1": f"| DR-18-1 | K7 full drill, dry run then enforced, on every nonprod tier folder including fld-agents-p-sa-nonprod; job path once B-04 lands (human path until then, not counted for G20) | monthly | platform owner | second human for the enforced drill; security reviewer signs when named | 18 | {d0} | {rec} | {nxt} | G20; 04 section 9.6 (a drill older than 30 days freezes every raise) |",
}
extra = [
 "| DR-18-2 | K7 human path from a managed device (ent-k7-human pair, the k7/ files by hand) | quarterly | platform owner | second human | 18 | " + d0 + " | " + rec + " | *tbd* (quarter after first) | 04 section 9.6, under 15 min |",
 "| DR-18-3 | K7 SIEM path: synthetic severity-1 event to the job (BLOCKED on 15 part B and B-04) | quarterly, with the tabletop | IT security | platform owner | 18 | *tbd* | | | 07 section 6.5; under 10 min |",
 "| DR-18-4 | KF-3 alone in production on fld-agents-r-prod, in a change window | quarterly | platform owner | security reviewer | 18 | *tbd* (after the first production Tier R project) | | | 04 section 9.6, no run lost |",
 "| DR-18-5 | KF-1 in production on fld-agents-r-prod, dry run then five minutes enforced, announced to agent owners | semi-annually | platform owner | security reviewer | 18 | *tbd* (after the first production Tier R project) | | | 04 section 9.6; never on P-SA production |",
]
lines = open(path).read().split("\n")
out, done = [], False
for l in lines:
    if l.startswith("| DR-18-1 |"):
        out.append(rows["DR-18-1"]); out.extend(extra); done = True
    else:
        out.append(l)
if not done: sys.exit("DR-18-1 not found: stop")
open(path, "w").write("\n".join(out))
print("calendar updated")
PY
  x git -C "$(v BUILD_LOG_DIR)" add "$(v DRILL_CALENDAR)" || return 1
  x git -C "$(v BUILD_LOG_DIR)" commit -m "registers: K7 drill rows DR-18-1 to DR-18-5 (setup 18 KS-7.1)" || return 1
  agp_say "      the second human reviews the commit (the page's WHO; the commit is the record)"
}

step KS-7.2 AUTO "Deviation rows, re-run index and BLOCKED index" \
  --needs "DEVIATION_REGISTER BUILD_LOG_DIR PLATFORM_REPO_DIR"
s_KS_7_2_check() {
  local i; for i in 1 2 3 4 5 6 7; do _ks_bd_has "BD-18-$i" || return 1; done
}
s_KS_7_2_apply() {
  local d psa cc perms qd f
  d="$(_ks_today)"
  if has_value SECURITY_REVIEWER_EMAIL; then psa=signed; else psa=unsigned; fi
  if [ "$AGP_MODE" = apply ]; then
    f="$(_ks_latest KS-3.1-p4-result-v1.txt)"; cc="$(sed -n 's/^CC-1 grade: //p' "$f" 2>/dev/null)"
    case "$cc" in enforcement|detection) ;; *) _ks_stop "no CC-1 grade in KS-3.1's record"; return 1;; esac
    # KS-4.1 deletes from the merged list every permission Google's supported list lacks, so the merged file
    # is the list of deniable ones
    f="$(_ks_main_file k7/deny-agents-halt.permissions.txt)"
    [ -n "$f" ] || { _ks_person "k7/deny-agents-halt.permissions.txt is not on origin/main (KS-4.1)"; return $?; }
    perms="$(printf '%s\n' "$f" | grep '/reasoningEngines\.' | sed 's#.*/##' | tr '\n' ' ' | sed 's/ $//')"
    if printf '%s\n' "$f" | grep -qx 'aiplatform.googleapis.com/reasoningEngines.query'; then qd=yes; else qd=no; fi
    [ -n "$perms" ] || perms=none
  else cc="<KS-3.1 CC-1 grade>"; perms="<KS-4.1 list>"; qd="<yes|no>"; fi
  x bd_insert "$(printf '| BD-18-1 | %s | 18 KS-6.2 to KS-6.5 | DEV | first K7 drills on the human path; the job path is BLOCKED (B-04) | four nonprod tier folders | k7/ merge; K7_FIRST_DRILL_RECORD | levers applied and lifted by hand under ent-k7-human and ent-platform-policy | zero-diff outputs of KS-6.4 | n/a | second human co-signed the record | KS-6.6 job-path drill; G20 read in 37 | open |' "$d")" || return 1
  x bd_insert "$(printf '| BD-18-2 | %s | 18 KS-6.4 | DEV | K7 lift applied by hand from a merged pull request, not by CI (04 section 9.5 says CI applies) | organisation, fld-agentic-platform, four tier folders | lift pull request | restored predecessors | KS-6.4 zero diff | n/a | ent-platform-policy approved by the second human | the factory pipeline (B-01) | open |' "$d")" || return 1
  x bd_insert "$(printf '| BD-18-3 | %s | 18 KS-4, KS-6.3 | DEV | KF-4 cannot be folder-selective: PAB eligibility is a union (PAB concepts page 2026-09-14); KF-4 applied only when every project bound to pab-agents is in the selection | pab-agents | KS-6.2 dry-kf4-bound | none | n/a | n/a | none: design correction for 04 section 9.3 | 04 decision (per-tier PAB or fleet-only KF-4) | open |' "$d")" || return 1
  x bd_insert "$(printf '| BD-18-4 | %s | 18 KS-2.3, KS-2.6 | DEV | tier floors equal the platform floor until each tier benign corpus is measured; P-SA floor content %s by the security reviewer | tier folders | floors.json merge | five folder floors | KS-2.6 compare | n/a | second human review | measured flips per tier (06 section 3.3); PA-8.1 signature | open |' "$d" "$psa")" || return 1
  x bd_insert "$(printf '| BD-18-5 | %s | 18 KS-1.1, KS-2.1 | DEV | canary-r used as the quota project for Model Armor calls; canary-probe@ fixture account in an agent project with conditioned, expiring grants only | canary-r | register row | canary-probe@; expired conditioned bindings | KS-1.4 checker | n/a | second human merged the row | a platform quota project with modelarmor enabled, if 13 allow-lists one | open |' "$d")" || return 1
  x bd_insert "$(printf '| BD-18-6 | %s | 18 KS-3.1 to KS-3.7 | DEV | spikes partly BLOCKED: P8 agent half, P71 part b, P3 spike 1; CC-1 grade from P4 = %s | canary-r | spike records | none | n/a | n/a | second human initialled the records | KS-3.3, KS-3.5, KS-3.6 when unblocked | open |' "$d" "$cc")" || return 1
  x bd_insert "$(printf '| BD-18-7 | %s | 18 KS-4.1, KS-6.3 | DEV | KF-2 denies only permissions on Google IAM deny-support list, one service_fqdn/resource.action entry each: no wildcard form exists. Deniable reasoningEngines permissions found: %s (all ten KF-2 permissions listed on 2026-10-01). reasoningEngines.query deniable: %s; if no, KF-2 stops engine management, not engine traffic, and the hold probe is re-specified | deny-agents-halt | k7/deny-agents-halt.permissions.txt | KF-2 permission list | KS-4.1 VERIFY; KS-6.3 KF-2 read back | n/a | second human reviewed the k7/ pull request | 04 section 9.3 re-grade of KF-2 if query is not deniable | open |' "$d" "$perms" "$qd")" || return 1
  agp_say "      by hand (wiki edits): README's re-run index lines for 12, 13, 15 part A and 25, 15 part B, 16, 17, 34, 35, 37, 40, 04 and 06"
  agp_say "      as setup/18 KS-7.2 lists them, and README's BLOCKED index row B-04: \"18 KS-1.5, KS-3.3 and KS-3.6, KS-5.1 to KS-5.3, KS-6.6\","
  agp_say "      with a person/record line for KS-3.6's missing ent-bootstrap-module-w-nonprod. The second human reads the rows."
}

step KS-7.3 AUTO-READ "End the sitting" \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM CANARY_R_PROJECT ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER ENT_PLATFORM_POLICY ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CANARY_R CICD_PROJECT"
s_KS_7_3_check() { ckpt_done KS-7.3; }
s_KS_7_3_apply() {
  local e bad=0 rc miss
  for e in ENT_K7_HUMAN ENT_K7_HUMAN_SCHEDULER ENT_PLATFORM_POLICY ENT_FOLDER_ADMIN ENT_PROJECT_REPAIR_CANARY_R; do
    if [ "$AGP_MODE" != apply ]; then
      agp_say "      read: gcloud pam grants search --entitlement=$(_ks_ent_id "$e") --location=$(_ks_ent_loc "$e") $(_ks_ent_scope "$e") --caller-relationship=had-created --filter=state=ACTIVE (must print nothing)"
      continue
    fi
    _ks_active "$e"; rc=$?
    case $rc in 0) agp_say "      an ACTIVE grant remains on $e: revoke it, then re-run"; bad=1;; 1) ;; *) agp_say "      the grant search on $e failed"; bad=1;; esac
  done
  if [ "$AGP_MODE" = apply ]; then penv_guard >&3 2>&1 || { agp_say "      penv_guard failed"; bad=1; }; else agp_say "      read: penv_guard"; fi
  # the page's VERIFY: a DONE line for every other step that is not BLOCKED (KS-2.9 included when 17 ran PF)
  if [ "$AGP_MODE" = apply ]; then
    miss=""
    for e in KS-0.1 KS-1.1 KS-1.2 KS-1.3 KS-1.4 KS-2.1 KS-2.2 KS-2.3 KS-2.4 KS-2.5 KS-2.6 KS-2.7 KS-2.8 KS-2.9 KS-2.10 \
             KS-3.1 KS-3.2 KS-3.4 KS-3.7 KS-4.1 KS-4.2 KS-6.1 KS-6.2 KS-6.3 KS-6.4 KS-6.5 KS-7.1 KS-7.2; do
      ckpt_done "$e" || miss="$miss $e"
    done
    [ -z "$miss" ] || { agp_say "      no DONE line in checkpoints.tsv for:$miss (a person's step: agp-platform done ID; KS-2.2 records IT security's outcome)"; bad=1; }
  else agp_say "      read: checkpoints.tsv holds a DONE line for every step of this file that is not BLOCKED"; fi
  [ $bad = 0 ] || return 1
  agp_say "      file 18 complete except BLOCKED KS-1.5, KS-3.3, KS-3.5, KS-3.6, KS-5.1, KS-5.2, KS-5.3, KS-6.6"
  agp_say "      then end the sitting: agp-platform sitting end   (sitting_end must print SITTING-END OK)"
}
