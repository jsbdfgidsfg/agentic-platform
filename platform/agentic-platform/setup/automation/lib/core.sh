# lib/core.sh: the runner. Sourced by agp-platform; defines no step of its own.
#
# A phase file (phases/NN-*.sh) registers one setup file's steps with `phase`, `requires` and `step`,
# and defines, per step id XX-n.n, the functions s_XX_n_n_check, s_XX_n_n_apply and, for a manual
# step, s_XX_n_n_manual. The runner decides what runs; the phase files only say how.
#
# Contract of a step's functions:
#   _check   read-only. Returns 0 done, 1 not done, 2 cannot tell (stop), 3 not checked (offline).
#            Uses `exists`, `r`, `api GET`, `ckpt_done`, `has_value`; never `x`.
#   _apply   makes the change. Every mutating command goes through `x` (or `api POST|PATCH|PUT`);
#            values go through `pset`. In plan mode `x` and `pset` print and change nothing.
#   _manual  prints what a person must do, where, and how it is recorded (`agp-platform done ID`).
#
# Bash 3.2 compatible (macOS); no associative arrays, no `set -e` (checks return non-zero by design).

set -o pipefail
AGP_VERSION="1.0"
AGP_MODE="plan"            # plan | apply
AGP_OFFLINE=0              # 1: plan without credentials; no read is executed
AGP_CONFIRMED=","          # ,ID,ID, steps whose IRREVERSIBLE confirmation was given on the command line
AGP_WITNESS="-"            # --witness EMAIL, recorded on steps that require one
AGP_FROM=""; AGP_TO=""
AGP_SELECTED=""            # " 09 10 " selected phases
AGP_RUNLOG="/dev/null"
AGP_PLANNED=" "            # names a not-yet-done step in this run would set
AGP_CUR_REMOVES=0          # the current step is allowed to remove (declared --removes)
AGP_CUR_STEP=""
AGP_STOP_REASON=""

# registry (indexed arrays, one row per step)
AGP_N=0
AGP_S_ID=(); AGP_S_PHASE=(); AGP_S_CLASS=(); AGP_S_TITLE=(); AGP_S_IRREV=(); AGP_S_GATE=()
AGP_S_NEEDS=(); AGP_S_SETS=(); AGP_S_ONUNMET=(); AGP_S_REMOVES=(); AGP_S_WITNESS=(); AGP_S_NOTE=()
AGP_P_N=0
AGP_P_ID=(); AGP_P_TITLE=(); AGP_P_FILE=(); AGP_P_ORG=(); AGP_P_BILL=(); AGP_P_SCOPE=()
AGP_CUR_PHASE=""

exec 3>&1   # fd 3: the terminal, even inside $( ) captures
export AGP_CALL_CONTEXT=""   # check | apply | plan: read by the offline fakes only; gcloud ignores it

# ---------------------------------------------------------------- output
agp_say()  { printf '%s\n' "$*" >&3; printf '%s\n' "$*" >> "$AGP_RUNLOG"; }
agp_warn() { printf 'agp-platform: %s\n' "$*" >&2; printf 'WARN %s\n' "$*" >> "$AGP_RUNLOG"; }
agp_die()  { printf 'agp-platform: %s\n' "$*" >&2; exit 2; }

agp_quote() {   # a shell-ready line for display; refuses to show anything shaped like a credential
  local out="" a
  for a in "$@"; do
    case "$a" in ya29.*|1//*|GOCSPX-*|*-----BEGIN*) a="<redacted>";; esac
    case "$a" in
      *[!A-Za-z0-9_./:=@%+,-]*)   # anything a shell would split or expand: single quotes, or %q if it holds one
        case "$a" in *"'"*) out="$out $(printf '%q' "$a")";; *) out="$out '$a'";; esac;;
      '') out="$out ''";;
      *) out="$out $a";;
    esac
  done
  out="${out# }"
  printf '%s' "$out"
}

# ---------------------------------------------------------------- values
# _penv_get comes from ~/.platform-env; a fallback lets `plan --offline` run before setup/01.
if ! command -v _penv_get >/dev/null 2>&1; then
  _penv_get() { case "${1-}" in ''|[0-9]*|*[!A-Za-z0-9_]*) return 2;; esac; eval "printf '%s' \"\${$1-}\""; }
fi

has_value() {   # has_value NAME: 0 when NAME holds a real value (not empty, *tbd* or <placeholder>)
  local v; v="$(_penv_get "$1")" || return 1
  case "$v" in ''|'*tbd*'|*'<'*'>'*) return 1;; esac
  return 0
}

v() {           # v NAME: the value, or <NAME> in plan mode so a printed command stays readable
  if has_value "$1"; then _penv_get "$1"; return 0; fi
  if [ "$AGP_MODE" = apply ]; then printf 'MISSING-%s' "$1"; agp_warn "v: $1 has no value"; return 1; fi
  printf '<%s>' "$1"
}

pset() {        # pset [--force] NAME VALUE: penv_set in apply mode; announced in plan mode
  local force=""
  if [ "${1-}" = "--force" ]; then force="--force"; shift; fi
  if [ "$AGP_MODE" != apply ]; then printf '      would set %s\n' "$1" >&3; return 0; fi
  case "${2-}" in ''|*MISSING-*|'<'*'>') agp_warn "pset: refused to write '$1' with an empty or placeholder value"; return 1;; esac
  if [ -n "$force" ]; then penv_set --force "$1" "$2" >&3; else penv_set "$1" "$2" >&3; fi
}

# ---------------------------------------------------------------- commands
agp_guard_cmd() {   # refuses what the procedures forbid, before anything runs
  local a
  for a in "$@"; do
    case "$a" in --yes|-y) agp_say "      REFUSED: --yes is never used"; return 1;; esac
  done
  case " $* " in
    *" config set project "*|*" config set core/project "*) agp_say "      REFUSED: a default project is never set"; return 1;;
  esac
  if [ "$AGP_CUR_REMOVES" != 1 ]; then
    for a in "$@"; do   # a verb is a whole argument; the same word inside free text (a justification) is not
      case "$a" in
        delete|remove-iam-policy-binding|set-iam-policy|disable|remove|rm|destroy|revoke)
          agp_say "      REFUSED: '$a' in step $AGP_CUR_STEP, which is not declared --removes"; return 1;;
      esac
    done
  fi
  return 0
}

x() {           # x CMD...: a mutating command. Printed in plan mode; run, logged and checked in apply mode
  agp_guard_cmd "$@" || return 97
  local line; line="$(agp_quote "$@")"
  if [ "$AGP_MODE" != apply ]; then printf '      $ %s\n' "$line" >&3; return 0; fi
  printf '      + %s\n' "$line" >&3; printf '+ %s\n' "$line" >> "$AGP_RUNLOG"
  local err rc; err="$(mktemp "${TMPDIR:-/tmp}/agp-err.XXXXXX")"
  "$@" 2>"$err"; rc=$?
  if [ -s "$err" ]; then sed 's/^/        /' "$err" >&2; cat "$err" >> "$AGP_RUNLOG"; fi
  rm -f "$err"
  [ $rc -eq 0 ] || agp_say "      FAILED ($rc): $line"
  return $rc
}

r() {           # r CMD...: a read. Not run offline (returns 3)
  [ "$AGP_OFFLINE" = 1 ] && return 3
  "$@"
}

exists() {      # exists CMD...: 0 present, 1 absent (not found), 2 another error (shown), 3 offline
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local err rc; err="$(mktemp "${TMPDIR:-/tmp}/agp-err.XXXXXX")"
  "$@" >/dev/null 2>"$err"; rc=$?
  if [ $rc -eq 0 ]; then rm -f "$err"; return 0; fi
  if grep -qiE 'NOT_FOUND|not found|does not exist|was not found|404' "$err"; then rm -f "$err"; return 1; fi
  sed 's/^/        /' "$err" >&3; cat "$err" >> "$AGP_RUNLOG"; rm -f "$err"
  return 2
}

nonempty() {    # nonempty CMD...: 0 when the read prints something, 1 when it prints nothing, 2 error, 3 offline
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local out rc; out="$("$@" 2>/dev/null)"; rc=$?
  [ $rc -eq 0 ] || return 2
  case "$out" in ''|'[]'|'{}') return 1;; esac
  return 0
}

has_binding() { # has_binding MEMBER ROLE CMD...: CMD prints an IAM policy as JSON
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local m="$1" role="$2" pol; shift 2
  pol="$("$@" --format=json 2>/dev/null)" || return 2
  printf '%s' "$pol" | python3 "$AGP_HOME/lib/agp_json.py" has-binding "$m" "$role"
}

api() {         # api METHOD URL [BODY_FILE]: a REST call with the active gcloud account's token.
  # The token is passed to curl on standard input (-H @-), never in its arguments. Prints the body.
  # Returns 0 for 2xx, 1 for 404, 2 otherwise. POST, PATCH, PUT and DELETE are mutations.
  local method="$1" url="$2" data="${3-}" code body tok
  case "$method" in
    GET) [ "$AGP_OFFLINE" = 1 ] && return 3;;
    DELETE) if [ "$AGP_CUR_REMOVES" != 1 ]; then agp_say "      REFUSED: DELETE in step $AGP_CUR_STEP, not declared --removes"; return 97; fi
            if [ "$AGP_MODE" != apply ]; then printf '      $ api %s %s\n' "$method" "$url" >&3; return 0; fi;;
    *) if [ "$AGP_MODE" != apply ]; then
         printf '      $ api %s %s\n' "$method" "$url" >&3
         [ -n "$data" ] && [ -f "$data" ] && printf '          body: %s\n' "$(tr -d '\n' < "$data" | cut -c1-300)" >&3
         return 0
       fi;;
  esac
  body="$(mktemp "${TMPDIR:-/tmp}/agp-api.XXXXXX")"
  tok="$(gcloud auth print-access-token 2>/dev/null)" || { rm -f "$body"; agp_warn "api: no access token"; return 2; }
  if [ -n "$data" ]; then
    code="$(printf 'Authorization: Bearer %s\n%s' "$tok" "${AGP_API_PROJECT:+X-Goog-User-Project: $AGP_API_PROJECT}" \
      | curl -sS -o "$body" -w '%{http_code}' -X "$method" -H @- -H 'Content-Type: application/json' --data-binary @"$data" "$url")"
  else
    code="$(printf 'Authorization: Bearer %s\n%s' "$tok" "${AGP_API_PROJECT:+X-Goog-User-Project: $AGP_API_PROJECT}" \
      | curl -sS -o "$body" -w '%{http_code}' -X "$method" -H @- "$url")"
  fi
  tok=""
  [ "$method" = GET ] || printf '+ api %s %s -> %s\n' "$method" "$url" "$code" >> "$AGP_RUNLOG"
  cat "$body"; rm -f "$body"
  case "$code" in 2??) return 0;; 404) return 1;; *) return 2;; esac
}

xw() {          # xw FILE [MODE]: write standard input to FILE in apply mode; announced in plan mode
  local f="$1" mode="${2-}" tmp
  if [ "$AGP_MODE" != apply ]; then printf '      would write %s (%s lines)\n' "$f" "$(wc -l | tr -d ' ')" >&3; return 0; fi
  tmp="$(mktemp "${f}.XXXXXX" 2>/dev/null)" || { agp_warn "xw: cannot write next to $f"; return 1; }
  cat > "$tmp" && { [ -z "$mode" ] || chmod "$mode" "$tmp"; } && mv "$tmp" "$f" || { rm -f "$tmp"; agp_warn "xw: write failed: $f"; return 1; }
  printf '      + wrote %s\n' "$f" >&3; printf '+ wrote %s\n' "$f" >> "$AGP_RUNLOG"
}

ev() {          # ev STEP SLUG E-ID TISAX LOCATION [FILE]: evidence_add in apply mode; announced in plan mode
  if [ "$AGP_MODE" != apply ]; then printf '      would record evidence %s-%s\n' "$1" "$2" >&3; return 0; fi
  evidence_add "$@" >&3
}

agp_pending_ckpt() {    # where DONE lines wait before checkpoints.tsv exists (setup/01 PR-2.4 backfills them)
  local d="${BUILD_LOG_DIR-}"; [ -n "$d" ] || d="${AGP_BUILD_LOG_DIR-}"; [ -n "$d" ] || d="$HOME"
  printf '%s/.agp-pending-checkpoints.tsv' "$d"
}

ckpt_done() {   # ckpt_done STEP_ID: 0 when checkpoints.tsv (or, before it exists, the pending file) has a DONE line
  local f
  for f in "${BUILD_LOG_DIR:-/nonexistent}/checkpoints.tsv" "$(agp_pending_ckpt)"; do
    [ -f "$f" ] || continue
    awk -F'\t' -v s="$1" '$2 == s && $3 == "DONE" {f=1} END {exit f ? 0 : 1}' "$f" && return 0
  done
  return 1
}

jget() { python3 "$AGP_HOME/lib/agp_json.py" get "$@"; }   # jget DOTTED.PATH < json

agp_tool() {    # agp_tool decision-need.sh: setup/03's decision tools, in PLATFORM_REPO_DIR/tools.
                # AGP_DECISION_DIR overrides the directory (the offline tests point it at stand-ins).
  if [ -n "${AGP_DECISION_DIR-}" ]; then printf '%s/%s' "$AGP_DECISION_DIR" "$1"; return 0; fi
  if has_value PLATFORM_REPO_DIR; then printf '%s/tools/%s' "$(_penv_get PLATFORM_REPO_DIR)" "$1"
  else printf '<PLATFORM_REPO_DIR>/tools/%s' "$1"; fi
}

# ---------------------------------------------------------------- registration
phase() {       # phase NN "Title" "setup file" [STEP_ID_REGEX]: the regex limits the page's steps in scope
  AGP_CUR_PHASE="$1"
  AGP_P_ID[$AGP_P_N]="$1"; AGP_P_TITLE[$AGP_P_N]="$2"; AGP_P_FILE[$AGP_P_N]="$3"; AGP_P_SCOPE[$AGP_P_N]="${4:-.*}"
  AGP_P_ORG[$AGP_P_N]=""; AGP_P_BILL[$AGP_P_N]=""
  AGP_P_N=$((AGP_P_N + 1))
}

requires() {    # requires org|billing "permission ...": what preflight tests for the current phase
  local k=$((AGP_P_N - 1))
  case "$1" in
    org) AGP_P_ORG[$k]="${AGP_P_ORG[$k]} $2";;
    billing) AGP_P_BILL[$k]="${AGP_P_BILL[$k]} $2";;
    *) agp_die "requires: unknown scope $1";;
  esac
}

step() {        # step ID CLASS "Title" [--needs "A B"] [--sets "C"] [--gate "SD-13"] [--irreversible]
                #                       [--on-unmet stop|skip] [--removes] [--witness] [--note "B-16"]
  local id="$1" cls="$2" title="$3"; shift 3
  case "$cls" in AUTO|AUTO-READ|CONSOLE|HUMAN|BLOCKED) ;; *) agp_die "step $id: unknown class $cls";; esac
  local needs="" sets="" gate="" irrev=0 onunmet="" removes=0 witness=0 note=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --needs) needs="$2"; shift 2;;
      --sets) sets="$2"; shift 2;;
      --gate) gate="$2"; shift 2;;
      --irreversible) irrev=1; shift;;
      --on-unmet) onunmet="$2"; shift 2;;
      --removes) removes=1; shift;;
      --witness) witness=1; shift;;
      --note) note="$2"; shift 2;;
      *) agp_die "step $id: unknown option $1";;
    esac
  done
  if [ -z "$onunmet" ]; then case "$cls" in BLOCKED) onunmet=skip;; *) onunmet=stop;; esac; fi
  local i=$AGP_N
  AGP_S_ID[$i]="$id"; AGP_S_PHASE[$i]="$AGP_CUR_PHASE"; AGP_S_CLASS[$i]="$cls"; AGP_S_TITLE[$i]="$title"
  AGP_S_IRREV[$i]=$irrev; AGP_S_GATE[$i]="$gate"; AGP_S_NEEDS[$i]="$needs"; AGP_S_SETS[$i]="$sets"
  AGP_S_ONUNMET[$i]="$onunmet"; AGP_S_REMOVES[$i]=$removes; AGP_S_WITNESS[$i]=$witness; AGP_S_NOTE[$i]="$note"
  AGP_N=$((AGP_N + 1))
}

agp_fn() { printf 's_%s' "$(printf '%s' "$1" | tr '.-' '__')"; }

agp_load_phases() {
  local f
  for f in "$AGP_HOME"/phases/[0-9][0-9]-*.sh; do
    [ -f "$f" ] || continue
    # shellcheck disable=SC1090
    . "$f"
  done
}

agp_check_registry() {  # every step has the functions its class needs; ids are unique
  local i fn cls bad=0 seen=" "
  i=0; while [ $i -lt $AGP_N ]; do
    fn="$(agp_fn "${AGP_S_ID[$i]}")"; cls="${AGP_S_CLASS[$i]}"
    case "$seen" in *" ${AGP_S_ID[$i]} "*) echo "duplicate step id ${AGP_S_ID[$i]}" >&2; bad=1;; esac
    seen="$seen${AGP_S_ID[$i]} "
    command -v "${fn}_check" >/dev/null 2>&1 || { echo "${AGP_S_ID[$i]}: no ${fn}_check" >&2; bad=1; }
    case "$cls" in
      AUTO|AUTO-READ) command -v "${fn}_apply" >/dev/null 2>&1 || { echo "${AGP_S_ID[$i]}: no ${fn}_apply" >&2; bad=1; };;
      CONSOLE|HUMAN|BLOCKED) command -v "${fn}_manual" >/dev/null 2>&1 || { echo "${AGP_S_ID[$i]}: no ${fn}_manual" >&2; bad=1; };;
    esac
    i=$((i + 1))
  done
  return $bad
}

# ---------------------------------------------------------------- gates
agp_gate_ok() { # 0 all signed; 1 one unsigned (printed); 2 the decision tool is missing
  local g tool; tool="$(agp_tool decision-need.sh)"
  [ -n "$*" ] || return 0
  [ -x "$tool" ] || return 2
  for g in "$@"; do
    "$tool" "$g" >/dev/null 2>&1 || { printf '%s' "$g"; return 1; }
  done
  return 0
}

agp_confirm_irreversible() {    # agp_confirm_irreversible ID TITLE
  case "$AGP_CONFIRMED" in *",$1,"*) return 0;; esac
  local ans=""
  { printf '\n      IRREVERSIBLE: %s, %s\n' "$1" "$2"
    printf '      This cannot be undone or renamed later. Type the step id (%s) to proceed, anything else to stop: ' "$1"; } >&3
  if ! read -r ans < /dev/tty 2>/dev/null; then
    agp_say "      no terminal: pass --confirm-irreversible $1 to confirm this step"; return 1
  fi
  [ "$ans" = "$1" ]
}

# ---------------------------------------------------------------- the step runner
agp_selected() {    # is step index $1 inside --phase, --from and --to?
  local i=$1
  case "$AGP_SELECTED" in *" ${AGP_S_PHASE[$i]} "*) ;; *) return 1;; esac
  return 0
}

agp_mark() {    # agp_mark STATE ID CLASS TITLE [DETAIL]
  local flag=""; [ "${AGP_S_IRREV[$AGP_I]}" = 1 ] && flag=" IRREVERSIBLE"
  agp_say "$(printf '  %-11s %-9s %-9s %s%s' "[$1]" "$2" "$3" "$4" "$flag")"
  [ -z "${5-}" ] || agp_say "              $5"
}

agp_stop() { AGP_STOP_REASON="$1"; }

agp_write_done() {   # agp_write_done ID WITNESS NOTE: the DONE line, in checkpoints.tsv or, before setup/01 PR-2.4, the side file
  if command -v checkpoint >/dev/null 2>&1 && has_value BUILD_LOG_DIR && [ -f "$(_penv_get BUILD_LOG_DIR)/checkpoints.tsv" ]; then
    checkpoint "$1" DONE "$2" - "$3" >/dev/null
  else
    printf '%s\t%s\tDONE\t%s\t%s\t-\t%s, before PR-2.4\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" \
      "$(git config user.email 2>/dev/null || echo -)" "$2" "$3" >> "$(agp_pending_ckpt)"
  fi
}

agp_plans() {   # agp_plans STEP_INDEX: in plan mode, names the step would set count as coming
  [ "$AGP_MODE" = apply ] && return 0
  local n; for n in ${AGP_S_SETS[$1]}; do AGP_PLANNED="$AGP_PLANNED$n "; done
}

agp_run_step() {    # returns 0 to continue, 1 to stop the run
  local i=$1 id cls title fn rc missing="" n g
  AGP_I=$i; id="${AGP_S_ID[$i]}"; cls="${AGP_S_CLASS[$i]}"; title="${AGP_S_TITLE[$i]}"; fn="$(agp_fn "$id")"
  AGP_CUR_STEP="$id"; AGP_CUR_REMOVES="${AGP_S_REMOVES[$i]}"; export AGP_CUR_STEP

  # inputs: in apply mode only a real value counts; in plan mode a value an earlier step would set counts too
  for n in ${AGP_S_NEEDS[$i]}; do
    has_value "$n" && continue
    if [ "$AGP_MODE" != apply ]; then case "$AGP_PLANNED" in *" $n "*) continue;; esac; fi
    missing="$missing $n"
  done

  # 1. already done? (a check that needs an input it does not have is not run)
  rc=1
  if [ -z "$missing" ]; then AGP_CALL_CONTEXT=check "${fn}_check"; rc=$?; else rc=4; fi
  if [ $rc -eq 0 ]; then
    agp_mark DONE "$id" "$cls" "$title"
    if [ "$AGP_MODE" = apply ] && ! ckpt_done "$id"; then agp_write_done "$id" - "agp-platform $AGP_VERSION: found done"; fi
    return 0
  fi
  if [ $rc -eq 5 ]; then agp_mark N/A "$id" "$cls" "$title" "not applicable in this organisation (the check says why)"; return 0; fi
  if [ $rc -eq 2 ]; then agp_mark UNKNOWN "$id" "$cls" "$title" "the check failed for another reason than not-found; read the error above"
    [ "$AGP_MODE" = apply ] && { agp_stop "$id: check failed"; return 1; }; return 0; fi

  # 2. inputs
  if [ -n "$missing" ]; then
    agp_mark MISSING "$id" "$cls" "$title" "needs:$missing  (agp-platform names shows who sets each)"
    agp_plans "$i"
    if [ "$AGP_MODE" != apply ]; then
      case "$cls" in
        AUTO|AUTO-READ) AGP_CALL_CONTEXT=plan "${fn}_apply" >/dev/null;;
        *) "${fn}_manual" 2>&1 | sed 's/^/              /' >&3;;
      esac
    fi
    if [ "$AGP_MODE" = apply ] && [ "${AGP_S_ONUNMET[$i]}" = stop ]; then agp_stop "$id: missing$missing"; return 1; fi
    return 0
  fi

  # 3. decision gates
  if [ -n "${AGP_S_GATE[$i]}" ]; then
    # shellcheck disable=SC2086
    g="$(agp_gate_ok ${AGP_S_GATE[$i]})"; rc=$?
    if [ $rc -ne 0 ]; then
      if [ $rc -eq 2 ]; then g="${AGP_S_GATE[$i]} (decision tools not installed: setup/03 DC-1.2)"; fi
      agp_mark GATED "$id" "$cls" "$title" "unsigned decision: $g"
      agp_plans "$i"
      if [ "$AGP_MODE" = apply ] && [ "${AGP_S_ONUNMET[$i]}" = stop ]; then agp_stop "$id: decision $g unsigned"; return 1; fi
      return 0
    fi
  fi

  # 4. by class
  case "$cls" in
    CONSOLE|HUMAN|BLOCKED)
      local state=MANUAL; [ "$cls" = BLOCKED ] && state=BLOCKED
      agp_mark "$state" "$id" "$cls" "$title" "${AGP_S_NOTE[$i]}"
      "${fn}_manual" 2>&1 | sed 's/^/              /' >&3
      agp_plans "$i"
      if [ "$AGP_MODE" = apply ]; then
        if [ "$cls" = BLOCKED ] && ! grep -q "	$id	BLOCKED	" "${BUILD_LOG_DIR:-/nonexistent}/checkpoints.tsv" 2>/dev/null \
           && command -v checkpoint >/dev/null 2>&1; then
          checkpoint "$id" BLOCKED - - "agp-platform: ${AGP_S_NOTE[$i]:-blocked}" >/dev/null 2>&1
        fi
        if [ "${AGP_S_ONUNMET[$i]}" = stop ]; then agp_stop "$id: done by a person, then: agp-platform done $id"; return 1; fi
      fi
      return 0;;
  esac

  # AUTO and AUTO-READ
  if [ $rc -eq 3 ]; then agp_mark UNCHECKED "$id" "$cls" "$title"; else agp_mark TODO "$id" "$cls" "$title"; fi
  agp_plans "$i"
  if [ "$AGP_MODE" != apply ]; then AGP_CALL_CONTEXT=plan "${fn}_apply" >/dev/null; return 0; fi

  if [ "${AGP_S_WITNESS[$i]}" = 1 ] && [ "$AGP_WITNESS" = "-" ]; then
    agp_stop "$id needs a witness present: re-run with --witness <email>"; return 1
  fi
  if [ "${AGP_S_IRREV[$i]}" = 1 ]; then
    agp_confirm_irreversible "$id" "$title" || { agp_stop "$id: IRREVERSIBLE step not confirmed"; return 1; }
  fi
  AGP_CALL_CONTEXT=apply "${fn}_apply"; rc=$?
  if [ $rc -eq 98 ]; then   # the step's own STOP: a person must act first (the message above says what)
    agp_stop "$id: a person must act first (read the lines above), then resume"; return 1
  fi
  if [ $rc -ne 0 ]; then
    if [ "$cls" = AUTO-READ ]; then agp_stop "$id: the verification failed ($rc); read the output above"; else agp_stop "$id: apply failed ($rc); nothing after it ran"; fi
    return 1
  fi
  if [ "$cls" = AUTO ]; then   # an AUTO-READ step is its own verification; an AUTO step is re-checked
    AGP_CALL_CONTEXT=check "${fn}_check"; rc=$?
    if [ $rc -ne 0 ]; then agp_stop "$id: applied, but its check still fails ($rc); read the output above"; return 1; fi
  fi
  local wit="-"; [ "${AGP_S_WITNESS[$i]}" = 1 ] && wit="$AGP_WITNESS"
  agp_write_done "$id" "$wit" "agp-platform $AGP_VERSION" || { agp_stop "$id: done, but the checkpoint could not be written"; return 1; }
  agp_mark DONE "$id" "$cls" "$title" "applied"
  return 0
}

agp_run() {
  local i started=0 p last=""
  [ -n "$AGP_FROM" ] || started=1
  i=0; while [ $i -lt $AGP_N ]; do
    if agp_selected $i; then
      [ "${AGP_S_ID[$i]}" = "$AGP_FROM" ] && started=1
      if [ $started = 1 ]; then
        p="${AGP_S_PHASE[$i]}"
        if [ "$p" != "$last" ]; then agp_phase_header "$p"; last="$p"; fi
        agp_run_step $i || break
        [ "${AGP_S_ID[$i]}" = "$AGP_TO" ] && break
      fi
    fi
    i=$((i + 1))
  done
  if [ -n "$AGP_STOP_REASON" ]; then
    agp_say ""; agp_say "STOPPED: $AGP_STOP_REASON"
    agp_say "Resume with: agp-platform $AGP_MODE --phase $(echo "$AGP_SELECTED" | tr -s ' ' ',' | sed 's/^,//;s/,$//') --from ${AGP_CUR_STEP}"
    return 1
  fi
  [ $started = 1 ] || agp_die "--from ${AGP_FROM}: no such step in the selected phases"
  return 0
}

agp_phase_header() {
  local k=0
  while [ $k -lt $AGP_P_N ]; do
    if [ "${AGP_P_ID[$k]}" = "$1" ]; then
      agp_say ""; agp_say "== ${AGP_P_ID[$k]} ${AGP_P_TITLE[$k]}   (setup/${AGP_P_FILE[$k]})"; return; fi
    k=$((k + 1))
  done
}

# ---------------------------------------------------------------- commands
agp_usage() {
  cat <<'USAGE'
usage: agp-platform COMMAND [options]

  plan      [--phase LIST|--all] [--from ID] [--to ID] [--offline]   show every step, its state and the
                                                                     commands it would run; changes nothing
  apply     (--phase LIST|--all) [--from ID] [--to ID] [--witness EMAIL] [--confirm-irreversible ID,ID]
                                                                     run the steps that are not done, in order;
                                                                     stops at the first step a person must do
  done      ID [--witness EMAIL] [--note TEXT]                       record that a person did a manual step
  names     [--phase LIST|--all]                                     every value the steps read or write
  list      [--phase LIST|--all] [--class C] [--irreversible]        the step table
  status                                                             progress per phase from checkpoints.tsv
  preflight [--phase LIST|--all]                                     tools, ~/.platform-env, account, permissions
  sitting   start|end                                                the start and end blocks of setup/01 PR-3.2

LIST is phase numbers separated by commas, e.g. 09,10,11. Phases: agp-platform list --all.
Nothing changes without `apply`. IRREVERSIBLE steps ask for their id to be typed (or
--confirm-irreversible), decision gates are read with setup/03's decision-need.sh, and no step runs
with --yes or a default gcloud project.
USAGE
}

agp_parse_common() {    # sets AGP_SELECTED and friends from options; echoes leftover args
  AGP_ARGS=()
  local all=0 list=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --phase) list="$2"; shift 2;;
      --all) all=1; shift;;
      --from) AGP_FROM="$2"; shift 2;;
      --to) AGP_TO="$2"; shift 2;;
      --offline) AGP_OFFLINE=1; shift;;
      --witness) AGP_WITNESS="$2"; shift 2;;
      --confirm-irreversible) AGP_CONFIRMED=",$2,"; shift 2;;
      --class) AGP_FILTER_CLASS="$2"; shift 2;;
      --irreversible) AGP_FILTER_IRREV=1; shift;;
      --note) AGP_NOTE="$2"; shift 2;;
      -h|--help) agp_usage; exit 0;;
      -*) agp_die "unknown option $1";;
      *) AGP_ARGS[${#AGP_ARGS[@]}]="$1"; shift;;
    esac
  done
  local k p
  if [ $all = 1 ] || [ -z "$list" ]; then
    AGP_SELECTED=" "; k=0; while [ $k -lt $AGP_P_N ]; do AGP_SELECTED="$AGP_SELECTED${AGP_P_ID[$k]} "; k=$((k + 1)); done
    AGP_ALL=$all
  else
    AGP_SELECTED=" "
    for p in $(echo "$list" | tr ',' ' '); do
      k=0; while [ $k -lt $AGP_P_N ]; do [ "${AGP_P_ID[$k]}" = "$p" ] && break; k=$((k + 1)); done
      [ $k -lt $AGP_P_N ] || agp_die "--phase: no phase $p (agp-platform list --all)"
      AGP_SELECTED="$AGP_SELECTED$p "
    done
    AGP_ALL=0
  fi
}

agp_source_env() {  # ~/.platform-env, as every sitting of the procedures does
  local f="${PLATFORM_ENV_FILE:-$HOME/.platform-env}"
  if [ -f "$f" ]; then
    # shellcheck disable=SC1090
    . "$f" >/dev/null || agp_warn "the guard in the file ~/.platform-env reported a failure above"
    return 0
  fi
  return 1
}

agp_open_runlog() {
  if [ "$AGP_MODE" = apply ]; then
    local bl=""
    if has_value BUILD_LOG_DIR; then bl="$(_penv_get BUILD_LOG_DIR)"; elif [ -n "${AGP_BUILD_LOG_DIR-}" ]; then bl="$AGP_BUILD_LOG_DIR"; fi
    [ -n "$bl" ] || agp_die "BUILD_LOG_DIR has no value: for the first run of phase 01, export AGP_PLATFORM_REPO_DIR and AGP_BUILD_LOG_DIR (setup/01 PR-2.1)"
    mkdir -p "$bl/automation" || agp_die "cannot create $bl/automation"
    AGP_RUNLOG="$bl/automation/$(date -u +%Y%m%dT%H%M%SZ)-apply.log"
    { echo "agp-platform $AGP_VERSION apply, phases:$AGP_SELECTED from:${AGP_FROM:--} to:${AGP_TO:--} witness:$AGP_WITNESS"
      echo "account: $(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)"; } > "$AGP_RUNLOG"
  fi
}

agp_close_runlog() {
  [ "$AGP_MODE" = apply ] || return 0
  local bl; bl="$(dirname "$(dirname "$AGP_RUNLOG")")"
  if git -C "$bl" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$bl" add automation >/dev/null 2>&1 && git -C "$bl" commit -q -m "agp-platform apply$AGP_SELECTED" >/dev/null 2>&1
  fi
  agp_say "Run log: $AGP_RUNLOG"
}

agp_cmd_plan_apply() {
  local mode="$1"; shift
  AGP_MODE="$mode"
  agp_parse_common "$@"
  if [ "$mode" = apply ]; then
    [ "$AGP_OFFLINE" = 0 ] || agp_die "apply cannot run --offline"
    if [ "$AGP_ALL" = 1 ]; then
      printf 'Apply every phase in order. Type APPLY to continue: ' >&3
      local ans=""; read -r ans < /dev/tty 2>/dev/null; [ "$ans" = APPLY ] || agp_die "not confirmed"
    fi
    agp_preflight_quick || agp_die "preflight failed; run: agp-platform preflight"
  fi
  agp_open_runlog
  agp_say "agp-platform $AGP_VERSION $mode$( [ "$AGP_OFFLINE" = 1 ] && echo ' (offline: nothing read, nothing checked)')  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  agp_run; local rc=$?
  agp_close_runlog
  return $rc
}

agp_cmd_done() {
  agp_parse_common "$@"
  local id="${AGP_ARGS[0]-}" i=0 found=-1
  [ -n "$id" ] || agp_die "done: which step?"
  while [ $i -lt $AGP_N ]; do [ "${AGP_S_ID[$i]}" = "$id" ] && found=$i; i=$((i + 1)); done
  [ $found -ge 0 ] || agp_die "done: no step $id"
  case "${AGP_S_CLASS[$found]}" in
    CONSOLE|HUMAN) ;;
    AUTO-READ) [ "$AGP_WITNESS" != "-" ] || agp_die "done: $id is a read-only verification; recording it by hand (a read only another person can make) needs --witness <email>";;
    *) agp_die "done: $id is ${AGP_S_CLASS[$found]}; only CONSOLE, HUMAN and (with a witness) AUTO-READ steps are recorded by hand";;
  esac
  if [ "${AGP_S_WITNESS[$found]}" = 1 ] && [ "$AGP_WITNESS" = "-" ]; then agp_die "done: $id names a witness; pass --witness <email>"; fi
  printf 'Record %s (%s) as DONE, performed by a person. Type the step id to confirm: ' "$id" "${AGP_S_TITLE[$found]}" >&3
  local ans=""; read -r ans < /dev/tty 2>/dev/null; [ "$ans" = "$id" ] || agp_die "not confirmed"
  agp_write_done "$id" "$AGP_WITNESS" "by hand, recorded with agp-platform done${AGP_NOTE:+: $AGP_NOTE}" && echo "recorded $id DONE"
}

agp_cmd_list() {
  agp_parse_common "$@"
  local i=0
  while [ $i -lt $AGP_N ]; do
    if agp_selected $i; then
      if [ -n "${AGP_FILTER_CLASS-}" ] && [ "${AGP_S_CLASS[$i]}" != "$AGP_FILTER_CLASS" ]; then i=$((i + 1)); continue; fi
      if [ "${AGP_FILTER_IRREV-0}" = 1 ] && [ "${AGP_S_IRREV[$i]}" != 1 ]; then i=$((i + 1)); continue; fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${AGP_S_PHASE[$i]}" "${AGP_S_ID[$i]}" "${AGP_S_CLASS[$i]}" \
        "$([ "${AGP_S_IRREV[$i]}" = 1 ] && echo IRREVERSIBLE || echo -)" "${AGP_S_GATE[$i]:--}" "${AGP_S_TITLE[$i]}" \
        "${AGP_S_NEEDS[$i]:--}" "${AGP_S_SETS[$i]:--}" "${AGP_S_ONUNMET[$i]}"
    fi
    i=$((i + 1))
  done
}

agp_cmd_names() {
  agp_parse_common "$@"
  python3 "$AGP_HOME/lib/agp_json.py" names "$AGP_SELECTED" <<EOF_NAMES
$(i=0; while [ $i -lt $AGP_N ]; do
    printf '%s\t%s\t%s\t%s\t%s\n' "${AGP_S_PHASE[$i]}" "${AGP_S_ID[$i]}" "${AGP_S_NEEDS[$i]}" "${AGP_S_SETS[$i]}" \
      "$(for n in ${AGP_S_NEEDS[$i]} ${AGP_S_SETS[$i]}; do has_value "$n" && printf '%s ' "$n"; done)"
    i=$((i + 1)); done)
EOF_NAMES
}

agp_cmd_status() {
  agp_parse_common "$@"
  [ -n "${BUILD_LOG_DIR-}" ] && [ -f "$BUILD_LOG_DIR/checkpoints.tsv" ] || agp_die "no checkpoints.tsv yet (setup/01 PR-2.4)"
  local k i total done_n blocked
  k=0; while [ $k -lt $AGP_P_N ]; do
    total=0; done_n=0; blocked=0
    i=0; while [ $i -lt $AGP_N ]; do
      if [ "${AGP_S_PHASE[$i]}" = "${AGP_P_ID[$k]}" ]; then
        total=$((total + 1))
        ckpt_done "${AGP_S_ID[$i]}" && done_n=$((done_n + 1))
        grep -q "	${AGP_S_ID[$i]}	BLOCKED	" "$BUILD_LOG_DIR/checkpoints.tsv" && blocked=$((blocked + 1))
      fi
      i=$((i + 1))
    done
    printf '%s  %-55s %3s of %3s done  %3s blocked\n' "${AGP_P_ID[$k]}" "${AGP_P_TITLE[$k]}" "$done_n" "$total" "$blocked"
    k=$((k + 1))
  done
}

agp_cmd_sitting() {
  case "${1-}" in
    start)
      penv_guard && echo "guard clean" || agp_die "penv_guard failed"
      gcloud auth list --format='value(account)'
      SITTING_ID="SITTING-$(date -u +%Y%m%d%H%M)"
      checkpoint "$SITTING_ID" START "${2:--}" - "present: platform owner${2:+, $2}; opened by agp-platform" \
        && echo "export SITTING_ID=$SITTING_ID   # keep it for: agp-platform sitting end $SITTING_ID";;
    end)
      local sid="${2-}"
      [ -n "$sid" ] || sid="$(awk -F'\t' '$2 ~ /^SITTING-/ {i=$2} END{print i}' "$BUILD_LOG_DIR/checkpoints.tsv")"
      awk -F'\t' -v s="$sid" '$2 == s && $3 == "DONE" {f=1} END {exit f ? 1 : 0}' "$BUILD_LOG_DIR/checkpoints.tsv" \
        || agp_die "$sid is already closed"
      sitting_end && checkpoint "$sid" DONE - - "credentials revoked; closed by agp-platform";;
    *) agp_die "sitting start [WITNESS_EMAIL] | sitting end [SITTING_ID]";;
  esac
}

agp_main() {
  local cmd="${1-help}"; [ $# -gt 0 ] && shift
  agp_source_env || true
  agp_load_phases
  agp_check_registry || agp_die "the phase files are inconsistent (above)"
  case "$cmd" in
    plan) agp_cmd_plan_apply plan "$@";;
    apply) AGP_PHASE_GIVEN=0; case " $* " in *" --phase "*|*" --all "*) AGP_PHASE_GIVEN=1;; esac
           [ "$AGP_PHASE_GIVEN" = 1 ] || agp_die "apply needs --phase LIST or --all"
           agp_cmd_plan_apply apply "$@";;
    done) agp_cmd_done "$@";;
    list) agp_cmd_list "$@";;
    phases) k=0; while [ $k -lt $AGP_P_N ]; do printf '%s\t%s\t%s\t%s\n' "${AGP_P_ID[$k]}" "${AGP_P_FILE[$k]}" "${AGP_P_SCOPE[$k]}" "${AGP_P_TITLE[$k]}"; k=$((k + 1)); done;;
    names) agp_cmd_names "$@";;
    status) agp_cmd_status "$@";;
    preflight) agp_cmd_preflight "$@";;
    sitting) agp_cmd_sitting "$@";;
    help|-h|--help) agp_usage;;
    *) agp_usage; exit 2;;
  esac
}
