# shellcheck shell=bash
# phases/05-gemini-enterprise-inventory.sh: setup/05, the read-only Gemini Enterprise inventory.
#
# Nothing here writes to the cloud or the tenant. Every AUTO-READ step reads Google and keeps what
# Google returned as a dated file under GE_INVENTORY_DIR (`<date>-<step>-<record>-v<n>.<ext>`, never
# overwritten), records it in the evidence register, and sets the page's variables. A stop rule of
# §4 does not end the sitting: the step records `STOP: ...` as a BLOCKED checkpoint line, exactly as
# the page's gi_done does, and the reads go on; GI-10.2 carries every stop into the fact sheet's gate.
# A read the page treats as tolerable (one location, one template) is kept with Google's error body;
# a read the page's VERIFY depends on fails the step.
#
# Paged lists (GI-7.1, GI-7.2, GI-8.2) follow the page's ge_list and GI-8.2 loop: every page is read; a
# failed first page of GI-7.1 or GI-7.2 is the page's tolerated "read failed" (Google's error kept in the
# file); a later page that fails, or a nextPageToken left over, is a truncated list: PENDING, never DONE.
# p05_pages is ge_list of GI-0.2, through `api` so that no token appears in a command line.
#
# Deliberate differences from the page's blocks, each one a correction:
#   GI-8.3 and GI-8.4 classify only the files written in this run, so a re-run after
#   `gcloud components update` is not stopped by an older file's `Invalid choice`.
#   GI-2.1 keeps one GET per location: engines.list documents pageSize and pageToken as "Not
#   supported" and returns every engine, so a nextPageToken there is treated as a truncated read.
#   GI-10.1 stops before the commit when a restricted file is staged.

phase 05 "Gemini Enterprise inventory, read-only" "05-gemini-enterprise-inventory.md" "GI-[0-9]+\.[0-9]+"
# No `requires`, on purpose. GI-1.5 searches the whole organisation (cloudasset.assets.searchAllResources
# on the organisation) and GI-5.3 reads the policies of the project's ancestors with their deny
# policies (resourcemanager.organizations.getIamPolicy, resourcemanager.folders.getIamPolicy,
# iam.denypolicies.get). The page records a refusal of either read as a PENDING re-run in file 19
# (GI-1.5's block, GI-5.3's VERIFY), and this phase runs before 06 grants any organisation role;
# preflight tests every declared permission first, so declaring them would refuse the whole phase
# instead of letting those two steps record PENDING.

# ---------------------------------------------------------------- helpers of this phase

p05_path() {    # p05_path DIR STEP RECORD EXT: the next free version of a dated record (gi_path of GI-0.2)
  local dir="$1" step="$2" rec="$3" ext="$4" n=1 d
  d="$(date -u +%F)"
  while [ -e "$dir/${d}-${step}-${rec}-v${n}.${ext}" ]; do n=$((n + 1)); done
  printf '%s\n' "$dir/${d}-${step}-${rec}-v${n}.${ext}"
}
p05_file() { p05_path "$(v GE_INVENTORY_DIR)" "$@"; }

p05_newest() {  # p05_newest STEP RECORD EXT: the newest file of a record, or nothing
  # shellcheck disable=SC2012
  ls -t "$(v GE_INVENTORY_DIR)"/*-"$1"-"$2"-v*."$3" 2>/dev/null | head -1
}

p05_host() {    # the endpoint Google's locations page names for each Gemini Enterprise location
  case "$1" in
    eu) echo https://eu-discoveryengine.googleapis.com;;
    us) echo https://us-discoveryengine.googleapis.com;;
    global) echo https://global-discoveryengine.googleapis.com;;
  esac
}

p05_show() {    # indent standard input onto the terminal and the run log
  local l
  while IFS= read -r l; do agp_say "      $l"; done
}

p05_save() {    # p05_save FILE CMD...: a read whose standard output is kept as FILE; shown in plan mode
  local f="$1" rc; shift
  if [ "$AGP_MODE" != apply ]; then printf '      $ %s > %s\n' "$(agp_quote "$@")" "$f" >&3; return 0; fi
  r "$@" | xw "$f"; rc=${PIPESTATUS[0]}
  return "$rc"
}

p05_save_all() {    # p05_save_all FILE CMD...: as p05_save, keeping Google's error text with the output
  local f="$1" rc; shift
  if [ "$AGP_MODE" != apply ]; then printf '      $ %s > %s 2>&1\n' "$(agp_quote "$@")" "$f" >&3; return 0; fi
  r "$@" 2>&1 | xw "$f"; rc=${PIPESTATUS[0]}
  return "$rc"
}

p05_get() {     # p05_get FILE URL [USER_PROJECT]: an HTTP GET (ge_get of GI-0.2); the body is kept whatever the status
  local f="$1" url="$2" up="${3:-}" rc
  [ -n "$up" ] || up="$(v GEMINI_PROJECT)"
  if [ "$AGP_MODE" != apply ]; then printf '      $ GET %s  (X-Goog-User-Project: %s) > %s\n' "$url" "$up" "$f" >&3; return 0; fi
  AGP_API_PROJECT="$up" api GET "$url" | xw "$f"; rc=${PIPESTATUS[0]}
  [ "$rc" -eq 0 ] || agp_say "      read failed ($rc) for $url (body kept in $f)"
  return "$rc"
}

p05_urlenc() {  # p05_urlenc TEXT: TEXT percent-encoded for a query string
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

p05_pages() {   # p05_pages URL KEY PAGE_SIZE [USER_PROJECT]: every page of a list, KEY merged, on standard output.
  # Returns 0 when the list is complete; 4 when a later page failed or a nextPageToken is left over (the
  # output then carries "truncated": true); otherwise the first page's api status, with Google's body printed.
  local url="$1" key="$2" size="$3" up="${4:-}" dir n=0 tok="" q body rc sep='?'
  [ -n "$up" ] || up="$(v GEMINI_PROJECT)"
  case "$url" in *'?'*) sep='&';; esac
  dir="$(mktemp -d "${TMPDIR:-/tmp}/agp-05.XXXXXX")" || return 2
  while [ $n -lt 1000 ]; do
    q="pageSize=$size"
    [ -z "$tok" ] || q="$q&pageToken=$(p05_urlenc "$tok")"
    body="$(AGP_API_PROJECT="$up" api GET "$url$sep$q")"; rc=$?
    if [ $rc -ne 0 ]; then
      if [ $n -eq 0 ]; then printf '%s\n' "$body"; rm -rf "$dir"; return $rc; fi
      printf '%s' "$body" > "$dir/error"; break
    fi
    n=$((n + 1))
    printf '%s' "$body" > "$dir/page-$n.json"
    tok="$(printf '%s' "$body" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("nextPageToken", ""))' 2>/dev/null)"
    [ -n "$tok" ] || break
  done
  python3 - "$dir" "$key" "$n" "$tok" <<'PY'
import json, os, sys
d, key, n, tok = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
items, err = [], None
for i in range(1, n + 1):
    try:
        items += json.load(open(os.path.join(d, "page-%d.json" % i))).get(key, [])
    except (ValueError, AttributeError):
        err = "page %d is not a JSON object" % i
        break
if os.path.exists(os.path.join(d, "error")):
    err = open(os.path.join(d, "error")).read()
out = {key: items, "pagesRead": n}
if err is not None or tok:
    out["truncated"] = True
    if tok:
        out["nextPageToken"] = tok
    if err is not None:
        out["readError"] = err
print(json.dumps(out, indent=1))
sys.exit(4 if out.get("truncated") else 0)
PY
  rc=$?
  rm -rf "$dir"
  return $rc
}

p05_get_pages() {   # p05_get_pages FILE URL KEY PAGE_SIZE [USER_PROJECT]: p05_pages kept as FILE; shown in plan mode
  local f="$1" url="$2" key="$3" size="$4" up="${5:-}" rc
  if [ "$AGP_MODE" != apply ]; then
    printf '      $ GET %s?pageSize=%s[&pageToken=...], every page  (X-Goog-User-Project: %s) > %s\n' "$url" "$size" "${up:-$(v GEMINI_PROJECT)}" "$f" >&3
    return 0
  fi
  p05_pages "$url" "$key" "$size" "$up" | xw "$f"; rc=${PIPESTATUS[0]}
  case "$rc" in
    0) ;;
    4) agp_say "      list truncated for $url: a later page failed or nextPageToken is still set (kept in $f)";;
    *) agp_say "      read failed ($rc) for $url (body kept in $f)";;
  esac
  return "$rc"
}

p05_json() {    # p05_json FILE PYTHON_EXPRESSION: the expression over the JSON in FILE (as d); empty when not JSON
  python3 -c 'import json, sys
d = json.load(open(sys.argv[1]))
r = eval(sys.argv[2])
if isinstance(r, (list, tuple)):
    if r:
        print("\n".join(str(x) for x in r))
elif r is not None:
    print(r if isinstance(r, str) else json.dumps(r))' "$@" 2>/dev/null
}

p05_enabled() {     # p05_enabled SERVICE: Google lists SERVICE as enabled in GEMINI_PROJECT. A filtered list, not a parse
  # of the saved GI-1.3 file (which stays the record): 0 enabled, 1 not enabled, 2 the read failed.
  nonempty gcloud services list --enabled --project="$(v GEMINI_PROJECT)" --filter="config.name=$1" --format="value(config.name)"
}

p05_ev() {      # p05_ev STEP FILE E_ID TISAX: gi_evidence of GI-0.2, through ev
  local b s
  b="$(basename "$2")"; s="${b#*-"$1"-}"; s="${s%.*}"; s="${s%-v[0-9]*}"
  s="$(printf '%s' "$s" | tr 'A-Z_.' 'a-z--' | tr -cd 'a-z0-9-')"
  ev "$1" "${s:-ge-inventory}" "$3" "$4" "build-log:ge-inventory/$b" "$2"
}

p05_app_id() {  # in apply mode, GEMINI_APP_ID has a value. Within the run in which GI-2.1 recorded a stop, the
  # runner counts GI-2.1's --sets as planned, so the app-level reads are reached without it: stop them here.
  [ "$AGP_MODE" != apply ] && return 0
  has_value GEMINI_APP_ID && return 0
  agp_say "      GEMINI_APP_ID has no value: GI-2.1 recorded a stop, so this app-level read cannot run."
  agp_say "      Run apply again: the step is then skipped as MISSING and the other reads go on (§4)."
  return 1
}

p05_mark() {    # p05_mark STEP BLOCKED|PENDING NOTE: the STOP: and PENDING: lines gi_done writes
  agp_say "      $3"
  x checkpoint "$1" "$2" - - "$3"
}

p05_track_error() {     # p05_track_error FILE...: the files whose saved text says gcloud is too old
  grep -liE 'Invalid choice|unrecognized arguments|Invalid command|is not a valid' "$@" 2>/dev/null
}

p05_reading() {         # p05_reading FILE: GI-8.3's three-case reading of one saved file
  if p05_json "$1" 'type(d).__name__' | grep -qx list; then echo "authoritative (JSON list of $(p05_json "$1" 'len(d)'))"
  elif grep -qE 'SERVICE_DISABLED|has not been used in project|PERMISSION_DENIED' "$1"; then echo "not readable in this project (record it; PENDING re-run in file 20 before GE-10)"
  else echo "unclassified: read the file"; fi
}

# ---------------------------------------------------------------- GI-0 the sitting

step GI-0.1 HUMAN "Open the shell and prove it has no default project" \
  --needs "DOMAIN ORG_ID GE_LOCATION BUILD_LOG_DIR EVIDENCE_REGISTER EVIDENCE_INTERIM_LOCATION WORKSPACE_EDITION OWNER_DAILY_ACCOUNT GCLOUD_CONFIG_NAME" \
  --note "a sitting and a sign-in: the person signs in, the script never does"
s_GI_0_1_check() { ckpt_done GI-0.1; }
s_GI_0_1_manual() {
  cat <<'EOF'
WHO: the platform owner, alone. WHERE: the workstation shell, ~/.platform-env sourced (setup/05 GI-0.1).
1. agp-platform sitting start   (01 PR-3.2: penv_guard prints 'guard clean'; gcloud auth list prints nothing;
   the sitting's START line, no witness; keep the SITTING_ID it prints)
2. gcloud config configurations activate "$GCLOUD_CONFIG_NAME"
   test -z "$(gcloud config get project 2>/dev/null)" || echo "STOP: configuration has a default project"
3. need DOMAIN ORG_ID GE_LOCATION BUILD_LOG_DIR EVIDENCE_REGISTER EVIDENCE_INTERIM_LOCATION WORKSPACE_EDITION OWNER_DAILY_ACCOUNT
   test "$GE_LOCATION" = "eu" || echo "STOP: GE_LOCATION must be eu (SD-21)"
4. gcloud auth login "$OWNER_DAILY_ACCOUNT" --no-launch-browser   (the URL in that account's own browser profile;
   sa-1-admin@ instead once file 06 has moved admin work to it)
5. gcloud auth list --filter=status:ACTIVE --format='value(account)'
   It prints the one account that holds Gemini Enterprise Admin today; the name goes into GI-10.2.
Then: agp-platform done GI-0.1
EOF
}

step GI-0.2 AUTO "Create the inventory directory and the sitting helpers" \
  --needs "BUILD_LOG_DIR" --sets "GE_INVENTORY_DIR"
s_GI_0_2_check() {
  has_value GE_INVENTORY_DIR || return 1
  local d bld; d="$(v GE_INVENTORY_DIR)"; bld="$(v BUILD_LOG_DIR)"
  [ -d "$d/restricted" ] || return 1
  cmp -s "$AGP_HOME/assets/gi-0.2-gi-helpers.sh" "$d/gi-helpers.sh" || return 1
  grep -qxF 'ge-inventory/restricted/' "$bld/.gitignore" 2>/dev/null || return 1
  git -C "$bld" check-ignore -q "$d/restricted/x" 2>/dev/null
}
s_GI_0_2_apply() {
  local bld dir
  bld="$(v BUILD_LOG_DIR)"; dir="$bld/ge-inventory"
  pset GE_INVENTORY_DIR "$dir" || return 1
  x mkdir -p "$dir/restricted" || return 1
  if ! grep -qxF 'ge-inventory/restricted/' "$bld/.gitignore" 2>/dev/null; then
    { cat "$bld/.gitignore" 2>/dev/null; printf '%s\n' 'ge-inventory/restricted/'; } | xw "$bld/.gitignore" || return 1
  fi
  # The page's heredoc, kept byte-identical in assets/ (assets/05.manifest; the tests compare it with the page).
  xw "$dir/gi-helpers.sh" < "$AGP_HOME/assets/gi-0.2-gi-helpers.sh" || return 1
}

# ---------------------------------------------------------------- GI-1 the project

step GI-1.1 CONSOLE "Find the app's project in the console" \
  --needs "GE_INVENTORY_DIR" --sets "GI_CANDIDATE_PROJECT"
s_GI_1_1_check() { ckpt_done GI-1.1; }
s_GI_1_1_manual() {
  cat <<'EOF'
WHO: the platform owner, alone.
WHERE: Google Cloud console > Gemini Enterprise (search 'Gemini Enterprise'), then the project selector.
Pick each project the selector offers until the page lists the tenant's app. Note the project id and,
for each app shown, its name and location (GI-2.1 asks whether its eu app is this one). Never open Create app.
Record:  penv_set GI_CANDIDATE_PROJECT <project id read in the console>
Screenshot:  source "$GE_INVENTORY_DIR/gi-helpers.sh"; screencapture -i "$(gi_file GI-1.1 console-apps png)"
Then: agp-platform done GI-1.1
EOF
}

step GI-1.2 AUTO-READ "Describe the project and record its id and number" \
  --needs "GI_CANDIDATE_PROJECT GE_INVENTORY_DIR" --sets "GEMINI_PROJECT GEMINI_PROJECT_NUMBER"
s_GI_1_2_check() { ckpt_done GI-1.2 && has_value GEMINI_PROJECT && has_value GEMINI_PROJECT_NUMBER; }
s_GI_1_2_apply() {
  local f pid pnum state
  f="$(p05_file GI-1.2 project json)"
  p05_save "$f" gcloud projects describe "$(v GI_CANDIDATE_PROJECT)" --format=json || return 1
  if [ "$AGP_MODE" != apply ]; then
    pset GEMINI_PROJECT "<projectId>"; pset GEMINI_PROJECT_NUMBER "<projectNumber>"; p05_ev GI-1.2 "$f" E-11 1.3; return 0
  fi
  pid="$(p05_json "$f" 'd.get("projectId", "")')"
  pnum="$(p05_json "$f" 'd.get("projectNumber", "")')"
  state="$(p05_json "$f" 'd.get("lifecycleState", "")')"
  p05_json "$f" '[d.get("lifecycleState"), (d.get("parent") or {}).get("type", "none"), (d.get("parent") or {}).get("id", "none"), json.dumps(d.get("labels") or {})]' | p05_show
  [ "$state" = ACTIVE ] || { agp_say "      VERIFY failed: lifecycleState is '$state', not ACTIVE"; return 1; }
  case "$pnum" in ''|*[!0-9]*) agp_say "      VERIFY failed: projectNumber '$pnum' is not all digits"; return 1;; esac
  [ -n "$pid" ] || { agp_say "      VERIFY failed: no projectId in $f"; return 1; }
  pset GEMINI_PROJECT "$pid" || return 1
  pset GEMINI_PROJECT_NUMBER "$pnum" || return 1
  p05_ev GI-1.2 "$f" E-11 1.3
}

p05_services_report() {     # p05_services_report FILE: GI-1.3's listing, count and cloudasset line
  p05_json "$1" 'sorted(str((s.get("config") or {}).get("name") or s.get("name")) for s in d)' | p05_show
  agp_say "      $(p05_json "$1" 'len(d)') services enabled"
  if p05_enabled cloudasset.googleapis.com; then agp_say "      cloudasset enabled"; else agp_say "      cloudasset NOT enabled"; fi
}

step GI-1.3 AUTO-READ "List the enabled services" --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_1_3_check() { ckpt_done GI-1.3; }
s_GI_1_3_apply() {
  local f rc
  f="$(p05_file GI-1.3 services-enabled json)"
  p05_save "$f" gcloud services list --enabled --project="$(v GEMINI_PROJECT)" --format=json || return 1
  [ "$AGP_MODE" = apply ] || { p05_ev GI-1.3 "$f" E-11 1.3; return 0; }
  p05_services_report "$f"
  p05_enabled discoveryengine.googleapis.com; rc=$?
  case "$rc" in
    0) ;;
    1) agp_say "      VERIFY failed: discoveryengine.googleapis.com is not enabled in $(v GEMINI_PROJECT); is this the app's project (GI-1.1)?"; return 1;;
    *) agp_say "      VERIFY failed: the filtered services list could not be read ($rc); read the error above"; return 1;;
  esac
  p05_ev GI-1.3 "$f" E-11 1.3
}

step GI-1.4 AUTO-READ "Record the current parent and the organisation" \
  --needs "GEMINI_PROJECT ORG_ID GE_INVENTORY_DIR" --sets "GE_CURRENT_PARENT"
s_GI_1_4_check() { ckpt_done GI-1.4; }
s_GI_1_4_apply() {
  local f rc p ptype pid parent org
  f="$(p05_file GI-1.4 ancestors json)"
  p05_save "$f" gcloud projects get-ancestors "$(v GEMINI_PROJECT)" --format=json; rc=$?
  [ "$AGP_MODE" = apply ] || { pset GE_CURRENT_PARENT "<organizations/N or folders/N>"; p05_ev GI-1.4 "$f" E-11 1.3; return 0; }
  p05_json "$f" '["%s\t%s" % (a.get("type"), a.get("id")) for a in d]' | p05_show
  p="$(p05_newest GI-1.2 project json)"
  ptype="$(p05_json "$p" '(d.get("parent") or {}).get("type", "none")')"
  pid="$(p05_json "$p" '(d.get("parent") or {}).get("id", "none")')"
  case "$ptype" in
    organization) parent="organizations/$pid";;
    folder) parent="folders/$pid";;
    *) parent="";;
  esac
  if [ -z "$parent" ]; then
    # The page: an unset GE_CURRENT_PARENT is the stop; the comparison is meaningless without a parent.
    p05_mark GI-1.4 BLOCKED "STOP: no organisation parent" || return 1
    p05_ev GI-1.4 "$f" E-11 1.3; return 0
  fi
  pset GE_CURRENT_PARENT "$parent" || return 1
  [ "$rc" -eq 0 ] || { agp_say "      get-ancestors failed: the organisation cannot be compared with ORG_ID; read the error above and re-run"; return 1; }
  org="$(p05_json "$f" '([a.get("id") for a in d if a.get("type") == "organization"] + [""])[0]')"
  if [ "$org" = "$(v ORG_ID)" ]; then agp_say "      organisation equals ORG_ID: true"
  else
    agp_say "      organisation equals ORG_ID: false (found '$org')"
    p05_mark GI-1.4 BLOCKED "STOP: the app's project sits in organisation ${org:-none}, not ORG_ID; open a decision record" || return 1
  fi
  p05_ev GI-1.4 "$f" E-11 1.3
}

step GI-1.5 AUTO-READ "Search the organisation for every Gemini Enterprise engine" \
  --needs "GEMINI_PROJECT ORG_ID GE_INVENTORY_DIR"
s_GI_1_5_check() { ckpt_done GI-1.5; }
s_GI_1_5_apply() {
  local f
  f="$(p05_file GI-1.5 org-engines json)"
  if [ "$AGP_MODE" != apply ]; then
    p05_save "$f" gcloud asset search-all-resources --scope="organizations/$(v ORG_ID)" --asset-types="discoveryengine.googleapis.com/Engine" --billing-project="$(v GEMINI_PROJECT)" --format=json
    printf '      (only when GI-1.3 printed cloudasset enabled; otherwise a PENDING line)\n' >&3
    p05_ev GI-1.5 "$f" E-11 1.3; return 0
  fi
  if p05_enabled cloudasset.googleapis.com; then
    if p05_save "$f" gcloud asset search-all-resources --scope="organizations/$(v ORG_ID)" --asset-types="discoveryengine.googleapis.com/Engine" --billing-project="$(v GEMINI_PROJECT)" --format=json; then
      p05_json "$f" '["%s\t%s\t%s" % (e.get("project"), e.get("location"), e.get("name")) for e in d]' | p05_show
      agp_say "      every row should belong to $(v GEMINI_PROJECT); an engine in another project is a fact-sheet line"
      p05_ev GI-1.5 "$f" E-11 1.3; return 0
    fi
    agp_say "      the organisation-wide search was refused (text kept in $f)"
  fi
  p05_mark GI-1.5 PENDING "PENDING: org-wide Engine search not run (cloudasset not enabled in GEMINI_PROJECT or no org permission); re-run from CORE_PROJECT in file 19 before GE-2"
}

# ---------------------------------------------------------------- GI-2 the app, location, edition, licences

step GI-2.1 AUTO-READ "List the apps in every location and apply the location stop" \
  --needs "GEMINI_PROJECT GE_INVENTORY_DIR GE_LOCATION" --sets "GEMINI_APP_ID GEMINI_APP_LOCATION"
s_GI_2_1_check() { ckpt_done GI-2.1; }
s_GI_2_1_apply() {
  local loc f failed="" short="" eu_n=0 other_n=0 n name
  for loc in eu us global; do
    f="$(p05_file GI-2.1 "engines-$loc" json)"
    # engines.list: pageSize and pageToken "Not supported"; one GET returns every engine.
    p05_get "$f" "$(p05_host "$loc")/v1/projects/$(v GEMINI_PROJECT)/locations/$loc/collections/default_collection/engines" || failed="$failed $loc"
    [ "$AGP_MODE" != apply ] || [ -z "$(p05_json "$f" 'd.get("nextPageToken", "")')" ] || short="$short $loc"
  done
  if [ "$AGP_MODE" != apply ]; then
    pset GEMINI_APP_ID "<the single eu APP_TYPE_INTRANET engine>"; pset GEMINI_APP_LOCATION eu
    p05_ev GI-2.1 "$f" E-11 7.1; return 0
  fi
  for loc in eu us global; do
    f="$(p05_newest GI-2.1 "engines-$loc" json)"
    agp_say "      == $loc"
    p05_json "$f" '["%s\t%s\t%s\t%s" % (e.get("name"), e.get("displayName"), e.get("appType", "none"), e.get("solutionType", "none")) for e in d.get("engines", [])]' | p05_show
    n="$(p05_json "$f" 'len([e for e in d.get("engines", []) if e.get("appType") == "APP_TYPE_INTRANET"])')"
    case "$n" in ''|*[!0-9]*) n=0;; esac
    if [ "$loc" = eu ]; then eu_n=$n; else other_n=$((other_n + n)); fi
    p05_ev GI-2.1 "$f" E-11 7.1 || return 1
  done
  agp_say "      Gemini Enterprise apps (APP_TYPE_INTRANET): eu $eu_n, us and global $other_n${failed:+; read failed for:$failed}"
  if [ -n "$short" ]; then
    # Not expected (Google documents no paging here), but a token means the count above may be short.
    p05_mark GI-2.1 PENDING "PENDING: engines list returned a nextPageToken for:$short; the app count is not complete, so no app id is set; re-run GI-2.1" || return 1
    return 1
  fi
  if [ "$eu_n" -eq 1 ]; then
    f="$(p05_newest GI-2.1 engines-eu json)"
    name="$(p05_json "$f" '[e["name"] for e in d.get("engines", []) if e.get("appType") == "APP_TYPE_INTRANET"][0]')"
    agp_say "      the eu app is ${name##*/} ($(p05_json "$f" '[e.get("displayName") for e in d.get("engines", []) if e.get("appType") == "APP_TYPE_INTRANET"][0]')): it must be the app seen in GI-1.1, or the fact sheet's LOCATION line is a STOP"
    pset GEMINI_APP_ID "${name##*/}" || return 1
    pset GEMINI_APP_LOCATION eu || return 1
    if [ "$other_n" -gt 0 ]; then
      p05_mark GI-2.1 BLOCKED "STOP: SECOND-APP: $other_n Gemini Enterprise app(s) in us or global besides the eu app; open a decision record naming the production app (P59)" || return 1
    fi
  else
    agp_say "      open decisions/$(date -u +%F)-gemini-enterprise-app-location.md: the locations found, the fix (a new eu app), what does not move (chat history, data stores)"
    p05_mark GI-2.1 BLOCKED "STOP: production app not a single eu app (eu $eu_n, us and global $other_n${failed:+, read failed for:$failed}); decision record to open (SD-21)" || return 1
  fi
}

step GI-2.2 AUTO-READ "Read the engine: features, models, logging, sessions, CMEK, gateway" \
  --needs "GEMINI_PROJECT GEMINI_APP_ID GE_INVENTORY_DIR" --on-unmet skip
s_GI_2_2_check() { ckpt_done GI-2.2; }
s_GI_2_2_apply() {
  p05_app_id || return 1
  local f rc name
  f="$(p05_file GI-2.2 engine json)"
  p05_get "$f" "$(p05_host eu)/v1/projects/$(v GEMINI_PROJECT)/locations/eu/collections/default_collection/engines/$(v GEMINI_APP_ID)"; rc=$?
  [ "$AGP_MODE" = apply ] || { p05_ev GI-2.2 "$f" E-11 5.2; return 0; }
  [ "$rc" -eq 0 ] || return 1
  name="$(p05_json "$f" 'd.get("name", "")')"
  case "$name" in */engines/"$(v GEMINI_APP_ID)") ;; *) agp_say "      VERIFY failed: .name is '$name'"; return 1;; esac
  p05_json "$f" 'json.dumps({k: d.get(k) for k in ["name", "displayName", "appType", "industryVertical", "disableAnalytics", "features", "modelConfigs", "observabilityConfig", "sessionConfig", "cmekConfig", "agentGatewaySetting", "marketplaceAgentVisibility"]}, indent=1)' | p05_show
  agp_say "      for the fact sheet: agentGatewaySetting $(p05_json "$f" '"present" if d.get("agentGatewaySetting") else "absent"'); sensitiveLoggingEnabled $(p05_json "$f" '(d.get("observabilityConfig") or {}).get("sensitiveLoggingEnabled", False)'); sessionTtl.days $(p05_json "$f" '((d.get("sessionConfig") or {}).get("sessionTtl") or {}).get("days", "unset (60)")'); cmekConfig $(p05_json "$f" '"present" if d.get("cmekConfig") else "absent"')"
  p05_ev GI-2.2 "$f" E-11 5.2
}

p05_edition() {    # p05_edition FILE: GI-2.3's edition from the licence configurations, or NONE, or a STOP: line
  # Google's SubscriptionTier descriptions, mapped as the page's table does; mixed tiers take the
  # highest in the order Plus, Standard, Frontline, Pay-as-you-go (the page's Assumption).
  python3 - "$1" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
m = {'SUBSCRIPTION_TIER_ENTERPRISE': 'Standard', 'SUBSCRIPTION_TIER_ENTERPRISE_EMERGING': 'Standard',
     'SUBSCRIPTION_TIER_SEARCH_AND_ASSISTANT': 'Plus', 'SUBSCRIPTION_TIER_CONSUMPTION_ONLY': 'Pay-as-you-go',
     'SUBSCRIPTION_TIER_FRONTLINE_WORKER': 'Frontline', 'SUBSCRIPTION_TIER_FRONTLINE_STARTER': 'Frontline'}
business = {'SUBSCRIPTION_TIER_AGENTSPACE_BUSINESS', 'SUBSCRIPTION_TIER_AGENTSPACE_STARTER'}
tiers = [c.get('subscriptionTier', '') for c in d.get('licenseConfigs', [])]
if not tiers:
    print('NONE')
elif [t for t in tiers if t in business]:
    print('STOP: Business tier found (' + ','.join(sorted(set(t for t in tiers if t in business))) + '); X-GE-18')
elif [t for t in tiers if t not in m]:
    print('STOP: tier outside the four editions (' + ','.join(sorted(set(t for t in tiers if t not in m))) + '); decision record')
else:
    eds = set(m[t] for t in tiers)
    print([e for e in ('Plus', 'Standard', 'Frontline', 'Pay-as-you-go') if e in eds][0])
PY
}

step GI-2.3 AUTO-READ "Read the subscriptions distributed to the project and set the edition" \
  --needs "GEMINI_PROJECT GE_INVENTORY_DIR" --sets "GE_EDITION"
s_GI_2_3_check() { ckpt_done GI-2.3; }
s_GI_2_3_apply() {
  local f rc res
  f="$(p05_file GI-2.3 licence-configs json)"
  p05_get "$f" "$(p05_host eu)/v1/projects/$(v GEMINI_PROJECT)/locations/eu/licenseConfigs"; rc=$?
  [ "$AGP_MODE" = apply ] || { pset GE_EDITION "<Standard|Plus|Pay-as-you-go|Frontline>"; p05_ev GI-2.3 "$f" E-11 6.1; return 0; }
  [ "$rc" -eq 0 ] || return 1
  p05_json "$f" '["%s\t%s\t%s\t%s\t%s\t%s\t%s" % (c.get("name"), c.get("subscriptionTier"), c.get("licenseCount"), c.get("state"), c.get("startDate"), c.get("endDate"), c.get("freeTrial", False)) for c in d.get("licenseConfigs", [])]' | p05_show
  res="$(p05_edition "$f")" || { agp_say "      the licence configurations could not be parsed (kept in $f)"; return 1; }
  case "$res" in
    NONE) agp_say "      VERIFY failed: no licenseConfig is distributed to $(v GEMINI_PROJECT) in eu, so GE_EDITION cannot be set; read GI-2.4's console page"; return 1;;
    STOP:*) p05_mark GI-2.3 BLOCKED "$res" || return 1;;
    *) agp_say "      edition: $res (mixed tiers take the highest; GI-3.2 confirms in the console)"; pset GE_EDITION "$res" || return 1;;
  esac
  p05_ev GI-2.3 "$f" E-11 6.1
}

step GI-2.4 CONSOLE "Record the licences procured on the billing account" \
  --needs "GEMINI_PROJECT_NUMBER GE_INVENTORY_DIR"
s_GI_2_4_check() { ckpt_done GI-2.4; }
s_GI_2_4_manual() {
  cat <<'EOF'
WHO: the platform owner; if the account cannot open the subscription's billing account, that account's
billing administrator reads the page on a shared screen and the platform owner records.
WHERE: Cloud console > Gemini Enterprise > Manage subscriptions > Billing account > Gemini Subscriptions > each name.
Record per subscription: name, edition, licences, period, auto-renew, distribution (project, location).
Then in the shell (source "$GE_INVENTORY_DIR/gi-helpers.sh" first): run GI-2.4's block of setup/05 with
GI_GE_BILLING_ACCOUNT set to the id the page shows (a local variable, not a secret); it keeps the
billingAccountLicenseConfigs read, and 'read refused' leaves the console record standing.
Evidence: screencapture -i "$(gi_file GI-2.4 subscriptions png)"; gi_evidence GI-2.4 "$f" E-11 "TISAX 6.1"
Then: agp-platform done GI-2.4
EOF
}

step GI-2.5 CONSOLE "Export the licence list and count who is assigned" \
  --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_2_5_check() { ckpt_done GI-2.5; }
s_GI_2_5_manual() {
  cat <<'EOF'
WHO: the platform owner. The list names every user: it stays under $GE_INVENTORY_DIR/restricted/.
1. Shell, helpers sourced: run GI-2.5's first block of setup/05 (userLicenses, every page, into restricted/).
2. Cloud console > Gemini Enterprise > Manage users > multi-region eu > Export all users
   (hidden when nobody is assigned); then GI-2.5's second block moves the CSV into restricted/ and counts it.
VERIFY: the CSV header has user_principal, license_config, license_assignment_state; the ASSIGNED counts
of the API and the CSV agree, or the difference goes into the fact sheet.
Evidence: upload both files by hand to EVIDENCE_INTERIM_LOCATION; then
  gi_evidence GI-2.5 "restricted (hash in manifest)" E-11 "TISAX 4.1-4.2"
Then: agp-platform done GI-2.5
EOF
}

step GI-2.6 CONSOLE "Read the identity provider" --needs "GE_INVENTORY_DIR"
s_GI_2_6_check() { ckpt_done GI-2.6; }
s_GI_2_6_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: Cloud console > Gemini Enterprise > Settings > Authentication.
Read the provider type shown for the eu location. Never click Add identity provider.
Not Google Identity: no stop, but open a decision record (P51); never change it here (a change loses chat history).
Evidence: screencapture -i "$(gi_file GI-2.6 authentication png)"; gi_evidence GI-2.6 <png> E-11 "TISAX 4.1-4.2"
Then: agp-platform done GI-2.6
EOF
}

# ---------------------------------------------------------------- GI-3 the assistant

step GI-3.1 AUTO-READ "Read the assistant's customer policy and grounding" \
  --needs "GEMINI_PROJECT GEMINI_APP_ID GE_INVENTORY_DIR" --on-unmet skip
s_GI_3_1_check() { ckpt_done GI-3.1; }
s_GI_3_1_apply() {
  p05_app_id || return 1
  local f rc
  f="$(p05_file GI-3.1 assistant json)"
  p05_get "$f" "$(p05_host eu)/v1/projects/$(v GEMINI_PROJECT)/locations/eu/collections/default_collection/engines/$(v GEMINI_APP_ID)/assistants/default_assistant"; rc=$?
  [ "$AGP_MODE" = apply ] || { p05_ev GI-3.1 "$f" E-11 5.2; return 0; }
  [ "$rc" -eq 0 ] || return 1
  p05_json "$f" 'json.dumps({"name": d.get("name"), "webGroundingType": d.get("webGroundingType"), "defaultWebGroundingToggleOff": d.get("defaultWebGroundingToggleOff"), "enabledTools": d.get("enabledTools"), "modelArmor": (d.get("customerPolicy") or {}).get("modelArmorConfig"), "bannedPhraseCount": len((d.get("customerPolicy") or {}).get("bannedPhrases") or []), "dataProtectionPolicy": (d.get("customerPolicy") or {}).get("dataProtectionPolicy")}, indent=1)' | p05_show
  agp_say "      cross-check without saving: Gemini Enterprise > the app > Configurations > Assistant > Enable Model Armor"
  p05_ev GI-3.1 "$f" E-11 5.2
}

step GI-3.2 CONSOLE "Read the current chat-history retention and set the floor" \
  --needs "GE_INVENTORY_DIR" --sets "GE_RETENTION_CURRENT_DAYS"
s_GI_3_2_check() { ckpt_done GI-3.2; }
s_GI_3_2_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: Cloud console > Gemini Enterprise > the app > Configurations > Assistant
tab > Chat history retention period. Read it; never change it, never click Save and publish: a lower
value deletes every older chat without warning and with no recovery (X-GE-01).
In the shell, helpers sourced, run GI-3.2's first block of setup/05 (it prints the API sessionTtl.days).
Floor: the console value if shown; if hidden, sessionTtl.days, or 60 when unset; if both, the larger.
Record:  penv_set GE_RETENTION_CURRENT_DAYS <integer per the rule>
Then GI-3.2's printf block writes the retention record; screencapture -i "$(gi_file GI-3.2 retention png)";
gi_evidence GI-3.2 "$f" E-11 "TISAX 7.1"
Then: agp-platform done GI-3.2
EOF
}

step GI-3.3 AUTO-READ "Read the Model Armor templates the assistant names" \
  --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_3_3_check() { ckpt_done GI-3.3; }
s_GI_3_3_apply() {
  local a t loc tp f
  if [ "$AGP_MODE" = apply ]; then
    a="$(p05_newest GI-3.1 assistant json)"
    if [ -n "$a" ]; then
      for t in $(p05_json "$a" '[x for x in [((d.get("customerPolicy") or {}).get("modelArmorConfig") or {}).get(k) for k in ("userPromptTemplate", "responseTemplate")] if x]'); do
        loc="$(printf '%s' "$t" | cut -d/ -f4)"; tp="$(printf '%s' "$t" | cut -d/ -f2)"
        f="$(p05_file GI-3.3 "template-${t##*/}" json)"
        p05_get "$f" "https://modelarmor.$loc.rep.googleapis.com/v1/$t" "$tp" || agp_say "      read failed: $t"
        [ "$loc" = eu ] || agp_say "      fact-sheet line for GE-7: template $t is in $loc, not eu (the template and app locations must match)"
        p05_ev GI-3.3 "$f" E-11 5.2 || return 1
      done
    else
      agp_say "      no GI-3.1 file (the app id is unset): no template is named; the list below still runs"
    fi
  else
    printf '      (first, one GET per template GI-3.1 names, on https://modelarmor.<loc>.rep.googleapis.com/v1/<template>)\n' >&3
  fi
  f="$(p05_file GI-3.3 templates-eu json)"
  p05_get "$f" "https://modelarmor.eu.rep.googleapis.com/v1/projects/$(v GEMINI_PROJECT)/locations/eu/templates" \
    || agp_say "      list failed (Model Armor API may not be enabled): a fact-sheet line"
  p05_ev GI-3.3 "$f" E-11 5.2
}

# ---------------------------------------------------------------- GI-4 encryption

step GI-4.1 AUTO-READ "Read the CmekConfig state" --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_4_1_check() { ckpt_done GI-4.1; }
s_GI_4_1_apply() {
  local f rc e
  f="$(p05_file GI-4.1 cmek-configs json)"
  p05_get "$f" "$(p05_host eu)/v1/projects/$(v GEMINI_PROJECT)/locations/eu/cmekConfigs"; rc=$?
  [ "$AGP_MODE" = apply ] || { p05_ev GI-4.1 "$f" E-11 5.1; return 0; }
  [ "$rc" -eq 0 ] || return 1
  p05_json "$f" '["%s\t%s\t%s\t%s\t%s" % (c.get("name"), c.get("kmsKey"), c.get("state"), c.get("isDefault"), len(c.get("singleRegionKeys") or [])) for c in d.get("cmekConfigs", [])] or ["no CmekConfig"]' | p05_show
  e="$(p05_newest GI-2.2 engine json)"
  [ -z "$e" ] || agp_say "      the engine's own cmekConfig: $(p05_json "$e" 'd.get("cmekConfig") or "absent"')"
  agp_say "      also read Gemini Enterprise > Settings > CMEK tab for eu (never click Add key); the fact sheet records the state"
  p05_ev GI-4.1 "$f" E-11 5.1
}

# ---------------------------------------------------------------- GI-5 access today

step GI-5.1 AUTO-READ "Export the project IAM policy" --needs "GEMINI_PROJECT DOMAIN GE_INVENTORY_DIR"
s_GI_5_1_check() { ckpt_done GI-5.1; }
s_GI_5_1_apply() {
  local f
  f="$(p05_file GI-5.1 project-iam json)"
  p05_save "$f" gcloud projects get-iam-policy "$(v GEMINI_PROJECT)" --format=json || return 1
  [ "$AGP_MODE" = apply ] || { p05_ev GI-5.1 "$f" E-11 4.1-4.2; return 0; }
  [ -n "$(p05_json "$f" 'd.get("etag", "")')" ] || { agp_say "      VERIFY failed: the policy has no etag"; return 1; }
  p05_json "$f" '["%s\t%s" % (b["role"], m) for b in d.get("bindings", []) if "discoveryengine" in b["role"] or b["role"] in ("roles/owner", "roles/editor", "roles/viewer") for m in b.get("members", [])]' | p05_show
  agp_say "      members outside $(v DOMAIN) that are not service accounts (each explained or flagged in the fact sheet):"
  p05_json "$f" 'sorted(set(m for b in d.get("bindings", []) for m in b.get("members", []) if not m.endswith("@" + sys.argv[3]) and not m.endswith("gserviceaccount.com")))' "$(v DOMAIN)" | p05_show
  p05_ev GI-5.1 "$f" E-11 4.1-4.2
}

step GI-5.2 AUTO-READ "Export the app's IAM policy" \
  --needs "GEMINI_PROJECT GEMINI_APP_ID GE_INVENTORY_DIR" --on-unmet skip
s_GI_5_2_check() { ckpt_done GI-5.2; }
s_GI_5_2_apply() {
  p05_app_id || return 1
  local f rc
  f="$(p05_file GI-5.2 engine-iam json)"
  p05_get "$f" "$(p05_host eu)/v1/projects/$(v GEMINI_PROJECT)/locations/eu/collections/default_collection/engines/$(v GEMINI_APP_ID):getIamPolicy"; rc=$?
  [ "$AGP_MODE" = apply ] || { p05_ev GI-5.2 "$f" E-11 4.1-4.2; return 0; }
  [ "$rc" -eq 0 ] || return 1
  [ -n "$(p05_json "$f" 'd.get("etag", "")')" ] || { agp_say "      VERIFY failed: the response has no etag"; return 1; }
  p05_json "$f" '["%s\t%s" % (b["role"], m) for b in d.get("bindings", []) for m in b.get("members", [])] or ["no app-level binding"]' | p05_show
  p05_ev GI-5.2 "$f" E-11 4.1-4.2
}

step GI-5.3 AUTO-READ "Export inherited and deny policies" --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_5_3_check() { ckpt_done GI-5.3; }
s_GI_5_3_apply() {
  local f anc missing="" id
  f="$(p05_file GI-5.3 ancestors-iam json)"
  if ! p05_save "$f" gcloud projects get-ancestors-iam-policy "$(v GEMINI_PROJECT)" --include-deny --format=json; then
    p05_mark GI-5.3 PENDING "PENDING: ancestor IAM not readable; re-run in file 19 before GE-3 with the file 06 admin account"
    return
  fi
  [ "$AGP_MODE" = apply ] || { p05_ev GI-5.3 "$f" E-11 4.1-4.2; return 0; }
  p05_json "$f" '["%s/%s\t%s\t%s" % (a.get("type"), a.get("id"), b.get("role"), m) for a in d if a.get("type") != "project" for b in ((a.get("policy") or {}).get("bindings") or []) for m in b.get("members", [])]' | p05_show
  anc="$(p05_newest GI-1.4 ancestors json)"
  for id in $(p05_json "$anc" '[a.get("id") for a in d if a.get("type") != "project"]'); do
    p05_json "$f" '[a.get("id") for a in d]' | grep -qx "$id" || missing="$missing $id"
  done
  [ -z "$missing" ] || { agp_say "      VERIFY failed: the policies of$missing (GI-1.4's ancestors) are not in $f"; return 1; }
  p05_ev GI-5.3 "$f" E-11 4.1-4.2
}

step GI-5.4 HUMAN "Write who reaches the app today, and how" --needs "GE_INVENTORY_DIR"
s_GI_5_4_check() { ckpt_done GI-5.4; }
s_GI_5_4_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: the shell (helpers sourced), then an editor.
1. Run GI-5.4's block of setup/05: one member count per group holding a discoveryengine role in GI-5.1 or GI-5.2.
2. Write "$(gi_file GI-5.4 access-today md)" as the page's table: one row per path to the app (project
   binding, app binding, inherited, licence only with GI-2.5's ASSIGNED count), counts only, no names.
3. Under the table, one sentence: which path today's users rely on (project-level IAM takes precedence).
VERIFY: every discoveryengine or basic-role binding of GI-5.1 to GI-5.3 appears in one row.
Evidence: gi_evidence GI-5.4 "$f" E-11 "TISAX 4.1-4.2"
Then: agp-platform done GI-5.4
EOF
}

# ---------------------------------------------------------------- GI-6 assets and policies

step GI-6.1 AUTO-READ "Confirm the services list is current" --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_6_1_check() { ckpt_done GI-6.1; }
s_GI_6_1_apply() {
  local newest
  if [ "$AGP_MODE" != apply ]; then
    printf '      (only when the newest GI-1.3 file carries an earlier date:)\n' >&3
    p05_save "$(p05_file GI-1.3 services-enabled json)" gcloud services list --enabled --project="$(v GEMINI_PROJECT)" --format=json
    return 0
  fi
  newest="$(p05_newest GI-1.3 services-enabled json)"
  case "$(basename "${newest:-none}")" in
    "$(date -u +%F)"-*) agp_say "      GI-1.3 already carries $(date -u +%F); not re-run";;
    *) newest="$(p05_file GI-1.3 services-enabled json)"
       p05_save "$newest" gcloud services list --enabled --project="$(v GEMINI_PROJECT)" --format=json || return 1
       agp_say "      GI-1.3 re-run into $newest; file 19's allow-list union must read this file, not the earlier one (X-GE-03)"
       p05_ev GI-6.1 "$newest" E-11 1.3 || return 1;;
  esac
  p05_services_report "$newest"
}

step GI-6.2 AUTO-READ "Take the Cloud Asset inventory of the project" --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_6_2_check() { ckpt_done GI-6.2; }
s_GI_6_2_apply() {
  local f g
  f="$(p05_file GI-6.2 assets json)"; g="$(p05_file GI-6.2 resource-iam json)"
  if [ "$AGP_MODE" != apply ]; then
    printf '      (only when GI-1.3 printed cloudasset enabled; otherwise a PENDING line)\n' >&3
    p05_save "$f" gcloud asset search-all-resources --scope="projects/$(v GEMINI_PROJECT)" --billing-project="$(v GEMINI_PROJECT)" --format=json
    p05_save "$g" gcloud asset search-all-iam-policies --scope="projects/$(v GEMINI_PROJECT)" --billing-project="$(v GEMINI_PROJECT)" --format=json
    p05_ev GI-6.2 "$f" E-11 1.3; p05_ev GI-6.2 "$g" E-11 4.1-4.2; return 0
  fi
  if ! p05_enabled cloudasset.googleapis.com; then
    p05_mark GI-6.2 PENDING "PENDING: asset search not run; re-run from CORE_PROJECT in file 19 before GE-3"; return
  fi
  if ! p05_save "$f" gcloud asset search-all-resources --scope="projects/$(v GEMINI_PROJECT)" --billing-project="$(v GEMINI_PROJECT)" --format=json \
     || ! p05_save "$g" gcloud asset search-all-iam-policies --scope="projects/$(v GEMINI_PROJECT)" --billing-project="$(v GEMINI_PROJECT)" --format=json; then
    p05_mark GI-6.2 PENDING "PENDING: asset search refused; re-run from CORE_PROJECT in file 19 before GE-3"; return
  fi
  p05_json "$f" '["%s\t%s" % (n, t) for t, n in sorted(__import__("collections").Counter(a.get("assetType") for a in d).items())]' | p05_show
  p05_json "$f" '[a.get("assetType") for a in d]' | grep -qx 'discoveryengine.googleapis.com/Engine' \
    || agp_say "      fact-sheet line: no discoveryengine.googleapis.com/Engine asset in the project"
  p05_json "$g" 'sorted(set("%s\t%s" % (p.get("assetType"), p.get("resource")) for p in d))' | p05_show
  p05_ev GI-6.2 "$f" E-11 1.3 || return 1
  p05_ev GI-6.2 "$g" E-11 4.1-4.2
}

step GI-6.3 AUTO-READ "Read the effective organisation policies that file 19 will change" \
  --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_6_3_check() { ckpt_done GI-6.3; }
s_GI_6_3_apply() {
  local f c out args=()
  f="$(p05_file GI-6.3 org-policies json)"
  if [ "$AGP_MODE" != apply ]; then
    for c in gcp.restrictServiceUsage gcp.resourceLocations discoveryengine.managed.allowedDataSources discoveryengine.managed.allowedEgressFqdns; do
      printf '      $ %s\n' "$(agp_quote gcloud org-policies describe "$c" --project="$(v GEMINI_PROJECT)" --effective --format=json)" >&3
    done
    printf '      $ %s\n' "$(agp_quote gcloud org-policies list --project="$(v GEMINI_PROJECT)" --format=json)" >&3
    printf '      (each answer, or the error text Google returned, kept in %s)\n' "$f" >&3
    p05_ev GI-6.3 "$f" E-11 5.2; return 0
  fi
  for c in gcp.restrictServiceUsage gcp.resourceLocations discoveryengine.managed.allowedDataSources discoveryengine.managed.allowedEgressFqdns; do
    out="$(r gcloud org-policies describe "$c" --project="$(v GEMINI_PROJECT)" --effective --format=json 2>&1)"
    args[${#args[@]}]="$c"; args[${#args[@]}]="$out"
  done
  out="$(r gcloud org-policies list --project="$(v GEMINI_PROJECT)" --format=json 2>&1)"
  args[${#args[@]}]="set_on_project"; args[${#args[@]}]="$out"
  python3 -c 'import json, sys
a = sys.argv[1:]
o = {}
for k, val in zip(a[0::2], a[1::2]):
    try:
        o[k] = json.loads(val)
    except ValueError:
        o[k] = val
print(json.dumps(o, indent=1))' "${args[@]}" | xw "$f" || return 1
  p05_json "$f" 'sorted(d.keys())' | p05_show
  p05_ev GI-6.3 "$f" E-11 5.2
}

# ---------------------------------------------------------------- GI-7 data stores and connectors

step GI-7.1 AUTO-READ "List collections and their connectors" --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_7_1_check() { ckpt_done GI-7.1; }
s_GI_7_1_apply() {
  local loc f rc short=""
  for loc in eu us global; do
    f="$(p05_file GI-7.1 "collections-$loc" json)"
    # Every page: collections.list returns at most 100 per call unless asked for more.
    p05_get_pages "$f" "$(p05_host "$loc")/v1alpha/projects/$(v GEMINI_PROJECT)/locations/$loc/collections" collections 100; rc=$?
    [ "$AGP_MODE" = apply ] || continue
    [ "$rc" -ne 4 ] || short="$short $loc"
    p05_json "$f" '["%s\t%s\t%s\t%s\t%s" % (sys.argv[3], c.get("name"), c.get("displayName"), (c.get("dataConnector") or {}).get("dataSource", "no connector"), (c.get("dataConnector") or {}).get("state", "")) for c in d.get("collections", [])]' "$loc" | p05_show
    p05_ev GI-7.1 "$f" E-11 6.1 || return 1
  done
  [ "$AGP_MODE" = apply ] || { p05_ev GI-7.1 "$f" E-11 6.1; return 0; }
  if [ -n "$short" ]; then
    p05_mark GI-7.1 PENDING "PENDING: collections list truncated in:$short (a later page failed or nextPageToken is still set); re-run GI-7.1 before GI-7.2 and GI-7.3" || return 1
    return 1
  fi
  return 0
}

step GI-7.2 AUTO-READ "List data stores per collection" --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_7_2_check() { ckpt_done GI-7.2; }
s_GI_7_2_apply() {
  local loc f c rc st tmp i short="" failed=""
  for loc in eu us global; do
    f="$(p05_file GI-7.2 "datastores-$loc" json)"
    if [ "$AGP_MODE" != apply ]; then
      printf '      $ GET %s/v1/projects/%s/locations/%s/collections/<each GI-7.1 collection>/dataStores?pageSize=50[&pageToken=...], every page > %s\n' "$(p05_host "$loc")" "$(v GEMINI_PROJECT)" "$loc" "$f" >&3
      continue
    fi
    # One entry per collection, every page merged (dataStores.list: 10 by default, at most 50 per page).
    [ "$(p05_json "$(p05_newest GI-7.1 "collections-$loc" json)" 'd.get("truncated", False)')" != true ] \
      || short="$short $loc(GI-7.1 collections)"
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/agp-05.XXXXXX")" || return 1
    i=0
    for c in $(p05_json "$(p05_newest GI-7.1 "collections-$loc" json)" '[c["name"].split("/")[-1] for c in d.get("collections", [])]'); do
      i=$((i + 1))
      p05_pages "$(p05_host "$loc")/v1/projects/$(v GEMINI_PROJECT)/locations/$loc/collections/$c/dataStores" dataStores 50 > "$tmp/$i.body"; rc=$?
      printf '%s' "$c" > "$tmp/$i.name"; printf '%s' "$rc" > "$tmp/$i.rc"
      case "$rc" in
        0) ;;
        4) short="$short $loc/$c"; agp_say "      data stores of $loc/$c: list truncated (a later page failed or nextPageToken is still set)";;
        *) failed="$failed $loc/$c"; agp_say "      data stores of $loc/$c: read failed ($rc); Google's answer kept as readError";;
      esac
    done
    python3 - "$tmp" "$i" <<'PY' | xw "$f"
import json, os, sys
d, n = sys.argv[1], int(sys.argv[2])
out = []
for i in range(1, n + 1):
    c = open(os.path.join(d, "%d.name" % i)).read()
    rc = open(os.path.join(d, "%d.rc" % i)).read()
    body = open(os.path.join(d, "%d.body" % i)).read()
    try:
        r = json.loads(body) if rc in ("0", "4") else None
    except ValueError:
        r = None
    if isinstance(r, dict):
        r = dict(r, collection=c)
    out.append(r if isinstance(r, dict) else {"collection": c, "readError": body})
print(json.dumps(out, indent=1))
PY
    st="${PIPESTATUS[0]} ${PIPESTATUS[1]}"
    rm -rf "$tmp"
    [ "$st" = "0 0" ] || return 1
    p05_json "$f" '["%s\t%s\t%s\t%s\t%s\t%s" % (sys.argv[3], s.get("name"), s.get("displayName"), s.get("industryVertical"), s.get("aclEnabled", False), s.get("kmsKeyName", "google-managed")) for x in d for s in x.get("dataStores", [])]' "$loc" | p05_show
    [ "$loc" = eu ] || [ "$(p05_json "$f" 'sum(len(x.get("dataStores", [])) for x in d)')" = 0 ] \
      || agp_say "      fact-sheet line: data stores in $loc (03 §12: data stores in eu only)"
    p05_ev GI-7.2 "$f" E-11 6.1 || return 1
  done
  agp_say "      cross-check in the console: Gemini Enterprise > Data stores; one the API did not list goes into GI-7.3 by hand"
  [ "$AGP_MODE" = apply ] || { p05_ev GI-7.2 "$f" E-11 6.1; return 0; }
  [ -z "$failed" ] || agp_say "      collections whose data stores could not be read (a fact-sheet line each):$failed"
  if [ -n "$short" ]; then
    p05_mark GI-7.2 PENDING "PENDING: data stores list truncated for:$short (a later page failed or nextPageToken is still set); re-run GI-7.2 before GI-7.3" || return 1
    return 1
  fi
  return 0
}

step GI-7.3 HUMAN "Decide, per data store, against the future allow-list" --needs "GE_INVENTORY_DIR"
s_GI_7_3_check() { ckpt_done GI-7.3; }
s_GI_7_3_manual() {
  cat <<'EOF'
WHO: the platform owner, as the P58 owner (IT security reviews the list later in file 19).
WHERE: an editor, writing "$(gi_file GI-7.3 datasource-decisions md)".
One row per data store (GI-7.2), connector (GI-7.1) and console-only item, in the page's columns,
decided against 03 §12's initial allow-list (first-party Google Workspace sources only): keep, keep and
propose an addition with a supplier row, remove in file 19 after the app owners agree, or *tbd* with a
named person and a date. Nothing is removed here.
Evidence: gi_evidence GI-7.3 "$f" E-11 "TISAX 6.1"
Then: agp-platform done GI-7.3
EOF
}

# ---------------------------------------------------------------- GI-8 agents and the GE-10 import list

step GI-8.1 CONSOLE "Read the Agents page in the console" --needs "GE_INVENTORY_DIR"
s_GI_8_1_check() { ckpt_done GI-8.1; }
s_GI_8_1_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: Cloud console > Gemini Enterprise > the app > Agents.
For every agent: display name, type (Agent Runtime, A2A, Dialogflow, no-code or other), state, and who
it is shared with where shown. Never click Add agent or Edit. The console count goes into the fact sheet.
Evidence: screencapture -i "$(gi_file GI-8.1 console-agents png)"
Then: agp-platform done GI-8.1
EOF
}

step GI-8.2 AUTO-READ "List agents through the API and extract what they reach" \
  --needs "GEMINI_PROJECT GEMINI_APP_ID GE_INVENTORY_DIR" --on-unmet skip
s_GI_8_2_check() { ckpt_done GI-8.2; }
s_GI_8_2_apply() {
  p05_app_id || return 1
  local f url q tok="" body failed=0 pages=0 args=()
  f="$(p05_file GI-8.2 agents json)"
  url="$(p05_host eu)/v1alpha/projects/$(v GEMINI_PROJECT)/locations/eu/collections/default_collection/engines/$(v GEMINI_APP_ID)/assistants/default_assistant/agents"
  if [ "$AGP_MODE" != apply ]; then
    printf '      $ GET %s?pageSize=100[&pageToken=...], every page > %s\n' "$url" "$f" >&3
    p05_ev GI-8.2 "$f" E-11 6.1; return 0
  fi
  while [ $pages -lt 1000 ]; do
    pages=$((pages + 1))
    q="pageSize=100"
    [ -z "$tok" ] || q="$q&pageToken=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$tok")"
    body="$(AGP_API_PROJECT="$(v GEMINI_PROJECT)" api GET "$url?$q")" || { failed=1; agp_say "      read failed on page $pages"; break; }
    args[${#args[@]}]="$body"
    tok="$(printf '%s' "$body" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("nextPageToken", ""))' 2>/dev/null)"
    [ -n "$tok" ] || break
  done
  python3 -c 'import json, sys
agents = []
for body in sys.argv[1:]:
    try:
        agents += json.loads(body).get("agents", [])
    except ValueError:
        pass
print(json.dumps({"agents": agents}, indent=1))' "${args[@]}" | xw "$f" || return 1
  python3 - "$f" <<'PY' | p05_show
import json, re, sys
d = json.load(open(sys.argv[1]))
def strings(x):
    if isinstance(x, dict):
        for v in x.values():
            yield from strings(v)
    elif isinstance(x, list):
        for v in x:
            yield from strings(v)
    elif isinstance(x, str):
        yield x
for a in d.get("agents", []):
    defs = ",".join(k for k in a if k.endswith("Definition"))
    reach = " ".join(sorted(set(s for s in strings(a) if re.search(r"reasoningEngines/|^https://|dialogflow", s))))
    print("\t".join([str(a.get("name")), str(a.get("displayName")), str(a.get("state")), defs, reach]))
PY
  agp_say "      agents collected: $(p05_json "$f" 'len(d["agents"])'); nextPageToken left: ${tok:-none}; read failed: $([ "$failed" = 1 ] && echo yes || echo no)"
  if [ "$failed" = 1 ] || [ -n "$tok" ]; then
    # A failed page, the first one included, leaves the list short: never recorded as done.
    p05_mark GI-8.2 PENDING "PENDING: agents list truncated (a page failed or nextPageToken is still set); re-run before GI-8.5" || return 1
    return 1
  fi
  agp_say "      agents.list returns only the agents created by the caller: the console list (GI-8.1) is authoritative"
  p05_ev GI-8.2 "$f" E-11 6.1
}

step GI-8.3 AUTO-READ "List what is already in an Agent Registry in the project" \
  --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_8_3_check() { ckpt_done GI-8.3; }
s_GI_8_3_apply() {
  local loc kind f files=() bad
  for loc in global eu europe-west1; do
    for kind in agents endpoints mcp-servers services; do
      f="$(p05_file GI-8.3 "registry-$kind-$loc" json)"
      p05_save_all "$f" gcloud agent-registry "$kind" list --location="$loc" --project="$(v GEMINI_PROJECT)" --format=json \
        || { [ "$AGP_MODE" != apply ] || agp_say "      failed: $kind $loc (see $f)"; }
      files[${#files[@]}]="$f"
    done
  done
  [ "$AGP_MODE" = apply ] || { p05_ev GI-8.3 "$f" E-11 6.1; return 0; }
  bad="$(p05_track_error "${files[@]}")"
  if [ -n "$bad" ]; then
    printf '%s\n' "$bad" | p05_show
    p05_mark GI-8.3 BLOCKED "STOP: command track wrong; registry state unknown" || return 1
    agp_say "      gcloud is too old: gcloud components update, then re-run GI-8.3; never record 'no registry'"
    return 1
  fi
  for f in "${files[@]}"; do
    agp_say "      $(basename "$f"): $(p05_reading "$f")"
    p05_ev GI-8.3 "$f" E-11 6.1 || return 1
  done
}

step GI-8.4 AUTO-READ "List existing agent gateways and the app's binding" \
  --needs "GEMINI_PROJECT GE_INVENTORY_DIR"
s_GI_8_4_check() { ckpt_done GI-8.4; }
s_GI_8_4_apply() {
  local loc f files=() bad e
  for loc in europe-west1 us-central1; do
    f="$(p05_file GI-8.4 "agent-gateways-$loc" json)"
    p05_save_all "$f" gcloud network-services agent-gateways list --location="$loc" --project="$(v GEMINI_PROJECT)" --format=json \
      || { [ "$AGP_MODE" != apply ] || agp_say "      failed: $loc (see $f)"; }
    files[${#files[@]}]="$f"
  done
  [ "$AGP_MODE" = apply ] || { p05_ev GI-8.4 "$f" E-11 5.2; return 0; }
  bad="$(p05_track_error "${files[@]}")"
  if [ -n "$bad" ]; then
    printf '%s\n' "$bad" | p05_show
    agp_say "      STOP: command track wrong: gcloud components update, then re-run GI-8.4; never record 'no gateway'"
    return 1
  fi
  for f in "${files[@]}"; do
    agp_say "      $(basename "$f"): $(p05_reading "$f")"
    p05_ev GI-8.4 "$f" E-11 5.2 || return 1
  done
  e="$(p05_newest GI-2.2 engine json)"
  if [ -n "$e" ]; then agp_say "      the app's binding: $(p05_json "$e" 'json.dumps({"name": d.get("name"), "agentGatewaySetting": d.get("agentGatewaySetting")})')"
  else agp_say "      no GI-2.2 file: the app's binding is read in the console (the app > Security > Agent Gateway configuration)"; fi
  agp_say "      the fact sheet says 'app not bound' or names the bound gateway; a bound app is a stop for file 20's GE-10"
}

step GI-8.5 HUMAN "Write the GE-10 import list" --needs "GE_INVENTORY_DIR"
s_GI_8_5_check() { ckpt_done GI-8.5; }
s_GI_8_5_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: an editor, writing "$(gi_file GI-8.5 ge10-import-list csv)".
Not before GI-8.2 ran to a clean end of pages (no PENDING line for GI-8.2).
Header: kind,identifier,seen_in,used_by_agent,in_registry,register_row,note
One line per destination the live app reaches today, from GI-7 and GI-8.1 to GI-8.4 (by eye from the
saved files); every console agent of GI-8.1 has a line, or 'none' in identifier.
Evidence: gi_evidence GI-8.5 "$f" E-11 "TISAX 6.1"
Then: agp-platform done GI-8.5
EOF
}

# ---------------------------------------------------------------- GI-9 the Workspace side

step GI-9.1 CONSOLE "Read the Gemini Enterprise service status per OU and per group" --needs "GE_INVENTORY_DIR"
s_GI_9_1_check() { ckpt_done GI-9.1; }
s_GI_9_1_manual() {
  cat <<'EOF'
WHO: the platform owner, with the Service Settings privilege or super admin.
WHERE: Google Admin console > Menu > Generative AI > Gemini Enterprise > Service status.
Read the top level, then each OU and each configuration group: value, inherited or overridden. Never click Save.
Write "$(gi_file GI-9.1 service-status md)" with the page's columns, including /Automation/Service Identities
(or 'OU does not exist on <date>'); if that OU exists and is On, flag it for file 30.
Evidence: screenshots of OUs with overrides; gi_evidence GI-9.1 "$f" E-11 "TISAX 4.1-4.2"
Then: agp-platform done GI-9.1
EOF
}

step GI-9.2 CONSOLE "Read 'Allow Gemini Enterprise to access Google Workspace data' per OU and per group" --needs "GE_INVENTORY_DIR"
s_GI_9_2_check() { ckpt_done GI-9.2; }
s_GI_9_2_manual() {
  cat <<'EOF'
WHO: the platform owner.
WHERE: Admin console > Menu > Generative AI > Gemini Enterprise > Standard, Plus, or Frontline (and
Business Edition if shown) > Allow Gemini Enterprise to access Google Workspace data.
Read the top level and every OU and group override, as in GI-9.1. Never click Save.
Write "$(gi_file GI-9.2 workspace-data-access md)": GI-9.1's columns plus the edition section;
whether a Business Edition section shows and has users goes into the fact sheet.
Evidence: gi_evidence GI-9.2 "$f" E-11 "TISAX 4.1-4.2"
Then: agp-platform done GI-9.2
EOF
}

step GI-9.3 CONSOLE "Check whether Context-Aware Access for Gemini Enterprise is visible" --needs "GE_INVENTORY_DIR WORKSPACE_EDITION"
s_GI_9_3_check() { ckpt_done GI-9.3; }
s_GI_9_3_manual() {
  cat <<'EOF'
WHO: the platform owner (super admin covers the access level and rule privileges).
WHERE: Admin console > Menu > Security > Access and data control > Context-Aware Access > Assign access
levels > Assign access levels to apps. Look for Gemini Enterprise; assign nothing.
Write "$(gi_file GI-9.3 caa md)": the date; visible yes or no (never 'not available'); WORKSPACE_EDITION
against Google's eligible list; any access level already assigned.
Evidence: screencapture -i "$(gi_file GI-9.3 caa png)"; gi_evidence GI-9.3 "$f" E-11 "TISAX 4.1-4.2"
Add the pending decision 'access level assigned to Gemini Enterprise' to 03's tracker (X-GE-19).
Then: agp-platform done GI-9.3
EOF
}

step GI-9.4 CONSOLE "Re-check Context-Aware Access on or after 2026-09-23" --needs "GE_INVENTORY_DIR"
s_GI_9_4_check() { ckpt_done GI-9.4; }
s_GI_9_4_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: as GI-9.3.
If GI-9.3 recorded 'visible': agp-platform done GI-9.4 --note "CAA re-check: visible=yes at GI-9.3; support case none"
Otherwise read the page again (any day from 2026-09-23, so a GI-9.3 read made on or after that date
already is this re-check) and write a new version of the GI-9.3 file. Still not visible: open a Google
Workspace support case asking why the feature announced on 2026-09-08 is not visible.
Then: agp-platform done GI-9.4 --note "CAA re-check: visible=<yes|no>; support case <number or none>"
EOF
}

# ---------------------------------------------------------------- GI-10 close

p05_manifest_today() {  # the newest GI-10.1 manifest, if it carries today's date
  local m; m="$(p05_newest GI-10.1 manifest sha256)"
  case "$(basename "${m:-none}")" in "$(date -u +%F)"-*) printf '%s\n' "$m";; esac
}

step GI-10.1 AUTO "Hash every file and commit the non-restricted ones" \
  --needs "GE_INVENTORY_DIR BUILD_LOG_DIR"
s_GI_10_1_check() {
  local m bld; bld="$(v BUILD_LOG_DIR)"
  m="$(p05_manifest_today)"; [ -n "$m" ] || return 1
  git -C "$bld" ls-files --error-unmatch "ge-inventory/$(basename "$m")" >/dev/null 2>&1 || return 1
  [ "$(git -C "$bld" ls-files ge-inventory | grep -c restricted)" = 0 ]
}
s_GI_10_1_apply() {
  local dir bld m
  dir="$(v GE_INVENTORY_DIR)"; bld="$(v BUILD_LOG_DIR)"
  m="$(p05_file GI-10.1 manifest sha256)"
  if [ "$AGP_MODE" != apply ]; then
    printf "      \$ ( cd %s && find . -type f ! -name '*-GI-10.1-manifest-*' ! -name 'gi-helpers.sh' -print0 | sort -z | xargs -0 shasum -a 256 ) > %s\n" "$dir" "$m" >&3
    x git -C "$bld" add .gitignore ge-inventory
    x git -C "$bld" commit -q -m "05 Gemini Enterprise inventory $(date -u +%F)"
    p05_ev GI-10.1 "$m" E-05 1.5; return 0
  fi
  ( cd "$dir" && find . -type f ! -name '*-GI-10.1-manifest-*' ! -name 'gi-helpers.sh' -print0 | sort -z | xargs -0 shasum -a 256 ) | xw "$m" || return 1
  x git -C "$bld" add .gitignore ge-inventory || return 1
  if git -C "$bld" diff --cached --name-only | grep -q restricted; then
    agp_say "      STOP: a restricted file is staged; nothing was committed. Unstage it and read .gitignore"
    return 1
  fi
  if ! git -C "$bld" diff --cached --quiet; then
    x git -C "$bld" commit -q -m "05 Gemini Enterprise inventory $(date -u +%F)" || return 1
  fi
  [ "$(git -C "$bld" ls-files ge-inventory | grep -c restricted)" = 0 ] || { agp_say "      VERIFY failed: a restricted file is in git"; return 1; }
  ( cd "$dir" && shasum -a 256 -c "$m" >/dev/null ) || { agp_say "      VERIFY failed: shasum -c $m"; return 1; }
  p05_ev GI-10.1 "$m" E-05 1.5 || return 1
  agp_say "      now upload every file under $dir/restricted/ to EVIDENCE_INTERIM_LOCATION by hand, and compare one hash with $m"
}

step GI-10.2 HUMAN "Write the fact sheet and the stop-gate record" --needs "GE_INVENTORY_DIR GEMINI_PROJECT"
s_GI_10_2_check() { ckpt_done GI-10.2; }
s_GI_10_2_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: an editor, writing "$(gi_file GI-10.2 facts md)".
Fill the page's fact table, every value or *tbd* with a reason; the restricted files are in EVIDENCE_INTERIM_LOCATION.
Every BLOCKED (STOP:) and PENDING line of a GI step in checkpoints.tsv goes into it:
  awk -F'\t' '$2 ~ /^GI-/ && ($3 == "BLOCKED" || $3 == "PENDING")' "$BUILD_LOG_DIR/checkpoints.tsv"
Then the gate, five lines at the start of a line: ORG:, LOCATION:, SECOND-APP:, EDITION: read 'clear' or
'STOP: <decision record path>'; IDP: reads 'clear' or 'DECISION: <path>'.
Check with GI-10.2's block of setup/05; gi_evidence GI-10.2 "$f" E-05 "TISAX 1.3"; commit as in GI-10.1.
Then: agp-platform done GI-10.2
EOF
}

step GI-10.3 HUMAN "End the sitting" --needs "BUILD_LOG_DIR"
s_GI_10_3_check() { ckpt_done GI-10.3; }
s_GI_10_3_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: the shell.
1. git -C "$BUILD_LOG_DIR" add ge-inventory
   git -C "$BUILD_LOG_DIR" diff --cached --quiet || git -C "$BUILD_LOG_DIR" commit -m "05 fact sheet $(date -u +%F)"
2. agp-platform done GI-10.3
3. agp-platform sitting end      (01's sitting_end, then the SITTING DONE line with the START line's id)
VERIFY: SITTING-END OK; the last two SITTING- lines of checkpoints.tsv carry one id, START then DONE;
ls ~/Downloads/*.csv no longer shows the 'Manage users' export.
EOF
}
