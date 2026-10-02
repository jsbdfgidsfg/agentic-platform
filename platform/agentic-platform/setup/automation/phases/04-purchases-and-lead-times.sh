# phases/04-purchases-and-lead-times.sh: setup/04, purchases and lead times.
#
# Nothing in Google Cloud or Workspace is created here (setup/04 "What this part builds"). The script reads
# and records the decision inputs of setup/03 (PU-0.1); every purchase, contract, registration, question to
# the account team and key custody is a person's act and is HUMAN (or CONSOLE for the seat count), with
# the page's commit gate named in the step's note. A quote may start before any signature, so the purchase
# steps carry no --gate (which would hide them until signed); the gate is stated, and checked by the person
# with tools/decision-need.sh, before anything is committed.
#
# Purchases run in parallel from day one, so every manual step is --on-unmet skip: apply lists it and
# carries on. A step that sets a value a later phase needs (SANDBOX_DOMAIN for 21, PAGER_SERVICE_NAME and
# PAGER_SUBJECT_SERVICE_NAME for 15, WITNESS_DOMAIN for 08) can be skipped safely, because in apply mode
# the runner counts an input only when it has a value: the consumer stops on the missing name itself.
# The order on the page (and here) is the lead-time order; PU-2.9 is performed after PU-2.10.

phase 04 "Purchases and lead times" "04-purchases-and-lead-times.md"

p04_done_line() {   # p04_done_line STEP [witness role]
  if [ -n "${2-}" ]; then echo "THEN: agp-platform done $1 --witness <$2 email>"
  else echo "THEN: agp-platform done $1"; fi
}

p04_any() {         # p04_any GLOB: 0 when a file matches
  local f
  for f in $1; do [ -f "$f" ] && return 0; done
  return 1
}

# ---------------------------------------------------------------- §2 purchase steps
step PU-0.1 AUTO "Confirm the inputs from 03" --on-unmet skip \
  --needs "PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER SIEM_KIND SCC_BILLING_MODEL BILLING_ADMIN_EMAIL SECOND_HUMAN_EMAIL INCIDENT_COMMANDER_EMAIL WITNESS_ADMIN_1_EMAIL WITNESS_ADMIN_2_EMAIL" \
  --note "a missing input does not stop the purchases: quote that row, do not commit it"
s_PU_0_1_check() { ckpt_done PU-0.1 || p04_any "$(v BUILD_LOG_DIR)/04-PU-0.1-inputs-*.txt"; }
s_PU_0_1_apply() {
  # The page's two `need` lines are this step's --needs (not the sandbox super admins' addresses: 03 DC-2.6 records
  # them only after PU-2.5 sets SANDBOX_DOMAIN; PPL-SB1 and PPL-SB2 are read as decisions instead). Its first
  # decision-need.sh line names the decisions every commit of 04 waits on; an UNSIGNED line is recorded and that
  # row is quoted, not committed (PU-0.1 VERIFY).
  local t f b out1 out2 rc1
  t="$(agp_tool decision-need.sh)"
  case "$t" in /tools/*) t="$(v PLATFORM_REPO_DIR)/tools/decision-need.sh";; esac   # PLATFORM_REPO_DIR not exported yet (plan)
  b="$(v BUILD_LOG_DIR)"; f="04-PU-0.1-inputs-$(date -u +%F).txt"
  if [ "$AGP_MODE" != apply ]; then
    printf '      would read: %s P10 P11 SD-15 P14 SD-28 P31 SD-16 WDEC-29 SD-29 PPL-SB1 PPL-SB2 SD-12 P22 SD-14\n' "$t" >&3
    printf '      would read: %s P63 P99 (GAP expected while 03'"'"'s tracker has no row for them)\n' "$t" >&3
    printf 'PU-0.1 decision inputs\n' | xw "$b/$f" 644
    x git -C "$b" add "$f"
    ev PU-0.1 decision-inputs E-05 1.1-1.2 "build-log:$f" "$b/$f"
    return 0
  fi
  [ -x "$t" ] || { printf '      STOP: %s is missing; setup/03 DC-1.2 writes it\n' "$t" >&3; return 1; }
  out1="$("$t" P10 P11 SD-15 P14 SD-28 P31 SD-16 WDEC-29 SD-29 PPL-SB1 PPL-SB2 SD-12 P22 SD-14 2>&1)"; rc1=$?
  out2="$("$t" P63 P99 2>&1)" || out2="$out2
GAP: P63 and/or P99 have no signed record; PU-2.9 and PU-2.6 may quote but not commit"
  printf '%s\n%s\n' "$out1" "$out2" | sed 's/^/        /' >&3
  if [ $rc1 -ne 0 ]; then
    printf '      a decision above is not SIGNED: start the quotes and questions for its rows, and do not commit them\n' >&3
  fi
  { printf 'PU-0.1 decision inputs, %s, %s\n' "$(date -u +%FT%TZ)" "$(git -C "$b" config user.email)"
    printf '%s\n%s\n' "$out1" "$out2"; } | xw "$b/$f" 644 || return 1
  x git -C "$b" add "$f" || return 1   # committed with the register line by evidence_add
  ev PU-0.1 decision-inputs E-05 1.1-1.2 "build-log:$f" "$b/$f"
}

step PU-2.1 HUMAN "SIEM and MDR retainer (row 1, P10)" --irreversible --on-unmet skip --note "quote now; commit only on P10"
s_PU_2_1_check() { ckpt_done PU-2.1; }
s_PU_2_1_manual() {
  echo "WHO: IT security buys; the platform owner raises the request and supplies S1-S9 (../07 §2.1) and the §9.2 targets; the finance approver signs."
  echo "WHERE: the procurement system; the Google account team for SecOps, or the organisation's SIEM owner."
  echo "DO: SIEM_KIND secops: Google SecOps, Europe multi-region (P93), retention of at least 400 days (S2). existing: IT security"
  echo "  measures the SIEM against S1-S9 and signs the result, naming any failed clause. Then the MDR retainer: SA-01..SA-09,"
  echo "  SG-01..SG-07, 24x7 acknowledgement of severity 1."
  echo "IRREVERSIBLE for the contract term once signed. Confirm first: decision-need.sh P10 prints SIGNED, region and retention match P93 and S2, the DPA is signed."
  echo "CHECK: on sight of the order form (or the signed S1-S9 assessment) and the retainer, not on a statement that they exist."
  echo "SAVE: <date>-PU-2.1-siem-order-v1 and <date>-PU-2.1-mdr-retainer-v1 in EVIDENCE_INTERIM_LOCATION (E-11; TISAX 6.1, 1.6)."
  p04_done_line PU-2.1
}

step PU-2.2 HUMAN "Penetration test (row 2, G8)" --irreversible --on-unmet skip --note "quote now; commit only on the G8 window (G8-WINDOW)"
s_PU_2_2_check() { ckpt_done PU-2.2; }
s_PU_2_2_manual() {
  echo "WHO: IT security buys; the platform owner raises; the finance approver signs."
  echo "WHERE: the procurement system."
  echo "DO: statement of work: Tier W control surfaces behind IAP, Wall-E action services and approval surfaces on the sandbox twin,"
  echo "  the Eve export path, organisation-policy and PAM configuration; a scoped test before the first Tier W Stage 1, the full"
  echo "  test before the super-admin grant; only the organisation's own projects and the sandbox tenant; the G8 window of 03."
  echo "IRREVERSIBLE as far as the vendor's cancellation fee: confirm the fee, and decision-need.sh G8-WINDOW, before signing."
  echo "CHECK: a signed statement of work with the scope, both windows and the tester's named contact."
  echo "SAVE: <date>-PU-2.2-pentest-sow-v1 (TISAX 5.2; E-03)."
  p04_done_line PU-2.2
}

step PU-2.3 HUMAN "SCC Premium payer or contract (row 3, P11, SD-15)" --irreversible --on-unmet skip --note "ask now; commit only on P11 and SD-15"
s_PU_2_3_check() { ckpt_done PU-2.3; }
s_PU_2_3_manual() {
  echo "WHO: IT security and finance decide and buy; the platform owner raises; the finance approver signs."
  echo "WHERE: the finance approval record; the Google account team for the subscription."
  echo "DO: both options in writing: pay-as-you-go at organisation level (charged to every project's billing account: finance"
  echo "  signs and notifies each cost-centre owner), or the subscription (minimum 15,000 USD a year, 12 months)."
  echo "  Record the payer; SCC_BILLING_MODEL is set in 03. Model Armor allowance: 3 billion tokens a month with the subscription;"
  echo "  pay-as-you-go is *tbd* (PU-3.3) and costed at zero until answered. Never the Enterprise tier (deprecated"
  echo "  2026-05-21, shut down 2027-05-21): a P11 naming it goes back to 03 to be re-signed for Premium."
  echo "IRREVERSIBLE for 12 months if the subscription: confirm decision-need.sh P11 SD-15, Premium tier and eu residency (P94) first."
  echo "CHECK: a signed payer record naming model and payer; the cost-centre notice, or a countersigned order. Activation is 09."
  echo "SAVE: <date>-PU-2.3-scc-payer-v1 and, if bought, <date>-PU-2.3-scc-order-v1 (E-11; TISAX 6.1)."
  p04_done_line PU-2.3
}

step PU-2.4 HUMAN "Witness domain and billing path (row 4, P14, SD-28)" --sets "WITNESS_DOMAIN" --on-unmet skip \
  --note "search now; commit only on P14 and SD-28; WITNESS_DOMAIN is read by 08"
s_PU_2_4_check() { ckpt_done PU-2.4; }
s_PU_2_4_manual() {
  echo "WHO: the two witness administrators (IT security) perform; procurement and the finance approver approve billing and support."
  echo "WHERE: a registrar and DNS account IT security alone administers, outside the tenant's organisation and the Digital Workplace line."
  echo "DO: a separately registered domain on no Google account; 2SV and registrar lock on; DNS with the same two administrators only."
  echo "  Billing: an account parented by the witness organisation, never the platform's (route after PU-3.2's answer)."
  echo "  Support: a Customer Care subscription for the witness organisation (PU-3.1). Gate: decision-need.sh P14 SD-28."
  echo "RECORD (the platform owner, from the name handed over; typed by you):"
  echo "  penv_set WITNESS_DOMAIN \"<domain handed over by the witness administrators>\""
  echo "CHECK: whois shows the registrar and clientTransferProhibited; dig NS shows the chosen DNS provider; written 2SV confirmation;"
  echo "  finance's and procurement's approvals on file. SAVE: <date>-PU-2.4-witness-domain-v1, <date>-PU-2.4-witness-billing-approval-v1."
  p04_done_line PU-2.4
}

step PU-2.5 HUMAN "Sandbox Workspace tenant (row 5, decision 29, SD-29)" --irreversible --sets "SANDBOX_DOMAIN" --on-unmet skip \
  --note "search now; commit only on decision 29 and SD-29; SANDBOX_DOMAIN is read by 21"
s_PU_2_5_check() { ckpt_done PU-2.5; }
s_PU_2_5_manual() {
  echo "WHO: the platform owner specifies; procurement orders through the reseller or account team; the finance approver signs;"
  echo "  the organisation's domain owner registers the domain."
  echo "WHERE: the procurement system; the corporate registrar; the tenant shell for the variable."
  echo "DO: order from SD-29 with its reasons: edition equal to production, never below Enterprise Standard; seats for walle@, eve@,"
  echo "  the two sandbox super admins named in PPL-SB1 and PPL-SB2 (03 DC-2.6) and the synthetic accounts; the terms signer named;"
  echo "  P59. Register a separate domain on no Google account, DNS editable by the sandbox super admins."
  echo "IRREVERSIBLE for the plan's commitment: confirm decision-need.sh WDEC-29 SD-29 and the edition line first."
  echo "RECORD (typed by you): penv_set SANDBOX_DOMAIN \"<registered sandbox domain>\"; then tell the ISMS, so 03 DC-2.6's"
  echo "  superseding record can add SANDBOX_SA_1_EMAIL and SANDBOX_SA_2_EMAIL."
  echo "CHECK: whois and dig NS as PU-2.5 says; dig TXT shows no google-site-verification value (one: stop and ask the domain owner)."
  echo "SAVE: <date>-PU-2.5-sandbox-order-v1, <date>-PU-2.5-sandbox-domain-v1 (E-04; TISAX 5.2, 1.3)."
  p04_done_line PU-2.5
}

step PU-2.6 HUMAN "The paging service (row 6, P99)" --sets "PAGER_SERVICE_NAME" --on-unmet skip --note "commit only on P99 (no tracker row yet: see PU-0.1's GAP) and SD-12"
s_PU_2_6_check() { ckpt_done PU-2.6; }
s_PU_2_6_manual() {
  echo "WHO: IT security owns the tool; the platform owner raises; the finance approver signs if a tool is bought."
  echo "WHERE: the procurement system; the paging tool's administration, performed by IT security."
  echo "DO: IT security's own 24x7 on-call tool, or PagerDuty (P99) on Business or higher: role separation per service or team"
  echo "  (Advanced Permissions) and a configuration audit trail (Audit Trail Reporting). IT security creates the service"
  echo "  agentic-platform; escalation, channels and integration keys are file 15's."
  echo "RECORD (typed by you, once the service exists): penv_set PAGER_SERVICE_NAME \"agentic-platform\""
  echo "CHECK: IT security shows the service in the tool, and the plan page shows both capabilities."
  echo "  P99 unsigned or without a tracker row: the tool is quoted, not bought. SAVE: <date>-PU-2.6-paging-contract-v1 (TISAX 1.6; E-10)."
  p04_done_line PU-2.6
}

step PU-2.7 HUMAN "The subject-report escalation (SD-12)" --witness --sets "PAGER_SUBJECT_SERVICE_NAME" --on-unmet skip --note "gate: SD-12"
s_PU_2_7_check() { ckpt_done PU-2.7; }
s_PU_2_7_manual() {
  echo "WHO: IT security creates and administers; the second human verifies alone and witnesses the platform owner's negative test."
  echo "WHERE: the paging tool, each person signed in with their own account."
  echo "DO: IT security creates the subject service (Assumption: agentic-platform-roster-subject), owned by an IT security team;"
  echo "  responders are SD-10's sole recipients. The platform owner holds no administrator, manager or responder role reaching it."
  echo "RECORD (typed by you): penv_set PAGER_SUBJECT_SERVICE_NAME \"<service name created by IT security>\""
  echo "CHECK: IT security's user and team export goes to the second human; the platform owner, watched, cannot see or act on the"
  echo "  subject service; the second human reads its audit trail (creation by IT security, no change by the platform owner)."
  echo "SAVE: <date>-PU-2.7-subject-escalation-roles-v1, signed by IT security and the second human (E-08; TISAX 4.1, 1.6)."
  p04_done_line PU-2.7 "second human"
}

step PU-2.8 HUMAN "Model throughput (row 8, decision 6)" --irreversible --needs "MODEL_ID" --on-unmet skip \
  --note "only after decision 6 (WDEC-6, SD-09) is signed and MODEL_ID is set"
s_PU_2_8_check() { ckpt_done PU-2.8; }
s_PU_2_8_manual() {
  echo "WHO: the platform owner raises; the finance approver signs."
  echo "WHERE: Google Cloud console, the Provisioned Throughput order flow of 'Purchase Provisioned Throughput' (path read on the day)."
  echo "DO: read whether Provisioned Throughput is offered on eu for MODEL_ID ($(if has_value MODEL_ID; then _penv_get MODEL_ID; else echo 'not pinned yet'; fi), 03 DC-8.3);"
  echo "  estimate Stage 0 and Mo-11 volume; decide Standard PayGo is enough (write why) or order Provisioned Throughput on eu."
  echo "IRREVERSIBLE for its term once active: confirm decision 6 signed, retirement at least 6 months after Stage 1, location eu."
  echo "CHECK: the signed 'Standard PayGo is enough' record, or the order active for the model on eu."
  echo "SAVE: <date>-PU-2.8-throughput-decision-v1 (E-11; TISAX 6.1)."
  p04_done_line PU-2.8
}

step PU-2.9 HUMAN "Chrome Enterprise Premium (row 7, P63), runs after PU-2.10" --needs "ORG_ID" --on-unmet skip \
  --note "after PU-2.10; commit only on P63 (no tracker row yet: see PU-0.1's GAP)"
s_PU_2_9_check() { ckpt_done PU-2.9; }
s_PU_2_9_manual() {
  echo "FIRST: PU-2.10 is done (the billing account is open and checked); the trial and the purchase both need it."
  echo "WHO: the purchase is made by an existing organisation-level holder of roles/beyondcorp.admin (IT security), never by the"
  echo "  platform owner or sa-1-admin@; procurement quotes; the finance approver signs."
  echo "READ (the platform owner, then name the principal in the build log; nothing printed: IT security names a holder first):"
  echo "  gcloud organizations get-iam-policy \"$(v ORG_ID)\" --format='table(bindings.role,bindings.members)' --flatten='bindings[].members[]' --filter='bindings.role=\"roles/beyondcorp.admin\"'"
  echo "DO: count one licence per operator and approver on the Tier W+ control surfaces (P63); optionally the 60-day trial; then the"
  echo "  subscription at https://console.cloud.google.com/security/cep/ on the platform billing account. Assignment is 33's."
  echo "CHECK: the purchaser is the printed principal; Admin console, Chrome browser, Reports, Security insights shows the trial or"
  echo "  subscription; the purchased count equals the counted one. SAVE: <date>-PU-2.9-cep-purchaser-v1, <date>-PU-2.9-cep-subscription-v1."
  p04_done_line PU-2.9
}

step PU-2.10 HUMAN "The dedicated platform billing account (row 10, P31, SD-16)" --on-unmet skip --note "commit only on P31 and SD-16"
s_PU_2_10_check() { ckpt_done PU-2.10; }
s_PU_2_10_manual() {
  echo "WHO: finance, as billing administrator, opens or designates the account and runs the check; no billing role is granted here (07)."
  echo "WHERE: Cloud console, Billing, for finance; finance's own shell for the check."
  echo "DO: a dedicated standard Cloud Billing account in EUR under the organisation's payments profile, platform use only; never a"
  echo "  reseller sub-account. Finance runs, and sends the output line to the platform owner:"
  echo "  gcloud billing accounts describe \"<account id>\" --format='value(open,currencyCode,masterBillingAccount,parent)'"
  echo "CHECK: True, EUR, an empty third field, organizations/<ORG_ID>. Another currency, or a non-empty third field: stop the row."
  echo "  The id is recorded as BILLING_ACCOUNT_ID by 07, not here. SAVE: <date>-PU-2.10-billing-account-v1 (TISAX 6.1; E-11)."
  p04_done_line PU-2.10
}

step PU-2.11 HUMAN "Planned-project list for the organisation's project-quota increase (row 10)" --on-unmet skip
s_PU_2_11_check() { ckpt_done PU-2.11; }
s_PU_2_11_manual() {
  echo "WHO: the platform owner writes the list; the billing administrator confirms the billing account it names. Nothing is filed here."
  echo "WHERE: the build log. 07 BA-6.2b files the one request, through Quotas & System Limits (cloudresourcemanager.googleapis.com/projects_count)."
  echo "DO: list the planned projects from the signed names (the five core projects, GEMINI_PROJECT if moved, canary-r, MO_PROJECT,"
  echo "  EVE_PROJECT, EVE_TWIN_PROJECT, WALLE_PROJECT, WALLE_TWIN_PROJECT, the Eve advisor project, the nonprod module runs of 17"
  echo "  and 18: about 20; not the witness project) with the count, the billing account id and the creating identities, for 07 BA-6.1."
  echo "CHECK: the list is in the build log with its count, and 07 BA-6.1 cites it. SAVE: <date>-PU-2.11-planned-projects-v1 (TISAX 1.3)."
  p04_done_line PU-2.11
}

step PU-2.12 CONSOLE "Gemini Enterprise licences and Gmail-bearing seats (row 11)" --on-unmet skip
s_PU_2_12_check() { ckpt_done PU-2.12; }
s_PU_2_12_manual() {
  echo "WHO: the platform owner checks, as the current Gemini Enterprise admin and super admin; procurement buys a shortfall."
  echo "WHERE: Admin console > Billing > Subscriptions; Google Cloud console > Gemini Enterprise > Manage subscriptions and Manage users."
  echo "DO: Gmail-bearing seats for walle@ and eve@ (sa-1-admin@ and sa-2-admin@ are decided in 06; brk-gcp-1@ and -2@ need none);"
  echo "  Gemini Enterprise licences for every member of walle-operators@ and ge-admins@, from 05's inventory; buy the shortfall."
  echo "CHECK: at least two free seats on a Gmail-bearing SKU; enough unassigned licences for the counted people (assignment is 35's)."
  echo "SAVE: <date>-PU-2.12-seats-and-licences-v1 with the counts (TISAX 1.3)."
  p04_done_line PU-2.12
}

step PU-2.13 HUMAN "The git-host plan (row 12, P22 / SD-14)" --on-unmet skip \
  --note "quote now; commit only on P22 and SD-14; done before 03 DC-9.2"
s_PU_2_13_check() { ckpt_done PU-2.13; }
s_PU_2_13_manual() {
  echo "WHO: the platform owner specifies; procurement orders; the finance approver signs; IT security countersigns the rule set."
  echo "WHERE: the procurement system; then the git host's billing page, by the person who will be organisation owner in 03 DC-9.2."
  echo "DO: read GIT_HOST from the signed P22 record. github.com: GitHub Team at least (Enterprise Cloud for SSO and the fuller audit"
  echo "  log); gitlab.com: GitLab Premium at least. Seats for every human who commits or reviews; no approving seat for a bot."
  echo "CHECK, with IT security, before DC-9.2: the plan on the billing page; a private test repository; a saved rule needing two"
  echo "  approvals and code owners on a path; a bot or service-account approval refused (screenshot), or DC-9.9 named as the control."
  echo "  Delete the test repository afterwards."
  echo "SAVE: <date>-PU-2.13-git-host-plan-v1 and <date>-PU-2.13-git-host-rules-proof-v1 (E-05, E-11; TISAX 5.2, 1.6)."
  p04_done_line PU-2.13
}

# ---------------------------------------------------------------- §3 questions to the account team
step PU-3.1 HUMAN "Access Approval's support prerequisite for the witness" --on-unmet skip
s_PU_3_1_check() { ckpt_done PU-3.1; }
s_PU_3_1_manual() {
  echo "WHO: a witness administrator (IT security) asks, in writing."
  echo "WHERE: the Google account team, by email or support case."
  echo "ASK: setup/04 PU-3.1's question: for the witness organisation on WITNESS_DOMAIN, does Access Approval need a Customer Care"
  echo "  subscription bought for that organisation, or does the existing one cover it; is Access Transparency on by default?"
  echo "CHECK: a dated written answer; if Access Approval is unavailable, 08 records W-2's Access Approval as unavailable (SD-28)."
  echo "SAVE: <date>-PU-3.1-access-approval-answer-v1 (TISAX 6.1; E-11)."
  p04_done_line PU-3.1
}

step PU-3.2 HUMAN "An additional invoiced billing account under a second organisation" --on-unmet skip
s_PU_3_2_check() { ckpt_done PU-3.2; }
s_PU_3_2_manual() {
  echo "WHO: finance asks, with a witness administrator copied."
  echo "WHERE: the account team or Cloud Billing support."
  echo "ASK: setup/04 PU-3.2's question: can the existing relationship open an invoiced billing account parented by the witness"
  echo "  organisation, administered only by its administrators; lead time and application; otherwise the approved self-serve route."
  echo "CHECK: a dated written answer, and PU-2.4 step 4 updated with the route and lead time."
  echo "SAVE: <date>-PU-3.2-witness-invoicing-answer-v1 (TISAX 6.1)."
  p04_done_line PU-3.2
}

step PU-3.3 HUMAN "SCC Premium residency activation and lead time, and the Premium Model Armor allowance" --on-unmet skip
s_PU_3_3_check() { ckpt_done PU-3.3; }
s_PU_3_3_manual() {
  echo "WHO: IT security asks; the platform owner writes the answer back into PU-2.3 step 4 and §5."
  echo "WHERE: the account team, in one message."
  echo "ASK: setup/04 PU-3.3's two questions: Premium at organisation level with eu residency needs no activation date scheduled"
  echo "  with the account team (and the subscription lead time); the Model Armor tokens included with organisation-level Premium"
  echo "  on pay-as-you-go, and the overage rate. Nothing about the Enterprise tier, which is deprecated."
  echo "CHECK: a dated answer to both; a scheduled date, if one is needed, recorded for 09; no token figure means PU-2.3's"
  echo "  zero-allowance costing stands, written into §5."
  echo "SAVE: <date>-PU-3.3-scc-residency-answer-v1 (E-11; TISAX 6.1)."
  p04_done_line PU-3.3
}

# ---------------------------------------------------------------- §4 hardware keys and custody
step PU-4.0 HUMAN "Order the custody materials (row 13)" --on-unmet skip
s_PU_4_0_check() { ckpt_done PU-4.0; }
s_PU_4_0_manual() {
  echo "WHO: the platform owner raises with IT security; facilities and procurement order."
  echo "WHERE: the procurement system; facilities for the safe."
  echo "DO: 16 sequentially numbered tamper-evident envelopes in use (4 for 06, 4 for 08, 4 for 21, 2 for walle@, 2 for eve@) and at"
  echo "  least 16 spares; a corporate safe with a sign-out log both custodians can open and IT security can audit, plus a separate"
  echo "  compartment in IT security's area; printed custody forms (01's template if it has one, else a form with PU-4.2's fields,"
  echo "  countersigned by IT security, and 01's owner told). The safe is the long pole: raise it first."
  echo "CHECK: envelopes counted with their number range; the safe installed, its log opened with a dated line, both custodians"
  echo "  tested; forms carry the fields; ticked item by item against 06's precondition list."
  echo "SAVE: <date>-PU-4.0-custody-materials-v1, no key serial (TISAX 3.1; E-08)."
  p04_done_line PU-4.0
}

step PU-4.1 HUMAN "Order the keys" --on-unmet skip --note "the count follows SD-29's signed answer: 22, or 26 with the twin robots"
s_PU_4_1_check() { ckpt_done PU-4.1; }
s_PU_4_1_manual() {
  echo "WHO: the platform owner raises; procurement orders."
  echo "WHERE: the procurement system."
  echo "DO: read SD-29's signed answer on the twin robots' 2SV and order 22 FIDO security keys, or 26 (§4's table); ask for the first"
  echo "  six (sa-1, sa-2, brk-gcp) ahead of the rest if deliveries are split, because 06 needs them first."
  echo "CHECK: the purchase order's quantity equals §4's order line for the SD-29 answer."
  echo "SAVE: <date>-PU-4.1-key-order-v1 (TISAX 3.1)."
  p04_done_line PU-4.1
}

step PU-4.2 HUMAN "Receive the keys and open the inventory" --witness --on-unmet skip
s_PU_4_2_check() { ckpt_done PU-4.2; }
s_PU_4_2_manual() {
  echo "WHO: the platform owner receives; each custodian signs for their keys; a witness from the other administration line signs"
  echo "  every line. The witness administrators receive theirs from procurement directly."
  echo "WHERE: at the safe; the paper custody record."
  echo "DO: per key: label, serial, intended account, custodian, envelope number, date, two signatures. Scan the record the same day"
  echo "  to EVIDENCE_INTERIM_LOCATION (SD-27). Serials live only on custody records and their scans: never in ~/.platform-env,"
  echo "  the build log, the wiki or a ticket."
  echo "CHECK: lines equal the delivered count and the order line; two signatures each; the build log says only"
  echo "  'N keys received, custody record <name>'. SAVE: <date>-PU-4.2-key-custody-record-v1 (TISAX 3.1; E-08)."
  p04_done_line PU-4.2 "other administration line witness"
}

# ---------------------------------------------------------------- §5 costs that sit on no Google Cloud budget
step PU-5.1 HUMAN "File the cost record" --needs "BUILD_LOG_DIR" --on-unmet skip
s_PU_5_1_check() { ckpt_done PU-5.1 || git -C "$(v BUILD_LOG_DIR)" ls-files --error-unmatch costs/outside-gcp-budgets.md >/dev/null 2>&1; }
s_PU_5_1_manual() {
  echo "WHO: the platform owner."
  echo "WHERE: the build-log repository, $(v BUILD_LOG_DIR)."
  echo "DO: commit §5's table, filled with the purchase-record references as they arrive, as costs/outside-gcp-budgets.md;"
  echo "  send it to finance and IT security for their rows. Then record the commit:"
  echo "  evidence_add PU-5.1 cost-record E-11 6.1 \"\$BUILD_LOG_DIR/costs/outside-gcp-budgets.md\" \"\$BUILD_LOG_DIR/costs/outside-gcp-budgets.md\""
  echo "CHECK: every row has an owner and either a purchase-record reference or *tbd* with the step that will fill it."
  echo "This row reads as done once the file is committed (or: agp-platform done PU-5.1)."
}

step PU-5.2 HUMAN "Measure Workspace audit-log volume before P31 sets LOGGING_PROJECT's budget" --needs "ORG_ID" --on-unmet skip
s_PU_5_2_check() { ckpt_done PU-5.2; }
s_PU_5_2_manual() {
  echo "WHO: the owner of organisation-level Cloud Logging, holding roles/logging.privateLogViewer at the organisation; the platform"
  echo "  owner records the numbers and runs nothing."
  echo "WHERE: that person's own shell, with no ~/.platform-env. Only if 'Share data with Google Cloud services' is on; otherwise"
  echo "  record 'not measurable on <date>' and re-run it from 14."
  echo "HAND OVER: the organisation id $(v ORG_ID) (not a secret), with a build-log line 'ORG_ID handed to <role> for PU-5.2 on <date>'."
  echo "DO: setup/04 PU-5.2's block: the ORG guard, four one-day counts (admin, cloudidentity, login, oauth2) and one compact byte"
  echo "  sample; nothing stored. Record the method: gcloud's jq -c upper bound, or the metered logging.googleapis.com/billing/bytes_ingested."
  echo "CHECK: four counts, one byte figure and its method, written into P31's input record. SAVE: <date>-PU-5.2-workspace-log-volume-v1."
  p04_done_line PU-5.2
}
