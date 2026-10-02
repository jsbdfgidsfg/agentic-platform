# phases/21-sandbox-tenant-and-nonprod-foundation.sh: setup/21, the sandbox tenant (a second Workspace
# customer with its own Cloud organisation) and the platform-side changes that let the nonprod twins
# live under the platform's folders while acting on that tenant.
#
# How the page maps onto the classes:
# - Every step done in or on the sandbox tenant (sign-up, domain, administrators, keys, groups,
#   multi-party approval, the sandbox organisation, its IAM and logging: SB-1.2 to SB-6.7) is done by
#   the sandbox super admins on their own workstations and browser profiles, never by the platform
#   owner's script, so each is HUMAN. A password, a key or a backup code never passes through here.
# - SB-6.8 is HUMAN: the identifiers are read out by sandbox super admin 1 and typed by the platform
#   owner with penv_set, compared by the second human.
# - The platform owner's reads (SB-1.1, SB-7.1) are AUTO-READ; the application of the B5 child policies
#   (SB-7.4), the admission proof (SB-7.5) and the twin id reservation (SB-8.1) are AUTO.
# - SB-7.3 is HUMAN: it ends in a pull request merged with the second human's approval, and it pushes to the
#   git host and runs gh (phase 03's rule for git-host steps). SB-7.4 stops until main carries its files.
# - SB-8.2 and SB-8.3 write here-documents with values a person fills from records; this phase does not
#   retype a page's here-document (lib/PHASES.md), so the person runs the page's block: HUMAN.
# - SB-8.4 ends in a signed manual parse, and SB-9.1 and SB-9.2 are reviews and the end of sittings on
#   several workstations: HUMAN. SB-7.6 and SB-8.5 are BLOCKED (B-02, B-03).
# - SB-7.2's answer is recorded with: agp-platform done SB-7.2 --note "improvers_nonprod_admits_sandbox=true"
#   (or =false); SB-7.3 and SB-7.4 add FLD_IMPROVERS_NONPROD to their targets only on =true.
# - Every evidence row the page registers names a file with its SHA-256 (SB-1.1's reads, SB-7.1's summary,
#   SB-7.4's reads file, SB-7.5's result file, SB-8.1's ids file); the summary, reads and result files end
#   with the SHA-256 of the other files of their directory, as the page's blocks write them.
# - SB-7.4 revokes its ENT_PLATFORM_POLICY grant once its VERIFY passes (the page's pam_revoke), so it
#   declares --removes; on a failed VERIFY the grant is kept for the page's ROLLBACK.
#
# Helpers are prefixed _sb_ because every phase file is loaded into the same shell.

phase 21 "Sandbox tenant and nonprod foundation" "21-sandbox-tenant-and-nonprod-foundation.md"
requires org "orgpolicy.policy.get"

SB_GATES="WDEC-29 SD-29 D3 SD-02 SD-05 SD-06 SD-25 SD-27 SD-35 NAMES PPL-SB1 PPL-SB2"
SB_FLD_ALL="FLD_AGENTIC_PLATFORM FLD_AGENTS_P_NONPROD FLD_AGENTS_P_PROD FLD_AGENTS_P_SA_NONPROD FLD_AGENTS_P_SA_PROD FLD_CONTROLLERS_NONPROD FLD_CONTROLLERS_PROD FLD_IMPROVERS_NONPROD FLD_IMPROVERS_PROD"
SB_FLD_READ="FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_NONPROD FLD_IMPROVERS_NONPROD FLD_AGENTS_P_PROD FLD_AGENTS_P_SA_PROD FLD_CONTROLLERS_PROD FLD_IMPROVERS_PROD"
SB_PAIRS="FLD_AGENTS_P_NONPROD:FLD_AGENTS_P_PROD FLD_AGENTS_P_SA_NONPROD:FLD_AGENTS_P_SA_PROD FLD_CONTROLLERS_NONPROD:FLD_CONTROLLERS_PROD"
SB_B5_BRANCH="sb-7-3-sandbox-b5"
SB_REFUSAL="do not belong to a permitted customer"

# ---------------------------------------------------------------- helpers

_sb_say() { printf '      %s\n' "$*" >&3; }
_sb_plan() { [ "$AGP_MODE" = apply ] || printf '      read: %s\n' "$*" >&3; }
_sb_pre() { AGP_CALL_CONTEXT=check "$@"; }      # a read inside _apply that decides; marked as a check for the fakes
_sb_ev() { printf '%s/evidence/21' "$(v BUILD_LOG_DIR)"; }
_sb_repo() { v PLATFORM_REPO_DIR; }

_sb_sleep() {   # SECONDS: a wait the page prescribes, multiplied by AGP_WAIT_SCALE (a whole number, 1 when unset; 0 in the tests)
  local s="${AGP_WAIT_SCALE:-1}"
  case "$s" in ''|*[!0-9]*) s=1;; esac
  [ $(($1 * s)) -gt 0 ] || return 0
  sleep $(($1 * s))
}

_sb_pull() {    # REPO: the page's `git pull --ff-only`. A clone whose branch has no upstream configured (a remote
                # added after the first push, without -u) names origin and the branch, which is the same pull.
  local b
  if [ "$AGP_MODE" = apply ] && ! git -C "$1" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    b="$(git -C "$1" symbolic-ref --short HEAD 2>/dev/null)" || b=main
    _sb_say "this clone's $b has no upstream configured: pulling origin $b by name"
    x git -C "$1" pull --ff-only origin "$b"; return $?
  fi
  x git -C "$1" pull --ff-only
}

_sb_xto() {     # FILE CMD...: x, with the command's output kept in FILE (apply mode only)
  local f="$1"; shift
  if [ "$AGP_MODE" != apply ]; then x "$@"; return $?; fi
  x "$@" > "$f" 2>&1
}

_sb_improvers() {   # SB-7.2 was recorded with improvers_nonprod_admits_sandbox=true
  local t; t="$(v BUILD_LOG_DIR)/checkpoints.tsv"
  [ -f "$t" ] || return 1
  awk -F'\t' '$2 == "SB-7.2" && $3 == "DONE"' "$t" | tail -n 1 | grep -q 'improvers_nonprod_admits_sandbox=true'
}

_sb_targets() {     # the nonprod folders whose B5 admits the sandbox customer
  printf 'FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_NONPROD'
  _sb_improvers && printf ' FLD_IMPROVERS_NONPROD'
  return 0
}

_sb_py() { python3 -c "$1" "${@:2}"; }

_sb_vals() {    # the allowedValues of the policy JSON on standard input, sorted, as compact JSON; `no-spec` when the
                # reply holds no spec object (then the own-policy reads of _sb_b5_own decide alone); 2 when not JSON
  _sb_py 'import json,sys
try:
    d=json.load(sys.stdin)
except ValueError:
    sys.exit(2)
if not isinstance(d, dict) or not isinstance(d.get("spec"), dict):
    print("no-spec"); sys.exit(0)
v=[]
for r in (d["spec"].get("rules") or []):
    v += ((r.get("values") or {}).get("allowedValues") or [])
print(json.dumps(sorted(v), separators=(",", ":")))'
}

# _sb_eff FOLDER_VAR: the effective allowedValues of B5 on that folder (see _sb_vals).
# 0 read, 1 not found, 2 another error, 3 offline.
_sb_eff() {
  [ "$AGP_OFFLINE" = 1 ] && return 3
  local j rc
  j="$(gcloud org-policies describe iam.allowedPolicyMemberDomains --folder="$(v "$1")" --effective --format=json 2>&1)"; rc=$?
  if [ $rc -ne 0 ]; then
    printf '%s' "$j" | grep -qiE 'NOT_FOUND|not found' && return 1
    printf '%s\n' "$j" | sed 's/^/        /' >&3; return 2
  fi
  printf '%s' "$j" | _sb_vals
}

# _sb_own FOLDER_VAR [FILTER]: the folder holds its own B5 policy (matching FILTER). A filtered list, as phase 13
# reads attachment points: 0 listed, 1 not, 2 error, 3 offline.
_sb_own() {
  nonempty r gcloud org-policies list --folder="$(v "$1")" \
    --filter="name~\"/policies/iam.allowedPolicyMemberDomains\$\"${2:+ AND $2}" --format='value(name)'
}

# _sb_b5_own WHEN: the attachment points of B5 that decide the effective values, one line each, `FAIL` on a
# miss. before (SB-7.1): fld-agentic-platform holds B5 with DIRECTORY_CUSTOMER_ID and not the sandbox customer,
# and no other folder of SB_FLD_ALL holds its own. after (SB-7.4): the same at fld-agentic-platform; each target
# holds its own, merging with the parent and admitting SANDBOX_CUSTOMER_ID; every other folder read holds none.
# Reads asserting an absence are marked as checks (the offline fakes answer every other read inside apply as present).
_sb_b5_own() {
  local F rc dir sbx list
  dir="spec.rules.values.allowedValues:$(v DIRECTORY_CUSTOMER_ID)"; sbx="spec.rules.values.allowedValues:$(v SANDBOX_CUSTOMER_ID)"
  _sb_own FLD_AGENTIC_PLATFORM "$dir"; rc=$?
  case $rc in 0) echo "FLD_AGENTIC_PLATFORM own B5 lists DIRECTORY_CUSTOMER_ID";; 1) echo "FAIL FLD_AGENTIC_PLATFORM holds no B5 listing DIRECTORY_CUSTOMER_ID (13)";;
    *) echo "FAIL FLD_AGENTIC_PLATFORM: the policy list failed ($rc)";; esac
  _sb_pre _sb_own FLD_AGENTIC_PLATFORM "$sbx"; rc=$?
  case $rc in 1) ;; 0) echo "FAIL FLD_AGENTIC_PLATFORM's own B5 lists SANDBOX_CUSTOMER_ID: production would admit the sandbox";;
    *) echo "FAIL FLD_AGENTIC_PLATFORM: the policy list failed ($rc)";; esac
  if [ "$1" = before ]; then list="$SB_FLD_ALL"; else list="$SB_FLD_READ"; fi
  for F in $list; do
    [ "$F" = FLD_AGENTIC_PLATFORM ] && continue
    if [ "$1" = after ] && case " $(_sb_targets) " in *" $F "*) true;; *) false;; esac; then
      _sb_own "$F" "spec.inheritFromParent=true AND $sbx"; rc=$?
      case $rc in 0) echo "$F own B5 merges with the parent and lists SANDBOX_CUSTOMER_ID";;
        1) echo "FAIL $F holds no own B5 merging with the parent and listing SANDBOX_CUSTOMER_ID";; *) echo "FAIL $F: the policy list failed ($rc)";; esac
    else
      _sb_pre _sb_own "$F"; rc=$?
      case $rc in 1) echo "$F holds no own B5 (inherits)";; 0) echo "FAIL $F holds its own B5 policy";; *) echo "FAIL $F: the policy list failed ($rc)";; esac
    fi
  done
}

_sb_want() {    # ID...: the sorted compact JSON list of the ids
  _sb_py 'import json,sys; print(json.dumps(sorted(sys.argv[1:]), separators=(",", ":")))' "$@"
}

# PAM: 12's pam_request and pam_wait, written with the gcloud commands they wrap.
_sb_grant_name() {  # ENTITLEMENT FILTER: the newest grant the caller created on it matching FILTER
  r gcloud pam grants search --entitlement="$1" --caller-relationship=had-created --filter="$2" \
    --format='value(name)' --billing-project="$(v CICD_PROJECT)" 2>/dev/null | head -n 1
}
_sb_grant_state() { r gcloud pam grants describe "$1" --billing-project="$(v CICD_PROJECT)" --format='value(state)' 2>/dev/null; }

SB_GRANT=""
_sb_grant() {   # ENT_VAR SECONDS JUSTIFICATION [FLAG...]: an ACTIVE grant of the caller in SB_GRANT; requested once, awaited
  local ent="$1" sec="$2" why="$3" n i=0 s; shift 3
  ent="$(v "$ent")"
  if [ "$AGP_MODE" != apply ]; then
    x gcloud pam grants create --entitlement="$ent" --requested-duration="${sec}s" --justification="$why" "$@" \
      --billing-project="$(v CICD_PROJECT)" --format='value(name)'
    _sb_say "then waits until the second human approves the grant (state ACTIVE); nothing privileged runs before"
    SB_GRANT="<grant>"; return 0
  fi
  n="$(_sb_pre _sb_grant_name "$ent" 'state=ACTIVE')"
  if [ -n "$n" ]; then SB_GRANT="$n"; _sb_say "an ACTIVE grant exists ($n); not requested again"; return 0; fi
  n="$(_sb_pre _sb_grant_name "$ent" 'state=APPROVAL_AWAITED OR state=SCHEDULED OR state=ACTIVATING')"
  if [ -n "$n" ]; then _sb_say "a grant is already waiting for approval ($n); not requested again"
  else
    n="$(x gcloud pam grants create --entitlement="$ent" --requested-duration="${sec}s" --justification="$why" "$@" \
      --billing-project="$(v CICD_PROJECT)" --format='value(name)')" || return 1
    n="$(printf '%s\n' "$n" | tail -n 1)"
  fi
  SB_GRANT="$n"
  _sb_say "waiting for the second human's approval of $n (polls every 20 s, up to 30 minutes)"
  while [ $i -lt 90 ]; do
    s="$(_sb_grant_state "$n")"
    [ "$s" = ACTIVE ] && { _sb_say "STATE ACTIVE"; return 0; }
    case "$s" in DENIED|REVOKED|ENDED|EXPIRED) _sb_say "STATE $s (terminal, not ACTIVE): request again by re-running this step"; return 1;; esac
    i=$((i + 1)); _sb_sleep 20
  done
  _sb_say "STOP: $n is not ACTIVE after 30 minutes; when it is approved, re-run this step (it will not request again)"
  return 1
}

_sb_revoke() {  # GRANT REASON: pam_revoke, then a short wait for REVOKED
  local i=0
  x gcloud pam grants revoke "$1" --reason="$2" --billing-project="$(v CICD_PROJECT)" || return 1
  [ "$AGP_MODE" = apply ] || return 0
  while [ $i -lt 6 ]; do
    [ "$(_sb_grant_state "$1")" = REVOKED ] && { _sb_say "STATE REVOKED"; return 0; }
    i=$((i + 1)); _sb_sleep 20
  done
  _sb_say "NOTE: $1 does not read REVOKED yet; confirm with: gcloud pam grants describe $1 --billing-project=$(v CICD_PROJECT)"
  return 0
}

_sb_manual_sandbox() {  # the common lines of a step done on the sandbox side
  echo "WHERE: the sandbox workstation (sandbox copy of ~/.platform-env, gcloud configuration 'sandbox') or the"
  echo "  sandbox Admin console in a clean sandbox browser profile. Never the platform owner's configuration."
}

# ======================================================================== Part 1: gates and workstations

_sb_1_1_reads() {
  local repo bld n f out
  repo="$(_sb_repo)"; bld="$(v BUILD_LOG_DIR)"
  # shellcheck disable=SC2086
  out="$("$(agp_tool decision-need.sh)" $SB_GATES 2>&1)" || echo "FAIL decision-need.sh: a gate is not SIGNED"
  printf '%s\n' "$out"
  f="$(grep -il "before the super-admin grant" "$repo"/decisions/*-sandbox-tenant.md 2>/dev/null)"
  if [ -n "$f" ]; then echo "sandbox-tenant record: $f"
  else echo "FAIL no decisions/*-sandbox-tenant.md reads \"before the super-admin grant\" (X-ORG-14; \"before Stage 1\" alone is a stop)"; fi
  out="$(awk -F'\t' '($2=="OP-6.5" || $2=="RG-2.6" || $2=="FM-10.3") && $3=="DONE" {print $2, $3}' "$bld/checkpoints.tsv" | sort -u)"
  printf '%s\n' "$out"
  for n in OP-6.5 RG-2.6 FM-10.3; do printf '%s\n' "$out" | grep -q "^$n DONE" || echo "FAIL no DONE line for $n (13, 16, 17 must be done)"; done
  n="$(printf '%s\n' "$(v SANDBOX_SA_1_EMAIL)" "$(v SANDBOX_SA_2_EMAIL)" | grep -vc "@$(v SANDBOX_DOMAIN)\$")"
  echo "addresses outside SANDBOX_DOMAIN: $n"; [ "$n" = 0 ] || echo "FAIL a sandbox super admin address is not on SANDBOX_DOMAIN"
  out="$(printf '%s\n' "$(v SANDBOX_SA_1_EMAIL)" "$(v SANDBOX_SA_2_EMAIL)" "$(v SECOND_HUMAN_EMAIL)" | sort | uniq -d)"
  [ -z "$out" ] || echo "FAIL the same address holds two roles: $out"
  case "$(v SANDBOX_DOMAIN)" in "$(v DOMAIN)"|*".$(v DOMAIN)") echo "FAIL STOP: sandbox domain is a production domain or subdomain";; *) echo "domain distinct";; esac
}

step SB-1.1 AUTO-READ "Check the gates, the order of work and the separation of people" \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER SANDBOX_DOMAIN SANDBOX_SA_1_EMAIL SANDBOX_SA_2_EMAIL SECOND_HUMAN_EMAIL DOMAIN DIRECTORY_CUSTOMER_ID ORG_ID" \
  --gate "$SB_GATES"
s_SB_1_1_check() { ckpt_done SB-1.1; }
s_SB_1_1_apply() {
  local out f
  if [ "$AGP_MODE" = apply ]; then penv_guard >/dev/null 2>&1 || { _sb_say "FAIL penv_guard: read its output in a sourced shell"; return 1; }
  else _sb_plan "penv_guard (silent)"; fi
  x checkpoint SB-1.1 START || return 1
  _sb_pull "$(_sb_repo)" || return 1
  x mkdir -p "$(_sb_ev)" || return 1
  if [ "$AGP_MODE" != apply ]; then
    _sb_plan "tools/decision-need.sh $SB_GATES (each SIGNED)"
    _sb_plan "grep -il 'before the super-admin grant' decisions/*-sandbox-tenant.md (the X-ORG-14 wording)"
    _sb_plan "checkpoints.tsv: DONE lines for OP-6.5, RG-2.6 and FM-10.3"
    _sb_plan "both sandbox super admins on SANDBOX_DOMAIN; no address holds two roles; SANDBOX_DOMAIN is not DOMAIN or a subdomain of it"
    ev SB-1.1 gates E-03 1.4.1 "build-log:evidence/21/SB-1.1-gates.txt"
    return 0
  fi
  f="$(_sb_ev)/SB-1.1-gates.txt"
  out="$(_sb_1_1_reads)"
  printf '%s\n' "$out" | sed 's/^/        /' >&3
  printf '%s\n' "$out" | xw "$f" 600 || return 1
  ev SB-1.1 gates E-03 1.4.1 "build-log:evidence/21/${f##*/}" "$f" || return 1
  _sb_say "The second human confirms, from 03's people records, that they hold neither sandbox role."
  ! printf '%s\n' "$out" | grep -q '^FAIL'
}

step SB-1.2 HUMAN "Confirm the order, the edition and the keys in hand" --witness
s_SB_1_2_check() { ckpt_done SB-1.2; }
s_SB_1_2_manual() {
  echo "WHO: platform owner; sandbox super admin 1 confirms (the witness)."
  echo "WHERE: 04's records in EVIDENCE_INTERIM_LOCATION (<date>-PU-2.5-sandbox-order-v1, <date>-PU-4.2-key-custody-record-v1); the safe log."
  echo "DO: write on the sitting form (1) the ordered edition, equal to WORKSPACE_EDITION and Enterprise Standard or Plus;"
  echo "  (2) the seats: two sandbox super admins, eve@ and walle@ on SANDBOX_DOMAIN, the synthetic users of SB-4.2;"
  echo "  (3) the named terms signer for the sandbox Cloud organisation (SB-6.1); (4) four labelled keys and their custodians."
  echo "STOP if the edition is below Enterprise Standard, or differs from production without a signed SD-29 exception (back to 04)."
  echo "RECORD: <date>-SB-1.2-order-and-keys-v1 (TISAX 5.2.2, 6.1.1); then: agp-platform done SB-1.2 --witness <sandbox super admin 1>"
}

step SB-1.3 HUMAN "Prepare each sandbox workstation copy" --witness
s_SB_1_3_check() { ckpt_done SB-1.3; }
s_SB_1_3_manual() {
  echo "WHO: each sandbox super admin on their own workstation (or separate macOS user); the other watches."
  echo "WHERE: the sandbox workstation shell. Not this shell: the platform owner's configuration never holds a sandbox credential."
  echo "DO: run SB-1.3's block of setup/21 as written: install the template as ~/.platform-env, penv_set GCLOUD_CONFIG_NAME sandbox"
  echo "  and the six names, re-source, then 'env -u CLOUDSDK_ACTIVE_CONFIG_NAME gcloud config configurations create sandbox"
  echo "  --no-activate' and 'gcloud config unset project'."
  echo "VERIFY in a new shell: 'sandbox' active (True), no account, no project, CLOUDSDK_CONFIG=\$HOME/.config/gcloud-sandbox,"
  echo "  'guard clean', and 0 production identifiers (ORG_ID, DIRECTORY_CUSTOMER_ID) in the sandbox copy."
  echo "RECORD: build-log line SB-1.3 with that output (TISAX 5.3.1); then: agp-platform done SB-1.3 --witness <the other admin>"
}

step SB-1.4 HUMAN "Confirm DNS custody of the sandbox domain" --witness
s_SB_1_4_check() { ckpt_done SB-1.4; }
s_SB_1_4_manual() {
  echo "WHO: sandbox super admin 1; sandbox super admin 2 watches."
  _sb_manual_sandbox
  echo "DO: whois \"\$SANDBOX_DOMAIN\" | grep -iE 'Registrar:|Domain Status:'; dig +short NS, TXT and MX \"\$SANDBOX_DOMAIN\";"
  echo "  in the DNS provider console confirm both sandbox super admins can edit the zone and 2SV is on for every user."
  echo "VERIFY: registrant is the organisation; no google-site-verification= TXT (one is a stop: 04 PU-2.5); MX empty or"
  echo "  confirmed replaceable."
  echo "RECORD: <date>-SB-1.4-sandbox-dns-custody-v1 (TISAX 5.2.2); then: agp-platform done SB-1.4 --witness <sandbox super admin 2>"
}

# ======================================================================== Part 2: sign-up and the first super admin

step SB-2.1 HUMAN "Activate the sandbox subscription with the first super admin" --witness
s_SB_2_1_check() { ckpt_done SB-2.1; }
s_SB_2_1_manual() {
  echo "WHO: sandbox super admin 1; the second human present (witness)."
  echo "WHERE: clean browser profile sandbox-sa-1; the provisioning route named in the signed order (04 PU-2.5)."
  echo "DO: setup/21 SB-2.1. The first administrator is SANDBOX_SA_1_EMAIL. The password is typed by sandbox super admin 1"
  echo "  from their own vault into the page only: never spoken, written, pasted or passed to this script."
  echo "  Add no user, app or Marketplace item during the setup tool's prompts."
  echo "VERIFY: Billing > Subscriptions shows the ordered edition and seats; Super Admin > View admins lists only SANDBOX_SA_1_EMAIL."
  echo "RECORD: <date>-SB-2.1-sandbox-subscription-v1; then: agp-platform done SB-2.1 --witness <second human>"
}

step SB-2.2 HUMAN "Verify the domain with a TXT record" --witness
s_SB_2_2_check() { ckpt_done SB-2.2; }
s_SB_2_2_manual() {
  echo "WHO: sandbox super admin 1 reads the value; sandbox super admin 2 adds the record."
  echo "WHERE: sandbox Admin console > Account > Domains > Manage domains > Verify domain; the DNS provider; the sandbox shell."
  echo "DO: TXT, host @ (or blank), the google-site-verification= value, TTL default; then Confirm on the page."
  echo "VERIFY: dig +short TXT \"\$SANDBOX_DOMAIN\" | grep -c 'google-site-verification=' prints 1; Manage domains shows it"
  echo "  primary and verified (up to 72 hours). The TXT record stays in DNS for good."
  echo "RECORD: <date>-SB-2.2-domain-verified-v1; then: agp-platform done SB-2.2 --witness <the other admin>"
}

step SB-2.3 HUMAN "Route mail with the MX record and activate Gmail" --witness
s_SB_2_3_check() { ckpt_done SB-2.3; }
s_SB_2_3_manual() {
  echo "WHO: sandbox super admin 2 edits DNS; sandbox super admin 1 activates Gmail."
  echo "WHERE: the DNS provider console; the sandbox Admin console (Activate Gmail)."
  echo "DO: remove every other MX record; add MX, host @, priority 1, value smtp.google.com; click Activate Gmail."
  echo "VERIFY: dig +short MX \"\$SANDBOX_DOMAIN\" prints exactly '1 smtp.google.com.'; a test mail from the second human's"
  echo "  organisation address reaches SANDBOX_SA_1_EMAIL (up to 72 hours)."
  echo "RECORD: <date>-SB-2.3-mx-v1 (header only, no body); then: agp-platform done SB-2.3 --witness <the other admin>"
}

step SB-2.4 HUMAN "Read the edition and the customer id" --witness
s_SB_2_4_check() { ckpt_done SB-2.4; }
s_SB_2_4_manual() {
  echo "WHO: sandbox super admin 1; sandbox super admin 2 re-reads on their own profile after SB-3.1."
  echo "WHERE: sandbox Admin console > Account > Account settings > Profile (Customer ID); Billing > Subscriptions; sandbox shell."
  echo "DO, in the SANDBOX copy: penv_set SANDBOX_CUSTOMER_ID \"<Customer ID from Account settings > Profile>\""
  echo "  printf '%s\\n' \"\$SANDBOX_CUSTOMER_ID\" | grep -Eq '^C[0-9A-Za-z]+\$' && echo \"form ok\""
  echo "VERIFY: form ok; the ordered edition. The value is provisional until SB-6.2's describe prints it."
  echo "  The platform owner's copy receives it only in SB-6.8."
  echo "RECORD: <date>-SB-2.4-customer-id-v1; then: agp-platform done SB-2.4 --witness <sandbox super admin 2>"
}

step SB-2.5 HUMAN "Create /Admins and enforce \"Only security key\" there"
s_SB_2_5_check() { ckpt_done SB-2.5; }
s_SB_2_5_manual() {
  echo "WHO: sandbox super admin 1."
  echo "WHERE: sandbox Admin console > Directory > Organizational units; Security > Authentication > 2-step verification, Admins selected."
  echo "DO: create OU Admins ('Sandbox super admins (21)'); on Admins: allow 2SV, Enforcement On, enrolment period at least"
  echo "  8 days, 'trust the device' unticked, Methods: Only security key, no security codes; Override."
  echo "VERIFY: /Admins exists and is empty; the 2SV page re-opened on Admins shows the values; the top OU is unchanged."
  echo "RECORD: <date>-SB-2.5-admins-ou-2sv-v1 (TISAX 4.1.2); then: agp-platform done SB-2.5"
}

step SB-2.6 HUMAN "Move the first super admin into /Admins, enrol two keys, remove recovery channels" --witness
s_SB_2_6_check() { ckpt_done SB-2.6; }
s_SB_2_6_manual() {
  echo "WHO: sandbox super admin 1; the second human witnesses each key and signs the custody record."
  echo "WHERE: myaccount.google.com/signinoptions/two-step-verification as SANDBOX_SA_1_EMAIL; Admin console > Directory > Users."
  echo "DO: keys first, enforcement second: turn on 2SV and add both labelled keys (label, never the serial); then change"
  echo "  the user's OU to /Admins; delete any recovery email and phone; sign the custody record (account, labels and"
  echo "  serials, holder, witness, date and time)."
  echo "VERIFY: OU /Admins, two security keys, no recovery information; a sign-in accepts each key in turn."
  echo "RECORD: <date>-custody-sandbox-sa-1-keys-v1 to the witness the same day (08 WO-3.3), E-08;"
  echo "  then: agp-platform done SB-2.6 --witness <second human>"
}

# ======================================================================== Part 3: the second super admin and custody

step SB-3.1 HUMAN "Create the second sandbox super admin and enrol their keys" --witness
s_SB_3_1_check() { ckpt_done SB-3.1; }
s_SB_3_1_manual() {
  echo "WHO: sandbox super admin 1 creates and assigns; sandbox super admin 2 sets their password and enrols; the second human witnesses."
  echo "WHERE: sandbox Admin console > Directory > Users > Add new user; Account > Admin roles > Super Admin; profile sandbox-sa-2."
  echo "DO: setup/21 SB-3.1: user SANDBOX_SA_2_EMAIL in /Admins, generated password, change at next sign-in, details not"
  echo "  emailed; admin 2 sets their own password from their vault (never through this script) and registers two keys;"
  echo "  assign Super Admin; remove any recovery email and phone."
  echo "VERIFY: View admins lists exactly the two sandbox super admins; /Admins, two keys, no recovery information."
  echo "RECORD: <date>-custody-sandbox-sa-2-keys-v1 to the witness the same day, E-08;"
  echo "  then: agp-platform done SB-3.1 --witness <second human>"
}

step SB-3.2 HUMAN "Session controls on /Admins"
s_SB_3_2_check() { ckpt_done SB-3.2; }
s_SB_3_2_manual() {
  echo "WHO: sandbox super admin 1."
  echo "WHERE: sandbox Admin console, Admins selected: Security > Access and data control > Google session control, and"
  echo "  Google Cloud session control."
  echo "DO: web session duration the shortest offered, Override; Cloud: Require reauthentication, every 1 hour, Security key,"
  echo "  'Exempt trusted apps' unticked, Override."
  echo "VERIFY: both pages re-opened on Admins show the values (up to 24 hours to apply)."
  echo "RECORD: <date>-SB-3.2-sessions-v1 (TISAX 4.1.2); then: agp-platform done SB-3.2"
}

step SB-3.3 HUMAN "Admin-generated backup codes, sealed with each spare key, cross-custodied" --witness
s_SB_3_3_check() { ckpt_done SB-3.3; }
s_SB_3_3_manual() {
  echo "WHO: for each account the OTHER sandbox super admin generates the codes; the holder and the second human witness."
  echo "WHERE: sandbox Admin console > Directory > Users > the user > Security > 2-Step Verification > Get backup verification codes."
  echo "DO: copy the codes by hand onto the inner sheet (never print, photograph, scan, type or paste them); seal the sheet"
  echo "  with the spare key in a tamper-evident envelope; the custodian is the other admin; envelope into the safe."
  echo "  The codes never pass through this script or any file."
  echo "VERIFY: two new envelopes in the safe log; each outer record carries two signatures."
  echo "RECORD: outer records only, <date>-custody-sandbox-sa-<n>-spare-v1, to the witness the same day, E-08;"
  echo "  then: agp-platform done SB-3.3 --witness <second human>"
}

step SB-3.4 HUMAN "Prove both sandbox super admin accounts" --witness
s_SB_3_4_check() { ckpt_done SB-3.4; }
s_SB_3_4_manual() {
  echo "WHO: each sandbox super admin on their own profile; the other watches."
  echo "WHERE: admin.google.com sign-in."
  echo "DO: each signs in with the primary key, opens Account > Admin roles, signs out; then once with the spare key under"
  echo "  the custodian's supervision (envelope opened, used and resealed as v2). No backup code is used."
  echo "VERIFY: four successful sign-ins on the sitting form, each with a key prompt and no code offered."
  echo "RECORD: <date>-SB-3.4-admins-proven-v1 and the v2 custody records, E-08;"
  echo "  then: agp-platform done SB-3.4 --witness <the other admin>"
}

step SB-3.5 HUMAN "Read the sandbox super-admin roster"
s_SB_3_5_check() { ckpt_done SB-3.5; }
s_SB_3_5_manual() {
  echo "WHO: sandbox super admin 2, on their own profile."
  echo "WHERE: sandbox Admin console > Account > Admin roles (each role > Admins); Directory > Users."
  echo "DO: export or screenshot every role's admins list; list all users."
  echo "VERIFY: Super Admin holds exactly the two sandbox super admins; no other role has an admin; the users are exactly"
  echo "  the two admins."
  echo "RECORD: <date>-SB-3.5-sandbox-roster-v1, E-08, TISAX 4.2.1 (nonprod Eve's first expected roster);"
  echo "  then: agp-platform done SB-3.5"
}

# ======================================================================== Part 4: directory content

step SB-4.1 HUMAN "Create the sandbox organisational units"
s_SB_4_1_check() { ckpt_done SB-4.1; }
s_SB_4_1_manual() {
  echo "WHO: sandbox super admin 1."
  echo "WHERE: sandbox Admin console > Directory > Organizational units."
  echo "DO: under the top OU: Synthetic ('Synthetic accounts, the only targets of twin tests (21, SD-35)'); Automation and,"
  echo "  under it, Service Identities ('Twin robots, created in 24 and 37'). Nothing is enforced there now."
  echo "VERIFY: /Admins, /Synthetic, /Automation/Service Identities, all empty except /Admins."
  echo "RECORD: <date>-SB-4.1-sandbox-ous-v1; then: agp-platform done SB-4.1"
}

step SB-4.2 HUMAN "Create the synthetic users" --witness
s_SB_4_2_check() { ckpt_done SB-4.2; }
s_SB_4_2_manual() {
  echo "WHO: sandbox super admin 1; sandbox super admin 2 checks names."
  echo "WHERE: sandbox Admin console > Directory > Users > Add new user; the sandbox shell."
  echo "DO: the number the order counted (synthetic-01@ to synthetic-04@ on SANDBOX_DOMAIN), each in /Synthetic, generated"
  echo "  password neither shown nor kept, no recovery information; then SB-4.2's block writes"
  echo "  \$BUILD_LOG_DIR/evidence/21/synthetic-users.txt on the sandbox workstation's build-log clone."
  echo "VERIFY: Users filtered on /Synthetic shows exactly the listed users, licensed; the file count matches."
  echo "RECORD: <date>-SB-4.2-synthetic-users-v1; then: agp-platform done SB-4.2 --witness <sandbox super admin 2>"
}

step SB-4.3 HUMAN "Create walle-operators@ on the sandbox domain as a security group" --witness --irreversible --gate "SD-25"
s_SB_4_3_check() { ckpt_done SB-4.3; }
s_SB_4_3_manual() {
  echo "IRREVERSIBLE for the Security label: a security group cannot be changed back to a Google Group."
  echo "WHO: sandbox super admin 1 creates; sandbox super admin 2 watches the save."
  echo "WHERE: sandbox Admin console > Directory > Groups > Create group."
  echo "CONFIRM before saving: the address is free; the spelling on screen is walle-operators@SANDBOX_DOMAIN; the members are"
  echo "  the two names of the signed PPL-SB1 and PPL-SB2 records."
  echo "DO: name walle-operators, no owner, label Security ticked, join by invitation only, no external members, post:"
  echo "  organisation members; members SANDBOX_SA_1_EMAIL and SANDBOX_SA_2_EMAIL only. In the SANDBOX copy:"
  echo "  penv_set SANDBOX_OPERATORS_GROUP \"walle-operators@\${SANDBOX_DOMAIN}\" (the platform owner's copy gets it in SB-6.8)."
  echo "RECORD: <date>-SB-4.3-sandbox-operators-group-v1, E-08; then: agp-platform done SB-4.3 --witness <sandbox super admin 2>"
}

# ======================================================================== Part 5: two-person controls in the tenant

step SB-5.1 HUMAN "Turn super-admin self-recovery Off at the top OU" --witness
s_SB_5_1_check() { ckpt_done SB-5.1; }
s_SB_5_1_manual() {
  echo "WHO: sandbox super admin 1; sandbox super admin 2 confirms."
  echo "WHERE: sandbox Admin console > Security > Authentication > Account recovery > Super admin account recovery."
  echo "DO: top OU: Off; Save. Select Admins, Synthetic and Service Identities in turn: each shows Inherited."
  echo "VERIFY: top OU Off, every child Inherited (Off); Admin log events show the change by SANDBOX_SA_1_EMAIL;"
  echo "  'Forgot password?' offers no self-recovery for either admin."
  echo "RECORD: <date>-SB-5.1-self-recovery-off-v1, E-08; then: agp-platform done SB-5.1 --witness <sandbox super admin 2>"
}

step SB-5.2 HUMAN "Turn multi-party approval On for every covered setting" --witness
s_SB_5_2_check() { ckpt_done SB-5.2; }
s_SB_5_2_manual() {
  echo "WHO: sandbox super admin 1; sandbox super admin 2 watches."
  echo "WHERE: sandbox Admin console > Security > Authentication > Multi-party approval settings."
  echo "DO: tick 'Require multi-party approval for sensitive actions'; select every setting category the page offers"
  echo "  (security settings, role assignment and custom role privileges, domains, calendar, groups, Vault, API-call"
  echo "  protections); Save; screenshot the full list."
  echo "VERIFY: re-opened, the box is ticked and every category selected; Admin log events show the change."
  echo "RECORD: <date>-SB-5.2-mpa-on-v1, E-08; then: agp-platform done SB-5.2 --witness <sandbox super admin 2>"
}

step SB-5.3 HUMAN "Exercise multi-party approval once (the 04 §8.4 test)" --witness --gate "SD-35"
s_SB_5_3_check() { ckpt_done SB-5.3; }
s_SB_5_3_manual() {
  echo "WHO: sandbox super admin 1 requests; sandbox super admin 2 approves or denies; each times and records."
  echo "WHERE: sandbox Admin console in each admin's own profile; Security > Authentication > Multi-party approval requests."
  echo "DO: setup/21 SB-5.3's six items: Help Desk Admin to synthetic-01@ approved (self-approval refused); its removal"
  echo "  (request? latency?); Super Admin to synthetic-02@ denied; multi-party approval off (request? minutes off?);"
  echo "  a 2SV change on /Synthetic denied; the Admin log event names."
  echo "VERIFY: six rows; items 1, 3 and 5 created requests (otherwise a stop and a finding against 04 §8.4); synthetic-02@"
  echo "  holds no role; multi-party approval On at the end."
  echo "RECORD: <date>-SB-5.3-mpa-test-v1 to the witness drills/ the same day, E-08, TISAX 4.2.1, 5.2.6;"
  echo "  then: agp-platform done SB-5.3 --witness <sandbox super admin 2>"
}

step SB-5.4 HUMAN "An activity rule on sandbox role and security changes" --witness
s_SB_5_4_check() { ckpt_done SB-5.4; }
s_SB_5_4_manual() {
  echo "WHO: sandbox super admin 1; sandbox super admin 2 receives the test mail."
  echo "WHERE: sandbox Admin console > Rules > Create rule > Activity."
  echo "DO: rule sandbox-admin-change on Admin log events, filtered on the event names SB-5.3 item 6 recorded; alert"
  echo "  center severity High; email both sandbox super admins (the second human is external and cannot be a recipient)."
  echo "VERIFY: admin 2 assigns then unassigns Help Desk Admin to synthetic-03@ (admin 1 approves); both admins receive the"
  echo "  mail; record the delay."
  echo "RECORD: <date>-SB-5.4-activity-rule-v1, E-08; then: agp-platform done SB-5.4 --witness <sandbox super admin 2>"
}

# ======================================================================== Part 6: the sandbox Cloud organisation

step SB-6.1 HUMAN "Accept the Google Cloud terms, which creates the sandbox organisation" --witness --irreversible --gate "SD-29"
s_SB_6_1_check() { ckpt_done SB-6.1; }
s_SB_6_1_manual() {
  echo "IRREVERSIBLE: the organisation resource stays bound to the sandbox account for its life."
  echo "WHO: sandbox super admin 1 signs in; the terms signer named in the order accepts (or delegated in writing);"
  echo "  sandbox super admin 2 watches."
  echo "WHERE: https://console.cloud.google.com in the sandbox-sa-1 profile (the avatar shows SANDBOX_SA_1_EMAIL)."
  echo "CONFIRM: SD-29 names the signer; SANDBOX_CUSTOMER_ID was read in SB-2.4; the profile is not a production account."
  echo "DO: read the terms with the signer; accept. Create no project and no billing account; close any setup checklist."
  echo "VERIFY: the resource picker shows an organisation named SANDBOX_DOMAIN."
  echo "RECORD: <date>-SB-6.1-cloud-terms-v1, E-03; then: agp-platform done SB-6.1 --witness <sandbox super admin 2>"
}

step SB-6.2 HUMAN "Record the sandbox organisation id and grant the second Organization Administrator" --witness
s_SB_6_2_check() { ckpt_done SB-6.2; }
s_SB_6_2_manual() {
  echo "WHO: sandbox super admin 1; sandbox super admin 2 watches."
  _sb_manual_sandbox
  echo "DO: SB-6.2's block of setup/21 as written: gcloud auth login SANDBOX_SA_1_EMAIL (a security key is asked),"
  echo "  organizations list, penv_set SANDBOX_ORG_ID in the SANDBOX copy, organizations describe, and"
  echo "  organizations add-iam-policy-binding for SANDBOX_SA_2_EMAIL as roles/resourcemanager.organizationAdmin."
  echo "VERIFY: one organisation, display name SANDBOX_DOMAIN; describe prints SANDBOX_CUSTOMER_ID and ACTIVE;"
  echo "  organizationAdmin holds exactly the two sandbox super admins."
  echo "RECORD: <date>-SB-6.2-sandbox-organisation-v1; then: agp-platform done SB-6.2 --witness <sandbox super admin 2>"
}

step SB-6.3 HUMAN "Remove the creation defaults and read the security baseline" --witness --removes
s_SB_6_3_check() { ckpt_done SB-6.3; }
s_SB_6_3_manual() {
  echo "WHO: sandbox super admin 1; sandbox super admin 2 watches."
  _sb_manual_sandbox
  echo "DO: SB-6.3's block of setup/21 as written: save the policy before; remove domain:SANDBOX_DOMAIN from"
  echo "  roles/resourcemanager.projectCreator and roles/billing.creator; add roles/logging.viewer for both sandbox super"
  echo "  admins; read the effective iam.allowedPolicyMemberDomains; projects list on the sandbox organisation."
  echo "VERIFY: no projectCreator or billing.creator binding; B5 admits only the sandbox customer; projects list empty."
  echo "RECORD: <date>-SB-6.3-sandbox-org-iam-v1 (before and after JSON); then: agp-platform done SB-6.3 --witness <sandbox super admin 2>"
}

step SB-6.4 HUMAN "Turn on \"Share data with Google Cloud services\" in the sandbox" --witness
s_SB_6_4_check() { ckpt_done SB-6.4; }
s_SB_6_4_manual() {
  echo "WHO: sandbox super admin 1 (super administrator only); sandbox super admin 2 watches."
  echo "WHERE: sandbox Admin console > Account > Account settings > Legal and compliance > Sharing options."
  echo "DO: screenshot the current state; select Enabled; Save; write the UTC time in the build log (nonprod Eve's feed"
  echo "  starts from it); record which event families the edition shares."
  echo "VERIFY: Enabled after reload; Admin log events show the change with actor and time."
  echo "RECORD: <date>-SB-6.4-sandbox-sharing-v1, E-06; then: agp-platform done SB-6.4 --witness <sandbox super admin 2>"
}

step SB-6.5 HUMAN "See Admin and login events at sandbox organisation scope"
s_SB_6_5_check() { ckpt_done SB-6.5; }
s_SB_6_5_manual() {
  echo "WHO: sandbox super admin 2, on their own workstation and profile."
  echo "WHERE: Logs Explorer with the sandbox ORGANISATION selected in the resource picker; optionally the sandbox shell."
  echo "DO: up to 24 hours after SB-6.4 and one harmless change by admin 1, run, last 2 days:"
  echo "  protoPayload.serviceName=\"admin.googleapis.com\" and protoPayload.serviceName=\"login.googleapis.com\"."
  echo "  The shell read of SB-6.5 is optional; a quota-project refusal is an expected, recorded outcome: never retry with"
  echo "  --billing-project, never create a project, never ask for a platform grant."
  echo "VERIFY: the /Synthetic change and the sign-in appear (the X-ORG-02 proof); else read SB-6.5's table."
  echo "RECORD: <date>-SB-6.5-sandbox-events-at-org-v1, E-06; then: agp-platform done SB-6.5"
}

step SB-6.6 HUMAN "Read the sandbox API controls and record the twin OAuth client rule" --witness --gate "SD-05"
s_SB_6_6_check() { ckpt_done SB-6.6; }
s_SB_6_6_manual() {
  echo "WHO: sandbox super admin 1 reads; the platform owner writes the rule into SB-8.2's file."
  echo "WHERE: sandbox Admin console > Security > Access and data control > API controls; Manage Third-Party App Access; Settings."
  echo "DO: screenshot the configured apps (expected empty) and the unconfigured-apps setting; change nothing."
  echo "  The five rule lines of SB-6.6 (External, In production never Testing, Trusted before consent; production"
  echo "  Internal; org_internal not reproduced; custom IAP credentials) go into sandbox/sandbox.yaml in SB-8.2."
  echo "RECORD: <date>-SB-6.6-sandbox-api-controls-v1; then: agp-platform done SB-6.6 --witness <sandbox super admin 1>"
}

step SB-6.7 HUMAN "Decide the sandbox SecOps export"
s_SB_6_7_check() { ckpt_done SB-6.7; }
s_SB_6_7_manual() {
  echo "WHO: IT security (SIEM owner) decides; a sandbox super administrator performs 15 PS-8.8 only if the answer is yes."
  echo "WHERE: a short record for the SB-8.2 pull request; if yes, the sandbox Admin console as 15 PS-8.8."
  echo "DO: IT security answers 'live sandbox fixtures wanted: yes or no'. If yes, a sandbox super administrator connects"
  echo "  the export with SANDBOX_CUSTOMER_ID and IT security's token (never through this script) 24 hours before any"
  echo "  capture; twin accounts go into agp_twin_accounts tagged env=nonprod. If no, nothing is connected."
  echo "VERIFY: answer, date and decider in sandbox/sandbox.yaml (secops_export); if yes, PS-8.8's VERIFY is DONE."
  echo "RECORD: the record (and <date>-PS-8.8-sandbox-export-v1 if connected); then: agp-platform done SB-6.7"
}

step SB-6.8 HUMAN "Hand the identifiers over to the tenant copy" --witness \
  --needs "DIRECTORY_CUSTOMER_ID ORG_ID DOMAIN" --sets "SANDBOX_CUSTOMER_ID SANDBOX_ORG_ID SANDBOX_OPERATORS_GROUP"
s_SB_6_8_check() { ckpt_done SB-6.8; }   # a value it did not set shows as MISSING at SB-7.1
s_SB_6_8_manual() {
  echo "WHO: sandbox super admin 1 reads the values out from their screen; the platform owner types them; the second human"
  echo "  compares them with SB-2.4's, SB-4.3's and SB-6.2's evidence."
  echo "WHERE: the platform owner's shell, ~/.platform-env sourced."
  echo "DO: penv_set SANDBOX_CUSTOMER_ID \"<from SB-2.4>\"; penv_set SANDBOX_ORG_ID \"<from SB-6.2>\";"
  echo "  penv_set SANDBOX_OPERATORS_GROUP \"<from SB-4.3>\"; then SB-6.8's two checks."
  echo "VERIFY: 'distinct from production' and 'sandbox group'; the second human signs that the values equal the evidence."
  echo "  SANDBOX_ORG_ID is used only inside twin_shell --sandbox-org (01)."
  echo "RECORD: build-log line SB-6.8; then: agp-platform done SB-6.8 --witness <second human>"
}

# ======================================================================== Part 7: B5 on the nonprod folders

_sb_7_1_reads() {   # S: the effective B5 of the nine folders and the policy files in the repository
  local S="$1" F j vals want rel
  want="$(_sb_want "$(v DIRECTORY_CUSTOMER_ID)")"
  for F in $SB_FLD_ALL; do
    j="$(r gcloud org-policies describe iam.allowedPolicyMemberDomains --folder="$(v "$F")" --effective --format=json 2>&1)" \
      || { echo "FAIL $F: the effective read failed: $(printf '%s' "$j" | head -n 1)"; continue; }
    printf '%s\n' "$j" | xw "$S/$F.effective.json" 600 >/dev/null || echo "FAIL $F: could not write $S/$F.effective.json"
    vals="$(printf '%s' "$j" | _sb_vals 2>/dev/null)"
    echo "$F ${vals:-?}"
    case "$vals" in
      no-spec) echo "$F: the effective reply holds no spec; the attachment points below decide";;
      "$want") ;;
      *) echo "FAIL $F: effective B5 is ${vals:-unreadable}, not [\"$(v DIRECTORY_CUSTOMER_ID)\"]";;
    esac
  done
  _sb_b5_own before
  for rel in "$(_sb_repo)"/policies/org/*/iam.allowedPolicyMemberDomains.json; do
    [ -e "$rel" ] || continue
    echo "${rel#"$(_sb_repo)"/}"
    case "$rel" in */policies/org/FLD_AGENTIC_PLATFORM/*) ;; *) echo "FAIL ${rel#"$(_sb_repo)"/} exists: 13 OP-6.5 removed every nonprod copy";; esac
  done
  [ -f "$(_sb_repo)/policies/org/FLD_AGENTIC_PLATFORM/iam.allowedPolicyMemberDomains.json" ] \
    || echo "FAIL policies/org/FLD_AGENTIC_PLATFORM/iam.allowedPolicyMemberDomains.json is missing (13)"
  (cd "$S" && shasum -a 256 ./*.effective.json 2>/dev/null)   # the page's last line: one registered hash covers the directory
}

step SB-7.1 AUTO-READ "Gates and the effective member constraint on every affected folder" \
  --needs "SA_1_ADMIN ORG_ID DIRECTORY_CUSTOMER_ID SANDBOX_CUSTOMER_ID CICD_PROJECT CORE_PROJECT ENT_PLATFORM_POLICY ENT_FOLDER_ADMIN PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER $SB_FLD_ALL"
s_SB_7_1_check() { ckpt_done SB-7.1; }
s_SB_7_1_apply() {
  local S out acct F
  S="$(_sb_ev)/SB-7.1"
  x checkpoint SB-7.1 START || return 1
  x mkdir -p "$S" || return 1
  if [ "$AGP_MODE" != apply ]; then
    _sb_plan "penv_guard; the active account is SA_1_ADMIN (sign in first: gcloud auth login, at the sitting's start)"
    for F in $SB_FLD_ALL; do
      _sb_plan "$(agp_quote gcloud org-policies describe iam.allowedPolicyMemberDomains --folder="$(v "$F")" --effective --format=json) > SB-7.1/$F.effective.json"
    done
    _sb_plan "each folder must print [\"$(v DIRECTORY_CUSTOMER_ID)\"] alone; policies/org/ holds only FLD_AGENTIC_PLATFORM's B5 file"
    _sb_plan "and the attachment points (gcloud org-policies list --folder=<id> --filter=...): only fld-agentic-platform holds B5, with DIRECTORY_CUSTOMER_ID"
    ev SB-7.1 b5-before - 5.2.2 "build-log:evidence/21/SB-7.1/summary.txt"
    return 0
  fi
  penv_guard >/dev/null 2>&1 || { _sb_say "FAIL penv_guard: read its output in a sourced shell"; return 1; }
  acct="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)"
  [ "$acct" = "$(v SA_1_ADMIN)" ] || { _sb_say "STOP: signed in as '${acct:-nobody}', not SA_1_ADMIN: gcloud auth login \"\$SA_1_ADMIN\" --no-launch-browser"; return 1; }
  out="$(_sb_7_1_reads "$S")"
  printf '%s\n' "$out" | sed 's/^/        /' >&3
  printf '%s\n' "$out" | xw "$S/summary.txt" 600 || return 1
  ev SB-7.1 b5-before - 5.2.2 "build-log:evidence/21/SB-7.1/summary.txt" "$S/summary.txt" || return 1
  if printf '%s\n' "$out" | grep -q '^FAIL'; then _sb_say "13's state is not what this file builds on: stop (setup/21 SB-7.1 VERIFY)"; return 1; fi
  return 0
}

step SB-7.2 HUMAN "Decide whether fld-improvers-nonprod joins" --witness --gate "SD-25"
s_SB_7_2_check() { ckpt_done SB-7.2; }
s_SB_7_2_manual() {
  echo "WHO: platform owner with the Mo owner (the witness), who signs."
  echo "WHERE: 22's records (MO_TWIN_PROJECT, the P40 answer) and Mo's design (mo/01-hld.md)."
  echo "DO: SD-25 admits the sandbox customer on fld-improvers-nonprod only if Mo reads sandbox data. Write"
  echo "  improvers_nonprod_admits_sandbox: true|false with the reason and the Mo owner's name for SB-8.2."
  echo "  Default when 22 has not run or MO_TWIN_PROJECT is *tbd*: false, with SB-9.1's re-run line."
  echo "RECORD: <date>-SB-7.2-improvers-decision-v1 (E-03); then, so SB-7.3 and SB-7.4 read the answer:"
  echo "  agp-platform done SB-7.2 --witness <Mo owner> --note \"improvers_nonprod_admits_sandbox=false\"   (or =true)"
}

_sb_on_main() {     # REL: the file exists on HEAD of the local main branch
  git -C "$(_sb_repo)" cat-file -e "main:$1" 2>/dev/null
}

# SB-7.3 is HUMAN: its VERIFY is a pull request merged with the second human's approval (and the security
# reviewer's, where appointed), and its block pushes to the git host and runs gh, for which the offline tests
# have no fake (phase 03 follows the same rule for git-host steps). The person runs the page's block; SB-7.4
# reads the merged files on main and stops until they are there.
step SB-7.3 HUMAN "Write the B5 child policies and merge them" --witness --gate "SD-25" \
  --needs "PLATFORM_REPO_DIR SANDBOX_CUSTOMER_ID FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_NONPROD"
s_SB_7_3_check() { ckpt_done SB-7.3; }
s_SB_7_3_manual() {
  local T
  echo "WHO: platform owner writes; the second human (and the security reviewer, if appointed) review as code owners of policies/."
  echo "WHERE: PLATFORM_REPO_DIR ($(_sb_repo)), branch $SB_B5_BRANCH."
  echo "DO: SB-7.3's block of setup/21 as written: switch main, pull --ff-only, switch -c $SB_B5_BRANCH; pol() for each target:"
  for T in $(_sb_targets); do echo "    policies/org/$T/iam.allowedPolicyMemberDomains.json  (folders/$(v "$T"), inheritFromParent true, + $(v SANDBOX_CUSTOMER_ID))"; done
  _sb_improvers || echo "  FLD_IMPROVERS_NONPROD is not a target: SB-7.2 was not recorded with improvers_nonprod_admits_sandbox=true."
  echo "  then jq -e (json-ok), git add policies/org, commit, push -u origin $SB_B5_BRANCH, gh pr create (the page's title and body)."
  echo "VERIFY: json-ok; the pull request merged with the second human's approval; git show --stat on the merge commit lists"
  echo "  $(_sb_targets | wc -w | tr -d ' ') files and no production folder."
  echo "RECORD: the merge commit id in the build log (TISAX 5.2.1, 5.2.2); then: agp-platform done SB-7.3 --witness <second human>"
}

# SB-7.4 is done when every target folder carries its own B5 policy: SB-7.1 proved that none did before (13
# OP-6.5 left B5 at fld-agentic-platform only), so a folder-level policy there is this step's. Its content
# (both customer ids in the effective value) is the VERIFY at the end of _apply, and SB-7.5 proves it.
# Every target is read, none skipped after a first miss: 0 all, 1 one is missing, 2 an error, 3 offline.
_sb_7_4_applied() {
  local T rc worst=0
  for T in $(_sb_targets); do
    exists gcloud org-policies describe iam.allowedPolicyMemberDomains --folder="$(v "$T")" --format='value(name)'; rc=$?
    case $rc in 0) ;; 1) [ $worst = 0 ] && worst=1;; *) worst=$rc;; esac
  done
  return $worst
}
step SB-7.4 AUTO "Apply the child policies under ENT_PLATFORM_POLICY" --witness --removes \
  --needs "ENT_PLATFORM_POLICY CICD_PROJECT CORE_PROJECT SANDBOX_CUSTOMER_ID DIRECTORY_CUSTOMER_ID PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER FLD_AGENTIC_PLATFORM $SB_FLD_READ"
s_SB_7_4_check() { _sb_7_4_applied; }
s_SB_7_4_apply() {
  local repo T sha out want1 want2 got bad=0 S
  repo="$(_sb_repo)"; S="$(_sb_ev)"
  x checkpoint SB-7.4 START || return 1
  x git -C "$repo" switch main || return 1
  _sb_pull "$repo" || return 1
  if [ "$AGP_MODE" = apply ]; then
    for T in $(_sb_targets); do
      _sb_on_main "policies/org/$T/iam.allowedPolicyMemberDomains.json" \
        || { _sb_say "STOP: policies/org/$T/iam.allowedPolicyMemberDomains.json is not on main: SB-7.3's pull request is not merged"; return 1; }
    done
    [ -x "$repo/policies/tools/op-set.sh" ] || { _sb_say "STOP: policies/tools/op-set.sh is missing (13 OP-0.3)"; return 1; }
    sha="$(git -C "$repo" log -n 1 --format=%h -- policies/org)"
  else
    _sb_plan "each target file is on main (SB-7.3's pull request merged); policies/tools/op-set.sh exists (13 OP-0.3)"
    sha="<merge commit>"
  fi
  _sb_grant ENT_PLATFORM_POLICY 3600 "setup 21 SB-7.4 B5 child policies merged at $sha (SB-7.3)" || return 1
  for T in $(_sb_targets); do
    x "$repo/policies/tools/op-set.sh" "$repo/policies/org/$T/iam.allowedPolicyMemberDomains.json" \
      || { _sb_say "STOP at $T (op-set.sh: 2 refused, 3 READBACK-DIFF: read the diff and roll back from the predecessor, 4 predecessor unreadable)"; return 1; }
  done
  if [ "$AGP_MODE" != apply ]; then
    _sb_say "waits 900 s: Google's propagation time for organisation policy changes"
    for T in $SB_FLD_READ; do _sb_plan "$(agp_quote gcloud org-policies describe iam.allowedPolicyMemberDomains --folder="$(v "$T")" --effective --format=json)"; done
    _sb_plan "both customer ids on each target; only DIRECTORY_CUSTOMER_ID on every production folder and non-target"
    _sb_plan "and the attachment points (gcloud org-policies list --folder=<id> --filter=...): fld-agentic-platform's B5 lists DIRECTORY_CUSTOMER_ID"
    _sb_plan "  and not the sandbox customer; each target's own B5 merges with the parent and lists SANDBOX_CUSTOMER_ID; no other folder holds one"
    _sb_plan "$(agp_quote gcloud pam grants describe "$SB_GRANT" --billing-project="$(v CICD_PROJECT)" --format=json) > SB-7.4-grant.json; its SHA-256 ends SB-7.4-effective.txt"
    ev SB-7.4 b5-sandbox-applied - "5.2.1, 5.2.2" "build-log:evidence/21/SB-7.4-effective.txt"
    _sb_say "when the VERIFY passes (SB-7.5 requests its own ENT_FOLDER_ADMIN; on a failure the grant is kept for the ROLLBACK):"
    _sb_revoke "$SB_GRANT" "setup 21 SB-7.4 done"
    return 0
  fi
  _sb_say "waiting 900 s for organisation policy propagation (times AGP_WAIT_SCALE, when set)"
  _sb_sleep 900
  want1="$(_sb_want "$(v DIRECTORY_CUSTOMER_ID)")"; want2="$(_sb_want "$(v DIRECTORY_CUSTOMER_ID)" "$(v SANDBOX_CUSTOMER_ID)")"
  out=""
  for T in $SB_FLD_READ; do
    got="$(_sb_eff "$T")" || got="unreadable"
    out="$out$T $got
"
    if [ "$got" = no-spec ]; then out="${out}$T: the effective reply holds no spec; the attachment points below decide
"; continue; fi
    case " $(_sb_targets) " in
      *" $T "*) [ "$got" = "$want2" ] || { out="${out}FAIL $T should admit both customers
"; bad=1; };;
      *) [ "$got" = "$want1" ] || { out="${out}FAIL $T should admit DIRECTORY_CUSTOMER_ID only
"; bad=1; };;
    esac
  done
  got="$(_sb_b5_own after)"
  out="$out$got
"
  printf '%s\n' "$got" | grep -q '^FAIL' && bad=1
  printf '%s' "$out" | sed 's/^/        /' >&3
  r gcloud pam grants describe "$SB_GRANT" --billing-project="$(v CICD_PROJECT)" --format=json | xw "$S/SB-7.4-grant.json" 600 || return 1
  out="$out$(cd "$S" && shasum -a 256 SB-7.4-grant.json)
"
  printf '%s' "$out" | xw "$S/SB-7.4-effective.txt" 600 || return 1
  ev SB-7.4 b5-sandbox-applied - "5.2.1, 5.2.2" "build-log:evidence/21/SB-7.4-effective.txt" "$S/SB-7.4-effective.txt" || return 1
  _sb_say "The predecessors are under policies/predecessors/<date>/ (op-set.sh)."
  if [ $bad != 0 ]; then
    _sb_say "ROLLBACK, under this grant (kept active for it), then revoke it and stop (the predecessor was none, SB-7.1):"
    for T in $(_sb_targets); do _sb_say "  gcloud org-policies delete iam.allowedPolicyMemberDomains --folder=$(v "$T")"; done
    _sb_say "  gcloud pam grants revoke $SB_GRANT --reason=\"setup 21 SB-7.4 rolled back\" --billing-project=$(v CICD_PROJECT)"
    return 1
  fi
  _sb_say "the VERIFY passed: the grant is revoked now (SB-7.5 requests its own ENT_FOLDER_ADMIN)"
  _sb_revoke "$SB_GRANT" "setup 21 SB-7.4 done" \
    || _sb_say "the revocation failed: revoke $SB_GRANT by hand before SB-7.5 (the policies are applied and recorded)"
  return 0
}

_sb_sandbox_members() {     # FOLDER_VAR: how many members of its IAM policy are on SANDBOX_DOMAIN
  r gcloud resource-manager folders get-iam-policy "$(v "$1")" --format=json 2>/dev/null | _sb_py 'import json,sys
d=sys.argv[1]
try:
    p=json.load(sys.stdin)
except ValueError:
    print("?"); sys.exit(0)
print(sum(1 for b in p.get("bindings", []) for m in b.get("members", []) if d in m))' "$(v SANDBOX_DOMAIN)"
}

step SB-7.5 AUTO "Prove admission on the nonprod folders and refusal on their production siblings" --witness --removes \
  --needs "ENT_FOLDER_ADMIN CICD_PROJECT SANDBOX_SA_1_EMAIL SANDBOX_OPERATORS_GROUP SANDBOX_DOMAIN PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_NONPROD FLD_AGENTS_P_PROD FLD_AGENTS_P_SA_PROD FLD_CONTROLLERS_PROD"
# Done when the proof passed, or when a person recorded the step after the page's own STOP was resolved.
s_SB_7_5_check() { ckpt_done SB-7.5 || { [ -f "$(_sb_ev)/SB-7.5/result.txt" ] && grep -q '^RESULT PASS' "$(_sb_ev)/SB-7.5/result.txt"; }; }
s_SB_7_5_apply() {
  local E pair NV PV N P rc out="" bad=0 m F n acc=0 nref=0
  E="$(_sb_ev)/SB-7.5"; m="user:$(v SANDBOX_SA_1_EMAIL)"
  x checkpoint SB-7.5 START || return 1
  _sb_say "sandbox super admin 1 has been told their account is the test member (Browser on an empty folder, removed at once)"
  _sb_grant ENT_FOLDER_ADMIN 3600 "setup 21 SB-7.5 SD-25 admission proof" || return 1
  x mkdir -p "$E" || return 1
  _sb_say "each production attempt below must be refused; an error printed there is the expected result"
  # Every add and remove names --condition=None: their output goes to a file, so a condition prompt from
  # gcloud (a folder whose policy holds conditional bindings) would be invisible and the run would seem to hang.
  for pair in $SB_PAIRS; do
    NV="${pair%%:*}"; PV="${pair##*:}"; N="$(v "$NV")"; P="$(v "$PV")"
    _sb_xto "$E/$NV.accept.txt" gcloud resource-manager folders add-iam-policy-binding "$N" --member="$m" --role=roles/browser --condition=None
    rc=$?; out="$out$NV accept exit $rc
"; [ $rc = 0 ] || { bad=1; nref=1; }
    _sb_xto "$E/$NV.remove.txt" gcloud resource-manager folders remove-iam-policy-binding "$N" --member="$m" --role=roles/browser --condition=None
    rc=$?; out="$out$NV remove exit $rc
"; [ $rc = 0 ] || bad=1
    _sb_xto "$E/$PV.refuse.txt" gcloud resource-manager folders add-iam-policy-binding "$P" --member="$m" --role=roles/browser --condition=None
    rc=$?; out="$out$PV refuse exit $rc
"
    if [ "$AGP_MODE" = apply ] && [ $rc = 0 ]; then
      bad=1; acc=1; out="${out}SEVERITY 1: the grant on $PV was ACCEPTED; removed at once, under the same grant
"
      x gcloud resource-manager folders remove-iam-policy-binding "$P" --member="$m" --role=roles/browser --condition=None
    fi
  done
  _sb_xto "$E/group.accept.txt" gcloud resource-manager folders add-iam-policy-binding "$(v FLD_AGENTS_P_SA_NONPROD)" \
    --member="group:$(v SANDBOX_OPERATORS_GROUP)" --role=roles/browser --condition=None
  rc=$?; out="${out}group accept exit $rc
"; [ $rc = 0 ] || { bad=1; nref=1; }
  _sb_xto "$E/group.remove.txt" gcloud resource-manager folders remove-iam-policy-binding "$(v FLD_AGENTS_P_SA_NONPROD)" \
    --member="group:$(v SANDBOX_OPERATORS_GROUP)" --role=roles/browser --condition=None
  rc=$?; out="${out}group remove exit $rc
"; [ $rc = 0 ] || bad=1
  if [ "$AGP_MODE" != apply ]; then
    _sb_plan "each accept and remove exits 0; each refuse exits non-zero with \"$SB_REFUSAL\"; then get-iam-policy on the six folders shows no SANDBOX_DOMAIN member"
    _sb_plan "$(agp_quote gcloud pam grants describe "$SB_GRANT" --billing-project="$(v CICD_PROJECT)" --format=json) > SB-7.5/grant.json; result.txt ends with the SHA-256 of every file"
    _sb_revoke "$SB_GRANT" "setup 21 SB-7.5 admission proof complete"
    ev SB-7.5 b5-admission-proof E-08 "4.1.3, 5.2.2" "build-log:evidence/21/SB-7.5/result.txt"
    return 0
  fi
  n="$(grep -l "$SB_REFUSAL" "$E"/*.refuse.txt 2>/dev/null | wc -l | tr -d ' ')"
  out="${out}refusals with the permitted-customer message: $n of 3
"; [ "$n" = 3 ] || bad=1
  for F in FLD_AGENTS_P_NONPROD FLD_AGENTS_P_SA_NONPROD FLD_CONTROLLERS_NONPROD FLD_AGENTS_P_PROD FLD_AGENTS_P_SA_PROD FLD_CONTROLLERS_PROD; do
    n="$(_sb_sandbox_members "$F")"
    out="$out$F sandbox members ${n:-?}
"; [ "$n" = 0 ] || bad=1
  done
  r gcloud pam grants describe "$SB_GRANT" --billing-project="$(v CICD_PROJECT)" --format=json | xw "$E/grant.json" 600 || bad=1
  out="$out$(cd "$E" && shasum -a 256 ./*.accept.txt ./*.remove.txt ./*.refuse.txt ./grant.json 2>/dev/null)
"
  _sb_revoke "$SB_GRANT" "setup 21 SB-7.5 admission proof complete" || bad=1
  if [ $bad = 0 ]; then out="${out}RESULT PASS
"; else out="${out}RESULT FAIL
"; fi
  printf '%s' "$out" | sed 's/^/        /' >&3
  printf '%s' "$out" | xw "$E/result.txt" 600 || return 1
  ev SB-7.5 b5-admission-proof E-08 "4.1.3, 5.2.2" "build-log:evidence/21/SB-7.5/result.txt" "$E/result.txt" || return 1
  if [ $acc = 1 ]; then   # the page's own STOP ("If something goes wrong"): a person acts before anything else
    _sb_say "STOP: a grant on a production folder was ACCEPTED (removed above, under the same grant). Severity 1 to the"
    _sb_say "  incident commander; re-read B5 at fld-agentic-platform and roll back Part 7 (setup/21, If something goes wrong)."
    _sb_say "  When resolved and the proof passes: agp-platform done SB-7.5 --witness <second human>"
    return 98
  fi
  if [ $nref = 1 ]; then
    _sb_say "STOP: a sandbox grant on a nonprod folder was refused. Read its effective policy: if SANDBOX_CUSTOMER_ID is absent,"
    _sb_say "  re-run SB-7.4; if present and still refused, stop and open an SD-25 amendment (setup/21, If something goes wrong)."
    return 98
  fi
  return $bad
}

step SB-7.6 BLOCKED "Add the sandbox folder values and identifiers to the drift inventory (BLOCKED)" --note "B-02: the drift job code"
s_SB_7_6_check() { ckpt_done SB-7.6; }
s_SB_7_6_manual() {
  echo "BLOCKED on B-02: the drift job does not exist (16, DRIFT_JOB). The run writes the BLOCKED checkpoint and continues."
  echo "Until then: the README BLOCKED index row and the quarterly manual read in DRILL_CALENDAR (SB-9.1)."
  echo "When unblocked: B5 effective values on the nine folders of SB-7.1, no sandbox-domain member in production, and the"
  echo "  sandbox sinks of 24 and 37 by name, in the drift job's expected state."
}

# ======================================================================== Part 8: names, the contract file, the nonprod rows

s_SB_8_1_check() {
  local t w e
  has_value WALLE_TWIN_PROJECT && has_value EVE_TWIN_PROJECT || return 1
  t="$(agp_tool decision-value.sh)"
  [ -x "$t" ] || return 0
  [ "$AGP_OFFLINE" = 1 ] && return 3
  w="$("$t" NAMES WALLE_TWIN_PROJECT 2>/dev/null)"; e="$("$t" NAMES EVE_TWIN_PROJECT 2>/dev/null)"
  [ "$w" = "$(v WALLE_TWIN_PROJECT)" ] && [ "$e" = "$(v EVE_TWIN_PROJECT)" ]
}
step SB-8.1 AUTO "Reserve the twin project ids" --gate "NAMES" --needs "PLATFORM_REPO_DIR EVIDENCE_REGISTER BUILD_LOG_DIR" \
  --sets "WALLE_TWIN_PROJECT EVE_TWIN_PROJECT"
s_SB_8_1_apply() {
  local t w e n id c f
  t="$(agp_tool decision-value.sh)"
  x checkpoint SB-8.1 START || return 1
  if [ "$AGP_MODE" != apply ]; then
    _sb_plan "tools/decision-value.sh NAMES WALLE_TWIN_PROJECT and NAMES EVE_TWIN_PROJECT; each 6 to 30 characters, [a-z][a-z0-9-]*[a-z0-9]; distinct from each other and from WALLE_PROJECT and EVE_PROJECT"
    pset WALLE_TWIN_PROJECT "<from NAMES>"; pset EVE_TWIN_PROJECT "<from NAMES>"
    ev SB-8.1 twin-project-ids E-05 1.3.1 "build-log:evidence/21/SB-8.1-twin-project-ids.txt"
    return 0
  fi
  [ -x "$t" ] || { _sb_say "STOP: $t is not installed (03 DC-1.2)"; return 1; }
  w="$("$t" NAMES WALLE_TWIN_PROJECT)" || { _sb_say "STOP: no signed WALLE_TWIN_PROJECT in NAMES"; return 1; }
  e="$("$t" NAMES EVE_TWIN_PROJECT)" || { _sb_say "STOP: no signed EVE_TWIN_PROJECT in NAMES"; return 1; }
  for n in "WALLE_TWIN_PROJECT:$w" "EVE_TWIN_PROJECT:$e"; do
    id="${n#*:}"
    printf '%s\n' "$id" | grep -Eq '^[a-z][a-z0-9-]{4,28}[a-z0-9]$' && _sb_say "${n%%:*} form ok" \
      || { _sb_say "STOP: ${n%%:*}=$id is not a well-formed project id"; return 1; }
  done
  [ "$w" != "$(_penv_get WALLE_PROJECT || true)" ] && [ "$e" != "$(_penv_get EVE_PROJECT || true)" ] && [ "$w" != "$e" ] \
    || { _sb_say "STOP: the twin ids are not distinct from each other and from the production ids"; return 1; }
  _sb_say "distinct"
  pset WALLE_TWIN_PROJECT "$w" || return 1
  pset EVE_TWIN_PROJECT "$e" || return 1
  # The page's evidence is a build-log line naming the names record commit; it is kept as a small file so that the
  # register row carries a SHA-256 (42 GD-4.1 lists a file-shaped location without one as a gap).
  c="$(git -C "$(_sb_repo)" log -n 1 --format=%h -- decisions 2>/dev/null)"
  f="$(_sb_ev)/SB-8.1-twin-project-ids.txt"
  x mkdir -p "$(_sb_ev)" || return 1
  printf 'WALLE_TWIN_PROJECT %s\nEVE_TWIN_PROJECT %s\nnames record: repo:decisions@%s\n' "$w" "$e" "${c:-unknown}" | xw "$f" 600 || return 1
  ev SB-8.1 twin-project-ids E-05 1.3.1 "build-log:evidence/21/${f##*/}" "$f"
}

step SB-8.2 HUMAN "Commit the sandbox contract file" --witness --needs "PLATFORM_REPO_DIR"
s_SB_8_2_check() { ckpt_done SB-8.2; }
s_SB_8_2_manual() {
  echo "WHO: platform owner writes; the second human is required reviewer; sandbox super admin 2 confirms the tenant facts."
  echo "WHERE: PLATFORM_REPO_DIR, branch sb-8-2-sandbox."
  echo "DO: run SB-8.2's block of setup/21 as written (the sandbox/sandbox.yaml here-document, the CODEOWNERS line from"
  echo "  identity/git-humans.yaml with yq: @login, never an email); replace every <...> from the records it names;"
  echo "  commit, push, open the pull request."
  echo "VERIFY: grep -n '<' sandbox/sandbox.yaml prints nothing; yq -e . sandbox/sandbox.yaml prints JSON (yaml-ok);"
  echo "  gh api repos/\$PLATFORM_REPO_SLUG/codeowners/errors?ref=sb-8-2-sandbox --jq .errors prints []; merged with the"
  echo "  second human's approval; sandbox super admin 2 comments 'tenant facts confirmed'."
  echo "RECORD: the merge commit (E-05); then: agp-platform done SB-8.2 --witness <second human>"
}

step SB-8.3 HUMAN "Prepare the env=nonprod register rows for the Eve and Wall-E twins" --witness --gate "SD-02 SD-25" \
  --needs "PLATFORM_REPO_DIR WALLE_TWIN_PROJECT EVE_TWIN_PROJECT SANDBOX_CUSTOMER_ID SANDBOX_OPERATORS_GROUP DOMAIN"
s_SB_8_3_check() { ckpt_done SB-8.3; }
s_SB_8_3_manual() {
  echo "WHO: platform owner writes; the second human reviews."
  echo "WHERE: PLATFORM_REPO_DIR, branch sb-8-3-nonprod-rows, pushed with a DRAFT pull request (never merged here)."
  echo "DO: run SB-8.3's block of setup/21 as written: register/drafts/eve.nonprod.yaml and walle.nonprod.yaml, values not"
  echo "  yet known left as '# 23' or '# 31' comments, never invented; commit; push; gh pr create --draft."
  echo "VERIFY: grep -c gate_checklist register/drafts/*.nonprod.yaml prints 0 for both; the draft exists and is not merged."
  echo "RECORD: the branch head commit (E-05); then: agp-platform done SB-8.3 --witness <second human>"
}

step SB-8.4 HUMAN "Check the twin rows against R-02 and R-04 and sign the manual parse" --witness --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR"
s_SB_8_4_check() { ckpt_done SB-8.4; }
s_SB_8_4_manual() {
  echo "WHO: platform owner runs; the second human and the security reviewer (if appointed) sign the parse."
  echo "WHERE: shell, PLATFORM_REPO_DIR on branch sb-8-3-nonprod-rows."
  echo "DO: run SB-8.4's block of setup/21 as written (yq wraps each draft into a one-row agent file, check-jsonschema"
  echo "  validates, the outputs go to \$BUILD_LOG_DIR/evidence/21/). No Ruby fallback: if yq is missing, install it."
  echo "  Then 16 RG-3.6's manual parse answers R-02, R-04, P1 and the list of remaining missing fields, in writing."
  echo "VERIFY: two 'wrapper ok'; both 'no checklist or privilege error'; only required-property errors for"
  echo "  manifest-derived fields; the R-02 and R-04 rows print; the signed parse names the branch head commit."
  echo "RECORD: <date>-SB-8.4-nonprod-rows-manual-parse-v1, signed (E-05); then: agp-platform done SB-8.4 --witness <second human>"
}

step SB-8.5 BLOCKED "The register CI asserts the nonprod rules on the merged rows (BLOCKED)" --note "B-03: the R-02 and R-04 rule code"
s_SB_8_5_check() { ckpt_done SB-8.5; }
s_SB_8_5_manual() {
  echo "BLOCKED on B-03: the register CI rules R-02 and R-04 have no code (16 RG-3.3). SB-8.4's signed parse stands in."
  echo "The run writes the BLOCKED checkpoint and continues. When unblocked, the checks of SB-8.4 run as CI on the merge"
  echo "  pull requests of 23 and 31, and a fixture with a second env=prod P-SA row fails R-02."
}

step SB-8.6 HUMAN "Hand the twin accounts and sandbox identifiers to the detection lists" --witness
s_SB_8_6_check() { ckpt_done SB-8.6; }
s_SB_8_6_manual() {
  echo "WHO: platform owner writes; IT security merges into its rule repository (the witness)."
  echo "WHERE: a pull request to 15's reference lists (agp_twin_accounts)."
  echo "DO: add, tagged env=nonprod: SANDBOX_SA_1_EMAIL, SANDBOX_SA_2_EMAIL, SANDBOX_OPERATORS_GROUP, the synthetic users"
  echo "  of SB-4.2, and the placeholders eve@SANDBOX_DOMAIN (24) and walle@SANDBOX_DOMAIN (37)."
  echo "VERIFY: the list in IT security's repository shows the entries with env=nonprod; IT security's reviewer approved."
  echo "RECORD: the merge commit id; then: agp-platform done SB-8.6 --witness <IT security reviewer>"
}

# ======================================================================== Part 9: close

step SB-9.1 HUMAN "Write the re-run lines, the BLOCKED rows and the calendar entries" --witness
s_SB_9_1_check() { ckpt_done SB-9.1; }
s_SB_9_1_manual() {
  echo "WHO: platform owner writes; the second human reviews the build-log pull request."
  echo "WHERE: BUILD_LOG_DIR/rerun-index.tsv; README §8 and §9 through a wiki pull request; DRILL_CALENDAR."
  echo "DO: SB-9.1's three lists of setup/21: the seven re-run lines; README BLOCKED rows SB-7.6 (B-02) and SB-8.5 (B-03);"
  echo "  the quarterly sandbox reads, the monthly sandbox sink export and the envelope check in DRILL_CALENDAR."
  echo "VERIFY: the merged pull requests show every line; the second human is the approver."
  echo "RECORD: the merge commit ids (E-08); then: agp-platform done SB-9.1 --witness <second human>"
}

step SB-9.2 HUMAN "End every sitting without credentials"
s_SB_9_2_check() { ckpt_done SB-9.2; }
s_SB_9_2_manual() {
  echo "WHO: each person who signed in with gcloud: both sandbox super admins on their workstations, and the platform owner."
  echo "WHERE: each workstation shell. On this one: agp-platform sitting end (it runs sitting_end)."
  echo "DO: sitting_end; checkpoint SB-9.2 DONE - \"build-log:checkpoints.tsv\" \"sitting closed on \$(hostname -s)\";"
  echo "  sign out of every sandbox and production browser profile."
  echo "VERIFY: SITTING-END OK on every workstation. The page's checkpoint line records the step: no agp-platform done needed."
}
