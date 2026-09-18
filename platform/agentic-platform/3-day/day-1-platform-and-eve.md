# Day 1. The platform and Eve

## Status

- Part of the three-day build. Entry point: [README.md](README.md). Next:
  [day-2-the-doer.md](day-2-the-doer.md), then
  [day-3-mo-demonstration-and-handover.md](day-3-mo-demonstration-and-handover.md). All code is in
  [code.md](code.md) and is pasted, not written.
- Date: 2026-09-22. Step prefix `T1`, steps T1-1 to T1-24, plus the five added on 2026-09-18 as
  suffixed steps rather than by renumbering: T1-9a, T1-12a, T1-14a, T1-16a and T1-19a.
- Last reviewed: 2026-09-18. Corrected on 2026-09-18 against [README.md](README.md) §6.1: the
  doer's foundation (audit dataset, two tables, two service accounts, three secrets, OAuth client
  marked Trusted) is built today; Eve's three tables match the code that writes them and
  `eve.watchlists` is seeded; the detections view exists before the first poll and the schedule is
  created last; `eve-reader@` registers its keys in a staging organisational unit and is moved
  afterwards; person B's alert path is built in the morning; the seeded test starts at 15:45.
- **The one ordering rule of the whole design: Eve is live before the doer exists.** Day 1 ends with
  a watcher that has seen and reported a real administrative action. **No doer account, no doer
  role assignment and no doer credential is created today.** The doer's *ground* is built today
  (a dataset with no writer that can act, two service accounts that can call nothing, three
  secrets of which only the halt has a value, an OAuth client nobody has consented to); the doer
  itself does not exist until day 2.
- Every command, flag, scope, privilege and console path below was read from Google's documentation
  on 2026-09-17, or on 2026-09-18 where a step says so; the pages are listed in §Sources. Re-read
  anything the shell refuses.
- `Assumption:` marks every estimate and every value the team must replace.

## The day

Working day 08:30 to 17:30, 90 minutes for lunch: **450 usable minutes** per person. The blocks
below allocate **375 minutes** to each person, leaving **75 minutes** of reserve, which is the
gaps between blocks and the end of the day. Not optimistic: the reserve is spent on overruns, not
planned into.

| Time | Person A | Person B |
|---|---|---|
| 08:30 to 10:00 (90) | D1-A1. Four projects, billing, APIs, labels, budgets, liens (T1-1 to T1-4) | D1-B1. `eve-reader@` created in staging, two keys, moved into the service-identity OU, the read-only role, the delegation list (T1-5 to T1-8) |
| 10:15 to 11:45 (90) | D1-A2. Datasets and the six tables, `eve.watchlists` seeded, Model Armor floor, Artifact Registry, Eve's two service accounts, **the doer's foundation** (T1-9, T1-9a, T1-10 to T1-12, T1-12a) | D1-B2. Eve's OAuth client and Trusted marking, **the doer's OAuth client and Trusted marking**, the empty secret, the pilot OU and its synthetic accounts, the unassigned doer role, **the notification channel and the two log-based metrics** (T1-13, T1-14, T1-14a, T1-15, T1-16, T1-16a) |
| 11:45 to 13:15 | Break | Break |
| 13:15 to 14:15 (60) | D1-C1. The consent sitting, both present (T1-17, T1-18) | D1-C1. The consent sitting, both present |
| 14:15 to 15:30 (75) | D1-A3. Poller deployed, the detections view, one poll by hand, first rows, the schedule created last (T1-19, T1-19a, T1-20, T1-21) | D1-B3. The finding policy, which needs no data; then the absence policy, once A's first rows exist (T1-22, T1-23) |
| 15:45 to 16:45 (60) | D1-C2. The seeded test; person A seeds and then stays silent (T1-24) | D1-C2. The seeded test; person B alone confirms |
| Reserve | 75 minutes: 10:00, 14:15 has none, 15:30, and 16:45 to 17:30 | the same |

Why 15:45 for the seeded test: the chain's tail (Admin log lag of "a couple of minutes", one
scheduler tick of up to 15, one alerting alignment period of 5, mail delivery) is 35 to 45 minutes
when it works correctly, and `T1-24`'s stop rule is 45 minutes. Starting at 16:00 against a 17:30
close left no room to work the chain after a miss; starting at 15:45 leaves an hour.

Person A builds. Person B approves, witnesses and receives every report. Person A never verifies
their own work.

## Before 08:30

- [ ] Both people are Google Workspace super admins and can create Google Cloud projects on a
      billing account they may attach. Note the billing account id. **Whoever runs T1-4 holds
      Billing Account Administrator or Billing Account Costs Manager on it**: Google's budgets page
      names those two roles for creating a budget (read 2026-09-18), and Billing Account User is
      not enough.
- [ ] `gcloud auth print-identity-token --audiences=https://example-00000.run.app` prints a token
      on **both** people's accounts, run once the week before ([README.md](README.md) §6 row 12).
      Every live call to the action service on day 2 depends on it.
- [ ] `gcloud` 500.0.0 or later with the `alpha` and `beta` components, `bq`, `python3.12`, `jq`,
      `git`. `gcloud components list --only-local-state --format='value(id)'` shows `alpha` and
      `beta`.
- [ ] Two hardware security keys per robot account, in hand. Day 2 needs two more.
- [ ] A browser profile signed in to nothing, for the robot sittings.
- [ ] Person B's own individual mailbox is reachable; it is the only alert destination today.
- [ ] A sponsor is named in writing today, because a finding whose subject is person B goes to the
      sponsor and to nobody else (cut C-19).
- [ ] [code.md](code.md) is open in VS Code. Nothing below asks anyone to design code.

---

## D1-A1 08:30 to 10:00. The four projects

### T1-1 The one variables file, and a shell with no default project

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** Three days get one variables file and one run log, and nothing else (cut C-15). No
  value below is a secret, so the file is committed. A gcloud configuration with no default project
  is what makes `--project` on every command a habit rather than a slogan.

```bash
mkdir -p "$HOME/agp-3day/records" "$HOME/agp-3day/tools" && cd "$HOME/agp-3day"
git init -b main . >/dev/null
cat > names.env <<'EOF'
# names.env. Holds no secret. Every value below is chosen once, on day 1, and never edited after.
# Values learned later (a client id, a service URL, a role id) are APPENDED with penv, never typed.
export ORG_DOMAIN="example.com"                      # Assumption: replace with the tenant domain
export CUSTOMER_ID="my_customer"
export BILLING_ACCOUNT_ID="000000-000000-000000"     # Assumption: replace
export SUFFIX="d3"   # keeps the ids unique; 4 characters at most, so every id stays inside
                     # Google's 30, and the ids keep the form 02 section 3.6 fixes:
                     # agp-<tier code>-<agent>-<env>, tier codes core, ctl, imp, p.
                     # A project id is never reusable, and a project never moves between
                     # tier folders, so an id spent in another form can never be adopted
                     # by the factory later. Check before creating anything:
                     # for v in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do
                     #   printf '%s\n' "$v" | grep -Eqx 'agp-(core|ctl|imp|p)-[a-z0-9-]*[a-z0-9]' && [ ${#v} -le 30 ] && echo "form ok $v" || echo "FORM $v"; done
export CORE_PROJECT="agp-core-${SUFFIX}"
export EVE_PROJECT="agp-ctl-eve-prod-${SUFFIX}"
export DOER_PROJECT="agp-p-steward-prod-${SUFFIX}"             # not "walle": the name is earned, not assumed
export MO_PROJECT="agp-imp-mo-prod-${SUFFIX}"
export REGION="europe-west1"
export BQ_LOCATION="EU"
export SERVICE_IDENTITY_OU="/service-identities"
export STAGING_OU="/staging"                         # keys are registered here, then the account is moved
export PILOT_OU="/pilot"                             # absolute 7: exact path, never widened, one spelling
export NONPROD_OU="/nonprod"
export SYNTHETIC_PREFIX="pilot-user-"                # absolute 7: what T1-16 creates, one spelling
export EVE_READER="eve-reader@${ORG_DOMAIN}"
export DOER_ROBOT="steward-robot@${ORG_DOMAIN}"      # named today, created on day 2 (T2-2)
export PERSON_A_EMAIL="a@${ORG_DOMAIN}"              # Assumption: replace with the builder's address
export PERSON_B_EMAIL="b@${ORG_DOMAIN}"              # Assumption: replace with the approver's address
export SPONSOR_EMAIL="sponsor@${ORG_DOMAIN}"         # Assumption: replace
export AGENT_ID="steward"
export RUN_LOG="$HOME/agp-3day/run-log.md"
EOF
cat > tools/penv.sh <<'EOF'
# penv NAME VALUE: append or replace one export line in names.env, and export it in this shell.
# Portable (no sed -i). The value is never a secret: names, ids and URLs only.
penv() {
  local f="$HOME/agp-3day/names.env" k="$1" v="$2"
  case "$v" in *token*|*secret*|*password*) echo "STOP: penv refuses a secret-looking value"; return 1;; esac
  if grep -q "^export ${k}=" "$f"; then
    python3 - "$f" "$k" "$v" <<'PY'
import re, sys
f, k, v = sys.argv[1:]
s = open(f).read()
s = re.sub(r'(?m)^export %s=.*$' % re.escape(k), 'export %s="%s"' % (k, v), s)
open(f, "w").write(s)
PY
  else
    printf 'export %s="%s"\n' "$k" "$v" >> "$f"
  fi
  export "${k}=${v}"
}
EOF
set -a; . ./names.env; set +a; . ./tools/penv.sh
[ "$PERSON_A_EMAIL" != "$PERSON_B_EMAIL" ] && echo "two people, two addresses" || echo "STOP: one address"
gcloud config configurations create agp3 --activate
gcloud config unset project
printf '# Run log, three-day build\n\n| UTC | step | who | what |\n|---|---|---|---|\n' > "$RUN_LOG"
git add names.env tools/penv.sh run-log.md && git commit -qm "T1-1 names, penv and run log"
```

- **VERIFY:** `gcloud config get-value project` prints `(unset)`. `grep -c '^export ' names.env`
  prints `22`. No line of `names.env` contains `token`, `secret` or `password`. `two people, two
  addresses` was printed.
- **Every later shell opens with** `set -a; . "$HOME/agp-3day/names.env"; set +a;
  . "$HOME/agp-3day/tools/penv.sh"`. Day 2 and day 3 read these names and no others; a name that
  is not in this file is not a name.
- **ROLLBACK:** `gcloud config configurations delete agp3`; `rm -rf "$HOME/agp-3day"`.
- **RECORD:** `names.env` committed; one run-log line.

### T1-2 Create the four projects and link billing

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** One purpose each: `CORE_PROJECT` evidence, `EVE_PROJECT` the watcher, `DOER_PROJECT`
  tomorrow's action service, `MO_PROJECT` the measurement. Nothing goes inside `DOER_PROJECT` today.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
for P in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do
  gcloud projects create "$P" --name="$P" --no-enable-cloud-apis
  gcloud billing projects link "$P" --billing-account="$BILLING_ACCOUNT_ID"
done
gcloud projects list --filter="projectId:agp-*-${SUFFIX}" --format='table(projectId,lifecycleState)'
```

- **VERIFY:** Four rows, all `ACTIVE`. `gcloud billing projects describe "$EVE_PROJECT"
  --format='value(billingEnabled)'` prints `True` for each of the four.
- **ROLLBACK:** `gcloud projects delete "$P"` before T1-4 puts a lien on it. After the lien, remove
  the lien first.
- **RECORD:** The table output, pasted into the run log.

### T1-3 Enable the API set and label each project

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** Each project gets only what it needs. `aiplatform.googleapis.com` is deliberately
  absent from `EVE_PROJECT`: the watcher never calls a model.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
COMMON="logging.googleapis.com monitoring.googleapis.com bigquery.googleapis.com secretmanager.googleapis.com"
gcloud services enable $COMMON run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com modelarmor.googleapis.com aiplatform.googleapis.com billingbudgets.googleapis.com --project="$CORE_PROJECT"
gcloud services enable $COMMON run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com cloudscheduler.googleapis.com admin.googleapis.com --project="$EVE_PROJECT"
gcloud services enable $COMMON run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com admin.googleapis.com modelarmor.googleapis.com aiplatform.googleapis.com --project="$DOER_PROJECT"
gcloud services enable $COMMON --project="$MO_PROJECT"
for P in "$CORE_PROJECT:core" "$EVE_PROJECT:controller" "$DOER_PROJECT:doer" "$MO_PROJECT:improver"; do
  gcloud projects update "${P%%:*}" --update-labels="programme=agp-3day,role=${P##*:},population=synthetic,ai_act_class=not_ai_system"
done
gcloud services list --enabled --project="$EVE_PROJECT" --format='value(config.name)' | grep -x aiplatform.googleapis.com && echo "STOP: the watcher can call a model" || echo "aiplatform absent from EVE_PROJECT, as required"
```

- **VERIFY:** The last line prints `aiplatform absent from EVE_PROJECT, as required`.
  `gcloud projects describe "$DOER_PROJECT" --format='value(labels)'` shows the four labels. Label
  values may hold only lowercase letters, digits, underscores and dashes.
  `billingbudgets.googleapis.com` is on `CORE_PROJECT` because T1-4 passes
  `--billing-project="$CORE_PROJECT"` and the Cloud Billing Budget API is enabled with
  `gcloud services enable billingbudgets.googleapis.com` (Google's Budget API setup page, read
  2026-09-18).
- **ROLLBACK:** `gcloud services disable <api> --project=<project>`;
  `gcloud projects update <project> --remove-labels=programme,role,population,ai_act_class`.
- **RECORD:** The enabled-services list per project, saved under `records/`.

### T1-4 A budget and a deletion lien on each project

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** The budget is a smoke alarm, not a control. The lien is what stops a tired hand at
  17:00 on day 3 deleting the project that holds the evidence.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
for P in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do
  gcloud billing budgets create --billing-account="$BILLING_ACCOUNT_ID" --display-name="agp-3day ${P}" \
    --budget-amount=50EUR --calendar-period=month --filter-projects="projects/${P}" \
    --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0 \
    --billing-project="$CORE_PROJECT"
  gcloud alpha resource-manager liens create --project="$P" \
    --restrictions=resourcemanager.projects.delete \
    --reason="agp-3day evidence; removed only by the hand-over of day 3" --origin="agp-3day" \
  || gcloud resource-manager liens create --project="$P" \
    --restrictions=resourcemanager.projects.delete \
    --reason="agp-3day evidence; removed only by the hand-over of day 3" --origin="agp-3day" \
  || { echo "STOP: no liens command on this gcloud; do not proceed without a lien"; break; }
done
for P in "$CORE_PROJECT" "$EVE_PROJECT" "$DOER_PROJECT" "$MO_PROJECT"; do gcloud alpha resource-manager liens list --project="$P" --format='value(name,restrictions)'; done
```

- **VERIFY:** Four lien rows, each carrying `resourcemanager.projects.delete`. Four budgets:
  `gcloud billing budgets list --billing-account="$BILLING_ACCOUNT_ID" --format='value(displayName)'`
  prints four `agp-3day` rows. `Assumption:` 50 EUR a month per project is ample for three days;
  the budget exists to notice a mistake, not to cap. If `budgets create` is refused with a
  permission error, the account running it holds Billing Account User only; creating a budget
  needs Billing Account Administrator or Billing Account Costs Manager (Google's budgets page, read
  2026-09-18), which is what the pre-flight checked.
- **Unsettled:** `liens create` is documented only under `gcloud alpha` (read 2026-09-17). The
  fallback line tries the general-availability spelling, and the step **stops loudly** if neither
  works rather than leaving a project unprotected.
- **ROLLBACK:** `gcloud alpha resource-manager liens delete <lien>`;
  `gcloud billing budgets delete <budget> --billing-account="$BILLING_ACCOUNT_ID"`.
- **RECORD:** The lien list.

---

## D1-B1 08:30 to 10:00. The watcher's account

### T1-5 The service-identity and staging organisational units, and two-step verification

- **WHO:** Person B. **WHERE:** Admin console.
- **ACTION:** Directory > Organisational units > Create organisational unit, twice, both with the
  top-level organisation as parent: `service-identities` and `staging`. Leave `staging`'s 2-step
  verification at **Inherit**. Then Security > Authentication > 2-step verification, select the
  `service-identities` organisational unit in the left panel, set **Enforcement** to **On**,
  **New user enrolment period** to **None**, and **Methods** to **Only security key** (the three
  documented values are "Any", "Any except verification codes via text, phone call" and "Only
  security key"; read 2026-09-17).
- **Why two units:** `service-identities` forces a security key at sign-in with no enrolment
  period, so an account created directly in it can never sign in for the first time to register
  the key it is required to present. Each robot is therefore created in `staging`, registers its
  keys there, and is moved (T1-6 for `eve-reader@`; day-2 T2-2 and T2-4 for the doer). `staging`
  is empty at every other moment and is deleted in the day-3 unwind.
- **VERIFY:** The 2-step verification page, with `service-identities` selected, shows enforcement On
  and method Only security key, and the setting is marked as locally overridden, not inherited.
  With `staging` selected it shows Inherited. Screenshot both.
- **ROLLBACK:** Set the organisational unit back to Inherit, then delete each organisational unit
  once it is empty.
- **RECORD:** `records/T1-5-service-identity-ou.png`, `records/T1-5-staging-ou.png`.

### T1-6 Create `eve-reader@` in staging, two keys, move it, no recovery channel

- **WHO:** Person B creates; person A witnesses the key count by eye and signs.
  **WHERE:** Admin console, then the clean browser profile.
- **ACTION:** Mirrors day-2 T2-2 to T2-4 exactly, one day earlier.
  1. Directory > Users > Add new user. Name the account `eve-reader`, put it in the **`staging`**
     organisational unit, generate a password, print nothing. Leave "Ask for a password change at
     the next sign-in" **off**: the password that is generated now is the one that is sealed, and
     it is **never changed afterwards**, so the envelope always holds a password that works.
     Write it into an envelope, seal it, both sign across the seal, and person B keeps it.
  2. Sign in once in the clean browser profile with that password and register **two** security
     keys at myaccount.google.com > Security > 2-Step Verification > Security key.
  3. Then, in the Admin console, `eve-reader@` > Security: remove any recovery email and recovery
     phone, and leave both blank.
  4. Move the account: `eve-reader@` > More options > Change organisational unit >
     `service-identities`. Sign it out everywhere, sign in again in the clean profile, and confirm
     the sign-in **demands a security key and offers no code fallback**.
- **VERIFY:** The user's page shows the organisational unit `service-identities`, 2-Step
  Verification **Enrolled**, and two security keys listed. Recovery email and recovery phone are
  empty. `staging` is empty again. Person A writes in the run log: "counted two keys by eye at
  `<UTC time>`", and person B writes: "eve-reader password sealed, unchanged since generation;
  envelope held by person B", and both sign.
- **Custody, plainly:** the account has no recovery channel on purpose. Its two keys and its sealed
  password are the only ways in. Losing all three loses the account the ordering rule depends on,
  so the envelope goes into the day-3 unwind (T3-19) with a destroy-or-retain decision that is
  read back and signed, and is never thrown away by one person alone.
- **ROLLBACK:** Suspend, then delete the user. Deleting a user is **IRREVERSIBLE** after 20 days;
  suspend first and delete only during the day-3 unwind.
- **RECORD:** `records/T1-6-eve-reader.png`; the two run-log lines.

### T1-7 One read-only custom admin role, assigned to `eve-reader@`

- **WHO:** Person B creates and assigns; person A reads the privilege list on screen before Save.
  **WHERE:** Admin console: Menu > Account > Admin roles > Create new role.
- **ACTION:** Name the role `Eve Reader (3-day)`. Tick, under **Admin console privileges**, only:

  | Privilege | Why |
  |---|---|
  | Reports | The Admin SDK Reports API refuses every call without it |

  Tick nothing else: **one privilege**. Not Users > Read (dropped on 2026-09-18: `activities.list`
  does not need it, and at customer scope it would read every real employee's directory record for
  an account that is left standing after the run, [README.md](README.md) §10 row 11), not Users >
  Update, Groups, Security settings, Services, or any Admin API privilege. Person B confirms the
  account's own state from their own super-admin session, not through this role. Assign the role
  to `eve-reader@` at **All organizational units** (customer scope), because the Reports privilege
  is one of those that "can't be limited to specific organizational units" (privilege
  definitions, read 2026-09-17), so pretending to scope it would be theatre.
- **VERIFY:** The role's page lists exactly one privilege. `eve-reader@`'s page, under Admin roles
  and privileges, shows `Eve Reader (3-day)` and **not** Super Admin. Person A states aloud the one
  privilege they read before Save, and person B writes that sentence in the run log.
- **Timing:** Google states that a role change "can take up to 24 hours but typically happen[s] more
  quickly" (read 2026-09-17). The consent at 13:15 is the first thing that needs it. If the Reports
  call at T1-20 returns a permission error, this is why; wait and retry rather than widening the
  role.
- **ROLLBACK:** Unassign the role, then delete it. Both are same-day and reversible.
- **RECORD:** `records/T1-7-eve-reader-role.png`.

### T1-8 The domain-wide delegation absence proof, first half

- **WHO:** Person B. **WHERE:** Admin console: Menu > Apps & integrations > Domain-wide delegation.
- **ACTION:** Read the list as it stands **before** any client of this build exists. Export or
  screenshot every row: client id, name, scopes. This is the baseline against which day 2 proves
  that neither robot client ever appears there. **No client created in these three days is ever
  added to this list.** Absolute 1 is that no agent is ever impersonated; each robot holds its own
  consented refresh token.
- **VERIFY:** The screenshot is timestamped and shows the complete list, including an empty list if
  the tenant has none. Person B writes the row count in the run log.
- **ROLLBACK:** Read only.
- **RECORD:** `records/T1-8-dwd-baseline.png`. Day 2 step T2-6 takes the second half.

---

## D1-A2 10:15 to 11:45. Stores, floor, registry, identities

### T1-9 Three datasets and the watcher's three tables

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** One dataset for evidence, one for the watcher, one for the improver (the doer's
  `steward_audit` is T1-12a). The three `eve` tables below are **exactly** the ones
  [code.md](code.md) §1 writes and §2 reads, copied from the table under §1's verify block:
  `ws_activities` with the eleven columns `poller.py`'s `flatten()` produces (`parameters` is a
  `STRING` holding JSON, not a `JSON` column), `poll_runs` which `record_run()` writes and
  `last_run()` reads, and `watchlists`, which the detections view reads three times. If a schema
  here disagrees with the code, the poller's insert fails loudly rather than dropping a column in
  silence; the fix is here, never in the code.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a; . "$HOME/agp-3day/tools/penv.sh"
bq --project_id="$CORE_PROJECT" --location="$BQ_LOCATION" mk --dataset --description="Three-day build: sealed records" --label=programme:agp-3day "${CORE_PROJECT}:evidence"
bq --project_id="$MO_PROJECT"  --location="$BQ_LOCATION" mk --dataset --description="Three-day build: measurement views" --label=programme:agp-3day "${MO_PROJECT}:mo"
bq --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" mk --dataset --description="Three-day build: Admin SDK Reports poll and detections" --label=programme:agp-3day "${EVE_PROJECT}:eve"
bq --project_id="$EVE_PROJECT" mk --table --time_partitioning_field=event_time --time_partitioning_type=DAY \
  "${EVE_PROJECT}:eve.ws_activities" \
  'insert_id:STRING,event_time:TIMESTAMP,application:STRING,actor_email:STRING,actor_profile_id:STRING,ip_address:STRING,event_type:STRING,event_name:STRING,parameters:STRING,subject:STRING,ingested_at:TIMESTAMP'
bq --project_id="$EVE_PROJECT" mk --table "${EVE_PROJECT}:eve.poll_runs" \
  'run_time:TIMESTAMP,rows_landed:INT64,findings:INT64,gaps:STRING'
bq --project_id="$EVE_PROJECT" mk --table "${EVE_PROJECT}:eve.watchlists" \
  'kind:STRING,value:STRING'
bq --project_id="$EVE_PROJECT" ls --format=prettyjson "${EVE_PROJECT}:eve" | jq -r '.[].tableReference.tableId' | sort
```

- **VERIFY:** The last command prints `poll_runs`, `watchlists`, `ws_activities`, and nothing
  else. `bq show --format=json "${EVE_PROJECT}:eve.ws_activities" | jq -r
  '.timePartitioning.field, (.schema.fields | length)'` prints `event_time` and `11`.
- **ROLLBACK:** `bq rm -r -f "${EVE_PROJECT}:eve"` and the same for the other two, before any row is
  written. After the seeded test this destroys evidence: do not.
- **RECORD:** The table list.
- **Cited:** `bq mk --table` with `--time_partitioning_field`, `--time_partitioning_type` and an
  inline `field:type,...` schema (bq command-line tool reference, read 2026-09-18).

### T1-9a Seed `eve.watchlists`: who is allowed, who is a robot, which groups are control groups

- **WHO:** Person A seeds; person B reads the three lists back and initials them. **WHERE:**
  Terminal.
- **ACTION:** The detections view ([code.md](code.md) §2) reads `watchlists` for three kinds:
  `admin_allowlist` (the actors whose admin events are expected, so that R2 fires on anyone else),
  `service_identity` (the robot accounts, so that R5 fires on a robot login) and `control_group`
  (group addresses whose membership changes R6 reports). A `watchlists` table that nothing
  populates makes R2 fire on every admin event and R5 and R6 never fire; that is not a detection
  set, it is noise and silence.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
cat > "$HOME/agp-3day/records/T1-9a-watchlists.json" <<EOF
{"kind":"admin_allowlist","value":"${PERSON_A_EMAIL}"}
{"kind":"admin_allowlist","value":"${PERSON_B_EMAIL}"}
{"kind":"service_identity","value":"${EVE_READER}"}
{"kind":"service_identity","value":"${DOER_ROBOT}"}
{"kind":"control_group","value":"gcp-organization-admins@${ORG_DOMAIN}"}
EOF
# Assumption: the control-group addresses. Replace with the tenant's real control groups
# (the super-admin group, the billing-admin group); person B names them and initials the file.
bq --project_id="$EVE_PROJECT" insert "${EVE_PROJECT}:eve.watchlists" "$HOME/agp-3day/records/T1-9a-watchlists.json"
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT kind, COUNT(*) AS n FROM `'"$EVE_PROJECT"'.eve.watchlists` GROUP BY kind ORDER BY kind'
```

- **VERIFY:** Three rows: `admin_allowlist` 2, `control_group` at least 1, `service_identity` 2.
  Person B reads the file on screen and initials the run-log line "watchlists seeded: two admins,
  two robots, `<n>` control groups". The doer robot is listed a day before it exists, on purpose:
  its first login on day 2 must be a finding.
- **Later changes** are rows, not SQL: person B adds or removes a row with `bq insert` or a
  `DELETE` statement and writes the change in the run log. Nobody edits the view to change who is
  watched.
- **ROLLBACK:** `bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" 'DELETE FROM
  `'"$EVE_PROJECT"'.eve.watchlists` WHERE TRUE'`.
- **RECORD:** `records/T1-9a-watchlists.json`, initialled.
- **Cited:** `bq insert` reads newline-delimited JSON rows from a file or stdin (bq command-line
  tool reference, read 2026-09-18).

### T1-10 The Model Armor floor on the two projects that can call a model

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** The floor is evidence, never a boundary (absolute 5). It is set on `CORE_PROJECT` and
  `DOER_PROJECT`, the two projects where `aiplatform.googleapis.com` is enabled. Every flag below
  was read on 2026-09-17 and the command is documented only under `alpha` and `beta`; re-read the
  page on the day and **stop if gcloud rejects a flag**.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
RAI='[{"filterType":"HATE_SPEECH","confidenceLevel":"MEDIUM_AND_ABOVE"},{"filterType":"HARASSMENT","confidenceLevel":"MEDIUM_AND_ABOVE"},{"filterType":"SEXUALLY_EXPLICIT","confidenceLevel":"MEDIUM_AND_ABOVE"},{"filterType":"DANGEROUS","confidenceLevel":"MEDIUM_AND_ABOVE"}]'
for P in "$CORE_PROJECT" "$DOER_PROJECT"; do
  gcloud beta model-armor floorsettings update \
    --full-uri="projects/${P}/locations/global/floorSetting" \
    --enable-floor-setting-enforcement=TRUE \
    --pi-and-jailbreak-filter-settings-enforcement=enable \
    --pi-and-jailbreak-filter-settings-confidence-level=high \
    --malicious-uri-filter-settings-enforcement=enabled \
    --rai-settings-filters="$RAI" \
  || { echo "STOP on ${P}: a flag was refused; re-read the floorsettings reference before guessing"; break; }
  gcloud beta model-armor floorsettings describe --full-uri="projects/${P}/locations/global/floorSetting" --format=json > "records/T1-10-floor-${P}.json"
done
jq -r '.enableFloorSettingEnforcement' records/T1-10-floor-*.json
```

- **VERIFY:** `true` twice. The described settings show the prompt-injection filter enabled at
  confidence `HIGH` and four RAI filters.
- **Fallback:** If the beta command refuses a flag, set the floor in the Cloud console (Security >
  Model Armor > Floor settings), screenshot the page, and record the console path instead of the
  command. Do not weaken a filter to make a command succeed.
- **Never write:** "Model Armor blocked the injection." It produces a finding. It is not a boundary.
- **ROLLBACK:** Re-run with `--enable-floor-setting-enforcement=FALSE`.
- **RECORD:** `records/T1-10-floor-*.json`.

### T1-11 One Artifact Registry repository

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** `gcloud run ... --source` builds through Cloud Build and pushes to Artifact Registry;
  creating the repository now turns tomorrow's silent permission failure into today's loud one.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
for P in "$EVE_PROJECT" "$DOER_PROJECT"; do
  gcloud artifacts repositories create cloud-run-source-deploy --repository-format=docker --location="$REGION" --description="Three-day build source deploys" --project="$P"
done
gcloud artifacts repositories list --location="$REGION" --project="$EVE_PROJECT" --format='value(name)'
```

- **VERIFY:** The repository is listed in both projects.
- **ROLLBACK:** `gcloud artifacts repositories delete cloud-run-source-deploy --location="$REGION" --project=<project>`.
- **RECORD:** The list output.

### T1-12 Two keyless service accounts for the watcher

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** `eve-verifier@` runs the poller and is the only identity that may read the refresh
  token. `eve-scheduler@` only triggers the job. Neither ever gets a downloaded key.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
gcloud iam service-accounts create eve-verifier --project="$EVE_PROJECT" --display-name="Eve verifier: polls the Reports API and writes eve.ws_activities"
gcloud iam service-accounts create eve-scheduler --project="$EVE_PROJECT" --display-name="Eve scheduler: triggers the poller job and nothing else"
gcloud projects add-iam-policy-binding "$EVE_PROJECT" --member="serviceAccount:eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com" --role=roles/bigquery.dataEditor --condition=None
gcloud projects add-iam-policy-binding "$EVE_PROJECT" --member="serviceAccount:eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com" --role=roles/bigquery.jobUser --condition=None
for SA in eve-verifier eve-scheduler; do
  gcloud iam service-accounts keys list --iam-account="${SA}@${EVE_PROJECT}.iam.gserviceaccount.com" --managed-by=user --project="$EVE_PROJECT" --format='value(name)' | grep . && echo "STOP: ${SA} has a user-managed key" || echo "${SA}: no user-managed key, as required"
done
```

- **VERIFY:** Two `no user-managed key, as required` lines. The secret-accessor grant comes in T1-15,
  after the secret exists, and is scoped to that one secret rather than to the project.
- **ROLLBACK:** `gcloud iam service-accounts delete <address> --project="$EVE_PROJECT"`; remove the
  two project bindings with `remove-iam-policy-binding`.
- **RECORD:** The two lines, in the run log.

### T1-12a The doer's foundation: audit dataset, two tables, two service accounts, three secrets

- **WHO:** Person A. **WHERE:** Terminal, in `DOER_PROJECT`.
- **ACTION:** Day 2 reads all of this back as though it already existed (T2-9 to T2-11), so it is
  built today, at a desk, with no clock running. Nothing here can act: the two service accounts
  hold no credential, the refresh-token secret and the OAuth-client secret are empty until T1-14a
  and day-2 T2-17, and the halt is seeded **`off`** only so that day 2's first request can be a
  refusal for the right reason. **The `actions` schema below is the eighteen columns
  [code.md](code.md) §3's `audit_row()` writes, in that order, and it is the only audit schema in
  these three days**: day-2 T2-9 reads it back and day-3 T3-1 checks the views against it.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
# 1. the dataset and its two tables. Location is IRREVERSIBLE: EU, like everything else.
bq --project_id="$DOER_PROJECT" --location="$BQ_LOCATION" mk --dataset \
  --description="Three-day build: the doer's write-ahead audit, insert-only, keyed on agent_id" \
  --label=programme:agp-3day "${DOER_PROJECT}:steward_audit"
bq --project_id="$DOER_PROJECT" mk --table --time_partitioning_field=ts --time_partitioning_type=DAY \
  --clustering_fields=operation,verdict "${DOER_PROJECT}:steward_audit.actions" \
  'row_id:STRING,ts:TIMESTAMP,agent_id:STRING,request_id:STRING,phase:STRING,operation:STRING,target:STRING,level:INT64,requester:STRING,approver:STRING,approval_nonce:STRING,verdict:STRING,denial_reason:STRING,request_hash:STRING,dry_run:BOOL,halt_state:STRING,google_status:STRING,detail:STRING'
bq --project_id="$DOER_PROJECT" mk --table --time_partitioning_field=created_at --time_partitioning_type=DAY \
  "${DOER_PROJECT}:steward_audit.approvals" \
  'nonce:STRING,request_hash:STRING,approver:STRING,created_at:TIMESTAMP,operation:STRING,target:STRING,level:INT64'

# 2. two keyless service accounts. steward-actions@ will be the only credential holder;
#    steward-plan@ will hold nothing but the right to call a model.
gcloud iam service-accounts create steward-actions --project="$DOER_PROJECT" --display-name="Steward actions: the only credential holder; writes steward_audit"
gcloud iam service-accounts create steward-plan --project="$DOER_PROJECT" --display-name="Steward plan: calls a model, holds no credential, cannot invoke the action service"
gcloud projects add-iam-policy-binding "$DOER_PROJECT" --member="serviceAccount:steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" --role=roles/bigquery.jobUser --condition=None

# 3. the writer: ONE custom role, granted in the DATASET's own access array, never project-wide.
#    tables.getData is required: the service reads its own approvals and nonce history.
gcloud iam roles create stewardAuditWriter --project="$DOER_PROJECT" --title="Steward audit writer" --stage=GA \
  --permissions=bigquery.tables.updateData,bigquery.tables.getData,bigquery.tables.get,bigquery.datasets.get
bq --project_id="$DOER_PROJECT" show --format=prettyjson "${DOER_PROJECT}:steward_audit" > "$HOME/agp-3day/ds-nowriter.json"
python3 - <<'PY'
import json, os
h, p = os.environ["HOME"], os.environ["DOER_PROJECT"]
d = json.load(open(h + "/agp-3day/ds-nowriter.json"))
d["access"] = [a for a in d["access"] if a.get("specialGroup") != "projectOwners"]   # owners read, never write
d["access"].append({"role": "READER", "userByEmail": f"eve-verifier@{os.environ['EVE_PROJECT']}.iam.gserviceaccount.com"})
json.dump(d, open(h + "/agp-3day/ds-nowriter.json", "w"), indent=1)   # readers only: day-2 N4's lever
d["access"].append({"role": f"projects/{p}/roles/stewardAuditWriter",
                    "userByEmail": f"steward-actions@{p}.iam.gserviceaccount.com"})
json.dump(d, open(h + "/agp-3day/ds-writer.json", "w"), indent=1)     # readers plus one writer
PY
bq --project_id="$DOER_PROJECT" update --source "$HOME/agp-3day/ds-writer.json" "${DOER_PROJECT}:steward_audit"

# 4. three secrets. Only the halt receives a value today. Values never pass on a command line.
for S in steward-refresh-token steward-halt steward-oauth-client; do
  gcloud secrets create "$S" --replication-policy=user-managed --locations="$REGION" --project="$DOER_PROJECT" --labels=programme=agp-3day
done
printf 'off' | gcloud secrets versions add steward-halt --data-file=- --project="$DOER_PROJECT"
for S in steward-refresh-token steward-halt; do
  gcloud secrets add-iam-policy-binding "$S" --member="serviceAccount:steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" --role=roles/secretmanager.secretAccessor --project="$DOER_PROJECT" --condition=None
done
gcloud secrets add-iam-policy-binding steward-halt --member="serviceAccount:steward-actions@${DOER_PROJECT}.iam.gserviceaccount.com" --role=roles/secretmanager.secretVersionAdder --project="$DOER_PROJECT" --condition=None

# 5. read it all back
bq --project_id="$DOER_PROJECT" show --format=prettyjson "${DOER_PROJECT}:steward_audit.actions" | jq -r '[.schema.fields[].name] | join(",")'
bq --project_id="$DOER_PROJECT" show --format=prettyjson "${DOER_PROJECT}:steward_audit" | jq -c '.access[]'
gcloud secrets versions access latest --secret=steward-halt --project="$DOER_PROJECT"; echo
for SA in steward-actions steward-plan; do
  gcloud iam service-accounts keys list --iam-account="${SA}@${DOER_PROJECT}.iam.gserviceaccount.com" --managed-by=user --project="$DOER_PROJECT" --format='value(name)' | grep . && echo "STOP: ${SA} has a user-managed key" || echo "${SA}: no user-managed key, as required"
done
```

- **VERIFY:** The column line reads exactly
  `row_id,ts,agent_id,request_id,phase,operation,target,level,requester,approver,approval_nonce,verdict,denial_reason,request_hash,dry_run,halt_state,google_status,detail`.
  The access array shows **one** entry naming `steward-actions@` with role
  `projects/<DOER_PROJECT>/roles/stewardAuditWriter`, one `READER` for `eve-verifier@`, and no
  `projectOwners` entry. The halt reads `off`. Two `no user-managed key` lines. `gcloud secrets
  versions list steward-refresh-token --project="$DOER_PROJECT"` and the same for
  `steward-oauth-client` list no version. `gcloud projects get-iam-policy "$DOER_PROJECT"
  --flatten='bindings[].members' --filter='bindings.members:steward-actions@'
  --format='value(bindings.role)'` prints `roles/bigquery.jobUser` and nothing else: **no
  project-wide `bigquery.dataEditor`, ever.**
- **`Assumption:`** BigQuery accepts a project-level custom role in a dataset access entry;
  Google's access-control page shows only `READER`, `WRITER` and `OWNER` in its `bq update
  --source` examples (read 2026-09-18). If the `bq update` is refused, replace the role string in
  `ds-writer.json` with `WRITER` (the dataset-level basic role, still one identity on one
  dataset), re-run the update, and write the widening in the run log. Never fall back to a
  project-level binding.
- **Why nothing here breaks the ordering rule:** no account can sign in, no credential exists, no
  role is assigned, nothing is deployed. A dataset with a writer that cannot be reached and two
  service accounts that hold no secret are ground, not a doer.
- **ROLLBACK:** `bq rm -r -f "${DOER_PROJECT}:steward_audit"` (before any row exists);
  `gcloud secrets delete <name> --project="$DOER_PROJECT"` for each of the three;
  `gcloud iam service-accounts delete <address> --project="$DOER_PROJECT"`;
  `gcloud iam roles delete stewardAuditWriter --project="$DOER_PROJECT"` (a deleted custom role id
  is not immediately reusable).
- **RECORD:** The column line, the access array and the halt value, saved to
  `records/T1-12a-doer-foundation.txt`. Keep `ds-nowriter.json` and `ds-writer.json`: they are
  day-2 T2-24 N4's two levers.
- **Cited:** the permissions `bigquery.tables.updateData`, `bigquery.tables.getData`,
  `bigquery.tables.get`, `bigquery.datasets.get` (BigQuery access control, read 2026-09-18);
  `bq mk --table --clustering_fields` (bq reference, read 2026-09-18); `gcloud iam roles create
  ROLE_ID --project --title --permissions --stage` (read 2026-09-17, day 2 sources).

---

## D1-B2 10:15 to 11:45. The client, the secret, and tomorrow's ground

### T1-13 One Desktop OAuth client in `EVE_PROJECT`, audience Internal

- **WHO:** Person B. **WHERE:** Cloud console, in `EVE_PROJECT`.
- **ACTION:** Menu > **Google Auth platform** > **Branding**: application name `agp-3day eve
  reader`, support email person B's, contact email person B's, accept the user-data policy, Create.
  Then **Audience**: select **Internal**. Then Menu > **Google Auth platform** > **Clients** >
  **Create client** > **Application type** > **Desktop app**, name it `eve-reader-desktop`, Create,
  and download the JSON (paths read 2026-09-17 from Google's Reports API Python quickstart).
- **VERIFY:** The Clients list shows one client of type Desktop app; the Audience page says
  Internal. Save the JSON to `$HOME/agp-3day/eve-client.json`, `chmod 600` it, and **do not commit
  it**: `echo 'eve-client.json' >> .gitignore`.
- **Unsettled:** Google has been moving these pages between "APIs & Services > OAuth consent
  screen" and "Google Auth platform". If the menu differs, find the Clients page by its content
  (Application type > Desktop app) and record the path you actually used.
- **ROLLBACK:** Delete the client. A replacement is always a **new** client with a new name; never
  reuse a deleted client's id.
- **RECORD:** The client id (not the secret) in the run log; `records/T1-13-client.png`.

### T1-14 Mark the client Trusted, in the same sitting

- **WHO:** Person B. **WHERE:** Admin console: Security > Access and data control > **API controls**
  > **Manage App Access** > **Configure new app** > OAuth App Name Or Client ID (path read
  2026-09-17).
- **ACTION:** Paste the client id from T1-13, select the app, scope it to the whole organisation,
  choose **Trusted**, finish. Trusted means the app "can access all Google services (both
  restricted and unrestricted)"; doing this **before** the consent also removes the granular-
  permissions untick surface that would otherwise let a consenting account drop a scope silently.
  The boundary is not this setting: the boundary is the single scope in T1-17 and the two
  privileges in T1-7.
- **VERIFY:** The Manage App Access list shows the client id with access **Trusted** at organisation
  scope. Screenshot the row.
- **ROLLBACK:** Change the app's access to Blocked, or remove the configured app.
- **RECORD:** `records/T1-14-trusted.png`.

### T1-14a The doer's OAuth client in `DOER_PROJECT`, marked Trusted, a day before it is needed

- **WHO:** Person B creates and marks; person A runs the one secret write. **WHERE:** Cloud
  console in `DOER_PROJECT`, the Admin console, and one terminal.
- **ACTION:** The same shape as T1-13 and T1-14, in the doer's project. Creating it today is what
  gives the Trusted marking an overnight propagation window: Google says a marking change "can
  take up to 24 hours but typically happen[s] more quickly" (read 2026-09-17), and a consent that
  fails on an unpropagated marking presents as an unhelpful blocked-app error, not as a timing
  message ([README.md](README.md) R-02). The client is inert until day-2 T2-17: it has no consent
  and no token. **Nothing about the doer exists after this step except a client id and a secret.**
  1. Menu > **Google Auth platform** > **Branding**: application name `agp-3day steward`, support
     and contact email person B's, Create. **Audience**: **Internal**. If Internal is not offered
     the project is not under the organisation: stop and check the project's parent rather than
     switching to External.
  2. **Clients** > **Create client** > **Desktop app**, name `steward-desktop`, Create. The client
     JSON is shown once: person A pastes it straight into Secret Manager on stdin, nothing on disk.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a; . "$HOME/agp-3day/tools/penv.sh"
gcloud secrets versions add steward-oauth-client --data-file=- --project="$DOER_PROJECT"
# paste the JSON, then Ctrl-D. Then:
pbcopy </dev/null 2>/dev/null || true
find "$HOME" -maxdepth 4 -name 'client_secret*' 2>/dev/null     # must print nothing
penv STEWARD_OAUTH_CLIENT_ID "<the client id from the dialog, never the secret>"
gcloud secrets versions list steward-oauth-client --project="$DOER_PROJECT" --format='value(name,state)'
```

  3. Admin console > Security > Access and data control > **API controls** > **Manage App Access**
     > **Configure new app** > OAuth App Name Or Client ID > paste `STEWARD_OAUTH_CLIENT_ID` >
     select > scope to the whole organisation > **Trusted** > finish.
- **VERIFY:** The Clients page of `DOER_PROJECT` lists exactly one Desktop client. The secret shows
  exactly one `enabled` version. `find` printed nothing. `grep STEWARD_OAUTH_CLIENT_ID
  "$HOME/agp-3day/names.env"` prints the id. The Manage App Access list shows this client id as
  **Trusted** beside Eve's. Screenshot the row. `eve-client.json` from T1-13 is the only client
  file on disk, and it is ignored by git.
- **What day 2 does with it:** T2-16 only confirms the id still reads Trusted in the configured-apps
  list, then T2-17 consents the robot to it. The day-2 re-consent after K4 (T2-26) consents to
  **this same client** again: revoking a grant consumes the token, not the client, so no second
  client is ever created at 16:45.
- **ROLLBACK:** Delete the client on the Clients page (check the box, Delete; "You can restore
  deleted clients within 30 days", Manage OAuth Clients, read 2026-09-18); disable the secret
  version. A replacement is always a **new** client with a new name.
- **RECORD:** The client id in the run log; `records/T1-14a-steward-client.png`,
  `records/T1-14a-trusted.png`.

### T1-15 The empty secret and its one reader

- **WHO:** Person A creates the secret; person B holds the client JSON. **WHERE:** Terminal.
- **ACTION:** The secret is created empty. The only version it will ever hold arrives at T1-17,
  piped from standard input and never printed.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
gcloud secrets create eve-refresh-token --replication-policy=user-managed --locations="$REGION" --project="$EVE_PROJECT" --labels=programme=agp-3day
gcloud secrets add-iam-policy-binding eve-refresh-token --member="serviceAccount:eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com" --role=roles/secretmanager.secretAccessor --project="$EVE_PROJECT" --condition=None
gcloud secrets get-iam-policy eve-refresh-token --project="$EVE_PROJECT" --format='value(bindings.members)'
gcloud secrets versions list eve-refresh-token --project="$EVE_PROJECT" --format='value(name,state)'
```

- **VERIFY:** Exactly one member holds `secretAccessor`, and it is `eve-verifier@`. The version list
  is empty. No human account is granted accessor on this secret.
- **ROLLBACK:** `gcloud secrets delete eve-refresh-token --project="$EVE_PROJECT"`.
- **RECORD:** The policy line, with the members list, in the run log.

### T1-16 The pilot organisational unit, four synthetic accounts, and tomorrow's role unassigned

- **WHO:** Person B. **WHERE:** Admin console.
- **ACTION:** This is day 2's ground, built a day early on purpose: a role assignment can take up to
  24 hours to propagate, so tomorrow's assignment must be the first thing of the morning and
  everything it depends on must already exist.
  1. Directory > Organisational units > Create: `pilot` and `nonprod`, both at the top level.
     Leave `nonprod` empty for the whole three days.
  2. Directory > Users > Add new user, four times: `pilot-user-01@` to `pilot-user-04@`, each
     directly in `pilot`, given name `Synthetic`, family name `Pilot 0n`. No licence beyond what the
     tenant assigns automatically. **These accounts belong to nobody.** They receive no mail, are
     told to nobody, and no real employee is ever moved into `pilot` (absolute 7).
  3. Menu > Account > Admin roles > Create new role: `Pilot Steward (3-day)`. Tick, under Admin
     console privileges, exactly **Users > Read** and **Users > Update > Suspend users**. Ticking
     Update grants Read automatically; Suspend users is one of Update's documented sub-options, and
     the Users privilege is one that may be limited to an organisational unit (read 2026-09-17).
     **Save it and assign it to nobody.** Tomorrow's T2-4 assigns it, scoped to `pilot`, with
     person B approving.
- **VERIFY:** `pilot` holds exactly four users, all with `@` addresses matching `pilot-user-0[1-4]`;
  `nonprod` holds zero. The role page lists exactly two privileges and the role's Assignments tab is
  empty. Person B writes in the run log: "Pilot Steward created, assigned to nobody, at `<UTC>`".
- **ROLLBACK:** Delete the role (unassigned, so free). Suspend and later delete the four accounts;
  delete the two organisational units once empty.
- **RECORD:** `records/T1-16-pilot-ou.png`, `records/T1-16-pilot-steward-privileges.png`.

### T1-16a The notification channel, its verification link, and the two log-based metrics

- **WHO:** Person B, on their own account. **WHERE:** Terminal, then person B's mailbox.
- **ACTION:** Built in the morning so that the emailed verification link has hours to be clicked,
  and so that person B's afternoon block does not wait on person A's poller for anything except
  the one condition that genuinely needs a data point (T1-23). The channel is person B's
  individual address, not a shared mailbox, because the seeded test needs one named person to
  confirm and one named person to receive nothing. The metrics count the poller's two structured
  lines (`EVE-FINDING route=...` per finding, `EVE-POLL-OK` per successful run,
  [code.md](code.md) §1); creating a log-based metric before any log line exists is fine.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a; . "$HOME/agp-3day/tools/penv.sh"
gcloud beta monitoring channels create --project="$EVE_PROJECT" \
  --display-name="agp-3day person B" --type=email \
  --channel-labels="email_address=${PERSON_B_EMAIL}" --enabled
penv EVE_CHANNEL "$(gcloud beta monitoring channels list --project="$EVE_PROJECT" --format='value(name)' | head -1)"
gcloud logging metrics create eve_findings --project="$EVE_PROJECT" \
  --description="One per EVE-FINDING line emitted by the poller" \
  --log-filter='resource.type="cloud_run_job" AND textPayload:"EVE-FINDING"'
gcloud logging metrics create eve_poll_ok --project="$EVE_PROJECT" \
  --description="One per successful poller run" \
  --log-filter='resource.type="cloud_run_job" AND textPayload:"EVE-POLL-OK"'
gcloud beta monitoring channels list --project="$EVE_PROJECT" --format='value(name,type,labels.email_address,verificationStatus)'
gcloud logging metrics list --project="$EVE_PROJECT" --format='value(name)'
```

- **VERIFY:** One channel, type `email`, the address person B's own. Person B opens their own
  mailbox and **clicks the verification link Google sends**; the channel list then shows
  `VERIFIED`. If the mail has not arrived by 11:45, re-check at 13:15 and again at 14:15; an
  unverified channel delivers nothing and T1-24 cannot pass. Two metrics, `eve_findings` and
  `eve_poll_ok`. `EVE_CHANNEL` is in `names.env`.
- **ROLLBACK:** `gcloud beta monitoring channels delete "$EVE_CHANNEL" --project="$EVE_PROJECT"`;
  `gcloud logging metrics delete eve_findings --project="$EVE_PROJECT"` and the same for
  `eve_poll_ok`.
- **RECORD:** The channel name and its verification status in the run log, with the UTC minute the
  link was clicked.

---

## D1-C1 13:15 to 14:15. The consent sitting

Both people are at one keyboard. No screen share, no recording, no remote session. The sitting ends
with a refresh token in Secret Manager that neither person has seen.

### T1-17 One account, one client, one scope, one consent

- **WHO:** Person B signs in; person A runs the command. **WHERE:** One workstation, the clean
  browser profile.
- **ACTION:** Person B signs the clean browser profile in to `eve-reader@` with its security key.
  Person A then runs `tools/consent.py` from [code.md](code.md) §6 (pasted into
  `$HOME/agp-3day/tools/` with its `requirements.txt`). The tool **prints the authorisation URL
  and waits**; it never opens a browser, because the browser it would open is the one signed in as
  an administrator. Person A reads the URL, person B types it into the clean robot profile and
  completes the consent there; the tool's local listener receives the code, compares the scopes
  **Google granted** with the one asked for, and pipes the refresh token straight into the
  secret. The token is never printed, never pasted, never written to a file.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
cd "$HOME/agp-3day/tools" && python3.12 -m venv .venv && .venv/bin/pip install -q -r requirements.txt
.venv/bin/python consent.py \
  --client-json="$HOME/agp-3day/eve-client.json" \
  --scope=https://www.googleapis.com/auth/admin.reports.audit.readonly \
  --secret=eve-refresh-token \
  --project="$EVE_PROJECT"
```

- **VERIFY:** The command prints the granted scope list and the new secret version name, and nothing
  else. The granted list has **exactly one** entry and it is
  `https://www.googleapis.com/auth/admin.reports.audit.readonly` (this is the scope
  `activities.list` requires; read 2026-09-17). If a second scope appears, stop: revoke at
  `https://myaccount.google.com/permissions` as `eve-reader@`, disable the secret version, and
  re-run. A scope set cannot be narrowed after the fact. `eve-client.json` stays on person A's
  disk, mode 600, ignored by git, until the day-3 unwind decides Eve's future (T3-19): Eve is
  left polling, and a re-consent would need it.
- **This is not domain-wide delegation and must never become it.** The account consented for
  itself, in front of two people. Nothing impersonates it.
- **ROLLBACK:** Revoke the grant in the account's own Third-party access page; disable the secret
  version with `gcloud secrets versions disable <n> --secret=eve-refresh-token --project="$EVE_PROJECT"`.
- **RECORD:** `records/T1-17-consent.txt` (the printed scope list and version name), countersigned
  by both people with the UTC time.

### T1-18 The three read-backs, immediately

- **WHO:** Person B reads; person A watches. **WHERE:** Admin console and terminal.
- **ACTION:** Three checks, in this order:
  1. **Delegation:** Apps & integrations > Domain-wide delegation. The client id from T1-13 is
     **absent**. Compare against the T1-8 baseline: the row count is unchanged.
  2. **Privilege:** Directory > Users > `eve-reader@` > Admin roles and privileges. It shows
     `Eve Reader (3-day)`, it does **not** show Super Admin, and the account is a delegated admin,
     not a super admin.
  3. **Secret:** `gcloud secrets versions list eve-refresh-token --project="$EVE_PROJECT"
     --format='value(name,state)'` prints exactly one `enabled` version.
- **VERIFY:** All three as stated. Any one of them failing stops the day here; the poller is not
  deployed against an account whose shape is not what was agreed.
- **Deferred, honestly:** the OAuth Token log confirms the authorisation event from Google's own
  side, but Google gives that stream a lag of "a couple of hours" (read 2026-09-17), so it is read
  on day 2 morning, not now. Day 2's T2-6 does it.
- **ROLLBACK:** Read only.
- **RECORD:** `records/T1-18-readbacks.png` and the version line.

---

## D1-A3 14:15 to 15:30. The poller, the detections, the first poll, the schedule last

The order inside this block is the correction of 2026-09-18 and is not optional: the poller's
every run reads `eve.findings` to emit its `EVE-FINDING` lines ([code.md](code.md) §1,
`emit_findings()`), so the view must exist **before** the first execution, and the schedule is
created **last**, after one execution by hand has proved the chain end to end. Deploy (T1-19),
view (T1-19a), one poll by hand (T1-20), read the findings and only then schedule (T1-21).

### T1-19 Deploy the poller as a Cloud Run job, holding no secret in its environment

- **WHO:** Person A. **WHERE:** Terminal, in `$HOME/agp-3day/eve/`, holding `poller.py`,
  `eve_detections.sql`, `requirements.txt`, `Procfile` and `.python-version` from
  [code.md](code.md) §1, §2 and §8.
- **ACTION:** No `--set-secrets`: the job reads `eve-refresh-token` with `access_secret_version`
  under the accessor grant of T1-15, and the flag would only copy the token into the job's
  environment, readable by anyone with `run.viewer` (absolute 9). No `APPS` flag: the code's
  default is already `admin,login,token,user_accounts,groups_enterprise`, and a comma-bearing
  value would need gcloud's alternate delimiter (`--set-env-vars=^:^EVE_PROJECT=...:APPS=...`;
  "In order to include commas in your arguments, specify an alternate delimiter", `gcloud topic
  escaping`, read 2026-09-17).

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
cd "$HOME/agp-3day/eve"
gcloud run jobs deploy eve-reports-poller --source=. --region="$REGION" \
  --service-account="eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --set-env-vars="EVE_PROJECT=${EVE_PROJECT}" \
  --max-retries=1 --task-timeout=10m --project="$EVE_PROJECT"
gcloud run jobs describe eve-reports-poller --region="$REGION" --project="$EVE_PROJECT" \
  --format='value(spec.template.spec.template.spec.containers[0].env)' \
  | grep -Eio '[A-Za-z0-9_-]{24,}' | grep -v "$EVE_PROJECT" || echo "no secret-looking value in env"
```

- **VERIFY:** `gcloud run jobs describe eve-reports-poller --region="$REGION" --project="$EVE_PROJECT"
  --format='value(status.conditions[0].type,status.conditions[0].status)'` prints a `Ready` `True`
  pair. The deploy prints the image it pushed to `cloud-run-source-deploy`. The last line printed
  `no secret-looking value in env`: the same scan day-2 T2-18 runs on the action service.
- **Fallback (R-03):** if `--source` fails on Cloud Build or Artifact Registry permissions, run
  `gcloud builds submit --tag "${REGION}-docker.pkg.dev/${EVE_PROJECT}/cloud-run-source-deploy/eve-reports-poller:v1" --project="$EVE_PROJECT"`
  and deploy with `--image` instead. Deploying the poller today rather than tomorrow is deliberate:
  a build problem found now costs a day of slack, not the demonstration.
- **ROLLBACK:** `gcloud run jobs delete eve-reports-poller --region="$REGION" --project="$EVE_PROJECT"`.
- **RECORD:** The deploy output and the scan line, saved to `records/T1-19-poller-deploy.txt`.

### T1-19a Create the detections view before the first poll

- **WHO:** Person A. **WHERE:** Terminal, in `$HOME/agp-3day/eve/`.
- **ACTION:** Run [code.md](code.md) §2 **unchanged**. It creates one view, `eve.findings`, over
  `eve.ws_activities` and `eve.watchlists` (seeded at T1-9a), with one row per match carrying
  `rule_id`, `subject`, `actor`, `route`, `event_time`, `detail` and `ingested_at`. The poller
  filters on `ingested_at`, so each finding is emitted once, when its row lands.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" < "$HOME/agp-3day/eve/eve_detections.sql"
bq show --format=prettyjson "${EVE_PROJECT}:eve.findings" | jq -r '.type'
```

- **VERIFY:** `VIEW`. The view exists before any execution of the poller. It returns zero rows
  now, and that is correct: no row has landed.
- **ROLLBACK:** `bq rm -f -t "${EVE_PROJECT}:eve.findings"`.
- **RECORD:** The `VIEW` line, in the run log.

### T1-20 Run the poller once by hand, and read the first rows

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** One execution by hand, before any schedule exists, so that a broken chain is found
  with a person watching it.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
gcloud run jobs execute eve-reports-poller --region="$REGION" --project="$EVE_PROJECT" --wait
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT application, COUNT(*) AS n, MAX(event_time) AS newest, MAX(ingested_at) AS landed FROM `'"$EVE_PROJECT"'.eve.ws_activities` GROUP BY application ORDER BY application'
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT run_time, rows_landed, findings, gaps FROM `'"$EVE_PROJECT"'.eve.poll_runs` ORDER BY run_time DESC LIMIT 1'
gcloud logging read 'resource.type="cloud_run_job" AND resource.labels.job_name="eve-reports-poller" AND textPayload:"EVE-POLL-OK"' \
  --limit=1 --freshness=30m --format='value(textPayload)' --project="$EVE_PROJECT"
```

- **VERIFY:** The execution succeeds; the first query returns at least one row for `admin`
  (`COUNT(*) AS n`, never `AS rows`: `ROWS` is a reserved keyword and must be backquoted to be
  used as a name, BigQuery lexical structure, read 2026-09-17); `poll_runs` holds one row; the
  log read prints one `EVE-POLL-OK` line. **Tell person B the moment the first rows land**: their
  absence policy (T1-23) needs a metric that has data. If the poller exits 1 with
  `EVE-POLL-SILENT` on a quiet tenant, that is the two-empty-polls rule, not a failure; the
  seeded test will feed it.
- **If a row count is zero for `token`, `saml` or `groups_enterprise`:** that is a coverage gap of
  the tenant's edition, not a broken poller (risk R-07). Record it as a gap in the run log. The
  `admin` application alone carries all six detections.
- **ROLLBACK:** `bq rm -f "${EVE_PROJECT}:eve.ws_activities"` only before the seeded test, then
  recreate it from T1-9.
- **RECORD:** `records/T1-20-first-rows.txt`.

### T1-21 Read the findings, then create the schedule, last

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** Read the view over real rows, then and only then create the fifteen-minute schedule.
  `gcloud run jobs deploy` has no `--schedule` flag (reference read 2026-09-17), so the trigger is
  a separate Cloud Scheduler job calling the Run Admin API with an OAuth token.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT rule_id, COUNT(*) AS n FROM `'"$EVE_PROJECT"'.eve.findings` GROUP BY rule_id ORDER BY rule_id'
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT DISTINCT event_name FROM `'"$EVE_PROJECT"'.eve.ws_activities` WHERE application = "admin" ORDER BY 1'
gcloud run jobs add-iam-policy-binding eve-reports-poller --region="$REGION" --project="$EVE_PROJECT" \
  --member="serviceAccount:eve-scheduler@${EVE_PROJECT}.iam.gserviceaccount.com" --role=roles/run.invoker
gcloud scheduler jobs create http eve-poll-15m --location="$REGION" --schedule='*/15 * * * *' --time-zone=UTC \
  --uri="https://run.googleapis.com/v2/projects/${EVE_PROJECT}/locations/${REGION}/jobs/eve-reports-poller:run" \
  --http-method=POST --oauth-service-account-email="eve-scheduler@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --project="$EVE_PROJECT"
gcloud scheduler jobs describe eve-poll-15m --location="$REGION" --project="$EVE_PROJECT" --format='value(state,schedule)'
```

  The seven rules, and why these seven (cut C-21 keeps six plus freshness, not twenty-three). The
  `rule_id` values are the ones [code.md](code.md) §2 emits:

  | `rule_id` | Catches | Route |
  |---|---|---|
  | `role_change` | a role assigned, unassigned, created, deleted or updated, or a privilege added to or removed from one | person B |
  | `admin_actor_outside_allowlist` | an admin event by an actor who is not on the `admin_allowlist` watchlist | person B |
  | `security_setting_change` | sharing, API controls, trusted domains, two-step verification, session or single sign-on settings changed | person B |
  | `delegation_client_changed` | a client authorised for or removed from domain-wide delegation | person B and the sponsor, same hour |
  | `service_identity_login` | a login by an account on the `service_identity` watchlist | person B |
  | `control_group_membership` | a membership change on a group on the `control_group` watchlist | person B |
  | `log_pipeline_silent` | the newest admin event is more than 30 minutes old, two ticks: the watcher has gone quiet | person B |

  A finding whose **subject** is person B routes to the sponsor instead (cut C-19). With two people
  somebody must still receive the report about the second person.
- **VERIFY:** The grouped query runs; counts may legitimately be zero at 15:30, and the seeded test
  at 15:45 is what proves the chain. The second query prints the admin event names this tenant
  actually emits; if the seeded test later lands in no rule, widen the regular expression in §2
  to a name you can see and record the change, never by removing a rule. The scheduler job is
  `ENABLED` with schedule `*/15 * * * *`.
- **ROLLBACK:** `gcloud scheduler jobs delete eve-poll-15m --location="$REGION" --project="$EVE_PROJECT"`;
  `bq rm -f -t "${EVE_PROJECT}:eve.findings"`.
- **RECORD:** `records/T1-21-detections.txt`, holding both query outputs and the scheduler line.
- **Never write:** "Eve is independent." Eve lives inside the reach of the administrators it watches
  (cut C-01). It is a watcher, not a witness.

---

## D1-B3 14:15 to 15:30. The two alerting policies

The channel, its verification and the two log-based metrics were built in the morning (T1-16a).
Person B's block therefore starts with work that depends on nobody: the finding policy needs no
data point. Only the absence condition waits for person A's first rows.

### T1-22 The finding policy, which needs no data

- **WHO:** Person B, on their own account. **WHERE:** Terminal.
- **ACTION:** One policy fires when the `eve_findings` metric rises above zero. A threshold
  condition can be created before the metric has any data point.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
: "${EVE_CHANNEL:?set at T1-16a}"
gcloud beta monitoring channels describe "$EVE_CHANNEL" --project="$EVE_PROJECT" --format='value(verificationStatus)'
cat > "$HOME/agp-3day/records/T1-22-policy-finding.yaml" <<EOF
displayName: "agp-3day: a finding was raised"
combiner: OR
conditions:
- displayName: "eve_findings above zero"
  conditionThreshold:
    filter: 'metric.type="logging.googleapis.com/user/eve_findings" AND resource.type="cloud_run_job"'
    comparison: COMPARISON_GT
    thresholdValue: 0
    duration: 0s
    aggregations:
    - alignmentPeriod: 300s
      perSeriesAligner: ALIGN_SUM
notificationChannels: ["${EVE_CHANNEL}"]
EOF
gcloud monitoring policies create --policy-from-file="$HOME/agp-3day/records/T1-22-policy-finding.yaml" --project="$EVE_PROJECT"
gcloud monitoring policies list --project="$EVE_PROJECT" --format='value(displayName,enabled)'
```

- **VERIFY:** The channel reads `VERIFIED`; if it does not, the link from T1-16a has not been
  clicked and nothing will be delivered: click it now. One policy, `True`, naming `EVE_CHANNEL`.
- **ROLLBACK:** `gcloud monitoring policies delete <policy> --project="$EVE_PROJECT"`.
- **RECORD:** The YAML file and the policy list line, in the run log.

### T1-23 The absence policy, once the metric has a data point

- **WHO:** Person B. **WHERE:** Terminal. **Wait for person A's word that T1-20 wrote rows**; this
  is the only line of the day that depends on the other person's block.
- **ACTION:** The second policy fires when the poller stops saying it is alive. **An absence
  condition only fires after the metric has had at least one data point**; created before that,
  it is decorative.

```bash
set -a; . "$HOME/agp-3day/names.env"; set +a
gcloud logging read 'resource.type="cloud_run_job" AND textPayload:"EVE-POLL-OK"' --limit=1 --freshness=1h \
  --format='value(timestamp)' --project="$EVE_PROJECT" | grep . || echo "STOP: no EVE-POLL-OK yet; wait for T1-20"
cat > "$HOME/agp-3day/records/T1-23-policy-silence.yaml" <<EOF
displayName: "agp-3day: the watcher has gone quiet"
combiner: OR
conditions:
- displayName: "no eve_poll_ok for 45 minutes"
  conditionAbsent:
    filter: 'metric.type="logging.googleapis.com/user/eve_poll_ok" AND resource.type="cloud_run_job"'
    duration: 2700s
    aggregations:
    - alignmentPeriod: 300s
      perSeriesAligner: ALIGN_SUM
notificationChannels: ["${EVE_CHANNEL}"]
EOF
gcloud monitoring policies create --policy-from-file="$HOME/agp-3day/records/T1-23-policy-silence.yaml" --project="$EVE_PROJECT"
gcloud monitoring policies list --project="$EVE_PROJECT" --format='value(displayName,enabled)'
```

- **VERIFY:** The log read printed a timestamp, not `STOP`. Two policies, both `True`, both naming
  `EVE_CHANNEL`.
- **ROLLBACK:** `gcloud monitoring policies delete <policy> --project="$EVE_PROJECT"`.
- **RECORD:** `records/T1-23-policies.txt`.

---

## D1-C2 15:45 to 16:45. The seeded test

### T1-24 Person A seeds; person B alone confirms

- **WHO:** Person A performs one harmless super-admin action and then says nothing. Person B
  confirms alone. **WHERE:** Admin console; person B's mailbox.
- **ACTION:**
  1. Person A, in the Admin console, creates one empty organisational unit named
     `seed-<UTC yyyymmdd-hhmm>` at the top level, and writes the exact UTC minute on paper. Person A
     does **not** tell person B that they have done it, or when.
  2. Wait for the Admin log lag, which Google gives as "Near real time (couple of minutes)" (read
     2026-09-17), plus one scheduler tick of up to 15 minutes, plus one alignment period of 5,
     plus mail delivery. `Assumption:` the alert arrives within 20 minutes and the chain's tail is
     35 to 45 minutes at worst when working correctly; the block starts at 15:45 so that the
     45-minute stop rule below lands at 16:30 with an hour of the day left to work the chain.
     Person B may, before person A seeds, shorten the poll schedule to `*/5 * * * *` for the
     duration (`gcloud scheduler jobs update http eve-poll-15m --schedule='*/5 * * * *'
     --location="$REGION" --project="$EVE_PROJECT"`) and restore `*/15 * * * *` afterwards; if
     they do, both values and both times go in the run log.
  3. Person B, alone, watches their own mailbox. On the alert arriving, person B opens
     `eve.findings`, reads the row, and writes in the run log: the `rule_id`, the actor, the event's
     UTC time, the alert's UTC time, and the difference in minutes.
  4. Person A then writes one sentence in the run log: "I received no alert for this action", and
     both sign.
  5. Person A deletes the seeded organisational unit. It was empty, so the deletion touches no
     account; it also produces a second admin event, which should raise a second finding.
- **VERIFY:** Person B's line names an event time within two minutes of the minute person A wrote on
  paper, and person B produced that line without being told anything. The second finding, from the
  deletion, arrives on the following tick. **If no alert arrives within 45 minutes,** work the chain
  in order and record where it broke: rows in `ws_activities` (the poll), a row in `eve.findings`
  (the detection), an `EVE-FINDING` line in Logs Explorer (the emission), an incident in Monitoring
  (the policy), the mailbox (the channel).
- **Why this is the day's last step:** it is the proof that Eve is live. Tomorrow the doer is born,
  and the birth itself is an administrative action that Eve must page. A doer created before this
  test passes is a doer nobody was watching.
- **ROLLBACK:** The organisational unit is deleted in step 5. Nothing else was changed.
- **RECORD:** `records/T1-24-seeded-test.md`, signed by both, holding the two UTC times, the
  latency in minutes, the `rule_id`, and person A's sentence.

---

## Before you stop

All of these must be true. A cross anywhere is tomorrow's failure.

- [ ] Four projects, `ACTIVE`, labelled, budgeted, and each carrying a deletion lien (T1-2 to T1-4).
- [ ] `aiplatform.googleapis.com` is **not** enabled on `EVE_PROJECT` (T1-3).
- [ ] The Model Armor floor is enforced on `CORE_PROJECT` and `DOER_PROJECT`, or the console
      screenshot and the reason stand in its place (T1-10).
- [ ] `eve.ws_activities`, `eve.poll_runs` and `eve.watchlists` exist with the schemas of
      [code.md](code.md) §1; `watchlists` holds two admins, two robots and the control groups
      (T1-9, T1-9a).
- [ ] `eve.ws_activities` holds rows for the `admin` application, and the coverage gaps of the other
      applications are written down rather than explained away (T1-20).
- [ ] `eve.findings` exists with its seven rules, and existed before the first poll (T1-19a).
- [ ] The poller's environment holds no secret-looking value (T1-19).
- [ ] The scheduler job is `ENABLED` at `*/15 * * * *`, or was shortened for the seeded test and
      restored, with both times in the run log (T1-21, T1-24).
- [ ] Both alerting policies are enabled and both name person B's **verified** channel (T1-16a,
      T1-22, T1-23).
- [ ] The seeded test passed, person B alone confirmed it, and person A confirmed in writing they
      received nothing (T1-24).
- [ ] `eve-reader@` holds one custom role with one privilege (Reports), is not a super admin, sits
      in `service-identities`, has two security keys, no recovery channel, and a sealed password
      that still works, held by person B (T1-6, T1-7).
- [ ] `staging` is empty (T1-6).
- [ ] Neither client id (T1-13, T1-14a) is in the domain-wide delegation list, measured against
      the T1-8 baseline (T1-18).
- [ ] `eve-refresh-token` has exactly one enabled version and exactly one accessor, which is a
      service account (T1-15, T1-17).
- [ ] `pilot` holds four synthetic accounts and no real one; `nonprod` is empty; `Pilot Steward
      (3-day)` exists and is assigned to nobody (T1-16).
- [ ] `steward_audit.actions` has the eighteen columns of [code.md](code.md) §3 and one writer
      entry in the dataset's own access array; `steward-actions@` holds no project-wide
      `bigquery.dataEditor`; `steward-halt` reads `off`; `steward-refresh-token` has **no**
      version; `steward-oauth-client` has one (T1-12a, T1-14a).
- [ ] The doer's OAuth client reads **Trusted** in Manage App Access and
      `STEWARD_OAUTH_CLIENT_ID` is in `names.env` (T1-14a).
- [ ] **No doer account, no doer role assignment and no doer credential exists.** Eve is live and
      the doer does not exist. That sentence is the day's deliverable.
- [ ] `git -C "$HOME/agp-3day" status --short` is clean except for `eve-client.json`, which is
      ignored and never committed, and the two `ds-*.json` levers, which hold no secret.

## If the day overran

Take these in order, and say in the run log which you took.

1. **The poller would not build (R-03).** Use the `--image` fallback in T1-19. If that also fails,
   run `python3.12 poller.py` by hand from a shell whose secret value was **read from Secret
   Manager, never typed**, defer the scheduler to day 2 morning, and trigger the poll by hand for
   the seeded test, which still counts: person A triggers it and still tells person B nothing.
2. **The consent failed (R-02).** Last resort:
   `gcloud auth application-default login --client-id-file="$HOME/agp-3day/eve-client.json" --scopes=https://www.googleapis.com/auth/admin.reports.audit.readonly`
   from the robot's own browser profile, with the refresh token piped into Secret Manager by hand
   with `--data-file=-`. Never echo it. If the consent cannot be made at all today, day 1 ends at
   T1-16a and day 2 starts with the sitting; the doer still waits for Eve.
3. **Model Armor refused a flag (R-06).** Console path and screenshot, as T1-10 says. Do not spend
   the afternoon on it.
4. **Anything else.** The cut order across the three days is: the improver's scorecard first, then
   the retrospective baseline, then the improvement pull request. **Never cut:** Eve live before the
   doer exists; the forced dry run; the two-person approval; the write-ahead audit; the kill drills;
   the same-day unwind.

## What day 2 takes from here

| Day 2 needs | Built here |
|---|---|
| `names.env` with every name, including `DOER_ROBOT`, `SYNTHETIC_PREFIX`, `STAGING_OU`, `PERSON_A_EMAIL`; `tools/penv.sh` | T1-1 |
| `pilot` with four synthetic accounts | T1-16 |
| `Pilot Steward (3-day)`, unassigned, so the assignment lands at about 09:45 | T1-16 |
| `service-identities` with security-key-only two-step verification, and an empty `staging` beside it | T1-5, T1-6 |
| A watcher that will page the doer's birth, with the doer's address already on the `service_identity` watchlist | T1-9a, T1-19 to T1-24 |
| The delegation baseline, for the second half of the absence proof | T1-8 |
| Artifact Registry and a proven `--source` deploy path | T1-11, T1-19 |
| `DOER_PROJECT` with its APIs, floor, budget and lien | T1-3, T1-4, T1-10 |
| `steward_audit` with `actions` (eighteen columns) and `approvals`; `steward-actions@` as the one writer, in the dataset's access array; `steward-plan@`; `steward-refresh-token` (empty), `steward-halt` (`off`), `steward-oauth-client` (one version); `ds-nowriter.json` and `ds-writer.json` | T1-12a, T1-14a |
| The doer's OAuth client, marked Trusted a day early, its id in `names.env` | T1-14a |

Day 2 **reads all of these back** (T2-9 to T2-11) and creates none of them. What day 2 creates is
the doer itself: the robot account, its keys, its one role assignment, its consent, and the two
deployments.

## What today did not buy

A watcher that polls the Admin SDK Reports API and mails one person. Not a witness organisation, a
security information and event management contract, a 24x7 acknowledgement, an organisation log
sink, a penetration test or Security Command Center Premium. Eve reads the tenant its own
administrators control: a watcher inside the blast radius, not an independent witness. Six
detections plus a freshness rule are not twenty-three, and the Model Armor floor produces evidence,
not a boundary. None of this is compliance evidence.

## Sources

Every page below was read on 2026-09-17.

| What was checked | Page |
|---|---|
| `activities.list`: scope `admin.reports.audit.readonly`, `userKey=all`, the `applicationName` enum, `startTime`, `pageToken`, `maxResults` | https://developers.google.com/workspace/admin/reports/reference/rest/v1/activities/list |
| Admin log events "Near real time (couple of minutes)", retained "6 months"; OAuth token "A couple of hours"; "Administrators cannot delete log event data or change the length of time that the data is available for." | https://knowledge.workspace.google.com/admin/reports/data-retention-and-lag-times |
| Users privilege children (Read; Update, whose sub-options include Suspend users); "You can let admins perform actions on all users in your account or only users in specific organizational units"; Reports and other privileges that "can't be limited to specific organizational units" | https://knowledge.workspace.google.com/admin/users/administrator-privilege-definitions |
| Custom role creation at Menu > Account > Admin roles | https://knowledge.workspace.google.com/admin/users/create-edit-and-delete-custom-admin-roles |
| "Changes can take up to 24 hours but typically happen more quickly"; the organisational-unit scoping control on an assignment | https://knowledge.workspace.google.com/admin/users/assign-specific-admin-roles |
| `isOuScopable` on a Privilege; `GET .../customer/{customer}/roles/ALL/privileges` | https://developers.google.com/workspace/admin/directory/reference/rest/v1/privileges/list |
| Google Auth platform > Branding, Audience **Internal**, Clients > Create client > Desktop app; "In the Google Cloud console, enable the Admin SDK API" | https://developers.google.com/workspace/admin/reports/v1/quickstart/python |
| API controls > Manage App Access > Configure new app; Trusted "can access all Google services (both restricted and unrestricted)"; domain-wide delegation under Apps and integrations | https://knowledge.workspace.google.com/admin/apps/control-which-apps-access-google-workspace-data |
| 2-step verification at Security > Authentication > 2-step verification; Methods values "Any", "Any except verification codes via text, phone call", "Only security key" | https://knowledge.workspace.google.com/admin/security/deploy-2-step-verification |
| `gcloud run jobs deploy`: `--source`, `--region`, `--service-account`, `--set-secrets`, `--set-env-vars`, `--max-retries`, `--task-timeout`; **no `--schedule` flag** | https://docs.cloud.google.com/sdk/gcloud/reference/run/jobs/deploy |
| `gcloud scheduler jobs create http`: `--location`, `--schedule`, `--uri`, `--http-method`, `--oauth-service-account-email` ("The service account must be within the same project as the job") | https://docs.cloud.google.com/sdk/gcloud/reference/scheduler/jobs/create/http |
| `gcloud beta model-armor floorsettings update`: `--full-uri` (required), `--enable-floor-setting-enforcement=TRUE\|FALSE`, `--pi-and-jailbreak-filter-settings-enforcement=enable\|disable`, `--pi-and-jailbreak-filter-settings-confidence-level=high\|medium-and-above\|low-and-above`, `--malicious-uri-filter-settings-enforcement`, `--rai-settings-filters`; alpha and beta only, no general-availability variant | https://docs.cloud.google.com/sdk/gcloud/reference/model-armor/floorsettings/update |
| `gcloud alpha resource-manager liens create`: `--restrictions` and `--reason` required, `--origin` optional; only the alpha variant is documented | https://docs.cloud.google.com/sdk/gcloud/reference/alpha/resource-manager/liens/create |
| `gcloud billing budgets create`: `--billing-account`, `--display-name`, `--budget-amount`, `--calendar-period`, `--filter-projects` in the form `projects/{project_id}`, `--threshold-rule=percent=,basis=` | https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/create |
| `gcloud beta monitoring channels create`: `--display-name`, `--type`, `--channel-labels`, `--enabled` | https://docs.cloud.google.com/sdk/gcloud/reference/beta/monitoring/channels/create |
| `gcloud monitoring policies create` is generally available: `--policy-from-file`, `--notification-channels` | https://docs.cloud.google.com/sdk/gcloud/reference/monitoring/policies/create |
| `gcloud logging metrics create`: `--description`, `--log-filter`, `--config-from-file` | https://docs.cloud.google.com/sdk/gcloud/reference/logging/metrics/create |
| `bq mk --dataset` with `--location`, `--description`, `--label`; `bq query --use_legacy_sql=false` | https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference |

Read on 2026-09-18, for the steps corrected or added on that date:

| What was checked | Page |
|---|---|
| Creating a budget needs Billing Account Administrator or Billing Account Costs Manager on the billing account (pre-flight, T1-4) | https://docs.cloud.google.com/billing/docs/how-to/budgets |
| The Cloud Billing Budget API is `billingbudgets.googleapis.com`, enabled with `gcloud services enable` (T1-3) | https://docs.cloud.google.com/billing/docs/how-to/budget-api-setup |
| `bq mk --table` with `--time_partitioning_field`, `--time_partitioning_type`, `--clustering_fields` and an inline `field:type` schema; `bq insert` reads newline-delimited JSON from a file or stdin; `bq update --source` (T1-9, T1-9a, T1-12a) | https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference |
| The permissions `bigquery.tables.updateData`, `bigquery.tables.getData`, `bigquery.tables.get`, `bigquery.datasets.get` (T1-12a) | https://docs.cloud.google.com/bigquery/docs/access-control |
| Dataset access entries through `bq update --source`; the examples show `READER`, `WRITER`, `OWNER` only, so a custom role in the entry is `Assumption:` with a fallback (T1-12a) | https://docs.cloud.google.com/bigquery/docs/control-access-to-resources-iam |
| `gcloud logging read` is generally available; a filter positional, `--limit`, `--freshness`, `--project` (T1-20, T1-23) | https://docs.cloud.google.com/sdk/gcloud/reference/logging/read |
| Deleting an OAuth client: Clients page, tick the id, Delete; "You can restore deleted clients within 30 days" (T1-14a rollback) | https://support.google.com/cloud/answer/15549257 |
| `run_local_server(open_browser=...)`: "Whether or not to open the authorization URL in the user's browser" (T1-17) | https://google-auth-oauthlib.readthedocs.io/en/latest/reference/google_auth_oauthlib.flow.html |

Where Google has not settled something, the step says so and fails loudly rather than guessing: the
Google Auth platform menu path (T1-13, T1-14a), whether `liens create` is generally available on
the team's gcloud version (T1-4), and whether a custom role is accepted in a dataset access entry
(T1-12a).
