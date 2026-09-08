# 9. Decisions to make before build

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-08

Answer these, then record each as a dated file in [`../../decisions/`](../../decisions/).
Nothing in that directory yet — Edge AI v2's ten decisions were never written down, so
Wall-E starts by closing the ones it inherits.

## Blocking — the build cannot start without these

| # | Decision | Why it blocks | Recommendation |
|---|---|---|---|
| **1** | **Wall-E replaces Edge AI v2, or coexists with it?** | Everything in this set assumes replacement. If Edge is meant to live, the two would share a robot account and contend on the same policy engine. | **Replace.** Edge's design is sound and Wall-E keeps all of it that still holds; the scaffold was never run, so nothing is lost. Mark Edge superseded. |
| **2** | **Names**: project id, robot account, OU, groups, BigQuery dataset, OAuth app name | The consent screen shows the app name to the robot and is awkward to change afterwards. Every script hard-codes the rest. | Decide in one sitting. `walle-` prefix throughout; robot `walle@<domain>`. |
| **3** | **The complete OAuth scope list** | Scopes freeze at consent. Adding one later means redoing the bootstrap and the Trusted-client step. | Take the list in [02](02-identity-and-auth.md) as the proposal. The two live questions: include `admin.directory.user.security` (sign-out, token revocation) for leaver hygiene? And confirm you do **not** want `drive`. |
| **4** | **Ratify the "must never happen" list** | It is the ceiling every other control is calibrated against, and I wrote it without you. | Read [06](06-security-guardrails.md) §"blast-radius ceiling". Nine rows. Tell me which you disagree with. |
| **5** | **Which OUs, and is a sandbox OU possible?** | Every write scope limit references an OU allowlist that is currently `tbd`, and Stage 0 shadow plans need somewhere safe to point. | A sandbox OU with synthetic accounts, plus one small real pilot OU. Without a sandbox, Stage 1 has to run against real users, which I would not do. |

## Needed before Stage 1 (the first real write)

| # | Decision | Why it matters | Recommendation |
|---|---|---|---|
| **6** | **Which model, pinned by id** | Not every current model has EU data residency. The id goes on every audit row so Mo can attribute behaviour changes. | Pick from the per-model EU residency table at build. Do not assume the newest is eligible. |
| **7** | **Data retention after removing a licence** on the organisation's plan | Licence reclaim is the clearest early saving, and on an *active* account it may destroy data. | Ask your Google account team before any active account is in scope. Until answered, reclaim only from suspended accounts. |
| **8** | **DPIA and works council** | Autonomous admin action is a **different processing activity** from human-requested action. Longest lead time in the plan. | Ask in week one, in parallel with build. Frame it in two parts: reads now, autonomous writes before Stage 3. |
| **9** | **Cloud Run ingress and network isolation** | Edge AI v2 specified internal-only; Agent Runtime may not qualify as internal traffic. | Deploy with IAM as the boundary and test. Add a PSC interface only if the organisation's network policy demands it. |
| **10** | **Does Eve get its own read-only Workspace credential?** | Without one, Eve verifies through the thing it is verifying. | **Yes.** One more bootstrap, and it is what makes verification independent. |
| **11** | **Who else is an operator, and who is the second approver?** | L4 and L5 promotions need two named humans. A one-person rota also means approvals stall whenever you are away. | Name at least one more DWP admin for `walle-operators@`, and someone from IT security as the second approver for high-risk promotions. |
| **12** | **Which playbooks first?** | The four in this design are my guesses. The ladder does not depend on them, but Stage 0's shadow evidence does. | Tell me the three admin tasks that waste the most of your time. My guesses: licence reclaim from suspended accounts, leaver group hygiene, stale-account reporting. |

## Needed before autonomy (Stage 3 onward)

| # | Decision | Why | Recommendation |
|---|---|---|---|
| **13** | **Is there an HR system of record** reachable as an event source? | Autonomous suspension at Stage 5 is only acceptable when the trigger is authoritative, never free text. | If there is none, F5 suspend stops at L3 permanently. That is an acceptable outcome. |
| **14** | **Approval and notification surface** | Operators need somewhere to approve and read digests. The approver's identity must be verifiable by the service. | Google Chat if Chat is in use; otherwise Gemini Enterprise messages. A branded Chat app is nice-to-have, not v1. |
| **15** | **Business hours, timezone, freeze windows** | Hard-coded into every autonomous run's gate. | `Assumption:` Europe/Paris, Mon–Fri, last write 16:00. Correct me. |
| **16** | **Budgets and caps** | The numbers in [05](05-autonomy-ladder.md) are defaults I chose. | Revisit at each stage decision rather than now. |
| **17** | **Audit retention** | 400 days is my default. | Align with the organisation policy. |

## Verified since Edge AI v2 — these are now closed

Recorded here so nobody re-opens them.

| Was open | Answer, verified 2026-09-07/08 |
|---|---|
| Agent Engine in europe-west1? | **Yes.** Agent Runtime, Sessions and Memory Bank are GA there, with EU at-rest residency. |
| How does Gemini Enterprise pass the end-user identity? | As `user_id` = the user's **email**, surfacing as the ADK session user id. Asserted by the caller, so lock down `reasoningEngines.query` and re-check group membership server-side. |
| Registration flow for a custom agent? | Console: Agents → Add agent → Custom agent via Agent Runtime, with the `reasoningEngines` resource path. Sharing is per-agent, and supports Google Groups. |
| Do Chat methods need an app identity? | **No.** The robot's user token can post and manage spaces it belongs to. A Chat app is optional UX. |
| Current deployment SDK? | `vertexai.Client(project, location).agent_engines.create(...)`. The old module API is deprecated. |
| Can the Alert Center API be used? | **No** — it requires domain-wide delegation. Replaced by Workspace audit-log sharing into Cloud Logging, which needs no credential and gives Eve an independent view. |
| Are there Workspace Events for directory changes? | No. The Events API covers Chat, Meet and Drive. Use the Cloud Logging route. |
| Deleted-user restore window? | 20 days, and it needs a spare licence. This is why deletion is not in the catalogue. |
| Can the admin role be OU-scoped? | Yes, `scopeType=ORG_UNIT` — so Workspace enforces scope independently of our code. Whether *group* privileges honour OU scope is still unverified; the design assumes not. |

## Still to verify in console during build

1. The exact custom-role privilege names covering licence read and assignment.
2. Whether the organisation's Gemini Enterprise app is in the `eu` multi-region, `us`, or `global`.
3. the organisation's Workspace edition, which determines whether OAuth and SAML audit events can be
   shared to Cloud Logging.
4. Whether the organisation's GCP session-control policy would affect the robot's token — it will not
   if `cloud-platform` is never requested, which is the rule.
5. Whether Agent Identity's SPIFFE credential satisfies Cloud Run IAM on the agent-to-action
   hop. If it does, adopt it and drop the long-lived service-account path.
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
