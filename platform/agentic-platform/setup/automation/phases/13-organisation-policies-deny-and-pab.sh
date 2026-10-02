# phases/13-organisation-policies-deny-and-pab.sh: setup/13, the organisation-policy baseline B1 to
# B22, the dry runs and their enforcement after 14 days, three deny policies and two principal access
# boundary policies, each proven on a throwaway probe project before it reaches production.
#
# How the page maps onto the classes:
# - The reads and inventories (OP-0.1, OP-1.1 to OP-1.4, OP-3.3, OP-8.1, OP-8.6) are AUTO-READ.
# - The policy files the page builds with its jq helpers `pol`, `dry` and `rsu` (OP-2.1 to OP-2.4) are
#   AUTO: the phase writes the same JSON with python3 and xw, and the check regenerates and compares.
# - OP-2.1's policies/HELD.md is the page's here-document, written from assets/op-2.1-held.md
#   (assets/13.manifest), so the tests compare it with the page byte for byte.
# - OP-0.3 (op-set.sh) and OP-2.5 (the custom constraints and deny policies) are here-documents on the
#   page that the person pastes, so both are HUMAN. OP-2.5's expand shell variables, so they cannot be
#   copied as assets. OP-0.3's could, but the offline tests' fake gcloud cannot return the policy a
#   set-policy call was given, so the page's read-back would fail every apply after it; it stays a paste.
# - Every grant approval, review, merge, signature, git-host workflow run and initialled record is HUMAN;
#   the SCC readings that IT security co-signs are CONSOLE with a witness.
# - Every organisation-policy change runs the committed policies/tools/op-set.sh, as the page does, so
#   the predecessor of each policy is saved before it changes.
# - Live enforcement at an attachment point (a policy `spec`, a deny policy, a PAB policy or binding) is
#   --irreversible, as are the probe project id and its HSM key ring (the page's IRREVERSIBLE).
# - OP-7.3 mints an access token for op-probe-target@ (the page filters it with jq): HUMAN, so that no
#   credential ever passes through the script.
# - The negative tests (OP-5.3 to OP-5.6, OP-6.5's re-run, OP-8.5) run the page's commands through x,
#   read the refusal text for the constraint the page names, and write a record ending in RESULT PASS
#   or RESULT FAIL. Their check is that record. An accepted command is rolled back as the page says, and
#   the step returns 98: the page stops the file there until a person has read the effective policy.
# - The page's other STOPs for a person also return 98: an issuer that is not GIT_OIDC_ISSUER (OP-2.3),
#   Google's supported-services list not yet saved by hand (OP-2.4), a blind dry-run window (OP-5.4), deny
#   rules read back unlike the committed file (OP-7.4 to OP-7.6), the 14-day window not yet over (OP-8.1),
#   and the core checks a person runs after KMS_PROJECT is enforced (OP-8.4).
# - Values are decided by robust reads: a filtered `list` that prints something, or the exit status of
#   `describe`. A policy's state (dry run or enforced) and an effective value are read as the attachment
#   point's own policy (`org-policies list --filter`), and an inherited value as "no folder below the
#   attachment point holds its own policy" along 09's expected tree (_p13_inherits). The page's
#   `describe --effective` reads are still made and recorded beside them.
# - A read inside _apply that decides what to do, or asserts that something is absent, goes through
#   _p13_pre, which marks it as a check, as phases 15 and 42 do.
# - Every check starts with ckpt_done: a later run must never re-apply a dry run that §8 enforced, nor
#   a nonprod copy that OP-6.5 removed.
# - No `requires`, deliberately: the page's preconditions say "nothing here runs on standing roles". Every
#   permission this phase uses on the organisation, a folder or a core project (organisation policies,
#   deny and PAB policies, the reads of §1 and §8) comes from a PAM grant (OP-0.2's ENT_PLATFORM_POLICY,
#   ENT_PROJECT_REPAIR_CORE, ENT_BOOTSTRAP_MODULE_IMPROVERS_NONPROD), so preflight's testIamPermissions
#   before the grant exists would rightly find none of them; a `requires` line would make preflight fail
#   on the very absence the page proves. The five create steps of §7 test the live grant themselves (the
#   page's op_grant_guard), and OP-0.2's VERIFY is the same testIamPermissions read, done by a person.
# - The B19 parameter name OP-1.2 reads from the catalogue is kept as B19_PARAM and recorded in the note
#   of OP-1.2's DONE checkpoint, as the page says; OP-2.3 reads B19_PARAM (the page's `need B19_PARAM`).
# - The by-hand lists of Google's supported services and deny-supported permissions are read as the newest
#   saved (policies/tools/*-<date>.txt), as the page says, so a re-run on a later day finds them.
# - OP-1.1 and OP-8.1 register their record directory through its SHA256SUMS file, so the evidence row
#   carries a hash (42 GD-4.1).
# - The fixed waits of the page (OP-3.3's hour, OP-5.3's 15 minutes, OP-5.4's 5 to 15 minutes, OP-8.4's
#   10 minutes per folder) are multiplied by AGP_WAIT_SCALE, a whole number, 1 when unset. Only the
#   offline tests set it, to 0; a value other than 1 is announced on every wait. The 14-day dry-run window
#   of §8 is a decision date, not a wait, and is never scaled.
#
# Helpers are prefixed _p13_ because every phase file is loaded into the same shell.

phase 13 "Organisation policies, deny policies and principal access boundaries" "13-organisation-policies-deny-and-pab.md"

P13_PROBE="agp-imp-opprobe-nonprod"   # fixed by the page (OP-2.1, §5); not a variable of plan §5
P13_FLDS="FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE FLD_GEMINI_ENTERPRISE FLD_AGENTS_R FLD_AGENTS_R_PROD FLD_AGENTS_R_NONPROD FLD_AGENTS_W FLD_AGENTS_W_PROD FLD_AGENTS_W_NONPROD FLD_AGENTS_P FLD_AGENTS_P_PROD FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD FLD_AGENTS_X FLD_CONTROLLERS FLD_CONTROLLERS_PROD FLD_CONTROLLERS_NONPROD FLD_IMPROVERS FLD_IMPROVERS_PROD FLD_IMPROVERS_NONPROD"
P13_CORE="CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT"
P13_LEGACY="gcp.resourceLocations iam.automaticIamGrantsForDefaultServiceAccounts iam.allowedPolicyMemberDomains iam.disableCrossProjectServiceAccountUsage storage.uniformBucketLevelAccess storage.publicAccessPrevention gcp.detailedAuditLoggingMode compute.vmExternalIpAccess compute.skipDefaultNetworkCreation sql.restrictPublicIp cloudkms.allowedProtectionLevels cloudkms.disableBeforeDestroy cloudkms.minimumDestroyScheduledDuration"
P13_DRYLOG='protoPayload.metadata.dryRunResult="DENIED" AND protoPayload.metadata.liveResult="ALLOWED"'
P13_B1='spec.rules.values.allowedValues="in:eu-locations" AND spec.rules.values.allowedValues="is:europe"'   # B1, as a list filter

# ---------------------------------------------------------------- JSON and file helpers (python3, no jq)
P13_PY='
import json, os, sys, glob, calendar, time, datetime

def dump(o):
    return json.dumps(o, indent=2) + "\n"

def load(p):
    with open(p) as f:
        return json.load(f)

def stdin_json():
    raw = sys.stdin.read()
    return json.loads(raw) if raw.strip() else {}

def wr(out, rel, text):
    p = os.path.join(out, rel)
    d = os.path.dirname(p)
    if not os.path.isdir(d):
        os.makedirs(d)
    with open(p, "w") as f:
        f.write(text)

def pol(out, rel, name, spec):
    wr(out, rel, dump({"name": name, "spec": spec}))

def dry(out, rel, name, spec):
    wr(out, rel, dump({"name": name, "dryRunSpec": spec}))

ENF = {"rules": [{"enforce": True}]}

def gen(step, out, V):
    if step == "OP-2.1":
        legacy = [
            ("gcp.resourceLocations", {"rules": [{"values": {"allowedValues": ["in:eu-locations", "is:europe"]}}]}),
            ("iam.automaticIamGrantsForDefaultServiceAccounts", ENF),
            ("iam.allowedPolicyMemberDomains", {"rules": [{"values": {"allowedValues": [V["DIRECTORY_CUSTOMER_ID"]]}}]}),
            ("iam.disableCrossProjectServiceAccountUsage", ENF),
            ("storage.uniformBucketLevelAccess", ENF),
            ("storage.publicAccessPrevention", ENF),
            ("gcp.detailedAuditLoggingMode", ENF),
            ("compute.vmExternalIpAccess", {"rules": [{"denyAll": True}]}),
            ("compute.skipDefaultNetworkCreation", ENF),
            ("sql.restrictPublicIp", ENF),
            ("cloudkms.allowedProtectionLevels", {"rules": [{"values": {"allowedValues": ["is:HSM"]}}]}),
            ("cloudkms.disableBeforeDestroy", ENF),
            ("cloudkms.minimumDestroyScheduledDuration", {"rules": [{"values": {"allowedValues": ["in:30d"]}}]}),
        ]
        for t in ("FLD_IMPROVERS_NONPROD", "FLD_AGENTIC_PLATFORM"):
            for c, spec in legacy:
                pol(out, "policies/org/%s/%s.json" % (t, c), "folders/%s/policies/%s" % (V[t], c), spec)
        egress = {"rules": [{"values": {"allowedValues": ["private-ranges-only"]}}]}
        binauthz = {"rules": [{"values": {"allowedValues": ["default"]}}]}
        for t in ("FLD_AGENTS_W_NONPROD", "FLD_AGENTS_P_NONPROD", "FLD_CONTROLLERS_NONPROD", "FLD_AGENTS_W", "FLD_AGENTS_P", "FLD_CONTROLLERS"):
            pol(out, "policies/org/%s/run.allowedVPCEgress.json" % t, "folders/%s/policies/run.allowedVPCEgress" % V[t], egress)
            pol(out, "policies/org/%s/run.allowedBinaryAuthorizationPolicies.json" % t, "folders/%s/policies/run.allowedBinaryAuthorizationPolicies" % V[t], binauthz)
        pol(out, "policies/org/FLD_PLATFORM_CORE/run.allowedBinaryAuthorizationPolicies.json", "folders/%s/policies/run.allowedBinaryAuthorizationPolicies" % V["FLD_PLATFORM_CORE"], binauthz)
        pol(out, "policies/probe/run.allowedVPCEgress.json", "projects/%s/policies/run.allowedVPCEgress" % V["PROBE"], egress)
        pol(out, "policies/probe/run.allowedBinaryAuthorizationPolicies.json", "projects/%s/policies/run.allowedBinaryAuthorizationPolicies" % V["PROBE"], binauthz)
        with open(V["HELD"]) as f:   # the here-document of the page, saved as assets/op-2.1-held.md
            wr(out, "policies/HELD.md", f.read())
    elif step == "OP-2.2":
        pol(out, "policies/org/FLD_AGENTIC_PLATFORM/iam.managed.disableAccessPolicyBinding.json",
            "folders/%s/policies/iam.managed.disableAccessPolicyBinding" % V["FLD_AGENTIC_PLATFORM"], ENF)
        for t in ("FLD_AGENTS_R", "FLD_AGENTS_W", "FLD_AGENTS_P", "FLD_CONTROLLERS"):
            pol(out, "policies/org/%s/iam.managed.disableAccessPolicyBinding.json" % t,
                "folders/%s/policies/iam.managed.disableAccessPolicyBinding" % V[t], {"rules": [{"enforce": False}]})
        f, p = V["FLD_AGENTIC_PLATFORM"], "policies/dryrun/FLD_AGENTIC_PLATFORM/"
        dry(out, p + "iam.managed.disableServiceAccountKeyCreation.json", "folders/%s/policies/iam.managed.disableServiceAccountKeyCreation" % f, ENF)
        dry(out, p + "iam.managed.disableServiceAccountKeyUpload.json", "folders/%s/policies/iam.managed.disableServiceAccountKeyUpload" % f, ENF)
        dry(out, p + "essentialcontacts.managed.allowedContactDomains.json", "folders/%s/policies/essentialcontacts.managed.allowedContactDomains" % f,
            {"rules": [{"enforce": True, "parameters": {"allowedDomains": ["@" + V["DOMAIN"]]}}]})
        dry(out, p + "gcp.restrictTLSVersion.json", "folders/%s/policies/gcp.restrictTLSVersion" % f,
            {"rules": [{"values": {"deniedValues": ["TLS_VERSION_1", "TLS_VERSION_1_1"]}}]})
    elif step == "OP-2.3":
        wr(out, "policies/dryrun/FLD_PLATFORM_CORE/iam.managed.workloadIdentityPoolProviders.json", dump(
            {"name": "folders/%s/policies/iam.managed.workloadIdentityPoolProviders" % V["FLD_PLATFORM_CORE"],
             "dryRunSpec": {"rules": [{"enforce": True, "parameters": {V["B19_PARAM"]: [V["GIT_OIDC_ISSUER"]]}}]}}))
    elif step == "OP-2.4":
        ctrl = "securitycenter securitycentermanagement privilegedaccessmanager policyanalyzer"
        r_list = "aiplatform apphub modelarmor iap networkservices networksecurity dns compute discoveryengine storage bigquery cloudtrace apptopology cloudapiregistry notebooks texttospeech dataform pubsub"
        w_list = r_list + " run secretmanager cloudkms firestore cloudtasks cloudscheduler cloudbuild artifactregistry binaryauthorization"
        def rsu(var, res, inh, svcs):
            vals = sorted(set("%s.googleapis.com" % s for s in svcs.split()))
            wr(out, "policies/dryrun/%s/gcp.restrictServiceUsage.json" % var, dump(
                {"name": "%s/policies/gcp.restrictServiceUsage" % res,
                 "dryRunSpec": {"inheritFromParent": inh, "rules": [{"values": {"allowedValues": vals}}]}}))
        rsu("FLD_PLATFORM_CORE", "folders/" + V["FLD_PLATFORM_CORE"], False, "bigquery bigquerydatatransfer storage cloudbuild artifactregistry containeranalysis binaryauthorization apphub pubsub run cloudscheduler iap cloudkms dlp " + ctrl)
        rsu("KMS_PROJECT", "projects/" + V["KMS_PROJECT"], False, "cloudkms " + ctrl)
        rsu("FLD_AGENTS_R", "folders/" + V["FLD_AGENTS_R"], False, r_list + " " + ctrl)
        rsu("FLD_AGENTS_R_NONPROD", "folders/" + V["FLD_AGENTS_R_NONPROD"], True, "run")
        rsu("FLD_AGENTS_W", "folders/" + V["FLD_AGENTS_W"], False, w_list + " " + ctrl)
        rsu("FLD_AGENTS_P", "folders/" + V["FLD_AGENTS_P"], False, w_list + " accessapproval " + ctrl)
        rsu("FLD_AGENTS_P_SA", "folders/" + V["FLD_AGENTS_P_SA"], False, "aiplatform discoveryengine run cloudbuild artifactregistry binaryauthorization secretmanager firestore cloudscheduler cloudtasks pubsub bigquery cloudkms storage modelarmor networkservices networksecurity compute dns iap apphub apptopology cloudapiregistry notebooks texttospeech dataform cloudtrace accessapproval " + ctrl)
        rsu("FLD_CONTROLLERS", "folders/" + V["FLD_CONTROLLERS"], False, "run cloudscheduler bigquery bigquerydatatransfer storage cloudkms secretmanager iap pubsub aiplatform modelarmor binaryauthorization compute " + ctrl)
        rsu("FLD_IMPROVERS", "folders/" + V["FLD_IMPROVERS"], False, "bigquery bigquerydatatransfer storage run cloudscheduler artifactregistry pubsub " + ctrl)
        wr(out, "policies/dryrun/FLD_AGENTS_X/gcp.restrictServiceUsage.json", dump(
            {"name": "folders/%s/policies/gcp.restrictServiceUsage" % V["FLD_AGENTS_X"], "dryRunSpec": {"rules": [{"denyAll": True}]}}))
    else:
        sys.exit("gen: unknown step " + step)

def polname(p):
    name = load(p)["name"]
    res, con = name.split("/policies/", 1)
    kind, ident = res.split("/", 1)
    flag = {"folders": "--folder", "projects": "--project", "organizations": "--organization"}[kind]
    print("%s\t%s=%s" % (con, flag, ident))

def policies_of(d):
    if isinstance(d, list):
        return d
    if isinstance(d, dict):
        return d.get("policies", []) or []
    return []

def catalogue(files):
    cons = []
    for p in files:
        cons += load(p).get("constraints", []) or []
    plan = ["gcp.resourceLocations", "iam.managed.disableServiceAccountKeyCreation", "iam.managed.disableServiceAccountKeyUpload",
            "iam.automaticIamGrantsForDefaultServiceAccounts", "iam.allowedPolicyMemberDomains", "iam.disableCrossProjectServiceAccountUsage",
            "iam.managed.disableAccessPolicyBinding", "storage.uniformBucketLevelAccess", "storage.publicAccessPrevention",
            "gcp.detailedAuditLoggingMode", "compute.vmExternalIpAccess", "compute.skipDefaultNetworkCreation", "sql.restrictPublicIp",
            "essentialcontacts.managed.allowedContactDomains", "gcp.restrictServiceUsage", "run.allowedIngress", "run.allowedVPCEgress",
            "run.allowedBinaryAuthorizationPolicies", "iam.managed.workloadIdentityPoolProviders", "gcp.restrictNonCmekServices",
            "gcp.restrictCmekCryptoKeyProjects", "cloudkms.allowedProtectionLevels", "cloudkms.disableBeforeDestroy",
            "cloudkms.minimumDestroyScheduledDuration", "gcp.restrictTLSVersion"]
    want_dry = set(["iam.managed.disableServiceAccountKeyCreation", "iam.managed.disableServiceAccountKeyUpload",
                    "iam.managed.disableAccessPolicyBinding", "essentialcontacts.managed.allowedContactDomains",
                    "gcp.restrictServiceUsage", "iam.managed.workloadIdentityPoolProviders", "gcp.restrictTLSVersion"])
    bad = 0
    for c in plan:
        hit = [x for x in cons if str(x.get("name", "")).endswith("/constraints/" + c)]
        if not hit:
            print("%s\tNOT-LISTED" % c); bad = 1; continue
        x = hit[0]
        dr = bool(x.get("supportsDryRun", False))
        typ = "list" if x.get("listConstraint") is not None else ("boolean" if x.get("booleanConstraint") is not None else "other")
        params = sorted(((x.get("booleanConstraint") or {}).get("customConstraintDefinition") or {}).get("parameters", {}).keys())
        print("%s\tdryRun=%s\ttype=%s\tparams=%s" % (c, "true" if dr else "false", typ, ",".join(params)))
        if dr != (c in want_dry):
            print("STOP: %s dryRun=%s differs from the constraint plan" % (c, dr)); bad = 1
        if c == "essentialcontacts.managed.allowedContactDomains" and params != ["allowedDomains"]:
            print("STOP: B14 parameters are [%s], not allowedDomains" % ",".join(params)); bad = 1
        if c == "iam.managed.workloadIdentityPoolProviders":
            if len(params) == 1:
                print("B19PARAM\t" + params[0])
            else:
                print("STOP: B19 has %d parameters, not exactly one" % len(params)); bad = 1
    sys.exit(bad)

def rules_norm(d):
    return json.dumps(d.get("rules", []), sort_keys=True)

def main():
    a = sys.argv[1:]
    cmd = a[0]
    if cmd == "gen":
        V = dict(kv.split("=", 1) for kv in a[3:])
        gen(a[1], a[2], V)
    elif cmd == "polname":
        polname(a[1])
    elif cmd == "names":
        for p in a[1:]:
            for x in policies_of(load(p)):
                print(x.get("name", ""))
    elif cmd == "nextpage":
        print(stdin_json().get("nextPageToken", ""))
    elif cmd == "catalogue":
        catalogue(a[1:])
    elif cmd == "rules-equal":
        sys.exit(0 if rules_norm(load(a[1])) == rules_norm(load(a[2])) else 1)
    elif cmd == "enforce":
        rules = (stdin_json().get("spec") or {}).get("rules") or [{}]
        e = rules[0].get("enforce")
        print("none" if e is None else ("true" if e else "false"))
    elif cmd == "values":
        rules = (stdin_json().get("spec") or {}).get("rules") or []
        print(" ".join(v for r in rules for v in (r.get("values") or {}).get("allowedValues", [])))
    elif cmd == "allowed":
        d = load(a[1])
        for r in (d.get("dryRunSpec") or d.get("spec") or {}).get("rules", []):
            for v in (r.get("values") or {}).get("allowedValues", []):
                print(v)
    elif cmd == "denyperms":
        out = set()
        for p in a[1:]:
            for r in load(p).get("rules", []):
                out.update((r.get("denyRule") or {}).get("deniedPermissions", []))
        for p in sorted(out):
            print(p)
    elif cmd == "no-member":
        b = [(x.get("role"), m) for x in stdin_json().get("bindings", []) for m in x.get("members", [])]
        held = [r for r, m in b if m == a[1]]
        print("== roles of %s: [%s]" % (a[1], " ".join(held)))
        sys.exit(0 if not held else 1)
    elif cmd == "only-binding":
        b = [(x.get("role"), m) for x in stdin_json().get("bindings", []) for m in x.get("members", [])]
        sys.exit(0 if b == [(a[2], a[1])] else 1)
    elif cmd == "effrow":
        d = stdin_json()
        print(json.dumps({"spec": (d.get("spec") or {}).get("rules"), "dry": d.get("dryRunSpec") is not None}, separators=(",", ":")))
    elif cmd == "summary":
        rows = {}
        for p in sorted(glob.glob(os.path.join(a[1], "*.json"))):
            for e in policies_of(load(p)):
                pp = e.get("protoPayload") or {}
                k = ((e.get("resource") or {}).get("labels") or {}).get("project_id", "folder"), pp.get("serviceName", ""), pp.get("methodName", "")
                rows[k] = rows.get(k, 0) + 1
        for k, n in sorted(rows.items(), key=lambda kv: -kv[1]):
            print("%7d %s" % (n, "\t".join(k)))
    elif cmd == "ckpt-epoch":
        t = ""
        with open(a[2]) as f:
            for line in f:
                c = line.rstrip("\n").split("\t")
                if len(c) > 2 and c[1] == a[1] and c[2] == "DONE":
                    t = c[0]
        print(calendar.timegm(time.strptime(t, "%Y-%m-%dT%H:%M:%SZ")) if t else "")
    elif cmd == "plus-days":
        print((datetime.datetime.utcnow().date() + datetime.timedelta(days=int(a[1]))).isoformat())
    elif cmd == "fmt-epoch":
        print(time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(int(a[1]))))
    elif cmd == "cal-end":
        end = ""
        with open(a[1]) as f:
            for line in f:
                c = [x.strip() for x in line.split("|")]
                if len(c) > 3 and c[1] == "13-dryrun":
                    end = c[3]
        print(end)
    else:
        sys.exit("p13: unknown command " + cmd)

main()
'
_p13_py() { python3 -c "$P13_PY" "$@"; }

_p13_repo() { v PLATFORM_REPO_DIR; }
_p13_today() { date -u +%Y-%m-%d; }

_p13_read() {   # a read whose output a step uses: shown in plan mode (returns 3), run in apply mode
  if [ "$AGP_MODE" != apply ]; then printf '      read: %s\n' "$(agp_quote "$@")" >&3; return 3; fi
  r "$@"
}

_p13_recpath() {    # STEP SLUG EXT: the next free records/<date>-STEP-SLUG-vN[.EXT] path of today
  local d n=1 base; d="$(v BUILD_LOG_DIR)/records"; base="$d/$(_p13_today)-$1-$2-v"
  while [ -e "$base$n${3:+.$3}" ]; do n=$((n + 1)); done
  printf '%s' "$base$n${3:+.$3}"
}

_p13_passed() {     # STEP SLUG: a record of the step ends in RESULT PASS
  local f
  for f in "$(v BUILD_LOG_DIR)"/records/*-"$1"-"$2"-v*; do
    [ -f "$f" ] && grep -qx 'RESULT PASS' "$f" && return 0
  done
  return 1
}

_p13_save() {       # STEP SLUG EXT TISAX VERDICT_FILE: writes the record, registers it, returns 0 on PASS
  local p; p="$(_p13_recpath "$1" "$2" "$3")"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      would write records/$(basename "$p")"; ev "$1" "$2" E-05 "$4" "build-log:records/$(basename "$p")"; return 0
  fi
  x mkdir -p "$(dirname "$p")" || return 1
  xw "$p" < "$5" || return 1
  ev "$1" "$2" E-05 "$4" "build-log:records/$(basename "$p")" "$p" || return 1
  grep -qx 'RESULT PASS' "$p"
}

_p13_need_done() {  # STEP WHY: the page's checkpoint gate; in apply mode a missing DONE stops the step
  ckpt_done "$1" && return 0
  if [ "$AGP_MODE" = apply ]; then agp_say "      STOP: $1 is not DONE ($2); nothing below runs"; return 1; fi
  agp_say "      gate: runs only when $1 is DONE ($2)"
  return 0
}

_p13_after() {      # STEP SECONDS WHY: at least SECONDS since STEP's DONE checkpoint
  local t now w
  _p13_need_done "$1" "$3" || return 1
  [ "$AGP_MODE" = apply ] || { agp_say "      wait: at least $(($2 / 60)) minutes after $1 ($3)"; return 0; }
  t="$(_p13_py ckpt-epoch "$1" "$(v BUILD_LOG_DIR)/checkpoints.tsv")"; now="$(date -u +%s)"; w="$(_p13_scale "$2")"
  [ -n "$t" ] || { agp_say "      STOP: no DONE time for $1"; return 1; }
  if [ $((now - t)) -lt "$w" ]; then
    agp_say "      STOP: $3. Wait until $(_p13_py fmt-epoch $((t + w))), then resume"; return 1
  fi
  return 0
}

_p13_glob() {   # PATTERN: the files it matches, one per line, nothing when none
  local f
  # shellcheck disable=SC2086
  for f in $1; do [ -f "$f" ] && printf '%s\n' "$f"; done
  return 0
}

_p13_gen_args() {   # STEP: the KEY=VALUE arguments _p13_py gen needs for the step
  local n
  case "$1" in
    OP-2.1) for n in FLD_IMPROVERS_NONPROD FLD_AGENTIC_PLATFORM FLD_AGENTS_W_NONPROD FLD_AGENTS_P_NONPROD FLD_CONTROLLERS_NONPROD FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS FLD_PLATFORM_CORE DIRECTORY_CUSTOMER_ID; do printf '%s=%s\n' "$n" "$(v "$n")"; done
            printf 'PROBE=%s\nHELD=%s\n' "$P13_PROBE" "$AGP_HOME/assets/op-2.1-held.md";;
    OP-2.2) for n in FLD_AGENTIC_PLATFORM FLD_AGENTS_R FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS DOMAIN; do printf '%s=%s\n' "$n" "$(v "$n")"; done;;
    OP-2.3) printf 'FLD_PLATFORM_CORE=%s\nGIT_OIDC_ISSUER=%s\nB19_PARAM=%s\n' "$(v FLD_PLATFORM_CORE)" "$(v GIT_OIDC_ISSUER)" "$(v B19_PARAM)";;
    OP-2.4) for n in FLD_PLATFORM_CORE KMS_PROJECT FLD_AGENTS_R FLD_AGENTS_R_NONPROD FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_P_SA FLD_CONTROLLERS FLD_IMPROVERS FLD_AGENTS_X; do printf '%s=%s\n' "$n" "$(v "$n")"; done;;
  esac
}

_p13_gen() {    # STEP OUTDIR: the step's files, generated into OUTDIR (a computation, not a change)
  local args=() line
  while IFS= read -r line; do args[${#args[@]}]="$line"; done <<EOF_P13
$(_p13_gen_args "$1")
EOF_P13
  _p13_py gen "$1" "$2" "${args[@]}"
}

_p13_files_equal() {    # STEP: the repository holds exactly the files the step generates (the check)
  local tmp rc=0 f rel
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/agp-p13.XXXXXX")" || return 2
  _p13_gen "$1" "$tmp" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  while IFS= read -r f; do
    rel="${f#"$tmp"/}"
    cmp -s "$f" "$(_p13_repo)/$rel" || { rc=1; break; }
  done <<EOF_P13
$(find "$tmp" -type f | sort)
EOF_P13
  rm -rf "$tmp"
  return $rc
}

_p13_write_files() {    # STEP: generate, then write each file into the repository with xw
  local tmp f rel dirs="" d n=0
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/agp-p13.XXXXXX")" || return 1
  _p13_gen "$1" "$tmp" || { rm -rf "$tmp"; agp_say "      STOP: the files could not be generated"; return 1; }
  while IFS= read -r f; do
    rel="${f#"$tmp"/}"; d="$(dirname "$rel")"; n=$((n + 1))
    case " $dirs " in *" $d "*) ;; *) dirs="$dirs $d";; esac
  done <<EOF_P13
$(find "$tmp" -type f | sort)
EOF_P13
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      would write $n files in $(_p13_repo):"
    for d in $dirs; do agp_say "        $d/  files: $(find "$tmp/$d" -maxdepth 1 -type f | wc -l | tr -d ' ')"; done
    rm -rf "$tmp"; return 0
  fi
  for d in $dirs; do x mkdir -p "$(_p13_repo)/$d" || { rm -rf "$tmp"; return 1; }; done
  while IFS= read -r f; do
    rel="${f#"$tmp"/}"
    xw "$(_p13_repo)/$rel" < "$f" || { rm -rf "$tmp"; return 1; }
  done <<EOF_P13
$(find "$tmp" -type f | sort)
EOF_P13
  rm -rf "$tmp"
}

_p13_scale() {  # SECONDS: the page's duration times AGP_WAIT_SCALE (a whole number, 1 when unset)
  local s="${AGP_WAIT_SCALE:-1}"
  case "$s" in *[!0-9]*) agp_warn "AGP_WAIT_SCALE '$s' is not a whole number; the page's durations are kept"; s=1;; esac
  [ "$s" = 1 ] || agp_say "      AGP_WAIT_SCALE=$s: the page's $1 s wait becomes $(($1 * s)) s (offline tests only)"
  printf '%s' $(($1 * s))
}

_p13_sleep() {  # SECONDS: a wait the page prescribes, scaled by AGP_WAIT_SCALE
  local t; t="$(_p13_scale "$1")"
  [ "$t" -gt 0 ] || return 0
  sleep "$t"
}

_p13_opset() {  # EXPECTED FILE...: the page's loop over op-set.sh; one bad file stops the batch
  local want="$1" tool n=0 f; shift
  tool="$(_p13_repo)/policies/tools/op-set.sh"
  if [ "$AGP_MODE" = apply ]; then
    [ -x "$tool" ] || { agp_say "      STOP: $tool is missing or not executable (OP-0.3, merged in OP-2.6)"; return 1; }
    for f in "$@"; do [ -f "$f" ] || { agp_say "      STOP: $f is missing (OP-2, merged in OP-2.6); nothing applied"; return 1; }; done
  fi
  for f in "$@"; do
    x "$tool" "$f" || { agp_say "      STOP at $f (op-set.sh: 2 attachment refused, 3 read-back difference, 4 predecessor unreadable)"; break; }
    n=$((n + 1))
  done
  agp_say "      APPLIED-COUNT $n (expected $want)"
  [ "$n" = "$want" ]
}

_p13_pol_args() {   # FILE: "CONSTRAINT SCOPE_FLAG" of a committed policy file
  _p13_py polname "$1" | tr '\t' ' '
}

_p13_all_exist() {  # FILE...: every policy the files name exists at its attachment point (0), or not (1, 2)
  local f a worst=0 rc
  for f in "$@"; do
    [ -f "$f" ] || return 1
    a="$(_p13_pol_args "$f")" || return 2
    # shellcheck disable=SC2086
    exists gcloud org-policies describe $a --format='value(name)'; rc=$?
    [ $rc -eq 0 ] && continue
    [ $rc -eq 1 ] && worst=1 && continue
    return $rc
  done
  return $worst
}

_p13_pre() {    # CMD...: a read inside _apply that decides what to do, or asserts that something is absent. It is
                # marked as a check (gcloud ignores the variable; the offline fakes, which answer every read inside
                # apply as "present", read it), as phases 15 and 42 do.
  AGP_CALL_CONTEXT=check "$@"
}

_p13_own_has() {    # SCOPE_FLAG CONSTRAINT [FILTER [FORMAT]]: the attachment point's own policy for CONSTRAINT exists
                    # (and matches FILTER): a filtered list, 0 listed, 1 not, 2 error, 3 offline
  nonempty r gcloud org-policies list "$1" --filter="name~\"/policies/$2\$\"${3:+ AND $3}" --format="${4:-value(name)}"
}

_p13_all_state() {  # WANT FILE...: every policy is in state WANT (spec: enforced, no dry run; dry: dry run only).
                    # Every file is read (none is skipped after a first miss); 0 all, 1 one is not, 2 error, 3 offline
  local want="$1" f a con flag frm rc worst=0; shift
  [ "$AGP_OFFLINE" = 1 ] && return 3
  case "$want" in spec) frm="spec:* AND NOT dryRunSpec:*";; dry) frm="dryRunSpec:* AND NOT spec:*";; *) return 2;; esac
  for f in "$@"; do
    [ -f "$f" ] || { worst=1; continue; }
    a="$(_p13_pol_args "$f")" || return 2
    con="${a%% *}"; flag="${a#* }"
    _p13_own_has "$flag" "$con" "$frm"; rc=$?
    case $rc in 0) ;; 1) worst=1;; *) return $rc;; esac
  done
  return $worst
}

_p13_enforced_since() {   # FILE: the policy is enforced at its attachment point; prints since when (OP-8.4's resume)
  local a; a="$(_p13_pol_args "$1")" || return 2
  _p13_own_has "${a#* }" "${a%% *}" "spec:* AND NOT dryRunSpec:*" "value(name,spec.updateTime)"
}

_p13_parent() {     # FLD_VAR: its parent in 09's expected tree (empty for FLD_AGENTIC_PLATFORM)
  case "$1" in
    FLD_AGENTIC_PLATFORM) ;;
    FLD_*_PROD|FLD_*_NONPROD) printf '%s' "${1%_*}";;
    FLD_AGENTS_P_SA) printf 'FLD_AGENTS_P';;
    FLD_*) printf 'FLD_AGENTIC_PLATFORM';;
  esac
}

_p13_inherits() {   # CONSTRAINT FILTER ANCESTOR_VAR CHILD_VAR: CHILD's effective value is ANCESTOR's: no folder from
                    # CHILD up to ANCESTOR (excluded) holds its own policy, and ANCESTOR's own matches FILTER.
                    # The page reads `describe --effective`; that read is recorded too, this one decides.
  local n="$4" rc
  while [ "$n" != "$3" ]; do
    [ -n "$n" ] || { agp_say "      $4 is not under $3 in 09's tree"; return 2; }
    _p13_pre _p13_own_has --folder="$(v "$n")" "$1"; rc=$?
    case $rc in 1) ;; 0) agp_say "      $n holds its own $1 policy"; return 1;; *) return $rc;; esac
    n="$(_p13_parent "$n")"
  done
  _p13_own_has --folder="$(v "$3")" "$1" "$2"
}

_p13_refused() {    # LOG LABEL CONSTRAINT_REGEX CMD...: a command the page expects to be refused, naming the constraint
  local log="$1" label="$2" con="$3" err rc; shift 3
  if [ "$AGP_MODE" != apply ]; then x "$@"; agp_say "        expected: refused, naming $con"; return 0; fi
  err="$(mktemp "${TMPDIR:-/tmp}/agp-p13.XXXXXX")" || return 2
  x "$@" 2>"$err"; rc=$?
  { printf '== %s: %s\n' "$label" "$(agp_quote "$@")"; sed 's/^ *//' "$err"; } >> "$log"
  if [ $rc -eq 0 ]; then
    printf '%s ACCEPTED, refusal expected\n' "$label" >> "$log"; rm -f "$err"
    agp_say "      FAIL $label: accepted; it must be refused ($con)"; return 1
  fi
  if grep -qE "$con" "$err"; then
    printf '%s REFUSED naming %s\n' "$label" "$(grep -oE "$con" "$err" | head -1)" >> "$log"; rm -f "$err"
    agp_say "      $label refused, naming $con, as required (the FAILED line above is the expected refusal)"; return 0
  fi
  printf '%s REFUSED, but the error does not name %s\n' "$label" "$con" >> "$log"; rm -f "$err"
  agp_say "      FAIL $label: refused, but the error does not name $con; read it above"; return 2
}

_p13_newlog() { mktemp "${TMPDIR:-/tmp}/agp-p13-rec.XXXXXX"; }

_p13_finish() {     # LOG BAD STEP SLUG EXT TISAX: verdict line, record, evidence; 0 only on PASS
  local log="$1" bad="$2"
  if [ "$AGP_MODE" = apply ]; then
    if [ "$bad" = 0 ]; then echo "RESULT PASS" >> "$log"; else echo "RESULT FAIL" >> "$log"; fi
  fi
  _p13_save "$3" "$4" "$5" "$6" "$log"; local rc=$?
  rm -f "$log"
  [ "$AGP_MODE" = apply ] || return 0
  [ "$bad" = 0 ] && [ $rc -eq 0 ]
}

_p13_stop_accepted() {  # ACCEPTED WHAT: the page's STOP when a refusal it expects did not happen (rolled back above)
  [ "$AGP_MODE" = apply ] && [ "$1" = 1 ] || return 0
  agp_say "      STOP: an expected refusal did not happen (rolled back above, where the page has a rollback). The page stops"
  agp_say "        the file here: $2. Resume once a person has done so."
  return 1
}

_p13_sa_create() {  # NAME PROJECT_VAR_VALUE DISPLAY: a service account, unless it exists
  local email="$1@$2.iam.gserviceaccount.com" rc
  if [ "$AGP_MODE" = apply ]; then
    _p13_pre exists gcloud iam service-accounts describe "$email" --project="$2" --format='value(email)'; rc=$?
    [ $rc -eq 0 ] && { agp_say "      $email exists; not created again"; return 0; }
    [ $rc -eq 1 ] || return 1
  fi
  x gcloud iam service-accounts create "$1" --display-name="$3" --project="$2"
}

_p13_bucket_create() {  # BUCKET PROJECT LOCATION: a uniform-access bucket, unless it exists
  local rc
  if [ "$AGP_MODE" = apply ]; then
    _p13_pre exists gcloud storage buckets describe "$1" --project="$2" --format='value(name)'; rc=$?
    [ $rc -eq 0 ] && { agp_say "      $1 exists; not created again"; return 0; }
    [ $rc -eq 1 ] || return 1
  fi
  x gcloud storage buckets create "$1" --project="$2" --location="$3" --uniform-bucket-level-access
}

_p13_grant_guard() {    # the page's op_grant_guard: the ENT_PLATFORM_POLICY grant is live; prints the grant
  local b out miss g
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      guard (op_grant_guard): testIamPermissions on organizations/$(v ORG_ID) holds iam.denypolicies.create and"
    agp_say "        iam.principalaccessboundarypolicies.create, and an ACTIVE grant on ENT_PLATFORM_POLICY is listed"
    return 0
  fi
  b="$(mktemp "${TMPDIR:-/tmp}/agp-p13.XXXXXX")" || return 1
  printf '{"permissions":["iam.denypolicies.create","iam.principalaccessboundarypolicies.create"]}' > "$b"
  out="$(api POST "https://cloudresourcemanager.googleapis.com/v3/organizations/$(v ORG_ID):testIamPermissions" "$b")" \
    || { rm -f "$b"; agp_say "      STOP: testIamPermissions failed; nothing created"; return 1; }
  rm -f "$b"
  miss="$(printf '%s' "$out" | python3 "$AGP_HOME/lib/agp_json.py" missing iam.denypolicies.create iam.principalaccessboundarypolicies.create)"
  [ -z "$miss" ] || { agp_say "      STOP: no ACTIVE grant on ENT_PLATFORM_POLICY (OP-0.2); nothing created"; return 1; }
  g="$(r gcloud pam grants search --entitlement="$(v ENT_PLATFORM_POLICY)" --caller-relationship=had-created --filter="state=ACTIVE" \
        --billing-project="$(v CICD_PROJECT)" --format="value(name,requestTime)")"
  [ -n "$g" ] || { agp_say "      STOP: no ACTIVE grant listed; nothing created"; return 1; }
  agp_say "      grant: $g"
  P13_GRANT="$g"
}

_p13_grant_record() {   # STEP: the grant name the guard listed, as a record beside the step's evidence
  local f
  [ "$AGP_MODE" = apply ] || return 0
  x mkdir -p "$(v BUILD_LOG_DIR)/records" || return 1
  f="$(_p13_newlog)" || return 1
  printf 'step %s ran under the ENT_PLATFORM_POLICY grant: %s\nRecord the approver from the PAM ApproveGrant audit entry beside it.\n' "$1" "${P13_GRANT-}" > "$f"
  xw "$(_p13_recpath "$1" grant txt)" < "$f"; local rc=$?
  rm -f "$f"; return $rc
}

_p13_deny_create() {    # STEP POLICY_ID FOLDER_VAR VAR: OP-7.4 to OP-7.6
  local step="$1" id="$2" ap file rec name rc
  ap="cloudresourcemanager.googleapis.com/folders/$(v "$3")"; file="$(_p13_repo)/policies/deny/$id.json"
  _p13_grant_guard || return 1
  if [ "$AGP_MODE" = apply ]; then
    [ -f "$file" ] || { agp_say "      STOP: $file is missing (OP-2.5, merged in OP-2.6)"; return 1; }
    _p13_pre exists gcloud iam policies get "$id" --attachment-point="$ap" --kind=denypolicies --format='value(name)'; rc=$?
  else rc=1; fi
  case $rc in
    0) agp_say "      $id exists at $ap; not created again";;
    1) x gcloud iam policies create "$id" --attachment-point="$ap" --kind=denypolicies --policy-file="$file" --format=json >/dev/null || return 1;;
    *) return 1;;
  esac
  rec="$(_p13_recpath "$step" "$id" json)"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud iam policies get $id --attachment-point=$ap --kind=denypolicies --format=json > records/$(basename "$rec")"
    agp_say "      check: its rules equal $file"
    pset "$4" "<policies/...denypolicies/$id>"
    ev "$step" "$id" E-05 4.2.1 "build-log:records/$(basename "$rec")"; return 0
  fi
  _p13_grant_record "$step" || return 1
  x mkdir -p "$(dirname "$rec")" || return 1
  r gcloud iam policies get "$id" --attachment-point="$ap" --kind=denypolicies --format=json | xw "$rec" || return 1
  if _p13_py rules-equal "$file" "$rec"; then agp_say "      rules-equal"
  else
    agp_say "      STOP: the rules read back ($rec) differ from $file (the page's rules-equal)."
    agp_say "        The policy stays, for diagnosis. A person compares the two and corrects the file by pull request, or records why"
    agp_say "        the difference is one of form only; then resume with $step"
    return 98
  fi
  name="$(r gcloud iam policies get "$id" --attachment-point="$ap" --kind=denypolicies --format='value(name)')"
  [ -n "$name" ] || { agp_say "      FAIL: the policy name could not be read"; return 1; }
  pset "$4" "$name" || return 1
  ev "$step" "$id" E-05 4.2.1 "build-log:records/$(basename "$rec")" "$rec"
}

_p13_deny_check() {     # STEP POLICY_ID FOLDER_VAR VAR
  ckpt_done "$1" && return 0
  exists gcloud iam policies get "$2" --attachment-point="cloudresourcemanager.googleapis.com/folders/$(v "$3")" --kind=denypolicies --format='value(name)' || return $?
  has_value "$4"
}

_p13_pab_create() {     # POLICY_ID RULES_FILE: a PAB policy at the organisation, enforcement version 4, unless it exists
  local rc
  if [ "$AGP_MODE" = apply ]; then
    [ -f "$2" ] || { agp_say "      STOP: $2 is missing (OP-2.5, merged in OP-2.6)"; return 1; }
    _p13_pre exists gcloud iam principal-access-boundary-policies describe "$1" --organization="$(v ORG_ID)" --location=global --format='value(name)'; rc=$?
  else rc=1; fi
  case $rc in
    0) agp_say "      $1 exists; not created again"; return 0;;
    1) x gcloud iam principal-access-boundary-policies create "$1" --organization="$(v ORG_ID)" --location=global \
         --display-name="$1" --details-rules="$2" --details-enforcement-version=4;;
    *) return 1;;
  esac
}

_p13_curl_token() {     # URL CURL_ARGS...: curl with the active account's token on standard input, never in argv
  local url="$1"; shift
  printf 'Authorization: Bearer %s\n' "$(gcloud auth print-access-token 2>/dev/null)" | curl -H @- "$@" "$url"
}

_p13_fld_vars() {   # the FLD_* names of ~/.platform-env, as the page reads them (OP-8.1, OP-8.6)
  grep -o '^export FLD_[A-Z_]*' "$(v PLATFORM_ENV_FILE)" 2>/dev/null | cut -d' ' -f2
}

# ---------------------------------------------------------------- 0. The sitting
step OP-0.1 AUTO-READ "Open the sitting and check the gates" \
  --gate "SD-15 SD-22 SD-24 SD-25 SD-46" \
  --needs "ORG_ID DIRECTORY_CUSTOMER_ID DOMAIN REGION PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER $P13_FLDS PLATFORM_ENV_FILE DRILL_CALENDAR SA_1_ADMIN SCC_TIER TAG_KEY_TIER $P13_CORE SA_FACTORY_APPLY SA_PLATFORM_DRIFT SA_K7_EXECUTOR WIF_PROVIDER TF_STATE_BUCKET GIT_OIDC_ISSUER BILLING_ACCOUNT_ID ENT_PLATFORM_POLICY ENT_PROJECT_REPAIR_CORE ENT_BOOTSTRAP_MODULE_IMPROVERS_NONPROD SECOND_HUMAN_EMAIL PLATFORM_REPO_REMOTE"
s_OP_0_1_check() { ckpt_done OP-0.1; }
s_OP_0_1_apply() {
  local bad=0 acct sr log
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: penv_guard; SCC_TIER is PREMIUM/eu; PA-9.3 (file 12's closing step) is DONE; the active account is SA_1_ADMIN"
    agp_say "      (the five decisions are read by the gate above, with setup/03's decision-need.sh)"
    _p13_save OP-0.1 gates txt 1.2.2 /dev/null; return 0
  fi
  log="$(_p13_newlog)" || return 1
  { penv_guard 2>&1 && echo "guard clean" || { echo "STOP: penv_guard failed"; bad=1; }
    if [ "$(v SCC_TIER)" = "PREMIUM/eu" ]; then echo "SCC gate OK"; else echo "STOP: SCC_TIER is not PREMIUM/eu"; bad=1; fi
    if ckpt_done PA-9.3; then echo "file 12 closed: PA-9.3 DONE"; else echo "STOP: file 12's closing step PA-9.3 is not DONE"; bad=1; fi
    acct="$(r gcloud auth list --filter=status:ACTIVE --format='value(account)')"
    if [ "$acct" = "$(v SA_1_ADMIN)" ]; then echo "account $acct"; else echo "STOP: the active account is '$acct', not SA_1_ADMIN"; bad=1; fi
    sr="$(_penv_get SECURITY_REVIEWER_EMAIL 2>/dev/null)"
    case "$sr" in ''|*tbd*) echo "one-approver mode: security reviewer not appointed";; *) echo "security reviewer: $sr";; esac
  } > "$log"
  sed 's/^/      /' "$log" >&3
  # The page's START line; the runner writes the one DONE line when this returns 0 (the page's
  # one-approver note rides on the START line, so a re-run never finds two DONE lines for OP-0.1).
  if [ $bad = 0 ]; then
    case "$sr" in
      ''|*tbd*) x checkpoint OP-0.1 START - - "one-approver mode: security reviewer not appointed" >/dev/null || bad=1;;
      *) x checkpoint OP-0.1 START >/dev/null || bad=1;;
    esac
  fi
  _p13_finish "$log" "$bad" OP-0.1 gates txt 1.2.2
}

step OP-0.2 HUMAN "Request the ENT_PLATFORM_POLICY grant for this window" \
  --needs "ENT_PLATFORM_POLICY CICD_PROJECT ORG_ID SECOND_HUMAN_EMAIL"
s_OP_0_2_check() { ckpt_done OP-0.2; }
s_OP_0_2_manual() {
  local e c; e="$(v ENT_PLATFORM_POLICY)"; c="$(v CICD_PROJECT)"
  printf 'WHO: the platform owner requests; the approver recorded in 12 (%s; the security reviewer too once appointed) approves. Never the platform owner.\n' "$(v SECOND_HUMAN_EMAIL)"
  printf '$ gcloud pam grants create --entitlement=%s --requested-duration=3600s --justification="setup 13 <PR_URL>" --billing-project=%s\n' "$e" "$c"
  echo "  PR_URL: the merged pull request this window applies (OP-2.6, or OP-8.2 on day 14)."
  printf 'Approver, after opening PR_URL and checking the merge commit (own shell, or console IAM & Admin > Privileged Access Manager > Approve grants):\n'
  printf '$ gcloud pam grants search --entitlement=%s --caller-relationship=can-approve --billing-project=%s --format="table(name,justification.unstructuredJustification)"\n' "$e" "$c"
  printf '$ gcloud pam grants approve "<grant name>" --reason="checked merged commit of <PR_URL>" --billing-project=%s\n' "$c"
  echo "VERIFY: the requester's search shows the grant ACTIVE, and testIamPermissions on the organisation echoes"
  echo "  orgpolicy.policies.create, iam.denypolicies.create and iam.principalaccessboundarypolicies.create (setup/13 OP-0.2)."
  echo "Repeat at the start of every 1-hour window; revoke at its end (OP-0.2 ROLLBACK, or OP-9.3)."
  echo "Then, the first time: agp-platform done OP-0.2"
}

step OP-0.3 HUMAN "Commit the apply and read-back script" --needs "PLATFORM_REPO_DIR"
s_OP_0_3_check() { ckpt_done OP-0.3; }
s_OP_0_3_manual() {
  local t; t="$(_p13_repo)/policies/tools/op-set.sh"
  echo "WHO: the platform owner writes; the required reviewers merge it with the policy files in OP-2.6."
  printf 'WHERE: shell, ~/.platform-env sourced, in %s.\n' "$(_p13_repo)"
  echo "Paste setup/13 OP-0.3's block as the page has it: it writes policies/tools/op-set.sh (the version of 2026-10-01,"
  echo "which compares the read-back by meaning and checks a project policy's name against the project number)."
  echo "The script does not retype the page's here-document; every later policy change runs this file."
  printf "VERIFY: \$ bash -n %s && echo syntax-ok\n" "$t"
  printf "        \$ grep -c 'exit [34]' %s      (prints 2)\n" "$t"
  echo "Then: agp-platform done OP-0.3"
}

# ---------------------------------------------------------------- 1. Read before any change
step OP-1.1 AUTO-READ "Snapshot every existing policy on the organisation and the platform folders" \
  --needs "ORG_ID CORE_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER $P13_FLDS $P13_CORE"
s_OP_1_1_check() { ckpt_done OP-1.1; }
s_OP_1_1_apply() {
  local s n url out tok page found orgloc nonorg base sums
  s="$(_p13_recpath OP-1.1 policy-snapshot "")"
  agp_say "      under an ENT_PROJECT_REPAIR_CORE grant (quota project CORE_PROJECT), and the OP-0.2 grant unless platform-readers@ holds roles/orgpolicy.policyViewer"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: GET https://orgpolicy.googleapis.com/v2/{organizations/<ORG_ID>, folders/<22 FLD_*>, projects/<5 core>}/policies  (x-goog-user-project: $(v CORE_PROJECT))"
    agp_say "      would write records/$(basename "$s")/ (28 files); STOP if a folder or core project holds a policy, or any gcp.resourceLocations exists"
    agp_say "      would write records/$(basename "$s")/SHA256SUMS (the hash of every file in it), registered as the evidence file"
    ev OP-1.1 policy-snapshot E-05 5.2.1 "build-log:records/$(basename "$s")/SHA256SUMS"; return 0
  fi
  x mkdir -p "$s" || return 1
  for n in ORG $P13_FLDS $P13_CORE; do
    case "$n" in
      ORG) url="https://orgpolicy.googleapis.com/v2/organizations/$(v ORG_ID)/policies"; base=organization;;
      FLD_*) url="https://orgpolicy.googleapis.com/v2/folders/$(v "$n")/policies"; base="$n";;
      *) url="https://orgpolicy.googleapis.com/v2/projects/$(v "$n")/policies"; base="$n";;
    esac
    tok=""; page=1
    while :; do
      out="$(AGP_API_PROJECT="$(v CORE_PROJECT)" api GET "$url${tok:+?pageToken=$tok}")" || { agp_say "      READ-ERROR $base"; return 1; }
      if [ $page = 1 ]; then printf '%s\n' "$out" | xw "$s/$base.json" || return 1
      else printf '%s\n' "$out" | xw "$s/$base-p$page.json" || return 1; fi
      tok="$(printf '%s' "$out" | _p13_py nextpage)"
      [ -n "$tok" ] || break
      page=$((page + 1))
    done
  done
  _p13_py names "$s"/*.json | xw "$s/all-policy-names.txt" || return 1
  sums="$(cd "$s" && shasum -a 256 -- *.json all-policy-names.txt)" || { agp_say "      FAIL: the files could not be hashed"; return 1; }
  printf '%s\n' "$sums" | xw "$s/SHA256SUMS" || return 1
  found="$(grep -c . "$s/all-policy-names.txt")"
  orgloc="$(grep -c 'gcp.resourceLocations' "$s/all-policy-names.txt")"
  nonorg="$(grep -vc '^organizations/' "$s/all-policy-names.txt")"
  sed 's/^/        /' "$s/all-policy-names.txt" >&3
  agp_say "      policies found: $found"
  grep -E 'iam.allowedPolicyMemberDomains|iam.automaticIamGrantsForDefaultServiceAccounts|iam.disableServiceAccountKeyCreation|storage.uniformBucketLevelAccess|essentialcontacts.allowedContactDomains' \
    "$s/all-policy-names.txt" | sed 's/^/      organisation baseline (write into the build log): /' >&3
  [ "$nonorg" -eq 0 ] || { agp_say "      STOP: a folder or core project already holds a policy"; return 1; }
  [ "$orgloc" -eq 0 ] || { agp_say "      STOP: a gcp.resourceLocations policy already exists (SD-15 order broken); IT security re-reads SCC first"; return 1; }
  ev OP-1.1 policy-snapshot E-05 5.2.1 "build-log:records/$(basename "$s")/SHA256SUMS" "$s/SHA256SUMS"
}

step OP-1.2 AUTO-READ "Read the constraint catalogue from Google, and stop on any mismatch" \
  --needs "FLD_AGENTIC_PLATFORM CORE_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "B19_PARAM"
s_OP_1_2_check() { ckpt_done OP-1.2; }
s_OP_1_2_apply() {
  local c out tok="" page=1 files="" f res rc url p
  c="$(_p13_recpath OP-1.2 catalogue json)"
  url="https://orgpolicy.googleapis.com/v2/folders/$(v FLD_AGENTIC_PLATFORM)/constraints?pageSize=1000"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: GET $url  (x-goog-user-project: $(v CORE_PROJECT)), into records/$(basename "$c")"
    agp_say "      check: dryRun=true for exactly B2 B3 B7 B14 B15 B19 B22; B14 params=allowedDomains; B19 one parameter, kept as"
    agp_say "        B19_PARAM, which OP-2.3 reads, and recorded as the checkpoint note \"B19 parameter <name>\""
    pset B19_PARAM "<the one B19 parameter name>"
    ev OP-1.2 constraint-catalogue E-05 5.2.1 "build-log:records/$(basename "$c")"; return 0
  fi
  x mkdir -p "$(dirname "$c")" || return 1
  while :; do
    out="$(AGP_API_PROJECT="$(v CORE_PROJECT)" api GET "$url${tok:+&pageToken=$tok}")" || { agp_say "      READ-ERROR: the catalogue could not be read"; return 1; }
    f="$c"; [ $page = 1 ] || f="${c%.json}-p$page.json"
    printf '%s\n' "$out" | xw "$f" || return 1
    files="$files $f"
    tok="$(printf '%s' "$out" | _p13_py nextpage)"
    [ -n "$tok" ] || break
    page=$((page + 1))
  done
  # shellcheck disable=SC2086
  res="$(_p13_py catalogue $files)"; rc=$?
  printf '%s\n' "$res" | sed 's/^/      /' >&3
  [ $rc -eq 0 ] || { agp_say "      STOP: the constraint plan is out of date; a pull request against setup/13 comes first"; return 1; }
  p="$(printf '%s\n' "$res" | awk -F'\t' '$1 == "B19PARAM" {print $2}')"
  [ -n "$p" ] || { agp_say "      STOP: no B19 parameter name"; return 1; }
  pset B19_PARAM "$p" || { agp_say "      STOP: B19_PARAM holds another name: the catalogue changed since it was recorded; a pull request against setup/13 comes first"; return 1; }
  x checkpoint OP-1.2 DONE - - "B19 parameter $p" >/dev/null || return 1
  ev OP-1.2 constraint-catalogue E-05 5.2.1 "build-log:records/$(basename "$c")" "$c"
}

step OP-1.3 AUTO-READ "Read the effective values on the platform folder" \
  --needs "FLD_AGENTIC_PLATFORM BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_1_3_check() { ckpt_done OP-1.3; }
s_OP_1_3_apply() {
  local e c log
  e="$(_p13_recpath OP-1.3 effective-before txt)"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud org-policies describe <C> --folder=$(v FLD_AGENTIC_PLATFORM) --effective --format=json, for 12 constraints"
    ev OP-1.3 effective-before E-05 1.5.1 "build-log:records/$(basename "$e")"; return 0
  fi
  log="$(_p13_newlog)" || return 1
  for c in gcp.resourceLocations iam.allowedPolicyMemberDomains iam.managed.disableAccessPolicyBinding iam.managed.disableServiceAccountKeyCreation iam.managed.disableServiceAccountKeyUpload iam.automaticIamGrantsForDefaultServiceAccounts iam.disableCrossProjectServiceAccountUsage storage.uniformBucketLevelAccess storage.publicAccessPrevention gcp.restrictServiceUsage cloudkms.allowedProtectionLevels gcp.restrictTLSVersion; do
    echo "== $c" >> "$log"
    r gcloud org-policies describe "$c" --folder="$(v FLD_AGENTIC_PLATFORM)" --effective --format=json >> "$log" 2>&1
  done
  x mkdir -p "$(dirname "$e")" && xw "$e" < "$log"; local rc=$?
  rm -f "$log"; [ $rc -eq 0 ] || return 1
  agp_say "      each constraint shows the inherited organisation value (OP-1.1) or the default; later steps compare with it"
  ev OP-1.3 effective-before E-05 1.5.1 "build-log:records/$(basename "$e")" "$e"
}

step OP-1.4 AUTO-READ "Confirm no deny policy or PAB exists yet" \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE CICD_PROJECT CORE_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_1_4_check() { ckpt_done OP-1.4; }
s_OP_1_4_apply() {
  local b log a out p pn bad=0 cnt
  b="$(_p13_recpath OP-1.4 deny-pab-before txt)"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud iam policies list --kind=denypolicies on the organisation, FLD_AGENTIC_PLATFORM and FLD_PLATFORM_CORE"
    agp_say "      read: gcloud iam principal-access-boundary-policies list --organization=$(v ORG_ID) --location=global"
    agp_say "      read: gcloud iam policy-bindings search-target-policy-bindings on the organisation, and on CICD_PROJECT and CORE_PROJECT by number"
    ev OP-1.4 deny-pab-before E-05 4.2.1 "build-log:records/$(basename "$b")"; return 0
  fi
  log="$(_p13_newlog)" || return 1
  for a in "organizations/$(v ORG_ID)" "folders/$(v FLD_AGENTIC_PLATFORM)" "folders/$(v FLD_PLATFORM_CORE)"; do
    echo "== deny $a" >> "$log"
    out="$(r gcloud iam policies list --attachment-point="cloudresourcemanager.googleapis.com/$a" --kind=denypolicies --format="value(name)")" \
      || { agp_say "      STOP: deny list failed on $a"; rm -f "$log"; return 1; }
    [ -z "$out" ] || printf '%s\n' "$out" >> "$log"
  done
  echo "== pab organisation" >> "$log"
  out="$(r gcloud iam principal-access-boundary-policies list --organization="$(v ORG_ID)" --location=global --format="value(name)")" \
    || { agp_say "      STOP: PAB list failed"; rm -f "$log"; return 1; }
  [ -z "$out" ] || printf '%s\n' "$out" >> "$log"
  echo "== pab bindings targeting the organisation" >> "$log"
  out="$(r gcloud iam policy-bindings search-target-policy-bindings --organization="$(v ORG_ID)" --location=global \
          --target="//cloudresourcemanager.googleapis.com/organizations/$(v ORG_ID)" --format="value(name)")" \
    || { agp_say "      STOP: binding search failed on the organisation"; rm -f "$log"; return 1; }
  [ -z "$out" ] || printf '%s\n' "$out" >> "$log"
  for p in CICD_PROJECT CORE_PROJECT; do
    echo "== pab bindings targeting $p" >> "$log"
    pn="$(r gcloud projects describe "$(v "$p")" --format='value(projectNumber)')" || { agp_say "      STOP: $p could not be described"; rm -f "$log"; return 1; }
    out="$(r gcloud iam policy-bindings search-target-policy-bindings --project="$(v "$p")" --location=global \
            --target="//cloudresourcemanager.googleapis.com/projects/$pn" --format="value(name)")" \
      || { agp_say "      STOP: binding search failed on $p"; rm -f "$log"; return 1; }
    [ -z "$out" ] || printf '%s\n' "$out" >> "$log"
  done
  cnt="$(grep -c '^[a-z]' "$log")"
  sed 's/^/        /' "$log" >&3
  agp_say "      names listed: $cnt (0, or only policies the organisation already had, recorded and left untouched)"
  if grep -qE '(^|/)(deny-agents-platform|deny-core-agents|deny-improvers|pab-agents|pab-core-ci)$' "$log"; then
    agp_say "      STOP: a policy of this file already exists: a hand edit happened outside this procedure"; bad=1
  fi
  _p13_finish "$log" "$bad" OP-1.4 deny-pab-before txt 4.2.1
}

step OP-1.5 CONSOLE "Read SCC before any location policy" --witness --needs "ORG_ID"
s_OP_1_5_check() { ckpt_done OP-1.5; }
s_OP_1_5_manual() {
  local o; o="$(v ORG_ID)"
  echo "WHO: the platform owner; witness: IT security (the P11 signatory of 09) co-signs the screenshots."
  echo "WHERE: the EU console, Security Command Center > Settings > Tier details, and Setup details, for the organisation. Screenshot both."
  printf '$ gcloud scc manage services describe security-health-analytics --organization=%s --format="value(effectiveEnablementState)"\n' "$o"
  printf '$ gcloud scc manage services describe event-threat-detection --organization=%s --format="value(effectiveEnablementState)"\n' "$o"
  echo '$ gcloud config set api_endpoint_overrides/securitycenter https://securitycenter.eu.rep.googleapis.com/'
  printf '$ gcloud scc findings list %s --location=eu --limit=1 --format="value(finding.name)"\n' "$o"
  echo '$ gcloud config unset api_endpoint_overrides/securitycenter'
  echo "VERIFY: Premium; residency eu; both ENABLED; the findings call exits 0. Equal to 09 FS-7.5, or the file stops and returns to 09."
  printf 'RECORD: <date>-OP-1.5-scc-before-v1 (screenshots, signed, and the output) under %s/records; evidence_add it (TISAX 1.5.1).\n' "$(v BUILD_LOG_DIR)"
  echo "Then: agp-platform done OP-1.5 --witness <IT security email>"
}

# ---------------------------------------------------------------- 2. The policy files
step OP-2.1 AUTO "Write the legacy-constraint files" \
  --needs "PLATFORM_REPO_DIR FLD_IMPROVERS_NONPROD FLD_AGENTIC_PLATFORM FLD_AGENTS_W_NONPROD FLD_AGENTS_P_NONPROD FLD_CONTROLLERS_NONPROD FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS FLD_PLATFORM_CORE DIRECTORY_CUSTOMER_ID"
s_OP_2_1_check() { ckpt_done OP-2.1 || _p13_files_equal OP-2.1; }
s_OP_2_1_apply() {
  _p13_write_files OP-2.1 || return 1
  agp_say "      13 files under each of the two platform-wide folders, 2 under each of the six tier folders, 1 under FLD_PLATFORM_CORE,"
  agp_say "      2 under policies/probe/ (project $P13_PROBE), and policies/HELD.md for B16 (P3) and B20 (P12)"
}

step OP-2.2 AUTO "Write the B7 files and the dry-run managed files" \
  --needs "PLATFORM_REPO_DIR FLD_AGENTIC_PLATFORM FLD_AGENTS_R FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS DOMAIN"
s_OP_2_2_check() { ckpt_done OP-2.2 || _p13_files_equal OP-2.2; }
s_OP_2_2_apply() { _p13_write_files OP-2.2; }

step OP-2.3 AUTO "Write B19 from the catalogue's parameter name" \
  --needs "PLATFORM_REPO_DIR FLD_PLATFORM_CORE GIT_OIDC_ISSUER WIF_PROVIDER CICD_PROJECT BUILD_LOG_DIR B19_PARAM"
s_OP_2_3_check() {
  ckpt_done OP-2.3 && return 0
  _p13_files_equal OP-2.3
}
s_OP_2_3_apply() {
  local w id flt rc
  w="$(v WIF_PROVIDER)"; id="${w##*/}"
  _p13_need_done OP-1.2 "it reads the B19 parameter name" || return 1
  agp_say "      B19 parameter (B19_PARAM, kept by OP-1.2): $(v B19_PARAM)"
  # The page's issuer-match, as a filtered list: the provider is listed only when its issuer equals
  # GIT_OIDC_ISSUER (an equality, so a trailing slash on one side and not the other is a mismatch).
  flt="name~\"/providers/$id\$\" AND oidc.issuerUri=\"$(v GIT_OIDC_ISSUER)\""
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: $(agp_quote gcloud iam workload-identity-pools providers list --workload-identity-pool=wif-factory --location=global \
      --project="$(v CICD_PROJECT)" --filter="$flt" --format='value(name)')"
    agp_say "      check: the provider is listed, so its issuer equals GIT_OIDC_ISSUER character for character (issuer-match)"
  else
    nonempty gcloud iam workload-identity-pools providers list --workload-identity-pool=wif-factory --location=global \
      --project="$(v CICD_PROJECT)" --filter="$flt" --format='value(name)'; rc=$?
    case $rc in
      0) agp_say "      issuer-match";;
      1) agp_say "      STOP: provider $id's issuer is not GIT_OIDC_ISSUER ($(v GIT_OIDC_ISSUER)), character for character."
         agp_say "        B19 would refuse the platform's own provider. Reconcile 03 (GIT_OIDC_ISSUER) and 10 (CP-4.3) first, then resume."
         return 98;;
      *) agp_say "      STOP: the providers of pool wif-factory in $(v CICD_PROJECT) could not be listed"; return 1;;
    esac
  fi
  _p13_write_files OP-2.3
}

step OP-2.4 AUTO "Write the gcp.restrictServiceUsage dry-run files" \
  --needs "PLATFORM_REPO_DIR FLD_PLATFORM_CORE KMS_PROJECT FLD_AGENTS_R FLD_AGENTS_R_NONPROD FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_P_SA FLD_CONTROLLERS FLD_IMPROVERS FLD_AGENTS_X"
_p13_sup() {   # the list saved by hand "once": the newest saved, as the page reads it; else today's name (to ask for it)
  local d last; d="$(_p13_repo)/policies/tools"
  last="$(_p13_glob "$d/restrict-services-supported-*.txt" | sort | tail -1)"
  printf '%s' "${last:-$d/restrict-services-supported-$(_p13_today).txt}"
}
_p13_rsu_verify() {     # the page's VERIFY of OP-2.4 on the files in the repository; prints what fails.
                        # Returns 0 pass, 1 fail, 4 Google's list has not been saved by hand yet
  local d sup bad=0 s n
  d="$(_p13_repo)/policies/dryrun"; sup="$(_p13_sup)"
  [ -s "$sup" ] || { echo "STOP: save Google's 'Services that support restricting service usage' list by hand first, one *.googleapis.com per line, as $sup, then resume"; return 4; }
  [ "$(_p13_glob "$d/*/gcp.restrictServiceUsage.json" | grep -c .)" = 10 ] || { echo "the ten files are not all present"; bad=1; }
  for s in $(for f in $(_p13_glob "$d/*/gcp.restrictServiceUsage.json"); do _p13_py allowed "$f"; done | sort -u); do
    grep -qx "$s" "$sup" || { echo "NOT-GOVERNED $s"; bad=1; }
  done
  n="$(_p13_py allowed "$d/FLD_AGENTS_P_SA/gcp.restrictServiceUsage.json" 2>/dev/null | grep -c -E '^(compute|networksecurity|networkservices|dns|iap|aiplatform|discoveryengine|storage|modelarmor|cloudtrace|apphub|apptopology|cloudapiregistry|notebooks|texttospeech|dataform)\.googleapis\.com$')"
  [ "$n" = 16 ] || { echo "fld-agents-p-sa holds $n of the 16 governed Agent Gateway APIs"; bad=1; }
  _p13_py allowed "$d/FLD_CONTROLLERS/gcp.restrictServiceUsage.json" 2>/dev/null | grep -qE '^(cloudbuild|artifactregistry)\.' && { echo "the controllers list holds cloudbuild or artifactregistry"; bad=1; }
  _p13_py allowed "$d/FLD_IMPROVERS/gcp.restrictServiceUsage.json" 2>/dev/null | grep -qE '^(aiplatform|modelarmor)\.' && { echo "the improvers list holds aiplatform or modelarmor"; bad=1; }
  return $bad
}
s_OP_2_4_check() {
  ckpt_done OP-2.4 && return 0
  _p13_files_equal OP-2.4 && { _p13_rsu_verify >/dev/null 2>&1 || return 1; }
}
s_OP_2_4_apply() {
  local out
  _p13_write_files OP-2.4 || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      check: every value is on Google's list saved by hand as $(_p13_sup) (no NOT-GOVERNED line);"
    agp_say "        ten files; fld-agents-p-sa holds the 16 governed Agent Gateway APIs; no cloudbuild or artifactregistry for"
    agp_say "        controllers; no aiplatform or modelarmor for improvers"
    return 0
  fi
  out="$(_p13_rsu_verify)"; local rc=$?
  [ -z "$out" ] || printf '%s\n' "$out" | sed 's/^/      /' >&3
  [ $rc -eq 0 ] && agp_say "      no NOT-GOVERNED line; ten files; 16 Agent Gateway APIs on fld-agents-p-sa"
  [ $rc -eq 4 ] && return 98   # the page's by-hand save comes first: a person must act
  return $rc
}

step OP-2.5 HUMAN "Write the custom constraints, the deny policies and the PAB rules" \
  --gate "SD-22 SD-24" --needs "PLATFORM_REPO_DIR ORG_ID SA_FACTORY_APPLY FLD_AGENTIC_PLATFORM FLD_AGENTS_R FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_X FLD_CONTROLLERS FLD_IMPROVERS"
s_OP_2_5_check() { ckpt_done OP-2.5; }
s_OP_2_5_manual() {
  local p; p="$(_p13_repo)"
  echo "WHO: the platform owner. WHERE: shell, ~/.platform-env sourced, in $p."
  echo "First define the page's two helpers of OP-2.1 and OP-2.2 (pol, dry), then paste setup/13 OP-2.5's two blocks as the page"
  echo "has them: three policies/custom/*.yaml, five dry-run CC files, policies/deny/{deny-agents-platform,deny-core-agents,deny-improvers}.json"
  echo "(R1, R2, R3, R6 and CORE_GOV with the three agentregistry write permissions) and policies/pab/{pab-agents,pab-core-ci}.rules.json."
  echo "The script does not retype the page's here-documents."
  echo "Save Google's 'Permissions supported in deny policies' list by hand as policies/tools/deny-supported-<date saved>.txt"
  echo "  (a list saved before 2026-09-29 lacks the Agent Registry names: save it again). The checks read the newest saved."
  printf "VERIFY: \$ grep -c '^name: organizations/' %s/policies/custom/*.yaml      (1 per file)\n" "$p"
  echo "  and the page's NOT-DENIABLE loop prints nothing; a name it prints leaves the deny file for the fence that applies (BD-13-2)."
  echo "Then: agp-platform done OP-2.5"
}

step OP-2.6 HUMAN "Check permission names, open the pull request, merge under two reviewers" \
  --needs "PLATFORM_REPO_DIR PLATFORM_REPO_REMOTE SECOND_HUMAN_EMAIL"
s_OP_2_6_check() { ckpt_done OP-2.6; }
s_OP_2_6_manual() {
  local p; p="$(_p13_repo)"
  echo "WHO: the platform owner opens; the required reviewers ($(v SECOND_HUMAN_EMAIL); the security reviewer where appointed) review and merge."
  echo "The platform owner never merges."
  printf 'WHERE: %s and the git host (%s).\n' "$p" "$(v PLATFORM_REPO_REMOTE)"
  echo "Run setup/13 OP-2.6's block: the NOT-DENIABLE check against the newest policies/tools/deny-supported-*.txt (no line, or stop),"
  echo "then git checkout -b setup-13-policies, git add policies, commit, git push -u origin setup-13-policies."
  echo "Open the pull request against main with the description the page lists (plan table, allow-lists, corrections, Assumption)."
  echo "VERIFY: merged with two human approvals, none from a bot or service account;"
  printf '$ git -C %s pull && git -C %s log -1 --format=%%H      (the policy commit)\n' "$p" "$p"
  echo "RECORD: evidence_add OP-2.6 policy-files-merged E-05 5.2.1 \"git:<merge commit>\""
  echo "Then: agp-platform done OP-2.6 --note \"policy commit <merge commit>\""
}

# ---------------------------------------------------------------- 3. Start the dry runs (day 0)
step OP-3.1 AUTO "Create the three custom constraints" --needs "ORG_ID PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_cc_names() { echo "custom.runBinaryAuthorizationRequired custom.agpProjectIdPrefix custom.fldFolderNaming"; }
s_OP_3_1_check() {   # the DONE line, the three read from Google, or the step's record (written once all three read back)
  local c rc worst=0
  ckpt_done OP-3.1 && return 0
  [ -n "$(_p13_glob "$(v BUILD_LOG_DIR)/records/*-OP-3.1-custom-constraints-v*.json" | head -1)" ] && return 0
  for c in $(_p13_cc_names); do
    exists gcloud org-policies describe-custom-constraint "$c" --organization="$(v ORG_ID)" --format='value(name)'; rc=$?
    case $rc in 0) ;; 1) worst=1;; *) return $rc;; esac
  done
  return $worst
}
s_OP_3_1_apply() {
  local c f rec log
  _p13_need_done OP-2.6 "the policy files are merged" || return 1
  agp_say "      under the grant of OP-0.2 (justification: OP-2.6's pull request)"
  for c in $(_p13_cc_names); do
    f="$(_p13_repo)/policies/custom/$c.yaml"
    if [ "$AGP_MODE" = apply ] && [ ! -f "$f" ]; then agp_say "      STOP: $f is missing (OP-2.5)"; return 1; fi
    # scope: the organisation named in the file (set-custom-constraint has no --organization flag)
    x gcloud org-policies set-custom-constraint "$f" || return 1
  done
  rec="$(_p13_recpath OP-3.1 custom-constraints json)"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud org-policies list-custom-constraints --organization=$(v ORG_ID) lists the three"
    ev OP-3.1 custom-constraints E-05 5.2.1 "build-log:records/$(basename "$rec")"; return 0
  fi
  r gcloud org-policies list-custom-constraints --organization="$(v ORG_ID)" --format="value(name)" | sed 's/^/        /' >&3
  log="$(_p13_newlog)" || return 1
  for c in $(_p13_cc_names); do
    r gcloud org-policies describe-custom-constraint "$c" --organization="$(v ORG_ID)" --format=json >> "$log" || { rm -f "$log"; agp_say "      FAIL: $c is not readable"; return 1; }
  done
  x mkdir -p "$(dirname "$rec")" && xw "$rec" < "$log"; local rc=$?
  rm -f "$log"; [ $rc -eq 0 ] || return 1
  ev OP-3.1 custom-constraints E-05 5.2.1 "build-log:records/$(basename "$rec")" "$rec"
}

step OP-3.2 AUTO "Apply the dry-run policies" --removes --needs "PLATFORM_REPO_DIR FLD_IMPROVERS BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_dryrun_files() { _p13_glob "$(_p13_repo)/policies/dryrun/*/*.json"; }
s_OP_3_2_check() {
  local files
  ckpt_done OP-3.2 && return 0
  files="$(_p13_dryrun_files)"; [ -n "$files" ] || return 1
  # shellcheck disable=SC2086
  _p13_all_exist $files
}
s_OP_3_2_apply() {
  local files n
  _p13_need_done OP-2.6 "the policy files are merged" || return 1
  agp_say "      under the grant of OP-0.2 (justification: OP-2.6's pull request)"
  files="$(_p13_dryrun_files)"; n="$(printf '%s' "$files" | grep -c .)"
  if [ "$AGP_MODE" != apply ] && [ "$n" = 0 ]; then
    agp_say "      \$ $(_p13_repo)/policies/tools/op-set.sh <each of the 20 files of policies/dryrun/*/*.json>"; return 0
  fi
  [ "$AGP_MODE" != apply ] || [ "$n" = 20 ] || { agp_say "      STOP: $n files under policies/dryrun, not 20"; return 1; }
  # shellcheck disable=SC2086
  _p13_opset 20 $files || return 1
  if [ "$AGP_MODE" = apply ]; then
    r gcloud org-policies describe gcp.restrictServiceUsage --folder="$(v FLD_IMPROVERS)" --format="yaml(spec,dryRunSpec)" | sed 's/^/        /' >&3
    _p13_all_state dry "$(_p13_repo)/policies/dryrun/FLD_IMPROVERS/gcp.restrictServiceUsage.json"
    case $? in
      0) agp_say "      fld-improvers shows dryRunSpec and no spec: nothing is enforced";;
      1) agp_say "      FAIL: gcp.restrictServiceUsage on fld-improvers is not in dry run only"; return 1;;
      *) agp_say "      FAIL: the policies of fld-improvers could not be listed"; return 1;;
    esac
    x git -C "$(_p13_repo)" add policies/predecessors || return 1
    x git -C "$(_p13_repo)" commit -m "predecessors: dry-run apply (setup 13 OP-3.2)" || return 1
    agp_say "      push the commit and open its pull request for the same two reviewers; record evidence_add OP-3.2 dryrun-applied E-05 5.2.1 \"git:<commit>\""
  else
    agp_say "      check: gcp.restrictServiceUsage on FLD_IMPROVERS shows dryRunSpec and no spec; commit policies/predecessors"
  fi
}

step OP-3.3 AUTO-READ "Take the day-0 reading of dry-run entries in the core projects" \
  --needs "$P13_CORE BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_3_3_check() { ckpt_done OP-3.3; }
s_OP_3_3_apply() {
  local p log
  _p13_after OP-3.2 3600 "one hour after the dry runs start" || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud logging read '$P13_DRYLOG' --project=<each core project> --freshness=2h --limit=20"
    _p13_save OP-3.3 dryrun-day0 txt 5.2.4 /dev/null; return 0
  fi
  log="$(_p13_newlog)" || return 1
  for p in $P13_CORE; do
    echo "== $p" >> "$log"
    r gcloud logging read "$P13_DRYLOG" --project="$(v "$p")" --freshness=2h --limit=20 \
      --format="table(timestamp,protoPayload.serviceName,protoPayload.methodName)" >> "$log" 2>&1 \
      || { echo "READ-ERROR $p" >> "$log"; agp_say "      READ-ERROR $p"; rm -f "$log"; return 1; }
  done
  sed 's/^/        /' "$log" >&3
  agp_say "      an entry for a governed service the core projects use is noted for OP-8.1; no entry is also valid"
  _p13_finish "$log" 0 OP-3.3 dryrun-day0 txt 5.2.4
}

step OP-3.4 AUTO "Record the dry-run window" --needs "DRILL_CALENDAR BUILD_LOG_DIR"
s_OP_3_4_check() { ckpt_done OP-3.4 && return 0; [ -f "$(v DRILL_CALENDAR)" ] && grep -q '^| 13-dryrun |' "$(v DRILL_CALENDAR)"; }
s_OP_3_4_apply() {
  local start end cal tmp
  cal="$(v DRILL_CALENDAR)"; start="$(_p13_today)"; end="$(_p13_py plus-days 14)"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      would append to $cal: | 13-dryrun | $start | $end | OP-8.1 review and enforcement of B2 B3 B14 B15 B19 B22 CC-3 CC-5 CC-9 | ... | open |"
    x git -C "$(v BUILD_LOG_DIR)" add "$cal"; x git -C "$(v BUILD_LOG_DIR)" commit -m "calendar: setup 13 dry-run window"
    x checkpoint OP-3.4 DONE - - "dry-run window $start to $end"; return 0
  fi
  [ -f "$cal" ] || { agp_say "      STOP: $cal does not exist (01)"; return 1; }
  tmp="$(_p13_newlog)" || return 1
  { cat "$cal"
    printf '| 13-dryrun | %s | %s | OP-8.1 review and enforcement of B2 B3 B14 B15 B19 B22 CC-3 CC-5 CC-9 | platform owner; second human reviews | open |\n' "$start" "$end"
  } > "$tmp"
  xw "$cal" < "$tmp"; local rc=$?; rm -f "$tmp"; [ $rc -eq 0 ] || return 1
  x git -C "$(v BUILD_LOG_DIR)" add "$cal" || return 1
  x git -C "$(v BUILD_LOG_DIR)" commit -m "calendar: setup 13 dry-run window" || return 1
  x checkpoint OP-3.4 DONE - - "dry-run window $start to $end" >/dev/null || return 1
  agp_say "      dry-run window $start to $end; §8 refuses to start before $end"
}

# ---------------------------------------------------------------- 4. Legacy constraints on the nonprod folder
step OP-4.1 AUTO "Apply B1, the first location policy, to fld-improvers-nonprod" --irreversible --removes \
  --gate "SD-15" --needs "PLATFORM_REPO_DIR FLD_IMPROVERS_NONPROD SCC_TIER BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_4_1_check() {
  ckpt_done OP-4.1 && return 0
  exists gcloud org-policies describe gcp.resourceLocations --folder="$(v FLD_IMPROVERS_NONPROD)" --format='value(name)'
}
s_OP_4_1_apply() {
  local log bad=0 rc
  _p13_need_done OP-1.5 "SCC read before any location policy (SD-15)" || return 1
  _p13_need_done OP-3.2 "the dry runs are started" || return 1
  [ "$AGP_MODE" != apply ] || [ "$(v SCC_TIER)" = "PREMIUM/eu" ] || { agp_say "      STOP: SCC_TIER is not PREMIUM/eu"; return 1; }
  agp_say "      under the grant of OP-0.2; tell IT security the time (it co-signs OP-4.2)"
  log="$(_p13_newlog)" || return 1
  [ "$AGP_MODE" != apply ] || date -u +%Y-%m-%dT%H:%M:%SZ >> "$log"
  _p13_opset 1 "$(_p13_repo)/policies/org/FLD_IMPROVERS_NONPROD/gcp.resourceLocations.json" || { rm -f "$log"; return 1; }
  if [ "$AGP_MODE" = apply ]; then
    r gcloud org-policies describe gcp.resourceLocations --folder="$(v FLD_IMPROVERS_NONPROD)" --effective --format=json >> "$log"
    # the file sets no inheritFromParent, so the effective policy is the folder's own: read as a filtered list
    _p13_inherits gcp.resourceLocations "$P13_B1" FLD_IMPROVERS_NONPROD FLD_IMPROVERS_NONPROD; rc=$?
    case $rc in
      0) agp_say "      effective: in:eu-locations and is:europe"; echo "effective: in:eu-locations is:europe" >> "$log";;
      1) agp_say "      FAIL: the effective policy does not list in:eu-locations and is:europe"; bad=1;;
      *) agp_say "      FAIL: the policy could not be read"; bad=1;;
    esac
    agp_say "      enforcement can take up to 15 minutes; OP-4.2 reads SCC at +1 h and +24 h"
  else
    agp_say "      read: the effective gcp.resourceLocations on FLD_IMPROVERS_NONPROD lists in:eu-locations and is:europe"
  fi
  _p13_finish "$log" "$bad" OP-4.1 b1-nonprod txt 7.1.1
}

step OP-4.2 CONSOLE "Read SCC after the nonprod location policy" --witness --needs "ORG_ID FLD_IMPROVERS_NONPROD"
s_OP_4_2_check() { ckpt_done OP-4.2; }
s_OP_4_2_manual() {
  echo "WHO: the platform owner; witness: IT security co-signs."
  echo "WHERE: as OP-1.5 (EU console SCC > Settings > Tier details and Setup details; then the five shell readings)."
  echo "Repeat OP-1.5's screenshots and commands at +1 hour and again at +24 hours after OP-4.1 (agp-platform plan --phase 13 --to OP-1.5"
  echo "prints them with values)."
  echo "VERIFY: both readings equal OP-1.5: Premium, residency eu, both services ENABLED, findings call exits 0."
  printf 'If any differs: run at once  $ gcloud org-policies delete gcp.resourceLocations --folder=%s\n' "$(v FLD_IMPROVERS_NONPROD)"
  echo "  ask IT security to reactivate from the EU console, record it, and stop the file until IT security and the security"
  echo "  reviewer sign a decision on where B1 may be set."
  echo "RECORD: <date>-OP-4.2-scc-after-nonprod-v1 (both readings, signed); evidence_add it (TISAX 1.5.1, 7.1.2)."
  echo "Then: agp-platform done OP-4.2 --witness <IT security email>"
}

step OP-4.3 AUTO "Apply the other platform-wide legacy constraints to fld-improvers-nonprod" --irreversible --removes \
  --needs "PLATFORM_REPO_DIR FLD_IMPROVERS_NONPROD BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_nonprod_files() { local c; for c in $P13_LEGACY; do [ "$c" = gcp.resourceLocations ] || printf '%s/policies/org/FLD_IMPROVERS_NONPROD/%s.json\n' "$(_p13_repo)" "$c"; done; }
s_OP_4_3_check() {
  ckpt_done OP-4.3 && return 0
  # shellcheck disable=SC2046
  _p13_all_exist $(_p13_nonprod_files)
}
s_OP_4_3_apply() {
  local log
  _p13_need_done OP-4.1 "B1 goes first" || return 1
  agp_say "      under the grant of OP-0.2"
  # shellcheck disable=SC2046
  _p13_opset 12 $(_p13_nonprod_files) || return 1
  [ "$AGP_MODE" = apply ] || { agp_say "      read: gcloud org-policies list --folder=$(v FLD_IMPROVERS_NONPROD) lists 13 constraints with B1"; _p13_save OP-4.3 legacy-nonprod txt 5.2.2 /dev/null; return 0; }
  log="$(_p13_newlog)" || return 1
  r gcloud org-policies list --folder="$(v FLD_IMPROVERS_NONPROD)" --format="value(constraint)" >> "$log"
  sed 's/^/        /' "$log" >&3
  agp_say "      commit policies/predecessors with the next pull request (OP-4.3 EVIDENCE)"
  _p13_finish "$log" 0 OP-4.3 legacy-nonprod txt 5.2.2
}

step OP-4.4 AUTO "Apply B7, and B17 and B18 to the nonprod tier folders" --irreversible --removes \
  --needs "PLATFORM_REPO_DIR FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE FLD_IMPROVERS FLD_AGENTS_R FLD_AGENTS_P_SA BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_44_files() {
  local p; p="$(_p13_repo)/policies/org"
  printf '%s\n' "$p/FLD_AGENTIC_PLATFORM/iam.managed.disableAccessPolicyBinding.json" "$p/FLD_AGENTS_R/iam.managed.disableAccessPolicyBinding.json" \
    "$p/FLD_AGENTS_W/iam.managed.disableAccessPolicyBinding.json" "$p/FLD_AGENTS_P/iam.managed.disableAccessPolicyBinding.json" \
    "$p/FLD_CONTROLLERS/iam.managed.disableAccessPolicyBinding.json" \
    "$p/FLD_AGENTS_W_NONPROD/run.allowedVPCEgress.json" "$p/FLD_AGENTS_W_NONPROD/run.allowedBinaryAuthorizationPolicies.json" \
    "$p/FLD_AGENTS_P_NONPROD/run.allowedVPCEgress.json" "$p/FLD_AGENTS_P_NONPROD/run.allowedBinaryAuthorizationPolicies.json" \
    "$p/FLD_CONTROLLERS_NONPROD/run.allowedVPCEgress.json" "$p/FLD_CONTROLLERS_NONPROD/run.allowedBinaryAuthorizationPolicies.json"
}
s_OP_4_4_check() {
  ckpt_done OP-4.4 && return 0
  # shellcheck disable=SC2046
  _p13_all_exist $(_p13_44_files)
}
s_OP_4_4_apply() {
  local log bad=0 n e e2 want from rc
  agp_say "      under the grant of OP-0.2; B7 goes directly to its final form, B17 and B18 nonprod first"
  # shellcheck disable=SC2046
  _p13_opset 11 $(_p13_44_files) || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: effective B7: enforce true on FLD_AGENTIC_PLATFORM, FLD_PLATFORM_CORE, FLD_IMPROVERS; false on FLD_AGENTS_R and FLD_AGENTS_P_SA"
    _p13_save OP-4.4 b7-b17-b18-nonprod txt 5.2.7 /dev/null; return 0
  fi
  log="$(_p13_newlog)" || return 1
  for n in FLD_AGENTIC_PLATFORM:true:FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE:true:FLD_AGENTIC_PLATFORM FLD_IMPROVERS:true:FLD_AGENTIC_PLATFORM \
           FLD_AGENTS_R:false:FLD_AGENTS_R FLD_AGENTS_P_SA:false:FLD_AGENTS_P; do
    from="${n##*:}"; n="${n%:*}"; want="${n#*:}"; n="${n%%:*}"
    e="$(r gcloud org-policies describe iam.managed.disableAccessPolicyBinding --folder="$(v "$n")" --effective --format=json | _p13_py enforce)"
    _p13_inherits iam.managed.disableAccessPolicyBinding "spec.rules.enforce=$want" "$from" "$n"; rc=$?
    case $rc in 0) e2="$want";; 1) e2="not $want"; bad=1;; *) e2="unreadable"; bad=1;; esac
    printf '== %s enforce=%s from %s (expected %s; the effective read printed %s)\n' "$n" "$e2" "$from" "$want" "$e" >> "$log"
  done
  sed 's/^/        /' "$log" >&3
  _p13_finish "$log" "$bad" OP-4.4 b7-b17-b18-nonprod txt 5.2.7
}

# ---------------------------------------------------------------- 5. The probe project
step OP-5.1 HUMAN "Create the probe project" --irreversible --gate "SD-46" \
  --needs "ENT_BOOTSTRAP_MODULE_IMPROVERS_NONPROD CICD_PROJECT FLD_IMPROVERS_NONPROD BILLING_ACCOUNT_ID SECOND_HUMAN_EMAIL DEVIATION_REGISTER"
s_OP_5_1_check() { ckpt_done OP-5.1; }
s_OP_5_1_manual() {
  echo "WHO: the platform owner requests ENT_BOOTSTRAP_MODULE_IMPROVERS_NONPROD; $(v SECOND_HUMAN_EMAIL) approves. IRREVERSIBLE as a name:"
  echo "  confirm $P13_PROBE is not in 03's names record for any real project."
  printf '$ gcloud pam grants create --entitlement=%s --requested-duration=3600s --justification="setup 13 OP-5.1 probe project for legacy constraint proofs; deviation BD-13-1; no register row (throwaway)" --billing-project=%s\n' \
    "$(v ENT_BOOTSTRAP_MODULE_IMPROVERS_NONPROD)" "$(v CICD_PROJECT)"
  echo "After the approval:"
  printf '$ gcloud projects create %s --folder=%s --labels="agent=opprobe,tier=imp,env=nonprod,created_by=setup-13"\n' "$P13_PROBE" "$(v FLD_IMPROVERS_NONPROD)"
  printf '$ gcloud billing projects link %s --billing-account=%s\n' "$P13_PROBE" "$(v BILLING_ACCOUNT_ID)"
  echo "Then the page's bd_insert of BD-13-1, in the same step (setup/13 OP-5.1)."
  printf 'VERIFY: $ gcloud projects describe %s --format="value(parent.type,parent.id,lifecycleState)"   (folder %s ACTIVE)\n' "$P13_PROBE" "$(v FLD_IMPROVERS_NONPROD)"
  echo "  billingEnabled True; bd_insert printed 'opened BD-13-1 at line <a> (Closures heading at line <b>)' with a < b."
  echo "RECORD: <date>-OP-5.1-probe-project-v1 (describe output and grant name). Then: agp-platform done OP-5.1"
}

step OP-5.2 AUTO "Put B17 and B18 on the probe, and create its service accounts" --removes --needs "PLATFORM_REPO_DIR"
s_OP_5_2_check() {
  local a b c
  ckpt_done OP-5.2 && return 0
  _p13_all_exist "$(_p13_repo)/policies/probe/run.allowedVPCEgress.json" "$(_p13_repo)/policies/probe/run.allowedBinaryAuthorizationPolicies.json"; a=$?
  exists gcloud iam service-accounts describe "op-probe@$P13_PROBE.iam.gserviceaccount.com" --project="$P13_PROBE" --format='value(email)'; b=$?
  exists gcloud iam service-accounts describe "op-probe-target@$P13_PROBE.iam.gserviceaccount.com" --project="$P13_PROBE" --format='value(email)'; c=$?
  for rc in $a $b $c; do [ "$rc" = 0 ] || [ "$rc" = 1 ] || return "$rc"; done
  [ "$a$b$c" = 000 ]
}
s_OP_5_2_apply() {
  _p13_need_done OP-5.1 "the probe project exists" || return 1
  agp_say "      under the grant of OP-0.2 for the two policies"
  _p13_opset 2 "$(_p13_repo)/policies/probe/run.allowedVPCEgress.json" "$(_p13_repo)/policies/probe/run.allowedBinaryAuthorizationPolicies.json" || return 1
  x gcloud services enable iam.googleapis.com storage.googleapis.com --project="$P13_PROBE" || return 1
  _p13_sa_create op-probe "$P13_PROBE" "op-probe (setup 13)" || return 1
  _p13_sa_create op-probe-target "$P13_PROBE" "op-probe-target, holds no role (setup 13)" || return 1
  [ "$AGP_MODE" = apply ] && r gcloud iam service-accounts list --project="$P13_PROBE" --format="value(email)" | sed 's/^/        /' >&3
  return 0
}

step OP-5.3 AUTO "Storage and member tests: B1, B5, B8, B9" --removes --needs "REGION BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_5_3_check() { ckpt_done OP-5.3 || _p13_passed OP-5.3 storage-member-tests; }
s_OP_5_3_apply() {
  local log bad=0 acc=0 rc p="$P13_PROBE" reg
  reg="$(v REGION)"
  _p13_after OP-4.3 900 "the legacy constraints take up to 15 minutes to be enforced" || return 1
  _p13_need_done OP-5.2 "the probe's accounts exist" || return 1
  log="$(_p13_newlog)" || return 1
  agp_say "      each command is expected to fail except (3); the failures are the proof"
  _p13_refused "$log" "(1) B1" 'constraints/gcp.resourceLocations' \
    gcloud storage buckets create "gs://$p-us" --project="$p" --location=us-central1 --uniform-bucket-level-access; rc=$?
  if [ $rc -eq 1 ]; then bad=1; acc=1; x gcloud storage buckets delete "gs://$p-us" --project="$p"; elif [ $rc -ne 0 ]; then bad=1; fi
  _p13_refused "$log" "(2) B8" 'constraints/storage.uniformBucketLevelAccess' \
    gcloud storage buckets create "gs://$p-fine" --project="$p" --location="$reg" --no-uniform-bucket-level-access; rc=$?
  if [ $rc -eq 1 ]; then bad=1; acc=1; x gcloud storage buckets delete "gs://$p-fine" --project="$p"; elif [ $rc -ne 0 ]; then bad=1; fi
  if _p13_bucket_create "gs://$p-ok" "$p" "$reg"; then echo "(3) created gs://$p-ok" >> "$log"; else echo "(3) FAILED: gs://$p-ok was not created" >> "$log"; bad=1; fi
  _p13_refused "$log" "(4) B5" 'constraints/iam.allowedPolicyMemberDomains|constraints/storage.publicAccessPrevention' \
    gcloud storage buckets add-iam-policy-binding "gs://$p-ok" --member=allUsers --role=roles/storage.objectViewer --project="$p"; rc=$?
  if [ $rc -eq 1 ]; then bad=1; acc=1; x gcloud storage buckets remove-iam-policy-binding "gs://$p-ok" --member=allUsers --role=roles/storage.objectViewer --project="$p"; elif [ $rc -ne 0 ]; then bad=1; fi
  _p13_refused "$log" "(5) B5" 'constraints/iam.allowedPolicyMemberDomains' \
    gcloud projects add-iam-policy-binding "$p" --member="domain:example.com" --role="roles/browser" --condition=None; rc=$?
  if [ $rc -eq 1 ]; then bad=1; acc=1; x gcloud projects remove-iam-policy-binding "$p" --member="domain:example.com" --role="roles/browser" --condition=None; elif [ $rc -ne 0 ]; then bad=1; fi
  _p13_refused "$log" "(6) B9" 'constraints/storage.publicAccessPrevention' \
    gcloud storage buckets update "gs://$p-ok" --no-public-access-prevention --project="$p"; rc=$?
  if [ $rc -eq 1 ]; then bad=1; acc=1; x gcloud storage buckets update "gs://$p-ok" --public-access-prevention --project="$p"; elif [ $rc -ne 0 ]; then bad=1; fi
  _p13_finish "$log" "$bad" OP-5.3 storage-member-tests txt 7.1.1; rc=$?
  _p13_stop_accepted "$acc" "re-read the effective policy of $P13_PROBE and of fld-improvers-nonprod" || return 98
  return $rc
}

step OP-5.4 AUTO "Compute tests: B12, B4, and the first real dry-run entry" --needs "BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_5_4_check() { ckpt_done OP-5.4 || _p13_passed OP-5.4 compute-tests; }
s_OP_5_4_apply() {
  local log bad=0 blind=0 rc=1 p="$P13_PROBE" out pn i=0
  _p13_need_done OP-5.2 "the probe project is set up" || return 1
  x gcloud services enable compute.googleapis.com --project="$p" || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud compute networks list --project=$p prints nothing (B12)"
    agp_say "      read: the probe's IAM policy holds no role for <number>-compute@developer.gserviceaccount.com (B4)"
    agp_say "      wait 5 minutes, then: gcloud logging read '$P13_DRYLOG' --project=$p --freshness=30m shows a compute.googleapis.com entry;"
    agp_say "        still empty after 15 minutes: stop, the 14-day window is blind"
    _p13_save OP-5.4 compute-tests txt 5.2.4 /dev/null; return 0
  fi
  log="$(_p13_newlog)" || return 1
  # B12: an absence the step asserts (a read marked as a check, _p13_pre)
  out="$(_p13_pre r gcloud compute networks list --project="$p" --format="value(name)")" || { echo "networks list failed" >> "$log"; bad=1; }
  printf '== networks (B12): [%s]\n' "$out" >> "$log"
  [ -z "$out" ] || { agp_say "      FAIL B12: the probe has networks: $out"; bad=1; }
  # B4: no binding names the Compute Engine default account (the page's --flatten read, decided on the policy JSON)
  pn="$(r gcloud projects describe "$p" --format='value(projectNumber)')"
  if out="$(r gcloud projects get-iam-policy "$p" --format=json)"; then
    printf '%s' "$out" | _p13_py no-member "serviceAccount:${pn}-compute@developer.gserviceaccount.com" >> "$log" \
      || { agp_say "      FAIL B4: the Compute Engine default account ${pn}-compute@ holds a project role"; bad=1; }
  else echo "IAM read failed" >> "$log"; bad=1; fi
  agp_say "      waiting 5 minutes for the dry-run entry of the compute call"
  _p13_sleep 300
  while :; do   # the page's read, filtered to the compute entry it looks for
    nonempty r gcloud logging read "$P13_DRYLOG AND protoPayload.serviceName=\"compute.googleapis.com\"" --project="$p" --freshness=30m --limit=5 \
      --format="value(timestamp,protoPayload.serviceName,protoPayload.methodName)"; rc=$?
    [ $rc -eq 1 ] || break
    i=$((i + 1)); [ $i -le 10 ] || break
    _p13_sleep 60
  done
  r gcloud logging read "$P13_DRYLOG" --project="$p" --freshness=30m --limit=5 --format="table(timestamp,protoPayload.serviceName,protoPayload.methodName)" \
    | sed 's/^/== dry-run entries: /' >> "$log"
  case $rc in
    0) echo "a compute.googleapis.com dry-run entry is logged" >> "$log";;
    1) echo "no compute.googleapis.com dry-run entry after 15 minutes" >> "$log"; blind=1; bad=1;;
    *) echo "the log read failed" >> "$log"; bad=1;;
  esac
  sed 's/^/        /' "$log" >&3
  _p13_finish "$log" "$bad" OP-5.4 compute-tests txt 5.2.4; rc=$?
  if [ "$blind" = 1 ]; then   # the page's STOP
    agp_say "      STOP: no dry-run entry after 15 minutes: the 14-day window is blind. A person finds why (the dry run of OP-3.2,"
    agp_say "        the audit log of $p) before anything else; resume with OP-5.4 once an entry is logged"
    return 98
  fi
  return $rc
}

step OP-5.5 AUTO "Cloud KMS tests: B21" --irreversible --removes --needs "REGION BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_5_5_check() { ckpt_done OP-5.5 || _p13_passed OP-5.5 kms-tests; }
s_OP_5_5_apply() {
  local log bad=0 acc=0 rc p="$P13_PROBE" reg
  reg="$(v REGION)"
  _p13_need_done OP-5.2 "the probe project is set up" || return 1
  agp_say "      IRREVERSIBLE: the key ring and the HSM key cannot be deleted; they end with $p, not a core or agent project"
  log="$(_p13_newlog)" || return 1
  x gcloud services enable cloudkms.googleapis.com --project="$p" || { rm -f "$log"; return 1; }
  rc=1; [ "$AGP_MODE" != apply ] || { _p13_pre exists gcloud kms keyrings describe op-probe --location="$reg" --project="$p" --format='value(name)'; rc=$?; }
  case $rc in 0) agp_say "      key ring op-probe exists";; 1) x gcloud kms keyrings create op-probe --location="$reg" --project="$p" || bad=1;; *) bad=1;; esac
  _p13_refused "$log" "SOFTWARE key" 'constraints/cloudkms.allowedProtectionLevels' \
    gcloud kms keys create sw-probe --keyring=op-probe --location="$reg" --purpose=encryption --protection-level=software --project="$p"; rc=$?
  [ $rc -eq 0 ] || { bad=1; [ $rc -eq 1 ] && acc=1; }
  _p13_refused "$log" "1-day destroy duration" 'constraints/cloudkms.minimumDestroyScheduledDuration' \
    gcloud kms keys create hsm-short --keyring=op-probe --location="$reg" --purpose=encryption --protection-level=hsm --destroy-scheduled-duration=1d --project="$p"; rc=$?
  [ $rc -eq 0 ] || { bad=1; [ $rc -eq 1 ] && acc=1; }
  rc=1; [ "$AGP_MODE" != apply ] || { _p13_pre exists gcloud kms keys describe hsm-ok --keyring=op-probe --location="$reg" --project="$p" --format='value(name)'; rc=$?; }
  case $rc in 0) agp_say "      hsm-ok exists";; 1) x gcloud kms keys create hsm-ok --keyring=op-probe --location="$reg" --purpose=encryption --protection-level=hsm --project="$p" || bad=1;; *) bad=1;; esac
  _p13_refused "$log" "destroy of an enabled version" 'constraints/cloudkms.disableBeforeDestroy' \
    gcloud kms keys versions destroy 1 --key=hsm-ok --keyring=op-probe --location="$reg" --project="$p"; rc=$?
  if [ $rc -eq 1 ]; then bad=1; acc=1; x gcloud kms keys versions restore 1 --key=hsm-ok --keyring=op-probe --location="$reg" --project="$p"; elif [ $rc -ne 0 ]; then bad=1; fi
  agp_say "      the first run of 02 4.1 B21's monthly negative test (42 schedules it)"
  _p13_finish "$log" "$bad" OP-5.5 kms-tests txt 5.1.1; rc=$?
  _p13_stop_accepted "$acc" "a key that should have been refused exists, or the destroy was accepted and restored; read the effective B21 policy on fld-improvers-nonprod" || return 98
  return $rc
}

step OP-5.6 AUTO "Cloud Run tests: B17, B18, CC-3 in dry run" --removes --needs "REGION BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_5_6_check() { ckpt_done OP-5.6 || _p13_passed OP-5.6 run-tests; }
s_OP_5_6_apply() {
  local log bad=0 acc=0 rc p="$P13_PROBE" reg sa err
  reg="$(v REGION)"; sa="op-probe@$p.iam.gserviceaccount.com"
  _p13_need_done OP-5.2 "the probe's accounts exist" || return 1
  log="$(_p13_newlog)" || return 1
  x gcloud services enable run.googleapis.com --project="$p" || { rm -f "$log"; return 1; }
  _p13_refused "$log" "first deploy (B18)" 'constraints/run.allowedBinaryAuthorizationPolicies' \
    gcloud run deploy op-probe --image=us-docker.pkg.dev/cloudrun/container/hello --region="$reg" --no-allow-unauthenticated --service-account="$sa" --project="$p"; rc=$?
  [ $rc -eq 0 ] || { bad=1; [ $rc -eq 1 ] && acc=1; agp_say "      STOP: the first deploy must be refused naming run.allowedBinaryAuthorizationPolicies"; }
  if [ "$AGP_MODE" != apply ]; then
    x gcloud run deploy op-probe --image=us-docker.pkg.dev/cloudrun/container/hello --region="$reg" --no-allow-unauthenticated --service-account="$sa" --binary-authorization=default --project="$p"
    agp_say "        either outcome is recorded: refused naming run.allowedVPCEgress, or deployed (then deleted, and a CC for 18's spike list)"
  elif [ $bad = 0 ]; then
    err="$(_p13_newlog)" || return 1
    x gcloud run deploy op-probe --image=us-docker.pkg.dev/cloudrun/container/hello --region="$reg" --no-allow-unauthenticated --service-account="$sa" --binary-authorization=default --project="$p" 2>"$err"; rc=$?
    { echo "== second deploy (--binary-authorization=default, no VPC egress)"; sed 's/^ *//' "$err"; } >> "$log"
    if [ $rc -ne 0 ] && grep -q 'constraints/run.allowedVPCEgress' "$err"; then
      echo "SECOND-DEPLOY refused naming constraints/run.allowedVPCEgress: B17 also fences a service with no VPC egress" >> "$log"
      agp_say "      second deploy refused by run.allowedVPCEgress: recorded"
    elif [ $rc -eq 0 ]; then
      echo "SECOND-DEPLOY deployed: run.allowedVPCEgress does not fence a service that sets no VPC egress; a custom constraint requiring one goes to 18's spike list (OP-9.2)" >> "$log"
      agp_say "      second deploy succeeded: recorded; deleting the service (gcloud asks to confirm)"
      x gcloud run services delete op-probe --region="$reg" --project="$p" || bad=1
    else
      echo "SECOND-DEPLOY refused for another reason: read the error above" >> "$log"
      agp_say "      FAIL: the second deploy was refused, but not by run.allowedVPCEgress; read the error"; bad=1
    fi
    rm -f "$err"
    r gcloud run services list --project="$p" --region="$reg" --format="value(metadata.name)" | sed 's/^/        services: /' >&3
  fi
  agp_say "      raise in 03's tracker, as a dated decision before 23's and 33's first production deploys: B17 all-traffic or private-ranges-only"
  _p13_finish "$log" "$bad" OP-5.6 run-tests txt 5.3.1; rc=$?
  _p13_stop_accepted "$acc" "op-probe was deployed without Binary Authorization; read B18 on $P13_PROBE (policies/probe) and delete the service" || return 98
  return $rc
}

step OP-5.7 HUMAN "Sign the nonprod verdict" --needs "BUILD_LOG_DIR SECOND_HUMAN_EMAIL"
s_OP_5_7_check() { ckpt_done OP-5.7; }
s_OP_5_7_manual() {
  echo "WHO: the platform owner writes; $(v SECOND_HUMAN_EMAIL) reads OP-4.2 and OP-5.3 to OP-5.6 and signs (the security reviewer too where appointed)."
  printf 'WHERE: %s/records/.\n' "$(v BUILD_LOG_DIR)"
  echo "One page: per legacy constraint, the nonprod result (refused as expected, or effective read only for B6, B10, B11, B13),"
  echo "both SCC readings of OP-4.2, OP-5.6's second-deploy outcome, anything unexpected, and the decision 'apply at production' or 'stop'."
  echo "VERIFY: signed, dated, committed; the +24-hour SCC reading of OP-4.2 is at least 24 hours old."
  echo "RECORD: evidence_add OP-5.7 nonprod-verdict E-05 5.2.2 \"build-log:records/<file>\" \"<file>\""
  echo "A 'stop' verdict ends here: do not record this step. On 'apply at production': agp-platform done OP-5.7"
}

# ---------------------------------------------------------------- 6. Legacy constraints at production
step OP-6.1 AUTO "Apply B1 at fld-agentic-platform" --irreversible --removes --gate "SD-15" \
  --needs "PLATFORM_REPO_DIR FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE FLD_AGENTS_P_SA FLD_CONTROLLERS FLD_GEMINI_ENTERPRISE SCC_TIER BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_6_1_check() {
  ckpt_done OP-6.1 && return 0
  exists gcloud org-policies describe gcp.resourceLocations --folder="$(v FLD_AGENTIC_PLATFORM)" --format='value(name)'
}
s_OP_6_1_apply() {
  local log bad=0 n vals rc
  _p13_need_done OP-5.7 "the nonprod verdict is signed 'apply at production'" || return 1
  [ "$AGP_MODE" != apply ] || [ "$(v SCC_TIER)" = "PREMIUM/eu" ] || { agp_say "      STOP: SCC_TIER is not PREMIUM/eu"; return 1; }
  agp_say "      under the grant of OP-0.2; tell IT security the time (it co-signs OP-6.2)"
  log="$(_p13_newlog)" || return 1
  [ "$AGP_MODE" != apply ] || date -u +%Y-%m-%dT%H:%M:%SZ >> "$log"
  _p13_opset 1 "$(_p13_repo)/policies/org/FLD_AGENTIC_PLATFORM/gcp.resourceLocations.json" || { rm -f "$log"; return 1; }
  for n in FLD_PLATFORM_CORE FLD_AGENTS_P_SA FLD_CONTROLLERS FLD_GEMINI_ENTERPRISE; do
    if [ "$AGP_MODE" != apply ]; then agp_say "      read: the effective gcp.resourceLocations on $n lists in:eu-locations and is:europe"; continue; fi
    vals="$(r gcloud org-policies describe gcp.resourceLocations --folder="$(v "$n")" --effective --format=json | _p13_py values)"
    _p13_inherits gcp.resourceLocations "$P13_B1" FLD_AGENTIC_PLATFORM "$n"; rc=$?
    printf '== %s: inherits B1 from FLD_AGENTIC_PLATFORM: %s (the effective read printed: %s)\n' "$n" "$([ $rc -eq 0 ] && echo yes || echo NO)" "$vals" >> "$log"
    [ $rc -eq 0 ] && continue
    agp_say "      FAIL: $n does not inherit in:eu-locations and is:europe from fld-agentic-platform"; bad=1
  done
  _p13_finish "$log" "$bad" OP-6.1 b1-production txt 7.1.1
}

step OP-6.2 CONSOLE "Read SCC after the production location policy" --witness --needs "ORG_ID FLD_AGENTIC_PLATFORM"
s_OP_6_2_check() { ckpt_done OP-6.2; }
s_OP_6_2_manual() {
  echo "WHO: the platform owner; witness: IT security co-signs."
  echo "WHERE: as OP-1.5. OP-1.5's screenshots and five readings at +1 hour and at +24 hours after OP-6.1."
  echo "VERIFY: as OP-4.2: Premium, residency eu, both services ENABLED, findings call exits 0."
  printf 'On any difference: $ gcloud org-policies delete gcp.resourceLocations --folder=%s\n' "$(v FLD_AGENTIC_PLATFORM)"
  echo "  then IT security reactivates from the EU console, and the file stops."
  echo "RECORD: <date>-OP-6.2-scc-after-production-v1, signed; evidence_add it (TISAX 1.5.1, 7.1.2)."
  echo "Then: agp-platform done OP-6.2 --witness <IT security email>"
}

step OP-6.3 AUTO "Apply the other platform-wide legacy constraints, B21 included, at fld-agentic-platform" --irreversible --removes \
  --needs "PLATFORM_REPO_DIR FLD_AGENTIC_PLATFORM BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_63_files() { local c; for c in $P13_LEGACY; do [ "$c" = gcp.resourceLocations ] || printf '%s/policies/org/FLD_AGENTIC_PLATFORM/%s.json\n' "$(_p13_repo)" "$c"; done; }
s_OP_6_3_check() {
  ckpt_done OP-6.3 && return 0
  # shellcheck disable=SC2046
  _p13_all_exist $(_p13_63_files)
}
s_OP_6_3_apply() {
  local fm log
  _p13_need_done OP-6.2 "SCC read after the production location policy" || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: cut -f2,3 $(v BUILD_LOG_DIR)/checkpoints.tsv | grep -E '^FM-' prints nothing (B21 precedes the first module run); an FM- line stops the step"
  fi
  fm="$(cut -f2,3 "$(v BUILD_LOG_DIR)/checkpoints.tsv" 2>/dev/null | grep -E '^FM-' | head -3)"
  if [ -n "$fm" ]; then
    agp_say "      STOP: a module equivalent has run ($fm): B21 did not precede it; check 17's projects for non-HSM keys first"; return 1
  fi
  [ "$AGP_MODE" != apply ] || agp_say "      no FM- checkpoint: B21 precedes the first module run"
  # shellcheck disable=SC2046
  _p13_opset 12 $(_p13_63_files) || return 1
  log="$(_p13_newlog)" || return 1
  [ "$AGP_MODE" != apply ] || echo "no FM- checkpoint; 12 applied at fld-agentic-platform; commit policies/predecessors" >> "$log"
  _p13_finish "$log" 0 OP-6.3 legacy-production txt 4.1.1
}

step OP-6.4 AUTO "Apply B17 and B18 at the tier folders and B18 at fld-platform-core" --irreversible --removes \
  --needs "PLATFORM_REPO_DIR CORE_PROJECT REGION BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_64_files() {
  local p; p="$(_p13_repo)/policies/org"
  printf '%s\n' "$p/FLD_AGENTS_W/run.allowedVPCEgress.json" "$p/FLD_AGENTS_W/run.allowedBinaryAuthorizationPolicies.json" \
    "$p/FLD_AGENTS_P/run.allowedVPCEgress.json" "$p/FLD_AGENTS_P/run.allowedBinaryAuthorizationPolicies.json" \
    "$p/FLD_CONTROLLERS/run.allowedVPCEgress.json" "$p/FLD_CONTROLLERS/run.allowedBinaryAuthorizationPolicies.json" \
    "$p/FLD_PLATFORM_CORE/run.allowedBinaryAuthorizationPolicies.json"
}
s_OP_6_4_check() {
  ckpt_done OP-6.4 && return 0
  # shellcheck disable=SC2046
  _p13_all_exist $(_p13_64_files)
}
s_OP_6_4_apply() {
  local log out
  _p13_need_done OP-5.7 "the nonprod verdict is signed" || return 1
  # shellcheck disable=SC2046
  _p13_opset 7 $(_p13_64_files) || return 1
  log="$(_p13_newlog)" || return 1
  if [ "$AGP_MODE" = apply ]; then
    out="$(r gcloud run services list --project="$(v CORE_PROJECT)" --region="$(v REGION)" --format="value(metadata.name)")$(r gcloud run jobs list --project="$(v CORE_PROJECT)" --region="$(v REGION)" --format="value(metadata.name)")"
    printf 'Cloud Run services and jobs in CORE_PROJECT: [%s]\n' "$out" >> "$log"
    [ -z "$out" ] || agp_say "      NOTE: CORE_PROJECT runs Cloud Run resources ($out); B18 now binds their next revision to Binary Authorization"
  else
    agp_say "      read: gcloud run services list and gcloud run jobs list --project=$(v CORE_PROJECT) --region=$(v REGION) (none expected: 10 CP-6.2 is BLOCKED)"
  fi
  _p13_finish "$log" 0 OP-6.4 b17-b18-production txt 5.3.1
}

step OP-6.5 AUTO "Remove the nonprod duplicates and confirm the held constraints are absent" --removes \
  --needs "FLD_IMPROVERS_NONPROD FLD_AGENTS_W_NONPROD FLD_AGENTS_P_NONPROD FLD_CONTROLLERS_NONPROD FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_pol_delete() {     # CONSTRAINT FOLDER_ID: delete the folder's own policy; an absent one is already done
  local rc=1
  if [ "$AGP_MODE" = apply ]; then
    exists gcloud org-policies describe "$1" --folder="$2" --format='value(name)'; rc=$?
    [ $rc -eq 1 ] && { agp_say "      $1 on folders/$2: already absent"; return 0; }
    [ $rc -eq 0 ] || return 1
  fi
  x gcloud org-policies delete "$1" --folder="$2"
}
s_OP_6_5_check() { ckpt_done OP-6.5 || _p13_passed OP-6.5 dedup-held; }
s_OP_6_5_apply() {
  local log bad=0 acc=0 c n rc vals
  _p13_need_done OP-6.4 "the production copies are in force" || return 1
  _p13_need_done OP-6.3 "the production copies are in force" || return 1
  log="$(_p13_newlog)" || return 1
  for c in $P13_LEGACY; do _p13_pol_delete "$c" "$(v FLD_IMPROVERS_NONPROD)" || bad=1; done
  for n in FLD_AGENTS_W_NONPROD FLD_AGENTS_P_NONPROD FLD_CONTROLLERS_NONPROD; do
    _p13_pol_delete run.allowedVPCEgress "$(v "$n")" || bad=1
    _p13_pol_delete run.allowedBinaryAuthorizationPolicies "$(v "$n")" || bad=1
  done
  for n in FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE FLD_AGENTS_W FLD_AGENTS_P FLD_CONTROLLERS; do
    for c in run.allowedIngress gcp.restrictNonCmekServices gcp.restrictCmekCryptoKeyProjects; do
      if [ "$AGP_MODE" != apply ]; then continue; fi
      _p13_pre exists gcloud org-policies describe "$c" --folder="$(v "$n")" --format='value(name)'; rc=$?
      case $rc in 1) ;; 0) echo "PRESENT $c on $n" >> "$log"; agp_say "      FAIL: PRESENT $c on $n (held: P3, P12)"; bad=1;; *) bad=1;; esac
    done
  done
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: run.allowedIngress, gcp.restrictNonCmekServices, gcp.restrictCmekCryptoKeyProjects absent on the five production folders"
    agp_say "      read: the effective gcp.resourceLocations on FLD_IMPROVERS_NONPROD still lists both values (inherited)"
  else
    vals="$(r gcloud org-policies describe gcp.resourceLocations --folder="$(v FLD_IMPROVERS_NONPROD)" --effective --format=json | _p13_py values)"
    _p13_inherits gcp.resourceLocations "$P13_B1" FLD_AGENTIC_PLATFORM FLD_IMPROVERS_NONPROD; rc=$?
    echo "effective B1 on fld-improvers-nonprod, inherited from fld-agentic-platform: $([ $rc -eq 0 ] && echo yes || echo NO) (the effective read printed: $vals)" >> "$log"
    [ $rc -eq 0 ] || { agp_say "      FAIL: B1 is no longer effective on fld-improvers-nonprod"; bad=1; }
  fi
  _p13_refused "$log" "OP-5.3 (1) again" 'constraints/gcp.resourceLocations' \
    gcloud storage buckets create "gs://$P13_PROBE-us" --project="$P13_PROBE" --location=us-central1 --uniform-bucket-level-access; rc=$?
  if [ $rc -eq 1 ]; then bad=1; acc=1; x gcloud storage buckets delete "gs://$P13_PROBE-us" --project="$P13_PROBE"; elif [ $rc -ne 0 ]; then bad=1; fi
  _p13_finish "$log" "$bad" OP-6.5 dedup-held txt 5.2.1; rc=$?
  _p13_stop_accepted "$acc" "B1 no longer refuses on the probe: re-apply the nonprod copy with op-set.sh from its file (the page's rollback) and read why" || return 98
  return $rc
}

# ---------------------------------------------------------------- 7. Deny policies and principal access boundaries
step OP-7.1 AUTO "Create the probe fixtures" --needs "CORE_PROJECT SA_FACTORY_APPLY SA_1_ADMIN REGION BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_7_1_check() {
  local c t rc
  ckpt_done OP-7.1 && return 0
  c="$(v CORE_PROJECT)"; t="op-probe-target@$c.iam.gserviceaccount.com"
  has_binding "serviceAccount:$(v SA_FACTORY_APPLY)" roles/iam.serviceAccountTokenCreator gcloud iam service-accounts get-iam-policy "$t" --project="$c" || return $?
  has_binding "serviceAccount:op-probe@$P13_PROBE.iam.gserviceaccount.com" roles/storage.admin gcloud storage buckets get-iam-policy "gs://$c-op-probe" --project="$c" || return $?
  has_binding "serviceAccount:op-probe@$P13_PROBE.iam.gserviceaccount.com" roles/iam.serviceAccountTokenCreator gcloud iam service-accounts get-iam-policy "op-probe-target@$P13_PROBE.iam.gserviceaccount.com" --project="$P13_PROBE" || return $?
  has_binding "user:$(v SA_1_ADMIN)" roles/iam.serviceAccountTokenCreator gcloud iam service-accounts get-iam-policy "op-probe@$P13_PROBE.iam.gserviceaccount.com" --project="$P13_PROBE"; rc=$?
  return $rc
}
s_OP_7_1_apply() {
  local c p="$P13_PROBE" t log bad=0 pol
  c="$(v CORE_PROJECT)"; t="op-probe-target@$c.iam.gserviceaccount.com"
  _p13_need_done OP-5.2 "the probe's accounts exist" || return 1
  agp_say "      under an ENT_PROJECT_REPAIR_CORE grant for the core half (approver: the one 12 recorded)"
  x gcloud services enable policytroubleshooter.googleapis.com --project="$c" || return 1
  _p13_sa_create op-probe-target "$c" "op-probe-target, holds no role (setup 13)" || return 1
  x gcloud iam service-accounts add-iam-policy-binding "$t" --member="serviceAccount:$(v SA_FACTORY_APPLY)" --role="roles/iam.serviceAccountTokenCreator" --project="$c" >/dev/null || return 1
  _p13_bucket_create "gs://$c-op-probe" "$c" "$(v REGION)" || return 1
  x gcloud storage buckets add-iam-policy-binding "gs://$c-op-probe" --member="serviceAccount:op-probe@$p.iam.gserviceaccount.com" --role="roles/storage.admin" --project="$c" >/dev/null || return 1
  x gcloud iam service-accounts add-iam-policy-binding "op-probe-target@$p.iam.gserviceaccount.com" --member="serviceAccount:op-probe@$p.iam.gserviceaccount.com" --role="roles/iam.serviceAccountTokenCreator" --project="$p" >/dev/null || return 1
  x gcloud iam service-accounts add-iam-policy-binding "op-probe@$p.iam.gserviceaccount.com" --member="user:$(v SA_1_ADMIN)" --role="roles/iam.serviceAccountTokenCreator" --project="$p" >/dev/null || return 1
  agp_say "      policytroubleshooter is not governed by gcp.restrictServiceUsage; its enabling is recorded in BD-13-2 (OP-9.2)"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: the core op-probe-target holds exactly the token-creator binding for factory-apply@; the bucket roles/storage.admin for op-probe@ only"
    _p13_save OP-7.1 fixtures txt 4.2.1 /dev/null; return 0
  fi
  log="$(_p13_newlog)" || return 1
  pol="$(r gcloud iam service-accounts get-iam-policy "$t" --project="$c" --format=json)"
  printf '== %s\n%s\n' "$t" "$pol" >> "$log"
  printf '%s' "$pol" | _p13_py only-binding "serviceAccount:$(v SA_FACTORY_APPLY)" roles/iam.serviceAccountTokenCreator \
    || { agp_say "      FAIL: $t holds more or other than the token-creator binding for factory-apply@"; bad=1; }
  pol="$(r gcloud storage buckets get-iam-policy "gs://$c-op-probe" --project="$c" --format=json)"
  printf '== gs://%s-op-probe\n%s\n' "$c" "$pol" >> "$log"
  printf '%s' "$pol" | python3 "$AGP_HOME/lib/agp_json.py" has-binding "serviceAccount:op-probe@$p.iam.gserviceaccount.com" roles/storage.admin \
    || { agp_say "      FAIL: the core bucket does not show roles/storage.admin for op-probe@"; bad=1; }
  _p13_finish "$log" "$bad" OP-7.1 fixtures txt 4.2.1
}

step OP-7.2 HUMAN "Merge the probe workflow that runs as factory-apply@, and take the baseline" \
  --needs "PLATFORM_REPO_DIR WIF_PROVIDER SA_FACTORY_APPLY CORE_PROJECT TF_STATE_BUCKET BILLING_ACCOUNT_ID CICD_PROJECT"
s_OP_7_2_check() { ckpt_done OP-7.2; }
s_OP_7_2_manual() {
  echo "WHO: the platform owner opens the pull request; the required reviewers merge; the platform owner triggers the run."
  printf 'WHERE: %s and the git host.\n' "$(_p13_repo)"
  echo "Write .github/workflows/op-deny-probe.yml from setup/13 OP-7.2 (same auth step and commit SHA as 10's wif-smoke), with:"
  printf '  WIF_PROVIDER=%s  SA_FACTORY_APPLY=%s\n' "$(v WIF_PROVIDER)" "$(v SA_FACTORY_APPLY)"
  printf '  CORE_PROJECT=%s  TF_STATE_BUCKET=%s  BILLING_ACCOUNT_ID=%s  CICD_PROJECT=%s\n' "$(v CORE_PROJECT)" "$(v TF_STATE_BUCKET)" "$(v BILLING_ACCOUNT_ID)" "$(v CICD_PROJECT)"
  echo "  (GitLab SaaS: 10 CP-5.3's ID-token job with the same three run lines.)"
  echo "After the merge: Actions > op-deny-probe > Run workflow on main."
  echo "VERIFY: R6-PROBE: MINTED (token discarded); INSIDE: state bucket readable; BUDGETS: readable. Any refusal: fix the fixture first."
  echo "RECORD: run URL and log as <date>-OP-7.2-probe-baseline-v1 (TISAX 4.2.1, 5.2.1). Then: agp-platform done OP-7.2"
}

step OP-7.3 HUMAN "Take the baseline as op-probe@" --needs "CORE_PROJECT BUILD_LOG_DIR" \
  --note "mints an access token for op-probe-target@: no credential passes through the script (PHASES.md rule 6)"
s_OP_7_3_check() { ckpt_done OP-7.3; }
s_OP_7_3_manual() {
  local c imp="op-probe@$P13_PROBE.iam.gserviceaccount.com"; c="$(v CORE_PROJECT)"
  echo "WHO: the platform owner. WHERE: shell, ~/.platform-env sourced, PROBE=$P13_PROBE. After OP-7.1."
  echo "Paste setup/13 OP-7.3's three commands as the page has them (IMP=$imp): the generateAccessToken call"
  echo "  is filtered by jq so a minted token is never printed; then the objectViewer binding on gs://$c-op-probe as op-probe@,"
  echo "  and its removal (the page's third command)."
  echo "VERIFY: DI-PROBE MINTED (token discarded) and DCA-PROBE: binding set; otherwise fix the fixtures (OP-7.1) first."
  printf 'RECORD: the output as <date>-OP-7.3-human-probe-baseline-v1.txt in %s/records (TISAX 4.2.1).\n' "$(v BUILD_LOG_DIR)"
  echo "Then: agp-platform done OP-7.3"
}

step OP-7.4 AUTO "Create deny-agents-platform at fld-agentic-platform" --irreversible \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM ENT_PLATFORM_POLICY CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "DENY_AGENTS_PLATFORM"
s_OP_7_4_check() { _p13_deny_check OP-7.4 deny-agents-platform FLD_AGENTIC_PLATFORM DENY_AGENTS_PLATFORM; }
s_OP_7_4_apply() {
  _p13_need_done OP-7.3 "the baselines are taken" || return 1
  _p13_need_done OP-7.2 "the workflow baseline is taken" || return 1
  _p13_deny_create OP-7.4 deny-agents-platform FLD_AGENTIC_PLATFORM DENY_AGENTS_PLATFORM
}

step OP-7.5 AUTO "Create deny-core-agents at fld-platform-core" --irreversible \
  --needs "ORG_ID FLD_PLATFORM_CORE ENT_PLATFORM_POLICY CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "DENY_CORE_AGENTS"
s_OP_7_5_check() { _p13_deny_check OP-7.5 deny-core-agents FLD_PLATFORM_CORE DENY_CORE_AGENTS; }
s_OP_7_5_apply() { _p13_deny_create OP-7.5 deny-core-agents FLD_PLATFORM_CORE DENY_CORE_AGENTS; }

step OP-7.6 AUTO "Create deny-improvers at fld-agentic-platform" --irreversible --gate "SD-24" \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM TAG_KEY_TIER ENT_PLATFORM_POLICY CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "DENY_IMPROVERS"
s_OP_7_6_check() { _p13_deny_check OP-7.6 deny-improvers FLD_AGENTIC_PLATFORM DENY_IMPROVERS; }
s_OP_7_6_apply() {
  local key s
  # The page's two tag reads come first here (reads only): a policy whose four conditions cannot match is not created.
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud resource-manager tags keys describe $(v ORG_ID)/agp-tier resolves to TAG_KEY_TIER; its values include w, p, p-sa, ctl"
  else
    key="$(r gcloud resource-manager tags keys describe "$(v ORG_ID)/agp-tier" --format="value(name)")"
    agp_say "      $(v ORG_ID)/agp-tier: $key"
    # decided as filtered lists: the key of that short name is TAG_KEY_TIER; each value exists under it
    nonempty r gcloud resource-manager tags keys list --parent="organizations/$(v ORG_ID)" \
      --filter="shortName=agp-tier AND name=$(v TAG_KEY_TIER)" --format="value(name)" \
      || { agp_say "      FAIL: $(v ORG_ID)/agp-tier does not resolve to TAG_KEY_TIER ($(v TAG_KEY_TIER)); nothing created"; return 1; }
    for s in w p p-sa ctl; do
      nonempty r gcloud resource-manager tags values list --parent="$(v TAG_KEY_TIER)" --filter="shortName=$s" --format="value(name)" \
        || { agp_say "      FAIL: the agp-tier key has no value '$s'; the conditions of deny-improvers cannot match; nothing created"; return 1; }
    done
    agp_say "      tag key resolves to TAG_KEY_TIER; values w, p, p-sa, ctl present"
  fi
  _p13_deny_create OP-7.6 deny-improvers FLD_AGENTIC_PLATFORM DENY_IMPROVERS
}

step OP-7.7 HUMAN "Prove the three deny policies" --needs "CORE_PROJECT SA_FACTORY_APPLY SA_PLATFORM_DRIFT SECOND_HUMAN_EMAIL BUILD_LOG_DIR"
s_OP_7_7_check() { ckpt_done OP-7.7; }
s_OP_7_7_manual() {
  echo "WHO: the platform owner runs; $(v SECOND_HUMAN_EMAIL) reads the outputs and initials the record. Wait 10 minutes after OP-7.6."
  echo "WHERE: shell, under an ENT_PROJECT_REPAIR_CORE grant (quota project CORE_PROJECT), and the git host."
  printf '1. Paste setup/13 OP-7.7'"'"'s block (TS_RAW, TS and the six TS lines; PROBE=%s). Record which path TS_RAW took (beta or REST).\n' "$P13_PROBE"
  echo "   Lines 1-3, 5, 6: DENY_ACCESS_STATE_DENIED; line 4 (control): only DENY_ACCESS_STATE_NOT_DENIED."
  echo "2. Run op-deny-probe on main: R6-PROBE: REFUSED (Permission 'iam.serviceAccounts.getAccessToken' denied); INSIDE and BUDGETS readable."
  echo "3. Repeat OP-7.3's first two commands: DI-PROBE REFUSED 403 ...; the bucket binding refused with 403."
  echo "Any expected refusal that succeeded: delete no policy, remove the fixture binding that allowed it, and stop."
  echo "Re-run points (not provable today): deny-improvers rules 2 to 5 (36's MD-3); every agent-identity entry (17, 18's P8)."
  echo "RECORD: <date>-OP-7.7-deny-proof-v1, initialled; evidence_add it (E-05, TISAX 4.2.1, 1.5.1)."
  echo "Then: agp-platform done OP-7.7"
}

step OP-7.8 AUTO "Create pab-agents" --irreversible \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM ENT_PLATFORM_POLICY CICD_PROJECT PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "PAB_AGENTS"
s_OP_7_8_check() {
  ckpt_done OP-7.8 && return 0
  exists gcloud iam principal-access-boundary-policies describe pab-agents --organization="$(v ORG_ID)" --location=global --format='value(name)' || return $?
  has_value PAB_AGENTS
}
s_OP_7_8_apply() {
  local o rec out bad=0
  o="$(v ORG_ID)"; rec="$(_p13_recpath OP-7.8 pab-agents json)"
  _p13_need_done OP-7.7 "the deny policies are proven" || return 1
  _p13_grant_guard || return 1
  _p13_pab_create pab-agents "$(_p13_repo)/policies/pab/pab-agents.rules.json" || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: describe pab-agents into records/$(basename "$rec"): enforcementVersion 4, one rule, //cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)"
    agp_say "      read: gcloud iam principal-access-boundary-policies search-policy-bindings pab-agents prints nothing (17 binds it per project)"
    pset PAB_AGENTS "organizations/$o/locations/global/principalAccessBoundaryPolicies/pab-agents"
    ev OP-7.8 pab-agents E-05 4.2.1 "build-log:records/$(basename "$rec")"; return 0
  fi
  _p13_grant_record OP-7.8 || return 1
  x mkdir -p "$(dirname "$rec")" || return 1
  r gcloud iam principal-access-boundary-policies describe pab-agents --organization="$o" --location=global --format=json | xw "$rec" || return 1
  _p13_pab_ok pab-agents || { agp_say "      FAIL: pab-agents is not version 4 with the one folder rule"; bad=1; }
  out="$(_p13_pre r gcloud iam principal-access-boundary-policies search-policy-bindings pab-agents --organization="$o" --location=global --format="value(name)")"
  [ -z "$out" ] || { agp_say "      FAIL: pab-agents already has bindings: $out"; bad=1; }
  [ $bad = 0 ] || return 1
  pset PAB_AGENTS "organizations/$o/locations/global/principalAccessBoundaryPolicies/pab-agents" || return 1
  ev OP-7.8 pab-agents E-05 4.2.1 "build-log:records/$(basename "$rec")" "$rec"
}

step OP-7.9 AUTO "Create pab-core-ci and bind it to factory-apply@ and platform-drift@" --irreversible \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM CICD_PROJECT CORE_PROJECT SA_FACTORY_APPLY SA_PLATFORM_DRIFT ENT_PLATFORM_POLICY PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER" --sets "PAB_CORE_CI"
s_OP_7_9_check() {
  ckpt_done OP-7.9 && return 0
  exists gcloud iam principal-access-boundary-policies describe pab-core-ci --organization="$(v ORG_ID)" --location=global --format='value(name)' || return $?
  exists gcloud iam policy-bindings describe pab-core-ci-factory-apply --project="$(v CICD_PROJECT)" --location=global --format='value(name)' || return $?
  exists gcloud iam policy-bindings describe pab-core-ci-platform-drift --project="$(v CORE_PROJECT)" --location=global --format='value(name)' || return $?
  has_value PAB_CORE_CI
}
_p13_pab_ok() {    # POLICY_ID: version 4, its rule on fld-agentic-platform (the page's describe, as a filtered list)
  nonempty r gcloud iam principal-access-boundary-policies list --organization="$(v ORG_ID)" --location=global \
    --filter="name~\"/principalAccessBoundaryPolicies/$1\$\" AND details.enforcementVersion=4 AND details.rules.resources=\"//cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)\"" \
    --format="value(name)"
}
_p13_bind_ok() {   # BINDING_ID PROJECT_VAR SA_VAR WHO: the binding of pab-core-ci, with its condition, on the project
  nonempty r gcloud iam policy-bindings list --project="$(v "$2")" --location=global \
    --filter="name~\"/policyBindings/$1\$\" AND policy~\"/principalAccessBoundaryPolicies/pab-core-ci\$\" AND condition.title=\"$4 only\" AND condition.expression~\"principal.subject == .$(v "$3").\"" \
    --format="value(name)"
}
_p13_pab_bind() {   # BINDING_ID PROJECT_VAR SA_VAR WHO: a conditioned binding of pab-core-ci, unless it exists
  local rc=1 proj
  proj="$(v "$2")"
  [ "$AGP_MODE" != apply ] || { _p13_pre exists gcloud iam policy-bindings describe "$1" --project="$proj" --location=global --format='value(name)'; rc=$?; }
  case $rc in
    0) agp_say "      $1 exists; not created again"; return 0;;
    1) x gcloud iam policy-bindings create "$1" --project="$proj" --location=global \
         --policy="organizations/$(v ORG_ID)/locations/global/principalAccessBoundaryPolicies/pab-core-ci" \
         --target-principal-set="//cloudresourcemanager.googleapis.com/projects/$proj" \
         --condition-title="$4 only" --condition-description="02 4.4: only $4@ is bound" \
         --condition-expression="principal.type == 'iam.googleapis.com/ServiceAccount' && principal.subject == '$(v "$3")'" \
         --display-name="pab-core-ci $4";;
    *) return 1;;
  esac
}
s_OP_7_9_apply() {
  local o rec
  o="$(v ORG_ID)"; rec="$(_p13_recpath OP-7.9 pab-core-ci-bindings json)"
  _p13_need_done OP-7.8 "pab-agents first" || return 1
  agp_say "      also under an ENT_PROJECT_REPAIR_CORE grant: a binding on a project's principal set needs Project IAM Admin there"
  _p13_grant_guard || return 1
  _p13_pab_create pab-core-ci "$(_p13_repo)/policies/pab/pab-core-ci.rules.json" || return 1
  _p13_pab_bind pab-core-ci-factory-apply CICD_PROJECT SA_FACTORY_APPLY factory-apply || return 1
  _p13_pab_bind pab-core-ci-platform-drift CORE_PROJECT SA_PLATFORM_DRIFT platform-drift || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: search-policy-bindings pab-core-ci into records/$(basename "$rec"): two bindings, each with its condition; enforcementVersion 4"
    pset PAB_CORE_CI "organizations/$o/locations/global/principalAccessBoundaryPolicies/pab-core-ci"
    ev OP-7.9 pab-core-ci E-05 4.2.1 "build-log:records/$(basename "$rec")"; return 0
  fi
  _p13_grant_record OP-7.9 || return 1
  x mkdir -p "$(dirname "$rec")" || return 1
  r gcloud iam principal-access-boundary-policies search-policy-bindings pab-core-ci --organization="$o" --location=global --format=json | xw "$rec" || return 1
  _p13_pab_ok pab-core-ci || { agp_say "      FAIL: pab-core-ci is not version 4 with the one folder rule"; return 1; }
  _p13_bind_ok pab-core-ci-factory-apply CICD_PROJECT SA_FACTORY_APPLY factory-apply \
    && _p13_bind_ok pab-core-ci-platform-drift CORE_PROJECT SA_PLATFORM_DRIFT platform-drift \
    || { agp_say "      FAIL: the two bindings, each with its condition, are not both listed; read $rec"; return 1; }
  agp_say "      record both grant names (ENT_PLATFORM_POLICY and ENT_PROJECT_REPAIR_CORE) with this step"
  pset PAB_CORE_CI "organizations/$o/locations/global/principalAccessBoundaryPolicies/pab-core-ci" || return 1
  ev OP-7.9 pab-core-ci E-05 4.2.1 "build-log:records/$(basename "$rec")" "$rec"
}

step OP-7.10 HUMAN "Prove pab-core-ci, and record what it costs" \
  --needs "ORG_ID CICD_PROJECT SA_FACTORY_APPLY SA_PLATFORM_DRIFT SA_K7_EXECUTOR SECOND_HUMAN_EMAIL"
s_OP_7_10_check() { ckpt_done OP-7.10; }
s_OP_7_10_manual() {
  echo "WHO: the platform owner; $(v SECOND_HUMAN_EMAIL) initials. WHERE: shell and the git host. Wait 30 minutes after OP-7.9."
  echo "Paste setup/13 OP-7.10's block (TSP over OP-7.7's TS_RAW; four lines), then run op-deny-probe once more."
  echo "VERIFY 1: lines 1 and 3: pab-core-ci applies, PAB_ACCESS_STATE_NOT_ALLOWED; line 2 not blocked; line 4 (k7-executor@) not enforced."
  echo "VERIFY 2: INSIDE: state bucket readable. BUDGETS: readable or REFUSED; REFUSED means budgets move to the privileged"
  echo "  phase (02 3.4's fallback), recorded for 17 as a re-run point; readable means 17's negative test adds the live denial."
  echo "VERIFY 3: record for 16: platform-drift@ cannot read organisation-level policy or IAM while bound."
  echo "RECORD: outputs and run URL as <date>-OP-7.10-pab-proof-v1, initialled (TISAX 4.2.1, 1.5.1)."
  echo "Then: agp-platform done OP-7.10"
}

# ---------------------------------------------------------------- 8. Enforcement after the dry-run window
step OP-8.1 AUTO-READ "Collect every dry-run violation of the window" \
  --needs "PLATFORM_ENV_FILE DRILL_CALENDAR $P13_CORE BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_8_1_check() { ckpt_done OP-8.1; }
s_OP_8_1_apply() {
  local vd end n f p sums
  end="$(_p13_py cal-end "$(v DRILL_CALENDAR)" 2>/dev/null)"
  _p13_need_done OP-7.7 "the deny proof is initialled" || return 1
  _p13_need_done OP-7.10 "the PAB proof is initialled" || return 1
  if [ "$AGP_MODE" = apply ]; then
    [ -n "$end" ] || { agp_say "      STOP: no 13-dryrun row in DRILL_CALENDAR (OP-3.4)"; return 1; }
    [ "$(_p13_today)" \< "$end" ] && { agp_say "      STOP: the dry-run window ends $end; §8 does not start before it (the page's gate). Resume on or after $end"; return 98; }
  else agp_say "      gate: today is on or after the 13-dryrun end date in DRILL_CALENDAR (${end:-not recorded yet})"; fi
  vd="$(_p13_recpath OP-8.1 dryrun-violations "")"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud logging read '$P13_DRYLOG' --freshness=16d on every FLD_* folder of ~/.platform-env and every project directly under it"
    agp_say "      read: gcloud services list --enabled on the five core projects; summary.tsv in records/$(basename "$vd")/"
    agp_say "      would write records/$(basename "$vd")/SHA256SUMS (the hash of every file in it), registered as the evidence file"
    ev OP-8.1 dryrun-violations E-05 1.5.1 "build-log:records/$(basename "$vd")/SHA256SUMS"; return 0
  fi
  x mkdir -p "$vd" || return 1
  for n in $(_p13_fld_vars); do
    f="$(v "$n")"
    r gcloud logging read "$P13_DRYLOG" --folder="$f" --freshness=16d --format=json | xw "$vd/folder-$n.json" || { agp_say "      READ-ERROR folder $n"; return 1; }
    for p in $(r gcloud projects list --filter="parent.type=folder AND parent.id=$f" --format="value(projectId)"); do
      r gcloud logging read "$P13_DRYLOG" --project="$p" --freshness=16d --format=json | xw "$vd/project-$p.json" || { agp_say "      READ-ERROR project $p"; return 1; }
    done
  done
  _p13_py summary "$vd" | xw "$vd/summary.tsv" || return 1
  sed 's/^/        /' "$vd/summary.tsv" >&3
  for n in $P13_CORE; do
    r gcloud services list --enabled --project="$(v "$n")" --format="value(config.name)" | xw "$vd/enabled-$n.txt" || return 1
  done
  sums="$(cd "$vd" && shasum -a 256 -- *.json summary.tsv enabled-*.txt)" || { agp_say "      FAIL: the files could not be hashed"; return 1; }
  printf '%s\n' "$sums" | xw "$vd/SHA256SUMS" || return 1
  agp_say "      every row is the probe's expected compute or cloudkms entry, or needs a decision in OP-8.2; compare enabled-*.txt with the core allow-list"
  ev OP-8.1 dryrun-violations E-05 1.5.1 "build-log:records/$(basename "$vd")/SHA256SUMS" "$vd/SHA256SUMS"
}

step OP-8.2 HUMAN "Decide each violation, and merge the enforcement files" --needs "PLATFORM_REPO_DIR SECOND_HUMAN_EMAIL"
s_OP_8_2_check() { ckpt_done OP-8.2; }
s_OP_8_2_manual() {
  local p; p="$(_p13_repo)"
  echo "WHO: the platform owner proposes; the required reviewers ($(v SECOND_HUMAN_EMAIL); the security reviewer where appointed) decide by merging."
  printf 'WHERE: %s, the git host.\n' "$p"
  echo "For each non-probe row of OP-8.1's summary.tsv: add the service to the folder's dry-run allow-list with its reason, or record"
  echo "why the call stays refused. Then run setup/13 OP-8.2's block: branch setup-13-enforce, one policies/org/<folder>/<constraint>.json"
  echo "twin per policies/dryrun file with spec and no dryRunSpec, commit, push."
  echo "The pull request links OP-8.1's summary and lists each decision; any allow-list change is repeated in setup/13's table."
  echo "VERIFY: merged with two human approvals; every dryrun file has its org twin."
  echo "RECORD: evidence_add OP-8.2 enforcement-files-merged E-05 5.2.1 \"git:<commit>\". Then: agp-platform done OP-8.2"
}

step OP-8.3 AUTO "Enforce the managed, TLS, WIF and custom constraints" --irreversible --removes \
  --needs "PLATFORM_REPO_DIR WIF_PROVIDER CICD_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_83_files() {
  local p; p="$(_p13_repo)/policies/org"
  printf '%s\n' "$p/FLD_AGENTIC_PLATFORM/iam.managed.disableServiceAccountKeyCreation.json" "$p/FLD_AGENTIC_PLATFORM/iam.managed.disableServiceAccountKeyUpload.json" \
    "$p/FLD_AGENTIC_PLATFORM/essentialcontacts.managed.allowedContactDomains.json" "$p/FLD_AGENTIC_PLATFORM/gcp.restrictTLSVersion.json" \
    "$p/FLD_PLATFORM_CORE/iam.managed.workloadIdentityPoolProviders.json" "$p/FLD_AGENTIC_PLATFORM/custom.agpProjectIdPrefix.json" \
    "$p/FLD_AGENTIC_PLATFORM/custom.fldFolderNaming.json" "$p/FLD_AGENTS_W/custom.runBinaryAuthorizationRequired.json" \
    "$p/FLD_AGENTS_P/custom.runBinaryAuthorizationRequired.json" "$p/FLD_CONTROLLERS/custom.runBinaryAuthorizationRequired.json"
}
s_OP_8_3_check() {
  ckpt_done OP-8.3 && return 0
  # shellcheck disable=SC2046
  _p13_all_state spec $(_p13_83_files)
}
s_OP_8_3_apply() {
  local w st log bad=0
  w="$(v WIF_PROVIDER)"
  _p13_need_done OP-8.2 "the enforcement files are merged" || return 1
  agp_say "      under a grant of OP-0.2 whose justification is OP-8.2's pull request"
  x git -C "$(_p13_repo)" checkout main || return 1
  x git -C "$(_p13_repo)" pull || return 1
  # shellcheck disable=SC2046
  _p13_opset 10 $(_p13_83_files) || return 1
  log="$(_p13_newlog)" || return 1
  if [ "$AGP_MODE" = apply ]; then
    # shellcheck disable=SC2046
    _p13_all_state spec $(_p13_83_files) || { agp_say "      FAIL: a read-back still has dryRunSpec, or no spec"; bad=1; }
    st="$(r gcloud iam workload-identity-pools providers describe "${w##*/}" --workload-identity-pool=wif-factory --location=global --project="$(v CICD_PROJECT)" --format="value(state)")"
    echo "WIF provider state: $st" >> "$log"
    [ "$st" = ACTIVE ] || { agp_say "      FAIL: 10's provider is '$st', not ACTIVE"; bad=1; }
  else
    agp_say "      read: each read-back has spec and no dryRunSpec; 10's WIF provider still ACTIVE"
  fi
  agp_say "      then run 10's wif-smoke on main: it must succeed (B19 limits creating providers, not using them)"
  _p13_finish "$log" "$bad" OP-8.3 enforced-managed txt 4.1.1
}

step OP-8.4 AUTO "Enforce the allow-lists, least exposed folder first" --irreversible --removes \
  --needs "PLATFORM_REPO_DIR PLATFORM_ENV_FILE KMS_PROJECT REGION BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_84_order() { echo "FLD_AGENTS_X FLD_IMPROVERS FLD_AGENTS_R FLD_AGENTS_R_NONPROD FLD_AGENTS_W FLD_AGENTS_P FLD_AGENTS_P_SA FLD_CONTROLLERS KMS_PROJECT FLD_PLATFORM_CORE"; }
_p13_84_files() { local t; for t in $(_p13_84_order); do printf '%s/policies/org/%s/gcp.restrictServiceUsage.json\n' "$(_p13_repo)" "$t"; done; }
_p13_84_projects() {    # T: the projects at or under T today (T a project variable, or a folder and its FLD_ children)
  local n
  case "$1" in KMS_PROJECT) v KMS_PROJECT; echo; return 0;; esac
  for n in $(_p13_fld_vars); do
    case "$n" in "$1"|"$1"_*) r gcloud projects list --filter="parent.type=folder AND parent.id=$(v "$n")" --format="value(projectId)";; esac
  done
}
s_OP_8_4_check() {
  ckpt_done OP-8.4 && return 0
  # shellcheck disable=SC2046
  _p13_all_state spec $(_p13_84_files)
}
s_OP_8_4_apply() {
  local t f n=0 log bad=0 projs p out marker
  _p13_need_done OP-8.3 "the managed constraints are enforced" || return 1
  agp_say "      under the grant of OP-8.3; one folder at a time, least exposed first, KMS_PROJECT and fld-platform-core last"
  if [ "$AGP_MODE" != apply ]; then
    # shellcheck disable=SC2046
    _p13_opset 9 $(_p13_84_files | grep -v '/FLD_PLATFORM_CORE/')
    agp_say "      between folders that hold projects: 10 minutes, then gcloud logging read for live refusals naming gcp.restrictServiceUsage"
    agp_say "      STOP (the page's): a person re-runs 10's wif-smoke, gcloud kms keyrings list --project=$(v KMS_PROJECT), and op-deny-probe's INSIDE step;"
    agp_say "        all pass: resume with --from OP-8.4, which applies the last folder"
    _p13_opset 1 "$(_p13_repo)/policies/org/FLD_PLATFORM_CORE/gcp.restrictServiceUsage.json"
    agp_say "      then the same three core checks once more"
    _p13_save OP-8.4 enforced-allowlists txt 1.3.3 /dev/null; return 0
  fi
  [ -x "$(_p13_repo)/policies/tools/op-set.sh" ] || { agp_say "      STOP: op-set.sh is missing (OP-0.3)"; return 1; }
  log="$(_p13_newlog)" || return 1
  marker="$(v BUILD_LOG_DIR)/records/.OP-8.4-paused-after-kms"
  for t in $(_p13_84_order); do
    f="$(_p13_repo)/policies/org/$t/gcp.restrictServiceUsage.json"
    [ -f "$f" ] || { agp_say "      STOP: $f is missing (OP-8.2)"; rm -f "$log"; return 1; }
    if _p13_pre _p13_enforced_since "$f"; then agp_say "      $t already enforced"; n=$((n + 1)); continue; fi
    x "$(_p13_repo)/policies/tools/op-set.sh" "$f" || { agp_say "      STOP at $t; roll it back with op-set.sh on its predecessor (its dry-run form) and return to OP-8.2"; break; }
    n=$((n + 1)); echo "enforced $t" >> "$log"
    projs="$(_p13_84_projects "$t" | grep .)"
    if [ -n "$projs" ]; then
      agp_say "      $t holds projects; reading live refusals for 10 minutes"
      _p13_sleep 600
      for p in $projs; do
        out="$(r gcloud logging read 'protoPayload.status.code=7 AND "constraints/gcp.restrictServiceUsage"' --project="$p" --freshness=15m --limit=20 \
                --format="table(timestamp,protoPayload.serviceName,protoPayload.methodName)")"
        printf '== live refusals in %s after %s\n%s\n' "$p" "$t" "$out" >> "$log"
        [ -z "$out" ] || { agp_say "      live refusals in $p:"; printf '%s\n' "$out" | sed 's/^/        /' >&3; }
      done
    fi
    if [ "$t" = KMS_PROJECT ] && [ ! -f "$marker" ]; then
      r gcloud kms keyrings list --location="$(v REGION)" --project="$(v KMS_PROJECT)" >> "$log" 2>&1 || { agp_say "      FAIL: the KMS_PROJECT key rings cannot be listed"; bad=1; }
      printf 'paused after KMS_PROJECT on %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" | xw "$marker" || bad=1
      sed 's/^/        /' "$log" >&3; rm -f "$log"
      [ $bad = 0 ] || return 1
      agp_say "      APPLIED-COUNT $n (expected 9 at the page's stop)"
      agp_say "      STOP: KMS_PROJECT is enforced (the page's core checks come before fld-platform-core). A person re-runs 10's wif-smoke"
      agp_say "        and op-deny-probe's INSIDE step at the git host now. A live refusal of a platform service: roll KMS_PROJECT back"
      agp_say "        (op-set.sh on its predecessor) and return to OP-8.2. Both pass: resume with --from OP-8.4."
      return 98
    fi
  done
  agp_say "      APPLIED-COUNT $n (expected 10)"
  [ "$n" = 10 ] || bad=1
  if [ $bad = 0 ]; then
    r gcloud kms keyrings list --location="$(v REGION)" --project="$(v KMS_PROJECT)" >> "$log" 2>&1 || { agp_say "      FAIL: the KMS_PROJECT key rings cannot be listed"; bad=1; }
    agp_say "      fld-platform-core is enforced: re-run 10's wif-smoke and op-deny-probe's INSIDE step now; a live refusal of a platform"
    agp_say "      service rolls fld-platform-core back at once (op-set.sh on its predecessor) and returns to OP-8.2"
  fi
  _p13_finish "$log" "$bad" OP-8.4 enforced-allowlists txt 1.3.3
}

step OP-8.5 AUTO "Negative tests after enforcement" --needs "BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_8_5_check() { ckpt_done OP-8.5 || _p13_passed OP-8.5 post-enforcement-tests; }
s_OP_8_5_apply() {
  local log bad=0 acc=0 key=0 rc p="$P13_PROBE" code
  _p13_need_done OP-8.4 "the allow-lists are enforced" || return 1
  log="$(_p13_newlog)" || return 1
  _p13_refused "$log" "(1) B15" 'constraints/gcp.restrictServiceUsage' \
    gcloud compute networks list --project="$p" --format="value(name)"; rc=$?
  [ $rc -eq 0 ] || { bad=1; [ $rc -eq 1 ] && acc=1; }
  agp_say "      (2) is a deliberate attempt to create a user-managed key: OP-8.5b destroys any key it creates, whatever the result"
  _p13_refused "$log" "(2) B2" 'constraints/iam.managed.disableServiceAccountKeyCreation' \
    gcloud iam service-accounts keys create /dev/null --iam-account="op-probe@$p.iam.gserviceaccount.com" --project="$p"; rc=$?
  [ $rc -eq 0 ] || { bad=1; [ $rc -eq 1 ] && key=1 && acc=1; }
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      \$ curl -sS --tlsv1.0 --tls-max 1.1 https://storage.googleapis.com/storage/v1/b/$p-ok  (token on standard input)"
    agp_say "        expected: fails at the handshake or with an error; a client that cannot offer TLS 1.1 is recorded as not testable"
  else
    code="$(_p13_curl_token "https://storage.googleapis.com/storage/v1/b/$p-ok" -sS --tlsv1.0 --tls-max 1.1 -o /dev/null -w '%{http_code}' 2>>"$log")"; rc=$?
    case "$rc:$code" in
      4:*|1:*|48:*) echo "(3) B22 not testable from this workstation (curl exit $rc); the effective read is the proof" >> "$log";;
      0:2*) echo "(3) B22 ACCEPTED: HTTP $code over TLS 1.0/1.1" >> "$log"; agp_say "      FAIL (3): the TLS 1.0/1.1 request succeeded (HTTP $code)"; bad=1;;
      0:*) echo "(3) B22 refused with an error: HTTP $code" >> "$log";;
      *) echo "(3) B22 refused at the handshake (curl exit $rc)" >> "$log";;
    esac
  fi
  sed 's/^/        /' "$log" >&3
  _p13_finish "$log" "$bad" OP-8.5 post-enforcement-tests txt 4.1.1; rc=$?
  if [ "$AGP_MODE" = apply ] && [ $rc -ne 0 ]; then
    if [ $key = 1 ]; then agp_say "      A KEY WAS CREATED. Run OP-8.5b now, before anything else: agp-platform apply --phase 13 --from OP-8.5b --to OP-8.5b"
    else agp_say "      Run OP-8.5b now, whatever the result: agp-platform apply --phase 13 --from OP-8.5b --to OP-8.5b"; fi
  fi
  _p13_stop_accepted "$acc" "read the effective B15 and B2 policies on the probe's folder; OP-8.5b runs first, whatever the result" || return 98
  return $rc
}

step OP-8.5b AUTO "Destroy any key the negative test created, and prove none remains" --removes --needs "BUILD_LOG_DIR EVIDENCE_REGISTER"
_p13_user_keys() { r gcloud iam service-accounts keys list --iam-account="op-probe@$P13_PROBE.iam.gserviceaccount.com" --managed-by=user --project="$P13_PROBE" --format="value(name)"; }
s_OP_8_5b_check() {    # its record ends in RESULT PASS only when the listing after the deletes printed nothing
  ckpt_done OP-8.5b || _p13_passed OP-8.5b probe-key-destroyed
}
s_OP_8_5b_apply() {
  local ia="op-probe@$P13_PROBE.iam.gserviceaccount.com" log bad=0 k keys left
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud iam service-accounts keys list --iam-account=$ia --managed-by=user --project=$P13_PROBE; for each KEY_ID:"
    x gcloud iam service-accounts keys delete "<KEY_ID>" --iam-account="$ia" --project="$P13_PROBE"
    agp_say "      read: the same list again prints nothing; a failed delete deletes the probe project in this sitting (OP-9.1's command)"
    _p13_save OP-8.5b probe-key-destroyed txt 4.1.1 /dev/null; return 0
  fi
  log="$(_p13_newlog)" || return 1
  keys="$(r gcloud iam service-accounts keys list --iam-account="$ia" --managed-by=user --project="$P13_PROBE" --format="value(name,validAfterTime)")" \
    || { agp_say "      FAIL: the key list could not be read"; rm -f "$log"; return 1; }
  printf '== user-managed keys before\n%s\n' "$keys" >> "$log"
  for k in $(_p13_user_keys); do
    echo "DESTROYING ${k##*/}" >> "$log"; agp_say "      DESTROYING ${k##*/}"
    if ! x gcloud iam service-accounts keys delete "${k##*/}" --iam-account="$ia" --project="$P13_PROBE"; then
      agp_say "      the key delete failed: the probe project is deleted now, in this sitting (gcloud asks to confirm)"
      echo "key delete failed; probe project deleted in this sitting; §8's remaining probe tests on a fresh probe or not at all" >> "$log"
      x gcloud projects delete "$P13_PROBE" || true
      bad=1; break
    fi
  done
  [ -n "$keys" ] || echo "none created: B2 refused the creation (the expected result)" >> "$log"
  left="$(_p13_pre _p13_user_keys)" || { echo "the second listing failed" >> "$log"; bad=1; }
  printf '== user-managed keys after\n%s\n' "$left" >> "$log"
  [ -z "$left" ] || { agp_say "      FAIL: user-managed keys remain on op-probe@: $left"; bad=1; }
  _p13_finish "$log" "$bad" OP-8.5b probe-key-destroyed txt 4.1.1
}

step OP-8.6 AUTO-READ "Read the effective baseline on every folder" --needs "PLATFORM_ENV_FILE BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_8_6_check() { ckpt_done OP-8.6; }
s_OP_8_6_apply() {
  local xf tmp n c out folders cons rows exp errs dry
  cons="gcp.resourceLocations iam.allowedPolicyMemberDomains iam.managed.disableServiceAccountKeyCreation iam.managed.disableAccessPolicyBinding storage.publicAccessPrevention gcp.restrictServiceUsage run.allowedBinaryAuthorizationPolicies run.allowedVPCEgress cloudkms.allowedProtectionLevels gcp.restrictTLSVersion iam.managed.workloadIdentityPoolProviders"
  xf="$(_p13_recpath OP-8.6 effective-after txt)"
  _p13_need_done OP-8.5b "no probe key remains" || return 1
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: gcloud org-policies describe <11 constraints> --folder=<every FLD_* of ~/.platform-env> --effective, one row each"
    agp_say "      check: rows = folders x constraints, errors 0, and only then still-dry 0"
    ev OP-8.6 effective-after E-05 5.2.1 "build-log:records/$(basename "$xf")"; return 0
  fi
  folders="$(_p13_fld_vars)"; tmp="$(_p13_newlog)" || return 1
  for n in $folders; do
    for c in $cons; do
      if out="$(r gcloud org-policies describe "$c" --folder="$(v "$n")" --effective --format=json 2>&1)"; then
        printf '%s\t%s\t%s\n' "$n" "$c" "$(printf '%s' "$out" | _p13_py effrow)" >> "$tmp"
      else
        printf '%s\t%s\tERROR\n' "$n" "$c" >> "$tmp"
      fi
    done
  done
  x mkdir -p "$(dirname "$xf")" && xw "$xf" < "$tmp"; local rc=$?
  rm -f "$tmp"; [ $rc -eq 0 ] || return 1
  # shellcheck disable=SC2086
  exp=$(( $(echo $folders | wc -w) * $(echo $cons | wc -w) ))
  rows="$(grep -c . "$xf")"; errs="$(grep -c 'ERROR$' "$xf")"; dry="$(grep -c '"dry":true' "$xf")"
  agp_say "      rows $rows expected $exp"; agp_say "      errors $errs"; agp_say "      still-dry $dry"
  ev OP-8.6 effective-after E-05 5.2.1 "build-log:records/$(basename "$xf")" "$xf" || return 1
  [ "$rows" = "$exp" ] && [ "$errs" = 0 ] || { agp_say "      FAIL: a read failed or is missing (an expired grant: request a fresh one and re-run the whole step)"; return 1; }
  [ "$dry" = 0 ] || { agp_say "      FAIL: a constraint is still in dry run past its window (02 6: severity 2)"; return 1; }
  agp_say "      compare every row with the constraint plan and the allow-lists (as amended in OP-8.2); fld-gemini-enterprise has no allow-list (19)"
}

# ---------------------------------------------------------------- 9. Close the part
step OP-9.1 AUTO "Remove the probes" --removes --needs "CORE_PROJECT SA_FACTORY_APPLY DEVIATION_REGISTER BUILD_LOG_DIR EVIDENCE_REGISTER"
s_OP_9_1_check() {
  ckpt_done OP-9.1 && return 0
  [ "$AGP_OFFLINE" = 1 ] && return 3
  _p13_probe_deleted || return $?
  awk -F' *[|] *' '$2 == "BD-13-1" && NF == 6 {f = 1} END {exit f ? 0 : 1}' "$(v DEVIATION_REGISTER)"
}
_p13_probe_deleted() {  # the probe project is DELETE_REQUESTED (the page's describe, as a filtered list)
  nonempty r gcloud projects list --filter="projectId=$P13_PROBE AND lifecycleState=DELETE_REQUESTED" --format="value(projectId)"
}
s_OP_9_1_apply() {
  local c t log bad=0 rc st n
  c="$(v CORE_PROJECT)"; t="op-probe-target@$c.iam.gserviceaccount.com"
  _p13_need_done OP-8.6 "the effective baseline is read" || return 1
  agp_say "      under an ENT_PROJECT_REPAIR_CORE grant for the core fixtures; gcloud asks to confirm each delete"
  rc=0; [ "$AGP_MODE" != apply ] || { exists gcloud iam service-accounts describe "$t" --project="$c" --format='value(email)'; rc=$?; }
  if [ $rc -eq 0 ]; then
    x gcloud iam service-accounts remove-iam-policy-binding "$t" --member="serviceAccount:$(v SA_FACTORY_APPLY)" --role="roles/iam.serviceAccountTokenCreator" --project="$c" >/dev/null || bad=1
    x gcloud iam service-accounts delete "$t" --project="$c" || bad=1
  elif [ $rc -ne 1 ]; then bad=1; fi
  rc=0; [ "$AGP_MODE" != apply ] || { exists gcloud storage buckets describe "gs://$c-op-probe" --project="$c" --format='value(name)'; rc=$?; }
  if [ $rc -eq 0 ]; then x gcloud storage rm --recursive "gs://$c-op-probe" --project="$c" || bad=1; elif [ $rc -ne 1 ]; then bad=1; fi
  st=ACTIVE; [ "$AGP_MODE" != apply ] || st="$(r gcloud projects describe "$P13_PROBE" --format='value(lifecycleState)')"
  [ "$st" = DELETE_REQUESTED ] || x gcloud projects delete "$P13_PROBE" || bad=1
  x gcloud services disable policytroubleshooter.googleapis.com --project="$c" || bad=1
  agp_say "      (keep policytroubleshooter enabled instead if 16 or 42 will use it, and record which in BD-13-2 (9))"
  agp_say "      remove .github/workflows/op-deny-probe.yml (or the GitLab job) by pull request; the reviewers merge it"
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: $P13_PROBE is DELETE_REQUESTED; no op-probe account in CORE_PROJECT; the bucket is gone"
    x bd_close BD-13-1 "withdrawal: probe project deleted in 13 OP-9.1" "13 OP-9.1 VERIFY"
    _p13_save OP-9.1 probes-removed txt 4.2.1 /dev/null; return 0
  fi
  log="$(_p13_newlog)" || return 1
  if _p13_probe_deleted; then echo "$P13_PROBE lifecycleState DELETE_REQUESTED" >> "$log"
  else echo "$P13_PROBE is not DELETE_REQUESTED" >> "$log"; bad=1; fi
  # the two absences the page asserts (reads marked as checks, _p13_pre)
  n="$(_p13_pre r gcloud iam service-accounts list --project="$c" --format="value(email)" | grep -c op-probe)"
  echo "op-probe accounts in CORE_PROJECT: $n" >> "$log"; [ "$n" = 0 ] || bad=1
  _p13_pre exists gcloud storage buckets describe "gs://$c-op-probe" --project="$c" --format='value(name)'; rc=$?
  echo "core probe bucket: $([ $rc -eq 1 ] && echo gone || echo present)" >> "$log"; [ $rc -eq 1 ] || bad=1
  sed 's/^/        /' "$log" >&3
  if [ $bad = 0 ]; then x bd_close BD-13-1 "withdrawal: probe project deleted in 13 OP-9.1" "13 OP-9.1 VERIFY" || bad=1; fi
  _p13_finish "$log" "$bad" OP-9.1 probes-removed txt 4.2.1
}

step OP-9.2 HUMAN "Record deviations, handoffs and the re-run index" \
  --needs "DEVIATION_REGISTER SECOND_HUMAN_EMAIL BUILD_LOG_DIR"
s_OP_9_2_check() { ckpt_done OP-9.2; }
s_OP_9_2_manual() {
  local f o="<the second-deploy outcome of OP-5.6>"
  for f in "$(v BUILD_LOG_DIR)"/records/*-OP-5.6-run-tests-v*; do [ -f "$f" ] && o="$(grep '^SECOND-DEPLOY' "$f" | tail -1 | cut -d: -f1)"; done
  [ -n "$o" ] || o="<the second-deploy outcome of OP-5.6>"
  echo "WHO: the platform owner writes; $(v SECOND_HUMAN_EMAIL) reads the rows and initials the build-log line."
  printf 'WHERE: %s, the setup README re-run index, the build log.\n' "$(v DEVIATION_REGISTER)"
  echo "Run setup/13 OP-9.2's bd_insert of BD-13-2, with its three <...> replaced: (9) policytroubleshooter kept or disabled"
  echo "  (OP-9.1 disabled it unless you kept it); (10) one-approver mode, yes until DATE or no; (12) $o."
  echo "Add the page's re-run lines for 16, 17, 18, 19, 21, 22, 23, 31, 34, 35, 36, 40, 42, 03 and file 10 to README's re-run index,"
  echo "  if not already there (a wiki pull request)."
  echo "VERIFY: BD-13-1 and BD-13-2 sit above '## Closures' (the page's two awk lines);"
  echo "  need DENY_AGENTS_PLATFORM DENY_CORE_AGENTS DENY_IMPROVERS PAB_AGENTS PAB_CORE_CI passes."
  echo "Then: agp-platform done OP-9.2"
}

step OP-9.3 AUTO "End the sitting" --removes --needs "ENT_PLATFORM_POLICY ENT_PROJECT_REPAIR_CORE CICD_PROJECT BUILD_LOG_DIR"
s_OP_9_3_check() { ckpt_done OP-9.3; }   # the page's own DONE line, written by the apply below once its VERIFY passes
s_OP_9_3_apply() {
  local e g missing="" i id
  _p13_need_done OP-9.2 "the deviations and re-run lines are written" || return 1
  for e in ENT_PLATFORM_POLICY ENT_PROJECT_REPAIR_CORE; do
    if [ "$AGP_MODE" != apply ]; then
      agp_say "      for each ACTIVE grant of $e this account created (gcloud pam grants search ... --filter=state=ACTIVE):"
      x gcloud pam grants revoke "<GRANT_NAME>" --reason="setup 13 complete" --billing-project="$(v CICD_PROJECT)"; continue
    fi
    for g in $(r gcloud pam grants search --entitlement="$(v "$e")" --caller-relationship=had-created --filter="state=ACTIVE" --billing-project="$(v CICD_PROJECT)" --format="value(name)"); do
      x gcloud pam grants revoke "$g" --reason="setup 13 complete" --billing-project="$(v CICD_PROJECT)" || return 1
    done
  done
  if [ "$AGP_MODE" != apply ]; then
    agp_say "      read: no ACTIVE grant left; penv_guard clean; a DONE line for every OP step, OP-8.5b included"
    x checkpoint OP-9.3 DONE - - "file 13 complete; dry runs enforced; deny and PAB created and proven for existing principals"
    agp_say "      then close the sitting with: agp-platform sitting end"; return 0
  fi
  # the page's final search: an absence the step asserts (a read marked as a check, _p13_pre)
  g="$(_p13_pre r gcloud pam grants search --entitlement="$(v ENT_PLATFORM_POLICY)" --caller-relationship=had-created --filter="state=ACTIVE" --billing-project="$(v CICD_PROJECT)" --format="value(name)")" \
    || { agp_say "      FAIL: the grants could not be searched"; return 1; }
  [ -z "$g" ] || { agp_say "      FAIL: still ACTIVE: $g"; return 1; }
  penv_guard || { agp_say "      FAIL: penv_guard (above)"; return 1; }
  i=0
  while [ $i -lt $AGP_N ]; do
    id="${AGP_S_ID[$i]}"
    if [ "${AGP_S_PHASE[$i]}" = 13 ] && [ "$id" != OP-9.3 ] && ! ckpt_done "$id"; then missing="$missing $id"; fi
    i=$((i + 1))
  done
  [ -z "$missing" ] || { agp_say "      FAIL: no DONE line for:$missing"; return 1; }
  x checkpoint OP-9.3 DONE - - "file 13 complete; dry runs enforced; deny and PAB created and proven for existing principals" >/dev/null || return 1
  agp_say "      no grant active; every OP step DONE. Close the sitting now with: agp-platform sitting end (the page's sitting_end)"
}
