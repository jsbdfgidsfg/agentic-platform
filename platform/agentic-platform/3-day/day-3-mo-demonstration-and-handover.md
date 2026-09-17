# Day 3. Mo, the demonstration and the hand-over

## Status

Last reviewed: 2026-09-17. Part of the three-day build ([README](README.md), day 1, day 2, code).
Google's commands, scopes, console paths and quoted wording were checked on 2026-09-17; the table at
the foot of this page lists what was read. Re-read anything marked `Assumption:` on the day.

**Wednesday 2026-09-24.** Day 3 measures what day 2 did, shows it once to a sponsor, writes down
what three days did not buy, and unwinds the standing privilege the same afternoon.

Nothing on day 3 grants anything new. The only mutating action of the day is the demonstration run,
against the same four synthetic accounts, under the same forced dry run and two-person approval. If
day 2 did not end with an executed reversible pair, read "If day 2 did not execute" before T3-1.

Person A builds. Person B approves, witnesses and holds the baseline. Neither verifies their own
work.

---

## Timetable

| Block | Time | Who | What |
|---|---|---|---|
| D3-A1 | 08:30 to 10:00 | A | Five metric views over `steward_audit.actions`, every one keyed on `agent_id`; reconcile the counts by hand against what day 2 did. |
| D3-B1 | 08:30 to 10:00 | B | The retrospective volume baseline from Admin log events. B does this, not A, because the baseline supports A's programme. |
| D3-A2 | 10:15 to 11:45 | A | The scorecard: one query, one page, with the minutes line. |
| D3-B2 | 10:15 to 11:45 | B | The evidence pack index; draft "what is owed". |
| lunch | 11:45 to 13:15 | both | |
| D3-C1 | 13:15 to 14:15 | both | One improvement as a pull request. A authors, B reviews and merges. |
| D3-C2 | 14:30 to 16:00 | both | The demonstration, in front of a sponsor. |
| D3-C3 | 16:15 to 17:15 | both | Seal the pack, sign the hand-over, run the unwind. |
| slack | 90 min each | both | Reserved. Not optimistic. Do not spend it before 14:00. |

---

## What day 3 reads, and where it comes from

| Value | What it holds | Set by |
|---|---|---|
| `CORE_PROJECT`, `EVE_PROJECT`, `DOER_PROJECT`, `MO_PROJECT` | the four project ids | day 1, T1-1 |
| `REGION`, `BQ_LOCATION`, `AGENT_ID`, `PILOT_OU`, `DOMAIN` | `europe-west1`, `EU`, `steward`, the pilot organisational unit, the tenant domain | day 1, T1-1 |
| `PERSON_A`, `PERSON_B`, `SPONSOR_EMAIL` | the two addresses, and the sponsor booked for 14:30 | day 1, T1-1 |
| `DOER_ROBOT`, `PILOT_ROLE_ID` | the doer's address, and the custom role's numeric id | day 2 |
| `STEWARD_ACTIONS_URL` | the action service, the only credential holder | day 2 |
| `RUN_LOG` | the one run log both people write to | day 1, T1-1 |

`DOER_PROJECT:steward_audit.actions` is the write-ahead audit table day 2 created, and it is what
every view below reads. Load the variables once per shell:

```bash
W="$HOME/agp-3day"; [ -d "$W" ] || W="$HOME/3day"      # whichever day 1 created
set -a; . "$W/names.env"; set +a
: "${CORE_PROJECT:?}" "${EVE_PROJECT:?}" "${DOER_PROJECT:?}" "${MO_PROJECT:?}" \
  "${PILOT_OU:?}" "${AGENT_ID:?}" "${DOMAIN:?}" "${CUSTOMER_ID:?}" \
  "${PERSON_A:?}" "${PERSON_B:?}" "${DOER_ROBOT:?}" "${PILOT_ROLE_ID:?}" "${RUN_LOG:?}" \
  && echo "names.env complete"
```

If any name is unset, **read `names.env` and use the name that is actually in it**; day 3 creates no
variable of its own. No step below uses a default gcloud project: every command passes `--project`
or `--project_id`.

---

## Preconditions, checked at 08:30 before anything else

- [ ] `steward_audit.actions` holds day 2's rows: a forced dry run, a denial, and (unless the
      fallback below applies) an approved execution and its inverse.
- [ ] The halt secret `steward-halt` reads `off`. If it reads `on`, clear it with both present and
      note the minute in `RUN_LOG`.
- [ ] The robot's credential was re-consented at the end of day 2. Without it there is no execution.
- [ ] `eve.findings` returns no `log_pipeline_silent` row, so the poller has run recently.
- [ ] A sponsor is booked for 14:30 and knows the run lasts 60 minutes with 30 in reserve.

---

## D3-A1. The metric pack, 08:30 to 10:00, person A

### T3-1. Fix the read contract before writing a single view

- **WHO:** A. **WHERE:** shell.
- **WHY:** the views are written on day 3 against a table created on day 2. If a column was named
  differently the views must fail now, loudly, not silently return zero rows in front of a sponsor.

```bash
bq show --project_id="$DOER_PROJECT" --schema --format=prettyjson steward_audit.actions \
  | python3 -c '
import json,sys
want={"ts","agent_id","request_id","request_hash","phase","operation","target","target_ou",
      "level","dry_run","verdict","denial_reason","requester","approver","approval_id",
      "approval_issued_at","pair_id","inverse_of","halt_state","google_status","notes"}
have={f["name"] for f in json.load(sys.stdin)}
missing=sorted(want-have)
print("extra:",sorted(have-want))
if missing:
    raise SystemExit("STOP: audit table is missing "+", ".join(missing))
print("read contract satisfied")
'
```

  Those twenty-one columns are the ones day 2 created. If the check stops, **do not rename anything
  in BigQuery**: renaming a column the running action service writes to breaks the write-ahead
  audit, which is absolute 8. Read the column list `code.md` §3 actually writes and change the view
  SQL below to match.

- **Then fix the vocabulary**, because a view that buckets on an unknown verdict hides rows:

```bash
bq query --use_legacy_sql=false --project_id="$DOER_PROJECT" --format=csv '
SELECT phase, verdict, IFNULL(denial_reason,"(none)") AS denial_reason, COUNT(*) AS n
FROM `'"$DOER_PROJECT"'.steward_audit.actions` GROUP BY 1,2,3 ORDER BY 4 DESC'
```

- **VERIFY:** every `phase` is `ahead` or `outcome`. Every `verdict` is `ok`, `shadow` or `denied`.
  Every `denial_reason` is one of `p:level_no_execute`, `p:self_approval`, `p:protected_principal`,
  `p:out_of_scope_ou`, `p:audit_unavailable`, `p:halted`, `(none)`. **Any value outside those three
  lists is a finding**: write it in `RUN_LOG`, name it in the scorecard's denial table, and do not
  quietly fold it into "other".
- **The counting rule that follows from `phase`:** every request writes an `ahead` row before the
  call and an `outcome` row after it. **Count requests on `phase = 'ahead'` and results on
  `phase = 'outcome'`**, never both, or every number doubles.
- **UNDO:** nothing was written.

### T3-2. Create the five views

- **WHO:** A. **WHERE:** shell, in `$W/mo/`.
- **ACTION:** save the five statements as `mo.sql` and run them as one file. Every view is grouped
  on `agent_id`, because the whole point of the schema is that a second agent added later is counted
  separately without a new view.

```sql
-- $W/mo/mo.sql   run against MO_PROJECT, reading DOER_PROJECT
-- Every view is grouped on agent_id and reads one phase only.
CREATE OR REPLACE VIEW `MO_PROJECT.mo.mo_volume_by_verdict` AS
SELECT agent_id, level, operation, verdict, COUNT(*) AS n,
       MIN(ts) AS first_ts, MAX(ts) AS last_ts
FROM `DOER_PROJECT.steward_audit.actions`
WHERE phase = 'outcome'
GROUP BY agent_id, level, operation, verdict;

CREATE OR REPLACE VIEW `MO_PROJECT.mo.mo_denial_reasons` AS
SELECT agent_id, denial_reason, COUNT(*) AS n
FROM `DOER_PROJECT.steward_audit.actions`
WHERE phase = 'outcome' AND verdict = 'denied'
GROUP BY agent_id, denial_reason;

CREATE OR REPLACE VIEW `MO_PROJECT.mo.mo_dry_run_ratio` AS
SELECT agent_id,
       COUNTIF(verdict = 'shadow') AS dry_runs,
       COUNTIF(verdict = 'ok' AND NOT dry_run) AS executions,
       COUNT(*) AS requests,
       SAFE_DIVIDE(COUNTIF(verdict = 'shadow'), COUNT(*)) AS dry_run_share
FROM `DOER_PROJECT.steward_audit.actions`
WHERE phase = 'outcome'
GROUP BY agent_id;

-- Latency runs from the shadow row that carries the same request_hash to the
-- approval issued for it. It is a difference between two timestamps, never a
-- measure of effort.
CREATE OR REPLACE VIEW `MO_PROJECT.mo.mo_approval_latency` AS
SELECT e.agent_id, e.request_hash, s.ts AS requested_ts, e.approval_issued_at,
       TIMESTAMP_DIFF(e.approval_issued_at, s.ts, SECOND) AS latency_seconds
FROM `DOER_PROJECT.steward_audit.actions` AS e
JOIN `DOER_PROJECT.steward_audit.actions` AS s
  ON s.request_hash = e.request_hash AND s.verdict = 'shadow' AND s.phase = 'outcome'
WHERE e.phase = 'outcome' AND e.verdict = 'ok' AND e.approval_issued_at IS NOT NULL;

-- A pair completes when a target that was suspended is restored. Any target with
-- suspends > restores is still suspended: that is a finding, not a metric.
CREATE OR REPLACE VIEW `MO_PROJECT.mo.mo_pair_completion` AS
SELECT agent_id, target,
       COUNTIF(operation = 'suspend_user' AND verdict = 'ok' AND NOT dry_run) AS suspends,
       COUNTIF(operation = 'restore_user' AND verdict = 'ok' AND NOT dry_run) AS restores,
       COUNTIF(operation = 'suspend_user' AND verdict = 'ok' AND NOT dry_run)
       - COUNTIF(operation = 'restore_user' AND verdict = 'ok' AND NOT dry_run) AS left_suspended
FROM `DOER_PROJECT.steward_audit.actions`
WHERE phase = 'outcome'
GROUP BY agent_id, target;
```

```bash
sed -e "s/MO_PROJECT/$MO_PROJECT/g" -e "s/DOER_PROJECT/$DOER_PROJECT/g" "$W/mo/mo.sql" \
  | bq query --use_legacy_sql=false --project_id="$MO_PROJECT"
bq ls --project_id="$MO_PROJECT" mo
```

- **VERIFY:** `bq ls` shows five entries of type `VIEW`. Each returns rows:
  `for v in mo_volume_by_verdict mo_denial_reasons mo_dry_run_ratio mo_approval_latency mo_pair_completion; do bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --format=csv "SELECT COUNT(*) FROM \`$MO_PROJECT.mo.$v\`"; done`
- **UNDO:** `for v in ...; do bq rm -f -t "$MO_PROJECT:mo.$v"; done`. Views hold no data; dropping
  one loses nothing.
- **Cited:** creating and removing views with `bq mk --view` / `bq rm -t`, and the note that
  `--use_legacy_sql=false` selects GoogleSQL (BigQuery "Manage views", read 2026-09-17).

### T3-3. Reconcile by hand against what day 2 actually did

- **WHO:** A queries; **B reads the day 2 pages of `RUN_LOG` aloud and confirms each number.**
- **WHERE:** one screen, both present. Ten minutes, no more.
- **ACTION:** print the five views and tick them off against day 2's witnessed negatives.

```bash
for v in mo_volume_by_verdict mo_denial_reasons mo_dry_run_ratio mo_approval_latency mo_pair_completion; do
  echo "== $v"; bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --format=prettyjson \
    "SELECT * FROM \`$MO_PROJECT.mo.$v\`"
done | tee "$W/records/2026-09-24-T3-3-reconciliation.json"
```

- **VERIFY:** the denial reasons view carries one row for each negative day 2 witnessed and no
  others; `mo_dry_run_ratio.executions` equals the number of executions `RUN_LOG` records;
  `mo_pair_completion.left_suspended` is `0` for every target unless day 2 deliberately left one
  suspended. **A mismatch stops the day**: either the audit is incomplete, which is a defect against
  absolute 8, or `RUN_LOG` is wrong. Find out which before 10:00 and write the answer down.
- **UNDO:** nothing was written.

---

## D3-B1. The retrospective volume baseline, 08:30 to 10:00, person B

Three days cannot buy a four-week prospective toil baseline, so nothing on day 3 may claim a minute
saved. What can be bought is **volume, counted backwards**, because Google keeps Admin log events
for a stated window and administrators cannot shorten it.

### T3-4. Re-read the retention page today and fix the window

- **WHO:** B. **WHERE:** browser, then `RUN_LOG`.
- **ACTION:** open Google's Workspace admin reports retention and lag page and copy three things
  into `RUN_LOG` with today's date: the Admin log events retention, its lag, and the sentence about
  administrators. On 2026-09-17 that page read: retention **"6 months"**, lag **"Near real time
  (couple of minutes)"**, and **"Administrators cannot delete log event data or change the length of
  time that the data is available for."**
- **Then set the window from what the page says today, not from the sentence above:**

```bash
# macOS
WINDOW_START="$(date -u -v-6m +%F)"
# GNU/Linux
# WINDOW_START="$(date -u -d '6 months ago' +%F)"
echo "$WINDOW_START"            # 2026-03-24 when the page still says 6 months
printf 'TOIL_WINDOW_START=%s\n' "$WINDOW_START" >> "$W/names.env"
```

- **VERIFY:** the quoted retention in `RUN_LOG` and `TOIL_WINDOW_START` agree. If Google's page
  states a different window today, the window changes and the quote in the scorecard changes with
  it. Do not carry 2026-03-24 forward on trust.
- **UNDO:** edit the line out of `names.env`; nothing else changed.
- **Cited:** Workspace admin, data retention and lag times, read 2026-09-17.

### T3-5. Export Admin log events, and print the header row first

- **WHO:** B. **WHERE:** Admin console, then shell.
- **CONSOLE PATH:** Menu > Reporting > Audit and investigation > Admin log events.
- **ACTION:** three exports, one per event, each with the same date filter.
  1. Add condition **Date** > **After** > `TOIL_WINDOW_START`.
  2. Add condition **Event** > `SUSPEND_USER`. Search. Click **Export all**, give the name
     `3day-suspend`, choose **CSV**.
  3. Repeat for `UNSUSPEND_USER` (the doer's inverse) and for `CREATE_USER`, which the doer
     **cannot** perform and which is there only to show what share of admin volume the one
     catalogued pair represents.
  4. Collect the three files from **Export action results** and download them to `$W/toil-raw/`.
- **VERIFY:** each search returns a row count, and the export finishes. If any export reports more
  than 100,000 rows it was truncated: Google states "The total results of the export are limited to
  100,000 rows" on standard editions. Narrow the window by month and export in slices, and record
  in `RUN_LOG` that the count is a sum of slices.
- **Then, before parsing anything:**

```bash
for f in "$W"/toil-raw/*.csv; do echo "== $f"; head -1 "$f"; done
```

  Google does not document the CSV header names, so the header is read, not assumed. Write the exact
  header line into `RUN_LOG`. The reducer in T3-6 names its columns from what is printed here.
- **UNDO:** the exports are read-only against the log. Deleting the downloads is T3-7.
- **Cited:** Admin log events, its filters and its export limit; event names `SUSPEND_USER`,
  `UNSUSPEND_USER`, `CREATE_USER` under `applicationName=admin`. Both read 2026-09-17.

### T3-6. Reduce to counts, keep no actor

- **WHO:** B. **WHERE:** shell.
- **WHY:** the raw export names the administrators who did the work. The baseline needs volume, not
  people. Nothing on day 3 has a data-protection impact assessment behind it, so the actor column
  does not survive the hour.

```bash
# DATE_COL and EVENT_COL come from the header line T3-5 printed. Do not guess them.
export W DATE_COL="Date" EVENT_COL="Event Name"
python3 - <<'PY'
import csv, glob, collections, os, sys
W = os.environ["W"]; DATE_COL = os.environ["DATE_COL"]; EVENT_COL = os.environ["EVENT_COL"]
counts = collections.Counter()
paths = sorted(glob.glob(os.path.join(W, "toil-raw", "*.csv")))
if not paths:
    sys.exit("STOP: no export found in " + os.path.join(W, "toil-raw"))
for path in paths:
    with open(path, newline="", encoding="utf-8-sig") as fh:
        r = csv.DictReader(fh)
        if DATE_COL not in r.fieldnames or EVENT_COL not in r.fieldnames:
            sys.exit(f"STOP: {path} headers are {r.fieldnames}; set DATE_COL and EVENT_COL")
        for row in r:
            counts[(row[DATE_COL][:10], row[EVENT_COL])] += 1
out = os.path.join(W, "records", "2026-09-24-T3-6-toil-counts.csv")
with open(out, "w", newline="") as fh:
    w = csv.writer(fh); w.writerow(["event_date", "event_name", "n"])
    for (d, e), n in sorted(counts.items()):
        w.writerow([d, e, n])
print("wrote", out, "rows:", len(counts))
PY
grep -ciE '@|actor|admin@' "$W/records/2026-09-24-T3-6-toil-counts.csv"   # expect 0
```

- **Then load it, so the scorecard reads a table and not a file:**

```bash
bq mk --project_id="$MO_PROJECT" --table mo.toil_retrospective \
  event_date:DATE,event_name:STRING,n:INT64
bq load --project_id="$MO_PROJECT" --source_format=CSV --skip_leading_rows=1 \
  mo.toil_retrospective "$W/records/2026-09-24-T3-6-toil-counts.csv"
```

- **VERIFY:** the `grep` prints `0`, so no address survived. `bq query` on
  `SELECT event_name, SUM(n) FROM mo.toil_retrospective GROUP BY 1` returns three rows, and the
  `SUSPEND_USER` total matches the row count the console reported in T3-5.
- **UNDO:** `bq rm -f -t "$MO_PROJECT:mo.toil_retrospective"` and delete the counts file.

### T3-7. Destroy the raw export, within the hour. **IRREVERSIBLE**

- **WHO:** B runs it; A watches the screen and signs the line in `RUN_LOG`.
- **CONFIRM FIRST:** `mo.toil_retrospective` holds rows (T3-6 verified), and the counts file is in
  `$W/records/`. Once the raw files are gone the per-actor detail cannot be recovered from the
  download; it can be re-exported from Google's log while the retention window still covers it, but
  only by repeating T3-5.

```bash
ls -l "$W/toil-raw/"
# macOS
rm -P "$W"/toil-raw/*.csv && rmdir "$W/toil-raw"
# GNU/Linux: shred -u "$W"/toil-raw/*.csv && rmdir "$W/toil-raw"
```

- **Then clear the console copy**: Reporting > Audit and investigation > Admin log events >
  **Export action results**, and remove the three named exports. `Assumption:` the export results
  list offers a delete control per row; if it does not, record in `RUN_LOG` that the console retains
  the export and name it in the hand-over as an open item.
- **VERIFY:** `ls "$W/toil-raw"` fails with "No such file or directory"; the export results list
  no longer shows `3day-suspend`, `3day-unsuspend`, `3day-create`.
- **UNDO:** none. That is the point.

---

## D3-A2. The scorecard, 10:15 to 11:45, person A

### T3-8. One query

- **WHO:** A. **WHERE:** shell.

```sql
-- $W/mo/scorecard.sql
SELECT * FROM (
  SELECT 'volume' AS line, agent_id, level, operation, verdict AS detail, CAST(n AS STRING) AS value
  FROM `MO_PROJECT.mo.mo_volume_by_verdict`
  UNION ALL SELECT 'denial', agent_id, NULL, NULL, denial_reason, CAST(n AS STRING)
  FROM `MO_PROJECT.mo.mo_denial_reasons`
  UNION ALL SELECT 'dry_run_share', agent_id, NULL, NULL, NULL, FORMAT('%.2f', dry_run_share)
  FROM `MO_PROJECT.mo.mo_dry_run_ratio`
  UNION ALL SELECT 'approval_latency_seconds', agent_id, NULL, NULL, request_hash,
                   CAST(latency_seconds AS STRING)
  FROM `MO_PROJECT.mo.mo_approval_latency`
  UNION ALL SELECT 'left_suspended', agent_id, NULL, NULL, target, CAST(left_suspended AS STRING)
  FROM `MO_PROJECT.mo.mo_pair_completion` WHERE left_suspended <> 0
  UNION ALL SELECT 'retro_volume', NULL, NULL, NULL, event_name, CAST(SUM(n) AS STRING)
  FROM `MO_PROJECT.mo.toil_retrospective` GROUP BY event_name
)
ORDER BY line, detail, value;
```

```bash
sed "s/MO_PROJECT/$MO_PROJECT/g" "$W/mo/scorecard.sql" \
  | bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --format=prettyjson \
  | tee "$W/records/2026-09-24-T3-8-scorecard.json"
```

- **VERIFY:** the output carries a `volume` line, at least one `denial` line, a `dry_run_share`, at
  least one `approval_latency_seconds`, and three `retro_volume` lines. No `left_suspended` line at
  all is the good outcome.
- **UNDO:** nothing was written to any table.

### T3-9. One page, with the minutes line

- **WHO:** A writes. **B initials the minutes line before the page is printed.**
- **WHERE:** `$W/records/2026-09-24-T3-9-scorecard.md`. Seven short sections, every figure
  copied from T3-8's JSON, nothing typed from memory.

| Section | Content | Source |
|---|---|---|
| 1. What the doer did | counts by operation, level and verdict, dry runs shown separately | `mo_volume_by_verdict` |
| 2. Why it refused | one row per denial reason, with the day 2 negative it came from | `mo_denial_reasons` |
| 3. How much never ran | dry runs over total requests | `mo_dry_run_ratio` |
| 4. How long approval took | each latency in seconds, plus the maximum | `mo_approval_latency` |
| 5. Was anything left broken | targets still suspended, expected `none` | `mo_pair_completion` |
| 6. Retrospective volume | counts per event over the window, with today's quoted retention and the window start | `mo.toil_retrospective`, T3-4 |
| 7. What this does not show | the paragraph below, unedited | this file |

**Section 6 is volume, and never time.** It says how many times an administrator performed each
event in the window. It does not say how long any of them took, and no median, rate or cost may be
attached to it anywhere on the page.

**Section 7 is written out in full, verbatim, and is not softened:**

> **No human minute was saved.** Every target was a synthetic account in the pilot organisational
> unit; no administrator was relieved of any task; no real employee's account was touched. The
> retrospective figure in section 6 is a count of events, not a measure of effort, and the four-week
> prospective baseline that would let a saving be claimed was not taken. Approval latency in section
> 4 is a difference between two timestamps, not a measure of work. This page measures machinery
> under control. It is not compliance evidence and it is not a production grant.

- **VERIFY:**

```bash
f="$W/records/2026-09-24-T3-9-scorecard.md"
grep -c 'No human minute was saved.' "$f"                 # exactly 1
grep -ciE 'minutes saved|time saved|saved [0-9]|hours saved' "$f"  # exactly 1, the line above
grep -ciE 'productivity gain|efficiency gain|ROI' "$f"    # 0
```

- **UNDO:** a `-v2` file supersedes it. Never edit a signed page in place.

---

## D3-B2. The evidence pack and what is owed, 10:15 to 11:45, person B

### T3-10. Index the pack and hash every record

- **WHO:** B. **WHERE:** shell.

```bash
D="$W/pack/2026-09-24"; mkdir -p "$D"
{ printf 'step\tfile\tsha256\n'
  find "$W/records" -type f | sort | while read -r f; do
    s="$(basename "$f" | sed -E 's/^[0-9-]{10}-(T[123]-[0-9]+).*/\1/')"
    printf '%s\t%s\t%s\n' "$s" "$f" "$(shasum -a 256 "$f" | cut -d' ' -f1)"
  done
} | tee "$D/index.tsv"
awk -F'\t' 'NR>1{print $1}' "$D/index.tsv" | sort -u > "$D/steps-present.txt"
printf 'T3-%d\n' $(seq 1 19) | sort > "$D/steps-expected.txt"
comm -13 "$D/steps-present.txt" "$D/steps-expected.txt" | tee "$D/steps-missing.txt"
```

- **VERIFY:** `steps-missing.txt` is empty, or every id in it is one day 3 deliberately did not
  reach, and each of those is named in the hand-over. A missing id with no explanation is a gap in
  the pack, not a tidy-up.
- **Grep the pack before it is sealed:**
  `grep -rIiE 'refresh_token|BEGIN PRIVATE|password|client_secret' "$W/records" | tee "$D/secret-scan.txt"`
  must print nothing. If it prints anything, that record is rewritten without the value and the
  original is destroyed under T3-7's rule, and the secret is rotated before 17:15.
- **UNDO:** `rm -r "$D"`. The pack is derived; the records are the source.

### T3-11. Draft what is owed

- **WHO:** B drafts. A reads it once and may only add, never remove.
- **WHERE:** `$W/records/2026-09-24-T3-11-what-is-owed.md`.
- **ACTION:** eleven rows, each naming the file and step in `../pov/` or `../setup/` that closes it.

| # | What three days did not buy | Closed by |
|---|---|---|
| 1 | No super admin for any agent, and no evidence about super-admin containment | `../pov/07-the-doer-tier-w-and-the-optional-tier-p.md` §7; `../setup/38-super-admin-gate-and-grant.md` |
| 2 | No witness organisation; Eve lives inside the reach of the administrators it watches | `../setup/08-witness-organisation.md`; `../setup/27-witness-grants-and-alarms.md` |
| 3 | No SIEM contract, no managed detection, no 24x7 acknowledgement | `../setup/15-pager-siem-and-detections.md` |
| 4 | No penetration test, no Security Command Center Premium | `../setup/09-folders-and-security-command-center.md` |
| 5 | No Terraform factory, no register CI, no Binary Authorization | `../setup/17-factory-module-equivalents-and-tier-r-gate.md` FM-2.1 onwards |
| 6 | No privileged-access-management entitlements; time-boxed IAM grants stood in and were removed the same day | `../pov/03-foundation-folders-logging-and-floors.md` PF-5.1; `../setup/12-privileged-access-catalogue.md` |
| 7 | No autonomy beyond a forced dry run and a two-person approved execution; no unattended running at any moment | `../pov/07-...md` PW-6.2 |
| 8 | No four-week prospective toil baseline, so no defensible claim of minutes saved | `../setup/02-toil-baseline.md` TB-1.2 |
| 9 | No data-protection impact assessment, no works-council information, which is why nothing mutating touched a real account | `../pov/02-decisions-people-and-the-retrospective-baseline.md` PD-8.0; `../setup/03-decisions-and-people.md` |
| 10 | No blind grading and no second reviewer on the improvement; two people give one reviewer | `../pov/08-mo-and-the-value-report.md` PM-7.1 to PM-7.3, PM-9.2 |
| 11 | Six detections and one freshness rule, not the full set; two kill switches, not seven | `../setup/25-eve-human-super-admin-detections.md` EH-2.3; `../pov/07-...md` PW-6.4 |

- **VERIFY:** every row names a file that exists: `awk -F'|' 'NR>2{print $4}' <file> | grep -oE '\.\./[a-z]+/[0-9a-z-]+\.md' | sort -u | while read -r p; do [ -f "$p" ] || echo "MISSING $p"; done` prints nothing.
- **UNDO:** a `-v2`.

---

## D3-C1. One improvement, 13:15 to 14:15, both

### T3-12. Author the change, from the data and not from taste

- **WHO:** A authors. **WHERE:** `$W/doer/`, the repository day 2 built the action service from.
- **THE CHANGE:** the approval expiry drops from 15 minutes to 5, in two places that must agree: the
  `APPROVAL_TTL_SECONDS` default in `actions.py`, and the `--set-env-vars` value day 2 deployed with.
  The observed approval latencies in `mo_approval_latency` justify it, or they do not. Read them
  first:

```bash
bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --format=csv \
  "SELECT MAX(latency_seconds) AS worst FROM \`$MO_PROJECT.mo.mo_approval_latency\`"
```

- **THE RULE:** if `worst` is 300 seconds or more, **the change is refused** and the record says so.
  A tighter expiry that the real approver cannot meet is a change that breaks the run to look good.
  Refusing it is the correct day-3 outcome and is written up as one.

```bash
cd "$W/doer" && git switch -c improve-approval-ttl
# edit APPROVAL_TTL_SECONDS from 900 to 300 in actions.py
python3.12 actions.py --selftest       # day 2's eight negatives must still pass
git add -A && git commit -m "Tighten approval expiry to 300s; observed worst latency <N>s"
git push -u origin improve-approval-ttl && gh pr create --fill   # only if a remote exists
```

- **VERIFY:** `--selftest` exits `0`. The commit message carries the observed worst latency, so the
  evidence for the change is in the history and not in anyone's recollection.
- **UNDO:** `git switch main && git branch -D improve-approval-ttl`, and the service is untouched
  because nothing is deployed from a branch.

### T3-13. Review and merge

- **WHO:** **B reviews and merges. A does not merge their own change**, and no machine merges
  anything.
- **WHERE:** the pull request if a remote exists, otherwise B's own checkout.

```bash
# no remote: B reviews the diff on their own machine and merges with a merge commit
git fetch . improve-approval-ttl && git switch main
git merge --no-ff improve-approval-ttl -m "Reviewed and merged by person B on 2026-09-24"
```

- **Redeploy only if there is time inside the block**, and then with the env var changed to match:
  `gcloud run services update steward-actions --region="$REGION" --project="$DOER_PROJECT" --update-env-vars=APPROVAL_TTL_SECONDS=300`.
  If there is no time, the merge stands and the deployment is listed in the hand-over as owed. The
  demonstration runs on whichever revision is live, and the record says which.
- **VERIFY:** `git log --merges -1 --format='%an %s'` names B as the committer of the merge; the
  branch's commit is not on `main` by fast-forward.
- **RECORD:** `2026-09-24-T3-13-improvement.md` states plainly: the full build wants two reviewers
  and two people give one, so this merge has a reviewer who is not the author and nothing more.
- **UNDO:** `git revert -m 1 <merge sha>`.

---

## D3-C2. The demonstration, 14:30 to 16:00, both, in front of a sponsor

### T3-14. What the sponsor is told first, before anything is shown

- **WHO:** B says it. **WHERE:** the room. Three sentences, spoken before the first command.
  1. Every account this touches is synthetic. No employee's account is in reach.
  2. The doer holds one custom admin privilege, scoped to one organisational unit, and it is removed
     this afternoon.
  3. This is a demonstration of machinery under control. It is not compliance evidence and it is not
     a production grant.
- **Two sentences are banned in the room and on every page:** "Eve is independent" and "Model Armor
  blocked the injection". Eve lives inside the tenant it watches, and Model Armor is a probabilistic
  screen that produces evidence, never a boundary.
- **VERIFY:** B ticks the three sentences in `RUN_LOG` before T3-15 starts.

### T3-15. The run, in this order and no other

- **WHO:** A drives. B approves. The sponsor watches. **WHERE:** one screen.

| # | What happens | What the room should see |
|---|---|---|
| 1 | A runs `steward-plan` with a sentence such as "suspend the pilot account that is leaving" | a JSON plan. **The plan tool holds no credential and has no invoker on the action service**; A copies the plan by hand into the request |
| 2 | A sends the request at L1 | `verdict: shadow`, `dry_run: true`, a would-be verdict, no change in the Admin console |
| 3 | A sends the same request at L1 **with a valid approval attached** | `denied`, `denial_reason: p:level_no_execute`. A valid approval does not buy an execution at L1 |
| 4 | A requests an execution and approves it themselves | `denied`, `denial_reason: p:self_approval` |
| 5 | B approves; A executes | `verdict: ok`; the `phase: ahead` row is written **before** the Directory call; the synthetic account shows Suspended in the Admin console |
| 6 | Refresh `eve.findings` after one scheduler tick | Eve carries the admin event. Eve was live before the doer existed |
| 7 | Re-run T3-8's scorecard query | Mo counts the execution, keyed on `agent_id` |
| 8 | A runs the inverse | the account is Active again; `mo_pair_completion.left_suspended` returns to `0` |
| 9 | **B pulls K0**: writes `on` to `steward-halt` | the next request is `denied` with `p:halted`. The halt is read per request and never mounted, so a warm instance sees it |
| 10 | B clears the halt back to `off`, with A present | the record notes the minute of both |

- **VERIFY:** after step 5, the `phase: ahead` row's `ts` is strictly earlier than its matching
  `phase: outcome` row and earlier than the Admin console's event time for that suspension. After
  step 9, record the seconds from B's decision to the refusal. Both numbers go in the record.
- **Say out loud at step 9:** an access token already issued may stay valid for up to an hour, so
  revoking the credential is not what stops work now. The halt is.
- **UNDO:** step 8 is the undo for step 5. If step 8 fails, suspend is reversed by hand in the Admin
  console (Directory > Users > the account > **Restore** / un-suspend) and the failure is recorded,
  not hidden.

### T3-16. Record it while the room is still there

- **WHO:** A writes; **B and the sponsor both sign.**
- **WHERE:** `$W/records/2026-09-24-T3-16-demonstration.md`.
- **ACTION:** ten lines, one per row of T3-15, each with the minute and the verdict; then the three
  sentences of T3-14; then one line naming anything that did not work. A demonstration with a
  recorded failure is worth more than one with none.
- **VERIFY:** three signatures. The sponsor's is the only third party these three days have.

---

## D3-C3. Seal, hand over, unwind, 16:15 to 17:15, both

### T3-17. Seal the pack

- **WHO:** B. **WHERE:** shell.

```bash
D="$W/pack/2026-09-24"
shasum -a 256 "$D/index.tsv" | tee "$D/index.sha256"
tar -czf "$W/pack/3day-evidence-2026-09-24.tar.gz" -C "$W/pack" 2026-09-24 records
shasum -a 256 "$W/pack/3day-evidence-2026-09-24.tar.gz" | tee "$W/pack/pack.sha256"
```

- **VERIFY:** re-running T3-10's `find` produces the same `index.tsv` hash. Both people write the
  pack hash into `RUN_LOG` by hand. There is no locked bucket in three days: the pack's integrity
  rests on two hashes written down by two people, and the hand-over says so.
- **UNDO:** delete the archive and re-run. The records are the source.

### T3-18. Sign the hand-over note

- **WHO:** both sign. **WHERE:** `$W/records/2026-09-24-T3-18-handover.md`.
- **ACTION:** six short parts.
  1. What exists at 17:15: four projects, three datasets, Eve polling on a schedule with two
     alerting policies, the action service, the plan tool, five Mo views, the scorecard.
  2. What was proved: Eve live before the doer existed; a forced dry run that refuses a valid
     approval; self-approval refused; a two-person approved execution with a write-ahead audit row;
     a reversible pair completed; two kill switches pulled and timed.
  3. What was **not** proved: T3-11's eleven rows, unedited.
  4. What is left standing after the unwind: the four projects, the datasets, the deployed services
     with no valid credential, the four synthetic accounts suspended in the pilot organisational
     unit, and Eve still polling.
  5. **What must be unwound before anything real is touched**, if this is ever picked up again: the
     standing IAM grants, the custom admin role, the synthetic accounts. T3-19 does the first three
     today; the sentence stays in the note because the next team will build new ones.
  6. Where it grows: `../pov/` next, then `../setup/`. Every name and schema used in these three
     days is the full build's own, so nothing is renamed on the way up, and no record from these
     three days satisfies a full-build gate it does not meet.
- **VERIFY:** part 3 has eleven rows and matches T3-11 line for line.

### T3-19. The unwind, today, with both people present

Run these in order. Each has its own read-back. Do not batch them.

**a. Remove the time-boxed IAM grants**

```bash
for P in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do
  gcloud projects get-iam-policy "$P" --project="$P" --format=json \
    | python3 -c 'import json,sys; [print(b["role"], m, b.get("condition",{}).get("title","-")) for b in json.load(sys.stdin)["bindings"] for m in b["members"] if m.startswith("user:")]'
done
# then, for each line printed, one removal naming the exact condition:
gcloud projects remove-iam-policy-binding "$P" --project="$P" \
  --member="user:$PERSON_A" --role="roles/ROLE" \
  --condition='expression=request.time < timestamp("2026-09-25T00:00:00Z"),title=three-day-run'
```

  `--condition` must match the binding exactly or nothing is removed; `--condition=None` removes
  only an unconditional binding, and `--all` removes every binding for that member and role
  regardless of condition (gcloud `projects remove-iam-policy-binding`, read 2026-09-17).
  **Read back:** the loop above prints no `user:` line on any of the four projects.

**b. Unassign the custom admin role, then delete it**

- **CONSOLE PATH:** Menu > Account > Admin roles > **Pilot Steward** > Admins > remove the robot.
- **Read back**, from B's own session, not A's:
  `GET https://admin.googleapis.com/admin/directory/v1/customer/${CUSTOMER_ID}/roleassignments?roleId=$PILOT_ROLE_ID`
  returns no item. The scope needed to read it is
  `https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly`
  (Directory API, `roleAssignments.list`, read 2026-09-17).
- **Then delete the role. IRREVERSIBLE.** Confirm first that the read-back is empty and that the
  privilege list is written into the hand-over, because a deleted custom role cannot be restored and
  must be rebuilt by hand:
  `DELETE https://admin.googleapis.com/admin/directory/v1/customer/${CUSTOMER_ID}/roles/$PILOT_ROLE_ID`
  (Directory API, `roles.delete`, read 2026-09-17), or Admin roles > Pilot Steward > Delete role.

**c. Revoke the robot's OAuth grant**

- **API:** `DELETE https://admin.googleapis.com/admin/directory/v1/users/$DOER_ROBOT/tokens/$CLIENT_ID`,
  scope `https://www.googleapis.com/auth/admin.directory.user.security`
  (Directory API, `tokens.delete`, read 2026-09-17).
- **Read back:** `GET .../users/$DOER_ROBOT/tokens` no longer lists that `clientId`.
- **Say it in the record:** an access token already issued may stay valid for up to an hour after
  the grant is revoked. The halt flag, left at `on` in step f, is what stops work immediately.

**d. Disable the secret versions**

```bash
for S in steward-refresh-token eve-refresh-token; do
  V="$(gcloud secrets versions list "$S" --project="$DOER_PROJECT" --filter='state:ENABLED' --format='value(name)' | head -1)"
  [ -n "$V" ] && gcloud secrets versions disable "$V" --secret="$S" --project="$DOER_PROJECT"
done
```

  `gcloud secrets versions disable` is GA, takes `--secret` and `--location` for a regional secret
  (read 2026-09-17). **Disable, not destroy:** disabling is reversible with `versions enable`.
  **Leave `eve-refresh-token` enabled if Eve is meant to keep polling after today**; decide in the
  room and write the decision down either way.

**e. Leave the synthetic accounts suspended, in the pilot organisational unit**

- Suspend all four. Do not delete them and do not move them: a suspended synthetic account in an
  organisational unit nothing else can reach is the safest resting state.
- **Read back:** Directory > Users, filtered to the pilot organisational unit, shows four accounts,
  all Suspended, and **no other account**. A real account appearing there is an incident: move it
  out immediately and record it.

**f. Leave the halt at `on`**, so the service is deployed but a stray invocation refuses:

```bash
printf 'on' | gcloud secrets versions add steward-halt --data-file=- --project="$DOER_PROJECT"
gcloud secrets versions access latest --secret=steward-halt --project="$DOER_PROJECT"   # on
```

**g. What is deliberately not unwound.** The four projects, their budgets and their deletion liens
stay: removing a lien needs the alpha `gcloud alpha resource-manager liens delete LIEN_NAME` and
`roles/resourcemanager.lienModifier` (read 2026-09-17), and the lien is what stops an accidental
project deletion after 2026-09-24. Eve's poller, policies and dataset stay, unless step d disabled
its token by decision.

- **VERIFY the unwind as a whole:** B reads back a, b and e from their own session while A watches,
  and both sign one line in `RUN_LOG`: the time, what was removed, and what was deliberately left.

---

## Before you stop

- [ ] Five views exist and every one is keyed on `agent_id` (T3-2).
- [ ] The counts reconcile by hand against day 2's `RUN_LOG`, with any mismatch written down (T3-3).
- [ ] The retrospective baseline is a table of counts with no actor, and the raw export is gone
      (T3-6, T3-7).
- [ ] The scorecard carries the line "No human minute was saved." exactly once, and no other saving
      claim anywhere (T3-9).
- [ ] The evidence pack's secret scan printed nothing (T3-10).
- [ ] The improvement was merged by the person who did not write it, or refused with a reason
      (T3-13).
- [ ] The demonstration ran in front of a sponsor, with the three opening sentences said first, and
      the record is signed by three people (T3-14 to T3-16).
- [ ] The hand-over's "what was not proved" has eleven rows (T3-18).
- [ ] The unwind ran **today**: no standing human IAM grant on any of the four projects, no role
      assignment on the robot, the custom role deleted, the OAuth grant revoked, the synthetic
      accounts suspended, the halt at `on` (T3-19).
- [ ] Nothing mutating ever touched a real employee's account, on any of the three days.

## If the day overran

Cut in this order, and write each cut into the hand-over as owed:

1. **The scorecard page** (T3-9). The query in T3-8 and its JSON output stand on their own; the
   sponsor is shown the JSON. The banned-claim grep still runs against whatever is written.
2. **The retrospective baseline** (T3-4 to T3-7). It is the only day-3 block that touches real
   administrators' data, so cutting it also removes the only privacy exposure of the day. If T3-5
   already exported, **T3-7 is not cut**: destroy the raw export whatever else is dropped.
3. **The improvement pull request** (T3-12, T3-13).

**Never cut:** the demonstration's forced dry run, the refusal of a valid approval at L1, the
two-person approved execution with its write-ahead row, the K0 pull, and the unwind. If there is
time for only one hour of day 3, it is 16:15 to 17:15.

## If day 2 did not execute

The single risk with no code fix is role-assignment propagation: Google states a role change
typically takes effect within minutes, "however, it can take up to 24 hours". If day 2's execution
failed with a Google permission error, the assignment landed at about 09:45 on 2026-09-23 and has
now had a full day.

- Run day 2's N-4 and N-5 once, at 09:00 on day 3, inside person A's slack. If they work, the
  demonstration is unchanged.
- If they fail again, **strike the executed pair from the claim. Do not soften it.** The
  demonstration then runs T3-15 rows 1, 2, 3, 4, 9 and 10, and shows Google's own refusal at row 5
  as what it is. The hand-over says in plain words that the privileged tier was not exercised, and
  T3-9's section 1 shows zero executions.
- `mo_approval_latency` will be empty in that case, so T3-12's change has no data behind it and is
  therefore refused under its own rule. That is the correct outcome, and it is recorded as one.

---

## Checked against Google's documentation on 2026-09-17

| What was checked | Page | What it said |
|---|---|---|
| Admin log events retention, lag, and administrators' rights | Workspace admin, data retention and lag times | "6 months"; "Near real time (couple of minutes)"; "Administrators cannot delete log event data or change the length of time that the data is available for." |
| Admin console path, filters and export | Workspace admin, Admin log events | Menu > Reporting > Audit and investigation > Admin log events; filters Event, Date, Actor, User email; "You can export search results to Sheets or to a CSV file"; "The total results of the export are limited to 100,000 rows." |
| Event names for the baseline | Reports API, admin user settings activity events | `SUSPEND_USER`, `UNSUSPEND_USER`, `CREATE_USER`, `DELETE_USER`, all under `applicationName=admin` |
| Reading and removing a role assignment | Directory API, `roleAssignments.list` and `roleAssignments.delete` | `GET/DELETE https://admin.googleapis.com/admin/directory/v1/customer/{customer}/roleassignments`; scope `admin.directory.rolemanagement.readonly` to read |
| Deleting a custom admin role | Directory API, `roles.delete` | `DELETE .../customer/{customer}/roles/{roleId}` |
| Revoking an app's access for one user | Directory API, `tokens.delete` and `tokens.list` | `DELETE .../users/{userKey}/tokens/{clientId}`; scope `admin.directory.user.security` |
| Disabling a secret version | gcloud `secrets versions disable` | GA; `--secret` required, `--location` for a regional secret; reversible with `versions enable` |
| Removing a conditional IAM binding | gcloud `projects remove-iam-policy-binding` | GA; `--condition` must match, `--condition=None` for an unconditional binding, `--all` for every binding of that member and role |
| Project liens | Resource Manager, project liens | `gcloud alpha resource-manager liens create/list/delete`; **alpha**; needs `roles/resourcemanager.lienModifier` |
| Creating and dropping views | BigQuery, Manage views; GoogleSQL DDL | `bq mk --use_legacy_sql=false --view`, `bq rm -t`; `CREATE OR REPLACE VIEW`, `DROP VIEW` |

## Could not verify, so each has a check that fails loudly

- **The CSV header names of an Admin log events export.** Google does not document them, which is
  why T3-5 prints the header row before anything parses it and T3-6 exits with `STOP` when the two
  named columns are absent.
- **Whether the Export action results list offers a per-export delete control.** T3-7 records the
  result either way and names it in the hand-over if it does not.
- **The exact console label for un-suspending a user** (Restore, or Reactivate, depending on the
  console's current wording). T3-15's undo reads the account's status back rather than trusting the
  label.
- **`Assumption:` the fifteen audit column names** of T3-1. The check stops the day rather than
  letting a view return zero rows in front of a sponsor.
- **`Assumption:` `gcloud alpha resource-manager liens`** is still alpha on the team's gcloud
  version. Nothing on day 3 runs it, so nothing on day 3 depends on it.
