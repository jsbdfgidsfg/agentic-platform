# B. Document map

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14

## What this appendix gives you

By the end of this appendix you can find, for any chapter, the design pages that define its facts, which page is authoritative for what, where the build procedures and decision records live, and which pages are dated history. Terms are in Appendix A, Glossary.

## Precedence

The brief explains intent and defines no fact. **Where the brief and a design page disagree, the design page is authoritative and the brief is corrected.** Each element has one canonical home; other pages summarise and link. Where two design pages still disagree, the platform register records the difference in [12-open-decisions.md §7](../12-open-decisions.md#7-values-that-differ-between-pages). Its rows 10–14 stay open until the agent sets carry the platform's changes, which is the propagation stage of [01-hld.md §18](../01-hld.md#18-what-this-hld-requires-of-the-wall-e-eve-and-mo-sets) (P143).

## The platform set

The folder `platform/agentic-platform/` holds thirteen pages, 00 to 12 ([README](../README.md#documents)).

- **00, objective review.** It quotes the objective verbatim, derives requirements R1–R16 and names the reversals the objective forces. Its current positions live on 01–12 (see below).
- **01, the HLD.** The parent: thesis, primitives and grading rule, roles, tier gate, charter, standing constraints (Status), trust-boundary template, what the platform does not do and what the agent sets must change (§18). Decisions P1–P34.
- **02–11, the detailed pages.** Each detailed page owns one part of the HLD and records its own decisions: landing zone and tiers (P35–P47), the Gemini Enterprise environment (P48–P59), identity and privileged access with K7 (P60–P70), and registry and autonomy contract (P71–P80). The rest are gateways, Model Armor and perimeter (P81–P91), monitoring and incident response (P92–P103), data, logging and retention (P104–P114), supply chain, keys and recovery (P115–P124), the EU AI Act (P125–P132) and TISAX (P133–P141).
- **12, the register of record.** It lists P1–P143 in one sequence, grouped by the gate each decision blocks. P142 and P143 follow P141, and new rows append at P144. An id on any page means the row here.

Two shared pages sit outside the folder. [project-topology.md](../../project-topology.md#status) is the single authority for where each project and resource lives and for every grant that crosses a project boundary. Its rows are now inputs to the factory, and Wall-E decisions 42–52 live there. [gemini-enterprise.md](../../gemini-enterprise.md#status) has been a pointer page since 2026-09-13. It keeps only the tenant facts that step GE-0 of the baseline runbook records. The tenant app's baseline is page 03.

## The agent sets

Each set designs one of the first three tenants; fleet-wide content was lifted into the platform pages.

### Wall-E

[The Wall-E README](../../wall-e/README.md#documents) separates standalone documents from numbered pages.

- **[PREREQUISITES.md](../../wall-e/PREREQUISITES.md)** says what must be true before the first command.
- **[SETUP.md](../../wall-e/SETUP.md)** is the one executable build procedure, ending at Stage 0.
- **[ARCHITECTURE.md](../../wall-e/ARCHITECTURE.md)** is the service architecture for a pilot decision. It is also the home of the kill-switch table.
- **[setup/](../../wall-e/setup/README.md)** holds the `walle` automation. Its README says where the script differs from the documents.

The numbered pages 01–14 carry the HLD, identity, the LLD, flows, the autonomy ladder (05, which owns the ladder's rules), guardrails, the team contract (08) and decisions 1–52. Page 07, the build runbook, is kept only as a pointer to SETUP.md so that inbound links still resolve. Chapters 11–13 were promoted into platform pages 04, 05 and 06. Their agent-specific sections, such as the engine query lock in 12 §7, remain canonical.

### Eve

The [Eve README](../../eve/README.md#documents) lists nine pages: HLD, identity and key, the verifier, flows, stages, failure modes, onboarding runbook (07), contract changes CC-1..CC-37 (08) and open decisions (09). Its [reading order](../../eve/README.md#reading-order) starts with 01 and 05; security review continues with 02, 06 and 03, and a builder reads 05, then 08, 03, 04 and 07. The platform pages cite Eve's register as E-1..E-20, but Eve's own page holds E-1..E-21, with E-21 proposed ([12-open-decisions.md Status](../12-open-decisions.md#status); [eve/09](../../eve/09-open-decisions.md#the-twenty-decisions)).

### Mo

The [Mo README](../../mo/README.md#documents) lists eight pages: what Mo is, identities and access, the metrics contract, artefacts and proposals, staging, failure modes, the build runbook (07) and open decisions M-1..M-11 with the changes Mo forces on the other sets (08). Its [reading order](../../mo/README.md#reading-order) starts with 01 and 03; security review continues with 02, 06 and 04, and a builder reads 08 first, because three of its changes block Mo.

## Build procedures

There are four procedures:

- the tenant-app baseline in [03 §16](../03-gemini-enterprise-environment.md#16-runbook-bringing-the-environment-to-baseline)
- Wall-E's [SETUP.md](../../wall-e/SETUP.md)
- [Eve's onboarding](../../eve/07-build-runbook.md)
- [Building Mo](../../mo/07-build-runbook.md)

The runbook that creates each resource is set out in [project-topology.md §7](../../project-topology.md#7-which-runbook-creates-what). The agent runbooks run after the platform exists.

## Decision records

The reasoning for a decision lives on the page named in its register row. The answer lives in [wiki/decisions](../../../decisions/README.md) as a dated file. That directory is append-only: a later record supersedes an earlier one and never rewrites it ([12 §1](../12-open-decisions.md#1-how-this-register-works)). On 2026-09-14 it holds two records:

- **[P33, Wall-E holds Super Admin](../../../decisions/2026-09-13-wall-e-holds-super-admin.md).** The record's own index reads "accepted (deviation signatures pending)", while the register carries P33 as decided with signatures pending.
- **[P34, Eve's reporting path may reason](../../../decisions/2026-09-13-eve-reporting-path-may-reason.md).** Proposed.

## Pages kept as dated records

Three pages hold positions partly overturned since; cite them for what they state on their date, never for current design ([Wall-E README](../../wall-e/README.md#this-design-has-been-attacked); [00 Status](../00-objective-review.md#status)).

- **[wall-e/10](../../wall-e/10-adversarial-review.md)** states the weaknesses known in the design of 2026-09-08, the fixes the numbered pages now carry and what was knowingly accepted. Its findings about a narrow custom role describe a role that no longer exists.
- **[wall-e/14](../../wall-e/14-hld-challenge.md#verdict)** states, for the design of 2026-09-11, the alternatives weighed and why the architecture stood. The objective of 2026-09-13 closed the service-account option for Wall-E and voided verdict reason 4.
- **[00-objective-review.md](../00-objective-review.md#status)** is complete as of 2026-09-13. Some of its positions are stale, `eve-advisor` among them. Design pages do not depend on it for a current position.

The pointer page wall-e/07 belongs with these three.

## Chapter to canonical pages

| Brief chapter | Canonical pages | Register rows |
|---|---|---|
| 0 About this document | [README](../README.md), [12 §1](../12-open-decisions.md#1-how-this-register-works) | — |
| 1 Executive summary | [01-hld](../01-hld.md), [README](../README.md) | cites only |
| 2 The objective | [00 §1](../00-objective-review.md#1-the-objective), [01-hld §0.6](../01-hld.md#06-traceability-the-objectives-sixteen-requirements-and-the-register-ids-not-cited-elsewhere) | P15, P28 |
| 3 Problem and risks | [00 §2–§3](../00-objective-review.md#2-verdict), [01-hld "What this reverses"](../01-hld.md#what-this-reverses-and-what-it-costs), [topology §1](../../project-topology.md#1-why-four-projects) | P33 |
| 4 Principles | [01-hld Status, §0–§1, §16](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded) | P1–P34 context |
| 5 Architecture overview | [01-hld §3, §15](../01-hld.md#3-the-landing-zone), [topology §2–§3](../../project-topology.md#2-the-four-projects) | P45, P46, P60 |
| 6 Gemini Enterprise environment | [03](../03-gemini-enterprise-environment.md), [gemini-enterprise](../../gemini-enterprise.md) | P6, P48–P59 |
| 7 Landing zone and tiers | [02](../02-landing-zone-and-tiers.md), [topology](../../project-topology.md) | P35–P47, P142, P3, P4 |
| 8 Identity and K7 | [04](../04-identity-and-privileged-access.md) | P60–P70, P5, P7, P8, P24 |
| 9 Registry and autonomy contract | [05](../05-registry-and-autonomy-contract.md), [wall-e/05 §1, §6](../../wall-e/05-autonomy-ladder.md) | P71–P80 |
| 10 Gateways, Model Armor, perimeter | [06](../06-gateways-model-armor-perimeter.md), [wall-e/11](../../wall-e/11-prompt-security.md) | P81–P91, P3 |
| 11 Monitoring and incident response | [07](../07-monitoring-detection-incident-response.md) | P92–P103, P10, P11, P21 |
| 12 Data, logging, sovereignty | [08](../08-data-logging-retention-sovereignty.md) | P104–P114, P12, P13 |
| 13 Supply chain, keys, recovery | [09 §1–§3](../09-supply-chain-secrets-recovery.md#1-supply-chain) | P115–P120, P22, P142 |
| 14 Scale and AGI readiness | [09 §4–§5](../09-supply-chain-secrets-recovery.md#5-agi-class-containment), [01-hld §11](../01-hld.md#11-the-tier-model) | P121–P124, P25–P27 |
| 15 Wall-E | [wall-e 01, 02, 03, 05, 06, ARCHITECTURE, SETUP](../../wall-e/README.md#documents) | P33, P16, P29; Wall-E 1–52 |
| 16 Eve | [eve 01, 02, 03, 05, 06](../../eve/README.md#documents) | P34, P14, P15, P19, P123; E-1..E-21 |
| 17 Mo | [mo 01, 03, 04, 05, 06](../../mo/README.md#documents) | P30; M-1..M-11 |
| 18 The three together | [wall-e/08](../../wall-e/08-team-eve-mo.md#the-separation-that-makes-a-team-worth-having), [wall-e/04](../../wall-e/04-flows.md), [eve/08](../../eve/08-contract-changes.md), [mo/08](../../mo/08-open-decisions.md) | P143 |
| 19 Threat model | [wall-e/06](../../wall-e/06-security-guardrails.md), [01-hld §13, §15](../01-hld.md#13-the-three-agents-on-the-platform), [eve/06](../../eve/06-failure-modes.md), [mo/06](../../mo/06-failure-modes.md) | P4, P7, P8, P60, P140 |
| 20 EU AI Act | [10](../10-eu-ai-act.md), [mo/04 §1.8](../../mo/04-artefacts-and-proposals.md) | P125–P132, P19, P23, P28, P32 |
| 21 TISAX | [11](../11-tisax.md) | P133–P141, P32 |
| 22 Personal data and employees | [10](../10-eu-ai-act.md), [08](../08-data-logging-retention-sovereignty.md), [07](../07-monitoring-detection-incident-response.md) | P13, P18, P19, P126, P129 |
| 23 Operating model | [01-hld §0.3](../01-hld.md#03-who-exists-on-2026-09-13-and-the-roles-the-platform-needs), [11 §7](../11-tisax.md#7-separation-of-duties-and-the-staffing-minimum-per-stage-p137), [PREREQUISITES §2](../../wall-e/PREREQUISITES.md#2-people) | P137 |
| 24 Roadmap and cost | [01-hld §0.4–§0.5](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens), [SETUP](../../wall-e/SETUP.md), [eve/05](../../eve/05-stages.md), [mo/05](../../mo/05-staging.md) | P31, P143; spikes P3, P4, P57, P61 |
| 25 Decisions awaiting the owner | [12](../12-open-decisions.md), [decisions](../../../decisions/README.md), agent registers | all open and proposed rows |
| A Glossary | [01-hld §0.2](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded), [05 §1](../05-registry-and-autonomy-contract.md#1-vocabulary-four-things-that-are-not-each-other), [wall-e/13 §1](../../wall-e/13-agent-interconnection.md#1-seven-things-with-confusable-names) | — |

## Reading paths through the wiki

These paths run through the design pages; the paths through this brief are in Chapter 0, About this document.

- **Executive sponsor.** Read the [platform README](../README.md), then [01-hld](../01-hld.md) Status and "What this reverses and what it costs", then [§0.4](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens), and finish with [12 §4](../12-open-decisions.md#4-before-the-super-admin-grant).
- **Security architect.** Follow the nine-step [reviewer order](../README.md#reading-order-for-a-security-reviewer), then the Eve and Mo security paths above and [wall-e/06](../../wall-e/06-security-guardrails.md).
- **Builder.** Follow the ten-step [builder order](../README.md#reading-order-for-a-builder). Then read [PREREQUISITES](../../wall-e/PREREQUISITES.md), [SETUP](../../wall-e/SETUP.md) and [topology §7](../../project-topology.md#7-which-runbook-creates-what).
- **Data protection officer and works council.** Start with [10](../10-eu-ai-act.md) §3–§4, then [08](../08-data-logging-retention-sovereignty.md) §5 for retention, [11 §3](../11-tisax.md#3-module-scope--data-protection-and-prototype-protection-p134) for the TISAX module scope, and [eve/03](../../eve/03-lld.md) for what Eve records.
- **TISAX or AI Act assessor.** Start with [11](../11-tisax.md) §2, §5, §6 and §13, then [10](../10-eu-ai-act.md) §4 and the [decision records](../../../decisions/README.md).

## Key decisions and where to go next

This appendix decides nothing. The rows it points to most often are P33 (decided, deviation signatures pending), P34 (proposed) and P143 (proposed, the propagation stage). Every row still open is in Chapter 25, Decisions awaiting the owner; read next the [platform README](../README.md#documents) and the [register's §1](../12-open-decisions.md#1-how-this-register-works).
