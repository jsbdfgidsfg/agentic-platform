# 1. Prerequisites and conventions

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-16
- Part of: the setup procedure set whose only entry point is [README.md](README.md). This page
  supports every stage. It is the platform prerequisites page the review calls M2
  ([../13-setup-procedure-review.md](../13-setup-procedure-review.md) §3), and it fixes the
  conventions files 02 to 42 follow.
- Replaces, for its scope: [../../wall-e/PREREQUISITES.md](../../wall-e/PREREQUISITES.md) §2,
  §3.1 and §7, [../../wall-e/SETUP.md](../../wall-e/SETUP.md) §1.5 to §1.7, and the "Set these
  once per shell" blocks of [../../eve/07-build-runbook.md](../../eve/07-build-runbook.md) and
  [../../mo/07-build-runbook.md](../../mo/07-build-runbook.md). Those pages are not executed.
- Step prefix: `PR`. 20 steps, none BLOCKED.
- Consumes: nothing from any other file. Decisions SD-01, SD-37 and SD-38 are applied here as
  pending; their signatures are recorded in `03-decisions-and-people.md`.
- Commands checked against Google's documentation on 2026-09-15, and the PAM, organisation-list
  and `gcloud config get` pages re-read on 2026-09-16 (§14). The helper code in §5
  was run under bash 3.2 (the macOS system shell) and zsh on 2026-09-15 against a throwaway
  copy. That run is a check of the helpers, not evidence that any Google command works (S177).
  The helper changes made on 2026-09-16 (`penv_guard`'s exit-status check, `sitting_end`'s
  `CLOUDSDK_CONFIG` guard, `checkpoint`'s placeholder refusal, the removal of `_PENV_MAPPED`) are
  re-checked by PR-2.5 on the day; §13 lists the second-round findings this revision closes.

## What this part builds

- One workstation fit for the build: tools at recorded versions, disk encryption on, a
  working area outside every synced folder, and one clean browser profile per admin account.
- Two local git repositories: the platform repository (`PLATFORM_REPO_DIR`) and the build log
  (`BUILD_LOG_DIR`). `03-decisions-and-people.md` gives both a remote on the git host.
- The variables file `~/.platform-env`, installed from a committed template, with its helpers
  `penv_set`, `need`, `exists_or_pending`, `twin_shell`, `walle_shell`, and four conveniences
  (`penv_guard`, `checkpoint`, `evidence_add`, `sitting_end`).
- A dedicated gcloud configuration with no default project, and the sitting rules that keep no
  admin credential on the laptop between sittings.
- The skeletons of the bootstrap deviation register (`DEVIATION_REGISTER`), the evidence
  register (`EVIDENCE_REGISTER`, also the evidence index) and the drill calendar
  (`DRILL_CALENDAR`), plus the checkpoint log and the re-run index. Later files append to them;
  `42-gates-drills-and-evidence.md` only consolidates.
- The interim evidence location (`EVIDENCE_INTERIM_LOCATION`), owned by the second human.
- The roles table with its incompatible pairs (§2) and the platform prerequisites table with
  the corrected hardware-key count (§3).

## Preconditions

- [ ] A macOS workstation issued by the organisation, that the platform owner administers.
- [ ] The platform owner's daily account (`OWNER_DAILY_ACCOUNT`) can read Admin console →
      Account → Account settings → Profile and Admin console → Billing → Subscriptions.
- [ ] The second human is known by name, even if `03-decisions-and-people.md` has not yet
      recorded the appointment. PR-4.4 and PR-6.1 wait for that person; every other step does not.
- [ ] Nothing has been created in the tenant or in Google Cloud by any procedure of this set.

## People needed

| Person | Steps | Present at the same time as the platform owner? |
|---|---|---|
| Platform owner | every step except PR-4.4 | — |
| Second human (IT security) | PR-4.4 (creates the interim evidence location), PR-6.1 (reviews §2, signs the evidence convention) | No. Both are asynchronous |

Solo reading, no sitting. The one short sign-in (PR-3.3) uses the sitting rules of §6.

## 1. The step format

Every step in files 01 to 42 has these fields, in this order.

| Field | Content | Rule |
|---|---|---|
| Id | File prefix and section-step number, for example `PR-2.3`, `EH-3.4` | Prefixes are listed in README. Ids never change once a checkpoint line cites them |
| WHO | The role that performs the step; then "witness:" and "approver:" when a second person must be present or approve | A missing witness or approver is a `BLOCKED` checkpoint. The platform owner never stands in for another role |
| WHERE | A console path written as Menu → Item → Item; or "shell, `~/.platform-env` sourced" | A console step names the browser profile (§4 PR-1.3) |
| ACTION | Commands in bash fences, one command per line of effect. A `need` line comes first and lists every variable the block reads | When `need` prints `MISSING`, stop. Do not run the rest of the block |
| VERIFY | A command or console read whose output proves the step worked, with the expected output | "It returned no error" is never a verify |
| ROLLBACK | The undo, or **IRREVERSIBLE** in bold (below) | A rollback that cannot be proven says "none documented" |
| EVIDENCE | Record id, location, the E-xx id of [../10-eu-ai-act.md](../10-eu-ai-act.md) §5 and the TISAX control id of [../11-tisax.md](../11-tisax.md) §5 and §13 | "E-xx: none" or "TISAX: none" is written, never left out. `evidence_add` takes the E-id as its third positional argument, so a step with no E-xx field leaves the operator nothing to type and no rule saying whether to pass `-` or to stop |

**The EVIDENCE convention is checked mechanically, not by eye.** Run this over the whole set; it
prints every EVIDENCE field that carries neither an `E-xx` id nor a TISAX control id within its
own three lines. A hit is a defect in the file it names, closed by that file's owner:

```bash
need WIKI_DIR
cat > "$BUILD_LOG_DIR/evidence-ids.awk" <<'AWK'
/^-? *\*\*EVIDENCE:?\*\*/ { b=$0; n=NR; inev=1; next }
inev && (/^$/ || /^#/ || /^- \*\*/ || /^\*\*/) {
  if (b !~ /E-[0-9]+/ && b !~ /E-xx: *none/) printf "%s:%d: no E-xx\n", FILENAME, n
  else if (b !~ /TISAX/) printf "%s:%d: no TISAX\n", FILENAME, n
  inev=0; next }
inev { b = b " " $0 }
END { if (inev && b !~ /E-[0-9]+/ && b !~ /E-xx: *none/) printf "%s:%d: no E-xx\n", FILENAME, n }
AWK
awk -f "$BUILD_LOG_DIR/evidence-ids.awk" "$WIKI_DIR"/platform/agentic-platform/setup/[0-4][0-9]-*.md
```

Expected for this page: no output. The check is deliberately lenient — any `E-<digits>` anywhere
in the field satisfies it, as does the literal `E-xx: none` — so every hit is a real omission.
`42-gates-drills-and-evidence.md` runs it at every quarterly review, and it is the CI rule to add
when the platform repository gets content tests.

Run on 2026-09-16 it reproduces the review's counts on the files that feed the EU AI Act
technical documentation index: 07 fourteen of sixteen fields with no E-xx, 10 twenty-seven of
thirty-nine, 13 thirty-nine of fifty-three, 17 thirty-three of seventy-four, with 02, 05, 19, 20,
34 and 35 worse still. Each of those files sweeps its own EVIDENCE fields against §7.2's mapping
table; this page supplies the rule and the check, not the sweep (§13, Deferred). This page's
twenty steps all carry both ids.

**Checkpoint lines.** Every step writes `START` before its ACTION and `DONE` when its VERIFY
passes, with `checkpoint` (§5) or by hand in the same tab-separated field order:

```text
<UTC timestamp> <step id> <START|DONE|BLOCKED|PENDING|ROLLED-BACK|N/A> <operator> <witness or -> <evidence path or -> <note>
```

The resume rule is README's: restart at the first step without `DONE`; a step with `START` and
no `DONE` has its VERIFY run first; an **IRREVERSIBLE** step with `START` and no `DONE` is never
re-run blind.

**IRREVERSIBLE.** A step whose effect cannot be undone (a project id, a key ring, a dataset
name, a retention lock, a consent, a security-group label) is written:

> **IRREVERSIBLE**: what cannot be undone. Confirm before running: the facts to read back
> first. Gate: the signed decision record `decisions/<date>-<name>.md` in the platform
> repository (from `03-decisions-and-people.md`), or the checked prerequisite (step id with a
> `DONE` line).

The ACTION of such a step starts with a check that the gate record exists, for example
`test -s "$PLATFORM_REPO_DIR/decisions/<date>-<name>.md" || echo "STOP: gate record missing"`.

**BLOCKED.** A step whose code, person or record does not exist yet is written:

> **BLOCKED**: Needs: the code (or person, or record). Commit it in: repository and path.
> Unblocked by: the commit id with green CI, recorded as the named variable (for example
> `EVE_CODE_COMMIT`). Gate waiting: the gate or file. Until then: `checkpoint <id> BLOCKED - - "<what>"`,
> and the step's row in README's BLOCKED index.

The rest of the step is still written in full, so that the day the code lands nothing needs
re-deciding. Nothing in a BLOCKED step is executed, not even partly.

## 2. Roles

### 2.1 The roles table

The platform RACI is [../01-hld.md](../01-hld.md) §0.3; the incompatible pairs are
[../11-tisax.md](../11-tisax.md) §7.1; decisions SD-04, SD-10, SD-12 and SD-16 add pairs. Names
and dates are recorded in `03-decisions-and-people.md`, never here.

| Role | Held by | What the role does in this set | Must never also be |
|---|---|---|---|
| Platform owner (PO) | the platform owner; `sa-1-admin@` from 06 | Builds; performs or requests most steps; Mo owner until 03 names another; monitored by Eve-H | IT security lead; security reviewer; AI compliance owner; Eve owner; second human; incident commander (from 15); witness administrator; billing administrator; approver of his own grants; approver of any elevation on `EVE_PROJECT` (SD-12); administrator or responder on `PAGER_SUBJECT_SERVICE_NAME` (SD-12); recipient of reports about himself; custodian of `eve@`'s keys |
| Second human (SA2, Eve owner) | An IT security person; `sa-2-admin@` from 06 | Owner of `eve-owners@`; required reviewer on the roster, control groups, `eve/`, `oncall.yaml` and the ladder; approver of Eve's PAM elevations and of `ENT_ORG_SINK`; key custodian (§3.2); manager of the interim evidence location; performs `eve@`'s consent; leads the independent proof of Eve (28); approves the grant (38); holds a non-administrator witness account as owner of record (08) | In the Wall-E administration line (member of any `walle-*` group); second operator; witness administrator (SD-04); platform owner; Mo's blind grader for Wall-E |
| Security reviewer (SR) | IT security; *tbd* until 03 | Reviews CI rules, deny, floor and ladder changes; signs the super-admin deviation; recipient of reports about the second human (SD-10); `eve@` key custodian; second approver on P-SA production singletons | Platform owner; Mo's CI operator; the second human, unless the ISMS records a dated exception (§2.3) |
| Second operator (OP2) | A Workspace admin in the operations line; *tbd* until 03 | Member of `walle-operators@`; reviews the toil and Mo input commits; confirms alert receipt | Requester of what it approves; the Wall-E owner; the second human; witness administrator (SD-04) |
| Validator custodian (VC) | The security reviewer's line; may be the security reviewer | Owns the validator identity in `VALIDATOR_PROJECT` (11, 40) | Mo's CI operator; Mo owner |
| Blind grader (BG) | *tbd* until 03 | Grades playbooks blind (40) | Owner of the playbooks graded; Eve owner for Wall-E's playbooks |
| Incident commander (IC) | IT security; not a tenant super admin | Signs paging escalation and routing (15, 26); until the security reviewer is appointed, recipient of reports about the second human and second `eve@` key custodian (SD-10, SD-12) | Platform owner (from 15); tenant super admin |
| Witness administrator 1 and 2 (WA1, WA2) | Two IT security people | Super admins of the witness organisation; perform 08 and 27 from their own workstations | Tenant super admin; platform owner; second human; second operator (SD-04) |
| Sandbox super admin 1 and 2 (SSA1, SSA2) | Two named people on `SANDBOX_DOMAIN` | Administer the sandbox tenant (21); requester and approver on the twin (37) | The requester of what they approve (the two are different people). `Assumption:` no further pair; 03 records any the ISMS adds |
| Billing administrator | Finance | Grants billing roles on `BILLING_ACCOUNT_ID` (07); enables the billing export (14) | Platform owner; any tenant super admin (so an Organization Administrator self-grant stays visible, SD-16) |
| DPO contact | Data protection | D7 letter; the SD-11 record on monitoring named administrators; retention ceiling P13 | — |
| Works council / HR | Employee representation | Information on Eve-H and Wall-E before Stage 1 (E-12) | — |
| Legal | Legal department | P19, Art. 25 position, supplier file (E-01, E-11) | — |
| AI compliance owner (ACO) | Legal's designate (P131) | Classifications, Art. 49 registration, Art. 73 clock | Platform owner; any agent owner |
| ISMS | The site's ISMS function | Role register with names; dated exceptions; training records (E-13) | — |
| Key custodians | Per key, §3.2 | Hold one sealed key each; open an envelope only with a witness from the other administration line | Holder of both keys of any one account |
| Envelope witness | Anyone from the other administration line than the custodian | Witnesses every envelope opening and signs the custody record | The custodian of that envelope |
| Toil recorders | The admins who perform the three measured tasks (02) | Record elapsed handling time for four weeks | The second operator's review of their own figures |
| Deployer second reviewer | Named in 33 | Approves credential-holder deploys | Owner of the agent deployed |
| Mo owner (MO) | Platform owner until 03 names another | Mo's CI, fixtures and queries (22, 29, 40) | Eve's second reviewer |

### 2.2 The pairs as a check

The pairs above resolve to principals once groups exist. Until the CI separation check of
[../11-tisax.md](../11-tisax.md) §7.3 runs, `03-decisions-and-people.md` records one line per
pair with the two names and "distinct: yes". A "no" on any pair stops the file that needs that
pair and is a finding to the ISMS.

### 2.3 How many humans

The super-admin grant needs **five distinct humans** when every pair holds. One legal
assignment:

| Human | Roles |
|---|---|
| 1 | Platform owner; Mo owner; agent owner; deployer (primary) |
| 2 | Second human; Eve owner |
| 3 | Second operator; blind grader |
| 4 | Security reviewer; validator custodian; deployer second reviewer; witness administrator 1 |
| 5 | Incident commander; witness administrator 2 |

The DPO, legal, works council, ISMS and the billing administrator are counted by their own
functions, not in the five.

**Four humans** are possible only under a dated ISMS exception that names the pair it relaxes,
its end date and its compensating control. `Assumption:` the exception most often proposed,
security reviewer = Eve owner ([../11-tisax.md](../11-tisax.md) §7.2), does not by itself
reach four, because the two witness administrators must still be outside the platform owner,
the second human and the second operator. The relaxed pair is therefore a witness pair, and
`03-decisions-and-people.md` records which. README's B-21 waits on it.

## 3. Platform prerequisites

### 3.1 The table

Every row is closed by its VERIFY, not by someone's word. "Needed by" is the earliest file that
fails without the row. PR-5.2 snapshots the open or closed state of every row into the build
log; the files named in "Needed by" close them.

| Id | Requirement | Why | How to verify | Needed by | Holder | Lead time |
|---|---|---|---|---|---|---|
| P-01 | Workstation built to §4 | Every command runs here | PR-1.1 to PR-1.3 VERIFY outputs in the build log | 02 | Platform owner | 1 day |
| P-02 | `OWNER_DAILY_ACCOUNT` holds Super Admin today | Only admin able to create the roster in 06 | PR-2.6: Admin console → Account → Admin roles → Super Admin → **View admins** lists it; screenshot `<date>-PR-2.6-super-admin-roster-v1`. 03 DC-4.4 repeats the read for the full inventory | 06 | Platform owner | none |
| P-03 | The Cloud organisation exists and is bound to the Workspace customer | Trust domain, organisation sinks, "Share data with Google Cloud services" | PR-3.3: `owner.directoryCustomerId` of `ORG_ID` equals `DIRECTORY_CUSTOMER_ID` | 05, 06 | Platform owner | none |
| P-04 | Workspace edition supports multi-party approval, activity rules and Context-Aware Access (Enterprise Standard or Plus, or another edition Google lists) | Interim activity rule (06), gate line G4 (38) | Admin console → Billing → Subscriptions; `WORKSPACE_EDITION` recorded | 06, 38 | Platform owner | procurement if not |
| P-05 | Second human named, IT security | Eve-H recipient and approver (SD-10, SD-12); every two-person step from 06 | Signed people record in `03-decisions-and-people.md`; `SECOND_HUMAN_EMAIL` set | 03 (gates 06) | IT security | weeks |
| P-06 | Security reviewer named, or the incident commander standing in | Reports about the second human; `eve@` second key; P-SA production approvals | `SECURITY_REVIEWER_EMAIL` or `INCIDENT_COMMANDER_EMAIL` not `*tbd*` | 15, 24, 26, 31, 38 | IT security | weeks to months |
| P-07 | Second operator, blind grader, validator custodian named | Tier W rows (G19); reviews in 02 and 22 | People record in 03 | 02, 11, 22, 40 | Platform owner with ISMS | weeks |
| P-08 | Two witness administrators named, outside the platform owner, the second human and the second operator | SD-04 | People record in 03; §2.2 pair lines | 08 | IT security | weeks |
| P-09 | Two sandbox super admins named | SD-29; twin approvals | People record in 03 | 21 | Platform owner | weeks |
| P-10 | Billing administrator named (finance) | SD-16 | People record in 03 | 07 | Finance | days |
| P-11 | DPO, works council or HR, legal, ISMS and AI compliance owner contacts; D7 letter sent, covering Eve's monitoring of named administrators | SD-11; longest lead time | Date the letter was sent, in 03 | 03 week one; blocks 25 | Platform owner, DPO | months |
| P-12 | Setup decisions SD-01 to SD-48 and the design decisions of 03 signed | Every gate | Each signed record parses (03) | 03 onwards | Platform owner and signatories | days to months |
| P-13 | Git host decided (P22), platform and build-log remotes with branch protection | SD-14; two-person commits before 16 | `PLATFORM_REPO_REMOTE` set; protection export in 03 | 03 (gates 06) | Platform owner | weeks |
| P-14 | Interim evidence location | SD-38; custody scans from 06 | PR-4.4 VERIFY | 06 | Second human | 1 day |
| P-15 | Corporate password vault usable for human break-glass and robot account passwords | No password in any file, ticket or chat | A test entry can be created and deleted by its custodian | 06 | Platform owner, IT security | *tbd* |
| P-16 | SIEM (Google SecOps in the EU or the organisation's SIEM) and MDR retainer | P10; G2 | Contract reference in 04 | 15 part B; 38 | IT security | months |
| P-17 | Penetration test contracted | G8 | Contract and window in 04 | 37 | IT security | months |
| P-18 | SCC Premium payer decided and activation possible | P11, SD-15 | Payer recorded in 04; activation in 09 | 09 | IT security, finance | weeks (a subscription is a 12-month contract) |
| P-19 | Organisation paging service and the subject-report escalation administered by IT security | SD-08, SD-12 | `PAGER_SERVICE_NAME`, `PAGER_SUBJECT_SERVICE_NAME` set; the platform owner holds no role on the second (04) | 15 part A; 26 | IT security | weeks |
| P-20 | Sandbox Workspace tenant: edition equal to production and at least Enterprise Standard, own domain with TXT and MX, seats | SD-29 | `SANDBOX_DOMAIN` set; edition read in the sandbox Admin console (04, 21) | 21 | Platform owner, procurement | weeks |
| P-21 | Witness Cloud Identity tenant on a separately registered domain, billing account parented by the witness organisation, Customer Care subscription | SD-28 | `WITNESS_DOMAIN` set; purchase record (04) | 08 | IT security | weeks |
| P-22 | Dedicated platform billing account in EUR and a project-quota request for about 20 projects | SD-16 | 07 VERIFY | 07, 10 | Finance | days |
| P-23 | Chrome Enterprise Premium licences | P63; Context-Aware Access for operators | Admin console → Billing → Subscriptions lists the SKU | *tbd* by 03 | IT security | weeks |
| P-24 | Gemini Enterprise licences for operators; Gmail-bearing seats for `walle@`, `eve@` and any licensed twin robot | 24, 30, 37 | Seat count in 04 | 24 | Platform owner | weeks |
| P-25 | Hardware keys in the count of §3.2, a safe, tamper-evident envelopes | Key-only 2SV; custody | Keys in hand, serials in custody records only (never in the variables file) | 06, 08, 21, 24, 30 | Platform owner, IT security | weeks |
| P-26 | Organisation roles for the bootstrap exception, all five to `sa-1-admin@`, dated with an expiry (SD-01): `roles/resourcemanager.organizationAdmin`, `roles/resourcemanager.folderCreator`, `roles/resourcemanager.projectCreator`, `roles/privilegedaccessmanager.admin` **and `roles/iam.securityAdmin`**. Google requires **both** the Privileged Access Manager Admin role and the Security Admin role to create, update or delete an entitlement at organisation level; Organization Administrator does not contain the Security Admin permission set. The analogues for entitlements created lower down are `roles/resourcemanager.folderAdmin` (folder) and `roles/resourcemanager.projectIamAdmin` (project); 12 says which level each entitlement is created at | First privileged acts before PAM exists (S002); every entitlement create of 12 | 06 reads the bindings back, then probes the permissions — see §3.3 | 06, 09, 12 | Platform owner under the exception | none |
| P-27 | Every located service used is offered in `europe-west1` (Agent Runtime, Agent Gateway, regional Agent Registry, Model Armor templates, Firestore, regional Secret Manager, Cloud KMS HSM, Cloud Run, Scheduler, Tasks), BigQuery in `EU`, SecOps in its Europe locations | R9; X-RQB-02 | Re-read Google's agent-locations page on the day of 18 and 35; once a project exists, `gcloud network-services agent-gateways list --location=europe-west1 --project=<project>` returns without a location error. Recorded on 2026-09-15 by the review: Agent Gateway is not supported only in asia-east2, asia-northeast3 and asia-southeast2 | 18, 20, 35 | Platform owner | none |
| P-28 | Agent Runtime quotas recorded in the quota register | X-RQB-02; HLD §3.4 | `gcloud beta quotas info list --service=aiplatform.googleapis.com --project=<agent project>`. Recorded on 2026-09-15 by the review: 90 query or streamQuery per minute, 10 create, update or delete per minute, 100 engines per project and region, 100 session writes per minute, 950 revisions per agent and 6,000 per project and region (the last two not adjustable) | 35 | Platform owner | days per increase |
| P-29 | Model Armor quotas sized from the right consumers | X-RQB-02 | `gcloud beta quotas info list --service=modelarmor.googleapis.com --project=<project>`. Defaults read 2026-09-15: 1,200 API queries per minute per project (adjustable), 600 ExternalProcessor requests per minute per project (adjustable from 0 to 1,200), filter token limits 65,536 and 130,000 (fixed). Needed: sanitize QPM ≈ 2 × model calls per minute + direct calls; ExternalProcessor QPM = gateway requests per minute. The 120 Admin SDK reads per minute are not a Model Armor consumer | 18, 19, 34 | Platform owner | days per increase |
| P-30 | A GA model on the `eu` endpoint pinned (decision 6, SD-09); no Gemini 2.5 model; plan for 2026-10-16 | X-RQB-01 | Decision record in 03; `MODEL_ID` set; 35 verifies one call | 35 | Platform owner | days |

### 3.2 Hardware keys, corrected count

The count in [../../wall-e/PREREQUISITES.md](../../wall-e/PREREQUISITES.md) §3.1 is Wall-E's
share only. The platform count, from [../04-identity-and-privileged-access.md](../04-identity-and-privileged-access.md)
§7.1 and §8.3 with SD-04, SD-12 and SD-29:

| Account | Keys | Custodians | Where |
|---|---|---|---|
| `sa-1-admin@` | 2 | carried by the platform owner; spare held by the second human | spare in the safe |
| `sa-2-admin@` | 2 | carried by the second human; spare held by the platform owner | spare in the safe |
| `brk-gcp-1@` | 1 | platform owner | safe |
| `brk-gcp-2@` | 1 | second human | safe |
| `walle@` | 2 | key A platform owner, key B second human | safe |
| `eve@` | 2 | the second human and the security reviewer (the incident commander until appointed); never the platform owner (SD-12) | safe |
| **Tenant total** | **10** | 8 in the safe, 2 carried | |
| `WITNESS_SA_1`, `WITNESS_SA_2` | 2 each, 4 | each witness administrator, spare with the other | IT security's own safe (`Assumption:` not the tenant safe) |
| `SANDBOX_SA_1_EMAIL`, `SANDBOX_SA_2_EMAIL` | 2 each, 4 | each sandbox super admin, spare with the other | safe |
| Twin robots `EVE_TWIN_ROBOT`, `WALLE_TWIN_ROBOT` | 0, or 2 each (4) only if SD-29 decides hardware-key 2SV for them | as the production robots | safe |
| Unenrolled spares | 4 (one replacement per custodian group, [04-purchases-and-lead-times.md](04-purchases-and-lead-times.md) §4) | incident commander, in the safe | safe |
| **Subtotal, firm** | **18**, or **22** with twin-robot keys | | |
| **Order** | **22**, or **26** with twin-robot keys | | |

[04-purchases-and-lead-times.md](04-purchases-and-lead-times.md) §4 is the single source for the
count; this table repeats it so that the order figure is the same in both places. Order 22 (26
with twin-robot keys). 06's first sitting needs six of them and the lead time is days to weeks,
so the order is raised on day one (04 row 9, step PU-4.1).

Serial numbers live in custody records, never in `~/.platform-env` or the wiki.

### 3.3 How P-26 is checked (the bootstrap organisation roles)

06 runs both checks below as the platform owner, before the first privileged act. The first is
deterministic (it reads the bindings that were granted); the second proves the permissions
resolve. `testIamPermissions` alone is not enough, because a role list missing
`roles/iam.securityAdmin` still echoes the four permissions the earlier draft of this row asked
for, and every entitlement create in
[12-privileged-access-catalogue.md](12-privileged-access-catalogue.md) then fails with
`PERMISSION_DENIED` after the dated exception has been signed and consumed.

```bash
need ORG_ID DOMAIN
gcloud organizations get-iam-policy "$ORG_ID" --format=json \
  | jq -r --arg m "user:sa-1-admin@$DOMAIN" '.bindings[] | select(.members[]? == $m) | .role' | sort
```

Expected, exactly these five lines: `roles/iam.securityAdmin`,
`roles/privilegedaccessmanager.admin`, `roles/resourcemanager.folderCreator`,
`roles/resourcemanager.organizationAdmin`, `roles/resourcemanager.projectCreator`. A missing
`roles/iam.securityAdmin` stops 06 and 12.

```bash
gcloud organizations get-iam-policy "$ORG_ID" >/dev/null   # proves the read half of Security Admin
gcloud iam roles describe roles/iam.securityAdmin --format='value(includedPermissions)' \
  | tr ';' '\n' | grep -E '^(iam\.roles\.create|resourcemanager\.projects\.setIamPolicy)$'
```

The second command reads Google's own definition of the role rather than asserting its contents
here, so the probe permission 06 passes to `testIamPermissions` is taken from the role as Google
publishes it on the day. `Assumption:` at least one of `iam.roles.create` and
`resourcemanager.projects.setIamPolicy` is in `roles/iam.securityAdmin` and in neither
`roles/resourcemanager.organizationAdmin` nor the two creator roles; if the output is empty,
06 uses the binding read above as the only gate and records a deviation row.

## 4. The workstation

### PR-1.1 Tools and versions

**WHO:** Platform owner. No witness.

**WHERE:** macOS terminal. `~/.platform-env` does not exist yet.

**ACTION:** Install the Google Cloud CLI from Google's installation page
(https://docs.cloud.google.com/sdk/docs/install), which ships `bq`; install Python 3.12 from
python.org or the organisation's package manager. `jq`, `openssl`, `git` and `curl` ship with
macOS. Then record the versions:

```bash
gcloud components update
gcloud components install beta
mkdir -p "$HOME/platform/tmp-records"
{ date -u +%Y-%m-%dT%H:%M:%SZ; gcloud version; bq version; python3.12 --version; jq --version; openssl version; git --version; curl --version | head -n 1; } > "$HOME/platform/tmp-records/tools.txt" 2>&1
gcloud version --format=json | jq -r '."Google Cloud SDK"'
```

`gcloud components update` and `install` apply only when the CLI was installed from Google's
archive; with a package manager, update through it. On 2026-09-15 the newest release was
584.0.0 (2026-09-09). The floor is 563.0.0 (Mo-10's command group).

**VERIFY:**

```bash
python3.12 -c 'import sys; v=tuple(int(x) for x in sys.argv[1].split(".")); sys.exit(0 if v >= (563,0,0) else 1)' "$(gcloud version --format=json | jq -r '."Google Cloud SDK"')" && echo "gcloud version OK"
gcloud components list --only-local-state --format='value(id)' | grep -qx beta && echo "beta OK"
command -v shred >/dev/null 2>&1 || echo "no shred: expected on macOS; no step uses it"
```

Expected: `gcloud version OK`, `beta OK`, and the `no shred` line.

**ROLLBACK:** Uninstall the tools. Nothing outside the workstation is touched.

**EVIDENCE:** `tools.txt`, moved into the build log at PR-2.4 as
`<date>-PR-1.1-workstation-tools-v1`. E-xx: E-05 (development environment of the technical
documentation). TISAX: 5.3.1.

### PR-1.2 Disk encryption and a working area outside synced folders

**WHO:** Platform owner.

**WHERE:** macOS terminal.

**ACTION:** Choose the working area. `Assumption:` `$HOME/platform`, which is outside
`~/Desktop`, `~/Documents` (synced when iCloud Desktop and Documents is on), `~/Library/CloudStorage`
(Google Drive and other providers), `~/Library/Mobile Documents` (iCloud Drive) and the wiki
(pushed to Google Drive by its sync script).

```bash
fdesetup status | tee -a "$HOME/platform/tmp-records/tools.txt"
echo "working area: $HOME/platform" >> "$HOME/platform/tmp-records/tools.txt"
ls -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Desktop" 2>/dev/null
```

**VERIFY:** `fdesetup status` prints `FileVault is On.` The `ls` prints nothing (iCloud is not
syncing the Desktop and Documents folders), and System Settings → your name → iCloud → Drive
shows `$HOME/platform` under no synced folder. `~/Downloads` is not synced either, because
§8.2 pipes browser-downloaded secret files from it.

**ROLLBACK:** None needed. If FileVault is off, stop: turn it on (System Settings → Privacy &
Security → FileVault) before any credential touches the disk.

**EVIDENCE:** One line in `tools.txt`: FileVault state and the working-area path.
`<date>-PR-1.1-workstation-tools-v1`. E-xx: none. TISAX: 5.1.1.

### PR-1.3 One clean browser profile per admin account

**WHO:** Platform owner.

**WHERE:** Chrome → profile icon → Add → Continue without an account.

**ACTION:** Create one profile per account that will ever sign in to an admin surface from this
workstation, each named after its account and signed in to nothing else:

| Profile | Account | Created in |
|---|---|---|
| `daily` | `OWNER_DAILY_ACCOUNT` (the existing profile; Admin console reads until 06) | now |
| `sa-1-admin` | `sa-1-admin@$DOMAIN`, the account [06-organisation-bootstrap-and-roster.md](06-organisation-bootstrap-and-roster.md) creates. No variable holds it in files 01 to 05; 06 sets `SA_1_ADMIN` when the account exists | now, empty until 06 |
| `consent-eve` | none: used once for `eve@`'s consent by the second human on the second human's own workstation | 24, not here |
| `consent-walle` | none: used once for Wall-E's consent sitting | 32 |

Rules: never sign two accounts into one profile; no password manager or sync in an admin
profile; `gcloud auth login --no-launch-browser` prints a URL that is opened by hand in the
matching profile, never in the default browser.

**VERIFY:** Chrome → profile icon lists `daily` and `sa-1-admin`; in `sa-1-admin`,
`chrome://settings/syncSetup` shows no account signed in.

**ROLLBACK:** Delete the profile (profile icon → Manage profiles → the profile → Delete).

**EVIDENCE:** The profile list in the build log under PR-1.3. E-xx: none. TISAX: 4.1.2.

## 5. The repositories and the variables file

### PR-2.1 Create the two local repositories

**WHO:** Platform owner.

**WHERE:** macOS terminal.

**ACTION:** These two paths are the only values typed as plain shell variables in the whole
set; PR-2.3 records them. `Assumption:` the paths below; choose others now if needed, never later.

```bash
PLATFORM_REPO_DIR="$HOME/platform/agentic-platform"
BUILD_LOG_DIR="$HOME/platform/build-log"
git init -b main "$PLATFORM_REPO_DIR"
git init -b main "$BUILD_LOG_DIR"
git -C "$PLATFORM_REPO_DIR" config user.email "<the platform owner's email>"
git -C "$BUILD_LOG_DIR" config user.email "$(git -C "$PLATFORM_REPO_DIR" config user.email)"
git -C "$PLATFORM_REPO_DIR" config user.name "the platform owner"
git -C "$BUILD_LOG_DIR" config user.name "the platform owner"
mkdir -p "$PLATFORM_REPO_DIR/env" "$PLATFORM_REPO_DIR/decisions" "$BUILD_LOG_DIR/registers" "$BUILD_LOG_DIR/records"
mv "$HOME/platform/tmp-records/tools.txt" "$BUILD_LOG_DIR/records/" && rmdir "$HOME/platform/tmp-records"
```

**VERIFY:**

```bash
git -C "$PLATFORM_REPO_DIR" rev-parse --is-inside-work-tree
git -C "$BUILD_LOG_DIR" rev-parse --is-inside-work-tree
case "$PLATFORM_REPO_DIR$BUILD_LOG_DIR" in *"Library/CloudStorage"*|*"Mobile Documents"*|*"/Desktop/"*|*"/Documents/"*|*"/Claude/wiki"*) echo "FAIL: synced location";; *) echo "location OK";; esac
```

Expected: `true`, `true`, `location OK`.

**ROLLBACK:** `rm -rf` the two directories before any commit; after the first commit, keep
them.

**EVIDENCE:** Build-log line under PR-2.1. E-xx: E-05. TISAX: 5.3.1.

### PR-2.2 Commit the variables-file template

**WHO:** Platform owner. The second operator reviews the commit when named (02 records the same
kind of local review until the remote exists).

**WHERE:** macOS terminal, same shell as PR-2.1.

**ACTION:** Write the template exactly as below, then commit it. It holds helpers and markers
only, no value.

```bash
cat > "$PLATFORM_REPO_DIR/env/platform-env.template" <<'PLATFORM_ENV_TEMPLATE'
# ~/.platform-env: the variables file of the agentic platform setup procedures.
# Installed from env/platform-env.template in the platform repository (setup/01, PR-2.3).
# Never committed. Holds no secret: no password, token, client secret, key material or backup code.
# Source it by hand at the start of every sitting:  source ~/.platform-env
# Write values only with penv_set. Never edit a value line by hand.

# ---- shell options and constants ------------------------------------------------
if [ -n "${ZSH_VERSION-}" ]; then setopt pipefail; else set -o pipefail; fi
_PENV_NL="$(printf '\n_')"; _PENV_NL="${_PENV_NL%_}"
_PENV_TAB="$(printf '\t')"
# The names a twin shell rewrites are listed once, in _penv_apply_mode below. There is no second
# list: a second one would drift from the code that does the work.
: "${PLATFORM_ENV_FILE:=$HOME/.platform-env}"
export PLATFORM_ENV_FILE

# ---- helpers ----------------------------------------------------------------------
_penv_get() {
  case "${1-}" in ''|[0-9]*|*[!A-Za-z0-9_]*) return 2;; esac
  eval "printf '%s' \"\${$1-}\""
}

_penv_names() { sed -n 's/^export \([A-Z0-9_]*\)=.*/\1/p' "$PLATFORM_ENV_FILE"; }

# penv_set [--force] NAME VALUE: writes a value once; refuses a different value without --force.
penv_set() {
  _pf=""
  if [ "${1-}" = "--force" ]; then _pf=1; shift; fi
  [ $# -eq 2 ] || { echo "usage: penv_set [--force] NAME VALUE" >&2; return 2; }
  _pn="$1"; _pv="$2"
  case "$_pn" in ''|[0-9]*|*[!A-Z0-9_]*) echo "penv_set: bad name '$_pn'" >&2; return 2;; esac
  case "$_pn" in PROJECT|FOLDER_ID|BILLING|CUSTOMER_ID|SA_WALLE_CI|LOGS_DATASET|CLOUDSDK_*)
    echo "penv_set: $_pn is a retired or forbidden name" >&2; return 2;; esac
  case "$_pn" in *PASSWORD*|*BACKUP_CODE*|*_SECRET|*_TOKEN|*PRIVATE_KEY*)
    echo "penv_set: $_pn names a secret; secrets go to Secret Manager or the vault" >&2; return 2;; esac
  case "$_pv" in *'"'*|*'\'*|*'$'*|*'`'*|*';'*|*"$_PENV_NL"*)
    echo "penv_set: the value of $_pn contains a forbidden character" >&2; return 2;; esac
  case "$_pv" in 1//*|ya29.*|GOCSPX-*|*-----BEGIN*)
    echo "penv_set: the value of $_pn looks like a credential; refused, nothing written" >&2; return 2;; esac
  case "${PLATFORM_SHELL_MODE-}" in
    '') ;;
    twin|twin-sandbox-org)
      case "$_pn" in *TWIN*|SANDBOX_*|*_RECORD) ;;
        *) echo "penv_set: in a $PLATFORM_SHELL_MODE shell only *TWIN*, SANDBOX_* and *_RECORD names may be written" >&2; return 2;; esac;;
    *) echo "penv_set: refused inside a $PLATFORM_SHELL_MODE shell; exit it first" >&2; return 2;;
  esac
  [ -f "$PLATFORM_ENV_FILE" ] || { echo "penv_set: $PLATFORM_ENV_FILE does not exist" >&2; return 1; }
  if grep -q "^export ${_pn}=" "$PLATFORM_ENV_FILE"; then
    _pcur="$(grep "^export ${_pn}=" "$PLATFORM_ENV_FILE" | tail -n 1 | sed -e "s/^export ${_pn}=\"//" -e 's/"$//')"
    if [ "$_pcur" = "$_pv" ]; then eval "export ${_pn}=\"\$_pv\""; echo "unchanged $_pn"; return 0; fi
    if [ "$_pcur" != '*tbd*' ] && [ -z "$_pf" ]; then
      echo "penv_set: REFUSED: $_pn is already '$_pcur'; a different value needs --force and a build-log line" >&2; return 1
    fi
    if [ -n "$_pf" ]; then
      if [ -z "${BUILD_LOG_DIR-}" ] || [ ! -d "$BUILD_LOG_DIR" ]; then echo "penv_set: --force needs BUILD_LOG_DIR" >&2; return 1; fi
      printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "penv_set --force" "$_pn" "$_pcur" "$_pv" >> "$BUILD_LOG_DIR/variables-changes.tsv"
    fi
  fi
  _ptmp="$(mktemp "${PLATFORM_ENV_FILE}.XXXXXX")" || return 1
  if awk -v n="$_pn" -v v="$_pv" '
      BEGIN { p = "export " n "="; done = 0 }
      index($0, p) == 1 { if (!done) { print p "\"" v "\""; done = 1 }; next }
      $0 == "# ---- end of values ----" && !done { print p "\"" v "\""; done = 1 }
      { print }' "$PLATFORM_ENV_FILE" > "$_ptmp" && chmod 600 "$_ptmp" && mv "$_ptmp" "$PLATFORM_ENV_FILE"; then
    eval "export ${_pn}=\"\$_pv\""; echo "set $_pn"
  else
    rm -f "$_ptmp"; echo "penv_set: write failed; file unchanged" >&2; return 1
  fi
}

# need NAME...: fails when a variable is empty, *tbd* or still a <placeholder>.
need() {
  _nm=0
  for _nn in "$@"; do
    _nv="$(_penv_get "$_nn")" || { echo "need: bad name '$_nn'" >&2; _nm=1; continue; }
    case "$_nv" in ''|'*tbd*'|*'<'*'>'*) echo "MISSING $_nn: stop, do not run the rest of this block" >&2; _nm=1;; esac
  done
  return $_nm
}

# exists_or_pending [--pending] MEMBER STEP_ID WHAT_TO_RERUN
#   0 EXISTS (run the grant); 1 PENDING (recorded in the re-run index; do not run the grant);
#   2 UNKNOWN (the check itself failed; stop and read the error).
exists_or_pending() {
  _ep=""
  if [ "${1-}" = "--pending" ]; then _ep=1; shift; fi
  [ $# -eq 3 ] || { echo "usage: exists_or_pending [--pending] MEMBER STEP_ID WHAT_TO_RERUN" >&2; return 2; }
  need BUILD_LOG_DIR || return 2
  _em="$1"; _es="$2"; _ew="$3"; _eerr="recorded by hand with --pending"
  if [ -z "$_ep" ]; then
    case "$_em" in
      serviceAccount:*@*.iam.gserviceaccount.com)
        _eaddr="${_em#serviceAccount:}"; _eproj="${_eaddr#*@}"; _eproj="${_eproj%.iam.gserviceaccount.com}"
        if _eerr="$(gcloud iam service-accounts describe "$_eaddr" --project="$_eproj" --format='value(email)' 2>&1 >/dev/null)"; then
          echo "EXISTS $_em"; return 0; fi;;
      group:*@*)
        _eaddr="${_em#group:}"
        if _eerr="$(gcloud identity groups describe "$_eaddr" --format='value(name)' 2>&1 >/dev/null)"; then
          echo "EXISTS $_em"; return 0; fi;;
      *) echo "UNKNOWN $_em: only serviceAccount: and group: members are checked; confirm by hand, then use --pending or run the grant" >&2; return 2;;
    esac
    case "$_eerr" in
      *NOT_FOUND*|*"not found"*|*"does not exist"*) ;;
      *) echo "UNKNOWN $_em: the check failed for another reason; stop and read:" >&2; printf '%s\n' "$_eerr" >&2; return 2;;
    esac
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%d)" "$_es" "$_em" "$_ew" "PENDING" \
    "$(printf '%s' "$_eerr" | tr '\t\n' '  ' | cut -c1-200)" >> "$BUILD_LOG_DIR/rerun-index.tsv"
  echo "PENDING $_em: recorded for $_es in rerun-index.tsv; the grant was not run"
  return 1
}

# twin_shell [--sandbox-org]: a child shell in which production names resolve to the twin names.
twin_shell() {
  _tm=twin
  if [ "${1-}" = "--sandbox-org" ]; then _tm=twin-sandbox-org; fi
  [ -z "${PLATFORM_SHELL_MODE-}" ] || { echo "twin_shell: already inside a $PLATFORM_SHELL_MODE shell" >&2; return 1; }
  need WALLE_TWIN_PROJECT EVE_TWIN_PROJECT SANDBOX_DOMAIN SANDBOX_CUSTOMER_ID || return 1
  if [ "$_tm" = twin-sandbox-org ]; then need SANDBOX_ORG_ID || return 1; fi
  echo "Opening a $_tm shell. First command inside it: source \"$PLATFORM_ENV_FILE\". Leave it with: exit"
  PLATFORM_SHELL_MODE="$_tm" "${SHELL:-/bin/zsh}" -i
}

# walle_shell: a child shell that exports PROJECT=$WALLE_PROJECT for the Wall-E helper script only (SD-37).
walle_shell() {
  [ -z "${PLATFORM_SHELL_MODE-}" ] || { echo "walle_shell: already inside a $PLATFORM_SHELL_MODE shell" >&2; return 1; }
  need WALLE_PROJECT || return 1
  echo "Opening a walle shell for the helper script only (SD-37). First command inside it: source \"$PLATFORM_ENV_FILE\". Leave it with: exit"
  PLATFORM_SHELL_MODE=walle "${SHELL:-/bin/zsh}" -i
}

_penv_swap_project() {
  [ -n "${1-}" ] || return 0
  for _sn in $(_penv_names); do
    case "$_sn" in *TWIN*|SANDBOX_*|*WITNESS*|PLATFORM_*|BUILD_LOG_DIR|WIKI_DIR|EVIDENCE_INTERIM_LOCATION) continue;; esac
    _sv="$(_penv_get "$_sn")"
    case "$_sv" in
      *"$1"*) if [ -n "${2-}" ]; then _sv="${_sv//$1/$2}"; else _sv=""; fi
              eval "export ${_sn}=\"\$_sv\"";;
    esac
  done
}

_penv_apply_mode() {
  case "${PLATFORM_SHELL_MODE-}" in
    '')
      if [ -n "${PROJECT-}" ]; then unset PROJECT; echo "unset PROJECT: only walle_shell sets it" >&2; fi;;
    twin|twin-sandbox-org)
      _penv_swap_project "${WALLE_PROJECT-}" "${WALLE_TWIN_PROJECT-}"
      _penv_swap_project "${EVE_PROJECT-}" "${EVE_TWIN_PROJECT-}"
      export WALLE_PROJECT="${WALLE_TWIN_PROJECT-}"
      export WALLE_PROJECT_NUMBER="${WALLE_TWIN_PROJECT_NUMBER-}"
      export EVE_PROJECT="${EVE_TWIN_PROJECT-}"
      export EVE_PROJECT_NUMBER="${EVE_TWIN_PROJECT_NUMBER-}"
      export DOMAIN="${SANDBOX_DOMAIN-}"
      export DIRECTORY_CUSTOMER_ID="${SANDBOX_CUSTOMER_ID-}"
      export WALLE_OPERATORS_GROUP="${SANDBOX_OPERATORS_GROUP-}"
      export EVE_ROBOT="${EVE_TWIN_ROBOT-}"
      export ROBOT="${WALLE_TWIN_ROBOT-}"
      export EVE_TOKEN_VERSION="${EVE_TWIN_TOKEN_VERSION-}"
      export REFRESH_TOKEN_VERSION=""
      export SUPER_REFRESH_TOKEN_VERSION=""
      if [ "$PLATFORM_SHELL_MODE" = twin-sandbox-org ]; then export ORG_ID="${SANDBOX_ORG_ID-}"; fi
      PS1="[$PLATFORM_SHELL_MODE] ${PS1-}";;
    walle)
      export PROJECT="${WALLE_PROJECT-}"
      PS1="[walle] ${PS1-}";;
    *) echo "unknown PLATFORM_SHELL_MODE '$PLATFORM_SHELL_MODE'; exit this shell" >&2;;
  esac
}

# penv_guard: fails when any gcloud or bq default project could redirect a command.
penv_guard() {
  _gf=0
  [ -n "${GCLOUD_CONFIG_NAME-}" ] || { echo "GUARD: GCLOUD_CONFIG_NAME is not set (01 PR-2.3)" >&2; return 1; }
  [ "${CLOUDSDK_ACTIVE_CONFIG_NAME-}" = "$GCLOUD_CONFIG_NAME" ] || { echo "GUARD: CLOUDSDK_ACTIVE_CONFIG_NAME is not $GCLOUD_CONFIG_NAME" >&2; _gf=1; }
  [ -z "${CLOUDSDK_CORE_PROJECT-}" ] || { echo "GUARD: CLOUDSDK_CORE_PROJECT is exported" >&2; _gf=1; }
  if [ "${PLATFORM_SHELL_MODE-}" != walle ] && [ -n "${PROJECT-}" ]; then echo "GUARD: PROJECT is set outside walle_shell" >&2; _gf=1; fi
  command -v gcloud >/dev/null 2>&1 || { echo "GUARD: gcloud is not on PATH" >&2; return 1; }
  # The exit status is checked separately: a hidden failure (no named configuration yet, a broken
  # install, an unreadable CLOUDSDK_CONFIG) also prints nothing on standard output, and must not
  # be read as "no project is set". Assumption: an unset property prints '' or '(unset)'.
  _gerr="$(mktemp "${TMPDIR:-/tmp}/penv-guard.XXXXXX")" || { echo "GUARD: cannot create a temporary file" >&2; return 1; }
  if _gp="$(gcloud config get project 2>"$_gerr")"; then
    case "$_gp" in
      ''|'(unset)') ;;
      *) echo "GUARD: configuration $GCLOUD_CONFIG_NAME has project '$_gp'; run: gcloud config unset project" >&2; _gf=1;;
    esac
  elif [ ! -f "${CLOUDSDK_CONFIG-}/configurations/config_${GCLOUD_CONFIG_NAME}" ]; then
    echo "GUARD: configuration $GCLOUD_CONFIG_NAME does not exist yet; 01 PR-3.1 creates it" >&2; _gf=1
  else
    echo "GUARD: could not read the active configuration; stop and read:" >&2; cat "$_gerr" >&2; _gf=1
  fi
  rm -f "$_gerr"
  if [ -f "$HOME/.bigqueryrc" ] && grep -q 'project_id' "$HOME/.bigqueryrc"; then echo "GUARD: ~/.bigqueryrc sets project_id; delete that line" >&2; _gf=1; fi
  return $_gf
}

# checkpoint STEP_ID STATUS [WITNESS] [EVIDENCE] [NOTE]: one committed build-log line per event.
#   STATUS: START DONE BLOCKED PENDING ROLLED-BACK N/A. WITNESS and EVIDENCE default to "-".
checkpoint() {
  [ $# -ge 2 ] || { echo "usage: checkpoint STEP_ID START|DONE|BLOCKED|PENDING|ROLLED-BACK|N/A [WITNESS] [EVIDENCE] [NOTE]" >&2; return 2; }
  need BUILD_LOG_DIR || return 2
  case "$2" in START|DONE|BLOCKED|PENDING|ROLLED-BACK|N/A) ;; *) echo "checkpoint: bad status '$2'" >&2; return 2;; esac
  case "$1${3-}${4-}${5-}" in *"$_PENV_TAB"*|*"$_PENV_NL"*) echo "checkpoint: no tab or newline allowed" >&2; return 2;; esac
  case "$1${3-}${4-}${5-}" in *'<'*'>'*) echo "checkpoint: an unreplaced <placeholder> would be written verbatim into the log; type the real value" >&2; return 2;; esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "$(git -C "$BUILD_LOG_DIR" config user.email)" "${3:--}" "${4:--}" "${5-}" >> "$BUILD_LOG_DIR/checkpoints.tsv" \
    && git -C "$BUILD_LOG_DIR" add checkpoints.tsv && git -C "$BUILD_LOG_DIR" commit -q -m "checkpoint $1 $2"
}

# evidence_add STEP_ID SLUG E_ID TISAX_ID LOCATION [FILE]: one row in the evidence register, committed.
evidence_add() {
  [ $# -ge 5 ] || { echo "usage: evidence_add STEP_ID SLUG E_ID|- TISAX_ID|- LOCATION [FILE]" >&2; return 2; }
  need BUILD_LOG_DIR EVIDENCE_REGISTER || return 2
  case "$1$2$3$4$5${6-}" in *'|'*|*"$_PENV_TAB"*|*"$_PENV_NL"*) echo "evidence_add: no | tab or newline allowed" >&2; return 2;; esac
  case "$2" in *[!a-z0-9-]*|'') echo "evidence_add: slug must be lower-case letters, digits and hyphens" >&2; return 2;; esac
  _xd="$(date -u +%Y-%m-%d)"; _xp="${_xd}-${1}-${2}-v"
  _xn=$(( $(grep -c "| ${_xp}[0-9]* |" "$EVIDENCE_REGISTER") + 1 ))
  _xh="-"
  if [ -n "${6-}" ]; then [ -f "$6" ] || { echo "evidence_add: $6 is not a file" >&2; return 2; }; _xh="$(shasum -a 256 "$6" | cut -d' ' -f1)"; fi
  printf '| %s | %s | %s | %s | %s | %s | %s | %s | - | - |\n' "${_xp}${_xn}" "$_xd" "$1" "$3" "$4" "$5" "$_xh" "$(git -C "$BUILD_LOG_DIR" config user.email)" >> "$EVIDENCE_REGISTER" \
    && git -C "$BUILD_LOG_DIR" add "$EVIDENCE_REGISTER" && git -C "$BUILD_LOG_DIR" commit -q -m "evidence ${_xp}${_xn}" && echo "recorded ${_xp}${_xn}"
}

# sitting_end: revokes every gcloud credential and proves none is left.
sitting_end() {
  command -v gcloud >/dev/null 2>&1 || { echo "sitting_end: gcloud not on PATH" >&2; return 1; }
  # Checked before anything is revoked: without CLOUDSDK_CONFIG the ADC path below would be the
  # absolute "/application_default_credentials.json", a file that can never exist, and sitting_end
  # would print OK while the real ADC file in $HOME/.config/gcloud-$GCLOUD_CONFIG_NAME/ was left in
  # place. Failing first also keeps an unsourced shell from revoking the daily account.
  [ -n "${CLOUDSDK_CONFIG-}" ] || { echo "SITTING-END FAIL: CLOUDSDK_CONFIG is not set; source ~/.platform-env first, then run sitting_end again. Nothing was revoked" >&2; return 1; }
  gcloud auth revoke --all --quiet 2>/dev/null
  gcloud auth application-default revoke --quiet 2>/dev/null
  _sa="$(gcloud auth list --format='value(account)' 2>/dev/null)"
  _sfail=0
  [ -z "$_sa" ] || { echo "SITTING-END FAIL: still credentialed: $_sa" >&2; _sfail=1; }
  for _sfile in "$CLOUDSDK_CONFIG/application_default_credentials.json" "$HOME/.walle/operator-token.json"; do
    [ ! -e "$_sfile" ] || { echo "SITTING-END FAIL: $_sfile exists" >&2; _sfail=1; }
  done
  [ ! -e "$HOME/.config/gcloud/application_default_credentials.json" ] || echo "SITTING-END WARN: default-directory ADC file exists; it must not belong to an admin account" >&2
  [ $_sfail -eq 0 ] && echo "SITTING-END OK: no credentialed account, no ADC file, no operator token cache"
  return $_sfail
}

# ---- values: written only by penv_set -----------------------------------------------
# ---- end of values ----

# ---- applied after the values -------------------------------------------------------
if [ -n "${GCLOUD_CONFIG_NAME-}" ]; then
  export CLOUDSDK_CONFIG="$HOME/.config/gcloud-${GCLOUD_CONFIG_NAME}"
  export CLOUDSDK_ACTIVE_CONFIG_NAME="$GCLOUD_CONFIG_NAME"
fi
if [ -n "${CLOUDSDK_CORE_PROJECT-}" ]; then unset CLOUDSDK_CORE_PROJECT; echo "unset CLOUDSDK_CORE_PROJECT" >&2; fi
_penv_apply_mode
if [ -n "${GCLOUD_CONFIG_NAME-}" ] && command -v gcloud >/dev/null 2>&1; then penv_guard; fi
PLATFORM_ENV_TEMPLATE
git -C "$PLATFORM_REPO_DIR" add env/platform-env.template
git -C "$PLATFORM_REPO_DIR" commit -m "env: platform-env template (setup 01 PR-2.2)"
```

What the helpers do:

| Helper | Does | Refuses |
|---|---|---|
| `penv_set [--force] NAME VALUE` | Writes `export NAME="VALUE"` before the end-of-values marker, mode 600, and exports it in the current shell; replaces `*tbd*` freely | A different existing value without `--force` (with `--force` it logs old and new values to `BUILD_LOG_DIR/variables-changes.tsv`); retired names (`PROJECT`, `FOLDER_ID`, `BILLING`, `CUSTOMER_ID`, `SA_WALLE_CI`, `LOGS_DATASET`, any `CLOUDSDK_*`); names that denote a secret; values containing `"` `\` `$` backtick `;` or a newline; values that look like a Google refresh token, access token, client secret or PEM key (a tripwire, not a guarantee); any write in a `walle` shell; in a twin shell, any name other than `*TWIN*`, `SANDBOX_*` or `*_RECORD` |
| `need NAME...` | Returns 0 when every name has a real value | Empty, `*tbd*` or `<placeholder>` values: prints `MISSING NAME` |
| `exists_or_pending [--pending] MEMBER STEP WHAT` | For `serviceAccount:` and `group:` members, describes the principal. 0 = EXISTS, run the grant; 1 = PENDING, a line is appended to `BUILD_LOG_DIR/rerun-index.tsv` and the grant is not run; 2 = UNKNOWN, stop | Treating an error other than not-found as pending. `--pending` records by hand when the owning project does not exist yet (the file that creates it has no `DONE` line) |
| `twin_shell [--sandbox-org]` | Opens a child shell; after `source ~/.platform-env` inside it, `WALLE_PROJECT`, `EVE_PROJECT`, their numbers, `DOMAIN`, `DIRECTORY_CUSTOMER_ID`, `WALLE_OPERATORS_GROUP`, `EVE_ROBOT`, `ROBOT` and `EVE_TOKEN_VERSION` resolve to the twin or sandbox names; every other value containing the production project id is rewritten to the twin id; `REFRESH_TOKEN_VERSION` and `SUPER_REFRESH_TOKEN_VERSION` are blanked; `ORG_ID` becomes `SANDBOX_ORG_ID` only with `--sandbox-org`, for sandbox-organisation sink steps | Opening without the twin names set; nesting. A twin name that is not set resolves to empty, so `need` fails instead of falling back to production |
| `walle_shell` | Opens a child shell in which `PROJECT=$WALLE_PROJECT`, for the Wall-E helper script only (SD-37) | Any `penv_set`; nesting |
| `penv_guard` | Runs at every source; silent when clean | A gcloud project in the active configuration, `CLOUDSDK_CORE_PROJECT` exported, `PROJECT` outside `walle_shell`, `project_id` in `~/.bigqueryrc`, a different active configuration |
| `checkpoint STEP STATUS [WITNESS] [EVIDENCE] [NOTE]` | Appends a tab-separated line to `BUILD_LOG_DIR/checkpoints.tsv` and commits it. `WITNESS` and `EVIDENCE` default to `-`, so a step whose WHO names a witness must pass a real value | Unknown statuses; tabs or newlines; an unreplaced `<placeholder>` in any field |
| `evidence_add STEP SLUG E-ID TISAX LOCATION [FILE]` | Appends a row named `<date>-<step>-<slug>-v<n>` to `EVIDENCE_REGISTER`, with the file's SHA-256, and commits it | A pipe, tab or newline; a slug outside `a-z0-9-` |
| `sitting_end` | Revokes every gcloud credential and ADC, then proves none is left | Exits non-zero while an account, the platform ADC file or `~/.walle/operator-token.json` remains |

Other names used by other files (for example `WALLE_READERS_GROUP` or `GRP_*` addresses) are
not rewritten in a twin shell. A twin step that reads one says why in its text.

**VERIFY:**

```bash
git -C "$PLATFORM_REPO_DIR" log --oneline -- env/platform-env.template
grep -c '^export ' "$PLATFORM_REPO_DIR/env/platform-env.template"
grep -n '^# ---- end of values ----$' "$PLATFORM_REPO_DIR/env/platform-env.template"
```

Expected: one commit; `1` (the only `export` at line start is `export PLATFORM_ENV_FILE`); one
marker line.

**ROLLBACK:** `git -C "$PLATFORM_REPO_DIR" revert HEAD` before any value is written.

**EVIDENCE:** Commit id in the build log under PR-2.2, `<date>-PR-2.2-env-template-v1`. E-xx:
E-05. TISAX: 5.3.1.

### PR-2.3 Install `~/.platform-env` and write the fixed values

**WHO:** Platform owner.

**WHERE:** macOS terminal, same shell as PR-2.1.

**ACTION:**

```bash
if [ -e "$HOME/.platform-env" ]; then
  echo "STOP: ~/.platform-env already exists. It may be a stale file from an aborted run or from other work: a different template, retired names, or another tenant's values. Check it holds no secret, move it to \"$BUILD_LOG_DIR/records/retired/\", then re-run this step. Do not source it."
else
  install -m 600 "$PLATFORM_REPO_DIR/env/platform-env.template" "$HOME/.platform-env"
fi
source "$HOME/.platform-env"
penv_set PLATFORM_ENV_FILE "$HOME/.platform-env"
penv_set GCLOUD_CONFIG_NAME platform-bootstrap
penv_set PLATFORM_REPO_DIR "$PLATFORM_REPO_DIR"
penv_set BUILD_LOG_DIR "$BUILD_LOG_DIR"
penv_set WIKI_DIR "$HOME/Claude/wiki"
penv_set REGION europe-west1
penv_set BQ_LOCATION EU
penv_set GE_LOCATION eu
penv_set MODEL_LOCATION eu
penv_set DEVIATION_REGISTER "$BUILD_LOG_DIR/registers/bootstrap-deviation-register.md"
penv_set EVIDENCE_REGISTER "$BUILD_LOG_DIR/registers/evidence-register.md"
penv_set DRILL_CALENDAR "$BUILD_LOG_DIR/registers/drill-calendar.md"
source "$PLATFORM_ENV_FILE"
```

Expect one line on the second `source`: once `GCLOUD_CONFIG_NAME` is set, `~/.platform-env` runs
`penv_guard` at every source, and the named gcloud configuration does not exist until PR-3.1
creates it. The guard prints
`GUARD: configuration platform-bootstrap does not exist yet; 01 PR-3.1 creates it` and returns
non-zero. That is the expected state here and only here; from PR-3.1 onwards the guard is silent,
and any other guard line is a stop.

Retired files: `~/.walle-env`, `~/.eve-env` and `~/.mo-env` are not created. If the Wall-E
helper script is ever used (SD-37), file 30 generates the file it reads from `~/.platform-env`
inside `walle_shell` and deletes it afterwards; nobody maintains a second variables file (S165).
Never source `~/.platform-env` from `~/.zshrc` or `~/.bashrc`: sourcing is a deliberate act at
the start of a sitting, and a twin shell depends on it.

**VERIFY:**

```bash
ls -l "$PLATFORM_ENV_FILE" | cut -c1-10
diff <(sed -n '/^# ---- helpers/,/^# ---- values/p' "$PLATFORM_REPO_DIR/env/platform-env.template") <(sed -n '/^# ---- helpers/,/^# ---- values/p' "$PLATFORM_ENV_FILE") && echo "template identity OK"
need PLATFORM_ENV_FILE GCLOUD_CONFIG_NAME PLATFORM_REPO_DIR BUILD_LOG_DIR WIKI_DIR REGION BQ_LOCATION GE_LOCATION MODEL_LOCATION DEVIATION_REGISTER EVIDENCE_REGISTER DRILL_CALENDAR && echo "values OK"
penv_set REGION europe-west4; echo "exit $?"
ls "$HOME/.walle-env" "$HOME/.eve-env" "$HOME/.mo-env" 2>/dev/null || echo "no retired variables files"
```

Expected: `-rw-------`; `template identity OK` (the helper block of the installed file is
byte-identical to the committed template, so a stale file from earlier work cannot pass
unnoticed); `values OK`; `penv_set: REFUSED: REGION is already 'europe-west1'…`
and `exit 1`; `no retired variables files`. If a retired file exists from earlier work, move it
out of `$HOME` into the build log's `records/retired/` after checking it holds no secret; do not
source it again.

**ROLLBACK:** `rm "$HOME/.platform-env"` and repeat from the template.

**EVIDENCE:** Build-log line under PR-2.3 listing the names set, not the file. E-xx: E-05.
TISAX: 5.3.1.

### PR-2.4 Start the checkpoint log, the re-run index and the change log

**WHO:** Platform owner.

**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:**

This step is re-runnable. Every creation below is guarded, because the resume rule of §1
restarts at the first step without a `DONE` line and PR-2.4 has none until it finishes: a run cut
between the header writes and the final `checkpoint` is resumed by re-running PR-2.4, and an
unguarded `>` would destroy every checkpoint, re-run and `penv_set --force` line already written.
`variables-changes.tsv` is the most exposed, because PR-2.6's ROLLBACK tells the operator to use
`penv_set --force`, which appends to it.

```bash
need BUILD_LOG_DIR
[ -e "$BUILD_LOG_DIR/checkpoints.tsv" ] || printf 'utc_timestamp\tstep_id\tstatus\toperator\twitness\tevidence\tnote\n' > "$BUILD_LOG_DIR/checkpoints.tsv"
[ -e "$BUILD_LOG_DIR/rerun-index.tsv" ] || printf 'date\tstep_id\tmember\twhat_to_rerun\tstatus\tdetail\n' > "$BUILD_LOG_DIR/rerun-index.tsv"
[ -e "$BUILD_LOG_DIR/variables-changes.tsv" ] || printf 'utc_timestamp\taction\tname\told_value\tnew_value\n' > "$BUILD_LOG_DIR/variables-changes.tsv"
head -n 1 "$BUILD_LOG_DIR/checkpoints.tsv" | grep -q '^utc_timestamp' || echo "STOP: checkpoints.tsv exists without its header; prepend it by hand. Nothing was overwritten"
head -n 1 "$BUILD_LOG_DIR/rerun-index.tsv" | grep -q '^date' || echo "STOP: rerun-index.tsv exists without its header; prepend it by hand. Nothing was overwritten"
head -n 1 "$BUILD_LOG_DIR/variables-changes.tsv" | grep -q '^utc_timestamp' || echo "STOP: variables-changes.tsv exists without its header; prepend it by hand. Nothing was overwritten"
git -C "$BUILD_LOG_DIR" add checkpoints.tsv rerun-index.tsv variables-changes.tsv records/tools.txt
git -C "$BUILD_LOG_DIR" diff --cached --quiet || git -C "$BUILD_LOG_DIR" commit -m "build log: headers and PR-1.1 tools record"
for step in PR-1.1 PR-1.2 PR-1.3 PR-2.1 PR-2.2 PR-2.3; do
  awk -F'\t' -v s="$step" '$2==s && $3=="DONE"{f=1} END{exit !f}' "$BUILD_LOG_DIR/checkpoints.tsv" \
    || checkpoint "$step" DONE - - "backfilled at PR-2.4; performed before the log existed"
done
awk -F'\t' '$2=="PR-2.4" && $3=="DONE"{f=1} END{exit !f}' "$BUILD_LOG_DIR/checkpoints.tsv" \
  || checkpoint PR-2.4 DONE - "build-log:checkpoints.tsv" "log started"
```

The three headers are written only when the file does not exist; a file that exists without its
header prints a `STOP:` line instead of being overwritten (`penv_set --force` can append to
`variables-changes.tsv` before PR-2.4 ever runs). The backfill loop and the closing `checkpoint`
run only when no `DONE` line for that step exists. A second run of PR-2.4 therefore adds nothing
and destroys nothing.

The re-run index is append-only: a re-run that has been made adds a second line with the same
member and status `DONE`, naming the step whose VERIFY closed it. README §9 is the planned list;
this file is the live list.

**VERIFY:**

```bash
awk -F'\t' '$3=="DONE"{print $2}' "$BUILD_LOG_DIR/checkpoints.tsv"
awk -F'\t' '$3=="DONE"{print $2}' "$BUILD_LOG_DIR/checkpoints.tsv" | sort | uniq -d
head -n 1 "$BUILD_LOG_DIR/rerun-index.tsv"
head -n 1 "$BUILD_LOG_DIR/variables-changes.tsv"
```

Expected: PR-1.1 to PR-2.4, one per line; the `uniq -d` line prints nothing (no step was
backfilled twice by a resumed run); the two headers. Run the whole ACTION block a second time and
repeat this VERIFY: the output must be identical.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD`; never rewrite history once pushed.

**EVIDENCE:** The commits themselves. E-xx: E-05. TISAX: 5.2.1.

### PR-2.5 Check the helpers on a throwaway copy

**WHO:** Platform owner.

**WHERE:** macOS terminal, in a new shell (this check must not touch the real file).

**ACTION:**

```bash
T="$(mktemp -d)"
install -m 600 "$(sed -n 's/^export PLATFORM_REPO_DIR="\(.*\)"$/\1/p' "$HOME/.platform-env")/env/platform-env.template" "$T/env"
mkdir "$T/log" && git -C "$T/log" init -q && git -C "$T/log" config user.email check@invalid && git -C "$T/log" config user.name check
bash -c 'export PLATFORM_ENV_FILE="$1/env"; . "$1/env"; penv_set BUILD_LOG_DIR "$1/log"; penv_set WALLE_PROJECT prod-x; penv_set WALLE_TWIN_PROJECT twin-x; penv_set EVE_PROJECT eve-p; penv_set EVE_TWIN_PROJECT eve-n; penv_set SANDBOX_DOMAIN sb.invalid; penv_set SANDBOX_CUSTOMER_ID C0sb; penv_set SA_ACTIONS walle-actions@prod-x.iam.gserviceaccount.com; penv_set WALLE_PROJECT other; penv_set REFRESH_TOKEN_VERSION 3; penv_set EVE_REFRESH_TOKEN x; ( PLATFORM_SHELL_MODE=twin; . "$1/env"; echo "twin: $WALLE_PROJECT $SA_ACTIONS [$REFRESH_TOKEN_VERSION]" ); ( PLATFORM_SHELL_MODE=walle; . "$1/env"; echo "walle: PROJECT=$PROJECT" ); need NOTSET; exists_or_pending --pending serviceAccount:x@eve-p.iam.gserviceaccount.com PR-2.5 check; cat "$1/log/rerun-index.tsv"; checkpoint PR-2.5 DONE "<witness or ->" - "placeholder check"; echo "checkpoint exit $?"; ( unset CLOUDSDK_CONFIG; sitting_end >/dev/null 2>"$1/se.err"; echo "sitting_end exit $?"; cat "$1/se.err" )' _ "$T"
rm -rf "$T"
```

**VERIFY:** The output contains, in order: `REFUSED: WALLE_PROJECT is already 'prod-x'`;
`EVE_REFRESH_TOKEN names a secret`; `twin: twin-x walle-actions@twin-x.iam.gserviceaccount.com []`;
`walle: PROJECT=prod-x`; `MISSING NOTSET`; `PENDING serviceAccount:x@eve-p…` and one
`rerun-index.tsv` line; then
`checkpoint: an unreplaced <placeholder> would be written verbatim into the log` with
`checkpoint exit 2`; then `sitting_end exit 1` with
`SITTING-END FAIL: CLOUDSDK_CONFIG is not set` — proving that an unsourced shell cannot report a
clean sitting close, and that nothing was revoked when it failed. Repeat the `bash -c` line with
`zsh -c` for the same output.

The `sitting_end` check is safe to run because the guard is the first thing in the function,
before `gcloud auth revoke`: no credential of any account is touched. Never run `sitting_end`
inside a check any other way.

**ROLLBACK:** None; the copy is deleted.

**EVIDENCE:** Build-log line under PR-2.5: "helper check passed in bash and zsh". This is a
check of shell logic only. It is not evidence that any Google command, flag or API behaves as
written, and no gate may cite it (S177). E-xx: none. TISAX: none.

### PR-2.6 Read the tenant identifiers from the consoles

**WHO:** Platform owner.

**WHERE:** Chrome profile `daily`. Admin console → Account → Account settings → Profile (Customer
ID); Admin console → Billing → Subscriptions (edition); Admin console → Account → Admin roles →
Super Admin → View admins (P-02); Google Cloud console → project picker → the organisation →
More → Settings (Organization ID). Shell with `~/.platform-env` sourced.

**ACTION:** Read the four console pages, then type the three values read on screen and the two
known ones. The fourth page is the P-02 read: open Admin console → Account → Admin roles, select
**Super Admin**, click **View admins**, and confirm `OWNER_DAILY_ACCOUNT` is listed. Screenshot
that page as `<date>-PR-2.6-super-admin-roster-v1`; it is the only evidence that closes P-02, and
without it PR-5.2 would record a prerequisite as proven with nothing behind it.
[03-decisions-and-people.md](03-decisions-and-people.md) DC-4.4 reads the same path again, with
the second human present, for the full roster inventory; this read is the narrow one P-02 needs.

```bash
penv_set OWNER_DAILY_ACCOUNT "<daily account email>"
penv_set DOMAIN "<primary domain, the one users' addresses end in>"
penv_set DIRECTORY_CUSTOMER_ID "<Customer ID from Account settings, Profile>"
penv_set WORKSPACE_EDITION "<edition name from Billing, Subscriptions>"
penv_set ORG_ID "<Organization ID from the Cloud console Settings page>"
```

The angle-bracket text is replaced on the day; `need` refuses a value still containing `<…>`.
Never `my_customer` for `DIRECTORY_CUSTOMER_ID`.

**VERIFY:** `need OWNER_DAILY_ACCOUNT DOMAIN DIRECTORY_CUSTOMER_ID WORKSPACE_EDITION ORG_ID && echo OK`
prints `OK`; `case "$ORG_ID" in *[!0-9]*) echo "FAIL: not numeric";; esac` prints nothing; the
Super Admin → View admins list shows `OWNER_DAILY_ACCOUNT` (P-02, screenshot taken); PR-3.3
proves the binding (P-03).

**ROLLBACK:** `penv_set --force NAME value` for a typing error, before any later file has used
the value. The `--force` write appends the old and new values to
`BUILD_LOG_DIR/variables-changes.tsv`; PR-2.4 never truncates that file.

**EVIDENCE:** A screenshot of each of the four console pages, as
`<date>-PR-2.6-tenant-identifiers-v1` and `<date>-PR-2.6-super-admin-roster-v1` (PDF) in
`EVIDENCE_INTERIM_LOCATION` once PR-4.4 exists; until then in `BUILD_LOG_DIR/records/`. E-xx:
E-05; E-06 for the roster read. TISAX: 1.3.1; 4.1.3 for the roster read.

## 6. Shell and credential rules

### 6.1 The rules

| Rule | How it is enforced |
|---|---|
| One dedicated gcloud configuration, `GCLOUD_CONFIG_NAME`, in its own configuration directory `$HOME/.config/gcloud-$GCLOUD_CONFIG_NAME`, activated per shell by `CLOUDSDK_ACTIVE_CONFIG_NAME` | Set by `~/.platform-env` at every source; the daily gcloud directory is never used for the platform |
| The configuration has no project. `gcloud config set project` is never run, and `CLOUDSDK_CORE_PROJECT` is never exported (S071) | `penv_guard` fails when `gcloud config get project` returns a value, when the variable is exported, **and when the `gcloud config get` call itself fails** — a hidden failure prints nothing on standard output and must never be read as "clean" |
| Every gcloud command passes `--project`, `--folder`, `--organization` or `--billing-account`; every bq command passes `--project_id` and fully qualified `project:dataset` names | Written into every ACTION; `~/.bigqueryrc` holds no `project_id` (guard) |
| `PROJECT` exists only inside `walle_shell` | `penv_set` refuses it; sourcing unsets it outside `walle_shell`; guard |
| No admin OAuth refresh token stays on the laptop between sittings. Each sitting signs in, works and ends with `sitting_end` (`gcloud auth revoke --all`, `gcloud auth application-default revoke`) | PR-3.2 VERIFY: the START and DONE lines must carry the **same** sitting id, computed once in `SITTING_ID` and carried to the end; the first check of every later sitting is `gcloud auth list` showing no account before sign-in |
| Application Default Credentials are created only by a step that needs them, and revoked in the same sitting | `sitting_end` fails while the platform ADC file exists, and refuses to run at all — revoking nothing — when `CLOUDSDK_CONFIG` is unset, so an unsourced shell cannot report a clean close |
| The Wall-E script's operator token cache is never enabled (S087) | `sitting_end` fails while `~/.walle/operator-token.json` exists |
| Machine secrets go straight into Secret Manager with `--data-file=-`; human account passwords go straight into the corporate vault; nothing is echoed, printed, pasted into chat, or written to a temporary file; `shred` is never used (macOS has none, and overwriting does not erase on APFS SSDs) (S139) | §8.2 pattern; the only on-disk secret ever tolerated is a file the browser itself downloaded, piped in and deleted at once |
| No step creates, authorises or uses a domain-wide delegation client. One found is reported to the second human and recorded, never used, never deleted by the platform owner alone | 06 lists the clients (Admin console → Security → Access and data control → API controls → Manage Domain Wide Delegation, super admin only); 25 raises on any addition; 32 and 38 re-check |
| Only one path per step: the setup/ procedures. [../../wall-e/SETUP.md](../../wall-e/SETUP.md), [../../wall-e/PREREQUISITES.md](../../wall-e/PREREQUISITES.md), [../../eve/07-build-runbook.md](../../eve/07-build-runbook.md) and [../../mo/07-build-runbook.md](../../mo/07-build-runbook.md) are not executed. [../../wall-e/setup/walle_setup.py](../../wall-e/setup/walle_setup.py) is a helper usable for a step only after its defects for that subcommand are fixed (SD-37); its 220-of-220 offline self-test is not evidence (S082, S177) | A step that cites the script is BLOCKED for the script and gives the manual commands; no step mixes the two paths |

### PR-3.1 Create the dedicated gcloud configuration

**WHO:** Platform owner.

**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:**

```bash
need GCLOUD_CONFIG_NAME
echo "$CLOUDSDK_CONFIG"
env -u CLOUDSDK_ACTIVE_CONFIG_NAME gcloud config configurations create "$GCLOUD_CONFIG_NAME" --no-activate
gcloud config configurations list
gcloud config unset project
```

`CLOUDSDK_CONFIG` points gcloud at `$HOME/.config/gcloud-platform-bootstrap`, so credentials of
this configuration never mix with the daily gcloud directory. Because the file exports
`CLOUDSDK_ACTIVE_CONFIG_NAME`, the configuration is active in this shell only, and
`--no-activate` leaves the directory's global default untouched. The create runs with
`CLOUDSDK_ACTIVE_CONFIG_NAME` removed from its environment, because the named configuration
does not exist yet.

**VERIFY:**

```bash
gcloud config configurations list --format='value(name,is_active)'
gcloud config get project 2>&1
gcloud auth list --format='value(account)'
penv_guard && echo "guard clean"
```

Expected: a line `platform-bootstrap` followed by `True` (a `default` configuration, if gcloud
created one, reads `False`); no project value (an empty line or `(unset)`);
no account; `guard clean`.

**ROLLBACK:** `gcloud config configurations delete "$GCLOUD_CONFIG_NAME"` after activating
another configuration, then `rm -rf "$CLOUDSDK_CONFIG"`.

**EVIDENCE:** The VERIFY output under PR-3.1 in the build log. E-xx: none. TISAX: 5.2.2.

### PR-3.2 Prove the start-of-sitting and end-of-sitting blocks

**WHO:** Platform owner.

**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** These two blocks open and close every sitting of files 02 to 42. Run them once now,
without signing in.

Start of a sitting:

The sitting id is computed **once**, at the start, and carried to the end in `SITTING_ID`. It is
never recomputed: `date -u +%Y%m%d%H%M` changes within the minute, so a second computation gives
a different id and the START and DONE lines can never be paired — and the pairing is what
enforces §6.1's "no admin OAuth refresh token stays on the laptop between sittings".

Start of a sitting:

```bash
source "$HOME/.platform-env"
penv_guard && echo "guard clean"
gcloud auth list --format='value(account)'
SITTING_ID="SITTING-$(date -u +%Y%m%d%H%M)"; export SITTING_ID
checkpoint "$SITTING_ID" START - - "present: platform owner alone"
```

A witnessed sitting passes the witness instead of the first `-`, and names who is present in the
note, for example:
`checkpoint "$SITTING_ID" START "$SECOND_HUMAN_EMAIL" - "present: platform owner, second human"`.
Type a real value: the literal `<witness or ->` would be written verbatim into the log.

End of the same sitting, in the same shell:

```bash
sitting_end
checkpoint "$SITTING_ID" DONE - - "credentials revoked"
```

If the shell was lost, read the id back rather than recomputing it:
`SITTING_ID="$(awk -F'\t' '$2 ~ /^SITTING-/ {i=$2} END{print i}' "$BUILD_LOG_DIR/checkpoints.tsv")"`,
and confirm it has no `DONE` line before closing it.

A sign-in inside a sitting is always `gcloud auth login <account> --no-launch-browser`, with the
URL opened in the account's own browser profile. The admin browser profile signs out of the
Admin console and the Cloud console at the end of the sitting.

**VERIFY:**

```bash
awk -F'\t' '$2 ~ /^SITTING-/ {print $2, $3}' "$BUILD_LOG_DIR/checkpoints.tsv" | tail -n 2
```

Expected: two lines carrying the **same** sitting id, the first `START` and the second `DONE`.
Two different ids is a failure of this step, not a closed sitting. `sitting_end` printed
`SITTING-END OK` before the DONE line was written.

**ROLLBACK:** None.

**EVIDENCE:** The two checkpoint lines. E-xx: none. TISAX: 4.1.2.

### PR-3.3 Cross-check the organisation in one short sign-in

**WHO:** Platform owner. No witness.

**WHERE:** Shell with `~/.platform-env` sourced; Chrome profile `daily` for the sign-in page.

**ACTION:** This is the first use of the sitting rules of §6 (PR-3.1 and PR-3.2 must be
`DONE`).

```bash
need GCLOUD_CONFIG_NAME ORG_ID DIRECTORY_CUSTOMER_ID OWNER_DAILY_ACCOUNT
penv_guard && echo "guard clean"
gcloud auth login "$OWNER_DAILY_ACCOUNT" --no-launch-browser
R="$BUILD_LOG_DIR/records/$(date -u +%Y-%m-%d)-PR-3.3-organizations-v1.json"
gcloud organizations list --format=json > "$R"
jq -r 'length' "$R"
jq -r --arg o "organizations/$ORG_ID" '[.[] | select(.name == $o)] | length' "$R"
jq -r --arg o "organizations/$ORG_ID" '.[] | select(.name == $o) | (.owner.directoryCustomerId // .directoryCustomerId)' "$R"
sitting_end
```

`gcloud organizations list` is a read; Google documents it as listing "all organizations to which
the active account has access". `jq` handles both the v1 (`owner.directoryCustomerId`) and v3
(`directoryCustomerId`) field forms.

**VERIFY:** read the three `jq` outputs in order. They separate three failure modes that all
produce the same empty screen if they are collapsed into one filter:

| Output | Means | What to do |
|---|---|---|
| First `jq` prints `0` | No organisation is **visible to this account**. This is a permission symptom, not proof that the organisation is unbound. Google assigns Organization Administrator only to the super administrator who created the organisation resource, and recommends delegating it away; the default domain-wide Project Creator grant that also supplies `resourcemanager.organizations.get` is routinely removed for hygiene | Do not conclude anything about the binding. Have an account that holds `roles/resourcemanager.organizationAdmin` (or the organisation-level Project Creator grant) run the read, or read the Organization ID and customer id from the consoles as in PR-2.6 and record that the API half could not be run. Note that P-26's organisation roles go to `sa-1-admin@`, which [06-organisation-bootstrap-and-roster.md](06-organisation-bootstrap-and-roster.md) creates **after** this step, so `sa-1-admin@` cannot be used here |
| First prints a number, second prints `0` | The account sees organisations, but not `organizations/$ORG_ID` | Re-read the Organization ID (PR-2.6). If it is right, the account has access to a different organisation: stop and record |
| Second prints `1`, third prints a value ≠ `DIRECTORY_CUSTOMER_ID` | The Workspace customer and the Cloud organisation are **not bound** | Stop. 06, 14 and 24 cannot work as designed. Record it and open a decision in 03 |
| Second prints `1`, third prints exactly `DIRECTORY_CUSTOMER_ID` | P-03 is closed | Continue |

`sitting_end` prints `SITTING-END OK`.

**ROLLBACK:** None needed; a read. Nothing was changed, so nothing is undone. The action on
failure is in the VERIFY table above: an empty list is a missing-permission finding, a differing
customer id is an unbound-organisation finding, and the two are never recorded as the same thing.

**EVIDENCE:** `<date>-PR-3.3-organizations-v1` in the build log. E-xx: E-05. TISAX: 1.3.1.

## 7. Build log, evidence and registers

### 7.1 Where evidence goes (SD-38, pending signature in 03)

| Kind of record | Home during the build | Copied to | When |
|---|---|---|---|
| Checkpoint lines, command outputs, exports, text records | Build-log repository `BUILD_LOG_DIR` under `records/`, named by record id. **Local only today** — see the residual risk below | Platform evidence bucket `records/` prefix | After 14 creates it |
| Scans, signed documents, screenshots | `EVIDENCE_INTERIM_LOCATION` (a restricted shared drive), same day, PDF | Platform evidence bucket | After 14 |
| Custody, rota and drill records | Paper in the safe plus a same-day scan in `EVIDENCE_INTERIM_LOCATION` (SD-27) | Witness bucket `custody/`, `rota/`, `drills/` | Uploaded by the witness administrators at W-2 (08); direct to the witness after that |
| Decision records | Platform repository `decisions/<date>-<name>.md`, append-only | Evidence bucket | After 14 |
| The three registers and the re-run index | `BUILD_LOG_DIR/registers/` and `BUILD_LOG_DIR/rerun-index.tsv` | Consolidated by 42 | Standing |

**Residual risk: the build log has no remote.** `03-decisions-and-people.md` §12 (DC-9.2 to
DC-9.6) creates **one** repository on the git host — the platform repository — sets one remote
variable, `PLATFORM_REPO_REMOTE`, and protects one branch. No step in the set creates a build-log
repository, a `BUILD_LOG_REMOTE` variable, or force-push and deletion protection on it. So from
PR-2.1 until that gap is closed, every checkpoint line, register, re-run line and evidence record
lives on one laptop — the laptop of the administrator Eve exists to monitor — with no off-machine
copy and no protection against a rewrite of history. That defeats the anti-silencing intent of
the set, and it is recorded here rather than papered over.

Until it is closed:

- 03 must add a step (proposed id **DC-9.11**) that creates the build-log repository (private,
  wiki disabled), grants write to the same named humans as DC-9.3, sets `allow_force_pushes:false`
  and `allow_deletions:false` on `main` through `gh api -X PUT repos/<build-log>/branches/main/protection`,
  runs `penv_set BUILD_LOG_REMOTE`, pushes, and adds the repository to 03 §14's handover table.
  §12 below carries this as a requirement on 03, and README's open-items list carries it until a
  dated revision of 03 lands.
- Interim control, owned by the platform owner, from the day PR-4.4 exists: at the end of every
  sitting, `git -C "$BUILD_LOG_DIR" bundle create` a bundle of `main` and upload it to
  `EVIDENCE_INTERIM_LOCATION`, where the second human is Manager and the platform owner is only
  Contributor and so cannot delete it. One bundle per sitting, named
  `<date>-build-log-bundle-v<n>`. This is a copy, not protection: a rewritten local history still
  produces a valid bundle, and only the second human comparing two bundles would see it. State
  that limit when the control is cited.
- The gap is a `DEV` row in `DEVIATION_REGISTER`, opened by the first step of
  `02-toil-baseline.md` that writes to the build log, with 03 named as the closing file.

**Record naming.** `<date>-<step-id>-<record>-v<n>`: UTC date `YYYY-MM-DD`, the step id, a
lower-case hyphenated slug, and a version starting at 1. A record is never overwritten; a
correction is `v<n+1>` with the reason in its first line. The SHA-256 of every file is written
in `EVIDENCE_REGISTER`, so a changed copy is detectable wherever it lives.

**What is never evidence.** A green offline self-test (S177); a console screenshot without a
date; a statement that a step was done; anything holding a secret.

### 7.2 Mapping build records to E-xx and TISAX ids

| Build record | E-xx ([../10-eu-ai-act.md](../10-eu-ai-act.md) §5) | TISAX control ([../11-tisax.md](../11-tisax.md) §5, §13) |
|---|---|---|
| Decision records, deviation records, the bootstrap deviation register | E-03; E-05 for the register | 1.4.1; 5.2.1 |
| People records, roles table, pair checks, the ISMS exception | E-08 | 1.2.2 |
| Key enrolment, custody and envelope records | E-08 | 3.1.1-3.1.4; 4.1.2 |
| IAM, PAM, roster and access-array exports; access reviews | E-06 where it is audit data, otherwise none | 4.1.3; 4.2.1 |
| Drill records (K0-K7, break-glass, Eve independent proof, restore) | E-08 | 5.2.6; 5.2.9 for restore |
| Tabletop and incident records | E-10 | 1.6.2; 1.6.3 |
| Stage snapshot tag `compliance/<agent>/S<n>/<date>` and bundle (created by hand while CI does not exist, as a dated deviation) | E-05 | 5.2.1 |
| Logging, sink, retention and lock configuration | E-06 | 5.2.4 |
| Key and secret configuration | none | 5.1.1 |
| Branch protection, CODEOWNERS, CI results | E-15 for content tests, otherwise none | 5.3.1; 5.2.1 |
| DPO record, D7 letter, works council information | E-12 | 7.1.2 |
| Training and briefing | E-13 | 2.1.3 |
| Purchases, supplier file, model pin | E-11 | 6.1.1; 1.3.3 |
| Penetration test report | none | 5.2.6 |
| Sandbox tenant and nonprod folder records | none | 5.2.2 |
| Toil baseline and Mo artefacts | E-09 | 1.5.1 |

A row not listed takes the closest one and says so in its EVIDENCE line.

### PR-4.1 Create the bootstrap deviation register (SD-01 format)

**WHO:** Platform owner.

**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:**

```bash
need DEVIATION_REGISTER
cat > "$DEVIATION_REGISTER" <<'REGISTER'
# Bootstrap deviation register

Format fixed by setup/01 PR-4.1 under SD-01 (pending signature in 03). Append-only: a row is
closed by adding a line under "Closures", never by editing it. Ids are BD-<file>-<n>, allocated
by the file that opens the row, so parallel files never collide.

Kinds: EXC = dated standing exception; MOD = a factory module performed by hand;
DEV = any other dated deviation (for example SD-08's interim paging route, one-person PAM mode,
a stage tag made by hand while CI does not exist).

| Id | Opened (UTC date) | File and step | Kind | Module or exception | Scope (organisation, folder id, project id) | Inputs (register row, commit) | Produced (folder placement, labels, tags, APIs, policies, grants, budget, sinks, deny and PAB entries) | Zero-diff checker output (path, or BLOCKED and why) | Creator Owner removed (UTC date) | Approver (PAM grant id or signed record) | Expiry, or superseded by | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

## Closures

| Id | Closed (UTC date) | How (terraform import and empty plan: commit and plan output; withdrawal: step id) | Verified by (step id) |
|---|---|---|---|
REGISTER
git -C "$BUILD_LOG_DIR" add "$DEVIATION_REGISTER"
git -C "$BUILD_LOG_DIR" commit -m "registers: bootstrap deviation register skeleton"
checkpoint PR-4.1 DONE - "build-log:registers/bootstrap-deviation-register.md"
```

Every MOD row is superseded by `terraform import` and an empty plan when the factory exists,
and closed or re-dated at the Tier W gate at the latest. An EXC row carries its expiry date in
"Expiry"; the file that withdraws it adds the closure. `17-factory-module-equivalents-and-tier-r-gate.md`
reads this register at the Tier R gate; 42 reviews it.

**VERIFY:** `grep -c '^| Id |' "$DEVIATION_REGISTER"` prints `2`; the file is in the last commit.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD` while no row exists.

**EVIDENCE:** `<date>-PR-4.1-deviation-register-v1` (the commit). E-xx: E-05. TISAX: 5.2.1, 1.4.1.

### PR-4.2 Create the evidence register (the evidence index)

**WHO:** Platform owner.

**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:**

```bash
need EVIDENCE_REGISTER
cat > "$EVIDENCE_REGISTER" <<'REGISTER'
# Evidence register

The evidence index of the setup procedures. Format fixed by setup/01 PR-4.2 under SD-38
(pending signature in 03). One row per record, appended with evidence_add or by hand in the same
columns. Never edited: a copy made later is a new row with the same record id and the copy
columns filled.

Location forms: build-log:<path> | interim:<file name> | repo:<path>@<commit> | bucket:gs://<bucket>/<object> | witness:gs://<bucket>/<object> | paper:safe (with its interim scan as a second row)

| Record id | Date | Step | E-xx | TISAX | Location | SHA-256 | Recorded by | Copied to evidence bucket | Copied to witness |
|---|---|---|---|---|---|---|---|---|---|
REGISTER
git -C "$BUILD_LOG_DIR" add "$EVIDENCE_REGISTER"
git -C "$BUILD_LOG_DIR" commit -m "registers: evidence register skeleton"
evidence_add PR-1.1 workstation-tools E-05 5.3.1 "build-log:records/tools.txt" "$BUILD_LOG_DIR/records/tools.txt"
checkpoint PR-4.2 DONE - "build-log:registers/evidence-register.md"
```

**VERIFY:** `tail -n 1 "$EVIDENCE_REGISTER"` shows a row whose record id is
`<date>-PR-1.1-workstation-tools-v1` with a 64-character SHA-256.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD~1..HEAD` while it holds only this row.

**EVIDENCE:** The commit. E-xx: E-05. TISAX: 1.5.1.

### PR-4.3 Create the drill calendar

**WHO:** Platform owner.

**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** The rows below are opened (first due date set) by the file named; this skeleton lets
18, 28 and 37 schedule drills without waiting for 42.

```bash
need DRILL_CALENDAR
cat > "$DRILL_CALENDAR" <<'REGISTER'
# Drill calendar

Format fixed by setup/01 PR-4.3. The opening file sets "First due"; each drill appends its
record id to "Records" and sets "Next due". Records live in the witness from W-2 (08).

| Drill id | Drill | Cadence | Performed by | Witness | Opened by | First due | Records | Next due | Gate or limit it feeds |
|---|---|---|---|---|---|---|---|---|---|
| DR-06-1 | Break-glass envelope: open one, sign in, activate nothing, re-seal, alternate accounts | quarterly | custodian of the envelope | other administration line | 06 | *tbd* | | | 04 §7.1 |
| DR-18-1 | K7 fleet kill switch, dry run then enforced, per nonprod tier folder including fld-agents-p-sa-nonprod | *tbd* by 18; younger than 30 days at the grant | platform owner | second human for the enforced drill | 18 | *tbd* | | | G20 |
| DR-27-1 | Manual check of the witness heartbeat table until the absence alarms have seen data | daily | a witness administrator | — | 27 | *tbd* | | | SD-07 |
| DR-28-1 | Second human's independent proof of Eve on a seeded super-admin action | monthly (Assumption) and after every eve/config change | second human | a witness administrator records | 28 | *tbd* | | | G-4, G-6; SD-12 |
| DR-28-2 | Anti-silencing drill: a declared change by the platform owner is reported without his help | *tbd* by 28 | second human | a witness administrator | 28 | *tbd* | | | SD-12 |
| DR-28-3 | Witness push withheld once (G-2) | once before the grant, then *tbd* | production eve-export@ path, second human | witness administrators | 28 | *tbd* | | | G-2 |
| DR-37-1 | K6 drill on the twin | younger than 30 days at the grant | sandbox super admins | second human | 37 | *tbd* | | | G11 |
| DR-37-2 | Restore drill | *tbd* by 37 | platform owner | *tbd* | 37 | *tbd* | | | Tier W, G19 |
| DR-38-1 | Crisis-scenario tabletop | quarterly after the first | incident commander | security reviewer | 38 | *tbd* | | | G17 |
REGISTER
git -C "$BUILD_LOG_DIR" add "$DRILL_CALENDAR"
git -C "$BUILD_LOG_DIR" commit -m "registers: drill calendar skeleton"
checkpoint PR-4.3 DONE - "build-log:registers/drill-calendar.md"
```

**VERIFY:** `grep -c '^| DR-' "$DRILL_CALENDAR"` prints `9`.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD` before any file opens a row.

**EVIDENCE:** The commit. E-xx: E-08. TISAX: 5.2.6.

### PR-4.4 The interim evidence location

**WHO:** Second human creates and manages it. The platform owner is added as Contributor and
does nothing else here.

**WHERE:** Google Drive (drive.google.com) signed in as the second human → Shared drives → New.
Then the new shared drive → its name menu → Manage members.

**ACTION:**

1. Create a shared drive named `agentic-platform-evidence-interim`.
2. Manage members: the second human as Manager; `OWNER_DAILY_ACCOUNT` as **Contributor**
   (Contributors can add and edit files but cannot move files to the trash or delete them); no
   one else until `platform-security@` exists (06), which is then added as Manager by the second
   human.
3. In the shared drive's settings, turn off access for people outside the organisation and for
   non-members.
4. Copy the shared drive id from the address bar (`https://drive.google.com/drive/folders/<id>`)
   and send it to the platform owner.
5. The platform owner records it:

```bash
penv_set EVIDENCE_INTERIM_LOCATION "<shared drive id>"
checkpoint PR-4.4 DONE "$SECOND_HUMAN_EMAIL" - "interim evidence location created by the second human"
```

If `SECOND_HUMAN_EMAIL` is not set yet (03), write the witness field as the second human's
name.

**VERIFY:** The platform owner uploads a one-line test PDF into the drive, then right-clicks
it: "Move to trash" is absent or refused. The second human opens Manage members and confirms
two members. The residual risk is stated: a super admin can change shared-drive membership
through the Admin console; that action is in the Drive and Admin audit logs, which Eve-H reads
from 25, and every file's SHA-256 is in `EVIDENCE_REGISTER`.

**ROLLBACK:** The second human deletes the shared drive while it is empty.

**EVIDENCE:** `<date>-PR-4.4-interim-location-members-v1`: a dated screenshot of Manage members,
in the drive itself and registered with `evidence_add`. E-xx: E-08. TISAX: 5.2.4, 3.1.1-3.1.4.

## 8. Change conventions

### 8.1 Access-array edits (S160)

Prefer a binding command (`gcloud … add-iam-policy-binding`, `remove-iam-policy-binding`), which
reads and writes with the policy etag. When a whole policy or a BigQuery dataset `access` array
must be written, follow this pattern exactly. Each edit uses its own `mktemp -d` directory, never
a fixed path.

IAM allow policy (the server refuses a stale etag with `409 Conflict`):

```bash
need EVE_PROJECT
W="$(mktemp -d)"
gcloud projects get-iam-policy "$EVE_PROJECT" --format=json > "$W/before.json"
jq '<the edit, keeping .etag unchanged>' "$W/before.json" > "$W/after.json"
diff <(jq -S '.bindings' "$W/before.json") <(jq -S '.bindings' "$W/after.json")
gcloud projects set-iam-policy "$EVE_PROJECT" "$W/after.json" --format=json > "$W/applied.json"
diff <(jq -S '.bindings' "$W/after.json") <(gcloud projects get-iam-policy "$EVE_PROJECT" --format=json | jq -S '.bindings') && echo "POLICY MATCHES"
```

BigQuery dataset access (bq exposes no etag precondition, so the etag is compared immediately
before the write, and the array is read back and compared):

```bash
need EVE_PROJECT EVE_DS
W="$(mktemp -d)"
bq --project_id="$EVE_PROJECT" show --format=prettyjson "${EVE_PROJECT}:${EVE_DS}" > "$W/before.json"
jq --argjson add '[{"role":"READER","userByEmail":"<service account email>"}]' '.access = ((.access + $add) | unique)' "$W/before.json" > "$W/after.json"
jq -S '.access | sort_by(tostring)' "$W/after.json" > "$W/expected.json"
[ "$(bq --project_id="$EVE_PROJECT" show --format=prettyjson "${EVE_PROJECT}:${EVE_DS}" | jq -r .etag)" = "$(jq -r .etag "$W/before.json")" ] && bq --project_id="$EVE_PROJECT" update --source "$W/after.json" "${EVE_PROJECT}:${EVE_DS}" || echo "STOP: the dataset changed since it was read, or the update failed"
bq --project_id="$EVE_PROJECT" show --format=prettyjson "${EVE_PROJECT}:${EVE_DS}" | jq -S '.access | sort_by(tostring)' | diff "$W/expected.json" - && echo "ACCESS MATCHES"
```

`unique` removes a duplicate when a step is re-run. Any `diff` output after the write is a stop:
read it, because BigQuery may normalise an entry, and record the normalised form. The policy
files are not secrets; the directory is removed with `rm -rf "$W"` after the EVIDENCE line has
copied `before.json` and the read-back into the build log.

### 8.2 Secrets (S139)

```bash
need EVE_PROJECT REGION EVE_REFRESH_TOKEN_SECRET_NAME
<command that writes the secret to its standard output> | gcloud secrets versions add "$EVE_REFRESH_TOKEN_SECRET_NAME" --project="$EVE_PROJECT" --location="$REGION" --data-file=- --format='value(name)'
```

- The producing command is committed code (for example Eve's consent command, BLOCKED in 24).
  Its standard output is piped, never displayed. `set -o pipefail` (zsh: `setopt pipefail`) is
  set by `~/.platform-env`, so a failing producer fails the pipe.
- Only the printed version name is recorded, and pinned by number in the variable the plan names
  (for example `EVE_TOKEN_VERSION`).
- A file the browser downloads (an OAuth client JSON) is piped in from where it landed and deleted
  in the same line, then checked:

```bash
gcloud secrets versions add "$EVE_OAUTH_CLIENT_SECRET_NAME" --project="$EVE_PROJECT" --location="$REGION" --data-file=- < "$HOME/Downloads/<downloaded file>.json" && rm -f "$HOME/Downloads/<downloaded file>.json"
ls "$HOME/Downloads"/client_secret_*.json 2>/dev/null && echo "FAIL: a client file is left" || echo "no client file left"
```

- Never `cat`, `echo`, `less` or open such a file in an editor; never copy it; never use
  `shred` or `rm -P` (no effect on macOS).

### 8.3 Foreign principals (SD-44)

Every grant to a principal made by another file is written:

```bash
exists_or_pending "serviceAccount:${SA_MO_METRICS}" WD-4.2 "31 WD-4.2 walle_audit READER for mo-metrics@" && <the grant command>
```

EXISTS runs the grant; PENDING records the line in `rerun-index.tsv` and runs nothing; UNKNOWN
stops the step. The file that creates the principal lists the re-run in its "what the next
files need" section, and the re-run closes the PENDING line with a `DONE` line.

### 8.4 Pending decisions applied here

| Decision | Applied in this file as | If 03 records it refused |
|---|---|---|
| SD-01 bootstrap deviation from the factory | The register format of PR-4.1; every hand module run is a row | The register stays as a record; the files that perform hand module runs stop until 03 records the alternative |
| SD-37 which path to follow | §6.1 last row: setup/ is canonical; the script only after fixes; self-test not evidence | 30 to 39 keep the manual commands; nothing in 01 changes |
| SD-38 where evidence lives | §7.1, §7.2, PR-4.2, PR-4.4 | The second human's signature at PR-6.1 is withdrawn and the evidence homes are re-decided before 06 |

## 9. Pending decisions and the prerequisites snapshot

### PR-5.1 Record SD-01, SD-37 and SD-38 as applied pending

**WHO:** Platform owner.

**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:**

```bash
need BUILD_LOG_DIR
printf '%s\n' "# Decisions applied pending signature" "" "Date: $(date -u +%Y-%m-%d)" "" "- SD-01: bootstrap deviation register format (PR-4.1). Signature: 03." "- SD-37: setup/ procedures are the only execution path; walle_setup.py only after fixes; its self-test is not evidence. Signature: 03." "- SD-38: evidence homes and naming (section 7). Signature: 03, after the second human's review at PR-6.1." > "$BUILD_LOG_DIR/records/$(date -u +%Y-%m-%d)-PR-5.1-pending-decisions-v1.md"
git -C "$BUILD_LOG_DIR" add records
git -C "$BUILD_LOG_DIR" commit -m "PR-5.1 pending decisions applied"
checkpoint PR-5.1 DONE - "build-log:records/$(date -u +%Y-%m-%d)-PR-5.1-pending-decisions-v1.md"
```

**VERIFY:** The record is in the last commit; README's sign-off tracker shows SD-01, SD-37 and
SD-38 as pending.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD`.

**EVIDENCE:** `<date>-PR-5.1-pending-decisions-v1`, registered with `evidence_add`. E-xx: E-03.
TISAX: 1.4.1.

### PR-5.2 Snapshot the platform prerequisites

**WHO:** Platform owner.

**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** Write one line per row of §3.1 with its state today. Rows P-01 to P-03 are closed by
this file's steps and each names the step that closed it, so no row is written `closed` without
an evidence record behind it: P-01 by PR-1.1 to PR-1.3, P-02 by PR-2.6's Super Admin → View
admins read and its screenshot, P-03 by PR-3.3. The rest are open with the file that closes them.

```bash
need BUILD_LOG_DIR EVIDENCE_REGISTER
grep -q -- '-PR-2.6-super-admin-roster-v' "$EVIDENCE_REGISTER" || echo "STOP: P-02 is not proven. Register PR-2.6's Super Admin roster screenshot first, then re-run: evidence_add PR-2.6 super-admin-roster E-06 4.1.3 \"interim:<file name>.pdf\""
F="$BUILD_LOG_DIR/prerequisites-status.tsv"
printf 'date\tid\tstate\tclosed_by_file\tnote\n' > "$F"
while read -r id step; do printf '%s\t%s\tclosed\t01\t%s\n' "$(date -u +%Y-%m-%d)" "$id" "$step" >> "$F"; done <<'CLOSED'
P-01 PR-1.1,PR-1.2,PR-1.3
P-02 PR-2.6
P-03 PR-3.3
CLOSED
while read -r id file; do printf '%s\t%s\topen\t%s\t\n' "$(date -u +%Y-%m-%d)" "$id" "$file" >> "$F"; done <<'ROWS'
P-04 06
P-05 03
P-06 03
P-07 03
P-08 03
P-09 03
P-10 03
P-11 03
P-12 03
P-13 03
P-14 01
P-15 06
P-16 04
P-17 04
P-18 04
P-19 04
P-20 04
P-21 04
P-22 07
P-23 04
P-24 04
P-25 04
P-26 06
P-27 18
P-28 35
P-29 18
P-30 03
ROWS
git -C "$BUILD_LOG_DIR" add prerequisites-status.tsv
git -C "$BUILD_LOG_DIR" commit -m "PR-5.2 prerequisites snapshot"
checkpoint PR-5.2 DONE - "build-log:prerequisites-status.tsv"
```

P-14 closes at PR-4.4. Later files append a `closed` line for their rows;
the file is append-only.

**VERIFY:**

```bash
cut -f2 "$BUILD_LOG_DIR/prerequisites-status.tsv" | grep -c '^P-'
awk -F'\t' '$3=="closed"{print $2, $5}' "$BUILD_LOG_DIR/prerequisites-status.tsv"
```

Expected: `30`; then exactly three `closed` rows, `P-01 PR-1.1,PR-1.2,PR-1.3`, `P-02 PR-2.6` and
`P-03 PR-3.3`, each naming a step with a `DONE` line in `checkpoints.tsv` and, for P-02, a row in
`EVIDENCE_REGISTER`. No `STOP:` line was printed by the ACTION.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD`.

**EVIDENCE:** `<date>-PR-5.2-prerequisites-status-v1`. E-xx: E-05. TISAX: 1.5.1.

## 10. Review and close

### PR-6.1 The second human reviews the roles and signs the evidence convention

**WHO:** Second human. Asynchronous; the platform owner is not present.

**WHERE:** This page (§2 and §7), read in the wiki or its Drive copy; the interim evidence
location.

**ACTION:**

1. Read §2.1 to §2.3. For each pair, confirm that the design pages say what the table says, or
   write the correction.
2. Read §7.1 and §7.2. Confirm the evidence homes, the naming, and that the platform owner holds
   Contributor only on the interim location.
3. Sign a one-page record, `<date>-PR-6.1-roles-and-evidence-review-v1`, with: the date, "roles
   table reviewed: agreed / corrections listed", "evidence convention SD-38: agreed / not
   agreed", the second human's name and signature. Upload it as PDF to
   `EVIDENCE_INTERIM_LOCATION`.
4. The platform owner registers it:

```bash
evidence_add PR-6.1 roles-and-evidence-review E-08 1.2.2 "interim:<file name>.pdf" "$HOME/Downloads/<file name>.pdf"
rm -f "$HOME/Downloads/<file name>.pdf"
checkpoint PR-6.1 DONE "${SECOND_HUMAN_EMAIL:-<second human name>}" "interim:<file name>.pdf"
```

`SECOND_HUMAN_EMAIL` is set by `03-decisions-and-people.md` DC-2.1, which runs **after** this
file. Until then, type the second human's name in place of `<second human name>`; do not leave
the variable to expand to nothing. `checkpoint` substitutes `-` for an empty third argument, so
an unset variable would silently record the one step in file 01 that a second person performs as
having had no witness, and PR-6.2's VERIFY would pass on that line. The same applies to PR-4.4.
03 backfills both witness fields with the real address once `SECOND_HUMAN_EMAIL` exists, by
appending a correcting line to `checkpoints.tsv` (the log is append-only; a line is never
edited).

**VERIFY:** The record exists in the interim location with the second human as its owner (file
details panel), and its SHA-256 in `EVIDENCE_REGISTER` matches the downloaded copy. Any
correction listed is applied to this page before 03 records SD-38.

**ROLLBACK:** A record is never withdrawn; a changed view is a `v2`.

**EVIDENCE:** `<date>-PR-6.1-roles-and-evidence-review-v1`. E-xx: E-08. TISAX: 1.2.2.

### PR-6.2 Close part 01

**WHO:** Platform owner.

**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:**

```bash
need PLATFORM_ENV_FILE BUILD_LOG_DIR EVIDENCE_REGISTER DEVIATION_REGISTER DRILL_CALENDAR EVIDENCE_INTERIM_LOCATION DOMAIN DIRECTORY_CUSTOMER_ID ORG_ID WORKSPACE_EDITION OWNER_DAILY_ACCOUNT
penv_guard && echo "guard clean"
awk -F'\t' '$3=="DONE"{print $2}' "$BUILD_LOG_DIR/checkpoints.tsv" | sort -u
awk -F'\t' '($2=="PR-4.4" || $2=="PR-6.1") && $3=="DONE" {print $2, $5}' "$BUILD_LOG_DIR/checkpoints.tsv"
grep -n '<[^>]*>' "$BUILD_LOG_DIR/checkpoints.tsv" && echo "FAIL: an unreplaced placeholder is in the log" || echo "no placeholder in the log"
git -C "$BUILD_LOG_DIR" status --short
sitting_end
checkpoint PR-6.2 DONE - - "part 01 complete"
```

**VERIFY:** `need` is silent; `guard clean`; the DONE list contains every step id from PR-1.1 to
PR-6.1 (PR-1.1 to PR-2.3 carry the backfilled lines of PR-2.4) with no id twice; the two
two-person steps PR-4.4 and PR-6.1 each print a witness field that is **not** `-` — a `-` there
means the witness was lost to an unset `SECOND_HUMAN_EMAIL` and the line must be corrected by an
appended line before 02 starts; `no placeholder in the log`; `git status` prints nothing;
`SITTING-END OK`.

**ROLLBACK:** None.

**EVIDENCE:** The final checkpoint commit. E-xx: E-05. TISAX: 5.2.1.

## 11. Verification checklist for part 01

- [ ] `tools.txt` records gcloud at 563.0.0 or later, bq, Python 3.12, jq, openssl, git, curl;
      FileVault on; working area outside synced folders.
- [ ] Browser profiles `daily` and `sa-1-admin` exist, `sa-1-admin` signed in to nothing.
- [ ] `PLATFORM_REPO_DIR` and `BUILD_LOG_DIR` are git repositories; the template is committed.
- [ ] `~/.platform-env` is mode 600, installed from the template, sourced by hand only.
- [ ] `need PLATFORM_ENV_FILE GCLOUD_CONFIG_NAME PLATFORM_REPO_DIR BUILD_LOG_DIR WIKI_DIR REGION BQ_LOCATION GE_LOCATION MODEL_LOCATION DEVIATION_REGISTER EVIDENCE_REGISTER DRILL_CALENDAR EVIDENCE_INTERIM_LOCATION DOMAIN DIRECTORY_CUSTOMER_ID ORG_ID WORKSPACE_EDITION OWNER_DAILY_ACCOUNT` is silent.
- [ ] The helper check passed in bash and zsh, and is recorded as a check, not as evidence.
- [ ] `penv_guard` is clean: no gcloud project, no `CLOUDSDK_CORE_PROJECT`, no `PROJECT`, no
      bq default project.
- [ ] `gcloud auth list` shows no account; no ADC file; no Wall-E operator token cache.
- [ ] The organisation's directory customer id equals `DIRECTORY_CUSTOMER_ID`.
- [ ] `checkpoints.tsv`, `rerun-index.tsv`, `variables-changes.tsv`, `prerequisites-status.tsv`
      and the three registers exist and are committed; PR-2.4 re-run twice leaves them unchanged,
      and no step id is backfilled twice.
- [ ] The last two `SITTING-` lines in `checkpoints.tsv` carry the same id, `START` then `DONE`.
- [ ] No `<placeholder>` string appears anywhere in `checkpoints.tsv`; the PR-4.4 and PR-6.1 lines
      carry a real witness, not `-`.
- [ ] P-02 is closed by PR-2.6's Super Admin → View admins read, and its screenshot has a row in
      `EVIDENCE_REGISTER`.
- [ ] The build log's lack of a remote is recorded as a residual risk (§7.1), with the sitting
      bundle in `EVIDENCE_INTERIM_LOCATION` as the interim copy and 03 named as the closing file.
- [ ] The interim evidence location has exactly the second human (Manager) and the platform owner
      (Contributor).
- [ ] The second human's review record is registered.
- [ ] No retired variables file (`~/.walle-env`, `~/.eve-env`, `~/.mo-env`) is in use.

## 12. What the next files need from this one

| File | Needs |
|---|---|
| `02-toil-baseline.md` | `PLATFORM_REPO_DIR` (local repository), `BUILD_LOG_DIR`, `EVIDENCE_INTERIM_LOCATION`, `EVIDENCE_REGISTER`, `checkpoint` |
| `03-decisions-and-people.md` | The roles table and pairs (§2) to name people against; the four-human exception question (§2.3); SD-01, SD-37, SD-38 as pending with the PR-6.1 review; the platform repository, for which DC-9.2 to DC-9.6 create the remote. **Two gaps 03 must close**, both recorded here: (1) the build-log repository has no remote — 03 needs a step (proposed DC-9.11) creating it with `allow_force_pushes:false`, `allow_deletions:false`, `penv_set BUILD_LOG_REMOTE` and a §14 row (§7.1 residual risk); (2) once DC-2.1 sets `SECOND_HUMAN_EMAIL`, 03 backfills the witness field of the PR-4.4 and PR-6.1 checkpoint lines, which were written with the second human's name because the variable did not exist yet, by appending a correcting line |
| `04-purchases-and-lead-times.md` | §3.1 rows P-16 to P-25 and the key count of §3.2 |
| `05-gemini-enterprise-inventory.md` | `DOMAIN`, `ORG_ID`, `GE_LOCATION`, the sitting rules |
| `06-organisation-bootstrap-and-roster.md` | `DOMAIN`, `ORG_ID`, `DIRECTORY_CUSTOMER_ID`, `OWNER_DAILY_ACCOUNT`, `EVIDENCE_INTERIM_LOCATION` (custody scans), `DEVIATION_REGISTER` (the EXC row), `DRILL_CALENDAR` (DR-06-1), the browser profile `sa-1-admin`, the domain-wide delegation rule; it adds `platform-security@` to the interim location |
| `07-billing-account.md` and every later file | The step format, the helpers, the sitting blocks of PR-3.2, the patterns of §8, the naming and mapping of §7 |
| `17-factory-module-equivalents-and-tier-r-gate.md` | `DEVIATION_REGISTER` format |
| `18-…`, `28-…`, `37-…` | `DRILL_CALENDAR` rows DR-18-1, DR-28-1 to DR-28-3, DR-37-1, DR-37-2 |
| `24-…` and `37-…` (twin work) | `twin_shell` and `twin_shell --sandbox-org`; 37 defines twin names for Wall-E's token versions if the twin needs them, since `twin_shell` blanks the production ones |
| `30-wall-e-workspace-side.md` | `walle_shell` and the SD-37 rule |
| `42-gates-drills-and-evidence.md` | The three registers, `rerun-index.tsv`, `prerequisites-status.tsv` |

## 13. Findings closed and deferred

| Finding | What this page does |
|---|---|
| S066 | Declares README the only entry point and this page's replacement scope (Status, §6.1 last row); README closes the build order |
| S067 | Evidence homes, interim location, naming, register and the E-xx and TISAX mapping (§7, PR-4.2, PR-4.4) |
| S069 | WHO field with witness and approver in every step (§1); roles table with pairs (§2); README carries the per-sitting table |
| S071 | Dedicated configuration without a project, `--project` everywhere, guard, no `gcloud config set project` (§6.1, PR-3.1) |
| S082 | One execution path per step; the script only after fixes (§6.1, §8.4) |
| S083 | Platform prerequisites with verify, holder and lead time (§3.1); corrected key count (§3.2); 04 closes the purchase half |
| S087 | No admin token between sittings; operator token cache forbidden and checked (§6.1, `sitting_end`) |
| S139 | Secrets piped with `--data-file=-`; no `shred`; downloaded files deleted at once and checked (§8.2) |
| S160 | Access-array pattern with `mktemp`, etag, read-back and diff (§8.1) |
| S165 | One variables file from one committed template; retired files checked (PR-2.3) |
| S177 | Helper check and the script's self-test declared not evidence (PR-2.5, §6.1, §7.1) |
| S178 | No source-time warning on empty values; `need` per step; values written to the file, so re-sourcing never wipes them |
| X-RQB-02 | Regional availability and quota rows with verify commands and the correct Model Armor consumers (P-27 to P-29) |

Second-round findings closed on 2026-09-16:

| Finding | What this page now does |
|---|---|
| P-26 missed `roles/iam.securityAdmin` | P-26 lists all five organisation roles and the folder and project analogues; §3.3 gates on a binding read plus a permission probe taken from Google's own role definition, so the gate cannot pass without Security Admin |
| PR-2.4 truncated the logs on a resumed run | Every creation is guarded by `[ -s … ] ||`, the backfill loop and the closing checkpoint are guarded on an existing `DONE` line, and the VERIFY asks for a second run with identical output |
| PR-3.2's sitting id computed twice | `SITTING_ID` is computed once and exported; the VERIFY asserts two lines with the same id; the literal placeholders are replaced and `checkpoint` now refuses any `<placeholder>` |
| `penv_guard` passed vacuously on a hidden `gcloud` failure | The exit status is checked separately, with "configuration does not exist yet" told apart from "gcloud failed"; the `(unset)` case is marked as an assumption |
| PR-5.2 wrote P-02 `closed` with no evidence | PR-2.6 performs the Super Admin → View admins read and its screenshot; PR-5.2 refuses to write the snapshot without a register row and records the closing step for each closed row |
| The build log's remote does not exist in 03 | §7.1 states the residual risk, names the interim bundle control and its limit, and §12 carries the requirement on 03 (proposed DC-9.11) |
| PR-6.1's witness lost to an unset variable | The fallback is written at the step, `checkpoint` refuses placeholders, PR-6.2's VERIFY asserts a non-`-` witness on PR-4.4 and PR-6.1, and §12 asks 03 to backfill |
| PR-3.3 misdiagnosed three failure modes as one | The ACTION prints three separate `jq` results and the VERIFY table separates "not visible to this account" from "not in the list" from "customer ids differ" |
| `sitting_end` checked a path that can never exist | The `CLOUDSDK_CONFIG` guard runs first, before any revoke, and PR-2.5 proves it |
| PR-2.3 silently accepted a stale `~/.platform-env` | The branch is explicit and loud, and the VERIFY diffs the installed helper block against the committed template |
| `SA_1_ADMIN` and `_PENV_MAPPED` dangled | The profile table names `sa-1-admin@$DOMAIN` and says 06 sets the variable; `_PENV_MAPPED` is deleted, leaving one list in `_penv_apply_mode` |
| §3.2's key total disagreed with 04 | §3.2 gives the order figure 22 (26 with twin-robot keys), spares fixed at four, with 04 §4 named as the single source |
| EVIDENCE fields without an E-xx across the set | §1 adds the mechanical check and names the files the review found broken; this page's twenty steps all carry both ids |

Deferred: the sweep of the EVIDENCE fields of 02, 05, 07, 10, 13, 17 and 42 is the work of those
files' owners, not of this page; this page supplies the rule, the mapping table (§7.2) and the
check that finds every hit. Owner: each file's owner, before 42's first quarterly review.

## 14. Sources checked on 2026-09-15, and on 2026-09-16 where noted

- gcloud configurations, `CLOUDSDK_ACTIVE_CONFIG_NAME`, `CLOUDSDK_CONFIG`, `gcloud config unset`:
  https://docs.cloud.google.com/sdk/docs/configurations
- `gcloud config configurations create --no-activate`:
  https://docs.cloud.google.com/sdk/gcloud/reference/config/configurations/create
- `gcloud config get`: https://docs.cloud.google.com/sdk/gcloud/reference/config/get
- Environment variables take precedence over properties:
  https://docs.cloud.google.com/sdk/docs/properties
- Release notes (584.0.0 on 2026-09-09): https://docs.cloud.google.com/sdk/docs/release-notes
- `gcloud auth login --no-launch-browser`: https://docs.cloud.google.com/sdk/gcloud/reference/auth/login
- `gcloud auth revoke --all`: https://docs.cloud.google.com/sdk/gcloud/reference/auth/revoke
- `gcloud auth application-default revoke`:
  https://docs.cloud.google.com/sdk/gcloud/reference/auth/application-default/revoke
- `gcloud auth list`: https://docs.cloud.google.com/sdk/gcloud/reference/auth/list
- `gcloud secrets versions add --data-file=-`, `--location`:
  https://docs.cloud.google.com/sdk/gcloud/reference/secrets/versions/add
- `gcloud iam service-accounts describe`:
  https://docs.cloud.google.com/sdk/gcloud/reference/iam/service-accounts/describe
- `gcloud identity groups describe`:
  https://docs.cloud.google.com/sdk/gcloud/reference/identity/groups/describe
- `gcloud organizations describe` and the Organization resource (`owner.directoryCustomerId`):
  https://docs.cloud.google.com/sdk/gcloud/reference/organizations/describe,
  https://docs.cloud.google.com/resource-manager/reference/rest/v1/organizations
- Organization ID in the Cloud console and `gcloud organizations list`:
  https://docs.cloud.google.com/resource-manager/docs/creating-managing-organization
- `gcloud beta quotas info list`: https://docs.cloud.google.com/sdk/gcloud/reference/beta/quotas/info/list
- Model Armor quotas (updated 2026-09-14): https://docs.cloud.google.com/model-armor/quotas
- IAM policy etag and `409 Conflict`: https://docs.cloud.google.com/iam/docs/policies
- BigQuery dataset access with `bq show` and `bq update --source` (access array overwritten):
  https://docs.cloud.google.com/bigquery/docs/control-access-to-resources-iam
- bq `--project_id` and `.bigqueryrc`: https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference
- PAM Admin role and entitlement creation: https://docs.cloud.google.com/iam/docs/pam-permissions-and-setup
  — re-read 2026-09-16. To work with entitlements at the organisation level a principal needs
  **both** `roles/privilegedaccessmanager.admin` and `roles/iam.securityAdmin`; at folder level
  `roles/resourcemanager.folderAdmin`; at project level `roles/resourcemanager.projectIamAdmin`.
  The supporting role is what supplies get and set of the IAM policy on the parent resource.
  Requesters and approvers of grants need no PAM-specific permission (P-26, §3.3)
- `gcloud organizations list` — read 2026-09-16: it "lists all organizations to which the active
  account has access", in an unspecified order, and the list may be incomplete for a service
  account. An empty list is therefore a permission symptom, never proof that an organisation does
  not exist or is unbound (PR-3.3):
  https://docs.cloud.google.com/sdk/gcloud/reference/organizations/list
- Organization Administrator is assigned by default only to the super administrator who created
  the organisation resource, and Google recommends delegating it away — read 2026-09-16 (PR-3.3):
  https://docs.cloud.google.com/resource-manager/docs/creating-managing-organization
- `gcloud organizations get-iam-policy`, used by §3.3's binding read:
  https://docs.cloud.google.com/sdk/gcloud/reference/organizations/get-iam-policy
- `gcloud iam roles describe`, used by §3.3 to read Google's own definition of
  `roles/iam.securityAdmin` rather than asserting its contents here:
  https://docs.cloud.google.com/sdk/gcloud/reference/iam/roles/describe. The per-role permission
  index pages did not render for automated reading on 2026-09-16, which is why §3.3 reads the
  role on the day instead of naming a permission from memory
- `gcloud config get`: the behaviour when a property is unset is not documented on
  https://docs.cloud.google.com/sdk/gcloud/reference/config/get (re-read 2026-09-16), so
  `penv_guard`'s `(unset)` case is written as an assumption and the exit status is checked
  separately
- Customer ID path: https://knowledge.workspace.google.com/admin/getting-started/find-your-customer-id
- Edition path: https://knowledge.workspace.google.com/admin/billing/which-edition-and-payment-plan-do-i-have
- Domain-wide delegation path, super admin only:
  https://knowledge.workspace.google.com/admin/apps/control-api-access-with-domain-wide-delegation
- Shared drive access levels (Contributor cannot trash or delete):
  https://support.google.com/a/users/answer/12380484
- Agent Runtime quotas and agent locations: taken from the review's second-round evidence for
  X-RQB-02, verified by both lenses on 2026-09-15; the pages did not render for automated reading
  when this page was written, so P-27 and P-28 re-read them on the day.

## Related

- [README.md](README.md): order, BLOCKED index, re-run index, sign-off tracker.
- [../13-setup-procedure-review.md](../13-setup-procedure-review.md): the review this set answers.
- [../01-hld.md](../01-hld.md) §0.3; [../11-tisax.md](../11-tisax.md) §7 and §13;
  [../10-eu-ai-act.md](../10-eu-ai-act.md) §5;
  [../04-identity-and-privileged-access.md](../04-identity-and-privileged-access.md) §7.1, §8.3;
  [../../project-topology.md](../../project-topology.md).
