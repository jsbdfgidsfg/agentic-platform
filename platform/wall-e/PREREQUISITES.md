# Prerequisites for the administrator

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-15
- Objective: 2026-09-13 — `$ROBOT` holds **Super Admin** (P33), not a narrow custom role ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) "What this reverses and what it costs", §0.4, §13.1).
- Topology: 2026-09-13 — four GCP projects, all beneath `$FOLDER_ID`. `$PROJECT` on this page is Wall-E's own project (`WALLE_PROJECT` elsewhere); `$GEMINI_PROJECT`, `$EVE_PROJECT` and `$MO_PROJECT` are the other three. [../project-topology.md](../project-topology.md) is the authority for placement and for every cross-project grant.
- Applies to: [SETUP.md](SETUP.md) (Phases 1 to 18), [setup/README.md](setup/README.md) and [setup/walle.env.example](setup/walle.env.example)
- Last executed: never. Nothing in the Wall-E stack is built yet. **Superseded on 2026-09-15; do not work from this page.** Start at [../agentic-platform/setup/README.md](../agentic-platform/setup/README.md); its files 01, 03 and 04 carry what is salvaged from here.

Read this page before you open [SETUP.md](SETUP.md). It lists everything that must already be true, decided, granted, bought or installed before the first command, plus the long-lead items that block later stages. It does not repeat the runbook's steps. Where the runbook and this page disagree, [SETUP.md](SETUP.md) wins, and the disagreement is listed under [Gaps this page found](#10-gaps-this-page-found) so the runbook can be fixed.

## How to use this page

Work in the order given below, not in section order. Every table has a tick-box column. Tick a row when its "How to verify" check passes, not when someone says it is done. Rows marked `Assumption:` are inferred, not stated in the stack. Confirm them before relying on them. "Needed by" gives the earliest phase, stage or `./walle` subcommand that fails without the row.

Sections are numbered for cross-reference, not for execution order. The order the work actually happens:

1. §1 decisions D1, D3, D5, D8 and the D7 question (week one — D7 has the longest lead time).
2. §7.1 tools installed, `gcloud auth login`, Application Default Credentials.
3. §7.2 `~/.walle-env` copied and filled.
4. §5.1 row 1: the M0 host project and the operator OAuth client — needed **before** `./walle workspace`, ahead of everything else in §4 and §5.
5. §9 long-lead procurement: security keys, Gmail licences, organisation-level role grants (§4.1).
6. §3 Workspace checks, then §11, then Phase 1.
7. §4.2, §5 (the rest), §6.2: run once `$PROJECT` exists, after Phase 6.

Every command on this page that contains a `$VARIABLE` assumes the config file is loaded. Copy [setup/walle.env.example](setup/walle.env.example) to `~/.walle-env` (§7.2) — it is shell-sourceable on purpose — and in every terminal you use:

```bash
source ~/.walle-env
gcloud auth login   # the signed-in account must equal OPERATOR_EMAIL
```

If a command errors with an empty path segment (`folders//locations`, `projects/`) or an empty `--project=`, you have not sourced the file. `SA_OPS_CALLER` is the one exception: it is derived, not a config key (§3.1).

---

## 1. Decisions to close first

[SETUP.md](SETUP.md) §1.1 holds the reasons and the recommendations. This table only says when each decision must be closed. SETUP.md asks for a written answer to every row before Phase 1, even the rows that only block later work.

D1 to D8 are SETUP.md's own set. D9 to D12 come from the design challenge of 2026-09-11 ([14](14-hld-challenge.md), recorded as [09](09-open-decisions.md) decisions 26, 27, 36 and 38) and are listed in number order like the rest, so read the "Close before" column rather than the position: **D10 gates the Phase 9 consent, which cannot be undone** (D9 gated it too until it closed for Wall-E on 2026-09-13), D11 and D12 gate Phase 1, and D13 gates the Phase 2 super-admin grant.

| Done | # | Decision | Close before | Why | Recorded in |
|---|---|---|---|---|---|
| [ ] | D1 | Names: the four project ids (`GEMINI_PROJECT`, `WALLE_PROJECT` — `PROJECT` in this stack — `EVE_PROJECT`, `MO_PROJECT`) and `FOLDER_ID`, robot address, organisational unit paths, group addresses, BigQuery dataset, **OAuth app name** | Phase 1 | The OAuth app name is shown to the robot at consent and is awkward to change. Every command hard-codes the rest. A project id can never be reused after a delete. | [09](09-open-decisions.md) decision 2 |
| [ ] | D2 | The frozen OAuth scope lists — since 2026-09-13 **two**, one per client (decision 3 reopened): list 1 for the narrow client and list 2 for the broad client of `walle-actions-super`; `cloud-platform` in neither. The lists, what each scope serves, and the scopes deliberately left out: [02 "Scopes"](02-identity-and-auth.md#scopes) | Answer before Phase 1. Final before Phase 9. | Scopes freeze at the Phase 9 consent and are the only Google-enforced ceiling left on a super-admin credential. Widening the broad list later is a re-consent of that client only. | [09](09-open-decisions.md) decision 3; [SETUP.md](SETUP.md) §1.2, §1.3; [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.1 item 3 |
| [ ] | D2b | **Eve's frozen scope list**, consented in Eve's own project by [Eve's runbook](../eve/07-build-runbook.md) (SETUP.md Phase 15 is retired since 2026-09-13). The list — ten read-only scopes, `apps.licensing` dropped — and its consequences: [eve/02 "The scopes, and the one that was dropped"](../eve/02-identity-and-auth.md#the-scopes-and-the-one-that-was-dropped) | Answer before Phase 1. Final before Eve's consent, in Eve's runbook. | Eve's grant freezes at her consent exactly as the robot's does. | [../eve/02-identity-and-auth.md](../eve/02-identity-and-auth.md#the-scopes-and-the-one-that-was-dropped); `EVE_SCOPES` in [setup/walle_setup.py](setup/walle_setup.py) still carries the older list ([setup/README.md](setup/README.md#where-this-differs-from-the-documents)) |
| [ ] | D3 | Sandbox organisational unit with synthetic accounts, plus one small real pilot unit; since 2026-09-13 also a **sandbox tenant** for the super-admin tier's non-production (PSA6) | Phase 1; the sandbox tenant before the Phase 2 grant | Stage 0 shadow plans and the OU allow-list need a unit to name. Super Admin cannot be scoped to a unit (P33), so the unit is enforced by code only, and K6 and the multi-party approval tests run on the sandbox tenant. Without a sandbox, Stage 1's first writes land on real employees. | [09](09-open-decisions.md) decisions 5 and 29; [../agentic-platform/02-landing-zone-and-tiers.md](../agentic-platform/02-landing-zone-and-tiers.md) §1.3 PSA6 |
| [ ] | D4 | Ratify the nine blast-radius rows in [06](06-security-guardrails.md), and since 2026-09-13 **the two lists** (hard-denied in every lane; band B at tier `SUPER` only), owner-signed | Before build; the two lists before the Phase 2 grant | Every other control is calibrated against those rows; under Super Admin the lists are enforced by code only. | [09](09-open-decisions.md) decision 4; P29 |
| [ ] | D5 | A second operator in `walle-operators@`, and someone from IT security as second approver | Phase 1 | A one-person operators group means every kill switch depends on you being reachable. L4 and L5 need two named humans. | [09](09-open-decisions.md) decision 11 |
| [ ] | D6 | Inventory of other automation that writes the same Workspace objects (directory sync, licence scripts, joiner and leaver tools), each with a named owner | Stage 1 | Two writers on one object collide. | [09](09-open-decisions.md) decision 1 |
| [ ] | D7 | The data-protection question, and employee representative bodies where your jurisdiction has them | **Ask in week one.** Blocks Stage 3. | It has the longest lead time in the plan. Autonomous action is a different processing activity from human-requested action. | [09](09-open-decisions.md) decisions 8 and 25 |
| [ ] | D8 | Gemini Enterprise app project (`GEMINI_PROJECT`, and its number `GEMINI_PROJECT_NUMBER`) and location, which must be `eu` or `global` | Phase 6 | Everything from Phase 6 on is regional. A `us` app cannot front a `europe-west1` agent. The Discovery Engine service agent that queries the engine is built from `GEMINI_PROJECT_NUMBER`, never from Wall-E's number. | [SETUP.md](SETUP.md) §1.1; `GEMINI_APP_LOCATION`, `GEMINI_PROJECT`, `GEMINI_PROJECT_NUMBER`; [../project-topology.md](../project-topology.md) §3 row 1 |
| [x] | D9 | Is the admin principal a keyless service account holding the custom role, rather than the robot user? | **Closed for Wall-E on 2026-09-13 by a Google fact**, not by a spike: a service account can hold any admin role except Super Admin ([Google](https://knowledge.workspace.google.com/admin/users/assign-specific-admin-roles)), and the objective requires Super Admin, so the admin principal is the robot user. The question survives for Eve's read-only role as E-16. | Before P33 (2026-09-13) decision 26 gated the Phase 9 consent with a spike whose success would have removed the password, recovery path, key and stealable token from the admin half. That benefit is now available only to Eve. | [09](09-open-decisions.md) decision 26 (superseded for Wall-E by P33); [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §4.6 |
| [ ] | D10 | Ratify which operations go to which of the three bands A, B and C ([03 "The three bands"](03-lld.md#the-three-bands)). Since the objective of 2026-09-13 requires "any super admin level action", decision 27 is "which lane", not "whether"; these bands are not the same B and C as the 2026-09-11 challenge's | Before D2, because the broad client's scopes freeze at consent | The narrowing is answered by the objective itself; what remains is to sign which operations go to which lane. | [09](09-open-decisions.md) decision 27; [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.1 "The three bands" |
| [ ] | D11 | What does Stage 0 actually provision? | Phase 1 | Phase 15 and the KMS key are Eve's, provisioned in `EVE_PROJECT` by Eve's setup. What Stage 0 might provision early in `WALLE_PROJECT` — the `eve-controller@EVE_PROJECT` allowlist entries, the cross-project bindings on Wall-E's resources, and `walle-events` — has no consumer yet. Stage 0 should provision what Stage 0 uses. | [09](09-open-decisions.md) decision 36; [../project-topology.md](../project-topology.md) §7.1 |
| [ ] | D12 | Four weeks of baseline toil measured, and a dated stop-or-continue rule | Baseline before Phase 1; review at S1 exit | There is no baseline, no stop rule, and the cost table is missing its largest line, human time. | [09](09-open-decisions.md) decision 38 |
| [ ] | D13 | **The super-admin grant and its gate**: the decision record `decisions/2026-09-13-wall-e-holds-super-admin.md` signed by the owner, the TISAX deviation signed by the security reviewer, and the dated, signed P-SA gate checklist G1–G11 of [SETUP.md](SETUP.md) Phase 2 | Phase 2 step 5, the assignment | The grant turns a leaked token or an interactive login into a tenant compromise; nothing at Google narrows it afterwards. It is a gate, not a runbook step. | P33; [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §0.4, §13.1 item 12 |

Not blocking, but settle them before Phase 14:

| Done | Item | Default until decided | Recorded in |
|---|---|---|---|
| [ ] | Business hours and timezone | `Assumption:` Europe/Paris, Monday to Friday, last write 16:00 | [09](09-open-decisions.md) decision 15; `TIMEZONE`, `PLAYBOOK_SCHEDULE` |
| [ ] | Audit retention | `Assumption:` 400 days | [09](09-open-decisions.md) decision 17 |
| [ ] | The three admin tasks that waste the most of your time. They become the Stage 0 shadow playbooks. | The four names in `PLAYBOOK_JOBS` are guesses | [09](09-open-decisions.md) decision 12 |

Four decisions come due during the build, not before it:

| Done | Decision | Close before | Why | Recorded in |
|---|---|---|---|---|
| [ ] | Agent Identity or `walle-agent@`, decided from the spike on a throwaway engine | Phase 12, the first production deploy | `identity_type` is fixed when the engine is created and cannot be patched | [09](09-open-decisions.md) decision 19; `AGENT_IDENTITY_MODE` |
| [ ] | Control-plane durability: RPO, RTO and the restore protocol | Phase 7 completes | A restore silently rolls back halts, overrides, nonces, dedup records and counters. | [09](09-open-decisions.md) decision 30 |
| [ ] | A second pair of hands named: a security reviewer with code ownership, a validator custodian, and a second person witnessed on the Phase 9 re-bootstrap. Since 2026-09-13 counted, not promised: 1 human at Stage 0, 3 at Stage 1, **4 at the super-admin grant** (P137) | Phase 10; the count before the Phase 2 grant | Separation of duties, the external validator and credential recovery all need another person before Phase 10, not before Stage 1. | [09](09-open-decisions.md) decision 37 (superseded by P137 with a count) |
| [ ] | Model Armor blocking threshold and confidence level | Stage 1 | Templates start inspect-only. Blocking is turned on from Stage 0 measurements. | [09](09-open-decisions.md) decision 24; `MODEL_ARMOR_ENFORCE_DECISION` |

---

## 2. People

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | You: Workspace super admin **on a separate admin account** (`sa-1-admin@` in the roster), Gemini Enterprise Admin (`roles/discoveryengine.agentspaceAdmin`), and holder of the GCP roles in §4 | You run every phase | §3 and §4 checks | Phase 1 | you |
| [ ] | **A second human super admin outside the Wall-E administration line** (IT security; `sa-2-admin@`; owner of `eve-owners@`), who approves the Phase 2 assignment under multi-party approval, holds key B, is on the K5/K6 rota and approves band-B `SUPER` requests | The robot must never be the only or a recovery super admin; the two-person rules of the privileged tier need two humans; reports about the administrator go to someone outside his line. Without this person the grant is not made ([../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §8.1). | Named in D13's record; the roster committed; Admin console → Admin roles → Super Admin lists both human admin accounts | Phase 2 (gate line G3) | IT security |
| [ ] | A named security reviewer with code ownership on the ceiling module, policy chain, catalogue and validator; a validator custodian; and a second person trained and witnessed on the Phase 9 re-bootstrap | Separation of duties, the external validator and credential recovery | Names recorded in the decision 37 record | Phase 10 | you and security |
| [ ] | A second operator, a Workspace admin, named in `SECOND_OPERATOR` and added to `walle-operators@` | Halt, demote, veto and approve must not depend on one person. An empty value is accepted, and the script records it as a known risk. | `SECOND_OPERATOR` is non-empty in `~/.walle-env` | Phase 1 (D5) | you and the second operator |
| [ ] | A second approver from IT security | L4 and L5 need two named humans. Name the person now, although they are only needed at Stage 4. | Name recorded in the D5 decision | Stage 4, named before Phase 1 | security |
| [ ] | An IT security contact who, with the operators group, is the only reader of `walle-content-logs` | That bucket holds raw prompts and personal data | Name recorded. **Nothing in the stack restricts this bucket.** Cloud Logging has no bucket-level IAM: read access runs through the bucket's log views with `roles/logging.viewAccessor`, condition-scoped to `projects/$PROJECT/locations/$REGION/buckets/walle-content-logs/views/<view>`, and any project-level holder of `logging.views.access` (`roles/logging.viewer`, `roles/logging.admin`, `roles/logging.privateLogViewer`, or basic `owner`/`editor`/`viewer`) reads it regardless. After Phase 12c, list them with `gcloud projects get-iam-policy "$PROJECT" --flatten='bindings[].members' --format='table(bindings.role,bindings.members)' --filter='bindings.role:(logging OR roles/owner OR roles/editor OR roles/viewer)'` and prune by hand (§10 item 21). `Assumption:` a freshly created project has no project-level logs reader other than you. | Phase 12c | security |
| [ ] | The owner of organisation-level Cloud Logging, consulted before audit-log sharing is turned on | Sharing adds organisation-wide admin activity to ingestion, the largest cost line. They know whether `_Default` excludes it. | Their answer recorded in the build log | Phase 5 (M4) | external party |
| [ ] | Data protection, and employee representative bodies where they exist | D7. Longest lead time. | Question sent, date recorded | Week one; blocks Stage 3 | legal/DPO, HR |
| [ ] | An owner for each existing writer found in D6 | Collisions on shared objects | Inventory with owners | Stage 1 | you |
| [ ] | An owner and a principal for Mo (`MO_PRINCIPAL`) | `./walle deploy` binds it as `run.invoker` on `walle-actions` and adds it to `READ_CALLER_ALLOWLIST` (Wall-E's Phase 10 step), and Mo does not exist yet: the account is created by Mo's runbook (Mo-6), and until then `deploy` records the binding as pending and is re-run. No registry role is granted to it (decision 43, §6.2), and `./walle registry` does not read it. `validate_config` refuses a principal outside `MO_PROJECT`. | `serviceAccount:mo-analyst@$MO_PROJECT.iam.gserviceaccount.com`. Mo's other identities, `mo-metrics@` and `mo-narrator@`, also live in `MO_PROJECT` ([../project-topology.md](../project-topology.md) §2); none is created in `$PROJECT`. | Phase 10 (`./walle deploy`: `run.invoker` on `walle-actions` and the `READ_CALLER_ALLOWLIST` entry) | you |
| [ ] | An owner for the CI deployer service account (`CI_DEPLOYER`) | On the per-project registry it is the only principal allowed to write Agent Registry, and no phase creates it. Since 2026-09-13 (P71) the registry is the shared one in `CORE_PROJECT`, written by `factory-apply@`, and `./walle registry` reads `CI_DEPLOYER` only on the local fallback, when `REGISTRY_LOCAL_FALLBACK_DECISION` names a record (§7.2) | *tbd* until the CI pipeline exists. Resolve it by deciding, with whoever owns the deployment pipeline, one of: (a) the pipeline's existing deployer service account — record its full email in `CI_DEPLOYER`; or (b) a dedicated account created by hand before Phase 13b (`gcloud iam service-accounts create walle-ci-deployer --project="$PROJECT"`, then record `walle-ci-deployer@$PROJECT.iam.gserviceaccount.com`), which is then the only principal holding `roles/agentregistry.admin` (§6.2). Record the choice in the build log. Until then `./walle registry` cannot run on the local fallback: it calls `ctx.need("CI_DEPLOYER")` and the value must be a full service account email. | Phase 13b (`./walle registry`), local fallback only | you, until a pipeline owner is named |

---

## 3. Workspace tenant

### 3.1 Roles, accounts, licences and physical artefacts

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | Workspace **super admin**, on a separate admin account | Organisational units, users, groups, Eve's custom role, 2-step verification enforcement, API controls, audit-log sharing; since 2026-09-13 also the Phase 2 Super Admin assignment to `$ROBOT`, multi-party approval, self-recovery Off at the top OU | Before the operator token is cached: Admin console → Account → Admin roles → Super Admin → your account is listed. Once `./walle workspace` has cached your token (M0), `./walle preflight` checks `users.get` `isAdmin`. Before that it prints "not checked". | Phases 1 to 5, Phase 9 step 4. Eve's consent is Eve's runbook, not SETUP.md Phase 15 | you |
| [ ] | **Gemini Enterprise Admin** (`roles/discoveryengine.agentspaceAdmin`) on the app that will front Wall-E, in `GEMINI_PROJECT`, or on that project | Registering the agent and setting its IAM policy to share it. Gemini Enterprise User (`roles/discoveryengine.agentspaceUser`) can create and update an agent but not share it. The app never lives in `$PROJECT`. | Gemini Enterprise console → the app → **Agents** → the agent → **User permissions**: you can add a principal. Project-level grants also show in `gcloud projects get-iam-policy "$GEMINI_PROJECT" --flatten="bindings[].members" --filter="bindings.members:user:${OPERATOR_EMAIL} AND bindings.role:discoveryengine" --format="value(bindings.role)"`, but a grant made at app level, or inherited through a group, will not appear there — so the console tab is the primary check. `Assumption:` no `./walle` command checks this role. | Phase 13 (`./walle register`) | you |
| [ ] | Membership of `walle-operators@` for everyone who pulls the andon cord | Phase 6 grants `roles/iam.serviceAccountTokenCreator` on `walle-operators-caller@` to the group. That is the only way a human can mint an ID token with the right audience: `gcloud auth print-identity-token --audiences=` is refused for user credentials (gcloud accepts the flag only for a service account or an impersonation), so without the grant the andon cord ([SETUP.md](SETUP.md) §5) has no handle you can pull from a terminal. | After Phase 6: `gcloud iam service-accounts get-iam-policy "walle-operators-caller@${PROJECT}.iam.gserviceaccount.com" --flatten="bindings[].members" --filter="bindings.role:roles/iam.serviceAccountTokenCreator" --format="value(bindings.members)"` lists `group:walle-operators@<domain>`, and you and `$SECOND_OPERATOR` are members of that group. (`SA_OPS_CALLER` is not a config key: [SETUP.md](SETUP.md) Phase 6 derives it in-line, so sourcing `~/.walle-env` does not define it.) | Phases 10, 14, 17 | you and `$SECOND_OPERATOR` |
| [ ] | **Spare Workspace licences that include Gmail**: one for `$ROBOT`, one for `$EVE_ROBOT`, and one per sandbox account (at least three; [SETUP.md](SETUP.md) §1.4 plans three or four). Five or six seats in total. The objective of 2026-09-13 requires the robot to be licensed. The two human super admins' separate admin accounts are user accounts too; whether they reuse existing seats is *tbd*. The sandbox tenant (D3) carries its own seats, *tbd*. | The frozen scope list and the Phase 16 mailbox watch need Gmail. A licence without Gmail gives a clean Phase 9 and a failure at Phase 16. | Admin console → Billing → Subscriptions: free seats on a Gmail-bearing SKU. `Assumption:` no purchase order is needed. | Phases 1 and 16; Eve's seat is provisioned by Eve's runbook | tenant |
| [ ] | A Gemini Enterprise licence for every member of `walle-operators@` | The agent is shared per group on the app's **User permissions** tab. An operator without a licence has no front door. | Google Cloud console → **Gemini Enterprise** → **Manage subscriptions** shows the edition (Gemini Enterprise Standard, Plus or Pay-as-you-go); **Manage users** lists each user's licence assignment state, and every member of `walle-operators@` must read ASSIGNED. Only the separate Gemini Enterprise - Business edition is assigned from Admin console → Directory → Users → Assign licences. Subscription-level counts (Admin console → Billing → Subscriptions) only say whether seats exist, not who holds one. | Phase 13 verify | tenant |
| [ ] | Access to a **corporate password vault** | The robot passwords go straight into it, never to the wiki, a ticket or chat | `Assumption:` one exists. You can create an entry. | Phase 1 (M1) | you |
| [ ] | **Four physical security keys** for the robots, labelled — two for `$ROBOT`, two for `$EVE_ROBOT` — plus a spare key for each of the two human admin accounts, a safe, and witnessed custody records. Custodians, spares and the key count: [04 §8.3](../agentic-platform/04-identity-and-privileged-access.md#83-key-custodians) | Hardware-key-only 2-step verification with no recovery path. If the keys are lost after Phase 9, Wall-E is down until Phase 9 is re-run in full. All four robot keys are needed by Phase 3, because M2A checks enrolment on both robots. | Keys in hand. `./walle workspace` checks `isEnrolledIn2Sv` (M2A) before it prints the enforcement step (M2B). | Phase 3 (M2A before M2B); all robot keys by then | you and the second human |
| [ ] | A **clean browser profile**, signed into nothing | A desktop OAuth flow opens the default browser, which is signed in as you, so the grant lands on a super admin ([SETUP.md](SETUP.md) §7.1) | Manual: a new profile with no Google session | Phase 9 (M7); Eve's consent, in Eve's runbook, needs the same | you |

### 3.2 Edition features and tenant settings

This checklist says what the tenant must offer and how to check it. Why each setting exists, and its value on the robot OU, are the account hygiene set in [02 "The account hygiene set"](02-identity-and-auth.md#the-account-hygiene-set) and the privileged tier's session controls and multi-party approval in [04 §8](../agentic-platform/04-identity-and-privileged-access.md#8-the-super-admin-robot-on-the-roster-and-the-privileged-tiers-two-person-rule).

| Done | Requirement | How to verify | Needed by | Holder |
|---|---|---|---|---|
| [ ] | **Super Admin assignable to `$ROBOT`** (P33: not scopable to an organisational unit, not holdable by a service account, no domain-wide delegation), and custom admin roles still available for **Eve's** read-only, customer-scoped role | Admin console → Account → Admin roles: Super Admin → Assign admin, and Create new role, are both available to you | Phase 2 | tenant edition |
| [ ] | **Workspace multi-party approval** available and on for every covered setting, console and API (P66) | Google lists Enterprise Standard and Plus, Education Standard and Plus, Enterprise Essentials Plus, and Cloud Identity Premium, for customers with two or more super admin accounts ([Google](https://knowledge.workspace.google.com/admin/security/multi-party-approval-for-sensitive-actions); [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md#84-workspace-multi-party-approval-the-two-person-rule-google-enforces) §8.4). Confirm the tenant's edition; *tbd* | Phase 2 (gate line G4) | tenant edition; super admin |
| [ ] | Super-admin self-recovery can be set **Off at the top organisational unit** (per OU or configuration group, On by default on most editions: [Google](https://knowledge.workspace.google.com/admin/users/allow-super-administrators-to-recover-their-password)) | By eye at the top OU and every child OU and configuration group | Phase 2 (gate line G5) | super admin |
| [ ] | Google Cloud session control and Context-Aware Access on the Admin console, both scopable to `$SVC_OU` (the hygiene set of SETUP.md Phase 3). CAA needs Frontline Standard/Plus, Enterprise Standard/Plus, Education Standard/Plus, Enterprise Essentials Plus or Cloud Identity Premium; its applicability to super admins is `Assumption:` (P7) | Admin console → Security → Google Cloud session control; Security → Access and data control → Context-Aware Access | Phase 3 | tenant edition |
| [ ] | Permission to create the top-level unit `/Automation` and `/Automation/Service Identities` under it, so Phase 3 hardening applies only to the robots | `Assumption:` allowed. Otherwise nest it where service identities already live and change `SVC_OU`. | Phase 1 | you |
| [ ] | An **activity rule** on the **User log events** data source (the same events Cloud Logging carries as `login.googleapis.com`), for the robot-login alert | Admin console → **Rules** → **Create activity rule** (reporting rules became activity rules throughout September 2025; the older names no longer appear in the console). The login data source is **User log events**, the same source at Reporting → Audit and investigation → User log events. Activity rules need one of: Frontline Standard or Plus; Enterprise Standard or Plus; Education Standard or Plus; Enterprise Essentials Plus; Cloud Identity Premium. Confirm the tenant holds one of these. The fallback is a log-based metric over Phase 5 data. [SETUP.md](SETUP.md) Phase 4 still uses both retired names (§10 item 23). | Phase 4 (M3) | tenant edition |
| [ ] | Groups accept alert mail from the alerting system: the login rule emails `$OPERATORS` | `Assumption:` true. Otherwise list individual addresses. | Phase 4 | tenant |
| [ ] | "Share data with Google Cloud services" is available, and the Workspace organisation is the same as the GCP organisation. It replaces the Alert Center API, which needs domain-wide delegation, and feeds the event trigger and Eve's evidence. | Admin console → Menu → Account → Account settings → Legal and compliance → **Sharing options** → **Enabled** → Save. Super administrator only; the path is the same on every edition, though which log types are shared depends on it — Admin log events and User log events, the two this check looks for, are shared on all of them. Google describes the data as reaching Cloud Logging at near real time, so allow minutes, not a day, before you suspect the setting. Then, at **organisation** scope in Logs Explorer, both `protoPayload.serviceName="admin.googleapis.com"` and `protoPayload.serviceName="login.googleapis.com"` appear. `Assumption:` same organisation. | Phase 5 (M4), resolved before Phase 9. Phase 11. | tenant |
| [ ] | You can mark an OAuth client **Trusted** (the Gmail scopes are restricted; tenant API controls can cut off an untrusted client weeks later) | Admin console → Security → Access and data control → API controls → App access control → Manage third-party app access is available to you. There is no API, so check by eye. | Phase 9 step 4 (M6); Eve's client in Eve's runbook | super admin |

---

## 4. GCP organisation and billing

### 4.1 Roles you must hold above project level

`./walle preflight` tests exactly four permissions: `resourcemanager.projects.create` and `logging.sinks.create` on the organisation, and `billing.resourceAssociations.create` and `billing.budgets.create` on the billing account. It checks none of the last four rows below.

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | `ORG_ID` known, and the project will be created under the organisation | Agent Identity's trust domain is `agents.global.org-${ORG_ID}.system.id.goog` | `gcloud organizations list`. After Phase 6: `gcloud projects describe "$PROJECT" --format="value(parent.type)"` prints `organization` or `folder` — either way the project is under `$ORG_ID`, which is all the trust domain needs ([12](12-agent-identity.md) §71); see the folder row below. | Phase 6, Phase 12b | you |
| [ ] | **Project Creator** (`roles/resourcemanager.projectCreator`) on folder `$FOLDER_ID` — for four projects. Since 2026-09-13 needed by a human only for SETUP.md Phase 6's manual fallback: the factory identity `factory-apply@` holds it, and the P-SA project is applied under an approved `ent-factory-singleton` PAM grant ([../agentic-platform/02-landing-zone-and-tiers.md](../agentic-platform/02-landing-zone-and-tiers.md) §3.4). The role is inherited by the tier folder `$WALLE_FOLDER_ID` below it | Phase 6 creates `$PROJECT` under `$WALLE_FOLDER_ID` (`fld-agents-p-sa-prod`, a child of `$FOLDER_ID`; `./walle gcp` reads it from `WALLE_FOLDER_ID`, §7.2); Eve's Phase 1 and Mo's Phase Mo-0b create `$EVE_PROJECT` and `$MO_PROJECT` under the same folder; `$GEMINI_PROJECT` is `Assumption:` pre-existing (decision 52). | `./walle preflight` (org `resourcemanager.projects.create` — it tests the organisation, not the folder; test the folder with `testIamPermissions` on `folders/${FOLDER_ID}` as below) | Phase 6; Eve Phase 1; Mo Phase Mo-0b | you (org admin grants) |
| [ ] | **Billing Account User and Billing Account Costs Manager** on `$BILLING`. Ask for both at once. | The first links the project. The second creates the budget: Billing Account User alone cannot call `billing.budgets.create`, and the failure lands on the last command of Phase 6. | `./walle preflight` (`billing.resourceAssociations.create`, `billing.budgets.create`) | Phase 6 | you (billing admin grants) |
| [ ] | `roles/logging.configWriter` at **organisation** level — **not needed since 2026-09-13** except on SETUP.md Phase 11's interim fallback | Workspace audit logs land at organisation level, so a project-level sink cannot see them — which is why the sinks are now the platform's (`S-org`, `S-folder`, `to-triggers-walle` in `LOGGING_PROJECT`) and no agent runbook holds this role ([../agentic-platform/08-data-logging-retention-sovereignty.md](../agentic-platform/08-data-logging-retention-sovereignty.md) §3.2, §12 item 6) | `./walle preflight` still tests org `logging.sinks.create` as a blocker ([setup/README.md](setup/README.md#not-implemented)) | Phase 11 interim fallback only | you (org admin grants), or nobody |
| [ ] | `roles/orgpolicy.policyAdmin` | Phase 12b step 1 sets `iam.managed.disableServiceAccountKeyCreation` and the key-upload constraint, spelled `iam.managed.disableServiceAccountKeyUpload` fleet-wide (P41, [02 §4.1](../agentic-platform/02-landing-zone-and-tiers.md#41-the-baseline-every-constraint-by-exact-name) B3; SETUP.md still writes the legacy `iam.disableServiceAccountKeyUpload`). Phase 13b needs `iam.managed.disableAccessPolicyBinding` lifted on the project, which takes up to 15 minutes to propagate. | The **write check** below the table. A `gcloud org-policies describe … --effective` is a read that `roles/orgpolicy.policyViewer` also passes, so it proves nothing here. `Assumption:` granted at organisation level. | Phase 12b step 1, Phase 13b | you (org admin grants) |
| [ ] | `roles/iam.denyAdmin` on the **organisation** (Google's instruction) — since 2026-09-13 held by nobody standing: the folder deny policy `deny-agents-platform` is the platform pipeline's, under PAM `ent-platform-policy`; a human needs it only for SETUP.md Phase 12b step 7's manual fallback | Until 2026-09-13 Phase 12b step 7 created the project-level `walle-deny-agents` deny policy; it now only reads the folder policy | The **write check** below the table. `gcloud iam policies list --kind=denypolicies --attachment-point="cloudresourcemanager.googleapis.com/projects/${PROJECT}"` needs only `iam.denypolicies.list`, which `roles/iam.denyReviewer` carries, so it does not prove you can create the policy. | Phase 12b step 7 (`./walle deploy`) | you (org admin grants) |
| [ ] | `roles/modelarmor.floorSettingsAdmin` on folder `$FOLDER_ID` | Phase 12c step 7 updates `folders/${FOLDER_ID}/locations/global/floorSetting` | Read access, with the endpoint override the folder-level `global` call needs: `CLOUDSDK_API_ENDPOINT_OVERRIDES_MODELARMOR="https://modelarmor.googleapis.com/" gcloud model-armor floorsettings describe --full-uri="folders/${FOLDER_ID}/locations/global/floorSetting"`. That override is the environment form of `gcloud config set api_endpoint_overrides/modelarmor`; `./walle armor` passes it per command so the regional `templates create` is not redirected, and without it gcloud calls the default `us` multi-region endpoint and this call fails. Succeeding proves only `modelarmor.floorSettings.get`, which `roles/modelarmor.floorSettingsViewer` also carries — prove the write with the check below the table. | Phase 12c step 7 (`./walle armor`) | you (org admin grants) |
| [ ] | **The folder decided before Phase 6, and all four projects created inside it.** `gcloud projects create` takes `--organization` **or** `--folder`, not both, and no phase moves a project afterwards | The folder is no longer only the Model Armor floor holder: it is the ancestor of `$PROJECT`, `$EVE_PROJECT` and `$MO_PROJECT`. Since 2026-09-13 `FOLDER_ID` is the numeric id of `fld-agentic-platform`, and Wall-E's project is parented to the tier folder `$WALLE_FOLDER_ID` (`fld-agents-p-sa-prod`) beneath it, which `./walle gcp` validates as numeric and refuses when it equals `$FOLDER_ID` ([../agentic-platform/02-landing-zone-and-tiers.md](../agentic-platform/02-landing-zone-and-tiers.md) §2). Whether Eve's and Mo's projects sit directly under `$FOLDER_ID` or under their own tier folders is unverified: [setup/walle.env.example](setup/walle.env.example) says the same folder, the platform folder tree says tier folders (and of `$GEMINI_PROJECT` if the Gemini Enterprise administrators agree, decision 52), so the Phase 12c conformance floor pinned at `folders/${FOLDER_ID}` binds Eve's and Mo's templates too. A project parented straight to the organisation inherits nothing from it, and `./walle armor` still succeeds. Phase 12c also writes a project-level floor setting, and a project-level setting takes precedence over the folder's, so read the project's effective floor back (`gcloud model-armor floorsettings describe --full-uri="projects/${PROJECT}/locations/global/floorSetting"`) rather than assuming inheritance. | `gcloud resource-manager folders list --organization="$ORG_ID"`, then, for each of the four once it exists, `gcloud projects get-ancestors "<project>"` lists `$FOLDER_ID` with the organisation above it; for `$PROJECT`, `gcloud projects describe "$PROJECT" --format="value(parent.id)"` equals `$WALLE_FOLDER_ID`. Any of the four created elsewhere is moved: `gcloud beta projects move "<project>" --folder="<its parent folder>"`. | Phase 6 (decision), Phase 12c (`./walle armor`), Eve Phase 1, Mo Phase Mo-0b | org admin |

**The write check for the three role rows above.** Testing permissions needs no IAM role of its own, and each permission you actually hold is echoed back; an empty body `{}` means you do not hold it, whatever a `describe` or `list` command says. This is the endpoint and request shape `./walle preflight` already uses. `Assumption:` the three roles are granted at organisation level, so the test is run there; if yours were granted lower down, test at that resource instead.

```bash
# organisation-level write permissions
curl -sS -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"permissions":["orgpolicy.policy.set","iam.denypolicies.create"]}' \
  "https://cloudresourcemanager.googleapis.com/v1/organizations/${ORG_ID}:testIamPermissions"

# folder-level Model Armor floor write
curl -sS -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"permissions":["modelarmor.floorSettings.update"]}' \
  "https://cloudresourcemanager.googleapis.com/v3/folders/${FOLDER_ID}:testIamPermissions"
```

The read-only counterparts `roles/orgpolicy.policyViewer`, `roles/iam.denyReviewer` and `roles/modelarmor.floorSettingsViewer` all pass a read check and then fail the build at Phase 12b step 1, Phase 12b step 7 and Phase 12c step 7.

### 4.2 Organisation policy constraints to check

The organisation-policy baseline is the platform's, set at `fld-agentic-platform` and its tier folders, every constraint by exact name with its value per folder: [02 §4.1](../agentic-platform/02-landing-zone-and-tiers.md#41-the-baseline-every-constraint-by-exact-name) (P41, which replaces a per-project checklist). None of these appears in [SETUP.md](SETUP.md). The checks below confirm, after Phase 6, that the effective values on `$PROJECT` allow what Wall-E's build needs; Eve's and Mo's projects are checked by their own runbooks. If a constraint blocks, the fix belongs to whoever owns organisation policy.

| Done | Constraint | What the build needs | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | `constraints/iam.allowedPolicyMemberDomains` (domain-restricted sharing) | `serviceAccount:gmail-api-push@system.gserviceaccount.com` as a Pub/Sub publisher. `Assumption:` also the `principal://agents.global.org-${ORG_ID}.system.id.goog/…` members granted in Phases 12b and 13b. The cross-project members — `eve-controller@$EVE_PROJECT…`, `mo-metrics@$MO_PROJECT…`, `mo-analyst@$MO_PROJECT…`, `service-${GEMINI_PROJECT_NUMBER}@gcp-sa-discoveryengine…` — are of the same organisation and need no exception ([../project-topology.md](../project-topology.md) §5). Check the sinks' writer identities separately. | `gcloud org-policies describe iam.allowedPolicyMemberDomains --project="$PROJECT" --effective` | Phase 7 (cross-project readers), 10, 12, 12b, 13b, 16 | org admin |
| [ ] | `constraints/gcp.resourceLocations` | `europe-west1`, the `EU` BigQuery multi-region, and `global` for the Model Armor floor settings, which the folder value adds only if the first factory run proves the floor write needs it (02 §4.1 B1). Agent Registry also enforces this constraint at write time. | `gcloud org-policies describe gcp.resourceLocations --project="$PROJECT" --effective` | Phase 6 onward; Phase 12c; Phase 13b | org admin |
| [ ] | `constraints/iam.managed.disableAccessPolicyBinding` (singular) | **Not enforced** on `$PROJECT` before any `roles/iap.egressor` access policy is bound. The platform lifts it at the agent tier folders (02 §4.1 B7). Anywhere it is not lifted, expect it enforced: Google lists it among the automatically enforced constraints, whose Google-managed default restricts the operation even where no organisation policy was ever defined, in an organisation of any age — it is not one of the seven security-baseline constraints tied to the 2024-05-03 cutoff (organisation policy constraints reference, checked 2026-09-12). There, lift it on `$PROJECT` with an explicit override policy before Phase 13b; reading the effective policy is not enough. | `gcloud org-policies describe iam.managed.disableAccessPolicyBinding --project="$PROJECT" --effective`. Changes take up to 15 minutes to propagate. | Phase 13b | org admin (`roles/orgpolicy.policyAdmin`) |
| [ ] | `constraints/iam.managed.disableServiceAccountKeyCreation`, `constraints/iam.managed.disableServiceAccountKeyUpload` | Enforced at the folder (02 §4.1 B2, B3); Wall-E also sets both on the project itself. This row confirms you can. | Covered by the `roles/orgpolicy.policyAdmin` row in §4.1 | Phase 12b step 1 | you |
| [ ] | No VPC Service Controls perimeter around the project — and none that would have to span or admit all four, since Eve's and Mo's identities read `walle_audit` and call `walle-actions` from their own projects and the app's service agent queries the engine from `$GEMINI_PROJECT` | Agent Gateway itself now supports VPC Service Controls, but only for gateway deployments created after 2026-09-08 that use an agent connectivity template for VPC connectivity. The binding constraint is elsewhere: IAM Unified Access Policies — the access policies Phase 13b binds for agent egress — carry a documented "This feature does not support VPC Service Controls" note. [09](09-open-decisions.md) decision 21 gives the older engine-level reason and needs re-checking against this change (§10 item 24). | The perimeter check below the table. If you lack `roles/accesscontextmanager.policyReader`, ask the perimeter owner instead and record their answer and its date. | Phase 12c, Phase 13b | security |

**The perimeter check.** Run it after Phase 6, once `PROJECT_NUMBER` exists.

```bash
gcloud access-context-manager policies list --organization="$ORG_ID" \
  --format="value(name)"
# no output: the organisation has no access policy, so no perimeter. Otherwise, per policy:
gcloud access-context-manager perimeters list --policy="<policy from above>" \
  --format="table(name,status.resources)" \
  | grep -F "projects/${PROJECT_NUMBER}" || echo "no enforced perimeter contains this project"
```

`--policy` may be omitted when the organisation has exactly one access policy; when it has several, run the second command once per policy. `status.resources` is the enforced configuration only — a dry-run perimeter will not show, and becomes a blocker the day it is enforced.

---

## 5. GCP projects (the M0 host project, `$PROJECT`, `$GEMINI_PROJECT`, `$EVE_PROJECT` and `$MO_PROJECT`)

### 5.1 What you hold on each project

`Assumption:` you create `$PROJECT` (Wall-E's, `WALLE_PROJECT` elsewhere) in Phase 6, so you hold `roles/owner` on it, unless an organisation policy removes the owner grant from project creators. Since 2026-09-13 this holds only on Phase 6's manual fallback: the factory removes standing `roles/owner` after its run and humans get a predefined-role bundle back through PAM `ent-project-repair` ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §3.2, §4.4). Owner covers project-level IAM grants, API enablement, Model Armor templates and Secret Manager, and it is what lets you bind the foreign principals on Wall-E's own resources. It does not cover organisation policies, deny policies or folder floor settings, which is why those are in §4.1.

On the other three you need only what [../project-topology.md](../project-topology.md) §7 asks of each, or a named owner of that project who does it: on `$GEMINI_PROJECT`, `roles/discoveryengine.viewer` for `OPERATOR_EMAIL` and the app's admin rights (§3.1) — nothing of Wall-E's is created there; on `$EVE_PROJECT`, the right to bind IAM on the specific resources of the three carve-outs of decision 48 (the optional `publicKeyViewer` on `eve-approval`, the `verdict_receipts` view dataset, the `ladder/` prefix of the evidence bucket), which Eve's runbook makes; on `$MO_PROJECT`, nothing — no Wall-E principal ever appears in Mo's IAM policy. `Assumption:` the four are one person until decision 52 names owner groups.

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | **An existing GCP project to host the operator OAuth client (M0)**, with the Admin SDK API and the Groups Settings API enabled. It needs an Internal, In-production consent screen and a Desktop client JSON saved at `OPERATOR_OAUTH_CLIENT_FILE`. | `./walle workspace` (Phases 1 and 2) calls the Admin SDK as you with `OPERATOR_SCOPES` (`admin.directory.user`, `admin.directory.group`, `admin.directory.orgunit`, `admin.directory.rolemanagement`, `apps.groups.settings`, `userinfo.email`, `openid`). It runs **before** `./walle gcp` creates `$PROJECT`, so the client cannot live there. | `./walle workspace` checks that the file is a valid OAuth client (`verify_operator_client_file`). APIs: `gcloud services list --enabled --project=<host-project> \| grep -E "admin\|groupssettings"`. `Assumption:` any existing project in the organisation works. It must never be the robot's client. | Before `./walle workspace` | you |
| [ ] | A Cloud Monitoring **email notification channel** for you and `$OPERATORS` | An alert policy with no channel is a dashboard. `./walle triggers` refuses to create the Gmail watch alert without one. | `gcloud beta monitoring channels list --format="value(name,displayName)"` is non-empty | Phase 16 (M9, `./walle triggers`) | you |
| [ ] | A **90-minute window** in which `walle-gmail-watch-renew` can be paused, and the knowledge that the drill needs an explicit flag | Phase 16 verify step 3 proves the *absence* condition fires — the failure the phase exists to catch ([SETUP.md](SETUP.md) Phase 16: "Step 3 is the whole point of this phase"). `./walle triggers` **skips it with a warning** unless run as `./walle triggers --drill-watch-alert`; with the flag it pauses the job, blocks until you confirm the alert fired, then resumes and force-runs it in the same sitting. Nothing records the result: `./walle verify` has no check for it and `./walle stage0` will not stop on a drill you never ran, so track it yourself. | The run prints "walle-gmail-watch-renew is running again and has been forced once"; `gcloud scheduler jobs describe walle-gmail-watch-renew --location="$REGION"` reads `ENABLED` | Phase 16, before Stage 0 entry | you |
| [ ] | **Three** separate Desktop OAuth clients (since 2026-09-13), never reused: the robot's **narrow** client and the robot's **broad** client, both under `$PROJECT`'s own Internal, In-production consent screen and consented in one sitting, and Eve's under **`$EVE_PROJECT`'s** consent screen, created by Eve's runbook — never under Wall-E's. `cloud-platform` in none of the robot's; a third client id on `$ROBOT` is severity 1 | One client, one token. Google invalidates the oldest refresh token without warning once one Google Account holds more than 100 live refresh tokens for a single OAuth client ID, and a separate, larger limit applies per account across all clients. External plus Testing expires refresh tokens after seven days. Eve's client and refresh token live in `$EVE_PROJECT`'s Secret Manager ([../project-topology.md](../project-topology.md) §2). | Three client IDs recorded in the build logs, and the robot's two committed for the SIEM's client-id rule (SA-05). All marked Trusted (§3.2). | Phase 9 (M5, M6); Eve's Phases 8 and 9 | you |
| [ ] | `roles/resourcemanager.projectIamAdmin` (or equivalent) on `$PROJECT`, plus `setIamPolicy` on the engine resource | Phase 12 binds the Gemini project's service agent, `service-${GEMINI_PROJECT_NUMBER}@gcp-sa-discoveryengine`, on the engine (`walleEngineQuery`), and only on the decision-42 fallback grants `roles/discoveryengine.serviceAgent` to it at project level; Phase 13 then registers the agent. `roles/owner` covers both on Phase 6's manual fallback; once the factory has removed standing owner, the grant must come back through PAM or a named role. | Project level: `curl -sS -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" -d '{"permissions":["resourcemanager.projects.setIamPolicy"]}' "https://cloudresourcemanager.googleapis.com/v1/projects/${PROJECT}:testIamPermissions"` echoes the permission back. The engine-level right is proved only when the Phase 12 lock-down succeeds. | Phase 12 (engine lock-down), Phase 13 | you |
| [ ] | Optional: `roles/iam.serviceAccountTokenCreator` for the operator on `walle-actions@` and `walle-agent@` | Without it, the two "service account is refused" proofs in `./walle verify` (the BigQuery `DELETE` and the refresh-token read) report `SKIP` INCONCLUSIVE. The runbook deliberately grants nothing. | Decide explicitly, because the grant lets a human act as the credential holder. If granted, make it temporary and record it. | `./walle verify` | you |

### 5.2 APIs the runbook enables

These are not operator prerequisites. The runbook enables them. `./walle preflight` **does not check APIs**, so check them with `gcloud services list --enabled --project="$PROJECT"`.

| Phase | APIs |
|---|---|
| 6 (SETUP.md) | `aiplatform`, `discoveryengine`, `run`, `cloudbuild`, `artifactregistry`, `secretmanager`, `firestore`, `cloudscheduler`, `cloudtasks`, `pubsub`, `bigquery`, `cloudkms`, `logging`, `monitoring`, `iamcredentials`, `billingbudgets`, `storage`, `admin`, `licensing`, `gmail`, `chat`, `calendar-json` (22, all `.googleapis.com`). `billingbudgets` must be on before the budget call at the end of the phase. |
| 6 (script addition) | `groupssettings.googleapis.com`, because `./walle` sets group access settings through the Groups Settings API |
| 12b | `agentidentity.googleapis.com`. **`agentidentitycredentials.googleapis.com` must stay disabled.** |
| 12c | `modelarmor`, `networkservices`, `networksecurity` |
| 13b | `agentregistry`, `apphub`, `iap`, `dns`, `compute` |
| Not enabled anywhere in the stack | See §6.2, Agent Gateway row: `iam`, `observability`, `telemetry`, `cloudtrace`, `apptopology`, `cloudapiregistry`, `notebooks`, `texttospeech`, `dataform` |

---

## 6. Product availability and preconditions

### 6.1 Launch stage as of 2026-09-11

| Product | Stage | Region fact | Used by Wall-E | Source |
|---|---|---|---|---|
| Agent Runtime (formerly Vertex AI Agent Engine; the API resource is still `reasoningEngines`) | GA | GA in `europe-west1`. `REGION` is fixed there and the script refuses any other value. | Yes, Phase 12 | [09](09-open-decisions.md) "Verified since the first draft" (Agent Runtime, Sessions and Memory Bank GA in `europe-west1` with EU at-rest residency, verified 2026-09-07/08); [setup/walle.env.example](setup/walle.env.example) `REGION`; agent-locations page |
| Agent Identity on Agent Runtime | GA since 2026-04-22 | — | Yes, Phase 12b, subject to the decision 19 spike | [12](12-agent-identity.md) |
| `agentidentity.googleapis.com`, `agentidentitycredentials.googleapis.com` | GA since 2026-08-22, after Preview from 2026-06-18 | GA in `europe-west1` | First enabled. Second kept **disabled**. | IAM release notes; IAM Agent Identity locations page |
| Agent Registry | GA since 2026-06-18 | A regional registry in `europe-west1`. The `eu` multi-region registry refuses manual registration. | Yes, Phase 13b | [13](13-agent-interconnection.md) §2.1 |
| Agent Gateway (Model Armor ingress fail-closed; egress in dry-run) | GA since 2026-06-18. Model Armor on a gateway GA since 2026-06-24. | Same project and region as the engine, so `europe-west1`. Whether Agent Gateway is offered there is *tbd*: the agent-locations table did not render for automated reading on 2026-09-12 ([12](12-agent-identity.md) §11). | Egress: yes, Phase 13b. Ingress: conditional — [14](14-hld-challenge.md) C29 (verified 2026-09-12) moves [SETUP.md](SETUP.md) 12c steps 4 and 5 behind the measured Gemini Enterprise invoke method and [09](09-open-decisions.md) decision 24, because Google supports Gemini Enterprise in Agent-to-Anywhere (egress) mode only (§10 item 26). | [12](12-agent-identity.md) §11; [13](13-agent-interconnection.md) §7, §12 [R27] |
| Model Armor | GA | `europe-west1` and `eu` supported. Floor settings use `global`. | Yes, Phase 12c | model-armor locations page |
| IAM Unified Access Policies | GA since 2026-08-31 | — | Yes, the `roles/iap.egressor` bindings in Phase 13b | research-registry |
| Skill Registry, Semantic Governance Policies | Preview | — | **Deliberately unused** | [13](13-agent-interconnection.md), [11](11-prompt-security.md) §7 |
| Workforce Identity Federation | GA | — | Only if an operator has no Google account. The runbook has no path for it (§10 item 18). | [12](12-agent-identity.md) §5, §8.2 |

### 6.2 Preconditions for Phases 12b, 12c and 13b

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | The project sits under an organisation | The trust domain is built from `ORG_ID` | `gcloud projects describe "$PROJECT" --format="value(parent.type)"` prints `organization` or `folder` — either way the project is under `$ORG_ID`, which is all the trust domain needs; see the folder row in §4.1 | Phase 12b | you |
| [ ] | `agentidentitycredentials.googleapis.com` is **disabled** | With it off, no auth provider can ever be used in the project. `./walle deploy` fails if it is enabled and disables nothing itself. | The **disabled-API check** below the table. Do not use `grep -c … prints 0`: POSIX `grep` exits non-zero when it selects nothing, so the one state you want to see reads as a failed command inside any `set -e` script. | Phase 12b (`./walle deploy`) | you |
| [ ] | Agent Gateway is offered in `europe-west1` | The gateway must sit in the same project and region as the engine, and the stack records its `europe-west1` availability as *tbd* ([12](12-agent-identity.md) §11) | Console → Network Services → Agent Gateways, or `gcloud network-services agent-gateways list --location=europe-west1 --project="$PROJECT"` | Phase 12c | you |
| [ ] | The Agent Identity spike result is recorded before the first production deploy (decision 19) | `identity_type` cannot be patched. `AGENT_IDENTITY_MODE=SERVICE_ACCOUNT` is refused unless the spike file exists. | `./walle spike` writes `AGENT_IDENTITY_SPIKE_RESULT`, then `test -s "$AGENT_IDENTITY_SPIKE_RESULT"`. Then run `./walle rollback --phase 12b` to delete the throwaway engine. | Phase 12b step 3 | you |
| [ ] | The Gemini Enterprise app location is `eu` or `global` (D8) | A `us` app cannot front the engine | Gemini Enterprise console → the app → settings | Phase 6 | you |
| [ ] | The config keys `GEMINI_PROJECT` and `GEMINI_PROJECT_NUMBER`: the project that hosts the Gemini Enterprise app, and its number | The Discovery Engine service agent that calls the engine is `service-${GEMINI_PROJECT_NUMBER}@gcp-sa-discoveryengine.iam.gserviceaccount.com`. The number is the app project's, never Wall-E's `PROJECT_NUMBER` ([12](12-agent-identity.md) §7; [../project-topology.md](../project-topology.md) §3 row 1). The app never lives in `$PROJECT`. | `gcloud projects describe "$GEMINI_PROJECT" --format="value(projectNumber)"` | Phase 12 engine lock-down | you |
| [ ] | Discovery Engine read access on `$GEMINI_PROJECT` for your own account: `roles/discoveryengine.viewer` for `OPERATOR_EMAIL` | `./walle register` and the M8 verifier address the app as `projects/$GEMINI_PROJECT/locations/$GEMINI_APP_LOCATION/collections/default_collection/engines/$GEMINI_APP_ID`, using your own `gcloud` access token — never `projects/$PROJECT/…`. Without the viewer role the app read only warns, the D8 location check is skipped with it, and the M8 verifier returns SKIP — you confirm the registration and the app location by eye instead. | `gcloud projects get-iam-policy "$GEMINI_PROJECT" --flatten="bindings[].members" --filter="bindings.members:user:${OPERATOR_EMAIL} AND bindings.role:roles/discoveryengine.viewer" --format="value(bindings.role)"` | Phase 13 (`./walle register`) | you |
| [ ] | Agent Gateway required APIs, as listed under "Required APIs" on Google's Agent Gateway set-up page (checked 2026-09-11): `compute`, `networksecurity`, `networkservices`, `dns`, `iam`, `iap`, `agentregistry`, `aiplatform`, `discoveryengine`, `storage`, `modelarmor`, `observability`, `telemetry`, `monitoring`, `cloudtrace`, `logging`, `apphub`, `apptopology`, `cloudapiregistry`, `notebooks`, `texttospeech`, `dataform` (all `.googleapis.com`) | The gateway is a Google-managed proxy and Google lists these as required. `Assumption:` `notebooks`, `texttospeech` and `dataform` serve console features, not the egress path. Enable them anyway, because Google lists them. | The **enabled-API loop** below the table. No output means all 22 are on. Nine of them are enabled by no phase in the stack (§5.2, §10 item 14), so expect output until that gap is fixed. | Phases 12c and 13b | you |
| [ ] | Model Armor default quotas are enough for Wall-E's 120 reads per minute: "API queries" (sanitize) and "Requests to ExternalProcessor", the latter counted in the project that holds the Agent Gateway, which for Wall-E is the same project. Values and alert threshold: the [HLD quota register](../agentic-platform/01-hld.md#34-labels-budgets-contacts-quotas); per-filter token limits: [06 §3.3](../agentic-platform/06-gateways-model-armor-perimeter.md#33-the-template-standard-per-tier) | With `failOpen: false`, a quota error is a Wall-E outage; above a token limit a filter returns `EXECUTION_SKIPPED`. | Console → IAM & Admin → Quotas, filtered on `modelarmor.googleapis.com` | Phase 12c | you |
| [ ] | Agent Registry roles: **none in `$PROJECT`** on the shared registry. Since 2026-09-13 (P71) the registry is the shared one in `CORE_PROJECT`, Wall-E's project never enables `agentregistry.googleapis.com`, and the only standing registry writer is `factory-apply@` ([05 §2.2](../agentic-platform/05-registry-and-autonomy-contract.md#22-options-and-the-decision-p71)). Only on the local fallback (`REGISTRY_LOCAL_FALLBACK_DECISION`, §7.2): `roles/agentregistry.admin` to `CI_DEPLOYER` and nobody else. On either path `roles/agentregistry.viewer` goes to no Eve or Mo principal ([decision 43](../project-topology.md#8-open-decisions-this-topology-adds)). | The registry's roles are project-level only, and admin and editor can change agent metadata and tool annotations ([05 §2.1](../agentic-platform/05-registry-and-autonomy-contract.md#21-the-google-facts-the-topology-rests-on-re-verified-2026-09-13-11)). | `gcloud projects get-iam-policy "$PROJECT" --flatten="bindings[].members" --filter="bindings.role:agentregistry"` shows nothing, or only `CI_DEPLOYER` on the fallback, and no `@${EVE_PROJECT}` or `@${MO_PROJECT}` member | Phase 13b (`./walle registry`) | you |
| [ ] | The runtime identity can write traces, logs and metrics: the default agent roles plus `roles/logging.logWriter`, and `roles/telemetry.tracesWriter` and `roles/monitoring.metricWriter` (or `roles/telemetry.writer`, which covers all three signals through the Telemetry API) if the dump of `roles/aiplatform.agentDefaultAccess` shows they are not already included | Agent observability sends traces through the Telemetry (OTLP) API. `Assumption:` the default agent roles may already carry trace write. Confirm from the role dump. | `gcloud iam roles describe roles/aiplatform.agentDefaultAccess --format="value(includedPermissions)"` | Phase 12b step 6, Phase 12c step 5 | you |

**The disabled-API check.** Both branches exit 0, so this is safe to paste into a `set -e` script.

```bash
gcloud services list --enabled --project="$PROJECT" --format="value(config.name)" \
  | grep -qx agentidentitycredentials.googleapis.com \
  && echo "ENABLED — must be disabled before Phase 12b" \
  || echo "disabled — correct"
```

`./walle deploy` refuses to run while the API is enabled, and disables nothing itself.

**The enabled-API loop**, for the 22 Agent Gateway APIs:

```bash
ENABLED=$(gcloud services list --enabled --project="$PROJECT" --format="value(config.name)")
for a in compute networksecurity networkservices dns iam iap agentregistry \
         aiplatform discoveryengine storage modelarmor observability telemetry \
         monitoring cloudtrace logging apphub apptopology cloudapiregistry \
         notebooks texttospeech dataform; do
  grep -qxF "$a.googleapis.com" <<<"$ENABLED" || echo "MISSING $a.googleapis.com"
done
```

---

## 7. Workstation

### 7.1 Tools

| Done | Tool | Version | Needed for | Check |
|---|---|---|---|---|
| [ ] | gcloud | current. Minimum version for the newer command groups is *tbd*. | every GCP phase; `agent-gateways`, `authz-extensions`, `agent-registry` in Phases 12c and 13b | `gcloud --version`. No minimum is published for the `network-services agent-gateways`, `service-extensions authz-extensions` and `agent-registry` groups (*tbd*), so resolve it empirically: update the CLI immediately before Phase 12c (`gcloud components update`, or your package manager if gcloud was installed that way), then check that each group exists — `gcloud agent-registry agents --help`, `gcloud network-services agent-gateways --help`, `gcloud service-extensions authz-extensions --help`, `gcloud beta model-armor --help`. A group that prints help exists in your build; one that errors means the CLI is behind. Record the version that worked in the build log. |
| [ ] | gcloud beta component | — | Phases 12, 12c (`gcloud beta model-armor`), 16 (`gcloud beta monitoring channels`) | `gcloud components list --only-local-state --format='value(id)' \| grep -x beta` |
| [ ] | gcloud signed in as you | — | every phase; `./walle preflight` prints BLOCKED and exits without it | `gcloud auth login`, then `gcloud config get-value account` equals `OPERATOR_EMAIL` |
| [ ] | Application Default Credentials | — | Phase 12: `agent/deploy.py` uses `vertexai.Client(...).agent_engines.create(...)`, and the virtual environment's Google client libraries authenticate through ADC, not through the gcloud account. Neither SETUP.md nor the script tells the operator to create ADC ([setup/README.md](setup/README.md#not-implemented)), and `gcloud auth login` does not provide it. | `gcloud auth application-default login`, then `gcloud auth application-default print-access-token` succeeds |
| [ ] | An interactive terminal | — | `./walle workspace`, `consent`, `register`, `triggers` and `stage0`, which carry the manual steps M0 to M10 | A manual step is refused with no TTY, and `--yes` does not cover manual steps by design, so none of those five can run from a wrapper or CI |
| [ ] | bq | ships with gcloud | Phases 7, 8, 11 | `bq version` |
| [ ] | python3 | 3.12 per [SETUP.md](SETUP.md) §1.5. Preflight accepts 3.9 or later. | bootstrap, deploy, the setup tool | `python3 --version` |
| [ ] | git | — | the floor list, image tags | `git --version` |
| [ ] | openssl | — | [SETUP.md](SETUP.md) §1.5 | `openssl version` |
| [ ] | jq | — | Phase 12b step 2 | `jq --version` |
| [ ] | curl | — | Phase 10 verify, Phase 12b step 5, Phase 12c step 3 | `curl --version` |

`shred` is absent on macOS. Phase 9 step 3 already falls back to `rm -P`.

The project virtual environment for the bootstrap and deploy scripts ([SETUP.md](SETUP.md) §1.5):

```bash
pip install "google-adk[a2a,gcp,agent-identity]~=2.8" \
            "google-cloud-aiplatform>=1.112" \
            google-auth-oauthlib google-api-python-client \
            google-cloud-secret-manager google-cloud-firestore google-cloud-bigquery
```

The setup tool builds its own environment. On first run, `./walle` creates `setup/.venv` from `setup/requirements.txt` (`google-api-python-client~=2.0`, `google-auth~=2.0`, `google-auth-oauthlib~=1.0`).

### 7.2 The config file `~/.walle-env`: where each value comes from

Copy [setup/walle.env.example](setup/walle.env.example) to `~/.walle-env`. The script validates *missing or empty* values only for the keys the subcommand you ran uses, but a **leftover `<placeholder>` anywhere in the file is a refusal for every subcommand**. `GEMINI_APP_ID` and `CI_DEPLOYER` are not needed before Phases 13 and 13b (`FOLDER_ID` and `WALLE_FOLDER_ID` are needed from Phase 6, since the project is created under the tier folder), `AGENT_IDENTITY_SPIKE_RESULT` inherits `WALLE_REPO`, and `MO_PRINCIPAL` inherits `MO_PROJECT`; until you have real values, **set them to `""`, do not leave the angle brackets**, or `./walle workspace` and `./walle gcp` refuse to run (`./walle preflight` still runs, but reports each one as a blocker and exits non-zero). An empty value is only a refusal for the subcommand that actually needs the key. **No value may contain a semicolon.** It is the delimiter for the Cloud Run `--set-env-vars` list. The file holds no secrets: passwords live in the vault, tokens in Secret Manager. `REGION=europe-west1` and `BQ_LOCATION=EU` are fixed.

Obtain before you start:

| Done | Key | Obtain from | Needed by subcommand |
|---|---|---|---|
| [ ] | `DOMAIN` | The tenant's primary domain, the one users' addresses actually end in. Not the vanity domain. | all |
| [ ] | `PROJECT` | D1. **Wall-E's own project** — `WALLE_PROJECT` in every other page and in Eve's and Mo's runbooks; the key is not renamed because `walle_setup.py` reads it in every subcommand ([../project-topology.md](../project-topology.md) §6). It can never be reused after a delete. | every GCP subcommand |
| [ ] | `GEMINI_PROJECT` | D8, before Phase 6. The project that hosts the Gemini Enterprise app; never `$PROJECT`. `gcloud projects describe "$GEMINI_PROJECT" --format='value(projectId)'` confirms it exists. Runbook: the Phase 12 engine lock-down and Phase 13. | register (the app path), deploy (engine lock-down member), gcp (its number for the build log), status |
| [ ] | `GEMINI_PROJECT_NUMBER` | D8. `gcloud projects describe "$GEMINI_PROJECT" --format='value(projectNumber)'`. Builds the Discovery Engine service agent. `validate_config` refuses it equal to `PROJECT_NUMBER`. | deploy (engine lock-down; looked up from `GEMINI_PROJECT` when unset), verify |
| [ ] | `EVE_PROJECT` | D1. Eve's project, created by Eve's runbook Phase 1. `SA_EVE`, `SA_EVE_VERIFIER`, `SA_EVE_CONSOLE` and `SA_EVE_V0` derive from it. Runbook: Phases 10, 12 and 15 name its principals. | gcp (Phase 7 dataset-level `READER` on `walle_audit`), deploy (Phase 10 `run.invoker` bindings and the allowlists), status, verify |
| [ ] | `MO_PROJECT` | D1. Mo's project, created by Mo's runbook Phase Mo-0b. `MO_PRINCIPAL` resolves to `serviceAccount:mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com`, and `SA_MO_METRICS` is derived from it, not a key. Runbook: Phases 10, 13b and 15 name its principals. | gcp (Phase 7 dataset-level `READER` on `walle_audit` and `walle_workspace_logs` for `mo-metrics@`), deploy (Phase 10 `run.invoker` binding and the read allowlist), status, verify |
| [ ] | `ORG_ID` | `gcloud organizations list` | preflight, gcp, deploy, spike, armor, registry, denials |
| [ ] | `BILLING` | `gcloud billing accounts list` | preflight, gcp |
| [ ] | `CUSTOMER_ID` | Admin console → Account → Account settings, or `my_customer` | workspace, rollback, dump-privileges |
| [ ] | `OPERATOR_EMAIL` | You. Must equal `gcloud config get-value account`, and preflight warns if it does not. | preflight, workspace, dump-privileges |
| [ ] | `OPERATOR_NAME` | You. | preflight, workspace |
| [ ] | `SECOND_OPERATOR` | D5. Empty is recorded as a known risk. | workspace |
| [ ] | `PILOT_OU`, `SANDBOX_OU` | D3 | workspace, deploy |
| [ ] | `SANDBOX_ACCOUNTS` | D3. At least three synthetic, licensed accounts, created in Phase 1. They are the only targets any verification step may name. | workspace, denials |
| [ ] | `WALLE_REPO` | The path of your clone of the Wall-E repository (§8). `./walle workspace` already refuses without a real value, because Phase 1 step 5 writes `config/protected_floor.txt` into it and then commits it. | workspace, gcp, deploy, spike, armor, registry |
| [ ] | `AGENT_IDENTITY_SPIKE_RESULT` | A path you choose **before** the spike runs, inside `WALLE_REPO` (the example file's default is `${WALLE_REPO}/drills/agent-identity-spike.json`; keep it). `./walle spike` refuses to start with it empty and writes its three results there; `./walle deploy` reads it back, refuses `AGENT_IDENTITY_MODE=SERVICE_ACCOUNT` unless it names an existing file, and refuses `AGENT_IDENTITY` if the recorded verdict is `fail`. | spike; deploy (checked at runtime, not at config validation) |
| [ ] | `OPERATOR_OAUTH_CLIENT_FILE` | The M0 download (§5.1) | workspace, rollback, dump-privileges |
| [ ] | `OPERATOR_TOKEN_CACHE` | A local path, mode 0600. It holds your own token, not Wall-E's. Set it to `""` to disable the cache. | workspace |
| [ ] | `GEMINI_APP_ID` | Gemini Enterprise console → Apps (*tbd*: exact path) | register |
| [ ] | `GEMINI_APP_LOCATION` | D8, `eu` or `global` | register |
| [ ] | `FOLDER_ID` | `gcloud resource-manager folders list --organization="$ORG_ID"`. It must be numeric, or you create the folder. Since 2026-09-13 the numeric id of `fld-agentic-platform` ([../agentic-platform/02-landing-zone-and-tiers.md](../agentic-platform/02-landing-zone-and-tiers.md) §2.1), where the Model Armor floor (Phase 12c) and `deny-agents-platform` attach; all four projects sit beneath it. | gcp (validated beside `WALLE_FOLDER_ID`), armor |
| [ ] | `WALLE_FOLDER_ID` | `gcloud resource-manager folders list --folder="$FOLDER_ID"`: the numeric id of `fld-agents-p-sa-prod`, the P-SA tier folder under `FOLDER_ID` and the parent of Wall-E's project. Never `FOLDER_ID` itself: a project directly under the platform folder inherits the floor but none of the tier's stricter policies, and the script refuses the two being equal. | gcp (Phase 6, `projects create --folder`) |
| [ ] | `CI_DEPLOYER` | A CI deployer service account email, in `$PROJECT`, that must already exist; no phase creates it (§2; [setup/README.md](setup/README.md#where-this-differs-from-the-documents)). Create one by hand before Phase 13b if the pipeline has none. Owner *tbd*. Since 2026-09-13 (P71) used only on the local fallback below; set it to `""` otherwise. | registry (local fallback only) |
| [ ] | `CORE_PROJECT` | The platform's core project, created by the factory, holding the shared Agent Registry (P71). Wall-E's project never enables `agentregistry.googleapis.com`; the egress gateway names this project's `europe-west1` registry and `./walle registry` only reads the entries `factory-apply@` wrote. `./walle registry` refuses it empty (unless on the fallback) or equal to `PROJECT`. | registry |
| [ ] | `REGISTRY_LOCAL_FALLBACK_DECISION` | Empty unless a dated decision record overturns P71's exclusion and records a per-project registry; when it names an existing file, `./walle registry` runs the pre-2026-09-13 per-project steps (enable `agentregistry` in `$PROJECT`, admin to `CI_DEPLOYER`, create the entries). | registry |
| [ ] | `MO_PRINCIPAL` | `serviceAccount:mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com`; derived from `MO_PROJECT` when unset. Kept because `deploy` binds it; the registry viewer grant is dropped (decision 43). `validate_config` refuses a principal outside `MO_PROJECT`. | deploy (Phase 10 `run.invoker` and `READ_CALLER_ALLOWLIST`) |
| [ ] | `AGENT_IDENTITY_MODE` | Decision 19. Default `AGENT_IDENTITY`. Decided before the first deploy and cannot be patched. | deploy |
| [ ] | `GEMINI_ACCESS_SPIKE_RESULT` | Decision 42: the path of the recorded result, a JSON file `{"verdict": "pass"\|"fail"}` with raw output and never a token, of registering and querying with only the engine-scoped `walleEngineQuery` binding in place. Empty means not attempted and no project-level role is granted; only a recorded `fail` makes `deploy` apply `roles/discoveryengine.serviceAgent` at project level, which `verify` (`engine_two_principals`) then tolerates. | deploy (Phase 12 engine lock-down), verify |
| [ ] | `CONTENT_LOG_RETENTION_DAYS` | The data-protection position (D7). `Assumption:` 30. | armor |
| [ ] | `SUPER_ADMIN_GRANT_DECISION` | D13: the path of the signed P33 record with the dated tier-gate checklist. Empty until the gate is passed, and then `verify` asserts the robot is **not** a super admin | workspace (M2C), verify |
| [ ] | `SUPER_ADMIN_ROSTER` | The committed roster, comma-separated: the two human admin accounts and, after the grant, `ROBOT`; never `EVE_ROBOT` ([../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §8.1) | verify |
| [ ] | `SUPER_SCOPES` | D2: the broad client's signed scope list, with `openid` and `userinfo.email`, never `cloud-platform`; *tbd* | consent --super |
| [ ] | `SUPER_SCOPES_DECISION` | D2: the path of the signed record of `SUPER_SCOPES` | consent --super |

`preflight`, `verify` and `stage0` validate the full *required* set — the 25 keys of `REQUIRED_CONFIG_KEYS` in `walle_setup.py` (read 2026-09-14): `DOMAIN`, `PROJECT`, `GEMINI_PROJECT`, `EVE_PROJECT`, `MO_PROJECT`, `REGION`, `BQ_LOCATION`, `ORG_ID`, `BILLING`, `CUSTOMER_ID`, `ROBOT`, `EVE_ROBOT`, `OPERATORS`, `READERS`, `PROTECTED`, `SVC_OU`, `PILOT_OU`, `SANDBOX_OU`, `WALLE_REPO`, `FLOOR_LIST_PATH`, `OPERATOR_EMAIL`, `OPERATOR_NAME`, `OPERATOR_OAUTH_CLIENT_FILE`, `SANDBOX_ACCOUNTS` and `BUDGET_AMOUNT`. Every other key in the tables — among them `SECOND_OPERATOR`, `AGENT_IDENTITY_SPIKE_RESULT`, `OPERATOR_TOKEN_CACHE`, `GEMINI_APP_ID`, `GEMINI_APP_LOCATION`, `GEMINI_PROJECT_NUMBER`, `FOLDER_ID`, `WALLE_FOLDER_ID`, `CI_DEPLOYER`, `CORE_PROJECT`, `REGISTRY_LOCAL_FALLBACK_DECISION`, `MO_PRINCIPAL`, `AGENT_IDENTITY_MODE`, `GEMINI_ACCESS_SPIKE_RESULT`, `CONTENT_LOG_RETENTION_DAYS` and the `SUPER_*` keys — is validated only by the subcommand that uses it. A `<placeholder>` in any key outside `REQUIRED_CONFIG_KEYS` still blocks every subcommand, which is why they must be blanked.

Tunables with defaults:

| Key | Default | Note |
|---|---|---|
| `PLAYBOOK_JOBS` | four guessed names | Replace with the top three tasks ([09](09-open-decisions.md) decision 12) |
| `PLAYBOOK_SCHEDULE`, `TIMEZONE` | `0 7 * * MON`, `Europe/Paris` | The business-hours decision. `Assumption:` Europe/Paris. |
| `BUDGET_AMOUNT` | `200EUR` | `Assumption:` a sane Stage 0 ceiling |
| `ENGINE_DISPLAY_NAME` | `wall-e` | Do not change after the first deploy. `./walle teardown` deletes only engines with this name. |
| `FLOOR_LIST_PATH` | `${WALLE_REPO}/config/protected_floor.txt` | Produced in Phase 1 step 5 |
| `EGRESS_GATEWAY` | `walle-egress` | |

Filled in during the build. Write each one into `~/.walle-env` as it appears. A missing value expands to an empty string and produces a wrong deployed resource rather than a failing command, so the guard in [SETUP.md](SETUP.md) §1.7 applies.

| Key | Produced by | How |
|---|---|---|
| `PROJECT_NUMBER` | Phase 6 | `gcloud projects describe "$PROJECT" --format='value(projectNumber)'`. Runbook Phases 11, 12 (the `aiplatform-re` service agent, `AGENT_PRINCIPAL`) and 12c need it. **Wall-E's** number: it builds Wall-E's own service agents (`gcp-sa-aiplatform-re`, `gcp-sa-dep`, `gcp-sa-aiplatform`, `gcp-sa-iap`), never the Discovery Engine service agent, which comes from `GEMINI_PROJECT_NUMBER` (§7.2 above) |
| `REFRESH_TOKEN_VERSION` | Phase 9 | The number the consent prints; Phase 10 pins it. It is `1` only on a first, clean bootstrap: every rollback, re-run and K4 or K5 drill produces a higher one, and a stale pin points the service at a destroyed version. Never `latest`: it resolves to the newest enabled version, so disabling the newest silently falls back to the previous, still-valid token and the kill switch does nothing. |
| `SUPER_REFRESH_TOKEN_VERSION` | Phase 9, `consent --super` | The number the broad client's consent prints for `walle-super-refresh-token`, pinned on `walle-actions-super`. Same rules: never `latest`, and every K4 on that service or K5 drill raises it. |
| `EVE_TOKEN_VERSION` | Eve's runbook, in `$EVE_PROJECT` | The number Eve's consent prints. **Not a Wall-E key any more**: Eve's consent, secret and version live in `$EVE_PROJECT` ([../project-topology.md](../project-topology.md) §7.2); Wall-E's stack never reads it |
| `ACTIONS_URL` | Phase 10 | Cloud Run URL of the action service. Runbook Phases 11, 12, 14 and 16 need it. |
| `SUPER_ACTIONS_URL` | Phase 10 | Cloud Run URL of `walle-actions-super`; `deploy` prints it on the first deploy |
| `SUPER_EXTRA_INVOKERS` | When named | Comma-separated IAM members, beyond the agent, `eve-controller@` and `eve-verifier@`, allowed to hold `run.invoker` on `walle-actions-super`: the approval surface's service account and `platform-drift@CORE_PROJECT` once named. Any other invoker fails `verify` (`super_service_allowlists`). |
| `DISPATCHER_URL` | Phase 11 | Cloud Run URL of the dispatcher. Runbook Phases 14 and 16 need it. |
| `ENGINE_ID` | Phase 12 | Agent Runtime `reasoningEngines` id. Runbook Phase 13 needs it. |
| `INGRESS_GATEWAY` | `./walle armor` | Set to `walle-ingress` when armor finishes, so deploy binds the engine at creation |
| `MODEL_ARMOR_ENFORCE_DECISION` | The Stage 1 decision record (decision 24) | Empty for the whole of Stage 0, so `./walle armor --enforce` is refused |
| `ACTIONS_IMAGE`, `ACTIONS_SUPER_IMAGE`, `DISPATCHER_IMAGE` | Optional | Pinned, already-built images |

---

## 8. The Wall-E code repository

Building the three code artefacts takes weeks, not hours ([SETUP.md](SETUP.md) §0.4), but `WALLE_REPO` **must be a real path from Phase 1**: `./walle workspace` validates `WALLE_REPO` and `FLOOR_LIST_PATH` and refuses while either is still a placeholder, then Phase 1 step 5 writes `config/protected_floor.txt` there and commits it with `git -C $WALLE_REPO commit`; `./walle gcp` validates `WALLE_REPO` too. Create the repository and `git init` it (with `user.name` and `user.email` set) before Phase 1; the code can arrive later. Phases 1 to 6 and 8 need no *code* in it, so run them early to surface tenant surprises while the code is being written.

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | An initialised git working tree at `WALLE_REPO`, with a commit identity | Phase 1 step 5 writes and commits the floor assertion into it; without `.git` the script only warns, records a note, and leaves it uncommitted | `git -C "$WALLE_REPO" rev-parse --is-inside-work-tree` prints `true`; `git -C "$WALLE_REPO" config user.email` is non-empty | Phase 1 (`./walle workspace`) | you |
| [ ] | Repository at `WALLE_REPO` with: `schemas/*.json`; the three bootstrap scripts `bootstrap/oauth_bootstrap.py`, `bootstrap/verify_token.py` and `bootstrap/dump_privileges.py`; the action service and dispatcher sources or images; `agent/deploy.py`; `agent/.agent_engine_config.json`; `agent/requirements.txt` pinning `google-auth>=2.45.0`; `config/ladder.yaml` and `config/deploy_ladder.py`; `tests/denials.py`. Phase 1 step 5 produces `config/protected_floor.txt`, and `./walle armor` writes `config/armor/`. | Phase 7 needs the schemas, Phases 9 and 15 the bootstrap scripts, 10 and 11 the services, 12 and 12b the agent package, 14 the ladder, 17 the denial suite | `ls "$WALLE_REPO"/schemas "$WALLE_REPO"/bootstrap "$WALLE_REPO"/agent/deploy.py "$WALLE_REPO"/config/ladder.yaml "$WALLE_REPO"/tests/denials.py` | Phase 7 (earliest) | engineering |
| [ ] | The three bootstrap scripts are written first | They are small, and they let the consent happen early | `ls "$WALLE_REPO"/bootstrap` | Phase 9 | engineering |

---

## 9. Security artefacts and lead-time items

| Done | Item | Lead time | Blocks | Where |
|---|---|---|---|---|
| [ ] | Data-protection question sent (D7), including the organisation-level audit logs whose storage region cannot be chosen, the content log bucket, and telemetry content | Longest in the plan | Stage 3; the retention values before Stage 1 | [09](09-open-decisions.md) decisions 8 and 25 |
| [ ] | Existing-automation inventory (D6) | Days | Stage 1 | [09](09-open-decisions.md) decision 1 |
| [ ] | Security keys, safe, access record (§3.1); since 2026-09-13 four robot keys with two custodians and spares for the human admin accounts | Procurement | Phase 3 | [SETUP.md](SETUP.md) Phase 3 |
| [ ] | The P-SA tier gate — Eve observe-and-report drilled, the witness organisation, a SIEM with 24x7 acknowledgement and the super-admin detection set, penetration test, DPIA started, works-council information, the signed deviation and two lists, the perimeter decision, the second human super admin | Weeks to months, much of it bought or hired | The Phase 2 grant, hence Stage 0 | [SETUP.md](SETUP.md) Phase 2; [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §0.4 |
| [ ] | Licences with Gmail (§3.1) | Procurement if no free seats | Phases 1 and 16 | [SETUP.md](SETUP.md) §0.3 |
| [ ] | Organisation-level role grants and organisation policy exceptions (§4) | Organisation admin approval | Phases 6, 11, 12b, 12c, 13b | this page |
| [ ] | An approval surface (a Chat app with app authentication, or an Identity-Aware-Proxy page) | Real engineering effort | Any family above L2; Stage 1 | [SETUP.md](SETUP.md) §7.10; [09](09-open-decisions.md) decisions 14 and 20 |
| [ ] | A change or decision record for each stage (Stage 0 record M10, Stage 1 record) | Your time | Phase 18, Stage 1 | [SETUP.md](SETUP.md) §6.2 |

---

## 10. Gaps this page found

Gaps in the **runbook, the script or the design pages**, not in this page. Fix them in the stack and then delete the line here. Item numbers are stable, because other pages cite them.

Where `walle_setup.py` and the documents differ — items 1 (the M2A verifier still requires Eve's robot), 4, 8, 9, 10, 12, 27, 29, 31, 32 and 35 — and what `./walle preflight` does not check — items 2, 3, 6, 19, 22 and 34 — are kept in [setup/README.md "Where this differs from the documents"](setup/README.md#where-this-differs-from-the-documents) and ["Not implemented"](setup/README.md#not-implemented). Closed: 11 (the §2 `MO_PRINCIPAL` row), 13 (the §6.2 Agent Registry row), 15 (the §7.2 `GEMINI_PROJECT_NUMBER` and `GEMINI_ACCESS_SPIKE_RESULT` rows; decision 42 stays open), 20 (the §4.1 folder row), 25 (SETUP.md §1.4 defers to §3.1, which names Gemini Enterprise Admin, `roles/discoveryengine.agentspaceAdmin`; there is no "Gemini Enterprise app administrator" role), and 33 and 36, which landed in the script ([setup/README.md](setup/README.md#the-four-project-placement)).

- **5. The M0 host project is unnamed.** Neither [SETUP.md](SETUP.md) nor `walle_setup.py` says which project hosts the operator OAuth client, which must exist before `./walle gcp` creates `$PROJECT`: *tbd*. `Assumption:` any existing project in the organisation, never the robot's client.
- **7. Organisation policy constraints not covered by SETUP.md.** `grep constraints/` over SETUP.md returns nothing. `constraints/iam.allowedPolicyMemberDomains` must permit `gmail-api-push@system.gserviceaccount.com` (Phase 16) and, `Assumption:`, the agent principals (Phases 12b, 13b); `constraints/gcp.resourceLocations` must allow `europe-west1`, `EU` and `global` (§4.2).
- **14. Agent Gateway APIs.** Google's set-up page lists 22 required APIs. The stack enables 13 of them across Phases 6, 12c and 13b. Not enabled anywhere: `iam`, `observability`, `telemetry`, `cloudtrace`, `apptopology`, `cloudapiregistry`, `notebooks`, `texttospeech`, `dataform`.
- **16. Telemetry write roles are unnamed.** Neither the runbook nor the script grants or checks `roles/telemetry.tracesWriter`, `roles/monitoring.metricWriter` or `roles/telemetry.writer` for the agent principal. Whether the default agent roles carry them is unconfirmed.
- **17. No approval-surface phase.** [SETUP.md](SETUP.md) §7.10 says the approval surface does not exist yet, and no phase deploys it. It blocks any family above L2.
- **18. No workforce identity path.** `grep -i workforce` over SETUP.md and `walle_setup.py` returns nothing. [12](12-agent-identity.md) §8.2 applies if any operator lacks a Google account.
- **21. Nothing restricts `walle-content-logs` on Phase 6's manual fallback.** On the platform, the factory's `agent-project` module generates the content bucket's restricted fields, one view, and `roles/logging.viewAccessor` and `roles/logging.fieldAccessor` for the operators group and `platform-security@` only ([../agentic-platform/08-data-logging-retention-sovereignty.md](../agentic-platform/08-data-logging-retention-sovereignty.md) §6.3, §12 item 6). On the manual fallback, Phase 12c creates the bucket, the sink and the `_Default` exclusion; the "readers: the operators group and IT security, nobody else" line is a bare comment in [SETUP.md](SETUP.md), and `walle_setup.py` grants no reader and leaves only a note. The manual step list runs M0 to M10 and none covers this bucket, so the only access control on the store of raw prompts and personal data has no owner, no instruction and no verification. It needs either a command — a log-view IAM binding, `gcloud logging views add-iam-policy-binding <view> --bucket=walle-content-logs --location="$REGION" --member="group:$OPERATORS" --role=roles/logging.viewAccessor --project="$PROJECT"`, repeated for the IT security principal, plus a check that nobody holds `roles/logging.viewer` or `roles/logging.privateLogViewer` at project level — or a numbered manual step with a verifier. Until then the §2 check cannot pass.
- **23. Dead console names for the login rule.** [SETUP.md](SETUP.md) Phase 4 steps 1 and 2 say "Create rule → Reporting rule" and data source "Login audit log". Both strings were retired: reporting rules became activity rules throughout September 2025, and the login data source is "User log events". SETUP.md's §1 phase table, Phase 15 and the Phase 18 checklist repeat "login reporting rule". [14](14-hld-challenge.md) already uses the current name.
- **24. Decision 21 is out of date.** [09](09-open-decisions.md) decision 21 says Agent Gateway and VPC Service Controls cannot be used together. Google now supports them together under conditions (deployments created after 2026-09-08 using an agent connectivity template); the surviving blocker is IAM Unified Access Policies, which do not support VPC Service Controls. Re-open the decision.
- **26. SETUP.md 12c still builds the ingress gateway unconditionally.** [14](14-hld-challenge.md) C29 decided to move 12c steps 4 and 5 — the Client-to-Agent gateway, the fail-closed Model Armor extension and the engine binding — behind the measured Gemini Enterprise invoke method and the [09](09-open-decisions.md) decision 24 flip, because Google supports Gemini Enterprise in egress mode only. The runbook has not been changed.
- **28. `walle-inbox-push` has a dead-letter topic and no subscriber grant.** Google requires `roles/pubsub.subscriber` for the Pub/Sub service agent on every source subscription that configures a dead-letter topic, as well as `roles/pubsub.publisher` on the dead-letter topic. Phase 11 grants subscriber on `walle-triggers-push` only; Phase 16 creates `walle-inbox-push` with `--dead-letter-topic=walle-dead-letter` and grants nothing, so dead-lettering on the inbox path silently does not work. Both [SETUP.md](SETUP.md) and `walle_setup.py` are missing it. Add to Phase 16: `gcloud pubsub subscriptions add-iam-policy-binding walle-inbox-push --member="serviceAccount:${PUBSUB_SA}" --role=roles/pubsub.subscriber`.
- **30. `WALLE_FOLDER_ID` has no source in SETUP.md.** [SETUP.md](SETUP.md) §1.6 and §1.7 define `<folder-id>` and `FOLDER_ID`, and Phase 6's manual fallback names the parent `fld-agents-p-sa-prod` by hand, but there is no `WALLE_FOLDER_ID` placeholder or export, while `./walle gcp` reads the project's parent from that key (§7.2). Add a row to §1.6 and an export to §1.7, sourced from `gcloud resource-manager folders list --folder="$FOLDER_ID"`.

---

## 11. Verify before Phase 1

Run `./walle preflight` first, then work through the hand checks. Preflight prints the manual step list (M0 to M10) either way.

| Checked by `./walle preflight` | Check by hand |
|---|---|
| `gcloud`, `bq` and `git` on `PATH` | `openssl version`, `jq --version`, `curl --version` |
| Python 3.9 or later | `gcloud agent-registry agents --help`, `gcloud network-services agent-gateways --help` and `gcloud service-extensions authz-extensions --help` all print help (§7.1) |
| gcloud beta component (warning only) | — |
| gcloud is authenticated (blocker; preflight stops here) | `gcloud auth application-default print-access-token` succeeds (Phase 12) |
| Config validation for the subcommand, and **no `<...>` anywhere in the file** — including the Phase 12c/13/13b keys you cannot fill yet, which must be blanked rather than left as placeholders | Where each key's value comes from (§7.2) |
| gcloud account equals `OPERATOR_EMAIL` (warning) | — |
| Organisation: `resourcemanager.projects.create`, `logging.sinks.create` | `roles/orgpolicy.policyAdmin`, `roles/iam.denyAdmin`, `roles/modelarmor.floorSettingsAdmin` (§4.1: the two `testIamPermissions` calls) |
| Billing: `billing.resourceAssociations.create`, `billing.budgets.create` | — |
| Workspace super admin, **only once an operator token is cached** (`users.get` `isAdmin`); otherwise "not checked" | Admin console → Account → Admin roles → Super Admin, before M0; since 2026-09-13 also: a second human super admin on a separate admin account, multi-party approval available on the edition, self-recovery Off at the top OU (§3.2) |
| — | Gemini Enterprise Admin (`roles/discoveryengine.agentspaceAdmin`), checked on the app's User permissions tab in `$GEMINI_PROJECT` (§3.1); app location `eu` or `global`, and `GEMINI_PROJECT` and `GEMINI_PROJECT_NUMBER` recorded (D8) |
| — | Licences with Gmail: Admin console → Billing → Subscriptions |
| — | A Gemini Enterprise licence per operator: Google Cloud console → Gemini Enterprise → Manage users (§3.1) |
| — | Four robot security keys with two custodians, spare keys for the two human admin accounts, safe, vault, clean browser profile |
| — | M0 host project with the Admin SDK and Groups Settings APIs enabled |
| — | Organisation policy constraints (§4.2 commands, once `$PROJECT` exists) |
| — | APIs: `gcloud services list --enabled --project="$PROJECT"` |
| — | Decisions D1 to D13, including D2b, written down (§1). D9 is closed for Wall-E (2026-09-13); D10 gates the irreversible Phase 9 consent; D11 and D12 gate Phase 1; D13 gates the Phase 2 grant. |
