#!/usr/bin/env bash
# tests/run-tests.sh: offline tests of agp-platform. Nothing contacts Google: gcloud, bq and curl are
# the fakes in tests/fake-bin, in a throwaway HOME.
#   bash tests/run-tests.sh              every phase, in order, each building on the one before
#   bash tests/run-tests.sh --only 10    one phase (or a list) in a world where every earlier phase is done
#   bash tests/run-tests.sh --selftest   the runner alone, against tests/fixtures/sample-phase.sh
# AGP_SETUP_DIR names the wiki's setup/ folder when automation/ does not sit inside it.
#
# What it proves: every file parses and passes shellcheck at warning level; every step of every page
# in scope is registered; files copied from the pages are byte-identical to their heredocs; plan never
# runs a mutating command; apply runs to the end, stopping only where a person must act (the test
# stands in for that person); and a second apply changes nothing.
#
# What a fake cannot prove: that Google accepts a command, or that a read returns a particular value.
# So when a read-only verification step (AUTO-READ) fails in the fake world, the test records a note
# with its output and stands in for it, as for a person, instead of failing; an AUTO step that fails,
# or whose check still fails after it ran, is a failure.
set -o pipefail
T="$(cd "$(dirname "$0")" && pwd)"; A="$(dirname "$T")"; A_FULL="$A"
SETUP_DIR="${AGP_SETUP_DIR:-$(dirname "$A")}"
SELFTEST=0; ONLY=""
case "${1-}" in --selftest) SELFTEST=1;; --only) ONLY="$2";; esac
pass=0; fail=0; warn=0
ok()   { pass=$((pass + 1)); printf 'ok    %s\n' "$*"; }
ko()   { fail=$((fail + 1)); printf 'FAIL  %s\n' "$*"; }
note() { warn=$((warn + 1)); printf 'note  %s\n' "$*"; }

W="$(mktemp -d "${TMPDIR:-/tmp}/agp-test.XXXXXX")"
cd "$W" || exit 2   # nothing a test runs may write into the folder it was started from
[ -n "${AGP_TEST_KEEP-}" ] && echo "keeping $W" || trap 'rm -rf "$W"' EXIT
if [ $SELFTEST = 1 ]; then
  cp -R "$A" "$W/automation"; rm -f "$W/automation"/phases/*.sh
  cp "$T/fixtures/sample-phase.sh" "$W/automation/phases/90-sample.sh"
  A="$W/automation"
fi
if [ -n "$ONLY" ]; then
  cp -R "$A" "$W/automation"; rm -f "$W/automation"/phases/*.sh
  for n in $(echo "$ONLY" | tr ',' ' '); do cp "$A"/phases/"$n"-*.sh "$W/automation/phases/" || { echo "no phase file $n"; exit 2; }; done
  A="$W/automation"
fi
AGP="$A/agp-platform"

# ---- 1. syntax and lint
for f in "$AGP" "$A"/lib/*.sh "$A"/phases/*.sh; do
  [ -f "$f" ] || continue
  bash -n "$f" 2>"$W/err" && ok "syntax $(basename "$f")" || ko "syntax $(basename "$f"): $(head -1 "$W/err")"
done
SC="$(command -v shellcheck || echo "$HOME/Claude/.agent-work/buildenv/bin/shellcheck")"
if [ -x "$SC" ]; then
  if "$SC" -S warning -s bash -e SC2034,SC1090,SC1091 "$AGP" "$A"/lib/*.sh "$A"/phases/*.sh > "$W/sc" 2>&1; then ok "shellcheck (warning level)"
  else ko "shellcheck: $(grep -c '^In ' "$W/sc") issues"; sed 's/^/      /' "$W/sc" | head -60; fi
else note "shellcheck not installed; lint skipped"; fi
python3 -m py_compile "$A/lib/agp_json.py" && ok "agp_json.py compiles" || ko "agp_json.py"

# ---- 2. assets are byte-identical to the pages' heredocs
extract_heredoc() {   # extract_heredoc PAGE "exact opening line": the body up to its terminator
  python3 - "$1" "$2" <<'PY'
import re, sys
page, opener = sys.argv[1], sys.argv[2]
lines = open(page, encoding='utf-8').read().split('\n')
try:
    i = lines.index(opener)
except ValueError:
    sys.exit(3)
term = re.search(r"<<-?'?\"?([A-Za-z_][A-Za-z0-9_]*)", opener).group(1)
out = []
for l in lines[i + 1:]:
    if l == term:
        break
    out.append(l)
sys.stdout.write('\n'.join(out) + '\n')
PY
}
if [ $SELFTEST = 0 ]; then
  for mf in "$A"/assets/*.manifest; do
    if [ -n "$ONLY" ]; then case ",$ONLY," in *",$(basename "$mf" .manifest),"*) ;; *) continue;; esac; fi
    [ -f "$mf" ] || continue
    while IFS='	' read -r asset page opener; do
      case "$asset" in ''|'#'*) continue;; esac
      if extract_heredoc "$SETUP_DIR/$page" "$opener" > "$W/asset" 2>/dev/null; then
        cmp -s "$W/asset" "$A/assets/$asset" && ok "asset $asset identical to setup/$page" \
          || ko "asset $asset differs from setup/$page (opener: $opener)"
      else ko "asset $asset: opener not found in setup/$page: $opener"; fi
    done < "$mf"
  done
fi

# ---- 3. registry, coverage of the pages, offline plan
PYTHONUSERBASE="$(python3 -m site --user-base 2>/dev/null)"; export PYTHONUSERBASE   # keep the real user's packages
export HOME="$W/home"; mkdir -p "$HOME"
export PATH="$T/fake-bin:$PATH" FAKE_STATE="$W/state.json" FAKE_LOG="$W/calls.tsv" FAKE_ACCOUNT="sa-1-admin@example.test"
unset CLOUDSDK_CONFIG CLOUDSDK_ACTIVE_CONFIG_NAME CLOUDSDK_CORE_PROJECT PLATFORM_ENV_FILE PROJECT BUILD_LOG_DIR PLATFORM_REPO_DIR
: > "$FAKE_LOG"
git config --global user.email owner@example.test; git config --global user.name "Platform Owner (test)"
git config --global init.defaultBranch main

"$AGP" list --all > "$W/list" 2>"$W/err" && ok "registry: $(wc -l < "$W/list" | tr -d ' ') steps in $(cut -f1 "$W/list" | sort -u | wc -l | tr -d ' ') phases" \
  || { ko "registry: $(head -3 "$W/err")"; exit 1; }
if [ $SELFTEST = 0 ]; then
  "$AGP" phases > "$W/phases"
  while IFS='	' read -r pid page scope title; do
    [ -f "$SETUP_DIR/$page" ] || { ko "phase $pid: setup/$page not found"; continue; }
    grep -oE '^#{3,4} [A-Z]{2,3}-[0-9]+(\.[0-9]+)?[a-z]?' "$SETUP_DIR/$page" | sed -E 's/^#+ //' | grep -E "^($scope)" | sort -u > "$W/ids-page"
    awk -F'\t' -v p="$pid" '$1 == p {print $2}' "$W/list" | sort -u > "$W/ids-reg"
    miss="$(comm -23 "$W/ids-page" "$W/ids-reg" | tr '\n' ' ')"; extra="$(comm -13 "$W/ids-page" "$W/ids-reg" | tr '\n' ' ')"
    if [ -z "$miss" ] && [ -z "$extra" ]; then ok "phase $pid registers every step of setup/$page ($(wc -l < "$W/ids-reg" | tr -d ' '))"
    else ko "phase $pid vs setup/$page: missing [${miss% }] extra [${extra% }]"; fi
  done < "$W/phases"
fi
"$AGP" plan --all --offline > "$W/plan-offline" 2>"$W/err" && ok "plan --offline with no ~/.platform-env" || ko "plan --offline: $(head -3 "$W/err")"
[ "$(grep -c MUTATE "$FAKE_LOG")" = 0 ] && ok "plan --offline ran no command" || ko "plan --offline ran a mutating command"

# ---- helpers for the world
fakeval() {     # a plausible value for a name, acceptable to penv_set
  case "$1" in
    ORG_ID|*_ORG_ID) echo 123456789012;;
    *PROJECT_NUMBER*) echo 123456789012;;
    *_PROJECT|*_PROJECT_ID) echo "agp-test-$(echo "$1" | tr 'A-Z_' 'a-z-' | cut -c1-14)";;
    *REMOTE*) local u; u="git@github.com:example-org/$(echo "$1" | tr 'A-Z_' 'a-z-').git"; mkdir -p "$W/remotes"
              [ -d "$W/remotes/$1.git" ] || git init -q --bare "$W/remotes/$1.git"
              git config --global "url.$W/remotes/$1.git.insteadOf" "$u"; echo "$u";;   # a real-shaped URL served locally
    *BILLING_ACCOUNT*) echo 000000-AAAAAA-BBBBBB;;
    BILLING_CURRENCY) echo EUR;;
    FLD_*) echo 987654321098;;
    *_DS) echo "$1" | sed 's/_DS$//' | tr 'A-Z' 'a-z';;
    GIT_HOST) echo github.com;;
    GIT_OIDC_ISSUER) echo https://token.actions.githubusercontent.com;;
    GIT_ORG) echo example-org;;
    SCC_TIER) echo PREMIUM/eu;;
    *PARENT*) echo organizations/123456789012;;
    ENT_*) echo "projects/agp-test-core/locations/global/entitlements/$(echo "${1#ENT_}" | tr 'A-Z_' 'a-z-')";;
    SA_1_ADMIN|SA_2_ADMIN|SANDBOX_SA_*) echo "$(echo "$1" | tr 'A-Z_' 'a-z-')@example.test";;
    SA_*|*_SA) echo "$(echo "$1" | tr 'A-Z_' 'a-z-' | cut -c1-28)@agp-test-core.iam.gserviceaccount.com";;
    *EMAIL*|*ADMIN*|*ACCOUNT*|*_GROUP|GRP_*|BRK_*) echo "$(echo "$1" | tr 'A-Z_' 'a-z-')@example.test";;
    *DAYS*) echo 400;;
    *REGION*) echo europe-west1;;
    BQ_LOCATION|*_LOCATION) echo EU;;
    *CUSTOMER_ID*) echo C0fake12;;
    *BILLING_ACCOUNT*) echo 000000-AAAAAA-BBBBBB;;
    *DOMAIN*) echo example.test;;
    *EXPIRY*|*_DATE) echo 2026-12-31;;
    *FOLDER*ID*|*_ID) echo 987654321098;;
    *_DIR) mkdir -p "$HOME/platform/test-$(echo "$1" | tr 'A-Z_' 'a-z-')"; echo "$HOME/platform/test-$(echo "$1" | tr 'A-Z_' 'a-z-')";;
    *_FILE|*REGISTER|*CALENDAR) echo "$HOME/platform/test-$(echo "$1" | tr 'A-Z_' 'a-z-')";;
    *) echo "fake-$(echo "$1" | tr 'A-Z_' 'a-z-')";;
  esac
}
have_env() { [ -f "$HOME/.platform-env" ] && grep -q '^penv_set()' "$HOME/.platform-env"; }
penv_in() {     # penv_in NAME VALUE: penv_set inside a shell that sourced the env file (no-op before it exists)
  have_env || return 0
  bash -c '. "$HOME/.platform-env" >/dev/null 2>&1; has() { v="$(_penv_get "$1")"; case "$v" in ""|"*tbd*") return 1;; esac; }; has "$1" || penv_set "$1" "$2" >/dev/null 2>&1' _ "$1" "$2"
}
stand_in() {    # stand_in STEP_ID NOTE: the DONE line a person would have written, then the step's outputs
  local sid="$1" sets n
  if have_env && bash -c '. "$HOME/.platform-env" >/dev/null 2>&1; [ -f "$BUILD_LOG_DIR/checkpoints.tsv" ]'; then
    bash -c '. "$HOME/.platform-env" >/dev/null 2>&1; checkpoint "$1" DONE witness@example.test - "$2"' _ "$sid" "$2" >/dev/null 2>&1
  else
    mkdir -p "$BLD"; printf '%s\t%s\tDONE\towner@example.test\twitness@example.test\t-\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$sid" "$2" >> "$BLD/.agp-pending-checkpoints.tsv"
  fi
  sets="$(awk -F'\t' -v s="$sid" '$2 == s {print $8}' "$W/list-full")"
  for n in $sets; do [ "$n" = "-" ] || penv_in "$n" "$(fakeval "$n")"; done
  python3 "$T/standin.py" "$sid" "$T/standins" >> "$W/standins.log" 2>&1
}
run_apply() {   # run_apply AGP PHASES LABEL: apply with stand-ins; 0 when it reached the end
  local agp="$1" phases="$2" label="$3" from="" iter=0 rc stop sid irrev skipid
  irrev="$("$agp" list --all --irreversible | cut -f2 | paste -sd, -)"
  LAST_STOP=""; PASSED=" "
  MANUAL=0; VERIF=0
  while [ $iter -lt 900 ]; do
    iter=$((iter + 1))
    # shellcheck disable=SC2086
    "$agp" apply --phase "$phases" --confirm-irreversible "${irrev:-none}" --witness witness@example.test $from > "$W/apply.out" 2>&1 < /dev/null
    rc=$?
    [ $rc = 0 ] && return 0
    stop="$(grep '^STOPPED: ' "$W/apply.out" | tail -1)"
    sid="$(echo "$stop" | sed -E 's/^STOPPED: ([^:]+):.*/\1/')"
    if [ -n "$sid" ] && [ "$stop" = "${LAST_STOP-}" ]; then
      ko "$label: stopped twice at $sid, even after standing in: ${stop#STOPPED: }"; sed 's/^/      /' "$W/apply.out" | tail -12; return 1
    fi
    LAST_STOP="$stop"
    # manual steps the run passed over (--on-unmet skip): a person did them as the run went by, so their
    # stand-in rows are applied now, in order, before this stop is handled
    for skipid in $(sed -nE 's/^ *\[(MANUAL|BLOCKED)\] +([A-Z0-9]+-[0-9.]+[a-z]?) .*/\2/p' "$W/apply.out"); do
      case "$PASSED" in *" $skipid "*) continue;; esac
      [ "$skipid" = "$sid" ] && continue
      PASSED="$PASSED$skipid "
      have_env && python3 "$T/standin.py" "$skipid" "$T/standins" >> "$W/standins.log" 2>&1
    done
    awk -v s="$sid" '$0 ~ ("\\] +" s " ") {f=1} f' "$W/apply.out" > "$W/step.out"
    case "$stop" in
      *"agp-platform done"*) MANUAL=$((MANUAL + 1)); stand_in "$sid" "test stand-in for a person"; from="--from $sid";;
      *"a person must act first"*)
        VERIF=$((VERIF + 1))
        note "$label: $sid stopped for a person's precondition, stood in: $(grep -E 'STOP|FAIL' "$W/step.out" | grep -v '^STOPPED' | head -1 | tr -s ' ' | cut -c1-200)"
        stand_in "$sid" "test stand-in: a person's precondition"; from="--from $sid";;
      *"the verification failed"*)
        VERIF=$((VERIF + 1))
        note "$label: $sid verification failed in the fake world, stood in: $(grep -E 'FAIL|STOP|ERROR' "$W/step.out" | grep -v '^STOPPED' | head -2 | tr '\n' ' ' | tr -s ' ' | cut -c1-200)"
        stand_in "$sid" "test stand-in: verification needs real Google"; from="--from $sid";;
      *": missing "*)
        for n in $(echo "$stop" | sed -E 's/.*: missing //'); do
          penv_in "$n" "$(fakeval "$n")"; note "$label: $sid needed $n, which no earlier step sets (supplied by the test)"
        done
        have_env || { ko "$label: $sid needs$(echo "$stop" | sed -E 's/.*: missing//') before ~/.platform-env exists"; return 1; }
        from="--from $sid";;
      *) ko "$label stopped at $sid: ${stop#STOPPED: }"; sed 's/^/      /' "$W/apply.out" | tail -15; return 1;;
    esac
  done
  ko "$label: more than 900 resumptions"; return 1
}

# ---- 4. the world
PRD="$HOME/platform/agentic-platform"; BLD="$HOME/platform/build-log"
export AGP_PLATFORM_REPO_DIR="$PRD" AGP_BUILD_LOG_DIR="$BLD" AGP_GIT_EMAIL=owner@example.test AGP_GIT_NAME="Platform Owner (test)"
export BLD PRD AGP_WAIT_SCALE=0   # standin.py expands $BLD and $PRD; phases scale their waits by AGP_WAIT_SCALE
STAND="$W/decision-standins"; mkdir -p "$STAND"
printf '#!/bin/sh\n# test stand-in: every decision reads as signed\nfor i in "$@"; do echo "SIGNED $i"; done\n' > "$STAND/decision-need.sh"
printf '#!/bin/sh\n# test stand-in: every record parses and is signed\nexit 0\n' > "$STAND/decision-check.sh"
declare -f fakeval > "$W/fakeval.sh"
cat > "$STAND/decision-value.sh" <<EOF
#!/bin/bash
# test stand-in: decision-value.sh ID NAME prints a plausible value for NAME
. "$W/fakeval.sh"; fakeval "\$2"
EOF
chmod +x "$STAND"/*.sh; export AGP_DECISION_DIR="$STAND"
"$A_FULL/agp-platform" list --all > "$W/list-full" 2>/dev/null

if [ $SELFTEST = 1 ]; then
  mkdir -p "$PRD" "$BLD"; git init -q "$PRD"; git init -q "$BLD"
  awk '/<<.PLATFORM_ENV_TEMPLATE.$/ {f=1; next} /^PLATFORM_ENV_TEMPLATE$/ {f=0} f' "$SETUP_DIR/01-prerequisites-and-conventions.md" > "$W/tpl"
  install -m 600 "$W/tpl" "$HOME/.platform-env"
  penv_in PLATFORM_ENV_FILE "$HOME/.platform-env"; penv_in GCLOUD_CONFIG_NAME platform-bootstrap
  penv_in PLATFORM_REPO_DIR "$PRD"; penv_in BUILD_LOG_DIR "$BLD"; penv_in EVIDENCE_REGISTER "$BLD/evidence.md"
  printf 'time\tstep\tstatus\tby\twitness\tevidence\tnote\n' > "$BLD/checkpoints.tsv"; : > "$BLD/evidence.md"
  git -C "$BLD" add -A >/dev/null; git -C "$BLD" commit -qm world >/dev/null
  mkdir -p "$HOME/.config/gcloud-platform-bootstrap/configurations"; : > "$HOME/.config/gcloud-platform-bootstrap/configurations/config_platform-bootstrap"
  penv_in SA_1_ADMIN "$FAKE_ACCOUNT"
elif [ "$ONLY" = 01 ]; then
  : # phase 01 builds the world itself, below
elif [ -z "$ONLY" ]; then
  # the full run: phase 01 first, because it creates ~/.platform-env; every other phase runs below
  BUILD_LOG_DIR="$BLD" run_apply "$A_FULL/agp-platform" 01 "phase 01" || WORLD_FAIL=1
  [ -z "${WORLD_FAIL-}" ] && ok "full run: phase 01 applied first ($MANUAL manual steps stood in for)"
else
  # every earlier phase is done: phase 01 really, then stand-ins for the rest
  BUILD_LOG_DIR="$BLD" run_apply "$A_FULL/agp-platform" 01 "world (phase 01)" || WORLD_FAIL=1
  first="$(echo "$ONLY" | tr ',' '\n' | sort | head -1)"
  awk -F'\t' -v f="$first" '$1 != "01" && $1 < f {print $2}' "$W/list-full" | while read -r sid; do stand_in "$sid" "test stand-in: earlier phase"; done
  ok "world: phase 01 applied; $(awk -F'\t' -v f="$first" '$1 != "01" && $1 < f' "$W/list-full" | wc -l | tr -d ' ') steps of earlier phases stood in"
fi
if have_env; then
  "$AGP" names --all > "$W/names" 2>&1
  supplied="$(awk '/must be supplied/ {f=1; next} f && /^  / {print $1}' "$W/names")"
  for n in $supplied; do penv_in "$n" "$(fakeval "$n")"; done
  if [ -n "$ONLY" ]; then   # world rows only from the phases under test; a full run builds its world by running
    world_files=""; for n in $(echo "$ONLY" | tr ',' ' '); do [ -f "$T/standins/$n.tsv" ] && world_files="$world_files $T/standins/$n.tsv"; done
    # shellcheck disable=SC2086
    [ -n "$world_files" ] && python3 "$T/standin.py" '*' $world_files >> "$W/standins.log" 2>&1
  fi
  for rv in PLATFORM_REPO_REMOTE BUILD_LOG_REMOTE; do   # local bare remotes, so pull and push work
    rem="$(bash -c '. "$HOME/.platform-env" >/dev/null 2>&1; printf %s "${'$rv'-}"')"
    case "$rv" in PLATFORM_REPO_REMOTE) repo="$PRD";; *) repo="$BLD";; esac
    if [ -n "$rem" ] && [ -d "$repo/.git" ]; then
      git -C "$repo" remote get-url origin >/dev/null 2>&1 || git -C "$repo" remote add origin "$rem"
      git -C "$repo" rev-parse -q --verify HEAD >/dev/null && git -C "$repo" push -q -u origin HEAD:main 2>/dev/null
    fi
  done
  if [ -n "$ONLY" ]; then   # the projects earlier phases would have made exist in the fake; not those the phases under test set
    own="$(awk -F'\t' -v ph=",$ONLY," 'index(ph, "," $1 ",") {print $8}' "$W/list-full" | tr ' ' '\n' | grep -v '^-$' | sort -u | tr '\n' ' ')"
    OWN=" $own " bash -c '. "$HOME/.platform-env" >/dev/null 2>&1; for n in $(_penv_names); do case "$n" in *_PROJECT) case "$OWN" in *" $n "*) continue;; esac; v="$(_penv_get "$n")"; case "$v" in ""|"*tbd*") ;; *) echo "$v";; esac;; esac; done' \
      | python3 -c 'import json,os,sys; p=os.environ["FAKE_STATE"]; st=json.load(open(p)) if os.path.exists(p) else {"mutations":0,"seen":{},"bindings":[]}; st.setdefault("projects",[]); [st["projects"].append(x) for x in sys.stdin.read().split() if x not in st["projects"]]; json.dump(st, open(p,"w"))'
  fi
  ok "world: $(echo "$supplied" | wc -w | tr -d ' ') supplied names given fake values"
fi

# ---- 5. plan with checks: nothing mutates
if [ -n "${WORLD_FAIL-}" ]; then ko "the world could not be built: phase 01 fails (run --only 01)"
  printf '\n%d passed, %d failed, %d notes\n' "$pass" "$fail" "$warn"; exit 1; fi
: > "$FAKE_LOG"
[ -f "$FAKE_STATE" ] && cp "$FAKE_STATE" "$W/state-before-plan.json"
"$AGP" plan --all > "$W/plan" 2>"$W/err"; rc=$?
[ -f "$W/state-before-plan.json" ] && cp "$W/state-before-plan.json" "$FAKE_STATE" || rm -f "$FAKE_STATE"
[ $rc = 0 ] && ok "plan --all exit 0" || ko "plan --all exit $rc: $(tail -3 "$W/err")"
m="$(grep -c '	MUTATE	' "$FAKE_LOG")"; [ "$m" = 0 ] && ok "plan ran $(wc -l < "$FAKE_LOG" | tr -d ' ') reads and no mutation" \
  || { ko "plan ran $m mutating commands"; grep '	MUTATE	' "$FAKE_LOG" | head -5 | sed 's/^/      /'; }
grep -q '\[UNKNOWN\]' "$W/plan" && note "plan shows UNKNOWN steps: $(grep '\[UNKNOWN\]' "$W/plan" | head -3 | tr -s ' ')" || ok "plan has no UNKNOWN step"

# ---- 6. apply every selected phase, standing in for the person at each manual step
PHASES="$(cut -f1 "$W/list" | uniq | paste -sd, -)"
applied_ok=0
if BUILD_LOG_DIR="$BLD" run_apply "$AGP" "$PHASES" "apply"; then
  applied_ok=1; ok "apply reached the end of phases $PHASES ($MANUAL manual steps and $VERIF verifications stood in for)"
fi

# ---- 7. a second apply changes nothing
if [ $applied_ok = 1 ]; then
  IRREV="$("$AGP" list --all --irreversible | cut -f2 | paste -sd, -)"
  before="$(grep -c '	MUTATE	' "$FAKE_LOG")"
  "$AGP" apply --phase "$PHASES" --confirm-irreversible "${IRREV:-none}" --witness witness@example.test > "$W/apply2.out" 2>&1 < /dev/null; rc=$?
  after="$(grep -c '	MUTATE	' "$FAKE_LOG")"
  [ $rc = 0 ] && [ "$before" = "$after" ] && ok "second apply: no mutation ($before before, $after after)" \
    || { ko "second apply: exit $rc, mutations $before -> $after"; grep '	MUTATE	' "$FAKE_LOG" | tail -n $((after - before)) | head -8 | sed 's/^/      /'; tail -5 "$W/apply2.out" | sed 's/^/      /'; }
fi
grep -q 'ya29\.\|1//0\|GOCSPX-' "$FAKE_LOG" "$W"/*.out "$W/plan" 2>/dev/null && ko "a credential-shaped string was printed" || ok "no credential-shaped string printed"

printf '\n%d passed, %d failed, %d notes\n' "$pass" "$fail" "$warn"
[ $fail = 0 ]
