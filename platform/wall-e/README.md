# Wall-E — autonomous Google Workspace administrator

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-18
- 2026-09-18: the Documents table no longer presents PREREQUISITES.md, SETUP.md and setup/ as the build; one row points to the platform setup procedures, files 30 to 39, and the numbered row 7 points there too.
- Premise: Wall-E holds **Super Admin** on a dedicated, licensed user account, not a narrow custom
  role (objective of 2026-09-13, register row P33). This set is the design of one tenant under the
  platform HLD ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md)); pages of this set
  that still describe the narrow role carry a dated line or are listed for edit in platform HLD §18.
- Maturity: **design — nothing built, nothing enabled.** Eve, Mo and the platform are designed and
  not built either; Wall-E is the platform's Tier P-SA singleton and **Super Admin is not granted
  before the platform's tier gate** (platform HLD §0.4).
- Projects: placement is [../project-topology.md §2](../project-topology.md#2-the-four-projects),
  the authority for names, placement and every cross-project grant; every page here points to it
  rather than restating it.
- Codename: `wall-e`. Resource prefix `walle-`. Final naming is [decision 2](09-open-decisions.md).
- Other writers: `Assumption:` no other automation already writes to the same Workspace objects ([decision 1](09-open-decisions.md))

## One-line summary

A single dedicated, licensed Google Workspace robot account holds **Super Admin**, and nothing at
Google's end narrows it. Two GCP action services on that one account are the only things that ever
hold its credential — `walle-actions` with a narrow OAuth client for the catalogue,
`walle-actions-super` with a broad one for uncatalogued super-admin work that two human super
admins approve — and they decide, in deterministic Python, never in the model, whether a requested
operation may run. A hard-denied list is refused in every lane. Wall-E is the agent that asks; Eve
watches everything the account does, from outside Wall-E's reach where it counts. **No domain-wide
delegation anywhere.**

## The load-bearing constraint

Wall-E must be autonomous, yet its criticality means it is enabled step by step, under control, so
**autonomy is never a property of Wall-E**: it is a level attached to a pair (operation family,
trigger class), stored as versioned data and enforced by the action service, which a human raises
one notch at a time against measured evidence and any operator, Eve or a breaker lowers instantly —
**humans raise, machines lower** ([05 §1](05-autonomy-ladder.md#1-the-eight-rules)). No
super-admin-class operation is ever autonomous, on any trigger, at any stage, and `WRITE_HIGH` never
reaches L5 — permanent ceilings in code ([05 §4](05-autonomy-ladder.md#4-ceilings-that-are-code-not-config)).
With a super-admin account behind the ladder, the action service alone enforces it and **detection
is the primary control** ([02](02-identity-and-auth.md#admin-rights-super-admin-and-what-that-removes)).

## The team

Wall-E is the first of three agents with shared responsibility for Workspace operations, and the
three are the first tenants of a platform meant for hundreds (platform HLD §0.1, §13).

| Agent | Role | Defined in |
|---|---|---|
| **Wall-E** | The doer: plans and executes admin operations on a human's prompt, as Super Admin, only through the two action services and three bands (catalogue, two-person generic lane, console handoff). Never raises autonomy; lowers it only by refusing its own run | this set; [08 Responsibilities](08-team-eve-mo.md#responsibilities) |
| **[Eve](../eve/README.md)** | The controller: approves, verifies after the fact, halts and lowers instantly; detects and reports misbehaviour to a second human outside the Wall-E line. Read-only, by a separate credential, never Super Admin | [../eve/README.md](../eve/README.md) |
| **[Mo](../mo/README.md)** | Continuous improvement of Wall-E and Eve, one Mo per platform: measures and proposes pull requests a human merges; cannot act or lower | [../mo/README.md](../mo/README.md) |

Eve and Mo were designed on 2026-09-12. [08-team-eve-mo.md](08-team-eve-mo.md) is the contract
Wall-E owes them (the interfaces every agent attaches to are now owned by platform HLD §12), and
[../eve/08-contract-changes.md](../eve/08-contract-changes.md) lists what those two designs ask
Wall-E to change.

## Documents

**Standalone documents.** Each is self-contained, and these are the ones to hand to someone
else.

| Document | For |
|---|---|
| [**Build: ../agentic-platform/setup/README.md**](../agentic-platform/setup/README.md) | The human-executed build of Wall-E is files [30](../agentic-platform/setup/30-wall-e-workspace-side.md) to [39](../agentic-platform/setup/39-wall-e-stage-0.md) of the platform setup procedures, after the platform (01 to 21), Mo's foundations (22) and Eve's first half (23 to 28); it ends at Stage 0 (39). [PREREQUISITES.md](PREREQUISITES.md), [SETUP.md](SETUP.md) and [setup/](setup/README.md) are pointer pages since 2026-09-16; `walle_setup.py` is a helper under decision SD-37, never the procedure. |
| [**../project-topology.md**](../project-topology.md) | Which project holds each identity, key, secret, dataset, bucket, topic, service and job, and the exact resource-level form of every grant that crosses a project boundary. The single authority for placement; decisions 42–52 live there. |
| [**../agentic-platform/01-hld.md**](../agentic-platform/01-hld.md) | The platform HLD this set sits under: the secure Gemini Enterprise environment, the landing zone and tiers, identity, registry, gateways and Model Armor, monitoring, compliance (EU AI Act, TISAX), and §13.1–§13.3 for Wall-E, Eve and Mo on the platform. Read it before this set's numbered pages. |
| [**ARCHITECTURE.md**](ARCHITECTURE.md) | The service architecture with diagrams. Written for a security reviewer deciding on a pilot, and for whoever builds Eve or Mo. |

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
| 7 | [Build runbook](07-build-runbook.md) | Pointer; the build is [../agentic-platform/setup/](../agentic-platform/setup/README.md) files 30 to 39 |
| 8 | [The team: Eve & Mo](08-team-eve-mo.md) | Shared responsibilities and the interfaces Wall-E must expose |
| 9 | [Decisions to make](09-open-decisions.md) | What you must choose before build starts |
| 10 | [**Adversarial review**](10-adversarial-review.md) | What was attacked, what changed, what is knowingly accepted |
| 11 | [Prompt security & monitoring](11-prompt-security.md) | The injection surface, what Model Armor screens and does not, telemetry, and what to alert on. A platform chapter, promoted into [../agentic-platform/06-gateways-model-armor-perimeter.md](../agentic-platform/06-gateways-model-armor-perimeter.md) |
| 12 | [Agent, operator & workforce identity](12-agent-identity.md) | Agent Identity for the agents, Google or federated identities for the operators. A platform chapter, promoted into [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) |
| 13 | [Interconnection](13-agent-interconnection.md) | Agent Registry, A2A, MCP, Agent Gateway and Skill Registry, and which of them a safety interlock may never depend on. A platform chapter, promoted into [../agentic-platform/05-registry-and-autonomy-contract.md](../agentic-platform/05-registry-and-autonomy-contract.md) and [06](../agentic-platform/06-gateways-model-armor-perimeter.md) |
| 14 | [**HLD challenge & revalidation**](14-hld-challenge.md) | Whether the design is the correct path: 54 challenges, what stands, what was refuted, and the alternatives weighed |

Code scaffold to be built in the application repository (not yet written).

## This design has been attacked

Before anything was built, [10-adversarial-review.md](10-adversarial-review.md) recorded two
reviews of 2026-09-08 — an adversarial pass of seventeen attacks and a consistency and fact pass —
whose fixes are in the numbered documents, and [14-hld-challenge.md](14-hld-challenge.md#verdict)
recorded the challenge of 2026-09-11: 54 challenges, no alternative architecture proposed, the
architecture judged the correct path with the changes it lists still to settle. The objective of
2026-09-13 overturned two of 14's positions — the service-account option closes for Wall-E because
a service account cannot hold Super Admin, and verdict reason 4 no longer holds — and
[../agentic-platform/00-objective-review.md](../agentic-platform/00-objective-review.md) is the
record of that review. Both records keep their findings as history, so nobody assumes a control
works because a superseded version of the design said so.

## What is assumed rather than known

This design was written without access to your tenant. Every statement about your tenant
is marked `Assumption:` where it appears. The big ones, all in
[09-open-decisions.md](09-open-decisions.md): the OU structure and whether a sandbox OU
can be created, the domain list, who else can be an operator, whether an HR feed exists,
the Workspace edition, and which project hosts the Gemini Enterprise app (`GEMINI_PROJECT`,
number `GEMINI_PROJECT_NUMBER`), because Wall-E's engine grant is built from **that** number,
never from Wall-E's own ([../project-topology.md](../project-topology.md) §3 row 1). The app
location is decided as `eu` by the platform HLD (§2.1), with `global` only as a dated exception;
the Workspace edition stays *tbd* and also decides which admin-2SV, multi-party-approval and
Context-Aware Access controls of the Super Admin grant Google enforces (platform HLD §4.6, §13.1
item 6).
