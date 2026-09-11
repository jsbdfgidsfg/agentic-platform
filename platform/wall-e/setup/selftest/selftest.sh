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
  *"get-iam-policy"*) echo '{"bindings":[]}'; exit 0;;
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
        "MO_PRINCIPAL": "serviceAccount:mo-analyst@test-walle.iam.gserviceaccount.com",
        "PROJECT_NUMBER": "111222333444", "REFRESH_TOKEN_VERSION": "7",
        "ACTIONS_URL": "https://walle-actions-abc.a.run.app"}
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
    with open(os.environ["WALLE_CALL_LOG"], "a") as h: h.write("HTTP %s %s\n" % (method, url))
    return 200, {}
m.list_engines, m.describe_engine, m.http_json = fake_list, fake_describe, fake_http
argv = sys.argv[4:]
if mode == "main":
    sys.exit(m.main(["--config", work + "/good.env"] + argv))
cfg = m.derive_config(m.load_config(work + "/good.env"))
ns = argparse.Namespace(dry_run="--dry-run" in argv, yes=True, verbose=False, config=None,
                        command="deploy", skip_build=True,
                        skip_deny_policy="--skip-deny-policy" in argv)
ctx = m.Ctx(cfg, ns)
try:
    if mode == "phase12":
        m.phase_12_agent(ctx); sys.exit(0)
    if mode == "check":
        status, detail = getattr(m, argv[0])(ctx)
        print("%s %s" % (status, detail)); sys.exit(0 if status == "PASS" else 1)
except m.WalleError as exc:
    print("STOPPED: %s" % exc); sys.exit(1)
PYEOF
harness() { python3 "$WORK/harness.py" "$SCRIPT" "$WORK" "$@"; }
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
walle --config "$WORK/good.env" --yes gcp >/dev/null 2>&1
n=$(wc -l < "$WALLE_CALL_LOG" | tr -d ' ')
[ "$n" -gt 40 ]; ck "gcp issued $n commands" $?

echo "=== corrections that were expensive to find"
! grep -q -- "--paused" "$WALLE_CALL_LOG";                  ck "scheduler: no --paused flag" $?
! grep -q "reasoningEngineUser" "$WALLE_CALL_LOG";          ck "no fictional reasoningEngineUser role" $?
! grep -q "bq add-iam-policy-binding" "$WALLE_CALL_LOG";    ck "no bq add-iam-policy-binding on a dataset" $?
! grep -q "replication-policy=automatic" "$WALLE_CALL_LOG"; ck "secrets are not multi-region" $?
grep -q "secrets create.*--location" "$WALLE_CALL_LOG";     ck "secrets are regional" $?
grep -qE "ec-sign-p256-sha256|asymmetric-signing" "$WALLE_CALL_LOG"; ck "Eve's KMS key is asymmetric" $?
grep -q "roles/datastore.user" "$WALLE_CALL_LOG";           ck "service accounts get project roles" $?
! grep -q "gcloud ai reasoning-engines" "$WALLE_CALL_LOG";  ck "no non-existent gcloud ai group" $?
! grep -qE "gcloud monitoring channels" "$WALLE_CALL_LOG";  ck "monitoring channels via beta" $?

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
grep -q 'mo-analyst@.*roles/agentregistry.viewer' "$WALLE_CALL_LOG" && grep -q 'eve-controller@.*roles/agentregistry.viewer' "$WALLE_CALL_LOG"; ck "viewer to Eve and Mo" $?
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

echo
echo "$pass passed, $fail failed"
exit $([ "$fail" -eq 0 ] && echo 0 || echo 1)
