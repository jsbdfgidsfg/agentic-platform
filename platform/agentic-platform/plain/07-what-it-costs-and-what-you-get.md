# 07. What it costs and what you get

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-18
- What this page is: the money side of the platform in plain words — what costs, who pays, what the organisation gets back, and why no total and no saving can be quoted yet. Nothing is built.

## In one sentence

Nobody has priced this platform, nobody has measured what it would save, and both facts are deliberate: the design names every cost and its payer, refuses to guess amounts, and puts a measured "before" and two exit points ahead of any promise of a "return".

## Why no price is quoted

No price is quoted anywhere in the design. The pages that would give one were written without reading a vendor's price list, and every amount is marked *tbd*, meaning to be decided. What the design does instead is name, for each cost, what drives it up or down and which budget pays it ([cost classes](../01-hld.md#05-cost-classes)).

This is not an oversight. A number written down before anyone has measured the organisation's own volumes would be read later as a quote. The one line that comes closest to a measurement is the volume of Workspace audit logs, which the full build measures for one day before the logging budget is set ([measure the log volume](../setup/04-purchases-and-lead-times.md#5-costs-that-sit-on-no-google-cloud-budget)).

One vendor list price is on record and it is not a quote: Google's subscription minimum for Security Command Center Premium, 15,000 US dollars a year for 12 months, as recorded on 2026-09-15 and to be re-verified ([the purchase table](../setup/04-purchases-and-lead-times.md#1-the-purchase-table-longest-lead-time-first)). Security Command Center Premium is Google's organisation-wide service that reports security findings across every cloud project; its unit prices are the vendor's on that day, not a figure this organisation has been offered.

## What costs money, and who pays

An **agent** is a program that uses a language model, the kind of software behind a chat assistant, to decide what to do, and may be given tools to act. The platform sorts agents into **tiers**, lettered C, R, W, P and X, by how much they may do. Each tier switches on the costs below, and each cost has a named payer ([cost classes](../01-hld.md#05-cost-classes); [the brief's table](../brief/29-roadmap-and-cost.md#cost-classes)).

| Cost | What drives it | Who pays | From tier |
|---|---|---|---|
| Security Command Center Premium | organisation-wide, every project | IT security (`Assumption:` a platform budget line until IT security decides, P11) | C |
| Central log ingestion, and central log storage that cannot be deleted early | the volume of Workspace audit logs plus cloud access logs — the largest line in the design | the platform | R |
| Model Armor | requests screened per project | the agent's own budget | R |
| Chrome Enterprise Premium licences | one licence per operator and approver | the platform | W |
| Google SecOps with managed detection | events per day, months kept, the retainer | IT security | P |
| A Workspace licence per privileged agent | one licensed user each; Tier P stays rare by policy | the agent owner's cost centre | P |
| The witness organisation | one tenant, one project, one bucket, one dataset, a few channels, two hardware keys | IT security | P |
| Human hours | the roles of every tier | — | every tier |

Three of those names need a sentence each. **Model Armor** is Google's screen for what goes into and comes out of a model; it produces evidence and is never relied on as a barrier. **Google SecOps** is Google's security information and event management service, in short a **SIEM**: the service that collects logs, runs detections and has a desk that answers alarms. **Managed detection and response**, in short **MDR**, is an outside company contracted to watch those alarms round the clock. The **witness organisation** is a second, separate Google organisation run by IT security, outside the reach of the tenant's administrators. It keeps a copy of Eve's evidence and pages a human if the copy stops arriving. Think of a witness who keeps a copy of the record outside the building.

**Log ingestion** means the fee for pulling logs into central storage and keeping them. It cannot be cut by keeping less evidence. Eve's reconciliation compares Google's record of every administrator's actions with the robot's own record, so the whole organisation-wide admin stream is needed, not only the robot's slice ([why the log line cannot be trimmed](../brief/29-roadmap-and-cost.md#cost-classes)).

### The costs that never appear on a cloud bill

The per-project budgets described later see only Google Cloud spend. Thirteen purchase rows are paid elsewhere, so each needs its own owner and purchase record, or the super-admin gate discovers them late ([costs that sit on no Google Cloud budget](../setup/04-purchases-and-lead-times.md#5-costs-that-sit-on-no-google-cloud-budget)):

- the SIEM and the MDR retainer (IT security; months to procure, `Assumption:`);
- a **penetration test**, a paid attack on the system by professionals to find weaknesses — scoped before the first writing agent, full before the super-admin grant (IT security);
- Security Command Center Premium (IT security and finance);
- the witness organisation's domain, billing account and support subscription (IT security, procurement, finance);
- a **sandbox tenant**, a second Workspace organisation of the same edition used only for tests that change things, with its own domain and seats (platform owner, procurement, finance);
- a paging service, the tool that wakes a human when an alarm fires (IT security);
- Chrome Enterprise Premium licences, which check that an operator's device is in a known state (procurement);
- extra model capacity, only if a later decision needs it;
- **hardware security keys**, small physical devices a person must plug in to sign in: 22, or 26 with the twin robots, with spares (procurement) — this count supersedes an older "ten in total" ([the key count](../setup/04-purchases-and-lead-times.md#4-hardware-keys-the-count-stated-once-and-the-inventory));
- a dedicated platform billing account in euros and a quota request for about 20 projects (finance);
- Gemini Enterprise licences and Gmail-bearing seats for the robot accounts;
- a subscription to a code-hosting service with rules on who may change what (the platform);
- physical custody materials: tamper-evident envelopes, a safe with a sign-out log, custody forms (facilities and procurement).

Every one is unpriced. Each line names the person who obtains its price and the tier it must be priced before ([what is not yet priced](../brief/29-roadmap-and-cost.md#what-is-not-yet-priced)).

## People are the binding cost

The design says it in five words: the binding cost is human hours ([cost classes](../brief/29-roadmap-and-cost.md#cost-classes)). Cloud services scale by paying more. People do not.

On 2026-09-13 the organisation behind the platform is one administrator: no security operations centre, no second super admin outside that administrator's line, no security reviewer, no Eve owner, no engaged data protection officer ([who exists](../01-hld.md#03-who-exists-on-2026-09-13-and-the-roles-the-platform-needs)). Every role sits with one person. That is why the platform opens tier by tier, and each tier opens only when the people and purchases it needs exist: a gate that opens when the people are there ([the tier gate](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens)).

The cost of that gate is speed. In the brief's words: "a sponsor who funds the build but not the people gets a read-only platform" ([the tier gate](../brief/29-roadmap-and-cost.md#the-tier-gate)).

## What each tier adds in people and purchases

| Tier | What agents there may do | People added | Purchases added |
|---|---|---|---|
| **C** classical | answer questions from documents with the user's own permissions | nobody new | Gemini Enterprise licences (exist); Security Command Center Premium |
| **R** read tools | read from systems through tools, in a project of their own | nobody new | nothing more |
| **W** write agents | change records in a business system through a separate service that holds the credential | a second operator (about 2 h a week); a part-time security reviewer from IT security (about 2 h a month); a blind grader (about 1 h a week per Tier W agent) | a build-time signing pipeline (no licence); Chrome Enterprise Premium licences |
| **P** privileged, and **P-SA** the one super-admin robot | hold a Workspace administrator role; P-SA holds Super Admin | a second human super admin outside the Wall-E line as Eve's owner; an incident commander from IT security; an engaged data protection officer; an AI compliance owner with a deputy; a bought detection desk | Google SecOps or the organisation's SIEM; the MDR retainer; a paging service; hardware keys; the witness organisation; the sandbox tenant; the penetration test |
| **X** AGI-class | agents beyond the designers' foresight — **closed** | an AI-safety reviewer who does not exist | a sandboxed runtime tier; a second model family |

Sources: [minimum staffing per tier](../01-hld.md#03-who-exists-on-2026-09-13-and-the-roles-the-platform-needs); [the tier gate](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens). The roles are explained on [04-people-and-decisions.md](04-people-and-decisions.md); three of them matter for cost. A **blind grader** is a named person who did not write an agent's routines and grades a weekly sample of its work without knowing which items were planted as tests. A **security reviewer** approves every rise in an agent's autonomy and every change to privileged access. A **Super Admin** is the Workspace role that can do everything in the organisation and that Google cannot limit to a part of it.

Counted as distinct humans, the minimum is 1 at Tier R, 3 when the first agent writes, 4 at the super-admin grant, and 4 plus a bought round-the-clock desk once Wall-E runs catalogued work without a human approving each action; five humans is the clean state ([the minimum per stage](../11-tisax.md#72-the-minimum-per-stage)). The full build raises the grant's count to five named humans, or four with a dated exception from the **ISMS**, the organisation's information-security governance function ([blocked row B-21](../setup/README.md#8-blocked-index)).

Hours do not stop once things are built. Eve costs under half an hour a week of human attention in steady state ([Eve's cost](../../eve/01-hld.md#cost)). Mo's blind grading costs at least two hours a week, indefinitely, from a named human who is not the playbook owner. Reading the weekly digest adds about half an hour. Mo reports that grading time beside the hours it saves, so a stall on human attention shows as a number ([the real number](../../mo/05-staging.md#run-human--the-real-number-and-the-one-that-decides-whether-the-programme-survives)).

## The agents' own estimates

Each agent's design carries an estimate of its build effort and running cost. Every figure is `Assumption:`, to be confirmed against the first billing cycle ([the agents' own estimates](../brief/29-roadmap-and-cost.md#the-agents-own-estimates)).

| Agent | Build effort | Running cost on Google Cloud | Human time |
|---|---|---|---|
| Wall-E at Stage 0 | — | low tens of euros a month; model spend below that | — |
| Eve | 36 to 45 engineer-days (seven to nine engineer-weeks); 41 to 50 with Wall-E's side | under €50 a month, plus one Workspace licence | under half an hour a week |
| Mo | 24 to 37 person-days | €25 to 60 a month, billed to Mo's own project | at least two hours a week of blind grading at Stage 4 volume |

An **engineer-day** or **person-day** is one person working one full day. Eve's figure predates two additions the objective made — the witness organisation and Eve's reporting path — and neither is priced yet. Mo's figure predates its remit over Eve. Every per-tier budget amount is open as decision P31 ([what is not yet priced](../brief/29-roadmap-and-cost.md#what-is-not-yet-priced)).

## What you get

The gain, stated without a number, is routine administration done faster and on the record, and every later agent added without rebuilding its security ([why build it](../brief/02-executive-summary.md#why-build-it-and-how-the-programme-can-stop)).

**Weekly digests, from Wall-E's read-only stage (S0).** Wall-E is the doer, the agent that does administration work on a human's request; [02-the-three-agents.md](02-the-three-agents.md) explains all three. Before it changes anything, it produces a weekly report: last week's administrative changes, accounts unused for 90 days, suspended accounts still holding a licence, groups with outside members or no owner, and the administrators checked against a signed list. The design assumes these reports are made by hand today or not at all (`Assumption:`).

**Leaver and joiner actions and licence reclaim, from the first writing stage (S1).** When someone leaves or joins, the routine account steps are done from a chat request. A **licence** is a paid seat for a Google service; reclaiming licences from suspended accounts is the first measurable saving. Reclaiming from accounts that are merely inactive waits on a legal answer about profiling, decision P18, and no AI output ever selects a person by behaviour ([the profiling boundary](../10-eu-ai-act.md#314-the-profiling-question-answered-by-design-p126)).

**Batch approval, at Stage 3 (S3).** One operator approves a whole planned run instead of each action. The design calls this the stage where the repetitive work goes away and the stage to sit in longest.

**The hundredth agent.** The platform is built as a factory that stamps out identical, pre-secured projects, and a **register**, one file every agent needs a row in before it may exist. So "a read-only assistant costs a register row and a factory run. A super-admin robot costs a witness organisation, a second super admin, a bought detection desk and a signed deviation." ([thesis](../01-hld.md#01-thesis)). A hundredth agent inherits controls reviewed once. What caps the count is not projects but grading capacity: every writing agent needs about an hour a week of a blind grader, and the cap itself is open as decision P25 ([the register's gate groups](../brief/29-roadmap-and-cost.md#the-registers-gate-groups-are-the-roadmap)).

## Why no saving figure exists yet

**No benefit figure exists.** The saving is *tbd* until four weeks of **toil** — repetitive manual administration — on the top three administrative tasks are measured before Wall-E's first phase ([why build it](../brief/02-executive-summary.md#why-build-it-and-how-the-programme-can-stop)). The reason is simple: no "before" can be measured after the robot has started. Once Wall-E does the work, nobody can go back and time the human doing it.

This is why the first act of the full build is the toil baseline, on day one, on paper if need be. The recording runs four consecutive calendar weeks and starts the first Monday after the answer from HR (human resources) on whether the works council must be consulted before staff time their own tasks ([the first act](../setup/README.md#31-blocks); [the toil baseline](../setup/02-toil-baseline.md)). The **works council** is the employees' elected representative body. Those four weeks cannot be recovered later, which is why they head the list of day-one items ([day-one lead-time items](../brief/29-roadmap-and-cost.md#day-one-lead-time-items)).

The proof of value takes a shortcut. It counts past volume from Google's own record of administrator events and times a small sample of tasks by hand, which yields a baseline of volumes and minutes but never a claim of minutes saved; the full build still owes the prospective four weeks ([P196](../12-open-decisions.md#6b-proposed-by-the-proof-of-value-set-p192p204)).

## The exits

The programme is designed to stop, twice, on purpose ([how the programme can stop](../brief/02-executive-summary.md#why-build-it-and-how-the-programme-can-stop)).

**Exit one: the dated review at the end of Stage 1.** Mo, the improver, produces one money decision at that point: the toil saved so far, plus the projected saving at Stage 3, set against the operating cost **including human hours**. If the balance is negative, the programme stops ([Mo at S1](../../mo/05-staging.md#s1--the-first-decision-mos-numbers-carry-and-it-is-about-money); [Wall-E decision 38](../../wall-e/09-open-decisions.md)).

**Exit two: a human approving each action is a legitimate permanent end state.** The agents climb an **autonomy ladder** of six levels; level L3 means a human approves every action. Eve's gate layer — the part that would sign approvals in a human's place — is not funded until a promotion can state, in numbers, how much approval work it removes ([what the staging does not promise](../../eve/05-stages.md#what-the-staging-does-not-promise)). In the brief's words: "A signature is not a commitment to full autonomy."

The two smaller build paths have their own exits. The proof of value ends at a dated stop-or-continue review with three options, and in every option nothing is deleted ([P204](../12-open-decisions.md#6b-proposed-by-the-proof-of-value-set-p192p204)). The three-day build ends with a same-day unwind ([the unwind](../3-day/README.md#10-the-unwind-before-anything-real-is-touched)).

## How runaway spend is caught

Every project carries a billing budget at its tier's default amount, with alerts at 50, 90 and 100 per cent of actual spend and at 100 per cent of forecast. There is no automatic switch that cuts billing: cutting billing would stop the evidence pipeline first, which is the opposite of what a stop needs. The stop levers are the kill switches K0 to K7, the pre-built ways to halt an agent described on [03-how-it-is-kept-safe.md](03-how-it-is-kept-safe.md). The mechanism is proposed as P39; the amounts stay open as P31 ([budgets per tier](../02-landing-zone-and-tiers.md#37-budgets-per-tier-p39-the-amounts-stay-p31)). One project per agent is forced by Google, not chosen, and it carries a recurring cost: each project has its own budget, permissions and owner group, checked daily ([the recurring cost of project-per-agent](../brief/29-roadmap-and-cost.md#the-recurring-cost-of-project-per-agent); [the cost](../../project-topology.md#14-the-cost)).

## The three ways to start, in people and in return

[06-three-ways-to-start.md](06-three-ways-to-start.md) describes the three build paths; this section gives only what each costs in people and what it returns. Every figure is the path's own and every date is `Assumption:`.

| Path | People | Effort | Elapsed | Buys |
|---|---|---|---|---|
| Three-day build | two people, plus a sponsor named in writing who does no work | six person-days: 38 person-hours allocated and 7 held in reserve | three business days | nothing; signs no new contract |
| Proof of value | three hands-on people plus one engineer, and named approvers for a signature or an hour | procedure 20 to 26 person-days; code 40 to 64 engineer-days; total 60 to 90 | first stage 6 to 9 weeks; second stage week 16 to 20 with a dedicated engineer; 26 to 34 weeks if one person does both | none of the thirteen purchases on its critical path |
| Full build | thirteen appointments | 85 to 90 person-days hands-on | 6 to 7 months to Stage 0, not before 2027-03; 9 to 12 months to Mo's first merged proposal | all thirteen purchase rows |

Sources: [the three-day team](../3-day/README.md#3-the-team-and-what-they-hold); [the two POV stages](../pov/README.md#4-pov_stage_dates-the-two-stages); [the full build's critical path](../setup/README.md#34-parallel-sittings-and-the-critical-path).

### What the three-day build returns

Two people build four cloud projects with budgets ([status](../3-day/README.md#status)). They put up a controller (Eve) that reads the administrator audit log and pages a human, live before any doer exists. They add a doer holding one narrow privilege over four **synthetic accounts**, test accounts that belong to nobody. Its first run is a forced **dry run**, which records what would happen without doing it; its real execution needs a second person's approval. Two kill levers are pulled and timed. Mo counts the doer's own rows against past volume. It is a demonstration of machinery under control; it is not compliance evidence and not a production grant, and the sponsor is told so before the demonstration ([what three days cannot buy](../3-day/README.md#7-what-three-days-cannot-buy)).

Four sentences are never to be used in any report, slide or message about it ([never to be used](../3-day/README.md#11-never-to-be-used-in-any-report-slide-or-message)). In the quotes, an "injection" is text planted to trick the model, "the floor" is the minimum Model Armor setting, and the codes in brackets are the build page's own numbering.

> 1. "Wall-E is safe as a super admin." Nothing here touches super-admin containment. No agent holds Super Admin at any moment of the three days.
> 2. "Eve is independent." Independence in the design is structural: a witness organisation, a second tenant. This set has neither (C-01), and its Eve lives inside the reach of the administrators it watches.
> 3. "Model Armor blocked the injection." A probabilistic content screen is never a trust boundary. And nothing here exercises it: no step sends anything through the floor, so these three days produce **no Model Armor evidence at all**, only the floor settings themselves (C-22).
> 4. "We saved `<n>` minutes of admin work." The doer acted only on synthetic accounts. No human minute was saved, and Mo's scorecard says so in bold (C-07).

They are never used because each would claim a thing the three days did not build or measure: no robot held Super Admin, no witness existed, nothing was sent through the content screen, and no real person's work was done by the doer. For money, the fourth sentence is the one to remember. The three days return a working demonstration and a volume baseline, and not one minute of saving.

### What the proof of value returns

Three people and one engineer produce a governed Gemini Enterprise environment in which an agent exists only as a register row ([the claim](../pov/README.md#11-pov_claim_statement)). Its first stage ends 6 to 9 weeks after day one. Its second stage ends in week 16 to 20, and only with a dedicated engineer ([the two stages](../pov/README.md#4-pov_stage_dates-the-two-stages)). It holds a controller that reported on every human super admin to someone who is not the subject. It holds a doer with **no Workspace administrator role at all**, whose every action is written ahead to an audit table. And it holds an improver that measured the doer against a baseline: volumes from Google's admin history, minutes from a timed sample. Its doer is a separate agent called `steward`; Super Admin goes to no agent, ever. A claim whose record is missing is struck, not softened.

Three sentences are never to be used in any report, slide or message about the proof of value ([never to be used](../pov/README.md#12-never-to-be-used-in-any-report-slide-or-message-about-the-pov)). In these quotes, "Track A" is the part of the proof of value that is built, the three lowest tiers on the production tenant; "Track B" is the super-admin part it leaves to the full build ([the two tracks](../pov/README.md#3-the-two-tracks)). "Injection" and the bracketed codes mean the same as above.

> 1. "Wall-E is safe as a super admin." Nothing in Track A touches super-admin containment (G10, G11, G14, G20, Eve G-7 need Track B, §3). Nor may any report say or imply that the doer "does admin work": it holds no Workspace admin role.
> 2. "Eve is independent." Independence in the design is structural (a witness organisation, a second tenant). The POV has neither (PV-D-03), and its Eve lives inside the reach of the administrators it watches.
> 3. "Model Armor blocked the injection." A probabilistic content screen is never a trust boundary, whatever its grade ([../01-hld.md](../01-hld.md) §0.2). It produced evidence.

They are never used for the same reason: the proof of value builds none of the super-admin containment, has no witness organisation, and treats the content screen as a producer of evidence, never as a barrier. It also claims no real minute of administration saved and no tamper-proof audit; alteration is detected, not prevented ([what the POV does not claim](../pov/README.md#11-pov_claim_statement)). A sponsor told "three weeks" has been misled about both of its stages; the page says to put "six to nine weeks" and "about four to five months with a dedicated engineer" on the first slide ([the two stages](../pov/README.md#4-pov_stage_dates-the-two-stages)).

### What the full build returns

The full build alone owns the super-admin grant, the sandbox tenant, the witness organisation and every gate around Wall-E's Super Admin; nothing the smaller paths produce is evidence for them ([status](../setup/README.md#status)). It returns the platform, Eve over the human super admins with a witness and an independent proof, the grant under its gate, Wall-E's Stage 0, Mo's first merged proposal and the standing drill and evidence records. It is the only path that yields the measured saving, because it is the only one that records the four prospective weeks of toil.

Nothing is torn down between the paths. Every artefact uses the full build's names and schemas, so a three-day build or a proof of value that has to be torn down has failed ([how it grows](../3-day/README.md#12-how-it-grows)).

## What this means for you

**If you hold the budget.** You will not receive a total. You will receive a table of unpriced lines, each with the person who must obtain its price and the tier it must be priced before, and a list of thirteen purchases whose longest lead times start on day one. Fund the people before the cloud services, or you buy a read-only platform. Expect a dated review at the end of Wall-E's first writing stage that may stop the programme, and treat that as the design working, not failing.

**If you sit on the works council.** The saving cannot be measured without four weeks of staff timing their own routine tasks, and that recording does not start until HR has answered whether you must be consulted first. The measurement is of tasks and volumes, not of individual performance; Mo's aggregates use surrogate keys with a minimum group size, and who may see a per-operator figure is still open ([04-people-and-decisions.md](04-people-and-decisions.md)).

**If you are the new engineer.** Your days are the scarce line. The proof of value's second stage is paced by the code, 40 to 64 engineer-days written by one person, and the full build has 22 blocked rows that are mostly code nobody has written. Nothing you build is thrown away on the way to the next path, provided you use the full build's names from the first line.

## What is still undecided

Only the decisions that touch money and value:

| Id | What | State | Who acts |
|---|---|---|---|
| P31 | every per-tier budget amount | open | the platform owner |
| P39 | the budget mechanism: one budget per project, alerts, no automatic billing cut | proposed | the platform owner |
| P11 | who funds and owns Security Command Center Premium | open | IT security |
| P10 | which SIEM and which MDR partner | open | IT security |
| P14 | the witness organisation and its billing path | open | IT security |
| P63 | Chrome Enterprise Premium licences for operators and approvers | proposed | procurement obtains the price |
| P25 | the cap on writing agents set by blind-grading capacity | open | the platform owner with the Mo owner and the ISMS |
| P18 | whether reclaiming licences from inactive accounts is profiling | open | the DPO (data protection officer) and legal |
| P196 | the proof of value's retrospective baseline, never a minutes-saved claim | proposed | the platform owner |
| P204 | the proof of value's dated stop-or-continue review, nothing deleted | proposed | the platform owner, the ISMS, the second person |
| Wall-E 38 | the toil baseline before Phase 1 and the stop rule at S1 exit | no decision file yet | the platform owner |
| — | whether the works council must be consulted before staff record their own task time | *tbd*, HR's answer | HR |

Sources: [before the folder exists](../12-open-decisions.md#2-before-the-folder-exists); [before the super-admin grant](../12-open-decisions.md#4-before-the-super-admin-grant); [proposed by the proof of value](../12-open-decisions.md#6b-proposed-by-the-proof-of-value-set-p192p204); [every open row](../brief/30-decisions-awaiting-owner.md#every-open-row-and-unsigned-signature); [the day-one HR question](../setup/README.md#34-parallel-sittings-and-the-critical-path).

## Where this is defined

- Cost classes, drivers and payers: [01-hld.md §0.5](../01-hld.md#05-cost-classes); [brief chapter 24, Cost](../brief/29-roadmap-and-cost.md#cost-classes)
- Costs on no cloud budget, the purchase table and the key count: [setup file 04](../setup/04-purchases-and-lead-times.md#5-costs-that-sit-on-no-google-cloud-budget)
- The tier gate, people and purchases per tier: [01-hld.md §0.4](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens); [01-hld.md §0.3](../01-hld.md#03-who-exists-on-2026-09-13-and-the-roles-the-platform-needs); [11-tisax.md §7.2](../11-tisax.md#72-the-minimum-per-stage)
- The gain, the missing benefit figure and the two exits: [brief chapter 1](../brief/02-executive-summary.md#why-build-it-and-how-the-programme-can-stop)
- The agents' own estimates: [brief chapter 24](../brief/29-roadmap-and-cost.md#the-agents-own-estimates); [Eve's cost](../../eve/01-hld.md#cost); [Mo's cost and effort](../../mo/05-staging.md#cost-and-effort); [Wall-E's cost](../../wall-e/SETUP.md#03-what-it-costs)
- The toil baseline: [setup file 02](../setup/02-toil-baseline.md); [the first act of the build](../setup/README.md#31-blocks)
- The Stage 1 money decision: [Mo's staging, S1](../../mo/05-staging.md#s1--the-first-decision-mos-numbers-carry-and-it-is-about-money); [Wall-E's decisions](../../wall-e/09-open-decisions.md)
- L3 as a permanent end state: [Eve's stages](../../eve/05-stages.md#what-the-staging-does-not-promise)
- Budgets per project: [02-landing-zone-and-tiers.md §3.7](../02-landing-zone-and-tiers.md#37-budgets-per-tier-p39-the-amounts-stay-p31)
- The three paths' effort and returns: [3-day/README.md](../3-day/README.md#status); [pov/README.md §4](../pov/README.md#4-pov_stage_dates-the-two-stages); [setup/README.md §3.4](../setup/README.md#34-parallel-sittings-and-the-critical-path)
- The sentences never to be used: [3-day/README.md §1.1](../3-day/README.md#11-never-to-be-used-in-any-report-slide-or-message); [pov/README.md §1.2](../pov/README.md#12-never-to-be-used-in-any-report-slide-or-message-about-the-pov)
- Words used here: [08-glossary.md](08-glossary.md)
