# 08. Glossary

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-18
- What this page is: every technical term, acronym, Google product, tier, kill switch, role and decision-id family used in this set, in alphabetical order, each in one or two everyday sentences, with a link to the page of the full documentation that defines it precisely. Nothing described here is built.

## In one sentence

If a word in pages 01 to 07 or the README stopped you, it is here, said plainly, with the line of the full documentation that says it exactly.

## A

**Action service.** The small, ordinary program that holds an agent's credential, checks a request against the rules, writes the audit record and then acts; the language model never touches the credential ([platform terms](../brief/31-glossary.md#platform-terms); [the third containment primitive](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded)).

**Admin console.** Google's web page on which a human administrator manages the tenant by hand. Some tasks exist only there; Wall-E's band C writes the steps for a human and then watches for the matching event, and no robot ever drives the console itself ([band C](../01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa); [the non-goals](../01-hld.md#16-what-the-platform-does-not-do)).

**Agent.** A program that uses a language model to decide what to do, and may be given tools to act ([what was asked](../brief/02-executive-summary.md#what-was-asked-and-the-readings-the-design-declines-or-qualifies)).

**Agent Gateway, Agent Identity, Agent Runtime.** Three Google products. Agent Runtime is the managed service that runs an agent's code. Agent Gateway is the one door through which an agent talks to the outside: it screens what comes in and lets out only listed destinations. Agent Identity is a keyless, Google-issued identity for an agent that expires daily ([Google products](../brief/31-glossary.md#google-products-and-features); [the gateway rule](../01-hld.md#61-the-gateway-rule); [Agent Identity](../01-hld.md#41-agent-identity-for-every-reasoning-layer)).

**AGI and Tier X.** AGI, artificial general intelligence, means an agent with abilities its designers cannot list: writing and running its own code, setting its own goals. Tier X is the platform's folder for such agents. It exists, is empty, refuses every Google service and stays closed until written conditions hold; the only one met on 2026-09-13 is that Google's sealed-box product, GKE Agent Sandbox, exists in the EU ([the honest line](../01-hld.md#115-the-honest-line); [the non-goals](../01-hld.md#16-what-the-platform-does-not-do)).

**Annex III, and the Article 6(3) derogation.** Annex III is the EU AI Act's list of uses it treats as high risk. Its point 4(b) covers AI used at work for decisions about employment, promotion, termination and monitoring. Wall-E is classed as adjacent to that point, not inside it. The Article 6(3) derogation is the Act's exemption for a system that only performs a narrow procedural task, or carries out a decision a human already took, and does not materially influence that decision. Wall-E claims it; profiling would remove it; the claim is made against guidelines that were still a draft on 2026-09-18 ([Annex III 4(b) family by family](../10-eu-ai-act.md#312-annex-iii-4b-family-by-family); [Wall-E's class](../10-eu-ai-act.md#31-wall-e-wall-e); [what cannot be promised](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean)).

**`Assumption:` and *tbd*.** Two markers used on every page. `Assumption:` means the value was inferred, not stated by its source; every cost figure carries it. *tbd*, to be decided, means nobody has decided yet and the placeholder stays until a real value exists ([platform terms](../brief/31-glossary.md#platform-terms)).

**Audit record, and Google's own admin audit log.** Two different records. Wall-E's audit record is written by its action service *before* every action: who asked, who approved, what will change and on whom; no record, no action, which is why it is called write-ahead. Google's admin audit log is Google's own record of what every administrator did in the tenant, fetched through the Reports API (the interface a program uses to read those reports). Eve compares the two ([the audit schema](../01-hld.md#123-auditschema-and-ladderschema); [Eve's evidence](../01-hld.md#132-eve--independent-controller-two-paths-a-witness-outside-the-tenant-a-second-human); [Google's log facts](../3-day/README.md#9-the-two-decisions-already-made-and-what-they-mean)).

**Autonomy ladder, stages and trigger classes.** Autonomy is how far an agent may go before a human must say yes. The ladder has six levels. L0 is off. L1 is a dry run: the action is planned and recorded but nothing changes, even with a valid approval in hand ([the nine absolutes](../3-day/README.md#2-the-nine-absolutes)). L2 is a proposal: the agent writes what it would do and a human who wants it done does it themselves. L3 is a human approving each action. L4 is Eve approving, with a hold window in which a human may veto. L5 is fully automatic with an independent check ([the six levels](../../wall-e/05-autonomy-ladder.md#2-the-six-levels)). Levels climb on evidence, never on the calendar; humans raise, machines lower. Wall-E's programme runs through six stages, S0 Eyes (read-only, at least 3 to 4 weeks) to S5 Steady state, each a floor and not a plan. Four trigger classes say what starts a run: T0 chat, T1 scheduled, T2 event, T3 inbox ([stage overview](../../wall-e/05-autonomy-ladder.md#stage-overview); [the ladder's rules](../01-hld.md#121-the-ladder--unchanged-rules-platform-defaults)).

## B

**Bands A, B and C, and the catalogue.** Wall-E's three lanes. Band A is the catalogue: a fixed, written list of routine operation types, the only lane that can earn autonomy. Band B is any uncatalogued super-admin request, spelled out in full by one human super admin and approved by a second, permanently one approval per action. Band C is console-only work, handed to a human as written steps ([Wall-E's bands](../01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa)).

**Blind grader and blind sample.** A named human who did not write an agent's routines grades a weekly sample of its work without knowing which items were planted as tests. About an hour a week per writing agent; grading capacity is what caps how many writing agents the platform can carry (P25, open) ([platform terms](../brief/31-glossary.md#platform-terms); [tiers and controls](../01-hld.md#111-tiers-and-mandatory-controls)).

**Bucket and SQL.** A bucket is a storage container in Google Cloud that holds files. SQL is the language used to ask questions of a database; on the platform the database is BigQuery. Mo is a body of committed SQL, one deterministic job and a bucket into which it drops its proposals; a bucket is also where Eve's evidence is kept ([Mo's thesis](../../mo/01-hld.md#thesis); [Eve's evidence](../01-hld.md#132-eve--independent-controller-two-paths-a-witness-outside-the-tenant-a-second-human)).

## C

**Chrome Enterprise Premium.** Google's paid browser-security licence, one per operator and approver, which checks that the device an operator works from is in a known state; unpriced, procurement obtains the price (P63) ([cost classes](../01-hld.md#05-cost-classes); [the purchase table](../setup/04-purchases-and-lead-times.md#1-the-purchase-table-longest-lead-time-first)).

**Compensations, the thirteen.** The thirteen conditions that must all be true before the robot receives Super Admin, none deferred: three bands, the two signed lists, two credentials in two services, the band-B requester rule, detection as the primary control, account hygiene, kill switches K0 to K7, the perimeter, a permanent ceiling, the controls replacing role scoping, a second human, the signed record, and the EU AI Act position. The gate adds four rows: a penetration test (a paid attempt by professionals to break in, with no open critical or high finding, repeated annually, P139), the DPIA started with the works council informed, a crisis rehearsal (a tabletop), and witnessed key custody ([the thirteen](../01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa); [the checklist the gate reads](../11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads)).

**Connector.** A link from the front-door app to a source of documents or data, so that an agent can read from it. The connectors allowed are a fixed list enforced by organisation policy, and no connector holds a credential that can write to Workspace (P58) ([the tenant app](../01-hld.md#21-the-tenant-app-and-its-project)).

**Containment primitives, CP1 to CP6.** The six controls every agent inherits: a boundary it cannot redraw (CP1), autonomy kept as data that humans raise and machines lower (CP2), a ceiling outside its own process (CP3), a fleet kill switch outside every agent project (CP4), a model-free monitor that can halt (CP5), and evidence it cannot forge or silence (CP6). The first five are enforced; the sixth is detected, with an absence alarm ([the six primitives](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded)).

**Contract, the autonomy contract.** The set of rules every agent that can change things must adopt: how much it may do on its own, how it records what it did, and how it is measured. One of the five things the platform is ([the autonomy contract](../01-hld.md#12-the-autonomy-contract)).

**Control path and reporting path.** Eve's two halves. The control path approves, vetoes, halts and lowers levels, and contains no language model at all: the model service is switched off in its project and the build refuses model software in its image, so it is deterministic, meaning the same input always gives the same output. The reporting path, `eve-advisor`, may use a model to describe findings but can only write reports and page a human at severity 2; nothing it writes is read by any gate ([Eve's two paths](../01-hld.md#132-eve--independent-controller-two-paths-a-witness-outside-the-tenant-a-second-human)).

**Credential, token, access token, refresh token.** A credential is the secret that proves to Google who is acting, like a key. A token is the temporary pass a program uses instead of a password. A refresh token is long-lived and is used to obtain short-lived access tokens; kill switch K4 revokes the refresh token, and an access token already issued stays valid for up to 60 minutes (`Assumption:`). A leaked token for the robot is a tenant compromise ([what this reverses](../01-hld.md#what-this-reverses-and-what-it-costs); [K4](../../wall-e/ARCHITECTURE.md#46-kill-switches)).

## D

**Data classes and retention.** Every store carries a class that fixes how long it is kept and who may read it: `evidence` (400 days floor), `record` (10 years), `content` (30 days ceiling), `ops` (30 days), plus `control` (an agent's live settings and state: its ladder configuration, plans, approvals, holds and halts) and `secret` (keys, tokens and the surrogate mapping, each read by one program identity and by no human); conversation history in the front-door app is 30 days, an interim value. The DPO sets the ceilings (P13, open); evidence stores are locked only on the day the ceiling is recorded, because a lock cannot be shortened later ([the five data classes](../08-data-logging-retention-sovereignty.md#21-the-five-data-classes); [the retention schedule, P106](../12-open-decisions.md#3-before-any-tier-w-agent-writes)).

**Decision id families.** Every decision, rule, risk and switch has an id. The families that share letters are easy to confuse, so here they are side by side ([identifier families](../brief/31-glossary.md#identifier-families); [families that share letters](../brief/31-glossary.md#families-that-share-letters)).

| Family | What it numbers | Where it lives |
|---|---|---|
| P1 to P204 | Every platform decision, one sequence; new ids append at P205, never reused | [the register](../12-open-decisions.md#1-how-this-register-works) |
| SD-01 to SD-48 | The 48 decisions the full-build procedures made; the same rows as P144 to P191, all pending the owner's signature | [the sign-off tracker](../setup/README.md#10-decision-sign-off-tracker) |
| PV-01 to PV-13 | The 13 decisions the proof of value made; the same rows as P192 to P204; PV-D-01 to PV-D-16 are its deviations from the full build | [the POV's rows](../12-open-decisions.md#6b-proposed-by-the-proof-of-value-set-p192p204) |
| E-1 to E-21, M-1 to M-11, Wall-E 1 to 52 | The agents' own decisions: Eve's (the platform pages cite 20; Eve's page holds 21), Mo's, and Wall-E's (P33 closes its decision 26 by fact) | [the agent-set registers](../brief/30-decisions-awaiting-owner.md#the-agent-set-registers) |
| C-01 to C-27 | The three-day build's cut list: 27 things the full design has and the three days do not | [the cut list](../3-day/README.md#8-the-cut-list-c-01-to-c-27) |
| K0 to K7 | The kill switches; K7's four levers are KF-1 to KF-4 | [kill switches](../../wall-e/ARCHITECTURE.md#46-kill-switches) |
| R-01 to R-17 | The platform risk register; R-01 is the super-admin robot | [the risk register](../11-tisax.md#10-the-risk-register-p140) |
| R1 to R16, and R1 to R11 | Two more families that are not risks: the sixteen requirements read out of the objective of 2026-09-13, and the eleven EU AI Act residuals that cannot be promised | [the objective](../00-objective-review.md#1-the-objective); [what cannot be promised](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean) |
| CP1 to CP6 | The containment primitives | [the six primitives](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded) |
| L0 to L5, S0 to S5, T0 to T3 | Ladder levels, stages, trigger classes | [stage overview](../../wall-e/05-autonomy-ladder.md#stage-overview) |
| B-01 to B-22; G1 to G21, G-1 to G-7 | The full build's BLOCKED rows (code, one contract and people that do not exist yet), and the gate lines of the super-admin grant with Eve's seven | [the BLOCKED index](../setup/README.md#8-blocked-index); [the gate map](../setup/README.md#7-gates-milestones-and-the-g-line-map) |
| E-01 to E-15 | The EU AI Act evidence register; not Eve's decisions | [the evidence register](../10-eu-ai-act.md#5-evidence-register) |

**Decision states.** A register row is `decided` (the owner decided, on a date), `closed` (a later row or a verified fact answered it), `proposed` (a page proposed a value; it stands until the owner overturns it in writing, so silence is consent), `open` (nobody has decided; the gate stays red) or `spike` (a test on a throwaway resource answers it). Exactly one row is `decided` on 2026-09-18: P33 ([how the register works](../12-open-decisions.md#1-how-this-register-works)).

**Deny rule and organisation policy.** Two Google mechanisms set once on the folder. An organisation policy says which Google services may be used at all inside it. A deny rule, or deny policy, lists actions that named identities are refused whatever a project grants them. With the Principal Access Boundary they are the platform's fence that no agent can redraw ([the mechanisms](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded); [deny policies](../01-hld.md#45-deny-policies-and-principal-access-boundaries)).

**Detection desk, severity, SOC.** The detection desk is whoever acknowledges an alarm: the next business morning below Tier P, a bought round-the-clock desk at Tier P. Severity grades an alarm, 1 being the most serious: severity 1 is acknowledged within 15 or 60 minutes, severity 2 within 4 business hours (`Assumption:`). A SOC, security operations centre, is an in-house team watching alarms round the clock; the platform does not run one, it buys acknowledgement ([platform terms](../brief/31-glossary.md#platform-terms); [acknowledgement targets, P99](../12-open-decisions.md#3-before-any-tier-w-agent-writes); [the non-goals](../01-hld.md#16-what-the-platform-does-not-do)).

**Deviation record.** The signed file admitting that a machine holding Super Admin breaks TISAX's least-privilege control, and listing the compensations under which the exception is accepted. Its sections are Decision, Deviation statement, Residual risk, Compensating controls, Precondition rule, Review, Signatures. The platform owner decides, the security reviewer signs (a person who is not the owner), the ISMS enters it; on 2026-09-18 the signature and the entry are pending ([the record](../11-tisax.md#62-the-record--decisions2026-09-13-wall-e-holds-super-adminmd); [the file](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)).

**Domain-wide delegation.** A Workspace mechanism that lets a program act as any user in the tenant. The platform grants it to nothing, ever ([the non-goals](../01-hld.md#16-what-the-platform-does-not-do)).

**DPIA and DPO.** The DPO is the data protection officer: the organisation's independent expert on personal data, who sets the retention ceilings, answers the profiling question with legal, and holds the record that permits monitoring named administrators. The DPIA is the data protection impact assessment: the DPO's written study of what a processing activity does to people and how its risks are reduced, required before the processing starts when the risk is likely high. It was not started on 2026-09-18 and is the longest lead item in the plan. Whether it must be complete or only started at the super-admin grant differs between the high-level design's tier gate and the grant checklist; the DPO and the owner decide. The review of 2026-09-18 reads the law as requiring it complete before Eve begins watching human administrators, because an impact assessment must come before the processing it assesses ([what the platform owes the DPO](../brief/26-personal-data-and-employees.md#222-what-the-platform-owes-the-dpo-and-where-each-input-stands); [still open](../brief/26-personal-data-and-employees.md#229-still-open); [the checklist the gate reads](../11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads); [the DPO's decisions](../brief/26-personal-data-and-employees.md#228-the-dpos-decisions-and-engagement-points)).

## E

**Enforced and detected.** The two grades every control carries. Enforced: the action cannot happen, because Google or code outside the agent refuses it, and if the control breaks the action stops. Detected: the action happens and something independent sees it afterwards within a stated time; it produces evidence and never stands alone in a safety argument. A screen that guesses, such as Model Armor, is never a fence whatever its grade ([the grading rule](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded)).

**Envelope witness, and the custodian.** An emergency credential is sealed in a tamper-evident envelope and kept in a safe with a sign-out log. The envelope witness is a person from another administration line who watches the sealing and signs that they saw it; the custodian keeps the envelope. The three-day build has no envelope witness ([every distinct human role](../pov/README.md#52a-every-distinct-human-role-and-the-first-file-that-needs-it); [the purchase table](../setup/04-purchases-and-lead-times.md#1-the-purchase-table-longest-lead-time-first); [the three-day team](../3-day/README.md#3-the-team-and-what-they-hold)).

**EU AI Act.** Regulation (EU) 2024/1689, the European Union's law on artificial intelligence, in force since 2024-08-01 and generally applicable since 2026-08-02. A second law, Regulation (EU) 2026/1744, the Digital Omnibus on AI, in force since 2026-07-27, moved the high-risk obligations of Annex III to 2027-12-02. A market surveillance authority is the national body that polices the Act. Every date was re-verified on 2026-09-18 and held ([the regulatory state](../10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13); [what Super Admin changes](../10-eu-ai-act.md#315-two-things-super-admin-does-and-does-not-change)).

**`eve-advisor`.** Eve's reporting path: a program that may use a language model to write narratives about what the control path found, and that holds no signing key, no right to call anything and no secret. Its class under the EU AI Act is *tbd*; legal decides (P19) ([eve-advisor](../10-eu-ai-act.md#33-eve-advisor--class-tbd-p19-interim-rules-eve-advisor)).

**Eve-H and Eve-W.** The two halves in which Eve is built. Eve-H is built first, before Wall-E exists: it watches every human super admin and every live holder of an administrator role, and reports to the second human. Eve-W is added later and brings the Wall-E side and the gate. Until a halt target exists, every rule that would halt instead pages a human at severity 1 (P153) ([Eve's two halves, P153](../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191)).

**Explanation path.** How an employee learns why something happened to their account: they ask HR, which obtains the frozen plan's reasoning, the state before, the trigger and the decision reference, with other people's data and the raw prompt removed. No decision on the platform is solely automated; the answer deadline in business days is *tbd* ([workers and the explanation path](../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129)).

## F

**Factory.** The pipeline, run by a machine identity and not a person, that creates each agent's own cloud project with its identity, gateway, logging, budget and deny rules already in place, from two inputs: the register row and the manifest. Like a factory stamping out identical parts, so the controls reviewed once hold for all ([the factory](../01-hld.md#32-the-factory); [platform terms](../brief/31-glossary.md#platform-terms)).

**Fingerprint.** A short code computed from a file or a row of data; change one character and the code changes. The platform uses it to notice alteration, not to prevent it: the manifest's fingerprint sits in the register row, and an audit row whose fingerprint no longer matches has been altered ([the manifest](../01-hld.md#122-agent-manifestyaml); [the POV's claim statement](../pov/README.md#11-pov_claim_statement)).

**Folder, organisation, project.** Google Cloud arranges resources in a tree. The organisation is the top of the company's tree. A folder groups what is below it, and a rule set on a folder binds everything inside, which nobody inside can remove. A project is the box in which one piece of software lives with its own identity, bills and permissions; every agent gets one, forced by Google, and a project is never moved between tier folders or reused ([the folder tree](../01-hld.md#31-folder-tree); [why one project per agent](../../project-topology.md#1-why-four-projects)).

## G

**Gate, the tier gate.** The rule that a tier of agents opens only when the people and the bought services it needs exist; like a lift that moves only when the required number of people are inside. The super-admin grant is a gate with its own checklist, not a phase ([the tier gate](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens)).

**GDPR and controller.** The General Data Protection Regulation, the EU's law on personal data. The controller is whoever decides why and how personal data is processed; the organisation is the controller, and the platform is its internal processing of its own employees' accounts. Its Article 88 covers monitoring systems at the workplace, which Eve over the administrators is ([controller and internal processing](../brief/26-personal-data-and-employees.md#221-the-position-controller-and-internal-processing)).

**Gemini Enterprise, the front door.** Google's application in which an employee talks to AI helpers. The platform makes one such app, located in `eu`, the only front door for every agent a human talks to; an agent with no register row cannot be reached from it ([the tenant app](../01-hld.md#21-the-tenant-app-and-its-project); [the detailed page](../03-gemini-enterprise-environment.md)).

**Google Cloud, Google Workspace, tenant, licence.** Google Cloud is Google's service where an organisation rents computers, storage and other building blocks; the platform runs in one European region, `europe-west1`, with its data warehouse, BigQuery, in the EU multi-region ([the projects and their region](../../project-topology.md#2-the-four-projects)). Google Workspace is the organisation's e-mail, calendar, documents and user directory, run by Google. The tenant is the organisation's own copy of it, with all its accounts and administrators. A licence is a paid seat for a Google service; reclaiming licences from suspended accounts is Wall-E's first measurable saving ([the objective](../00-objective-review.md#1-the-objective); [the gain](../brief/02-executive-summary.md#why-build-it-and-how-the-programme-can-stop)).

**GPAI.** General-purpose AI: the EU AI Act's regime for large models sold for many uses, binding since 2025-08-02. Google is the provider of the Gemini models under it; the platform hosts them and never trains, fine-tunes or substantially modifies them ([Gemini](../10-eu-ai-act.md#35-gemini-enterprise-app-and-the-gemini-models--deployer-duties-and-the-gpai-one-liner-gemini); [the regulatory state](../10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13)).

## H

**Hard-denied list, and the two lists.** The hard-denied list is what Wall-E may never do, refused by code in every band, the band-C handoff included: change the tenant's security posture, delete data, assign administrator roles, spend money, select people by behaviour. The second list is the operations reachable only through band B with two humans. Together they are "the two lists", decision P29, open, which the owner signs ([Wall-E's lists](../01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa); [P29](../12-open-decisions.md#4-before-the-super-admin-grant)).

**Hardware key.** A small physical device that must be plugged in to sign in. The robot's account has two, custody is witnessed, and the full build orders 22, or 26 with the twin robots, a count that supersedes an older "ten in total" ([the count stated once](../setup/04-purchases-and-lead-times.md#4-hardware-keys-the-count-stated-once-and-the-inventory)).

**Harmonised standard.** A technical standard that the European Union publishes in its Official Journal. Following one gives a legal presumption that a system meets the EU AI Act's requirements. On 2026-09-18 none is cited, so no such presumption exists and the design leans on none ([what cannot be promised](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean); [the regulatory state](../10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13)).

**Hold window, vetoable hold.** At ladder level L4, after Eve approves an action, a pause opens during which any operator can veto it with one click; only then does it execute. For a suspension the hold never runs out outside business hours. Stated plainly, a wrongful suspension can last the hold window plus the human approval of the restore, up to four business hours ([the six levels](../../wall-e/05-autonomy-ladder.md#2-the-six-levels); [the actions that affect employees](../brief/26-personal-data-and-employees.md#224-the-actions-that-affect-employees-and-how-they-are-bounded)).

**HSM.** Hardware security module: a tamper-resistant device that signs data without ever giving the key out. Eve's approval key and its evidence keys live in one ([key management](../01-hld.md#83-key-management); [Eve's keys, P166](../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191)).

## I

**IAM.** Identity and Access Management, Google Cloud's system for saying which identity may do what on which resource. On the platform no human, group or domain is ever allowed to call a credential-holding service; only named machine identities are ([identity](../01-hld.md#4-identity)).

**Intended purpose.** The sentence the provider declares a system is *for*, which is what the EU AI Act classifies, not what the account could do. Wall-E's is a fixed catalogue of administration chores on a named person's request or an HR event; it must be identical in five places (register row, manifest, agent card, app description, operator instructions) and Super Admin never appears in it (P28, signature open) ([the declared purpose](../10-eu-ai-act.md#311-the-declared-intended-purpose-the-sentence-the-assessment-rests-on)).

**ISMS.** Information security management system: the organisation's security governance function, which names people to roles, enters risks in the site's risk register and orders the TISAX assessment ([abbreviations](../brief/31-glossary.md#abbreviations); [the target](../11-tisax.md#2-the-target--label-level-scope-catalogue-p133)).

## K

**Kill switches, K0 to K7.** Eight pre-built ways to stop an agent, from surgical to total. A breaker is an automatic rule that trips on a threshold and may pull K0 or K1 with no approval. No machine may lock the robot's account itself (P16, "none now"), because an automatic lock-out is a path a compromised monitor could pull ([the table](../../wall-e/ARCHITECTURE.md#46-kill-switches); [K7](../01-hld.md#114-the-fleet-kill-switch-k7-and-the-containment-primitives-for-the-top-tier)).

| Switch | In plain words | Who pulls it | Target |
|---|---|---|---|
| K0 halt writes | The action service stops changing anything; reads continue | Any operator, Eve or a breaker; no approval | Under 5 seconds at the endpoint; under 60 seconds to contain |
| K1 demote one cell | One kind of operation on one kind of trigger drops a level | The same | Under 5 seconds |
| K2 stop new runs | The timers and message queues that start runs are paused | An operator with the cloud rights | Seconds |
| K3 cut the agent off | The agent loses its permission to call its own action service | A project administrator | About a minute |
| K4 kill the credential | The action service revokes its own refresh token at Google, on both services | Any operator, one call to each service | Seconds; an access token already issued lasts up to 60 minutes (`Assumption:`) |
| K5 revoke the grant or suspend the robot | A human suspends the robot's account or revokes its application grants | A human super admin on the two-person rota | Within 30 minutes of a severity-1 acknowledgement |
| K6 remove Super Admin | A human strips the role from the robot's account; the one switch that survives a token already minted | Human only, never a machine | Within 60 minutes |
| K7 fleet kill | Four pre-written levers stop every agent at once; lifting it takes two humans | A named group, or a deterministic job on a severity-1 SIEM rule; never a model | First lever under 60 seconds; under 5 minutes end to end |

## L

**Language model, model pin, model family.** A language model is the software behind a chat assistant: it reads text and produces text, and it can be wrong. A model pin is the exact model version an agent uses, recorded in its register row. A model family is one maker's line of models; the platform runs one family fleet-wide, an accepted limit until Tier X needs a second ([the honest line](../01-hld.md#115-the-honest-line); [the residual risks](../brief/23-threat-model-and-residual-risk.md#the-residual-risks-a-sponsor-accepts-by-signing)).

**Least privilege and separation of duties.** Two TISAX controls. Least privilege (4.2.1): every account holds only the rights its task needs; a machine holding Super Admin cannot meet it, hence the deviation record. Separation of duties (1.2.2): the person who asks is never the person who approves, and the person who benefits from an exception never signs it; on 2026-09-13 every role is one person, the finding most likely to stop an assessment ([the deviation](../11-tisax.md#61-what-the-deviation-is-in-isa-terms); [separation of duties](../11-tisax.md#7-separation-of-duties-and-the-staffing-minimum-per-stage-p137)).

**Log ingestion.** Taking every log line into the central store and keeping it there, locked, for its retention period. It is the largest cost line of the design, driven by Workspace audit volume, and it cannot be cut by keeping less evidence, because Eve's reconciliation needs Google's record of all administrator activity, not only the robot's; no price exists yet ([cost classes](../brief/29-roadmap-and-cost.md#cost-classes)).

## M

**MDR.** Managed detection and response: an outside company contracted to watch the super-admin detections and respond round the clock. Bought for Tier P with the SIEM; months to procure (`Assumption:`); which partner is open (P10) ([what the sponsor is asked for](../brief/02-executive-summary.md#what-the-sponsor-is-asked-for-in-order); [the purchase table](../setup/04-purchases-and-lead-times.md#1-the-purchase-table-longest-lead-time-first)).

**Model Armor.** Google's screen for the text going into and coming out of a model. It works by probability, so it produces evidence and is never a trust boundary. A floor is a minimum setting applied tenant-wide. The sentence "Model Armor blocked the injection" is never used; see the entry on the never-to-be-used sentences ([Google products](../brief/31-glossary.md#google-products-and-features); [Model Armor](../06-gateways-model-armor-perimeter.md#3-model-armor)).

**Multi-party approval.** A Workspace setting under which covered administrative changes need a second administrator's approval. Switched on before the grant (P66), it is the only Google-enforced two-person rule over the robot's credential; the robot is never an approver and switching it off is hard-denied ([the two-person rule Google enforces](../04-identity-and-privileged-access.md#84-workspace-multi-party-approval-the-two-person-rule-google-enforces)).

## N

**Never-to-be-used sentences.** The two smaller build paths list sentences banned from any report, slide or message, because each would be true of the full design and false of the build that produced the report. Why: neither smaller path gives any agent Super Admin, so neither produces evidence about containing one; neither has a witness organisation, so its Eve is inside the reach of those it watches; a probabilistic screen is evidence, never a wall; and acting on made-up accounts saves nobody a minute. From the three-day build, verbatim ([never to be used](../3-day/README.md#11-never-to-be-used-in-any-report-slide-or-message)):

> 1. "Wall-E is safe as a super admin." Nothing here touches super-admin containment. No agent holds Super Admin at any moment of the three days. 2. "Eve is independent." Independence in the design is structural: a witness organisation, a second tenant. This set has neither (C-01), and its Eve lives inside the reach of the administrators it watches. 3. "Model Armor blocked the injection." A probabilistic content screen is never a trust boundary. And nothing here exercises it: no step sends anything through the floor, so these three days produce **no Model Armor evidence at all**, only the floor settings themselves (C-22). 4. "We saved `<n>` minutes of admin work." The doer acted only on synthetic accounts. No human minute was saved, and Mo's scorecard says so in bold (C-07).

The proof of value forbids the first three in its own words ([never to be used about the POV](../pov/README.md#12-never-to-be-used-in-any-report-slide-or-message-about-the-pov)):

> "1. 'Wall-E is safe as a super admin.' Nothing in Track A touches super-admin containment (G10, G11, G14, G20, Eve G-7 need Track B, §3). Nor may any report say or imply that the doer 'does admin work': it holds no Workspace admin role. 2. 'Eve is independent.' Independence in the design is structural (a witness organisation, a second tenant). The POV has neither (PV-D-03), and its Eve lives inside the reach of the administrators it watches. 3. 'Model Armor blocked the injection.' A probabilistic content screen is never a trust boundary, whatever its grade ([../01-hld.md](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded) §0.2). It produced evidence."

## O

**OAuth scope and consent.** A scope is one permission an application is granted, such as reading the directory. Consent is the one-time sitting in which the robot account grants its own application a listed set of scopes, producing the refresh token the action service holds. That consented scope set is the only ceiling Google itself still enforces on the super-admin robot; the scope granting the whole of Google Cloud is never consented ([what this reverses](../01-hld.md#what-this-reverses-and-what-it-costs)).

**OU.** Organisational unit: a folder in the Workspace directory into which accounts are sorted, so that settings can apply to a group of them. Super Admin cannot be limited to an OU, which is why a pilot OU inside production is not a sandbox ([what this reverses](../01-hld.md#what-this-reverses-and-what-it-costs); [the sandbox rule, P178](../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191)).

## P

**PAM.** Privileged Access Manager, Google's product for time-boxed, justified and logged elevation of rights with no self-approval, so that nobody holds a standing owner role anywhere ([Google products](../brief/31-glossary.md#google-products-and-features); [the entitlement catalogue](../04-identity-and-privileged-access.md#5-privileged-access-manager-the-entitlement-catalogue)).

**Principal Access Boundary, PAB.** A Google rule, set on the folder, that lists the only resources an identity may reach at all, whatever a project grants it. With the deny rule and the organisation policy it forms the fence no agent can redraw. It is counted only for engine queries, because a test showed it does not block a call to a Cloud Run service (P60) ([deny policies and boundaries](../01-hld.md#45-deny-policies-and-principal-access-boundaries); [the non-goals](../01-hld.md#16-what-the-platform-does-not-do)).

**Profiling.** Any automated evaluation of a person's behaviour, performance or reliability; it removes the EU AI Act exemption outright. The design lets no AI output select a person by behaviour: the inactivity report is a document a human reads, and Wall-E acts only on identities a human typed in. Whether that report is still profiling is open (P18) ([the profiling boundary](../10-eu-ai-act.md#314-the-profiling-question-answered-by-design-p126)).

**Provider and deployer.** Under the EU AI Act the provider puts a system into service under its own name and the deployer uses it. The organisation is both for Wall-E and Mo; Google is the provider of the models and of Gemini Enterprise, the organisation their deployer; which legal entity holds the roles is *tbd* (P23) ([roles](../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer)).

**Pull request, version control, CI.** Version control is a system that keeps every version of a file and records who changed what and who approved it. A pull request is a proposed change to those files that people review before it is accepted. CI, continuous integration, is the automatic check that runs on every proposed change and refuses the ones that break a rule; the register's mandatory fields and the separation-of-duties check are CI checks. Mo reaches production only through a pull request two humans merge ([Mo](../01-hld.md#133-mo--improving-both-one-mo-per-platform-without-touching-eves-independence); [supply chain](../01-hld.md#9-supply-chain)).

## R

**Reconciliation gap, and silence as a halt.** A reconciliation gap is any robot event in Google's own logs with no matching row in Wall-E's audit record; it halts Wall-E's writes and pages at severity 1. Silence is a halt too: if the log pipeline goes quiet, no agent may act on its own and the super-admin lanes stop, until one human clears it, and every clearing is itself reported (P97) ([Eve's evidence](../01-hld.md#132-eve--independent-controller-two-paths-a-witness-outside-the-tenant-a-second-human); [the silent-pipeline halt](../07-monitoring-detection-incident-response.md#7-pipeline-heartbeats-and-the-log_pipeline_silent-halt)).

**Records of processing.** The list that the GDPR requires every controller to keep of what personal data it processes, for what purpose, and for how long. The platform owes the DPO one entry per agent, covering reads at Stage 0, writes from Stage 1, band B, Mo's metrics, the content logs and the identity log store; on 2026-09-13 none was started ([what the platform owes the DPO](../brief/26-personal-data-and-employees.md#222-what-the-platform-owes-the-dpo-and-where-each-input-stands)).

**Register, registry, manifest.** The register is one file per agent in version control; an agent needs a row there before it may exist, like a civil register. The registry is Google's product, Agent Registry, a catalogue written from the register by CI that never authorises anything. The manifest, `agent-manifest.yaml`, is the short file that says what an agent may be, whose fingerprint is recorded in its register row ([the inventory of record](../01-hld.md#51-the-inventory-of-record-is-a-git-file-not-a-product); [four things that are not each other](../05-registry-and-autonomy-contract.md#1-vocabulary-four-things-that-are-not-each-other); [the manifest](../01-hld.md#122-agent-manifestyaml)).

**Residual risk and the risk register.** A residual risk is what remains after every control, and a signature accepts it. Eight are listed for the sponsor, the first being that a stolen robot credential is a takeover of the tenant. The platform risk register holds rows R-01 to R-17 (P140). Who owns R-01 differs between two pages: the TISAX page names the platform owner, the signed decision record names the security reviewer; the acceptance is the security reviewer's signature and the ISMS entry either way ([the residual risks](../brief/23-threat-model-and-residual-risk.md#the-residual-risks-a-sponsor-accepts-by-signing); [the risk register](../11-tisax.md#10-the-risk-register-p140); [every unresolved point](../brief/30-decisions-awaiting-owner.md#every-unresolved-point-the-brief-raises)).

**Roles.** Every role is a job, not a person; on 2026-09-13 one administrator holds them all. Page [04-people-and-decisions.md](04-people-and-decisions.md) gives the forbidden pairs and the count per stage ([who exists and the roles needed](../01-hld.md#03-who-exists-on-2026-09-13-and-the-roles-the-platform-needs); [the roles](../11-tisax.md#71-the-roles); [who must be present](../setup/README.md#6-who-must-be-present-s069)).

| Role | In plain words |
|---|---|
| Platform owner | Builds and runs the shared parts: folder, factory, register, floors |
| Agent owner (Wall-E owner, Mo owner) | One per agent; writes its routines, keeps its register row and budget |
| Operator / approver | Asks an agent for work; approves the actions that need a human's yes; can pull K0 |
| Security reviewer | From IT security; reviews every rise in autonomy and signs deviations; never the platform owner |
| Blind grader | Grades the weekly sample without knowing the planted items; never wrote the routines |
| Deployer | Runs the factory and the release pipeline; a second reviewer checks every release holding a credential |
| Eve owner, the second human | A super admin in IT security outside the Wall-E line; owns Eve's group, configuration reviews and evidence copy; sole recipient of reports about the administrator |
| Detection desk | Acknowledges alarms within the target time; bought at Tier P |
| Incident commander | From IT security; leads a severity-1 incident; talks to the DPO and the works council |
| Human super admins | Two humans on separate admin accounts with hardware keys; the robot is never the only one nor the recovery one |
| Validator custodian | Runs the independent recalculation Mo cannot reach |
| AI compliance owner | Legal's designate; signs classifications, files registrations, answers an authority (P131) |
| Witness administrators; sandbox super admins | Two IT security people who run the witness organisation and hold no rights in the tenant; two people who run the separate practice tenant |
| Sponsor | Funds the programme and signs for its residual risks; in the three-day build, named in writing and does no work |
| HR, legal, procurement, finance | Human resources answers the works-council question; legal signs the EU AI Act files; procurement and finance obtain prices and accounts |

## S

**SCC, Security Command Center Premium.** Google's organisation-wide service that reports security findings across every cloud project; the detection desk for Tier C, switched on at organisation level; its funding is open (P11). The one vendor list price on record is on [07-what-it-costs-and-what-you-get.md](07-what-it-costs-and-what-you-get.md) ([Google products](../brief/31-glossary.md#google-products-and-features); [SCC at organisation level](../07-monitoring-detection-incident-response.md#3-security-command-center-premium-at-organisation-level)).

**Second human.** A human super admin in IT security, outside the reporting line of whoever administers Wall-E: owner of Eve's group, required reviewer of Eve's configuration, holder of the second human admin account, member of no Wall-E group, parallel recipient of every severity-1 and severity-2 page, sole recipient of reports about the administrator's own actions, second name on the K5 and K6 rota ([the roles](../11-tisax.md#71-the-roles)).

**Service account and user account.** A service account is the identity a program normally uses on Google Cloud; it has no password. Google lets it hold any Workspace admin role except Super Admin, so a robot that must hold Super Admin has to be a user account, like an employee's, protected by hardware keys with no interactive login ([what this reverses](../01-hld.md#what-this-reverses-and-what-it-costs)).

**SIEM, Google SecOps.** A SIEM, security information and event management service, collects logs, runs detections and has a desk that acknowledges pages. Google SecOps is Google's SIEM, the proposed default, in the EU; the choice, with the MDR partner, is open (P10). Bought for Tier P; the largest cost line of the design is the log volume it must ingest ([Google products](../brief/31-glossary.md#google-products-and-features); [the SIEM contract](../07-monitoring-detection-incident-response.md#2-the-siem-the-contract-the-decision-and-the-default-instance)).

**Super Admin, and the super-admin grant.** Super Admin is the Workspace role with every administrative power, which Google cannot limit to part of the organisation or to a subset of its powers. A Workspace super admin can also grant themselves Organization Administrator, the top role on the organisation's Google Cloud, so nothing inside the organisation is structurally out of their reach. Wall-E holds it through the user account `walle@`, decided by the platform owner on 2026-09-13 (P33); the design works around that decision and never re-argues it ([what this reverses](../01-hld.md#what-this-reverses-and-what-it-costs); [Eve's independence](../../eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness); [the decision](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)). The super-admin grant is the day `walle@` receives the role: a gate with its own checklist, not a phase of the build. Before it Wall-E exists, is licensed and hardened, holds no admin role and reads nothing. The order is Eve's observe-and-report layer live and drilled, then the grant, then Stage 0. Five named humans are needed, or four with a dated ISMS exception; the enforceable refusal on the day is the second human's ([a gate, not a stage](../../wall-e/05-autonomy-ladder.md#the-super-admin-grant--a-gate-not-a-stage); [the gate map](../setup/README.md#7-gates-milestones-and-the-g-line-map)).

**Surrogate key.** A made-up code that stands in for a person in an audit row or a metric, so that the row does not carry their name. The table that maps codes back to people is `secret` class, with no reader. Mo publishes only totals over surrogates, with at least five people per cell (`Assumption:`); a total over one surrogate is a person, and who may read such a figure is open (M-3) ([operators as data subjects](../brief/26-personal-data-and-employees.md#226-operators-as-data-subjects-the-limits-on-monitoring)).

**Synthetic account, pilot OU, sandbox tenant.** A synthetic account is a made-up account that belongs to nobody; the proof of value acts on 5 to 10 of them (`Assumption:`) and the three-day build on four, in a pilot OU, an otherwise empty organisational unit. A sandbox tenant is a separate, second Workspace organisation of the same edition, used for any test that changes things as a Super Admin ([the pilot population, P197](../12-open-decisions.md#6b-proposed-by-the-proof-of-value-set-p192p204); [the sandbox rule, P178](../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191)).

## T

**Tabletop, and the penetration test.** Two rehearsals the super-admin gate requires. A tabletop is a crisis rehearsal held round a table: the people walk through a scenario, an abused super-admin credential, without touching any system, and a dated record is kept. A penetration test is a paid attempt by professionals to break in; a scoped one runs before the first Tier W agent writes, a full one before the grant, and then annually, and no critical or high finding may be open (P139) ([the checklist the gate reads](../11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads); [the assurance cadence, P139](../12-open-decisions.md#4-before-the-super-admin-grant)).

**Three build paths.** The three-day build: two people, three business days, four cloud projects, four synthetic accounts, a doer with one OU-scoped privilege, a demonstration and nothing else. The proof of value (POV): three hands-on people and one engineer, 6 to 9 weeks to its first stage and week 16 to 20 to its second, on the real tenant, with no agent holding any admin role; its Track A is Tiers C, R and W, and Track B, the super-admin path, is not in it. The full build: 42 human-executed files, thirteen appointments, thirteen purchases, 6 to 7 months to Stage 0 and not before 2027-03, the only path that grants Super Admin. In the two smaller paths the doer is called `steward`, because the names `walle`, `WALLE_PROJECT` and `walle_audit` are reserved for the full build (P193; [the two tracks](../pov/README.md#3-the-two-tracks)). Each hands over to the next with nothing torn down ([how it grows](../3-day/README.md#12-how-it-grows); [the POV's two stages](../pov/README.md#4-pov_stage_dates-the-two-stages); [what the full build builds](../setup/README.md#status)).

**Tier.** A letter that says what an agent may do, and therefore which controls, people and purchases must exist before it runs. Letters, never numbers, so they never collide with the trigger classes T0 to T3 ([the tier model](../01-hld.md#11-the-tier-model); [tiers and controls](../01-hld.md#111-tiers-and-mandatory-controls)).

| Tier | What the agent may do | Who checks its work |
|---|---|---|
| C, classical | Answer questions from documents inside the front-door app, with the asking person's own permissions | Nobody dedicated |
| R, read tools | Read other systems through tools, via its gateway, in its own project | Nobody dedicated |
| W, write agents | Change records in a system of record through an action service | The platform verifier |
| P, privileged | Its action service holds a Workspace administrator role over the whole tenant | A dedicated Eve |
| P-SA, the super-admin singleton | As P, with Super Admin; exactly one agent, Wall-E on 2026-09-13 | A dedicated Eve |
| X, AGI-class | Would run code it wrote or pursue its own goals; closed | Closed |

**TISAX.** Trusted Information Security Assessment Exchange: the automotive industry's shared way of checking a supplier's information security once. A label is earned by a site, never by a platform; the target is the label Confidential (`Assumption:`, P133) at assessment level AL2 (evidence review and a video interview) with maturity 3, "established", on every applicable control, and a result is valid three years. An assessor may still refuse maturity 3 on least privilege for a super-admin robot ([TISAX on 2026-09-13](../11-tisax.md#1-tisax-on-2026-09-13-verified); [the honest paragraph](../11-tisax.md#0-what-this-page-decides-in-one-paragraph)).

**Toil baseline.** Four consecutive weeks in which staff record their own time on the top three administrative tasks, before Wall-E's first phase, because no "before" can be measured afterwards. The first act of the full build, starting the first Monday after HR's works-council answer; until it is done no benefit figure exists ([the first act](../setup/README.md#31-blocks); [why build it](../brief/02-executive-summary.md#why-build-it-and-how-the-programme-can-stop)).

## V

**Validator, platform verifier, validator custodian.** The validator is a separate program the agent cannot reach; it re-runs the query behind every number an agent cites and refuses a promotion if one value differs, so numbers are re-derived, not believed. The platform verifier is the Tier W checker built in Eve's model-free shape; at Tier P the verifier is a dedicated Eve. The validator custodian is the role that runs the validator ([the validator and the platform verifier](../01-hld.md#124-the-validator-and-the-platform-verifier); [Mo's thesis](../../mo/01-hld.md#thesis)).

**VDA ISA, ISA2027, ENX.** The VDA is the automotive industry association that owns the TISAX questionnaire, the VDA ISA (Information Security Assessment); the ENX Association runs TISAX on its behalf and holds the results on its portal. VDA ISA 6.0.3 (2024-04-25) is in force; ISA2027 (2026-07-01) is the basis of assessments ordered from 2027-01-01, and 2026-12-31 is the last day to order under ISA 6. The design maps against ISA2027 ([TISAX on 2026-09-13](../11-tisax.md#1-tisax-on-2026-09-13-verified)).

## W

**Witness organisation.** A second, minimal Google organisation on its own domain, run by two IT security administrators who hold no rights in the tenant; a witness who keeps a copy outside the building. Eve pushes its evidence, its incident record and its pager there, one way, create-only; an absence alarm pages a human when the copy stops arriving. It sees the deletion of Eve's project within fifteen minutes and the absence of evidence; it does not see the forgery of an approval. Open as P14; the smaller build paths have none ([Eve's independence](../../eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness); [platform terms](../brief/31-glossary.md#platform-terms)).

**Works council.** The employees' elected representatives. The design informs them, or consults them where national law requires it, before any agent acting on employee accounts takes its first write (P129); the review of 2026-09-18 asks for that step earlier, before Eve begins watching human administrators, and as consultation, with consent where co-determination applies. Which country's law applies is *tbd*, because the operating site's country is not fixed, and no page may name one ([workers and the explanation path](../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129); [the legal register](../11-tisax.md#11-the-legal-and-contractual-register-p141)).

## What this means for you

**If you are an employee or a works-council member.** The entries that concern your account are Audit record, Explanation path, Profiling, Works council, DPIA and DPO. The two actions that change whether a person can work, suspension and licence removal, are under Bands and Hard-denied list: a human decides first, and the record says who. None of it exists yet.

**If you are a manager or a board member.** Read Super Admin and the grant, Enforced and detected, Compensations and Residual risk in that order; they are the signature. Then the never-to-be-used sentences, because they are what a slide will most want to say.

**If you are a new engineer.** Learn the families that share letters before you read a design page, and the three sentences no page may break: the model holds no credential; no model produces an approval, a signature, a halt, a veto or a refusal; Mo reaches production only through a pull request a human merges ([the standing constraints](../01-hld.md#status)). The glossary of record for identifiers is [../brief/31-glossary.md](../brief/31-glossary.md).

## What is still undecided

Only the decisions that change what a term on this page means.

| Id | What is undecided | Entry it touches |
|---|---|---|
| P29 | The two lists, unsigned; the owner signs | Hard-denied list |
| P28 | Wall-E's intended purpose, signature with legal open | Intended purpose |
| P19 | `eve-advisor`'s class under the EU AI Act; legal | `eve-advisor` |
| P34 | Eve's reporting path may reason; the Eve owner and the security reviewer sign | Control path and reporting path |
| P14 | The witness organisation: domain, edition, billing; IT security | Witness organisation |
| P10 | Which SIEM and which MDR partner; IT security | SIEM, MDR |
| P13 | The retention ceiling per class; the DPO | Data classes and retention |
| P23 | Which legal entity is provider and deployer; legal | Provider and deployer |
| P133 / P20 | The TISAX label, level and scope; the ISMS confirms | TISAX |
| P16 | No machine may lock the robot's account; proposed "none now" | Kill switches |
| P25 | How many writing agents one blind grader can carry | Blind grader |
| P33 / P136 | The deviation record's two missing signatures | Deviation record |
| no register row | Two counts differ between pages and no register row records either: Eve's decisions (the platform pages cite 20, Eve's page holds 21) and the hardware keys (22 or 26, superseding an older ten) ([the agent-set registers](../brief/30-decisions-awaiting-owner.md#the-agent-set-registers); [the count stated once](../setup/04-purchases-and-lead-times.md#4-hardware-keys-the-count-stated-once-and-the-inventory)) | Decision id families; Hardware key |

## Where this is defined

- The glossary of record, written for engineers, with the identifier families and the families that share letters; where this page and that one differ, that one and the design page it cites are right: [../brief/31-glossary.md](../brief/31-glossary.md). The high-level design, parent of every design page: [../01-hld.md](../01-hld.md); its vocabulary of four things that are not each other: [../05-registry-and-autonomy-contract.md §1](../05-registry-and-autonomy-contract.md#1-vocabulary-four-things-that-are-not-each-other)
- The agents: Wall-E's ladder and switches, [../../wall-e/05-autonomy-ladder.md](../../wall-e/05-autonomy-ladder.md#stage-overview) and [../../wall-e/ARCHITECTURE.md §4.6](../../wall-e/ARCHITECTURE.md#46-kill-switches); Eve, [../../eve/01-hld.md](../../eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness); Mo, [../../mo/01-hld.md](../../mo/01-hld.md#thesis)
- The law, the standard and personal data: [../10-eu-ai-act.md](../10-eu-ai-act.md); [../11-tisax.md](../11-tisax.md); [../brief/26-personal-data-and-employees.md](../brief/26-personal-data-and-employees.md). The register of decisions and their states: [../12-open-decisions.md](../12-open-decisions.md#1-how-this-register-works); the one decided row: [../../../decisions/2026-09-13-wall-e-holds-super-admin.md](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)
- The three build paths: [../3-day/README.md](../3-day/README.md); [../pov/README.md](../pov/README.md); [../setup/README.md](../setup/README.md). The questions readers ask, in plain words: [09-questions-people-ask.md](09-questions-people-ask.md); back to the front page: [README.md](README.md)
