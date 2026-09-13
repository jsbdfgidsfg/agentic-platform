# Wall-E — autonomous Google Workspace administrator

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- **Objective restated 2026-09-13; see the platform HLD** ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md)).
  Premise changed the same day: Wall-E holds **Super Admin** on a dedicated, licensed user account,
  not a narrow custom role; the revised [01-hld.md](01-hld.md) is this set's design under the
  platform HLD. The one-line summary, the load-bearing constraint and the team table below were
  rewritten on 2026-09-13 (platform HLD §18 item 5); pages of this set that still describe the
  narrow role carry a dated line or are listed for edit in platform HLD §18.
- Maturity: **design — nothing built, nothing enabled.** Updated 2026-09-13: Eve and Mo are
  designed (2026-09-12) and not built either; the platform this set now sits in is designed
  (platform HLD, 2026-09-13) and not built; Wall-E is its Tier P-SA singleton and **Super Admin
  is not granted before the platform's tier gate** (platform HLD §0.4).
- Projects: **four**, under one folder — `GEMINI_PROJECT` (the app), `WALLE_PROJECT`
  (everything of Wall-E's), `EVE_PROJECT`, `MO_PROJECT`. Decided 2026-09-13;
  [../project-topology.md](../project-topology.md) is the authority for names, placement and every
  cross-project grant, and every page here points to it rather than restating it. Qualified
  2026-09-13: "four" is now a pattern the platform's factory produces, not a count — the folder
  is `fld-agentic-platform`, `WALLE_PROJECT` sits in `fld-agents-p-sa`, and Eve gains
  `EVE_ADVISOR_PROJECT` and a witness project in a second organisation (platform HLD §3.1, §13.2).
- Codename: `wall-e`. Resource prefix `walle-`. Final naming is [decision 2](09-open-decisions.md).
- Other writers: `Assumption:` no other automation already writes to the same Workspace objects ([decision 1](09-open-decisions.md))

## One-line summary

Rewritten 2026-09-13 (earlier text: "A single Google Workspace robot account holds a narrow
custom admin role"). A single dedicated, licensed Google Workspace robot account holds **Super
Admin**, and nothing at Google's end narrows it. Two GCP action services on that one account are
the only things that ever hold its credential — `walle-actions` with a narrow OAuth client for
the catalogue, `walle-actions-super` with a broad one for uncatalogued super-admin work that two
human super admins approve — and they decide, in deterministic Python, never in the model,
whether a requested operation may run. A hard-denied list is refused in every lane. Wall-E is
the agent that asks; Eve watches everything the account does, from outside Wall-E's reach where
it counts. **No domain-wide delegation anywhere.**

## The load-bearing constraint

You said Wall-E must be autonomous, but that its criticality means it has to be enabled
step by step, under control. That single sentence drives the whole design, and it is
expressed as one rule:

> **Autonomy is never a property of Wall-E. It is a number attached to a pair
> (operation family, trigger class), stored as versioned data, enforced by the action
> service. A human raises it one notch at a time against measured evidence. Any
> operator, Eve, or an automatic breaker lowers it instantly, alone, with the paperwork
> done afterwards.**

Added 2026-09-13, in the same breath: **no super-admin-class operation is ever autonomous**, on any
trigger, at any stage — `SUPER` rows are chat L3 with a two-person rule and L0 on every other
trigger, in code, beside the older permanent ceiling that `WRITE_HIGH` never reaches L5
([platform HLD §12.1](../agentic-platform/01-hld.md), §13.1 item 9). With a super-admin account behind the
ladder, the ladder is enforced by the action service alone, and **detection is the primary
control**.

There is no state of the world in which the sentence "Wall-E is autonomous now" is true.
At any moment Wall-E is at level 5 for reading the directory, level 3 for suspending a
user from chat, and level 0 for anything derived from its own mailbox. That asymmetry —
**humans raise, machines lower** — is the entire safety story.

## The team

Wall-E is the first of three agents with shared responsibility for Workspace operations.
This document set designs Wall-E and *fixes the interfaces* Eve and Mo attach to, so the
two later designs have something concrete to build against. Qualified 2026-09-13: true as
history; the platform HLD now owns the interfaces every agent attaches to (the manifest, the
audit and ladder schemas, the factory's grant rows — platform HLD §12), and the three agents are
the first three tenants of a platform meant for hundreds (platform HLD §0.1, §13).

| Agent | Role | Can it act on Workspace? | Can it raise autonomy? | Can it lower it? |
|---|---|---|---|---|
| **Wall-E** | The doer. Plans and executes admin operations on a human's prompt; since 2026-09-13 any super-admin-level action, through three bands (catalogue, two-person generic lane, console handoff). | Yes, **as Super Admin** (since 2026-09-13), through the two action services only | **Never** | Only by refusing its own run |
| **[Eve](../eve/README.md)** | The controller. Approves, verifies after the fact, halts. Since 2026-09-13 also detects and reports misbehaviour across every Workspace stream the robot touches, independently and autonomously, to a second human outside the Wall-E line; the control path holds no model, a separate reporting path may reason and writes reports and pages only. | No — read-only, by a separate credential, **never Super Admin** | **Never** | Yes, instantly, to any level |
| **[Mo](../mo/README.md)** | Continuous improvement. Measures, proposes — since 2026-09-13 for **Wall-E and Eve**, one Mo per platform. | No | No — proposes a pull request a human merges | No |

Both are now designed, on 2026-09-12: [../eve/README.md](../eve/README.md) and
[../mo/README.md](../mo/README.md). [08-team-eve-mo.md](08-team-eve-mo.md) is the contract
Wall-E owes them, and [../eve/08-contract-changes.md](../eve/08-contract-changes.md) lists
what those two designs ask Wall-E to change.

## Documents

**Two standalone documents.** Both are self-contained, and both are the ones to hand to
someone else.

| Document | For |
|---|---|
| [**PREREQUISITES.md**](PREREQUISITES.md) | Everything that must be true, decided, granted, bought or installed **before** the first command of SETUP.md, with a verification check per row and the long-lead items that block later stages. Read it first. |
| [**SETUP.md**](SETUP.md) | The procedure to stand Wall-E up from nothing, executable by a Workspace super admin who owns four GCP projects under one folder (`GEMINI_PROJECT`, `WALLE_PROJECT`, `EVE_PROJECT`, `MO_PROJECT`). SETUP.md stands up `WALLE_PROJECT` and makes the cross-project grants Wall-E owes the other three; Eve's and Mo's runbooks stand up theirs. Ends at Stage 0: it can read the tenant, and no autonomous write is possible. |
| [**../project-topology.md**](../project-topology.md) | Which of the four projects holds each identity, key, secret, dataset, bucket, topic, service and job, and the exact resource-level form of every grant that crosses a project boundary. The single authority for placement; decisions 42–52 live there. |
| [**../agentic-platform/01-hld.md**](../agentic-platform/01-hld.md) (added 2026-09-13) | The platform HLD this set now sits under: the secure Gemini Enterprise environment, the landing zone and tiers, identity, registry, gateways and Model Armor, monitoring, compliance (EU AI Act, TISAX), and §13.1–§13.3 for Wall-E, Eve and Mo on the platform. Read it before this set's numbered pages. |
| [**ARCHITECTURE.md**](ARCHITECTURE.md) | The service architecture with diagrams. Written for a security reviewer deciding on a pilot, and for whoever builds Eve or Mo. |
| [**setup/**](setup/README.md) | The automation for the procedure. One script, `walle`, with a subcommand per group of phases. It stops where the procedure does, and refuses to attest a console step you have not done. |

**Then:** [05-autonomy-ladder.md](05-autonomy-ladder.md) is the step-by-step enablement
plan. Everything else exists to make it enforceable.

| # | Document | What it answers |
|---|---|---|
| 1 | [High-level design](01-hld.md) | The components, the request path, and why each exists |
| 2 | [Identity & authorisation](02-identity-and-auth.md) | Which principal acts, how it gets a credential, what is deliberately not used |
| 3 | [Low-level design](03-lld.md) | Tool contracts, the operation catalogue, the policy engine, storage, idempotency |
| 4 | [Flows](04-flows.md) | Numbered end-to-end sequences, including the failure branches |
| 5 | [**Autonomy ladder**](05-autonomy-ladder.md) | Levels, trigger classes, six stages, entry/exit criteria, promotion and demotion |
| 6 | [Security & guardrails](06-security-guardrails.md) | Blast-radius ceiling, threat model, kill switches, what is logged |
| 7 | [Build runbook](07-build-runbook.md) | Every command in order, with verification and rollback per phase |
| 8 | [The team: Eve & Mo](08-team-eve-mo.md) | Shared responsibilities and the interfaces Wall-E must expose |
| 9 | [Decisions to make](09-open-decisions.md) | What you must choose before build starts |
| 10 | [**Adversarial review**](10-adversarial-review.md) | What was attacked, what changed, what is knowingly accepted |
| 11 | [Prompt security & monitoring](11-prompt-security.md) | The injection surface, what Model Armor screens and does not, telemetry, and what to alert on. **A platform chapter seeded here** (2026-09-13; promoted into [../agentic-platform/06-gateways-model-armor-perimeter.md](../agentic-platform/06-gateways-model-armor-perimeter.md)) |
| 12 | [Agent, operator & workforce identity](12-agent-identity.md) | Agent Identity for the agents, Google or federated identities for the operators. **A platform chapter seeded here** (2026-09-13; promoted into [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md)) |
| 13 | [Interconnection](13-agent-interconnection.md) | Agent Registry, A2A, MCP, Agent Gateway and Skill Registry, and which of them a safety interlock may never depend on. **A platform chapter seeded here** (2026-09-13; promoted into [../agentic-platform/05-registry-and-autonomy-contract.md](../agentic-platform/05-registry-and-autonomy-contract.md) and [06](../agentic-platform/06-gateways-model-armor-perimeter.md)) |
| 14 | [**HLD challenge & revalidation**](14-hld-challenge.md) | Whether the design is the correct path: 54 challenges from 11 reviewer lenses, what stands, what was refuted, and the alternatives weighed |
Code scaffold to be built in the application repository (not yet written).

## This design has been attacked

Two independent reviews went over it before anything was built: an adversarial pass that
produced seventeen attacks, and a consistency pass that checked every claim against
Google's current documentation and against the other documents. Both found things that
would have broken the safety model if built as first written — including an approval path
that still ran through the model, an Eve signing key that could not be verified without
destroying its own purpose, a Stage 0 budget that would have denied every shadow item and
produced no evidence, and an admin role sliced in ways Workspace does not allow.

Those are fixed in the documents. [10-adversarial-review.md](10-adversarial-review.md)
records what was found, so nobody assumes a control works because an earlier draft said so.

A third pass, on 2026-09-11, attacked the design as it now stands rather than as first
drafted. Eleven reviewer lenses, each arguing for a different cheaper or safer path, produced
54 challenges; refuter lenses then tried to dismiss each one. Nobody proposed a different
architecture, and 39 challenges survived refutation. Three of them block:
a documented service-account option the identity chapter never considered, nobody checking
what the human behind a request is entitled to, and no environment in which a change to the
gate runs before it runs as the holder of the production credential.
[14-hld-challenge.md](14-hld-challenge.md) is the record, and the edits it calls for are
listed there rather than applied.

On 2026-09-13 the objective was restated and the whole documentation reviewed against it
(nine lenses); the platform HLD is the result. Two verdicts above are overturned by it: the
service-account option closes for Wall-E by a Google fact (a service account cannot hold Super
Admin), and 14's reason 4 ("super-admin-only APIs are unreachable whatever sits in front of
them") no longer holds. The history above stays as written.

## What is assumed rather than known

This design was written without access to your tenant. Every statement about your tenant
is marked `Assumption:` where it appears. The big ones, all in
[09-open-decisions.md](09-open-decisions.md): the OU structure and whether a sandbox OU
can be created, the domain list, who else can be an operator, whether an HR feed exists,
the Workspace edition, and whether the Gemini Enterprise app is in the `eu` multi-region —
and which project hosts it (`GEMINI_PROJECT`, number `GEMINI_PROJECT_NUMBER`), because
Wall-E's engine grant is built from **that** number, never from Wall-E's own
([../project-topology.md](../project-topology.md) §3 row 1). Updated 2026-09-13: the app location is decided as `eu` by the platform HLD (§2.1), with `global` only as a dated exception; the Workspace edition stays *tbd* and now also decides which admin-2SV, multi-party-approval and Context-Aware Access controls of the Super Admin grant Google enforces (platform HLD §4.6, §13.1 item 6).
