# Agents catalogue

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Maturity: all three agents designed, nothing built; they are the platform's first three
  tenants, and the platform HLD ([agentic-platform/01-hld.md](agentic-platform/01-hld.md)) says
  where their designs change.

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
| **Wall-E** ([design](wall-e/README.md)) | The doer. Operates Workspace as a super-admin robot account, on a human's prompt and then progressively autonomously within the catalogue; bands B and C are always human-approved or human-executed | DWP admins | Gemini Enterprise + scheduled/event triggers | Admin SDK, Licensing, Reports, Gmail, Chat, Calendar | P-SA | `super_admin` on the dedicated licensed user `walle@` ([decision](../decisions/2026-09-13-wall-e-holds-super-admin.md), P33) | `annex_iii_adjacent` ([10](agentic-platform/10-eu-ai-act.md) §3.1) | the platform owner | `idea` |
| **Eve** ([design](eve/README.md)) | The controller. Approves high-risk plans, verifies independently, halts and demotes; detects and reports misbehaviour across every Workspace stream (control path, model-free) | — (machine); reports to the Wall-E owner and the second human outside the Wall-E line | REST control plane; `eve-console` | Wall-E audit tables, Workspace audit logs (all six streams), Reports API by actor | controllers (`fld-controllers`) | `workspace_role:` the read-only custom role "Eve — Verifier" on `eve@` ([project-topology.md](project-topology.md) §2); never Super Admin | `not_ai_system` ([10](agentic-platform/10-eu-ai-act.md) §3.2) | the platform owner (target: the second human outside the Wall-E line, HLD §13.2) | `idea` |
| **Eve reporting path** (`eve-advisor`) | Narrates anomalies and pages at severity 2 only; report-only, nothing it writes reaches a verdict | — (machine) | `eve.incidents` narratives, `eve.advice` | `eve.*`, `eve_workspace_logs` through authorised views | controllers (`EVE_ADVISOR_PROJECT`) | `none` | *tbd* (P19) | Eve owner | `idea` — not built until P34 is signed and P19 answered |
| **Mo** ([design](mo/README.md)) | Continuous improvement of Wall-E **and Eve**. Measures outcomes, produces promotion-readiness scorecards and Eve quality packs, proposes changes; one Mo per platform keyed on `agent_id` | — (machine) | BigQuery, pull requests | Wall-E audit tables, traces; Eve's `eve_quality` dataset (findings, verdicts, attestations, pages, incidents minus narrative, seeded-fault runs) | improvers (`fld-improvers`) | `none` | `minimal` ([10](agentic-platform/10-eu-ai-act.md) §3.4) | the platform owner | `idea` |
| `factory-groups@` (platform machine, not an agent) | Makes agent groups from the register; refuses the control groups in code | — | — | the register | platform core | `workspace_role:groups_admin` (P65) | *tbd* (no classification recorded) | platform owner | `idea` |
| ~~Edge AI v2~~ ([design](edge-ai-v2/README.md)) | Superseded by Wall-E on 2026-09-08. Kept for its identity and policy-engine reasoning. | — | — | — | — | — | — | the platform owner | `retired` |

Status values and their lifecycle, `suspended` included, are
[05 §3.2](agentic-platform/05-registry-and-autonomy-contract.md#32-mandatory-fields-per-tier).
Tier values are `C R W P P-SA X`
([02 §1.1](agentic-platform/02-landing-zone-and-tiers.md#11-letters-not-numbers-and-how-the-briefs-t0tx-map)).
The AI Act class of each system is argued in
[10 §3](agentic-platform/10-eu-ai-act.md#3-classification-per-system).

## The team

Wall-E, Eve and Mo share responsibility for Workspace operations under three separation rules —
no agent both decides and acts, none grades its own work, only humans loosen
([wall-e/08-team-eve-mo.md](wall-e/08-team-eve-mo.md#the-separation-that-makes-a-team-worth-having)).
Eve and Mo have their own document sets, [eve/](eve/README.md) and [mo/](mo/README.md), written
against that contract; the platform HLD §13 owns how the three sit on the platform.

**Eve is not an agent**: no language model sits anywhere in its authority path (approve, veto,
halt, demote), because a controller whose approval can be talked into existence is not a
control. A separate, report-only reasoning path `eve-advisor` is proposed (P34,
[../decisions/2026-09-13-eve-reporting-path-may-reason.md](../decisions/2026-09-13-eve-reporting-path-may-reason.md)), and nothing it
writes is read by the gate ([eve/01-hld.md](eve/01-hld.md#thesis)). **Mo may use a model**,
precisely because it holds no credential and no write path, and because every number it
publishes is re-derived by the gate that acts on it.

With Wall-E a super admin, Eve's independence inside the tenant's organisation is detective,
not structural; the witness organisation is the structural part
([eve/01-hld.md §1](eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness)).

Designing Eve surfaced about twenty contradictions inside Wall-E's own set, listed in
[eve/08-contract-changes.md](eve/08-contract-changes.md). They are recorded there rather than
applied.

**Each agent has its own GCP project**, a pattern rather than a count: no project-level role in
one agent's project reaches another agent's secret, key or evidence, and every interaction
between them is an explicit, resource-level grant
([project-topology.md §1](project-topology.md#1-why-four-projects)). What each project hosts,
the core projects and the witness organisation included, is
[project-topology.md §2](project-topology.md#2-the-four-projects); a super-admin credential is
not bounded by any project boundary, a residual the super-admin decision record carries.
