#!/usr/bin/env python3.12
"""fm-zero-diff: compare a hand-made module equivalent with its run spec (setup 17, SD-01).

  fm-zero-diff.py inputs SPEC.json [--report FILE]
      the spec against the register row, register/folders.yaml, the signed NAMES register,
      the parent folder's effective gcp.restrictServiceUsage allow-list and the tier budget table.
  fm-zero-diff.py live SPEC.json [--report FILE] [--accept-pending]
      the live project and its platform entries against the spec.

Exit 0 only when every check is PASS (or PENDING with --accept-pending, recorded in the report).
Read-only. Never reads a secret payload. Environment: ~/.platform-env sourced.
Register files are YAML (16 RG-2.2: one document per agent, agent_id plus a rows[] array, one row
per env); they are read with the PyYAML interpreter 16 RG-2.1 installed, never with a regex.
"""
import json, os, re, subprocess, sys, hashlib, datetime, pathlib

ENV = os.environ
REPO = pathlib.Path(ENV["PLATFORM_REPO_DIR"])
REGISTER_PY = ENV.get("REGISTER_VENV_PYTHON", os.path.expanduser("~/platform/venv-register/bin/python"))
MA_ENV = dict(os.environ, CLOUDSDK_API_ENDPOINT_OVERRIDES_MODELARMOR="https://modelarmor.googleapis.com/")
BUDGET = {("r", "prod"): 100, ("r", "nonprod"): 50, ("w", "prod"): 300, ("w", "nonprod"): 150,
          ("p", "prod"): 500, ("p", "nonprod"): 250, ("p-sa", "prod"): 500, ("p-sa", "nonprod"): 250,
          ("ctl", "prod"): 200, ("ctl", "nonprod"): 100, ("imp", "prod"): 200, ("imp", "nonprod"): 100,
          ("core", "prod"): 300}
ALWAYS_ALLOWED = {"iam.googleapis.com", "logging.googleapis.com", "monitoring.googleapis.com"}
results = []

def gc(*args, env=None):
    p = subprocess.run(["gcloud", *args, "--format=json"], capture_output=True, text=True, env=env)
    if p.returncode != 0:
        return None, (p.stderr.strip().splitlines() or ["error"])[-1][:300]
    out = p.stdout.strip()
    return (json.loads(out) if out else []), None

def rec(check, ok, expected, actual, spec):
    pend = [x for x in spec.get("pending", []) if x.get("check") == check]
    status = "PASS" if ok else ("PENDING" if pend else "FAIL")
    results.append({"check": check, "status": status, "expected": expected, "actual": actual,
                    "pending": pend[0] if pend else None})

def yaml_doc(path):
    """Read a YAML file as JSON through the PyYAML virtual environment of 16 RG-2.1."""
    p = subprocess.run([REGISTER_PY, "-c",
                        "import json,sys,yaml; json.dump(yaml.safe_load(open(sys.argv[1])), sys.stdout)",
                        str(REPO / path)], capture_output=True, text=True)
    if p.returncode != 0:
        return None, (p.stderr.strip().splitlines() or ["yaml read failed"])[-1][:300]
    return json.loads(p.stdout or "null"), None

def register_row(path, env):
    """16 RG-2.2's shape: one document, agent_id at the top, rows[] with one member per env."""
    doc, err = yaml_doc(path)
    if not isinstance(doc, dict):
        return None, err or "register file is not a mapping"
    if "rows" not in doc or not isinstance(doc.get("rows"), list):
        return None, "no rows[] array (16 RG-2.2 requires agent_id and rows)"
    match = [r for r in doc["rows"] if isinstance(r, dict) and r.get("env") == env]
    if len(match) != 1:
        return None, f"{len(match)} rows with env={env}, expected 1"
    row = dict(match[0])
    row["agent_id"] = doc.get("agent_id")
    return row, None

def folders_yaml():
    ids, cur = {}, None
    for line in (REPO / "register/folders.yaml").read_text().splitlines():
        m = re.match(r"\s*- variable:\s*(\S+)", line)
        if m: cur = m.group(1)
        m = re.match(r'\s*id:\s*"(\d+)"', line)
        if m and cur: ids[cur] = m.group(1)
    return ids

def check_inputs(s):
    row, rerr = register_row(s["register_row"], s["env"])
    rec("row.found", row is not None, "one rows[] member with this env", rerr or "found", s)
    row = row or {}
    for k, sk in (("agent_id", "agent_id"), ("env", "env"), ("tier", "register_tier")):
        rec(f"row.{k}", row.get(k) == s[sk], s[sk], row.get(k), s)
    anc = subprocess.run(["git", "-C", str(REPO), "merge-base", "--is-ancestor", s["register_commit"], "origin/main"])
    rec("row.commit_on_main", anc.returncode == 0, "ancestor of origin/main", anc.returncode, s)
    if s.get("manifest"):
        sha = hashlib.sha256((REPO / s["manifest"]).read_bytes()).hexdigest()
        rec("manifest.sha", row.get("manifest_sha") == sha, sha, row.get("manifest_sha"), s)
    if s["create"]:
        p = subprocess.run([str(REPO / "tools/decision-value.sh"), "NAMES", s["project_variable"]], capture_output=True, text=True)
        rec("names.project_id", p.stdout.strip() == s["project_id"], s["project_id"], p.stdout.strip(), s)
        pid = s["project_id"]
        rec("project_id.form", bool(re.fullmatch(r"agp-(r|w|p|psa|x|ctl|imp|core|ge)-[a-z0-9-]*[a-z0-9]", pid)) and 6 <= len(pid) <= 30,
            "agp-<tiercode>-..., 6-30 chars (02 3.6)", pid, s)
    fid = ENV.get(s["parent_folder_variable"], "")
    rec("parent.folders_yaml", folders_yaml().get(s["parent_folder_variable"]) == fid and fid != "", fid, folders_yaml().get(s["parent_folder_variable"]), s)
    pol, err = gc("org-policies", "describe", "gcp.restrictServiceUsage", f"--folder={fid}", "--effective")
    allowed = set()
    for r in (pol or {}).get("spec", {}).get("rules", []):
        allowed |= set(r.get("values", {}).get("allowedValues", []))
    extra = sorted(set(s["services"]) - allowed - ALWAYS_ALLOWED)
    rec("services.subset_of_folder_allowlist", not extra and err is None, "no service outside the allow-list", extra or err, s)
    for k, v in s["labels"].items():
        rec(f"label.{k}.alphabet", bool(re.fullmatch(r"[a-z0-9_-]{0,63}", v)), "label alphabet, 63 chars", v, s)
    key = (s["labels"]["tier"], s["env"])
    want = BUDGET.get(key)
    ok = s["budget"]["amount"] == want or bool(s["budget"].get("reason_if_not_tier_default"))
    rec("budget.tier_default", ok, want, s["budget"]["amount"], s)
    rec("labels.factory_run", s["labels"].get("factory_run") == s["run_id"], s["run_id"], s["labels"].get("factory_run"), s)
    # Deny entries: no placeholder may reach FM-2.15, and every exception key must be a rule the entry visits.
    for i, de in enumerate(s.get("deny_entries", [])):
        principals = [de["principal"]] + [p for lst in de.get("exceptions", {}).values() for p in lst]
        bad = [p for p in principals
               if not re.fullmatch(r"(principal|principalSet)://[A-Za-z0-9._/-]+", p)
               or re.search(r"[<>]|PROJECT_NUMBER|\bafter FM-", p)]
        rec(f"deny_entry.{i}.principal_form", not bad, "resolved principal or principalSet URI", bad, s)
        nums = re.findall(r"/projects/(\d+)", " ".join(principals))
        rec(f"deny_entry.{i}.project_number", all(n.isdigit() and len(n) >= 6 for n in nums) and bool(nums) if s["create"] else True,
            "a real project number (FM-2.4)", nums, s)
        stray = sorted(set(de.get("exceptions", {}).keys()) - set(de["rules"]))
        rec(f"deny_entry.{i}.exception_rules_visited", not stray,
            "every exception key is in rules[] (FM-2.15 only visits rules[])", stray, s)
    pf = s.get("project_floor")
    rec("floor.declared", isinstance(pf, dict) and ("applies" in pf), "a project_floor block (FM-2.12a)", pf, s)
    if isinstance(pf, dict) and pf.get("applies") is False:
        owned = [x for x in (s.get("made_elsewhere", []) + s.get("pending", []))
                 if "floor" in json.dumps(x).lower() and (x.get("file") or x.get("owner"))]
        rec("floor.not_applicable_is_owned", bool(pf.get("reason")) and bool(owned),
            "a reason plus a made_elsewhere or pending line naming the file or owner", [pf.get("reason"), owned], s)
    if isinstance(pf, dict) and pf.get("applies") is not False and pf.get("vertex_ai") is False:
        rec("floor.vertex_absence_matches_services", "aiplatform.googleapis.com" not in s["services"] and bool(pf.get("reason")),
            "vertex_ai false only where aiplatform is not enabled, with a reason", [pf.get("reason"), "aiplatform.googleapis.com" in s["services"]], s)

def check_live(s):
    pid, reg = s["project_id"], ENV["REGION"]
    p, err = gc("projects", "describe", pid)
    p = p or {}
    num = p.get("projectNumber", "")
    fid = ENV.get(s["parent_folder_variable"], "")
    rec("project.parent", p.get("parent", {}) == {"type": "folder", "id": fid}, f"folder {fid}", p.get("parent") or err, s)
    rec("project.state", p.get("lifecycleState") == "ACTIVE", "ACTIVE", p.get("lifecycleState"), s)
    rec("project.labels", p.get("labels", {}) == s["labels"], s["labels"], p.get("labels"), s)
    eff, _ = gc("resource-manager", "tags", "bindings", "list", f"--parent=//cloudresourcemanager.googleapis.com/projects/{num}", "--effective")
    got = {}
    for t in eff or []:
        parts = t.get("namespacedTagValue", "").split("/")
        if len(parts) >= 3: got[parts[-2]] = parts[-1]
    rec("tags.effective", all(got.get(k) == v for k, v in s["tags_effective"].items()), s["tags_effective"], got, s)
    direct, _ = gc("resource-manager", "tags", "bindings", "list", f"--parent=//cloudresourcemanager.googleapis.com/projects/{num}")
    rec("tags.none_direct", not direct, [], direct, s)
    b, err = gc("billing", "projects", "describe", pid)
    rec("billing.link", (b or {}).get("billingEnabled") is True and (b or {}).get("billingAccountName") == f"billingAccounts/{ENV['BILLING_ACCOUNT_ID']}",
        ENV["BILLING_ACCOUNT_ID"], b or err, s)
    sv, err = gc("services", "list", "--enabled", f"--project={pid}")
    enabled = {x["config"]["name"] for x in sv or []}
    want = set(s["services"])
    rec("services.exact", enabled - set(s["service_dependencies"]) == want, sorted(want), sorted(enabled) if sv is not None else err, s)
    lr = s["log_routing"]
    d, err = gc("logging", "sinks", "describe", "_Default", f"--project={pid}")
    rec("logging.default_route", (d or {}).get("destination") == f"logging.googleapis.com/projects/{pid}/locations/{lr['location']}/buckets/{lr['default_bucket']}", lr, (d or {}).get("destination") or err, s)
    bk, err = gc("logging", "buckets", "describe", lr["default_bucket"], f"--location={lr['location']}", f"--project={pid}")
    rec("logging.default_bucket_retention", (bk or {}).get("retentionDays") == lr["retention_days"], lr["retention_days"], (bk or {}).get("retentionDays") or err, s)
    rq, err = gc("logging", "sinks", "describe", "_Required", f"--project={pid}")
    rec("logging.required_global", str((rq or {}).get("destination", "")).endswith("/locations/global/buckets/_Required"), "global _Required", (rq or {}).get("destination") or err, s)
    if lr["trace_bucket"]:
        tb, err = gc("observability", "buckets", "list", f"--location={reg}", f"--project={pid}")
        rec("trace.bucket", any(str(x.get("name", "")).endswith(f"/locations/{reg}/buckets/_Trace") for x in tb or []), f"_Trace in {reg}", tb if tb is not None else err, s)
    bu, err = gc("billing", "budgets", "list", f"--billing-account={ENV['BILLING_ACCOUNT_ID']}", f"--billing-project={ENV['CICD_PROJECT']}")
    mine = [x for x in bu or [] if x.get("displayName") == s["budget"]["display_name"]]
    ok = len(mine) == 1 and str(mine[0].get("amount", {}).get("specifiedAmount", {}).get("units")) == str(s["budget"]["amount"]) \
        and mine[0].get("budgetFilter", {}).get("projects") in ([f"projects/{pid}"], [f"projects/{num}"]) and len(mine[0].get("thresholdRules", [])) == 4
    rec("budget", ok, s["budget"], mine or err, s)
    ec, err = gc("essential-contacts", "list", f"--project={pid}", f"--billing-project={ENV['CICD_PROJECT']}")
    have = {(x["email"], tuple(sorted(x.get("notificationCategorySubscriptions", [])))) for x in ec or []}
    wantc = {(c["email"], tuple(sorted(c["categories"]))) for c in s["essential_contacts"]}
    rec("essential_contacts", have == wantc, sorted(wantc), sorted(have) if ec is not None else err, s)
    sa, err = gc("iam", "service-accounts", "list", f"--project={pid}")
    emails = {x["email"].split("@")[0] for x in sa or []}
    rec("service_accounts.exact", emails == set(s["service_accounts"]), sorted(s["service_accounts"]), sorted(emails) if sa is not None else err, s)
    for e in sorted(emails):
        k, _ = gc("iam", "service-accounts", "keys", "list", f"--iam-account={e}@{pid}.iam.gserviceaccount.com", "--managed-by=user", f"--project={pid}")
        rec(f"service_account.{e}.no_user_keys", not k, [], k, s)
    pol, err = gc("projects", "get-iam-policy", pid)
    humans, unexpected = [], []
    want_b = {(x["role"], x["member"]) for x in s["project_bindings"]}
    seen = set()
    for bnd in (pol or {}).get("bindings", []):
        for m in bnd.get("members", []):
            seen.add((bnd["role"], m))
            if m.split(":")[0] in ("user", "group", "domain") or m in ("allUsers", "allAuthenticatedUsers"):
                if m not in s["allowed_human_members"]: humans.append((bnd["role"], m))
            elif m.startswith("serviceAccount:") and (bnd["role"], m) not in want_b:
                if not re.search(r"@(gcp-sa-[a-z0-9-]+|cloudservices|container-engine-robot|cloudbuild|serverless-robot-prod)\.iam\.gserviceaccount\.com$|@cloudservices\.gserviceaccount\.com$", m):
                    unexpected.append((bnd["role"], m))
            if bnd["role"] in ("roles/owner", "roles/editor") and m not in s["allowed_human_members"]:
                humans.append((bnd["role"], m))
    rec("iam.no_human_or_basic_role", not humans, [], humans if pol is not None else err, s)
    rec("iam.no_unexpected_service_account", not unexpected, [], unexpected, s)
    rec("iam.spec_bindings_present", want_b <= seen, sorted(want_b), sorted(want_b - seen), s)
    if s["lien"]:
        li, err = gc("alpha", "resource-manager", "liens", "list", f"--project={pid}")
        rec("lien", any("resourcemanager.projects.delete" in x.get("restrictions", []) for x in li or []), "delete lien", li if li is not None else err, s)
    ch, err = gc("beta", "monitoring", "channels", "list", f"--project={pid}")
    have_ch = {(x.get("type"), x.get("displayName")) for x in ch or []}
    rec("channels", {(c["type"], c["display_name"]) for c in s["notification_channels"]} <= have_ch, s["notification_channels"], sorted(have_ch) if ch is not None else err, s)
    ts = s.get("trigger_sink")
    if ts:
        sk, err = gc("logging", "sinks", "describe", ts["name"], f"--project={ENV['LOGGING_PROJECT']}")
        dest = f"pubsub.googleapis.com/projects/{pid}/topics/{ts['topic']}"
        fsha = hashlib.sha256((sk or {}).get("filter", "").encode()).hexdigest()
        rec("trigger_sink.destination_filter", (sk or {}).get("destination") == dest and fsha == ts["filter_sha256"], [dest, ts["filter_sha256"]], [(sk or {}).get("destination"), fsha] if sk else err, s)
        tp, err = gc("pubsub", "topics", "get-iam-policy", ts["topic"], f"--project={pid}")
        pubs = [m for b2 in (tp or {}).get("bindings", []) if b2["role"] == "roles/pubsub.publisher" for m in b2["members"]]
        rec("trigger_sink.writer_publisher", (sk or {}).get("writerIdentity") in pubs, (sk or {}).get("writerIdentity"), pubs or err, s)
    for de in s["deny_entries"]:
        dp, err = gc("iam", "policies", "get", de["policy_id"], f"--attachment-point={de['attachment_point']}", "--kind=denypolicies")
        for rid in de["rules"]:
            rules = [r for r in (dp or {}).get("rules", []) if r.get("description", "").startswith(rid + " ")]
            ok = len(rules) == 1 and de["principal"] in rules[0].get("denyRule", {}).get("deniedPrincipals", [])
            rec(f"deny.{de['policy_id']}.{rid}", ok, de["principal"], "present" if ok else (err or "absent"), s)
            for ex in de.get("exceptions", {}).get(rid, []):
                ok2 = len(rules) == 1 and ex in rules[0].get("denyRule", {}).get("exceptionPrincipals", [])
                rec(f"deny.{de['policy_id']}.{rid}.exception", ok2, ex, "present" if ok2 else "absent", s)
    for pb in s["pab_bindings"]:
        bd, err = gc("iam", "policy-bindings", "describe", pb["binding_id"], f"--{pb['parent_type']}={pb['parent_id']}", "--location=global")
        ok = (bd or {}).get("policy") == pb["policy"] and (bd or {}).get("target", {}).get("principalSet") == pb["principal_set"]
        rec(f"pab.{pb['binding_id']}", ok, pb, bd or err, s)
    for op in s["project_org_policies"]:
        po, err = gc("org-policies", "describe", op["constraint"], f"--project={pid}")
        denied = {v for r in (po or {}).get("spec", {}).get("rules", []) for v in r.get("values", {}).get("deniedValues", [])}
        inherit = (po or {}).get("spec", {}).get("inheritFromParent") is True
        rec(f"orgpolicy.{op['constraint']}", set(op["denied"]) <= denied and inherit, op, [sorted(denied), inherit] if po else err, s)
    for dp_ in s["project_deny_policies"]:
        dd, err = gc("iam", "policies", "get", dp_["policy_id"], f"--attachment-point=cloudresourcemanager.googleapis.com/projects/{pid}", "--kind=denypolicies")
        body = json.dumps({"rules": (dd or {}).get("rules", [])}, sort_keys=True)
        committed = json.dumps({"rules": json.loads((REPO / dp_["file"]).read_text())["rules"]}, sort_keys=True)
        rec(f"project_deny.{dp_['policy_id']}", body == committed, dp_["file"], "equal" if body == committed else (err or "differs"), s)
    en, err = gc("pam", "entitlements", "list", f"--project={pid}", "--location=global", f"--billing-project={ENV['CICD_PROJECT']}")
    names = {x["name"].split("/")[-1] for x in en or []}
    rec("entitlements", set(s["entitlements"]) <= names, s["entitlements"], sorted(names) if en is not None else err, s)
    check_floor(s, pid, num)

STRICTER = {"LOW_AND_ABOVE": 3, "MEDIUM_AND_ABOVE": 2, "HIGH": 1}
RAI_TYPES = {"HATE_SPEECH", "HARASSMENT", "DANGEROUS", "SEXUALLY_EXPLICIT"}

def check_floor(s, pid, num):
    """The Model Armor project floor (PF), applied by FM-2.12a; 18 section 2 defines the parameters."""
    pf = s.get("project_floor")
    if not isinstance(pf, dict):
        rec("floor.declared", False, "a project_floor block (FM-2.12a)", pf, s)
        return
    if pf.get("applies") is False:
        rec("floor.not_applicable", bool(pf.get("reason")), "a recorded reason and an owner", pf.get("reason"), s)
        return
    fs, err = gc("model-armor", "floorsettings", "describe",
                 f"--full-uri=projects/{pid}/locations/global/floorSetting", f"--billing-project={pid}", env=MA_ENV)
    fs = fs or {}
    if err:
        rec("floor.read", False, "floorsettings describe succeeds", err, s)
        return
    fc = fs.get("filterConfig", {})
    rec("floor.enforced", fs.get("enableFloorSettingEnforcement") is True, True, fs.get("enableFloorSettingEnforcement"), s)
    pi = fc.get("piAndJailbreakFilterSettings", {})
    want_pi, want_rai = pf.get("pi_confidence", "HIGH"), pf.get("rai_min", "MEDIUM_AND_ABOVE")
    rec("floor.pi", pi.get("filterEnforcement") == "ENABLED"
        and STRICTER.get(pi.get("confidenceLevel"), 9) <= STRICTER.get(want_pi, 0),
        ["ENABLED", f"{want_pi} or stricter"], pi, s)
    rec("floor.malicious_uri", fc.get("maliciousUriFilterSettings", {}).get("filterEnforcement") == "ENABLED",
        "ENABLED", fc.get("maliciousUriFilterSettings"), s)
    rai = fc.get("raiSettings", {}).get("raiFilters", []) or []
    rec("floor.rai", {f.get("filterType") for f in rai} == RAI_TYPES
        and all(STRICTER.get(f.get("confidenceLevel"), 9) <= STRICTER.get(want_rai, 0) for f in rai),
        [sorted(RAI_TYPES), f"{want_rai} or stricter"], rai, s)
    if pf.get("vertex_ai"):
        rec("floor.integration", "AI_PLATFORM" in (fs.get("integratedServices") or []),
            "AI_PLATFORM (the REST name of gcloud's VERTEX_AI)", fs.get("integratedServices"), s)
        ai = fs.get("aiPlatformFloorSetting", {})
        field = "inspectAndBlock" if pf.get("vertex_enforcement") == "INSPECT_AND_BLOCK" else "inspectOnly"
        rec("floor.vertex_enforcement", ai.get(field) is True and ai.get("enableCloudLogging") is True,
            [field, "enableCloudLogging"], ai, s)
        agent = f"serviceAccount:service-{num}@gcp-sa-aiplatform.iam.gserviceaccount.com"
        pol2, err2 = gc("projects", "get-iam-policy", pid)
        mem = {m for b3 in (pol2 or {}).get("bindings", []) if b3["role"] == "roles/modelarmor.user" for m in b3["members"]}
        rec("floor.service_agent_role", mem == {agent}, agent, sorted(mem) if pol2 is not None else err2, s)
    else:
        rec("floor.vertex_absent_reason", bool(pf.get("reason")),
            "a reason for a floor without the VERTEX_AI integration", pf.get("reason"), s)

def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("inputs", "live"):
        print(__doc__); sys.exit(2)
    spec = json.loads(pathlib.Path(sys.argv[2]).read_text())
    (check_inputs if sys.argv[1] == "inputs" else check_live)(spec)
    accept = "--accept-pending" in sys.argv
    bad = [r for r in results if r["status"] == "FAIL" or (r["status"] == "PENDING" and not accept)]
    report = {"tool": "fm-zero-diff", "mode": sys.argv[1], "spec": sys.argv[2], "run_id": spec["run_id"],
              "at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "accept_pending": accept,
              "summary": {k: sum(1 for r in results if r["status"] == k) for k in ("PASS", "FAIL", "PENDING")},
              "zero_diff": not bad, "results": results}
    if "--report" in sys.argv:
        pathlib.Path(sys.argv[sys.argv.index("--report") + 1]).write_text(json.dumps(report, indent=2))
    for r in results:
        print(f"{r['status']:8} {r['check']}")
    print(json.dumps(report["summary"]), "ZERO-DIFF" if not bad else "DIFF")
    sys.exit(0 if not bad else 1)

if __name__ == "__main__":
    main()
