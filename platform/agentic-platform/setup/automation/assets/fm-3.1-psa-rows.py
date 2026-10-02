import glob, os, sys, yaml
for f in sorted(glob.glob(os.path.join(sys.argv[1], "*.yaml"))):
    d = yaml.safe_load(open(f, encoding="utf-8"))
    if not isinstance(d, dict):
        continue
    for r in d.get("rows") or []:
        if r.get("tier") == "P-SA" and r.get("env") == "prod" and r.get("status") != "retired":
            print(os.path.basename(f), d.get("agent_id"), r.get("env"), r.get("status"))
