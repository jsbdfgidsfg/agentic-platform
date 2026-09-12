# 7. Building Mo

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-12
- Last executed: **never**

## When to use this

To bring Mo into existence, one stage at a time, runnable by one person. Mo is not a
sitting; it is a series of them, spread along the stage floors of
[05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) at roughly a day a week.

Two of these phases are additions to Wall-E's own runbook and are written here in that
runbook's format so they can be lifted into it unchanged — **"Mo — metrics"** at Stage 0
and **"Mo — reporting"** at S1 (change 17 of [08-open-decisions.md](08-open-decisions.md)).
Everything after S1 happens once [SETUP.md](../wall-e/SETUP.md) has ended, so it lives only
here.

| Sitting | Stage | Phases | What exists afterwards |
|---|---|---|---|
| **The baseline** | Before Phase 1 | Mo-0 | `config/metrics/toil_baseline.csv`, and four weeks of elapsed measurement that cannot be reconstructed later. Nothing else of Mo |
| **SETUP phase "Mo — metrics"** | S0 | Mo-1 to Mo-5 | `walle_metrics`, `walle_metrics_archive`, `mo-metrics@`, `gates.yaml`, the Wilson and Newcombe UDFs, the golden fixtures, ~12 scheduled queries, the assertion queries, the daily snapshot. **No reporter job, no drop box, no model, no Pub/Sub, no Firestore, no action-service access.** Every cell reports `insufficient_data` |
| **SETUP phase "Mo — reporting"** | S1 | Mo-6 to Mo-8 | `mo-analyst@`, the authorised-view layer and its surrogate keys, the `mo-reporter` Cloud Run job on a weekly schedule, the freshness absence alert, the cost report and the S1 stop-or-continue document |
| **The gate** | S2 exit | Mo-9 | The drop box, CI ingestion, the bot author, and the validator's recompute check. This is the phase that makes a promotion able to cite Mo at all |
| **Spans** | S3 | Mo-10 | The one-off linked trace dataset, created by a human, never by Mo |
| **The narrator** | S4, optional | Mo-11 | `mo-narrator@` and one Cloud Run job calling `generateContent` with a pinned model id. It is legitimate never to execute this phase — [M-8 · 49](08-open-decisions.md) |
| **Standing** | every stage | Mo-12 | The denial tests authored from Mo's side. They run at the end of every sitting and again before every promotion |

**Executing Mo-1 to Mo-5 changes no autonomy level.** It grants no Workspace credential, mints
no token, creates no Workspace account, opens no network path and puts nothing on the
enforcement path. It is fifteen SQL files and one service account that reads BigQuery. That
is deliberate: a Mo that is abandoned after S0 costs nothing to abandon, and the S0 and S1
exit criteria deliberately cite no verdict of Mo's ([05-staging.md](05-staging.md)).

**Nothing in this runbook gives Mo a write path into anything that enforces.** Mo holds no
secret at any phase, no git credential at any phase, and no Workspace credential ever. If a
step below appears to grant one, it is wrong — stop and read
[02-identity-and-access.md](02-identity-and-access.md).

---

## What already exists, and what does not

**Almost nothing exists.** `grep` for `mo-analyst`, `mo_analyst` or `MO_` across
[SETUP.md](../wall-e/SETUP.md) returns one thing: `MO_PRINCIPAL`, an unresolved IAM member
string in `setup/walle.env.example`, used exactly once, to grant
`roles/agentregistry.viewer` in Phase 13b. No service account is created — `mo-analyst` is
not one of the five entries in `SERVICE_ACCOUNT_IDS`. No dataset grant, no topic
subscription, no Cloud Run binding, no phase.

**And no BigQuery read grant for Mo exists anywhere in the runbook.**
`add_dataset_access` is called exactly twice in `setup/walle_setup.py`: once for
`walle-actions@` on `walle_audit`, once for the `walle-audit-bq` sink writer identity on
`walle_workspace_logs`. The shared data plane that
[08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) promises is entirely unbuilt.

> **Every IAM grant, dataset, table, view, job, bucket and alert in this document is new.**
> Where a phase adds one, it is marked **NEW**. Nothing below is a re-statement of something
> the runbook already does.

The one thing that does exist is settled by resolution rather than by a code change:
`MO_PRINCIPAL` becomes `serviceAccount:mo-analyst@${PROJECT}.iam.gserviceaccount.com`, which
closes [PREREQUISITES](../wall-e/PREREQUISITES.md) items 11 and 13 with no edit to
`walle_setup.py` (change 12 of [08-open-decisions.md](08-open-decisions.md)). Phase Mo-6
creates the account that name refers to; until then Phase 13b's grant points at an account
that does not exist yet, which is a harmless no-op if Phase 13b runs first and a reason to
run Mo-6 before re-running Phase 13b if it does not.

---

## Prerequisites

### Upstream schema work that blocks phases, not decisions

These are not open questions. They are decided-and-not-landed changes to Wall-E's tables,
listed in full in [08-open-decisions.md](08-open-decisions.md). Each one silently empties a
metric if the phase that needs it runs first.

| Blocks | What must exist | Consequence if it does not |
|---|---|---|
| Mo-4 | `walle_audit.grades`, `walle_audit.proposal_verdicts`, `walle_audit.drills` as first-class write-ahead tables, with `grades` carrying `run_id`, `item_index`, `verdict`, `grader_id`, `is_playbook_owner`, `blind`, `saw_eve_verdict`, `graded_at`, `second_grader`, `adjudicated_by`, `adjudication`, `playbook_version` | Plan precision and drill freshness are **not computable at all**. Those rows render `not computable — C46 schema decision outstanding` and no cell is reported ready. Do **not** route around this by granting Mo Firestore access |
| Mo-4 | `walle_audit.ladder_events`, one row per effective-level transition | Dwell, the ratchet, two-demotions-in-90-days, >3-demotions-in-an-hour and the E35 false-positive review are all uncomputable. Automatic demotions deliberately write no decision file, so there is nowhere else to read them from |
| Mo-4 | `actions.noop BOOL NOT NULL` | Breaker-trip counts carry `noop_exclusion_unavailable` and are used in no verdict |
| Mo-4 | `actions.selection_hash`, `adk_version`, `ma_filter_version`, `engine_resource`, and a computed `fingerprint_sha` | Six of the ten fingerprint fields are on the row today. Until the other four land, `fingerprint_sha` is computed over the available subset and the scorecard labels attribution `partial_fingerprint` |
| Mo-4 | The per-item accept/reject vector on `approvals`, bound to `plan_hash`, with rejections as `skipped_by_operator` | Batch precision is `not computable` rather than approximated. The approximation is exactly the inflation C16 found |
| Mo-4 | The `capability_gap` closed-enum intent class | `agg_capability_gap` returns empty and the demand signal is `tbd` |
| Mo-7 | Canonical plan serialisation — RFC 8785 canonical JSON, SHA-256 — and the signed field list, written **before** the approve endpoint and its stub caller are built | Mo cannot recompute `plan_hash` the same way. The weekly plan/audit agreement check is dropped, and with it the only justification for Mo holding any action-service access at all — at which point Mo-6 should not grant `roles/run.invoker` |

### Decisions that must be closed before the phase that needs them

| Decision | Needed before | If unanswered |
|---|---|---|
| [M-5 · 46](08-open-decisions.md) — the retention floor ([decision 17](../wall-e/09-open-decisions.md)) | Mo-1 | `walle_metrics` partition expiry is set to 400 days to match `walle_audit`, marked `Assumption:`. Mo clamps every window to the declared floor and flags a clamped window rather than reporting it as if it were full |
| [M-4 · 45](08-open-decisions.md) — who is the second grader | Before S2 entry, not S3 | A `WRITE_HIGH` cell cannot pass L2 without 20 % blind double-grading by someone other than the playbook owner. Mo reports `no_second_grader` from S0 so the block is visible for months before it bites |
| [M-6 · 47](08-open-decisions.md) — the pilot OU account count ([decision 5](../wall-e/09-open-decisions.md)) | Before S2 | Mo's scorecard has no denominator. At small volume the coupled floor of 35 and the 30-day window may never both be satisfiable, and some cells sit at L2 or L3 permanently |
| [M-3 · 44](08-open-decisions.md) — who may read `walle_metrics` ([decision 35](../wall-e/09-open-decisions.md)) | Mo-8 | Readers are `walle-operators@` and the ladder owner only, minimum reporting cell size 5 (`Assumption:`), and **no Mo artefact is synced to Drive** |
| [M-7 · 48](08-open-decisions.md) — the git host and its admin-bypass setting | Mo-9 | The two-distinct-authenticated-reviewer rule is decoration if an administrator can bypass branch protection. The validator reports the setting it observes and cannot enforce it |
| [M-1 · 42](08-open-decisions.md) — does "no write path of any kind" permit `mo-metrics@` writing `walle_metrics`? | Mo-1 | The whole of Mo-1 is that write. The design reads the rule as *no byte Mo writes is read by anything that enforces*, and makes it true by mechanism — denial test **MD-9** below is that mechanism |
| [M-8 · 49](08-open-decisions.md) — is T2 built at all, and against which pinned model id? | Mo-11 | Do not execute Mo-11. Mo is complete and useful without it |

### Access you need, and where to get it early

| What | Where | Phase | Lead time |
|---|---|---|---|
| Project editor on `${PROJECT}`, or the narrower set below | Wall-E's project | Mo-1 onward | Same day |
| `bigquery.transfers.update` on the project, **and** Service Account User on `mo-metrics@` | Wall-E's project | Mo-4 | Same day. Both are required to pin a scheduled query to a service account |
| The ability to edit the `access` array of `walle_audit` — dataset owner or `roles/bigquery.admin` | Wall-E's project | Mo-2, Mo-6 | Same day. This is the grant nothing in the runbook makes today |
| **`roles/observability.editor`** | Wall-E's project | Mo-10 | **Allow calendar time** if you do not already hold it. One human holds it once, to create the linked trace dataset. Mo never holds it |
| Repository admin on the config repository, to add a required CI check and to set branch protection | Git host | Mo-9 | `tbd` until [M-7 · 48](08-open-decisions.md) names the host |
| The **validator custodian** ([decision 37](../wall-e/09-open-decisions.md)), who owns the recompute check from outside the config repository | Organisation | Mo-9 | Name them at S2, not at S2 exit. Roughly 3 of Mo-9's days are theirs, not Mo's |
| Two named humans who will grade | Tenant | Mo-8 | See [M-4 · 45](08-open-decisions.md). Mo cannot supply a person |
| `gcloud` **563.0.0 or later**, `bq`, `python 3.12`, `openssl` | Your machine | all | Mo-10's command needs that version |

**No Workspace access is needed at any phase.** Mo has no Workspace account, no OAuth
client, no scope, no consent, no licence and no hardware key. That is the shortest statement
of what Mo is.

### Set these once per shell

```bash
# ---- Wall-E's, from SETUP.md section 1.7 ------------------------------------
export PROJECT="<walle-project-id>"
export REGION="europe-west1"
export BQ_LOCATION="EU"
export DOMAIN="<primary-domain>"
export OPERATORS="walle-operators@${DOMAIN}"
export ACTIONS_URL="<https url of walle-actions>"

export SA_ACTIONS="walle-actions@${PROJECT}.iam.gserviceaccount.com"
export SA_AGENT="walle-agent@${PROJECT}.iam.gserviceaccount.com"
export SA_DISPATCH="walle-dispatcher@${PROJECT}.iam.gserviceaccount.com"
export SA_EVE="eve-controller@${PROJECT}.iam.gserviceaccount.com"

# ---- Mo's three identities, none of which exists yet ------------------------
export SA_MO_METRICS="mo-metrics@${PROJECT}.iam.gserviceaccount.com"
export SA_MO_ANALYST="mo-analyst@${PROJECT}.iam.gserviceaccount.com"
export SA_MO_NARRATOR="mo-narrator@${PROJECT}.iam.gserviceaccount.com"

export MO_PROPOSALS="gs://walle-mo-proposals"
export MO_AR="${REGION}-docker.pkg.dev/${PROJECT}/mo"

echo "PROJECT=$PROJECT REGION=$REGION BQ_LOCATION=$BQ_LOCATION"
```

Save it to `~/.mo-env`, `source` it at the start of every session, and guard it the way
Wall-E's runbook does — this build spans months, not a week:

```bash
[ -n "$PROJECT" ] || { echo 'env not sourced'; return 1; }
```

`SA_EVE` is written here as `eve-controller@${PROJECT}` because that is what
[SETUP.md](../wall-e/SETUP.md) section 1.7 says. If Eve is built in its own project per
[../eve/07-build-runbook.md](../eve/07-build-runbook.md), the address changes and denial
test **MD-9** below must name the other project's account. Check before running it; a test
that names an account which does not exist passes for the wrong reason.

---

# SETUP phase "Mo — metrics" (Stage 0)

Slots into [SETUP.md](../wall-e/SETUP.md) after Phase 7, which is where `walle_audit` comes
into existence. `Assumption:` Phase 7b is a free number.

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

## Phase Mo-1 — `walle_metrics` and `walle_metrics_archive` **NEW**

Two datasets, for the same reason Wall-E's Phase 7 makes two: their reader sets differ.
`walle_metrics` has a **wider reader set than `walle_audit`** — which is precisely why
suppression is a mechanism in [03-metrics-contract.md](03-metrics-contract.md) and not a
promise.

```bash
bq --location="$BQ_LOCATION" mk --dataset \
   --description="Mo's computed metrics. Written only by mo-metrics@. Read by NOTHING on Wall-E's enforcement path." \
   "${PROJECT}:walle_metrics"

bq --location="$BQ_LOCATION" mk --dataset \
   --description="Dated scorecard snapshots. The citable object a promotion points at." \
   "${PROJECT}:walle_metrics_archive"
```

The scorecard and the sixteen supporting aggregates, partitioned on `as_of`. Schemas live in
`schemas/mo_*.json` in the repository; columns are specified in
[03-metrics-contract.md](03-metrics-contract.md), which is authoritative wherever this page's
SQL names one.

`Assumption:` the twenty table names in the loop below, the single agent-facing view
`walle_metrics.v_cell_public` used as the example in Mo-6, the metric SQL filenames under
`config/metrics/`, and `config/metrics/graders.yaml` for the committed grader list are this
runbook's names for objects the design describes without naming. The sixteen `agg_*` names
are the design's own.

```bash
# 34560000 seconds = 400 days, matching walle_audit.
# Assumption: 400 days pending Wall-E decision 17 (M-5). The floor is read from gates.yaml
# query time, so a later, shorter answer clamps the windows without a table rebuild.
for T in scorecard \
         agg_precision_cell agg_verification_cell agg_reliability_playbook \
         agg_invalid_params_cell agg_invariant_denials agg_breaker_trips \
         agg_audit_completeness agg_drill_freshness agg_approval_latency \
         agg_eve_latency agg_sample_coverage agg_regression_attribution \
         agg_cost_operation agg_cost_playbook agg_value_toil agg_capability_gap \
         grading_worklist principal_surrogates toil_baseline; do
  bq mk --table \
    --time_partitioning_field=as_of \
    --time_partitioning_type=DAY \
    --time_partitioning_expiration=34560000 \
    "${PROJECT}:walle_metrics.${T}" "./schemas/mo_${T}.json"
done
```

`bq mk` rejects a clustering field that is not in the supplied schema, so a loop like this
one dies partway and leaves some tables created and some not. Re-running it after a fix is
safe — `bq mk` on an existing table is an error, not an overwrite — but read the error
before assuming it is the harmless one.

**Verify.**

```bash
bq show --format=prettyjson "${PROJECT}:walle_metrics" | grep -E '"location"|"datasetId"'
# expect: EU

bq show --format=prettyjson "${PROJECT}:walle_metrics.scorecard" \
  | grep -E 'timePartitioning|expirationMs' -A3
# expect: DAY partitioning on as_of, expirationMs 34560000000

bq ls --format=prettyjson "${PROJECT}:walle_metrics" | python3 -c \
  "import json,sys; d=json.load(sys.stdin); print(len(d), 'objects')"
# expect: 20
```

Both datasets must report `EU`. A dataset created in the wrong location cannot be moved, and
a cross-location join against `walle_audit` fails outright rather than quietly.

**Rollback.**

```bash
bq rm -r -f -d "${PROJECT}:walle_metrics"
bq rm -r -f -d "${PROJECT}:walle_metrics_archive"
```

Nothing outside these two datasets has changed, and nothing in them is irreplaceable at this
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
gcloud iam service-accounts create mo-metrics --project="$PROJECT" \
  --display-name="Mo T0 — committed metric SQL, no model, no egress"

# job creation only. NOT dataViewer at project level: that would be a lateral path
# into every dataset in Wall-E's project.
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_MO_METRICS}" --role=roles/bigquery.jobUser

# the Data Transfer Service impersonates this account; the human creating the config
# must be allowed to say so (verified 2026-09-12, "Service accounts with BigQuery
# Data Transfer": the updating user needs bigquery.transfers.update and access to the
# service account)
gcloud iam service-accounts add-iam-policy-binding "$SA_MO_METRICS" \
  --project="$PROJECT" \
  --member="user:$(gcloud config get-value account)" \
  --role=roles/iam.serviceAccountUser
```

The read grants are **dataset-level, never project-level**. `bq add-iam-policy-binding`
operates on tables, views and connections, not datasets, so dataset access is edited through
the dataset's own `access` array:

```bash
grant_dataset () {   # grant_dataset <dataset> <ROLE> <member-email>
  bq show --format=prettyjson "${PROJECT}:$1" > /tmp/ds.json
  DS_ROLE="$2" DS_SA="$3" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/ds.json'))
d.setdefault('access', []).append(
    {"role": os.environ['DS_ROLE'], "userByEmail": os.environ['DS_SA']})
json.dump(d, open('/tmp/ds.json', 'w'))
EOF
  bq update --source=/tmp/ds.json "${PROJECT}:$1"
}

grant_dataset walle_audit          READER "$SA_MO_METRICS"
grant_dataset walle_workspace_logs READER "$SA_MO_METRICS"
grant_dataset walle_metrics        WRITER "$SA_MO_METRICS"
grant_dataset walle_metrics_archive WRITER "$SA_MO_METRICS"
```

`WRITER` is the dataset-level form of `roles/bigquery.dataEditor`, and the account
additionally needs `bigquery.datasets.get` and `bigquery.datasets.update` on the **target**
dataset for the Data Transfer Service to write there — both of which `WRITER` carries
([Service accounts with BigQuery Data Transfer](https://docs.cloud.google.com/bigquery/docs/use-service-accounts),
verified 2026-09-12).

> **None of these four grants exists in the runbook today.** `add_dataset_access` is called
> exactly twice in `setup/walle_setup.py`, for `walle-actions@` and the `walle-audit-bq`
> sink writer. This phase is where change 3 of [08-open-decisions.md](08-open-decisions.md)
> lands.

**Verify.**

```bash
for DS in walle_audit walle_workspace_logs walle_metrics walle_metrics_archive; do
  echo "== $DS"
  bq show --format=prettyjson "${PROJECT}:${DS}" | python3 -c \
    "import json,sys;[print(a) for a in json.load(sys.stdin)['access']]"
done
# expect: mo-metrics@ READER on walle_audit and walle_workspace_logs, and WRITER on
#         neither of them. WRITER on walle_metrics and walle_metrics_archive only.

# prove the negative at project level
gcloud projects get-iam-policy "$PROJECT" --flatten='bindings[].members' \
  --filter="bindings.members:${SA_MO_METRICS}" --format='value(bindings.role)'
# expect: roles/bigquery.jobUser, and nothing else. No dataViewer, no dataEditor,
#         no run.invoker, no secretmanager.secretAccessor, no aiplatform.user.

# it holds no secret, at any phase
for S in walle-refresh-token walle-oauth-client eve-oauth-client eve-refresh-token; do
  gcloud secrets get-iam-policy "$S" --project="$PROJECT" \
    --flatten='bindings[].members' \
    --filter="bindings.members:${SA_MO_METRICS}" --format='value(bindings.role)'
done
# expect: nothing, four times
```

**Rollback.** Remove the four `access` entries the same way they were added, then

```bash
gcloud projects remove-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_MO_METRICS}" --role=roles/bigquery.jobUser
gcloud iam service-accounts delete "$SA_MO_METRICS" --project="$PROJECT" --quiet
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
also touch `ladder.yaml`**. The full field list is in
[03-metrics-contract.md](03-metrics-contract.md); the numbers are `z = 1.959964`, promote
lower bound 0.90, demote upper bound 0.95, L1 upper bound 0.90, graded floor 35, `unsure`
cap 0.10 (`Assumption:`), blind sample rate `max(10 %, 5/week)`, double-grade coverage 0.20,
minimum reporting cell size 5 (`Assumption:`), business-hours calendar Europe/Paris, the
per-source freshness bounds, and `retention_floor_days`, which stays *tbd* until Wall-E's
[decision 17](../wall-e/09-open-decisions.md) ([M-5 · 46](08-open-decisions.md)) answers it —
every window is clamped to it at query time, so a later, shorter answer needs no rebuild.

**2. The Wilson bounds, as persistent UDFs** in `walle_metrics`, so that the scheduled
queries, the assertion queries and the validator all execute the same text:

```bash
bq query --use_legacy_sql=false --project_id="$PROJECT" --location="$BQ_LOCATION" <<'SQL'
CREATE OR REPLACE FUNCTION `walle_metrics.wilson_lower`(k INT64, n INT64)
RETURNS FLOAT64 AS (
  IF(n = 0, NULL,
    ( (k/n) + (1.959964*1.959964)/(2*n)
      - 1.959964 * SQRT( ((k/n)*(1-(k/n)))/n + (1.959964*1.959964)/(4*n*n) )
    ) / (1 + (1.959964*1.959964)/n)
  )
);

CREATE OR REPLACE FUNCTION `walle_metrics.wilson_upper`(k INT64, n INT64)
RETURNS FLOAT64 AS (
  IF(n = 0, NULL,
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
with the declared parameter is exactly the failure the fixtures below exist to catch.

**3. The golden fixtures — the design document is the test oracle.** Expected values are the
constants [14-hld-challenge.md](../wall-e/14-hld-challenge.md) C18 published, re-derived
during judging. **CI fails if any differs**, which makes code drifting from the design a
build failure rather than a discovery.

```bash
bq query --use_legacy_sql=false --project_id="$PROJECT" --location="$BQ_LOCATION" <<'SQL'
WITH fixtures AS (
  SELECT 'lower' bound, 30 k, 30 n, 0.8865 expected UNION ALL
  SELECT 'lower', 35, 35, 0.9011 UNION ALL
  SELECT 'lower', 39, 40, 0.8712 UNION ALL
  SELECT 'lower', 52, 53, 0.9006 UNION ALL
  SELECT 'upper', 18, 20, 0.9721 UNION ALL
  SELECT 'upper', 17, 20, 0.9476 UNION ALL
  SELECT 'upper', 16, 20, 0.9193 UNION ALL
  SELECT 'upper', 15, 20, 0.8881
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

**Verify.** Eight rows, eight `PASS`. Each one is a decision in the ladder, and it is worth
reading them as such rather than as arithmetic: 30/30 does **not** promote, which is why the
floor moved to 35; 35/35 is the smallest perfect sample that promotes; 39/40 does not
promote, so one wrong at n=40 is not enough; 52/53 is the smallest sample admitting one
wrong that promotes; 18/20 (two wrong) does **not** demote; 17/20 (three wrong) demotes one
level; 16/20 (four wrong) does **not** drop to L1; 15/20 (five wrong) drops to L1.

Then the two floor fixtures, which are about the verdict rather than the bound: a synthetic
cell at 34/34 must report `not_ready` with reason `sample_below_floor`, and at 35/35
`ready`. The floor and the gate are one decision, so a build in which 34/34 reports `ready`
is not a build with a bug in its floor; it is a build without a floor.

**Rollback.**

```bash
bq rm -f --routine "${PROJECT}:walle_metrics.wilson_lower"
bq rm -f --routine "${PROJECT}:walle_metrics.wilson_upper"
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
    --project_id="$PROJECT" \
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

**Two rules the query text must obey, and CI must check.**

1. **No free-text column is ever selected.** `params_redacted`, `result_summary` and every
   Google error string are excluded by the query text and again by CI review. This is what
   makes N5 of [06-security-guardrails.md](../wall-e/06-security-guardrails.md) satisfied by
   there being nothing to canonicalise.
2. **Every query prunes to its window.** `actions` is partitioned on `ts` and clustered on
   `operation`; an unpartitioned scan of the whole history, fifteen times an hour, is the
   difference between single-digit euros a month and a bill worth arguing about.

**Verify.**

```bash
bq ls --transfer_config --transfer_location="$BQ_LOCATION" --project_id="$PROJECT" \
  --format=prettyjson | python3 -c \
  "import json,sys;[print(c['displayName'], c['schedule'], c.get('serviceAccountName','USER CREDENTIALS')) for c in json.load(sys.stdin)]"
# expect: every row pinned to mo-metrics@. A row reading USER CREDENTIALS is the
#         audit-independence defect this phase exists to prevent — delete and recreate it.

# after the first hour, the watermark exists and the verdicts are honest
bq query --use_legacy_sql=false --project_id="$PROJECT" \
  'SELECT verdict, COUNT(*) n, MAX(as_of) watermark
   FROM `walle_metrics.scorecard` GROUP BY verdict'
# expect at S0: every row insufficient_data. The write budget is 0 and no sample
#         approaches 35. A `ready` row at S0 means the floor is not wired.
```

Read the reason arrays too. At S0 the expected reasons include `sample_below_floor` and
— if [M-4 · 45](08-open-decisions.md) is still open — `no_second_grader` on every `WRITE_HIGH`
cell. That second one is the point of reporting from S0: the block is visible for months
before it bites at S2, rather than being discovered at S3.

**Rollback.**

```bash
bq ls --transfer_config --transfer_location="$BQ_LOCATION" --project_id="$PROJECT" \
  --format='value(name)' | grep 'transferConfigs/' | while read -r C; do
  bq rm -f --transfer_config "$C"
done
```

Check what that lists before running it — the same command deletes any other project's
transfer configs in the same location if any exist. `walle_metrics` rows survive; they are
recomputable, and leaving them makes the gap in the series visible rather than invisible.

---

## Phase Mo-5 — Assertion queries and the daily snapshot **NEW**

**The assertion queries are the control that holds regardless of whether the arithmetic is
right.** They are the answer to the failure the validator structurally cannot catch: the
validator re-runs the same committed SQL and inherits the same defect, so an invariant that
does not depend on the arithmetic is the only thing left. A failure pages and **freezes
promotions**.

```bash
bq query --use_legacy_sql=false --project_id="$PROJECT" --location="$BQ_LOCATION" <<'SQL'
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
        LEFT JOIN `walle_audit.grades` g USING (run_id, item_index)
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
SQL
```

The last two are the suppression rule, and they are enforcement rather than review: no
published row carries an email-shaped string, and no published group-by cell has a count
between 1 and 4 (`Assumption:` minimum cell size 5, pending
[decision 35](../wall-e/09-open-decisions.md)).

**The daily snapshot.** A promotion should point at a dated, citable object, not at a
mutable table. `CREATE SNAPSHOT TABLE … OPTIONS(expiration_timestamp=…)` (verified
2026-09-12) gives exactly that, at storage cost only:

```bash
bq mk --transfer_config \
  --project_id="$PROJECT" \
  --location="$BQ_LOCATION" \
  --data_source=scheduled_query \
  --display_name="mo-snapshot-scorecard" \
  --service_account_name="$SA_MO_METRICS" \
  --schedule="every day 02:07" \
  --params='{"query": "EXECUTE IMMEDIATE FORMAT(\"CREATE SNAPSHOT TABLE `walle_metrics_archive.scorecard_%s` CLONE `walle_metrics.scorecard` OPTIONS(expiration_timestamp = TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 400 DAY))\", FORMAT_DATE(\"%Y%m%d\", CURRENT_DATE()))"}'
```

The 400-day expiration is `Assumption:` pending [M-5 · 46](08-open-decisions.md), and it is set
**at creation** so that an unattended snapshot series cannot outlive the retention answer.

**Verify.**

```bash
# the assertions actually bite: write a deliberately bad row into a scratch copy
# and confirm the ASSERT fails the job rather than warning
bq query --use_legacy_sql=false --project_id="$PROJECT" \
  "SELECT 1 FROM \`walle_metrics.scorecard\` WHERE verdict='ready' AND n_decided < 35"
# expect: zero rows, always

bq ls --format=prettyjson "${PROJECT}:walle_metrics_archive" | python3 -c \
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

# SETUP phase "Mo — reporting" (S1)

Executed after Stage 0 exit, against the S1 decision record. It adds one identity, one view
layer, one Cloud Run job and one alert. It still grants Mo no credential and no write path
into anything that enforces.

---

## Phase Mo-6 — `mo-analyst@`, the authorised views, and the surrogate keys **NEW**

This is the phase that resolves `MO_PRINCIPAL`. After it, the Phase 13b grant in
[SETUP.md](../wall-e/SETUP.md) points at an account that exists.

```bash
gcloud iam service-accounts create mo-analyst --project="$PROJECT" \
  --display-name="Mo T1 — reporter. Reads computed aggregates only."

gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_MO_ANALYST}" --role=roles/bigquery.jobUser

# the two read grants, and they are the ONLY two. Never on walle_audit.
grant_dataset walle_metrics         READER "$SA_MO_ANALYST"
grant_dataset walle_metrics_archive READER "$SA_MO_ANALYST"

# the two read endpoints on the action service, and nothing else
gcloud run services add-iam-policy-binding walle-actions --region="$REGION" \
  --member="serviceAccount:${SA_MO_ANALYST}" --role=roles/run.invoker

# Phase 13b's grant, now that the principal resolves
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_MO_ANALYST}" --role=roles/agentregistry.viewer
```

`roles/agentregistry.viewer` is **granted and unused**. It is kept because M47 binds
`strong`, the grant is already built in Phase 13b, and it is read-only on a registry. The
scorecard records it as granted-and-unused, which is the honest state and is cheaper to
audit than a deletion that forces an edit to `walle_setup.py`.

`roles/run.invoker` on `walle-actions` allows the HTTP call; it does **not** allow the path.
`GET /v1/plans/{id}` and `GET /v1/runs/{id}` are the only two endpoints Mo may reach, and
they are the only thing BigQuery cannot tell Mo. `/v1/ladder`, `/v1/control/*`, `/approve`
and `/veto` are refused by the in-app allowlist — that is denial tests **MD-3** and **MD-4**,
and it is the same mechanism that refuses `walle-agent@` in
[SETUP.md](../wall-e/SETUP.md) §4 test 4.

**The authorised-view layer.** This is what makes the model's blindness an IAM fact rather
than a sanitisation step. Principals granted on an authorised view "can view the data you
share and run queries on it, but they can't access the source dataset directly" (verified
2026-09-12).

```bash
# one view per agent-facing surface. Ids, hashes, closed enums, counts, timestamps and
# surrogate keys ONLY: no params_redacted, no result_summary, no content_flags free text,
# no display name, no group name, no Google error string, no principal email.
bq query --use_legacy_sql=false --project_id="$PROJECT" --location="$BQ_LOCATION" <<'SQL'
CREATE OR REPLACE VIEW `walle_metrics.v_cell_public` AS
SELECT as_of, as_of_hour, family, trigger, fingerprint_sha,
       current_level, target_level, verdict, reasons,
       n_decided, n_unsure, unsure_rate, wilson_lower, wilson_upper,
       sample_coverage_achieved, sample_coverage_required,
       double_grade_coverage, raw_agreement, gwet_ac1,
       error_budget_state, freeze_state, ceiling, dwell_elapsed, dwell_required
FROM `walle_metrics.scorecard`;
SQL

# register each view on the SOURCE dataset's access list
authorise_view () {   # authorise_view <source-dataset> <view-dataset> <view-name>
  bq show --format=prettyjson "${PROJECT}:$1" > /tmp/src.json
  V_DS="$2" V_TB="$3" P="$PROJECT" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/src.json'))
d.setdefault('access', []).append({"view": {
    "projectId": os.environ['P'],
    "datasetId": os.environ['V_DS'],
    "tableId":   os.environ['V_TB']}})
json.dump(d, open('/tmp/src.json', 'w'))
EOF
  bq update --source=/tmp/src.json "${PROJECT}:$1"
}

authorise_view walle_audit walle_metrics v_cell_public
```

**The surrogate keys.** `walle_metrics.principal_surrogates` holds a monotone integer per
distinct principal, populated by a `MERGE` inside T0 — never by T1, which cannot read the
raw rows it would need. The agent-facing views carry `principal_surrogate INT64` and never
`principal`. This preserves "the same subject recurs", which is a real signal, while
destroying identity, which is strictly better than omitting the column and losing the
signal with it.

**Verify.** The negatives are the point of this phase.

```bash
TOKEN="$(gcloud auth print-access-token --impersonate-service-account="$SA_MO_ANALYST")"

# mo-analyst@ must NOT be able to read walle_audit
curl -s -X POST -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' \
  "https://bigquery.googleapis.com/bigquery/v2/projects/${PROJECT}/queries" \
  -d '{"query":"SELECT COUNT(*) FROM `walle_audit.actions`","useLegacySql":false}'
# expect: 403 accessDenied. This is denial test MD-2.

# it CAN read the computed aggregates
curl -s -X POST -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' \
  "https://bigquery.googleapis.com/bigquery/v2/projects/${PROJECT}/queries" \
  -d '{"query":"SELECT COUNT(*) FROM `walle_metrics.scorecard`","useLegacySql":false}'
# expect: a row count

# no free-text column survives into a view
bq query --use_legacy_sql=false --project_id="$PROJECT" \
  "SELECT column_name FROM \`walle_metrics.INFORMATION_SCHEMA.COLUMNS\`
   WHERE table_name LIKE 'v_%'
     AND column_name IN ('params_redacted','result_summary','content_flags',
                         'principal','primary_email','group_key','error_message')"
# expect: zero rows
```

**Rollback.** Remove the `view` entries from `walle_audit`'s access array, drop the views,
remove the four bindings, and `gcloud iam service-accounts delete "$SA_MO_ANALYST"`. Note
that removing the account leaves `MO_PRINCIPAL` dangling again and Phase 13b's grant
pointing at nothing.

---

## Phase Mo-7 — `mo-reporter`, its schedule, and the absence alert **NEW**

**A job, not a service.** Mo's workload is batch-shaped. A Cloud Run service caps one
request at 60 minutes; a job task runs to 168 hours (verified 2026-09-12). Nothing in Mo is
request-shaped, and pretending otherwise would inherit a ceiling for no gain.

```bash
gcloud run jobs create mo-reporter \
  --image="${MO_AR}/mo-reporter@sha256:<digest>" \
  --region="$REGION" \
  --service-account="$SA_MO_ANALYST" \
  --task-timeout=3600s \
  --max-retries=1 \
  --tasks=1 \
  --set-env-vars="PROJECT=${PROJECT},BQ_LOCATION=${BQ_LOCATION},ACTIONS_URL=${ACTIONS_URL},GATES_PATH=config/metrics/gates.yaml"
```

**By digest, never by a mutable tag.** A tag can be moved after review; a digest cannot. The
same rule applies to the validator image in Mo-9 and to the narrator in Mo-11.

Scheduling. The target is `run.googleapis.com`, which is a `*.googleapis.com` host, so it
takes an **OAuth** token and not OIDC — "OIDC is generally used *except* for Google APIs
hosted on `*.googleapis.com` as these APIs expect an OAuth token" (verified 2026-09-12).

```bash
# the invoking identity needs run.invoker ON THE JOB, which is a different resource
# from the walle-actions service. Assumption: mo-analyst@ invokes itself. The binding is
# carried in 02-identity-and-access.md section 2.2 as its own row.
gcloud run jobs add-iam-policy-binding mo-reporter --region="$REGION" \
  --member="serviceAccount:${SA_MO_ANALYST}" --role=roles/run.invoker

gcloud scheduler jobs create http mo-reporter-weekly \
  --location="$REGION" \
  --schedule="0 6 * * 1" \
  --time-zone="Europe/Paris" \
  --uri="https://run.googleapis.com/v2/projects/${PROJECT}/locations/${REGION}/jobs/mo-reporter:run" \
  --http-method=POST \
  --oauth-service-account-email="$SA_MO_ANALYST" \
  --attempt-deadline=180s \
  --max-retry-attempts=2
```

Monday 06:00 Europe/Paris, so the digest is in `walle-operators@`'s inbox by 08:00. The
Cloud Scheduler **service agent** must additionally hold `roles/cloudscheduler.serviceAgent`
to mint the token — without it "authentication will fail regardless of your service account
permissions". And Scheduler is at-least-once: "only a single instance of a job should be run
at any time", but in rare cases multiple may, so the handler must be idempotent. `mo-reporter`
is idempotent on job name plus the `X-CloudScheduler-ScheduleTime` header, which "contains
the original scheduled invocation time and remains constant across retry attempts".

**The freshness absence alert.** Mo's absence must be strictly more restrictive than its
presence, and the detection of that absence cannot depend on Mo publishing a liveness
signal. A threshold-only policy is silent exactly when the metric stops being written.

```bash
gcloud beta monitoring channels list --format='value(name,displayName)'
```

```bash
cat > /tmp/mo-watermark.yaml <<'EOF'
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
  - projects/PROJECT_ID/notificationChannels/CHANNEL_ID   # paste yours
EOF

gcloud monitoring policies create --policy-from-file=/tmp/mo-watermark.yaml
```

The 24-hour number is the same one the validator enforces in Mo-9: a watermark older than 24
hours makes the validator refuse **every** promotion. That is the mirror of Eve failing
closed, and it is why this alert is a control rather than a dashboard.

**Verify.**

```bash
gcloud run jobs execute mo-reporter --region="$REGION" --wait
gcloud run jobs executions list --job=mo-reporter --region="$REGION" \
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
gcloud scheduler jobs resume mo-reporter-weekly --location="$REGION"
gcloud scheduler jobs run    mo-reporter-weekly --location="$REGION"
```

**Rollback.**

```bash
gcloud scheduler jobs delete mo-reporter-weekly --location="$REGION" --quiet
gcloud run jobs delete mo-reporter --region="$REGION" --quiet
gcloud monitoring policies list --format='value(name,displayName)'   # then delete by name
```

Deleting the reporter degrades nothing that enforces. The artefacts go stale and say so —
`ladder-state.md` carries the watermark — and no promotion can cite a stale one.

---

## Phase Mo-8 — The artefact paths, the readers, and the grader list

No cloud resource. Four things a human does, and the reason each one is a human's.

1. **Create the artefact directory** `platform/wall-e/mo/` in the wiki repository, and
   commit an empty `ladder-state.md` with the current matrix. `mo-reporter` regenerates it
   **as a pull request**, never as a push — Mo holds no git credential, at any phase.
2. **Set the reader list.** Until [decision 35](../wall-e/09-open-decisions.md) lands,
   readers are `walle-operators@` and the ladder owner only, and **no Mo artefact is synced
   to Drive** ([M-3 · 44](08-open-decisions.md)). This is a manual choice in the wiki's sync
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

**Verify.** The wiki sync excludes `platform/wall-e/mo/**`; the grader list is committed and
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

**1. The drop box.** One bucket. It exists so that Mo holds no git credential: Mo drops a
bundle, and CI — under a bot identity that is **not** Mo — turns it into a pull request.
The one component in the alternative designs whose compromise produces a plausible promotion
pull request therefore does not exist.

```bash
gcloud storage buckets create "$MO_PROPOSALS" \
  --project="$PROJECT" \
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
```

`objectCreator` is doing real work here. `mo-analyst@` cannot read back, replace or delete a
bundle it has written, so a duplicate write — from a double-triggered scheduler run —
**fails** rather than silently replacing the first one.

**2. CI ingestion, and the path allowlist.** The allowlist is enforced **at ingestion,
before CI**, so [05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §10's "the gate
cannot be part of what it gates" is enforced twice. A bundle whose diff touches anything
outside this list is rejected and never becomes a pull request:

```
config/ladder.yaml
config/playbooks/**
config/prompts/**
config/catalogue/**
platform/wall-e/mo/**
platform/wall-e/ladder-state.md
```

The ceiling module, the policy chain, the catalogue's risk tiers and the validator itself
are **unreachable by construction** — Mo may not propose changes to its own gating layer.
Ingestion also strips the `narrative` field before validation and renders it into the
pull-request body under a fixed heading, "Mo's reading — advisory, not evidence; CI ignores
this block".

**3. The validator's recompute check**, a required check on the config repository, owned by
the custodian, deployed by digest. It:

- re-executes the evidence block's SQL at its pinned `sql_commit_sha` against `walle_audit`
  and refuses the merge if **any** value differs;
- re-draws the blind sample from the published `week_seed` and refuses if the membership
  differs;
- refuses any bundle citing a `scorecard_sha256` that `mo-metrics@` never published, or a
  `snapshot_name` that does not exist;
- refuses every promotion whose `walle_metrics` watermark is older than **24 hours**;
- enforces every §10 gate — the decision-file link, the ceiling, the second named approver
  for `WRITE_HIGH`, the override-incident reference, the §6 dwell rule and drill freshness
  within 30 days;
- enforces the **two distinct authenticated approving reviewers**, neither of whom authored
  the pull request, matched against the decision file's `Approvers:` line (C17);
- refuses a change to a pinned selection query, `uses` list or scope, for a playbook serving
  a cell above L2, that carries no linked decision record (C15);
- refuses `redesign_required` where two demotions in 90 days have set it;
- refuses a pull request touching more than one of `ladder.yaml`, `config/metrics/*.sql`,
  `gates.yaml`, the ceiling module, the policy chain, the catalogue risk tiers and the
  validator (change 13);
- refuses an L3→L4 `WRITE_HIGH` promotion whose decision file lacks the "Why worth it" line
  (C34).

The authoritative list, with each gate's source and refusal, is
[04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) §3.4; this is the build-order
restatement of it.

It reads `walle_audit` directly. It **never reads `walle_metrics`** — a validator that read
Mo's own output would be checking Mo against Mo. That exclusion is denial test **MD-9**.

The validator's identity needs its own `READER` entry on `walle_audit`, granted the same way
Mo-2's were, and it must appear **nowhere** on `walle_metrics`.

**4. Branch protection.** Two distinct authenticated reviewers, neither the author, and
**admin bypass disabled and audited** ([M-7 · 48](08-open-decisions.md)). The validator reports
the setting it observes and cannot enforce it; a repository where an administrator can
bypass protection turns the two-reviewer rule into decoration.

**Verify.** Denial tests **MD-5**, **MD-6**, **MD-7** and **MD-9** below, plus one end-to-end
dry run: assemble a bundle by hand for a cell the scorecard reports `not_ready`, drop it,
and confirm CI opens a pull request whose validator check **fails** with the reason named.
A validator that has only ever passed has not been tested.

**Rollback.**

```bash
gcloud storage buckets delete "$MO_PROPOSALS"    # only after the bucket is empty
```

Remove the required check and the ingestion workflow. Rolling this back returns the
programme to arguing promotions from hand-run queries, which is where S0 started and is a
working fallback — see the acceptance test's stated fallback in
[05-staging.md](05-staging.md).

---

## Phase Mo-10 — The linked Spans dataset (S3)

Staged to S3 because M38 binds `strong` and names Mo specifically. **The link is created
once, by a human holding `roles/observability.editor`, and never by Mo.** Mo holds that role
at no stage.

`gcloud` 563.0.0 or later is required.

```bash
gcloud beta observability buckets datasets links create \
  "projects/${PROJECT}/locations/${REGION}/buckets/_Trace/datasets/Spans/links/walle_spans" \
  --dataset=Spans \
  --bucket=_Trace \
  --location="$REGION" \
  --project="$PROJECT"
```

This initiates a long-running operation, and audit logs record both the request and the
completion. `mo-metrics@` then needs `roles/bigquery.dataViewer` on the resulting linked
dataset to join `_AllSpans` on `invocation_id` and, through `runs`, on `trace_id`. That
grant is carried in [02-identity-and-access.md](02-identity-and-access.md) §2.1 as an S3-only
row, because it widens `mo-metrics@`'s read surface by one dataset of trace data and should
not be read as part of the S0 grant set.

**Cloud Trace sinks to BigQuery are deprecated since 2026-02-18** and are deliberately not
designed around. The linked dataset is the supported route.

**Verify.**

```bash
bq ls --format=prettyjson "${PROJECT}:walle_spans" | head
bq query --use_legacy_sql=false --project_id="$PROJECT" \
  'SELECT COUNT(*) FROM `walle_spans._AllSpans` WHERE start_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)'
```

**Rollback.** Delete the link. Token spend, tool-call counts and per-invocation latency
become uncomputable; nothing else changes, and no cell's verdict depends on them.

---

## Phase Mo-11 — `mo-narrator@` (S4, optional)

**It is legitimate never to execute this phase.** Cutting T2 entirely is a defensible
reading of this design — denying the narrator every free-text string is what makes it safe
and also makes its prose thin. Decide on the S4 entry record ([M-8 · 49](08-open-decisions.md)).

Deliberately **not** a reasoning engine: an Agent Runtime engine would buy an immutable
`identity_type=AGENT_IDENTITY` and a `discoveryengine.serviceAgent` blast-radius problem
(M52) that a Cloud Run job calling `generateContent` does not have.

```bash
gcloud iam service-accounts create mo-narrator --project="$PROJECT" \
  --display-name="Mo T2 — prose only. Computes nothing, selects nothing, grades nothing."

gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_MO_NARRATOR}" --role=roles/aiplatform.user

# dataViewer on the AGENT-FACING VIEWS ONLY. Never on walle_metrics as a whole,
# never on walle_audit, never on the archive.
bq add-iam-policy-binding \
  --member="serviceAccount:${SA_MO_NARRATOR}" \
  --role=roles/bigquery.dataViewer \
  "${PROJECT}:walle_metrics.v_cell_public"

gcloud run jobs create mo-narrator \
  --image="${MO_AR}/mo-narrator@sha256:<digest>" \
  --region="$REGION" \
  --service-account="$SA_MO_NARRATOR" \
  --task-timeout=900s \
  --max-retries=1 \
  --set-env-vars="PROJECT=${PROJECT},REGION=${REGION},MODEL_ID=<pinned-model-id>"
```

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

**Verify.** Denial test **MD-1**. Then confirm the output contract: the narrator's block is
closed-schema, any `mo_schema_violation` is counted, and **any occurrence disables the
renderer until a human reviews it**. A malformed or steered output must be loud, not
silently dropped.

**Rollback.**

```bash
gcloud run jobs delete mo-narrator --region="$REGION" --quiet
gcloud iam service-accounts delete "$SA_MO_NARRATOR" --project="$PROJECT" --quiet
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
| MD-1 | `mo-narrator@` selects a raw column: `SELECT params_redacted FROM walle_audit.actions` | **403 accessDenied.** It holds `dataViewer` on the agent-facing views only. Repeat for `result_summary` and for `walle_metrics.scorecard` — the whole table, not the view — which must also fail |
| MD-2 | `mo-analyst@` reads `walle_audit`: `SELECT COUNT(*) FROM walle_audit.actions` | **403 accessDenied.** T1 cannot see the raw evidence it would need to forge a number |
| MD-3 | `mo-analyst@` calls `POST /v1/control/demote` | **403.** `run.invoker` allows the HTTP call; the in-app allowlist refuses the path. Same for `/v1/control/halt`, `/v1/plans/{id}/approve` and `/veto` |
| MD-4 | `mo-analyst@` calls `GET /v1/ladder` | **403.** Mo is not on that allowlist row (M72). Only `GET /v1/plans/{id}` and `GET /v1/runs/{id}` succeed |
| MD-5 | A bundle whose diff touches the **ceiling module** is written to the drop box | **Rejected at ingestion, before CI.** No pull request is created. Repeat for the policy chain, the catalogue's risk tiers and the validator |
| MD-6 | A bundle citing a `scorecard_sha256` that `mo-metrics@` never published | **Rejected at ingestion.** Closes the "cite evidence that does not exist" path before the recompute even runs. Repeat with a `snapshot_name` that does not exist |
| MD-7 | A bundle whose `evidence_block` value differs from what the SQL returns when re-run at its pinned commit | **Merge refused by the validator.** A forged promotion has to be *true* to pass |
| MD-8 | `mo-analyst@` writes a bundle to an object name that already exists; then reads back an object it wrote; then deletes one | **Fails, three times.** `roles/storage.objectCreator` "does not give permission to view, delete, or overwrite objects", so a double-triggered run duplicates nothing and Mo cannot retract a bundle after dropping it |
| MD-9 | Each of the five enforcement identities [02-identity-and-access.md](02-identity-and-access.md) §5 names reads `walle_metrics`: `walle-actions@`, `walle-dispatcher@`, the ladder deploy tool, `eve-controller@`, the CI gate validator. Run `walle-agent@` as a sixth for completeness — it is not on the assertion's list, and it should fail too | **403 accessDenied**, five times for the assertion and once more for `walle-agent@`. This is the mechanism behind [M-1 · 42](08-open-decisions.md) and change 15, and the only thing that turns Mo's containment from a claim into a test |
| MD-10 | Any Mo identity attempts `secretmanager.versions.access` on any secret | **403 at Google**, three times. Mo holds no Secret Manager grant anywhere, at any phase |
| MD-11 | A `walle_metrics.scorecard` row with `verdict='ready'` and `n_decided = 34` is inserted into a scratch copy and the assertion query is run | **The job fails.** The floor and the gate are one decision |
| MD-12 | A published artefact is searched for an email-shaped string, and for any group-by cell with a count of 1 to 4 | **Zero matches**, both times |

The two shapes every test above uses:

```bash
# BigQuery, as a named service account
as_sa () {   # as_sa <service-account-email> <sql>
  TOKEN="$(gcloud auth print-access-token --impersonate-service-account="$1")"
  curl -s -o /dev/stderr -w '%{http_code}\n' -X POST \
    -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' \
    "https://bigquery.googleapis.com/bigquery/v2/projects/${PROJECT}/queries" \
    -d "$(python3 -c 'import json,sys;print(json.dumps({"query":sys.argv[1],"useLegacySql":False}))' "$2")"
}

as_sa "$SA_MO_NARRATOR" 'SELECT params_redacted FROM `walle_audit.actions` LIMIT 1'   # MD-1
as_sa "$SA_MO_ANALYST"  'SELECT COUNT(*) FROM `walle_audit.actions`'                  # MD-2
as_sa "$SA_ACTIONS"     'SELECT COUNT(*) FROM `walle_metrics.scorecard`'              # MD-9
as_sa "$SA_DISPATCH"    'SELECT COUNT(*) FROM `walle_metrics.scorecard`'              # MD-9
as_sa "$SA_EVE"         'SELECT COUNT(*) FROM `walle_metrics.scorecard`'              # MD-9

# the action service, as a named service account
call_actions () {   # call_actions <service-account-email> <method> <path>
  ID_TOKEN="$(gcloud auth print-identity-token \
    --impersonate-service-account="$1" --audiences="$ACTIONS_URL")"
  curl -s -o /dev/stderr -w '%{http_code}\n' -X "$2" \
    -H "Authorization: Bearer ${ID_TOKEN}" "${ACTIONS_URL}$3"
}

call_actions "$SA_MO_ANALYST" POST /v1/control/demote    # MD-3, expect 403
call_actions "$SA_MO_ANALYST" GET  /v1/ladder            # MD-4, expect 403
call_actions "$SA_MO_ANALYST" GET  /v1/runs/<known-id>   # expect 200
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
| 2 | Review and merge `config/metrics/gates.yaml` under `ladder.yaml`'s reviewers, in a pull request that does **not** also touch `ladder.yaml` | Mo-3 | M29, and change 13: a metric change must cost its own reviewed pull request and cannot promote anything in the same breath |
| 3 | Review the ~12 metric SQL files, checking specifically that no free-text column is selected and every query prunes to its window | Mo-4 | The exclusion of `params_redacted`, `result_summary` and error text is enforced by the query text and by this review, and by nothing else |
| 4 | Hold `bigquery.transfers.update` and Service Account User on `mo-metrics@` when creating each transfer config | Mo-4 | Required to pin the query to a service account rather than to your own credentials |
| 5 | Paste the Monitoring notification channel resource name into the policy file before creating it | Mo-7 | An alert policy with no channel is a dashboard |
| 6 | Pause the metric transfer configs and confirm the **absence** condition fires, then resume in the same sitting | Mo-7 | The failure this alert exists to catch produces no data points at all; testing the threshold branch proves nothing |
| 7 | Set the artefact reader list to `walle-operators@` and the ladder owner, and exclude `platform/wall-e/mo/**` from the wiki's Drive sync | Mo-8 | [M-3 · 44](08-open-decisions.md). `walle_metrics` has a wider reader set than `walle_audit`, over data derived from personal data |
| 8 | Commit `config/metrics/graders.yaml`, and **name the second grader before S2 entry** | Mo-8 | [M-4 · 45](08-open-decisions.md). Mo cannot supply a person, and a `WRITE_HIGH` cell cannot pass L2 without one |
| 9 | Record Mo as a processor in the data-protection assessment, and correct weakness 11 rather than inheriting it | Mo-8 | T0 reads per-person rows. The claim that Mo's reads are aggregated per organisational unit is false at the pipeline layer |
| 10 | Name the validator custodian ([decision 37](../wall-e/09-open-decisions.md)) and hand them the recompute check | Mo-9 | The gate cannot be part of what it gates. Roughly 3 days of Mo-9 are theirs |
| 11 | Disable and audit admin bypass on branch protection; require two distinct authenticated reviewers, neither the author | Mo-9 | [M-7 · 48](08-open-decisions.md). The validator reports the setting it observes and cannot enforce it |
| 12 | Create the linked Spans dataset once, holding `roles/observability.editor` | Mo-10 | Mo holds that role at no stage |
| 13 | Decide at the S4 entry record whether `mo-narrator` is built at all, and against which pinned model id | Mo-11 | [M-8 · 49](08-open-decisions.md). Not building it is a defensible reading of this design |
| 14 | Grade `max(10 %, 5 items/week)` of executing items, blind, weekly, indefinitely — plus 20 % double-graded for `WRITE_HIGH`, plus adjudication | From S2 | Roughly **one hour a week from a named human who is not the playbook owner**. It cannot be automated, cannot be sampled more thinly without the cell going `not_ready`, and cannot be delegated to a model without destroying the thing it measures |

Step 14 is not a build step and it is the one that decides whether any of the rest matters.
If nobody grades, the worklist goes ungraded, `n` never reaches 35, and no cell is ever
promotable — with everything above working perfectly. Mo reports grading coverage in the
digest **and in the monthly cost report, beside the hours it costs**, so a stalled programme
looks stalled on human attention rather than on safety.

---

## What this runbook forces on Wall-E's own set

Each of these is a change to a file outside this directory, listed with its target and its
reasoning in [08-open-decisions.md](08-open-decisions.md). They are repeated here only as
the build order needs them.

| Before | Change | # | Target |
|---|---|---|---|
| Mo-4 | Write-ahead `grades`, `proposal_verdicts`, `drills`; new table `ladder_events`; `actions.noop`; the four missing fingerprint columns; the `approvals` per-item vector; the `capability_gap` enum; the canonical plan serialisation spec | 1, 2, 4, 5, 6, 7, 8 | [03-lld.md](../wall-e/03-lld.md), SETUP Phase 7 |
| Mo-2 | The BigQuery grants for Mo's three service accounts, the two new datasets, and the authorised-view registration | 3 | SETUP Phases 7 and 13b, `walle_setup.py` `add_dataset_access` |
| Mo-6 | Correct the Mo identities row and item 6 from "never call the action service" to "**the two read endpoints only**"; remove `walle-events` "subscribe" for Mo | 9, 10 | [08-team-eve-mo.md](../wall-e/08-team-eve-mo.md), [ARCHITECTURE](../wall-e/ARCHITECTURE.md) |
| Mo-6 | Record `MO_PRINCIPAL = serviceAccount:mo-analyst@${PROJECT}.iam.gserviceaccount.com` | 12 | `setup/walle.env.example`, [PREREQUISITES](../wall-e/PREREQUISITES.md) items 11 and 13 |
| Mo-7 | A Phase 16 monitoring row for the `walle_metrics` freshness watermark, as an **absence** condition | 14 | SETUP Phase 16, [06-security-guardrails.md](../wall-e/06-security-guardrails.md) |
| Mo-8 | Correct weakness 11's claim that Mo's reads are aggregated per organisational unit, and record Mo as a processor | 11 | [ARCHITECTURE](../wall-e/ARCHITECTURE.md) §11 |
| Mo-9 | Extend §10 so one pull request may not touch more than one of `ladder.yaml`, `config/metrics/*.sql`, `gates.yaml`, the ceiling module, the policy chain, the catalogue risk tiers and the validator | 13 | [05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §10 |
| Mo-12 | The denial-suite row asserting that **no enforcement identity holds read on `walle_metrics`** | 15 | SETUP §4 |
| Before S2 | Note that a second **grader** is needed by S2, not S3 | 16 | [05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md) §7, decision 11b |
| — | Two new SETUP phases, "Mo — metrics" at Stage 0 and "Mo — reporting" at S1 | 17 | SETUP. No Mo phase exists at all today |

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
- [../wall-e/SETUP.md](../wall-e/SETUP.md) — the runbook these two phases are written to be lifted into
- [../eve/07-build-runbook.md](../eve/07-build-runbook.md) — Eve's equivalent, and the source of `SA_EVE`'s real address
