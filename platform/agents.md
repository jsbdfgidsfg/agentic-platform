# Agents catalogue

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-08
- Maturity: a three-agent team designed; Wall-E fully specified

One row per agent. Detail pages under `platform/agents/` when a row outgrows the table.

| Agent | Purpose | Audience | Surface | Data sources | Owner | Status |
|---|---|---|---|---|---|---|
| **Wall-E** ([design](wall-e/README.md)) | The doer. Operates Workspace as an admin robot account, on request and then progressively autonomously | DWP admins | Gemini Enterprise + scheduled/event triggers | Admin SDK, Licensing, Reports, Gmail, Chat, Calendar | the platform owner | `idea` |
| **Eve** | The controller. Approves high-risk plans, verifies independently, halts and demotes | — (machine) | REST control plane | Wall-E audit tables, Workspace audit logs | the platform owner | `idea` |
| **Mo** | Continuous improvement. Measures outcomes, produces promotion-readiness scorecards, proposes changes | — (machine) | BigQuery, pull requests | Wall-E audit tables, traces | the platform owner | `idea` |
| ~~Edge AI v2~~ ([design](edge-ai-v2/README.md)) | Superseded by Wall-E on 2026-09-08. Kept for its identity and policy-engine reasoning. | — | — | — | the platform owner | `retired` |

Status values: `idea` → `poc` → `pilot` → `prod` → `retired`

## The team

Wall-E, Eve and Mo share responsibility for Workspace operations and are designed so that
no single agent both decides and acts, or both acts and grades itself. The contract
between them is fixed in [wall-e/08-team-eve-mo.md](wall-e/08-team-eve-mo.md); Eve and Mo
get their own document sets when they are designed.
