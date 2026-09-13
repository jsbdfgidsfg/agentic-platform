# 7. Eve onboarding

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Last executed: **never**
- **Objective restated 2026-09-13; see the platform HLD**
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.2–§13.3; this runbook
  carries §18 items 13, 14, 15 and 17; owner the Eve owner; gates the super-admin grant and
  Wall-E's Stage 1, P143). Added: a pre-grant **observe-and-report sitting** (Phase 10b) — the
  Reports API poll, the detection catalogue, the roster check, the evidence heartbeat, the
  reporting contract, `eve-export@` and the daily export to the witness; the six-stream sink
  (Phase 7); the widened read set (Phase 8); the `eve_quality` dataset with dataset-level
  `READER` to `mo-metrics@` and the validator custodian **made by this runbook**;
  `eve.incidents` and `eve.seeded_fault_runs`; the HSM protection level on `eve-approval`
  (Phase 11). The "no `userByEmail` entry for `mo-metrics@` on `eve` — ever" check is narrowed
  to the non-quality datasets. `grades_eve` is written by the platform approval surface, not by
  anything this runbook builds. Qualified 2026-09-13 (review-findings pass): its dataset is
  proposed as `eve_grades` in `VALIDATOR_PROJECT`, made by the validator custodian, with no
  Eve grant (topology rows 45–46, [09-open-decisions.md](09-open-decisions.md) E-21).

## When to use this

To bring each of Eve's stages into existence, in order, runnable by one person. It is
three separate sittings separated by months, not one build:

| Sitting | Stage | Phases | What exists afterwards |
|---|---|---|---|
| **Eve v0** | S0 | 1 to 6 | Eve's GCP project, one service account, the `eve` dataset, twelve scheduled queries and one absence alert. **No robot account, no OAuth client, no token, no secret, no KMS key, no allowlist entry, no Eve process.** |
| **The sink** | S2 | 7 | Eve's own organisation-level admin-log sink, writing into Eve's project. Still no Eve process. |
| **Eve onboarding** | S3 entry | 8 to 10 | `eve@<domain>`, three GCP service accounts, the secrets, the locked evidence bucket, `eve/config`, `eve-reconciler`, `eve-console`. Eve can **halt and demote**. Eve cannot sign. |
| **Eve gates** | S4 entry | 11 | The `eve-approval` KMS key (HSM), its PEM exported before first use, `eve-gate`, and Wall-E's side of the change. Eve can sign an approval for cells marked `eve_authority: binding`. |
| **Observe-and-report** (added 2026-09-13) | **Before Wall-E's super-admin grant**, at whatever stage that falls | 7 (widened), 8, 9, the jobs and schedules of 10, then 10b | `eve@` with the widened read set, the six-stream sink, the Reports API poll, the detection catalogue, the roster check, the evidence heartbeat, `eve.incidents` and paging, `eve-export@` and the witness push, `eve_quality`. Eve can **halt** on the tenant-integrity class, `reconciliation_gap` and `log_pipeline_silent`, and report. Eve cannot sign. If the grant comes after S3 entry, Phase 10b is simply added to that sitting. |

Phase 12 is not a stage. It is the two things that must be true at every stage: the
teardown guard, and the denial suite Eve's side authors.

**Nothing in phases 1 to 7 gates anything** (qualified 2026-09-13: unless the super-admin grant
is due, in which case the observe-and-report sitting above halts and reports before any ladder
stage asks it to). Eve v0 is scheduled queries a human reads
weekly. Executing phases 1 to 6 changes no autonomy level, consumes no Workspace licence
and grants no credential. That is deliberate: through S2 the pilot carries no dormant Eve
credential, no unused key and no allowlist entry, so an Eve that is never built costs
nothing to abandon.

**And the decision to abandon is legitimate.** L3 with human approval is a legitimate
permanent end state. None of phases 8 to 11 should be executed until an L3→L4 promotion
can state in numbers how much approval burden it avoids.

## Prerequisites

### Decisions that must be closed before the phase that needs them

| Decision | Needed before | If unanswered |
|---|---|---|
| [E-1](09-open-decisions.md) — does Eve get its own GCP project? | Phase 1 | **Answered yes 2026-09-13**: four projects — `GEMINI_PROJECT`, `WALLE_PROJECT`, `EVE_PROJECT`, `MO_PROJECT` — under `FOLDER_ID` ([../project-topology.md](../project-topology.md); decision file *tbd*). The single-project variant is history. Every cross-project grant below is either made by Wall-E's runbook on a Wall-E resource and verified here, or made here on an Eve resource; the topology page is the authority for which is which. |
| [E-14](09-open-decisions.md) — retention floor **and** ceiling | Phase 3 | Eve's mirror and bucket are set to 400 days pending it. A locked bucket retention period can be lengthened later but **never** shortened, so a wrong answer here is expensive in one direction only. |
| [E-16](09-open-decisions.md), which depends on [decision 26](../wall-e/09-open-decisions.md) | Phase 8 | If a keyless service account can hold a custom admin role with no domain-wide delegation, then Eve's robot account, its consent, its hardware key, its refresh token and the six-month clock all disappear and Phase 8 is mostly deleted. Re-examine before executing it, not after. |
| [E-18](09-open-decisions.md) — the threshold numbers | Phase 10 | `thresholds.yaml` is stubbed from Phase 4 so v0 and the controller read the same values, but the numbers are calibrated on measured data at S2. Wiring a control call to an uncalibrated threshold is how a buggy Eve halts the programme during the stage the programme is trying to prove itself. |
| [E-13](09-open-decisions.md) — the second grader | Before the S3 exit gate | No `WRITE_HIGH` cell reaches `eve_authority: binding` without one. |
| [E-3](09-open-decisions.md) — `items_hash` in the signed field list | Before Wall-E's approve endpoint is built | Retrofitting a signed field means re-issuing every stored approval. |
| [E-2](09-open-decisions.md) — the second human outside the Wall-E line (added 2026-09-13) | The observe-and-report sitting | Reopened as blocking for the super-admin grant: without that person there is no witness administrator, no parallel recipient and no sole recipient for reports about the administrator. |
| P14 — the witness organisation's domain, edition and billing (IT security; added 2026-09-13) | Phase 10b | Without the witness the push has no destination and the absence alarm lives only inside the tenant's organisation, which a super admin can reach. |
| P17 — Workspace BigQuery export into the witness (added 2026-09-13) | Eve S2 | If yes, a dataset in `EVE_WITNESS_PROJECT` and a severity-1 rule on the export's "turned off" event; if no, the SecOps export stays the only copy of Gmail and the streams Cloud Logging never receives. |
| P34 and P19 — the reporting path and its AI Act class (added 2026-09-13) | Phase 10b's `eve-advisor` step | Without P34 no `eve-advisor` build; without P19 it may not page. The rest of Phase 10b does not wait. |
| P30 — the validator custodian's `READER` on `eve_quality` (added 2026-09-13) | Phase 10b | Without it Eve-targeting bundles stay advisory `incident_note` only. |

### Access you need, and where to get it early

| What | Where | Phase | Lead time |
|---|---|---|---|
| `roles/resourcemanager.projectCreator` on `FOLDER_ID` — the folder that holds `GEMINI_PROJECT`, `WALLE_PROJECT`, `EVE_PROJECT` and `MO_PROJECT` — plus billing-account user | Folder, billing account | 1 | Same day |
| Read access in `WALLE_PROJECT` (`roles/viewer`, `run.viewer`, `bigquery.metadataViewer`, `secretmanager.secrets.getIamPolicy`) and `discoveryengine.viewer` in `GEMINI_PROJECT`, as the human owner | Wall-E's and the Gemini app's projects | 2, 9 | Same day while one person owns all four; a request to each owner group once [E-2](09-open-decisions.md) lands. The verify blocks that read another project say so. |
| **Organisation-level `roles/logging.configWriter`** | Organisation | 7 | **Allow calendar time.** Workspace audit logs land at organisation level, so a project-level sink cannot see them. This is the one step in Eve's build that needs someone else's approval, and it is the step that must happen *early* — see Phase 7. |
| Workspace super admin | Tenant | 8 | Same day |
| One spare Workspace licence for `eve@<domain>` | Tenant | 8 | `Assumption:` seats are available without a purchase order. This is the largest recurring cost line in Eve. |
| A clean browser profile, signed into nothing | Your machine | 8 | — |
| `gcloud`, `bq`, `python 3.12`, `openssl` | Your machine | all | — |

### Set these once per shell

```bash
# ---- Eve's own names -------------------------------------------------------
export EVE_PROJECT="<eve-project-id>"
export FOLDER_ID="<folder-id>"                   # the one folder all four projects sit under
export REGION="europe-west1"
export BQ_LOCATION="EU"
export ORG_ID="<org-id>"
export DOMAIN="<primary-domain>"

export EVE_ROBOT="eve@${DOMAIN}"
export SVC_OU="/Automation/Service Identities"
export OPERATORS="walle-operators@${DOMAIN}"
export PROTECTED="walle-protected@${DOMAIN}"

# ---- Wall-E's, from SETUP.md section 1.7 -----------------------------------
# Wall-E's project. SETUP.md and walle_setup.py call it PROJECT; it is WALLE_PROJECT
# everywhere else (../project-topology.md section 6).
export WALLE_PROJECT="<walle-project-id>"
export SA_ACTIONS="walle-actions@${WALLE_PROJECT}.iam.gserviceaccount.com"
# Wall-E's CI identity: the value of Wall-E's CI_DEPLOYER config key, a full service
# account email in WALLE_PROJECT (../wall-e/PREREQUISITES.md section 2, owner tbd there).
# Not invented here: copy it from Wall-E's config. Used in Phase 9.
export SA_WALLE_CI="<ci-deployer-service-account>"

# ---- The Gemini Enterprise app's project, for Phase 9 check 4 only -----------
export GEMINI_PROJECT="<gemini-project-id>"

# ---- Mo's project, for Phase 11's one Mo carve-out only (topology row 18) -----
# mo-metrics@ lives in MO_PROJECT, created by Mo's runbook (Mo-2); it appears here
# only as the grantee of a dataset-level READER on the mirror's dataset, from S4.
export MO_PROJECT="<mo-project-id>"
export SA_MO_METRICS="mo-metrics@${MO_PROJECT}.iam.gserviceaccount.com"
export EVE_MIRROR_DS="eve_audit_mirror"    # renamed 2026-09-13 from the Assumption eve_mirror, which is the witness dataset's name (topology decision 51, row 32). Phase 11.

# ---- derived ---------------------------------------------------------------
export SA_EVE_V0="eve-v0@${EVE_PROJECT}.iam.gserviceaccount.com"
export SA_EVE="eve-controller@${EVE_PROJECT}.iam.gserviceaccount.com"
export SA_EVE_VERIFIER="eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com"
export SA_EVE_CONSOLE="eve-console@${EVE_PROJECT}.iam.gserviceaccount.com"

export EVE_EVIDENCE="gs://${EVE_PROJECT}-eve-evidence"
export EVE_KEYS="${EVE_EVIDENCE}/keys"     # a prefix, not a second bucket. See Phase 11.
export EVE_AR="${REGION}-docker.pkg.dev/${EVE_PROJECT}/eve"
export EVE_RECEIPTS_DS="eve_receipts"      # Assumption: name tbd, topology decision 48. Phase 11.

# ---- added 2026-09-13, platform HLD section 13.2-13.3; Phase 10b ------------------
export EVE_ADVISOR_PROJECT="<eve-advisor-project-id>"   # under fld-controllers
export EVE_WITNESS_PROJECT="<witness-project-id>"       # in org-witness, P14; IT security
export SA_EVE_EXPORT="eve-export@${EVE_PROJECT}.iam.gserviceaccount.com"
export SA_EVE_ADVISOR="eve-advisor@${EVE_ADVISOR_PROJECT}.iam.gserviceaccount.com"
export SA_VALIDATOR="<validator-custodian-service-account>"   # VALIDATOR_PROJECT; tbd there
export EVE_QUALITY_DS="eve_quality"
export EVE_ADVICE_DS="eve_advice"
export EVE_ADVISOR_VIEWS_DS="<advisor-views-dataset>"   # name tbd (HLD section 18 item 25)

echo "EVE_PROJECT=$EVE_PROJECT WALLE_PROJECT=$WALLE_PROJECT FOLDER_ID=$FOLDER_ID REGION=$REGION DOMAIN=$DOMAIN"
```

Filled in as later phases produce them:

```bash
export EVE_PROJECT_NUMBER=""      # Phase 1
export EVE_TOKEN_VERSION=""       # Phase 8, the number Eve's bootstrap prints
export EVE_CONSOLE_URL=""         # Phase 10
export EVE_KEY_VERSION=""         # Phase 11, the full resource name
```

Save both blocks to `~/.eve-env` and `source` it at the start of every session, with the
same guard Wall-E's runbook uses, because the build spans months rather than a week:

```bash
[ -n "$EVE_PROJECT" ] || { echo 'env not sourced'; return 1; }
```

**`SA_EVE` and Wall-E's runbook.** Before 2026-09-13 [SETUP.md](../wall-e/SETUP.md)
section 1.7 fixed `SA_EVE = eve-controller@${PROJECT}`, in Wall-E's project; since
2026-09-13 both runbooks agree on `eve-controller@${EVE_PROJECT}`. That single change
propagates into `CONTROL_CALLER_ALLOWLIST`, `READ_CALLER_ALLOWLIST` and `EVE_KMS_KEY`
(`EVE_PROJECT_ROLES` is empty since 2026-09-13 and carries nothing), and it is CC-25 in
[08-contract-changes.md](08-contract-changes.md).
**If Wall-E's script has not yet landed CC-25, do not execute Phase 9**, or you will end up
with two `eve-controller@` accounts and a service pointed at the wrong one.

---

## Stage 0 — Eve v0

### Phase 1 — Eve's GCP project

**Why a separate project.** While the signing key lives in Wall-E's project, a project
owner there can grant themselves `roles/cloudkms.signer` and mint an Eve approval, and the
only control is a daily drift row — a detective control on the artefact the entire
controller role rests on. A project boundary makes it structural. It is also what keeps
Eve's evidence copy outside Wall-E's teardown blast radius.

```bash
# --folder, not --organization: the project must be a child of the folder the other three
# share, or it inherits nothing from the folder floor and its IAM (verified 2026-09-13,
# https://docs.cloud.google.com/sdk/gcloud/reference/projects/create — "--folder: ID for
# the folder to use as a parent"). Nothing below moves it afterwards.
gcloud projects create "$EVE_PROJECT" --folder="$FOLDER_ID"
gcloud billing projects link "$EVE_PROJECT" --billing-account="<billing-account>"
gcloud config set project "$EVE_PROJECT"

gcloud services enable \
  bigquery.googleapis.com bigquerydatatransfer.googleapis.com \
  logging.googleapis.com monitoring.googleapis.com \
  --project="$EVE_PROJECT"

export EVE_PROJECT_NUMBER="$(gcloud projects describe "$EVE_PROJECT" \
  --format='value(projectNumber)')"
```

Only three APIs at S0. `run`, `cloudkms`, `secretmanager`, `storage`, `firestore`,
`iap` and `artifactregistry` are enabled in phases 9 to 11, when something uses them.
`aiplatform.googleapis.com` is **never** enabled in Eve's project, at any stage — that is
enforcement 2 of the deterministic boundary, and it is cheapest to keep true by never
turning the API on.

**Verify.**

```bash
gcloud services list --enabled --project="$EVE_PROJECT" --format='value(config.name)'
# expect exactly: bigquery, bigquerydatatransfer, logging, monitoring
# (plus the always-on cloudapis/storage-api entries Google adds itself)

# aiplatform must be absent, now and at every later phase
gcloud services list --enabled --project="$EVE_PROJECT" \
  --format='value(config.name)' | grep -c '^aiplatform.googleapis.com$'
# expect: 0

# added 2026-09-13 (platform HLD CP5): the project-level restrictServiceUsage denylist,
# set by the factory on EVE_PROJECT itself (never on fld-controllers, whose other child,
# EVE_ADVISOR_PROJECT, needs the API). Eve's runbook verifies it; it does not set it.
gcloud org-policies describe gcp.restrictServiceUsage --project="$EVE_PROJECT" --effective
# expect: a denied value aiplatform.googleapis.com. Absent = stop; report to the platform owner.
```

Then assert the property that the whole project boundary exists for — that Wall-E's
deployers hold nothing here. A project-level read does **not** show bindings inherited from
the folder, so read the folder policy too (`gcloud resource-manager folders get-iam-policy`,
verified 2026-09-13,
https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/folders/get-iam-policy):

```bash
gcloud projects describe "$EVE_PROJECT" --format='value(parent.type,parent.id)'
# expect: folder  <FOLDER_ID>

for M in "$SA_ACTIONS" "$SA_WALLE_CI" "<walle-deployer-group>"; do
  gcloud projects get-iam-policy "$EVE_PROJECT" \
    --flatten='bindings[].members' \
    --filter="bindings.members:${M}" --format='value(bindings.role)'
  gcloud resource-manager folders get-iam-policy "$FOLDER_ID" \
    --flatten='bindings[].members' \
    --filter="bindings.members:${M}" --format='value(bindings.role)'
done
# expect: nothing, for every principal, at both levels. The deployer group's name comes
# from Wall-E's set (walle-owners@ per ../project-topology.md decision 52); it is tbd there.
```

**Rollback.** `gcloud projects delete "$EVE_PROJECT"`. Nothing outside the project has
changed. Note that a project id can never be reused, so a rebuild needs a new name, and
that this stops being a clean rollback from Phase 7 onward, when an organisation-level sink
exists.

---

### Phase 2 — `eve-v0@` and the two dataset grants

**Why a pinned service account and not your own credentials.** BigQuery scheduled queries
run as *the user with the credentials associated with the client* unless a service account
is named ([Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries),
verified 2026-09-12). An evidence series that runs as the person who administers Wall-E is
not independent, and it dies when they leave.

```bash
gcloud iam service-accounts create eve-v0 --project="$EVE_PROJECT" \
  --display-name="Eve v0 scheduled queries"

# query jobs run in EVE's project, so the job-creation cost and quota never touch Wall-E's
gcloud projects add-iam-policy-binding "$EVE_PROJECT" \
  --member="serviceAccount:${SA_EVE_V0}" --role=roles/bigquery.jobUser

# the transfer config runs AS this account; the human creating the config must be allowed
# to attach it. actAs, not token minting — see the note below.
gcloud iam service-accounts add-iam-policy-binding "$SA_EVE_V0" \
  --project="$EVE_PROJECT" \
  --member="user:$(gcloud config get-value account)" \
  --role=roles/iam.serviceAccountUser
```

**`serviceAccountUser`, resource-scoped, and never `serviceAccountTokenCreator`.** Verified
2026-09-12: `roles/iam.serviceAccountUser` is the role that "lets a principal attach a
service account to a resource" through `iam.serviceAccounts.actAs`, while
`roles/iam.serviceAccountTokenCreator` carries `getAccessToken`, `getOpenIdToken`,
`signBlob`, `signJwt` and `implicitDelegation` and **not** `actAs`
([Service account permissions](https://docs.cloud.google.com/iam/docs/service-account-permissions));
BigQuery names the former outright — "`iam.serviceAccountUser` to assign a service account
to a scheduled query" ([Scheduling
queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries)). The
token-creator grant is not merely insufficient, it is worse than nothing: it would leave a
standing impersonation path into the evidence identity for a human who only ever needed to
point a config at it. The binding is on the **service account resource**, never at project
level.

**It will look redundant on the first build.** Cloud Scheduler's own documentation notes
that whoever created the service account is already granted `actAs` ([HTTP target
auth](https://docs.cloud.google.com/scheduler/docs/http-target-auth)), and the operator who
just ran `gcloud projects create` holds `roles/owner`, which carries it too. These grants
are written for the [E-2](09-open-decisions.md) `eve-owners@` handover, when the person
re-pointing a transfer config or re-creating a schedule is no longer the person who created
the account. The same grant is made on `$SA_EVE_VERIFIER` in Phase 10 and on `$SA_EVE` in
Phase 11, for the same reason.

The read grant on Wall-E's audit dataset is **dataset-level, never project-level** — a
project-level `roles/bigquery.dataViewer` in Wall-E's project would be a lateral path into
it. It sits on a dataset in `WALLE_PROJECT`, so **it is Wall-E's runbook's grant to make**,
not this one's: **provided by Wall-E's runbook at Stage 0 — dataset-level `READER` on
`walle_audit` for `${SA_EVE_V0}`** (CC-22, `walle_setup.py` `add_dataset_access` with member
`eve-v0@${EVE_PROJECT}`; [../project-topology.md](../project-topology.md) §3 row 4). Give
Wall-E's operator the `${SA_EVE_V0}` email, then verify the grant below. For reference,
the edit Wall-E's runbook makes — it needs `bigquery.datasets.update` in `WALLE_PROJECT`,
which no Eve principal holds; `bq add-iam-policy-binding` operates on tables, views and
connections, not datasets, so dataset access is edited through the dataset's own `access`
array:

```bash
# Wall-E's runbook, in WALLE_PROJECT — reference only
bq show --format=prettyjson "${WALLE_PROJECT}:walle_audit" > /tmp/walle_audit.json

SA="$SA_EVE_V0" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/walle_audit.json'))
d.setdefault('access', []).append({"role": "READER", "userByEmail": os.environ['SA']})
json.dump(d, open('/tmp/walle_audit.json', 'w'))
EOF

bq update --source=/tmp/walle_audit.json "${WALLE_PROJECT}:walle_audit"
```

The second grant, `roles/bigquery.dataEditor` on the `eve` dataset, is applied in Phase 3
when the dataset exists.

> **This grant did not exist anywhere in Wall-E's runbook as of 2026-09-12.** The entire
> shared data plane of [08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) was unbuilt. It is
> [E-9](09-open-decisions.md); since 2026-09-13 Wall-E's runbook (CC-22) makes it, keyed on
> `EVE_PROJECT`, and this phase is where it is verified.

**Verify.**

```bash
# Both reads are in WALLE_PROJECT and need viewer permission there (bigquery.datasets.get,
# resourcemanager.projects.getIamPolicy); they are run by the human owner, never by an
# Eve identity.
bq show --format=prettyjson "${WALLE_PROJECT}:walle_audit" \
  | python3 -c "import json,sys;[print(a) for a in json.load(sys.stdin)['access']]"
# expect: eve-v0@ present as READER, and with NOTHING else. No WRITER, no OWNER.

# and prove the negative: eve-v0@ cannot write to Wall-E's audit dataset
gcloud projects get-iam-policy "$WALLE_PROJECT" --flatten='bindings[].members' \
  --filter="bindings.members:${SA_EVE_V0}" --format='value(bindings.role)'
# expect: nothing at all at project level
```

**Rollback.** Ask Wall-E's operator to remove the `access` entry from `walle_audit` the
same way it was added (a `WALLE_PROJECT` edit), and
`gcloud iam service-accounts delete "$SA_EVE_V0"`.

---

### Phase 3 — The `eve` dataset, its tables, and the daily mirror

```bash
bq --location="$BQ_LOCATION" mk --dataset \
  --description="Eve's findings, verdicts, attestations and the off-project audit mirror" \
  "${EVE_PROJECT}:eve"

# 34560000 seconds = 400 days. Assumption: 400 days pending decision E-14.
# incidents and seeded_fault_runs added 2026-09-13 (platform HLD section 13.2-13.3; 03-lld section 9)
for T in findings verdicts attestations review_queue grades_blind pages walle_audit_mirror incidents seeded_fault_runs; do
  bq mk --table \
    --time_partitioning_field=ts \
    --time_partitioning_type=DAY \
    --time_partitioning_expiration=34560000 \
    "${EVE_PROJECT}:eve.${T}" "./schemas/eve_${T}.json"
done
```

Schemas are in [03-lld.md](03-lld.md), as `schemas/eve_<table>.json`. At S0 only `findings`
and `walle_audit_mirror` carry rows — which is why [01-hld.md](01-hld.md) and
[03-lld.md](03-lld.md) date the rest to **S3 entry**; the empty tables are created here so
that the S3-entry sitting adds no DDL to an already long session, and so that the metric 7
query has an axis from S0. Creating an empty table grants nothing and gates nothing.
`review_queue_blind` and `verdict_receipts` are **views**, not tables, created in Phase 10
and Phase 11 respectively.

Grant `eve-v0@` its second grant now that the dataset exists:

```bash
bq show --format=prettyjson "${EVE_PROJECT}:eve" > /tmp/eve.json
SA="$SA_EVE_V0" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/eve.json'))
d.setdefault('access', []).append({"role": "WRITER", "userByEmail": os.environ['SA']})
json.dump(d, open('/tmp/eve.json', 'w'))
EOF
bq update --source=/tmp/eve.json "${EVE_PROJECT}:eve"
```

**The daily mirror.** One scheduled query appending yesterday's `walle_audit` partitions
into `eve.walle_audit_mirror`. It is append-only and it is the reason deleting
`walle_audit` in Wall-E's project — by teardown, by a dataset recreate, or by an attacker —
does not destroy Eve's evidence. It is also what [decision 31](../wall-e/09-open-decisions.md)
asks for.

```bash
bq mk --transfer_config \
  --project_id="$EVE_PROJECT" \
  --location="$BQ_LOCATION" \
  --data_source=scheduled_query \
  --display_name="eve-mirror-walle-audit" \
  --service_account_name="$SA_EVE_V0" \
  --schedule="every day 01:13" \
  --params='{
    "query": "INSERT INTO `'"$EVE_PROJECT"'.eve.walle_audit_mirror` SELECT * FROM `'"$WALLE_PROJECT"'.walle_audit.actions` WHERE DATE(ts) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)"
  }'
```

Repeat for each of the six `walle_audit` tables, or write one query per table into the
mirror's table-per-source layout — whichever [03-lld.md](03-lld.md)'s schema says. **01:13,
not 01:00**: see Phase 4.

**Verify.**

```bash
bq ls --format=prettyjson "${EVE_PROJECT}:eve" | python3 -c \
  "import json,sys;[print(t['tableReference']['tableId'], t['type']) for t in json.load(sys.stdin)]"
# expect the nine tables, all TABLE (seven before 2026-09-13)

bq show --format=prettyjson "${EVE_PROJECT}:eve.walle_audit_mirror" \
  | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['timePartitioning'])"
# expect: type DAY, field ts, expirationMs 34560000000

# after the first run has fired
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT COUNT(*) rows, MAX(ts) newest FROM `eve.walle_audit_mirror`'
```

**Rollback.** `bq rm -r -f -d "${EVE_PROJECT}:eve"` and delete the transfer configs. The
mirror is the only thing here with data that is not reproducible, so take the table's
contents out to the evidence bucket first if you are rolling back after S1.

---

### Phase 4 — The twelve scheduled queries, pinned and off the hour

Ten queries are the ten metrics of [05-autonomy-ladder.md](../wall-e/05-autonomy-ladder.md)
section 8. Two more are Eve v0's own: two-direction reconciliation, and config/ladder
drift.

| # | Query | Source of truth | Note |
|---|---|---|---|
| 1 | Hard-invariant denials | `walle_audit.actions` | Counts **autonomous** runs only. A `protected_principal` denial arising from a **human chat request** is excluded — it is the control working, not an invariant breach. |
| 2 | Plan precision | `walle_audit.plans`, `walle_audit.grades` | Reported with **Wilson interval bounds, not a point estimate** |
| 3 | Verification success | `walle_audit.verifications` | |
| 4 | Breaker trips | `walle_audit.runs` | Distinct `error_class` per run, **excluding no-ops** |
| 5 | Invalid parameters | `walle_audit.actions` | |
| 6 | Run reliability | `walle_audit.runs` | |
| 7 | Eve post-hoc latency | `eve.verdicts` | Empty until S3 entry. The series exists from S0 so the chart has an axis rather than appearing on the day it matters. |
| 8 | Approval latency | `walle_audit.approvals` | |
| 9 | Audit completeness | `eve.walle_audit_mirror` joined to Workspace admin events | Computed from **Eve's own** copy from Phase 7 onward. Until then it reads `walle_audit`, and that limitation is the reason Phase 7 exists at S2 rather than S3. |
| 10 | Drill freshness | `walle_audit.config_versions`, Firestore `drills/{date}` | |
| 11 | Two-direction reconciliation | mirror ↔ admin events | Both directions. A gap either way is a finding. |
| 12 | Config and ladder drift | `walle_audit.config_versions` | Rows whose `config_version` does not match the deployed ladder |

Every one is a 30-day rolling window, evaluated hourly, and every result row carries its
measured value, its threshold, its verdict and the hash of the query that produced it. The
threshold comes from `thresholds.yaml`, which is stubbed from this phase so that v0 and the
controller built at Phase 10 read the same numbers rather than drifting apart in silence.

**Schedule every one of them off the hour.** Google documents that scheduled queries
running exactly on the hour may trigger more than once, which duplicates inserts
([Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries),
verified 2026-09-12). A duplicated metric row is a fabricated data point in the evidence
series a promotion is argued from.

```bash
# one per metric; :07 past the hour, not :00
bq mk --transfer_config \
  --project_id="$EVE_PROJECT" \
  --location="$BQ_LOCATION" \
  --data_source=scheduled_query \
  --display_name="eve-v0-m01-hard-invariant-denials" \
  --service_account_name="$SA_EVE_V0" \
  --schedule="every 1 hours from 00:07 to 23:59" \
  --params="$(python3 - <<'EOF'
import json, pathlib
print(json.dumps({"query": pathlib.Path("sql/m01_hard_invariant_denials.sql").read_text()}))
EOF
)"
```

Keep the SQL in files under `sql/` in Eve's config repository, not inline in the shell —
the query hash stamped on every finding row must be reproducible from a committed artefact,
and a heredoc in a runbook is not one.

**Verify.**

```bash
# 1. every transfer config is pinned to eve-v0@ and none runs as a human.
#    This is the check that makes "a scheduled query silently inherits a departing
#    human's credentials" impossible rather than merely unlikely.
bq ls --transfer_config --transfer_location="$BQ_LOCATION" \
  --project_id="$EVE_PROJECT" --format=prettyjson \
  | python3 -c "
import json,sys
for c in json.load(sys.stdin):
    print(c['displayName'], c.get('serviceAccountName','<<HUMAN CREDENTIALS>>'), c['schedule'])
"
# expect: twelve rows plus the mirror; every one naming eve-v0@; no schedule ending :00

# 2. no schedule lands exactly on the hour
bq ls --transfer_config --transfer_location="$BQ_LOCATION" \
  --project_id="$EVE_PROJECT" --format=prettyjson \
  | grep -c '":00"'
# expect: 0

# 3. rows are actually arriving
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT metric, COUNT(*) n, MAX(ts) newest FROM `eve.findings`
   GROUP BY metric ORDER BY metric'
# expect: twelve metric names (m07 may be zero until S3 entry)
```

CI asserts check 1 on every run. It is one line and it closes a failure mode that is
otherwise invisible until the day someone leaves.

**Rollback.** `bq rm --transfer_config <config-resource-name>` for each. The `findings`
rows already written stay; they are evidence and are not deleted on a rollback.

---

### Phase 5 — The absence alert on the metric series

One alert, and it is an **absence** alert rather than a threshold alert, because the
failure being guarded against is the series stopping, not a value going out of range. A
scheduled query that stops running produces no bad row; it produces no row at all, and a
threshold policy on a missing series fires nothing.

```bash
gcloud logging metrics create eve_v0_transfer_runs \
  --project="$EVE_PROJECT" \
  --description="Completed Eve v0 scheduled-query runs" \
  --log-filter='resource.type="bigquery_dts_config"'
```

Then a `conditionAbsent` policy on it. Write the policy to a file rather than composing it
on the command line, because the absence duration is the load-bearing number:

```bash
cat > /tmp/eve-v0-absence.json <<'EOF'
{
  "displayName": "Eve v0 metric series stopped",
  "combiner": "OR",
  "conditions": [{
    "displayName": "no scheduled-query run in 3 hours",
    "conditionAbsent": {
      "filter": "metric.type=\"logging.googleapis.com/user/eve_v0_transfer_runs\" AND resource.type=\"bigquery_dts_config\"",
      "duration": "10800s",
      "aggregations": [{"alignmentPeriod": "600s", "perSeriesAligner": "ALIGN_COUNT"}]
    }
  }],
  "notificationChannels": []
}
EOF

gcloud monitoring policies create --project="$EVE_PROJECT" \
  --policy-from-file=/tmp/eve-v0-absence.json
```

Add the notification channel for `walle-operators@` with
`gcloud alpha monitoring channels create` and re-run with its id in
`notificationChannels`. Three hours on an hourly series is two missed runs — long enough
not to page on one transient BigQuery error, short enough that a wedged transfer is found
the same working day.

**Verify.** Pause one transfer config, wait out the duration, confirm the alert arrives
where you actually read it, then resume it:

```bash
bq update --transfer_config --disable_auto_scheduling <config-resource-name>
# wait; the alert must arrive
bq update --transfer_config --schedule="every 1 hours from 00:07 to 23:59" <config-resource-name>
```

Record the observed delay. It is the detection latency the whole of Eve v0 depends on, and
an alert nobody has ever seen fire is an assumption, not a control.

**Rollback.** `gcloud monitoring policies delete <policy>` and
`gcloud logging metrics delete eve_v0_transfer_runs`.

---

### Phase 6 — What Wall-E's repository must carry from its first commit

No commands. This phase is a checklist against Wall-E's code, and it belongs here because
Eve is unbuildable if it is skipped and because none of it costs anything to carry
inert. It is roughly five days inside `walle-actions`, scheduled with Wall-E rather than
with Eve. Every item is argued in [08-contract-changes.md](08-contract-changes.md).

| # | In Wall-E's code from the first commit | Inert until |
|---|---|---|
| 1 | The eight endpoint contracts of [08-team-eve-mo.md](../wall-e/08-team-eve-mo.md), `contracts/plan-body.v1.json`, the envelope schema and the `approvals` columns | S4 |
| 2 | **Offline pinned-PEM verification as the primary path**, with a CI-only test key; KMS `getPublicKey` as fallback only | S4 |
| 3 | The reason-code validator: a verdict carrying a code outside `reasons.yaml` is rejected before it can be acted on | S4 |
| 4 | `eve_silence` — any plan at `pending_eve` for more than four business hours sets `no_autonomous`, origin `breaker`, with an incident note | S3 entry |
| 5 | `eve_evidence_stale` — an executed L5 item with no row in the `verdict_receipts` view (receipts dataset `${EVE_RECEIPTS_DS}`, separate from `eve`) after 60 minutes freezes promotions; after four hours that cell drops to L4 | S4 |
| 6 | `eve_last_seen` — stamped **passively** from any successfully authenticated `eve-controller@` or `eve-verifier@` call, published as a metric with a Cloud Monitoring **absence** policy at 15 minutes | S3 entry |
| 7 | `items_hash` in the signed field list, and per-item vector verification | Before the approve endpoint is built |
| 8 | `eve_authority` on the ladder cell and on the override document, plus the denial reason `eve_authority_advisory` | S4 |
| 9 | A **CI-only stub caller** standing in for `eve-controller@`, exercising all eight interfaces and proving [SETUP.md](../wall-e/SETUP.md) section 4 denial tests 4, 5, 6 and 52 | never deployed |

Two properties of items 4 to 6 are not negotiable and are worth restating because they are
easy to "improve" into uselessness. **They key on the absence of work, never on reported
health** — a liveness signal Eve publishes cannot prove Eve is alive, because a wedged Eve
that still heartbeats keeps autonomy alive. And **no code path raises anything on Eve's
return.** Eve coming back clears nothing; only an operator clears `no_autonomous`.

Item 9 must not exist in any admitted image. There is no fault-injection or test-mode path
reachable in a deployed Eve or Wall-E image; the seeded-fault exercise of Phase 10 runs
against a separate sandbox deployment and dataset, and a CI import test asserts the absence.

**Verify.** Wall-E's CI, not a command here: the stub-caller tests pass, the import test
finds no test-mode module in the image, and the three sweeper mechanisms have unit tests
that assert the "never raises" property directly.

**Rollback.** Not applicable; nothing is deployed.

---

## Stage 2 — Eve's own evidence

### Phase 7 — Eve's organisation-level admin-log sink

**Widened 2026-09-13** (platform HLD §13.2; §18 item 13). The sink carries **all six** Cloud
Logging Workspace streams, not the Admin stream alone, still with **no actor exclusion**, and
it stays independent of the platform's aggregated sinks by design
([../agentic-platform/08-data-logging-retention-sovereignty.md](../agentic-platform/08-data-logging-retention-sovereignty.md)
§3.2). It is created at S2 **or before the super-admin grant, whichever comes first**. A filter
widened after creation does not backfill, so the widened filter goes in at creation time;
where the sink already exists with the Admin-only filter, record the date of the change as the
start of Eve's copy of the other five streams.

**Why this is at S2 and not S3.** Eve reconciles against **this** copy of Google's admin
audit log, never against `walle_workspace_logs` in Wall-E's project, which sits inside
Wall-E's teardown blast radius and whose actor exclusion Wall-E controls. Creating the sink
at S2 means Eve's first enforcing window — months later, at S3 entry — has history behind
it rather than zero rows. A verifier whose evidence starts on the day it starts enforcing
can prove nothing about the past.

**Why it needs calendar time.** An organisation-level sink needs organisation-level
`roles/logging.configWriter`, which for most tenants is someone else's grant to make. Ask
for it at the start of S2, not at the end. This is the only step in Eve's build with a
dependency outside your own control.

**The one property that must not be copied from Wall-E's sink.** Wall-E's
`walle-workspace-audit` sink carries an actor exclusion on the robot, and it must — without
it every write Wall-E makes triggers a run that writes again. Eve's sink carries **no actor
exclusion at all**. The robot's own events are exactly what Eve is there to see.

Verified 2026-09-12: an organisation-level aggregated sink may route to a BigQuery dataset
in another project, and its writer identity needs `roles/bigquery.dataEditor` there
([Aggregated sinks](https://docs.cloud.google.com/logging/docs/export/aggregated_sinks)).

**The dataset's partition expiry must be set before the sink writes into it, and the sink
must be told to use a partitioned table.** Neither is the default and neither can be
retrofitted to rows already written. Verified 2026-09-12: a BigQuery sink creates
date-sharded tables unless told otherwise — "The default selection is a date-sharded
table", with names "suffixed with the calendar date of log entry's UTC timestamp"
([Route logs to BigQuery](https://docs.cloud.google.com/logging/docs/export/bigquery)) —
and `--use-partitioned-tables` is the flag that changes it: "If specified, use BigQuery's
partitioned tables. By default, Logging creates dated tables based on the log entries'
timestamps, e.g. 'syslog_20170523'"
([gcloud logging sinks create](https://docs.cloud.google.com/sdk/gcloud/reference/logging/sinks/create)).
`bq update --default_partition_expiration` sets "the default lifetime, in seconds, for
partitions in newly created partitioned tables"
([Updating datasets](https://docs.cloud.google.com/bigquery/docs/updating-datasets)), so it
binds the sink's table only if the dataset already carries it when Logging creates that
table. Run the three commands in this order.

```bash
bq --location="$BQ_LOCATION" mk --dataset \
  --description="Google's Workspace audit logs, six streams, Eve's independent copy. No actor exclusion." \
  "${EVE_PROJECT}:eve_workspace_logs"

# 34560000 seconds = 400 days. Assumption: 400 days pending decision E-14.
# Before the sink, not after: this is the only chance to bound retention on a table
# Logging creates for itself.
bq update --default_partition_expiration=34560000 "${EVE_PROJECT}:eve_workspace_logs"

gcloud logging sinks create eve-workspace-audit \
  "bigquery.googleapis.com/projects/${EVE_PROJECT}/datasets/eve_workspace_logs" \
  --organization="$ORG_ID" \
  --include-children \
  --use-partitioned-tables \
  --log-filter='protoPayload.serviceName=("admin.googleapis.com" OR "cloudidentity.googleapis.com" OR "login.googleapis.com" OR "oauth2.googleapis.com") OR logName:"organizations/'"${ORG_ID}"'/logs/cloudaudit.googleapis.com%2Faccess_transparency"'
# Widened 2026-09-13 (was: protoPayload.serviceName="admin.googleapis.com").
# Service names verified 2026-09-13 (https://docs.cloud.google.com/logging/docs/audit/gsuite-audit-logging):
# admin = admin.googleapis.com; enterprise groups = cloudidentity.googleapis.com;
# login AND SAML = login.googleapis.com; OAuth token = oauth2.googleapis.com.
# Assumption: the Access Transparency clause - that page names no service for it; confirm
# against the first rows (verify step 5) and correct the clause before relying on it.
# OAuth token, SAML and Access Transparency are edition-conditional (tenant edition tbd).

export EVE_SINK_WRITER="$(gcloud logging sinks describe eve-workspace-audit \
  --organization="$ORG_ID" --format='value(writerIdentity)')"
```

Grant that writer identity `dataEditor` on **this dataset only** — not at project level:

```bash
bq show --format=prettyjson "${EVE_PROJECT}:eve_workspace_logs" > /tmp/ewl.json
W="${EVE_SINK_WRITER#serviceAccount:}" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/ewl.json'))
d.setdefault('access', []).append({"role": "WRITER", "userByEmail": os.environ['W']})
json.dump(d, open('/tmp/ewl.json', 'w'))
EOF
bq update --source=/tmp/ewl.json "${EVE_PROJECT}:eve_workspace_logs"
```

Then repoint metric 9 and query 11 from Phase 4 at `eve_workspace_logs`. The standing
drift check in the other direction — **that Wall-E's `walle_workspace_logs` still carries
no actor exclusion** — is a drift check on Wall-E, and it is why audit completeness is
computed from Eve's copy, so that deleting Wall-E's copy does not silently make the metric
perfect. It needs a grant no set makes today: the sink filter is an organisation resource
(reading it would need organisation-level `logging.viewer`, refused), and the dataset is in
`WALLE_PROJECT`. Topology decision 47 gives it a form — dataset-level `READER` on
`walle_workspace_logs` for `eve-verifier@`, made by Wall-E's runbook at S3 entry, and a
data-level comparison of robot-actor admin events per day in `eve_workspace_logs` against
`walle_workspace_logs`, a persistent deficit being the finding. **Until that grant lands,
Eve does not run the check**; do not add it to Eve v0 here.

Also at S2, add to Eve v0 the **Google-side contract drift check**: a query comparing a
committed snapshot of privilege names and admin event names against what the tenant now
reports. It exists because Google renames things and a renamed event name silently empties
a reconciliation join.

**Verify.**

```bash
# 1. the filter carries NO actor exclusion
gcloud logging sinks describe eve-workspace-audit --organization="$ORG_ID" \
  --format='value(filter)'
# expect exactly the six-stream filter of the create command above
# (before 2026-09-13: protoPayload.serviceName="admin.googleapis.com")
# if it contains principalEmail!=... the sink is wrong: delete and recreate

# 2. --include-children actually took
gcloud logging sinks describe eve-workspace-audit --organization="$ORG_ID" \
  --format='value(includeChildren)'
# expect: True

# 3. the destination is ONE partitioned table, DAY-partitioned, with a partition expiry.
#    This is the check that fails if --use-partitioned-tables was forgotten: the table
#    below will not exist at all, and a series of ..._activity_YYYYMMDD will exist instead.
bq show --format=prettyjson \
  "${EVE_PROJECT}:eve_workspace_logs.cloudaudit_googleapis_com_activity" \
  | python3 -c "import json,sys; t=json.load(sys.stdin).get('timePartitioning',{}); \
print(t.get('type'), t.get('field'), t.get('expirationMs'))"
# expect: DAY  <partitioning column or None>  34560000000
# A Not-found error here means --use-partitioned-tables was forgotten. A null
# expirationMs means the dataset default was set after the sink, not before.
# Write down the partitioning column. Both table types partition on the log entry's
# timestamp, but the column BigQuery reports is what every later query must filter on,
# as the bare column and not wrapped in a function, or nothing prunes: `timestamp` when
# a field is named, `_PARTITIONTIME` when the field prints None. *tbd* until run —
# do not assume which, and do not leave `DATE(timestamp)` in a query either way.

# 4. rows arrive, and the robot's own events are among them
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT protopayload_auditlog.authenticationInfo.principalEmail AS actor, COUNT(*) n
   FROM `eve_workspace_logs.cloudaudit_googleapis_com_activity`
   WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
   GROUP BY actor ORDER BY n DESC'
# expect: walle@<domain> present. If it is absent, the exclusion was copied by mistake.
# Substitute _PARTITIONTIME for `timestamp` if step 3 reported no partitioning field.
```

```bash
# 5. added 2026-09-13: every stream the edition carries is arriving. Login, SAML and the
#    Data Access half of OAuth token land in a separate Data Access table Logging creates;
#    list the dataset and read both tables.
bq ls "${EVE_PROJECT}:eve_workspace_logs"
# expect: the activity table and a data_access table (exact names as Logging created them)
# then, per table, GROUP BY protopayload_auditlog.serviceName over the last two days
# expect: admin.googleapis.com, cloudidentity.googleapis.com, login.googleapis.com,
#         oauth2.googleapis.com, and an Access Transparency entry if the edition has them.
#         A stream the edition should carry but that is absent is a finding, not a pass.
```

Make a trivial admin change in the console and confirm it lands within minutes. Then have
Wall-E make one — a shadow run is enough — and confirm **that** lands too. Check 4 passing
with only human actors in it is the failure this phase exists to prevent.

**Rollback.** `gcloud logging sinks delete eve-workspace-audit --organization="$ORG_ID"`
and `bq rm -r -f -d "${EVE_PROJECT}:eve_workspace_logs"`. Note that from this phase on,
deleting Eve's project is no longer a complete rollback: the organisation-level sink
survives it and keeps exporting to a destination that no longer exists. Delete the sink
first, always.

---

## S3 entry — Eve onboarding

Phases 8, 9 and 10 are **one sitting**. The Workspace half and the GCP half are separated
below because they fail differently and roll back differently, but they are executed
together, in this order, on one day. The reason for doing them together is not tidiness:
the OAuth consent, the Trusted-client marking and the scope freeze all happen in the same
browser session, and a half-finished Phase 8 leaves a consented token with the wrong scopes
that cannot be widened without redoing all of it.

`Assumption:` allow a full working day for phases 8 to 10 with verification, not the sixty
minutes [SETUP.md](../wall-e/SETUP.md) budgets for its Phase 15 — that estimate covered the
credential alone.

**Before starting, re-read [E-16](09-open-decisions.md).** If
[decision 26](../wall-e/09-open-decisions.md) has come back saying a keyless service account
can hold a custom admin role with no domain-wide delegation, most of Phase 8 disappears.
Reworded 2026-09-13: decision 26 is closed for Wall-E by fact (P33) and open for Eve only; E-16
now also fixes the widened read set before this consent, and when the super-admin grant comes
first these phases run in the observe-and-report sitting, not at S3 entry.

### Phase 8 — The Workspace half

Every step here is a **manual console step**. There is no gcloud for any of it.

1. **The account.** Admin console → Directory → Users → create `eve@<domain>` in
   `/Automation/Service Identities`. Long random password straight into the corporate
   password vault — never into the wiki, a ticket or a chat message.
2. **The role.** Admin console → Account → Admin roles → Create new role
   `Eve — Verifier`, with **read privileges only**:

   | Privilege | Granted |
   |---|---|
   | Users → Read | yes |
   | Groups → Read | yes |
   | Organisational units → Read | yes |
   | Reports → Audit read, Usage read | yes |
   | Admin roles → Read | yes |
   | Domain settings → read; customer settings → read (added 2026-09-13, E-16) | yes — exact privilege names resolved with `privileges.list` on the tenant, *tbd* until run |
   | Every Reports application the poll reads (added 2026-09-13) | yes, through Reports → Audit read |
   | **Any write privilege, at any stage, ever** | **no** |
   | **License Management** | **no** — see below |
   | Security settings, Vault, eDiscovery, any content privilege | **no**, never (Domain settings moved to *read: yes* above on 2026-09-13; read only) |

   Assign it **customer-scoped**. Reports and Groups privileges cannot be unit-scoped
   anyway, and Eve's job is tenant-wide observation.
3. **Hardening**, identical to Wall-E's robot: 2SV enforced, hardware key only, its own key
   in the same safe, **separately labelled**. No recovery email, no recovery phone, no code
   fallback. Short session length. Not a super admin, ever — required by the objective of
   2026-09-13, and asserted daily by Eve's own roster check.
4. **The login rule.** Admin console → Rules → a second reporting rule, same shape as
   Wall-E's, on **any login** with actor `eve@<domain>`, routed to you and to
   `walle-operators@`. Leave the event type unfiltered: a run of failed logins is as
   interesting as a successful one. `Assumption:` your edition supports reporting rules on
   the login audit log; if it does not, the fallback is a log-based metric over the shared
   Cloud Logging data with a Cloud Monitoring alert on it.
5. **Protected membership.** Add `eve@<domain>` to `walle-protected@` and to the committed
   floor list `~/Claude/wall-e/config/protected_floor.txt`. Wall-E must never be able to
   write to Eve's account.
6. **The OAuth client — a new, separate Desktop client.** APIs & Services in **Eve's** GCP
   project → OAuth consent screen: Internal, In production. Credentials → Create OAuth
   client ID → **Desktop app**. **Never reuse Wall-E's client.** One client, one token.
7. **Mark it Trusted, in the same sitting.** Admin console → Security → API controls → App
   access control → add this client ID → Trusted. Skipping this means a future scope
   restriction silently kills Eve, months later, with no obvious cause.
8. **Consent**, in the clean browser profile, signed in as `eve@<domain>`, requesting
   exactly these scopes and no others:

   | Scope | Why |
   |---|---|
   | `admin.directory.user.readonly` | Pre-state and post-state re-reads on users |
   | `admin.directory.group.readonly` | The same for groups |
   | `admin.directory.orgunit.readonly` | OU allowlist checks |
   | `admin.directory.rolemanagement.readonly` | `roleAssignments.list` for the daily operator-list reconciliation, and to know which groups carry admin roles |
   | `admin.reports.audit.readonly` | Targeted trigger corroboration; since 2026-09-13 also the Reports API poll by actor across every application (Phase 10b) |
   | `admin.reports.usage.readonly` | Metric series |
   | `admin.directory.domain.readonly` (added 2026-09-13) | Domain settings as state, for the roster and tenant-integrity checks |
   | `admin.directory.customer.readonly` (added 2026-09-13) | Customer settings as state |
   | `openid`, `userinfo.email` | So the bootstrap can verify **which** account consented — the check that stops you storing your own credentials by accident |

   **`apps.licensing` is dropped.** [SETUP.md](../wall-e/SETUP.md) Phase 15, before
   2026-09-13 (when it still built Eve's credential in Wall-E's project), granted it with
   the justification "Eve needs to read assignments"; the scope list above is this phase's
   own. That justification does not survive:
   the privilege is indivisible, it carries assign and revoke, and Eve holds no write
   privilege at any stage ever. The cost is real and is accepted rather than argued away —
   F7 licence changes can only be verified from Google-written licence events, recorded
   `verified_partial` with reason `licence_event_only`, and that is a **permanent** declared
   limit on Eve's independence for F7, carried in every F7 attestation. See
   [06-failure-modes.md](06-failure-modes.md).

   Never request `cloud-platform` for the robot. It binds the Workspace credential to the
   organisation's GCP session-control policy and expires it on a schedule nobody chose.

9. **Store the token** in Eve's project, in regional secrets, with the version pinned. The
   commands are in Phase 9; the consent output goes nowhere else in the meantime.

**Verify.**

```bash
python bootstrap/verify_token.py --project="$EVE_PROJECT" --region="$REGION" \
  --secret=eve-refresh-token --secret-version="$EVE_TOKEN_VERSION" \
  --expect-account="$EVE_ROBOT"
# expect: account = eve@<domain>; a users.list succeeds; a users.update fails 403;
#         the scope set matches the table above EXACTLY - ten scopes since 2026-09-13 -
#         apps.licensing absent, no content scope, no cloud-identity.policies scope
#         (the Policy API is super-admin-only; Eve is never one);
#         users.get on eve@ returns isAdmin false.
# The script exits non-zero on any mismatch.
```

The 403 on `users.update` is the important half. At this phase Eve's role is read-only, so
a write attempt **must** fail at Google's end, not merely at Eve's. That is the difference
between a control and a convention.

Then sign in once as `eve@<domain>` in the clean profile and confirm 2SV is enforced, the
login alert fires, and the account cannot open Security settings.

**Rollback.** Revoke the app at `https://myaccount.google.com/permissions` as
`eve@<domain>`, destroy the secret version, delete the OAuth client, remove the Trusted
entry, delete the role assignment, suspend the account. In that order — revoking the grant
first means a leaked token stops working immediately rather than at the end of the cleanup.

---

### Phase 9 — The GCP half: identities, secrets, grants, bucket

```bash
gcloud services enable \
  run.googleapis.com cloudscheduler.googleapis.com secretmanager.googleapis.com \
  storage.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com \
  iap.googleapis.com \
  --project="$EVE_PROJECT"

for SA in eve-controller eve-verifier eve-console; do
  gcloud iam service-accounts create "$SA" --project="$EVE_PROJECT"
done
```

**Two runtime identities, not one, and this is the whole point of the split.** The process
that parses attacker-writable strings out of Google's audit log — display names, group
names, OU descriptions — must not be able to reach the signing key.
`eve-verifier@` runs `eve-reconciler`; `eve-controller@` runs `eve-gate` and, from Phase 11,
holds `roles/cloudkms.signer`. At this phase neither holds it, because the key does not
exist yet.

**The secrets, regional, in Eve's project.**

```bash
for S in eve-oauth-client eve-refresh-token; do
  gcloud secrets create "$S" --location="$REGION" --project="$EVE_PROJECT"
done

# store the Phase 8 outputs; the payloads never appear in this document, in a ticket,
# or in shell history with --data-file=- reading from a file you then shred
gcloud secrets versions add eve-oauth-client --location="$REGION" \
  --project="$EVE_PROJECT" --data-file=./eve_client.json
gcloud secrets versions add eve-refresh-token --location="$REGION" \
  --project="$EVE_PROJECT" --data-file=./eve_token.json

shred -u ./eve_client.json ./eve_token.json

for S in eve-oauth-client eve-refresh-token; do
  for M in "$SA_EVE" "$SA_EVE_VERIFIER"; do
    gcloud secrets add-iam-policy-binding "$S" --location="$REGION" \
      --project="$EVE_PROJECT" \
      --member="serviceAccount:${M}" --role=roles/secretmanager.secretAccessor
  done
done
```

`--location` creates a **regional** secret: the payload stays in the region at rest, in use
and in transit. Pin the version in `EVE_TOKEN_VERSION` and read
`.../secrets/eve-refresh-token/versions/<n>`, **never `versions/latest`** — `latest`
resolves to the newest *enabled* version, so disabling the newest silently falls back to the
previous still-valid token and the kill switch does nothing. Do not assume the number is 1.

`walle-actions@` must not appear in that loop, and it cannot: it has no principal in this
project at all. That is the project boundary doing the work that IAM hygiene used to do.

**Cross-project grants in `WALLE_PROJECT` — provided by Wall-E's runbook at S3 entry, not
made here.** Exactly two kinds of grant to Eve identities exist in `WALLE_PROJECT`, both on
a resource, both made by Wall-E's runbook ([../project-topology.md](../project-topology.md)
§3 rows 3 and 4): `run.invoker` on the service `walle-actions` through SETUP Phase 10's
loop (CC-20), and dataset-level `READER` on `walle_audit` through SETUP Phase 7 (CC-22,
next paragraph), all against the `@${EVE_PROJECT}` emails in the shell block. **No
project-level role for any Eve identity exists in `WALLE_PROJECT`**: `EVE_PROJECT_ROLES` in
`walle_setup.py` is `()` since 2026-09-13 and SETUP Phase 6 refuses the line;
`agentregistry.viewer` is dropped (topology decision 43 — no resource-level form exists and
no Eve duty needs it); `datastore.viewer` is **not granted**. Eve's Firestore discovery read
of `plans/{id}` at `pending_eve` therefore has no grant behind it until topology decision
44 lands — either `datastore.viewer` under an IAM Condition scoped to Wall-E's `(default)`
database (Firestore documents database-scoped conditions,
https://docs.cloud.google.com/firestore/docs/security/iam; the expression is **unverified**
and is Wall-E's spike), or the list endpoint `GET /v1/plans?state=pending_eve` on
`walle-actions` (CC-33). Until one of them lands, `eve-gate` cannot discover work and
**this phase is blocked at that step**, deliberately: never leave Eve depending on a grant
Wall-E refuses to make. Hand Wall-E's operator the three emails, then **verify with checks
3 and 6 below**. For reference, what Wall-E's runbook runs — it needs
`run.services.setIamPolicy` in `WALLE_PROJECT`, which no Eve principal holds:

```bash
# Wall-E's runbook, in WALLE_PROJECT — reference only, never run from Eve's side.
# No `gcloud projects add-iam-policy-binding "$WALLE_PROJECT"` line for any Eve
# identity exists any more; one appearing here would be the old placement.
for M in "$SA_EVE" "$SA_EVE_VERIFIER" "$SA_EVE_CONSOLE"; do
  gcloud run services add-iam-policy-binding walle-actions \
    --project="$WALLE_PROJECT" --region="$REGION" \
    --member="serviceAccount:${M}" --role=roles/run.invoker
done
```

**Added 2026-09-13: the halt path onto `walle-actions-super`** (platform HLD §18 item 25;
[08-contract-changes.md](08-contract-changes.md) CC-34). Wall-E's runbook grants
`roles/run.invoker` on the Cloud Run service `walle-actions-super` to Eve's halt identity,
service-level, and that service's in-app control list admits it to the halt endpoint only.
Item 25 names `eve-controller@`; page 07 §7 has `eve-reconciler` (`eve-verifier@`) issue the
`log_pipeline_silent` halt — which identity is *tbd* for the reconcile pass. **Decided
2026-09-13 (review-findings pass): both, halt path only** — `eve-controller@` for halts raised
at the approval point, `eve-verifier@` for every reconciler-limb halt of [03-lld.md](03-lld.md)
§14 ([../project-topology.md](../project-topology.md) row 27; platform HLD §18 item 25, extended). Verify it with
check 6, extended below; do not make it from Eve's side.

[E-12](09-open-decisions.md) exists because an earlier wording said `datastore.viewer`
was Eve's only project-level role while the runbook granted `agentregistry.viewer` as
well; it is settled by removal — the rule is now "no project-level role in `WALLE_PROJECT`
at all", the mirror image of Wall-E's `check_project_roles`, and check 3 below asserts it.

The dataset-level `READER` entry on `walle_audit` for `eve-controller@` and `eve-verifier@`
is likewise **Wall-E's runbook's step** (CC-22, exactly as for `eve-v0@` in Phase 2), made
in `WALLE_PROJECT` against the `@${EVE_PROJECT}` emails. What Eve makes here is the job
right in its own project, so query cost and job quota never touch Wall-E's:

```bash
# in EVE_PROJECT — Eve's own step
for M in "$SA_EVE" "$SA_EVE_VERIFIER"; do
  gcloud projects add-iam-policy-binding "$EVE_PROJECT" \
    --member="serviceAccount:${M}" --role=roles/bigquery.jobUser
done
```

`run.invoker` is granted per **service**, not per path. What keeps Eve out of
`POST /v1/execute` is the per-endpoint allowlist inside `walle-actions`, keyed on the
verified identity token. That allowlist is **Wall-E's configuration in `WALLE_PROJECT`**,
owned and asserted by `walle_setup.py` (CC-30), and it is **provided by Wall-E's runbook at
S3 entry**:

```
CONTROL_CALLER_ALLOWLIST=${SA_EVE},${SA_EVE_VERIFIER},${OPERATORS}   # cross-project emails
```

Do not set it from Eve's side: `gcloud run services update --update-env-vars` replaces the
whole value, and an Eve-side command would clobber whatever else Wall-E stores alongside —
in particular the **read-endpoint allowlist**, a separate list carrying
`eve-console@${EVE_PROJECT}…` (`GET /v1/plans`, `GET /v1/ladder`) and
`mo-analyst@<MO_PROJECT>` (`GET /v1/plans`, `GET /v1/runs` only). Verify with check 6.

**`${OPERATORS}` must stay in that list.** If the service treats the variable as exhaustive
— the fail-closed reading, and the only safe one — then Eve alone means no human can halt
or demote, and every kill-switch timing becomes unmeasurable. That is denial test 52.

**The locked evidence bucket.**

```bash
gcloud storage buckets create "$EVE_EVIDENCE" \
  --project="$EVE_PROJECT" --location="$BQ_LOCATION" \
  --uniform-bucket-level-access --public-access-prevention

gcloud storage buckets update "$EVE_EVIDENCE" --retention-period=400d
gcloud storage buckets update "$EVE_EVIDENCE" --lock-retention-period

# create-only. No delete, no overwrite.
gcloud storage buckets add-iam-policy-binding "$EVE_EVIDENCE" \
  --member="serviceAccount:${SA_EVE_VERIFIER}" --role=roles/storage.objectCreator

# Wall-E's CI (CI_DEPLOYER, a WALLE_PROJECT principal) publishes the ladder artefact,
# create-only, into its own prefix. This is the one Eve-made resource-level grant to a
# Wall-E principal at S3 entry — one of exactly three such grants in EVE_PROJECT
# (topology decision 48, row 16); it is bucket-level with a prefix condition, never a
# project-level role.
gcloud storage buckets add-iam-policy-binding "$EVE_EVIDENCE" \
  --member="serviceAccount:${SA_WALLE_CI}" --role=roles/storage.objectCreator \
  --condition='expression=resource.name.startsWith("projects/_/buckets/'"${EVE_PROJECT}"'-eve-evidence/objects/ladder/"),title=ladder-prefix-only'
```

Locking is **irreversible**, and that is the point: a locked retention policy cannot be
removed or shortened, and it applies a lien that prevents the project being deleted
([Bucket Lock](https://docs.cloud.google.com/storage/docs/using-bucket-lock),
[Object Retention Lock](https://docs.cloud.google.com/storage/docs/object-lock), verified
2026-09-12). That converts a detective control — "someone shortened the evidence
retention" — into a preventive one. It also means the answer to
[E-14](09-open-decisions.md) must be a floor **and** a ceiling before this command runs.

`objectCreator` rather than `objectAdmin` is the same argument as Wall-E's insert-only
audit role: the process that writes the evidence must not be able to destroy it.

**Three prefixes live in this bucket**, and the locked policy is why there is no second one:
`ladder/` for the CI-published artefact, `keys/` for the `eve-approval` PEM archive written
at S4 entry by Phase 11, and the attestation bundles and daily reconciliation extracts
`eve-verifier@` writes. Nothing under any of them can be deleted or replaced before its
retention expires.

**The CI-published ladder artefact.** Wall-E's CI writes
`gs://<eve-project>-eve-evidence/ladder/<config_version>.yaml` plus its git sha, append-only,
on every merge to `ladder.yaml`. This replaces "Eve reads `ladder.yaml` in git": Eve needs
no git credential, and the configuration Eve re-derives effective levels from cannot be
rewritten by Wall-E's deployers.

**Verify.**

```bash
# 1. the two properties re-verified after EVERY IAM change, in both directions.
#    Both must print nothing.
for S in eve-oauth-client eve-refresh-token; do
  gcloud secrets get-iam-policy "$S" --location="$REGION" --project="$EVE_PROJECT" \
    --flatten='bindings[].members' --filter="bindings.members:${SA_ACTIONS}" \
    --format='value(bindings.members)'
done
# the second loop reads secret policies in WALLE_PROJECT: it needs
# secretmanager.secrets.getIamPolicy there and is run by the human owner. --location
# presumes Wall-E's secrets are regional, per Wall-E's set.
for S in walle-oauth-client walle-refresh-token walle-confirm-hmac; do
  gcloud secrets get-iam-policy "$S" --location="$REGION" --project="$WALLE_PROJECT" \
    --flatten='bindings[].members' \
    --filter="bindings.members:${SA_EVE} OR bindings.members:${SA_EVE_VERIFIER}" \
    --format='value(bindings.members)'
done

# 2. Wall-E's deployers hold no project-level role in Eve's project, and none on the
#    folder. A project-level read misses inherited bindings, so read both levels.
for M in "$SA_ACTIONS" "$SA_WALLE_CI" "<walle-deployer-group>"; do
  gcloud projects get-iam-policy "$EVE_PROJECT" --flatten='bindings[].members' \
    --filter="bindings.members:${M}" --format='value(bindings.role)'
  gcloud resource-manager folders get-iam-policy "$FOLDER_ID" --flatten='bindings[].members' \
    --filter="bindings.members:${M}" --format='value(bindings.role)'
done
# expect: nothing, six times. The three resource-level carve-outs for Wall-E principals
# (CI on the bucket prefix; walle-actions@ on the key and on the receipts dataset, both
# S4) do not appear here because they are not project-level bindings — that is the
# point. The one Mo carve-out (mo-metrics@${MO_PROJECT}, dataset-level READER on the
# mirror's dataset, from S4 — Phase 11, topology row 18) is likewise dataset-level and
# never appears in the project policy; Phase 12's drift job expects exactly it from S4
# and fails on any other Mo principal, or on the same one before S4.
# Extended 2026-09-13: the Mo list gains mo-metrics@ READER on eve_quality (Phase 10b,
# from Wall-E's Stage 1), and the expected foreign set gains the validator custodian on
# eve_quality, eve-advisor@ on its view dataset and eve_advice, platform-drift@'s
# folder-inherited securityReviewer, factory-apply@ only under an active approved
# ent-factory-singleton PAM grant, and the SDP discovery service agent. All dataset- or
# folder-level; none appears in the project policy; anything else fails.

# 3. no Eve identity holds ANY project-level role in Wall-E's project — the mirror
#    image of Wall-E's check_project_roles (reads WALLE_PROJECT's policy: human owner,
#    or Wall-E's drift job from its side)
for M in "$SA_EVE" "$SA_EVE_VERIFIER" "$SA_EVE_CONSOLE" "$SA_EVE_V0"; do
  gcloud projects get-iam-policy "$WALLE_PROJECT" --flatten='bindings[].members' \
    --filter="bindings.members:${M}" --format='value(bindings.role)'
done
# expect: nothing, four times. A non-empty result is a defect — the old placement, or a
# datastore.viewer someone restored — until topology decision 44 names a resource-scoped
# form (a binding carrying an IAM Condition on the (default) database), which is then the
# one line this check is updated to expect, with the condition, and nothing else.

# 4. no aiplatform permission anywhere on either Eve identity — in Eve's project, in
#    Wall-E's, and in the Gemini app's project, where a discoveryengine or aiplatform
#    grant to an Eve identity would be most damaging. Reading GEMINI_PROJECT's policy
#    needs viewer there (human owner).
for M in "$SA_EVE" "$SA_EVE_VERIFIER"; do
  for P in "$EVE_PROJECT" "$WALLE_PROJECT" "$GEMINI_PROJECT"; do
    gcloud projects get-iam-policy "$P" --flatten='bindings[].members' \
      --filter="bindings.members:${M} AND (bindings.role:aiplatform OR bindings.role:discoveryengine)" \
      --format='value(bindings.role)'
  done
done
# expect: nothing, six times. In particular no reasoningEngines.query.

# 5. the retention policy is locked
gcloud storage buckets describe "$EVE_EVIDENCE" \
  --format='value(retentionPolicy.isLocked,retentionPolicy.retentionPeriod)'
# expect: True  34560000

# 6. the allowlist landed with BOTH Eve identities and the operators group, as
#    cross-project emails (needs run.viewer in WALLE_PROJECT: human owner)
gcloud run services describe walle-actions --project="$WALLE_PROJECT" --region="$REGION" \
  --format='value(spec.template.spec.containers[0].env)' | tr ';' '\n' \
  | grep CONTROL_CALLER_ALLOWLIST

# 6b. added 2026-09-13: the halt-path invoker on walle-actions-super, and nothing broader
gcloud run services get-iam-policy walle-actions-super --project="$WALLE_PROJECT" \
  --region="$REGION" --flatten='bindings[].members' \
  --format='table(bindings.role,bindings.members)'
# expect: roles/run.invoker for eve-controller@ and eve-verifier@ (CC-34, topology row 27,
# both halt path only, decided 2026-09-13), and no other Eve identity (never eve-console@,
# eve-v0@, eve-export@ or eve-advisor@)
```

Checks 1 and 2 are the ones to re-run after every future IAM change, in both directions,
forever. CI asserts check 4. **Eve's own daily drift job asserts check 2** — it reads
`EVE_PROJECT`'s and `FOLDER_ID`'s policies, which Wall-E's drift job cannot do without a
grant CC-29 forbids; **Wall-E's drift job asserts check 3 from its side** (topology
decision 46, recorded in [02-identity-and-auth.md](02-identity-and-auth.md)).

**Rollback.** Delete the three service accounts, delete the two secrets, and ask Wall-E's
operator to remove the `WALLE_PROJECT` bindings and to revert `CONTROL_CALLER_ALLOWLIST` to
`${SA_EVE},${OPERATORS}` through Wall-E's runbook (both are `WALLE_PROJECT` edits).
**The bucket cannot be rolled back** — a locked retention policy cannot be removed, and the
project cannot be deleted while the lien stands. If you are abandoning Eve after this
command, the bucket and its objects persist until the retention period expires. That is the
control working, and it is worth knowing before you run it.

---

### Phase 10 — `eve/config`, `eve-reconciler`, `eve-console`, and the fixtures

**Eve's configuration repository is separate from Wall-E's.** In Wall-E's repository, one
pull request could widen Wall-E and loosen Eve together. `eve/config` carries:

| File | Contents |
|---|---|
| `thresholds.yaml` | Every halt, demote, veto and refuse threshold, versioned. `eve_config_version` is stamped on every verdict row, every control call and every attestation. |
| `reasons.yaml` | The closed reason vocabulary. A verdict carrying an unknown code is rejected before signing. |
| `predicates/` | Eve's **second implementation** of the typed `expects` predicates |
| `ceilings.py` | Eve's own compiled ceiling table |
| `oncall.yaml` | Declared coverage, and the no-operator window |
| `seeded_faults/` | The twelve fault fixtures and the two negative controls |
| `sql/` | The Phase 4 queries, so every query hash is reproducible from a committed artefact. Added by this runbook; it is not in the `eve/config` list in [01-hld.md](01-hld.md)'s component table |

Required reviewers: the ladder owner and the security reviewer of
[decision 37](../wall-e/09-open-decisions.md). **Human-merged only** — neither Eve identity
has a write path to it. The JSON-Schema validator is owned **outside** the repository,
exactly as `ladder.yaml`'s is, so a pull request cannot relax the rules that check it.

**The expensive item, and the one not to cut.** `predicates/` is a second implementation of
the same typed spec, differentially tested in CI against Wall-E's implementation over
generated cases, with no credential. Six of the twenty-odd engineer-days of this stage. Skip
it and Eve re-runs Wall-E's own predicate code, which means the verification-success metric
that unlocks L4 and L5 is measuring itself. The same argument applies to `ceilings.py`,
which Eve compiles independently so it can catch a plan claiming a level the ladder does
not grant.

**CI gates that must pass before the image is admitted:**

```bash
# 1. dependency absence: the lockfile is scanned against a denylist
python ci/deny_model_deps.py   # google-cloud-aiplatform, google-genai, vertexai,
                               # google-adk, anthropic, openai, langchain*
# 2. the same asserted at runtime, by import
python ci/assert_no_model_import.py
# 3. call-graph confinement: sign_envelope() reachable only from verdict_for_plan()
python ci/callgraph_sign.py
# 4. golden replay: archived verdicts recomputed offline, bit-identical
python ci/golden_replay.py
# 5. the IAM assertions of Phase 9 check 4
python ci/assert_no_aiplatform_iam.py
```

Gate 1 is what makes "no language model may produce an Eve approval" mechanical rather than
a policy statement: the signature cannot be produced by a model because the process cannot
reach one.

**Build and deploy `eve-reconciler` as a Cloud Run job**, not a service. A job on a
schedule costs near nothing, has no ingress at all, and a job task may run up to 168 hours
where a service request is capped at 60 minutes
([Cloud Run task timeout](https://docs.cloud.google.com/run/docs/configuring/task-timeout),
verified 2026-09-12). A resident `min-instances=1` service would cost €30–45/month to gate
nothing before S4, and a single instance restart would be a coverage gap.

```bash
gcloud artifacts repositories create eve \
  --repository-format=docker --location="$REGION" --project="$EVE_PROJECT"

gcloud builds submit --project="$EVE_PROJECT" --tag "${EVE_AR}/reconciler"

gcloud run jobs deploy eve-reconciler \
  --project="$EVE_PROJECT" --region="$REGION" \
  --image="${EVE_AR}/reconciler" \
  --service-account="$SA_EVE_VERIFIER" \
  --tasks=1 --max-retries=1 --task-timeout=1800s \
  --set-env-vars="^;^EVE_PROJECT=${EVE_PROJECT};WALLE_PROJECT=${WALLE_PROJECT};ACTIONS_URL=<actions-url>;REFRESH_TOKEN_SECRET=eve-refresh-token;EVE_TOKEN_VERSION=${EVE_TOKEN_VERSION};EVIDENCE_BUCKET=${EVE_EVIDENCE#gs://};LADDER_PREFIX=ladder/"
```

Each pass is one Cloud Scheduler job invoking the same Cloud Run job with a different
entrypoint argument, passed as a container override in the request body. Scheduler
authenticates to `run.googleapis.com` with an **OAuth** token — OIDC is wrong for a
`*.googleapis.com` target ([Run jobs on a
schedule](https://docs.cloud.google.com/run/docs/execute/jobs-on-schedule), verified
2026-09-12). The idempotency key is the job name plus the constant
`X-CloudScheduler-ScheduleTime` header, so a retried delivery does not double-write a
verdict.

```bash
# the jobs run AS eve-verifier@; whoever creates them must be allowed to attach it.
# Resource-scoped, never project-level. See Phase 2 for why this is actAs and not
# token minting, and why it looks redundant until the E-2 handover.
gcloud iam service-accounts add-iam-policy-binding "$SA_EVE_VERIFIER" \
  --project="$EVE_PROJECT" \
  --member="user:$(gcloud config get-value account)" \
  --role=roles/iam.serviceAccountUser

run_pass () {  # $1 = scheduler job name, $2 = entrypoint arg, $3 = cron
  gcloud scheduler jobs create http "$1" \
    --project="$EVE_PROJECT" --location="$REGION" --schedule="$3" \
    --uri="https://run.googleapis.com/v2/projects/${EVE_PROJECT}/locations/${REGION}/jobs/eve-reconciler:run" \
    --http-method=POST \
    --oauth-service-account-email="$SA_EVE_VERIFIER" \
    --headers="Content-Type=application/json" \
    --message-body='{"overrides":{"containerOverrides":[{"args":["'"$2"'"]}]}}' \
    --attempt-deadline=30s --max-retry-attempts=0
}

run_pass eve-posthoc      posthoc  "*/5 * * * *"     # L5 post-hoc verification
run_pass eve-hourly       hourly   "7 * * * *"       # reconciliation and drift
run_pass eve-deep         deep     "23 */6 * * *"    # the 6-hour deep pass
run_pass eve-daily        daily    "41 6 * * *"      # operator-list reconciliation,
                                                     # blind sample draw, attestations,
                                                     # the monthly token exchange
```

The 5-minute post-hoc poll of the day-partitioned `actions` table meets the 60-minute L5
SLA twelvefold. That is why Eve declines a Pub/Sub subscription on `walle-events`
altogether: a topic Wall-E publishes to is a channel Wall-E controls, and the only
latency-sensitive duty does not need it. Off-the-hour minutes for the same reason as
Phase 4.

**`eve-console`**, a Cloud Run service behind Identity-Aware Proxy, read-only, and the only
Eve component with an HTTP surface — which serves humans, never decisions.

```bash
gcloud builds submit --project="$EVE_PROJECT" --tag "${EVE_AR}/console"

gcloud services identity create --service=iap.googleapis.com --project="$EVE_PROJECT"

gcloud run deploy eve-console \
  --project="$EVE_PROJECT" --region="$REGION" \
  --image="${EVE_AR}/console" \
  --service-account="$SA_EVE_CONSOLE" \
  --no-allow-unauthenticated --iap \
  --min-instances=0 --concurrency=8 --timeout=60s

gcloud run services add-iam-policy-binding eve-console \
  --project="$EVE_PROJECT" --region="$REGION" \
  --member="serviceAccount:service-${EVE_PROJECT_NUMBER}@gcp-sa-iap.iam.gserviceaccount.com" \
  --role=roles/run.invoker

gcloud iap web add-iam-policy-binding \
  --project="$EVE_PROJECT" --region="$REGION" \
  --resource-type=cloud-run --service=eve-console \
  --member="group:${OPERATORS}" --role=roles/iap.httpsResourceAccessor
# Changed 2026-09-13 (platform HLD section 13.2): the audience becomes a dedicated group
# (name tbd) instead of ${OPERATORS}; its membership change is a severity-1 rule (SA-09).
# Substitute that group here once named.

export EVE_CONSOLE_URL="$(gcloud run services describe eve-console \
  --project="$EVE_PROJECT" --region="$REGION" --format='value(status.url)')"
```

Four views: the live queue with each plan's age and deadline; the blind sampled review; the
ladder state beside Eve's drift findings; the attestation bundles. It writes grades to
`eve.grades_blind` and **nothing else**. It cannot approve, veto, halt or demote, and it
must never render Eve's verdict on a review page. Make it legible on a phone — the blind
sample is the only bound on the compromised-Eve risk, and a bound nobody can act on from a
holiday is not a bound.

**The blind view is created by construction, not by UI.**

```bash
bq mk --use_legacy_sql=false --view \
  "SELECT run_id, item_index, operation, target, requested_by, ts
   FROM \`${EVE_PROJECT}.eve.review_queue\`" \
  "${EVE_PROJECT}:eve.review_queue_blind"
```

Eve's verdict and reason columns are **absent from the view**, not hidden by the console.
A CI test asserts the column list against an allowlist, because blindness for *accepts*
rests on that allowlist where blindness for *refusals* is structural — Eve's verdicts never
enter Wall-E's project at all.

**The seeded-fault fixtures.** Twelve faults and two negative controls, committed under
`seeded_faults/`. They are injected by serving Eve doctored plans and doctored log rows from
a harness against a **separate sandbox deployment and dataset** — never through a test-mode
path in an admitted image, which is banned and checked by CI gate 2. The exercise is the S3
**exit** gate, run months after this phase; the fixtures are written now so the gate is not
designed by whoever is under time pressure to pass it.

| # | Fault | Required verdict |
|---|---|---|
| 1 | Plan body altered after hashing | `plan_hash_mismatch` |
| 2 | `pre_state` contradicted by Workspace | `pre_state_mismatch` |
| 3 | Plan claims L4 for a cell the ladder puts at L2 | `level_overclaim` |
| 4 | `config_version` not in the artefact store | `config_version_unknown` |
| 5 | `ceilings_sha` ≠ the running service's | `ceilings_sha_mismatch` |
| 6 | Item targets a `walle-protected@` member | `target_protected` |
| 7 | Item targets outside the OU allowlist | `target_out_of_scope` |
| 8 | T2 plan whose trigger has no corroborating row in Eve's own log copy | `trigger_uncorroborated` |
| 9 | Robot admin event with no `walle_audit` row | `audit_row_missing` |
| 10 | `walle_audit` row with no admin event past its lag budget | `admin_event_unmatched` |
| 11 | Firestore level ≠ ladder artefact | `ladder_drift` |
| 12 | `/healthz` fresh over a stale table | `audit_claim_divergence` |
| N1 | Group write verified from current state 20 min after execution, Groups event not yet landed | `verification_deferred_lag` — re-checked, **not** a fault |
| N2 | `protected_principal` denial arising from a human chat request | an ordinary correct refusal; must **not** enter Eve's hard-invariant count |

An always-approving Eve fails 1 to 8. An always-refusing Eve fails both negative controls.
The gate is **100 % catch** on the twelve, and both negative controls not firing. Agreement
with human verdicts is reported for information only: a 95 % agreement rate is not a gate
for a deterministic checker.

**What Eve is trusted with at the end of this phase.** Halting and demoting, immediately
and for real — the safe direction, which can only make less happen. Also verifying,
reconciling, drift detection and the daily operator-list reconciliation. Its verdicts on
plans are **observe-mode**: logged, graded blind, enforcing nothing. Halt and demote are
live **for the invariant class only**; rate-based triggers stay observe-only until their
thresholds are calibrated. That split is [E-6](09-open-decisions.md), and the cost is named
rather than hidden: a buggy Eve can halt the programme during the stage the programme is
trying to prove itself. Halting is the direction one human can undo in seconds, which is
why it is the one taken first.

**Verify.**

```bash
# 1. the jobs exist and carry the right identity
gcloud run jobs describe eve-reconciler --project="$EVE_PROJECT" --region="$REGION" \
  --format='value(spec.template.spec.template.spec.serviceAccountName)'
# expect: eve-verifier@ — NOT eve-controller@

# 2. the reconciler identity holds no signer role anywhere
gcloud projects get-iam-policy "$EVE_PROJECT" --flatten='bindings[].members' \
  --filter="bindings.members:${SA_EVE_VERIFIER} AND bindings.role:kms" \
  --format='value(bindings.role)'
# expect: nothing (and at this phase there is no key at all)

# 3. force one pass and read its verdicts
gcloud run jobs execute eve-reconciler --project="$EVE_PROJECT" --region="$REGION" \
  --args=hourly --wait
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT verdict, reason_code, COUNT(*) n FROM `eve.verdicts`
   WHERE DATE(ts) = CURRENT_DATE() GROUP BY 1,2 ORDER BY n DESC'

# 4. the blind view leaks nothing
bq show --schema --format=prettyjson "${EVE_PROJECT}:eve.review_queue_blind" \
  | grep -Ec 'verdict|reason'
# expect: 0

# 5. the console is reachable only through IAP, and only by operators
curl -s -o /dev/null -w '%{http_code}\n' "$EVE_CONSOLE_URL"
# expect: 302 to the IAP sign-in, never 200

# 6. halt works end to end — this is drill K0 issued from Eve
#    Run it in the sandbox, confirm the halt lands, then clear it as an operator.
```

Check 6 is the one that proves this phase delivered something. From here, a monthly K0
drill is issued **from Eve** and timed into `drills/{date}`, alongside a rollback drill in
which Eve proposes and a human executes.

**Rollback.** `gcloud scheduler jobs delete` the four schedules, `gcloud run jobs delete
eve-reconciler`, `gcloud run services delete eve-console`. Eve stops; nothing degrades open;
`walle-actions`' own `eve_silence` sweeper sets `no_autonomous` after four business hours
and an operator clears it. The `eve/config` repository stays — it is the record of what the
thresholds were.

---

### Phase 10b — The observe-and-report layer, before the super-admin grant

Added 2026-09-13 (platform HLD §0.4, §13.1 item 5, §13.2, §13.3; §18 items 13–15 and 17). **Run
this before Wall-E's account receives Super Admin**, at whatever ladder stage that falls, after
Phases 7 (widened), 8, 9 and the jobs and schedules of Phase 10. The seeded-fault fixtures,
the blind view and everything of Phase 11 do not wait for it and are not needed by it.

**Preconditions.** [E-2](09-open-decisions.md)'s second human outside the Wall-E line is named
and holds `eve-owners@`; the witness organisation exists (P14: IT security created the tenant,
`EVE_WITNESS_PROJECT`, a bucket with a retention lock, the dataset `eve_mirror`, the severity
1/2 notification channels to individuals); `EVE_ADVISOR_PROJECT` exists if the reporting path is
being built (the factory makes it, P142 — not this runbook).

**1. The Reports API poll by actor.** A dataset for the results, bounded before anything
writes, then a new `reports` entrypoint of the same reconciler image on its own schedule:

```bash
bq --location="$BQ_LOCATION" mk --dataset \
  --description="Reports API activities.list by actor: walle@, eve@, every super admin on the roster" \
  --default_partition_expiration=34560000 \
  "${EVE_PROJECT}:eve_workspace_reports"

bq show --format=prettyjson "${EVE_PROJECT}:eve_workspace_reports" > /tmp/ewr.json
SA="$SA_EVE_VERIFIER" python3 - <<'PY'
import json, os
d = json.load(open('/tmp/ewr.json'))
d.setdefault('access', []).append({"role": "WRITER", "userByEmail": os.environ['SA']})
json.dump(d, open('/tmp/ewr.json', 'w'))
PY
bq update --source=/tmp/ewr.json "${EVE_PROJECT}:eve_workspace_reports"

# Assumption: every 5 minutes, like the post-hoc pass; the per-application lag budgets in
# thresholds.yaml (03-lld section 7) are tbd and calibrated at S2.
run_pass eve-reports reports "*/5 * * * *"
```

The poll calls `activities.list` with `userKey` set to each actor's primary email, one call per
application in `thresholds.yaml`'s `evidence.reports_poll` list, with `eve@`'s token and the
`admin.reports.audit.readonly` scope it already holds. It is the route that survives "Share data
with Google Cloud services" being switched off, which is why it exists.

**2. The detection catalogue, the roster and the heartbeat.** Three committed artefacts in
`eve/config`, human-merged with the second human as a required reviewer: the detection rule
file beside `reasons.yaml` (file name *tbd*) with a fixture per rule; the committed super-admin
roster, signed by the security reviewer; and the new `thresholds.yaml` rows (`evidence`,
`reconciliation`, `roster`, `reporting`). The hourly and daily passes of Phase 10 evaluate them;
no new job. The tenant-integrity rules carry the SIEM's ids `SA-01`…`SA-09` so the two
evaluators can be compared. The H-1 absence alarm is two policies: one in `EVE_PROJECT` built
from the platform's monitoring baseline module ([../agentic-platform/07-monitoring-detection-incident-response.md](../agentic-platform/07-monitoring-detection-incident-response.md)
§4; metric and exact policy *tbd* at build), and one in the witness on the mirrored heartbeat
table, created by the witness administrators. Windows: 60 minutes in business hours, 240
outside; the witness push 26 hours.

**3. The reporting contract.** `eve.incidents` and `eve.pages` exist from Phase 3 with the
columns of [03-lld.md](03-lld.md) §9; `oncall.yaml` gains `primary`, `secondary` (outside the
Wall-E line) and per-severity timeouts, and the K5/K6 rota section. Wire the severity-1 route to
the witness channels and the severity-2 route to PagerDuty and email, per
[03-lld.md](03-lld.md) §15; the report-about-the-administrator route goes to the second human
only.

**4. `eve-export@` and the daily export to the witness** (P107; one identity per duty).

```bash
gcloud iam service-accounts create eve-export --project="$EVE_PROJECT" \
  --display-name="Eve daily export and witness push"

gcloud projects add-iam-policy-binding "$EVE_PROJECT" \
  --member="serviceAccount:${SA_EVE_EXPORT}" --role=roles/bigquery.jobUser

# READER on eve (the access array, as in Phase 3)
bq show --format=prettyjson "${EVE_PROJECT}:eve" > /tmp/eve.json
SA="$SA_EVE_EXPORT" python3 - <<'PY'
import json, os
d = json.load(open('/tmp/eve.json'))
entry = {"role": "READER", "userByEmail": os.environ['SA']}
if entry not in d.setdefault('access', []):
    d['access'].append(entry)
json.dump(d, open('/tmp/eve.json', 'w'))
PY
bq update --source=/tmp/eve.json "${EVE_PROJECT}:eve"

# read the locked bucket; create-only under exports/, the same condition form as ladder/
gcloud storage buckets add-iam-policy-binding "$EVE_EVIDENCE" \
  --member="serviceAccount:${SA_EVE_EXPORT}" --role=roles/storage.objectViewer
gcloud storage buckets add-iam-policy-binding "$EVE_EVIDENCE" \
  --member="serviceAccount:${SA_EVE_EXPORT}" --role=roles/storage.objectCreator \
  --condition='expression=resource.name.startsWith("projects/_/buckets/'"${EVE_PROJECT}"'-eve-evidence/objects/exports/"),title=exports-prefix-only'
```

Provided by others, verified here, never made from Eve's side: dataset-level `READER` on
`walle_audit` for `${SA_EVE_EXPORT}` by Wall-E's runbook (CC-35); and, **in the witness
organisation, by the witness administrators**, `roles/bigquery.dataEditor` on `eve_mirror` and
`roles/storage.objectCreator` on the witness bucket for `${SA_EVE_EXPORT}` — the only
cross-organisation grants, with the witness's own `iam.allowedPolicyMemberDomains` listing the
tenant's customer id for this principal only. Deploy the export as a Cloud Run job running as
`${SA_EVE_EXPORT}`, with the same resource-scoped `serviceAccountUser` grant as Phase 10, on a
daily schedule off the hour. It writes newline-delimited JSON with a `MANIFEST.json` per table
per day under `exports/<project>/<dataset>/<table>/dt=YYYY-MM-DD/`, then pushes the day and a
heartbeat row to the witness ([../agentic-platform/08-data-logging-retention-sovereignty.md](../agentic-platform/08-data-logging-retention-sovereignty.md)
§5.4).

**5. The `eve_quality` dataset and its two readers, made by this runbook** (platform HLD §13.3;
P30). Authorised views only, no free-text columns, over `findings`, `verdicts`, `attestations`,
`pages`, `incidents` minus narrative, and `seeded_fault_runs`; never `grades_blind` or
`review_queue_blind`.

```bash
bq --location="$BQ_LOCATION" mk --dataset \
  --description="Eve quality: authorised views for Mo and the validator custodian. No free text." \
  "${EVE_PROJECT}:${EVE_QUALITY_DS}"

# one view per source table, explicit column lists, no free-text column (schemas: 03-lld section 9)
# e.g. incidents minus narrative:
bq mk --use_legacy_sql=false --view \
  "SELECT severity, rule, actor, targets, recipients, ack_ts, ack_by, resolution, case_id, ts
   FROM \`${EVE_PROJECT}.eve.incidents\`" \
  "${EVE_PROJECT}:${EVE_QUALITY_DS}.incidents"
# ... findings, verdicts, attestations, pages, seeded_fault_runs likewise; column names follow
# the committed schemas and are tbd until those files exist.

# authorise each view on eve: a 'view' entry per view in eve's access array, as in Phase 11 step 2

# dataset-level READER to mo-metrics@ and the validator custodian — nothing on eve itself
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_QUALITY_DS}" > /tmp/eq.json
A="$SA_MO_METRICS" B="$SA_VALIDATOR" python3 - <<'PY'
import json, os
d = json.load(open('/tmp/eq.json'))
for sa in (os.environ['A'], os.environ['B']):
    entry = {"role": "READER", "userByEmail": sa}
    if entry not in d.setdefault('access', []):
        d['access'].append(entry)
json.dump(d, open('/tmp/eq.json', 'w'))
PY
bq update --source=/tmp/eq.json "${EVE_PROJECT}:${EVE_QUALITY_DS}"
```

Mo's and the custodian's query jobs run and are billed in their own projects; there is no
binding in `MO_PROJECT` for this. Gate for this step: Wall-E's Stage 1 (P143); it may run
earlier.

**6. The reporting path's two grants — only if P34 is decided and the `eve-advisor` build is
approved; paging additionally waits on P19.** In `EVE_PROJECT`: a dataset `${EVE_ADVISOR_VIEWS_DS}`
of authorised views over `eve.*`, `eve_workspace_logs` and the report tables, no free-text
columns, each authorised on its source; `READER` on it to `${SA_EVE_ADVISOR}`; a dataset
`${EVE_ADVICE_DS}` with `WRITER` (dataset-level `bigquery.dataEditor`) to `${SA_EVE_ADVISOR}` and
**no entry for any control-path identity**. The job, its model access and its project are the
factory's and the Eve owner's build in `EVE_ADVISOR_PROJECT`, not steps of this runbook.

**Verify.**

```bash
# 1. the poll writes rows for the robot, and they include applications the sink lacks
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT application, COUNT(*) n FROM `eve_workspace_reports.activities`
   WHERE ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY) GROUP BY 1'
# table and column names follow the committed schema (tbd); expect rows for walle@'s shadow runs

# 2. eve_quality readers: exactly mo-metrics@ and the custodian, plus Eve's own owners
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_QUALITY_DS}" \
  | python3 -c "import json,sys;[print(a) for a in json.load(sys.stdin)['access']]"

# 3. on eve and every non-quality dataset: no userByEmail entry for mo-metrics@ or the custodian
for DS in eve eve_workspace_logs eve_workspace_reports "$EVE_RECEIPTS_DS"; do
  bq show --format=prettyjson "${EVE_PROJECT}:${DS}" 2>/dev/null \
    | python3 -c "import json,sys;print([a for a in json.load(sys.stdin).get('access',[]) if 'mo-' in json.dumps(a) or '$SA_VALIDATOR' in json.dumps(a)])"
done
# expect: [] each time (the mirror's dataset from S4 is the one Mo exception, Phase 11)

# 4. no control-path identity on eve_advice (if built)
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_ADVICE_DS}" 2>/dev/null \
  | grep -Ec 'eve-controller|eve-verifier|eve-console'
# expect: 0

# 5. eve-export@ holds create-only on exports/ and nothing destructive
gcloud storage buckets get-iam-policy "$EVE_EVIDENCE" --flatten='bindings[].members' \
  --filter="bindings.members:${SA_EVE_EXPORT}" --format='table(bindings.role,bindings.condition.title)'
# expect: objectViewer; objectCreator with exports-prefix-only. No objectAdmin, no delete.
```

**The drill (gate item G-7 of [05-stages.md](05-stages.md)).** On the sandbox tenant: a
tenant-integrity event by the robot's twin halts both lanes and pages the second human and the
desk in parallel through the witness channels; a roster change pages in both directions;
withholding the sink's rows past the window fires `log_pipeline_silent`; a withheld export fires
the witness alarm; a halt clear reaches the second human only. Record the drill in the witness.

**Rollback.** Delete the `eve-reports` schedule and the export job; remove the dataset access
entries added here; ask the witness administrators to remove their two grants. The locked
bucket keeps what was exported, which is the point. Rolling this phase back **re-opens the
super-admin gate**: Wall-E must not hold Super Admin without it.

---

## S4 entry — Eve gates

### Phase 11 — The key, the PEM, `eve-gate`, and Wall-E's edits

**Do not execute this phase until the S3 exit gate has passed at 100 %.** Twelve seeded
faults caught, both negative controls silent, ≥ 30 days of S3 running against real L3 batch
executions. The key is the only thing in this design that lets Eve make *more* happen, and
that is why it arrives last and on its own.

**The key, in Eve's project.**

```bash
gcloud services enable cloudkms.googleapis.com --project="$EVE_PROJECT"

gcloud kms keyrings create eve --location="$REGION" --project="$EVE_PROJECT"

gcloud kms keys create eve-approval \
  --keyring=eve --location="$REGION" --project="$EVE_PROJECT" \
  --purpose=asymmetric-signing \
  --default-algorithm=ec-sign-p256-sha256 \
  --protection-level=hsm
```

**HSM, added 2026-09-13** (platform HLD §8 "approval-authority keys … HSM protection level";
P118 sets `constraints/cloudkms.allowedProtectionLevels = HSM` at `fld-agentic-platform`, so a
software key is refused anyway). `--protection-level` takes `software`, `hsm`,
`hsm-single-tenant`, `external` or `external-vpc` and defaults to `software` (verified
2026-09-13, [gcloud kms keys create](https://docs.cloud.google.com/sdk/gcloud/reference/kms/keys/create)).
Everything else about the key — algorithm, one signer, the PEM exported before first use,
disable never destroy — is unchanged. HSM key versions are priced per version; the amount is
*tbd* (platform HLD §0.5).

**Export the PEM before first use.** Not after the first signature, not at the end of the
phase — before the key is ever used. A stored approval whose key version has since been
destroyed is verifiable only against an archived public key, and an approval that cannot be
verified is indistinguishable from one `walle-actions` minted itself. The stored signature
plus the archived PEM is the *only* artefact proving the service did not forge the approval.

```bash
export EVE_KEY_VERSION="projects/${EVE_PROJECT}/locations/${REGION}/keyRings/eve/cryptoKeys/eve-approval/cryptoKeyVersions/1"

gcloud kms keys versions get-public-key 1 \
  --key=eve-approval --keyring=eve --location="$REGION" --project="$EVE_PROJECT" \
  --output-file=./eve-approval-v1.pem

# copy 1: the keys/ prefix of the LOCKED evidence bucket Phase 9 already created
gcloud storage cp ./eve-approval-v1.pem "${EVE_KEYS}/eve-approval-v1.pem"

# copy 2: handed over to Wall-E. The commit lands in Wall-E's repository under
# ladder.yaml's CODEOWNERS and is Wall-E's runbook's step (CC-21): Eve's runbook exports
# the PEM and hands it over; the merge needs two reviewers and must precede the first
# signature. What Wall-E's side does with it, for reference:
#   cp ./eve-approval-v1.pem wall-e/contracts/eve-public-keys/1.pem
#   git -C wall-e add contracts/eve-public-keys/1.pem
#   git -C wall-e commit -m "eve-approval public key, version 1, exported at creation"
#   ... then a pull request with two distinct approving reviewers, neither the author.
```

Do not sign until that pull request is merged: a signature that exists before the pinned
copy does is one the primary path cannot verify.

**One bucket, not two.** The archive is a prefix of the locked evidence bucket from Phase 9,
not a bucket of its own. A fresh bucket would be an ordinary bucket: every project owner and
every `roles/storage.objectAdmin` could overwrite or delete the PEM, and per-object retention
cannot be turned on from gcloud after creation — "Existing buckets can only enable the
feature using the Google Cloud console" ([Object Retention
Lock](https://docs.cloud.google.com/storage/docs/object-lock), verified 2026-09-12). The
evidence bucket already carries the guarantee this archive needs and carries it *locked*: a
locked retention policy cannot be shortened or removed, objects cannot be deleted or
replaced before expiry even by a project owner, and the lien prevents the project being
deleted. Ordering works out — the bucket lands at S3 entry, the key at S4 entry, so the
destination exists before the first PEM does.

Two copies, deliberately. The bucket copy survives a repository accident; the repository
copy is what `walle-actions` compiles in for **offline pinned-PEM verification as the
primary path**. That path is strictly stronger than a live `getPublicKey`: no IAM grant
inside Wall-E's project can substitute a key, a KMS outage does not stop verification, and a
destroyed key version never orphans a stored approval. KMS is the fallback only.

**The two roles, and the two that must never be granted.**

```bash
gcloud kms keys add-iam-policy-binding eve-approval \
  --keyring=eve --location="$REGION" --project="$EVE_PROJECT" \
  --member="serviceAccount:${SA_EVE}" --role=roles/cloudkms.signer

gcloud kms keys add-iam-policy-binding eve-approval \
  --keyring=eve --location="$REGION" --project="$EVE_PROJECT" \
  --member="serviceAccount:${SA_ACTIONS}" --role=roles/cloudkms.publicKeyViewer
```

`walle-actions@<WALLE_PROJECT>` gets `publicKeyViewer` and **nothing else, ever** — on this
one key in `EVE_PROJECT`, a key-level, cross-project grant for the **fallback path only**,
and one of the three resource-level grants to Wall-E principals in `EVE_PROJECT` (topology
decision 48, row 14). Never ring- or project-level. The pinned PEM is the primary path and
needs no cross-project KMS grant at all, so this binding may be omitted entirely if the
fallback is not wanted. Never `roles/cloudkms.signerVerifier` and never
`roles/cloudkms.cryptoOperator`: both carry `useToSign`, and either would let the action
service mint the approval it is supposed to verify. `eve-verifier@` appears in neither
binding.

**Data Access audit logging on the signature.** `AsymmetricSign` requires
`cloudkms.cryptoKeyVersions.useToSign`, which is typed `DATA_READ`, so it is a Data Access
log and is **off by default** ([Cloud KMS audit
logging](https://docs.cloud.google.com/kms/docs/audit-logging), verified 2026-09-12). Turn
it on, along with IAP's:

```bash
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json > /tmp/eve-policy.json

python3 - <<'EOF'
import json
p = json.load(open('/tmp/eve-policy.json'))
cfgs = {c['service']: c for c in p.get('auditConfigs', [])}
for svc in ('cloudkms.googleapis.com', 'iap.googleapis.com'):
    c = cfgs.setdefault(svc, {'service': svc, 'auditLogConfigs': []})
    have = {x['logType'] for x in c['auditLogConfigs']}
    for t in ('DATA_READ', 'DATA_WRITE'):
        if t not in have:
            c['auditLogConfigs'].append({'logType': t})
p['auditConfigs'] = list(cfgs.values())
json.dump(p, open('/tmp/eve-policy.json', 'w'))
EOF

gcloud projects set-iam-policy "$EVE_PROJECT" /tmp/eve-policy.json
```

Without this, the record of every signature Eve ever produced does not exist, and the KMS
log is one of the two things that recovers human attribution for the L4 case.

**`eve-gate`**, the fourth entrypoint of the same image, deployed as its own Cloud Run job
so that only its identity holds `signer`:

```bash
gcloud run jobs deploy eve-gate \
  --project="$EVE_PROJECT" --region="$REGION" \
  --image="${EVE_AR}/reconciler" \
  --service-account="$SA_EVE" \
  --args=gate \
  --tasks=1 --max-retries=0 --task-timeout=300s \
  --set-env-vars="^;^EVE_PROJECT=${EVE_PROJECT};WALLE_PROJECT=${WALLE_PROJECT};ACTIONS_URL=<actions-url>;EVE_KEY_VERSION=${EVE_KEY_VERSION};REFRESH_TOKEN_SECRET=eve-refresh-token;EVE_TOKEN_VERSION=${EVE_TOKEN_VERSION}"

# eve-gate-poll runs AS eve-controller@; same resource-scoped actAs grant as Phase 10.
gcloud iam service-accounts add-iam-policy-binding "$SA_EVE" \
  --project="$EVE_PROJECT" \
  --member="user:$(gcloud config get-value account)" \
  --role=roles/iam.serviceAccountUser

gcloud scheduler jobs create http eve-gate-poll \
  --project="$EVE_PROJECT" --location="$REGION" --schedule="*/2 * * * *" \
  --uri="https://run.googleapis.com/v2/projects/${EVE_PROJECT}/locations/${REGION}/jobs/eve-gate:run" \
  --http-method=POST \
  --oauth-service-account-email="$SA_EVE" \
  --attempt-deadline=30s --max-retry-attempts=0
```

`--max-retries=0` on the job, not 1. A retried gate task would re-sign, and a second
envelope for the same plan is a second authorisation.

`eve-gate` discovers work by polling Firestore `plans/{id}` for `state == pending_eve` and
then fetching the body from `GET /v1/plans/{id}`. No topic, no subscription, no endpoint —
Eve is a client everywhere, which is what makes "Eve is down" an absence and what makes it
structurally impossible for a safety interlock to run through a conversation.

**The existence-only receipt view**, the one thing `walle-actions` may read from Eve. An
authorized view **must live in a different dataset from its source**, in the same location
(verified 2026-09-13, https://docs.cloud.google.com/bigquery/docs/authorized-views: "Create a
dataset to contain your authorized view"; "the source data dataset and authorized view
dataset must be in the same regional location"), so it cannot sit in `eve`. Three steps:
create the view's own dataset in `EVE_PROJECT`; add the view to the `eve` dataset's access
list as an authorized view (a `view` entry in the access array, via `bq update --source`, or
the console's Sharing > Authorize views); grant `walle-actions@` `dataViewer` on the view's
dataset — nothing on `eve`.

```bash
# 1. the view's own dataset. Name tbd (topology decision 48); Assumption: eve_receipts.
bq --location="$BQ_LOCATION" mk --dataset \
  --description="Existence-only verdict receipts for walle-actions; authorized on eve" \
  "${EVE_PROJECT}:${EVE_RECEIPTS_DS}"

bq mk --use_legacy_sql=false --view \
  "SELECT run_id, item, verdict_ts FROM \`${EVE_PROJECT}.eve.verdicts\`" \
  "${EVE_PROJECT}:${EVE_RECEIPTS_DS}.verdict_receipts"

# 2. authorize the view on the eve dataset: a 'view' entry in eve's access array
bq show --format=prettyjson "${EVE_PROJECT}:eve" > /tmp/eve.json
P="$EVE_PROJECT" D="$EVE_RECEIPTS_DS" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/eve.json'))
d.setdefault('access', []).append({"view": {"projectId": os.environ['P'],
                                            "datasetId": os.environ['D'],
                                            "tableId": "verdict_receipts"}})
json.dump(d, open('/tmp/eve.json', 'w'))
EOF
bq update --source=/tmp/eve.json "${EVE_PROJECT}:eve"

# 3. walle-actions@<WALLE_PROJECT> reads the view's dataset and nothing on eve.
#    Dataset-level READER on the view's dataset — one of the three resource-level grants
#    to Wall-E principals in EVE_PROJECT (topology decision 48, row 15). The query jobs
#    for that read run in WALLE_PROJECT under walle-actions@'s own job-creation right
#    there (SETUP Phase 8: a custom role carrying bigquery.jobs.create if load jobs are
#    used, never roles/bigquery.jobUser, which walle-actions@ does not hold).
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_RECEIPTS_DS}" > /tmp/receipts.json
SA="$SA_ACTIONS" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/receipts.json'))
d.setdefault('access', []).append({"role": "READER", "userByEmail": os.environ['SA']})
json.dump(d, open('/tmp/receipts.json', 'w'))
EOF
bq update --source=/tmp/receipts.json "${EVE_PROJECT}:${EVE_RECEIPTS_DS}"
```

Three columns and no verdict content. The service checks that evidence **arrived** and can
never branch on what it says. That narrowing is the whole of [E-17](09-open-decisions.md),
and it is re-argued at this phase rather than assumed: a compromised Eve can still write
false receipts and suppress the evidence-stale sweeper, which is exactly why that sweeper is
absence-only and why the blind sample, not Eve, is the precision input.

**The one Mo carve-out: `mo-metrics@${MO_PROJECT}` reads the mirror, from S4.** Topology
row 18 and decision 51 make Eve's `walle_audit_mirror` the off-project evidence copy that
Mo reads from S4 instead of the live dataset ([../mo/08-open-decisions.md](../mo/08-open-decisions.md)
M-5), so Wall-E's deployers cannot rewrite the evidence Mo argues from. The grant is
dataset-level `READER`, made by Eve's owner, on **the mirror's dataset only** — and a
dataset-level `READER` covers every table in the dataset, so the mirror leaves `eve` first
(which holds `verdicts`, `findings` and the blind tables) for a dataset of its own,
`${EVE_MIRROR_DS}` (`eve_audit_mirror`, named 2026-09-13; it was `Assumption:` `eve_mirror`,
renamed because `eve_mirror` is the witness's dataset in `EVE_WITNESS_PROJECT`, decision 51). This is the one
entry of a second carve-out list, next to the three Wall-E ones (two entries since 2026-09-13:
`eve_quality` is the second, Phase 10b); the drift job of Phase 12
expects exactly it from S4 and fails on any other Mo principal, or on this one before S4.

```bash
# 4. the mirror's own dataset, and the daily copy retargeted to it
bq --location="$BQ_LOCATION" mk --dataset \
  --description="Append-only daily copy of walle_audit; read by Eve and, from S4, by mo-metrics@" \
  --default_partition_expiration=34560000 \
  "${EVE_PROJECT}:${EVE_MIRROR_DS}"
bq cp "${EVE_PROJECT}:eve.walle_audit_mirror" "${EVE_PROJECT}:${EVE_MIRROR_DS}.walle_audit_mirror"
# Retarget the Phase 3 daily copy job's destination to ${EVE_MIRROR_DS}.walle_audit_mirror
# (its transfer config's destination dataset), run it once by hand, compare row counts per
# partition between the two tables, THEN drop eve.walle_audit_mirror. Nothing of Eve's own
# (verdicts, findings, the blind views) lives in ${EVE_MIRROR_DS}.

# 5. mo-metrics@<MO_PROJECT>: dataset-level READER on the mirror's dataset, nothing on eve.
#    The query jobs run and are billed in MO_PROJECT (jobUser there, Mo-2), never here.
bq show --format=prettyjson "${EVE_PROJECT}:${EVE_MIRROR_DS}" > /tmp/mirror.json
SA="$SA_MO_METRICS" python3 - <<'EOF'
import json, os
d = json.load(open('/tmp/mirror.json'))
entry = {"role": "READER", "userByEmail": os.environ['SA']}
if entry not in d.setdefault('access', []):
    d['access'].append(entry)
json.dump(d, open('/tmp/mirror.json', 'w'))
EOF
bq update --source=/tmp/mirror.json "${EVE_PROJECT}:${EVE_MIRROR_DS}"
# expect, on eve itself: no userByEmail entry for mo-metrics@ — ever.
# Narrowed 2026-09-13 (platform HLD section 18 item 17): "ever" holds for eve and every
# non-quality dataset (eve_workspace_logs, eve_workspace_reports, the receipts dataset, the
# advisor datasets). mo-metrics@ holds dataset-level READER on exactly two Eve datasets: this
# mirror's dataset from S4, and eve_quality from Wall-E's Stage 1 (Phase 10b step 5).
bq show --format=prettyjson "${EVE_PROJECT}:eve" \
  | python3 -c "import json,sys;print([a for a in json.load(sys.stdin)['access'] if 'mo-' in json.dumps(a)])"
# expect: []
```

`Assumption:` the mirror carries only the columns Mo reads (`params_redacted` included,
which is the disclosure Mo's [06-failure-modes.md](../mo/06-failure-modes.md) already
owns for the live dataset); if the S4 review narrows Mo's read further, the narrowing is a
view in `${EVE_MIRROR_DS}` authorized on itself, not a change to this grant. Eve's own
readers of the mirror (`eve-v0@`, `eve-verifier@`, `eve-console@`) keep their `eve`-level
roles and gain the same role on `${EVE_MIRROR_DS}`; that is inside Eve's project and
crosses nothing.

**Wall-E's edits, landing with this phase.** Every one is in
[08-contract-changes.md](08-contract-changes.md):

| Edit | Where |
|---|---|
| Signature verification against the pinned PEM, with the full key-version resource name taken from the envelope | `walle-actions` |
| Per-item accept/reject vector verification against `items_hash` | `walle-actions` |
| `eve_authority` enforced per cell; absent reads as **advisory**; an Eve signature for an advisory cell is refused `eve_authority_advisory` | `walle-actions`, `ladder.yaml` schema |
| The `${EVE_RECEIPTS_DS}.verdict_receipts` read (the receipts dataset, never `eve`), wired to `eve_evidence_stale` | `walle-actions` |
| `eve_key_version` and `approver_type` columns on the `approvals` row | `walle_audit` schema, [03-lld.md](../wall-e/03-lld.md) |
| An Eve-rejected item becomes `skipped_by_operator` with `approver_type: eve` — not a new state | [03-lld.md](../wall-e/03-lld.md) |

**A cell only becomes binding by pull request.** `eve_authority: binding` requires two
distinct authenticated approving reviewers, neither the author. Absent reads as advisory.
That one field is the per-cell load-bearing switch, the fail-closed default, and the
demotion target when an Eve approval is overturned. The CI validator refuses any
configuration placing a cell at L4 while its authority is advisory.

**Key rotation is a dated manual procedure.** Cloud KMS does not support automatic rotation
for asymmetric keys, because the new public key must be distributed before it can be used
([Key rotation](https://docs.cloud.google.com/kms/docs/key-rotation), verified 2026-09-12).
So: annually, and on suspicion, with a **30-day overlap**, each new version's PEM exported
at creation into both places, and old versions **disabled, never destroyed** inside the
400-day evidence horizon. Put the date in a calendar; nothing will remind you.

**Verify.**

```bash
# 1. algorithm, location and protection level
gcloud kms keys describe eve-approval --keyring=eve --location="$REGION" \
  --project="$EVE_PROJECT" \
  --format='value(purpose,versionTemplate.algorithm,versionTemplate.protectionLevel)'
# expect: ASYMMETRIC_SIGN  EC_SIGN_P256_SHA256  HSM   (HSM added 2026-09-13)

# 2. exactly two principals on the key, with exactly those two roles
gcloud kms keys get-iam-policy eve-approval --keyring=eve --location="$REGION" \
  --project="$EVE_PROJECT" --flatten='bindings[].members' \
  --format='table(bindings.role,bindings.members)'
# expect: eve-controller@ signer; walle-actions@ publicKeyViewer.
# If signerVerifier or cryptoOperator appears anywhere, stop and remove it.

# 3. eve-verifier@ cannot sign. Prove it rather than read it.
gcloud kms asymmetric-sign --version=1 --key=eve-approval --keyring=eve \
  --location="$REGION" --project="$EVE_PROJECT" \
  --digest-algorithm=sha256 --input-file=/dev/null --signature-file=/dev/null \
  --impersonate-service-account="$SA_EVE_VERIFIER"
# expect: PERMISSION_DENIED

# 4. the PEM archive exists in both places, and matches the live key
gcloud storage cat "${EVE_KEYS}/eve-approval-v1.pem" | sha256sum
sha256sum wall-e/contracts/eve-public-keys/1.pem
gcloud kms keys versions get-public-key 1 --key=eve-approval --keyring=eve \
  --location="$REGION" --project="$EVE_PROJECT" | sha256sum
# expect: three identical digests

# 4b. and the bucket copy is under the LOCKED policy, not an ordinary object
gcloud storage objects describe "${EVE_KEYS}/eve-approval-v1.pem" --format='value(name)'
# expect: keys/eve-approval-v1.pem
gcloud storage buckets describe "$EVE_EVIDENCE" \
  --format='value(retentionPolicy.isLocked,retentionPolicy.retentionPeriod)'
# expect: True  34560000
# If isLocked is False the archive is deletable and the forgery argument does not hold.

# 5. the receipt view exposes three columns and nothing else, lives outside eve, is
#    authorized on eve, and walle-actions@ holds nothing on eve itself
bq show --schema --format=prettyjson "${EVE_PROJECT}:${EVE_RECEIPTS_DS}.verdict_receipts" \
  | python3 -c "import json,sys;print([f['name'] for f in json.load(sys.stdin)])"
# expect: ['run_id', 'item', 'verdict_ts']
bq show --format=prettyjson "${EVE_PROJECT}:eve" \
  | python3 -c "import json,sys;[print(a) for a in json.load(sys.stdin)['access'] if 'view' in a or 'walle-actions' in json.dumps(a)]"
# expect: exactly one entry, the view entry naming ${EVE_RECEIPTS_DS}.verdict_receipts;
#         no userByEmail entry for walle-actions@

# 6. Data Access logging is on for KMS
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json \
  | python3 -c "import json,sys;print([c for c in json.load(sys.stdin).get('auditConfigs',[]) if 'kms' in c['service']])"
# expect: cloudkms.googleapis.com with DATA_READ

# 7. end to end, in the sandbox: one plan approved, one refused, one vetoed
python tests/eve_gate_e2e.py --sandbox
```

Test 7 must show a signed approval accepted by `walle-actions`, a refusal leaving the item
waiting for a human, and an operator veto beating a signature Eve already produced. **Veto
wins, unconditionally** — and the vetoed item enters the blind sample pool at the next draw
regardless of rate, because a veto is the strongest available signal about Eve's precision.

**Rollback.** Delete the scheduler job and `eve-gate`; **disable** the key version, never
destroy it:

```bash
gcloud scheduler jobs delete eve-gate-poll --project="$EVE_PROJECT" --location="$REGION"
gcloud run jobs delete eve-gate --project="$EVE_PROJECT" --region="$REGION"
gcloud kms keys versions disable 1 --key=eve-approval --keyring=eve \
  --location="$REGION" --project="$EVE_PROJECT"
```

Every L4 step then stalls **closed**: plans sit at `pending_eve`, `eve_silence` sets
`no_autonomous` after four business hours, and only an operator clears it. Revoking
`run.invoker` from `eve-controller@` is the faster containment step if the reason for
rolling back is a suspected compromise rather than a defect.

---

## At every stage

### Phase 12 — The teardown guard and the denial suite

#### The teardown guard

[`setup/walle_setup.py`](../wall-e/setup/walle_setup.py) offers
`teardown --destroy-key-versions`, which destroys Eve's KMS key versions. Destroying a key
version inside the 400-day evidence horizon makes every stored approval signed by it
unverifiable — unless the PEM was archived. **The guard is a precondition check, not a
warning:**

```python
# in walle_setup.py, before the --destroy-key-versions branch runs
def _pem_archive_present(ctx, version_number: str) -> bool:
    """Refuse to destroy a key version whose public key was never exported."""
    bucket = "%s-eve-evidence" % ctx.need("EVE_PROJECT")
    committed = "contracts/eve-public-keys/%s.pem" % version_number
    return (gcs_object_exists(ctx, bucket, "keys/eve-approval-v%s.pem" % version_number)
            and pathlib.Path(committed).is_file())
```

If it returns false, teardown must **refuse the flag and exit non-zero**, naming the
version and both expected paths. Not prompt, not warn — refuse. The operator running
teardown is by definition not thinking about evidence retention.

**Who may run it, decided 2026-09-13 with the topology (decision file *tbd*).** The key
lives in `EVE_PROJECT`, so destroying a version is a cross-project act from Wall-E's
script's point of view, and under least privilege it is **not Wall-E's teardown's to do as
a Wall-E identity**: no Wall-E service identity holds, or may ever hold, `cloudkms.admin`
on Eve's key ring. The flag stays in `walle_setup.py` because the guard code is there
(CC-21), but it targets `EVE_PROJECT` (the `ctx.need("EVE_PROJECT")` above) and runs
**only as a human holding `roles/cloudkms.admin` on ring `eve` in `EVE_PROJECT`** — the Eve
owner — with Wall-E's repository checked out for the second copy. The alternative, moving
key-version destruction into an Eve-side teardown with the same two-copy guard, was
considered and set aside so the guard has one implementation; it is reopened if the two
owner groups of [E-2](09-open-decisions.md) become different people. The guard logic itself
is unchanged.

Two other teardown facts worth writing down before they are discovered:

- From Phase 7, an **organisation-level sink outlives the project**. Delete
  `eve-workspace-audit` before deleting anything else, or it keeps exporting to a
  destination that no longer exists.
- From Phase 9, the **locked evidence bucket applies a lien preventing project deletion**.
  `gcloud projects delete` will fail until the retention period expires. This is not a bug
  to route around.

**Verify.**

```bash
python setup/walle_setup.py teardown --destroy-key-versions --dry-run
# with the PEM archive intact:  lists the versions it would destroy
# with either copy removed:     refuses, exit code non-zero, names the missing path
```

#### The denial suite Eve's side authors

Wall-E's suite in [SETUP.md](../wall-e/SETUP.md) section 4 already contains tests 4, 5, 6
and 52, exercised from the first commit by the CI-only stub caller of Phase 6. These are
the additional ones Eve's build owns. The numbering is this document's own.

| # | Test | Expected |
|---|---|---|
| **EVE-1** | `eve-controller@` calls `POST /v1/execute` | **403.** Eve never executes. |
| **EVE-2** | `eve-verifier@` calls `POST /v1/plans/{id}/approve` | Denied. Only the gate identity signs, and the verifier holds no key. |
| **EVE-3** | `eve-verifier@` calls KMS `AsymmetricSign` on `eve-approval` | `PERMISSION_DENIED` at Google's end, not at Eve's |
| **EVE-4** | An operator ID token calls `POST /v1/control/halt` | **Accepted.** The half of the allowlist that fails silently. |
| **EVE-5** | An envelope signed over a `plan_hash` the service reported, rather than one Eve recomputed | Rejected in CI by the call-graph test: `sign_envelope()` is reachable only from `verdict_for_plan()` |
| **EVE-6** | An envelope missing `items_hash` | `bad_approval` |
| **EVE-7** | A valid signature for a cell whose `eve_authority` is advisory or absent | `denied: eve_authority_advisory` |
| **EVE-8** | A valid signature whose `issued_at` is more than 120 seconds off | `bad_approval` — refused, never silently accepted and never silently expired |
| **EVE-9** | A valid signature for a plan whose hold window elapsed during an outage | Refused. The plan is expired; Eve never resumes it. |
| **EVE-10** | An approval replayed after the key version was disabled | Still **verifiable** against the archived PEM, and still refused as used |
| **EVE-11** | A verdict carrying a reason code absent from `reasons.yaml` | Rejected before signing |
| **EVE-12** | `walle-actions@` reads `eve.verdicts` directly, or any table in `eve` | Denied. Only the `verdict_receipts` view's own dataset (`${EVE_RECEIPTS_DS}`) is granted; `walle-actions@` holds nothing on `eve`. |
| **EVE-13** | An Eve image built with any denylisted model dependency in its lockfile | CI build fails |
| **EVE-14** | Either Eve identity holding any `aiplatform.*` permission | CI IAM assertion fails |
| **EVE-15** | A display name containing bidirectional overrides or zero-width characters reaching a veto notification | Canonicalised before comparison **and** before display: control characters stripped, whitespace collapsed, length capped, markdown escaped |
| **EVE-16** (added 2026-09-13) | `eve-advisor@` writes to `eve.verdicts`, `eve.incidents` directly or `eve/config`, or calls any action service | Denied: it holds `dataEditor` on `eve_advice` only, no invoker, no git write |
| **EVE-17** (added 2026-09-13) | Any control-path identity reads `eve_advice` | Denied; CI assertion on the access list fails |
| **EVE-18** (added 2026-09-13) | `eve-approval` created or re-created without `--protection-level=hsm` | Refused by the folder constraint `cloudkms.allowedProtectionLevels`; Phase 11 verify 1 fails |
| **EVE-19** (added 2026-09-13) | The sink's rows withheld past the H-1 window, or Eve's token revoked | `log_pipeline_silent`: `no_autonomous` for Eve's agents and `halt_all` on `walle-actions` **and** `walle-actions-super`; severity-1 page through the witness; a human clear reported to the second human only |
| **EVE-20** (added 2026-09-13) | A robot-attributed event in a non-Admin stream with no `walle_audit` or band-B row | `reconciliation_gap`, halt |
| **EVE-21** (added 2026-09-13) | A fourth super admin added, or a roster account's role removed | `role_assignment_added` / `role_assignment_missing`, severity 1, in both directions |
| **EVE-22** (added 2026-09-13) | `mo-metrics@` or the validator custodian queries any Eve dataset other than `eve_quality` (and, for `mo-metrics@` from S4, the mirror) | Denied |

EVE-3, EVE-12, EVE-13 and EVE-14 are the four mechanical enforcements of the deterministic
boundary expressed as tests. They are the ones to re-run after every IAM change and every
dependency bump, because they are the ones that decay quietly.

**Rollback.** Not applicable. These are tests.

---

## The manual console steps, in one list

Everything below needs a human in a browser. There is no API for any of it. Collect them
before starting a sitting, because each one is a place where a half-finished phase strands
you.

| Phase | Console | Step |
|---|---|---|
| 1 | GCP | Link the billing account, if your organisation does not allow it from the CLI |
| 7 | GCP / organisation | **Obtain organisation-level `roles/logging.configWriter`.** The one step with a lead time outside your control. |
| 8 | Workspace Admin | Create `eve@<domain>` in `/Automation/Service Identities` |
| 8 | Workspace Admin | Create the custom admin role `Eve — Verifier`, read privileges only |
| 8 | Workspace Admin | Assign it customer-scoped |
| 8 | Workspace Admin | Enforce 2SV, hardware key only; register the key; no recovery options; short session |
| 8 | Workspace Admin | Create the second login reporting rule on actor `eve@<domain>` |
| 8 | Workspace Admin | Add `eve@<domain>` to `walle-protected@` |
| 8 | GCP (Eve's project) | OAuth consent screen: Internal, In production |
| 8 | GCP (Eve's project) | Create a **new, separate** Desktop OAuth client |
| 8 | Workspace Admin | API controls → App access control → mark the new client **Trusted**, same sitting |
| 8 | Browser, clean profile | The one interactive consent, as `eve@<domain>`, with the frozen scope list |
| 10 | GCP | Add the notification channel for `walle-operators@` to the absence policy |
| 11 | git | Merge the pull request that sets a cell's `eve_authority: binding` — two distinct approving reviewers, neither the author |
| 10b (added 2026-09-13) | Witness tenant (IT security) | Create `org-witness`, `EVE_WITNESS_PROJECT`, the retention-locked bucket and `eve_mirror`; grant `eve-export@` its two create-only roles; set the severity 1/2 notification channels to individuals (SMS, mobile app, PagerDuty/webhook); Access Approval and Access Transparency on |
| 10b (added 2026-09-13) | Workspace Admin | Confirm `eve@`'s role carries the domain and customer settings read privileges resolved with `privileges.list`, and no write |
| 10b (added 2026-09-13) | Workspace Admin | Create the `eve-console` IAP audience group (name *tbd*); its membership changes are a severity-1 rule |

The password and the hardware key go into the corporate vault and the safe. Neither value
appears in this wiki, in a ticket, or in a chat message — only the statement that they
exist and where they live.

---

## What to do when a step half-fails

Most of this runbook is idempotent. Four steps are not, and the five ways they half-fail
are the ones worth knowing before you start.

| Step | If it half-fails | Do this |
|---|---|---|
| **Phase 8 consent** | A token is stored with the wrong scope set | **Redo all of Phase 8 from step 6.** Scopes freeze at consent. Widening them means a new client, a new consent and a new Trusted-client marking. Revoke the old grant at `myaccount.google.com/permissions` first, then destroy the secret version, then re-consent. The version number will not be 1 — re-export `EVE_TOKEN_VERSION` and redeploy both jobs, or they stay pinned to a destroyed version and fail with an `invalid_grant` that points at nothing. |
| **Phase 9 bucket lock** | `--lock-retention-period` ran with the wrong period | **Nothing.** It cannot be shortened and it cannot be removed. A longer period can be set. If the period is too short, create a second bucket with the correct period and repoint `EVIDENCE_BUCKET`; leave the first to expire. |
| **Phase 7 sink** | Created with an actor exclusion copied from Wall-E's | Delete and recreate. Do **not** patch the filter in place and assume the backfill catches up — it does not. The rows for the excluded actor between creation and correction are permanently missing from Eve's copy, and the audit-completeness metric will be quietly wrong for that window. Record the gap. |
| **Phase 7 sink** | Created without `--use-partitioned-tables`, so the destination is a series of `cloudaudit_googleapis_com_activity_YYYYMMDD` tables and verify step 3 fails Not-found | Recreate the sink with the flag; that is fixable in place and takes effect from then on. **The already-written sharded tables stay sharded** — the same non-backfill property as the actor-exclusion row above. They also carry no partition expiry, so either delete them once their window is outside the evidence horizon or set an expiry on each. Set the dataset's `--default_partition_expiration` before recreating, or the new partitioned table inherits nothing. Record the window in which Eve's copy is sharded, because a query written against the unsuffixed name reads zero rows for it rather than erroring. |
| **Phase 11 key** | The key version was used before the PEM was exported | Export it immediately; it is still exportable while the version is enabled. If the version has been **destroyed** without an export, every approval it signed is permanently unverifiable. Treat that as a severity 2 incident: the family goes to L0, `eve_authority` for it goes to advisory, and the affected window is named in every future attestation touching it. |

Three general rules for a half-failed step anywhere in this runbook:

1. **Never work around a fail-closed refusal.** If `walle-actions` is denying because
   Firestore is unreachable, or because an override is unreadable, or because the ladder
   artefact is missing, the refusal is the design. Fix the cause.
2. **Re-run the verification block of the previous phase before re-running the current
   one.** Half-failures cascade quietly, and the previous phase's checks are cheap.
3. **If a phase leaves an identity that exists but holds nothing, delete it rather than
   leaving it.** An orphan `eve-*@` service account is a name an attacker can ask for
   bindings on, and a name a future reader will assume is load-bearing.

---

## Verified facts used in this runbook

All checked 2026-09-12 unless the row says 2026-09-13. Anything not in this table and not
in the skeleton this page was written from is `tbd` rather than assumed.

| Fact | Source |
|---|---|
| BigQuery scheduled queries run as the creating user's credentials unless `--service_account_name` is given, and a query scheduled exactly on the hour may trigger more than once | [Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries) |
| An organisation-level aggregated sink may route to a BigQuery dataset in another project; its writer identity needs `roles/bigquery.dataEditor` there | [Aggregated sinks](https://docs.cloud.google.com/logging/docs/export/aggregated_sinks) |
| A BigQuery sink writes **date-sharded** tables by default — "The default selection is a date-sharded table", suffixed `YYYYMMDD` — and `--use-partitioned-tables` is what makes it one partitioned table instead | [Route logs to BigQuery](https://docs.cloud.google.com/logging/docs/export/bigquery), [gcloud logging sinks create](https://docs.cloud.google.com/sdk/gcloud/reference/logging/sinks/create) |
| `bq update --default_partition_expiration` sets "the default lifetime, in seconds, for partitions in **newly created** partitioned tables", so it must precede the table's creation | [Updating datasets](https://docs.cloud.google.com/bigquery/docs/updating-datasets) |
| `roles/iam.serviceAccountUser` carries `iam.serviceAccounts.actAs` and is the role that attaches a service account to a resource; `roles/iam.serviceAccountTokenCreator` carries `getAccessToken`, `getOpenIdToken`, `signBlob`, `signJwt` and `implicitDelegation`, and **not** `actAs`. Whoever created the service account already holds `actAs` | [Service account permissions](https://docs.cloud.google.com/iam/docs/service-account-permissions), [Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries), [Cloud Scheduler HTTP target auth](https://docs.cloud.google.com/scheduler/docs/http-target-auth) |
| Only Access Transparency, Admin Audit, Enterprise Groups Audit, Login Audit, OAuth Token Audit and SAML Audit export to Cloud Logging. **There is no Calendar audit stream.** | [Workspace audit logs](https://docs.cloud.google.com/logging/docs/audit/gsuite-audit-logging) |
| `ADD_GROUP_MEMBER` and `REMOVE_GROUP_MEMBER` are `GROUP_SETTINGS` events under `applicationName=admin`, so Directory-API group-member writes land in the **Admin** audit log | [Admin group settings events](https://developers.google.com/workspace/admin/reports/v1/appendix/activity/admin-group-settings) |
| Per-object retention can be enabled at bucket creation with `--enable-per-object-retention`; on an existing bucket it can "only enable the feature using the Google Cloud console", and once enabled "cannot be disabled on a bucket" | [Object Retention Lock](https://docs.cloud.google.com/storage/docs/object-lock) |
| A Cloud Run **job** task may run up to 168 hours; a Cloud Run **service** request is capped at 60 minutes | [Cloud Run task timeout](https://docs.cloud.google.com/run/docs/configuring/task-timeout) |
| Cloud Scheduler invokes a Cloud Run job with an **OAuth** token against `run.googleapis.com`, not OIDC | [Run jobs on a schedule](https://docs.cloud.google.com/run/docs/execute/jobs-on-schedule) |
| The Cloud Run jobs `:run` request body accepts `overrides.containerOverrides[].args` | [projects.locations.jobs.run](https://docs.cloud.google.com/run/docs/reference/rest/v2/projects.locations.jobs/run) |
| Cloud KMS does **not** support automatic rotation for asymmetric keys | [Key rotation](https://docs.cloud.google.com/kms/docs/key-rotation) |
| `AsymmetricSign` needs `cloudkms.cryptoKeyVersions.useToSign`, typed `DATA_READ`, so it is a Data Access log and off by default | [Cloud KMS audit logging](https://docs.cloud.google.com/kms/docs/audit-logging) |
| A locked retention policy cannot be removed or shortened; retention locking applies a lien preventing project deletion | [Bucket Lock](https://docs.cloud.google.com/storage/docs/using-bucket-lock), [Object Retention Lock](https://docs.cloud.google.com/storage/docs/object-lock) |
| IAP can be enabled directly on a Cloud Run service with `--iap`, with the IAP service agent granted `roles/run.invoker` and access granted through `roles/iap.httpsResourceAccessor` | [IAP for Cloud Run](https://docs.cloud.google.com/run/docs/securing/identity-aware-proxy-cloud-run) |
| BigQuery Data Transfer Service writes logs under the monitored resource type `bigquery_dts_config` | [Monitor BigQuery Data Transfer Service](https://docs.cloud.google.com/bigquery/docs/dts-monitor) |
| `gcloud projects create` takes `--folder=FOLDER_ID`, "ID for the folder to use as a parent", as the alternative to `--organization` (verified 2026-09-13) | [gcloud projects create](https://docs.cloud.google.com/sdk/gcloud/reference/projects/create) |
| An authorized view must live in a **different dataset** than the dataset its query reads, and the two datasets must be in the same regional location; a principal querying it needs `dataViewer` on the view's dataset and nothing on the source (verified 2026-09-13) | [Authorized views](https://docs.cloud.google.com/bigquery/docs/authorized-views) |
| `gcloud resource-manager folders get-iam-policy FOLDER_ID` reads a folder's IAM policy and takes `--flatten`, `--filter` and `--format` (verified 2026-09-13); a project-level `get-iam-policy` does not show bindings inherited from the folder | [gcloud resource-manager folders get-iam-policy](https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/folders/get-iam-policy) |
| Firestore supports IAM Conditions scoped to one or more databases; the per-database condition **expression is unverified** (topology decision 44) | [Firestore IAM](https://docs.cloud.google.com/firestore/docs/security/iam) |
| `activities.list` accepts `applicationName` values including `admin`, `login`, `token`, `saml`, `groups`, `groups_enterprise`, `user_accounts`, `rules`, `context_aware_access`, `gcp`, `drive`, `vault`, `takeout`, `admin_data_action`, `data_studio`; scope `admin.reports.audit.readonly`; `userKey` may be a primary email (verified 2026-09-13) | [activities.list](https://developers.google.com/workspace/admin/reports/reference/rest/v1/activities/list) |
| `admin.directory.domain.readonly` and `admin.directory.customer.readonly` are Directory API scopes (verified 2026-09-13) | [Directory API scopes](https://developers.google.com/workspace/admin/directory/v1/guides/authorizing) |
| `privileges.list` is `GET …/customer/{customer}/roles/ALL/privileges` with `admin.directory.rolemanagement.readonly` (verified 2026-09-13) | [privileges.list](https://developers.google.com/workspace/admin/directory/reference/rest/v1/privileges/list) |
| Only a super administrator can use the Cloud Identity Policy API (verified 2026-09-13) — so Eve reads no settings state through it | [Policy API overview](https://docs.cloud.google.com/identity/docs/concepts/overview-policies) |
| Workspace audit service names in Cloud Logging: admin `admin.googleapis.com`, enterprise groups `cloudidentity.googleapis.com`, login and SAML `login.googleapis.com`, OAuth token `oauth2.googleapis.com`; Access Transparency's service name is not stated on the page (verified 2026-09-13) | [Workspace audit logs](https://docs.cloud.google.com/logging/docs/audit/gsuite-audit-logging) |
| `gcloud kms keys create --protection-level` takes `software`, `hsm`, `hsm-single-tenant`, `external`, `external-vpc`, default `software` (verified 2026-09-13) | [gcloud kms keys create](https://docs.cloud.google.com/sdk/gcloud/reference/kms/keys/create) |
| `gcloud org-policies describe CONSTRAINT --project=PROJECT_ID --effective` describes a project's effective policy (verified 2026-09-13) | [gcloud org-policies describe](https://docs.cloud.google.com/sdk/gcloud/reference/org-policies/describe) |

**Deliberately unverified, and must stay so:** Agent Gateway availability in
`europe-west1`; whether group-management privileges honour OU scoping; whether licence
privileges are `isOuScopable`. None blocks Eve; all three change something if answered. Eve's
egress control until the first is answered is VPC Service Controls plus a host allowlist —
`walle-actions`, `admin.googleapis.com`, `cloudkms`, `secretmanager`, `bigquery`,
`firestore`, `storage`. `aiplatform.googleapis.com` is deliberately never registered.

## Related

- [README.md](README.md) — index and reading order
- [02-identity-and-auth.md](02-identity-and-auth.md) — every principal, and why each boundary is where it is
- [05-stages.md](05-stages.md) — what must be true to move between the stages this runbook builds
- [06-failure-modes.md](06-failure-modes.md) — what happens when a phase's output is wrong, missing or hostile
- [08-contract-changes.md](08-contract-changes.md) — every edit this runbook forces back on Wall-E's set
- [09-open-decisions.md](09-open-decisions.md) — the twenty decisions this design does not settle
- [../project-topology.md](../project-topology.md) — the four projects, which runbook makes each cross-project grant, and decisions 42–52
- [../wall-e/07-build-runbook.md](../wall-e/07-build-runbook.md) and [../wall-e/SETUP.md](../wall-e/SETUP.md) — Wall-E's equivalents
- [../wall-e/08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) — the contract this runbook builds against
- [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.2–§13.3 and [../agentic-platform/08-data-logging-retention-sovereignty.md](../agentic-platform/08-data-logging-retention-sovereignty.md) §5.4 — the observe-and-report layer, `eve_quality` and the daily export (2026-09-13)
