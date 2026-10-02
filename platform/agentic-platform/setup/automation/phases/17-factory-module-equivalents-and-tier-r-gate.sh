# phases/17-factory-module-equivalents-and-tier-r-gate.sh: setup/17, the hand equivalents of the
# factory modules, the zero-diff checker, the platform-core rows, the negative test and the Tier R
# gate record. Registers FM-0.1 to FM-12.2 (77 steps) in the page's order.
#
# Two kinds of step live in this page, and the runner treats them differently.
#
# 1. This file's own sittings: §0, §1, §8, §9, §10, §11 and §12. They run once, in order, and are
#    checked like any other phase. The Terraform factory does not exist (README B-01), so FM-0.2,
#    FM-6.5, FM-8.6 and FM-11.1 to FM-11.3 are BLOCKED; FM-7.3 is BLOCKED wherever the agent's code
#    is not committed (B-16 for Wall-E).
#
# 2. The per-call procedures: §2 (FM-COMMON) and the module sections §3 to §7. They do not run in
#    this file's own sitting; files 18, 19, 22, 23, 31 and 37 call them with a run spec. Here each is
#    a step that reads its values from the merged run spec named by FM_RUN_SPEC, a sitting variable
#    (a path under PLATFORM_REPO_DIR, never penv_set, because it changes with every call):
#      FM-2.1 is the person writing and merging the spec; its manual says to export FM_RUN_SPEC and
#      FM_BD_ID (the deviation-row id the calling file allocates). Every other per-call step needs
#      FM_RUN_SPEC and is --on-unmet skip, so in this file's own sitting (no FM_RUN_SPEC) they show
#      MISSING and are passed over: the sitting continues with `apply --phase 17 --from FM-8.1`.
#      A value that is neither a .json path nor under factory/runs/ selects no run: each such step prints
#      an [N/A] line and is passed over with no checkpoint (the runner has no N/A state, so its mark
#      reads DONE). A value that selects a run but names no readable spec stops the run (check 2).
#      A call then runs, for example:
#        FM_RUN_SPEC=factory/runs/mo-prod.json FM_BD_ID=BD-22-1 agp-platform apply --phase 17 --from FM-2.2 --to FM-2.22
#      with the module section's steps called where §3 to §7 place them (`--from FM-3.1 --to FM-3.1`
#      before FM-2.2, FM-3.2 between FM-2.4 and FM-2.15, and so on). Each AUTO step that the page orders
#      after a person's step refuses, in apply mode, until that step's per-run checkpoint exists.
#    Per-run checkpoints carry the run (`FM-2.7@mo-prod DONE`), as the page's conventions say; a person
#    records a per-run manual step with `checkpoint FM-x.y@<run> DONE`, because `agp-platform done`
#    writes the run-less id. A module section's step reads as done (N/A) for a run of another module.
#    FM-7 (revoke) is guarded the same way by FM_REVOKE_DECISION, which FM-7.1 has the person export
#    once the revoke decision is signed; without it FM-7.2 to FM-7.7 are passed over.
#
# Classes. Commands that only the platform owner runs, and that are deterministic once the spec is
# merged, are AUTO; reads and the checker are AUTO-READ; pull-request merges at the git host, the
# reviewers' approvals, PAM one-grant tests, the Tier R record and its signatures, the end of a sitting
# and the wiki pass are HUMAN; the git-host workflow run and Policy Troubleshooter are CONSOLE. The
# script never contacts the git host (setup/03's rule): it writes the page's files with xw, and the
# commit, push and merge are the person's. FM-9.1 is HUMAN: it stores a secret version (a canary, but
# still a secret value piped into Secret Manager), and no secret passes through the script.
# A grant the page waits for is requested with `gcloud pam grants create` and waited for with setup/12's
# `pam_wait` from the committed pam/tools/pam.sh; the approver acts in their own session.
#
# No `requires`: every change here runs under a PAM grant on a folder or project (12), or under the
# billing roles that end at BOOTSTRAP_BILLING_EXPIRY, and the organisation-scope reads are settled by
# FM-0.4 on the day rather than assumed (an organisation permission listed here would make preflight
# refuse a sitting the page says can run).
#
# Helpers are prefixed _fm_ because every phase file is loaded into the same shell.

phase 17 "Factory module equivalents and the Tier R gate" "17-factory-module-equivalents-and-tier-r-gate.md"

# ---------------------------------------------------------------- helpers

FM17_PY='
import json, sys
cmd, a = sys.argv[1], sys.argv[2:]
def load(p):
    raw = sys.stdin.read() if p == "-" else open(p, encoding="utf-8").read()
    try:
        return json.loads(raw) if raw.strip() else None
    except ValueError:
        print("unreadable JSON: " + raw[:160].replace("\n", " "))
        return None
def walk(d, path):
    for part in [x for x in path.split(".") if x]:
        if isinstance(d, list) and part.isdigit() and int(part) < len(d):
            d = d[int(part)]
        elif isinstance(d, dict) and part in d:
            d = d[part]
        else:
            return None, False
    return d, True
def show(v):
    if isinstance(v, str):
        return v
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    return json.dumps(v, separators=(",", ":"))
def rules_named(r, ids):
    desc = r.get("description") or ""
    return [i for i in ids if desc.startswith(i + " ")]
rc = 0
if cmd == "get":
    v, ok = walk(load(a[0]), a[1])
    if not ok:
        sys.exit(1)
    print(show(v))
elif cmd == "each":
    v, ok = walk(load(a[0]), a[1])
    for x in (v or []):
        print(show(x))
elif cmd == "len":
    v, ok = walk(load(a[0]), a[1])
    print(len(v or []))
elif cmd == "labels":
    v, ok = walk(load(a[0]), "labels")
    print(",".join("%s=%s" % (k, x) for k, x in (v or {}).items()))
elif cmd == "cats":
    print(",".join(x.lower().replace("_", "-") for x in json.loads(a[0]).get("categories", [])))
elif cmd == "edit":
    d = load(a[0])
    for op in a[1:]:
        app = "+=" in op
        k, val = op.split("+=" if app else "=", 1)
        parts, o = k.split("."), d
        for p in parts[:-1]:
            o = o.setdefault(p, {})
        if app:
            o.setdefault(parts[-1], []).append(val)
        else:
            o[parts[-1]] = val
    print(json.dumps(d, indent=2))
elif cmd == "humans":
    d = load("-") or {}
    for b in d.get("bindings", []):
        for m in b.get("members", []):
            if m.split(":")[0] in ("user", "group", "domain") or m in ("allUsers", "allAuthenticatedUsers"):
                print(b.get("role"), m)
elif cmd == "members":
    d = load("-") or {}
    for b in d.get("bindings", []):
        if b.get("role") == a[0]:
            for m in b.get("members", []):
                print(m)
elif cmd == "deny-edit":
    d, de, mode = load(a[0]), json.loads(a[1]), a[2]
    rules = []
    for r in d.get("rules", []):
        named = rules_named(r, de.get("rules", []))
        if named:
            dr = r.setdefault("denyRule", {})
            den, exc = list(dr.get("deniedPrincipals") or []), list(dr.get("exceptionPrincipals") or [])
            if mode == "add":
                dr["deniedPrincipals"] = sorted(set(den + [de["principal"]]))
                dr["exceptionPrincipals"] = sorted(set(exc + list((de.get("exceptions") or {}).get(named[0], []))))
            else:
                dr["deniedPrincipals"] = [p for p in den if p != de["principal"]]
        rules.append(r)
    print(json.dumps({"displayName": d.get("displayName"), "rules": rules}, indent=2, sort_keys=True))
elif cmd == "deny-only":
    d = load(a[0]) or {}
    print(json.dumps({"displayName": d.get("displayName"), "rules": d.get("rules", [])}, indent=2, sort_keys=True))
elif cmd in ("deny-has", "deny-lacks"):
    d, de, seen = load("-") or {}, json.loads(a[0]), set()
    for r in d.get("rules", []):
        named = rules_named(r, de.get("rules", []))
        if not named:
            continue
        seen.add(named[0])
        dr = r.get("denyRule") or {}
        has = de["principal"] in (dr.get("deniedPrincipals") or [])
        if cmd == "deny-lacks":
            if has:
                print("STILL DENIED in " + named[0]); rc = 1
            continue
        if not has:
            print("MISSING principal in " + named[0]); rc = 1
        for e in (de.get("exceptions") or {}).get(named[0], []):
            if e not in (dr.get("exceptionPrincipals") or []):
                print("MISSING exception %s in %s" % (e, named[0])); rc = 1
    if cmd == "deny-has":
        for i in de.get("rules", []):
            if i not in seen:
                print("NO RULE described " + i); rc = 1
elif cmd == "allowlen":
    d = load("-") or {}
    print(sum(len((r.get("values") or {}).get("allowedValues") or []) for r in (d.get("spec") or {}).get("rules", [])))
elif cmd == "denied-values":
    d = load("-") or {}
    for r in (d.get("spec") or {}).get("rules", []):
        for x in (r.get("values") or {}).get("deniedValues") or []:
            print(x)
elif cmd == "rule-lines":
    d = load("-") or {}
    for r in d.get("rules", []):
        print("%s\t%s" % (r.get("description") or "(no description)", ",".join((r.get("denyRule") or {}).get("deniedPrincipals") or [])))
elif cmd == "rule-count":
    print(len((load("-") or {}).get("rules", [])))
elif cmd == "report":
    for r in load(a[0]).get("results", []):
        if r.get("status") == "PASS":
            continue
        p = r.get("pending") or {}
        print("%s %s %s %s" % (r.get("status"), r.get("check"), p.get("owner", ""), p.get("rerun_in", "")))
        if r.get("status") == "FAIL" or not (p.get("owner") and p.get("rerun_in")):
            rc = 1
        elif rc == 0:
            rc = 3
elif cmd == "rows":
    for r in load(a[0]).get("results", []):
        if str(r.get("check", "")).startswith(a[1]):
            print("%s %s %s" % (r.get("status"), r.get("check"), show(r.get("actual"))))
elif cmd == "fails":
    for r in load(a[0]).get("results", []):
        if r.get("status") == "FAIL":
            print(r.get("check"))
elif cmd == "tags":
    want = (load(a[0]) or {}).get("tags_effective") or {}
    d = load("-") or []
    got = {}
    for b in (d if isinstance(d, list) else [d]):
        parts = str(b.get("namespacedTagValue") or "").split("/")
        if len(parts) >= 3:
            got[parts[-2]] = (parts[-1], b.get("inherited"))
    for k, val in want.items():
        g = got.get(k)
        if g is None:
            print("MISSING " + k); rc = 1
        elif g[0] != val:
            print("DIFFERS %s: %s, spec %s" % (k, g[0], val)); rc = 1
        elif g[1] is not True:
            print("NOT INHERITED " + k); rc = 1
elif cmd == "agent-deny":
    s = load(a[0])
    ap, apc, agp, num, ag, pid, tier = a[1:8]
    sa = lambda e: "principal://iam.googleapis.com/projects/-/serviceAccounts/" + e + "@" + pid + ".iam.gserviceaccount.com"
    exc = {} if tier == "R" else {"R1": [sa(ag + "-actions")], "R3b": [sa(ag + "-deployer")], "R4": [sa(ag + "-deployer")]}
    rl = ["R1", "R2", "R3", "R3b", "R4", "R5"]
    s["deny_entries"] = [
        {"policy_id": "deny-agents-platform", "attachment_point": ap, "rules": rl,
         "principal": "principalSet://cloudresourcemanager.googleapis.com/projects/" + num + "/type/ServiceAccount", "exceptions": exc},
        {"policy_id": "deny-agents-platform", "attachment_point": ap, "rules": rl, "principal": agp, "exceptions": {}},
        {"policy_id": "deny-core-agents", "attachment_point": apc, "rules": ["CA"], "principal": agp, "exceptions": {}}]
    print(json.dumps(s, indent=2))
elif cmd == "mo-deny":
    s = load(a[0])
    s["deny_entries"] = [{"policy_id": "deny-agents-platform", "attachment_point": a[1], "rules": ["R1", "R2", "R3", "R3b", "R4", "R5"],
                          "principal": "principalSet://cloudresourcemanager.googleapis.com/projects/" + a[2] + "/type/ServiceAccount", "exceptions": {}}]
    s.setdefault("made_elsewhere", []).append({"item": "deny-improvers and deny-core-agents cover MO_PROJECT through the fld-improvers service-account set", "file": "13", "step": "OP-7.5, OP-7.6"})
    print(json.dumps(s, indent=2))
elif cmd == "set-count":
    d = load("-") or {}
    print(sum(1 for r in d.get("rules", []) for p in ((r.get("denyRule") or {}).get("deniedPrincipals") or []) if p == a[0]))
elif cmd == "floor":
    f, s = load(a[0]), load(a[1])
    pf = s.get("project_floor") or {}
    sp = (f.get("spellings") or {}).get("accepted")
    plat = [x for x in f.get("floors", []) if x.get("level") == "platform"]
    if sp not in ("gcloud", "gcloud-lower", "rest") or not plat:
        print("STOP: floors.json .spellings.accepted is not set (18 KS-2.5 records it, KS-2.10 commits it)"); sys.exit(2)
    pic = str(pf.get("pi_confidence") or "")
    if sp == "rest":
        out = ["ENABLED", "ENABLED", pic.upper().replace("-", "_"), (plat[0].get("rest") or {}).get("rai")]
    else:
        rai = (plat[0].get("gcloud") or {}).get("rai")
        if sp == "gcloud-lower":
            rai = [dict(x, confidenceLevel=str(x.get("confidenceLevel", "")).lower().replace("_", "-")) for x in (rai or [])]
        out = ["enable", "enabled", pic.lower().replace("_", "-"), rai]
    print(out[0]); print(out[1]); print(out[2]); print(pf.get("vertex_enforcement") or ""); print(json.dumps(out[3], separators=(",", ":")))
elif cmd == "floor-on":
    rc = 0 if (load("-") or {}).get("enableFloorSettingEnforcement") is True else 1
elif cmd == "approvers":
    d = load("-") or {}
    for st in (((d.get("approvalWorkflow") or {}).get("manualApprovals") or {}).get("steps") or []):
        for ap in st.get("approvers") or []:
            for p in ap.get("principals") or []:
                print(p)
elif cmd == "ent":
    d = load(a[0])
    g = (d.get("privilegedAccess") or {}).get("gcpIamAccess") or {}
    print(g.get("resource"))
    print(",".join(b.get("role", "") for b in g.get("roleBindings") or []))
    print(d.get("maxRequestDuration"))
    print(",".join(p for st in (((d.get("approvalWorkflow") or {}).get("manualApprovals") or {}).get("steps") or []) for ap in st.get("approvers") or [] for p in ap.get("principals") or []))
elif cmd == "elsewhere":
    s, bad = load(a[0]), 0
    for x in s.get("made_elsewhere", []):
        line = "%s\t%s\t%s" % (x.get("item"), x.get("file"), x.get("step"))
        print(line)
        if not x.get("file") or not x.get("step") or "*tbd*" in line:
            rc = 1
elif cmd == "elsewhere-has":
    s = load(a[0])
    rc = 0 if any(a[1].lower() in str(x.get("item", "")).lower() for x in s.get("made_elsewhere", [])) else 1
elif cmd == "row36":
    e = load(a[0])
    for k, f in (("folder", a[1]), ("core_project", a[2])):
        got = sorted(l.strip() for l in open(f) if l.strip())
        want = sorted(e.get(k) or [])
        if got != want:
            print("DIFFERS %s: %s; expected %s" % (k, ",".join(got) or "(nothing)", ",".join(want))); rc = 1
elif cmd == "join":
    v, ok = walk(load(a[0]), a[1])
    xs = [str(x.get(a[2]) if a[2] and isinstance(x, dict) else x) for x in (v or [])]
    if len(a) > 3:
        xs = sorted(set(xs))
    print("+".join(xs) or "none")
elif cmd == "canary-gone":
    # FM-9.5 VERIFY: 1 while the policy of the secret names member a[0] under any role. The conditioned binding of FM-9.3
    # (role a[1], condition title a[2]) is STILL BOUND; any other role is one FM-9.3 did not place (severity 1 at FM-9.4)
    d = load("-") or {}
    for b in d.get("bindings", []):
        if a[0] not in (b.get("members") or []):
            continue
        t = (b.get("condition") or {}).get("title")
        rc = 1
        if b.get("role") == a[1] and t == a[2]:
            print("STILL BOUND %s %s (condition %s)" % (a[0], a[1], t))
        else:
            print("STILL BOUND %s %s (condition %s): FM-9.3 did not place it; severity 1 at FM-9.4" % (a[0], b.get("role"), t or "none"))
elif cmd == "member-roles":
    d = load("-") or {}
    for role in sorted(set(b.get("role") for b in d.get("bindings", []) if a[0] in (b.get("members") or []))):
        print(role)
elif cmd == "access-email":
    d = load("-") or {}
    for x in d.get("access", []):
        if x.get("userByEmail") == a[0]:
            print(json.dumps(x, sort_keys=True))
sys.exit(rc)
'
_fm_py() { python3 -c "$FM17_PY" "$@"; }

_fm_plan() { [ "$AGP_MODE" = apply ] || printf '      %s\n' "$*" >&3; }     # one line of explanation in plan mode
_fm_say()  { printf '      %s\n' "$*" >&3; }                                # one line for the operator, both modes

_fm_ckpt_is() {     # ID STATUS...: checkpoints.tsv holds a line for ID with one of the statuses
  local id="$1" st; shift
  [ -n "${BUILD_LOG_DIR-}" ] && [ -f "$BUILD_LOG_DIR/checkpoints.tsv" ] || return 1
  for st in "$@"; do
    awk -F'\t' -v s="$id" -v t="$st" '$2 == s && $3 == t {f=1} END {exit f ? 0 : 1}' "$BUILD_LOG_DIR/checkpoints.tsv" && return 0
  done
  return 1
}

_fm_rec() {         # NAME: a record path under BUILD_LOG_DIR/records, dated today
  printf '%s/records/%s-%s' "$(v BUILD_LOG_DIR)" "$(date -u +%F)" "$1"
}

_fm_save() {        # FILE CMD...: run a read and keep its output (stdout and stderr) as a record; plan: announce
  local f="$1" out rc; shift
  if [ "$AGP_MODE" != apply ]; then printf '      read: %s  > %s\n' "$(agp_quote "$@")" "${f##*/}" >&3; return 0; fi
  out="$(r "$@" 2>&1)"; rc=$?
  printf '%s\n' "$out" | xw "$f" 600 >/dev/null || return 1
  printf '%s\n' "$out" | sed 's/^/        /' >&3
  return $rc
}

_fm_pamsh() { printf '%s/pam/tools/pam.sh' "$(v PLATFORM_REPO_DIR)"; }

_fm_grant() {       # ENT DURATION JUSTIFICATION [SCOPE_FLAG]: request a grant and wait for ACTIVE (12's pam_wait); prints the grant name
  local ent="$1" dur="$2" just="$3" g rc
  shift 3
  if [ "$AGP_MODE" != apply ]; then
    x gcloud pam grants create --entitlement="$ent" --requested-duration="$dur" --justification="$just" \
      --location=global --billing-project="$(v CICD_PROJECT)" "$@" --format='value(name)'
    _fm_plan "then: pam_wait <grant> ACTIVE (setup/12 pam/tools/pam.sh); the approver acts in their own session"
    printf '<grant>'; return 0
  fi
  [ -f "$(_fm_pamsh)" ] || { _fm_say "STOP: $(_fm_pamsh) is missing (setup/12 PA-1.5)"; return 1; }
  g="$(x gcloud pam grants create --entitlement="$ent" --requested-duration="$dur" --justification="$just" \
      --location=global --billing-project="$(v CICD_PROJECT)" "$@" --format='value(name)')" || return 1
  [ -n "$g" ] || { _fm_say "STOP: the grant request printed no name"; return 1; }
  _fm_say "grant $g requested; waiting for the approver (pam_wait, up to the request's lifetime)"
  r bash -c '. "$1" >/dev/null 2>&1 || exit 2; pam_wait "$2" ACTIVE' _ "$(_fm_pamsh)" "$g" >&3; rc=$?
  [ $rc -eq 0 ] || { _fm_say "STOP: grant $g did not become ACTIVE (pam_wait $rc); never re-request on a timeout: read pam_state first"; return 1; }
  printf '%s' "$g"
}

# ---- the run spec (§2 onwards)
_fm_sv() {          # PATH: a value of the run spec, or <PATH> when no spec is loaded
  if [ "${FM_OK:-0}" = 1 ]; then _fm_py get "$FM_SPEC" "$1" 2>/dev/null || printf '<%s: absent from the spec>' "$1"
  else printf '<spec.%s>' "$1"; fi
}

_fm_list() {        # PATH: the members of an array of the spec, one per line; one placeholder without a spec
  if [ "${FM_OK:-0}" = 1 ]; then _fm_py each "$FM_SPEC" "$1"; else printf '<each-of-spec.%s>\n' "$1"; fi
}

_fm_field() {       # JSON KEY: a field of one spec member, or <KEY> for a placeholder member
  case "$1" in '<'*) printf '<%s>' "$2";; *) printf '%s' "$1" | _fm_py get - "$2" 2>/dev/null || printf '<%s>' "$2";; esac
}

_fm_run_selected() { # 0 when FM_RUN_SPEC names a run: a .json path, or any path under factory/runs/
  # (so factory/runs/mo-prod, a missing extension, selects a run and then stops as unreadable)
  has_value FM_RUN_SPEC || return 1
  case "$(_penv_get FM_RUN_SPEC)" in *.json|factory/runs/*|*/factory/runs/*) return 0;; esac
  return 1
}

_fm_ctx() {         # load the spec FM_RUN_SPEC names into FM_* variables; FM_OK=1 when it is readable
  local s
  FM_OK=0; FM_SPEC=""
  if _fm_run_selected; then
    s="$(_penv_get FM_RUN_SPEC)"
    case "$s" in /*) FM_SPEC="$s";; *) FM_SPEC="$(v PLATFORM_REPO_DIR)/$s";; esac
    [ -r "$FM_SPEC" ] && _fm_py get "$FM_SPEC" run_id >/dev/null 2>&1 && FM_OK=1
  fi
  [ -n "$FM_SPEC" ] || FM_SPEC="<FM_RUN_SPEC>"
  FM_AG="$(_fm_sv agent_id)"; FM_ENV="$(_fm_sv env)"; FM_MOD="$(_fm_sv module)"
  FM_RUNID="$(_fm_sv run_id)"; FM_PVAR="$(_fm_sv project_variable)"; FM_PID="$(_fm_sv project_id)"
  FM_PFLDVAR="$(_fm_sv parent_folder_variable)"; FM_TIER="$(_fm_sv register_tier)"
  if [ "$FM_OK" = 1 ]; then FM_RUN="${FM_AG}-${FM_ENV}"; FM_PFLD="$(v "$FM_PFLDVAR")"; else FM_RUN="<agent_id>-<env>"; FM_PFLD="<folder-id-of-spec.parent_folder_variable>"; fi
  FM_R="$(_fm_rec "FM-${FM_RUN}")"
}

_fm_nf() { if [ "$1" = 3 ]; then echo 3; else echo 1; fi; }   # a failed read in a per-run check: 3 offline, else not done

_fm_pre() {         # the start of every per-run check: 0 spec loaded, 3 no run selected (plan), 2 FM_RUN_SPEC names no spec
  # A value that is not a .json path selects no run (a sitting variable left in ~/.platform-env, or the
  # offline tests' stand-in value): the per-call step is passed over, never run against a guessed spec.
  _fm_ctx
  [ "$FM_OK" = 1 ] && return 0
  if _fm_run_selected; then echo "      FM_RUN_SPEC names no readable run spec: $FM_SPEC"; return 2; fi
  if has_value FM_RUN_SPEC; then
    # 0 is the only result lib/core.sh passes over without running _apply or stopping (1 and 4 give TODO
    # and run _apply, 3 gives UNCHECKED and runs it, 2 stops). A check-DONE writes no checkpoint, so
    # status, FM-0.1 and the gates still count this step as not done; the line below says so.
    echo "      [N/A] ${AGP_CUR_STEP:-per-call step}: not checked, not run, no checkpoint written. FM_RUN_SPEC='$(_penv_get FM_RUN_SPEC)'"
    echo "            selects no run (a run is factory/runs/<agent_id>-<env>.json); the runner's [DONE] below is its pass-over mark"
    return 0
  fi
  return 3
}

_fm_apre() {        # the start of every per-run apply: refuse without a spec in apply mode
  _fm_ctx
  [ "$FM_OK" = 1 ] && return 0
  if [ "$AGP_MODE" = apply ]; then _fm_say "STOP: FM_RUN_SPEC names no readable run spec ($FM_SPEC)"; return 1; fi
  _fm_plan "per call (FM_RUN_SPEC unset): values below are read from the merged run spec of the calling file"
  return 0
}

_fm_skip_unless() { # MODULE...: 0 (and an N/A line) when this run's module is none of them
  local m
  for m in "$@"; do [ "$FM_MOD" = "$m" ] && return 1; done
  echo "      N/A for this run: its module is $FM_MOD"
  return 0
}

_fm_ck() {          # STEP STATUS NOTE: the page's per-run checkpoint, STEP@<run>
  x checkpoint "$1@$FM_RUN" "$2" - - "$3"
}

_fm_ckd() {         # STEP: the per-run checkpoint is DONE, N/A or PENDING
  _fm_ckpt_is "$1@$FM_RUN" DONE N/A PENDING
}

_fm_after() {       # STEP...: the page orders each STEP before this one; apply refuses until its per-run checkpoint
  # exists or its own check reads it as done for this run (an AUTO step found done is never re-applied, so it has no line)
  local s
  for s in "$@"; do
    if [ "$AGP_MODE" != apply ]; then _fm_plan "runs only after $s is done for this run"; continue; fi
    _fm_ckd "$s" && continue
    "$(agp_fn "$s")_check" >/dev/null 2>&1 && continue
    _fm_say "STOP: $s is not done for $FM_RUN; the page runs it first"; return 1
  done
  return 0
}

_fm_ent_var() {     # the variable naming this run's entitlement (FM-2.2), from the parent folder (§3 to §6 tables)
  case "$FM_PFLDVAR" in
    FLD_AGENTS_P_SA_PROD) echo ENT_FACTORY_SINGLETON_PSA_PROD;;
    FLD_AGENTS_P_SA_NONPROD) echo ENT_FACTORY_SINGLETON_PSA_NONPROD;;
    FLD_CONTROLLERS_PROD) echo ENT_FACTORY_SINGLETON_CTL_PROD;;
    FLD_CONTROLLERS_NONPROD) echo ENT_FACTORY_SINGLETON_CTL_NONPROD;;
    FLD_GEMINI_ENTERPRISE) echo ENT_PROJECT_REPAIR_TENANT_APP;;
    FLD_*) # ent-bootstrap-module per folder (SD-46): FLD_AGENTS_R_NONPROD -> ENT_BOOTSTRAP_MODULE_R_NONPROD,
           # FLD_IMPROVERS_PROD -> ENT_BOOTSTRAP_MODULE_IMPROVERS_PROD; a new folder's variable follows the same form
      local f="${FM_PFLDVAR#FLD_}"; echo "ENT_BOOTSTRAP_MODULE_${f#AGENTS_}";;
    *) echo "RUN_ENTITLEMENT";;
  esac
}

_fm_join() {        # PATH [FIELD [unique]]: the spec array joined with +, or none; a placeholder without a spec
  if [ "${FM_OK:-0}" = 1 ]; then _fm_py join "$FM_SPEC" "$1" "${2-}" ${3:+"$3"}; else printf '<spec.%s>' "$1"; fi
}

_fm_ag_var() { printf '%s' "$FM_AG" | tr 'a-z-' 'A-Z_'; }    # mo -> MO, canary-r -> CANARY_R

_fm_ent_repair() { printf 'projects/%s/locations/global/entitlements/ent-project-repair-%s' "$FM_PID" "$FM_AG"; }

_fm_iam_humans() {  # PROJECT: user, group and domain members at project level (empty when none)
  r gcloud projects get-iam-policy "$1" --format=json 2>/dev/null | _fm_py humans
}

_fm_probe() {       # PROJECT PERM...: testIamPermissions as the platform owner; prints the permissions held
  local p="$1" b out; shift
  b="$(mktemp "${TMPDIR:-/tmp}/agp-fm.XXXXXX")" || return 1
  python3 -c 'import json,sys; print(json.dumps({"permissions": sys.argv[1:]}))' "$@" > "$b"
  out="$(AGP_API_PROJECT="$p" api POST "https://cloudresourcemanager.googleapis.com/v3/projects/${p}:testIamPermissions" "$b")"
  rm -f "$b"
  printf '%s\n' "$out"
}

_fm_org_read() {    # FM-0.4's test, re-established in each sitting that needs it: prints yes or no
  # yes only when the three organisation reads succeed AND print something: an empty output with no
  # error proves nothing (the page's warning about empty tables), so it counts as no.
  local o d
  [ "$AGP_MODE" = apply ] || { printf 'no'; return 0; }
  d="$(mktemp -d "${TMPDIR:-/tmp}/agp-fm.XXXXXX")" || { printf 'no'; return 0; }
  o="$(v ORG_ID)"
  r gcloud organizations get-iam-policy "$o" --format="value(etag)" > "$d/1" 2> "$d/1e"
  r gcloud asset search-all-iam-policies --scope="organizations/${o}" --limit=1 --format="value(resource)" > "$d/2" 2> "$d/2e"
  r gcloud logging sinks list --organization="$o" --format="value(name)" > "$d/3" 2> "$d/3e"
  if [ -s "$d/1" ] && [ -s "$d/2" ] && [ -s "$d/3" ] && [ ! -s "$d/1e" ] && [ ! -s "$d/2e" ] && [ ! -s "$d/3e" ]; then printf 'yes'; else printf 'no'; fi
  rm -rf "$d"
}

_fm_checker() {     # MODE SPEC REPORT [--accept-pending]: tools/fm-zero-diff.py, exit code returned; plan: announce
  local m="$1" s="$2" rep="$3"; shift 3
  if [ "$AGP_MODE" != apply ]; then
    printf '      read: python3.12 %s %s %s --report %s %s\n' "$(v PLATFORM_REPO_DIR)/tools/fm-zero-diff.py" "$m" "$s" "${rep##*/}" "$*" >&3
    return 0
  fi
  command -v python3.12 >/dev/null 2>&1 || { _fm_say "STOP: python3.12 is not on PATH (a workstation precondition of setup/17)"; return 2; }
  ( cd "$(v PLATFORM_REPO_DIR)" && r python3.12 tools/fm-zero-diff.py "$m" "$s" --report "$rep" "$@" ) 2>&1 | tail -n 3 | sed 's/^/        /' >&3
  [ -s "$rep" ] || { _fm_say "STOP: the checker wrote no report ($rep)"; return 2; }
  python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1])).get("zero_diff") else 1)' "$rep"
}

_fm_rerun_has() {   # STEP: rerun-index.tsv names STEP
  local f; f="$(v BUILD_LOG_DIR)/rerun-index.tsv"
  [ -f "$f" ] && awk -F'\t' -v s="$1" '$2 == s || index($0, s) {f=1} END {exit f ? 0 : 1}' "$f"
}

# ---------------------------------------------------------------- 0. The sitting

_fm_prior_steps() { # the registered steps of the loaded phases 09 to 16 with no DONE, BLOCKED, PENDING or N/A line
  local i id
  i=0; while [ $i -lt $AGP_N ]; do
    case "${AGP_S_PHASE[$i]}" in
      09|10|11|12|13|14|15|16)
        id="${AGP_S_ID[$i]}"
        _fm_ckpt_is "$id" DONE BLOCKED PENDING N/A || printf '%s %s %s\n' "${AGP_S_PHASE[$i]}" "$id" "${AGP_S_CLASS[$i]}";;
    esac
    i=$((i + 1))
  done
}

_fm_0_1_reads() { # TSV REGISTER: FM-0.1's reads, one line each; FAIL lines stop the step
  local tsv="$1" reg="$2" p pre proj acct notdone
    r penv_guard 2>&1 || echo "FAIL penv_guard"
    for p in 09:FS 10:CP 11:KV 12:PA 13:OP 14:CL 15:PS 16:RG; do
      pre="${p#*:}"
      printf '%s ' "${p%%:*}"
      awk -F'\t' -v p="$pre" '$2 ~ "^"p"-" {print $2"\t"$3}' "$tsv" | sort -u -k1,1 | awk -F'\t' '{c[$2]++} END {for (k in c) printf "%s=%d ", k, c[k]; print ""}'
    done
    echo "BLOCKED and PENDING lines (each must be in README's BLOCKED index or re-run index):"
    awk -F'\t' '$3=="BLOCKED" || $3=="PENDING" {print $2"\t"$3"\t"$7}' "$tsv" | sort -u
    proj="$(gcloud config get project 2>/dev/null)"
    case "$proj" in ''|'(unset)') echo "default project: none";; *) echo "FAIL default project set: $proj";; esac
    acct="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)"
    [ "$acct" = "$(v SA_1_ADMIN)" ] && echo "account: $acct" || echo "FAIL not sa-1-admin@ (active: ${acct:-none})"
    if [ -f "$reg" ]; then
      grep -E '^\| BD-10-6 ' "$reg" || echo "FAIL no BD-10-6 row in the deviation register"
      grep -A200 '^## Closures' "$reg" | grep -E '^\| BD-10-6 ' || echo "FAIL BD-10-6 has no line under Closures: the creator's Owner is not removed (12)"
    else
      echo "FAIL DEVIATION_REGISTER $reg does not exist (01 PR-4.1)"
    fi
    notdone="$(_fm_prior_steps)"
    if [ -n "$notdone" ]; then echo "FAIL steps of 09 to 16 with no DONE, BLOCKED, PENDING or N/A line:"; printf '%s\n' "$notdone" | sed 's/^/  /'; fi
}

step FM-0.1 AUTO-READ "Open the sitting and check files 09 to 16 and the gates" \
  --needs "ORG_ID REGION PLATFORM_REPO_DIR BUILD_LOG_DIR DEVIATION_REGISTER EVIDENCE_REGISTER SA_1_ADMIN SECOND_HUMAN_EMAIL BILLING_ACCOUNT_ID BILLING_CURRENCY CICD_PROJECT CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT SA_FACTORY_APPLY SA_PLATFORM_DRIFT FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE ENT_PROJECT_REPAIR_CORE ENT_FOLDER_ADMIN ENT_PLATFORM_POLICY DENY_AGENTS_PLATFORM PAB_AGENTS SINK_S_ORG SINK_S_FOLDER PLATFORM_LOGS_VIEWS_DS AGENT_REGISTRY REGISTER_PATH MANIFEST_SCHEMA_PATH NOTIF_CH_PAGER_CORE" \
  --gate "NAMES SD-01 SD-12 SD-17 SD-18 SD-22 SD-40 SD-41 SD-42 SD-44 SD-46"
s_FM_0_1_check() { ckpt_done FM-0.1; }
s_FM_0_1_apply() {
  local f bad=0 tsv reg out
  f="$(_fm_rec FM-0.1-inputs-v1).txt"
  x checkpoint FM-0.1 START || return 1
  _fm_plan "reads: penv_guard; DONE/BLOCKED/PENDING counts per file 09 to 16 in checkpoints.tsv; every BLOCKED and PENDING line;"
  _fm_plan "no default project; the active account is SA_1_ADMIN; BD-10-6 has a row and a line under Closures;"
  _fm_plan "the registered steps of phases 09 to 16 that have no line; saved as ${f##*/} and registered (E-05, 1.4.1)"
  [ "$AGP_MODE" = apply ] || return 0
  tsv="$(v BUILD_LOG_DIR)/checkpoints.tsv"; reg="$(v DEVIATION_REGISTER)"
  out="$(_fm_0_1_reads "$tsv" "$reg")"
  printf '%s\n' "$out" | sed 's/^/        /' >&3
  printf '%s\n' "$out" | xw "$f" 600 >/dev/null || return 1
  printf '%s\n' "$out" | grep -q '^FAIL' && bad=1
  ev FM-0.1 inputs E-05 1.4.1 "build-log:records/${f##*/}" "$f" || return 1
  [ $bad = 0 ] || _fm_say "any FAIL above: stop and finish the earlier file (setup/17 FM-0.1 VERIFY)"
  return $bad
}

step FM-0.2 BLOCKED "Record that the factory's automation is BLOCKED" --note "B-01: factory code; hand equivalents run under SD-01"
s_FM_0_2_check() { ckpt_done FM-0.2; }
s_FM_0_2_manual() {
  echo "BLOCKED on B-01: the factory repository (five modules plus platform-core, each wrapping Fabric project-factory;"
  echo "  the pin v58.0.0 is re-decided when B-01 starts, v59.0.0 being out), its Cloud Build pipeline as factory-apply@"
  echo "  through wif-factory, and the 02 §3.4 checks. The run writes the BLOCKED checkpoint; the run continues."
  echo "READ (yours, the script does not contact the git host):"
  echo "  git -C \"\$PLATFORM_REPO_DIR\" ls-tree -r --name-only origin/main -- factory/ | grep -E '\\.tf\$' | head -n 5"
  echo "VERIFY: no .tf file (one means the factory has started to exist: read FM-11 before any further hand run);"
  echo "  README's BLOCKED index row B-01 names '17 automation' and FM-0.2."
}

_fm_0_3_reads() { # SINK: FM-0.3's reads and their checks, one line each
  local sk="$1" F n rules pab sink
    for F in FLD_AGENTS_R_NONPROD FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_PROD FLD_CONTROLLERS_NONPROD FLD_IMPROVERS_PROD FLD_IMPROVERS_NONPROD FLD_GEMINI_ENTERPRISE; do
      n="$(r gcloud org-policies describe gcp.restrictServiceUsage --folder="$(v "$F")" --effective --format=json 2>/dev/null | _fm_py allowlen)"
      echo "== $F ${n:-0}"; [ "${n:-0}" -gt 0 ] 2>/dev/null || echo "FAIL $F: empty allow-list"
    done
    rules="$(r gcloud iam policies get deny-agents-platform --attachment-point="cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)" --kind=denypolicies --format=json | _fm_py rule-lines)"
    printf '%s\n' "$rules"
    printf '%s\n' "$rules" | grep -qF "principal://iam.googleapis.com/projects/-/serviceAccounts/$(v SA_FACTORY_APPLY)" || echo "FAIL deny-agents-platform: no rule denies factory-apply@ (R6)"
    pab="$(r gcloud iam principal-access-boundary-policies describe pab-agents --organization="$(v ORG_ID)" --location=global --format="value(name,details.enforcementVersion)" 2>&1)"
    echo "$pab"; case "$pab" in *pab-agents*4) ;; *) echo "FAIL pab-agents: not enforcement version 4";; esac
    sink="$(r gcloud logging sinks describe "$sk" --folder="$(v FLD_AGENTIC_PLATFORM)" --format="value(destination,includeChildren,interceptChildren)" 2>&1)"
    echo "$sink"
    case "$sink" in "logging.googleapis.com/projects/$(v LOGGING_PROJECT)"*) ;; *) echo "FAIL S-folder does not point at LOGGING_PROJECT";; esac
    printf '%s\n' "$sink" | grep -q 'True[[:space:]]*True' || echo "FAIL S-folder: includeChildren and interceptChildren are not both True"
}

step FM-0.3 AUTO-READ "Read back the platform the module equivalents stand on" \
  --needs "FLD_AGENTS_R_NONPROD FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_PROD FLD_CONTROLLERS_NONPROD FLD_IMPROVERS_PROD FLD_IMPROVERS_NONPROD FLD_GEMINI_ENTERPRISE FLD_AGENTIC_PLATFORM ORG_ID SINK_S_FOLDER SA_FACTORY_APPLY LOGGING_PROJECT BUILD_LOG_DIR EVIDENCE_REGISTER"
s_FM_0_3_check() { ckpt_done FM-0.3; }
s_FM_0_3_apply() {
  local bad=0 out f sk F
  f="$(_fm_rec FM-0.3-platform-readback-v1).txt"
  sk="$(v SINK_S_FOLDER)"; sk="${sk##*/}"
  if [ "$AGP_MODE" != apply ]; then
    for F in FLD_AGENTS_R_NONPROD FLD_AGENTS_P_SA_PROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_PROD FLD_CONTROLLERS_NONPROD FLD_IMPROVERS_PROD FLD_IMPROVERS_NONPROD FLD_GEMINI_ENTERPRISE; do
      _fm_say "read: $(agp_quote gcloud org-policies describe gcp.restrictServiceUsage --folder="$(v "$F")" --effective --format=json)  (allow-list length > 0)"
    done
    _fm_say "read: $(agp_quote gcloud iam policies get deny-agents-platform --attachment-point="cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)" --kind=denypolicies --format=json)"
    _fm_say "read: $(agp_quote gcloud iam principal-access-boundary-policies describe pab-agents --organization="$(v ORG_ID)" --location=global --format="value(name,details.enforcementVersion)")"
    _fm_say "read: $(agp_quote gcloud logging sinks describe "$sk" --folder="$(v FLD_AGENTIC_PLATFORM)" --format="value(destination,includeChildren,interceptChildren)")"
    _fm_say "saved as ${f##*/} and registered (E-05, 5.2.1)"
    return 0
  fi
  out="$(_fm_0_3_reads "$sk")"

  printf '%s\n' "$out" | sed 's/^/        /' >&3
  printf '%s\n' "$out" | xw "$f" 600 >/dev/null || return 1
  printf '%s\n' "$out" | grep -q '^FAIL' && bad=1
  ev FM-0.3 platform-readback E-05 5.2.1 "build-log:records/${f##*/}" "$f" || return 1
  return $bad
}

step FM-0.4 AUTO-READ "Establish whether this file's organisation-scope reads are permitted" --needs "ORG_ID BUILD_LOG_DIR EVIDENCE_REGISTER"
s_FM_0_4_check() { ckpt_done FM-0.4; }
s_FM_0_4_apply() {
  local R0 ok o
  R0="$(_fm_rec FM-0.4)"; o="$(v ORG_ID)"
  if [ "$AGP_MODE" != apply ]; then
    _fm_say "read: $(agp_quote gcloud organizations get-iam-policy "$o" --format="value(etag)")  > ${R0##*/}-getiampolicy.txt/.err"
    _fm_say "read: $(agp_quote gcloud asset search-all-iam-policies --scope="organizations/${o}" --limit=1 --format="value(resource)")  > ${R0##*/}-assetsearch.txt/.err"
    _fm_say "read: $(agp_quote gcloud logging sinks list --organization="$o" --format="value(name)")  > ${R0##*/}-sinks.txt/.err"
    _fm_say "ORG_READ_OK=yes only with three non-empty outputs and three empty .err files; otherwise no (FM-8.2, FM-8.6, FM-10.1 then PENDING)"
    x checkpoint FM-0.4 DONE - "build-log:records/${R0##*/}-*" "ORG_READ_OK=<yes|no>"
    return 0
  fi
  r gcloud organizations get-iam-policy "$o" --format="value(etag)" 2> "${R0}-getiampolicy.err" | xw "${R0}-getiampolicy.txt" 600 >/dev/null
  r gcloud asset search-all-iam-policies --scope="organizations/${o}" --limit=1 --format="value(resource)" 2> "${R0}-assetsearch.err" | xw "${R0}-assetsearch.txt" 600 >/dev/null
  r gcloud logging sinks list --organization="$o" --format="value(name)" 2> "${R0}-sinks.err" | xw "${R0}-sinks.txt" 600 >/dev/null
  ok=no
  if [ -s "${R0}-getiampolicy.txt" ] && [ -s "${R0}-assetsearch.txt" ] && [ -s "${R0}-sinks.txt" ] \
     && [ ! -s "${R0}-getiampolicy.err" ] && [ ! -s "${R0}-assetsearch.err" ] && [ ! -s "${R0}-sinks.err" ]; then ok=yes; fi
  _fm_say "ORG_READ_OK=$ok"
  cat "${R0}"-*.err 2>/dev/null | sed 's/^/        /' >&3
  if [ "$ok" = no ]; then
    _fm_say "no is not a failure: FM-8.2's organisation line, FM-8.6 and FM-10.1's organisation sink list are recorded PENDING"
    _fm_say "(owner platform owner, re-run point: 12 when an organisation read entitlement is added), and TIER_R_RECORD carries them."
    _fm_say "An output that is empty with no error also counts as no: an empty table proves nothing."
  fi
  printf 'ORG_READ_OK=%s\n' "$ok" | xw "${R0}-org-read-scope-v1.txt" 600 >/dev/null || return 1
  ev FM-0.4 org-read-scope E-08 "4.2.1, 5.2.4" "build-log:records/${R0##*/}-*" "${R0}-org-read-scope-v1.txt" || return 1
  x checkpoint FM-0.4 DONE - "build-log:records/${R0##*/}-*" "ORG_READ_OK=$ok"
}

# ---------------------------------------------------------------- 1. The run spec and the zero-diff checker

step FM-1.1 AUTO "Commit the run-spec template" --needs "PLATFORM_REPO_DIR"
s_FM_1_1_check() {
  local t; t="$(v PLATFORM_REPO_DIR)/factory/runs/_template.json"
  [ -f "$t" ] && cmp -s "$AGP_HOME/assets/fm-runspec-template.json" "$t"
}
s_FM_1_1_apply() {
  local d; d="$(v PLATFORM_REPO_DIR)"
  [ -d "$d/factory/runs" ] || x mkdir -p "$d/factory/runs" || return 1
  xw "$d/factory/runs/_template.json" 644 < "$AGP_HOME/assets/fm-runspec-template.json" || return 1
  if [ "$AGP_MODE" = apply ]; then
    python3 -m json.tool "$d/factory/runs/_template.json" >/dev/null && _fm_say "JSON-OK" || { _fm_say "the template is not valid JSON"; return 1; }
  fi
  _fm_say "then, yourself at the git host (the script never contacts it): git switch -c fm-1-runspec-template; git add"
  _fm_say "factory/runs/_template.json; commit 'factory: run-spec template for hand module equivalents (setup 17 FM-1.1, SD-01)';"
  _fm_say "push; merge with two human approvals. If BD-10-7 item 5 says hyphens won for label keys, change them in that pull request."
}

step FM-1.2 AUTO "Commit the zero-diff checker" --needs "PLATFORM_REPO_DIR"
s_FM_1_2_check() {
  local t; t="$(v PLATFORM_REPO_DIR)/tools/fm-zero-diff.py"
  [ -x "$t" ] && cmp -s "$AGP_HOME/assets/fm-zero-diff.py" "$t"
}
s_FM_1_2_apply() {
  local d py; d="$(v PLATFORM_REPO_DIR)"
  [ -d "$d/tools" ] || x mkdir -p "$d/tools" || return 1
  xw "$d/tools/fm-zero-diff.py" 755 < "$AGP_HOME/assets/fm-zero-diff.py" || return 1
  py="${REGISTER_VENV_PYTHON:-$HOME/platform/venv-register/bin/python}"
  if [ "$AGP_MODE" = apply ]; then
    if command -v python3.12 >/dev/null 2>&1; then
      python3.12 -m py_compile "$d/tools/fm-zero-diff.py" || return 1
    else
      _fm_say "python3.12 is not on PATH (a workstation precondition of setup/17): py_compile not run; install it before FM-1.4"
    fi
    if [ -x "$py" ] && "$py" -c 'import yaml' 2>/dev/null; then _fm_say "PyYAML $("$py" -c 'import yaml; print(yaml.__version__)') in $py"
    else _fm_say "the register interpreter $py with PyYAML is missing: re-run 16 RG-2.1 before FM-1.4 (never parse YAML by hand)"; fi
  fi
  _fm_say "then, yourself: git switch main && git pull --ff-only; git switch -c fm-1-zero-diff-checker; add tools/fm-zero-diff.py;"
  _fm_say "commit 'tools: fm-zero-diff checker for hand module equivalents (setup 17 FM-1.2)'; push; merge with two human"
  _fm_say "approvals, one the security reviewer once appointed (otherwise the second human)."
}

step FM-1.3 HUMAN "Write a platform-core run spec for CICD_PROJECT" --needs "CICD_PROJECT FLD_PLATFORM_CORE PLATFORM_REPO_DIR"
_fm_cicd_spec_ok() {
  local s; s="$(v PLATFORM_REPO_DIR)/factory/runs/platform-core-cicd.json"
  [ -f "$s" ] && [ "$(_fm_py get "$s" module 2>/dev/null)" = platform-core ] \
    && [ "$(_fm_py get "$s" create 2>/dev/null)" = false ] && [ "$(_fm_py get "$s" run_id 2>/dev/null)" = dev-10-core-cicd ]
}
s_FM_1_3_check() { ckpt_done FM-1.3 || _fm_cicd_spec_ok; }
s_FM_1_3_manual() {
  echo "WHO: the platform owner. WHERE: PLATFORM_REPO_DIR (by hand: the reads are for transcription, 10's records are the source)."
  echo "DO: cp factory/runs/_template.json factory/runs/platform-core-cicd.json, then fill it as setup/17 FM-1.3 says"
  echo "  (module platform-core, create false, run_id dev-10-core-cicd, 10's labels and services, the two contact groups,"
  echo "  the four service accounts of CP-8.1, non-human bindings, lien true, project_floor applies false with its reason"
  echo "  and made_elsewhere line). Reads: gcloud services list --enabled --project=$(v CICD_PROJECT) --format=\"value(config.name)\";"
  echo "  gcloud projects get-iam-policy $(v CICD_PROJECT) --flatten=\"bindings[].members\"; gcloud projects describe $(v CICD_PROJECT) --format=\"json(labels)\"."
  echo "A value that differs between 10's record and the live read is a finding: write it to the build log, resolve before FM-1.4."
  echo "VERIFY: the file is valid JSON and module, create, run_id read platform-core, false, dev-10-core-cicd (the check reads them)."
  echo "THEN: agp-platform done FM-1.3   (or re-run apply: the step reads as done once the file holds those three values)"
}

step FM-1.4 AUTO-READ "Prove the checker: the register fixture, zero diff on CICD_PROJECT, then a deliberate diff" \
  --needs "CICD_PROJECT BUILD_LOG_DIR PLATFORM_REPO_DIR EVIDENCE_REGISTER"
s_FM_1_4_check() { ckpt_done FM-1.4; }
s_FM_1_4_apply() {
  local d R s rc bad=0 rows fails
  d="$(v PLATFORM_REPO_DIR)"; R="$(_fm_rec FM-1.4)"; s="factory/runs/platform-core-cicd.json"
  [ -d "$d/register/fixtures" ] || x mkdir -p "$d/register/fixtures" || return 1
  xw "$d/register/fixtures/fm-zero-diff-row.yaml" 644 < "$AGP_HOME/assets/fm-zero-diff-row.yaml" || return 1
  if [ "$AGP_MODE" != apply ]; then
    _fm_say "writes ${R##*/}-fixture-spec.json (agent_id fm-fixture, env prod, register_tier R, register_row the fixture),"
    _fm_say "${R##*/}-fixture-bad.json (register_tier W) and ${R##*/}-negative-spec.json (labels.env nonprod, services + compute)"
    _fm_checker inputs "${R}-fixture-spec.json" "${R}-fixture-ok-v1.json"
    _fm_checker inputs "${R}-fixture-bad.json" "${R}-fixture-bad-v1.json"
    _fm_checker live "$s" "${R}-cicd-live-v1.json"
    _fm_checker live "${R}-negative-spec.json" "${R}-cicd-negative-v1.json"
    _fm_say "expected: fixture exit 0 with row.* PASS; bad fixture exactly one FAIL row.tier, exit 1; CICD_PROJECT ZERO-DIFF exit 0;"
    _fm_say "negative DIFF exit 1 with exactly project.labels and services.exact. Then commit the spec and fixture yourself."
    return 0
  fi
  _fm_cicd_spec_ok || { _fm_say "STOP: $s is missing or not FM-1.3's (module, create, run_id)"; return 1; }
  command -v python3.12 >/dev/null 2>&1 || { _fm_say "STOP: python3.12 is not on PATH (setup/17 workstation precondition)"; return 1; }
  _fm_py edit "$d/$s" agent_id=fm-fixture env=prod register_tier=R register_row=register/fixtures/fm-zero-diff-row.yaml | xw "${R}-fixture-spec.json" 600 >/dev/null || return 1
  _fm_py edit "${R}-fixture-spec.json" register_tier=W | xw "${R}-fixture-bad.json" 600 >/dev/null || return 1
  _fm_py edit "$d/$s" labels.env=nonprod services+=compute.googleapis.com | xw "${R}-negative-spec.json" 600 >/dev/null || return 1
  _fm_checker inputs "${R}-fixture-spec.json" "${R}-fixture-ok-v1.json"; rc=$?
  rows="$(_fm_py rows "${R}-fixture-ok-v1.json" row. 2>/dev/null)"; printf '%s\n' "$rows" | sed 's/^/        /' >&3
  [ $rc -eq 0 ] && [ "$(printf '%s\n' "$rows" | grep -cE '^PASS row\.(found|agent_id|env|tier) ')" = 4 ] \
    || { _fm_say "FAIL (a): the fixture run is not exit 0 with row.found, row.agent_id, row.env, row.tier PASS (if row.found speaks of rows[], the checker is not reading 16 RG-2.2's format)"; bad=1; }
  _fm_checker inputs "${R}-fixture-bad.json" "${R}-fixture-bad-v1.json"; rc=$?
  fails="$(_fm_py fails "${R}-fixture-bad-v1.json" 2>/dev/null)"
  [ $rc -eq 1 ] && [ "$fails" = "row.tier" ] || { _fm_say "FAIL (a): the bad fixture should fail on row.tier alone with exit 1 (exit $rc; FAIL: $(printf '%s' "$fails" | tr '\n' ' '))"; bad=1; }
  _fm_checker live "$s" "${R}-cicd-live-v1.json"; rc=$?
  [ $rc -eq 0 ] || { _fm_say "FAIL (b): CICD_PROJECT is not ZERO-DIFF (exit $rc): a checker defect (fix by pull request, re-review FM-1.2) or a real difference (repair under ENT_PROJECT_REPAIR_CORE, DEV row)"; bad=1; }
  _fm_checker live "${R}-negative-spec.json" "${R}-cicd-negative-v1.json"; rc=$?
  fails="$(_fm_py fails "${R}-cicd-negative-v1.json" 2>/dev/null | sort | tr '\n' ' ')"
  [ $rc -eq 1 ] && [ "$fails" = "project.labels services.exact " ] || { _fm_say "FAIL (b): the negative run should fail on project.labels and services.exact alone (exit $rc; FAIL: $fails)"; bad=1; }
  [ $bad = 0 ] || return 1
  ev FM-1.4 checker-proof E-05 5.2.4 "build-log:records/${R##*/}-cicd-live-v1.json" "${R}-cicd-live-v1.json" || return 1
  ev FM-1.4 checker-proof E-05 5.2.4 "build-log:records/${R##*/}-cicd-negative-v1.json" "${R}-cicd-negative-v1.json" || return 1
  _fm_say "the checker is trusted. Then, yourself: git add $s register/fixtures/fm-zero-diff-row.yaml; commit"
  _fm_say "'factory: platform-core run spec for CICD_PROJECT and the checker's register fixture (setup 17 FM-1.4)'; push."
}

# ---------------------------------------------------------------- 2. FM-COMMON (per call)

step FM-2.1 HUMAN "Inputs: the merged register row, the manifest and the run spec" --sets "FM_RUN_SPEC FM_BD_ID"
s_FM_2_1_check() {
  if _fm_run_selected; then _fm_ctx; _fm_ckpt_is "FM-2.1@$FM_RUN" DONE; else ckpt_done FM-2.1; fi
}
s_FM_2_1_manual() {
  echo "PER CALL. In this file's own sitting there is no run: continue with  agp-platform apply --phase 17 --from FM-8.1"
  echo "A calling file (18, 19, 22, 23, 31, 37): refuse without TIER_R_RECORD (test -s \"\$PLATFORM_REPO_DIR/\$TIER_R_RECORD\"), except 17's own sittings."
  echo "WHO: the platform owner writes; two human reviewers merge (the second human for factory/runs/eve-*.json; the security"
  echo "  reviewer for a P-SA production run). WHERE: PLATFORM_REPO_DIR and the git host."
  echo "DO: copy factory/runs/_template.json to factory/runs/<agent_id>-<env>.json, fill it from the merged row, the manifest,"
  echo "  the module section's table and the signed NAMES register (setup/17 FM-2.1 filling rules); run"
  echo "  python3.12 tools/fm-zero-diff.py inputs <spec> --report <R>-FM-2.1-inputs-v1.json (ZERO-DIFF, exit 0); commit, push, merge."
  echo "RECORD: evidence_add FM-2.1@<run> inputs E-05 1.3.1 \"build-log:records/<R name>-FM-2.1-inputs-v1.json\" \"<R>-FM-2.1-inputs-v1.json\""
  echo "  (with the file, so the register holds its SHA-256); checkpoint FM-2.1@<run> DONE"
  echo "THEN, in the shell that runs the call: export FM_RUN_SPEC=factory/runs/<agent_id>-<env>.json FM_BD_ID=<BD-xx-n the calling"
  echo "  file allocates>, and run  agp-platform apply --phase 17 --from FM-2.2 --to FM-2.22  with the module section where §3 to §7 say."
}

step FM-2.2 AUTO "Activate the run's entitlement" --witness --on-unmet skip --needs "FM_RUN_SPEC CICD_PROJECT PLATFORM_REPO_DIR SA_1_ADMIN" \
  --note "witness: the run's approver (second human; security reviewer and second human for P-SA prod)"
_fm_ent_of_run() { local n; n="$(_fm_ent_var)"; v "$n"; }
s_FM_2_2_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  _fm_ckd FM-2.22 && return 0
  local e nv; nv="$(_fm_ent_var)"
  has_value "$nv" || { echo "      $nv has no value: the folder's entitlement is created in 12 first (SD-46)"; return 1; }
  e="$(_penv_get "$nv")"
  nonempty r gcloud pam grants list --entitlement="$e" --location=global --billing-project="$(v CICD_PROJECT)" --filter="state=ACTIVE" --format="value(name)"
  case $? in 0) return 0;; 3) return 3;; esac
  if nonempty r gcloud pam grants list --entitlement="$e" --location=global --billing-project="$(v CICD_PROJECT)" --filter="state=APPROVAL_AWAITED" --format="value(name)"; then
    echo "      a grant on $e awaits its approver; re-run when it is approved (no second request)"; return 2
  fi
  return 1
}
s_FM_2_2_apply() {
  _fm_apre || return 1
  local nv e g sha f
  nv="$(_fm_ent_var)"
  if [ "$AGP_MODE" = apply ]; then
    has_value "$nv" || { _fm_say "STOP: $nv has no value: create the folder's entitlement in 12 first (SD-46)"; return 1; }
    case "$FM_MOD:$FM_ENV:$FM_TIER" in
      agent-project:prod:P-SA) _fm_after FM-3.1 || return 1;;
      verifier-project:*) _fm_after FM-4.1 || return 1;;
    esac
  fi
  _fm_after FM-2.1 || return 1
  if [ "$FM_OK" = 1 ]; then _fm_plan "ENT_VAR=$nv (the page's entitlement column for the run's parent folder); ENT is its value in ~/.platform-env"
  else _fm_plan "ENT_VAR: the page's entitlement column for spec.parent_folder_variable; ENT is its value in ~/.platform-env"; fi
  e="$(v "$nv")"; f="${FM_R}-FM-2.2-grant-v1.txt"
  _fm_save "$f" gcloud pam entitlements describe "$e" --location=global --billing-project="$(v CICD_PROJECT)" --format="yaml(eligibleUsers,approvalWorkflow,maxRequestDuration,privilegedAccess)" || return 1
  if [ "$AGP_MODE" = apply ]; then sha="$(git -C "$(v PLATFORM_REPO_DIR)" rev-parse --short origin/main 2>/dev/null || echo unknown)"; else sha="<origin/main>"; fi
  _fm_plan "the approver reads the justification, opens the merged spec and runs: gcloud pam grants approve <grant> --reason=\"spec reviewed: $FM_RUNID\" --location=global --billing-project=$(v CICD_PROJECT)"
  g="$(_fm_grant "$e" 3600s "${FM_RUNID}: hand module equivalent, spec ${sha} (setup 17, SD-01, SD-46)")" || return 1
  if [ "$AGP_MODE" = apply ]; then
    printf 'GRANT %s\n' "$g" >> "$f"
    _fm_say "VERIFY by eye in ${f##*/}: eligibleUsers include platform-owners@, the 04 §5.2 ent-factory-singleton bundle on this folder,"
    _fm_say "maxRequestDuration 1 hour, approvers as the module section names and never the platform owner"
  fi
  _fm_ck FM-2.2 DONE "grant $g"
}

step FM-2.3 AUTO "Create the project under its folder" --irreversible --gate "NAMES" --on-unmet skip --needs "FM_RUN_SPEC PLATFORM_REPO_DIR"
s_FM_2_3_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  [ "$(_fm_sv create)" = true ] || return 0
  exists gcloud projects describe "$FM_PID" --format="value(projectId)"
}
s_FM_2_3_apply() {
  _fm_apre || return 1
  local sv
  if [ "$AGP_MODE" = apply ] && [ "$(_fm_sv create)" != true ]; then
    _fm_say "create is false: N/A"; _fm_ck FM-2.3 N/A "create false"; return 0
  fi
  _fm_after FM-2.2 || return 1
  if [ "$AGP_MODE" = apply ]; then
    sv="$("$(agp_tool decision-value.sh)" NAMES "$FM_PVAR" 2>/dev/null)"
    [ "$sv" = "$FM_PID" ] || { _fm_say "STOP: id differs from the signed NAMES register ($FM_PVAR: '$sv', spec '$FM_PID')"; return 1; }
    [ -n "$FM_PFLD" ] && [ "$FM_PFLD" != "MISSING-$FM_PFLDVAR" ] || { _fm_say "STOP: $FM_PFLDVAR has no value"; return 1; }
  fi
  x gcloud projects create "$FM_PID" --folder="$FM_PFLD" --name="$(printf '%s %s' "$FM_AG" "$FM_ENV" | cut -c1-30)" \
    --no-enable-cloud-apis --labels="$( [ "$FM_OK" = 1 ] && _fm_py labels "$FM_SPEC" || printf '<spec.labels-as-k=v>')" || return 1
  x gcloud alpha resource-manager liens create --project="$FM_PID" --restrictions=resourcemanager.projects.delete \
    --reason="Module-equivalent project ${FM_RUNID}; deletion only through FM-REVOKE" --origin="setup-17-${FM_RUNID}" || return 1
  _fm_save "${FM_R}-FM-2.3-project-v1.txt" gcloud projects describe "$FM_PID" --format="yaml(parent,labels,lifecycleState)" || return 1
  _fm_save "${FM_R}-FM-2.3-liens-v1.txt" gcloud alpha resource-manager liens list --project="$FM_PID" || return 1
  _fm_ck FM-2.3 DONE "project $FM_PID under $FM_PFLDVAR"
}

step FM-2.4 AUTO "Record the id and number" --on-unmet skip --needs "FM_RUN_SPEC"
s_FM_2_4_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  has_value "$FM_PVAR" && has_value "${FM_PVAR}_NUMBER" && [ "$(_penv_get "$FM_PVAR")" = "$FM_PID" ]
}
s_FM_2_4_apply() {
  _fm_apre || return 1
  local n
  pset "$FM_PVAR" "$FM_PID" || return 1
  if [ "$AGP_MODE" = apply ]; then
    n="$(r gcloud projects describe "$FM_PID" --format='value(projectNumber)')" || return 1
    case "$n" in ''|*[!0-9]*) _fm_say "STOP: no project number for $FM_PID"; return 1;; esac
    pset "${FM_PVAR}_NUMBER" "$n" || return 1
  else
    _fm_plan "read: gcloud projects describe $FM_PID --format='value(projectNumber)'"; pset "${FM_PVAR}_NUMBER" "<number>"
  fi
  _fm_ck FM-2.4 DONE "$FM_PVAR"
}

step FM-2.5 AUTO "Link billing" --on-unmet skip --needs "FM_RUN_SPEC BILLING_ACCOUNT_ID BOOTSTRAP_BILLING_EXPIRY"
s_FM_2_5_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  local out; out="$(r gcloud billing projects describe "$FM_PID" --format="value(billingAccountName,billingEnabled)" 2>/dev/null)" || return 1
  case "$out" in "billingAccounts/$(v BILLING_ACCOUNT_ID)"*True) return 0;; esac
  return 1
}
s_FM_2_5_apply() {
  _fm_apre || return 1
  if [ "$AGP_MODE" = apply ] && ! [[ "$(date -u +%F)" < "$(v BOOTSTRAP_BILLING_EXPIRY)" ]]; then
    _fm_say "billing roles expired on $(v BOOTSTRAP_BILLING_EXPIRY): the billing administrator runs, in their own session:"
    _fm_say "  gcloud billing projects link $FM_PID --billing-account=$(v BILLING_ACCOUNT_ID)"
    _fm_say "then re-run this step: it reads as done once the project is linked"
    return 1
  fi
  x gcloud billing projects link "$FM_PID" --billing-account="$(v BILLING_ACCOUNT_ID)" || { _fm_say "a refusal naming a project quota stops the run until 07's quota request is raised again"; return 1; }
  _fm_save "${FM_R}-FM-2.5-billing-v1.txt" gcloud billing projects describe "$FM_PID" --format="value(billingAccountName,billingEnabled)" || return 1
  _fm_ck FM-2.5 DONE "billing linked"
}

step FM-2.6 AUTO-READ "Confirm the inherited tags" --on-unmet skip --needs "FM_RUN_SPEC"
s_FM_2_6_check() { _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0; _fm_ckd FM-2.6; }
s_FM_2_6_apply() {
  _fm_apre || return 1
  local num par eff direct
  if [ "$AGP_MODE" != apply ]; then
    _fm_say "read: gcloud resource-manager tags bindings list --parent=//cloudresourcemanager.googleapis.com/projects/<number> --effective --format=json"
    _fm_say "read: the same without --effective (direct bindings: none expected); compare with the spec's tags_effective"
    _fm_ck FM-2.6 DONE "tags inherited"; return 0
  fi
  num="$(r gcloud projects describe "$FM_PID" --format='value(projectNumber)')" || return 1
  par="//cloudresourcemanager.googleapis.com/projects/${num}"
  eff="$(r gcloud resource-manager tags bindings list --parent="$par" --effective --format=json)" || return 1
  direct="$(r gcloud resource-manager tags bindings list --parent="$par" --format="value(tagValue)")" || return 1
  printf '%s\n--- direct:\n%s\n' "$eff" "$direct" | xw "${FM_R}-FM-2.6-tags-v1.txt" 600 >/dev/null
  printf '%s' "$eff" | _fm_py tags "$FM_SPEC" | sed 's/^/        /' >&3
  printf '%s' "$eff" | _fm_py tags "$FM_SPEC" >/dev/null || { _fm_say "STOP: a missing or different inherited tag is 09's binding to correct"; return 1; }
  [ -z "$direct" ] || { _fm_say "STOP: direct tag bindings on the project: $direct"; return 1; }
  _fm_ck FM-2.6 DONE "tags inherited"
}

step FM-2.7 AUTO "Enable exactly the spec's services" --on-unmet skip --needs "FM_RUN_SPEC"
_fm_services_missing() {    # the spec's services not enabled (one per line)
  local en; en="$(r gcloud services list --enabled --project="$FM_PID" --format="value(config.name)" 2>/dev/null)" || return "$(_fm_nf $?)"
  _fm_list services | while read -r s; do printf '%s\n' "$en" | grep -qxF "$s" || echo "$s"; done
}
s_FM_2_7_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  local m; m="$(_fm_services_missing)" || return $?
  [ -z "$m" ]
}
s_FM_2_7_apply() {
  _fm_apre || return 1
  local S en extra
  _fm_after FM-2.5 || return 1
  for S in $(_fm_list services); do
    x gcloud services enable "$S" --project="$FM_PID" || { _fm_say "REFUSED $S: a restrictServiceUsage refusal means the spec names a service outside the folder list; correct the spec by pull request, never the folder policy"; return 1; }
  done
  [ "$AGP_MODE" = apply ] || { _fm_ck FM-2.7 DONE "services"; return 0; }
  en="$(r gcloud services list --enabled --project="$FM_PID" --format="value(config.name)" | sort)" || return 1
  printf '%s\n' "$en" | xw "${FM_R}-FM-2.7-services-v1.txt" 600 >/dev/null
  extra="$(printf '%s\n' "$en" | comm -13 <(_fm_list services | sort) -)"
  [ -z "$extra" ] || _fm_say "REVIEW enabled but not in the spec (each a dependency Google enabled, added to service_dependencies by a spec revision): $(printf '%s' "$extra" | tr '\n' ' ')"
  _fm_ck FM-2.7 DONE "services"
}

FM17_DEFAULT_FILTER='NOT LOG_ID("cloudaudit.googleapis.com/activity") AND NOT LOG_ID("externalaudit.googleapis.com/activity") AND NOT LOG_ID("cloudaudit.googleapis.com/system_event") AND NOT LOG_ID("externalaudit.googleapis.com/system_event") AND NOT LOG_ID("cloudaudit.googleapis.com/access_transparency") AND NOT LOG_ID("externalaudit.googleapis.com/access_transparency")'

_fm_route_check() { # PROJECT: _Default ends with the spec's regional bucket
  local d; d="$(r gcloud logging sinks describe _Default --project="$1" --format="value(destination)" 2>/dev/null)" || return "$(_fm_nf $?)"
  case "$d" in */locations/"$(_fm_sv log_routing.location)"/buckets/"$(_fm_sv log_routing.default_bucket)") return 0;; esac
  return 1
}
_fm_route_apply() { # PROJECT: FM-2.8's commands
  local p="$1" B L D
  B="$(_fm_sv log_routing.default_bucket)"; L="$(_fm_sv log_routing.location)"; D="$(_fm_sv log_routing.retention_days)"
  if [ "$AGP_MODE" != apply ] || ! exists gcloud logging buckets describe "$B" --location="$L" --project="$p"; then
    x gcloud logging buckets create "$B" --location="$L" --retention-days="$D" --description="Regional destination of _Default (SD-17, ${FM_RUNID})" --project="$p" || return 1
  fi
  x gcloud logging sinks update _Default "logging.googleapis.com/projects/${p}/locations/${L}/buckets/${B}" --log-filter="$FM17_DEFAULT_FILTER" --project="$p" || return 1
  _fm_save "${FM_R}-log-routing-v1.txt" gcloud logging sinks describe _Required --project="$p" --format="value(destination)" || return 1
  _fm_plan "never a Cloud Logging folder default (SD-17); the routing test of 10 CP-1.7 (write an entry, read it from the regional bucket) is yours"
}

step FM-2.8 AUTO "Route _Default to a regional bucket; leave _Required global" --irreversible --on-unmet skip --needs "FM_RUN_SPEC"
s_FM_2_8_check() { _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0; _fm_route_check "$FM_PID"; }
s_FM_2_8_apply() { _fm_apre || return 1; _fm_route_apply "$FM_PID" || return 1; _fm_ck FM-2.8 DONE "_Default regional"; }

_fm_trace_check() { # PROJECT
  nonempty r gcloud observability buckets list --location="$(v REGION)" --project="$1" --filter="name~/_Trace\$" --format="value(name)"
}
_fm_trace_apply() { # PROJECT
  if [ "$AGP_MODE" = apply ]; then
    _fm_py get "$FM_SPEC" services | grep -q '"observability.googleapis.com"' || { _fm_say "STOP: observability API not in spec"; return 1; }
  fi
  x gcloud observability buckets create _Trace --location="$(v REGION)" --project="$1"
}

step FM-2.9 AUTO "Create _Trace in europe-west1" --irreversible --on-unmet skip --needs "FM_RUN_SPEC REGION"
s_FM_2_9_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  [ "$(_fm_sv log_routing.trace_bucket)" = false ] && { _fm_ckd FM-2.9; return $?; }
  _fm_trace_check "$FM_PID"
}
s_FM_2_9_apply() {
  _fm_apre || return 1
  if [ "$AGP_MODE" = apply ] && [ "$(_fm_sv log_routing.trace_bucket)" = false ]; then
    _fm_say "trace_bucket false: N/A with the spec's reason"; _fm_ck FM-2.9 N/A "trace_bucket false"; return 0
  fi
  _fm_trace_apply "$FM_PID" || return 1
  _fm_save "${FM_R}-FM-2.9-trace-v1.txt" gcloud observability buckets list --location="$(v REGION)" --project="$FM_PID" || return 1
  _fm_ck FM-2.9 DONE "_Trace"
}

step FM-2.10 AUTO "Create the project budget" --on-unmet skip --needs "FM_RUN_SPEC BILLING_ACCOUNT_ID BILLING_CURRENCY CICD_PROJECT BOOTSTRAP_BILLING_EXPIRY"
s_FM_2_10_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  nonempty r gcloud billing budgets list --billing-account="$(v BILLING_ACCOUNT_ID)" --billing-project="$(v CICD_PROJECT)" \
    --filter="displayName=$(_fm_sv budget.display_name)" --format="value(name)"
}
s_FM_2_10_apply() {
  _fm_apre || return 1
  local cur
  if [ "$AGP_MODE" = apply ]; then
    if ! [[ "$(date -u +%F)" < "$(v BOOTSTRAP_BILLING_EXPIRY)" ]]; then
      _fm_say "billing roles expired: the billing administrator runs FM-2.10's create in their own session, then re-run this step"; return 1
    fi
    cur="$(r gcloud billing accounts describe "$(v BILLING_ACCOUNT_ID)" --format='value(currencyCode)')" || return 1
    [ "$cur" = "$(v BILLING_CURRENCY)" ] || { _fm_say "STOP: currency changed ($cur)"; return 1; }
  fi
  x gcloud billing budgets create --billing-account="$(v BILLING_ACCOUNT_ID)" --display-name="$(_fm_sv budget.display_name)" \
    --budget-amount="$(_fm_sv budget.amount)" --filter-projects="projects/${FM_PID}" --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 \
    --threshold-rule=percent=1.0 --threshold-rule=percent=1.0,basis=forecasted-spend --billing-project="$(v CICD_PROJECT)" || return 1
  _fm_save "${FM_R}-FM-2.10-budget-v1.txt" gcloud billing budgets list --billing-account="$(v BILLING_ACCOUNT_ID)" --billing-project="$(v CICD_PROJECT)" \
    --filter="displayName=$(_fm_sv budget.display_name)" --format="yaml(amount,budgetFilter.projects,thresholdRules)" || return 1
  _fm_plan "VERIFY: one budget, the spec's amount, a project filter naming only this project (never empty), four thresholds"
  _fm_ck FM-2.10 DONE "budget"
}

_fm_contacts_missing() {    # PROJECT: spec contact emails not listed
  local got c e
  got="$(r gcloud essential-contacts list --project="$1" --billing-project="$(v CICD_PROJECT)" --format="value(email)" 2>/dev/null)" || return "$(_fm_nf $?)"
  _fm_list essential_contacts | while read -r c; do e="$(_fm_field "$c" email)"; printf '%s\n' "$got" | grep -qxF "$e" || echo "$e"; done
}
_fm_cats() { if [ "${1#<}" != "$1" ]; then printf '<spec-categories-lower-case-hyphenated>'; else _fm_py cats "$1"; fi; }
_fm_contacts_apply() {      # PROJECT: FM-2.11's loop, skipping a contact already listed
  local p="$1" c e have=""
  [ "$AGP_MODE" = apply ] && have="$(r gcloud essential-contacts list --project="$p" --billing-project="$(v CICD_PROJECT)" --format="value(email)" 2>/dev/null)"
  _fm_list essential_contacts | while read -r c; do
    e="$(_fm_field "$c" email)"
    printf '%s\n' "$have" | grep -qxF "$e" && continue
    x gcloud essential-contacts create --email="$e" \
      --notification-categories="$(_fm_cats "$c")" \
      --language=en --project="$p" --billing-project="$(v CICD_PROJECT)" || exit 1
  done
}

step FM-2.11 AUTO "Set Essential Contacts" --on-unmet skip --needs "FM_RUN_SPEC CICD_PROJECT"
s_FM_2_11_check() { _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0; local m; m="$(_fm_contacts_missing "$FM_PID")" || return $?; [ -z "$m" ]; }
s_FM_2_11_apply() {
  _fm_apre || return 1
  _fm_contacts_apply "$FM_PID" || return 1
  _fm_save "${FM_R}-FM-2.11-contacts-v1.txt" gcloud essential-contacts list --project="$FM_PID" --billing-project="$(v CICD_PROJECT)" --format="table(email,notificationCategorySubscriptions)" || return 1
  _fm_ck FM-2.11 DONE "contacts"
}

FM17_CREDENTIAL_ROLES='*secretmanager*|*cloudkms*|*run.invoker*|*serviceAccountTokenCreator*|*serviceAccountUser*|*iam.securityAdmin*|*projectIamAdmin*|roles/owner|roles/editor'

step FM-2.12 AUTO "Create the service accounts and the non-credential project bindings" --on-unmet skip --needs "FM_RUN_SPEC"
s_FM_2_12_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  local got sa b
  got="$(r gcloud iam service-accounts list --project="$FM_PID" --format="value(email)" 2>/dev/null)" || return "$(_fm_nf $?)"
  for sa in $(_fm_list service_accounts); do printf '%s\n' "$got" | grep -q "^${sa}@" || return 1; done
  while read -r b; do
    [ -n "$b" ] || continue
    # shellcheck disable=SC2254
    case "$(_fm_field "$b" role)" in $FM17_CREDENTIAL_ROLES) continue;; esac
    has_binding "$(_fm_field "$b" member)" "$(_fm_field "$b" role)" gcloud projects get-iam-policy "$FM_PID" || return 1
  done <<EOF
$(_fm_list project_bindings)
EOF
  return 0
}
s_FM_2_12_apply() {
  _fm_apre || return 1
  local SA B role have=""
  [ "$AGP_MODE" = apply ] && have="$(r gcloud iam service-accounts list --project="$FM_PID" --format="value(email)" 2>/dev/null)"
  for SA in $(_fm_list service_accounts); do
    printf '%s\n' "$have" | grep -q "^${SA}@" && continue
    x gcloud iam service-accounts create "$SA" --display-name="$SA" --description="${FM_RUNID} (setup 17 FM-2.12)" --project="$FM_PID" || return 1
  done
  while read -r B; do
    [ -n "$B" ] || continue
    role="$(_fm_field "$B" role)"
    # shellcheck disable=SC2254
    case "$role" in $FM17_CREDENTIAL_ROLES) _fm_say "REFUSED credential role in spec: $B (fix the spec by pull request; credential paths are the calling file's, FM-2.18 onwards)"; return 1;; esac
    x gcloud projects add-iam-policy-binding "$FM_PID" --member="$(_fm_field "$B" member)" --role="$role" --condition=None >/dev/null || return 1
  done <<EOF
$(_fm_list project_bindings)
EOF
  _fm_save "${FM_R}-FM-2.12-identities-v1.txt" gcloud iam service-accounts list --project="$FM_PID" --format="value(email)" || return 1
  _fm_plan "VERIFY also: keys list --managed-by=user is empty for each account (keyless, B2, B3)"
  _fm_ck FM-2.12 DONE "identities"
}

# Model Armor floor settings live on the global endpoint. The override is set for that one command,
# through the environment (as 18 and 19 do), never exported into the runner's shell.
_fm_ma_ep() { printf 'CLOUDSDK_API_ENDPOINT_OVERRIDES_MODELARMOR=https://modelarmor.googleapis.com/'; }

step FM-2.12a AUTO "Apply the Model Armor project floor (PF)" --witness --on-unmet skip \
  --needs "FM_RUN_SPEC ENT_FOLDER_ADMIN CICD_PROJECT PLATFORM_REPO_DIR" --note "witness: the second human, approver of the ENT_FOLDER_ADMIN grant"
s_FM_2_12a_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  _fm_ckpt_is "FM-2.12a@$FM_RUN" N/A PENDING && return 0
  [ "$(_fm_sv project_floor.applies)" = true ] || return 1
  r env "$(_fm_ma_ep)" gcloud model-armor floorsettings describe --full-uri="projects/${FM_PID}/locations/global/floorSetting" --billing-project="$FM_PID" --format=json 2>/dev/null \
    | _fm_py floor-on
}
s_FM_2_12a_apply() {
  _fm_apre || return 1
  local F vals PIE MU PI ET RAI num uri
  if [ "$AGP_MODE" = apply ] && [ "$(_fm_sv project_floor.applies)" != true ]; then
    _fm_say "project_floor.applies=false: N/A, reason $(_fm_sv project_floor.reason)"
    _fm_ck FM-2.12a N/A "applies false: $(_fm_sv project_floor.reason | tr -d '\t\n' | cut -c1-120)"; return 0
  fi
  _fm_after FM-2.7 || return 1
  F="$(v PLATFORM_REPO_DIR)/$(_fm_sv project_floor.floors_file)"
  if [ "$AGP_MODE" = apply ] && [ ! -s "$F" ]; then
    _fm_say "PENDING: model-armor/floors.json not merged yet (18 KS-2.3). The spec's pending[] carries floor.enforced (owner platform owner,"
    _fm_say "re-run in 18 KS-2.9); this is the canary-r run of 18 KS-1.3 only."
    _fm_ck FM-2.12a PENDING "floors.json not merged (18 KS-2.3); applied by 18 KS-2.9"; return 0
  fi
  uri="projects/${FM_PID}/locations/global/floorSetting"
  if [ "$AGP_MODE" = apply ]; then
    vals="$(_fm_py floor "$F" "$FM_SPEC")" || { _fm_say "$vals"; return 1; }
    PIE="$(printf '%s\n' "$vals" | sed -n 1p)"; MU="$(printf '%s\n' "$vals" | sed -n 2p)"; PI="$(printf '%s\n' "$vals" | sed -n 3p)"
    ET="$(printf '%s\n' "$vals" | sed -n 4p)"; RAI="$(printf '%s\n' "$vals" | sed -n 5p)"
    num="$(r gcloud projects describe "$FM_PID" --format='value(projectNumber)')" || return 1
  else
    PIE="<from floors.json .spellings.accepted>"; MU="$PIE"; PI="<spec pi_confidence, that spelling>"; ET="$(_fm_sv project_floor.vertex_enforcement)"
    RAI="<floors.json .floors[level=platform] .gcloud.rai or .rest.rai>"; num="<number>"
  fi
  _fm_save "${FM_R}-FM-2.12a-floor-before-v1.json" env "$(_fm_ma_ep)" gcloud model-armor floorsettings describe --full-uri="$uri" --billing-project="$FM_PID" --format=json || return 1
  _fm_grant "$(v ENT_FOLDER_ADMIN)" 3600s "${FM_RUNID}: Model Armor project floor per model-armor/floors.json (SD-41, X-RQB-08)" >/dev/null || return 1
  if [ "$(_fm_sv project_floor.vertex_ai)" = true ] || [ "$AGP_MODE" != apply ]; then
    _fm_plan "where project_floor.vertex_ai is true:"
    x gcloud beta services identity create --service=aiplatform.googleapis.com --project="$FM_PID" || return 1
    x gcloud projects add-iam-policy-binding "$FM_PID" --member="serviceAccount:service-${num}@gcp-sa-aiplatform.iam.gserviceaccount.com" --role=roles/modelarmor.user --condition=None >/dev/null || return 1
    x env "$(_fm_ma_ep)" gcloud model-armor floorsettings update --full-uri="$uri" --pi-and-jailbreak-filter-settings-enforcement="$PIE" --pi-and-jailbreak-filter-settings-confidence-level="$PI" \
      --malicious-uri-filter-settings-enforcement="$MU" --rai-settings-filters="$RAI" --enable-multi-language-detection --enable-floor-setting-enforcement=TRUE \
      --add-integrated-services=VERTEX_AI --vertex-ai-enforcement-type="$ET" --enable-vertex-ai-cloud-logging --billing-project="$FM_PID" || return 1
  fi
  if [ "$(_fm_sv project_floor.vertex_ai)" != true ] || [ "$AGP_MODE" != apply ]; then
    _fm_plan "where project_floor.vertex_ai is false (the filter half only):"
    x env "$(_fm_ma_ep)" gcloud model-armor floorsettings update --full-uri="$uri" --pi-and-jailbreak-filter-settings-enforcement="$PIE" --pi-and-jailbreak-filter-settings-confidence-level="$PI" \
      --malicious-uri-filter-settings-enforcement="$MU" --rai-settings-filters="$RAI" --enable-multi-language-detection --enable-floor-setting-enforcement=TRUE \
      --billing-project="$FM_PID" || return 1
  fi
  _fm_save "${FM_R}-FM-2.12a-floor-v1.json" env "$(_fm_ma_ep)" gcloud model-armor floorsettings describe --full-uri="$uri" --billing-project="$FM_PID" --format=json || return 1
  _fm_plan "VERIFY: enforce true; pi ENABLED at the spec's confidence or stricter; uri ENABLED; four RAI filters; with vertex_ai, AI_PLATFORM"
  _fm_plan "integrated, cloud logging on and exactly one modelarmor.user member (the aiplatform service agent); the checker's floor.* in FM-2.21"
  _fm_ck FM-2.12a DONE "floor $(_fm_sv project_floor.tier) vertex=$(_fm_sv project_floor.vertex_ai)"
}

step FM-2.13 AUTO "Monitoring baseline channels" --on-unmet skip --needs "FM_RUN_SPEC NOTIF_CH_PAGER_CORE CORE_PROJECT"
_fm_email_channel() {  # the display name of the spec's email channel
  [ "${FM_OK:-0}" = 1 ] || { printf '<spec.notification_channels[type=email].display_name>'; return 0; }
  _fm_list notification_channels | while read -r c; do [ "$(_fm_field "$c" type)" = email ] && _fm_field "$c" display_name && break; done
}
s_FM_2_13_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  nonempty r gcloud beta monitoring channels list --project="$FM_PID" --filter="displayName=\"$(_fm_email_channel)\"" --format="value(name)"
}
s_FM_2_13_apply() {
  _fm_apre || return 1
  local t
  x gcloud beta monitoring channels create --display-name="$(_fm_email_channel)" --type=email \
    --channel-labels=email_address="$(_fm_sv essential_contacts.0.email)" --description="Monitoring baseline email channel (07 §4.1), ${FM_RUNID}" --project="$FM_PID" || return 1
  if [ "$AGP_MODE" = apply ]; then
    t="$(r gcloud beta monitoring channels describe "$(v NOTIF_CH_PAGER_CORE)" --project="$(v CORE_PROJECT)" --format="value(type)")" || return 1
  else
    _fm_say "read: $(agp_quote gcloud beta monitoring channels describe "$(v NOTIF_CH_PAGER_CORE)" --project="$(v CORE_PROJECT)" --format="value(type)")"; t="<type>"
  fi
  case "$t" in
    pubsub|email) _fm_say "pager channel: create a $t channel in $FM_PID with the non-secret labels 15 recorded, and grant what 15's record says (yours: the labels are in 15's record)";;
    *) _fm_say "pager channel type '$t' carries a key: the paging administrator (IT security) creates it in $FM_PID in their own session and tells you only its display name; the spec gains it";;
  esac
  _fm_say "then: a test notification from Monitoring > Alerting > Edit notification channels; the owner group confirms receipt with a time"
  _fm_save "${FM_R}-FM-2.13-channels-v1.txt" gcloud beta monitoring channels list --project="$FM_PID" --format="table(displayName,type,verificationStatus)" || return 1
  _fm_ck FM-2.13 DONE "email channel; pager channel per 15"
}

step FM-2.14 AUTO "The to-triggers-<agent> sink, where the spec declares one" --witness --on-unmet skip \
  --needs "FM_RUN_SPEC LOGGING_PROJECT ENT_FOLDER_ADMIN CICD_PROJECT PLATFORM_REPO_DIR" --note "witness: the second human, approver of the ENT_FOLDER_ADMIN grant"
s_FM_2_14_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  [ "$(_fm_sv trigger_sink)" = null ] && return 0
  exists gcloud logging sinks describe "$(_fm_sv trigger_sink.name)" --project="$(v LOGGING_PROJECT)" --format="value(name)"
}
s_FM_2_14_apply() {
  _fm_apre || return 1
  local TS_NAME TS_TOPIC ff W
  if [ "$AGP_MODE" = apply ] && [ "$(_fm_sv trigger_sink)" = null ]; then _fm_ck FM-2.14 N/A "trigger_sink null"; return 0; fi
  TS_NAME="$(_fm_sv trigger_sink.name)"; TS_TOPIC="$(_fm_sv trigger_sink.topic)"; ff="${FM_R}-FM-2.14-filter.txt"
  _fm_sv trigger_sink.filter | xw "$ff" 600 >/dev/null || return 1
  if [ "$AGP_MODE" = apply ]; then
    [ "$(shasum -a 256 "$ff" | cut -d' ' -f1)" = "$(_fm_sv trigger_sink.filter_sha256)" ] || { _fm_say "STOP: filter hash differs from spec"; return 1; }
    exists gcloud pubsub topics describe "$TS_TOPIC" --project="$FM_PID" || x gcloud pubsub topics create "$TS_TOPIC" --project="$FM_PID" || return 1
  else
    x gcloud pubsub topics create "$TS_TOPIC" --project="$FM_PID"
  fi
  _fm_grant "$(v ENT_FOLDER_ADMIN)" 3600s "${FM_RUNID}: to-triggers sink (08 §3.2, row 39)" >/dev/null || return 1
  x gcloud logging sinks create "$TS_NAME" "pubsub.googleapis.com/projects/${FM_PID}/topics/${TS_TOPIC}" --log-filter="$(_fm_sv trigger_sink.filter)" \
    --description="Trigger stream of ${FM_RUNID} (08 §3.2, topology row 39)" --project="$(v LOGGING_PROJECT)" || return 1
  if [ "$AGP_MODE" = apply ]; then
    W="$(r gcloud logging sinks describe "$TS_NAME" --project="$(v LOGGING_PROJECT)" --format='value(writerIdentity)')" || return 1
  else W="<writerIdentity>"; fi
  x gcloud pubsub topics add-iam-policy-binding "$TS_TOPIC" --member="$W" --role=roles/pubsub.publisher --project="$FM_PID" >/dev/null || return 1
  _fm_save "${FM_R}-FM-2.14-trigger-sink-v1.txt" gcloud logging sinks describe "$TS_NAME" --project="$(v LOGGING_PROJECT)" --format="yaml(destination,filter,writerIdentity)" || return 1
  _fm_say "then: an admin event matching the family filter reaches a temporary subscription in $FM_PID (deleted after); the calling file records the sink variable"
  _fm_ck FM-2.14 DONE "trigger sink $TS_NAME"
}

_fm_confirm() {     # WORD: the operator types WORD after reading the diff above (apply only)
  local ans=""
  [ "$AGP_MODE" = apply ] || return 0
  printf '      Read the diff above. Type %s to apply it, anything else to stop: ' "$1" >&3
  read -r ans < /dev/tty 2>/dev/null || { _fm_say "no terminal: the diff must be read before the update; stop"; return 1; }
  [ "$ans" = "$1" ]
}

_fm_deny_rmw() {    # ENTRY_JSON add|remove STEP: FM-2.15's read-modify-write of one deny policy (FM-7.4 with remove)
  local DE="$1" mode="$2" st="$3" PID_ AP T ETAG
  PID_="$(_fm_field "$DE" policy_id)"; AP="$(_fm_field "$DE" attachment_point)"
  if [ "$AGP_MODE" != apply ]; then
    _fm_say "read: $(agp_quote gcloud iam policies get "$PID_" --attachment-point="$AP" --kind=denypolicies --format=json) > before; etag from it"
    _fm_say "the update body is {displayName, rules} with the entry's principal $( [ "$mode" = add ] && echo added to || echo removed from ) the named rules; the diff is shown and confirmed"
    x gcloud iam policies update "$PID_" --attachment-point="$AP" --kind=denypolicies --policy-file="<after.json>" --etag="<etag>"
    return 0
  fi
  T="$(mktemp "${TMPDIR:-/tmp}/agp-fm.XXXXXX")" || return 1
  r gcloud iam policies get "$PID_" --attachment-point="$AP" --kind=denypolicies --format=json > "$T.before" || { rm -f "$T" "$T.before"; return 1; }
  ETAG="$(_fm_py get "$T.before" etag)"
  _fm_py deny-edit "$T.before" "$DE" "$mode" > "$T.after" || { rm -f "$T" "$T.before" "$T.after"; return 1; }
  _fm_py deny-only "$T.before" > "$T.b"
  diff "$T.b" "$T.after" | sed 's/^/        /' >&3
  xw "${FM_R}-${st}-${PID_}-before-v1.json" 600 < "$T.before" >/dev/null
  if ! _fm_confirm UPDATE; then rm -f "$T" "$T.before" "$T.after" "$T.b"; return 1; fi
  x gcloud iam policies update "$PID_" --attachment-point="$AP" --kind=denypolicies --policy-file="$T.after" --etag="$ETAG"; local rc=$?
  rm -f "$T" "$T.before" "$T.after" "$T.b"
  return $rc
}

step FM-2.15 AUTO "Add the project's deny-policy entries" --witness --removes --on-unmet skip \
  --needs "FM_RUN_SPEC ENT_PLATFORM_POLICY CICD_PROJECT PLATFORM_REPO_DIR" --note "witness: the approver of ENT_PLATFORM_POLICY; replaces each deny policy with its read-modify-write"
s_FM_2_15_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  [ "$(_fm_py len "$FM_SPEC" deny_entries)" = 0 ] && return 0
  local DE
  while read -r DE; do
    [ -n "$DE" ] || continue
    r gcloud iam policies get "$(_fm_field "$DE" policy_id)" --attachment-point="$(_fm_field "$DE" attachment_point)" --kind=denypolicies --format=json 2>/dev/null \
      | _fm_py deny-has "$DE" >/dev/null || return 1
  done <<EOF
$(_fm_list deny_entries)
EOF
  return 0
}
s_FM_2_15_apply() {
  _fm_apre || return 1
  local DE
  if [ "$AGP_MODE" = apply ]; then
    [ "$(_fm_py len "$FM_SPEC" deny_entries)" = 0 ] && { _fm_ck FM-2.15 N/A "deny_entries empty"; return 0; }
    _fm_py get "$FM_SPEC" deny_entries | grep -q '<' && { _fm_say "STOP: a deny entry still holds a placeholder (FM-3.2 or FM-5.1 not merged)"; return 1; }
    case "$FM_MOD" in agent-project) _fm_after FM-3.2 || return 1;; improver-project) _fm_after FM-5.1 || return 1;; esac
  fi
  _fm_plan "first run only: if deny-agents-platform has no rule described 'R1 ', merge policies/deny/deny-agents-platform-agent-rules.json first (yours, reviewed)"
  _fm_grant "$(v ENT_PLATFORM_POLICY)" 3600s "${FM_RUNID}: deny and PAB entries (04 §3, §4)" >/dev/null || return 1
  while read -r DE; do
    [ -n "$DE" ] || continue
    _fm_deny_rmw "$DE" add FM-2.15 || return 1
  done <<EOF
$(_fm_list deny_entries)
EOF
  _fm_say "a deny change takes about 2 minutes, sometimes 7 or more, to take effect (04 §3)"
  _fm_ck FM-2.15 DONE "deny entries"
}

step FM-2.16 AUTO "Bind the project's PAB entry" --on-unmet skip --needs "FM_RUN_SPEC"
s_FM_2_16_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  local PB
  while read -r PB; do
    [ -n "$PB" ] || continue
    exists gcloud iam policy-bindings describe "$(_fm_field "$PB" binding_id)" --project="$FM_PID" --location=global --format="value(name)" || return 1
  done <<EOF
$(_fm_list pab_bindings)
EOF
  return 0
}
s_FM_2_16_apply() {
  _fm_apre || return 1
  local PB
  _fm_after FM-2.15 || return 1
  while read -r PB; do
    [ -n "$PB" ] || continue
    x gcloud iam policy-bindings create "$(_fm_field "$PB" binding_id)" --"$(_fm_field "$PB" parent_type)"="$(_fm_field "$PB" parent_id)" --location=global \
      --policy="$(_fm_field "$PB" policy)" --target-principal-set="$(_fm_field "$PB" principal_set)" --display-name="$(_fm_field "$PB" binding_id)" || return 1
    _fm_save "${FM_R}-FM-2.16-pab-v1.txt" gcloud iam policy-bindings describe "$(_fm_field "$PB" binding_id)" --project="$FM_PID" --location=global --format="yaml(policy,target)" || return 1
  done <<EOF
$(_fm_list pab_bindings)
EOF
  _fm_ck FM-2.16 DONE "PAB bindings"
}

step FM-2.17 AUTO "Instantiate the project's repair and deploy entitlements" --on-unmet skip \
  --needs "FM_RUN_SPEC ENT_PROJECT_REPAIR_TEMPLATE ENT_DEPLOY_CREDENTIAL_HOLDER_TEMPLATE CICD_PROJECT DOMAIN PLATFORM_REPO_DIR SA_1_ADMIN"
s_FM_2_17_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  local id
  for id in "ent-project-repair-$FM_AG" "ent-deploy-credential-holder-$FM_AG"; do
    exists gcloud pam entitlements describe "$id" --project="$FM_PID" --location=global --billing-project="$(v CICD_PROJECT)" --format="value(name)" || return 1
  done
  has_value "ENT_PROJECT_REPAIR_$(_fm_ag_var)" && has_value "ENT_DEPLOY_CREDENTIAL_HOLDER_$(_fm_ag_var)"
}
s_FM_2_17_apply() {
  _fm_apre || return 1
  local id f vals AGV
  AGV="$(_fm_ag_var)"
  for id in "ent-project-repair-$FM_AG" "ent-deploy-credential-holder-$FM_AG"; do
    f="$(v PLATFORM_REPO_DIR)/pam/entitlements/${id}.json"
    if [ "$AGP_MODE" = apply ]; then
      [ -s "$f" ] || { _fm_say "STOP: $f missing: render it with 12 PA-8.4's generator (never by editing JSON) with the approver the row names, merge it"; return 1; }
      vals="$(_fm_py ent "$f")"; printf '%s\n' "$vals" | sed 's/^/        /' >&3
      [ "$(printf '%s\n' "$vals" | sed -n 1p)" = "//cloudresourcemanager.googleapis.com/projects/$FM_PID" ] || { _fm_say "STOP: $id is not scoped to $FM_PID"; return 1; }
      printf '%s\n' "$vals" | sed -n 4p | grep -qiF "$(v SA_1_ADMIN)" && { _fm_say "STOP: $id lists the platform owner as approver"; return 1; }
      exists gcloud pam entitlements describe "$id" --project="$FM_PID" --location=global --billing-project="$(v CICD_PROJECT)" && continue
    else
      _fm_plan "rendered by 12 PA-8.4's generator: $f (resource the project, 04 §5.2 roles, 7200s repair / 1 h deploy, approver never the owner)"
    fi
    x gcloud pam entitlements create "$id" --entitlement-file="$f" --location=global --project="$FM_PID" --billing-project="$(v CICD_PROJECT)" || return 1
  done
  pset "ENT_PROJECT_REPAIR_${AGV}" "projects/${FM_PID}/locations/global/entitlements/ent-project-repair-${FM_AG}" || return 1
  pset "ENT_DEPLOY_CREDENTIAL_HOLDER_${AGV}" "projects/${FM_PID}/locations/global/entitlements/ent-deploy-credential-holder-${FM_AG}" || return 1
  _fm_save "${FM_R}-FM-2.17-entitlements-v1.txt" gcloud pam entitlements list --project="$FM_PID" --location=global --billing-project="$(v CICD_PROJECT)" --format="table(name,state)" || return 1
  _fm_plan "VERIFY also: 12's compare.py prints CATALOGUE ZERO DIFF with both ids; the approver is not in the requester groups (12 PA-8.4)"
  _fm_ck FM-2.17 DONE "entitlements"
}

step FM-2.18 HUMAN "Prove the repair entitlement with one grant" --witness --on-unmet skip --needs "FM_RUN_SPEC CICD_PROJECT"
s_FM_2_18_check() { _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0; _fm_ckd FM-2.18; }
s_FM_2_18_manual() {
  _fm_ctx
  echo "WHO: the platform owner requests; the repair entitlement's approver approves (for Eve, the second human). PER CALL."
  echo "DO: gcloud pam grants create --entitlement=$(_fm_ent_repair) --requested-duration=1800s"
  echo "  --justification=\"${FM_RUNID}: one-grant test before the creator Owner is removed (FM-2.18)\" --location=global --billing-project=$(v CICD_PROJECT) --project=$FM_PID"
  echo "  after approval and propagation (about 7 minutes): the testIamPermissions probe of setup/17 FM-2.18 (token in the header only),"
  echo "  then gcloud pam grants revoke <GRANT> --reason=\"one-grant test complete\" ...; then 12's tests T1 to T5 for this entitlement."
  echo "VERIFY: APPROVAL_AWAITED -> ACTIVE only after the named approver acted, REVOKED or ENDED afterwards; the probe echoed all five permissions."
  echo "RECORD: the grant list and probe as ${FM_R##*/}-FM-2.18-repair-test-v1; checkpoint FM-2.18@${FM_RUN} DONE <approver email>"
}

step FM-2.19 AUTO "Remove the creator's Owner" --removes --on-unmet skip --needs "FM_RUN_SPEC SA_1_ADMIN"
s_FM_2_19_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  [ "$FM_MOD" = tenant-app ] && { echo "      N/A for tenant-app (19 GE-5 removes standing human roles)"; return 0; }
  local h; h="$(_fm_iam_humans "$FM_PID")"
  [ -z "$h" ]
}
s_FM_2_19_apply() {
  _fm_apre || return 1
  local h
  _fm_after FM-2.18 || return 1
  _fm_save "${FM_R}-FM-2.19-iam-before-v1.json" gcloud projects get-iam-policy "$FM_PID" --format=json || return 1
  x gcloud projects remove-iam-policy-binding "$FM_PID" --member="user:$(v SA_1_ADMIN)" --role=roles/owner --condition=None >/dev/null || {
    _fm_say "if gcloud refused to remove the last Owner: keep it, record a DEV row with the refusal text (owner platform owner, closed in 42), stop"; return 1; }
  if [ "$AGP_MODE" = apply ]; then
    h="$(_fm_iam_humans "$FM_PID")"
    [ -z "$h" ] || { _fm_say "FAIL user, group or domain members remain:"; printf '%s\n' "$h" | sed 's/^/        /' >&3; return 1; }
    _fm_probe "$FM_PID" resourcemanager.projects.setIamPolicy run.services.update | xw "${FM_R}-FM-2.19-probe-v1.json" 600 >/dev/null
  else
    _fm_say "$ api POST https://cloudresourcemanager.googleapis.com/v3/projects/${FM_PID}:testIamPermissions (setIamPolicy, run.services.update)"
  fi
  _fm_say "the run grant (folder projectIamAdmin) still shows setIamPolicy: FM-2.22 runs the probe again after the grant ends"
  _fm_ck FM-2.19 DONE "owner removed"
}

step FM-2.20 AUTO-READ "Sweep the project for anything the spec does not name" --on-unmet skip --needs "FM_RUN_SPEC"
s_FM_2_20_check() { _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0; _fm_ckd FM-2.20; }
s_FM_2_20_apply() {
  _fm_apre || return 1
  _fm_save "${FM_R}-FM-2.20-assets-v1.txt" gcloud asset search-all-resources --scope="projects/${FM_PID}" --format="table(assetType,name)" \
    || _fm_say "the asset search was refused: rely on the checker's live output alone and record the gap"
  _fm_save "${FM_R}-FM-2.20-iam-v1.txt" gcloud asset search-all-iam-policies --scope="projects/${FM_PID}" --format="table(resource,policy.bindings.role,policy.bindings.members)" \
    || _fm_say "the IAM search was refused: record the gap"
  _fm_say "REVIEW: every asset is in the spec or a Google default (_Required, _Default, service agents); anything else is removed or added to the spec before FM-2.21"
  _fm_ck FM-2.20 DONE "sweep read"
}

step FM-2.21 AUTO-READ "Run the zero-diff checker" --on-unmet skip --needs "FM_RUN_SPEC PLATFORM_REPO_DIR EVIDENCE_REGISTER"
s_FM_2_21_check() { _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0; _fm_ckd FM-2.21; }
s_FM_2_21_apply() {
  _fm_apre || return 1
  local rep rc
  rep="${FM_R}-FM-2.21-live-v1.json"
  _fm_checker live "$FM_SPEC" "$rep"; rc=$?
  [ "$AGP_MODE" = apply ] || { _fm_ck FM-2.21 DONE "zero diff"; return 0; }
  [ $rc -eq 2 ] && return 1
  if [ $rc -ne 0 ]; then
    _fm_py report "$rep" | sed 's/^/        /' >&3
    _fm_py report "$rep" >/dev/null; rc=$?
    case $rc in
      3) _fm_say "only PENDING checks, each with an owner and a re-run file: re-run with --accept-pending; each goes into README's re-run index"
         _fm_checker live "$FM_SPEC" "$rep" --accept-pending || return 1;;
      *) _fm_say "FAIL: repair (the project's repair entitlement in-project, ENT_PLATFORM_POLICY for deny and PAB) and re-run; never recorded as a module equivalent"; return 1;;
    esac
  fi
  ev "FM-2.21@${FM_RUN}" zero-diff E-05 5.2.4 "build-log:records/${rep##*/}" "$rep" || return 1
  _fm_ck FM-2.21 DONE "zero diff"
}

_fm_bd_open() {     # ID: the register's first table holds the row
  local f; f="$(v DEVIATION_REGISTER)"
  [ -f "$f" ] && awk -F' *[|] *' -v id="$1" '$2 == id && NF == 15 {f = 1} END {exit f ? 0 : 1}' "$f"
}
_fm_bd_closed() {   # ID: the Closures table holds the line
  local f; f="$(v DEVIATION_REGISTER)"
  [ -f "$f" ] && awk -F' *[|] *' -v id="$1" '$2 == id && NF == 6 {f = 1} END {exit f ? 0 : 1}' "$f"
}

step FM-2.22 AUTO "Write the deviation row, end the grant and close the run" --witness --on-unmet skip \
  --needs "FM_RUN_SPEC FM_BD_ID DEVIATION_REGISTER BUILD_LOG_DIR CICD_PROJECT" --note "the run's approver reads the row and initials the build-log line"
s_FM_2_22_check() { _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0; _fm_bd_open "$(v FM_BD_ID)" && _fm_ckd FM-2.22; }
s_FM_2_22_apply() {
  _fm_apre || return 1
  local GRANT gf row sv
  _fm_after FM-2.21 || return 1
  gf="$(ls -1 "$(v BUILD_LOG_DIR)"/records/*-FM-"${FM_RUN}"-FM-2.2-grant-v1.txt 2>/dev/null | tail -n 1)"
  GRANT="$( [ -n "$gf" ] && awk '/^GRANT /{g=$2} END{print g}' "$gf")"
  if [ -z "$GRANT" ] && [ "$AGP_MODE" = apply ] && has_value "$(_fm_ent_var)"; then
    GRANT="$(r gcloud pam grants list --entitlement="$(_penv_get "$(_fm_ent_var)")" --location=global --billing-project="$(v CICD_PROJECT)" \
      --filter="state=ACTIVE" --format="value(name)" 2>/dev/null | head -n 1)"
  fi
  if [ -z "$GRANT" ]; then
    [ "$AGP_MODE" = apply ] && { _fm_say "STOP: no run grant in FM-2.2's record and none ACTIVE: type the grant name into the row by hand (setup/17 FM-2.22)"; return 1; }
    GRANT="<run-grant-from-FM-2.2>"
  fi
  if [ "$AGP_MODE" = apply ] && [ "$(r gcloud pam grants describe "$GRANT" --billing-project="$(v CICD_PROJECT)" --format='value(state)' 2>/dev/null)" != ACTIVE ]; then
    _fm_say "grant already ended"
  else
    x gcloud pam grants revoke "$GRANT" --reason="${FM_RUNID} complete" --location=global --billing-project="$(v CICD_PROJECT)" || return 1
  fi
  row="$(printf '| %s | %s | %s via 17 FM-2 | MOD | %s (hand, SD-01) | folder %s, project %s | %s @ %s | parent, labels, inherited tags, %s services, _Default->default-europe-west1, _Trace %s, budget %s, contacts, %s service accounts, channels, trigger sink %s, %s, deny %s, PAB %s, entitlements %s | %s | %s | %s | terraform import + empty plan (17 FM-11), expiry Tier W gate | open |' \
    "$(v FM_BD_ID)" "$(date -u +%F)" "$(_fm_sv calling_file_step)" "$FM_MOD" "$FM_PFLD" "$FM_PID" "$(_fm_sv register_row)" "$(_fm_sv register_commit)" \
    "$( [ "$FM_OK" = 1 ] && _fm_py len "$FM_SPEC" services || echo '<n>')" "$(_fm_sv log_routing.trace_bucket)" "$(_fm_sv budget.amount)" \
    "$( [ "$FM_OK" = 1 ] && _fm_py len "$FM_SPEC" service_accounts || echo '<n>')" \
    "$( [ "$(_fm_sv trigger_sink)" = null ] && echo none || _fm_sv trigger_sink.name)" \
    "$( if [ "$(_fm_sv project_floor.applies)" = true ]; then printf 'floor %s vertex=%s' "$(_fm_sv project_floor.tier)" "$(_fm_sv project_floor.vertex_ai)"; else printf 'floor n/a: %s' "$(_fm_sv project_floor.reason)"; fi)" \
    "$(_fm_join deny_entries policy_id unique)" "$(_fm_join pab_bindings binding_id)" "$(_fm_join entitlements)" \
    "build-log:records/${FM_R##*/}-FM-2.21-live-v1.json" "$(date -u +%F) (FM-2.19)" "PAM grant ${GRANT}" | tr -d '\t')"
  if [ "$AGP_MODE" = apply ]; then
    case "$row" in *'<'*'>'*) _fm_say "STOP: the row still holds a placeholder: $row"; return 1;; esac
    x bd_insert "$row" || return 1
    _fm_probe "$FM_PID" resourcemanager.projects.setIamPolicy run.services.update | sed 's/^/        /' >&3
    _fm_say "the post-grant probe must echo neither permission"
  else
    _fm_say "$ bd_insert '$row'"
  fi
  x checkpoint "FM-2.22@${FM_RUN}" DONE - "build-log:registers/bootstrap-deviation-register.md" "${FM_RUNID} zero diff"
}

# ---------------------------------------------------------------- 3. FM-AGENT (per call)

step FM-3.1 AUTO-READ "Refuse a second P-SA production row, and a production run without both approvers" --on-unmet skip \
  --needs "FM_RUN_SPEC REGISTER_PATH SECURITY_REVIEWER_EMAIL SECOND_HUMAN_EMAIL ENT_FACTORY_SINGLETON_PSA_PROD CICD_PROJECT PLATFORM_REPO_DIR SA_1_ADMIN" \
  --note "P-SA runs only, before FM-2.2; the security reviewer and the second human confirm they are the named approvers"
s_FM_3_1_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  [ "$FM_TIER" = P-SA ] || { echo "      N/A: not a P-SA run"; return 0; }
  _fm_ckd FM-3.1
}
s_FM_3_1_apply() {
  _fm_apre || return 1
  local py rows appr f bad=0
  py="${REGISTER_VENV_PYTHON:-$HOME/platform/venv-register/bin/python}"; f="${FM_R}-FM-3.1-singleton-v1.txt"
  if [ "$AGP_MODE" != apply ]; then
    _fm_say "read: $py - $(v PLATFORM_REPO_DIR)/$(v REGISTER_PATH) < setup/17 FM-3.1's PyYAML reader (prod, non-retired P-SA rows)"
    _fm_say "read: $(agp_quote gcloud pam entitlements describe "$(v ENT_FACTORY_SINGLETON_PSA_PROD)" --location=global --billing-project="$(v CICD_PROJECT)" --format=json)"
    _fm_ck FM-3.1 DONE "singleton"; return 0
  fi
  rows="$(r "$py" - "$(v PLATFORM_REPO_DIR)/$(v REGISTER_PATH)" < "$AGP_HOME/assets/fm-3.1-psa-rows.py")" || return 1
  appr="$(r gcloud pam entitlements describe "$(v ENT_FACTORY_SINGLETON_PSA_PROD)" --location=global --billing-project="$(v CICD_PROJECT)" --format=json | _fm_py approvers)" || return 1
  printf '%s\n--- approvers:\n%s\n' "$rows" "$appr" | xw "$f" 600 >/dev/null
  printf '%s\n%s\n' "$rows" "$appr" | sed 's/^/        /' >&3
  [ "$(printf '%s\n' "$rows" | grep -c .)" = 1 ] || { _fm_say "FAIL: not exactly one prod P-SA row (PSA1, SD-02)"; bad=1; }
  printf '%s\n' "$appr" | grep -qiF "$(v SECURITY_REVIEWER_EMAIL)" || _fm_say "REVIEW: SECURITY_REVIEWER_EMAIL is not listed by name (a group whose only members are the two, as 12 recorded, is accepted)"
  printf '%s\n' "$appr" | grep -qiF "$(v SA_1_ADMIN)" && { _fm_say "FAIL: the platform owner is an approver"; bad=1; }
  [ $bad = 0 ] || return 1
  _fm_ck FM-3.1 DONE "one P-SA prod row; two named approvers"
}

step FM-3.2 AUTO "Write the deny entries into the spec" --on-unmet skip --needs "FM_RUN_SPEC ORG_ID FLD_AGENTIC_PLATFORM FLD_PLATFORM_CORE"
s_FM_3_2_check() {
  _fm_mc agent-project; [ "$FM_MC" = go ] || return "$FM_MC"
  [ "$(_fm_py len "$FM_SPEC" deny_entries)" = 3 ] && ! _fm_py get "$FM_SPEC" deny_entries | grep -q '<'
}
_fm_mc() {          # MODULE...: FM_MC=go to check this run, 0 (N/A) for another module, or _fm_pre's 2 or 3
  _fm_pre; local rc=$?
  if [ $rc != 0 ]; then FM_MC=$rc; elif [ "$FM_OK" != 1 ] || _fm_skip_unless "$@"; then FM_MC=0; else FM_MC=go; fi
}
s_FM_3_2_apply() {
  _fm_apre || return 1
  local num agp tier
  _fm_after FM-2.4 || return 1
  if [ "$AGP_MODE" = apply ]; then
    num="$(r gcloud projects describe "$FM_PID" --format='value(projectNumber)')"
    case "$num" in ''|*[!0-9]*) _fm_say "STOP: no project number; FM-2.3 and FM-2.4 must have run"; return 1;; esac
  else num="<number>"; fi
  tier="$FM_TIER"
  case "$(_penv_get DENY_AGENT_FORM 2>/dev/null)" in
    set) agp="principalSet://agents.global.org-$(v ORG_ID).system.id.goog/attribute.platformContainer/aiplatform/projects/${num}";;
    principal) agp="principal://agents.global.org-$(v ORG_ID).system.id.goog/resources/aiplatform/projects/${num}";;
    *) if [ "$AGP_MODE" = apply ] && [ "$tier" != R ]; then _fm_say "STOP: DENY_AGENT_FORM unset (18 KS-3.2); a Tier W+ run does not reach FM-2.15 without it"; return 1; fi
       agp="principalSet://agents.global.org-$(v ORG_ID).system.id.goog/attribute.platformContainer/aiplatform/projects/${num}";;
  esac
  if [ "$AGP_MODE" = apply ]; then
    _fm_py agent-deny "$FM_SPEC" "cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)" "cloudresourcemanager.googleapis.com/folders/$(v FLD_PLATFORM_CORE)" \
      "$agp" "$num" "$FM_AG" "$FM_PID" "$tier" | xw "$FM_SPEC" 644 || return 1
    _fm_list deny_entries | while read -r e; do printf '        %s rules=%s exceptions=%s\n' "$(_fm_field "$e" policy_id)" "$(_fm_field "$e" rules)" "$(_fm_field "$e" exceptions)"; done >&3
  else
    _fm_say "writes deny_entries into the spec: deny-agents-platform R1-R5,R3b for the project's service-account set (exceptions R1 actions@, R3b and R4"
    _fm_say "deployer@; none on Tier R), the same rules for $agp, and deny-core-agents CA for it; xw <spec>"
  fi
  _fm_say "REVIEW: Wall-E's deployer lives in CICD_PROJECT (SD-34): its R3b and R4 exceptions name walle-deployer@ from 31's list, and R1 adds"
  _fm_say "walle-actions-super@; edit those by hand. Then inputs must PASS deny_entry.0.*; commit as the second spec commit, merge before FM-2.15;"
  _fm_say "then: checkpoint FM-3.2@<run> DONE"
}

step FM-3.3 AUTO "Binary Authorization verifier grants (Tier W and above)" --on-unmet skip --needs "FM_RUN_SPEC CICD_PROJECT BINAUTHZ_ATTESTOR" \
  --note "under ENT_PROJECT_REPAIR_CORE (the attestors are in CICD_PROJECT)"
s_FM_3_3_check() {
  _fm_mc agent-project; [ "$FM_MC" = go ] || return "$FM_MC"
  [ "$FM_TIER" = R ] && { echo "      N/A for Tier R"; return 0; }
  local num A
  num="$(r gcloud projects describe "$FM_PID" --format='value(projectNumber)' 2>/dev/null)" || return "$(_fm_nf $?)"
  for A in $(r gcloud container binauthz attestors list --project="$(v CICD_PROJECT)" --format="value(name)" 2>/dev/null); do
    has_binding "serviceAccount:service-${num}@gcp-sa-binaryauthorization.iam.gserviceaccount.com" roles/binaryauthorization.attestorsVerifier \
      gcloud container binauthz attestors get-iam-policy "$A" --project="$(v CICD_PROJECT)" || return 1
  done
  return 0
}
s_FM_3_3_apply() {
  _fm_apre || return 1
  local num A list
  _fm_after FM-2.7 || return 1
  if [ "$AGP_MODE" = apply ]; then
    num="$(r gcloud projects describe "$FM_PID" --format='value(projectNumber)')" || return 1
    list="$(r gcloud container binauthz attestors list --project="$(v CICD_PROJECT)" --format="value(name)")" || return 1
  else num="<number>"; list="<each-attestor-in-CICD_PROJECT>"; fi
  _fm_plan "requires an active ENT_PROJECT_REPAIR_CORE grant; if the member is unknown: gcloud beta services identity create --service=binaryauthorization.googleapis.com --project=$FM_PID"
  for A in $list; do
    x gcloud container binauthz attestors add-iam-policy-binding "$A" --member="serviceAccount:service-${num}@gcp-sa-binaryauthorization.iam.gserviceaccount.com" \
      --role=roles/binaryauthorization.attestorsVerifier --project="$(v CICD_PROJECT)" >/dev/null || return 1
  done
  _fm_say "the note-level roles/containeranalysis.notes.occurrences.viewer of row 42 is granted on each attestor's note the same way (yours)"
  _fm_ck FM-3.3 DONE "binauthz verifier"
}

step FM-3.4 AUTO-READ "Record the agent-project items that belong to other files" --on-unmet skip --needs "FM_RUN_SPEC"
s_FM_3_4_check() { _fm_mc agent-project; [ "$FM_MC" = go ] || return "$FM_MC"; _fm_ckd FM-3.4; }
s_FM_3_4_apply() {
  _fm_apre || return 1
  if [ "$AGP_MODE" = apply ]; then
    _fm_py elsewhere "$FM_SPEC" | sed 's/^/        /' >&3
    _fm_py elsewhere "$FM_SPEC" >/dev/null || { _fm_say "FAIL: a made_elsewhere item lacks a file or step, or reads *tbd*"; return 1; }
  else _fm_say "read: made_elsewhere[] item, file, step (none *tbd*)"; fi
  _fm_say "REVIEW: every 02 §3.3 agent-project item this run did not make is listed (engine, gateways, iap.egressor, action service, secrets,"
  _fm_say "Firestore, <agent>_audit, content-log bucket and view, topics, absence policies, Model Armor template, registry card, credential bindings)"
  _fm_ck FM-3.4 DONE "made_elsewhere"
}

# ---------------------------------------------------------------- 4. FM-VERIFIER (per call)

step FM-4.1 AUTO-READ "Confirm the approver is the second human, not the platform owner" --witness --on-unmet skip \
  --needs "FM_RUN_SPEC ENT_FACTORY_SINGLETON_CTL_PROD ENT_FACTORY_SINGLETON_CTL_NONPROD SECOND_HUMAN_EMAIL SA_1_ADMIN OWNER_DAILY_ACCOUNT CICD_PROJECT" \
  --note "witness: the second human confirms in person or in writing, before FM-2.2"
s_FM_4_1_check() { _fm_mc verifier-project; [ "$FM_MC" = go ] || return "$FM_MC"; _fm_ckd FM-4.1; }
s_FM_4_1_apply() {
  _fm_apre || return 1
  local e appr bad=0
  if [ "$FM_ENV" = nonprod ]; then e="$(v ENT_FACTORY_SINGLETON_CTL_NONPROD)"; else e="$(v ENT_FACTORY_SINGLETON_CTL_PROD)"; fi
  if [ "$AGP_MODE" != apply ]; then _fm_say "read: $(agp_quote gcloud pam entitlements describe "$e" --location=global --billing-project="$(v CICD_PROJECT)" --format=json) (approvers)"; _fm_ck FM-4.1 DONE "approver"; return 0; fi
  appr="$(r gcloud pam entitlements describe "$e" --location=global --billing-project="$(v CICD_PROJECT)" --format=json | _fm_py approvers)" || return 1
  printf '%s\n' "$appr" | xw "${FM_R}-FM-4.1-approver-v1.txt" 600 >/dev/null; printf '%s\n' "$appr" | sed 's/^/        /' >&3
  printf '%s\n' "$appr" | grep -qiF "$(v SA_1_ADMIN)" && { _fm_say "FAIL: sa-1-admin@ is an approver (SD-12 item 2)"; bad=1; }
  printf '%s\n' "$appr" | grep -qiF "$(v OWNER_DAILY_ACCOUNT)" && { _fm_say "FAIL: the owner's daily account is an approver (SD-12 item 2)"; bad=1; }
  printf '%s\n' "$appr" | grep -qiF "$(v SECOND_HUMAN_EMAIL)" || _fm_say "REVIEW: SECOND_HUMAN_EMAIL is not listed by name (eve-owners@, owned by the second human as 06 recorded, is accepted)"
  [ $bad = 0 ] || { _fm_say "stop; 12 is corrected by the second human's review"; return 1; }
  _fm_ck FM-4.1 DONE "approver is the second human"
}

step FM-4.2 AUTO "Deny aiplatform on the control-path project" --witness --removes --on-unmet skip \
  --needs "FM_RUN_SPEC ENT_PLATFORM_POLICY CICD_PROJECT PLATFORM_REPO_DIR" --note "witness: the approver of ENT_PLATFORM_POLICY; set-policy writes the project's whole policy"
s_FM_4_2_check() {
  _fm_mc verifier-project; [ "$FM_MC" = go ] || return "$FM_MC"
  r gcloud org-policies describe gcp.restrictServiceUsage --project="$FM_PID" --format=json 2>/dev/null | _fm_py denied-values | grep -qx aiplatform.googleapis.com
}
s_FM_4_2_apply() {
  _fm_apre || return 1
  local pf
  _fm_after FM-2.7 || return 1
  pf="${FM_R}-FM-4.2-policy.yaml"
  sed "s/\${P_ID}/${FM_PID}/" "$AGP_HOME/assets/fm-4.2-policy.yaml" | xw "$pf" 600 || return 1
  _fm_save "${FM_R}-FM-4.2-before-v1.yaml" gcloud org-policies describe gcp.restrictServiceUsage --project="$FM_PID" --effective --format=yaml || return 1
  _fm_grant "$(v ENT_PLATFORM_POLICY)" 3600s "${FM_RUNID}: project-level aiplatform denial and deny-eve-project-foreign (FM-4.2, FM-4.3)" >/dev/null || return 1
  # the scope is the policy file's name: projects/<P_ID>/policies/gcp.restrictServiceUsage (set-policy takes no scope flag)
  x gcloud org-policies set-policy "$pf" || return 1
  _fm_say "VERIFY: gcloud services enable aiplatform.googleapis.com --project=$FM_PID must be REFUSED naming the constraint (a refusal is the pass)"
  if [ "$AGP_MODE" = apply ]; then
    if x gcloud services enable aiplatform.googleapis.com --project="$FM_PID"; then
      _fm_say "FAIL: aiplatform was enabled on the control-path project: severity 1, disable it under a grant and page platform-security@"; return 1
    fi
    _fm_say "refused, as required"
  fi
  _fm_ck FM-4.2 DONE "aiplatform denied"
}

step FM-4.3 AUTO "Attach deny-eve-project-foreign from its committed file" --witness --on-unmet skip \
  --needs "FM_RUN_SPEC PLATFORM_REPO_DIR" --note "witness: the approver of the same ENT_PLATFORM_POLICY grant; the file is merged with the second human's review"
s_FM_4_3_check() {
  _fm_mc verifier-project; [ "$FM_MC" = go ] || return "$FM_MC"
  exists gcloud iam policies get deny-eve-project-foreign --attachment-point="cloudresourcemanager.googleapis.com/projects/${FM_PID}" --kind=denypolicies --format="value(name)"
}
s_FM_4_3_apply() {
  _fm_apre || return 1
  local F
  _fm_after FM-4.2 || return 1
  F="$(v PLATFORM_REPO_DIR)/$(_fm_sv project_deny_policies.0.file)"
  if [ "$AGP_MODE" = apply ]; then
    [ -s "$F" ] || { _fm_say "STOP: deny-eve-project-foreign file not merged (23 commits it under topology decision 48)"; return 1; }
    git -C "$(v PLATFORM_REPO_DIR)" log --oneline -1 origin/main -- "${F#"$(v PLATFORM_REPO_DIR)"/}" 2>/dev/null | sed 's/^/        /' >&3
  fi
  x gcloud iam policies create deny-eve-project-foreign --attachment-point="cloudresourcemanager.googleapis.com/projects/${FM_PID}" --kind=denypolicies --policy-file="$F" || return 1
  _fm_save "${FM_R}-FM-4.3-deny-eve-v1.json" gcloud iam policies get deny-eve-project-foreign --attachment-point="cloudresourcemanager.googleapis.com/projects/${FM_PID}" --kind=denypolicies --format=json || return 1
  _fm_plan "VERIFY: its rule count equals the committed file's; the checker's project_deny.* passes in FM-2.21"
  _fm_ck FM-4.3 DONE "deny-eve-project-foreign"
}

step FM-4.4 HUMAN "Re-scope ent-witness-export-repair to EVE_PROJECT (12 PA-8.3)" --witness --on-unmet skip \
  --needs "FM_RUN_SPEC EVE_PROJECT FLD_CONTROLLERS_PROD CICD_PROJECT BUILD_LOG_DIR"
s_FM_4_4_check() {
  _fm_mc verifier-project; [ "$FM_MC" = go ] || return "$FM_MC"
  [ "$FM_ENV" = nonprod ] && { echo "      N/A for the twin"; return 0; }
  _fm_ckd FM-4.4
}
s_FM_4_4_manual() {
  echo "WHO: the platform owner; the second human approves the ent-folder-admin grant PA-8.3 uses and the one-grant test. PER CALL (EVE_PROJECT only)."
  echo "DO: run 12 PA-8.3 as written: catalogue.py row to project scope, merge with the second human's review, create the project-scoped"
  echo "  entitlement, test it, delete the folder-scoped one, close its BD-12 row. Reads:"
  echo "  awk -F'\\t' '\$2==\"PA-4.9\"' \"\$BUILD_LOG_DIR/rerun-index.tsv\""
  echo "  gcloud pam entitlements list --project=$(v EVE_PROJECT) --location=global --billing-project=$(v CICD_PROJECT) --format=\"value(name)\" | grep ent-witness-export-repair"
  echo "  gcloud pam entitlements list --folder=$(v FLD_CONTROLLERS_PROD) --location=global --billing-project=$(v CICD_PROJECT) --format=\"value(name)\" | grep ent-witness-export-repair || echo \"folder-scoped copy gone\""
  echo "VERIFY: the project list prints it; the folder list prints 'folder-scoped copy gone'; ENT_WITNESS_EXPORT_REPAIR names the project resource;"
  echo "  the re-run line is closed with PA-8.3's id; the spec's entitlements gain ent-witness-export-repair."
  echo "RECORD: checkpoint FM-4.4@<run> DONE <second human's email>"
}

step FM-4.5 AUTO-READ "The verifier module's PAB binding: recorded as not applicable to EVE_PROJECT" --on-unmet skip --needs "FM_RUN_SPEC"
s_FM_4_5_check() { _fm_mc verifier-project; [ "$FM_MC" = go ] || return "$FM_MC"; _fm_ckd FM-4.5; }
s_FM_4_5_apply() {
  _fm_apre || return 1
  if [ "$AGP_MODE" = apply ]; then
    [ "$(_fm_py len "$FM_SPEC" pab_bindings)" = 0 ] || { _fm_say "FAIL: pab_bindings is not empty"; return 1; }
    _fm_py elsewhere-has "$FM_SPEC" "PAB for the reporting-path project" || { _fm_say "FAIL: no made_elsewhere line for the EVE_ADVISOR_PROJECT PAB (file 41, Eve owner)"; return 1; }
  else _fm_say "read: pab_bindings length 0; a made_elsewhere line 'PAB for the reporting-path project EVE_ADVISOR_PROJECT ... file 41'"; fi
  _fm_ck FM-4.5 DONE "PAB not applicable"
}

# ---------------------------------------------------------------- 5. FM-IMPROVER (per call)

step FM-5.1 AUTO "Write Mo's deny entries into the spec" --on-unmet skip --needs "FM_RUN_SPEC FLD_AGENTIC_PLATFORM FLD_IMPROVERS"
s_FM_5_1_check() {
  _fm_mc improver-project; [ "$FM_MC" = go ] || return "$FM_MC"
  [ "$(_fm_py len "$FM_SPEC" deny_entries)" = 1 ] && ! _fm_py get "$FM_SPEC" deny_entries | grep -q '<' && _fm_py elsewhere-has "$FM_SPEC" "deny-improvers and deny-core-agents"
}
s_FM_5_1_apply() {
  _fm_apre || return 1
  local num set ap n
  _fm_after FM-2.4 || return 1
  ap="cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)"
  set="principalSet://cloudresourcemanager.googleapis.com/folders/$(v FLD_IMPROVERS)/type/ServiceAccount"
  if [ "$AGP_MODE" = apply ]; then
    num="$(r gcloud projects describe "$FM_PID" --format='value(projectNumber)')"
    case "$num" in ''|*[!0-9]*) _fm_say "STOP: no project number; FM-2.3 and FM-2.4 must have run"; return 1;; esac
    _fm_py mo-deny "$FM_SPEC" "$ap" "$num" | xw "$FM_SPEC" 644 || return 1
    n="$(r gcloud iam policies get deny-improvers --attachment-point="$ap" --kind=denypolicies --format=json | _fm_py set-count "$set")" || return 1
    _fm_say "deny-improvers carries the folder set in $n rules (5 expected)"
    [ "$n" = 5 ] || { _fm_say "FAIL: deny-improvers does not name $set in each of its five rules (13 OP-2.5)"; return 1; }
  else
    _fm_say "writes deny_entries = [deny-agents-platform R1-R5,R3b for projects/<number>/type/ServiceAccount] and a made_elsewhere line (13 OP-7.5, OP-7.6)"
    _fm_say "read: $(agp_quote gcloud iam policies get deny-improvers --attachment-point="$ap" --kind=denypolicies --format=json) (the folder set in 5 rules)"
  fi
  _fm_say "then: inputs PASS; commit as the second spec commit, merge before FM-2.15; checkpoint FM-5.1@<run> DONE"
}

step FM-5.2 AUTO-READ "The improver module's PAB binding: deferred to S4" --on-unmet skip --needs "FM_RUN_SPEC"
s_FM_5_2_check() { _fm_mc improver-project; [ "$FM_MC" = go ] || return "$FM_MC"; _fm_ckd FM-5.2; }
s_FM_5_2_apply() {
  _fm_apre || return 1
  if [ "$AGP_MODE" = apply ]; then
    [ "$(_fm_py len "$FM_SPEC" pab_bindings)" = 0 ] || { _fm_say "FAIL: pab_bindings is not empty"; return 1; }
    _fm_py elsewhere-has "$FM_SPEC" "pab-agents" || { _fm_say "FAIL: no made_elsewhere line for the pab-agents binding (file 40 Mo-11, Mo owner, using FM-2.16)"; return 1; }
  else _fm_say "read: pab_bindings length 0; a made_elsewhere line for the pab-agents binding before the first model call (40 Mo-11)"; fi
  _fm_say "REVIEW: 40's scope lists it (README re-run index row)"
  _fm_ck FM-5.2 DONE "PAB deferred to S4"
}

# ---------------------------------------------------------------- 6. FM-TENANT-APP (per call, from 19)

step FM-6.1 HUMAN "Write the tenant-app spec from the read-only inventory" --on-unmet skip \
  --needs "FM_RUN_SPEC GEMINI_PROJECT GE_INVENTORY_DIR FLD_GEMINI_ENTERPRISE"
s_FM_6_1_check() { _fm_mc tenant-app; [ "$FM_MC" = go ] || return "$FM_MC"; _fm_ckd FM-6.1; }
s_FM_6_1_manual() {
  echo "WHO: the platform owner; two approvals merge it. WHERE: PLATFORM_REPO_DIR; GE_INVENTORY_DIR (05). Called from 19 GE-2."
  echo "DO: copy the template to factory/runs/gemini-prod.json as setup/17 FM-6.1 says (module tenant-app, create false, GEMINI_PROJECT,"
  echo "  FLD_GEMINI_ENTERPRISE, tier ge, factory_run dev-19-tenant-gemini-prod, services from the inventory with pending lines, budget 0"
  echo "  with its reason and pending line, allowed_human_members from the inventory, lien false, ent-project-repair-tenant-app,"
  echo "  project_floor applies false with the 19 GE-7 made_elsewhere line, whose item names the floor). made_elsewhere and pending"
  echo "  members are objects, never strings: pending {check, reason, owner, rerun_in} for services.subset_of_folder_allowlist and budget,"
  echo "  as the page gives them. Reads: ls -1 $(v GE_INVENTORY_DIR);"
  echo "  gcloud projects describe $(v GEMINI_PROJECT) --format=\"yaml(parent,labels)\""
  echo "VERIFY: inputs passes with --accept-pending except the listed pending checks; merged with two approvals."
  echo "RECORD: the report and merge as <R>-FM-6.1-tenant-spec-v1; checkpoint FM-6.1@gemini-prod DONE"
}

step FM-6.2 HUMAN "Instantiate ENT_PROJECT_REPAIR_TENANT_APP before any standing role is touched" --witness --on-unmet skip \
  --needs "FM_RUN_SPEC GEMINI_PROJECT CICD_PROJECT" --sets "ENT_PROJECT_REPAIR_TENANT_APP"
s_FM_6_2_check() { _fm_mc tenant-app; [ "$FM_MC" = go ] || return "$FM_MC"; _fm_ckd FM-6.2 && has_value ENT_PROJECT_REPAIR_TENANT_APP; }
s_FM_6_2_manual() {
  echo "WHO: the platform owner; the approver 12's template names for a Tier C project."
  echo "DO: FM-2.17 and FM-2.18 with resource GEMINI_PROJECT, requesters platform-owners@ and ge-admins@, and only the repair entitlement"
  echo "  (no deploy entitlement): gcloud pam entitlements create ent-project-repair-tenant-app --entitlement-file=<rendered by 12 PA-8.4>"
  echo "  --location=global --project=$(v GEMINI_PROJECT) --billing-project=$(v CICD_PROJECT); then the one-grant test of FM-2.18."
  echo "RECORD: penv_set ENT_PROJECT_REPAIR_TENANT_APP projects/$(v GEMINI_PROJECT)/locations/global/entitlements/ent-project-repair-tenant-app;"
  echo "  checkpoint FM-6.2@gemini-prod DONE <approver email>. It must exist before 19's GE-5 removes standing project roles."
}

step FM-6.3 AUTO "Reconcile labels and Essential Contacts" --on-unmet skip --needs "FM_RUN_SPEC GEMINI_PROJECT CICD_PROJECT"
s_FM_6_3_check() {
  _fm_mc tenant-app; [ "$FM_MC" = go ] || return "$FM_MC"
  local got kv m
  got="$(r gcloud projects describe "$(v GEMINI_PROJECT)" --format=json 2>/dev/null | _fm_py labels -)" || return "$(_fm_nf $?)"
  for kv in $(_fm_py labels "$FM_SPEC" | tr ',' ' '); do printf '%s\n' "$got" | tr ',' '\n' | grep -qxF "$kv" || return 1; done
  m="$(_fm_contacts_missing "$(v GEMINI_PROJECT)")" || return $?
  [ -z "$m" ]
}
s_FM_6_3_apply() {
  _fm_apre || return 1
  _fm_after FM-6.2 || return 1
  x gcloud projects update "$(v GEMINI_PROJECT)" --update-labels="$( [ "$FM_OK" = 1 ] && _fm_py labels "$FM_SPEC" || printf '<spec.labels-as-k=v>')" || return 1
  _fm_say "then FM-2.11 on GEMINI_PROJECT, keeping any contact of the app's current administrators the inventory recorded until 19 decides"
  _fm_contacts_apply "$(v GEMINI_PROJECT)" || return 1
  _fm_save "${FM_R}-FM-6.3-reconcile-v1.txt" gcloud projects describe "$(v GEMINI_PROJECT)" --format="json(labels)" || return 1
  _fm_ck FM-6.3 DONE "labels and contacts"
}

step FM-6.4 AUTO "Regional _Default route and _Trace on the app project" --irreversible --witness --on-unmet skip \
  --needs "FM_RUN_SPEC GEMINI_PROJECT REGION" --note "under ENT_FOLDER_ADMIN (approver: the second human), after the move of FM-6.6"
s_FM_6_4_check() {
  _fm_mc tenant-app; [ "$FM_MC" = go ] || return "$FM_MC"
  _fm_route_check "$(v GEMINI_PROJECT)" || return $?
  [ "$(_fm_sv log_routing.trace_bucket)" = false ] && return 0
  _fm_trace_check "$(v GEMINI_PROJECT)"
}
s_FM_6_4_apply() {
  _fm_apre || return 1
  _fm_after FM-6.6 || return 1
  _fm_plan "requires an active ENT_FOLDER_ADMIN grant (logging.configWriter at fld-agentic-platform): the project is under it after FM-6.6"
  _fm_route_apply "$(v GEMINI_PROJECT)" || return 1
  if [ "$(_fm_sv log_routing.trace_bucket)" != false ] || [ "$AGP_MODE" != apply ]; then _fm_trace_apply "$(v GEMINI_PROJECT)" || return 1; fi
  _fm_say "only entries written after the redirect go to the regional bucket; 19 records that the old _Default entries age out globally"
  _fm_ck FM-6.4 DONE "route and _Trace"
}

step FM-6.5 BLOCKED "Row 38, the factory CI's standing editor on the app project" --note "B-01: row 38 waits for the factory"
s_FM_6_5_check() { ckpt_done FM-6.5; }
s_FM_6_5_manual() {
  echo "BLOCKED on B-01: the factory code that imports endpoints into gemini-registry, writes the gateway access policy and registers"
  echo "  agents (topology row 38, P49), with its identity decided. Until then no machine holds roles/discoveryengine.editor on GEMINI_PROJECT."
  echo "VERIFY (a read): gcloud projects get-iam-policy \"\$GEMINI_PROJECT\" --flatten=\"bindings[].members\""
  echo "  --filter=\"bindings.role=roles/discoveryengine.editor AND bindings.members:serviceAccount\" --format=\"value(bindings.members)\""
  echo "  prints nothing from CICD_PROJECT."
}

step FM-6.6 HUMAN "The move under fld-gemini-enterprise (performed in 19 GE-3)" --witness --on-unmet skip \
  --needs "FM_RUN_SPEC GEMINI_PROJECT FLD_GEMINI_ENTERPRISE GE_CURRENT_PARENT ENT_PROJECT_MOVE_SRC ENT_PROJECT_MOVE_DST CICD_PROJECT PLATFORM_REPO_DIR"
s_FM_6_6_check() {
  _fm_mc tenant-app; [ "$FM_MC" = go ] || return "$FM_MC"
  _fm_ckd FM-6.6 && [ "$(r gcloud projects describe "$(v GEMINI_PROJECT)" --format="value(parent.id)" 2>/dev/null)" = "$(v FLD_GEMINI_ENTERPRISE)" ]
}
s_FM_6_6_manual() {
  echo "WHO: the platform owner, through ENT_PROJECT_MOVE_SRC and ENT_PROJECT_MOVE_DST activated together (approvers as 12), in 19's"
  echo "  announced change window, after 19's preconditions (allow-list union dry-run with zero denials, roles re-granted on the destination)."
  echo "  A live app's move is held for the window, so the script does not run it. WHERE: shell with pam/tools/pam.sh sourced."
  echo "DO: setup/17 FM-6.6's block: the two gcloud pam grants create lines with pam_wait ACTIVE, then"
  echo "  gcloud beta projects move $(v GEMINI_PROJECT) --folder=$(v FLD_GEMINI_ENTERPRISE)"
  echo "VERIFY: gcloud projects describe $(v GEMINI_PROJECT) --format=\"value(parent.type,parent.id)\" prints folder $(v FLD_GEMINI_ENTERPRISE);"
  echo "  19's non-admin user test passes; then FM-6.4, FM-2.20 and FM-2.21 with --accept-pending, and FM-2.22 (kind MOD, module tenant-app)."
  echo "ROLLBACK: move back to GE_CURRENT_PARENT in the same window with the same pair."
  echo "RECORD: outputs as <R>-FM-6.6-move-v1; checkpoint FM-6.6@gemini-prod DONE <approver email>"
}

# ---------------------------------------------------------------- 7. FM-REVOKE (per call)

step FM-7.1 HUMAN "Preconditions: the decision, the evidence export, the row" --sets "FM_REVOKE_DECISION"
s_FM_7_1_check() {
  if _fm_run_selected; then _fm_ctx; _fm_ckpt_is "FM-7.1@$FM_RUN" DONE; else ckpt_done FM-7.1; fi
}
s_FM_7_1_manual() {
  echo "PER CALL, revoke only. In this file's own sitting and in a creation run nothing is revoked: stop here (use --to FM-2.22 for a run)."
  echo "WHO: the platform owner; the agent's owner signs the decision; the second human co-signs for any P, P-SA or controllers project."
  echo "DO: a signed decisions/<date>-revoke-<agent_id>.md naming the project ids, the export object paths and their SHA-256 manifests,"
  echo "  and the retention; a pull request setting the row status: retired. Check: \"\$(agp_tool decision-check.sh)\" <record> prints OK;"
  echo "  each export path exists and gcloud storage hash <object> matches its manifest."
  echo "RECORD: checkpoint FM-7.1@<run> DONE; export FM_REVOKE_DECISION=decisions/<date>-revoke-<agent_id>.md and FM_BD_ID=<the project's MOD row>"
  echo "  in the shell that runs  agp-platform apply --phase 17 --from FM-7.2 --to FM-7.7  with FM_RUN_SPEC set."
}

step FM-7.2 CONSOLE "Unpublish: engine grant, gemini-egress entry, registry card" --on-unmet skip --needs "FM_RUN_SPEC FM_REVOKE_DECISION"
s_FM_7_2_check() { _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0; _fm_ckd FM-7.2; }
s_FM_7_2_manual() {
  echo "WHO: a ge-admins@ member through ENT_GE_ADMIN for the app side; the platform owner through ENT_FOLDER_ADMIN for the registry card."
  echo "WHERE: as the agent's own file (35 for Wall-E) performed them, in reverse: the agent file's registration steps with remove verbs."
  echo "DO: remove the agent's share and the geEngineQuery binding on the engine; regenerate the gemini-egress access policy from env == prod"
  echo "  rows; set the card's meta: line to status=retired."
  echo "VERIFY: a colleague in the former audience no longer sees the agent; the engine policy has no geEngineQuery member; card status=retired."
  echo "RECORD: outputs as <R>-FM-7.2-unpublish-v1; checkpoint FM-7.2@<run> DONE"
}

step FM-7.3 BLOCKED "halt_all for a Tier W+ agent" --note "B-16 for Wall-E: the agent's action service code is not committed; N/A on Tier R"
s_FM_7_3_check() { ckpt_done FM-7.3; }
s_FM_7_3_manual() {
  echo "BLOCKED for any agent whose action service code does not exist (Wall-E: B-16, WALLE_CODE_COMMIT): needs its /v1/control/halt endpoint."
  echo "For a Tier R project (canary-r) the step is N/A. Where the code exists, call the halt endpoint as the agent file documents and read the"
  echo "ladder state back as halt_all (checkpoint FM-7.3@<run> DONE). VERIFY where BLOCKED: README §8 row B-16 lists '17 FM-7.3'."
}

step FM-7.4 AUTO "Remove the deny entries and the PAB binding" --removes --witness --on-unmet skip \
  --needs "FM_RUN_SPEC FM_REVOKE_DECISION ENT_PLATFORM_POLICY CICD_PROJECT PLATFORM_REPO_DIR" --note "witness: the approver of ENT_PLATFORM_POLICY"
s_FM_7_4_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  local DE PB
  while read -r DE; do
    [ -n "$DE" ] || continue
    r gcloud iam policies get "$(_fm_field "$DE" policy_id)" --attachment-point="$(_fm_field "$DE" attachment_point)" --kind=denypolicies --format=json 2>/dev/null \
      | _fm_py deny-lacks "$DE" >/dev/null || return 1
  done <<EOF
$(_fm_list deny_entries)
EOF
  while read -r PB; do
    [ -n "$PB" ] || continue
    exists gcloud iam policy-bindings describe "$(_fm_field "$PB" binding_id)" --project="$FM_PID" --location=global --format="value(name)"
    [ $? = 1 ] || return 1
  done <<EOF
$(_fm_list pab_bindings)
EOF
  _fm_ckd FM-7.4
}
s_FM_7_4_apply() {
  _fm_apre || return 1
  local DE PB
  _fm_after FM-7.1 FM-7.2 || return 1
  _fm_grant "$(v ENT_PLATFORM_POLICY)" 3600s "${FM_RUNID}: revoke, remove deny and PAB entries (FM-7.4)" >/dev/null || return 1
  while read -r DE; do
    [ -n "$DE" ] || continue
    _fm_deny_rmw "$DE" remove FM-7.4 || return 1
  done <<EOF
$(_fm_list deny_entries)
EOF
  while read -r PB; do
    [ -n "$PB" ] || continue
    x gcloud iam policy-bindings delete "$(_fm_field "$PB" binding_id)" --project="$FM_PID" --location=global || return 1
  done <<EOF
$(_fm_list pab_bindings)
EOF
  _fm_say "a project-level deny policy (FM-4.3) goes with the project"
  _fm_ck FM-7.4 DONE "fences removed"
}

step FM-7.5 AUTO "Remove the trigger sink, the per-project entitlements and the lien" --removes --on-unmet skip \
  --needs "FM_RUN_SPEC FM_REVOKE_DECISION LOGGING_PROJECT CICD_PROJECT" --note "ENT_FOLDER_ADMIN for the sink; the project's repair grant for the rest"
s_FM_7_5_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  local rc
  if [ "$(_fm_sv trigger_sink)" != null ]; then
    exists gcloud logging sinks describe "$(_fm_sv trigger_sink.name)" --project="$(v LOGGING_PROJECT)"; rc=$?; [ $rc = 1 ] || return 1
  fi
  exists gcloud pam entitlements describe "ent-deploy-credential-holder-${FM_AG}" --project="$FM_PID" --location=global --billing-project="$(v CICD_PROJECT)"; rc=$?
  [ $rc = 1 ] || return 1
  nonempty r gcloud alpha resource-manager liens list --project="$FM_PID" --format="value(name)" && return 1
  return 0
}
s_FM_7_5_apply() {
  _fm_apre || return 1
  local L
  _fm_after FM-7.4 || return 1
  _fm_plan "lien removal needs resourcemanager.projects.updateLiens: probe it under the repair grant; if refused, 12 adds lienModifier to the template first"
  if [ "$(_fm_sv trigger_sink)" != null ] || [ "$AGP_MODE" != apply ]; then
    x gcloud logging sinks delete "$(_fm_sv trigger_sink.name)" --project="$(v LOGGING_PROJECT)" || return 1
  fi
  x gcloud pam entitlements delete "ent-deploy-credential-holder-${FM_AG}" --project="$FM_PID" --location=global --billing-project="$(v CICD_PROJECT)" || return 1
  if [ "$AGP_MODE" = apply ]; then
    for L in $(r gcloud alpha resource-manager liens list --project="$FM_PID" --format="value(name)"); do
      x gcloud alpha resource-manager liens delete "$L" --project="$FM_PID" || return 1
    done
  else
    x gcloud alpha resource-manager liens delete "<each-lien-of-the-project>" --project="$FM_PID"
  fi
  _fm_say "the repair entitlement is deleted last, in FM-7.6, after the project delete is requested"
  _fm_ck FM-7.5 DONE "sink, deploy entitlement, lien removed"
}

step FM-7.6 AUTO "Delete the project" --irreversible --removes --witness --on-unmet skip \
  --needs "FM_RUN_SPEC FM_REVOKE_DECISION PLATFORM_REPO_DIR" --note "under ENT_PROJECT_REPAIR_<AGENT>; gate: the signed revoke decision record"
s_FM_7_6_check() {
  _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0
  local s rc
  s="$(r gcloud projects describe "$FM_PID" --format="value(lifecycleState)" 2>/dev/null)"; rc=$?
  [ "$s" = DELETE_REQUESTED ] && return 0
  [ $rc = 0 ] && return 1
  exists gcloud projects describe "$FM_PID" --format="value(projectId)"; [ $? = 1 ]
}
s_FM_7_6_apply() {
  _fm_apre || return 1
  _fm_after FM-7.4 FM-7.5 || return 1
  if [ "$AGP_MODE" = apply ]; then
    [ -s "$(v PLATFORM_REPO_DIR)/$(v FM_REVOKE_DECISION)" ] || { _fm_say "STOP: gate record missing"; return 1; }
    "$(agp_tool decision-check.sh)" "$(v PLATFORM_REPO_DIR)/$(v FM_REVOKE_DECISION)" | sed 's/^/        /' >&3 \
      || { _fm_say "STOP: the revoke decision does not check"; return 1; }
  fi
  x gcloud projects delete "$FM_PID" || return 1
  _fm_save "${FM_R}-FM-7.6-deleted-v1.txt" gcloud projects describe "$FM_PID" --format="value(lifecycleState)" || return 1
  _fm_say "gcloud projects undelete $FM_PID restores it within the restore period, which 42 records as the last day the decision can be reversed;"
  _fm_say "then delete the repair entitlement ent-project-repair-${FM_AG} (yours, after the delete request)"
  _fm_ck FM-7.6 DONE "delete requested"
}

step FM-7.7 AUTO "Close the deviation row" --on-unmet skip --needs "FM_RUN_SPEC FM_REVOKE_DECISION FM_BD_ID DEVIATION_REGISTER BUILD_LOG_DIR"
s_FM_7_7_check() { _fm_pre || return $?; [ "$FM_OK" = 1 ] || return 0; _fm_bd_closed "$(v FM_BD_ID)"; }
s_FM_7_7_apply() {
  _fm_apre || return 1
  _fm_after FM-7.6 || return 1
  x bd_close "$(v FM_BD_ID)" "closed by revoke: $(v FM_REVOKE_DECISION)" "17 FM-7.6"
}

# ---------------------------------------------------------------- 8. FM-CORE

step FM-8.1 AUTO-READ "Check the other four core projects with the checker" --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER"
s_FM_8_1_check() { ckpt_done FM-8.1; }
s_FM_8_1_apply() {
  local P rc bad=0 d rep
  d="$(v PLATFORM_REPO_DIR)"
  _fm_plan "the four specs factory/runs/platform-core-{core,logging,kms,validator}.json are written by hand first, as FM-1.3"
  for P in core logging kms validator; do
    rep="$(_fm_rec "FM-8.1-${P}-live-v1").json"
    if [ "$AGP_MODE" = apply ] && [ ! -s "$d/factory/runs/platform-core-${P}.json" ]; then _fm_say "${P}: factory/runs/platform-core-${P}.json missing (written by hand, as FM-1.3)"; bad=1; continue; fi
    _fm_checker live "$d/factory/runs/platform-core-${P}.json" "$rep"; rc=$?
    [ "$AGP_MODE" = apply ] || continue
    _fm_say "${P} exit=$rc"
    [ $rc = 0 ] || { bad=1; continue; }
    ev FM-8.1 core-zero-diff E-05 5.2.4 "build-log:records/${rep##*/}" "$rep" || return 1
  done
  [ $bad = 0 ] || _fm_say "a FAIL is repaired under ENT_PROJECT_REPAIR_CORE and recorded as a DEV row; then re-run"
  return $bad
}

step FM-8.2 AUTO-READ "Row 36: platform-drift@ on the platform folder" \
  --needs "FLD_AGENTIC_PLATFORM SA_PLATFORM_DRIFT CORE_PROJECT ORG_ID PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_FM_8_2_check() { ckpt_done FM-8.2; }
s_FM_8_2_apply() {
  local R8 E py ok f bad=0 sa
  R8="$(_fm_rec FM-8.2)"; E="$(v PLATFORM_REPO_DIR)/ci/drift/expected-principals.yaml"; sa="$(v SA_PLATFORM_DRIFT)"
  py="${REGISTER_VENV_PYTHON:-$HOME/platform/venv-register/bin/python}"
  if [ "$AGP_MODE" != apply ]; then
    _fm_say "read: row_36 of $E with $py (PyYAML) > ${R8##*/}-expected.json"
    _fm_say "read: $(agp_quote gcloud resource-manager folders get-iam-policy "$(v FLD_AGENTIC_PLATFORM)" --flatten="bindings[].members" --filter="bindings.members:serviceAccount:${sa}" --format="value(bindings.role)") (stderr kept)"
    _fm_say "read: $(agp_quote gcloud projects get-iam-policy "$(v CORE_PROJECT)" --flatten="bindings[].members" --filter="bindings.members:serviceAccount:${sa}" --format="value(bindings.role)") (stderr kept)"
    _fm_say "read, when FM-0.4's test passes today: gcloud organizations get-iam-policy $(v ORG_ID) (same filter; nothing expected); otherwise PENDING"
    return 0
  fi
  [ -s "$E" ] || { _fm_say "STOP: ci/drift/expected-principals.yaml missing (made in 16 RG-7.5)"; return 1; }
  r "$py" -c 'import sys,yaml,json; d=yaml.safe_load(open(sys.argv[1]))["row_36"]; print(json.dumps({"principal":d["principal"],"folder":sorted(d["folder"]),"core_project":sorted(d["core_project"])}))' "$E" \
    | xw "${R8}-expected.json" 600 >/dev/null || return 1
  r gcloud resource-manager folders get-iam-policy "$(v FLD_AGENTIC_PLATFORM)" --flatten="bindings[].members" --filter="bindings.members:serviceAccount:${sa}" --format="value(bindings.role)" 2> "${R8}-folder.err" | sort | xw "${R8}-folder.txt" 600 >/dev/null
  r gcloud projects get-iam-policy "$(v CORE_PROJECT)" --flatten="bindings[].members" --filter="bindings.members:serviceAccount:${sa}" --format="value(bindings.role)" 2> "${R8}-core.err" | sort | xw "${R8}-core.txt" 600 >/dev/null
  ok="$(_fm_org_read)"
  if [ "$ok" = yes ]; then
    r gcloud organizations get-iam-policy "$(v ORG_ID)" --flatten="bindings[].members" --filter="bindings.members:serviceAccount:${sa}" --format="value(bindings.role)" 2> "${R8}-org.err" | sort | xw "${R8}-org.txt" 600 >/dev/null
    [ -s "${R8}-org.txt" ] && { _fm_say "FAIL: the organisation binds platform-drift@ (16 RG-7.4: nothing)"; bad=1; }
  else
    : > "${R8}-org.err"
    echo "organisation read unavailable (FM-0.4): PENDING, owner platform owner, re-run when 12 names an organisation read entitlement" | xw "${R8}-org.txt" 600 >/dev/null
  fi
  for f in folder core org; do
    if [ -s "${R8}-${f}.err" ]; then _fm_say "REFUSED on the ${f} read, not an empty result:"; sed 's/^/        /' "${R8}-${f}.err" >&3; bad=1; fi
  done
  cat "${R8}-expected.json" "${R8}-folder.txt" "${R8}-core.txt" "${R8}-org.txt" | sed 's/^/        /' >&3
  _fm_py row36 "${R8}-expected.json" "${R8}-folder.txt" "${R8}-core.txt" | sed 's/^/        /' >&3
  _fm_py row36 "${R8}-expected.json" "${R8}-folder.txt" "${R8}-core.txt" >/dev/null || { _fm_say "a difference from expected-principals.yaml is a finding against 16 (a 16 PENDING binding stays PENDING with 16 as owner)"; bad=1; }
  [ $bad = 0 ] || return 1
  ev FM-8.2 row36 - "4.2.1, 5.2.4" "build-log:records/${R8##*/}-*" "${R8}-expected.json"
}

step FM-8.3 AUTO-READ "Row 40: platform_logs_views readers" --needs "LOGGING_PROJECT PLATFORM_LOGS_VIEWS_DS BUILD_LOG_DIR"
s_FM_8_3_check() { ckpt_done FM-8.3; }
s_FM_8_3_apply() {
  local f ds
  f="$(_fm_rec FM-8.3-row40-v1).json"; ds="$(v LOGGING_PROJECT):$(v PLATFORM_LOGS_VIEWS_DS)"
  _fm_save "$f" bq show --format=prettyjson "$ds" || { _fm_say "the dataset read failed"; return 1; }
  [ "$AGP_MODE" = apply ] || { _fm_say "read: grep CL-7.3 \$BUILD_LOG_DIR/rerun-index.tsv (two PENDING lines, for 22 and 24, or their closures)"; return 0; }
  _fm_rerun_has CL-7.3 || { _fm_say "FAIL: the re-run index holds no CL-7.3 line (14 CL-7.3's readers for mo-metrics@ and eve-verifier@)"; return 1; }
  grep -E 'CL-7.3' "$(v BUILD_LOG_DIR)/rerun-index.tsv" | sed 's/^/        /' >&3
  _fm_say "REVIEW: the access list holds 14's entries (the authorised view walle_workspace_logs, no other reader than CL-7.3 recorded);"
  _fm_say "platform-core-rows.json carries the two readers as pending checks owned by 22 and 24"
}

step FM-8.4 AUTO-READ "Row 41: the aggregated sinks' writer identities" \
  --needs "ORG_ID FLD_AGENTIC_PLATFORM LOGGING_PROJECT PLATFORM_LOGS_DS SINK_S_ORG SINK_S_FOLDER BUILD_LOG_DIR"
s_FM_8_4_check() { ckpt_done FM-8.4; }
s_FM_8_4_apply() {
  local so sf W_ORG W_FLD W_BQ writers acc f bad=0
  so="$(v SINK_S_ORG)"; sf="$(v SINK_S_FOLDER)"; f="$(_fm_rec FM-8.4-row41-v1).txt"
  if [ "$AGP_MODE" != apply ]; then
    _fm_say "read: $(agp_quote gcloud logging sinks describe "${so##*/}" --organization="$(v ORG_ID)" --format='value(writerIdentity)')"
    _fm_say "read: $(agp_quote gcloud logging sinks describe "${sf##*/}" --folder="$(v FLD_AGENTIC_PLATFORM)" --format='value(writerIdentity)')"
    _fm_say "read: $(agp_quote gcloud projects get-iam-policy "$(v LOGGING_PROJECT)" --flatten="bindings[].members" --filter="bindings.role=roles/logging.logWriter" --format="value(bindings.members)")"
    _fm_say "read: $(agp_quote gcloud logging sinks describe to-bigquery --project="$(v LOGGING_PROJECT)" --format='value(writerIdentity)'); bq show --format=prettyjson $(v LOGGING_PROJECT):$(v PLATFORM_LOGS_DS)"
    return 0
  fi
  W_ORG="$(r gcloud logging sinks describe "${so##*/}" --organization="$(v ORG_ID)" --format='value(writerIdentity)')" || bad=1
  W_FLD="$(r gcloud logging sinks describe "${sf##*/}" --folder="$(v FLD_AGENTIC_PLATFORM)" --format='value(writerIdentity)')" || bad=1
  writers="$(r gcloud projects get-iam-policy "$(v LOGGING_PROJECT)" --flatten="bindings[].members" --filter="bindings.role=roles/logging.logWriter" --format="value(bindings.members)")" || bad=1
  W_BQ="$(r gcloud logging sinks describe to-bigquery --project="$(v LOGGING_PROJECT)" --format='value(writerIdentity)')" || bad=1
  acc="$(r bq show --format=prettyjson "$(v LOGGING_PROJECT):$(v PLATFORM_LOGS_DS)" | _fm_py access-email "${W_BQ#serviceAccount:}")" || bad=1
  printf 'S-org %s\nS-folder %s\nlogWriter on LOGGING_PROJECT:\n%s\nto-bigquery %s\n%s\n' "$W_ORG" "$W_FLD" "$writers" "$W_BQ" "$acc" | xw "$f" 600 >/dev/null
  sed 's/^/        /' "$f" >&3
  [ $bad = 0 ] || { _fm_say "a read failed (above)"; return 1; }
  for W in "$W_ORG" "$W_FLD"; do
    printf '%s\n' "$writers" | grep -qxF "$W" || _fm_say "REVIEW: $W is not a logWriter member on LOGGING_PROJECT: compare with 14's record (a same-organisation project destination may need no grant)"
  done
  printf '%s' "$acc" | grep -q '"role": *"WRITER"' || { _fm_say "FAIL: to-bigquery's writer does not hold WRITER on $(v PLATFORM_LOGS_DS)"; return 1; }
  return 0
}

step FM-8.5 AUTO-READ "Row 44: the Sensitive Data Protection discovery configuration" --needs "BUILD_LOG_DIR"
s_FM_8_5_check() { ckpt_done FM-8.5; }
s_FM_8_5_apply() {
  local out f
  f="$(_fm_rec FM-8.5-row44-v1).txt"
  [ "$AGP_MODE" = apply ] || { _fm_say "read: 16's BLOCKED lines in checkpoints.tsv matching SDP, discovery or row 44 (exactly one expected)"; return 0; }
  out="$(awk -F'\t' '$2 ~ /^RG-/ && $3=="BLOCKED" {print $2"\t"$7}' "$(v BUILD_LOG_DIR)/checkpoints.tsv" | grep -i -E 'SDP|discovery|row 44')"
  printf '%s\n' "$out" | xw "$f" 600 >/dev/null; printf '%s\n' "$out" | sed 's/^/        /' >&3
  if [ -z "$out" ]; then
    _fm_say "no BLOCKED line for row 44 from 16: if 16 has made the configuration, read its status the way 16 recorded and move the check"
    _fm_say "from pending to live in platform-core-rows.json; otherwise 16 is not finished"
    return 1
  fi
  _fm_say "REVIEW: the same item is in README's BLOCKED index, and the platform-core spec's pending entry names it"
}

step FM-8.6 BLOCKED "The factory identity's deferred roles" --note "B-01: factory-apply@ folder roles, builds.builder, state copy"
s_FM_8_6_check() { ckpt_done FM-8.6; }
s_FM_8_6_manual() {
  echo "BLOCKED on B-01 (the code that uses factory-apply@'s folder roles, builds.builder, agentregistry.admin, the state copy)."
  echo "The negative assertion runs now, by you, only when FM-0.4's test passes today (ORG_READ_OK=yes); otherwise record it PENDING"
  echo "(owner platform owner, re-run point 12 ent-org-read) and never write an empty table as evidence:"
  echo "  gcloud asset search-all-iam-policies --scope=organizations/$(v ORG_ID) --query=\"policy:\\\"serviceAccount:$(v SA_FACTORY_APPLY)\\\"\""
  echo "    --format=\"value(resource,policy.bindings.role)\" > <date>-FM-8.6-factory-apply.txt 2> <date>-FM-8.6-factory-apply.err"
  echo "VERIFY: an empty .err; only workloadIdentityUser on the account, storage.objectAdmin on TF_STATE_BUCKET and, if 16 made it,"
  echo "  agentregistry.admin on the registry. No folder-level role. The run writes the BLOCKED checkpoint itself."
}

step FM-8.7 HUMAN "Write the platform-core deviation rows" --witness \
  --needs "DEVIATION_REGISTER BUILD_LOG_DIR FLD_PLATFORM_CORE FLD_AGENTIC_PLATFORM ORG_ID LOGGING_PROJECT PLATFORM_REPO_DIR"
s_FM_8_7_check() { ckpt_done FM-8.7 || { _fm_bd_open BD-17-1 && _fm_bd_open BD-17-2; }; }
s_FM_8_7_manual() {
  echo "WHO: the platform owner writes; the second human reads and initials. WHERE: DEVIATION_REGISTER, with ~/.platform-env sourced."
  echo "DO: setup/17 FM-8.7's two bd_insert lines (BD-17-1, BD-17-2). BD-17-2 holds '<made or PENDING>' cells only this sitting knows"
  echo "  (row 40 readers, row 44 SDP discovery, from FM-8.3 and FM-8.5): replace them; bd_insert refuses a row that still holds one."
  echo "VERIFY: grep -c '^| BD-17-' \"\$DEVIATION_REGISTER\" prints 2; both rows above '## Closures' (06 OB-3.2's check)."
  echo "THEN: agp-platform done FM-8.7 --witness <second human's email>  (or re-run apply: it reads as done once both rows exist)"
}

# ---------------------------------------------------------------- 9. The negative test

step FM-9.1 HUMAN "Create the canary secret in CORE_PROJECT" --witness --needs "CORE_PROJECT ENT_PROJECT_REPAIR_CORE REGION CICD_PROJECT PLATFORM_REPO_DIR"
s_FM_9_1_check() { ckpt_done FM-9.1; }
s_FM_9_1_manual() {
  echo "WHO: the platform owner under ENT_PROJECT_REPAIR_CORE (approver as 12 configured). HUMAN because it stores a secret version:"
  echo "  no secret value passes through this script, even random bytes that protect nothing."
  echo "DO: setup/17 FM-9.1's block in your shell: the grant with pam_wait ACTIVE; enable secretmanager in $(v CORE_PROJECT) if 15 has not;"
  echo "  gcloud secrets create fm-negative-canary --location=$(v REGION) --labels=purpose=negative-test,owner=platform-owners --project=$(v CORE_PROJECT);"
  echo "  openssl rand -base64 32 | gcloud secrets versions add fm-negative-canary --location=$(v REGION) --data-file=- --project=$(v CORE_PROJECT)"
  echo "VERIFY: gcloud secrets versions list fm-negative-canary --location=$(v REGION) --project=$(v CORE_PROJECT) --format=\"value(name,state)\""
  echo "  shows version 1 ENABLED; nothing printed but resource names. RECORD: the list as <date>-FM-9.1-canary-v1."
  echo "THEN: agp-platform done FM-9.1 --witness <the grant's approver's email>"
}

step FM-9.2 HUMAN "Commit the negative-test workflow" --witness --needs "PLATFORM_REPO_DIR WIF_PROVIDER SA_FACTORY_APPLY CORE_PROJECT"
s_FM_9_2_check() { ckpt_done FM-9.2; }
s_FM_9_2_manual() {
  echo "WHO: the platform owner opens the pull request; two human reviewers merge, one the second human (it runs as the factory identity)."
  echo "WHERE: PLATFORM_REPO_DIR/.github/workflows/fm-negative-test.yml and the git host (GitLab: CP-5.3's job shape)."
  echo "DO: setup/17 FM-9.2's YAML with its angle brackets filled: auth pinned at the same full commit SHA as wif-smoke.yml, setup-gcloud at"
  echo "  the release's full SHA read on the day, WIF_PROVIDER=$(v WIF_PROVIDER), SA_FACTORY_APPLY=$(v SA_FACTORY_APPLY), CORE_PROJECT=$(v CORE_PROJECT)."
  echo "  The job succeeds only when both the secret read and the secret IAM change are refused; the payload goes to /dev/null."
  echo "VERIFY: merged with the second human's approval; git log --oneline -1 origin/main -- .github/workflows/fm-negative-test.yml shows it."
  echo "THEN: agp-platform done FM-9.2 --witness <second human's email>"
}

step FM-9.3 AUTO "Place the temporary allow binding on the canary" --needs "SA_FACTORY_APPLY CORE_PROJECT REGION BUILD_LOG_DIR" \
  --note "under the FM-9.1 grant; wait at least 7 minutes before FM-9.4"
s_FM_9_3_check() {
  ckpt_done FM-9.3 && return 0
  has_binding "serviceAccount:$(v SA_FACTORY_APPLY)" roles/secretmanager.secretAccessor gcloud secrets get-iam-policy fm-negative-canary --location="$(v REGION)" --project="$(v CORE_PROJECT)"
}
s_FM_9_3_apply() {
  local UNTIL f
  UNTIL="$(python3 -c 'import datetime as d;print((d.datetime.now(d.timezone.utc)+d.timedelta(hours=2)).strftime("%Y-%m-%dT%H:%M:%SZ"))')"
  x gcloud secrets add-iam-policy-binding fm-negative-canary --location="$(v REGION)" --member="serviceAccount:$(v SA_FACTORY_APPLY)" \
    --role=roles/secretmanager.secretAccessor --condition="expression=request.time < timestamp(\"$UNTIL\"),title=fm-negative-test,description=17 FM-9.3 R6 proof" \
    --project="$(v CORE_PROJECT)" >/dev/null || return 1
  f="$(_fm_rec FM-9.3-ancestors-v1).json"
  _fm_save "$f" gcloud beta projects get-ancestors-iam-policy "$(v CORE_PROJECT)" --include-deny --format=json >/dev/null || return 1
  if [ "$AGP_MODE" = apply ]; then
    grep -q 'deny-agents-platform' "$f" && grep -q 'secretmanager.googleapis.com/versions.access' "$f" \
      || _fm_say "REVIEW: the ancestors file should show deny-agents-platform's R6 denying factory-apply@ secretmanager.googleapis.com/versions.access"
  fi
  _fm_say "wait at least 7 minutes (deny and allow propagation, 04 §3) before FM-9.4"
}

step FM-9.4 CONSOLE "Run the test and read the refusal from both sides" --witness --needs "SA_FACTORY_APPLY CORE_PROJECT BUILD_LOG_DIR"
s_FM_9_4_check() { ckpt_done FM-9.4; }
s_FM_9_4_manual() {
  echo "WHO: the platform owner runs it; the second human watches the run page or reads it afterwards."
  echo "WHERE: the git host, Actions > fm-negative-test > Run workflow, branch main; then the shell; then IAM & Admin > Policy Troubleshooter."
  echo "READ: gcloud logging read \"protoPayload.serviceName=\\\"secretmanager.googleapis.com\\\" AND protoPayload.authenticationInfo.principalEmail=\\\"$(v SA_FACTORY_APPLY)\\\"\""
  echo "  --project=$(v CORE_PROJECT) --freshness=1h --format=\"table(timestamp,protoPayload.methodName,protoPayload.status.code,protoPayload.status.message)\""
  echo "  Troubleshooter: principal factory-apply@, the canary's full resource name, permission secretmanager.versions.access."
  echo "VERIFY: 'read refused' and 'setIamPolicy refused', no payload; status code 7; the troubleshooter shows allow granting, deny denying."
  echo "  A successful read is severity 1: FM-9.5 at once, page platform-security@, Tier R stays shut until the incident note is signed."
  echo "RECORD: run URL, its log and the audit read in $(v BUILD_LOG_DIR)/records/<date>-FM-9.4-negative-test-v1.txt, the screenshot as"
  echo "  <date>-FM-9.4-troubleshooter-v1.png beside it; evidence_add FM-9.4 negative-test (and troubleshooter) E-08 4.2.1 \"build-log:records/<file>\" \"<path>\""
  echo "THEN: agp-platform done FM-9.4 --witness <second human's email>"
}

step FM-9.5 AUTO "Remove the allow binding and park the canary" --removes --needs "SA_FACTORY_APPLY CORE_PROJECT REGION DRILL_CALENDAR"
s_FM_9_5_check() {     # VERIFY: no factory-apply@ binding under any role (remove --all takes every condition of one role) and version 1 is DISABLED
  local pol rc vr
  pol="$(r gcloud secrets get-iam-policy fm-negative-canary --location="$(v REGION)" --project="$(v CORE_PROJECT)" --format=json 2>/dev/null)"; rc=$?
  [ $rc = 3 ] && return 3
  [ $rc = 0 ] || return 1
  printf '%s' "$pol" | _fm_py canary-gone "serviceAccount:$(v SA_FACTORY_APPLY)" roles/secretmanager.secretAccessor fm-negative-test | sed 's/^/      /'
  printf '%s' "$pol" | _fm_py canary-gone "serviceAccount:$(v SA_FACTORY_APPLY)" roles/secretmanager.secretAccessor fm-negative-test >/dev/null; rc=$?
  # both halves are always read, so the operator sees the whole state
  nonempty r gcloud secrets versions list fm-negative-canary --location="$(v REGION)" --project="$(v CORE_PROJECT)" \
    --filter="name~/versions/1\$ AND state=DISABLED" --format="value(name)"; vr=$?
  [ $vr = 1 ] && echo "      version 1 is not DISABLED"
  [ $vr = 0 ] || return $vr
  return $rc
}
s_FM_9_5_apply() {
  local m role roles
  m="serviceAccount:$(v SA_FACTORY_APPLY)"
  x gcloud secrets remove-iam-policy-binding fm-negative-canary --location="$(v REGION)" --member="$m" \
    --role=roles/secretmanager.secretAccessor --all --project="$(v CORE_PROJECT)" >/dev/null || return 1
  # the page's role read: every role factory-apply@ still holds on the canary; each is one FM-9.3 did not place
  _fm_plan "read: gcloud secrets get-iam-policy fm-negative-canary --location=$(v REGION) --project=$(v CORE_PROJECT) --format=json:"
  _fm_plan "  every role $m still holds must be none; any printed role is removed the same way (severity 1 at FM-9.4)"
  if [ "$AGP_MODE" = apply ]; then
    roles="$(r gcloud secrets get-iam-policy fm-negative-canary --location="$(v REGION)" --project="$(v CORE_PROJECT)" --format=json | _fm_py member-roles "$m")" || return 1
    for role in $roles; do
      _fm_say "SEVERITY 1: factory-apply@ still holds $role on the canary (FM-9.3 placed only secretAccessor): removing it; add it to FM-9.4's incident note"
      x gcloud secrets remove-iam-policy-binding fm-negative-canary --location="$(v REGION)" --member="$m" \
        --role="$role" --all --project="$(v CORE_PROJECT)" >/dev/null || return 1
    done
  fi
  x gcloud secrets versions disable 1 --secret=fm-negative-canary --location="$(v REGION)" --project="$(v CORE_PROJECT)" || return 1
  _fm_save "$(_fm_rec FM-9.5-cleanup-v1).txt" gcloud secrets get-iam-policy fm-negative-canary --location="$(v REGION)" --project="$(v CORE_PROJECT)" || return 1
  _fm_say "VERIFY (the check, re-run now): no factory-apply@ binding on the canary under any role; version 1 DISABLED"
  _fm_say "then, yourself: add the 'factory negative test' row with today's date to DRILL_CALENDAR ($(v DRILL_CALENDAR)); the secret"
  _fm_say "stays, disabled, for the factory's release-time re-runs (each enables a new version and repeats FM-9.3 to FM-9.5)"
  if [ "$AGP_MODE" = apply ] && ! grep -qi 'factory negative test' "$(v DRILL_CALENDAR)" 2>/dev/null; then
    _fm_say "REVIEW: DRILL_CALENDAR has no 'factory negative test' row yet (the page's VERIFY asks for it with this run's date)"
  fi
}

step FM-9.6 HUMAN "The two negative tests 13 handed on: a second WIF provider and an out-of-boundary call" --witness \
  --needs "CICD_PROJECT ENT_PROJECT_REPAIR_CORE PLATFORM_REPO_DIR"
s_FM_9_6_check() { ckpt_done FM-9.6; }
s_FM_9_6_manual() {
  echo "WHO: the platform owner; the second human reads the outputs. HUMAN: the pass is a refusal you read, and 13's probe runs at the git host."
  echo "DO: setup/17 FM-9.6's block: the ENT_PROJECT_REPAIR_CORE grant with pam_wait ACTIVE, then"
  echo "  gcloud iam workload-identity-pools providers create-oidc fm-b19-probe --workload-identity-pool=wif-factory --location=global"
  echo "    --issuer-uri=\"https://accounts.google.com\" --attribute-mapping=\"google.subject=assertion.sub\" --project=$(v CICD_PROJECT); echo \"exit=\$?\""
  echo "  gcloud iam workload-identity-pools providers list --workload-identity-pool=wif-factory --location=global --project=$(v CICD_PROJECT) --format=\"value(name)\""
  echo "  then 13 OP-7.10's probe exactly as 13 recorded it."
  echo "VERIFY: the create names iam.managed.workloadIdentityPoolProviders (or the policy violation) and exit=1; one provider listed;"
  echo "  13's probe prints its out-of-boundary refusal. A provider that was created is deleted at once: severity 1 against B19."
  echo "RECORD: both outputs as <date>-FM-9.6-b19-pab-v1.   THEN: agp-platform done FM-9.6 --witness <second human's email>"
}

# ---------------------------------------------------------------- 10. The Tier R gate record

step FM-10.1 AUTO-READ "Collect the evidence for each Tier R item" \
  --needs "EVIDENCE_REGISTER FLD_AGENTIC_PLATFORM LOGGING_PROJECT AGENT_REGISTRY ORG_ID REGION BUILD_LOG_DIR"
s_FM_10_1_check() { ckpt_done FM-10.1; }
s_FM_10_1_apply() {
  local S idx R10 ok bad=0 deny sinks f
  idx="$(_fm_rec FM-10.1-evidence-index-v1).txt"; R10="$(_fm_rec FM-10.1)"; f="${R10}-tier-r-evidence-v1.txt"
  if [ "$AGP_MODE" != apply ]; then
    _fm_say "read: the evidence register rows of FM-1.4, FM-8.1, FM-9.4, OP-, CL-, RG-, FS- > ${idx##*/}"
    _fm_say "read: $(agp_quote gcloud org-policies list --folder="$(v FLD_AGENTIC_PLATFORM)" --format="value(constraint)")"
    _fm_say "read: $(agp_quote gcloud iam policies list --attachment-point="cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)" --kind=denypolicies --format="value(name)")"
    _fm_say "read, when FM-0.4's test passes today: gcloud logging sinks list --organization=$(v ORG_ID) (else PENDING in TIER_R_RECORD)"
    _fm_say "read: $(agp_quote gcloud logging sinks list --folder="$(v FLD_AGENTIC_PLATFORM)" --format="value(name,destination,includeChildren)")"
    _fm_say "read: $(agp_quote gcloud logging buckets list --location="$(v REGION)" --project="$(v LOGGING_PROJECT)" --format="value(name,retentionDays,locked)")"
    return 0
  fi
  for S in FM-1.4 FM-8.1 FM-9.4 OP- CL- RG- FS-; do grep -E "\| [0-9-]+-${S}" "$(v EVIDENCE_REGISTER)" | cut -d'|' -f2,4,7; done | xw "$idx" 600 >/dev/null
  deny="$(r gcloud iam policies list --attachment-point="cloudresourcemanager.googleapis.com/folders/$(v FLD_AGENTIC_PLATFORM)" --kind=denypolicies --format="value(name)")" || bad=1
  ok="$(_fm_org_read)"
  if [ "$ok" = yes ]; then
    r gcloud logging sinks list --organization="$(v ORG_ID)" --format="value(name,destination)" > "${R10}-org-sinks.txt" 2> "${R10}-org-sinks.err"
    [ -s "${R10}-org-sinks.err" ] && { _fm_say "REFUSED, not empty:"; sed 's/^/        /' "${R10}-org-sinks.err" >&3; bad=1; }
  else
    echo "organisation sink list unavailable (FM-0.4): S-org is evidenced by 14's own record, and this line is PENDING in TIER_R_RECORD, owner platform owner, re-run point 12 ent-org-read" \
      | xw "${R10}-org-sinks.txt" 600 >/dev/null
  fi
  sinks="$(r gcloud logging sinks list --folder="$(v FLD_AGENTIC_PLATFORM)" --format="value(name,destination,includeChildren)")" || bad=1
  {
    echo "== org policies on fld-agentic-platform"; r gcloud org-policies list --folder="$(v FLD_AGENTIC_PLATFORM)" --format="value(constraint)" | sort
    echo "== deny policies"; printf '%s\n' "$deny"
    echo "== organisation sinks"; cat "${R10}-org-sinks.txt"
    echo "== folder sinks"; printf '%s\n' "$sinks"
    echo "== LOGGING_PROJECT buckets"; r gcloud logging buckets list --location="$(v REGION)" --project="$(v LOGGING_PROJECT)" --format="value(name,retentionDays,locked)"
    echo "== AGENT_REGISTRY $(v AGENT_REGISTRY) (re-run 16's recorded read for its location and writer)"
  } 2>&1 | xw "$f" 600 >/dev/null
  sed 's/^/        /' "$f" >&3
  printf '%s\n' "$deny" | grep -q 'deny-agents-platform' || { _fm_say "FAIL: deny-agents-platform not listed"; bad=1; }
  printf '%s\n' "$deny" | grep -q 'deny-core-agents' || { _fm_say "FAIL: deny-core-agents not listed"; bad=1; }
  printf '%s\n' "$sinks" | grep -q "logging.googleapis.com/projects/$(v LOGGING_PROJECT)" || { _fm_say "FAIL: no folder sink points at LOGGING_PROJECT (S-folder)"; bad=1; }
  _fm_say "REVIEW: fill the FM-10.1 table (record id in every Evidence cell, today's read matching): B1-B22 as 13 records them, buckets'"
  _fm_say "retention and locks as 14 set them, AGENT_REGISTRY in europe-west1 with factory-apply@ its only writer"
  [ $bad = 0 ] || return 1
  ev FM-10.1 tier-r-evidence E-05 "5.2.4, 1.4.1" "build-log:records/${f##*/}" "$f"
}

step FM-10.2 HUMAN "Write TIER_R_RECORD" --witness --needs "PLATFORM_REPO_DIR"
s_FM_10_2_check() { ckpt_done FM-10.2; }
s_FM_10_2_manual() {
  echo "WHO: the platform owner writes and signs; the second human reviews and co-signs; the security reviewer co-signs when appointed"
  echo "  (otherwise a PENDING line for 42's quarterly review). WHERE: PLATFORM_REPO_DIR/records/gates/ (not 42's gates/)."
  echo "DO: mkdir -p records/gates; F=records/gates/\$(date -u +%F)-tier-r-record-v1.md; git switch -c tier-r-record-\$(date -u +%Y%m%d);"
  echo "  write \$F with every section of setup/17 FM-10.2: Gate; Opened under SD-01 (with the factory statement); Items (FM-10.1's table);"
  echo "  Open deviation rows; BLOCKED; PENDING (FM-0.4's organisation lines when ORG_READ_OK=no); What Tier R does not open; Signatures."
  echo "VERIFY: \"\$(agp_tool decision-check.sh)\" \"\$PLATFORM_REPO_DIR/\$F\" prints OK; the platform owner and the second human signed."
  echo "THEN: agp-platform done FM-10.2 --witness <second human's email>"
}

step FM-10.3 HUMAN "Merge the record and set TIER_R_RECORD" --witness --needs "PLATFORM_REPO_DIR EVIDENCE_REGISTER" --sets "TIER_R_RECORD"
s_FM_10_3_check() {
  ckpt_done FM-10.3 && return 0
  has_value TIER_R_RECORD && [ -s "$(v PLATFORM_REPO_DIR)/$(v TIER_R_RECORD)" ]
}
s_FM_10_3_manual() {
  echo "WHO: the platform owner; the second human as required reviewer. WHERE: PLATFORM_REPO_DIR, the git host, the shell."
  echo "DO: git add \"\$F\" && git commit -m \"gates: Tier R record under SD-01 (setup 17 FM-10)\" && git push -u origin HEAD; merge."
  echo "  After the merge: git switch main && git pull --ff-only; penv_set TIER_R_RECORD \"\$F\";"
  echo "  evidence_add FM-10.3 tier-r-record E-05 1.4.1 \"repo:\${F}@\$(git -C \"\$PLATFORM_REPO_DIR\" rev-parse --short HEAD)\" \"\$PLATFORM_REPO_DIR/\$F\""
  echo "VERIFY: need TIER_R_RECORD passes; the file exists; the merge shows the second human's approval; README's 'Tier R open' row names it."
  echo "THEN: agp-platform done FM-10.3 --witness <second human's email>  (or re-run apply: it reads as done once TIER_R_RECORD names the file)"
}

step FM-10.4 HUMAN "End the sitting"
s_FM_10_4_check() { ckpt_done FM-10.4; }
s_FM_10_4_manual() {
  echo "WHO: the platform owner, at the end of the sitting (not inside a multi-phase apply: it revokes every credential)."
  echo "DO: penv_guard; checkpoint FM-10.4 DONE - \"repo:\${TIER_R_RECORD}\" \"file 17 own sittings complete; FM-0.2, FM-6.5, FM-8.6, FM-11.x BLOCKED\";"
  echo "  then agp-platform sitting end   (sitting_end: SITTING-END OK)."
  echo "VERIFY: DONE for FM-0.1, FM-0.3, FM-0.4, FM-1.1 to FM-1.4, FM-8.1 to FM-8.5, FM-8.7, FM-9.1 to FM-9.6, FM-10.1 to FM-10.4;"
  echo "  BLOCKED for FM-0.2, FM-8.6, FM-11.1 to FM-11.3. The per-call steps (§2 to §7) have no lines: the calling files write them."
  echo "  The page's checkpoint line is the record: re-run apply and the step reads as done."
}

# ---------------------------------------------------------------- 11. The supersession path (BLOCKED on B-01)

step FM-11.1 BLOCKED "Import each hand-made resource into the factory's state" --note "B-01: the module code and a pipeline job that accepts a run spec"
s_FM_11_1_check() { ckpt_done FM-11.1; }
s_FM_11_1_manual() {
  echo "BLOCKED on B-01. When unblocked, from the pipeline (not the laptop): import blocks generated from each run spec, one per resource"
  echo "  (project, services, log bucket and _Default sink, _Trace, budget, contacts, accounts, bindings, channels, trigger sink, deny rules,"
  echo "  PAB binding, project org policy, entitlements, lien); import ids from each Terraform resource's documentation, read on the day."
  echo "VERIFY then: terraform plan shows imports only."
}

step FM-11.2 BLOCKED "An empty plan" --note "B-01"
s_FM_11_2_check() { ckpt_done FM-11.2; }
s_FM_11_2_manual() {
  echo "BLOCKED on B-01. When unblocked: terraform plan -detailed-exitcode after the import; exit 0 means no change, and the same run spec"
  echo "  passes fm-zero-diff.py live the same day. A non-empty plan is reviewed and the module or the project corrected by pull request."
}

step FM-11.3 BLOCKED "Close the deviation row and retire the bootstrap entitlements" --note "B-01"
s_FM_11_3_check() { ckpt_done FM-11.3; }
s_FM_11_3_manual() {
  echo "BLOCKED on B-01. When unblocked: bd_close <id> \"terraform import <commit> and empty plan <plan output>\" \"17 FM-11.2\" per MOD row;"
  echo "  when every row an ent-bootstrap-module served is closed, delete it (gcloud pam entitlements delete <id> --folder=<id> --location=global"
  echo "  --billing-project=\"\$CICD_PROJECT\") and close its README re-run row (SD-46). The second human reviews."
}

# ---------------------------------------------------------------- 12. The design corrections pass

step FM-12.1 HUMAN "Correct the design pages this file and 10 found wrong" --witness --needs "WIKI_DIR"
s_FM_12_1_check() { ckpt_done FM-12.1; }
s_FM_12_1_manual() {
  echo "WHO: the platform owner edits the wiki; the second human reviews the diff. WHERE: WIKI_DIR, design pages only."
  echo "DO: one commit, each change dated and marked 'corrected by setup 17': project-topology.md §7.4 history note, §7.6 makers, row 16,"
  echo "  rows 180/182 and §7.2, §7.3; 02 §3.3 platform-core note and §3.6 (display name, recovery_class r-d and r-k, k7-executor@, label keys);"
  echo "  the FOLDER_ID comments of wall-e/SETUP.md, eve/07 and mo/07; SD-22's text once 18 records the principal form."
  echo "VERIFY: git -C $(v WIKI_DIR) diff --stat; grep -n \"k7-kill@\" .../02-landing-zone-and-tiers.md and"
  echo "  grep -n \"Factory \\\`platform-core\\\` module\" .../project-topology.md print nothing; git log -1 --stat lists the four pages."
  echo "RECORD: the commit id as <date>-FM-12.1-design-corrections-v1; the second human's review note in the build log."
  echo "THEN: agp-platform done FM-12.1 --witness <second human's email>"
}

step FM-12.2 HUMAN "Hand the two 18 corrections that follow from FM-2.12a to 18's owner" --witness --needs "BUILD_LOG_DIR"
s_FM_12_2_check() { ckpt_done FM-12.2; }
s_FM_12_2_manual() {
  echo "WHO: the platform owner; the second human reads the hand-over line. This file does not edit another setup file."
  echo "DO: two rows in README's re-run index against file 18, owner the platform owner: (1) KS-1.3's VERIFY records the canary-r floor"
  echo "  pending on floors.json and KS-2.9 applies it; (2) KS-2.10's controllers line: EVE_PROJECT and its twin take the filter half with"
  echo "  vertex_ai false (FM-4.2 denies aiplatform), and EVE_ADVISOR_PROJECT (file 41) is the controller-side project for a full floor."
  echo "  The hand-over line and its date in BUILD_LOG_DIR."
  echo "RECORD: the re-run rows as <date>-FM-12.2-18-corrections-v1.   THEN: agp-platform done FM-12.2 --witness <second human's email>"
}
