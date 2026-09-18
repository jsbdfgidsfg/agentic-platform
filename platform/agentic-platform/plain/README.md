# The platform in plain words

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-18
- What this page is: the front door to a ten-page set that explains, to any reader, a secure platform for software agents on Google Cloud and Google Workspace, and its three agents; the set opens the door to the full documentation and replaces none of it.

## In one sentence

This set tells you, without assuming any computing background, what is being designed, who the three agents are, how a robot with every administrative power is meant to be kept in check, who must exist for that to be true, and what nobody can promise yet.

## What this set is, and who it is for

The full documentation is large. It has a set of design pages, a brief of about 200 A4 pages, three human-executed build procedures and a register of 204 decisions. It is written for people who build and review systems. This set is written for everyone else.

It is for an employee whose account the doer will one day touch. It is for a manager who will be asked to approve a run. It is for a works-council member, an elected representative of the employees. They are to be informed, or consulted where the law requires it, before Eve begins watching the human administrators and before any agent acts on employee accounts. It is for a board member who will be asked to sign. And it is for a new engineer who wants the shape of the thing before the detail.

Every page of the set defines each technical term where it first appears. No page relies on a term defined on another page. Where a page gives a number, a date or a name, that value comes from the full documentation. The page links to the line that defines it.

Nothing described here is built. On 2026-09-18 nothing exists: no shared place in Google Cloud for agents, no automated builder for their projects, no list an agent must be on, no outside copy of the evidence, and no robot account with administrative power ([the maturity statement](../README.md#status)).

## How every page is laid out

Every page of the set has the same shape, so you can find the same thing in the same place.

| Section | What you find there |
|---|---|
| Status | Who owns the page, when it was last reviewed, and one line saying what it is |
| In one sentence | The whole page, compressed |
| The body | Short sections, one idea per paragraph, a table wherever two things are compared |
| What this means for you | Two or three reader types, and what each should take away |
| What is still undecided | Only the open decisions that touch that page, each with its register id (a "P" number) |
| Where this is defined | The links to the pages of the full documentation that hold the precise version |

## How to read it in thirty minutes

Read in this order and stop where you have enough.

| Minutes | Read | What you will know afterwards |
|---|---|---|
| 0 to 3 | The ten sentences below | The whole idea, and what it does not promise |
| 3 to 8 | [01-what-we-are-building.md](01-what-we-are-building.md) | What "the platform" is, and why it is not the three agents |
| 8 to 14 | [02-the-three-agents.md](02-the-three-agents.md) | What Wall-E, Eve and Mo each do, and what each may never do |
| 14 to 19 | [03-how-it-is-kept-safe.md](03-how-it-is-kept-safe.md) | What Google refuses, what code refuses, and what is only watched |
| 19 to 23 | [04-people-and-decisions.md](04-people-and-decisions.md) | Who must exist, and which decisions are still open |
| 23 to 27 | [05-the-law-and-the-standards.md](05-the-law-and-the-standards.md) | What the EU AI Act and TISAX ask, and what cannot be promised |
| 27 to 30 | [09-questions-people-ask.md](09-questions-people-ask.md) | The answers to the questions you are probably holding |

With another thirty minutes, read [06-three-ways-to-start.md](06-three-ways-to-start.md) (how a build could begin, and what each way cannot show), [07-what-it-costs-and-what-you-get.md](07-what-it-costs-and-what-you-get.md) (why no price exists yet) and [08-glossary.md](08-glossary.md) (every term in one place).

A new engineer reads the whole set once, then goes to the full documentation through the map further down this page.

## The platform in ten plain sentences

1. **Nothing is built.** Every page describes a design, a procedure or a decision about something that does not exist on 2026-09-18. Three ways to start are written down: two people for three days; three people for a proof of value whose first stage ends 6 to 9 weeks after day one and whose second ends in week 16 to 20 with a dedicated engineer; or the full build, 6 to 7 months to its first stage ([the hand-over chain](../3-day/README.md#12-how-it-grows); [the proof of value's two stages](../pov/README.md#4-pov_stage_dates-the-two-stages)).
2. **The platform is a secured place for agents.** An agent is a program that uses a language model (software that produces text and plans from text) to decide what to do, and may be given tools to act; the place is the organisation's Google Cloud (Google's rented computing) and Google Workspace (its mail, calendar, documents and user accounts) ([what an agent is](../brief/02-executive-summary.md#what-was-asked-and-the-readings-the-design-declines-or-qualifies)).
3. **It is five things, not three agents.** A folder where every rule Google can enforce is set once; a factory that stamps out an identical, already-secured working space (a "project") for each agent; a register an agent must be in before it may exist; a contract every agent that can change things adopts; and a gate that opens a class of agents only when the people and services that class needs exist ([the thesis](../01-hld.md#01-thesis)).
4. **Agents are sorted into lettered tiers by what they may do.** C for assistants built without programming, R for agents that only read, W for agents that write, P for agents whose program holds an administrator's key to Workspace (P-SA for the single super-admin agent), and X, AGI-class (agents of general capability), which is closed ([the tier model](../01-hld.md#11-the-tier-model)).
5. **Wall-E is the doer.** It carries out routine account and licence tasks from a fixed, written list, when a named person asks it to. It works through a dedicated user account holding Super Admin, the Google Workspace role with every administrative power, which Google cannot limit to part of the organisation. The owner decided that on 2026-09-13, and the design works around it rather than re-arguing it ([the decision](../../../decisions/2026-09-13-wall-e-holds-super-admin.md); [what it costs](../01-hld.md#what-this-reverses-and-what-it-costs)).
6. **Eve is the controller.** It is a rule-based watcher; no language model sits on the path that can stop Wall-E. Inside the organisation's own cloud a super admin could reach Eve, so Eve can see and report an attack on itself but cannot be put beyond reach. Only the copy of its evidence held in a separate "witness organisation", a second Google organisation run by IT security, is out of a super admin's reach ([Eve's independence, stated honestly](../../eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness)).
7. **Mo is the improver.** It measures the other two and can only propose a change, through a pull request (a written change request) that two humans review, one outside the owner's line ([Mo](../01-hld.md#133-mo--improving-both-one-mo-per-platform-without-touching-eves-independence)).
8. **No setting in Google can make a Super Admin account less powerful.** So for Wall-E the main safeguard is spotting misuse fast, not preventing it. If the robot's credential (the secret that proves to Google who is acting) is stolen, the thief controls the organisation's whole Google Workspace and can reach its cloud. Locked-away keys, powers split across two programs, alarms within minutes and people pulling switches limit the damage; nothing prevents it ([what nothing can narrow](../01-hld.md#16-what-the-platform-does-not-do); [the residual risks](../brief/23-threat-model-and-residual-risk.md#the-residual-risks-a-sponsor-accepts-by-signing)).
9. **No price is quoted, no benefit figure exists, and the people do not yet exist.** On 2026-09-13 the organisation has one administrator, no second super admin outside that administrator's line, no security reviewer, no engaged data protection officer and no detection desk (a team that watches security alerts round the clock); the binding cost is human hours ([who exists](../01-hld.md#03-who-exists-on-2026-09-13-and-the-roles-the-platform-needs); [cost classes](../01-hld.md#05-cost-classes)).
10. **The law is answered with mechanisms and evidence, never with a promised outcome.** For the EU AI Act (the European Union's law on artificial intelligence) and TISAX (the automotive industry's information-security assessment) the design lists what the regulator or the assessor still decides ([what "bulletproof" can and cannot mean](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean)).

## The ten pages

| Page | One line |
|---|---|
| [README.md](README.md) | This page: what the set is, how to read it, the platform in ten sentences, the map to the full documentation, and the honesty rules |
| [01-what-we-are-building.md](01-what-we-are-building.md) | The five things the platform is, the six tiers, and why a hundredth agent costs a register row and a factory run |
| [02-the-three-agents.md](02-the-three-agents.md) | Wall-E the doer, Eve the controller, Mo the improver: what each does, what each may never do, and how they meet |
| [03-how-it-is-kept-safe.md](03-how-it-is-kept-safe.md) | What Google refuses, what code refuses, what is only watched, the kill switches, and why a super-admin robot is watched rather than narrowed |
| [04-people-and-decisions.md](04-people-and-decisions.md) | The roles the design needs, the counted minimum of distinct humans per stage, and the register of decisions still open |
| [05-the-law-and-the-standards.md](05-the-law-and-the-standards.md) | The EU AI Act, TISAX, personal data and the works council: what is due when, and what cannot be promised |
| [06-three-ways-to-start.md](06-three-ways-to-start.md) | The three-day build, the proof of value and the full build: what each shows, what each can never claim |
| [07-what-it-costs-and-what-you-get.md](07-what-it-costs-and-what-you-get.md) | Why no price and no benefit figure exist yet, who obtains each price, and the two deliberate exits |
| [08-glossary.md](08-glossary.md) | Every technical term of the set, one plain sentence each |
| [09-questions-people-ask.md](09-questions-people-ask.md) | The questions an employee, a manager, a works-council member, a board member and a new engineer ask, with short answers |

## From your question to the page, and to the full documentation

The full documentation has four parts. The **design set** is the specification, fourteen files numbered 00 to 13, of which [01-hld.md](../01-hld.md), the high-level design, is the parent every other page details ([the document table](../README.md#documents)). The **brief** explains the intent behind the design in about 200 A4 pages, in 33 chapter files ([brief/README.md](../brief/README.md)). The **three build procedures** are human-executed, step by step: the three-day build ([3-day/README.md](../3-day/README.md)), the proof of value ([pov/README.md](../pov/README.md)) and the full build ([setup/README.md](../setup/README.md), files 01 to 42). The **register** is one page that holds every platform decision, P1 to P204, with its state ([12-open-decisions.md](../12-open-decisions.md)).

| Your question | Plain page | Where the full documentation defines it |
|---|---|---|
| What is being built, and why is it more than three agents? | [01-what-we-are-building.md](01-what-we-are-building.md) | [Thesis](../01-hld.md#01-thesis); [brief chapter 1](../brief/02-executive-summary.md#what-is-proposed-a-platform-of-which-the-three-agents-are-the-first-tenants) |
| What does each agent do, and what may it never do? | [02-the-three-agents.md](02-the-three-agents.md) | [The three agents on the platform](../01-hld.md#13-the-three-agents-on-the-platform); [Wall-E's declared purpose](../10-eu-ai-act.md#311-the-declared-intended-purpose-the-sentence-the-assessment-rests-on) |
| How is a robot with Super Admin kept safe? | [03-how-it-is-kept-safe.md](03-how-it-is-kept-safe.md) | [Wall-E in Tier P-SA](../01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa); [the six containment primitives](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded); [the decision record](../../../decisions/2026-09-13-wall-e-holds-super-admin.md) |
| Can Eve really stop Wall-E? | [03-how-it-is-kept-safe.md](03-how-it-is-kept-safe.md) | [Eve's independence](../../eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness); [Eve on the platform](../01-hld.md#132-eve--independent-controller-two-paths-a-witness-outside-the-tenant-a-second-human) |
| How is it switched off? | [03-how-it-is-kept-safe.md](03-how-it-is-kept-safe.md) | [The kill switches](../../wall-e/ARCHITECTURE.md#46-kill-switches); [the fleet kill switch](../01-hld.md#114-the-fleet-kill-switch-k7-and-the-containment-primitives-for-the-top-tier) |
| Who has to exist, and who decides what? | [04-people-and-decisions.md](04-people-and-decisions.md) | [Who exists and the roles needed](../01-hld.md#03-who-exists-on-2026-09-13-and-the-roles-the-platform-needs); [the minimum per stage](../11-tisax.md#72-the-minimum-per-stage); [the register](../12-open-decisions.md) |
| What is still undecided, and who must act? | [04-people-and-decisions.md](04-people-and-decisions.md) | [The register in one screen](../12-open-decisions.md#0-the-register-in-one-screen); [decisions awaiting the owner](../brief/30-decisions-awaiting-owner.md) |
| Is it lawful, and what about my data? | [05-the-law-and-the-standards.md](05-the-law-and-the-standards.md) | [EU AI Act](../10-eu-ai-act.md); [TISAX](../11-tisax.md); [personal data and employees](../brief/26-personal-data-and-employees.md) |
| When is the works council told? | [05-the-law-and-the-standards.md](05-the-law-and-the-standards.md) | [Workers and the explanation path](../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129) |
| How would we start, and how long would it take? | [06-three-ways-to-start.md](06-three-ways-to-start.md) | [3-day/README.md](../3-day/README.md); [pov/README.md](../pov/README.md); [setup/README.md](../setup/README.md) |
| What does it cost, and what do we get? | [07-what-it-costs-and-what-you-get.md](07-what-it-costs-and-what-you-get.md) | [Cost classes](../01-hld.md#05-cost-classes); [roadmap and cost](../brief/29-roadmap-and-cost.md#cost); [purchases and lead times](../setup/04-purchases-and-lead-times.md) |
| What does this word mean? | [08-glossary.md](08-glossary.md) | [The glossary of record](../brief/31-glossary.md) |
| I have a different question | [09-questions-people-ask.md](09-questions-people-ask.md) | [The objective and its review](../00-objective-review.md#1-the-objective) |

## The honesty rules this set keeps

Every page in this set follows the same rules, because the full documentation follows them.

**Nothing is built.** Every sentence in the present tense describes a design. Where a page says "Eve halts Wall-E", read "the design says Eve would halt Wall-E". The objective is dated 2026-09-13; the build procedures added their decisions to the register on 2026-09-15 and 2026-09-16 ([the register's status](../12-open-decisions.md#status)). The first thing that could exist is a three-day demonstration on synthetic accounts, test accounts that belong to nobody ([the maturity table](../README.md#maturity-what-exists-on-2026-09-13)).

**No price is quoted.** No page of the full documentation quotes a price. The design consulted no price list, and every amount is to be decided. The design names only each cost's driver and who pays ([cost classes](../01-hld.md#05-cost-classes)). This set follows suit. The one recorded figure, a yearly minimum for one Google security subscription, is repeated where it belongs, with its date, in [07-what-it-costs-and-what-you-get.md](07-what-it-costs-and-what-you-get.md).

**No benefit figure exists.** The saving cannot be stated until four weeks of routine administrative work have been measured before the doer starts. No "before" can be measured afterwards ([why build it](../brief/02-executive-summary.md#why-build-it-and-how-the-programme-can-stop)).

**No regulator's or assessor's decision is promised.** The design offers mechanisms and evidence. Whether an authority accepts Wall-E as a narrow-task system is the authority's decision. Whether a TISAX assessor accepts a super-admin robot at the required maturity is the assessor's ([what cannot be promised](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean); [the honest line on TISAX](../11-tisax.md#0-what-this-page-decides-in-one-paragraph)). Every legal date the set relies on was re-checked on 2026-09-18 and held.

**Giving a robot Super Admin is a decision the owner made.** It was decided on 2026-09-13 (decision P33). The design works around it and lists, without softening, what it costs. It is also an exception under TISAX (P136). That exception still awaits the security reviewer's signature and the entry in the organisation's risk register ([the decision record](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)).

**Eve's independence inside the organisation is detective, not structural.** A super admin can reach anything inside the organisation, including Eve. What is structurally out of reach is the copy of the evidence held in the witness organisation ([the non-goals](../01-hld.md#16-what-the-platform-does-not-do)).

**The two smaller build paths never claim what they cannot show.** The three-day build lists four sentences never to be used in any report, slide or message ([3-day/README.md](../3-day/README.md#11-never-to-be-used-in-any-report-slide-or-message)). In the quote, Model Armor is Google's screen for the text going into and out of a model; an "injection" is text planted in a document or message to trick the model into doing something else; "the floor" is the minimum Model Armor setting applied to every agent; and the codes in brackets are the build page's own numbering of what it left out:

> 1. "Wall-E is safe as a super admin." Nothing here touches super-admin containment. No agent holds Super Admin at any moment of the three days.
> 2. "Eve is independent." Independence in the design is structural: a witness organisation, a second tenant. This set has neither (C-01), and its Eve lives inside the reach of the administrators it watches.
> 3. "Model Armor blocked the injection." A probabilistic content screen is never a trust boundary. And nothing here exercises it: no step sends anything through the floor, so these three days produce **no Model Armor evidence at all**, only the floor settings themselves (C-22).
> 4. "We saved `<n>` minutes of admin work." The doer acted only on synthetic accounts. No human minute was saved, and Mo's scorecard says so in bold (C-07).

The proof of value forbids the first three in the same words, with its own reasons ([pov/README.md](../pov/README.md#12-never-to-be-used-in-any-report-slide-or-message-about-the-pov)). They are never used because each would be true of the full design and false of the smaller build that produced the report. Neither smaller build grants Super Admin to any agent. Neither has a witness organisation. And Model Armor works by probability: it produces evidence and is never a boundary. Any page of this set that discusses those subjects carries the same sentences.

**Roles, never people.** No page names a person or an employer. "The platform owner", "the second human", "the security reviewer" are roles. Where a fact is inferred rather than stated, it is marked `Assumption:`.

## What this means for you

**If you are an employee.** The doer would read every employee's directory, licence and group data from its first stage. Later it would act on accounts: group membership, profile fields, licences, and suspending an account only after a human in HR (human resources) or a named operator has already decided. No decision about you would be made by the machine alone. You could ask HR for the reasons behind any action on your account. None of this exists yet. Start with [02-the-three-agents.md](02-the-three-agents.md) and [05-the-law-and-the-standards.md](05-the-law-and-the-standards.md).

**If you are a works-council member.** Two things would watch employees: the doer over accounts, and Eve over every human administrator, from Eve's first run. The design puts your information, or consultation where national law requires it, before the first write on employee accounts and before the super-admin grant, the day the robot's account is given Super Admin. A re-check of the law on 2026-09-18 moved that step earlier still: you are to be informed, or consulted where the law requires it, before Eve begins watching the human administrators, which happens before either of those two moments. The register row itself still says "before Stage 1" (P129). The country, and so the exact duty, is not yet fixed. Start with [05-the-law-and-the-standards.md](05-the-law-and-the-standards.md), then [04-people-and-decisions.md](04-people-and-decisions.md).

**If you are a board member or sponsor.** A signature would accept eight named residual risks, the risks that remain after every control is in place. The first is that a stolen robot credential is a takeover of the Workspace tenant. It would also fund people before machines: a sponsor who funds the build but not the people gets a read-only platform. Start with the ten sentences above, then [07-what-it-costs-and-what-you-get.md](07-what-it-costs-and-what-you-get.md) and [06-three-ways-to-start.md](06-three-ways-to-start.md).

## What is still undecided

Only the decisions that touch this page. Each id is a row of [the register](../12-open-decisions.md).

| Id | What is undecided | Why it touches this page |
|---|---|---|
| P33 / P136 | Wall-E holds Super Admin: decided by the owner; the TISAX exception it also is still lacks the security reviewer's signature and the risk-register entry | The honesty rule "a decision the owner made" is true; "signed" is not yet |
| P29 | The two lists: what Wall-E may never do, and what it may do only with two humans | Sentence 5 says "a fixed, written list"; that list's edges are the owner's to sign |
| P129 | When the works council is informed or consulted: the register row says before Wall-E's first write; the re-check of 2026-09-18 asks for it before Eve starts watching administrators | The works-council paragraph above answers "when am I told?" |
| P28 | Wall-E's declared intended purpose, signed with legal | Sentence 10 rests on the purpose being narrow and signed |
| P31 | The budget amount per tier | The rule "no price is quoted" stays true until these are set |
| P23 | Which legal entity is the provider and deployer under the EU AI Act | Sentence 10 names a law whose duties fall on an entity not yet named |
| — | The benefit figure | No id exists; it waits on four weeks of measured work before the doer's first stage |

## Where this is defined

- [../README.md](../README.md) — the design set's front page: maturity, the document table, what the platform is and is not
- [../01-hld.md](../01-hld.md) — the high-level design, the parent of every design page
- [../brief/README.md](../brief/README.md) — the brief: intent, reading paths per reader, 33 chapter files
- [../12-open-decisions.md](../12-open-decisions.md) — the register of record, P1 to P204
- [../3-day/README.md](../3-day/README.md), [../pov/README.md](../pov/README.md), [../setup/README.md](../setup/README.md) — the three build procedures
- [../../../decisions/2026-09-13-wall-e-holds-super-admin.md](../../../decisions/2026-09-13-wall-e-holds-super-admin.md) — the one decided row, P33
- [../brief/31-glossary.md](../brief/31-glossary.md) — the glossary of record
