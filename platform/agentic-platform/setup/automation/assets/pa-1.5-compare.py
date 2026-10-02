#!/usr/bin/env python3
"""Compare every entitlement in pam/index.tsv with the live entitlement. Prints DIFF lines, EXTRA lines
for live entitlements not in the index, and 'CATALOGUE ZERO DIFF' when clean. Stdlib only (setup/12 PA-1.5)."""
import json, os, subprocess, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[1]
bp = os.environ["CICD_PROJECT"]
def run(args):
    r = subprocess.run(["gcloud", *args, f"--billing-project={bp}", "--format=json"], capture_output=True, text=True)
    if r.returncode: sys.exit(f"ERROR gcloud {' '.join(args)}: {r.stderr.strip()}")
    return json.loads(r.stdout or "null")
def norm(d, alt):
    d = json.loads(json.dumps(d))
    for k in ("name", "createTime", "updateTime", "state", "etag"):
        d.pop(k, None)
    g = d["privilegedAccess"]["gcpIamAccess"]
    g["resource"] = g["resource"].rsplit("/", 1)[0] + "/" + alt.get(g["resource"].rsplit("/", 1)[1], g["resource"].rsplit("/", 1)[1])
    g["roleBindings"] = sorted(({k: v for k, v in b.items() if k != "id"} for b in g["roleBindings"]), key=lambda b: (b["role"], b.get("conditionExpression", "")))
    for e in d.get("eligibleUsers", []):
        e["principals"] = sorted(e.get("principals", []))
    for s in d.get("approvalWorkflow", {}).get("manualApprovals", {}).get("steps", []):
        s.pop("id", None)
        for a in s.get("approvers", []):
            a["principals"] = sorted(a.get("principals", []))
        s["approverEmailRecipients"] = sorted(s.get("approverEmailRecipients", []))
    t = d.setdefault("additionalNotificationTargets", {})
    for k in ("adminEmailRecipients", "requesterEmailRecipients"):
        t[k] = sorted(t.get(k, []))
    return d
rc, seen = 0, {}
for line in (root / "index.tsv").read_text().splitlines()[1:]:
    eid, kind, ident, alt, var, path = line.split("\t")
    flag = {"organizations": "--organization", "folders": "--folder", "projects": "--project"}[kind]
    seen.setdefault((kind, ident), set()).add(eid)
    live = run(["pam", "entitlements", "describe", eid, f"{flag}={ident}", "--location=global"])
    want = json.loads((root / path).read_text())
    amap = {alt: ident} if alt != "-" else {}
    if norm(live, amap) != norm(want, amap):
        rc = 1; print(f"DIFF {eid} {kind}/{ident}")
for (kind, ident), ids in seen.items():
    flag = {"organizations": "--organization", "folders": "--folder", "projects": "--project"}[kind]
    for e in run(["pam", "entitlements", "list", f"{flag}={ident}", "--location=global"]) or []:
        if e["name"].rsplit("/", 1)[1] not in ids:
            rc = 1; print(f"EXTRA {e['name']}")
print("CATALOGUE ZERO DIFF" if rc == 0 else "CATALOGUE DIFFERS")
sys.exit(rc)
