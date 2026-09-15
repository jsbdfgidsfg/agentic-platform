# 25. Decisions awaiting the owner

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14

## What you will understand by the end

Nothing on the platform is built, and beyond the first two tiers nothing can be until a few people answer a few questions. By the end you will know what to do first, how a platform decision is made and recorded, which decisions are the owner's own and which wait for IT security, legal, the data protection officer (DPO), the information security management system (ISMS) or a test against Google's products, every unresolved point the brief raises, and every open row with who must act.

The register of record is [page 12](../12-open-decisions.md), and every state below is as it stood on 2026-09-14. The order in which the gates open, and their cost, is Chapter 24, Roadmap and cost. The roles are defined in Chapter 23, Operating model.

## First actions

The design is almost wholly proposed; what holds the first gate red is a handful of answers, and what holds the later gates red is mostly other people's lead time. The sequence below puts the owner's own answers first, because some of them change what the requests must say, and sends every request in the same month, because the longest of them sets the calendar.

### What the owner does alone this month

1. **Record the gate-counting rule.** Write down how an open row with a recorded fallback counts towards its gate (see "Rows that fit the gate rule awkwardly" below). Read literally, the rule keeps the first, second and grant gates red for reasons nobody can act on, so every other schedule waits on this answer. It has no register row yet; a new row would take the next free id from P144.
2. **Read the tenant's editions in the Admin console.** The Workspace edition decides whether the edition-conditional F1 feed exists, whether multi-party approval (P66) is available and which identity streams reach Google Cloud, which makes it a Stage 0 precondition. The Gemini Enterprise edition decides whether conversation retention can be changed from its 60-day default at step GE-6 (Chapter 8; Chapter 11; Chapter 12).
3. **Set P31**, the quota and per-tier budget amounts, or adopt the `Assumption:` numbers as his own in writing.
4. **Choose P22**, the git host and the audit of admin bypasses, which Tier W needs.
5. **Start Mo's toil baseline**: four weeks of measured toil for the top three admin tasks plus monthly operating hours, before Wall-E's first phase. It cannot be reconstructed once Wall-E runs (Chapter 17, Mo, continuous improvement).
6. **Decide where the P4 and P61 spikes run** before the folder exists (Chapter 24).

### The requests to send, by recipient

| Recipient | What to ask for | Lead time recorded | What it unblocks |
|---|---|---|---|
| DPO | P13, the retention floor and ceiling; P18 with legal; start the DPIA; plan the works-council information with the owner (P129) | the longest item in the plan | the evidence lock and the first Tier W write; F7 above L3; the grant |
| IT security | P10, the SIEM and managed detection partner; P11, SCC Premium funding; P14, the witness organisation; name the second human super admin and the security reviewer; quotes for SCC Premium, SecOps with the retainer and the penetration test | weeks to months, much of it bought or hired | Tier C; Tier W's reviewer; the grant |
| Legal | P23, the legal entity; P28, Wall-E's intended purpose, signed with the owner; P19, the class of `eve-advisor`; designate the AI compliance owner (P131) | not recorded | Wall-E's first write; `eve-advisor`; the grant |
| ISMS | role names under P137; confirm P133; enter P33's deviation; hear the owner on self-review at Tiers C and R and keep its answer in writing; request and file Google's TISAX assessment result share | not recorded | Tier W; the grant; the assessment order |
| Google | P7, whether Context-Aware Access binds super admins and API tokens; P32, per-service TISAX coverage and a written Art. 25 position; P5, Agent Identity on Cloud Run at general availability, re-read at each factory release | not recorded | the grade of Context-Aware Access; Wall-E's Stage 1; Tier R prod without exceptions |
| Procurement | Chrome Enterprise Premium licences (P63); ten hardware keys; five or six Gmail-bearing seats if none are free | procurement | Tier W access levels; Wall-E's Phase 3 |

### The first spikes

The platform owner runs P4's engine half and P8's principal-set spelling (via P61) first, on a throwaway engine, because both are in the first gate group and P8's spelling must be proven before the folder deny policy is applied. Where that engine lives before the folder exists is the open sequencing question above. After the first factory run, the first nonprod project runs P3's two spikes with the security reviewer, P42's CC-6 and CC-11 sub-spikes, and P57's throwaway-app spike with the Gemini Enterprise admin, ahead of its 30-day dry run. Chapter 24 gives the position held until each passes.

## How a decision is made and recorded

### One sequence, five states

Every platform decision has an id in one sequence, P1 to P143: P1–P34 from the high-level design (HLD), P35–P141 from the ten detailed pages in page order, then P142 and P143. Each row names its owner, the gate it blocks and where the reasoning lives. To be admitted, a row's "why it matters" must name one thing that cannot be built, verified or defended while the row is open; anything else is a preference and stays out.

A row is in one of five states ([§1](../12-open-decisions.md#1-how-this-register-works)):

- **decided:** the named owner decided, on a stated date.
- **closed:** a later row or a verified fact answered it. The row stays so the closing reference is not lost.
- **proposed:** a detailed page proposed a value. It stands, and the factory, validator and runbooks are written to it, until the named owner overturns it in writing.
- **open:** nobody has decided, and no page proposes anything beyond the HLD's recommendation.
- **spike:** a test on a throwaway resource in nonprod decides it, against pass criteria on the recording page.

"Proposed" lets the design move forward without pretending anything is signed. The price is that silence counts as consent: an owner who never reads a proposed row has accepted it. That is deliberate, and it is why this chapter names the owners.

### Who changes a row, and how a gate closes

Only a row's owner changes it, by a dated pull request on the register page. Once a row's gate has passed, a new row supersedes it rather than an edit. Loosening a fleet default (P77) needs the security reviewer's signature. New ids start at P144 and are never reused. No program answers a row: raising a level, widening a scope and answering a decision are human acts, recorded by hand.

Rows are grouped by the gate they block, in the order the gates come: §2 before the folder exists, §3 before any Tier W agent writes, §4 before the super-admin grant, §5 before Wall-E's Stage 1 and its later stages, §6 later. A row that blocks two gates sits in the earlier one. A gate is green when every row in its group is decided, closed, proposed or a passed spike; a single open row or unpassed spike keeps it red. The admission gate reads this state, so an unanswered decision shows up as a refused register row for an agent.

### Rows that fit the gate rule awkwardly

Six open rows either cannot close when their gate is evaluated or already carry a position the design works to. The register resolves none of them:

- **P31** (quota and budget amounts) is open in §2, yet work proceeds on `Assumption:` numbers.
- **P5** (Agent Identity on Cloud Run in production) is open in §2, yet work proceeds on dated service-account exceptions, and only Google can close it.
- **P24** (a workforce pool for operators) is open in §3, yet a pool is needed only if non-Google operators ever exist, and while none do nothing prompts an answer.
- **P25** (the Tier W cap per grader) is open in §3, yet its value is measured after the first Tier W agent's first quarter, and it blocks the second Tier W agent, not the first write.
- **P7** (Context-Aware Access on the robot) is open in §4 and waits on Google's answer, yet the design already counts the control as detection plus friction and never as part of the safety case.
- **P10** (the SIEM) is open in §4, yet P92 has the factory provision a default if P10 is unanswered when the rest of the Tier P checklist is green.

Read literally, the rule keeps §2, §3 and §4 red however much else is done. How an open row with a recorded fallback counts is the owner's first decision, and it is the one every other gate waits on.

### Two places for every decision

**The reasoning** lives on the page named in the row's "Recorded in" column, which is edited when the answer lands. **The answer** is a dated file in the append-only decisions directory, with the id on its first line ([decision log](../../../decisions/README.md)). This applies alike to P rows and the agents' own rows. On 2026-09-14 the directory holds two records:

- **[Wall-E holds Super Admin](../../../decisions/2026-09-13-wall-e-holds-super-admin.md), P33, accepted.** Decided by the owner on 2026-09-13. The file is also the TISAX deviation record (P136). The security reviewer's signature and the ISMS's risk-register entry are pending, and the grant stays blocked until every precondition in it is green.
- **[Eve's reporting path may reason](../../../decisions/2026-09-13-eve-reporting-path-may-reason.md), P34, proposed.** Dated 2026-09-13. It is accepted once the Eve owner and the security reviewer sign.

No Wall-E, Eve or Mo row has its own file yet. Anything else that looks settled is settled on a design page, not by a signature.

## The register in one screen

The register has 143 rows, each id once ([§0](../12-open-decisions.md#0-the-register-in-one-screen)).

Of **the HLD's 34 rows**, three are decided or closed (P33 decided; P2 closed by P35; P9 closed by P60), nine proposed, eighteen open (P5, P7, P10–P14, P17–P19, P21–P23, P25, P26, P29, P31, P32, with P28's signature and P24 for operators also open) and four spikes (P3, P4, P6 via P57, P8 via P61). Of **the pages' 109 rows**, 107 are proposed and two are spikes, P57 and P61; P42 carries three sub-spikes, and P89 and P90 wait on P3's first spike. Eleven proposed page rows depend on something open or carry an `Assumption:` value the owner must confirm: P39 (on P31); P52, P106 and P113 (on P13); P64 (on P24); P92 (on P10); P119 and P133 (on P20); P126 (on P18); and the values of P83 (the 99.5 % gateway SLO) and P117 (the vulnerability thresholds).

What is missing is a thin layer of signatures, bought services and tests. Most of it belongs to people who did not exist on 2026-09-13: no security reviewer, no Eve owner, no engaged DPO and no ISMS names (Chapter 23, Operating model).

## Who must answer what

The gate each row blocks is in the final table; this section says why each answer matters.

### The owner's own

- **The gate-counting rule, no row yet.** Until it is recorded, P5, P7, P10, P24, P25 and P31 keep their gates red by the letter of the rule.
- **P33, decided.** Wall-E holds Super Admin, and the design is built around that (Chapter 15, Wall-E, the doer). The deviation still needs signatures the owner cannot supply: TISAX rejects self-signature.
- **P29, open.** Sign the two lists that replace Wall-E's never-list: the hard-denied operations, refused in every lane, and the operations reachable only through band B with two human super admins ([HLD §13.1](../01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa)). This re-ratifies Wall-E's decision 4. The lists are the Art. 6(3) boundary; unsigned, the deviation record has no scope.
- **P28, signature open.** Sign Wall-E's intended purpose with legal, as P125 records it (Chapter 20, EU AI Act).
- **P68, proposed.** Approve the roster of three super admins: two humans, one outside the Wall-E administration line, plus `walle@`. The row is shared with that second human, so it cannot be completed until someone is named.
- **P34, proposed.** The owner holds the Eve owner role until the second human is named, and P34 also needs the security reviewer, so in practice it waits for both.

As platform owner he also owns the proposed rows P1 (the tier model), P15 (with IT security) and P16 (with the security reviewer).

### IT security

- **P10, open.** The SIEM, the organisation's own or a Google SecOps instance of the platform's, and a managed detection partner; either must meet the P92 contract.
- **P11, open.** Who funds and owns Security Command Center Premium, Tier C's detection desk; the platform line carries it as an Assumption until IT security takes it.
- **P14, open.** The witness organisation's domain, Cloud Identity edition (Assumption: a free edition) and billing linkage. Every claim that evidence sits beyond the super admins' reach rests on it.
- **P15, proposed, with the owner.** Eve's control path moving into the witness is dated now as the end state, so that inside-the-organisation independence is not mistaken for the final position; it gates Tier X, not the grant (Chapter 16, Eve, the independent controller).

### Legal and the DPO

- **P13, open (DPO).** The retention floor and ceiling per store and the conversation retention period. A locked bucket can never be shortened, so the evidence stores are locked, and the evidence immutable, only once the ceiling is recorded. Interim values are 30 days for conversations and a 400-day evidence floor, both Assumption (Chapter 12, Data, logging, retention and sovereignty).
- **P18, open (DPO and legal).** Whether reclaiming licences from inactive users (F7) is profiling. Until then `F7-inactive` stays at L3; a "yes" removes the operation from the catalogue and does not make Wall-E high-risk.
- **P19, open (legal).** The EU AI Act class of `eve-advisor`, which decides whether it may page at severity 2 and must be registered. P19 depends on P34.
- **P23, open (legal).** The legal entity holding the provider and deployer roles, which the Art. 26 obligations, the Art. 49 registration and P131's determinations all name.

The DPO's input checklist is in Chapter 22, Personal data, employees and the works council.

### The ISMS

- **P20 via P133, proposed.** The Confidential label (Assumption), assessment level AL2, no availability label, scope location *tbd*; without confirmation no assessment is ordered (Chapter 21, TISAX).
- **P131 and P137, proposed; names awaited.** An AI compliance owner designated by legal and engaged before the grant; the counted separation-of-duties minimum.
- **Also:** map the data classes to the organisation's scheme (P109), confirm P117's thresholds and P119's key exceptions, and enter P33's deviation in the risk register.

### Google, and the spikes that decide grades

These rows decide how a control is graded, enforcement or detection, not whether it exists. The four spikes, P3 (engine reach, which the grant needs through P90, and the Tier W perimeter), P4 (Agent Identity required on engines), P6 via P57 (the tenant app bound to `gemini-egress`) and P8 via P61 (the agent principal-set spelling behind the deny policy and KF-2), had not run by 2026-09-13. Chapter 24 gives the position held until each passes; Chapter 10, Agent Gateway, Model Armor and the perimeter, gives the perimeter models.

- **P7, open: verify with Google.** Whether the Admin console's Context-Aware Access level applies to super admins and can bind API tokens. Until then it counts as detection plus friction, never as part of the safety case (Chapter 8, Identity, privileged access and the fleet kill switch).
- **P5, open.** Agent Identity on Cloud Run at GA; it was Preview on 2026-09-10.
- **P32, open.** Google's TISAX coverage per service and a written Art. 25 position.

The Google pages behind each item are in the HLD's [sources](../01-hld.md#19-sources).

### Other open platform decisions

- **P12 (platform owner).** Date the "no" to Assured Workloads with a re-ask trigger, or it becomes permanent through neglect.
- **P17 (Eve owner).** Whether the Workspace BigQuery export lands in the witness, giving Eve's reconciliation source a copy outside the super admins' reach.
- **P21 (security reviewer).** The public agent-threat taxonomy that gives detection coverage a denominator. Nobody holds the role, so until one is named the platform owner holds it with self-review recorded.
- **P22 (platform owner).** The git host and the audit of admin bypasses; branch protection is what confines Mo to merged pull requests.
- **P24 (platform owner).** A workforce pool for operators, needed only if non-Google operators exist; the tenant app needs none (P51).
- **P25 (Mo owner, ISMS).** The Tier W cap as agents per named grader (Chapter 14, Scale and AGI readiness).
- **P26 (platform owner).** A second, EU-resident model family for Tier X's monitors.
- **P31 (platform owner).** The quota and budget amounts.

## The agent-set registers

Each agent keeps its own register, and the platform indexes it ([§8](../12-open-decisions.md#8-index-agent-set-decisions-and-the-platform-rows-that-touch-them)). A platform row **supersedes** an agent's decision when it replaces it for every agent, **depends on** it when it cannot pass its gate until that decision is answered, and **generalises** it when the decision stays true for its agent and becomes the fleet rule.

**Wall-E 1–52.** Decisions 1–41 are on [Wall-E's page](../../wall-e/09-open-decisions.md#decisions-changed-by-the-objective-of-2026-09-13); 42–52 are recorded on the [topology page](../../project-topology.md#8-open-decisions-this-topology-adds), which is why Chapter 5 calls decision 42 a topology decision. The objective of 2026-09-13 moved the answer of twenty-two of them; P33, for example, closes decision 26 by fact. A new Wall-E choice that is really a platform matter opens as a P row, not as 53.

**Eve E-1 to E-21.** [Eve's page](../../eve/09-open-decisions.md#the-twenty-decisions) holds twenty-one rows. E-21, where `grades_eve` lives, is proposed. E-2 (the Eve owner) and E-16 (Eve's credential) block the grant.

**Mo M-1 to M-11.** The rows are on [Mo's page](../../mo/08-open-decisions.md#the-eleven-open-decisions). Some Mo pages still cite them as 42–52, meaning M-1 to M-11 in order. P22 supersedes M-7, and P25 depends on M-4.

The dated pointer lines in each agent set come from the propagation stage (P143), which has not yet run.

## Where the pages still disagree

The register records conflicting values rather than silently picking one ([§7](../12-open-decisions.md#7-values-that-differ-between-pages)). Rows 1–9 are resolved and applied: conversation retention at 30 days until P13, HSM keys on the central log buckets, a description line rather than labels on registry entries, two sinks, a wider Binary Authorization scope, five core projects, a TISAX scope field, P4's engine half kept as a spike, and one home for silence budgets.

Rows 10–14 are open until the named agent pages carry the platform's value, mostly through the propagation stage: row 10, constraint spellings, nonprod folders and project ids; row 11, Eve's missing severity-1 rows and a principal-set spelling; row 12, an incident-note path that does not exist; row 13, de-identification, residency text, Eve's lock timing and graders' content; row 14, EU AI Act changes to Wall-E, Eve and retention.

## Every unresolved point the brief raises

Beyond the register's rows, the chapters carry points no row yet owns: open sequencing, values that differ between canonical pages, and facts still *tbd*. "Who decides" names the owner of the pages concerned where no row names one.

| Unresolved point | Raised in | Who decides | Gate it blocks |
|---|---|---|---|
| How an open row with a recorded fallback counts towards its gate | Ch. 25 | Platform owner | every gate, from the first |
| Where the P4 and P61 spikes run before the folder and factory exist | Ch. 24 | Platform owner | before the folder exists |
| The tenant's Workspace and Gemini Enterprise editions, *tbd* | Ch. 8, 11, 12 | Platform owner reads them | Tier C at GE-6; Wall-E's Stage 0; multi-party approval before the grant |
| An ordinary grant-checklist row still red on day 30 | Ch. 21 | Platform owner, in page 11 and P33's record | standing condition after the grant |
| K5 and K6 drilled quarterly on the sandbox twin, against checklist row 7's K6 record younger than 30 days | Ch. 15, 23 | Platform owner, with Wall-E's agent owner for the drill | the grant |
| Who the fifth human is in P137's clean state | Ch. 23 | ISMS | the grant, where four with a dated exception is the floor |
| Whether the DPIA must be complete or only started at the grant | Ch. 22 | DPO with the platform owner | the grant |
| Whether Wall-E's scheduled, event and inbox triggers qualify requirement R3 | Ch. 2 | Platform owner, in the HLD's traceability table | none recorded; bites at the first non-chat trigger |
| Blind sample drawn daily with `unsure` counted wrong (Eve) or weekly from a CI seed excluding it (Mo) | Ch. 17 | Eve owner and Mo owner | S3 entry, when the protocol takes force |
| Verification drift sends a family to L0, one level down with an incident, or L3 | Ch. 9, 18 | Wall-E's agent owner, with the Mo and Eve owners | the first autonomous family |
| Who registers an agent in the app: CI or `ge-admins@` through PAM | Ch. 6 | Platform owner | the first agent published above Tier C |
| Who removes an agent's `gemini-egress` entry in an emergency: `ge-admins@` or the CI identity | Ch. 6 | Platform owner | P57's enforcement, before the first Tier W publication |
| One evidence bucket per tier past about 25 agents (P114), where two views per agent fill a bucket at about 13 | Ch. 12 | Platform owner | the factory variable, before the buckets lock |
| Restore-drill age: a quarter, or younger than 30 days at the first promotion above L3 | Ch. 13 | Platform owner | Tier W promotions above L3 |
| Who owns the Model Armor folder floors, and the handover date to IT security | Ch. 10 | Platform owner with IT security | none recorded |
| Who owns risk row R-01: the platform owner or the security reviewer | Ch. 21 | Security reviewer and ISMS (P140) | the assessment order |
| The Tier W verifier owned by the platform owner until a second person exists | Ch. 11, 23 | ISMS (P137) | Tier W |
| Who writes role training: the platform owner or the AI compliance owner | Ch. 23 | ISMS, with the AI compliance owner | Tier W, since an untrained holder does not count |
| Mo's Eve reads between Mo's S1 and S2, or with Eve's layer before Wall-E's S0 | Ch. 24 | Mo owner | the grant |
| The Tier C baseline's dependence on the factory: none in the set's README, the `tenant-app` module in the runbook | Ch. 24 | Platform owner | Tier C |
| Wall-E's prerequisites page still dates the DPO question to Stage 3 | Ch. 24 | Wall-E's agent owner, through P143 | Stage 1 |
| Tier X conditions: four unmet (HLD §0.4) or five (§11.5) | Ch. 14 | Platform owner | Tier X |
| P29's second list: the protected principals (register) or the tier-`SUPER` two-person list (HLD §13.1, [Wall-E's guardrails](../../wall-e/06-security-guardrails.md#the-two-lists)) | Ch. 25 | Platform owner | the grant |
| The approval surface as a core resource ([page 04 §4.3](../04-identity-and-privileged-access.md#43-the-policy-and-its-grade--p9-answered)) or in each agent's project ([page 02 §5](../02-landing-zone-and-tiers.md#5-platform-core-what-is-shared-what-stays-per-agent-p45-p46)) | Ch. 25 | Platform owner | any family above L2 |
| Agent Registry Data Access logs, described differently on Google's two pages ([page 08 §11](../08-data-logging-retention-sovereignty.md#11-exceptions-and-what-could-not-be-verified)) | Ch. 25 | Platform owner, from the canary's first registry row | none recorded |
| The register cites E-1 to E-20; Eve's page holds E-1 to E-21 | Ch. 25 | Platform owner | none |
| Register rows 10–14 | Ch. 25 | Owners named in P143 | the grant; Stage 1 |

## What the register does not do

The register decides nothing itself; the content of each row is on its recording page. It holds none of the agent sets' decisions, only an index to them. It does not replace the P33 and P34 records, which carry the signatures. It does not track build status ([§9](../12-open-decisions.md#9-what-this-page-does-not-do)).

## Every open row and unsigned signature

Ordered by who must act, so the table doubles as the owner's list of whom to ask for what. "Gate" is the register section.

| Id | State | Who must act | Gate | What stays closed until answered |
|---|---|---|---|---|
| — | gate-counting rule, no row yet | Owner | every gate | a green gate wherever a fallback row is open |
| P29 | open | Owner | §4 | the grant; the deviation's scope |
| P28 | signature open | Owner with legal | §5 | Wall-E's first write |
| P68 | proposed; second human unnamed | Owner with second human | §4 | the grant |
| P33 / P136 | decided; deviation unsigned | Security reviewer signs; ISMS enters | §4 | the grant |
| P34 | proposed; unsigned | Eve owner, security reviewer | §5 | the `eve-advisor` build |
| P10 | open | IT security | §4 | the Tier P detection desk |
| P11 | open | IT security | §2 | Tier C |
| P14 | open | IT security | §4 | the grant; the witness |
| P13 | open | DPO | §3 | Stage 1 of any Tier W agent; the evidence lock |
| P18 | open | DPO and legal | §5 | F7 above L3 |
| P19 | open | Legal | §5 | `eve-advisor` paging; any registration |
| P23 | open | Legal | §6 | P131's determinations |
| P20 / P133 | proposed; confirmation awaited | ISMS | §6 | the TISAX assessment order |
| P131, P137 | proposed; names awaited | ISMS | §4, §3 | the grant; Tier W |
| P3 | spike | Platform owner, security reviewer | §3 | the Tier W perimeter; the grant, via P90 |
| P4 | spike | Platform owner | §2 | enforcement of D2's engine half |
| P6 / P57 | spike | Platform owner, Gemini Enterprise admin | §6 / §3 | the register as publication enforcement |
| P8 / P61 | spike | Platform owner | §2 | the folder deny policy; KF-2 |
| P7 | open; verify with Google | Platform owner | §4 | the grade of Context-Aware Access on `walle@` |
| P5 | open; verify GA | Platform owner | §2 | Tier R prod without exceptions |
| P32 | open | Platform owner, ISMS | §6 | Stage 1 (Art. 25); the assessment order |
| P12 | open | Platform owner | §6 | a dated re-ask of Assured Workloads |
| P17 | open | Eve owner | §5 | Eve's Stage 2 |
| P21 | open | Security reviewer; platform owner until named | §2 | a detection coverage figure |
| P22 | open | Platform owner | §3 | Tier W |
| P24 | open for operators | Platform owner | §3 | a workforce pool (P64) |
| P25 | open | Mo owner, ISMS | §3 | the second Tier W agent |
| P26 | open | Platform owner | §6 | Tier X |
| P31 | open | Platform owner | §2 | Tier R budgets and quota alerts |

## Key decisions and what to read next

- **Not yet a row:** the gate-counting rule for open rows with a recorded fallback, the owner's first decision.
- **Decided:** P33, with its deviation signatures pending.
- **Proposed:** P34, and P131, P133 and P137 (awaiting ISMS names).
- **Open:** P29, P10, P11, P13, P14, P18, P19, P23 and P32.
- **Spikes:** P3, P4, P57 and P61, none run; where P4 and P61 run before the folder exists is unsettled.
- **Proposed, unrun:** P143, the propagation stage that closes rows 10–14.

Read next:

- Register [§0](../12-open-decisions.md#0-the-register-in-one-screen), [§1](../12-open-decisions.md#1-how-this-register-works), [§4](../12-open-decisions.md#4-before-the-super-admin-grant) and [§7](../12-open-decisions.md#7-values-that-differ-between-pages)
- The [decision log](../../../decisions/README.md)
- The [tier gate](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens)
- The grant checklist in [page 11 §6.3](../11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads)
- The propagation stage, [HLD §18](../01-hld.md#18-what-this-hld-requires-of-the-wall-e-eve-and-mo-sets)
- Wall-E's [lead-time items](../../wall-e/PREREQUISITES.md#9-security-artefacts-and-lead-time-items)
