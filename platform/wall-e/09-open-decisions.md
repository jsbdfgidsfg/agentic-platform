# 9. Decisions to make before build

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-09

Answer these, then record each as a dated file in [`../../decisions/`](../../decisions/).
Nothing in that directory yet — none of these decisions has been written down, so
Wall-E starts by closing them.

## Blocking — the build cannot start without these

| # | Decision | Why it blocks | Recommendation |
|---|---|---|---|
| **1** | **Does any other automation already write to the same Workspace objects?** An HR-driven directory sync, a licence-management script, a joiner/leaver tool. | Two writers on one object is the collision this design's pre-state re-read exists to catch, but it is far better to know up front. | **Inventory every existing writer before Stage 1** and give each a named owner. |
| **2** | **Names**: project id, robot account, OU, groups, BigQuery dataset, OAuth app name | The consent screen shows the app name to the robot and is awkward to change afterwards. Every script hard-codes the rest. | Decide in one sitting. `walle-` prefix throughout; robot `walle@<domain>`. |
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
| **10** | **Does Eve get its own read-only Workspace credential?** | Without one, Eve verifies through the thing it is verifying. | **Yes.** One more bootstrap, and it is what makes verification independent. |
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
| **19** | **Adopt Agent Identity now?** | It is generally available, gives the agent a per-agent SPIFFE identity with 24-hour certificates instead of a long-lived service account, and removes a standing credential. | Yes, unless the build finds it cannot satisfy the Cloud Run hop. This was wrongly listed as unverified. |
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
2. Whether your Gemini Enterprise app is in the `eu` multi-region, `us`, or `global`.
   An `eu` app can front a `europe-west1` agent; a `global` app can front any region.
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

## Sources for the verified rows

Google Cloud documentation, read 2026-09-07 and 2026-09-08: Agent Platform supported
locations for agents; Agent Engine SDK migration guide; register and manage an ADK agent
in Gemini Enterprise; share custom agents; Gemini Enterprise locations; Agent Identity with
Agent Runtime. Google Workspace developer documentation: Admin SDK Reports push
notifications; Alert Center authorization; Admin SDK Directory limits and roles; Chat
authentication and authorization; Enterprise License Manager. Google Workspace admin help:
restoring a recently deleted user. ADK release notes on GitHub for versions 2.5 to 2.8.
