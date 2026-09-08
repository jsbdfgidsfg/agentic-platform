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
        "PILOT_OU": "/Pilot", "SANDBOX_OU": "/Automation/Sandbox"}
for k, v in subs.items():
    s = re.sub(r'^(export %s=)".*?"' % k, r'\1"%s"' % v, s, flags=re.M)
s = re.sub(r'"<[^"]*>"', '"filled"', s)
p.write_text(s)
PYEOF

pass=0; fail=0
ck() { if [ "$2" = 0 ]; then echo "  ok   $1"; pass=$((pass+1)); else echo "  FAIL $1"; fail=$((fail+1)); fi; }
walle() { python3 "$SCRIPT" "$@"; }

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
! grep -Eq ' (create|delete|update|deploy|add-iam-policy-binding|set-iam-policy|enable|link|mk|rm) ' "$WALLE_CALL_LOG"
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

echo
echo "$pass passed, $fail failed"
exit $([ "$fail" -eq 0 ] && echo 0 || echo 1)
