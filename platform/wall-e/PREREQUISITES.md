# Prerequisites for the administrator

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-15
- Status: **superseded on 2026-09-15**. Retired to a pointer page on 2026-09-16. Never executed. Nothing on this page is worked from again.
- Replaced by: [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) (platform prerequisites, roles, tools, the variables file), [03](../agentic-platform/setup/03-decisions-and-people.md) (decisions and people) and [04](../agentic-platform/setup/04-purchases-and-lead-times.md) (purchases by lead time) of the human-executed setup procedures in [../agentic-platform/setup/](../agentic-platform/setup/README.md).
- Review that retired it: [../agentic-platform/13-setup-procedure-review.md](../agentic-platform/13-setup-procedure-review.md) (S083, S059, X-ORG-04, X-ORG-05, X-RQB-09 among others).

This page listed what had to be true, decided, granted, bought or installed before the first
command of [SETUP.md](SETUP.md), for Wall-E alone. The setup review of 2026-09-15 found that the
prerequisites were complete only for Wall-E: no verified list existed for the organisation
roles, Security Command Center, the SIEM, the witness tenant, the sandbox tenant, break-glass or
the keys (S083); the roles it asked the builder to hold were standing organisation-level
privileges with no approval or expiry (S059); its purchase list was unsorted (X-RQB-09); its key
count was wrong; and the people it named could not all sign the gate true at once (X-ORG-05).
The platform-wide prerequisites, one decision register with signatories, and one purchase list
sorted by lead time now live in files 01, 03 and 04 of
[../agentic-platform/setup/README.md](../agentic-platform/setup/README.md), the one entry point.
Those files salvage the tables that were right (the people, tool and artefact rows, the
decision table, the purchase rows) and correct the rest.

## Where each section went

Step ids are those of the new files (prefix index: [setup README §5.1](../agentic-platform/setup/README.md#51-step-prefix-index)).

| Old section | New file | Steps |
|---|---|---|
| How to use this page, and the order the work happens | [setup README](../agentic-platform/setup/README.md) §2 and §3 | — |
| §1 decisions to close first (D1 to D13) | [03](../agentic-platform/setup/03-decisions-and-people.md) §7 to §11; D12 (the toil baseline) starts on day one in [02](../agentic-platform/setup/02-toil-baseline.md); D13 becomes the G1 to G18 checklist of [38](../agentic-platform/setup/38-super-admin-gate-and-grant.md) §1 | DC-7.* to DC-11.*, TB-1.*, GT-1.* |
| §2 people | [03](../agentic-platform/setup/03-decisions-and-people.md) §5 (appointed with dates, including the witness administrators and the second human); the role table in [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §2 | DC-5.*, PR-2.* |
| §3.1 roles, accounts, licences and physical artefacts | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §3; the key count stated once in [04](../agentic-platform/setup/04-purchases-and-lead-times.md) §4 | PR-3.*, PU-4.* |
| §3.2 edition features and tenant settings | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §3; the sandbox edition in [21](../agentic-platform/setup/21-sandbox-tenant-and-nonprod-foundation.md); the robot-OU settings in [30](../agentic-platform/setup/30-wall-e-workspace-side.md) | PR-3.*, SB-1.*, WW-5.* |
| §4.1 roles above project level | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §2; the bootstrap principals of [06](../agentic-platform/setup/06-organisation-bootstrap-and-roster.md); time-boxed entitlements in [12](../agentic-platform/setup/12-privileged-access-catalogue.md) replace every standing role (S059) | PR-2.*, OB-*, PA-* |
| §4.2 organisation policy constraints | [13](../agentic-platform/setup/13-organisation-policies-deny-and-pab.md), read before any project exists rather than per project afterwards | OP-* |
| §5.1 what you hold on each project | [10](../agentic-platform/setup/10-core-projects-and-ci-identities.md) for the core projects; [12](../agentic-platform/setup/12-privileged-access-catalogue.md) for the grants; the M0 host project and operator OAuth client are retired with the script path (SD-37) | CP-*, PA-* |
| §5.2 APIs the runbook enables | the module specs of [17](../agentic-platform/setup/17-factory-module-equivalents-and-tier-r-gate.md); per project, [22](../agentic-platform/setup/22-mo-foundations.md) §2, [23](../agentic-platform/setup/23-eve-project-and-evidence-stores.md) §2, [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §2 | FM-*, MO-2.*, EP-2.*, WD-2.* |
| §6 product availability and the 12b, 12c, 13b preconditions | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §3; the "Facts this file relies on" and "Unverified" sections of [34](../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md) and [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) | PR-3.*, WI-0.*, WE-0.* |
| §7.1 tools | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §4 | PR-4.* |
| §7.2 the config file `~/.walle-env` | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §5: one file, `~/.platform-env`, with `penv_set` and the variable register of the [setup README](../agentic-platform/setup/README.md) §5.2; `walle.env` exists only inside `walle_shell` and is deleted afterwards (S165) | PR-5.* |
| §8 the Wall-E code repository | [30](../agentic-platform/setup/30-wall-e-workspace-side.md) §1; the platform repository in [03](../agentic-platform/setup/03-decisions-and-people.md) §12; the missing code is indexed as B-16 and B-17 in the [setup README](../agentic-platform/setup/README.md) §8 | WW-1.*, DC-12.* |
| §9 security artefacts and lead-time items | [04](../agentic-platform/setup/04-purchases-and-lead-times.md) §1 and §2, sorted longest lead time first | PU-1.*, PU-2.* |
| §10 gaps this page found | absorbed into [../agentic-platform/13-setup-procedure-review.md](../agentic-platform/13-setup-procedure-review.md) §4 | — |
| §11 verify before Phase 1 | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §11; the sitting gate of [30](../agentic-platform/setup/30-wall-e-workspace-side.md) §0 | PR-6.*, WW-0.* |

## Retired headings

The headings below are kept only because other pages link to them. Each carries one pointer and
nothing else.

## 1. Decisions to close first

Moved to [03](../agentic-platform/setup/03-decisions-and-people.md) §7 to §11 (DC-7.* to DC-11.*); D12 to [02](../agentic-platform/setup/02-toil-baseline.md).

## 2. People

Moved to [03](../agentic-platform/setup/03-decisions-and-people.md) §5 (DC-5.*) and [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §2.

### 3.1 Roles, accounts, licences and physical artefacts

Moved to [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §3 (PR-3.*); the key count to [04](../agentic-platform/setup/04-purchases-and-lead-times.md) §4 (PU-4.*).

### 4.1 Roles you must hold above project level

Moved to [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §2, [06](../agentic-platform/setup/06-organisation-bootstrap-and-roster.md) and [12](../agentic-platform/setup/12-privileged-access-catalogue.md); standing roles survive only as the dated bootstrap exception that 12 withdraws.

## 9. Security artefacts and lead-time items

Moved to [04](../agentic-platform/setup/04-purchases-and-lead-times.md) §1 and §2 (PU-1.*, PU-2.*).

## Related documents

- [../agentic-platform/setup/README.md](../agentic-platform/setup/README.md), the one entry point
- [../agentic-platform/13-setup-procedure-review.md](../agentic-platform/13-setup-procedure-review.md), the review that retired this page
- [SETUP.md](SETUP.md), retired the same day
- [setup/README.md](setup/README.md), the helper script and why it is not used
