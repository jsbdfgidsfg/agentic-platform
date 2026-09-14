# GCP projects

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Maturity: skeleton; the platform's projects are planned, not existing. The platform HLD
  ([agentic-platform/01-hld.md](agentic-platform/01-hld.md) §3) is the design they follow.

## Inventory

Every platform project is **planned, not existing**, as of 2026-09-14, and project ids are
*tbd*. Every agent from Tier R up gets its own factory-made project in its tier folder — a
pattern, not a count ([project-topology.md §1](project-topology.md#1-why-four-projects)). What
each project hosts and must never host, its folder, region, creator and billing, is
[project-topology.md §2](project-topology.md#2-the-four-projects), the single authority for
placement; the digest below names the projects only.

| Project | Variable(s) |
|---|---|
| Gemini Enterprise app | `GEMINI_PROJECT` |
| Wall-E, the doer | `WALLE_PROJECT` (`PROJECT` inside Wall-E's own script and runbook) |
| Eve, the controller, and its reporting path | `EVE_PROJECT`, `EVE_ADVISOR_PROJECT` |
| Mo, continuous improvement | `MO_PROJECT` |
| Platform core | `CORE_PROJECT`, `LOGGING_PROJECT`, `CICD_PROJECT`, `VALIDATOR_PROJECT`, `KMS_PROJECT` |

Beside them: nonprod twins per agent, and the witness project `EVE_WITNESS_PROJECT` in the
second organisation `org-witness`
([project-topology.md §2](project-topology.md#2-the-four-projects),
[eve/01-hld.md §1](eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness)).
Also in use but outside the platform: the pre-existing **M0 host project** for the operator's
OAuth client ([wall-e/PREREQUISITES.md](wall-e/PREREQUISITES.md) §5.1).

## Org structure

- The platform folder `fld-agentic-platform` holds the tier and role folders (`fld-platform-core`,
  `fld-gemini-enterprise`, `fld-agents-r`, `-w`, `-p` with `-p-sa`, `-x`, `fld-controllers`,
  `fld-improvers`, each with prod and nonprod) and carries the organisation-policy baseline, the
  deny policy, the Principal Access Boundary, the Model Armor floor, the Data Access audit
  configuration and the PAM entitlements — the tree is
  [02 §2.1](agentic-platform/02-landing-zone-and-tiers.md#21-the-tree).
- Log sinks — the aggregated `S-org` (organisation) and `S-folder` (`fld-agentic-platform`,
  intercepting) into `LOGGING_PROJECT`, and Eve's independent organisation sink
  `eve-workspace-audit` — are
  [08 §3.2](agentic-platform/08-data-logging-retention-sovereignty.md#32-the-sinks); Wall-E's
  `walle-content-sink` is project-level, not an organisation sink. The `gmail-api-push@`
  member exception to `iam.allowedPolicyMemberDomains` is row B5 of
  [02 §4.1](agentic-platform/02-landing-zone-and-tiers.md#41-the-baseline-every-constraint-by-exact-name).
- *(organisation id, other folders, org policies in force — tbd)*

## Key services in use

*(Vertex AI, Agent Builder / Agentspace, BigQuery, Cloud Run, etc.)* — per project, see the
"Hosts" column of [project-topology.md](project-topology.md) §2. The per-folder allow-lists of
`gcp.restrictServiceUsage` (which services each tier may enable at all) are
[agentic-platform/02-landing-zone-and-tiers.md](agentic-platform/02-landing-zone-and-tiers.md) §4.2.

## Access & IAM

*(who has what, groups used for role binding — reference groups, not individuals)* — every
grant that crosses a project is a row of [project-topology.md](project-topology.md) §3; owner
groups per project are its decision 52. Human access is Privileged Access Manager entitlements
([04 §5.2](agentic-platform/04-identity-and-privileged-access.md#52-the-catalogue)) and the
break-glass accounts
([04 §7](agentic-platform/04-identity-and-privileged-access.md#7-break-glass-accounts-and-their-custody)).

## Quotas & limits to watch

*(model quotas, regional availability)* — the quota register (P31) is
[agentic-platform/01-hld.md §3.4](agentic-platform/01-hld.md#34-labels-budgets-contacts-quotas).

## Secrets
Location only, never values. Wall-E's secrets, all in `WALLE_PROJECT`, are listed in
[wall-e/02-identity-and-auth.md](wall-e/02-identity-and-auth.md#where-each-secret-lives); Eve's
two regional secrets are in `EVE_PROJECT`; Mo and `EVE_ADVISOR_PROJECT` hold none;
`CORE_PROJECT` holds `platform-pager-key`; break-glass hardware-key custody records are in the
witness bucket; robot passwords are in the corporate vault.
