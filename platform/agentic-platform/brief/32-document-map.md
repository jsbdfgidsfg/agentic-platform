# B. Document map

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-18
- 2026-09-18: build procedures corrected — the one entry point is setup/README.md, with pov/ and 3-day/ beside it; SETUP.md, PREREQUISITES.md, eve/07 and mo/07 recorded as pointer pages since 2026-09-16 in the Wall-E, Eve and Mo bullets, the Builder reading path and chapter rows 15 and 24.

## What this appendix gives you

By the end you can find, for any chapter, the design pages that define its facts, which page is authoritative for what, where build procedures and decision records live, and which pages are dated history. Terms are in Appendix A, Glossary.

## Precedence

The brief explains intent and defines no fact. **Where the brief and a design page disagree, the design page is authoritative and the brief is corrected.** Each element has one canonical home; other pages summarise and link. Where two design pages disagree, the register records it in [12-open-decisions.md §7](../12-open-decisions.md#7-values-that-differ-between-pages); rows 10–14 stay open until the propagation stage of [01-hld.md §18](../01-hld.md#18-what-this-hld-requires-of-the-wall-e-eve-and-mo-sets) (P143) runs.

## The platform set

The platform folder holds thirteen pages, 00 to 12 ([README](../README.md#documents)).

- **00, objective review.** Quotes the objective verbatim, derives R1–R16 and names the reversals it forces; current positions live on 01–12.
- **01, the HLD.** The parent: thesis, primitives and grading, roles, tier gate, charter, standing constraints, trust-boundary template, non-goals and what the agent sets must change (§18). Decisions P1–P34.
- **02–11, the detailed pages.** Each owns one part of the HLD and its decisions, P35–P141 in page order; the table below maps them to chapters.
- **12, the register of record.** P1–P143 in one sequence, grouped by the gate each blocks; new rows append at P144. An id on any page means the row here.

Two shared pages sit outside the folder. [project-topology.md](../../project-topology.md#status) is the single authority for where each project and resource lives and for every cross-project grant; its rows feed the factory, and Wall-E decisions 42–52 live there. [gemini-enterprise.md](../../gemini-enterprise.md#status) has been a pointer page since 2026-09-13, keeping only the tenant facts step GE-0 records; the tenant app's baseline is page 03.

## The agent sets

Each set designs one of the first three tenants; fleet-wide content moved to the platform pages.

### Wall-E

[The Wall-E README](../../wall-e/README.md#documents) separates standalone documents from numbered pages.

- **[PREREQUISITES.md](../../wall-e/PREREQUISITES.md)**: a pointer page since 2026-09-16; what must be true before the first command is now [setup/01](../setup/01-prerequisites-and-conventions.md), [03](../setup/03-decisions-and-people.md) and [04](../setup/04-purchases-and-lead-times.md).
- **[SETUP.md](../../wall-e/SETUP.md)**: superseded on 2026-09-15 and a pointer page since 2026-09-16, never executed; the Wall-E build is now [setup/30](../setup/30-wall-e-workspace-side.md) to [39](../setup/39-wall-e-stage-0.md).
- **[ARCHITECTURE.md](../../wall-e/ARCHITECTURE.md)**: the service architecture for a pilot decision, and home of the kill-switch table.
- **[setup/](../../wall-e/setup/README.md)**: the `walle` automation; its README says why the script is not used.

The numbered pages 01–14 include the autonomy ladder (05, owner of the ladder's rules), guardrails (06), the team contract (08) and decisions 1–52. Page 07 is only a pointer, kept for inbound links. Pages 11–13 were promoted into platform pages 04, 05 and 06; their agent-specific sections, such as the engine query lock in 12 §7, remain canonical.

### Eve

The [Eve README](../../eve/README.md#documents) lists nine pages, from the HLD to the onboarding runbook (07, a pointer page since 2026-09-16), contract changes CC-1..CC-37 (08) and open decisions (09). Its [reading order](../../eve/README.md#reading-order) starts with 01 and 05; security review continues with 02, 06 and 03, a builder with 08, 03, 04 and 07. The E-1..E-20 versus E-1..E-21 citation gap is in Chapter 25.

### Mo

The [Mo README](../../mo/README.md#documents) lists eight pages, from what Mo is to the build runbook (07, a pointer page since 2026-09-16) and open decisions M-1..M-11 with the changes Mo forces on the other sets (08). Its [reading order](../../mo/README.md#reading-order) starts with 01 and 03; security review continues with 02, 06 and 04, and a builder reads 08 first, since three of its changes block Mo.

## Build procedures

One entry point: [setup/README.md](../setup/README.md) (42 files, order platform → Mo and Eve → Wall-E, 6–7 months to Stage 0). Beside it:

- the proof of value, [pov/README.md](../pov/README.md) (Tiers C, R and W; no Super Admin to any agent; hands over to setup/ with nothing torn down)
- the three-day build, [3-day/README.md](../3-day/README.md) (two people, six person-days; a demonstration, not compliance evidence; hands over to pov/)
- the tenant-app baseline in [03 §16](../03-gemini-enterprise-environment.md#16-runbook-bringing-the-environment-to-baseline), executed through [setup/19](../setup/19-gemini-enterprise-import-and-baseline.md)

[SETUP.md](../../wall-e/SETUP.md), [PREREQUISITES.md](../../wall-e/PREREQUISITES.md), [eve/07](../../eve/07-build-runbook.md) and [mo/07](../../mo/07-build-runbook.md) are pointer pages since 2026-09-16, superseded by the review of 2026-09-15 ([13](../13-setup-procedure-review.md)); none was ever executed. Which runbook creates each resource is [project-topology.md §7](../../project-topology.md#7-which-runbook-creates-what); the agent files run after the platform exists.

## Decision records

A decision's reasoning lives on the page its register row names; the answer is a dated file in the append-only [wiki/decisions](../../../decisions/README.md), where a later record supersedes and never rewrites ([12 §1](../12-open-decisions.md#1-how-this-register-works)). On 2026-09-14 it holds two:

- **[P33, Wall-E holds Super Admin](../../../decisions/2026-09-13-wall-e-holds-super-admin.md).** "Accepted (deviation signatures pending)" in the record's index; decided, signatures pending, in the register.
- **[P34, Eve's reporting path may reason](../../../decisions/2026-09-13-eve-reporting-path-may-reason.md).** Proposed.

## Pages kept as dated records

Three pages hold positions partly overturned since; cite them for their date, never for current design ([Wall-E README](../../wall-e/README.md#this-design-has-been-attacked); [00 Status](../00-objective-review.md#status)).

- **[wall-e/10](../../wall-e/10-adversarial-review.md)**: the weaknesses known in the design of 2026-09-08, the fixes now carried and what was knowingly accepted; its narrow-custom-role findings describe a role that no longer exists.
- **[wall-e/14](../../wall-e/14-hld-challenge.md#verdict)**: the alternatives weighed for the design of 2026-09-11 and why it stood; the objective of 2026-09-13 closed the service-account option and voided verdict reason 4.
- **[00-objective-review.md](../00-objective-review.md#status)**: complete as of 2026-09-13, with some stale positions, `eve-advisor` among them; no design page depends on it for a current position.

The pointer page wall-e/07 belongs with these.

## Chapter to canonical pages

| Brief chapter | Canonical pages | Register rows |
|---|---|---|
| 0 About this document | [README](../README.md), [12 §1](../12-open-decisions.md#1-how-this-register-works) | — |
| 1 Executive summary | [01-hld](../01-hld.md), [README](../README.md) | cites only |
| 2 The objective | [00 §1](../00-objective-review.md#1-the-objective), [01-hld §0.6](../01-hld.md#06-traceability-the-objectives-sixteen-requirements-and-the-register-ids-not-cited-elsewhere) | P15, P28 |
| 3 Problem and risks | [00 §2–§3](../00-objective-review.md#2-verdict), [01-hld "What this reverses"](../01-hld.md#what-this-reverses-and-what-it-costs), [topology §1](../../project-topology.md#1-why-four-projects) | P33 |
| 4 Principles | [01-hld Status, §0–§1, §16](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded) | P1–P34 |
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
| 15 Wall-E | [wall-e 01, 02, 03, 05, 06, ARCHITECTURE](../../wall-e/README.md#documents), [setup/30–39](../setup/README.md) | P33, P16, P29; Wall-E 1–52 |
| 16 Eve | [eve 01, 02, 03, 05, 06](../../eve/README.md#documents) | P34, P14, P15, P19, P123; E-1..E-21 |
| 17 Mo | [mo 01, 03, 04, 05, 06](../../mo/README.md#documents) | P30; M-1..M-11 |
| 18 The three together | [wall-e/08](../../wall-e/08-team-eve-mo.md#the-separation-that-makes-a-team-worth-having), [wall-e/04](../../wall-e/04-flows.md), [eve/08](../../eve/08-contract-changes.md), [mo/08](../../mo/08-open-decisions.md) | P143 |
| 19 Threat model | [wall-e/06](../../wall-e/06-security-guardrails.md), [01-hld §13, §15](../01-hld.md#13-the-three-agents-on-the-platform), [eve/06](../../eve/06-failure-modes.md), [mo/06](../../mo/06-failure-modes.md) | P4, P7, P8, P60, P140 |
| 20 EU AI Act | [10](../10-eu-ai-act.md), [mo/04 §1.8](../../mo/04-artefacts-and-proposals.md) | P125–P132, P19, P23, P28, P32 |
| 21 TISAX | [11](../11-tisax.md) | P133–P141, P32 |
| 22 Personal data and employees | [10](../10-eu-ai-act.md), [08](../08-data-logging-retention-sovereignty.md), [07](../07-monitoring-detection-incident-response.md) | P13, P18, P19, P126, P129 |
| 23 Operating model | [01-hld §0.3](../01-hld.md#03-who-exists-on-2026-09-13-and-the-roles-the-platform-needs), [11 §7](../11-tisax.md#7-separation-of-duties-and-the-staffing-minimum-per-stage-p137), [PREREQUISITES §2](../../wall-e/PREREQUISITES.md#2-people) | P137 |
| 24 Roadmap and cost | [01-hld §0.4–§0.5](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens), [setup/README](../setup/README.md), [pov/README](../pov/README.md), [3-day/README](../3-day/README.md), [eve/05](../../eve/05-stages.md), [mo/05](../../mo/05-staging.md) | P31, P143; spikes P3, P4, P57, P61 |
| 25 Decisions awaiting the owner | [12](../12-open-decisions.md), [decisions](../../../decisions/README.md), agent registers | all open and proposed |
| A Glossary | [01-hld §0.2](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded), [05 §1](../05-registry-and-autonomy-contract.md#1-vocabulary-four-things-that-are-not-each-other), [wall-e/13 §1](../../wall-e/13-agent-interconnection.md#1-seven-things-with-confusable-names) | — |

## Reading paths through the wiki

These paths run through the design pages; paths through the brief are in Chapter 0, About this document.

- **Executive sponsor.** The [platform README](../README.md); [01-hld](../01-hld.md) Status and "What this reverses and what it costs"; [§0.4](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens); [12 §4](../12-open-decisions.md#4-before-the-super-admin-grant).
- **Security architect.** The nine-step [reviewer order](../README.md#reading-order-for-a-security-reviewer), the Eve and Mo security paths above, [wall-e/06](../../wall-e/06-security-guardrails.md).
- **Builder.** The ten-step [builder order](../README.md#reading-order-for-a-builder), then [setup/README](../setup/README.md) (its §3 order, files 01 to 42), with [pov/README](../pov/README.md) or [3-day/README](../3-day/README.md) if a proof of value or a demonstration comes first, and [topology §7](../../project-topology.md#7-which-runbook-creates-what).
- **Data protection officer and works council.** [10](../10-eu-ai-act.md) §3–§4; [08](../08-data-logging-retention-sovereignty.md) §5, retention; [11 §3](../11-tisax.md#3-module-scope--data-protection-and-prototype-protection-p134), TISAX module scope; [eve/03](../../eve/03-lld.md), what Eve records.
- **TISAX or AI Act assessor.** [11](../11-tisax.md) §2, §5, §6 and §13; [10](../10-eu-ai-act.md) §4; the [decision records](../../../decisions/README.md).

## Key decisions and where to go next

This appendix decides nothing. The rows it points to most are P33 (decided, deviation signatures pending), P34 (proposed) and P143 (proposed, the propagation stage). Every open row is in Chapter 25, Decisions awaiting the owner; read next the [platform README](../README.md#documents) and the [register's §1](../12-open-decisions.md#1-how-this-register-works).
