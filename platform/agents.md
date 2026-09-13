# Agents catalogue

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Maturity: all three agents designed; nothing built. Qualified 2026-09-13: Wall-E, Eve and Mo
  are the platform's first three tenants, and the designs predate the objective in places — the
  platform HLD says what changes.
- Objective restated 2026-09-13; see the platform HLD
  ([agentic-platform/01-hld.md](agentic-platform/01-hld.md)).

One row per agent, and one row per non-agent machine that holds a Workspace admin role. Detail
pages under `platform/agents/` when a row outgrows the table.

**Generated from the register, once it exists.** The inventory of record is the agent register
— one YAML file per agent under `platform/agentic-platform/register/`, merged under the
two-reviewer rule — from which CI generates this table, the Agent Registry card and the factory
inputs ([agentic-platform/01-hld.md](agentic-platform/01-hld.md) §5.1). On 2026-09-13 the register
does not exist yet, so this table is maintained by hand with the register's column names; the
day CI generates it, a hand edit here is overwritten. The `privilege` column shows every
tenant-level right a machine holds (`none`, `workspace_role:<name>`, `super_admin`); CI refuses
a second `super_admin` row while one is not `retired`.

| Agent | Purpose | Audience | Surface | Data sources | Tier | Privilege | AI Act class | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|
| **Wall-E** ([design](wall-e/README.md)) | The doer. Operates Workspace as a super-admin robot account (qualified 2026-09-13; this said "an admin robot account" under the narrow-role design), on a human's prompt and then progressively autonomously within the catalogue; bands B and C are always human-approved or human-executed | DWP admins | Gemini Enterprise + scheduled/event triggers | Admin SDK, Licensing, Reports, Gmail, Chat, Calendar | P-SA | `super_admin` on the dedicated licensed user `walle@` ([decision](../decisions/2026-09-13-wall-e-holds-super-admin.md), P33) | `annex_iii_adjacent` ([10](agentic-platform/10-eu-ai-act.md) §3.1) | the platform owner | `idea` |
| **Eve** ([design](eve/README.md)) | The controller. Approves high-risk plans, verifies independently, halts and demotes; detects and reports misbehaviour across every Workspace stream (control path, model-free) | — (machine); reports to the Wall-E owner and the second human outside the Wall-E line | REST control plane; `eve-console` | Wall-E audit tables, Workspace audit logs (all six streams), Reports API by actor | controllers (`fld-controllers`) | `workspace_role:` the read-only custom role "Eve — Verifier" on `eve@` ([project-topology.md](project-topology.md) §2); never Super Admin | `not_ai_system` ([10](agentic-platform/10-eu-ai-act.md) §3.2) | the platform owner (target: the second human outside the Wall-E line, HLD §13.2) | `idea` |
| **Eve reporting path** (`eve-advisor`) | Narrates anomalies and pages at severity 2 only; report-only, nothing it writes reaches a verdict | — (machine) | `eve.incidents` narratives, `eve.advice` | `eve.*`, `eve_workspace_logs` through authorised views | controllers (`EVE_ADVISOR_PROJECT`) | `none` | *tbd* (P19) | Eve owner | `idea` — not built until P34 is signed and P19 answered |
| **Mo** ([design](mo/README.md)) | Continuous improvement of Wall-E **and Eve** (widened 2026-09-13). Measures outcomes, produces promotion-readiness scorecards and Eve quality packs, proposes changes; one Mo per platform keyed on `agent_id` | — (machine) | BigQuery, pull requests | Wall-E audit tables, traces; Eve's `eve_quality` dataset (findings, verdicts, attestations, pages, incidents minus narrative, seeded-fault runs) — added 2026-09-13 | improvers (`fld-improvers`) | `none` | `minimal` ([10](agentic-platform/10-eu-ai-act.md) §3.4) | the platform owner | `idea` |
| `factory-groups@` (platform machine, not an agent) | Makes agent groups from the register; refuses the control groups in code | — | — | the register | platform core | `workspace_role:groups_admin` (P65) | *tbd* (no classification recorded) | platform owner | `idea` |
| ~~Edge AI v2~~ ([design](edge-ai-v2/README.md)) | Superseded by Wall-E on 2026-09-08. Kept for its identity and policy-engine reasoning. | — | — | — | — | — | — | the platform owner | `retired` |

Status values: `idea` → `poc` → `pilot` → `prod` → `retired`, plus `suspended` (set by the
reconciliation job or an incident; left only by a human pull request, P74). Tier values:
`C R W P P-SA X` ([agentic-platform/02-landing-zone-and-tiers.md](agentic-platform/02-landing-zone-and-tiers.md) §1).

## The team

Wall-E, Eve and Mo share responsibility for Workspace operations and are designed so that
no single agent both decides and acts, or both acts and grades itself. The contract
between them is fixed in [wall-e/08-team-eve-mo.md](wall-e/08-team-eve-mo.md), and Eve and Mo
now have their own document sets: [eve/](eve/README.md) and [mo/](mo/README.md), both written
on 2026-09-12 against that contract. Since 2026-09-13 the platform HLD §13 owns how the three
sit on the platform; the contract's structure holds.

Two properties are worth knowing without reading either set. **Eve is not an agent**: no
language model sits anywhere in its authority path, because a controller whose approval can
be talked into existence is not a control. Qualified 2026-09-13: that holds for the authority
path (approve, veto, halt, demote) and is recorded as a compliance invariant; a separate
report-only reasoning path `eve-advisor` is proposed
([../decisions/2026-09-13-eve-reporting-path-may-reason.md](../decisions/2026-09-13-eve-reporting-path-may-reason.md),
P34), and nothing it writes is read by the gate. **Mo may use one**, precisely because it holds no
credential and no write path, and because every number it publishes is re-derived by the
gate that acts on it.

With Wall-E a super admin, Eve's independence inside the tenant's organisation is detective,
not structural; the evidence, incident record and pager that leave the organisation — the
witness organisation, administered by a second human outside the Wall-E line — are the
structural part (platform HLD §13.2).

Designing Eve surfaced about twenty contradictions inside Wall-E's own set, listed in
[eve/08-contract-changes.md](eve/08-contract-changes.md). They are recorded there rather than
applied.

**Each agent has its own GCP project**, and the Gemini Enterprise app a fourth, decided on
2026-09-13 for least privilege: no project-level role in one agent's project reaches another
agent's secret, key or evidence, and every interaction between them is an explicit,
resource-level grant. Qualified 2026-09-13: project-per-agent is a **pattern, not a count of
four** — every agent gets a factory-made project in its tier folder, Eve's reporting path has
a project of its own (`EVE_ADVISOR_PROJECT`), and the platform adds core projects and a witness
organisation ([agentic-platform/01-hld.md](agentic-platform/01-hld.md) §3.1). A super-admin
credential is not bounded by any project boundary; that residual is the super-admin decision
record's. [project-topology.md](project-topology.md) is the single authority for what lives
where and how the grants cross.
