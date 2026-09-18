# The three-day build. Two people, six person-days, three agents

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-18. The corrections this page listed as owed on 2026-09-17 were made in
  the day files and the code on 2026-09-18; §6.1 records them.
- Reviewed on 2026-09-18 against the proof-of-value set and the design, later the same day: the
  doer now takes the proof of value's Tier P identity rather than spending `steward` at Tier P
  (§5, §12); the project ids drop the `-d3` suffix the design does not allow (§5); the elapsed
  time of the proof of value is quoted as it states it (Status, §12); Mo's dataset names, the
  reachability of the action service, the identity-token pre-flight, the caller-account fallback,
  the DPO record before Eve polls real administrators and the unreconciled robot credential are
  corrected in §5, §6, §7, §8, §10 and §11; the corrections these need in the day files and the
  code are listed as owed at the end of §6.1.
- What this is: the one entry point to the three-day procedures in this folder,
  [day 1](day-1-platform-and-eve.md), [day 2](day-2-the-doer.md),
  [day 3](day-3-mo-demonstration-and-handover.md) and [the code](code.md). It holds the claim, the
  nine absolutes, the team, the order, the project names, the twelve things three days cannot buy,
  the cut list C-01 to C-27 and the unwind. **No step is executed from this page.**
- Answers the owner's request of 2026-09-17: something two IT experts can implement in three
  business days with a simple procedure, with VS Code and Google Code Assist, as Workspace super
  admins and owners of four GCP projects they create themselves.
- Counterparts, neither replaced: the proof-of-value set [../pov/README.md](../pov/README.md)
  (20 to 26 person-days of procedure and 40 to 64 engineer-days of code; 16 to 20 weeks elapsed
  with a dedicated engineer, 26 to 34 if one person does both) and the full build
  [../setup/README.md](../setup/README.md) (6 to 7 months to Stage 0). This set is the smallest
  thing in this wiki and grows into both (§12).
- Maturity: never executed. Nothing here is built. Where a day file and this page disagree on a
  command, a flag or a console path, **the day file is right and this page is corrected**, unless
  the day file breaks a rule of this page, which is a defect in the day file. §10 carries no row
  the day files do not; §6.1 ends with the corrections the review of 2026-09-18 found owed to the
  day files and the code, each to be made before the run and struck from that list when made.
- Sizing, restated from the three day tables rather than from a nominal day: each day runs 08:30 to
  17:30 with a **90-minute** break, so **450 usable minutes** per person per day. Day 1 and day 2
  each allocate **375 minutes** of blocks, leaving **75 minutes** of reserve; day 3 allocates
  **390 minutes**, leaving **60**, because its unwind carries every row of §10 and starts at
  16:00. Over three days: 1,140 minutes allocated and 210 reserved per person, which is **38
  person-hours allocated and 7 reserved** for two people. The three day files quote the same
  figures. The reserve is the gaps between blocks and the end of each day; it covers a
  fifteen-minute overrun in any block and no more, which is the honest version of R-08.

## 1. The claim, in one sentence

The closing report uses this sentence and no other, with the dates filled in:

> Between `<day 1>` and `<day 3>`, on the production tenant, with two people and no new contract,
> the containment machinery of an agentic platform was built and run: four projects with budgets and
> deletion liens, and a Model Armor floor on the two of them that can call a model; a controller
> (Eve) reading the Workspace admin audit log
> through the Reports API and paging a human, live before any doer existed; a doer (the
> proof of value's Tier P agent, `PILOT_ADMIN_AGENT_ID`)
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
**exact equality**, not as a prefix. Day-2 `T2-24`'s scope test therefore sets its one-minute
override to the exact path holding the one synthetic target, `NONPROD_OU`, reads `/control/status`
back before, during and after, and records that the test is exact-match so nobody converts it: a
prefix match would accept every account in the tenant for the duration, and the parent of
`/pilot` is `/`. And **the synthetic-population guard runs on day 3 as well**, as row 0 of the
demonstration (`T3-15`): the procedure that "refuses to run if a real account is in it" looks on
the day it matters most, and it reports an HTTP status before it counts anything, so a 403 is
never read as an empty unit.

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

- **Every file of code they need is written out in [code.md](code.md)**: six files, complete and
  pasteable (`poller.py`, `eve_detections.sql`, `actions.py`, `plan.py`, `mo.sql`, `consent.py`),
  with the `requirements.txt` of each directory. There is no bootstrap script: day 1 is the
  bootstrap. Code Assist is for adapting them (a project id, a region, a domain), not for
  inventing them. Neither person is expected to design code in three days.
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
| 1 | 2026-09-22 | four projects, datasets, Model Armor floor on the two that call a model, the read-only admin account (keys registered in a staging unit, then moved), its own OAuth client and one consent, the poller, the detections view before the first poll, the schedule last, the alerting; and, brought forward, the pilot organisational unit, four synthetic accounts, the custom role created but assigned to nobody, **the doer's audit dataset with its two tables, its two service accounts and its three secrets with the halt seeded `off`, and the doer's own OAuth client marked Trusted** (`T1-12a`, `T1-14a`) | person B **alone** confirms the alert from a seeded harmless super-admin action, started at 15:45 |
| 2 | 2026-09-23 | the robot account, its one organisational-unit-scoped privilege, its consent, the action service, the one reversible pair, the policy chain, the write-ahead audit rows, the prompt tool | ten live results witnessed, the halt and the revoke pulled by person B and timed, the re-consent to the same client |
| 3 | 2026-09-24 | Mo's views, the retrospective volume baseline, the scorecard, one improvement merged by a human, the demonstration, the evidence pack, the hand-over | the unwind, started at 16:00, is signed the same day |

Why the pilot organisational unit, the synthetic accounts and the unassigned custom role are built
on day 1: role assignment propagation is the one risk with no code fix (§11, R-01). Google says
"The user typically becomes an admin within a few minutes. However, it can take up to 24 hours"
(§15, read 2026-09-17). Building everything except the assignment on day 1 lets the assignment
land at about 09:45 on day 2 and the first execution wait until about 14:45.

Why the doer's audit tables, service accounts, secrets and OAuth client are built on day 1 too
(`T1-12a`, `T1-14a`): day 2 reads all of them back (`T2-9` to `T2-11`, `T2-16`) and creates none
of them, which gives back about half an hour at 10:15 and another at 13:15, in the two blocks that
had the least room. The doer's OAuth client is inert until the consent at day-2 `T2-17`, and
creating it on day 1 buys the Trusted marking an overnight propagation window, which is what R-02
assumes. None of this is a doer: no account can sign in, no role is assigned, no credential
exists, nothing is deployed. The ordering rule holds.

## 5. The four projects, and why the doer's project is not called `walle`

Four GCP projects, created and owned by the two people.

**`names.env`, written once at day-1 `T1-1`, is the only source of every name in these three days.**
This page and [code.md](code.md) quote it and never restate it; [code.md](code.md) §0 sources it.
Project ids are globally unique and never reusable, so a wrong paste on day 1 is not recoverable:
fix the ids at `T1-1` and change nothing afterwards. Values learned later (a client id, a service
URL, a role id, the retrospective window) are appended with the `penv` helper `T1-1` writes,
never typed into the file.

| Variable | Id at `T1-1` (`Assumption:`) | Holds | Model Armor floor |
|---|---|---|---|
| `CORE_PROJECT` | `agp-core-<name>`, where `<name>` is the one the proof of value's PV-03 signs for `CORE_PROJECT` (*tbd*; `Assumption:` `platform`) | Artifact Registry, the evidence dataset, the shared budget | **yes** |
| `EVE_PROJECT` | `agp-ctl-eve-prod` | `eve` dataset, the Reports API poller job, the scheduler, the detections, the alerting policies, the read-only refresh token | no (calls no model) |
| `DOER_PROJECT` | `agp-p-${AGENT_ID}-prod`, where `AGENT_ID` is the value PV-07 signs as `PILOT_ADMIN_AGENT_ID` (*tbd*; `Assumption:` `pilot-admin` until signed) | the `${AGENT_ID with hyphens as underscores}_audit` dataset, the `${AGENT_ID}-actions` and `${AGENT_ID}-plan` services, the robot's refresh token, the halt secret | **yes** |
| `MO_PROJECT` | `agp-imp-mo-prod` | the five metric views in `platform_metrics_views`, the retrospective volume table in `platform_metrics`, the scorecard | no (calls no model) |

No suffix. The design allows one only as four hexadecimal characters on a global-id collision
([../02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §3.6), and the proof of
value's form check ([../pov/02](../pov/02-decisions-people-and-the-retrospective-baseline.md) `PD-3.2`)
refuses any other shape, so an id such as `agp-ctl-eve-prod-d3` would be a project the factory can
never adopt and the proof of value would create a second Eve project beside it. If an id is taken,
`T1-1` applies exactly one four-hex suffix to that id, writes it into the run log, and changes
nothing else. Until 2026-09-18 the day files carried `-${SUFFIX}` on every id; that is the first
correction owed in §6.1.

Two values in `names.env` carry absolute 7 and have exactly one spelling across every file,
because a mismatch means a request is refused for the wrong reason or a target is built that nothing
can act on: **`PILOT_OU="/pilot"`** and the synthetic local-part prefix
**`SYNTHETIC_PREFIX="pilot-user-"`**, which is what day-1 `T1-16` actually creates. `actions.py`
([code.md](code.md) §3) and `plan.py` (§4) read both as **required** environment variables with no
default, so a lost variable is a hard failure at start-up, never a silent fall-back to a plausible
path; the guard (`T2-8`) builds its pattern from the same two values.

Mo's five views live in `MO_PROJECT.platform_metrics_views` and the retrospective volume table in
`MO_PROJECT.platform_metrics`, reading the doer's `actions` and `approvals` tables across projects.
Those two dataset names are fixed by the full build and the proof of value (SD-33, P176,
[../pov/02](../pov/02-decisions-people-and-the-retrospective-baseline.md) `PD-3.2`) and are the only
names under which pov/08 can take the views over without recreating them. [code.md](code.md) §5 is
the one `mo.sql`, and day-3 `T3-2` pastes it unchanged; as written on 2026-09-18 it creates
everything in a dataset called `mo`, which is not the full build's name, so its move to the two
datasets above is owed in §6.1.

**The doer's project is not called `walle`, and its `agent_id` is not `steward` either.** The
reason is the same one the proof-of-value set gives ([../pov/README.md](../pov/README.md) §3):
[../setup/31](../setup/31-wall-e-project-and-data-plane.md) creates `WALLE_PROJECT` in the
privileged super-admin tier folder. Project ids are never reusable and a project is never moved
between tier folders ([../02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §1.5).
Spending the name here, at a tier that grants no Super Admin, would force the full build to rename
Wall-E. The same rule bites `steward`: the proof of value fixes `steward` as its **Tier W** doer,
holding no Workspace admin role at all, in `agp-w-steward-prod`, and a delegated admin role is Tier
P, never Tier W ([../pov/README.md](../pov/README.md) §3, P192). A doer with an
organisational-unit-scoped admin privilege is the proof of value's **optional Tier P agent**
([../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) §7, `PD-5.5`, P198): a
separate agent with its own id, `PILOT_ADMIN_AGENT_ID`, in `fld-agents-p-prod`. So the three-day
doer takes that identity, `AGENT_ID` = `PILOT_ADMIN_AGENT_ID` (*tbd* until PV-07 is signed;
`Assumption:` `pilot-admin`), its project is `agp-p-${AGENT_ID}-prod` and its dataset
`${AGENT_ID}_audit`. `walle`, `WALLE_PROJECT`, `walle_audit`, `EVE_WITNESS_PROJECT`, **`steward`,
`agp-w-steward-prod` and `steward_audit`** are **reserved and never used by a step in this
folder**. Everything the doer produces (its code, schemas, catalogue, consent procedure, kill switch
and audit table) carries over to the Tier P agent of pov/07 §7 unchanged, and to Wall-E after it.
As written on 2026-09-18 the day files and [code.md](code.md) still spell every doer name after
`steward` (`steward_audit`, `steward-actions`, `steward-plan`, `stewardAuditWriter`,
`STEWARD_OAUTH_CLIENT_ID`, `STEWARD_ACTIONS_URL`); §6.1 owes their derivation from `AGENT_ID` at
`T1-1`, and where this page still quotes a `steward` name below it quotes the day files as they
stand.

Eve and Mo keep their own names, because they carry across every set: `eve`, `EVE_PROJECT`,
`eve.ws_activities`, `eve.findings`; `mo`, `MO_PROJECT`, `platform_metrics`,
`platform_metrics_views`, `mo_volume_by_verdict` and its four siblings.

## 6. What must be true before day 1 starts

Check these the week before. Each one, unmet, costs hours on the day.

| # | Must be true | How to check | If it is not |
|---|---|---|---|
| 1 | Both people are genuinely free for three days | a calendar block, accepted, with their manager told | stop. Six person-days means six person-days (R-08) |
| 2 | Both hold Workspace super admin and can reach the Admin console | Admin console loads and shows Account > Admin roles | stop |
| 3 | A billing account exists, both can link projects to it, **and whoever runs day-1 `T1-4` can create a budget on it** | Billing > Account management shows the account with **Billing Account Administrator or Billing Account Costs Manager**, the two roles Google's budgets page names for creating a budget (§15, read 2026-09-18); Billing Account User is not enough | stop. A new billing account is 2 to 5 days (`Assumption:`, [../setup/07](../setup/07-billing-account.md)); a missing budget role costs the first hour of day 1 |
| 4 | The organisation permits project creation by these two | `gcloud projects create` succeeds for a throwaway id, then delete it | ask the Cloud organisation administrator for `roles/resourcemanager.projectCreator`, a day ahead |
| 5 | `gcloud`, `bq` and Python 3.12 are installed on person A's machine | `gcloud version`, `bq version`, `python3.12 --version` | install the week before, not on day 1 |
| 6 | Both admin accounts have two-step verification with a security key, and spare keys exist for the robot | Admin console > Security > Authentication > 2-step verification | order keys now. Allow up to 7 days before a new key works (`Assumption:`, [../setup/11](../setup/11-keys-and-validator-custodian.md)) |
| 7 | Person B has a mailbox they alone read, for alerts | send a test mail | the seeded test cannot prove anything if both read the box |
| 8 | A sponsor is named, in writing | one line in the run log | C-19 has no recipient for a finding about person B |
| 9 | Four synthetic account names are agreed and are nobody's | the names are not in the directory | pick names no leaver could ever hold |
| 10 | Nothing in scope is a real employee account | the pilot organisational unit is empty at the start of day 1 | absolute 7 |
| 11 | The day files and the code are the revision corrected on 2026-09-18 (§6.1) **and carry the corrections §6.1 lists as owed** | each of the four files' Status block says "Corrected on 2026-09-18"; day-1 `T1-12a` and `T1-14a` exist; [code.md](code.md) §7 is not a script; `T1-1` carries no `SUFFIX` and derives the doer's names from `AGENT_ID` | an older revision is being used: fetch the current one. Run from the older revision, three days does not fit |
| 12 | **Mandatory, the week before:** the token both people will mint for the action service is proved on **both** accounts, and the code accepts it. [../setup/33](../setup/33-wall-e-action-services-and-approval-surfaces.md) `WS-3.6` records that `gcloud auth print-identity-token --audiences=` is **refused for a user credential** and accepted only for a service account or an impersonation, so as written every `TOK()` call of day 2 fails | run `gcloud auth print-identity-token --audiences=<any Cloud Run URL>` once on each account and record the refusal or the token; then prove the path §11 names instead | the alternative in §11 is prepared **in code before the run**, never at 14:30 on day 2: either `caller_email` accepts a user token minted without `--audiences` (audience Google's gcloud client id) as well as the service URL, or the caller-account path of §11 is built with its two-person rule intact |
| 13 | **A DPO record on the monitoring of named administrators exists** (purpose, subjects, retention, recipient: the proof of value's SD-11 and PV-08 form, [../pov/02](../pov/02-decisions-people-and-the-retrospective-baseline.md) `PD-2.1` and `PD-5.1`), **and HR's written answer on information or consultation of the works council exists.** Eve's poll reads the admin audit log of every real administrator from day 1 (`userKey=all`, §15), which is a monitoring system at the workplace whether or not any doer ever acts | both documents are in the run log's evidence folder before `T1-19` | the poll is limited to persons A and B, each with written consent, for the three days (the fallback [../pov/README.md](../pov/README.md) §4 describes): `userKey` names them rather than `all`, the seeded test of day 1 is person A's own action, and the claim's "reading the Workspace admin audit log" is read as "of the two participants". Which of the two applies is written into the run log on day 1 |

Read on the day, not from this page: the Google Auth Platform console path for a Desktop OAuth
client with an Internal audience; whether `gcloud resource-manager liens create` is generally
available on the installed gcloud version; the current `gcloud beta model-armor floorsettings
update` flags; whether BigQuery accepts a custom role in a dataset access entry. Each has a step
that fails loudly rather than a guess (§11).

## 6.1 Corrections made on 2026-09-18

On 2026-09-17 this section listed six corrections and twenty-two smaller ones that the day files
and [code.md](code.md) did not yet carry. Every row was checked against the files on 2026-09-18,
none was found already carried, and every one was made that day, in the file and step named.
Nothing here is executed from this page; the rows say where each change now lives.

The six:

1. **One audit vocabulary, taken from the code.** Day-3 `T3-1`, `T3-2`, `T3-8` and `T3-15` are
   written against the eighteen columns `actions.py` writes and its vocabulary (`phase` `intent`
   or `outcome`; `verdict` `attempting`, `dry_run`, `executed`, `denied` or `error`; reasons
   without prefix; `suspend` and `restore`); `T3-2` pastes [code.md](code.md) §5 unchanged, and §5
   builds the five views in `MO_PROJECT.mo` reading `DOER_PROJECT.steward_audit` across projects.
2. **The doer's foundation is built on day 1.** Day-1 `T1-12a` creates `steward_audit`, `actions`
   (eighteen columns) and `approvals`, `steward-actions@` and `steward-plan@`, the three secrets
   with the halt seeded `off`, and `stewardAuditWriter` carrying `bigquery.tables.getData` in the
   dataset's own access array; day-2 `T2-9` to `T2-11` read them back; day 1's hand-off table says
   so; [code.md](code.md) §7 is no longer a script but a table mapping what the script did to the
   day-1 step that does it.
3. **Eve's three tables match the code.** Day-1 `T1-9` creates `ws_activities`, `poll_runs` and
   `watchlists` with the schemas of [code.md](code.md) §1; `T1-9a` seeds `watchlists`; `T1-19`
   deploys, `T1-19a` creates the detections view before the first poll, `T1-20` polls once by hand,
   and `T1-21` creates the schedule last. The seed puts the two people on `admin_allowlist` and
   the robot and `eve-reader@` under `service_identity` **and not on `admin_allowlist`**, so every
   admin event attributed to the robot fires detection R2 to person B, who reconciles it by hand
   against the doer's `actions` table for the same minute: that reconciliation is the only check
   that the robot's refresh token was used by the action service and by nothing else (§7 item 12).
4. **The doer's OAuth client is created and marked Trusted on day 1** at `T1-14a`; day-2 `T2-16`
   only confirms the marking, and `T2-26` re-consents to the same client, or at 08:30 on day 3.
5. **One Directory-scoped credential.** Day-2 `T2-1a` logs person A in with
   `admin.directory.user.readonly` and `admin.directory.rolemanagement.readonly` beside
   `cloud-platform` through `gcloud auth application-default login --scopes`, records it, and
   day-3 `T3-19 l` revokes it; the guard (`T2-8`) reports the HTTP status before it counts, and
   runs again as row 0 of `T3-15`.
6. **One spelling of every name.** [code.md](code.md) §0 sources `names.env`; `actions.py` and
   `plan.py` read `PILOT_OU` and `SYNTHETIC_PREFIX` as required variables with no default; day 2's
   opening gate reads `MAX(ingested_at)`.

The twenty-two smaller ones:

- `eve-reader@` is created in `staging`, registers its keys, and is moved into
  `service-identities` (day-1 `T1-5`, `T1-6`).
- The poller deploy carries no `--set-secrets`, and its environment scan is in `T1-19`'s verify and
  day 1's closing checklist.
- The `APPS` flag is dropped; the code's default is the list, and the alternate-delimiter syntax is
  documented for anyone who narrows it (`T1-19`, [code.md](code.md) §1).
- `COUNT(*) AS n` (`T1-20`).
- The notification channel, its verification link and the two log-based metrics are built at
  `T1-16a` in the morning; `T1-22` creates the finding policy with no dependency on person A;
  only `T1-23` waits for a data point.
- `eve-reader@`'s generated password is never changed, so the sealed envelope always works; both
  envelopes are in the unwind at `T3-19 m` with a destroy-or-retain decision.
- `T2-6` and `T2-8` run in person B's parallel block `D2-B1`; `T2-5` stays before `T2-7` because it
  is the "before" half of its read-back.
- The seeded test starts at 15:45, with the option of a shorter poll schedule for its duration
  (`T1-24`).
- `billingbudgets.googleapis.com` is on `CORE_PROJECT` (`T1-3`), and the budget role is Billing
  Account Administrator or Costs Manager (§6 row 3, day 1's pre-flight).
- `PILOT_ROLE_ID` is written with `penv` at `T2-7`.
- `T2-17` writes the client JSON to one path, consents, shreds it and proves it gone.
- `consent.py` passes `open_browser=False`, compares `granted_scopes`, and reads the version name
  from stdout with `--format=value(name)` ([code.md](code.md) §6).
- `insert_or_deny()` turns any transport or permission failure into `503 audit_unavailable`; the
  approval reads are wrapped the same way; selftest `N4b` covers it, so `--selftest` prints twelve
  lines ([code.md](code.md) §3, `T2-12`).
- `T2-22` names the reasons the code raises: person B's address is `not_synthetic` (N3'), a
  robot-shaped synthetic address is `protected_principal` (N3), and the live N6 is
  `approver_not_authorised` at `/approve`; `T2-9` carries the full table of reasons.
- `steward-plan` has its own directory, `Procfile`, `requirements.txt` and `.python-version`, and
  its deploy sets `VERTEX_LOCATION`, `PILOT_OU` and `SYNTHETIC_PREFIX` (`T2-12`, `T2-20`,
  [code.md](code.md) §4).
- The job's log is read with `gcloud logging read` (`T2-24`, [code.md](code.md) §4).
- Day 3 reads `ORG_DOMAIN`, `PERSON_A_EMAIL`, `PERSON_B_EMAIL`, `DOER_ROBOT`,
  `STEWARD_OAUTH_CLIENT_ID`, `PILOT_ROLE_ID` and `STEWARD_ACTIONS_URL` under those names.
- `T3-19 d` names a project per secret and stops on an empty version list.
- `T3-5` runs a trial search and cuts the window to 90 or 30 days above about 20,000 rows; the
  scorecard's section 6 says which window was used.
- The hand-over is drafted in `D3-B2` and signed at `T3-18`; the unwind starts at 16:00.
- The poller steps its watermark by one millisecond ([code.md](code.md) §1).
- The scorecard's closing statement is one string literal ([code.md](code.md) §5).

Three things beyond the list were done in the same pass because they left the set inconsistent
otherwise: the six rows of §10 that were marked owed are now `T3-19 h` to `m` and `T3-19 e`; the
`Eve Reader (3-day)` role carries Reports only (`T1-7`), as §10 asked; and the three timetables
were recomputed from their blocks (§Status).

**Owed after the review of 2026-09-18.** These the day files and [code.md](code.md) do not yet
carry; each is made before the run and struck from this list when made (§6 row 11):

1. Day-1 `T1-1` drops `SUFFIX` and writes `agp-core-<name>`, `agp-ctl-eve-prod`,
   `agp-p-${AGENT_ID}-prod` and `agp-imp-mo-prod` (§5), with one four-hex suffix applied only to
   an id that is taken, written into the run log; `T1-1`'s read-back filter follows.
2. Day-1 `T1-1` sets `AGENT_ID` to the proof of value's `PILOT_ADMIN_AGENT_ID` (`Assumption:`
   `pilot-admin`) and every doer name in day 1, day 2, day 3 and the code is derived from it: the
   dataset, the two services, the two service accounts, the three secrets, the custom IAM role,
   the OAuth client variables and the service URL variable (§5).
3. [code.md](code.md) §5 and day-3 `T3-2` create the five views in
   `MO_PROJECT.platform_metrics_views` and `toil_retrospective` in `MO_PROJECT.platform_metrics`,
   not in a dataset called `mo`; day-1 creates those two datasets where it creates `mo` (§5).
4. [code.md](code.md) §3 `caller_email` accepts a user token minted without `--audiences`
   (audience Google's gcloud client id) as well as the service URL, or the caller-account path of
   §11 is built with `/act` refusing a service-identity requester unless that identity is a caller
   account only the requester can impersonate; day-2 `T2-1a` proves the chosen path (§6 row 12,
   §11).
5. Day-1 `T1-19` reads `userKey` from `names.env` so that §6 row 13's fallback can name the two
   participants instead of `all`; `T1-9a`'s seed keeps the robot and `eve-reader@` off
   `admin_allowlist` (row 3 above, §7 item 12).
6. Day-3 `T3-19` (§10 rows 11 and 12) stops the poller at the hand-over unless §6 row 13's DPO
   record exists, and `T3-19a` reads back that no `serviceAccountTokenCreator` binding remains on
   any caller account of §11.

**The honest statement is three days**, with the reserve stated in §Status, or three days ending
with the executed pair struck from the claim rather than softened (§1).

## 7. What three days cannot buy

Twelve things. Every file in this folder repeats the ones it touches, and no report may imply
otherwise.

1. **No super admin for any agent, and no evidence about super-admin containment.** The doer holds
   one privilege on one organisational unit. Nothing here says anything about what a super-admin
   robot would do.
2. **No witness organisation and no second tenant.** Eve lives inside the reach of the
   administrators it watches, so Eve is never called independent.
3. **No security information and event management contract, no managed detection, no 24x7
   acknowledgement.** Alerts go to one mailbox, during working hours, on an attended run.
4. **No penetration test and no Security Command Center Premium.** Nothing accepts an
   unauthenticated request: the action service's URL is reachable from the internet and relies on
   IAM alone (`run.invoker` to two named principals), which is a reason a penetration test is owed,
   not a reason it is not needed, and not evidence that there is nothing to find.
5. **No Terraform factory, no register continuous integration, no Binary Authorization.** Four
   projects built by hand and read back by hand.
6. **No privileged-access management entitlements, and no time-boxing either.** Every IAM binding in
   these three days is an ordinary standing grant: each one passes `--condition=None`, so nothing
   expires by itself. They are removed by hand on day 3 (§10) and by nothing else. gcloud does
   support a real expiry (`--condition='expression=request.time < timestamp("..."),title=...'`,
   `gcloud projects add-iam-policy-binding`, read 2026-09-17) and the day files do not use it; if
   that is wanted, it is a pre-run correction to every binding in day-1 `T1-12`, `T1-12a` and
   `T1-15` and day-2 `T2-19` and `T2-20`, not a claim to make about the run as written.
7. **No autonomy beyond a forced dry run and a two-person approved execution.** No unattended
   running at any moment, no ladder, no dwell period.
8. **No four-week toil baseline, so no defensible claim of minutes saved.** The retrospective
   baseline gives volume, not saved time.
9. **No data-protection impact assessment and no works-council information completed.** Two
   consequences: nothing mutating touches a real account, and Eve's poll is limited to the two
   participants unless the DPO record and HR's answer of §6 row 13 exist. Reading every real
   administrator's admin audit log is monitoring of employees at the workplace, and it starts on
   day 1, before any doer exists.
10. **No Gemini Enterprise, no agent gateway, no Agent Registry row.** The prompt tool calls a model
    on Vertex AI directly, and holds no credential.
11. **It is a demonstration of machinery under control. It is not compliance evidence and it is not
    a production grant.** Say this sentence to the sponsor before the demonstration, not after.
12. **No automatic reconciliation of the robot's admin events against the audit table.** The six
    detections (C-21) join nothing to the doer's `actions` table. The write-ahead audit covers the
    action service; it says nothing about the credential itself, and either project owner can read
    the robot's refresh-token secret with no Data Access log to show it (C-26). A use of that token
    outside the service produces an admin event with no audit row, and it is caught only because
    the robot is not on `admin_allowlist` (§6.1 row 3) and person B reads every R2 page and
    reconciles it by hand for the same minute. "Whose every action is written ahead to an audit
    table" (§1) is true of the service and silent about the credential.

## 8. The cut list, C-01 to C-27

Twenty-seven things the full design has and these three days do not. Each is safe **only** because
the population is synthetic, the run is attended and nothing is claimed as compliance evidence. The
unwind column names the file and step that puts the piece back.

| Id | Cut | Why it is safe here | Where it comes back |
|---|---|---|---|
| C-01 | No witness organisation, no second tenant. Eve lives inside the reach of the administrators it watches | Nothing is claimed about Eve's independence; §1.1 bans the sentence | [../setup/08](../setup/08-witness-organisation.md); [../setup/27](../setup/27-witness-grants-and-alarms.md) `WI-*` |
| C-02 | No organisation log sink. Eve reads the Admin SDK Reports API instead | The team may hold only project-level GCP access; the admin log lag is minutes, so the poll sees what a sink would | [../setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) `EW-1.2` to `EW-1.11` adds the sink beside the poll |
| C-03 | No SIEM contract, no managed detection, no 24x7 acknowledgement | Alerts go to one named person's own mailbox and are confirmed by that person alone, in working hours | [../setup/15](../setup/15-pager-siem-and-detections.md) |
| C-04 | No penetration test, no Security Command Center Premium | Nothing accepts an unauthenticated request: the action service is deployed `--no-allow-unauthenticated` and `run.invoker` goes to two named principals only. Its URL is still reachable from the internet and IAM is the only thing in front of it, so this is a reason a penetration test is owed, not a reason it is not needed; the proof of value treats any grant as the trigger to unwind this deviation (PV-D-11) | [../setup/09](../setup/09-folders-and-security-command-center.md) |
| C-05 | No Terraform factory, no register CI, no Binary Authorization, no zero-diff checker | Four projects built by hand in one morning and read back by hand the same morning | [../setup/17](../setup/17-factory-module-equivalents-and-tier-r-gate.md) `FM-2.1` onwards |
| C-06 | No privileged-access-management entitlements, and no time-boxing. Standing IAM grants stand in, removed by hand on the last day | The grants outlive the run by hours, not weeks, and day 3 removes them in front of both people and reads the bindings back. Nothing expires on its own, so the removal is the only control and it is a human one | [../pov/03](../pov/03-foundation-folders-logging-and-floors.md) `PF-5.1`; [../setup/12](../setup/12-privileged-access-catalogue.md) |
| C-07 | No four-week prospective toil baseline. Retrospective volume only, and no minutes | Volume can be counted backwards because Google keeps admin log events six months and administrators cannot delete them. Minutes cannot be counted backwards, so none are claimed | [../setup/02](../setup/02-toil-baseline.md) `TB-1.2` sets the start date and records four prospective ISO weeks |
| C-08 | No blind grading, no double-graded subset, no agreement record | Blind grading needs a third person who is neither builder nor approver, and there are two people | [../pov/08](../pov/08-mo-and-the-value-report.md) `PM-7.1` to `PM-7.3` |
| C-09 | One reviewer on the improvement pull request, not two | The author is person A and the only other human is person B, so the merge still has a reviewer who is not the author; the rule that matters is kept, which is that nothing machine-written merges itself | [../pov/08](../pov/08-mo-and-the-value-report.md) `PM-9.2` |
| C-10 | No autonomy ladder walk. No two weeks at L1 and two at L2 | There is no unattended running at any moment, so there is no dwell for a dwell period to protect | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) `PW-6.2` |
| C-11 | No Gemini Enterprise, no Tier C agents, no agent gateway, no Agent Registry, no engine registration | The only component that can act is the action service, reachable by two named principals | [../pov/05](../pov/05-gemini-enterprise-and-tier-c.md); [../setup/19](../setup/19-gemini-enterprise-import-and-baseline.md), [20](../setup/20-gemini-enterprise-gateway-and-tier-c-gate.md), [35](../setup/35-wall-e-engine-registration-and-gateways.md) |
| C-12 | No data-protection impact assessment, no works-council information | Two consequences, not one. Nothing mutating touches a real employee: four synthetic accounts are the whole population, and the procedure refuses to run if a real account is in the pilot organisational unit. And Eve's poll is limited to the two participants, each with written consent, unless the DPO record and HR's answer of §6 row 13 exist, because reading every real administrator's admin audit log is monitoring at the workplace from day 1 | [../pov/02](../pov/02-decisions-people-and-the-retrospective-baseline.md) `PD-2.1`, `PD-5.1`, `PD-8.0`; [../pov/06](../pov/06-eve-over-the-human-super-admins.md) `PE-0.2`; [../setup/03](../setup/03-decisions-and-people.md) |
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
| 1 | Every standing IAM grant to a human principal removed (C-06), including any `roles/iam.serviceAccountTokenCreator` binding on a caller service account of §11 | `gcloud projects get-iam-policy` on each of the four projects prints **no `user:` binding other than the two named owners**, both written into the hand-over; `gcloud iam service-accounts get-iam-policy` on each caller account prints no binding at all. Every binding was made with `--condition=None` (§7 item 6) and is removed the same way, so nothing is left behind by a condition that did not match. The two people keep `roles/owner` on projects they created; stripping it would lock them out of the evidence | `T3-19a` |
| 2 | The custom admin role unassigned from the robot | `roleAssignments.list` for the role prints nothing, read from person B's own session | `T3-19b` |
| 3 | The custom admin role deleted. **IRREVERSIBLE** | Admin console > Account > Admin roles no longer lists it. Confirm first that row 2 read back empty and that the privilege list is in the hand-over | `T3-19b` |
| 4 | The robot's OAuth grant revoked and the `steward-refresh-token` version disabled | the robot's Security > Connected applications page is empty; the secret version state is `DISABLED` | `T3-19c`, `T3-19d` |
| 5 | **The doer's OAuth client entry removed from app access control, and Eve's if Eve is stopped.** Day-1 `T1-14` and `T1-14a` each mark a client **Trusted** at organisation scope, which by Google's own words "can access all Google services (both restricted and unrestricted)" for any user in the organisation. A blocked app's tokens stop working, so Eve's entry stays exactly as long as Eve polls, and is recorded as deliberately left | Admin console > Menu > Security > Access and data control > API controls > Manage App Access: the doer's client id does not appear in the configured-apps list, or reads **Blocked**; Eve's reads as the hand-over says. Read back by person B, not person A. Google: "Changes can take up to 24 hours but typically happen more quickly" (§15), so a second look the next morning is written into the hand-over | `T3-19h` |
| 6 | **The doer's OAuth client deleted** in the Google Auth Platform console for `DOER_PROJECT`, and Eve's in `EVE_PROJECT` only if Eve was stopped at row 11, since deleting a client invalidates its tokens | the doer's client id is not listed under Clients in `DOER_PROJECT`; "You can restore deleted clients within 30 days" (§15) | `T3-19i` |
| 7 | **The client credentials destroyed.** Every version of the `steward-oauth-client` secret destroyed (irreversible), and `eve-client.json` shredded from person A's disk, which is safe whether or not Eve polls because Eve's refresh-token secret already carries its client id and secret | the secret's versions all read `DESTROYED`; `ls` on the JSON path fails | `T3-19j` |
| 8 | The five synthetic accounts left **suspended**: the four in the pilot organisational unit and `pilot-user-99@` in the nonprod organisational unit (day-2 `T2-15`) | Admin console > Directory > Users, filtered to each organisational unit, shows suspended accounts and **no other account**. A real account in either is an incident | `T3-19e` |
| 9 | The halt secret left at `on` | the secret's latest version reads `on`. Clearing it is a procedure, not a control: both people hold project owner, so either can clear it alone | `T3-19f` |
| 10 | The staging organisational unit, the `stewardAuditWriter` custom IAM role, the audit dataset's writer ACL entry and the two `run.invoker` user bindings removed | each reads back absent | `T3-19k` |
| 11 | **`eve-reader@`, stopped at the hand-over unless §6 row 13's DPO record exists.** A read-only admin account holding one privilege (Reports) and a live consented refresh token, whose `eve-refresh-token` secret lives in `EVE_PROJECT`, not `DOER_PROJECT` (`T3-19d` names a project per secret and stops on an empty version list). The proof of value's Eve holds no Workspace credential at all (PV-D-07), so nothing in pov/06 receives this account: the default is that `T3-19d` disables the token version, `T3-19g` suspends the account, and both are recorded before pov/06 `PE-0.2` starts. It is left standing only if the DPO record of §6 row 13 exists, in which case it is PV-D-07's unwind exercised early, pov/06 records it under that record, and the hand-over names the account's owner and what would revoke it | the secret version reads `DISABLED` and the account reads suspended, with the run-log line; or the DPO record is cited in the hand-over and the account's owner is named | `T3-19d`, `T3-19g` |
| 12 | **Eve polling, stopped with row 11 unless §6 row 13's DPO record exists.** A poll left standing is a standing monitoring system over every real administrator, and it names its DPO record in the hand-over or it does not stand | the scheduler job is `PAUSED` with a line in the run log saying who paused it and why; or it is `ENABLED` and the hand-over cites the DPO record | `T3-19d` |
| 13 | The two application-default credentials revoked, on person A's machine (`T2-1a`) and person B's (`T2-8`): the only credentials a human holds on disk in these three days | `gcloud auth application-default print-access-token` fails on both machines | `T3-19l` |
| 14 | The two sealed envelopes, Eve's password and the doer's keys, each decided: destroyed, or retained by a named role in a named place | one run-log line per envelope, both signatures | `T3-19m` |

Every row above is in day-3 `T3-19` as written (rows a to m, corrected on 2026-09-18); rows 5, 6
and 7 are the ones that matter most, because without them the tenant carries an
organisation-scoped allowlisted app and its credentials after the run ends, which is a tenant left
less safe than it started.

On row 11, plainly: the `Eve Reader (3-day)` role created at day-1 `T1-7` carries **Reports only**,
since 2026-09-18. It no longer carries Users > Read at all organisational units, which would have
read every real employee's directory record for an account that is left standing;
`activities.list` does not need it. What is left behind is a tenant-wide read-only admin account
with one privilege and a live credential, and the hand-over names who owns it.

What is **not** unwound, on purpose: the audit table, the evidence dataset, the deletion liens and
the run log. They are the record.

Before anything real is ever touched, three things must exist that three days cannot produce: the
data-protection impact assessment and the works-council information (C-12), a recipient for alerts
outside working hours (C-03), and a decision that raises autonomy taken by humans with the evidence
in front of them (C-10).

## 11. The eight risks, and what to do

| Id | Risk | Mitigation built in | Fallback |
|---|---|---|---|
| R-01 | **Role assignment propagation.** Google says a few minutes, "However, it can take up to 24 hours". If it has not propagated, day 2's centrepiece is gone | the pilot organisational unit, the synthetic accounts and the unassigned role are built on day 1, so the assignment lands about 09:45 on day 2 and the first attempt is about 14:45 | the executed pair moves to day 3 morning; the demonstration shows the dry run, the approval chain and Google's own refusal. If it fails again, the executed pair is **struck from the claim, not softened** |
| R-02 | **The consent fails.** The Desktop client is blocked by app access control, the key-only two-step verification makes the browser flow awkward, or the Internal audience is misconfigured. Google says a marking change "can take up to 24 hours but typically happen more quickly" (§15), and a consent that fails on an unpropagated marking presents as an unhelpful blocked-app error, not as a timing message | **both** clients are marked Trusted on day 1 (`T1-14`, `T1-14a`), a day before either is consented to, and the re-consent after K4 uses the same doer client (`T2-26`). Before each sitting, the client id is read back in the configured-apps list (`T1-18`, `T2-16`) and the sitting stops if it is not there | `gcloud auth application-default login --client-id-file --scopes` from the robot's own browser profile, which uses the same app access control and can fail the same way. Last resort: day 2 ends at the offline selftest, and every result is demonstrated against a fake Directory client |
| R-03 | **`gcloud run --source` fails** on Cloud Build, Artifact Registry or build permissions | the APIs and grants are made on day 1; the poller's deploy is the canary, leaving a whole day to fix it | `gcloud builds submit --tag` then deploy `--image`. Last resort: run the poller by hand and defer the scheduler to day 2 |
| R-04 | **The live results overrun.** 75 minutes for ten results is the tightest block in the plan, and the live block holds work the offline selftest does not: two Cloud Run revisions that must reach ready, two dataset ACL changes, a job execution and a log read | `actions.py --selftest` runs the same set offline (twelve lines), four hours earlier, so only the clock is at risk and not the code | treat day 2's own cut order as the expected case: the model step first, then the audit-unavailable test, then the organisational-unit scope test, which recovers about 45 minutes. **Never dropped:** the forced dry run, the dry run refusing a valid approval, the approval chain refusing a caller who is not an approver, and the approved execution with its write-ahead row. Note that **self-approval is proved offline**, not live: the live service refuses person A at `/approve` before a nonce exists, so the live refusal is `approver_not_authorised` and the two are not the same result; `T2-22` says which one was seen |
| R-05 | **The halt flag does not halt.** A secret mounted at `:latest` resolves when the instance starts, so a warm instance would never see a halt written afterwards | the halt is read with `access_secret_version` on **every request** and never mounted; [code.md](code.md) states this in bold | none needed, but the drill is run against an instance that was already warm before the halt was written, so a regression shows |
| R-06 | **Model Armor floor flags are beta and shift** | every flag is re-read on the day and the step fails loudly if gcloud rejects one | set the floor in the console, screenshot the settings page, record the console path instead of the command |
| R-07 | **The edition does not carry every Reports application.** `token` or `access_transparency` may be absent, and empty detections read as a broken poller | the poller records a 403 or an empty stream as a coverage gap in the evidence pack, not as a stop; the `admin` application alone carries all six detections | none needed |
| R-08 | **The two people are pulled into their day jobs.** The most likely failure of all, and nothing to do with Google | **75 minutes** of daily reserve per person on days 1 and 2 and **60** on day 3, restated from the day tables (§Status). It covers a fifteen-minute overrun in any block and no more; the corrections of §6.1 were made on 2026-09-18 precisely so that none of it is spent on a known defect | the cut order across the three days is: Mo's scorecard, then the retrospective baseline, then the improvement pull request, and under a three-hour overrun **all three go together** and Mo's five views collapse to one query over `steward_audit.actions` grouped by `agent_id`, `operation` and `verdict`. **Never cut:** Eve live before the doer exists; the forced dry run; the two-person approval; the write-ahead audit; the kill drills; the same-day unwind, started at 16:00 |

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

Seven things Google does not settle, each given a step that fails loudly rather than a guess: the
console path for a Desktop OAuth client with an Internal audience; whether
`gcloud resource-manager liens create` is generally available on the installed gcloud version (the
step tries both and stops if neither works); the column headers of an Admin log events CSV export,
which Google does not document (day 3 prints the header row first); the edition's Reports
application coverage (R-07); the accepted values of the beta Model Armor floor flags, which the
reference does not enumerate, so every value in the day files is `Assumption:` and is re-read from
`gcloud beta model-armor floorsettings update --help` on the day (R-06); whether BigQuery accepts a
project-level custom role in a dataset access entry (`T1-12a` reads it back and falls back to the
dataset-level `WRITER` role, never to a project binding); and whether the tenant's app access
control lets the Google Cloud SDK client carry a Directory read-only scope (`T2-1a` prints the
HTTP status and falls back to the APIs Explorer). One thing this page listed as unsettled until
2026-09-18 is settled by the full build: `gcloud auth print-identity-token --audiences=<url>` is
**refused for a user credential**, gcloud accepting the flag only for a service account or an
impersonation ([../setup/33](../setup/33-wall-e-action-services-and-approval-surfaces.md)
`WS-3.6`), so as written every `TOK()` call of day 2 fails and the alternative is the main path.
Every live call to the action service depends on it, so the pre-flight of §6 row 12 is mandatory
the week before, and the alternative is prepared in code before the run (§6.1 owed row 4). The
preferred alternative keeps both callers human: `caller_email` accepts a user token minted without
`--audiences`, whose audience is Google's gcloud client id, as well as the service URL. The other
is a dedicated caller service account holding `roles/run.invoker`, and it must not collapse
absolute 4: `actions.py` compares approver and requester by e-mail and refuses a service identity
as **approver** only, so whoever can impersonate one shared caller account can request as the
account and approve as themselves, and one person executes. Under that path there are two caller
accounts, one per person, each impersonable by that person only (`serviceAccountTokenCreator`
bound to one person, the policy read back by the other, removed at `T3-19a`), the approver holds
no `serviceAccountTokenCreator` on the requester's account, and `/act` refuses a service-identity
requester unless it is the account only the requester can impersonate. The widening is noted in
the run log and the bindings are in §10 row 1.

## 12. How it grows

Every artefact here uses the full build's names and schemas, so nothing is torn down to move on. A
three-day build that has to be torn down has failed. The one thing paused rather than carried is
Eve's Reports poll (§10 rows 11 and 12), because the proof of value's Eve holds no Workspace
credential; its tables stay and the full build brings the poll back.

```
3-day/  ->  pov/  ->  setup/
two people, three days      three hands-on people and one engineer, 16 to 20 weeks      the full build, 6 to 7 months to Stage 0
```

| Piece built here | Next step | Then |
|---|---|---|
| Four projects, budgets, liens | [../pov/03](../pov/03-foundation-folders-logging-and-floors.md) adds folders, the organisation sink and the evidence bucket | [../setup/09](../setup/09-folders-and-security-command-center.md) to [14](../setup/14-central-logging-and-billing-export.md) |
| Eve's Reports API poll | [../pov/06](../pov/06-eve-over-the-human-super-admins.md) does **not** continue it: it builds Eve on the organisation sink with no Workspace credential (PV-D-07), adding the fingerprint, the lock and the unannounced proof to that Eve. The poller, `eve-reader@`, its token and the `eve.ws_activities`, `eve.poll_runs` and `eve.watchlists` tables have no receiving step in the proof of value, so §10 rows 11 and 12 stop them at the hand-over unless §6 row 13's DPO record exists | [../setup/24](../setup/24-eve-workspace-identity-and-audit-feeds.md) `EW-1.x` brings the poll back beside the organisation sink; [25](../setup/25-eve-human-super-admin-detections.md) takes the six detections to twenty-three |
| The doer, its catalogue and its chain | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) §7, the optional Tier P step (`PW-7.1` to `PW-7.5`, gated by [../pov/02](../pov/02-decisions-people-and-the-retrospective-baseline.md) `PD-5.5`, PV-07), which takes over the same agent id, project and dataset and adds the second role, the ladder and Eve as verifier. pov/07's Tier W doer `steward` is a **different agent**, with no admin role, that this build does not seed | [../setup/30](../setup/30-wall-e-workspace-side.md) to [35](../setup/35-wall-e-engine-registration-and-gateways.md) become Wall-E, keeping the code |
| The doer's `actions` table (`${AGENT_ID}_audit.actions`) | [../pov/07](../pov/07-the-doer-tier-w-and-the-optional-tier-p.md) §7 re-runs `PW-2.6` for the Tier P agent and adds the fingerprint | [../setup/23](../setup/23-eve-project-and-evidence-stores.md) |
| Mo's five views and the scorecard, in `platform_metrics_views` and `platform_metrics` | [../pov/08](../pov/08-mo-and-the-value-report.md) adds grading and the four-week window | [../setup/22](../setup/22-mo-foundations.md), [29](../setup/29-mo-eve-quality-pack.md), [40](../setup/40-mo-after-stage-0.md) |
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

Read this page once, both of you, the day before. **Work through §6 the week before**, not the day
before: four of its rows (the budget role, the identity token on both accounts, the security
keys, the DPO record and HR's answer) take days to put right. §6.1 is a record, not a task list: the day files already carry it.
Then open [day 1](day-1-platform-and-eve.md) at `T1-1` and work down. Keep [code.md](code.md) open
in VS Code beside it; every file you need to paste is there, with its deploy command and its verify
command underneath.

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
| Creating a budget needs Billing Account Administrator or Billing Account Costs Manager (§6 row 3) | `docs.cloud.google.com/billing/docs/how-to/budgets` | 2026-09-18 |
| The Cloud Billing Budget API is `billingbudgets.googleapis.com`, enabled with `gcloud services enable` (§6.1, day-1 `T1-3`) | `docs.cloud.google.com/billing/docs/how-to/budget-api-setup` | 2026-09-18 |
| `gcloud auth application-default login --scopes`: "The names of the scopes to authorize for"; the matching `revoke` "deletes the local credential file" (§6.1 row 5, §10 row 13) | `docs.cloud.google.com/sdk/gcloud/reference/auth/application-default/login` and `.../revoke` | 2026-09-18 |
| Directory `users.list` accepts `admin.directory.user.readonly` (§6.1 row 5) | `developers.google.com/workspace/admin/directory/reference/rest/v1/users/list` | 2026-09-18 |
| `gcloud logging read` is generally available: a filter, `--limit`, `--freshness` (§6.1) | `docs.cloud.google.com/sdk/gcloud/reference/logging/read` | 2026-09-18 |
| `gcloud run jobs execute --update-env-vars` overrides variables for one execution (day-2 `T2-24`) | `docs.cloud.google.com/sdk/gcloud/reference/run/jobs/execute` | 2026-09-18 |
| `gcloud secrets versions destroy` is generally available and "This action is irreversible" (§10 row 7) | `docs.cloud.google.com/sdk/gcloud/reference/secrets/versions/destroy` | 2026-09-18 |
| `gcloud secrets versions add --data-file=-` reads stdin; `--format='value(name)'` prints the version name (§6.1, `consent.py`) | `docs.cloud.google.com/sdk/gcloud/reference/secrets/versions/add` | 2026-09-18 |
| google-auth `Credentials.granted_scopes`: "The scopes that were consented/granted by the user ... could be empty if granted and requested scopes were same" (§6.1, `consent.py`) | `googleapis.dev/python/google-auth/latest/reference/google.oauth2.credentials.html` | 2026-09-18 |
| `run_local_server(open_browser=...)`: "Whether or not to open the authorization URL in the user's browser" (§6.1, `consent.py`) | `google-auth-oauthlib.readthedocs.io/en/latest/reference/google_auth_oauthlib.flow.html` | 2026-09-18 |
| The permissions `bigquery.tables.getData`, `.updateData`, `.get`, `bigquery.datasets.get`; dataset access entries by `bq update --source` show only `READER`, `WRITER`, `OWNER` in Google's examples (§6.1 row 2, `T1-12a`) | `docs.cloud.google.com/bigquery/docs/access-control` and `.../control-access-to-resources-iam` | 2026-09-18 |
| `bq mk --table` with `--time_partitioning_field`, `--time_partitioning_type`, `--clustering_fields`; `bq insert` reads newline-delimited JSON (§6.1 rows 2 and 3) | `docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference` | 2026-09-18 |
| Deleting an OAuth client: Clients page, tick, Delete; "You can restore deleted clients within 30 days of the deletion" (§10 row 6) | `support.google.com/cloud/answer/15549257` | 2026-09-18 |

Each day file cites the pages its own steps depend on, re-read on the day. Where a page has changed,
**the page is right and the step is corrected before it is run.**
