#!/usr/bin/env bash
# Exercise walle_setup.py without touching Google.
#
# Stubs gcloud, bq and gsutil on PATH, records every invocation, and asserts the
# properties that must hold before anyone runs this against a real tenant. It
# needs no credentials, no project and no network.
#
# Objective restated 2026-09-13; see the platform HLD
# (platform/agentic-platform/01-hld.md §13.1, §18 item 5). The section "the
# super-admin robot" asserts the reversal: the robot is a super admin at the
# tier gate (the hardening check inverted, the roster rule), two OAuth clients
# with one reader each, walle-actions-super and its allowlists, the hard-denied
# list as data handed to the denial suite, and cloud-platform never consented
# (this file is the CI assertion the HLD asks for). A fake Admin SDK Directory
# (WALLE_FAKE_DIRECTORY) drives the Workspace checks without credentials.
#
#   ./selftest.sh
#
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SETUP="$(cd "$HERE/.." && pwd)"
SCRIPT="$SETUP/walle_setup.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

export WALLE_CALL_LOG="$WORK/calls.log"
export PATH="$WORK/bin:$PATH"
mkdir -p "$WORK/bin" "$WORK/repo/config"
: > "$WORK/repo/config/protected_floor.txt"
: > "$WORK/repo/operator_client.json"
( cd "$WORK/repo" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m t ) 2>/dev/null

for tool in gcloud bq gsutil; do
  cat > "$WORK/bin/$tool" <<STUB
#!/usr/bin/env bash
printf '%s' "$tool" >> "\$WALLE_CALL_LOG"
for a in "\$@"; do printf ' %q' "\$a" >> "\$WALLE_CALL_LOG"; done
printf '\n' >> "\$WALLE_CALL_LOG"
case " \$* " in
  # the two cross-project grant mutations (dataset access array, run.invoker):
  # WALLE_STUB_ABSENT answers the way IAM/BigQuery do for a principal the other
  # runbook has not created yet; WALLE_STUB_BREAK answers with any other error.
  *" update --source="*|*" run services add-iam-policy-binding "*)
    if [ -n "\${WALLE_STUB_ABSENT:-}" ]; then echo "ERROR: Service account \${*: -3:1} does not exist." >&2; exit 1; fi
    if [ -n "\${WALLE_STUB_BREAK:-}" ]; then echo "ERROR: (gcloud) PERMISSION_DENIED: caller lacks setIamPolicy" >&2; exit 1; fi
    echo '{}'; exit 0;;
  # verify-check tests feed a project IAM policy, a Cloud Run service policy,
  # a deployed service description or a dataset access array in through these
  # files; everything else answers empty.
  *" projects get-iam-policy "*) if [ -n "\${WALLE_STUB_PROJECT_POLICY:-}" ]; then cat "\$WALLE_STUB_PROJECT_POLICY"; else echo '{"bindings":[]}'; fi; exit 0;;
  *" run services get-iam-policy "*) if [ -n "\${WALLE_STUB_RUN_POLICY:-}" ]; then cat "\$WALLE_STUB_RUN_POLICY"; else echo '{"bindings":[]}'; fi; exit 0;;
  *" run services describe walle-actions "*) if [ -n "\${WALLE_STUB_RUN_DESCRIBE:-}" ]; then cat "\$WALLE_STUB_RUN_DESCRIBE"; exit 0; fi; echo "NOT_FOUND" >&2; exit 1;;
  # 2026-09-13: the band-B service and the per-secret reader policies
  *" run services describe walle-actions-super "*) if [ -n "\${WALLE_STUB_SUPER_DESCRIBE:-}" ]; then cat "\$WALLE_STUB_SUPER_DESCRIBE"; exit 0; fi; echo "NOT_FOUND" >&2; exit 1;;
  *" secrets describe "*) if [ -n "\${WALLE_STUB_SECRETS_EXIST:-}" ]; then echo '{}'; exit 0; fi; echo "NOT_FOUND" >&2; exit 1;;
  *" secrets get-iam-policy "*)
    prev=""; name=""; for a in "\$@"; do if [ "\$prev" = get-iam-policy ]; then name="\$a"; fi; prev="\$a"; done
    if [ -n "\${WALLE_STUB_SECRET_POLICY_DIR:-}" ] && [ -f "\$WALLE_STUB_SECRET_POLICY_DIR/\$name.json" ]; then cat "\$WALLE_STUB_SECRET_POLICY_DIR/\$name.json"; else echo '{"bindings":[]}'; fi; exit 0;;
  *"get-iam-policy"*) echo '{"bindings":[]}'; exit 0;;
  *" show --format=prettyjson "*) if [ -n "\${WALLE_STUB_BQ_SHOW:-}" ]; then cat "\$WALLE_STUB_BQ_SHOW"; else echo '{}'; fi; exit 0;;
  # phases 12b/12c/13b: the reads that must answer for the get-or-create paths
  *" iam roles describe roles/"*) echo '{"includedPermissions":["aiplatform.reasoningEngines.query"]}'; exit 0;;
  *" iam policies get "*) echo "NOT_FOUND" >&2; exit 1;;
  *" sinks describe _Default "*) echo '{"name":"_Default","exclusions":[]}'; exit 0;;
  *" agent-registry agents describe "*) echo '{"name":"wall-e","attributes":{"RuntimeIdentity":"principal://agents.global.org-123456789012.system.id.goog/x","RuntimeReference":"y"}}'; exit 0;;
  *" list "*|*" list-"*|*"list "*) echo '[]'; exit 0;;
  *" describe "*|*" versions access "*) echo "NOT_FOUND" >&2; exit 1;;
esac
echo '{}'; exit 0
STUB
  chmod +x "$WORK/bin/$tool"
done

# a filled-in config, derived from the example so new keys are never missed
sed -e 's|<primary-domain>|example.com|; s|<project-id>|test-walle|' \
    -e 's|<org-id>|123456789012|; s|<billing-account>|AAAAAA-BBBBBB-CCCCCC|' \
    "$SETUP/walle.env.example" > "$WORK/good.env"
python3 - "$WORK" <<'PYEOF'
import re, sys, pathlib
w = sys.argv[1]
p = pathlib.Path(w + "/good.env"); s = p.read_text()
subs = {"WALLE_REPO": w + "/repo",
        "FLOOR_LIST_PATH": w + "/repo/config/protected_floor.txt",
        "OPERATOR_EMAIL": "operator@example.com", "OPERATOR_NAME": "Test Operator",
        "OPERATOR_OAUTH_CLIENT_FILE": w + "/repo/operator_client.json",
        "SANDBOX_ACCOUNTS": "walle-test-01,walle-test-02,walle-test-03",
        "PILOT_OU": "/Pilot", "SANDBOX_OU": "/Automation/Sandbox",
        # phases 12b, 12c, 13b
        "FOLDER_ID": "987654321098",
        "WALLE_FOLDER_ID": "555666777888",
        "CI_DEPLOYER": "ci-deployer@test-walle.iam.gserviceaccount.com",
        # Mo's principal lives in MO_PROJECT, never in Wall-E's project.
        "MO_PRINCIPAL": "serviceAccount:mo-analyst@test-mo.iam.gserviceaccount.com",
        "PROJECT_NUMBER": "111222333444", "REFRESH_TOKEN_VERSION": "7",
        "ACTIONS_URL": "https://walle-actions-abc.a.run.app"}
# The four-project topology (platform/project-topology.md, 2026-09-13). The
# Gemini project's NUMBER is deliberately different from Wall-E's so an engine
# policy built from the wrong number is caught, not passed by coincidence.
# Appended when the example does not carry the key yet, replaced when it does.
topology = {"GEMINI_PROJECT": "test-gemini", "EVE_PROJECT": "test-eve",
            "MO_PROJECT": "test-mo", "GEMINI_PROJECT_NUMBER": "555666777888",
            # 2026-09-13 (P71): the shared Agent Registry's project
            "CORE_PROJECT": "test-core"}
for k, v in topology.items():
    if re.search(r'^export %s=' % k, s, flags=re.M):
        subs[k] = v
    else:
        s += '\nexport %s="%s"\n' % (k, v)
for k, v in subs.items():
    s = re.sub(r'^(export %s=)".*?"' % k, r'\1"%s"' % v, s, flags=re.M)
s = re.sub(r'"<[^"]*>"', '"filled"', s)
p.write_text(s)
PYEOF

pass=0; fail=0
ck() { if [ "$2" = 0 ]; then echo "  ok   $1"; pass=$((pass+1)); else echo "  FAIL $1"; fail=$((fail+1)); fi; }
walle() { python3 "$SCRIPT" "$@"; }
# every verb a mutating gcloud/bq/gsutil call can carry
MUTATING=' (create|delete|update|deploy|add-iam-policy-binding|remove-iam-policy-binding|set-iam-policy|set-policy|import|enable|disable|link|mk|rm) '

# The Agent Runtime REST API has no gcloud group, so deploy, spike and registry
# reach it over HTTP. This harness loads the script as a module, replaces the
# three HTTP entry points with canned answers (one engine, an agent identity,
# the telemetry env), and runs either main(), phase_12_agent() alone, or one
# verify check. Everything else still goes through the stubs on PATH.
cat > "$WORK/harness.py" <<'PYEOF'
import argparse, importlib.util, json, os, sys
script, work, mode = sys.argv[1], sys.argv[2], sys.argv[3]
spec = importlib.util.spec_from_file_location("ws", script)
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
ENGINE = "projects/111222333444/locations/europe-west1/reasoningEngines/4242"
def fake_list(ctx): return [{"name": ENGINE, "displayName": "wall-e"}]
def fake_describe(ctx, engine_id):
    return {"name": ENGINE, "displayName": "wall-e",
            "spec": {"effectiveIdentity": "agents.global.org-123456789012.system.id.goog",
                     "deploymentSpec": {"env": [
                         {"name": "ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS", "value": "false"}]}}}
def fake_http(ctx, method, url, token, payload=None, mutating=True):
    # The payload is logged too, so the engine setIamPolicy BODY can be
    # asserted: which project's service agent it names is the whole point.
    # Under --dry-run the real http_json refuses a mutating non-GET before
    # sending; the fake mirrors that guard so a caller that reaches it with
    # mutating=False, or bypasses it, shows up as an "HTTP POST" line.
    with open(os.environ["WALLE_CALL_LOG"], "a") as h:
        if ctx.dry_run and mutating and method != "GET":
            h.write("HTTP DRYRUN %s %s\n" % (method, url))
            return 0, None
        h.write("HTTP %s %s %s\n" % (method, url, json.dumps(payload) if payload is not None else ""))
    if url.endswith(":getIamPolicy"):
        members = [x for x in os.environ.get("WALLE_STUB_ENGINE_MEMBERS", "").split(",") if x]
        role = "projects/%s/roles/walleEngineQuery" % ctx.need("PROJECT")
        return 200, {"bindings": [{"role": role, "members": members}]} if members else {"bindings": []}
    return 200, {}
m.list_engines, m.describe_engine, m.http_json = fake_list, fake_describe, fake_http
# 2026-09-13: a fake Admin SDK Directory, so the super-admin checks (the
# inverted hardening check, the roster rule, the role assignments) can be
# driven from a JSON file with no credentials. googleapiclient is not needed:
# its HttpError is stubbed the way api_get catches it.
import types
if os.environ.get("WALLE_FAKE_DIRECTORY"):
    gac = types.ModuleType("googleapiclient"); gae = types.ModuleType("googleapiclient.errors")
    class HttpError(Exception):
        def __init__(self, status):
            Exception.__init__(self, "HTTP %s" % status); self.resp = types.SimpleNamespace(status=status)
    gae.HttpError = HttpError; gac.errors = gae
    sys.modules["googleapiclient"] = gac; sys.modules["googleapiclient.errors"] = gae
    D = json.load(open(os.environ["WALLE_FAKE_DIRECTORY"]))
    class Req:
        def __init__(self, fn): self.fn = fn
        def execute(self): return self.fn()
    class Coll:
        def __init__(self, name): self.name = name
        def list_next(self, request, response): return None
        def get(self, userKey=None, projection=None, **kw):
            def fn():
                for u in D.get("users", []):
                    if u["primaryEmail"].lower() == str(userKey).lower(): return u
                raise HttpError(404)
            return Req(fn)
        def list(self, **kw):
            if self.name == "users":
                q = kw.get("query", "")
                us = [u for u in D.get("users", []) if (q != "isAdmin=true" or u.get("isAdmin"))]
                return Req(lambda: {"users": us})
            if self.name == "roles":
                return Req(lambda: {"items": D.get("roles", [])})
            if self.name == "roleAssignments":
                rid = kw.get("roleId")
                return Req(lambda: {"items": [a for a in D.get("roleAssignments", [])
                                              if not rid or a.get("roleId") == rid]})
            if self.name == "privileges":
                return Req(lambda: {"items": [{"privilegeName": n, "serviceId": "s"} for n in D.get("privileges", [])]})
            return Req(lambda: {})
    class Dir:
        def users(self): return Coll("users")
        def roles(self): return Coll("roles")
        def roleAssignments(self): return Coll("roleAssignments")
        def privileges(self): return Coll("privileges")
    m.admin = lambda ctx: Dir()
argv = sys.argv[4:]
CONFIG = os.environ.get("WALLE_HARNESS_CONFIG") or work + "/good.env"
if mode == "main":
    sys.exit(m.main(["--config", CONFIG] + argv))
cfg = m.derive_config(m.load_config(CONFIG))
for key in [k for k in os.environ.get("WALLE_UNSET_KEYS", "").split(",") if k]:
    cfg.pop(key, None)
# KEY=VALUE pairs separated by '|', for the keys a test sets on top of good.env
for pair in [x for x in os.environ.get("WALLE_SET_KEYS", "").split("|") if x]:
    k, v = pair.split("=", 1); cfg[k] = v
cfg.setdefault("ACTIONS_IMAGE", "europe-west1-docker.pkg.dev/test-walle/walle/actions:test")
ns = argparse.Namespace(dry_run="--dry-run" in argv, yes=True, verbose=False, config=None,
                        command="deploy", skip_build=True,
                        skip_deny_policy="--skip-deny-policy" in argv)
ctx = m.Ctx(cfg, ns)
try:
    if mode == "phase12":
        m.phase_12_agent(ctx); sys.exit(0)
    if mode == "phase10":
        m.phase_10_actions(ctx); sys.exit(0)
    if mode == "fn":
        # extra argv are passed through positionally, so a helper that takes
        # (ctx, service, member, foreign) can be exercised on its own
        print(getattr(m, argv[0])(ctx, *argv[1:])); sys.exit(0)
    if mode == "check":
        status, detail = getattr(m, argv[0])(ctx)
        print("%s %s" % (status, detail)); sys.exit(0 if status == "PASS" else 1)
except m.WalleError as exc:
    print("STOPPED: %s" % exc); sys.exit(1)
PYEOF
harness() { python3 "$WORK/harness.py" "$SCRIPT" "$WORK" "$@"; }
# a check whose FAIL text is the thing under test: pipefail must not hide it
checkout() { harness check "$@" 2>/dev/null || true; }
# a repo shaped the way phases 12/12b/12c/13b expect, with a deploy.py that
# records the contract it received instead of deploying anything
mkdir -p "$WORK/repo/agent" "$WORK/repo/dispatcher" "$WORK/repo/drills"
export WALLE_DEPLOY_ENV_LOG="$WORK/deploy_env.json"
cat > "$WORK/repo/agent/deploy.py" <<'PYEOF'
import json, os
keys = ["IDENTITY_TYPE", "SERVICE_ACCOUNT", "AGENT_GATEWAY", "AGENT_ENV_VARS",
        "WALLE_ENGINE_NAME", "WALLE_SPIKE", "ENGINE_DISPLAY_NAME", "MIN_INSTANCES"]
json.dump({k: os.environ.get(k) for k in keys}, open(os.environ["WALLE_DEPLOY_ENV_LOG"], "w"))
PYEOF
printf 'google-auth>=2.45.0\n' > "$WORK/repo/agent/requirements.txt"
printf 'import google.adk\n' > "$WORK/repo/agent/agent.py"
printf 'app.stream_query(x)\n' > "$WORK/repo/dispatcher/main.py"
deploy_env() { python3 -c "import json,sys; d=json.load(open('$WALLE_DEPLOY_ENV_LOG')); v=d.get(sys.argv[1]); print('' if v is None else v)" "$1"; }

echo "=== the script itself"
python3 -m py_compile "$SCRIPT" 2>&1 | head -3; ck "compiles on this python" $?

echo "=== an unedited config cannot do damage"
: > "$WALLE_CALL_LOG"
out="$(walle --config "$SETUP/walle.env.example" --yes gcp 2>&1)"; rc=$?
[ $rc -ne 0 ]; ck "placeholder config is refused" $?
[ ! -s "$WALLE_CALL_LOG" ]; ck "and nothing ran" $?

echo "=== flags work in either position"
walle --config "$WORK/good.env" --dry-run --yes gcp >/dev/null 2>&1; a=$?
walle gcp --config "$WORK/good.env" --dry-run --yes >/dev/null 2>&1; b=$?
[ $a -eq 0 ] && [ $b -eq 0 ]; ck "flags before and after the subcommand" $?

echo "=== dry run cannot mutate"
: > "$WALLE_CALL_LOG"
walle --config "$WORK/good.env" --dry-run --yes gcp >/dev/null 2>&1
! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"
ck "no mutating command during --dry-run" $?

echo "=== a real run does the work"
: > "$WALLE_CALL_LOG"
walle --config "$WORK/good.env" --yes gcp > "$WORK/gcp.out" 2>&1; ck "gcp runs to completion against the stubs" $?
n=$(wc -l < "$WALLE_CALL_LOG" | tr -d ' ')
[ "$n" -gt 40 ]; ck "gcp issued $n commands" $?

echo "=== corrections that were expensive to find"
! grep -q -- "--paused" "$WALLE_CALL_LOG";                  ck "scheduler: no --paused flag" $?
! grep -q "reasoningEngineUser" "$WALLE_CALL_LOG";          ck "no fictional reasoningEngineUser role" $?
! grep -q "bq add-iam-policy-binding" "$WALLE_CALL_LOG";    ck "no bq add-iam-policy-binding on a dataset" $?
! grep -q "replication-policy=automatic" "$WALLE_CALL_LOG"; ck "secrets are not multi-region" $?
grep -q "secrets create.*--location" "$WALLE_CALL_LOG";     ck "secrets are regional" $?
! grep -q "kms keys create" "$WALLE_CALL_LOG";              ck "walle gcp creates no KMS key (Eve's key lives in EVE_PROJECT)" $?
! grep -q "kms keyrings create" "$WALLE_CALL_LOG";          ck "and no key ring" $?
grep -q "roles/datastore.user" "$WALLE_CALL_LOG";           ck "service accounts get project roles" $?
! grep -q "gcloud ai reasoning-engines" "$WALLE_CALL_LOG";  ck "no non-existent gcloud ai group" $?
! grep -qE "gcloud monitoring channels" "$WALLE_CALL_LOG";  ck "monitoring channels via beta" $?

echo "=== four projects: nothing of Eve's or Mo's is created in Wall-E's project"
grep -q "projects create test-walle --folder 555666777888" "$WALLE_CALL_LOG"; ck "the project is created under WALLE_FOLDER_ID, the P-SA tier folder" $?
! grep -q "projects create test-walle --folder 987654321098" "$WALLE_CALL_LOG"; ck "and not directly under the platform folder FOLDER_ID" $?
! grep -q "projects create .*--organization" "$WALLE_CALL_LOG"; ck "and not straight under the organisation" $?
[ "$(grep -c 'service-accounts create ' "$WALLE_CALL_LOG")" = 5 ]; ck "exactly five service accounts created (walle-actions-super added 2026-09-13)" $?
grep -q "service-accounts create walle-actions-super " "$WALLE_CALL_LOG"; ck "walle-actions-super@ is created, in Wall-E's project" $?
! grep -q "service-accounts create eve-controller" "$WALLE_CALL_LOG"; ck "eve-controller@ is not created here" $?
! grep -qE "service-accounts create (eve-|mo-)" "$WALLE_CALL_LOG"; ck "no Eve or Mo identity of any kind" $?
! grep -q "secrets create eve-" "$WALLE_CALL_LOG"; ck "no Eve secret created here" $?
! grep -qE "add-iam-policy-binding test-walle --member serviceAccount:(eve-|mo-)" "$WALLE_CALL_LOG"
ck "no project-level role in Wall-E's project for an Eve or Mo identity" $?
! grep -q "roles/datastore.viewer" "$WALLE_CALL_LOG"; ck "datastore.viewer is not re-granted (decision 44 is open)" $?
! grep -qE "(eve-|mo-)[a-z0-9-]*@test-walle" "$WALLE_CALL_LOG"; ck "no Eve or Mo address is ever spelled in Wall-E's project" $?
grep -q "eve-controller@test-eve.iam.gserviceaccount.com gains roles/bigquery.dataViewer on walle_audit" "$WORK/gcp.out"
ck "eve-controller@EVE_PROJECT gains dataset-level dataViewer on walle_audit" $?
grep -q "eve-v0@test-eve.iam.gserviceaccount.com gains roles/bigquery.dataViewer on walle_audit" "$WORK/gcp.out"
ck "eve-v0@EVE_PROJECT gains it too (S0, topology row 4)" $?
grep -q "mo-metrics@test-mo.iam.gserviceaccount.com gains roles/bigquery.dataViewer on walle_audit" "$WORK/gcp.out" \
  && grep -q "mo-metrics@test-mo.iam.gserviceaccount.com gains roles/bigquery.dataViewer on walle_workspace_logs" "$WORK/gcp.out"
ck "mo-metrics@MO_PROJECT gains dataViewer on walle_audit and walle_workspace_logs" $?
grep -q "bq update --source=.* test-walle:walle_audit" "$WALLE_CALL_LOG" && grep -q "bq update --source=.* test-walle:walle_workspace_logs" "$WALLE_CALL_LOG"
ck "the access array is written on the SOURCE dataset in Wall-E's project" $?
! grep -q "roles/bigquery.jobUser" "$WALLE_CALL_LOG"; ck "jobUser is never granted cross-project (jobs run in the reader's project)" $?
! grep -qE "kms .*--project test-walle" "$WALLE_CALL_LOG"; ck "no KMS command is ever issued against Wall-E's project" $?
! grep -qE "secrets [a-z-]+ eve-(oauth-client|refresh-token) .*--project test-walle" "$WALLE_CALL_LOG"
ck "no Eve secret is ever addressed in Wall-E's project" $?
: > "$WALLE_CALL_LOG"
WALLE_UNSET_KEYS=GEMINI_PROJECT_NUMBER harness fn gemini_project_number >/dev/null 2>&1
grep -q "gcloud projects describe test-gemini --format=json" "$WALLE_CALL_LOG" && ! grep -q -- "--project test-walle" "$WALLE_CALL_LOG"
ck "GEMINI_PROJECT_NUMBER is looked up on GEMINI_PROJECT, never through Wall-E's default project" $?
python3 - "$SCRIPT" "$WORK/good.env" <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
cfg = m.derive_config(m.load_config(sys.argv[2]))
ok = (cfg["SA_EVE"] == "eve-controller@test-eve.iam.gserviceaccount.com"
      and cfg["SA_EVE_VERIFIER"] == "eve-verifier@test-eve.iam.gserviceaccount.com"
      and cfg["SA_MO_METRICS"] == "mo-metrics@test-mo.iam.gserviceaccount.com"
      and cfg["MO_PRINCIPAL"] == "serviceAccount:mo-analyst@test-mo.iam.gserviceaccount.com"
      and "test-walle" not in cfg["SA_EVE"] + cfg["SA_MO_ANALYST"])
sys.exit(0 if ok else 1)
PYEOF
ck "derive_config builds Eve's and Mo's identities from EVE_PROJECT and MO_PROJECT" $?
python3 - "$SCRIPT" "$WORK/good.env" <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
base = m.load_config(sys.argv[2])
same = dict(base); same["EVE_PROJECT"] = same["PROJECT"]
bad_number = dict(base); bad_number["GEMINI_PROJECT_NUMBER"] = "not-a-number"
wrong_mo = dict(base); wrong_mo["MO_PRINCIPAL"] = "serviceAccount:mo-analyst@test-walle.iam.gserviceaccount.com"
# the old placement, written by hand into an explicitly exported Eve key
old_eve = dict(base); old_eve["SA_EVE"] = "eve-controller@test-walle.iam.gserviceaccount.com"
old_v0 = dict(base); old_v0["SA_EVE_V0"] = "eve-v0@test-walle.iam.gserviceaccount.com"
wrong_home = dict(base); wrong_home["SA_EVE_CONSOLE"] = "eve-console@test-mo.iam.gserviceaccount.com"
same_number = dict(base); same_number["GEMINI_PROJECT_NUMBER"] = same_number["PROJECT_NUMBER"]
ok = (not m.validate_config(m.derive_config(dict(base)), "gcp")
      and not m.validate_config(m.derive_config(dict(base)), "deploy")
      and any("both" in p for p in m.validate_config(m.derive_config(same), "gcp"))
      and any("GEMINI_PROJECT_NUMBER" in p for p in m.validate_config(m.derive_config(bad_number), "deploy"))
      and any("MO_PRINCIPAL" in p for p in m.validate_config(m.derive_config(wrong_mo), "deploy"))
      and any("SA_EVE" in p and "Wall-E's own project" in p for p in m.validate_config(m.derive_config(old_eve), "deploy"))
      and any("SA_EVE_V0" in p and "Wall-E's own project" in p for p in m.validate_config(m.derive_config(old_v0), "gcp"))
      and any("SA_EVE_CONSOLE" in p and "not a service account in EVE_PROJECT" in p
              for p in m.validate_config(m.derive_config(wrong_home), "deploy"))
      and any("equals PROJECT_NUMBER" in p for p in m.validate_config(m.derive_config(same_number), "deploy"))
      and "GEMINI_PROJECT" in m.CONFIG_KEYS_FOR_SUBCOMMAND["register"]
      and "GEMINI_PROJECT" in m.CONFIG_KEYS_FOR_SUBCOMMAND["gcp"]
      and "EVE_PROJECT" in m.CONFIG_KEYS_FOR_SUBCOMMAND["gcp"]
      and "MO_PROJECT" in m.CONFIG_KEYS_FOR_SUBCOMMAND["deploy"]
      and "MO_PRINCIPAL" not in m.CONFIG_KEYS_FOR_SUBCOMMAND["registry"]
      and "EVE_ROBOT" not in m.CONFIG_KEYS_FOR_SUBCOMMAND["consent"]
      and all(k in m.REQUIRED_CONFIG_KEYS for k in ("GEMINI_PROJECT", "EVE_PROJECT", "MO_PROJECT")))
sys.exit(0 if ok else 1)
PYEOF
ck "validate_config refuses two keys naming one project, a bad or Wall-E-equal GEMINI_PROJECT_NUMBER, and any Eve or Mo identity outside its home project" $?
: > "$WALLE_CALL_LOG"
walle --config "$WORK/good.env" --yes consent --eve >/dev/null 2>&1; rc=$?
[ $rc -ne 0 ] && [ ! -s "$WALLE_CALL_LOG" ]; ck "consent --eve is refused (Eve's consent is Eve's runbook) and nothing ran" $?
! walle teardown --help 2>&1 | grep -q "destroy-key-versions"; ck "teardown no longer offers --destroy-key-versions" $?

echo "=== phase 10: the cross-project invokers and allowlists"
: > "$WALLE_CALL_LOG"
harness phase10 >/dev/null 2>&1; ck "phase 10 runs against the stubs" $?
for who in eve-controller@test-eve eve-verifier@test-eve eve-console@test-eve mo-analyst@test-mo; do
  grep -q "run services add-iam-policy-binding walle-actions --region europe-west1 --member serviceAccount:$who.iam.gserviceaccount.com --role roles/run.invoker --project test-walle" "$WALLE_CALL_LOG"
  ck "run.invoker on walle-actions (Wall-E's project) for $who" $?
done
! grep -qE "run services add-iam-policy-binding .*(eve-|mo-)[a-z0-9-]*@test-walle" "$WALLE_CALL_LOG"; ck "no invoker for an Eve or Mo account spelled in Wall-E's project" $?
grep 'run deploy walle-actions' "$WALLE_CALL_LOG" | tr -d '\\' | grep -q "CONTROL_CALLER_ALLOWLIST=eve-controller@test-eve.iam.gserviceaccount.com,eve-verifier@test-eve.iam.gserviceaccount.com,walle-operators@example.com"
ck "CONTROL_CALLER_ALLOWLIST carries the EVE_PROJECT emails and the operators" $?
grep 'run deploy walle-actions' "$WALLE_CALL_LOG" | grep -q "EVE_KMS_KEY=projects/test-eve/locations/europe-west1/keyRings/eve/cryptoKeys/eve-approval"
ck "EVE_KMS_KEY points at Eve's key in EVE_PROJECT" $?
! grep 'run deploy walle-actions' "$WALLE_CALL_LOG" | grep -q "keyRings/walle/"; ck "and not at a ring in Wall-E's project" $?
! grep 'run deploy walle-actions' "$WALLE_CALL_LOG" | tr -d '\\' | grep -qE "CONTROL_CALLER_ALLOWLIST=[^;]*(eve-console|mo-analyst)"; ck "read-only callers are not on the control list" $?
grep 'run deploy walle-actions' "$WALLE_CALL_LOG" | tr -d '\\' | grep -qE "READ_CALLER_ALLOWLIST=[^;]*eve-console@test-eve\.iam\.gserviceaccount\.com[^;]*mo-analyst@test-mo\.iam\.gserviceaccount\.com"
ck "READ_CALLER_ALLOWLIST carries eve-console@EVE_PROJECT and mo-analyst@MO_PROJECT" $?
! grep 'run deploy walle-actions' "$WALLE_CALL_LOG" | tr -d '\\' | grep -qE "READ_CALLER_ALLOWLIST=[^;]*(eve-|mo-)[a-z0-9-]*@test-walle"; ck "and no Eve or Mo address spelled in Wall-E's project" $?
grep 'run deploy walle-actions' "$WALLE_CALL_LOG" | grep -q "EVE_PUBLIC_KEY_PEM=/app/contracts/eve-public-keys"; ck "EVE_PUBLIC_KEY_PEM names the pinned-PEM directory (the primary verification input)" $?
: > "$WALLE_CALL_LOG"
harness phase10 --dry-run >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"; ck "phase 10 --dry-run issues no mutating command (the foreign run.invoker path included)" $?

echo "=== the Cloud Run env flag survives email-shaped values"
python3 - "$SCRIPT" <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
try: spec.loader.exec_module(m)
except SystemExit: pass
fn = getattr(m, "env_flag_value", None)
if not fn: print("  SKIP env_flag_value not found"); sys.exit(0)
out = fn([("ROBOT_ACCOUNT", "walle@example.com"),
          ("CONTROL_CALLER_ALLOWLIST", "eve@a.iam.gserviceaccount.com,ops@example.com")])
delim = out[1] if out.startswith("^") else ","
body = out[3:] if out.startswith("^") else out
bad = [t for t in body.split(delim) if "=" not in t]
sys.exit(1 if bad else 0)
PYEOF
ck "every env token keeps its '=' (gcloud would reject otherwise)" $?

echo "=== phase 12c: armor"
: > "$WALLE_CALL_LOG"
walle --config "$WORK/good.env" --dry-run --yes armor >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"; ck "armor --dry-run issues no mutating command" $?
: > "$WALLE_CALL_LOG"
walle --config "$WORK/good.env" --yes armor >/dev/null 2>&1; ck "armor runs to completion against the stubs" $?
[ "$(grep -c 'model-armor templates create' "$WALLE_CALL_LOG")" = 2 ]; ck "two templates created" $?
grep 'model-armor templates create' "$WALLE_CALL_LOG" | grep -q 'gcloud beta '; ck "templates on the beta track (the enforcement flag lives there)" $?
[ "$(grep 'model-armor templates create' "$WALLE_CALL_LOG" | grep -c -- '--template-metadata-enforcement-type=inspect-only')" = 2 ]
ck "templates created with --template-metadata-enforcement-type=inspect-only" $?
! grep -q 'inspect-and-block\|INSPECT_AND_BLOCK' "$WALLE_CALL_LOG"; ck "nothing flipped to blocking" $?
first_template=$(grep -n 'model-armor templates create' "$WALLE_CALL_LOG" | head -1 | cut -d: -f1)
bucket=$(grep -n 'logging buckets create walle-content-logs' "$WALLE_CALL_LOG" | cut -d: -f1)
sink=$(grep -n 'logging sinks create walle-content-sink' "$WALLE_CALL_LOG" | cut -d: -f1)
excl=$(grep -n 'logging sinks update _Default' "$WALLE_CALL_LOG" | cut -d: -f1)
[ -n "$bucket" ] && [ -n "$sink" ] && [ -n "$excl" ] && [ "$bucket" -lt "$first_template" ] && [ "$sink" -lt "$first_template" ] && [ "$excl" -lt "$first_template" ]
ck "bucket, sink and _Default exclusion exist BEFORE any template" $?
grep -q -- '--retention-days=30' "$WALLE_CALL_LOG"; ck "content log bucket carries CONTENT_LOG_RETENTION_DAYS" $?
ext="$WORK/repo/config/armor/walle-ma-ext.yaml"
[ -f "$ext" ] && grep -q '^failOpen: false$' "$ext" && grep -q '^timeout: 1s$' "$ext"; ck "the committed extension YAML has failOpen: false and timeout: 1s" $?
grep -q "authz-extensions import walle-ma-content-authz-ext --source=$ext" "$WALLE_CALL_LOG"; ck "and that file is the one imported" $?
grep -q 'policyProfile: CONTENT_AUTHZ' "$WORK/repo/config/armor/walle-ma-policy.yaml"; ck "the policy is CONTENT_AUTHZ" $?
grep -q 'agent-gateways import walle-ingress' "$WALLE_CALL_LOG"; ck "ingress gateway imported" $?
grep -q 'floorsettings update --full-uri=folders/987654321098/' "$WALLE_CALL_LOG" && grep -q 'floorsettings update --full-uri=projects/test-walle/.*--add-integrated-services=VERTEX_AI' "$WALLE_CALL_LOG" && grep -q -- '--enable-vertex-ai-cloud-logging' "$WALLE_CALL_LOG"
ck "folder conformance floor, project inline floor, logging on" $?
! grep -q 'config set api_endpoint_overrides' "$WALLE_CALL_LOG"; ck "no persistent gcloud config change (endpoint override is per-command env)" $?
: > "$WALLE_CALL_LOG"
walle --config "$WORK/good.env" --yes armor --enforce >/dev/null 2>&1; rc=$?
[ $rc -ne 0 ] && [ ! -s "$WALLE_CALL_LOG" ]; ck "armor --enforce is refused without MODEL_ARMOR_ENFORCE_DECISION, and nothing ran" $?

echo "=== phase 12b: deploy on the identity path"
: > "$WALLE_CALL_LOG"; rm -f "$WALLE_DEPLOY_ENV_LOG"
harness phase12 >/dev/null 2>&1; ck "phase 12 runs on the AGENT_IDENTITY path" $?
[ "$(deploy_env IDENTITY_TYPE)" = "AGENT_IDENTITY" ]; ck "deploy.py receives IDENTITY_TYPE=AGENT_IDENTITY" $?
[ -z "$(deploy_env SERVICE_ACCOUNT)" ]; ck "and NO service_account" $?
! grep -q 'gcp-sa-aiplatform-re.*serviceAccountTokenCreator' "$WALLE_CALL_LOG"; ck "no tokenCreator grant to the reasoning-engine service agent" $?
deploy_env AGENT_ENV_VARS | grep -q '^\^;\^' && deploy_env AGENT_ENV_VARS | grep -q 'ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false'
ck "telemetry env uses the ^;^ list and sets ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false" $?
! deploy_env AGENT_ENV_VARS | grep -q GOOGLE_API_PREVENT_AGENT_TOKEN_SHARING; ck "token-sharing opt-out never passed" $?
[ "$(grep -c 'add-iam-policy-binding test-walle --member principal://agents.global.org-123456789012' "$WALLE_CALL_LOG")" = 4 ]; ck "four baseline grants on the read-back principal" $?
grep -q 'run services add-iam-policy-binding walle-actions --region europe-west1 --member principal://' "$WALLE_CALL_LOG"; ck "run.invoker bound to the agent principal" $?
grep -q 'iam policies create walle-deny-agents --kind=denypolicies' "$WALLE_CALL_LOG"; ck "deny policy created" $?
grep -q 'org-policies set-policy .*iam.managed.disableServiceAccountKeyCreation' "$WALLE_CALL_LOG"; ck "key-creation constraint set explicitly" $?
! grep -q 'services disable' "$WALLE_CALL_LOG"; ck "nothing disabled by the script" $?
echo "=== phase 12: the engine lock names the GEMINI project's service agent"
grep ':setIamPolicy' "$WALLE_CALL_LOG" | grep -q 'service-555666777888@gcp-sa-discoveryengine'; ck "engine IAM names the GEMINI project's service agent (GEMINI_PROJECT_NUMBER)" $?
! grep -q 'service-111222333444@gcp-sa-discoveryengine' "$WALLE_CALL_LOG"; ck "and never Wall-E's own project number" $?
grep ':setIamPolicy' "$WALLE_CALL_LOG" | grep -q 'walle-dispatcher@test-walle'; ck "walle-dispatcher@ is the second member" $?
! grep -q 'eve-controller' "$WALLE_CALL_LOG"; ck "eve-controller@ is no longer an engine principal (C10)" $?
[ "$(grep ':setIamPolicy' "$WALLE_CALL_LOG" | grep -o 'serviceAccount:' | wc -l | tr -d ' ')" = 2 ]; ck "exactly two members" $?
! grep -q 'roles/discoveryengine.serviceAgent' "$WALLE_CALL_LOG"; ck "no project-level fallback without a failed spike on file" $?
: > "$WALLE_CALL_LOG"
harness phase12 --dry-run >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG" && ! grep -q 'HTTP POST .*:setIamPolicy' "$WALLE_CALL_LOG"
ck "phase 12 --dry-run issues no mutating command and no engine setIamPolicy" $?
printf '{"verdict":"fail"}\n' > "$WORK/repo/drills/gemini-access-spike.json"
printf 'export GEMINI_ACCESS_SPIKE_RESULT="%s"\n' "$WORK/repo/drills/gemini-access-spike.json" >> "$WORK/good.env"
: > "$WALLE_CALL_LOG"
harness phase12 >/dev/null 2>&1 && grep -q 'add-iam-policy-binding test-walle --member serviceAccount:service-555666777888@gcp-sa-discoveryengine.iam.gserviceaccount.com --role roles/discoveryengine.serviceAgent' "$WALLE_CALL_LOG"
ck "a FAIL spike on file applies Google's documented fallback, project-level in Wall-E's project, to the app's agent (decision 42)" $?
sed -i.bak '/^export GEMINI_ACCESS_SPIKE_RESULT=/d' "$WORK/good.env" && rm -f "$WORK/good.env.bak" "$WORK/repo/drills/gemini-access-spike.json"
: > "$WALLE_CALL_LOG"
harness phase12 --skip-deny-policy >/dev/null 2>&1 && ! grep -q 'iam policies create' "$WALLE_CALL_LOG"; ck "--skip-deny-policy escape works" $?
sed -i.bak 's|^export AGENT_IDENTITY_MODE=.*|export AGENT_IDENTITY_MODE="SERVICE_ACCOUNT"|' "$WORK/good.env"
: > "$WALLE_CALL_LOG"
harness phase12 >/dev/null 2>&1; rc=$?
[ $rc -ne 0 ] && [ ! -s "$WALLE_CALL_LOG" ]; ck "SERVICE_ACCOUNT without AGENT_IDENTITY_SPIKE_RESULT is refused, and nothing ran" $?
echo '{"verdict":"fail"}' > "$WORK/repo/drills/agent-identity-spike.json"
: > "$WALLE_CALL_LOG"; rm -f "$WALLE_DEPLOY_ENV_LOG"
harness phase12 >/dev/null 2>&1 && [ "$(deploy_env SERVICE_ACCOUNT)" = "walle-agent@test-walle.iam.gserviceaccount.com" ] && grep -q 'gcp-sa-aiplatform-re.*serviceAccountTokenCreator' "$WALLE_CALL_LOG"
ck "the recorded fallback passes walle-agent@ and restores the tokenCreator grant" $?
mv "$WORK/good.env.bak" "$WORK/good.env"
: > "$WALLE_CALL_LOG"
harness phase12 >/dev/null 2>&1; rc=$?
[ $rc -ne 0 ] && [ ! -s "$WALLE_CALL_LOG" ]; ck "AGENT_IDENTITY with a FAIL spike on file is refused" $?
rm -f "$WORK/repo/drills/agent-identity-spike.json"
: > "$WALLE_CALL_LOG"
harness main --dry-run --yes spike >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"; ck "spike --dry-run issues no mutating command" $?

echo "=== phase 13b: registry"
# 2026-09-13 (P71): the shared registry in CORE_PROJECT is the default path.
: > "$WALLE_CALL_LOG"
harness main --dry-run --yes registry >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"; ck "registry --dry-run issues no mutating command" $?
: > "$WALLE_CALL_LOG"
harness main --yes registry > "$WORK/registry.out" 2>&1; ck "registry runs to completion against the stubs (shared registry, P71)" $?
! grep -q 'services enable.*agentregistry.googleapis.com' "$WALLE_CALL_LOG"; ck "Wall-E's project never enables agentregistry (P71)" $?
! grep -q 'roles/agentregistry' "$WALLE_CALL_LOG"; ck "and no registry role is granted anywhere by this script" $?
! grep -q 'agent-registry services create' "$WALLE_CALL_LOG"; ck "and no registry entry is created: the factory writes the shared registry" $?
grep -q 'agent-registry services describe walle-actions .*--project test-core' "$WALLE_CALL_LOG" \
  && ! grep 'agent-registry' "$WALLE_CALL_LOG" | grep -q -- '--project test-walle'
ck "the shared entries are read in CORE_PROJECT, never in Wall-E's project" $?
grep -q 'agent-gateways import walle-egress' "$WALLE_CALL_LOG" && grep -q 'agentregistry.googleapis.com/projects/test-core/locations/europe-west1' "$WORK/registry.out" \
  && ! grep -q 'agentregistry.googleapis.com/projects/test-walle/' "$WORK/registry.out"
ck "egress gateway imported, bound to the shared registry in CORE_PROJECT" $?
grep -q 'iamEnforcementMode: DRY_RUN' "$WORK/repo/config/gateway/walle-iap-ext.yaml" && grep -q '^failOpen: false$' "$WORK/repo/config/gateway/walle-iap-ext.yaml"
ck "IAP extension starts in DRY_RUN and fail-closed" $?
cp "$WORK/good.env" "$WORK/nocore.env"; sed -i.bak 's|^export CORE_PROJECT=.*|export CORE_PROJECT=""|' "$WORK/nocore.env" && rm -f "$WORK/nocore.env.bak"
: > "$WALLE_CALL_LOG"
out="$(WALLE_HARNESS_CONFIG="$WORK/nocore.env" harness main --yes registry 2>&1)"; rc=$?
[ $rc -ne 0 ] && echo "$out" | grep -q "CORE_PROJECT is empty" && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"
ck "registry with no CORE_PROJECT and no fallback record is refused, and nothing ran" $?
# the recorded fallback: a dated record overturning P71's exclusion
echo "signed" > "$WORK/repo/decisions-registry-fallback.md"
cp "$WORK/good.env" "$WORK/fallback.env"; printf 'export REGISTRY_LOCAL_FALLBACK_DECISION="%s"\n' "$WORK/repo/decisions-registry-fallback.md" >> "$WORK/fallback.env"
: > "$WALLE_CALL_LOG"
WALLE_HARNESS_CONFIG="$WORK/fallback.env" harness main --yes registry >/dev/null 2>&1; ck "registry runs on the recorded per-project fallback" $?
grep -q 'add-iam-policy-binding test-walle --member serviceAccount:ci-deployer@.*roles/agentregistry.admin' "$WALLE_CALL_LOG"; ck "fallback: agentregistry.admin to CI_DEPLOYER" $?
! grep 'roles/agentregistry.admin' "$WALLE_CALL_LOG" | grep -qv 'ci-deployer@'; ck "and to nobody else" $?
! grep -q 'roles/agentregistry.viewer' "$WALLE_CALL_LOG"; ck "no project-level agentregistry.viewer to a foreign identity (decision 43)" $?
! grep -qE 'add-iam-policy-binding test-walle --member serviceAccount:(eve-|mo-)' "$WALLE_CALL_LOG"; ck "registry grants no project-level role to Eve or Mo" $?
grep -q 'agent-registry services create walle-actions .*--endpoint-spec-type=no-spec' "$WALLE_CALL_LOG"; ck "fallback: walle-actions registered as NO_SPEC" $?
n=$(grep -c 'agent-registry services create' "$WALLE_CALL_LOG"); [ "$n" -ge 12 ]; ck "fallback: essential platform endpoints registered ($n)" $?
! grep 'agent-registry services create' "$WALLE_CALL_LOG" | grep -Eqi 'secretmanager|firestore|admin\.googleapis\.com|bigquery|gmail\.|chat\.googleapis|calendar-json|www\.googleapis\.com'
ck "no forbidden host is ever registered" $?
[ "$(grep -c 'iap web set-iam-policy .*--endpoint=' "$WALLE_CALL_LOG")" = "$n" ]; ck "fallback: egressor policy applied per endpoint" $?
grep -q 'agent-gateways import walle-egress' "$WALLE_CALL_LOG"; ck "fallback: egress gateway imported" $?
echo '{"supportedInterfaces":[{"url":"https://tbd.example/a2a"}],"skills":[{"id":"list_users"}]}' > "$WORK/card-tbd.json"
: > "$WALLE_CALL_LOG"
harness main --yes registry --card "$WORK/card-tbd.json" >/dev/null 2>&1; rc=$?
[ $rc -ne 0 ] && ! grep -q 'agent-registry services create' "$WALLE_CALL_LOG"; ck "--card refuses a supportedInterfaces url still 'tbd'" $?
echo '{"supportedInterfaces":[{"url":"https://secretmanager.googleapis.com/v1"}],"skills":[]}' > "$WORK/card-sm.json"
: > "$WALLE_CALL_LOG"
harness main --yes registry --card "$WORK/card-sm.json" >/dev/null 2>&1; rc=$?
[ $rc -ne 0 ] && ! grep -q 'agent-registry services create' "$WALLE_CALL_LOG"; ck "--card refuses a forbidden host too" $?

echo "=== the new verify checks pass on a good repo and can fail"
harness check check_dispatcher_stream_query >/dev/null 2>&1; ck "dispatcher_uses_stream_query passes on stream_query" $?
printf 'r = client.query(sql)\n' > "$WORK/repo/dispatcher/bq.py"
! harness check check_dispatcher_stream_query >/dev/null 2>&1; ck "and FAILS on .query(" $?
rm "$WORK/repo/dispatcher/bq.py"
harness check check_agent_no_dynamic_toolsets >/dev/null 2>&1; ck "agent_no_dynamic_toolsets passes on a plain agent" $?
printf 'from google.adk.tools.mcp_tool import McpToolset\n' > "$WORK/repo/agent/tools.py"
! harness check check_agent_no_dynamic_toolsets >/dev/null 2>&1; ck "and FAILS on McpToolset" $?
rm "$WORK/repo/agent/tools.py"
harness check check_extension_yaml_fail_closed >/dev/null 2>&1; ck "extension_yaml_fail_closed passes on what armor wrote" $?
sed -i.bak 's/^failOpen: false$/failOpen: true/' "$ext"
! harness check check_extension_yaml_fail_closed >/dev/null 2>&1; ck "and FAILS on failOpen: true" $?
mv "$ext.bak" "$ext"
harness check check_agent_identity_effective >/dev/null 2>&1; ck "agent_identity_effective passes on agents.global.org-" $?
harness check check_engine_no_span_content >/dev/null 2>&1; ck "engine_no_span_content passes on false" $?
harness check check_engine_no_token_sharing_optout >/dev/null 2>&1; ck "engine_no_token_sharing_optout passes when absent" $?
harness check check_agentidentitycredentials_disabled >/dev/null 2>&1; ck "agentidentitycredentials_disabled passes" $?

echo "=== the cross-project verify checks read the right project and can fail"
cat > "$WORK/policy-foreign.json" <<'EOF'
{"bindings":[{"role":"roles/datastore.viewer","members":["serviceAccount:eve-controller@test-eve.iam.gserviceaccount.com"]}]}
EOF
WALLE_STUB_PROJECT_POLICY="$WORK/policy-foreign.json" checkout check_project_roles | grep -q 'foreign identity'
ck "project_roles FAILS when eve-controller@EVE_PROJECT holds a project-level role in Wall-E's project" $?
cat > "$WORK/policy-viewer.json" <<'EOF'
{"bindings":[{"role":"roles/agentregistry.viewer","members":["serviceAccount:mo-analyst@test-mo.iam.gserviceaccount.com"]}]}
EOF
WALLE_STUB_PROJECT_POLICY="$WORK/policy-viewer.json" checkout check_project_roles | grep -q 'mo-analyst@test-mo.*project-level'
ck "and when mo-analyst@MO_PROJECT holds agentregistry.viewer" $?
WALLE_STUB_ENGINE_MEMBERS="serviceAccount:service-111222333444@gcp-sa-discoveryengine.iam.gserviceaccount.com,serviceAccount:walle-dispatcher@test-walle.iam.gserviceaccount.com" \
  checkout check_engine_principals | grep -q "WALL-E's own project number"
ck "engine_two_principals FAILS on Wall-E's own project number" $?
WALLE_STUB_ENGINE_MEMBERS="serviceAccount:service-555666777888@gcp-sa-discoveryengine.iam.gserviceaccount.com,serviceAccount:walle-dispatcher@test-walle.iam.gserviceaccount.com,serviceAccount:eve-controller@test-eve.iam.gserviceaccount.com" \
  checkout check_engine_principals | grep -q "C10"
ck "and FAILS with eve-controller@ as a third member (C10)" $?
WALLE_STUB_ENGINE_MEMBERS="serviceAccount:service-555666777888@gcp-sa-discoveryengine.iam.gserviceaccount.com,serviceAccount:walle-dispatcher@test-walle.iam.gserviceaccount.com" \
  harness check check_engine_principals >/dev/null 2>&1
ck "and PASSES on the GEMINI project's agent plus walle-dispatcher@" $?
: > "$WALLE_CALL_LOG"
harness check check_eve_separation >/dev/null 2>&1; ck "eve_credential_separation passes on empty policies" $?
grep -q "secrets get-iam-policy eve-refresh-token --location europe-west1 --project test-eve --format=json" "$WALLE_CALL_LOG"
ck "and reads Eve's secrets in EVE_PROJECT" $?
! grep -qE "eve-(oauth-client|refresh-token) .*--project test-walle" "$WALLE_CALL_LOG"; ck "never in Wall-E's project" $?
: > "$WALLE_CALL_LOG"
harness check check_kms_separation >/dev/null 2>&1; ck "kms_separation passes with no KMS role at home" $?
grep -q "kms keys get-iam-policy eve-approval --keyring eve --location europe-west1 --project test-eve --format=json" "$WALLE_CALL_LOG"
ck "and reads Eve's key policy in EVE_PROJECT" $?
! grep -qE "kms .*--project test-walle" "$WALLE_CALL_LOG"; ck "no KMS read against Wall-E's project" $?
cat > "$WORK/policy-kms-home.json" <<'EOF'
{"bindings":[{"role":"roles/cloudkms.signer","members":["serviceAccount:walle-actions@test-walle.iam.gserviceaccount.com"]}]}
EOF
WALLE_STUB_PROJECT_POLICY="$WORK/policy-kms-home.json" checkout check_kms_separation | grep -q "cloudkms.signer"
ck "and FAILS when walle-actions@ holds a KMS role in Wall-E's project (A2)" $?
harness check check_agent_reads_no_secret >/dev/null 2>&1; ck "agent_reads_no_secret passes and covers Eve's project" $?
cat > "$WORK/bq-view.json" <<'EOF'
{"access":[{"view":{"projectId":"test-mo","datasetId":"walle_metrics_views","tableId":"v_plans"}}]}
EOF
WALLE_STUB_BQ_SHOW="$WORK/bq-view.json" checkout check_cross_project_dataset_access | grep -q "row 9"
ck "cross_project_dataset_access FAILS on a Mo authorised view over a Wall-E dataset (row 9)" $?
cat > "$WORK/bq-old.json" <<'EOF'
{"access":[{"role":"READER","userByEmail":"eve-controller@test-walle.iam.gserviceaccount.com"}]}
EOF
WALLE_STUB_BQ_SHOW="$WORK/bq-old.json" checkout check_cross_project_dataset_access | grep -q "IN Wall-E's project"
ck "and on an Eve reader spelled in Wall-E's project (the old placement)" $?
cat > "$WORK/bq-good.json" <<'EOF'
{"access":[{"role":"READER","userByEmail":"eve-v0@test-eve.iam.gserviceaccount.com"},
           {"role":"READER","userByEmail":"eve-controller@test-eve.iam.gserviceaccount.com"},
           {"role":"READER","userByEmail":"eve-verifier@test-eve.iam.gserviceaccount.com"},
           {"role":"READER","userByEmail":"mo-metrics@test-mo.iam.gserviceaccount.com"}]}
EOF
WALLE_STUB_BQ_SHOW="$WORK/bq-good.json" harness check check_cross_project_dataset_access >/dev/null 2>&1
ck "and PASSES on the dataset-level READER entries of rows 4 and 6" $?
checkout check_cross_project_dataset_access | grep -q "^SKIP"; ck "and is SKIP, not PASS, while the entries are absent" $?

echo "=== the absent-principal tolerance on the two cross-project grant paths"
out="$(WALLE_STUB_ABSENT=1 harness fn grant_cross_project_dataset_readers 2>&1)"; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q "is NOT applied"; ck "a foreign reader BigQuery reports as absent is a PENDING note and exit 0, not a stop" $?
out="$(WALLE_STUB_BREAK=1 harness fn grant_cross_project_dataset_readers 2>&1)"; rc=$?
[ $rc -ne 0 ] && echo "$out" | grep -q "STOPPED"; ck "and any other bq update error stops the run" $?
out="$(WALLE_STUB_ABSENT=1 harness fn ensure_run_invoker walle-actions serviceAccount:eve-controller@test-eve.iam.gserviceaccount.com "topology row 3" 2>&1)"; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q "is NOT bound"; ck "an absent foreign invoker is a PENDING note and exit 0" $?
out="$(WALLE_STUB_BREAK=1 harness fn ensure_run_invoker walle-actions serviceAccount:eve-controller@test-eve.iam.gserviceaccount.com "topology row 3" 2>&1)"; rc=$?
[ $rc -ne 0 ] && echo "$out" | grep -q "STOPPED"; ck "and any other binding error stops the run" $?

echo "=== run_invoker_handles: SKIP while the cross-project invokers are unbound"
cat > "$WORK/run-policy-home.json" <<'EOF'
{"bindings":[{"role":"roles/run.invoker","members":[
  "group:walle-operators@example.com",
  "serviceAccount:walle-operators-caller@test-walle.iam.gserviceaccount.com",
  "serviceAccount:walle-agent@test-walle.iam.gserviceaccount.com",
  "serviceAccount:walle-actions@test-walle.iam.gserviceaccount.com",
  "serviceAccount:walle-dispatcher@test-walle.iam.gserviceaccount.com"]}]}
EOF
WALLE_STUB_RUN_POLICY="$WORK/run-policy-home.json" checkout check_run_invoker_handles | grep -q "^SKIP.*not yet bound"
ck "run_invoker_handles is SKIP, not PASS, with Wall-E's own invokers held and the foreign ones unbound" $?

echo "=== the two caller allowlists, read back from the deployed service"
mkenv() { python3 -c "
import json, sys
env = [{'name': k, 'value': v} for k, v in (a.split('=', 1) for a in sys.argv[1:])]
print(json.dumps({'spec': {'template': {'spec': {'containers': [{'env': env}]}}}}))" "$@"; }
E="test-eve.iam.gserviceaccount.com"; M="test-mo.iam.gserviceaccount.com"; W="test-walle.iam.gserviceaccount.com"
CTRL_OK="CONTROL_CALLER_ALLOWLIST=eve-controller@$E,eve-verifier@$E,walle-operators@example.com"
READ_OK="READ_CALLER_ALLOWLIST=eve-controller@$E,eve-verifier@$E,eve-console@$E,mo-analyst@$M,walle-operators-caller@$W,walle-operators@example.com"
mkenv "$CTRL_OK" "$READ_OK" > "$WORK/env-good.json"
WALLE_STUB_RUN_DESCRIBE="$WORK/env-good.json" harness check check_control_caller_allowlist >/dev/null 2>&1; ck "control_caller_allowlist PASSES on the two Eve members plus the operators" $?
WALLE_STUB_RUN_DESCRIBE="$WORK/env-good.json" harness check check_read_caller_allowlist >/dev/null 2>&1; ck "read_caller_allowlist PASSES with eve-console@ and mo-analyst@ at their cross-project addresses" $?
mkenv "CONTROL_CALLER_ALLOWLIST=eve-controller@$E,eve-verifier@$E,eve-console@$W,walle-operators@example.com" "$READ_OK" > "$WORK/env-old.json"
WALLE_STUB_RUN_DESCRIBE="$WORK/env-old.json" checkout check_control_caller_allowlist | grep -q "Wall-E's own project"
ck "control_caller_allowlist FAILS on an Eve identity spelled in Wall-E's project (the old placement)" $?
mkenv "CONTROL_CALLER_ALLOWLIST=eve-controller@$E,eve-verifier@$E,mo-analyst@$M,walle-operators@example.com" "$READ_OK" > "$WORK/env-ctrl-read.json"
WALLE_STUB_RUN_DESCRIBE="$WORK/env-ctrl-read.json" checkout check_control_caller_allowlist | grep -q "read-endpoint list only"
ck "and when a read-only caller is on the control list" $?
mkenv "$CTRL_OK" "READ_CALLER_ALLOWLIST=eve-console@$E,walle-operators@example.com" > "$WORK/env-read-nomo.json"
WALLE_STUB_RUN_DESCRIBE="$WORK/env-read-nomo.json" checkout check_read_caller_allowlist | grep -q "mo-analyst@test-mo is not in READ_CALLER_ALLOWLIST"
ck "read_caller_allowlist FAILS without mo-analyst@MO_PROJECT" $?
mkenv "$CTRL_OK" > "$WORK/env-noread.json"
WALLE_STUB_RUN_DESCRIBE="$WORK/env-noread.json" checkout check_read_caller_allowlist | grep -q "absent or empty"
ck "and when READ_CALLER_ALLOWLIST is missing from the deployed revision" $?
mkenv "$CTRL_OK" "READ_CALLER_ALLOWLIST=eve-console@$E,mo-analyst@$W" > "$WORK/env-read-old.json"
WALLE_STUB_RUN_DESCRIBE="$WORK/env-read-old.json" checkout check_read_caller_allowlist | grep -q "Wall-E's own project"
ck "and on a Mo identity spelled in Wall-E's project" $?

echo "=== the super-admin robot (2026-09-13, platform HLD §13.1 and §18 item 5)"
# --- two clients, one reader each (the gcp run above) ---
: > "$WALLE_CALL_LOG"
walle --config "$WORK/good.env" --yes gcp > "$WORK/gcp2.out" 2>&1
for secret in walle-oauth-client walle-refresh-token walle-confirm-hmac; do
  grep -q "secrets add-iam-policy-binding $secret --location europe-west1 --member serviceAccount:walle-actions@test-walle" "$WALLE_CALL_LOG" \
    && ! grep -q "secrets add-iam-policy-binding $secret .*walle-actions-super@" "$WALLE_CALL_LOG"
  ck "$secret: reader walle-actions@ only" $?
done
for secret in walle-super-oauth-client walle-super-refresh-token; do
  grep -q "secrets create $secret --location europe-west1" "$WALLE_CALL_LOG" \
    && grep -q "secrets add-iam-policy-binding $secret --location europe-west1 --member serviceAccount:walle-actions-super@test-walle" "$WALLE_CALL_LOG" \
    && ! grep -q "secrets add-iam-policy-binding $secret --location europe-west1 --member serviceAccount:walle-actions@" "$WALLE_CALL_LOG"
  ck "$secret: created regional, reader walle-actions-super@ only" $?
done
grep -q "add-iam-policy-binding test-walle --member serviceAccount:walle-actions-super@test-walle.iam.gserviceaccount.com --role roles/datastore.user" "$WALLE_CALL_LOG" \
  && ! grep -q "walle-actions-super@test-walle.iam.gserviceaccount.com --role roles/cloudtasks.enqueuer" "$WALLE_CALL_LOG"
ck "walle-actions-super@ gets its project roles and no cloudtasks.enqueuer (band B has no queue)" $?
grep -q "walle-actions-super@test-walle.iam.gserviceaccount.com gains projects/test-walle/roles/walleAuditWriter on walle_audit" "$WORK/gcp2.out"
ck "walle-actions-super@ writes its own audit rows, insert-only" $?

# --- cloud-platform is never consented: the CI assertion ---
python3 - "$SCRIPT" "$WORK/good.env" <<'PYEOF'
import importlib.util, re, sys
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
src = open(sys.argv[1]).read()
base = m.derive_config(m.load_config(sys.argv[2]))
def cfg(**kw):
    c = dict(base); c.update(kw); return c
good = "https://www.googleapis.com/auth/admin.directory.user,https://www.googleapis.com/auth/userinfo.email,openid"
ok = (
    not m.forbidden_scopes(m.ROBOT_SCOPES)
    and not m.forbidden_scopes(m.EVE_SCOPES)
    # the literal appears in exactly one place: the refusal list
    and len(re.findall(r"auth/cloud-platform", src)) == 1
    and m.forbidden_scopes(["https://www.googleapis.com/auth/cloud-platform"])
    and m.forbidden_scopes(["https://www.googleapis.com/auth/cloud-platform.read-only"])
    and not m.forbidden_scopes(["https://www.googleapis.com/auth/cloud-platformish"])
    and any("cloud-platform" in p for p in m.validate_config(cfg(SUPER_SCOPES=good + ",https://www.googleapis.com/auth/cloud-platform"), "consent"))
    and any("cloud-platform" in p for p in m.validate_config(cfg(SUPER_SCOPES=good + ",https://www.googleapis.com/auth/cloud-platform.read-only"), "consent"))
    and any("lacks" in p for p in m.validate_config(cfg(SUPER_SCOPES="https://www.googleapis.com/auth/admin.directory.user"), "consent"))
    and not m.validate_config(cfg(SUPER_SCOPES=good), "consent")
    and any("EVE_ROBOT" in p for p in m.validate_config(cfg(SUPER_ADMIN_ROSTER=base["EVE_ROBOT"]), "verify"))
)
sys.exit(0 if ok else 1)
PYEOF
ck "cloud-platform (and .read-only) is in no scope constant, refused in SUPER_SCOPES, and spelled only in the refusal list" $?
python3 - "$SCRIPT" "$WORK" <<'PYEOF'
import argparse, importlib.util, sys
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
cfg = m.derive_config(m.load_config(sys.argv[2] + "/good.env"))
ctx = m.Ctx(cfg, argparse.Namespace(dry_run=True, yes=True, verbose=False))
try:
    m.run_consent(ctx, "walle-super-oauth-client", "walle-super-refresh-token", cfg["ROBOT"],
                  ("openid", "https://www.googleapis.com/auth/cloud-platform"), False)
except m.WalleError as exc:
    sys.exit(0 if "cloud-platform" in str(exc) else 1)
sys.exit(1)
PYEOF
ck "run_consent refuses a cloud-platform list before anything, --dry-run included" $?
: > "$WALLE_CALL_LOG"
walle --config "$WORK/good.env" --yes consent --super >/dev/null 2>&1; rc=$?
[ $rc -ne 0 ] && [ ! -s "$WALLE_CALL_LOG" ]; ck "consent --super without SUPER_SCOPES_DECISION is refused, and nothing ran" $?
mkdir -p "$WORK/repo/decisions"; echo "signed" > "$WORK/repo/decisions/broad-scopes.md"; echo "signed" > "$WORK/repo/decisions/2026-09-13-wall-e-holds-super-admin.md"
cp "$WORK/good.env" "$WORK/super.env"
printf 'export SUPER_SCOPES_DECISION="%s"\nexport SUPER_SCOPES="https://www.googleapis.com/auth/admin.directory.user,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/userinfo.email,openid"\n' "$WORK/repo/decisions/broad-scopes.md" >> "$WORK/super.env"
: > "$WALLE_CALL_LOG"
walle --config "$WORK/super.env" --yes consent --super >/dev/null 2>&1; rc=$?
[ $rc -ne 0 ] && [ ! -s "$WALLE_CALL_LOG" ]; ck "consent --super with cloud-platform in SUPER_SCOPES is refused, and nothing ran" $?
sed -i.bak 's|,https://www.googleapis.com/auth/cloud-platform,|,|' "$WORK/super.env" && rm -f "$WORK/super.env.bak"
: > "$WALLE_CALL_LOG"
out="$(walle --config "$WORK/super.env" --yes --dry-run consent --super 2>&1)"; rc=$?
[ $rc -eq 0 ] && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG" && echo "$out" | grep -q "M5S" && echo "$out" | grep -q "walle-super-oauth-client"
ck "consent --super --dry-run rehearses client 2 (M5S, the broad pair) and mutates nothing" $?
echo "$out" | grep -q "would BLOCK here until M7" ; ck "and still blocks on the robot's own consent (M7)" $?

# --- walle-actions-super: deployed only with client 2, allowlists and invokers exactly the HLD's ---
: > "$WALLE_CALL_LOG"
harness phase10 >/dev/null 2>&1
! grep -q "run deploy walle-actions-super" "$WALLE_CALL_LOG"; ck "without SUPER_REFRESH_TOKEN_VERSION walle-actions-super is not deployed" $?
: > "$WALLE_CALL_LOG"
WALLE_SET_KEYS="SUPER_REFRESH_TOKEN_VERSION=3|ACTIONS_SUPER_IMAGE=europe-west1-docker.pkg.dev/test-walle/walle/actions-super:test" harness phase10 >/dev/null 2>&1; ck "phase 10 runs with client 2 consented" $?
SD="$(grep 'run deploy walle-actions-super' "$WALLE_CALL_LOG" | tr -d '\\')"
echo "$SD" | grep -q -- "--service-account walle-actions-super@test-walle.iam.gserviceaccount.com" \
  && echo "$SD" | grep -q "REFRESH_TOKEN_SECRET=walle-super-refresh-token" \
  && echo "$SD" | grep -q "OAUTH_CLIENT_SECRET=walle-super-oauth-client" \
  && echo "$SD" | grep -q "REFRESH_TOKEN_VERSION=3" && echo "$SD" | grep -q -- "--no-allow-unauthenticated"
ck "walle-actions-super runs as its own account, reads the broad pair, pins version 3" $?
echo "$SD" | grep -q "CONTROL_CALLER_ALLOWLIST=eve-controller@test-eve.iam.gserviceaccount.com,eve-verifier@test-eve.iam.gserviceaccount.com;" \
  && echo "$SD" | grep -q "EXEC_CALLER_ALLOWLIST=walle-agent@test-walle.iam.gserviceaccount.com;" \
  && ! echo "$SD" | grep -qE "READ_CALLER_ALLOWLIST|INTERNAL_CALLER_ALLOWLIST|mo-analyst|eve-console|walle-dispatcher|walle-operators-caller" \
  && ! echo "$SD" | grep -qE "(EXEC|CONTROL)_CALLER_ALLOWLIST=[^;]*walle-operators@"
ck "its allowlists: EXEC the agent, CONTROL eve-controller@ and eve-verifier@ (halt, topology row 27); no read or internal list, no Mo, dispatcher or operators" $?
grep -q "run services add-iam-policy-binding walle-actions-super --region europe-west1 --member serviceAccount:walle-agent@test-walle" "$WALLE_CALL_LOG" \
  && grep -q "run services add-iam-policy-binding walle-actions-super --region europe-west1 --member serviceAccount:eve-controller@test-eve" "$WALLE_CALL_LOG" \
  && grep -q "run services add-iam-policy-binding walle-actions-super --region europe-west1 --member serviceAccount:eve-verifier@test-eve" "$WALLE_CALL_LOG"
ck "run.invoker on walle-actions-super: the agent, eve-controller@ and eve-verifier@ (halt path)" $?
! grep "run services add-iam-policy-binding walle-actions-super" "$WALLE_CALL_LOG" | grep -qE "walle-dispatcher|mo-|eve-console|walle-operators|group:"
ck "and nobody else: no dispatcher route, no Mo, no operators group" $?
! grep 'run deploy walle-actions ' "$WALLE_CALL_LOG" | grep -q "walle-super-"; ck "walle-actions never names the broad pair" $?
: > "$WALLE_CALL_LOG"
WALLE_SET_KEYS="SUPER_REFRESH_TOKEN_VERSION=3|ACTIONS_SUPER_IMAGE=x" harness phase10 --dry-run >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"; ck "phase 10 --dry-run with client 2 issues no mutating command" $?
out="$(WALLE_SET_KEYS="SUPER_REFRESH_TOKEN_VERSION=latest|ACTIONS_SUPER_IMAGE=x" harness phase10 2>&1)"
echo "$out" | grep -q "STOPPED: SUPER_REFRESH_TOKEN_VERSION must be the NUMBER"; ck "a 'latest' band-B pin is refused" $?
senv() { mkenv "WORKSPACE_DOMAIN=example.com" "ROBOT_ACCOUNT=walle-bot@example.com" "OPERATOR_GROUP=walle-operators@example.com" \
  "PROTECTED_GROUP=walle-protected@example.com" "SECRET_LOCATION=europe-west1" "REFRESH_TOKEN_SECRET=walle-super-refresh-token" \
  "REFRESH_TOKEN_VERSION=3" "OAUTH_CLIENT_SECRET=walle-super-oauth-client" "EVE_PUBLIC_KEY_PEM=/app/contracts/eve-public-keys" \
  "AUDIT_DATASET=walle_audit" "EXEC_CALLER_ALLOWLIST=walle-agent@$W" "AUDIENCE=https://walle-actions-super-abc.a.run.app" "$@"; }
senv "CONTROL_CALLER_ALLOWLIST=eve-controller@$E,eve-verifier@$E" > "$WORK/super-good.json"
# the HLD's invoker set, exactly (tightened 2026-09-13)
INV='"serviceAccount:walle-agent@test-walle.iam.gserviceaccount.com","serviceAccount:eve-controller@test-eve.iam.gserviceaccount.com","serviceAccount:eve-verifier@test-eve.iam.gserviceaccount.com"'
echo "{\"bindings\":[{\"role\":\"roles/run.invoker\",\"members\":[$INV]}]}" > "$WORK/super-policy-good.json"
WALLE_STUB_SUPER_DESCRIBE="$WORK/super-good.json" WALLE_STUB_RUN_POLICY="$WORK/super-policy-good.json" harness check check_super_service >/dev/null 2>&1; ck "super_service_allowlists PASSES on the HLD's set" $?
senv "CONTROL_CALLER_ALLOWLIST=eve-controller@$E,eve-verifier@$E,mo-analyst@$M" > "$WORK/super-mo.json"
WALLE_STUB_SUPER_DESCRIBE="$WORK/super-mo.json" WALLE_STUB_RUN_POLICY="$WORK/super-policy-good.json" checkout check_super_service | grep -q "^FAIL.*CONTROL_CALLER_ALLOWLIST"; ck "and FAILS with Mo on its control list" $?
senv "CONTROL_CALLER_ALLOWLIST=eve-controller@$E" > "$WORK/super-noverifier.json"
WALLE_STUB_SUPER_DESCRIBE="$WORK/super-noverifier.json" WALLE_STUB_RUN_POLICY="$WORK/super-policy-good.json" checkout check_super_service | grep -q "^FAIL.*CONTROL_CALLER_ALLOWLIST.*missing.*eve-verifier"; ck "and FAILS without eve-verifier@ on its control list (topology row 27)" $?
senv "CONTROL_CALLER_ALLOWLIST=eve-controller@$E,eve-verifier@$E" "READ_CALLER_ALLOWLIST=eve-console@$E" > "$WORK/super-read.json"
WALLE_STUB_SUPER_DESCRIBE="$WORK/super-read.json" WALLE_STUB_RUN_POLICY="$WORK/super-policy-good.json" checkout check_super_service | grep -q "^FAIL.*READ_CALLER_ALLOWLIST"; ck "and with a read list" $?
cat > "$WORK/super-policy-dispatch.json" <<'EOF2'
{"bindings":[{"role":"roles/run.invoker","members":["serviceAccount:walle-dispatcher@test-walle.iam.gserviceaccount.com"]}]}
EOF2
echo "{\"bindings\":[{\"role\":\"roles/run.invoker\",\"members\":[$INV,\"serviceAccount:walle-actions@test-walle.iam.gserviceaccount.com\"]}]}" > "$WORK/super-policy-extra.json"
WALLE_STUB_SUPER_DESCRIBE="$WORK/super-good.json" WALLE_STUB_RUN_POLICY="$WORK/super-policy-extra.json" checkout check_super_service | grep -q "^FAIL.*held by.*walle-actions@"
ck "and FAILS when an invoker outside the set (walle-actions@) holds run.invoker" $?
echo '{"bindings":[{"role":"roles/run.invoker","members":["serviceAccount:eve-controller@test-eve.iam.gserviceaccount.com","serviceAccount:eve-verifier@test-eve.iam.gserviceaccount.com"]}]}' > "$WORK/super-policy-noagent.json"
WALLE_STUB_SUPER_DESCRIBE="$WORK/super-good.json" WALLE_STUB_RUN_POLICY="$WORK/super-policy-noagent.json" checkout check_super_service | grep -q "^FAIL.*missing.*walle-agent@"
ck "and FAILS when the agent does not hold run.invoker" $?
senv "CONTROL_CALLER_ALLOWLIST=eve-controller@$E,eve-verifier@$E" > /dev/null
python3 - "$WORK/super-good.json" "$WORK/super-exec-extra.json" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
env = d["spec"]["template"]["spec"]["containers"][0]["env"] if "spec" in d else None
text = json.dumps(d).replace("walle-agent@test-walle.iam.gserviceaccount.com", "walle-agent@test-walle.iam.gserviceaccount.com,walle-actions@test-walle.iam.gserviceaccount.com", 1)
open(sys.argv[2], "w").write(text)
PYEOF
WALLE_STUB_SUPER_DESCRIBE="$WORK/super-exec-extra.json" WALLE_STUB_RUN_POLICY="$WORK/super-policy-good.json" checkout check_super_service | grep -q "^FAIL.*EXEC_CALLER_ALLOWLIST names callers"
ck "and FAILS when EXEC_CALLER_ALLOWLIST names a caller beside the agent" $?
WALLE_STUB_SUPER_DESCRIBE="$WORK/super-good.json" WALLE_STUB_RUN_POLICY="$WORK/super-policy-dispatch.json" checkout check_super_service | grep -q "^FAIL.*walle-dispatcher"
ck "and when walle-dispatcher@ holds run.invoker on it" $?
checkout check_super_service | grep -q "^SKIP"; ck "and is SKIP while it is not deployed" $?

# --- review-findings pass, 2026-09-13: scopes unnarrowed, HD-15, denials, gate keys ---
python3 - "$SCRIPT" "$WORK/good.env" <<'PYEOF'
import importlib.util, json, sys, types, urllib.parse
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
seen = {}
def fake_request(url, method, body, headers):
    seen.update(urllib.parse.parse_qs(body.decode()))
    seen["url"] = url
    return types.SimpleNamespace(status=200, data=json.dumps({"access_token": "t", "scope": "openid https://www.googleapis.com/auth/cloud-platform"}).encode())
tok, granted = m.refresh_unnarrowed(fake_request, {"client_id": "c", "client_secret": "s", "refresh_token": "r", "token_uri": "https://oauth2.googleapis.com/token"})
ok = "scope" not in seen and seen["grant_type"] == ["refresh_token"] and "https://www.googleapis.com/auth/cloud-platform" in granted
hd15 = [r for r in m.HARD_DENIED if r["id"] == "HD-15"][0]
ok = ok and {"directory.users.update", "directory.users.patch"} <= set(hd15["methods"]) and "recoveryEmail" in hd15["security_fields"]
ok = ok and {"DOMAIN", "SVC_OU", "EVE_ROBOT", "PROTECTED"} <= set(m.CONFIG_KEYS_FOR_SUBCOMMAND["denials"])
cfg = m.derive_config(m.load_config(sys.argv[2]))
cfg["SUPER_ADMIN_GRANT_DECISION"] = "/nonexistent/grant.md"
ok = ok and any("SUPER_ADMIN_GRANT_DECISION" in p and "existing file" in p for p in m.validate_config(cfg, "verify"))
sys.exit(0 if ok else 1)
PYEOF
ck "the scope check refreshes with no scope parameter and sees cloud-platform; HD-15 covers admin password and recovery fields; denials needs its target keys; a gate key naming a missing file is refused" $?
: > "$WALLE_CALL_LOG"
mkdir -p "$WORK/repo/tests"; printf 'print("{}")\n' > "$WORK/repo/tests/denials.py"
out="$(WALLE_SET_KEYS="EVE_ROBOT=" python3 "$WORK/harness.py" "$SCRIPT" "$WORK" fn cmd_denials 2>&1)"
echo "$out" | grep -q "targets the config cannot resolve"; ck "walle denials refuses to hand an unresolved hard-denied target to the suite" $?
rm -rf "$WORK/repo/tests"

# --- secret readers split ---
mkdir -p "$WORK/secpol"
for s in walle-oauth-client walle-refresh-token walle-confirm-hmac; do
  echo '{"bindings":[{"role":"roles/secretmanager.secretAccessor","members":["serviceAccount:walle-actions@test-walle.iam.gserviceaccount.com"]}]}' > "$WORK/secpol/$s.json"
done
for s in walle-super-oauth-client walle-super-refresh-token; do
  echo '{"bindings":[{"role":"roles/secretmanager.secretAccessor","members":["serviceAccount:walle-actions-super@test-walle.iam.gserviceaccount.com"]}]}' > "$WORK/secpol/$s.json"
done
WALLE_STUB_SECRETS_EXIST=1 WALLE_STUB_SECRET_POLICY_DIR="$WORK/secpol" harness check check_secret_readers_split >/dev/null 2>&1; ck "secret_readers_split PASSES with one reader per pair" $?
echo '{"bindings":[{"role":"roles/secretmanager.secretAccessor","members":["serviceAccount:walle-actions@test-walle.iam.gserviceaccount.com","serviceAccount:walle-actions-super@test-walle.iam.gserviceaccount.com"]}]}' > "$WORK/secpol/walle-refresh-token.json"
WALLE_STUB_SECRETS_EXIST=1 WALLE_STUB_SECRET_POLICY_DIR="$WORK/secpol" checkout check_secret_readers_split | grep -q "^FAIL.*walle-refresh-token is readable by walle-actions-super@"
ck "and FAILS when the band-B account can read the narrow token" $?
harness check check_no_cloud_platform_scope >/dev/null 2>&1; ck "no_cloud_platform_scope PASSES on the constants" $?
WALLE_SET_KEYS="SUPER_SCOPES=openid,https://www.googleapis.com/auth/cloud-platform.read-only" checkout check_no_cloud_platform_scope | grep -q "^FAIL"
ck "and FAILS on cloud-platform.read-only in client 2's list" $?

# --- the hard-denied list as data, handed to the denial suite ---
python3 - "$SCRIPT" "$WORK/good.env" <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
cfg = m.derive_config(m.load_config(sys.argv[2]))
rows = m.hard_denied_resolved(cfg)
text = " ".join(r["what"] for r in rows).lower()
methods = {x for r in rows for x in r["methods"]}
targets = {x for r in rows for x in r["targets"]}
needed = ["robot account", "robot's ou", "eve's robot", "eve's admin role", "control groups",
          "oauth clients", "activity rules", "share data with google cloud services", "secops export",
          "organisation sinks", "users.makeadmin", "super admin", "users.delete of any admin",
          "tenant account", "backup codes", "self-recovery", "domain-wide delegation", "multi-party approval"]
ok = (not m.hard_denied_problems()
      and all(n in text for n in needed)
      and all(r["reason"] in m.HARD_DENIED_REASONS for r in rows)
      and all(r["lanes"] == ["A", "B", "C"] and r["severity"] == 1 for r in rows)
      and {"directory.users.makeAdmin", "directory.roleAssignments.insert",
           "directory.verificationCodes.generate", "directory.twoStepVerification.turnOff"} <= methods
      and cfg["ROBOT"] in targets and cfg["SVC_OU"] in targets and cfg["EVE_ROBOT"] in targets
      and cfg["OPERATORS"] in targets and "eve-owners@example.com" in targets
      and not any("unset>" in t for t in targets)
      and tuple(m.HARD_DENIED_REASONS) == ("self_modification_denied", "escalation_denied",
          "posture_change_denied", "irreversible_denied", "money_denied"))
saved = m.HARD_DENIED
m.HARD_DENIED = saved + ({"id": "HD-99", "kind": "method", "what": "x", "methods": ("a",), "reason": "because"},)
ok = ok and any("closed vocabulary" in p for p in m.hard_denied_problems())
sys.exit(0 if ok else 1)
PYEOF
ck "HARD_DENIED names every HLD §13.1 item 2 row, verified method names, a closed reason vocabulary, all three lanes" $?
python3 - "$SCRIPT" <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
by_id = {r["id"]: r["reason"] for r in m.HARD_DENIED}
ok = all(by_id.get(h) == "self_modification_denied" for h in ("HD-01", "HD-02", "HD-03", "HD-04", "HD-05"))
sys.exit(0 if ok else 1)
PYEOF
ck "the robot, its OU, Eve's robot, Eve's role and the control groups carry self_modification_denied, as 03-lld.md assigns" $?
python3 - "$SCRIPT" <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
base = {k: "x" for k in m.CONFIG_KEYS_FOR_SUBCOMMAND["gcp"]}
same = dict(base, FOLDER_ID="111111111111", WALLE_FOLDER_ID="111111111111")
word = dict(base, FOLDER_ID="111111111111", WALLE_FOLDER_ID="fld-agents-p-sa-prod")
good = dict(base, FOLDER_ID="111111111111", WALLE_FOLDER_ID="222222222222")
probs = lambda cfg: [str(p) for p in m.validate_config(cfg, "gcp")]
ok = any("WALLE_FOLDER_ID equals FOLDER_ID" in p for p in probs(same)) \
     and any("WALLE_FOLDER_ID must be the numeric" in p for p in probs(word)) \
     and not any("WALLE_FOLDER_ID" in p for p in probs(good))
sys.exit(0 if ok else 1)
PYEOF
ck "WALLE_FOLDER_ID is refused when it equals FOLDER_ID or is not numeric" $?
harness check check_hard_denied_list >/dev/null 2>&1; ck "hard_denied_list verify check PASSES on the filled config" $?
mkdir -p "$WORK/repo/tests"
cat > "$WORK/repo/tests/denials.py" <<'PYEOF'
import json, os, shutil
shutil.copy(os.environ["WALLE_HARD_DENIED_FILE"], os.path.join(os.path.dirname(__file__), "received-hard-denied.json"))
print(json.dumps({"ok": True}))
PYEOF
harness main --yes denials >/dev/null 2>&1
python3 -c "
import json,sys; rows=json.load(open('$WORK/repo/tests/received-hard-denied.json'))
sys.exit(0 if len(rows) >= 18 and any('walle-bot@example.com' in r['targets'] or any('@example.com' in t for t in r['targets']) for r in rows) else 1)" 2>/dev/null
ck "walle denials hands the resolved hard-denied list to tests/denials.py (WALLE_HARD_DENIED_FILE)" $?
rm -rf "$WORK/repo/tests"

# --- the inverted hardening check, the roster rule, the role assignments ---
mkdir -p "$WORK/dir"
mkdir_dir() { python3 - "$WORK/dir/$1.json" "$2" <<'PYEOF'
import json, sys
path, variant = sys.argv[1], sys.argv[2]
robot = {"primaryEmail": "walle-bot@example.com", "id": "r1", "isAdmin": True, "isEnrolledIn2Sv": True,
         "isEnforcedIn2Sv": True, "orgUnitPath": "/Automation/Service Identities"}
eve = {"primaryEmail": "eve-bot@example.com", "id": "e1", "isAdmin": False, "isEnrolledIn2Sv": True,
       "isEnforcedIn2Sv": True, "orgUnitPath": "/Automation/Service Identities"}
h1 = {"primaryEmail": "sa-1-admin@example.com", "id": "h1", "isAdmin": True, "isEnrolledIn2Sv": True, "isEnforcedIn2Sv": True}
h2 = {"primaryEmail": "sa-2-admin@example.com", "id": "h2", "isAdmin": True, "isEnrolledIn2Sv": True, "isEnforcedIn2Sv": True}
roles = [{"roleId": "SA", "roleName": "_SEED_ADMIN_ROLE", "isSuperAdminRole": True},
         {"roleId": "EV", "roleName": "Eve — Verifier", "rolePrivileges": []},
         {"roleId": "RD", "roleName": "Wall-E — Reader", "rolePrivileges": []}]
assign = [{"roleId": "SA", "assignedTo": "r1", "scopeType": "CUSTOMER"},
          {"roleId": "SA", "assignedTo": "h1", "scopeType": "CUSTOMER"},
          {"roleId": "SA", "assignedTo": "h2", "scopeType": "CUSTOMER"},
          {"roleId": "EV", "assignedTo": "e1", "scopeType": "CUSTOMER"}]
users = [robot, eve, h1, h2]
if variant == "not_admin": robot["isAdmin"] = False; assign = [a for a in assign if a["assignedTo"] != "r1"]
if variant == "one_human": users.remove(h2); assign = [a for a in assign if a["assignedTo"] != "h2"]
if variant == "recovery": h1["recoveryEmail"] = "walle-bot@example.com"
if variant == "extra_admin": users.append({"primaryEmail": "stranger@example.com", "id": "x1", "isAdmin": True})
if variant == "eve_admin": eve["isAdmin"] = True
if variant == "phone": robot["recoveryPhone"] = "+33000000000"
if variant == "retired": assign.append({"roleId": "RD", "assignedTo": "r1", "scopeType": "CUSTOMER"})
if variant == "human_no_2sv": h2["isEnforcedIn2Sv"] = False
if variant in ("no_eve", "no_eve_pre"): users.remove(eve); assign = [a for a in assign if a["assignedTo"] != "e1"]
if variant == "no_eve_pre": robot["isAdmin"] = False; assign = [a for a in assign if a["assignedTo"] != "r1"]
json.dump({"users": users, "roles": roles, "roleAssignments": assign}, open(path, "w"))
PYEOF
}
for v in good not_admin one_human recovery extra_admin eve_admin phone retired human_no_2sv no_eve no_eve_pre; do mkdir_dir "$v" "$v"; done
GRANT="SUPER_ADMIN_GRANT_DECISION=$WORK/repo/decisions/2026-09-13-wall-e-holds-super-admin.md"
ROSTER="SUPER_ADMIN_ROSTER=walle-bot@example.com,sa-1-admin@example.com,sa-2-admin@example.com"
SVC="SVC_OU=/Automation/Service Identities|ROBOT=walle-bot@example.com|EVE_ROBOT=eve-bot@example.com"
hard() { WALLE_FAKE_DIRECTORY="$WORK/dir/$1.json" WALLE_SET_KEYS="$SVC|$2" checkout check_robot_hardening; }
hard good "$GRANT|$ROSTER" | grep -q "^PASS"; ck "robot_hardening PASSES: a super admin with the grant on file, two humans, roster exact" $?
hard not_admin "$GRANT|$ROSTER" | grep -q "^FAIL.*NOT a super admin"; ck "and FAILS when the grant is on file but the robot is not a super admin" $?
hard good "$ROSTER" | grep -q "^FAIL.*tier gate"; ck "and FAILS when the robot is a super admin with no signed grant record (isAdmin inverted, gated)" $?
hard not_admin "" | grep -q "^PASS"; ck "and PASSES before the gate on a robot that holds no admin role" $?
hard one_human "$GRANT|SUPER_ADMIN_ROSTER=walle-bot@example.com,sa-1-admin@example.com" | grep -q "^FAIL.*at least two"; ck "and FAILS with fewer than two human super admins (never the only one)" $?
hard recovery "$GRANT|$ROSTER" | grep -q "^FAIL.*recovery email of super admin"; ck "and FAILS when the robot is another super admin's recovery email" $?
hard extra_admin "$GRANT|$ROSTER" | grep -q "^FAIL.*NOT on the committed roster"; ck "and FAILS on a super admin not on the committed roster (role_assignment_added)" $?
hard good "$GRANT" | grep -q "^FAIL.*SUPER_ADMIN_ROSTER is empty"; ck "and FAILS after the grant with no committed roster" $?
hard eve_admin "$GRANT|SUPER_ADMIN_ROSTER=walle-bot@example.com,sa-1-admin@example.com,sa-2-admin@example.com,eve-bot@example.com" | grep -q "^FAIL.*Eve's robot"
ck "and FAILS when Eve's robot is a super admin" $?
hard phone "$GRANT|$ROSTER" | grep -q "^FAIL.*recovery phone"; ck "and keeps the hygiene set (a recovery phone FAILS)" $?
hard human_no_2sv "$GRANT|$ROSTER" | grep -q "^FAIL.*sa-2-admin@example.com is not enrolled in and enforced for 2-step"; ck "and FAILS after the grant when a human super admin lacks enforced 2SV (added 2026-09-13)" $?
WALLE_FAKE_DIRECTORY="$WORK/dir/good.json" WALLE_SET_KEYS="$SVC|$GRANT|$ROSTER" harness check check_role_assignments >/dev/null 2>&1
ck "role_assignments PASSES: robot holds exactly Super Admin, Eve exactly her customer-scoped role" $?
WALLE_FAKE_DIRECTORY="$WORK/dir/retired.json" WALLE_SET_KEYS="$SVC|$GRANT|$ROSTER" checkout check_role_assignments | grep -q "^FAIL.*retired role 'Wall-E — Reader' is still ASSIGNED"
ck "and FAILS while a retired Wall-E role is still assigned" $?
WALLE_FAKE_DIRECTORY="$WORK/dir/good.json" WALLE_SET_KEYS="$SVC|$ROSTER" checkout check_role_assignments | grep -q "^FAIL.*tier gate was skipped"
ck "and FAILS on a Super Admin assignment with no grant record" $?
WALLE_FAKE_DIRECTORY="$WORK/dir/no_eve.json" WALLE_SET_KEYS="$SVC|$GRANT|$ROSTER" checkout check_role_assignments | grep -q "^FAIL.*Eve's .*not present although the grant record is on file"
ck "and FAILS after the grant when Eve's account is absent, instead of asserting her role (2026-09-13)" $?
WALLE_FAKE_DIRECTORY="$WORK/dir/no_eve_pre.json" WALLE_SET_KEYS="$SVC" checkout check_role_assignments | grep -q "^PASS.*NOT checked"
ck "and before the gate says Eve's role was NOT checked" $?
WALLE_FAKE_DIRECTORY="$WORK/dir/eve_admin.json" WALLE_SET_KEYS="$SVC|$GRANT" checkout verify_2sv_enforced | grep -q "^FAIL.*Eve's robot) is a super admin"
ck "verify_2sv_enforced keeps the super-admin refusal for EVE_ROBOT only" $?
WALLE_FAKE_DIRECTORY="$WORK/dir/good.json" WALLE_SET_KEYS="$SVC|$GRANT|$ROSTER" harness check verify_2sv_enforced >/dev/null 2>&1
ck "and passes a granted super-admin robot" $?

# --- the manual step, the retired roles, and what the script never does ---
out="$(WALLE_SET_KEYS="$GRANT" python3 "$WORK/harness.py" "$SCRIPT" "$WORK" fn do_manual_step M2C 2>&1 < /dev/null)"
echo "$out" | grep -q "STOPPED: M2C is a console step performed by a person" && echo "$out" | grep -q -- "--yes does not cover manual steps"
ck "M2C (the Super Admin grant) blocks for a human and is never attested by --yes" $?
python3 - "$SCRIPT" "$WORK/good.env" <<'PYEOF'
import argparse, importlib.util, inspect, re, sys
spec = importlib.util.spec_from_file_location("ws", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["ws"] = m
spec.loader.exec_module(m)
src = open(sys.argv[1]).read()
cfg = m.derive_config(m.load_config(sys.argv[2]))
steps = {s.ident: s for s in m.manual_steps(m.Ctx(cfg, argparse.Namespace()))}
ok = (
    "M2C" in steps and steps["M2C"].verifier == "verify_super_admin_grant"
    and "M5S" in steps
    and not any(l.strip().startswith("Confirm") and "NOT a super admin" in l for s in steps.values() for l in s.lines)
    and not hasattr(m, "ROLE_READER_NAME") and not hasattr(m, "ROLE_OPERATOR_NAME")
    and not hasattr(m, "READ_PRIVILEGE_ALLOWLIST") and not hasattr(m, "READER_PRIVILEGE_CANDIDATES")
    and not hasattr(m, "check_stage0_role_has_no_write") and not hasattr(m, "check_robot_credential_is_read_only")
    # phase 2 builds Eve's role only, and assigns only Eve's
    and re.findall(r"ensure_role\(\s*ctx, (\w+)", inspect.getsource(m.phase_2_roles)) == ["ROLE_EVE_NAME"]
    and "super_admin_grant_on_file(ctx)" in inspect.getsource(m.cmd_workspace)
    # never makeAdmin, never a Super Admin insert, from this script
    and ".makeAdmin(" not in src
    and src.count("roleAssignments().insert(") == 1
    and set(m.SERVICE_ACCOUNT_IDS) >= {"walle-actions", "walle-actions-super"}
    and m.SECRET_READERS["walle-super-refresh-token"] == "SA_ACTIONS_SUPER"
    and m.SECRET_READERS["walle-refresh-token"] == "SA_ACTIONS"
    and [n for n, _p, _f in m.CHECKS if n in ("robot_hardening_and_roster", "no_cloud_platform_scope",
         "hard_denied_list", "secret_readers_split", "super_service_allowlists", "eve_role_is_read_only",
         "robot_credentials_scoped")].__len__() == 7
)
sys.exit(0 if ok else 1)
PYEOF
ck "retired Wall-E roles are gone from the code, phase 2 builds Eve's role only, the script never mints a super admin, M2C/M5S exist" $?
cp "$WORK/good.env" "$WORK/rb.env"; printf 'export SUPER_REFRESH_TOKEN_VERSION="3"\n' >> "$WORK/rb.env"
: > "$WALLE_CALL_LOG"
out="$(walle --config "$WORK/rb.env" --dry-run --yes rollback --phase 9 --super 2>&1)"
echo "$out" | grep -q "WOULD RUN: gcloud secrets versions destroy 3 --secret walle-super-refresh-token" && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"
ck "rollback --phase 9 --super targets the band-B token, and --dry-run destroys nothing" $?
: > "$WALLE_CALL_LOG"
harness main --dry-run --yes teardown >/dev/null 2>&1
grep -q "run services describe walle-actions-super" "$WALLE_CALL_LOG" && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"
ck "teardown knows walle-actions-super, and teardown --dry-run deletes nothing" $?

echo "=== every cross-project read names the other project, never Wall-E's"
out="$(harness fn gcloud_probe_json_in test-walle projects describe test-walle 2>&1)"; rc=$?
[ $rc -ne 0 ] && echo "$out" | grep -q "Wall-E's own project"; ck "gcloud_probe_json_in refuses Wall-E's own project id" $?
: > "$WALLE_CALL_LOG"
harness main --yes register >/dev/null 2>&1
grep -q 'HTTP GET .*/projects/test-gemini/locations/eu/collections/default_collection/engines/' "$WALLE_CALL_LOG" \
  && ! grep -q 'HTTP GET .*/projects/test-walle/locations/eu/' "$WALLE_CALL_LOG"
ck "register reads the Gemini Enterprise app under GEMINI_PROJECT, never PROJECT" $?

echo
echo "$pass passed, $fail failed"
exit $([ "$fail" -eq 0 ] && echo 0 || echo 1)
