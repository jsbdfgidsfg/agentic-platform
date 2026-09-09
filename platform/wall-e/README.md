# Wall-E — autonomous Google Workspace administrator

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-09
- Maturity: **design — nothing built, nothing enabled**
- Codename: `wall-e`. Resource prefix `walle-`. Final naming is [decision 2](09-open-decisions.md).
- Other writers: `Assumption:` no other automation already writes to the same Workspace objects ([decision 1](09-open-decisions.md))

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

**Two standalone documents.** Both are self-contained, and both are the ones to hand to
someone else.

| Document | For |
|---|---|
| [**SETUP.md**](SETUP.md) | The procedure to stand Wall-E up from nothing, executable by a Workspace super admin who owns a GCP project. Ends at Stage 0: it can read the tenant, and no autonomous write is possible. |
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

## What is assumed rather than known

This design was written without access to your tenant. Every statement about your tenant
is marked `Assumption:` where it appears. The big ones, all in
[09-open-decisions.md](09-open-decisions.md): the OU structure and whether a sandbox OU
can be created, the domain list, who else can be an operator, whether an HR feed exists,
the Workspace edition, and whether the Gemini Enterprise app is in the `eu` multi-region.
