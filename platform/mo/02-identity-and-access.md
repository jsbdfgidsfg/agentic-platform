# 2. Identities and access

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13

Exactly who holds what, and — at least as important — what nothing holds. Mo runs as three
service accounts, each strictly weaker than the last, and the seam between them is an **IAM
boundary rather than a coding convention**. The code/model split that the rest of this set
argues from is only as good as this page: if `mo-narrator@` could select one free-text
column out of `walle_audit`, the claim that a model in Mo is safe would be a claim about
code review rather than about access control.

Two facts frame everything below.

- **None of it exists, and the ownership is split by project.** Mo's accounts are never
  created in Wall-E's runbook — they are created in `MO_PROJECT` by Mo's own runbook,
  [07-build-runbook.md](07-build-runbook.md), together with every in-project grant. Wall-E's
  runbook owns **exactly the cross-project grants on Wall-E's resources**: dataset-level
  `READER` on `walle_audit` and `walle_workspace_logs` for `mo-metrics@${MO_PROJECT}`, and
  `roles/run.invoker` on the `walle-actions` service for `mo-analyst@${MO_PROJECT}`, keyed on
  a new `MO_PROJECT` config key ([`../project-topology.md`](../project-topology.md) §3 rows 6
  and 8, §7.1). **No BigQuery read grant for Mo exists today**: `add_dataset_access` is called
  exactly twice in `setup/walle_setup.py`, once for the custom `walleAuditWriter` role on
  `walle-actions@`, once for the `walle-audit-bq` sink writer identity on
  `walle_workspace_logs`. Neither call names a Mo principal. Every grant on this page is a
  build task.
- **Mo holds no credential and no secret of any kind.** Not a Workspace credential, not a
  refresh token, not a signing key, not a git credential, not a Secret Manager grant on any
  secret in any project. There is no domain-wide delegation anywhere in this platform and Mo
  is not an exception to that; Mo has no Workspace identity to delegate to in the first
  place.

Read [01-hld.md](01-hld.md) first for what Mo is and why it has that shape. This page assumes
it.

---

## 1. The three identities

All three live in Mo's project, `${MO_PROJECT}`, region `europe-west1`, BigQuery location
`EU`. `WALLE_PROJECT` is where the two datasets they read and the service one of them calls
live; a principal here reaches those only through a grant on the resource, never through a
project-level role in Wall-E's project ([`../project-topology.md`](../project-topology.md),
"the one rule").

| Identity | What it is | Grants — exactly | Holds no | Why it is separate |
|---|---|---|---|---|
| `mo-metrics@${MO_PROJECT}.iam.gserviceaccount.com` | The pinned identity of the ~12 BigQuery scheduled queries, set with `--service_account_name`. **Never a human's user credentials**, which is the BigQuery Data Transfer Service default and an audit-independence defect when that human also administers Wall-E | `roles/bigquery.dataViewer` **dataset-level** on `${WALLE_PROJECT}:walle_audit` and `${WALLE_PROJECT}:walle_workspace_logs` (cross-project, made by Wall-E's runbook); `roles/bigquery.jobUser` on `MO_PROJECT` **only** — none in `WALLE_PROJECT`, because the job runs and is billed where it is submitted ("`bigquery.jobs.create` on the project from which the query is being run, regardless of where the data is stored", [Run a query](https://docs.cloud.google.com/bigquery/docs/running-queries), verified 2026-09-13); `roles/bigquery.dataEditor` on the four `walle_metrics*` datasets in `MO_PROJECT`. Additionally, per Google's service-account guidance for the Data Transfer Service, the **updating human** needs `bigquery.transfers.update` and Service Account User on this account, and the **account** needs `bigquery.datasets.get` and `bigquery.datasets.update` on the target dataset | Secret, key, Workspace credential, Firestore role, Cloud Run invoker binding, git credential, network egress | It is the only identity that reads raw per-person rows, and it runs committed SQL with no model and no way to be prompted |
| `mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com` | The attached service account of the `mo-reporter` Cloud Run job, workload identity only. **The name [../wall-e/ARCHITECTURE.md](../wall-e/ARCHITECTURE.md) §7.5's caller allowlist already carries** — the allowlist row must now carry this **full cross-project email** — and the resolution of `MO_PRINCIPAL` | `roles/bigquery.dataViewer` on `walle_metrics` and `walle_metrics_archive` in `MO_PROJECT` **only** — never on `walle_audit`, never on `walle_metrics_private`; `roles/bigquery.jobUser` on `MO_PROJECT`; `roles/run.invoker` on the service `walle-actions` in `WALLE_PROJECT` (cross-project, resource-level, made by Wall-E's runbook); `roles/storage.objectCreator` on `walle-mo-proposals` in `MO_PROJECT`. **Not** `roles/agentregistry.viewer`: Phase 13b binds it at project level on `WALLE_PROJECT`, which the topology forbids for a `MO_PROJECT` principal — dropped, or bound at resource level once verified (§6) | Secret of any kind, key, Workspace credential, Firestore role, git credential, read on `walle_audit` | It is the only identity that talks to anything outside BigQuery, and it cannot see the raw evidence it would need to forge a number |
| `mo-narrator@${MO_PROJECT}.iam.gserviceaccount.com` | The attached service account of the optional T2 job, built at S4 or never | `roles/bigquery.dataViewer` on the **agent-facing authorised-view dataset `walle_metrics_views` only**; `roles/aiplatform.user` on `MO_PROJECT`, for `generateContent` against a pinned model id — the Vertex AI API is enabled in `MO_PROJECT` at S4; nothing in `WALLE_PROJECT` | Everything else — no action-service invoker, no drop-box write, no raw read, no secret | It is the only identity that carries a model, and it can neither call the action service nor write a proposal bundle |

The table is the grant set as of S1. Two further bindings arrive later and are listed with
their reasons in [§2](#2-the-grant-list-account-by-account): `roles/run.invoker` for
`mo-analyst@` on the `mo-reporter` **job** — a different resource from the `walle-actions`
service — which is what lets Cloud Scheduler start the job at S1; and
`roles/bigquery.dataViewer` for `mo-metrics@` on the linked Spans dataset **in
`WALLE_PROJECT`** at S3 — a cross-project, dataset-level grant made by Wall-E's owner
(`Assumption:` the trace bucket is Wall-E's engine's; unverified that a linked dataset accepts
the entry, [M-11 · 52](08-open-decisions.md) (b)). Neither changes the ordering of the three
tiers, and both are marked where they arrive rather than folded into the row above.

Three notes that belong with the table rather than under it.

**`roles/storage.objectCreator` cannot overwrite.** Google's role reference (verified
2026-09-12) says: "Allows users to create objects. Does not give permission to view, delete,
or overwrite objects." So `mo-analyst@` cannot read back, replace or delete a bundle it has
written. A duplicate write **fails** rather than silently replacing, which is what makes the
drop box safe against a double-triggered reporter job as well as against a second, hostile
bundle written over a first.

**`roles/run.invoker` on `walle-actions` is a service-level grant, and the path restriction
is application code.** Cloud Run IAM is per service, not per path. The two endpoints Mo may
call —`GET /v1/plans/{id}` and `GET /v1/runs/{id}` — are restricted by the in-app allowlist
printed in [../wall-e/ARCHITECTURE.md](../wall-e/ARCHITECTURE.md) §7.5, which already names
`mo-analyst@` on exactly that row and on no other. That is structural weakness 2 of Wall-E's
architecture, inherited here rather than solved here, and it is why the denial tests in
§7 below exercise `/v1/control/demote` from `mo-analyst@` and expect a 403 from the
application rather than from IAM. It is also a **cross-project** grant: the binding is on the
`walle-actions` service in `WALLE_PROJECT`, the member is
`serviceAccount:mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com`, and it is made by Wall-E's
runbook (the Phase 10 invoker loop) from the `MO_PROJECT` config key — never by Mo's runbook.
The gcloud shape is `gcloud run services add-iam-policy-binding SERVICE --member=PRINCIPAL
--role=roles/run.invoker` ([Cloud Run — managing access](https://docs.cloud.google.com/run/docs/securing/managing-access),
verified 2026-09-13); Google documents no same-project restriction on the member, and the
domain-restricted-sharing constraint admits any service account in the organisation
([`../project-topology.md`](../project-topology.md) §5).

**`roles/agentregistry.viewer` is dropped, not kept.** On 2026-09-12 it was to be kept as
granted-and-unused: built in Phase 13b beside Eve's, read-only on a registry, and dropping it
meant editing `walle_setup.py`. Phase 13b binds it at **project** level on `WALLE_PROJECT`;
for `mo-analyst@${MO_PROJECT}` that is a project-level role in another project, forbidden by
the 2026-09-13 topology, and the Agent Registry v1 API offers no resource-level IAM. So the
paragraph flips: drop it from Phase 13b (an edit to `walle_setup.py`, which gains
`MO_PROJECT` in the same change; `MO_PRINCIPAL` may stay as a documented key), unless a
resource-level binding is verified — a spike, recorded as [M-11 · 52](08-open-decisions.md)
(a) and topology decision 43.

### 1.1 What no Mo identity holds, stated positively

| Capability | Which Mo identity holds it | Where the enforcement is |
|---|---|---|
| A Workspace credential, admin role, OAuth client or refresh token | **None** | No Workspace account is created for Mo at all; there is nothing to consent, nothing to impersonate, and no domain-wide delegation anywhere |
| `roles/secretmanager.secretAccessor` on any secret, in any project | **None** | Mo appears on no secret's IAM policy — none in `WALLE_PROJECT`, none in `EVE_PROJECT`, none in `GEMINI_PROJECT`, and no secret exists in `MO_PROJECT` at all. The separation sweep that already asserts `walle-actions@` and `eve-controller@` share no secret gains a third name to assert absent, in both projects that hold secrets |
| A Cloud KMS role of any kind, in particular `signer`, `signerVerifier` or `cryptoOperator` | **None** | Mo cannot produce an Eve approval, and neither can any language model — the standing rule, restated here at the identity layer |
| A git credential, GitHub App installation, deploy key or push right | **None** | Mo writes a bundle to a bucket. CI, under a bot identity that is **not** Mo, opens the pull request |
| `roles/datastore.viewer` or any other Firestore role | **None** | Everything Mo needs is write-ahead in BigQuery. Reading Firestore would put Mo inside the control plane's read surface for no artefact's sake |
| A Pub/Sub subscription on `walle-events` or any other topic | **None** | [C30](../wall-e/14-hld-challenge.md): no duty of Mo's needs it, default-stream writes are queryable immediately, and the `PS --> MO` edge leaves the component map |
| Write access to anything in `walle_audit` — or to anything else in `WALLE_PROJECT` | **None** | `mo-metrics@` holds `dataViewer` there, never `dataEditor`. Mo's only write targets are inside `MO_PROJECT`: `walle_metrics`, `walle_metrics_archive`, `walle_metrics_private` and the drop box |
| Any access to the restricted content-log bucket `walle-content-logs`, in `WALLE_PROJECT` | **None** | Its reader list is decision 25's: the operators group and IT security. Mo is not on it and does not ask to be |
| `aiplatform.reasoningEngines.query`, or any engine-level permission | **None** | The engine is in `WALLE_PROJECT` and no Mo principal appears in its IAM policy. Mo asks Wall-E nothing about itself, reads none of Wall-E's memory, and is not an Agent Runtime agent in this design |
| Any **project-level** role in `WALLE_PROJECT`, `EVE_PROJECT` or `GEMINI_PROJECT` | **None** | The topology's one rule. Mo's only bindings outside `MO_PROJECT` are three resource-level ones — two dataset access entries and one Cloud Run service binding — plus, at S3, one on the linked Spans dataset. Asserted by MD-9b and by Wall-E's drift job ([`../project-topology.md`](../project-topology.md) §3 row 26) |
| The right to call `/v1/ladder`, `/v1/control/*`, `/approve` or `/veto` | **None** | No IAM binding, no allowlist entry, no code path. `ladder.yaml` in git is what tells Mo what the level *should* be |

---

## 2. The grant list, account by account

One row per grant, with the resource it is scoped to and whether it exists today. "Exists
today" is `no` for every row but one, and that one is a placeholder.

### 2.1 `mo-metrics@` — the only identity that reads raw rows

| Grant | Scope | Made in, by | Why | Exists today |
|---|---|---|---|---|
| `roles/bigquery.dataViewer` (dataset access entry `READER`) | dataset `${WALLE_PROJECT}:walle_audit` — **cross-project, dataset-level** | `WALLE_PROJECT`, by Wall-E's owner: `walle_setup.py` `add_dataset_access` with member `mo-metrics@${MO_PROJECT}`, keyed on `MO_PROJECT` (SETUP Phase 7) | T0 computes every metric from `actions`, `runs`, `plans`, `approvals`, `verifications`, `config_versions`, and the new `grades`, `proposal_verdicts`, `drills` and `ladder_events` tables | no |
| `roles/bigquery.dataViewer` (dataset access entry `READER`) | dataset `${WALLE_PROJECT}:walle_workspace_logs` — **cross-project, dataset-level** | `WALLE_PROJECT`, by Wall-E's owner, the same way | Audit completeness joins Google's org-level admin events to Wall-E's requester and approver rows. Queried from BigQuery, never from org-level Cloud Logging, whose `_Default` bucket is fixed at 30 days for organisations | no |
| `roles/bigquery.jobUser` | project `${MO_PROJECT}` — and explicitly **none on `WALLE_PROJECT`** | `MO_PROJECT`, Mo's runbook (Mo-2) | A scheduled query is a job, and the job runs and is billed in the project it is submitted from, wherever the data is ([Run a query](https://docs.cloud.google.com/bigquery/docs/running-queries), verified 2026-09-13) | no |
| `roles/bigquery.dataEditor` | datasets `${MO_PROJECT}:walle_metrics`, `${MO_PROJECT}:walle_metrics_archive` | `MO_PROJECT`, Mo's runbook (Mo-2) | The `MERGE` target and the daily snapshot. This is the write that open decision 42 is about. The destination must be in the transfer config's project — "The destination dataset and table for a scheduled query must be in the same project as the scheduled query" ([Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries), verified 2026-09-13) — which is why these datasets are in `MO_PROJECT` and the sources are read cross-project, never the other way round | no |
| `roles/bigquery.dataEditor` | dataset `${MO_PROJECT}:walle_metrics_private` — **the only principal on it, and no reader is ever granted there to anyone** | `MO_PROJECT`, Mo's runbook (Mo-2) | `principal_surrogates` lives in this dataset alone, so the mapping sits outside every dataset `mo-analyst@` or `mo-narrator@` can reach. See §4 | no |
| `bigquery.datasets.get`, `bigquery.datasets.update` | the target dataset, in `MO_PROJECT` | `MO_PROJECT` (carried by `WRITER`) | Required of the service account a scheduled query is pinned to, per Google's Data Transfer Service documentation | no |
| `bigquery.transfers.update` on `MO_PROJECT` + Service Account User **on `mo-metrics@`** | held by the **human** who creates or edits a transfer config | `MO_PROJECT` | Not a grant to Mo. It is what the build step needs, and it is why creating the scheduled queries is a named human act in the runbook | no |
| `roles/bigquery.dataViewer` | the **linked Spans dataset** (`_AllSpans`) in `${WALLE_PROJECT}` (`Assumption:` the `_Trace` bucket is Wall-E's engine's) — **cross-project, dataset-level** | `WALLE_PROJECT`, by Wall-E's owner, after a human holding `roles/observability.editor` **in `WALLE_PROJECT`** creates the link | `Assumption:` the design names the Spans join but not the grant that makes it possible. Token spend, tool-call counts and per-invocation latency, joined on `invocation_id` and, through `runs`, on `trace_id`. **Granted at S3 only**, when [07-build-runbook.md](07-build-runbook.md) Phase Mo-10 creates the link; it widens `mo-metrics@`'s read surface by one dataset of trace data, and the link itself is never created by Mo. **Unverified** that a linked dataset's access array accepts the entry — [M-11 · 52](08-open-decisions.md) (b), topology decision 49 | no |

The pin itself is the control: `bq query --schedule ... --service_account_name` rather than
the default, which is the credentials of whoever pressed the button. A metrics pipeline that
silently runs as the administrator of the thing it measures is not independent evidence, and
it dies when that person leaves.

### 2.2 `mo-analyst@` — the only identity that leaves BigQuery

| Grant | Scope | Made in, by | Why | Exists today |
|---|---|---|---|---|
| `roles/bigquery.dataViewer` | datasets `${MO_PROJECT}:walle_metrics`, `${MO_PROJECT}:walle_metrics_archive` | `MO_PROJECT`, Mo's runbook (Mo-6) | T1 renders the five artefacts from computed aggregates and snapshots | no |
| `roles/bigquery.jobUser` | project `${MO_PROJECT}` | `MO_PROJECT`, Mo's runbook (Mo-6) | Reading a view is a job | no |
| `roles/run.invoker` | service `walle-actions` **in `WALLE_PROJECT`** — cross-project, service-level | `WALLE_PROJECT`, by Wall-E's owner: SETUP Phase 10's invoker loop gains `mo-analyst@${MO_PROJECT}` from the `MO_PROJECT` config key | The weekly `plan_hash` recomputation on a sample, through the two read endpoints. Phase 10's invoker loop covers `$SA_AGENT`, `$SA_DISPATCH`, `$SA_EVE`, `$SA_ACTIONS` and `$SA_OPS_CALLER` — **no Mo principal**, so this binding is new even though §7.5's allowlist row is not; and the allowlist row must carry the full `@${MO_PROJECT}` email | no |
| `roles/run.invoker` | **job** `mo-reporter`, in `MO_PROJECT` | `MO_PROJECT`, Mo's runbook (Mo-7) | A different resource from the `walle-actions` service. Cloud Scheduler's HTTP target on `run.googleapis.com` takes an OAuth token minted for the job's invoker, so the scheduling identity needs this binding on the job itself. `Assumption:` `mo-analyst@` is that scheduling identity — it invokes the job it also runs as | no |
| `roles/storage.objectCreator` | bucket `walle-mo-proposals`, in `MO_PROJECT` | `MO_PROJECT`, Mo's runbook (Mo-9) | Write one proposal bundle per object. Create only: no read-back, no overwrite, no delete | no |
| ~~`roles/agentregistry.viewer`~~ | ~~project `${WALLE_PROJECT}`~~ — **removed** | — | Phase 13b grants it through `MO_PRINCIPAL` at project level on Wall-E's project; for a `MO_PROJECT` principal that is a project-level role in another project, which the topology forbids, and the registry has no resource-level IAM. The row is retired unless a verified resource-level binding replaces it (§6, [M-11 · 52](08-open-decisions.md) (a)) | **no**, and must stay no — the grant written in `walle_setup.py` is deleted (topology decision 43) |

Explicitly **not** granted to `mo-analyst@`: `roles/bigquery.dataViewer` on `walle_audit`,
and `roles/bigquery.dataViewer` — or any other read — on `walle_metrics_private`. The first
absence is the whole point of the tier: `mo-analyst@` renders numbers it cannot recompute and
cannot check, which is exactly the property that makes the validator's independent
recomputation meaningful rather than ceremonial. The second is what makes the surrogate keys
surrogates: T1's `READER` on `walle_metrics` is **dataset-level** and covers every table in
that dataset, so the mapping cannot live there. See §4.

### 2.3 `mo-narrator@` — the only identity that carries a model

| Grant | Scope | Made in, by | Why | Exists today |
|---|---|---|---|---|
| `roles/bigquery.dataViewer` | dataset `${MO_PROJECT}:walle_metrics_views` — the **agent-facing authorised views only**, never `walle_metrics`, never `walle_metrics_archive`, never `walle_metrics_private`, never `walle_audit` | `MO_PROJECT`, Mo's runbook (Mo-11) | The model reads ids, hashes, closed enums, counts, timestamps and surrogate keys. Nothing else is selectable by it, anywhere. The grant is on the **view dataset**, which is what Google's authorized-view mechanism requires of the querying principal | no |
| `roles/aiplatform.user` | project `${MO_PROJECT}` | `MO_PROJECT`, Mo's runbook (Mo-11), after `aiplatform.googleapis.com` is enabled there | `generateContent` against a pinned model id in `europe-west1`. Deliberately not a reasoning engine, deliberately not Agent Runtime. The folder's Model Armor floor applies to these calls ([`../project-topology.md`](../project-topology.md) §5) | no |

Explicitly **not** granted: any `run.invoker` binding, any `storage.objectCreator` on the
drop box, any read on `walle_audit` or on the raw `walle_metrics` tables, any secret. T2
writes prose into a field that is stripped before validation and rendered into a pull-request
body under a fixed advisory heading. It cannot alter a number, cannot remove a `not_ready`
reason — the reason array is a set union, and there is no subtraction path — and cannot
reach the merge.

---

## 3. The authorised-view layer

The views are defined **in their own dataset, `walle_metrics_views`, over
`walle_metrics.scorecard`**, and registered on `walle_metrics`'s access list. Google's
documentation (verified 2026-09-12,
[authorized views](https://docs.cloud.google.com/bigquery/docs/authorized-views)) states three
things this design has to honour together, and getting any of them wrong makes the boundary
not exist rather than exist weakly:

| Requirement | The documented wording | What it forces here |
|---|---|---|
| Separate dataset | The authorized view "must be a different dataset than the dataset used in the source query" | The views cannot live in `walle_metrics` beside `scorecard`. `walle_metrics_views` holds views and no tables |
| Same location | "the source data dataset and authorized view dataset must be in the same regional location" | Every Mo dataset is `EU`, and the location is not a free choice later |
| Grant on the view's dataset | The querying principal needs "`roles/bigquery.dataViewer` … to the dataset that contains the authorized view", and no permission on the source — plus `roles/bigquery.jobUser` on the project where the query job runs (same page, verified 2026-09-13) | `mo-narrator@` is granted on `walle_metrics_views`, not on the view as a table and not on `walle_metrics`; its `jobUser` is on `MO_PROJECT`, where the view, its source and the job all are |

"Principals can view the data you share and run queries on it, but they can't access the
source dataset directly" is the property the tier rests on, and it is only available when all
three hold.

This is what lets `mo-narrator@` read derived rows that originate in `walle_audit` while
holding no access on `walle_metrics` or `walle_audit` at all. The column allowlist below is
therefore an access-control boundary, not a style guide.

**An agent-facing view never holds an authorization on `walle_audit`.** A view executes with
**its own** authorization rather than the caller's, and `mo-metrics@` holds `WRITER` on
`walle_metrics` and can therefore `CREATE OR REPLACE` these views. A view authorized on
`walle_audit` would, the moment it was redefined to select `params_redacted`, hand raw free
text to whichever principal may read it — a standing escalation path into the one dataset the
three-tier split exists to fence off. The views read `walle_metrics.scorecard` and are
registered on `walle_metrics` only — an **intra-project** authorisation, since both datasets
are in `MO_PROJECT`. The cross-project form exists: the source dataset's access entry names
the view as `PROJECT_ID.DATASET_ID.VIEW_NAME` ([authorized views](https://docs.cloud.google.com/bigquery/docs/authorized-views),
verified 2026-09-13), so authorising a `MO_PROJECT` view on `${WALLE_PROJECT}:walle_audit` is
possible and is exactly what is refused. Mo-6's verify block checks that
`${WALLE_PROJECT}:walle_audit`'s access array contains no `view` entry whose `projectId` is
`MO_PROJECT` ([`../project-topology.md`](../project-topology.md) §3 row 9, an anti-grant).

### 3.1 The column allowlist

Admitted: **ids, hashes, closed enums, counts, timestamps and surrogate keys**. Every string
a view returns is drawn from a closed vocabulary defined in
[../wall-e/03-lld.md](../wall-e/03-lld.md).

The table below is about **provenance, not about the view's `FROM` clause**. The views select
from `walle_metrics.scorecard`, which T0 computed from `walle_audit`; the allowlist says which
`walle_audit.actions` columns may survive that journey into a published column, and which must
not exist anywhere downstream of T0.

| From `walle_audit.actions` | Admitted to the agent-facing views | Note |
|---|---|---|
| `run_id`, `plan_id`, `trigger_id`, `approval_id` | yes | Opaque ids. `run_id#item_index` is also what keeps the grading worklist blind |
| `family`, `risk`, `level`, `decision`, `denial_reason`, `verification`, `screen_state`, `error_class` | yes | Closed enums. `error_class` is a closed set in [../wall-e/03-lld.md](../wall-e/03-lld.md); a raw Google error string is not that set and is never exposed |
| `config_version`, `ceilings_sha`, `catalogue_version`, `playbook_version`, `prompt_hash`, `model_id`, `pre_state_hash`, `post_state_hash` | yes | Versions and hashes. These are the attribution fingerprint's inputs |
| `tainted`, `dry_run`, and the `noop BOOL` column this design requires | yes | Booleans |
| `latency_ms`, `approval_latency_ms`, `ts` | yes | Numbers and timestamps |
| `principal_id`, `on_behalf_of`, `approver` | **no** — replaced by a surrogate | Email-shaped. See §4 |
| `params_redacted` | **no** | Attacker-writable in part, and redaction is not a closed vocabulary |
| `result_summary` | **no** | The field [../wall-e/03-lld.md](../wall-e/03-lld.md) already warns about: a first implementation put mail excerpts into BigQuery |
| `content_flags` | **no** as text | A `filter:confidence` list. `Assumption:` where a metric needs it, T0 reduces it to a count inside `walle_metrics`; the design states only that no `content_flags` free text is exposed. The free-text form never leaves `walle_audit` |
| Any display name, group name, group description, or Google-returned error message, from any table | **no** | These are the attacker-writable strings [../wall-e/06-security-guardrails.md](../wall-e/06-security-guardrails.md) N5 is about |

The exclusion is enforced three ways, in descending order of how much each should be
trusted: by the view definitions themselves, which are the IAM boundary; by an assertion
query that fails the run if any published row carries an email-shaped string; and by CI
review of the query text, which is the weakest of the three and is not relied on alone.

### 3.2 Why this is stronger than sanitising

[../wall-e/06-security-guardrails.md](../wall-e/06-security-guardrails.md) N5 requires
canonicalisation of every attacker-writable string that reaches a model. In Mo that
requirement is met by **there being nothing to canonicalise**. An injected display name, a
hostile group description or a crafted error message written into an audit row cannot reach
Mo's prose layer, because no view returns a column that could carry one and `mo-narrator@`
has no other read. A sanitiser is code that can be wrong in a way nobody notices; an absent
column is not.

The one place the split is imperfect is stated rather than hidden: T1 calls
`GET /v1/plans/{id}`, whose response carries per-item pre-state. The reduction to counts and
the `plan_hash` recomputation happen in T1's own deterministic code before anything could
reach a model, and T2 has no access to that response at all — but that is a **process
boundary inside T1, not an IAM boundary**, and it is the only one in this design.

---

## 4. Surrogate keys

Every person-identifying column in an agent-facing view is replaced by a **surrogate key**: a
monotone integer per distinct principal, held in `principal_surrogates` in
**`walle_metrics_private`** and assigned by T0.

**The dataset is the mechanism, and it has to be a fourth dataset.** BigQuery dataset-level
`READER` covers every table in the dataset, and `mo-analyst@` holds dataset-level `READER` on
`walle_metrics`. A mapping table inside `walle_metrics` would therefore be selectable by T1,
which could join every surrogate in every view and every artefact back to a principal email —
and every future table added to `walle_metrics`, including one carrying free text, would be
readable by T1 automatically with no design review. `walle_metrics_private` holds the mapping
alone, `mo-metrics@` is the only principal on it, and **no reader is ever granted there**.
`walle_metrics` then carries surrogate integers and nothing that reverses them.

This preserves the one signal that matters analytically — *the same subject recurs* — while
destroying identity. It is strictly better than omitting the column, which loses a real
signal: "one principal accounts for nine of the twelve rejections in this cell" is a finding,
and "some principals" is not.

| Property | How |
|---|---|
| Scope | `Assumption:` one surrogate space across `principal_id`, `on_behalf_of`, `approver` and `grades.grader_id`, so the same human is the same integer wherever they appear. The design states the scheme — a monotone integer per distinct principal — but not which columns share the space |
| Stability | Monotone and assigned once, so a surrogate is comparable across weeks and across snapshots |
| Reversibility | `principal_surrogates` lives in `walle_metrics_private`, on which `mo-metrics@` holds the only binding and no reader exists. It is excluded from every agent-facing view and from every published artefact, and denial test **MD-13** proves both other Mo identities are refused. A surrogate that can be joined back to an email is not a surrogate — so this is built, not assumed |
| Suppression | Surrogates do not exempt a row from the minimum reporting cell size of 5 (`Assumption:`, decision 35). An aggregate over a single surrogate is a person |

Mo is nonetheless **inside the personal-data perimeter**: T0 reads per-person rows, and Mo
belongs in the data-protection assessment as a processor.
[../wall-e/ARCHITECTURE.md](../wall-e/ARCHITECTURE.md) weakness 11's claim that Mo's reads
are aggregated per organisational unit is **wrong at the pipeline layer and should be
corrected rather than inherited** — that correction is one of the changes listed in
[08-open-decisions.md](08-open-decisions.md), and the disclosure argument is in
[06-failure-modes.md](06-failure-modes.md).

---

## 5. Containment: nothing that enforces may read `walle_metrics`

Mo's writes are claimed to be harmless because nothing acts on them. That claim is only
worth something if it is tested, so it is stated as an assertion with a named identity list
and a denial-suite row.

**The assertion.** No identity in Wall-E's enforcement path holds read access on
`walle_metrics`, `walle_metrics_archive`, `walle_metrics_private` or `walle_metrics_views` —
and, since those datasets are in `MO_PROJECT`, no principal homed in `WALLE_PROJECT`,
`EVE_PROJECT`, `GEMINI_PROJECT` or the validator custodian's project holds **any binding of
any kind** in `MO_PROJECT`: `MO_PROJECT`'s project IAM policy names none of them, and no Mo
dataset's access list does either ([`../project-topology.md`](../project-topology.md) §3
row 24).

| Identity | Home | Role in enforcement | Must not hold |
|---|---|---|---|
| `walle-actions@` | `WALLE_PROJECT` | Holds the Workspace credential; runs the policy chain, the breakers and the level check | `bigquery.dataViewer`, `jobUser` or any custom read role on any of the four Mo datasets; any binding in `MO_PROJECT`'s IAM policy |
| `walle-dispatcher@` | `WALLE_PROJECT` | Invokes the reasoning layer | the same |
| The ladder deploy tool's identity (`config/deploy_ladder.py`) | `WALLE_PROJECT` | Writes the effective level | the same |
| `eve-controller@${EVE_PROJECT}` and every other Eve identity | `EVE_PROJECT` | Approves, vetoes, halts, demotes | the same |
| The CI gate validator's identity | The custodian's own project (*tbd*, decision 37) | Recomputes evidence and refuses merges | the same — **it reads `${WALLE_PROJECT}.walle_audit` directly, cross-project, never Mo's output.** A validator that read `walle_metrics` would be checking Mo against Mo |
| `service-${GEMINI_PROJECT_NUMBER}@gcp-sa-discoveryengine.iam.gserviceaccount.com` | `GEMINI_PROJECT` | The Gemini Enterprise app's service agent, which queries Wall-E's engine | the same. It has no business in `MO_PROJECT`; its only cross-project grant is on Wall-E's engine |

**The denial-suite row**, authored in [../wall-e/SETUP.md](../wall-e/SETUP.md) §4's format
and listed with the rest of Mo's tests in [07-build-runbook.md](07-build-runbook.md):

| # | Test | Expected result |
|---|---|---|
| *tbd* in SETUP §4; `MD-9` in [07-build-runbook.md](07-build-runbook.md) | Each of the enforcement identities in the table above attempts `SELECT` on `` `${MO_PROJECT}.walle_metrics.scorecard` ``, with the job submitted in the identity's **home** project (`WALLE_PROJECT`, `EVE_PROJECT`, the custodian's), so that the 403 comes from the table and not from a missing `bigquery.jobs.create` — a test refused at job creation passes for the wrong reason | **403 at Google** for every one. The suite fails if any single identity succeeds |
| `MD-9b` in [07-build-runbook.md](07-build-runbook.md) | `gcloud projects get-iam-policy "$MO_PROJECT"` is read and every member checked | **Zero** members ending in `@${WALLE_PROJECT}.iam.gserviceaccount.com` or `@${EVE_PROJECT}.iam.gserviceaccount.com`, and none containing `gcp-sa-discoveryengine`. The same check over each Mo dataset's `access` array |

Two consequences follow from making this a test rather than a sentence.

**It is the mechanism behind open decision 42.** A strict reading of
[../wall-e/ARCHITECTURE.md](../wall-e/ARCHITECTURE.md) §7.5 — "Mo has **no write path of any
kind**" — forbids `mo-metrics@` writing `walle_metrics` at all, which would leave the
scorecard, the cost report and the regression explanation with no home while the same
contract demands Mo publish them. This design reads the sentence as **no byte Mo writes is
read by anything that enforces**, and makes that true by mechanism rather than by
interpretation. The fallback if the narrow reading is refused — artefacts into a Cloud
Storage bucket with the same read exclusions — is the same interpretation in different
storage, so refusing it changes nothing except cost. The decision is in
[08-open-decisions.md](08-open-decisions.md).

**It bounds the blast radius of a compromised `mo-metrics@`.** The worst an attacker with
that identity can do is write false numbers into a dataset that no enforcing component
reads, and then watch the validator refuse every promotion those numbers support, because
the validator recomputes from `walle_audit` rather than believing `walle_metrics`. The
threat-model rows for each Mo identity are in
[06-failure-modes.md](06-failure-modes.md).

### 5.1 The reader set on the other side

`walle_metrics` has a **wider reader set than `walle_audit`**, which is exactly why
suppression is a mechanism here and not a promise. Until decision 35 lands, the reader set is
`walle-operators@` and the ladder owner only, the minimum reporting cell size is 5
(`Assumption:`), and **no Mo artefact is synced to Drive**. That restriction and its reasons
are open decision 44 in [08-open-decisions.md](08-open-decisions.md).

---

## 6. `MO_PRINCIPAL`, resolved

`MO_PRINCIPAL` exists today in exactly two places: `setup/walle.env.example`, as the
placeholder `"<mo-principal>"`, and `walle_setup.py`'s `_REGISTRY_KEYS`, where it is a
required key for `./walle registry` and is used once, to grant `roles/agentregistry.viewer`
at project level in Phase 13b. No service account is created for it, and a grep for
`mo-analyst` across the runbook returns only a comment.

**It resolves to `serviceAccount:mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com`** — the
value needs `MO_PROJECT` in `walle.env`.

| Consequence | Detail |
|---|---|
| A code change after all | On 2026-09-12 "no code change" held: the IAM member string is in the documented form and a bare email is taken as a service account. It no longer holds. `walle_setup.py` and `walle.env.example` gain `MO_PROJECT` for the cross-project grants regardless, and Phase 13b's **project-level** `roles/agentregistry.viewer` on `WALLE_PROJECT` to a `MO_PROJECT` principal is forbidden by the topology's one rule |
| [../wall-e/PREREQUISITES.md](../wall-e/PREREQUISITES.md) item 11 | "`MO_PRINCIPAL` is required by `./walle registry` while Mo does not exist" — settled by naming the principal, so the key stops being a blank that blocks every subcommand; if the registry grant goes, the key is kept only where another subcommand needs it (`validate_config` then stops requiring it for `registry`) |
| [../wall-e/PREREQUISITES.md](../wall-e/PREREQUISITES.md) item 13 | The registry-viewer holders disagree between SETUP prose, the SETUP command and the script. The resolution names the principal; the grant itself is removed from all three so they agree on absence |
| The former alternative, now the recommendation | Dropping `roles/agentregistry.viewer` is correct by the artefact test — no Mo duty uses the registry — **and** required by placement: the registry v1 API has no `getIamPolicy`/`setIamPolicy` and its roles are project-level only, so there is no resource-level form to fall back to. Drop the grant from Phase 13b; keep `MO_PRINCIPAL` only if it has another use. A resource-level binding, if one is ever verified, is the only thing that would reinstate it — [M-11 · 52](08-open-decisions.md) (a), topology decision 43; not verified as of 2026-09-13 |

`Assumption:` `mo-analyst@` rather than `mo-metrics@` is the right principal for the key,
because anything the key is ever used for is about the reporting tier's view of the platform,
and `mo-metrics@` is deliberately confined to BigQuery.

---

## 7. Denial tests authored from Mo's side

The full set, with commands, lives in [07-build-runbook.md](07-build-runbook.md) Phase Mo-12,
numbered `MD-1` to `MD-12`. The identity-shaped ones are listed here, with that number, because
they are the tests that make this page's claims falsifiable, and because each maps to exactly
one grant that is absent above. `MD-11` and `MD-12` are not identity-shaped — they test the
floor assertion and the suppression rule — and live only in the runbook.

| # | Test | Expected result | Which claim it tests |
|---|---|---|---|
| MD-1 | `mo-narrator@` selects a raw column (`params_redacted`, `result_summary`, `principal_id`) from `` `${WALLE_PROJECT}.walle_audit.*` `` or from a `` `${MO_PROJECT}.walle_metrics` `` base table, from a job in `MO_PROJECT` | **403 / not found.** It holds `dataViewer` on the agent-facing views only | §3 — the model cannot see the data, and cannot see a free string |
| MD-2 | `mo-analyst@` runs `SELECT` against `` `${WALLE_PROJECT}.walle_audit.actions` ``, fully qualified, from a job in `MO_PROJECT` — a bare `walle_audit.actions` resolves in `MO_PROJECT`, fails as not-found and proves nothing | **403 at Google** | §2.2 — the reporting tier cannot reach the raw evidence |
| MD-3 | `mo-analyst@` calls `POST /v1/control/demote` on `walle-actions` in `WALLE_PROJECT`, cross-project | **403** from the in-app allowlist. `run.invoker` allows the HTTP call; the allowlist refuses the path. The paired positive — `GET /v1/runs/{id}` returns 200 — proves the allowlist row carries the `@${MO_PROJECT}` email; an allowlist still carrying an old `@${PROJECT}` address 403s everything and passes this test for the wrong reason | §1 — Mo cannot demote, halt, approve or veto |
| MD-4 | `mo-analyst@` calls `GET /v1/ladder`, cross-project | **403.** Mo is not on that allowlist row | §1.1 — `ladder.yaml` in git is Mo's source for the declared level |
| MD-8 | `mo-analyst@` writes a second object over an existing bundle name in `walle-mo-proposals` | **Fails.** `objectCreator` does not permit overwrite | §1 — a duplicate bundle fails rather than replacing |
| MD-8 | `mo-analyst@` reads back or deletes a bundle it wrote | **403** | the same |
| MD-5 | A bundle whose diff touches the ceiling module, the policy chain, the catalogue risk tiers or the validator | **Rejected at ingestion, before CI** | [04-artefacts-and-proposals.md](04-artefacts-and-proposals.md) — the gate cannot be part of what it gates |
| MD-6 | A bundle citing a `scorecard_sha256` that `mo-metrics@` never published | **Rejected at ingestion** | the same — evidence is hash-bound |
| MD-9 | Each enforcement identity reads `` `${MO_PROJECT}.walle_metrics.*` `` cross-project, from a job in its **home** project (`WALLE_PROJECT`, `EVE_PROJECT`, the custodian's) | **403 at Google**, for every one | §5 — the containment assertion |
| MD-9b | `MO_PROJECT`'s IAM policy and each Mo dataset's access array are enumerated | **No** member from `WALLE_PROJECT`, `EVE_PROJECT` or `GEMINI_PROJECT`, and no `gcp-sa-discoveryengine` agent | §5 — the containment assertion as a project-IAM fact |
| MD-10 | Each of the three Mo identities attempts `secretmanager.versions.access` on every secret in `WALLE_PROJECT` and every secret in `EVE_PROJECT`, enumerated explicitly (there are none in `MO_PROJECT` or `GEMINI_PROJECT`) | **403 at Google** | §1.1 — Mo holds no secret anywhere |

---

## 8. The package boundary that goes with the IAM boundary

IAM says which identity may read what. CI says which code may run under which identity, and
the two together are what make "T0 carries no model" a checkable statement rather than a
convention. These lints are required checks on Mo's packages:

- No import of `skill_registry`, `SkillToolset`, `McpToolset` or `RemoteA2aAgent` anywhere
  in Mo.
- An import test banning `google.genai`, `vertexai` and `google.adk` from **T0's and T1's**
  packages specifically. Only T2's package may import a model client, and only T2's identity
  can use one.
- `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS` absent or false.
- No fault-injection or test-mode path reachable in an admitted image.
- Deploy **by image digest**, never a mutable tag — for `mo-reporter`, for the optional
  `mo-narrator`, and for the validator's recompute check.

The reasoning behind these belongs with the deterministic boundary in
[01-hld.md](01-hld.md); they are repeated here because each one is an access control in
substance, whatever its implementation.

---

## 9. Egress, and the gateway Mo is not behind

Mo v1 is **not** behind Agent Gateway. Its egress control is the absence of any HTTP tool in
T0 — a BigQuery scheduled query cannot make an outbound call and cannot be prompted — and a
two-entry allowlist in T1, which reaches `walle-actions` and nothing else.

If Mo is ever put behind a gateway, the obligation is concrete and is recorded now rather
than discovered later. Per
[../wall-e/13-agent-interconnection.md](../wall-e/13-agent-interconnection.md) §7, a bound
gateway is **default deny**, hostname matching is **exact**, wildcards are unsupported, and
every standard, regional and mTLS variant an SDK resolves to must be registered or
invocations fail with 498.

| Hostname that would have to be registered | For |
|---|---|
| `bigquery.googleapis.com`, plus its regional and mTLS variants | Every read T1 performs |
| `aiplatform.googleapis.com`, plus its regional and mTLS variants | T2's `generateContent` calls only |
| `storage.googleapis.com`, plus its regional and mTLS variants | `Assumption:` the drop-box write, which is a Cloud Storage call T1 makes today without a gateway |
| The `walle-actions` `run.app` URL | The two read endpoints |

Two constraints come with that choice and are not Mo's to take alone: binding a gateway
requires `identity_type=AGENT_IDENTITY` at engine creation and is immutable afterwards, and
with a gateway bound there is no VPC Service Controls perimeter. Mo has no engine, so
neither binds today.

---

## 10. What this forces on Wall-E's set

Identity-shaped only; the full list of changes, with their targets and references, is in
[08-open-decisions.md](08-open-decisions.md).

| Change | Target | Why |
|---|---|---|
| Make the two **cross-project** dataset grants: `add_dataset_access` `READER` on `walle_audit` and on `walle_workspace_logs` for `mo-metrics@${MO_PROJECT}`, driven by a new `MO_PROJECT` config key. The three accounts, the four datasets and the authorised-view registration on **`walle_metrics`** leave Wall-E's set — they are `MO_PROJECT` resources built by [07-build-runbook.md](07-build-runbook.md) Mo-1, Mo-2 and Mo-6 | [../wall-e/SETUP.md](../wall-e/SETUP.md) Phase 7; `walle_setup.py` `add_dataset_access` (gains a project argument); `walle.env.example` | The shared data plane [../wall-e/08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) promises is entirely unbuilt, and the only part of it Wall-E's runbook can build is the grant on Wall-E's own datasets |
| Add `mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com` to Phase 10's `run.invoker` loop on `walle-actions`, and write that full email into the read-endpoint allowlist | [../wall-e/SETUP.md](../wall-e/SETUP.md) Phase 10; [../wall-e/ARCHITECTURE.md](../wall-e/ARCHITECTURE.md) §7.5 | §7.5's allowlist already names `mo-analyst@`; the IAM binding that lets the call arrive does not exist, and the allowlist row now names a foreign email |
| Correct the Mo identities row and item 6 from "never call the action service" to "**the two read endpoints only**" | [../wall-e/08-team-eve-mo.md](../wall-e/08-team-eve-mo.md) | [C39](../wall-e/14-hld-challenge.md), decided and not landed; 08's own interfaces table and §7.5 already say the corrected thing |
| Remove `walle-events` "subscribe" for Mo from the shared data plane | [../wall-e/08-team-eve-mo.md](../wall-e/08-team-eve-mo.md), [../wall-e/01-hld.md](../wall-e/01-hld.md), [../wall-e/ARCHITECTURE.md](../wall-e/ARCHITECTURE.md) | [C30](../wall-e/14-hld-challenge.md). Mo takes no subscription |
| Add the denial-suite row asserting no enforcement identity reads `walle_metrics` | [../wall-e/SETUP.md](../wall-e/SETUP.md) §4 | Turns Mo's containment from a claim into a test, and is the mechanism behind open decision 42 |
| Correct weakness 11's claim that Mo's reads are aggregated per organisational unit | [../wall-e/ARCHITECTURE.md](../wall-e/ARCHITECTURE.md) | False at the pipeline layer: T0 reads per-person rows, and the data-protection assessment needs the true version |
| Record `MO_PRINCIPAL = serviceAccount:mo-analyst@${MO_PROJECT}.iam.gserviceaccount.com`, and add `MO_PROJECT` to `walle.env.example` and `walle_setup.py` | `setup/walle.env.example`; `walle_setup.py`; [../wall-e/PREREQUISITES.md](../wall-e/PREREQUISITES.md) items 11 and 13 | The principal is named; the key needs the new project variable to resolve |
| Remove Phase 13b's `roles/agentregistry.viewer` for `MO_PRINCIPAL`, or replace it with a verified resource-level binding | [../wall-e/SETUP.md](../wall-e/SETUP.md) Phase 13b; `walle_setup.py` `registry` | A project-level role in `WALLE_PROJECT` for a `MO_PROJECT` principal breaks the topology's one rule; no Mo duty needs the registry (§6, topology decision 43) |

---

## Sources

Google product claims on this page, verified 2026-09-12:

- [BigQuery — authorized views](https://docs.cloud.google.com/bigquery/docs/authorized-views) — "Principals can view the data you share and run queries on it, but they can't access the source dataset directly"; "The source data dataset and authorized view dataset must be in the same regional location."
- [Cloud Storage — IAM roles](https://docs.cloud.google.com/storage/docs/access-control/iam-roles) — `roles/storage.objectCreator`: "Allows users to create objects. Does not give permission to view, delete, or overwrite objects."
- [BigQuery — scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries) — scheduled queries run on the BigQuery Data Transfer Service and use user credentials by default; a service account can be configured instead.
- [BigQuery — use service accounts with the Data Transfer Service](https://docs.cloud.google.com/bigquery/docs/use-service-accounts) — the updating user needs `bigquery.transfers.update` and access to the service account; the service account needs `bigquery.datasets.get` and `bigquery.datasets.update` on the target dataset.
- [Cloud Run — execute jobs on a schedule](https://docs.cloud.google.com/run/docs/execute/jobs-on-schedule) — a Cloud Scheduler HTTP target on `run.googleapis.com` uses an **OAuth** token and needs `roles/run.invoker` on the job.

Cross-project claims added on 2026-09-13, verified that day:

- [BigQuery — run a query](https://docs.cloud.google.com/bigquery/docs/running-queries) — "`bigquery.jobs.create` on the project from which the query is being run, regardless of where the data is stored"; "`bigquery.tables.getData` on all tables and views that your query references"; "the querying project is billed for the query job while the project storing the data is billed for the amount of data stored in BigQuery."
- [BigQuery — scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries) — "The destination dataset and table for a scheduled query must be in the same project as the scheduled query"; "Queries can reference tables from different projects and different datasets."
- [BigQuery — authorized views](https://docs.cloud.google.com/bigquery/docs/authorized-views) — the view is identified on the source dataset's access list by "the fully qualified name of the view, in the format `PROJECT_ID.DATASET_ID.VIEW_NAME`"; the querying principal needs `roles/bigquery.dataViewer` on the view's dataset and `roles/bigquery.jobUser` on the project where the query runs.
- [Cloud Run — managing access](https://docs.cloud.google.com/run/docs/securing/managing-access) — `gcloud run services add-iam-policy-binding SERVICE_NAME --member=PRINCIPAL --role=ROLE`; the page states no same-project restriction on the member. The admissibility of a foreign service account as a member rests on the domain-restricted-sharing constraint, cited in [`../project-topology.md`](../project-topology.md) §5.

Agent Gateway's default-deny, exact-hostname and 498 behaviour is taken from
[../wall-e/13-agent-interconnection.md](../wall-e/13-agent-interconnection.md) §7, which
carries its own verified citations.
