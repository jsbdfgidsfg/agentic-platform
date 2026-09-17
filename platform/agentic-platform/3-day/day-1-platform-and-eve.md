# Day 1. The platform and Eve

## Status

- Part of the three-day build. Entry point: [README.md](README.md). Next:
  [day-2-the-doer.md](day-2-the-doer.md), then
  [day-3-mo-demonstration-and-handover.md](day-3-mo-demonstration-and-handover.md). All code is in
  [code.md](code.md) and is pasted, not written.
- Date: 2026-09-22. Step prefix `T1`, steps T1-1 to T1-24.
- **The one ordering rule of the whole design: Eve is live before the doer exists.** Day 1 ends with
  a watcher that has seen and reported a real administrative action. No doer account, no doer role
  and no doer credential is created today.
- Every command, flag, scope, privilege and console path below was read from Google's documentation
  on 2026-09-17; the pages are listed in §Sources. Re-read anything the shell refuses.
- `Assumption:` marks every estimate and every value the team must replace.

## The day

| Time | Person A | Person B |
|---|---|---|
| 08:30 to 10:00 | D1-A1. Four projects, billing, APIs, labels, budgets, liens (T1-1 to T1-4) | D1-B1. `eve-reader@` in the service-identity OU, keys, read-only role, delegation list (T1-5 to T1-8) |
| 10:15 to 11:45 | D1-A2. Datasets and tables, Model Armor floor, Artifact Registry, two service accounts (T1-9 to T1-12) | D1-B2. OAuth client and Trusted marking, the empty secret, the pilot OU and its synthetic accounts, the unassigned doer role (T1-13 to T1-16) |
| 11:45 to 13:15 | Break | Break |
| 13:15 to 14:15 | D1-C1. The consent sitting, both present (T1-17, T1-18) | D1-C1. The consent sitting, both present |
| 14:30 to 15:45 | D1-A3. Poller, schedule, first rows, detections (T1-19 to T1-21) | D1-B3. Notification channel and the two alerting policies (T1-22, T1-23) |
| 16:00 to 17:00 | D1-C2. The seeded test; person A seeds and then stays silent (T1-24) | D1-C2. The seeded test; person B alone confirms |
| Reserved | 105 minutes of slack, not optimistic | 105 minutes of slack, not optimistic |

Person A builds. Person B approves, witnesses and receives every report. Person A never verifies
their own work.

## Before 08:30

- [ ] Both people are Google Workspace super admins and can create Google Cloud projects on a
      billing account they may attach. Note the billing account id.
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
mkdir -p "$HOME/agp-3day/records" && cd "$HOME/agp-3day"
git init -b main . >/dev/null
cat > names.env <<'EOF'
# names.env. Holds no secret. Every value is chosen once, on day 1, and never edited after.
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
export PILOT_OU="/pilot"
export NONPROD_OU="/nonprod"
export EVE_READER="eve-reader@${ORG_DOMAIN}"
export PERSON_B_EMAIL="b@${ORG_DOMAIN}"              # Assumption: replace
export SPONSOR_EMAIL="sponsor@${ORG_DOMAIN}"         # Assumption: replace
export AGENT_ID="steward"
export RUN_LOG="$HOME/agp-3day/run-log.md"
EOF
. ./names.env
gcloud config configurations create agp3 --activate
gcloud config unset project
printf '# Run log, three-day build\n\n| UTC | step | who | what |\n|---|---|---|---|\n' > "$RUN_LOG"
git add names.env run-log.md && git commit -qm "T1-1 names and run log"
```

- **VERIFY:** `gcloud config get-value project` prints `(unset)`. `grep -c '^export ' names.env`
  prints `18`. No line of `names.env` contains `token`, `secret` or `password`.
- **ROLLBACK:** `gcloud config configurations delete agp3`; `rm -rf "$HOME/agp-3day"`.
- **RECORD:** `names.env` committed; one run-log line.

### T1-2 Create the four projects and link billing

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** One purpose each: `CORE_PROJECT` evidence, `EVE_PROJECT` the watcher, `DOER_PROJECT`
  tomorrow's action service, `MO_PROJECT` the measurement. Nothing goes inside `DOER_PROJECT` today.

```bash
. ./names.env
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
. ./names.env
COMMON="logging.googleapis.com monitoring.googleapis.com bigquery.googleapis.com secretmanager.googleapis.com"
gcloud services enable $COMMON run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com modelarmor.googleapis.com aiplatform.googleapis.com --project="$CORE_PROJECT"
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
- **ROLLBACK:** `gcloud services disable <api> --project=<project>`;
  `gcloud projects update <project> --remove-labels=programme,role,population,ai_act_class`.
- **RECORD:** The enabled-services list per project, saved under `records/`.

### T1-4 A budget and a deletion lien on each project

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** The budget is a smoke alarm, not a control. The lien is what stops a tired hand at
  17:00 on day 3 deleting the project that holds the evidence.

```bash
. ./names.env
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

- **VERIFY:** Four lien rows, each carrying `resourcemanager.projects.delete`. `Assumption:` 50 EUR
  a month per project is ample for three days; the budget exists to notice a mistake, not to cap.
- **Unsettled:** `liens create` is documented only under `gcloud alpha` (read 2026-09-17). The
  fallback line tries the general-availability spelling, and the step **stops loudly** if neither
  works rather than leaving a project unprotected.
- **ROLLBACK:** `gcloud alpha resource-manager liens delete <lien>`;
  `gcloud billing budgets delete <budget> --billing-account="$BILLING_ACCOUNT_ID"`.
- **RECORD:** The lien list.

---

## D1-B1 08:30 to 10:00. The watcher's account

### T1-5 The service-identity organisational unit and its two-step verification

- **WHO:** Person B. **WHERE:** Admin console.
- **ACTION:** Directory > Organisational units > Create organisational unit. Name
  `service-identities`, parent the top-level organisation. Then Security > Authentication >
  2-step verification, select the `service-identities` organisational unit in the left panel, set
  **Enforcement** to **On**, **New user enrolment period** to **None**, and **Methods** to
  **Only security key** (the three documented values are "Any", "Any except verification codes via
  text, phone call" and "Only security key"; read 2026-09-17).
- **VERIFY:** The 2-step verification page, with `service-identities` selected, shows enforcement On
  and method Only security key, and the setting is marked as locally overridden, not inherited.
  Screenshot.
- **ROLLBACK:** Set the organisational unit back to Inherit, then delete the organisational unit
  once it is empty.
- **RECORD:** `records/T1-5-service-identity-ou.png`.

### T1-6 Create `eve-reader@`, two keys, no recovery channel

- **WHO:** Person B creates; person A witnesses the key count by eye and signs.
  **WHERE:** Admin console.
- **ACTION:** Directory > Users > Add new user. Name the account `eve-reader`, put it directly into
  the `service-identities` organisational unit, generate a password, print nothing, and store the
  password in a sealed envelope that person B keeps. Sign in once in the clean browser profile,
  change the password, and register **two** security keys. Then Account > Security: remove any
  recovery email and recovery phone, and leave both blank.
- **VERIFY:** The user's page shows the organisational unit `service-identities`, 2-Step
  Verification **Enrolled**, and two security keys listed. Recovery email and recovery phone are
  empty. Person A writes in the run log: "counted two keys by eye at `<UTC time>`".
- **ROLLBACK:** Suspend, then delete the user. Deleting a user is **IRREVERSIBLE** after 20 days;
  suspend first and delete only during the day-3 unwind.
- **RECORD:** `records/T1-6-eve-reader.png`; the run-log line with the key count.

### T1-7 One read-only custom admin role, assigned to `eve-reader@`

- **WHO:** Person B creates and assigns; person A reads the privilege list on screen before Save.
  **WHERE:** Admin console: Menu > Account > Admin roles > Create new role.
- **ACTION:** Name the role `Eve Reader (3-day)`. Tick, under **Admin console privileges**, only:

  | Privilege | Why |
  |---|---|
  | Reports | The Admin SDK Reports API refuses every call without it |
  | Users > Read | Lets person B confirm the account's own state; grants no write |

  Tick nothing else. In particular do not tick Users > Update, Groups, Security settings, Services,
  or Admin API privileges beyond the two above. Assign the role to `eve-reader@` at **All
  organizational units** (customer scope), because the Reports privilege is one of those that
  "can't be limited to specific organizational units" (privilege definitions, read 2026-09-17), so
  pretending to scope it would be theatre.
- **VERIFY:** The role's page lists exactly two privileges. `eve-reader@`'s page, under Admin roles
  and privileges, shows `Eve Reader (3-day)` and **not** Super Admin. Person A states aloud the two
  privileges they read before Save, and person B writes that sentence in the run log.
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

### T1-9 Three datasets and the watcher's two tables

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** One dataset for evidence, one for the watcher, one for the improver. The doer's
  `steward_audit` dataset waits for tomorrow, because its writer identity does not exist yet. The
  `ws_activities` schema below is the contract [code.md](code.md) §1 writes and §2 reads: if they
  disagree the load fails loudly rather than dropping a column in silence.

```bash
. ./names.env
bq --project_id="$CORE_PROJECT" --location="$BQ_LOCATION" mk --dataset --description="Three-day build: sealed records" --label=programme:agp-3day "${CORE_PROJECT}:evidence"
bq --project_id="$MO_PROJECT"  --location="$BQ_LOCATION" mk --dataset --description="Three-day build: measurement views" --label=programme:agp-3day "${MO_PROJECT}:mo"
bq --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" mk --dataset --description="Three-day build: Admin SDK Reports poll and detections" --label=programme:agp-3day "${EVE_PROJECT}:eve"
bq --project_id="$EVE_PROJECT" mk --table --time_partitioning_field=event_time --time_partitioning_type=DAY \
  "${EVE_PROJECT}:eve.ws_activities" \
  'event_time:TIMESTAMP,application:STRING,unique_qualifier:STRING,actor_email:STRING,actor_key:STRING,event_type:STRING,event_name:STRING,org_unit:STRING,ip_address:STRING,parameters:JSON,ingested_at:TIMESTAMP'
bq --project_id="$EVE_PROJECT" mk --table "${EVE_PROJECT}:eve.poll_watermark" \
  'application:STRING,last_event_time:TIMESTAMP,last_run_at:TIMESTAMP,rows_written:INTEGER'
bq --project_id="$EVE_PROJECT" ls --format=prettyjson "${EVE_PROJECT}:eve" | jq -r '.[].tableReference.tableId'
```

- **VERIFY:** The last command prints `poll_watermark` and `ws_activities`. `bq show --format=json
  "${EVE_PROJECT}:eve.ws_activities" | jq -r '.timePartitioning.field'` prints `event_time`.
- **ROLLBACK:** `bq rm -r -f "${EVE_PROJECT}:eve"` and the same for the other two, before any row is
  written. After the seeded test this destroys evidence: do not.
- **RECORD:** The table list.

### T1-10 The Model Armor floor on the two projects that can call a model

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** The floor is evidence, never a boundary (absolute 5). It is set on `CORE_PROJECT` and
  `DOER_PROJECT`, the two projects where `aiplatform.googleapis.com` is enabled. Every flag below
  was read on 2026-09-17 and the command is documented only under `alpha` and `beta`; re-read the
  page on the day and **stop if gcloud rejects a flag**.

```bash
. ./names.env
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
. ./names.env
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
. ./names.env
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

### T1-15 The empty secret and its one reader

- **WHO:** Person A creates the secret; person B holds the client JSON. **WHERE:** Terminal.
- **ACTION:** The secret is created empty. The only version it will ever hold arrives at T1-17,
  piped from standard input and never printed.

```bash
. ./names.env
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

---

## D1-C1 13:15 to 14:15. The consent sitting

Both people are at one keyboard. No screen share, no recording, no remote session. The sitting ends
with a refresh token in Secret Manager that neither person has seen.

### T1-17 One account, one client, one scope, one consent

- **WHO:** Person B signs in; person A runs the command. **WHERE:** One workstation, the clean
  browser profile.
- **ACTION:** Person B signs the clean browser profile in to `eve-reader@` with its security key.
  Person A then runs `tools/consent.py` from [code.md](code.md) §6, which opens the Desktop-app
  flow, asks for exactly one scope, and pipes the refresh token straight into the secret. The token
  is never printed, never pasted, never written to a file.

```bash
. ./names.env
python3.12 tools/consent.py \
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
  re-run. A scope set cannot be narrowed after the fact.
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

## D1-A3 14:30 to 15:45. The poller, the schedule, the detections

### T1-19 Deploy the poller as a Cloud Run job

- **WHO:** Person A. **WHERE:** Terminal, in the directory holding `eve/poller.py`,
  `eve/requirements.txt` and `eve/eve_detections.sql` from [code.md](code.md) §1, §2 and §8.
- **ACTION:**

```bash
. ./names.env
cd "$HOME/agp-3day/eve"
gcloud run jobs deploy eve-reports-poller --source=. --region="$REGION" \
  --service-account="eve-verifier@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --set-secrets=EVE_REFRESH_TOKEN=eve-refresh-token:latest \
  --set-env-vars="EVE_PROJECT=${EVE_PROJECT},APPS=admin,login,token,user_accounts,groups_enterprise" \
  --max-retries=1 --task-timeout=10m --project="$EVE_PROJECT"
```

- **VERIFY:** `gcloud run jobs describe eve-reports-poller --region="$REGION" --project="$EVE_PROJECT"
  --format='value(status.conditions[0].type,status.conditions[0].status)'` prints a `Ready` `True`
  pair. The deploy prints the image it pushed to `cloud-run-source-deploy`.
- **Fallback (R-03):** if `--source` fails on Cloud Build or Artifact Registry permissions, run
  `gcloud builds submit --tag "${REGION}-docker.pkg.dev/${EVE_PROJECT}/cloud-run-source-deploy/eve-reports-poller:v1" --project="$EVE_PROJECT"`
  and deploy with `--image` instead. Deploying the poller today rather than tomorrow is deliberate:
  a build problem found now costs a day of slack, not the demonstration.
- **ROLLBACK:** `gcloud run jobs delete eve-reports-poller --region="$REGION" --project="$EVE_PROJECT"`.
- **RECORD:** The deploy output, saved to `records/T1-19-poller-deploy.txt`.

### T1-20 Run it once by hand, then every fifteen minutes

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** `gcloud run jobs deploy` has no `--schedule` flag (reference read 2026-09-17), so the
  trigger is a separate Cloud Scheduler job calling the Run Admin API with an OAuth token.

```bash
. ./names.env
gcloud run jobs execute eve-reports-poller --region="$REGION" --project="$EVE_PROJECT" --wait
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT application, COUNT(*) AS rows, MAX(event_time) AS newest FROM `'"$EVE_PROJECT"'.eve.ws_activities` GROUP BY application ORDER BY application'
gcloud run jobs add-iam-policy-binding eve-reports-poller --region="$REGION" --project="$EVE_PROJECT" \
  --member="serviceAccount:eve-scheduler@${EVE_PROJECT}.iam.gserviceaccount.com" --role=roles/run.invoker
gcloud scheduler jobs create http eve-poll-15m --location="$REGION" --schedule='*/15 * * * *' --time-zone=UTC \
  --uri="https://run.googleapis.com/v2/projects/${EVE_PROJECT}/locations/${REGION}/jobs/eve-reports-poller:run" \
  --http-method=POST --oauth-service-account-email="eve-scheduler@${EVE_PROJECT}.iam.gserviceaccount.com" \
  --project="$EVE_PROJECT"
gcloud scheduler jobs describe eve-poll-15m --location="$REGION" --project="$EVE_PROJECT" --format='value(state,schedule)'
```

- **VERIFY:** The manual execution succeeds; the query returns at least one row for `admin`; the
  scheduler job is `ENABLED` with schedule `*/15 * * * *`. Tell person B the moment the first rows
  land: their second alerting policy (T1-23) needs a metric that has data.
- **If a row count is zero for `token`, `saml` or `groups_enterprise`:** that is a coverage gap of
  the tenant's edition, not a broken poller (risk R-07). Record it as a gap in the run log. The
  `admin` application alone carries all six detections.
- **ROLLBACK:** `gcloud scheduler jobs delete eve-poll-15m --location="$REGION" --project="$EVE_PROJECT"`;
  `bq rm -f "${EVE_PROJECT}:eve.ws_activities"` only before the seeded test.
- **RECORD:** `records/T1-20-first-rows.txt`.

### T1-21 Six detections and one freshness rule

- **WHO:** Person A. **WHERE:** Terminal.
- **ACTION:** Run [code.md](code.md) §2 unchanged. It creates one view, `eve.findings`, over
  `eve.ws_activities`, with one row per match carrying `rule_id`, `subject`, `actor`, `route` and
  `event_time`.

```bash
. ./names.env
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" < eve_detections.sql
bq query --use_legacy_sql=false --project_id="$EVE_PROJECT" \
  'SELECT rule_id, COUNT(*) AS n FROM `'"$EVE_PROJECT"'.eve.findings` GROUP BY rule_id ORDER BY rule_id'
```

  The seven rules, and why these seven (cut C-21 keeps six plus freshness, not twenty-three):

  | `rule_id` | Catches | Route |
  |---|---|---|
  | `role_change` | a role assigned, created, or a privilege added to one | person B |
  | `admin_outside_allowlist` | an admin event by a watched actor whose event name is not on the allowlist | person B |
  | `security_setting_change` | sharing, API controls, delegation, two-step verification or session settings changed | person B |
  | `delegation_client_added` | a client added to domain-wide delegation | person B, same hour |
  | `service_identity_login` | a login by a robot account | person B |
  | `control_group_membership` | a membership change on a control group | person B |
  | `log_pipeline_silent` | the watermark is older than two ticks: the watcher has gone quiet | person B |

  A finding whose **subject** is person B routes to the sponsor instead (cut C-19). With two people
  somebody must still receive the report about the second person.
- **VERIFY:** The view is created and the grouped query runs. Counts may legitimately be zero at
  15:45; the seeded test at 16:00 is what proves the chain.
- **ROLLBACK:** `bq rm -f -t "${EVE_PROJECT}:eve.findings"`.
- **RECORD:** `records/T1-21-detections.txt`.
- **Never write:** "Eve is independent." Eve lives inside the reach of the administrators it watches
  (cut C-01). It is a watcher, not a witness.

---

## D1-B3 14:30 to 15:45. The alert path

### T1-22 One notification channel, to person B's own mailbox

- **WHO:** Person B, on their own account. **WHERE:** Terminal.
- **ACTION:** The channel is person B's individual address, not a shared mailbox, because the seeded
  test needs one named person to confirm and one named person to receive nothing.

```bash
. ./names.env
gcloud beta monitoring channels create --project="$EVE_PROJECT" \
  --display-name="agp-3day person B" --type=email \
  --channel-labels="email_address=${PERSON_B_EMAIL}" --enabled
gcloud beta monitoring channels list --project="$EVE_PROJECT" --format='value(name,type,labels.email_address,verificationStatus)'
```

- **VERIFY:** One channel, type `email`, the address person B's own, and person B has clicked the
  verification link Google sends. Export the channel name:
  `CH=$(gcloud beta monitoring channels list --project="$EVE_PROJECT" --format='value(name)' | head -1)`.
- **ROLLBACK:** `gcloud beta monitoring channels delete "$CH" --project="$EVE_PROJECT"`.
- **RECORD:** The channel name and its verification status in the run log.

### T1-23 Two log-based metrics and two alerting policies

- **WHO:** Person B. **WHERE:** Terminal. Wait for person A's word that T1-20 wrote rows.
- **ACTION:** The poller emits one structured line per finding (`EVE-FINDING route=...`) and one
  `EVE-POLL-OK` line per successful run. One policy fires on a finding; the other fires when the
  poller stops saying it is alive.

```bash
. ./names.env
gcloud logging metrics create eve_findings --project="$EVE_PROJECT" \
  --description="One per EVE-FINDING line emitted by the poller" \
  --log-filter='resource.type="cloud_run_job" AND textPayload:"EVE-FINDING"'
gcloud logging metrics create eve_poll_ok --project="$EVE_PROJECT" \
  --description="One per successful poller run" \
  --log-filter='resource.type="cloud_run_job" AND textPayload:"EVE-POLL-OK"'
CH=$(gcloud beta monitoring channels list --project="$EVE_PROJECT" --format='value(name)' | head -1)
cat > /tmp/policy-finding.yaml <<EOF
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
notificationChannels: ["${CH}"]
EOF
cat > /tmp/policy-silence.yaml <<EOF
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
notificationChannels: ["${CH}"]
EOF
gcloud monitoring policies create --policy-from-file=/tmp/policy-finding.yaml --project="$EVE_PROJECT"
gcloud monitoring policies create --policy-from-file=/tmp/policy-silence.yaml --project="$EVE_PROJECT"
gcloud monitoring policies list --project="$EVE_PROJECT" --format='value(displayName,enabled)'
```

- **VERIFY:** Two policies, both `True`, both naming the channel from T1-22. **An absence condition
  only fires after the metric has had at least one data point**, which is why this step waits for
  T1-20; if `eve_poll_ok` has never been written, the silence policy is decorative. Confirm the
  metric has data: Logs Explorer, filter `textPayload:"EVE-POLL-OK"`, at least one entry.
- **ROLLBACK:** `gcloud monitoring policies delete <policy> --project="$EVE_PROJECT"`;
  `gcloud logging metrics delete eve_findings --project="$EVE_PROJECT"`.
- **RECORD:** `records/T1-23-policies.txt`.

---

## D1-C2 16:00 to 17:00. The seeded test

### T1-24 Person A seeds; person B alone confirms

- **WHO:** Person A performs one harmless super-admin action and then says nothing. Person B
  confirms alone. **WHERE:** Admin console; person B's mailbox.
- **ACTION:**
  1. Person A, in the Admin console, creates one empty organisational unit named
     `seed-<UTC yyyymmdd-hhmm>` at the top level, and writes the exact UTC minute on paper. Person A
     does **not** tell person B that they have done it, or when.
  2. Wait for the Admin log lag, which Google gives as "Near real time (couple of minutes)" (read
     2026-09-17), plus one scheduler tick. `Assumption:` the alert arrives within 20 minutes; the
     block allows 60.
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
- [ ] `eve.ws_activities` holds rows for the `admin` application, and the coverage gaps of the other
      applications are written down rather than explained away (T1-20).
- [ ] `eve.findings` exists with its seven rules (T1-21).
- [ ] The scheduler job is `ENABLED` at `*/15 * * * *` (T1-20).
- [ ] Both alerting policies are enabled and both name person B's verified channel (T1-22, T1-23).
- [ ] The seeded test passed, person B alone confirmed it, and person A confirmed in writing they
      received nothing (T1-24).
- [ ] `eve-reader@` holds one custom role with two privileges, is not a super admin, has two
      security keys and no recovery channel (T1-6, T1-7).
- [ ] The client id from T1-13 is **absent** from the domain-wide delegation list, measured against
      the T1-8 baseline (T1-18).
- [ ] `eve-refresh-token` has exactly one enabled version and exactly one accessor, which is a
      service account (T1-15, T1-17).
- [ ] `pilot` holds four synthetic accounts and no real one; `nonprod` is empty; `Pilot Steward
      (3-day)` exists and is assigned to nobody (T1-16).
- [ ] **No doer account, no doer role assignment and no doer credential exists.** Eve is live and
      the doer does not exist. That sentence is the day's deliverable.
- [ ] `git -C "$HOME/agp-3day" status --short` is clean except for `eve-client.json`, which is
      ignored and never committed.

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
   T1-16 and day 2 starts with the sitting; the doer still waits for Eve.
3. **Model Armor refused a flag (R-06).** Console path and screenshot, as T1-10 says. Do not spend
   the afternoon on it.
4. **Anything else.** The cut order across the three days is: the improver's scorecard first, then
   the retrospective baseline, then the improvement pull request. **Never cut:** Eve live before the
   doer exists; the forced dry run; the two-person approval; the write-ahead audit; the kill drills;
   the same-day unwind.

## What day 2 takes from here

| Day 2 needs | Built here |
|---|---|
| `pilot` with four synthetic accounts | T1-16 |
| `Pilot Steward (3-day)`, unassigned, so the assignment lands at about 09:45 | T1-16 |
| `service-identities` with security-key-only two-step verification | T1-5 |
| A watcher that will page the doer's birth | T1-19 to T1-24 |
| The delegation baseline, for the second half of the absence proof | T1-8 |
| Artifact Registry and a proven `--source` deploy path | T1-11, T1-19 |
| `DOER_PROJECT` with its APIs, floor, budget and lien, and nothing inside it | T1-3, T1-4, T1-10 |

`steward_audit` and its `actions` table are **not** created today: their writer identity does not
exist yet, and a table with no writer is an invitation. Day 2 T2-7 creates both.

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

Where Google has not settled something, the step says so and fails loudly rather than guessing: the
Google Auth platform menu path (T1-13), and whether `liens create` is generally available on the
team's gcloud version (T1-4).
