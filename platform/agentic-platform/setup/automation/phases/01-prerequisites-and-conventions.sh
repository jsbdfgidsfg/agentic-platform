# phases/01-prerequisites-and-conventions.sh: setup/01-prerequisites-and-conventions.md as code.
#
# This phase may run before ~/.platform-env exists. Until PR-2.3 installs it:
#   - the two repository paths are read from PLATFORM_REPO_DIR and BUILD_LOG_DIR when they hold a
#     value, else from AGP_PLATFORM_REPO_DIR and AGP_BUILD_LOG_DIR in the environment. The person
#     chooses them (PR-2.1: "choose others now if needed, never later"); a step refuses when unset.
#     The runner's own run log needs BUILD_LOG_DIR in apply mode, so a first apply is started as
#       AGP_PLATFORM_REPO_DIR=... AGP_BUILD_LOG_DIR=... BUILD_LOG_DIR=... agp-platform apply --phase 01
#   - checkpoints.tsv does not exist until PR-2.4, so the runner writes each DONE line to
#     $(agp_pending_ckpt) instead (PHASES.md, rule 3 of 2026-10-01), and PR-1.3's person writes
#     theirs there by hand. PR-2.4 appends those lines to checkpoints.tsv in order and removes the
#     file, as the page backfills PR-1.1 to PR-2.3 by hand.
# The git identity is typed by the person (PR-2.1 says so), either as the two git config lines the
# step prints or beforehand as AGP_GIT_EMAIL and AGP_GIT_NAME; the script copies it to the build log,
# never invents it. Local commands (gcloud version, components and config, git, mkdir) name no
# resource scope because they touch none.

phase 01 "Prerequisites and conventions" "01-prerequisites-and-conventions.md"

# ------------------------------------------------------------------ helpers of this phase
_pr01_show() { printf '      $ %s\n' "$*" >&3; }             # a line the person runs, shown only
_pr01_say()  { printf '      %s\n' "$*" >&3; }
_pr01_fail() { printf '      FAIL: %s\n' "$*" >&3; return 1; }
_pr01_live() { [ "$AGP_MODE" = apply ]; }

_pr01_dir_quiet() {   # _pr01_dir_quiet NAME: the value of NAME, else of AGP_NAME; fails when neither
  local alt
  if has_value "$1"; then _penv_get "$1"; return 0; fi
  alt="$(_penv_get "AGP_$1")" || return 1
  case "$alt" in ''|*'<'*|*'>'*) return 1;; esac
  printf '%s' "$alt"
}

_pr01_dir() {         # _pr01_dir NAME: as above; <NAME> in plan mode; a clear refusal in apply mode
  if _pr01_dir_quiet "$1"; then return 0; fi
  if ! _pr01_live; then printf '<%s>' "$1"; return 0; fi
  case "$1" in
    PLATFORM_REPO_DIR) agp_warn "PLATFORM_REPO_DIR has no value: export AGP_PLATFORM_REPO_DIR=<path> (setup/01 PR-2.1 assumes \$HOME/platform/agentic-platform; choose it now, never later)";;
    BUILD_LOG_DIR) agp_warn "BUILD_LOG_DIR has no value: export AGP_BUILD_LOG_DIR=<path> and BUILD_LOG_DIR=<the same path> (setup/01 PR-2.1 assumes \$HOME/platform/build-log)";;
    *) agp_warn "$1 has no value";;
  esac
  return 1
}

_pr01_synced() {      # 0 when a path lies in a synced location (PR-2.1 VERIFY)
  case "$1" in *"Library/CloudStorage"*|*"Mobile Documents"*|*"/Desktop/"*|*"/Documents/"*|*"/Claude/wiki"*) return 0;; esac
  return 1
}

_pr01_tmp_tools() { printf '%s' "$HOME/platform/tmp-records/tools.txt"; }

_pr01_tools_file() {  # the PR-1.1 record where it is now: the working area, or the build log after PR-2.1
  local t log; t="$(_pr01_tmp_tools)"
  if [ -f "$t" ]; then printf '%s' "$t"; return 0; fi
  log="$(_pr01_dir_quiet BUILD_LOG_DIR)" || return 1
  [ -f "$log/records/tools.txt" ] || return 1
  printf '%s' "$log/records/tools.txt"
}

_pr01_gcloud_version() {   # the "Google Cloud SDK" field of `gcloud version --format=json`
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local j; j="$(r gcloud version --format=json 2>/dev/null)" || return 1
  printf '%s' "$j" | jget "Google Cloud SDK" 2>/dev/null && return 0
  r gcloud version --format='value("Google Cloud SDK")' 2>/dev/null   # the form lib/preflight.sh reads
}

_pr01_floor_ok() {    # _pr01_floor_ok VERSION: 0 at or above 586.0.0, the page's floor
  local maj="${1%%.*}"
  case "$maj" in ''|*[!0-9]*) return 1;; esac
  [ "$maj" -ge 586 ]
}

_pr01_beta_ok() { r gcloud components list --only-local-state --format='value(id)' 2>/dev/null | grep -qx beta; }

_pr01_tools_versions() {   # the record block of PR-1.1, as the page writes it
  date -u +%Y-%m-%dT%H:%M:%SZ; gcloud version; bq version; python3.12 --version; jq --version; openssl version; git --version; curl --version | head -n 1
  return 0   # a missing tool is written into the record; the VERIFY below decides
}

_pr01_has_header() {  # _pr01_has_header FILE: the first line is a header, not a data line
  local h; h="$(head -n 1 "$1" 2>/dev/null)"
  case "$h" in ''|[0-9]*) return 1;; esac
  return 0
}

_pr01_helper_block() { sed -n '/^# ---- helpers/,/^# ---- values/p' "$1"; }

_pr01_file_value() {  # _pr01_file_value FILE NAME: the value a variables file holds for NAME
  sed -n "s/^export $2=\"\\(.*\\)\"\$/\\1/p" "$1" | tail -n 1
}

_pr01_committed() {   # _pr01_committed REPO PATH...: every path is tracked and has no uncommitted change
  local repo="$1"; shift
  git -C "$repo" ls-files --error-unmatch -- "$@" >/dev/null 2>&1 || return 1
  git -C "$repo" diff --quiet HEAD -- "$@" 2>/dev/null
}

_pr01_commit() {      # _pr01_commit REPO MESSAGE: commit what is staged, only when something is
  if _pr01_live && git -C "$1" diff --cached --quiet 2>/dev/null; then _pr01_say "nothing new to commit"; return 0; fi
  x git -C "$1" commit -m "$2"
}

# ------------------------------------------------------------------ 4. The workstation

step PR-1.1 AUTO "Tools and versions"
s_PR_1_1_check() {
  ckpt_done PR-1.1 && return 0
  [ "$AGP_OFFLINE" = 1 ] && return 3
  _pr01_tools_file >/dev/null || return 1
  local ver; ver="$(_pr01_gcloud_version)" || return 1
  _pr01_floor_ok "$ver" || return 1
  _pr01_beta_ok || return 1
  command -v python3.12 >/dev/null 2>&1
}
s_PR_1_1_apply() {
  local t log ver; t="$(_pr01_tmp_tools)"
  if ! _pr01_live; then
    _pr01_say "Install the Google Cloud CLI (https://docs.cloud.google.com/sdk/docs/install) and Python 3.12 first."
    _pr01_say "Each of the two lines below runs only when needed (gcloud below 586.0.0; beta missing), and asks before it acts:"
    x gcloud components update
    x gcloud components install beta
  else
    ver="$(_pr01_gcloud_version)"
    if ! _pr01_floor_ok "$ver"; then
      x gcloud components update || { _pr01_fail "gcloud could not update itself. If it came from a package manager, update it through that, then resume"; return 1; }
    fi
    if ! _pr01_beta_ok; then x gcloud components install beta || return 1; fi
  fi
  log="$(_pr01_dir_quiet BUILD_LOG_DIR)" || log=""
  if [ -n "$log" ] && [ -f "$log/records/tools.txt" ]; then
    _pr01_say "the record $log/records/tools.txt exists (moved by PR-2.1): not rewritten"
  else
    x mkdir -p "$HOME/platform/tmp-records" || return 1
    if _pr01_live; then _pr01_tools_versions 2>&1 | xw "$t" 644 || return 1
    else printf '%s\n' date gcloud bq python3.12 jq openssl git curl | xw "$t"; fi
  fi
  _pr01_live || return 0
  # VERIFY
  ver="$(_pr01_gcloud_version)"
  _pr01_floor_ok "$ver" && _pr01_say "gcloud version OK ($ver)" || { _pr01_fail "gcloud is ${ver:-unreadable}; the floor is 586.0.0 (setup/01 PR-1.1)"; return 1; }
  _pr01_beta_ok && _pr01_say "beta OK" || { _pr01_fail "the beta component is not installed"; return 1; }
  command -v python3.12 >/dev/null 2>&1 || { _pr01_fail "python3.12 is not installed (python.org or the organisation's package manager)"; return 1; }
  command -v shred >/dev/null 2>&1 || _pr01_say "no shred: expected on macOS; no step uses it"
  return 0
}

step PR-1.2 AUTO "Disk encryption and a working area outside synced folders"
s_PR_1_2_check() {
  ckpt_done PR-1.2 && return 0
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local f; f="$(_pr01_tools_file)" || return 1
  grep -qx 'FileVault is On.' "$f" && grep -qxF "working area: $HOME/platform" "$f" || return 1
  fdesetup status 2>/dev/null | grep -qx 'FileVault is On.' || return 1
  [ ! -e "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Desktop" ]
}
s_PR_1_2_apply() {
  local f st
  if ! _pr01_live; then
    f="$(_pr01_tools_file)" || f="$(_pr01_tmp_tools)"
    _pr01_show "fdesetup status | tee -a \"$f\""
    _pr01_show "echo \"working area: $HOME/platform\" >> \"$f\""
    printf 'FileVault\nworking area\n' | xw "$f"
    _pr01_show "ls -d \"$HOME/Library/Mobile Documents/com~apple~CloudDocs/Desktop\""
    return 0
  fi
  f="$(_pr01_tools_file)" || { _pr01_fail "PR-1.1's record tools.txt was not found; run PR-1.1 first"; return 1; }
  st="$(fdesetup status 2>&1)"
  printf '%s\n' "$st" | sed 's/^/      /' >&3
  { cat "$f"; printf '%s\n' "$st"; printf 'working area: %s\n' "$HOME/platform"; } | xw "$f" 644 || return 1
  # VERIFY
  if [ -e "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Desktop" ]; then
    _pr01_fail "iCloud is syncing the Desktop and Documents folders; turn it off before the build"; return 1
  fi
  printf '%s\n' "$st" | grep -qx 'FileVault is On.' || { _pr01_fail "FileVault is not on: System Settings > Privacy & Security > FileVault, before any credential touches the disk"; return 98; }
  _pr01_say "FileVault is On; no iCloud Desktop and Documents sync"
  _pr01_say "Also read by eye: System Settings > your name > iCloud > Drive shows $HOME/platform under no synced folder; ~/Downloads is not synced"
  return 0
}

step PR-1.3 HUMAN "One clean browser profile per admin account"
s_PR_1_3_check() { ckpt_done PR-1.3; }
s_PR_1_3_manual() {
  cat <<EOF
WHO: the platform owner. WHERE: Chrome > profile icon > Add > Continue without an account.
Create profile 'daily' (the existing profile of your daily account, for Admin console reads until 06)
and profile 'sa-1-admin' (empty until 06 creates sa-1-admin@<DOMAIN>). Never two accounts in one profile;
no password manager and no sync in an admin profile. 'consent-eve' (24) and 'consent-walle' (32) come later.
VERIFY: the profile icon lists daily and sa-1-admin; in sa-1-admin, chrome://settings/syncSetup shows no account.
Record: the checkpoint log does not exist yet (PR-2.4 starts it and backfills this line), so type the line by hand:
  printf '%s\tPR-1.3\tDONE\t%s\t-\t-\t%s\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\$(git config user.email || echo -)" \\
    "by hand, before the log existed" >> "$(agp_pending_ckpt)"
Then resume with the command printed below.
EOF
}

# ------------------------------------------------------------------ 5. The repositories and the variables file

step PR-2.1 AUTO "Create the two local repositories" --removes
s_PR_2_1_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local repo log d
  repo="$(_pr01_dir_quiet PLATFORM_REPO_DIR)" || return 1
  log="$(_pr01_dir_quiet BUILD_LOG_DIR)" || return 1
  _pr01_synced "$repo$log" && return 1
  for d in "$repo" "$log"; do
    [ -e "$d/.git" ] || return 1
    [ "$(git -C "$d" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || return 1
    [ -n "$(git -C "$d" config --local user.email)" ] && [ -n "$(git -C "$d" config --local user.name)" ] || return 1
  done
  [ "$(git -C "$log" config --local user.email)" = "$(git -C "$repo" config --local user.email)" ] || return 1
  [ -d "$repo/env" ] && [ -d "$repo/decisions" ] && [ -d "$log/registers" ] && [ -d "$log/records" ] || return 1
  [ ! -e "$(_pr01_tmp_tools)" ] && [ -f "$log/records/tools.txt" ]
}
s_PR_2_1_apply() {
  local repo log d em nm t
  repo="$(_pr01_dir PLATFORM_REPO_DIR)" || return 1
  log="$(_pr01_dir BUILD_LOG_DIR)" || return 1
  if _pr01_synced "$repo$log"; then _pr01_fail "synced location: $repo, $log (setup/01 PR-1.2 and PR-2.1)"; return 1; fi
  for d in "$repo" "$log"; do
    if _pr01_live && [ -e "$d/.git" ]; then _pr01_say "$d is already a git repository"; else x git init -b main "$d" || return 1; fi
  done
  # The platform owner's git identity: the repository's own when it has one, else what the person
  # typed into AGP_GIT_EMAIL and AGP_GIT_NAME before the run (PHASES.md rule 5). Never invented.
  em="$(git -C "$repo" config --local user.email 2>/dev/null)"; nm="$(git -C "$repo" config --local user.name 2>/dev/null)"
  if [ -z "$em" ] || [ -z "$nm" ]; then
    if _pr01_live && { [ -z "${AGP_GIT_EMAIL-}" ] || [ -z "${AGP_GIT_NAME-}" ]; }; then
      agp_warn "REFUSED: PR-2.1 needs the platform owner's git identity, typed by the platform owner. Export AGP_GIT_EMAIL=\"<email>\" and AGP_GIT_NAME=\"<name>\", or run: git -C \"$repo\" config user.email \"<email>\"; git -C \"$repo\" config user.name \"<name>\". Then resume"
      return 1
    fi
    em="${AGP_GIT_EMAIL:-<AGP_GIT_EMAIL>}"; nm="${AGP_GIT_NAME:-<AGP_GIT_NAME>}"
    x git -C "$repo" config user.email "$em" || return 1
    x git -C "$repo" config user.name "$nm" || return 1
  fi
  if ! _pr01_live || [ "$(git -C "$log" config --local user.email 2>/dev/null)" != "$em" ]; then x git -C "$log" config user.email "$em" || return 1; fi
  if ! _pr01_live || [ "$(git -C "$log" config --local user.name 2>/dev/null)" != "$nm" ]; then x git -C "$log" config user.name "$nm" || return 1; fi
  x mkdir -p "$repo/env" "$repo/decisions" "$log/registers" "$log/records" || return 1
  t="$(_pr01_tmp_tools)"
  if ! _pr01_live; then
    x mv "$t" "$log/records/"; x rmdir "$HOME/platform/tmp-records"
  elif [ -f "$t" ]; then
    if [ -e "$log/records/tools.txt" ]; then _pr01_fail "both $t and $log/records/tools.txt exist; keep one by hand"; return 1; fi
    x mv "$t" "$log/records/" && x rmdir "$HOME/platform/tmp-records" || return 1
  elif [ ! -f "$log/records/tools.txt" ]; then
    _pr01_fail "PR-1.1's record tools.txt is missing; run PR-1.1 again"; return 1
  fi
  _pr01_live || return 0
  # VERIFY
  git -C "$repo" rev-parse --is-inside-work-tree >&3 && git -C "$log" rev-parse --is-inside-work-tree >&3 || return 1
  _pr01_say "location OK"
}

step PR-2.2 AUTO "Commit the variables-file template"
s_PR_2_2_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local repo f a="$AGP_HOME/assets/platform-env.template"
  repo="$(_pr01_dir_quiet PLATFORM_REPO_DIR)" || return 1
  f="$repo/env/platform-env.template"
  git -C "$repo" cat-file -e HEAD:env/platform-env.template 2>/dev/null || return 1
  git -C "$repo" show HEAD:env/platform-env.template | cmp -s - "$a" || return 1
  cmp -s "$f" "$a" || return 1
  [ "$(grep -c '^export ' "$f")" = 1 ] && [ "$(grep -c '^# ---- end of values ----$' "$f")" = 1 ]
}
s_PR_2_2_apply() {
  local repo
  repo="$(_pr01_dir PLATFORM_REPO_DIR)" || return 1
  xw "$repo/env/platform-env.template" 644 < "$AGP_HOME/assets/platform-env.template" || return 1
  x git -C "$repo" add env/platform-env.template || return 1
  _pr01_commit "$repo" "env: platform-env template (setup 01 PR-2.2)" || return 1
  _pr01_say "The second operator reviews this commit when named (02 records the same kind of local review)."
  _pr01_live || return 0
  # VERIFY
  git -C "$repo" log --oneline -- env/platform-env.template | sed 's/^/      /' >&3
}

_pr01_fixed_values() {   # NAME VALUE KIND, one per line. strict: must equal; kept: an existing value is kept
  local repo="$1" log="$2" wiki
  wiki="$(_penv_get AGP_WIKI_DIR)"; [ -n "$wiki" ] || wiki="$HOME/Claude/wiki"
  printf '%s\t%s\t%s\n' \
    PLATFORM_ENV_FILE "$HOME/.platform-env" strict \
    GCLOUD_CONFIG_NAME platform-bootstrap strict \
    PLATFORM_REPO_DIR "$repo" strict \
    BUILD_LOG_DIR "$log" strict \
    WIKI_DIR "$wiki" kept \
    REGION europe-west1 strict \
    BQ_LOCATION EU strict \
    GE_LOCATION eu strict \
    MODEL_LOCATION eu strict \
    DEVIATION_REGISTER "$log/registers/bootstrap-deviation-register.md" kept \
    EVIDENCE_REGISTER "$log/registers/evidence-register.md" kept \
    DRILL_CALENDAR "$log/registers/drill-calendar.md" kept
}

step PR-2.3 AUTO "Install \`~/.platform-env\` and write the fixed values" \
  --sets "PLATFORM_ENV_FILE GCLOUD_CONFIG_NAME PLATFORM_REPO_DIR BUILD_LOG_DIR WIKI_DIR REGION BQ_LOCATION GE_LOCATION MODEL_LOCATION DEVIATION_REGISTER EVIDENCE_REGISTER DRILL_CALENDAR"
s_PR_2_3_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local env="$HOME/.platform-env" repo n
  [ -f "$env" ] || return 1
  [ "$(ls -l "$env" | cut -c1-10)" = "-rw-------" ] || return 1
  repo="$(_pr01_dir_quiet PLATFORM_REPO_DIR)" || return 1
  [ "$(_pr01_helper_block "$repo/env/platform-env.template")" = "$(_pr01_helper_block "$env")" ] || return 1
  for n in PLATFORM_ENV_FILE GCLOUD_CONFIG_NAME PLATFORM_REPO_DIR BUILD_LOG_DIR WIKI_DIR REGION BQ_LOCATION GE_LOCATION MODEL_LOCATION DEVIATION_REGISTER EVIDENCE_REGISTER DRILL_CALENDAR; do
    has_value "$n" || return 1
  done
  [ ! -e "$HOME/.walle-env" ] && [ ! -e "$HOME/.eve-env" ] && [ ! -e "$HOME/.mo-env" ]
}
s_PR_2_3_apply() {
  local env="$HOME/.platform-env" repo log tpl n val kind cur alt t
  repo="$(_pr01_dir PLATFORM_REPO_DIR)" || return 1
  log="$(_pr01_dir BUILD_LOG_DIR)" || return 1
  tpl="$repo/env/platform-env.template"
  for n in PLATFORM_REPO_DIR BUILD_LOG_DIR; do
    alt="$(_penv_get "AGP_$n")"
    if [ -n "$alt" ] && has_value "$n" && [ "$alt" != "$(_penv_get "$n")" ]; then
      _pr01_fail "the file ~/.platform-env holds $n='$(_penv_get "$n")' but AGP_$n is '$alt': a stale file? Read PR-2.3 and decide by hand"; return 1
    fi
  done
  if [ -e "$env" ]; then
    if [ -f "$tpl" ] && [ "$(_pr01_helper_block "$tpl")" = "$(_pr01_helper_block "$env")" ] \
       && { cur="$(_pr01_file_value "$env" PLATFORM_REPO_DIR)"; [ -z "$cur" ] || [ "$cur" = "$repo" ]; } \
       && { cur="$(_pr01_file_value "$env" BUILD_LOG_DIR)"; [ -z "$cur" ] || [ "$cur" = "$log" ]; }; then
      _pr01_say "the file ~/.platform-env exists, installed from this repository's committed template (a resumed PR-2.3): kept"
    else
      _pr01_fail "STOP: the file ~/.platform-env already exists. It may be a stale file from an aborted run or from other work: a different template, retired names, or another tenant's values. Check it holds no secret, move it to \"$log/records/retired/\", then re-run this step. Do not source it."
      return 98   # the page's own STOP: a person moves the file first
    fi
  else
    x install -m 600 "$tpl" "$env" || return 1
  fi
  if _pr01_live; then
    # shellcheck disable=SC1090
    . "$env" 2>/dev/null
  fi
  while IFS='	' read -r n val kind; do
    if [ "$kind" = kept ] && has_value "$n" && [ "$(_penv_get "$n")" != "$val" ]; then
      _pr01_say "kept $n='$(_penv_get "$n")' (the page writes '$val'; a change needs penv_set --force and a build-log line)"
      continue
    fi
    pset "$n" "$val" || return 1
  done <<EOF
$(_pr01_fixed_values "$repo" "$log")
EOF
  _pr01_live || return 0
  _pr01_say "Expected on the next source, and only before PR-3.1: GUARD: configuration platform-bootstrap does not exist yet; 01 PR-3.1 creates it"
  # shellcheck disable=SC1090
  . "$(_penv_get PLATFORM_ENV_FILE)" 2>&3
  # VERIFY
  [ "$(ls -l "$env" | cut -c1-10)" = "-rw-------" ] || { _pr01_fail "$env is not mode 600"; return 1; }
  [ "$(_pr01_helper_block "$tpl")" = "$(_pr01_helper_block "$env")" ] && _pr01_say "template identity OK" || { _pr01_fail "the helper block differs from the committed template"; return 1; }
  need PLATFORM_ENV_FILE GCLOUD_CONFIG_NAME PLATFORM_REPO_DIR BUILD_LOG_DIR WIKI_DIR REGION BQ_LOCATION GE_LOCATION MODEL_LOCATION DEVIATION_REGISTER EVIDENCE_REGISTER DRILL_CALENDAR 2>&3 && _pr01_say "values OK" || return 1
  # The page's refusal check (penv_set REGION europe-west4), run on a throwaway copy so that it can
  # never change the real file even if the refusal were broken.
  t="$(mktemp -d "${TMPDIR:-/tmp}/agp-pr23.XXXXXX")" || return 1
  cp "$env" "$t/env" && ( PLATFORM_ENV_FILE="$t/env"; penv_set REGION europe-west4; echo "exit $?" ) 2>&1 | sed 's/^/      /' >&3
  rm -f "$t/env"; rmdir "$t"
  if [ -e "$HOME/.walle-env" ] || [ -e "$HOME/.eve-env" ] || [ -e "$HOME/.mo-env" ]; then
    _pr01_fail "a retired variables file exists; check it holds no secret, move it out of \$HOME into $log/records/retired/, never source it"; return 1
  fi
  _pr01_say "no retired variables files"
}

# --removes: the step removes the runner's side file of DONE lines once they are in checkpoints.tsv.
step PR-2.4 AUTO "Start the checkpoint log, the re-run index and the change log" --needs "BUILD_LOG_DIR" --removes
_pr01_backfill_steps() { printf '%s\n' PR-1.1 PR-1.2 PR-1.3 PR-2.1 PR-2.2 PR-2.3; }
_pr01_pending_new() {   # _pr01_pending_new PENDING LOG: the waiting DONE lines whose step has none in LOG, in order
  awk -F'\t' 'FNR == NR { if ($3 == "DONE") d[$2] = 1; next }
              $3 == "DONE" && !($2 in d) { d[$2] = 1; print }' "$2" "$1"
}
s_PR_2_4_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local log s f; log="$(v BUILD_LOG_DIR)"
  [ -e "$(agp_pending_ckpt)" ] && return 1   # DONE lines still wait outside the log
  for f in checkpoints.tsv rerun-index.tsv variables-changes.tsv; do
    [ -f "$log/$f" ] && _pr01_has_header "$log/$f" || return 1
  done
  _pr01_committed "$log" checkpoints.tsv rerun-index.tsv variables-changes.tsv records/tools.txt || return 1
  for s in $(_pr01_backfill_steps); do ckpt_done "$s" || return 1; done
  return 0
}
s_PR_2_4_apply() {
  local log s fn bad="" f fill="" pend add
  log="$(v BUILD_LOG_DIR)"; pend="$(agp_pending_ckpt)"
  # Which of PR-1.1 to PR-2.3 have no DONE line, in the log or waiting in the side file, and whether
  # each is really done (its check): decided before anything is written, so that a refused run
  # leaves the log unstarted and a manual step can still be recorded in the side file (PR-1.3).
  for s in $(_pr01_backfill_steps); do
    ckpt_done "$s" && continue
    fn="$(agp_fn "$s")_check"
    if ! _pr01_live || "$fn" >/dev/null 2>&1; then fill="$fill $s"; else bad="$bad $s"; fi
  done
  if [ -n "$bad" ]; then
    _pr01_fail "not done:$bad. Do it first; a manual step is recorded as its own instructions say (PR-1.3: a line typed into $pend). Then resume"
    return 1
  fi
  # Every creation is guarded: a resumed PR-2.4 never truncates a log (the page's rule).
  [ -e "$log/checkpoints.tsv" ] && _pr01_live || printf 'utc_timestamp\tstep_id\tstatus\toperator\twitness\tevidence\tnote\n' | xw "$log/checkpoints.tsv" 644 || return 1
  [ -e "$log/rerun-index.tsv" ] && _pr01_live || printf 'date\tstep_id\tmember\twhat_to_rerun\tstatus\tdetail\n' | xw "$log/rerun-index.tsv" 644 || return 1
  [ -e "$log/variables-changes.tsv" ] && _pr01_live || printf 'utc_timestamp\taction\tname\told_value\tnew_value\n' | xw "$log/variables-changes.tsv" 644 || return 1
  if _pr01_live; then
    # The page greps each header's first word; any header line passes here, a data line does not.
    for f in checkpoints.tsv rerun-index.tsv variables-changes.tsv; do
      _pr01_has_header "$log/$f" || bad="$bad $f"
    done
    [ -z "$bad" ] || { _pr01_fail "STOP:$bad exists without its header; prepend it by hand. Nothing was overwritten"; return 98; }
    [ -f "$log/records/tools.txt" ] || { _pr01_fail "records/tools.txt is missing: PR-1.1's record was not moved by PR-2.1"; return 1; }
  fi
  # The DONE lines written before the log existed (by the runner, and PR-1.3's by hand) are the
  # page's backfill: appended in their order, each step once, then the side file goes.
  if ! _pr01_live; then
    _pr01_say "append the DONE lines waiting in $pend, if any, to checkpoints.tsv in order (a step already there is skipped), then:"
    x rm -f "$pend"
  elif [ -f "$pend" ]; then
    add="$(_pr01_pending_new "$pend" "$log/checkpoints.tsv")"
    if [ -n "$add" ]; then
      { cat "$log/checkpoints.tsv"; printf '%s\n' "$add"; } | xw "$log/checkpoints.tsv" 644 || return 1
      _pr01_say "appended the waiting DONE lines of: $(printf '%s\n' "$add" | cut -f2 | tr '\n' ' ')"
    fi
    x rm -f "$pend" || return 1
  fi
  x git -C "$log" add checkpoints.tsv rerun-index.tsv variables-changes.tsv records/tools.txt || return 1
  _pr01_commit "$log" "build log: headers and PR-1.1 tools record" || return 1
  if _pr01_live; then [ -z "$fill" ] || _pr01_say "no DONE line yet, but done by their checks:$fill"
  else _pr01_say "then, for each of PR-1.1 to PR-2.3 still without a DONE line (normally none) whose check passes:"; fi
  for s in $fill; do
    x checkpoint "$s" DONE - - "backfilled at PR-2.4; performed before the log existed" || return 1
  done
  _pr01_live || return 0
  # VERIFY (PR-2.4's own DONE line is written by the runner when this step passes)
  awk -F'\t' '$3=="DONE"{print $2}' "$log/checkpoints.tsv" | sort | uniq -d | grep . >/dev/null && { _pr01_fail "a step has two DONE lines"; return 1; }
  head -n 1 "$log/rerun-index.tsv" | sed 's/^/      /' >&3
  head -n 1 "$log/variables-changes.tsv" | sed 's/^/      /' >&3
}

step PR-2.5 AUTO-READ "Check the helpers on a throwaway copy" --needs "PLATFORM_REPO_DIR"
_pr01_pr25_block1() {
  cat <<'B1'
export PLATFORM_ENV_FILE="$1/env"; . "$1/env"; penv_set BUILD_LOG_DIR "$1/log"; penv_set WALLE_PROJECT prod-x; penv_set WALLE_TWIN_PROJECT twin-x; penv_set EVE_PROJECT eve-p; penv_set EVE_TWIN_PROJECT eve-n; penv_set SANDBOX_DOMAIN sb.invalid; penv_set SANDBOX_CUSTOMER_ID C0sb; penv_set SA_ACTIONS walle-actions@prod-x.iam.gserviceaccount.com; penv_set WALLE_PROJECT other; penv_set REFRESH_TOKEN_VERSION 3; penv_set EVE_REFRESH_TOKEN x; penv_set EMPTY_CHECK ""; penv_set PLACEHOLDER_CHECK "<value>"; ( PLATFORM_SHELL_MODE=twin; . "$1/env"; echo "twin: $WALLE_PROJECT $SA_ACTIONS [$REFRESH_TOKEN_VERSION]" ); ( PLATFORM_SHELL_MODE=walle; . "$1/env"; echo "walle: PROJECT=$PROJECT" ); need NOTSET; exists_or_pending --pending serviceAccount:x@eve-p.iam.gserviceaccount.com PR-2.5 check; cat "$1/log/rerun-index.tsv"; checkpoint PR-2.5 DONE "<witness or ->" - "placeholder check"; echo "checkpoint exit $?"; ( unset CLOUDSDK_CONFIG; sitting_end >/dev/null 2>"$1/se.err"; echo "sitting_end exit $?"; cat "$1/se.err" )
B1
}
_pr01_pr25_block2() {
  cat <<'B2'
export PLATFORM_ENV_FILE="$1/env"; . "$1/env"; penv_set DEVIATION_REGISTER "$1/log/dr.md"; printf "%s\n" "| Id | a | b | c | d | e | f | g | h | i | j | k | Status |" "|---|---|---|---|---|---|---|---|---|---|---|---|---|" "" "## Closures" "" "| Id | Closed | How | Verified by |" "|---|---|---|---|" > "$DEVIATION_REGISTER"; git -C "$1/log" add dr.md && git -C "$1/log" commit -q -m skeleton; r="| BD-01-9 | d | 01 PR-2.5 | DEV | check | - | - | - | - | - | - | - | open |"; bd_insert "$r"; bd_insert "$r"; bd_close BD-01-9 check "01 PR-2.5"; bd_close BD-01-9 check "01 PR-2.5"; bd_insert "| BD-01-8 | d | 01 PR-2.5 | DEV | <placeholder> | - | - | - | - | - | - | - | open |"; bd_insert "| BD-1-7 | d | 01 PR-2.5 | DEV | check | - | - | - | - | - | - | - | open |"; bd_insert "| BD-01-6 | d | 01 PR-2.5 | DEV | check | - | - | - | - | - | - | open |"; bd_insert "| BD-01-5 | d | 01 PR-2.5 | DEV | check | - | - | - | - | - | - | - | open |"; grep -n -e "^| BD-01-" -e "^## Closures" "$DEVIATION_REGISTER"; git -C "$1/log" log --format=%s | head -n 3
B2
}
_pr01_pr25_expected() {   # the VERIFY of PR-2.5, in order; @TODAY@ is today's UTC date
  cat <<'EXP'
REFUSED: WALLE_PROJECT is already 'prod-x'
EVE_REFRESH_TOKEN names a secret
EMPTY_CHECK: empty or <placeholder> value refused
PLACEHOLDER_CHECK: empty or <placeholder> value refused
twin: twin-x walle-actions@twin-x.iam.gserviceaccount.com []
walle: PROJECT=prod-x
MISSING NOTSET
PENDING serviceAccount:x@eve-p.iam.gserviceaccount.com
	PR-2.5	serviceAccount:x@eve-p.iam.gserviceaccount.com	check	PENDING
checkpoint: an unreplaced <placeholder> would be written verbatim into the log
checkpoint exit 2
sitting_end exit 1
SITTING-END FAIL: CLOUDSDK_CONFIG is not set
set DEVIATION_REGISTER
opened BD-01-9 at line 3 (Closures heading at line 5)
exists: BD-01-9
closed BD-01-9
already closed: BD-01-9
bd_insert: an unreplaced <placeholder>
bd_insert: 'BD-1-7' is not an id of the form BD-<file>-<n>
bd_insert: BD-01-6 has 12 cells, not PR-4.1's thirteen
opened BD-01-5 at line 4 (Closures heading at line 6)
3:| BD-01-9 |
4:| BD-01-5 |
6:## Closures
10:| BD-01-9 | @TODAY@ | check | 01 PR-2.5 |
BD-01-5 opened
BD-01-9 closed
BD-01-9 opened
EXP
}
_pr01_pr25_run() {   # _pr01_pr25_run SHELL: the page's ACTION in a new, unsourced shell; prints its output
  local sh="$1" T rc=0
  T="$(mktemp -d "${TMPDIR:-/tmp}/agp-pr25.XXXXXX")" || return 1
  install -m 600 "$(sed -n 's/^export PLATFORM_REPO_DIR="\(.*\)"$/\1/p' "$HOME/.platform-env")/env/platform-env.template" "$T/env" || rc=1
  if [ $rc = 0 ]; then
    mkdir "$T/log" && git -C "$T/log" init -q && git -C "$T/log" config user.email check@invalid && git -C "$T/log" config user.name check || rc=1
  fi
  if [ $rc = 0 ]; then
    # HOME is the throwaway directory: sitting_end in block 1 can then never reach the real gcloud
    # configuration, even if the template's CLOUDSDK_CONFIG guard were broken.
    mkdir "$T/home" || rc=1
  fi
  if [ $rc = 0 ]; then
    env -i HOME="$T/home" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" "$sh" -c "$(_pr01_pr25_block1)" _ "$T" 2>&1
    env -i HOME="$T/home" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" "$sh" -c "$(_pr01_pr25_block2)" _ "$T" 2>&1
  fi
  rm -rf "$T"
  return $rc
}
_pr01_pr25_compare() {   # _pr01_pr25_compare OUTPUT_FILE: every expected line, in order
  local want n=0 at today; today="$(date -u +%Y-%m-%d)"
  while IFS= read -r want; do
    want="$(printf '%s' "$want" | sed "s/@TODAY@/$today/")"
    at="$(awk -v n="$n" -v w="$want" 'NR > n && index($0, w) {print NR; exit}' "$1")"
    if [ -z "$at" ]; then _pr01_say "missing, or out of order: $want"; return 1; fi
    n="$at"
  done <<EOF
$(_pr01_pr25_expected)
EOF
  return 0
}
s_PR_2_5_check() { ckpt_done PR-2.5; }
s_PR_2_5_apply() {
  local sh out bad=0
  if ! _pr01_live; then
    _pr01_show "T=\"\$(mktemp -d)\"; install -m 600 <PLATFORM_REPO_DIR>/env/platform-env.template \"\$T/env\"; git init \"\$T/log\""
    _pr01_show "bash -c '<PR-2.5 block 1: penv_set, need, twin and walle shells, exists_or_pending, checkpoint, sitting_end>' _ \"\$T\""
    _pr01_show "bash -c '<PR-2.5 block 2: bd_insert and bd_close on a register of PR-4.1's shape>' _ \"\$T\""
    _pr01_show "the same two blocks with zsh -c; rm -rf \"\$T\" (a throwaway copy: the real file is never touched)"
    return 0
  fi
  for sh in bash zsh; do
    if ! command -v "$sh" >/dev/null 2>&1; then _pr01_say "$sh is not installed: the $sh run is skipped"; [ "$sh" = bash ] && bad=1; continue; fi
    out="$(mktemp "${TMPDIR:-/tmp}/agp-pr25out.XXXXXX")" || return 1
    _pr01_pr25_run "$sh" > "$out" || bad=1
    if _pr01_pr25_compare "$out"; then _pr01_say "helper check passed in $sh"
    else _pr01_say "helper check FAILED in $sh; its output:"; sed 's/^/        /' "$out" >&3; bad=1; fi
    rm -f "$out"
  done
  _pr01_say "A check of shell logic only: not evidence that any Google command behaves as written (S177)."
  return $bad
}

step PR-2.6 CONSOLE "Read the tenant identifiers from the consoles" --needs "BUILD_LOG_DIR EVIDENCE_REGISTER" \
  --sets "OWNER_DAILY_ACCOUNT DOMAIN DIRECTORY_CUSTOMER_ID WORKSPACE_EDITION ORG_ID"
_pr01_pr26_roster() {   # 0 when the Super Admin roster PDF (P-02) is in records/ or has an evidence row
  local pdf
  for pdf in "$(v BUILD_LOG_DIR)"/records/*-PR-2.6-super-admin-roster-v*.pdf; do [ -f "$pdf" ] && return 0; done
  grep -q -- '-PR-2.6-super-admin-roster-v' "$(v EVIDENCE_REGISTER)" 2>/dev/null
}
s_PR_2_6_check() {
  ckpt_done PR-2.6 || return 1
  # The person's `agp-platform done PR-2.6` is the attestation (PHASES.md, rule 1 of 2026-10-01). A
  # missing roster is only a warning here; PR-5.2 stops on it, as the page does, before P-02 is closed.
  _pr01_pr26_roster || _pr01_say "WARNING: PR-2.6 is done but its Super Admin roster PDF is neither in $(v BUILD_LOG_DIR)/records/ nor in the evidence register; PR-5.2 will stop until PR-4.4 action 6 registers it"
  return 0
}
s_PR_2_6_manual() {
  cat <<EOF
WHO: the platform owner, Chrome profile daily. Read: Admin console > Account > Account settings > Profile (Customer ID);
Billing > Subscriptions (edition); Cloud console > project picker > the organisation > More > Settings (Organization ID);
Account > Admin roles > Super Admin > View admins: confirm your daily account is listed (P-02).
Save the pages as PDF in $(v BUILD_LOG_DIR)/records/: $(date -u +%Y-%m-%d)-PR-2.6-tenant-identifiers-v1.pdf, and the last one as
$(date -u +%Y-%m-%d)-PR-2.6-super-admin-roster-v1.pdf. PR-4.4 action 6 uploads both to the interim evidence location
and registers the roster with evidence_add; PR-5.2 stops until it is registered.
Then type, with the values read on screen (never my_customer for the customer id):
  penv_set OWNER_DAILY_ACCOUNT "<daily account email>";  penv_set DOMAIN "<primary domain>"
  penv_set DIRECTORY_CUSTOMER_ID "<Customer ID>";  penv_set WORKSPACE_EDITION "<edition name>"
  penv_set ORG_ID "<Organization ID>"
VERIFY: need OWNER_DAILY_ACCOUNT DOMAIN DIRECTORY_CUSTOMER_ID WORKSPACE_EDITION ORG_ID && echo OK; ORG_ID is all digits.
Record: agp-platform done PR-2.6
EOF
}

# ------------------------------------------------------------------ 6. Shell and credential rules

step PR-3.1 AUTO "Create the dedicated gcloud configuration" --needs "GCLOUD_CONFIG_NAME"
s_PR_3_1_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local p rc
  # The page's VERIFY: the configuration is listed and active in this shell, and holds no project.
  [ -n "${CLOUDSDK_CONFIG-}" ] || return 1
  r gcloud config configurations list --format='value(name,is_active)' 2>/dev/null \
    | awk -F'\t' -v n="$(v GCLOUD_CONFIG_NAME)" '$1 == n && $2 == "True" {f=1} END {exit !f}' || return 1
  p="$(r gcloud config get project 2>/dev/null)"; rc=$?
  [ $rc = 3 ] && return 3
  [ $rc = 0 ] || return 2
  case "$p" in ''|'(unset)') return 0;; esac
  return 1
}
s_PR_3_1_apply() {
  local name; name="$(v GCLOUD_CONFIG_NAME)"
  _pr01_say "CLOUDSDK_CONFIG=${CLOUDSDK_CONFIG:-<set by ~/.platform-env>}"
  if _pr01_live && [ -n "${CLOUDSDK_CONFIG-}" ] && [ -f "$CLOUDSDK_CONFIG/configurations/config_$name" ]; then
    _pr01_say "configuration $name exists"
  else
    x env -u CLOUDSDK_ACTIVE_CONFIG_NAME gcloud config configurations create "$name" --no-activate || return 1
  fi
  if _pr01_live; then gcloud config configurations list --format='value(name,is_active)' 2>&1 | sed 's/^/      /' >&3; fi
  x gcloud config unset project || return 1
  _pr01_live || return 0
  # VERIFY: the account line is shown, not enforced here: it is the sitting's state, and PR-3.2
  # and every sitting start check it.
  gcloud auth list --format='value(account)' 2>/dev/null | sed 's/^/      account: /' >&3
  penv_guard 2>&3 && _pr01_say "guard clean"
}

step PR-3.2 HUMAN "Prove the start-of-sitting and end-of-sitting blocks" --needs "BUILD_LOG_DIR GCLOUD_CONFIG_NAME" \
  --note "runs in your own shell: agp-platform sitting start, then sitting end"
s_PR_3_2_check() { ckpt_done PR-3.2; }
s_PR_3_2_manual() {
  cat <<EOF
WHO: the platform owner, alone. WHERE: your shell, ~/.platform-env sourced, nobody signed in.
The runner implements PR-3.2's two blocks; run them once now, without signing in:
  agp-platform sitting start     (penv_guard, gcloud auth list, SITTING_ID computed once, checkpoint START)
  agp-platform sitting end       (sitting_end, then checkpoint DONE with the same SITTING_ID)
VERIFY: awk -F'\t' '\$2 ~ /^SITTING-/ {print \$2, \$3}' "$(v BUILD_LOG_DIR)/checkpoints.tsv" | tail -n 2
  shows the same id twice, START then DONE, and sitting_end printed SITTING-END OK.
Every later sign-in: gcloud auth login <account> --no-launch-browser, the URL opened in that account's profile.
Record: agp-platform done PR-3.2
EOF
}

step PR-3.3 HUMAN "Cross-check the organisation in one short sign-in" \
  --needs "GCLOUD_CONFIG_NAME ORG_ID DIRECTORY_CUSTOMER_ID OWNER_DAILY_ACCOUNT BUILD_LOG_DIR" \
  --note "a sign-in stores a credential: the person runs it"
s_PR_3_3_check() { ckpt_done PR-3.3; }
s_PR_3_3_manual() {
  cat <<EOF
WHO: the platform owner, alone. WHERE: your shell, ~/.platform-env sourced; Chrome profile daily for the sign-in page.
  penv_guard && echo "guard clean"; gcloud auth login "$(v OWNER_DAILY_ACCOUNT)" --no-launch-browser
  R="$(v BUILD_LOG_DIR)/records/\$(date -u +%Y-%m-%d)-PR-3.3-organizations-v1.json"; gcloud organizations list --format=json > "\$R"
  jq -r 'length' "\$R"
  jq -r --arg o "organizations/$(v ORG_ID)" '[.[] | select(.name == \$o)] | length' "\$R"
  jq -r --arg o "organizations/$(v ORG_ID)" '.[] | select(.name == \$o) | (.owner.directoryCustomerId // .directoryCustomerId)' "\$R"
  sitting_end
P-03 closes only when the second prints 1 and the third prints $(v DIRECTORY_CUSTOMER_ID). A first 0 is a permission
symptom, a second 0 a wrong Organization ID, another customer id an unbound organisation: stop and record which
(PR-3.3's VERIFY table); never record two of them as the same thing.
Record: agp-platform done PR-3.3
EOF
}

# ------------------------------------------------------------------ 7. Build log, evidence and registers

_pr01_deviation_register() {
  cat <<'REGISTER'
# Bootstrap deviation register

Format fixed by setup/01 PR-4.1 under SD-01 (pending signature in 03). Append-only: a row is
closed by adding a line under "Closures", never by editing it. Ids are BD-<file>-<n>, allocated
by the file that opens the row, so parallel files never collide.

Kinds: EXC = dated standing exception; MOD = a factory module performed by hand;
DEV = any other dated deviation (for example SD-08's interim paging route, one-person PAM mode,
a stage tag made by hand while CI does not exist).

| Id | Opened (UTC date) | File and step | Kind | Module or exception | Scope (organisation, folder id, project id) | Inputs (register row, commit) | Produced (folder placement, labels, tags, APIs, policies, grants, budget, sinks, deny and PAB entries) | Zero-diff checker output (path, or BLOCKED and why) | Creator Owner removed (UTC date) | Approver (PAM grant id or signed record) | Expiry, or superseded by | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

## Closures

| Id | Closed (UTC date) | How (terraform import and empty plan: commit and plan output; withdrawal: step id) | Verified by (step id) |
|---|---|---|---|
REGISTER
}

_pr01_evidence_register() {
  cat <<'REGISTER'
# Evidence register

The evidence index of the setup procedures. Format fixed by setup/01 PR-4.2 under SD-38
(pending signature in 03). One row per record, appended with evidence_add or by hand in the same
columns. Never edited: a copy made later is a new row with the same record id and the copy
columns filled.

Location forms: build-log:<path> | interim:<file name> | repo:<path>@<commit> | bucket:gs://<bucket>/<object> | witness:gs://<bucket>/<object> | paper:safe (with its interim scan as a second row)

| Record id | Date | Step | E-xx | TISAX | Location | SHA-256 | Recorded by | Copied to evidence bucket | Copied to witness |
|---|---|---|---|---|---|---|---|---|---|
REGISTER
}

_pr01_drill_calendar() {
  cat <<'REGISTER'
# Drill calendar

Format fixed by setup/01 PR-4.3. The opening file sets "First due"; each drill appends its
record id to "Records" and sets "Next due". Records live in the witness from W-2 (08).

| Drill id | Drill | Cadence | Performed by | Witness | Opened by | First due | Records | Next due | Gate or limit it feeds |
|---|---|---|---|---|---|---|---|---|---|
| DR-06-1 | Break-glass envelope: open one, sign in, activate nothing, re-seal, alternate accounts | quarterly | custodian of the envelope | other administration line | 06 | *tbd* | | | 04 §7.1 |
| DR-18-1 | K7 fleet kill switch, dry run then enforced, per nonprod tier folder including fld-agents-p-sa-nonprod | *tbd* by 18; younger than 30 days at the grant | platform owner | second human for the enforced drill | 18 | *tbd* | | | G20 |
| DR-27-1 | Manual check of the witness heartbeat table until the absence alarms have seen data | daily | a witness administrator | — | 27 | *tbd* | | | SD-07 |
| DR-28-1 | Second human's independent proof of Eve on a seeded super-admin action | monthly (Assumption) and after every eve/config change | second human | a witness administrator records | 28 | *tbd* | | | G-4, G-6; SD-12 |
| DR-28-2 | Anti-silencing drill: a declared change by the platform owner is reported without their help | *tbd* by 28 | second human | a witness administrator | 28 | *tbd* | | | SD-12 |
| DR-28-3 | Witness push withheld once (G-2) | once before the grant, then *tbd* | production eve-export@ path, second human | witness administrators | 28 | *tbd* | | | G-2 |
| DR-37-1 | K6 drill on the twin | younger than 30 days at the grant | sandbox super admins | second human | 37 | *tbd* | | | G11 |
| DR-37-2 | Restore drill | *tbd* by 37 | platform owner | *tbd* | 37 | *tbd* | | | Tier W, G19 |
| DR-38-1 | Crisis-scenario tabletop | quarterly after the first | incident commander | security reviewer | 38 | *tbd* | | | G17 |
REGISTER
}

_pr01_register_apply() {   # _pr01_register_apply NAME BODY_FUNCTION COMMIT_MESSAGE: PR-4.1 to PR-4.3
  local f log; f="$(v "$1")"; log="$(v BUILD_LOG_DIR)"
  if _pr01_live && [ -s "$f" ]; then _pr01_say "exists: $f not rewritten"
  else "$2" | xw "$f" 644 || return 1; fi
  x git -C "$log" add "$f" || return 1
  _pr01_commit "$log" "$3"
  # The page's closing `checkpoint` line is written by the runner when the step passes.
}

step PR-4.1 AUTO "Create the bootstrap deviation register (SD-01 format)" --needs "DEVIATION_REGISTER BUILD_LOG_DIR"
s_PR_4_1_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local f; f="$(v DEVIATION_REGISTER)"
  [ -s "$f" ] && [ "$(grep -c '^| Id |' "$f")" = 2 ] && _pr01_committed "$(v BUILD_LOG_DIR)" "$f"
}
s_PR_4_1_apply() {
  _pr01_register_apply DEVIATION_REGISTER _pr01_deviation_register "registers: bootstrap deviation register skeleton" || return 1
  _pr01_live && _pr01_say "From here on rows go in with bd_insert and closures with bd_close (PR-2.2), never with >>."
  return 0
}

step PR-4.2 AUTO "Create the evidence register (the evidence index)" --needs "EVIDENCE_REGISTER BUILD_LOG_DIR"
s_PR_4_2_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local f; f="$(v EVIDENCE_REGISTER)"
  [ -s "$f" ] && grep -Eq -- '-PR-1\.1-workstation-tools-v[0-9]+ \|.*\| [0-9a-f]{64} \|' "$f" && _pr01_committed "$(v BUILD_LOG_DIR)" "$f"
}
s_PR_4_2_apply() {
  local f log; f="$(v EVIDENCE_REGISTER)"; log="$(v BUILD_LOG_DIR)"
  _pr01_register_apply EVIDENCE_REGISTER _pr01_evidence_register "registers: evidence register skeleton" || return 1
  if ! _pr01_live || ! grep -q -- '-PR-1.1-workstation-tools-v' "$f"; then
    ev PR-1.1 workstation-tools E-05 5.3.1 "build-log:records/tools.txt" "$log/records/tools.txt" || return 1
  fi
  _pr01_live || return 0
  grep -- '-PR-1.1-workstation-tools-v' "$f" | tail -n 1 | sed 's/^/      /' >&3
}

step PR-4.3 AUTO "Create the drill calendar" --needs "DRILL_CALENDAR BUILD_LOG_DIR"
s_PR_4_3_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local f; f="$(v DRILL_CALENDAR)"
  [ -s "$f" ] && [ "$(grep -c '^| DR-' "$f")" -ge 9 ] && _pr01_committed "$(v BUILD_LOG_DIR)" "$f"
}
s_PR_4_3_apply() {
  _pr01_register_apply DRILL_CALENDAR _pr01_drill_calendar "registers: drill calendar skeleton"
}

step PR-4.4 HUMAN "The interim evidence location" --witness --needs "OWNER_DAILY_ACCOUNT BUILD_LOG_DIR EVIDENCE_REGISTER" \
  --sets "EVIDENCE_INTERIM_LOCATION"
s_PR_4_4_check() {
  ckpt_done PR-4.4 || return 1
  # The person's `agp-platform done PR-4.4` is the attestation (PHASES.md, rule 1 of 2026-10-01); the
  # two rows actions 6 and 7 register are read here only to warn.
  local s; for s in PR-2.6-super-admin-roster PR-4.4-interim-location-members; do
    grep -q -- "-$s-v" "$(v EVIDENCE_REGISTER)" 2>/dev/null \
      || _pr01_say "WARNING: PR-4.4 is done but the evidence register has no $s row (setup/01 PR-4.4 actions 6 and 7)"
  done
  return 0
}
s_PR_4_4_manual() {
  cat <<EOF
WHO: the second human creates and manages it; the platform owner is only added as Contributor.
WHERE: drive.google.com signed in as the second human > Shared drives > New; then the drive's name menu > Manage members.
1-3. Shared drive agentic-platform-evidence-interim; the second human Manager, $(v OWNER_DAILY_ACCOUNT) Contributor, nobody
   else until platform-security@ (06); settings: no access for people outside the organisation, nor for non-members.
4-5. The second human sends the drive id (https://drive.google.com/drive/folders/<id>); the platform owner types:
   penv_set EVIDENCE_INTERIM_LOCATION "<shared drive id>"
6. Upload PR-2.6's two PDFs from $(v BUILD_LOG_DIR)/records/ to the drive; run PR-4.4 action 6's block (it registers the roster once).
7. The second human saves a dated Manage members screenshot in the drive; the platform owner downloads it, then:
   evidence_add PR-4.4 interim-location-members E-08 5.2.4 "interim:<file name>.pdf" "\$HOME/Downloads/<file name>.pdf"; rm -f the download
VERIFY: a test PDF uploaded by the platform owner cannot be moved to the trash; the second human sees two members.
Record: agp-platform done PR-4.4 --witness <the second human's email, or their name until 03 sets SECOND_HUMAN_EMAIL>
EOF
}

# ------------------------------------------------------------------ 9. Pending decisions and the prerequisites snapshot

step PR-5.1 AUTO "Record SD-01, SD-37 and SD-38 as applied pending" --needs "BUILD_LOG_DIR EVIDENCE_REGISTER"
_pr01_pr51_record() {   # the record of PR-5.1 that exists, of any date (prints its path relative to the log)
  local log f; log="$(v BUILD_LOG_DIR)"
  for f in "$log"/records/*-PR-5.1-pending-decisions-v1.md; do
    [ -f "$f" ] && { printf '%s' "records/${f##*/}"; return 0; }
  done
  return 1
}
s_PR_5_1_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local rec; rec="$(_pr01_pr51_record)" || return 1
  _pr01_committed "$(v BUILD_LOG_DIR)" "$rec" || return 1
  grep -q -- '-PR-5.1-pending-decisions-v' "$(v EVIDENCE_REGISTER)"
}
s_PR_5_1_apply() {
  local log r51; log="$(v BUILD_LOG_DIR)"
  if _pr01_live && r51="$(_pr01_pr51_record)"; then
    _pr01_say "exists: $r51 not rewritten"
  else
    r51="records/$(date -u +%Y-%m-%d)-PR-5.1-pending-decisions-v1.md"
    printf '%s\n' "# Decisions applied pending signature" "" "Date: $(date -u +%Y-%m-%d)" "" "- SD-01: bootstrap deviation register format (PR-4.1). Signature: 03." "- SD-37: setup/ procedures are the only execution path; walle_setup.py only after fixes; its self-test is not evidence. Signature: 03." "- SD-38: evidence homes and naming (section 7). Signature: 03, after the second human's review at PR-6.1." \
      | xw "$log/$r51" 644 || return 1
  fi
  x git -C "$log" add records || return 1
  _pr01_commit "$log" "PR-5.1 pending decisions applied" || return 1
  if ! _pr01_live || ! grep -q -- '-PR-5.1-pending-decisions-v' "$(v EVIDENCE_REGISTER)"; then
    ev PR-5.1 pending-decisions E-03 1.4.1 "build-log:$r51" "$log/$r51" || return 1
  fi
  _pr01_say "README's sign-off tracker shows SD-01, SD-37 and SD-38 as pending (read it there)."
}

step PR-5.2 AUTO "Snapshot the platform prerequisites" --needs "BUILD_LOG_DIR EVIDENCE_REGISTER"
_pr01_pr52_closed() {
  cat <<'CLOSED'
P-01 PR-1.1,PR-1.2,PR-1.3
P-02 PR-2.6
P-03 PR-3.3
P-14 PR-4.4
CLOSED
}
_pr01_pr52_open() {
  cat <<'ROWS'
P-04 06
P-05 03
P-06 03
P-07 03
P-08 03
P-09 03
P-10 03
P-11 03
P-12 03
P-13 03
P-15 06
P-16 04
P-17 04
P-18 04
P-19 04
P-20 04
P-21 04
P-22 07
P-23 04
P-24 04
P-25 04
P-26 06
P-27 18
P-28 35
P-29 18
P-30 03
ROWS
}
s_PR_5_2_check() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local log F id rest; log="$(v BUILD_LOG_DIR)"; F="$log/prerequisites-status.tsv"
  [ -f "$F" ] && _pr01_committed "$log" prerequisites-status.tsv || return 1
  while read -r id rest; do
    awk -F'\t' -v i="$id" '$2 == i && $3 == "closed" {f=1} END {exit !f}' "$F" || return 1
  done <<EOF
$(_pr01_pr52_closed)
EOF
  while read -r id rest; do
    awk -F'\t' -v i="$id" '$2 == i {f=1} END {exit !f}' "$F" || return 1
  done <<EOF
$(_pr01_pr52_open)
EOF
  return 0
}
s_PR_5_2_apply() {
  local log F reg today pdf s miss="" id step file
  log="$(v BUILD_LOG_DIR)"; reg="$(v EVIDENCE_REGISTER)"; F="$log/prerequisites-status.tsv"; today="$(date -u +%Y-%m-%d)"
  # The page's guard: P-02 is closed only on PR-2.6's registered roster. Registering it is the
  # platform owner's act (PR-4.4 action 6), never this step's.
  if ! _pr01_live; then
    _pr01_show "grep -q -- '-PR-2.6-super-admin-roster-v' \"$reg\"   (else STOP: P-02 is not proven; nothing written)"
  elif ! grep -q -- '-PR-2.6-super-admin-roster-v' "$reg"; then
    _pr01_fail "STOP: P-02 is not proven; nothing written. Register PR-2.6's Super Admin roster PDF with PR-4.4 action 6 first, then re-run this step"
    for pdf in "$log"/records/*-PR-2.6-super-admin-roster-v*.pdf; do [ -f "$pdf" ] && _pr01_say "the PDF saved at PR-2.6: $pdf"; done
    return 98   # the page's own STOP: a person registers the roster first
  fi
  if _pr01_live; then   # each closed row names a step with a DONE line
    for s in PR-1.1 PR-1.2 PR-1.3 PR-2.6 PR-3.3 PR-4.4; do ckpt_done "$s" || miss="$miss $s"; done
    [ -z "$miss" ] || { _pr01_fail "STOP: no DONE line for$miss; a closed row must name a done step. Nothing written"; return 1; }
  fi
  {
    if _pr01_live && [ -e "$F" ]; then cat "$F"; else printf 'date\tid\tstate\tclosed_by_file\tnote\n'; fi
    while read -r id step; do printf '%s\t%s\tclosed\t01\t%s\n' "$today" "$id" "$step"; done <<EOF
$(_pr01_pr52_closed)
EOF
    while read -r id file; do printf '%s\t%s\topen\t%s\t\n' "$today" "$id" "$file"; done <<EOF
$(_pr01_pr52_open)
EOF
  } | xw "$F" 644 || return 1
  x git -C "$log" add prerequisites-status.tsv || return 1
  _pr01_commit "$log" "PR-5.2 prerequisites snapshot" || return 1
  _pr01_live || return 0
  # VERIFY
  _pr01_say "P- rows today: $(awk -F'\t' -v d="$today" '$1 == d && $2 ~ /^P-/' "$F" | wc -l | tr -d ' ') (expected 30 on the first run)"
  awk -F'\t' -v d="$today" '$1 == d && $3 == "closed" {print "      " $2, $5}' "$F" >&3
}

# ------------------------------------------------------------------ 10. Review and close

step PR-6.1 HUMAN "The second human reviews the roles and signs the evidence convention" --witness \
  --needs "EVIDENCE_REGISTER EVIDENCE_INTERIM_LOCATION"
s_PR_6_1_check() { ckpt_done PR-6.1; }
s_PR_6_1_manual() {
  cat <<EOF
WHO: the second human, asynchronously; the platform owner is not present.
WHERE: setup/01 §2 and §7 (wiki or its Drive copy); the interim evidence location $(v EVIDENCE_INTERIM_LOCATION).
The second human checks every pair of §2.1 to §2.3 against the design pages, and §7.1 and §7.2 (evidence homes,
naming, Contributor only for the platform owner), then signs <date>-PR-6.1-roles-and-evidence-review-v1:
"roles table reviewed: agreed / corrections listed", "evidence convention SD-38: agreed / not agreed", and uploads the PDF.
The platform owner registers it (the file downloaded from the drive), then deletes the download:
  evidence_add PR-6.1 roles-and-evidence-review E-08 1.2.2 "interim:<file name>.pdf" "\$HOME/Downloads/<file name>.pdf"
  rm -f "\$HOME/Downloads/<file name>.pdf"
VERIFY: the record's owner is the second human, and its SHA-256 in the evidence register matches the download.
Record: agp-platform done PR-6.1 --witness <second human email, or name until 03> --note "interim:<file name>.pdf"
EOF
}

step PR-6.2 AUTO-READ "Close part 01" \
  --needs "PLATFORM_ENV_FILE BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER DRILL_CALENDAR EVIDENCE_INTERIM_LOCATION DOMAIN DIRECTORY_CUSTOMER_ID ORG_ID WORKSPACE_EDITION OWNER_DAILY_ACCOUNT"
_pr01_part_steps() {
  printf '%s\n' PR-1.1 PR-1.2 PR-1.3 PR-2.1 PR-2.2 PR-2.3 PR-2.4 PR-2.5 PR-2.6 PR-3.1 PR-3.2 PR-3.3 \
    PR-4.1 PR-4.2 PR-4.3 PR-4.4 PR-5.1 PR-5.2 PR-6.1
}
s_PR_6_2_check() { ckpt_done PR-6.2; }
s_PR_6_2_apply() {
  local log c s fn bad=0 nolog="" missing="" w st acct f cred=0
  log="$(v BUILD_LOG_DIR)"; c="$log/checkpoints.tsv"
  if ! _pr01_live; then
    _pr01_show "need PLATFORM_ENV_FILE BUILD_LOG_DIR ... OWNER_DAILY_ACCOUNT; penv_guard && echo \"guard clean\""
    _pr01_show "awk -F'\\t' '\$3==\"DONE\"{print \$2}' \"$c\" | sort -u        (PR-1.1 to PR-6.1, none twice)"
    _pr01_show "awk -F'\\t' '(\$2==\"PR-4.4\" || \$2==\"PR-6.1\") && \$3==\"DONE\" {print \$2, \$5}' \"$c\"   (witness not -)"
    _pr01_show "grep -n '<[^>]*>' \"$c\"; git -C \"$log\" status --short"
    _pr01_show "gcloud auth list --format='value(account)'   (no account: PR-3.3's sitting_end left none)"
    _pr01_show "for f in \"\$CLOUDSDK_CONFIG/application_default_credentials.json\" \"\$HOME/.walle/operator-token.json\"; do [ ! -e \"\$f\" ] || echo \"FAIL: \$f exists\"; done"
    return 0
  fi
  need PLATFORM_ENV_FILE BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER DRILL_CALENDAR EVIDENCE_INTERIM_LOCATION DOMAIN DIRECTORY_CUSTOMER_ID ORG_ID WORKSPACE_EDITION OWNER_DAILY_ACCOUNT 2>&3 || bad=1
  if penv_guard 2>&3; then _pr01_say "guard clean"; else bad=1; fi
  for s in $(_pr01_part_steps); do
    ckpt_done "$s" && continue
    # A step the runner found already done by its check has no DONE line; its check is run again here.
    fn="$(agp_fn "$s")_check"
    if "$fn" >/dev/null 2>&1; then nolog="$nolog $s"; else missing="$missing $s"; fi
  done
  [ -z "$nolog" ] || _pr01_say "done by their checks, with no DONE line of their own:$nolog"
  [ -z "$missing" ] || { _pr01_say "FAIL: not done:$missing"; bad=1; }
  awk -F'\t' '$3=="DONE" && $2 ~ /^PR-/ {print $2}' "$c" | sort | uniq -d | grep . >/dev/null && { _pr01_say "FAIL: a step has two DONE lines"; bad=1; }
  for s in PR-4.4 PR-6.1; do
    w="$(awk -F'\t' -v s="$s" '$2 == s && $3 == "DONE" {w=$5} END {print w}' "$c")"
    _pr01_say "$s witness: ${w:--}"
    case "$w" in ''|-) _pr01_say "FAIL: $s has no witness; append a correcting line before 02 starts"; bad=1;; esac
  done
  if grep -n '<[^>]*>' "$c" >/dev/null; then _pr01_say "FAIL: an unreplaced placeholder is in the log"; bad=1; else _pr01_say "no placeholder in the log"; fi
  # The runner's own run log (automation/) is committed when the run ends, so it is left out here.
  st="$(git -C "$log" status --short -- . ':(exclude)automation' 2>&1)"
  if [ -n "$st" ]; then _pr01_say "FAIL: the build log has uncommitted changes:"; printf '%s\n' "$st" | sed 's/^/        /' >&3; bad=1; fi
  # Part 01 opens no sitting of its own: PR-3.3's sign-in ended with sitting_end, so the page reads
  # that no credential is left. The read is all the script does; revoking is the person's sitting_end.
  if ! acct="$(r gcloud auth list --format='value(account)' 2>&3)"; then
    _pr01_say "FAIL: gcloud auth list failed (read the error above); an empty answer would not prove anything"; bad=1
  elif [ -n "$acct" ]; then
    _pr01_say "FAIL: still credentialed: $(printf '%s' "$acct" | tr '\n' ' ')"; cred=1
  else _pr01_say "no credentialed account"; fi
  if [ -z "${CLOUDSDK_CONFIG-}" ]; then _pr01_say "FAIL: CLOUDSDK_CONFIG is not set; ~/.platform-env was not sourced"; bad=1
  else
    for f in "$CLOUDSDK_CONFIG/application_default_credentials.json" "$HOME/.walle/operator-token.json"; do
      [ ! -e "$f" ] || { _pr01_say "FAIL: $f exists"; cred=1; }
    done
  fi
  if [ $cred = 1 ]; then
    _pr01_say "In your shell, ~/.platform-env sourced: sitting_end (it revokes them); record in the build log why a credential outlived PR-3.3; then resume"
    bad=1
  fi
  return $bad
}
