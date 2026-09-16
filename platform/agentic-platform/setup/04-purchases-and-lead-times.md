# 4. Purchases and lead times

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-15
- What this is: the one purchase list for the agentic platform, Mo, Eve and Wall-E, sorted by lead time, longest first. Each row names who raises it, who buys and approves it, the file and gate it blocks, and the check that proves the item is in hand. It is stage 3 of the set ([README](README.md)) and runs from day one, in parallel with [03](03-decisions-and-people.md) and [05](05-gemini-enterprise-inventory.md).
- It replaces: the unsorted lists in [../../wall-e/PREREQUISITES.md](../../wall-e/PREREQUISITES.md) §3.1 and §9, the day-one items of [../brief/29-roadmap-and-cost.md](../brief/29-roadmap-and-cost.md) and the cost lines of [../01-hld.md](../01-hld.md) §0.5, which now point here. The key count of PREREQUISITES §3.1 and 04 §8.3 is superseded by §4 below.
- Step prefix: `PU`. Steps: 22. Steps marked BLOCKED: none (no step here needs code that does not exist).
- Review findings closed here (from [../13-setup-procedure-review.md](../13-setup-procedure-review.md)): S003 (the purchase half; activation is [09](09-folders-and-security-command-center.md), the SIEM feed is [15](15-pager-siem-and-detections.md)), S083 (the purchase and key-count half; the prerequisites table is [01](01-prerequisites-and-conventions.md)), X-ORG-04, X-ORG-08, X-RQB-06, X-RQB-07, X-RQB-09. §8 says how each is closed.
- Google facts on this page were read on 2026-09-15; the sources are listed at the end. Vendor lead times (MDR, penetration test, paging tool, keys) are `Assumption:` values, never Google facts.

## What this part builds

Nothing in Google Cloud or Workspace. It gets into hand everything that is bought, contracted, registered or answered by someone outside the platform line, early enough that no later file waits on a purchase order:

- the contracts and payers the tier gates need (SIEM and MDR, penetration test, SCC Premium);
- the two domains that start two other organisations: `SANDBOX_DOMAIN` for the sandbox Workspace tenant and `WITNESS_DOMAIN` for the witness Cloud Identity organisation;
- the witness organisation's own billing path and support subscription, approved and ready for [08](08-witness-organisation.md) to open;
- the paging service `PAGER_SERVICE_NAME` and the separate escalation for reports whose subject is a roster human, `PAGER_SUBJECT_SERVICE_NAME`, administered by IT security with the platform owner holding no administrator or responder role on it (SD-12);
- Chrome Enterprise Premium, Gemini Enterprise licences, Gmail-bearing seats, and model throughput if decision 6 needs it;
- the dedicated platform billing account in hand and the project-quota request filed;
- the git-host plan that [03](03-decisions-and-people.md) DC-9 needs, because protected branches and code owners on a private repository are a paid feature on both candidate hosts;
- the hardware keys, counted once and correctly, with an inventory whose serials live only in custody records, and the envelopes, spare envelopes, safe and custody forms that [06](06-organisation-bootstrap-and-roster.md) requires at its first sitting;
- three written answers from the Google account team;
- the costs that sit on no Google Cloud budget, each with an owner and a purchase record.

What it does not do: activate SCC (09), open the witness organisation or its billing account (08), sign up the sandbox tenant or add its TXT and MX records (21), grant billing roles or read the currency (07), create paging escalations, channels or integration keys (15), enrol any key (06, 08, 21, 24, 30, 37).

## Preconditions

A quote, a question or a domain-availability search may start before any signature. An order, a contract or a registration waits on the decision named in its step.

- [ ] [01](01-prerequisites-and-conventions.md) done: `~/.platform-env` exists with `penv_set` and `need`; `BUILD_LOG_DIR`, `EVIDENCE_INTERIM_LOCATION`, `EVIDENCE_REGISTER`, `PLATFORM_REPO_DIR` set. `PLATFORM_REPO_DIR` is needed because PU-0.1 calls `tools/decision-need.sh`, written by [03](03-decisions-and-people.md) DC-1.2.
- [ ] From [03](03-decisions-and-people.md), signed or dated as pending in its tracker:
  - [ ] P10 (SIEM: `SIEM_KIND`) and the MDR partner, signed by IT security.
  - [ ] P11 / SD-15 (SCC Premium: `SCC_BILLING_MODEL` and the payer), signed by IT security and finance.
  - [ ] P14 / SD-28 (the witness: domain, edition, billing, the two witness administrators), signed by IT security; `WITNESS_ADMIN_1_EMAIL`, `WITNESS_ADMIN_2_EMAIL` set.
  - [ ] P31 / SD-16 (the dedicated platform billing account), signed by the owner and finance; `BILLING_ADMIN_EMAIL` set.
  - [ ] Decision 29 / SD-29 (sandbox before the grant, edition, whether the twin robots use hardware-key 2SV); `SANDBOX_SA_1_EMAIL`, `SANDBOX_SA_2_EMAIL` set.
  - [ ] Decision 6 / SD-09 (model pin), only for PU-2.8.
  - [ ] SD-12 (the subject-report escalation), co-signed by the second human; `SECOND_HUMAN_EMAIL`, `INCIDENT_COMMANDER_EMAIL` set.
  - [ ] P63 (the Chrome Enterprise Premium licence count: one per operator and approver on the Tier W+ control surfaces), signed by the platform owner and IT security. Gates PU-2.9 only.
  - [ ] P99 (the paging tool), signed by IT security. Gates PU-2.6 only.
  - [ ] P22 / SD-14 (the git host), signed by the platform owner and IT security, so PU-2.13 can buy the plan [03](03-decisions-and-people.md) DC-9 needs.
  - [ ] The penetration-test window (G8) recorded.
- [ ] The workstation shell rules of 01 hold: no default gcloud project.

**Precondition gap to close in 03, not here.** `decisions/TRACKER.md`, written by [03](03-decisions-and-people.md) DC-1.3 from §5 and §11 of that file, has rows for P10, P11, P22 and P31 but **no row for P63 and none for P99**: 03 §11.5 does not list them, so `tools/decision-need.sh P63 P99` fails on a missing tracker row rather than on an unsigned decision. Before PU-2.6 or PU-2.9 commits, the platform owner adds the two rows to the tracker under DC-1.3's rule and signs the records under DC-1.4. Until the rows exist, PU-0.1 records the gap and neither purchase is committed. Owner: platform owner with IT security.

## People

| Role | What they do here | Second person |
|---|---|---|
| Platform owner | Raises every request, keeps the table, runs the read-only checks, records variables and evidence | — |
| Procurement | Issues quotes and purchase orders, holds contracts | — |
| Finance (billing administrator and finance approver) | Approves spend; opens or designates the platform billing account; signs the SCC payer | the finance approver signs every order above the delegated limit (`Assumption:` the organisation's usual rule) |
| IT security | Buys and owns SecOps or the SIEM contract, the MDR retainer, the penetration test, every witness purchase, the paging tool and the subject-report escalation | — |
| The two witness administrators (IT security) | Register the witness domain in a registrar account they alone administer | — |
| The second human | Confirms, without the platform owner's help, that he holds no role on the subject-report escalation (PU-2.7) | witnesses PU-2.7 |
| Key custodians | Receive keys and sign the inventory (PU-4.2) | a witness from the other administration line |
| The existing organisation-level administrator holding `roles/beyondcorp.admin` (IT security) | Performs the Chrome Enterprise Premium trial and purchase (PU-2.9); the platform owner does not | — |
| The owner of organisation-level Cloud Logging | Runs the volume measurement in their own shell from a handed-over organisation id (PU-5.2) | — |
| Facilities | Delivers and installs the safe with its sign-out log (PU-4.0) | — |

No other second person is needed in this part.

## 1. The purchase table, longest lead time first

Start every row on day one. "Start" is what may happen before the decision; "Commit" is the gate for signing. Lead times marked `Assumption:` are vendor estimates to be replaced by the quote's own figure.

| # | Item | Lead time | Start / commit gate | Raised by; bought by; approved by | Blocks (file, gate) | Item in hand when | Step |
|---|---|---|---|---|---|---|---|
| 1 | Google SecOps in the EU (Europe multi-region, P93) or the organisation's SIEM measured against the S1-S9 contract (P92), plus the MDR retainer with 24x7 acknowledgement | months (`Assumption:` sales, DPA, retainer) | quote now; commit on P10 | platform owner; IT security; finance approver | [15](15-pager-siem-and-detections.md) part B; Tier P, gate line G2 | signed order with EU region and retention of at least 400 days, and a signed retainer with the §9.2 targets | PU-2.1 |
| 2 | Penetration test: scoped test before the first Tier W Stage 1, full test before the grant | weeks to months (`Assumption:` vendor calendar) | quote now; commit on the G8 window | platform owner; IT security; finance approver | [37](37-wall-e-sandbox-rehearsal.md); G8 | signed statement of work with window and scope | PU-2.2 |
| 3 | SCC Premium at organisation level: pay-as-you-go (billed to every project's billing account in the organisation) or the subscription contract (12 months minimum, 15,000 USD a year minimum) | subscription: weeks; pay-as-you-go: finance notice to every cost-centre owner | ask now; commit on P11 / SD-15 | platform owner; IT security; finance | [09](09-folders-and-security-command-center.md); Tier C | signed payer record, and for the subscription a countersigned order | PU-2.3 |
| 4 | Witness: a separately registered domain outside the tenant's reach; approval of a billing account parented by the witness organisation; a Customer Care subscription for the witness organisation | weeks (billing path answer; domain registration days) | search now; commit on P14 / SD-28 | IT security (witness administrators); procurement; finance approver | [08](08-witness-organisation.md) W-1, W-2; custody records home (SD-27); G-2; the grant | domain registered and locked; billing path and support approved in writing | PU-2.4, PU-3.1, PU-3.2 |
| 5 | Sandbox Workspace tenant: edition equal to production and at least Enterprise Standard, its own domain (TXT and MX added in 21), seats, two sandbox super admins | weeks (`Assumption:` second customer contract through the reseller or account team; a domain removed from another account waits 24 hours, or 7 days through a reseller) | search now; commit on decision 29 / SD-29 | platform owner; procurement; finance approver | [21](21-sandbox-tenant-and-nonprod-foundation.md); Eve drills in [28](28-eve-independent-proof-and-sandbox-drills.md); G10, G11, G14, G-7 | domain registered with DNS access for 21; order with edition and seat count | PU-2.5 |
| 6 | The organisation paging service and the subject-report escalation (SD-12) | weeks if a tool must be bought (`Assumption:`); days if IT security operates one | now; commit on P99 and SD-12 | platform owner; IT security; finance approver | [15](15-pager-siem-and-detections.md) part A; [26](26-eve-reporting-and-witness-export.md) route 1 (SD-08 fallback until then) | tool contracted with role separation and an audit trail; both service names reserved; the platform owner proven absent from the subject escalation | PU-2.6, PU-2.7 |
| 7 | Chrome Enterprise Premium licences, one per operator and approver (P63) | weeks (`Assumption:` procurement); a 60-day trial for up to 5,000 users is available at once, but Google requires valid payment details even for the trial | quote now; commit on P63 **and after row 10**, because both the trial and the purchase need a billing account | platform owner; procurement; finance approver | [33](33-wall-e-action-services-and-approval-surfaces.md) (`al-platform-operator`, `-lite` until then); Tier W | subscription active for the licensed count | PU-2.9, run after PU-2.10 |
| 8 | Model throughput (Provisioned Throughput on `eu`), only if decision 6 needs it | minutes to weeks (Google: depends on the order size and capacity) | only after decision 6 | platform owner; finance approver | [35](35-wall-e-engine-registration-and-gateways.md); [40](40-mo-after-stage-0.md); Stage 0 | order active, or a signed "Standard PayGo is enough" record | PU-2.8 |
| 9 | Hardware security keys, 22 or 26 with spares (§4) | days to weeks (`Assumption:` procurement and delivery) | order now | platform owner; procurement | [06](06-organisation-bootstrap-and-roster.md) first (6 keys), then 08, 21, 24, 30, 37 | keys received, inventory signed, serials in custody records only | PU-4.1, PU-4.2 |
| 10 | The dedicated platform billing account (standard, not a reseller sub-account; EUR) and a project-quota request for about 20 projects | days; quota requests typically within 2 business days, possibly with a payment | now; commit on P31 / SD-16 | platform owner; finance (billing administrator) | [07](07-billing-account.md), [10](10-core-projects-and-ci-identities.md); stage 5 | account open and designated; quota request reference recorded | PU-2.10, PU-2.11 |
| 11 | Gemini Enterprise licences for operators and administrators; Gmail-bearing seats for `walle@`, `eve@` (the twin robots' seats are row 5) | days if seats must be bought; none if free seats exist | now | platform owner; procurement | [24](24-eve-workspace-identity-and-audit-feeds.md) (`eve@`), [30](30-wall-e-workspace-side.md) (`walle@`), [35](35-wall-e-engine-registration-and-gateways.md) (share verify) | free seats and licences shown in the consoles | PU-2.12 |
| 12 | Git-host plan for **private** repositories with protected branches, required reviewers and code owners on the control files (P22 / SD-14) | weeks (`Assumption:` procurement and the host's own provisioning); days if the organisation already holds an eligible plan | quote now; commit on P22 / SD-14 | platform owner; procurement; finance approver | [03](03-decisions-and-people.md) DC-9.2 to DC-9.7 (the repository and its rules); [06](06-organisation-bootstrap-and-roster.md) (the roster merge needs the second human as required reviewer); [16](16-register-and-shared-registry.md) | a private repository exists on the bought plan in which a ruleset or approval rule enforces two human approvals with code owners, and an approval given by a bot or service account does not satisfy it | PU-2.13 |
| 13 | Physical custody materials: tamper-evident envelopes, spare envelopes for re-sealing, a corporate safe with a sign-out log, printed custody forms | days to weeks (`Assumption:` facilities and stationery supply; a safe that must be installed is the long pole) | order now | platform owner with IT security; facilities and procurement | [06](06-organisation-bootstrap-and-roster.md) preconditions (four sealed envelopes plus at least four spares, the safe, the forms), then 08, 21, 24, 30 | materials received and counted against the 06 precondition list; the safe installed with its sign-out log opened | PU-4.0 |

Rows 12 and 13 were added after the first sort and keep the numbering of rows 1-11, which later files, §5 and §8 cite. Their lead times place row 12 between rows 5 and 9, and row 13 between rows 9 and 10.

**The table's order is not the execution order of §2.** §1 sorts by lead time so that nothing waits on a purchase order; §2 runs in a dependency order. The one place they differ: **PU-2.9 (row 7) runs after PU-2.10 (row 10)**, because Chrome Enterprise Premium is purchased in the Cloud console against a billing account and Google requires valid payment details even to start the 60-day trial. Quoting row 7 still starts on day one.

The account-team questions (§3) and the cost records (§5) run alongside rows 1-4.

## 2. Purchase steps

Every shell step runs in the shell with `~/.platform-env` sourced, per 01 — **except PU-5.2**, which is performed by someone outside the platform line who has no variables file; that step says how its one value is handed over. Contracts, quotes and prices are commercial records: they go to `EVIDENCE_INTERIM_LOCATION` (restricted), and the build log holds only their reference.

The steps are numbered from §1's lead-time order, so they are not in execution order. Read this before working top to bottom: **PU-2.9 is performed after PU-2.10**, and its own preconditions repeat that. Every other step may be raised on day one in the order printed.

### PU-0.1 Confirm the inputs from 03

- **WHO:** platform owner. No witness.
- **WHERE:** shell with `~/.platform-env` sourced.
- **ACTION:**

```bash
need SIEM_KIND SCC_BILLING_MODEL BILLING_ADMIN_EMAIL SECOND_HUMAN_EMAIL INCIDENT_COMMANDER_EMAIL
need WITNESS_ADMIN_1_EMAIL WITNESS_ADMIN_2_EMAIL SANDBOX_SA_1_EMAIL SANDBOX_SA_2_EMAIL
"$PLATFORM_REPO_DIR/tools/decision-need.sh" P10 P11 SD-15 P14 SD-28 P31 SD-16 WDEC-29 SD-29 SD-12 P22 SD-14
"$PLATFORM_REPO_DIR/tools/decision-need.sh" P63 P99 || echo "GAP: P63 and/or P99 have no signed record; PU-2.9 and PU-2.6 may quote but not commit"
```

  The second `decision-need.sh` line is written with `|| echo` on purpose: on 2026-09-15 neither P63 nor P99 has a row in 03's tracker (see the precondition gap above), so a hard failure here would stop every other row for two purchases that are only quoted on day one.

- **VERIFY:** the two `need` lines and the first `decision-need.sh` line return without error. A failure names the empty or `*tbd*` variable, or the unsigned decision: start the quotes and questions for that row, and do not commit it. If the second line prints `GAP`, record which of P63 and P99 is missing and carry it into PU-2.6 and PU-2.9 as an uncommitted row.
- **ROLLBACK:** none needed (read-only).
- **EVIDENCE:** a build-log checkpoint for PU-0.1 listing which decisions were signed on the day, and the `GAP` line verbatim if it printed (`EVIDENCE_REGISTER`; E-05; TISAX 1.1-1.2).

### PU-2.1 SIEM and MDR retainer (row 1, P10)

- **WHO:** IT security buys; the platform owner raises the request and supplies the contract; the finance approver signs.
- **WHERE:** procurement system; the Google account team for SecOps, or the organisation's SIEM owner.
- **ACTION:**
  1. The platform owner sends IT security the S1-S9 contract of [../07-monitoring-detection-incident-response.md](../07-monitoring-detection-incident-response.md) §2.1 and the acknowledgement targets of §9.2 as the requirement.
  2. If `SIEM_KIND` is `secops`: IT security orders Google SecOps with the Europe multi-region (P93) and retention of at least 400 days (S2). Google SecOps data residency is always on and cannot be disabled.
  3. If `SIEM_KIND` is `existing`: IT security measures the organisation's SIEM against S1-S9 and signs the result, naming any clause it fails.
  4. IT security signs an MDR retainer covering the super-admin detection set SA-01..SA-09 and SG-01..SG-07, with 24x7 acknowledgement of severity 1.
- **VERIFY:** the order form (or the signed S1-S9 assessment) shows the EU region and the retention term; the retainer shows the 24x7 severity-1 acknowledgement. The platform owner ticks row 1 only on sight of both documents, not on a statement that they exist.
- **ROLLBACK:** before signature, withdraw the request. After signature: **IRREVERSIBLE** for the contract term. Confirm before signing: P10 signed by IT security, the region and retention lines match P93 and S2, and the DPA is signed. Gate: P10.
- **EVIDENCE:** order form and retainer references in `EVIDENCE_INTERIM_LOCATION`, named `<date>-PU-2.1-siem-order-v1` and `<date>-PU-2.1-mdr-retainer-v1` (E-11 supplier file; TISAX 6.1, 1.6).

### PU-2.2 Penetration test (row 2, G8)

- **WHO:** IT security buys; platform owner raises; finance approver signs.
- **WHERE:** procurement system.
- **ACTION:**
  1. Scope in the statement of work: the Tier W control surfaces behind IAP, the Wall-E action services and approval surfaces on the sandbox twin, the Eve export path, and the platform's organisation-policy and PAM configuration; a scoped test before the first Tier W Stage 1 and the full test before the super-admin grant.
  2. Rules of engagement: tests touch only the organisation's own projects and the sandbox tenant. Google does not require notice of a penetration test of the customer's own Google Cloud projects, provided the Acceptable Use Policy and Terms of Service are kept and other customers are unaffected.
  3. Window: the G8 window recorded in 03.
- **VERIFY:** a signed statement of work carrying the scope, both windows and the tester's named contact.
- **ROLLBACK:** cancellation under the vendor's terms; record the date. Commitment is **IRREVERSIBLE** only as far as the vendor's cancellation fee; confirm the fee before signing. Gate: the G8 window in 03.
- **EVIDENCE:** `<date>-PU-2.2-pentest-sow-v1` (TISAX 5.2; E-03). The report itself is evidence of file 37.

### PU-2.3 SCC Premium payer or contract (row 3, P11, SD-15)

- **WHO:** IT security and finance decide and buy; platform owner raises. Finance approver signs.
- **WHERE:** finance approval record; the Google account team for the subscription.
- **ACTION:**
  1. Put both options to IT security and finance in writing, with Google's terms of 2026-09-15:
     - pay-as-you-go at organisation level: Google's wording is that Premium tier pay-as-you-go pricing for an organisation bases charges on usage of Google Cloud services, "with your usage charged to the billing accounts associated with the projects in your organization". So every existing cost centre sees a surcharge. It needs finance's signature and a notice to each cost-centre owner. The platform budget line cannot carry it.
     - subscription: a sales contract, minimum annual cost 15,000 USD, minimum term 12 months.
  2. Record the choice in `SCC_BILLING_MODEL` (set in 03) and the payer's name.
  3. If pay-as-you-go: finance sends the cost-centre notice. If subscription: IT security signs the order.
  4. Record the Model Armor allowance the chosen model carries, because it changes the Model Armor bill of `GEMINI_PROJECT` (SD-15). What Google's pricing pages state, read on 2026-09-15:
     - a **Premium subscription** includes 3 billion Model Armor tokens a month, then 0.10 USD per million tokens;
     - **standalone Model Armor**, bought outside Security Command Center, is free up to 2 million tokens a month, then 0.10 USD per million tokens.

     The allowance carried by **organisation-level Premium on pay-as-you-go** is *tbd*: it is not stated as retrievable text on either page. Do not assume it is the 2 million figure, which is the standalone allowance. PU-3.3 asks the account team for it, and the answer is written back into this step and into §5 before P11 is signed. If P11 must be signed before the answer arrives, the pay-as-you-go option is costed with a **zero** included allowance, which is the conservative reading.
  5. If P11 chooses the Enterprise tier instead (P94 does not), see PU-3.3 before anything else.
- **VERIFY:** a signed payer record naming the model and the payer; for pay-as-you-go, the dated notice to cost-centre owners; for the subscription, a countersigned order. Activation with `eu` residency is file 09's step, not this one.
- **ROLLBACK:** pay-as-you-go: none until 09 activates. Subscription: **IRREVERSIBLE** for 12 months. Confirm before signing: P11 signed by IT security and finance, and P94's tier (Premium) and residency (`eu`) are what the order names. Gate: P11 / SD-15.
- **EVIDENCE:** `<date>-PU-2.3-scc-payer-v1` and, if bought, `<date>-PU-2.3-scc-order-v1` (E-11; TISAX 6.1).

### PU-2.4 Witness domain and billing path (row 4, P14, SD-28)

- **WHO:** the two witness administrators (IT security) perform; procurement and the finance approver approve the billing path and the support subscription. The platform owner performs nothing except PU-2.4's last variable line, from the name handed over.
- **WHERE:** a registrar account and DNS provider that IT security alone administers, outside the tenant's Google Cloud organisation and outside the Digital Workplace line; then the tenant shell for the variable.
- **ACTION:**
  1. The witness administrators choose a domain that is separately registered (not a subdomain of any tenant domain) and not attached to any Google account.
  2. They register it in their registrar account, turn on 2SV on that account, and set the registrar lock. The DNS provider account has the same two administrators and no tenant principal.
  3. They record the registrar and DNS custodians as witness roles.
  4. Billing path: the shared or platform billing account is excluded, because a tenant Organization Administrator can reach Billing Account Administrator on any account the tenant organisation owns and close it or unlink the witness project, and because linking would need a cross-organisation grant the witness design forbids. The witness uses a billing account whose parent is the witness organisation, administered only by the witness administrators. Finance approves the payment route after PU-3.2's answer (invoiced, which Google documents as needing business registration of at least a year, expected spend of at least 40,000 USD a year and country availability, or self-serve).
  5. Support: procurement approves a Customer Care subscription (Standard or higher) for the witness organisation resource once it exists, because Access Approval is included with Standard, Enhanced and Premium Support and the tenant's subscription is bought for the tenant's organisation resource. PU-3.1 records Google's answer.
  6. The platform owner records the name only:

```bash
penv_set WITNESS_DOMAIN "<domain handed over by the witness administrators>"
```

- **VERIFY:**

```bash
whois "$WITNESS_DOMAIN" | grep -iE 'Registrar:|Domain Status:'
dig +short NS "$WITNESS_DOMAIN"
```

  `Registrar:` names the registrar IT security chose; `Domain Status:` includes `clientTransferProhibited`; the name servers belong to the DNS provider recorded in step 2. A witness administrator confirms in writing that the registrar and DNS accounts have 2SV on and list only the two witness administrators. Finance's written approval of the billing route and procurement's approval of the support subscription are on file.
- **ROLLBACK:** a registered domain is kept (letting it lapse would hand a recovery path to whoever registers it next). The variable is corrected only with `penv_set --force` and a build-log line.
- **EVIDENCE:** `<date>-PU-2.4-witness-domain-v1` (registrar, lock state, custodians; no credential), `<date>-PU-2.4-witness-billing-approval-v1` (E-06 witness copy; TISAX 6.1, 4.1). The witness administrators also keep the record for upload at W-2 (SD-27).

### PU-2.5 Sandbox Workspace tenant (row 5, decision 29, SD-29)

- **WHO:** platform owner raises and specifies; procurement orders through the reseller or account team; the finance approver signs; the organisation's domain owner registers the domain.
- **WHERE:** procurement system; the corporate registrar; tenant shell for the variable.
- **ACTION:**
  1. Specify the order from SD-29, and write the reasons into it so no one buys a cheaper edition:
     - edition equal to production (`WORKSPACE_EDITION`, 01) and never below Enterprise Standard: multi-party approval exists only on Enterprise Standard and Plus, Education Standard and Plus and Enterprise Essentials Plus; Essentials editions carry no Gmail, which the twins' Gmail scopes need; OAuth and SAML log sharing to Google Cloud and the SecOps export need Enterprise Standard or Plus. Enterprise Plus if G-4's Access Transparency stream is drilled.
     - seats: `walle@SANDBOX_DOMAIN` and `eve@SANDBOX_DOMAIN` (the twin robots), the two sandbox super admins, and *tbd* synthetic accounts (`Assumption:` three to four, as SETUP §1.4 planned).
     - two named sandbox super admins, `SANDBOX_SA_1_EMAIL` and `SANDBOX_SA_2_EMAIL` (03). Multi-party approval needs two or more super admin accounts, and G14 needs a requester and a different approver, so the platform owner cannot build or drill the twin alone.
     - the person entitled to accept Google Cloud terms for the sandbox organisation, named in the order.
     - P59 closed in 03 as "no sandbox Gemini Enterprise app; the twin engine is called directly", or the app licence added here.
  2. The domain owner registers a separate domain (`Assumption:` not a subdomain of a production domain, so it cannot collide with the production account's verification), not attached to any Google account, with DNS the sandbox super admins can edit for the TXT and MX records of file 21 (MX `smtp.google.com`, priority 1).
  3. Record the name:

```bash
penv_set SANDBOX_DOMAIN "<registered sandbox domain>"
```

- **VERIFY:**

```bash
whois "$SANDBOX_DOMAIN" | grep -iE 'Registrar:|Creation Date:|Domain Status:'
dig +short NS "$SANDBOX_DOMAIN"
dig +short TXT "$SANDBOX_DOMAIN"
```

  The domain is registered to the organisation; the name servers are the provider the sandbox super admins can edit; the TXT output has no `google-site-verification` value (a value here means another Google account may already hold it: stop and ask the domain owner). The signed order shows the edition, the seat count and the terms signer.
- **ROLLBACK:** before sign-up in 21, the order can be cancelled under the reseller's terms. After signature: **IRREVERSIBLE** for the plan's commitment (`Assumption:` annual or flexible plan, as the order says). Confirm before signing: decision 29 reads "before the super-admin grant", SD-29 signed, the edition line is not below Enterprise Standard. Gate: decision 29 / SD-29.
- **EVIDENCE:** `<date>-PU-2.5-sandbox-order-v1`, `<date>-PU-2.5-sandbox-domain-v1` (E-04 test environment; TISAX 5.2, 1.3).

### PU-2.6 The paging service (row 6, P99)

- **WHO:** IT security owns the tool; platform owner raises; finance approver signs if a tool is bought.
- **WHERE:** procurement system; the paging tool's administration, performed by IT security.
- **ACTION:**
  1. IT security states whether it operates an incident and on-call tool with 24x7 paging. If yes, that tool is used; if no, PagerDuty is bought (P99).
  2. The plan or tool must offer (a) role separation per service or team, so that a user can be excluded from administering or responding to one service while responding on another, and (b) an audit trail of configuration changes. On PagerDuty this means Advanced Permissions (Professional, Business, Enterprise for Incident Management or Digital Operations legacy plans) and Audit Trail Reporting, which needs Business, Enterprise for Incident Management or Digital Operations (legacy). So the PagerDuty plan bought is Business or higher.
  3. IT security creates the organisation-owned service named `agentic-platform` (escalation, channels and integration keys are file 15).
  4. Record the name:

```bash
penv_set PAGER_SERVICE_NAME "agentic-platform"
```

- **VERIFY:** IT security shows the service in the tool (PagerDuty: Services, Service Directory, the service is listed) and the contract or plan page shows a plan with both capabilities of step 2.
- **ROLLBACK:** the service can be deleted by IT security before file 15 wires it; the contract follows the vendor's terms. If no tool is contracted when Eve goes live, file 26 uses SD-08's temporary route 1 (Cloud Monitoring email and SMS channels in `EVE_PROJECT` to the second human) as a dated deviation. Gate: P99 (signed by IT security) and SD-12. If PU-0.1 printed `GAP` for P99, the tool is quoted but not bought until the record is signed and its tracker row exists.
- **EVIDENCE:** `<date>-PU-2.6-paging-contract-v1` (TISAX 1.6; E-10).

### PU-2.7 The subject-report escalation (SD-12)

- **WHO:** IT security creates and administers; the second human verifies alone; the platform owner performs the negative test with the second human watching. Witness: the second human.
- **WHERE:** the paging tool, each person signed in with their own account; tenant shell for the variable.
- **ACTION:**
  1. IT security creates a second service, `PAGER_SUBJECT_SERVICE_NAME`, for every report whose subject is a roster human (`Assumption:` name `agentic-platform-roster-subject`). It is owned by an IT security team. Its responders are the sole recipients of SD-10: the second human for reports about the platform owner; the security reviewer, or the incident commander until the security reviewer is appointed, for reports about the second human.
  2. The platform owner holds no administrator, manager or responder role on it, and no account-wide administrator role that reaches it. On PagerDuty: his base role is not Account Owner or Global Admin; he is on no team that owns the subject service; with Restricted Access as base role he sees only objects of the teams he belongs to.
  3. The second human and the security reviewer (or incident commander) are not given any administrator role on the `agentic-platform` service that would let them silence route 1 either, beyond what 15 assigns.
  4. Record the name:

```bash
penv_set PAGER_SUBJECT_SERVICE_NAME "<service name created by IT security>"
```

- **VERIFY:**
  1. IT security exports the user and team list and hands it to the second human, not to the platform owner. It shows the platform owner's base role and teams; none reaches the subject service.
  2. The platform owner signs in to the tool with his own account while the second human watches, and opens the service directory. The subject service is not listed, or opening it offers no edit or acknowledge action.
  3. The second human opens the subject service's audit trail (PagerDuty: Services, Service Directory, the service, More, View Audit Trail Reporting) and sees its creation by IT security and no change by the platform owner.
- **ROLLBACK:** IT security removes the service; the variable is corrected with `penv_set --force` and a build-log line. Until the escalation exists, file 26 is not started for reports about roster humans (SD-10).
- **EVIDENCE:** `<date>-PU-2.7-subject-escalation-roles-v1`, signed by IT security and the second human (E-08 oversight roster; TISAX 4.1, 1.6). The configuration-change log route to the second human is file 15's step.

### PU-2.8 Model throughput (row 8, decision 6)

- **WHO:** platform owner raises; finance approver signs. Runs only after decision 6 is signed.
- **WHERE:** Google Cloud console, the Provisioned Throughput order flow of Google's "Purchase Provisioned Throughput" page (console path to be read on the day; the page did not render its steps on 2026-09-15).
- **ACTION:**
  1. From the pinned model's page, read on the pin date whether Provisioned Throughput is offered on the `eu` multi-region for `MODEL_ID`.
  2. Estimate Stage 0 and Mo-11 volume. Standard PayGo is an organisation-level usage tier; clients retry with backoff on 429 (SD-09).
  3. Decide: Standard PayGo is enough (write why), or order Provisioned Throughput on `eu`. Google states processing takes from a few minutes to a few weeks depending on the size of the order and available capacity.
- **VERIFY:** `need MODEL_ID` passes; either the signed "Standard PayGo is enough" record exists, or the order shows status active for `MODEL_ID` on `eu`.
- **ROLLBACK:** before the order is active, cancel it in the same flow. An active order: **IRREVERSIBLE** for its term. Confirm before ordering: decision 6 signed, the model's retirement date at least 6 months after Stage 1, the location `eu`. Gate: decision 6 / SD-09.
- **EVIDENCE:** `<date>-PU-2.8-throughput-decision-v1` (E-11; TISAX 6.1).

### PU-2.9 Chrome Enterprise Premium (row 7, P63) — runs after PU-2.10

**Preconditions, both checked before the request is raised:**

- [ ] **PU-2.10 is complete:** the dedicated platform billing account is open and designated, its check output reads `True`, `EUR`, empty, `organizations/<ORG_ID>`, and its id is on file with finance. Both the purchase and the 60-day trial are made in the Cloud console against a billing account, and Google requires valid payment details even for the trial. Without PU-2.10 this step cannot be performed at all.
- [ ] **A named holder of Cloud BeyondCorp Admin exists today.** Google requires `roles/beyondcorp.admin` **at the organisation level** to buy Chrome Enterprise Premium. This file runs at stage 3, before [06](06-organisation-bootstrap-and-roster.md) exists, and `sa-1-admin@` is not created until then; [06](06-organisation-bootstrap-and-roster.md) OB-3.7 grants exactly four organisation roles to `sa-1-admin@` (`organizationAdmin`, `folderCreator`, `projectCreator`, `privilegedaccessmanager.admin`) and says "No other role is granted", and no file from 06 to 12 grants `roles/beyondcorp.admin` to anyone. So the purchaser here is **an existing organisation-level administrator of the tenant's Google Cloud organisation** — in practice the IT security administrator who already holds Organization Administrator, named in the build log before the request is raised. The platform owner does not grant himself the role to make this step work; if nobody holds it, IT security grants it to one of its own named administrators and records that grant, and file 12 is not affected because the grant is not on a platform principal.

- **WHO:** procurement quotes; **the purchase itself is performed by the named existing organisation-level administrator identified by the check below** (IT security), not by the platform owner and not by `sa-1-admin@`; the finance approver signs. No witness.
- **WHERE:** the platform owner's shell for the check; then Google Cloud console, `https://console.cloud.google.com/security/cep/`, Subscribe or Purchase, by the named administrator; then the Admin console for the status read.
- **ACTION:**
  1. Establish who may buy. The platform owner runs the read below and records the named principal in the build log; if it prints nothing, the request stops here and IT security names a holder first.

```bash
need ORG_ID
gcloud organizations get-iam-policy "$ORG_ID" --format='table(bindings.role,bindings.members)' --flatten='bindings[].members[]' --filter='bindings.role="roles/beyondcorp.admin"'
```

  2. Count one licence per operator and approver on the Tier W+ control surfaces (P63); record the count and the names it was counted from.
  3. Optionally start the 60-day trial (Google: 60 days for up to 5,000 users at no cost, "you won't be charged, but our systems require valid payment details") so file 33 can test `al-platform-operator` before the purchase completes. The trial is started by the same named administrator, against the billing account of PU-2.10.
  4. Purchase the subscription for the counted licences on the platform billing account (HLD §0.5 payer: platform). Purchasing makes licences available but does not assign them; assignment is file 33.
- **VERIFY:**
  1. The command of action 1 printed at least one principal, and that principal is the person who performed actions 3 and 4.
  2. Admin console, Menu, Chrome browser, Reports, Security insights: the status banner shows the trial or subscription active (for a trial it reads "Your trial ends in X days").
  3. The Cloud console Chrome Enterprise Premium page shows the purchased count, and it equals the count of action 2.
- **ROLLBACK:** cancel under the subscription terms; file 33 keeps `al-platform-operator-lite` (IP and time) until licences exist. A started trial is left to expire; no rollback is needed and no charge arises. Gate: P63, signed, with a row in 03's tracker. If PU-0.1 printed `GAP` for P63, the licences are quoted and the trial may be started, but the subscription is not bought.
- **EVIDENCE:** `<date>-PU-2.9-cep-purchaser-v1` (the output of action 1 and the named administrator), `<date>-PU-2.9-cep-subscription-v1` (the order and the count) (TISAX 4.1; E-11).

### PU-2.10 The dedicated platform billing account (row 10, P31, SD-16)

- **WHO:** finance, as billing administrator (`BILLING_ADMIN_EMAIL`), opens or designates the account and runs the check; the platform owner receives the output. No billing role is granted here (that is 07, to `sa-1-admin@`).
- **WHERE:** Cloud console, Billing, for finance; finance's shell for the check.
- **ACTION:**
  1. Finance opens or designates a dedicated standard Cloud Billing account in EUR under the organisation's payments profile, used by the platform only. Not a sub-account: Google states sub-accounts are intended for resellers.
  2. Finance runs the check below and sends the output line to the platform owner. The account id is not a secret; it is recorded as `BILLING_ACCOUNT_ID` by 07, not here.

```bash
gcloud billing accounts describe "<account id>" --format='value(open,currencyCode,masterBillingAccount,parent)'
```

- **VERIFY:** the output reads `True`, then `EUR`, then an empty sub-account field, then `organizations/<ORG_ID>`. Any other currency stops the row: 07 records the currency every budget must use, or finance opens an EUR account. A non-empty third field means a reseller sub-account: stop.
- **ROLLBACK:** finance closes a mistaken new account before any project links to it.
- **EVIDENCE:** `<date>-PU-2.10-billing-account-v1` with the output line (TISAX 6.1; E-11).

### PU-2.11 Project-quota request for about 20 projects (row 10)

- **WHO:** the billing administrator files (Google's form asks for the billing account); the platform owner supplies the list.
- **WHERE:** Google's project quota request (the console prompts it when a create would exceed the limit, or the "Request billing quota increase" form linked from Google's project-quota help page).
- **ACTION:**
  1. The platform owner lists the planned projects from the signed topology names: the five core projects, `GEMINI_PROJECT` if moved, `canary-r`, `MO_PROJECT`, `EVE_PROJECT`, `EVE_TWIN_PROJECT`, `WALLE_PROJECT`, `WALLE_TWIN_PROJECT`, the Eve advisor project and the nonprod module runs of files 17 and 18: about 20. The witness project is paid by the witness billing account and is not on this request.
  2. The billing administrator files one request naming the number of projects, the platform's email addresses that create projects (`sa-1-admin@` and later `factory-apply@`), the billing account id, paid services, and the reason (associating projects with billing).
- **VERIFY:** Google's acknowledgement carries a case reference, recorded with the date. Google typically answers within 2 business days and may ask for a payment. File 07's linking test proves the granted quota.
- **ROLLBACK:** none needed; an unused quota costs nothing.
- **EVIDENCE:** `<date>-PU-2.11-project-quota-request-v1` (TISAX 1.3).

### PU-2.12 Gemini Enterprise licences and Gmail-bearing seats (row 11)

- **WHO:** platform owner checks as the current Gemini Enterprise admin and super admin; procurement buys if short.
- **WHERE:** Admin console, Billing, Subscriptions; Google Cloud console, Gemini Enterprise, Manage subscriptions and Manage users.
- **ACTION:**
  1. Gmail-bearing seats in production: one for `walle@`, one for `eve@` (Eve's is assigned in 24, Wall-E's in 30). Whether `sa-1-admin@` and `sa-2-admin@` use seats is decided in 06 (*tbd*). `brk-gcp-1@` and `brk-gcp-2@` are Cloud Identity accounts with no Workspace licence (04 §7.1).
  2. Gemini Enterprise licences: one for every member of `walle-operators@` and `ge-admins@`, taking the licensed, distributed and assigned counts from file 05's inventory.
  3. Buy the shortfall of each.
- **VERIFY:** Admin console, Billing, Subscriptions shows at least two free seats on a Gmail-bearing SKU. Cloud console, Gemini Enterprise, Manage subscriptions shows enough unassigned licences for the counted people. (Subscription counts say seats exist, not who holds one: assignment is checked in 35.)
- **ROLLBACK:** reduce seats under the plan's terms.
- **EVIDENCE:** `<date>-PU-2.12-seats-and-licences-v1` with the counts (TISAX 1.3).

### PU-2.13 The git-host plan (row 12, P22 / SD-14)

This step exists because the git host is a hard prerequisite of Tier R ([01](01-prerequisites-and-conventions.md) P-13) and [03](03-decisions-and-people.md) DC-9 builds a repository whose required-reviewer, code-owner and audited-bypass settings are **paid features on a private repository**, yet nothing in the earlier draft of this file costed it, gave it a lead time or named a procurement owner. 03 runs in parallel with this file, so the plan is bought before DC-9.2 creates the repository, not after.

- **WHO:** platform owner raises and specifies; procurement orders; the finance approver signs. IT security countersigns the rule set, because it is the control that makes every later two-human commit real. No witness.
- **WHERE:** procurement system; then the git host's own billing page, performed by the person who will be organisation owner on the host in DC-9.2.
- **ACTION:**
  1. Read the signed P22 / SD-14 record for `GIT_HOST`. Do not guess: 03 DC-4.3 sets `GIT_HOST` and `GIT_OIDC_ISSUER` from the record, and a self-managed host is out of scope of Google's Workload Identity Federation page, so 10 stops on it.
  2. Specify the plan against what DC-9 needs, and write the reasons into the order so nobody buys the free tier:
     - **If `GIT_HOST` is `github.com`:** protected branches are available on private repositories with GitHub Pro, Team, Enterprise Cloud and Enterprise Server; code owners are available on private repositories with the same plans; and code review settings on organisation-owned private repositories need Team, Enterprise Cloud or Enterprise Server. The repository of DC-9 is organisation-owned and private, so the floor is **GitHub Team**, and Enterprise Cloud if the organisation wants SSO and the fuller audit log.
     - **If `GIT_HOST` is `gitlab.com`:** Code Owners and merge-request approval rules (the number and type of required approvals) are **Premium and Ultimate** features; audit events record a bypassed policy. So the floor is **GitLab Premium**.
     - Seats: one per human who commits or reviews — at least the platform owner, the second human, the second operator, the security reviewer or incident commander, and the blind grader. Bot and service accounts are not given seats that can approve.
  3. Procurement orders the plan for the counted seats. The billing account of the git host is the organisation's usual one, not the Google Cloud platform billing account of PU-2.10.
- **VERIFY:** before 03 DC-9.2 is run, the platform owner and IT security together confirm, on the host's own settings pages, all four:
  1. the organisation's plan on the billing page is the one ordered (GitHub Team or higher; GitLab Premium or higher);
  2. a **private** test repository can be created in that organisation;
  3. in that test repository a ruleset or approval rule can be set that requires two approvals and review from code owners on a named path, and that rule can be saved;
  4. an approval given by a bot or service account does not satisfy the rule — proved on the test repository by having a bot or service account approve and the merge still being refused, with the refusal screenshotted. Where the host cannot express this as a setting, the rule is enforced by DC-9.9's CI check instead, and that is written here as the reason, with DC-9.9 named as the compensating control.

  The test repository is deleted once the four checks pass; the real repository is DC-9.2's.
- **ROLLBACK:** downgrade or cancel under the host's terms before DC-9.2 creates the repository. After DC-9.5 has pushed history, a downgrade that removes protected branches or code owners is **a control failure, not a rollback**: it is treated as a change to a control file and needs the same two-human approval, and IT security is told the same day.
- **EVIDENCE:** `<date>-PU-2.13-git-host-plan-v1` (the order and the plan name) and `<date>-PU-2.13-git-host-rules-proof-v1` (the four verify outputs, including the refused bot approval) in `EVIDENCE_INTERIM_LOCATION` (E-05, E-11; TISAX 5.2, 1.6). 03 DC-9.6 cites this evidence rather than re-proving it.

## 3. Questions to the account team

Each question is sent in writing by the named person; the answer is filed the day it arrives. A step is done when the answer is in hand, whatever it says.

### PU-3.1 Access Approval's support prerequisite for the witness

- **WHO:** a witness administrator (IT security) asks; no witness.
- **WHERE:** the Google account team, by email or support case.
- **ACTION:** ask: "Access Approval is included with Standard, Enhanced and Premium Support. For a second organisation (the witness) created on `WITNESS_DOMAIN`, does Access Approval require a Customer Care subscription bought for that organisation resource, or does the existing subscription cover it? Is Access Transparency on by default for a new organisation?"
- **VERIFY:** a dated written answer. If Access Approval is not available to the witness, 08 records W-2's Access Approval as unavailable (SD-28).
- **ROLLBACK:** none needed.
- **EVIDENCE:** `<date>-PU-3.1-access-approval-answer-v1` (TISAX 6.1; E-11).

### PU-3.2 An additional invoiced billing account under a second organisation

- **WHO:** finance asks, with a witness administrator copied.
- **WHERE:** the account team or Cloud Billing support.
- **ACTION:** ask: "Can our existing commercial relationship open an additional invoiced Cloud Billing account whose parent is a separate organisation (the witness), administered only by that organisation's administrators? If yes, what is the lead time and what does the application need? If no, what is the approved self-serve route for a business account?"
- **VERIFY:** a dated written answer, and PU-2.4 step 4 updated with the route and lead time.
- **ROLLBACK:** none needed.
- **EVIDENCE:** `<date>-PU-3.2-witness-invoicing-answer-v1` (TISAX 6.1).

### PU-3.3 SCC Enterprise residency activation date, and the Premium Model Armor allowance

- **WHO:** IT security asks; the platform owner writes the answer back into PU-2.3 step 4 and §5.
- **WHERE:** the account team.
- **ACTION:** ask, in one message:
  1. "For the Enterprise tier with data residency, Google says activation must be scheduled with the account representative. Confirm that the Premium tier with `eu` residency at organisation level needs no scheduled date, and give the lead time for a Premium subscription order." P94 does not choose Enterprise; the answer is recorded so P11 is closed on facts.
  2. "How many Model Armor tokens a month are included with Security Command Center Premium activated at organisation level on **pay-as-you-go**, as opposed to the 3 billion a month stated for a Premium **subscription** and the 2 million a month stated for standalone Model Armor? State the overage rate that applies in each case."
- **VERIFY:** a dated written answer covering both questions. If P11 selects Enterprise, the scheduled activation date is recorded and file 09 waits for it. The token figure replaces the *tbd* in PU-2.3 step 4 and in §5's SCC row on the day it arrives; if the answer does not give one, PU-2.3's zero-allowance costing stands and that is written into §5.
- **ROLLBACK:** none needed.
- **EVIDENCE:** `<date>-PU-3.3-scc-residency-answer-v1` (E-11; TISAX 6.1).

## 4. Hardware keys: the count, stated once, and the inventory

The count below supersedes [../04-identity-and-privileged-access.md](../04-identity-and-privileged-access.md) §8.3 ("ten in total") and PREREQUISITES §3.1 ("four robot keys"), neither of which counts the witness, the sandbox or SD-12's custodians. Any FIDO security key that Google accepts for "Only security key" 2SV will do (`Assumption:` a model with the connector every custodian's workstation has).

| Accounts | Keys | Custodians | Enrolled in |
|---|---|---|---|
| `sa-1-admin@` | 2 | one carried by the platform owner; spare in the safe, custodian the second human | [06](06-organisation-bootstrap-and-roster.md) |
| `sa-2-admin@` | 2 | one carried by the second human; spare in the safe, custodian the platform owner | 06 |
| `brk-gcp-1@`, `brk-gcp-2@` | 2 (one each) | key 1 the platform owner, key 2 the second human, sealed (04 §7.1) | 06 |
| `walle@` | 2 | key A the platform owner, key B the second human | [30](30-wall-e-workspace-side.md) |
| `eve@` | 2 | the second human and the security reviewer, or the incident commander until the security reviewer is appointed; never the platform owner (SD-12) | [24](24-eve-workspace-identity-and-audit-feeds.md) |
| The two witness administrators | 4 (two each) | each administrator, spare in IT security's safe | [08](08-witness-organisation.md) |
| The two sandbox super admins | 4 (two each) | each administrator, spare in the safe | [21](21-sandbox-tenant-and-nonprod-foundation.md) |
| Subtotal, firm | **18** | | |
| `walle@SANDBOX_DOMAIN`, `eve@SANDBOX_DOMAIN` | 4, **only if SD-29 decides hardware-key 2SV for the twin robots** | as their production counterparts | [24](24-eve-workspace-identity-and-audit-feeds.md), [37](37-wall-e-sandbox-rehearsal.md) |
| Spares, unenrolled | 4 (`Assumption:` one replacement for each custodian group, so a loss is repaired the same day instead of after a new order) | IT security (incident commander), in the safe | on loss |
| **Order** | **22, or 26 with the twin robots** | | |

The second human's non-administrator witness account (SD-04) is decided in 08; if it needs keys of its own, 08 draws them from the spares and PU-4.1 re-orders.

### PU-4.0 Order the custody materials (row 13)

Keys without envelopes, a safe and forms cannot be taken into custody, and [06](06-organisation-bootstrap-and-roster.md)'s preconditions require all three at its first sitting: "one [envelope] per human admin account (spare key and backup codes) and one per break-glass account, four in total, plus at least four spares for re-sealing (`v2` records). A corporate safe with a sign-out log. Paper custody forms (file 01 template)." The earlier draft of this file ordered only the keys. Raised on day one, alongside PU-4.1.

- **WHO:** platform owner raises with IT security; facilities and procurement order. No approver beyond the usual purchase limit. No witness.
- **WHERE:** procurement system; facilities for the safe.
- **ACTION:**
  1. Order **tamper-evident envelopes**: 4 for 06 (one per human admin account and one per break-glass account), plus 4 for 08's witness administrators, 4 for 21's sandbox super admins, 2 for `walle@` (30) and 2 for `eve@` (24) — 16 in use.
  2. Order **spare envelopes** for re-sealing: at least one per envelope in use, so a `v2` record never waits on a new order. `Assumption:` 16 spares, 32 envelopes in total. Envelopes must be sequentially numbered by the supplier, because the custody record of PU-4.2 records an envelope number.
  3. Confirm or order a **corporate safe with a sign-out log** that the platform owner and the second human can both reach and that IT security can audit, plus a second safe or compartment in IT security's own area for the witness administrators' spares (SD-04 keeps the lines apart). A safe that must be delivered and bolted down is the long pole of this row: raise it first.
  4. Print the **paper custody forms**, enough for every line of §4's table plus spares. 06's preconditions call these "file 01 template"; on 2026-09-15 [01](01-prerequisites-and-conventions.md) names the keys, the safe and the envelopes (P-25, §3.2, and the envelope-witness role) but prints no form. Check first: if 01 carries a form on the day, use it unchanged; if it does not, the platform owner drafts one carrying exactly the fields PU-4.2 records, has IT security countersign it as the template, and tells 01's owner so the template lands in 01 rather than here.
- **VERIFY:** count the delivered envelopes against steps 1 and 2 and record the number range; the safe is installed, its sign-out log is open with a first dated line, and both custodians have tested that they can open it; the printed forms carry the template's fields (label, serial, account, custodian, envelope number, date, two signature blocks). The platform owner ticks row 13 only against 06's precondition list, item by item.
- **ROLLBACK:** amend or cancel the order before delivery. Nothing here is irreversible.
- **EVIDENCE:** `<date>-PU-4.0-custody-materials-v1` with the envelope number range, the safe's location and the date its sign-out log was opened (TISAX 3.1; E-08). No envelope number is a secret; no key serial is written here, because no key is opened at this step.

### PU-4.1 Order the keys

- **WHO:** platform owner raises; procurement orders. No approver beyond the usual purchase limit.
- **WHERE:** procurement system.
- **ACTION:**
  1. Read SD-29's signed answer on the twin robots' 2SV; order 22 or 26.
  2. Ask for delivery of the first six (sa-1, sa-2, brk-gcp) ahead of the rest if the supplier splits deliveries, because file 06 needs them first.
- **VERIFY:** the purchase order shows the quantity equal to the table's order line for the SD-29 answer.
- **ROLLBACK:** amend the order before dispatch.
- **EVIDENCE:** `<date>-PU-4.1-key-order-v1` (TISAX 3.1).

### PU-4.2 Receive the keys and open the inventory

- **WHO:** platform owner receives; each custodian signs for their keys; a witness from the other administration line signs every line. The witness administrators receive theirs from procurement directly, not from the platform owner.
- **WHERE:** at the safe; the paper custody record.
- **ACTION:**
  1. For each key write on the custody record: label, serial, intended account (not yet enrolled), custodian, envelope number, date, custodian's and witness's signatures.
  2. Scan the record the same day to `EVIDENCE_INTERIM_LOCATION` (SD-27). The witness administrators upload it at W-2.
  3. Serials are written only on custody records and their scans: never in `~/.platform-env`, the build log, the wiki or a ticket.
- **VERIFY:** the count of lines on the custody record equals the delivered count and the order line; every line carries two signatures; the build log records only "N keys received, custody record `<name>`".
- **ROLLBACK:** a key found defective or unaccounted for is recorded as such, destroyed with a witnessed line if defective, and replaced from the spares.
- **EVIDENCE:** `<date>-PU-4.2-key-custody-record-v1` (scan) in `EVIDENCE_INTERIM_LOCATION`; the build-log line (TISAX 3.1; E-08).

## 5. Costs that sit on no Google Cloud budget

The per-project budgets of P39 see only Google Cloud spend on the platform account. The lines below are paid elsewhere, so each needs an owner and a purchase record, or the P-SA gate discovers them late (X-RQB-07). Amounts are *tbd* until the quotes arrive; unit prices quoted are Google's of 2026-09-15.

| Cost | Driver | Paid by | Purchase record | From tier |
|---|---|---|---|---|
| SCC Premium | pay-as-you-go on every project billing account of the organisation, or the subscription (min. 15,000 USD a year, 12 months). Model Armor tokens included: 3 billion a month with the subscription; *tbd* with organisation-level pay-as-you-go, costed at zero until PU-3.3 answers | per P11 (IT security and finance) | PU-2.3, PU-3.3 | C |
| Google SecOps or the organisation's SIEM, with the MDR retainer | events per day, retention term, retainer | IT security | PU-2.1 | P |
| Penetration test | scoped, then full | IT security | PU-2.2 | W (scoped), P-SA (full) |
| Paging tool (Business plan or higher if PagerDuty) | users | IT security | PU-2.6 | W (channel), P (24x7) |
| Witness organisation: billing account, Customer Care subscription, domain | one organisation, one project, support tier | IT security | PU-2.4, PU-3.1, PU-3.2 | P |
| Sandbox Workspace tenant | edition, seats, domain | platform | PU-2.5 | before the grant |
| Chrome Enterprise Premium | licences per operator and approver | platform | PU-2.9 | W |
| Gemini Enterprise licences and Gmail-bearing seats | people and robots | tenant (seats), platform (robots) | PU-2.12 | C, P |
| Model throughput, if ordered | GSUs and term | agent budgets | PU-2.8 | Stage 0 |
| Git-host plan (GitHub Team or higher; GitLab Premium or higher) | seats for the humans who commit and review | platform, with the organisation's usual git-host payer | PU-2.13 | R (03 DC-9 gates 06) |
| Hardware keys | 22 or 26 | platform | PU-4.1 | first file (06) |
| Custody materials: envelopes, spare envelopes, safe, custody forms | 16 envelopes in use plus spares; one safe, plus a compartment in IT security's area | platform (envelopes, forms); facilities (safe) | PU-4.0 | first file (06) |
| Human hours | roles of HLD §0.3 | — | — | every tier |

### PU-5.1 File the cost record

- **WHO:** platform owner.
- **WHERE:** the build-log repository.
- **ACTION:** commit the table above, filled with the purchase-record references as they arrive, as `costs/outside-gcp-budgets.md` in `BUILD_LOG_DIR`; send it to finance and IT security for their rows.
- **VERIFY:** every row has an owner and either a purchase-record reference or *tbd* with the step that will fill it.
- **ROLLBACK:** revert the commit.
- **EVIDENCE:** the commit reference in `EVIDENCE_REGISTER` (TISAX 6.1; E-11).

### PU-5.2 Measure Workspace audit-log volume before P31 sets LOGGING_PROJECT's budget

- **WHO:** the owner of organisation-level Cloud Logging, holding `roles/logging.privateLogViewer` at the organisation (login, SAML and part of the OAuth token logs are Data Access logs). The platform owner records the numbers and performs nothing here.
- **WHERE:** **that person's own shell, which has no `~/.platform-env`, no `penv_set` and no `need`** — those exist only on the platform owner's workstation ([01](01-prerequisites-and-conventions.md) §4). So nothing below interpolates a platform variable. Runs only if "Share data with Google Cloud services" is already on; otherwise the measurement is a re-run point of file [14](14-central-logging-and-billing-export.md) after it turns sharing on, and this step records "not measurable on `<date>`".

  **Handing over the one value.** The platform owner runs `echo "$ORG_ID"` in his own shell and gives the logging owner that number — the organisation id is not a secret — by the same route the two use for other work, recorded in the build log as "ORG_ID handed to `<name>` for PU-5.2 on `<date>`". The logging owner substitutes it for `<ORG_ID>` in the first line below and runs nothing until the guard prints `using organizations/<number>`.

  *Alternative, if the two cannot meet:* the organisation's existing IAM owner grants the platform owner `roles/logging.privateLogViewer` at the organisation for the day and withdraws it the same day, recorded in `DEVIATION_REGISTER`. The platform owner then runs the block in his own shell with `--organization="$ORG_ID"`. This is a second person reading employee login metadata, so IT security approves it in writing first; the handover above is the default.

- **ACTION:** count one day of entries per stream, then size one compact sample. Output goes straight to `wc`; nothing is stored, because the entries hold employee login metadata.

```bash
ORG="<ORG_ID handed over by the platform owner, digits only>"
case "$ORG" in ''|*[!0-9]*) echo "STOP: not an organisation id; ask the platform owner and run nothing below" >&2; unset ORG;; *) echo "using organizations/$ORG";; esac
gcloud logging read 'protoPayload.serviceName="admin.googleapis.com"' --organization="${ORG:?stop: organisation id not set}" --freshness=1d --format='value(insertId)' | wc -l
gcloud logging read 'protoPayload.serviceName="cloudidentity.googleapis.com"' --organization="${ORG:?stop: organisation id not set}" --freshness=1d --format='value(insertId)' | wc -l
gcloud logging read 'protoPayload.serviceName="login.googleapis.com"' --organization="${ORG:?stop: organisation id not set}" --freshness=1d --format='value(insertId)' | wc -l
gcloud logging read 'protoPayload.serviceName="oauth2.googleapis.com"' --organization="${ORG:?stop: organisation id not set}" --freshness=1d --format='value(insertId)' | wc -l
gcloud logging read 'protoPayload.serviceName="login.googleapis.com"' --organization="${ORG:?stop: organisation id not set}" --freshness=1d --limit=1000 --format=json | jq -c '.[]' | wc -c
```

  `--limit` defaults to unlimited, so the four counting lines are not capped at 1,000. `${ORG:?...}` stops each line with a message if the guard unset the variable, instead of sending `--organization=` and getting four silent failures. If `jq` is not installed on that workstation, replace `jq -c '.[]'` with `python3 -c 'import json,sys;[print(json.dumps(e,separators=(",",":"))) for e in json.load(sys.stdin)]'`.

  **Which byte figure to record.** The last line measures what `gcloud` renders, not what Cloud Logging meters, so `jq -c` is used to strip the pretty-printer's indentation and the figure is recorded as an **upper bound** on ingested bytes. Where the logging owner can read Cloud Monitoring for the organisation's log bucket, prefer the metered figure instead: the metric type `logging.googleapis.com/billing/bytes_ingested` gives billable ingested bytes and can be filtered by `log_source` and `log_bucket_id` over the same day. **Record which of the two methods produced the number**, alongside the number; an estimate built on the upper bound is marked as such so P31's budget is not read as a measurement it is not.

- **VERIFY:** four counts, one byte figure, and the method that produced it, all recorded. The estimate (entries a day times bytes per entry times 30) is written with the date and the method into P31's input record, so LOGGING_PROJECT's budget is set from a measurement plus 13 months of 400-day retention growth (Cloud Logging: 0.50 USD per GiB ingested above 50 GiB per project a month; 0.01 USD per GiB a month retained beyond 30 days). A budget set from the upper-bound method is revisited once 14 can read the metered figure.
- **ROLLBACK:** none needed (read-only). If the alternative route was used, confirm the temporary `roles/logging.privateLogViewer` grant was withdrawn the same day and that the withdrawal is in `DEVIATION_REGISTER`.
- **EVIDENCE:** `<date>-PU-5.2-workspace-log-volume-v1` with numbers and the method only — no log entry, no employee identifier (TISAX 1.3; E-09). The handover line and, if used, the temporary grant and its withdrawal, in the build log.

## 6. Verification checklist for the whole part

- [ ] Every row of §1 is ticked on sight of its item-in-hand evidence, or carries a dated reason and the step that will close it.
- [ ] SIEM order (or signed S1-S9 assessment) and MDR retainer in hand (PU-2.1).
- [ ] Penetration test statement of work signed with the G8 window (PU-2.2).
- [ ] SCC payer signed; subscription countersigned if chosen (PU-2.3); PU-3.3 answered.
- [ ] `WITNESS_DOMAIN` set; registrar lock and 2SV confirmed; billing route and support approved; PU-3.1 and PU-3.2 answered (PU-2.4).
- [ ] `SANDBOX_DOMAIN` set; sandbox order at Enterprise Standard or above with seats and terms signer (PU-2.5).
- [ ] `PAGER_SERVICE_NAME` set; the tool has role separation and an audit trail (PU-2.6).
- [ ] `PAGER_SUBJECT_SERVICE_NAME` set; the second human has proven the platform owner holds no role on it (PU-2.7).
- [ ] Model throughput decided after decision 6, or row 8 marked "waits on decision 6" (PU-2.8).
- [ ] Billing account check output `True`, `EUR`, empty, `organizations/<ORG_ID>` on file; quota request reference recorded (PU-2.10, PU-2.11).
- [ ] Chrome Enterprise Premium active or trial started, **after** PU-2.10, by a named holder of `roles/beyondcorp.admin` at the organisation whose binding was printed and recorded (PU-2.9).
- [ ] Free Gmail-bearing seats and Gemini Enterprise licences counted (PU-2.12).
- [ ] Git-host plan bought and its four rule checks passed before 03 DC-9.2 runs (PU-2.13).
- [ ] Envelopes, spares, safe with an open sign-out log and custody forms counted against 06's precondition list (PU-4.0).
- [ ] 22 or 26 keys received; custody record signed and scanned; no serial outside custody records (PU-4.1, PU-4.2).
- [ ] Cost record committed; log volume measured with its method recorded, or the re-run point recorded (PU-5.1, PU-5.2).
- [ ] P63 and P99 either signed with a tracker row, or the PU-0.1 `GAP` line is on file and neither purchase was committed.

```bash
need SANDBOX_DOMAIN WITNESS_DOMAIN PAGER_SERVICE_NAME PAGER_SUBJECT_SERVICE_NAME
grep -ciE 'serial' "$PLATFORM_ENV_FILE"
```

The first line passes; the second prints `0`.

## 7. What the next files need from this part

| File | Needs | From |
|---|---|---|
| [03](03-decisions-and-people.md) | the git-host plan in force before DC-9.2 creates the repository, with DC-9.6's settings evidence already produced here | PU-2.13 |
| [06](06-organisation-bootstrap-and-roster.md) | six keys (sa-1, sa-2, brk-gcp) received with custody lines | PU-4.2 |
| [06](06-organisation-bootstrap-and-roster.md) | four tamper-evident envelopes plus at least four spares, the safe with its sign-out log, the printed custody forms — its stated preconditions | PU-4.0 |
| [07](07-billing-account.md) | the account designated and checked; the quota request reference (07 verifies the granted quota with its linking test and re-files only if refused) | PU-2.10, PU-2.11 |
| [08](08-witness-organisation.md) | `WITNESS_DOMAIN`; the approved billing route; the approved Customer Care subscription; PU-3.1 and PU-3.2 answers; four witness-administrator keys | PU-2.4, PU-3.1, PU-3.2, PU-4.2 |
| [09](09-folders-and-security-command-center.md) | the SCC payer record and, if chosen, the contract; PU-3.3 | PU-2.3, PU-3.3 |
| [15](15-pager-siem-and-detections.md) | `PAGER_SERVICE_NAME`, `PAGER_SUBJECT_SERVICE_NAME` with IT security as administrator; for part B, the SIEM order and MDR retainer | PU-2.6, PU-2.7, PU-2.1 |
| [21](21-sandbox-tenant-and-nonprod-foundation.md) | `SANDBOX_DOMAIN` with editable DNS; the order with edition and seats; four sandbox keys | PU-2.5, PU-4.2 |
| [24](24-eve-workspace-identity-and-audit-feeds.md), [30](30-wall-e-workspace-side.md) | a free Gmail-bearing seat each; two keys each with SD-12's custodians for `eve@` | PU-2.12, PU-4.2 |
| [33](33-wall-e-action-services-and-approval-surfaces.md) | Chrome Enterprise Premium licences or the trial | PU-2.9 |
| [35](35-wall-e-engine-registration-and-gateways.md), [40](40-mo-after-stage-0.md) | the throughput decision | PU-2.8 |
| [37](37-wall-e-sandbox-rehearsal.md) | the penetration test window; twin robot keys if SD-29 chose them | PU-2.2, PU-4.2 |
| [14](14-central-logging-and-billing-export.md) | the re-run point for PU-5.2 if sharing was off | PU-5.2 |

## 8. Findings closed

| Finding | What stood after verification | How this page closes it |
|---|---|---|
| S003 (blocking) | Nothing buys the SIEM, the MDR retainer or the pager, or settles who pays for SCC Premium; P10 open | Rows 1, 3 and 6 with PU-2.1, PU-2.3, PU-2.6; activation and wiring stay in 09 and 15, which close the rest |
| S083 (major) | No platform purchase list with verify checks; the key count omitted break-glass and platform items | §1 with an item-in-hand check per row; §4's single count including break-glass, witness, sandbox and SD-12 custodians; the prerequisites table is 01's |
| X-ORG-04 (major) | The sandbox tenant had no edition, domain, seats, administrators or keys; the edition floor rests on multi-party approval, Gmail, OAuth and SAML sharing and the SecOps export, not on activity rules | PU-2.5 with that floor and its reasons, the domain, seats, two sandbox super admins, the terms signer, P59; twin-robot keys conditional on SD-29 in §4 |
| X-ORG-08 (major) | The witness could be paid by a tenant billing account that a tenant Organization Administrator can close; invoiced eligibility is business-level and silent on additional accounts | PU-2.4 excludes the tenant account and requires an account parented by the witness organisation; PU-3.2 asks the account team and records the answer and lead time |
| X-RQB-06 (major) | Witness billing and its Customer Care subscription are missing from the purchase list; Access Approval is included with a paid support tier bought per organisation | PU-2.4 steps 4-5 and PU-3.1; the billingEnabled check and budget are 08's (W-4) |
| X-RQB-07 (minor) | Costs outside Google Cloud budgets had no owner or record; LOGGING_PROJECT's budget would be set without a volume measurement | §5 table with owners and purchase records; PU-5.2 measures volume before P31 sets the budget |
| X-RQB-09 (minor) | No list sorted by lead time with owner and blocked gate; the witness billing account, the platform billing account and quota, and model throughput were in no list | §1, one table sorted by lead time with owner, blocked file and gate; rows 4, 8 and 10 |

Findings raised by the 2026-09-16 review of this file:

| Finding | What stood | How this page closes it |
|---|---|---|
| PU-2.9 named a principal that never exists (major) | `roles/beyondcorp.admin` is granted to nobody in files 06 to 12; 06 OB-3.7 grants four organisation roles to `sa-1-admin@` and says "No other role is granted", so row 7 could never be ticked | PU-2.9's second precondition names the existing organisation-level administrator as the purchaser and prints the binding with `gcloud organizations get-iam-policy` before the request is raised; the alternative fix (adding the role to OB-3.7's exception set with a DEV-06-01 line and a withdrawal in 12) is left to 06's and 12's owners and is **not** assumed here |
| PU-2.9 ordered before PU-2.10 (major) | Both the purchase and the trial need a billing account that PU-2.10 opens; §1's lead-time sort put row 7 before row 10 | PU-2.9's first precondition, the heading "runs after PU-2.10", the note under §1's table and the note in §2's preamble; the §6 checklist puts PU-2.10 first |
| PU-5.2 interpolated `$ORG_ID` in a shell that has no variables file (major) | Five commands would have run as `--organization=` and failed silently | PU-5.2 hands the organisation id over as a literal, guards it, and uses `${ORG:?}` on every line; a temporary-grant alternative is written with IT security approval and a `DEVIATION_REGISTER` entry |
| No git-host row (major) | The git host is a Tier R prerequisite (01 P-13) and 03 DC-9 needs paid private-repository features, but nothing costed it or named a procurement owner | Row 12 and PU-2.13, with the plan floor for each candidate host and a four-part rule check run before DC-9.2 |
| No custody-materials row (major) | 06's preconditions require envelopes, spares, a safe with a sign-out log and custody forms; 04 ordered only the keys | Row 13 and PU-4.0, counted against 06's own precondition list |
| P63 and P99 missing from the Preconditions and PU-0.1 (minor) | §1 rows 6 and 7 named gates that no precondition or gate line carried | Two Precondition lines, the tracker-gap note, the `decision-need.sh` lines in PU-0.1, and `Gate:` lines in PU-2.6 and PU-2.9 |
| PU-5.2's byte figure measured gcloud's pretty-printer (minor) | The estimate feeding P31's budget would be materially high | `jq -c` with the figure recorded as an upper bound, the metered `logging.googleapis.com/billing/bytes_ingested` route preferred where readable, and the method recorded with the number |
| PU-2.3's Model Armor allowances unconfirmed (minor) | "Organisation-level Premium includes 2 million tokens" conflated the standalone allowance with the Premium one | PU-2.3 step 4 restates the two confirmed figures and marks the pay-as-you-go allowance *tbd* with a zero-allowance costing rule; PU-3.3 asks for it. The pay-as-you-go billing target **was** confirmed and is now quoted in Google's own words |

No finding in this page's scope is deferred. One fix is **declined as out of scope for this file**: adding `roles/beyondcorp.admin` to OB-3.7's exception set would be an edit to [06](06-organisation-bootstrap-and-roster.md) and a matching withdrawal in [12](12-privileged-access-catalogue.md); this file owns neither, so it takes the alternative the same finding offers and names the existing holder instead.

## Sources checked on 2026-09-15, and on 2026-09-16 where marked

- Security Command Center pricing (subscription minimums; Premium subscription includes 3 billion Model Armor tokens a month, then 0.10 USD per million; standalone Model Armor free to 2 million tokens a month): https://cloud.google.com/security-command-center/pricing and https://cloud.google.com/security/products/model-armor#pricing (re-read 2026-09-16; the organisation-level pay-as-you-go allowance is not stated on either page and is *tbd*, asked in PU-3.3)
- Organisation-level pay-as-you-go charges "the billing accounts associated with the projects in your organization" (re-read 2026-09-16): https://cloud.google.com/security-command-center/pricing and https://docs.cloud.google.com/security-command-center/docs/service-tiers
- `gcloud logging read` resource-scope flags, at most one of `--organization`, `--folder`, `--project`, `--billing-account`, and `--limit` defaulting to unlimited (re-read 2026-09-16): https://docs.cloud.google.com/sdk/gcloud/reference/logging/read
- The metered ingestion metric `logging.googleapis.com/billing/bytes_ingested`, with `log_source` and `log_bucket_id` labels (read 2026-09-16): https://docs.cloud.google.com/logging/docs/logs-based-metrics and https://docs.cloud.google.com/stackdriver/estimating-bills
- GitHub: protected branches and code owners on private repositories need GitHub Pro, Team, Enterprise Cloud or Enterprise Server; code review settings on organisation-owned private repositories need Team or Enterprise (read 2026-09-16): https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches and https://docs.github.com/articles/about-code-owners and https://docs.github.com/en/organizations/organizing-members-into-teams/managing-code-review-settings-for-your-team
- GitLab: Code Owners and merge-request approval rules are Premium and Ultimate features; audit events record a bypass (read 2026-09-16): https://docs.gitlab.com/user/project/codeowners/ and https://docs.gitlab.com/user/project/merge_requests/approvals/rules/ and https://docs.gitlab.com/user/compliance/audit_events/
- SCC and SecOps data residency, Enterprise activation scheduled with the account representative: https://docs.cloud.google.com/security-command-center/docs/data-residency-support and https://docs.cloud.google.com/security-command-center/docs/activate-enterprise-tier
- Access Approval pricing (included with Standard, Enhanced and Premium Support): https://cloud.google.com/assured-workloads/access-approval/pricing
- Billing access and inheritance from the parent organisation: https://docs.cloud.google.com/billing/docs/how-to/billing-access
- Disabling billing stops a project's services: https://docs.cloud.google.com/billing/docs/how-to/modify-project
- Invoiced billing eligibility: https://docs.cloud.google.com/billing/docs/how-to/invoiced-billing
- Sub-accounts are intended for resellers: https://docs.cloud.google.com/billing/docs/concepts
- `gcloud billing accounts describe` (GA): https://docs.cloud.google.com/sdk/gcloud/reference/billing/accounts/describe; BillingAccount fields `open`, `currencyCode`, `masterBillingAccount`, `parent`: https://docs.cloud.google.com/billing/docs/reference/rest/v1/billingAccounts
- Project quota requests (2 business days, possible payment): https://support.google.com/cloud/answer/6330231, https://support.google.com/cloud/answer/7283050, form https://support.google.com/code/contact/billing_quota_increase
- Multi-party approval editions and two super admins: https://knowledge.workspace.google.com/admin/security/multi-party-approval-for-sensitive-actions
- Share data with Google Cloud services, edition limits: https://knowledge.workspace.google.com/admin/getting-started/share-data-with-google-cloud-services
- Domain already in use: https://knowledge.workspace.google.com/admin/support/troubleshooting/cant-sign-up-my-domain-for-a-google-service
- Workspace MX record `smtp.google.com`, priority 1: https://knowledge.workspace.google.com/admin/domains/set-up-mx-records-for-google-workspace
- Workspace audit logs, types and buckets: https://docs.cloud.google.com/logging/docs/audit/gsuite-audit-logging
- Cloud Logging pricing: https://cloud.google.com/stackdriver/pricing
- Chrome Enterprise Premium: `roles/beyondcorp.admin` "must be assigned at the Organization level"; purchase at `https://console.cloud.google.com/security/cep/`; trial 60 days for up to 5,000 users, "you won't be charged, but our systems require valid payment details"; status banner in Admin console, Chrome browser, Reports, Security insights (re-read 2026-09-16): https://support.google.com/chrome/a/answer/15832585
- Gemini Enterprise subscriptions and licences: https://docs.cloud.google.com/gemini/enterprise/docs/licenses
- Provisioned Throughput processing time: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/provisioned-throughput/purchase-provisioned-throughput
- Penetration testing of own projects needs no notice: https://support.google.com/cloud/answer/6262505
- PagerDuty Advanced Permissions: https://support.pagerduty.com/main/docs/advanced-permissions; Audit Trail Reporting: https://support.pagerduty.com/main/docs/audit-trail-reporting
