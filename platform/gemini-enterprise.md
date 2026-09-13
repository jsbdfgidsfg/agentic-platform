# Gemini Enterprise

## Status
- Owner: the platform owner (admin)
- Last reviewed: 2026-09-13
- Objective restated 2026-09-13; see the platform HLD
  ([agentic-platform/01-hld.md](agentic-platform/01-hld.md) §2 and §18 item 26).
- Maturity: pointer page since 2026-09-13. The security baseline of the tenant app — project and
  folder, administration, location and retention, identity provider, user population, feature
  toggles, console Model Armor, agent admission and revocation, the egress gateway, connectors,
  audit logging and the runbook — is
  [agentic-platform/03-gemini-enterprise-environment.md](agentic-platform/03-gemini-enterprise-environment.md),
  the detailed page under [agentic-platform/01-hld.md](agentic-platform/01-hld.md) §2. This page
  keeps only the tenant facts that runbook step GE-0 records.

## Tenant facts (filled at GE-0 of the baseline runbook)

| Item | Value |
|---|---|
| `GEMINI_PROJECT` / `GEMINI_PROJECT_NUMBER` | *tbd* |
| App id and location | *tbd* (must be `eu`; see 03 §5.1) |
| Identity provider shown in the console | *tbd* (decided: Google Identity, 03 P51) |
| Edition (Standard / Plus) | *tbd* (Plus gates assistant configuration, 03 §5.4) |
| Licence subscription and count | *tbd* |
| `CmekConfig` registered | *tbd* (03 §5.2) |
| Gateway bound (`agentGatewaySetting`) | *tbd* (03 §11) |
| Workspace service toggle: OUs ON; robot OU OFF | *tbd* (03 §7) |
| Context-Aware Access applicable to the app | *tbd* (03 §6) |

## Data sources connected

Governed by the org-policy allow-list of 03 §12; the connected list is generated from
`platform/agentic-platform/register/gemini-connectors.yaml` once it exists.

## Agents published here
→ [agents.md](agents.md), generated from the register (`publish_to_gemini`, `audience_groups`);
admission and revocation per 03 §10.

## Access model
→ 03 §4 (administrators), §7 (the three gates on users), §10.2 (what an administrator can and
cannot do to an agent).

## Known issues / limitations
→ 03 §18 (unverified items) and [agentic-platform/01-hld.md](agentic-platform/01-hld.md) §17.
