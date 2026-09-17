# The code

## Status

- Owner: person A writes and deploys; person B reads every deploy command before it is run.
- Last reviewed: 2026-09-17.
- Part of the three-day build: [README.md](README.md), [day 1](day-1-platform-and-eve.md),
  [day 2](day-2-the-doer.md), [day 3](day-3-mo-demonstration-and-handover.md).
- Every file below is complete. Paste it, set the variables at the top of §0, deploy. Google Code
  Assist is for adapting these files, not for inventing them.
- Runtime everywhere: **Python 3.12**, deployed from source by Cloud Run buildpacks
  (`.python-version` pins it; the buildpack installs `requirements.txt` and reads `Procfile` for the
  entrypoint; Google's Python buildpack page, read 2026-09-17).

## Two facts that the rest of the design rests on

1. **The halt secret is read with `access_secret_version` on every request and is never mounted.**
   A secret mounted with `--set-secrets ...:latest` is resolved when the container instance starts,
   so a warm instance would never see a halt written after it started. A kill switch that does not
   kill is worse than none. `actions.py` reads `steward-halt` per request, and drill K0 is run
   against an instance that was already warm.
2. **The audit row is written before the Directory call, and a failed audit write is a denial
   reason.** `actions.py` writes the `intent` row first; if that insert returns any error the
   request is refused with `denial_reason=audit_unavailable` and no Google call is made.

## The tree

```
build/
  .python-version            # 3.12, copied into each deployable
  eve/      poller.py  eve_detections.sql  requirements.txt  Procfile  .python-version
  doer/     actions.py plan.py             requirements.txt  Procfile  .python-version
  mo/       mo.sql
  tools/    consent.py bootstrap.sh
```

`plan.py` ships in the same directory as `actions.py` but is deployed as a separate Cloud Run job
with a different service account and its own `Procfile` line; see §4.

## §0 Variables

Set these once per shell. No default project is ever set: every command below passes `--project`.

```bash
export ORG_DOMAIN="example.test"                  # the tenant's primary domain
export REGION="europe-west1"
export BQ_LOCATION="EU"
export CORE_PROJECT="agp-3d-core"
export EVE_PROJECT="agp-3d-eve"
export DOER_PROJECT="agp-3d-doer"
export MO_PROJECT="agp-3d-mo"
export BILLING_ACCOUNT="000000-000000-000000"
export AGENT_ID="steward"
export PILOT_OU="/Automation/Pilot"
export SYNTHETIC_PREFIX="steward-pilot-"
export EVE_READER="eve-reader@${ORG_DOMAIN}"
export STEWARD_ROBOT="steward-robot@${ORG_DOMAIN}"
export PERSON_B="<person B's own account>"        # the approver, a human
gcloud config configurations describe "$(gcloud config configurations list --filter=is_active=true --format='value(name)')" --format='value(properties.core.project)' | grep -q . && echo "STOP: a default project is set" || echo "no default project"
```

`Assumption:` the project ids above are free. Project ids are permanent and never reusable, so read
them back from `gcloud projects describe` before anything else is built on them.

---

## §1 `eve/poller.py`

Polls the Admin SDK Reports API for one tenant, writes rows into `eve.ws_activities`, runs the
detections and emits one `EVE-FINDING` line per match. It holds one scope,
`https://www.googleapis.com/auth/admin.reports.audit.readonly` (Google's `activities.list`
reference, read 2026-09-17), and it is not domain-wide delegation: the credential is
`eve-reader@`'s own consented refresh token and no account is impersonated.

```python
# build/eve/poller.py
#!/usr/bin/env python3.12
"""Eve. Poll the Admin SDK Reports API, land rows in BigQuery, emit findings.

One account, one scope, one consent. No domain-wide delegation: userKey is 'all'
because the consenting account is a delegated admin with Reports read, not because
any account is impersonated.
"""
from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
import sys

from google.cloud import bigquery, secretmanager
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

PROJECT = os.environ["EVE_PROJECT"]
DATASET = os.environ.get("EVE_DATASET", "eve")
APPS = [a.strip() for a in os.environ.get(
    "APPS", "admin,login,token,user_accounts,groups_enterprise").split(",") if a.strip()]
CRED_SECRET = os.environ.get("EVE_CREDENTIAL_SECRET", "eve-refresh-token")
LOOKBACK_HOURS = int(os.environ.get("LOOKBACK_HOURS", "24"))
PAGE_SIZE = int(os.environ.get("PAGE_SIZE", "1000"))
TOKEN_URI = "https://oauth2.googleapis.com/token"
SCOPES = ["https://www.googleapis.com/auth/admin.reports.audit.readonly"]

ACTIVITIES = f"{PROJECT}.{DATASET}.ws_activities"
RUNS = f"{PROJECT}.{DATASET}.poll_runs"
FINDINGS = f"{PROJECT}.{DATASET}.findings"

bq = bigquery.Client(project=PROJECT)


def log(line: str) -> None:
    """One line, unbuffered, so Cloud Logging sees it even if the task is killed."""
    sys.stdout.write(line.rstrip() + "\n")
    sys.stdout.flush()


def credentials() -> Credentials:
    """Read {client_id, client_secret, refresh_token} written by tools/consent.py.

    The credential secret is read once per run. Unlike the doer's halt flag it may be
    mounted or cached, because a revoked refresh token fails at Google straight away.
    """
    sm = secretmanager.SecretManagerServiceClient()
    name = f"projects/{PROJECT}/secrets/{CRED_SECRET}/versions/latest"
    blob = json.loads(sm.access_secret_version(request={"name": name}).payload.data.decode("utf-8"))
    return Credentials(
        token=None,
        refresh_token=blob["refresh_token"],
        client_id=blob["client_id"],
        client_secret=blob["client_secret"],
        token_uri=TOKEN_URI,
        scopes=SCOPES,
    )


def watermark(application: str) -> dt.datetime:
    """Latest event already landed for this application, or the lookback floor."""
    floor = dt.datetime.now(dt.timezone.utc) - dt.timedelta(hours=LOOKBACK_HOURS)
    sql = f"SELECT MAX(event_time) AS m FROM `{ACTIVITIES}` WHERE application = @a"
    job = bq.query(sql, job_config=bigquery.QueryJobConfig(query_parameters=[
        bigquery.ScalarQueryParameter("a", "STRING", application)]))
    rows = list(job.result())
    if rows and rows[0].m is not None and rows[0].m > floor:
        # startTime is inclusive, so step one microsecond past the last event.
        return rows[0].m + dt.timedelta(microseconds=1)
    return floor


def rfc3339(value: dt.datetime) -> str:
    return value.astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def insert_id(application: str, item: dict) -> str:
    """Deterministic, so a retried task cannot double-count an event."""
    ident = item.get("id", {}) or {}
    key = "|".join([
        application,
        str(ident.get("time", "")),
        str(ident.get("uniqueQualifier", "")),
        str(ident.get("applicationName", "")),
        str(item.get("etag", "")),
    ])
    return hashlib.sha256(key.encode("utf-8")).hexdigest()


def flatten(application: str, item: dict) -> list[dict]:
    """One BigQuery row per event inside the activity item."""
    ident = item.get("id", {}) or {}
    actor = item.get("actor", {}) or {}
    now = rfc3339(dt.datetime.now(dt.timezone.utc))
    base_id = insert_id(application, item)
    out: list[dict] = []
    for index, event in enumerate(item.get("events", []) or []):
        params = {}
        for p in event.get("parameters", []) or []:
            if "value" in p:
                params[p.get("name")] = p.get("value")
            elif "boolValue" in p:
                params[p.get("name")] = str(p.get("boolValue"))
            elif "intValue" in p:
                params[p.get("name")] = str(p.get("intValue"))
            elif "multiValue" in p:
                params[p.get("name")] = ",".join(p.get("multiValue") or [])
        out.append({
            "insert_id": f"{base_id}-{index}",
            "event_time": ident.get("time"),
            "application": application,
            "actor_email": (actor.get("email") or "").lower(),
            "actor_profile_id": actor.get("profileId"),
            "ip_address": item.get("ipAddress"),
            "event_type": event.get("type"),
            "event_name": event.get("name"),
            "parameters": json.dumps(params, sort_keys=True),
            "subject": (params.get("USER_EMAIL") or params.get("user_email")
                        or params.get("GROUP_EMAIL") or params.get("group_email")
                        or params.get("ROLE_NAME") or params.get("role_name")),
            "ingested_at": now,
        })
    return out


def land(rows: list[dict]) -> int:
    if not rows:
        return 0
    errors = bq.insert_rows_json(ACTIVITIES, rows, row_ids=[r["insert_id"] for r in rows])
    if errors:
        log("EVE-POLL-ERROR stage=insert detail=" + json.dumps(errors)[:900])
        raise SystemExit(2)
    return len(rows)


def poll(service, application: str) -> int:
    start = rfc3339(watermark(application))
    token = None
    landed = 0
    while True:
        request = service.activities().list(
            userKey="all", applicationName=application, startTime=start,
            maxResults=PAGE_SIZE, pageToken=token)
        try:
            page = request.execute()
        except HttpError as exc:
            # A 403 here usually means the tenant's edition does not share this stream.
            log(f"EVE-POLL-GAP application={application} status={exc.resp.status} "
                f"detail={str(exc)[:200]!r}")
            return -1
        rows: list[dict] = []
        for item in page.get("items", []) or []:
            rows.extend(flatten(application, item))
        landed += land(rows)
        token = page.get("nextPageToken")
        if not token:
            break
    return landed


def emit_findings(since: dt.datetime) -> int:
    """Read the detections view and print one line per match landed since the previous
    run, so a finding is not re-emitted every fifteen minutes. The log-based metric
    counts these lines; the alerting policy mails person B."""
    sql = (f"SELECT rule_id, subject, actor, route, event_time, detail FROM `{FINDINGS}` "
           "WHERE ingested_at > @since ORDER BY event_time")
    job = bq.query(sql, job_config=bigquery.QueryJobConfig(query_parameters=[
        bigquery.ScalarQueryParameter("since", "TIMESTAMP", since)]))
    count = 0
    for row in job.result():
        count += 1
        log("EVE-FINDING route={route} rule={rule} subject={subject} actor={actor} "
            "event_time={ts} detail={detail}".format(
                route=row.route, rule=row.rule_id, subject=row.subject or "-",
                actor=row.actor or "-", ts=row.event_time, detail=(row.detail or "-")[:300]))
    return count


def record_run(landed: int, gaps: list[str], findings: int) -> None:
    bq.insert_rows_json(RUNS, [{
        "run_time": rfc3339(dt.datetime.now(dt.timezone.utc)),
        "rows_landed": landed,
        "findings": findings,
        "gaps": ",".join(gaps) or None,
    }])


def last_run() -> tuple[dt.datetime, int | None]:
    """Previous run time (the floor for new findings) and how many rows it landed."""
    floor = dt.datetime.now(dt.timezone.utc) - dt.timedelta(minutes=60)
    sql = f"SELECT run_time, rows_landed FROM `{RUNS}` ORDER BY run_time DESC LIMIT 1"
    rows = list(bq.query(sql).result())
    if not rows:
        return floor, None
    return (rows[0].run_time or floor), rows[0].rows_landed


def main() -> int:
    since, previous_rows = last_run()
    was_empty = previous_rows == 0
    service = build("admin", "reports_v1", credentials=credentials(), cache_discovery=False)
    landed = 0
    gaps: list[str] = []
    for application in APPS:
        result = poll(service, application)
        if result < 0:
            gaps.append(application)
        else:
            landed += result
    findings = emit_findings(since)
    record_run(landed, gaps, findings)
    log(f"EVE-POLL-OK apps={len(APPS)} rows={landed} findings={findings} "
        f"gaps={','.join(gaps) or '-'}")
    if landed == 0 and was_empty:
        # Two consecutive empty polls. In a quiet tenant this is a real quiet period,
        # and on an attended three-day run the answer is to look, not to suppress it.
        log("EVE-POLL-SILENT two consecutive polls landed no rows")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

```
# build/eve/Procfile
web: python poller.py
```

```
# build/eve/.python-version
3.12
```

**Deploy** (person A, `EVE_PROJECT`):

```bash
gcloud run jobs deploy eve-reports-poller \
  --source=build/eve \
  --region="$REGION" \
  --service-account="eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --set-secrets=UNUSED_MOUNT_CHECK=eve-refresh-token:latest \
  --set-env-vars=EVE_PROJECT="$EVE_PROJECT",APPS=admin,login,token,user_accounts,groups_enterprise \
  --max-retries=1 --task-timeout=10m --project="$EVE_PROJECT"
```

Drop `--set-secrets` entirely if you prefer: the poller reads the credential with
`access_secret_version` and needs only `roles/secretmanager.secretAccessor` on
`eve-refresh-token`. Keeping the flag off is one less copy of the token in the environment;
`gcloud run jobs deploy` has no `--schedule` flag (Google's `run jobs deploy` reference, read
2026-09-17), so the schedule is a separate Cloud Scheduler job:

```bash
gcloud scheduler jobs create http eve-poll-15m \
  --location="$REGION" --schedule='*/15 * * * *' \
  --uri="https://run.googleapis.com/v2/projects/${EVE_PROJECT}/locations/${REGION}/jobs/eve-reports-poller:run" \
  --http-method=POST \
  --oauth-service-account-email="eve-scheduler@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --project="$EVE_PROJECT"
gcloud run jobs add-iam-policy-binding eve-reports-poller --region="$REGION" \
  --member="serviceAccount:eve-scheduler@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/run.invoker --project="$EVE_PROJECT"
```

(URL template and `roles/run.invoker` from Google's "Execute jobs on a schedule" page, read
2026-09-17.)

**Verify:**

```bash
gcloud run jobs execute eve-reports-poller --region="$REGION" --wait --project="$EVE_PROJECT"
gcloud logging read \
  'resource.type="cloud_run_job" AND resource.labels.job_name="eve-reports-poller" AND textPayload:"EVE-POLL-OK"' \
  --limit=1 --freshness=30m --format='value(textPayload)' --project="$EVE_PROJECT"
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  "SELECT application, COUNT(*) n, MAX(event_time) newest FROM \`${EVE_PROJECT}.eve.ws_activities\` GROUP BY application ORDER BY n DESC"
```

Look for: one `EVE-POLL-OK` line with `rows=` greater than zero; at least the `admin` application
in the table; `gaps=` naming any application this edition does not share (record it as a coverage
gap, do not treat it as a stop).

**Undo:** `gcloud scheduler jobs delete eve-poll-15m --location="$REGION" --project="$EVE_PROJECT"`
then `gcloud run jobs delete eve-reports-poller --region="$REGION" --project="$EVE_PROJECT"`. The
landed rows stay; drop the dataset only at the unwind.

---

## §2 `eve/eve_detections.sql`

Six detections and one freshness rule, as one view. The watchlists are rows, not literals, so
person B can change who is watched without touching SQL.

```sql
-- build/eve/eve_detections.sql
-- Run: bq query --use_legacy_sql=false --project_id=$EVE_PROJECT < build/eve/eve_detections.sql

CREATE OR REPLACE VIEW `eve.findings` AS
WITH allowlist AS (
  SELECT LOWER(value) AS value FROM `eve.watchlists` WHERE kind = 'admin_allowlist'
), service_identity AS (
  SELECT LOWER(value) AS value FROM `eve.watchlists` WHERE kind = 'service_identity'
), control_group AS (
  SELECT LOWER(value) AS value FROM `eve.watchlists` WHERE kind = 'control_group'
), acts AS (
  SELECT * FROM `eve.ws_activities`
  WHERE event_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY)
),

-- R1. A role was assigned, created, deleted or had a privilege changed.
r1 AS (
  SELECT 'role_change' AS rule_id, COALESCE(subject, '-') AS subject, actor_email AS actor,
         'person_b' AS route, event_time,
         CONCAT(event_name, ' ', parameters) AS detail, ingested_at
  FROM acts
  WHERE application = 'admin'
    AND REGEXP_CONTAINS(event_name, r'(?i)(ASSIGN_ROLE|UNASSIGN_ROLE|CREATE_ROLE|DELETE_ROLE|UPDATE_ROLE|ADD_PRIVILEGE|REMOVE_PRIVILEGE)')
),

-- R2. An admin action by an actor who is not on the allowlist.
r2 AS (
  SELECT 'admin_actor_outside_allowlist', COALESCE(subject, '-'), actor_email, 'person_b',
         event_time, CONCAT(event_name, ' ', parameters), ingested_at
  FROM acts
  WHERE application = 'admin'
    AND actor_email NOT IN (SELECT value FROM allowlist)
),

-- R3. A change to sharing, API controls, delegation, 2SV or session settings.
r3 AS (
  SELECT 'security_setting_change', COALESCE(subject, '-'), actor_email, 'person_b',
         event_time, CONCAT(event_name, ' ', parameters), ingested_at
  FROM acts
  WHERE application = 'admin'
    AND REGEXP_CONTAINS(event_name, r'(?i)(SHARING|API|TRUSTED_DOMAIN|TWO_STEP|2SV|SESSION|SSO|SECURITY|APP_ACCESS|LESS_SECURE)')
),

-- R4. A domain-wide delegation client was authorised or removed. Absolute 1 says this
-- must never happen on this tenant during the three days.
r4 AS (
  SELECT 'delegation_client_changed', COALESCE(subject, '-'), actor_email, 'person_b_and_sponsor',
         event_time, CONCAT(event_name, ' ', parameters), ingested_at
  FROM acts
  WHERE application = 'admin'
    AND REGEXP_CONTAINS(event_name, r'(?i)(API_CLIENT_ACCESS|DOMAIN_WIDE|AUTHORIZE_API_CLIENT)')
),

-- R5. A service identity signed in.
r5 AS (
  SELECT 'service_identity_login', actor_email, actor_email, 'person_b', event_time,
         CONCAT(event_name, ' ', parameters), ingested_at
  FROM acts
  WHERE application = 'login'
    AND actor_email IN (SELECT value FROM service_identity)
),

-- R6. Membership changed on a control group.
r6 AS (
  SELECT 'control_group_membership', COALESCE(a.subject, '-'), a.actor_email, 'person_b',
         a.event_time, CONCAT(a.event_name, ' ', a.parameters), a.ingested_at
  FROM acts AS a
  WHERE a.application IN ('admin', 'groups_enterprise')
    AND REGEXP_CONTAINS(a.event_name, r'(?i)(GROUP_MEMBER|ADD_GROUP_MEMBER|REMOVE_GROUP_MEMBER)')
    AND EXISTS (SELECT 1 FROM control_group g
                WHERE STRPOS(LOWER(COALESCE(a.parameters, '')), g.value) > 0)
),

-- R7, the freshness rule. The poll runs every 15 minutes; two ticks with no new event
-- means the pipeline is silent, which is itself a finding. It carries CURRENT_TIMESTAMP()
-- as its ingested_at, so it keeps firing for as long as the silence lasts.
r7 AS (
  SELECT 'log_pipeline_silent' AS rule_id, 'eve' AS subject, 'eve' AS actor,
         'person_b' AS route, newest AS event_time,
         CONCAT('newest admin event is ', CAST(age_minutes AS STRING), ' minutes old') AS detail,
         CURRENT_TIMESTAMP() AS ingested_at
  FROM (
    SELECT COALESCE(MAX(event_time), TIMESTAMP('1970-01-01')) AS newest,
           TIMESTAMP_DIFF(CURRENT_TIMESTAMP(),
                          COALESCE(MAX(event_time), TIMESTAMP('1970-01-01')),
                          MINUTE) AS age_minutes
    FROM `eve.ws_activities`
    WHERE application = 'admin'
  )
  WHERE age_minutes > 30
)

SELECT rule_id, subject, actor, route, event_time, detail, ingested_at,
       CURRENT_TIMESTAMP() AS finding_time
FROM (
  SELECT * FROM r1 UNION ALL SELECT * FROM r2 UNION ALL SELECT * FROM r3
  UNION ALL SELECT * FROM r4 UNION ALL SELECT * FROM r5 UNION ALL SELECT * FROM r6
  UNION ALL SELECT * FROM r7
);
```

`ingested_at` is what the poller filters on, so a finding is emitted once, when its row lands, and
not again at every tick.

**Run and verify:**

```bash
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" < build/eve/eve_detections.sql
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  "SELECT rule_id, COUNT(*) n FROM \`${EVE_PROJECT}.eve.findings\` GROUP BY rule_id ORDER BY n DESC"
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  "SELECT DISTINCT event_name FROM \`${EVE_PROJECT}.eve.ws_activities\` WHERE application='admin' ORDER BY 1"
```

Look for: the view creates; the seeded super-admin action of day 1 appears under `r1`, `r2` or
`r3`. `Assumption:` the exact Admin event names above. The third query prints what this tenant
actually emits; if the seeded action is not caught by any rule, widen the regular expression to the
name you can see and record the change. Do not widen it by removing a rule.

**Undo:** `bq rm -f -t "${EVE_PROJECT}:eve.findings"`.

---

## §3 `doer/actions.py`

The action service, and **the only credential holder**. One mutating route, one approval route and
two control routes. It holds the scope `https://www.googleapis.com/auth/admin.directory.user`
(Google's `users.update` reference, read 2026-09-17), which is broader than the privilege the robot
actually has: the boundary is the custom admin role scoped to the pilot organisational unit, not
the scope.

```python
# build/doer/actions.py
#!/usr/bin/env python3.12
"""steward-actions. The only credential holder in the build.

Order of every request, and it never changes:
  1. read the halt flag, per request, never mounted
  2. parse and check the catalogue and the target's shape
  3. WRITE THE AUDIT INTENT ROW, before any Google call; a failed write is a denial
  4. read the target live (organisational unit, admin flags, synthetic prefix)
  5. level 1 forces a dry run and refuses to execute even with a valid approval
  6. check the approval (bound, fresh, unused, not the requester, not a service identity)
  7. mutate, then write the outcome row
"""
from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
import sys
import uuid

from flask import Flask, jsonify, request

PROJECT = os.environ.get("DOER_PROJECT", "")
AGENT_ID = os.environ.get("AGENT_ID", "steward")
PILOT_OU = os.environ.get("PILOT_OU", "/Automation/Pilot")
SYNTHETIC_PREFIX = os.environ.get("SYNTHETIC_PREFIX", "steward-pilot-")
DATASET = os.environ.get("AUDIT_DATASET", "steward_audit")
ACTIONS_TABLE = f"{PROJECT}.{DATASET}.actions"
APPROVALS_TABLE = f"{PROJECT}.{DATASET}.approvals"
HALT_SECRET = os.environ.get("HALT_SECRET", "steward-halt")
CRED_SECRET = os.environ.get("STEWARD_CREDENTIAL_SECRET", "steward-refresh-token")
SERVICE_URL = os.environ.get("SERVICE_URL", "")
APPROVERS = {e.strip().lower() for e in os.environ.get("APPROVERS", "").split(",") if e.strip()}
LEVEL_CAP = int(os.environ.get("LEVEL_CAP", "2"))
APPROVAL_TTL_SECONDS = int(os.environ.get("APPROVAL_TTL_SECONDS", "900"))
TOKEN_URI = "https://oauth2.googleapis.com/token"
SCOPES = ["https://www.googleapis.com/auth/admin.directory.user"]

# The whole catalogue. One reversible pair, and nothing else exists.
CATALOGUE = {
    "suspend": {"field": "suspended", "value": True, "inverse": "restore"},
    "restore": {"field": "suspended", "value": False, "inverse": "suspend"},
}
PROTECTED_SUFFIXES = (".gserviceaccount.com",)


def now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def stamp(value: dt.datetime) -> str:
    return value.astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def request_hash(operation: str, target: str, level: int) -> str:
    body = json.dumps({"operation": operation, "target": target, "level": level}, sort_keys=True)
    return hashlib.sha256(body.encode("utf-8")).hexdigest()


def is_service_identity(email: str) -> bool:
    email = (email or "").lower()
    return email.endswith(PROTECTED_SUFFIXES) or "robot" in email.split("@")[0]


class Denied(Exception):
    def __init__(self, reason: str, status: int = 403) -> None:
        super().__init__(reason)
        self.reason = reason
        self.status = status


class GoogleBackend:
    """Everything that talks to Google. Replaced wholesale by FakeBackend in --selftest."""

    def __init__(self) -> None:
        self._bq = None
        self._sm = None
        self._directory = None

    @property
    def bq(self):
        if self._bq is None:
            from google.cloud import bigquery
            self._bq = bigquery.Client(project=PROJECT)
        return self._bq

    @property
    def sm(self):
        if self._sm is None:
            from google.cloud import secretmanager
            self._sm = secretmanager.SecretManagerServiceClient()
        return self._sm

    # ---- absolute 6: the halt is read per request and never mounted -------------
    def halt_state(self) -> str:
        name = f"projects/{PROJECT}/secrets/{HALT_SECRET}/versions/latest"
        data = self.sm.access_secret_version(request={"name": name}).payload.data
        return data.decode("utf-8").strip().lower()

    def set_halt(self) -> str:
        parent = f"projects/{PROJECT}/secrets/{HALT_SECRET}"
        version = self.sm.add_secret_version(
            request={"parent": parent, "payload": {"data": b"on"}})
        return version.name

    # ---- absolute 8: write-ahead audit -----------------------------------------
    def audit(self, row: dict) -> None:
        errors = self.bq.insert_rows_json(ACTIONS_TABLE, [row], row_ids=[row["row_id"]])
        if errors:
            raise Denied("audit_unavailable", status=503)

    def record_approval(self, row: dict) -> None:
        errors = self.bq.insert_rows_json(APPROVALS_TABLE, [row], row_ids=[row["nonce"]])
        if errors:
            raise Denied("approval_not_recorded", status=503)

    def approval(self, nonce: str) -> dict | None:
        from google.cloud import bigquery
        sql = (f"SELECT nonce, request_hash, approver, created_at FROM `{APPROVALS_TABLE}` "
               "WHERE nonce = @n LIMIT 1")
        job = self.bq.query(sql, job_config=bigquery.QueryJobConfig(query_parameters=[
            bigquery.ScalarQueryParameter("n", "STRING", nonce)]))
        rows = list(job.result())
        if not rows:
            return None
        row = rows[0]
        return {"nonce": row.nonce, "request_hash": row.request_hash,
                "approver": row.approver, "created_at": row.created_at}

    def nonce_used(self, nonce: str) -> bool:
        from google.cloud import bigquery
        sql = (f"SELECT COUNT(*) AS n FROM `{ACTIONS_TABLE}` "
               "WHERE approval_nonce = @n AND phase = 'outcome' AND verdict = 'executed'")
        job = self.bq.query(sql, job_config=bigquery.QueryJobConfig(query_parameters=[
            bigquery.ScalarQueryParameter("n", "STRING", nonce)]))
        return list(job.result())[0].n > 0

    # ---- the one credential -----------------------------------------------------
    @property
    def directory(self):
        if self._directory is None:
            from google.oauth2.credentials import Credentials
            from googleapiclient.discovery import build
            name = f"projects/{PROJECT}/secrets/{CRED_SECRET}/versions/latest"
            blob = json.loads(
                self.sm.access_secret_version(request={"name": name}).payload.data.decode("utf-8"))
            creds = Credentials(token=None, refresh_token=blob["refresh_token"],
                                client_id=blob["client_id"], client_secret=blob["client_secret"],
                                token_uri=TOKEN_URI, scopes=SCOPES)
            self._directory = build("admin", "directory_v1", credentials=creds,
                                    cache_discovery=False)
        return self._directory

    def read_user(self, target: str) -> dict:
        from googleapiclient.errors import HttpError
        try:
            return self.directory.users().get(userKey=target, projection="basic").execute()
        except HttpError as exc:
            raise Denied(f"target_unreadable_{exc.resp.status}", status=403) from exc

    def write_user(self, target: str, field: str, value) -> str:
        from googleapiclient.errors import HttpError
        try:
            self.directory.users().update(userKey=target, body={field: value}).execute()
            return "200"
        except HttpError as exc:
            return f"google_error_{exc.resp.status}"


def caller_email(backend) -> str:
    """The invoker's identity, taken from the verified ID token Cloud Run passed through.

    Cloud Run has already refused anyone without run.invoker; this reads who it was.
    """
    header = request.headers.get("Authorization", "")
    if not header.lower().startswith("bearer "):
        raise Denied("caller_unidentified", status=401)
    token = header.split(" ", 1)[1]
    from google.auth.transport import requests as grequests
    from google.oauth2 import id_token
    try:
        claims = id_token.verify_oauth2_token(token, grequests.Request(),
                                              audience=SERVICE_URL or None)
    except Exception as exc:  # noqa: BLE001 - any failure here is a refusal
        raise Denied("caller_token_invalid", status=401) from exc
    email = (claims.get("email") or "").lower()
    if not email:
        raise Denied("caller_unidentified", status=401)
    return email


def check_approval(approval: dict, requester: str, rhash: str, backend) -> None:
    if not approval or not approval.get("nonce"):
        raise Denied("approval_missing")
    record = backend.approval(approval["nonce"])
    if record is None:
        raise Denied("approval_unknown")
    if record["request_hash"] != rhash:
        raise Denied("approval_mismatch")
    approver = (record["approver"] or "").lower()
    if approver == requester.lower():
        raise Denied("self_approval")
    if is_service_identity(approver):
        raise Denied("approver_not_human")
    if APPROVERS and approver not in APPROVERS:
        raise Denied("approver_not_authorised")
    age = (now() - record["created_at"]).total_seconds()
    if age > APPROVAL_TTL_SECONDS:
        raise Denied("approval_expired")
    if backend.nonce_used(approval["nonce"]):
        raise Denied("approval_replayed")


def audit_row(ctx: dict, phase: str, verdict: str, reason: str | None,
              google_status: str | None = None) -> dict:
    return {
        "row_id": f"{ctx['request_id']}-{phase}",
        "ts": stamp(now()),
        "agent_id": AGENT_ID,
        "request_id": ctx["request_id"],
        "phase": phase,
        "operation": ctx["operation"],
        "target": ctx["target"],
        "level": ctx["level"],
        "requester": ctx["requester"],
        "approver": ctx.get("approver"),
        "approval_nonce": ctx.get("nonce"),
        "verdict": verdict,
        "denial_reason": reason,
        "request_hash": ctx["request_hash"],
        "dry_run": ctx["dry_run"],
        "halt_state": ctx["halt_state"],
        "google_status": google_status,
        "detail": ctx.get("detail"),
    }


def handle(payload: dict, requester: str, backend) -> tuple[dict, int]:
    operation = (payload.get("operation") or "").strip().lower()
    target = (payload.get("target") or "").strip().lower()
    level = int(payload.get("level", 1))
    approval = payload.get("approval") or {}
    ctx = {
        "request_id": payload.get("request_id") or str(uuid.uuid4()),
        "operation": operation, "target": target, "level": level,
        "requester": requester, "approver": None, "nonce": approval.get("nonce"),
        "request_hash": request_hash(operation, target, level),
        "dry_run": bool(payload.get("dry_run")) or level <= 1,
        "halt_state": "unknown", "detail": None,
    }

    def refuse(reason: str, status: int = 403) -> tuple[dict, int]:
        try:
            backend.audit(audit_row(ctx, "outcome", "denied", reason))
        except Denied:
            pass  # a denial that cannot be audited is still a denial
        return ({"verdict": "denied", "denial_reason": reason,
                 "request_id": ctx["request_id"]}, status)

    # 1. halt, per request, never mounted
    try:
        ctx["halt_state"] = backend.halt_state()
    except Exception:  # noqa: BLE001 - if the flag cannot be read, assume halted
        return refuse("halt_unreadable", 503)
    if ctx["halt_state"] != "off":
        return refuse("halted")

    # 2. catalogue and target shape, before any Google call
    if operation not in CATALOGUE:
        return refuse("not_catalogued")
    if not target.endswith(f"@{os.environ.get('ORG_DOMAIN', target.split('@')[-1])}"):
        return refuse("target_not_in_tenant")
    if not target.split("@")[0].startswith(SYNTHETIC_PREFIX):
        return refuse("not_synthetic")
    if is_service_identity(target):
        return refuse("protected_principal")
    if level > LEVEL_CAP:
        return refuse("level_above_cap")

    # 3. WRITE-AHEAD AUDIT. Nothing below this line runs if this insert fails.
    try:
        backend.audit(audit_row(ctx, "intent", "attempting", None))
    except Denied as exc:
        return ({"verdict": "denied", "denial_reason": exc.reason,
                 "request_id": ctx["request_id"]}, exc.status)

    # 4. the target, read live
    try:
        user = backend.read_user(target)
    except Denied as exc:
        return refuse(exc.reason, exc.status)
    if (user.get("orgUnitPath") or "") != PILOT_OU:
        return refuse("out_of_scope_ou")
    if user.get("isAdmin") or user.get("isDelegatedAdmin"):
        return refuse("protected_principal")
    ctx["detail"] = f"ou={user.get('orgUnitPath')} suspended={user.get('suspended')}"

    # 5. level 1 forces a dry run and refuses to execute even with a valid approval
    if ctx["dry_run"]:
        would = CATALOGUE[operation]["value"]
        ctx["detail"] = f"{ctx['detail']} would_set_{CATALOGUE[operation]['field']}={would}"
        try:
            backend.audit(audit_row(ctx, "outcome", "dry_run",
                                    "l1_dry_run_forced" if level <= 1 else "dry_run_requested"))
        except Denied as exc:
            return ({"verdict": "denied", "denial_reason": exc.reason,
                     "request_id": ctx["request_id"]}, exc.status)
        return ({"verdict": "dry_run", "would_set": {CATALOGUE[operation]["field"]: would},
                 "executed": False, "request_id": ctx["request_id"]}, 200)

    # 6. the approval
    try:
        check_approval(approval, requester, ctx["request_hash"], backend)
    except Denied as exc:
        return refuse(exc.reason, exc.status)
    ctx["approver"] = (backend.approval(approval["nonce"]) or {}).get("approver")

    # 7. mutate, then the outcome row
    spec = CATALOGUE[operation]
    status = backend.write_user(target, spec["field"], spec["value"])
    verdict = "executed" if status == "200" else "error"
    try:
        backend.audit(audit_row(ctx, "outcome", verdict,
                                None if verdict == "executed" else status,
                                google_status=status))
    except Denied as exc:
        # The call happened. An unrecorded outcome after a recorded intent is a stop:
        # say so loudly and let person B reconcile against the Admin log.
        return ({"verdict": verdict, "denial_reason": f"outcome_{exc.reason}",
                 "request_id": ctx["request_id"], "reconcile_against_admin_log": True}, 500)
    if verdict != "executed":
        return ({"verdict": "error", "denial_reason": status,
                 "request_id": ctx["request_id"]}, 502)
    return ({"verdict": "executed", "inverse": spec["inverse"], "executed": True,
             "request_id": ctx["request_id"]}, 200)


app = Flask(__name__)
BACKEND = GoogleBackend()


@app.post("/act")
def act():
    try:
        requester = caller_email(BACKEND)
    except Denied as exc:
        return jsonify({"verdict": "denied", "denial_reason": exc.reason}), exc.status
    body, status = handle(request.get_json(force=True, silent=True) or {}, requester, BACKEND)
    return jsonify(body), status


@app.post("/approve")
def approve():
    """The approval surface. One authenticated call from the approver's own account."""
    try:
        approver = caller_email(BACKEND)
    except Denied as exc:
        return jsonify({"denial_reason": exc.reason}), exc.status
    if is_service_identity(approver):
        return jsonify({"denial_reason": "approver_not_human"}), 403
    if APPROVERS and approver not in APPROVERS:
        return jsonify({"denial_reason": "approver_not_authorised"}), 403
    payload = request.get_json(force=True, silent=True) or {}
    operation = (payload.get("operation") or "").strip().lower()
    target = (payload.get("target") or "").strip().lower()
    level = int(payload.get("level", 2))
    if operation not in CATALOGUE:
        return jsonify({"denial_reason": "not_catalogued"}), 403
    nonce = str(uuid.uuid4())
    BACKEND.record_approval({
        "nonce": nonce, "request_hash": request_hash(operation, target, level),
        "approver": approver, "created_at": stamp(now()),
        "operation": operation, "target": target, "level": level,
    })
    return jsonify({"nonce": nonce, "expires_in_seconds": APPROVAL_TTL_SECONDS,
                    "approver": approver}), 200


# ---- control endpoint 1: what is this service doing right now ------------------
@app.get("/control/status")
def control_status():
    try:
        halt = BACKEND.halt_state()
    except Exception:  # noqa: BLE001
        halt = "unreadable"
    return jsonify({
        "agent_id": AGENT_ID, "halt": halt, "level_cap": LEVEL_CAP,
        "pilot_ou": PILOT_OU, "synthetic_prefix": SYNTHETIC_PREFIX,
        "audit_table": ACTIONS_TABLE, "catalogue": sorted(CATALOGUE),
        "approval_ttl_seconds": APPROVAL_TTL_SECONDS,
        "approvers_configured": len(APPROVERS),
    }), 200


# ---- control endpoint 2: K0, the halt. It only ever tightens -------------------
@app.post("/control/halt")
def control_halt():
    try:
        caller = caller_email(BACKEND)
    except Denied as exc:
        return jsonify({"denial_reason": exc.reason}), exc.status
    if is_service_identity(caller):
        return jsonify({"denial_reason": "halt_caller_not_human"}), 403
    version = BACKEND.set_halt()
    return jsonify({"halt": "on", "version": version, "pulled_by": caller,
                    "note": "clearing a halt is done out of band by two people"}), 200


# ---- the offline self-test: eight negatives and one reversible pair ------------
class FakeBackend:
    def __init__(self, halt="off", audit_fails=False, ou=PILOT_OU, is_admin=False) -> None:
        self.halt = halt
        self.audit_fails = audit_fails
        self.ou = ou
        self.is_admin = is_admin
        self.rows: list[dict] = []
        self.approvals: dict[str, dict] = {}
        self.used: set[str] = set()
        self.writes: list[tuple[str, str, object]] = []
        self.users: dict[str, dict] = {}

    def halt_state(self) -> str:
        return self.halt

    def set_halt(self) -> str:
        self.halt = "on"
        return "fake/versions/1"

    def audit(self, row: dict) -> None:
        if self.audit_fails:
            raise Denied("audit_unavailable", status=503)
        self.rows.append(row)

    def record_approval(self, row: dict) -> None:
        self.approvals[row["nonce"]] = row

    def approval(self, nonce: str) -> dict | None:
        row = self.approvals.get(nonce)
        if row is None:
            return None
        created = row["created_at"]
        if isinstance(created, str):
            created = dt.datetime.strptime(created, "%Y-%m-%dT%H:%M:%S.%fZ").replace(
                tzinfo=dt.timezone.utc)
        return {"nonce": nonce, "request_hash": row["request_hash"],
                "approver": row["approver"], "created_at": created}

    def nonce_used(self, nonce: str) -> bool:
        return nonce in self.used

    def read_user(self, target: str) -> dict:
        return self.users.get(target, {
            "primaryEmail": target, "orgUnitPath": self.ou,
            "isAdmin": self.is_admin, "isDelegatedAdmin": False, "suspended": False})

    def write_user(self, target: str, field: str, value) -> str:
        self.writes.append((target, field, value))
        user = self.read_user(target)
        user[field] = value
        self.users[target] = user
        return "200"


def selftest() -> int:
    good = f"{SYNTHETIC_PREFIX}01@{os.environ.get('ORG_DOMAIN', 'example.test')}"
    requester = "person-a@example.test"
    approver = "person-b@example.test"
    globals()["APPROVERS"] = {approver}
    failures: list[str] = []

    def case(name: str, condition: bool, detail: str = "") -> None:
        print(f"{'PASS' if condition else 'FAIL'} {name} {detail}".rstrip())
        if not condition:
            failures.append(name)

    def approve_for(backend, operation, target, level, who=approver):
        nonce = str(uuid.uuid4())
        backend.record_approval({
            "nonce": nonce, "request_hash": request_hash(operation, target, level),
            "approver": who, "created_at": stamp(now())})
        return {"nonce": nonce}

    # N1 halted
    b = FakeBackend(halt="on")
    body, _ = handle({"operation": "suspend", "target": good, "level": 2,
                      "approval": approve_for(b, "suspend", good, 2)}, requester, b)
    case("N1 halt refuses", body["denial_reason"] == "halted" and not b.writes)

    # N2 target outside the pilot organisational unit
    b = FakeBackend(ou="/Staff")
    body, _ = handle({"operation": "suspend", "target": good, "level": 2,
                      "approval": approve_for(b, "suspend", good, 2)}, requester, b)
    case("N2 out of scope refused", body["denial_reason"] == "out_of_scope_ou" and not b.writes)

    # N3 a real or privileged account
    b = FakeBackend(is_admin=True)
    body, _ = handle({"operation": "suspend", "target": good, "level": 2,
                      "approval": approve_for(b, "suspend", good, 2)}, requester, b)
    case("N3 protected principal refused",
         body["denial_reason"] == "protected_principal" and not b.writes)

    # N4 the audit write fails
    b = FakeBackend(audit_fails=True)
    body, status = handle({"operation": "suspend", "target": good, "level": 2}, requester, b)
    case("N4 audit_unavailable refuses",
         body["denial_reason"] == "audit_unavailable" and status == 503 and not b.writes)

    # N5 level 1 forces a dry run and refuses even a valid approval
    b = FakeBackend()
    body, _ = handle({"operation": "suspend", "target": good, "level": 1,
                      "approval": approve_for(b, "suspend", good, 1)}, requester, b)
    case("N5 L1 forces dry run",
         body["verdict"] == "dry_run" and body["executed"] is False and not b.writes)

    # N6 self-approval
    b = FakeBackend()
    body, _ = handle({"operation": "suspend", "target": good, "level": 2,
                      "approval": approve_for(b, "suspend", good, 2, who=requester)},
                     requester, b)
    case("N6 self-approval refused", body["denial_reason"] == "self_approval" and not b.writes)

    # N7 a service identity as approver
    b = FakeBackend()
    body, _ = handle({"operation": "suspend", "target": good, "level": 2,
                      "approval": approve_for(b, "suspend", good, 2,
                                              who="sa@p.iam.gserviceaccount.com")},
                     requester, b)
    case("N7 service identity cannot approve",
         body["denial_reason"] == "approver_not_human" and not b.writes)

    # N8 an approval bound to a different request
    b = FakeBackend()
    other = f"{SYNTHETIC_PREFIX}02@{os.environ.get('ORG_DOMAIN', 'example.test')}"
    body, _ = handle({"operation": "suspend", "target": good, "level": 2,
                      "approval": approve_for(b, "suspend", other, 2)}, requester, b)
    case("N8 approval mismatch refused",
         body["denial_reason"] == "approval_mismatch" and not b.writes)

    # The positive: the pair executes, audit is written ahead, the inverse restores
    b = FakeBackend()
    body, _ = handle({"operation": "suspend", "target": good, "level": 2,
                      "approval": approve_for(b, "suspend", good, 2)}, requester, b)
    ahead = [r["phase"] for r in b.rows][:1] == ["intent"]
    case("P1 approved suspend executes", body["verdict"] == "executed" and b.writes)
    case("P2 audit row written ahead of the call", ahead)
    body, _ = handle({"operation": "restore", "target": good, "level": 2,
                      "approval": approve_for(b, "restore", good, 2)}, requester, b)
    case("P3 inverse restores",
         body["verdict"] == "executed" and b.users[good]["suspended"] is False)

    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        raise SystemExit(selftest())
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
```

```
# build/doer/Procfile
web: gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 actions:app
```

```
# build/doer/.python-version
3.12
```

**Self-test first, before any deploy** (person A, in D2-A1):

```bash
python3.12 -m venv /tmp/steward-venv && /tmp/steward-venv/bin/pip install -r build/doer/requirements.txt
ORG_DOMAIN="$ORG_DOMAIN" PILOT_OU="$PILOT_OU" SYNTHETIC_PREFIX="$SYNTHETIC_PREFIX" \
  /tmp/steward-venv/bin/python build/doer/actions.py --selftest
```

Look for: eleven `PASS` lines and `0 failure(s)`. A single `FAIL` stops the day; fix the code, not
the test.

**Deploy** (person A, `DOER_PROJECT`):

```bash
gcloud run deploy steward-actions \
  --source=build/doer \
  --region="$REGION" --no-allow-unauthenticated \
  --service-account="steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --set-env-vars=DOER_PROJECT="$DOER_PROJECT",ORG_DOMAIN="$ORG_DOMAIN",AGENT_ID="$AGENT_ID",PILOT_OU="$PILOT_OU",SYNTHETIC_PREFIX="$SYNTHETIC_PREFIX",APPROVERS="$PERSON_B",LEVEL_CAP=2 \
  --project="$DOER_PROJECT"
DOER_URL=$(gcloud run services describe steward-actions --region="$REGION" \
  --format='value(status.url)' --project="$DOER_PROJECT")
gcloud run services update steward-actions --region="$REGION" \
  --update-env-vars=SERVICE_URL="$DOER_URL" --project="$DOER_PROJECT"
gcloud run services add-iam-policy-binding steward-actions --region="$REGION" \
  --member="user:${PERSON_B}" --role=roles/run.invoker --project="$DOER_PROJECT"
```

The credential secret is deliberately **not** passed with `--set-secrets`: the service reads it
with `access_secret_version` under `roles/secretmanager.secretAccessor` on
`steward-refresh-token`, and reads `steward-halt` the same way, **per request**.

**Verify:**

```bash
TOKEN=$(gcloud auth print-identity-token --audiences="$DOER_URL")
curl -s -H "Authorization: Bearer $TOKEN" "$DOER_URL/control/status" | python3.12 -m json.tool
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"operation\":\"suspend\",\"target\":\"${SYNTHETIC_PREFIX}01@${ORG_DOMAIN}\",\"level\":1}" \
  "$DOER_URL/act" | python3.12 -m json.tool
bq query --use_legacy_sql=false --project_id="$DOER_PROJECT" \
  "SELECT ts, phase, verdict, denial_reason, dry_run FROM \`${DOER_PROJECT}.steward_audit.actions\` ORDER BY ts DESC LIMIT 5"
```

Look for: `"halt": "off"` and `"level_cap": 2` from the status route; `"verdict": "dry_run"` with
`"executed": false`; two rows in the audit table, `intent` written before `outcome`. An
unauthenticated `curl` with no token must return 403 from Cloud Run itself.

**Undo:** `gcloud run services delete steward-actions --region="$REGION" --project="$DOER_PROJECT"`.
The audit rows are insert-only and stay.

---

## §4 `doer/plan.py`

Asks a Gemini model for a plan. **It holds no Admin SDK credential, has no `run.invoker` on the
action service and no `secretAccessor`, and it cannot approve.** A human reads the plan and pastes
it into the request.

```python
# build/doer/plan.py
#!/usr/bin/env python3.12
"""steward-plan. Turn one operator sentence into a JSON plan. Holds nothing."""
from __future__ import annotations

import json
import os
import sys

from google import genai
from google.genai import types

PROJECT = os.environ["DOER_PROJECT"]
LOCATION = os.environ.get("VERTEX_LOCATION", "europe-west1")
MODEL_ID = os.environ.get("MODEL_ID", "gemini-2.5-flash")
PILOT_OU = os.environ.get("PILOT_OU", "/Automation/Pilot")
SYNTHETIC_PREFIX = os.environ.get("SYNTHETIC_PREFIX", "steward-pilot-")

CATALOGUE = [
    {"operation": "suspend", "inverse": "restore",
     "scope": f"accounts in {PILOT_OU} whose local part starts with {SYNTHETIC_PREFIX}"},
    {"operation": "restore", "inverse": "suspend",
     "scope": f"accounts in {PILOT_OU} whose local part starts with {SYNTHETIC_PREFIX}"},
]

SYSTEM = (
    "You plan one administrative action and nothing else. You may only choose an operation "
    "from the catalogue you are given. You never approve anything, you never hold a credential, "
    "and you never claim an action was performed. Reply with JSON only, with the keys "
    "operation, target, level, reason, inverse. level is always 1 unless the operator's sentence "
    "says the word execute, in which case it is 2. If the request is not in the catalogue, reply "
    "with {\"operation\": null, \"reason\": \"not in catalogue\"}."
)


def plan(sentence: str) -> dict:
    client = genai.Client(vertexai=True, project=PROJECT, location=LOCATION)
    prompt = (f"Catalogue: {json.dumps(CATALOGUE)}\n"
              f"Operator sentence: {sentence}\n"
              "JSON only.")
    response = client.models.generate_content(
        model=MODEL_ID, contents=prompt,
        config=types.GenerateContentConfig(system_instruction=SYSTEM, temperature=0,
                                           response_mime_type="application/json"))
    text = (response.text or "").strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {"operation": None, "reason": "model did not return JSON", "raw": text[:500]}


def main() -> int:
    sentence = " ".join(sys.argv[1:]) or os.environ.get("SENTENCE", "")
    if not sentence:
        print("usage: plan.py <one sentence>", file=sys.stderr)
        return 2
    result = plan(sentence)
    result["carries_credential"] = False
    result["can_approve"] = False
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

**Deploy** as a separate job. Copy `plan.py`, `requirements.txt` and `.python-version` into
`build/plan/` with its own one-line `Procfile` (`web: python plan.py`), so the buildpack does not
pick up the Flask entrypoint:

```bash
mkdir -p build/plan && cp build/doer/plan.py build/doer/.python-version build/plan/
printf 'web: python plan.py\n' > build/plan/Procfile
printf 'google-genai==1.46.0\n' > build/plan/requirements.txt   # Assumption: re-pin, see §8
gcloud run jobs deploy steward-plan --source=build/plan --region="$REGION" \
  --service-account="steward-plan@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --set-env-vars=DOER_PROJECT="$DOER_PROJECT",MODEL_ID=gemini-2.5-flash,VERTEX_LOCATION="$REGION",PILOT_OU="$PILOT_OU",SYNTHETIC_PREFIX="$SYNTHETIC_PREFIX" \
  --max-retries=0 --project="$DOER_PROJECT"
```

**Verify** that it plans, and that it holds nothing:

```bash
gcloud run jobs execute steward-plan --region="$REGION" --wait \
  --args="dry run a suspend on ${SYNTHETIC_PREFIX}01@${ORG_DOMAIN}" --project="$DOER_PROJECT"
gcloud projects get-iam-policy "$DOER_PROJECT" --flatten='bindings[].members' \
  --filter="bindings.members:steward-plan@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --format='value(bindings.role)' --project="$DOER_PROJECT"
gcloud run services get-iam-policy steward-actions --region="$REGION" \
  --format=json --project="$DOER_PROJECT" | grep -c "steward-plan@" || echo "0 - plan cannot invoke"
```

Look for: a JSON plan with `"level": 1` and `"carries_credential": false`; the IAM listing showing
`roles/aiplatform.user` and nothing else, in particular no `roles/secretmanager.secretAccessor`;
and `0 - plan cannot invoke`.

**Undo:** `gcloud run jobs delete steward-plan --region="$REGION" --project="$DOER_PROJECT"`.

---

## §5 `mo/mo.sql`

Five views over the audit table, every one keyed on `agent_id`, then the scorecard.

```sql
-- build/mo/mo.sql
-- Run: bq query --use_legacy_sql=false --project_id=$DOER_PROJECT < build/mo/mo.sql
-- The views live beside the audit table so no cross-project read is needed on day 3.

-- Person B loads this table in D3-B1. It is created empty here so the scorecard runs
-- on day 3 morning whether or not the baseline has landed yet.
CREATE TABLE IF NOT EXISTS `steward_audit.retrospective_volume` (
  event_date DATE, event_name STRING, events INT64, window_start DATE, window_end DATE
);

CREATE OR REPLACE VIEW `steward_audit.mo_volume_by_verdict` AS
SELECT agent_id, DATE(ts) AS day, verdict, COUNT(*) AS n
FROM `steward_audit.actions`
WHERE phase = 'outcome'
GROUP BY agent_id, day, verdict;

CREATE OR REPLACE VIEW `steward_audit.mo_denial_reasons` AS
SELECT agent_id, denial_reason, COUNT(*) AS n, MIN(ts) AS first_seen, MAX(ts) AS last_seen
FROM `steward_audit.actions`
WHERE phase = 'outcome' AND verdict = 'denied'
GROUP BY agent_id, denial_reason;

CREATE OR REPLACE VIEW `steward_audit.mo_dry_run_ratio` AS
SELECT agent_id,
       COUNTIF(verdict = 'dry_run') AS dry_runs,
       COUNTIF(verdict = 'executed') AS executions,
       SAFE_DIVIDE(COUNTIF(verdict = 'dry_run'),
                   COUNTIF(verdict IN ('dry_run', 'executed'))) AS dry_run_ratio
FROM `steward_audit.actions`
WHERE phase = 'outcome'
GROUP BY agent_id;

CREATE OR REPLACE VIEW `steward_audit.mo_approval_latency` AS
SELECT a.agent_id,
       a.request_id,
       a.approver,
       TIMESTAMP_DIFF(a.ts, p.created_at, SECOND) AS approval_to_execution_seconds
FROM `steward_audit.actions` a
JOIN `steward_audit.approvals` p ON p.nonce = a.approval_nonce
WHERE a.phase = 'outcome' AND a.verdict = 'executed';

CREATE OR REPLACE VIEW `steward_audit.mo_pair_completion` AS
WITH pairs AS (
  SELECT agent_id, target,
         COUNTIF(operation = 'suspend' AND verdict = 'executed') AS suspends,
         COUNTIF(operation = 'restore' AND verdict = 'executed') AS restores
  FROM `steward_audit.actions`
  WHERE phase = 'outcome'
  GROUP BY agent_id, target
)
SELECT agent_id, target, suspends, restores,
       suspends = restores AS pair_complete
FROM pairs;

-- The scorecard. One page. The minutes line is literal and is never softened.
SELECT
  'steward' AS agent_id,
  (SELECT SUM(n) FROM `steward_audit.mo_volume_by_verdict` WHERE verdict = 'executed') AS executed,
  (SELECT SUM(n) FROM `steward_audit.mo_volume_by_verdict` WHERE verdict = 'dry_run') AS dry_runs,
  (SELECT SUM(n) FROM `steward_audit.mo_volume_by_verdict` WHERE verdict = 'denied') AS denied,
  (SELECT STRING_AGG(CONCAT(denial_reason, '=', CAST(n AS STRING)), '; ' ORDER BY n DESC)
     FROM `steward_audit.mo_denial_reasons`) AS denial_reasons,
  (SELECT ROUND(dry_run_ratio, 3) FROM `steward_audit.mo_dry_run_ratio` LIMIT 1) AS dry_run_ratio,
  (SELECT ROUND(AVG(approval_to_execution_seconds), 1)
     FROM `steward_audit.mo_approval_latency`) AS mean_approval_latency_seconds,
  (SELECT COUNTIF(pair_complete) FROM `steward_audit.mo_pair_completion`) AS complete_pairs,
  (SELECT SUM(events) FROM `steward_audit.retrospective_volume`) AS retrospective_event_volume,
  'No human minute was saved. The doer acted only on synthetic accounts, and the retrospective '
  'figure is a volume of past events, never a time.' AS minutes_saved_statement;
```

The retrospective table is loaded by person B in D3-B1 from the Admin console export, reduced to
counts with the actor column dropped:

```bash
bq load --source_format=CSV --skip_leading_rows=1 --project_id="$DOER_PROJECT" \
  "${DOER_PROJECT}:steward_audit.retrospective_volume" /tmp/retro-counts.csv
```

**Verify:** `bq query --use_legacy_sql=false --project_id="$DOER_PROJECT" < build/mo/mo.sql` prints
one scorecard row whose `executed` and `complete_pairs` match what day 2 actually did, counted by
hand. **Undo:** `bq rm -f -t` each view; the tables stay.

---

## §6 `tools/consent.py`

Run once per robot, at one keyboard, with both people present. The refresh token never touches
disk and is never printed.

```python
# build/tools/consent.py
#!/usr/bin/env python3.12
"""One robot, one client, one scope, one consent. Not domain-wide delegation.

Usage:
  python3.12 tools/consent.py --client-json=/path/client.json \
      --scope=https://www.googleapis.com/auth/admin.reports.audit.readonly \
      --secret=eve-refresh-token --project=$EVE_PROJECT
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys

from google_auth_oauthlib.flow import InstalledAppFlow


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--client-json", required=True)
    parser.add_argument("--scope", required=True, action="append",
                        help="repeat only if the design says more than one scope")
    parser.add_argument("--secret", required=True)
    parser.add_argument("--project", required=True)
    args = parser.parse_args()

    with open(args.client_json, "r", encoding="utf-8") as handle:
        client_config = json.load(handle)
    installed = client_config.get("installed") or client_config.get("web") or {}
    if not installed.get("client_id"):
        print("STOP: this is not a Desktop app client JSON", file=sys.stderr)
        return 2

    flow = InstalledAppFlow.from_client_config(client_config, scopes=args.scope)
    creds = flow.run_local_server(port=0, access_type="offline", prompt="consent")

    granted = sorted(creds.scopes or [])
    if granted != sorted(args.scope):
        print(f"STOP: granted scopes are {granted}, asked for {sorted(args.scope)}",
              file=sys.stderr)
        return 3
    if not creds.refresh_token:
        print("STOP: no refresh token returned; re-run with a fresh consent", file=sys.stderr)
        return 4

    blob = json.dumps({
        "client_id": installed["client_id"],
        "client_secret": installed["client_secret"],
        "refresh_token": creds.refresh_token,
    })
    # Straight into Secret Manager on stdin. Nothing is written to disk and nothing is echoed.
    result = subprocess.run(
        ["gcloud", "secrets", "versions", "add", args.secret,
         "--data-file=-", "--project", args.project],
        input=blob.encode("utf-8"), capture_output=True, check=False)
    if result.returncode != 0:
        print("STOP: secret write failed: " + result.stderr.decode("utf-8")[:400], file=sys.stderr)
        return 5
    print("granted scopes: " + ", ".join(granted))
    print("secret version: " + result.stderr.decode("utf-8").strip().splitlines()[-1][:200])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

**Run** (both people present, no screen share, the browser signed in as the robot only):

```bash
python3.12 build/tools/consent.py --client-json="$HOME/eve-client.json" \
  --scope=https://www.googleapis.com/auth/admin.reports.audit.readonly \
  --secret=eve-refresh-token --project="$EVE_PROJECT"
shred -u "$HOME/eve-client.json" 2>/dev/null || rm -P "$HOME/eve-client.json"
```

**Verify:** exactly one scope printed; a secret version line printed; then, in the Admin console,
**Security > Access and data control > API controls > Manage Domain Wide Delegation**, this
client id is **absent** (Google's domain-wide delegation page, read 2026-09-17). For the doer's
sitting the scope is `https://www.googleapis.com/auth/admin.directory.user` and the secret is
`steward-refresh-token`.

**Undo, and this is K4:** the robot revokes the grant at myaccount.google.com under
**Data and privacy > Third-party apps and services**, then
`gcloud secrets versions disable <version> --secret=steward-refresh-token --project="$DOER_PROJECT"`.
Record that an access token already issued may remain valid for up to an hour, so the halt (K0) is
what stops work now.

---

## §7 `tools/bootstrap.sh`

Everything a project needs before any code is deployed. It prints each command before running it
and stops on the first failure. No `--yes` on anything destructive, no default project, no secret
echoed.

```bash
#!/usr/bin/env bash
# build/tools/bootstrap.sh
# Run: bash build/tools/bootstrap.sh
set -euo pipefail

run() { printf '+ %s\n' "$*"; "$@"; }

: "${ORG_DOMAIN:?}" "${REGION:?}" "${BQ_LOCATION:?}" "${BILLING_ACCOUNT:?}"
: "${CORE_PROJECT:?}" "${EVE_PROJECT:?}" "${DOER_PROJECT:?}" "${MO_PROJECT:?}"

CORE_APIS="secretmanager.googleapis.com logging.googleapis.com monitoring.googleapis.com"
EVE_APIS="$CORE_APIS bigquery.googleapis.com run.googleapis.com cloudbuild.googleapis.com \
artifactregistry.googleapis.com cloudscheduler.googleapis.com admin.googleapis.com"
DOER_APIS="$EVE_APIS aiplatform.googleapis.com modelarmor.googleapis.com"

echo "== 1. projects, billing, APIs, labels =="
for P in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do
  gcloud projects describe "$P" >/dev/null 2>&1 || run gcloud projects create "$P" --name="$P"
  run gcloud billing projects link "$P" --billing-account="$BILLING_ACCOUNT"
  run gcloud projects update "$P" \
    --update-labels=agp-build=3-day,agp-owner=platform,agp-data-class=evidence
done
# shellcheck disable=SC2086
run gcloud services enable $CORE_APIS --project="$CORE_PROJECT"
# shellcheck disable=SC2086
run gcloud services enable $EVE_APIS --project="$EVE_PROJECT"
# shellcheck disable=SC2086
run gcloud services enable $DOER_APIS --project="$DOER_PROJECT"
# shellcheck disable=SC2086
run gcloud services enable $EVE_APIS --project="$MO_PROJECT"

echo "== 2. a deletion lien on each project =="
for P in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do
  if ! gcloud resource-manager liens create --project="$P" \
        --restrictions=resourcemanager.projects.delete \
        --reason="three-day build, evidence in flight" --origin="3-day-build" 2>/dev/null; then
    echo "  GA lien command refused; trying alpha"
    run gcloud alpha resource-manager liens create --project="$P" \
      --restrictions=resourcemanager.projects.delete \
      --reason="three-day build, evidence in flight" --origin="3-day-build"
  fi
  run gcloud resource-manager liens list --project="$P" --format='value(name,restrictions)'
done

echo "== 3. a budget on each project =="
for P in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do
  NUM=$(gcloud projects describe "$P" --format='value(projectNumber)')
  run gcloud billing budgets create --billing-account="$BILLING_ACCOUNT" \
    --display-name="3day-$P" --budget-amount=100EUR \
    --filter-projects="projects/${NUM}" \
    --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0
done

echo "== 4. datasets and tables =="
run bq --project_id="$EVE_PROJECT" mk --dataset --location="$BQ_LOCATION" \
  --description="Eve evidence, insert-only" "${EVE_PROJECT}:eve"
run bq --project_id="$DOER_PROJECT" mk --dataset --location="$BQ_LOCATION" \
  --description="Doer audit, insert-only, keyed on agent_id" "${DOER_PROJECT}:steward_audit"
run bq --project_id="$MO_PROJECT" mk --dataset --location="$BQ_LOCATION" \
  --description="Mo metrics" "${MO_PROJECT}:mo"

run bq mk --table --project_id="$EVE_PROJECT" --time_partitioning_field=event_time \
  "${EVE_PROJECT}:eve.ws_activities" \
  insert_id:STRING,event_time:TIMESTAMP,application:STRING,actor_email:STRING,actor_profile_id:STRING,ip_address:STRING,event_type:STRING,event_name:STRING,parameters:STRING,subject:STRING,ingested_at:TIMESTAMP
run bq mk --table --project_id="$EVE_PROJECT" "${EVE_PROJECT}:eve.poll_runs" \
  run_time:TIMESTAMP,rows_landed:INT64,findings:INT64,gaps:STRING
run bq mk --table --project_id="$EVE_PROJECT" "${EVE_PROJECT}:eve.watchlists" \
  kind:STRING,value:STRING

run bq mk --table --project_id="$DOER_PROJECT" --time_partitioning_field=ts \
  --clustering_fields=operation,verdict \
  "${DOER_PROJECT}:steward_audit.actions" \
  row_id:STRING,ts:TIMESTAMP,agent_id:STRING,request_id:STRING,phase:STRING,operation:STRING,target:STRING,level:INT64,requester:STRING,approver:STRING,approval_nonce:STRING,verdict:STRING,denial_reason:STRING,request_hash:STRING,dry_run:BOOL,halt_state:STRING,google_status:STRING,detail:STRING
run bq mk --table --project_id="$DOER_PROJECT" --time_partitioning_field=created_at \
  "${DOER_PROJECT}:steward_audit.approvals" \
  nonce:STRING,request_hash:STRING,approver:STRING,created_at:TIMESTAMP,operation:STRING,target:STRING,level:INT64

echo "== 5. service accounts, keyless =="
run gcloud iam service-accounts create eve-verifier --project="$EVE_PROJECT"
run gcloud iam service-accounts create eve-scheduler --project="$EVE_PROJECT"
run gcloud iam service-accounts create steward-actions --project="$DOER_PROJECT"
run gcloud iam service-accounts create steward-plan --project="$DOER_PROJECT"
run gcloud projects add-iam-policy-binding "$EVE_PROJECT" \
  --member="serviceAccount:eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/bigquery.dataEditor
run gcloud projects add-iam-policy-binding "$EVE_PROJECT" \
  --member="serviceAccount:eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/bigquery.jobUser
run gcloud projects add-iam-policy-binding "$DOER_PROJECT" \
  --member="serviceAccount:steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/bigquery.dataEditor
run gcloud projects add-iam-policy-binding "$DOER_PROJECT" \
  --member="serviceAccount:steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/bigquery.jobUser
run gcloud projects add-iam-policy-binding "$DOER_PROJECT" \
  --member="serviceAccount:steward-plan@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/aiplatform.user

echo "== 6. secrets. Values are never passed on a command line =="
run gcloud secrets create eve-refresh-token --replication-policy=user-managed \
  --locations="$REGION" --project="$EVE_PROJECT"
run gcloud secrets create steward-refresh-token --replication-policy=user-managed \
  --locations="$REGION" --project="$DOER_PROJECT"
run gcloud secrets create steward-halt --replication-policy=user-managed \
  --locations="$REGION" --project="$DOER_PROJECT"
printf 'off' | gcloud secrets versions add steward-halt --data-file=- --project="$DOER_PROJECT"
run gcloud secrets add-iam-policy-binding eve-refresh-token \
  --member="serviceAccount:eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/secretmanager.secretAccessor --project="$EVE_PROJECT"
for S in steward-refresh-token steward-halt; do
  run gcloud secrets add-iam-policy-binding "$S" \
    --member="serviceAccount:steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" \
    --role=roles/secretmanager.secretAccessor --project="$DOER_PROJECT"
done
run gcloud secrets add-iam-policy-binding steward-halt \
  --member="serviceAccount:steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/secretmanager.secretVersionAdder --project="$DOER_PROJECT"

echo "== 7. the Model Armor floor on every project that can call a model =="
for P in "$CORE_PROJECT" "$DOER_PROJECT"; do
  run gcloud beta model-armor floorsettings update \
    --full-uri="projects/${P}/locations/global/floorSetting" \
    --enable-floor-setting-enforcement=TRUE \
    --pi-and-jailbreak-filter-settings-enforcement=enable \
    --pi-and-jailbreak-filter-settings-confidence-level=low-and-above \
    --malicious-uri-filter-settings-enforcement=enable \
    --rai-settings-filters='[{"filterType":"HATE_SPEECH","confidenceLevel":"medium-and-above"},{"filterType":"DANGEROUS","confidenceLevel":"medium-and-above"}]' \
    --project="$P"
  run gcloud beta model-armor floorsettings describe \
    --full-uri="projects/${P}/locations/global/floorSetting" --project="$P"
done

echo "== 8. artifact registry, for the source deploys =="
run gcloud artifacts repositories create cloud-run-source-deploy \
  --repository-format=docker --location="$REGION" --project="$EVE_PROJECT"
run gcloud artifacts repositories create cloud-run-source-deploy \
  --repository-format=docker --location="$REGION" --project="$DOER_PROJECT"

echo "BOOTSTRAP OK"
```

**Verify** after it prints `BOOTSTRAP OK`:

```bash
for P in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do
  echo "== $P"; gcloud resource-manager liens list --project="$P" --format='value(restrictions)'
  gcloud projects describe "$P" --format='value(labels)'
done
bq ls --project_id="$EVE_PROJECT"; bq ls --project_id="$DOER_PROJECT"
gcloud beta model-armor floorsettings describe \
  --full-uri="projects/${DOER_PROJECT}/locations/global/floorSetting" --project="$DOER_PROJECT"
gcloud secrets versions access latest --secret=steward-halt --project="$DOER_PROJECT"
```

Look for: one lien per project; `eve` and `steward_audit` listed; the floor setting with
enforcement `TRUE`; the halt reading `off`. **If `gcloud` rejects any Model Armor flag, stop**: set
the floor in the Cloud console instead, screenshot the settings page and record the console path,
rather than guessing a flag name (flags read on 2026-09-17, and they are beta).

**Undo:** `gcloud resource-manager liens delete <lien>` then
`gcloud projects delete <project>` per project, one at a time, never with `--quiet`.

---

## §8 `requirements.txt`, three of them

```
# build/eve/requirements.txt
google-api-python-client==2.184.0
google-auth==2.41.1
google-cloud-bigquery==3.38.0
google-cloud-secret-manager==2.25.0
```

```
# build/doer/requirements.txt
flask==3.1.2
gunicorn==23.0.0
google-api-python-client==2.184.0
google-auth==2.41.1
google-cloud-bigquery==3.38.0
google-cloud-secret-manager==2.25.0
google-genai==1.46.0
```

```
# build/tools/requirements.txt
google-auth==2.41.1
google-auth-oauthlib==1.2.2
```

`Assumption:` every version above. Pins are the point, the exact numbers are not: re-pin on the day
and record what you pinned.

```bash
python3.12 -m venv /tmp/pin && /tmp/pin/bin/pip install -U pip >/dev/null
for pkg in google-api-python-client google-auth google-auth-oauthlib google-cloud-bigquery \
           google-cloud-secret-manager google-genai flask gunicorn; do
  /tmp/pin/bin/pip index versions "$pkg" 2>/dev/null | head -1
done
```

Take the latest of each, write it into the three files, and run the `--selftest` of §3 again before
deploying anything.

---

## §9 Sources, all read 2026-09-17

| Page | Used for |
|---|---|
| Admin SDK Reports API, `activities.list` reference | the HTTP path, `userKey=all`, the `applicationName` list, `startTime`, `maxResults`, `pageToken`, and the single scope `https://www.googleapis.com/auth/admin.reports.audit.readonly` |
| Admin SDK Directory API, `users.update` reference | `PUT .../admin/directory/v1/users/{userKey}` and the scope `https://www.googleapis.com/auth/admin.directory.user` |
| Admin SDK Directory API, Users resource | the `suspended`, `orgUnitPath`, `isAdmin` and `isDelegatedAdmin` fields |
| Admin SDK Directory API, "Update user accounts" guide | "the Directory API supports patch semantics, so you only need to submit the updated fields in your request" |
| `gcloud run jobs deploy` reference | `--source`, `--region`, `--service-account`, `--set-secrets`, `--set-env-vars`, `--max-retries`, `--task-timeout`; **there is no `--schedule` flag** |
| `gcloud scheduler jobs create http` reference | `--schedule`, `--uri`, `--http-method`, `--oauth-service-account-email`, `--location` |
| Cloud Run, "Execute jobs on a schedule" | the run URL `https://run.googleapis.com/v2/projects/PROJECT-ID/locations/REGION/jobs/JOB-NAME:run` and `roles/run.invoker` for the scheduler identity |
| `gcloud beta model-armor floorsettings update` reference | `--full-uri`, `--enable-floor-setting-enforcement=TRUE`, `--pi-and-jailbreak-filter-settings-enforcement=enable`, `--pi-and-jailbreak-filter-settings-confidence-level` (`high`, `medium-and-above`, `low-and-above`), `--malicious-uri-filter-settings-enforcement`, `--rai-settings-filters` |
| Google Cloud buildpacks, Python | `.python-version` pins the runtime; `requirements.txt` is installed automatically; `Procfile` sets the entrypoint, default `gunicorn -b :8080 main:app` |
| Secret Manager, "Access a secret version" | `SecretManagerServiceClient().access_secret_version(request={"name": name})` and `response.payload.data` |
| BigQuery Python client, `Client.insert_rows_json` | `row_ids` for duplicate suppression; an empty return means every row landed |
| Vertex AI generative AI SDKs overview | `genai.Client(vertexai=True, project=..., location=...)` and `client.models.generate_content` |

## §10 What is not settled, and how each fails loudly

| Unsettled | Where it bites | The check that catches it |
|---|---|---|
| The exact Admin log event names for role changes, security settings and delegation clients | §2's regular expressions | The third verify query prints the distinct `event_name` values this tenant actually emits; the seeded test must land in a rule, and if it does not you widen the expression to a name you can see and record it |
| Whether the tenant's edition shares `token`, `saml` or `access_transparency` | §1's application list | The poller logs `EVE-POLL-GAP application=... status=403` and records it as a coverage gap, not a stop. The `admin` application alone carries all six detections |
| Whether `gcloud resource-manager liens create` is generally available on the team's gcloud version | §7 step 2 | It tries GA, then `alpha`, and `set -e` stops the script if neither works |
| Single use of an approval nonce, inside BigQuery's streaming window | §3's `nonce_used` | A replay within the streaming buffer is possible in principle. The run is attended and the approver is in the room; the nonce is also bound to the request hash and expires in 900 seconds. Record it as a known residual, do not claim it as prevented |
| The Google Auth Platform console path for a Desktop client with an Internal audience | §6 | `consent.py` refuses anything that is not a Desktop client JSON, and refuses a scope set that is not exactly what was asked for |
| Whether `--set-secrets` is wanted at all on the poller | §1 | It is not needed. The service reads its credential with `access_secret_version`; leaving the flag off is one fewer copy of the token |
