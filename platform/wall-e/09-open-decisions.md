# 9. Decisions to make before build

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Decisions 42 to 52, opened on 2026-09-13 by the four-project topology, live in
  [../project-topology.md](../project-topology.md) §8. Decision 42 is repeated below
  because it gates Phase 7. Where a row below said "the project", it now names which of
  `GEMINI_PROJECT`, `WALLE_PROJECT`, `EVE_PROJECT` and `MO_PROJECT` it means; no decision
  changed.

Answer these, then record each as a dated file in [`../../decisions/`](../../decisions/).
Nothing in that directory yet — none of these decisions has been written down, so
Wall-E starts by closing them.

## Blocking — the build cannot start without these

| # | Decision | Why it blocks | Recommendation |
|---|---|---|---|
| **1** | **Does any other automation already write to the same Workspace objects?** An HR-driven directory sync, a licence-management script, a joiner/leaver tool. | Two writers on one object is the collision this design's pre-state re-read exists to catch, but it is far better to know up front. | **Inventory every existing writer before Stage 1** and give each a named owner. |
| **2** | **Names**: the four project ids (`GEMINI_PROJECT`, `WALLE_PROJECT`, `EVE_PROJECT`, `MO_PROJECT`) and `FOLDER_ID`, robot account, OU, groups, BigQuery dataset, OAuth app name | The consent screen shows the app name to the robot and is awkward to change afterwards. Every script hard-codes the rest. | Decide in one sitting. `walle-` prefix throughout; robot `walle@<domain>`. |
| **3** | **The complete OAuth scope list** | Scopes freeze at consent. Adding one later means redoing the bootstrap and the Trusted-client step. | Take the list in [02](02-identity-and-auth.md) as the proposal. The two live questions: include `admin.directory.user.security` (sign-out, token revocation) for leaver hygiene? And confirm you do **not** want `drive`. |
| **4** | **Ratify the "must never happen" list** | It is the ceiling every other control is calibrated against, and I wrote it without you. | Read [06](06-security-guardrails.md) §"blast-radius ceiling". Nine rows. Tell me which you disagree with. |
| **5** | **Which OUs, and is a sandbox OU possible?** | Every write scope limit references an OU allowlist that is currently `tbd`, and Stage 0 shadow plans need somewhere safe to point. | A sandbox OU with synthetic accounts, plus one small real pilot OU. Without a sandbox, Stage 1 has to run against real users, which I would not do. |

## Needed before Stage 1 (the first real write)

| # | Decision | Why it matters | Recommendation |
|---|---|---|---|
| **6** | **Which model, pinned by id** | Not every current model has EU data residency. The id goes on every audit row so Mo can attribute behaviour changes. | Pick from the per-model EU residency table at build. Do not assume the newest is eligible. |
| **7** | **Data retention after removing a licence** on your tenant's plan | Licence reclaim is the clearest early saving, and on an *active* account it may destroy data. | Ask your Google account team before any active account is in scope. Until answered, reclaim only from suspended accounts. |
| **8** | **DPIA, and employee representative bodies where your jurisdiction has them** | Autonomous admin action is a **different processing activity** from human-requested action. Longest lead time in the plan. | Ask in week one, in parallel with build. Frame it in two parts: reads now, autonomous writes before Stage 3. |
| **9** | **Cloud Run ingress and network isolation** | An earlier draft specified internal-only; Agent Runtime may not qualify as internal traffic. | Deploy with IAM as the boundary and test. Add a PSC interface only if your network policy demands it. |
| **10** | **Does Eve get its own read-only Workspace credential?** | Without one, Eve verifies through the thing it is verifying. | **Yes.** One more bootstrap, and it is what makes verification independent. Its OAuth client and refresh token live in `EVE_PROJECT`'s Secret Manager, never in `WALLE_PROJECT` ([../project-topology.md](../project-topology.md) §2). |
| **11** | **Who else is an operator, and who is the second approver?** | L4 and L5 promotions need two named humans. A one-person rota also means approvals stall whenever you are away. | Name at least one more Workspace admin for `walle-operators@`, and someone from IT security as the second approver for high-risk promotions. |
| **12** | **Which playbooks first?** | The four in this design are my guesses. The ladder does not depend on them, but Stage 0's shadow evidence does. | Tell me the three admin tasks that waste the most of your time. My guesses: licence reclaim from suspended accounts, leaver group hygiene, stale-account reporting. |

## Needed before autonomy (Stage 3 onward)

| # | Decision | Why | Recommendation |
|---|---|---|---|
| **13** | **Is there an HR system of record** reachable as an event source? | Autonomous suspension at Stage 5 is only acceptable when the trigger is authoritative, never free text. | If there is none, F5 suspend stops at L3 permanently. That is an acceptable outcome. |
| **14** | **Approval and notification surface** | Operators need somewhere to approve, veto and grade, and the surface must authenticate the human itself — the agent must never carry consent. **Promoted from a later decision to a Stage 1 blocker.** | Google Chat, **and it needs a Chat app**: under user authentication the Chat API can send text only, so the one-click veto and approval cards this design assumes require app authentication. Budget for that, or use an Identity-Aware-Proxy-fronted approval page instead. |
| **15** | **Business hours, timezone, freeze windows** | Hard-coded into every autonomous run's gate. | `Assumption:` Europe/Paris, Mon–Fri, last write 16:00. Correct me. |
| **16** | **Budgets and caps** | The numbers in [05](05-autonomy-ladder.md) are defaults I chose. | Revisit at each stage decision rather than now. |
| **17** | **Audit retention** | 400 days is my default. | Align with your retention policy. |
| **18** | **Split the control plane onto its own service?** | Today every control — credential, policy, approval minting *and* verification, execution, audit — runs in one Cloud Run process, and `run.invoker` is granted per service rather than per path. An in-app allowlist works; a second service is stronger. | Do it before Stage 4. Until then, the per-endpoint allowlist plus Eve's asymmetric key is the minimum. |
| **19** | **Adopt Agent Identity, and decide it before the first production engine exists** | Generally available, per-agent identity with 24-hour certificates and bound tokens, and the identity every platform governance feature keys on. `identity_type` is fixed at engine creation. One fact is undocumented: whether the agent can present a Google-signed ID token that Cloud Run IAM accepts. | Yes, contingent on the one-day spike in [12-agent-identity.md](12-agent-identity.md) section 8.1 step 7, run on a throwaway engine before the production one is created. Fallback is `walle-agent@`, with the spike output attached. |
| **21** | **Gateway or perimeter for the reasoning layer, one decision before Stage 1** | Agent Gateway and VPC Service Controls are not supported together on the engine, so weakness 13's deferred perimeter and the egress-gateway allowlist are the same choice. | The gateway, for the agent: default-deny hostnames, dry-run evidence, no Google-managed tenant network to reason about. Whether a perimeter can still wrap the action service's dependencies while excluding the engine is `tbd` in the same record. [13](13-agent-interconnection.md) section 7.5. |
| **22** | **Is `walle-actions` ever exposed as an MCP server?** | It is the only way the egress gateway's Model Armor would screen tool results. It adds a second protocol to the credential holder. | No, unless the injection-precision metric at Stage 2 shows tool-result injections reaching the proposal queue at a rate canonicalisation and the taint bit do not contain. [13](13-agent-interconnection.md) section 6.3. |
| **23** | **When, if ever, does Wall-E serve A2A, and from where?** | Three options: none, the Preview Agent Runtime template, or a Cloud Run `to_a2a` service. Every A2A path is a second ingress to the reasoning layer. | None through Stage 2. Eve uses `reasoningEngines.streamQuery`. Revisit at Stage 3 only if a consumer needs it. [13](13-agent-interconnection.md) section 4.1. |
| **24** | **Model Armor blocking threshold and confidence level** | Templates start inspect-only; the flip to blocking and the confidence level are measured decisions, and the prompt-injection filter changes version on 2026-09-25. | Decide from the Stage 0 regression-suite numbers, in the Stage 1 record. [11](11-prompt-security.md) section 4. |
| **25** | **Telemetry content capture: `EVENT_ONLY` or `NO_CONTENT`** | Grading and forensics need the model's inputs and outputs; those logs then hold employee data and tenant content. Span capture is off regardless. | `EVENT_ONLY` at Stage 0 into a restricted EU bucket; the data-protection assessment decides before Stage 1. [11](11-prompt-security.md) section 6. |
| **20** | **How do operators authenticate to the control plane?** | Without an answer there is no kill switch, no approval and no veto — the entire enablement plan is unexecutable. | Bind `run.invoker` to the operator group for day one, and build the approval surface before Stage 1's first real write. |

## Verified since the first draft — these are now closed

Recorded here so nobody re-opens them.

| Was open | Answer, verified 2026-09-07/08 |
|---|---|
| Agent Engine in europe-west1? | **Yes.** Agent Runtime, Sessions and Memory Bank are GA there, with EU at-rest residency. |
| How does Gemini Enterprise pass the end-user identity? | As `user_id` = the user's **email**, surfacing as the ADK session user id. Asserted by the caller, so lock down `reasoningEngines.query` and re-check group membership server-side. |
| Registration flow for a custom agent? | Console: Agents → Add agent → Custom agent via Agent Runtime, with the `reasoningEngines` resource path. Sharing is per-agent, and supports Google Groups. |
| Do Chat methods need an app identity? | **Partly — and the earlier "no" was misleading.** The robot's user token can post **text** messages. Cards, buttons and interactive widgets require app authentication, so the one-click approval and veto surface does need a Chat app. |
| Current deployment SDK? | `vertexai.Client(project, location).agent_engines.create(...)`. The old module API is deprecated. |
| Can the Alert Center API be used? | **No** — it requires domain-wide delegation. Replaced by Workspace audit-log sharing into Cloud Logging, which needs no credential and gives Eve an independent view. |
| Are there Workspace Events for directory changes? | No. The Events API covers Chat, Meet and Drive. Use the Cloud Logging route. |
| Deleted-user restore window? | 20 days, and it needs a spare licence. This is why deletion is not in the catalogue. |
| Can the admin role be OU-scoped? | Yes, `scopeType=ORG_UNIT` — so Workspace enforces scope independently of our code. Whether *group* privileges honour OU scope is still unverified; the design assumes not. |

## Still to verify in console during build

1. The exact custom-role privilege names covering licence read and assignment.
2. Whether your Gemini Enterprise app is in the `eu` multi-region, `us`, or `global`,
   and which project hosts it (`GEMINI_PROJECT`) and that project's number
   (`GEMINI_PROJECT_NUMBER`), from which the service-agent principal
   `service-<GEMINI_PROJECT_NUMBER>@gcp-sa-discoveryengine.iam.gserviceaccount.com` is
   built — never from Wall-E's number. An `eu` app can front a `europe-west1` agent; a
   `global` app can front any region.
3. Your Workspace edition, which determines whether OAuth and SAML audit events can be
   shared to Cloud Logging — and therefore whether the event trigger class is viable at
   all. Note **Drive audit events are not among the shareable types** in any edition.
   Also confirm the edition supports the login reporting rule in Phase 1.
4. Whether your GCP session-control policy would affect the robot's token — it will not
   if `cloud-platform` is never requested, which is the rule.
5. Whether Agent Identity satisfies the Cloud Run hop in practice. It is generally
   available and supported on both ends, so this is a build check, not an unknown —
   [decision 19](#).
6. Whether group-management privileges honour OU scoping.
7. Current Agent Runtime and Sessions unit prices — the pricing page did not render for
   automated reading.

## Raised by the design challenge of 2026-09-11

[14-hld-challenge.md](14-hld-challenge.md) re-examined the high-level design with the set
complete and nothing built. Its verdict is that the architecture is the correct path and that
sixteen further decisions are open. The reasoning, the evidence and the challenge each one
comes from are on that page; only the decisions are repeated here.

Three are blocking, and two of those come due before the Phase 9 consent, which cannot be
undone.

| # | Decision | Why | Recommendation | Gate |
|---|---|---|---|---|
| **26** | **Is the admin principal a keyless service account holding the custom role, rather than the robot user?** | Google documents that any role except Super Admin can be assigned to a service account with no DWD. If it covers Directory, Licensing and Reports, the password, recovery path, hardware key, consent, frozen scope set and stealable token all disappear. | Spike on a throwaway service account with the reader role through ADC. If it passes, the admin half moves; Gmail, Chat and Calendar stay on a user with no admin role. | **Blocking — before Phase 9 consent, which is irreversible** |
| **27** | **Catalogue breadth: ratify bands B and C** | The requirement was narrowed and never signed off, and scopes freeze at consent. | Wall-E is a narrow operator, not a stand-in for a super admin. Read the bands table and say which band-B exclusions you disagree with. | **Blocking — before [decision 3](09-open-decisions.md)** |
| **28** | **Does a human request or approval have to fall inside the requester's own admin scope?** | Group membership currently grants the robot's whole allowlisted reach. Harmless with one super-admin operator, a privilege-escalation path the day a second operator is added — and [SETUP.md](SETUP.md) Phase 1 already names one. | Yes, but through the committed operator list rather than a live check: record each operator's admin role, families and OU reach before they are added, and reconcile daily against `roleAssignments.list`. Live policy step 5b — privilege-level for Groups and Reports, which Google does not OU-scope, full OU intersection for the rest — is the stronger form and is deferred, because it would put a fail-closed live Directory read on the approval path of a one-person rota and rests on a privilege mapping the set records as unverified. | Before S1 and **before any operator who is not a super admin** |
| **29** | **Where does a change to the gate first execute?** | Today: as the production credential holder, against the production tenant. Group-family writes have no containment but the code under test. | Offline harness by default; a second robot scoped to the sandbox OU with no customer-scoped Reader, in Wall-E's project (`WALLE_PROJECT`). A separate tenant only if F3/F3b autonomy is wanted. | Before Stage 1's first write; the tenant sub-question before any F3/F3b cell leaves L1 |
| **30** | **Control-plane durability: RPO, RTO and the restore protocol** | A restore silently rolls back halts, overrides, nonces, dedup records and counters. | PITR, delete protection and daily backups at Phase 7; a restored control plane starts at `halt_all` and is reconciled against BigQuery before it resumes. | Before Phase 7 completes |
| **31** | **Evidence durability and retention** | `walle_audit` is inside teardown's blast radius, recreation destroys undelete, and grades live only in Firestore. | Write-ahead grades to BigQuery and teardown guards now; an off-project copy at Stage 1 — Eve's `walle_audit` mirror in `EVE_PROJECT` is the natural candidate (decision 51 in [../project-topology.md](../project-topology.md)); the decision itself is unchanged. Moves [decision 17](09-open-decisions.md) earlier and makes it a minimum *and* a maximum. | Before Stage 1 |
| **32** | **Do fully pinned T1/T2 playbooks need a model at all?** | Everything the model would decide is already pinned; keeping it there carries the A3/A11 class and all the platform churn. | Deterministic by default with a typed predicate; `requires_model` per playbook by exception, entering at L0 and tainted. | Before S0 shadow evidence is collected |
| **33** | **Promotion and demotion statistics** | Point thresholds on 20–30 items promote a 90 % playbook about one time in five and demote an on-target one about one window in four. | Wilson interval gates with hysteresis; `unsure` reported separately. The gate forces the sample floor up and cannot be decided apart from it: at n = 30 even a flawless record gives a Wilson 95 % lower bound of 0.886, so [05](05-autonomy-ladder.md) §7's "≥ 30 proposals graded per family" must rise to ≥ 35 or no cell is ever promotable. | Before the first item is graded |
| **34** | **Eve is a deterministic verifier; no LLM produces an approval** | Already decided in [12](12-agent-identity.md) section 1.8 and contradicted in four other pages. Eve's designer will inherit whichever version they read. | State it in 01, 05, 06 and 08. Until an Eve design record exists, "Eve v0" is BigQuery scheduled queries read by a human. | Now for the wording; before S3 for the design record |
| **35** | **Who may receive per-person reporting output?** | `walle-readers@` is specified on the write axis only, and there is no aggregate-only operation to give a non-admin. | Answer inside [decision 8](09-open-decisions.md): aggregate-only family with a minimum cell size (`Assumption:` 5), or no readers beyond admins. | Before the first reader is onboarded |
| **36** | **What does Stage 0 actually provision?** | Phase 15 and the KMS key are now Eve's, provisioned in `EVE_PROJECT` by Eve's setup (2026-09-13); what Wall-E's Stage 0 could still provision early is only the `eve-controller@EVE_PROJECT` allowlist entries, the cross-project bindings on Wall-E's resources, and `walle-events`, none of which has a consumer; a consented Eve token dies after six months unused. | Stage 0 provisions what Stage 0 uses; seams stay in code as contracts, audit columns and a CI-only stub caller. | Before Phase 1 |
| **37** | **Second pair of hands during the build (splits [decision 11](09-open-decisions.md) into 11a)** | Separation of duties, the external validator and credential recovery all need another person before Phase 10, not before S1. | Name a security reviewer with code ownership on the ceiling module, policy chain, catalogue and validator; a validator custodian; and a second person trained and witnessed on the Phase 9 re-bootstrap. | Before Phase 10 |
| **38** | **Value baseline and stop rule** | No baseline, no stop rule, and a cost table missing its largest line — human time. | Measure four weeks of baseline toil before Phase 1; dated stop-or-continue review at S1 exit. | Baseline before Phase 1; review at S1 exit |
| **39** | **Robot account lifecycle: detection, custody and rebuild** | No detection of another administrator acting on the robot, no paging class for a removed role assignment, no rebuild path past the 20-day deletion window. | Activity rule (Google's current name for a reporting rule) on admin events targeting the robot; `role_assignment_missing` as a paging class; second vault custodian; rebuild checklist. | Before S0 opens |
| **40** | **Google-side contract drift probe** | Two dependencies fail silently on the autonomous path: the admin audit event names the playbook `trigger` fields key on, and the robot's actually-assigned privilege set for reads other than the admin enumeration. Loud breaks, such as a renamed privilege returning 403, are already caught by the closed error enum, verification and the breaker. | Extend the existing daily drift job: privilege-name and event-name diffs set `no_autonomous`; discovery-revision bumps are informational and freeze promotions. No SKU diff — Google renames SKU display names while the ids stay stable, and the Licensing API takes ids ([C54](14-hld-challenge.md#c54--google-side-contract-drift-is-watched-for-model-armor-but-not-for-the-workspace-apis-stands)). | Before Stage 1 |
| **41** | **Single region, accepted** | Everything but BigQuery is in one region and nothing records that as a decision. | Accept, with RTO equal to Google's regional recovery, because multi-region would cost a residency analysis and duplicated engines for a system that is not business-critical. | Record now; non-blocking |

## Raised by the four-project topology of 2026-09-13

[../project-topology.md](../project-topology.md) moved Eve, Mo and the Gemini Enterprise
app out of Wall-E's project and wrote down every grant that crosses. It opened decisions
42 to 52; all are recorded there. Decision 42 is repeated here because it gates Wall-E's
own Phase 7 registration.

| # | Decision | Why | Recommendation | Gate |
|---|---|---|---|---|
| **42** | **Does the custom role `walleEngineQuery`, bound on the engine to `service-<GEMINI_PROJECT_NUMBER>@gcp-sa-discoveryengine…`, suffice for a Gemini Enterprise app in another project to register and invoke Wall-E?** | Google documents only the project-level `roles/discoveryengine.serviceAgent` on the agent project for the cross-project case; the design's grant is narrower, and the project-level role carries `reasoningEngines.create`, `update` and `delete` on every engine in `WALLE_PROJECT`. | Spike on a throwaway engine: apply the engine-scoped binding only, run the Phase 7 registration and one query. On success it is the grant. On failure apply the documented project-level role on `WALLE_PROJECT`, record it as the topology's single named project-level exception with the failing error, and note that the three-principal lock then holds only because `WALLE_PROJECT` contains exactly one engine. | Before Phase 7 registration |
| **43–52** | Registry viewer for Eve and Mo (drop); Eve's Firestore read; `walle-events` subscriptions; who asserts Eve-side drift; Eve's check of `walle_workspace_logs`; Eve's carve-out list; Mo on the linked spans dataset; the CI ingestion identity; the off-project evidence copy; ownership and budgets | Each is a grant that would otherwise cross a project boundary implicitly. | See [../project-topology.md](../project-topology.md) §8. | Per row there |

## Sources for the verified rows

Google Cloud documentation, read 2026-09-07 and 2026-09-08: Agent Platform supported
locations for agents; Agent Engine SDK migration guide; register and manage an ADK agent
in Gemini Enterprise; share custom agents; Gemini Enterprise locations; Agent Identity with
Agent Runtime. Google Workspace developer documentation: Admin SDK Reports push
notifications; Alert Center authorization; Admin SDK Directory limits and roles; Chat
authentication and authorization; Enterprise License Manager. Google Workspace admin help:
restoring a recently deleted user. ADK release notes on GitHub for versions 2.5 to 2.8.
