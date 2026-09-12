# Prerequisites for the administrator

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-11
- Applies to: [SETUP.md](SETUP.md) (Phases 1 to 18), [setup/README.md](setup/README.md) and [setup/walle.env.example](setup/walle.env.example)
- Last executed: never. Nothing in the Wall-E stack is built yet.

Read this page before you open [SETUP.md](SETUP.md). It lists everything that must already be true, decided, granted, bought or installed before the first command, plus the long-lead items that block later stages. It does not repeat the runbook's steps. Where the runbook and this page disagree, [SETUP.md](SETUP.md) wins, and the disagreement is listed under [Gaps this page found](#10-gaps-this-page-found) so the runbook can be fixed.

## How to use this page

Work top to bottom. Every table has a tick-box column. Tick a row when its "How to verify" check passes, not when someone says it is done. Rows marked `Assumption:` are inferred, not stated in the stack. Confirm them before relying on them. "Needed by" gives the earliest phase, stage or `./walle` subcommand that fails without the row.

Section order follows when you need each item: decisions and people first, then Workspace, GCP organisation, GCP project, products, your workstation, the code repository, and a final check before Phase 1.

---

## 1. Decisions to close first

[SETUP.md](SETUP.md) §1.1 holds the reasons and the recommendations. This table only says when each decision must be closed. SETUP.md asks for a written answer to every row before Phase 1, even the rows that only block later work.

| Done | # | Decision | Close before | Why | Recorded in |
|---|---|---|---|---|---|
| [ ] | D1 | Names: project id, robot address, organisational unit paths, group addresses, BigQuery dataset, **OAuth app name** | Phase 1 | The OAuth app name is shown to the robot at consent and is awkward to change. Every command hard-codes the rest. A project id can never be reused after a delete. | [09](09-open-decisions.md) decision 2 |
| [ ] | D2 | The frozen OAuth scope list, including whether to add `admin.directory.user.security` and a confirmation that there is **no** `drive` scope | Answer before Phase 1. Final before Phase 9. | Scopes freeze at the Phase 9 consent. Widening them later means a new interactive sign-in and a new bootstrap. | [09](09-open-decisions.md) decision 3; [SETUP.md](SETUP.md) §1.2, §1.3 |
| [ ] | D3 | Sandbox organisational unit with synthetic accounts, plus one small real pilot unit | Phase 1 | Phase 2 scopes a role to a unit that must exist. Without a sandbox, Stage 1's first writes land on real employees. | [09](09-open-decisions.md) decision 5 |
| [ ] | D4 | Ratify the nine blast-radius rows in [06](06-security-guardrails.md) | Before build | Every other control is calibrated against those rows. | [09](09-open-decisions.md) decision 4 |
| [ ] | D5 | A second operator in `walle-operators@`, and someone from IT security as second approver | Phase 1 | A one-person operators group means every kill switch depends on you being reachable. L4 and L5 need two named humans. | [09](09-open-decisions.md) decision 11 |
| [ ] | D6 | Inventory of other automation that writes the same Workspace objects (directory sync, licence scripts, joiner and leaver tools), each with a named owner | Stage 1 | Two writers on one object collide. | [09](09-open-decisions.md) decision 1 |
| [ ] | D7 | The data-protection question, and employee representative bodies where your jurisdiction has them | **Ask in week one.** Blocks Stage 3. | It has the longest lead time in the plan. Autonomous action is a different processing activity from human-requested action. | [09](09-open-decisions.md) decisions 8 and 25 |
| [ ] | D8 | Gemini Enterprise app location: must be `eu` or `global` | Phase 6 | Everything from Phase 6 on is regional. A `us` app cannot front a `europe-west1` agent. | [SETUP.md](SETUP.md) §1.1; `GEMINI_APP_LOCATION` |

Not blocking, but settle them before Phase 14:

| Done | Item | Default until decided | Recorded in |
|---|---|---|---|
| [ ] | Business hours and timezone | `Assumption:` Europe/Paris, Monday to Friday, last write 16:00 | [09](09-open-decisions.md) decision 15; `TIMEZONE`, `PLAYBOOK_SCHEDULE` |
| [ ] | Audit retention | `Assumption:` 400 days | [09](09-open-decisions.md) decision 17 |
| [ ] | The three admin tasks that waste the most of your time. They become the Stage 0 shadow playbooks. | The four names in `PLAYBOOK_JOBS` are guesses | [09](09-open-decisions.md) decision 12 |

Two decisions come due during the build, not before it:

| Done | Decision | Close before | Why | Recorded in |
|---|---|---|---|---|
| [ ] | Agent Identity or `walle-agent@`, decided from the spike on a throwaway engine | Phase 12, the first production deploy | `identity_type` is fixed when the engine is created and cannot be patched | [09](09-open-decisions.md) decision 19; `AGENT_IDENTITY_MODE` |
| [ ] | Model Armor blocking threshold and confidence level | Stage 1 | Templates start inspect-only. Blocking is turned on from Stage 0 measurements. | [09](09-open-decisions.md) decision 24; `MODEL_ARMOR_ENFORCE_DECISION` |

---

## 2. People

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | You: Workspace super admin, Gemini Enterprise app administrator, and holder of the GCP roles in §4 | You run every phase | §3 and §4 checks | Phase 1 | you |
| [ ] | A second operator, a Workspace admin, named in `SECOND_OPERATOR` and added to `walle-operators@` | Halt, demote, veto and approve must not depend on one person. An empty value is accepted, and the script records it as a known risk. | `SECOND_OPERATOR` is non-empty in `~/.walle-env` | Phase 1 (D5) | you and the second operator |
| [ ] | A second approver from IT security | L4 and L5 need two named humans. Name the person now, although they are only needed at Stage 4. | Name recorded in the D5 decision | Stage 4, named before Phase 1 | security |
| [ ] | An IT security contact who, with the operators group, is the only reader of `walle-content-logs` | That bucket holds raw prompts and personal data | Name recorded. Log bucket IAM shows only those two principals after Phase 12c. | Phase 12c | security |
| [ ] | The owner of organisation-level Cloud Logging, consulted before audit-log sharing is turned on | Sharing adds organisation-wide admin activity to ingestion, the largest cost line. They know whether `_Default` excludes it. | Their answer recorded in the build log | Phase 5 (M4) | external party |
| [ ] | Data protection, and employee representative bodies where they exist | D7. Longest lead time. | Question sent, date recorded | Week one; blocks Stage 3 | legal/DPO, HR |
| [ ] | An owner for each existing writer found in D6 | Collisions on shared objects | Inventory with owners | Stage 1 | you |
| [ ] | An owner and a principal for Mo (`MO_PRINCIPAL`) | `walle registry` grants Mo registry viewer, and Mo does not exist yet | *tbd*. `Assumption:` `serviceAccount:mo-analyst@<project>.iam.gserviceaccount.com` | Phase 13b (`./walle registry`) | you |
| [ ] | An owner for the CI deployer service account (`CI_DEPLOYER`) | It is the only principal allowed to write Agent Registry, and no phase creates it | *tbd* | Phase 13b (`./walle registry`) | *tbd* |

---

## 3. Workspace tenant

### 3.1 Roles, accounts, licences and physical artefacts

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | Workspace **super admin** | Organisational units, users, groups, custom roles, 2-step verification enforcement, API controls, audit-log sharing | Before the operator token is cached: Admin console → Account → Admin roles → Super Admin → your account is listed. Once `./walle workspace` has cached your token (M0), `./walle preflight` checks `users.get` `isAdmin`. Before that it prints "not checked". | Phases 1 to 5, Phase 9 step 4, Phase 15 | you |
| [ ] | Gemini Enterprise **app administrator** on the app that will front Wall-E | Registering the agent and sharing it | Gemini Enterprise console → the app → the Agents page is visible and you can add an agent. `Assumption:` no command checks this role. | Phase 13 (`./walle register`) | you |
| [ ] | Membership of `walle-operators@` for everyone who pulls the andon cord | Phase 6 grants `roles/iam.serviceAccountTokenCreator` on `walle-operators-caller@` to the group. That is the only way a human can mint an ID token with the right audience. | After Phase 6: `gcloud iam service-accounts get-iam-policy "$SA_OPS_CALLER"` shows `group:walle-operators@…` with that role, and you and `$SECOND_OPERATOR` are members | Phases 10, 14, 17 | you and `$SECOND_OPERATOR` |
| [ ] | **Spare Workspace licences that include Gmail**: one for `$ROBOT`, one for `$EVE_ROBOT`, and one per sandbox account (at least three). Five or six seats in total. | The frozen scope list and the Phase 16 mailbox watch need Gmail. A licence without Gmail gives a clean Phase 9 and a failure at Phase 16. | Admin console → Billing → Subscriptions: free seats on a Gmail-bearing SKU. `Assumption:` no purchase order is needed. | Phases 1, 15, 16 | tenant |
| [ ] | A Gemini Enterprise seat for every member of `walle-operators@` | The agent is shared per group on the User permissions tab. An operator without a seat has no front door. | `Assumption:` Admin console → Billing → Subscriptions, each operator assigned | Phase 13 verify | tenant |
| [ ] | Access to a **corporate password vault** | The robot passwords go straight into it, never to the wiki, a ticket or chat | `Assumption:` one exists. You can create an entry. | Phase 1 (M1) | you |
| [ ] | **Three physical security keys**, labelled (two for `$ROBOT`, one for `$EVE_ROBOT`), plus a safe and a witnessed record of who has access | Hardware-key-only 2-step verification with no recovery path. If the only key is lost after Phase 9, Wall-E is down until Phase 9 is re-run in full. | Keys in hand. `./walle workspace` checks `isEnrolledIn2Sv` (M2A) before it prints the enforcement step (M2B). | Phase 3 (M2A before M2B), Phase 15 | you |
| [ ] | A **clean browser profile**, signed into nothing | A desktop OAuth flow opens the default browser, which is signed in as you, so the grant lands on a super admin ([SETUP.md](SETUP.md) §7.1) | Manual: a new profile with no Google session | Phases 9 and 15 (M7) | you |

### 3.2 Edition features and tenant settings

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | Custom admin roles, and role assignments scoped to an organisational unit | The robot holds a narrow custom role. There is no domain-wide delegation. | Admin console → Account → Admin roles → Create new role is available | Phase 2 | tenant edition |
| [ ] | Permission to create the top-level unit `/Automation` and `/Automation/Service Identities` under it | Phase 3 hardening must apply only to the robots | `Assumption:` allowed. Otherwise nest it where service identities already live and change `SVC_OU`. | Phase 1 | you |
| [ ] | Reporting rules on the **login audit log** | The robot-login alert is the highest-value single detection control | Admin console → Rules → Create rule → Reporting rule → the "Login audit log" data source exists. `Assumption:` the edition supports it. The fallback is a log-based metric over Phase 5 data. | Phase 4 (M3) | tenant edition |
| [ ] | Groups accept alert mail from the alerting system | The login rule emails `$OPERATORS` | `Assumption:` true. Otherwise list individual addresses. | Phase 4 | tenant |
| [ ] | "Share data with Google Cloud services" is available, and the Workspace organisation is the same as the GCP organisation | Replaces the Alert Center API, which needs domain-wide delegation. It feeds the event trigger and Eve's evidence. | Admin console → Account → Account settings → Legal and compliance (the path varies by edition). After up to 24 h, Logs Explorer at **organisation** scope shows both `protoPayload.serviceName="admin.googleapis.com"` and `protoPayload.serviceName="login.googleapis.com"`. `Assumption:` same organisation. | Phase 5 (M4), resolved before Phase 9. Phase 11. | tenant |
| [ ] | You can mark an OAuth client **Trusted** | The Gmail scopes are restricted. Tenant API controls can cut off an untrusted client weeks later. | Admin console → Security → Access and data control → API controls → App access control → Manage third-party app access is available to you. There is no API, so check by eye. | Phase 9 step 4 (M6), Phase 15 | super admin |

---

## 4. GCP organisation and billing

### 4.1 Roles you must hold above project level

`./walle preflight` tests exactly four permissions: `resourcemanager.projects.create` and `logging.sinks.create` on the organisation, and `billing.resourceAssociations.create` and `billing.budgets.create` on the billing account. It checks none of the last three rows below.

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | `ORG_ID` known, and the project will be created under the organisation | Agent Identity's trust domain is `agents.global.org-${ORG_ID}.system.id.goog` | `gcloud organizations list`. After Phase 6: `gcloud projects describe "$PROJECT" --format="value(parent.type)"` prints `organization`. | Phase 6, Phase 12b | you |
| [ ] | **Project Creator** on the organisation | Phase 6 creates the project | `./walle preflight` (org `resourcemanager.projects.create`) | Phase 6 | you (org admin grants) |
| [ ] | **Billing Account User and Billing Account Costs Manager** on `$BILLING`. Ask for both at once. | The first links the project. The second creates the budget, which fails without it on the last command of Phase 6. | `./walle preflight` (`billing.resourceAssociations.create`, `billing.budgets.create`) | Phase 6 | you (billing admin grants) |
| [ ] | `roles/logging.configWriter` at **organisation** level | Workspace audit logs land at organisation level, so a project-level sink cannot see them | `./walle preflight` (org `logging.sinks.create`) | Phase 11 | you (org admin grants) |
| [ ] | `roles/orgpolicy.policyAdmin` | Phase 12b step 1 sets `iam.managed.disableServiceAccountKeyCreation` and `iam.disableServiceAccountKeyUpload`. Phase 13b needs `iam.managed.disableAccessPolicyBindings` lifted on the project, which takes up to 15 minutes to propagate. | `gcloud org-policies describe iam.managed.disableAccessPolicyBindings --project="$PROJECT" --effective` succeeds. `Assumption:` granted at organisation level. | Phase 12b step 1, Phase 13b | you (org admin grants) |
| [ ] | `roles/iam.denyAdmin` on the **organisation** (Google's instruction) | Phase 12b step 7 creates the `walle-deny-agents` deny policy | `gcloud iam policies list --kind=denypolicies --attachment-point=cloudresourcemanager.googleapis.com/projects/$PROJECT` succeeds | Phase 12b step 7 (`./walle deploy`) | you (org admin grants) |
| [ ] | `roles/modelarmor.floorSettingsAdmin` on folder `$FOLDER_ID` | Phase 12c step 7 updates `folders/${FOLDER_ID}/locations/global/floorSetting` | `gcloud model-armor floorsettings describe --full-uri="folders/${FOLDER_ID}/locations/global/floorSetting"` succeeds. This needs the global endpoint override, which `./walle armor` passes per command. | Phase 12c step 7 (`./walle armor`) | you (org admin grants) |
| [ ] | A folder that holds the Wall-E project, or permission to create one | The Model Armor conformance floor is pinned at the folder | `gcloud resource-manager folders list --organization="$ORG_ID"`. `Assumption:` one exists or can be created. | Phase 12c (`./walle armor`) | org admin |

### 4.2 Organisation policy constraints to check

None of these appears in [SETUP.md](SETUP.md). Run each check against the project as soon as it exists (after Phase 6). If a constraint blocks, the fix belongs to whoever owns organisation policy.

| Done | Constraint | What it must allow | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | `constraints/iam.allowedPolicyMemberDomains` (domain-restricted sharing) | `serviceAccount:gmail-api-push@system.gserviceaccount.com` as a Pub/Sub publisher. `Assumption:` also the `principal://agents.global.org-${ORG_ID}.system.id.goog/…` members granted in Phases 12b and 13b. | `gcloud org-policies describe iam.allowedPolicyMemberDomains --project="$PROJECT" --effective` | Phase 12b, 13b, 16 | org admin |
| [ ] | `constraints/gcp.resourceLocations` | `europe-west1`, the `EU` BigQuery multi-region, and `global` (Model Armor floor settings). Agent Registry also enforces this constraint at write time. | `gcloud org-policies describe gcp.resourceLocations --project="$PROJECT" --effective` | Phase 6 onward; Phase 13b | org admin |
| [ ] | `constraints/iam.managed.disableAccessPolicyBindings` ("Disable binding access policy to resource") | Must be **off** for the project before any `roles/iap.egressor` access policy is bound. Google documents it as enabled by default for new organisations. Only whether an older organisation enforces it is unknown. | `gcloud org-policies describe iam.managed.disableAccessPolicyBindings --project="$PROJECT" --effective`. Changes take up to 15 minutes to propagate. | Phase 13b | org admin (`roles/orgpolicy.policyAdmin`) |
| [ ] | `iam.managed.disableServiceAccountKeyCreation`, `iam.disableServiceAccountKeyUpload` | Wall-E sets both to enforced on the project itself. This row confirms you can. | Covered by the `roles/orgpolicy.policyAdmin` row in §4.1 | Phase 12b step 1 | you |
| [ ] | No VPC Service Controls perimeter around the project | Agent Gateway and VPC Service Controls are not supported together on the engine ([09](09-open-decisions.md) decision 21) | `Assumption:` ask the perimeter owner. `gcloud access-context-manager perimeters list --policy=<org access policy>` | Phase 12c | security |

---

## 5. GCP project

### 5.1 What you hold on the project

`Assumption:` you create `$PROJECT` in Phase 6, so you hold `roles/owner` on it, unless an organisation policy removes the owner grant from project creators. Owner covers project-level IAM grants, API enablement, Model Armor templates and Secret Manager. It does not cover organisation policies, deny policies or folder floor settings, which is why those are in §4.1.

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | **An existing GCP project to host the operator OAuth client (M0)**, with the Admin SDK API and the Groups Settings API enabled. It needs an Internal, In-production consent screen and a Desktop client JSON saved at `OPERATOR_OAUTH_CLIENT_FILE`. | `./walle workspace` (Phases 1 and 2) calls the Admin SDK as you with `OPERATOR_SCOPES` (`admin.directory.user`, `admin.directory.group`, `admin.directory.orgunit`, `admin.directory.rolemanagement`, `apps.groups.settings`, `userinfo.email`, `openid`). It runs **before** `./walle gcp` creates `$PROJECT`, so the client cannot live there. | `./walle workspace` checks that the file is a valid OAuth client (`verify_operator_client_file`). APIs: `gcloud services list --enabled --project=<host-project> \| grep -E "admin\|groupssettings"`. `Assumption:` any existing project in the organisation works. It must never be the robot's client. | Before `./walle workspace` | you |
| [ ] | A Cloud Monitoring **email notification channel** for you and `$OPERATORS` | An alert policy with no channel is a dashboard. `./walle triggers` refuses to create the Gmail watch alert without one. | `gcloud beta monitoring channels list --format="value(name,displayName)"` is non-empty | Phase 16 (M9, `./walle triggers`) | you |
| [ ] | Two **separate** Desktop OAuth clients, one for the robot and one for Eve, never reused, under the project's own Internal, In-production consent screen | One client, one token. More than 100 live tokens for one client invalidates the oldest. External plus Testing expires refresh tokens after seven days. | Two client IDs recorded in the build log. Both marked Trusted (§3.2). | Phase 9 (M5, M6), Phase 15 | you |
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
| Agent Runtime (formerly Vertex AI Agent Engine; the API resource is still `reasoningEngines`) | GA | GA in `europe-west1`. `REGION` is fixed there and the script refuses any other value. | Yes, Phase 12 | runtime-facts, agent-locations page |
| Agent Identity on Agent Runtime | GA since 2026-04-22 | — | Yes, Phase 12b, subject to the decision 19 spike | [12](12-agent-identity.md) |
| `agentidentity.googleapis.com`, `agentidentitycredentials.googleapis.com` | GA since 2026-08-22, after Preview from 2026-06-18 | GA in `europe-west1` | First enabled. Second kept **disabled**. | IAM release notes; IAM Agent Identity locations page |
| Agent Registry | GA since 2026-06-18 | A regional registry in `europe-west1`. The `eu` multi-region registry refuses manual registration. | Yes, Phase 13b | [13](13-agent-interconnection.md) §2.1 |
| Agent Gateway (Model Armor ingress fail-closed; egress in dry-run) | Available in `europe-west1` per the agent-locations page | Same project and region as the engine | Yes, Phases 12c and 13b | [11](11-prompt-security.md), [13](13-agent-interconnection.md) |
| Model Armor | GA | `europe-west1` and `eu` supported. Floor settings use `global`. | Yes, Phase 12c | model-armor locations page |
| IAM Unified Access Policies | GA since 2026-08-31 | — | Yes, the `roles/iap.egressor` bindings in Phase 13b | research-registry |
| Skill Registry, Semantic Governance Policies | Preview | — | **Deliberately unused** | [13](13-agent-interconnection.md), [11](11-prompt-security.md) §7 |
| Workforce Identity Federation | GA | — | Only if an operator has no Google account. The runbook has no path for it (see §10). | [12](12-agent-identity.md) §5, §8.2 |

### 6.2 Preconditions for Phases 12b, 12c and 13b

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | The project sits under an organisation | The trust domain is built from `ORG_ID` | `gcloud projects describe "$PROJECT" --format="value(parent.type)"` prints `organization` | Phase 12b | you |
| [ ] | `agentidentitycredentials.googleapis.com` is **disabled** | With it off, no auth provider can ever be used in the project. `./walle deploy` fails if it is enabled and disables nothing itself. | `gcloud services list --enabled --project="$PROJECT" \| grep -c agentidentitycredentials` prints `0` | Phase 12b (`./walle deploy`) | you |
| [ ] | The Agent Identity spike result is recorded before the first production deploy (decision 19) | `identity_type` cannot be patched. `AGENT_IDENTITY_MODE=SERVICE_ACCOUNT` is refused unless the spike file exists. | `./walle spike` writes `AGENT_IDENTITY_SPIKE_RESULT`, then `test -s "$AGENT_IDENTITY_SPIKE_RESULT"`. Then run `./walle rollback --phase 12b` to delete the throwaway engine. | Phase 12b step 3 | you |
| [ ] | The Gemini Enterprise app location is `eu` or `global` (D8) | A `us` app cannot front the engine | Gemini Enterprise console → the app → settings | Phase 6 | you |
| [ ] | The project number of the project that hosts the Gemini Enterprise app | The Discovery Engine service agent that calls the engine is `service-<APP_PROJECT_NUMBER>@gcp-sa-discoveryengine.iam.gserviceaccount.com`. The number is the app project's, not Wall-E's ([12](12-agent-identity.md) §7). | `gcloud projects describe <gemini-app-project> --format="value(projectNumber)"` | Phase 12 engine lock-down | you |
| [ ] | Agent Gateway required APIs, as listed under "Required APIs" on Google's Agent Gateway set-up page (checked 2026-09-11): `compute`, `networksecurity`, `networkservices`, `dns`, `iam`, `iap`, `agentregistry`, `aiplatform`, `discoveryengine`, `storage`, `modelarmor`, `observability`, `telemetry`, `monitoring`, `cloudtrace`, `logging`, `apphub`, `apptopology`, `cloudapiregistry`, `notebooks`, `texttospeech`, `dataform` (all `.googleapis.com`) | The gateway is a Google-managed proxy and Google lists these as required. `Assumption:` `notebooks`, `texttospeech` and `dataform` serve console features, not the egress path. Enable them anyway, because Google lists them. | `gcloud services list --enabled --project="$PROJECT"`. Nine of these are in no enable list in the stack (§5.2). | Phases 12c and 13b | you |
| [ ] | Model Armor default quotas are enough: "API queries" at 1,200 QPM per project, and "Requests to ExternalProcessor" at 600 QPM per project. The ExternalProcessor quota is counted in the project that holds the Agent Gateway, which for Wall-E is the same project. Both are above Wall-E's 120 reads per minute. | With `failOpen: false`, a quota error is a Wall-E outage. Per-filter token limits: prompt injection and jailbreak 65,536; RAI 65,536; CSAM 65,536; Sensitive Data Protection 130,000. Above a limit the filter returns `EXECUTION_SKIPPED`. | Console → IAM & Admin → Quotas, filtered on `modelarmor.googleapis.com` | Phase 12c | you |
| [ ] | Agent Registry roles: `roles/agentregistry.admin` to `CI_DEPLOYER` only. `roles/agentregistry.editor` and `roles/agentregistry.user` to nobody. `roles/agentregistry.viewer`, which search needs, to `eve-controller@` and `MO_PRINCIPAL`. | Editor, like Admin, can change agent metadata and tool annotations (`readOnlyHint`, `destructiveHint`), which redirects consumers and flips gateway rules. User can create, update and delete skills. SETUP.md prose says viewer goes to "the readers". Its command grants only `eve-controller@`, and the script also grants `MO_PRINCIPAL` (see §10). | `gcloud projects get-iam-policy "$PROJECT" --flatten="bindings[].members" --filter="bindings.role:agentregistry"` | Phase 13b (`./walle registry`) | you |
| [ ] | The runtime identity can write traces, logs and metrics: the default agent roles plus `roles/logging.logWriter`, and `roles/telemetry.tracesWriter` and `roles/monitoring.metricWriter` (or `roles/telemetry.writer`, which covers all three signals through the Telemetry API) if the dump of `roles/aiplatform.agentDefaultAccess` shows they are not already included | Agent observability sends traces through the Telemetry (OTLP) API. `Assumption:` the default agent roles may already carry trace write. Confirm from the role dump. | `gcloud iam roles describe roles/aiplatform.agentDefaultAccess --format="value(includedPermissions)"` | Phase 12b step 6, Phase 12c step 5 | you |

---

## 7. Workstation

### 7.1 Tools

| Done | Tool | Version | Needed for | Check |
|---|---|---|---|---|
| [ ] | gcloud | current. Minimum version for the newer command groups is *tbd*, see §10. | every GCP phase; `agent-gateways`, `authz-extensions`, `agent-registry` in Phases 12c and 13b | `gcloud --version` |
| [ ] | gcloud beta component | — | Phases 12, 12c (`gcloud beta model-armor`), 16 (`gcloud beta monitoring channels`) | `gcloud components list --only-local-state --format='value(id)' \| grep -x beta` |
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

Copy [setup/walle.env.example](setup/walle.env.example) to `~/.walle-env`. The script refuses to run while any value still looks like `<this>`, and validates only the keys the subcommand you ran uses. **No value may contain a semicolon.** It is the delimiter for the Cloud Run `--set-env-vars` list. The file holds no secrets: passwords live in the vault, tokens in Secret Manager. `REGION=europe-west1` and `BQ_LOCATION=EU` are fixed.

Obtain before you start:

| Done | Key | Obtain from | Needed by subcommand |
|---|---|---|---|
| [ ] | `DOMAIN` | The tenant's primary domain, the one users' addresses actually end in. Not the vanity domain. | all |
| [ ] | `PROJECT` | D1. It can never be reused after a delete. | every GCP subcommand |
| [ ] | `ORG_ID` | `gcloud organizations list` | preflight, gcp, deploy, armor |
| [ ] | `BILLING` | `gcloud billing accounts list` | preflight, gcp |
| [ ] | `CUSTOMER_ID` | Admin console → Account → Account settings, or `my_customer` | workspace |
| [ ] | `OPERATOR_EMAIL`, `OPERATOR_NAME` | You. Must equal `gcloud config get-value account`, and preflight warns if it does not. | preflight, workspace |
| [ ] | `SECOND_OPERATOR` | D5. Empty is recorded as a known risk. | workspace |
| [ ] | `PILOT_OU`, `SANDBOX_OU` | D3 | workspace |
| [ ] | `SANDBOX_ACCOUNTS` | D3. At least three synthetic, licensed accounts, created in Phase 1. They are the only targets any verification step may name. | workspace |
| [ ] | `WALLE_REPO` | The path of your clone of the Wall-E repository (§8) | gcp, deploy |
| [ ] | `OPERATOR_OAUTH_CLIENT_FILE` | The M0 download (§5.1) | workspace |
| [ ] | `OPERATOR_TOKEN_CACHE` | A local path, mode 0600. It holds your own token, not Wall-E's. Set it to `""` to disable the cache. | workspace |
| [ ] | `GEMINI_APP_ID` | Gemini Enterprise console → Apps (*tbd*: exact path) | register |
| [ ] | `GEMINI_APP_LOCATION` | D8, `eu` or `global` | register |
| [ ] | `FOLDER_ID` | `gcloud resource-manager folders list --organization="$ORG_ID"`. It must be numeric, or you create the folder. | armor |
| [ ] | `CI_DEPLOYER` | A CI deployer service account email that must already exist. No phase creates it. Owner *tbd*. | registry |
| [ ] | `MO_PRINCIPAL` | *tbd*, because Mo is not built. IAM member form `serviceAccount:…`. | registry |
| [ ] | `AGENT_IDENTITY_MODE` | Decision 19. Default `AGENT_IDENTITY`. Decided before the first deploy and cannot be patched. | deploy |
| [ ] | `CONTENT_LOG_RETENTION_DAYS` | The data-protection position (D7). `Assumption:` 30. | armor |

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
| `PROJECT_NUMBER` | Phase 6 | `gcloud projects describe "$PROJECT" --format='value(projectNumber)'` |
| `REFRESH_TOKEN_VERSION` | Phase 9 | The number the consent prints. Never `latest`. |
| `EVE_TOKEN_VERSION` | Phase 15 | The number Eve's consent prints |
| `ACTIONS_URL` | Phase 10 | Cloud Run URL of the action service |
| `DISPATCHER_URL` | Phase 11 | Cloud Run URL of the dispatcher |
| `ENGINE_ID` | Phase 12 | Agent Runtime `reasoningEngines` id |
| `AGENT_IDENTITY_SPIKE_RESULT` | `./walle spike` | The spike output file |
| `INGRESS_GATEWAY` | `./walle armor` | Set to `walle-ingress` when armor finishes, so deploy binds the engine at creation |
| `MODEL_ARMOR_ENFORCE_DECISION` | The Stage 1 decision record (decision 24) | Empty for the whole of Stage 0, so `./walle armor --enforce` is refused |
| `ACTIONS_IMAGE`, `DISPATCHER_IMAGE` | Optional | Pinned, already-built images |

---

## 8. The Wall-E code repository

Building the three code artefacts takes weeks, not hours ([SETUP.md](SETUP.md) §0.4). Phases 1 to 6 and 8 do not need the repository. Run them early to surface tenant surprises while the code is being written.

| Done | Requirement | Why | How to verify | Needed by | Holder |
|---|---|---|---|---|---|
| [ ] | Repository at `WALLE_REPO` with: `schemas/*.json`; the three bootstrap scripts `bootstrap/oauth_bootstrap.py`, `bootstrap/verify_token.py` and `bootstrap/dump_privileges.py`; the action service and dispatcher sources or images; `agent/deploy.py`; `agent/.agent_engine_config.json`; `agent/requirements.txt` pinning `google-auth>=2.45.0`; `config/ladder.yaml` and `config/deploy_ladder.py`; `tests/denials.py`. Phase 1 step 5 produces `config/protected_floor.txt`, and `./walle armor` writes `config/armor/`. | Phase 7 needs the schemas, Phases 9 and 15 the bootstrap scripts, 10 and 11 the services, 12 and 12b the agent package, 14 the ladder, 17 the denial suite | `ls "$WALLE_REPO"/schemas "$WALLE_REPO"/bootstrap "$WALLE_REPO"/agent/deploy.py "$WALLE_REPO"/config/ladder.yaml "$WALLE_REPO"/tests/denials.py` | Phase 7 (earliest) | engineering |
| [ ] | The three bootstrap scripts are written first | They are small, and they let the consent happen early | `ls "$WALLE_REPO"/bootstrap` | Phase 9 | engineering |

---

## 9. Security artefacts and lead-time items

| Done | Item | Lead time | Blocks | Where |
|---|---|---|---|---|
| [ ] | Data-protection question sent (D7), including the organisation-level audit logs whose storage region cannot be chosen, the content log bucket, and telemetry content | Longest in the plan | Stage 3; the retention values before Stage 1 | [09](09-open-decisions.md) decisions 8 and 25 |
| [ ] | Existing-automation inventory (D6) | Days | Stage 1 | [09](09-open-decisions.md) decision 1 |
| [ ] | Security keys, safe, access record (§3.1) | Procurement | Phase 3 | [SETUP.md](SETUP.md) Phase 3 |
| [ ] | Licences with Gmail (§3.1) | Procurement if no free seats | Phases 1, 15, 16 | [SETUP.md](SETUP.md) §0.3 |
| [ ] | Organisation-level role grants and organisation policy exceptions (§4) | Organisation admin approval | Phases 6, 11, 12b, 12c, 13b | this page |
| [ ] | An approval surface (a Chat app with app authentication, or an Identity-Aware-Proxy page) | Real engineering effort | Any family above L2; Stage 1 | [SETUP.md](SETUP.md) §7.10; [09](09-open-decisions.md) decisions 14 and 20 |
| [ ] | A change or decision record for each stage (Stage 0 record M10, Stage 1 record) | Your time | Phase 18, Stage 1 | [SETUP.md](SETUP.md) §6.2 |

---

## 10. Gaps this page found

Gaps in the **runbook or script**, not in this page. Fix them in the stack and then delete the line here.

1. **Security key count.** [SETUP.md](SETUP.md) §1.4 asks for "a physical security key". Phase 3 step 1 and M2A register two on `$ROBOT`, and Phase 15 registers a third for `$EVE_ROBOT`.
2. **Tools not listed.** `jq` (Phase 12b step 2) and `curl` (Phases 10, 12b, 12c) are missing from §1.5 and from preflight. The minimum gcloud version for the `agent-gateways`, `authz-extensions` and `agent-registry` command groups is *tbd*: §1.5 says only "current".
3. **Preflight beta warning is too narrow.** It says "phase 12 needs it". Phases 12c (`gcloud beta model-armor`) and 16 (`gcloud beta monitoring channels`) need it too.
4. **Phase 12 uses a command group the script says does not exist.** [SETUP.md](SETUP.md) Phase 12 runs `gcloud beta ai reasoning-engines set-iam-policy`. [setup/README.md](setup/README.md) says there is no `gcloud ai reasoning-engines` group in GA, beta or alpha, and uses the REST API.
5. **The M0 host project is unnamed.** Neither [SETUP.md](SETUP.md) nor `walle_setup.py` says which project hosts the operator OAuth client, which must exist before `./walle gcp` creates `$PROJECT`: *tbd*. `Assumption:` any existing project in the organisation, never the robot's client.
6. **Organisation-level roles missing from §1.4 and preflight.** `roles/orgpolicy.policyAdmin` (Phase 12b step 1, Phase 13b), `roles/iam.denyAdmin` (Phase 12b step 7) and `roles/modelarmor.floorSettingsAdmin` (Phase 12c step 7) are named by neither.
7. **Organisation policy constraints not covered by SETUP.md.** `constraints/iam.allowedPolicyMemberDomains` must permit `gmail-api-push@system.gserviceaccount.com` (Phase 16) and, `Assumption:`, the agent principals (Phases 12b, 13b). `constraints/gcp.resourceLocations` must allow `europe-west1`, `EU` and `global`. `grep constraints/` over SETUP.md returns nothing.
8. **`iam.managed.disableAccessPolicyBindings` default.** SETUP.md Phase 13b marks it "Assumption: enforced by default". Google documents it as enabled by default for new organisations, so only older organisations need checking.
9. **The repository phase numbers contradict each other.** [setup/README.md](setup/README.md) says Phases 10 to 14 need the repository and 1 to 8 do not. [SETUP.md](SETUP.md) §0.4 says Phase 7 (schemas) and Phase 9 (bootstrap scripts) do. [setup/walle.env.example](setup/walle.env.example) says Phases 7, 10, 11, 12 and 14. None of them mentions Phase 17's `tests/denials.py`.
10. **`CI_DEPLOYER` is required by `./walle registry`, but no phase creates it.** Phase 6 creates five service accounts, and none is a CI deployer. The Workload Identity Federation pool that [12](12-agent-identity.md) §6 expects the pipeline to use is not created anywhere either.
11. **`MO_PRINCIPAL` is required by `./walle registry`** while Mo does not exist.
12. **Agent baseline roles: script against runbook.** `walle_setup.py` `AGENT_BASELINE_ROLES` includes `roles/aiplatform.expressUser` and grants it to the agent principal. [SETUP.md](SETUP.md) Phase 12b step 6 deliberately does not, because at project level it carries `reasoningEngines.query` on every engine and would make the agent a fourth caller of its own engine. SETUP.md is authoritative, and the script constant must drop it.
13. **Registry viewer holders disagree.** [SETUP.md](SETUP.md) Phase 13b prose says "viewer to the readers". Its command grants `roles/agentregistry.viewer` to `eve-controller@` only. The script grants it to `eve-controller@` and `MO_PRINCIPAL`. Neither document says `roles/agentregistry.editor` and `roles/agentregistry.user` go to nobody.
14. **Agent Gateway APIs.** Google's set-up page lists 22 required APIs. The stack enables 13 of them across Phases 6, 12c and 13b. Not enabled anywhere: `iam`, `observability`, `telemetry`, `cloudtrace`, `apptopology`, `cloudapiregistry`, `notebooks`, `texttospeech`, `dataform`.
15. **Discovery Engine service agent project number.** [SETUP.md](SETUP.md) Phase 12 builds the service agent from `$PROJECT_NUMBER`, Wall-E's project. [12](12-agent-identity.md) §7 says it is the Gemini Enterprise app project's number. There is no config key for the app project number.
16. **Telemetry write roles are unnamed.** Neither the runbook nor the script grants or checks `roles/telemetry.tracesWriter`, `roles/monitoring.metricWriter` or `roles/telemetry.writer` for the agent principal. Whether the default agent roles carry them is unconfirmed.
17. **No approval-surface phase.** [SETUP.md](SETUP.md) §7.10 says the approval surface does not exist yet, and no phase deploys it. It blocks any family above L2.
18. **No workforce identity path.** `grep -i workforce` over SETUP.md and `walle_setup.py` returns nothing. [12](12-agent-identity.md) §8.2 applies if any operator lacks a Google account.
19. **Preflight does not check APIs, licences, keys, the vault, the clean profile, the M0 host project or organisation policy.** That is by design, but only this page lists the gap (§11).

---

## 11. Verify before Phase 1

Run `./walle preflight` first, then work through the hand checks. Preflight prints the manual step list (M0 to M10) either way.

| Checked by `./walle preflight` | Check by hand |
|---|---|
| `gcloud`, `bq` and `git` on `PATH` | `openssl version`, `jq --version`, `curl --version` |
| Python 3.9 or later | gcloud version for the newer command groups (*tbd* minimum) |
| gcloud beta component (warning only) | — |
| Config validation for the subcommand, and no placeholders left | Where each key's value comes from (§7.2) |
| gcloud account equals `OPERATOR_EMAIL` (warning) | — |
| Organisation: `resourcemanager.projects.create`, `logging.sinks.create` | `roles/orgpolicy.policyAdmin`, `roles/iam.denyAdmin`, `roles/modelarmor.floorSettingsAdmin` (§4.1 commands) |
| Billing: `billing.resourceAssociations.create`, `billing.budgets.create` | — |
| Workspace super admin, **only once an operator token is cached** (`users.get` `isAdmin`); otherwise "not checked" | Admin console → Account → Admin roles → Super Admin, before M0 |
| — | Gemini Enterprise app administrator; app location `eu` or `global` (D8) |
| — | Licences with Gmail: Admin console → Billing → Subscriptions |
| — | Three security keys, safe, vault, clean browser profile |
| — | M0 host project with the Admin SDK and Groups Settings APIs enabled |
| — | Organisation policy constraints (§4.2 commands, once `$PROJECT` exists) |
| — | APIs: `gcloud services list --enabled --project="$PROJECT"` |
| — | Decisions D1 to D8 written down (§1) |
