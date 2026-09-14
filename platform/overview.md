# Platform overview

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Maturity: landing page for the platform design set; design only, nothing built. The objective
  of 2026-09-13 is answered by the platform HLD
  ([agentic-platform/01-hld.md](agentic-platform/01-hld.md)).

## What this is

The agentic platform: internal AI agents for employees, built on Google Cloud, integrated into
Google Workspace, with Gemini Enterprise as the primary end-user surface. It is designed to
sustain hundreds of agents, classical or autonomous, with a closed tier for future AGI-class
agents, enterprise-class security and monitoring, an EU AI Act position and TISAX compatibility;
Wall-E (the doer), Eve (the controller) and Mo (continuous improvement) are its first three
tenants, not the platform itself. The thesis is the platform HLD
[§0.1](agentic-platform/01-hld.md#01-thesis).

## Building blocks

| Layer | Product | Page |
|---|---|---|
| Platform design | The platform HLD, its detailed pages 02–11 and the decision register P1.. | [agentic-platform/](agentic-platform/README.md), [agentic-platform/01-hld.md](agentic-platform/01-hld.md), [agentic-platform/12-open-decisions.md](agentic-platform/12-open-decisions.md) |
| End-user surface | Gemini Enterprise | [gemini-enterprise.md](gemini-enterprise.md) |
| Identity & collaboration | Google Workspace | [google-workspace.md](google-workspace.md) |
| Compute / data / models | GCP | [gcp-projects.md](gcp-projects.md) |
| Project layout | One factory-made project per agent in its tier folder under `fld-agentic-platform`, beside the core projects, the Gemini Enterprise app project and a witness organisation outside the tenant. The folder tree is [02 §2.1](agentic-platform/02-landing-zone-and-tiers.md#21-the-tree); what each project hosts is [project-topology.md §2](project-topology.md#2-the-four-projects) | [project-topology.md](project-topology.md), [agentic-platform/02-landing-zone-and-tiers.md](agentic-platform/02-landing-zone-and-tiers.md) |
| The agents themselves | — | [agents.md](agents.md) |
| First tenants | **Wall-E** (Tier P-SA, Super Admin), **Eve** (control path + reporting path), **Mo** (one per platform) | [wall-e/](wall-e/README.md), [eve/](eve/README.md), [mo/](mo/README.md) |
| Compliance | EU AI Act; TISAX | [agentic-platform/10-eu-ai-act.md](agentic-platform/10-eu-ai-act.md), [agentic-platform/11-tisax.md](agentic-platform/11-tisax.md) |
| Decisions | Dated, append-only records | [../decisions/](../decisions/README.md) |
| Superseded | Edge AI v2 | [edge-ai-v2/](edge-ai-v2/README.md) |

## Architecture

An employee reaches an agent through the tenant's one Gemini Enterprise app, and each agent runs
in its own factory-made project behind an ingress gateway with Model Armor and a default-deny
egress gateway; the reasoning layer never holds a credential, so every write goes through an
action service that holds it, applies the autonomy contract and writes an insert-only audit row.
The folder carries what Google can enforce once, and the tiers (C, R, W, P, P-SA, X —
[02 §1.1](agentic-platform/02-landing-zone-and-tiers.md#11-letters-not-numbers-and-how-the-briefs-t0tx-map))
add the controls that need people. Eve checks the doer from a model-free control path, Mo
measures both and changes production only through a merged pull request, and a fleet kill switch
sits outside every agent project. The design is the platform HLD
([§2](agentic-platform/01-hld.md#2-the-secure-gemini-enterprise-environment) Gemini Enterprise,
[§3](agentic-platform/01-hld.md#3-the-landing-zone) landing zone,
[§4](agentic-platform/01-hld.md#4-identity) identity,
[§6](agentic-platform/01-hld.md#6-gateways-and-model-armor) gateways and Model Armor,
[§7](agentic-platform/01-hld.md#7-monitoring-and-detection) monitoring,
[§11](agentic-platform/01-hld.md#11-the-tier-model) tiers,
[§13](agentic-platform/01-hld.md#13-the-three-agents-on-the-platform) the three agents); where
each resource lives and how every grant crosses a project is
[project-topology.md](project-topology.md).

## Constraints

No domain-wide delegation; the language model holds no credential and cannot approve; humans
raise autonomy and machines lower it — the full set of standing constraints is the platform HLD
[Status](agentic-platform/01-hld.md#status), with Wall-E's Super Admin as the owner's decision
of 2026-09-13 ([../decisions/2026-09-13-wall-e-holds-super-admin.md](../decisions/2026-09-13-wall-e-holds-super-admin.md)).
Residency is EU with sovereignty exceptions in
[08](agentic-platform/08-data-logging-retention-sovereignty.md), and compliance is the EU AI Act
([10](agentic-platform/10-eu-ai-act.md)) and TISAX ([11](agentic-platform/11-tisax.md)), with
GDPR, the DPIA and works-council information beside them. The review gates are the tier gate
(HLD [§0.4](agentic-platform/01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens)) and the admission gate (§5.3); who pays for what is HLD
§0.5, and the quota register is
[§3.4](agentic-platform/01-hld.md#34-labels-budgets-contacts-quotas).
