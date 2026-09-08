# Wall-E — autonomous Google Workspace administrator

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-08
- Maturity: **design — nothing built, nothing enabled**
- Codename: `wall-e`. Resource prefix `walle-`. Final naming is [decision 2](09-open-decisions.md).
- Supersedes: [Edge AI v2](../edge-ai-v2/README.md) (`Assumption:` you want Wall-E to replace it rather than run alongside it — [decision 1](09-open-decisions.md))

## One-line summary

A single Google Workspace robot account holds a narrow custom admin role. A GCP action
service is the only thing that ever holds its credential, and it decides — in
deterministic Python, never in the model — whether a requested operation may run.
Wall-E is the agent that asks. **No domain-wide delegation anywhere.**

## The load-bearing constraint

You said Wall-E must be autonomous, but that its criticality means it has to be enabled
step by step, under control. That single sentence drives the whole design, and it is
expressed as one rule:

> **Autonomy is never a property of Wall-E. It is a number attached to a pair
> (operation family, trigger class), stored as versioned data, enforced by the action
> service. A human raises it one notch at a time against measured evidence. Any
> operator, Eve, or an automatic breaker lowers it instantly, alone, with the paperwork
> done afterwards.**

There is no state of the world in which the sentence "Wall-E is autonomous now" is true.
At any moment Wall-E is at level 5 for reading the directory, level 3 for suspending a
user from chat, and level 0 for anything derived from its own mailbox. That asymmetry —
**humans raise, machines lower** — is the entire safety story.

## The team

Wall-E is the first of three agents with shared responsibility for Workspace operations.
This document set designs Wall-E and *fixes the interfaces* Eve and Mo attach to, so the
two later designs have something concrete to build against.

| Agent | Role | Can it act on Workspace? | Can it raise autonomy? | Can it lower it? |
|---|---|---|---|---|
| **Wall-E** | The doer. Plans and executes admin operations. | Yes, through the action service only | **Never** | Only by refusing its own run |
| **Eve** | The controller. Approves, verifies after the fact, halts. | No — read-only, and by a separate credential | **Never** | Yes, instantly, to any level |
| **Mo** | Continuous improvement. Measures, proposes. | No | No — proposes a pull request a human merges | No |

Eve and Mo are designed later. See [08-team-eve-mo.md](08-team-eve-mo.md) for the
contracts Wall-E owes them.

## Documents

**Start here:** [05-autonomy-ladder.md](05-autonomy-ladder.md) is the step-by-step
enablement plan you asked for. Everything else exists to make it enforceable.

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

Code scaffold to be built at `~/Claude/wall-e/`, starting from the
Edge AI v2 scaffold at `~/Claude/edge-ai-v2/` (which has never been run).

## What is assumed rather than known

This design was written without access to the organisation's tenant. Every statement about the organisation
is marked `Assumption:` where it appears. The big ones, all in
[09-open-decisions.md](09-open-decisions.md): the OU structure and whether a sandbox OU
can be created, the domain list, who else can be an operator, whether an HR feed exists,
the Workspace edition, and whether the Gemini Enterprise app is in the `eu` multi-region.
