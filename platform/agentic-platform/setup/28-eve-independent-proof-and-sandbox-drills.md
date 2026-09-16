# 28. Eve: the second human's independent proof and the sandbox drills

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-15
- Last executed: never
- Stage: review §2 stage 30 (the Eve 10b drill, re-cut to Eve-H) and the Eve part of stage 32 (the sandbox tenant). It is the last file of the Eve-H block and the one that produces `EVE_H_LIVE_RECORD`, on which [30](30-wall-e-workspace-side.md) and every later Wall-E file depend.
- Step prefix: `EV`. Steps: 50. BLOCKED: EV-5.3 (Eve's self-integrity rules and the configuration fingerprint, README B-08), EV-6.2, EV-6.3 and EV-6.4 (the twin reconciler and the detection catalogue, README B-08 and B-09; they run as written the day [25](25-eve-human-super-admin-detections.md)'s twin deploy is `DONE`). **IRREVERSIBLE:** EV-2.10, EV-4.5, EV-5.6 and EV-6.6 — each writes a record into the witness bucket, whose retention policy is locked, so the object cannot be removed before its retention period ends.
- Replaces: the drill paragraph of [../../eve/07-build-runbook.md](../../eve/07-build-runbook.md) Phase 10b (l.1597-1602) and the evidence columns of G-2, G-4, G-5, G-6 and G-7 in [../../eve/05-stages.md](../../eve/05-stages.md). Neither page is executed.
- Salvaged: the intent of the 10b drill (a tenant-integrity event, a roster diff in both directions, `log_pipeline_silent`, a withheld export, a halt clear reaching one recipient, a dated record in the witness); the G-2 to G-7 rows of `eve/05`, with their evidence columns rewritten by SD-03 (G-4) and SD-26 (G-5, G-6, G-7).
- Not copied: "rows in `eve_workspace_reports` for `walle@`'s shadow runs" as G-4 evidence (S039: circular, and the admin application records changes only); "expect rows for `walle@`'s shadow runs" in the 10b verify (S039); Phase 7 check 4's pre-grant expectation of a robot actor and "a shadow run is enough" (S141); one drill that runs "on the sandbox tenant" and at the same time expects the witness alarm, the witness channels and a witness record (X-ORG-12, SD-26); any nonprod identity granted on a witness resource (X-ORG-12); a sandbox drill run against an OU of the production tenant (S004, X-ORG-02).
- Applies decisions (signed in [03](03-decisions-and-people.md) before the step that needs them): SD-03, SD-07, SD-08, SD-10, SD-11, SD-12, SD-26, SD-27, SD-29, SD-43, SD-45.
- Closes: S004 (the Eve half: the sandbox drills run against the sandbox tenant and its own organisation sink, never an OU of production; the Wall-E half is [37](37-wall-e-sandbox-rehearsal.md), the tenant itself [21](21-sandbox-tenant-and-nonprod-foundation.md)), S039, S141 (the drill half; the pre-grant/post-grant split of check 4 is [24](24-eve-workspace-identity-and-audit-feeds.md), the post-grant half [39](39-wall-e-stage-0.md)), X-ORG-02 (the Eve half), X-ORG-12. Defers nothing without an owner (§13).
- Consumes: `EVE_PROJECT`, `EVE_DS`, `EVE_WS_LOGS_DS`, `EVE_WS_REPORTS_DS`, `EVE_EVIDENCE_BUCKET`, `EVE_SCHEMAS_COMMIT`, `ENT_PROJECT_REPAIR_EVE` ([23](23-eve-project-and-evidence-stores.md)); `EVE_ROBOT`, `EVE_SINK`, `EVE_TWIN_SINK`, `EVE_TWIN_ROBOT`, `SA_EVE_VERIFIER`, `EVE_REFRESH_TOKEN_SECRET_NAME`, `EVE_TOKEN_VERSION` ([24](24-eve-workspace-identity-and-audit-feeds.md)); `EVE_CONFIG_REPO`, `EVE_JOB_REPORTS_POLL`, `EVE_JOB_ROSTER`, `EVE_JOB_DETECT`, `EVE_JOB_HEARTBEAT`, `EVE_CODE_COMMIT`, `SA_EVE_CONSOLE`, `EVE_CONSOLE_URL`, `GRP_EVE_CONSOLE_READERS` ([25](25-eve-human-super-admin-detections.md)); `SA_EVE_EXPORT`, `EVE_JOB_EXPORT`, `EVE_JOB_HEARTBEAT_PUSH`, `EVE_INCIDENTS_TABLE`, `EVE_PAGES_TABLE`, `NOTIF_CH_EVE_EMAIL_SECOND_HUMAN`, `NOTIF_CH_EVE_SMS_SECOND_HUMAN`, `EVE_FIRST_RUN_RECORD` ([26](26-eve-reporting-and-witness-export.md)); `WITNESS_ALERT_HEARTBEAT`, `WITNESS_ALERT_EXPORT`, `WITNESS_ALERT_INCIDENT`, `WITNESS_ALERT_FINGERPRINT` ([27](27-witness-grants-and-alarms.md)); `EVE_WITNESS_PROJECT`, `WITNESS_MIRROR_DS`, `WITNESS_HEARTBEAT_TABLE`, `WITNESS_BUCKET` ([08](08-witness-organisation.md)); `SANDBOX_DOMAIN`, `SANDBOX_CUSTOMER_ID`, `SANDBOX_ORG_ID`, `EVE_TWIN_PROJECT` ([21](21-sandbox-tenant-and-nonprod-foundation.md)); `ROSTER_FILE`, `SA_1_ADMIN`, `SA_2_ADMIN`, `GRP_EVE_OWNERS` ([06](06-organisation-bootstrap-and-roster.md)); `PAGER_SUBJECT_SERVICE_NAME` ([04](04-purchases-and-lead-times.md), [15](15-pager-siem-and-detections.md)); `DRILL_CALENDAR`, `DEVIATION_REGISTER`, `EVIDENCE_REGISTER` ([01](01-prerequisites-and-conventions.md)).
- Produces: `EVE_H_LIVE_RECORD`; the drill records `EVE_PROOF_RECORD`, `WITNESS_WITHHOLD_RECORD`, `ANTI_SILENCING_RECORD`, `SANDBOX_DRILL_RECORD`; the G-2, G-4 (production half), G-5, G-6 and G-7 rows of the gate table; rows DR-28-1, DR-28-2 and DR-28-3 of `DRILL_CALENDAR`.
- Variables new against plan §5, handed to README's variable list: `EVE_PROOF_ROLE`, `EVE_PROOF_OU`, `EVE_PROOF_ACCOUNT`, `SEEDED_ACTION_LIST`, `SANDBOX_SEEDED_ACTION_LIST`, `EVE_PROOF_T0`, `EVE_PROOF_RECORD`, `WITNESS_WITHHOLD_RECORD`, `ANTI_SILENCING_RECORD`, `SANDBOX_DRILL_RECORD`, `NOTIF_CH_EVE_TWIN_EMAIL`, `NOTIF_CH_EVE_TWIN_SA1`, `NOTIF_CH_EVE_TWIN_SA2`, `EVE_H_LIVE_RECORD`.
- Commands checked against Google's documentation on 2026-09-15 (§15). What could not be settled that day is in §14.

## What this part builds

Nothing new is deployed here. This file is the proof that what files 23 to 27 built actually watches the person who built it, performed by the one person in the programme who is outside the administration line, and the drills that turn Eve's gate rows green.

1. **The seeded-action list and the proof fixtures** (§1). Five harmless, reversible super-admin actions on objects that exist only for this purpose — a proof role with no assignment, a proof OU with no real users, a proof account — each with the exact Admin log event it must produce and the lag budget it must meet. The list is committed so that a later reader can repeat the proof; which action is used, and when, is not.
2. **The blind proof** (§2), which is the owner's question answered: the second human picks an unannounced window and one action from the list; the platform owner performs it and nothing else; the second human alone confirms the page on her own device, the row in `eve_workspace_logs`, the row in `eve_workspace_reports`, the `eve.incidents` and `eve.pages` rows, the sole recipient, the witness copy, and that nobody touched Eve's configuration or held a grant on `EVE_PROJECT` during the window. A witness administrator, not the platform owner, uploads the record.
3. **The anti-silencing checks that do not need a drill** (§3): a merge to `eve/config` without the second human's review is refused; a direct push to its default branch is refused; the platform owner holds no standing role that can edit Eve, proven from the drift output and from live reads.
4. **The witness part of the drill** (§4, gate row G-2, calendar row DR-28-3): after the first heartbeat has landed and long before the super-admin grant, production `eve-export@` misses exactly one push; the witness absence alarm fires; the backlog push carries what was withheld and the cumulative counts do not go backwards.
5. **The anti-silencing drill** (§5, DR-28-2): the platform owner makes one *declared*, visible change to Eve — pausing a single schedule for a named window — under a grant the second human approves; the second human confirms that Eve's self-integrity page and the witness fingerprint or absence alarm reach her without the platform owner's help.
6. **The sandbox part** (§6, gate rows G-5 and G-7): nonprod Eve, against the sandbox tenant and the sandbox organisation's own sink, sees a seeded tenant-integrity event, a roster diff in both directions and `log_pipeline_silent`; it pages nonprod channels only and never touches the witness. §6 carries its **own** seeded-action list (EV-6.0), separate from §2's: the production list is deliberately confined to role and organisational-unit fixtures, so it can prove `SA-02` and no more. The classes that carry the real risk — Sharing options, OAuth app trust, 2-step verification enforcement, domain-wide delegation, API controls, `SA-03` and `SI-08` — are exercised where they can be exercised safely, on the sandbox tenant, and `EVE_H_LIVE_RECORD` requires at least one of each class proven on the twin or a signed residual risk with an owner and a date (EV-8.2).
7. **The recurrence** (§7): DR-28-1 (monthly blind proof, and after every `eve/config` merge), DR-28-2 and DR-28-3 written into `DRILL_CALENDAR` here, not deferred to [42](42-gates-drills-and-evidence.md).
8. **`EVE_H_LIVE_RECORD`** (§8), refused unless the organisation exception is withdrawn, the break-glass envelopes are sealed and the witness alarms have seen data; and the second human's decision on whether [06](06-organisation-bootstrap-and-roster.md)'s interim Admin console activity rules are retired (recommended: kept).

**The residual risk this file states rather than removes** (SD-12 item 8). An Organization Administrator, or a super admin willing to break the rules, can still reach Eve inside the tenant: pause a job, edit a sink, revoke `eve@`. Nothing here makes that impossible. What it makes is *noticed*: by the self-integrity rules ([25](25-eve-human-super-admin-detections.md)), by the configuration fingerprint and cumulative counts in every witness heartbeat ([26](26-eve-reporting-and-witness-export.md), [27](27-witness-grants-and-alarms.md)), by the witness alarms in an organisation the platform owner has no account in, and by this file's unannounced proof. The second human signs that she has read this paragraph before `EVE_H_LIVE_RECORD` is written.

What the old text got wrong, and must not come back:

| Old text | Why it fails | Here instead |
|---|---|---|
| G-4 evidence: "rows in `eve_workspace_reports` for `walle@`'s shadow runs" (`eve/05` l.310); 10b verify 1 "expect rows for `walle@`'s shadow runs" | Circular: the grant needs G-4, G-4 needs shadow runs, shadow runs need the grant and Stage 0. The admin application records changes, not reads, so a shadow run leaves no admin row anyway (S039) | SD-03's three pieces: §2's seeded human super-admin change in both `eve_workspace_logs` and `eve_workspace_reports` within the lag budget (this file); the twin robot's seeded change in the nonprod datasets (§6 and [37](37-wall-e-sandbox-rehearsal.md)); the production robot's consent login event ([32](32-wall-e-consents.md)). `walle@` admin rows move to the post-grant list in [39](39-wall-e-stage-0.md) |
| Phase 7 check 4: "expect `walle@` present. If it is absent, the exclusion was copied by mistake", and "a shadow run is enough" (S141) | Before the grant the robot holds no admin role; absence is expected. A follower deletes and recreates the sink, and sinks do not backfill | [24](24-eve-workspace-identity-and-audit-feeds.md) splits the check; here, §2 proves the same filter with a **human** actor, and EV-2.4 says in terms that a missing robot row before the grant is expected and is never a reason to touch the sink |
| One drill "on the sandbox tenant" that also expects the witness alarm, pages "through the witness channels" and a record "in the witness" (X-ORG-12) | Nonprod Eve has no grant in the witness organisation, and the design allows exactly two cross-organisation grants, both to production `eve-export@` | SD-26's split: §6 is the sandbox part (nonprod channels only, no witness contact); §4 is the witness part (production `eve-export@`); a witness administrator records both |
| Sandbox drills run against a sandbox **OU** of the production tenant (`SETUP` Phase 1 step 6; S004) | 02 §1.3 PSA6 and §3.5 forbid it; a drill in production's OU proves nothing about a separate tenant and risks real users | [21](21-sandbox-tenant-and-nonprod-foundation.md)'s tenant; §6 runs in `twin_shell`, against `SANDBOX_ORG_ID`'s own sink ([24](24-eve-workspace-identity-and-audit-feeds.md)'s `EVE_TWIN_SINK`) |
| Sandbox events expected in the production organisation sink (X-ORG-02) | Workspace audit logs land in the **tenant's own** Cloud organisation; `--organization=$ORG_ID` never sees them | EV-6.1 asserts the twin sink's organisation is `SANDBOX_ORG_ID` and that the production datasets contain **no** sandbox rows |
| The drill performed and recorded by the person Eve watches | The proof is worthless if its subject runs it | The second human runs every verification; the platform owner's only action is the seeded one (§2) and the declared change (§5); a witness administrator uploads every record |

```mermaid
flowchart TD
  A["EV-0 Sitting, refusal gates, independent access"] --> B["EV-1 Seeded-action list, fixtures, freeze"]
  B --> C["EV-2 The blind proof (DR-28-1 run 1)"]
  A --> D["EV-3 Anti-silencing checks: eve/config, standing roles"]
  C --> E["EV-4 Witness part: one push withheld (G-2, DR-28-3)"]
  D --> F["EV-5 Anti-silencing drill under a declared grant (DR-28-2)"]
  E --> F
  A --> G["EV-6 Sandbox part by nonprod Eve (G-5, G-7)"]
  C --> H["EV-7 DRILL_CALENDAR rows DR-28-1 to DR-28-3"]
  F --> H
  G --> H
  H --> I["EV-8 EVE_H_LIVE_RECORD; interim rules decision"]
  I --> J["EV-9 Deviations, re-run index, gate rows"]
  J --> K["30 Wall-E starts"]
```

## Preconditions

- [ ] [23](23-eve-project-and-evidence-stores.md) to [27](27-witness-grants-and-alarms.md) complete, or their open steps indexed: `checkpoints.tsv` shows `DONE` for the closing step of each, and `EVE_FIRST_RUN_RECORD` is set and committed.
- [ ] [26](26-eve-reporting-and-witness-export.md): route 1 tested to the second human; `NOTIF_CH_EVE_EMAIL_SECOND_HUMAN` and `NOTIF_CH_EVE_SMS_SECOND_HUMAN` exist in `EVE_PROJECT`; the subject-report escalation `PAGER_SUBJECT_SERVICE_NAME` of [15](15-pager-siem-and-detections.md) part A is live, or the dated Cloud Monitoring deviation is open and named in the record.
- [ ] [27](27-witness-grants-and-alarms.md): the push is enabled, the first heartbeat has landed, and every witness alert policy **has seen data** (a metric-absence condition cannot fire before its first data point). `WITNESS_ALERT_FINGERPRINT` exists.
- [ ] [21](21-sandbox-tenant-and-nonprod-foundation.md): the sandbox tenant exists with two sandbox super admins; `SANDBOX_ORG_ID` set; the nonprod folder constraint admits `SANDBOX_CUSTOMER_ID`.
- [ ] [24](24-eve-workspace-identity-and-audit-feeds.md): `EVE_TWIN_SINK` created in the **sandbox** organisation to the twin dataset, with its seeded-event verify passed.
- [ ] [25](25-eve-human-super-admin-detections.md): the four production jobs and their twin counterparts deployed at `EVE_CODE_COMMIT` with green CI; `eve/config` has branch protection with `SECOND_HUMAN_EMAIL` as required reviewer; the platform owner's standing `actAs` on Eve's accounts removed.
- [ ] [12](12-privileged-access-catalogue.md): `PA-9.3` shows `DONE` (the organisation exception withdrawn). Checked again in EV-8.1; a missing `DONE` refuses `EVE_H_LIVE_RECORD`, not this file's drills.
- [ ] [06](06-organisation-bootstrap-and-roster.md): `OB-7.3` shows `DONE` (break-glass envelopes sealed); the interim activity rules A to D exist and their mail reaches the second human.
- [ ] Workstations: the **second human's** workstation has gcloud (with `alpha`), `bq`, `jq`, `python3.12`, `git` and the git host's CLI, her own `~/.platform-env` copy, and the browser profile of `sa-2-admin@`. The witness administrators use their own witness copies ([08](08-witness-organisation.md)). The platform owner's workstation is **not** used for any verification in this file.
- [ ] Two sittings booked: the proof review (EV-2.3 to EV-2.10, about two hours, second human and one witness administrator) and the sandbox drill (§6, half a day, second human and both sandbox super admins). The seeded window of EV-2.1 is **not** booked and **not** announced.
- [ ] **Not** a precondition: anything from [22](22-mo-foundations.md), [29](29-mo-eve-quality-pack.md) or any Wall-E file. Eve-H is proven without Mo and without Wall-E (SD-45).

## People needed

| Role | Does | Present at |
|---|---|---|
| Second human (`SECOND_HUMAN_EMAIL`, admin account `SA_2_ADMIN`; owner of `GRP_EVE_OWNERS`; IT security line) | Leads the file. Chooses the window and the action; performs every verification; approves the one grant of §5; signs `EVE_H_LIVE_RECORD`; decides on the interim rules | every step except EV-1.2, EV-2.2, EV-5.1, EV-5.2 |
| Platform owner (as `SA_1_ADMIN`) | Creates the proof fixtures (EV-1.2); performs the one seeded action (EV-2.2); requests and performs the declared change of §5; performs nothing else and verifies nothing | EV-1.2, EV-2.2, EV-3.1, EV-5.1, EV-5.2, EV-5.5 |
| Witness administrator 1 (`WITNESS_ADMIN_1_EMAIL`, working as `WITNESS_SA_1`) | Runs every witness-side query with the second human watching; uploads every drill record to `WITNESS_BUCKET` | EV-2.8, EV-2.10, EV-4.3, EV-4.5, EV-5.4, EV-5.6, EV-6.6 |
| Witness administrator 2 (`WITNESS_ADMIN_2_EMAIL`) | Confirms receipt of the witness alarms on a second device; countersigns the records | EV-4.3, EV-4.5, EV-5.4 |
| Sandbox super admin 1 (`SANDBOX_SA_1_EMAIL`) | Seeds the sandbox events (§6) in the sandbox tenant | EV-6.2, EV-6.3 |
| Sandbox super admin 2 (`SANDBOX_SA_2_EMAIL`) | Second actor for the roster diff; countersigns the sandbox record | EV-6.3, EV-6.6 |
| Incident commander (`INCIDENT_COMMANDER_EMAIL`) | Confirms the subject-report escalation behaved as signed in [15](15-pager-siem-and-detections.md); co-signs G-6 | EV-2.3, EV-9.3 |
| Security reviewer (`SECURITY_REVIEWER_EMAIL`), once named | Reads the residual-risk paragraph and countersigns `EVE_H_LIVE_RECORD`. Until named, the second human signs alone and EV-8.2 records the gap | EV-8.2 |

Hands-on: about 3 days spread over 2 to 4 weeks, because the blind window must be genuinely unannounced and the witness absence alarm needs a full window to fire. Elapsed: 3 to 4 weeks from EV-0.1 to `EVE_H_LIVE_RECORD`.

Conventions of [01](01-prerequisites-and-conventions.md) apply to every step: `checkpoint <id> START` before ACTION and `checkpoint <id> DONE <witness> <evidence>` after VERIFY; records named `<date>-<step>-<slug>-v<n>` under `BUILD_LOG_DIR/records/` (text) or `EVIDENCE_INTERIM_LOCATION` (screenshots and signed PDFs), each registered with `evidence_add`. Deviation rows use ids `BD-28-<n>`. With no default project, every gcloud call passes `--project`, `--folder` or `--organization`. Every shell block in this file, unless the step says otherwise, starts as:

```bash
source ~/.platform-env
penv_guard
R="$BUILD_LOG_DIR/records/$(date -u +%F)-EV"
```

**Who types what.** Steps whose WHO is the second human are typed on her workstation, signed in as her own account or `SA_2_ADMIN`. The platform owner must not type, dictate or watch a verification command in this file; if he does, the run is void and is repeated from EV-2.1 with a new window.

## Facts this file relies on, read on 2026-09-15

| Fact | Source | Consequence here |
|---|---|---|
| Admin log events: lag "Near real time (couple of minutes)", retention 6 months. User (login) log events: same lag. OAuth Token log events: "A couple of hours". Groups: "Tens of minutes (can also go up to a couple of hours)". SAML: near real time | Workspace admin help, *Data retention and lag times for Google services* | The seeded actions of §1 are all **admin** application events, the only stream fast enough for a same-sitting proof; a token or groups event would make a lag-budget failure meaningless. EV-1.1 records the published lag beside Eve's budget |
| `activities.list` path `GET .../activity/users/{userKey or all}/applications/{applicationName}`; `applicationName` includes `admin`, `login`, `token`, `groups`, `saml`, `access_transparency`; query parameters `eventName`, `startTime`, `endTime`, `filters`, `actorIpAddress`, `maxResults` | Reports API v1, `activities.list` reference | Eve's poll by actor (25) is expected to carry `application`, `event_name` and `actor` columns; EV-2.5 reads the committed schema at `EVE_SCHEMAS_COMMIT` rather than assuming column names |
| Delegated admin settings events: `ASSIGN_ROLE`, `CREATE_ROLE`, `DELETE_ROLE`, `ADD_PRIVILEGE`, `REMOVE_PRIVILEGE`, `RENAME_ROLE`, `UPDATE_ROLE`, `UNASSIGN_ROLE`, with parameters `USER_EMAIL`, `ROLE_NAME`, `ROLE_ID`, `ORG_UNIT_NAME`, `PRIVILEGE_NAME`, `NEW_VALUE` | Reports API appendix, admin activity events, delegated admin settings | Seeded actions 1, 4 and 5 of §1 and their exact expected `eventName` values |
| Org unit settings events: `CREATE_ORG_UNIT` (`ORG_UNIT_NAME`), `EDIT_ORG_UNIT_NAME` (`ORG_UNIT_NAME`, `NEW_VALUE`), `EDIT_ORG_UNIT_DESCRIPTION` (`ORG_UNIT_NAME`), `MOVE_ORG_UNIT`, `REMOVE_ORG_UNIT`; all `type=ORG_SETTINGS` | Reports API appendix, admin activity events, org settings | Seeded actions 2 and 3 |
| Workspace audit logs are provided **at the Google Cloud organisation level** of that Workspace customer; admin audit is an Admin Activity log (`admin.googleapis.com`), login and SAML are Data Access logs (`login.googleapis.com`), OAuth token produces both (`oauth2.googleapis.com`), enterprise groups is `cloudidentity.googleapis.com` | Cloud Logging, *Audit logs for Google Workspace* | EV-2.4 queries the `cloudaudit_googleapis_com_activity` table with `serviceName = "admin.googleapis.com"`; EV-6.1 proves the sandbox tenant's events reach only `SANDBOX_ORG_ID`'s sink (X-ORG-02) |
| Audit-log entries can be filtered on `protoPayload.metadata.event.eventName` with `resource.type="audited_resource"`; the Workspace event sits in `protoPayload.metadata` | Cloud Logging audit documentation and the Workspace log samples | The filters of EV-2.4 and EV-6.2; in BigQuery the same field is the JSON string `protopayload_auditlog.metadataJson` (*Assumption*, checked by printing one raw row first) |
| Admin console: Menu → Reporting → Audit and investigation → Admin log events | Workspace admin help, *Admin log events* | The second human's independent read, which needs no Eve component and no platform-owner help |
| `gcloud pam grants create --entitlement= --location= [--project|--folder|--organization] --requested-duration= [--justification] [--additional-email-recipients]`; `gcloud pam grants approve GRANT --entitlement= --location= --reason=`; `gcloud pam grants list --entitlement= --location=` | gcloud PAM reference | The declared grant of §5 and the anti-collusion check of EV-2.7 |
| `gcloud scheduler jobs pause JOB --location=` and its `resume` counterpart | gcloud Scheduler reference | EV-4.2 and EV-5.2 |
| `gcloud monitoring` has `dashboards`, `policies`, `snoozes` and `uptime`; **no command lists alerting incidents** | gcloud Monitoring reference | The second human reads incidents in the Monitoring console and, above all, on her own device and in the paging service; a row Eve wrote is never the proof that a page arrived |
| A metric-absence condition is not met until the measured stream has written at least one data point; the longest window is 23.5 hours | Cloud Monitoring, metric absence | EV-4.1 refuses the withhold drill until [27](27-witness-grants-and-alarms.md)'s alarms show data |
| Under a **locked** retention policy the policy can never be removed or shortened, and objects cannot be deleted until they meet the retention period | Cloud Storage bucket lock | The four upload steps are **IRREVERSIBLE**; §10 says what to confirm before each |
| `gcloud storage ls [--recursive|-r] [--long|-l] [--json|-j]`, `--project` available as a wide flag | gcloud Storage reference | The witness-side listing of EV-2.8 |

## 0. The sitting, the gates and independent access

### EV-0.1 Open the sitting and read the inputs

- **WHO:** Second human, on her own workstation, signed in as her own account.
- **WHERE:** Shell, her copy of `~/.platform-env` sourced.
- **ACTION:**

```bash
checkpoint EV-0.1 START
need ORG_ID DOMAIN DIRECTORY_CUSTOMER_ID REGION BQ_LOCATION BUILD_LOG_DIR PLATFORM_REPO_DIR DRILL_CALENDAR DEVIATION_REGISTER EVIDENCE_REGISTER \
     EVE_PROJECT EVE_DS EVE_WS_LOGS_DS EVE_WS_REPORTS_DS EVE_EVIDENCE_BUCKET EVE_SCHEMAS_COMMIT EVE_CODE_COMMIT EVE_CONFIG_REPO \
     EVE_ROBOT EVE_SINK EVE_TWIN_SINK EVE_TWIN_ROBOT EVE_TWIN_PROJECT EVE_JOB_REPORTS_POLL EVE_JOB_ROSTER EVE_JOB_DETECT EVE_JOB_HEARTBEAT \
     SA_EVE_EXPORT EVE_JOB_EXPORT EVE_JOB_HEARTBEAT_PUSH EVE_INCIDENTS_TABLE EVE_PAGES_TABLE EVE_FIRST_RUN_RECORD \
     NOTIF_CH_EVE_EMAIL_SECOND_HUMAN NOTIF_CH_EVE_SMS_SECOND_HUMAN PAGER_SUBJECT_SERVICE_NAME \
     EVE_WITNESS_PROJECT WITNESS_MIRROR_DS WITNESS_HEARTBEAT_TABLE WITNESS_BUCKET \
     SANDBOX_DOMAIN SANDBOX_CUSTOMER_ID SANDBOX_ORG_ID ROSTER_FILE SA_1_ADMIN SA_2_ADMIN OWNER_DAILY_ACCOUNT GRP_EVE_OWNERS GRP_EVE_CONSOLE_READERS ENT_PROJECT_REPAIR_EVE \
     SA_EVE_VERIFIER SA_EVE_CONSOLE EVE_REFRESH_TOKEN_SECRET_NAME EVE_TOKEN_VERSION EVE_CONSOLE_URL SECOND_HUMAN_EMAIL \
     WITNESS_ADMIN_1_EMAIL WITNESS_ADMIN_2_EMAIL SANDBOX_SA_1_EMAIL SANDBOX_SA_2_EMAIL BUSINESS_TZ
printf 'reports about the second human go to: '; printenv SECURITY_REVIEWER_EMAIL || printenv INCIDENT_COMMANDER_EMAIL || echo "NOBODY NAMED: see README B-12"
awk -F'\t' '$2 ~ /^(EP|EW|EH|ER|WG)-/ && $3 == "DONE" {n[substr($2,1,2)]++} END {for (p in n) print p, n[p]}' "$BUILD_LOG_DIR/checkpoints.tsv"
awk -F'\t' '$3 == "BLOCKED" {print $2"\t"$7}' "$BUILD_LOG_DIR/checkpoints.tsv" | sort -u
test -s "$PLATFORM_REPO_DIR/$EVE_FIRST_RUN_RECORD" && echo "EVE_FIRST_RUN_RECORD present"
test -z "$(gcloud config get project 2>/dev/null)" && echo "no default project"
```

- **VERIFY:** Each of the five Eve prefixes shows at least one `DONE`; the `EVE_FIRST_RUN_RECORD` file exists; `no default project`. Read the BLOCKED list: `B-08` and `B-09` entries are expected and decide whether §5 and §6 run in full or are recorded BLOCKED here; a BLOCKED step in 26 or 27 that has not been replaced by a dated deviation stops the file.
- **ROLLBACK:** Read only.
- **EVIDENCE:** The output as `${R}-0.1-inputs-v1.txt`; `evidence_add EV-0.1 inputs E-05 1.4.1 build-log:records/<file> <file>`. E-05. TISAX 1.4.1.

### EV-0.2 Read the three refusal gates now, not at the end

- **WHO:** Second human.
- **WHERE:** Shell; `BUILD_LOG_DIR/checkpoints.tsv`.
- **ACTION:** SD-12 items 7 and 8 make `EVE_H_LIVE_RECORD` conditional on three facts that belong to other files. They are read here so that a gap is known before three weeks of drills, and read again in EV-8.1.

```bash
for S in PA-9.3 OB-7.3 OB-2.9; do
  printf '%s\t' "$S"; awk -F'\t' -v s="$S" '$2==s {print $3" "$1}' "$BUILD_LOG_DIR/checkpoints.tsv" | tail -1
done
awk -F'\t' '$2 ~ /^WG-/ && $3 == "DONE" {print $2"\t"$7}' "$BUILD_LOG_DIR/checkpoints.tsv"
```

  Then ask witness administrator 1 for the state of the four alert policies: each must have **seen data** (27's own verify), not merely exist.
- **VERIFY:** `PA-9.3 DONE` (the organisation exception withdrawn), `OB-7.3 DONE` and `OB-2.9 DONE` (break-glass and admin envelopes sealed), and the witness administrator's written statement that `WITNESS_ALERT_HEARTBEAT`, `WITNESS_ALERT_EXPORT`, `WITNESS_ALERT_INCIDENT` and `WITNESS_ALERT_FINGERPRINT` have each received at least one measurement. A gap is recorded, the drills continue, and EV-8.1 refuses the record until it closes.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-0.2-refusal-gates-v1.txt` with the witness statement attached. E-05. TISAX 1.4.1.

### EV-0.3 Prove the second human can see Eve and the witness without the platform owner

- **WHO:** Second human; witness administrator 1 for the witness half.
- **WHERE:** Shell; browser profile of `SA_2_ADMIN`; the witness administrator's own shell.
- **ACTION:** The proof is worth nothing if she has to ask the subject for access.

```bash
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json \
  | jq -r --arg g "group:$GRP_EVE_OWNERS" '.bindings[] | select(.members[]? == $g) | .role'
bq query --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" --use_legacy_sql=false --format=csv \
  'SELECT COUNT(*) AS n FROM `'"$EVE_PROJECT"'.'"$EVE_DS"'.INFORMATION_SCHEMA.TABLES`'
gcloud scheduler jobs list --project="$EVE_PROJECT" --location="$REGION" --format='table(name,state,schedule)'
```

  In the browser: open the Admin console as `SA_2_ADMIN` → Menu → Reporting → Audit and investigation → Admin log events, and confirm the search returns results. Witness administrator 1 runs, in the witness organisation, a `SELECT` of the last five heartbeat rows and a `gcloud storage ls -l "gs://$WITNESS_BUCKET/exports/"`, with the second human watching the screen.
- **VERIFY:** `GRP_EVE_OWNERS` holds at least `roles/bigquery.dataViewer` and `roles/bigquery.jobUser` (or the reader role 23 granted); the count query returns; the scheduler list prints the four jobs and their state. The Admin console search returns rows. The witness queries return rows. Any missing read is a **re-run line against [23](23-eve-project-and-evidence-stores.md)** (`rerun-index.tsv`, member `group:$GRP_EVE_OWNERS`), not a grant made here, and until it is closed the second human uses `EVE_CONSOLE_URL` behind IAP as her read path and says so in the record.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-0.3-independent-access-v1.txt` plus one console screenshot to `EVIDENCE_INTERIM_LOCATION`. E-06. TISAX 4.2.1.

### EV-0.4 Agree what may be announced, and what may not

- **WHO:** Second human; the platform owner is told only the parts that concern him.
- **WHERE:** A short written note, committed to the build log.
- **ACTION:** Write and have both parties initial a note stating: (a) the platform owner is told **that** a proof will happen in the next 30 days and that he will be asked to perform exactly one action from the committed list; (b) he is **not** told the date, the hour or which action, until the moment of EV-2.1; (c) he will not query Eve, the witness, the paging service or the audit log about the proof, and will not open a PAM grant on `EVE_PROJECT` during the window; (d) if he is paged for anything unrelated during the window he answers it normally and tells the second human afterwards; (e) the drill is announced to nobody else, including the IT security desk, because the subject-report escalation is exercised exactly as it would be in earnest.
- **VERIFY:** Both initials on the note; the note names the 30-day span and nothing more precise.
- **ROLLBACK:** Tear up and rewrite before EV-2.1; after EV-2.1 the note is part of the record.
- **EVIDENCE:** `${R}-0.4-blind-window-note-v1.pdf` in `EVIDENCE_INTERIM_LOCATION`. E-08. TISAX 5.2.6.

## 1. The seeded-action list and the proof fixtures

### EV-1.1 Commit the seeded-action list

- **WHO:** Second human writes; a second reviewer approves under branch protection; the platform owner does **not** review it.
- **WHERE:** `PLATFORM_REPO_DIR`, branch `eve-proof-actions`, then `PLATFORM_REPO_REMOTE`.
- **ACTION:** Five actions, all in the `admin` application (the only stream whose published lag is minutes), all reversible, none touching a real user, a real role assignment or a production setting. `PRIV` is any harmless read privilege chosen at EV-1.2 and recorded there.

```bash
mkdir -p "$PLATFORM_REPO_DIR/eve"
cat > "$PLATFORM_REPO_DIR/eve/seeded-actions.md" <<'LIST'
# Seeded super-admin actions for Eve's independent proof

Owner: the second human. Changed only by a reviewed pull request that the platform owner does
not review. One action is chosen per proof; which one, and when, is never announced.

| # | Action, performed in the Admin console by the platform owner as sa-1-admin@ | Expected Admin log event(s) | Reversal | Touches a real object? |
|---|---|---|---|---|
| 1 | Add privilege PRIV to the custom role EVE_PROOF_ROLE, then remove it | ADD_PRIVILEGE then REMOVE_PRIVILEGE (parameters ROLE_NAME, PRIVILEGE_NAME) | the removal is part of the action | no: the role is assigned to nobody |
| 2 | Edit the description of the OU EVE_PROOF_OU to the drill token, then restore it | EDIT_ORG_UNIT_DESCRIPTION (parameter ORG_UNIT_NAME) | restore the previous description | no: the OU holds only EVE_PROOF_ACCOUNT |
| 3 | Create a child OU under EVE_PROOF_OU named with the drill token, then remove it | CREATE_ORG_UNIT then REMOVE_ORG_UNIT (parameter ORG_UNIT_NAME) | the removal is part of the action | no |
| 4 | Rename EVE_PROOF_ROLE to the drill token, then rename it back | RENAME_ROLE (parameters ROLE_NAME, NEW_VALUE) | the second rename | no |
| 5 | Assign EVE_PROOF_ROLE (zero privileges) to EVE_PROOF_ACCOUNT, then unassign it | ASSIGN_ROLE then UNASSIGN_ROLE (parameters ROLE_NAME, USER_EMAIL) | the unassignment is part of the action | no: a role with no privileges on a proof account |

Google's published lag for Admin log events is "near real time (couple of minutes)"
(admin help, Data retention and lag times, read 2026-09-15). Eve's own budget per application
is in thresholds.yaml of the eve/config repository; the drill uses Eve's budget, and records
both numbers.

Never on this list: anything that changes a real user's access, a tenant-wide security setting,
a super-admin assignment, an OU that holds real users, or anything a rollback cannot undo in
the same sitting.
LIST
git -C "$PLATFORM_REPO_DIR" checkout -b eve-proof-actions
git -C "$PLATFORM_REPO_DIR" add eve/seeded-actions.md
git -C "$PLATFORM_REPO_DIR" commit -m "setup 28 EV-1.1: seeded-action list for Eve's independent proof"
git -C "$PLATFORM_REPO_DIR" push -u origin eve-proof-actions
penv_set SEEDED_ACTION_LIST "eve/seeded-actions.md"
```

- **VERIFY:** The pull request is merged with one approval that is not the platform owner's; `git -C "$PLATFORM_REPO_DIR" log --oneline -1 -- eve/seeded-actions.md` shows the merge; `SEEDED_ACTION_LIST` is set.
- **ROLLBACK:** `git revert` the merge before EV-2.1.
- **EVIDENCE:** The merge commit and the approvals page as `${R}-1.1-seeded-actions-v1`. E-08. TISAX 5.2.6.

### EV-1.2 Create the proof fixtures

- **WHO:** Platform owner as `SA_1_ADMIN`; second human present (in person or on a shared screen) and recording.
- **WHERE:** Admin console, signed in as `SA_1_ADMIN`: Menu → Account → Admin roles, and Menu → Directory → Organizational units, Menu → Directory → Users.
- **ACTION:** These objects are created **now**, well before any window, so that their creation is not confused with a seeded action.
  1. Create an organisational unit `Eve-Proof` under `/Automation` (path `/Automation/Eve-Proof`), description `fixtures for Eve's independent proof; no real users`.
  2. Create a user `zz-eve-proof@$DOMAIN` in that OU: no licence beyond what the tenant assigns automatically, suspended immediately after creation, never signed in, never given a role other than the proof role.
  3. Create a custom admin role named `zz-eve-proof-role`, description `drill fixture; assigned to nobody in normal state`, **with no privileges selected**. If the console refuses a role with zero privileges, select exactly one harmless read privilege, record which, and make that the role's normal state.
  4. Choose `PRIV` for action 1: a read-only privilege the role does not already hold (for example an "Organizational Units → Read" privilege). Record the exact label shown in the console.
  5. Record the three names.

```bash
penv_set EVE_PROOF_OU "/Automation/Eve-Proof"
penv_set EVE_PROOF_ACCOUNT "zz-eve-proof@$DOMAIN"
penv_set EVE_PROOF_ROLE "zz-eve-proof-role"
```

- **VERIFY:** The second human, from her own browser as `SA_2_ADMIN`, sees the OU with one suspended user and the role with its recorded privilege set, and confirms the role appears in no assignment. She also confirms in Admin log events that the four creation events (`CREATE_ORG_UNIT`, a user-creation event, `CREATE_ROLE`, and any `ADD_PRIVILEGE`) are present — which is itself a first, non-blind sanity check that the stream is alive.
- **ROLLBACK:** Delete the role, the user and the OU in that order. Deleting them removes nothing Eve has already recorded.
- **EVIDENCE:** Screenshots of the three objects and the privilege label as `${R}-1.2-proof-fixtures-v1` in `EVIDENCE_INTERIM_LOCATION`; the three variable names in the build log. E-08. TISAX 4.2.1.

### EV-1.3 Read Eve's coverage of the chosen classes, and set the mode

- **WHO:** Second human.
- **WHERE:** Shell, a clone of `EVE_CONFIG_REPO` at its merged head.
- **ACTION:** The proof has two modes. **Full mode**: the detection catalogue covers the class of the chosen action, so a page is expected. **Evidence mode**: it does not, so only the two rows and the witness copy are expected. `EVE_H_LIVE_RECORD` is written only after a run in full mode (EV-8.1).

```bash
git clone "$EVE_CONFIG_REPO" "$HOME/eve-config" 2>/dev/null || git -C "$HOME/eve-config" pull --ff-only
grep -n -E 'ADD_PRIVILEGE|REMOVE_PRIVILEGE|RENAME_ROLE|ASSIGN_ROLE|UNASSIGN_ROLE|ORG_UNIT|DELEGATED_ADMIN_SETTINGS|ORG_SETTINGS' \
  "$HOME/eve-config"/detections/*.y*ml "$HOME/eve-config"/thresholds.yaml 2>/dev/null
python3 - "$HOME/eve-config/thresholds.yaml" <<'PY'
import sys
try:
    import yaml
except ImportError:
    sys.exit("PyYAML absent: read thresholds.yaml by eye and copy the admin budget into the record")
t = yaml.safe_load(open(sys.argv[1]))
print("lag budgets:", (t.get("lag_budgets") or t.get("thresholds", {}).get("lag_budgets")))
PY
```

- **VERIFY:** The grep shows at least one rule whose actor set is "any roster human" and whose event set contains the class of at least one listed action; the lag budget for the `admin` application prints a number. Record `MODE=full` with the rule id, or `MODE=evidence` with a re-run line owned by the Eve owner against README B-09.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-1.3-coverage-and-mode-v1.txt`. E-05. TISAX 1.4.1.

### EV-1.4 Freeze Eve's configuration for the window

- **WHO:** Second human declares; the platform owner acknowledges in writing.
- **WHERE:** The note of EV-0.4; `EVE_CONFIG_REPO`.
- **ACTION:** From this step until EV-2.10 closes: no merge to `eve/config`, no PAM grant on `EVE_PROJECT`, no change to the schedules, no redeploy. A genuine operational need during the freeze is met, and the run is restarted from EV-2.1 with a new window; the need and the restart are both recorded. The second human records the head commit of `eve/config` and the current fingerprint from the last heartbeat row so that any change is visible afterwards.

```bash
git -C "$HOME/eve-config" rev-parse HEAD | tee "$R-1.4-config-head.txt"
```

  Witness administrator 1 records, from the witness side, the latest heartbeat row's configuration fingerprint and cumulative counts, and gives the second human a copy. The platform owner is not shown either value.
- **VERIFY:** The commit id and the fingerprint are written down before the window opens.
- **ROLLBACK:** Lift the freeze by writing a dated line in the record.
- **EVIDENCE:** `${R}-1.4-freeze-v1.txt` with the fingerprint attached. E-06. TISAX 5.2.4.

## 2. The blind proof (DR-28-1, run 1)

This section is the owner's question — *does Eve actually watch the human super admin?* — answered by the only person who can answer it.

### EV-2.1 Open the window and name the action

- **WHO:** Second human alone.
- **WHERE:** Any channel she chooses; the time is recorded from her own device.
- **ACTION:** At a moment of her choosing inside the 30-day span, and with no prior notice, she sends the platform owner one message: "Perform seeded action *k* now, and nothing else. Reply with the exact UTC minute when you have finished." She records, on paper or in a private note: the UTC time she sent it, *k*, and the drill token (`eve-proof-<YYYYMMDD-HHMM>`) she will look for in the event parameters.
- **VERIFY:** Her note exists before the platform owner's reply. The chosen hour is inside business hours in `BUSINESS_TZ` for the first run (an out-of-hours run is a later drill, recorded as such, because H-1's business-hours rule changes the expected route).
- **ROLLBACK:** Not applicable; a cancelled window is simply not used and a new one chosen.
- **EVIDENCE:** Her note, scanned after EV-2.10, as part of `${R}-2.10-proof-record-v1`. E-08. TISAX 5.2.6.

### EV-2.2 The seeded action

- **WHO:** Platform owner as `SA_1_ADMIN`, alone, from his normal workstation and browser profile.
- **WHERE:** Admin console, the path the chosen action needs (Menu → Account → Admin roles, or Menu → Directory → Organizational units).
- **ACTION:** Perform action *k* from `SEEDED_ACTION_LIST` exactly as written, using the drill token as the new value where the action has one (the OU description, the child OU name, the role's temporary name). Note the UTC minute of each half of the action. Reverse it as the list prescribes. Perform nothing else in the console during the window: no other change, no audit search, no query against Eve, no grant request.
- **VERIFY:** He replies to the second human with the two UTC minutes and the token used, and nothing else. He does **not** check whether Eve noticed.
- **ROLLBACK:** The reversal is part of the action. If he mistypes and produces an extra event, he says so in the same reply; the extra event becomes part of the expected set and the run continues.
- **EVIDENCE:** His reply, kept by the second human; the console screenshots are **not** taken by him (they would be his evidence, not hers). E-08. TISAX 5.2.6.

### EV-2.3 The page, on her own device

- **WHO:** Second human; the incident commander confirms the escalation's behaviour afterwards.
- **WHERE:** Her phone and mailbox; the paging service `PAGER_SUBJECT_SERVICE_NAME`; Cloud Monitoring console of `EVE_PROJECT` (Alerting) as a cross-check.
- **ACTION:** Wait for Eve's budget from EV-1.3 plus the published Google lag, and record what arrived and when:
  1. the page on the subject-report escalation of [15](15-pager-siem-and-detections.md) — time received, severity, subject, the text of the finding, whether the platform owner is named as subject;
  2. the email on `NOTIF_CH_EVE_EMAIL_SECOND_HUMAN` and, for a severity 1, the SMS on `NOTIF_CH_EVE_SMS_SECOND_HUMAN`;
  3. the acknowledgement she gives in the paging service, and its timestamp;
  4. in the Monitoring console, the incident for the policy that fired (there is no gcloud command that lists incidents, so this is a console read).
- **VERIFY:** In **full mode**: at least one of (1) and (2) arrived within the budget, the subject is the platform owner, and the recipient set contains her and nobody in the administration line — in particular the platform owner is not a recipient and is not a responder on that escalation (SD-12 item 10). In **evidence mode**: nothing arrives, which is the expected result, and the record says so. Either way she records the observed delta in minutes between the seeded minute and the page.
- **ROLLBACK:** None; acknowledge and close the page in the paging service as a drill.
- **EVIDENCE:** Screenshots of the page, the mail headers and the acknowledgement, as `${R}-2.3-page-v1` in `EVIDENCE_INTERIM_LOCATION`. E-10. TISAX 1.6.2.

### EV-2.4 The `eve_workspace_logs` row

- **WHO:** Second human.
- **WHERE:** Shell on her workstation; and the Admin console for the independent read.
- **ACTION:** First the independent read that needs no Eve component: Menu → Reporting → Audit and investigation → Admin log events, filtered on the event name of action *k* and the drill token, as `SA_2_ADMIN`. Then Eve's copy:

```bash
T0='2026-__-__T__:__:00Z'   # the minute the platform owner reported
bq query --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" --use_legacy_sql=false --format=prettyjson \
 'SELECT TO_JSON_STRING(t) AS raw
  FROM `'"$EVE_PROJECT"'.'"$EVE_WS_LOGS_DS"'.cloudaudit_googleapis_com_activity` t
  WHERE timestamp >= TIMESTAMP("'"$T0"'") - INTERVAL 10 MINUTE
    AND protopayload_auditlog.serviceName = "admin.googleapis.com"
  ORDER BY timestamp LIMIT 3'
bq query --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" --use_legacy_sql=false --format=csv \
 'SELECT timestamp,
         protopayload_auditlog.authenticationInfo.principalEmail AS actor,
         JSON_VALUE(protopayload_auditlog.metadataJson, "$.event[0].eventName") AS event_name,
         JSON_VALUE(protopayload_auditlog.metadataJson, "$.event[0].eventType") AS event_type
  FROM `'"$EVE_PROJECT"'.'"$EVE_WS_LOGS_DS"'.cloudaudit_googleapis_com_activity`
  WHERE timestamp BETWEEN TIMESTAMP("'"$T0"'") - INTERVAL 10 MINUTE AND TIMESTAMP("'"$T0"'") + INTERVAL 60 MINUTE
    AND protopayload_auditlog.serviceName = "admin.googleapis.com"
  ORDER BY timestamp'
```

  The first query prints a whole row so that the field path can be corrected by eye if the export schema differs; the second is the assertion. *Assumption:* the Workspace event object is carried in `protopayload_auditlog.metadataJson` as JSON with an `event` array. If the raw row shows another shape, rewrite the second query from the raw row and record the correction in the deviation register as `BD-28-<n>`.
- **VERIFY:** A row exists whose `actor` is `SA_1_ADMIN` and whose `event_name` is the expected event of action *k*, within Eve's sink budget of the seeded minute. The reversal's event is there too. **Absence of any `walle@` row in this window is expected and is never a reason to delete or recreate the sink** — sinks do not backfill, and the robot holds no admin role before the grant (S141).
- **ROLLBACK:** Read only.
- **EVIDENCE:** Both query outputs and the Admin console screenshot as `${R}-2.4-ws-logs-v1`. E-06. TISAX 5.2.4.

### EV-2.5 The `eve_workspace_reports` row

- **WHO:** Second human.
- **WHERE:** Shell.
- **ACTION:** The Reports poll by actor is a second, independent path over the same event: it reaches the admin application through the Reports API rather than the sink, so a broken sink filter and a broken poll cannot hide each other. Read the committed schema first, so no column name is invented:

```bash
git -C "$PLATFORM_REPO_DIR" show "$EVE_SCHEMAS_COMMIT" --stat | grep -i report
bq show --schema --format=prettyjson "$EVE_PROJECT:$EVE_WS_REPORTS_DS.activities" | jq -r '.[].name'
bq query --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" --use_legacy_sql=false --format=csv \
 'SELECT * EXCEPT(raw)
  FROM `'"$EVE_PROJECT"'.'"$EVE_WS_REPORTS_DS"'.activities`
  WHERE actor = "'"$SA_1_ADMIN"'"
    AND ts BETWEEN TIMESTAMP("'"$T0"'") - INTERVAL 10 MINUTE AND TIMESTAMP("'"$T0"'") + INTERVAL 2 HOUR
  ORDER BY ts'
```

  If the schema names the columns differently, use the printed names; the step's requirement is the content, not the spelling.
- **VERIFY:** At least one row for actor `SA_1_ADMIN`, application `admin`, with the event name of action *k*, inside the poll budget (poll period plus the published lag). She records the observed delta. She also confirms that the table holds rows for **other** roster accounts in the same day, which proves the poll is by actor over the union of the roster and the live admin-role holders and not a one-account fixture.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-2.5-ws-reports-v1.csv` and the schema listing. E-06. TISAX 5.2.4. This output, with EV-2.4's, is the production half of **G-4** under SD-03.

### EV-2.6 The `eve.incidents` and `eve.pages` rows and the sole recipient

- **WHO:** Second human.
- **WHERE:** Shell.
- **ACTION:**

```bash
bq query --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" --use_legacy_sql=false --format=prettyjson \
 'SELECT * FROM `'"$EVE_PROJECT"'.'"$EVE_DS"'.'"${EVE_INCIDENTS_TABLE##*.}"'`
  WHERE detected_at >= TIMESTAMP("'"$T0"'") - INTERVAL 10 MINUTE ORDER BY detected_at'
bq query --project_id="$EVE_PROJECT" --location="$BQ_LOCATION" --use_legacy_sql=false --format=prettyjson \
 'SELECT * FROM `'"$EVE_PROJECT"'.'"$EVE_DS"'.'"${EVE_PAGES_TABLE##*.}"'`
  WHERE sent_at >= TIMESTAMP("'"$T0"'") - INTERVAL 10 MINUTE ORDER BY sent_at'
```

- **VERIFY:** In full mode, one incident row whose subject is `SA_1_ADMIN`, whose rule id matches EV-1.3's rule, and whose `halt_target` field records `halt_target_pending` (no halt target exists before Wall-E, SD-10); one page row whose recipient set is exactly the sole recipient for a report about the platform owner — the second human — plus the subject-report escalation, and which contains **no** address inside the administration line. Cross-check the page row's recipients against what actually arrived in EV-2.3: a page row that names a recipient who received nothing, or an arrival at an address no row names, is a severity-1 finding on the reporting contract and stops the file. In evidence mode both queries return nothing and the record says so.
- **ROLLBACK:** Read only. The rows stay; they are evidence, and Eve's writer roles cannot delete them (SD-43).
- **EVIDENCE:** `${R}-2.6-incident-and-page-v1.json`. E-10. TISAX 1.6.2. This is the production half of **G-6**.

### EV-2.7 Nobody touched Eve during the window

- **WHO:** Second human.
- **WHERE:** Shell.
- **ACTION:** The anti-collusion check: prove that the result was not arranged.

```bash
git -C "$HOME/eve-config" fetch --all && git -C "$HOME/eve-config" rev-parse origin/HEAD
diff <(cat "$R-1.4-config-head.txt") <(git -C "$HOME/eve-config" rev-parse origin/HEAD) && echo "eve/config unchanged during the window"
gcloud pam grants list --entitlement="$ENT_PROJECT_REPAIR_EVE" --location=global \
  --format='table(name,requester,state,requestedDuration,createTime)'
gcloud scheduler jobs list --project="$EVE_PROJECT" --location="$REGION" --format='table(name,state,lastAttemptTime)'
gcloud logging read 'protoPayload.serviceName="cloudscheduler.googleapis.com" OR protoPayload.serviceName="run.googleapis.com" OR protoPayload.serviceName="logging.googleapis.com"' \
  --project="$EVE_PROJECT" --freshness=1d --limit=50 --format='table(timestamp,protoPayload.authenticationInfo.principalEmail,protoPayload.methodName)'
```

- **VERIFY:** `eve/config unchanged during the window`; no PAM grant on `ENT_PROJECT_REPAIR_EVE` was created or approved inside the window (she is the approver, so any grant would have needed her, but the list is read anyway); every scheduler job is `ENABLED`; the admin-activity read shows no write by `SA_1_ADMIN` in `EVE_PROJECT` during the window. Any exception voids the run: it is recorded, the cause is investigated as a finding, and the proof is repeated with a new window.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-2.7-no-interference-v1.txt`. E-06. TISAX 4.2.1.

### EV-2.8 The witness copy

- **WHO:** Witness administrator 1 types; the second human watches; the platform owner is absent.
- **WHERE:** The witness administrator's own workstation, witness organisation.
- **ACTION:**

```bash
bq query --project_id="$EVE_WITNESS_PROJECT" --use_legacy_sql=false --format=prettyjson \
 'SELECT * FROM `'"$EVE_WITNESS_PROJECT"'.'"$WITNESS_MIRROR_DS"'.'"$WITNESS_HEARTBEAT_TABLE"'`
  ORDER BY ts DESC LIMIT 6'
gcloud storage ls -l "gs://$WITNESS_BUCKET/exports/**" | tail -20
gcloud storage cat "gs://$WITNESS_BUCKET/exports/<the export covering T0>/MANIFEST.sha256" | head
```

- **VERIFY:** A heartbeat row exists for the hour containing `T0`; its cumulative per-table counts for the incidents, pages and `eve_workspace_reports` tables are **greater than** the values witness administrator 1 recorded at EV-1.4; its configuration fingerprint is **unchanged** from EV-1.4; and the export covering `T0` contains the finding, with a manifest whose SHA-256 matches the object. The second human reads the values herself from the screen and copies them into her record.
- **ROLLBACK:** Read only.
- **EVIDENCE:** The three outputs, exported by the witness administrator to `${R}-2.8-witness-copy-v1.txt` in the witness organisation's own record area. E-06. TISAX 5.2.4. This is the witness half of **G-2**.

### EV-2.9 The reversal is reported too

- **WHO:** Second human.
- **WHERE:** Shell.
- **ACTION:** Repeat the queries of EV-2.4 and EV-2.5 for the reversal half of action *k* (the `REMOVE_PRIVILEGE`, the second `RENAME_ROLE`, the `REMOVE_ORG_UNIT`, the `UNASSIGN_ROLE`, or the restored description).
- **VERIFY:** Both rows exist. A pipeline that reports the change but not the undo would let an administrator hide the shape of what he did; this step is the check that it does not.
- **ROLLBACK:** Read only.
- **EVIDENCE:** Appended to `${R}-2.4-ws-logs-v1` and `${R}-2.5-ws-reports-v1`. E-06. TISAX 5.2.4.

### EV-2.10 The record, uploaded by the witness

- **WHO:** Second human writes and signs; witness administrator 1 uploads; witness administrator 2 countersigns.
- **WHERE:** `BUILD_LOG_DIR/records/`, then `gs://$WITNESS_BUCKET/drills/`.
- **ACTION:** **IRREVERSIBLE** — the witness bucket's retention policy is locked, so the uploaded object cannot be deleted before its retention period ends. Before uploading, confirm: the date in the name is today's; the version suffix is not already used (`gcloud storage ls "gs://$WITNESS_BUCKET/drills/"`); the file contains no secret, no key material, no personal data beyond the named administrators the DPO record of SD-11 covers.

```bash
cat > "$R-2.10-proof-record-v1.md" <<'REC'
# Eve independent proof — run 1

- Date, window opened (UTC): ...
- Mode: full | evidence (EV-1.3 rule id: ...)
- Seeded action: # ... ; drill token: ...
- Performed by: sa-1-admin@ at ...:...Z; reversed at ...:...Z
- Page received by the second human: yes/no, at ...:...Z, delta ... minutes, severity ...
- Sole recipient respected: yes/no (recipients observed: ...)
- eve_workspace_logs row: yes/no, delta ... minutes
- eve_workspace_reports row: yes/no, delta ... minutes; other roster actors present: yes/no
- eve.incidents / eve.pages rows: ... / ...; halt_target: halt_target_pending
- Witness heartbeat for the hour: counts increased, fingerprint unchanged: yes/no
- Witness export containing the finding: object ..., manifest verified: yes/no
- Interference check (EV-2.7): clean / voided because ...
- Residual risk paragraph of this file read and accepted: second human ..., security reviewer ...
- Signatures: second human ...; witness administrator 1 ...; witness administrator 2 ...
REC
penv_set EVE_PROOF_RECORD "records/$(basename "$R-2.10-proof-record-v1.md")"
```

  The witness administrator then uploads it as `gs://$WITNESS_BUCKET/drills/<date>-eve-independent-proof-v1.md` and returns the object's generation number and hash. The platform owner is given the fact that the drill passed, and nothing else.
- **VERIFY:** `gcloud storage ls -l "gs://$WITNESS_BUCKET/drills/"` lists the object with today's date; its hash matches the local file; `EVE_PROOF_RECORD` is set; `checkpoint EV-2.10 DONE "$WITNESS_ADMIN_1_EMAIL" "witness:drills/<object>"`.
- **ROLLBACK:** **None for the upload.** A wrong record is superseded by a `v2` object; `v1` stays for ever, which is the point of the witness.
- **EVIDENCE:** The object name, generation and hash in the build log. E-08. TISAX 5.2.6, 5.2.4. Feeds **G-4**, **G-6** and, with EV-2.8, **G-2**.

## 3. The anti-silencing checks that need no drill

### EV-3.1 A merge to `eve/config` without the second human's review is refused

- **WHO:** Platform owner attempts, as himself; second human observes the result from her own session.
- **WHERE:** `EVE_CONFIG_REPO` on the git host.
- **ACTION:** He opens a pull request that changes one harmless line of `thresholds.yaml` (a comment), then tries to merge it with no review, and then tries to approve it himself and merge.

```bash
git -C "$HOME/eve-config" checkout -b anti-silencing-negative-test
printf '\n# negative test %s: this branch must not be mergeable without the second human\n' "$(date -u +%F)" >> "$HOME/eve-config/thresholds.yaml"
git -C "$HOME/eve-config" commit -am "negative test: unreviewed change to thresholds"
git -C "$HOME/eve-config" push -u origin anti-silencing-negative-test
gh pr create --repo "$EVE_CONFIG_REPO" --title "negative test (do not merge)" --body "setup 28 EV-3.1" || echo "use the git host's UI"
gh pr merge --repo "$EVE_CONFIG_REPO" --merge || echo "refused, as required"
```

- **VERIFY:** The merge is refused with a message naming the missing required review (CODEOWNERS: the second human); a self-approval does not satisfy it. The second human reads the refusal in the pull request's own timeline, not from a screenshot he sends her. Close the pull request without merging and delete the branch.
- **ROLLBACK:** Close and delete; nothing is merged.
- **EVIDENCE:** The pull request URL, its timeline and the refusal message as `${R}-3.1-config-merge-refused-v1`. E-15. TISAX 5.3.1, 5.2.1.

### EV-3.2 A direct push to the default branch is refused, and a bypass would be audited

- **WHO:** Platform owner attempts; second human reads the result.
- **WHERE:** `EVE_CONFIG_REPO`.
- **ACTION:**

```bash
git -C "$HOME/eve-config" checkout main && git -C "$HOME/eve-config" pull --ff-only
printf '\n# direct push negative test %s\n' "$(date -u +%F)" >> "$HOME/eve-config/thresholds.yaml"
git -C "$HOME/eve-config" commit -am "negative test: direct push"
git -C "$HOME/eve-config" push origin main || echo "refused, as required"
git -C "$HOME/eve-config" reset --hard origin/main
```

  The second human then confirms in the repository settings that administrator bypass is either disabled or audited, and that the audit log of the git host is readable by her.
- **VERIFY:** `refused, as required`; local branch reset clean; the settings show the branch protection with "require a pull request", "require review from code owners" and either no admin bypass or an audited one; she can open the git host's audit log herself.
- **ROLLBACK:** `git reset --hard origin/main`, already in the action.
- **EVIDENCE:** Terminal output and the settings screenshot as `${R}-3.2-direct-push-refused-v1`. E-15. TISAX 5.3.1.

### EV-3.3 The platform owner holds no standing role that can edit Eve

- **WHO:** Second human.
- **WHERE:** Shell.
- **ACTION:**

```bash
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json > "$R-3.3-eve-iam.json"
jq -r '.bindings[] | select(.members[]? | test("^user:")) | "\(.role)\t\(.members|join(","))"' "$R-3.3-eve-iam.json"
jq -r '.bindings[] | select(.members[]? == "user:'"$SA_1_ADMIN"'" or .members[]? == "user:'"$OWNER_DAILY_ACCOUNT"'") | .role' "$R-3.3-eve-iam.json"
for SA in "$SA_EVE_EXPORT" "$SA_EVE_VERIFIER" "$SA_EVE_CONSOLE"; do
  printf '%s\n' "$SA"
  gcloud iam service-accounts get-iam-policy "$SA" --project="$EVE_PROJECT" --format=json \
    | jq -r '.bindings[]? | "\(.role)\t\(.members|join(","))"'
done
gcloud asset search-all-iam-policies --scope="projects/$EVE_PROJECT" \
  --query="policy:\"$SA_1_ADMIN\"" --format='table(resource,policy.bindings.role)' 2>/dev/null || echo "asset search unavailable: record and use the two reads above"
```

  Then read the most recent drift-job output for `EVE_PROJECT` ([16](16-register-and-shared-registry.md)), or, while the drift job is BLOCKED (README B-02), record that the two reads above are the drift evidence for this row.
- **VERIFY:** No binding on `EVE_PROJECT` names `SA_1_ADMIN` or `OWNER_DAILY_ACCOUNT`; no `roles/iam.serviceAccountUser` or `roles/iam.serviceAccountTokenCreator` on any Eve service account names a human (S143, SD-12 item 2); every human principal on the project is a member of `GRP_EVE_OWNERS` or `GRP_EVE_CONSOLE_READERS`. A finding here is a stop: the file does not continue until the binding is removed and the removal is itself reported by Eve's self-integrity rule.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-3.3-eve-iam.json` and the printed tables. E-06. TISAX 4.2.1, 4.1.3.

### EV-3.4 Eve's own paths out are intact

- **WHO:** Second human.
- **WHERE:** Shell.
- **ACTION:**

```bash
gcloud logging sinks describe "$(basename "$EVE_SINK")" --organization="$ORG_ID" \
  --format='value(destination,filter,writerIdentity,disabled)' | tee "$R-3.4-sink.txt"
gcloud scheduler jobs list --project="$EVE_PROJECT" --location="$REGION" --format='table(name,state,schedule,timeZone)'
gcloud secrets versions list "$EVE_REFRESH_TOKEN_SECRET_NAME" --project="$EVE_PROJECT" --location="$REGION" \
  --format='table(name,state,createTime)'
```

- **VERIFY:** The sink is not `disabled`, its filter still carries the six streams and **no** actor exclusion, and its writer identity is unchanged from what [24](24-eve-workspace-identity-and-audit-feeds.md) recorded; the four jobs are `ENABLED`; the pinned token version `EVE_TOKEN_VERSION` is `ENABLED` and no newer version has appeared without a recorded reason. Any difference is a severity-1 finding that Eve should already have reported — and if Eve did not report it, that is the finding.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-3.4-sink.txt` and the two tables. E-06. TISAX 5.2.4.

## 4. The witness part of the drill (G-2, DR-28-3)

### EV-4.1 Refuse the withhold until the alarms have seen data

- **WHO:** Second human with witness administrator 1.
- **WHERE:** Witness organisation, Monitoring console and shell.
- **ACTION:** A metric-absence condition is never met until the stream has written at least one data point, so a withhold run before the first heartbeat proves nothing and teaches the wrong lesson. Confirm, in the witness project, that each of `WITNESS_ALERT_HEARTBEAT` and `WITNESS_ALERT_EXPORT` has a policy whose condition has measured data, and that the last heartbeat is younger than its window.

```bash
gcloud monitoring policies list --project="$EVE_WITNESS_PROJECT" \
  --format='table(displayName,enabled,conditions[].displayName)'
bq query --project_id="$EVE_WITNESS_PROJECT" --use_legacy_sql=false --format=csv \
 'SELECT MAX(ts) AS last_heartbeat FROM `'"$EVE_WITNESS_PROJECT"'.'"$WITNESS_MIRROR_DS"'.'"$WITNESS_HEARTBEAT_TABLE"'`'
```

- **VERIFY:** Both policies are enabled; the last heartbeat is inside its expected cadence. Also confirm the drill runs **before** the super-admin grant of [38](38-super-admin-gate-and-grant.md): no `walle@` holds Super Admin yet, so a blind window in Eve's export costs nothing.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-4.1-alarms-ready-v1.txt`. E-06. TISAX 5.2.4.

### EV-4.2 Withhold exactly one push

- **WHO:** Platform owner performs the pause under a grant the second human approves; she times it.
- **WHERE:** Shell; `EVE_PROJECT`.
- **ACTION:** The withhold is a pause of the push schedule for one window, not a deletion and not an IAM change.

```bash
gcloud pam grants create --entitlement="$ENT_PROJECT_REPAIR_EVE" --location=global --project="$EVE_PROJECT" \
  --requested-duration=3600s --justification="setup 28 EV-4.2 witness withhold drill DR-28-3"
# the second human approves:
gcloud pam grants approve <GRANT_ID> --entitlement="$ENT_PROJECT_REPAIR_EVE" --location=global --project="$EVE_PROJECT" \
  --reason="approved for DR-28-3, one window, resume at <time>"
gcloud scheduler jobs pause "$(basename "$EVE_JOB_HEARTBEAT_PUSH")" --location="$REGION" --project="$EVE_PROJECT"
gcloud scheduler jobs describe "$(basename "$EVE_JOB_HEARTBEAT_PUSH")" --location="$REGION" --project="$EVE_PROJECT" --format='value(state)'
```

- **VERIFY:** `state` prints `PAUSED`; the second human notes the UTC minute. The export job `EVE_JOB_EXPORT` is left running, so only the heartbeat's absence is under test in this run; the export absence alarm is exercised in a later monthly run and the calendar row says so.
- **ROLLBACK:** `gcloud scheduler jobs resume ...` at any moment (EV-4.4 does it on schedule).
- **EVIDENCE:** The grant id, the approval and the two command outputs as `${R}-4.2-withhold-v1.txt`. E-06. TISAX 5.2.6.

### EV-4.3 The witness alarm fires

- **WHO:** Witness administrators 1 and 2 receive; second human receives; none of them tells the platform owner.
- **WHERE:** Their own mail and phones; the witness Monitoring console.
- **ACTION:** Wait out the absence window (about 90 minutes for the heartbeat policy, per [27](27-witness-grants-and-alarms.md)). Record what arrived, on which channel, at what time, on how many devices.
- **VERIFY:** The heartbeat absence alarm fired within its window; it reached both witness administrators **and** the second human; the platform owner received nothing on a witness channel (he has no account in the witness organisation, which is the design, and the record states that it held). If nothing arrives within the window plus 15 minutes, that is the finding: the witness alarm does not work, G-2 stays red, and the file stops until [27](27-witness-grants-and-alarms.md) is repaired.
- **ROLLBACK:** Acknowledge the alarm as a drill in the witness console.
- **EVIDENCE:** Screenshots of the alarm on two devices as `${R}-4.3-witness-alarm-v1`. E-10. TISAX 1.6.2, 5.2.6.

### EV-4.4 Resume and prove the backlog

- **WHO:** Platform owner resumes under the same grant; second human verifies.
- **WHERE:** Shell; then the witness side.
- **ACTION:**

```bash
gcloud scheduler jobs resume "$(basename "$EVE_JOB_HEARTBEAT_PUSH")" --location="$REGION" --project="$EVE_PROJECT"
gcloud scheduler jobs run "$(basename "$EVE_JOB_HEARTBEAT_PUSH")" --location="$REGION" --project="$EVE_PROJECT"
```

  Witness administrator 1, with the second human watching, reads the heartbeat table again.
- **VERIFY:** A new heartbeat row lands; its cumulative counts are **greater than or equal to** the last pre-withhold row (a decrease is the tampering signal `WITNESS_ALERT_FINGERPRINT` exists for, and would be a severity-1 finding); its configuration fingerprint equals the pre-withhold fingerprint, because a paused schedule that has been resumed is not a configuration change — *and if it differs, the difference is expected to be exactly the schedule state, which the record names*; the gap in the series is visible and matches the withheld window exactly. The PAM grant expires or is revoked; `gcloud pam grants list` shows it ended.
- **ROLLBACK:** None needed; the pause is undone here.
- **EVIDENCE:** `${R}-4.4-backlog-v1.txt` with both heartbeat rows. E-06. TISAX 5.2.4.

### EV-4.5 Record DR-28-3 in the witness

- **WHO:** Second human writes; witness administrator 1 uploads; witness administrator 2 countersigns.
- **WHERE:** `gs://$WITNESS_BUCKET/drills/`.
- **ACTION:** **IRREVERSIBLE** (locked retention). Confirm before uploading: today's date in the name, an unused version suffix, no secret, no grant id that is also a credential (a PAM grant id is not a credential and may be recorded).

```bash
penv_set WITNESS_WITHHOLD_RECORD "records/$(date -u +%F)-EV-4.5-witness-withhold-v1.md"
```

  Content: the paused job, the pause and resume minutes, the alarm arrival times per recipient and device, the backlog result, the counts before and after, the grant id and approver.
- **VERIFY:** The object is listed in the witness bucket; `WITNESS_WITHHOLD_RECORD` is set; `checkpoint EV-4.5 DONE "$WITNESS_ADMIN_1_EMAIL" "witness:drills/<object>"`.
- **ROLLBACK:** **None.** A correction is a `v2` object.
- **EVIDENCE:** Object name, generation and hash. E-08. TISAX 5.2.6. This closes **G-2**.

## 5. The anti-silencing drill (DR-28-2)

The question this section answers is narrower and harder than §2's: *when the monitored administrator legitimately changes Eve, does the second human learn of it without his help?*

### EV-5.1 The declared change, requested and approved

- **WHO:** Platform owner requests; second human approves, and starts a stopwatch.
- **WHERE:** Shell.
- **ACTION:** He declares, in the justification, exactly what he will change and for how long: pause `EVE_JOB_ROSTER` for 30 minutes. He tells her nothing else, and in particular does not tell her when inside the grant he will act.

```bash
gcloud pam grants create --entitlement="$ENT_PROJECT_REPAIR_EVE" --location=global --project="$EVE_PROJECT" \
  --requested-duration=3600s \
  --justification="DR-28-2 anti-silencing drill: pause EVE_JOB_ROSTER for 30 minutes, resume, no other change"
gcloud pam grants approve <GRANT_ID> --entitlement="$ENT_PROJECT_REPAIR_EVE" --location=global --project="$EVE_PROJECT" \
  --reason="DR-28-2 approved; scope limited to pausing and resuming EVE_JOB_ROSTER"
```

- **VERIFY:** The grant exists, is approved by `SECOND_HUMAN_EMAIL` and nobody else, and its justification names the single change.
- **ROLLBACK:** Revoke the grant.
- **EVIDENCE:** The grant JSON as `${R}-5.1-declared-grant-v1.json`. E-06. TISAX 4.1.3.

### EV-5.2 The change

- **WHO:** Platform owner alone.
- **WHERE:** Shell.
- **ACTION:**

```bash
gcloud scheduler jobs pause "$(basename "$EVE_JOB_ROSTER")" --location="$REGION" --project="$EVE_PROJECT"
```

  He notes the minute and says nothing until EV-5.5.
- **VERIFY:** `gcloud scheduler jobs describe ... --format='value(state)'` prints `PAUSED`.
- **ROLLBACK:** Resume (EV-5.5).
- **EVIDENCE:** His noted minute, handed over at EV-5.5. E-06. TISAX 5.2.6.

### EV-5.3 Eve reports her own pause — **BLOCKED** until the self-integrity rules exist

- **WHO:** Second human.
- **WHERE:** Her phone and mailbox; the paging service.
- **ACTION:** **BLOCKED (README B-08).** This step needs Eve's self-integrity rules and configuration fingerprint — the rule set of [25](25-eve-human-super-admin-detections.md) that treats a scheduler, job, IAM, sink, dataset, bucket, key or `eve@` change on `EVE_PROJECT` as severity 1 with the actor as subject. It needs: that rule set and the fingerprint computation committed in Eve's repository at a named commit with green CI, deployed at `EVE_CODE_COMMIT`. Until then the step records `BLOCKED`, the drill continues at EV-5.4 (the witness half, which does not need the rule), and the missing half is listed in README's BLOCKED index against `EVE_H_LIVE_RECORD`.

  When unblocked: wait for the detection period plus the budget, and record the page exactly as EV-2.3 does.
- **VERIFY:** A severity-1 page reaches the second human naming `SA_1_ADMIN` as the actor and the paused job as the object, **without** the platform owner telling her. The page arrives even though the change was declared: Eve does not read the PAM justification and must not be taught to suppress declared changes — the approval record, not the detector, is what makes it benign.
- **ROLLBACK:** Acknowledge as a drill.
- **EVIDENCE:** `${R}-5.3-self-integrity-page-v1` or a `BLOCKED` checkpoint with the B-08 reference. E-10. TISAX 1.6.2.

### EV-5.4 The witness sees it

- **WHO:** Witness administrator 1 types; second human watches; both witness administrators watch their channels.
- **WHERE:** Witness organisation.
- **ACTION:** Read the heartbeat rows spanning the pause.
- **VERIFY:** Either the configuration fingerprint changes between the two heartbeats and `WITNESS_ALERT_FINGERPRINT` fires to the second human and both witness administrators, **or** — if the fingerprint does not include scheduler state — the roster-derived counts stop increasing and the second human can see the flat line. One of the two must be true; if neither is, the fingerprint's definition is too narrow, and that is a finding against [26](26-eve-reporting-and-witness-export.md) recorded here with an owner (Eve owner) and a due date (before the super-admin grant), because a quiet pause that leaves no witness trace is exactly the failure this drill exists to find.
- **ROLLBACK:** Acknowledge the alarm as a drill.
- **EVIDENCE:** `${R}-5.4-witness-fingerprint-v1.txt`, the alarm screenshots. E-06, E-10. TISAX 5.2.4, 1.6.2.

### EV-5.5 Resume, close the grant, compare notes

- **WHO:** Platform owner resumes; second human closes.
- **WHERE:** Shell.
- **ACTION:**

```bash
gcloud scheduler jobs resume "$(basename "$EVE_JOB_ROSTER")" --location="$REGION" --project="$EVE_PROJECT"
gcloud scheduler jobs run "$(basename "$EVE_JOB_ROSTER")" --location="$REGION" --project="$EVE_PROJECT"
gcloud pam grants list --entitlement="$ENT_PROJECT_REPAIR_EVE" --location=global --format='table(name,state,createTime)'
```

  Only now does he tell her the minute he paused. She compares it with the page time (EV-5.3) and the fingerprint change (EV-5.4) and records both deltas.
- **VERIFY:** The job is `ENABLED` and its next run completed; the grant is ended or expired; the roster check's output for the skipped window is either backfilled or explicitly absent, and the absence is recorded (a paused roster check is a blind window in the roster, which is why the drill window is short and declared).
- **ROLLBACK:** None needed.
- **EVIDENCE:** `${R}-5.5-resume-v1.txt`. E-06. TISAX 5.2.6.

### EV-5.6 Record DR-28-2 in the witness

- **WHO:** Second human writes; witness administrator 1 uploads.
- **WHERE:** `gs://$WITNESS_BUCKET/drills/`.
- **ACTION:** **IRREVERSIBLE** (locked retention); the same pre-upload confirmations as EV-2.10.

```bash
penv_set ANTI_SILENCING_RECORD "records/$(date -u +%F)-EV-5.6-anti-silencing-v1.md"
```

  Content: the declared change, the grant and approver, the pause and resume minutes, whether the self-integrity page arrived (or the B-08 BLOCKED note), the witness fingerprint result, the two deltas, and the second human's one-line verdict: *did I learn of it without his help?*
- **VERIFY:** The object is listed; `ANTI_SILENCING_RECORD` is set.
- **ROLLBACK:** **None.**
- **EVIDENCE:** Object name, generation and hash. E-08. TISAX 5.2.6.

## 6. The sandbox part, by nonprod Eve (G-5, G-7 sandbox half)

Under SD-26 this part **never touches the witness**: no nonprod identity is granted on a witness resource, no page goes to a witness channel, and no row reaches `eve_mirror`. It pages nonprod channels only.

### EV-6.1 Open the twin shell and prove the separation

- **WHO:** Second human; sandbox super admin 1 present.
- **WHERE:** Shell.
- **ACTION:**

```bash
twin_shell --sandbox-org
source ~/.platform-env
penv_guard
need EVE_PROJECT EVE_TWIN_PROJECT ORG_ID SANDBOX_ORG_ID SANDBOX_CUSTOMER_ID EVE_TWIN_SINK EVE_TWIN_ROBOT
echo "EVE_PROJECT resolves to: $EVE_PROJECT ; ORG_ID resolves to: $ORG_ID"
gcloud logging sinks describe "$(basename "$EVE_TWIN_SINK")" --organization="$SANDBOX_ORG_ID" \
  --format='value(name,destination,writerIdentity,disabled)'
gcloud projects get-iam-policy "$EVE_TWIN_PROJECT" --format=json \
  | jq -r '[.bindings[].members[]] | map(select(test("witness|eve-export"))) | length'
```

  If a nonprod notification channel does not exist yet, create one here, in the twin project, to the second human and the two sandbox super admins only:

```bash
gcloud beta monitoring channels create --project="$EVE_TWIN_PROJECT" \
  --display-name="eve-twin-drill-email" --type=email \
  --channel-labels="email_address=$SECOND_HUMAN_EMAIL"
penv_set NOTIF_CH_EVE_TWIN_EMAIL "<the returned channel resource name>"
```

- **VERIFY:** `EVE_PROJECT` resolves to the twin id and `ORG_ID` to `SANDBOX_ORG_ID` (the twin shell's `--sandbox-org` mode); the twin sink's parent organisation is the **sandbox** organisation and its destination is the twin dataset; the jq count prints `0` (no witness or export principal anywhere in the twin project); the nonprod channel exists. This is the check X-ORG-02 asked for: sandbox events reach the sandbox organisation's own sink and nothing else.
- **ROLLBACK:** `exit` the twin shell; delete the channel if it was created in error.
- **EVIDENCE:** `${R}-6.1-twin-separation-v1.txt`. E-06. TISAX 5.2.2, 5.2.4.

### EV-6.2 A seeded tenant-integrity event — **BLOCKED** while B-08 or B-09 is open

- **WHO:** Sandbox super admin 1 seeds; second human verifies; nonprod Eve detects.
- **WHERE:** Sandbox Admin console; then the twin shell.
- **ACTION:** **BLOCKED (README B-08, B-09)** exactly as [25](25-eve-human-super-admin-detections.md)'s twin deploy is: it runs as written the day the twin reconciler and the detection catalogue are deployed at `EVE_CODE_COMMIT`. When unblocked: the sandbox super admin performs, in the **sandbox** tenant, one tenant-integrity event from the SA-01..SA-09 catalogue — for example granting a super-admin role to a synthetic sandbox account, or adding a third OAuth client marked trusted — using the drill token in any name it accepts. Then:

```bash
bq query --project_id="$EVE_TWIN_PROJECT" --location="$BQ_LOCATION" --use_legacy_sql=false --format=csv \
 'SELECT timestamp, protopayload_auditlog.authenticationInfo.principalEmail AS actor,
         JSON_VALUE(protopayload_auditlog.metadataJson, "$.event[0].eventName") AS event_name
  FROM `'"$EVE_TWIN_PROJECT"'.'"$EVE_WS_LOGS_DS"'.cloudaudit_googleapis_com_activity`
  WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 HOUR)
  ORDER BY timestamp DESC LIMIT 20'
```

- **VERIFY:** The event appears in the twin dataset within the nonprod budget; nonprod Eve raises a finding and pages `NOTIF_CH_EVE_TWIN_EMAIL`; **no** page reaches the production paging service, the witness channels or the incident commander; the production `eve_workspace_logs` contains **no** row for the sandbox actor (query it from a separate, non-twin shell). Reverse the seeded event.
- **ROLLBACK:** Reverse the sandbox change; delete the synthetic role assignment.
- **EVIDENCE:** `${R}-6.2-sandbox-tenant-integrity-v1.txt` and the nonprod page screenshot. E-10. TISAX 1.6.2, 5.2.2.

### EV-6.3 A roster diff in both directions — **BLOCKED** on the same code

- **WHO:** Sandbox super admins 1 and 2; second human verifies.
- **WHERE:** Sandbox Admin console; twin shell.
- **ACTION:** **BLOCKED (README B-08)**, as above. When unblocked, in the sandbox tenant: (a) **addition** — grant a delegated admin role to a synthetic account that is not on the sandbox roster file, wait for the nonprod roster check to run, then revoke it; (b) **removal** — remove a role that *is* on the sandbox roster file from its holder, wait, then restore it. Both directions must page: an unrostered new admin, and a rostered admin who has quietly lost or gained privilege.
- **VERIFY:** Two distinct findings, one per direction, each naming the actor and the account, each paging the nonprod channel only. A catalogue that pages only on additions is a finding against [25](25-eve-human-super-admin-detections.md), recorded with an owner and a date before the grant.
- **ROLLBACK:** Both changes are reversed as part of the action; the sandbox roster file returns to its committed state.
- **EVIDENCE:** `${R}-6.3-roster-diff-v1.txt`. E-06, E-10. TISAX 4.2.1, 1.6.2.

### EV-6.4 `log_pipeline_silent` on the nonprod sinks — **BLOCKED** on the same code

- **WHO:** Second human, with sandbox super admin 1.
- **WHERE:** Twin shell.
- **ACTION:** **BLOCKED (README B-08, B-09)**. When unblocked: withhold the twin sink's rows for longer than the freshness window — by disabling the twin sink for one window, or, better, by producing no sandbox events at all for that window while a synthetic freshness canary is stopped — and confirm that Eve's H-1 freshness rule raises `log_pipeline_silent`.

```bash
gcloud logging sinks update "$(basename "$EVE_TWIN_SINK")" --organization="$SANDBOX_ORG_ID" --disabled
# wait out the freshness window, then:
gcloud logging sinks update "$(basename "$EVE_TWIN_SINK")" --organization="$SANDBOX_ORG_ID" --no-disabled
```

- **VERIFY:** `log_pipeline_silent` fires within the freshness window plus its grace, on the nonprod channel only; after the sink is re-enabled, new events land again and the finding clears with an explicit clear message. Note in the record that a disabled sink does **not** backfill: events during the window are lost in the twin, which is acceptable in nonprod and is the reason the same test is never run against the production sink.
- **ROLLBACK:** `--no-disabled`, in the action. If the re-enable fails, stop and repair before leaving the sitting.
- **EVIDENCE:** `${R}-6.4-log-pipeline-silent-v1.txt`. E-06. TISAX 5.2.4.

### EV-6.5 Nonprod pages only, and the witness heard nothing

- **WHO:** Second human; witness administrator 1 confirms the negative.
- **WHERE:** Twin project's Monitoring; the production paging service; the witness.
- **ACTION:** List what fired where during §6's window and, on the witness side, confirm that no drill row, no page and no export entry arrived from a nonprod source.
- **VERIFY:** Every §6 page is on `NOTIF_CH_EVE_TWIN_EMAIL`; `PAGER_SUBJECT_SERVICE_NAME` shows no incident for the §6 window; the witness heartbeat rows for the window carry the production fingerprint and no nonprod marker; `gs://$WITNESS_BUCKET/exports/` gained no object attributable to the twin. This is the positive statement of SD-26: no nonprod identity is ever granted on witness resources, and the drill proves the separation as well as the detection.
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-6.5-nonprod-only-v1.txt` with the witness administrator's counter-signature on the negative. E-06. TISAX 5.2.2.

### EV-6.6 Record the sandbox drill

- **WHO:** Second human writes; sandbox super admin 2 countersigns; witness administrator 1 uploads.
- **WHERE:** `gs://$WITNESS_BUCKET/drills/`.
- **ACTION:** **IRREVERSIBLE** (locked retention); same pre-upload confirmations as EV-2.10. The record of a *nonprod* drill is uploaded to the witness because it is a **record**, not a nonprod identity: a human uploads it under their own witness account, which is not a cross-organisation grant.

```bash
penv_set SANDBOX_DRILL_RECORD "records/$(date -u +%F)-EV-6.6-sandbox-drill-v1.md"
```

  Content: each seeded event with its minute, the nonprod finding and page for each, the `log_pipeline_silent` result, the negative confirmations of EV-6.5, and the BLOCKED state of any step that did not run with its B id.
- **VERIFY:** The object is listed; `SANDBOX_DRILL_RECORD` is set; `checkpoint EV-6.6 DONE "$SANDBOX_SA_2_EMAIL" "witness:drills/<object>"`.
- **ROLLBACK:** **None.**
- **EVIDENCE:** Object name, generation and hash. E-08. TISAX 5.2.6, 5.2.2. Closes the sandbox half of **G-5** and **G-7**.

## 7. The recurrence, written here

### EV-7.1 Fill DR-28-1, DR-28-2 and DR-28-3

- **WHO:** Second human writes; a second reviewer approves the commit.
- **WHERE:** Shell; `DRILL_CALENDAR`.
- **ACTION:** The three rows exist as skeletons from [01](01-prerequisites-and-conventions.md) PR-4.3 with `*tbd*` values. They are completed here — not in [42](42-gates-drills-and-evidence.md), which only reviews them — so that the cadence is in force from the day Eve is live.

```bash
need DRILL_CALENDAR EVE_PROOF_RECORD WITNESS_WITHHOLD_RECORD ANTI_SILENCING_RECORD BUILD_LOG_DIR
D0="<date of EV-2.2, YYYY-MM-DD>"
NEXT="$(date -u -j -v+1m -f %Y-%m-%d "$D0" +%F 2>/dev/null || date -u -d "$D0 +1 month" +%F)"
python3 - "$DRILL_CALENDAR" "$D0" "$NEXT" "$EVE_PROOF_RECORD" "$ANTI_SILENCING_RECORD" "$WITNESS_WITHHOLD_RECORD" <<'PY'
import sys
path, d0, nxt, rec1, rec2, rec3 = sys.argv[1:7]
rows = {
 "DR-28-1": f"| DR-28-1 | Second human's blind proof: an unannounced window, one seeded super-admin action from eve/seeded-actions.md, verified by her alone from the paging service, the two tables and the witness | monthly, and within five business days of every merge to eve/config | second human (platform owner performs the seeded action only) | a witness administrator records | 28 | {d0} | {rec1} | {nxt} | G-4, G-6; SD-12 item 5 |",
 "DR-28-2": f"| DR-28-2 | Anti-silencing drill: one declared change to Eve by the platform owner under an approved grant; the second human confirms the self-integrity page and the witness fingerprint arrive without his help | quarterly, and after any change to Eve's self-integrity rules or fingerprint definition | second human | a witness administrator | 28 | {d0} | {rec2} | *tbd* (quarter after the first) | SD-12 item 12 |",
 "DR-28-3": f"| DR-28-3 | Witness push withheld for one window; the absence alarm fires; the backlog push restores the series and the counts do not decrease | once before the super-admin grant, then semi-annually, alternating heartbeat and export | platform owner pauses under an approved grant; second human times | both witness administrators | 28 | {d0} | {rec3} | *tbd* (six months after the first) | G-2; SD-07 |",
}
lines = open(path).read().split("\n")
out, seen = [], set()
for l in lines:
    k = l[2:9] if l.startswith("| DR-28-") else None
    if k in rows:
        out.append(rows[k]); seen.add(k)
    else:
        out.append(l)
missing = set(rows) - seen
if missing: sys.exit("rows not found in the calendar: " + ", ".join(sorted(missing)))
open(path, "w").write("\n".join(out))
print("calendar updated")
PY
git -C "$BUILD_LOG_DIR" add "$DRILL_CALENDAR"
git -C "$BUILD_LOG_DIR" commit -m "registers: DR-28-1 to DR-28-3 filled (setup 28 EV-7.1)"
```

- **VERIFY:** `grep -c '^| DR-28-' "$DRILL_CALENDAR"` prints `3`; each row carries a first due date, a record id and either a next due date or a dated `*tbd*` with its rule; no row still says `*tbd* by 28`.
- **ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD`.
- **EVIDENCE:** The commit. E-08. TISAX 5.2.6.

### EV-7.2 Wire the "after every `eve/config` merge" trigger

- **WHO:** Second human; the Eve owner implements the reminder.
- **WHERE:** `EVE_CONFIG_REPO` settings; `DRILL_CALENDAR`.
- **ACTION:** A cadence nobody is reminded of is a cadence that lapses. Add to `eve/config`'s pull-request template a checkbox — "a DR-28-1 proof is due within five business days of this merge; second human to schedule" — and, where the git host supports it, a rule that notifies the second human on every merge to the default branch. While CI is BLOCKED (README B-03) the checkbox plus her own calendar entry is the mechanism, recorded as such.
- **VERIFY:** A test pull request shows the checkbox; the merge notification reaches her (confirmed on the EV-3.1 negative test's close, or on the next real merge).
- **ROLLBACK:** Revert the template change.
- **EVIDENCE:** The template commit and one notification as `${R}-7.2-config-merge-trigger-v1`. E-15. TISAX 5.2.6.

## 8. `EVE_H_LIVE_RECORD`

### EV-8.1 The refusal gates, read for the last time

- **WHO:** Second human.
- **WHERE:** Shell.
- **ACTION:**

```bash
FAIL=0
for S in PA-9.3 OB-7.3 OB-2.9; do
  awk -F'\t' -v s="$S" '$2==s && $3=="DONE" {found=1} END {exit !found}' "$BUILD_LOG_DIR/checkpoints.tsv" \
    || { echo "REFUSED: $S is not DONE"; FAIL=1; }
done
for V in EVE_PROOF_RECORD WITNESS_WITHHOLD_RECORD ANTI_SILENCING_RECORD SANDBOX_DRILL_RECORD; do
  need "$V" || { echo "REFUSED: $V missing"; FAIL=1; }
done
grep -q 'MODE=full' "$BUILD_LOG_DIR"/records/*EV-1.3* || { echo "REFUSED: the proof ran in evidence mode only"; FAIL=1; }
test "$FAIL" = 0 && echo "gates clear"
```

  Then the two facts that no local file can prove: witness administrator 1 states in writing that all four witness alert policies have **seen data**, and the second human states that she has read the residual-risk paragraph at the head of this file.
- **VERIFY:** `gates clear`, both written statements present. Any `REFUSED` line stops the step: `EVE_H_LIVE_RECORD` is not written, `checkpoint EV-8.1 BLOCKED` names which gate is open, and README's BLOCKED index gains a line — Wall-E does not start (SD-12 item 13).
- **ROLLBACK:** Read only.
- **EVIDENCE:** `${R}-8.1-refusal-gates-v1.txt`. E-05, E-08. TISAX 1.4.1.

### EV-8.2 Write and sign `EVE_H_LIVE_RECORD`

- **WHO:** Second human writes and signs; security reviewer countersigns once named; the platform owner is informed, not a signatory.
- **WHERE:** `PLATFORM_REPO_DIR/decisions/`, then `gs://$WITNESS_BUCKET/drills/`.
- **ACTION:**

```bash
D="$(date -u +%F)"
cat > "$PLATFORM_REPO_DIR/decisions/${D}-eve-h-live.md" <<'REC'
# Eve-H is live and independently proven

## Status
- Owner: the platform owner
- Last reviewed: <date>

## What is live
The six-stream organisation sink, the Reports API poll by actor over the union of the committed
roster and the live admin-role holders, the daily roster check, the tenant-integrity and posture
rules with the actor set to any roster human, H-1, the Eve credential check, the self-integrity
rules (or their BLOCKED state, named below), eve.incidents and eve.pages, route 1 and route 2,
the witness export, the heartbeat with its configuration fingerprint and cumulative counts, and
the witness absence and fingerprint alarms.

## What is not live, and who owns it
- Halt targets: none exist before Wall-E; every halting rule pages severity 1 and records
  halt_target_pending (SD-10). Wired in file 36.
- BLOCKED steps at this date: <list with B ids and owners>.

## The proof
- Blind proof (DR-28-1) run on <date>, record <EVE_PROOF_RECORD>, mode full, rule <id>,
  observed deltas: page <n> min, sink <n> min, reports <n> min.
- Anti-silencing drill (DR-28-2) on <date>, record <ANTI_SILENCING_RECORD>.
- Witness withhold (DR-28-3) on <date>, record <WITNESS_WITHHOLD_RECORD>.
- Sandbox drill on <date>, record <SANDBOX_DRILL_RECORD>.
- Anti-silencing checks EV-3.1 to EV-3.4: passed on <date>.

## Residual risk, accepted
An Organization Administrator can still alter Eve inside the tenant. The witness alarms, the
configuration fingerprint, the self-integrity rules and the monthly blind proof make that
noticed, not impossible. Accepted by: second human <name, date>; security reviewer
<name, date | not yet appointed>.

## Consequence
File 30 (Wall-E) may start. The interim Admin console activity rules of file 06 are
<kept | retired> per EV-8.3.

## Signatures
Second human: ...   Security reviewer: ...   Informed: platform owner on <date>.
REC
penv_set EVE_H_LIVE_RECORD "decisions/${D}-eve-h-live.md"
git -C "$PLATFORM_REPO_DIR" checkout -b eve-h-live
git -C "$PLATFORM_REPO_DIR" add "decisions/${D}-eve-h-live.md"
git -C "$PLATFORM_REPO_DIR" commit -m "setup 28 EV-8.2: Eve-H live and independently proven"
git -C "$PLATFORM_REPO_DIR" push -u origin eve-h-live
```

  Witness administrator 1 then uploads the signed PDF to `gs://$WITNESS_BUCKET/drills/${D}-eve-h-live-v1.pdf` (**IRREVERSIBLE**, locked retention; confirm the date, the version and that no signature image is a scanned credential).
- **VERIFY:** The pull request is merged with the second human's approval and one other; `EVE_H_LIVE_RECORD` is set and the file parses (`test -s`); the witness object is listed; `checkpoint EV-8.2 DONE "$SECOND_HUMAN_EMAIL" "$EVE_H_LIVE_RECORD"`.
- **ROLLBACK:** The commit can be reverted before Wall-E starts; the witness object cannot be removed, so a withdrawal is a `v2` record saying so.
- **EVIDENCE:** The merge commit, the witness object. E-08, E-05. TISAX 5.2.6, 1.4.1.

### EV-8.3 The interim activity rules: kept or retired

- **WHO:** Second human decides alone (she is their recipient).
- **WHERE:** Admin console as `SA_2_ADMIN`: Menu → Rules; `06`'s OB-2.6 rules A to D.
- **ACTION:** [06](06-organisation-bootstrap-and-roster.md) OB-2.6 created four activity rules that mail her on roster-account logins and admin-role changes, "until the second human retires them, never before `EVE_H_LIVE_RECORD`". Now she may. **Recommended: keep them.** They cost nothing, they run inside Workspace rather than inside anything the platform owner administers, and they are the only detector that survives the loss of `EVE_PROJECT` entirely — which is precisely the scenario Eve cannot report on. If she retires any rule, she records which, why, and what now covers it.
- **VERIFY:** A dated line in `EVE_H_LIVE_RECORD` stating `kept` or `retired: <rules>, covered by <what>`; if kept, a screenshot showing the four rules still enabled; README's re-run index line for the interim rules is closed or annotated.
- **ROLLBACK:** Re-create a retired rule from OB-2.6's text.
- **EVIDENCE:** `${R}-8.3-interim-rules-decision-v1`. E-08. TISAX 4.1.2.

### EV-8.4 Hand over to Wall-E

- **WHO:** Second human tells the platform owner; both update README.
- **WHERE:** `README.md` of this set.
- **ACTION:** Record in README's stage table that stage 30 may begin, naming `EVE_H_LIVE_RECORD`; add any BLOCKED step of this file to README's BLOCKED index with its B id; add to the re-run index the lines this file opened (an EV-2.5 repeat after each `eve/config` merge; the EV-3.3 IAM read after every new Eve identity, in particular after [36](36-wall-e-joins-to-eve-and-mo.md) and [41](41-eve-s3-and-s4.md)).
- **VERIFY:** README shows the record path; `grep -c 'EV-' "$BUILD_LOG_DIR/rerun-index.tsv"` is at least 2.
- **ROLLBACK:** Revert the README commit.
- **EVIDENCE:** The commit. E-05. TISAX 1.4.1.

## 9. Close

### EV-9.1 Deviation rows

- **WHO:** Second human; the platform owner reads the rows.
- **WHERE:** `DEVIATION_REGISTER`.
- **ACTION:**

```bash
need DEVIATION_REGISTER
d=$(date -u +%F)
{
printf '| BD-28-1 | %s | 28 EV-5.3 | DEV | the anti-silencing drill ran without its self-integrity half: Eve'"'"'s self-integrity rules and configuration fingerprint are not committed (B-08) | EVE_PROJECT | eve repository | witness fingerprint half only | EV-5.4 output | n/a | second human signed the partial record | re-run EV-5.3 when B-08 lands, before the super-admin grant | open |\n' "$d"
printf '| BD-28-2 | %s | 28 EV-6.2 to EV-6.4 | DEV | the sandbox half of G-5 and G-7 ran <in full | not at all>: the twin reconciler and detection catalogue depend on B-08 and B-09 | EVE_TWIN_PROJECT, sandbox organisation | 25 twin deploy | nonprod findings and pages | EV-6.x outputs | n/a | second human and sandbox super admin 2 | re-run the three steps when 25'"'"'s twin deploy is DONE | open |\n' "$d"
printf '| BD-28-3 | %s | 28 EV-2.4 | DEV | the BigQuery field path for the Workspace event object was <confirmed | corrected> from a raw row rather than from a published schema | EVE_PROJECT eve_workspace_logs | n/a | the corrected query | EV-2.4 raw row | n/a | second human | replace with the documented path if Google publishes one | open |\n' "$d"
} >> "$DEVIATION_REGISTER"
git -C "$BUILD_LOG_DIR" add "$DEVIATION_REGISTER"
git -C "$BUILD_LOG_DIR" commit -m "registers: BD-28-1 to BD-28-3 (setup 28)"
```

  Rows whose condition did not occur are deleted before the commit rather than left open.
- **VERIFY:** `grep -c '^| BD-28-' "$DEVIATION_REGISTER"` matches the number of rows that actually apply; each open row names an owner and a closing condition.
- **ROLLBACK:** `git revert`.
- **EVIDENCE:** The commit. E-05. TISAX 5.2.1, 1.4.1.

### EV-9.2 Re-run index and BLOCKED index

- **WHO:** Second human.
- **WHERE:** `BUILD_LOG_DIR/rerun-index.tsv`; README.
- **ACTION:** Record: (a) EV-5.3 to be re-run when B-08 lands; (b) EV-6.2 to EV-6.4 when [25](25-eve-human-super-admin-detections.md)'s twin deploy completes; (c) EV-2.5's poll check to be repeated after [39](39-wall-e-stage-0.md) so that the post-grant `walle@` rows land on the post-grant verification list where SD-03 put them, not here; (d) EV-3.3 after every new Eve identity.
- **VERIFY:** Four lines with `PENDING` status and named owners; README's BLOCKED index carries the same B ids.
- **ROLLBACK:** Not applicable; the index is append-only.
- **EVIDENCE:** The committed index. E-05. TISAX 1.4.1.

### EV-9.3 Write the gate rows

- **WHO:** Second human; the incident commander co-signs G-6; the Eve owner reads.
- **WHERE:** The gate table README and [38](38-super-admin-gate-and-grant.md) share.
- **ACTION:** Replace the evidence columns of Eve's rows with what this file actually produced.

| Row | Green when | Evidence produced here |
|---|---|---|
| G-2 | The witness exists, the first push landed, and the absence alarm fires on a withheld push | EV-2.8 (heartbeat and export containing a finding), EV-4.3 (alarm fired to three recipients), `WITNESS_WITHHOLD_RECORD` |
| G-4 | The six-stream sink and the Reports poll by actor are running with lag budgets set (SD-03) | EV-2.4 and EV-2.5 (production half: a seeded human super-admin change in both tables within the budget); [37](37-wall-e-sandbox-rehearsal.md) and §6 (twin robot half); [32](32-wall-e-consents.md) (the robot's consent login event). **Not** `walle@` shadow runs |
| G-5 | Reconciliation, tenant-integrity rules, roster check and heartbeat live | EV-6.2 to EV-6.4 (sandbox part: tenant-integrity event, roster diff both ways, `log_pipeline_silent`), EV-2.8 (heartbeat) |
| G-6 | The reporting contract live on both routes | EV-2.3 (route 1 page and acknowledgement), EV-2.6 (rows and the sole-recipient check), EV-4.3 (route 2 through the witness) |
| G-7 | The layer exercised end to end before the grant | `EVE_PROOF_RECORD`, `SANDBOX_DRILL_RECORD`, `ANTI_SILENCING_RECORD`, `WITNESS_WITHHOLD_RECORD`, all four in the witness; split per SD-26 into a sandbox part and a witness part |

- **VERIFY:** Every row names a record that exists in the witness bucket; no row cites a `walle@` shadow run; [38](38-super-admin-gate-and-grant.md)'s copy of the table matches this one.
- **ROLLBACK:** Revert the commit.
- **EVIDENCE:** The commit and the incident commander's signature on G-6. E-08. TISAX 5.2.6.

## 10. What to confirm before each irreversible step

| Step | What is irreversible | Confirm first | Gated on |
|---|---|---|---|
| EV-2.10 | The proof record in `gs://$WITNESS_BUCKET/drills/` cannot be deleted before its retention period | today's date in the name; the version suffix is unused; no secret, key, token or backup code; personal data limited to the named administrators the SD-11 DPO record covers | the DPO record (SD-11), P13 retention signed ([03](03-decisions-and-people.md)) |
| EV-4.5 | Same, for the withhold record | as above, plus: the PAM grant id is recorded but no credential is | SD-07 |
| EV-5.6 | Same, for the anti-silencing record | as above, plus: the BLOCKED state of EV-5.3 is stated rather than omitted | SD-12 item 12 |
| EV-6.6 | Same, for the sandbox record | as above, plus: no sandbox user's personal data beyond synthetic accounts | SD-26, SD-29 |
| EV-8.2 | The signed `EVE_H_LIVE_RECORD` PDF in the witness | every refusal gate of EV-8.1 clear; the mode was full; the residual-risk paragraph accepted and signed | SD-12 items 7, 8 and 13 |

No step in this file prints, pastes or stores a secret value. The only credentials touched are PAM grants, which expire, and no token, key or backup code is read, copied or displayed.

## 11. Verification checklist for the whole part

- [ ] `EVE_FIRST_RUN_RECORD` existed before the first window opened; Eve had a recipient outside the administration line from her first run.
- [ ] The seeded-action list is merged, and the platform owner did not review it.
- [ ] The proof fixtures exist and hold no real user, no real role assignment and no production setting.
- [ ] The window was unannounced; the second human's note predates the platform owner's reply.
- [ ] The platform owner performed exactly one action and verified nothing.
- [ ] A page reached the second human on her own device within the recorded budget (full mode), and the recipient set contained nobody in the administration line.
- [ ] The event is in `eve_workspace_logs` with actor `SA_1_ADMIN`, and the absence of `walle@` rows was recorded as expected and not acted on.
- [ ] The event is in `eve_workspace_reports` through the Reports poll, and the table holds rows for other roster actors.
- [ ] `eve.incidents` and `eve.pages` rows match what actually arrived; `halt_target_pending` is recorded.
- [ ] The reversal is reported as well as the change.
- [ ] No `eve/config` merge, no PAM grant and no scheduler change happened inside the window.
- [ ] The witness heartbeat for the hour shows increased counts and an unchanged fingerprint; the export containing the finding verifies against its manifest.
- [ ] A merge to `eve/config` without the second human is refused; a direct push is refused; bypass is disabled or audited and she can read the audit.
- [ ] No human principal on `EVE_PROJECT` outside `GRP_EVE_OWNERS` and `GRP_EVE_CONSOLE_READERS`; no human `actAs` or token-creator on any Eve service account.
- [ ] The sink is enabled, its filter carries no actor exclusion, and the pinned token version is unchanged.
- [ ] One push was withheld after the alarms had seen data and before the grant; the absence alarm fired to both witness administrators and the second human; the backlog restored the series and no count decreased.
- [ ] The declared change was reported without the platform owner's help — or EV-5.3 is recorded BLOCKED against B-08 with an owner and a date before the grant.
- [ ] The sandbox drills ran against the sandbox tenant and `SANDBOX_ORG_ID`'s own sink, paged nonprod channels only, and left no trace in the witness or in production — or are recorded BLOCKED against B-08 and B-09.
- [ ] DR-28-1, DR-28-2 and DR-28-3 carry real dates, records and next-due values; the `eve/config` merge trigger exists.
- [ ] Every refusal gate of EV-8.1 is clear; `EVE_H_LIVE_RECORD` is merged and in the witness; the interim rules decision is recorded (recommended: kept).
- [ ] Every record in this file was uploaded by a witness administrator, never by the platform owner.
- [ ] Deviation rows, re-run lines and the five gate rows are committed.

## 12. What the next file needs from this one

| Needs it | What it takes | Where |
|---|---|---|
| [30](30-wall-e-workspace-side.md) and every later Wall-E file | `EVE_H_LIVE_RECORD` merged; Wall-E does not start without it (SD-12 item 13, SD-45) | EV-8.2 |
| [36](36-wall-e-joins-to-eve-and-mo.md) | The knowledge that every halting rule currently records `halt_target_pending`; 36 wires the targets and re-runs EV-3.3's identity check for the new principals | EV-2.6, EV-9.2 |
| [37](37-wall-e-sandbox-rehearsal.md) | The twin sink separation proven in EV-6.1, and the nonprod channel `NOTIF_CH_EVE_TWIN_EMAIL`, so the Wall-E twin's drills page the same way | EV-6.1 |
| [38](38-super-admin-gate-and-grant.md) | The five gate rows G-2, G-4, G-5, G-6, G-7 with their evidence, and the statement that `walle@` shadow-run rows belong to the post-grant list | EV-9.3 |
| [39](39-wall-e-stage-0.md) | The post-grant re-run line: the first robot-attributed admin change in the production tenant must appear in `eve_workspace_logs` with actor `walle@` within the lag budget; absence is a severity-1 evidence-perimeter finding, never a reason to recreate the sink (S141) | EV-9.2 |
| [41](41-eve-s3-and-s4.md) | The monthly DR-28-1 cadence, which continues across S3 and S4 and is re-run after every `eve/config` merge | EV-7.1 |
| [42](42-gates-drills-and-evidence.md) | `DRILL_CALENDAR` rows DR-28-1 to DR-28-3, already dated; 42 reviews them and does not open them | EV-7.1 |

## 13. Review findings this file closes

| Id | Severity | How it is closed here | Deferred part |
|---|---|---|---|
| S004 | blocking | The Eve half: §6 runs every sandbox drill against the sandbox **tenant** of [21](21-sandbox-tenant-and-nonprod-foundation.md) and its own organisation sink, in `twin_shell --sandbox-org`, never against an OU of production; EV-6.1 proves the separation and EV-6.5 proves the negative | The tenant itself is [21](21-sandbox-tenant-and-nonprod-foundation.md); the Wall-E twin drills (G10, G11, G14, K6) are [37](37-wall-e-sandbox-rehearsal.md) |
| S039 | blocking | G-4's circularity is gone: EV-2.4 and EV-2.5 evidence a **seeded human super-admin change** in both tables within the lag budget; EV-9.3 rewrites the gate row; `walle@` shadow-run rows move to the post-grant list ([39](39-wall-e-stage-0.md)) | The twin-robot piece of SD-03 is [37](37-wall-e-sandbox-rehearsal.md); the consent login piece is [32](32-wall-e-consents.md) |
| S141 | major | EV-2.4 states that a missing `walle@` row before the grant is expected, forbids deleting or recreating the sink on that basis (sinks do not backfill), and EV-9.2 writes the post-grant robot-actor check into [39](39-wall-e-stage-0.md)'s list | The pre-grant/post-grant split of Phase 7 check 4 itself is [24](24-eve-workspace-identity-and-audit-feeds.md) |
| X-ORG-02 | blocking | The Eve half: EV-6.1 asserts that the twin sink's parent is `SANDBOX_ORG_ID`, that the production datasets hold no sandbox rows, and that no witness or export principal appears in the twin project; the drills read only the twin dataset | The sandbox sink creation is [24](24-eve-workspace-identity-and-audit-feeds.md); Wall-E's sandbox trigger sink is [37](37-wall-e-sandbox-rehearsal.md); the SIEM fixtures are [15](15-pager-siem-and-detections.md) part B |
| X-ORG-12 | major | SD-26's split is executed: §6 is the sandbox part (nonprod channels only, no witness contact, no row in `eve_mirror`), §4 is the witness part (production `eve-export@`, after the first heartbeat, before the grant), and a witness administrator uploads both records under their own witness account, which is not a cross-organisation grant | Nothing |

Nothing is deferred without an owner and a date. The two conditional deferrals inside the file — EV-5.3 (B-08) and EV-6.2 to EV-6.4 (B-08, B-09) — are owned by the Eve owner and due before the super-admin gate of [38](38-super-admin-gate-and-grant.md), and are carried in README's BLOCKED index and in `DEVIATION_REGISTER`.

## 14. What could not be verified on 2026-09-15

- The exact BigQuery field path of the Workspace event object in a partitioned audit-log export (`protopayload_auditlog.metadataJson` with an `event` array). The Cloud Logging filter form `protoPayload.metadata.event.eventName` is documented; the BigQuery export's column spelling is not stated on the pages read. EV-2.4 therefore prints one raw row first and corrects the query by eye, recording the result as `BD-28-3`.
- The column names of `eve_workspace_reports` and of `eve.incidents` / `eve.pages`. They come from Eve's committed schemas (`EVE_SCHEMAS_COMMIT`, README B-07) and are read at the step, never assumed.
- Whether the organisation's paging service can show the second human an incident's full recipient list and its configuration-change log without an administrator role on that service. Asked of IT security in [04](04-purchases-and-lead-times.md); if it cannot, EV-2.3's recipient check falls back to the mail headers plus `eve.pages`, and the gap is recorded.
- Whether Eve's configuration fingerprint includes scheduler state. EV-5.4 tests both outcomes and turns "neither" into a dated finding against [26](26-eve-reporting-and-witness-export.md).
- Whether the Admin console refuses a custom role with zero privileges. EV-1.2 handles both cases.
- The sandbox tenant's edition eligibility for every SA-rule fixture (SD-29, P66). §6 uses only fixtures the sandbox edition supports and names any it cannot run.

## 15. Sources read on 2026-09-15

| Fact used | Page |
|---|---|
| Audit-log lag and retention per Workspace stream | Workspace admin help, *Data retention and lag times for Google services* |
| `activities.list` path, `applicationName` values and query parameters | Workspace Admin SDK, *Reports API v1, activities.list* |
| `ASSIGN_ROLE`, `CREATE_ROLE`, `ADD_PRIVILEGE`, `REMOVE_PRIVILEGE`, `RENAME_ROLE`, `UNASSIGN_ROLE` and their parameters | Reports API appendix, *Admin activity events — delegated admin settings* |
| `CREATE_ORG_UNIT`, `EDIT_ORG_UNIT_NAME`, `EDIT_ORG_UNIT_DESCRIPTION`, `MOVE_ORG_UNIT`, `REMOVE_ORG_UNIT` | Reports API appendix, *Admin activity events — org settings* |
| Workspace audit logs at Cloud organisation level; service names per stream | Cloud Logging, *Audit logs for Google Workspace* |
| `protoPayload.metadata.event.eventName` filtering with `resource.type="audited_resource"` | Cloud Logging audit documentation and the Workspace login samples |
| Admin console path to Admin log events | Workspace admin help, *Admin log events* |
| `gcloud pam grants create` / `approve` / `list` flags | gcloud reference, `pam grants` |
| `gcloud scheduler jobs pause` and `resume` | gcloud reference, `scheduler jobs pause` |
| No gcloud command lists Monitoring incidents; groups are dashboards, policies, snoozes, uptime | gcloud reference, `monitoring` |
| Metric absence needs a first data point; window at most 23.5 hours | Cloud Monitoring, *Metric-absence conditions* |
| A locked retention policy can never be removed or shortened; objects are held until they meet the period | Cloud Storage, *Bucket Lock* |
| `gcloud storage ls` flags | gcloud reference, `storage ls` |

## Related

- [README.md](README.md) — the order, the BLOCKED index and the re-run index
- [25-eve-human-super-admin-detections.md](25-eve-human-super-admin-detections.md), [26-eve-reporting-and-witness-export.md](26-eve-reporting-and-witness-export.md), [27-witness-grants-and-alarms.md](27-witness-grants-and-alarms.md) — what this file proves
- [21-sandbox-tenant-and-nonprod-foundation.md](21-sandbox-tenant-and-nonprod-foundation.md) — the tenant §6 runs against
- [37-wall-e-sandbox-rehearsal.md](37-wall-e-sandbox-rehearsal.md) — the Wall-E half of the sandbox drills
- [38-super-admin-gate-and-grant.md](38-super-admin-gate-and-grant.md) — the gate that reads G-2 to G-7
- [42-gates-drills-and-evidence.md](42-gates-drills-and-evidence.md) — reviews DR-28-1 to DR-28-3
- [../../eve/05-stages.md](../../eve/05-stages.md) — the superseded gate table
- [../../eve/07-build-runbook.md](../../eve/07-build-runbook.md) — the superseded Phase 10b drill
- [../13-setup-procedure-review.md](../13-setup-procedure-review.md) — the review this answers
