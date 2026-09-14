# Platform overview

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Maturity: landing page for the platform design set; design only, nothing built. The
  "skeleton — to be filled" state ended 2026-09-13, when the platform HLD landed.
- Objective restated 2026-09-13; see the platform HLD
  ([agentic-platform/01-hld.md](agentic-platform/01-hld.md)).

## What this is

The agentic platform: internal AI agents for employees, built on Google Cloud
and integrated into Google Workspace, with Gemini Enterprise as the primary
end-user surface.

Since the objective of 2026-09-13 it is designed to sustain hundreds of agents, classical or
autonomous, and to hold a closed tier for future AGI-class agents, with enterprise-class
security and monitoring, an EU AI Act position and TISAX compatibility. Wall-E (the doer),
Eve (the controller) and Mo (continuous improvement) are its first three tenants, not the
platform itself.

## Building blocks

| Layer | Product | Page |
|---|---|---|
| Platform design | The platform HLD, its detailed pages 02–11 and the decision register P1.. | [agentic-platform/](agentic-platform/README.md), [agentic-platform/01-hld.md](agentic-platform/01-hld.md), [agentic-platform/12-open-decisions.md](agentic-platform/12-open-decisions.md) |
| End-user surface | Gemini Enterprise | [gemini-enterprise.md](gemini-enterprise.md) |
| Identity & collaboration | Google Workspace | [google-workspace.md](google-workspace.md) |
| Compute / data / models | GCP | [gcp-projects.md](gcp-projects.md) |
| Project layout | One project per agent under `fld-agentic-platform`, made by a factory, in a tier folder; five core projects; the Gemini Enterprise app project; Eve's two projects under `fld-controllers`; Mo under `fld-improvers`; a witness organisation outside the tenant. Rewritten 2026-09-13: this row said "Four GCP projects: Gemini Enterprise, Wall-E, Eve, Mo" — the four remain as the first instances of the pattern | [project-topology.md](project-topology.md), [agentic-platform/02-landing-zone-and-tiers.md](agentic-platform/02-landing-zone-and-tiers.md) |
| The agents themselves | — | [agents.md](agents.md) |
| First tenants | **Wall-E** (Tier P-SA, Super Admin), **Eve** (control path + reporting path), **Mo** (one per platform) | [wall-e/](wall-e/README.md), [eve/](eve/README.md), [mo/](mo/README.md) |
| Compliance | EU AI Act; TISAX | [agentic-platform/10-eu-ai-act.md](agentic-platform/10-eu-ai-act.md), [agentic-platform/11-tisax.md](agentic-platform/11-tisax.md) |
| Decisions | Dated, append-only records | [../decisions/](../decisions/README.md) |
| Superseded | Edge AI v2 | [edge-ai-v2/](edge-ai-v2/README.md) |

## Architecture

An employee reaches an agent through the one Gemini Enterprise app of the tenant (location
`eu`, Google Identity), whose egress gateway `gemini-egress` admits only the engines the agent
register lists as published; the app's Data Access log names the human behind every request.
Each agent runs in its own factory-made project under Agent Identity, behind an ingress gateway
with Model Armor and a default-deny egress gateway, so an injected prompt cannot reach a secret
or the internet through it. The reasoning layer never holds a credential: an agent that writes
does so through an action service that holds the credential, applies the autonomy contract and
writes an insert-only audit row. The folder carries what can be set once and enforced by Google
(organisation policy, deny policy, Principal Access Boundary, Model Armor floors, aggregated
sinks into a central logging project); tiers C, R, W, P, P-SA and X add the controls that need
people, and a tier does not open until those people and services exist. Eve checks the doer
from a separate, model-free control path and reports through a separate reporting path; Mo
measures both and changes production only through a pull request a human merges; a fleet kill
switch sits outside every agent project. The full design is the platform HLD
([agentic-platform/01-hld.md](agentic-platform/01-hld.md) §2 Gemini Enterprise, §3 landing zone,
§4 identity, §6 gateways and Model Armor, §7 monitoring, §11 tiers, §13 the three agents); where
each resource lives and how every grant crosses a project is
[project-topology.md](project-topology.md).

## Constraints

Standing constraints: no domain-wide delegation; the language model holds no credential and
cannot approve; humans raise autonomy and machines lower it; no model on Eve's approval path; Mo
reaches production only through a merged pull request; safety interlocks are plain
authenticated REST; no secrets in the wiki. Wall-E holds Super Admin by the owner's decision of
2026-09-13 ([../decisions/2026-09-13-wall-e-holds-super-admin.md](../decisions/2026-09-13-wall-e-holds-super-admin.md)),
which makes its grant a gate with its own checklist rather than a runbook step. Data residency
is EU (`in:eu-locations` at the platform folder; the app in `eu`), with sovereignty exceptions
recorded in [agentic-platform/08-data-logging-retention-sovereignty.md](agentic-platform/08-data-logging-retention-sovereignty.md).
Compliance is two named regimes: the EU AI Act, with a classification per system and the
declined promise of "bulletproof" stated ([agentic-platform/10-eu-ai-act.md](agentic-platform/10-eu-ai-act.md)),
and TISAX, with the super-admin deviation as its first risk ([agentic-platform/11-tisax.md](agentic-platform/11-tisax.md));
GDPR, the DPIA and works-council information sit beside them, the latter before Stage 1 of any
write agent acting on employee accounts. Security review gates are the tier gate
([agentic-platform/01-hld.md](agentic-platform/01-hld.md) §0.4) and the admission gate (§5.3).
Budget owner: the platform owner for platform lines, IT security for SCC, the SIEM and the
witness, and each agent owner's cost centre for its project; amounts are *tbd* (P31).
