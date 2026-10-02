# phases/10-core-projects-and-ci-identities.sh: setup/10, the five core projects, the CI supply-chain
# base and the platform's machine identities. Registers CP-0.1 to CP-8.3 in the page's order.
#
# How §1 runs. The page runs CP-1.1 to CP-1.12 as one pass per row of its §1 table. The runner runs
# one step at a time, so each CP-1.x step here loops over the five rows, in row order, and stops at
# the first row that fails. The dependencies the page's order protects still hold: row 1
# (CICD_PROJECT) is the first row of every step, so it is linked, enabled and logged before CP-1.9
# and CP-1.10 use it as the quota project. Each row a run completes gets the page's per-row
# checkpoint (CP-1.7@LOGGING_PROJECT DONE), and CP-1.12 writes `CP-1 DONE` after row 5.
#
# Where the ids come from. The five project ids and TF_STATE_BUCKET are values of the signed NAMES
# record (setup/03 DC-5.1), read with 03's tools/decision-value.sh, as the page does. CP-0.1 prints
# and checks all six; CP-1.1 reads each id from the record (cp10_id) until CP-1.2 writes it with
# `penv_set "$P_VAR" "$P_ID"`; CP-2.1 reads the bucket name from the record and writes
# TF_STATE_BUCKET. Nothing is typed by hand before the phase. A value written earlier by hand is
# kept only when it equals the signed one (penv_set refuses a different value).
#
# Prompts. gcloud asks before some commands (the package delete of CP-3.5). The runner shows gcloud's
# messages only after a command ends, so the step prints what to answer before such a command.

phase 10 "Core projects and CI identities" "10-core-projects-and-ci-identities.md"
requires org "resourcemanager.projects.create resourcemanager.projects.list resourcemanager.folders.get resourcemanager.folders.list"
# Billing permissions: sa-1-admin@ holds billing roles only between 07 BA-2.2 (granted) and BA-7.1
# (removed), so they are declared for that window only, as 07 does; outside it preflight would refuse
# every apply of this phase, a resume at CP-8 included. Reading the checkpoints at load time changes nothing.
if ckpt_done BA-2.2 && ! ckpt_done BA-7.1; then
  requires billing "billing.accounts.get billing.resourceAssociations.create billing.resourceAssociations.list billing.budgets.create billing.budgets.list"
fi

CP10_ROWS="CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT"
CP10_NUMBERS="CICD_PROJECT_NUMBER CORE_PROJECT_NUMBER LOGGING_PROJECT_NUMBER KMS_PROJECT_NUMBER VALIDATOR_PROJECT_NUMBER"
CP10_TISAX_CATS="TECHNICAL,TECHNICAL_INCIDENTS,SUSPENSION,SECURITY"
CP10_LOG_FILTER='NOT LOG_ID("cloudaudit.googleapis.com/activity") AND NOT LOG_ID("externalaudit.googleapis.com/activity") AND NOT LOG_ID("cloudaudit.googleapis.com/system_event") AND NOT LOG_ID("externalaudit.googleapis.com/system_event") AND NOT LOG_ID("cloudaudit.googleapis.com/access_transparency") AND NOT LOG_ID("externalaudit.googleapis.com/access_transparency")'

# ---------------------------------------------------------------- helpers of this phase

cp10_row() {    # cp10_row VAR: the row of the page's §1 table (display name, purpose, labels, APIs, _Trace)
  CP10_TRACE=yes
  case "$1" in
    CICD_PROJECT) CP10_N=1; CP10_NAME="Platform CICD core prod"; CP10_PURPOSE=cicd; CP10_OWNER=platform-owners; CP10_RECOVERY=r-d
      CP10_APIS="serviceusage cloudresourcemanager iam iamcredentials sts logging monitoring storage cloudbuild artifactregistry containeranalysis containerscanning binaryauthorization cloudkms billingbudgets essentialcontacts observability";;
    CORE_PROJECT) CP10_N=2; CP10_NAME="Platform core prod"; CP10_PURPOSE=core; CP10_OWNER=platform-owners; CP10_RECOVERY=r-d
      CP10_APIS="serviceusage cloudresourcemanager iam iamcredentials logging monitoring storage bigquery pubsub run cloudscheduler binaryauthorization agentregistry apphub cloudasset policyanalyzer orgpolicy iap observability";;
    LOGGING_PROJECT) CP10_N=3; CP10_NAME="Platform logging core prod"; CP10_PURPOSE=logging; CP10_OWNER=platform-owners; CP10_RECOVERY=r-d
      CP10_APIS="serviceusage cloudresourcemanager iam logging monitoring storage bigquery pubsub dlp cloudkms observability";;
    KMS_PROJECT) CP10_N=4; CP10_NAME="Platform KMS core prod"; CP10_PURPOSE=kms; CP10_OWNER=platform-owners; CP10_RECOVERY=r-k; CP10_TRACE=no
      CP10_APIS="cloudresourcemanager cloudkms logging";;
    VALIDATOR_PROJECT) CP10_N=5; CP10_NAME="Platform validator core prod"; CP10_PURPOSE=validator; CP10_OWNER=platform-security; CP10_RECOVERY=r-d
      CP10_APIS="serviceusage cloudresourcemanager iam logging monitoring storage bigquery cloudkms observability";;
    *) return 2;;
  esac
}

cp10_id() {     # cp10_id NAME: a NAMES value (a row's project id, TF_STATE_BUCKET): the value already
  # written (CP-1.2, CP-2.1), else the signed NAMES record through decision-value.sh; else <NAME> in
  # plan mode, and MISSING-NAME with a non-zero status in apply mode
  local t sv
  if has_value "$1"; then v "$1"; return 0; fi
  t="$(agp_tool decision-value.sh)"
  if [ "$AGP_OFFLINE" != 1 ] && [ -x "$t" ] && sv="$("$t" NAMES "$1" 2>/dev/null)"; then
    case "$sv" in ''|'*tbd*'|*'<'*'>'*) ;; *) printf '%s' "$sv"; return 0;; esac
  fi
  if [ "$AGP_MODE" = apply ]; then
    printf 'MISSING-%s' "$1"
    agp_warn "$1: no signed value in the NAMES record ($t, setup/03 DC-1.2 and DC-5.1)"
    return 1
  fi
  printf '<%s>' "$1"
}

cp10_now() {    # cp10_now CMD...: inside _apply, the read that decides whether a resource (or a row's
  # resource) still has to be made. It is the step's own check of that resource, so it runs in the check
  # context, as the runner runs _check; gcloud ignores the variable, the offline fakes read it
  AGP_CALL_CONTEXT=check "$@"
}

cp10_alpha() {  # 0 the gcloud alpha component is installed, 1 it is not, 2 cannot tell, 3 offline.
  # Asked before any `gcloud alpha` command: without the component gcloud stops to offer the install,
  # and inside a read or `x` that question is not shown, so the run would wait with nothing on screen.
  local ids
  [ "$AGP_OFFLINE" = 1 ] && return 3
  ids="$(gcloud components list --only-local-state --format='value(id)' 2>/dev/null)" || return 2
  printf '%s\n' "$ids" | grep -qx alpha
}
cp10_alpha_msg() {
  case "$1" in
    1) echo "FAIL the gcloud alpha component is not installed (setup/10 precondition; CP-1.3 uses it): gcloud components install alpha";;
    2) echo "FAIL cannot tell whether the gcloud alpha component is installed (gcloud components list failed; with a package-manager install, add its alpha package)";;
  esac
}

cp10_slug() { printf '%s' "$1" | tr 'A-Z_' 'a-z-'; }                       # CICD_PROJECT -> cicd-project
cp10_re()   { printf '%s' "$1" | sed -e 's/[.]/[.]/g' -e 's/[+]/[+]/g'; }  # an address as a literal regex
cp10_plan() { [ "$AGP_MODE" = apply ] || printf '      %s\n' "$*" >&3; }     # one line of explanation in plan mode

cp10_ckpt_is() {    # cp10_ckpt_is ID STATUS: checkpoints.tsv holds that line
  [ -n "${BUILD_LOG_DIR-}" ] && [ -f "$BUILD_LOG_DIR/checkpoints.tsv" ] || return 1
  awk -F'\t' -v s="$1" -v t="$2" '$2 == s && $3 == t {f=1} END {exit f ? 0 : 1}' "$BUILD_LOG_DIR/checkpoints.tsv"
}

cp10_ckpt() {       # cp10_ckpt STEP VAR: the page's per-row checkpoint (CP-1.7@LOGGING_PROJECT DONE), once
  cp10_ckpt_is "$1@$2" DONE && return 0
  x checkpoint "$1@$2" DONE - - "agp-platform $AGP_VERSION"
}

cp10_rowdone() {    # cp10_rowdone STEP FUNC VAR: the row's end state (FUNC VAR) holds AND its per-row checkpoint is written.
  # The checkpoint is written only after the row's verification passed, so a row whose verification failed
  # after its resource was made is run again, not passed over. A row done by hand carries the same line.
  local rc
  "$2" "$3"; rc=$?
  [ $rc -eq 0 ] || return $rc
  cp10_ckpt_is "$1@$3" DONE
}

cp10_allrows() {    # cp10_allrows FUNC: 0 when FUNC VAR is 0 for every row; else the first other status
  local var rc
  for var in $CP10_ROWS; do "$1" "$var"; rc=$?; [ $rc -eq 0 ] || return $rc; done
  return 0
}

cp10_rec() {        # cp10_rec STEP SLUG E-ID TISAX CMD...: save the read's output under records/ and register it
  local step="$1" slug="$2" eid="$3" tisax="$4" f out
  shift 4
  f="$(v BUILD_LOG_DIR)/records/$(date -u +%F)-${step}-${slug}-v1.txt"
  if [ "$AGP_MODE" != apply ]; then printf '      would save %s and record its evidence\n' "${f##*/}" >&3; return 0; fi
  out="$(r "$@" 2>&1)" || { printf '%s\n' "$out"; agp_warn "$step: the read for the record $slug failed"; return 1; }
  printf '%s\n' "$out" | xw "$f" 600 || return 1
  ev "$step" "$slug" "$eid" "$tisax" "BUILD_LOG_DIR/records" "$f"
}

# Precise JSON tests on what gcloud prints with --format=json. Each prints the offending items, one per
# line, and nothing when the state is right. They select entries by an identifying field (role,
# member, email, displayName), so a test passes only on what it can name.
CP10_PY='
import json, re, sys
cmd, a = sys.argv[1], sys.argv[2:]
raw = sys.stdin.read()
try:
    d = json.loads(raw) if raw.strip() else []
except ValueError:
    print("unreadable output: " + raw[:120].replace("\n", " ")); sys.exit(0)
items = d if isinstance(d, list) else [d]
def get(o, path):
    for p in path.split("."):
        if not isinstance(o, dict) or p not in o:
            return None
        o = o[p]
    return o
def binds():
    return (d.get("bindings") or []) if isinstance(d, dict) else []
AGENT = re.compile(r"^serviceAccount:(service-[0-9]+@|service-org-[0-9]+@|[0-9]+@cloudservices[.]gserviceaccount[.]com$|[0-9]+@cloudbuild[.]gserviceaccount[.]com$)")
out = []
if cmd in ("iam-humans", "iam-snapshot"):
    owner = "user:" + a[0]
    for b in binds():
        role = b.get("role", "")
        for m in b.get("members", []):
            if role == "roles/owner" and m == owner:
                continue
            kind = m.split(":")[0]
            human = kind in ("user", "group", "domain") or m in ("allUsers", "allAuthenticatedUsers")
            other = cmd == "iam-snapshot" and (role == "roles/editor" or kind in ("principal", "principalSet", "principalHierarchy") or (kind == "serviceAccount" and not AGENT.match(m)))
            if human or other:
                out.append(role + " " + m)
elif cmd == "roles-of":
    out = [b.get("role", "") for b in binds() if a[0] in b.get("members", [])]
elif cmd == "bindings":
    out = [b.get("role", "") + " " + m for b in binds() for m in b.get("members", [])]
elif cmd == "user-keys":
    out = [str(i.get("name")) for i in items if isinstance(i, dict) and i.get("keyType") == "USER_MANAGED"]
elif cmd == "has-value":
    out = [str(get(i, a[0])) for i in items if get(i, a[0]) == a[1]]
elif cmd == "not-in":
    out = [str(get(i, a[0])) for i in items if get(i, a[0]) is not None and get(i, a[0]) not in a[1:]]
elif cmd == "projects-unexpected":
    out = [str(i.get("projectId")) for i in items if isinstance(i, dict) and str(get(i, "parent.id")) == a[0] and i.get("projectId") not in a[1:]]
elif cmd == "sa-unexpected":
    sfx = "@" + a[0] + ".iam.gserviceaccount.com"
    out = [i["email"] for i in items if isinstance(i, dict) and str(i.get("email", "")).endswith(sfx) and i["email"] not in a[1:]]
elif cmd == "buckets-unexpected":
    for i in items:
        if isinstance(i, dict) and i.get("name") and i.get("location"):
            if str(i["location"]).upper() != a[0].upper():
                out.append(i["name"] + " in " + str(i["location"]))
            elif i["name"] not in a[1:]:
                out.append(i["name"] + " (not expected)")
elif cmd == "tag-direct":
    out = [str(i.get("tagValue")) for i in items if isinstance(i, dict) and i.get("tagValue")]
elif cmd == "budget-bad":
    name, pid, num = a
    sel = [i for i in items if isinstance(i, dict) and i.get("displayName") == name]
    if len(sel) > 1:
        out.append("%d budgets named %s" % (len(sel), name))
    for i in sel:
        if len(i.get("thresholdRules") or []) != 4:
            out.append(name + ": not four threshold rules")
        prj = get(i, "budgetFilter.projects") or []
        if not prj:
            out.append(name + ": budgetFilter.projects is empty (the budget covers the whole billing account)")
        for p in prj:
            if p not in ("projects/" + pid, "projects/" + num):
                out.append(name + ": filter names " + p)
elif cmd == "provider-bad":
    prov, issuer, repo, owner = a
    for i in items:
        if isinstance(i, dict) and str(i.get("name", "")).endswith("/providers/" + prov):
            if get(i, "oidc.issuerUri") != issuer:
                out.append(prov + ": issuer " + str(get(i, "oidc.issuerUri")) + ", not " + issuer)
            cond = str(i.get("attributeCondition", ""))
            for need in ("\x27" + repo + "\x27", "\x27" + owner + "\x27"):
                if need not in cond:
                    out.append(prov + ": the condition does not name " + need)
            if "refs/heads/main" not in cond and "\x27main\x27" not in cond:
                out.append(prov + ": the condition does not pin main")
elif cmd == "contact-bad":
    want = set(a[1].split(","))
    for i in items:
        if isinstance(i, dict) and i.get("email") == a[0]:
            got = set(i.get("notificationCategorySubscriptions") or [])
            if got != want:
                out.append(a[0] + ": " + ",".join(sorted(got)))
for o in out:
    print(o)
'
cp10_json() { python3 -c "$CP10_PY" "$@"; }

cp10_none() {       # cp10_none LABEL JSONCMD [ARG...] -- CMD...: the JSON test JSONCMD finds nothing in CMD's output
  local label="$1" jc="$2" a out rc
  local ja=()
  shift 2
  while [ $# -gt 0 ] && [ "$1" != -- ]; do ja[${#ja[@]}]="$1"; shift; done
  shift
  out="$(r "$@" --format=json 2>/dev/null)"; rc=$?
  [ $rc -eq 0 ] || { echo "FAIL $label: the read failed ($rc)"; return 2; }
  a="$(printf '%s' "$out" | cp10_json "$jc" ${ja[@]+"${ja[@]}"})"
  [ -z "$a" ] && return 0
  printf 'FAIL %s:\n' "$label"; printf '%s\n' "$a" | sed 's/^/       /'
  return 1
}

cp10_owner_kept() { # cp10_owner_kept PROJECT: the creator's roles/owner is on the project (the read is live)
  nonempty r gcloud projects get-iam-policy "$1" --project="$1" --flatten="bindings[].members" \
    --filter='bindings.role~"^roles/owner$" AND bindings.members~"^user:'"$(cp10_re "$(v SA_1_ADMIN)")"'$"' \
    --format="value(bindings.members)"
}

cp10_sa_ok() {      # cp10_sa_ok EMAIL PROJECT: exists, enabled, no user-managed key, no binding on the account
  local e="$1" p="$2" bad=0
  nonempty r gcloud iam service-accounts list --project="$p" --filter='email~"^'"$(cp10_re "$e")"'$" AND disabled=false' --format="value(email)" \
    || { echo "FAIL $e: not found enabled in $p"; bad=1; }
  cp10_none "user-managed keys of $e" user-keys -- gcloud iam service-accounts keys list --iam-account="$e" --managed-by=user --project="$p" || bad=1
  return $bad
}

# ---------------------------------------------------------------- 0. The sitting

step CP-0.1 AUTO-READ "Open the sitting and check the gates" \
  --needs "PLATFORM_ENV_FILE ORG_ID REGION FLD_PLATFORM_CORE FLD_AGENTIC_PLATFORM TAG_KEY_TIER TAG_KEY_TISAX BILLING_ACCOUNT_ID BILLING_CURRENCY SA_1_ADMIN SA_2_ADMIN GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY ROSTER_FILE BOOTSTRAP_EXCEPTION_EXPIRY GIT_HOST GIT_OIDC_ISSUER PLATFORM_REPO_REMOTE PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_INTERIM_LOCATION EVIDENCE_REGISTER DEVIATION_REGISTER SECOND_HUMAN_EMAIL BILLING_ADMIN_EMAIL" \
  --gate "NAMES SD-01 SD-14 SD-16 SD-17 SD-18 SD-34 P22"
s_CP_0_1_check() { ckpt_done CP-0.1; }
s_CP_0_1_apply() {
  cp10_plan "reads: penv_guard (no default project); the gcloud alpha component; the six NAMES values with decision-value.sh (printed; any value"
  cp10_plan "already in the variables file must equal them); well-formed, distinct project ids; the active account is SA_1_ADMIN;"
  cp10_plan "the exception has not expired; fld-platform-core under fld-agentic-platform; no project under it other than the"
  cp10_plan "five core ids; saves the folder describe as a record"
  [ "$AGP_MODE" = apply ] || return 0
  local bad=0 n sv ids=" " tool fld acct rc
  tool="$(agp_tool decision-value.sh)"
  penv_guard || { echo "FAIL penv_guard"; bad=1; }
  cp10_alpha; rc=$?; [ $rc -eq 0 ] || { cp10_alpha_msg $rc; bad=1; }
  if [ -x "$tool" ]; then
    for n in $CP10_ROWS TF_STATE_BUCKET; do
      sv="$("$tool" NAMES "$n" 2>/dev/null)" || { echo "FAIL no signed value for $n in the NAMES record"; bad=1; continue; }
      case "$sv" in ''|'*tbd*'|*'<'*'>'*) echo "FAIL $n is empty, *tbd* or a placeholder in the NAMES record"; bad=1; continue;; esac
      echo "$n=$sv"
      if has_value "$n" && [ "$sv" != "$(v "$n")" ]; then
        echo "FAIL $n is '$(v "$n")' in the variables file, '$sv' in the signed NAMES record (CP-1.2 ROLLBACK: penv_set --force with a build-log line)"; bad=1
      fi
      [ "$n" = TF_STATE_BUCKET ] && continue
      case "$sv" in *[!a-z0-9-]*|[!a-z]*|*-) echo "FAIL $n=$sv: lowercase letters, digits and hyphens, starting with a letter, not ending with a hyphen"; bad=1;; esac
      [ ${#sv} -ge 6 ] && [ ${#sv} -le 30 ] || { echo "FAIL $n=$sv: 6 to 30 characters"; bad=1; }
      case "$ids" in *" $sv "*) echo "FAIL $n=$sv: the same id as another core project"; bad=1;; esac
      ids="$ids$sv "
      case "$sv" in agp-core-*) ;; *) echo "REVIEW $n=$sv is not of the form agp-core-<purpose> (02 3.6): right only under the NAMES record's fallback rule";; esac
    done
  else
    echo "FAIL $tool is not installed (setup/03 DC-1.2): the six NAMES values cannot be read"; bad=1
  fi
  [ -f "$(v PLATFORM_ENV_FILE)" ] || { echo "FAIL PLATFORM_ENV_FILE does not point at a file"; bad=1; }
  acct="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)"
  [ "$acct" = "$(v SA_1_ADMIN)" ] || { echo "FAIL signed in as '$acct', not SA_1_ADMIN"; bad=1; }
  [[ "$(date -u +%F)" < "$(v BOOTSTRAP_EXCEPTION_EXPIRY)" ]] || { echo "FAIL the bootstrap exception expired on $(v BOOTSTRAP_EXCEPTION_EXPIRY)"; bad=1; }
  [ "$(v BILLING_ADMIN_EMAIL)" != "$(v SA_1_ADMIN)" ] || { echo "FAIL the billing administrator is sa-1-admin@"; bad=1; }
  fld="$(v FLD_PLATFORM_CORE)"
  nonempty r gcloud resource-manager folders list --folder="$(v FLD_AGENTIC_PLATFORM)" \
    --filter='name~"^folders/'"$fld"'$" AND displayName~"^fld-platform-core$"' --format="value(name)" \
    || { echo "FAIL folders/$fld is not fld-platform-core under fld-agentic-platform"; bad=1; }
  # shellcheck disable=SC2086
  cp10_none "projects under fld-platform-core that are not core projects" projects-unexpected "$fld" $ids -- \
    gcloud projects list --filter="parent.type=folder AND parent.id=${fld}" || bad=1
  [ $bad = 0 ] || return 1
  cp10_rec CP-0.1 folder-core-describe - 1.3.1 gcloud resource-manager folders describe "$fld" --format="value(displayName,parent)"
}

# ---------------------------------------------------------------- 1. The platform-core shape, per row

step CP-1.1 AUTO "Create the project under fld-platform-core" --irreversible \
  --needs "FLD_PLATFORM_CORE BUILD_LOG_DIR PLATFORM_REPO_DIR" --gate "NAMES SD-01"
cp10_1_1_row() {
  local id rc
  id="$(cp10_id "$1")"; rc=$?
  [ $rc -eq 0 ] || return 2
  nonempty r gcloud projects list --filter="projectId=${id} AND parent.type=folder AND parent.id=$(v FLD_PLATFORM_CORE)" --format="value(projectId)"
}
cp10_1_1_done() { cp10_rowdone CP-1.1 cp10_1_1_row "$1"; }
s_CP_1_1_check() { cp10_allrows cp10_1_1_done; }
s_CP_1_1_apply() {
  local var id rc
  for var in $CP10_ROWS; do
    cp10_row "$var"; id="$(cp10_id "$var")" || return 1
    cp10_1_1_done "$var" && continue
    cp10_now cp10_1_1_row "$var"; rc=$?
    if [ $rc -ne 0 ]; then
      cp10_now exists gcloud projects describe "$id" --project="$id" --format="value(projectId)"; rc=$?
      case $rc in
        0) echo "FAIL $id already exists outside fld-platform-core: never delete it; move it (ROLLBACK of CP-1.1)"; return 1;;
        1|3) ;;
        *) return 1;;
      esac
      x gcloud projects create "$id" --folder="$(v FLD_PLATFORM_CORE)" --name="$CP10_NAME" --no-enable-cloud-apis \
        --labels="agent=platform-${CP10_PURPOSE},owner=${CP10_OWNER},tier=core,env=prod,data_class=confidential,ai_act_class=not-ai-system,recovery_class=${CP10_RECOVERY},cost_centre=tbd,created_by=bootstrap-hand,factory_run=dev-10-${CP10_PURPOSE}" \
        || { echo "If the refusal names a label key, nothing was created: change the six underscore keys to hyphens for all five rows under a dated 02 3.6 amendment (CP-1.1)"; return 1; }
    fi
    cp10_rec CP-1.1 "$(cp10_slug "$var")-describe" E-05 1.3.1 gcloud projects describe "$id" --project="$id" --format="yaml(projectId,projectNumber,name,parent,labels,lifecycleState)" || return 1
    cp10_ckpt CP-1.1 "$var" || return 1
  done
}

step CP-1.2 AUTO "Record the id and number" \
  --needs "PLATFORM_REPO_DIR" --sets "$CP10_ROWS $CP10_NUMBERS" --gate "NAMES"
cp10_1_2_row() { has_value "$1" && has_value "${1}_NUMBER"; }
s_CP_1_2_check() { cp10_allrows cp10_1_2_row; }
s_CP_1_2_apply() {
  local var id num
  for var in $CP10_ROWS; do
    cp10_1_2_row "$var" && continue
    id="$(cp10_id "$var")" || return 1
    num="$(r gcloud projects describe "$id" --project="$id" --format='value(projectNumber)')"
    if [ "$AGP_MODE" = apply ]; then
      case "$num" in ''|*[!0-9]*) echo "FAIL ${var}: projectNumber '$num' is not a number"; return 1;; esac
    fi
    pset "$var" "$id" || return 1
    pset "${var}_NUMBER" "${num:-<projectNumber>}" || return 1
    cp10_ckpt CP-1.2 "$var" || return 1
  done
}

step CP-1.3 AUTO "Place a deletion lien" --needs "CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT"
cp10_1_3_row() { nonempty r gcloud alpha resource-manager liens list --project="$(v "$1")" --filter='origin~"^setup-10-core-projects$"' --format="value(name)"; }
cp10_1_3_done() { cp10_rowdone CP-1.3 cp10_1_3_row "$1"; }
s_CP_1_3_check() {  # no `gcloud alpha` call before the component is known to be there (it would wait unseen)
  local rc
  cp10_alpha; rc=$?
  case $rc in 0) ;; 3) return 3;; *) cp10_alpha_msg $rc; return 2;; esac
  cp10_allrows cp10_1_3_done
}
s_CP_1_3_apply() {
  local var id rc
  cp10_alpha; rc=$?
  case $rc in 0|3) ;; *) cp10_alpha_msg $rc; return 1;; esac
  for var in $CP10_ROWS; do
    cp10_1_3_done "$var" && continue
    id="$(v "$var")"
    cp10_now cp10_1_3_row "$var" || x gcloud alpha resource-manager liens create --project="$id" --restrictions=resourcemanager.projects.delete \
      --reason="Core platform project; deletion only by a signed decision (10, SD-01)" --origin="setup-10-core-projects" || return 1
    cp10_rec CP-1.3 "$(cp10_slug "$var")-lien" - "1.3.1, 5.3" gcloud alpha resource-manager liens list --project="$id" --format="table(name,restrictions,origin)" || return 1
    cp10_ckpt CP-1.3 "$var" || return 1
  done
}

step CP-1.4 AUTO "Link billing (the linking test on row 1)" \
  --needs "BILLING_ACCOUNT_ID CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT" --gate "SD-16"
cp10_1_4_row() { nonempty r gcloud billing projects list --billing-account="$(v BILLING_ACCOUNT_ID)" --filter='projectId~"^'"$(v "$1")"'$" AND billingEnabled=true' --format="value(projectId)"; }
cp10_1_4_done() { cp10_rowdone CP-1.4 cp10_1_4_row "$1"; }
s_CP_1_4_check() { cp10_allrows cp10_1_4_done; }
s_CP_1_4_apply() {
  local var id
  for var in $CP10_ROWS; do
    cp10_1_4_done "$var" && continue
    id="$(v "$var")"
    if ! cp10_now cp10_1_4_row "$var" && ! x gcloud billing projects link "$id" --billing-account="$(v BILLING_ACCOUNT_ID)"; then
      echo "Refused. On row 1 this is 07's linking test: a permission error on the billing account means the billing administrator"
      echo "adds roles/billing.viewer for sa-1-admin@ and writes the SD-16 note of 07 BA-2.2, then re-run. A refusal naming a project"
      echo "quota means 07 BA-6's request is not granted yet: stop every pass until it is."
      return 1
    fi
    cp10_rec CP-1.4 "$(cp10_slug "$var")-billing" - 1.3.3 gcloud billing projects describe "$id" --project="$id" --format="value(billingAccountName,billingEnabled)" || return 1
    cp10_ckpt CP-1.4 "$var" || return 1
  done
}

step CP-1.5 AUTO-READ "Confirm the inherited tags" \
  --needs "TAG_KEY_TIER TAG_KEY_TISAX CICD_PROJECT_NUMBER CORE_PROJECT_NUMBER LOGGING_PROJECT_NUMBER KMS_PROJECT_NUMBER VALIDATOR_PROJECT_NUMBER"
s_CP_1_5_check() { ckpt_done CP-1.5; }
cp10_tags_both() {  # the effective and the direct tag bindings of one project, for the record
  gcloud resource-manager tags bindings list --parent="//cloudresourcemanager.googleapis.com/projects/$1" --effective --format=yaml
  echo "--- bound directly on the project (must be empty):"
  gcloud resource-manager tags bindings list --parent="//cloudresourcemanager.googleapis.com/projects/$1" --format=yaml
}
s_CP_1_5_apply() {
  cp10_plan "reads, per project: an inherited agp-tier=core and agp-tisax-scope=in, and no tag bound on the project itself"
  [ "$AGP_MODE" = apply ] || return 0
  local var num parent bad=0
  for var in $CP10_ROWS; do
    num="$(v "${var}_NUMBER")"; parent="//cloudresourcemanager.googleapis.com/projects/${num}"
    nonempty r gcloud resource-manager tags bindings list --parent="$parent" --effective \
      --filter='tagKey~"^'"$(v TAG_KEY_TIER)"'$" AND namespacedTagValue~"/agp-tier/core$"' --format="value(namespacedTagValue)" \
      || { echo "FAIL $var: no inherited agp-tier=core (09 binds it on fld-platform-core; fix it there)"; bad=1; }
    nonempty r gcloud resource-manager tags bindings list --parent="$parent" --effective \
      --filter='tagKey~"^'"$(v TAG_KEY_TISAX)"'$" AND namespacedTagValue~"/agp-tisax-scope/in$"' --format="value(namespacedTagValue)" \
      || { echo "FAIL $var: no inherited agp-tisax-scope=in (09 binds it on fld-agentic-platform; fix it there)"; bad=1; }
    cp10_none "$var: tags bound directly on the project" tag-direct -- gcloud resource-manager tags bindings list --parent="$parent" || bad=1
    [ $bad = 0 ] || return 1
    cp10_rec CP-1.5 "$(cp10_slug "$var")-tags" - 1.3.2 cp10_tags_both "$num" || return 1
    cp10_ckpt CP-1.5 "$var" || return 1
  done
}

step CP-1.6 AUTO "Enable the row's APIs, and nothing else" --needs "CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT"
cp10_1_6_row() {    # every service of the row is enabled (each one is read, so the result names all that are missing)
  local s id rc worst=0
  cp10_row "$1"; id="$(v "$1")"
  for s in $CP10_APIS; do
    nonempty r gcloud services list --enabled --project="$id" --filter='config.name~"^'"$s"'[.]googleapis[.]com$"' --format="value(config.name)"; rc=$?
    case "$rc:$worst" in 0:*) ;; 2:*) worst=2;; 3:0|3:1) worst=3;; 1:0) worst=1;; esac
  done
  return $worst
}
cp10_1_6_done() { cp10_rowdone CP-1.6 cp10_1_6_row "$1"; }
s_CP_1_6_check() { cp10_allrows cp10_1_6_done; }
s_CP_1_6_apply() {
  local var id s wanted extra
  for var in $CP10_ROWS; do
    cp10_1_6_done "$var" && continue
    local have=0; cp10_now cp10_1_6_row "$var" && have=1
    cp10_row "$var"; id="$(v "$var")"; wanted=""
    for s in $CP10_APIS; do
      wanted="$wanted ${s}.googleapis.com"
      if [ $have = 0 ] && ! x gcloud services enable "${s}.googleapis.com" --project="$id"; then
        [ "$var:$s" = KMS_PROJECT:cloudresourcemanager ] && echo "Console route: APIs & Services > Enabled APIs & services > + Enable APIs and services > Cloud Resource Manager API > Enable, project $id; record it in BD-10-7"
        return 1
      fi
    done
    [ "$AGP_MODE" = apply ] || continue
    cp10_none "$var: compute.googleapis.com is enabled; do not disable it as a reflex: find its parent service and decide with the second human (CP-1.6, BD-10-7)" \
      has-value config.name compute.googleapis.com -- gcloud services list --enabled --project="$id" || return 1
    # shellcheck disable=SC2086
    extra="$(r gcloud services list --enabled --project="$id" --format=json 2>/dev/null | cp10_json not-in config.name $wanted)"
    [ -z "$extra" ] || { echo "REVIEW $var: enabled beyond the row; classify each in the record as (a) on 02 4.2's core allow-list or (b) a dependency with a named parent, for 13; any other is disabled without --force first (CP-1.6):"; printf '%s\n' "$extra" | sed 's/^/       /'; }
    cp10_rec CP-1.6 "$(cp10_slug "$var")-services" - "5.2.1, 1.3.1" gcloud services list --enabled --project="$id" --format="value(config.name)" --sort-by=config.name || return 1
    cp10_ckpt CP-1.6 "$var" || return 1
  done
  cp10_plan "after each project's enables: compute.googleapis.com must be off (if on, stop: decide with the second human); any other"
  cp10_plan "extra service is printed for classification, never disabled by the script; the enabled list is saved; CP-1.6@<VAR> DONE"
}

step CP-1.7 AUTO "Route _Default to a regional bucket; leave _Required global" --irreversible \
  --needs "REGION CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT" --gate "SD-17"
cp10_1_7_bucket() { exists gcloud logging buckets describe default-europe-west1 --location="$(v REGION)" --project="$(v "$1")" --format="value(name)"; }
cp10_1_7_sink() {
  nonempty r gcloud logging sinks list --project="$(v "$1")" \
    --filter='name="_Default" AND destination~"^logging[.]googleapis[.]com/projects/'"$(v "$1")"'/locations/'"$(v REGION)"'/buckets/default-europe-west1$"' --format="value(name)"
}
cp10_1_7_row() { local rc; cp10_1_7_bucket "$1"; rc=$?; [ $rc -eq 0 ] || return $rc; cp10_1_7_sink "$1"; }
cp10_1_7_done() { cp10_rowdone CP-1.7 cp10_1_7_row "$1"; }
s_CP_1_7_check() { cp10_allrows cp10_1_7_done; }
cp10_logs_read() { gcloud logging read 'logName:"cp-1-7-routing-test"' --project="$1" --bucket=default-europe-west1 --location="$2" --view=_AllLogs --freshness=10m --format="value(textPayload)"; }
cp10_routing_record() {
  gcloud logging buckets describe default-europe-west1 --location="$2" --project="$1" --format="yaml(name,retentionDays,lifecycleState)"
  gcloud logging sinks describe _Default --project="$1" --format="yaml(destination,filter)"
  gcloud logging sinks describe _Required --project="$1" --format="value(destination)"
  cp10_logs_read "$1" "$2"
}
s_CP_1_7_apply() {
  local var id reg rc n
  reg="$(v REGION)"
  for var in $CP10_ROWS; do
    cp10_1_7_done "$var" && continue
    id="$(v "$var")"
    cp10_now cp10_1_7_bucket "$var"; rc=$?
    case $rc in
      0) ;;
      1|3) x gcloud logging buckets create default-europe-west1 --location="$reg" --retention-days=30 \
             --description="Regional destination of the _Default sink (SD-17, file 10)" --project="$id" || return 1;;
      *) return 1;;
    esac
    cp10_now cp10_1_7_sink "$var" || x gcloud logging sinks update _Default "logging.googleapis.com/projects/${id}/locations/${reg}/buckets/default-europe-west1" \
      --log-filter="$CP10_LOG_FILTER" --description="Updated the _Default sink to route logs to the europe-west1 region" --project="$id" || return 1
    if [ "$AGP_MODE" != apply ]; then
      cp10_plan "reads: default-europe-west1 ACTIVE with 30 days; _Required still ends locations/global/buckets/_Required"
      x gcloud logging write cp-1-7-routing-test "CP-1.7 routing test ${var}" --project="$id"
      cp10_plan "then the entry is read back from default-europe-west1 (view _AllLogs, up to five minutes); record; CP-1.7@${var} DONE"
      continue
    fi
    nonempty r gcloud logging buckets list --location="$reg" --project="$id" \
      --filter='name~"/buckets/default-europe-west1$" AND retentionDays=30 AND lifecycleState=ACTIVE' --format="value(name)" \
      || { echo "FAIL $var: default-europe-west1 is not ACTIVE with 30 days"; return 1; }
    nonempty r gcloud logging sinks list --project="$id" --filter='name="_Required" AND destination~"/locations/global/buckets/_Required$"' --format="value(name)" \
      || { echo "FAIL $var: _Required no longer ends in locations/global/buckets/_Required"; return 1; }
    x gcloud logging write cp-1-7-routing-test "CP-1.7 routing test ${var}" --project="$id" || return 1
    n=0
    until nonempty r cp10_logs_read "$id" "$reg"; do
      n=$((n + 1))
      [ $n -lt 10 ] || { echo "FAIL $var: the test entry did not reach default-europe-west1 within five minutes. If the read's flags are refused, read it in Logging > Logs Explorer > Refine scope > Log view (default-europe-west1 / _AllLogs), save it as a screenshot and write: checkpoint CP-1.7@${var} DONE - - \"routing read in the console\""; return 1; }
      sleep 30
    done
    cp10_rec CP-1.7 "$(cp10_slug "$var")-log-routing" E-06 "5.2.4, 7.1" cp10_routing_record "$id" "$reg" || return 1
    cp10_ckpt CP-1.7 "$var" || return 1
  done
}

step CP-1.8 AUTO "Create the _Trace bucket in europe-west1 (rows 1, 2, 3 and 5)" --irreversible \
  --needs "REGION BUILD_LOG_DIR CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT" --gate "SD-17"
cp10_1_8_row() {
  cp10_row "$1"
  if [ "$CP10_TRACE" = no ]; then cp10_ckpt_is "CP-1.8@$1" N/A; return; fi
  nonempty r gcloud observability buckets list --location="$(v REGION)" --project="$(v "$1")" --filter='name~"/buckets/_Trace$"' --format="value(name)"
}
cp10_trace_wait() {   # cp10_trace_wait ROW PROJECT RESPONSE: waits for the create's long-running operation, then for the bucket
  local var="$1" id="$2" resp="$3" op n=0
  op="$(printf '%s' "$resp" | jget name 2>/dev/null)" || op=""
  case "$op" in
    */operations/*)
      until [ "$(printf '%s' "$resp" | jget 'done' 2>/dev/null)" = true ]; do
        n=$((n + 1))
        [ $n -le 30 ] || { echo "FAIL $var: the operation $op was not done within five minutes; read it again with api GET https://observability.googleapis.com/v1/$op, then rerun"; return 1; }
        sleep 10
        resp="$(AGP_API_PROJECT="$id" api GET "https://observability.googleapis.com/v1/$op")" \
          || { echo "FAIL $var: the operation $op could not be read"; return 1; }
      done
      if printf '%s' "$resp" | jget error >/dev/null 2>&1; then
        echo "FAIL $var: the operation $op ended with an error: $(printf '%s' "$resp" | jget error.message 2>/dev/null)"
        return 1
      fi;;
  esac
  n=0
  until cp10_1_8_row "$var"; do
    n=$((n + 1))
    [ $n -le 12 ] || { echo "FAIL $var: _Trace is still not listed in $(v REGION) two minutes after the create"; return 1; }
    sleep 10
  done
}
cp10_1_8_done() { cp10_row "$1"; [ "$CP10_TRACE" = no ] && { cp10_1_8_row "$1"; return; }; cp10_rowdone CP-1.8 cp10_1_8_row "$1"; }
s_CP_1_8_check() { cp10_allrows cp10_1_8_done; }
s_CP_1_8_apply() {
  local var id reg body
  reg="$(v REGION)"
  [ "$AGP_MODE" != apply ] || [ "$reg" = europe-west1 ] || { echo "FAIL REGION is '$reg', not europe-west1: an observability bucket's location cannot be changed"; return 1; }
  for var in $CP10_ROWS; do
    cp10_1_8_done "$var" && continue
    cp10_row "$var"; id="$(v "$var")"
    if [ "$CP10_TRACE" = no ]; then
      x checkpoint "CP-1.8@$var" N/A - - "no _Trace in the key project: nothing there emits spans (10 section 1)" || return 1
      continue
    fi
    if ! cp10_now cp10_1_8_row "$var" && ! x gcloud observability buckets create _Trace --location="$reg" --project="$id"; then
      echo "gcloud refused the create; trying the documented REST call (projects.locations.buckets.create), as CP-1.8 allows"
      body="$(mktemp "${TMPDIR:-/tmp}/cp10-trace.XXXXXX")" || return 1
      printf '{}' > "$body"
      local rc resp
      resp="$(AGP_API_PROJECT="$id" api POST "https://observability.googleapis.com/v1/projects/${id}/locations/${reg}/buckets?bucketId=_Trace" "$body")"
      rc=$?; rm -f "$body"
      if [ $rc -ne 0 ]; then
        echo "FAIL $var: _Trace not created. If a _Trace already exists, list it without --location filtering: one outside europe-west1 is a residency deviation for 13 and 42, recorded in CP-8.2"
        return 1
      fi
      cp10_trace_wait "$var" "$id" "$resp" || return 1
      echo "CP-1.8 $var: created through the REST fallback (recorded in the run log)"
    fi
    cp10_rec CP-1.8 "$(cp10_slug "$var")-trace-bucket" - 7.1 gcloud observability buckets list --location="$reg" --project="$id" || return 1
    cp10_ckpt CP-1.8 "$var" || return 1
  done
}

step CP-1.9 AUTO "Create the project budget" \
  --needs "BILLING_ACCOUNT_ID BILLING_CURRENCY CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT $CP10_NUMBERS" --gate "SD-16"
cp10_1_9_row() {
  nonempty r gcloud billing budgets list --billing-account="$(v BILLING_ACCOUNT_ID)" --billing-project="$(v CICD_PROJECT)" \
    --filter='displayName~"^'"$(v "$1")"'-budget$"' --format="value(name)"
}
cp10_1_9_done() { cp10_rowdone CP-1.9 cp10_1_9_row "$1"; }
s_CP_1_9_check() { cp10_allrows cp10_1_9_done; }
s_CP_1_9_apply() {
  local var id ba
  ba="$(v BILLING_ACCOUNT_ID)"
  if [ "$AGP_MODE" = apply ]; then   # the page's currency test, as a filtered read of that one account
    local rc
    nonempty r gcloud billing accounts list --filter="name=billingAccounts/${ba} AND currencyCode=$(v BILLING_CURRENCY)" --format="value(name)"; rc=$?
    case $rc in
      0) ;;
      1) echo "STOP the billing account's currency is not $(v BILLING_CURRENCY) (the page: currency changed: stop)."
         echo "  A person must act first: an amount in another currency needs a signed SD-16 amendment (02 section 2.2), then BILLING_CURRENCY as 07 BA-1.3 records it."
         return 98;;
      *) echo "FAIL could not read the billing account $ba (gcloud billing accounts list)"; return 1;;
    esac
  fi
  cp10_plan "first: the billing account's currency is BILLING_CURRENCY (else stop: an amount in another currency needs SD-16)"
  for var in $CP10_ROWS; do
    cp10_1_9_done "$var" && continue
    id="$(v "$var")"
    cp10_now cp10_1_9_row "$var" || x gcloud billing budgets create --billing-account="$ba" --display-name="${id}-budget" --budget-amount=300 --filter-projects="projects/${id}" \
      --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0 --threshold-rule=percent=1.0,basis=forecasted-spend \
      --billing-project="$(v CICD_PROJECT)" || return 1
    [ "$AGP_MODE" = apply ] || { cp10_plan "then: one budget of that name, four thresholds, its filter names this project only and is not empty; record; CP-1.9@${var} DONE"; continue; }
    cp10_none "$var: the budget ${id}-budget" budget-bad "${id}-budget" "$id" "$(v "${var}_NUMBER")" -- \
      gcloud billing budgets list --billing-account="$ba" --billing-project="$(v CICD_PROJECT)" || return 1
    cp10_rec CP-1.9 "$(cp10_slug "$var")-budget" - 1.3.3 gcloud billing budgets list --billing-account="$ba" --billing-project="$(v CICD_PROJECT)" \
      --filter='displayName~"^'"$id"'-budget$"' --format="yaml(displayName,amount,budgetFilter.projects,thresholdRules)" || return 1
    cp10_ckpt CP-1.9 "$var" || return 1
  done
}

step CP-1.10 AUTO "Set Essential Contacts" \
  --needs "GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT"
cp10_contact() {    # cp10_contact PROJECT EMAIL: the contact exists
  nonempty r gcloud essential-contacts list --project="$1" --billing-project="$(v CICD_PROJECT)" --filter='email~"^'"$(cp10_re "$2")"'$"' --format="value(email)"
}
cp10_1_10_row() {
  local rc
  cp10_ckpt_is "CP-1.10@$1" N/A && return 0
  cp10_contact "$(v "$1")" "$(v GRP_PLATFORM_OWNERS)"; rc=$?; [ $rc -eq 0 ] || return $rc
  cp10_contact "$(v "$1")" "$(v GRP_PLATFORM_SECURITY)"
}
cp10_1_10_done() { cp10_ckpt_is "CP-1.10@$1" N/A && return 0; cp10_rowdone CP-1.10 cp10_1_10_row "$1"; }
s_CP_1_10_check() { cp10_allrows cp10_1_10_done; }
s_CP_1_10_apply() {
  local var id own sec cp
  own="$(v GRP_PLATFORM_OWNERS)"; sec="$(v GRP_PLATFORM_SECURITY)"; cp="$(v CICD_PROJECT)"
  for var in $CP10_ROWS; do
    cp10_1_10_done "$var" && continue
    id="$(v "$var")"
    if ! { cp10_now cp10_contact "$id" "$own" || x gcloud essential-contacts create --email="$own" --notification-categories=technical,technical-incidents,suspension,security --language=en --project="$id" --billing-project="$cp"; } \
      || ! { cp10_now cp10_contact "$id" "$sec" || x gcloud essential-contacts create --email="$sec" --notification-categories=security --language=en --project="$id" --billing-project="$cp"; }; then
      echo "If the refusal names the Essential Contacts API as disabled on $id: enable essentialcontacts.googleapis.com there (on the core allow-list) and re-run;"
      echo "on KMS_PROJECT instead leave the contacts to 09's folder contacts, record the gap for CP-8.2, and write:"
      echo "  checkpoint CP-1.10@KMS_PROJECT N/A - - \"folder contacts of 09\""
      return 1
    fi
    [ "$AGP_MODE" = apply ] || { cp10_plan "then: the categories read back exactly as created; record; CP-1.10@${var} DONE"; continue; }
    cp10_none "$var: categories of $own" contact-bad "$own" "$CP10_TISAX_CATS" -- gcloud essential-contacts list --project="$id" --billing-project="$cp" || return 1
    cp10_none "$var: categories of $sec" contact-bad "$sec" SECURITY -- gcloud essential-contacts list --project="$id" --billing-project="$cp" || return 1
    cp10_rec CP-1.10 "$(cp10_slug "$var")-contacts" - 1.6.1 gcloud essential-contacts list --project="$id" --billing-project="$cp" --format="table(email,notificationCategorySubscriptions)" || return 1
    cp10_ckpt CP-1.10 "$var" || return 1
  done
}

step CP-1.11 AUTO-READ "Snapshot IAM: the creator's Owner is kept, and nothing else is human" \
  --needs "SA_1_ADMIN CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT"
s_CP_1_11_check() { ckpt_done CP-1.11; }
s_CP_1_11_apply() {
  cp10_plan "reads, per project: the IAM policy, saved as JSON; only user:SA_1_ADMIN as roles/owner and Google service agents;"
  cp10_plan "no other user, group, domain, public, agent or user-managed service account member, no roles/editor"
  [ "$AGP_MODE" = apply ] || return 0
  local var id
  for var in $CP10_ROWS; do
    id="$(v "$var")"
    cp10_none "$var: members other than the creator's Owner and service agents (remove them, then re-run)" iam-snapshot "$(v SA_1_ADMIN)" -- \
      gcloud projects get-iam-policy "$id" --project="$id" || return 1
    cp10_owner_kept "$id" || { echo "FAIL $var: the creator's roles/owner is not on the project; 11 needs it (find out who removed it before going on)"; return 1; }
    cp10_rec CP-1.11 "$(cp10_slug "$var")-iam" - "4.1.3, 4.2.1" gcloud projects get-iam-policy "$id" --project="$id" --format=json || return 1
    cp10_ckpt CP-1.11 "$var" || return 1
  done
}

step CP-1.12 AUTO "Check the shape and write the deviation row" \
  --needs "DEVIATION_REGISTER BUILD_LOG_DIR FLD_PLATFORM_CORE BOOTSTRAP_EXCEPTION_EXPIRY REGION BILLING_ACCOUNT_ID CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT" \
  --gate "NAMES SD-01 SD-17"
cp10_bd_open() { [ -f "$(v DEVIATION_REGISTER)" ] && awk -F' *[|] *' -v id="$1" '$2 == id && NF == 15 {f = 1} END {exit !f}' "$(v DEVIATION_REGISTER)"; }
cp10_1_12_row() { cp10_row "$1"; cp10_bd_open "BD-10-$CP10_N"; }
s_CP_1_12_check() { cp10_allrows cp10_1_12_row && ckpt_done CP-1; }
s_CP_1_12_apply() {
  local var id d
  d="$(date -u +%Y-%m-%d)"
  for var in $CP10_ROWS; do
    cp10_1_12_row "$var" && continue
    cp10_row "$var"; id="$(v "$var")"
    cp10_plan "reads first: parent fld-platform-core, tier=core, created_by=bootstrap-hand, billing enabled, _Default to default-europe-west1"
    if [ "$AGP_MODE" = apply ]; then
      nonempty r gcloud projects list --filter='projectId="'"$id"'" AND parent.id="'"$(v FLD_PLATFORM_CORE)"'" AND labels.tier~"^core$" AND labels.created_by~"^bootstrap-hand$"' --format="value(projectId)" \
        || { echo "FAIL $var: parent, tier=core or created_by=bootstrap-hand differs from the shape"; return 1; }
      cp10_1_4_row "$var" || { echo "FAIL $var: billing is not enabled on BILLING_ACCOUNT_ID"; return 1; }
      cp10_1_7_sink "$var" || { echo "FAIL $var: _Default does not route to default-europe-west1"; return 1; }
    fi
    x bd_insert "$(printf '| BD-10-%s | %s | 10 CP-1.1 to CP-1.11 (%s) | MOD | platform-core: one core project (02 2.2, 3.6, 3.7, 4.2; SD-17) | folder %s; project %s | NAMES record; row %s of the 10 section 1 table | parent fld-platform-core; 10 labels; tags inherited, none bound; APIs of the row; _Default to default-europe-west1 (30 d), _Required global; _Trace europe-west1 or N/A for KMS_PROJECT; budget 300; 2 Essential Contacts; deletion lien; policies none (13); grants none beyond service agents | BLOCKED (checker is 17): manual, BUILD_LOG_DIR/records/*-CP-1.1 to CP-1.11-%s-* | not removed: kept under BD-10-6 until 12 | none: SD-01 one-person bootstrap, reviewed at 42 | superseded by terraform import and an empty plan (B-01); Tier W gate at the latest | open |\n' \
      "$CP10_N" "$d" "$var" "$(v FLD_PLATFORM_CORE)" "$id" "$CP10_N" "$(cp10_slug "$var")")" || return 1
    cp10_ckpt CP-1.12 "$var" || return 1
  done
  ckpt_done CP-1 || x checkpoint CP-1 DONE - - "five core projects"
}

# ---------------------------------------------------------------- 2. CICD_PROJECT: state and registry

step CP-2.1 AUTO "Create the Terraform state bucket" --irreversible --needs "CICD_PROJECT REGION PLATFORM_REPO_DIR BUILD_LOG_DIR" \
  --sets "TF_STATE_BUCKET" --gate "NAMES"
s_CP_2_1_check() {  # EUROPE-WEST1, uniform access, public access prevention, versioning, 30-day soft delete; the name recorded
  local b rc
  b="$(cp10_id TF_STATE_BUCKET)" || return 2
  nonempty r gcloud storage buckets list "$b" --project="$(v CICD_PROJECT)" \
    --filter='location~"^EUROPE-WEST1$" AND uniform_bucket_level_access=true AND public_access_prevention~"^enforced$" AND versioning_enabled=true AND soft_delete_policy.retentionDurationSeconds=2592000' \
    --format="value(name)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  has_value TF_STATE_BUCKET
}
s_CP_2_1_apply() {
  local b p rc
  b="$(cp10_id TF_STATE_BUCKET)" || return 1
  p="$(v CICD_PROJECT)"
  cp10_now exists gcloud storage buckets describe "$b" --project="$p" --format="value(name)"; rc=$?
  case $rc in
    0) ;;
    1|3) x gcloud storage buckets create "$b" --project="$p" --location="$(v REGION)" --uniform-bucket-level-access --public-access-prevention --soft-delete-duration=30d \
           || { echo "A name already taken fails the create with nothing made: apply the NAMES record's fallback rule (CP-2.1)"; return 1; };;
    *) return 1;;
  esac
  x gcloud storage buckets update "$b" --versioning --project="$p" || return 1
  pset TF_STATE_BUCKET "$b" || return 1
  cp10_plan "the check then proves EUROPE-WEST1, uniform access, public access prevention enforced, versioning and a 2592000 s soft delete"
  cp10_rec CP-2.1 tf-state-bucket E-05 "5.3, 7.1" gcloud storage buckets describe "$b" --project="$p" \
    --format="default(location,uniform_bucket_level_access,public_access_prevention,versioning_enabled,soft_delete_policy)"
}

step CP-2.2 AUTO "Test 09 §3.4's retention policy, then clear it" --removes --needs "TF_STATE_BUCKET CICD_PROJECT BUILD_LOG_DIR"
cp10_2_2_record() { ls "$(v BUILD_LOG_DIR)"/records/*-CP-2.2-tf-state-retention-test-v1.txt >/dev/null 2>&1; }
s_CP_2_2_check() {
  local rc
  local out
  out="$(r gcloud storage buckets describe "$(v TF_STATE_BUCKET)" --project="$(v CICD_PROJECT)" --format=json 2>/dev/null)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  cp10_2_2_record || return 1
  printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(1 if isinstance(d, dict) and d.get("retention_policy") else 0)' 2>/dev/null
  rc=$?; [ $rc -le 1 ] || return 2
  return $rc
}
s_CP_2_2_apply() {
  local b p t rep=ok rmrc=ok branch
  b="$(v TF_STATE_BUCKET)"; p="$(v CICD_PROJECT)"; t="${b}/cp-2-2-test"
  cp10_plan "Two lines are expected to fail with 403 retentionPolicyNotMet; the step ends with NO retention policy (never locked, never re-applied)."
  x gcloud storage buckets update "$b" --retention-period=30d --project="$p" || return 1
  printf 'v1\n' | x gcloud storage cp - "${t}/default.tfstate" --project="$p" || return 1
  printf 'v2\n' | x gcloud storage cp - "${t}/default.tfstate" --project="$p" || rep=refused
  printf 'lock\n' | x gcloud storage cp - "${t}/default.tflock" --project="$p" || return 1
  x gcloud storage rm "${t}/default.tflock" --project="$p" || rmrc=refused
  [ "$AGP_MODE" != apply ] || r gcloud storage ls --all-versions "${t}/" --project="$p"
  cp10_plan "reads: gcloud storage ls --all-versions ${t}/ (the version listing, for the record)"
  x gcloud storage buckets update "$b" --clear-retention-period --project="$p" \
    || { echo "FAIL the clear was refused: a locked policy cannot be removed; stop and tell 17 before any state is written"; return 1; }
  printf 'v3\n' | x gcloud storage cp - "${t}/default.tfstate" --project="$p" || { echo "FAIL the post-clear replace failed"; return 1; }
  x gcloud storage rm "${t}/default.tfstate" --project="$p" || { echo "FAIL the post-clear delete failed"; return 1; }
  [ "$AGP_MODE" = apply ] || { cp10_plan "then: which branch the in-policy test took (BD-10-7 item 8), and the post-clear describe, saved as the record"; return 0; }
  if [ "$rep" = refused ] || [ "$rmrc" = refused ]; then branch="retention policy refused the state rewrite; cleared"
  else branch="versioning absorbed the rewrite; policy cleared anyway"; fi
  echo "BD-10-7 item (8) for CP-8.2: $branch (replace: $rep, lock delete: $rmrc; the error text is in the apply run log)"
  { echo "CP-2.2 in-policy test: replace of default.tfstate: $rep; delete of default.tflock: $rmrc"
    echo "BD-10-7 item (8): $branch"
    echo "post-clear replace and delete: succeeded"
    gcloud storage buckets describe "$b" --project="$p" --format="default(retention_policy,versioning_enabled,soft_delete_policy)"; } \
    | xw "$(v BUILD_LOG_DIR)/records/$(date -u +%F)-CP-2.2-tf-state-retention-test-v1.txt" 600 || return 1
  ev CP-2.2 tf-state-retention-test - "5.3, 5.2.1" "BUILD_LOG_DIR/records" "$(v BUILD_LOG_DIR)/records/$(date -u +%F)-CP-2.2-tf-state-retention-test-v1.txt"
}

step CP-2.3 AUTO "Create the shared Artifact Registry repository platform" --needs "CICD_PROJECT REGION" --sets "AR_PLATFORM"
cp10_2_3_repo() { exists gcloud artifacts repositories describe platform --location="$(v REGION)" --project="$(v CICD_PROJECT)" --format="value(name)"; }
s_CP_2_3_check() {  # a DOCKER standard repository with immutable tags in REGION, and AR_PLATFORM recorded
  nonempty r gcloud artifacts repositories list --location="$(v REGION)" --project="$(v CICD_PROJECT)" \
    --filter='name~"/locations/'"$(v REGION)"'/repositories/platform$" AND format=DOCKER AND dockerConfig.immutableTags=true AND mode=STANDARD_REPOSITORY' --format="value(name)" \
    || return $?
  has_value AR_PLATFORM
}
s_CP_2_3_apply() {
  local p reg rc
  p="$(v CICD_PROJECT)"; reg="$(v REGION)"
  cp10_now cp10_2_3_repo; rc=$?
  case $rc in
    0) ;;
    1|3) x gcloud artifacts repositories create platform --repository-format=docker --location="$reg" --immutable-tags \
           --description="Platform images (k7-executor, drift, reconciliation); agent images live in per-agent repositories (09 section 1.3)" --project="$p" || return 1;;
    *) return 1;;
  esac
  pset AR_PLATFORM "${reg}-docker.pkg.dev/${p}/platform" || return 1
  cp10_rec CP-2.3 ar-platform E-05 5.2.2 gcloud artifacts repositories describe platform --location="$reg" --project="$p" --format="yaml(name,format,dockerConfig,mode)"
}

# ---------------------------------------------------------------- 3. CICD_PROJECT: build identity

cp10_sa_step_check() {  # cp10_sa_step_check EMAIL_VAR NAME PROJECT_VAR [nobind]: the account exists, its value is
  # recorded, it has no user-managed key and, with nobind, no IAM binding on it (nobody can act as it)
  local rc e
  e="$2@$(v "$3").iam.gserviceaccount.com"
  exists gcloud iam service-accounts describe "$e" --project="$(v "$3")" --format="value(email)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  has_value "$1" || return 1
  cp10_none "user-managed keys of $e" user-keys -- gcloud iam service-accounts keys list --iam-account="$e" --managed-by=user --project="$(v "$3")" || return 1
  [ "${4-}" = nobind ] || return 0
  cp10_none "bindings on $e" bindings -- gcloud iam service-accounts get-iam-policy "$e" --project="$(v "$3")"
}
cp10_sa_create() {      # cp10_sa_create NAME PROJECT_VAR DESCRIPTION: create the account unless it exists
  local rc
  cp10_now exists gcloud iam service-accounts describe "$1@$(v "$2").iam.gserviceaccount.com" --project="$(v "$2")" --format="value(email)"; rc=$?
  case $rc in
    0) return 0;;
    1|3) x gcloud iam service-accounts create "$1" --display-name="$1" --description="$3" --project="$(v "$2")";;
    *) return 1;;
  esac
}

step CP-3.1 AUTO "Create the build identity" --needs "CICD_PROJECT" --sets "SA_CI_BUILD"
s_CP_3_1_check() { cp10_sa_step_check SA_CI_BUILD platform-build CICD_PROJECT; }
s_CP_3_1_apply() {
  local p e
  p="$(v CICD_PROJECT)"; e="platform-build@${p}.iam.gserviceaccount.com"
  cp10_sa_create platform-build CICD_PROJECT "Cloud Build identity for platform images; writes AR_PLATFORM only (10, 09 section 1.2)" || return 1
  pset SA_CI_BUILD "$e" || return 1
  [ "$AGP_MODE" = apply ] || { cp10_plan "then: enabled, no user-managed key; the describe saved as a record"; return 0; }
  cp10_sa_ok "$e" "$p" || return 1
  cp10_rec CP-3.1 sa-ci-build - 4.1.1 gcloud iam service-accounts describe "$e" --project="$p" --format="value(email,disabled)"
}

step CP-3.2 AUTO "Create the regional staging bucket and grant the build identity its three roles" \
  --needs "CICD_PROJECT CICD_PROJECT_NUMBER REGION SA_CI_BUILD"
cp10_staging() { printf 'gs://%s_%s_cloudbuild' "$(v CICD_PROJECT)" "$(v REGION)"; }
s_CP_3_2_check() {
  local p m rc
  p="$(v CICD_PROJECT)"; m="serviceAccount:$(v SA_CI_BUILD)"
  local extra
  nonempty r gcloud storage buckets list "$(cp10_staging)" --project="$p" \
    --filter='location~"^EUROPE-WEST1$" AND uniform_bucket_level_access=true AND public_access_prevention~"^enforced$"' --format="value(name)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  has_binding "$m" roles/storage.objectUser gcloud storage buckets get-iam-policy "$(cp10_staging)" --project="$p" || return $?
  has_binding "$m" roles/artifactregistry.writer gcloud artifacts repositories get-iam-policy platform --location="$(v REGION)" --project="$p" || return $?
  has_binding "$m" roles/logging.logWriter gcloud projects get-iam-policy "$p" --project="$p" || return $?
  extra="$(r gcloud projects get-iam-policy "$p" --project="$p" --format=json | cp10_json roles-of "$m" | grep -vx 'roles/logging.logWriter')"
  [ -z "$extra" ] || { echo "FAIL the build identity holds more than roles/logging.logWriter on $p: $extra"; return 1; }
}
cp10_logs_bucket_grant() {  # CP-3.2's conditional grant, run only when the regional logs bucket exists
  local lb rc
  lb="gs://$(v CICD_PROJECT_NUMBER)-$(v REGION)-cloudbuild-logs"
  exists gcloud storage buckets describe "$lb" --project="$(v CICD_PROJECT)" --format="value(name)"; rc=$?
  [ $rc -eq 0 ] || return 0
  has_binding "serviceAccount:$(v SA_CI_BUILD)" roles/storage.objectUser gcloud storage buckets get-iam-policy "$lb" --project="$(v CICD_PROJECT)" && return 0
  echo "The regional logs bucket $lb exists: granting the build identity objectUser on it (record it in BD-10-7 item 13)"
  x gcloud storage buckets add-iam-policy-binding "$lb" --member="serviceAccount:$(v SA_CI_BUILD)" --role="roles/storage.objectUser" --project="$(v CICD_PROJECT)"
}
s_CP_3_2_apply() {
  local p reg sa st rc
  p="$(v CICD_PROJECT)"; reg="$(v REGION)"; sa="$(v SA_CI_BUILD)"; st="$(cp10_staging)"
  cp10_now exists gcloud storage buckets describe "$st" --project="$p" --format="value(name)"; rc=$?
  case $rc in
    0) ;;
    1|3) x gcloud storage buckets create "$st" --project="$p" --location="$reg" --uniform-bucket-level-access --public-access-prevention || return 1;;
    *) return 1;;
  esac
  x gcloud storage buckets add-iam-policy-binding "$st" --member="serviceAccount:${sa}" --role="roles/storage.objectUser" --project="$p" || return 1
  x gcloud artifacts repositories add-iam-policy-binding platform --location="$reg" --member="serviceAccount:${sa}" --role="roles/artifactregistry.writer" --project="$p" || return 1
  x gcloud projects add-iam-policy-binding "$p" --project="$p" --member="serviceAccount:${sa}" --role="roles/logging.logWriter" || return 1
  [ "$AGP_MODE" = apply ] || { cp10_plan "then, only if gs://<CICD_PROJECT_NUMBER>-$reg-cloudbuild-logs exists: objectUser on it for the build identity"; return 0; }
  cp10_logs_bucket_grant || return 1
  cp10_rec CP-3.2 build-grants - "4.2.1, 7.1" gcloud storage buckets describe "$st" --project="$p" --format="default(location,uniform_bucket_level_access,public_access_prevention)"
}

step CP-3.3 AUTO-READ "Read the Cloud Build defaults and confirm the Compute Engine default account cannot be used" --needs "CICD_PROJECT REGION"
s_CP_3_3_check() { ckpt_done CP-3.3; }
cp10_build_defaults() {
  gcloud builds get-default-service-account --region="$2" --project="$1"
  gcloud services list --enabled --project="$1" --filter="config.name=compute.googleapis.com" --format="value(config.name)"
  gcloud iam service-accounts list --project="$1" --format="value(email)"
}
s_CP_3_3_apply() {
  cp10_plan "reads: Cloud Build's default account in REGION; compute.googleapis.com is not enabled; no -compute@developer account"
  [ "$AGP_MODE" = apply ] || return 0
  local p bad=0
  p="$(v CICD_PROJECT)"
  echo "Cloud Build default account (recorded; expected the Compute Engine default, which does not exist here):"
  r gcloud builds get-default-service-account --region="$(v REGION)" --project="$p" | sed 's/^/       /'
  cp10_none "compute.googleapis.com is enabled in CICD_PROJECT" has-value config.name compute.googleapis.com -- gcloud services list --enabled --project="$p" || bad=1
  r gcloud iam service-accounts list --project="$p" --format="value(email)" | grep -q -- '-compute@developer[.]gserviceaccount[.]com$' \
    && { echo "FAIL a Compute Engine default service account exists in CICD_PROJECT"; bad=1; }
  [ $bad = 0 ] || return 1
  echo "13 is handed: enforce constraints/cloudbuild.disableCreateDefaultServiceAccount at fld-platform-core (CP-8.2's re-run index)"
  cp10_rec CP-3.3 build-defaults - 4.2.1 cp10_build_defaults "$p" "$(v REGION)"
}

step CP-3.4 HUMAN "Commit the build contract" --needs "PLATFORM_REPO_DIR PLATFORM_REPO_REMOTE"
s_CP_3_4_check() { ckpt_done CP-3.4; }
s_CP_3_4_manual() {
  echo "WHO: the platform owner writes and pushes; two human reviewers approve under branch protection (03)."
  echo "WHERE: PLATFORM_REPO_DIR, branch cp-3-4-build-contract, a pull request to PLATFORM_REPO_REMOTE."
  echo "DO: run CP-3.4's block of setup/10 as written (ci/BUILD-CONTRACT.md, switch -c, add, commit, push); open the pull request."
  echo "VERIFY: merged with two approvals; git -C \"\$PLATFORM_REPO_DIR\" log --oneline -1 origin/main -- ci/BUILD-CONTRACT.md shows the merge."
  echo "RECORD: the merge commit id in the build log. Then: agp-platform done CP-3.4"
}

step CP-3.5 AUTO "Run one smoke build and delete its image" --removes \
  --needs "CICD_PROJECT CICD_PROJECT_NUMBER REGION SA_CI_BUILD AR_PLATFORM TF_STATE_BUCKET BUILD_LOG_DIR"
s_CP_3_5_check() { ls "$(v BUILD_LOG_DIR)"/records/*-CP-3.5-smoke-build-v1.txt >/dev/null 2>&1; }
cp10_smoke_record() {
  gcloud builds describe "$1" --region="$3" --project="$2" --format="yaml(id,status,serviceAccount,options.logging,source.storageSource.bucket,results.images)"
  gcloud storage buckets list --project="$2" --format="value(name,location)"
  gcloud artifacts docker images list "$4" --include-tags --project="$2" --format="value(package,tags,version)"
}
s_CP_3_5_apply() {
  local p reg sa ar dir tag out id n st
  p="$(v CICD_PROJECT)"; reg="$(v REGION)"; sa="$(v SA_CI_BUILD)"; ar="$(v AR_PLATFORM)"
  tag="$(date -u +%Y%m%d%H%M)"
  if [ "$AGP_MODE" = apply ]; then dir="$(mktemp -d "${TMPDIR:-/tmp}/cp-3-5-smoke.XXXXXX")" || return 1; else dir="<scratch directory>"; fi
  printf 'cp-3.5 smoke\n' | xw "${dir}/smoke.txt" || return 1
  printf 'FROM scratch\nCOPY smoke.txt /smoke.txt\n' | xw "${dir}/Dockerfile" || return 1
  printf "steps:\n- name: 'gcr.io/cloud-builders/docker'\n  args: ['build', '-t', '%s/cp-3-5-smoke:%s', '.']\nimages:\n- '%s/cp-3-5-smoke:%s'\noptions:\n  logging: CLOUD_LOGGING_ONLY\n  requestedVerifyOption: VERIFIED\n" \
    "$ar" "$tag" "$ar" "$tag" | xw "${dir}/cloudbuild.yaml" || return 1
  out="$(x gcloud builds submit "$dir" --config="${dir}/cloudbuild.yaml" --region="$reg" --default-buckets-behavior=regional-user-owned-bucket \
    --service-account="projects/${p}/serviceAccounts/${sa}" --project="$p" --format='value(id)')" || { [ "$AGP_MODE" = apply ] && rm -r "$dir"; return 1; }
  id="$(printf '%s\n' "$out" | tail -n 1)"
  if [ "$AGP_MODE" = apply ] && [ -z "$id" ]; then
    echo "The synchronous submit printed no id: re-running with --async, as CP-3.5 says, and polling the build"
    id="$(x gcloud builds submit "$dir" --config="${dir}/cloudbuild.yaml" --region="$reg" --default-buckets-behavior=regional-user-owned-bucket \
      --service-account="projects/${p}/serviceAccounts/${sa}" --project="$p" --async --format='value(id)' | tail -n 1)"
    n=0; st=""
    while [ -n "$id" ] && [ $n -lt 60 ]; do
      st="$(r gcloud builds describe "$id" --region="$reg" --project="$p" --format='value(status)')"
      case "$st" in SUCCESS|FAILURE|INTERNAL_ERROR|TIMEOUT|CANCELLED|EXPIRED) break;; esac
      n=$((n + 1)); sleep 10
    done
  fi
  [ "$AGP_MODE" = apply ] || {
    cp10_plan "then: the build by its own id (SUCCESS, as platform-build@, CLOUD_LOGGING_ONLY), no <CICD_PROJECT>_cloudbuild bucket, every bucket in EUROPE-WEST1"
    cp10_plan "gcloud asks to confirm the package delete; its question is shown only after the command ends: the operator types y"
    x gcloud artifacts packages delete cp-3-5-smoke --repository=platform --location="$reg" --project="$p"
    x rm -r "$dir"; return 0; }
  [ -n "$id" ] || { echo "FAIL no build id"; rm -r "$dir"; return 1; }
  echo "BUILD_ID=$id"
  nonempty r gcloud builds list --region="$reg" --project="$p" \
    --filter='id="'"$id"'" AND status=SUCCESS AND serviceAccount~"/serviceAccounts/'"$(cp10_re "$sa")"'$" AND options.logging=CLOUD_LOGGING_ONLY' --format="value(id)" \
    || { echo "FAIL build $id: not SUCCESS as $sa with CLOUD_LOGGING_ONLY"; rm -r "$dir"; return 1; }
  cp10_logs_bucket_grant || { rm -r "$dir"; return 1; }
  cp10_none "buckets of CICD_PROJECT outside EUROPE-WEST1 or not expected (a ${p}_cloudbuild bucket is S022's failure)" \
    buckets-unexpected EUROPE-WEST1 "$(v TF_STATE_BUCKET | sed 's#^gs://##')" "${p}_${reg}_cloudbuild" "$(v CICD_PROJECT_NUMBER)-${reg}-cloudbuild-logs" -- \
    gcloud storage buckets list --project="$p" || { rm -r "$dir"; return 1; }
  nonempty r gcloud artifacts docker images list "$ar" --include-tags --project="$p" --filter='package~"/cp-3-5-smoke$"' --format="value(package)" \
    || { echo "FAIL the smoke image is not listed in $ar"; rm -r "$dir"; return 1; }
  cp10_rec CP-3.5 smoke-build E-05 "5.2.2, 7.1" cp10_smoke_record "$id" "$p" "$reg" "$ar" || { rm -r "$dir"; return 1; }
  printf '      gcloud now asks to confirm the delete of package cp-3-5-smoke; the question is shown only after the\n      command ends, so type y and press Return when the run pauses here\n' >&3
  x gcloud artifacts packages delete cp-3-5-smoke --repository=platform --location="$reg" --project="$p" \
    || echo "NOTE the package delete was refused: record the image as a harmless test artefact for 42's cleanup"
  x rm -r "$dir"
}

# ---------------------------------------------------------------- 4. Workload Identity Federation

step CP-4.1 HUMAN "Check the git-host gate and read the repository's numeric ids" \
  --needs "GIT_HOST GIT_OIDC_ISSUER PLATFORM_REPO_REMOTE PLATFORM_ENV_FILE" --sets "WIF_REPO_ID WIF_OWNER_ID" --gate "P22 SD-14"
s_CP_4_1_check() { ckpt_done CP-4.1; }
s_CP_4_1_manual() {
  echo "WHO: the platform owner, repository administrator on the git host ($(v GIT_HOST)), with gh or glab signed in."
  echo "DO: confirm the signed P22/SD-14 record; the host must be GitHub or GitLab SaaS (Azure DevOps, HCP Terraform: stop, 03 re-opens)."
  echo "  GitHub: gh api \"repos/<owner>/<repository>\" --jq '\"repo_id=\\(.id) owner_id=\\(.owner.id) default_branch=\\(.default_branch)\"'"
  echo "  GitLab: glab api \"projects/<group%2Frepository>\" | jq -r '\"project_id=\\(.id) namespace_id=\\(.namespace.id) default_branch=\\(.default_branch)\"'"
  echo "VERIFY: default_branch is main; main requires two reviews; GIT_OIDC_ISSUER is the host's issuer (CP-4.1 VERIFY)."
  echo "RECORD (typed by you): penv_set WIF_REPO_ID <digits>; penv_set WIF_OWNER_ID <digits>; the outputs as <date>-CP-4.1-repo-ids-v1."
  echo "Then: agp-platform done CP-4.1"
}

step CP-4.2 AUTO "Create the pool wif-factory" --needs "CICD_PROJECT" --sets "WIF_POOL"
cp10_pool() { exists gcloud iam workload-identity-pools describe wif-factory --location=global --project="$(v CICD_PROJECT)" --format="value(name)"; }
s_CP_4_2_check() {
  nonempty r gcloud iam workload-identity-pools list --location=global --project="$(v CICD_PROJECT)" \
    --filter='name~"/workloadIdentityPools/wif-factory$" AND state=ACTIVE' --format="value(name)" || return $?
  has_value WIF_POOL
}
s_CP_4_2_apply() {
  local p rc
  p="$(v CICD_PROJECT)"
  cp10_now cp10_pool; rc=$?
  case $rc in
    0) ;;
    1|3) x gcloud iam workload-identity-pools create wif-factory --location="global" --display-name="wif-factory" \
           --description="Platform repository CI only (02 section 3.4, P36)" --project="$p" || return 1;;
    *) return 1;;
  esac
  pset WIF_POOL "wif-factory" || return 1
  cp10_rec CP-4.2 wif-pool - 4.1.1 gcloud iam workload-identity-pools describe wif-factory --location=global --project="$p" --format="value(name,state)"
}

step CP-4.3 AUTO "Create the provider with the repository condition" \
  --needs "CICD_PROJECT CICD_PROJECT_NUMBER GIT_HOST GIT_OIDC_ISSUER WIF_REPO_ID WIF_OWNER_ID" --sets "WIF_PROVIDER" --gate "P22 SD-14"
cp10_provider_id() {    # 03 DC-4.3 records github.com or gitlab.com; a record written as GitHub or GitLab is read the same
  case "$(v GIT_HOST | tr 'A-Z' 'a-z')" in github.com|github) echo github;; gitlab.com|gitlab) echo gitlab;; *) return 1;; esac
}
s_CP_4_3_check() {
  local prov rc
  prov="$(cp10_provider_id)" || return 1
  nonempty r gcloud iam workload-identity-pools providers list --workload-identity-pool=wif-factory --location=global --project="$(v CICD_PROJECT)" \
    --filter='name~"/providers/'"$prov"'$" AND state=ACTIVE' --format="value(name)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  cp10_none "provider $prov: the issuer must equal GIT_OIDC_ISSUER and the condition name both ids and main" \
    provider-bad "$prov" "$(v GIT_OIDC_ISSUER)" "$(v WIF_REPO_ID)" "$(v WIF_OWNER_ID)" -- \
    gcloud iam workload-identity-pools providers list --workload-identity-pool=wif-factory --location=global --project="$(v CICD_PROJECT)" || return 1
  [ "$(r gcloud iam workload-identity-pools providers list --workload-identity-pool=wif-factory --location=global --project="$(v CICD_PROJECT)" --format="value(name)" | grep -c .)" -le 1 ] \
    || { echo "FAIL wif-factory holds more than one provider"; return 1; }
  has_value WIF_PROVIDER
}
cp10_4_3_github() {    # the page's GitHub Actions form (provider id github)
  x gcloud iam workload-identity-pools providers create-oidc github --location="global" --workload-identity-pool="wif-factory" --issuer-uri="$(v GIT_OIDC_ISSUER)" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository_id=assertion.repository_id,attribute.repository_owner_id=assertion.repository_owner_id,attribute.ref=assertion.ref" \
    --attribute-condition="assertion.repository_owner_id=='$(v WIF_OWNER_ID)' && assertion.repository_id=='$(v WIF_REPO_ID)' && assertion.ref=='refs/heads/main'" \
    --display-name="platform repository" --project="$1"
}
cp10_4_3_gitlab() {    # the page's GitLab SaaS form (provider id gitlab)
  x gcloud iam workload-identity-pools providers create-oidc gitlab --location="global" --workload-identity-pool="wif-factory" --issuer-uri="$(v GIT_OIDC_ISSUER)" \
    --attribute-mapping="google.subject=assertion.sub,attribute.project_id=assertion.project_id,attribute.namespace_id=assertion.namespace_id,attribute.ref=assertion.ref" \
    --attribute-condition="assertion.namespace_id=='$(v WIF_OWNER_ID)' && assertion.project_id=='$(v WIF_REPO_ID)' && assertion.ref_type=='branch' && assertion.ref=='main'" \
    --display-name="platform repository" --project="$1"
}
s_CP_4_3_apply() {
  local p prov rc
  p="$(v CICD_PROJECT)"
  if ! prov="$(cp10_provider_id)"; then
    if has_value GIT_HOST; then
      printf '      GIT_HOST is %s: this file gives a provider for github.com and gitlab.com only (P22, SD-14); stop, 03 is re-opened\n' "$(v GIT_HOST)" >&3
    elif [ "$AGP_MODE" != apply ]; then   # plan only: the runner never applies a step whose GIT_HOST is unset
      cp10_plan "GIT_HOST chooses one of the two forms (github.com: provider github; gitlab.com: provider gitlab):"
      cp10_4_3_github "$p"; cp10_4_3_gitlab "$p"
      pset WIF_PROVIDER "projects/<CICD_PROJECT_NUMBER>/locations/global/workloadIdentityPools/wif-factory/providers/<github|gitlab>"
    fi
    return 1
  fi
  cp10_now exists gcloud iam workload-identity-pools providers describe "$prov" --workload-identity-pool=wif-factory --location=global --project="$p" --format="value(name)"; rc=$?
  case "$rc:$prov" in
    0:*) ;;
    1:github|3:github) cp10_4_3_github "$p" || return 1;;
    1:gitlab|3:gitlab) cp10_4_3_gitlab "$p" || return 1;;
    *) return 1;;
  esac
  pset WIF_PROVIDER "projects/$(v CICD_PROJECT_NUMBER)/locations/global/workloadIdentityPools/wif-factory/providers/${prov}" || return 1
  cp10_plan "the check then proves: ACTIVE, the issuer equals GIT_OIDC_ISSUER, both numeric ids in the condition, one provider only"
  cp10_rec CP-4.3 wif-provider - "4.1.1, 5.2.1" gcloud iam workload-identity-pools providers describe "$prov" --workload-identity-pool=wif-factory --location=global --project="$p" \
    --format="yaml(name,state,oidc.issuerUri,attributeMapping,attributeCondition)"
}

# ---------------------------------------------------------------- 5. factory, group-factory and deploy identities

step CP-5.1 AUTO "Create factory-apply@" --needs "CICD_PROJECT" --sets "SA_FACTORY_APPLY"
s_CP_5_1_check() { cp10_sa_step_check SA_FACTORY_APPLY factory-apply CICD_PROJECT; }
s_CP_5_1_apply() {
  local p e
  p="$(v CICD_PROJECT)"; e="factory-apply@${p}.iam.gserviceaccount.com"
  cp10_sa_create factory-apply CICD_PROJECT "Factory routine identity, impersonated only through wif-factory (02 section 3.4, P36)" || return 1
  pset SA_FACTORY_APPLY "$e" || return 1
  [ "$AGP_MODE" = apply ] || { cp10_plan "then: enabled, no user-managed key; the describe saved as a record"; return 0; }
  cp10_sa_ok "$e" "$p" || return 1
  cp10_rec CP-5.1 factory-apply - 4.1.1 gcloud iam service-accounts describe "$e" --project="$p" --format="value(email)"
}

step CP-5.2 AUTO "Let only the platform repository impersonate factory-apply@, and give it the state bucket" \
  --needs "SA_FACTORY_APPLY CICD_PROJECT CICD_PROJECT_NUMBER TF_STATE_BUCKET WIF_REPO_ID WIF_PROVIDER"
cp10_wif_member() {     # the principal set of the repository (GitHub: repository_id; GitLab: project_id)
  local attr=repository_id
  case "$(v WIF_PROVIDER)" in */providers/gitlab) attr=project_id;; esac
  printf 'principalSet://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/wif-factory/attribute.%s/%s' "$(v CICD_PROJECT_NUMBER)" "$attr" "$(v WIF_REPO_ID)"
}
s_CP_5_2_check() {
  has_binding "$(cp10_wif_member)" roles/iam.workloadIdentityUser gcloud iam service-accounts get-iam-policy "$(v SA_FACTORY_APPLY)" --project="$(v CICD_PROJECT)" || return $?
  has_binding "serviceAccount:$(v SA_FACTORY_APPLY)" roles/storage.objectAdmin gcloud storage buckets get-iam-policy "$(v TF_STATE_BUCKET)" --project="$(v CICD_PROJECT)" || return $?
  local other
  other="$(r gcloud iam service-accounts get-iam-policy "$(v SA_FACTORY_APPLY)" --project="$(v CICD_PROJECT)" --format=json | cp10_json bindings | grep -vxF "roles/iam.workloadIdentityUser $(cp10_wif_member)")"
  [ -z "$other" ] || { echo "FAIL factory-apply@ holds another binding: $other"; return 1; }
  other="$(r gcloud storage buckets get-iam-policy "$(v TF_STATE_BUCKET)" --project="$(v CICD_PROJECT)" --format=json | cp10_json roles-of "serviceAccount:$(v SA_FACTORY_APPLY)" | grep -vx roles/storage.objectAdmin)"
  [ -z "$other" ] || { echo "FAIL factory-apply@ holds more than objectAdmin on the state bucket: $other"; return 1; }
}
s_CP_5_2_apply() {
  local p sa b
  p="$(v CICD_PROJECT)"; sa="$(v SA_FACTORY_APPLY)"; b="$(v TF_STATE_BUCKET)"
  x gcloud iam service-accounts add-iam-policy-binding "$sa" --role="roles/iam.workloadIdentityUser" --member="$(cp10_wif_member)" --project="$p" || return 1
  x gcloud storage buckets add-iam-policy-binding "$b" --member="serviceAccount:${sa}" --role="roles/storage.objectAdmin" --project="$p" || return 1
  cp10_rec CP-5.2 factory-apply-grants E-05 4.2.1 gcloud iam service-accounts get-iam-policy "$sa" --project="$p" --format=json
}

step CP-5.3 HUMAN "Prove the federation from main, and its refusal from another branch" --needs "WIF_PROVIDER SA_FACTORY_APPLY TF_STATE_BUCKET CICD_PROJECT"
s_CP_5_3_check() { ckpt_done CP-5.3; }
s_CP_5_3_manual() {
  echo "WHO: the platform owner opens the pull request; two human reviewers merge it."
  echo "DO: add .github/workflows/wif-smoke.yml (workflow_dispatch; google-github-actions/auth pinned to the v3 commit SHA) with"
  echo "  workload_identity_provider: $(v WIF_PROVIDER)   service_account: $(v SA_FACTORY_APPLY)   run: gcloud storage ls $(v TF_STATE_BUCKET)/"
  echo "  (GitLab SaaS: the id_tokens job of CP-5.3.) Merge; run it on main (Actions > wif-smoke > Run workflow), then on branch cp-5-3-negative."
  echo "VERIFY: main succeeds with an empty listing; the branch run fails at the token exchange (attribute condition)."
  echo "  gcloud logging read 'protoPayload.serviceName=\"sts.googleapis.com\"' --project=$(v CICD_PROJECT) --freshness=1h (may be empty before 14)."
  echo "RECORD: the two run URLs and the merge commit as <date>-CP-5.3-wif-proof-v1; delete the negative branch. Then: agp-platform done CP-5.3"
}

step CP-5.4 AUTO "Create factory-groups@" --needs "CICD_PROJECT" --sets "SA_FACTORY_GROUPS" --gate "SD-18"
s_CP_5_4_check() { cp10_sa_step_check SA_FACTORY_GROUPS factory-groups CICD_PROJECT nobind; }
s_CP_5_4_apply() {
  local p e
  p="$(v CICD_PROJECT)"; e="factory-groups@${p}.iam.gserviceaccount.com"
  cp10_sa_create factory-groups CICD_PROJECT "Group-factory identity; Workspace Groups Admin; agent groups only, control groups refused in code (04 section 2.4, P65)" || return 1
  pset SA_FACTORY_GROUPS "$e" || return 1
  [ "$AGP_MODE" = apply ] || { cp10_plan "then: enabled, no user-managed key, no IAM binding on the account; uniqueId saved for section 7"; return 0; }
  cp10_sa_ok "$e" "$p" || return 1
  cp10_rec CP-5.4 factory-groups - 4.1.1 gcloud iam service-accounts describe "$e" --project="$p" --format="value(email,uniqueId)"
}

step CP-5.5 AUTO "Create walle-deployer@, the ladder publisher" --needs "CICD_PROJECT" --sets "SA_WALLE_DEPLOYER" --gate "SD-34"
s_CP_5_5_check() { cp10_sa_step_check SA_WALLE_DEPLOYER walle-deployer CICD_PROJECT nobind; }
s_CP_5_5_apply() {
  local p e
  p="$(v CICD_PROJECT)"; e="walle-deployer@${p}.iam.gserviceaccount.com"
  cp10_sa_create walle-deployer CICD_PROJECT "Wall-E deploy identity and ladder publisher; publishes only from a merged two-human commit (SD-34, P142)" || return 1
  pset SA_WALLE_DEPLOYER "$e" || return 1
  [ "$AGP_MODE" = apply ] || { cp10_plan "then: enabled, no user-managed key, no IAM binding on the account; the describe saved as a record"; return 0; }
  cp10_sa_ok "$e" "$p" || return 1
  cp10_rec CP-5.5 walle-deployer - 4.1.1 gcloud iam service-accounts describe "$e" --project="$p" --format="value(email)"
}

step CP-5.6 HUMAN "Billing roles for factory-apply@ (re-run of 07 BA-3.1)" --needs "BILLING_ACCOUNT_ID SA_FACTORY_APPLY BILLING_ADMIN_EMAIL"
s_CP_5_6_check() { ckpt_done CP-5.6; }
s_CP_5_6_manual() {
  echo "WHO: the billing administrator ($(v BILLING_ADMIN_EMAIL)) grants; the platform owner checks first and verifies."
  echo "FIRST (platform owner): exists_or_pending \"serviceAccount:$(v SA_FACTORY_APPLY)\" CP-5.6 \"07 BA-3.1 billing.user and billing.costsManager for factory-apply@\""
  echo "WHERE (billing administrator): Billing > Account management > Permissions > Add principal, account $(v BILLING_ACCOUNT_ID) only:"
  echo "  serviceAccount:$(v SA_FACTORY_APPLY) with Billing Account User and Billing Account Costs Manager (or the two"
  echo "  gcloud billing accounts add-iam-policy-binding lines of CP-5.6)."
  echo "VERIFY (billing administrator): gcloud billing accounts get-iam-policy $(v BILLING_ACCOUNT_ID) --flatten=\"bindings[].members\""
  echo "  shows factory-apply@ under exactly those two roles. Close 07 BA-3.1's re-run row; record <date>-CP-5.6-factory-apply-billing-v1."
  echo "Then: agp-platform done CP-5.6"
}

# ---------------------------------------------------------------- 6. CORE_PROJECT: drift and kill identities

step CP-6.1 AUTO "Create platform-drift@ and k7-executor@" --needs "CORE_PROJECT SA_1_ADMIN" --sets "SA_PLATFORM_DRIFT SA_K7_EXECUTOR"
s_CP_6_1_check() {
  local rc
  local e held
  cp10_sa_step_check SA_PLATFORM_DRIFT platform-drift CORE_PROJECT nobind; rc=$?; [ $rc -eq 0 ] || return $rc
  cp10_sa_step_check SA_K7_EXECUTOR k7-executor CORE_PROJECT nobind; rc=$?; [ $rc -eq 0 ] || return $rc
  for e in "$(v SA_PLATFORM_DRIFT)" "$(v SA_K7_EXECUTOR)"; do
    held="$(r gcloud projects get-iam-policy "$(v CORE_PROJECT)" --project="$(v CORE_PROJECT)" --format=json | cp10_json roles-of "serviceAccount:$e")"
    [ -z "$held" ] || { echo "FAIL $e holds a project role: $held"; return 1; }
  done
}
s_CP_6_1_apply() {
  local p d k e
  p="$(v CORE_PROJECT)"; d="platform-drift@${p}.iam.gserviceaccount.com"; k="k7-executor@${p}.iam.gserviceaccount.com"
  cp10_sa_create platform-drift CORE_PROJECT "Drift and reconciliation jobs (P73, topology row 36); roles made in file 16" || return 1
  cp10_sa_create k7-executor CORE_PROJECT "K7 fleet-kill job; no standing role, activates ent-k7-executor (04 section 9)" || return 1
  pset SA_PLATFORM_DRIFT "$d" || return 1
  pset SA_K7_EXECUTOR "$k" || return 1
  [ "$AGP_MODE" = apply ] || { cp10_plan "then: both enabled, no user-managed key, no binding on either account, no project role (the same read shows the creator's Owner)"; return 0; }
  for e in "$d" "$k"; do cp10_sa_ok "$e" "$p" || return 1; done
  cp10_owner_kept "$p" || { echo "FAIL the same read does not show the creator's Owner on CORE_PROJECT: the policy read is not live"; return 1; }
  cp10_rec CP-6.1 core-identities E-08 4.1.1 gcloud iam service-accounts list --project="$p" --format="value(email,disabled)"
}

step CP-6.2 BLOCKED "The jobs that run as these identities" --note "B-02 (drift, reconciliation, Data Access canary) and B-04 (k7-executor): no code"
s_CP_6_2_check() { ckpt_done CP-6.2; }
s_CP_6_2_manual() {
  echo "Nothing is created. Before any job is deployed in CORE_PROJECT: the source on PLATFORM_REPO_REMOTE with green CI"
  echo "(B-02, deployed in 16; B-04, deployed in 18); an image built under ci/BUILD-CONTRACT.md by SA_CI_BUILD, pushed to"
  echo "AR_PLATFORM, attested and deployed by digest with --binary-authorization=default; CORE_PROJECT's Cloud Run service"
  echo "agent given roles/artifactregistry.reader on platform at the deploy step. Check: gcloud run jobs list --region=REGION"
  echo "--project=CORE_PROJECT prints nothing, and the README BLOCKED index lists CP-6.2 against B-02 and B-04."
}

# ---------------------------------------------------------------- 7. Groups Admin for factory-groups@

step CP-7.1 HUMAN "Prepare the witnessed assignment" --witness \
  --needs "ROSTER_FILE SA_FACTORY_GROUPS CICD_PROJECT SECOND_HUMAN_EMAIL PLATFORM_REPO_DIR" --gate "SD-18"
s_CP_7_1_check() { ckpt_done CP-7.1; }
s_CP_7_1_manual() {
  echo "WHO: the platform owner; the second human ($(v SECOND_HUMAN_EMAIL)) present for the whole of section 7."
  echo "WHERE: PLATFORM_REPO_DIR, branch cp-7-roster-factory-groups."
  echo "DO: run CP-7.1's block of setup/10 as written: it moves factory-groups@ from expected_later[] into accounts[] of"
  echo "  $(v ROSTER_FILE) (kind service_account_admin, its uniqueId, Groups Admin), commits and pushes."
  echo "  Open the pull request marked \"do not merge before CP-7.3\"; confirm 06's interim activity rule is still active."
  echo "VERIFY: the JSON parses; accounts[] holds $(v SA_FACTORY_GROUPS) once; CODEOWNERS requests the second human's review."
  echo "Then: agp-platform done CP-7.1 --witness <second human's email>"
}

step CP-7.2 CONSOLE "Assign Groups Admin to factory-groups@" --witness --needs "SA_FACTORY_GROUPS EVIDENCE_INTERIM_LOCATION" --gate "SD-18"
s_CP_7_2_check() { ckpt_done CP-7.2; }
s_CP_7_2_manual() {
  echo "WHO: the platform owner as super admin (sa-1-admin@); the second human witnesses."
  echo "WHERE: Google Admin console, Menu > Account > Admin roles."
  echo "DO: point to Groups Admin > Assign admin > Assign service accounts; enter $(v SA_FACTORY_GROUPS); confirm."
  echo "  Assign no other role and no organisational-unit scope."
  echo "RECORD: the second human's dated screenshot of the confirmation as <date>-CP-7.2-groups-admin-assigned-v1 in EVIDENCE_INTERIM_LOCATION."
  echo "Then: agp-platform done CP-7.2 --witness <second human's email>"
}

step CP-7.3 HUMAN "Verify the assignment and its audit record" --witness --needs "SA_FACTORY_GROUPS CICD_PROJECT"
s_CP_7_3_check() { ckpt_done CP-7.3; }
s_CP_7_3_manual() {
  echo "WHO: the second human reads; the platform owner operates the screen."
  echo "WHERE: Admin console, Menu > Account > Admin roles > Groups Admin > View admins; then Menu > Reporting > Audit and"
  echo "  investigation > Admin log events (last hour, actor sa-1-admin@)."
  echo "VERIFY: factory-groups@ under Groups Admin; exactly one assignment event for it by sa-1-admin@; under no other role"
  echo "  (View admins of every role with admins); gcloud iam service-accounts keys list --iam-account=$(v SA_FACTORY_GROUPS)"
  echo "  --managed-by=user --project=$(v CICD_PROJECT) prints nothing. The second human writes \"verified\" and the time in the pull request."
  echo "RECORD: screenshots of both screens as <date>-CP-7.3-groups-admin-verify-v1."
  echo "Then: agp-platform done CP-7.3 --witness <second human's email>"
}

step CP-7.4 HUMAN "Merge the roster change (re-run of 06)" --witness --needs "ROSTER_FILE PLATFORM_REPO_DIR"
s_CP_7_4_check() { ckpt_done CP-7.4; }
s_CP_7_4_manual() {
  echo "WHO: the second human approves as required reviewer, a second reviewer as branch protection requires; the platform owner merges."
  echo "WHERE: the git host, the pull request of CP-7.1."
  echo "VERIFY: git -C \"\$PLATFORM_REPO_DIR\" fetch && git -C \"\$PLATFORM_REPO_DIR\" log --oneline -1 origin/main -- \"$(v ROSTER_FILE)\""
  echo "  shows the merge; the approvals include the second human; close the README re-run row for factory-groups@ with CP-7.4."
  echo "RECORD: the merge commit and approvals as <date>-CP-7.4-roster-merge-v1."
  echo "Then: agp-platform done CP-7.4 --witness <second human's email>"
}

# ---------------------------------------------------------------- 8. Close the part

step CP-8.1 AUTO-READ "Sweep the five projects" \
  --needs "FLD_PLATFORM_CORE SA_1_ADMIN CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT"
s_CP_8_1_check() { ckpt_done CP-8.1; }
cp10_sweep_record() {
  local p
  for p in "$@"; do
    echo "== $p"
    gcloud projects describe "$p" --project="$p" --format="value(parent.id,labels.tier,lifecycleState)"
    gcloud iam service-accounts list --project="$p" --format="value(email)"
    gcloud projects get-iam-policy "$p" --project="$p" --flatten="bindings[].members" --format="table(bindings.role,bindings.members)"
  done
}
s_CP_8_1_apply() {
  cp10_plan "reads, per project: parent fld-platform-core, tier core, ACTIVE; exactly the expected service accounts, none with a"
  cp10_plan "user-managed key; no human or public principal but user:SA_1_ADMIN as roles/owner, which must be there"
  [ "$AGP_MODE" = apply ] || return 0
  local var p want e bad=0
  for var in $CP10_ROWS; do
    p="$(v "$var")"
    case "$var" in
      CICD_PROJECT) want="platform-build factory-apply factory-groups walle-deployer";;
      CORE_PROJECT) want="platform-drift k7-executor";;
      *) want="";;
    esac
    nonempty r gcloud projects list --filter='projectId="'"$p"'" AND parent.id="'"$(v FLD_PLATFORM_CORE)"'" AND labels.tier~"^core$" AND lifecycleState=ACTIVE' --format="value(projectId)" \
      || { echo "FAIL $p: not ACTIVE, tier core, under fld-platform-core"; bad=1; }
    local emails=""
    for e in $want; do
      emails="$emails $e@${p}.iam.gserviceaccount.com"
      cp10_sa_ok "$e@${p}.iam.gserviceaccount.com" "$p" || bad=1
    done
    # shellcheck disable=SC2086
    cp10_none "$p: service accounts beyond the expected ones" sa-unexpected "$p" $emails -- gcloud iam service-accounts list --project="$p" || bad=1
    cp10_none "$p: human or public principals beyond the creator's Owner" iam-humans "$(v SA_1_ADMIN)" -- gcloud projects get-iam-policy "$p" --project="$p" || bad=1
    cp10_owner_kept "$p" || { echo "FAIL $p: no roles/owner for user:SA_1_ADMIN; an empty result means the read is wrong or the Owner was removed early: re-run before concluding"; bad=1; }
  done
  [ $bad = 0 ] || return 1
  # shellcheck disable=SC2046
  cp10_rec CP-8.1 core-sweep - "4.2.1, 1.3.1" cp10_sweep_record $(for var in $CP10_ROWS; do v "$var"; echo; done)
}

step CP-8.2 HUMAN "Record the kept Owner and the deviations; update the re-run index" --witness \
  --needs "DEVIATION_REGISTER BUILD_LOG_DIR BOOTSTRAP_EXCEPTION_EXPIRY SA_1_ADMIN CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT"
s_CP_8_2_check() { ckpt_done CP-8.2; }
s_CP_8_2_manual() {
  echo "WHO: the platform owner writes; the second human reads the EXC row BD-10-6 and initials the build-log line (a reader)."
  echo "DO: run CP-8.2's two bd_insert lines of setup/10. BD-10-7 holds <...> fields only this sitting knows: label keys"
  echo "  (CP-1.1), dependency services and forced disables (CP-1.6's REVIEW lines), the CP-2.2 branch (printed by CP-2.2"
  echo "  and in its record), KMS_PROJECT contacts (CP-1.10), the regional logs bucket (CP-3.2, CP-3.5); bd_insert refuses"
  echo "  a row that still holds one. Add the six re-run lines of CP-8.2 to the README re-run index."
  echo "VERIFY: grep -c '^| BD-10-' \"\$DEVIATION_REGISTER\" prints 7; every row above '## Closures'; no '<' left in BD-10-7."
  echo "Then: agp-platform done CP-8.2 --witness <second human's email>"
}

step CP-8.3 HUMAN "End the sitting"
s_CP_8_3_check() { ckpt_done CP-8.3; }
s_CP_8_3_manual() {
  echo "WHO: the platform owner, at the end of the sitting (not in the middle of a multi-phase apply: it revokes every credential)."
  echo "DO: agp-platform sitting end   (penv_guard, then sitting_end: SITTING-END OK); sign out of the Admin console profile of section 7."
  echo "VERIFY: checkpoints.tsv holds DONE for every step of file 10 except CP-6.2 (BLOCKED) and CP-1.8@KMS_PROJECT (N/A)."
  echo "Then: agp-platform done CP-8.3 --note \"file 10 complete except CP-6.2 BLOCKED and CP-1.8@KMS_PROJECT N/A\""
}
