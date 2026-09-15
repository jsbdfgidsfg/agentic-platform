# 7. Building Mo

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Last executed: **never**
- Objective restated 2026-09-13 (platform HLD
  [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.3): the build includes
  Mo's Eve reads, tables, assertions, allowlist paths and denial test MD-15.
- Placement: every command here runs against **`MO_PROJECT`**, Mo's own project, except the
  three that are marked as Wall-E's owner's and run against `WALLE_PROJECT` from Wall-E's
  runbook, and the one marked as Eve's owner's, which runs against `EVE_PROJECT` from Eve's
  runbook. [`../project-topology.md`](../project-topology.md) is the authority for both.

## When to use this

To bring Mo into existence, one stage at a time, runnable by one person. Mo is not a
sitting; it is a series of them, spread along the stage floors of
[05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) at roughly a day a week.

The two S0 and S1 phases, **"Mo — metrics"** and **"Mo — reporting"**, run against
`MO_PROJECT` from this runbook and are **not** lifted into [SETUP.md](../wall-e/SETUP.md);
only their cross-project grants are made from Wall-E's runbook (change 17 of
[08-open-decisions.md](08-open-decisions.md); [`../project-topology.md`](../project-topology.md)
§7.1 and [§7.3](../project-topology.md#73-mo--mo07-build-runbookmd)).
Everything after S1 happens once SETUP has ended, so it lives only here. What exists at each
stage is [05-staging.md](05-staging.md#the-stage-table); the sittings are:

| Sitting | Stage | Phases |
|---|---|---|
| The baseline | Before Phase 1 | Mo-0 |
| "Mo — metrics" | S0 | Mo-1 (step 0 first) to Mo-5 |
| "Mo — reporting" | S1 | Mo-6 to Mo-8 |
| The gate, Spans, the narrator | S2 exit, S3, S4 (optional, [M-8](08-open-decisions.md)) | Mo-9, Mo-10, Mo-11 |
| Standing — the denial tests, at the end of every sitting and before every promotion | every stage | Mo-12 |

**Executing Mo-1 to Mo-5 changes no autonomy level.** It grants no Workspace credential, mints
no token, creates no Workspace account, opens no network path and puts nothing on the
enforcement path. It is one project, fifteen SQL files, one service account in that project,
and two dataset-level read grants into `WALLE_PROJECT`. That is deliberate: a Mo that is abandoned after S0 costs nothing to abandon, and the S0 and S1
exit criteria deliberately cite no verdict of Mo's ([05-staging.md](05-staging.md)).

**Nothing in this runbook gives Mo a write path into anything that enforces.** Mo holds no
secret at any phase, no git credential at any phase, and no Workspace credential ever. If a
step below appears to grant one, it is wrong — stop and read
[02-identity-and-access.md](02-identity-and-access.md).

---

## What already exists, and what does not

As of 2026-09-12 Wall-E's runbook held nothing of Mo's but `MO_PRINCIPAL`, an unresolved
member string used once for Phase 13b's `roles/agentregistry.viewer`; `mo-analyst` was not in
`SERVICE_ACCOUNT_IDS`, and `add_dataset_access` was called only for `walle-actions@` and the
`walle-audit-bq` sink writer. As of 2026-09-13 Wall-E's side carries Mo's cross-project grants
and nothing else of Mo's: `walle gcp` (SETUP Phase 7) makes the dataset-level `READER`s for
`mo-metrics@${MO_PROJECT}` on `walle_audit` and `walle_workspace_logs` (topology row 6)
alongside Eve's three readers, `walle deploy` (SETUP Phase 10) makes `run.invoker` on
`walle-actions` and the `READ_CALLER_ALLOWLIST` entry for `GET /v1/plans/{id}` and
`GET /v1/runs/{id}`, the accounts themselves are Mo-2 and Mo-6 below, and the rest of the
shared data plane [08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) promises is still unbuilt.
`MO_PRINCIPAL` resolves to `serviceAccount:mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com`,
and Phase 13b's project-level registry grant to it is removed (topology decision 43) — the
resolution and its consequences are
[02-identity-and-access.md](02-identity-and-access.md#6-mo_principal-resolved) §6.

> **Every Mo-side IAM grant, dataset, table, view, job, bucket and alert in this document is
> new.** Where a phase adds one, it is marked **NEW**. The cross-project grants Wall-E's and
> Eve's runbooks make are shown only for the build order.

---

## Prerequisites

### Upstream schema work that blocks phases, not decisions

These are not open questions. They are decided-and-not-landed changes to Wall-E's tables,
each defined, with its columns and its degraded behaviour, in
[08-open-decisions.md](08-open-decisions.md#what-this-design-forces-on-wall-es-set). Each one
silently empties a metric if the phase that needs it runs first.

| Blocks | Change | If it has not landed |
|---|---|---|
| Mo-4 | 1 and 2 — write-ahead `grades`, `proposal_verdicts`, `drills`; `ladder_events` | Plan precision, drill freshness, dwell and the ratchet are `not computable` and no cell is reported ready. Do **not** route around this by granting Mo Firestore access |
| Mo-4 | 4 to 7 — `actions.noop`, the four missing fingerprint columns, the `approvals` per-item vector, the `capability_gap` enum | Each metric carries its labelled degraded state rather than a quietly wrong number |
| Mo-7 | 8 — the canonical plan serialisation, before the approve endpoint is built | The weekly plan/audit agreement check is dropped, and Mo-6 should not grant `roles/run.invoker` |

### Decisions that must be closed before the phase that needs them

Each decision, its recommendation and its fallback if unanswered are in
[08-open-decisions.md](08-open-decisions.md#the-eleven-open-decisions). By phase: **M-1** and
**M-5** before Mo-1; **M-11** (d) before the Eve-pack queries of Mo-4; **M-11** (a) before
Mo-6; **M-3** before Mo-8; **M-7** and **M-11** (c) before Mo-9; **M-11** (b) before Mo-10;
**M-8** before Mo-11; **M-4** and **M-6** before S2 entry.

### Access you need, and where to get it early

| What | Where | Phase | Lead time |
|---|---|---|---|
| `roles/resourcemanager.projectCreator` on `FOLDER_ID` and Billing Account User on the billing account, to create `MO_PROJECT`; then owner of `MO_PROJECT`, or the narrower set below | The folder; then `MO_PROJECT` | Mo-1 step 0, then Mo-1 onward | Same day if you already hold the folder role; otherwise calendar time |
| `bigquery.transfers.update` on the project, **and** Service Account User on `mo-metrics@` | `MO_PROJECT` | Mo-4 | Same day. Both are required to pin a scheduled query to a service account |
| The two dataset `READER` entries on `walle_audit` and `walle_workspace_logs` for `mo-metrics@${MO_PROJECT}` (the logs half becomes `READER` on `platform_logs_views` in `LOGGING_PROJECT`, made by the factory, once the logs are re-homed there — P104, P107, topology row 40) | **`WALLE_PROJECT`** — Wall-E's owner's step, run from Wall-E's runbook (`walle_setup.py` `add_dataset_access`, SETUP Phase 7) with `MO_PROJECT` set in `walle.env`. Mo's builder hands over the project id and does **not** need `walle_audit` access | Mo-2 | Same day once `MO_PROJECT` exists |
| The `roles/run.invoker` binding on `walle-actions` for `mo-analyst@${MO_PROJECT}` | **`WALLE_PROJECT`** — Wall-E's owner's step, SETUP Phase 10's invoker loop, plus the in-app allowlist email | Mo-6 | Same day once `mo-analyst@` exists |
| **`roles/observability.editor`** | **`WALLE_PROJECT`** (`Assumption:` the trace bucket is Wall-E's engine's) | Mo-10 | **Allow calendar time** if you do not already hold it. One human holds it once, to create the linked trace dataset. Mo never holds it |
| Repository admin on the config repository, to add a required CI check and to set branch protection | Git host | Mo-9 | `tbd` until [M-7](08-open-decisions.md) names the host |
| The **validator custodian** ([decision 37](../wall-e/09-open-decisions.md)), who owns the recompute check from outside the config repository | Organisation | Mo-9 | Name them at S2, not at S2 exit. Roughly 3 of Mo-9's days are theirs, not Mo's |
| Two named humans who will grade | Tenant | Mo-8 | See [M-4](08-open-decisions.md). Mo cannot supply a person |
| `gcloud` **563.0.0 or later**, `bq`, `python 3.12`, `openssl` | Your machine | all | Mo-10's command needs that version |

Every grant above that crosses a project is a row of
[`../project-topology.md`](../project-topology.md#3-cross-project-grants) §3, which is the
authority for its level and its maker.

**No Workspace access is needed at any phase.** Mo has no Workspace account, no OAuth
client, no scope, no consent, no licence and no hardware key. That is the shortest statement
of what Mo is.

### Set these once per shell

```bash
# ---- The four projects (../project-topology.md section 6) --------------------
export WALLE_PROJECT="<walle-project-id>"     # PROJECT in Wall-E's own runbook
export EVE_PROJECT="<eve-project-id>"
export MO_PROJECT="<mo-project-id>"           # does not exist until Mo-1 step 0
export FOLDER_ID="<folder-id>"                # the one folder all four sit under
export REGION="europe-west1"
export BQ_LOCATION="EU"
export DOMAIN="<primary-domain>"
export OPERATORS="walle-operators@${DOMAIN}"
export ACTIONS_URL="<https url of walle-actions, in WALLE_PROJECT>"

# ---- Wall-E's identities, in WALLE_PROJECT ----------------------------------
export SA_ACTIONS="walle-actions@${WALLE_PROJECT}.iam.gserviceaccount.com"
export SA_AGENT="walle-agent@${WALLE_PROJECT}.iam.gserviceaccount.com"
export SA_DISPATCH="walle-dispatcher@${WALLE_PROJECT}.iam.gserviceaccount.com"

# ---- Eve's controller, in EVE_PROJECT (../eve/07-build-runbook.md) ----------
export SA_EVE="eve-controller@${EVE_PROJECT}.iam.gserviceaccount.com"

# ---- Mo's three identities, in MO_PROJECT, none of which exists yet ---------
export SA_MO_METRICS="mo-metrics@${MO_PROJECT}.iam.gserviceaccount.com"
export SA_MO_ANALYST="mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com"
export SA_MO_NARRATOR="mo-narrator@${MO_PROJECT}.iam.gserviceaccount.com"

export MO_PROPOSALS="gs://mo-proposals"   # created in MO_PROJECT; agent-neutral name (04 §3.7)
export MO_AR="${REGION}-docker.pkg.dev/${MO_PROJECT}/mo"     # Artifact Registry in MO_PROJECT

echo "MO_PROJECT=$MO_PROJECT WALLE_PROJECT=$WALLE_PROJECT REGION=$REGION BQ_LOCATION=$BQ_LOCATION"
```

`PROJECT` in Wall-E's runbook is `WALLE_PROJECT` here; Mo's runbook never uses a bare
`PROJECT`. `MO_PROJECT_NUMBER` is recorded in Mo-1 step 0, once the project exists.

Save it to `~/.mo-env`, `source` it at the start of every session, and guard it the way
Wall-E's runbook does — this build spans months, not a week:

```bash
[ -n "$MO_PROJECT" ] && [ -n "$WALLE_PROJECT" ] || { echo 'env not sourced'; return 1; }
```

`SA_EVE` is `eve-controller@${EVE_PROJECT}`: Eve is built in
`EVE_PROJECT` per [../eve/07-build-runbook.md](../eve/07-build-runbook.md), and denial test
**MD-9** below names that account. A test that names an account which does not exist passes
for the wrong reason, so the address is checked before the test runs.

---

# Phase "Mo — metrics" (Stage 0)

Runs against `MO_PROJECT` from this runbook, after `MO_PROJECT` exists (Mo-1 step 0) and
after Wall-E's Phase 7 has created the datasets being granted. Only the cross-project grant
step slots into [SETUP.md](../wall-e/SETUP.md) after Phase 7, which is where `walle_audit`
comes into existence (`Assumption:` Phase 7b is a free number), and the invoker entry into
Phase 10; both are marked below as **Wall-E's owner's**.

---

## Phase Mo-0 — The toil baseline

**This is the only part of Mo that must exist before Wall-E does**, and it is the only phase
that cannot be caught up afterwards. [Decision 38](../wall-e/09-open-decisions.md)'s
stop-or-continue review divides measured toil saved by operating cost, and the denominator
of that fraction is how long the top three admin tasks take **today**, by hand. Once Wall-E
is running the tasks, there is no way back to that number.

It is a human measurement. No command creates it.

**Manual steps.**

1. Pick the top three admin tasks by volume — the same three the pilot's first playbooks
   will cover.
2. For four consecutive weeks, the people who do them record, per instance: the date, the
   task, elapsed handling time, and whether it was interrupted.
3. Record the monthly human operating hours the programme consumes, separately.
4. Commit the result as `config/metrics/toil_baseline.csv` under the same reviewers
   `config/ladder.yaml` carries.

The file is **never estimated by Mo, never inferred from audit rows, and never edited
outside a pull request**. A loader scheduled query reads it into `walle_metrics` in Phase
Mo-4; that is the only automated thing that touches it.

**Verify.** The committed file has at least four distinct week-numbers, three distinct task
identifiers, a median handling time per task, and a monthly operating-hours row. A missing
operating-hours row is the common failure: the cost report's "Why worth it" line is
approval events × measured median handling time, and the comparison it feeds is against
operating cost **including human hours**.

**Rollback.** Delete the file. There is nothing to undo in any cloud, and nothing to
recover: the four weeks are gone, and a re-measurement after Wall-E starts measures a
different world.

---

## Phase Mo-1 — step 0, the project **NEW**

Nothing of Mo's is created in Wall-E's project. Mo gets a project of its own under the same
folder, so that no Wall-E, Eve or Gemini principal can hold anything in it and no Mo principal
holds a project-level role anywhere else ([`../project-topology.md`](../project-topology.md)
§1, §2). `--folder` and `--organization` are alternatives, and a project parented straight to
the organisation inherits nothing from the folder's Model Armor floor.

```bash
gcloud projects create "$MO_PROJECT" --folder="$FOLDER_ID" \
  --name="Mo — continuous improvement"

gcloud billing projects link "$MO_PROJECT" --billing-account=<billing-account-id>

# aiplatform.googleapis.com is NOT enabled here: only at Mo-11, if T2 is ever built
gcloud services enable \
  bigquery.googleapis.com bigquerydatatransfer.googleapis.com \
  run.googleapis.com cloudscheduler.googleapis.com monitoring.googleapis.com \
  storage.googleapis.com artifactregistry.googleapis.com \
  --project="$MO_PROJECT"

export MO_PROJECT_NUMBER="$(gcloud projects describe "$MO_PROJECT" --format='value(projectNumber)')"
echo "MO_PROJECT_NUMBER=$MO_PROJECT_NUMBER"   # add it to ~/.mo-env

# the Artifact Registry repository the reporter and narrator images are pushed to
gcloud artifacts repositories create mo --repository-format=docker \
  --location="$REGION" --project="$MO_PROJECT"
```

`Assumption:` a budget of 50 EUR at S0 per topology decision 52, created with
`gcloud billing budgets create --filter-projects=projects/${MO_PROJECT_NUMBER}` the way
Wall-E's Phase 6 does, and adjusted after one measured cycle.

**Hand-off.** Wall-E's `walle.env` receives the `MO_PROJECT` value now: every cross-project
grant Wall-E's runbook makes for Mo (Mo-2's two `READER`s, Mo-6's `run.invoker`) is spelled
from it. The CI that pushes images to `MO_AR` needs `roles/artifactregistry.writer` on that
repository in `MO_PROJECT` — the identity is *tbd* with the git host ([M-7](08-open-decisions.md)).

**Verify.**

```bash
gcloud projects describe "$MO_PROJECT" --format='value(parent.type,parent.id,lifecycleState)'
# expect: folder <FOLDER_ID> ACTIVE — never organization

gcloud services list --enabled --project="$MO_PROJECT" --format='value(config.name)' \
  | grep -c -E 'bigquery|bigquerydatatransfer|run|cloudscheduler|monitoring|storage|artifactregistry'
# expect: 7, and aiplatform.googleapis.com absent

gcloud projects get-iam-policy "$MO_PROJECT" --flatten='bindings[].members' \
  --format='value(bindings.members)' \
  | grep -E "@${WALLE_PROJECT}\.iam|@${EVE_PROJECT}\.iam|gcp-sa-discoveryengine"
# expect: nothing. MD-9b, from the first day
```

Then confirm that the folder's Model Armor floor binds the new project, with the command
[PREREQUISITES](../wall-e/PREREQUISITES.md) §10 item 20 records for the folder check — a
project parented straight to the organisation shows no floor, and `gcloud beta projects move`
is the repair ([`../project-topology.md`](../project-topology.md) §5). Confirm each of the
organisation-policy constraints in that page's §5 with the commands in PREREQUISITES §4.2.

**Rollback.**

```bash
gcloud projects delete "$MO_PROJECT"
```

Nothing outside the project references it yet. Once Mo-2's grants exist in `WALLE_PROJECT`,
remove those two `access` entries first, or they dangle.

---

## Phase Mo-1 — the four Mo datasets **NEW**

Four datasets, for the same reason Wall-E's Phase 7 makes two: their reader sets differ, and
in BigQuery the **dataset is the unit of read access**. `walle_metrics` has a **wider reader
set than `walle_audit`** — which is precisely why suppression is a mechanism in
[03-metrics-contract.md](03-metrics-contract.md) and not a promise.

| Dataset | Holds | Who may read it |
|---|---|---|
| `walle_metrics` | The scorecard and the sixteen aggregates | `mo-metrics@` (WRITER), `mo-analyst@` (READER) |
| `walle_metrics_archive` | Dated scorecard snapshots | `mo-metrics@` (WRITER), `mo-analyst@` (READER) |
| `walle_metrics_private` | `principal_surrogates`, and nothing else | `mo-metrics@` (WRITER). **No reader, ever, to any principal** |
| `walle_metrics_views` | The agent-facing authorised views. **No tables** | `mo-narrator@` (READER, from Mo-11) |

The last two are not tidiness. `principal_surrogates` cannot live in `walle_metrics`, because
`mo-analyst@`'s `READER` there is **dataset-level** and covers every table in the dataset —
including the mapping, and including any table added to that dataset later with no design
review. A surrogate that can be joined back to an email is not a surrogate. And the views
cannot live in `walle_metrics` either: Google requires an authorized view to sit in "a
different dataset than the dataset used in the source query"
([Authorized views](https://docs.cloud.google.com/bigquery/docs/authorized-views), verified
2026-09-12), so a view defined beside its source table is not an authorized view at all.

```bash
bq --location="$BQ_LOCATION" mk --dataset \
   --description="Mo's computed metrics. Written only by mo-metrics@. Read by NOTHING on Wall-E's enforcement path." \
   "${MO_PROJECT}:walle_metrics"

bq --location="$BQ_LOCATION" mk --dataset \
   --description="Dated scorecard snapshots. The citable object a promotion points at." \
   "${MO_PROJECT}:walle_metrics_archive"

bq --location="$BQ_LOCATION" mk --dataset \
   --description="The surrogate mapping, alone. Written only by mo-metrics@. NO READER, EVER." \
   "${MO_PROJECT}:walle_metrics_private"

bq --location="$BQ_LOCATION" mk --dataset \
   --description="Agent-facing authorised views over walle_metrics. Views only, no tables." \
   "${MO_PROJECT}:walle_metrics_views"
```

All four must be `EU`: an authorized view and its source must share a regional location, and
a cross-location, cross-project join against `walle_audit` fails outright. Check the source
side too, before creating anything:

```bash
bq show --format=prettyjson "${WALLE_PROJECT}:walle_audit" | grep '"location"'
# expect: EU. Any other answer means the join in Mo-4 cannot run, and nothing here helps.
```

The scorecard and the sixteen supporting aggregates, partitioned on `as_of`. Schemas live in
`schemas/mo_*.json` in the repository; columns are specified in
[03-metrics-contract.md](03-metrics-contract.md), which is authoritative wherever this page's
SQL names one.

`Assumption:` the nineteen table names in the loop below, the single agent-facing view
`walle_metrics_views.v_cell_public` used as the example in Mo-6, the metric SQL filenames
under `config/metrics/`, and `config/metrics/graders.yaml` for the committed grader list are
this runbook's names for objects the design describes without naming. The sixteen `agg_*`
names are the design's own.

```bash
# Metric 9b's aggregate, and the Eve quality pack's tables (03-metrics-contract.md §7.2, §7.3). Create the Eve-pack tables only once Eve's runbook has created
# eve_quality and granted mo-metrics@ on it (Mo-2, Eve's owner's step).
#   agg_uncatalogued_admin_events
#   eve_scorecard agg_eve_false_refusal agg_eve_wrong_accept agg_eve_agreement agg_eve_pages
#   agg_eve_time_to_verdict agg_eve_time_to_ack agg_eve_availability agg_eve_seeded_faults
#   agg_eve_divergence
# Same bq mk shape and schemas/mo_<table>.json as the loop below; every table carries agent_id.

# 34560000 seconds = 400 days, matching walle_audit.
# Assumption: 400 days pending Wall-E decision 17 (M-5). The floor is read from gates.yaml
# query time, so a later, shorter answer clamps the windows without a table rebuild.
for T in scorecard \
         agg_precision_cell agg_verification_cell agg_reliability_playbook \
         agg_invalid_params_cell agg_invariant_denials agg_breaker_trips \
         agg_audit_completeness agg_drill_freshness agg_approval_latency \
         agg_eve_latency agg_sample_coverage agg_regression_attribution \
         agg_cost_operation agg_cost_playbook agg_value_toil agg_capability_gap \
         grading_worklist toil_baseline; do
  bq mk --table \
    --time_partitioning_field=as_of \
    --time_partitioning_type=DAY \
    --time_partitioning_expiration=34560000 \
    "${MO_PROJECT}:walle_metrics.${T}" "./schemas/mo_${T}.json"
done

# the surrogate mapping, in the private dataset, alone
bq mk --table \
  --time_partitioning_field=as_of \
  --time_partitioning_type=DAY \
  --time_partitioning_expiration=34560000 \
  "${MO_PROJECT}:walle_metrics_private.principal_surrogates" \
  "./schemas/mo_principal_surrogates.json"
```

`principal_surrogates` is **deliberately not in that loop**. It is the one table whose
presence in `walle_metrics` would make every surrogate in every view and every artefact
reversible by `mo-analyst@`, and moving it is the whole of that fix.

`bq mk` rejects a clustering field that is not in the supplied schema, so a loop like this
one dies partway and leaves some tables created and some not. Re-running it after a fix is
safe — `bq mk` on an existing table is an error, not an overwrite — but read the error
before assuming it is the harmless one.

**Verify.**

```bash
bq show --format=prettyjson "${MO_PROJECT}:walle_metrics" | grep -E '"location"|"datasetId"'
# expect: EU

bq show --format=prettyjson "${MO_PROJECT}:walle_metrics.scorecard" \
  | grep -E 'timePartitioning|expirationMs' -A3
# expect: DAY partitioning on as_of, expirationMs 34560000000

bq ls --format=prettyjson "${MO_PROJECT}:walle_metrics" | python3 -c \
  "import json,sys; d=json.load(sys.stdin); print(len(d), 'objects')"
# expect: 19 — principal_surrogates is NOT among them; 30 once the metric-9b and Eve-pack tables exist

bq ls --format=prettyjson "${MO_PROJECT}:walle_metrics_private" | python3 -c \
  "import json,sys; d=json.load(sys.stdin); print(len(d), 'objects')"
# expect: 1 — principal_surrogates and nothing else

bq ls --format=prettyjson "${MO_PROJECT}:walle_metrics_views" | python3 -c \
  "import json,sys; d=json.load(sys.stdin); print(len(d), 'objects')"
# expect: 0 at this phase; the views arrive in Mo-6

for DS in walle_metrics walle_metrics_archive walle_metrics_private walle_metrics_views; do
  bq show --format=prettyjson "${MO_PROJECT}:${DS}" | grep -E '"location"'
done
# expect: EU, four times
```

All four datasets must report `EU`. A dataset created in the wrong location cannot be moved,
a cross-location join against `walle_audit` fails outright rather than quietly, and an
authorized view whose source dataset is in another location is refused.

**Rollback.**

```bash
bq rm -r -f -d "${MO_PROJECT}:walle_metrics"
bq rm -r -f -d "${MO_PROJECT}:walle_metrics_archive"
bq rm -r -f -d "${MO_PROJECT}:walle_metrics_private"
bq rm -r -f -d "${MO_PROJECT}:walle_metrics_views"
```

Nothing outside these four datasets has changed, and nothing in them is irreplaceable at this
phase — every row is recomputable from `walle_audit` by definition. That stops being true
from Mo-5, when the archive holds dated snapshots that decision files cite; take those out
before rolling back after S2.

---

## Phase Mo-2 — `mo-metrics@` and its grants **NEW**

**Why a pinned service account and not your own credentials.** BigQuery scheduled queries
run under the BigQuery Data Transfer Service, and "by default, scheduled queries run using
user credentials"
([Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries),
verified 2026-09-12). An evidence series that runs as the person who also administers
Wall-E is not independent, and it dies the day they leave. `--service_account_name` is the
whole of the fix.

```bash
gcloud iam service-accounts create mo-metrics --project="$MO_PROJECT" \
  --display-name="Mo T0 — committed metric SQL, no model, no egress"

# job creation only, in MO_PROJECT: the job runs and is billed where it is submitted,
# wherever the data is. NOT dataViewer at project level: that would be a lateral path
# into every dataset in Mo's project — and never ANY project-level role in WALLE_PROJECT.
gcloud projects add-iam-policy-binding "$MO_PROJECT" \
  --member="serviceAccount:${SA_MO_METRICS}" --role=roles/bigquery.jobUser

# the Data Transfer Service impersonates this account; the human creating the config
# must be allowed to say so (verified 2026-09-12, "Service accounts with BigQuery
# Data Transfer": the updating user needs bigquery.transfers.update and access to the
# service account)
gcloud iam service-accounts add-iam-policy-binding "$SA_MO_METRICS" \
  --project="$MO_PROJECT" \
  --member="user:$(gcloud config get-value account)" \
  --role=roles/iam.serviceAccountUser
```

The read grants are **dataset-level, never project-level**, and two of them are
**cross-project**: the dataset is in `WALLE_PROJECT`, the member is in `MO_PROJECT`.
`bq add-iam-policy-binding` operates on tables, views and connections, not datasets, so
dataset access is edited through the dataset's own `access` array, in the dataset's project:

```bash
grant_dataset () {   # grant_dataset <project> <dataset> <ROLE> <member-email>
  bq show --format=prettyjson "${1}:$2" > /tmp/ds.json
  DS_ROLE="$3" DS_SA="$4" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/ds.json'))
d.setdefault('access', []).append(
    {"role": os.environ['DS_ROLE'], "userByEmail": os.environ['DS_SA']})
json.dump(d, open('/tmp/ds.json', 'w'))
EOF
  bq update --source=/tmp/ds.json "${1}:$2"
}

# ---- Wall-E's owner's step, in WALLE_PROJECT, from Wall-E's runbook -----------
# These two lines are walle_setup.py add_dataset_access with member mo-metrics@${MO_PROJECT},
# keyed on the MO_PROJECT config key (SETUP Phase 7). Shown here for the build order only:
# Mo's builder does not run them and needs no access to walle_audit.
grant_dataset "$WALLE_PROJECT" walle_audit           READER "$SA_MO_METRICS"
grant_dataset "$WALLE_PROJECT" walle_workspace_logs  READER "$SA_MO_METRICS"
# Reversed 2026-09-13 (P104, P107, topology row 40): Wall-E's organisation sink is deleted and
# walle_workspace_logs becomes the authorised view platform_logs_views.walle_workspace_logs in
# LOGGING_PROJECT. Once it has, the line above is replaced by dataset-level READER on
# "${LOGGING_PROJECT}:platform_logs_views" for mo-metrics@, made by the factory's platform-core
# module, and Mo's builder runs neither.

# ---- Eve's owner's step, in EVE_PROJECT, from Eve's runbook ----------------------
# Dataset-level READER on eve_quality for mo-metrics@${MO_PROJECT} (platform HLD §13.3,
# §18 items 17 and 25; 02-identity-and-access.md §2.1). Made by Eve's owner once Eve's
# observe-and-report layer has created eve_quality. Shown for the build order only: Mo's
# builder does not run it, holds nothing in EVE_PROJECT, and makes no binding in MO_PROJECT
# in return. Never on the eve dataset itself, never on grades_blind or review_queue_blind.
grant_dataset "$EVE_PROJECT" eve_quality READER "$SA_MO_METRICS"

# ---- Mo's own, in MO_PROJECT --------------------------------------------------
grant_dataset "$MO_PROJECT" walle_metrics         WRITER "$SA_MO_METRICS"
grant_dataset "$MO_PROJECT" walle_metrics_archive WRITER "$SA_MO_METRICS"
grant_dataset "$MO_PROJECT" walle_metrics_private WRITER "$SA_MO_METRICS"
grant_dataset "$MO_PROJECT" walle_metrics_views   WRITER "$SA_MO_METRICS"
```

The cross-project pair rests on BigQuery's job-project / data-project split: the principal
needs "`bigquery.jobs.create` on the project from which the query is being run, regardless of
where the data is stored" and `bigquery.tables.getData` on every referenced table, and "the
querying project is billed for the query job while the project storing the data is billed for
the amount of data stored" ([Run a query](https://docs.cloud.google.com/bigquery/docs/running-queries),
verified 2026-09-13). So `jobUser` is in `MO_PROJECT`, `READER` is on Wall-E's datasets, and
nothing of Mo's is ever bound at project level in `WALLE_PROJECT`.

`walle_metrics_private` gets exactly this one entry and **never another**. Every later phase
that adds a reader adds it to `walle_metrics`, `walle_metrics_archive` or
`walle_metrics_views`; a reader on the private dataset would undo the surrogate scheme
silently, which is why MD-13 tests for its absence rather than trusting the runbook.

`WRITER` is the dataset-level form of `roles/bigquery.dataEditor`, and the account
additionally needs `bigquery.datasets.get` and `bigquery.datasets.update` on the **target**
dataset for the Data Transfer Service to write there — both of which `WRITER` carries
([Service accounts with BigQuery Data Transfer](https://docs.cloud.google.com/bigquery/docs/use-service-accounts),
verified 2026-09-12).

> **Six grants plus one.** Two of the six are cross-project and are made by Wall-E's runbook
> (change 3 of [08-open-decisions.md](08-open-decisions.md)); four are in-project and are made
> here. A seventh, the `eve_quality` `READER`, is cross-project and lands in Eve's runbook
> (change 20). Its verify is denial test MD-15 (a), run as `mo-metrics@` from `MO_PROJECT`,
> because Mo's builder cannot read `EVE_PROJECT`'s access lists; that query also proves
> `eve_quality` is in `EU`, since a cross-location query fails outright.

**Verify.**

```bash
for DS in "${WALLE_PROJECT}:walle_audit" "${WALLE_PROJECT}:walle_workspace_logs" \
          "${MO_PROJECT}:walle_metrics" "${MO_PROJECT}:walle_metrics_archive" \
          "${MO_PROJECT}:walle_metrics_private" "${MO_PROJECT}:walle_metrics_views"; do
  echo "== $DS"
  bq show --format=prettyjson "$DS" | python3 -c \
    "import json,sys;[print(a) for a in json.load(sys.stdin)['access']]"
done
# expect: mo-metrics@${MO_PROJECT} READER on walle_audit and walle_workspace_logs, and
#         (P104) READER on ${LOGGING_PROJECT}:platform_logs_views instead of
#         walle_workspace_logs once the factory has re-homed it;
#         WRITER on neither of them. WRITER on the four walle_metrics* datasets only.
#         walle_metrics_private must show mo-metrics@ and NO other principal.

# prove the negative at project level, in BOTH projects
gcloud projects get-iam-policy "$MO_PROJECT" --flatten='bindings[].members' \
  --filter="bindings.members:${SA_MO_METRICS}" --format='value(bindings.role)'
# expect: roles/bigquery.jobUser, and nothing else. No dataViewer, no dataEditor,
#         no run.invoker, no secretmanager.secretAccessor, no aiplatform.user.

gcloud projects get-iam-policy "$WALLE_PROJECT" --flatten='bindings[].members' \
  --filter="bindings.members:${SA_MO_METRICS}" --format='value(bindings.role)'
# expect: NOTHING. A Mo principal holds no project-level role in another project
#         (../project-topology.md section 3 row 26).

# it holds no secret, at any phase — Wall-E's secrets are in WALLE_PROJECT, Eve's in
# EVE_PROJECT, and there are none in MO_PROJECT
for S in walle-refresh-token walle-oauth-client walle-confirm-hmac; do
  gcloud secrets get-iam-policy "$S" --project="$WALLE_PROJECT" \
    --flatten='bindings[].members' \
    --filter="bindings.members:${SA_MO_METRICS}" --format='value(bindings.role)'
done
for S in eve-oauth-client eve-refresh-token; do
  gcloud secrets get-iam-policy "$S" --project="$EVE_PROJECT" \
    --flatten='bindings[].members' \
    --filter="bindings.members:${SA_MO_METRICS}" --format='value(bindings.role)'
done
gcloud secrets list --project="$MO_PROJECT" --format='value(name)'
# expect: nothing, five times; and an empty list
```

**Rollback.** Remove the six `access` entries the same way they were added — the two in
`WALLE_PROJECT` by Wall-E's owner, the four in `MO_PROJECT` here — then

```bash
gcloud projects remove-iam-policy-binding "$MO_PROJECT" \
  --member="serviceAccount:${SA_MO_METRICS}" --role=roles/bigquery.jobUser
gcloud iam service-accounts delete "$SA_MO_METRICS" --project="$MO_PROJECT" --quiet
```

Deleting a service account whose transfer configs still exist leaves those configs failing
silently rather than loudly. Delete the transfer configs from Mo-4 first.

---

## Phase Mo-3 — `gates.yaml`, the two UDFs, and the golden fixtures **NEW**

**Nothing here is deployed; all of it is committed.** The point of doing it at S0 — before
the first item is graded — is that the definitions are fixed and version-controlled before
anyone has an interest in their being different, which is C18's own instruction.

**1. `config/metrics/gates.yaml`.** The complete parameterisation, under
`config/ladder.yaml`'s required reviewers, and — per M29 — in a pull request that **may not
also touch `ladder.yaml`**. The parameters and their sources are
[03-metrics-contract.md](03-metrics-contract.md#2-configmetricsgatesyaml--the-full-parameter-list)
§2, and the gates they drive are [§4](03-metrics-contract.md#4-the-gates); the values committed are `z = 1.959964`, promote
lower bound 0.90, demote upper bound 0.95, L1 upper bound 0.90, graded floor 35, `unsure`
cap 0.10 (`Assumption:`), blind sample rate `max(10 %, 5/week)`, double-grade coverage 0.20,
minimum reporting cell size 5 (`Assumption:`), business-hours calendar Europe/Paris, the
per-source freshness bounds, and `retention_floor_days`, which stays *tbd* until Wall-E's
[decision 17](../wall-e/09-open-decisions.md) ([M-5](08-open-decisions.md)) answers it —
every window is clamped to it at query time, so a later, shorter answer needs no rebuild.

**2. The Wilson bounds, as persistent UDFs** in `${MO_PROJECT}.walle_metrics`, so that the
scheduled queries and the assertion queries execute the same text. The validator cannot use
these routines, so every committed evidence SQL also declares them as `CREATE TEMP FUNCTION`
from the same committed text, and CI asserts the two are byte-identical
([03-metrics-contract.md](03-metrics-contract.md#3-the-two-interval-functions) §3).

```bash
bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --location="$BQ_LOCATION" <<'SQL'
CREATE OR REPLACE FUNCTION `walle_metrics.wilson_lower`(k INT64, n INT64)
RETURNS FLOAT64 AS (
  IF(n = 0 OR k < 0 OR k > n, NULL,
    ( (k/n) + (1.959964*1.959964)/(2*n)
      - 1.959964 * SQRT( ((k/n)*(1-(k/n)))/n + (1.959964*1.959964)/(4*n*n) )
    ) / (1 + (1.959964*1.959964)/n)
  )
);

CREATE OR REPLACE FUNCTION `walle_metrics.wilson_upper`(k INT64, n INT64)
RETURNS FLOAT64 AS (
  IF(n = 0 OR k < 0 OR k > n, NULL,
    ( (k/n) + (1.959964*1.959964)/(2*n)
      + 1.959964 * SQRT( ((k/n)*(1-(k/n)))/n + (1.959964*1.959964)/(4*n*n) )
    ) / (1 + (1.959964*1.959964)/n)
  )
);
SQL
```

The Newcombe difference interval for attribution is built from these two, per
[03-metrics-contract.md](03-metrics-contract.md). `z` appears as a literal here and as a
parameter in `gates.yaml`; CI asserts the two agree, because a UDF that silently disagrees
with the declared parameter is exactly the failure the fixtures below exist to catch. Change
13 lists `config/metrics/gates.yaml` as a group separate from `config/metrics/*.sql`, so the
pull request that changed both to keep them agreeing is refused.

`IF(n = 0 OR k < 0 OR k > n, NULL, …)` is the domain guard ([03-metrics-contract.md](03-metrics-contract.md#31-wilson-score-interval) §3.1).

**3. The golden fixtures.** Expected values are the constants
[14-hld-challenge.md](../wall-e/14-hld-challenge.md) C18 published, and **CI fails if any
differs**. Commit them at their **own path**, `config/metrics/fixtures/wilson.sql`, with a
comment against each constant citing C18 as its source, and add `config/metrics/fixtures/**`
to change 13's mutually-exclusive list as a group distinct from `config/metrics/*.sql`
([04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §3.4). Why the oracle travels
alone, and what each fixture decides, is
[03-metrics-contract.md](03-metrics-contract.md#5-golden-fixtures--the-design-document-is-the-test-oracle) §5.

```bash
bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --location="$BQ_LOCATION" <<'SQL'
WITH fixtures AS (
  SELECT 'lower' bound, 30 k, 30 n, 0.8865 expected UNION ALL
  SELECT 'lower', 35, 35, 0.9011 UNION ALL
  SELECT 'lower', 39, 40, 0.8712 UNION ALL
  SELECT 'lower', 52, 53, 0.9006 UNION ALL
  SELECT 'upper', 18, 20, 0.9721 UNION ALL
  SELECT 'upper', 17, 20, 0.9476 UNION ALL
  SELECT 'upper', 16, 20, 0.9193 UNION ALL
  SELECT 'upper', 15, 20, 0.8881 UNION ALL
  SELECT 'lower', 35, 38, 0.7921    -- conservative: 35 accepts with 3 unsure
)
SELECT bound, k, n, expected,
       ROUND(IF(bound='lower', `walle_metrics.wilson_lower`(k,n),
                               `walle_metrics.wilson_upper`(k,n)), 4) AS actual,
       IF(ROUND(IF(bound='lower', `walle_metrics.wilson_lower`(k,n),
                                  `walle_metrics.wilson_upper`(k,n)), 4) = expected,
          'PASS', 'FAIL') AS result
FROM fixtures ORDER BY bound, n, k;
SQL
```

**Verify.** Nine rows, nine `PASS`. Then run the verdict fixtures of
[03-metrics-contract.md](03-metrics-contract.md#5-golden-fixtures--the-design-document-is-the-test-oracle)
§5 — 34/34, 35/35, the closed block and its retirement, 35 accepts with 3 `unsure`, and the
cap boundary — which are criterion 4 of the acceptance test in [05-staging.md](05-staging.md).
A build in which 34/34 reports `ready`, or which demotes twice on one cluster of three errors,
fails here.

**Rollback.**

```bash
bq rm -f --routine "${MO_PROJECT}:walle_metrics.wilson_lower"
bq rm -f --routine "${MO_PROJECT}:walle_metrics.wilson_upper"
```

Revert the `gates.yaml` pull request. Nothing depends on either until Mo-4.

---

## Phase Mo-4 — The metric queries: ~12 scheduled queries, pinned, and off the hour **NEW**

This is **T0**, and it is "Eve v0" in the sense [05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md)
section 8 forbids skipping. There is no later handover, because there is no later
replacement: T0 is what computes every number and every selection for the life of the
system.

**Why a scheduled query and not a service.** A scheduled query calls no model, has no
network egress and cannot be prompted. It touches no Firestore, no Workspace, no action
service, no Secret Manager and no git. The identity that reads raw per-person audit rows is
therefore structurally incapable of talking to anything — which is the IAM seam the whole
design rests on, rather than a coding convention.

**Why :07 and not :00.** Google documents that "scheduled queries running exactly on the
hour (for example, 09:00) might trigger multiple times, which can cause unintended results
like data duplication from INSERT operations"
([Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries),
verified 2026-09-12). Every metric write is additionally a `MERGE` keyed on
`(as_of_hour, cell, fingerprint_sha)`, so a double fire is a no-op. Belt and braces, because
the belt is one line of schedule text.

Commit each query as `config/metrics/<name>.sql` under `ladder.yaml`'s reviewers, then
create one transfer config per file:

```bash
create_metric () {   # create_metric <name> <sql-file>
  bq mk --transfer_config \
    --project_id="$MO_PROJECT" \
    --location="$BQ_LOCATION" \
    --data_source=scheduled_query \
    --display_name="mo-metric-$1" \
    --service_account_name="$SA_MO_METRICS" \
    --schedule="every 60 mins from 00:07 to 23:07" \
    --params="$(python3 -c 'import json,sys;print(json.dumps({"query": open(sys.argv[1]).read()}))' "$2")"
}

create_metric precision-cell        config/metrics/precision_cell.sql
create_metric verification-cell     config/metrics/verification_cell.sql
create_metric reliability-playbook  config/metrics/reliability_playbook.sql
create_metric invalid-params-cell   config/metrics/invalid_params_cell.sql
create_metric invariant-denials     config/metrics/invariant_denials.sql
create_metric breaker-trips         config/metrics/breaker_trips.sql
create_metric audit-completeness    config/metrics/audit_completeness.sql
create_metric drill-freshness       config/metrics/drill_freshness.sql
create_metric approval-latency      config/metrics/approval_latency.sql
create_metric eve-latency           config/metrics/eve_latency.sql
create_metric sample-coverage       config/metrics/sample_coverage.sql
create_metric capability-gap        config/metrics/capability_gap.sql
create_metric cost-attribution      config/metrics/cost_attribution.sql
create_metric toil-baseline-load    config/metrics/toil_baseline_load.sql
create_metric scorecard             config/metrics/scorecard.sql

# Metric 9b, from S0 with the rest of Wall-E's pack:
create_metric uncatalogued-admin-events config/metrics/uncatalogued_admin_events.sql
# The Eve quality pack, only once eve_quality exists and MD-15 (a) passes
# (03-metrics-contract.md §7.3; file names are this runbook's):
create_metric eve-quality-pack      config/metrics/eve_quality_pack.sql
create_metric eve-divergence        config/metrics/eve_divergence.sql     # A11
create_metric eve-scorecard         config/metrics/eve_scorecard.sql
```

That is fifteen transfer configs, against the "~12 scheduled queries" the rest of this set
quotes: **twelve are the metric queries** — one per §8 metric plus `sample-coverage` and
`capability-gap` — and the last three are supporting, `cost-attribution`,
`toil-baseline-load` and the `scorecard` `MERGE` over the aggregates. A sixteenth, the daily
snapshot, is created in Mo-5. Where another page says "about twelve", it means the metric
queries.

`every 60 mins from 00:07 to 23:07` is the App Engine cron form the TransferConfig
`schedule` field accepts; the documented minimum duration between scheduled queries is 5
minutes, so hourly is comfortably inside it. The `scorecard` query runs last in the list but
not last in time — it is a `MERGE` over the aggregates, so an aggregate that has not yet
refreshed produces a stale-but-flagged row, never a silently wrong one. Its `verdict` is a
SQL `CASE` over its own columns and nothing else.

**Three rules the query text must obey, and CI must check.**

1. **No free-text column is ever selected.** `params_redacted`, `result_summary` and every
   Google error string are excluded by the query text and again by CI review. This is what
   makes N5 of [06-security-guardrails.md](../wall-e/06-security-guardrails.md) satisfied by
   there being nothing to canonicalise.
2. **Every query prunes to its window.** `actions` is partitioned on `ts` and clustered on
   `operation`; an unpartitioned scan of the whole history, fifteen times an hour, is the
   difference between single-digit euros a month and a bill worth arguing about — and that
   bill is `MO_PROJECT`'s.
3. **Every reference to Wall-E's data is fully qualified** —
   `` `<walle-project-id>.walle_audit.<table>` `` and
   `` `<walle-project-id>.walle_workspace_logs.<table>` `` — and every reference to Eve's
   as `` `<eve-project-id>.eve_quality.<view>` ``. The job's default project is
   `MO_PROJECT`, the destination must be in `MO_PROJECT`, and the source may be in another
   project: "The destination dataset and table for a scheduled query must be in the same
   project as the scheduled query" and "Queries can reference tables from different projects
   and different datasets" ([Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries),
   verified 2026-09-13). A bare `walle_audit.actions` resolves in `MO_PROJECT`, does not exist
   there, and fails. CI checks the qualification; `Assumption:` the project id is templated
   into the committed SQL at commit time from one committed variable, so a rename is one
   edit.

**Verify.**

```bash
bq ls --transfer_config --transfer_location="$BQ_LOCATION" --project_id="$MO_PROJECT" \
  --format=prettyjson | python3 -c \
  "import json,sys;[print(c['displayName'], c['schedule'], c.get('serviceAccountName','USER CREDENTIALS')) for c in json.load(sys.stdin)]"
# expect: every row pinned to mo-metrics@. A row reading USER CREDENTIALS is the
#         audit-independence defect this phase exists to prevent — delete and recreate it.

# every committed query names Wall-E's tables fully qualified (rule 3)
grep -L "${WALLE_PROJECT}\.walle_audit\|${WALLE_PROJECT}\.walle_workspace_logs" config/metrics/*.sql
# expect: only the files that read no Wall-E table (toil_baseline_load.sql, scorecard.sql)

# after the first hour, the watermark exists and the verdicts are honest
bq query --use_legacy_sql=false --project_id="$MO_PROJECT" \
  'SELECT verdict, COUNT(*) n, MAX(as_of) watermark
   FROM `walle_metrics.scorecard` GROUP BY verdict'
# expect at S0: every row insufficient_data. The write budget is 0 and no sample
#         approaches 35. A `ready` row at S0 means the floor is not wired.
```

Read the reason arrays too. At S0 the expected reasons include `sample_below_floor` and
— if [M-4](08-open-decisions.md) is still open — `no_second_grader` on every `WRITE_HIGH`
cell. That second one is the point of reporting from S0: the block is visible for months
before it bites at S2, rather than being discovered at S3.

**Rollback.**

```bash
bq ls --transfer_config --transfer_location="$BQ_LOCATION" --project_id="$MO_PROJECT" \
  --format='value(name)' | grep 'transferConfigs/' | while read -r C; do
  bq rm -f --transfer_config "$C"
done
```

Check what that lists before running it — the same command deletes any other transfer config
in `MO_PROJECT` in that location if any exist. `walle_metrics` rows survive; they are
recomputable, and leaving them makes the gap in the series visible rather than invisible.

---

## Phase Mo-5 — Assertion queries and the daily snapshot **NEW**

**The assertion queries are the control that holds regardless of whether the arithmetic is
right.** They are the answer to the failure the validator structurally cannot catch: the
validator re-runs the same committed SQL and inherits the same defect, so an invariant that
does not depend on the arithmetic is the only thing left. A failure pages and **freezes
promotions**.

```bash
# A5 and A9 read Wall-E's tables cross-project and must name them fully qualified. The
# heredoc stays quoted (backticks would otherwise be command substitution), so the project
# id is templated in with sed; the committed copy carries the same __WALLE_PROJECT__ token
# and CI templates it the same way (rule 3 of Mo-4).
sed "s/__WALLE_PROJECT__/${WALLE_PROJECT}/g" <<'SQL' | bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --location="$BQ_LOCATION"
-- runs after every scheduled query; ASSERT fails the job, which fails the transfer run
ASSERT (SELECT COUNT(*) FROM `walle_metrics.scorecard`
        WHERE n_decided + n_unsure != n_graded) = 0
  AS 'n_decided + n_unsure != n_graded';

ASSERT (SELECT COUNT(*) FROM `walle_metrics.scorecard`
        WHERE precision_ratio < 0 OR precision_ratio > 1) = 0
  AS 'precision outside [0,1]';

ASSERT (SELECT COUNT(*) FROM `walle_metrics.scorecard`
        WHERE verdict = 'ready' AND n_decided < 35) = 0
  AS 'ready with n_decided below the floor of 35';

ASSERT (SELECT COUNT(*) FROM `walle_metrics.scorecard`
        WHERE verdict = 'ready'
          AND (dwell_satisfied = FALSE OR drill_age_days > 30)) = 0
  AS 'ready with dwell unsatisfied or a drill older than 30 days';

ASSERT (SELECT COUNT(*) FROM `walle_metrics.agg_precision_cell` a
        LEFT JOIN `__WALLE_PROJECT__.walle_audit.grades` g USING (run_id, item_index)
        WHERE g.run_id IS NULL) = 0
  AS 'a grade row does not join to an action row';

ASSERT (SELECT COUNT(*) FROM `walle_metrics.agg_precision_cell`
        WHERE accepts_counted > approval_vector_entries) = 0
  AS 'a batch approval contributed more accepts than its per-item vector has entries';

ASSERT (SELECT COUNT(*) FROM `walle_metrics.scorecard`
        WHERE REGEXP_CONTAINS(TO_JSON_STRING(t), r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+')) = 0
  AS 'a published row carries an email-shaped string';

ASSERT (SELECT COUNT(*) FROM `walle_metrics.scorecard`
        WHERE cell_count BETWEEN 1 AND 4) = 0
  AS 'a published group-by cell has a count between 1 and 4';

-- A9: a retired block can never fire a second demotion
ASSERT (SELECT COUNT(*) FROM (
          SELECT family, trigger, decided_block_id
          FROM `__WALLE_PROJECT__.walle_audit.ladder_events`
          WHERE origin = 'breaker' AND to_level < from_level
          GROUP BY family, trigger, decided_block_id
          HAVING COUNT(*) > 1)) = 0
  AS 'a cell carries two demotion rows attributable to the same decided block';
SQL
```

**A10, the source rule, and A11, the differential check**
([03-metrics-contract.md](03-metrics-contract.md) §6, §7.3). A10 is an `ASSERT` and runs after
every Eve-pack query, with the text §7.3 prints, committed as
`config/metrics/assert_eve_source_rule.sql`. A11 is **not** an `ASSERT`: it is the
`eve-divergence` transfer config of Mo-4, a `MERGE` that sets `metric_divergence` on
`walle_metrics.eve_scorecard` wherever Mo's value for one of the ten metrics and a window
differs from `eve.findings` read through `eve_quality`, because a divergence is an Eve finding
rather than a failed run. Neither runs before `eve_quality` exists; until then the Eve scorecard
reads `not_computable`.

A7 and A8 are the suppression rule, and they are enforcement rather than review: no
published row carries an email-shaped string, and no published group-by cell has a count
between 1 and 4 (`Assumption:` minimum cell size 5, pending
[decision 35](../wall-e/09-open-decisions.md)).

**A9 does not run until `ladder_events` exists, and it needs one column beyond the ones dwell
and the ratchet need.** `decided_block_id` on the demotion row is what makes "the same block" a
fact rather than an inference; change 2 in [08-open-decisions.md](08-open-decisions.md) carries
it alongside the rest of that table's columns.
Until the table and the column land, A9 reports `not_computable` beside the dwell column and
**no cell is reported ready** — which is the same restrictive behaviour every other
`ladder_events` dependency already has.

**The daily snapshot.** A promotion should point at a dated, citable object, not at a
mutable table. `CREATE SNAPSHOT TABLE … OPTIONS(expiration_timestamp=…)` (verified
2026-09-12) gives exactly that, at storage cost only:

```bash
bq mk --transfer_config \
  --project_id="$MO_PROJECT" \
  --location="$BQ_LOCATION" \
  --data_source=scheduled_query \
  --display_name="mo-snapshot-scorecard" \
  --service_account_name="$SA_MO_METRICS" \
  --schedule="every day 02:07" \
  --params='{"query": "EXECUTE IMMEDIATE FORMAT(\"CREATE SNAPSHOT TABLE `walle_metrics_archive.scorecard_%s` CLONE `walle_metrics.scorecard` OPTIONS(expiration_timestamp = TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 400 DAY))\", FORMAT_DATE(\"%Y%m%d\", CURRENT_DATE()))"}'
```

The 400-day expiration is `Assumption:` pending [M-5](08-open-decisions.md), and it is set
**at creation** so that an unattended snapshot series cannot outlive the retention answer.

**Verify.**

```bash
# the assertions actually bite: write a deliberately bad row into a scratch copy
# and confirm the ASSERT fails the job rather than warning
bq query --use_legacy_sql=false --project_id="$MO_PROJECT" \
  "SELECT 1 FROM \`walle_metrics.scorecard\` WHERE verdict='ready' AND n_decided < 35"
# expect: zero rows, always

bq ls --format=prettyjson "${MO_PROJECT}:walle_metrics_archive" | python3 -c \
  "import json,sys;[print(t['tableReference']['tableId'], t['type'], t.get('expirationTime')) for t in json.load(sys.stdin)]"
# expect: one scorecard_YYYYMMDD per day, type SNAPSHOT, each with an expirationTime
```

Testing an assertion by reading it is not testing it. Run the negative case in a scratch
dataset — insert a row with `verdict='ready'` and `n_decided = 34`, run the assertion, and
confirm the **job fails**. An assertion that only ever runs against clean data is a comment.

**Rollback.** Delete the snapshot transfer config the way Mo-4's are deleted. Snapshots
already taken expire on their own; delete them early only if the retention answer says to.
Removing the assertion queries is not a rollback, it is a regression — if they must come out
to unblock something, freeze promotions in `gates.yaml` in the same change.

**Stage 0 is now complete for Mo.** A human reads the numbers and signs the S1 decision
record. Nothing automatic consumes them, and **no S0 or S1 exit criterion cites Mo's
verdict**.

---

# Phase "Mo — reporting" (S1)

Executed after Stage 0 exit, against the S1 decision record, against `MO_PROJECT`. It adds
one identity, one view layer, one Cloud Run job and one alert, plus one cross-project
binding that Wall-E's owner makes. It still grants Mo no credential and no write path into
anything that enforces.

---

## Phase Mo-6 — `mo-analyst@`, the authorised views, and the surrogate keys **NEW**

This is the phase that creates the account `MO_PRINCIPAL` resolves to. There is no longer a
Phase 13b grant in [SETUP.md](../wall-e/SETUP.md) waiting for it — see below.

```bash
gcloud iam service-accounts create mo-analyst --project="$MO_PROJECT" \
  --display-name="Mo T1 — reporter. Reads computed aggregates only."

gcloud projects add-iam-policy-binding "$MO_PROJECT" \
  --member="serviceAccount:${SA_MO_ANALYST}" --role=roles/bigquery.jobUser

# the two read grants, and they are the ONLY two. Never on walle_audit.
grant_dataset "$MO_PROJECT" walle_metrics         READER "$SA_MO_ANALYST"
grant_dataset "$MO_PROJECT" walle_metrics_archive READER "$SA_MO_ANALYST"

# ---- Wall-E's owner's step, in WALLE_PROJECT, from Wall-E's runbook -----------
# SETUP Phase 10's run.invoker loop gains mo-analyst@${MO_PROJECT}; the in-app read-endpoint
# allowlist gains the same full email. Cross-project, service-level. Shown for the build
# order; Mo's builder does not run it.
# (gcloud run services add-iam-policy-binding SERVICE --member=PRINCIPAL --role=ROLE:
#  https://docs.cloud.google.com/run/docs/securing/managing-access, verified 2026-09-13)
gcloud run services add-iam-policy-binding walle-actions \
  --region="$REGION" --project="$WALLE_PROJECT" \
  --member="serviceAccount:${SA_MO_ANALYST}" --role=roles/run.invoker

# There is deliberately NO roles/agentregistry.viewer binding here. Phase 13b's was a
# project-level role on WALLE_PROJECT for a MO_PROJECT principal, which the topology
# forbids, and the registry has no resource-level IAM to narrow it to (topology decision 43).
```

`roles/agentregistry.viewer` is **dropped**, reversing on 2026-09-13 the 2026-09-12 outcome
that kept it granted-and-unused (topology decision 43;
[02-identity-and-access.md](02-identity-and-access.md#6-mo_principal-resolved) §6): it binds at
project level on `WALLE_PROJECT` for a `MO_PROJECT` principal, and comes back only if a
resource-level binding is verified — [M-11](08-open-decisions.md) (a), not verified as of
2026-09-13.

`roles/run.invoker` on `walle-actions` allows the HTTP call; it does **not** allow the path.
`GET /v1/plans/{id}` and `GET /v1/runs/{id}` are the only two endpoints Mo may reach, and
they are the only thing BigQuery cannot tell Mo. `/v1/ladder`, `/v1/control/*`, `/approve`
and `/veto` are refused by the in-app allowlist — that is denial tests **MD-3** and **MD-4**,
and it is the same mechanism that refuses `walle-agent@` in
[SETUP.md](../wall-e/SETUP.md) §4 test 4. The binding is cross-project, and the in-app
allowlist row must read `mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com`: an allowlist
still carrying an old `@${PROJECT}` address 403s every legitimate call, and MD-3 then passes
for the wrong reason — which is why MD-3 is paired with a positive `GET /v1/runs/{id}`.

**The authorised-view layer.** This is what makes the model's blindness an IAM fact rather
than a sanitisation step. Principals granted on an authorised view "can view the data you
share and run queries on it, but they can't access the source dataset directly" (verified
2026-09-12).

The view goes in `walle_metrics_views`, **not** beside its source table: an authorized view
"must be a different dataset than the dataset used in the source query"
([Authorized views](https://docs.cloud.google.com/bigquery/docs/authorized-views), verified
2026-09-12), so a view defined in `walle_metrics` over `walle_metrics.scorecard` is not an
authorized view and the whole boundary is decoration.

```bash
# one view per agent-facing surface, in the VIEW dataset. Ids, hashes, closed enums, counts,
# timestamps and surrogate keys ONLY: no params_redacted, no result_summary, no content_flags
# free text, no display name, no group name, no Google error string, no principal email.
bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --location="$BQ_LOCATION" <<'SQL'
CREATE OR REPLACE VIEW `walle_metrics_views.v_cell_public` AS
SELECT as_of, as_of_hour, family, trigger, fingerprint_sha,
       current_level, target_level, verdict, reasons,
       n_decided, n_unsure, unsure_rate,
       wilson_lower, wilson_upper, wilson_lower_conservative,
       window_length_days, weeks_to_promotable,
       sample_coverage_achieved, sample_coverage_required,
       double_grade_coverage, raw_agreement, gwet_ac1,
       error_budget_state, freeze_state, ceiling, dwell_elapsed, dwell_required
FROM `walle_metrics.scorecard`;
SQL

# register each view on the SOURCE dataset's access list. Intra-project: source and view
# are both in MO_PROJECT. The view.projectId field is what would make this cross-project
# (the access entry is PROJECT_ID.DATASET_ID.VIEW_NAME —
# https://docs.cloud.google.com/bigquery/docs/authorized-views, verified 2026-09-13), and
# it is always MO_PROJECT here.
authorise_view () {   # authorise_view <source-dataset> <view-dataset> <view-name>
  bq show --format=prettyjson "${MO_PROJECT}:$1" > /tmp/src.json
  V_DS="$2" V_TB="$3" P="$MO_PROJECT" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/src.json'))
d.setdefault('access', []).append({"view": {
    "projectId": os.environ['P'],
    "datasetId": os.environ['V_DS'],
    "tableId":   os.environ['V_TB']}})
json.dump(d, open('/tmp/src.json', 'w'))
EOF
  bq update --source=/tmp/src.json "${MO_PROJECT}:$1"
}

# register the view on the dataset it READS FROM — walle_metrics, not walle_audit
authorise_view walle_metrics walle_metrics_views v_cell_public
```

**There is deliberately no `authorise_view walle_audit …` line here, and its absence is a
control rather than an omission.** A view executes with **its own** authorization, not the
caller's, and `mo-metrics@` holds `WRITER` on `walle_metrics` and can therefore
`CREATE OR REPLACE` this view. A view carrying an authorization on `walle_audit` could be
redefined to select `walle_audit.actions.params_redacted` and would then hand raw free text to
whichever principal may read it — a standing escalation path into the one dataset the
three-tier split exists to fence off, built by a line that serves no purpose. The view reads
`walle_metrics.scorecard`; it is registered on `walle_metrics`; it holds nothing on
`walle_audit` at any stage. That line would also be a cross-project entry —
a `view` with `projectId = MO_PROJECT` in `WALLE_PROJECT`'s dataset access array — which is
one more reason it is never written, and the verify block below reads Wall-E's dataset to
prove it ([`../project-topology.md`](../project-topology.md) §3 row 9).

**The surrogate keys.** `walle_metrics_private.principal_surrogates` holds a monotone integer
per distinct principal, populated by a `MERGE` inside T0 — never by T1, which cannot read the
raw rows it would need, and which cannot read the mapping either: `mo-analyst@`'s `READER` is
dataset-level on `walle_metrics`, and the mapping is not in that dataset. The agent-facing
views carry `principal_surrogate INT64` and never `principal`. This preserves "the same subject recurs", which is a real signal, while
destroying identity, which is strictly better than omitting the column and losing the
signal with it.

**Verify.** The negatives are the point of this phase.

```bash
TOKEN="$(gcloud auth print-access-token --impersonate-service-account="$SA_MO_ANALYST")"

# Jobs are submitted to MO_PROJECT — the principal's home, where its jobUser is. Wall-E's
# table is named fully qualified: a bare `walle_audit.actions` would resolve in MO_PROJECT,
# fail as not-found, and prove nothing about access.

# mo-analyst@ must NOT be able to read walle_audit, cross-project
curl -s -X POST -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' \
  "https://bigquery.googleapis.com/bigquery/v2/projects/${MO_PROJECT}/queries" \
  -d "{\"query\":\"SELECT COUNT(*) FROM \`${WALLE_PROJECT}.walle_audit.actions\`\",\"useLegacySql\":false}"
# expect: 403 accessDenied (not 404 notFound). This is denial test MD-2.

# it CAN read the computed aggregates
curl -s -X POST -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' \
  "https://bigquery.googleapis.com/bigquery/v2/projects/${MO_PROJECT}/queries" \
  -d '{"query":"SELECT COUNT(*) FROM `walle_metrics.scorecard`","useLegacySql":false}'
# expect: a row count

# it must NOT be able to read the surrogate mapping
curl -s -X POST -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' \
  "https://bigquery.googleapis.com/bigquery/v2/projects/${MO_PROJECT}/queries" \
  -d '{"query":"SELECT COUNT(*) FROM `walle_metrics_private.principal_surrogates`","useLegacySql":false}'
# expect: 403 accessDenied. This is half of denial test MD-13, and it is the whole of the
#         claim that a surrogate cannot be joined back to an email.

# no free-text column survives into a view
bq query --use_legacy_sql=false --project_id="$MO_PROJECT" \
  "SELECT column_name FROM \`walle_metrics_views.INFORMATION_SCHEMA.COLUMNS\`
   WHERE table_name LIKE 'v_%'
     AND column_name IN ('params_redacted','result_summary','content_flags',
                         'principal','primary_email','group_key','error_message')"
# expect: zero rows

# the view dataset holds views and nothing else, and walle_audit's access array — in
# WALLE_PROJECT — carries NO view entry whose projectId is MO_PROJECT
bq show --format=prettyjson "${WALLE_PROJECT}:walle_audit" | MO="$MO_PROJECT" python3 -c \
  "import json,sys,os;[print(a) for a in json.load(sys.stdin)['access'] if 'view' in a and a['view'].get('projectId')==os.environ['MO']]"
# expect: nothing. Any entry here is a cross-project authorised view on the raw evidence,
#         and an escalation path (../project-topology.md section 3 row 9)
```

**Rollback.** Remove the `view` entry from `walle_metrics`'s access array, drop the views,
remove the in-project bindings, ask Wall-E's owner to remove the `run.invoker` binding and
the allowlist email in `WALLE_PROJECT`, and
`gcloud iam service-accounts delete "$SA_MO_ANALYST" --project="$MO_PROJECT"`. Note that
removing the account leaves `MO_PRINCIPAL` naming an account that no longer exists.

---

## Phase Mo-7 — `mo-reporter`, its schedule, and the absence alert **NEW**

**A job, not a service.** Mo's workload is batch-shaped. A Cloud Run service caps one
request at 60 minutes; a job task runs to 168 hours (verified 2026-09-12). Nothing in Mo is
request-shaped, and pretending otherwise would inherit a ceiling for no gain.

```bash
gcloud run jobs create mo-reporter \
  --project="$MO_PROJECT" \
  --image="${MO_AR}/mo-reporter@sha256:<digest>" \
  --region="$REGION" \
  --service-account="$SA_MO_ANALYST" \
  --task-timeout=3600s \
  --max-retries=1 \
  --tasks=1 \
  --set-env-vars="MO_PROJECT=${MO_PROJECT},WALLE_PROJECT=${WALLE_PROJECT},BQ_LOCATION=${BQ_LOCATION},ACTIONS_URL=${ACTIONS_URL},GATES_PATH=config/metrics/gates.yaml"
```

The reporter's BigQuery jobs run in `MO_PROJECT` (its `jobUser` is there); `WALLE_PROJECT`
is passed only so it can spell fully qualified names; `ACTIONS_URL` is the `walle-actions`
service in `WALLE_PROJECT`. `MO_AR` is the Artifact Registry repository created in Mo-1
step 0, in `MO_PROJECT`; the CI that pushes images there needs
`roles/artifactregistry.writer` on that repository — a cross-project grant into `MO_PROJECT`
whose identity is *tbd* with the git host ([M-7](08-open-decisions.md)).

**By digest, never by a mutable tag.** A tag can be moved after review; a digest cannot. The
same rule applies to the validator image in Mo-9 and to the narrator in Mo-11.

Scheduling. The target is `run.googleapis.com`, which is a `*.googleapis.com` host, so it
takes an **OAuth** token and not OIDC — "OIDC is generally used *except* for Google APIs
hosted on `*.googleapis.com` as these APIs expect an OAuth token" (verified 2026-09-12).

```bash
# the invoking identity needs run.invoker ON THE JOB, which is a different resource
# from the walle-actions service. Assumption: mo-analyst@ invokes itself. The binding is
# carried in 02-identity-and-access.md section 2.2 as its own row.
gcloud run jobs add-iam-policy-binding mo-reporter --region="$REGION" --project="$MO_PROJECT" \
  --member="serviceAccount:${SA_MO_ANALYST}" --role=roles/run.invoker

gcloud scheduler jobs create http mo-reporter-weekly \
  --project="$MO_PROJECT" \
  --location="$REGION" \
  --schedule="0 6 * * 1" \
  --time-zone="Europe/Paris" \
  --uri="https://run.googleapis.com/v2/projects/${MO_PROJECT}/locations/${REGION}/jobs/mo-reporter:run" \
  --http-method=POST \
  --oauth-service-account-email="$SA_MO_ANALYST" \
  --attempt-deadline=180s \
  --max-retry-attempts=2
```

Monday 06:00 Europe/Paris, so the digest is in `walle-operators@`'s inbox by 08:00. The
Cloud Scheduler **service agent** must additionally hold `roles/cloudscheduler.serviceAgent`
to mint the token — without it "authentication will fail regardless of your service account
permissions". That agent is **`MO_PROJECT`'s**,
`service-${MO_PROJECT_NUMBER}@gcp-sa-cloudscheduler.iam.gserviceaccount.com` — the first
use of `MO_PROJECT_NUMBER` in this set, and never Wall-E's number. And Scheduler is at-least-once: "only a single instance of a job should be run
at any time", but in rare cases multiple may, so the handler must be idempotent. `mo-reporter`
is idempotent on job name plus the `X-CloudScheduler-ScheduleTime` header, which "contains
the original scheduled invocation time and remains constant across retry attempts".

**The freshness absence alert.** Mo's absence must be strictly more restrictive than its
presence, and the detection of that absence cannot depend on Mo publishing a liveness
signal. A threshold-only policy is silent exactly when the metric stops being written.

The policy, the custom metric and the notification channel all live in `MO_PROJECT`. The
metric `custom.googleapis.com/mo/metrics_watermark_age_hours` is written to `MO_PROJECT` by
the `scorecard` transfer's companion step (`Assumption:` a one-line write from the
`mo-reporter` job's pre-flight, and from a tiny hourly Cloud Run job if the reporter runs only
weekly — the writer is Mo's, never Wall-E's). Wall-E's on-call channel is subscribed to this
policy; Wall-E's Phase 16 records where the alert is and creates nothing (change 14).

```bash
gcloud beta monitoring channels list --project="$MO_PROJECT" --format='value(name,displayName)'
```

```bash
cat > /tmp/mo-watermark.yaml <<EOF
displayName: "Mo metrics watermark stale or absent"
combiner: OR
conditions:
  - displayName: "walle_metrics watermark older than 24h"
    conditionThreshold:
      filter: 'metric.type="custom.googleapis.com/mo/metrics_watermark_age_hours"'
      comparison: COMPARISON_GT
      thresholdValue: 24
      duration: 1800s
      evaluationMissingData: EVALUATION_MISSING_DATA_ACTIVE
      aggregations:
        - alignmentPeriod: 1800s
          perSeriesAligner: ALIGN_MAX
  - displayName: "watermark metric absent: T0 has stopped"
    conditionAbsent:
      filter: 'metric.type="custom.googleapis.com/mo/metrics_watermark_age_hours"'
      duration: 7200s
notificationChannels:
  - projects/${MO_PROJECT}/notificationChannels/<CHANNEL_ID>   # paste yours, from the list above
EOF

gcloud monitoring policies create --project="$MO_PROJECT" --policy-from-file=/tmp/mo-watermark.yaml
```

The 24-hour number is the same one the validator enforces in Mo-9: a watermark older than 24
hours makes the validator refuse **every** promotion. That is the mirror of Eve failing
closed, and it is why this alert is a control rather than a dashboard.

**Verify.**

```bash
gcloud run jobs execute mo-reporter --region="$REGION" --project="$MO_PROJECT" --wait
gcloud run jobs executions list --job=mo-reporter --region="$REGION" --project="$MO_PROJECT" \
  --format='value(name,status.succeededCount,status.failedCount)'
```

Then the artefacts: `platform/wall-e/mo/scorecard.md`, `cost-YYYY-MM.md` and the S1
stop-or-continue document exist, are aggregate-only, and carry no per-person identifier.

**Break it on purpose, the way it actually breaks.** Pause the four hourly metric transfer
configs and **do not write the watermark metric by any other means**. Confirm the
**absence** condition fires within two hours. Do not test this by pushing the value above
24: that only proves the comparison works, and the comparison is the branch that already
works. Then resume.

```bash
gcloud scheduler jobs resume mo-reporter-weekly --location="$REGION" --project="$MO_PROJECT"
gcloud scheduler jobs run    mo-reporter-weekly --location="$REGION" --project="$MO_PROJECT"
```

**Rollback.**

```bash
gcloud scheduler jobs delete mo-reporter-weekly --location="$REGION" --project="$MO_PROJECT" --quiet
gcloud run jobs delete mo-reporter --region="$REGION" --project="$MO_PROJECT" --quiet
gcloud monitoring policies list --project="$MO_PROJECT" --format='value(name,displayName)'   # then delete by name
```

Deleting the reporter degrades nothing that enforces. The artefacts go stale and say so —
`ladder-state.md` carries the watermark — and no promotion can cite a stale one.

---

## Phase Mo-8 — The artefact paths, the readers, and the grader list

No cloud resource. Four things a human does, and the reason each one is a human's.

1. **Create the artefact directories** in the wiki repository — `platform/wall-e/mo/`,
   `platform/eve/mo/` and one `platform/<agent>/mo/` per high-risk system for
   its Art. 72 plan — and commit an empty `ladder-state.md` with the current matrix. `mo-reporter` regenerates it
   **as a pull request**, never as a push — Mo holds no git credential, at any phase.
2. **Set the reader list.** Until [decision 35](../wall-e/09-open-decisions.md) lands,
   readers are `walle-operators@` and the ladder owner only, and **no Mo artefact is synced
   to Drive** ([M-3](08-open-decisions.md)). This is a manual choice in the wiki's sync
   configuration, and it is the one place where forgetting a step silently widens a reader
   set over personal data.
3. **Commit the grader list** — human principals only, at `config/metrics/graders.yaml`
   under `ladder.yaml`'s reviewers. A grade from a principal not on that list, or from the
   author of the playbook version under test, is **excluded and counted** in
   `grades_excluded`. For a `WRITE_HIGH` cell the second grade must come from someone other
   than the `owner:` recorded in the playbook file.
4. **Record Mo as a processor in the data-protection assessment.** T0 reads per-person rows.
   [ARCHITECTURE](../wall-e/ARCHITECTURE.md) weakness 11's claim that Mo's reads are
   aggregated per organisational unit is **wrong**, and correcting it is change 11 of
   [08-open-decisions.md](08-open-decisions.md). Do not inherit the false version into the
   assessment.

**Verify.** The wiki sync excludes `platform/wall-e/mo/**` and
`platform/eve/mo/**`; the grader list is committed and
contains at least one human who is not the playbook owner; the assessment names Mo.

**Rollback.** Revert the commits. Step 2 has no rollback worth the name — a reader set that
was widened and then narrowed is still a reader set that was widened.

---

# After Stage 1

Not SETUP phases. [SETUP.md](../wall-e/SETUP.md) ends at Stage 0 entry; everything below
happens against a dated stage decision record.

---

## Phase Mo-9 — The drop box, CI ingestion, and the validator's recompute check (S2 exit)

**This phase is the precondition for the first promotion that cites Mo**, not an improvement
to add later. Until the validator recomputes, nothing Mo says may be load-bearing, and the
licence that lets a model anywhere near Mo is void.

Roughly three of this phase's days belong to the **validator custodian**, not to Mo's
budget. The validator is owned outside the config repository per
[05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §10 — the gate cannot be part of
what it gates — and it is deployed by image digest.

**1. The drop box.** One bucket, so that Mo holds no git credential: Mo drops a bundle and CI,
under a bot identity that is **not** Mo, turns it into a pull request
([04-artefacts-and-proposals.md](04-artefacts-and-proposals.md#3-from-bundle-to-merge) §3).

```bash
gcloud storage buckets create "$MO_PROPOSALS" \
  --project="$MO_PROJECT" \
  --location="$BQ_LOCATION" \
  --uniform-bucket-level-access \
  --public-access-prevention

# --versioning is not a create-time flag; it is set on update
gcloud storage buckets update "$MO_PROPOSALS" --versioning

cat > /tmp/mo-lifecycle.json <<'EOF'
{"rule":[{"action":{"type":"Delete"},"condition":{"age":90,"isLive":false}},
         {"action":{"type":"Delete"},"condition":{"age":90,"isLive":true}}]}
EOF
gcloud storage buckets update "$MO_PROPOSALS" --lifecycle-file=/tmp/mo-lifecycle.json

# objectCreator, and deliberately nothing more: "Allows users to create objects. Does not
# give permission to view, delete, or overwrite objects." (verified 2026-09-12)
gcloud storage buckets add-iam-policy-binding "$MO_PROPOSALS" \
  --member="serviceAccount:${SA_MO_ANALYST}" --role=roles/storage.objectCreator

# Bundle writes must be attributable, and the bucket is in MO_PROJECT, so MO_PROJECT
# enables Cloud Storage Data Access audit logs itself — nothing is inherited from Wall-E's
# project. 06-failure-modes.md relies on this row.
cat > /tmp/mo-audit-policy.yaml <<'EOF'
auditConfigs:
- service: storage.googleapis.com
  auditLogConfigs:
  - logType: DATA_WRITE
  - logType: DATA_READ
EOF
# Merge the auditConfigs block into MO_PROJECT's IAM policy: `gcloud projects get-iam-policy`,
# add the block, `gcloud projects set-iam-policy` — never overwrite the bindings.
# Assumption: DATA_READ is included so the CI bot's reads are attributable as well.

# The CI ingestion identity reads the bucket from OUTSIDE MO_PROJECT — a cross-project
# grant into Mo's project. Assumption: roles/storage.objectViewer, bucket-level; the identity
# and its home are tbd with the git host (M-7), through a Workload Identity Federation pool in
# MO_PROJECT if the host federates (topology decision 50, M-11 (c)).
gcloud storage buckets add-iam-policy-binding "$MO_PROPOSALS" \
  --member="<ci-ingestion-principal>" --role=roles/storage.objectViewer
```

Why `objectCreator` and nothing more, and why the ingestion identity's reader binding is the
only other principal on the bucket, is [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md)
§3.1 and §3.3.

**2. CI ingestion, and the path allowlist.** Configure ingestion with this allowlist; a bundle
whose diff touches anything outside it is rejected **at ingestion, before CI**, and never
becomes a pull request:

```
config/ladder.yaml
config/playbooks/**
config/prompts/**
config/catalogue/**
platform/wall-e/mo/**
platform/wall-e/ladder-state.md
platform/eve/mo/**
platform/<agent>/mo/art72-plan.md

# eve/config — Eve proposal types only (04 §3.2, §3.5)
eve/config/thresholds.yaml
eve/config/seeded_faults/**
```

The paths ingestion must refuse in every bundle, the ingestion checks (closed schema,
published `scorecard_sha256` and `snapshot_name`, the anchored seed, the closed proposal type
sets of [§3.5](04-artefacts-and-proposals.md#35-the-closed-proposal-type-set)) and the stripping
of `narrative` are specified in [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md#32-the-path-allowlist)
§3.2–§3.3; ingestion also refuses an Eve type other than `eve_incident_note` while the
custodian's `READER` on `eve_quality` (P30, made by Eve's runbook) does not exist.

**3. The validator's recompute check**, a required check on the config repository, owned by
the custodian, deployed by digest. Implement every gate of
[04-artefacts-and-proposals.md](04-artefacts-and-proposals.md#34-what-the-validator-enforces)
§3.4, which is the authoritative list with each gate's source and refusal. The validator
**holds no binding of any kind in `MO_PROJECT`** — denial tests **MD-9** and **MD-9b**.

The validator's identity holds a dataset-level `READER` entry on
`${WALLE_PROJECT}:walle_audit`, made by Wall-E's owner the same way Mo-2's were, and
`roles/bigquery.jobUser` in the **custodian's own project** (*tbd*, decision 37) — never
project-wide in `WALLE_PROJECT`, never anything in `MO_PROJECT`. It appears nowhere in
`MO_PROJECT`'s IAM policy or dataset access lists
([`../project-topology.md`](../project-topology.md) §3 row 21).

The **CI ingestion identity** additionally holds `Assumption:` `roles/bigquery.metadataViewer`
at dataset level on `${MO_PROJECT}:walle_metrics_archive` and on the published-hash register,
for the snapshot and hash checks, and the validator takes the watermark from the cited
snapshot's own date — the provisional route of
[04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §3.3, §3.4, *tbd* until the
identity is named ([M-11](08-open-decisions.md) (c)).

**4. Branch protection.** Two distinct authenticated reviewers, neither the author, and
**admin bypass disabled and audited** ([M-7](08-open-decisions.md)). The validator reports
the setting it observes and cannot enforce it; a repository where an administrator can
bypass protection turns the two-reviewer rule into decoration.

**Verify.** Denial tests **MD-5**, **MD-6**, **MD-7** and **MD-9** below, plus one end-to-end
dry run: assemble a bundle by hand for a cell the scorecard reports `not_ready`, drop it,
and confirm CI opens a pull request whose validator check **fails** with the reason named.
A validator that has only ever passed has not been tested.

**Rollback.**

```bash
gcloud storage buckets delete "$MO_PROPOSALS" --project="$MO_PROJECT"   # only after the bucket is empty
```

Remove the required check and the ingestion workflow. Rolling this back returns the
programme to arguing promotions from hand-run queries, which is where S0 started and is a
working fallback — see the acceptance test's stated fallback in
[05-staging.md](05-staging.md).

---

## Phase Mo-10 — The linked Spans dataset (S3)

Staged to S3 because M38 binds `strong` and names Mo specifically. **The link is created
once, by a human holding `roles/observability.editor`, and never by Mo.** Mo holds that role
at no stage. `Assumption:` the traces are Wall-E's engine's, so the `_Trace` bucket and the
link are in **`WALLE_PROJECT`**, the human holds the role **there**, and this whole phase is
Wall-E's owner's keystrokes apart from the verify query.

`gcloud` 563.0.0 or later is required.

```bash
# ---- Wall-E's owner's step, in WALLE_PROJECT ---------------------------------
gcloud beta observability buckets datasets links create \
  "projects/${WALLE_PROJECT}/locations/${REGION}/buckets/_Trace/datasets/Spans/links/walle_spans" \
  --dataset=Spans \
  --bucket=_Trace \
  --location="$REGION" \
  --project="$WALLE_PROJECT"

# then the cross-project, dataset-level READER for mo-metrics@${MO_PROJECT} on the linked
# dataset — same shape as Mo-2's two READERs, same owner. SPIKE: it is unverified that a
# linked observability dataset's access array accepts a foreign dataset-level entry
# (M-11 (b), topology decision 49). If bq update refuses it, stop: Mo forgoes the three
# cost and latency metrics, and a Wall-E-side copy job into MO_PROJECT is refused because it
# would give a Wall-E identity a write into Mo's project.
grant_dataset "$WALLE_PROJECT" walle_spans READER "$SA_MO_METRICS"
```

This initiates a long-running operation, and audit logs record both the request and the
completion. `mo-metrics@` then needs `roles/bigquery.dataViewer` on the resulting linked
dataset to join `_AllSpans` on `invocation_id` and, through `runs`, on `trace_id`. That
grant is carried in [02-identity-and-access.md](02-identity-and-access.md) §2.1 as an S3-only
row, because it widens `mo-metrics@`'s read surface by one dataset of trace data and should
not be read as part of the S0 grant set.

**Cloud Trace sinks to BigQuery are deprecated since 2026-02-18** and are deliberately not
designed around. The linked dataset is the supported route.

**Verify.** The query runs as a job in `MO_PROJECT` against Wall-E's linked dataset, fully
qualified:

```bash
bq ls --format=prettyjson "${WALLE_PROJECT}:walle_spans" | head
bq query --use_legacy_sql=false --project_id="$MO_PROJECT" \
  "SELECT COUNT(*) FROM \`${WALLE_PROJECT}.walle_spans._AllSpans\` WHERE start_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)"
```

**Rollback.** Remove the `READER` entry, then delete the link (both in `WALLE_PROJECT`).
Token spend, tool-call counts and per-invocation latency become uncomputable; nothing else
changes, and no cell's verdict depends on them.

---

## Phase Mo-11 — `mo-narrator@` (S4, optional)

**It is legitimate never to execute this phase.** Cutting T2 entirely is a defensible
reading of this design — denying the narrator every free-text string is what makes it safe
and also makes its prose thin. Decide on the S4 entry record ([M-8](08-open-decisions.md)).

Deliberately **not** a reasoning engine: an Agent Runtime engine would buy an immutable
`identity_type=AGENT_IDENTITY` and a `discoveryengine.serviceAgent` blast-radius problem
(M52) that a Cloud Run job calling `generateContent` does not have.

```bash
# the one API MO_PROJECT enables late, and only for this phase. Never in EVE_PROJECT.
gcloud services enable aiplatform.googleapis.com --project="$MO_PROJECT"

gcloud iam service-accounts create mo-narrator --project="$MO_PROJECT" \
  --display-name="Mo T2 — prose only. Computes nothing, selects nothing, grades nothing."

# aiplatform.user in MO_PROJECT, where the job runs; nothing in WALLE_PROJECT, and no
# engine anywhere. The folder's Model Armor floor applies to these calls.
gcloud projects add-iam-policy-binding "$MO_PROJECT" \
  --member="serviceAccount:${SA_MO_NARRATOR}" --role=roles/aiplatform.user

# dataViewer on the AGENT-FACING VIEW DATASET. Never on walle_metrics, never on
# walle_metrics_archive, never on walle_metrics_private, never on walle_audit.
# The grant is on the DATASET that contains the authorized view, which is what Google
# requires of the querying principal: a table-level binding on the view alone leaves the
# query failing on the underlying table.
grant_dataset "$MO_PROJECT" walle_metrics_views READER "$SA_MO_NARRATOR"

gcloud run jobs create mo-narrator \
  --project="$MO_PROJECT" \
  --image="${MO_AR}/mo-narrator@sha256:<digest>" \
  --region="$REGION" \
  --service-account="$SA_MO_NARRATOR" \
  --task-timeout=900s \
  --max-retries=1 \
  --set-env-vars="MO_PROJECT=${MO_PROJECT},REGION=${REGION},MODEL_ID=<pinned-model-id>"
```

The pinned model must be available in `europe-west1` from `MO_PROJECT` — check the model's
regional availability before pinning it, because a model available to Wall-E's project is
not thereby available to Mo's.

The pinned model id lives in `gates.yaml`'s sibling deploy config. **Swapping it is the
whole of the model-family comparison** [08-team-eve-mo.md](../wall-e/08-team-eve-mo.md)
invites, and changing it is a configuration change with no safety review — which is exactly
the claim being tested.

**CI lints the package, and these are build failures, not warnings:**

- no import of `skill_registry`, `SkillToolset`, `McpToolset` or `RemoteA2aAgent`;
- `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS` absent or false;
- no fault-injection or test-mode path reachable in an admitted image;
- deploy by digest, never a mutable tag;
- an import test banning `google.genai`, `vertexai` and `google.adk` from **T0's and T1's**
  packages specifically. T2 may import them; T0 and T1 may not, and that asymmetry is the
  deterministic boundary expressed as a lint.

**Verify.** Denial test **MD-1**, which is paired and must fail in both directions: the
narrator's `SELECT` on `walle_metrics_views.v_cell_public` must **succeed**, and its selects
on `walle_metrics.scorecard`, on `walle_metrics_private.principal_surrogates` and on
`walle_audit.actions` must each be refused. A negative-only test passes identically whether
the boundary works or is dead. Then confirm the output contract: the narrator's block is
closed-schema, any `mo_schema_violation` is counted, and **any occurrence disables the
renderer until a human reviews it**. A malformed or steered output must be loud, not
silently dropped.

**Rollback.**

```bash
gcloud run jobs delete mo-narrator --region="$REGION" --project="$MO_PROJECT" --quiet
gcloud iam service-accounts delete "$SA_MO_NARRATOR" --project="$MO_PROJECT" --quiet
gcloud services disable aiplatform.googleapis.com --project="$MO_PROJECT"
```

Every artefact still renders; the prose paragraphs are absent. Nothing that gates changes,
because nothing T2 writes ever entered an evidence block.

---

## Phase Mo-12 — The denial tests, authored from Mo's side

**This is the gate, not a one-off.** It runs at the end of every sitting above and again
before every promotion, forever. It appends to
[SETUP.md](../wall-e/SETUP.md) §4's suite; numbered `MD-n` here to avoid colliding with that
suite's own 1 to 52, with the phase numbers above, and with
[08-open-decisions.md](08-open-decisions.md)'s `M-n` decision index.

| # | Test | Expected result |
|---|---|---|
| MD-1 | **Paired, and it must be able to fail in both directions.** (a) `mo-narrator@` selects from `walle_metrics_views.v_cell_public`. (b) It selects `params_redacted`, `result_summary` and `principal_id` from `` `${WALLE_PROJECT}.walle_audit.actions` `` (cross-project, fully qualified), `walle_metrics.scorecard` — the whole table, not the view — and `walle_metrics_private.principal_surrogates`; every job submitted in `MO_PROJECT` | **(a) succeeds**, returning rows; **(b) 403 accessDenied**, every time — not 404. A negative-only test passes identically whether the authorised-view boundary works or does not exist |
| MD-2 | `mo-analyst@` reads `walle_audit`, cross-project: `` SELECT COUNT(*) FROM `${WALLE_PROJECT}.walle_audit.actions` `` from a job in `MO_PROJECT` | **403 accessDenied.** T1 cannot see the raw evidence it would need to forge a number. A bare `walle_audit.actions` would fail as not-found in `MO_PROJECT` and prove nothing |
| MD-3 | `mo-analyst@${MO_PROJECT}` calls `POST /v1/control/demote` on `walle-actions` in `WALLE_PROJECT` — and, paired, `GET /v1/runs/{id}` | **403** on the control path: `run.invoker` allows the HTTP call; the in-app allowlist refuses the path. Same for `/v1/control/halt`, `/v1/plans/{id}/approve` and `/veto`. **200** on the read path, which proves the allowlist row carries the cross-project email rather than an old `@${PROJECT}` address that 403s everything |
| MD-4 | `mo-analyst@${MO_PROJECT}` calls `GET /v1/ladder`, cross-project | **403.** Mo is not on that allowlist row (M72). Only `GET /v1/plans/{id}` and `GET /v1/runs/{id}` succeed |
| MD-5 | A bundle whose diff touches the **ceiling module** is written to the drop box | **Rejected at ingestion, before CI.** No pull request is created. Repeat for the policy chain, the catalogue's risk tiers and the validator |
| MD-6 | A bundle citing a `scorecard_sha256` that `mo-metrics@` never published | **Rejected at ingestion.** Closes the "cite evidence that does not exist" path before the recompute even runs. Repeat with a `snapshot_name` that does not exist |
| MD-7 | A bundle whose `evidence_block` value differs from what the SQL returns when re-run at its pinned commit | **Merge refused by the validator.** A forged promotion has to be *true* to pass |
| MD-8 | `mo-analyst@` writes a bundle to an object name that already exists; then reads back an object it wrote; then deletes one | **Fails, three times.** `roles/storage.objectCreator` "does not give permission to view, delete, or overwrite objects", so a double-triggered run duplicates nothing and Mo cannot retract a bundle after dropping it |
| MD-9 | Each of the enforcement identities [02-identity-and-access.md](02-identity-and-access.md) §5 names reads each of `` `${MO_PROJECT}.walle_metrics` ``, `walle_metrics_archive`, `walle_metrics_private` and `walle_metrics_views`, **cross-project, with the job submitted in the identity's home project**: `walle-actions@${WALLE_PROJECT}`, `walle-dispatcher@${WALLE_PROJECT}`, the ladder deploy tool (`WALLE_PROJECT`), `eve-controller@${EVE_PROJECT}`, the CI gate validator (its custodian's project). Run `walle-agent@${WALLE_PROJECT}` as a sixth for completeness — it is not on the assertion's list, and it should fail too | **403 accessDenied**, five times for the assertion and once more for `walle-agent@`. An identity without `jobUser` in its home project is refused at `jobs.create`, which is **not** this test's 403 — fix the harness, not the assertion. This is the mechanism behind [M-1](08-open-decisions.md) and change 15, and the only thing that turns Mo's containment from a claim into a test |
| MD-9b | `gcloud projects get-iam-policy "$MO_PROJECT"` and each Mo dataset's `access` array are enumerated | **No** member ending in `@${WALLE_PROJECT}.iam.gserviceaccount.com`, `@${EVE_PROJECT}.iam.gserviceaccount.com` or `@${GEMINI_PROJECT}.iam.gserviceaccount.com`, and none containing `gcp-sa-discoveryengine` (in particular not `service-${GEMINI_PROJECT_NUMBER}@gcp-sa-discoveryengine.iam.gserviceaccount.com`). The containment assertion as a project-IAM fact ([`../project-topology.md`](../project-topology.md) §3 row 24) |
| MD-10 | Each of the three Mo identities attempts `secretmanager.versions.access` on every secret enumerated in `WALLE_PROJECT` and every secret enumerated in `EVE_PROJECT` — there are none in `MO_PROJECT` or `GEMINI_PROJECT`, and `gcloud secrets list --project="$MO_PROJECT"` is asserted empty | **403 at Google**, for every identity on every secret. Mo holds no Secret Manager grant anywhere, at any phase |
| MD-11 | A `walle_metrics.scorecard` row with `verdict='ready'` and `n_decided = 34` is inserted into a scratch copy and the assertion query is run | **The job fails.** The floor and the gate are one decision |
| MD-12 | A published artefact is searched for an email-shaped string, and for any group-by cell with a count of 1 to 4 | **Zero matches**, both times |
| MD-13 | `mo-analyst@` and then `mo-narrator@` select from `walle_metrics_private.principal_surrogates` | **403 accessDenied, twice.** The mapping lives in a dataset with one WRITER and no reader. A surrogate that can be joined back to an email is not a surrogate, and dataset-level `READER` on `walle_metrics` would have covered the mapping had it stayed there |
| MD-14 | A bundle citing a `seed` that the per-week seed file does not record for `week(window_end)` is written to the drop box | **Rejected at ingestion**, beside MD-6 and for the same reason: the seed decides *which items are evidence*, and re-drawing from an unanchored seed proves only that the bundle agrees with itself |
| MD-15 | **Paired.** (a) `mo-metrics@` selects from a view in `` `${EVE_PROJECT}.eve_quality` ``, job in `MO_PROJECT`. (b) `mo-metrics@` selects from `` `${EVE_PROJECT}.eve.grades_blind` `` and from any other `eve` dataset; `mo-analyst@` and `mo-narrator@` select from `eve_quality`; a bundle whose diff touches `eve/config/predicates/**`, `ceilings.py`, `reasons.yaml`, `oncall.yaml` or `eve_authority` is dropped | **(a) succeeds; (b) 403 accessDenied** on every read, and the bundle is **rejected at ingestion**. Mo reads Eve's quality surfaces through one identity, never Eve's blind grades, and cannot reach Eve's gating layer |

The two shapes every test above uses:

```bash
# BigQuery, as a named service account. The job is submitted in the identity's HOME project
# (where its jobUser is); every table is fully qualified, because the reads cross projects.
# An identity without jobUser in its home project is refused at jobs.create — that is not
# the 403 these tests are for.
as_sa () {   # as_sa <service-account-email> <job-project> <sql>
  TOKEN="$(gcloud auth print-access-token --impersonate-service-account="$1")"
  curl -s -o /dev/stderr -w '%{http_code}\n' -X POST \
    -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' \
    "https://bigquery.googleapis.com/bigquery/v2/projects/${2}/queries" \
    -d "$(python3 -c 'import json,sys;print(json.dumps({"query":sys.argv[1],"useLegacySql":False}))' "$3")"
}

as_sa "$SA_MO_NARRATOR" "$MO_PROJECT"    "SELECT COUNT(*) FROM \`${MO_PROJECT}.walle_metrics_views.v_cell_public\`"    # MD-1a, expect 200
as_sa "$SA_MO_NARRATOR" "$MO_PROJECT"    "SELECT params_redacted FROM \`${WALLE_PROJECT}.walle_audit.actions\` LIMIT 1" # MD-1b
as_sa "$SA_MO_NARRATOR" "$MO_PROJECT"    "SELECT COUNT(*) FROM \`${MO_PROJECT}.walle_metrics.scorecard\`"              # MD-1b
as_sa "$SA_MO_ANALYST"  "$MO_PROJECT"    "SELECT COUNT(*) FROM \`${WALLE_PROJECT}.walle_audit.actions\`"               # MD-2
as_sa "$SA_MO_ANALYST"  "$MO_PROJECT"    "SELECT COUNT(*) FROM \`${MO_PROJECT}.walle_metrics_private.principal_surrogates\`"  # MD-13
as_sa "$SA_MO_NARRATOR" "$MO_PROJECT"    "SELECT COUNT(*) FROM \`${MO_PROJECT}.walle_metrics_private.principal_surrogates\`"  # MD-13
as_sa "$SA_ACTIONS"     "$WALLE_PROJECT" "SELECT COUNT(*) FROM \`${MO_PROJECT}.walle_metrics.scorecard\`"              # MD-9
as_sa "$SA_DISPATCH"    "$WALLE_PROJECT" "SELECT COUNT(*) FROM \`${MO_PROJECT}.walle_metrics.scorecard\`"              # MD-9
as_sa "$SA_AGENT"       "$WALLE_PROJECT" "SELECT COUNT(*) FROM \`${MO_PROJECT}.walle_metrics.scorecard\`"              # MD-9, sixth
as_sa "$SA_EVE"         "$EVE_PROJECT"   "SELECT COUNT(*) FROM \`${MO_PROJECT}.walle_metrics.scorecard\`"              # MD-9
# MD-15 (<view> is any view Eve's runbook publishes in eve_quality)
as_sa "$SA_MO_METRICS"  "$MO_PROJECT"    "SELECT COUNT(*) FROM \`${EVE_PROJECT}.eve_quality.<view>\`"                 # MD-15a, expect 200
as_sa "$SA_MO_METRICS"  "$MO_PROJECT"    "SELECT COUNT(*) FROM \`${EVE_PROJECT}.eve.grades_blind\`"                   # MD-15b, expect 403
as_sa "$SA_MO_ANALYST"  "$MO_PROJECT"    "SELECT COUNT(*) FROM \`${EVE_PROJECT}.eve_quality.<view>\`"                 # MD-15b, expect 403
as_sa "$SA_MO_NARRATOR" "$MO_PROJECT"    "SELECT COUNT(*) FROM \`${EVE_PROJECT}.eve_quality.<view>\`"                 # MD-15b, expect 403

# MD-9b: the containment assertion as a project-IAM fact
gcloud projects get-iam-policy "$MO_PROJECT" --flatten='bindings[].members' \
  --format='value(bindings.members)' \
  | grep -E "@${WALLE_PROJECT}\.iam\.gserviceaccount\.com|@${EVE_PROJECT}\.iam\.gserviceaccount\.com|gcp-sa-discoveryengine"
# expect: nothing
for DS in walle_metrics walle_metrics_archive walle_metrics_private walle_metrics_views; do
  bq show --format=prettyjson "${MO_PROJECT}:${DS}" | python3 -c \
    "import json,sys;[print(a) for a in json.load(sys.stdin)['access'] if 'userByEmail' in a and not a['userByEmail'].endswith('@${MO_PROJECT}.iam.gserviceaccount.com')]"
done
# expect: nothing from another project (the human owner's entry, if any, is the exception to read by eye)

# the action service, as a named service account
call_actions () {   # call_actions <service-account-email> <method> <path>
  ID_TOKEN="$(gcloud auth print-identity-token \
    --impersonate-service-account="$1" --audiences="$ACTIONS_URL")"
  curl -s -o /dev/stderr -w '%{http_code}\n' -X "$2" \
    -H "Authorization: Bearer ${ID_TOKEN}" "${ACTIONS_URL}$3"
}

# the service is in WALLE_PROJECT; the caller is in MO_PROJECT. The 200 on the read path is
# what proves the in-app allowlist carries mo-analyst@${MO_PROJECT}, not an old address.
call_actions "$SA_MO_ANALYST" POST /v1/control/demote    # MD-3, expect 403
call_actions "$SA_MO_ANALYST" GET  /v1/ladder            # MD-4, expect 403
call_actions "$SA_MO_ANALYST" GET  /v1/runs/<known-id>   # MD-3's pair, expect 200
```

**Record the result** the way [SETUP.md](../wall-e/SETUP.md) §4 requires: the date, the
commit, the image digests, and every test's outcome, committed. A promotion whose denial
suite has not been run is not a promotion.

---

## The manual steps, collected

Everything a human must do that no command above performs. **None of them is in the Admin
console** — Mo touches Workspace nowhere.

| # | Step | Phase | Why a human |
|---|---|---|---|
| 1 | Measure four weeks of baseline toil for the top three admin tasks, and the monthly human operating hours | Mo-0 | The denominator of [decision 38](../wall-e/09-open-decisions.md)'s stop-or-continue review cannot be reconstructed once Wall-E is doing the tasks |
| 1a | Create `MO_PROJECT` under `FOLDER_ID`, link billing, record its number; give Wall-E's owner the value for `walle.env` | Mo-1 step 0 | Project creation needs a folder-level role and a billing role no agent holds, and the id must reach Wall-E's config before any cross-project grant can be spelled |
| 1b | Wall-E's owner runs the cross-project grants from Wall-E's runbook — two dataset `READER`s on `walle_audit` and `walle_workspace_logs` after Phase 7, and the Phase 10 `run.invoker` entry plus the allowlist email | Mo-2, Mo-6 | The grants are on Wall-E's resources, in `WALLE_PROJECT`; Mo's builder never edits `WALLE_PROJECT` ([`../project-topology.md`](../project-topology.md) §7.1) |
| 1c | Eve's owner creates `eve_quality` and makes the dataset-level `READER` for `mo-metrics@${MO_PROJECT}` from Eve's runbook | Mo-2 | The dataset and the grant are Eve's resources, in `EVE_PROJECT`; Mo's builder never edits `EVE_PROJECT` (platform HLD §18 items 17 and 25) |
| 2 | Review and merge `config/metrics/gates.yaml` under `ladder.yaml`'s reviewers, in a pull request that does **not** also touch `ladder.yaml` | Mo-3 | M29, and change 13: a metric change must cost its own reviewed pull request and cannot promote anything in the same breath |
| 3 | Review the ~12 metric SQL files, checking specifically that no free-text column is selected and every query prunes to its window | Mo-4 | The exclusion of `params_redacted`, `result_summary` and error text is enforced by the query text and by this review, and by nothing else |
| 4 | Hold `bigquery.transfers.update` on `MO_PROJECT` and Service Account User on `mo-metrics@` when creating each transfer config | Mo-4 | Required to pin the query to a service account rather than to your own credentials |
| 5 | Paste the Monitoring notification channel resource name into the policy file before creating it | Mo-7 | An alert policy with no channel is a dashboard |
| 6 | Pause the metric transfer configs and confirm the **absence** condition fires, then resume in the same sitting | Mo-7 | The failure this alert exists to catch produces no data points at all; testing the threshold branch proves nothing |
| 7 | Set the artefact reader list to `walle-operators@` and the ladder owner, and exclude `platform/wall-e/mo/**` from the wiki's Drive sync | Mo-8 | [M-3](08-open-decisions.md). `walle_metrics` has a wider reader set than `walle_audit`, over data derived from personal data |
| 8 | Commit `config/metrics/graders.yaml`, and **name the second grader before S2 entry** | Mo-8 | [M-4](08-open-decisions.md). Mo cannot supply a person, and a `WRITE_HIGH` cell cannot pass L2 without one |
| 9 | Record Mo as a processor in the data-protection assessment, and correct weakness 11 rather than inheriting it | Mo-8 | T0 reads per-person rows. The claim that Mo's reads are aggregated per organisational unit is false at the pipeline layer |
| 10 | Name the validator custodian ([decision 37](../wall-e/09-open-decisions.md)) and hand them the recompute check | Mo-9 | The gate cannot be part of what it gates. Roughly 3 days of Mo-9 are theirs |
| 11 | Disable and audit admin bypass on branch protection; require two distinct authenticated reviewers, neither the author | Mo-9 | [M-7](08-open-decisions.md). The validator reports the setting it observes and cannot enforce it |
| 12 | Create the linked Spans dataset once in `WALLE_PROJECT`, holding `roles/observability.editor` there, then add the cross-project `READER` for `mo-metrics@${MO_PROJECT}` (a spike) | Mo-10 | Mo holds that role at no stage, and the dataset is Wall-E's |
| 13 | Decide at the S4 entry record whether `mo-narrator` is built at all, and against which pinned model id | Mo-11 | [M-8](08-open-decisions.md). Not building it is a defensible reading of this design |
| 13a | Review the first edition of the misbehaviour taxonomy and coverage map with the Eve owner and the security reviewer, before Wall-E's Stage 1 | With Eve's observe-and-report layer | Mo names the gaps; only humans decide which detectors to build ([04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §1.6) |
| 14 | Grade `max(10 %, 5 items/week)` of executing items **per cell**, blind, weekly, indefinitely — at pilot volume the floor of five binds in every cell, so ≥ 40 items a week across ~8 cells — plus 20 % double-graded for `WRITE_HIGH`, plus adjudication | From S2 | At least **two hours a week from a named human who is not the playbook owner**. It cannot be automated, cannot be sampled more thinly without the cell going `not_ready`, and cannot be delegated to a model without destroying the thing it measures |

Step 14 is not a build step and it is the one that decides whether any of the rest matters.
If nobody grades, the worklist goes ungraded, `n` never reaches 35, and no cell is ever
promotable — with everything above working perfectly. Mo reports grading coverage in the
digest **and in the monthly cost report, beside the hours it costs**, so a stalled programme
looks stalled on human attention rather than on safety.

---

## What this runbook forces on Wall-E's own set

Every change this build needs outside Mo's directory — its target file, its reference and why —
is defined in [08-open-decisions.md](08-open-decisions.md#what-this-design-forces-on-wall-es-set).
In build order: change **19** lands before Mo-1 step 0; **3** and Eve's **20** before Mo-2;
**1**, **2** and **4** to **7** before Mo-4; **9**, **10** and **12** before Mo-6; **8** and
**14** before Mo-7; **11** before Mo-8; **13** before Mo-9; the unnumbered Spans step before
Mo-10; **15** before Mo-12; **16** before S2; and **17** keeps the two full Mo phases here,
against `MO_PROJECT`, with only their cross-project grant steps in SETUP.

---

## Related documents

- [README.md](README.md) — the index and the one-paragraph claim
- [01-hld.md](01-hld.md) — what Mo is, and why it has that shape
- [02-identity-and-access.md](02-identity-and-access.md) — the authoritative grant tables this runbook executes
- [03-metrics-contract.md](03-metrics-contract.md) — the arithmetic, the fixtures and the assertion queries in full
- [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) — the bundle contract, the seed protocol and the validator's gates
- [05-staging.md](05-staging.md) — what exists at each stage, the acceptance test, and the cost tables
- [06-failure-modes.md](06-failure-modes.md) — what happens when each piece is wrong, absent or hostile
- [08-open-decisions.md](08-open-decisions.md) — the open decisions and the changes Mo forces on Wall-E's set
- [../project-topology.md](../project-topology.md) — the four projects, and the authority for every grant here that crosses one
- [../wall-e/SETUP.md](../wall-e/SETUP.md) — Wall-E's runbook, which makes the three cross-project grants on Mo's behalf (after Phase 7; Phase 10)
- [../eve/07-build-runbook.md](../eve/07-build-runbook.md) — Eve's equivalent, and the source of `EVE_PROJECT`; `SA_EVE` is `eve-controller@${EVE_PROJECT}.iam.gserviceaccount.com`
