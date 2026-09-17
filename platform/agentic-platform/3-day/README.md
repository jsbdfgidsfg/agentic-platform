# The three-day build. Two people, six person-days, three agents

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-17
- What this is: the one entry point to the three-day procedures in this folder,
  [day 1](day-1-platform-and-eve.md), [day 2](day-2-the-doer.md),
  [day 3](day-3-mo-demonstration-and-handover.md) and [the code](code.md). It holds the claim, the
  nine absolutes, the team, the order, the project names, the eleven things three days cannot buy,
  the cut list C-01 to C-27 and the unwind. **No step is executed from this page.**
- Answers the owner's request of 2026-09-17: something two IT experts can implement in three
  business days with a simple procedure, with VS Code and Google Code Assist, as Workspace super
  admins and owners of four GCP projects they create themselves.
- Counterparts, neither replaced: the proof-of-value set [../pov/README.md](../pov/README.md)
  (20 to 26 person-days of procedure, 6 to 20 weeks elapsed) and the full build
  [../setup/README.md](../setup/README.md) (6 to 7 months to Stage 0). This set is the smallest
  thing in this wiki and grows into both (§12).
- Maturity: never executed. Nothing here is built. Where a day file and this page disagree on a
  command, a flag or a console path, **the day file is right and this page is corrected**, unless
  the day file breaks a rule of this page, which is a defect in the day file. The exceptions run the
  other way and are listed, not scattered: §6.1 and the rows marked **owed** in §10 are corrections
  the day files do not yet carry and must be given before the run.
- Sizing, restated from the three day tables rather than from a nominal day: each day runs 08:30 to
  17:30 with a **90-minute** break, so **450 usable minutes** per person per day. Each day allocates
  **375 minutes** of blocks, leaving **75 minutes** of reserve, not the 105 the day tables claim.
  Over three days: 37.5 person-hours allocated, 7.5 reserved. **Seventy-five minutes does not cover
  a single one of the block overruns in §6.1**, which is the honest version of R-08.
- **Read §6.1 before booking the three days.** Six corrections have to be made to the day files
  before the run starts. They cost nothing on the day and the run does not fit without them.

## 1. The claim, in one sentence

The closing report uses this sentence and no other, with the dates filled in:

> Between `<day 1>` and `<day 3>`, on the production tenant, with two people and no new contract,
> the containment machinery of an agentic platform was built and run: four projects with budgets and
> deletion liens, and a Model Armor floor on the two of them that can call a model; a controller
> (Eve) reading the Workspace admin audit log
> through the Reports API and paging a human, live before any doer existed; a doer (`steward`)
> holding one organisational-unit-scoped Workspace admin privilege over four synthetic accounts,
> whose model holds no credential, whose every action is written ahead to an audit table, whose
> first level forces a dry run and whose execution needs a second human; two kill levers pulled and
> timed during live work; and an improver (Mo) counting the doer's own rows against a volume
> baseline read from Google's admin history. Every artefact carries the full build's name, schema
> and folder.

A clause whose record is missing or failed at the end is **struck from the sentence, not softened**.

### 1.1 Never to be used, in any report, slide or message

Copied unchanged from [../pov/README.md](../pov/README.md) §1.2, and one more:

1. "Wall-E is safe as a super admin." Nothing here touches super-admin containment. No agent holds
   Super Admin at any moment of the three days.
2. "Eve is independent." Independence in the design is structural: a witness organisation, a second
   tenant. This set has neither (C-01), and its Eve lives inside the reach of the administrators it
   watches.
3. "Model Armor blocked the injection." A probabilistic content screen is never a trust boundary.
   And nothing here exercises it: no step sends anything through the floor, so these three days
   produce **no Model Armor evidence at all**, only the floor settings themselves (C-22).
4. "We saved `<n>` minutes of admin work." The doer acted only on synthetic accounts. No human minute
   was saved, and Mo's scorecard says so in bold (C-07).

## 2. The nine absolutes

Binding on every file in this folder. **A step that loosens one is a defect, not a deviation.**
Restated verbatim from the owner's brief of 2026-09-17.

1. **No domain-wide delegation, ever.** Each robot holds its own consented refresh token and is
   never impersonated. Prove its absence in the Admin console rather than assuming it.
2. **The model holds no credential and cannot approve.** The action service is the only credential
   holder. No service identity is ever the second person.
3. **A dry run never mutates.** The first level forces it, records the would-be verdict and refuses
   to execute even when handed a valid approval.
4. **Two people.** Person A never approves or verifies their own work: the role assignment, the
   consent sitting, every execution and every drill result involve person B.
5. **Model Armor's floor on every project that can call a model.** It produces evidence, never a
   boundary.
6. **Kill switches built and pulled on the day:** halt writes, and revoke the credential. Record
   that an access token already issued may stay valid for up to an hour, so the halt is what stops
   work now.
7. **Nothing mutating touches a real employee's account.** The pilot organisational unit holds
   synthetic accounts only, and the procedure refuses to run if a real account is in it.
8. **Write-ahead audit:** the row is written before the call, and no action runs when the audit
   write fails.
9. **Never `--yes` on a destructive command; never a default gcloud project** (pass `--project`); no
   secret is printed, echoed or committed; secrets live in Secret Manager and are read by one
   identity.

On absolute 7, two things bind and neither is optional. **The pilot organisational unit is never
widened to the organisation root.** The action service compares the target's `orgUnitPath` for
**exact equality**, not as a prefix, and day-2 `T2-24`'s scope test currently widens it to the
parent of `/pilot`, which is `/`. As written the test proves nothing (the service refuses the
request itself and Google is never asked); repaired into a prefix match it would accept every
account in the tenant for the duration. Set the override to the exact path holding the one synthetic
target, `/nonprod`, read `/control/status` back before and after, and record that the test is
exact-match so nobody converts it. And **the synthetic-population guard runs on day 3 as well**, as
the first line of the demonstration block: the procedure that "refuses to run if a real account is
in it" must look on the day it matters most.

On absolute 8, precisely: the write-ahead row is written before any Google call, and the refusals
that happen **before** that point (halt, catalogue, tenant, synthetic prefix, protected principal,
level cap) produce an `outcome` row only. That is correct, because nothing was called and there is
nothing to write ahead of. Say which negatives produce an intent row and which do not, rather than
claiming a strictly earlier intent row for all of them, and count requests by distinct `request_id`
rather than by intent rows, or the scorecard shown to the sponsor undercounts every early refusal.
Moving the audit write to make the claim come out is the one edit that breaks this absolute.

On absolute 5, honestly: the floor is **set** on the two projects that can call a model, and it is
met as configuration only. No step in the three days sends a prompt through it, records a Model
Armor finding, or verifies that a floor at `projects/<p>/locations/global/floorSetting` applies to
the regional Vertex call the prompt tool makes. Say "the floor was set and never exercised", never
"Model Armor produced evidence" (C-22). The flag values themselves are `Assumption:`, read from the
installed gcloud on the day, not from this page (R-06).

On absolute 6, honestly: Google's OAuth 2.0 page says only that "Access tokens have limited
lifetimes" and does not publish a figure (read 2026-09-17, §15). `Assumption:` up to 60 minutes is
the planning figure, carried over from
[../../wall-e/04-flows.md](../../wall-e/04-flows.md). The drill on day 2 measures the real residue
rather than quoting this.

## 3. The team, and what they hold

Two people, for three business days. Roles, never names; they and them, never he or she.

| | Person A | Person B |
|---|---|---|
| Does | builds | approves, witnesses, receives Eve's reports |
| Workspace | super admin | super admin |
| GCP | owner of the four projects | owner of the four projects |
| Never | approves or verifies their own work | builds the thing they approve |
| Tools | VS Code, Google Code Assist, gcloud, bq, a browser | the same, plus their own mailbox for alerts |

- **Every file of code they need is written out in [code.md](code.md)**: seven files, complete and
  pasteable. Code Assist is for adapting them (a project id, a region, a domain), not for inventing
  them. Neither person is expected to design code in three days.
- A **sponsor** is needed for two things only: to receive a finding whose subject is person B
  (C-19), and to watch the demonstration on day 3. Name them on day 1, in writing, before Eve goes
  live. They do no work.
- Nobody else is appointed. There is no security reviewer, no blind grader and no incident commander
  (C-08, C-15, C-19), and no envelope witness or validator custodian (C-27): key custody rests on
  two signatures in the run log.

## 4. The order, and the one ordering rule

**Eve is live before the doer exists.** This is the only ordering rule of the whole design, and it
is not negotiable for time. The controller that watches admin activity must be running, paging a
human and proven by a seeded test **before** any robot account with an admin privilege exists.

The proof of the rule is built in: the robot account and its role assignment are created on day 2
morning, and **day 2 block D2-B1 confirms that Eve paged that very assignment**. Eve saw the doer
being born. If Eve did not page it, the doer stops there and day 2 becomes a repair day.

| Day | Date (Assumption) | What is built | Ends when |
|---|---|---|---|
| 1 | 2026-09-22 | four projects, datasets, Model Armor floor on the two that call a model, the read-only admin account, its own OAuth client and one consent, the poller, the detections, the alerting; and, brought forward, the pilot organisational unit, four synthetic accounts, the custom role created but assigned to nobody, **the doer's audit dataset, its two tables, its two service accounts and its three secrets with the halt seeded `off`, and the doer's own OAuth client marked Trusted** (§6.1 rows 2 and 4) | person B **alone** confirms the alert from a seeded harmless super-admin action |
| 2 | 2026-09-23 | the robot account, its one organisational-unit-scoped privilege, its consent, the action service, the one reversible pair, the policy chain, the write-ahead audit rows, the prompt tool | nine live results witnessed, the halt and the revoke pulled by person B and timed |
| 3 | 2026-09-24 | Mo's views, the retrospective volume baseline, the scorecard, one improvement merged by a human, the demonstration, the evidence pack, the hand-over | the unwind is signed, the same day |

Why the pilot organisational unit, the synthetic accounts and the unassigned custom role move to
day 1: role assignment propagation is the one risk with no code fix (§11, R-01). Google says "The
user typically becomes an admin within a few minutes. However, it can take up to 24 hours" (§15,
read 2026-09-17). Building everything except the assignment on day 1 lets the assignment land at
about 09:45 on day 2 and the first execution wait until about 15:00.

Why the doer's audit tables, service accounts, secrets and OAuth client also move to day 1: day 2
reads all of them back as though they already existed, and nothing on day 1 creates them (§6.1 rows
2 and 4). Left as they are, day 2 loses about half an hour at 10:15 and another half hour at 13:15,
in the two blocks that have the least room. The doer's OAuth client is inert until the consent at
day-2 `T2-17`, and creating it on day 1 also buys the Trusted marking an overnight propagation
window, which is what R-02 assumes and does not currently get.

## 5. The four projects, and why the doer's project is not called `walle`

Four GCP projects, created and owned by the two people.

**`names.env`, written once at day-1 `T1-1`, is the only source of every name in these three days.**
This page and [code.md](code.md) quote it and never restate it. Project ids are globally unique and
never reusable, so a wrong paste on day 1 is not recoverable: fix the ids at `T1-1` and change
nothing afterwards.

| Variable | Id at `T1-1` (`SUFFIX=d3`, `Assumption:`) | Holds | Model Armor floor |
|---|---|---|---|
| `CORE_PROJECT` | `agp-core-${SUFFIX}` | Artifact Registry, the evidence dataset, the shared budget | **yes** |
| `EVE_PROJECT` | `agp-ctl-eve-prod-${SUFFIX}` | `eve` dataset, the Reports API poller job, the scheduler, the detections, the alerting policies, the read-only refresh token | no (calls no model) |
| `DOER_PROJECT` | `agp-p-steward-prod-${SUFFIX}` | `steward_audit` dataset, `steward-actions`, `steward-plan`, the robot's refresh token, the halt secret | **yes** |
| `MO_PROJECT` | `agp-imp-mo-prod-${SUFFIX}` | the five metric views, the retrospective volume table, the scorecard | no (calls no model) |

Two values in `names.env` carry absolute 7 and must have exactly one spelling across every file,
because a mismatch means a request is refused for the wrong reason or a target is built that nothing
can act on: **`PILOT_OU="/pilot"`** and the synthetic local-part prefix **`pilot-user-`**, which is
what day-1 `T1-16` actually creates. [code.md](code.md) §0 and the `PILOT_OU` and `SYNTHETIC_PREFIX`
defaults inside `actions.py` (§3) and `plan.py` (§4) must be corrected to these before the run
(§6.1 row 6), and the defaults should be values that cannot match anything, so a lost environment
variable is a hard failure rather than a silent fall-back to a plausible path.

Mo's five views live in `MO_PROJECT`, reading `DOER_PROJECT.steward_audit.actions` across projects.
[code.md](code.md) §5 must say the same before the run (§6.1 row 3); two files claiming to be
`mo.sql` is a defect, not a choice made on the day.

**The doer's project is not called `walle`, and the doer's `agent_id` is `steward`.** The reason is
the same one the proof-of-value set gives ([../pov/README.md](../pov/README.md) §3):
[../setup/31](../setup/31-wall-e-project-and-data-plane.md) creates `WALLE_PROJECT` in the
privileged super-admin tier folder. Project ids are never reusable and a project is never moved
between tier folders ([../02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §1.5).
Spending the name here, at a tier that grants no Super Admin, would force the full build to rename
Wall-E. So `walle`, `WALLE_PROJECT`, `walle_audit` and `EVE_WITNESS_PROJECT` are **reserved and
never used by a step in this folder**. Everything the doer produces (its code, schemas, catalogue,
consent procedure, kill switch and audit table) carries over to Wall-E unchanged.

Eve and Mo keep their own names, because they carry across every set: `eve`, `EVE_PROJECT`,
`eve.ws_activities`, `eve.findings`; `mo`, `MO_PROJECT`, `mo_volume_by_verdict` and its four
siblings.

## 6. What must be true before day 1 starts

Check these the week before. Each one, unmet, costs hours on the day.

| # | Must be true | How to check | If it is not |
|---|---|---|---|
| 1 | Both people are genuinely free for three days | a calendar block, accepted, with their manager told | stop. Six person-days means six person-days (R-08) |
| 2 | Both hold Workspace super admin and can reach the Admin console | Admin console loads and shows Account > Admin roles | stop |
| 3 | A billing account exists, both can link projects to it, **and whoever runs day-1 `T1-4` can create a budget on it** | Billing > Account management shows the account and a Billing Account User or Administrator role; budget creation needs more than Billing Account User, so check it against the account rather than assuming | stop. A new billing account is 2 to 5 days (`Assumption:`, [../setup/07](../setup/07-billing-account.md)); a missing budget role costs the first hour of day 1 |
| 4 | The organisation permits project creation by these two | `gcloud projects create` succeeds for a throwaway id, then delete it | ask the Cloud organisation administrator for `roles/resourcemanager.projectCreator`, a day ahead |
| 5 | `gcloud`, `bq` and Python 3.12 are installed on person A's machine | `gcloud version`, `bq version`, `python3.12 --version` | install the week before, not on day 1 |
| 6 | Both admin accounts have two-step verification with a security key, and spare keys exist for the robot | Admin console > Security > Authentication > 2-step verification | order keys now. Allow up to 7 days before a new key works (`Assumption:`, [../setup/11](../setup/11-keys-and-validator-custodian.md)) |
| 7 | Person B has a mailbox they alone read, for alerts | send a test mail | the seeded test cannot prove anything if both read the box |
| 8 | A sponsor is named, in writing | one line in the run log | C-19 has no recipient for a finding about person B |
| 9 | Four synthetic account names are agreed and are nobody's | the names are not in the directory | pick names no leaver could ever hold |
| 10 | Nothing in scope is a real employee account | the pilot organisational unit is empty at the start of day 1 | absolute 7 |
| 11 | **The six corrections in §6.1 are made in the day files** | each row of §6.1 reads back as done, by the person who did not make it | three days does not fit. Say four days, or run three and strike the executed pair from the claim |
| 12 | `gcloud auth print-identity-token --audiences=<a Cloud Run URL>` works on **both** people's accounts | run it once, the week before, against any Cloud Run URL. Every live call to the action service depends on it | set up the impersonated caller service account named in §11 before the run, not at 14:45 on day 2 |

Read on the day, not from this page: the Google Auth Platform console path for a Desktop OAuth
client with an Internal audience; whether `gcloud resource-manager liens create` is generally
available on the installed gcloud version; the current `gcloud beta model-armor floorsettings
update` flags. Each has a step that fails loudly rather than a guess (§11).

## 6.1 The corrections the day files need before the run

Made at a desk the week before, each costs minutes. Left in place, each costs a block on the day, in
the blocks that have the least room. **Three days is achievable with these six done and is not
achievable without them.** Nothing below is executed from this page; each row names the file and the
step that must carry the change.

| # | Correction | File and step | What it costs if left |
|---|---|---|---|
| 1 | **One audit vocabulary, taken from the code.** `actions.py` writes eighteen columns (`row_id, ts, agent_id, request_id, phase, operation, target, level, requester, approver, approval_nonce, verdict, denial_reason, request_hash, dry_run, halt_state, google_status, detail`), `phase` is `intent` or `outcome`, `verdict` is `attempting`, `dry_run`, `executed`, `denied` or `error`, denial reasons carry no prefix, and the catalogue is `suspend` and `restore`. Day 3 is written against a different twenty-one-column schema and a different vocabulary, so its first check stops the day | rewrite day-3 `T3-1`, `T3-2`, `T3-8` and `T3-15` against [code.md](code.md) §3, and have `T3-2` paste [code.md](code.md) §5 unchanged the way day-1 `T1-21` pastes §2 | 45 to 75 minutes lost on the morning of the demonstration, in a 90-minute block |
| 2 | **The doer's foundation is built on day 1, not assumed.** Day-2 `T2-9`, `T2-10` and `T2-11` read back a `steward_audit` dataset, its `actions` and `approvals` tables, the `steward-actions@` and `steward-plan@` service accounts and three secrets with the halt seeded `off`. No step in the three days creates them, and day 1 says the opposite | add them as numbered steps to day-1 `D1-A2`, with the eighteen columns the code writes; correct day 1's "What day 2 takes from here", which names `T2-7` as the creator, and `T2-9`/`T2-10`, which name a bootstrap script no day file runs. `stewardAuditWriter` must also carry `bigquery.tables.getData`, or the service cannot read its own approvals. Then **cut [code.md](code.md) §7 down to exactly what the day steps do, or delete it**: run as a recovery at 10:15 it sets a weaker Model Armor floor than day 1 agreed, grants project-wide `bigquery.dataEditor`, writes a third `ws_activities` schema, and aborts on the first already-exists | 25 to 35 minutes at 10:15 on day 2, in a block already over capacity, and every approved execution fails |
| 3 | **Eve's three tables match the code that writes them.** Day-1 `T1-9` creates a `ws_activities` schema the poller does not write, creates `poll_watermark` where the poller reads `poll_runs`, and never creates `watchlists`, which the detections view reads three times and no step ever populates | replace day-1 `T1-9`'s DDL with the three `bq mk --table` lines from [code.md](code.md) §7, add a step seeding `eve.watchlists` with the admin allowlist, the service identities and the control groups, and reorder `T1-19` to `T1-21` so the tables and the detections view exist **before** the first execution and the schedule is created last | Eve cannot run at all on day 1, so the one ordering rule fails and day 2 does not start |
| 4 | **The doer's OAuth client is created and marked Trusted on day 1**, beside `T1-13` and `T1-14`, and the day-2 re-consent does not create a second client at 16:45 | move day-2 `T2-16` into day-1 `D1-B2`; make day-2 `T2-26` re-consent to that client, or move the re-consent to 08:30 on day 3 | about 28 minutes out of the tightest afternoon block, and a consent that can fail on a marking Google says "can take up to 24 hours" to apply (§15) |
| 5 | **One Directory-scoped credential, established once.** Day-2 `T2-5` and `T2-8` and day-3 `T3-19`'s read-backs call Admin SDK Directory endpoints with `gcloud auth print-access-token`, whose user credential carries no Directory scope. The synthetic-population guard reads the 403 body as an empty user list and prints `count=0`, which stops the day for the wrong reason | add a pre-flight step that logs person A in with `admin.directory.user.readonly` beside `cloud-platform`, record the scope grant in the run log, and add an HTTP-status check to the guard so a 403 is reported as a 403. The same guard runs again as the first line of day-3 `T3-15` | 15 to 30 minutes the first time, on the guard absolute 7 rests on, and absolute 7 goes unchecked on demonstration day |
| 6 | **One spelling of every name.** `names.env` (day-1 `T1-1`) is the source; [code.md](code.md) §0 must source it rather than restate three different project ids, `/Automation/Pilot` and `steward-pilot-` (§5) | correct [code.md](code.md) §0 and the defaults in §3 and §4; correct day-2's opening gate, which selects a `ts` column that exists in no schema, to `MAX(ingested_at)` | a failed command at the opening of each of the three mornings, and a gate that cannot tell a live Eve from a broken one |

These smaller corrections belong with them. Each is a line or two, and each stops or silently skips
a step.

| Correction | File and step |
|---|---|
| `eve-reader@` registers its security keys in a staging organisational unit and is moved afterwards, exactly as the robot is. The service-identity organisational unit forces a key the account cannot register until it can sign in once | day-1 `T1-6`, mirroring day-2 `T2-2` and `T2-4` |
| Drop `--set-secrets` from the poller deploy: the job reads its own secret, and the flag only copies the token into the job's environment, readable by anyone with `run.viewer` (absolute 9). Add day-2 `T2-18`'s "no secret-looking value in env" scan to day 1's verify and its closing checklist | day-1 `T1-19` |
| Escape the comma-bearing `APPS` value with gcloud's alternate delimiter, `--set-env-vars=^:^EVE_PROJECT=...:APPS=admin,login,...`, or drop the flag, since the code's default is already that list. "In order to include commas in your arguments, specify an alternate delimiter" (`gcloud topic escaping`, read 2026-09-17) | day-1 `T1-19`, [code.md](code.md) §1 |
| `COUNT(*) AS rows` does not parse: `ROWS` is reserved and must be backquoted. Use `AS n` | day-1 `T1-20` |
| Give person B work in the 14:30 block that does not depend on person A. As written, B waits for A's poller to write rows before the absence policy can be created, so a poller fault stalls both people at once. Move the notification channel and **its emailed verification link** into the morning, so the click has hours to happen, and create the two log-based metrics in the morning too; only the absence condition genuinely needs a data point | day-1 `T1-22`, `T1-23`, `D1-B3` |
| Re-seal `eve-reader@`'s working password, or do not change it after the first sign-in. As written the sealed envelope holds a password that no longer works, the account has no recovery email or phone, and losing both keys loses the account the ordering rule depends on. Add both envelopes, Eve's password and the doer's keys, to the unwind with a destroy-or-retain decision, read back and signed | day-1 `T1-6`, day-3 `T3-19` |
| Move the two read-only steps (the delegation baseline and the synthetic-population read) into person B's parallel block, so the morning is not two people at one keyboard. It is the only 25 minutes recoverable in that block | day-2 `T2-5`, `T2-6`, `D2-B1` |
| Start the seeded test at 15:45, or shorten the poll schedule and the alerting alignment period for its duration and restore both afterwards. The chain's tail is 35 to 45 minutes when it is working correctly, against a 45-minute stop rule at 16:45 on day 1 | day-1 `T1-24` |
| Add `billingbudgets.googleapis.com` to the API set for `CORE_PROJECT`, and check the billing role budget creation actually needs, not only Billing Account User | day-1 `T1-3`, §6 row 3 |
| The custom role's numeric id is written into `names.env` as `PILOT_ROLE_ID`. Day 3 cannot delete a role whose id nothing recorded | day-2 `T2-7` |
| Write the client JSON to one path chosen once, consent, then shred it and prove it is gone. As written the write and the removal use different paths on any host where `TMPDIR` is set, leaving the client secret behind | day-2 `T2-17` |
| The consent tool passes `open_browser=False`, so it prints the URL and waits, which is what both sittings describe; it compares the **granted** scopes returned by the token endpoint, not the scopes it requested, which is a tautology; and it does not index into an empty stderr | [code.md](code.md) §6, used by day-1 `T1-17` and day-2 `T2-17` |
| The audit and approval helpers catch transport and permission failures, not only the row-level error list, and re-raise as a `503 audit_unavailable`. Otherwise the test that proves absolute 8 returns a traceback instead of the designed denial. Add a selftest case for it | [code.md](code.md) §3, exercised by day-2 `T2-24` |
| Correct the denial reason each live negative actually produces (person B's address is refused as `not_synthetic`, one step before the protected-principal check) and replace the closed list of reasons with the full set the code raises, since person B is asked to confirm there are no others | day-2 `T2-9`, `T2-22` |
| `steward-plan` gets its own directory with its own `Procfile`, `requirements.txt` and `.python-version`; one Cloud Run source build reads one `Procfile` per directory, so the service and the job cannot share one. The deploy sets `VERTEX_LOCATION`, which is the variable the code reads | day-2 `T2-12`, `T2-20`, [code.md](code.md) §4 |
| `gcloud run jobs executions` has no `logs` subcommand. Read the execution's logs with `gcloud logging read 'resource.type="cloud_run_job" AND resource.labels.job_name="steward-plan"'` (reference read 2026-09-17) | day-2 `T2-24` |
| Day 3 uses the variable names day 1 and day 2 actually write (`ORG_DOMAIN`, `PERSON_A_EMAIL`, `PERSON_B_EMAIL`, `STEWARD_OAUTH_CLIENT_ID`), or its first command aborts and the day opens on a failure | day-3 preconditions, `T3-19c` |
| The secret-disable loop carries a project per secret, and fails loudly on an empty version list. `eve-refresh-token` lives in `EVE_PROJECT` | day-3 `T3-19d` |
| Fix the retrospective export window by volume, not by retention: run one trial search and cut the window to 30 or 90 days if it exceeds roughly 20,000 rows, rather than slicing eighteen exports against the 100,000-row cap. Say which window was used in the scorecard | day-3 `T3-5` |
| Draft the hand-over note in the late-morning block, so 16:15 is signing rather than composing, and start the unwind at 16:00 | day-3 `T3-18`, `T3-19` |
| The poller steps its watermark by one millisecond, matching the precision it formats, or the same millisecond is re-requested on every poll and duplicate rows inflate Mo's counts | [code.md](code.md) §1 |
| The scorecard's closing statement is one string, or joined with `\|\|`. Two adjacent literals do not concatenate in GoogleSQL and the whole script fails to parse, taking all five views with it | [code.md](code.md) §5 |

**If the six are not made, the honest statement is four days**, or three days ending with the
executed pair struck from the claim rather than softened (§1).

## 7. What three days cannot buy

Eleven things. Every file in this folder repeats the ones it touches, and no report may imply
otherwise.

1. **No super admin for any agent, and no evidence about super-admin containment.** The doer holds
   one privilege on one organisational unit. Nothing here says anything about what a super-admin
   robot would do.
2. **No witness organisation and no second tenant.** Eve lives inside the reach of the
   administrators it watches, so Eve is never called independent.
3. **No security information and event management contract, no managed detection, no 24x7
   acknowledgement.** Alerts go to one mailbox, during working hours, on an attended run.
4. **No penetration test and no Security Command Center Premium.** Nothing is exposed to the
   internet, which is a reason not to need one here, not evidence that there is nothing to find.
5. **No Terraform factory, no register continuous integration, no Binary Authorization.** Four
   projects built by hand and read back by hand.
6. **No privileged-access management entitlements, and no time-boxing either.** Every IAM binding in
   these three days is an ordinary standing grant: each one passes `--condition=None`, so nothing
   expires by itself. They are removed by hand on day 3 (§10) and by nothing else. gcloud does
   support a real expiry (`--condition='expression=request.time < timestamp("..."),title=...'`,
   `gcloud projects add-iam-policy-binding`, read 2026-09-17) and the day files do not use it; if
   that is wanted, it is a pre-run correction to every binding in day-1 `T1-12` and `T1-15` and
   day-2 `T2-10`, `T2-19` and `T2-20`, not a claim to make about the run as written.
7. **No autonomy beyond a forced dry run and a two-person approved execution.** No unattended
   running at any moment, no ladder, no dwell period.
8. **No four-week toil baseline, so no defensible claim of minutes saved.** The retrospective
   baseline gives volume, not saved time.
9. **No data-protection impact assessment and no works-council information completed.** This is
   exactly why nothing mutating may touch a real account.
10. **No Gemini Enterprise, no agent gateway, no Agent Registry row.** The prompt tool calls a model
    on Vertex AI directly, and holds no credential.
11. **It is a demonstration of machinery under control. It is not compliance evidence and it is not
    a production grant.** Say this sentence to the sponsor before the demonstration, not after.

## 8. The cut list, C-01 to C-27

Twenty-seven things the full design has and these three days do not. Each is safe **only** because
the population is synthetic, the run is attended and nothing is claimed as compliance evidence. The
unwind column names the file and step that puts the piece back.

| Id | Cut | Why it is safe here | Where it comes back |
|---|---|---|---|
| C-01 | No witness organisation, no second tenant. Eve lives inside the reach of the administrators it watches | Nothing is claimed about Eve's independence; §1.1 bans the sentence | [../setup/08](../setup/08-witness-organisation.md); [../setup/27](../setup/27-witness-grants-and-alarms.md) `WI-*` |
| C-02 | No organisation log sink. Eve reads the Admin SDK Reports API instead | The team may hold only project-level GCP access; the admin log lag is minutes, so the poll sees what a sink would | [../setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) `EW-1.2` to `EW-1.11` adds the sink beside the poll |
| C-03 | No SIEM contract, no managed detection, no 24x7 acknowledgement | Alerts go to one named person's own mailbox and are confirmed by that person alone, in working hours | [../setup/15](../setup/15-pager-siem-and-detections.md) |
| C-04 | No penetration test, no Security Command Center Premium | Nothing is exposed: the action service is deployed `--no-allow-unauthenticated` and `run.invoker` goes to named principals only | [../setup/09](../setup/09-folders-and-security-command-center.md) |
| C-05 | No Terraform factory, no register CI, no Binary Authorization, no zero-diff checker | Four projects built by hand in one morning and read back by hand the same morning | [../setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md) `FM-2.1` onwards |
| C-06 | No privileged-access-management entitlements, and no time-boxing. Standing IAM grants stand in, removed by hand on the last day | The grants outlive the run by hours, not weeks, and day 3 removes them in front of both people and reads the bindings back. Nothing expires on its own, so the removal is the only control and it is a human one | [../pov/03](../pov/03-foundation-folders-logging-and-floors.md) `PF-5.1`; [../setup/12](../setup/12-privileged-access-catalogue.md) |
| C-07 | No four-week prospective toil baseline. Retrospective volume only, and no minutes | Volume can be counted backwards because Google keeps admin log events six months and administrators cannot delete them. Minutes cannot be counted backwards, so none are claimed | [../setup/02](../setup/02-toil-baseline.md) `TB-1.2` sets the start date and records four prospective ISO weeks |
| C-08 | No blind grading, no double-graded subset, no agreement record | Blind grading needs a third person who is neither builder nor approver, and there are two people | [../pov/08](../pov/08-mo-and-the-value-report.md) `PM-7.1` to `PM-7.3` |
| C-09 | One reviewer on the improvement pull request, not two | The author is person A and the only other human is person B, so the merge still has a reviewer who is not the author; the rule that matters is kept, which is that nothing machine-written merges itself | [../pov/08](../pov/08-mo-and-the-value-report.md) `PM-9.2` |
| C-10 | No autonomy ladder walk. No two weeks at L1 and two at L2 | There is no unattended running at any moment, so there is no dwell for a dwell period to protect | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) `PW-6.2` |
| C-11 | No Gemini Enterprise, no Tier C agents, no agent gateway, no Agent Registry, no engine registration | The only component that can act is the action service, reachable by two named principals | [../pov/05](../pov/05-gemini-enterprise-and-tier-c.md); [../setup/19](../setup/19-gemini-enterprise-import-and-baseline.md), [20](../setup/20-gemini-enterprise-gateway-and-tier-c-gate.md), [35](../setup/35-wall-e-engine-registration-and-gateways.md) |
| C-12 | No data-protection impact assessment, no works-council information | This is exactly why nothing mutating touches a real employee: four synthetic accounts are the whole population, and the procedure refuses to run if a real account is in the pilot organisational unit | [../pov/02](../pov/02-decisions-people-and-the-retrospective-baseline.md) `PD-8.0`; [../setup/03](../setup/03-decisions-and-people.md) |
| C-13 | No locked evidence bucket with a locked retention policy. A dataset and a deletion lien stand in | Locking a retention policy is irreversible, and a wrong lock made in a rushed three days cannot be undone | [../pov/06](../pov/06-eve-over-the-human-super-admins.md) `PE-4.1` to `PE-4.5` |
| C-14 | No customer-managed encryption keys, no key rings. Google-managed keys throughout | Key delivery alone is a week, and the data is synthetic | [../pov/06](../pov/06-eve-over-the-human-super-admins.md) `PE-2.1` to `PE-2.4` |
| C-15 | No decision-record machinery: no `decision-need.sh`, no NAMES records, no `penv_guard`, no `checkpoints.tsv`. One `names.env` and one run log | Two people in one room sign on paper; the machinery exists to bind many people over months | [../pov/01](../pov/01-conventions-and-variables.md); [../pov/02](../pov/02-decisions-people-and-the-retrospective-baseline.md) `PD-3.2`, `PD-4.1` |
| C-16 | No Firestore, no point-in-time recovery, no daily backup, no restore drill. The audit table is BigQuery only | The only durable state that matters is the audit, and it is written ahead into BigQuery before every call | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) `PW-2.3`, `PW-2.8` |
| C-17 | No nonprod project for any agent and no nonprod ladder test | Nothing is promoted, so there is nothing for a nonprod environment to rehearse | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) `PW-2.1`; [../setup/21](../setup/21-sandbox-tenant-and-nonprod-foundation.md) |
| C-18 | No approval surface behind Identity-Aware Proxy. Person B approves with one authenticated call from their own account, carrying a nonce | The approver is in the room and signs the paper record as well as making the call | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) `PW-4.5` |
| C-19 | No security reviewer and no separate routing. Every finding goes to person B; a finding whose subject is person B goes to the sponsor, named on day 1 | With two people someone must still receive the report about the second person, and the sponsor is the only third party present | [../pov/06](../pov/06-eve-over-the-human-super-admins.md) `PE-0.3`, `PE-10.2` |
| C-20 | No unannounced Eve proof inside a 30-day window. The seeded test is same-day | Person A knows they are seeding but person B does not know when, so B's confirmation is still blind to the minute, which is what the test is for | [../pov/06](../pov/06-eve-over-the-human-super-admins.md) `PE-12.1` to `PE-12.4` |
| C-21 | Six detections plus one freshness rule, not twenty-three | The six cover the events these three days can actually generate: a role assigned, an admin method outside the allowlist, a security-setting change, a delegation client added, a robot login, a membership change on a control group | [../setup/25](../setup/25-eve-human-super-admin-detections.md) `EH-2.3` |
| C-22 | Model Armor is **set and never exercised**. The floor settings are the only artefact; no step sends anything through it and the three days produce no Model Armor finding | It was never a boundary; §1.1 bans the sentence. The floor is on the two projects that can call a model, and whether a global floor setting reaches a regional Vertex call is not verified here | [../setup/18](../setup/18-model-armor-floor-spikes-and-kill-switch.md) |
| C-23 | K0 and K4 only. No K1 demote, no K2, no K3, no K7 | K1 demotes a ladder that does not exist under C-10; K0 and K4 are the two that stop work now and stop the credential | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) `PW-6.4` |
| C-24 | One reversible pair, not three. Suspend and restore on the pilot organisational unit, and nothing else | One pair proves write-ahead audit, the forced dry run, two-person approval and a kill; three pairs cost code and prove nothing new in three days | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) `PW-7.5`; [../pov/02](../pov/02-decisions-people-and-the-retrospective-baseline.md) `PD-4.3` sets the six-entry catalogue |
| C-25 | No organisation policies, no deny policies and no principal access boundary floor. The four projects sit under whatever the organisation already enforces, and these three days add nothing | The two people may hold only project-level access, so an organisation-wide floor is not theirs to set; the containment that is actually relied on is the organisational-unit-scoped admin role, the synthetic population and the two-person chain | [../setup/13](../setup/13-organisation-policies-deny-and-pab.md) |
| C-26 | No central log sink for the four projects and no billing export. Budgets and a deletion lien stand in for cost control, and each project keeps its own default logs | Four attended projects for three days, watched by the two people who built them; nothing runs unattended, so there is no window in which an unread central log would have been the only witness | [../setup/14](../setup/14-central-logging-and-billing-export.md) |
| C-27 | No key ceremony, no validator custodian, no envelope witness. Key custody rests on two signatures in the run log | Four hardware keys and two sealed envelopes, handled by the two people in one room over three days, both of whom already hold super admin. There is no third party present to witness a ceremony, and inventing one would be theatre | [../setup/11](../setup/11-keys-and-validator-custodian.md) |

## 9. The two decisions already made, and what they mean

**The doer does real admin work, on synthetic accounts.** A dedicated robot account holds one custom
Workspace admin role, scoped to a pilot organisational unit that contains only synthetic accounts,
carrying the smallest privilege that makes a reversible pair possible: Users > Update > Suspend
Users, with Users > Read. The doer suspends a synthetic user and restores it. That is a real
Admin-console task, fully reversible, and it lands in the admin audit log, so Eve sees it and Mo
counts it. This is the shape already written and verified in
[../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) §7, compressed into one day.

Why this privilege and not another: Google's page on creating an admin role for an organisational
unit lists the categories that **can** be limited to an organisational unit, and Users is one of
them; Groups is not, and "If you grant any other privileges to the custom role, you can't limit the
role for use with an organisational unit" (§15, read 2026-09-17). So a suspend-and-restore pair on
a user is the smallest real Admin-console privilege that can be fenced to one organisational unit.

**It is therefore the privileged tier compressed into a day, and it is not:** super-admin behaviour
(never granted), a ladder walk (C-10), unattended running (C-10), an action on any real account
(absolute 7), or evidence that a robot with wider privilege would behave.

**Eve reads through the Admin SDK Reports API, not an organisation log sink** (C-02), because the
team may hold only project-level access in GCP. A dedicated read-only admin account consents once to
its **own** OAuth client with the single scope
`https://www.googleapis.com/auth/admin.reports.audit.readonly` ("View audit reports for your Google
Workspace domain", §15, read 2026-09-17), and a scheduled Cloud Run job polls the API and writes
rows to BigQuery. **This is not domain-wide delegation and must never become it.** Its absence is
proved in the Admin console on both days, not assumed.

This works inside three days because the admin log lag is "Near real time (couple of minutes)",
retention is "6 months", and "Administrators cannot delete log event data or change the length of
time that the data is available for" (§15, read 2026-09-17). A seeded test therefore closes the
same afternoon, and a volume baseline can be counted backwards.

## 10. The unwind, before anything real is touched

Run on day 3, the same day, in front of both people, and signed. **No privilege, grant, allowlisted
app or credential created by this run may be left standing over a weekend, and no real account may
be brought into scope until every row below reads back as stated.** Two things are deliberately left
running and are named as such in rows 11 and 12; everything else goes.

| # | Unwind | Read back | Day-3 step |
|---|---|---|---|
| 1 | Every standing IAM grant to a human principal removed (C-06) | `gcloud projects get-iam-policy` on each of the four projects prints **no `user:` binding other than the two named owners**, both written into the hand-over. The two people keep `roles/owner` on projects they created; stripping it would lock them out of the evidence | `T3-19a` |
| 2 | The custom admin role unassigned from the robot | `roleAssignments.list` for the role prints nothing, read from person B's own session | `T3-19b` |
| 3 | The custom admin role deleted. **IRREVERSIBLE** | Admin console > Account > Admin roles no longer lists it. Confirm first that row 2 read back empty and that the privilege list is in the hand-over | `T3-19b` |
| 4 | The robot's OAuth grant revoked and the `steward-refresh-token` version disabled | the robot's Security > Connected applications page is empty; the secret version state is `DISABLED` | `T3-19c`, `T3-19d` |
| 5 | **Both OAuth client entries removed from app access control.** Day-1 `T1-13`/`T1-14` and day-2 `T2-16` each mark a client **Trusted** at organisation scope, which by Google's own words "can access all Google services (both restricted and unrestricted)" for any user in the organisation | Admin console > Menu > Security > Access and data control > API controls > Manage App Access: neither client id appears in the configured-apps list, or both read **Blocked**. Read back by person B, not person A. Google: "Changes can take up to 24 hours but typically happen more quickly" (§15) | **owed: add to `T3-19`** |
| 6 | **Both OAuth clients deleted**, in the Google Auth Platform console for `EVE_PROJECT` and `DOER_PROJECT` | neither client id is listed under Clients in either project | **owed: add to `T3-19`** |
| 7 | **The client credentials destroyed.** `eve-client.json` on person A's disk (day-1 `T1-13` only changes its mode), and the `steward-oauth-client` secret | `ls` on the JSON path fails after `shred -u`; the secret's versions read `DESTROYED` or the secret is deleted | **owed: add to `T3-19`** |
| 8 | The five synthetic accounts left **suspended**: the four in the pilot organisational unit and `pilot-user-99@` in the nonprod organisational unit (day-2 `T2-15`) | Admin console > Directory > Users, filtered to each organisational unit, shows suspended accounts and **no other account**. A real account in either is an incident | `T3-19e`, plus `pilot-user-99@`, **owed** |
| 9 | The halt secret left at `on` | the secret's latest version reads `on`. Clearing it is a procedure, not a control: both people hold project owner, so either can clear it alone | `T3-19f` |
| 10 | The staging organisational unit, the `stewardAuditWriter` custom IAM role, the audit dataset's writer ACL entry and the two `run.invoker` user bindings removed | each reads back absent | **owed: add to `T3-19`** |
| 11 | **Left standing on purpose: `eve-reader@`**, a read-only admin account with a live consented refresh token. Its `eve-refresh-token` secret lives in `EVE_PROJECT`, not `DOER_PROJECT`, so day-3 `T3-19d`'s loop does not reach it and silently reports success | name the account's owner and what would revoke it in the hand-over. If Eve is stopped instead, `gcloud secrets versions list eve-refresh-token --project="$EVE_PROJECT"` shows the state, and the decision is written in the run log either way | `T3-19d`, **correction owed** |
| 12 | **Left standing on purpose: Eve polling**, or stopped deliberately and recorded | the scheduler job is `ENABLED`, or is `PAUSED` with a line in the run log saying who paused it and why | `T3-19d` |

Rows marked **owed** are not in day-3 `T3-19` as written and must be added to it before the run;
rows 5, 6 and 7 are the ones that matter most, because without them the tenant carries two
organisation-scoped allowlisted apps and their credentials after the run ends, which is a tenant
left less safe than it started.

On row 11, plainly: the `Eve Reader (3-day)` role created at day-1 `T1-7` carries **Users > Read at
all organisational units**, which reads every real employee's directory record. `activities.list`
does not need it; `T1-7` justifies it only as a convenience. **Drop Users > Read from that role
before the run**, leaving Reports alone, or record in the hand-over that a tenant-wide read-only
admin account with a live credential was deliberately left behind, and who owns it.

What is **not** unwound, on purpose: the audit table, the evidence dataset, the deletion liens and
the run log. They are the record.

Before anything real is ever touched, three things must exist that three days cannot produce: the
data-protection impact assessment and the works-council information (C-12), a recipient for alerts
outside working hours (C-03), and a decision that raises autonomy taken by humans with the evidence
in front of them (C-10).

## 11. The eight risks, and what to do

| Id | Risk | Mitigation built in | Fallback |
|---|---|---|---|
| R-01 | **Role assignment propagation.** Google says a few minutes, "However, it can take up to 24 hours". If it has not propagated, day 2's centrepiece is gone | the pilot organisational unit, the synthetic accounts and the unassigned role are built on day 1, so the assignment lands about 09:45 on day 2 and the first attempt is about 15:00 | the executed pair moves to day 3 morning; the demonstration shows the dry run, the approval chain and Google's own refusal. If it fails again, the executed pair is **struck from the claim, not softened** |
| R-02 | **The consent fails.** The Desktop client is blocked by app access control, the key-only two-step verification makes the browser flow awkward, or the Internal audience is misconfigured. Google says a marking change "can take up to 24 hours but typically happen more quickly" (§15), and a consent that fails on an unpropagated marking presents as an unhelpful blocked-app error, not as a timing message | **both** clients are marked Trusted on day 1, a day before either is needed (§6.1 row 4). As written, only Eve's client gets that margin: the doer's is marked and consented twenty minutes later, and again minutes later at the re-consent. Before each sitting, confirm the client id appears in the configured-apps list and stop if it does not | `gcloud auth application-default login --client-id-file --scopes` from the robot's own browser profile, which uses the same app access control and can fail the same way. Last resort: day 2 ends at the offline selftest, and every result is demonstrated against a fake Directory client |
| R-03 | **`gcloud run --source` fails** on Cloud Build, Artifact Registry or build permissions | the APIs and grants are made on day 1; the poller's deploy is the canary, leaving a whole day to fix it | `gcloud builds submit --tag` then deploy `--image`. Last resort: run the poller by hand and defer the scheduler to day 2 |
| R-04 | **The live results overrun.** 75 minutes for nine results is the tightest block in the plan, and the live block holds work the offline selftest does not: two Cloud Run revisions that must reach ready, two dataset ACL changes, a job execution and a log read | `actions.py --selftest` runs the same set offline, four hours earlier, so only the clock is at risk and not the code | treat day 2's own cut order as the expected case: the model step first, then the audit-unavailable test, then the organisational-unit scope test, which recovers about 45 minutes. **Never dropped:** the forced dry run, the dry run refusing a valid approval, the approval chain refusing a caller who is not an approver, and the approved execution with its write-ahead row. Note that **self-approval is proved offline**, not live: the live service refuses person A at `/approve` before a nonce exists, so the live refusal is `approver_not_authorised` and the two are not the same result |
| R-05 | **The halt flag does not halt.** A secret mounted at `:latest` resolves when the instance starts, so a warm instance would never see a halt written afterwards | the halt is read with `access_secret_version` on **every request** and never mounted; [code.md](code.md) states this in bold | none needed, but the drill is run against an instance that was already warm before the halt was written, so a regression shows |
| R-06 | **Model Armor floor flags are beta and shift** | every flag is re-read on the day and the step fails loudly if gcloud rejects one | set the floor in the console, screenshot the settings page, record the console path instead of the command |
| R-07 | **The edition does not carry every Reports application.** `token` or `access_transparency` may be absent, and empty detections read as a broken poller | the poller records a 403 or an empty stream as a coverage gap in the evidence pack, not as a stop; the `admin` application alone carries all six detections | none needed |
| R-08 | **The two people are pulled into their day jobs.** The most likely failure of all, and nothing to do with Google | **75 minutes** of daily reserve per person, restated from the day tables (§Status). It does not cover a single one of the §6.1 overruns, which is why those are made before the run and not absorbed on the day | the cut order across the three days is: Mo's scorecard, then the retrospective baseline, then the improvement pull request, and under a three-hour overrun **all three go together** and Mo's five views collapse to one query over `steward_audit.actions` grouped by `agent_id`, `operation` and `verdict`. **Never cut:** Eve live before the doer exists; the forced dry run; the two-person approval; the write-ahead audit; the kill drills; the same-day unwind, started at 16:00 rather than 16:15 |

**If day 2 overruns by three hours**, which is the shape R-08 actually takes, the demonstration
still happens and this is the plan, written down rather than improvised at 08:30: day 3 opens with
day 2's carried-over kill drills and re-consent, about 80 minutes of both-person work; the sponsor
slot stays at 14:30; Mo's five views collapse to one query over `steward_audit.actions` grouped by
`agent_id`, `operation` and `verdict`; the retrospective baseline, the scorecard page and the
improvement pull request are cut **together**, each written into the hand-over as owed; the unwind
starts at 16:00. If what was dropped on day 2 was the re-consent itself, there is no working
credential and the demonstration reduces to the dry run, the refusals, the approval chain and the
kills, with the executed pair struck from the claim and said plainly to the sponsor in the first
minute.

Six things Google does not settle, each given a step that fails loudly rather than a guess: the
console path for a Desktop OAuth client with an Internal audience; whether
`gcloud resource-manager liens create` is generally available on the installed gcloud version (the
step tries both and stops if neither works); the column headers of an Admin log events CSV export,
which Google does not document (day 3 prints the header row first); the edition's Reports
application coverage (R-07); the accepted values of the beta Model Armor floor flags, which the
reference does not enumerate, so every value in the day files is `Assumption:` and is re-read from
`gcloud beta model-armor floorsettings update --help` on the day (R-06); and whether
`gcloud auth print-identity-token --audiences=<url>` works for a **user** credential, which the
reference neither permits nor forbids. Every live call to the action service depends on it, so test
it on both accounts during day 1's pre-flight, not at 14:45 on day 2. Fallback if it refuses:
impersonate a dedicated caller service account holding `roles/run.invoker`, note the widening in the
run log, and remove the grant in the same day-3 unwind.

## 12. How it grows

Every artefact here uses the full build's names and schemas, so nothing is torn down to move on. A
three-day build that has to be torn down has failed.

```
3-day/  ->  pov/  ->  setup/
two people, three days      three people, 6 to 20 weeks      the full build, 6 to 7 months to Stage 0
```

| Piece built here | Next step | Then |
|---|---|---|
| Four projects, budgets, liens | [../pov/03](../pov/03-foundation-folders-logging-and-floors.md) adds folders, the organisation sink and the evidence bucket | [../setup/09](../setup/09-folders-and-security-command-center.md) to [14](../setup/14-central-logging-and-billing-export.md) |
| Eve's Reports API poll | [../pov/06](../pov/06-eve-over-the-human-super-admins.md) adds the fingerprint, the lock and the unannounced proof | [../setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) adds the organisation sink beside the poll; [25](../setup/25-eve-human-super-admin-detections.md) takes the six detections to twenty-three |
| The doer, its catalogue and its chain | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) adds three reversible pairs, the ladder and the second approver | [../setup/30](../setup/30-wall-e-workspace-side.md) to [35](../setup/35-wall-e-engine-registration-and-gateways.md) become Wall-E, keeping the code |
| `steward_audit.actions` | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) `PW-2.6` adds the fingerprint | [../setup/23](../setup/23-eve-project-and-evidence-stores.md) |
| Mo's five views and the scorecard | [../pov/08](../pov/08-mo-and-the-value-report.md) adds grading and the four-week window | [../setup/22](../setup/22-mo-foundations.md), [29](../setup/29-mo-eve-quality-pack.md), [40](../setup/40-mo-after-stage-0.md) |
| The volume baseline | [../setup/02](../setup/02-toil-baseline.md) `TB-1.2` adds four prospective ISO weeks and the timed sample | the first defensible minutes-saved claim |
| The evidence pack and hand-over | [../pov/09](../pov/09-the-demonstration-deviations-and-the-hand-over.md) | [../setup/42](../setup/42-gates-drills-and-evidence.md) |

## 13. How to read a step

Every step in the three day files carries six things, in this order, and nothing else:

1. **A number** (`T1-7`, `T2-14`, `T3-3`), used in the run log and the evidence pack.
2. **WHO**: person A, person B, or both.
3. **WHERE**: the Admin console, the Cloud console, or a terminal with the project named.
4. **The exact command or console path.** Every command passes `--project`. No command carries
   `--yes`. No secret is echoed.
5. **What proves it worked**: the output to look for, read by the person named.
6. **How to undo it**, or **IRREVERSIBLE** in bold with what to confirm before running it.

Estimates and unverified assumptions are marked `Assumption:`. Every flag, scope, privilege name,
API and console path is cited with the Google page it was read from and the date.

Records: one `names.env` file for variables (never a secret, only names and version numbers), one
run log in plain text with a line per step, and the evidence pack index on day 3. That is all the
machinery there is (C-15).

## 14. Where to start

Read this page once, both of you, the day before. **Work through §6 and §6.1 the week before**, not
the day before: §6.1 changes the day files, and the run does not fit until it has been done. Then
open [day 1](day-1-platform-and-eve.md) at `T1-1` and work down. Keep [code.md](code.md) open in VS Code
beside it; every file you need to paste is there, with its deploy command and its verify command
underneath.

## 15. Google pages read, with dates

| What it settles | Page | Read |
|---|---|---|
| Admin log lag "Near real time (couple of minutes)", retention "6 months", "Administrators cannot delete log event data or change the length of time that the data is available for" | `knowledge.workspace.google.com/admin/reports/data-retention-and-lag-times` | 2026-09-17 |
| "The user typically becomes an admin within a few minutes. However, it can take up to 24 hours" | `knowledge.workspace.google.com/admin/users/make-a-user-an-admin` | 2026-09-17 |
| Which privilege categories can be limited to an organisational unit (Users yes, Groups not listed); "If you grant any other privileges to the custom role, you can't limit the role for use with an organisational unit" | `knowledge.workspace.google.com/admin/users/create-an-admin-role-for-an-organizational-unit` | 2026-09-17 |
| `https://www.googleapis.com/auth/admin.reports.audit.readonly`, "View audit reports for your Google Workspace domain"; `https://www.googleapis.com/auth/admin.directory.user`, "View and manage the provisioning of users on your domain" | `developers.google.com/identity/protocols/oauth2/scopes` | 2026-09-17 |
| "Access tokens have limited lifetimes"; no figure published, so the 60-minute planning figure is an `Assumption:` and the drill measures the real residue | `developers.google.com/identity/protocols/oauth2` | 2026-09-17 |
| The app access control path, Menu > Security > Access and data control > API controls > Manage App Access; the access states Trusted, Limited, Specific Google data and Blocked; Trusted "Can access all Google services (both restricted and unrestricted)"; "Changes can take up to 24 hours but typically happen more quickly" (§10 rows 5 and 6, R-02) | `knowledge.workspace.google.com/admin/apps/control-which-apps-access-google-workspace-data` | 2026-09-17 |
| `--condition` on an IAM binding takes a required `expression` and `title`, with a `request.time` expiry example, and `--condition=None` adds a binding without a condition. This is what the day files do **not** use (§7.6, C-06) | `docs.cloud.google.com/sdk/gcloud/reference/projects/add-iam-policy-binding` | 2026-09-17 |
| "In order to include commas in your arguments, specify an alternate delimiter using the following syntax: ^DELIM^flag value, with comma" (§6.1, the `APPS` flag) | `docs.cloud.google.com/sdk/gcloud/reference/topic/escaping` | 2026-09-17 |
| An identifier matching a reserved keyword must be backquoted, so `COUNT(*) AS rows` does not parse (§6.1) | `docs.cloud.google.com/bigquery/docs/reference/standard-sql/lexical` | 2026-09-17 |
| `gcloud run jobs executions` offers `cancel`, `delete`, `describe`, `describe-latest`, `list` and the `tasks` group, and no `logs` subcommand (§6.1) | `docs.cloud.google.com/sdk/gcloud/reference/run/jobs/executions` | 2026-09-17 |
| The beta Model Armor floor flags publish no accepted values for the malicious-URI filter and document the responsible-AI filters as a list of strings, so every value in the day files is `Assumption:` and is re-read from `--help` on the day (R-06, C-22) | `docs.cloud.google.com/sdk/gcloud/reference/beta/model-armor/floorsettings/update` | 2026-09-17 |
| Directory `users.list` requires an `admin.directory.user` scope, which a plain gcloud user credential does not carry (§6.1 row 5) | `developers.google.com/workspace/admin/directory/reference/rest/v1/users/list` | 2026-09-17 |
| An Admin log events export is capped at 100,000 rows and opens in Sheets, with no published preparation time (§6.1) | `knowledge.workspace.google.com/admin/reports/admin-log-events` | 2026-09-17 |

Each day file cites the pages its own steps depend on, re-read on the day. Where a page has changed,
**the page is right and the step is corrected before it is run.**
