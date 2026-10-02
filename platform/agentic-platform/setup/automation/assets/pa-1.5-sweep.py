#!/usr/bin/env python3
"""Standing-role sweep (04 section 5.2 'verified'). Reads live IAM policies of the organisation, every FLD_* folder,
the five core projects and GEMINI_PROJECT; prints VIOLATION for any user:, group: or domain: member bound to a role
listed in pam/role-columns.txt, conditioned or not, AT EVERY SCOPE, except (a) GRP_GCP_ORG_ADMINS at the organisation
(break-glass, 04 section 7.1, printed as ALLOWED-BREAKGLASS so what break-glass holds is never silent), (b) an explicit row of
pam/role-allow.tsv, printed as ALLOWED, and (c) the conditioned binding of SWEEP_GRANT_MEMBER for SWEEP_GRANT_ROLE
while that grant is active. Only VIOLATION and OWNER lines set the exit code; the ALLOWED lines are the evidence
that the tolerated set is exactly the written-down set.
roles/owner, roles/editor, roles/resourcemanager.folderCreator and roles/privilegedaccessmanager.admin are in
role-columns.txt, so a standing basic role, Folder Creator or PAM Admin on a human, group or domain fails the sweep
at the organisation and on every folder too, not only on projects; the documented exceptions (PAM Admin for
platform-owners@ and gcp-organization-admins@) are allow-list rows, never omissions. Basic roles print with the tag
OWNER rather than VIOLATION so they read at a glance; both set the exit code. The pre-existing Owner of
GEMINI_PROJECT (removed in 19) prints OWNER-TOLERATED and does not fail. Stdlib only (setup/12 PA-1.5)."""
import json, os, subprocess, sys, pathlib
E = os.environ; root = pathlib.Path(__file__).resolve().parents[1]
roles = {l.strip() for l in (root / "role-columns.txt").read_text().splitlines() if l.strip()}
allow = set()  # role, kind, ident (or "*"), member; the fifth column is the reason and is not matched on
for l in (root / "role-allow.tsv").read_text().splitlines()[1:]:
    if l.strip():
        allow.add(tuple(l.split("\t")[:4]))
BASIC = ("roles/owner", "roles/editor")
allow_group = "group:" + E["GRP_GCP_ORG_ADMINS"]
gm, gr = E.get("SWEEP_GRANT_MEMBER", ""), E.get("SWEEP_GRANT_ROLE", "")
scopes = [("organizations", E["ORG_ID"])] + [("folders", E[k]) for k in sorted(E) if k.startswith("FLD_")] \
       + [("projects", E[k]) for k in ("CICD_PROJECT", "CORE_PROJECT", "LOGGING_PROJECT", "KMS_PROJECT", "VALIDATOR_PROJECT", "GEMINI_PROJECT")]
cmd = {"organizations": ["organizations"], "folders": ["resource-manager", "folders"], "projects": ["projects"]}
bad = 0
for kind, ident in scopes:
    r = subprocess.run(["gcloud", *cmd[kind], "get-iam-policy", ident, "--format=json"], capture_output=True, text=True)
    if r.returncode:
        print(f"UNREADABLE {kind}/{ident}: {r.stderr.strip()[:160]}"); bad = 1; continue
    for b in json.loads(r.stdout).get("bindings", []):
        for m in b["members"]:
            if not m.split(":", 1)[0] in ("user", "group", "domain"):
                continue
            cond = (b.get("condition") or {}).get("title", "") or ("conditioned" if b.get("condition") else "")
            if b["role"] not in roles:
                continue
            if (b["role"], kind, ident, m) in allow or (b["role"], kind, "*", m) in allow:
                print(f"ALLOWED {kind}/{ident} {b['role']} {m} {cond}"); continue
            if kind == "organizations" and m == allow_group:
                print(f"ALLOWED-BREAKGLASS {kind}/{ident} {b['role']} {m} {cond}"); continue
            if m == gm and b["role"] == gr and b.get("condition"):
                continue
            if b["role"] in BASIC and kind == "projects" and ident == E["GEMINI_PROJECT"]:
                print(f"OWNER-TOLERATED {kind}/{ident} {b['role']} {m} {cond}"); continue
            print(f"{'OWNER' if b['role'] in BASIC else 'VIOLATION'} {kind}/{ident} {b['role']} {m} {cond}"); bad = 1
print("SWEEP CLEAN" if bad == 0 else "SWEEP NOT CLEAN")
sys.exit(bad)
