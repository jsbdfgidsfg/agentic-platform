# Running the three days with one human and a terminal assistant

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-19
- What this is: the variant of the three-day build in which **one human** holds Workspace super
  admin and the four projects, and **an assistant drives person A's terminal** on that human's
  machine. [README.md](README.md) assumes two humans; this page says what changes, what the human
  must decide and provide before day 1, which steps stay in the human's hands, and what such a
  run can and cannot prove. It executes nothing; the day files do.
- Nothing is built on 2026-09-19. Every id on this page is a proposal until the human writes it
  into `names.env` at day-1 `T1-1`.

## 1. The split

| Work in the day files | Who does it in this variant |
|---|---|
| Person A, **terminal**: projects, APIs, budgets, liens, datasets, tables, floor, service accounts, secrets, deploys, the poller run, the schedule, the offline tests, Mo's views, the GCP half of the unwind, the run log and the records | **the assistant**, under the human's `gcloud` session |
| Person A, **Admin console or browser**: the robot account, its keys, the organisational-unit move, the seeded super-admin action of `T1-24` | **the human** |
| Person B, everything: consents, approvals, the kill levers, the alert confirmations, the merges, the signatures, the Workspace half of the unwind | **the human** |

Two consequences, stated before the run rather than after:

1. **Absolute 4 is not met by two humans.** The human creates the robot and also approves its
   role; the human requests nothing, but approves and pulls levers for work the assistant built.
   The run log opens with the line *"one human; person A's terminal work delegated to an
   assistant; absolute 4 not met by two people"*, and the closing report **does not produce the
   claim sentence of [README.md §1](README.md#1-the-claim-in-one-sentence)**. It is a rehearsal
   of the machinery. A second human present for the eight sittings below restores the claim.
2. **The assistant holds no credential.** It runs commands inside a `gcloud` session the human
   opened in their own browser; it never sees a password, a refresh token or a client secret, and
   the day files already forbid printing any. The one credential on disk, person A's
   application-default token of `T2-1a`, is the human's, named in the run log and revoked at
   `T3-19`.

The eight sittings a second human would take, with their length from the day tables: `T1-17`
(60 min), `T1-24` (15), `T2-7` (20), `T2-17` (60), `T2-22` to `T2-24` (75), `T2-25` and `T2-26`
(60), `T3-13` (30), `T3-19` (75). About six and a half hours over three days.

## 2. Six decisions, before anything is created

Project ids are permanent and a deleted id is never reusable. Decide these first; the assistant
writes `names.env` from the answers and nothing else.

| # | Decision | Options | Recommendation |
|---|---|---|---|
| D1 | Rehearsal, or the first real day one | **Rehearsal:** the four ids carry one four-hex suffix chosen by the assistant (`agp-ctl-eve-prod-7c1a`), so the canonical ids survive a tear-down. **Real:** the bare ids of [README.md §5](README.md#5-the-four-projects-and-why-the-doers-project-is-not-called-walle), and the projects stay and hand over to the proof of value | Rehearsal first. A never-executed procedure finds its faults on the first run; spend the canonical ids on the second |
| D2 | Two names inside the ids | `agp-core-<name>` (`Assumption:` `platform`) and the pilot-admin agent id (`Assumption:` `pilot-admin`, the proof of value's `PILOT_ADMIN_AGENT_ID`, PV-07, unsigned) | Take both defaults for a rehearsal; sign PV-03 and PV-07 before a real run |
| D3 | The tenant | **Production tenant** with a pilot organisational unit holding synthetic accounts only (the design). **Test tenant** on a spare domain (Cloud Identity Free or a Workspace trial; `Assumption:` both expose the Admin SDK Directory and Reports APIs, to be checked before choosing) | Production tenant if D4 is answered; otherwise the test tenant, which also removes every employee-monitoring question |
| D4 | Eve's poll scope on the production tenant | **Full:** `userKey=all`, allowed only with the DPO record and HR's answer of [README.md §6](README.md#6-what-must-be-true-before-day-1-starts) row 13. **Limited:** the poll names the human's own administrator account(s), with one written consent line in the run log | Limited, for a rehearsal |
| D5 | The budget per project | The tier defaults of `T1-4`, or one amount for the run | **€5 per project**, alert at 50, 90 and 100 %; the tier defaults return with the proof of value |
| D6 | Four synthetic names, and the sponsor line | Names nobody could ever hold (`pilot-user-1` to `-4` under `SYNTHETIC_PREFIX`); a sponsor named in writing, or *"no sponsor; `T3-14` to `T3-16` skipped"* | Defaults; skip the demonstration in a rehearsal |

## 3. What the human provides, in order

### 3.1 The week before

| # | Action | Done when |
|---|---|---|
| 1 | Install **Python 3.12** and **jq** on person A's machine. Both need the machine's administrator password, which the assistant never enters: `brew install python@3.12 jq` after installing Homebrew, or the python.org installer plus a `jq` binary | `python3.12 --version` and `jq --version` print |
| 2 | Let the assistant install the Google Cloud SDK into the home directory with the `alpha` and `beta` components and `bq` (no password needed), or install it yourself | `gcloud version` and `bq version` print; `gcloud components list --only-local-state --format='value(id)'` shows `alpha` and `beta` |
| 3 | Confirm you hold Workspace **super admin**, and that your own account has two-step verification with a security key | Admin console > Account > Admin roles; Security > Authentication |
| 4 | Have **four hardware security keys** in hand for the two robot accounts (`T1-6`, `T2-3`), or decide in writing that the rehearsal registers passkeys or an authenticator instead, as a recorded deviation (`Assumption:` whether the organisational unit's "only security key" setting accepts a passkey is read on the day) | keys on the desk, or the deviation line drafted |
| 5 | Note the **billing account id** and confirm your role on it is Billing Account Administrator or Billing Account Costs Manager (`T1-4` needs it; Billing Account User is not enough) | Billing > Account management shows the role |
| 6 | **Projects.** Either grant your account `roles/resourcemanager.projectCreator` (or confirm project creation works without an organisation) so the assistant runs `T1-2` as written, or create the four projects yourself with the exact ids from D1 and D2 and link billing to each | `gcloud projects list` shows the four, `ACTIVE`, billing enabled |
| 7 | **Authenticate on person A's machine, yourself.** Run `gcloud auth login` and complete it in your browser with the account that owns the projects; then `T2-1a`'s line, `gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/admin.directory.user.readonly,https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly`. The assistant never runs either | `gcloud auth list` shows the account; `gcloud auth print-identity-token --audiences=https://example-00000.run.app` prints a token ([README.md §6](README.md#6-what-must-be-true-before-day-1-starts) row 12) |
| 8 | A **clean browser profile** signed in to nothing, for the robot sittings | a second Chrome profile exists |
| 9 | **Your mailbox** is the only alert destination; nobody else reads it | a test mail arrives |
| 10 | If D3 is the production tenant: the pilot organisational unit does not exist yet, and **no real account** will be placed in it | absolute 7 |
| 11 | Write the six answers of §2 and these values in one message to the assistant: tenant domain, billing account id, your email (person B, and person A's Workspace hands), the sponsor line, the four synthetic names, the D4 line | the assistant replies with `names.env` for your approval before `T1-1` runs |

### 3.2 Day 1, about four hours of your time

| Time | You | The assistant meanwhile |
|---|---|---|
| 08:30 to 10:00 | `T1-5` to `T1-8`: the two organisational units and their two-step setting, `eve-reader@` in staging with its keys and no recovery channel, its read-only role, the delegation screen read | `T1-1` to `T1-4`: names, projects, APIs, labels, budgets, liens |
| 10:15 to 11:45 | `T1-13`, `T1-14`, `T1-14a`: the two OAuth clients, marked Trusted; `T1-16`: the pilot organisational unit and the four synthetic accounts; the verification link of `T1-16a` in your mailbox | `T1-9` to `T1-12a`: datasets, tables, the watchlists you then initial, the floor, the registry, the identities, the doer's foundation; the secrets of `T1-15` |
| 13:15 to 14:15 | `T1-17`: you sign the clean profile in as `eve-reader@`; the assistant runs the consent tool and reads you the URL; you complete the consent in the robot's profile. `T1-18`: the three read-backs, you reading | `T1-17`: runs the tool, which pipes the token into the secret and prints only the granted scope |
| 14:15 to 15:30 | nothing, unless the assistant asks for a console read | `T1-19` to `T1-23`: the poller, the detections view, the first poll, the schedule last, the two alerting policies (the channel is yours; the policies are terminal work) |
| 15:45 to 16:45 | `T1-24`: you perform one harmless super-admin action in the Admin console, say nothing, and confirm from your own mailbox that the alert arrived | reads the finding rows and writes the record |
| before you stop | sign the day-1 checklist lines in the run log | the "before you stop" checklist, the corrections found today written into the pages |

### 3.3 Day 2, about four and a half hours of your time

| Time | You | The assistant meanwhile |
|---|---|---|
| 08:30 to 10:00 | `T2-1a` (your login, done the week before, checked); `T2-2` to `T2-4`: the robot in staging, two keys, the move, the forced-key proof; `T2-5`, `T2-6`: the two read-only checks; `T2-7`: assign the role scoped to `/pilot`, and write the approval line | the opening gate of `T2-1`; then waits, since every step in this block is yours |
| 10:15 to 11:45 | `T2-8`: the synthetic-population guard (one command the assistant hands you, run in your own shell); `T2-13`: confirm in your mailbox that Eve paged the role assignment; `T2-14`, `T2-15`: read the catalogue line by line and write the approval procedure | `T2-9` to `T2-12`: the read-backs, the container build, every result offline |
| 13:15 to 14:15 | `T2-16`, `T2-17`: the second consent sitting, as on day 1, for the robot; `T2-19`: verify the invoker binding from your own session; `T2-21`: the delegation screen, second half | `T2-18`, `T2-20`: deploy the action service and the plan tool |
| 14:30 to 15:45 | `T2-22` to `T2-24`: you issue every approval **from your own shell** with the command the assistant hands you each time, and read every row | runs every request, times every response |
| 16:00 to 17:00 | `T2-25`: you pull the halt (one command); `T2-26`: you revoke the robot's credential in the Admin console, then re-consent in the same sitting | times the residue, reads the rows, writes the drill records |

### 3.4 Day 3, about four hours of your time

| Time | You | The assistant meanwhile |
|---|---|---|
| 08:30 to 10:00 | `T3-4` to `T3-7`: the retention page, the window, the Admin log export from the console, the reduction to counts, the destruction of the raw export within the hour | `T3-1` to `T3-3`: the read contract, the five views, the reconciliation you confirm aloud |
| 10:15 to 11:45 | `T3-10`, `T3-11`, the draft of `T3-18`: the pack index, what is owed, the hand-over note | `T3-8`, `T3-9`: the scorecard and its page, whose minutes line you initial |
| 13:15 to 14:15 | `T3-13`: review and merge the one improvement | `T3-12`: authors it from the data |
| 14:30 to 15:45 | `T3-14` to `T3-16` only if a sponsor is named (D6) | drives the run if it happens |
| 16:00 to 17:15 | `T3-17`, `T3-18`: seal and sign; `T3-19`: the Workspace half of the unwind (the role unassigned and deleted, the grant revoked, the clients removed from access control and deleted, the synthetic accounts left suspended) | `T3-19`: the GCP half (grants, secrets, the halt left `on`, the read-backs), and the run-log close |

## 4. What the assistant does, before and during

- **Before day 1, first:** carries the six corrections [README.md §6.1](README.md#61-corrections-made-on-2026-09-18)
  still lists as "owed after the review of 2026-09-18" on 2026-09-19, none of which the day files
  or the code carry yet: day-1 `T1-1` drops `SUFFIX` and takes the ids of D1 and D2; `AGENT_ID`
  becomes the pilot-admin id and every doer name in the three days and the code derives from it;
  [code.md](code.md) §5 creates Mo's views in `platform_metrics_views` and its table in
  `platform_metrics` rather than in `mo`; the action service's caller check accepts the token
  path `T2-1a` proves; `T1-19` reads Eve's `userKey` from `names.env` so D4's limited poll can
  name accounts instead of `all`; `T3-19` stops the poller at the hand-over unless the DPO record
  exists. Until these are carried, [README.md §6](README.md#6-what-must-be-true-before-day-1-starts)
  row 11 is red and day 1 cannot start. This is the assistant's work, not the human's.
- **Before day 1, second:** installs the SDK, pastes every file of [code.md](code.md) into
  `$HOME/agp-3day/`, and runs the offline tests of `T2-12` against a fake Google client, so the
  first execution of the code is not on the day.
- **On the days:** every step marked *Person A, Terminal*; the run log line for each; the
  records under `records/`; a correction into the page for every step that fails, the same day.
- **Always:** `--project` on every command, never `--yes` on a destructive one, no secret
  printed, echoed or committed; a step whose guard fails stops the block and is reported, never
  worked around.

## 5. What the assistant will not do

Sign in as any account, or enter a password, a token or a client secret anywhere; create a
Workspace account or an organisational unit; complete a consent; approve a request; pull a kill
lever in person B's place; run anything mutating against an account outside the pilot
organisational unit (the guard of `T2-8` decides, not a judgement); start Eve's poll before D4 is
answered in writing; delete anything outside `T3-19`; or write a tenant fact (a project id, the
domain, an address) into this wiki. The run log and the records live in `$HOME/agp-3day/`,
outside the wiki, for that reason.

## 6. What it costs

`Assumption:`, and read from Google's pricing pages before `T1-2`, since no page of this set has
read them: at this scale BigQuery, Cloud Run (the job and the two services), Cloud Scheduler,
Secret Manager, Cloud Logging, Cloud Monitoring, Artifact Registry and the Model Armor floor
(set, never exercised) sit inside their free tiers. Two things are not free: the Gemini calls of
the plan tool at `T2-24` (a few requests), and the requirement that a billing account be linked
to each project for Cloud Run to deploy at all. The €5 budgets of D5 are the ceiling the run
accepts. Hardware security keys are the one purchase, if the human does not already hold four.

## 7. What the run proves, and does not

It proves that the commands and the code run as written on the day, that the schemas match, that
the detections fire on seeded rows, that the action service refuses what it must (halt, forced
dry run, self-approval, a reused nonce, a protected principal, a target outside the synthetic
population), that the two levers stop work when pulled, and that the unwind leaves nothing
standing that the page did not name. It does not prove the two-person rule, the role-propagation
wait (`R-01`, which only the calendar tests), or anything a works council would ask; and with one
human it produces no claim sentence. The sentences of [README.md §1.1](README.md#11-never-to-be-used-in-any-report-slide-or-message)
are not used, in a rehearsal least of all.

## 8. Where to start

Send the eleven items of §3.1, with the six decisions of §2, in one message. The assistant
replies with `names.env` for approval, the three corrections of §4 made and pushed, and the day-1
timetable with your blocks marked. Day 1 starts when you say so and `gcloud auth list` shows your
account on person A's machine.

## Related

- [README.md](README.md), the three-day build as written for two humans
- [day-1-platform-and-eve.md](day-1-platform-and-eve.md), [day-2-the-doer.md](day-2-the-doer.md), [day-3-mo-demonstration-and-handover.md](day-3-mo-demonstration-and-handover.md), [code.md](code.md)
- [../pov/README.md](../pov/README.md), where the projects go next if D1 was the real run
