# Agents catalogue

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-12
- Maturity: all three agents designed; nothing built

One row per agent. Detail pages under `platform/agents/` when a row outgrows the table.

| Agent | Purpose | Audience | Surface | Data sources | Owner | Status |
|---|---|---|---|---|---|---|
| **Wall-E** ([design](wall-e/README.md)) | The doer. Operates Workspace as an admin robot account, on request and then progressively autonomously | DWP admins | Gemini Enterprise + scheduled/event triggers | Admin SDK, Licensing, Reports, Gmail, Chat, Calendar | the platform owner | `idea` |
| **Eve** ([design](eve/README.md)) | The controller. Approves high-risk plans, verifies independently, halts and demotes | — (machine) | REST control plane | Wall-E audit tables, Workspace audit logs | the platform owner | `idea` |
| **Mo** ([design](mo/README.md)) | Continuous improvement. Measures outcomes, produces promotion-readiness scorecards, proposes changes | — (machine) | BigQuery, pull requests | Wall-E audit tables, traces | the platform owner | `idea` |
| ~~Edge AI v2~~ ([design](edge-ai-v2/README.md)) | Superseded by Wall-E on 2026-09-08. Kept for its identity and policy-engine reasoning. | — | — | — | the platform owner | `retired` |

Status values: `idea` → `poc` → `pilot` → `prod` → `retired`

## The team

Wall-E, Eve and Mo share responsibility for Workspace operations and are designed so that
no single agent both decides and acts, or both acts and grades itself. The contract
between them is fixed in [wall-e/08-team-eve-mo.md](wall-e/08-team-eve-mo.md), and Eve and Mo
now have their own document sets: [eve/](eve/README.md) and [mo/](mo/README.md), both written
on 2026-09-12 against that contract.

Two properties are worth knowing without reading either set. **Eve is not an agent**: no
language model sits anywhere in its authority path, because a controller whose approval can
be talked into existence is not a control. **Mo may use one**, precisely because it holds no
credential and no write path, and because every number it publishes is re-derived by the
gate that acts on it.

Designing Eve surfaced about twenty contradictions inside Wall-E's own set, listed in
[eve/08-contract-changes.md](eve/08-contract-changes.md). They are recorded there rather than
applied.
