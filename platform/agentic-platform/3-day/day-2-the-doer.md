# Day 2. The doer

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-17
- Steps T2-1 to T2-27. Run date 2026-09-23. Two people, 08:30 to 17:30.
- Compressed from [pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) §1 to §7. Every
  command, flag, scope, privilege name and console path below was checked against Google's current
  documentation on 2026-09-17; see Sources.

Part of the three-day build. Entry point: [README.md](README.md). Previous day:
[day-1-platform-and-eve.md](day-1-platform-and-eve.md). Next day:
[day-3-mo-demonstration-and-handover.md](day-3-mo-demonstration-and-handover.md). Code:
[code.md](code.md).

Today builds the one thing that can act. A robot account holding **one** custom Workspace admin
role, scoped to an organisational unit that contains **four synthetic accounts and nothing else**,
suspends one of those accounts and restores it. Every guard that makes that safe is built, and
then pulled, in front of both people.

**The ordering rule was settled yesterday.** Eve is live. If Eve is not live, today does not start.
The proof that Eve was live before the doer existed is T2-13: Eve pages the doer's own birth.

---

## The day at a glance

Working day 08:30 to 17:30, 60 minutes for lunch. 390 of 480 usable minutes are allocated to each
person; the remaining 90 minutes are slack, reserved and not optimistic.

| Block | Time | Who | What |
|---|---|---|---|
| D2-C1 | 08:30-10:00 | Both | T2-1 to T2-8. The robot, two keys counted by eye, the move into the service-identity OU, the role assigned scoped to `PILOT_OU` with person B approving and re-reading it. **The assignment lands by about 09:45.** |
| D2-A1 | 10:15-11:45 | A | T2-9 to T2-12. The audit tables read back and the writer narrowed to one identity on one dataset; the secrets checked; the container built; `--selftest` runs all eleven results offline before anything is deployed. |
| D2-B1 | 10:15-11:45 | B | T2-13 to T2-15. Confirm Eve paged the role assignment; commit the catalogue of one reversible pair; write the approval procedure. |
| | 11:45-13:15 | Both | Break. |
| D2-C2 | 13:15-14:30 | Both | T2-16 to T2-21. The doer's OAuth client, marked Trusted; the second consent sitting, one scope; `steward-actions` deployed as the only credential holder; `steward-plan` deployed holding nothing; the delegation-absence proof, second half. |
| D2-C3 | 14:45-16:00 | Both | T2-22 to T2-24. The witnessed results: six refusals, one approved execution and its inverse, and the model that holds nothing. |
| D2-C4 | 16:15-17:15 | Both | T2-25 to T2-27. K0 and K4, both pulled by person B and timed, the re-consent inside the same sitting, and the close. |

**The tightest block is D2-C3.** It is 75 minutes for nine results. It only fits because T2-12 ran
the same set offline four hours earlier. If a result fails there, fix it before lunch, not at 14:45.

---

## Before you start

Do not begin T2-2 until every line is true. Person B reads them aloud; person A answers.

- [ ] Day 1 closed. `eve-reports-poller` has run on its schedule at least twice this morning and
      `eve.ws_activities` has rows with a `ts` inside the last 30 minutes.
- [ ] The seeded test of day 1 passed: person B alone received the alert and recorded the latency.
- [ ] `PILOT_OU` exists at the path in `names.env` and holds exactly four accounts, all matching
      `pilot-user-NN@$ORG_DOMAIN`, none an administrator.
- [ ] `SERVICE_IDENTITY_OU` exists with 2-Step Verification enforced, method **Only security key**,
      no enrolment period, device trust off.
- [ ] The custom admin role **Pilot Steward (3-day)** exists, carries exactly Users > Read and
      Users > Update > Suspend users, and is assigned to nobody.
- [ ] Both security keys are in the room, unused, still in their packaging.
- [ ] Person B has their own terminal, their own browser profile, and their own Google sign-in.
      Person B never types into person A's session today, and person A never approves anything.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
: "${ORG_DOMAIN:?}" "${CUSTOMER_ID:?}" "${CORE_PROJECT:?}" "${DOER_PROJECT:?}" "${EVE_PROJECT:?}" \
  "${MO_PROJECT:?}" "${REGION:?}" "${BQ_LOCATION:?}" "${PILOT_OU:?}" "${SERVICE_IDENTITY_OU:?}" \
  "${NONPROD_OU:?}" "${AGENT_ID:?}" && echo "day 1 names present"
bq query --project_id="$EVE_PROJECT" --use_legacy_sql=false --format=csv \
  "SELECT MAX(ts) AS newest FROM \`${EVE_PROJECT}.eve.ws_activities\`"
```

`newest` must be inside the last 30 minutes. If it is not, Eve is not live and today does not
start: fix the poller first, out of today's slack.

Day 1 fixed `AGENT_ID=steward`, `REGION=europe-west1`, `BQ_LOCATION=EU`, `PILOT_OU=/pilot`,
`SERVICE_IDENTITY_OU=/service-identities`, `NONPROD_OU=/nonprod`, and the four synthetic accounts
`pilot-user-01@` to `pilot-user-04@`. T2-1 adds today's five names to the same file.

---

## D2-C1, 08:30 to 10:00. The robot and its one privilege

Both people, at one keyboard, for the whole block. This block is first because of the one risk
with no code fix: Google says an admin role change "can take up to 24 hours but typically happen
more quickly" (Assign specific admin roles, read 2026-09-17). Assigning at 09:45 leaves five hours
before the first execution at about 15:00.

### T2-1 Open the day

- **WHO:** Both. **WHERE:** one terminal, screen visible to both.
- **DO:** Read the "Before you start" list aloud and tick it. Add today's names to the same file,
  and open the run log.

```bash
cat >> "$HOME/agp-3day/names.env" <<EOF
export STAGING_OU="/staging"                         # created in T2-2, deleted in the day-3 unwind
export DOER_ROBOT="steward-robot@\${ORG_DOMAIN}"
export SYNTHETIC_PREFIX="pilot-user-"                # must match the accounts day 1 actually created
export PERSON_A_EMAIL="a@\${ORG_DOMAIN}"             # Assumption: replace with the builder's address
export PERSON_B_EMAIL="\${PERSON_B_EMAIL:-b@\${ORG_DOMAIN}}"
EOF
set -a; . "$HOME/agp-3day/names.env"; set +a
[ "$PERSON_A_EMAIL" != "$PERSON_B_EMAIL" ] && echo "two people, two addresses" || echo "STOP: one address"
printf '%s  day 2 opened. PILOT_OU holds synthetic accounts only. Nothing mutating touches a real account today.\n' \
  "$(date -u +%FT%TZ)" >> "$RUN_LOG"
```

- **PROVES:** `two people, two addresses`. The run log carries the opening line, the date, both
  roles and the four project ids. If day 1 finished early and T2-16 was pulled forward,
  `STEWARD_OAUTH_CLIENT_ID` is already in `names.env`: note it and skip to T2-17 when you get there.
- **UNDO:** Not applicable.

### T2-2 Create the robot in the staging OU, with no recovery channel

- **WHO:** A operates, B watches the screen. **WHERE:** Admin console, Menu > Directory >
  Organisational units > Create; then Directory > Users > Add new user; then the user's page >
  Security.
- **DO:** First create the organisational unit `staging` at the top level, with 2-Step Verification
  left at Inherit. Then create `steward-robot@$ORG_DOMAIN` **in `staging`**, not in
  `SERVICE_IDENTITY_OU`. Assign a licence. Set the password from the password manager's generator so
  the value exists only there; record the vault entry's **name** in the run log, never the value.
  Then Security > Recovery information: remove any recovery email and any recovery phone. Leave
  "Ask for a password change at the next sign-in" **off**: an unattended robot cannot answer that
  prompt.
- **PROVES:** The user page shows `staging`, a licence, and **no admin role**. Recovery information
  is empty on both lines. Nothing on disk and nothing in `names.env` holds the password.
- **UNDO:** Delete the user while it holds nothing, then delete the empty OU. Reversible today, and
  the day-3 unwind deletes the OU in any case.

Why a staging OU first: `SERVICE_IDENTITY_OU` forces a security key at sign-in, and the account
cannot register its first key until it can sign in once.

### T2-3 Two security keys, counted by eye

- **WHO:** A registers key A; **B is present for both and takes key B**. **WHERE:** a clean browser
  profile signed in to nothing else; the robot's own sign-in.
- **DO:** Sign in as the robot in the clean profile with the vault password. Register key A, then
  key B, at myaccount.google.com > Security > 2-Step Verification > Security key. Then, in the
  Admin console, open Menu > Directory > Users > `steward-robot@` > Security and **count the keys on
  screen with your eyes**. Write the number you saw into the run log as
  `security_keys_observed=2`, and both people initial that line.
- **PROVES:** The line reads exactly 2 and carries two sets of initials. Do not substitute an API
  field for the count: a boolean that says enrolment happened does not say how many keys exist, and
  one key is a lock-out waiting to happen.
- **UNDO:** Remove and re-register a key. After T2-4 this is a lock-out risk: move the account back
  to `staging` first.

Seal key A and key B in **separate** signed envelopes. Neither person holds both. Write the two
custody lines in the run log and both sign.

### T2-4 Move into `SERVICE_IDENTITY_OU` and prove the key is forced

- **WHO:** A moves; B witnesses the two sign-in attempts. **WHERE:** Admin console, Menu >
  Directory > Users > `steward-robot@` > More options > Change organisational unit.
- **DO:** Move the robot into `SERVICE_IDENTITY_OU`. Sign the robot out everywhere. Sign in again
  in the clean profile. Then, in the same profile, try to open admin.google.com as the robot.
- **PROVES:** The second sign-in offers the security key and **no code fallback and no "try another
  way" that ends in a code**. The Admin console refuses the robot ("You do not have access"). Both
  observations go in the run log, initialled by B.
- **UNDO:** Move back to `staging`. The key registration survives the move.

Google's 2-Step Verification page (read 2026-09-17) gives the method as *"Only security key - Users
must set up a security key"*, with a separate "New user enrolment period" and an "Allow user to
trust the device" option under Frequency. Confirm on screen that the enrolment period is not giving
this new account a password-only window; if it is, shorten it and move the robot after it lapses.

### T2-5 The robot holds no admin role, before it holds one

- **WHO:** A runs; B reads the output. **WHERE:** the APIs Explorer on the Directory API reference
  pages, signed in as person A's admin account, or `curl` with an admin token.
- **DO:** Run `users.get` with `userKey=steward-robot@$ORG_DOMAIN`, `projection=full`,
  `viewType=admin_view`. Then run `roleAssignments.list` with `userKey=steward-robot@$ORG_DOMAIN` and
  `customer=my_customer`.
- **PROVES:** `isAdmin` is not `true`; `isDelegatedAdmin` is not `true`; no `recoveryEmail` and no
  `recoveryPhone` field; `suspended` is `false`. `roleAssignments.list` returns **no `items`**.
  Paste both JSON bodies into the run log. This is the "before" half of T2-7's read-back.
- **UNDO:** Read only.

### T2-6 The delegation-absence proof, first half

- **WHO:** A reads; **B repeats the read independently from their own session**. **WHERE:** Admin
  console, Menu > Security > Access and data control > API controls > **Manage Domain Wide
  Delegation** (super administrator only; read 2026-09-17).
- **DO:** Read the whole API clients list on screen and write every client id in it into
  `$HOME/agp-3day/dwd-before.txt`, one per line. Then list every service account in the doer's project:

```bash
gcloud iam service-accounts list --project="$DOER_PROJECT" \
  --format="value(email,uniqueId)" | tee "$HOME/agp-3day/doer-sa-ids.tsv"
```

- **PROVES:** Both people have read the same list and agree on its contents; no unique id from
  `doer-sa-ids.tsv` appears in it. Google documents no API that lists delegation clients, so this is
  read by two pairs of eyes and by nothing else. **An entry neither person recognises is reported to
  the sponsor the same hour, never used, and never deleted by one person alone.**
- **UNDO:** Read only. No step of this build ever creates a delegation entry. There is no step
  anywhere in these three days that opens this page to add something.

### T2-7 Assign **Pilot Steward (3-day)**, scoped to `PILOT_OU`

This is the step day 1's T1-16 points at as tomorrow's assignment.

- **WHO:** A assigns. **B reads the privilege list on screen before Save, approves in writing, and
  then re-reads the assignment from their own session.** **WHERE:** Admin console, Menu > Account >
  Admin roles > **Pilot Steward (3-day)** > Assign admin (read 2026-09-17).
- **DO:** Before Save, B reads the role's privilege list aloud. It must be exactly:

  | Ticked | Deliberately absent |
  |---|---|
  | Users > Read | Users > Create, Users > Delete |
  | Users > Update > **Suspend users** | Users > Update > Move users, Rename users, Reset password, Force password change, Add/remove aliases |
  | | **Every Groups privilege**, every Security, Domain, Admin roles, Data and Services privilege |

  Assign the role to `steward-robot@`. Then, **next to "All organizational units", click Edit,
  select `PILOT_OU` only, and click Done** (Assign specific admin roles, read 2026-09-17). Save.
  Person B writes and signs one line in the run log: *"I read the privilege list and approved the
  assignment of Pilot Steward (3-day), scoped to /pilot, to steward-robot@, at HH:MM."*
- **PROVES:** From **person B's own session**, `roleAssignments.list` with
  `userKey=steward-robot@$ORG_DOMAIN` returns **exactly one item**, with `scopeType: ORG_UNIT` and
  `orgUnitId` equal to `PILOT_OU`'s id. `users.get` now shows `isDelegatedAdmin: true` and `isAdmin`
  still not `true`. Any item with `scopeType: CUSTOMER` fails the step and is unassigned in the same
  minute.
- **UNDO:** Admin roles and privileges > Pilot Steward (3-day) > Unassign. This is the lever that
  ends the day if anything goes wrong, and it is the first line of day 3's unwind.

**If "Edit" does not appear next to "All organizational units", stop.** Google's page says: *"If you
don't see Edit, you cannot apply the role to organizational units."* A customer-scoped assignment
would let the robot's token read every real employee's directory record, which nothing in these
three days covers. The fix is the role, not the assignment: re-open it and confirm it carries only
Users and Organizational Units privileges, the ones Google says can be limited to organisational
units. One ticked Groups box removes the Edit link.

Note the time of the Save. Nothing executes for at least four hours; the first execution is at 15:00.

### T2-8 The synthetic-population guard

- **WHO:** A runs; B reads. **WHERE:** terminal.
- **DO:** Run the guard. Run it again immediately before every execution today, and on day 3.

```bash
# Every account in PILOT_OU must match the synthetic pattern. One that does not stops the day.
Q=$(python3 -c "import urllib.parse,os;print(urllib.parse.quote('orgUnitPath='+os.environ['PILOT_OU']))")
curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://admin.googleapis.com/admin/directory/v1/users?customer=my_customer&viewType=admin_view&projection=full&maxResults=200&query=$Q" \
  | python3 -c '
import json,sys,re,os
us=json.load(sys.stdin).get("users",[])
pat=re.compile(r"^pilot-user-\d{2}@"+re.escape(os.environ["ORG_DOMAIN"])+r"$")
bad=[u["primaryEmail"] for u in us if not pat.match(u["primaryEmail"]) or u.get("isAdmin") or u.get("isDelegatedAdmin")]
print("count=%d"%len(us)); print("BAD:",bad) if bad else print("PILOT_OU SYNTHETIC ONLY")
sys.exit(1 if bad or len(us)!=4 else 0)'
```

- **PROVES:** `count=4` and `PILOT_OU SYNTHETIC ONLY`. Any other output stops the day at this line.
  A count larger than four usually means the query was not encoded and the read fell back to the
  whole tenant; fix the encoding, never widen the check.
- **UNDO:** Read only.

---

## D2-A1, 10:15 to 11:45. Person A: the audit, the halt and the selftest

### T2-9 Read back the audit tables, and know their columns

- **WHO:** A. **WHERE:** terminal.
- **DO:** `tools/bootstrap.sh` created `steward_audit` and its two tables on day 1. Read them back
  and learn the column names, because every verification today is a query against them.

```bash
bq show --format=prettyjson "${DOER_PROJECT}:steward_audit"          | grep -E '"location"|datasetId'
bq show --format=prettyjson "${DOER_PROJECT}:steward_audit.actions"  | grep -E '"name"|"type"' | head -40
bq show --format=prettyjson "${DOER_PROJECT}:steward_audit.approvals"| grep -E '"name"' | head -10
```

- **PROVES:** Location `EU`. `actions` carries, in this order: `row_id`, `ts`, `agent_id`,
  `request_id`, `phase`, `operation`, `target`, `level`, `requester`, `approver`, `approval_nonce`,
  `verdict`, `denial_reason`, `request_hash`, `dry_run`, `halt_state`, `google_status`, `detail`,
  partitioned by day on `ts` and clustered on `operation, verdict`. `approvals` carries `nonce`,
  `request_hash`, `approver`, `created_at`, `operation`, `target`, `level`.

  Two values matter all day. **`phase` is `intent` or `outcome`**: the `intent` row is written
  before the Google call and the `outcome` row after, and they share a `request_id`. **`verdict` is
  `dry_run`, `executed` or `denied`.** Denial reasons carry no prefix: `halted`, `out_of_scope_ou`,
  `protected_principal`, `not_catalogued`, `self_approval`, `approver_not_authorised`,
  `approver_not_human`, `approval_mismatch`, `audit_unavailable`.
- **UNDO:** Read only. **The dataset name and location are IRREVERSIBLE**, and were fixed yesterday.
  Nothing today writes a `bq rm` against `steward_audit`: it is the only evidence the doer produces.

### T2-10 Narrow the writer to one identity on one dataset

- **WHO:** A. **WHERE:** terminal.
- **DO:** The bootstrap gave `steward-actions@` `roles/bigquery.dataEditor` **on the whole project**,
  which is wider than it needs and cannot be withdrawn quickly enough for T2-24 N4. Replace it with
  a custom role granted in the dataset's own access array. A dataset ACL takes effect at once; a
  project IAM change does not.

```bash
gcloud iam roles create stewardAuditWriter --project="$DOER_PROJECT" \
  --title="Steward audit writer" --stage=GA \
  --permissions=bigquery.tables.updateData,bigquery.tables.get,bigquery.datasets.get

bq --project_id="$DOER_PROJECT" show --format=prettyjson "${DOER_PROJECT}:steward_audit" \
  > "$HOME/agp-3day/ds-writer.json"
python3 - <<'PY'
import json, os
h, p = os.environ["HOME"], os.environ["DOER_PROJECT"]
d = json.load(open(h + "/agp-3day/ds-writer.json"))
d["access"] = [a for a in d["access"] if a.get("specialGroup") != "projectOwners"]
for sa in (f"eve-verifier@{os.environ['EVE_PROJECT']}.iam.gserviceaccount.com",
           f"mo-metrics@{os.environ['MO_PROJECT']}.iam.gserviceaccount.com"):
    if not any(a.get("userByEmail") == sa for a in d["access"]):
        d["access"].append({"role": "READER", "userByEmail": sa})
json.dump(d, open(h + "/agp-3day/ds-nowriter.json", "w"), indent=1)   # readers only: N4's lever
d["access"].append({"role": f"projects/{p}/roles/stewardAuditWriter",
                    "userByEmail": f"steward-actions@{p}.iam.gserviceaccount.com"})
json.dump(d, open(h + "/agp-3day/ds-writer.json", "w"), indent=1)     # readers plus one writer
PY
bq --project_id="$DOER_PROJECT" update --source "$HOME/agp-3day/ds-writer.json" "${DOER_PROJECT}:steward_audit"

gcloud projects remove-iam-policy-binding "$DOER_PROJECT" --condition=None \
  --member="serviceAccount:steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/bigquery.dataEditor
```

- **PROVES:** The access array lists **exactly one** writer entry, the two readers, and no
  `projectOwners` OWNER entry. `steward-plan@` holds nothing on the dataset. `roles/bigquery.jobUser`
  stays at project level, because the service must still run a query job. Keep both JSON files:
  they are T2-24 N4's two levers.
- **UNDO:** `bq update --source "$HOME/agp-3day/ds-nowriter.json"` removes the writer;
  `gcloud projects add-iam-policy-binding ... --role=roles/bigquery.dataEditor` puts the wide grant
  back. Do not delete the custom role today; a deleted custom role id is not immediately reusable.

`Assumption:` `mo-metrics@` may not exist until day 3, and BigQuery may refuse a project-level custom
role in a dataset access entry. If either is refused, drop that line, fall back to
`roles/bigquery.dataEditor` scoped to the dataset only, and record the widening in the run log.

### T2-11 The halt secret, and the credential secret

- **WHO:** A. **WHERE:** terminal.
- **DO:** Both secrets exist from day 1, empty except for the halt. Verify them, and verify that the
  service can both read the halt and write a new version of it, because `POST /control/halt` is how
  person B pulls K0.

```bash
gcloud secrets versions access latest --secret=steward-halt --project="$DOER_PROJECT"   # expect: off
for S in steward-halt steward-refresh-token; do
  echo "== $S"; gcloud secrets get-iam-policy "$S" --project="$DOER_PROJECT" \
    --format='table(bindings.role, bindings.members)'
done
gcloud secrets create steward-oauth-client --replication-policy=user-managed \
  --locations="$REGION" --project="$DOER_PROJECT"     # created empty; T2-16 adds version 1
```

- **PROVES:** The halt reads `off`. On `steward-refresh-token`, exactly one accessor, and it is
  `steward-actions@`: not `steward-plan@`, not a human. On `steward-halt`, `steward-actions@` holds
  both `secretAccessor` and `secretVersionAdder`. Nothing else holds anything.
- **UNDO:** `gcloud secrets delete steward-oauth-client --project="$DOER_PROJECT"` while empty.

**The halt is read per request, never through `--set-secrets`.** Cloud Run's page says environment
variables built from secrets are *"resolved at instance startup time"* (read 2026-09-17), so a warm
instance started before the halt was written would never see it. The service calls
`access_secret_version` on every request instead, which is explicit, timed and auditable. **The
refresh token is not in `--set-secrets` either**, for the same reason inverted: the service reads it
per request, so a revoked token fails at Google straight away instead of living on in a warm
instance. T2-25 and T2-26 prove both against an instance that was already warm. A kill switch that
does not kill is worse than none.

### T2-12 Build the container and run every result offline

- **WHO:** A. **WHERE:** VS Code and a terminal, in `$HOME/agp-3day/doer/`.
- **DO:** Paste `actions.py`, `plan.py` and the two `requirements.txt` files from
  [code.md](code.md) §3, §4 and §8. Then, before anything is deployed:

```bash
cd "$HOME/agp-3day/doer" && python3.12 -m venv .venv && . .venv/bin/activate
pip install -q -r requirements.txt
ORG_DOMAIN="$ORG_DOMAIN" PILOT_OU="$PILOT_OU" SYNTHETIC_PREFIX=pilot-user- \
  python3.12 actions.py --selftest
```

- **PROVES:** Eleven lines, every one starting `PASS`, then `0 failure(s)`, exit code 0:

  | | Refusal | Reason it must print |
  |---|---|---|
  | N1 | halt refuses | `halted` |
  | N2 | out of scope refused | `out_of_scope_ou` |
  | N3 | protected principal refused | `protected_principal` |
  | N4 | audit unavailable refuses | `audit_unavailable`, HTTP 503 |
  | N5 | level 1 forces a dry run | verdict `dry_run`, executed false, **with a valid approval in hand** |
  | N6 | self-approval refused | `self_approval` |
  | N7 | a service identity cannot approve | `approver_not_human` |
  | N8 | approval bound to another request | `approval_mismatch` |
  | P1 | approved suspend executes | verdict `executed` |
  | P2 | audit row written ahead of the call | first row `phase: intent` |
  | P3 | the inverse restores | `suspended` back to false |

  Every one runs against a fake Directory client and a fake audit sink: no Google API, no
  credential, no network. **A failure here is fixed now, in this block, not at 14:45.**
- **UNDO:** Nothing was deployed.

Use Code Assist to explain a traceback and adapt a variable name. Do not let it rewrite the policy
order in `/act`, which is: halt, catalogue, scope, synthetic prefix, protected principal,
**write the intent row**, level, approval, call, outcome row. Changing that order is a defect, not a
refactor, and the eleven lines above are how you notice.

---

## D2-B1, 10:15 to 11:45. Person B: Eve saw the doer being born

### T2-13 Confirm Eve paged the role assignment

- **WHO:** B alone. **WHERE:** B's own mailbox; the BigQuery console on `EVE_PROJECT`.
- **DO:** Find the alert for T2-7 in your own inbox. Then read the finding behind it:

```bash
bq query --project_id="$EVE_PROJECT" --use_legacy_sql=false --format=prettyjson \
 "SELECT rule_id, subject, actor, route, event_time
  FROM \`${EVE_PROJECT}.eve.findings\`
  WHERE event_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 4 HOUR)
  ORDER BY event_time"
```

- **PROVES:** One row with `rule_id` for a role assignment, `subject` = `steward-robot@$ORG_DOMAIN`,
  `actor` = person A's admin account. Record the latency: the Save time from T2-7 to the minute the
  alert arrived. **Eve was live before the doer existed, and the proof is that Eve saw the doer
  being born.** Write that sentence and the latency in the run log; B signs it.
- **UNDO:** Read only.

If no finding appears within one scheduler tick plus Google's stated Admin log lag of a couple of
minutes, stop and fix Eve. Nothing today proceeds past a blind verifier.

### T2-14 Review and commit the catalogue: one reversible pair, and nothing else

- **WHO:** B reads every line; A answers. **WHERE:** `$HOME/agp-3day/doer/actions.py`, the `CATALOGUE`
  constant, and `$HOME/agp-3day/plan/plan.py`, its own `CATALOGUE` list. Commit both.
- **DO:** The catalogue is a constant in the code, not a file the service loads at runtime, so
  changing it is a commit and a redeploy that person B witnesses. Read it on screen and check four
  things:

  1. **Exactly two operations, and they are each other's inverse.** `suspend` sets
     `suspended: true`; `restore` sets `suspended: false`. Nothing else: no group operation, no
     rename, no move, no delete, no password reset. Anything the robot's role could not do anyway
     still does not belong here.
  2. `PILOT_OU` in the deploy command equals `PILOT_OU` in `names.env`, character for character.
  3. `SYNTHETIC_PREFIX` is `pilot-user-`, matching the four accounts day 1 actually created, so a
     target whose local part does not start with it is
     refused before anything else is considered.
  4. The protected test refuses any address ending `.gserviceaccount.com` and any local part
     containing `robot`, so the doer can never act on a service identity or on itself. Person B's
     own account is refused by (3) in any case: it does not carry the synthetic prefix.

- **PROVES:** Person B initials the four checks in the run log. `plan.py`'s catalogue lists the same
  two operations, so the model is never shown an operation the service would refuse.
- **UNDO:** Revert the commit and redeploy. One pair proves write-ahead audit, the forced dry run,
  two-person approval and a kill; three pairs cost code and prove nothing new in three days.

**The level is not in the catalogue and not in a file: it travels in the request.** A request with
`"level": 1` is a forced dry run. A request with `"level": 2` can execute, and only with a valid
approval from someone other than the requester. `LEVEL_CAP=2` on the deployment is the ceiling, and
a request above it is refused with `level_above_cap`. That is weaker than the full build, where the
level lives in a file with a code owner and a two-reviewer merge; it is named as a cut in
[README.md](README.md) (C-05, C-10).

### T2-15 The approval procedure

- **WHO:** B writes. **WHERE:** `$HOME/agp-3day/doer/approval.md`, and the run log.
- **DO:** Write the procedure in six lines and sign it:

  1. Person A sends `POST /act` at `"level": 1` and receives a `request_hash` and a `dry_run`
     verdict naming the field it would have set.
  2. Person A reads the `request_hash`, the operation and the target **aloud**.
  3. Person B sends `POST /approve` **from their own terminal, with their own identity token**,
     carrying the same operation, target and `"level": 2`, and receives a `nonce`.
  4. Person A sends `POST /act` at `"level": 2` carrying that nonce.
  5. The service refuses if the approver is not in `APPROVERS`, if the approver equals the
     requester, if the approver's token is a service identity, if the nonce has been used, if it has
     expired, or if the approval's `request_hash` does not match the request being made.
  6. Person B writes the nonce, the time and their signature in the run log.

- **PROVES:** `APPROVERS` on the deployment names person B and nobody else, so the approval cannot
  be issued by the requester or by any machine. There is no approval user interface and no
  Identity-Aware Proxy today: the approver is in the room and signs the paper record as well as
  making the call.
- **UNDO:** Not applicable.

Last thing in this block: create **one more synthetic account**, `pilot-user-99@$ORG_DOMAIN`, in
`NONPROD_OU`, not in `PILOT_OU`. It is the out-of-scope target N2 needs, and it exists so that no
test ever needs a real account to stand outside the boundary.

---

## D2-C2, 13:15 to 14:30. The consent sitting and the deployment

### T2-16 The doer's OAuth client, and mark it Trusted

- **WHO:** A creates; B watches the dialog. **WHERE:** Cloud console, Menu > **Google Auth
  Platform** > Audience, then Clients, in `DOER_PROJECT`; then the Admin console.
- **DO:** Set the Audience to **Internal** (available because the project sits in the organisation;
  Internal limits authorisation requests to members of the organisation). Then Clients > Create
  client > Application type **Desktop app**, name `steward-2026-09-23`, Create. Copy the client JSON
  from the dialog and paste it straight into Secret Manager, on stdin, with nothing echoed:

```bash
gcloud secrets versions add steward-oauth-client --data-file=- --project="$DOER_PROJECT"
# paste the JSON, then Ctrl-D. Nothing is written to disk. Then:
pbcopy </dev/null
find "$HOME" -name 'client_secret*' -maxdepth 4 2>/dev/null   # must print nothing
```

  Then mark the client Trusted: Admin console > Menu > Security > Access and data control > API
  controls > App access control > **Manage Third-Party App Access** > Configure new app > **OAuth
  App Name Or Client ID** > paste the client id > Search > Select > tick the client id > Select >
  **Trusted** > Configure (read 2026-09-17).

```bash
penv() { grep -q "^$1=" "$HOME/agp-3day/names.env" && sed -i '' "s|^$1=.*|$1=$2|" "$HOME/agp-3day/names.env" || printf '%s=%s\n' "$1" "$2" >> "$HOME/agp-3day/names.env"; }
penv STEWARD_OAUTH_CLIENT_ID "<the client id from the dialog>"
```

- **PROVES:** The Clients page lists exactly one client for this project. `find` prints nothing.
  `gcloud secrets versions list steward-oauth-client --project="$DOER_PROJECT"` shows one `ENABLED`
  version. The Admin console's configured-apps list shows the client id as Trusted.
- **UNDO:** **IRREVERSIBLE as a secret: the client secret is shown once.** If it is lost, delete
  this client and create a new one with a new name. Deleting the client is reversible in the sense
  that nothing depends on it until T2-17.

`Assumption:` the exact Google Auth Platform page layout moves. If Audience offers no Internal
option, the project is not under the organisation and the consent will be refused by the Admin
console's app controls; stop and check the project's parent rather than switching to External.

### T2-17 The second consent sitting

- **WHO:** A types; **B is the second person at the keyboard and reads the granted scope list back
  before anything is saved.** **WHERE:** the clean robot browser profile; a terminal.
- **The rule of the room, read aloud:** exactly two people; no screen share, no recording, no `tee`,
  no shell history file for this shell; no service identity is the second person; key A and key B
  leave their envelopes on one signed line and neither person holds both.
- **DO:** Sign in as `steward-robot@` in the clean profile with the vault password and key A. Then:

```bash
unset HISTFILE
gcloud secrets versions access latest --secret=steward-oauth-client --project="$DOER_PROJECT" \
  > /dev/shm/c.json 2>/dev/null || gcloud secrets versions access latest \
  --secret=steward-oauth-client --project="$DOER_PROJECT" > "$TMPDIR/c.json"
python3.12 tools/consent.py \
  --client-json="${TMPDIR:-/dev/shm}/c.json" \
  --scope="https://www.googleapis.com/auth/admin.directory.user" \
  --secret=steward-refresh-token --project="$DOER_PROJECT"
rm -f "${TMPDIR:-/dev/shm}/c.json"
```

  Copy the printed URL **by hand** into the clean robot profile. Never let the tool open a browser:
  it would open the profile that is signed in as an administrator. Sign the robot out for good
  afterwards. Both keys go back into their envelopes on one line, both signatures.
- **PROVES:** The tool prints the granted scope list and a secret version number, and **nothing
  else** - no token, no code, no client secret. The scope list has exactly one entry and it is
  `https://www.googleapis.com/auth/admin.directory.user`.
  `gcloud secrets versions list steward-refresh-token --project="$DOER_PROJECT"` shows exactly one
  `ENABLED` version, and the service reads it per request rather than through `--set-secrets`.
- **UNDO:** Revoke from the Admin console: Directory > Users > `steward-robot@` > Security >
  Connected applications > remove; then disable the secret version; then delete the client.

**Write this into the record, in these words:** *"The consented scope, admin.directory.user, is
broader than the privilege. The privilege is the boundary: the account holds one custom role, Users
Read and Users Update Suspend, scoped to PILOT_OU, and Google enforces that scope on every call the
token makes. Google publishes no narrower write scope for the Directory users resource."* T2-24's
T2-24 N2b is the check that this is true and not merely believed.

**This is not domain-wide delegation and must never become it.** The robot consented for itself, at
a keyboard, with two people present; T2-21 proves its client id is absent from the delegation page.

### T2-18 Deploy `steward-actions`, the only credential holder

- **WHO:** A. **WHERE:** terminal, in `$HOME/agp-3day/doer/`.
- **DO:**

```bash
gcloud run deploy steward-actions --source=. --region="$REGION" --project="$DOER_PROJECT" \
  --no-allow-unauthenticated --ingress=all \
  --service-account="steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --set-env-vars="DOER_PROJECT=${DOER_PROJECT},ORG_DOMAIN=${ORG_DOMAIN},AGENT_ID=steward,PILOT_OU=${PILOT_OU},SYNTHETIC_PREFIX=pilot-user-,APPROVERS=${PERSON_B_EMAIL},LEVEL_CAP=2" \
  --timeout=60s --min-instances=0 --max-instances=2

penv STEWARD_ACTIONS_URL "$(gcloud run services describe steward-actions --region="$REGION" \
  --project="$DOER_PROJECT" --format='value(status.url)')"
gcloud run services update steward-actions --region="$REGION" --project="$DOER_PROJECT" \
  --update-env-vars="SERVICE_URL=${STEWARD_ACTIONS_URL}"
```

- **PROVES:** Ask the service what it thinks it is, and read every line of the answer:

```bash
curl -s -H "Authorization: Bearer $(gcloud auth print-identity-token --audiences="$STEWARD_ACTIONS_URL")" \
  "${STEWARD_ACTIONS_URL}/control/status" | python3 -m json.tool
curl -s -o /dev/null -w '%{http_code}\n' "${STEWARD_ACTIONS_URL}/control/status"   # no token: expect 403
gcloud run services describe steward-actions --region="$REGION" --project="$DOER_PROJECT" \
  --format='value(spec.template.spec.containers[0].env)' \
  | grep -Eio '[A-Za-z0-9_-]{24,}' | grep -v "$DOER_PROJECT" || echo "no secret-looking value in env"
```

  `/control/status` must print `"halt": "off"`, `"level_cap": 2`, the `pilot_ou` and
  `synthetic_prefix` you set, the audit table name, a catalogue of exactly `restore` and `suspend`,
  and `"approvers_configured": 1`. The unauthenticated call returns **403 from Cloud Run itself**,
  before the container is reached.

  **There is no `--set-secrets` here, and that is deliberate.** Neither the refresh token nor the
  halt is an environment variable. The service reads both from Secret Manager per request, so a
  halt written a second ago and a credential revoked a second ago both take effect on the very next
  request, on an instance that is already warm.
- **UNDO:** `gcloud run services delete steward-actions --region="$REGION" --project="$DOER_PROJECT"`.
  The credential is untouched by a delete.

### T2-19 `run.invoker` to named principals only

- **WHO:** A binds; B verifies from their own session. **WHERE:** terminal.
- **DO:**

```bash
for M in "user:${PERSON_A_EMAIL}" "user:${PERSON_B_EMAIL}"; do
  gcloud run services add-iam-policy-binding steward-actions --region="$REGION" \
    --project="$DOER_PROJECT" --member="$M" --role=roles/run.invoker
done

gcloud run services get-iam-policy steward-actions --region="$REGION" --project="$DOER_PROJECT" \
  --format=json | python3 -c '
import json,sys
b=[x for x in json.load(sys.stdin).get("bindings",[]) if x["role"]=="roles/run.invoker"]
m=sorted(sum([x["members"] for x in b],[]))
bad=[x for x in m if not x.startswith("user:")]
print("invokers:", m); print("BAD:", bad) if bad else print("invoker set clean: named humans only")
sys.exit(1 if bad or len(m)!=2 else 0)'
```

- **PROVES:** `invoker set clean: named humans only`, exactly two members, both `user:`. No
  `allUsers`, no `allAuthenticatedUsers`, no `domain:`, no `group:`, and **no service account**:
  nothing that is not a person in the room can reach the only thing that can act.
- **UNDO:** `gcloud run services remove-iam-policy-binding` per member. This is also K3's lever if
  you need one.

The full build binds service accounts behind an approval surface with Identity-Aware Proxy. There is
no surface today (C-18), so the two humans are named directly. That is the deviation, written down.

### T2-20 Deploy `steward-plan`, which holds nothing

- **WHO:** A. **WHERE:** terminal, in `$HOME/agp-3day/plan/`.
- **DO:**

```bash
gcloud projects add-iam-policy-binding "$DOER_PROJECT" \
  --member="serviceAccount:steward-plan@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --role=roles/aiplatform.user --condition=None

gcloud run jobs deploy steward-plan --source=. --region="$REGION" --project="$DOER_PROJECT" \
  --service-account="steward-plan@${DOER_PROJECT}.iam.gserviceaccount.com" \
  --set-env-vars="DOER_PROJECT=${DOER_PROJECT},MODEL_ID=gemini-2.5-flash,REGION=${REGION}" \
  --max-retries=0 --task-timeout=5m
```

- **PROVES:** Three negatives, all read back:

```bash
gcloud projects get-iam-policy "$DOER_PROJECT" --flatten="bindings[].members" \
  --filter="bindings.members:steward-plan@" --format='value(bindings.role)'   # expect only roles/aiplatform.user
gcloud secrets get-iam-policy steward-refresh-token --project="$DOER_PROJECT" --format=json | grep -q 'steward-plan@' \
  && echo "FAIL: plan holds the credential" || echo "plan holds no credential"
gcloud run services get-iam-policy steward-actions --region="$REGION" --project="$DOER_PROJECT" --format=json | grep -q 'steward-plan@' \
  && echo "FAIL: plan can invoke the action service" || echo "plan cannot invoke the action service"
```

  One role, no `secretAccessor`, no `run.invoker`. **The model holds no credential and cannot
  approve.** It produces text. A human reads the text and types the request.
- **UNDO:** `gcloud run jobs delete steward-plan --region="$REGION" --project="$DOER_PROJECT"`.

### T2-21 The delegation-absence proof, second half

- **WHO:** A reads; **B repeats it independently**. **WHERE:** Admin console, Manage Domain Wide
  Delegation.
- **DO:** Re-read the list. Search it for `STEWARD_OAUTH_CLIENT_ID` and for every unique id in
  `doer-sa-ids.tsv`, including the two service accounts created today. Compare the whole list with
  `dwd-before.txt`.
- **PROVES:** The client id is **absent**. Every service account unique id is absent. The list is
  byte-identical to `dwd-before.txt`. Both people sign the screenshot. Also re-run T2-5's
  `users.get`: `isAdmin` is still not `true`.
- **UNDO:** Read only.

---

## D2-C3, 14:45 to 16:00. The witnessed results

Both people, at one keyboard, for the whole block. Person A requests; person B approves and reads
every audit row. Six refusals and three executions, and they carry the same names as the eleven
lines `--selftest` printed this morning, so you can tell live behaviour from fake at a glance.

Run the T2-8 guard first. Then set up once, in each person's own shell:

```bash
TOK() { gcloud auth print-identity-token --audiences="$STEWARD_ACTIONS_URL"; }
POST() { curl -s -X POST -H "Authorization: Bearer $(TOK)" -H 'Content-Type: application/json' \
           "${STEWARD_ACTIONS_URL}$1" -d "$2" | python3 -m json.tool; }
ROWS() { bq query --project_id="$DOER_PROJECT" --use_legacy_sql=false --format=prettyjson \
  "SELECT ts, phase, verdict, denial_reason, dry_run, level, requester, approver, request_id
   FROM \`${DOER_PROJECT}.steward_audit.actions\`
   WHERE ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 MINUTE) ORDER BY ts"; }
GOOD="pilot-user-01@${ORG_DOMAIN}"
OUT="pilot-user-99@${ORG_DOMAIN}"       # the account person B put in NONPROD_OU at T2-15
```

Tokens are never echoed, never stored, never pasted into the run log. Person B reads the target
aloud before every single call, and no call is made while the room disagrees about what it is.

### T2-22 N5, N6, N3: the dry run is forced, and cannot be bought

- **WHO:** A runs every call; B issues the one real approval and reads every row.
- **DO:**

```bash
# N5  level 1 is a forced dry run. Person B issues a genuine, valid approval first.
#     person B's shell:
POST /approve '{"operation":"suspend","target":"'"$GOOD"'","level":1}'
#     person A's shell, carrying that nonce:
POST /act '{"operation":"suspend","target":"'"$GOOD"'","level":1,"approval":{"nonce":"<nonce>"}}'

# N6  self-approval. Person A asks for the approval from their own shell.
POST /approve '{"operation":"suspend","target":"'"$GOOD"'","level":2}'
POST /act '{"operation":"suspend","target":"'"$GOOD"'","level":2,"approval":{"nonce":"<that nonce>"}}'

# N3  a protected principal: person B's own account, which carries no synthetic prefix.
POST /act '{"operation":"suspend","target":"'"$PERSON_B_EMAIL"'","level":1}'
```

- **PROVES:**
  - **N5** returns `"verdict": "dry_run"`, `"executed": false`, and a `would_set` naming
    `suspended: true`. **A valid, unexpired, correctly bound approval did not buy an execution.**
    Confirm with `users.get` that `suspended` is still `false`; do not assume it. If the account was
    suspended, today stops and the build is unwound.
  - **N6** returns `"denial_reason": "self_approval"`. The approver's identity comes from the
    verified identity token, not from anything in the request body, so person A cannot assert it.
  - **N3** returns `"denial_reason": "protected_principal"`. Person B's account is refused because
    its local part does not start with `pilot-user-`. Nothing reached Google.
  - `ROWS` shows, for every one of the three, a `phase: intent` row with a **strictly earlier** `ts`
    than its `phase: outcome` row, sharing a `request_id`.
- **UNDO:** Nothing changed, by construction.

### T2-23 P1, P2, P3: the approved execution, and its inverse

- **WHO:** A requests; **B approves from their own shell**; both watch the clock. **WHERE:** two
  terminals. Re-run the T2-8 guard immediately before this step.
- **DO:** Follow T2-15's procedure exactly. No level is raised and nothing is redeployed: the level
  travels in the request, and `LEVEL_CAP=2` already permits it.

```bash
# person A, out loud: operation suspend, target pilot-user-01, level 2.
# person B's shell:
POST /approve '{"operation":"suspend","target":"'"$GOOD"'","level":2}'
# person A's shell:
POST /act '{"operation":"suspend","target":"'"$GOOD"'","level":2,"approval":{"nonce":"<nonce>"}}'
# then the inverse, on its own separate approval:
POST /approve '{"operation":"restore","target":"'"$GOOD"'","level":2}'     # person B
POST /act '{"operation":"restore","target":"'"$GOOD"'","level":2,"approval":{"nonce":"<nonce>"}}'
```

- **PROVES:**
  - **P1:** `"verdict": "executed"`, `"dry_run": false`, `approver` equals person B and differs from
    `requester`. `users.get` on the target shows `suspended: true` with a `suspensionReason`.
  - **P2:** in `ROWS`, the `phase: intent` row for that `request_id` has a strictly earlier `ts`
    than its `outcome` row. **The row was written before the call**, not after it.
  - **P3:** the inverse executes and `users.get` shows `suspended: false`. The account is back
    exactly where it started, on a second approval that person B issued separately.
  - The two nonces are used once each: re-posting either is refused. B writes both nonces, both
    times and their signature in the run log.
- **UNDO:** `restore` is the undo, and it is P3. If the service becomes unreachable between P1 and
  P3, undo by hand in the Admin console (Directory > Users > the account > Reactivate) before
  leaving the room, and record it as a deviation.

### T2-24 N2, N4, and the model

- **WHO:** A runs; B approves the one-minute change and watches the clock. **WHERE:** two terminals.
- **DO:**

```bash
# N2a  a synthetic target outside PILOT_OU: the service refuses before any call is made.
POST /act '{"operation":"suspend","target":"'"$OUT"'","level":1}'

# N2b  the service's own check stood down for one witnessed minute, so Google has to answer.
#      Person B approves this aloud and times it. The target is still a synthetic account.
gcloud run services update steward-actions --region="$REGION" --project="$DOER_PROJECT" \
  --update-env-vars="PILOT_OU=$(dirname "$PILOT_OU")"     # the parent OU: NONPROD_OU now in range
POST /approve '{"operation":"suspend","target":"'"$OUT"'","level":2}'      # person B
POST /act '{"operation":"suspend","target":"'"$OUT"'","level":2,"approval":{"nonce":"<nonce>"}}'
gcloud run services update steward-actions --region="$REGION" --project="$DOER_PROJECT" \
  --update-env-vars="PILOT_OU=${PILOT_OU}"                # put it back, before anything else runs

# N4  the audit write fails. Take the writer out of the dataset ACL, send one request, put it back.
bq --project_id="$DOER_PROJECT" update --source "$HOME/agp-3day/ds-nowriter.json" "${DOER_PROJECT}:steward_audit"
POST /act '{"operation":"suspend","target":"'"$GOOD"'","level":1}'
bq --project_id="$DOER_PROJECT" update --source "$HOME/agp-3day/ds-writer.json" "${DOER_PROJECT}:steward_audit"

# the model. It plans; it holds nothing.
gcloud run jobs execute steward-plan --region="$REGION" --project="$DOER_PROJECT" --wait \
  --update-env-vars="SENTENCE=the pilot account that left the company last week needs suspending"
gcloud run jobs executions logs read "$(gcloud run jobs executions list --job=steward-plan \
  --region="$REGION" --project="$DOER_PROJECT" --limit=1 --format='value(name)')" \
  --region="$REGION" --project="$DOER_PROJECT"
```

- **PROVES:**
  - **N2a:** `"denial_reason": "out_of_scope_ou"`. The service read the target's organisational unit
    and refused before the catalogue's write was ever attempted.
  - **N2b:** `"verdict": "denied"` with a `google_status` of 403. **Google refuses it, not only the
    service.** The OU-scoped role is a real boundary, not a convention, and it holds with the
    service's own check stood down and a valid two-person approval in hand. If this call
    **succeeds**, stop the day, unassign the role (T2-7's undo), reactivate `pilot-user-99@` and
    write it up: the scope is not what it appears to be and nothing else today is safe.
  - **N4:** HTTP 503 and `"denial_reason": "audit_unavailable"`. There is **no audit row**, which is
    the point, and no Google call was made. After the ACL is restored, the next request writes a row
    again. **No action runs when the audit write fails.**
  - **The model:** the job prints a JSON plan with `"level": 1` and `"carries_credential": false`.
    The plan is text. The log shows no Admin SDK call and no token. A human reads it and retypes the
    request; the job cannot call `/act` at all (T2-20 proved it holds no `run.invoker`).
- **UNDO:** Each part restores itself as its own last line. Verify all three before leaving:

```bash
bq show --format=prettyjson "${DOER_PROJECT}:steward_audit" | grep -q stewardAuditWriter && echo "writer back"
curl -s -H "Authorization: Bearer $(TOK)" "${STEWARD_ACTIONS_URL}/control/status" \
  | python3 -c 'import json,sys; print("pilot_ou:", json.load(sys.stdin)["pilot_ou"])'
```

  `pilot_ou` must equal `names.env` again, and `pilot-user-99@` must be reactivated in the Admin
  console if N2b unexpectedly succeeded.

**Why N2b stands the service's check down rather than forging a call from a laptop.** The action
service is the only credential holder, and it stays that way: handing a person the robot's refresh
token to make a call by hand would break the very absolute this day exists to demonstrate. Standing
down one environment variable for one witnessed minute, against a synthetic target, makes Google
answer the question without anyone else ever holding the credential.

**If the block is running out of time,** drop in this order: the model, then N4, then N2b. **Never
dropped: N5, N6, N3 and P1 with P2.** Those are the demonstration.

---

## D2-C4, 16:15 to 17:15. The kill drills

Both people. **Person B pulls both levers.** Person A times and writes.

### T2-25 K0: halt, pulled on a warm instance

- **WHO:** **B pulls it**; A times and reads the rows. **WHERE:** B's terminal, then A's.
- **DO:** Person A sends one dry-run request first, so an instance is warm and stays warm. Then,
  without warning person A of the exact second, person B pulls the halt through the service's own
  kill switch:

```bash
# person B. Timing starts when B decides, not when the command returns.
T0=$(date -u +%s)
curl -s -X POST -H "Authorization: Bearer $(TOK)" "${STEWARD_ACTIONS_URL}/control/halt" \
  -H 'Content-Type: application/json' -d '{}' | python3 -m json.tool
echo "halt accepted at +$(( $(date -u +%s) - T0 ))s"
```

  Person A immediately sends the next request against that **same warm instance**.
- **PROVES:** The halt response carries `"halt": "on"`, a secret version, and `pulled_by` equal to
  person B's address. The next request is `"verdict": "denied"`, `"denial_reason": "halted"`, with
  `halt_state: on` in its audit row. Record two numbers in the run log: seconds from B's decision to
  the endpoint accepting, and seconds from B's decision to A's refusal. The second is the one that
  matters. **It works on an instance that was already warm because the halt is read with
  `access_secret_version` on every request and is never an environment variable.**

  A service identity cannot pull it either: the endpoint refuses a caller it recognises as a machine
  with `halt_caller_not_human`. The kill switch is for people.
- **UNDO:** **Clearing a halt is out of band and takes two people.** There is no clear endpoint, on
  purpose: clearing raises autonomy, and no single person and no machine does that. Person A asks
  aloud, person B writes the value, both initial the line. Do it now, so T2-26 can run.

```bash
printf 'off' | gcloud secrets versions add steward-halt --data-file=- --project="$DOER_PROJECT"
gcloud secrets versions access latest --secret=steward-halt --project="$DOER_PROJECT"  # expect: off
```

### T2-26 K4: revoke the credential, measure the residue, re-consent in the same sitting

- **WHO:** **B revokes** as a super admin; A times and reads. **WHERE:** the Admin console, then two
  terminals.
- **DO:** Person B revokes the robot's grant: Admin console > Menu > Directory > Users >
  `steward-robot@` > Security > **Connected applications** > the `steward-2026-09-23` client >
  Remove. (The robot can equally revoke it for itself at myaccount.google.com under its own
  connected applications; the admin path is used here because it needs no security key.) Note the
  second of the removal. Then, from the same warm instance:

```bash
T0=$(date -u +%s)
for i in $(seq 1 10); do
  curl -s -X POST -H "Authorization: Bearer $(TOK)" -H 'Content-Type: application/json' \
    "${STEWARD_ACTIONS_URL}/act" -d '{"operation":"suspend","target":"'"$GOOD"'","level":1}' \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("verdict"), d.get("denial_reason",""), d.get("google_status",""))'
  echo "  t+$(( $(date -u +%s) - T0 ))s"; sleep 60
done
```

- **PROVES:** The requests fail with a credential error once the token the service holds stops
  working. Write the **measured residue** in the run log as a number of seconds, from the revocation
  to the first refusal. Then write this sentence, in these words: *"An access token already issued
  may stay valid for up to an hour after the grant is revoked. The measured residue today was N
  seconds. K0 is what stops work now; K4 stops the credential."* Do not claim 60 minutes as a fact,
  and do not claim the revoke was instant. Record what you measured, even if it was one second.
- **UNDO:** **IRREVERSIBLE: the credential is consumed.** Confirm before revoking: both people are
  present, both keys are in the room, and there are at least 30 minutes left. Then re-run **T2-16
  and T2-17 in this same sitting**: a new client, a new consent, one scope, a new secret version.
  Disable the old version afterwards:

```bash
gcloud secrets versions list steward-refresh-token --project="$DOER_PROJECT" \
  --format='table(name, state, createTime)'
gcloud secrets versions disable "<the old version number>" --secret=steward-refresh-token \
  --project="$DOER_PROJECT"
curl -s -H "Authorization: Bearer $(TOK)" "${STEWARD_ACTIONS_URL}/control/status" | python3 -m json.tool
```

  Prove the new credential works before you leave: one dry run at level 1 that returns `dry_run`
  rather than a credential error. **Day 3 needs a working credential.** If the clock beats you, stop
  the re-consent, and tell day 3 first thing: the demonstration then runs to the dry-run refusal and
  no further, and the hand-over says the executed pair was not repeated in front of a sponsor.

### T2-27 Close the day

- **WHO:** Both. **WHERE:** the run log.
- **DO:** Write the day's record: every step id marked `done` or `deviation`, both signatures, the
  K0 seconds, the K4 residue, and any result that was dropped for time, named as dropped. Then leave
  the machinery in the state day 3 opens on:

```bash
curl -s -H "Authorization: Bearer $(TOK)" "${STEWARD_ACTIONS_URL}/control/status" | python3 -m json.tool
bq query --project_id="$DOER_PROJECT" --use_legacy_sql=false --format=csv \
  "SELECT verdict, denial_reason, COUNT(*) n
   FROM \`${DOER_PROJECT}.steward_audit.actions\`
   WHERE phase='outcome' AND DATE(ts)=CURRENT_DATE() GROUP BY 1,2 ORDER BY n DESC"
```

- **PROVES:** `/control/status` shows `"halt": "off"`, `"level_cap": 2`, `pilot_ou` equal to
  `names.env`, and a catalogue of exactly two operations. The query is today's whole story on one
  screen, and person B reads it against the run log line by line: every denial reason there was
  produced on purpose, by a named step, and there are no others.
- **UNDO:** Not applicable.

---

## Before you stop

Every line must be true, and person B ticks it, not person A.

- [ ] `steward-robot@` sits in `SERVICE_IDENTITY_OU`, holds a security key with **no code
      fallback**, has no recovery email and no recovery phone, and is refused by the Admin console.
- [ ] `roleAssignments.list` for the robot returns **exactly one** item, `scopeType: ORG_UNIT`,
      `orgUnitId` = `PILOT_OU`. `isAdmin` is not true.
- [ ] Manage Domain Wide Delegation is unchanged from `dwd-before.txt`, and the doer's client id and
      every service account unique id are absent from it. Both people signed both halves.
- [ ] `PILOT_OU` holds exactly four accounts, all `pilot-user-NN@`, none an administrator, and
      `pilot-user-01@` is **not suspended** (P3 restored it).
- [ ] `steward_audit.actions` holds, for today, at least one `phase: intent` row whose `ts` is
      strictly earlier than its matching `phase: outcome` row.
- [ ] N5, N6, N3, P1, P2 and P3 all happened and all produced the verdicts above. Anything dropped is
      named in the run log as dropped, not described as passed.
- [ ] `steward-plan@` holds `roles/aiplatform.user` and nothing else: no `secretAccessor`, no
      `run.invoker`.
- [ ] The deployed `PILOT_OU` equals the value in `names.env` (N2b put it back), the dataset ACL
      lists the writer again (N4 put it back), and `pilot-user-99@` is not suspended.
- [ ] `run.invoker` on `steward-actions` names exactly two `user:` principals and nothing else.
- [ ] The `staging` organisational unit is empty (the robot moved out at T2-4) and is on day 3's
      unwind list.
- [ ] `/control/status` reads `"halt": "off"` and `"level_cap": 2`; `steward-refresh-token` has
      exactly one `ENABLED` version, and it is the one the consent sitting created.
- [ ] The run log carries: two key-custody lines, person B's written role approval, both
      approval nonces, the K0 seconds, the K4 residue in seconds, and both signatures.

---

## If the day overran

The cut order across the three days is Mo's scorecard, then the retrospective baseline, then the
improvement pull request. **Never cut: Eve live before the doer exists; the forced dry run; the
two-person approval; the write-ahead audit; the kill drills; the same-day unwind.**

| What failed | What to do |
|---|---|
| The role assignment has not propagated by 14:45 (P1 fails with a Google permission error) | Do not widen the role and do not assign a second one. Run N5, N6, N3, N2 and N4, none of which needs a successful write. Move P1, P2 and P3 to day 3, 09:00. If it fails again on day 3, **strike the executed pair from the claim**, do not soften it: the hand-over says the privileged tier was not exercised. |
| The consent fails (the Desktop client is blocked, or the security-key sign-in will not complete in the browser) | The client was marked Trusted at T2-16; check that first. Then try `gcloud auth application-default login --client-id-file --scopes=https://www.googleapis.com/auth/admin.directory.user` from the robot's own browser profile and pipe the refresh token into Secret Manager by hand. Last resort: the day ends at T2-12's `--selftest`, every result is demonstrated offline against a fake Directory client, and day 3's demonstration shows the policy chain without a live Google call. Say so to the sponsor in the first minute. |
| `gcloud run deploy --source` fails on Cloud Build or Artifact Registry | Day 1 already deployed the poller this way, so the path is known good; read the build log for the missing permission. Fallback: `gcloud builds submit --tag` then deploy with `--image`. |
| D2-C3 overruns | Drop the model, then N4, then N2b. Never N5, N6, N3 or P1 with P2. |
| The halt does not stop the next request | This is a stop-the-build defect, not a timing problem. Check that the service reads the halt with `access_secret_version` per request and that it is **not** in `--set-secrets`. Do not proceed to day 3 with a kill switch that does not kill. |
| One or both people are pulled into other work | The 90 minutes of daily slack is the buffer and it is reserved. If more than 90 minutes is lost, move D2-C4 to day 3 morning and tell the sponsor the demonstration is 45 minutes later. |

---

## What day 3 needs from today

- `steward_audit.actions` with real rows from every result of D2-C3, each keyed on `agent_id` = `steward`:
  that is what Mo's five views count and group by.
- The `approvals` table with today's nonces and their `created_at`: that is Mo's approval-latency join, and it
  justifies the one improvement day 3 proposes as a pull request.
- A working credential, `LEVEL_CAP=2`, the halt `off`, and four unsuspended synthetic accounts
  ready for one more suspend-and-restore in front of a sponsor.
- The unwind list day 3 executes the same day: the standing IAM grants, the **Pilot Steward (3-day)**
  assignment and then the role, the robot's OAuth grant and its secret version, the synthetic
  accounts.

## How this grows

| Built today, compressed | Where it goes next |
|---|---|
| The robot, the keys, the OU move | [pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) PW-1.3, PW-1.4; then [setup/30](../setup/30-wall-e-workspace-side.md) |
| The custom role and its OU-scoped assignment | [pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) PW-7.3, PW-7.4 (two roles, reader and writer) |
| The delegation-absence proof | [pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) PW-1.6 and PW-8.1 |
| One consent, one scope | [pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) §3; [setup/32](../setup/32-wall-e-consents.md) |
| The audit table, one writer | [pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) PW-2.4 to PW-2.6 (nine tables, Firestore, restore drill) |
| The catalogue of one pair, the level in an environment variable | [pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) PW-4.2 (a ladder file with a code owner) and PW-6.2 (the dwell) |
| The approval by a shouted hash | [pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) PW-4.5 (a surface behind Identity-Aware Proxy) |
| K0 and K4 | [pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) PW-6.3 to PW-6.5 (K1, K2, K3, K7 as well) |

---

## Sources checked on 2026-09-17

- [Administrator privilege definitions](https://knowledge.workspace.google.com/admin/users/administrator-privilege-definitions): Users tree Create, Read, Update (Move users, Suspend users, Rename users, Reset password, Force password change, Add/remove aliases), Delete; Users privileges can be limited to organisational units; Groups actions "can't be limited to specific organizational units".
- [Assign specific admin roles](https://knowledge.workspace.google.com/admin/users/assign-specific-admin-roles): Menu > Account > Admin roles > the role > Assign admin; "next to All organizational units, click Edit, select the organizational units, and click Done"; "If you don't see Edit, you cannot apply the role to organizational units"; "Changes can take up to 24 hours but typically happen more quickly".
- [Create, edit and delete custom admin roles](https://knowledge.workspace.google.com/admin/users/create-edit-and-delete-custom-admin-roles): Menu > Account > Admin roles > Create new role; delete via the role > Delete Role. The page states no propagation time.
- [Directory API RoleAssignment](https://developers.google.com/workspace/admin/directory/reference/rest/v1/roleAssignments): fields `roleAssignmentId`, `roleId`, `assignedTo`, `assigneeType`, `scopeType`, `orgUnitId`, `condition`; `scopeType` is `CUSTOMER` or `ORG_UNIT`; `orgUnitId` is "the ID for the organization unit the exercise of this role is restricted to".
- [Directory API roleAssignments.list](https://developers.google.com/workspace/admin/directory/reference/rest/v1/roleAssignments/list): `userKey`, `roleId`, `customer` (with the `my_customer` alias), `maxResults`, `pageToken`, `includeIndirectRoleAssignments`.
- [Directory API users.update](https://developers.google.com/workspace/admin/directory/reference/rest/v1/users/update): `PUT https://admin.googleapis.com/admin/directory/v1/users/{userKey}`; `userKey` is the primary email, an alias or the unique id.
- [Directory API User resource](https://developers.google.com/workspace/admin/directory/reference/rest/v1/users): `suspended` "Indicates if user is suspended"; `suspensionReason` is output only and "returned only if the suspended property is true"; `isAdmin` is output only and changeable only through `makeAdmin`.
- [Search for users](https://developers.google.com/workspace/admin/directory/v1/guides/search-users): `orgUnitPath=` with the full OU path, requiring `viewType=admin_view`; `isAdmin=` takes `true` or `false`; clauses separated by spaces are ANDed; the query must be URL-encoded.
- [Control API access with domain-wide delegation](https://knowledge.workspace.google.com/admin/apps/control-api-access-with-domain-wide-delegation): Menu > Security > Access and data control > API controls > Manage Domain Wide Delegation; "You must be signed in as a super administrator for this task"; the page documents no API that lists delegation clients.
- [Control which third-party and internal apps access Google Workspace data](https://knowledge.workspace.google.com/admin/apps/control-which-third-party-and-internal-apps-access-google-workspace-data): Menu > Security > Access and data control > API controls > App access control > Manage Third-Party App Access; configure by OAuth App Name or Client ID, then Trusted or Blocked, then Configure; "A trusted app has access to all Google Workspace services (OAuth scopes), including restricted services".
- [Deploy 2-Step Verification](https://knowledge.workspace.google.com/admin/security/deploy-2-step-verification): Menu > Security > Authentication > 2-step verification; "Only security key - Users must set up a security key"; "New user enrollment period"; "Allow user to trust the device" under Frequency.
- [Manage OAuth Clients](https://support.google.com/cloud/answer/15549257): Menu > Google Auth Platform > Clients; Application type > Desktop app; "The console does not require any additional information to create OAuth 2.0 credentials for desktop applications". Audience Internal limits authorisation to members of the organisation.
- [Using OAuth 2.0 for web server applications](https://developers.google.com/identity/protocols/oauth2/web-server): revocation is `POST https://oauth2.googleapis.com/revoke` with the `token` parameter and content type `application/x-www-form-urlencoded`.
- [Use secrets with Cloud Run](https://docs.cloud.google.com/run/docs/configuring/services/secrets): "Environment variables are resolved at instance startup time, so ... pin the secret to a particular version instead of using latest"; a mounted volume "always fetches the secret value from the Secret Manager to use the value with the latest version".
- gcloud reference pages, all read 2026-09-17: [run deploy](https://docs.cloud.google.com/sdk/gcloud/reference/run/deploy) (`--source`, `--image`, `--region`, `--project`, `--service-account`, `--no-allow-unauthenticated`, `--ingress`, `--set-env-vars`, `--set-secrets` with values "in the form SECRET_NAME:SECRET_VERSION", `--timeout`, `--max-instances`); [run jobs deploy](https://docs.cloud.google.com/sdk/gcloud/reference/run/jobs/deploy) (same plus `--max-retries`, `--task-timeout`; **no `--schedule` flag**, scheduling is a separate Cloud Scheduler job); [run services add-iam-policy-binding](https://docs.cloud.google.com/sdk/gcloud/reference/run/services/add-iam-policy-binding) (`SERVICE --member --role --region [--project]`); [secrets versions add](https://docs.cloud.google.com/sdk/gcloud/reference/secrets/versions/add) ("Set this to \"-\" to read the secret data from stdin"); [secrets versions disable](https://docs.cloud.google.com/sdk/gcloud/reference/secrets/versions/disable) (`VERSION --secret [--location] [--project]`); [iam roles create](https://docs.cloud.google.com/sdk/gcloud/reference/iam/roles/create) (`ROLE_ID --project --title --permissions --stage`).

## Unsettled on 2026-09-17, and the step that fails loudly

| Item | Why it matters | The step that settles it |
|---|---|---|
| Whether an `ORG_UNIT`-scoped role really stops a write on an account outside `PILOT_OU` | The whole boundary rests on it: the consented scope is tenant-wide, the role is not | T2-24 N2b must be refused by Google with 403. A success stops the day and the assignment is removed. |
| The exact Google Auth Platform page layout for a Desktop client with an Internal audience | T2-16 is on the critical path for the consent | T2-16 fails loudly if Internal is not offered; do not fall back to External. |
| Whether the tenant's app access control blocks a newly created internal Desktop client by default | A blocked client makes the consent fail with an unhelpful error | T2-16 marks the client Trusted before it is used; T2-17 fails at the consent screen if it did not take. |
| The maximum lifetime of an already-issued Google access token | K4's claim | T2-26 measures the residue and records the measured number, never the design's figure. |
| The URL encoding of an OU path in a `users.list` query | T2-8's guard could silently read the whole tenant | T2-8 asserts `count=4`; any other count stops the day at that line. |
| Whether `bq update` accepts a reader entry naming a service account that does not exist yet | T2-10's `mo-metrics@` line | The first run: if it is refused, drop the line and add it on day 3. |

---

**What today does not prove.** No agent held a super admin role, so nothing here says anything about
super-admin containment. Nothing ran unattended: no dwell, no ladder walked, no grading. Four
synthetic accounts are the whole population, so no human minute was saved and none is claimed. There
is no witness organisation, no security information and event management contract, no 24x7
acknowledgement, no penetration test. This is a demonstration of machinery under control. It is not
compliance evidence and it is not a production grant.
