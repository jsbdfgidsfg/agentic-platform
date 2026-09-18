# Day 3. Mo, the demonstration and the hand-over

## Status

Last reviewed: 2026-09-18. Part of the three-day build ([README](README.md), day 1, day 2, code).
Google's commands, scopes, console paths and quoted wording were checked on 2026-09-17, or on
2026-09-18 where a step says so; the table at the foot of this page lists what was read. Re-read
anything marked `Assumption:` on the day.

Corrected on 2026-09-18 against [README.md](README.md) §6.1: T3-1, T3-2, T3-8 and T3-15 are written
against the one audit schema and vocabulary of [code.md](code.md) §3 (eighteen columns; `phase`
`intent` or `outcome`; verdicts `attempting`, `dry_run`, `executed`, `denied`, `error`; reasons
without prefix; operations `suspend` and `restore`), and T3-2 pastes [code.md](code.md) §5
unchanged; the variables are the ones day 1 and day 2 actually write; the retrospective window is
set by volume; the hand-over is drafted in the late morning; the unwind starts at 16:00 and
carries every row of [README.md](README.md) §10, including the two OAuth clients, their allowlist
entries, the credentials, the staging unit, the custom IAM role, the invoker bindings, the two
application-default credentials and the sealed envelopes; the secret-disable loop names a project
per secret and fails loudly.

Reviewed again on 2026-09-18: T3-19 a (unconditional removal, owner read-back) and T3-19 h to m
(app access control, client deletion, credential destruction, staging unit, writer role, invoker
bindings, application-default credentials, envelopes) were checked against
[README.md](README.md) §7.6 and §10 rows 1 to 14 and found already in place; nothing changed.

**Wednesday 2026-09-24.** Day 3 measures what day 2 did, shows it once to a sponsor, writes down
what three days did not buy, and unwinds the standing privilege the same afternoon.

Nothing on day 3 grants anything new. The only mutating action of the day is the demonstration run,
against the same four synthetic accounts, under the same forced dry run and two-person approval. If
day 2 did not end with an executed reversible pair, read "If day 2 did not execute" before T3-1.

Person A builds. Person B approves, witnesses and holds the baseline. Neither verifies their own
work.

---

## Timetable

Working day 08:30 to 17:30, 90 minutes for lunch: **450 usable minutes** per person. The blocks
below allocate **390 minutes** to each person, leaving **60 minutes** of reserve (the gaps at
10:00, 14:15 and 15:45, and 17:15 to 17:30). Day 3 allocates fifteen minutes more than days 1 and
2 because the unwind grew on 2026-09-18 to carry every row of [README.md](README.md) §10 and starts
at 16:00, not 16:15. Not optimistic: the reserve is spent on overruns, not planned into, and not
before 14:00.

| Block | Time | Who | What |
|---|---|---|---|
| D3-A1 | 08:30 to 10:00 (90) | A | The read contract checked against the code's eighteen columns; the five metric views pasted from [code.md](code.md) §5, every one keyed on `agent_id`; reconcile the counts by hand against what day 2 did. |
| D3-B1 | 08:30 to 10:00 (90) | B | The retrospective volume baseline from Admin log events, window set by volume. B does this, not A, because the baseline supports A's programme. |
| D3-A2 | 10:15 to 11:45 (90) | A | The scorecard: one query, one page, with the minutes line. |
| D3-B2 | 10:15 to 11:45 (90) | B | The evidence pack index; draft "what is owed"; **draft the hand-over note**, so that 16:00 is signing rather than composing. |
| lunch | 11:45 to 13:15 | both | |
| D3-C1 | 13:15 to 14:15 (60) | both | One improvement as a pull request. A authors, B reviews and merges. |
| D3-C2 | 14:30 to 15:45 (75) | both | The demonstration, in front of a sponsor; the sponsor is told 60 minutes with 15 in reserve. |
| D3-C3 | 16:00 to 17:15 (75) | both | Seal the pack, sign the hand-over, run the unwind, every row read back. |
| reserve | 60 min each | both | Reserved. Not optimistic. Do not spend it before 14:00. |

---

## What day 3 reads, and where it comes from

Every name below is spelled exactly as day 1 (T1-1) and day 2 wrote it into `names.env`. Day 3
invents no variable of its own; the one value it learns, `TOIL_WINDOW_START`, is appended with
`penv` at T3-4.

| Value | What it holds | Set by |
|---|---|---|
| `CORE_PROJECT`, `EVE_PROJECT`, `DOER_PROJECT`, `MO_PROJECT` | the four project ids | day 1, T1-1 |
| `REGION`, `BQ_LOCATION`, `AGENT_ID`, `PILOT_OU`, `NONPROD_OU`, `STAGING_OU`, `SYNTHETIC_PREFIX`, `ORG_DOMAIN`, `CUSTOMER_ID` | `europe-west1`, `EU`, `steward`, the three organisational units, `pilot-user-`, the tenant domain, `my_customer` | day 1, T1-1 |
| `PERSON_A_EMAIL`, `PERSON_B_EMAIL`, `SPONSOR_EMAIL` | the two addresses, and the sponsor booked for 14:30 | day 1, T1-1 |
| `EVE_READER`, `DOER_ROBOT` | the two robot addresses | day 1, T1-1 |
| `STEWARD_OAUTH_CLIENT_ID`, `EVE_CHANNEL` | the doer's OAuth client id; person B's notification channel | day 1, T1-14a, T1-16a |
| `PILOT_ROLE_ID` | the custom role's numeric id | day 2, T2-7 |
| `STEWARD_ACTIONS_URL` | the action service, the only credential holder | day 2, T2-18 |
| `RUN_LOG` | the one run log both people write to | day 1, T1-1 |

`DOER_PROJECT:steward_audit.actions` is the write-ahead audit table day 1 created (T1-12a) and
day 2 filled, and it is what every view below reads. Load the variables once per shell:

```bash
W="$HOME/agp-3day"
set -a; . "$W/names.env"; set +a; . "$W/tools/penv.sh"
: "${CORE_PROJECT:?}" "${EVE_PROJECT:?}" "${DOER_PROJECT:?}" "${MO_PROJECT:?}" "${REGION:?}" \
  "${PILOT_OU:?}" "${NONPROD_OU:?}" "${STAGING_OU:?}" "${SYNTHETIC_PREFIX:?}" "${AGENT_ID:?}" \
  "${ORG_DOMAIN:?}" "${CUSTOMER_ID:?}" "${PERSON_A_EMAIL:?}" "${PERSON_B_EMAIL:?}" \
  "${EVE_READER:?}" "${DOER_ROBOT:?}" "${STEWARD_OAUTH_CLIENT_ID:?}" "${EVE_CHANNEL:?}" \
  "${PILOT_ROLE_ID:?}" "${STEWARD_ACTIONS_URL:?}" "${RUN_LOG:?}" \
  && echo "names.env complete"
DTOK() { gcloud auth application-default print-access-token; }     # the T2-1a credential, for Directory reads
```

If any name is unset, **read `names.env` and use the name that is actually in it**; do not type a
value from memory. No step below uses a default gcloud project: every command passes `--project`
or `--project_id`.

---

## Preconditions, checked at 08:30 before anything else

- [ ] `steward_audit.actions` holds day 2's rows: a forced dry run, a denial, and (unless the
      fallback below applies) an approved execution and its inverse.
- [ ] The halt secret `steward-halt` reads `off`. If it reads `on`, clear it with both present and
      note the minute in `RUN_LOG`.
- [ ] The robot's credential was re-consented at the end of day 2 (T2-26, to the same client).
      Without it there is no execution. **If day 2's clock beat the re-consent, it is the first
      thing today, 08:30, both present, day-2 T2-17 run once more**, inside person A's reserve;
      if it cannot be made, the executed pair is struck from the claim and T3-15 runs without
      rows 5 to 8.
- [ ] `eve.findings` returns no `log_pipeline_silent` row, so the poller has run recently.
- [ ] Both people's application-default credentials from day 2 (T2-1a, T2-8) still work:
      `curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(DTOK)"
      "https://admin.googleapis.com/admin/directory/v1/users/${DOER_ROBOT}?viewType=admin_view"`
      prints `200` on each terminal. They are revoked at T3-19.
- [ ] A sponsor is booked for 14:30 and knows the run lasts 60 minutes with 15 in reserve.

---

## D3-A1. The metric pack, 08:30 to 10:00, person A

### T3-1. Fix the read contract before writing a single view

- **WHO:** A. **WHERE:** shell.
- **WHY:** the views are written on day 3 against a table created on day 1 and written by the
  code. If a column were named differently the views must fail now, loudly, not silently return
  zero rows in front of a sponsor. The contract is the **eighteen columns
  [code.md](code.md) §3's `audit_row()` writes**, the same line day-1 T1-12a created and day-2
  T2-9 read back; there is no other audit schema in these three days.

```bash
bq show --project_id="$DOER_PROJECT" --schema --format=prettyjson steward_audit.actions \
  | python3 -c '
import json,sys
want=["row_id","ts","agent_id","request_id","phase","operation","target","level","requester",
      "approver","approval_nonce","verdict","denial_reason","request_hash","dry_run","halt_state",
      "google_status","detail"]
have=[f["name"] for f in json.load(sys.stdin)]
if have!=want:
    raise SystemExit("STOP: audit table columns are %s, not the eighteen code.md section 3 writes" % have)
print("read contract satisfied: eighteen columns, in order")
'
```

  If the check stops, **do not rename anything in BigQuery**: renaming a column the running action
  service writes to breaks the write-ahead audit, which is absolute 8. Find out which of T1-12a
  and `code.md` §3 was pasted wrongly and write it in `RUN_LOG`; the views are not changed to fit
  a wrong table.

- **Then check the vocabulary**, because a view that buckets on an unknown verdict hides rows:

```bash
bq query --use_legacy_sql=false --project_id="$DOER_PROJECT" --format=csv '
SELECT phase, verdict, IFNULL(denial_reason,"(none)") AS denial_reason, COUNT(*) AS n
FROM `'"$DOER_PROJECT"'.steward_audit.actions` GROUP BY 1,2,3 ORDER BY 1,2,3'
```

- **VERIFY:** every `phase` is `intent` or `outcome`. Every `intent` row has verdict `attempting`.
  Every `outcome` row has verdict `dry_run`, `executed`, `denied` or `error`. Every
  `denial_reason` is `(none)`, `l1_dry_run_forced` or `dry_run_requested` (on `dry_run` rows), a
  `google_error_<status>` (on `error` rows), or one of the reasons in day-2 T2-9's table:
  `halted`, `halt_unreadable`, `not_catalogued`, `target_not_in_tenant`, `not_synthetic`,
  `protected_principal`, `level_above_cap`, `audit_unavailable`, `target_unreadable_<status>`,
  `out_of_scope_ou`, `approval_missing`, `approval_unknown`, `approval_mismatch`,
  `self_approval`, `approver_not_human`, `approver_not_authorised`, `approval_expired`,
  `approval_replayed`. No reason carries a prefix. **Any value outside those lists is a finding**:
  write it in `RUN_LOG`, name it in the scorecard's denial table, and do not quietly fold it into
  "other".
- **The counting rule that follows from `phase`:** an `intent` row is written before the Google
  call and an `outcome` row after it, **but the refusals that happen before the write-ahead point
  (halt, catalogue, tenant, synthetic prefix, protected principal, level cap) produce an `outcome`
  row only.** So: **count results on `phase = 'outcome'`, and count requests by
  `COUNT(DISTINCT request_id)`**, never on both phases (every number doubles) and never on intent
  rows (every early refusal is undercounted). [code.md](code.md) §5's views do exactly this.
- **UNDO:** nothing was written.

### T3-2. Create the five views, by pasting [code.md](code.md) §5 unchanged

- **WHO:** A. **WHERE:** shell, in `$W/mo/`.
- **ACTION:** paste [code.md](code.md) §5 as `$W/mo/mo.sql`, **unchanged**, exactly as day-1
  T1-19a pastes §2. It creates the empty `mo.toil_retrospective` table (T3-6 loads it), the five
  views in `MO_PROJECT.mo` reading `DOER_PROJECT.steward_audit` across projects, and ends with the
  scorecard query. Every view is grouped on `agent_id`, because the whole point of the schema is
  that a second agent added later is counted separately without a new view. The file carries the
  placeholders `MO_PROJECT` and `DOER_PROJECT`; `sed` substitutes the ids from `names.env`.

```bash
sed -e "s/MO_PROJECT/$MO_PROJECT/g" -e "s/DOER_PROJECT/$DOER_PROJECT/g" "$W/mo/mo.sql" \
  | bq query --use_legacy_sql=false --project_id="$MO_PROJECT"
bq ls --project_id="$MO_PROJECT" mo
```

- **VERIFY:** `bq ls` shows five entries of type `VIEW` (`mo_volume_by_verdict`,
  `mo_denial_reasons`, `mo_dry_run_ratio`, `mo_approval_latency`, `mo_pair_completion`) and one
  `TABLE` (`toil_retrospective`). Each view returns rows:
  `for v in mo_volume_by_verdict mo_denial_reasons mo_dry_run_ratio mo_approval_latency mo_pair_completion; do bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --format=csv "SELECT COUNT(*) FROM \`$MO_PROJECT.mo.$v\`"; done`.
  If the script fails to parse, the paste is wrong, not the code: diff the file against §5.
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
penv TOIL_WINDOW_START "$WINDOW_START"
```

- **VERIFY:** the quoted retention in `RUN_LOG` and `TOIL_WINDOW_START` agree. If Google's page
  states a different window today, the window changes and the quote in the scorecard changes with
  it. Do not carry 2026-03-24 forward on trust. T3-5 may still **shorten** this window by volume;
  it never lengthens it.
- **UNDO:** `penv TOIL_WINDOW_START ""`; nothing else changed.
- **Cited:** Workspace admin, data retention and lag times, read 2026-09-17.

### T3-5. Fix the window by volume, export Admin log events, and print the header row first

- **WHO:** B. **WHERE:** Admin console, then shell.
- **CONSOLE PATH:** Menu > Reporting > Audit and investigation > Admin log events.
- **ACTION:** one trial search first, then three exports, one per event, each with the same date
  filter.
  1. **The trial search.** Add condition **Date** > **After** > `TOIL_WINDOW_START` and **Event**
     > `SUSPEND_USER`. Search, and read the row count the console reports. `Assumption:` an
     export of roughly 20,000 rows or fewer opens and downloads within the block; Google publishes
     the 100,000-row cap and no preparation time (read 2026-09-17). **If the count exceeds about
     20,000, cut the window to 90 days; if 90 days still exceeds it, to 30 days**, and set
     `TOIL_WINDOW_START` again with `penv`. The window is chosen by volume, once, and written in
     `RUN_LOG` and in the scorecard's section 6; it is never sliced into eighteen exports against
     the cap.
  2. Add condition **Event** > `SUSPEND_USER` with the final **Date** > **After** >
     `TOIL_WINDOW_START`. Search. Click **Export all**, give the name `3day-suspend`, choose
     **CSV**.
  3. Repeat for `UNSUSPEND_USER` (the doer's inverse) and for `CREATE_USER`, which the doer
     **cannot** perform and which is there only to show what share of admin volume the one
     catalogued pair represents.
  4. Collect the three files from **Export action results** and download them to `$W/toil-raw/`.
- **VERIFY:** each search returns a row count, and the export finishes. If any export still
  reports more than 100,000 rows it was truncated: Google states "The total results of the export
  are limited to 100,000 rows"; the window was set too wide, so cut it again and re-export, and
  record in `RUN_LOG` that the first attempt was truncated. `RUN_LOG` names the window used and
  the trial count.
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
# T3-2's mo.sql creates this table empty; A and B run in parallel, so create it here only if A has not yet.
bq show --project_id="$MO_PROJECT" mo.toil_retrospective >/dev/null 2>&1 \
  || bq mk --project_id="$MO_PROJECT" --table mo.toil_retrospective event_date:DATE,event_name:STRING,n:INT64
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

### T3-8. One query, the scorecard at the foot of [code.md](code.md) §5

- **WHO:** A. **WHERE:** shell.
- **ACTION:** the scorecard is the last statement of `mo.sql`, pasted at T3-2; nothing is written
  here. Run that statement alone, with the same substitution, and keep the JSON. The five views
  are printed beside it so that every figure on the page has a row behind it.

```bash
sed -n '/^-- The scorecard/,$p' "$W/mo/mo.sql" \
  | sed -e "s/MO_PROJECT/$MO_PROJECT/g" -e "s/DOER_PROJECT/$DOER_PROJECT/g" \
  | bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --format=prettyjson \
  | tee "$W/records/2026-09-24-T3-8-scorecard.json"
for v in mo_volume_by_verdict mo_denial_reasons mo_dry_run_ratio mo_approval_latency mo_pair_completion; do
  echo "== $v"; bq query --use_legacy_sql=false --project_id="$MO_PROJECT" --format=prettyjson "SELECT * FROM \`$MO_PROJECT.mo.$v\` ORDER BY 1"
done | tee "$W/records/2026-09-24-T3-8-views.json"
```

- **VERIFY:** one scorecard row per agent (today: one, `agent_id` `steward`) carrying `executed`,
  `dry_runs`, `denied`, `errors`, `denial_reasons`, `dry_run_share`,
  `worst_approval_latency_seconds`, `targets_left_suspended`, `retrospective_event_volume` and
  the `minutes_saved_statement`. `targets_left_suspended` is `0`. `retrospective_event_volume`
  is null if B has not loaded T3-6 yet; re-run after 10:00. `denial_reasons` names only reasons
  from T3-1's list.
- **UNDO:** nothing was written to any table.

### T3-9. One page, with the minutes line

- **WHO:** A writes. **B initials the minutes line before the page is printed.**
- **WHERE:** `$W/records/2026-09-24-T3-9-scorecard.md`. Seven short sections, every figure
  copied from T3-8's JSON, nothing typed from memory.

| Section | Content | Source |
|---|---|---|
| 1. What the doer did | counts by operation, level and verdict, dry runs shown separately; `error` rows (Google's own refusal at N2b) shown as what they are | `mo_volume_by_verdict` |
| 2. Why it refused | one row per denial reason, with the day 2 negative it came from (T2-22, T2-24, T2-25) | `mo_denial_reasons` |
| 3. How much never ran | dry runs over distinct requests | `mo_dry_run_ratio` |
| 4. How long approval took | each latency in seconds from the approval's `created_at` to the executed outcome row, plus the maximum | `mo_approval_latency` |
| 5. Was anything left broken | targets still suspended (`left_suspended <> 0`), expected `none` | `mo_pair_completion` |
| 6. Retrospective volume | counts per event over the window, with today's quoted retention, **the window actually used (6 months, 90 days or 30 days) and why**, and the trial count | `mo.toil_retrospective`, T3-4, T3-5 |
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
| 6 | No privileged-access-management entitlements and no time-boxing; standing IAM grants stood in, and their removal the same day, by hand, was the only control | `../pov/03-foundation-folders-logging-and-floors.md` PF-5.1; `../setup/12-privileged-access-catalogue.md` |
| 7 | No autonomy beyond a forced dry run and a two-person approved execution; no unattended running at any moment | `../pov/07-...md` PW-6.2 |
| 8 | No four-week prospective toil baseline, so no defensible claim of minutes saved | `../setup/02-toil-baseline.md` TB-1.2 |
| 9 | No data-protection impact assessment, no works-council information, which is why nothing mutating touched a real account | `../pov/02-decisions-people-and-the-retrospective-baseline.md` PD-8.0; `../setup/03-decisions-and-people.md` |
| 10 | No blind grading and no second reviewer on the improvement; two people give one reviewer | `../pov/08-mo-and-the-value-report.md` PM-7.1 to PM-7.3, PM-9.2 |
| 11 | Six detections and one freshness rule, not the full set; two kill switches, not seven | `../setup/25-eve-human-super-admin-detections.md` EH-2.3; `../pov/07-...md` PW-6.4 |

- **VERIFY:** every row names a file that exists: `awk -F'|' 'NR>2{print $4}' <file> | grep -oE '\.\./[a-z]+/[0-9a-z-]+\.md' | sort -u | while read -r p; do [ -f "$p" ] || echo "MISSING $p"; done` prints nothing.
- **UNDO:** a `-v2`.

### T3-18, the draft. Write the hand-over note now, sign it at 16:00

- **WHO:** B drafts, in this block. **WHERE:** `$W/records/2026-09-24-T3-18-handover.md`.
- **ACTION:** the six parts of T3-18 below. Parts 1, 3, 5 and 6 are known now and are written in
  full; parts 2 and 4 are drafted from day 2's run log and corrected after the demonstration. The
  point is that D3-C3 is **signing**, not composing: a hand-over composed at 16:15 by two tired
  people is where the unwind's time went before 2026-09-18.
- **VERIFY:** the file exists with six headed parts before lunch, and part 3 has eleven rows
  matching T3-11.

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
cd "$W" && git switch -c improve-approval-ttl
# edit APPROVAL_TTL_SECONDS from 900 to 300 in doer/actions.py
( cd doer && ORG_DOMAIN="$ORG_DOMAIN" PILOT_OU="$PILOT_OU" SYNTHETIC_PREFIX="$SYNTHETIC_PREFIX" \
    .venv/bin/python actions.py --selftest )      # day 2's twelve results must still pass
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

## D3-C2. The demonstration, 14:30 to 15:45, both, in front of a sponsor

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

- **WHO:** A drives. B approves. The sponsor watches. **WHERE:** one screen. The vocabulary in the
  right-hand column is [code.md](code.md) §3's, the same one T3-1 checked this morning. Use
  day 2's `TOK`, `POST` and `ROWS` helpers (D2-C3), defined in each person's own shell.

| # | What happens | What the room should see |
|---|---|---|
| 0 | **The synthetic-population guard, day-2 T2-8, run first**, with B's own credential | `http=200 count=4` and `PILOT_OU SYNTHETIC ONLY`. Any other output ends the demonstration before it starts, and the sponsor is told why: absolute 7 is checked on the day it matters most |
| 1 | A runs `steward-plan` with a sentence such as "suspend the pilot account that is leaving", and reads the plan with `gcloud logging read` (day-2 T2-24) | a JSON plan with `"level": 1` and `"carries_credential": false`. **The plan tool holds no credential and has no invoker on the action service**; A copies the plan by hand into the request |
| 2 | A sends the request at level 1 | `"verdict": "dry_run"`, `"executed": false`, a `would_set` naming `suspended: true`; no change in the Admin console |
| 3 | A sends the same request at level 1 **with a valid approval attached** (B issues it at level 1 first) | `"verdict": "dry_run"`, `"executed": false` again. A valid approval does not buy an execution at level 1; the outcome row carries `l1_dry_run_forced` |
| 4 | A asks `/approve` for an execution from their own shell | `"denial_reason": "approver_not_authorised"` and no nonce: the requester cannot be the approver. (Self-approval as such, `self_approval`, was proved offline on day 2 and is said to be, not shown) |
| 5 | B approves at level 2 from their own shell; A executes with that nonce | `"verdict": "executed"`; the `phase: intent` row (verdict `attempting`) is written **before** the Directory call; the synthetic account shows Suspended in the Admin console |
| 6 | Refresh `eve.findings` after one scheduler tick | Eve carries the admin event. Eve was live before the doer existed |
| 7 | Re-run T3-8's scorecard query | Mo counts the execution, keyed on `agent_id` |
| 8 | A runs the inverse, on a second approval from B | `"verdict": "executed"` for `restore`; the account is Active again; `mo_pair_completion.left_suspended` returns to `0` |
| 9 | **B pulls K0** through `POST /control/halt` (day-2 T2-25) | the next request is `"verdict": "denied"`, `"denial_reason": "halted"`, with `halt_state: on` in its outcome row. The halt is read per request and never mounted, so a warm instance sees it |
| 10 | B clears the halt back to `off`, with A present, out of band (`printf 'off' \| gcloud secrets versions add steward-halt --data-file=- --project="$DOER_PROJECT"`) | the record notes the minute of both |

- **VERIFY:** after step 5, the `phase: intent` row's `ts` is strictly earlier than its matching
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

## D3-C3. Seal, hand over, unwind, 16:00 to 17:15, both

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

- **WHO:** both sign. **WHERE:** `$W/records/2026-09-24-T3-18-handover.md`, drafted by B at D3-B2.
- **ACTION:** correct parts 2 and 4 from the demonstration record, then sign. Six short parts.
  1. What exists at 17:15: four projects, four datasets, Eve polling on a schedule with two
     alerting policies (or deliberately stopped, step d), the action service, the plan tool, five
     Mo views, the scorecard.
  2. What was proved: Eve live before the doer existed; a forced dry run that refuses a valid
     approval; the requester refused as approver, and self-approval refused offline; a two-person
     approved execution with a write-ahead audit row; a reversible pair completed; two kill
     switches pulled and timed.
  3. What was **not** proved: T3-11's eleven rows, unedited.
  4. What is left standing after the unwind: the four projects, the datasets, the deployed services
     with no valid credential, the five synthetic accounts suspended (four in the pilot
     organisational unit, one in the nonprod unit), `eve-reader@` with a live consented token and
     its owner named, and Eve still polling, or the recorded decision to stop it.
  5. **What must be unwound before anything real is touched**, if this is ever picked up again:
     the standing IAM grants, the custom admin role, the synthetic accounts. T3-19 does the first
     three today; the sentence stays in the note because the next team will build new ones.
  6. Where it grows: `../pov/` next, then `../setup/`. Every name and schema used in these three
     days is the full build's own, so nothing is renamed on the way up, and no record from these
     three days satisfies a full-build gate it does not meet.
- **VERIFY:** part 3 has eleven rows and matches T3-11 line for line. Signing takes five minutes,
  because the note was drafted before lunch.

### T3-19. The unwind, today, from 16:00, with both people present

Run these in order. Each has its own read-back. Do not batch them. Rows a to m carry every row of
[README.md](README.md) §10; before 2026-09-18 rows h to m were owed and not written. Rows h to j
are the ones that matter most: without them the tenant carries two organisation-scoped
allowlisted apps and their credentials after the run ends, which is a tenant left less safe than
it started.

**a. Remove the standing IAM grants to human principals**

Every binding in these three days is an ordinary standing grant made with `--condition=None`
([README.md](README.md) §7.6): nothing expires by itself, so this removal, by hand, in front of
both people, is the only control.

```bash
for P in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do
  echo "== $P"
  gcloud projects get-iam-policy "$P" --project="$P" --format=json \
    | python3 -c 'import json,sys; [print(b["role"], m, b.get("condition",{}).get("title","-")) for b in json.load(sys.stdin)["bindings"] for m in b["members"] if m.startswith("user:")]'
done
# then, for each line printed whose role is not roles/owner on one of the two named owners:
gcloud projects remove-iam-policy-binding "$P" --project="$P" \
  --member="user:${PERSON_A_EMAIL}" --role="roles/ROLE" --condition=None
```

  `--condition=None` removes an unconditional binding, which is what every binding here is;
  `--all` removes every binding for that member and role regardless of condition (gcloud
  `projects remove-iam-policy-binding`, read 2026-09-17). **Read back:** the loop prints, on each
  of the four projects, **no `user:` binding other than `roles/owner` for the two named owners**,
  both written into the hand-over. The two people keep `roles/owner` on projects they created;
  stripping it would lock them out of the evidence.

**b. Unassign the custom admin role, then delete it**

- **CONSOLE PATH:** Menu > Account > Admin roles > **Pilot Steward (3-day)** > Admins > remove the
  robot.
- **Read back**, from B's own session with their T2-1a-style credential, not A's:

```bash
curl -s -H "Authorization: Bearer $(DTOK)" \
  "https://admin.googleapis.com/admin/directory/v1/customer/${CUSTOMER_ID}/roleassignments?roleId=${PILOT_ROLE_ID}" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); n=len(d.get("items",[])); print("assignments:", n); sys.exit(1 if n else 0)'
```

  prints `assignments: 0`. The scope is `admin.directory.rolemanagement.readonly` (Directory API,
  `roleAssignments.list`, read 2026-09-17), which T2-1a's credential carries. `PILOT_ROLE_ID` is
  the numeric id day-2 T2-7 wrote into `names.env`; a role whose id nothing recorded cannot be
  deleted by API.
- **Then delete the role. IRREVERSIBLE.** Confirm first that the read-back is empty and that the
  privilege list is written into the hand-over, because a deleted custom role cannot be restored
  and must be rebuilt by hand: Admin roles > Pilot Steward (3-day) > Delete role (or
  `DELETE .../customer/${CUSTOMER_ID}/roles/${PILOT_ROLE_ID}` with the `admin.directory.rolemanagement`
  scope, Directory API `roles.delete`, read 2026-09-17, which the read-only credential does not
  carry; the console is the path).

**c. Revoke the robot's OAuth grant**

- **CONSOLE PATH:** Directory > Users > `$DOER_ROBOT` > Security > Connected applications > the
  `agp-3day steward` app > Remove (day-2 T2-26 used this path). The API equivalent is
  `DELETE https://admin.googleapis.com/admin/directory/v1/users/${DOER_ROBOT}/tokens/${STEWARD_OAUTH_CLIENT_ID}`,
  scope `https://www.googleapis.com/auth/admin.directory.user.security` (Directory API,
  `tokens.delete`, read 2026-09-17), which the read-only credential does not carry.
- **Read back:** the robot's Connected applications page is empty.
- **Say it in the record:** an access token already issued may stay valid for up to an hour after
  the grant is revoked. The halt flag, left at `on` in step f, is what stops work immediately.

**d. Disable the secret versions, each in its own project, and fail loudly on an empty list**

`eve-refresh-token` lives in `EVE_PROJECT`, not `DOER_PROJECT`; a loop that names one project
silently reports success for the other secret.

```bash
disable_latest() {  # secret project
  V="$(gcloud secrets versions list "$1" --project="$2" --filter='state:ENABLED' --format='value(name)' | head -1)"
  [ -n "$V" ] || { echo "STOP: $1 in $2 has no ENABLED version; read the state and decide before continuing"; return 1; }
  gcloud secrets versions disable "$V" --secret="$1" --project="$2" && echo "$1 ($2): disabled $V"
}
disable_latest steward-refresh-token "$DOER_PROJECT"
# Eve: decide in the room, and write the decision down either way.
# gcloud secrets versions list eve-refresh-token --project="$EVE_PROJECT" --format='value(name,state)'
# disable_latest eve-refresh-token "$EVE_PROJECT"          # only if Eve is being stopped
```

  `gcloud secrets versions disable` is GA, takes `--secret` and `--location` for a regional secret
  (read 2026-09-17). **Disable, not destroy:** disabling is reversible with `versions enable`.
  **Leave `eve-refresh-token` enabled if Eve is meant to keep polling after today**; if Eve is
  stopped instead, disable it, pause the scheduler (`gcloud scheduler jobs pause eve-poll-15m
  --location="$REGION" --project="$EVE_PROJECT"`) and write who paused it and why in `RUN_LOG`.
  **Read back:** `gcloud secrets versions list steward-refresh-token --project="$DOER_PROJECT"
  --format='value(name,state)'` shows no `ENABLED` version.

**e. Leave the five synthetic accounts suspended, where they are**

- Suspend all four in the pilot organisational unit **and `pilot-user-99@` in `NONPROD_OU`**
  (day-2 T2-15). Do not delete them and do not move them: a suspended synthetic account in an
  organisational unit nothing else can reach is the safest resting state.
- **Read back:** Directory > Users, filtered to `PILOT_OU`, shows four accounts, all Suspended, and
  **no other account**; filtered to `NONPROD_OU`, one account, Suspended, and no other. A real
  account appearing in either is an incident: move it out immediately and record it.

**f. Leave the halt at `on`**, so the service is deployed but a stray invocation refuses:

```bash
printf 'on' | gcloud secrets versions add steward-halt --data-file=- --project="$DOER_PROJECT"
gcloud secrets versions access latest --secret=steward-halt --project="$DOER_PROJECT"; echo   # on
```

  Clearing it is a procedure, not a control: both people hold project owner, so either could
  clear it alone. Say so in the hand-over.

**g. What is deliberately not unwound.** The four projects, their budgets and their deletion liens
stay: removing a lien needs the alpha `gcloud alpha resource-manager liens delete LIEN_NAME` and
`roles/resourcemanager.lienModifier` (read 2026-09-17), and the lien is what stops an accidental
project deletion after 2026-09-24. The audit table, the evidence dataset and the run log stay:
they are the record. Eve's poller, policies and dataset stay, unless step d stopped Eve by
decision. `eve-reader@`, a read-only admin account holding one privilege (Reports) and a live
consented token, is **left standing on purpose**: name its owner and what would revoke it (step
c's path, for `$EVE_READER`) in the hand-over.

**h. Remove both OAuth clients from app access control**

- **CONSOLE PATH:** Menu > Security > Access and data control > API controls > Manage App Access
  (read 2026-09-17). Day-1 T1-14 and T1-14a each marked a client **Trusted** at organisation
  scope, which by Google's own words "can access all Google services (both restricted and
  unrestricted)" for any user in the organisation.
- **The doer's client (`STEWARD_OAUTH_CLIENT_ID`): remove the configured app, or set it to
  Blocked.** Eve's client: **if Eve keeps polling, its entry stays**, because a blocked app's
  tokens stop working and the entry is recorded in the hand-over as deliberately left; if Eve was
  stopped at step d, remove it too.
- **Read back, by person B, not person A:** the configured-apps list no longer shows the doer's
  client id, or shows it as **Blocked**; Eve's reads as the hand-over says. Google: "Changes can
  take up to 24 hours but typically happen more quickly" (read 2026-09-17), so the read-back is
  of the configured state, and a second look the next morning is written into the hand-over as a
  task for the account owner.

**i. Delete the doer's OAuth client, and Eve's if Eve was stopped**

- **CONSOLE PATH:** Cloud console, `DOER_PROJECT`, Menu > Google Auth platform > Clients > tick
  `STEWARD_OAUTH_CLIENT_ID` > Delete ("You can restore deleted clients within 30 days of the
  deletion", Manage OAuth Clients, read 2026-09-18). The same in `EVE_PROJECT` only if Eve was
  stopped; a deleted client invalidates the tokens issued to it, so deleting Eve's client while
  Eve polls is stopping Eve without saying so.
- **Read back:** the doer's client id is not listed under Clients in `DOER_PROJECT`.

**j. Destroy the client credentials**

```bash
# the doer's client JSON, in Secret Manager since T1-14a: destroy every version. IRREVERSIBLE.
for V in $(gcloud secrets versions list steward-oauth-client --project="$DOER_PROJECT" --format='value(name)'); do
  gcloud secrets versions destroy "$V" --secret=steward-oauth-client --project="$DOER_PROJECT"
done
gcloud secrets versions list steward-oauth-client --project="$DOER_PROJECT" --format='value(name,state)'   # every row DESTROYED
# Eve's client JSON on person A's disk (T1-13). Eve's refresh-token secret already holds the client
# id and secret it needs (code.md section 6), so the file is redundant whether or not Eve polls.
F="$HOME/agp-3day/eve-client.json"; { shred -u "$F" 2>/dev/null || rm -P "$F"; }; ls "$F" 2>&1 | head -1
```

  `gcloud secrets versions destroy` is GA and "This action is irreversible" (reference, read
  2026-09-18). **Confirm first** that step i deleted the doer's client (a destroyed JSON for a
  deleted client loses nothing) and that step d's decision on Eve is written down. **Read back:**
  every version of `steward-oauth-client` reads `DESTROYED`; `ls` on the JSON path fails with "No
  such file or directory".

**k. Remove the staging unit, the writer role, the dataset writer entry and the invoker bindings**

```bash
# the dataset: readers only (day-1 T1-12a's lever), so nothing can write the audit table again
bq --project_id="$DOER_PROJECT" update --source "$HOME/agp-3day/ds-nowriter.json" "${DOER_PROJECT}:steward_audit"
bq --project_id="$DOER_PROJECT" show --format=prettyjson "${DOER_PROJECT}:steward_audit" | grep -c stewardAuditWriter   # 0
# the custom IAM role
gcloud iam roles delete stewardAuditWriter --project="$DOER_PROJECT"
# the two run.invoker bindings on the action service
for M in "user:${PERSON_A_EMAIL}" "user:${PERSON_B_EMAIL}"; do
  gcloud run services remove-iam-policy-binding steward-actions --region="$REGION" --project="$DOER_PROJECT" --member="$M" --role=roles/run.invoker
done
gcloud run services get-iam-policy steward-actions --region="$REGION" --project="$DOER_PROJECT" --format=json | grep -c 'run.invoker' || echo "0 invokers"
```

- **The staging organisational unit:** Admin console > Directory > Organisational units >
  `staging` > delete. It is empty (the robots moved out at T1-6 and T2-4). **Read back:** the unit
  is gone; `grep -c` printed `0`; the role reads `deleted` in `gcloud iam roles describe`; the
  invoker read-back printed `0 invokers`.

**l. Revoke the two application-default credentials**

Person A (T2-1a) and person B (T2-8) each hold a refresh token on disk scoped to read the
directory. Each runs, on their own machine:

```bash
gcloud auth application-default revoke
gcloud auth application-default print-access-token 2>&1 | head -1     # must fail: no credential
```

  The command "revokes Application Default Credentials that have been previously generated by
  `gcloud auth application-default login` and deletes the local credential file" (reference, read
  2026-09-18). **Read back:** the second line is an error on both machines, and both write it in
  `RUN_LOG`.

**m. The two envelopes: destroy or retain, decided, read back and signed**

- Eve's sealed password (day-1 T1-6) and the doer's two security keys in their signed envelopes
  (day-2 T2-3). For each, both people decide **destroy or retain**, and for a retained envelope,
  who holds it and where. The doer's keys: with the robot's role unassigned, its grant revoked and
  its client deleted, the keys open an account that can do nothing; retain them sealed with the
  evidence until the account is deleted, or destroy them and suspend the account now. Eve's
  password: if Eve keeps polling, retained by person B, because it is one of the three ways into
  the account the watcher depends on.
- **Read back:** person B reads each envelope's seal and both signatures aloud; A writes one line
  per envelope in `RUN_LOG` (`retained by <role>` or `destroyed at <UTC>`), and both sign.

- **VERIFY the unwind as a whole:** B reads back a, b, e, h, i and k from their own session while
  A watches, and both sign one line in `RUN_LOG`: the time, what was removed, and what was
  deliberately left (g, and Eve's entries under d, h and i if Eve polls on).

---

## Before you stop

- [ ] The read contract printed `eighteen columns, in order`, and no verdict or reason outside
      T3-1's lists was found, or the one found is named in the scorecard (T3-1).
- [ ] Five views exist, pasted from [code.md](code.md) §5 unchanged, and every one is keyed on
      `agent_id` (T3-2).
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
- [ ] The unwind ran **today, from 16:00**: no standing human IAM grant other than the two owners
      on any of the four projects, no role assignment on the robot, the custom role deleted, the
      OAuth grant revoked, the five synthetic accounts suspended, the halt at `on`, the doer's
      client removed from app access control and deleted, its JSON destroyed, Eve's client JSON
      shredded, the staging unit gone, the writer role and the invoker bindings gone, both
      application-default credentials revoked, both envelopes decided and signed (T3-19 a to m).
- [ ] Eve's fate is one written decision: polling on, with `eve-reader@`'s owner named, or
      stopped, with the token disabled and the scheduler paused (T3-19 d, g, h, i).
- [ ] Nothing mutating ever touched a real employee's account, on any of the three days.

## If the day overran

Cut in this order, and write each cut into the hand-over as owed:

1. **The scorecard page** (T3-9). The query in T3-8 and its JSON output stand on their own; the
   sponsor is shown the JSON. The banned-claim grep still runs against whatever is written.
2. **The retrospective baseline** (T3-4 to T3-7). It is the only day-3 block that touches real
   administrators' data, so cutting it also removes the only privacy exposure of the day. If T3-5
   already exported, **T3-7 is not cut**: destroy the raw export whatever else is dropped.
3. **The improvement pull request** (T3-12, T3-13).

**Never cut:** the demonstration's forced dry run, the refusal of a valid approval at level 1, the
two-person approved execution with its write-ahead row, the K0 pull, and the unwind. If there is
time for only 75 minutes of day 3, they are 16:00 to 17:15.

## If day 2 did not execute

The single risk with no code fix is role-assignment propagation: Google states a role change
typically takes effect within minutes, "however, it can take up to 24 hours". If day 2's execution
failed with a Google permission error, the assignment landed at about 09:45 on 2026-09-23 and has
now had a full day.

- Run day 2's P1, P2 and P3 once (T2-23), at 09:00 on day 3, inside person A's reserve, after the
  T2-8 guard. If they work, the demonstration is unchanged.
- If they fail again, **strike the executed pair from the claim. Do not soften it.** The
  demonstration then runs T3-15 rows 0, 1, 2, 3, 4, 9 and 10, and shows Google's own refusal at
  row 5 as what it is (verdict `error`, `google_error_403`). The hand-over says in plain words that
  the privileged tier was not exercised, and T3-9's section 1 shows zero executions.
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

Read on 2026-09-18, for the corrections of that date:

| What was checked | Page | What it said |
|---|---|---|
| Destroying a secret version | gcloud `secrets versions destroy` (`docs.cloud.google.com/sdk/gcloud/reference/secrets/versions/destroy`) | GA; `VERSION --secret [--etag] [--location]`; "This action is irreversible" (T3-19 j) |
| Revoking application-default credentials | gcloud `auth application-default revoke` | "revokes Application Default Credentials that have been previously generated by `gcloud auth application-default login` and deletes the local credential file" (T3-19 l) |
| Deleting and restoring an OAuth client | Manage OAuth Clients (`support.google.com/cloud/answer/15549257`) | Clients page, tick the id, Delete; "You can restore deleted clients within 30 days of the deletion" (T3-19 i) |
| `roleAssignments.list` scopes and the `roleId` filter | Directory API, `roleAssignments.list` | `admin.directory.rolemanagement` and `.readonly`; `roleId` "returns only role assignments containing this role ID" (T3-19 b) |
| Reading a job's log | gcloud `logging read` | GA; a filter, `--limit`, `--freshness` (T3-15 row 1) |

## Could not verify, so each has a check that fails loudly

- **The CSV header names of an Admin log events export.** Google does not document them, which is
  why T3-5 prints the header row before anything parses it and T3-6 exits with `STOP` when the two
  named columns are absent.
- **Whether the Export action results list offers a per-export delete control.** T3-7 records the
  result either way and names it in the hand-over if it does not.
- **The exact console label for un-suspending a user** (Restore, or Reactivate, depending on the
  console's current wording). T3-15's undo reads the account's status back rather than trusting the
  label.
- **The eighteen audit column names** of T3-1 are not an assumption: they are what
  [code.md](code.md) §3 writes and day-1 T1-12a created. The check still stops the day rather
  than letting a view return zero rows in front of a sponsor, because a wrong paste is possible.
- **`Assumption:` the export volume that fits the block** (about 20,000 rows, T3-5). Google
  publishes the 100,000-row cap and no preparation time; the trial search is what settles it.
- **`Assumption:` a project-level custom role in a dataset access entry** (T3-19 k reads back
  whichever role T1-12a actually granted, `stewardAuditWriter` or `WRITER`).
- **`Assumption:` `gcloud alpha resource-manager liens`** is still alpha on the team's gcloud
  version. Nothing on day 3 runs it, so nothing on day 3 depends on it.
