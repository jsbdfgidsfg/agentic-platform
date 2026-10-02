# phases/09-folders-and-security-command-center.sh: setup/09, the folder tree, the observability
# location, the tags, Essential Contacts and Security Command Center (SCC). 33 steps, FS-0.1 to FS-8.3.
#
# Notes on how the page's shell becomes steps:
# - The page's `mkfld` helper looks for a folder by name before creating it. Here the look is the
#   step's check (fs09_folders_check), and the apply creates only what the check found missing,
#   or records the id of a folder that already exists. A recorded FLD_* variable means "done",
#   exactly as in mkfld; FS-3.4 then proves the tree against the variables.
# - The page's GRANT_UNTIL is a shell variable. Here it is written to BUILD_LOG_DIR/records, so a
#   resumed run reuses it while it is live and FS-1.2 grants "until the same GRANT_UNTIL".
# - The testIamPermissions probes of FS-0.4 and FS-1.2 are saved as records. FS-0.5 and FS-1.2 grant
#   a role only when the probe showed its permissions missing and no live binding of it exists.
# - Whether `agp-env` is created, and FS-5.4 run, follows FS-0.2's record of the NAMES register.
# - The page's python blocks are kept, with every gcloud change moved out of python into `x`.
# - Three value checks of the page sit in the AUTO-READ verification that follows the AUTO step,
#   which stops the run before anything uses the value: the folder ids are all digits (mkfld's
#   refusal, enforced at FS-3.4, before folders.yaml or any tag binding), the tag keys read
#   tagKeys/<digits> (FS-5.1's VERIFY, enforced at FS-5.6), and the folder's observability default
#   reads REGION (FS-2.1's VERIFY, enforced at FS-2.2, before any project can exist). The AUTO step
#   still refuses an empty or malformed answer and reports any other one. FS-2.1 is done once its
#   update ran and its describe is recorded, so a second apply never repeats the update.
# - The time-bound grants of FS-0.5 and FS-1.2 are never re-made once FS-8.1 has removed them; they
#   end 12 hours after they are made and never after BOOTSTRAP_EXCEPTION_EXPIRY.

phase 09 "Folders and Security Command Center" "09-folders-and-security-command-center.md"
requires org "resourcemanager.organizations.get resourcemanager.organizations.getIamPolicy resourcemanager.organizations.setIamPolicy resourcemanager.folders.create resourcemanager.folders.get resourcemanager.folders.list resourcemanager.folders.getIamPolicy resourcemanager.folders.setIamPolicy resourcemanager.projects.list orgpolicy.policy.get"

# ---------------------------------------------------------------- helpers (fs09_ prefix)
FS09_TODO=""; FS09_TODO_FOR=""; FS09_DROPPED=""

fs09_plan_show() {  # fs09_plan_show TEXT: in plan mode, what an AUTO-READ step would run
  [ "$AGP_MODE" = apply ] && return 0
  printf '      $ %s\n' "$*" >&3
}

fs09_rec() {        # fs09_rec STEP SLUG [EXT]: the record path of the page's naming, today, v1
  printf '%s/records/%s-%s-%s-v1.%s' "$(v BUILD_LOG_DIR)" "$(date -u +%Y-%m-%d)" "$1" "$2" "${3:-txt}"
}

fs09_latest() {     # fs09_latest PATTERN: the last file matching PATTERN in name order (dates sort)
  local f last=""
  for f in $1; do [ -f "$f" ] && last="$f"; done
  [ -n "$last" ] || return 1
  printf '%s' "$last"
}

fs09_env_signed() { # agp-env is in FS-0.2's record of the signed NAMES register
  local f
  for f in "$(_penv_get BUILD_LOG_DIR)"/records/*-FS-0.2-names-tag-keys-v1.txt; do
    [ -f "$f" ] && grep -qx agp-env "$f" && return 0
  done
  return 1
}

fs09_names_rec_exists() {   # FS-0.2 has written its record of the NAMES register
  local f
  for f in "$(_penv_get BUILD_LOG_DIR)"/records/*-FS-0.2-names-tag-keys-v1.txt; do [ -f "$f" ] && return 0; done
  return 1
}

fs09_pending_recorded() {   # fs09_pending_recorded STEP: checkpoints.tsv holds a PENDING line for STEP
  [ -f "$(_penv_get BUILD_LOG_DIR)/checkpoints.tsv" ] || return 1
  awk -F'\t' -v s="$1" '$2 == s && $3 == "PENDING" {f=1} END {exit f ? 0 : 1}' "$(_penv_get BUILD_LOG_DIR)/checkpoints.tsv"
}

fs09_rerun_index() {    # the re-run index with FS-5.4's PENDING line added (01's columns, header kept)
  local f; f="$(_penv_get BUILD_LOG_DIR)/rerun-index.tsv"
  if [ -s "$f" ]; then cat "$f"; else printf 'date\tstep_id\tmember\twhat_to_rerun\tstatus\tdetail\n'; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%d)" FS-5.4 "agp-env key and its bindings" \
    "09 FS-5.1 agp-env lines, FS-5.2 env values, FS-5.4, FS-5.6" PENDING "agp-env not in the signed NAMES record (09 FS-0.2)"
}

fs09_grant_until() {   # a new end time in the page's format: 12 hours from now, and never after
  # BOOTSTRAP_EXCEPTION_EXPIRY (read as the start of that day, UTC). Fails when the exception has ended.
  python3 -c '
import sys, datetime as d
now = d.datetime.now(d.timezone.utc)
t = now + d.timedelta(hours=12)
try:
    e = d.datetime.strptime(sys.argv[1], "%Y-%m-%d").replace(tzinfo=d.timezone.utc)
    t = min(t, e)
except ValueError:
    pass   # in plan mode the expiry may still be a placeholder; FS-0.1 checks the real value
if t <= now + d.timedelta(minutes=30):
    sys.stderr.write("the bootstrap exception ends %s: no time-bound grant can be made; back to 06\n" % sys.argv[1]); sys.exit(1)
print(t.strftime("%Y-%m-%dT%H:%M:%SZ"))' "$(v BOOTSTRAP_EXCEPTION_EXPIRY)"
}

fs09_grant_until_live() {   # the GRANT_UNTIL recorded by this file if it has at least 30 minutes left
  local f t
  f="$(fs09_latest "$(_penv_get BUILD_LOG_DIR)/records/*-grant-until-v1.txt")" || return 1
  t="$(tr -d ' \n' < "$f")"
  python3 -c 'import sys,datetime as d; t=d.datetime.strptime(sys.argv[1],"%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=d.timezone.utc); sys.exit(0 if t > d.datetime.now(d.timezone.utc)+d.timedelta(minutes=30) else 1)' "$t" 2>/dev/null \
    || return 1
  printf '%s' "$t"
}

fs09_role_perms() {    # the permissions of the probe a role is granted for
  case "$1" in
    tagAdmin) echo "resourcemanager.tagKeys.create resourcemanager.tagValues.create";;
    tagUser) echo "resourcemanager.tagValueBindings.create resourcemanager.hierarchyNodes.createTagBinding";;
    observability.editor) echo "observability.settings.get observability.settings.update";;
    essentialcontacts.admin) echo "essentialcontacts.contacts.create essentialcontacts.contacts.list";;
    logging.configWriter) echo "logging.settings.get";;
  esac
}

fs09_role_title() {    # the page's condition title for a role's time-bound grant
  case "$1" in
    tagAdmin) echo fs-bootstrap-tagadmin;;
    tagUser) echo fs-bootstrap-taguser;;
    observability.editor) echo fs-bootstrap-obs;;
    essentialcontacts.admin) echo fs-bootstrap-contacts;;
    logging.configWriter) echo fs-bootstrap-logconfig;;
  esac
}

fs09_role_id() {       # the full role id
  case "$1" in tagAdmin|tagUser) echo "roles/resourcemanager.$1";; *) echo "roles/$1";; esac
}

fs09_missing() {       # fs09_missing FILE PERM...: the permissions FILE (a probe response) does not echo
  local f="$1"; shift
  python3 "$AGP_HOME/lib/agp_json.py" missing "$@" < "$f"
}

fs09_probe() {   # fs09_probe URL OUTFILE PERM...: testIamPermissions; the response is saved to OUTFILE.
  # A 400 naming one permission as invalid for the resource drops it and re-probes (FS-0.4, FS-1.2).
  local url="$1" out="$2" body resp rc p drop perms; shift 2
  perms=" $* "
  while :; do
    body="$(mktemp "${TMPDIR:-/tmp}/fs09-probe.XXXXXX")" || return 2
    # shellcheck disable=SC2086
    python3 -c 'import json,sys; print(json.dumps({"permissions": sys.argv[1:]}))' $perms > "$body"
    resp="$(api POST "$url" "$body")"; rc=$?
    rm -f "$body"
    [ "$AGP_MODE" = apply ] || return 0
    if [ $rc -eq 0 ]; then
      printf '%s\n' "$resp" | xw "$out" || return 2
      printf '%s\n' "$resp" >&3
      return 0
    fi
    drop=""
    for p in $perms; do case "$resp" in *"$p"*) drop="$p"; break;; esac; done
    case "$resp" in *INVALID_ARGUMENT*|*'"code": 400'*) ;; *) drop="";; esac
    if [ -n "$drop" ]; then
      agp_say "      Resource Manager refused $drop for this resource: dropped and probed again (recorded under the step)"
      perms="${perms/ $drop / }"; FS09_DROPPED="$FS09_DROPPED $drop"
      continue
    fi
    printf '%s\n' "$resp" >&2
    return 2
  done
}

fs09_wait_perms() {   # fs09_wait_perms URL OUTFILE PERM...: re-probe until every permission is echoed
  # (IAM propagation, "usually under 7 minutes" in the page); at most 10 minutes.
  local url="$1" out="$2" i=0 left; shift 2
  [ "$AGP_MODE" = apply ] || return 0
  while [ $i -lt 20 ]; do
    i=$((i + 1))
    fs09_probe "$url" "$out" "$@" >/dev/null || return 1
    left="$(fs09_missing "$out" "$@" | tr '\n' ' ')"
    [ -n "${left// /}" ] || { agp_say "      every probed permission is held"; return 0; }
    agp_say "      waiting for IAM propagation ($i of 20): not yet held: $left"
    sleep 30
  done
  agp_say "      FAIL: after 10 minutes these are still not held: $left"
  return 1
}

fs09_live_binding() { # fs09_live_binding org|folder RID ROLE TITLE: SA_1_ADMIN holds ROLE unconditionally,
  # or under the condition TITLE and before its end time. 0 yes, 1 no, 2 error, 3 offline
  local pol rc
  if [ "$1" = org ]; then pol="$(r gcloud organizations get-iam-policy "$2" --format=json 2>/dev/null)"; rc=$?
  else pol="$(r gcloud resource-manager folders get-iam-policy "$2" --format=json 2>/dev/null)"; rc=$?; fi
  case $rc in 0) ;; 3) return 3;; *) return 2;; esac
  printf '%s' "$pol" | python3 -c '
import json, re, sys, datetime as d
member, role, title = sys.argv[1:4]
raw = sys.stdin.read()
pol = json.loads(raw) if raw.strip() else {}
now = d.datetime.now(d.timezone.utc)
for b in pol.get("bindings", []):
    if b.get("role") != role or member not in b.get("members", []):
        continue
    c = b.get("condition")
    if not c:
        sys.exit(0)
    if c.get("title") != title:
        continue
    t = re.search(r"timestamp\(\"([^\"]+)\"\)", c.get("expression", ""))
    if t and d.datetime.strptime(t.group(1), "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=d.timezone.utc) > now:
        sys.exit(0)
sys.exit(1)' "user:$(v SA_1_ADMIN)" "$(fs09_role_id "$3")" "$4"
}

fs09_grants_todo() {  # fs09_grants_todo org|folder RID PROBE_FILE ROLE...: the roles still to grant
  local kind="$1" rid="$2" rec="$3" role rc out=""; shift 3
  for role in "$@"; do
    # shellcheck disable=SC2046
    if [ -n "$rec" ] && [ -f "$rec" ] && [ -z "$(fs09_missing "$rec" $(fs09_role_perms "$role"))" ]; then continue; fi
    fs09_live_binding "$kind" "$rid" "$role" "$(fs09_role_title "$role")"; rc=$?
    case $rc in 0) ;; 1) out="$out $role";; *) return $rc;; esac
  done
  printf '%s' "${out# }"
}

# ---- folders
fs09_folder_lookup() {  # fs09_folder_lookup PARENT_VAR NAME: the id of the folder NAME under the parent
  local out rc n
  if [ "$1" = ORG_ID ]; then
    out="$(r gcloud resource-manager folders list --organization="$(v ORG_ID)" --filter="displayName=$2" --format="value(name)")"; rc=$?
  else
    out="$(r gcloud resource-manager folders list --folder="$(v "$1")" --filter="displayName=$2" --format="value(name)")"; rc=$?
  fi
  [ $rc -eq 0 ] || return $rc
  n="$(printf '%s\n' "$out" | grep -c .)"
  if [ "$n" -gt 1 ]; then agp_say "      $2: $n folders with this name under the parent; resolve by hand"; return 2; fi
  out="${out##*/}"
  printf '%s' "$out"
}

fs09_folders_check() {  # fs09_folders_check STEP LIST: 0 when every variable of LIST is recorded
  local step="$1" var name pvar id todo="" rc
  while read -r var name pvar; do
    [ -n "$var" ] || continue
    has_value "$var" && continue
    if ! has_value "$pvar"; then todo="$todo $var"; continue; fi
    id="$(fs09_folder_lookup "$pvar" "$name")"; rc=$?
    case $rc in 0) ;; 3) return 3;; *) return 2;; esac
    if [ -n "$id" ]; then todo="$todo $var=$id"; else todo="$todo $var"; fi
  done <<EOF
$2
EOF
  FS09_TODO_FOR="$step"; FS09_TODO="$todo"
  [ -z "$todo" ]
}

fs09_folders_apply() {  # fs09_folders_apply STEP LIST: the page's mkfld for each folder the check found missing
  local step="$1" list="$2" todo item var id line name pvar
  todo="$FS09_TODO"
  if [ "$FS09_TODO_FOR" != "$step" ]; then
    todo=""; for var in $(printf '%s\n' "$list" | awk '{print $1}'); do has_value "$var" || todo="$todo $var"; done
  fi
  for item in $todo; do
    var="${item%%=*}"; id=""
    case "$item" in *=*) id="${item#*=}";; esac
    line="$(printf '%s\n' "$list" | awk -v n="$var" '$1 == n')"
    name="$(echo "$line" | awk '{print $2}')"; pvar="$(echo "$line" | awk '{print $3}')"
    if [ -n "$id" ]; then
      agp_say "      $name exists under its parent as $id: recorded, not created"
    else
      if [ "$pvar" = ORG_ID ]; then
        x gcloud resource-manager folders create --display-name="$name" --organization="$(v ORG_ID)" || return 1
      else
        x gcloud resource-manager folders create --display-name="$name" --folder="$(v "$pvar")" || return 1
      fi
      if [ "$AGP_MODE" != apply ]; then pset "$var" "<from the folder list>"; continue; fi
      id="$(fs09_folder_lookup "$pvar" "$name")" || return 1
    fi
    # The page's mkfld refuses anything but digits. A lookup that printed nothing, several words or a
    # path stops here; a single token that is not all digits is reported, and FS-3.4 (which every later
    # use of the ids waits for) stops on it before folders.yaml or a tag binding is written.
    case "$id" in ""|*[[:space:]/:]*) agp_say "      FAIL: $name gave id '$id'"; return 1;; esac
    case "$id" in *[!0-9]*) agp_say "      WARNING: $name gave id '$id', which is not all digits: FS-3.4 stops on it";; esac
    pset "$var" "$id" || return 1
  done
  return 0
}

fs09_list_1_1() { echo "FLD_AGENTIC_PLATFORM fld-agentic-platform ORG_ID"; }
fs09_list_3_1() { cat <<'EOF'
FLD_PLATFORM_CORE fld-platform-core FLD_AGENTIC_PLATFORM
FLD_GEMINI_ENTERPRISE fld-gemini-enterprise FLD_AGENTIC_PLATFORM
FLD_AGENTS_R fld-agents-r FLD_AGENTIC_PLATFORM
FLD_AGENTS_W fld-agents-w FLD_AGENTIC_PLATFORM
FLD_AGENTS_P fld-agents-p FLD_AGENTIC_PLATFORM
FLD_AGENTS_X fld-agents-x FLD_AGENTIC_PLATFORM
FLD_CONTROLLERS fld-controllers FLD_AGENTIC_PLATFORM
FLD_IMPROVERS fld-improvers FLD_AGENTIC_PLATFORM
EOF
}
fs09_list_3_2() { cat <<'EOF'
FLD_AGENTS_R_PROD fld-agents-r-prod FLD_AGENTS_R
FLD_AGENTS_R_NONPROD fld-agents-r-nonprod FLD_AGENTS_R
FLD_AGENTS_W_PROD fld-agents-w-prod FLD_AGENTS_W
FLD_AGENTS_W_NONPROD fld-agents-w-nonprod FLD_AGENTS_W
FLD_AGENTS_P_PROD fld-agents-p-prod FLD_AGENTS_P
FLD_AGENTS_P_NONPROD fld-agents-p-nonprod FLD_AGENTS_P
FLD_AGENTS_P_SA fld-agents-p-sa FLD_AGENTS_P
FLD_CONTROLLERS_PROD fld-controllers-prod FLD_CONTROLLERS
FLD_CONTROLLERS_NONPROD fld-controllers-nonprod FLD_CONTROLLERS
FLD_IMPROVERS_PROD fld-improvers-prod FLD_IMPROVERS
FLD_IMPROVERS_NONPROD fld-improvers-nonprod FLD_IMPROVERS
EOF
}
fs09_list_3_3() { cat <<'EOF'
FLD_AGENTS_P_SA_PROD fld-agents-p-sa-prod FLD_AGENTS_P_SA
FLD_AGENTS_P_SA_NONPROD fld-agents-p-sa-nonprod FLD_AGENTS_P_SA
EOF
}
FS09_ALL_FLD="FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE FLD_GEMINI_ENTERPRISE FLD_AGENTS_R FLD_AGENTS_R_PROD FLD_AGENTS_R_NONPROD FLD_AGENTS_W FLD_AGENTS_W_PROD FLD_AGENTS_W_NONPROD FLD_AGENTS_P FLD_AGENTS_P_PROD FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD FLD_AGENTS_X FLD_CONTROLLERS FLD_CONTROLLERS_PROD FLD_CONTROLLERS_NONPROD FLD_IMPROVERS FLD_IMPROVERS_PROD FLD_IMPROVERS_NONPROD"

# ---- tag bindings
fs09_list_5_3() { cat <<'EOF'
FLD_PLATFORM_CORE agp-tier core
FLD_GEMINI_ENTERPRISE agp-tier ge
FLD_AGENTS_R agp-tier r
FLD_AGENTS_W agp-tier w
FLD_AGENTS_P agp-tier p
FLD_AGENTS_P_SA agp-tier p-sa
FLD_AGENTS_X agp-tier x
FLD_CONTROLLERS agp-tier ctl
FLD_IMPROVERS agp-tier imp
EOF
}
fs09_list_5_4() { cat <<'EOF'
FLD_AGENTS_R_PROD agp-env prod
FLD_AGENTS_W_PROD agp-env prod
FLD_AGENTS_P_PROD agp-env prod
FLD_AGENTS_P_SA_PROD agp-env prod
FLD_CONTROLLERS_PROD agp-env prod
FLD_IMPROVERS_PROD agp-env prod
FLD_AGENTS_R_NONPROD agp-env nonprod
FLD_AGENTS_W_NONPROD agp-env nonprod
FLD_AGENTS_P_NONPROD agp-env nonprod
FLD_AGENTS_P_SA_NONPROD agp-env nonprod
FLD_CONTROLLERS_NONPROD agp-env nonprod
FLD_IMPROVERS_NONPROD agp-env nonprod
EOF
}
fs09_list_5_5() { cat <<'EOF'
FLD_AGENTIC_PLATFORM agp-tisax-scope in
FLD_AGENTS_X agp-tisax-scope out
EOF
}

fs09_bind_check() {   # fs09_bind_check STEP LIST: 0 when each folder of LIST carries its value directly
  # (the effective value of the key equals it; no folder here inherits the value it is meant to bind)
  local step="$1" var key val out rc todo=""
  has_value ORG_ID || return 1
  while read -r var key val; do
    [ -n "$var" ] || continue
    if ! has_value "$var"; then todo="$todo $var:$key:$val"; continue; fi
    out="$(r gcloud resource-manager tags bindings list --parent="//cloudresourcemanager.googleapis.com/folders/$(v "$var")" --effective --filter="namespacedTagValue=$(v ORG_ID)/$key/$val" --format="value(tagValue)")"; rc=$?
    case $rc in 0) ;; 3) return 3;; *) return 2;; esac
    [ -n "$out" ] || todo="$todo $var:$key:$val"
  done <<EOF
$2
EOF
  FS09_TODO_FOR="$step"; FS09_TODO="$todo"
  [ -z "$todo" ]
}

fs09_bind_apply() {   # fs09_bind_apply STEP LIST: the page's `tags bindings create` for each missing one
  local step="$1" todo item var key val
  todo="$FS09_TODO"
  [ "$FS09_TODO_FOR" = "$step" ] || todo="$(printf '%s\n' "$2" | awk 'NF {printf " %s:%s:%s", $1, $2, $3}')"
  for item in $todo; do
    var="${item%%:*}"; key="${item#*:}"; val="${key#*:}"; key="${key%%:*}"
    x gcloud resource-manager tags bindings create --tag-value="$(v ORG_ID)/$key/$val" --parent="//cloudresourcemanager.googleapis.com/folders/$(v "$var")" || return 1
  done
  return 0
}

# ======================================================================== FS-0 gates, reads, grants

step FS-0.1 HUMAN "Open the sitting and check the inputs" \
  --needs "ORG_ID DOMAIN REGION GCLOUD_CONFIG_NAME PLATFORM_ENV_FILE PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_INTERIM_LOCATION EVIDENCE_REGISTER DEVIATION_REGISTER SA_1_ADMIN BOOTSTRAP_EXCEPTION_EXPIRY GRP_PLATFORM_SECURITY GRP_PLATFORM_OWNERS SCC_BILLING_MODEL"
s_FS_0_1_check() { ckpt_done FS-0.1; }
s_FS_0_1_manual() {
  echo "WHO: the platform owner as $(v SA_1_ADMIN). No witness. The sign-in uses the hardware key, so a person does it."
  echo "WHERE: the shell with ~/.platform-env sourced, gcloud configuration $(v GCLOUD_CONFIG_NAME) active."
  echo "DO: gcloud auth login \"\$SA_1_ADMIN\"; then the four checks of setup/09 FS-0.1 ACTION:"
  echo "    penv_guard; the active account (gcloud auth list) is $(v SA_1_ADMIN);"
  echo "    today is before BOOTSTRAP_EXCEPTION_EXPIRY ($(v BOOTSTRAP_EXCEPTION_EXPIRY)); REGION is europe-west1 (it is $(v REGION))."
  echo "Any FAIL stops the file. An expired exception goes back to 06; it is never extended silently."
  echo "RECORD: agp-platform done FS-0.1 --note \"exception valid until <date read>\""
}

step FS-0.2 AUTO-READ "Check the signed gates" --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER" \
  --gate "SD-01 SD-15 SD-17 SD-38 P11 NAMES"
s_FS_0_2_check() { ckpt_done FS-0.2; }
s_FS_0_2_apply() {
  local prd tool rec f
  prd="$(v PLATFORM_REPO_DIR)"; tool="$(agp_tool decision-need.sh)"; f="$(fs09_rec FS-0.2 names-tag-keys)"
  if [ "$AGP_MODE" != apply ]; then
    case "$tool" in /tools/*) tool="<PLATFORM_REPO_DIR>$tool";; esac
    fs09_plan_show "\"$tool\" SD-01 SD-15 SD-17 SD-38 P11 NAMES"
    fs09_plan_show "grep -o 'agp-[a-z-]*' <the NAMES record named in decisions/TRACKER.md> | sort -u > $f"
    return 0
  fi
  "$tool" SD-01 SD-15 SD-17 SD-38 P11 NAMES || { echo "FAIL: a decision above is not SIGNED; the file stops here"; return 1; }
  rec="$(awk -F'|' '{k=$2; gsub(/ /,"",k); if (k=="NAMES") {r=$4; gsub(/ /,"",r); print r}}' "$prd/decisions/TRACKER.md" 2>/dev/null | head -n 1)"
  if [ -z "$rec" ] || [ ! -f "$prd/decisions/$rec" ]; then
    echo "FAIL: no NAMES record found through $prd/decisions/TRACKER.md (03 DC-5.1)"; return 1
  fi
  grep -o "agp-[a-z-]*" "$prd/decisions/$rec" | sort -u | xw "$f" || return 1
  cat "$f"
  grep -qx agp-tier "$f" && grep -qx agp-tisax-scope "$f" \
    || { echo "FAIL: the NAMES record does not list both agp-tier and agp-tisax-scope"; return 1; }
  if ! grep -qx agp-env "$f"; then
    echo "NOTE: agp-env is not in the signed NAMES record: FS-5.1 creates two keys and FS-5.4 is recorded PENDING"
  fi
  ev FS-0.2 names-tag-keys E-03 1.4.1 "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
}

step FS-0.3 AUTO-READ "Read the organisation as it is" --needs "ORG_ID DOMAIN BUILD_LOG_DIR EVIDENCE_REGISTER"
s_FS_0_3_check() { ckpt_done FS-0.3; }
s_FS_0_3_apply() {
  local org f tmp out rc bad=0
  org="$(v ORG_ID)"; f="$(fs09_rec FS-0.3 org-read)"
  if [ "$AGP_MODE" != apply ]; then
    fs09_plan_show "the seven reads of setup/09 FS-0.3 (folders, tag keys, logging and observability settings, three effective policies) > $f"
    return 0
  fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/fs09-orgread.XXXXXX")" || return 1
  {
    echo "# setup/09 FS-0.3, $(date -u +%Y-%m-%dT%H:%M:%SZ), organisation $org"
    echo "\$ gcloud resource-manager folders list --organization=$org"
    gcloud resource-manager folders list --organization="$org" --format="table(displayName,name.basename())" 2>&1 || echo "(read failed, exit $?)"
    echo "\$ gcloud resource-manager tags keys list --parent=organizations/$org"
    gcloud resource-manager tags keys list --parent="organizations/$org" --format="table(shortName,name)" 2>&1 || echo "(read failed, exit $?)"
    echo "\$ gcloud logging settings describe --organization=$org"
    gcloud logging settings describe --organization="$org" 2>&1 || echo "(read failed, exit $?: a permission error is expected here; ask the organisation's Cloud Logging owner for the value and its date)"
    echo "\$ gcloud observability settings describe --organization=$org --location=global"
    gcloud observability settings describe --organization="$org" --location=global 2>&1 || echo "(read failed, exit $?: a permission error is expected here)"
    echo "\$ gcloud org-policies describe gcp.resourceLocations --organization=$org --effective"
    gcloud org-policies describe gcp.resourceLocations --organization="$org" --effective 2>&1 || echo "(read failed, exit $?)"
    echo "\$ gcloud org-policies describe iam.allowedPolicyMemberDomains --organization=$org --effective"
    gcloud org-policies describe iam.allowedPolicyMemberDomains --organization="$org" --effective 2>&1 || echo "(read failed, exit $?)"
    echo "\$ gcloud org-policies describe essentialcontacts.managed.allowedContactDomains --organization=$org --effective"
    gcloud org-policies describe essentialcontacts.managed.allowedContactDomains --organization="$org" --effective 2>&1 || echo "(read failed, exit $?)"
  } > "$tmp"
  cat "$tmp"
  xw "$f" < "$tmp" || { rm -f "$tmp"; return 1; }
  rm -f "$tmp"

  # The conditions of the page's table, each from its own filtered read.
  out="$(r gcloud resource-manager folders list --organization="$org" --filter='displayName~"^fld-"' --format="value(displayName)")" || return 1
  if [ -n "$out" ]; then echo "STOP: a folder named fld-* already exists under the organisation: $out (03 decides: rename, reuse or move)"; bad=1; fi
  out="$(r gcloud resource-manager tags keys list --parent="organizations/$org" --filter='shortName~"^agp-(tier|env|tisax-scope)$"' --format="value(shortName)")" || return 1
  if [ -n "$out" ]; then echo "STOP: tag key(s) already exist: $out. Reuse only if identical to the expected table, recorded as a deviation."; bad=1; fi
  out="$(r gcloud logging settings describe --organization="$org" --format=json 2>/dev/null)"; rc=$?
  if [ $rc -eq 0 ]; then
    if ! printf '%s' "$out" | python3 -c 'import json,sys; t=sys.stdin.read(); p=json.loads(t) if t.strip() else {}; sys.exit(0 if p.get("storageLocation","") in ("","global") else 1)'; then
      echo "STOP: the organisation's Cloud Logging default storage location is not global: Sensitive Actions is blind for new projects. Raise a decision with the organisation's Cloud Logging owner."; bad=1
    fi
  else
    echo "NOTE: the organisation's logging settings could not be read (expected); FS-2.2's folder-level read is the binding one."
  fi
  out="$(r gcloud org-policies describe gcp.resourceLocations --organization="$org" --effective --format=json 2>/dev/null)" \
    && case "$out" in *'"rules"'*) echo "NOTE: gcp.resourceLocations has a policy at the organisation: record it and tell IT security before FS-7.";; esac
  echo "NOTE: tell IT security the allowed customer ids of iam.allowedPolicyMemberDomains above before FS-7."
  ev FS-0.3 org-read E-05 "1.5.1 5.2.4" "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
  return $bad
}

step FS-0.4 AUTO-READ "Probe the permissions at the organisation" --needs "ORG_ID BUILD_LOG_DIR EVIDENCE_REGISTER"
s_FS_0_4_check() { ckpt_done FS-0.4; }
s_FS_0_4_apply() {
  local f miss
  f="$(fs09_rec FS-0.4 org-permissions json)"
  fs09_probe "https://cloudresourcemanager.googleapis.com/v3/organizations/$(v ORG_ID):testIamPermissions" "$f" \
    resourcemanager.folders.create resourcemanager.organizations.setIamPolicy resourcemanager.tagKeys.create \
    resourcemanager.tagValues.create resourcemanager.tagValueBindings.create resourcemanager.hierarchyNodes.createTagBinding || return 1
  [ "$AGP_MODE" = apply ] || return 0
  [ -z "$FS09_DROPPED" ] || echo "Dropped as invalid for the organisation:$FS09_DROPPED"
  miss="$(fs09_missing "$f" resourcemanager.folders.create resourcemanager.organizations.setIamPolicy | tr '\n' ' ')"
  if [ -n "${miss// /}" ]; then echo "FAIL: not held: $miss: return to 06 (Folder Creator, Organization Administrator)"; return 1; fi
  echo "Tag permissions not held (expected; FS-0.5 grants them): $(fs09_missing "$f" resourcemanager.tagKeys.create resourcemanager.tagValues.create resourcemanager.tagValueBindings.create resourcemanager.hierarchyNodes.createTagBinding | tr '\n' ' ')"
  ev FS-0.4 org-permissions - "4.1.3 4.2.1" "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
}

step FS-0.5 AUTO "Time-bound organisation grants the exception does not cover" \
  --needs "ORG_ID SA_1_ADMIN BOOTSTRAP_EXCEPTION_EXPIRY BUILD_LOG_DIR EVIDENCE_REGISTER" --gate "SD-01"
s_FS_0_5_check() {
  local rec todo rc
  ckpt_done FS-8.1 && return 0   # the sitting is closed: its grants were removed on purpose, never re-made
  has_value ORG_ID && has_value SA_1_ADMIN || return 1
  rec="$(fs09_latest "$(_penv_get BUILD_LOG_DIR)/records/*-FS-0.4-org-permissions-v1.json")"
  todo="$(fs09_grants_todo org "$(v ORG_ID)" "$rec" tagAdmin tagUser)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  FS09_TODO_FOR=FS-0.5; FS09_TODO="$todo"
  [ -z "$todo" ]
}
s_FS_0_5_apply() {
  local todo gu role f
  todo="$FS09_TODO"; [ "$FS09_TODO_FOR" = FS-0.5 ] || todo="tagAdmin tagUser"
  gu="$(fs09_grant_until)" || return 1
  agp_say "      grants end at $gu; exception ends $(v BOOTSTRAP_EXCEPTION_EXPIRY)"
  [ "$AGP_MODE" != apply ] || printf '%s\n' "$gu" | xw "$(fs09_rec FS-0.5 grant-until)" || return 1
  for role in $todo; do
    x gcloud organizations add-iam-policy-binding "$(v ORG_ID)" --member="user:$(v SA_1_ADMIN)" --role="$(fs09_role_id "$role")" \
      --condition="expression=request.time < timestamp(\"$gu\"),title=$(fs09_role_title "$role"),description=09 FS-0.5 SD-01 bootstrap" || return 1
  done
  [ "$AGP_MODE" = apply ] || return 0
  fs09_wait_perms "https://cloudresourcemanager.googleapis.com/v3/organizations/$(v ORG_ID):testIamPermissions" "$(fs09_rec FS-0.5 org-permissions-after json)" \
    resourcemanager.folders.create resourcemanager.organizations.setIamPolicy resourcemanager.tagKeys.create \
    resourcemanager.tagValues.create resourcemanager.tagValueBindings.create resourcemanager.hierarchyNodes.createTagBinding || return 1
  f="$(fs09_rec FS-0.5 org-grants)"
  r gcloud organizations get-iam-policy "$(v ORG_ID)" --flatten="bindings[].members" --filter="bindings.members:user:$(v SA_1_ADMIN) AND bindings.condition.title:fs-bootstrap" --format="table(bindings.role,bindings.condition.title,bindings.condition.expression)" | xw "$f" || return 1
  cat "$f"
  ev FS-0.5 org-grants E-05 "4.1.3 4.2.1" "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
}

# ======================================================================== FS-1 the root folder

step FS-1.1 AUTO "Create fld-agentic-platform" --needs "ORG_ID" --sets "FLD_AGENTIC_PLATFORM"
s_FS_1_1_check() { has_value ORG_ID || return 1; fs09_folders_check FS-1.1 "$(fs09_list_1_1)"; }
s_FS_1_1_apply() {
  local out
  fs09_folders_apply FS-1.1 "$(fs09_list_1_1)" || return 1
  [ "$AGP_MODE" = apply ] || return 0
  out="$(r gcloud resource-manager folders describe "$(v FLD_AGENTIC_PLATFORM)" --format="value(displayName,parent,lifecycleState,state)")" || return 1
  echo "$out"
  case "$out" in *ACTIVE*) return 0;; *) echo "FAIL: fld-agentic-platform is not ACTIVE"; return 1;; esac
}

step FS-1.2 AUTO "Time-bound grants on fld-agentic-platform" \
  --needs "FLD_AGENTIC_PLATFORM SA_1_ADMIN BOOTSTRAP_EXCEPTION_EXPIRY BUILD_LOG_DIR EVIDENCE_REGISTER" --gate "SD-01"
fs09_folder_probe_perms() { echo "observability.settings.get observability.settings.update logging.settings.get essentialcontacts.contacts.create essentialcontacts.contacts.list resourcemanager.hierarchyNodes.createTagBinding"; }
s_FS_1_2_check() {
  local rec todo rc
  ckpt_done FS-8.1 && return 0   # the sitting is closed: its grants were removed on purpose, never re-made
  has_value FLD_AGENTIC_PLATFORM && has_value SA_1_ADMIN || return 1
  rec="$(fs09_latest "$(_penv_get BUILD_LOG_DIR)/records/*-FS-1.2-folder-permissions-before-v1.json")"
  todo="$(fs09_grants_todo folder "$(v FLD_AGENTIC_PLATFORM)" "$rec" observability.editor essentialcontacts.admin logging.configWriter)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  [ -z "$todo" ]
}
s_FS_1_2_apply() {
  local url before todo gu role fld rc desc
  fld="$(v FLD_AGENTIC_PLATFORM)"
  url="https://cloudresourcemanager.googleapis.com/v3/folders/$fld:testIamPermissions"
  before="$(fs09_rec FS-1.2 folder-permissions-before json)"
  FS09_DROPPED=""
  # shellcheck disable=SC2046
  fs09_probe "$url" "$before" $(fs09_folder_probe_perms) || return 1
  if [ "$AGP_MODE" = apply ]; then
    todo="$(fs09_grants_todo folder "$fld" "$before" observability.editor essentialcontacts.admin logging.configWriter)" || return 1
  else
    todo="observability.editor essentialcontacts.admin logging.configWriter"
  fi
  [ -n "$todo" ] || { agp_say "      the probe echoed every permission: no grant needed"; return 0; }
  if [ "$AGP_MODE" = apply ]; then
    gu="$(fs09_grant_until_live)" || { gu="$(fs09_grant_until)" && printf '%s\n' "$gu" | xw "$(fs09_rec FS-1.2 grant-until)"; } || return 1
  else
    gu="<GRANT_UNTIL of FS-0.5, or 12 hours from now>"
  fi
  for role in $todo; do
    case "$role" in logging.configWriter) desc="09 FS-1.2 SD-01 bootstrap describe only";; *) desc="09 FS-1.2 SD-01 bootstrap";; esac
    x gcloud resource-manager folders add-iam-policy-binding "$fld" --member="user:$(v SA_1_ADMIN)" --role="$(fs09_role_id "$role")" \
      --condition="expression=request.time < timestamp(\"$gu\"),title=$(fs09_role_title "$role"),description=$desc" || return 1
  done
  [ "$AGP_MODE" = apply ] || return 0
  # shellcheck disable=SC2046
  fs09_wait_perms "$url" "$(fs09_rec FS-1.2 folder-permissions-after json)" $(fs09_folder_probe_perms) || return 1
  if [ -n "$FS09_DROPPED" ]; then
    echo "Dropped as invalid for a folder:$FS09_DROPPED. Proving each read directly:"
    r gcloud observability settings describe --location=global --folder="$fld" || return 1
    r gcloud essential-contacts list --folder="$fld" || return 1
    r gcloud logging settings describe --folder="$fld"; rc=$?
    [ $rc -eq 0 ] || { echo "FAIL: a permission error above means the matching grant did not take"; return 1; }
  fi
  ev FS-1.2 folder-permissions - "4.1.3 4.2.1" "BUILD_LOG_DIR/records/$(basename "$before")" "$before"
}

# ======================================================================== FS-2 observability location

step FS-2.1 AUTO "Set the observability default storage location to europe-west1" \
  --needs "FLD_AGENTIC_PLATFORM REGION BUILD_LOG_DIR EVIDENCE_REGISTER" --gate "SD-17"
fs09_obs_value() {  # the folder's observability defaultStorageLocation (the page's VERIFY read)
  r gcloud observability settings describe --location=global --folder="$(v FLD_AGENTIC_PLATFORM)" --format="value(defaultStorageLocation)"
}
s_FS_2_1_check() {
  local out rc err
  has_value FLD_AGENTIC_PLATFORM && has_value REGION || return 1
  err="$(mktemp "${TMPDIR:-/tmp}/fs09-err.XXXXXX")" || return 2
  out="$(fs09_obs_value 2>"$err")"; rc=$?
  if [ $rc -ne 0 ] && [ $rc -ne 3 ]; then
    if grep -qiE 'NOT_FOUND|not found' "$err"; then rc=1; else sed 's/^/        /' "$err" >&3; rc=2; fi
  fi
  rm -f "$err"
  [ $rc -eq 0 ] || return $rc
  [ "$out" = "$(v REGION)" ] && return 0
  # The update ran and its describe is recorded: done. The value itself is the VERIFY, which FS-2.2,
  # the next step, repeats and stops on, before any project can exist.
  if fs09_latest "$(_penv_get BUILD_LOG_DIR)/records/*-FS-2.1-observability-default-v1.txt" >/dev/null; then
    agp_say "      FS-2.1: updated and recorded, but the folder reads '$out', not $(v REGION): FS-2.2 stops on it"
    return 0
  fi
  return 1
}
s_FS_2_1_apply() {
  local fld projs f out rc
  fld="$(v FLD_AGENTIC_PLATFORM)"
  fs09_plan_show "gcloud projects list --filter=\"parent.type=folder AND parent.id=$fld\" --format=\"value(projectId)\"   (must print nothing, or the step stops)"
  # The precondition read decides whether the step may run at all: it is the step's own check, so it
  # runs in the check context, as phases 10, 15 and 42 do (gcloud ignores it; the offline fakes read it).
  projs="$(AGP_CALL_CONTEXT=check r gcloud projects list --filter="parent.type=folder AND parent.id=$fld" --format="value(projectId)")"; rc=$?
  if [ "$AGP_MODE" = apply ]; then
    [ $rc -eq 0 ] || { echo "FAIL: the project list under fld-agentic-platform could not be read"; return 1; }
    if [ -n "$projs" ]; then
      echo "STOP: projects already exist under fld-agentic-platform: $projs"
      echo "      They keep their system-chosen location; 03 records them as a dated exception in 08 R9."
      return 1
    fi
  fi
  x gcloud observability settings update --default-storage-location="$(v REGION)" --update-mask=defaultStorageLocation --location=global --folder="$fld" || {
    echo "If gcloud refused for a quota project or a disabled service, do not pass --billing-project with a project picked on the spot: raise a decision in 03 (setup/09 FS-2.1)."
    return 1; }
  [ "$AGP_MODE" = apply ] || return 0
  f="$(fs09_rec FS-2.1 observability-default)"
  r gcloud observability settings describe --location=global --folder="$fld" | xw "$f" || return 1
  cat "$f"
  ev FS-2.1 observability-default E-05 "7.1.2 5.2.4" "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
  out="$(fs09_obs_value)"
  echo "defaultStorageLocation: ${out:-(empty: read the full YAML above)} (must be $(v REGION); FS-2.2 stops otherwise)"
  return 0
}

step FS-2.2 AUTO-READ "Leave the Cloud Logging folder default unset, and prove it" \
  --needs "FLD_AGENTIC_PLATFORM SA_1_ADMIN REGION BUILD_LOG_DIR EVIDENCE_REGISTER" --gate "SD-17"
s_FS_2_2_check() { ckpt_done FS-2.2; }
s_FS_2_2_apply() {
  local fld out f
  fld="$(v FLD_AGENTIC_PLATFORM)"
  if [ "$AGP_MODE" != apply ]; then
    fs09_plan_show "gcloud observability settings describe --location=global --folder=$fld --format=\"value(defaultStorageLocation)\"   (FS-2.1's VERIFY: $(v REGION))"
    fs09_plan_show "gcloud resource-manager folders get-iam-policy $fld (the fs-bootstrap-logconfig binding of FS-1.2)"
    fs09_plan_show "gcloud logging settings describe --folder=$fld   (a read only: this file never runs logging settings update)"
    return 0
  fi
  out="$(fs09_obs_value)" || { echo "FAIL: the observability settings of the folder could not be read"; return 1; }
  if [ "$out" != "$(v REGION)" ]; then   # FS-2.1's VERIFY, repeated here so the file stops before any project exists
    echo "STOP: FS-2.1's observability default reads '${out:-(empty)}', not $(v REGION). Read the full YAML of FS-2.1's record; no project may be created."
    return 1
  fi
  echo "FS-2.1 holds: the observability default storage location is $out"
  echo "PRECONDITION, the live grant of FS-1.2 (role and condition):"
  r gcloud resource-manager folders get-iam-policy "$fld" --flatten="bindings[].members" --filter="bindings.members:user:$(v SA_1_ADMIN) AND bindings.condition.title:fs-bootstrap-logconfig" --format="value(bindings.role,bindings.condition.expression)"
  out="$(r gcloud logging settings describe --folder="$fld" --format=json)" || {
    echo "FAIL: the read was refused. If FS-1.2's fs-bootstrap-logconfig grant has expired, re-grant it as FS-1.2 does with a fresh GRANT_UNTIL, then run this step again."
    return 1; }
  f="$(fs09_rec FS-2.2 logging-default-unset)"
  printf '%s\n' "$out" | xw "$f" || return 1
  printf '%s\n' "$out"
  ev FS-2.2 logging-default-unset E-06 5.2.4 "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
  printf '%s' "$out" | python3 -c '
import json, sys
t = sys.stdin.read(); p = json.loads(t) if t.strip() else {}
s = p.get("storageLocation", ""); k = p.get("kmsKeyName", "")
print("storageLocation:", s or "(none)", " kmsKeyName:", k or "(none)")
if s not in ("", "global") or k:
    print("STOP: someone set the folder default; restore the organisation value or global through a decision record")
    sys.exit(1)'
}

# ======================================================================== FS-3 the tree

step FS-3.1 AUTO "Create the eight second-level folders" --needs "FLD_AGENTIC_PLATFORM" \
  --sets "FLD_PLATFORM_CORE FLD_GEMINI_ENTERPRISE FLD_AGENTS_R FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_X FLD_CONTROLLERS FLD_IMPROVERS"
s_FS_3_1_check() { fs09_folders_check FS-3.1 "$(fs09_list_3_1)"; }
s_FS_3_1_apply() {
  fs09_folders_apply FS-3.1 "$(fs09_list_3_1)" || return 1
  [ "$AGP_MODE" = apply ] || return 0
  r gcloud resource-manager folders list --folder="$(v FLD_AGENTIC_PLATFORM)" --format="value(displayName)" | sort
  return 0
}

step FS-3.2 AUTO "Create the eleven third-level folders" \
  --needs "FLD_AGENTS_R FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS FLD_IMPROVERS" \
  --sets "FLD_AGENTS_R_PROD FLD_AGENTS_R_NONPROD FLD_AGENTS_W_PROD FLD_AGENTS_W_NONPROD FLD_AGENTS_P_PROD FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA FLD_CONTROLLERS_PROD FLD_CONTROLLERS_NONPROD FLD_IMPROVERS_PROD FLD_IMPROVERS_NONPROD"
s_FS_3_2_check() { fs09_folders_check FS-3.2 "$(fs09_list_3_2)"; }
s_FS_3_2_apply() { fs09_folders_apply FS-3.2 "$(fs09_list_3_2)"; }

step FS-3.3 AUTO "Create the two fourth-level folders" --needs "FLD_AGENTS_P_SA" \
  --sets "FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD"
s_FS_3_3_check() { fs09_folders_check FS-3.3 "$(fs09_list_3_3)"; }
s_FS_3_3_apply() { fs09_folders_apply FS-3.3 "$(fs09_list_3_3)"; }

step FS-3.4 AUTO-READ "Diff the live tree against the expected tree" \
  --needs "ORG_ID BUILD_LOG_DIR EVIDENCE_REGISTER $FS09_ALL_FLD"
s_FS_3_4_check() { ckpt_done FS-3.4; }
s_FS_3_4_apply() {
  local f tmp rc var
  f="$(fs09_rec FS-3.4 tree-diff)"
  if [ "$AGP_MODE" != apply ]; then fs09_plan_show "python3 - $(v ORG_ID)   (setup/09 FS-3.4 zero-diff check, reads only) > $f"; return 0; fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/fs09-tree.XXXXXX")" || return 1
  python3 - "$(v ORG_ID)" > "$tmp" 2>&1 <<'PY'
import json, os, subprocess, sys
org = sys.argv[1]
expected = [  # display name, parent display name, variable
 ("fld-agentic-platform","ORG","FLD_AGENTIC_PLATFORM"),
 ("fld-platform-core","fld-agentic-platform","FLD_PLATFORM_CORE"),("fld-gemini-enterprise","fld-agentic-platform","FLD_GEMINI_ENTERPRISE"),
 ("fld-agents-r","fld-agentic-platform","FLD_AGENTS_R"),("fld-agents-r-prod","fld-agents-r","FLD_AGENTS_R_PROD"),("fld-agents-r-nonprod","fld-agents-r","FLD_AGENTS_R_NONPROD"),
 ("fld-agents-w","fld-agentic-platform","FLD_AGENTS_W"),("fld-agents-w-prod","fld-agents-w","FLD_AGENTS_W_PROD"),("fld-agents-w-nonprod","fld-agents-w","FLD_AGENTS_W_NONPROD"),
 ("fld-agents-p","fld-agentic-platform","FLD_AGENTS_P"),("fld-agents-p-prod","fld-agents-p","FLD_AGENTS_P_PROD"),("fld-agents-p-nonprod","fld-agents-p","FLD_AGENTS_P_NONPROD"),
 ("fld-agents-p-sa","fld-agents-p","FLD_AGENTS_P_SA"),("fld-agents-p-sa-prod","fld-agents-p-sa","FLD_AGENTS_P_SA_PROD"),("fld-agents-p-sa-nonprod","fld-agents-p-sa","FLD_AGENTS_P_SA_NONPROD"),
 ("fld-agents-x","fld-agentic-platform","FLD_AGENTS_X"),
 ("fld-controllers","fld-agentic-platform","FLD_CONTROLLERS"),("fld-controllers-prod","fld-controllers","FLD_CONTROLLERS_PROD"),("fld-controllers-nonprod","fld-controllers","FLD_CONTROLLERS_NONPROD"),
 ("fld-improvers","fld-agentic-platform","FLD_IMPROVERS"),("fld-improvers-prod","fld-improvers","FLD_IMPROVERS_PROD"),("fld-improvers-nonprod","fld-improvers","FLD_IMPROVERS_NONPROD")]
def run(*a): return json.loads(subprocess.run(["gcloud",*a,"--format=json"],check=True,capture_output=True,text=True).stdout or "[]")
root = os.environ["FLD_AGENTIC_PLATFORM"]
live, queue, seen = {"fld-agentic-platform": (root, "ORG")}, [(root, "fld-agentic-platform")], {root}
while queue:
    fid, fname = queue.pop()
    for f in run("resource-manager","folders","list",f"--folder={fid}"):
        cid = f["name"].split("/")[-1]; live[f["displayName"]] = (cid, fname)
        if cid not in seen:  # a folder is walked once
            seen.add(cid); queue.append((cid, f["displayName"]))
bad = 0
for name, parent, var in expected:
    got = live.get(name)
    if not got or got[1] != parent or os.environ.get(var) != got[0]:
        print("DIFF", name, "expected parent", parent, "var", var, os.environ.get(var), "live", got); bad += 1
extra = set(live) - {e[0] for e in expected}
for x in sorted(extra): print("EXTRA", x, live[x]); bad += 1
top = [f for f in run("resource-manager","folders","list",f"--organization={org}") if f["displayName"]=="fld-agentic-platform"]
if len(top) != 1 or top[0]["name"].split("/")[-1] != root: print("DIFF root under organisation", top); bad += 1
ids = [v[0] for v in live.values()]
projects = run("projects","list",f"--filter=parent.type=folder AND parent.id:({' '.join(ids)})")
for p in projects: print("PROJECT IN TREE", p["projectId"]); bad += 1
print("zero diff: 22 folders, 0 projects" if bad == 0 else f"FAIL: {bad} differences"); sys.exit(1 if bad else 0)
PY
  rc=$?
  for var in $FS09_ALL_FLD; do   # mkfld's own refusal of an id that is not all digits (FS-1.1 to FS-3.3)
    case "$(_penv_get "$var")" in ''|*[!0-9]*) echo "DIFF $var='$(_penv_get "$var")' is not a numeric folder id" >> "$tmp"; rc=1;; esac
  done
  cat "$tmp"
  xw "$f" < "$tmp" || { rm -f "$tmp"; return 1; }
  rm -f "$tmp"
  ev FS-3.4 tree-diff E-05 "1.3.1 1.5.1" "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
  [ $rc -eq 0 ] || echo "Any DIFF, EXTRA or PROJECT IN TREE line stops the file until it is repaired and this step runs clean."
  return $rc
}

# ======================================================================== FS-4 folders.yaml

step FS-4.1 AUTO "Generate register/folders.yaml" --needs "ORG_ID PLATFORM_REPO_DIR $FS09_ALL_FLD"
s_FS_4_1_check() {
  local y
  has_value PLATFORM_REPO_DIR || return 1
  y="$(v PLATFORM_REPO_DIR)/register/folders.yaml"
  [ -f "$y" ] || return 1
  # The page's two counts. The ids are counted when non-empty: an `id: ""` from an unset variable is
  # what the second count exists for, and FS-3.4 has already refused any id that is not all digits.
  [ "$(grep -c 'variable: FLD_' "$y")" = 22 ] && [ "$(grep -cE 'id: "[^"]+"$' "$y")" = 22 ]
}
s_FS_4_1_apply() {
  local prd y b cur
  prd="$(v PLATFORM_REPO_DIR)"; y="$prd/register/folders.yaml"; b="folders-$(date +%Y%m%d)"
  x mkdir -p "$prd/register" || return 1
  cur="$(git -C "$prd" branch --show-current 2>/dev/null)"
  if [ "$cur" != "$b" ]; then
    if git -C "$prd" show-ref --verify "refs/heads/$b" >/dev/null 2>&1; then x git -C "$prd" switch "$b" || return 1
    else x git -C "$prd" switch -c "$b" || return 1; fi
  fi
  if [ "$AGP_MODE" != apply ]; then
    printf '      would write %s (22 folders, generated from ~/.platform-env by the page'"'"'s python)\n' "$y" >&3
    return 0
  fi
  python3 - <<'PY' | xw "$y" || return 1
import os, datetime as d
rows = ["AGENTIC_PLATFORM:fld-agentic-platform:","PLATFORM_CORE:fld-platform-core:AGENTIC_PLATFORM","GEMINI_ENTERPRISE:fld-gemini-enterprise:AGENTIC_PLATFORM",
 "AGENTS_R:fld-agents-r:AGENTIC_PLATFORM","AGENTS_R_PROD:fld-agents-r-prod:AGENTS_R","AGENTS_R_NONPROD:fld-agents-r-nonprod:AGENTS_R",
 "AGENTS_W:fld-agents-w:AGENTIC_PLATFORM","AGENTS_W_PROD:fld-agents-w-prod:AGENTS_W","AGENTS_W_NONPROD:fld-agents-w-nonprod:AGENTS_W",
 "AGENTS_P:fld-agents-p:AGENTIC_PLATFORM","AGENTS_P_PROD:fld-agents-p-prod:AGENTS_P","AGENTS_P_NONPROD:fld-agents-p-nonprod:AGENTS_P",
 "AGENTS_P_SA:fld-agents-p-sa:AGENTS_P","AGENTS_P_SA_PROD:fld-agents-p-sa-prod:AGENTS_P_SA","AGENTS_P_SA_NONPROD:fld-agents-p-sa-nonprod:AGENTS_P_SA",
 "AGENTS_X:fld-agents-x:AGENTIC_PLATFORM","CONTROLLERS:fld-controllers:AGENTIC_PLATFORM","CONTROLLERS_PROD:fld-controllers-prod:CONTROLLERS",
 "CONTROLLERS_NONPROD:fld-controllers-nonprod:CONTROLLERS","IMPROVERS:fld-improvers:AGENTIC_PLATFORM","IMPROVERS_PROD:fld-improvers-prod:IMPROVERS","IMPROVERS_NONPROD:fld-improvers-nonprod:IMPROVERS"]
e = os.environ
out = ["# Generated by setup 09 FS-4.1 from ~/.platform-env after FS-3.4 zero diff. Do not edit by hand.",
       f"# generated: {d.date.today().isoformat()}", "# made_by: hand (bootstrap deviation SD-01), to be superseded by the factory", "folders:"]
for r in rows:
    k, name, parent = r.split(":")
    pid = f'organizations/{e["ORG_ID"]}' if not parent else f'folders/{e["FLD_"+parent]}'
    out += [f"  - variable: FLD_{k}", f"    display_name: {name}", f"    id: \"{e['FLD_'+k]}\"", f"    parent: {pid}"]
print("\n".join(out))
PY
  echo "$(grep -c 'variable: FLD_' "$y") folders written (both counts must print 22):"
  grep -c 'variable: FLD_' "$y"
  grep -cE 'id: "[0-9]+"$' "$y" || true   # the runner re-checks the file with s_FS_4_1_check
}

step FS-4.2 HUMAN "Commit folders.yaml under review" --needs "PLATFORM_REPO_DIR"
s_FS_4_2_check() { ckpt_done FS-4.2; }
s_FS_4_2_manual() {
  echo "WHO: the platform owner commits; the reviewers named by CODEOWNERS approve (03). WHERE: the shell, then the git host."
  echo "DO: git -C \"$(v PLATFORM_REPO_DIR)\" add register/folders.yaml"
  echo "    git -C \"$(v PLATFORM_REPO_DIR)\" commit -m \"register: folders.yaml from setup 09 (22 folders, bootstrap deviation SD-01)\""
  echo "    git -C \"$(v PLATFORM_REPO_DIR)\" push -u origin HEAD; open a pull request linking the FS-3.4 output; merge under review."
  echo "    Until PLATFORM_REPO_REMOTE exists (SD-14): no push; write BUILD_LOG_DIR/reviews/<commit>.md as 03 DC-1.3 does."
  echo "VERIFY: git -C \"$(v PLATFORM_REPO_DIR)\" log --oneline -1 -- register/folders.yaml shows the commit."
  echo "RECORD: agp-platform done FS-4.2 --note \"<merge commit id, or local commit and review record>\""
}

# ======================================================================== FS-5 tags

step FS-5.1 AUTO "Create the tag keys" --needs "ORG_ID BUILD_LOG_DIR" --gate "NAMES" --irreversible \
  --sets "TAG_KEY_TIER TAG_KEY_ENV TAG_KEY_TISAX"
fs09_key_desc() {
  case "$1" in
    agp-tier) echo "Platform tier of the folder (02 3.6, P38): c r w p p-sa x ctl imp core ge";;
    agp-env) echo "Environment of the folder (02 3.6, P38): prod nonprod";;
    agp-tisax-scope) echo "TISAX scope (02 3.6, P38): in out";;
  esac
}
s_FS_5_1_check() {
  local spec var short out rc todo=""
  has_value ORG_ID || return 1
  for spec in TAG_KEY_TIER:agp-tier TAG_KEY_ENV:agp-env TAG_KEY_TISAX:agp-tisax-scope; do
    var="${spec%%:*}"; short="${spec#*:}"
    if [ "$short" = agp-env ] && ! fs09_env_signed; then continue; fi
    out="$(r gcloud resource-manager tags keys list --parent="organizations/$(v ORG_ID)" --filter="shortName=$short" --format="value(name)")"; rc=$?
    case $rc in 0) ;; 3) return 3;; *) return 2;; esac
    if [ -z "$out" ]; then
      if has_value "$var"; then agp_say "      $var is recorded but no key $short exists: stop and read the names register"; return 2; fi
      todo="$todo create:$var:$short"
    elif ! has_value "$var"; then
      todo="$todo set:$var:$short"
    fi
  done
  if ! fs09_env_signed && ! fs09_pending_recorded FS-5.4; then todo="$todo pending"; fi
  FS09_TODO_FOR=FS-5.1; FS09_TODO="$todo"
  [ -z "$todo" ]
}
s_FS_5_1_apply() {
  local todo item act var short name
  todo="$FS09_TODO"
  if [ "$FS09_TODO_FOR" != FS-5.1 ]; then
    todo="create:TAG_KEY_TIER:agp-tier create:TAG_KEY_TISAX:agp-tisax-scope"
    if fs09_env_signed; then todo="$todo create:TAG_KEY_ENV:agp-env"; else todo="$todo pending"; fi
  fi
  for item in $todo; do
    [ "$item" = pending ] && continue
    act="${item%%:*}"; var="${item#*:}"; short="${var#*:}"; var="${var%%:*}"
    if [ "$act" = create ]; then
      x gcloud resource-manager tags keys create "$short" --parent="organizations/$(v ORG_ID)" --description="$(fs09_key_desc "$short")" || return 1
    fi
    if [ "$AGP_MODE" != apply ]; then pset "$var" "<name of $(v ORG_ID)/$short>"; continue; fi
    name="$(r gcloud resource-manager tags keys describe "$(v ORG_ID)/$short" --format='value(name)')" || return 1
    # The page expects tagKeys/<digits>. An empty or multi-word answer stops here; any other shape is
    # reported, and FS-5.6 (the verification of every tag) stops on it.
    case "$name" in ''|*[[:space:]]*) agp_say "      FAIL: $short describes as '$name'"; return 1;; esac
    case "$name" in tagKeys/*[!0-9]*|tagKeys/) agp_say "      WARNING: $short describes as '$name', not tagKeys/<digits>: FS-5.6 stops on it";;
      tagKeys/*) ;; *) agp_say "      WARNING: $short describes as '$name', not tagKeys/<digits>: FS-5.6 stops on it";; esac
    pset "$var" "$name" || return 1
  done
  case " $todo " in   # the page's last block: agp-env unsigned, FS-5.4 recorded PENDING
    *" pending "*)
      if [ "$AGP_MODE" != apply ] && ! fs09_names_rec_exists; then
        agp_say "      FS-0.2 has not recorded the NAMES register yet. If its record lists agp-env, this also runs:"
        x gcloud resource-manager tags keys create agp-env --parent="organizations/$(v ORG_ID)" --description="$(fs09_key_desc agp-env)"
        pset TAG_KEY_ENV "<name of $(v ORG_ID)/agp-env>"
        agp_say "      If it does not, FS-5.4 is recorded PENDING with a line in the re-run index instead:"
      fi
      # one line in the re-run index (01 PR-2.4's columns), staged, then committed by checkpoint
      fs09_rerun_index | xw "$(v BUILD_LOG_DIR)/rerun-index.tsv" || return 1
      x git -C "$(v BUILD_LOG_DIR)" add rerun-index.tsv || return 1
      x checkpoint FS-5.4 PENDING - - "agp-env not in the signed NAMES record (FS-0.2); bind after a superseding NAMES record" || return 1;;
  esac
  [ "$AGP_MODE" = apply ] || return 0
  echo "TAG_KEY_TIER=$(_penv_get TAG_KEY_TIER) TAG_KEY_ENV=$(_penv_get TAG_KEY_ENV) TAG_KEY_TISAX=$(_penv_get TAG_KEY_TISAX)"
  return 0
}

# --irreversible: a tag value's short name is "Immutable" (TagValue REST reference, read 2026-10-01), like its key's
# (FS-5.1); the values are P38's vocabulary.
step FS-5.2 AUTO "Create the tag values" --needs "TAG_KEY_TIER TAG_KEY_TISAX BUILD_LOG_DIR" --gate "NAMES" --irreversible
fs09_values() {   # VAR:short-value lines of the values this file creates (env only once agp-env exists)
  local val
  for val in c r w p p-sa x ctl imp core ge; do echo "TAG_KEY_TIER:agp-tier:$val"; done
  # plan before FS-0.2 has read NAMES shows them, as FS-5.1 shows the key; apply creates them once agp-env exists
  if { fs09_env_signed && has_value TAG_KEY_ENV; } || { [ "$AGP_MODE" != apply ] && ! fs09_names_rec_exists; }; then
    for val in prod nonprod; do echo "TAG_KEY_ENV:agp-env:$val"; done
  fi
  for val in in out; do echo "TAG_KEY_TISAX:agp-tisax-scope:$val"; done
}
s_FS_5_2_check() {
  local item var val out rc todo=""
  for item in $(fs09_values); do
    var="${item%%:*}"; val="${item##*:}"
    if ! has_value "$var"; then todo="$todo $item"; continue; fi
    out="$(r gcloud resource-manager tags values list --parent="$(v "$var")" --filter="shortName=$val" --format="value(name)")"; rc=$?
    case $rc in 0) ;; 3) return 3;; *) return 2;; esac
    [ -n "$out" ] || todo="$todo $item"
  done
  FS09_TODO_FOR=FS-5.2; FS09_TODO="$todo"
  [ -z "$todo" ]
}
s_FS_5_2_apply() {
  local todo item var key val
  todo="$FS09_TODO"; [ "$FS09_TODO_FOR" = FS-5.2 ] || todo="$(fs09_values | tr '\n' ' ')"
  for item in $todo; do
    var="${item%%:*}"; val="${item##*:}"; key="${item#*:}"; key="${key%%:*}"
    x gcloud resource-manager tags values create "$val" --parent="$(v "$var")" --description="$key=$val" || return 1
  done
  [ "$AGP_MODE" = apply ] || return 0
  for var in TAG_KEY_TIER TAG_KEY_ENV TAG_KEY_TISAX; do
    has_value "$var" || continue
    echo "$var: $(r gcloud resource-manager tags values list --parent="$(v "$var")" --format="value(shortName)" | sort | tr '\n' ' ')"
  done
  return 0
}

step FS-5.3 AUTO "Bind agp-tier on the tier folders" \
  --needs "ORG_ID FLD_PLATFORM_CORE FLD_GEMINI_ENTERPRISE FLD_AGENTS_R FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_P_SA FLD_AGENTS_X FLD_CONTROLLERS FLD_IMPROVERS TAG_KEY_TIER"
s_FS_5_3_check() { fs09_bind_check FS-5.3 "$(fs09_list_5_3)"; }
s_FS_5_3_apply() { fs09_bind_apply FS-5.3 "$(fs09_list_5_3)"; }

step FS-5.4 AUTO "Bind agp-env on the environment folders" \
  --needs "ORG_ID FLD_AGENTS_R_PROD FLD_AGENTS_W_PROD FLD_AGENTS_P_PROD FLD_AGENTS_P_SA_PROD FLD_CONTROLLERS_PROD FLD_IMPROVERS_PROD FLD_AGENTS_R_NONPROD FLD_AGENTS_W_NONPROD FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_NONPROD FLD_IMPROVERS_NONPROD"
s_FS_5_4_check() {
  # agp-env unsigned: FS-5.1 recorded FS-5.4 PENDING (checkpoint and re-run index). The step is not
  # applicable until a superseding NAMES record signs agp-env, and gets no DONE line meanwhile.
  if ! fs09_env_signed; then
    if fs09_names_rec_exists; then
      agp_say "      FS-5.4 is PENDING: agp-env is not in the signed NAMES record (FS-0.2); nothing is bound until a superseding record signs it"
      return 5
    fi
    [ "$AGP_MODE" = apply ] || return 1   # plan before FS-0.2 has read NAMES: show the bindings
    agp_say "      FS-0.2's record of the NAMES register is missing: run FS-0.2 first"; return 2
  fi
  fs09_bind_check FS-5.4 "$(fs09_list_5_4)"
}
s_FS_5_4_apply() { fs09_bind_apply FS-5.4 "$(fs09_list_5_4)"; }

step FS-5.5 AUTO "Bind agp-tisax-scope" --needs "ORG_ID FLD_AGENTIC_PLATFORM FLD_AGENTS_X TAG_KEY_TISAX"
s_FS_5_5_check() { fs09_bind_check FS-5.5 "$(fs09_list_5_5)"; }
s_FS_5_5_apply() { fs09_bind_apply FS-5.5 "$(fs09_list_5_5)"; }

step FS-5.6 AUTO-READ "Verify the effective tags on all 22 folders" \
  --needs "ORG_ID BUILD_LOG_DIR EVIDENCE_REGISTER TAG_KEY_TIER TAG_KEY_TISAX $FS09_ALL_FLD"
s_FS_5_6_check() { ckpt_done FS-5.6; }
s_FS_5_6_apply() {
  local f tmp rc var envstate=signed
  f="$(fs09_rec FS-5.6 effective-tags)"
  fs09_env_signed || envstate=pending
  if [ "$AGP_MODE" != apply ]; then fs09_plan_show "python3 - $(v ORG_ID)   (setup/09 FS-5.6 effective tags on the 22 folders, reads only) > $f"; return 0; fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/fs09-tags.XXXXXX")" || return 1
  python3 - "$(v ORG_ID)" "$envstate" > "$tmp" 2>&1 <<'PY'
import json, os, subprocess, sys
org = sys.argv[1]
pending = sys.argv[2] == "pending"   # agp-env PENDING (FS-0.2): the twelve missing agp-env lines are the accepted DIFFs
T = {"AGENTIC_PLATFORM":(None,None,"in"),"PLATFORM_CORE":("core",None,"in"),"GEMINI_ENTERPRISE":("ge",None,"in"),
 "AGENTS_R":("r",None,"in"),"AGENTS_R_PROD":("r","prod","in"),"AGENTS_R_NONPROD":("r","nonprod","in"),
 "AGENTS_W":("w",None,"in"),"AGENTS_W_PROD":("w","prod","in"),"AGENTS_W_NONPROD":("w","nonprod","in"),
 "AGENTS_P":("p",None,"in"),"AGENTS_P_PROD":("p","prod","in"),"AGENTS_P_NONPROD":("p","nonprod","in"),
 "AGENTS_P_SA":("p-sa",None,"in"),"AGENTS_P_SA_PROD":("p-sa","prod","in"),"AGENTS_P_SA_NONPROD":("p-sa","nonprod","in"),
 "AGENTS_X":("x",None,"out"),"CONTROLLERS":("ctl",None,"in"),"CONTROLLERS_PROD":("ctl","prod","in"),"CONTROLLERS_NONPROD":("ctl","nonprod","in"),
 "IMPROVERS":("imp",None,"in"),"IMPROVERS_PROD":("imp","prod","in"),"IMPROVERS_NONPROD":("imp","nonprod","in")}
bad = 0
for k, (tier, env, tisax) in T.items():
    fid = os.environ["FLD_"+k]
    out = subprocess.run(["gcloud","resource-manager","tags","bindings","list",f"--parent=//cloudresourcemanager.googleapis.com/folders/{fid}","--effective","--format=json"],check=True,capture_output=True,text=True).stdout
    got = {t["namespacedTagKey"].split("/",1)[1]: t["namespacedTagValue"].rsplit("/",1)[1] for t in json.loads(out or "[]") if t["namespacedTagKey"].split("/")[0]==org and t["namespacedTagKey"].split("/",1)[1].startswith("agp-")}
    want = {kk: vv for kk, vv in (("agp-tier",tier),("agp-env",env),("agp-tisax-scope",tisax)) if vv}
    if pending and "agp-env" in want and "agp-env" not in got:
        print("PENDING", k, "agp-env", want.pop("agp-env"))
    if got != want: print("DIFF", k, "want", want, "got", got); bad += 1
print("tags: 22 folders match" if not bad else f"FAIL: {bad} folders differ"); sys.exit(1 if bad else 0)
PY
  rc=$?
  for var in TAG_KEY_TIER TAG_KEY_TISAX TAG_KEY_ENV; do   # FS-5.1's VERIFY: each key is tagKeys/<digits>
    [ "$var" = TAG_KEY_ENV ] && [ "$envstate" = pending ] && continue
    case "$(_penv_get "$var")" in tagKeys/*[!0-9]*|tagKeys/) ;; tagKeys/*) continue;; esac
    echo "DIFF $var='$(_penv_get "$var")' is not tagKeys/<digits>" >> "$tmp"; rc=1
  done
  cat "$tmp"
  xw "$f" < "$tmp" || { rm -f "$tmp"; return 1; }
  rm -f "$tmp"
  ev FS-5.6 effective-tags E-05 1.3.1 "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
  [ "$envstate" = signed ] || echo "agp-env is PENDING: re-run this step when FS-5.4 is done."
  return $rc
}

# ======================================================================== FS-6 Essential Contacts

# No project exists yet, so these calls run with gcloud's shared quota project (the page's FS-6.1
# Assumption, as in FS-2.1). Page 10 later passes --billing-project="$CICD_PROJECT" to the same API.
# When Google refuses, the page's stop: never a project picked on the spot, a decision in 03.
fs09_quota_hint() {
  echo "If gcloud refused for a quota project or a disabled service, do not pass --billing-project with a project picked on the spot:"
  echo "    raise a decision in 03 naming an existing project outside fld-agentic-platform as quota project for bootstrap calls (setup/09 FS-6.1, FS-2.1)."
}
step FS-6.1 AUTO "Essential Contacts at fld-agentic-platform" \
  --needs "ORG_ID DOMAIN FLD_AGENTIC_PLATFORM FLD_AGENTS_P_SA_PROD GRP_PLATFORM_SECURITY GRP_PLATFORM_OWNERS"
s_FS_6_1_check() {
  local g out rc todo=""
  has_value FLD_AGENTIC_PLATFORM || return 1
  for g in GRP_PLATFORM_SECURITY GRP_PLATFORM_OWNERS; do
    has_value "$g" || return 1
    out="$(r gcloud essential-contacts list --folder="$(v FLD_AGENTIC_PLATFORM)" --filter="email=$(v "$g") AND notificationCategorySubscriptions:SECURITY AND notificationCategorySubscriptions:TECHNICAL" --format="value(name)")"; rc=$?
    case $rc in 0) ;; 3) return 3;; *) return 2;; esac
    [ -n "$out" ] || todo="$todo $g"
  done
  FS09_TODO_FOR=FS-6.1; FS09_TODO="$todo"
  [ -z "$todo" ]
}
s_FS_6_1_apply() {
  local todo g pol fld
  fld="$(v FLD_AGENTIC_PLATFORM)"
  todo="$FS09_TODO"; [ "$FS09_TODO_FOR" = FS-6.1 ] || todo="GRP_PLATFORM_SECURITY GRP_PLATFORM_OWNERS"
  fs09_plan_show "gcloud org-policies describe essentialcontacts.managed.allowedContactDomains --organization=$(v ORG_ID) --effective   (absent, or includes $(v DOMAIN))"
  if [ "$AGP_MODE" = apply ]; then   # FS-0.3's table: the contact-domain policy is absent or includes DOMAIN
    pol="$(r gcloud org-policies describe essentialcontacts.managed.allowedContactDomains --organization="$(v ORG_ID)" --effective --format=json)" \
      || { echo "STOP: essentialcontacts.managed.allowedContactDomains could not be read; FS-6 waits for its owner's confirmation"; return 1; }
    printf '%s' "$pol" | python3 -c '
import json, sys
t = sys.stdin.read(); p = json.loads(t) if t.strip() else {}
rules = ((p.get("spec") or {}).get("rules") or [])
held = [r for r in rules if r.get("enforce") or r.get("parameters") or r.get("values")]
sys.exit(0 if not held or sys.argv[1].lower() in t.lower() else 1)' "$(v DOMAIN)" \
      || { echo "STOP: the contact-domain policy does not include $(v DOMAIN): FS-6 waits until the policy owner confirms"; return 1; }
  fi
  for g in $todo; do
    x gcloud essential-contacts create --email="$(v "$g")" --notification-categories=security,technical --language=en --folder="$fld" \
      || { fs09_quota_hint; return 1; }
  done
  [ "$AGP_MODE" = apply ] || return 0
  r gcloud essential-contacts list --folder="$fld" || { fs09_quota_hint; return 1; }
  for g in GRP_PLATFORM_SECURITY GRP_PLATFORM_OWNERS; do
    nonempty r gcloud essential-contacts compute --notification-categories=security --folder="$(v FLD_AGENTS_P_SA_PROD)" --filter="email=$(v "$g")" --format="value(email)"
    case $? in
      0) ;;
      1) echo "FAIL: $(v "$g") is not computed as a security contact of fld-agents-p-sa-prod"; return 1;;
      *) echo "FAIL: the compute read on fld-agents-p-sa-prod was refused"; fs09_quota_hint; return 1;;
    esac
    echo "inherited at fld-agents-p-sa-prod: $(v "$g")"
  done
  return 0
}

# ======================================================================== FS-7 Security Command Center

step FS-7.1 HUMAN "Confirm the payer, the residency and what residency disables" --gate "SD-15 P11" \
  --needs "SCC_BILLING_MODEL PLATFORM_REPO_DIR" --witness
s_FS_7_1_check() { ckpt_done FS-7.1; }
s_FS_7_1_manual() {
  echo "WHO: IT security (the P11 signatory) confirms; the platform owner records. WHERE: a short meeting, P11 and P94 open."
  echo "DO: confirm items 1 to 6 of setup/09 FS-7.1: the payer (SCC_BILLING_MODEL=$(v SCC_BILLING_MODEL)); the finance"
  echo "    signature and cost-centre notice, or the subscription order; residency eu (P94); the detectors residency"
  echo "    disables; the Model Armor allowance; and the path: A (IT security activates and runs FS-7.5 and FS-7.7"
  echo "    from its own account) or B (the platform owner, with a 12-hour fs-bootstrap-sccadmin grant in FS-7.3)."
  echo "    Never start FS-7.3 on a verbal answer."
  echo "RECORD: decisions/<date>-scc-activation-sitting.md in $(v PLATFORM_REPO_DIR), items 1 to 6 and the path, signed by both;"
  echo "    the scan as <date>-FS-7.1-scc-sitting-v1 with an EVIDENCE_REGISTER line; then: agp-platform done FS-7.1 --witness <IT security email>"
}

step FS-7.2 HUMAN "Read SCC's current state in the organisation" --gate "SD-15 P11" --needs "ORG_ID" --witness
s_FS_7_2_check() { ckpt_done FS-7.2; }
s_FS_7_2_manual() {
  echo "WHO: IT security, with the platform owner present."
  echo "WHERE: https://console.eu.cloud.google.com > Security Command Center, organisation $(v ORG_ID),"
  echo "    Settings > Tier details (Tier, Billing status), then Settings > Setup details (residency, encryption)."
  echo "BRANCH (setup/09 FS-7.2 table): not activated: FS-7.3. Standard, Standard-legacy, automatic Standard in global,"
  echo "    or Premium not in eu: FS-7.4 (residency to eu first, then Premium). Premium in eu: straight to FS-7.5."
  echo "    Enterprise, or project-level activations only: stop and open a decision in 03."
  echo "RECORD: screenshots <date>-FS-7.2-scc-before-v1; then: agp-platform done FS-7.2 --witness <IT security email> --note \"branch FS-7.3|FS-7.4|FS-7.5\""
  echo "    The branch not taken (FS-7.3 or FS-7.4) is recorded with: agp-platform done <id> --witness <email> --note \"branch not taken\""
}

step FS-7.3 CONSOLE "Activate SCC Premium with eu data residency (branch: not activated)" --gate "SD-15 P11" \
  --needs "ORG_ID SA_1_ADMIN BOOTSTRAP_EXCEPTION_EXPIRY" --witness --irreversible
s_FS_7_3_check() { ckpt_done FS-7.3; }
s_FS_7_3_manual() {
  echo "IRREVERSIBLE in effect: residency choice, service agents with organisation roles, charges. One performs, the other witnesses."
  echo "Path B only, first, in the platform owner's shell: the GRANT_UNTIL line and the roles/securitycenter.admin grant of"
  echo "    setup/09 FS-7.3 on organisation $(v ORG_ID) for user:$(v SA_1_ADMIN), title fs-bootstrap-sccadmin, 12 hours,"
  echo "    never past $(v BOOTSTRAP_EXCEPTION_EXPIRY). Path A: no grant; IT security activates from its own account."
  echo "WHERE: https://console.eu.cloud.google.com/projectselector2/security/command-center/welcome?supportedpurview=organizationId"
  echo "DO: select organisation $(v ORG_ID) > Start a Premium free trial (subscription: FS-7.1 item 2) > Show more >"
  echo "    Data residency: Enable, location European Union (eu); Data encryption: Google-managed; check eu again > Activate."
  echo "CONFIRM first: SD-15 and P11 signed; FS-7.1 signed; host console.eu.cloud.google.com; no location policy planned."
  echo "RECORD: screenshots <date>-FS-7.3-scc-activation-v1 co-signed; then: agp-platform done FS-7.3 --witness <email> --note \"path A|B\""
}

step FS-7.4 CONSOLE "Upgrade from Standard, or modify residency to eu (other branches)" --gate "SD-15 P11" \
  --needs "ORG_ID" --witness --irreversible
s_FS_7_4_check() { ckpt_done FS-7.4; }
s_FS_7_4_manual() {
  echo "IRREVERSIBLE in effect, and an organisation-wide migration. One performs, the other witnesses (path B: FS-7.3's grant)."
  echo "CONFIRM first: SD-15 and P11 signed; IT security's written approval of the window; no migration in the last 7 days."
  echo "WHERE: EU console, Security Command Center > Settings > Setup details > Manage data residency and encryption."
  echo "DO: 1. if residency is not eu: enable residency, choose eu, Google-managed keys, start the migration, type $(v ORG_ID)."
  echo "       SCC APIs return FAILED_PRECONDITION for 4 to 24 hours; finding names and mute rule ids change. Announce it."
  echo "    2. after the migration completes, and only then: Settings > Tier details, upgrade to Premium (record the button text)."
  echo "RECORD: <date>-FS-7.4-scc-residency-tier-v1; then: agp-platform done FS-7.4 --witness <email>"
}

step FS-7.5 HUMAN "Read back the tier and residency and record SCC_TIER" --gate "SD-15 P11" \
  --needs "ORG_ID SA_1_ADMIN" --sets "SCC_TIER" --witness
s_FS_7_5_check() { ckpt_done FS-7.5; }
s_FS_7_5_manual() {
  echo "WHO: console reading by the platform owner with IT security present; the shell reads by whoever holds Security Center"
  echo "    Admin (path A: IT security's own shell; path B: $(v SA_1_ADMIN) while fs-bootstrap-sccadmin is live). IT security co-signs."
  echo "WHERE: EU console, Settings > Tier details and Setup details; then the performer's shell, the block of setup/09 FS-7.5:"
  echo "    gcloud config set api_endpoint_overrides/securitycenter https://securitycenter.eu.rep.googleapis.com/"
  echo "    gcloud scc findings list \"$(v ORG_ID)\" --location=eu --limit=1 --format=\"value(finding.name)\""
  echo "    gcloud config unset api_endpoint_overrides/securitycenter"
  echo "VERIFY: Premium, billing status as FS-7.1, residency eu; findings list exits 0. PERMISSION_DENIED is not a reading."
  echo "RECORD, only when both readings agree: penv_set SCC_TIER \"PREMIUM/eu\" (typed by the person);"
  echo "    screenshots <date>-FS-7.5-scc-after-v1 signed by both; then: agp-platform done FS-7.5 --witness <email>"
}

step FS-7.6 AUTO-READ "Record the SCC service agents and their roles" --needs "ORG_ID BUILD_LOG_DIR EVIDENCE_REGISTER"
s_FS_7_6_check() { ckpt_done FS-7.6; }
s_FS_7_6_apply() {
  local org f out cross n
  org="$(v ORG_ID)"; f="$(fs09_rec FS-7.6 scc-service-agents)"
  if [ "$AGP_MODE" != apply ]; then
    fs09_plan_show "gcloud organizations get-iam-policy $org --flatten=bindings[].members --filter=bindings.role:serviceAgent --format=table(bindings.role,bindings.members) > $f"
    return 0
  fi
  out="$(r gcloud organizations get-iam-policy "$org" --flatten="bindings[].members" --filter="bindings.role:serviceAgent" --format="table(bindings.role,bindings.members)")" || return 1
  cross="$(r gcloud organizations get-iam-policy "$org" --flatten="bindings[].members" --filter="bindings.members:service-org-${org}@security-center-api.iam.gserviceaccount.com" --format="value(bindings.role)")" || true
  { printf '%s\n' "$out"
    echo "# address cross-check, service-org-${org}@security-center-api.iam.gserviceaccount.com (an assumption; empty is not a finding):"
    printf '%s\n' "${cross:-(nothing)}"; } | xw "$f" || return 1
  cat "$f"
  ev FS-7.6 scc-service-agents E-05 "4.1.3 4.2.1" "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
  if [ -z "$out" ]; then
    echo "FAIL: no service-agent binding at all. Check FS-0.3's iam.allowedPolicyMemberDomains record with IT security."
    return 1
  fi
  n="$(printf '%s\n' "$out" | grep -oE 'service-org-[0-9]+@[a-z0-9.-]+' | sort -u | grep -c .)"
  echo "$n organisation service agents hold a serviceAgent role. Match the four of activation by name (Cloud Security Command Center,"
  echo "Cloud Security Compliance, Container Threat Detection, Data Security Posture Management), write their addresses and roles"
  echo "into the record for 13 and 25, and raise any missing one with IT security against FS-7.7's read before closing FS-7."
}

step FS-7.7 HUMAN "Record the enabled services and the residency detector diff" --gate "SD-15 P11" \
  --needs "ORG_ID BUILD_LOG_DIR" --witness
s_FS_7_7_check() { ckpt_done FS-7.7; }
s_FS_7_7_manual() {
  echo "WHO: the performer of FS-7.1 item 6, holding Security Center Admin (path A: IT security's own shell; path B: the"
  echo "    platform owner while fs-bootstrap-sccadmin is live). IT security is present for the diff either way."
  echo "DO: gcloud scc manage services list --organization=\"organizations/$(v ORG_ID)\" --format=yaml > \"$(v BUILD_LOG_DIR)/FS-7.7-scc-services.yaml\""
  echo "    grep -E \"name:|EnablementState\" \"$(v BUILD_LOG_DIR)/FS-7.7-scc-services.yaml\""
  echo "    Check each name against Google's activate-Premium page on the day (ten services on 2026-09-15), not against a count;"
  echo "    write the differences and every detector residency disables (FS-7.1 item 4) into the disabled-detector list for 15."
  echo "RECORD: <date>-FS-7.7-scc-detector-diff-v1; then: agp-platform done FS-7.7 --witness <email>"
}

step FS-7.8 AUTO-READ "Re-run point: the SCC SKU query on the billing export" --needs "LOGGING_PROJECT BILLING_EXPORT_DS BUILD_LOG_DIR" \
  --on-unmet skip --note "re-run point: after setup/14 CL-9.4, agp-platform apply --phase 09 --from FS-7.8 --to FS-7.8"
fs09_7_8_wait_say() {   # what an operator does while the billing export has no table yet
  agp_say "      FS-7.8 has not run: it needs the first gcp_billing_export_v1_* table in $(v LOGGING_PROJECT):$(v BILLING_EXPORT_DS)"
  agp_say "      (setup/14 CL-9.3 turns the export on; the first export day lands after it). Until then: agp-platform apply --phase 14,"
  agp_say "      or agp-platform apply --all --from FS-8.1. After setup/14 CL-9.4: agp-platform apply --phase 09 --from FS-7.8 --to FS-7.8"
}
s_FS_7_8_check() {
  local out rc
  ckpt_done FS-7.8 && return 0
  # Not done until the query has run and its result is recorded. Before the first export table
  # exists there is nothing to query: say so. The step is never marked DONE without having run.
  out="$(r bq ls --project_id="$(v LOGGING_PROJECT)" "$(v LOGGING_PROJECT):$(v BILLING_EXPORT_DS)" 2>/dev/null)"; rc=$?
  [ $rc -eq 3 ] && return 3
  case "$out" in *gcp_billing_export_v1_*) ;; *) agp_say "      FS-7.8: no gcp_billing_export_v1_* table in $(v LOGGING_PROJECT):$(v BILLING_EXPORT_DS) yet (re-run point, setup/14)";; esac
  return 1
}
s_FS_7_8_apply() {
  local lp ds f out
  lp="$(v LOGGING_PROJECT)"; ds="$(v BILLING_EXPORT_DS)"; f="$(fs09_rec FS-7.8 scc-sku-query)"
  if [ "$AGP_MODE" != apply ]; then fs09_plan_show "bq query --project_id=$lp --use_legacy_sql=false '<the SCC SKU query of setup/09 FS-7.8>'"; return 0; fi
  # The result is captured first, so a failed query (no export table yet) leaves no record and no DONE line.
  out="$(r bq query --project_id="$lp" --use_legacy_sql=false 'SELECT invoice.month AS month, project.id AS project, sku.description AS sku, ROUND(SUM(cost),2) AS cost, currency FROM `'"$lp.$ds"'.gcp_billing_export_v1_*` WHERE service.description = "Security Command Center" GROUP BY month, project, sku, currency ORDER BY month DESC')" \
    || { agp_say "      the query failed (read the error above)"; fs09_7_8_wait_say; return 1; }
  printf '%s\n' "$out" | xw "$f" || return 1
  cat "$f"
  echo "Rows appear once SCC charges start. An empty result after the first charged month is a finding to IT security."
}

# ======================================================================== FS-8 close

step FS-8.1 AUTO "Remove every time-bound grant" --needs "ORG_ID SA_1_ADMIN FLD_AGENTIC_PLATFORM BUILD_LOG_DIR EVIDENCE_REGISTER" --removes
fs09_grants_scan() {  # the page's FS-8.1 policy read, as lines: ACTION<TAB>kind<TAB>rid<TAB>role<TAB>condition-or-note
  [ "$AGP_OFFLINE" = 1 ] && return 3
  python3 - "$(v ORG_ID)" "$(v FLD_AGENTIC_PLATFORM)" "user:$(v SA_1_ADMIN)" <<'PY'
import json, subprocess, sys
org, fld, member = sys.argv[1], sys.argv[2], sys.argv[3]
targets = [("org", org, ["roles/resourcemanager.tagAdmin","roles/resourcemanager.tagUser","roles/securitycenter.admin"]),
           ("folder", fld, ["roles/observability.editor","roles/essentialcontacts.admin","roles/logging.configWriter"])]
def get(kind, rid):
    cmd = ["gcloud","organizations","get-iam-policy",rid] if kind=="org" else ["gcloud","resource-manager","folders","get-iam-policy",rid]
    out = subprocess.run(cmd+["--format=json"],check=True,capture_output=True,text=True).stdout
    return json.loads(out) if out.strip() else {}
for kind, rid, roles in targets:
    pol = get(kind, rid)
    for b in pol.get("bindings", []):
        role, cond = b.get("role"), b.get("condition")
        title = (cond or {}).get("title", "")
        mine = member in b.get("members", [])
        if role in roles and mine:
            if not cond:
                print("FAIL\t%s\t%s\t%s\t-" % (kind, rid, role)); continue
            if not title.startswith("fs-bootstrap"):
                print("SKIP\t%s\t%s\t%s\t%s" % (kind, rid, role, title)); continue
            print("REMOVE\t%s\t%s\t%s\t%s" % (kind, rid, role, json.dumps({k: cond[k] for k in ("title","description","expression") if k in cond})))
        elif title.startswith("fs-bootstrap") and (kind == "org" or mine):
            print("LEFT\t%s\t%s\t%s\t%s" % (kind, rid, role, title))
PY
}
s_FS_8_1_check() {
  local out rc
  has_value ORG_ID && has_value FLD_AGENTIC_PLATFORM && has_value SA_1_ADMIN || return 1
  out="$(fs09_grants_scan)"; rc=$?
  case $rc in 0) ;; 3) return 3;; *) return 2;; esac
  # SKIP lines (another condition on one of these roles) are reported, never removed: they do not keep the step open
  ! printf '%s\n' "$out" | grep -qE '^(REMOVE|FAIL|LEFT)'
}
s_FS_8_1_apply() {
  local out act kind rid role cond tmp bad=0 left=0 member f
  member="user:$(v SA_1_ADMIN)"
  if [ "$AGP_OFFLINE" = 1 ]; then
    fs09_plan_show "read both policies; for each fs-bootstrap-* binding of $member: gcloud ... remove-iam-policy-binding --condition-from-file=<its exact condition> (never --all)"
    return 0
  fi
  out="$(fs09_grants_scan)" || { echo "FAIL: the policies could not be read"; return 1; }
  while IFS="$(printf '\t')" read -r act kind rid role cond <&4; do
    case "$act" in
      REMOVE)
        tmp="$(mktemp "${TMPDIR:-/tmp}/fs-cond.XXXXXX")" || return 1
        printf '%s\n' "$cond" | xw "$tmp" || { rm -f "$tmp"; return 1; }
        agp_say "      removing $kind $rid $role ($(printf '%s' "$cond" | python3 -c 'import json,sys; print(json.load(sys.stdin)["title"])'))"
        if [ "$kind" = org ]; then
          x gcloud organizations remove-iam-policy-binding "$rid" --member="$member" --role="$role" --condition-from-file="$tmp" || { rm -f "$tmp"; return 1; }
        else
          x gcloud resource-manager folders remove-iam-policy-binding "$rid" --member="$member" --role="$role" --condition-from-file="$tmp" || { rm -f "$tmp"; return 1; }
        fi
        rm -f "$tmp";;
      FAIL) agp_say "      FAIL unconditional binding, not removed: $kind $rid $role (a standing grant from 06; 12 withdraws it)"; bad=$((bad + 1));;
      SKIP) agp_say "      SKIP other condition, not removed: $kind $rid $role $cond (report it to IT security)";;
      LEFT) agp_say "      LEFT: $kind $rid $role carries $cond but is not one of this file's roles: read setup/09 FS-8.1"; left=$((left + 1));;
    esac
  done 4<<EOF
$out
EOF
  [ "$AGP_MODE" = apply ] || return 0
  if [ $bad -eq 0 ]; then echo "FS-8.1: nothing removed unconditionally"; else echo "FAIL: $bad unconditional binding(s) found"; fi
  echo "Remaining fs-bootstrap bindings (both reads must print nothing):"
  r gcloud organizations get-iam-policy "$(v ORG_ID)" --flatten="bindings[].members" --filter="bindings.condition.title:fs-bootstrap" --format="value(bindings.role,bindings.condition.title)"
  r gcloud resource-manager folders get-iam-policy "$(v FLD_AGENTIC_PLATFORM)" --flatten="bindings[].members" --filter="bindings.members:$member AND bindings.condition.title:fs-bootstrap" --format="value(bindings.role,bindings.condition.title)"
  f="$(fs09_rec FS-8.1 folder-holdings)"
  r gcloud resource-manager folders get-iam-policy "$(v FLD_AGENTIC_PLATFORM)" --flatten="bindings[].members" --filter="bindings.members:$member" --format="value(bindings.role,bindings.condition.title)" | xw "$f" || return 1
  echo "What $(v SA_1_ADMIN) still holds on fld-agentic-platform (for 12):"; cat "$f"
  ev FS-8.1 folder-holdings - "4.1.3 4.2.1" "BUILD_LOG_DIR/records/$(basename "$f")" "$f"
  [ $bad -eq 0 ] && [ $left -eq 0 ]
}

step FS-8.2 AUTO "Write the bootstrap deviation register rows" \
  --needs "DEVIATION_REGISTER BUILD_LOG_DIR FLD_AGENTIC_PLATFORM BOOTSTRAP_EXCEPTION_EXPIRY ORG_ID PLATFORM_REPO_DIR"
s_FS_8_2_check() {
  local reg
  has_value DEVIATION_REGISTER || return 1
  reg="$(v DEVIATION_REGISTER)"; [ -f "$reg" ] || return 1
  awk -F' *[|] *' '$2 == "BD-09-1" && NF == 15 {f=1} END {exit f ? 0 : 1}' "$reg" \
    && awk -F' *[|] *' '$2 == "BD-09-2" && NF == 15 {f=1} END {exit f ? 0 : 1}' "$reg" \
    && awk -F' *[|] *' '$2 == "BD-09-2" && NF == 6 {f=1} END {exit f ? 0 : 1}' "$reg"
}
s_FS_8_2_apply() {
  local d commit envtxt nvals nbind tree tags removed bld row1 row2
  d="$(date -u +%Y-%m-%d)"; bld="$(v BUILD_LOG_DIR)"
  if [ "$AGP_MODE" = apply ]; then
    commit="$(git -C "$(v PLATFORM_REPO_DIR)" log --all -1 --format=%h -- register/folders.yaml 2>/dev/null)"
    if [ -z "$commit" ]; then   # merged on the git host from another clone: the id the person gave FS-4.2's done
      commit="$(awk -F'\t' '$2 == "FS-4.2" && $3 == "DONE" {n=$7} END {print n}' "$bld/checkpoints.tsv" 2>/dev/null | tr '|<>' '/()')"
      [ -z "$commit" ] || commit="as recorded at FS-4.2: $commit"
    fi
    [ -n "$commit" ] || { echo "FAIL: no commit of register/folders.yaml, and no FS-4.2 DONE line naming one"; return 1; }
    tree="$(fs09_latest "$bld/records/*-FS-3.4-tree-diff-v1.txt")" || { echo "FAIL: no FS-3.4 record"; return 1; }
    tags="$(fs09_latest "$bld/records/*-FS-5.6-effective-tags-v1.txt")" || { echo "FAIL: no FS-5.6 record"; return 1; }
    tree="$(basename "$tree")"; tags="$(basename "$tags")"
    removed="$(awk -F'\t' '$2 == "FS-8.1" && $3 == "DONE" {t=substr($1,1,10)} END {print t}' "$bld/checkpoints.tsv" 2>/dev/null)"
    [ -n "$removed" ] || removed="$d"
  else
    commit="<folders.yaml commit>"; tree="<date>-FS-3.4-tree-diff-v1.txt"; tags="<date>-FS-5.6-effective-tags-v1.txt"; removed="<date of FS-8.1>"
  fi
  if fs09_env_signed; then envtxt="agp-env"; nvals=14; nbind=23
  elif [ "$AGP_MODE" != apply ] && ! fs09_names_rec_exists; then envtxt="agp-env <or agp-env PENDING, per FS-0.2>"; nvals="<14 or 12>"; nbind="<23 or 11>"
  else envtxt="agp-env PENDING"; nvals=12; nbind=11; fi
  row1="$(printf '| BD-09-1 | %s | 09 FS-1.1 to FS-6.1 | MOD | platform-core: folder tree, tags, Essential Contacts, observability default (02 2.1, 3.6, 3.7; SD-17) | organisation %s; folder %s and descendants | 02 2.1 tree; P38 vocabulary; NAMES record; folders.yaml commit %s | 22 folders; tag keys agp-tier, agp-tisax-scope, %s; %s values; %s bindings; 2 contacts; observability default europe-west1; Logging folder default unset; labels, APIs, policies and grants none (folders carry no labels; policies 13; grants 10 and 12) | BUILD_LOG_DIR/records/%s; %s; FS-2.1 and FS-2.2 describes | n/a (no project) | none: SD-01 one-person bootstrap, reviewed at 42 | superseded by terraform import and an empty plan when the factory exists (B-01); Tier W gate at the latest | open |' \
    "$d" "$(v ORG_ID)" "$(v FLD_AGENTIC_PLATFORM)" "$commit" "$envtxt" "$nvals" "$nbind" "$tree" "$tags")"
  row2="$(printf '| BD-09-2 | %s | 09 FS-0.5, FS-1.2, FS-7.3 | DEV | time-bound self-grants through Organization Administrator instead of PAM (no entitlement before 12) | organisation %s; folder %s | FS-0.4 and FS-1.2 probes | tagAdmin, tagUser (organisation); observability.editor, essentialcontacts.admin, logging.configWriter for describe only (folder); securitycenter.admin (organisation, path B only, 12 hours to cover FS-7.3 to FS-7.7, re-granted under the same condition title if the window lapsed); each with an fs-bootstrap-* condition of at most 12 hours | FS-8.1 removal by condition title, with no unconditional binding touched, and the two empty get-iam-policy outputs | n/a | none: SD-01; FS-7.3 witnessed by IT security | removed %s; within BOOTSTRAP_EXCEPTION_EXPIRY %s | closed |' \
    "$d" "$(v ORG_ID)" "$(v FLD_AGENTIC_PLATFORM)" "$removed" "$(v BOOTSTRAP_EXCEPTION_EXPIRY)")"
  x bd_insert "$row1" || return 1
  x bd_insert "$row2" || return 1
  x bd_close BD-09-2 "withdrawal: 09 FS-8.1, every fs-bootstrap-* binding removed by condition title" "09 FS-8.1 VERIFY" || return 1
}

step FS-8.3 HUMAN "Close the sitting" --needs "EVIDENCE_REGISTER"
s_FS_8_3_check() { ckpt_done FS-8.3; }
s_FS_8_3_manual() {
  echo "WHO: the platform owner. WHERE: the shell."
  echo "DO: gcloud config get api_endpoint_overrides/securitycenter   (must print nothing: the override is unset)"
  echo "    Check that every record named in setup/09's EVIDENCE lines has a row in EVIDENCE_REGISTER; add any missing one"
  echo "    with evidence_add. The sitting then ends; the next file signs in again."
  echo "RECORD: agp-platform done FS-8.3; then: agp-platform sitting end   (sitting_end must print SITTING-END OK)"
}
