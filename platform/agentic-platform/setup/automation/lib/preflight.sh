# lib/preflight.sh: what must be true before `apply` changes anything.
#
# Tools, ~/.platform-env and its guard, the signed-in account, and the permissions each selected phase
# declares with `requires`, tested on the organisation and the billing account with the
# testIamPermissions methods (which need no special role to call and change nothing).

AGP_MIN_GCLOUD_MAJOR="${AGP_MIN_GCLOUD_MAJOR:-500}"   # a phase file may raise it (setup/01 PR-1.1)

agp_pf_line() { printf '  %-6s %s\n' "$1" "$2" >&3; }

agp_pf_tools() {
  local t bad=0 maj
  for t in gcloud bq git python3 curl awk sed shasum mktemp; do
    if command -v "$t" >/dev/null 2>&1; then agp_pf_line ok "$t"; else agp_pf_line FAIL "$t is not installed"; bad=1; fi
  done
  if command -v gcloud >/dev/null 2>&1; then
    maj="$(gcloud version --format='value("Google Cloud SDK")' 2>/dev/null | cut -d. -f1)"
    case "$maj" in
      ''|*[!0-9]*) agp_pf_line WARN "could not read the gcloud version";;
      *) if [ "$maj" -lt "$AGP_MIN_GCLOUD_MAJOR" ]; then agp_pf_line FAIL "gcloud $maj is older than $AGP_MIN_GCLOUD_MAJOR (gcloud components update)"; bad=1
         else agp_pf_line ok "gcloud core $maj"; fi;;
    esac
    gcloud components list --only-local-state --format='value(id)' 2>/dev/null | grep -qx beta \
      && agp_pf_line ok "gcloud beta component" || agp_pf_line WARN "gcloud beta component not installed; some steps use it"
  fi
  return $bad
}

agp_pf_env() {
  local bad=0 n
  if [ -f "${PLATFORM_ENV_FILE:-$HOME/.platform-env}" ]; then agp_pf_line ok "the file ~/.platform-env is present"
  else agp_pf_line FAIL "the file ~/.platform-env is missing: agp-platform apply --phase 01 (setup/01 PR-2.1 to PR-2.3)"; return 1; fi
  for n in GCLOUD_CONFIG_NAME BUILD_LOG_DIR PLATFORM_REPO_DIR EVIDENCE_REGISTER; do
    if has_value "$n"; then agp_pf_line ok "$n"; else agp_pf_line FAIL "$n has no value"; bad=1; fi
  done
  if command -v penv_guard >/dev/null 2>&1; then
    if penv_guard >/dev/null 2>&1; then agp_pf_line ok "penv_guard clean: no default gcloud or bq project"
    else agp_pf_line FAIL "penv_guard: $(penv_guard 2>&1 | head -1)"; bad=1; fi
  fi
  [ -n "${BUILD_LOG_DIR-}" ] && git -C "$BUILD_LOG_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    && agp_pf_line ok "build log is a git repository" || { agp_pf_line FAIL "BUILD_LOG_DIR is not a git repository (setup/01 PR-2.1)"; bad=1; }
  [ -x "${PLATFORM_REPO_DIR-}/tools/decision-need.sh" ] && agp_pf_line ok "decision tools (setup/03 DC-1.2)" \
    || agp_pf_line WARN "decision tools not installed yet: every gated step reads as GATED until setup/03 DC-1.2"
  return $bad
}

agp_pf_account() {
  local acct expected
  acct="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)"
  if [ -z "$acct" ]; then
    # setup/01 to 06 part 2 run before any admin account signs in to gcloud (06 OB-3.1 is the first sign-in)
    agp_pf_line WARN "no active gcloud account: a step that calls Google will stop (gcloud auth login <account> --no-launch-browser)"; return 0
  fi
  if has_value SA_1_ADMIN && [ "$acct" = "$(_penv_get SA_1_ADMIN)" ]; then :
  elif has_value OWNER_DAILY_ACCOUNT && [ "$acct" = "$(_penv_get OWNER_DAILY_ACCOUNT)" ]; then
    has_value SA_1_ADMIN && agp_pf_line WARN "signed in as the daily account $acct; from 06 OB-3.1 on the procedures run as $(_penv_get SA_1_ADMIN)"
  elif has_value SA_1_ADMIN || has_value OWNER_DAILY_ACCOUNT; then
    agp_pf_line FAIL "signed in as $acct, which is neither SA_1_ADMIN nor OWNER_DAILY_ACCOUNT (setup/06 OB-2.12)"; return 1
  fi
  agp_pf_line ok "signed in as $acct"
  case "$acct" in *.gserviceaccount.com) agp_pf_line FAIL "a service account: the platform is set up by a person"; return 1;; esac
  return 0
}

agp_pf_test_perms() {   # agp_pf_test_perms URL "perm ..."  -> prints missing permissions
  local url="$1" perms="$2" body p first=1
  body="$(mktemp "${TMPDIR:-/tmp}/agp-tp.XXXXXX")"
  { printf '{"permissions":['
    for p in $perms; do [ $first = 1 ] || printf ','; printf '"%s"' "$p"; first=0; done
    printf ']}'; } > "$body"
  local saved="$AGP_MODE"; AGP_MODE=apply   # testIamPermissions is a read, sent as POST
  local out; out="$(AGP_CUR_STEP=preflight api POST "$url" "$body")"; local rc=$?
  AGP_MODE="$saved"; rm -f "$body"
  if [ $rc -ne 0 ]; then printf 'ERROR\n'; return 2; fi
  # shellcheck disable=SC2086
  printf '%s' "$out" | python3 "$AGP_HOME/lib/agp_json.py" missing $perms
}

agp_pf_perms() {
  local k org="" bill="" miss bad=0
  k=0; while [ $k -lt $AGP_P_N ]; do
    case "$AGP_SELECTED" in *" ${AGP_P_ID[$k]} "*) org="$org ${AGP_P_ORG[$k]}"; bill="$bill ${AGP_P_BILL[$k]}";; esac
    k=$((k + 1))
  done
  org="$(printf '%s\n' $org | sort -u | tr '\n' ' ')"; bill="$(printf '%s\n' $bill | sort -u | tr '\n' ' ')"
  if [ -n "$(echo "$org" | tr -d ' ')" ]; then
    if has_value ORG_ID; then
      miss="$(agp_pf_test_perms "https://cloudresourcemanager.googleapis.com/v3/organizations/$(_penv_get ORG_ID):testIamPermissions" "$org")"
      if [ "$miss" = ERROR ]; then agp_pf_line FAIL "could not test permissions on organizations/$(_penv_get ORG_ID)"; bad=1
      elif [ -n "$miss" ]; then agp_pf_line FAIL "missing on the organisation:"; printf '%s\n' "$miss" | sed 's/^/           /' >&3; bad=1
      else agp_pf_line ok "every organisation permission the selected phases declare ($(echo $org | wc -w | tr -d ' '))"; fi
    else agp_pf_line WARN "ORG_ID has no value yet (setup/01 PR-2.6): organisation permissions not tested"; fi
  fi
  if [ -n "$(echo "$bill" | tr -d ' ')" ]; then
    if has_value BILLING_ACCOUNT_ID; then
      miss="$(agp_pf_test_perms "https://cloudbilling.googleapis.com/v1/billingAccounts/$(_penv_get BILLING_ACCOUNT_ID):testIamPermissions" "$bill")"
      if [ "$miss" = ERROR ]; then agp_pf_line FAIL "could not test permissions on the billing account"; bad=1
      elif [ -n "$miss" ]; then agp_pf_line FAIL "missing on the billing account:"; printf '%s\n' "$miss" | sed 's/^/           /' >&3; bad=1
      else agp_pf_line ok "every billing permission the selected phases declare"; fi
    else agp_pf_line WARN "BILLING_ACCOUNT_ID has no value yet (setup/07): billing permissions not tested"; fi
  fi
  return $bad
}

agp_cmd_preflight() {
  agp_parse_common "$@"
  local bad=0
  printf 'Preflight, phases:%s\n' "$AGP_SELECTED" >&3
  printf 'Tools\n' >&3;        agp_pf_tools   || bad=1
  printf 'Variables\n' >&3;    agp_pf_env     || bad=1
  printf 'Account\n' >&3;      agp_pf_account || bad=1
  printf 'Permissions\n' >&3;  agp_pf_perms   || bad=1
  [ $bad = 0 ] && printf '\nPREFLIGHT OK\n' >&3 || printf '\nPREFLIGHT FAILED: fix the lines marked FAIL\n' >&3
  return $bad
}

agp_preflight_quick() {     # before apply: the parts that make a run unsafe if wrong
  local bad=0
  agp_pf_tools >/dev/null 2>&1 3>/dev/null || bad=1
  # phase 01 creates ~/.platform-env, so it may run before the file exists
  case "$AGP_SELECTED" in
    " 01 ") ;;
    *) agp_pf_env 3>/dev/null || bad=1
       agp_pf_account 3>/dev/null || bad=1
       agp_pf_perms 3>/dev/null || bad=1;;
  esac
  return $bad
}
