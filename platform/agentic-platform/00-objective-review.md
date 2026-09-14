# 0. The objective, and how far the documentation is from it

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Maturity: review, complete 2026-09-13. Nothing is built. This page opens the
  `platform/agentic-platform/` document set for the secure agentic platform the objective of
  2026-09-13 describes. The three agent sets ([wall-e](../wall-e/README.md),
  [eve](../eve/README.md), [mo](../mo/README.md)) stay where they are and are adjusted in later
  stages against the platform HLD that follows this page.
- Inputs: the objective (`.agent-work/OBJECTIVE.md`, quoted verbatim in §1) and nine review
  lenses written on 2026-09-13, one file each under `.agent-work/review/` relative to the
  working directory (outside the wiki; copying them into `platform/agentic-platform/review/`
  is *tbd*):
  `platform-security.md`, `walle-super-admin.md`, `eve-independence.md`, `mo-both-agents.md`,
  `scale-and-agi.md`, `eu-ai-act.md`, `tisax.md`, `monitoring.md`, `consistency.md`.
  Every gap in §4 and every decision in §5 is traceable to one of them; this page does not
  re-review the documentation.
- What this page is not: a design. It states the distance, names the reversals, keeps every
  gap, and lists what the platform HLD must decide. It recommends nothing the lenses did not.

---

## 1. The objective

Stated verbatim by the platform owner on 2026-09-13 (`.agent-work/OBJECTIVE.md`):

> Create a secure Gemini Entreprise environment and secure all agents through it (including
> agent identity, agent registry, model armor). If you think about other security element to
> secure autonomous agent, please add the correct path.
> Then, have 3 different agents. The first agent "Wall-e" is the doer and execute action based
> on a prompt by a human. The action will have the ability to any super admin level action of
> Google Workspace. In order to do that, Wall-E will have a dedicated user account, with a
> google license and super admin roles.
> The second is "Eve" that needs to control & report any misbehaviour of Wall-E. She won't have
> super admin access to control and should work independantly & autonomous. She needs to report
> to the human anything wrong.
> The thrid is "Mo" that work on continuous improvements of both Wall-E & Eve agent.
>
> The overall objective is to set up an agentic platform that can sustain hundreds of agents
> (classicial or autonomous) & host future AGI agent while ensuring a full proof security &
> monitoring for entreprise class. All of that must be EU AI Act bulletproof & TISAX compatible.
>
> Please review the entire documentation first & focus on the HLD. Then work on the detailed.

Restated as requirements, each with the lens or lenses that examined it:

| Id | Requirement | Lens |
|---|---|---|
| R1 | A secure Gemini Enterprise environment through which **all** agents are secured, with agent identity, agent registry and Model Armor as named elements | platform-security, scale-and-agi, monitoring |
| R2 | Any other security element needed to secure an autonomous agent, added with "the correct path" (the right mechanism, not a note) | platform-security, monitoring, scale-and-agi |
| R3 | Wall-E is the doer: it executes actions on a prompt by a human | walle-super-admin, eu-ai-act |
| R4 | Wall-E can perform **any super-admin-level action** of Google Workspace | walle-super-admin, consistency, eu-ai-act, tisax |
| R5 | Wall-E holds a **dedicated user account with a Google licence and super admin roles** | walle-super-admin, consistency, tisax, monitoring |
| R6 | Eve controls and reports **any misbehaviour** of Wall-E | eve-independence, monitoring, mo-both-agents |
| R7 | Eve holds **no super admin** access | eve-independence (already satisfied) |
| R8 | Eve works **independently and autonomously** | eve-independence, consistency, tisax |
| R9 | Eve reports to **the human** anything wrong | eve-independence, monitoring, eu-ai-act, tisax |
| R10 | Mo works on continuous improvement of **both** Wall-E and Eve | mo-both-agents, consistency, scale-and-agi |
| R11 | The platform sustains **hundreds** of classical or autonomous agents | scale-and-agi, platform-security, monitoring, mo-both-agents |
| R12 | The platform hosts **future AGI agents** | scale-and-agi, eu-ai-act |
| R13 | Full-proof security and monitoring at **enterprise class** | monitoring, platform-security, tisax |
| R14 | **EU AI Act** bulletproof | eu-ai-act, consistency |
| R15 | **TISAX** compatible | tisax, consistency |
| R16 | Method: review the whole documentation first, focus on the HLD, then the detailed design | this page; consistency |

Standing constraints that the objective does not override and every lens confirmed as still in
force: no domain-wide delegation; the language model holds no credential and cannot approve;
the action service is the only credential holder; humans raise autonomy and machines lower it;
no secrets in the wiki; inferred facts carry `Assumption:`; dates are absolute; unknowns are
*tbd*. The platform's current statement of its standing constraints is
[01-hld.md Status](01-hld.md#status).

---

## 2. Verdict

The documentation is a careful, adversarially reviewed design for **one** privileged Workspace
agent held on a **narrow, OU-scoped custom role**, with a deterministic verifier and a
measurement loop bolted to that one agent. All nine lenses reached the same conclusion
independently: it does not meet the objective. It does not meet it in two different ways.

First, on Wall-E, Eve and Mo the documentation **asserts the opposite of the objective** and
does so as design intent on nineteen pages plus the setup script: "never Super Admin", two
OU-scoped role assignments so that "Workspace itself can refuse an operation outside the pilot
scope", a fixed catalogue of about twenty typed operations, a never-list that excludes exactly
the super-admin-only actions, "Wall-E is a narrow operator, not a stand-in for a super admin",
"no model anywhere in Eve v1 or v2", and a Mo whose grants, path allowlist and validator reach
Wall-E's data only. The setup script would fail its own hardening check the moment the robot
is a super admin (`isAdmin` → FAIL).

Second, on the platform the documentation is **silent**. The words "hundreds", "AGI", "fleet",
"template", "TISAX" and "AI Act" appear nowhere in the ~70 pages. `overview.md`'s Architecture
and Constraints sections read `(to document)`. `gemini-enterprise.md` — the subject of the
objective's first sentence — is a skeleton. There is no landing zone, no project factory, no
organisation-policy baseline above the project, no tier model, no Security Command Center, no
SIEM, no incident-response roles, no retention schedule, no supply-chain control, no privileged
access mechanism, no backup policy, no compliance classification and no register of agents.
Every control that exists is configured by Wall-E's runbook, in Wall-E's project, for Wall-E's
engine; Eve and Mo inherit almost none of it, and a fourth agent would re-implement chapters
11–13 by hand.

**What stands as-is.** The shape generalises and should be lifted into the platform verbatim:
the credential split (the model never holds a credential; one action service does); a
deterministic gate in front of every write; autonomy as data per (family, trigger) with
permanent ceilings, humans raising and machines lowering; a model-free Eve on the approval and
halt path, "deterministic by absence"; Mo's every number re-derivable by a validator the
proposer cannot reach; resource-level-only grants across project boundaries; no agent both
decides and acts, none grades its own work, only humans loosen. Chapters 11 (prompt security
and Model Armor), 12 (agent, operator and workforce identity), 13 (registry, A2A, MCP, Agent
Gateway) and `project-topology.md` are already platform-grade in substance and need promotion,
not rewriting. Eve's own credential, project, key, halt authority and "not a super admin, ever"
are exactly what the objective asks for. The full list of pages that need no edit is §7.

**What changes.** Wall-E's identity chapter and everything that depends on the role as an
enforcer; the catalogue's meaning (a lane structure, not a ceiling on breadth); Eve's evidence
perimeter, detection model, reporting contract, staging and trust root; Mo's remit, data plane
and proposal contract; every "four projects" and "Wall-E's platform" framing; and the absent
platform layer, which must be written as a platform HLD above the three sets.

**The five hardest problems**, in the order the lenses weighted them:

1. **Super admin cannot be scoped, so Workspace stops enforcing anything.** Google cannot
   limit Super Admin to an OU, subset its privileges or grow it with a ladder. The design had
   two enforcement points and now has one: the action service, with the OAuth scope set as the
   only Google-enforced ceiling. Detection becomes the primary control and the catalogue a
   secondary one — the reverse of today's framing. Three controls the set deferred to "before
   S1" (a network perimeter around the credential holder, the control-plane split, privileged
   access on the deploy grant) become preconditions of granting the role. (walle-super-admin,
   monitoring, platform-security, tisax)
2. **Eve's independence is no longer structural.** A Workspace super admin sits above the GCP
   organisation Eve's project lives in: it can suspend `eve@`, revoke Eve's token, rewrite Eve's
   role, mint super admins, switch off audit-log sharing, and — through the console — reach
   Organization Administrator. Eve reads one of the many streams a super admin acts in, verifies
   catalogued plans rather than detecting misbehaviour, and reports to a page budget with two
   empty conditions addressed to the person who administers Wall-E. The HLD must decide where
   Eve's trust root sits and what "report to the human" means before the role is granted.
   (eve-independence, monitoring)
3. **There is no platform.** Project-per-agent is forced by Google (the Discovery Engine
   service agent is project-wide; all engines in a project-region share one gateway), so
   hundreds of agents means hundreds of projects, and nothing makes that repeatable: a hand-run
   runbook, 26 hand-made cross-project grants, per-agent organisation-level sinks, per-agent
   alert channels reading "paste yours". The tier model, landing zone, project factory, shared
   services, SIEM, SCC and monitoring baseline have to be designed from nothing. For AGI-class
   agents the platform offers three of eight containment properties and lacks a fleet kill
   switch outside any agent's project. (scale-and-agi, platform-security, monitoring)
4. **"Any super-admin action" collides with the never-list and with the EU AI Act.** Read
   literally it includes admin-role assignment, security-posture change, user deletion and
   silencing Eve — which the objective's own Eve requirement forbids. It also decides Wall-E's
   classification: if "any admin action on a prompt" is the declared intended purpose, the
   narrow-task derogation collapses and Wall-E is an Annex III 4(b) high-risk system with the
   full Chapter III programme due 2027-12-02. The owner must draw the line and sign it.
   (walle-super-admin, eu-ai-act, consistency)
5. **One person holds every role.** Owner, deployer, operator, approver, grader, security
   reviewer, Eve's owner, Mo's owner and the recipient of Eve's pages are one person today, and
   that person will also prompt a super-admin robot. TISAX 1.2.2 will not rate maturity 3 for
   that; Eve's reports about the administrator have nowhere independent to go; the two-person
   rules in the design are notional. This is organisational, not technical, and it is the item
   most likely to stop an assessment. (tisax, eve-independence, monitoring)

---

## 3. What the objective reverses

### 3.1 Wall-E holds Super Admin

**What the earlier design refused, and why.** `wall-e/02-identity-and-auth.md` §"Admin rights:
a custom role, scoped to an OU" says "**Never Super Admin.** A super admin can alter security
policy, grant DWD, and escalate … the difference between a contained incident and a breach."
The robot held a customer-scoped read role and an OU-scoped write role, "so that Workspace
itself can refuse an operation outside the pilot scope — a second enforcement point outside our
own code" (§"Two role assignments, not one"). The role grew with the ladder and was pruned
quarterly. Two never-list rows (N1 posture, N2 permanent loss) were "not in the catalogue, and
not in the custom role"; the threat model bounded a leaked credential "by the role's privileges
at the current stage"; `SETUP.md` §0.2 promised that "even a total failure of every control in
the action service leaves Workspace refusing the call at Google's end". Decision 26 sought a
keyless service account for the admin half; decision 27 recorded "Wall-E is a narrow operator,
not a stand-in for a super admin"; the HLD challenge (14) rejected a generic Admin SDK proxy
(C35) and gave, as verdict reason 4, "with no DWD and no super admin, super-admin-only and
DWD-only APIs are unreachable whatever sits in front of them".

**What the objective now asks.** A dedicated user account with a Google licence and super admin
roles, able to perform any super-admin-level action of Google Workspace on a human's prompt.
Two Google facts fix the consequences: a service account can hold any admin role except Super
Admin (so decision 26 is closed for Wall-E by fact, not by choice), and Super Admin cannot be
limited to an organisational unit or subset by privilege.

**What safety the platform loses.** Stated without softening:

- The Workspace-side gate. Every control that read "not in the role" is now enforced by the
  action service alone: the OU allowlist, N1 and N2, role-grows-with-the-ladder, the
  credential-leak bound, the `SAFE_USER_FIELDS` split. "Google refuses at its end" is no longer
  a Stage-0 property and must be deleted from `SETUP.md` §0.2 and `setup/README.md`.
- The blast radius of a leaked token or an interactive login becomes **the tenant**, and —
  through the console's ability to grant Organization Administrator, or through a
  `cloud-platform` token — **the GCP organisation** including `EVE_PROJECT` and `MO_PROJECT`.
  Nothing in Workspace or GCP can narrow the account; the perimeter is token custody, key
  custody and detection latency.
- The robot can, via API and the scopes it already holds, `users.makeAdmin` (mint super
  admins), suspend or delete `eve@`, remove Eve's role, revoke Eve's tokens, and act on other
  administrators' security settings. Only code stops it.
- Eve's structural independence (`eve/01` structural choice 1) no longer holds by construction;
  it becomes detective unless Eve's trust root moves outside the tenant's reach.
- The monitoring story's central assumption ("custom role, not Super Admin") is void: the
  credential can switch off "Share data with Google Cloud services", edit the Admin console
  activity rule and re-filter the organisation-level sinks, and nothing in the set would notice.
- Least privilege (TISAX 4.2.1) becomes an accepted deviation to be signed, not a property to be
  shown; the robot is a super admin that is a machine, on the organisation's admin-role review.
- The EU AI Act narrow-task argument now rests entirely on the declared intended purpose and the
  never-list enforced in code; the account's privilege is the fact most likely to be held
  against it.

The platform's own statement of what the reversal costs is
[01-hld.md "What this reverses and what it costs"](01-hld.md#what-this-reverses-and-what-it-costs).

**What must compensate.** The review found one converging set — lanes not breadth, two lists,
two credentials, detection as the primary control, account hygiene, the deferred controls no
longer deferred, a permanent ceiling and a signed record — all preconditions of the grant rather
than "before S1" items; the set as the platform adopted it is
[01-hld.md §13.1](01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa), and the
checklist the gate reads is [11-tisax.md §6.3](11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads).

### 3.2 Other reversals the lenses found

| Reversal | What the design said | What the objective says | Consequence |
|---|---|---|---|
| **Catalogue as ceiling** | `03` "Nothing executes that is not registered"; decision 27; 14 C35 "generic Admin SDK proxy — rejected" | Any super-admin action on a prompt | The catalogue stays the intended purpose and the autonomous band; C35 is re-argued as band B (never above L3, so the lost inverse, pre-state predicate and taint declaration are not needed); decision 27 becomes "which lane", not "whether" |
| **Eve has no judgement anywhere** | `eve/01` "the word judgement does not appear"; `eve/09` settled "no model anywhere in Eve v1 or v2"; `eve-advisor` "Never, on current evidence"; decision 34; 14 C12 | Eve independent, autonomous, reporting anything wrong | Decision 34 stands for approve, halt, demote and veto. "Anything wrong" cannot be enumerated in a closed vocabulary, so the objective is the "new evidence" the settled row asked for: the HLD decides whether the `eve-advisor` slot is built as a one-directional reporting path (own project, no signer, no invoker, no secret access, able only to raise a refusal). `wall-e/08` item 5 ("halting, on its own judgement") is the one sentence that already matched the objective and was voided by CC-10 |
| **Eve verifies plans** | `eve/01` deterministic boundary: the verdict is a pure function of six plan inputs; reasons are control-plane shaped | Eve controls and reports misbehaviour | A versioned detection catalogue over all ingested streams (privilege changes, out-of-family writes, baselines, prompt-to-action divergence), deterministic, in the reconciler limb |
| **Mo measures Wall-E only** | `mo/01` "re-derivable from `walle_audit` alone"; `eve/01` "nothing in `MO_PROJECT` reaches Eve"; `eve/07` "no `userByEmail` entry for `mo-metrics@` on `eve` — ever" | Mo improves both Wall-E and Eve | Mo reads Eve's quality dataset through dataset-level `READER` grants made by Eve's runbook; a second drop-box allowlist into `eve/config` with a closed type set; Eve reads nothing Mo writes; Mo is never Eve's grader |
| **Four projects for four things** | `overview.md`, `agents.md`, `gcp-projects.md`, `project-topology.md` decision 52; `ARCHITECTURE.md` §0 "Eve and Mo do not exist" (stale since 2026-09-12) | A platform for hundreds of agents | Project-per-agent is a pattern produced by a factory under tier folders; chapters 11–13 and the topology are promoted to platform pages; the counts of four become "pattern, not count" |
| **Decision 26** | Keyless service account holding the custom role, blocking before Phase 9 | A user account with Super Admin | Closed for Wall-E by the Google fact; survives only as Eve's E-16, where a service account could still remove Eve's password, key and consent |
| **Compliance is data protection** | `06` Compliance, decision 8, D7: DPIA and employee representatives "before Stage 3" | EU AI Act bulletproof, TISAX compatible | Both regimes named, classified and mapped in a platform compliance chapter; worker consultation moves before Stage 1 under both GDPR and the Act |
| **Eve arrives late** | `eve/05`: Eve gates nothing in the pilot; `eve@` from S3; signing from S4 | A controlled Wall-E from the moment it holds super admin | The observe-and-report layer is live and drilled before the super-admin grant, which becomes a gate with its own checklist; the gate layer keeps S3/S4 |

---

## 4. Gap register

Every gap from every lens, none merged away. Ids are prefixed by lens: PS platform-security,
WSA walle-super-admin, EVE eve-independence, MO mo-both-agents, SCA scale-and-agi, AIA eu-ai-act,
TIS tisax, MON monitoring, CON consistency; the number is the gap's number in its lens file.
Severity: blocking (the HLD cannot claim the requirement without it), major (the requirement is
not met at enterprise grade), minor (documentation or a small addition). "Owner stage": HLD (the
platform HLD decides), detailed (a platform detailed-design page), agent sets (edits to the
Wall-E, Eve or Mo sets), runbook (setup scripts, Terraform, drills). Where several stages own a
gap the first decides and the others implement.

| Id | Lens | Severity | Req. | What exists today (file:section) | Recommended path | Owner stage |
|---|---|---|---|---|---|---|
| PS-01 | platform-security | blocking | R1, R11 | One folder `FOLDER_ID` (`Assumption:` dedicated); four projects created by hand in three runbooks (`wall-e/SETUP.md` Phase 6, `eve/07` Phase 1, `mo/07` Mo-0b), each with its own API list, IAM, budget, owner group (`project-topology.md` §1.4, §2, §5; decision 52); `gcp-projects.md` "Org structure" tbd; Terraform only as an alternative command form; no environment split, Essential Contacts or asset inventory | Platform HLD chapter "Landing zone": folder tree (shared-services, agents-prod, agents-nonprod, one project per agent), a Terraform project factory run by a CI identity through Workload Identity Federation that bakes in APIs, org-policy exceptions, deny policy, sinks, budget, labels (agent, owner, risk-tier, ai-act-class); Wall-E, Eve, Mo and the Gemini project as its first four instances; `walle_setup.py` Phase 6 reduced to a factory call | HLD → runbook |
| PS-02 | platform-security | blocking | R1, R8 | `wall-e/12` §1.7 Agent Identity for Wall-E's engine with a gated fallback; §1.8 Eve and Mo "only if ever on Agent Runtime"; Cloud Run Agent Identity rejected as Preview; deny policy `walle-deny-agents` on `WALLE_PROJECT` only (§1.4; `SETUP.md` Phase 12b step 7); no deny policy in `eve/07` or `mo/07`; PAB named, unused; drift job exact for `WALLE_PROJECT` only (decision 46) | Identity chapter with folder-inherited rules: `AGENT_IDENTITY` mandatory (`SERVICE_ACCOUNT` a named, expiring exception enforced by a custom constraint); one folder-level deny policy on `principalSet://agents.global.org-ORG/*` for secret access, `setIamPolicy`, key creation, `useToSign`, deploy permissions; a PAB bounding agent principals to the agents folder; platform Policy Analyzer drift job with folder-level `securityReviewer` (closes decision 46); one workforce pool if non-Google operators exist; Cloud Run Agent Identity for controllers when GA (*tbd*) | HLD → detailed |
| PS-03 | platform-security | blocking | R1, R11 | `wall-e/13` §2: one regional registry in `WALLE_PROJECT`, admin to CI only, alert on writes; §2.5 "a privilege, not a phone book"; §9 "Neither. A catalogue"; Eve and Mo not registered, no viewer role (decision 43); no mandatory metadata; no reconciliation across projects | Registry as the inventory of record backed by SCC AI Protection's organisation-wide AI asset inventory as the independent cross-check; decide shared registry project versus per-agent registries; mandatory card metadata (owner, risk tier, autonomy ceiling, EU AI Act class, TISAX asset class, data classes, gateway id, principal) with a CI schema check; a platform drift job reconciling registry, SCC inventory and `reasoningEngines.list` across the folder (shadow-agent control) | HLD |
| PS-04 | platform-security | blocking | R1 | `gemini-enterprise.md` skeleton (tenant, licences, admin surface, access model tbd); `project-topology.md` §7.4 five steps and "nothing else"; console Model Armor does not cover custom agents (`11` §2); conversation store region and retention tbd (`ARCHITECTURE.md` §9); identity provider tbd (`12` §11); wrong admin role name (`PREREQUISITES.md` §10 item 25); tenant gateway binding "outside this design" (`13` §7.6); service-agent role project-wide (decision 42) | A "Gemini Enterprise security baseline" page owned with the Gemini Enterprise administrators: app location and retention, identity provider and SSO, IAM gating of agent creation, connector and action allow-lists, data-store residency, console Model Armor on, the tenant egress-gateway decision, the app project under the platform folder, a generalised publishing model for agents from other projects, app audit logs into the central logging project | HLD → detailed |
| PS-05 | platform-security | major | R1 | `wall-e/PREREQUISITES.md` §4.2 and `project-topology.md` §5: five constraints checked per project after it exists; `SETUP.md` Phase 12b step 1 sets SA-key constraints on `WALLE_PROJECT` only; `disableAccessPolicyBinding` lifted on `WALLE_PROJECT` only; the forbidden-configuration list (`06`) is a CI check in Wall-E's repository | Folder-level baseline (`gcp.resourceLocations` EU, SA-key constraints, `automaticIamGrantsForDefaultServiceAccounts`, `allowedPolicyMemberDomains`, `uniformBucketLevelAccess`, `run.allowedIngress`, `run.allowedVPCEgress`, `run.allowedBinaryAuthorizationPolicies`) plus custom constraints enforcing `spec.identityType=AGENT_IDENTITY` and a gateway binding on `ReasoningEngine` and `binaryAuthorization` on Cloud Run; per-project exceptions as factory inputs; spike which custom constraints the resource types support (*tbd*) | HLD → runbook |
| PS-06 | platform-security | major | R1 | `13` §7.6: Wall-E egress in dry-run (`SETUP.md` Phase 13b); ingress conditional on the Gemini Enterprise invoke method (C29, decision 24; `PREREQUISITES.md` §10 item 26); Eve E-19 unresolved; Mo none; tenant app binding "a tenant-wide decision outside this design"; all engines in one project-region share one gateway; a bound engine loses Agent Platform Threat Detection and revisions | Platform rule: every engine created with `agent_gateway_config` bound to an egress gateway (default deny, per-agent access policy), ingress with fail-closed Model Armor for machine-called engines, templated by the factory and enforced by the custom constraint; decide the tenant app's egress binding; decide gateway versus Agent Platform Threat Detection per risk tier; record that one-agent-per-project is also a gateway-policy decision | HLD |
| PS-07 | platform-security | major | R1 | Folder floor (PI HIGH, malicious URL) and a stricter project floor written by Wall-E's `./walle armor` (`SETUP.md` Phase 12c step 7; `project-topology.md` §5); no org-level floor; floor path fail-open, detection-grade (`11` §2); console setting does not cover custom agents; SDP a per-template choice (`11` §4) and not checked by floor conformance | Organisation-level floor owned by IT security (API only), per-tier folder floors, inline enforcement on Vertex at the folder, applied by the factory's Terraform; a committed template standard per tier with SDP basic on and a de-identify template for logs; alert on floor writes; console Model Armor on tenant-wide | HLD → detailed |
| PS-08 | platform-security | major | R13, R9 | Monitoring is per-agent log-based alerts and BigQuery scheduled queries to "the operator channel" (`06` Monitoring; `11` §6; `12` §10); SCC only as a capability lost on a gateway-bound engine (`11` §2; `13` §7.1); SIEM absent except one aside in `14` line 1781; Agent Platform Security dashboard Preview, read not alerted on | SCC Premium at organisation level with AI Protection, SHA and ETD; Google SecOps or the existing SIEM (*tbd*) ingesting Cloud Audit Logs for the agents folder, the org-level Workspace audit sink, Model Armor sanitize logs, registry, deny-policy and floor writes, agents' event topics; a platform detection catalogue; decide per tier between gateway binding and Agent Platform Threat Detection; give Eve a platform reporting channel (SecOps case or SCC finding) | HLD |
| PS-09 | platform-security | major | R13, R5 | `ARCHITECTURE.md` §9 and weakness 13: `walle-actions` ingress `all`, IAM the only gate; VPC-SC "deferred for the pilot … before S1"; decision 21 out of date per `PREREQUISITES.md` §10 item 24; `13` §7.5 PSC spike pending; Eve E-19 open; Mo "no perimeter" | The deferral rested on "no writes" and a narrow OU-scoped role; super admin removes both. Decide one perimeter model for the agents folder per tier: (a) VPC-SC over the folder's projects with connectivity-template gateways (losing Unified Access Policies) or (b) gateway access policies plus `run.allowedIngress` internal-and-cloud-load-balancing behind an internal LB via PSC for every credential holder; "credential holders are never internet-reachable" becomes a folder org policy; re-open decision 21 and E-19 as one decision | HLD |
| PS-10 | platform-security | major | R13, R15 | `SETUP.md` Phase 10 `gcloud builds submit` into a per-project Artifact Registry; CI-only deploys via WIF (`12` §6; `ARCHITECTURE.md` §4.2); no Binary Authorization, SLSA provenance, vulnerability gating or image signing; `14` only notes BinAuth exists; Agent Runtime bundles have no provenance beyond requirements pinning | Folder org policy `run.allowedBinaryAuthorizationPolicies` requiring a policy attested by Cloud Build SLSA-L3 provenance from the shared-services CI project, continuous validation on; Artifact Analysis with a severity gate; a shared Artifact Registry with remote repositories; for Agent Runtime the factory records bundle SHA-256 and dependency lock in the registry entry and `config_versions` and the drift job compares post-deploy (*tbd* until Google offers engine attestation) | HLD → runbook |
| PS-11 | platform-security | major | R11, R13 | `gcp-projects.md` "Secrets" and `ARCHITECTURE.md` §9: per-agent counts of regional secrets; KMS ring `eve` in `EVE_PROJECT`; CMEK unavailable on some runtime paths so unused; KMS Data Access logs enabled only by Eve's runbook; no naming, rotation, CMEK/Autokey, HSM or alert convention | Conventions page implemented by the factory: regional secrets only, naming and rotation labels, folder-level Data Access logs for `secretmanager` and `cloudkms`, folder-level alert on `versions.access` by non-attached identities, CMEK stance via Cloud KMS Autokey with the Agent Runtime exception recorded once, HSM protection level (and Key Access Justifications if Assured Workloads) for approval-authority keys | detailed |
| PS-12 | platform-security | major | R14, R15 | SDP only as a Model Armor filter (`11` §4: basic on, advanced de-identify tbd); `ARCHITECTURE.md` §9 and weakness 11: logs, traces, datasets carry personal data; `PREREQUISITES.md` §10 item 21: `walle-content-logs` has no reader control; no discovery, classification or tagging | SDP discovery at the agents folder over BigQuery and Cloud Storage with findings into SCC; platform data classes declared in registry entries; a de-identify template for the sanitize-log copy decided once; factory-generated log-view IAM on every content bucket; retention defaults per data class | HLD → detailed |
| PS-13 | platform-security | major | R14, R15 | Residency by region choice with two recorded exceptions (`ARCHITECTURE.md` §9; `06` Compliance); zero hits across all pages for TISAX, AI Act, ISO 27001/42001, Assured Workloads, sovereign; EU Data Boundary package covers `aiplatform`, `modelarmor`, `run`, `firestore`, `bigquery`, `secretmanager`, `cloudkms`, `pubsub`, `cloudtasks`, `cloudscheduler`, `discoveryengine` but **not** Agent Gateway or Agent Registry | Decide whether the agents folder is an Assured Workloads EU Data Boundary folder (then spike or record exceptions for Agent Gateway and Agent Registry and review affected features) or record the compensating set (org-level `resourceLocations`, Access Transparency, Access Approval); a platform compliance chapter mapping controls to EU AI Act deployer duties and the TISAX catalogue (the compliance lenses own the mapping) | HLD |
| PS-14 | platform-security | major | R13 | `ARCHITECTURE.md` §11 weakness 12: "time-boxed, alerted break-glass grant" as prose, no mechanism; `project-topology.md` §1.1: the creator holds `roles/owner` on every project; decision 52: four owner groups, one person; Privileged Access Manager not named | PAM entitlements at the platform folder for `roles/owner`, `run.developer`/`run.admin` on credential holders, `secretAccessor`, `iam.denyAdmin`, `orgpolicy.policyAdmin`, `modelarmor.floorSettingsAdmin`, `agentregistry.admin`, with justification, second approver where the two-person rule applies, maximum duration, grants logged to SecOps; no standing `roles/owner` on any agent project after the factory runs | HLD → runbook |
| PS-15 | platform-security | major | R13 | `wall-e/09` decision 30 (Firestore PITR, delete protection, daily backups, restore protocol) open; decision 41 single region accepted; `14` scores DR 5/10; Eve's locked evidence bucket; BigQuery 400-day expiry; no platform RPO/RTO classes, restore drill, or policy for shared services | Recovery classes per risk tier applied by the factory: Firestore PITR plus scheduled backups and delete protection everywhere; BigQuery snapshots or an append-only cross-project mirror for evidence (decision 51 generalised); bucket retention locks; Backup and DR for shared services; a restore drill as a standing promotion criterion; single-region acceptance stated per tier | HLD → runbook |
| PS-16 | platform-security | major | R13, R14 | Three organisation-level sinks created by two agents' runbooks (`gcp-projects.md` "Org structure"), each needing org-level `logging.configWriter` (`PREREQUISITES.md` §4.1); retention tbd on every row of `ARCHITECTURE.md` §9; Data Access logs enabled ad hoc (KMS in `eve/07`) | Central logging project in shared-services with one org-level aggregated sink (Workspace audit plus Cloud Audit Logs for the agents folder) into a retention-locked EU log bucket and BigQuery dataset; per-agent access via log views and authorised views; folder-level Data Access logs for `secretmanager`, `cloudkms`, `iam`, `firestore`, `bigquery`, `sts`; retention defaults per data class; existing agent sinks become views | HLD → runbook |
| PS-17 | platform-security | minor | R13 | `12` §5 designs operator cases (a)/(b); no runbook path (`PREREQUISITES.md` §10 item 18); IAP on Wall-E's approval page and Eve's console; Context-Aware Access only as the Google-managed token-binding policy; security keys only on robot accounts | One platform statement: all human access to agent control surfaces through IAP with a Context-Aware Access level (managed device, security key), factory-created group naming per agent, one workforce pool if non-Google operators exist | detailed |
| WSA-01 | walle-super-admin | blocking | R5 | "Never Super Admin" and the narrow OU-scoped role asserted as design intent on sixteen pages: `wall-e/02` §"Admin rights", §"Two role assignments"; `01` design intent 1 and RB node; `ARCHITECTURE.md` §4.5; `SETUP.md` Phases 2–3 and exit checklist; README, `03`, `05`, `06`, `07`, `09` (decisions 3, 26, 27, 28), `10`, `12` §5.5, `14` (verdict reason 4, C1/C3/C35/C41), `PREREQUISITES.md` §3.2; `setup/walle_setup.py` `isAdmin`-must-be-false checks; `project-topology.md` §7.1 | One dated owner-signed decision "Wall-E holds Super Admin" superseding decision 26 for Wall-E (keep E-16 open for Eve); rewrite `02` §"Admin rights" with the verified fact table; delete the privilege-by-stage and two-assignment sections; edit the listed sentences in place; header notes on `10` and `14`; invert the script's `isAdmin` checks | HLD → agent sets → runbook |
| WSA-02 | walle-super-admin | blocking | R4, R5 | The design had two enforcement points ("Workspace itself can refuse an operation outside the pilot scope", `02` §"Two role assignments"); five controls cite the role as enforcer: OU allowlist (`03` policy step 6), N1/N2 ("not in the custom role", `06`), role-grows-with-the-ladder (`02`; `05` S0, S5), the threat row "Robot credential leak — bounded by the role's privileges" (`06`), `SAFE_USER_FIELDS` | State in `01` and `06` that the action service is the only gate and the scope set the only Google-enforced ceiling; move every never-list row into the policy chain as hard-invariant denials (`posture_change_denied`, `irreversible_denied`, `self_modification_denied`, `money_denied`); add the robot to the committed floor list; make Eve's minute-latency reconciliation of robot-attributed admin events against `walle_audit` the primary detective control; rewrite the credential-leak row as tenant compromise bounded by custody, scope split and detection latency | HLD → agent sets |
| WSA-03 | walle-super-admin | blocking | R3, R4 | Sixteen typed operations (`03` §"Operation catalogue"); generic Admin SDK proxy "rejected, and the reason must be recorded" (`14` C35); decision 27; `01` non-goal "Replacing the Admin console"; C1's bands never written into `01` | Write the bands into `01`: A = typed catalogue on the ladder (only autonomous band); B = generic Admin SDK lane validated against pinned Discovery documents, T0 only, fixed L3 with two-person rule for tier SUPER, pre-state by matching `get`, treated as irreversible, taint and never-list denials apply, never in `playbook.uses`; C = console-only work (DWD, 2SV enforcement, session control, API controls, Marketplace, data regions, billing, Gmail/Drive/Meet settings) served by the C35 handoff-and-verify lane with an explicit prohibition on browser or computer-use automation of the Admin console under the robot's session; re-cut decision 27 as "which lane" | HLD → agent sets |
| WSA-04 | walle-super-admin | blocking | R4, R6 | `06` N1–N9 and §"Never in the catalogue" are absolute ("Not a level, not a stage, not a config flag"); decision 4 unratified | Split into two lists: hard-denied in every lane (anything targeting the robot, `eve@`, Eve's role, control groups, the two OAuth clients, activity rules, audit-log sharing, org sinks; `users.makeAdmin` and any Super Admin `roleAssignments.insert`; `users.delete` of admins; DWD) as severity-1 hard invariants; everything else reachable only via band B at tier SUPER with two-person approval, approver a human super admin, change-ticket reference, hold window; owner signs as decision 4 re-ratified | HLD |
| WSA-05 | walle-super-admin | major | R4 | `02` §"Scopes": fourteen scopes, one client, one token, "scopes are frozen at consent time"; decision 3 | Two OAuth clients on the robot account, two refresh tokens, two secrets, two readers: narrow client for `walle-actions`, broad client for a separate `walle-actions-super` service implementing band B — forcing decision 18 (control-plane split) to now; both Internal, In production, Trusted, consented in the same Phase 9 sitting; `cloud-platform` forbidden in both and checked in CI; 100-tokens-per-client rule unchanged | HLD → agent sets |
| WSA-06 | walle-super-admin | major | R5 | `02` §"Locking down the robot account" and `SETUP.md` Phase 3 assume OU-scoped controls and "Super admin: Never"; no mention of Google-enforced admin 2SV, tenant-wide super-admin self-recovery, super-admin roster count, or other admins' settings now in reach | Rewrite for a super admin: hardware-key-only 2SV (Google-enforced, cannot be bypassed; two keys; M2A-before-M2B ordering kept; 30-day web lockout noted); super-admin self-recovery Off tenant-wide with drift check; no recovery channels; short session control on the OU (settings can be OU-scoped, the role cannot); robot never the only or recovery super admin, at least two human super admins, robot on the floor list; second activity rule on admin events by the robot targeting another admin; `role_assignment_missing` (decision 39) as a paging class in both directions | agent sets → runbook |
| WSA-07 | walle-super-admin | major | R8, R11 | `project-topology.md` §1.2 and `06` threat table reason only about GCP principals; Google documents that a Workspace super admin can grant Organization Administrator through the console | Add rows to `project-topology.md` §1.2, `06` threat table and `10` accepted risks: interactive login or a `cloud-platform` token on the robot reaches the GCP organisation including `EVE_PROJECT` and `MO_PROJECT`; prevented by no-interactive-login (severity 1), witnessed key custody, `cloud-platform` forbidden and CI-checked, org-level Cloud Audit Logs alert on any `SetIamPolicy` by the robot; mark the console mechanism `Assumption:`; state that nothing in Workspace or GCP can narrow the account | HLD → agent sets |
| WSA-08 | walle-super-admin | major | R6, R9 | `eve/03` §"Protected and scope" and `eve/04` step 6 recompute catalogue controls only; no roster check, no evidence heartbeat, hourly reconciliation; via API Wall-E can suspend or delete `eve@`, remove Eve's role, revoke Eve's tokens | Add to Eve's verifier and `wall-e/08` §"What Eve must do": daily roster check (`roleAssignments.list`, `users.list isAdmin`) from Eve's own credential diffed against a committed roster, severity 1 to a human on any change to super admins, the robot, `eve@` or operators; evidence-flow heartbeat paging a human when `admin.googleapis.com` events stop or Eve's token returns `invalid_grant`; minute-latency reconciliation for robot-attributed events; `eve@`, Eve's role and groups as protected principals in every Wall-E lane | agent sets |
| WSA-09 | walle-super-admin | major | R3, R4 | `walle-operators@` membership grants the robot's whole reach; decision 28 defers the live entitlement check "before S1 and before any operator who is not a super admin"; committed operator list covers catalogue families only | For band B / tier SUPER make live check 5b mandatory and fail-closed: requester must be a human super admin (`users.get isAdmin` via the narrow token), approver a different human super admin, both on the audit row; band A unchanged; record as the answer to decision 28 | HLD → agent sets |
| WSA-10 | walle-super-admin | major | R4, R11 | `05` §4 four risk tiers and "`WRITE_HIGH` never reaches L5"; `03` effective-level formula; no tier for band B | Add rows SUPER (T0 L3 two-person; T1/T2/T3 L0, permanent, code not config) and WRITE-generic (T0 L3; others L0); CI asserts band B never appears in `playbook.uses`; HLD states as a permanent ceiling that no super-admin-class operation is ever autonomous | HLD → agent sets |
| WSA-11 | walle-super-admin | minor | R5 | `ARCHITECTURE.md` §4.6 K5; `12` §5.5; `SETUP.md` denial tests 12–13, exit checklist "`$ROBOT` is not a super admin", §7.1 wrong-account text; `setup/walle_setup.py` verify/preflight | Add K6 (a human super admin removes Super Admin from the robot via `users.makeAdmin false`); denial tests gain "write targeting the robot itself" and "any `makeAdmin`"; exit checklist inverts to "`$ROBOT` is a super admin, on the floor list, and every super-admin-class request is denied in the catalogue lane"; script checks invert; §7.1 reframed as an attribution error | agent sets → runbook |
| WSA-12 | walle-super-admin | minor | R1, R11 | `google-workspace.md`, `agents.md`, `overview.md` are skeletons; super-admin roster and Workspace–GCP org relationship tbd | Record the super-admin roster as groups, the robot's super-admin status with its decision link; add a "privilege" column to `agents.md` so a platform of hundreds shows which agents hold tenant-level rights (target: one) | detailed |
| EVE-01 | eve-independence | blocking | R7, R8 | `eve/01` structural choice 1 and "Eve is not a service inside Wall-E's project" argue independence from `EVE_PROJECT` under `FOLDER_ID`; `eve/02` "Eve's Workspace robot" protects `eve@` only through `walle-protected@` and the floor list honoured by Wall-E's own code; `wall-e/02` line 138 "Never Super Admin" is the inherited premise; `eve/06` failure table never considers the tenant itself being administered by the thing under control | HLD decides where Eve's trust root sits: same organisation with independence recorded as detective-only, or a resource the tenant's super admins cannot reach (separate organisation/Cloud Identity, or an Org Admin identity not in this tenant); either way add tenant-integrity rules (actor = Wall-E's account; targets `eve@`, Eve's role, super-admin assignments, DWD, 2SV, audit sharing, operator groups) at severity 1 with out-of-band paging, an absence alarm on Google's feed to Eve, and re-open E-2 and topology decision 52 as blocking for the super-admin grant; verify the super admin's standing recovery rights on the GCP organisation (`Assumption:` today) | HLD |
| EVE-02 | eve-independence | blocking | R6, R9 | `eve/01` components table: sink filter `serviceName=admin.googleapis.com`; `eve/03` §7 "every budget clocks ONE stream: the Admin audit log"; `eve/06` "Google's audit event has not landed"; Reports API scope consented (`eve/02`) but used only for trigger corroboration (`eve/04` flow 2) | Widen the org sink to all six Cloud Logging Workspace streams; add an Eve-owned Reports API poll by actor across applications (token, drive, vault, takeout, admin_data_action, context_aware_access, user_accounts, rules, gcp, …) into `eve_workspace_reports` with lag budgets; decide on the Workspace BigQuery export into Eve's trust root with its "turned off" event as severity 1; publish a per-capability "which stream records it / nothing records it" table as declared limits; extend reconciliation (flow 3) to every ingested stream so an uncatalogued write anywhere is a `reconciliation_gap` and a halt | HLD → agent sets |
| EVE-03 | eve-independence | blocking | R6 | `eve/01` "The deterministic boundary" (verdict a pure function of six plan inputs); `eve/03` §7 and `eve/04` flow 5 closed control-plane reason vocabulary; `eve/04` flow 4 drift covers config, ladder, IAM, registry only; `wall-e/05` §9 sev-1 conditions detected inside Wall-E's own component | A versioned, human-merged detection catalogue in `eve/03` alongside `reasons.yaml`: privilege/role/DWD/2SV/audit-setting changes (sev 1), writes in streams outside catalogue families (sev 1), volume/time-of-day/target-population baselines (sev 2/3, calibrated at S2), prompt-to-action divergence (needs decision 14's signed human assertion); run deterministically in the reconciler limb (`eve-verifier@`), never the gate limb | HLD → agent sets |
| EVE-04 | eve-independence | major | R8, R9 | `eve/01` "Eve is not a model"; `eve-advisor` row "Never, on current evidence"; `eve/09` "Settled — do not reopen without new evidence: no model anywhere in Eve v1 or v2"; `wall-e/09` decision 34 | Keep decision 34 for approve/halt/demote/veto; split Eve in the HLD into a deterministic control path (unchanged) and a reporting path that may reason: build `eve-advisor` in its own project reading `eve.*` and the log tables through authorised views with no free-text columns, writing only `eve.incidents` narratives and `eve.advice`, holding no signer, invoker or secret access, able only to raise a refusal; decide whether it may page (recommend sev 2 only, within the page budget); record the reopening as a dated decision | HLD → agent sets |
| EVE-05 | eve-independence | major | R9, R13 | `eve/06` "The page budget and the paging conditions" (budget tbd, conditions 5–6 tbd, `Assumption:` sev 2 pages, no channel); `wall-e/05` §9 has no notification column; `eve/04` flow 5 "a notification to `walle-operators@`" with no channel; `eve/02` login rule is email inside the tenant; `eve/03` §9 `eve.pages` has three columns; the `eve_silence` incident note is written by `walle-actions`; the "daily digest" is Mo's weekly artefact; `oncall.yaml` covers the no-operator window only; `eve-console` is pull, not push | A reporting contract chapter: per severity, channels, recipients, acknowledgement window, escalation, fallback; sev 1/2 channels out-of-band of the Workspace tenant (Cloud Monitoring notification channels from Eve's trust root: SMS, mobile app, PagerDuty/webhook); an Eve-owned `eve.incidents` table (severity, rule, actor, targets as ids, evidence pointers, narrative, recipients, ack ts/by, resolution, root-cause link); extend `eve.pages` with recipient, channel, delivery result, acknowledgement; extend `oncall.yaml` with primary, secondary outside the Wall-E line, per-severity ack timeouts; record against `wall-e` decision 14 | HLD → agent sets |
| EVE-06 | eve-independence | major | R8, R9 | `eve/01` limit 5 and `eve/06` limit 5; `eve/04` flow 7 "holds all four projects"; `eve/09` E-2, E-13 gated "before S4" / "before S3 exit"; `wall-e/09` decisions 11, 37 open; every notification target is `walle-operators@` or the ladder owner | Make a second recipient outside the Wall-E administration line (IT security) a prerequisite to the super-admin grant: owns `eve-owners@`, required reviewer on `eve/config`, receives every sev 1/2 page in parallel, sole recipient of reports about the administrator (level raises, halt clears, threshold edits, `eve_authority` promotions, requests on protected principals); have Eve report on human prompts as well as robot actions via decision 14's signed human assertion; date the expiry of "the four owner groups are one person" to the super-admin grant | HLD |
| EVE-07 | eve-independence | major | R6, R7 | `wall-e/08` interfaces and `eve/04` flow 5: Eve's authorities are halt/demote/veto on `walle-actions`; `wall-e/12` line 326 and `ARCHITECTURE.md` §4.5: K5 suspend/revoke is a Workspace super admin act by a human; `eve/02`: Eve holds no write privilege ever; `eve/06` compromised-Eve containment is a human revoking `run.invoker` | HLD decides the break-glass path to stop the **account** when the service is bypassed: (a) human-only K5 with a two-person rota and paged runbook, made explicit; (b) a separate deterministic kill-switch holder (not Eve, not a model) with exactly one privilege — suspend the named robot user in `/Automation/Service Identities` — in Eve's trust root, invoked by sev-1 rules; and regardless (c) context-aware access binding the robot account to the action service's egress so a leaked super-admin token is unusable elsewhere | HLD |
| EVE-08 | eve-independence | major | R6 | `eve/02` "Eve's Workspace robot" (Users/Groups/OUs/Admin roles/Reports read; eight scopes frozen at consent; no Drive/Gmail/Chat/Calendar scopes); `eve/09` E-16 gate before onboarding | Before the one-sitting consent add read coverage for domain and customer settings, security/API-controls state where an API exists (`Assumption:` DWD and OAuth app access are seen via the token Reports application — verify), context-aware-access policies, and the Reports API applications; keep "no content scopes"; resolve privileges with `privileges.list` as `eve/02` prescribes | agent sets |
| EVE-09 | eve-independence | major | R6 | `eve/README` and `eve/01` "Eve gates nothing in the pilot"; through S2 Eve is ten scheduled queries read weekly; `eve@` and halting from S3 entry, signing from S4 (`eve/05`) | Re-cut `eve/05` along the two paths: the observe-and-report layer (all-stream sinks, Reports polling by actor, tenant-integrity rules, out-of-band paging, `eve.incidents`) live and drilled before the super-admin grant, which becomes a gate with its own checklist; the gate layer keeps its S3/S4 schedule and seeded-fault exit | HLD → agent sets |
| EVE-10 | eve-independence | minor | R9 | `eve/01` components (`eve-console` IAP audience `walle-operators@`); `eve/04` flow 5 and `eve/02` login rule notify `walle-operators@`; protection from Wall-E is code only | Sev 1/2 recipients are individuals on out-of-band channels; the console's IAP audience is a group in Eve's trust root or, if the tenant is kept, a group whose membership change is a sev-1 rule | agent sets |
| EVE-11 | eve-independence | minor | R10 | `wall-e/08` gives Mo pull requests against Wall-E's repository; `eve/01` `eve/config` is a separate repo with two human reviewers; `mo/*` names no read on `eve.*` beyond a possible mirror read (topology decision 51) and no proposal path to `eve/config` | If Mo proposes changes to `thresholds.yaml`, the detection catalogue or `reasons.yaml`, say so in the HLD; keep the two-human merge with one reviewer outside the Wall-E line; give Mo read on `eve.findings`/`pages`/`incidents` through authorised views only; forbid any Mo output from reaching Eve's control path except via a merged pull request | HLD → agent sets |
| MO-01 | mo-both-agents | blocking | R10 | `wall-e/08` §Responsibilities and §"What Mo must do" give Mo Wall-E duties only; `mo/01` §"What Mo reads" lists only `walle_audit`, `walle_workspace_logs`, Wall-E spans, endpoints and git paths; the only Eve-side grant contemplated is `walle_audit_mirror` from S4, and `eve/03` §9 moves it to its own dataset so Mo cannot see `eve.verdicts`/`findings`/`pages`/`attestations`/`grades_blind`; `mo/03` §7 metric 7 gates Wall-E's L5 cells; `mo/05` S3 excludes Eve's verdicts; `mo/04` §3.2 allowlist and §3.5 type set contain no Eve path or type; all five artefacts under `platform/wall-e/` | Amend `wall-e/08` with Mo rows for Eve (measure detection quality and time-to-report, explain Eve regressions, propose threshold/seeded-fault changes); add Eve tables to Mo's data plane as dataset-level `READER` grants from `EVE_PROJECT` made by Eve's runbook, with Eve's Mo-readable tables split into their own dataset; a second drop-box path allowlist and CI ingestion flow into Eve's repository with its own closed type set; an Eve scorecard and Eve regression explanation keyed on `eve_config_version` under `platform/eve/mo/**` | HLD → agent sets |
| MO-02 | mo-both-agents | major | R10 | `eve/06` §"The disagreement threshold": false-refusal rate is a `thresholds.yaml` row computed by Eve's reconciler from `eve.verdicts` joined to `eve.grades_blind` and acted on by Eve (self-measurement, despite `eve/05` S4 exit saying no Eve exit criterion may be self-reported); wrong accepts severity 2 with no rate; `eve/05` S3 exit runs twelve seeded faults once, no table records results, nothing reruns them; `eve/06` page budget tbd (E-18); no time-to-report metric; `eve.pages` has no acknowledgement column; report quality unmeasured; the twelve faults are for an OU-scoped Wall-E; grades live in `eve.grades_blind` written by `eve-console@` while `mo/03` §10 and `mo/08` change 1 expect `walle_audit.grades` (`mo/08` reopen row (b)) | Move Eve-quality computations into Mo's T0 (false-refusal Wilson bounds, wrong-accept count, agreement, pages vs budget, time-to-verdict and time-to-acknowledge; availability from Wall-E's stamp); Eve keeps its fast automatic drop to advisory on its own number and Mo reports divergence as an Eve finding; add `eve.seeded_fault_runs` written by the harness, scheduled monthly and on every `eve_config_version` change; add `acknowledged_by`/`acknowledged_at` to `eve.pages`; store grades of Wall-E's plans in `walle_audit.grades` and grades of Eve's verdicts in a separate `grades_eve` written by the approval surface; write the super-admin misbehaviour taxonomy and its detector coverage map; Mo publishes it as the Eve-improvement backlog | HLD → agent sets |
| MO-03 | mo-both-agents | major | R10 | `mo/01` §Thesis: every number re-derivable from `walle_audit` and the validator re-derives it; validator holds a dataset-level `READER` on `walle_audit` only and nothing in `EVE_PROJECT` (`project-topology.md` §3 row 21); an evidence block citing an `eve.*` query cannot be re-executed, so an Eve-targeting bundle is refused or accepted on Mo's word, which `mo/01` §"The deterministic boundary" says would void the licence for the model tier | Extend the organising sentence to `walle_audit` plus Eve's quality dataset; grant the validator custodian a dataset-level `READER` on the Eve dataset(s) Mo reads (new topology row, made by Eve's runbook, still no binding in `MO_PROJECT`); golden fixtures for the Eve metrics; until it lands, record that Eve-targeting bundles are advisory `incident_note` only | HLD → agent sets |
| MO-04 | mo-both-agents | major | R10, R8 | `wall-e/08` rule 3 and `mo/04` §7 forbid Mo touching its own gating layer, but Eve's `thresholds.yaml` (the gate for Wall-E's L4/L5 cells) is on no Mo list; `mo/04` §7 change 13 scoped to Wall-E's repository; `eve/01` limit 5 (same human writes thresholds, binds `eve_authority`, grades); `mo/03` §13.2 keeps Eve from authoring evidence it is graded against yet from S4 Mo's source is Eve's mirror; `eve/06` residual: a compromised Eve writes false receipts | A closed Eve proposal type set: `eve_threshold_tighten` (monotone-restrictive, one reviewer), `eve_threshold_loosen` (full evidence block, two reviewers including the decision-37 security reviewer, decision record, five-business-day cooling), `seeded_fault_addition` (additive), `eve_incident_note`; never `predicates/`, `ceilings.py`, `reasons.yaml`, `oncall.yaml`, `eve_authority`; validator-enforced cross-repository rule: no Eve loosening within 30 days of a promote on the same cell in either order; source rule per subject (numbers about Eve from `grades_eve`, `seeded_fault_runs`, golden-replay results and Wall-E's passive `eve_last_seen`, never from `eve.verdicts` alone) as an assertion query; re-argue `eve/01` limit 5 so Eve's second reviewer is neither the ladder owner nor the person running Mo's CI (`mo/06` R5) | HLD → agent sets |
| MO-05 | mo-both-agents | major | R11, R14 | Every Mo component is named and keyed for one agent: `walle_metrics*`, `walle-mo-proposals`, `platform/wall-e/mo/**`, (family, trigger) cells, ten invariant codes from Wall-E's `03`, `plan_hash` recompute against `walle-actions`, `walle_workspace_logs` join; `agents.md` lists Wall-E audit tables as Mo's only source; `mo/README` and `mo/05` §"Run, human": an hour a week of blind grading per agent, indefinitely; `overview.md` Architecture and Constraints still "(to document)"; no platform audit schema or metric contract; the reusable parts (three-tier IAM seam, validator recompute, drop box, surrogate keys, Wilson bounds, seed protocol, freshness watermark, fingerprint tuple) not stated as a platform pattern | Split Mo into a platform measurement contract (every registered agent writes an audit table to a platform schema keyed on `agent_id` with fingerprint tuple, decision, level, `config_version`, verification outcome, cost, Model Armor findings, with a dataset-level `READER` to Mo's T0 recorded in the topology) and per-agent metric packs (Wall-E's ten §8 metrics first, Eve's quality metrics second); tier agents (autonomous with a ladder get grading; classical get cost, reliability, Model Armor `MATCH_FOUND` rate, drift and freshness with no grading hour); publish the per-tier human cost; one Mo per platform in `MO_PROJECT` keyed on `agent_id`; agent-neutral dataset and bucket names before Stage 0; the EU AI Act Art. 72 post-market monitoring plan as a Mo artefact per high-risk system | HLD |
| MO-06 | mo-both-agents | minor | R8, R10 | `mo/05` S0 and `mo/08` reopen row (a) say Mo's T0 in `MO_PROJECT` is the Eve v0 step; `eve/05` S0 and `eve/01` build Eve v0 as twelve scheduled queries in `EVE_PROJECT` pinned to `eve-v0@` writing `eve.findings` with the same ten §8 metrics; both sets expect one to be cut | Keep both as a differential check: an assertion query in Mo's T0 diffs `walle_metrics.scorecard` against `eve.findings` per metric and window and sets `metric_divergence` on the Eve scorecard — the independently written second implementation `mo/01` declined for cost, obtained for free; needs one dataset-level `READER` on `eve.findings` in its own dataset | HLD → agent sets |
| MO-07 | mo-both-agents | minor | R10 | `wall-e/08` §Status says not reconciled; its identities table and item 6 say Mo must never call the action service while its interfaces table and `ARCHITECTURE.md` §7.5 list `mo-analyst@` on two read endpoints (`mo/08` change 9 pending); shared-data-plane table still has Mo subscribing to `walle-events` (change 10 pending); rule 3 says Eve and Mo can lower a level while `mo/01` says Mo cannot | Land `mo/08` changes 9 and 10, reword rule 3 as "Eve can lower and Mo can only propose", and add the Eve rows for Mo in the same reconciliation edit | agent sets |
| MO-08 | mo-both-agents | minor | R4, R6 | `mo/03` §7 rows 1 and 9: hard-invariant denials and audit completeness assume the custom role bounds Wall-E and that `walle_workspace_logs` carries the event classes the catalogue produces; with super admin, an out-of-catalogue action by the robot becomes the primary misbehaviour class, evidenced only by Google's admin log | Make audit completeness the headline Wall-E metric and add a separate count of robot admin events with no matching catalogue operation (target 0, severity 1); verify with a citation that the org-level admin sink and `eve_workspace_logs` capture role-assignment, security-setting, DWD and API-control event classes for a super-admin actor; Mo publishes the event-class coverage of both sinks on the Eve scorecard | agent sets |
| SCA-01 | scale-and-agi | blocking | R11, R12 | `overview.md` "Architecture" and "Constraints" are "(to document)" placeholders; `agents.md` is a four-row table; `project-topology.md` §1–2 fixes four named projects and calls itself "a placement and least-privilege change, not a redesign"; `wall-e/13` "position in one paragraph" is the only mention of "agents this design has never heard of"; no agent class, tier, onboarding path or reuse model | Write a platform HLD above the three agent sets: tier model, landing-zone pattern (folder per tier, project per agent from a factory), shared-services list, a platform charter lifted from `ARCHITECTURE.md` §12's three rules, the topology's "one rule", `06`'s blast-radius method, `12` §1.4's deny policy on the agents principal set, `13` §9's enforcement-vs-detection grading and `05` §1's ladder rules, plus an AGI containment section; Wall-E, Eve and Mo become first instances of tiers, not the platform | HLD |
| SCA-02 | scale-and-agi | major | R11 | `project-topology.md` §1.4: 26 cross-project grant rows, each "a runbook step in the resource's project, made by that project's owner, and a row in a drift job"; decision 52 (four owner groups, four budgets, notional with one admin); `SETUP.md` "Last executed: never", hand-run; `PREREQUISITES.md` §10 lists 32 runbook defects for one agent; `wall-e/12` §7 and `13` §5.1 show one-engine-per-project is Google-forced (`discoveryengine.serviceAgent` is project-wide; all engines in a project-region share one gateway); Terraform is GA for engine, engine IAM and registry yet everything is scripted in `gcloud` | Terraform modules `agent-project` / `verifier-project` / `improver-project` whose inputs are topology §3 rows generalised (invoker principals, dataset `READER`s, engine query role, deny policy, key constraints, budget, labels); Cloud Foundation Fabric FAST project factory (YAML-driven) or equivalent creates projects under tier folders; replace per-agent drift jobs with Cloud Asset Inventory feeds and Terraform plan-drift at folder level; Resource Manager limits pose no obstacle | HLD → runbook |
| SCA-03 | scale-and-agi | major | R1, R13 | Everything per agent: registry per project (`13` §2.1, automatic registration same-project only; whether Wall-E's registry lists Eve/Mo tbd), Model Armor templates per project, three organisation-level log sinks for three agents (`gcp-projects.md`), one bespoke `*_audit` dataset per agent, per-agent content-log bucket and approval surface (`12` §5.3), validator custodian project tbd; `13` §7.6 defers binding the Gemini Enterprise app to a gateway | Name a `platform-core` project holding the inventory of record, an evidence lake with a versioned platform audit schema (insert-only per-agent writers), one folder-scoped aggregated sink per log family with `includeChildren` instead of N org sinks, a shared Model Armor template pipeline, one shared IAP approval surface, the validator custodian and the ladder-state page; keep engine, gateway binding, action service, secrets, Firestore and verifier keys per agent; decide explicitly whether the Gemini Enterprise app is gateway-bound | HLD |
| SCA-04 | scale-and-agi | major | R1, R14, R15 | `13` §2.2 "the registry answers what exists", §2.5 "a privilege, not a phone book", §9 "Neither. A catalogue"; no resource-level IAM on entries; Eve's viewer dropped (decision 43); automatic registration same-project only; hand-written card "not before S3"; no label taxonomy anywhere | Inventory of record = reconciled triple: Cloud Asset Inventory over `ReasoningEngine`, Cloud Run agent services and Gemini Enterprise agents (folder-scoped, exported daily); a platform registry in `platform-core` (regional, `europe-west1`) where CI registers every card under the two-reviewer rule; a required label set (`owner`, `tier`, `risk_class`, `data_class`, `autonomy_ceiling`, `model_pin`, `verifier`); an unregistered or unlabelled engine in the folder is a finding via asset feed, since no org constraint can require registration; keep "registration never authorises" | HLD |
| SCA-05 | scale-and-agi | major | R1 | `06` "Forbidden configurations" and `12` §8.1 step 3 enforce Agent Identity and gateway binding by CI checks in each agent's repository; `13` §7.1: 5,000 resources per gateway, one gateway per project-region; `PREREQUISITES.md` §10 item 24 says gateway and VPC-SC now compatible while Google's runtime page (2026-09-08) says not supported and the overview (2026-09-10) says perimeter rules apply via a connectivity template — the pages contradict; Model Armor 600/1,200 QPM per project (`11` §6); `13` §7.3 accepts fail-closed availability coupling for one agent | Folder-level custom org constraints on `aiplatform.googleapis.com/ReasoningEngine` requiring `agentGatewayConfig` set and in an allowed list (CEL verified on Google's page, CREATE/UPDATE); verify whether `identityType` is constrainable before relying on it; `AuthProvider` custom constraints at folder level; floor at folder plus fleet-wide alert on floor/template change; treat gateway plus Model Armor as a platform availability domain with an SLO; per-project Model Armor quota is an argument for per-agent projects; spike the VPC-SC contradiction | HLD |
| SCA-06 | scale-and-agi | major | R11, R10 | `05` §1–4, §6 are general in shape, but families F1–F10 are Workspace operations (`05` §5), ceilings are `ceilings_sha` inside `walle-actions` (`ARCHITECTURE.md` §8.3), config is `walle/config/ladder.yaml`, decision files are `walle-promote-*`, the validator re-runs Wall-E's SQL against `walle_audit` (`mo/01`), Eve compiles ceilings from Wall-E's CI artefact and re-implements Wall-E's predicate at six engineer-days (`eve/01` choice 5, §Cost), Mo's contract is `walle_audit`'s columns; no machine-readable agent manifest | Extract a platform autonomy contract: `agent-manifest.yaml` (families, risk tier, reversibility, inverse, predicate type, taint fields, trigger classes, ceilings); contract-versioned `ladder.schema` and `audit.schema` implemented by every action service; one platform validator custodian; ratchet, dwell, Wilson gates and severity table as platform defaults agents may only tighten; Eve generalised per tier with predicates from the manifest, recording that the "second implementation" property weakens; the `agent` ceiling column (`13` §5.4, L0 for every write) made a fleet-wide rule | HLD |
| SCA-07 | scale-and-agi | major | R11, R12 | Five boundaries (`01`) plus a hand-written action service with catalogue, policy chain, ladder and audit are mandatory for the one agent designed; applied literally to a read-only RAG assistant this is disproportionate, applied to an AGI-class agent it is incomplete; no tier model; `14` rejects a generic Admin SDK proxy for Wall-E only | Define tiers with mandatory controls per tier: T0 classical (Gemini Enterprise no-code/data-store agents, user's own permissions, console Model Armor); T1 read tools (Agent Runtime, Agent Identity, gateway default-deny, MCP/A2A through the gateway with Model Armor on MCP payloads, no write path); T2 write agents (action service, catalogue, ladder, audit schema, verifier); T3 privileged (Wall-E's full set plus a Workspace credential) — the super-admin variant a singleton T3 sub-class in its own folder with its own kill plane, and since super admin cannot be OU-scoped the platform gate is the only scoping; TX AGI-class per SCA-09; state per tier which controls are platform-enforced versus agent code | HLD |
| SCA-08 | scale-and-agi | minor (major if no tier model) | R10, R11 | `mo/01` "What Mo reads" is `walle_audit.*` only; the scorecard, gates and fixtures are Wall-E's; nothing measures Eve as an Eve metric Mo publishes; `eve/01` choice 5 is per-agent by construction | Mo reads the platform audit schema so any agent implementing it gets a scorecard; add Eve's own metrics to the contract (refusal precision, halt false-positive rate, time-to-verdict, drift-detection latency); Mo's proposals about Eve are pull requests to `thresholds.yaml` merged by a human | HLD → agent sets |
| SCA-09 | scale-and-agi | blocking | R12, R13 | Nothing addresses AGI-class containment. Present: capability ceiling outside the agent (`05` §4, `03`, `13` §5.4), default-deny egress by hostname (`13` §7.2), no credential reach with a project-level deny policy (`12` §1.4). Absent: fleet kill switch outside the agent's project (K0–K5 in `ARCHITECTURE.md` §4.6 all live in `WALLE_PROJECT` or Workspace; a compromised project owner undoes them, topology §1.2); evaluation gates before capability grants; EU-resident sandboxing (Agent Runtime Code Execution has no EU residency, never enabled, `06`/`ARCHITECTURE.md` §9); capability-drift monitoring (only C15 fingerprint drift and `11` §6 filter drift; Agent Platform Threat Detection Preview and unavailable with a gateway bound); no-self-modification against a code-writing agent (weakness 12; Mo already opens pull requests) | Buildable now: lift the deny policy and add a Principal Access Boundary on `principalSet://agents.global.org-ORG/*` to folder/organisation level as the fleet kill switch (verify permission names against the deny-supported list), drilled like K0; folder rule that no agent principal holds any write on repositories, Artifact Registry or deploy identities, Binary Authorization on images, agent-authored PRs labelled and reviewed; GKE Agent Sandbox (gVisor, default egress blocks RFC 1918, DNS, metadata; page dated 2026-09-10, stage *tbd*) in `europe-west1` as the only EU code-execution tier; behavioural baselines per agent from the audit schema plus SCC AI Protection where compatible. Research-grade, recorded honestly: capability evaluations (provider-side, Frontier Safety Framework) and deception-robust trusted monitoring; the platform's AI-control primitive is a model-free monitor with halt authority (Eve's shape), every new model pin re-qualifies every cell (C15), the halt path never contains a model, and peer callers are L0 for writes with taint on receipt | HLD |
| SCA-10 | scale-and-agi | minor | R11 | `gcp-projects.md` "Quotas & limits to watch" empty; `SETUP.md` §0.3 quotes no unit prices; `mo/01` says the billing export is not provisioned; Model Armor and gateway limits known for one project only; Agent Runtime quotas page did not render (*tbd*) | A platform quota register (Model Armor 1,200 QPM per project, gateway 5,000 resources, Agent Runtime engines/QPM *tbd*, org sink ingestion), one billing export in `platform-core` keyed on the label taxonomy, per-tier budget defaults created by the factory; each T3 agent is a licensed Workspace user and an admin-role holder, so T3 stays rare by policy | detailed |
| SCA-11 | scale-and-agi | minor | R13 | `09` decision 21 and `13` §7.1 say Agent Gateway and VPC-SC are not supported together; `PREREQUISITES.md` §10 item 24 says supported since 2026-09-08 with a connectivity template; Google's runtime deploy page (2026-09-08) and overview (2026-09-10) disagree with each other | One spike on a throwaway engine, one decision record naming which Google page was right; at fleet scale the folder-wide perimeter is the natural egress backstop and the answer matters more than for one agent | HLD → runbook |
| AIA-01 | eu-ai-act | blocking | R14 | No page mentions the Act; `overview.md` Constraints is a stub; `06` §Compliance and `09` decision 8 frame compliance as data protection; `14` line 174 puts the legal question outside every review | Create `platform/ai-act.md` (or the compliance chapter of this set) as the single authority: per AI system the legal entity and role, declared intended purpose, Art. 6 analysis with the Art. 6(3) condition and the profiling question answered, Art. 5 check, Art. 50 position, registration status, obligation crosswalk; legal sign-off dated; Wall-E's entry before Stage 1 | HLD → detailed |
| AIA-02 | eu-ai-act | blocking | R4, R14 | `01` intent 1, `ARCHITECTURE.md` §4.5 and `06` N1/N2 and "Never in the catalogue" are all written against a narrow OU-scoped custom role that the objective removes | HLD states that the catalogue is the intended purpose and Super Admin a credential fact; "Never in the catalogue" (user delete, admin roles, security posture, Vault, billing) becomes the Art. 6(3) boundary enforced in code with CI ownership outside the agent repo; otherwise declare "any admin action" as purpose and plan full Chapter III compliance (Art. 43/47/49) by 2027-12-02 | HLD |
| AIA-03 | eu-ai-act | major | R9, R13 | `05` §2 levels, kill switches in `04` and `ARCHITECTURE.md` §4.6, L4 veto window, L5 digest, `eve/06` paging map onto Art. 14(4)(a)–(e), but no page names the overseers, their competence or training, no automation-bias control for approvers, no level cap for Annex III-relevant families F5/F7 where Eve (not a natural person) is the L4 gate | Oversight chapter naming roles and training, per-family maximum level compatible with Art. 14 (F5/F7 capped at L4 with holds that never expire outside business hours), K0 drill recorded as the Art. 14(4)(e) stop test, operator self-grading sample as automation-bias control | HLD → detailed |
| AIA-04 | eu-ai-act | major | R13 | `walle_audit` in `03` §Storage is a strong Art. 12 log at 400 days and Eve's locked bucket (`eve/03`) matches; content logs and Model Armor sanitize logs are `Assumption:` 30 days (`11` §6), Cloud Trace 30 days, `params_redacted` omits what the model saw, no page says which stores are the Act's automatically generated logs | Retention matrix (store, content, legal basis, retention, readers) pairing each Art. 12 purpose with its store; designate `walle_audit` plus the frozen plan as the Art. 12 log; record the data-minimisation reasoning for stores under six months | detailed |
| AIA-05 | eu-ai-act | major (blocking on 2027-12-02 if high-risk) | R14 | Wiki close to Annex IV in substance but `01` status says `14` edits are not applied, `08` is unreconciled, `eve/08` lists ~20 unapplied contradictions; no instructions for use, no QMS, no post-market monitoring plan although `mo/04` §1 is exactly its evidence, no incident procedure | Annex IV crosswalk page with "frozen at stage N" tags; operator instructions-for-use derived from `06`, `eve/06` and the ladder with declared accuracy levels; Mo's artefacts declared as the Art. 72 plan; ten-year retention of decision records and compliance snapshots; wiki reconciled before Stage 1 | detailed → agent sets |
| AIA-06 | eu-ai-act | major | R1, R14 | Operator chat via Gemini Enterprise is obviously AI (Art. 50(1) exception plausible); families F2 templated and F2b free text (`06` N6) send mail and Chat to employees with no disclosure that the text is AI-generated; Art. 50 applies since 2026-08-02 | Action service injects a fixed disclosure line and header into every F2b message (never the model); agent card and Gemini Enterprise description state the responder is an AI system; record the Art. 50(2) text-marking position with what the model provider supplies | agent sets |
| AIA-07 | eu-ai-act | major | R14 | Decision 8 and `PREREQUISITES.md` row D7 ask the DPIA / representative-body question "before Stage 3", framed as data protection only | Move consultation before Stage 1 and frame it under both GDPR and the AI Act (Art. 26(7), 26(11)); add an Art. 86 explanation path exposing the frozen plan's rationale and pre-state, redacted, to the affected employee via HR | HLD → detailed |
| AIA-08 | eu-ai-act | major | R9, R14 | Engineering alerts and paging conditions exist (`06` §Monitoring, `eve/06`) with no mapping to Art. 3(49), no reporting owner, no 15-day/2-day deadlines, no rule against altering the system before the authority is informed (Art. 73(6)) | Incident taxonomy naming which events are AI Act serious incidents (mass wrongful suspension first), reporting owner and deadlines, evidence-preservation rule; align with the TISAX incident process (TIS-09) | detailed |
| AIA-09 | eu-ai-act | major | R13, R14 | `06` threat model, `10` (17 attacks) and `14` (54 challenges) are security-only; Art. 15 largely met via Mo metrics, breakers, Model Armor, injection suite; no fundamental-rights risks (wrongful suspension, discriminatory inactivity heuristics), no lifecycle loop with acceptance criteria, no input-data relevance statement for the HR feed and usage reports | Add a fundamental-rights column to the adversarial-review format; the per-stage decision record carries the Art. 9 residual-risk statement fed by Mo's regression explanation; declare accuracy metrics in instructions for use; state input-data relevance for triggers | detailed → agent sets |
| AIA-10 | eu-ai-act | major | R11, R12, R14 | `13` §2 treats Agent Registry as a security directory and `agents.md` as a status catalogue; no AI Act fields, no gate between idea and prod, no policy on training or fine-tuning models, no Art. 25(4) position with the model provider | HLD defines a publication gate: no agent reaches Gemini Enterprise without an `ai-act.md` entry; the registry entry carries the classification id validated in CI like the agent card; a one-line GPAI policy that the platform hosts third-party models and never trains or substantially modifies them | HLD |
| AIA-11 | eu-ai-act | minor | R8, R14 | `eve/01` "Deterministic by absence" and `agents.md` "Eve is not an agent" state the property for safety only | Record in Eve's HLD and CI check that a model-free Eve is outside the Act's AI-system definition and can serve as an oversight measure; keep the `eve-advisor` slot outside Eve's authority path | agent sets |
| AIA-12 | eu-ai-act | minor | R14 | Nothing recorded; operators named in `PREREQUISITES.md` §D without any training measure; no negative determination on emotion recognition, social scoring, biometric categorisation | One-page Art. 4 measure from `06` and the ladder with attendance recorded; dated Art. 5 negative determination in `ai-act.md` | detailed |
| AIA-13 | eu-ai-act | minor | R14 | Nothing recorded on FRIA (Art. 27) or public-authority registration (Art. 26(8)) | Record the `Assumption:` that the organisation is private, provides no public service and uses no Annex III 5(b)/(c) system, so Art. 27 and 26(8) do not apply; name entity and date | detailed |
| TIS-01 | tisax | blocking | R15 | No page mentions TISAX; `overview.md` §Constraints tbd; `06` §Compliance covers data protection, residency and retention only; nothing names a label, an assessment level, a scope location or an ISA version (6.0.3 in force; ISA2027 applies to assessments ordered from 2027-01-01) | HLD states target label (`Assumption:` Confidential; Strictly confidential if `walle_audit`, content logs or conversation history are secret under the organisation's scheme), no availability label, AL2 working level, scope location *tbd* from the ISMS, mapping against ISA2027 with 6.0.3 cross-reference; new page `platform/agentic-platform/0x-compliance-mapping.md` with per-control mechanism, evidence, owner, status | HLD → detailed |
| TIS-02 | tisax | blocking | R5, R15 | `02` §Admin rights "Never Super Admin"; §Two role assignments relies on Workspace refusing operations outside the pilot OU as "a second enforcement point outside our own code"; `06` N1 and threat-model residual; `ARCHITECTURE.md` §4.5; super admin cannot be OU-scoped, so the catalogue becomes the only privilege boundary and the robot becomes a protected principal under its own N7/`_check_target` rule | Dated decision record accepting the deviation, signed by the security reviewer (decision 37), entered in the risk register; HLD restates the privilege boundary honestly and makes the split control plane (decision 18), an independent human-reachable halt/K5 and the second deploy reviewer (weakness 12) preconditions of granting the role; privileged-account procedure (creation, hardware-key custody, no interactive login, login activity rule, quarterly role review against a signed list, rebuild checklist per decision 39); super-admin-level actions stay typed and enumerated, never free-form; protected-self logic re-run | HLD → detailed → agent sets |
| TIS-03 | tisax | blocking | R8, R10, R13 | `ARCHITECTURE.md` §11 weakness 10 ("a one-person operator rota is the binding constraint"); `09` decisions 11 and 37 (second operator, approver, security reviewer, validator custodian tbd); `eve/09` E-2, E-13 ("the boundary is notional"); topology decision 52 (four owner groups are one person); `PREREQUISITES.md` §2 empty checkboxes | HLD carries a platform RACI (owner, security reviewer, deployer, operator, approver, grader, DPO contact, Eve owner, Mo owner, incident manager) with minimum staffing per stage; the ISMS supplies the names; an organisational control that does not exist and the item most likely to stop an assessment | HLD (organisational) |
| TIS-04 | tisax | major | R1, R15 | Google never treated as a supplier; `ARCHITECTURE.md` §9 records residency per component and two exceptions; `project-topology.md` §5 records constraints; nothing records Google's TISAX status (scope SYN0NK, assessments ATTRRN-1/2, per-region labels incl. `europe-west1`), DPAs, sub-processors, SLAs, exit/deletion, or which ISA controls Google holds; coverage of BigQuery EU multi-region, global Model Armor floors, Gemini Enterprise `eu`/`global`, the Google-managed Agent Runtime tenant project and the org-level audit sink unconfirmed; `13` §1 says Wall-E consumes and exposes no MCP server but no onboarding rule exists for a third-party agent, MCP server or Marketplace app | Supplier page for Google (request the ENX result share, file it), per-control shared-responsibility column (Google / platform / ISMS), explicit *tbd* on the unlisted services, the model as a separate supplier item; controls that do not exist: a 5.3.3 return-and-removal procedure at teardown/contract end; a 6.1.1 onboarding rule for external agents/MCP servers (ISA2027: at very high protection need suppliers show a TISAX label or equivalent) | detailed |
| TIS-05 | tisax | major | R11, R15 | `project-topology.md` §2/§9 is a de facto resource inventory for four projects with no owner per asset (decision 52) and no classification; `gcp-projects.md` and `google-workspace.md` are skeletons; `agents.md` is a four-row table; `13` §2.5 states Agent Registry is "a catalogue, not a control" and cannot serve as the governance register | Classify `walle_audit`, `walle_workspace_logs`, `eve_workspace_logs`, the content-log bucket, Cloud Trace, Gemini Enterprise conversation history, `walle_metrics_private` against the organisation's scheme; owners per project; an agent register in the HLD (owner, purpose, data and classification, risk tier, autonomy ceiling, identity, gateway and Model Armor binding, supplier, EU AI Act class, TISAX relevance, review date), Agent Registry entries generated from it, CI refusing an engine without a register row | HLD → detailed |
| TIS-06 | tisax | major | R13, R15 | `walle_audit` 400 days "subject to your retention policy" (`03` §Storage; `09` decision 17; `eve/09` E-14 and `mo/08` M-5 require floor and ceiling before Stage 1); org-level sink retention tbd and Cloud Logging "`Assumption:` 30 days" (`ARCHITECTURE.md` §9); conversation-history retention tbd (`14` C42); "Data Access audit logging is enabled nowhere in the set" (`14` C43); `walle_audit` deletable by a project owner and inside teardown blast radius (decision 31; topology decision 51); no SIEM export | Decide floor and ceiling now in one decision file; enable Data Access audit logs for `iap.googleapis.com`, the IAM Credentials API and Secret Manager in all agent projects (`12` §10 lists two as tbd); state log-integrity protection per store (Eve's locked bucket is the model); one organisation-level sink to the corporate SIEM or a recorded statement that the SOC reads Cloud Logging | HLD → runbook |
| TIS-07 | tisax | major | R13, R15 | Process well designed (`05` §10; `ARCHITECTURE.md` 4.2) but `wiki/decisions/` holds only README and template; decision 29 leaves the gate changing first in production; git host and admin bypass tbd (`mo/08` M-7); CI deployer identity tbd (`PREREQUISITES.md` §10 items 10, 22); `google-adk~=2.8` and `google-auth>=2.45.0` float; no image scanning, CVE triage or patch cadence; software approval implicit in decision 6 only | Missing controls: pre-production project or sandbox tenant before S1; Artifact Analysis scanning with blocking threshold; hash-pinned lockfile with monthly review; git admin bypass disabled and audited. Documentation: release and emergency-change procedure, rollback references to `SETUP.md`, first decision files (super-admin deviation, retention, single region) | HLD → runbook |
| TIS-08 | tisax | major | R13 | Decisions 30 (RPO/RTO, PITR, delete protection, restore starts at `halt_all`) and 41 (single region) are recommendations, not decisions; `14` C45 "no backup is configured"; `eve/06` covers how Eve treats a restore; no BIA, no restore exercise, manual Admin-console fallback not written as the continuity plan | One-page continuity statement (agents are not critical IT services; evidence stores are the critical asset with RPO 24 h via Eve's mirror and locked bucket; SLA references in the supplier file); missing controls: Firestore PITR and scheduled backups at Phase 7, one recorded restore exercise before S1, `halt_all` boot rule on restore | detailed → runbook |
| TIS-09 | tisax | major | R9, R13 | `05` §9 severities and automatic responses; `ARCHITECTURE.md` 4.6 kill switches, K3+ "open an incident"; `05` §10 writes notes under `platform/wall-e/incidents/` which does not exist; `eve/06` page budget and paging conditions; no reporting channel, incident manager, escalation to CSIRT/SOC, 72-hour GDPR breach path, evidence preservation, post-incident review, or crisis scenario (abused super-admin robot credential) | Platform incident page (event definitions extended to Eve, Mo and hosted agents; channel; roles; SLAs; escalation; breach link; note template; one crisis scenario with tabletop date); missing control: a staffed human recipient of Eve's reports with an acknowledgement SLA — today the recipient group has one member | detailed |
| TIS-10 | tisax | major | R14, R15 | Decision 8 (DPIA and employee representatives, "longest lead time"); `ARCHITECTURE.md` weakness 11; `PREREQUISITES.md` §9 question sent, checkbox empty; `mo/02` §4 (Mo inside the perimeter as processor; "aggregated per OU" claim wrong); `11` §6 content logs and span capture; `14` C42 conversation history an unlisted copy; no records of processing, DPIA, retention decision, data-subject-request path or employee notice | ISMS/DPO owns the artefacts, platform owes inputs: records of processing per agent (9.3.1), DPIA (9.4.1), transfers incl. the two residency exceptions and model location (9.5.x), data-subject requests answerable across all stores (9.6.1), breach process (9.6.2), operator training (9.7.2), deletion capability tied to 5.3.3 (9.8.1); works-council track in parallel; HLD states the platform is not built for the Data label unless a hosted agent later processes customer data as processor | detailed (ISMS/DPO) |
| TIS-11 | tisax | minor | R15 | `06` threat model, `10` adversarial review, `14` challenges, `ARCHITECTURE.md` §11 weaknesses, `eve/06` and `mo/06` failure modes all carry residuals; none has likelihood, impact, owner, treatment or signed acceptance | Risk register page or ISMS tool, one row per weakness and accepted residual, super-admin deviation as row one, security reviewer's acceptance as a decision file, refreshed at each stage decision | detailed |
| TIS-12 | tisax | minor | R13 | Denial suite (`SETUP.md` §4), drift job (`12` §10), kill-switch drills (`ARCHITECTURE.md` 4.6), injection suite (`11` §6) — no penetration test, internal audit or management review | Penetration test of the action service, approval page and Gemini Enterprise share before S1; annual internal-audit slot and management review of the ladder state page in the ISMS calendar | detailed → runbook |
| TIS-13 | tisax | minor | R13 | Strong per-key detail scattered across `eve/02` §The signing key, `02` §Rotation, `ARCHITECTURE.md` §9 (CMEK unavailable for the reasoning layer); no key inventory, no reference to an organisational crypto standard | One table in the compliance mapping (key/secret, algorithm, location, rotation, owner, audit log); CMEK position for BigQuery, Firestore, GCS decided with the label choice; reference the organisation's cryptography standard (*tbd*) | detailed |
| TIS-14 | tisax | minor | R13 | Operators approve, veto, grade and pull kill switches; nothing describes training on the taint bit, approval-card canonicalisation or severity-1 recognition; blind-grader role (`eve/09` E-13, `mo/08` M-4) unnamed and untrained | Short training outline per role with completion record, refreshed at each stage transition | detailed |
| TIS-15 | tisax | minor | R13 | `ARCHITECTURE.md` weakness 13 (credential holder internet-reachable, IAM the only gate); decision 21 says Agent Gateway and VPC-SC are incompatible; `PREREQUISITES.md` §10 item 24 says that is out of date since 2026-09-08 (surviving blocker: Unified Access Policies); topology §5 defers the `EVE_PROJECT` perimeter to E-19 | Re-open decision 21 in the platform HLD as a single network posture for all projects, decided before S1, compensating controls named until then (same decision as PS-09 and SCA-11) | HLD |
| TIS-16 | tisax | minor | R14, R15 | GDPR, AI Act, works-council rules and the Google contract mentioned in passing; NIS2 not mentioned (ENX published a NIS2 fulfilment analysis 2025-06-29); no list of the platform's applicable set | Table in the compliance mapping: instrument, why it applies, owner, evidence; NIS2 applicability *tbd* with the ISMS | detailed |
| MON-01 | monitoring | blocking | R13, R11 | Every alert is a Cloud Monitoring policy or BigQuery scheduled query inside the agent's own project with its own hand-pasted channel: `SETUP.md` Phase 16, `11` §6, `eve/07` Phase 5, `mo/07` Mo-7; `06` "Monitoring" lists signals with no destination; "SIEM" appears once, hypothetically, in `14` C43; `overview.md` Architecture still "(to document: … logging)" | Platform HLD names one SIEM (own Google SecOps instance in EU multi-region/`europe-west3` with retention raised from the 12-month default, or the organisation's existing SIEM — IT security decides); four organisation-owned feeds needing no domain-wide delegation: Admin-console native SecOps export of Workspace events (Enterprise Standard/Plus prerequisite, tbd; also covers Gmail/Drive/Calendar/Chat events Cloud Logging never receives), one folder-level aggregated Cloud Audit Logs sink, SCC findings, agent-layer events as metadata only via Pub/Sub; "registered in Agent Registry ⇒ feeding the SIEM" as a platform invariant; per-project absence policies kept as the builder-owned liveness layer | HLD |
| MON-02 | monitoring | blocking | R5, R9 | `06` "Threat model" mitigates "Robot credential leak" with "Custom role, not Super Admin; OU-scoped role"; `SETUP.md` Phase 2 says super admin "Never"; `ARCHITECTURE.md` §4.5 "never super admin"; no monitoring row for "Share data with Google Cloud services" being turned off (Phase 5), Admin console rule edits (Phase 4), role creation/assignment, API-controls/OAuth/DWD/2SV/SSO changes, or GCP-side `SetIamPolicy`/sink/`auditConfig` changes — although a Workspace super admin holds irrevocable Organization Administrator power and could collapse Eve's independence (`eve/01` choice 1) without an alert; `14` C4 already records undetected refresh-token replay | Severity-1 detections owned by the SOC and hosted in the SIEM, not in Wall-E's project: any `admin.googleapis.com` `methodName` by `walle@` outside a committed allowlist derived from the catalogue; any role assignment or creation; any change to data sharing, activity rules, API controls, OAuth trust, DWD, 2SV, SSO, recovery or session settings; any `login.googleapis.com` event; any token authorisation from a non-committed client id; on the GCP organisation: `SetIamPolicy` at org/folder/`EVE_PROJECT` by `walle@`, `logging.sinks`/`buckets` changes on the org sinks and locked buckets, `auditConfig` and `orgpolicy` changes; pipeline-integrity heartbeats (absence alert on `eve_workspace_logs` rows per hour; new halt reason `log_pipeline_silent`); record in the HLD that with super admin detection is the primary control; drift job checks `walle@` holds no organisation-level IAM role | HLD → detailed |
| MON-03 | monitoring | blocking | R9, R13 | `05` §9 gives severities, automatic responses and deadlines but no channel, roles or record; `ARCHITECTURE.md` §4.6 "K3 and above open an incident" — where and by whom unstated; channels are "paste yours" (`SETUP.md` Phase 16), `"notificationChannels": []` (`eve/07` Phase 5), "Wall-E's on-call channel" (`mo/07` Mo-7) never defined; `eve/06` page budget tbd, conditions 5–6 empty, `oncall.yaml` only triggers a halt when nobody covers; weakness 10 one-person rota; decisions 11 and 37 open | An incident-response playbook page in the platform set: roles (incident commander from IT security, on-duty Workspace super admin able to pull K5 within a stated time, Wall-E owner, DPO, communications), severity-to-response mapping reusing `05` §9, per-scenario runbooks (robot interactive login, token replay, forged approval, CI/deployer compromise, Eve compromised or silent, Model Armor/gateway outage, log-pipeline outage, out-of-catalogue super-admin action, Art. 73 serious incident); one organisation-owned PagerDuty (or equivalent) service as the Terraform-managed channel in all four projects with L1 SOC → L2 platform owner → L3 IT security escalation and acknowledgement targets (tbd; `Assumption:` 15 min business hours, 60 outside); one incident record system carrying `run_id`/`plan_id`/`audit_id`, copied to the locked evidence bucket; fold Eve's page budget into the SOC alert budget and fill conditions 5–6 from the super-admin detections | detailed |
| MON-04 | monitoring | major | R14, R15 | `walle_audit` 400-day table expiry, deletable by a project owner (decision 31); Eve's mirror append-only by IAM, not locked; the locked evidence bucket in `EVE_PROJECT` is the only immutable store; `walle-content-logs` 30 days, unlocked, readers unrestricted (`PREREQUISITES.md` §10 item 21); `ARCHITECTURE.md` §9: project logs "`Assumption:` 30 days", org Workspace logs tbd; verified: Login and SAML entries are Data Access logs in the org `_Default` bucket (30 days unless changed) and neither Phase 11 sink nor Eve's Phase 7 sink routes `login.googleapis.com` (`SETUP.md` Phase 4); decisions 17, 31, E-14, M-5 all open | A retention schedule page (source, store, region, days, locked, owner, legal basis, personal-data flag) covering every store; route login/token/saml org logs into a locked regional Cloud Logging bucket in `EVE_PROJECT` or the SIEM at 400 days; daily JSONL export of `walle_audit`, `eve.findings` and `eve.verdicts` partitions into the locked evidence bucket by `eve-verifier@` (closes decision 31); floor = max(six months, organisation standard), ceiling = DPO (decision 8); 400 days stays as `Assumption:`; separate shorter line for `walle-content-logs`; lock its readers before any content is produced | detailed → runbook |
| MON-05 | monitoring | major | R13 | `06` alerts on "Secret access by a non-service identity … Cloud Audit Logs" but `AccessSecretVersion` is `DATA_READ` and no Wall-E phase enables it (no `auditConfigs` in `SETUP.md`); `14` C43 found the same for IAP; Eve enables it for KMS only (`eve/07` Phase 11), Mo for Cloud Storage only (Mo-9); the Gemini project's `discoveryengine.googleapis.com` Data Access entries (`StreamAssist`, `AnswerQuery`, `GetAgentCard` — the human's actual requests) never enabled; `project-topology.md` §7.4 has no logging item for the Gemini project | One organisation- or folder-level `auditConfigs` policy (Terraform, platform-owned, drift-checked) enabling `DATA_READ`/`DATA_WRITE` for `secretmanager`, `iap`, `cloudkms`, `firestore`, `aiplatform`, `discoveryengine`, `sts`, `storage` on evidence buckets; no exemptions for agent principals; cost line in `SETUP.md` §0.3; route to the SIEM rather than per-project buckets | HLD → runbook |
| MON-06 | monitoring | major | R1, R13 | SCC appears only as a cost of the ingress gateway (`11` §2, `13` §7.1); Model Armor findings read from the sanitize log; the Agent Platform Security dashboard "Preview and read, not alerted on" (`11` §6); posture is a bespoke 18-check daily drift job (`12` §10); no tier, no org-level activation, no owner | SCC Premium at organisation level, organisation-owned (Enterprise tier deprecated 2026-05-21, shutdown 2027-05-21 — must not be chosen): Event Threat Detection incl. Workspace detectors, Security Health Analytics, AI Protection, Sensitive Actions, Agent Platform Threat Detection (Preview) for non-gateway-bound agents; decide per agent class gateway-with-Model-Armor versus runtime threat detection; enable the Model Armor → SCC finding integration; move IAM-shaped drift checks into Security Health Analytics custom modules owned by the SOC; Audit Manager assessments (ISO 27001:2022, NIST AI 600-1, Google Recommended AI Essentials for Gemini Enterprise Agent Platform) stored in the evidence bucket | HLD |
| MON-07 | monitoring | major | R13 | Joins exist for reconciliation and grading only: Eve joins `walle_audit` to `eve_workspace_logs` (`eve/04` flow 3); Mo joins spans and sanitize logs on `invocation_id`/`trace_id` (`11` §6); T0 chat runs have no owned `traceparent`; Gemini project audit logs never captured; no log scope or observability scope spans the four projects; `14` C43: Google's log names the robot, never the human | A platform correlation contract every agent's audit row must carry (`invocation_id`, `run_id`, `trace_id`, human `sub` from the Gemini `StreamAssist` Data Access log, Workspace `insertId`/`uniqueQualifier`), exported to the SIEM as UDM fields; one log scope and observability scope over `GEMINI`/`WALLE`/`EVE`/`MO` projects and the org Workspace logs; SIEM entity model and rules joining Workspace admin events by `walle@` to audit rows, alerting on an admin event without a matching audit row (Eve's completeness metric promoted to near-real-time); a committed "one request end to end" investigation query set exercised in the tabletop | HLD → detailed |
| MON-08 | monitoring | major | R13 | Alert JSON "kept in the repository" (`11` §6), SQL "committed in the repo" (`13` §10); `thresholds.yaml` reviewed by ladder owner and a security reviewer (`eve/01`) is the only review rule and covers Eve's thresholds only; no threat-model-row-to-detection map, no per-detection test beyond the injection suite, no false-positive review | A detection catalogue page (id, threat-model row, data source, rule location, severity, runbook, owner, test, last fired, last reviewed); detection-as-code in the SIEM (YARA-L if SecOps) under SOC code-ownership; curated Cloud Threats and Workspace detections enabled; CI test per detection using the seeded-fault and injection fixtures (`eve/05` S3 exit gate); quarterly review aligned with Eve's threshold review; coverage stated against the threat table and a public agent-threat taxonomy (tbd which) | detailed |
| MON-09 | monitoring | major | R13 | Only Eve measures its own pages (`eve.pages`, budget tbd, `eve/06`); Mo's ten metrics concern Wall-E's behaviour, not detection (`mo/03` §7); drill times in `drills/{date}`; detection latency recorded once at build | Platform SOC metrics — MTTD/MTTA per severity, time-to-K0 and time-to-K5 from drills, alert volume and precision per agent and rule, detection coverage, log-pipeline availability, seeded-fault catch rate — targets tbd, monthly; `Assumption:` Mo can produce the Wall-E-scoped ones as a fourth artefact; platform-wide ones belong to the SOC and must not depend on Mo's project | HLD → detailed |
| MON-10 | monitoring | major | R13, R15 | Monthly K0 and rollback drills with a 30-day freshness gate (`05` §8, `eve/05` S5), twelve seeded faults, injection suite, absence tests — all technical, builder-run; none rehearses page → acknowledge → decide → contain → notify or involves IT security, the DPO or a second super admin | Quarterly tabletop (semi-annual once stable) on the playbook scenarios, run by IT security with the Wall-E owner, on-duty super admin, DPO and, where required, employee representatives; outcomes in the locked evidence bucket and decision records; first one before S1 since `05` §7 gates S1 on "controls live first" | detailed |
| MON-11 | monitoring | major | R14, R15 | Pieces exist unmapped: attestation bundles (`eve/04` flow 6), locked evidence bucket, `config_versions`, decision records, drill records, denial-suite results; `06` "Compliance" stops at "the first thing an auditor will ask for"; no page names the article or ISA control an evidence item serves; alert/incident history retention tbd; SIEM 12-month default short of 400 days | An evidence register (evidence, location, retention, owner, producer, serves: AI Act article / ISA control / ISO 27001 control), generated by Audit Manager where possible; monthly export of alert and incident history to the evidence bucket; SIEM retention aligned with the schedule; a named post-market monitoring plan page | detailed |
| MON-12 | monitoring | major | R11 | Three agents, three hand-built monitoring stacks, three org-level sinks (`gcp-projects.md` "Org structure"), three channels, one bespoke drift job each; `PREREQUISITES.md` §10 items 14 and 16 leave telemetry APIs and writer roles unnamed; nothing states what a fourth agent must deploy | A platform-owned Terraform monitoring baseline module required before Agent Registry admission: Data Access audit config, regional log bucket with the scheduled retention, standard absence policy with the organisation channel, telemetry variables with span content off, correlation-contract labels, SCC by inheritance, SIEM feed via the folder-level aggregated sink (replacing per-agent org sinks except Eve's independent copy); baseline drift as a Security Health Analytics custom module; agent classes (classical / autonomous / gateway-bound / Workspace-credentialed) each mapped to a baseline tier so a future AGI agent is a tier, not a new design | HLD → runbook |
| MON-13 | monitoring | minor | R1 | `11` §6: alerts from the sanitize log filter; the Agent Platform Security dashboard is "read, not alerted on"; findings reach no central place | Covered by the SCC step (finding integration); additionally alert on `modelarmor` floor-settings updates since `project-topology.md` §5 makes the folder floor a platform control | detailed |
| MON-14 | monitoring | minor | R13 | `gcloud alpha monitoring channels create` (`eve/07` Phase 5), `gcloud beta monitoring channels list` (`SETUP.md` Phase 16, `mo/07` Mo-7); channels created by hand per project; email to a group as the only concrete target | One Terraform-managed notification channel (PagerDuty or the organisation's webhook) per project from the baseline module; email as secondary; verify the current GA `gcloud` surface at build | runbook |
| MON-15 | monitoring | minor | R15 | `eve/07` "Verified facts" lists Access Transparency among shareable Workspace log types; nothing uses it; Access Approval not mentioned for any project | Confirm Access Transparency is enabled for the tenant and the GCP organisation (edition-dependent, tbd), route entries to the SIEM, enable Access Approval on `WALLE_PROJECT` and `EVE_PROJECT` with the operators group as approvers; record in the platform HLD | HLD → runbook |
| CON-01 | consistency | blocking | R5 | P1/P2 stated as design intent in `wall-e/README.md` l.16, `01` design intent 1 and RB node, `02` §"Admin rights" and §"Two role assignments", `05` §7 S0/S1/S5 controls, `06` N1/N2 and threat row, `07` Phase 1 steps 5–6, `ARCHITECTURE.md` §1, §2.1, §3, §4.2, §4.5, §8.5, §10, `SETUP.md` §0.1, §0.2 callout, Phase 2, Phase 3, §6.1, §7.1, `PREREQUISITES.md` §3.2, `setup/README.md`, `walle_setup.py` (`READ_PRIVILEGE_ALLOWLIST`, `ROLE_READER_NAME`, `phase_2_roles`, `check_robot_hardening` `isAdmin` → FAIL, two-robot 2SV check, manual step "Confirm ROBOT is NOT a super admin"); decisions 26, 27, 28, 29 and `14` verdict reason 4 rest on it — full sentence-level inventory in `consistency.md` Gap 1 | Platform HLD rewrites the identity chapter around a super-admin user account whose only containment is the action service plus Workspace-side detection; then rewrite every line in the Gap 1 table, keep the Workspace privilege facts as footnotes, close decision 26 for Wall-E (survives as Eve's E-16), and retarget the script checks | agent sets → runbook |
| CON-02 | consistency | blocking | R4 | `01` design intent 3 and boundary 4; `03` catalogue (20 rows, "Nothing executes that is not registered") and protected-principal rule; `05` §4/§5 families and ceilings; `06` N1–N9 and "Never in the catalogue"; `ARCHITECTURE.md` §1 and §10 excluded table; decision 27, decision 4; `14` C1/C21/C22/C35 and the residual "the limit is the identity, not the design"; `mo/05` privilege-pruning query | HLD decides the mechanism (typed catalogue that grows, generic executor behind the policy chain, or handoff lane) and, per never-list row, whether it moves from catalogue exclusion to a ladder ceiling (L3 on chat, never autonomous); until then the lines are qualified with a dated pointer, not rewritten; decision 27 rewritten as how, not whether | HLD → agent sets |
| CON-03 | consistency | major | R8, R9 | `eve/README` "Not an agent / Not a model", `eve/01` thesis, "the word judgement does not appear", structural choices 3–4, deterministic boundary, `eve-advisor` row "Never, on current evidence"; `eve/03` l.12; `eve/04` "No flow passes through a model"; `eve/06` "Eve has no judgement, it has thresholds"; `eve/08` CC-10; `eve/09` E-7 and settled rows; `wall-e/09` decision 34; `14` C12 and "An LLM Eve — Rejected"; `agents.md` "Eve is not an agent"; `08` item 5 ("halting, on its own judgement") is the one sentence that matches the objective and Eve's set voids it; `12` §1.8 and `13` §4.3 already anticipate a reasoning layer with no authority | Keep the deterministic signing/halting core; HLD decides whether the `eve-advisor` slot (fifth project, no signer, no invoker, one-directional) is built as the reporting layer; rewrite only "Never", "void" and "Eve has no judgement" (narrow to the authority path); qualify the rest with a dated pointer to that decision | HLD → agent sets |
| CON-04 | consistency | major | R10 | `08` responsibilities table and "What Mo must do" items 1–6 Wall-E only; `mo/README`, `mo/01` "What Mo reads", `mo/02` §2.1 grants (two Wall-E datasets), `mo/03` §7 (only `agg_eve_latency`), `mo/04` §3.2 allowlist (no `eve/config`) and §3.5 types, `mo/07` Mo-2, `mo/08` M-11 and the nineteen changes; `eve/01` l.133 "nothing in `MO_PROJECT` reaches Eve", `eve/07` "no `userByEmail` entry for `mo-metrics@` on `eve` — ever"; `project-topology.md` §3 rows 18–24; `agents.md` Mo row | HLD defines Mo's Eve metrics (false-refusal bound, seeded-fault catch, disagreement rate) and the Eve tables Mo reads (findings, verdicts, attestations; never `grades_blind`); one topology §3 row; widen the path allowlist to `eve/config/thresholds.yaml` and `seeded_faults`; add proposal types and Mo change 20; re-assert that Eve reads nothing Mo writes and Mo is never Eve's grader | HLD → agent sets |
| CON-05 | consistency | major | R11 | `overview.md` "First build — Wall-E (+ Eve, Mo)" and empty Architecture/Constraints; `agents.md` and `gcp-projects.md` "four projects"; `gemini-enterprise.md` skeleton with no security section; `project-topology.md` title/status "the three agents", §1.4 four budgets, decision 52; `wall-e/README.md` title and "first of three agents"; `ARCHITECTURE.md` §0 "Eve and Mo do not exist. They have no design and no date" (stale since 2026-09-12); `08` "designed separately, after this"; chapters 11–13 filed as Wall-E's though `13`'s position paragraph already names unknown future agents | Promote chapters 11, 12, 13 and `project-topology.md` into the platform HLD as templates (per-agent project, owner group, budget, identity, gateway, registry ownership); rewrite `overview.md`, `gemini-enterprise.md`, `ARCHITECTURE.md` §0 and the `08` sequencing sentences; qualify the counts of four with "pattern, not count" | HLD → agent sets |
| CON-06 | consistency | minor | R16 | All Status blocks say design/nothing built with no objective line; `ARCHITECTURE.md` §0 and `mo/README.md` l.146–148 are factually stale | One dated line ("Objective restated 2026-09-13; see the platform HLD") on every page this inventory edits, none on untouched pages; rewrite the two stale sentences | agent sets |
| CON-07 | consistency | major | R16 | Untouched decisions: 1, 2, 6, 7, 9, 12–17, 20–25, 30–33, 35, 36, 38, 40–51; E-1..E-5, E-8..E-12, E-14, E-15, E-17, E-18, E-20; M-1..M-3, M-5..M-7, M-9, M-10. Affected: 3, 4, 5, 8, 10, 11, 18, 19, 26 (closed for Wall-E), 27 (rewrite), 28, 29, 34, 37, 39, 52; E-6, E-7, E-13, E-16, E-19 and two settled rows; M-4, M-8, M-11 (add read (d)) and the nineteen-changes list | Qualify each affected row with a dated line and the superseding HLD section; rewrite only 26 and 27 in Wall-E's set; add M-11 (d) and Mo change 20 | agent sets |
| CON-08 | consistency | major | R14, R15 | Zero occurrences of "AI Act", "TISAX", "ISO 27001", "42001", "NIS2" across the 70 pages; compliance text lives only in `06` Compliance, `ARCHITECTURE.md` §9/§11, decision 8, `PREREQUISITES.md` D7/§9, `mo/08` M-3, `overview.md` Constraints (empty) | Rewrite those seven places to name both regimes and point at the platform compliance chapter; owned by the EU AI Act and TISAX lenses; no other page contradicts them | agent sets |

Counts: 111 gaps — 24 blocking, 63 major, 24 minor. By lens: platform-security 17, walle-super-admin 12, eve-independence 11, mo-both-agents 8, scale-and-agi 11, eu-ai-act 13, tisax 16, monitoring 15, consistency 8.

### 4.1 Where the blocking and major gaps are answered

A trace kept beside the register, not a finding of this review. Each row is a blocking or major
gap above that no page 02–11 cites by id, plus the monitoring gaps MON-06 to MON-11 that page
07's Status cites, kept here for their owner and gate. It gives the section that answers the gap
— the detailed page first where one owns the answer, then the HLD section that summarises it —
and, where the answer is an agent-set edit, the owner and gate the propagation stage carries
([12-open-decisions.md](12-open-decisions.md) P143). Every other gap cited by id on pages 02–11
is traced on the citing page; the gaps whose substance the HLD answers without citing them are
listed in
[01-hld.md §0.6](01-hld.md#06-traceability-the-objectives-sixteen-requirements-and-the-register-ids-not-cited-elsewhere).

| Gap | Severity | Answered in | Owner of what remains | Gate |
|---|---|---|---|---|
| WSA-01 | blocking | HLD §13.1; P33 (decided) and its decision file | agent owner (Wall-E), §18 items 1, 5, 7 (P143) | the super-admin grant |
| WSA-02 | blocking | HLD §13.1, §7; [04](04-identity-and-privileged-access.md) §8.5 (two-person rule) | agent owner (Wall-E), §18 items 1, 4 (P143) | the super-admin grant |
| WSA-03 | blocking | HLD §13.1 (bands A/B/C); [10](10-eu-ai-act.md) §3.1 (P125) | agent owner (Wall-E), §18 item 2 (P143) | the super-admin grant |
| WSA-04 | blocking | HLD §13.1 compensation 2; P29 (two lists, open — owner signs) | agent owner (Wall-E), §18 item 2; owner signature P29 | the super-admin grant |
| WSA-05 | major | HLD §13.1 compensation 3; [02](02-landing-zone-and-tiers.md) PSA3; [09](09-supply-chain-secrets-recovery.md) §2.4 class D | agent owner (Wall-E), §18 item 1 (P143) | the super-admin grant |
| WSA-06 | major | HLD §13.1 compensation 6; [04](04-identity-and-privileged-access.md) §8.1–§8.2 (roster, session controls); [02](02-landing-zone-and-tiers.md) P2 | agent owner (Wall-E), §18 item 1 (P143) | the super-admin grant |
| WSA-07 | major | HLD §13.1; [07](07-monitoring-detection-incident-response.md) §6.2, RB-02 | agent owner (Wall-E), §18 items 4, 5; topology §1.2 via item 25 | the super-admin grant |
| WSA-08 | major | HLD §13.1 compensation 5; [04](04-identity-and-privileged-access.md) §8.1 (roster); Eve's verifier rows | Eve owner, §18 item 12 (P143) | the super-admin grant |
| WSA-09 | major | HLD §13.1 | agent owner (Wall-E), §18 item 2 (P143) | the super-admin grant |
| WSA-10 | major | HLD §12; [02](02-landing-zone-and-tiers.md) PSA5 | agent owner (Wall-E), §18 item 3 (P143) | the super-admin grant |
| EVE-01 | blocking | HLD §13.2; P14 (witness organisation); [08](08-data-logging-retention-sovereignty.md) DL-7.6; [07](07-monitoring-detection-incident-response.md) §7 | Eve owner, §18 item 11 (P143); IT security for P14 | the super-admin grant |
| EVE-02 | blocking | [08](08-data-logging-retention-sovereignty.md) §3, §5.3 (P104); [07](07-monitoring-detection-incident-response.md) §1.1 F2 (edition-conditional) | Eve owner, §18 item 13 (P143) | the super-admin grant |
| EVE-03 | blocking | [07](07-monitoring-detection-incident-response.md) §6 (P96) | Eve owner, §18 item 14 (P143); IT security owns rule content | the super-admin grant |
| EVE-04 | major | HLD §13.2; P34; [10](10-eu-ai-act.md) §3.2–§3.3 | Eve owner, §18 item 11 (P143) | the super-admin grant |
| EVE-05 | major | [07](07-monitoring-detection-incident-response.md) §8 (P98) | Eve owner, §18 item 15 (P143) | the super-admin grant |
| EVE-06 | major | HLD §0.3; [07](07-monitoring-detection-incident-response.md) §8 (P98) | Eve owner (P143); ISMS names the recipient | the super-admin grant |
| EVE-07 | major | HLD §13.1 compensation 7; [04](04-identity-and-privileged-access.md) §7.2, §8 | agent owner (Wall-E) and Eve owner (P143) | the super-admin grant |
| EVE-08 | major | HLD §13.2 | Eve owner, §18 item 16 (P143) | the super-admin grant |
| EVE-09 | major | HLD §13.2 | Eve owner, §18 item 16 (P143) | the super-admin grant |
| MO-01 | blocking | HLD §13.3 | Mo owner and agent owner (Wall-E), §18 item 6 (P143) | Wall-E's Stage 1 |
| MO-02 | major | HLD §13.2–§13.3; P30 | Mo owner, §18 item 21 (P143) | Wall-E's Stage 1 |
| MO-03 | major | HLD §13.3; P30 | Mo owner, §18 items 19–20; Eve owner for the grant (P143) | Wall-E's Stage 1 |
| MO-04 | major | HLD §13.3 | Mo owner, §18 item 22 (P143) | Wall-E's Stage 1 |
| MO-05 | major | HLD §12, §13.3; [10](10-eu-ai-act.md) §4.4 | Mo owner, §18 items 19, 21 (P143) | Wall-E's Stage 1 |
| AIA-06 | major | [10](10-eu-ai-act.md) §4.7 (P128) | agent owner per agent; AI compliance owner | Wall-E's Stage 1 |
| AIA-07 | major | [10](10-eu-ai-act.md) §4.10 (P129) | HR/communications, DPO, legal | Wall-E's Stage 1 |
| AIA-09 | major | [10](10-eu-ai-act.md) §4.2 | agent owner; security reviewer signs | Wall-E's Stage 1 |
| TIS-10 | major | [11](11-tisax.md) §3 (P134) | ISMS; DPO | the TISAX assessment order |
| MON-06 | major | [07](07-monitoring-detection-incident-response.md) §3 (P94); summarised in HLD §7.1 | organisation IT security | Tier C |
| MON-07 | major | [07](07-monitoring-detection-incident-response.md) §5 | platform owner | Tier R |
| MON-08 | major | [07](07-monitoring-detection-incident-response.md) §6 (P96) | IT security (rule content); platform owner | Tier W |
| MON-09 | major | [07](07-monitoring-detection-incident-response.md) §14 (P103) | detection desk; platform owner | Tier W |
| MON-10 | major | [07](07-monitoring-detection-incident-response.md) §13 (P102) | IT security | the super-admin grant |
| MON-11 | major | [10](10-eu-ai-act.md) §5; [08](08-data-logging-retention-sovereignty.md) §5.5; summarised in HLD §7.5, §14.3 | AI compliance owner; platform owner | Tier W |
| CON-01 | blocking | HLD §13.1; [04](04-identity-and-privileged-access.md) §8 | agent owner (Wall-E), §18 item 1 (P143) | the super-admin grant |
| CON-02 | blocking | HLD §13.1 (bands); P125 | agent owner (Wall-E), §18 item 2 (P143) | the super-admin grant |
| CON-03 | major | HLD §13.2; P34; P19 | Eve owner, §18 item 11 (P143); legal for P19 | the `eve-advisor` build |
| CON-04 | major | HLD §13.3; P30 | Mo owner, §18 item 21 (P143) | Wall-E's Stage 1 |
| CON-05 | major | [02](02-landing-zone-and-tiers.md) §8 (P47); [04](04-identity-and-privileged-access.md), [06](06-gateways-model-armor-perimeter.md) §5 | platform owner, §18 items 8, 25 (P143) | the documentation reconciliation before the S1 tag (P47, P130) |
| CON-07 | major | [12](12-open-decisions.md) §8; HLD §18 | the three agent owners (P143) | Wall-E's Stage 1 |
| CON-08 | major | HLD §14 (both regimes named); [10](10-eu-ai-act.md) §8 (the agent-set places still to change) | AI compliance owner; agent owners, §18 items 5, 12 (P143) | Wall-E's Stage 1 |

---

## 5. What the platform HLD must decide

The nine lenses' `hld_must_decide` lists, consolidated and deduplicated into 82 questions. Each
question's options and the lenses' recommendations are the fixes in the §4 rows it cites; the
answers are the register rows of [12-open-decisions.md](12-open-decisions.md) (one screen in
[§0](12-open-decisions.md#0-the-register-in-one-screen)), argued on the page each row names.

### A. Platform shape

| Item | Question | Gaps | Answered by |
|---|---|---|---|
| 1 | Which tier model? | SCA-07, PS-17, MON-12 | P1, P43; HLD §0.4, §11 |
| 2 | What is the landing zone? | PS-01, SCA-02 | P2 (closed by P35), P35–P40 |
| 3 | What lives in `platform-core` and what stays per agent? | SCA-03, PS-16 | P45; the shared IAP approval surface refused by P46 |
| 4 | Registry topology and the inventory of record | PS-03, SCA-04, TIS-05, AIA-10 | P71–P75 |
| 5 | Which organisation policies at the folder, and which custom constraints are enforceable? | PS-05, SCA-05 | P4, P41, P42, P44 |
| 6 | What the Gemini Enterprise security baseline page carries | PS-04, PS-06, SCA-03 | P6, P48–P59 |
| 7 | The platform autonomy contract | SCA-06, MO-05 | P76, P77, P79 |
| 8 | The fleet-wide peer rule | SCA-09 | P78 |
| 9 | Which of chapters 11, 12 and 13 are promoted, and what `project-topology.md` becomes | CON-05, SCA-01 | P47 |

### B. Wall-E as a super admin

| Item | Question | Gaps | Answered by |
|---|---|---|---|
| 10 | Which super-admin actions may Wall-E reach at all? | WSA-04, CON-02 | P29, P33 |
| 11 | What does "any super-admin action" mean mechanically? | WSA-03, CON-02 | P28, P125; HLD §13.1 (bands A/B/C) |
| 12 | One credential or two? | WSA-05 | HLD §13.1 item 3 |
| 13 | The requester rule for the super-admin lane | WSA-09 | HLD §13.1 item 4 |
| 14 | May any super-admin-class operation ever be autonomous? | WSA-10 | HLD §13.1 item 9; P77 |
| 15 | What replaces the lost Workspace-side gate? | WSA-02, WSA-08, MON-02, CON-01 | HLD §13.1 items 5 and 10; P96 |
| 16 | The robot's place on the super-admin roster | WSA-06, WSA-11 | P66, P68, P69; HLD §13.1 items 6–7 (self-recovery set Off at the top OU) |
| 17 | Acceptance of the new residual | WSA-07, TIS-02, MON-02 | P33, P136, P140 |
| 18 | Decision 26's fate | WSA-01, CON-07 | P33 (E-16 stays open for Eve) |
| 19 | Is the catalogue the declared intended purpose (EU AI Act)? | AIA-02 | P28, P125 |

### C. Eve

| Item | Question | Gaps | Answered by |
|---|---|---|---|
| 20 | Where does Eve's trust root sit? | EVE-01 | P14, P15; HLD §13.2 |
| 21 | Is Eve split into a deterministic control path and a model-permitted reporting path? | EVE-04, CON-03 | P34, P19, P123 |
| 22 | Eve's evidence perimeter | EVE-02 | P17, P104; HLD §13.2 |
| 23 | The detection catalogue | EVE-03, MO-02 | P96, P21 |
| 24 | The reporting contract | EVE-05 | P98, P99, P100 |
| 25 | A second human outside the Wall-E administration line | EVE-06, TIS-03 | P98, P137; HLD §13.2 |
| 26 | The break-glass path to stop the account (K5) | EVE-07, MON-03 | P16, P7; HLD §13.1 item 7 |
| 27 | The staging re-cut | EVE-09 | P136; HLD §13.2; [11](11-tisax.md) §6.3 |
| 28 | Eve's complete Workspace read privilege and scope set | EVE-08 | [../eve/02-identity-and-auth.md "Eve's Workspace robot"](../eve/02-identity-and-auth.md#eves-workspace-robot); [../eve/03-lld.md §13](../eve/03-lld.md#13-the-evidence-perimeter-for-a-super-admin-wall-e); E-16 (register §8) |
| 29 | Eve's model-free property on the authority path as a compliance invariant | AIA-11 | P132; [10](10-eu-ai-act.md) §3.2 |

### D. Mo

| Item | Question | Gaps | Answered by |
|---|---|---|---|
| 30 | Does Mo's remit formally include Eve? | MO-01, MO-07, CON-04 | HLD §13.3; P143 |
| 31 | Which Eve tables Mo reads, in which dataset, from which stage | MO-01, CON-04 | P30; HLD §13.3 |
| 32 | Where human grades live | MO-02 | [../mo/03-metrics-contract.md §7.3](../mo/03-metrics-contract.md#73-the-eve-quality-pack); `grades_eve` in [../eve/03-lld.md §8](../eve/03-lld.md#8-the-data-plane); HLD §13.3 |
| 33 | Who computes Eve's quality metrics | MO-02 | HLD §13.3 |
| 34 | Does the validator custodian get `READER` on Eve's quality dataset? | MO-03 | P30 |
| 35 | The closed Eve proposal type set and Eve path allowlist | MO-04, EVE-11 | HLD §13.3 |
| 36 | New Eve tables | MO-02 | [../eve/03-lld.md §8–§9](../eve/03-lld.md#8-the-data-plane) (`eve_quality`, `grades_eve`, `seeded_fault_runs`); [../mo/03-metrics-contract.md §7.3](../mo/03-metrics-contract.md#73-the-eve-quality-pack) |
| 37 | Does the metrics contract become a platform schema keyed on `agent_id`, with one Mo per platform? | MO-05, SCA-08 | P25; HLD §12, §13.3 |
| 38 | The per-tier human cost of measurement, and the Art. 72 plan as a Mo artefact | MO-05, MON-11 | P25; [10](10-eu-ai-act.md) §4.4 |
| 39 | Do Eve v0 and Mo's T0 both survive as a differential check? | MO-06 | [../mo/01-hld.md "Components"](../mo/01-hld.md#components) (T0 row, `metric_divergence`); [../mo/03-metrics-contract.md §6](../mo/03-metrics-contract.md#6-assertion-queries) A11 and [§7.3](../mo/03-metrics-contract.md#73-the-eve-quality-pack) |
| 40 | Whether Mo produces Wall-E-scoped SOC metrics, and who produces the platform-wide ones | MON-09 | P103 |

### E. Gateway, Model Armor, perimeter

| Item | Question | Gaps | Answered by |
|---|---|---|---|
| 41 | The gateway rule | PS-06, SCA-05, MON-06 | P81, P82, P83 |
| 42 | Model Armor floors and templates | PS-07 | P84–P87 |
| 43 | The perimeter model for the agents folder | PS-09, SCA-11, TIS-15 | P3, P89, P90, P91 |

### F. Monitoring, SIEM, SCC, incident response

| Item | Question | Gaps | Answered by |
|---|---|---|---|
| 44 | Which SIEM? | MON-01, PS-08 | P10, P92, P74; the instance region superseded by P93 |
| 45 | SCC Premium at organisation level | MON-06, PS-08 | P11, P94 |
| 46 | The super-admin detection set | MON-02 | P96, P97; SOC ownership superseded by P99 |
| 47 | Incident response | MON-03, TIS-09, AIA-08 | P99, P100, P101, P102 |
| 48 | The correlation contract | MON-07 | P100; [07](07-monitoring-detection-incident-response.md) §5 |
| 49 | The mandatory monitoring baseline module and the detection catalogue | MON-12, MON-08 | P95, P96, P21 |
| 50 | Tabletop cadence and participants | MON-10 | P102 |
| 51 | The evidence register and post-market monitoring plan as named pages | MON-11, AIA-05 | P130; [10](10-eu-ai-act.md) §4.4, §5 |

### G. Logging, retention, data

| Item | Question | Gaps | Answered by |
|---|---|---|---|
| 52 | The retention schedule per store | MON-04, TIS-06, AIA-04 | P13, P106, P107 |
| 53 | Organisation- or folder-level Data Access audit logging | MON-05, TIS-06, PS-16 | P105, P80 |
| 54 | A central logging project | PS-16, SCA-03 | P104 (two aggregated sinks, not one), P114 |
| 55 | Sensitive Data Protection discovery | PS-12 | P108 |
| 56 | Data classification of every platform store | TIS-05 | P109 |
| 57 | Assured Workloads EU Data Boundary for the agents folder — yes or no? | PS-13, MON-15 | P110, P12; Access Approval scope in P111 |

### H. Supply chain, secrets, backup, privileged and human access

| Item | Question | Gaps | Answered by |
|---|---|---|---|
| 58 | Supply chain | PS-10, TIS-07 | P115 (continuous validation is GKE-only), P116, P117, P22, P40 |
| 59 | Secrets and keys conventions | PS-11, TIS-13 | P112, P118, P119 |
| 60 | Privileged Access Manager entitlements | PS-14 | P62 (`roles/owner` cannot be a PAM entitlement, [04](04-identity-and-privileged-access.md) §5.1), P49 |
| 61 | Recovery classes per tier | PS-15, TIS-08 | P120; [09](09-supply-chain-secrets-recovery.md) §3 |
| 62 | Human access | PS-17 | P63, P64, P24, P65 |
| 63 | A fleet kill switch outside any agent project | SCA-09, PS-02 | P60, P61 and P8 (principal-set form, [04](04-identity-and-privileged-access.md) §2.1), P9, P67, P70 |
| 64 | The code-execution tier | SCA-09 | P27, P121, P122 (GKE Agent Sandbox GA) |
| 65 | What the platform does not claim | SCA-09 | P123, P124; HLD §16 |

### I. Compliance

| Item | Question | Gaps | Answered by |
|---|---|---|---|
| 66 | Wall-E's Art. 6 classification | AIA-01, AIA-02 | P28, P125, P75 |
| 67 | Is inactivity-based licence reclaim (F7) profiling of natural persons? | AIA-01 | P18, P126 |
| 68 | Which legal entity is provider and deployer | AIA-01 | P23 |
| 69 | The per-family maximum autonomy level compatible with Art. 14, overseers and literacy | AIA-03, AIA-12, TIS-14 | P127, P131 |
| 70 | Art. 50 disclosure | AIA-06 | P128 |
| 71 | Timing of worker information and consultation, and the Art. 86 path | AIA-07 | P129 |
| 72 | A one-line GPAI policy | AIA-10 | P132; [10](10-eu-ai-act.md) §3.5 |
| 73 | When the documentation is reconciled and frozen per stage | AIA-05, CON-06 | P130, P47 |
| 74 | The TISAX target | TIS-01 | P20, P133 |
| 75 | Data Protection module scope | TIS-01, TIS-10 | P134 |
| 76 | A platform RACI with minimum staffing and separation of duties | TIS-03, EVE-06 | P137, P131; HLD §0.3 |
| 77 | The shared-responsibility split with Google and the supplier file | TIS-04 | P135, P32 |
| 78 | The supplier onboarding rule and exit procedure | TIS-04 | P138 |
| 79 | Penetration test, internal audit, management review, risk register | TIS-12, TIS-11 | P139, P140 |
| 80 | The legal and contractual register | TIS-16 | P141 |
| 81 | DPIA, records of processing, data-subject requests, employee notice, works council | TIS-10, AIA-07 | P129, P141; [08](08-data-logging-retention-sovereignty.md) §5.1 |
| 82 | Where EU AI Act classification and TISAX scope are recorded | CON-08, SCA-04 | P75, P38 |

---

## 6. Compliance frames

### 6.1 EU AI Act

The EU AI Act frame the review drew from the `eu-ai-act.md` lens file (regulatory state on
2026-09-13, classification, applicable obligations, and where "bulletproof" can and cannot be
promised) is carried by [10-eu-ai-act.md](10-eu-ai-act.md):
[§1](10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13),
[§3](10-eu-ai-act.md#3-classification-per-system),
[§4](10-eu-ai-act.md#4-obligation-crosswalk--every-obligation-its-owner-its-evidence-its-mechanism)
and [§6](10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean). What the review concluded on
2026-09-13 is kept below as its finding.

**Applicable obligations.** Biting on 2026-09-13: Art. 4, Art. 5 and Art. 50; from 2027-12-02, if
high-risk, Art. 9–15, Art. 17, Art. 43/47/48, Art. 49, Art. 72, Art. 73 and the deployer duties of
Art. 26 (the obligation-by-obligation list is 10 §4). The review's verdict: the engineering
substance often exceeds what Art. 9–15 ask (the ladder as oversight, the write-ahead audit at 400
days, the independent verifier, the adversarial reviews, Mo as a de facto Art. 72 loop); the legal
layer is entirely absent.

**Where "bulletproof" can and cannot be promised.** It can be promised that the documentation
set, once reconciled and organised as Annex IV, exceeds the Act's engineering expectations for
the pilot. It cannot be promised on 2026-09-13 that (1) an Art. 6(3) claim survives guidelines
that are still draft; (2) any presumption of conformity exists, since no harmonised standard is
published; (3) an authority will read licence reclaim by inactivity as anything other than
monitoring of workers before enforcement practice exists; (4) the Super Admin grant will not be
held against the narrow-task reading unless the catalogue is declared as the intended purpose
and the never-list is enforced in code and shown in the logs; (5) oversight above L3 rests on a
natural person, since Eve is not one; (6) Art. 11 documentation matches the system while the
sets carry unapplied edits; (7) "hundreds of agents" is covered without a publication gate that
requires a classification per agent.

### 6.2 TISAX

The TISAX frame the review drew from the `tisax.md` lens file (catalogue state on 2026-09-13,
classification, applicable controls, and where "compatible" can and cannot be promised) is
carried by [11-tisax.md](11-tisax.md): [§1](11-tisax.md#1-tisax-on-2026-09-13-verified),
[§2](11-tisax.md#2-the-target--label-level-scope-catalogue-p133) and
[§5](11-tisax.md#5-control-by-control-mapping). What the review concluded on 2026-09-13 is kept
below as its finding.

**Applicable controls and where the platform stands.** Strong on 2026-09-13, at maturity 3 or
better once built: 5.2.4 administrator-activity logging, 4.1–4.2 keyless identity and enumerated
least-privilege grants, 5.2.1/5.3.1 change control with the gate separated from what it gates,
5.1 cryptographic proof of approval, 5.2.6 technical self-audit; and the habit of arguing every
rejected alternative in place already meets ISA2027's rule that "aspects considered" need a
written rationale. Absent or in *tbd* skeletons: 1.1.1 policies by reference, 1.2.2 roles and
separation of duties, 1.2.4 shared responsibility with Google, 1.3.1/1.3.2 asset register and
classification, 1.3.3/6.1.1 approved external services and suppliers, 1.4.1 risk register,
1.6.x incident process and crisis scenario, 5.2.2 pre-production, 5.2.5 vulnerability
management, 5.2.8/5.2.9 continuity and backup with a restore test, 7.1.1 legal register,
7.1.2 DPIA. The super-admin robot turns 4.2.1 least privilege into an accepted deviation carried
entirely by the catalogue, the ladder, Eve and a split control plane.

**Where "compatible" can and cannot be promised.** Roughly half is documentation the platform
can write now: the target and scope statement, the control-to-ISA mapping, the
shared-responsibility matrix and supplier file, the asset and agent register, the risk register,
the cryptography statement, the continuity statement, the incident page, the legal register, the
RACI, the training outline, the first decision files. The other half is controls that do not
exist yet and cannot be promised by a document: a second person in every load-bearing role;
compensating controls strong enough to carry a super-admin robot; an agent register enforced by
CI; Data Access audit logs, retention decided and enforced, a SIEM feed; a pre-production
environment, image scanning, pinned dependencies; Firestore backups and a restore exercise; a
staffed incident channel with an acknowledgement SLA for Eve's reports; DPIA, records of
processing, a data-subject-request path; a penetration test; a supplier onboarding and exit
procedure. Nothing is architecturally wrong; it is unfinished at the layer an assessor reads
first, and separation of duties (1.2.2) is the item most likely to stop an assessment.

---

## 7. What does not change

Pages and sections the consistency lens cleared as consistent with the objective as written.
Later stages should not touch them.

| Page | Why it stands |
|---|---|
| [wall-e/04-flows.md](../wall-e/04-flows.md) | Flows A–G describe the action-service path, approvals, Eve gating, injection, halting; none names the role or the catalogue breadth. Flow A's protected-principal branch inherits the band decision but needs no edit until it lands. |
| [wall-e/03-lld.md](../wall-e/03-lld.md) except the operation catalogue and protected-principals sections | Interface, autonomy config, taint bit, fail-closed control plane, playbooks, policy engine order, storage, denial reasons, error handling, the agent, the model — all hold. |
| [wall-e/10-adversarial-review.md](../wall-e/10-adversarial-review.md) | A dated record; one pointer line at the top at most. |
| [wall-e/11-prompt-security.md](../wall-e/11-prompt-security.md) | No screen, threshold or control depends on the role; only the framing note (platform chapter seeded here). |
| [wall-e/12-agent-identity.md](../wall-e/12-agent-identity.md) §1.1–1.7, §2–§11 | Platform-grade already; §1.8 anticipates a reasoning Eve without authority. |
| [wall-e/13-agent-interconnection.md](../wall-e/13-agent-interconnection.md) §1–§12 | Platform-grade already; the position paragraph already names "agents this design has never heard of". |
| [wall-e/05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §1 (eight rules), §2 (levels), §3 (trigger classes), §6 (who raises/lowers), §8 (metrics), §9 (severity), §10 (recording a promotion) | Autonomy stays per (family, trigger); nothing in the objective touches the ladder's shape. |
| [wall-e/06-security-guardrails.md](../wall-e/06-security-guardrails.md) "What prompt-based defence cannot do", "Forbidden configurations", "Monitoring" | Hold as written; Monitoring gains rows from the monitoring lens, not from consistency. |
| [wall-e/08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) "The separation that makes a team worth having" (three rules), Identities table, Interfaces table (eight endpoints), "Failure modes of the team itself" | The contract's structure holds; only the Mo duties and item 5 change. |
| [eve/02-identity-and-auth.md](../eve/02-identity-and-auth.md) (all but the Mo grant row), [eve/03-lld.md](../eve/03-lld.md) (all but line 12), [eve/04-flows.md](../eve/04-flows.md) (all but the two judgement lines), [eve/05-stages.md](../eve/05-stages.md), [eve/06-failure-modes.md](../eve/06-failure-modes.md) (all but line 21), [eve/07-build-runbook.md](../eve/07-build-runbook.md) (all but the Mo-on-`eve` checks), [eve/08-contract-changes.md](../eve/08-contract-changes.md) | Eve's design is the objective's Eve: independent, no super admin, own credential, own project, halts and reports. The deterministic core is not overturned. (The eve-independence lens adds to these pages; it does not overturn them.) |
| [mo/03-metrics-contract.md](../mo/03-metrics-contract.md) §1–§6, §8–§17; [mo/04-artefacts-and-proposals.md](../mo/04-artefacts-and-proposals.md) §1, §2, §3.1, §3.3, §3.4, §4–§8; [mo/05-staging.md](../mo/05-staging.md) (all but the S5 pruning text); [mo/06-failure-modes.md](../mo/06-failure-modes.md); [mo/07-build-runbook.md](../mo/07-build-runbook.md) (all but the new Eve read) | The recompute property, the drop box, the validator, the seed protocol and the blind sample are untouched. |
| [project-topology.md](../project-topology.md) §2 (the four projects' contents), §3 (26 grant rows), §4, §5, §6, §7, §9 | Placement is unchanged; only §1 wording, §8 decision 52 and one new §3 row. |
| [google-workspace.md](../google-workspace.md) | Skeleton; nothing asserted. |
| `wall-e/setup/walle.env.example`, `wall-e/setup/walle`, `requirements.txt`, `selftest/selftest.sh` | No key or assertion names the role model (verified by grep). |
| Decision records 1, 2, 6, 7, 9, 12–17, 20–25, 30–33, 35, 36, 38, 40–51; E-1..E-5, E-8..E-12, E-14, E-15, E-17, E-18, E-20; M-1..M-3, M-5..M-7, M-9, M-10 | Untouched by the objective. |
| Standing constraints everywhere: no DWD; the LLM holds no credential; the action service is the only credential holder; humans raise, machines lower; no secrets in the wiki | Unchanged and, for Eve, now required by the objective. |

---

## 8. Sources

URLs the nine lenses cited, read on 2026-09-13, deduplicated and grouped. Facts drawn from them
are stated in the lens files; anything not cited there is marked `Assumption:` or *tbd*.

**Google Workspace administration and identity**
- https://knowledge.workspace.google.com/admin/users/assign-specific-admin-roles — a service account may hold any role except Super Admin
- https://knowledge.workspace.google.com/admin/users/administrator-privilege-definitions — privileges that cannot be OU-limited; super-admin-only tasks
- https://knowledge.workspace.google.com/admin/security/about-2sv-enforcement-for-admins — Google-set 2SV enforcement on admins
- https://knowledge.workspace.google.com/admin/users/allow-super-administrators-to-recover-their-password — tenant-level super-admin self-recovery
- https://knowledge.workspace.google.com/admin/apps/control-api-access-with-domain-wide-delegation — DWD is Admin console only
- https://developers.google.com/workspace/admin/directory/reference/rest/v1/users/makeAdmin
- https://docs.cloud.google.com/identity/docs/concepts/supported-policy-api-settings — Policy API mutate support
- https://developers.google.com/identity/protocols/oauth2 — refresh-token limits
- https://developers.google.com/workspace/admin/reports/reference/rest/v1/activities/list — Reports API applications
- https://knowledge.workspace.google.com/admin/reports/takeout-log-events
- https://knowledge.workspace.google.com/admin/reports/set-up-service-log-exports-to-bigquery
- https://knowledge.workspace.google.com/admin/reports/export-log-events-to-google-security-operations-to-monitor-insider-risk — native SecOps export
- https://docs.cloud.google.com/resource-manager/docs/super-admin-best-practices — super admins and Organization Administrator
- https://docs.cloud.google.com/resource-manager/docs/creating-managing-organization
- https://docs.cloud.google.com/resource-manager/docs/limits

**Google Cloud security, identity and platform products**
- https://docs.cloud.google.com/iam/docs/agent-identity-overview
- https://docs.cloud.google.com/iam/docs/agent-identity-custom-constraints
- https://docs.cloud.google.com/iam/docs/principal-access-boundary-policies
- https://docs.cloud.google.com/iam/help/deny/supported-permissions (did not render for the lens; verify)
- https://docs.cloud.google.com/iam/docs/pam-overview — Privileged Access Manager
- https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/agent-registry
- https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern
- https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/gateways/agent-gateway-overview
- https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/agent-gateway-runtime-deploy
- https://docs.cloud.google.com/gemini-enterprise-agent-platform/machine-learning/predictions/custom-constraints
- https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes — VPC-SC with Agent Gateway after 2026-09-08
- https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/agent-quotas (did not render; *tbd*)
- https://docs.cloud.google.com/gemini/enterprise/docs/audit-logging — Gemini Enterprise Data Access entries
- https://cloud.google.com/security-command-center/docs/model_armor_floor_settings
- https://docs.cloud.google.com/model-armor/quotas
- https://docs.cloud.google.com/security-command-center/docs/ai-protection-overview
- https://docs.cloud.google.com/security-command-center/docs/agent-platform-threat-detection-overview
- https://docs.cloud.google.com/security-command-center/docs/agent-engine-threat-detection-overview
- https://docs.cloud.google.com/security-command-center/docs/google-workspace-threats
- https://docs.cloud.google.com/security-command-center/docs/concepts-event-threat-detection-overview
- https://docs.cloud.google.com/security-command-center/docs/release-notes — Enterprise tier deprecation; AI Protection GA
- https://cloud.google.com/solutions/security/agentic-soc
- https://docs.cloud.google.com/chronicle/docs/ingestion/default-parsers/collect-workspace-logs
- https://docs.cloud.google.com/chronicle/docs/ingestion/default-parsers/ingest-gcp-logs
- https://docs.cloud.google.com/chronicle/docs/detection/cloud-threats-category
- https://docs.cloud.google.com/chronicle/docs/about/data-retention
- https://cloud.google.com/terms/secops/data-residency
- https://docs.cloud.google.com/logging/docs/audit/gsuite-audit-logging
- https://docs.cloud.google.com/logging/docs/buckets
- https://docs.cloud.google.com/logging/docs/log-scope/create-and-manage
- https://docs.cloud.google.com/monitoring/support/notification-options
- https://docs.cloud.google.com/audit-manager/docs/overview
- https://cloud.google.com/blog/products/identity-security/streamline-auditing-compliance-manager-is-now-in-preview
- https://docs.cloud.google.com/assured-workloads/docs/control-packages/eu-data-boundary
- https://docs.cloud.google.com/assured-workloads/access-transparency/docs/understanding-workspace-logs
- https://docs.cloud.google.com/binary-authorization/docs/overview
- https://docs.cloud.google.com/build/docs/securing-builds/generate-validate-build-provenance
- https://docs.cloud.google.com/firestore/native/docs/backups
- https://docs.cloud.google.com/kubernetes-engine/docs/how-to/agent-sandbox
- https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/fast/stages/2-project-factory/README.md
- https://github.com/terraform-google-modules/terraform-google-org-policy
- https://deepmind.google/blog/strengthening-our-frontier-safety-framework/

**EU AI Act**
- https://artificialintelligenceact.eu/article/113/ ; /article/6/ ; /article/18/ ; /article/19/ ; /annex/3/
- https://digital-strategy.ec.europa.eu/en/news/ai-omnibus-enters-force
- https://digital-strategy.ec.europa.eu/en/policies/regulatory-framework-ai
- https://digital-strategy.ec.europa.eu/en/library/draft-commission-guidelines-classification-high-risk-ai-systems
- https://digital-strategy.ec.europa.eu/en/policies/contents-code-gpai ; https://code-of-practice.ai/
- https://ai-act-service-desk.ec.europa.eu/en/ai-act/article-26 ; https://www.euaiact.com/article/12
- https://labs.cloudsecurityalliance.org/research/csa-research-note-eu-ai-act-high-risk-deadline-omnibus-20260/
- https://www.gibsondunn.com/eu-ai-act-omnibus-agreement-postponed-high-risk-deadlines-and-other-key-changes/
- https://www.lewissilkin.com/insights/2026/07/27/the-digital-omnibus-on-ai-enters-into-force-today-102nedo
- https://www.joneswalker.com/en/insights/blogs/ai-law-blog/yes-august-2-still-matters-the-eu-approved-a-high-risk-ai-delay-but-most-trans.html?id=102nbon
- https://www.dlapiper.com/en/insights/publications/2026/06/eu-commission-draft-guidelines-on-classification-of-high-risk-ai-systems-key-points
- https://lawandtechnology.eu/en/ai-literacy-digital-omnibus-article-4-ai-act/
- https://www.lw.com/en/insights/eu-ai-act-gpai-model-obligations-in-force-and-final-gpai-code-of-practice-in-place

**TISAX / VDA ISA**
- https://enx.com/en-US/TISAX/downloads/ — ISA 6.0.3, ISA2027, redline
- https://enx.com/en-US/news/isa2027/
- https://portal.enx.com/handbook/tisax-participant-handbook.html
- https://enx.com/en-US/news/new-tisax-labels-for-availability/
- https://cloud.google.com/security/compliance/tisax — Google's labels, scope SYN0NK
- https://www.sorinmustaca.com/isa-vda-6-0-3-part-2-information-security-sheet-is-policies-and-organization/ (and parts 3–5)
- https://www.sorinmustaca.com/isa-vda-6-0-3-the-data-protection-sheet-explained
- https://www.itis-secure.com/blog/vda-isa-6-changes-tisax-suppliers
- https://vda-isa-berater.com/en/vda-isa-catalog-6/
- https://www.syngenity.com/en/vda-isa2027-5-key-changes-for-tisax-starting-in-2027/
- https://www.cyberday.ai/requirement/tisax-1-3-3-use-of-approved-external-it-services
- https://www.docusnap.com/en/it-documentation/tisax-label-level
- https://www.docusnap.com/en/it-documentation/tisax-requirements
- https://360dt.de/en/vda-isa-6-the-most-important-changes-in-the-catalog/
