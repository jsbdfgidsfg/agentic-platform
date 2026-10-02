# phases/06-organisation-bootstrap-and-roster.sh: setup/06, organisation bootstrap, break-glass and
# the super-admin roster. Registers all 50 steps of the page in its order.
#
# What the script does here, and what it leaves to people:
#   - Every Admin console step (accounts, the admin and break-glass OUs, 2-Step Verification, keys,
#     backup codes, Super Admin, activity rules, groups) is CONSOLE or HUMAN. A step that types or
#     reads a password or backup codes is HUMAN.
#   - The exception's expiry and condition file (OB-3.2), the rest of the exception (OB-3.7), the Policy
#     Simulator preview (OB-3.5a), the removal of the organisation-creation defaults (OB-3.6) and the
#     standing break-glass roles (OB-7.1) are AUTO. OB-3.3, the first organisation grant, is CONSOLE:
#     the page grants it in the Cloud console (IAM & Admin > IAM) with the second human present; its
#     check is the person's `done`, and it also reads the binding and warns on a mismatch (OB-3.7's
#     EXCEPTION EXACT, which covers the role, is the gate that stops).
#   - The Directory API reads of OB-1.3, OB-2.14 and OB-5.3 are CONSOLE: the page runs them in the
#     APIs Explorer, so no Directory token ever reaches the workstation. No domain-wide delegation.
#
# The page splits the work into two sittings at least eight days apart (OB-2.11, OB-3.1, OB-3.5).
# The runner follows the page's step order; `--from` and `--to` select the steps of each sitting.

phase 06 "Organisation bootstrap, break-glass and the super-admin roster" "06-organisation-bootstrap-and-roster.md"
# The organisation permissions are declared only once OB-3.3 is recorded. Until then no account this
# phase runs as holds an organisation role (the page's OB-3.1 VERIFY: `organizations list` may be empty
# until OB-3.3 grants one), and Parts 1 and 2 are Admin console work. Preflight tests every declared
# permission before any apply, so an unconditional line would refuse every apply of OB-1.1 to OB-3.3,
# the steps that make the grant. From OB-3.3, sa-1-admin@ holds Organization Administrator under the
# SD-01 condition, which includes all four (access-control-org, read 2026-10-01): getIamPolicy and the
# two lists for OB-3.4 and every check here, setIamPolicy for OB-3.5a, OB-3.6, OB-3.7 and OB-7.1.
# Reading the checkpoints at load time changes nothing (07 does the same for its billing permissions).
if ckpt_done OB-3.3; then
  requires org "resourcemanager.organizations.getIamPolicy resourcemanager.organizations.setIamPolicy resourcemanager.projects.list resourcemanager.folders.list"
fi

# ---------------------------------------------------------------- helpers of this phase
ob06_m()    { printf '%s\n' "$@"; }
ob06_say()  { local l; for l in "$@"; do agp_say "$l"; done; }   # one line per argument
ob06_val()  { if has_value "$1"; then _penv_get "$1"; else printf '<%s>' "$1"; fi; }   # for messages only
ob06_ev()   { printf '%s/evidence/06' "$(v BUILD_LOG_DIR)"; }
ob06_cond() { printf '%s/identity/bootstrap-exception-condition.yaml' "$(v PLATFORM_REPO_DIR)"; }
ob06_plan() { [ "$AGP_MODE" = apply ] || printf '      reads: %s\n' "$*" >&3; }    # a read shown in plan mode
ob06_save() {  # ob06_save FILE CMD...: a read whose output is kept as evidence; shown, not run, in plan mode
  local f="$1"; shift
  if [ "$AGP_MODE" != apply ]; then printf '      reads: %s > %s\n' "$(agp_quote "$@")" "$f" >&3; return 0; fi
  r "$@" | xw "$f"
}
ob06_py()   { local n="$1"; shift; python3 -c "$("ob06_src_$n")" "$@"; }
ob06_gate() {  # ob06_gate STEP WHY: the page's checkpoint gate; in apply mode a missing DONE stops the step
  ckpt_done "$1" && return 0
  if [ "$AGP_MODE" = apply ]; then agp_say "      STOP: $1 is not DONE ($2); nothing below runs"; return 1; fi
  agp_say "      gate: runs only when $1 is DONE ($2)"
  return 0
}

ob06_cond_text() {  # ob06_cond_text EXPIRY: the condition file of OB-3.2, as the page writes it
  printf 'expression: request.time < timestamp("%sT00:00:00Z")\n' "$1"
  printf 'title: bootstrap-exception-sd-01\n'
  printf 'description: SD-01 dated organisation exception for %s; withdrawn in file 12\n' "$(v SA_1_ADMIN)"
}

ob06_sim_cond_text() {  # ob06_sim_cond_text EXPIRY: the condition file of OB-3.5a action 1
  printf 'expression: request.time < timestamp("%sT00:00:00Z")\n' "$1"
  printf 'title: ob-3-5a-simulator-preview\n'
  printf 'description: Policy Simulator preview of the OB-3.6 removal; removed in this step, BD-06-5\n'
}

ob06_bd() {  # ob06_bd bd_insert ROW | ob06_bd bd_close ID HOW VERIFIED_BY: 01's helpers, through x in apply mode;
  # in plan mode shown as the line a person would type (x's quoting would make a register row unreadable)
  local f a line
  if [ "$AGP_MODE" = apply ]; then x "$@"; return $?; fi
  f="$1"; shift; line="      \$ $f"
  for a in "$@"; do line="$line \"$a\""; done
  printf '%s\n' "$line" >&3
}

ob06_bd_open()   { [ -f "$(v DEVIATION_REGISTER)" ] && awk -F' *[|] *' -v id="$1" '$2 == id && NF == 15 {f = 1} END {exit !f}' "$(v DEVIATION_REGISTER)"; }
ob06_bd_closed() { [ -f "$(v DEVIATION_REGISTER)" ] && awk -F' *[|] *' -v id="$1" '$2 == id && NF == 6 {f = 1} END {exit !f}' "$(v DEVIATION_REGISTER)"; }

ob06_withdrawn() {  # 0 once file 12 has withdrawn the SD-01 exception (12 PA-9.3, BD-06-1 closed): the exception's
  # steps then read as done, so that a later run of this phase never grants the five roles again
  ckpt_done PA-9.3 || ob06_bd_closed BD-06-1
}

ob06_policy_json() { r gcloud organizations get-iam-policy "$(v ORG_ID)" --format=json; }

ob06_policy_state() {  # ob06_policy_state SRC ARG...: the organisation policy, read once as JSON, judged by the page's
  # Python (ob06_src_SRC). 0 yes, 1 no (the script prints why), 2 the read failed, 3 offline.
  local src="$1" pol rc; shift
  pol="$(ob06_policy_json)"; rc=$?
  [ $rc -eq 3 ] && return 3
  [ $rc -eq 0 ] || return 2
  printf '%s' "$pol" | ob06_py "$src" "$@"
}

ob06_exception_ok() {  # ob06_exception_ok exact|role ROLE...: each ROLE bound to SA_1_ADMIN once, under the SD-01 condition
  # (title bootstrap-exception-sd-01, expression naming BOOTSTRAP_EXCEPTION_EXPIRY); with `exact`, nothing else at all on
  # SA_1_ADMIN: OB-3.7's EXCEPTION EXACT. 0 yes, 1 no, 2 error, 3 offline.
  ob06_policy_state exception_state "user:$(v SA_1_ADMIN)" "$(v BOOTSTRAP_EXCEPTION_EXPIRY)" "$@" >/dev/null
}

ob06_sim_absent() {  # 0 when neither Policy Simulator role of OB-3.5a is bound to SA_1_ADMIN
  local pol rc roles
  pol="$(ob06_policy_json)"; rc=$?
  [ $rc -eq 3 ] && return 3
  [ $rc -eq 0 ] || return 2
  roles="$(printf '%s' "$pol" | ob06_py member_roles "user:$(v SA_1_ADMIN)")" || return 2
  case "$roles" in *roles/policysimulator.admin*|*roles/cloudasset.viewer*) return 1;; esac
  return 0
}

ob06_perms() { r gcloud iam roles describe "$1" --flatten=includedPermissions --format="value(includedPermissions)"; }

ob06_p26_probe() {  # 01 section 3.3, second block: the first permission Security Admin holds and none of the
  # other four exception roles holds. Predefined roles are global: `iam roles describe` takes no scope here.
  local t rc=0
  t="$(mktemp -d "${TMPDIR:-/tmp}/agp-p26.XXXXXX")" || return 2
  ob06_perms roles/iam.securityAdmin | sort -u > "$t/sec" || rc=2
  { ob06_perms roles/resourcemanager.organizationAdmin && ob06_perms roles/resourcemanager.folderCreator \
      && ob06_perms roles/resourcemanager.projectCreator && ob06_perms roles/privilegedaccessmanager.admin; } | sort -u > "$t/oth" || rc=2
  [ $rc -eq 0 ] && comm -23 "$t/sec" "$t/oth" | head -n 1
  rm -rf "$t"
  return $rc
}

ob06_tty_answer() {  # ob06_tty_answer PROMPT: prints what the operator types at the terminal; 1 without a terminal
  local ans=""
  printf '%s ' "$1" >&3
  { read -r ans < /dev/tty; } 2>/dev/null || { printf '\n' >&3; return 1; }
  printf '%s' "$ans"
}

ob06_bd_row1() {
  printf '| BD-06-1 | %s | 06 OB-3.2 | EXC | SD-01 dated organisation exception: Organization Administrator, Folder Creator, Project Creator, Privileged Access Manager Admin and Security Admin to %s, conditioned (PAM cannot bootstrap itself; folder-scoped entitlements need their folder) | organizations/%s | SD-01; identity/bootstrap-exception-condition.yaml | five conditioned organisation grants (OB-3.3, OB-3.7) | BLOCKED: no factory | - | %s | %s; withdrawn in file 12, last steps | open |' \
    "$(date -u +%F)" "$(v SA_1_ADMIN)" "$(v ORG_ID)" "$(v SECOND_HUMAN_EMAIL)" "$(v BOOTSTRAP_EXCEPTION_EXPIRY)"
}

ob06_bd_row5() {  # ob06_bd_row5 SIM_EXPIRY: bd06_row 5 of the page
  printf '| BD-06-5 | %s | 06 OB-3.5a | DEV | roles/policysimulator.admin and roles/cloudasset.viewer to %s at the organisation, conditioned, for the Policy Simulator preview of the OB-3.6 removal | organizations/%s | OB-3.5 change record; evidence/06/OB-3.5a-simulator-condition.yaml | two conditioned organisation grants, removed by OB-3.5a action 5 | BLOCKED: no factory | - | %s | %s; removed the same sitting | open |' \
    "$(date -u +%F)" "$(v SA_1_ADMIN)" "$(v ORG_ID)" "$(v SECOND_HUMAN_EMAIL)" "$1"
}

ob06_grp_names() { echo "GRP_GCP_ORG_ADMINS GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY GRP_PLATFORM_APPROVERS GRP_PLATFORM_READERS GRP_GE_ADMINS GRP_GE_USERS GRP_EVE_OWNERS"; }
ob06_grp_lookup() {  # ob06_grp_lookup ADDRESS (OB-6.1 only): 0 exists, 1 not found, 4 a denial that says the group
  # "may not exist" (Cloud Identity's lookup answers so for an address it cannot resolve), 2 any other error
  # (a missing quota project included), 3 offline. Unlike `exists`, it keeps the error text in every
  # failure case, since the page counts any failure as free and leaves the decision to the console search.
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local g="$1" err rc
  err="$(mktemp "${TMPDIR:-/tmp}/agp-err.XXXXXX")"
  # the group address is the scope of `gcloud identity groups describe`
  gcloud identity groups describe "$g" --format="value(groupKey.id,labels)" >/dev/null 2>"$err"; rc=$?
  if [ $rc -eq 0 ]; then rm -f "$err"; return 0; fi
  sed 's/^/        /' "$err" >&3; cat "$err" >> "$AGP_RUNLOG"
  if grep -qiE 'quota' "$err"; then rc=2
  elif grep -qiE 'may not exist' "$err" && grep -qiE 'PERMISSION_DENIED|NOT_FOUND|403|404' "$err"; then rc=4
  elif grep -qiE 'NOT_FOUND|not found|does not exist|was not found|404' "$err"; then rc=1
  else rc=2
  fi
  rm -f "$err"; return $rc
}

# ---------------------------------------------------------------- the page's Python, unchanged except where noted
ob06_src_member_roles() { cat <<'PY'
import json, sys
p = json.load(sys.stdin)
for b in p.get("bindings", []):
    if sys.argv[1] in b.get("members", []):
        print(b["role"])
PY
}

# OB-3.7's VERIFY (and OB-3.3's), reading the policy on standard input. Arguments: member, expiry, exact|role, roles.
# With `exact` it is the page's EXCEPTION EXACT; with `role` only the named roles are judged.
ob06_src_exception_state() { cat <<'PY'
import json, sys
p = json.load(sys.stdin); who, exp, mode, want = sys.argv[1], sys.argv[2], sys.argv[3], set(sys.argv[4:])
got = {}
for b in p.get("bindings", []):
    if who in b.get("members", []):
        got.setdefault(b["role"], []).append(b.get("condition") or {})
def good(v):
    return len(v) == 1 and v[0].get("title") == "bootstrap-exception-sd-01" and exp in v[0].get("expression", "")
ok = all(good(got.get(r, [])) for r in want) and (mode != "exact" or set(got) == want)
for r, v in sorted(got.items()):
    print(r, [c.get("title") for c in v])
print(("EXCEPTION EXACT" if mode == "exact" else "EXCEPTION BINDING OK") if ok else "FAIL")
sys.exit(0 if ok else 1)
PY
}

# OB-7.1's VERIFY, reading the policy on standard input; the argument is the group member.
ob06_src_breakglass_state() { cat <<'PY'
import json, sys
p = json.load(sys.stdin)
roles = sorted(b["role"] + ("?cond" if b.get("condition") else "") for b in p.get("bindings", []) if sys.argv[1] in b["members"])
print(roles)
ok = roles == ["roles/privilegedaccessmanager.admin", "roles/resourcemanager.organizationAdmin"]
print("BREAK-GLASS ROLES EXACT" if ok else "FAIL")
sys.exit(0 if ok else 1)
PY
}

ob06_src_inventory() { cat <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
print("etag", p.get("etag"), "version", p.get("version"))
for b in sorted(p.get("bindings", []), key=lambda b: b["role"]):
    c = (b.get("condition") or {}).get("title", "")
    for m in b["members"]:
        print(b["role"], m, c, sep=" | ")
PY
}

# OB-3.5a action 2; the proposal goes to standard output (written with xw), the summary to standard error.
ob06_src_proposed() { cat <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
targets = ("roles/resourcemanager.projectCreator", "roles/billing.creator")
out, removed = [], []
for b in p.get("bindings", []):
    if b["role"] in targets:
        keep = [m for m in b["members"] if not m.startswith("domain:")]
        removed += [(b["role"], m, (b.get("condition") or {}).get("title", "no condition")) for m in b["members"] if m.startswith("domain:")]
        if not keep: continue
        b = dict(b, members=keep)
    out.append(b)
p["bindings"] = out
json.dump(p, sys.stdout, indent=2); sys.stdout.write("\n")
for r in removed: print("proposed removal:", *r, file=sys.stderr)
print(len(removed), "domain binding(s) in the proposal", file=sys.stderr)
PY
}

ob06_src_replay_summary() { cat <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
rows = d if isinstance(d, list) else d.get("results", d.get("accessStateDiffs", []))
seen = {}
for r in rows:
    s = json.dumps(r)
    for state in ("REVOKED", "POTENTIALLY_REVOKED", "GAINED", "POTENTIALLY_GAINED", "UNKNOWN_CONVERSION", "UNKNOWN_INFO_DENIED"):
        if state in s:
            seen.setdefault(state, []).append(r.get("accessTuple", {}).get("principal") or r.get("principal") or "tbd")
for state, who in sorted(seen.items()):
    print(state, len(who), sorted(set(who))[:50], sep=" | ")
print("NO ACCESS LOST" if not seen.get("REVOKED") and not seen.get("POTENTIALLY_REVOKED") else "ACCESS WOULD BE LOST: read every principal above")
PY
}

# OB-3.6's done state: no unconditional domain: binding of either creator role (exit 0), as its VERIFY's "still present".
ob06_src_domain_left() { cat <<'PY'
import json, sys
p = json.load(sys.stdin)
left = [(b["role"], m) for b in p.get("bindings", []) if b["role"] in ("roles/resourcemanager.projectCreator", "roles/billing.creator") and not b.get("condition") for m in b["members"] if m.startswith("domain:")]
for r in left: print("still present:", *r)
sys.exit(1 if left else 0)
PY
}

# OB-3.6 action 1; the rows go to standard output (written with xw), the table to standard error.
ob06_src_removal_rows() { cat <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
targets = ("roles/resourcemanager.projectCreator", "roles/billing.creator")
rows = [{"role": b["role"], "member": m, "condition": b.get("condition")}
        for b in p.get("bindings", []) if b["role"] in targets
        for m in b["members"] if m.startswith("domain:")]
json.dump(rows, sys.stdout, indent=2); sys.stdout.write("\n")
for r in rows:
    print(r["role"], r["member"], (r["condition"] or {}).get("title", "no condition"), sep=" | ", file=sys.stderr)
print(len(rows), "binding(s) to remove;", len([r for r in rows if r["condition"]]), "conditional", file=sys.stderr)
PY
}

# OB-3.6 action 2's generator; the organisation id comes as the second argument instead of the environment.
ob06_src_removal_cmds() { cat <<'PY'
import json, shlex, sys
org = sys.argv[2]
for r in json.load(open(sys.argv[1])):
    if r["condition"]:
        print("# conditional, left in place:", r["role"], r["member"])
        continue
    print("gcloud organizations remove-iam-policy-binding %s --member=%s --role=%s --condition=None" % (shlex.quote(org), shlex.quote(r["member"]), shlex.quote(r["role"])))
PY
}

ob06_src_removal_pairs() { cat <<'PY'
import json, sys
for r in json.load(open(sys.argv[1])):
    if not r["condition"]:
        print(r["member"] + "|" + r["role"])
PY
}

ob06_src_defaults_removed() { cat <<'PY'
import json, sys
def flat(f):
    p = json.load(open(f))
    return {(b["role"], m, json.dumps(b.get("condition"), sort_keys=True)) for b in p.get("bindings", []) for m in b["members"]}
before, after = flat(sys.argv[1]), flat(sys.argv[2])
planned = {(r["role"], r["member"], json.dumps(r["condition"], sort_keys=True)) for r in json.load(open(sys.argv[3])) if not r["condition"]}
gone, added = before - after, after - before
left = [(r, m) for (r, m, c) in after if m.startswith("domain:") and r in ("roles/resourcemanager.projectCreator", "roles/billing.creator") and c == "null"]
problems = []
if left: problems.append(f"still present: {sorted(left)}")
if gone != planned: problems.append(f"removed set differs from the plan: unexpected {sorted(gone - planned)}, not removed {sorted(planned - gone)}")
if added: problems.append(f"bindings appeared during the step: {sorted(added)}")
print("\n".join(problems) or "DEFAULTS REMOVED")
sys.exit(1 if problems else 0)
PY
}

ob06_src_delegated_file_ok() { cat <<'PY'
import json, sys
u = json.load(open(sys.argv[1])).get("users", [])
ok = all(x.get("isDelegatedAdmin") for x in u)
print("OK delegated file" if ok else "STOP: not the isDelegatedAdmin response")
sys.exit(0 if ok else 1)
PY
}

# OB-5.1; the roster goes to standard output (written with xw).
ob06_src_roster() { cat <<'PY'
import json, os, sys, datetime
E = os.environ
delegated = [u["primaryEmail"] for u in json.load(open(sys.argv[1])).get("users", []) if u.get("isDelegatedAdmin") and not u.get("isAdmin")]
roster = {
  "schema": "super-admin-roster/v1",
  "as_of": datetime.date.today().isoformat(),
  "tenant": {"domain": E["DOMAIN"], "directory_customer_id": E["DIRECTORY_CUSTOMER_ID"], "org_id": E["ORG_ID"]},
  "rules": "04-identity-and-privileged-access.md section 8.1 (P68); exactly two human super admins; any other super admin or admin-role holder is role_assignment_added; a listed role missing is role_assignment_missing",
  "accounts": [
    {"email": E["SA_1_ADMIN"], "kind": "human_super_admin", "holder": "platform owner", "workspace_roles": ["Super Admin"], "org_unit": E["ADMIN_OU"], "two_sv": "only_security_key", "keys": 2, "spare_key_custodian": "second human", "gcp_org_roles": [{"role": r, "until": E["BOOTSTRAP_EXCEPTION_EXPIRY"], "decision": "SD-01", "withdrawn_in": "file 12"} for r in ["roles/resourcemanager.organizationAdmin", "roles/resourcemanager.folderCreator", "roles/resourcemanager.projectCreator", "roles/privilegedaccessmanager.admin", "roles/iam.securityAdmin"]], "eve_reports_poll": True},
    {"email": E["SA_2_ADMIN"], "kind": "human_super_admin", "holder": "second human", "workspace_roles": ["Super Admin"], "org_unit": E["ADMIN_OU"], "two_sv": "only_security_key", "keys": 2, "spare_key_custodian": "platform owner", "gcp_org_roles": [], "eve_reports_poll": True},
    {"email": E["BRK_GCP_1"], "kind": "break_glass_cloud", "workspace_roles": [], "org_unit": E["BREAK_GLASS_OU"], "two_sv": "only_security_key", "keys": 1, "key_custodian": "platform owner", "password_custodian": "second human", "gcp_org_roles_via_group": "gcp-organization-admins@" + E["DOMAIN"], "eve_reports_poll": True},
    {"email": E["BRK_GCP_2"], "kind": "break_glass_cloud", "workspace_roles": [], "org_unit": E["BREAK_GLASS_OU"], "two_sv": "only_security_key", "keys": 1, "key_custodian": "second human", "password_custodian": "platform owner", "gcp_org_roles_via_group": "gcp-organization-admins@" + E["DOMAIN"], "eve_reports_poll": True},
  ] + [{"email": e, "kind": "delegated_admin", "workspace_roles": ["<role name from OB-2.13>"], "decision": "G3 reduction record (file 03)", "eve_reports_poll": True} for e in sorted(delegated)],
  "exceptions": [],
  "expected_later": [
    {"email": "factory-groups@<CICD_PROJECT>.iam.gserviceaccount.com", "kind": "service_account_admin", "workspace_roles": ["Groups Admin"], "added_in": "file 10"},
    {"email": "eve@" + E["DOMAIN"], "kind": "robot_non_admin", "workspace_roles": ["Eve read-only custom role"], "added_in": "file 24"},
    {"email": "walle@" + E["DOMAIN"], "kind": "robot", "workspace_roles": [], "added_in": "file 30; Super Admin in file 38"}
  ],
  "signatures": {"required_reviewer": "second human (CODEOWNERS)", "security_reviewer": "tbd: signs when appointed (04 section 8.1)"}
}
json.dump(roster, sys.stdout, indent=2); sys.stdout.write("\n")
print("roster:", len(roster["accounts"]), "accounts", file=sys.stderr)
PY
}

# OB-5.1's VERIFY: the roster parses, no "<role name" is left, and the delegated rows match the guard file.
ob06_src_roster_ok() { cat <<'PY'
import json, sys
text = open(sys.argv[1]).read()
rows = [a for a in json.loads(text)["accounts"] if a["kind"] == "delegated_admin"]
live = [u for u in json.load(open(sys.argv[2])).get("users", []) if u.get("isDelegatedAdmin") and not u.get("isAdmin")]
left = text.count("<role name")
print(len(rows), "roster rows /", len(live), "live delegated admins;", left, "<role name placeholder(s) left", "OK" if len(rows) == len(live) and left == 0 else "FAIL")
sys.exit(0 if len(rows) == len(live) and left == 0 else 1)
PY
}

# OB-5.2; the list goes to standard output (written with xw).
ob06_src_control_groups() { cat <<'PY'
import json, os, sys, datetime
E = os.environ; D = E["DOMAIN"]
def g(name, cls, purpose, members, owners=(), used_by="", source=None):
    x = {"email": f"{name}@{D}", "class": cls, "security_label": True, "who_can_join": "Only invited users", "external_members": "none", "owners": list(owners), "members": list(members), "purpose": purpose, "used_by": used_by}
    if source: x["membership_source"] = source
    return x
doc = {
  "schema": "control-groups/v1", "as_of": datetime.date.today().isoformat(),
  "rules": "hand-managed; changed only by a merged pull request with the second human as required reviewer; any live membership change without a merge is severity 1 (04 section 2.4, section 8.5); factory-groups@ refuses every group listed here",
  "groups": [
    g("gcp-organization-admins", "control", "Cloud break-glass: standing Organization Administrator and PAM Admin (04 section 7.1)", [E["BRK_GCP_1"], E["BRK_GCP_2"]], used_by="organisation IAM, file 06 OB-7.1"),
    g("platform-owners", "control", "PAM requester for platform entitlements; standing PAM Admin from file 12", [E["SA_1_ADMIN"]], used_by="file 12"),
    g("platform-security", "control", "Notified on every PAM grant (04 section 5.2)", [E["SECOND_HUMAN_EMAIL"]] + ([E["INCIDENT_COMMANDER_EMAIL"]] if E.get("INCIDENT_COMMANDER_EMAIL") else []), used_by="file 12 notifications"),
    g("platform-approvers", "control", "ent-k7-human requesters (04 section 5.2)", [E["SA_1_ADMIN"], E["SA_2_ADMIN"]], used_by="file 12, file 18"),
    g("platform-readers", "control", "Read-only platform surfaces (04 section 6.4)", [E["SA_1_ADMIN"], E["SA_2_ADMIN"]], used_by="files 16, 18"),
    g("ge-admins", "control", "Requester group of ent-ge-admin (SD-18, SD-19)", [E["SA_1_ADMIN"]], used_by="files 12, 19, 20, 35"),
    g("eve-owners", "control", "Eve owners; owned by the second human (SD-12 item 1)", [E["SA_2_ADMIN"]], owners=[E["SA_2_ADMIN"]], used_by="files 12, 23 to 28"),
    g("ge-users", "hand_made_bulk", "Gemini Enterprise app users; filled and counted before any access removal (SD-20)", [], used_by="file 19", source="the licence-holder list recorded by file 05 in GE_INVENTORY_DIR, loaded in file 19; not a control group: no severity 1 on membership change; adopted by the group factory at Tier R (P65)"),
  ],
  "planned": [
    {"email": f"walle-operators@{D}", "class": "control", "made_in": "file 30"},
    {"email": f"walle-protected@{D}", "class": "control", "made_in": "file 30"},
    {"email": f"walle-super-approvers@{D}", "class": "control", "made_in": "file 33"},
    {"email": "the eve-console IAP audience group", "class": "control", "made_in": "file 26"}
  ],
  "owner_note": "04 section 2.4 names platform-owners@ as owner of platform and controller groups; this list sets no group owner except eve-owners@ (SD-12), so that membership changes need a super admin acting on a merged change; the second human confirms this choice at the merge"
}
json.dump(doc, sys.stdout, indent=2); sys.stdout.write("\n")
print("control groups:", len(doc["groups"]), "groups", file=sys.stderr)
PY
}

# OB-5.2's VERIFY: the file parses and its eight group emails equal the eight GRP_* values (arguments 2 to 9).
ob06_src_control_groups_ok() { cat <<'PY'
import json, sys
emails = sorted(g["email"] for g in json.load(open(sys.argv[1]))["groups"])
want = sorted(sys.argv[2:])
print("parses;", len(emails), "groups", "OK" if emails == want else "FAIL: the list and the GRP_* values differ")
sys.exit(0 if emails == want else 1)
PY
}

ob06_src_groups_match() { cat <<'PY'
import json, os, sys
lst = json.load(open(sys.argv[1])); d = sys.argv[2]; bad = 0
for g in lst["groups"]:
    e = g["email"]
    desc = json.load(open(os.path.join(d, e + ".describe.json")))
    mem = json.load(open(os.path.join(d, e + ".members.json")))
    labels = desc.get("labels", {})
    sec = "cloudidentity.googleapis.com/groups.security" in labels
    live = {m["preferredMemberKey"]["id"]: sorted(r["name"] for r in m.get("roles", [])) for m in mem}
    want = set(g["members"]) | set(g["owners"])
    owners_live = {k for k, v in live.items() if "OWNER" in v}
    ok = sec and set(live) == want and owners_live == set(g["owners"])
    bad += not ok
    print("OK  " if ok else "FAIL", e, "security" if sec else "NO-SECURITY-LABEL", sorted(live), "owners", sorted(owners_live))
print("GROUPS MATCH LIST" if bad == 0 else f"{bad} GROUP(S) DIFFER")
sys.exit(1 if bad else 0)
PY
}

# ================================================================ Part 1: preflight and read-only inventory

step OB-1.1 AUTO-READ "Preflight: variables, decisions, people and the shell" \
  --needs "DOMAIN DIRECTORY_CUSTOMER_ID ORG_ID WORKSPACE_EDITION OWNER_DAILY_ACCOUNT SECOND_HUMAN_EMAIL PLATFORM_REPO_DIR PLATFORM_REPO_REMOTE BUILD_LOG_DIR EVIDENCE_INTERIM_LOCATION EVIDENCE_REGISTER DEVIATION_REGISTER GCLOUD_CONFIG_NAME" \
  --gate "SD-01 SD-12 SD-18 SD-27 SD-30 G3-ROSTER"
s_OB_1_1_check() { ckpt_done OB-1.1; }
s_OB_1_1_apply() {
  # The page's `gcloud config configurations activate` is not run: ~/.platform-env exports
  # CLOUDSDK_ACTIVE_CONFIG_NAME, which takes precedence, and penv_guard checks it.
  local bad=0 p o
  ob06_plan "gcloud config get project (must print nothing); CLOUDSDK_CORE_PROJECT unset; penv_guard; git config --get remote.origin.url"
  x mkdir -p "$(ob06_ev)" || bad=1
  [ "$AGP_MODE" = apply ] || return 0
  p="$(r gcloud config get project 2>/dev/null)"   # a local configuration read: the check that no project is in scope
  case "$p" in ''|'(unset)') ob06_say "      OK no default project";; *) ob06_say "      FAIL default project set: $p"; bad=1;; esac
  if [ -z "${CLOUDSDK_CORE_PROJECT:-}" ]; then ob06_say "      OK CLOUDSDK_CORE_PROJECT unset"; else ob06_say "      FAIL CLOUDSDK_CORE_PROJECT set"; bad=1; fi
  if command -v penv_guard >/dev/null 2>&1; then
    if penv_guard; then ob06_say "      OK guard clean"; else ob06_say "      FAIL penv_guard (above)"; bad=1; fi
  fi
  # the configured value, as the page reads it: `remote get-url` would expand insteadOf rewriting
  o="$(r git -C "$(v PLATFORM_REPO_DIR)" config --get remote.origin.url 2>/dev/null)"
  if [ -n "$o" ] && [ "$o" = "$(v PLATFORM_REPO_REMOTE)" ]; then ob06_say "      OK origin is PLATFORM_REPO_REMOTE"
  else ob06_say "      FAIL git config --get remote.origin.url prints '$o', not PLATFORM_REPO_REMOTE"; bad=1; fi
  ob06_say "      The six decisions were read as signed by the gate above. Now open SD-01 (the expiry), the G3 decision" \
          "      (accounts and target roles) and SD-27 (custody); confirm the two sitting dates, at least eight days apart," \
          "      with the second human; and check the PPL-EW envelope-witness record (if absent: BD-06-4, page preconditions)."
  return $bad
}

step OB-1.2 CONSOLE "Record the edition and the tenant-wide settings this file must not change" --gate "SD-30"
s_OB_1_2_check() { ckpt_done OB-1.2; }
s_OB_1_2_manual() { ob06_m \
  "WHO: platform owner as super admin (OWNER_DAILY_ACCOUNT). Read only: never change either setting (SD-30)." \
  "WHERE: Admin console > Security > Authentication > Account recovery > Super admin account recovery;" \
  "       Security > Authentication > Multi-party approval settings; Billing > Subscriptions." \
  "DO: at the top OU, write down super-admin self-recovery; write down multi-party approval (on/off, which settings);" \
  "    confirm WORKSPACE_EDITION ($(ob06_val WORKSPACE_EDITION)) and whether Cloud Identity Free exists; screenshot each page." \
  "    If multi-party approval is on, a second existing super admin must attend Part 2 to approve." \
  "RECORD: <date>-OB-1.2-tenant-wide-settings-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-1.2"; }

step OB-1.3 CONSOLE "Inventory every super admin and every admin-role holder"
s_OB_1_3_check() { ckpt_done OB-1.3; }
s_OB_1_3_manual() { ob06_m \
  "WHO: platform owner as super admin, clean browser profile of OWNER_DAILY_ACCOUNT (the browser holds the token)." \
  "WHERE: APIs Explorer of Directory API users.list, roles.list and roleAssignments.list (customer $(ob06_val DIRECTORY_CUSTOMER_ID))." \
  "DO: users.list query isAdmin=true, then isDelegatedAdmin=true (viewType admin_view, projection full, maxResults 500);" \
  "    roles.list; roleAssignments.list with includeIndirectRoleAssignments=true. Paste each response at once with pbpaste" \
  "    into $(ob06_val BUILD_LOG_DIR)/evidence/06/OB-1.3-{users-isAdmin,users-isDelegatedAdmin,roles,roleassignments}.json" \
  "    (pages -p2, -p3 if nextPageToken). Run the page's step 4 table script; resolve unmatched ids in Account > Admin roles." \
  "VERIFY: the super-admin count equals Admin roles > Super Admin > Admins." \
  "RECORD: <date>-OB-1.3-admin-inventory-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-1.3"; }

step OB-1.4 CONSOLE "Record every domain-wide delegation client"
s_OB_1_4_check() { ckpt_done OB-1.4; }
s_OB_1_4_manual() { ob06_m \
  "WHO: platform owner as super admin." \
  "WHERE: Admin console > Security > Access and data control > API controls > Domain wide delegation > Manage Domain Wide Delegation." \
  "DO: record every client's name, client ID and scopes, and its owner (or *tbd*). Add, remove or edit nothing." \
  "VERIFY: the record's row count equals the page's. If any client serves a platform identity (walle@, eve@, factory-*@," \
  "        eve-*@, mo-*@, walle-*@, platform-*@): STOP this file and open a severity 1 record to the second human." \
  "RECORD: <date>-OB-1.4-dwd-clients-v1 in EVIDENCE_INTERIM_LOCATION (the baseline of file 25's rule)." \
  "THEN: agp-platform done OB-1.4"; }

step OB-1.5 CONSOLE "Read the licensing state for accounts without a Workspace licence"
s_OB_1_5_check() { ckpt_done OB-1.5; }
s_OB_1_5_manual() { ob06_m \
  "WHO: platform owner as super admin (License management). Read only: nothing is clicked except navigation." \
  "WHERE: Admin console > Billing > Subscriptions; Billing > License settings." \
  "DO: record every subscription with status and licence counts; state whether Cloud Identity Free is present" \
  "    (must agree with OB-1.2); record whether automatic licensing is On at the top OU." \
  "RECORD: a two-line build-log note; <date>-OB-1.5-subscriptions-before-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-1.5 --note \"Cloud Identity Free present|absent; top-level auto-licensing On|Off\""; }

step OB-1.6 HUMAN "Brief the people and notify the super admins that G3 reduces" --witness --gate "G3-ROSTER"
s_OB_1_6_check() { ckpt_done OB-1.6; }
s_OB_1_6_manual() { ob06_m \
  "WHO: platform owner with the second human; IT security signs the notification (its G3 decision)." \
  "WHERE: a meeting, then email from the second human's daily account." \
  "DO: walk the second human through setup/06, its settings table and the sitting dates." \
  "    From the OB-1.3 table and the G3 decision, the second human notifies every other super admin: removal date," \
  "    the delegated role they receive, and the hand-over exception process. Warn the organisation-level role holders" \
  "    that OB-3.5 will ask them about the domain-wide defaults." \
  "VERIFY: every account the G3 decision reduces has a sent notice; replies filed." \
  "RECORD: <date>-OB-1.6-g3-notices-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-1.6 --witness <second human's email>"; }

# ================================================================ Part 2: the admin OU and the two human admin accounts

step OB-2.0 CONSOLE "Add the Cloud Identity Free subscription, if OB-1.5 found none" --witness
s_OB_2_0_check() { ckpt_done OB-2.0; }
s_OB_2_0_manual() { ob06_m \
  "WHO: platform owner as super admin; the second human watches the screen." \
  "GATE: OB-1.5 recorded Cloud Identity Free as absent. If present: change nothing and record it as not needed." \
  "WHERE: Admin console > Billing > Subscriptions (screenshot before); Billing > Buy or upgrade." \
  "DO: next to Cloud Identity Free, click Get Started. Accept no other offer, add no Workspace licence." \
  "    Screenshot Subscriptions after; the second human states only the Cloud Identity Free line differs." \
  "VERIFY: the Workspace subscription and the top OU's automatic-licensing value are unchanged from OB-1.5." \
  "RECORD: <date>-OB-2.0-cloud-identity-free-added-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-2.0 --witness <second human's email> [--note \"not needed, Cloud Identity Free already present\"]"; }

step OB-2.1 CONSOLE "Create the admin organisational unit" --sets "ADMIN_OU"
s_OB_2_1_check() { ckpt_done OB-2.1; }
s_OB_2_1_manual() { ob06_m \
  "WHO: platform owner as super admin." \
  "WHERE: Admin console > Directory > Organizational units; Billing > License settings." \
  "DO: under the top OU create 'Admins', description \"Human super-admin accounts (P68, file 06)\"." \
  "    License settings: select Admins, Workspace subscription > Edit > Off > Override. Cloud Identity Free stays inherited." \
  "VERIFY: /Admins exists with no users; License settings shows the override." \
  "RECORD (type it): penv_set ADMIN_OU \"/Admins\"; screenshots <date>-OB-2.1-admin-ou-v1." \
  "THEN: agp-platform done OB-2.1"; }

step OB-2.2 CONSOLE "Enforce \"Only security key\" 2-Step Verification on ADMIN_OU, with an enrolment period"
s_OB_2_2_check() { ckpt_done OB-2.2; }
s_OB_2_2_manual() { ob06_m \
  "WHO: platform owner as super admin." \
  "WHERE: Admin console > Security > Authentication > 2-step verification, OU 'Admins' selected." \
  "DO: allow users to turn on 2SV; Enforcement On; new user enrollment period: shortest value of at least 8 days;" \
  "    uncheck \"Allow user to trust the device\"; Methods: Only security key; security codes: not allowed; Override." \
  "VERIFY: re-open on Admins and read every value back; the top OU is unchanged (screenshot both)." \
  "RECORD: <date>-OB-2.2-2sv-admin-ou-v1 in EVIDENCE_INTERIM_LOCATION, with the enrolment period." \
  "THEN: agp-platform done OB-2.2"; }

step OB-2.3 CONSOLE "Session controls on ADMIN_OU"
s_OB_2_3_check() { ckpt_done OB-2.3; }
s_OB_2_3_manual() { ob06_m \
  "WHO: platform owner as super admin." \
  "WHERE: Admin console, OU 'Admins': Security > Access and data control > Google session control;" \
  "       Security > Access and data control > Google Cloud session control." \
  "DO: web session duration: the shortest offered; Override." \
  "    Google Cloud: Require reauthentication, every 1 hour, method Security key, \"Exempt trusted apps\" unchecked; Override." \
  "VERIFY: both pages re-opened on Admins show the values (changes may take up to 24 hours; gcloud is observed in OB-3.1)." \
  "RECORD: <date>-OB-2.3-sessions-admin-ou-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-2.3"; }

step OB-2.4 HUMAN "Create sa-1-admin@" --sets "SA_1_ADMIN"
s_OB_2_4_check() { ckpt_done OB-2.4; }
s_OB_2_4_manual() { ob06_m \
  "HUMAN: a password is handled; the script never sees it (setup/06 OB-2.4)." \
  "WHO: platform owner as super admin. WHERE: Admin console > Directory > Users > Add new user; clean sa-1-admin@ profile." \
  "DO: first name sa-1, last name admin, primary email sa-1-admin@$(ob06_val DOMAIN); no secondary email, no phone;" \
  "    OU /Admins; automatically generated password; ask for a change at next sign-in. Send details to nobody." \
  "    Paste the initial password once into the sign-in box only; set the vault-generated password from the vault entry." \
  "VERIFY: user page shows /Admins, no recovery information, only a Cloud Identity Free licence; 2SV enrolment prompt reached." \
  "RECORD (type it): penv_set SA_1_ADMIN \"sa-1-admin@\${DOMAIN}\"; the vault entry's name (never its content)." \
  "THEN: agp-platform done OB-2.4"; }

step OB-2.5 HUMAN "Create sa-2-admin@" --sets "SA_2_ADMIN" --witness
s_OB_2_5_check() { ckpt_done OB-2.5; }
s_OB_2_5_manual() { ob06_m \
  "HUMAN: the second human sets the password alone; the platform owner does not look." \
  "WHO: platform owner creates the account; the second human performs the first sign-in on their own workstation." \
  "DO: as OB-2.4 with first name sa-2, primary email sa-2-admin@$(ob06_val DOMAIN), OU /Admins; hand over the screen;" \
  "    the second human pastes the initial password once and sets a vault-generated password from their own vault entry." \
  "VERIFY: as OB-2.4; the second human states in the record that the platform owner did not see the password." \
  "RECORD (type it): penv_set SA_2_ADMIN \"sa-2-admin@\${DOMAIN}\"" \
  "THEN: agp-platform done OB-2.5 --witness <second human's email>"; }

step OB-2.6 CONSOLE "Interim Admin console activity rules" --needs "SECOND_HUMAN_EMAIL SA_1_ADMIN SA_2_ADMIN" --witness
s_OB_2_6_check() { ckpt_done OB-2.6; }
s_OB_2_6_manual() {
  local rb="WAITING incident commander (create rule B as soon as one is named)"
  if has_value INCIDENT_COMMANDER_EMAIL; then rb="$(_penv_get INCIDENT_COMMANDER_EMAIL)"; elif has_value SECURITY_REVIEWER_EMAIL; then rb="$(_penv_get SECURITY_REVIEWER_EMAIL)"; fi
  ob06_m \
  "WHO: platform owner as super admin; the second human watches each save and receives the test mail." \
  "WHERE: Admin console > Home > Rules > Create rule > Activity." \
  "A interim-roster-login-to-second-human: User log events, Actor $(ob06_val SA_1_ADMIN), Event unfiltered; alert center High;" \
  "  email $(ob06_val SECOND_HUMAN_EMAIL) only (not \"All super administrators\")." \
  "B interim-sa-2-login-to-incident-commander: User log events, Actor $(ob06_val SA_2_ADMIN); High; email $rb." \
  "C interim-admin-role-change: Admin log events, each role-assignment event (record the exact labels); High; email the" \
  "  second human and the rule B recipient. D interim-rule-changed, if a rule-change event label exists (step 4)." \
  "VERIFY: sign in once more as each admin account; the recipients confirm the mails. No mail in 24 hours, or no User log" \
  "  events source: the fallback daily read and BD-06-2 (bd_insert \"\$(bd06_row 2)\", bd06_row from the page)." \
  "RECORD: <date>-OB-2.6-interim-rules-v1. Only the second human retires these rules, never before EVE_H_LIVE_RECORD." \
  "THEN: agp-platform done OB-2.6 --witness <second human's email>"; }

step OB-2.7 HUMAN "Enrol two security keys on sa-1-admin@" --witness
s_OB_2_7_check() { ckpt_done OB-2.7; }
s_OB_2_7_manual() { ob06_m \
  "HUMAN: hardware security keys. WHO: platform owner; the second human present." \
  "WHERE: clean sa-1-admin@ profile: Google Account > Security > 2-Step Verification > Passkeys and security keys." \
  "DO: sign in as sa-1-admin@ (inside the enrolment period); turn on 2SV with the first key ('sa-1 primary');" \
  "    add the second key ('sa-1 spare'); write both serials on the custody form only, never in a file; sign out." \
  "VERIFY: in the daily account's Admin console, Directory > Users > sa-1-admin@ > Security lists two named keys;" \
  "        the second human reads the names and signs the form (it stays with the spare key for OB-2.9)." \
  "THEN: agp-platform done OB-2.7 --witness <second human's email>"; }

step OB-2.8 HUMAN "Enrol two security keys on sa-2-admin@" --witness
s_OB_2_8_check() { ckpt_done OB-2.8; }
s_OB_2_8_manual() { ob06_m \
  "HUMAN: hardware security keys. WHO: the second human performs; the platform owner present." \
  "WHERE: the second human's clean sa-2-admin@ profile." \
  "DO: as OB-2.7 on sa-2-admin@, labels 'sa-2 primary' and 'sa-2 spare'; serials on the second human's custody form." \
  "VERIFY: Directory > Users > sa-2-admin@ > Security shows 2SV on and two keys; the platform owner signs the form." \
  "THEN: agp-platform done OB-2.8 --witness <second human's email>"; }

step OB-2.9 HUMAN "Admin-generated backup codes, sealed with each spare key" --witness --gate "SD-27"
s_OB_2_9_check() { ckpt_done OB-2.9; }
s_OB_2_9_manual() { ob06_m \
  "HUMAN: backup codes are secrets; the script never sees them. Needs the envelope witness named in PPL-EW." \
  "WHO: platform owner (OWNER_DAILY_ACCOUNT) generates both sets; custodian of sa-1-admin@'s envelope: the second human;" \
  "     of sa-2-admin@'s: the security reviewer or PPL-EW's IT security witness, never the platform owner." \
  "WHERE: Admin console > Directory > Users > the user > Security > 2-Step Verification > Get backup verification codes." \
  "DO: copy the codes by hand onto the inner sheet; seal with the spare key; custodian and witness sign the outer record;" \
  "    safe and safe log; scan the outer record only, same day, as <date>-custody-<account>-spare-v1 (SD-27)." \
  "    Open BD-06-3: paste bd06_row from the page, then bd_insert \"\$(bd06_row 3)\"." \
  "No witness present: checkpoint OB-2.9 PENDING - - \"WAITING envelope witness\" and seal nothing." \
  "THEN: agp-platform done OB-2.9 --witness <envelope witness's email>"; }

step OB-2.10 CONSOLE "Assign Super Admin to sa-1-admin@ and sa-2-admin@" --witness
s_OB_2_10_check() { ckpt_done OB-2.10; }
s_OB_2_10_manual() { ob06_m \
  "WHO: platform owner as super admin (OWNER_DAILY_ACCOUNT); the second human present." \
  "WHERE: Admin console > Account > Admin roles > Super Admin > Assign admin > Assign members." \
  "DO: assign Super Admin to $(ob06_val SA_1_ADMIN), then to $(ob06_val SA_2_ADMIN). If multi-party approval is on (OB-1.2)," \
  "    an existing super admin other than the platform owner approves each request; record who." \
  "VERIFY: Super Admin > Admins lists both; rule C mailed the second human for each (record the delay; if no mail in" \
  "        24 hours, correct rule C's event filter and record it)." \
  "RECORD: <date>-OB-2.10-super-admin-assigned-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-2.10 --witness <second human's email>"; }

step OB-2.10a HUMAN "The second human regenerates their own backup codes and reseals as v2" --witness --gate "SD-27"
s_OB_2_10a_check() { ckpt_done OB-2.10a; }
s_OB_2_10a_manual() { ob06_m \
  "HUMAN: the second human alone, as sa-2-admin@, with the envelope witness; the platform owner out of the room and off" \
  "       any screen share. Same sitting as OB-2.10." \
  "WHERE: their own workstation: Admin console > Directory > Users > sa-2-admin@ > Security > Get backup verification codes." \
  "DO: generate fresh codes (OB-2.9's set becomes inactive); copy by hand; open the v1 envelope before the witness and seal" \
  "    the spare key with the new sheet as v2; paper record, safe log; scan as <date>-custody-sa-2-admin-spare-v2." \
  "    Close BD-06-3: bd_close BD-06-3 \"codes regenerated by the account holder; v2 envelope <serial>\" \"06 OB-2.10a VERIFY\"" \
  "    (or the page's BD-06-6 fallback if self-generation is refused)." \
  "VERIFY: the platform owner confirms only that the safe log balances; never sees the sheet." \
  "THEN: agp-platform done OB-2.10a --witness <envelope witness's email>"; }

step OB-2.11 HUMAN "Prove both admin accounts before any daily account loses Super Admin" --witness
s_OB_2_11_check() { ckpt_done OB-2.11; }
s_OB_2_11_manual() { ob06_m \
  "HUMAN: security-key sign-ins, at the second sitting, at least 7 days after OB-2.7 and OB-2.8, inside the enrolment period." \
  "WHO: platform owner for sa-1-admin@, the second human for sa-2-admin@; each watches the other." \
  "DO: sign in with the primary key (no other second-step option may be offered); open Admin roles; sign in again with the" \
  "    spare key in front of custodian and envelope witness; reseal (v2 for sa-1-admin@, v3 for sa-2-admin@); scan same day." \
  "    APIs Explorer users.list query orgUnitPath=/Admins, viewType admin_view; pbpaste into" \
  "    $(ob06_val BUILD_LOG_DIR)/evidence/06/OB-2.11-admin-ou-users.json and run the page's script." \
  "VERIFY: it prints ADMIN ACCOUNTS PROVEN; each sign-in produced a rule A or B mail. A code or phone option: STOP (OB-2.2)." \
  "THEN: agp-platform done OB-2.11 --witness <second human's email>"; }

step OB-2.12 HUMAN "Remove Super Admin from the daily accounts" --witness --removes
s_OB_2_12_check() { ckpt_done OB-2.12; }
s_OB_2_12_manual() { ob06_m \
  "HUMAN: the second human removes their own daily account's Super Admin, as sa-2-admin@, in their own profile." \
  "GATE: OB-2.11 printed ADMIN ACCOUNTS PROVEN today." \
  "WHO: platform owner as sa-1-admin@; the second human present, signed in as sa-2-admin@ in their own profile." \
  "WHERE: Admin console > Account > Admin roles > Super Admin > Assign admin." \
  "DO: tick $(ob06_val OWNER_DAILY_ACCOUNT) > Unassign role. If the second human's daily account holds Super Admin, they" \
  "    unassign it as sa-2-admin@. Sign the daily account out of the Admin console everywhere." \
  "VERIFY: neither daily account is listed; admin.google.com no longer opens for the daily account; rule C mailed." \
  "RECORD: <date>-OB-2.12-daily-super-admin-removed-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-2.12 --witness <second human's email> --note \"<who unassigned which account, and when>\""; }

step OB-2.13 HUMAN "Execute the G3 reduction of every other super admin" --witness --removes --gate "G3-ROSTER"
s_OB_2_13_check() { ckpt_done OB-2.13; }
s_OB_2_13_manual() { ob06_m \
  "HUMAN: each reduced admin tests their new role. WHO: platform owner as sa-1-admin@; the second human confirms each row." \
  "WHERE: Admin console > Account > Admin roles; the G3 decision record (file 03), in its order." \
  "DO, per account: assign the delegated role the decision names; the admin performs one routine task and confirms in" \
  "    writing; then unassign Super Admin. Not ready: keep Super Admin and record a dated hand-over exception signed by" \
  "    the second human (04 section 7.2)." \
  "VERIFY: every row is reduced or carries a signed exception with an expiry; rule C mailed for each change." \
  "RECORD: <date>-OB-2.13-g3-reduction-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-2.13 --witness <second human's email>"; }

step OB-2.14 CONSOLE "Verify the super-admin roster state" --witness
s_OB_2_14_check() { ckpt_done OB-2.14; }
s_OB_2_14_manual() { ob06_m \
  "WHO: platform owner as sa-1-admin@ (clean profile); the second human reads the result." \
  "WHERE: APIs Explorer, users.list, customer $(ob06_val DIRECTORY_CUSTOMER_ID), viewType admin_view, projection full, maxResults 500." \
  "DO: run query isAdmin=true and paste AT ONCE: pbpaste > \"\$BUILD_LOG_DIR/evidence/06/OB-2.14-users-isAdmin.json\"" \
  "    return to the panel, run isDelegatedAdmin=true and paste: ... > OB-2.14-users-isDelegatedAdmin.json" \
  "    (merge every page by hand if nextPageToken). Then run the page's action 3 block (cmp guard and script)." \
  "VERIFY: 'OK two distinct responses', QUERIES DISTINCT and G3 STATE OK; every other super admin has a signed, unexpired" \
  "        exception; a CHECK: line is cleared only by the second human. OB-5.1 builds the roster from these files." \
  "RECORD: <date>-OB-2.14-roster-state-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-2.14 --witness <second human's email>"; }

# ================================================================ Part 3: organisation IAM

step OB-3.1 HUMAN "Sign gcloud in as sa-1-admin@" --needs "SA_1_ADMIN"
s_OB_3_1_check() {   # done once recorded, and only while gcloud is signed in as SA_1_ADMIN (a new sitting signs in again)
  local acct rc
  ckpt_done OB-3.1 || return 1
  acct="$(r gcloud auth list --filter=status:ACTIVE --format='value(account)')"; rc=$?
  [ $rc -eq 3 ] && return 3
  [ $rc -eq 0 ] || return 2
  [ "$acct" = "$(v SA_1_ADMIN)" ]
}
s_OB_3_1_manual() { ob06_m \
  "HUMAN: an interactive sign-in with the security key; the script never opens it." \
  "WHO: platform owner. WHERE: shell with ~/.platform-env sourced; the URL opened in the clean sa-1-admin@ profile." \
  "DO: agp-platform sitting start <second human's email>   (01 PR-3.2's start block; keep the SITTING_ID it prints)" \
  "    gcloud auth login \"$(ob06_val SA_1_ADMIN)\" --no-launch-browser" \
  "    gcloud config set account \"$(ob06_val SA_1_ADMIN)\"; gcloud config get account" \
  "    gcloud organizations list --format=\"table(displayName,name)\"   (may be empty until OB-3.3)" \
  "VERIFY: the browser demands the key; the account is SA_1_ADMIN; agp-platform preflight --phase 06 shows no default project." \
  "The second sitting opens the same way; the first closes after OB-3.4 with: agp-platform sitting end." \
  "THEN: agp-platform done OB-3.1"; }

step OB-3.2 AUTO "Fix the exception expiry and open the deviation entry" \
  --needs "PLATFORM_REPO_DIR ORG_ID SA_1_ADMIN SECOND_HUMAN_EMAIL DEVIATION_REGISTER BUILD_LOG_DIR" \
  --sets "BOOTSTRAP_EXCEPTION_EXPIRY" --gate "SD-01" --witness
s_OB_3_2_check() {
  local c; c="$(ob06_cond)"
  has_value BOOTSTRAP_EXCEPTION_EXPIRY && [ -f "$c" ] || return 1
  ob06_cond_text "$(v BOOTSTRAP_EXCEPTION_EXPIRY)" | cmp -s - "$c" || return 1
  ob06_bd_open BD-06-1
}
s_OB_3_2_apply() {
  local tool exp c probe rc
  tool="$(agp_tool decision-value.sh)"; c="$(ob06_cond)"
  # 1. the expiry, only from the signed SD-01 record (03 DC-4.1), in the two-step form
  if [ "$AGP_MODE" = apply ]; then
    [ -x "$tool" ] || { ob06_say "      STOP: $tool is not installed (setup/03 DC-1.2); nothing written"; return 1; }
    exp="$(r "$tool" SD-01 BOOTSTRAP_EXCEPTION_EXPIRY)" || {
      ob06_say "      STOP: decision-value.sh SD-01 BOOTSTRAP_EXCEPTION_EXPIRY failed (unsigned, or no Values row); nothing written"; return 1; }
    case "$exp" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) ob06_say "      STOP: SD-01's expiry '$exp' is not YYYY-MM-DD"; return 1;; esac
    [ "$(date -u +%F)" \< "$exp" ] || { ob06_say "      STOP: SD-01's expiry $exp is not after today"; return 1; }
  else
    has_value PLATFORM_REPO_DIR || [ -n "${AGP_DECISION_DIR-}" ] || tool="<PLATFORM_REPO_DIR>/tools/decision-value.sh"
    printf '      reads: %s SD-01 BOOTSTRAP_EXCEPTION_EXPIRY (the signed SD-01 record; a refusal stops the step)\n' "$tool" >&3
    exp="$(v BOOTSTRAP_EXCEPTION_EXPIRY)"
  fi
  pset BOOTSTRAP_EXCEPTION_EXPIRY "$exp" || return 1
  # 2. the condition file every exception binding uses; never rewritten once bindings may match it
  x mkdir -p "$(v PLATFORM_REPO_DIR)/identity" || return 1
  if [ "$AGP_MODE" = apply ] && [ -f "$c" ]; then
    if ob06_cond_text "$exp" | cmp -s - "$c"; then ob06_say "      unchanged $c"
    else ob06_say "      STOP: $c exists with other content; bindings match it exactly. Correct it only by the page's" \
                 "      'BOOTSTRAP_EXCEPTION_EXPIRY is reached' row (signed extension, new version, superseding BD-06-1 line)"; return 1; fi
  else
    ob06_cond_text "$exp" | xw "$c" 644 || return 1
  fi
  [ "$AGP_MODE" = apply ] && sed 's/^/      /' "$c" >&3
  # 3. BD-06-1, inserted into the register's first table with 01's bd_insert
  ob06_bd bd_insert "$(ob06_bd_row1)" || return 1
  # 4. 01 section 3.3's role-definition read, kept for OB-3.7 (which reads it again: the script keeps no shell value)
  ob06_plan "gcloud iam roles describe for the five exception roles (01 section 3.3, second block)"
  if [ "$AGP_MODE" = apply ]; then
    probe="$(ob06_p26_probe)"; rc=$?
    if [ $rc -eq 0 ] && [ -n "$probe" ]; then ob06_say "      P-26 probe: $probe"
    elif [ $rc -eq 0 ]; then ob06_say "      STOP (01 section 3.3): no permission is unique to Security Admin; OB-3.7's binding read is the only gate, with a deviation row"
    else agp_warn "OB-3.2: the role definitions could not be read; OB-3.7 reads them again"; fi
  fi
  return 0
}

step OB-3.3 CONSOLE "Grant Organization Administrator to sa-1-admin@, conditioned on the expiry" \
  --needs "ORG_ID SA_1_ADMIN PLATFORM_REPO_DIR BUILD_LOG_DIR BOOTSTRAP_EXCEPTION_EXPIRY" --gate "SD-01" --witness
s_OB_3_3_check() {   # a manual step: the person's `done` is the record. The binding the page's VERIFY reads is read
  # too, and a mismatch is shown; OB-3.7's EXCEPTION EXACT, which covers this role, is the gate that stops on it.
  local rc
  ckpt_done OB-3.3 || return 1
  ob06_withdrawn && return 0
  ob06_exception_ok role roles/resourcemanager.organizationAdmin; rc=$?
  case $rc in
    1) agp_warn "OB-3.3 is recorded, but Organization Administrator on SA_1_ADMIN is not exactly the one binding under bootstrap-exception-sd-01; correct it now (page ROLLBACK, then OB-3.3 again): OB-3.7 stops on it";;
    2) agp_warn "OB-3.3: the organisation policy could not be read to confirm the binding";;
  esac
  return 0
}
s_OB_3_3_manual() { ob06_m \
  "WHO: platform owner as $(ob06_val SA_1_ADMIN), acting as super admin; the second human present." \
  "WHERE: Cloud console, clean sa-1-admin@ profile: IAM & Admin > IAM, resource selector on organisation $(ob06_val ORG_ID)." \
  "DO: Grant access > New principals $(ob06_val SA_1_ADMIN) > Role Resource Manager > Organization Administrator;" \
  "    Add IAM condition: title bootstrap-exception-sd-01, description and Condition editor expression exactly as in" \
  "    $(ob06_val PLATFORM_REPO_DIR)/identity/bootstrap-exception-condition.yaml (OB-3.2). Save." \
  "VERIFY: the page's VERIFY block writes \$BUILD_LOG_DIR/evidence/06/OB-3.3-org-policy.json and prints only" \
  "        roles/resourcemanager.organizationAdmin bootstrap-exception-sd-01 request.time < timestamp(...);" \
  "        no unconditional binding of that role on sa-1-admin@; policy version 3. This step's check reads the same." \
  "RECORD: evidence_add for <date>-OB-3.3-org-admin-exception-v1 (E-05, TISAX 4.2.1)." \
  "THEN: agp-platform done OB-3.3 --witness <second human's email>"; }

step OB-3.4 AUTO-READ "Inventory the organisation's IAM policy and its projects" --needs "ORG_ID BUILD_LOG_DIR"
s_OB_3_4_check() { ckpt_done OB-3.4; }
s_OB_3_4_apply() {
  local d f n org
  d="$(ob06_ev)"; f="$d/OB-3.4-org-policy-before.json"; org="$(v ORG_ID)"
  # OB-3.6's rollback reads this file: never overwrite it. A re-run writes the next free -v<n> file.
  if [ -e "$f" ]; then n=2; while [ -e "${f%.json}-v$n.json" ]; do n=$((n + 1)); done; f="${f%.json}-v$n.json"; ob06_say "      OB-3.4 already captured; writing $f"; fi
  x mkdir -p "$d" || return 1
  ob06_save "$f" gcloud organizations get-iam-policy "$org" --format=json || return 1
  # `gcloud projects list` takes no scope flag: the first list filters on the organisation, the second is the
  # page's 50 most recent projects the account can see.
  ob06_save "$d/OB-3.4-projects-under-organisation.txt" gcloud projects list --filter="parent.type=organization AND parent.id=$org" \
    --sort-by=~createTime --format="table(projectId,createTime,parent.type,parent.id)" || return 1
  ob06_save "$d/OB-3.4-projects-recent.txt" gcloud projects list --sort-by=~createTime --limit=50 \
    --format="table(projectId,createTime,parent.type,parent.id)" || return 1
  ob06_save "$d/OB-3.4-folders.txt" gcloud resource-manager folders list --organization="$org" --format="table(displayName,name)" || return 1
  [ "$AGP_MODE" = apply ] || return 0
  ob06_py inventory "$f" || return 1
  cat "$d/OB-3.4-projects-under-organisation.txt" "$d/OB-3.4-projects-recent.txt" "$d/OB-3.4-folders.txt"
  ob06_say "      Now mark, in the record, every domain: binding and every organizationAdmin, owner/editor, PAM admin," \
          "      orgpolicy.policyAdmin, iam.denyAdmin, logging.configWriter and billing.* binding, with its owner (or *tbd*)." \
          "      No domain: projectCreator/billing.creator binding: record \"already removed, date unknown\" (OB-3.5 and OB-3.6 are then nil)." \
          "      The first sitting closes here: agp-platform sitting end. OB-3.5 runs between the sittings."
  ev OB-3.4 org-iam-inventory E-05 4.2.1 "$f" "$f"
}

step OB-3.5 HUMAN "Confirm that nothing depends on the domain-wide defaults"
s_OB_3_5_check() { ckpt_done OB-3.5; }
s_OB_3_5_manual() { ob06_m \
  "HUMAN: between the two sittings; written answers from the owners OB-3.4 found and from the second human." \
  "DO: for every project created in the last 180 days directly under the organisation, find its owner:" \
  "    gcloud projects get-iam-policy <project-id> --flatten=\"bindings[].members\" --filter=\"bindings.role=roles/owner\" --format=\"value(bindings.members)\"" \
  "    and ask whether anything relies on self-service project or billing-account creation. Send the change notice." \
  "    Write decisions/<date>-remove-organisation-creation-defaults.md in PLATFORM_REPO_DIR, signed by both humans" \
  "    (OB-3.6 refuses to run without it). A named dependency stops OB-3.6 until its owner holds an explicit grant." \
  "Record 'OB-3.5 open, <n> replies outstanding' at the end of the first sitting; the second sitting opens like OB-3.1." \
  "RECORD: <date>-OB-3.5-defaults-dependency-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-3.5 --note \"last reply <date>\""; }

step OB-3.5a AUTO "Preview the removal with Policy Simulator, and list who loses access" \
  --needs "ORG_ID SA_1_ADMIN PLATFORM_REPO_DIR BUILD_LOG_DIR DEVIATION_REGISTER SECOND_HUMAN_EMAIL" --witness --removes
s_OB_3_5a_check() {
  [ -s "$(ob06_ev)/OB-3.5a-replay.json" ] || return 1
  ob06_sim_absent || return $?
  ob06_bd_closed BD-06-5
}
s_OB_3_5a_apply() {
  local d c cur prop rep xc org m exp role out rc replay_ok=1 ans
  d="$(ob06_ev)"; c="$d/OB-3.5a-simulator-condition.yaml"; cur="$d/OB-3.5a-policy-current.json"
  prop="$d/OB-3.5a-policy-proposed.json"; rep="$d/OB-3.5a-replay.json"; xc="$d/OB-3.5a-console-crosscheck.txt"
  org="$(v ORG_ID)"; m="user:$(v SA_1_ADMIN)"
  x mkdir -p "$d" || return 1
  # 1. the two simulator roles, for this sitting only, under their own condition; then BD-06-5
  if [ "$AGP_MODE" = apply ] && [ -f "$c" ]; then
    exp="$(sed -n 's/.*timestamp("\([0-9-]*\)T.*/\1/p' "$c")"
    if [ -n "$exp" ] && [ "$(date -u +%F)" \< "$exp" ]; then ob06_say "      reusing $c (until $exp): a re-run must match the bindings it made"
    else ob06_say "      STOP: $c is from an earlier sitting ($exp); remove any binding it made (action 5's commands) and move it aside first"; return 1; fi
  else
    exp="$(date -u -v+1d +%Y-%m-%d 2>/dev/null || date -u -d tomorrow +%Y-%m-%d)"
    ob06_sim_cond_text "$exp" | xw "$c" || return 1
  fi
  x gcloud organizations add-iam-policy-binding "$org" --member="$m" --role="roles/policysimulator.admin" --condition-from-file="$c" >/dev/null || return 1
  x gcloud organizations add-iam-policy-binding "$org" --member="$m" --role="roles/cloudasset.viewer" --condition-from-file="$c" >/dev/null || return 1
  ob06_bd bd_insert "$(ob06_bd_row5 "$exp")" || return 1
  # 2. the proposed policy: the current one without the domain: bindings of the two creator roles
  ob06_save "$cur" gcloud organizations get-iam-policy "$org" --format=json || return 1
  if [ "$AGP_MODE" = apply ]; then ob06_py proposed "$cur" | xw "$prop" || return 1
  else printf '      would write %s (the current policy without the domain: creator bindings)\n' "$prop" >&3; fi
  # 3. the replay of the last 90 days against the proposal
  out="$(x gcloud iam simulator replay-recent-access "organizations/$org" "$prop" --format=json)"; rc=$?
  if [ "$AGP_MODE" = apply ]; then
    if [ $rc -eq 0 ] && [ -n "$out" ]; then
      printf '%s\n' "$out" | xw "$rep" || return 1
      ob06_py replay_summary "$rep" | sed 's/^/      /' >&3
    else
      replay_ok=0
      agp_warn "OB-3.5a: the replay was refused (VERIFY 3). Grant no further role; the console route below is the fallback."
    fi
    # 4. the console cross-check the second human watches, while the simulator roles are still held. Action 5
    #    removes them, after which the console route can no longer run: without an answer the step stops here.
    #    The answer is kept in a local record, so that a run without a terminal can resume after it.
    ob06_say "      Action 4, now: Cloud console > IAM & Admin > IAM, organisation selected; Edit the domain: principal, revoke" \
            "      Project Creator and Billing Account Creator, click Test changes (never Save); read and screenshot" \
            "      \"Access changes over the past 90 days\"; leave the page without saving."
    if [ -s "$xc" ] && [ ! "$c" -nt "$xc" ]; then
      ans="$(awk 'NR == 1 {print $1}' "$xc")"; ob06_say "      action 4 recorded in $xc: $ans"
    elif ans="$(ob06_tty_answer '      Type DONE when the screenshot is taken (or REFUSED if the console route was refused too):')"; then
      case "$ans" in DONE|REFUSED) printf '%s %s witness %s\n' "$ans" "$(date -u +%FT%TZ)" "$AGP_WITNESS" | xw "$xc" || return 1;; esac
    else
      ob06_say "      STOP: no terminal to record action 4, which must happen while the simulator roles are held. Do it with" \
              "      the second human, then record it (REFUSED instead of DONE if the console route was refused too) and resume:" \
              "      printf '%s %s witness %s\\n' DONE \"\$(date -u +%FT%TZ)\" \"<second human's email>\" > \"$xc\"" \
              "      agp-platform apply --phase 06 --from OB-3.5a --witness <second human's email>"
      return 98
    fi
    case "$ans" in
      DONE) ;;
      REFUSED) [ $replay_ok = 1 ] || replay_ok=-1;;
      *) ob06_say "      STOP: '$ans' is neither DONE nor REFUSED; action 4 is not recorded and the roles stay held. Resume to answer again."
         return 98;;
    esac
  else
    ob06_plan "action 4: the console Test changes cross-check, answered DONE or REFUSED at the terminal and kept in $xc"
  fi
  # 5. remove the two simulator roles again, in this sitting, with the same condition file
  for role in roles/policysimulator.admin roles/cloudasset.viewer; do
    if [ "$AGP_MODE" = apply ] && ! has_binding "$m" "$role" gcloud organizations get-iam-policy "$org"; then continue; fi
    x gcloud organizations remove-iam-policy-binding "$org" --member="$m" --role="$role" --condition-from-file="$c" >/dev/null || return 1
  done
  [ "$AGP_MODE" = apply ] || { ob06_bd bd_close BD-06-5 "withdrawal: 06 OB-3.5a action 5" "06 OB-3.5a VERIFY 2"; return 0; }
  if ob06_sim_absent; then ob06_say "      SIMULATOR ROLES REMOVED"; else ob06_say "      FAIL: a simulator role is still bound to SA_1_ADMIN"; return 1; fi
  if [ $replay_ok != 1 ]; then
    ob06_say "      The replay was refused: BD-06-5 stays open. If the console route was refused too, close it as superseded" \
            "      by the next free BD-06 id carrying \"preview refused: OB-3.6 proceeds on OB-3.5's written confirmations alone\"," \
            "      signed by the second human; then continue with: agp-platform apply --phase 06 --from OB-3.6"
    return 1
  fi
  ob06_bd bd_close BD-06-5 "withdrawal: 06 OB-3.5a action 5" "06 OB-3.5a VERIFY 2" || return 1
  ev OB-3.5a removal-preview E-05 4.2.1 "$rep" "$rep"
}

step OB-3.6 AUTO "Remove Project Creator and Billing Account Creator from the whole domain" \
  --needs "ORG_ID BUILD_LOG_DIR PLATFORM_REPO_DIR" --witness --removes
s_OB_3_6_check() {
  local pol rc
  pol="$(ob06_policy_json)"; rc=$?
  [ $rc -eq 3 ] && return 3
  [ $rc -eq 0 ] || return 2
  printf '%s' "$pol" | ob06_py domain_left >/dev/null
}
s_OB_3_6_apply() {
  local d before out gen after org pairs pair rec ans
  d="$(ob06_ev)"; before="$d/OB-3.4-org-policy-before.json"; out="$d/OB-3.6-removed-domain-bindings.json"
  gen="$d/OB-3.6-remove-commands.sh"; after="$d/OB-3.6-org-policy-after.json"; org="$(v ORG_ID)"
  if [ "$AGP_MODE" != apply ]; then
    ob06_plan "gates: OB-3.5's signed change record, OB-3.5a's replay summary, SIMULATOR ROLES REMOVED; the removals come from $before"
    x gcloud organizations remove-iam-policy-binding "$org" --member="domain:<EACH_DOMAIN_OF_OB-3.4_BEFORE_POLICY>" --role="roles/resourcemanager.projectCreator" --condition=None
    x gcloud organizations remove-iam-policy-binding "$org" --member="domain:<EACH_DOMAIN_OF_OB-3.4_BEFORE_POLICY>" --role="roles/billing.creator" --condition=None
    return 0
  fi
  # the three gates of the page, checked before the first command
  [ -s "$before" ] || { ob06_say "      STOP: re-run OB-3.4; its before-policy is the source of this step"; return 1; }
  rec="$(ls "$(v PLATFORM_REPO_DIR)"/decisions/*-remove-organisation-creation-defaults.md 2>/dev/null | tail -n 1)"
  [ -n "$rec" ] || { ob06_say "      STOP: gate 1: OB-3.5's change record decisions/<date>-remove-organisation-creation-defaults.md is missing"; return 1; }
  ob06_say "      gate 1: $rec (signed by both humans, no dependency open: read it now)"
  if [ -s "$d/OB-3.5a-replay.json" ]; then ob06_py replay_summary "$d/OB-3.5a-replay.json" | sed 's/^/      gate 2: /' >&3
  else ob06_say "      gate 2: no replay file; OB-3.5a's console route or its BD-06 superseding row stands in"; fi
  ob06_sim_absent || { ob06_say "      STOP: gate 3: a simulator role is still bound to SA_1_ADMIN (OB-3.5a action 5)"; return 1; }
  ob06_say "      gate 3: SIMULATOR ROLES REMOVED"
  # 1. what will be removed, generated from the before-policy (every domain, never typed from DOMAIN)
  ob06_py removal_rows "$before" | xw "$out" || return 1
  # 2. one command per unconditional row; conditional rows stay, under their own signed change record
  ob06_py removal_cmds "$out" "$org" | xw "$gen" || return 1
  sed 's/^/      /' "$gen" >&3
  pairs="$(ob06_py removal_pairs "$out")" || return 1
  if [ -n "$pairs" ]; then
    ans="$(ob06_tty_answer '      The second human reads the commands above and the three gates. Type REMOVE to run them:')" || {
      ob06_say "      STOP: no terminal; the second human must read the commands before they run"; return 1; }
    [ "$ans" = REMOVE ] || { ob06_say "      STOP: not confirmed"; return 1; }
  fi
  for pair in $pairs; do
    x gcloud organizations remove-iam-policy-binding "$org" --member="${pair%%|*}" --role="${pair#*|}" --condition=None >/dev/null || return 1
  done
  ob06_save "$after" gcloud organizations get-iam-policy "$org" --format=json || return 1
  ob06_py defaults_removed "$before" "$after" "$out" | sed 's/^/      /' >&3 || {
    ob06_say "      Where the diff names OB-3.3's, OB-3.5a's or OB-3.7's bindings, tick them off by hand and record it (page VERIFY)."; return 1; }
  ev OB-3.6 defaults-removed E-05 4.2.1 "$after" "$after"
}

step OB-3.7 AUTO "Grant Folder Creator, Project Creator, PAM Admin and Security Admin to sa-1-admin@ under the same condition" \
  --needs "ORG_ID SA_1_ADMIN PLATFORM_REPO_DIR BUILD_LOG_DIR BOOTSTRAP_EXCEPTION_EXPIRY" --gate "SD-01" --witness
ob06_exception_roles() { echo roles/resourcemanager.organizationAdmin roles/resourcemanager.folderCreator roles/resourcemanager.projectCreator roles/privilegedaccessmanager.admin roles/iam.securityAdmin; }
# shellcheck disable=SC2046
s_OB_3_7_check() { ob06_withdrawn && return 0; ob06_exception_ok exact $(ob06_exception_roles); }
s_OB_3_7_apply() {
  local c f role probe prc b out arc
  c="$(ob06_cond)"; f="$(ob06_ev)/OB-3.7-org-policy.json"
  if [ "$AGP_MODE" = apply ] && [ ! -f "$c" ]; then ob06_say "      STOP: $c is missing; run OB-3.2"; return 1; fi
  for role in roles/resourcemanager.folderCreator roles/resourcemanager.projectCreator roles/privilegedaccessmanager.admin roles/iam.securityAdmin; do
    x gcloud organizations add-iam-policy-binding "$(v ORG_ID)" --member="user:$(v SA_1_ADMIN)" --role="$role" --condition-from-file="$c" >/dev/null || return 1
  done
  x mkdir -p "$(ob06_ev)" || return 1
  ob06_save "$f" gcloud organizations get-iam-policy "$(v ORG_ID)" --format=json || return 1
  ob06_plan "the page's VERIFY on that file: EXCEPTION EXACT (five roles on SA_1_ADMIN, each once, each under bootstrap-exception-sd-01)"
  [ "$AGP_MODE" = apply ] || { printf '      $ api POST %s (the P-26 probe of 01 section 3.3)\n' "https://cloudresourcemanager.googleapis.com/v3/organizations/$(v ORG_ID):testIamPermissions" >&3; return 0; }
  # the page's VERIFY on the saved policy: EXCEPTION EXACT, which is also 01 section 3.3's binding read: five roles,
  # each once, each under bootstrap-exception-sd-01, nothing else on SA_1_ADMIN
  # shellcheck disable=SC2046
  ob06_py exception_state "user:$(v SA_1_ADMIN)" "$(v BOOTSTRAP_EXCEPTION_EXPIRY)" exact $(ob06_exception_roles) < "$f" | sed 's/^/      /' >&3 || {
    ob06_say "      SA_1_ADMIN does not hold exactly the five roles, each once under bootstrap-exception-sd-01; 07 does not start"; return 1; }
  # the probe permission, unique to Security Admin, must resolve on the organisation
  probe="$(ob06_p26_probe)"; prc=$?
  if [ $prc -ne 0 ] || [ -z "$probe" ]; then
    agp_warn "OB-3.7: no P-26 probe (role definitions unreadable or no permission unique to Security Admin): the binding read is the only gate; add a deviation row (01 section 3.3)"
  else
    b="$(mktemp "${TMPDIR:-/tmp}/agp-p26.XXXXXX")" || return 1
    printf '{"permissions":["%s"]}' "$probe" > "$b"
    out="$(api POST "https://cloudresourcemanager.googleapis.com/v3/organizations/$(v ORG_ID):testIamPermissions" "$b")"; arc=$?
    rm -f "$b"
    if [ $arc -ne 0 ]; then
      agp_warn "OB-3.7: testIamPermissions refused $probe ($out): record that, keep the binding read as the only gate, add a deviation row (01 section 3.3)"
    elif printf '%s' "$out" | grep -qF "\"$probe\""; then ob06_say "      P-26 probe granted: $probe"
    else ob06_say "      FAIL: the P-26 probe $probe is not granted on the organisation; 07 does not start"; return 1; fi
  fi
  ev OB-3.7 org-exception E-05 4.2.1 "$f" "$f"
}

# ================================================================ Part 4: break-glass OU and accounts

step OB-4.1 CONSOLE "Create /Automation/Break-Glass" --sets "BREAK_GLASS_OU"
s_OB_4_1_check() { ckpt_done OB-4.1; }
s_OB_4_1_manual() { ob06_m \
  "WHO: platform owner as sa-1-admin@." \
  "WHERE: Admin console > Directory > Organizational units; Billing > License settings." \
  "DO: if /Automation is missing, create it under the top OU (\"Non-human and break-glass accounts\"); if it exists, record" \
  "    its settings and change nothing. Under it create Break-Glass (\"Cloud break-glass accounts, 04 section 7.1, P69\")." \
  "    License settings: Break-Glass, Workspace subscription Off, Override." \
  "VERIFY: /Automation/Break-Glass exists, empty, with the licence override." \
  "RECORD (type it): penv_set BREAK_GLASS_OU \"/Automation/Break-Glass\"; screenshots <date>-OB-4.1-break-glass-ou-v1." \
  "THEN: agp-platform done OB-4.1"; }

step OB-4.2 CONSOLE "2-Step Verification and session controls on BREAK_GLASS_OU"
s_OB_4_2_check() { ckpt_done OB-4.2; }
s_OB_4_2_manual() { ob06_m \
  "WHO: platform owner as sa-1-admin@." \
  "WHERE: Admin console, OU Break-Glass: Security > Authentication > 2-step verification; Security > Access and data" \
  "       control > Google session control; Google Cloud session control." \
  "DO: exactly OB-2.2's and OB-2.3's values: 2SV On, Only security key, trust device off, no security codes, enrolment" \
  "    period at least 8 days; shortest web session; Google Cloud reauthentication every 1 hour with Security key." \
  "VERIFY: screenshots of the three pages match the page's settings table." \
  "RECORD: <date>-OB-4.2-break-glass-policies-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-4.2"; }

step OB-4.3 HUMAN "Create brk-gcp-1@ and brk-gcp-2@" --sets "BRK_GCP_1 BRK_GCP_2" --witness
s_OB_4_3_check() { ckpt_done OB-4.3; }
s_OB_4_3_manual() { ob06_m \
  "HUMAN: passwords set by their custodians: the second human for brk-gcp-1@, the platform owner for brk-gcp-2@." \
  "WHO: platform owner as sa-1-admin@ creates both; the vault administrator confirms each entry's access list." \
  "DO, per account: primary email brk-gcp-<n>@$(ob06_val DOMAIN), OU /Automation/Break-Glass, no secondary email or phone," \
  "    generated password, change at next sign-in; send details to nobody. The custodian pastes the initial password" \
  "    once and sets a vault-generated one from an entry only they can read; the other person does not look." \
  "VERIFY: no recovery information, no Workspace licence, no admin role; the vault administrator confirms in writing." \
  "RECORD (type it): penv_set BRK_GCP_1 \"brk-gcp-1@\${DOMAIN}\"; penv_set BRK_GCP_2 \"brk-gcp-2@\${DOMAIN}\"" \
  "THEN: agp-platform done OB-4.3 --witness <second human's email>"; }

step OB-4.4 HUMAN "Enrol one key on each break-glass account, prove it, and add them to rule A" --witness
s_OB_4_4_check() { ckpt_done OB-4.4; }
s_OB_4_4_manual() { ob06_m \
  "HUMAN: hardware keys over two sittings. brk-gcp-1@: second human signs in, platform owner enrols and keeps the key;" \
  "       brk-gcp-2@: the reverse. Both present for both." \
  "DO: first sitting: enrol the key (label brk-gcp-1 / brk-gcp-2), serial on the custody form, key sealed temporarily in" \
  "    the safe. Edit rule A (OB-2.6): add both accounts to the Actor filter. Second sitting (7 days later, in the" \
  "    enrolment period): sign in with each key, open console.cloud.google.com only, sign out." \
  "VERIFY: APIs Explorer users.list, customer $(ob06_val DIRECTORY_CUSTOMER_ID), query orgUnitPath=/Automation/Break-Glass," \
  "    viewType admin_view, projection full; pbpaste > \"\$BUILD_LOG_DIR/evidence/06/OB-4.4-break-glass-users.json\";" \
  "    the page's script prints BREAK-GLASS KEYS PROVEN (the checked prerequisite of OB-7.1). Rule A mailed each sign-in." \
  "THEN: agp-platform done OB-4.4 --witness <second human's email>"; }

# ================================================================ Part 5: the roster file and the control-group list

step OB-5.1 AUTO "Write ROSTER_FILE" \
  --needs "DOMAIN DIRECTORY_CUSTOMER_ID ORG_ID SA_1_ADMIN SA_2_ADMIN BRK_GCP_1 BRK_GCP_2 ADMIN_OU BREAK_GLASS_OU BOOTSTRAP_EXCEPTION_EXPIRY PLATFORM_REPO_DIR BUILD_LOG_DIR" \
  --sets "ROSTER_FILE"
s_OB_5_1_check() {
  local f; f="$(v PLATFORM_REPO_DIR)/identity/super-admin-roster.json"
  has_value ROSTER_FILE && [ -s "$f" ] || return 1
  ob06_py roster_ok "$f" "$(ob06_ev)/OB-2.14-users-isDelegatedAdmin.json" >/dev/null 2>&1
}
s_OB_5_1_apply() {
  local a b f
  a="$(ob06_ev)/OB-2.14-users-isAdmin.json"; b="$(ob06_ev)/OB-2.14-users-isDelegatedAdmin.json"
  f="$(v PLATFORM_REPO_DIR)/identity/super-admin-roster.json"
  ob06_plan "the OB-2.14 guard: cmp of the two responses, and every user of the delegated file has isDelegatedAdmin"
  if [ "$AGP_MODE" = apply ]; then
    # the page's gate and STOP lines: each is a person's paste to redo at OB-2.14 (98: a person must act first)
    [ -s "$a" ] && [ -s "$b" ] || { ob06_say "      STOP: OB-2.14's two files are missing; re-run OB-2.14"; return 98; }
    if cmp -s "$a" "$b"; then ob06_say "      STOP: OB-2.14 pasted one response twice; re-run OB-2.14"; return 98; fi
    ob06_say "      OK two distinct responses"
    ob06_py delegated_file_ok "$b" | sed 's/^/      /' >&3 || return 98
  fi
  pset ROSTER_FILE "identity/super-admin-roster.json" || return 1
  x mkdir -p "$(v PLATFORM_REPO_DIR)/identity" || return 1
  if [ "$AGP_MODE" = apply ] && [ -e "$f" ]; then
    ob06_say "      kept $f: it exists, and a hand-edited roster is never overwritten (rewrite it by hand, OB-5.1 ROLLBACK)"
  elif [ "$AGP_MODE" = apply ]; then
    env DOMAIN="$(v DOMAIN)" DIRECTORY_CUSTOMER_ID="$(v DIRECTORY_CUSTOMER_ID)" ORG_ID="$(v ORG_ID)" \
      SA_1_ADMIN="$(v SA_1_ADMIN)" SA_2_ADMIN="$(v SA_2_ADMIN)" BRK_GCP_1="$(v BRK_GCP_1)" BRK_GCP_2="$(v BRK_GCP_2)" \
      ADMIN_OU="$(v ADMIN_OU)" BREAK_GLASS_OU="$(v BREAK_GLASS_OU)" BOOTSTRAP_EXCEPTION_EXPIRY="$(v BOOTSTRAP_EXCEPTION_EXPIRY)" \
      python3 -c "$(ob06_src_roster)" "$b" | xw "$f" || return 1
  else
    printf '      would write %s (the page'"'"'s roster: two admins, two break-glass accounts, the delegated admins of OB-2.14)\n' "$f" >&3
    return 0
  fi
  if grep -q '<role name' "$f"; then
    ob06_say "      Edit $f by hand: replace each <role name from OB-2.13> with the delegated role name(s) from the OB-1.3" \
            "      table as changed by OB-2.13, and add one exceptions entry per signed hand-over exception" \
            "      (email, role, until, decision). Then: agp-platform apply --phase 06 --from OB-5.1"
    return 98
  fi
  ob06_py roster_ok "$f" "$b" | sed 's/^/      /' >&3
}

step OB-5.2 AUTO "Write CONTROL_GROUPS_FILE" \
  --needs "DOMAIN SA_1_ADMIN SA_2_ADMIN BRK_GCP_1 BRK_GCP_2 SECOND_HUMAN_EMAIL PLATFORM_REPO_DIR" \
  --sets "CONTROL_GROUPS_FILE GRP_GCP_ORG_ADMINS GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY GRP_PLATFORM_APPROVERS GRP_PLATFORM_READERS GRP_GE_ADMINS GRP_GE_USERS GRP_EVE_OWNERS" \
  --gate "SD-12 SD-18"
ob06_grp_values() { local n; for n in $(ob06_grp_names); do v "$n"; echo; done; }
s_OB_5_2_check() {
  local f n; f="$(v PLATFORM_REPO_DIR)/identity/control-groups.json"
  has_value CONTROL_GROUPS_FILE && [ -s "$f" ] || return 1
  for n in $(ob06_grp_names); do has_value "$n" || return 1; done
  # shellcheck disable=SC2046
  ob06_py control_groups_ok "$f" $(ob06_grp_values) >/dev/null
}
s_OB_5_2_apply() {
  local f d; f="$(v PLATFORM_REPO_DIR)/identity/control-groups.json"; d="$(v DOMAIN)"
  pset CONTROL_GROUPS_FILE "identity/control-groups.json" || return 1
  x mkdir -p "$(v PLATFORM_REPO_DIR)/identity" || return 1
  if [ "$AGP_MODE" = apply ] && [ -e "$f" ]; then
    ob06_say "      kept $f: it exists and is not overwritten before the OB-5.4 merge (rewrite it by hand, OB-5.2 ROLLBACK)"
  elif [ "$AGP_MODE" = apply ]; then
    env DOMAIN="$d" SA_1_ADMIN="$(v SA_1_ADMIN)" SA_2_ADMIN="$(v SA_2_ADMIN)" BRK_GCP_1="$(v BRK_GCP_1)" BRK_GCP_2="$(v BRK_GCP_2)" \
      SECOND_HUMAN_EMAIL="$(v SECOND_HUMAN_EMAIL)" INCIDENT_COMMANDER_EMAIL="$(has_value INCIDENT_COMMANDER_EMAIL && _penv_get INCIDENT_COMMANDER_EMAIL)" \
      python3 -c "$(ob06_src_control_groups)" | xw "$f" || return 1
  else
    printf '      would write %s (the eight groups of the page)\n' "$f" >&3
  fi
  pset GRP_GCP_ORG_ADMINS "gcp-organization-admins@$d" || return 1
  pset GRP_PLATFORM_OWNERS "platform-owners@$d" || return 1
  pset GRP_PLATFORM_SECURITY "platform-security@$d" || return 1
  pset GRP_PLATFORM_APPROVERS "platform-approvers@$d" || return 1
  pset GRP_PLATFORM_READERS "platform-readers@$d" || return 1
  pset GRP_GE_ADMINS "ge-admins@$d" || return 1
  pset GRP_GE_USERS "ge-users@$d" || return 1
  pset GRP_EVE_OWNERS "eve-owners@$d" || return 1
  [ "$AGP_MODE" = apply ] || return 0
  # shellcheck disable=SC2046
  ob06_py control_groups_ok "$f" $(ob06_grp_values) | sed 's/^/      /' >&3
}

step OB-5.3 HUMAN "Check the roster file against the live tenant" --witness
s_OB_5_3_check() { ckpt_done OB-5.3; }
s_OB_5_3_manual() { ob06_m \
  "HUMAN: the second human repeats it on their own workstation, as sa-2-admin@, from the pushed branch; the platform" \
  "       owner's output is not accepted in place of theirs." \
  "WHERE: APIs Explorer users.list (customer $(ob06_val DIRECTORY_CUSTOMER_ID), viewType admin_view, projection full, 500)." \
  "DO: FRESH reads, never OB-2.14's files: isAdmin=true, paste at once:" \
  "    pbpaste > \"\$BUILD_LOG_DIR/evidence/06/OB-5.3-live-isAdmin.json\"; then isDelegatedAdmin=true > OB-5.3-live-isDelegatedAdmin.json" \
  "    Then run the page's action 3 block (cmp guards and the comparison with ROSTER_FILE)." \
  "VERIFY: 'OK two distinct responses', no FAIL line, and ROSTER MATCHES LIVE TENANT, from today's reads, on both workstations." \
  "RECORD: <date>-OB-5.3-roster-live-check-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-5.3 --witness <second human's email>"; }

step OB-5.4 HUMAN "Commit, and merge with the second human as required reviewer" --witness
s_OB_5_4_check() { ckpt_done OB-5.4; }
s_OB_5_4_manual() { ob06_m \
  "HUMAN: two human approvals (the second human as CODEOWNER, and a second approver); never a bot or service account." \
  "DO: git -C \"\$PLATFORM_REPO_DIR\" switch -c identity/roster-and-control-groups" \
  "    git -C \"\$PLATFORM_REPO_DIR\" add identity/super-admin-roster.json identity/control-groups.json identity/bootstrap-exception-condition.yaml decisions/" \
  "    git -C \"\$PLATFORM_REPO_DIR\" commit -m \"identity: super-admin roster, control-group list, SD-01 exception condition (file 06)\"" \
  "    git -C \"\$PLATFORM_REPO_DIR\" push -u origin identity/roster-and-control-groups" \
  "    Open the pull request with the OB-5.3 and OB-2.14 outputs; merge after both approvals." \
  "VERIFY: the page's fetch / log / diff block: the merge is on the default branch and the diff is empty." \
  "RECORD: merge commit id (the gate of OB-6.2), pull-request URL, approvers; <date>-OB-5.4-roster-merge-v1." \
  "THEN: agp-platform done OB-5.4 --witness <second human's email> --note \"merge <commit>\""; }

# ================================================================ Part 6: the control groups

step OB-6.1 AUTO-READ "Check that none of the group addresses is taken" \
  --needs "GRP_GCP_ORG_ADMINS GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY GRP_PLATFORM_APPROVERS GRP_PLATFORM_READERS GRP_GE_ADMINS GRP_GE_USERS GRP_EVE_OWNERS"
s_OB_6_1_check() { ckpt_done OB-6.1; }
s_OB_6_1_apply() {
  local n g rc bad=0
  for n in $(ob06_grp_names); do
    g="$(v "$n")"
    ob06_grp_lookup "$g"; rc=$?
    case $rc in
      0) ob06_say "      EXISTS $g"; bad=1;;
      1) ob06_say "      free   $g";;
      4) ob06_say "      free   $g (console search must confirm: the lookup was denied with \"may not exist\")";;
      3) ;;
      *) ob06_say "      ERROR  $g: the read failed (a quota project? then use the console search only and record it)"; bad=1;;
    esac
  done
  [ "$AGP_MODE" = apply ] || { ob06_plan "gcloud identity groups describe for each of the eight addresses"; return 0; }
  ob06_say "      Also search each address in Admin console > Directory > Groups and Directory > Users (a user or an alias)." \
          "      An address that exists stops OB-6.2 for that group until a signed adoption or rename record exists."
  return $bad
}

step OB-6.2 CONSOLE "Create the groups as security groups" --irreversible --witness --gate "SD-18"
s_OB_6_2_check() { ckpt_done OB-6.2; }
s_OB_6_2_manual() { ob06_m \
  "IRREVERSIBLE: a security group cannot be changed back to a Google Group. Before each save confirm: the OB-5.4 merge lists" \
  "  the group with security_label true; OB-6.1 showed it free (or a signed adoption record); the spelling equals the list." \
  "WHO: platform owner as sa-1-admin@; the second human watches each save." \
  "WHERE: Admin console > Directory > Groups > Create group, for the eight groups of CONTROL_GROUPS_FILE, in its order." \
  "DO: name = local part, email and description (purpose) from the list; owners none, except eve-owners@ owned by" \
  "    $(ob06_val SA_2_ADMIN); Labels: tick Security; who can join: only invited users; external members not allowed;" \
  "    who can post: organisation members only; who can view members: group managers. Create group." \
  "VERIFY: Directory > Groups filtered on the Security label lists the eight groups (OB-6.4 checks labels and members)." \
  "RECORD: <date>-OB-6.2-groups-created-v1 in EVIDENCE_INTERIM_LOCATION." \
  "THEN: agp-platform done OB-6.2 --witness <second human's email>"; }

step OB-6.3 CONSOLE "Add the members from the merged list" --witness
s_OB_6_3_check() { ckpt_done OB-6.3; }
s_OB_6_3_manual() { ob06_m \
  "WHO: platform owner as sa-1-admin@; for eve-owners@ the second human (its owner, as sa-2-admin@) confirms on screen." \
  "WHERE: Admin console > Directory > Groups > the group > Members > Add members." \
  "DO: add exactly the members of the merged CONTROL_GROUPS_FILE, as Member (Owner for sa-2-admin@ in eve-owners@)." \
  "    ge-users@ stays empty (file 19). Add nobody else; a removal is itself a control-group change, recorded here." \
  "VERIFY: OB-6.4. RECORD: a build-log line per group." \
  "THEN: agp-platform done OB-6.3 --witness <second human's email>"; }

step OB-6.4 AUTO-READ "Verify groups against the merged list" \
  --needs "GRP_GCP_ORG_ADMINS GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY GRP_PLATFORM_APPROVERS GRP_PLATFORM_READERS GRP_GE_ADMINS GRP_GE_USERS GRP_EVE_OWNERS CONTROL_GROUPS_FILE PLATFORM_REPO_DIR BUILD_LOG_DIR" --witness
s_OB_6_4_check() { ckpt_done OB-6.4; }
s_OB_6_4_apply() {
  local d n g
  d="$(ob06_ev)/OB-6.4"
  x mkdir -p "$d" || return 1
  for n in $(ob06_grp_names); do
    g="$(v "$n")"
    ob06_save "$d/$g.describe.json" gcloud identity groups describe "$g" --format=json || return 1
    ob06_save "$d/$g.members.json" gcloud identity groups memberships list --group-email="$g" --format=json || return 1
  done
  [ "$AGP_MODE" = apply ] || return 0
  ob06_py groups_match "$(v PLATFORM_REPO_DIR)/$(v CONTROL_GROUPS_FILE)" "$d" | sed 's/^/      /' >&3 || return 1
  ob06_say "      The second human re-runs this check on their own workstation."
  ev OB-6.4 groups-verified E-08 4.2.1 "$d"
}

# ================================================================ Part 7: break-glass roles and custody

step OB-7.1 AUTO "Grant standing Organization Administrator and PAM Admin to gcp-organization-admins@" \
  --needs "ORG_ID GRP_GCP_ORG_ADMINS BUILD_LOG_DIR" --witness
# BREAK-GLASS ROLES EXACT (the page's VERIFY): the two roles, unconditioned, and nothing else on the group
s_OB_7_1_check() { ob06_policy_state breakglass_state "group:$(v GRP_GCP_ORG_ADMINS)" >/dev/null; }
s_OB_7_1_apply() {
  local m org f
  m="group:$(v GRP_GCP_ORG_ADMINS)"; org="$(v ORG_ID)"; f="$(ob06_ev)/OB-7.1-org-policy.json"
  # The page's gate, checked here so that a resume (`--from OB-7.1`) cannot skip it: standing Organization
  # Administrator is never granted to a group whose members' second factor has not been proven.
  ob06_gate OB-4.4 "its VERIFY printed BREAK-GLASS KEYS PROVEN" || return 1
  ob06_gate OB-6.4 "it printed GROUPS MATCH LIST for gcp-organization-admins@" || return 1
  # --condition=None, as the page names it: the organisation policy holds conditional bindings by now (OB-3.3,
  # OB-3.7); these two bindings are standing by design.
  x gcloud organizations add-iam-policy-binding "$org" --member="$m" --role="roles/resourcemanager.organizationAdmin" --condition=None >/dev/null || return 1
  x gcloud organizations add-iam-policy-binding "$org" --member="$m" --role="roles/privilegedaccessmanager.admin" --condition=None >/dev/null || return 1
  x mkdir -p "$(ob06_ev)" || return 1
  ob06_save "$f" gcloud organizations get-iam-policy "$org" --format=json || return 1
  ob06_plan "the page's VERIFY on that file: BREAK-GLASS ROLES EXACT (the two roles, unconditioned, nothing else on the group)"
  [ "$AGP_MODE" = apply ] || return 0
  ob06_py breakglass_state "$m" < "$f" | sed 's/^/      /' >&3 || {
    ob06_say "      the group's organisation roles are not exactly the two standing roles"; return 1; }
  ev OB-7.1 break-glass-roles E-08 4.2.1 "$f" "$f"
}

step OB-7.2 HUMAN "Prove one break-glass account reaches the organisation, then rotate its password" --witness
s_OB_7_2_check() { ckpt_done OB-7.2; }
s_OB_7_2_manual() { ob06_m \
  "HUMAN: a password is typed and rotated. brk-gcp-1@: the second human types the password, the platform owner the key." \
  "DO: sign in as brk-gcp-1@; console.cloud.google.com, organisation, IAM & Admin > IAM; change nothing; sign out." \
  "    Rotate: as sa-1-admin@, Directory > Users > brk-gcp-1@ > Reset password, change-at-next-sign-in off, Create password;" \
  "    the second human enters a new vault-generated value while the platform owner looks away, and saves the vault entry" \
  "    before closing the dialogue." \
  "    PROVE IT NOW: sign in again with the new password and the key; the Cloud console opens; sign out. If it fails," \
  "    reset again at once from a fresh vault value, both still present." \
  "VERIFY: two rule-A mails; the password change in User log events between them; vault entry modified after the reset;" \
  "        DRILL_CALENDAR holds the next quarterly drill with brk-gcp-2@." \
  "THEN: agp-platform done OB-7.2 --witness <second human's email>"; }

step OB-7.3 HUMAN "Seal the break-glass keys with cross-line custodians" --witness --gate "SD-27"
s_OB_7_3_check() { ckpt_done OB-7.3; }
s_OB_7_3_manual() { ob06_m \
  "HUMAN: at the safe. Per account: key custodian, password custodian and the PPL-EW envelope witness." \
  "  brk-gcp-1@: key = platform owner, password = second human, witness from IT security other than the second human." \
  "  brk-gcp-2@: key = second human, password = platform owner, witness a non-admin Digital Workplace colleague." \
  "DO: key from its temporary envelope into a new tamper-evident envelope with a card (account, key label); seal; serial" \
  "    and date; paper record with three signatures; safe and safe log; scan the record the same day as" \
  "    <date>-custody-brk-gcp-<n>-v1 (SD-27). No witness: WAITING envelope witness, seal nothing." \
  "VERIFY: the safe log lists both, plus the two spare-key envelopes; nobody is key and password custodian of one account." \
  "THEN: agp-platform done OB-7.3 --witness <envelope witness's email>"; }

step OB-7.4 AUTO-READ "Verify the break-glass state end to end" --needs "GRP_GCP_ORG_ADMINS BRK_GCP_1 BRK_GCP_2 BUILD_LOG_DIR" --witness
s_OB_7_4_check() { ckpt_done OB-7.4; }
s_OB_7_4_apply() {
  local g mem want a grp bad=0 f rec
  g="$(v GRP_GCP_ORG_ADMINS)"; f="$(ob06_ev)/OB-7.4-break-glass-verified.txt"
  # the group address and the member addresses are the scope of these Cloud Identity reads
  ob06_plan "gcloud identity groups memberships list --group-email=$g; search-transitive-groups for each break-glass account"
  [ "$AGP_MODE" = apply ] || return 0
  mem="$(r gcloud identity groups memberships list --group-email="$g" --format="value(preferredMemberKey.id)" | tr 'A-Z' 'a-z' | sort)" || return 1
  want="$(printf '%s\n%s\n' "$(v BRK_GCP_1)" "$(v BRK_GCP_2)" | tr 'A-Z' 'a-z' | sort)"
  rec="$(printf '== members of %s\n%s' "$g" "$mem")"
  if [ "$mem" = "$want" ]; then ob06_say "      OK $g holds exactly the two break-glass accounts"; else ob06_say "      FAIL $g members: $(echo "$mem" | tr '\n' ' ')"; bad=1; fi
  for a in "$(v BRK_GCP_1)" "$(v BRK_GCP_2)"; do
    grp="$( { r gcloud identity groups memberships search-transitive-groups --member-email="$a" --labels="cloudidentity.googleapis.com/groups.discussion_forum" --format="value(groupKey.id)" \
           && r gcloud identity groups memberships search-transitive-groups --member-email="$a" --labels="cloudidentity.googleapis.com/groups.security" --format="value(groupKey.id)"; } | tr 'A-Z' 'a-z' | sort -u)" || { bad=1; continue; }
    rec="$(printf '%s\n== groups of %s\n%s' "$rec" "$a" "$grp")"
    if [ "$grp" = "$(echo "$g" | tr 'A-Z' 'a-z')" ]; then ob06_say "      OK $a belongs to $g only"; else ob06_say "      FAIL $a groups: $(echo "$grp" | tr '\n' ' ')"; bad=1; fi
  done
  printf '%s\n' "$rec" | xw "$f" || return 1
  ob06_say "      Then, in the APIs Explorer, roleAssignments.list with userKey = each break-glass address: an empty result;" \
          "      check each account's Groups section on its Admin console page by eye; OB-7.1 printed BREAK-GLASS ROLES EXACT;" \
          "      both envelopes are sealed (OB-7.3)."
  [ $bad = 0 ] || return 1
  ev OB-7.4 break-glass-verified E-08 4.2.1 "$f" "$f"
}

# ================================================================ Part 8: close and hand over

step OB-8.1 AUTO-READ "Check the produced variables" \
  --needs "SA_1_ADMIN SA_2_ADMIN ADMIN_OU BREAK_GLASS_OU BRK_GCP_1 BRK_GCP_2 GRP_GCP_ORG_ADMINS GRP_PLATFORM_OWNERS GRP_PLATFORM_SECURITY GRP_PLATFORM_APPROVERS GRP_PLATFORM_READERS GRP_GE_ADMINS GRP_GE_USERS GRP_EVE_OWNERS ROSTER_FILE CONTROL_GROUPS_FILE BOOTSTRAP_EXCEPTION_EXPIRY"
s_OB_8_1_check() { ckpt_done OB-8.1; }
s_OB_8_1_apply() {
  local envf names
  envf="${PLATFORM_ENV_FILE:-$HOME/.platform-env}"
  ob06_plan "the value names in $envf, for a secret-like name"
  [ "$AGP_MODE" = apply ] || return 0
  ob06_say "      06 VARIABLES COMPLETE"   # the runner ran need on every name above before this step
  # Only the value lines are searched: the file's own helper code names PASSWORD, SECRET and TOKEN in its refusals.
  names="$(sed -n 's/^export \([A-Z0-9_]*\)=.*/\1/p' "$envf" | grep -Ei 'password|secret|backup|token')"
  if [ -z "$names" ]; then ob06_say "      no secret-like names"; return 0; fi
  ob06_say "      FAIL secret-like names in $envf: $(echo "$names" | tr '\n' ' ')"
  return 1
}

step OB-8.2 HUMAN "Register evidence, the deviation and the re-run points" --witness
s_OB_8_2_check() { ckpt_done OB-8.2; }
s_OB_8_2_manual() { ob06_m \
  "WHO: platform owner; the second human reads and initials the entries." \
  "DO: one EVIDENCE_REGISTER line per EVIDENCE record of setup/06 (the script already registered OB-3.4, OB-3.5a," \
  "    OB-3.6, OB-3.7, OB-6.4, OB-7.1 and OB-7.4: add the others with evidence_add)." \
  "    Confirm BD-06-1 (open until file 12), BD-06-2 (if used), BD-06-3 (closed by OB-2.10a), BD-06-4 (if opened)," \
  "    BD-06-5 (closed by OB-3.5a); each open one names owner and expiry. Placement check:" \
  "    awk -F' *[|] *' '\$2 ~ /^BD-06-/ && NF==15 {print NR, \$2}' \"\$DEVIATION_REGISTER\" (lines before '## Closures')." \
  "    DRILL_CALENDAR: quarterly break-glass drill (brk-gcp-2@ first), weekly interim-rule check (OB-8.4)." \
  "    Confirm README's re-run index (ROSTER_FILE updates in 10, 24, 30, 38; rule retirement after 28; expiry in 12)." \
  "VERIFY: OB-* register lines equal the evidence records produced; the second human initials the build-log line." \
  "THEN: agp-platform done OB-8.2 --witness <second human's email>"; }

step OB-8.3 HUMAN "End the sitting without leaving credentials behind"
s_OB_8_3_check() { ckpt_done OB-8.3; }
s_OB_8_3_manual() { ob06_m \
  "HUMAN: revoking the credentials of the shell that runs this script; each human on their own workstation." \
  "DO: agp-platform sitting end   (01 PR-3.2's block: sitting_end, then checkpoint SITTING-... DONE \"credentials revoked\")" \
  "    Sign out of every admin and break-glass browser profile; confirm every key is on its holder or in the safe." \
  "VERIFY: SITTING-END OK; the last two SITTING- lines of checkpoints.tsv carry the same id, START then DONE;" \
  "        the safe log balances (record it in the build log)." \
  "THEN: agp-platform done OB-8.3"; }

step OB-8.4 HUMAN "Weekly check of the interim rules by the second human (standing until file 28)" --on-unmet skip
s_OB_8_4_check() { ckpt_done OB-8.4; }
s_OB_8_4_manual() { ob06_m \
  "HUMAN: the second human alone, weekly, on a day they choose; the platform owner is not told the day." \
  "WHERE: Admin console as sa-2-admin@: Home > Rules; Reporting > Audit and investigation > User log events." \
  "DO: confirm rules A, B, C (and D) exist, are active and keep OB-2.6's recipients; compare the week's User log events" \
  "    for the four roster accounts with the mails received. A login without a mail, an edited rule or a new super admin" \
  "    goes the same day to the incident commander (or security reviewer), not to the platform owner." \
  "VERIFY: one dated line per week in the second human's own record, until EVE_H_LIVE_RECORD (file 28)." \
  "THEN (once the standing check is in DRILL_CALENDAR): agp-platform done OB-8.4"; }
