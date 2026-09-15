# 2. The objective and what it demands

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14

## What this chapter settles

By the end of this chapter you will have read the objective in the owner's words and will know the sixteen requirements drawn from it, the chapter that meets each, the eight literal readings the design qualifies or declines and why, and the demands the objective makes without stating them. This is the brief's only requirement-to-chapter map; later chapters point here.

## The objective, in the owner's words

Stated by the platform owner on 2026-09-13 and quoted as written, spelling included ([00 §1](../00-objective-review.md#1-the-objective)):

> Create a secure Gemini Entreprise environment and secure all agents through it (including agent identity, agent registry, model armor). If you think about other security element to secure autonomous agent, please add the correct path.
> Then, have 3 different agents. The first agent "Wall-e" is the doer and execute action based on a prompt by a human. The action will have the ability to any super admin level action of Google Workspace. In order to do that, Wall-E will have a dedicated user account, with a google license and super admin roles.
> The second is "Eve" that needs to control & report any misbehaviour of Wall-E. She won't have super admin access to control and should work independantly & autonomous. She needs to report to the human anything wrong.
> The thrid is "Mo" that work on continuous improvements of both Wall-E & Eve agent.
>
> The overall objective is to set up an agentic platform that can sustain hundreds of agents (classicial or autonomous) & host future AGI agent while ensuring a full proof security & monitoring for entreprise class. All of that must be EU AI Act bulletproof & TISAX compatible.
>
> Please review the entire documentation first & focus on the HLD. Then work on the detailed.

The text names mechanisms, outcomes and a method. The design treats the mechanisms as binding, turns each outcome into mechanisms plus evidence, and says where an outcome cannot be delivered as worded, because a promise it cannot keep would mislead the sponsor who signs for it.

## The sixteen requirements

The design restates the objective as sixteen requirements, R1 to R16 ([00 §1](../00-objective-review.md#1-the-objective)); Appendix A, Glossary, separates them from other R-numbered families.

### The platform

- **R1 — a secure Gemini Enterprise environment through which all agents are secured.** No agent reaches users, tools or data except through platform-owned controls, agent identity, the registry and Model Armor among them.
- **R2 — any other security element an autonomous agent needs, "with the correct path".** Missing controls arrive as enforced mechanisms, not recommendations.

### Wall-E

- **R3 — Wall-E is the doer and acts on a human's prompt.** An identifiable person is the origin of what Wall-E does.
- **R4 — Wall-E can perform any super-admin-level action of Google Workspace.** Literally, breadth with no upper bound inside the tenant.
- **R5 — a dedicated user account with a Google licence and super admin roles.** A licensed robot user holds Super Admin; a service account cannot, so the account type is fixed too.

### Eve

- **R6 — Eve controls and reports any misbehaviour of Wall-E.** Detection covers everything Wall-E can do, not only what it was designed to do.
- **R7 — Eve holds no super admin access.** The controller's power is observing and halting, never the controlled agent's privilege.
- **R8 — Eve works independently and autonomously.** Eve keeps working, and keeps its evidence, against the wishes of the agent it watches or its administrator.
- **R9 — Eve reports anything wrong to the human.** A named human reliably receives Eve's reports and can act on them.

### Mo

- **R10 — Mo continuously improves both Wall-E and Eve.** The improvement loop covers both without becoming a way to weaken the controller or approve its own proposals.

### Scale and assurance

- **R11 — hundreds of classical or autonomous agents.** Adding an agent is repeatable and cheap in people, not a re-run of hand-built controls.
- **R12 — future AGI agents.** A place, and conditions, for agents whose capabilities exceed their designers' foresight.
- **R13 — "full proof" security and monitoring at enterprise class.** Someone contracted to answer handles detection and response, at a stated latency.
- **R14 — EU AI Act "bulletproof".** Every system has a classification and the documentation and evidence that class requires.
- **R15 — TISAX compatible.** An assessor can rate the controls against the VDA ISA catalogue, with evidence.
- **R16 — the method: review all the documentation, focus on the HLD, then the detailed design.** The platform is decided before the agents' detail.

## Where each requirement is met

The design section behind each row is in the HLD's traceability table ([01 §0.6](../01-hld.md#06-traceability-the-objectives-sixteen-requirements-and-the-register-ids-not-cited-elsewhere)).

| R | Met in | Reading |
|---|---|---|
| R1 | Chapter 6, The Gemini Enterprise environment; agent identity in Chapter 8, Identity, privileged access and the fleet kill switch; the registry in Chapter 9, Registry, governance and the autonomy contract; Model Armor in Chapter 10, Agent Gateway, Model Armor and the perimeter | as stated |
| R2 | Chapter 7, Landing zone and the tier model; Chapter 12, Data, logging, retention and sovereignty; Chapter 13, Supply chain, keys and recovery; deny policies and the fleet kill switch in Chapter 8; the perimeter in Chapter 10 | as stated |
| R3 | Chapter 15, Wall-E, the doer: band A on the chat trigger | as stated; see the note below |
| R4 | Chapter 15: the three bands and the hard-denied list | qualified |
| R5 | Chapter 15: the robot account, its hygiene set, P33; the roster in Chapter 8 | as stated; the grant waits for its checklist |
| R6 | Chapter 16, Eve, the independent controller: detection catalogue and reporting path | qualified |
| R7 | Chapter 16; the robot accounts in Chapter 8 | as stated |
| R8 | Chapter 16: two-part independence and the witness organisation | qualified |
| R9 | Chapter 16: the reporting contract and the second human outside the Wall-E line; the role in Chapter 23, Operating model | as stated |
| R10 | Chapter 17, Mo, continuous improvement; separation in Chapter 18, How the three work together | as stated |
| R11 | Chapter 14, Scale and AGI readiness; the factory in Chapter 7 and the register in Chapter 9 | qualified |
| R12 | Chapter 14: Tier X and its opening conditions | declined for 2026 |
| R13 | Chapter 11, Monitoring, detection and incident response; the tier gate in Chapter 24, Roadmap and cost | qualified |
| R14 | Chapter 20, EU AI Act | "bulletproof" declined |
| R15 | Chapter 21, TISAX | qualified |
| R16 | Chapter 3, The problem and its risks (the earlier design and what stands); Chapter 24 (the propagation stage) | as stated |

Chapter 19, Threat model and residual risk, tests every answer.

**A note on R3.** Band B is chat-only, but Wall-E's ladder lets catalogued band A families run on scheduled, event and inbox triggers once each has earned it, scheduled runs acting on behalf of the agent owner ([wall-e 05 §3](../../wall-e/05-autonomy-ladder.md#3-trigger-classes)). The traceability table records no qualification of R3 for this, so the brief reads the human prompt as the origin of Wall-E's mandate rather than its only trigger. Wall-E will then act without a fresh human prompt, and that reading is the owner's to confirm (Chapter 25, Decisions awaiting the owner).

## Where a literal reading is qualified or declined

Eight requirements are not delivered word for word. For each: what the design delivers instead, why the literal reading cannot be delivered or defeats another requirement, and the decision that carries the position, in its state on 2026-09-14.

### R4 — "any super admin level action"

Read literally, R4 includes assigning admin roles, changing security posture, deleting administrators and removing Eve's access: a doer that can switch off its controller defeats R6 to R9. As a declared purpose, "any admin action on a prompt" also makes Wall-E an Annex III high-risk system (Chapter 3 states the regulatory problem; Chapter 20 the classification).

The design keeps the breadth but routes it through three bands ([01 §13.1](../01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa)). Band A, the catalogue of typed operations, is the declared purpose and the only band that can become autonomous. Band B carries uncatalogued work as a generic request, permanently approved by two different human super admins. Band C turns console-only work into instructions for a human. In every band a hard-denied list — escalation, blinding Eve or the alerting, minting or deleting administrators, unlisted spend among its rows — is refused however many approve ([wall-e 03](../../wall-e/03-lld.md#the-hard-denied-list)).

"Any" becomes "any, except what lets Wall-E escalate, blind its controller or cause permanent loss, and nothing autonomous beyond the catalogue". Breadth is paid for in human approvals, enforced by the action service's code, not Google (Chapter 3). The two lists are P29, open until the owner signs; the register describes them as hard-denied operations and protected principals ([12](../12-open-decisions.md#4-before-the-super-admin-grant)), the HLD as the hard-denied list and the operations reachable only through band B ([01 §13.1](../01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa)). Wall-E's intended purpose is P28: content proposed through P125, signature, by the owner with legal, open. The bands are Chapter 15, Wall-E, the doer.

### R6 — "any misbehaviour"

Eve detects with a deterministic catalogue over every stream it ingests, all six Workspace log streams included, and reconciles every robot event against Wall-E's audit rows; an unmatched event halts Wall-E. A catalogue cannot name what nobody foresaw, so a reporting path, `eve-advisor`, may use a model to describe the rest ([01 §13.2](../01-hld.md#132-eve--independent-controller-two-paths-a-witness-outside-the-tenant-a-second-human)).

That path is report-only by construction: nothing it writes is read by Eve's gate, Eve's reconciler or either Wall-E action service. Approving, halting, vetoing and demoting stay model-free (Chapter 4, The principles; the mechanism is Chapter 16). "Any" ends where enumeration ends: Eve halts on what is enumerated, reports beyond it, and declares as limits what Google never records and the settings Eve cannot read. The reporting path is P34, proposed; its AI Act class is P19, open with legal, and its paging rights wait on that answer.

### R8 — "independantly & autonomous"

Autonomy is met: Eve's control path runs and halts without a human in the loop. Independence is split: because a super admin can reach Eve's project, structural independence inside the tenant's organisation is declined as unachievable and is detective there, while what leaves for the witness organisation — evidence, incident record, pagers, an absence alarm — is structural (Chapter 16, Eve, the independent controller; [eve 01 §1](../../eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness)). The witness sees the deletion of Eve's project within fifteen minutes, not a forged approval; only relocating Eve's control path into the witness would stop that. The relocation is the end state P15, proposed, built when IT security operates the witness and gated on Tier X, not the grant. The witness itself, P14, open with IT security, is a precondition.

### R11 — "hundreds of agents"

The factory makes a project per agent, so projects are not the limit; people are. Tier W, agents that write to a system of record, is capped by named blind-grading capacity, and a Tier W register row without a named grader with declared hours is refused at admission ([02 §1.3](../02-landing-zone-and-tiers.md#13-mandatory-controls-per-tier--what-the-platform-enforces-and-what-the-agents-code-must-carry)). Hundreds is realistic for classical and read-only agents; writing agents are as many as graders allow, privileged agents stay rare by policy, and at most one holds Super Admin. The cap is P25, open, its number *tbd* until the first Tier W agent's first quarter (Chapter 14).

### R12 — "host future AGI agent"

Declined for 2026. Tier X is a closed folder that refuses every service until six written conditions hold — among them a capability-evaluation report per model pin, an AI-safety reviewer and the fleet kill switch drilled for six months — of which only the first, an EU sandbox at general availability, was met on 2026-09-13; the monitor condition is P26, open ([01 §11.5](../01-hld.md#115-the-honest-line); Chapter 14, Scale and AGI readiness). Capability evaluation is the provider's work and deception-robust monitoring is research, so the platform claims no AGI containment.

### R13 — "full proof security & monitoring for entreprise class"

Below Tier P, findings and absence alerts page the platform owner and are answered "next business morning", written down as such ([01 §7.1](../01-hld.md#71-feeds-siem-and-security-command-center)). Tier P and the super-admin singleton get a bought 24x7 desk: Google SecOps in the EU or the organisation's own SIEM, with a managed detection and response retainer (P10, open with IT security), severity 1 acknowledged within 15 minutes in business hours and 60 outside (Assumption: until the contract fixes them). With no SOC, a round-the-clock promise nobody is contracted to answer would be a log line. Nor does the design claim "full proof": detection never stands alone in a safety argument (Chapter 4).

### R14 — "EU AI Act bulletproof"

Declined as worded. No harmonised standard gives a presumption of conformity, an Art. 6(3) claim rests on draft guidelines, Annex III obligations are deferred to 2027-12-02, and the Super Admin grant is the fact most likely to be held against Wall-E's narrow-task reading. The platform promises mechanisms and evidence, and lists what the regulator or guidelines still decide: eleven residuals, each with its closing evidence ([10 §6](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean)).

### R15 — "TISAX compatible"

The target is the Confidential label (Assumption) at assessment level AL2 against ISA2027 (P20 proposed through P133; the ISMS confirms). The qualification is least privilege, 4.2.1: a machine Super Admin cannot show it, so it is a signed deviation whose compensations are preconditions of the grant (P136, proposed), and an assessor may still refuse maturity 3 on 4.2.1 ([11 §0](../11-tisax.md#0-what-this-page-decides-in-one-paragraph)). Separation of duties, 1.2.2, the item most likely to stop an assessment, is answered rather than qualified, by counting distinct humans per stage (P137, proposed; Chapter 23).

## What the objective demands without saying

### Controls the existing organisation can operate

The organisation asking for enterprise-class security is, on 2026-09-13, one administrator (Chapter 1, Executive summary; [01 Status](../01-hld.md#status)). The unstated demand is that every control has someone able to run it, because a control nobody operates is a promise the first audit breaks. No tier opens until the people and services it needs exist: classical and read-only agents start now; writing agents and the super-admin grant wait. Hence R13's qualification by tier. The principle is Chapter 4, The principles; staffing, Chapter 23, Operating model; the gate, Chapter 24, Roadmap and cost.

### Three agent designs brought into line with the platform

The three agents' existing designs assume a Wall-E that never holds Super Admin (Chapter 3), so they must change; the HLD lists the edits ([01 §18](../01-hld.md#18-what-this-hld-requires-of-the-wall-e-eve-and-mo-sets)) and P143, proposed, gives them owners and gates. The items that make the grant safe, Eve's observe-and-report layer and the witness among them, gate the grant; the rest, Mo's included, gate Wall-E's Stage 1. Until then agent and platform pages still differ, and rows 10 to 14 of the register's list of differing values stay open ([12 §7](../12-open-decisions.md#7-values-that-differ-between-pages)). The propagation stage is Chapter 24.

The objective's silence does not lift the standing constraints that already governed every agent (Chapter 4, The principles).

## Key decisions and what to read next

| Decision | State on 2026-09-14 | Bears on |
|---|---|---|
| P33 Wall-E holds Super Admin | decided by the owner; deviation signatures pending (P136 proposed) | R5, R15 |
| P29 the two lists | open, owner signs | R4 |
| P28 Wall-E's intended purpose | content proposed through P125; signature open | R4, R14 |
| P34 Eve's reporting path may reason | proposed | R6 |
| P19 `eve-advisor`'s AI Act class | open, legal | R6, R14 |
| P14 the witness organisation | open, IT security | R8 |
| P15 Eve's control path relocated to the witness | proposed, end state | R8 |
| P25 the Tier W grading cap | open | R11 |
| P10 SIEM and managed detection partner | open, IT security | R13 |
| P20 TISAX target through P133 | proposed; ISMS confirms | R15 |
| P137 distinct humans per stage | proposed | R15, implied demands |
| P143 the propagation stage | proposed | R16, implied demands |

Read next:

- [00 §1](../00-objective-review.md#1-the-objective), the requirement text of record; [01 §0.6](../01-hld.md#06-traceability-the-objectives-sixteen-requirements-and-the-register-ids-not-cited-elsewhere), the design section behind each row; [01 §16](../01-hld.md#16-what-the-platform-does-not-do), the refusals behind several readings; [12 §0](../12-open-decisions.md#0-the-register-in-one-screen), the register of record.
- Chapter 3, The problem and its risks, for what Super Admin breaks in the earlier design and the risk themes the brief answers.
