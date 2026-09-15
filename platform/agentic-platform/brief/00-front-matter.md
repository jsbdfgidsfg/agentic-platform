# 0. About this document

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14

## What you will understand by the end

What this brief is for, which source wins when it and a design page differ, what exists of the platform on 2026-09-14 (nothing but the design), how the argument runs from Part I to Part V, which short path through it fits your role, and the conventions that make a word such as *proposed* mean the same thing on every page.

## What the brief is and is not

The platform — a secure Gemini Enterprise environment for hundreds of agents, whose first tenants are Wall-E the doer, Eve the controller and Mo the improver — is specified in full on thirteen platform pages, the three agent sets and the project topology page. Those pages say *what*: every folder, role, control, retention period and decision row, with its owner, verification and failure mode.

The brief says *why*: the intent behind each choice, whom it serves, what it costs in people, bought services and signatures, which risks it answers, and what it deliberately does not do. It is written for readers who must judge the design: a sponsor accepting a residual risk, a data protection officer weighing a log's proportionality, an assessor weighing a deviation.

The brief is not a second specification. It summarises mechanisms and links to the section that defines them; it reproduces no design table and introduces no product fact, value or decision of its own.

### Precedence

Every value — a name, a number, a date, a decision state — is authoritative on its design page ([design set status](../README.md#status)). Where the brief and a design page disagree, the design page wins and the brief is corrected. Where two design pages disagree with each other, the brief says so in one sentence and cites both; it does not choose between them.

## Maturity on 2026-09-14

The platform is a design; nothing is built ([maturity](../README.md#maturity-what-exists-on-2026-09-13)). There is no platform folder, factory run, gateway, registry entry, log sink, SIEM, witness organisation or robot account holding Super Admin. The four projects of the topology are decided and not created. The Workspace tenant exists with Gemini Enterprise licences, and the tenant app's project, `GEMINI_PROJECT`, is to be imported rather than recreated; the design set's maturity table records it as existing, while the HLD and the topology page carry its existence as an `Assumption:` ([HLD §2.1](../01-hld.md#21-the-tenant-app-and-its-project), [topology §2](../../project-topology.md#2-the-four-projects)). No spike has been run.

When a chapter says a control "refuses" or "halts", it describes what the design requires of something that does not yet exist. Behind it today stands one administrator holding every role (Chapter 1, Executive summary; Chapter 23, Operating model); which tiers can open with the people who exist is Chapter 24, Roadmap and cost.

## How the brief is argued

The brief is a case, not a catalogue; each part hands the next its premise.

- **Part I, Intent** (Chapters 1–4) says why: the objective and what it demands, the problem it creates and its risk themes, and the principles every later answer derives from. Chapter 1 stands alone.
- **Parts II and III, The platform and The agents** (Chapters 5–18) say what is built and how. Each chapter opens with the Chapter 3 risk themes it answers and closes with what Chapter 19 found remaining. The platform comes first because Wall-E, Eve and Mo are instances of its rules, not its definition.
- **Part IV, Proof** (Chapters 19–22) tests the design: the threat model, closing each risk theme with its residual, then the EU AI Act, TISAX, and personal data from the employees' side.
- **Part V, Delivery** (Chapters 23–25): who must exist, in what order the platform opens and at what cost, and which decisions wait for whom.

## Reading paths

Stop when your question is answered. The paths adapt the design set's reading orders for a [security reviewer](../README.md#reading-order-for-a-security-reviewer) and a [builder](../README.md#reading-order-for-a-builder).

| Reader | Path |
|---|---|
| Executive sponsor | Chapter 1 alone; or Part I, then the residual risks in Chapter 19, then Chapters 24 and 25 |
| Security architect | Chapters 3 and 4, Part II, then Chapters 15, 16 and 19 |
| Builder | Chapters 5, 7, 8, 9, 13 and 24 |
| Data protection officer | Chapters 2 and 22, Chapter 12, then the regulatory clocks in Chapter 11 |
| Works council | Chapter 22, the bands and ceilings in Chapter 15, the reporting contract in Chapter 16 |
| TISAX assessor | Chapters 21, 19, 23, 8 and 12 |
| AI compliance owner and legal | Chapters 20 and 22, then the post-market monitoring plan in Chapter 17 |
| Programme lead | Part V, then the scaling argument in Chapter 14 |

Appendix B, Document map, gives the design pages behind every chapter.

## Conventions

The brief carries the design's conventions unchanged ([design set status](../README.md#status)).

- `Assumption:` marks a fact the design inferred rather than verified; the brief keeps every one, including all cost figures.
- *tbd* marks a value nobody has decided.
- Every Google product, launch stage, role, constraint, regulatory article and date was verified against its source on 2026-09-13, or is listed under "Unverified" on its design page and stays *tbd*; the brief never upgrades an unverified fact.
- Dates are absolute. Roles are named, never people, except the owner, the platform owner.
- No company other than Google is named; no secret appears.

### Decision identifiers and states

The platform register's identifiers form one sequence: P1–P34 are the HLD's decisions, P35–P141 those of the detailed pages in page order, then P142 and P143 ([how the register works](../12-open-decisions.md#1-how-this-register-works)). Every other identifier family — tiers, primitives, detections, agent-set registers — is listed once, with the chapter that explains it, in Appendix A, Glossary.

Five state words are used exactly as the register defines them (in full in Chapter 25, Decisions awaiting the owner): *decided* (the named owner decided, on a date), *closed* (answered by a later row or a verified fact), *proposed* (stands until its owner overturns it in writing), *open* (nobody has decided; the gate it blocks stays red) and *spike* (settled by a test on a throwaway resource in nonprod). A proposed or open row is never presented as settled.

### Chapter shape

Every chapter opens with a Status block and what you will understand by the end, and closes with the key decisions it rests on, with register id and state, and the canonical design pages to read next. An element is explained fully in one chapter only; elsewhere it gets at most a sentence and a pointer by number and title. Part dividers carry one paragraph.

## Key decisions and what to read next

- **P33, decided** by the owner: Wall-E holds Super Admin, and the design is built around that choice rather than re-arguing it; the deviation signatures are pending ([decision record](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)). Chapter 15, Wall-E, the doer, explains what it costs and what compensates.
- The register's states and gate rule, P1–P143 — [12-open-decisions.md §1](../12-open-decisions.md#1-how-this-register-works).
- Read next: the [design set README](../README.md#status) for the page inventory and maturity, [what the platform deliberately is not](../README.md#what-it-deliberately-is-not), then the first chapter on your path.
