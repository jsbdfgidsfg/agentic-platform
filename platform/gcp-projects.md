# GCP projects

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Maturity: skeleton, with the four planned projects of the agent platform recorded. Qualified
  2026-09-13: the four are the first instances of a project-per-agent pattern; the platform's
  core projects, Eve's reporting-path project and the witness organisation's project are
  recorded below as planned too.
- Objective restated 2026-09-13; see the platform HLD
  ([agentic-platform/01-hld.md](agentic-platform/01-hld.md) §3).

## Inventory

The four agent-platform projects are **planned, not existing**, as of 2026-09-13. Project
ids are *tbd* (Wall-E's is decision D1 in [wall-e/SETUP.md](wall-e/SETUP.md) §1.1). Where
each resource lives and how every grant crosses between them is fixed in
[project-topology.md](project-topology.md), the single authority for placement.

Qualified 2026-09-13: "four" is a count of the first tenants, not a design limit. Every agent
from Tier R up gets its own project, made by the factory (Cloud Foundation Fabric
`project-factory` wrapped as `agent-project`, `verifier-project`, `improver-project`, P35) in
its tier folder, so hundreds of agents are hundreds of rows here; Tier C agents have no project.
The runbook phases that created the four by hand (Wall-E SETUP Phase 6, Eve 07 Phase 1, Mo-0b)
become factory calls ([agentic-platform/02-landing-zone-and-tiers.md](agentic-platform/02-landing-zone-and-tiers.md) §3).

| Project ID | Purpose | Env | Region(s) | Billing account | Notes |
|---|---|---|---|---|---|
| *tbd* — `GEMINI_PROJECT` | The Gemini Enterprise app: the human front door for Wall-E, its Discovery Engine service agent, the registration and share of Wall-E as a custom agent | **planned** (`Assumption:` the app already exists in a project of its own; [gemini-enterprise.md](gemini-enterprise.md) records it as *tbd*) | App location `eu` (or `global`) | *tbd* | Hosts nothing of Wall-E's, Eve's or Mo's. Whether it sits under `FOLDER_ID` is [project-topology.md](project-topology.md) decision 52. **2026-09-13:** a platform project, imported in place by the factory's `tenant-app` module and moved under `fld-gemini-enterprise` with the Gemini Enterprise administrators' agreement (otherwise the one project outside the folder, controls re-applied at project level); also hosts `gemini-egress`, `gemini-registry` and the console Model Armor template `ge-console-standard`; the front door for every human-facing agent, not only Wall-E (HLD §2.1) |
| *tbd* — `WALLE_PROJECT` (`PROJECT` inside Wall-E's own script and runbook) | Wall-E, the doer: the action service (the only credential holder), the dispatcher, the Agent Runtime engine, Firestore, `walle_audit`, `walle_workspace_logs`, the topics, secrets, Agent Registry and gateways | **planned** — created by [wall-e/SETUP.md](wall-e/SETUP.md) Phase 6 | `europe-west1`; BigQuery `EU` | *tbd* | Under folder `FOLDER_ID`. Budget `walle-stage-0`, 200 EUR (`Assumption:`). Never hosts Eve's key or secrets, nor Mo's datasets. **2026-09-13:** under `fld-agents-p-sa` (Tier P-SA, the super-admin singleton); gains `walle-actions-super` (broad OAuth client, bands B and C) beside `walle-actions` (narrow client); the Agent Registry moves to `CORE_PROJECT` (P71); `walle_workspace_logs` becomes an authorised view in `LOGGING_PROJECT` (P104); created by the factory under a PAM grant (P142) |
| *tbd* — `EVE_PROJECT` | Eve, the controller: `eve-approval` KMS key, Eve's secrets and OAuth client, the `eve` dataset with the `walle_audit` mirror, `eve_workspace_logs`, the locked evidence bucket, `eve-gate`, `eve-reconciler`, `eve-console` | **planned** — created by [eve/07-build-runbook.md](eve/07-build-runbook.md) Phase 1 at Stage 0 | `europe-west1`; BigQuery `EU` | *tbd* | Under folder `FOLDER_ID`. `aiplatform.googleapis.com` is never enabled. Only three Wall-E principals may appear in its IAM policy (topology decision 48). **2026-09-13:** under `fld-controllers`; the `aiplatform` denylist is a project-level `restrictServiceUsage` on this project (not the folder); gains `eve-export@` (daily export and witness push), the `eve_quality` dataset Mo and the validator read, and the `eve_advice` dataset `eve-advisor` writes; the decision-48 carve-outs gain dated platform exceptions (topology §3) |
| *tbd* — `EVE_ADVISOR_PROJECT` | Eve's reporting path `eve-advisor` (may reason; report-only) | **planned** (added 2026-09-13, HLD §13.2; not built until P34 is signed and P19 answered) | `europe-west1`; BigQuery `EU` (`Assumption:` as `EVE_PROJECT`) | *tbd* | Under `fld-controllers`. No signer, no invoker, no secret; the one controller project where `aiplatform` is allowed |
| *tbd* — `MO_PROJECT` | Mo, continuous improvement: `mo-metrics@`, `mo-analyst@`, `mo-narrator@`, the four `walle_metrics*` datasets, the scheduled metric queries, the `mo-proposals` drop box (renamed 2026-09-13 from `walle-mo-proposals`), `mo-reporter` | **planned** — created by Phase Mo-0b in [mo/07-build-runbook.md](mo/07-build-runbook.md) at Stage 0 (`gcloud projects create "$MO_PROJECT" --folder="$FOLDER_ID"`; before 2026-09-13 that runbook placed Mo inside Wall-E's project) | `europe-west1`; BigQuery `EU` | *tbd* | Under folder `FOLDER_ID`. Holds no credential, secret or key. No enforcement identity of the other projects holds any read here (denial test MD-9). **2026-09-13:** under `fld-improvers`; one Mo per platform keyed on `agent_id`, measuring Wall-E and Eve; agent-neutral dataset and bucket names (`mo-proposals`) before Stage 0 (HLD §13.3) |
| *tbd* — `CORE_PROJECT` | Register of record, shared Agent Registry (`europe-west1`), evidence lake, ladder-state page, reconciliation job, drift job (`platform-drift@`), K7 fleet-kill job (`k7-executor@`) | **planned** (HLD §3.1) | `europe-west1`; BigQuery `EU` | *tbd* | Under `fld-platform-core`; no agent principal exists here; `platform-pager-key` is its one secret (a dated factory input) |
| *tbd* — `LOGGING_PROJECT` | Central logging: destination of the two aggregated sinks `S-org` and `S-folder`, locked EU log buckets, `platform_logs`, log views, billing export | **planned** (HLD §3.1, P104) | `europe-west1`; BigQuery `EU` | *tbd* | Under `fld-platform-core` |
| *tbd* — `CICD_PROJECT` | Cloud Build, shared Artifact Registry, SLSA provenance, Binary Authorization attestors, WIF pool for CI, Terraform state; `factory-apply@` | **planned** (HLD §3.1, P142) | `europe-west1` | *tbd* | Under `fld-platform-core` |
| *tbd* — `VALIDATOR_PROJECT` | The validator custodian's project (security reviewer) | **planned** (HLD §3.1) | `europe-west1`; BigQuery `EU` | *tbd* | Under `fld-platform-core`; replaces "the validator custodian's own project, *tbd*" below |
| *tbd* — `KMS_PROJECT` | Autokey key project: engine CMEK keys, platform-logs key; keys and nothing else | **planned** (added 2026-09-13, P118) | `europe-west1` | *tbd* | Under `fld-platform-core`; HSM protection level fleet-wide |
| *tbd* — `EVE_WITNESS_PROJECT` | Evidence mirror, `eve.incidents` copy, K5 rota records, severity 1/2 paging channels, absence alarm on Eve and on Google's feed | **planned** (added 2026-09-13, HLD §13.2; a precondition of the super-admin grant) | EU (`Assumption:`; *tbd* with P14) | *tbd* (P14: whether the platform's billing account may fund it) | **In a second organisation `org-witness`** on a separate Cloud Identity tenant, administered by two IT-security super admins outside the Wall-E line; not under `fld-agentic-platform` and not administered by the tenant's super admins |
| *tbd* — nonprod twins | A nonprod project per agent, optional at Tier R, mandatory from Tier W and for controllers and improvers | **planned** (P40) | as prod | *tbd* | Under the `-nonprod` folder of each tier; Tier P / P-SA nonprod acts against a sandbox Workspace tenant, never an OU of production |

Also in use but outside the platform's four: the pre-existing **M0 host project** for the
operator's OAuth client ([wall-e/PREREQUISITES.md](wall-e/PREREQUISITES.md) §5.1), and the
validator custodian's own project (*tbd*, Wall-E decision 37). 2026-09-13: the custodian's
project is `VALIDATOR_PROJECT` above.

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
- **Superseded 2026-09-13 (platform HLD §3.1, §7.1; P104):** `FOLDER_ID` becomes
  `fld-agentic-platform`, with child folders `fld-platform-core`, `fld-gemini-enterprise`,
  `fld-agents-r`, `fld-agents-w`, `fld-agents-p` (and `fld-agents-p-sa` beneath it),
  `fld-agents-x` (empty), `fld-controllers` and `fld-improvers`, each with prod and nonprod.
  The folder carries the organisation-policy baseline, the deny policy on agent principals, the
  Principal Access Boundary, the Model Armor floor, the Data Access audit configuration and the
  PAM entitlements. Wall-E's two organisation sinks are deleted and re-homed as fan-out sinks of
  `LOGGING_PROJECT` behind the two aggregated sinks `S-org` and `S-folder`; Eve's organisation
  sink `eve-workspace-audit` is kept, independent, widened to all six Workspace streams. The
  witness project is in a separate organisation.
- *(organisation id, other folders, org policies in force — tbd)*

## Key services in use

*(Vertex AI, Agent Builder / Agentspace, BigQuery, Cloud Run, etc.)* — per project, see the
"Hosts" column of [project-topology.md](project-topology.md) §2. The per-folder allow-lists of
`gcp.restrictServiceUsage` (which services each tier may enable at all) are
[agentic-platform/02-landing-zone-and-tiers.md](agentic-platform/02-landing-zone-and-tiers.md) §4.2.

## Access & IAM

*(who has what, groups used for role binding — reference groups, not individuals)* — every
grant that crosses a project is a row of [project-topology.md](project-topology.md) §3;
owner groups per project are its decision 52. 2026-09-13: no standing `roles/owner` on any
project after the factory runs — humans get predefined-role bundles through Privileged Access
Manager ([agentic-platform/04-identity-and-privileged-access.md](agentic-platform/04-identity-and-privileged-access.md));
the only standing organisation-level human roles are the two break-glass accounts (P69).

## Quotas & limits to watch

*(model quotas, regional availability)* — the quota register (P31) is
[agentic-platform/01-hld.md](agentic-platform/01-hld.md) §3.4: first row `GEMINI_PROJECT`'s
Model Armor sanitize quota; then Model Armor, Agent Gateway and Agent Registry per project,
reviewed quarterly by the platform owner.

## Secrets
Location only, never values: Wall-E's three regional secrets in `WALLE_PROJECT`; Eve's two
regional secrets in `EVE_PROJECT`; Mo holds none. Robot passwords in the corporate vault.
2026-09-13: Wall-E's second OAuth client (the broad client read only by `walle-actions-super`,
HLD §13.1 item 3) adds its own regional secrets in `WALLE_PROJECT`, one reader each (names
*tbd*); `CORE_PROJECT` holds `platform-pager-key`; break-glass hardware-key custody records are in
the witness bucket; `EVE_ADVISOR_PROJECT` holds no secret.
