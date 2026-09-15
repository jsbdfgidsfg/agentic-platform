# 4. The principles

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14

## What you will understand by the end

This chapter states the few rules every later design choice follows from. By the end you will know where a control is placed and why placement follows the people who exist rather than the ambition; the one test that decides whether a control may carry a safety argument or only produce evidence; the six containment primitives every agent receives; the constraints no page may loosen; why a decided premise is designed around rather than re-argued; what the platform promises each agent and what it demands in return; and the full list of what the platform refuses to do, each with its reason. Chapter 3, The problem and its risks, explains why the rules are needed; Parts II and III apply them. Mechanisms are left to the chapters named.

## 4.1 The thesis

The objective asks for enterprise-class security and monitoring across hundreds of agents. On 2026-09-13 the organisation that must run it is one administrator, with no security operations centre and no second super admin outside his own line. The design treats that as the central fact to design around, not an inconvenience to be staffed away later ([HLD §0.1](../01-hld.md#01-thesis)).

### The two ways to fail

The first way to fail is a platform shaped like a security operations centre (round-the-clock triage, two-person approvals everywhere) that nobody in the organisation can operate. Its alerts would go unread and its approvals would be granted by the person who requested them. The second is to take the controls hand-built for the pilot agent, call them "the platform", and let every later agent re-implement them. Each copy would drift, and none could be reviewed as a class. The design refuses both.

### Where a control sits

The answer is a placement rule. Every control Google can enforce once it is set, such as organisation policy, deny policies, Principal Access Boundaries, Model Armor floors, Binary Authorization, Security Command Center and aggregated log sinks, is set at the platform folder. There one person can own it, and every project beneath inherits it. Every control that needs a second person, or a desk that answers at any hour, sits in the tiers that need it, and those tiers do not open until the person or service exists. Staffing becomes a gate instead of a hope.

The rule also makes cost visible before anyone commits to it. A read-only assistant costs a register row and a factory run. A super-admin robot costs a witness organisation, a second super admin, a bought detection desk and a signed deviation (figures in Chapter 24, Roadmap and cost). And it says what "the platform" is: the folder, the factory, the register, the autonomy contract and the tier gate. Wall-E, Eve and Mo are its first three tenants and the proof that its rules can be met, not its definition.

### The tier as the unit of everything

The unit the thesis needs is the tier. A tier is at once a folder, a factory module, a monitoring baseline variant, a metric pack, a staffing minimum and a compliance gate ([HLD §11](../01-hld.md#11-the-tier-model)). The tier an agent is admitted to settles all six together, so nobody negotiates controls agent by agent. Tiers are lettered so they never collide with the ladder's trigger classes T0–T3: C classical, R read tools, W write agents, P privileged with the super-admin singleton P-SA, and X for AGI-class agents, not open. A future AGI-class agent is therefore a new tier with written opening conditions, not a new design. The tier model is register row P1, proposed; letters, admission test and mandatory controls are Chapter 7, Landing zone and the tier model.

## 4.2 Enforcement-grade and detection-grade

Every control carries one of two grades, and the grade decides whether it may carry a safety argument ([HLD §0.2](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded)).

### The three conditions

A control is enforcement-grade only when three conditions hold together: the action cannot proceed without a verdict from the control; the verdict is produced outside the agent's own process, by Google or by code in the action service or gateway that the agent cannot bypass; and a failure of the control stops the action. If any condition fails, the control is detection-grade: the action happens, and at best something independent sees it within a stated latency.

Each condition closes one escape. Without the first, an unscreened path exists and an attacker takes it. Without the second, a code change in the agent, or an injected instruction steering its generated arguments, removes the control. Without the third, the control vanishes exactly when it matters: a screen that skips its check when its service is unreachable is one outage from absent.

### What the grade does not measure

The grade describes placement and failure mode, not accuracy. Model Armor on the ingress gateway sits in the request path and fails closed, so it is enforcement-grade on the prompt channel it sees; Model Armor floor settings applied inline to the model call fail open when the service is unreachable, so they are detection-grade in every mode, blocking mode included ([06 §3.1](../06-gateways-model-armor-perimeter.md#31-the-layers-and-their-grades-made-platform-wide)). Neither placement makes the classifier right. A probabilistic content screen, whether a Model Armor classifier or a language-model judge, is never a trust boundary whatever its grade on a given path: a screen that is usually right is one an attacker can keep testing until it is wrong.

### Nothing detection-grade stands alone

A safety case may rest on an enforcement-grade control; a detection-grade control produces evidence and never a boundary. Detection matters greatly here (for the super-admin tier it is the primary control, as Chapter 11, Monitoring, detection and incident response, explains), but it is always paired with something that refuses. The design applies the rule to its own uncertain facts: a feature whose enforcement Google's documentation does not settle stays out of every safety case until a test answers the question (section 4.8, item 6). Demand D8 of the charter binds every tenant to the same rule.

## 4.3 The six containment primitives

Containment for any agent reduces to six primitives, numbered CP1 to CP6 so they are never confused with the register rows P1–P143. Each is a promise with a named enforcer and a grade ([HLD §0.2](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded)).

**CP1: a trust boundary the agent cannot redraw.** The factory creates the agent's principal, project, gateway, Model Armor floor and deny policy, governed at the folder; the agent's owner cannot loosen them. Folders, organisation policy, the factory's CI identity and Privileged Access Manager enforce it. Enforcement-grade, because a boundary its occupant can edit is only a preference.

**CP2: autonomy as data; humans raise, machines lower.** Autonomy is one manifest and two schemas; a promotion is a pull request whose evidence a validator recomputes, and the action service's ceiling module reads the result. Enforcement-grade in the action service. Autonomy held in prompts or scattered code cannot be audited, compared or lowered quickly. Chapter 9, Registry, governance and the autonomy contract.

**CP3: a capability ceiling outside the agent's process.** The model holds no credential; the action service is the only credential holder; ceilings are code in the action service and permissions the folder deny policy refuses, with the OAuth scope set as the outer limit Google enforces. Enforcement-grade. For the super-admin robot this is the one enforcement point left on the Workspace side (Chapter 15, Wall-E, the doer).

**CP4: a fleet kill switch outside any agent project.** One organisation-policy change and one deny rule stop every agent principal in the selected tier folders, drilled monthly. Enforcement-grade, though two of its levers count only as far as unresolved decisions allow. K7 is Chapter 8, Identity, privileged access and the fleet kill switch.

**CP5: a model-free monitor with halt authority.** The path that approves, halts, demotes or vetoes contains no model. Enforcement by absence: a CI check forbids a model client in the image, and a project-level service-usage denylist removes the Vertex AI API from Eve's project — set on the project, not the controllers' folder, whose other child, the reporting path, needs the API. That path may reason but writes reports and pages only, and nothing it writes feeds a verdict (P34, proposed). Chapter 16, Eve, the independent controller.

**CP6: evidence the judged thing cannot forge or silence.** Organisation-level sinks copy Google-written audit streams into a locked bucket and the SIEM export and, for the super-admin case, to the witness organisation, beyond the agent, its owner and the tenant's super admins. Detection-grade with an absence alarm: evidence stops nothing, but its silence is itself an alert, so an attacker who stops the logs causes a page. Chapters 11 and 12.

## 4.4 The standing constraints

Eight constraints sit above every page; no page loosens them ([HLD Status](../01-hld.md#status)).

- **No domain-wide delegation.** Delegation lets one credential act as any user; compromised, it impersonates everyone and the audit row names the victim, not the actor. Mechanism in Chapter 8.
- **The language model holds no credential and cannot approve.** The model reads text an attacker can reach (mail, tool results, peers). A credential in its reach is in the attacker's reach; an approval it can give is one the attacker can write.
- **The action service is the only holder of a Workspace credential.** One place where deterministic code decides and acts: one component to review, test, sign and halt.
- **Humans raise autonomy and machines lower it.** A raise widens what happens without a human, and a machine that can raise can be talked into raising. Lowering is safe to automate because its failure costs throughput, not harm.
- **No model produces an approval, a signature, a halt, a veto or a refusal.** Each is an authority act; made by a model it would be a probabilistic screen presented as a boundary. A model may narrate; it may not decide.
- **Mo holds no credential and reaches production only through a pull request a human merges.** The improver can change behaviour across agents at once; the human merge makes each change a reviewed, attributable act (Chapter 17, Mo, continuous improvement).
- **Safety interlocks are plain authenticated REST.** Reasoning under D12 in section 4.7.
- **No secrets in the wiki.** The design is written for assessors, a data protection officer and a works council; a design holding secrets could not be shared with them.

## 4.5 Designing around a decided premise

Wall-E holding Super Admin on a dedicated, licensed user account is the owner's decision of 2026-09-13, register row P33, the only row marked decided ([decision record](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)). No page reopens whether the account holds the role; pages ask only how it is contained ([HLD Status](../01-hld.md#status)). A premise re-argued on every page yields controls that assume a narrow role beside controls that assume Super Admin, and nothing buildable.

Designing around a premise is not accepting it uncritically. The design writes down the safety the choice removes without softening (Chapter 3), turns least privilege from a claimed property into a signed deviation, makes thirteen compensations preconditions of the grant, makes the grant a gate with a checklist, enters the residual as row R-01 of the risk register, and records that a TISAX assessor may still refuse maturity 3 on least privilege. On 2026-09-14 the security reviewer's and the ISMS's signatures on the deviation are pending, and the grant stays blocked until every precondition is green. The argument for the choice is Chapter 15; the deviation record is Chapter 21, TISAX.

## 4.6 Operability and the four cells

### A control the people cannot run is the wrong control

If a control cannot be operated by the people at the tier where it is required, the control is wrong, not the people ([HLD Status](../01-hld.md#status)). The tier gate enforces this, and it changes how targets are written. Below Tier P the detection desk is Security Command Center findings, routed to a person through a notification configuration because the service does not page on its own, plus absence alerts paging the platform owner; the target is "next business morning", written down as the honest number ([HLD §7.1](../01-hld.md#71-feeds-siem-and-security-command-center)). A fifteen-minute target nobody meets would give the sponsor false assurance and an assessor a finding. Likewise at Tiers C and R the platform owner's self-review is recorded as self-review. Faster targets come with the tier that buys the desk (Chapter 11; the desk per tier is Chapter 23, Operating model).

### The four cells

Every control on every design page names its **owner** (a role from the platform RACI), the **resource** it sits on, its **verification** (a job, a drill or a CI check, with a cadence) and its **failure behaviour** (fail-closed, fail-open with a page, or a detection with a latency). A control that cannot fill the four cells is not on the page ([README Status](../README.md#status)). Each cell removes one way to exist only on paper: without an owner nobody acts when it fires; without a resource it cannot be inspected and drifts; without verification on a cadence there is no evidence it still works, the first thing an assessor asks for; without a failure behaviour it cannot be graded, because section 4.2's grade is largely a statement about failure. The fleet kill switch shows the rule working: its failure behaviour is measured in the monthly drill rather than asserted, because one lever rests on an Assumption about how running Cloud Run instances respond.

## 4.7 The platform charter

The charter is the contract between the platform and each tenant: nine promises and twelve demands ([HLD §1](../01-hld.md#1-the-platform-charter)). The promises remove any reason for an agent team to build its own version of a platform control; the demands let every agent be reviewed against one list.

### What every agent is promised

On the day it is created an agent receives a project of its own, made by the factory in under an hour with APIs, identity, gateway, sinks, budget, labels and deny policy in place (PR1); an identity issued by Google, with no key, expiring daily (PR2); default-deny egress and screened ingress, so an injected prompt cannot reach a secret or the internet through it (PR3 — the default-deny egress is what enforces, since the ingress screen is Model Armor, never a boundary); and logs sent somewhere it cannot delete, with somebody paged if they stop (PR4). It is protected by a kill switch outside its project, drilled (PR5), and by autonomy that rises on evidence, never on the calendar, and only when a human raises it (PR6). It is spared re-arguing its compliance classification per auditor, because the gate does it once (PR7); implementing any control the tier above needs (PR8); and rewriting the ladder, validator or approval surface, which are services (PR9).

### What every agent must accept

Most demands follow from the standing constraints. D1: a register row (owner, tier, purpose, data classes, EU AI Act class, TISAX class) before the agent exists in any project; the factory refuses without it. D2: Agent Identity, a gateway binding and a factory-made project, with no exceptions below Tier P and dated exceptions in it; whether D2 is enforced by folder constraints or only a CI check waits on spike P4, half closed by P42. D3: no credential in the reasoning layer; an agent that writes does so through an action service that holds the credential and decides. D5: audit rows in the platform schema with the correlation keys, insert-only and written ahead. D6: every peer agent is principal type `agent`, at ladder level L0 for writes, tainted on receipt. D8: every feature graded, nothing detection-grade alone. D10: removable, so deleting the project removes the agent and nothing else, its evidence having already left. D11: no write on any repository, Artifact Registry, deploy identity, its own ladder or its own ceilings. Four demands need their reasoning stated.

**D4: never decide and act, never grade your own work, never loosen your own autonomy.** One rule in three forms: no component checks itself. If an agent's choice of action is also its permission, nothing can refuse the action, so the reasoning layer proposes and separate deterministic code decides. An agent measuring its own quality has the incentive and the opportunity to measure wrongly, so numbers are recomputed by a validator the proposer cannot reach and graded blind. An agent that can widen its ceiling has none. The charter rule, the contract validator and a humans-only raise path enforce it.

**D7: cross a project boundary only through a grant on the resource, never a project-level role.** A project-level role grants everything in the project today and whatever is added tomorrow; a resource grant names one thing. Only the second keeps reach enumerable, and only enumerable reach lets the design state what a compromise of each project reaches. The drift job asserts the anti-grants. The platform's own folder-level principals are named exceptions ([topology §3.1](../../project-topology.md#31-notes-the-table-cannot-hold)), explained in Chapter 5, Architecture overview.

**D9: re-qualification on every model pin change.** Evidence of good behaviour is evidence about one combination: prompt, model pin, framework version and Model Armor template version, the fingerprint tuple. When any member changes, the agent that earned the autonomy is not the one running. A change therefore resets every ladder cell above L3 to L3, where a named human approves each action, until evidence is gathered again. A model upgrade costs autonomy for a while, deliberately. Ladder in Chapter 9, fingerprint rule in Chapter 17.

**D12: safety interlocks as plain authenticated REST, never over an agent protocol.** Halt and approve must work when the model layer is wedged, hallucinating or looping ([Wall-E architecture §7.4](../../wall-e/ARCHITECTURE.md#74-the-interfaces-eve-consumes-and-why-they-are-plain-rest)). An agent protocol carries messages models generate and read, so the layer being stopped could screen, reformulate or ignore the interlock. A REST endpoint invocable only by named principals can be called by a deterministic job or a human and is refused to everyone else. Agent protocols suit delegated conversational work, not halt and approve.

## 4.8 What the platform does not do

The refusals are as much design as the controls; each closes an argument that would otherwise reopen agent by agent ([HLD §16](../01-hld.md#16-what-the-platform-does-not-do)).

1. **It does not make Eve's control path structurally unreachable by a super admin inside the tenant's organisation.** There a super admin can suspend Eve's account, revoke its token and re-filter the sinks, and nothing Google offers prevents it. Evidence, incident record and pager move to the witness organisation; the rest is called detective; relocating the control path is the recorded end state (P15, proposed: built when IT security operates the witness, gated on Tier X, not the grant). Chapter 16.
2. **It does not narrow a super-admin account; nothing in Workspace or Google Cloud can.** The perimeter is custody, scope split, a split control plane, detection latency and the witness, said openly rather than implying a boundary that does not exist.
3. **It does not automate the Admin console under any robot session, by browser or computer use.** An interactive login on the robot account is an incident, the one control that survives Super Admin intact; automating the console would make it a lane that routes around the action service, where every check lives. Band C is instructions for a human, plus verification.
4. **It does not let any model produce an approval, a signature, a halt, a veto or a refusal.** A model may narrate and page a human at severity 2; nothing it writes is read by the gate. Reasons in sections 4.2 and 4.4.
5. **It does not evaluate model capabilities, detect deception or claim AGI containment.** Capability evaluation is the model provider's responsibility and deception-robust monitoring is research; the platform gates on measured behaviour within a catalogue. Tier X stays closed until its conditions hold (Chapter 14, Scale and AGI readiness).
6. **It does not count three unverified mechanisms in any safety case until answered:** the Principal Access Boundary for Cloud Run invocation, which it does not fence (P60, proposed, closing P9); the Admin console Context-Aware Access level, unverified for super admins (P7, open); and the deny policy's agent principal-set spelling (P8, spike narrowed by P61). Section 4.2 applied to the design's own gaps.
7. **It does not run a security operations centre.** It buys acknowledgement for Tier P, runs Google's detections for the rest, and feeds the organisation's own centre if one exists. One administrator cannot operate one, and section 4.6 forbids designing one he would have to. The SIEM choice is P10, open.
8. **It does not place the folder in Assured Workloads EU Data Boundary while the agent products are outside the package.** The package would refuse them or flag standing violations, a paper exception on the services the platform is built around; a compensating set applies instead (P110, proposed; revisit trigger P12, open; Chapter 12). The HLD names two products outside the package, Agent Gateway and Agent Registry ([HLD §8.2](../01-hld.md#82-sovereignty)), while page 08 and P110 name three, adding Agent Identity ([08 §7.1](../08-data-logging-retention-sovereignty.md#71-assured-workloads-eu-data-boundary-for-the-agents-folder-no-not-now-p110)).
9. **It does not host a second super-admin agent, a third-party agent without a supplier row, or any agent without a register row.** Each super-admin agent adds a path to tenant compromise and the compensations are sized for one, so a second P-SA row fails CI until the first is retired (Chapter 7). A third party's assurance cannot come from the platform's own tests, hence the supplier procedure (P138, proposed; Chapter 14). An agent without a register row is a shadow agent, and the row is the input to everything else (D1).
10. **It does not train or modify models.** Training, fine-tuning or substantially modifying a model could make the organisation a general-purpose AI model provider under the EU AI Act; making no modification avoids the threshold question entirely (Chapter 20, EU AI Act).
11. **It does not grant domain-wide delegation to anything.** Section 4.4.
12. **It does not back up Workspace.** The platform recovers its own control plane, compute and evidence (Chapter 13, Supply chain, keys and recovery); what an agent changes in Workspace is undone by the inverse operation its manifest declares per operation family, and beyond that by Google's own recovery ([09 §3.1](../09-supply-chain-secrets-recovery.md#31-classes-per-tier)).
13. **It does not run code execution below Tier X.** Code execution turns generated text into arbitrary behaviour, the capability that most needs a sandbox. Agent Runtime Code Execution is EU-resident but not adopted and is off fleet-wide; no organisation-policy constraint enforces that, so the absence is enforced by other means (P121, proposed). The Tier X sandbox is GKE Agent Sandbox, generally available since 2026-05-21 (P122, proposed); Tier X stays closed on its other conditions.
14. **It does not promise EU AI Act or TISAX outcomes.** It promises mechanisms and evidence; the regulator and the assessor still decide (Chapters 20 and 21).
15. **It does not create per-agent organisation sinks, registries, Mo instances or workforce pools, or hand-made cross-project grants after Stage 0.** Each would copy something the thesis sets once at the folder, and each copy drifts and needs its own review. The tenant gateway's registry in `GEMINI_PROJECT` is a CI-generated working set, not an inventory; a hand-made grant would sit outside the grant table the factory reads.

## Key decisions and where to read next

Register states on 2026-09-14: **P33 decided** (Wall-E holds Super Admin, designed around; deviation signatures pending); **proposed**: P1 (tier model), P15 (control path to the witness as end state), P34 (Eve's reporting path, report-only), P60 (closing P9, the Principal Access Boundary's grade), P110 (Assured Workloads not now), P121 and P122 (code execution), P138 (suppliers); **open**: P7 (Context-Aware Access on the robot), P10 (SIEM), P11 (Security Command Center Premium funding), P12 (Assured Workloads revisit); **spikes**: P4, half closed by P42 (custom constraints behind D2), P8, narrowed by P61 (deny-policy principal spelling).

Canonical pages: [HLD Status](../01-hld.md#status) for the standing constraints and the operability sentence; [HLD §0.1](../01-hld.md#01-thesis) and [§0.2](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded) for the thesis, the grading rule and CP1–CP6; [HLD §1](../01-hld.md#1-the-platform-charter) for the charter; [HLD §11](../01-hld.md#11-the-tier-model) for the tier as unit; [HLD §16](../01-hld.md#16-what-the-platform-does-not-do) for the refusals; [README Status](../README.md#status) for the four cells; the [P33 decision record](../../../decisions/2026-09-13-wall-e-holds-super-admin.md). In the brief, Chapter 5, Architecture overview, shows these principles as layers and trust boundaries, and Chapter 7 turns the tier into folders and mandatory controls.
