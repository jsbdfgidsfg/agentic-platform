# 05. The law and the standards

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-18
- What this page is: a plain-words account of the three rulebooks the platform must answer to, the EU AI Act, TISAX and data-protection law, and of where the design stands against each on 2026-09-18. Nothing is built. Every legal position here is the design's position, written so that legal, the data protection officer and the security assessor can sign it or strike it.

## In one sentence

The platform is designed to be assessable under the EU AI Act, TISAX and data-protection law, but nobody can promise the outcome of an assessment, so the design promises the mechanisms and the evidence and says out loud what a regulator, an assessor or a court still decides.

## 1. The EU AI Act in plain words

### What it is

The EU AI Act is a European law, Regulation (EU) 2024/1689, that sets rules for anyone who builds or uses artificial intelligence in the European Union. A regulation is a law that applies directly in every member state without being rewritten nationally. It sorts AI systems by how much harm they could do to people, and it asks more of the riskier ones.

The Act uses two words for the parties it binds. The **provider** is whoever builds a system, or has it built, and puts it to use under its own name. The **deployer** is whoever uses the system under its own authority. An **agent** is a program that uses a language model to decide what to do, and may be given tools to act. A language model is the software behind a chat assistant: it reads and writes text, and it can be wrong. The organisation is both provider and deployer of Wall-E, the agent that does administration work, and of Mo, the agent that measures and proposes improvements. Google is the provider of the language models and of the Gemini Enterprise application (the chat surface employees will use); the organisation is only their deployer. Which legal entity in the organisation holds those roles is decision P23, not yet answered by legal ([../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer](../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer)).

Eve, the agent that watches Wall-E and the human administrators, is a special case. Its control path, the part that can stop or veto Wall-E, contains no language model at all. It runs only rules written by humans. Under the Act's own definition that is not an AI system, and the design keeps it that way by construction: the tooling refuses to build Eve's control path with a model inside it ([../10-eu-ai-act.md#32-eve-control-path--not-an-ai-system-as-an-invariant-eve](../10-eu-ai-act.md#32-eve-control-path--not-an-ai-system-as-an-invariant-eve)).

### The dates that matter

A second law, Regulation (EU) 2026/1744 (called the Digital Omnibus on AI), amended the Act in July 2026 and moved the heaviest deadline back by more than a year. All dates below were re-verified on 2026-09-18 and every one held.

| Date | What happens | What it means here |
|---|---|---|
| 2024-08-01 | The Act enters into force | The clock starts |
| 2025-02-02 | Article 4 (AI literacy: staff must be given measures to understand the AI they operate) and Article 5 (banned uses) apply | Both already bind the organisation today |
| 2025-08-02 | The rules for general-purpose AI models (large models sold for many uses, such as Google's) apply | They bind Google as model provider, not the organisation |
| 2026-07-27 | The Digital Omnibus enters into force (published 2026-07-24) | The high-risk deadline moves |
| 2026-08-02 | Article 50 (transparency: people must be told when they are dealing with an AI system) applies | Already binding; every message Wall-E sends must carry a disclosure line |
| 2026-12-02 | Two new banned uses apply; the grace period for marking older systems ends | No effect on this platform: nothing here generates images, audio or video, and nothing was in use before 2026-08-02 |
| End of 2026 (expected) | The European Commission's final guidelines on classifying high-risk systems | The design's classification is re-run within 90 days of their adoption (P132) |
| 2027-12-02 | The full obligations for "high-risk" systems listed in Annex III apply (moved from 2026-08-02) | A fixed date, not conditional on anything else |
| 2028-08-02 | Obligations for AI embedded in regulated products apply | Not this platform |

Three things bind today, before anything is built: Article 4, Article 5 and Article 50. The penalties are real now. A breach of Article 5 can cost up to EUR 35 million or 7 % of worldwide turnover; a breach of most other duties, Article 50 included, up to EUR 15 million or 3 %; giving a regulator wrong information up to EUR 7.5 million or 1 % ([../10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13](../10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13)).

### What "high risk" means

**Annex III** is the Act's list of uses it treats as high risk. Point 4(b) of that list covers AI used at work to make decisions about people's employment, promotion, termination or how they are monitored and assessed. A system that falls inside the list must carry a full programme of obligations from 2027-12-02: risk management, technical documentation, logging, human oversight, a quality management system, a conformity assessment (an independent check that the system meets the rules) and registration.

The Act also offers an exemption, called the Article 6(3) **derogation**. A system that only performs a narrow procedural task, or only carries out a decision a human already took, and does not materially influence that decision, is not high risk even if its subject matter appears on the list. One thing removes the exemption outright: **profiling**, meaning any automated evaluation of a person's behaviour, performance or reliability.

The exemption is not free. The provider must write down its assessment before putting the system into service (Article 6(4)) and register the system in the EU database before first use (Article 49(2)). On 2026-09-18 it was confirmed that the Digital Omnibus kept that registration duty, after a proposal to delete it was rejected. So "registered before Wall-E's first write" stands as the rule ([../10-eu-ai-act.md#313-art-64-assessment--the-document-its-content-its-owner](../10-eu-ai-act.md#313-art-64-assessment--the-document-its-content-its-owner)).

### Where each of our systems stands

The Act classifies a system by its **intended purpose**: what the provider declares it is for, not what its account could technically do. That distinction is the whole argument for Wall-E.

| System | Class in the design's vocabulary | Why | What must exist before production |
|---|---|---|---|
| Wall-E (the doer) | `annex_iii_adjacent`: next to the high-risk list, claiming the exemption | Its declared purpose is a fixed catalogue of administration chores done on a named person's request or on an HR (human resources) event; it never decides who leaves, who is promoted or how anyone performs, and never picks people by behaviour | A written Article 6(4) assessment signed by legal; an EU-database registration id; a purpose paragraph identical in five places; the tooling refuses production while any is missing (P75) |
| Eve's control path | `not_ai_system` | Human-written rules only; no model; enforced by the build | A recorded statement that it is an oversight measure, not an AI system |
| `eve-advisor` (Eve's optional reporting half, which may use a model to write narratives) | *tbd*: legal decides (P19) | It may reason, but it can only write reports and page a human; nothing it writes is read by the part that stops Wall-E | Legal's determination before any build; until then no finding about a named person without the human-written rule behind it |
| Mo (the improver) | `minimal` | It grades plans, not people; its prose is labelled as agent-authored | Nothing beyond its register row |
| Gemini Enterprise and the Gemini models | Deployer duties only | Google is the provider; the organisation never trains or modifies a model | A written position with Google on shared responsibilities (P32, open) |
| Every future agent | Its own class, per register row | Each is its own Article 6 question | A row without a class, a role and a signed purpose cannot reach production (P75) |

The rejected alternative was to declare Wall-E's purpose as "any super-admin action on a human's prompt". That would have put Wall-E squarely inside Annex III point 4(b), with the full high-risk programme due by 2027-12-02 and no published standard to build against. The design rejected it because that sentence describes the account's power, not the use ([../10-eu-ai-act.md#311-the-declared-intended-purpose-the-sentence-the-assessment-rests-on](../10-eu-ai-act.md#311-the-declared-intended-purpose-the-sentence-the-assessment-rests-on)).

The one family that could amount to profiling, removing licences from accounts that look inactive, was redesigned so that no AI output ever selects a person by behaviour. The inactivity report is a document a human reads; Wall-E acts only on identities a human typed in. Whether that report is still "profiling" is an open question for the DPO (data protection officer) and legal (P18). If the answer is yes, the design recommends removing that family rather than reclassifying Wall-E as high risk ([../10-eu-ai-act.md#314-the-profiling-question-answered-by-design-p126](../10-eu-ai-act.md#314-the-profiling-question-answered-by-design-p126)).

### The weakest point

Wall-E's account holds **Super Admin**, the Google Workspace role with every administrative power, which Google cannot limit to part of the organisation or to a subset of its powers. The owner decided that on 2026-09-13 (P33), and the design works around it rather than re-arguing it.

Super Admin does not change the classification, because purpose is declared by the provider. It does change how believable the declaration is. The draft classification guidelines say a purpose must be described coherently across all materials and cannot be narrower than how the system is positioned. An account that can do everything is a positioning fact. A **market surveillance authority**, the national body that polices the Act, could read Wall-E's second lane (band B, for requests outside its fixed list, each written out by one human super admin and approved by another) as "the purpose is any administration action, with supervision". That reading would collapse the exemption ([../10-eu-ai-act.md#315-two-things-super-admin-does-and-does-not-change](../10-eu-ai-act.md#315-two-things-super-admin-does-and-does-not-change)).

The design's answers are real, but they are evidence of behaviour, and the guidelines test purpose as stated. The answers are four. A list of operations that are always refused, in every one of Wall-E's three lanes (the fixed list, band B, and the hand-off of console-only work to a human), owned outside the agent's own code. Band B permanently limited to a human approving each action. A mandatory reference to the human decision on any band-B write touching a person. And a count, checked against Google's own records, of robot actions outside the fixed list, with a target of zero. Super Admin appears in the technical file and as risk number one in the risk register, never in the purpose paragraph.

Two smaller weaknesses sit behind it, as re-verified on 2026-09-18. The suspension family currently leans on the exemption's condition (b), "improves the result of a previously completed human activity", whose worked examples are about polishing drafted text; carrying out a suspension fits condition (a), a narrow procedural task, better. And the whole claim is signed against **draft** guidelines; the final text is expected by the end of 2026.

### Why "bulletproof" cannot be promised, and what is promised instead

The owner's objective asked for a platform that is "EU AI Act bulletproof". The design declines that as a promise, because no provider can promise how a regulator will read a law whose guidelines are still draft and whose standards are not yet published.

What **can** be said: the design contains most of the engineering a high-risk programme would need, for a system that claims not to be high risk. A record of every action written before the action happens, kept 400 days, with an independent copy outside the tenant; a model-free watcher with the power to halt; an autonomy ladder on which every step up is a pre-declared change with evidence; a publication gate that makes classification a precondition of existence; and a measurement loop that doubles as the ongoing watch the Act asks a provider to keep once a system is in use ([../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean)).

What **cannot** be promised, the eleven residuals on the record:

| # | What stays open | Who closes or narrows it |
|---|---|---|
| R1 | The exemption is claimed against draft guidelines | Legal re-runs the assessment within 90 days of the final text |
| R2 | No **harmonised standard** (a European technical standard that, once cited in the Official Journal, lets a builder presume compliance) exists; none is cited on 2026-09-18 | Nobody's to produce; the design assesses against the articles themselves |
| R3 | How an authority will read licence reclaim by inactivity | The DPO and legal answer P18 |
| R4 | The Super Admin grant is the fact most likely to be held against the narrow-purpose reading | The purpose paragraph in five places, the hard-denied list in code, the reconciled count at zero |
| R5 | Above the level where a human approves each action, oversight rests on Eve, not on a natural person | Drill records, veto statistics, per-family caps |
| R6 | The technical documentation does not yet match the system | The frozen snapshot at Stage 1 (P130) |
| R7 | Hundreds of agents multiply every row | The register export produced by the tooling |
| R8 | The written position with Google and Google's model documentation are not on file | The supplier file (P32) |
| R9 | An invisible mark inside AI-written text, saying a machine wrote it, is Google's job to add and is unverified | Google's written confirmation per model version |
| R10 | `eve-advisor`'s class | Legal (P19) |
| R11 | Penalty exposure is real now for Articles 4, 5 and 50, and the first evidence of compliance with Article 50 does not exist until the first message is sent | The first message under the mechanism, at Stage 1 |

The phrase the platform uses instead of "bulletproof": *it promises the mechanisms and the evidence, and lists what the regulator or the guidelines still decide*.

## 2. TISAX in plain words

### What it is and who runs it

**TISAX** (Trusted Information Security Assessment Exchange) is the automotive industry's shared way of checking a supplier's information security once, so that every car maker can rely on the same result. It is run by the ENX Association on behalf of the VDA, the automotive industry association that owns the questionnaire. An independent audit provider assesses a **site** against a questionnaire called the VDA ISA (Information Security Assessment), scores each control on a **maturity** scale from 0 to 5, and the site earns a **label** if it reaches the target, which for most controls is maturity 3, "established": defined, documented and actually followed. A result is valid for three years ([../11-tisax.md#1-tisax-on-2026-09-13-verified](../11-tisax.md#1-tisax-on-2026-09-13-verified)).

Two versions of the questionnaire matter. VDA ISA 6.0.3, published 2024-04-25, is in force. Its successor, VDA ISA2027, was published 2026-07-01 and is the basis of every assessment ordered from 2027-01-01; the last day to order under the old version is 2026-12-31. Because nothing here is built in 2026, any assessment covering this platform will be ordered in 2027 or later, so the design is mapped against ISA2027 with a cross-reference to 6.0.3. `Assumption:` the control numbering is unchanged between the two; the ISMS confirms on the published comparison when it orders.

One thing the platform cannot do is earn a label. A label belongs to a site. The platform is one asset inside the security management system of the site that operates it, and it must be assessable there at maturity 3 on every control that applies.

### The label and level we aim at

| Element | Target | Status |
|---|---|---|
| Confidentiality label | **Confidential** | `Assumption:` (P133, proposed). It rises to "Strictly confidential" only if the ISMS classes the robot's audit log, the content logs, the sign-in logs or chat history as secret, which would also raise the level and reopen three encryption and sovereignty decisions |
| Availability label | **None** | Wall-E, Eve and Mo are not critical services; the Admin console worked by a human is Wall-E's continuity plan |
| Assessment level | **AL2**: the auditor checks the site's self-assessment for plausibility, reviews evidence and interviews by video call | AL2.5 (full remote) accepted if the auditor proposes it; AL3 (on site) only if the label rises |
| Scope location | ***tbd***: the site whose ISMS operates the platform | The ISMS names it (P20). Google, the witness organisation and every third party are external IT services of that scope, never sites of their own |
| Questionnaire | ISA2027, with the 6.0.3 cross-reference | The ISMS confirms |

The **ISMS** is the information security management system: the organisation's security governance function, which names people to roles, enters risks in its register and places the assessment order ([../11-tisax.md#2-the-target--label-level-scope-catalogue-p133](../11-tisax.md#2-the-target--label-level-scope-catalogue-p133)).

Google is itself a TISAX participant. Its cloud regions and Workspace data regions were assessed and carry the "Strictly Confidential", "Very High Availability" and "Information with Very High Protection Needs" labels, and the region the platform uses, `europe-west1`, is on the list. But Google's result names regions, not services, so which of the individual Google services the platform uses are covered is *tbd* until the ISMS retrieves the full result over the ENX portal (P32, P135). Google's public web page is not evidence.

### What is in scope

The questionnaire has three parts, called **modules**. The Information Security module applies in full. The Data Protection module does not: it is written for a company processing a customer's personal data on that customer's behalf, and this platform processes the organisation's own employees' data for the organisation itself. The DPO uses that module as a checklist anyway. The moment a future agent processes a customer's or a car maker's data on their behalf, the module becomes an objective for that agent, and a field on the agent's register row enforces it (P134). The Prototype Protection module, about unreleased vehicles and parts, does not apply; a dated negative determination of 2026-09-13 records that ([../11-tisax.md#3-module-scope--data-protection-and-prototype-protection-p134](../11-tisax.md#3-module-scope--data-protection-and-prototype-protection-p134)).

### Why Super Admin is a deviation, and what the signed record says

Control 4.2.1 of the questionnaire is **least privilege**: every account holds only the rights its task needs, approved, reviewed and revoked. A machine account holding Super Admin, a role that cannot be narrowed, cannot meet that control as written. So the platform records a **deviation**: a signed admission that one control is not met, why, what carries the risk instead, and under what conditions the exception is accepted. Two neighbouring controls are met, not deviated: strong authentication for privileged accounts (4.1.2) and logging of privileged activity (5.2.4) ([../11-tisax.md#61-what-the-deviation-is-in-isa-terms](../11-tisax.md#61-what-the-deviation-is-in-isa-terms)).

The assessor will also cite Google's own guidance, that super admins should be few, human and not used daily. The answer is that the robot's daily use is bounded to its catalogued lane and its human-approved lane, every action is attributable to a human prompt or a catalogued trigger, and no super-admin-class operation is ever autonomous.

The record is one file, `decisions/2026-09-13-wall-e-holds-super-admin.md`, with sections in a fixed order: Decision, Deviation statement, Residual risk, Compensating controls, Precondition rule, Review, Signatures ([../../../decisions/2026-09-13-wall-e-holds-super-admin.md](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)). What it says, in plain words:

| Section | What it says |
|---|---|
| Decision | Wall-E holds Super Admin, decided by the platform owner on 2026-09-13 |
| Deviation statement | Least privilege is not met; what carries it instead is the three lanes, the two signed lists of operations, the split of permissions across two services, the autonomy ladder, Eve, the quarterly roster review and the switch that removes the role |
| Residual risk | A leaked token or an interactive login on the robot's account is a **tenant compromise**, a takeover of the whole Workspace, with a path into the cloud organisation including Eve's own project. Severity 1. Nothing prevents it; custody, the permission split and detection within minutes bound it |
| Compensating controls | Thirteen conditions, every one a precondition of the grant, none deferred, plus four checklist rows: a penetration test with no open critical or high finding, the DPIA started and the works council informed, a crisis rehearsal, and witnessed custody of the hardware keys |
| Precondition rule | The role is granted only when every row is green. After the grant, one red row is a severity-2 finding with 30 days to fix; two red rows at once, or the detection, hygiene or second-human row red at all, is severity 1 and the on-duty human super admin removes the robot's Super Admin until it is green again. "The role exists only while its compensations do" |
| Review | Reviewed quarterly with the roster; re-signed at every Wall-E stage transition and when a compensation's grade changes; it expires with the assessment result (three years) or earlier on any severity-1 credential incident. The TISAX page words the incident case as a re-signature rather than an expiry; the record's own text is followed here |
| Signatures | The platform owner decides; the **security reviewer** signs, a person who is not the platform owner, because the questionnaire forbids signing off one's own exception; the ISMS enters it in the site's risk register |

On 2026-09-18 the decision is made and the deviation is **not signed**: no security reviewer exists yet, and the ISMS has entered nothing. Every one of the thirteen rows is not built, not signed, not drilled, not run or not named on the day of signing ([the record's Compensating controls table](../../../decisions/2026-09-13-wall-e-holds-super-admin.md#compensating-controls)).

The honest sentence the assessor should hear first: about half of the TISAX mapping is documentation the platform writes now; the other half is controls that do not exist on 2026-09-18 and cannot be claimed by writing. And an assessor may still refuse maturity 3 on least privilege for a super-admin robot, however good the compensation is ([../11-tisax.md#0-what-this-page-decides-in-one-paragraph](../11-tisax.md#0-what-this-page-decides-in-one-paragraph)).

That is why the sentence **"Wall-E is safe as a super admin"** is never to be used in any report, slide or message about the proof of value or the three-day build. Those are the two smaller ways of starting: the three-day build is a three-day demonstration on made-up accounts, and the proof of value is a weeks-long trial on the real tenant with no robot holding any admin role (both on [06-three-ways-to-start.md](06-three-ways-to-start.md)). Neither of them gives any agent Super Admin, so neither produces one piece of evidence about super-admin containment. Only the full build owns the grant and its gate.

The second thing most likely to stop an assessment is **separation of duties** (control 1.2.2): the rule that the person who requests a thing is not the person who approves it, and the person who signs an exception is not the one who benefits from it. On 2026-09-18 every role on the platform is one person. The design turns that into a count the gate enforces: one distinct human at the read-only stage, three at the first write, four at the super-admin grant, four plus a bought round-the-clock detection desk once Wall-E acts autonomously; five is the clean state ([../11-tisax.md#72-the-minimum-per-stage](../11-tisax.md#72-the-minimum-per-stage)). [04-people-and-decisions.md](04-people-and-decisions.md) says who those people are.

### When the assessment is ordered

The ISMS orders the assessment when the label, the scope and every accepted risk with its signed acceptance exist. That sits in the register's "later" gate group, after the grant, together with the legal register and the answers about Google's per-service coverage. Before the order: an internal audit by the ISMS's auditor, never the platform owner, and no open finding on separation of duties or least privilege. An accepted risk without its signature stops the order ([../12-open-decisions.md#6-later](../12-open-decisions.md#6-later)). Earliest plausible timing, `Assumption:` mid to late 2027, after Wall-E's first write.

## 3. Personal data in plain words

### Who is responsible

Under the **GDPR**, the General Data Protection Regulation, the **controller** is whoever decides why and how personal data is processed. The platform administers the organisation's own tenant and its own employees' accounts, so the organisation is the controller and the platform is its internal processing. The frame is the organisation's existing data-protection programme, not a new regime for AI ([../brief/26-personal-data-and-employees.md#221-the-position-controller-and-internal-processing](../brief/26-personal-data-and-employees.md#221-the-position-controller-and-internal-processing)).

### What data about employees is touched, and by whom

| Who | What it touches | From when | The bound |
|---|---|---|---|
| Wall-E, reading | Every employee's directory record, licence, group memberships and administration history | Stage 0, the read-only stage | Read only; reports go to a human |
| Wall-E, writing | Group membership, profile fields, moves between organisational units, licences; and the two families that change whether a person can work: suspending an account and removing or assigning a licence | Stage 1, the first write | It suspends only when HR or a named operator has already decided. That suspension, and any write on a person's account through the broad band-B lane (requests outside its fixed list), must cite the decision record or the lane refuses (P125). Restoring an account is always human-approved |
| Eve | The activity of every human super admin and admin-role holder, the platform owner and the second human included: administration, sign-in, token, single-sign-on, group and reporting **metadata**, never content | Its first run, before Wall-E exists | Findings go only to the second human, the security reviewer and the incident commander; never to the person they concern |
| Mo | Aggregates over surrogate keys (a random token standing in for a person), minimum group size 5 (`Assumption:`) | Its first metric | An aggregate over one surrogate is a person; who may read the per-operator self-grading figure is open (M-3) |
| Operators and approvers | Their prompts in chat history and content logs, their identity in every audit row, their training records | Their first prompt | A poor self-grading score opens a review item, never an automatic consequence for the person |

The residual stated plainly: a wrongful suspension can last the hold window plus the human approval of the restore, up to four business hours ([../brief/26-personal-data-and-employees.md#224-the-actions-that-affect-employees-and-how-they-are-bounded](../brief/26-personal-data-and-employees.md#224-the-actions-that-affect-employees-and-how-they-are-bounded)).

### Eve watching the administrators is monitoring of employees

Eve's job, from its first run and before Wall-E exists, is to watch every human super admin. Super admins are employees. Watching what they do at work is a "monitoring system at the work place" in the words of GDPR Article 88, whatever the AI Act says about Eve. So Eve needs a record from the DPO before any of its jobs is deployed: the purpose (detecting misuse of tenant-wide privilege), the subjects (the committed roster and every live admin-role holder), the data (metadata only), the retention (400 days in Eve's own store plus the copy in the witness organisation) and the recipients. That record is decision P154 in the full build and P199 in the proof of value, and the tooling keeps Eve's jobs blocked until it is signed ([../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191](../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191)).

Eve's independence has a limit that belongs in this section. Inside the organisation's own cloud, a Workspace super admin can grant themselves administrator rights over everything, Eve's project included. So Eve's independence there is **detective**, not structural: it sees and reports, it cannot be put beyond reach. What is structural is the copy of evidence, the incident record and the pager that leave for the **witness organisation**, a separate Google organisation run by IT security. That is why the sentence **"Eve is independent"** is never to be used in any report, slide or message about the proof of value or the three-day build, the two smaller ways of starting: both have no witness organisation, and their Eve lives inside the reach of the administrators it watches ([03-how-it-is-kept-safe.md](03-how-it-is-kept-safe.md)).

The fear of being watched, which can change how administrators behave, is recorded as a fundamental-rights risk for the administrators, with no residual stated until legal classifies `eve-advisor` (P19).

### The DPIA, retention and the two gates

A **DPIA** is a data protection impact assessment: the DPO's written study of what a processing activity does to people and how the risks are reduced, required before the processing starts when the risk is likely high. Systematic monitoring of employees meets that bar (`Assumption:` the competent authority's list of high-risk processing names employee monitoring, as most do). On 2026-09-18 the DPIA is not started, and it is the longest lead item in the whole plan. The pages disagree on how far it must have got by the super-admin grant: the tier gate says "the DPIA", the grant checklist says "started". The re-verification of 2026-09-18 reads the law as requiring the assessment before the processing it covers, which puts the part covering Eve's monitoring and Wall-E's Stage 0 reads before those start. The DPO and the owner decide ([../brief/26-personal-data-and-employees.md#229-still-open](../brief/26-personal-data-and-employees.md#229-still-open)).

**Retention** is how long a store keeps data. The design fixes floors and ceilings by class:

| Class | Examples | Rule |
|---|---|---|
| Evidence | Audit rows, Eve's copies | 400 days floor; the DPO sets the ceiling (P13) |
| Record | Assessments, registrations, worker packs | 10 years |
| Content | Full prompt text, raw copies | 30 days ceiling; a de-identified copy for graders 30 days, 90 only if the DPO approves |
| Chat history | Prompts and answers in the Gemini Enterprise app | 30 days interim; the DPO settles it |
| Sign-in log | Every account's sign-ins, the densest personal-data store | 400 days `Assumption:`; legal basis legitimate interest, `Assumption:` the DPO confirms |

Evidence stores are locked: nothing in them can be deleted before the retention period ends. A store is locked only on the day the DPO records its ceiling, never before, because a lock cannot be shortened afterwards. An employee's request to delete data held in a locked store is answered by disclosure, not deletion; what makes that lawful is that locked stores hold only who asked, who approved, what changed and on whom ([../12-open-decisions.md#3-before-any-tier-w-agent-writes](../12-open-decisions.md#3-before-any-tier-w-agent-writes)).

Two people hold gates:

- **The DPO** (data protection officer, the organisation's independent data-protection expert) gates the retention ceiling before the first write (P13), the profiling answer with legal (P18), the graders' 90-day copy, the breach path (P101), the DPIA and records of processing, and the monitoring-of-administrators record (P154). The platform's staffing plan understates this load ([../brief/26-personal-data-and-employees.md#228-the-dpos-decisions-and-engagement-points](../brief/26-personal-data-and-employees.md#228-the-dpos-decisions-and-engagement-points)).
- **The works council**, the employees' elected representatives, is informed, and consulted where national law requires it, before Wall-E's first write on employee accounts, and that is a precondition of the super-admin grant (P129). The AI Act's own duty to inform workers binds high-risk systems only from 2027-12-02; the design adopts it now. The re-verification of 2026-09-18 found the trigger too late by one step: Eve's monitoring of administrators and the sign-in log go live before the grant, so the works council must be told before Eve's first stream, not only before Wall-E's first write. The register row still says "before Stage 1" ([../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129](../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129)).

Every employee can ask for an **explanation** of an action taken on their account. No decision on the platform is solely automated, but the path exists anyway: the employee asks HR, which obtains the frozen plan's reasoning, the state before, the trigger and the decision reference, with other people's data and the raw prompt removed, and answers within a number of business days still *tbd*. One unanswered request past the deadline is a finding.

### Jurisdiction

`Assumption:` the jurisdiction is unknown. Which country's labour and works-council law applies is *tbd*, because the operating site's country is not fixed, and no document names one. The design's default is "information before use", with a consultation record kept where the law asks for consultation. The re-verification of 2026-09-18 advised the stronger default, consultation, and consent where a works council has co-determination rights (a legal right to agree before a monitoring tool is introduced), with information only as the fallback if HR's written answer says so. Lead time under co-determination is months, not weeks ([../11-tisax.md#11-the-legal-and-contractual-register-p141](../11-tisax.md#11-the-legal-and-contractual-register-p141)).

## What this means for you

**If you are an employee.** Wall-E will never decide whether you stay, move or are promoted, and it never picks people by how they behave. If it suspends an account, HR or a named person decided first, and the record says who. You can ask HR why something happened to your account and get an answer. You will be told, in writing, before any agent acts on employee accounts. The rules above are the design's promises; they are not yet in force because nothing is built.

**If you are a works-council member.** You should expect to be asked before Eve starts watching the administrators and before Wall-E's first write, not after. Ask for the record permitting the monitoring of administrators (P154), the information pack, the employee notice, the explanation log and the fundamental-rights risk rows. Which country's rules apply is not yet fixed; press for that answer first.

**If you are a board member or sponsor.** Nobody can promise "EU AI Act bulletproof" or a TISAX label. Signing the super-admin deviation accepts that a leaked robot credential is a tenant compromise, and that the only person who may sign it is a security reviewer who does not exist yet. Three duties bind today regardless of the build, with real penalties: Articles 4, 5 and 50 of the AI Act.

**If you are a new engineer.** Classification is a gate, not a page. A register row without a class, a role, a signed purpose and, where the exemption is claimed, an assessment and a registration id cannot reach production, and Eve's jobs stay blocked until the DPO's record exists. Read [02-the-three-agents.md](02-the-three-agents.md) for what each agent is, then the canonical pages below.

## What is still undecided

| Id | What | Who |
|---|---|---|
| P23 | Which legal entity is provider and deployer | Legal |
| P28 | The signature on Wall-E's intended-purpose statement | Owner with legal |
| P18 | Whether inactivity-based licence reclaim is profiling | DPO and legal |
| P19 | `eve-advisor`'s class | Legal |
| P32 | The written position with Google and its per-service TISAX coverage | Platform owner, ISMS |
| P20 / P133 | Label, level and scope location | ISMS confirms |
| P134 | Module scope and the processor-role register field | DPO, ISMS |
| P136 | The deviation's two missing signatures | Security reviewer, ISMS |
| P140 | The risk register and its signed acceptances, including who owns R-01 (the pages disagree: platform owner or security reviewer) | Security reviewer, ISMS |
| P141 | The legal register, including the country whose law applies | ISMS, legal |
| P13 | The retention ceiling per class | DPO |
| P129 | The works-council trigger: before Stage 1, or earlier, before Eve's first stream | HR, DPO, legal |
| P154 / P199 | The DPO record on monitoring administrators (unsigned) | DPO, HR, the second human |
| P202 | Classification of every register row the proof of value writes | Legal's designate, DPO |
| P131 | Naming an AI compliance owner who is not the platform owner | ISMS, legal |
| no row | Whether the DPIA must be complete or only started at the grant: the tier gate says "the DPIA", the grant checklist says "started" ([../brief/26-personal-data-and-employees.md#229-still-open](../brief/26-personal-data-and-employees.md#229-still-open)) | DPO and owner |
| no row | The jurisdiction: which country's law applies is *tbd* on every page, and no document names one ([../11-tisax.md#11-the-legal-and-contractual-register-p141](../11-tisax.md#11-the-legal-and-contractual-register-p141)) | Legal |

## Where this is defined

- The EU AI Act page: [../10-eu-ai-act.md](../10-eu-ai-act.md), especially [§1 the regulatory state](../10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13), [§3 classification per system](../10-eu-ai-act.md#3-classification-per-system), [§4.10 workers](../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129), [§5 the evidence register](../10-eu-ai-act.md#5-evidence-register) and [§6 what "bulletproof" can and cannot mean](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean).
- The TISAX page: [../11-tisax.md](../11-tisax.md), especially [§2 the target](../11-tisax.md#2-the-target--label-level-scope-catalogue-p133), [§3 module scope](../11-tisax.md#3-module-scope--data-protection-and-prototype-protection-p134), [§6 the deviation record](../11-tisax.md#6-the-super-admin-deviation-record-p136), [§7 separation of duties](../11-tisax.md#7-separation-of-duties-and-the-staffing-minimum-per-stage-p137), [§10 the risk register](../11-tisax.md#10-the-risk-register-p140) and [§11 the legal register](../11-tisax.md#11-the-legal-and-contractual-register-p141).
- The decision record: [../../../decisions/2026-09-13-wall-e-holds-super-admin.md](../../../decisions/2026-09-13-wall-e-holds-super-admin.md).
- Personal data and employees: [../brief/26-personal-data-and-employees.md](../brief/26-personal-data-and-employees.md); the brief's chapters [24](../brief/24-eu-ai-act.md) and [25](../brief/25-tisax.md).
- The register of decisions: [../12-open-decisions.md](../12-open-decisions.md), gate groups [§4 before the super-admin grant](../12-open-decisions.md#4-before-the-super-admin-grant), [§5 before Stage 1](../12-open-decisions.md#5-before-wall-es-stage-1-and-its-later-stages) and [§6 later](../12-open-decisions.md#6-later).
- The objective and what the design declines: [../00-objective-review.md#1-the-objective](../00-objective-review.md#1-the-objective); [../01-hld.md#16-what-the-platform-does-not-do](../01-hld.md#16-what-the-platform-does-not-do).
- The two build paths that may never claim these outcomes: [../pov/README.md#12-never-to-be-used-in-any-report-slide-or-message-about-the-pov](../pov/README.md#12-never-to-be-used-in-any-report-slide-or-message-about-the-pov); [../3-day/README.md#11-never-to-be-used-in-any-report-slide-or-message](../3-day/README.md#11-never-to-be-used-in-any-report-slide-or-message).
- Next in this set: [06-three-ways-to-start.md](06-three-ways-to-start.md); every term in one place: [08-glossary.md](08-glossary.md).
