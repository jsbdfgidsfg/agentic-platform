#!/usr/bin/env bash
# Exercise walle_setup.py without touching Google.
#
# Stubs gcloud, bq and gsutil on PATH, records every invocation, and asserts the
# properties that must hold before anyone runs this against a real tenant. It
# needs no credentials, no project and no network.
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
            "MO_PROJECT": "test-mo", "GEMINI_PROJECT_NUMBER": "555666777888"}
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
argv = sys.argv[4:]
if mode == "main":
    sys.exit(m.main(["--config", work + "/good.env"] + argv))
cfg = m.derive_config(m.load_config(work + "/good.env"))
for key in [k for k in os.environ.get("WALLE_UNSET_KEYS", "").split(",") if k]:
    cfg.pop(key, None)
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
grep -q "projects create test-walle --folder 987654321098" "$WALLE_CALL_LOG"; ck "the project is created under FOLDER_ID" $?
! grep -q "projects create .*--organization" "$WALLE_CALL_LOG"; ck "and not straight under the organisation" $?
[ "$(grep -c 'service-accounts create ' "$WALLE_CALL_LOG")" = 4 ]; ck "exactly four service accounts created" $?
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
: > "$WALLE_CALL_LOG"
harness main --dry-run --yes registry >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ! grep -Eq "$MUTATING" "$WALLE_CALL_LOG"; ck "registry --dry-run issues no mutating command" $?
: > "$WALLE_CALL_LOG"
harness main --yes registry >/dev/null 2>&1; ck "registry runs to completion against the stubs" $?
grep -q 'add-iam-policy-binding test-walle --member serviceAccount:ci-deployer@.*roles/agentregistry.admin' "$WALLE_CALL_LOG"; ck "agentregistry.admin to CI_DEPLOYER" $?
! grep 'roles/agentregistry.admin' "$WALLE_CALL_LOG" | grep -qv 'ci-deployer@'; ck "and to nobody else" $?
! grep -q 'roles/agentregistry.viewer' "$WALLE_CALL_LOG"; ck "no project-level agentregistry.viewer to a foreign identity (decision 43)" $?
! grep -qE 'add-iam-policy-binding test-walle --member serviceAccount:(eve-|mo-)' "$WALLE_CALL_LOG"; ck "registry grants no project-level role to Eve or Mo" $?
grep -q 'agent-registry services create walle-actions .*--endpoint-spec-type=no-spec' "$WALLE_CALL_LOG"; ck "walle-actions registered as NO_SPEC" $?
n=$(grep -c 'agent-registry services create' "$WALLE_CALL_LOG"); [ "$n" -ge 12 ]; ck "essential platform endpoints registered ($n)" $?
! grep 'agent-registry services create' "$WALLE_CALL_LOG" | grep -Eqi 'secretmanager|firestore|admin\.googleapis\.com|bigquery|gmail\.|chat\.googleapis|calendar-json|www\.googleapis\.com'
ck "no forbidden host is ever registered" $?
[ "$(grep -c 'iap web set-iam-policy .*--endpoint=' "$WALLE_CALL_LOG")" = "$n" ]; ck "egressor policy applied per endpoint" $?
grep -q 'agent-gateways import walle-egress' "$WALLE_CALL_LOG"; ck "egress gateway imported" $?
grep -q 'iamEnforcementMode: DRY_RUN' "$WORK/repo/config/gateway/walle-iap-ext.yaml" && grep -q '^failOpen: false$' "$WORK/repo/config/gateway/walle-iap-ext.yaml"
ck "IAP extension starts in DRY_RUN and fail-closed" $?
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
