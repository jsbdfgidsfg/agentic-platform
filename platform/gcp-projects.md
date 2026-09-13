# GCP projects

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Maturity: skeleton, with the four planned projects of the agent platform recorded

## Inventory

The four agent-platform projects are **planned, not existing**, as of 2026-09-13. Project
ids are *tbd* (Wall-E's is decision D1 in [wall-e/SETUP.md](wall-e/SETUP.md) §1.1). Where
each resource lives and how every grant crosses between them is fixed in
[project-topology.md](project-topology.md), the single authority for placement.

| Project ID | Purpose | Env | Region(s) | Billing account | Notes |
|---|---|---|---|---|---|
| *tbd* — `GEMINI_PROJECT` | The Gemini Enterprise app: the human front door for Wall-E, its Discovery Engine service agent, the registration and share of Wall-E as a custom agent | **planned** (`Assumption:` the app already exists in a project of its own; [gemini-enterprise.md](gemini-enterprise.md) records it as *tbd*) | App location `eu` (or `global`) | *tbd* | Hosts nothing of Wall-E's, Eve's or Mo's. Whether it sits under `FOLDER_ID` is [project-topology.md](project-topology.md) decision 52. |
| *tbd* — `WALLE_PROJECT` (`PROJECT` inside Wall-E's own script and runbook) | Wall-E, the doer: the action service (the only credential holder), the dispatcher, the Agent Runtime engine, Firestore, `walle_audit`, `walle_workspace_logs`, the topics, secrets, Agent Registry and gateways | **planned** — created by [wall-e/SETUP.md](wall-e/SETUP.md) Phase 6 | `europe-west1`; BigQuery `EU` | *tbd* | Under folder `FOLDER_ID`. Budget `walle-stage-0`, 200 EUR (`Assumption:`). Never hosts Eve's key or secrets, nor Mo's datasets. |
| *tbd* — `EVE_PROJECT` | Eve, the controller: `eve-approval` KMS key, Eve's secrets and OAuth client, the `eve` dataset with the `walle_audit` mirror, `eve_workspace_logs`, the locked evidence bucket, `eve-gate`, `eve-reconciler`, `eve-console` | **planned** — created by [eve/07-build-runbook.md](eve/07-build-runbook.md) Phase 1 at Stage 0 | `europe-west1`; BigQuery `EU` | *tbd* | Under folder `FOLDER_ID`. `aiplatform.googleapis.com` is never enabled. Only three Wall-E principals may appear in its IAM policy (topology decision 48). |
| *tbd* — `MO_PROJECT` | Mo, continuous improvement: `mo-metrics@`, `mo-analyst@`, `mo-narrator@`, the four `walle_metrics*` datasets, the scheduled metric queries, the `walle-mo-proposals` drop box, `mo-reporter` | **planned** — created by Phase Mo-0b in [mo/07-build-runbook.md](mo/07-build-runbook.md) at Stage 0 (`gcloud projects create "$MO_PROJECT" --folder="$FOLDER_ID"`; before 2026-09-13 that runbook placed Mo inside Wall-E's project) | `europe-west1`; BigQuery `EU` | *tbd* | Under folder `FOLDER_ID`. Holds no credential, secret or key. No enforcement identity of the other projects holds any read here (denial test MD-9). |

Also in use but outside the platform's four: the pre-existing **M0 host project** for the
operator's OAuth client ([wall-e/PREREQUISITES.md](wall-e/PREREQUISITES.md) §5.1), and the
validator custodian's own project (*tbd*, Wall-E decision 37).

## Org structure

- All four platform projects are children of one folder, `FOLDER_ID`, which carries the
  Model Armor conformance floor. The organisation holds the three organisation-level log
  sinks: `walle-workspace-audit` and `walle-audit-bq` (destinations in `WALLE_PROJECT`,
  [wall-e/SETUP.md](wall-e/SETUP.md) Phase 11) and `eve-workspace-audit` (destination in
  `EVE_PROJECT`, [eve/07-build-runbook.md](eve/07-build-runbook.md) Phase 7);
  `walle-content-sink` is project-level, not organisation-level. Separately, the
  organisation policy `iam.allowedPolicyMemberDomains` needs an exception for
  `gmail-api-push@system.gserviceaccount.com` (the Gmail push subscription,
  [wall-e/PREREQUISITES.md](wall-e/PREREQUISITES.md) §4.2) — a domain-restricted-sharing
  exception, not a sink. Constraints to check per project:
  [project-topology.md](project-topology.md) §5.
- *(organisation id, other folders, org policies in force — tbd)*

## Key services in use

*(Vertex AI, Agent Builder / Agentspace, BigQuery, Cloud Run, etc.)* — per project, see the
"Hosts" column of [project-topology.md](project-topology.md) §2.

## Access & IAM

*(who has what, groups used for role binding — reference groups, not individuals)* — every
grant that crosses a project is a row of [project-topology.md](project-topology.md) §3;
owner groups per project are its decision 52.

## Quotas & limits to watch

*(model quotas, regional availability)*

## Secrets
Location only, never values: Wall-E's three regional secrets in `WALLE_PROJECT`; Eve's two
regional secrets in `EVE_PROJECT`; Mo holds none. Robot passwords in the corporate vault.
