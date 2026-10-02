# shellcheck shell=bash
# phases/07-billing-account.sh: setup/07, the platform billing account.
#
# The billing administrator (finance) performs every step on the account itself: confirming it,
# reading it, granting and removing the two bootstrap roles, reading its audit log. Those steps are
# HUMAN here: the platform owner never grants themselves a billing role, and is never given a way to
# read the account's audit log. The script runs only the platform owner's own commands: the expiry
# and its deviation row (BA-2.1), the present-and-absent permission proof (BA-2.3), and the
# self-grant path of the quota request (BA-6.2a grant, BA-6.2c removal). No budget is created here:
# §8 is the contract that files 10 and 17 follow.

phase 07 "The platform billing account" "07-billing-account.md"
requires org "resourcemanager.organizations.getIamPolicy resourcemanager.organizations.setIamPolicy"
# The two billing permissions exist only between BA-2.2 (the billing administrator's grant) and
# BA-7.1 (its removal). Declared unconditionally, preflight would refuse every apply between BA-1.1
# (which sets BILLING_ACCOUNT_ID) and BA-2.2, and every apply after BA-7.1. Reading the checkpoints
# at load time changes nothing.
if ckpt_done BA-2.2 && ! ckpt_done BA-7.1; then
  requires billing "billing.resourceAssociations.create billing.budgets.create"
fi

# ---------------------------------------------------------------- helpers of this phase

p07_ckpt() {    # p07_ckpt ID: checkpoints.tsv holds a DONE or N/A line for the step (N/A: path not taken)
  [ -n "${BUILD_LOG_DIR-}" ] && [ -f "$BUILD_LOG_DIR/checkpoints.tsv" ] || return 1
  awk -F'\t' -v s="$1" '$2 == s && ($3 == "DONE" || $3 == "N/A") {f = 1} END {exit f ? 0 : 1}' "$BUILD_LOG_DIR/checkpoints.tsv"
}

p07_bd_row() {      # p07_bd_row ID: the deviation register's first table holds row ID (01 PR-4.1, thirteen cells)
  local reg; reg="$(v DEVIATION_REGISTER)"; [ -f "$reg" ] || return 1
  awk -F' *[|] *' -v id="$1" '$2 == id && NF == 15 {f = 1} END {exit !f}' "$reg"
}

p07_bd_closed() {   # p07_bd_closed ID: the Closures table holds a line for ID
  local reg; reg="$(v DEVIATION_REGISTER)"; [ -f "$reg" ] || return 1
  awk -F' *[|] *' -v id="$1" '$2 == id && NF == 6 {f = 1} END {exit !f}' "$reg"
}

p07_record() {      # p07_record STEP SLUG EXT: the next free <date>-<step>-<slug>-v<n> in the build log's records
  local d n=1; d="$(date -u +%F)"
  while [ -e "$(v BUILD_LOG_DIR)/records/${d}-$1-$2-v${n}.$3" ]; do n=$((n + 1)); done
  printf '%s\n' "$(v BUILD_LOG_DIR)/records/${d}-$1-$2-v${n}.$3"
}

p07_keep() {        # p07_keep STEP FILE: commit one evidence record of the build log's records/ (evidence_add commits only the register)
  local bld; bld="$(v BUILD_LOG_DIR)"
  x git -C "$bld" add "records/$(basename "$2")" || return 1
  x git -C "$bld" commit -q -m "07 $1 evidence record" -- "records/$(basename "$2")"
}

p07_perms() {       # p07_perms: the permission names of the testIamPermissions response on standard input
  python3 -c 'import json, sys
print("\n".join(json.load(sys.stdin).get("permissions", [])))' 2>/dev/null
}

p07_test_perms() {  # p07_test_perms URL PERMISSION...: testIamPermissions (a read sent as POST); prints the response
  local url="$1" body rc first=1 p; shift
  body="$(mktemp "${TMPDIR:-/tmp}/agp-07.XXXXXX")"
  { printf '{"permissions":['
    for p in "$@"; do [ $first = 1 ] || printf ','; printf '"%s"' "$p"; first=0; done
    printf ']}'; } > "$body"
  AGP_API_PROJECT="" api POST "$url" "$body"; rc=$?
  rm -f "$body"
  return "$rc"
}

p07_tool_shown() {  # p07_tool_shown TOOL: the decision tool's path as a person types it (<PLATFORM_REPO_DIR> while unset)
  local t; t="$(agp_tool "$1")"
  case "$t" in /tools/*) t="<PLATFORM_REPO_DIR>$t";; esac
  printf '%s' "$t"
}

p07_bd_insert() {   # p07_bd_insert ROW: 01's bd_insert (idempotent, commits the register); the row is shown once in plan mode
  if [ "$AGP_MODE" != apply ]; then
    printf '      row %s, inserted into the first table of DEVIATION_REGISTER and committed:\n        %s\n' "$(printf '%s' "$1" | awk -F' *[|] *' '{print $2}')" "$1" >&3
    printf '      $ bd_insert "<the row above>"\n' >&3
    return 0
  fi
  x bd_insert "$1"
}

p07_row_bd071() {   # BA-2.1's row, in 01 PR-4.1's thirteen columns, as the page writes it
  printf '| BD-07-1 | %s | 07 BA-2.1 | EXC | billing roles roles/billing.user and roles/billing.costsManager to %s, granted by the billing administrator | billingAccounts/%s | SD-16 | two account-level grants (BA-2.2) | BLOCKED: no factory | - | %s | %s; superseded by factory-apply@ (BA-3.1), removed by BA-7.1 | open |' \
    "$(date -u +%F)" "$(v SA_1_ADMIN)" "$(v BILLING_ACCOUNT_ID)" "$(v BILLING_ADMIN_EMAIL)" "$(v BOOTSTRAP_BILLING_EXPIRY)"
}

p07_row_bd072() {   # p07_row_bd072 EXPIRY: BA-6.2a's row; kind DEV; expiry the condition's end; approver the second human, told the same day
  printf '| BD-07-2 | %s | 07 BA-6.2a | DEV | roles/servicemanagement.quotaAdmin to %s at organisation level for the BA-6.2b quota request | organizations/%s | BA-6.1 count in the build log | one conditioned organisation-level grant (BA-6.2a) | - | - | %s, told the same day | %s by the binding condition; removed by BA-6.2c | open |' \
    "$(date -u +%F)" "$(v SA_1_ADMIN)" "$(v ORG_ID)" "$(v SECOND_HUMAN_EMAIL)" "$1"
}

p07_qa_cond() {     # BA-6.2a's condition file, which BA-6.2c removes the binding by
  printf '%s/records/BA-6.2a-quota-admin-condition.yaml' "$(v BUILD_LOG_DIR)"
}

p07_qa_cond_text() {    # p07_qa_cond_text EXPIRY: the condition BA-6.2a's printf writes
  printf 'expression: request.time < timestamp("%s")\ntitle: ba-6-2a-quota-request\ndescription: Quota Administrator for the BA-6.2b project-quota request; removed by BA-6.2c, BD-07-2\n' "$1"
}

# ---------------------------------------------------------------- 1. the account

step BA-1.1 HUMAN "Identify the account and confirm it is standard, open and owned by the organisation" \
  --needs "ORG_ID PLATFORM_REPO_DIR" --sets "BILLING_ACCOUNT_ID" --gate "SD-16"
s_BA_1_1_check() { ckpt_done BA-1.1; }
s_BA_1_1_manual() {
  cat <<'EOF'
WHO: the billing administrator confirms; the platform owner records. WHERE: Cloud console > Billing >
Manage billing accounts > the account's row > Show info panel; then the platform owner's shell.
1. The billing administrator confirms the account SD-16 names is listed under the organisation.
EOF
  printf '2. BA_ID=$("%s" SD-16 BILLING_ACCOUNT_ID) && echo "account $BA_ID"\n' "$(p07_tool_shown decision-value.sh)"
  cat <<'EOF'
3. gcloud billing accounts describe "$BA_ID" --format="yaml(name,displayName,open,masterBillingAccount,parent,currencyCode)"
   (sa-1-admin@ holds no billing role yet: on permission denied the billing administrator runs it and sends the output)
4. Stop unless: open: true; masterBillingAccount empty; parent: organizations/$ORG_ID; display name as in SD-16.
Record: penv_set BILLING_ACCOUNT_ID "$BA_ID"; the YAML as <date>-BA-1.1-billing-account-describe-v1 in
EVIDENCE_INTERIM_LOCATION, and evidence_add BA-1.1 billing-account-describe E-05 1.3.1 "<location>"
Then: agp-platform done BA-1.1
EOF
}

step BA-1.2 HUMAN "Confirm the account is dedicated to the platform" --needs "BILLING_ACCOUNT_ID"
s_BA_1_2_check() { ckpt_done BA-1.2; }
s_BA_1_2_manual() {
  cat <<'EOF'
WHO: the billing administrator runs the list (Billing Account User lacks billing.resourceAssociations.list);
the platform owner verifies. WHERE: the billing administrator's shell, or Billing > Account management.
  gcloud billing projects list --billing-account="$BILLING_ACCOUNT_ID" --format="table(projectId,billingEnabled)"
VERIFY: the list is empty (the platform's first link is file 10). Any project listed: stop, and amend SD-16
with (a) a new dedicated account, BA-1.1 again, or (b) a shared account recorded, with file 14's
label-filtered view. EVE_WITNESS_PROJECT is never on this account (SD-28).
Evidence: the output as <date>-BA-1.2-linked-projects-v1; evidence_add BA-1.2 linked-projects E-05 1.3.1 "<location>"
Then: agp-platform done BA-1.2
EOF
}

step BA-1.3 HUMAN "Read the currency and stop unless EUR" --needs "BILLING_ACCOUNT_ID" --sets "BILLING_CURRENCY"
s_BA_1_3_check() { ckpt_done BA-1.3; }
s_BA_1_3_manual() {
  cat <<'EOF'
WHO: the billing administrator reads and reports the code (sa-1-admin@ holds no billing.accounts.get yet);
the platform owner records it. WHERE: the billing administrator's shell, then the platform owner's.
  gcloud billing accounts describe "<BILLING_ACCOUNT_ID>" --format='value(currencyCode)'
  (empty: the same session reads currencyCode from GET https://cloudbilling.googleapis.com/v1/billingAccounts/<id>)
EUR: penv_set BILLING_CURRENCY EUR
Not EUR: stop. Finance provides an EUR account (BA-1.1 again), or SD-16 is amended and signed to accept
the currency with every 02 §2.2 amount converted; then penv_set BILLING_CURRENCY "<the code>".
Evidence: the value (and any amendment) as <date>-BA-1.3-currency-v1; evidence_add BA-1.3 currency - 1.3.3 "<location>"
Then: agp-platform done BA-1.3
EOF
}

# ---------------------------------------------------------------- 2. the bootstrap roles for sa-1-admin@

step BA-2.1 AUTO "Record the expiry and check separation" \
  --needs "SA_1_ADMIN SA_2_ADMIN OWNER_DAILY_ACCOUNT BILLING_ADMIN_EMAIL PLATFORM_REPO_DIR BILLING_ACCOUNT_ID DEVIATION_REGISTER BUILD_LOG_DIR" \
  --sets "BOOTSTRAP_BILLING_EXPIRY" --gate "SD-16"
s_BA_2_1_check() { has_value BOOTSTRAP_BILLING_EXPIRY && p07_bd_row BD-07-1; }
s_BA_2_1_apply() {
  local tool adm o exp today
  tool="$(agp_tool decision-value.sh)"
  adm="$(v BILLING_ADMIN_EMAIL)"
  for o in SA_1_ADMIN SA_2_ADMIN OWNER_DAILY_ACCOUNT; do
    [ "$adm" != "$(v "$o")" ] || { agp_say "      VERIFY failed: BILLING_ADMIN_EMAIL equals $o; the billing administrator is a separate person"; return 1; }
  done
  if [ "$AGP_MODE" != apply ]; then
    printf '      $ %s SD-16 BOOTSTRAP_BILLING_EXPIRY   (an absolute date after today)\n' "$(p07_tool_shown decision-value.sh)" >&3
    pset BOOTSTRAP_BILLING_EXPIRY "<from SD-16>"
    p07_bd_insert "$(p07_row_bd071)"
    return 0
  fi
  [ -x "$tool" ] || { agp_say "      $tool is not installed: setup/03 DC-1.2 installs the decision tools"; return 1; }
  exp="$(r "$tool" SD-16 BOOTSTRAP_BILLING_EXPIRY)" || { agp_say "      decision-value.sh refused: SD-16 unsigned, altered, or no BOOTSTRAP_BILLING_EXPIRY row"; return 1; }
  case "$exp" in [0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]) ;; *) agp_say "      VERIFY failed: '$exp' is not an absolute date (YYYY-MM-DD)"; return 1;; esac
  today="$(date -u +%F)"
  [[ "$exp" > "$today" ]] || { agp_say "      VERIFY failed: $exp is not after today ($today)"; return 1; }
  pset BOOTSTRAP_BILLING_EXPIRY "$exp" || return 1
  p07_bd_insert "$(p07_row_bd071)" || return 1
  agp_say "      confirm by eye: $exp is no later than the Tier W gate target in 03's tracker (SD-01)"
}

step BA-2.2 HUMAN "Grant Billing Account User and Billing Account Costs Manager on the account only" \
  --needs "BILLING_ACCOUNT_ID SA_1_ADMIN"
s_BA_2_2_check() { ckpt_done BA-2.2; }
s_BA_2_2_manual() {
  cat <<'EOF'
WHO: the billing administrator. The platform owner never grants these to themselves.
WHERE: Billing > Account management > the account > Permissions > Add principal: sa-1-admin@<DOMAIN>,
roles Billing Account User and Billing Account Costs Manager, Save. Or in the billing administrator's shell:
  gcloud billing accounts add-iam-policy-binding "$BILLING_ACCOUNT_ID" --member="user:${SA_1_ADMIN}" --role="roles/billing.user"
  gcloud billing accounts add-iam-policy-binding "$BILLING_ACCOUNT_ID" --member="user:${SA_1_ADMIN}" --role="roles/billing.costsManager"
Never at organisation level, never Billing Account Administrator. Read back:
  gcloud billing accounts get-iam-policy "$BILLING_ACCOUNT_ID" --flatten="bindings[].members" --format="table(bindings.role,bindings.members)"
VERIFY: user:sa-1-admin@ exactly twice, under those two roles. The billing administrator puts a calendar
entry on BOOTSTRAP_BILLING_EXPIRY (BA-7.1). Evidence: the table as <date>-BA-2.2-billing-iam-after-grant-v1.
Then: agp-platform done BA-2.2
EOF
}

step BA-2.3 AUTO-READ "Prove the permissions as sa-1-admin@, present and absent" \
  --needs "BILLING_ACCOUNT_ID BUILD_LOG_DIR DEVIATION_REGISTER"
s_BA_2_3_check() { ckpt_done BA-2.3; }
s_BA_2_3_apply() {
  local url resp granted rec sec bd061_open=0 p row idx
  url="https://cloudbilling.googleapis.com/v1/billingAccounts/$(v BILLING_ACCOUNT_ID):testIamPermissions"
  if [ "$AGP_MODE" != apply ]; then
    p07_test_perms "$url" billing.resourceAssociations.create billing.budgets.create billing.accounts.close billing.accounts.setIamPolicy
    printf '      $ %s   (does Security Admin carry billing.accounts.setIamPolicy today?)\n' "$(agp_quote gcloud iam roles describe roles/iam.securityAdmin --format=json)" >&3
    ev BA-2.3 testiampermissions - 4.2.1 "build-log:records"
    return 0
  fi
  resp="$(p07_test_perms "$url" billing.resourceAssociations.create billing.budgets.create billing.accounts.close billing.accounts.setIamPolicy)" || {
    agp_say "      testIamPermissions failed: $resp"
    case "$resp" in *[Qq]uota*|*"user project"*|*[Uu]ser[Pp]roject*)
      agp_say "      the error names a quota or user project: repeat this call in file 10 with x-goog-user-project: CICD_PROJECT, and record BA-2.3 as re-run there";; esac
    return 1; }
  rec="$(p07_record BA-2.3 testiampermissions json)"
  printf '%s\n' "$resp" | xw "$rec" || return 1
  granted="$(printf '%s' "$resp" | p07_perms)"
  printf '%s\n' "$granted" | while IFS= read -r p; do [ -z "$p" ] || agp_say "      granted: $p"; done
  for p in billing.resourceAssociations.create billing.budgets.create; do
    printf '%s\n' "$granted" | grep -qx "$p" || { agp_say "      VERIFY failed: $p is missing; BA-2.2's grant is not live"; return 1; }
  done
  if printf '%s\n' "$granted" | grep -qx billing.accounts.close; then
    agp_say "      STOP: billing.accounts.close is held: the platform owner already holds more. Run BA-5.1 to find the source and have it removed"
    return 1
  fi
  if printf '%s\n' "$granted" | grep -qx billing.accounts.setIamPolicy; then
    sec="$(r gcloud iam roles describe roles/iam.securityAdmin --format=json)" || { agp_say "      could not read roles/iam.securityAdmin"; return 1; }
    p07_bd_row BD-06-1 && ! p07_bd_closed BD-06-1 && bd061_open=1
    if [ "$bd061_open" = 1 ] && printf '%s' "$sec" | python3 -c 'import json, sys
sys.exit(0 if "billing.accounts.setIamPolicy" in json.load(sys.stdin).get("includedPermissions", []) else 1)'; then
      agp_say "      billing.accounts.setIamPolicy is expected: inherited from BD-06-1's Security Admin; record it in BA-5.1 as an indirect closer path covered by SG-BILL-01"
      idx="$(v BUILD_LOG_DIR)/rerun-index.tsv"
      row="$(printf '%s\t%s\t%s\t%s\t%s\t%s' "$(date -u +%F)" BA-2.3 - "after 12 PA-9.3: re-run BA-2.3, expect billing.accounts.setIamPolicy absent" PENDING "07 BA-2.3")"
      if ! grep -qF "after 12 PA-9.3: re-run BA-2.3" "$idx" 2>/dev/null; then
        { cat "$idx" 2>/dev/null; printf '%s\n' "$row"; } | xw "$idx" || return 1
      fi
    else
      agp_say "      STOP: billing.accounts.setIamPolicy is held while BD-06-1 is closed or Security Admin does not carry it: run BA-5.1 to find the source and have it removed"
      return 1
    fi
  fi
  ev BA-2.3 testiampermissions - 4.2.1 "build-log:records/$(basename "$rec")" "$rec" || return 1
  p07_keep BA-2.3 "$rec"
}

# ---------------------------------------------------------------- 3. the factory identity (re-run point from file 10)

step BA-3.1 HUMAN "Grant the same two roles to factory-apply@" --needs "BILLING_ACCOUNT_ID" --on-unmet skip \
  --note "PENDING by design until file 10 creates SA_FACTORY_APPLY; the run goes on"
s_BA_3_1_check() { ckpt_done BA-3.1; }
s_BA_3_1_manual() {
  cat <<'EOF'
WHO: the billing administrator grants; the platform owner checks existence first and verifies.
Before file 10 (replace <CICD_PROJECT> with the signed NAMES value), record the re-run once:
  exists_or_pending --pending "serviceAccount:factory-apply@<CICD_PROJECT>.iam.gserviceaccount.com" BA-3.1 "07 BA-3.1 roles/billing.user and roles/billing.costsManager for factory-apply@"
After file 10:
  exists_or_pending "serviceAccount:${SA_FACTORY_APPLY}" BA-3.1 "07 BA-3.1 billing roles for factory-apply@" && echo "EXISTS: billing administrator grants"
The billing administrator then adds serviceAccount:<SA_FACTORY_APPLY> with roles/billing.user and
roles/billing.costsManager (console, or BA-3.1's two add-iam-policy-binding lines of setup/07).
VERIFY: BA-2.2's get-iam-policy table shows it under exactly those two roles; clear the PENDING line.
Then: agp-platform done BA-3.1
EOF
}

# ---------------------------------------------------------------- 4. detecting a self-grant and admin changes

step BA-4.1 HUMAN "Commit the detection specification" --needs "PLATFORM_REPO_DIR BILLING_ADMIN_EMAIL SECOND_HUMAN_EMAIL"
s_BA_4_1_check() { ckpt_done BA-4.1; }
s_BA_4_1_manual() {
  cat <<'EOF'
WHO: the platform owner writes; the second human reviews (CODEOWNERS of 03).
WHERE: PLATFORM_REPO_DIR, branch ba-billing-detection, file detections/billing-account-admin.yaml.
Write it with rule id SG-BILL-01, severity 2 (1 if the actor is on ROSTER_FILE), recipients
BILLING_ADMIN_EMAIL and SECOND_HUMAN_EMAIL, and BA-4.1's filters A and B of setup/07, as written there.
  git -C "$PLATFORM_REPO_DIR" switch -c ba-billing-detection
  git -C "$PLATFORM_REPO_DIR" add detections/billing-account-admin.yaml
  git -C "$PLATFORM_REPO_DIR" commit -m "detection: billing-role self-grant and billing-account admin writes (07 BA-4.1)"
  git -C "$PLATFORM_REPO_DIR" push -u origin ba-billing-detection
Open the pull request; merge after the two reviews. VERIFY:
  git -C "$PLATFORM_REPO_DIR" log --oneline origin/main -- detections/billing-account-admin.yaml
Evidence: the merge commit and pull request URL in EVIDENCE_REGISTER. Then: agp-platform done BA-4.1
EOF
}

step BA-4.2 HUMAN "Prove filter B on the grants just made" --needs "BILLING_ACCOUNT_ID BILLING_ADMIN_EMAIL"
s_BA_4_2_check() { ckpt_done BA-4.2; }
s_BA_4_2_manual() {
  cat <<'EOF'
WHO: the billing administrator runs every read, in their own shell only (no console route: billing audit
logs are readable only through gcloud or the Logging API); the platform owner verifies what they are sent.
Never grant sa-1-admin@ a logging role or a way to read this log.
1. Precondition: BA-4.2's get-iam-policy read of setup/07 shows the billing administrator under roles/billing.admin.
2. BA-4.2's two gcloud logging read commands of setup/07 (--billing-account, --freshness=7d), each exit status noted.
VERIFY: the first returns at least one SetIamPolicy row dated with BA-2.2 by BILLING_ADMIN_EMAIL; the second
returns nothing. Empty first read with exit 0: stop (source B is blind). PERMISSION_DENIED: not a result;
fix the billing administrator's grant and repeat, as BA-4.2's VERIFY says.
Evidence: the three outputs and exit statuses as <date>-BA-4.2-filter-b-proof-v1.
Then: agp-platform done BA-4.2
EOF
}

step BA-4.3 HUMAN "Run the interim check weekly until file 15's alert is live" \
  --needs "BILLING_ACCOUNT_ID BILLING_ADMIN_EMAIL ORG_ID" --on-unmet skip \
  --note "weekly from BA-2.2 until file 15 part A records SG-BILL-01 live; the run goes on"
s_BA_4_3_check() { ckpt_done BA-4.3; }
s_BA_4_3_manual() {
  cat <<'EOF'
Each week, until file 15 records the SG-BILL-01 alert live; the output goes to the second human.
Source B, the billing administrator's shell only (never the console): BA-4.3's first gcloud logging read
of setup/07 (--freshness=8d). VERIFY: no row and exit 0; a 403 is a missed week, reported the same day.
Source A, the platform owner's shell (weak: they are its subject):
  gcloud organizations get-iam-policy "$ORG_ID" --flatten="bindings[].members" --filter="bindings.role:roles/billing. OR bindings.role=roles/iam.securityAdmin" --format="table(bindings.role,bindings.members)"
VERIFY: only the principals BA-5.1 recorded. Any difference: to the billing administrator and the second human the same day.
Each week: checkpoint "BA-4.3-$(date -u +%G-W%V)" DONE - - "weekly check"; outputs as <date>-BA-4.3-weekly-v<n>.
Re-run index rows: "14: billing-account sink for source B"; "15 part A: SG-BILL-01 alert, back-dated from BA-2.2".
When file 15's alert is live: agp-platform done BA-4.3
EOF
}

# ---------------------------------------------------------------- 5. who may close the account

step BA-5.1 HUMAN "Inventory every direct, inherited and indirect closer" --needs "BILLING_ACCOUNT_ID ORG_ID"
s_BA_5_1_check() { ckpt_done BA-5.1; }
s_BA_5_1_manual() {
  cat <<'EOF'
WHO: the billing administrator (account side); the platform owner (organisation side). Both shells.
Account side: BA-5.1's roles/billing.linkAdmin read and its prefix-filtered read of setup/07:
  gcloud billing accounts get-iam-policy "$BILLING_ACCOUNT_ID" --flatten="bindings[].members" --filter="bindings.role:roles/billing." --format="table(bindings.role,bindings.members)"
Organisation side:
  gcloud organizations get-iam-policy "$ORG_ID" --flatten="bindings[].members" --filter="bindings.role:roles/billing. OR bindings.role=roles/iam.securityAdmin OR bindings.role=roles/resourcemanager.organizationAdmin" --format="table(bindings.role,bindings.members)"
  gcloud iam roles list --organization="$ORG_ID" --format="value(name)"   (then describe each custom role)
VERIFY: the four-column table (direct closers, inherited closers, unlinkers, indirect paths) of setup/07;
no domain: or allUsers member on any billing role; neither SA_1_ADMIN nor factory-apply@ a direct or
inherited closer; SA_1_ADMIN's Security Admin listed as indirect while BD-06-1 is open.
Evidence: the table as <date>-BA-5.1-closers-inventory-v1. Then: agp-platform done BA-5.1
EOF
}

step BA-5.2 HUMAN "Sign the closers record"
s_BA_5_2_check() { ckpt_done BA-5.2; }
s_BA_5_2_manual() {
  cat <<'EOF'
WHO: the billing administrator signs; the platform owner files it.
WHERE: decisions/<date>-platform-billing-account-closers.md in the platform repository (append-only).
Record, as BA-5.2 of setup/07 lists: the named direct closers; the indirect paths of BA-5.1 and the
detection covering each; the invoiced-account closure route and its finance contacts (*tbd* until named);
the payments-profile administrators (*tbd*); the rule that no platform principal holds Billing Account Administrator.
VERIFY: it merges with the billing administrator's and the second human's approvals; every name matches BA-5.1.
Evidence: the merge commit in EVIDENCE_REGISTER. Then: agp-platform done BA-5.2
EOF
}

# ---------------------------------------------------------------- 6. project quota

step BA-6.1 HUMAN "Count the projects the set creates in this organisation"
s_BA_6_1_check() { ckpt_done BA-6.1; }
s_BA_6_1_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: the build log, under BA-6.1.
Fill BA-6.1's table of setup/07 from the signed NAMES record: the core projects (10), the canary (18),
Mo, Eve and Wall-E projects and twins, advisor and spike projects, and headroom for soft-deleted projects.
The witness organisation's and the sandbox organisation's projects do not count here.
VERIFY: a total is written, at least 18 (target about 20).
Then: agp-platform done BA-6.1
EOF
}

step BA-6.2a AUTO "Grant Quota Administrator to SA_1_ADMIN for this sitting (self-grant path only)" \
  --needs "ORG_ID SA_1_ADMIN SECOND_HUMAN_EMAIL DEVIATION_REGISTER BUILD_LOG_DIR"
s_BA_6_2a_check() {
  local rc
  p07_ckpt BA-6.2a && return 0
  has_binding "user:$(v SA_1_ADMIN)" roles/servicemanagement.quotaAdmin gcloud organizations get-iam-policy "$(v ORG_ID)"; rc=$?
  [ $rc -eq 0 ] || return $rc
  p07_bd_row BD-07-2
}
s_BA_6_2a_apply() {
  local url resp rec p granted c exp
  printf '      self-grant path only. When the organisation has a holder of roles/servicemanagement.quotaAdmin, that\n' >&3
  printf '      person files BA-6.2b instead; name them in the build log and record, before re-running:\n' >&3
  printf '        checkpoint BA-6.2a N/A - - "existing quota administrator files BA-6.2b"   (and the same for BA-6.2c)\n' >&3
  c="$(p07_qa_cond)"
  # The page's guard: a condition file left by an earlier grant is removed with BA-6.2c first, then moved aside.
  if [ "$AGP_MODE" = apply ] && [ -e "$c" ]; then
    agp_say "      STOP: $c exists from an earlier grant; run BA-6.2c's removal with it, then move it aside"
    return 98
  fi
  # The binding carries a request.time condition ending twelve hours after the grant (the page, as 06 OB-3.5a).
  if [ "$AGP_MODE" = apply ]; then
    exp="$(date -u -v+12H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '+12 hours' +%Y-%m-%dT%H:%M:%SZ)"
  else
    exp="<now + 12 hours, UTC>"
  fi
  x mkdir -p "$(v BUILD_LOG_DIR)/records" || return 1
  p07_qa_cond_text "$exp" | xw "$c" || return 1
  [ "$AGP_MODE" = apply ] || printf '        expression: request.time < timestamp("%s")\n' "$exp" >&3
  x gcloud organizations add-iam-policy-binding "$(v ORG_ID)" --member="user:$(v SA_1_ADMIN)" --role="roles/servicemanagement.quotaAdmin" --condition-from-file="$c" || return 1
  p07_bd_insert "$(p07_row_bd072 "$exp")" || return 1
  url="https://cloudresourcemanager.googleapis.com/v3/organizations/$(v ORG_ID):testIamPermissions"
  if [ "$AGP_MODE" != apply ]; then
    p07_test_perms "$url" serviceusage.quotas.update cloudquotas.quotas.update
    ev BA-6.2a quota-admin-granted - 4.1.3 "build-log:records"
    return 0
  fi
  resp="$(p07_test_perms "$url" serviceusage.quotas.update cloudquotas.quotas.update)" || { agp_say "      testIamPermissions failed: $resp"; return 1; }
  rec="$(p07_record BA-6.2a quota-admin-granted json)"
  printf '%s\n' "$resp" | xw "$rec" || return 1
  granted="$(printf '%s' "$resp" | p07_perms)"
  for p in serviceusage.quotas.update cloudquotas.quotas.update; do
    printf '%s\n' "$granted" | grep -qx "$p" || { agp_say "      STOP: $p is not live; do not go on to BA-6.2b (the console request would fail after the form is filled)"; return 1; }
  done
  ev BA-6.2a quota-admin-granted - 4.1.3 "build-log:records/$(basename "$rec")" "$rec" || return 1
  p07_keep BA-6.2a "$rec" || return 1
  agp_say "      tell the second human today that the role was taken; BA-6.2c removes it in this same sitting"
  agp_say "      the role stops working at $exp (its condition); if BA-6.2b cannot be filed before then, the binding"
  agp_say "      still stands: run BA-6.2c now (agp-platform apply --phase 07 --from BA-6.2c) and write in the build log why"
}

step BA-6.2b CONSOLE "File the increase" --irreversible --needs "BILLING_ACCOUNT_ID"
s_BA_6_2b_check() { ckpt_done BA-6.2b; }
s_BA_6_2b_manual() {
  cat <<'EOF'
WHO: the named existing Quota Administrator, or the platform owner once BA-6.2a's VERIFY has passed.
Only once BA-6.1's count is written and file 04's purchase row for the billing account is settled.
WHERE: Console > IAM & Admin > Quotas & System Limits, resource selector on the organisation.
Metric cloudresourcemanager.googleapis.com/projects_count > Cloud Resource Manager API > More actions >
Edit quota: BA-6.1's target, description "Agentic platform: about 20 projects under fld-agentic-platform,
paid by billing account BILLING_ACCOUNT_ID, 2026-09 to Tier W"; Next; contact details; Submit request.
IRREVERSIBLE as a submission. If Google asks for a payment, nothing is paid until finance approves it.
VERIFY: the acknowledgement email; Increase Requests shows it pending with the target.
Evidence: the email as <date>-BA-6.2b-quota-request-v1, with the submitter's name.
Then: agp-platform done BA-6.2b
EOF
}

step BA-6.2c AUTO "Remove Quota Administrator (self-grant path only)" --removes \
  --needs "ORG_ID SA_1_ADMIN DEVIATION_REGISTER BUILD_LOG_DIR"
s_BA_6_2c_check() {
  p07_ckpt BA-6.2c && return 0
  # The self-grant path was not taken: nothing was granted, so nothing is removed.
  [ -n "${BUILD_LOG_DIR-}" ] && awk -F'\t' '$2 == "BA-6.2a" && $3 == "N/A" {f = 1} END {exit f ? 0 : 1}' "$BUILD_LOG_DIR/checkpoints.tsv" 2>/dev/null && return 0
  # BD-07-2 is closed only after this step's VERIFY passed.
  p07_bd_closed BD-07-2
}
s_BA_6_2c_apply() {
  local pol left rec c
  c="$(p07_qa_cond)"
  if [ "$AGP_MODE" = apply ] && [ ! -f "$c" ]; then
    agp_say "      $c is missing: the binding is removed by the condition BA-6.2a wrote; read the policy and restore the file first"
    return 1
  fi
  x gcloud organizations remove-iam-policy-binding "$(v ORG_ID)" --member="user:$(v SA_1_ADMIN)" --role="roles/servicemanagement.quotaAdmin" --condition-from-file="$c" || return 1
  # The page's VERIFY read (--flatten, --filter, value()) must print nothing. The same read is made on the
  # whole policy as JSON and the members of the role are taken from it, so the answer does not depend on
  # gcloud's filter and format: no member, under any condition, may hold the role.
  if [ "$AGP_MODE" != apply ]; then
    printf '      $ %s   (no member may hold roles/servicemanagement.quotaAdmin)\n' "$(agp_quote gcloud organizations get-iam-policy "$(v ORG_ID)" --format=json)" >&3
    ev BA-6.2c quota-admin-removed - 4.1.3 "build-log:records"
    x bd_close BD-07-2 "withdrawal: 07 BA-6.2c, quotaAdmin removed from sa-1-admin@" "07 BA-6.2c VERIFY"
    return 0
  fi
  pol="$(r gcloud organizations get-iam-policy "$(v ORG_ID)" --format=json)" \
    || { agp_say "      the read-back failed; read the error above"; return 1; }
  left="$(printf '%s' "$pol" | python3 -c 'import json, sys
print(" ".join(m for b in (json.load(sys.stdin) or {}).get("bindings", []) if b.get("role") == "roles/servicemanagement.quotaAdmin" for m in b.get("members", [])))')" \
    || { agp_say "      the read-back is not an IAM policy in JSON"; return 1; }
  [ -z "$left" ] || { agp_say "      VERIFY failed: roles/servicemanagement.quotaAdmin is still held by: $left"; return 1; }
  rec="$(p07_record BA-6.2c quota-admin-removed txt)"
  printf '%s  ->  (nothing: no member holds roles/servicemanagement.quotaAdmin, read %s)\n' "gcloud organizations get-iam-policy $(v ORG_ID) --format=json" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" | xw "$rec" || return 1
  ev BA-6.2c quota-admin-removed - 4.1.3 "build-log:records/$(basename "$rec")" "$rec" || return 1
  p07_keep BA-6.2c "$rec" || return 1
  x bd_close BD-07-2 "withdrawal: 07 BA-6.2c, quotaAdmin removed from sa-1-admin@" "07 BA-6.2c VERIFY" || return 1
  agp_say "      tell the second human that the role is removed"
}

step BA-6.3 HUMAN "Record the answer" --on-unmet skip \
  --note "Google answers by email in about two business days; file 10 does not wait for it"
s_BA_6_3_check() { ckpt_done BA-6.3; }
s_BA_6_3_manual() {
  cat <<'EOF'
WHO: the platform owner. WHERE: the decision email (the primary record; it needs no role).
The Increase Requests tab is a confirmation only, read by the existing Quota Administrator or a Quota
Viewer holder; the role is never re-taken for a read.
VERIFY: the approved value is at least BA-6.1's total. Lower, or refused: file 18 waits for a new request.
Before file 10, confirm on the Quotas & System Limits row that the five core projects fit today's quota.
Evidence: the email as <date>-BA-6.3-quota-decision-v1.
Then: agp-platform done BA-6.3
EOF
}

# ---------------------------------------------------------------- 7. removal at expiry

step BA-7.1 HUMAN "Remove the bootstrap roles" --removes --on-unmet skip \
  --needs "BILLING_ACCOUNT_ID SA_1_ADMIN BOOTSTRAP_BILLING_EXPIRY" \
  --note "due on BOOTSTRAP_BILLING_EXPIRY, or earlier when file 17 records the factory's first empty plan"
s_BA_7_1_check() { ckpt_done BA-7.1; }
s_BA_7_1_manual() {
  cat <<'EOF'
WHO: the billing administrator removes; the platform owner verifies.
WHEN: on BOOTSTRAP_BILLING_EXPIRY, or earlier when file 17 records that the factory supersedes hand runs.
WHERE: Billing > Account management > Permissions, filter on sa-1-admin@, Delete; or their shell:
  gcloud billing accounts remove-iam-policy-binding "$BILLING_ACCOUNT_ID" --member="user:${SA_1_ADMIN}" --role="roles/billing.user"
  gcloud billing accounts remove-iam-policy-binding "$BILLING_ACCOUNT_ID" --member="user:${SA_1_ADMIN}" --role="roles/billing.costsManager"
VERIFY: BA-2.3's testIamPermissions as sa-1-admin@ returns {} (or only billing.accounts.setIamPolicy while
BD-06-1 is open); the policy table no longer lists sa-1-admin@; factory-apply@ still holds both roles.
A pending hand run needs a signed SD-16 extension first (penv_set --force BOOTSTRAP_BILLING_EXPIRY).
Then: bd_close BD-07-1 "withdrawal: 07 BA-7.1, billing.user and billing.costsManager removed from sa-1-admin@" "07 BA-7.1 VERIFY"
and: agp-platform done BA-7.1
EOF
}
