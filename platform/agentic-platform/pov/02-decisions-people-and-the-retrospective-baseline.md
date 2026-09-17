# POV 02. Day one: the decision records, the people, the purchases, and the toil baseline taken backwards

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-17
- Last executed: never
- Stage: POV-1, day one to the end of week 2. It starts the day [01](01-conventions-and-variables.md) Part A is `DONE`; 01 Part B (the git host) runs after this file has signed PV-03 and PV-09 and appointed persons 2 and 3 (PD-6.1), and before 03.
- Step prefix: `PD`. Steps: 27. BLOCKED steps: one, PD-4.3 (the PV-01 supersession that carries the doer's scope hash, operation catalogue and K4 line), which waits on PB-04's proof of one operation and its inverse and on PB-05's committed scope file ([07](07-the-doer-tier-w-and-the-optional-tier-p.md)) and runs in POV-2, before 07 PW-3.1. Every other item here is a letter, a signature, a purchase request, a query or a time-boxed role assignment; no service code is needed.
- Full-set counterparts: [setup/02 toil baseline](../setup/02-toil-baseline.md), [setup/03 decisions and people](../setup/03-decisions-and-people.md), [setup/04 purchases and lead times](../setup/04-purchases-and-lead-times.md).
- POV deviations used here (full text in [09](09-the-demonstration-deviations-and-the-hand-over.md)): PV-D-01, PV-D-02, PV-D-03, PV-D-04, PV-D-05, PV-D-06, PV-D-07, PV-D-08, PV-D-09, PV-D-10, PV-D-11, PV-D-12, PV-D-14, PV-D-15, PV-D-16.
- The prefix is `PD`, never `PS`, because setup/15 owns `PS` in the same `checkpoints.tsv` ([README](README.md) §6.2).

## What this part builds

1. **The thirteen POV decision records, PV-01 to PV-13**, in the record format of [setup/03](../setup/03-decisions-and-people.md) §4 (DC-1.1 to DC-1.4): headings Context, Options considered, Decision, Values, Gates, Consequences, Signatures; append-only; parsed by `tools/decision-check.sh`; read by `tools/decision-need.sh` and `tools/decision-value.sh`. No new tool, no new format.
2. **Full-set decisions carried in the same records under their full-set ids.** Where a POV record settles a question the full build also asks (NAMES, KEYS, SD-11, P13, WDEC-6, D12 and others, §1.2), the record lists both ids in its `Decision ids` line. The full build's `decision-need.sh NAMES` then prints `SIGNED` against the POV's record and continues from it. This is how a decision taken for the POV scales: it is never taken twice.
3. **The people**: the full set's appointment records (PPL-SH, PPL-SO, PPL-SR, PPL-BG, PPL-IC, PPL-BA) with their full-set ids and variables, plus the POV-only engineer appointment (PPL-ENG) that the code's calendar depends on, the separations, the three days on which person 3 becomes mandatory, and the fallback approver.
4. **The day-one letters** to the DPO and the works-council or HR contact, and the day-one purchases, including the hardware-key wait.
5. **The toil baseline, taken backwards**: six months of Admin log event volume by event type, per-task handling medians from a timed calibration sample, written into [setup/02](../setup/02-toil-baseline.md)'s nine-column CSV contract unchanged, so that the full build's `bq load` (setup/22 §8) and Mo's value report read it without change. This is a deliberate adaptation, **PV-D-05**: the full build still owes the four prospective weeks before any promotion claims time saved.

What this file does **not** do: create any Google Cloud or Workspace resource. The only Google actions are reading Admin log events and reading documentation pages.

## Preconditions

- [ ] [01](01-conventions-and-variables.md) Part A `DONE`: `~/.platform-env` (`PLATFORM_ENV_FILE`) with the helpers `penv_set`, `need`, `penv_guard`, `checkpoint`, `evidence_add`, `confirm_manual`; `PLATFORM_REPO_DIR` holding `decisions/_template.md`, `decisions/TRACKER.md` and the three decision tools of setup/03 DC-1.1 to DC-1.3; `BUILD_LOG_DIR`, `EVIDENCE_REGISTER`, `EVIDENCE_INTERIM_LOCATION`, `PLATFORM_REPO_REMOTE`. Check:

```bash
source "$HOME/.platform-env"
need PLATFORM_REPO_DIR BUILD_LOG_DIR EVIDENCE_REGISTER EVIDENCE_INTERIM_LOCATION && echo "01 values OK"
penv_guard && echo "no default project"
ls "$PLATFORM_REPO_DIR"/tools/decision-check.sh "$PLATFORM_REPO_DIR"/tools/decision-need.sh "$PLATFORM_REPO_DIR"/tools/decision-value.sh "$PLATFORM_REPO_DIR"/decisions/_template.md "$PLATFORM_REPO_DIR"/decisions/TRACKER.md
git -C "$PLATFORM_REPO_DIR" status --porcelain
```

  Expect `01 values OK`, `no default project`, five paths and an empty status. `PLATFORM_REPO_REMOTE` comes from 01 Part B and is needed only by PD-8.6; every other step runs without it. Until 01 Part B pushes, records are committed locally, each commit with its `reviews/<sha>.md` record or inside `BD-P01-1`'s exempt list (01 PP-4.1).
- [ ] The platform owner holds a Workspace account with the Audit & Investigation privilege (PD-8.2). A super admin has it. On day one this is the account in hand; [03](03-foundation-folders-logging-and-floors.md) later moves administration to `sa-1-admin@`, and the build log notes which account read the logs.
- [ ] Workstation: `git`, `bash`, `awk`, `shasum`, `python3` (3.12, as setup/01).
- [ ] Nothing here runs `gcloud` against a resource; `penv_guard` is still run because the variables file is sourced.

## People

Roles, never names. The full-set role ids in the third column are the ids used in the `Required signatories` line of every record.

| POV role | Holds | Full-set role ids | In this file |
|---|---|---|---|
| Person 1, the platform owner and operator | drafts every record, sends the letters, runs PD-8.1 to PD-8.5 | PO, MOO (Mo owner by default, recorded in PD-6.1) | every step except the task choice and automation list of PD-8.2 and the recount of PD-8.6 |
| Person 2, the second person (IT security) | future `sa-2-admin@`, owner of `eve-owners@` | SH | signs PV-01 to PV-05, PV-07 to PV-10, PV-13; reviewer of commits alongside person 3; with person 3, may choose PD-8.2's kept tasks and write its automation list; by default recounts the baseline in PD-8.6 from `sa-2-admin@`; assigns and unassigns PD-8.7's role if it is used |
| Person 3, appointed in PD-6.1 before 01 Part B | second operator, blind grader, part-time security reviewer, evidence verifier | SO, BG, SR | signs PV-05's baseline record, PV-07 and PD-4.3's PV-01 supersession as SR; with person 2, may choose PD-8.2's kept tasks and write its automation list; signs the independent check of the baseline (PD-8.6) |
| ISMS | names the people, signs scope and separations | ISMS | PD-4.1, PD-4.3, PD-5.5, PD-6.1, PD-6.2, PD-8.7 |
| DPO | receives the letter, signs data protection | DPO | PD-2.1, PD-5.1 to PD-5.4, PD-7.1, PD-8.0, PD-8.3, PD-8.7 |
| HR or works-council contact | answers the works-council question | HR | PD-2.1, PD-5.1 to PD-5.3, PD-8.0, PD-8.3 |
| AI compliance owner or legal's designate | classification and purpose | AIC | PD-5.4 |
| IT security lead or named delegate | security rows until SR ratifies | ITSEC | PD-3.3, PD-4.2, PD-6.2, PD-7.1 |
| Incident commander (IT security) | severity-1 recipient; interim recipient of reports about person 2 | IC | PD-6.1, PD-6.2 |
| Finance and the billing administrator | the dedicated EUR billing account | FIN, BA | PD-2.3, PD-6.1 |

Signatures are collected by mail from each signatory's own account (setup/03 DC-1.4). No step of this file is a sitting.

## 1. How a POV record is made

### 1.1 Format and signing: setup/03, unchanged

Every record is drafted, hashed, signed and committed exactly as [setup/03](../setup/03-decisions-and-people.md) DC-1.4 says: one reply per signatory from their own account quoting the file name, the body SHA-256 and the role id; each reply saved to `EVIDENCE_INTERIM_LOCATION` as `<date>-<step>-<slug>-<role>-v1`; the status set to `accepted` only when every required row is present; the tracker row updated; the commit merged under the branch protection file 01 applied. Reading a value always uses setup/03 §4.2's two-step form, because `penv_set` would otherwise record an empty string:

```bash
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" <ID> <NAME>) && penv_set <NAME> "$v"
```

**The title line.** `decision-check.sh` requires the first line to be the date, a space, the U+2014 dash character, a space and the title. This file's prose carries no such dash, so block D writes it with `printf` octal escapes, which the macOS `bash` 3.2 and `printf` accept.

**Block D, the drafting block**, used by every record step with that step's slug and title:

```bash
source "$HOME/.platform-env"
need PLATFORM_REPO_DIR BUILD_LOG_DIR
slug="<slug>"; title="<title>"
case "$slug$title" in *'<'*'>'*) echo "STOP: type the slug and the title first";; *)
  d=$(date -u +%F); rec="$PLATFORM_REPO_DIR/decisions/$d-$slug.md"
  test ! -e "$rec" || echo "STOP: $rec exists; a signed record is never overwritten"
  test -e "$rec" || { printf '# %s \342\200\224 %s\n' "$d" "$title"; tail -n +2 "$PLATFORM_REPO_DIR/decisions/_template.md"; } > "$rec"
  head -n 1 "$rec";;
esac
```

  Then fill the status block (`Decision ids`, `Required signatories`), every body section and the Values and Gates tables, compute the body hash with setup/03 DC-1.4's `awk ... | shasum -a 256` line, and send.

### 1.2 The POV's records, their ids and what each carries for the full build

| Step | Slug | Decision ids | Required signatories | Sets | Gates |
|---|---|---|---|---|---|
| PD-2.1 | `d7-letter` | D7-LETTER | PO | `DPO_CONTACT`, `WORKS_COUNCIL_QUESTION_RECORD` | PD-5.1 |
| PD-3.1 | `pov-reserved-ids` | PV-02 | PO, SH, ISMS | `AGENT_ID_DOER`, `AGENT_ID_EVE`, `AGENT_ID_MO`, `RESERVED_NAMES_RECORD` | every create step in 03, 04, 07 |
| PD-3.2 | `names-register` | PV-03, NAMES, D1, SD-23, SD-33 | PO, SH, MOO, ISMS | `NAMES_RECORD`; record values `PLATFORM_REPO_NAME`, `BUILD_LOG_REPO_NAME` | 01 Part B; every IRREVERSIBLE name in 03 to 08 |
| PD-3.3 | `key-table` | KEYS, SD-47 | PO, SH, ITSEC | `KEYS_RECORD` | ring creates in 03 and 06 |
| PD-4.1 | `pov-scope-track-and-end` | PV-01, PV-04, PV-13 | PO, SH, ISMS | `POV_GATE_LIST`, `POV_END_DATE` | every POV file; 09 |
| PD-4.3 (POV-2) | `pov-doer-catalogue-scopes-and-k4` | PV-01 (supersedes PD-4.1's record for PV-01 only) | PO, SH, SR, ISMS | none new in the variables file; record values `DOER_SCOPES_SHA256`, `DOER_OPERATION_CATALOGUE`, `DOER_FIRESTORE_BACKUP_RETENTION`, `DOER_K4_SCHEDULE`, `K4_RESIDUE_MAX_SECONDS`, with `POV_GATE_LIST` and `POV_END_DATE` restated unchanged | 07 PW-2.3, PW-3.1, PW-3.3, PW-4.1, PW-6.5; 09 PX-1.7 |
| PD-4.2 | four records of setup/03, see the step | SD-01 and the DC-4.1 set; P22, SD-14, M-7; P31, SD-16; SD-19, SD-48 | as setup/03 | none new | 01 to 07 |
| PD-5.1 | `monitoring-of-administrators` | PV-08, SD-11 | DPO, PO, SH, HR | none | every step of 06 |
| PD-5.2 | `retention` | PV-10, P13, E-14, M-5, P52, SD-20 | DPO, PO, MOO, SH, HR | `EVIDENCE_RETENTION_DAYS`, `IDENTITY_RETENTION_DAYS`, `RECORD_RETENTION_DAYS` | the locks in 03 and 06 |
| PD-5.3 | `pilot-population` | PV-06 | PO, DPO, HR, SH | `PILOT_POPULATION_COUNT`; record values `PILOT_OU`, `NONPROD_OU` | 07 parts 1 and 7 |
| PD-5.4 | `ai-act-classification` | PV-11 | AIC, DPO, PO | none; record values `AI_ACT_CLASS_*`, `AI_ACT_ROLE_*`, `PURPOSE_SHA256_*`, `AI_ACT_CLASS_TIER_C`, `AI_ACT_ROLE` | register rows in 04, 05, 07 |
| PD-5.5 | `pov-optional-tier-p` | PV-07 | PO, SH, SR, ISMS | none; record values `PILOT_ADMIN_AGENT_ID`, `PILOT_ADMIN_ROLE_READ_ID`, `PILOT_ADMIN_ROLE_WRITER_ID` | 07 part 7 |
| PD-6.1 | `appointment-<role>` | PPL-SH, PPL-SO, PPL-SR, PPL-BG, PPL-IC, PPL-BA | as setup/03 §5 | the six `*_EMAIL` values of the step's table, all before 01 Part B | 01 Part B; 04; two-person steps |
| PD-6.2 | `people-and-separations`; `recipient-of-reports-about-second-human` | PV-09; SH-REPORTS | ISMS, PO, SH; ISMS, ITSEC, PO | `ISMS_EMAIL`; record value `VERIFIER_OWNER_GROUP` | 01 Part B; 04 PC-3.2; 06 reporting route; 08 merge |
| PD-7.1 | `model-pin` | PV-12, WDEC-6, SD-09 | PO, ITSEC, DPO | `MODEL_ID` | 05, 07 |
| PD-8.0 | `pov-retrospective-log-reading-basis` | PV-05 | PO, SH, DPO, HR | none; record values `TOIL_RETRO_READ_BASIS`, `TOIL_RETRO_RESIDUAL_RISK` | PD-8.2 (no export before it is signed) |
| PD-8.3 | `pov-retrospective-toil-baseline` | PV-05 (supersedes PD-8.0's record), D12 | PO, SR, DPO, HR | `TOIL_TASKS`, `TOIL_BASELINE_FILE`, `TOIL_RETRO_WINDOW` | 08 value report |
| PD-8.7 (optional, before PD-8.6) | `recount-audit-privilege-grant` | PV-09 (supersedes PD-6.2's PV-09 record) | ISMS, DPO, PO, SH | record values `RECOUNT_ROLE_NAME`, `RECOUNT_GRANT_END` | PD-8.6 when person 3 recounts |

### 1.3 Full-set decisions: inherited, or unused because Track B is not started

| Kind | Ids | How the POV carries them |
|---|---|---|
| Inherited and signed in a POV record | NAMES, D1, SD-23, SD-33 (PD-3.2); KEYS, SD-47 (PD-3.3); SD-11 (PD-5.1); P13, E-14, M-5, P52, SD-20 (PD-5.2); WDEC-6, SD-09 (PD-7.1); D12 (PD-8.3); the six PPL ids and SH-REPORTS (PD-6) | the full-set text is quoted unchanged; only POV values are added |
| Inherited and signed with setup/03's own step | SD-01, SD-13, SD-17, SD-22, SD-35, SD-37, SD-38, SD-40, SD-41, SD-44, SD-45 (DC-4.1); P22, SD-14, M-7 (DC-4.3); P31, SD-16 (the billing half of DC-4.5); SD-19, SD-48 (PD-4.2) | PD-4.2 |
| Binding as written; no POV step reaches their gate | SD-36 and D13 (gate G1-G21), P137 (five humans at the grant), SD-30 (self-recovery and multi-party approval on gate day) | stated in PV-04 so nobody reads silence as waiver; G3-ROSTER, the roster reduction, is signed in 03 |
| **Unused, not loosened**, because Track B is not started (PV-D-04) | SD-05, SD-06, SD-25, SD-26, SD-29, WDEC-29, D3's sandbox half, PPL-SB1, PPL-SB2 | tracker rows stay `*tbd*`; SD-35 is signed (DC-4.1) and forbids mutating super-admin tests anywhere but a twin |
| Unused because the witness is not built (PV-D-03) | P14, SD-04, SD-27, SD-28, PPL-WA1, PPL-WA2, the witness rows of NAMES | tracker rows stay `*tbd*`; the NAMES record leaves the witness names `*tbd*` |
| Unused because nothing is bought (PV-D-10, PV-D-11, PV-D-02) | P10 (SIEM), P11 and SD-15 (SCC Premium payer), G8-WINDOW, G17-DATE, PPL-VC | tracker rows stay `*tbd*` |

#### PD-1.1 Add the POV rows to the tracker

- **WHO:** the platform owner. No witness.
- **WHERE:** shell, `~/.platform-env` sourced.
- **ACTION:** append one row per id of §1.2 that the tracker does not already hold, `Record` and `Status` set to `*tbd*` and `open`, in setup/03 §4.2's column order `| Id | Title | Record | Gates | Signatories | Status |`. The PV ids live in their own `PV-` space so they never collide with SD, P, D or E ids.

```bash
checkpoint PD-1.1 START - - "POV tracker rows"
for id in PV-01 PV-02 PV-03 PV-04 PV-05 PV-06 PV-07 PV-08 PV-09 PV-10 PV-11 PV-12 PV-13; do
  grep -q "^| $id |" "$PLATFORM_REPO_DIR/decisions/TRACKER.md" || printf '| %s | see POV 02 §1.2 | *tbd* | see POV 02 §1.2 | see POV 02 §1.2 | open |\n' "$id" >> "$PLATFORM_REPO_DIR/decisions/TRACKER.md"
done
grep -q "^| PPL-ENG |" "$PLATFORM_REPO_DIR/decisions/TRACKER.md" || printf '| PPL-ENG | POV-only: the engineer who writes PB-01 to PB-06 (no full-set record; superseded by the agent owners) | *tbd* | PB-01 to PB-06 start; 07 PW-4.1 | ISMS; the appointee; the platform owner | open |\n' >> "$PLATFORM_REPO_DIR/decisions/TRACKER.md"
for id in D7-LETTER NAMES KEYS D1 D12 SD-09 SD-11 SD-14 SD-16 SD-19 SD-20 SD-23 SD-33 SD-47 SD-48 P13 P22 P31 P52 E-14 M-5 M-7 WDEC-6 SH-REPORTS PPL-SH PPL-SO PPL-SR PPL-BG PPL-IC PPL-BA; do
  grep -q "^| $id |" "$PLATFORM_REPO_DIR/decisions/TRACKER.md" || echo "missing full-set row $id: add it exactly as setup/03 §11"
done
```

  Replace each `see POV 02 §1.2` cell by the title, gates and signatories of §1.2 before committing. Commit with a review record as setup/03 DC-1.3.
- **VERIFY:** `awk -F'|' 'NR>2 && NF>=7 {k=$2; gsub(/ /,"",k); print k}' "$PLATFORM_REPO_DIR/decisions/TRACKER.md" | sort | uniq -d` prints nothing; `grep -c '^| PV-' "$PLATFORM_REPO_DIR/decisions/TRACKER.md"` prints `13`; `grep -c '^| PPL-ENG |' "$PLATFORM_REPO_DIR/decisions/TRACKER.md"` prints `1`; `grep -c 'see POV 02' "$PLATFORM_REPO_DIR/decisions/TRACKER.md"` prints `0`; no `missing full-set row` line.
- **ROLLBACK:** `git -C "$PLATFORM_REPO_DIR" revert HEAD` before any record is signed.
- **EVIDENCE:** the commit and its review record; `checkpoint PD-1.1 DONE - "git:decisions/TRACKER.md" "13 PV rows"`; `evidence_add PD-1.1 pov-tracker E-05 1.4.1 "platform-repo:decisions/TRACKER.md@$(git -C "$PLATFORM_REPO_DIR" rev-parse HEAD)" "$PLATFORM_REPO_DIR/decisions/TRACKER.md"`. E-05; TISAX 1.4.1.

## 2. Day one: the clocks the POV does not control

#### PD-2.1 Send the letter to the DPO and the works-council question to HR (D7-LETTER)

- **WHO:** the platform owner sends; the DPO and the HR or works-council contact receive; legal in copy.
- **WHERE:** mail from the platform owner's daily account; record by block D, slug `d7-letter`, required signatory PO only (it records that the letter left, not an answer). Counterpart: [setup/03](../setup/03-decisions-and-people.md) DC-3.1.
- **ACTION:** send on day one, before anything is built. The letter asks for a written answer on seven points:
  1. **Eve watching named administrators** (SD-11, PV-08): purpose, detection of misuse of tenant-wide privilege; data, Admin, login, groups and, where the edition shares them, token and SAML event metadata written by Google, no content; subjects, every super admin and every admin-role holder, **including person 1 and person 2**; recipients, person 2 for reports about person 1, person 3 or the incident commander for reports about person 2, never the subject; retention at PV-10's values.
  2. **The retrospective toil count** (PV-05): six months of Admin log events read by the platform owner, reduced on the day of reading to counts per date and event name, with no actor identity kept.
  3. **The calibration sample**: a small number of real task instances timed by volunteers who agree to it, recorded under codes.
  4. **Synthetic pilot accounts only** (PV-06), and the three conditions before any real account enters.
  5. **Retention floors and ceilings** (P13, PV-10), and that the Gemini Enterprise baseline never lowers today's conversation retention (P52, SD-20).
  6. **The DPIA**: started now, with a completion date the DPO names (PV-D-15).
  7. **The works-council question**, to HR: is information or consultation required before (a) the calibration sample, (b) Eve's first run, (c) a real account entering `PILOT_OU`; and who gives it.

  Record Values: `DPO_CONTACT` (a role mailbox where one exists), the full set's own name (setup/03 DC-3.1), so the full build reads this record without a second variable; `WORKS_COUNCIL_QUESTION_RECORD`, the evidence name of the sent mail.

```bash
checkpoint PD-2.1 START - - "DPO letter and works-council question"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" D7-LETTER DPO_CONTACT) && penv_set DPO_CONTACT "$v"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" D7-LETTER WORKS_COUNCIL_QUESTION_RECORD) && penv_set WORKS_COUNCIL_QUESTION_RECORD "$v"
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" D7-LETTER` prints `SIGNED`; `need DPO_CONTACT WORKS_COUNCIL_QUESTION_RECORD` passes; the sent mail is in `EVIDENCE_INTERIM_LOCATION` under the name `WORKS_COUNCIL_QUESTION_RECORD` holds, and its date equals the record's date.
- **ROLLBACK:** none needed; a correction is a second letter recorded the same way, with a superseding record.
- **EVIDENCE:** `<date>-PD-2.1-d7-letter-v1` (the sent mail); `evidence_add PD-2.1 d7-letter E-12 7.1 "interim:$WORKS_COUNCIL_QUESTION_RECORD"`; `checkpoint PD-2.1 DONE - "interim:$WORKS_COUNCIL_QUESTION_RECORD" "letter sent"`. E-12; TISAX 7.1.

#### PD-2.2 Count and order the hardware keys, and start the seven-day clock

- **WHO:** the platform owner raises; procurement orders; person 2 is custodian of person 1's spare and the reverse.
- **WHERE:** procurement system; the paper custody record of [setup/04](../setup/04-purchases-and-lead-times.md) PU-4.2.
- **ACTION:** the POV's count is setup/04 §4's table without the witness, sandbox and `eve@` rows (PV-D-03, PV-D-04, PV-D-07):

  | Accounts | Keys | Custodians | Enrolled in |
  |---|---|---|---|
  | `sa-1-admin@` | 2 | person 1 carries one; spare in the safe, custodian person 2 | 03 |
  | `sa-2-admin@` | 2 | person 2 carries one; spare in the safe, custodian person 1 | 03 |
  | `brk-gcp-1@`, `brk-gcp-2@` | 2, one each | sealed; key 1 person 1, key 2 person 2 | 03 |
  | the doer's robot account | 2 | key A person 1, key B person 2 | 07 |
  | Spares, unenrolled | 2 (`Assumption:` one per custodian) | IT security, in the safe | on loss |
  | **Order** | **10**, minus keys already held and custody-recorded | | |

  1. Count the keys already held on a custody record; order only the difference. Order the custody materials of setup/04 PU-4.0 in the same request (envelopes for four accounts plus spares, a safe with a sign-out log, printed custody forms).
  2. **The hidden clock.** Google Account Help, "Use a security key for 2-Step Verification", read 2026-09-16: "You may need to wait 7 days before a newly added security key is available at sign-in", faster if the account already has a trusted passkey or security key. So a key that arrives on day *n* may not sign in until day *n*+7. [03](03-foundation-folders-logging-and-floors.md)'s first sitting is scheduled no earlier than seven days after the first key is added to `sa-1-admin@` and `sa-2-admin@`. Re-read the page on the ordering day and record the number it states.
- **VERIFY:** the purchase order's quantity equals the table's last line minus the held count; the build log carries the page's wait figure and the date it was read; when keys arrive, setup/04 PU-4.2's VERIFY (line count equals delivered count, two signatures per line, serials only on the custody record).
- **ROLLBACK:** amend or cancel the order before dispatch.
- **EVIDENCE:** `<date>-PD-2.2-key-order-v1` in `EVIDENCE_INTERIM_LOCATION`, later `<date>-PD-2.2-key-custody-record-v1`; `evidence_add PD-2.2 key-order E-08 3.1 "interim:<date>-PD-2.2-key-order-v1"`. No serial is ever written into the build log, the variables file or the wiki. E-08; TISAX 3.1.

#### PD-2.3 Confirm what is already owned and raise the three small purchases

- **WHO:** the platform owner; finance and the billing administrator for the billing account; the Workspace licence owner for seats.
- **WHERE:** the Admin console (Billing), finance's request channel; a record in the build log.
- **ACTION:** confirm, do not assume, each **Assumption:** row below, writing what was seen and where:

  | Item | Status to confirm | Lead time | Consumer |
  |---|---|---|---|
  | Workspace tenant and Cloud organisation | owned `Assumption:` | none | 03 |
  | Gemini Enterprise licences and app | owned `Assumption:`; the app's location is read in 05 | none | 05 |
  | Git host with branch protection | owned; proven by 01 | none | 01 |
  | **Workspace edition** | read in 06, because it decides which audit streams Eve sees ([08-data-logging-retention-sovereignty.md](../08-data-logging-retention-sovereignty.md) row R5) | none | 06 |
  | Dedicated EUR billing account (SD-16) | **raise now** with finance | 2 to 5 business days `Assumption:` | 03 |
  | One licence for the doer's robot account | raise now | same day `Assumption:` | 07 |
  | `PILOT_POPULATION_COUNT` licences for synthetic accounts | raise once PV-06 is signed | same day `Assumption:` | 07 |
  | **The engineer** (PPL-ENG, PD-6.1), only if not staffed internally: a contract for 40 to 64 engineer-days (README §8) | **raise now** if PD-6.1 records `contractor`; this is on the critical path, because PB-01 to PB-03 start the day the engineer does | weeks `Assumption:` (procurement, security vetting, repository access) | PB-01 to PB-06; 04, 06, 07, 08 |
  | GCP usage | low tens of euros a month `Assumption:`; budget alerts in 03 | none | 03 |
  | SCC Standard | free | none | 03 |

  **Not bought for Track A**, each named so nobody reads silence as a decision: SIEM and 24x7 MDR retainer (PV-D-10), penetration test (PV-D-11), SCC Premium (PV-D-02), witness domain and billing (PV-D-03), second Workspace tenant (PV-D-04), Chrome Enterprise Premium (PV-D-16). File 09 costs them.
- **VERIFY:** the build log carries one line per table row with `confirmed`, `raised <date>` or `not owned`; a `not owned` on the tenant, the organisation or Gemini Enterprise stops the POV and is raised to the platform owner's sponsor.
- **ROLLBACK:** withdraw a request before it is fulfilled.
- **EVIDENCE:** `<date>-PD-2.3-purchases-v1.md` in `$BUILD_LOG_DIR/records/`; `evidence_add PD-2.3 purchases E-11 6.1 "build-log:records/$(date -u +%F)-PD-2.3-purchases-v1.md" "$BUILD_LOG_DIR/records/$(date -u +%F)-PD-2.3-purchases-v1.md"`. E-11; TISAX 6.1.

## 3. Names first: every name the POV creates is permanent

Project ids are never reusable even after deletion; key rings cannot be deleted and deleted key names cannot be reused; a BigQuery dataset's name and location cannot be changed; a tag key's short name cannot be changed ([setup/03](../setup/03-decisions-and-people.md) §8). So the POV signs the full build's names before it creates anything, and every create step in 03 to 08 refuses without `decision-need.sh PV-02 NAMES`.

#### PD-3.1 PV-02: the doer is a separate agent, and Wall-E's names are reserved

- **WHO:** the platform owner drafts; person 2 signs; ISMS signs the reservation.
- **WHERE:** block D, slug `pov-reserved-ids`, title `PV-02 the doer is a separate agent; Wall-E's names are reserved`.
- **ACTION:** the record body:
  - **Context.** [setup/31](../setup/31-wall-e-project-and-data-plane.md) creates Wall-E's project in `fld-agents-p-sa-prod` with `agent_id` `walle` and register tier P-SA; its audit dataset is `walle_audit` (setup/03 NAMES). A project never moves between tier folders; a tier change is a new row and a new project ([02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §3). The register schema pins `privilege: none` at tiers C, R and W ([setup/16](../setup/16-register-and-shared-registry.md), `register-row.schema.json`).
  - **Options considered.** A: spend Wall-E's names at Tier W (refused: the full build would have to rename Wall-E). B: create Wall-E's project in `fld-agents-p-sa-prod` on day one with no grant (refused: P-SA nonprod must be a sandbox tenant, [02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) line 488, which pulls in Track B). C: a separate doer agent with its own permanent `agent_id` at Tier W; Wall-E's names reserved and left empty (chosen).
  - **Decision.** The POV doer is a separate agent. The ids `walle`, the variable `WALLE_PROJECT`, the dataset `walle_audit`, the variable `EVE_WITNESS_PROJECT` and the folders `fld-agents-p-sa-prod` and `fld-agents-p-sa-nonprod` are reserved: 03 creates the two folders empty, and no POV step creates the rest. `agent_id` follows `^[a-z][a-z0-9-]{1,30}$`, the pattern [setup/22](../setup/22-mo-foundations.md) MO-1.1 and [setup/23](../setup/23-eve-project-and-evidence-stores.md) EP-1.1 write into the register schemas so that `mo`, two characters, is legal, and the pattern [04](04-the-contract-register-agent-ids-and-schemas.md) PC-1.2 merges. [05-registry-and-autonomy-contract.md](../05-registry-and-autonomy-contract.md) §3 and setup/16's original schemas still print `{2,30}`; that older form is superseded by MO-1.1 and is not the join key's rule here. The doer's audit dataset is `<agent_id>_audit` with hyphens spelled as underscores (same page, §9); that rule is also why Wall-E's reserved id is `walle` and never `wall-e`. Eve and Mo keep the full set's ids, because the full set's run specs are `factory/runs/eve-prod.json` and `factory/runs/mo-prod.json`. **PV-D-08.**
  - **Values:** `AGENT_ID_DOER` = `steward` (`Assumption:` a recommendation; the signers may choose another legal id, once and for good); `AGENT_ID_EVE` = `eve`; `AGENT_ID_MO` = `mo`.
  - **Gates:** 03 folder creates; 04 register rows; 07 every create step.
  - **Consequences:** the doer's code, schemas, ladder, consent procedure and kill switch carry to Wall-E; its project and data do not. When the P-SA gate opens, setup/30 to 39 run unchanged against the reserved names.

```bash
checkpoint PD-3.1 START - - "PV-02 reserved ids"
for n in AGENT_ID_DOER AGENT_ID_EVE AGENT_ID_MO; do
  v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-02 "$n") || { echo "STOP: no signed value for $n"; break; }
  penv_set "$n" "$v"
done
rec="$PLATFORM_REPO_DIR/decisions/$(awk -F'|' '{k=$2; gsub(/ /,"",k); if (k=="PV-02") {r=$4; gsub(/ /,"",r); print r}}' "$PLATFORM_REPO_DIR/decisions/TRACKER.md" | head -n 1)"
test -f "$rec" && penv_set RESERVED_NAMES_RECORD "decisions/$(basename "$rec")"
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-02` prints `SIGNED`; then

```bash
for v in "$AGENT_ID_DOER" "$AGENT_ID_EVE" "$AGENT_ID_MO"; do printf '%s' "$v" | grep -Eq '^[a-z][a-z0-9-]{1,30}$' && echo "$v legal" || echo "FAIL $v"; done
# names-check: off PV-02
case "$AGENT_ID_DOER" in walle|wall-e|eve|mo) echo "FAIL: the doer may not take a reserved or existing id";; *) echo "doer id distinct";; esac
# names-check: on
```

  prints three `legal` lines and `doer id distinct`.
- **ROLLBACK:** a superseding record, possible only while no create step has used `AGENT_ID_DOER`. **After 04 commits the doer's register row or 07 creates its project, the id is IRREVERSIBLE.**
- **EVIDENCE:** the record and its signature mails; `evidence_add PD-3.1 pov-reserved-ids E-05 1.3 "platform-repo:$RESERVED_NAMES_RECORD" "$PLATFORM_REPO_DIR/$RESERVED_NAMES_RECORD"`; `checkpoint PD-3.1 DONE - "git:$RESERVED_NAMES_RECORD" "doer id $AGENT_ID_DOER"`. E-05; TISAX 1.3.

#### PD-3.2 PV-03: the names register, signed unchanged (NAMES, D1, SD-23, SD-33)

- **WHO:** the platform owner drafts; person 2 signs the Eve names; the Mo owner (person 1 unless PD-6.1 names another) signs the Mo names; ISMS signs.
- **WHERE:** block D, slug `names-register`, title `PV-03 names register`. Counterpart: [setup/03](../setup/03-decisions-and-people.md) DC-5.1, whose table is copied in full and whose values are kept.
- **ACTION:** copy DC-5.1's names table into the Values table, then make exactly these POV additions and nothing else:
  - fill every value the POV creates: `CORE_PROJECT`, `LOGGING_PROJECT`, `KMS_PROJECT`, `VALIDATOR_PROJECT`, `CICD_PROJECT`, `GEMINI_PROJECT`, `EVE_PROJECT`, `MO_PROJECT`, `PLATFORM_EVIDENCE_BUCKET` (setup/42's precondition asks NAMES for it), `EVE_EVIDENCE_BUCKET`, the OU paths `ADMIN_OU`, `BREAK_GLASS_OU`, `SERVICE_IDENTITY_OU`, `PILOT_OU`, `NONPROD_OU` (the empty OU the doer's nonprod ladder names, created in 07 PW-1.2), the group addresses of the brief, and the two repository names `PLATFORM_REPO_NAME` (DC-5.1's `Repository` row) and `BUILD_LOG_REPO_NAME`, which [01](01-conventions-and-variables.md) Part B reads from this record once it is signed to create both repositories;
  - add the doer's rows: `DOER_PROJECT`, `DOER_NONPROD_PROJECT`, `DOER_AUDIT_DS` = `<AGENT_ID_DOER with hyphens as underscores>_audit`, `DOER_ROBOT` (the doer's robot address, read by 07 PW-1.3) and the doer's OAuth app name (D1), and the optional Tier P rows `PILOT_ADMIN_PROJECT`, `PILOT_ADMIN_NONPROD_PROJECT` and `PILOT_ADMIN_ROBOT` (PV-07; read by 07 PW-7.1 and PW-7.2);
  - `TAG_KEY_ENV` = `agp-env` only if the signers adopt the environment tag key; 03 creates `agp-env` only when this row reads exactly that, and leaves it out otherwise;
  - fixed values stay exactly: datasets `platform_logs`, `platform_logs_views`, `platform_metrics`, `platform_metrics_archive`, `platform_metrics_private`, `platform_metrics_views` (SD-33, every table keyed on `agent_id`), `eve`, `eve_workspace_logs`, `eve_quality`, `eve_grades`; log buckets `platform-evidence-logs`, `platform-identity-logs`; tag keys `agp-tier`, `agp-tisax-scope`; `EVE_EVIDENCE_LOCATION` = `europe-west1` (SD-23);
  - left `*tbd*` and reserved: `WALLE_PROJECT` and its audit dataset (PV-02), the twin projects and `SANDBOX_OU` (PV-D-04), the witness project, bucket and mirror dataset (PV-D-03). The full build supersedes this record to fill them, with the witness administrators' signatures DC-5.1 requires.
  - The fallback rule for a project id or bucket name found taken at creation: one suffix, stated in the record, applied and recorded by the create step.

```bash
checkpoint PD-3.2 START - - "PV-03 names register"
rec="$PLATFORM_REPO_DIR/decisions/$(awk -F'|' '{k=$2; gsub(/ /,"",k); if (k=="NAMES") {r=$4; gsub(/ /,"",r); print r}}' "$PLATFORM_REPO_DIR/decisions/TRACKER.md" | head -n 1)"
test -f "$rec" && penv_set NAMES_RECORD "decisions/$(basename "$rec")"
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-03 NAMES D1 SD-23 SD-33` prints five `SIGNED` lines; then

```bash
need NAMES_RECORD AGENT_ID_DOER
r="$PLATFORM_REPO_DIR/$NAMES_RECORD"
for n in platform_logs platform_logs_views platform_metrics platform_metrics_archive platform_metrics_private platform_metrics_views eve_workspace_logs eve_quality eve_grades platform-evidence-logs platform-identity-logs agp-tier agp-tisax-scope europe-west1; do grep -q "$n" "$r" || echo "missing $n"; done
grep -q "$(printf '%s' "$AGENT_ID_DOER" | tr - _)_audit" "$r" && echo "doer audit dataset follows the <agent_id>_audit rule"
"$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES EVE_EVIDENCE_LOCATION
for n in PLATFORM_REPO_NAME BUILD_LOG_REPO_NAME SERVICE_IDENTITY_OU PILOT_OU NONPROD_OU DOER_PROJECT DOER_NONPROD_PROJECT DOER_AUDIT_DS DOER_ROBOT PLATFORM_EVIDENCE_BUCKET EVE_PROJECT EVE_EVIDENCE_BUCKET MO_PROJECT; do "$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-03 "$n" >/dev/null || echo "MISSING $n"; done
# Project ids are permanent, so their form is checked before anything is created (02-landing-zone §3.6, P37):
# agp-<tier code>-<agent>-<env>[-<4 hex>], core projects agp-core-<name>. setup/17's checker refuses any other form.
form() { v="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-03 "$1" 2>/dev/null)" || { echo "MISSING $1"; return; }
  if printf '%s' "$v" | grep -Eqx "$2" && [ "${#v}" -ge 6 ] && [ "${#v}" -le 30 ]; then echo "form ok $1"; else echo "FORM $1=$v expected $2 (6 to 30 characters)"; fi; }
for n in CORE_PROJECT LOGGING_PROJECT KMS_PROJECT VALIDATOR_PROJECT CICD_PROJECT; do form "$n" 'agp-core-[a-z0-9]+(-[0-9a-f]{4})?'; done
form GEMINI_PROJECT 'agp-ge-[a-z0-9-]*[a-z0-9]'
form EVE_PROJECT 'agp-ctl-eve-prod(-[0-9a-f]{4})?'
form MO_PROJECT 'agp-imp-mo-prod(-[0-9a-f]{4})?'
form DOER_PROJECT "agp-w-${AGENT_ID_DOER}-prod(-[0-9a-f]{4})?"
form DOER_NONPROD_PROJECT "agp-w-${AGENT_ID_DOER}-nonprod(-[0-9a-f]{4})?"
```

  Expect no `missing` or `MISSING` line, the `follows` line, `europe-west1`, and eleven `form ok` lines. A `FORM` line is corrected in the record before it is signed: the form is what setup/17's checker (`project_id.form`) and the design's `custom.agpProjectIdPrefix` constraint require, and a project created under another id can never be adopted by the factory. The Tier P rows follow the same form with `agp-p-` when PV-07 is exercised. The Tier P rows (`PILOT_ADMIN_*`) may be `*tbd*` until PV-07 is exercised. The reviewer reads the retired names of [setup/README.md](../setup/README.md) §5 against the record by eye and file 01's retired-names check runs over it.
- **ROLLBACK:** a superseding record, only for names not yet created. **IRREVERSIBLE once a create step has used a name.**
- **EVIDENCE:** `evidence_add PD-3.2 names-register E-05 1.3 "platform-repo:$NAMES_RECORD" "$PLATFORM_REPO_DIR/$NAMES_RECORD"`; `checkpoint PD-3.2 DONE - "git:$NAMES_RECORD" "NAMES signed"`. E-05; TISAX 1.3.

#### PD-3.3 The key table, signed unchanged (KEYS, SD-47)

- **WHO:** the platform owner; person 2 (Eve's rings); ITSEC.
- **WHERE:** block D, slug `key-table`. Counterpart: setup/03 DC-5.2, whose table is copied without change: rings `logging` (`KMS_PROJECT`, `europe-west1`), `gemini` (`KMS_PROJECT`, `europe`), `engines` (`KMS_PROJECT`, `europe-west1`), `supply-chain` (`CICD_PROJECT`, `europe-west1`), `eve` (`EVE_PROJECT`, `europe-west1`), `eve-eu` (`EVE_PROJECT`, `europe`, because a dataset in `EU` needs a key from a `europe` ring).
- **ACTION:** the one POV addition is a line in Consequences: the `supply-chain` ring is created in 03 and holds no Binary Authorization key during the POV (PV-D-12); the ring name is spent so the full build does not choose another. Then:

```bash
checkpoint PD-3.3 START - - "KEYS"
rec="$PLATFORM_REPO_DIR/decisions/$(awk -F'|' '{k=$2; gsub(/ /,"",k); if (k=="KEYS") {r=$4; gsub(/ /,"",r); print r}}' "$PLATFORM_REPO_DIR/decisions/TRACKER.md" | head -n 1)"
test -f "$rec" && penv_set KEYS_RECORD "decisions/$(basename "$rec")"
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" KEYS SD-47` prints two `SIGNED`; `for k in logging gemini engines supply-chain eve-eu eve-evidence-eu; do grep -c -- "$k" "$PLATFORM_REPO_DIR/$KEYS_RECORD"; done` prints six numbers of at least `1`.
- **ROLLBACK:** a superseding record before 03 or 06 creates a ring. **IRREVERSIBLE once a ring exists.**
- **EVIDENCE:** `evidence_add PD-3.3 key-table - 5.1.1 "platform-repo:$KEYS_RECORD" "$PLATFORM_REPO_DIR/$KEYS_RECORD"` (E-xx: none, key configuration, as setup/03 DC-5.2); `checkpoint PD-3.3 DONE - "git:$KEYS_RECORD" "KEYS signed"`. TISAX 5.1.1.

## 4. Scope, track and the end date

#### PD-4.1 PV-01, PV-04 and PV-13: scope, Track A only, and the dated end

- **WHO:** the platform owner drafts; person 2 (as IT security); ISMS.
- **WHERE:** block D, slug `pov-scope-track-and-end`, title `PV-01 PV-04 PV-13 POV scope, track and end`.
- **ACTION:** the record body:
  - **PV-01, scope.** POV-1 (weeks 0 to 3 or 4, no service code beyond SQL): Tier C and Tier R, Eve watching every human super admin. POV-2 (weeks 4 to 12, paced by code PB-01 to PB-06): the doer at Tier W with `privilege: none`, and Mo. Quote the schema's conditionals: privilege is `none` at C, R and W; `workspace_role:<name>` is legal only at P and P-SA, where the verifier must be `eve`. A row is never relabelled to avoid that. Extends SD-45 (the owner's order) and SD-13 (Gemini Enterprise baseline after Tier R).
  - **PV-04, Track A only.** Super Admin cannot be scoped to an organisational unit ([02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) line 488); mutating super-admin tests run only on a twin (SD-35). Given up and named: G10, G11, G14, G20 and Eve's G-7; the gate G1-G21 (SD-36, D13) and the five-human count (P137) stand as written and no POV step reaches them. Track B needs a sandbox tenant and four distinct humans (persons 1 and 2 plus two sandbox super admins who are neither).
  - **PV-13, the end.** A dated stop-or-continue review in 09. In either outcome nothing is torn down: every project, dataset, ring, record and register row is the full build's.
  - **Values:** `POV_GATE_LIST` = `TIER-R,TIER-C,TIER-W` plus `TIER-P` only if PV-07 is exercised (the POV claims these gate records and no G-line of the super-admin gate); `POV_END_DATE` = the review date, `YYYY-MM-DD`, `Assumption:` no earlier than twelve weeks after day one.

```bash
checkpoint PD-4.1 START - - "PV-01 PV-04 PV-13"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 POV_GATE_LIST) && penv_set POV_GATE_LIST "$v"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-13 POV_END_DATE) && penv_set POV_END_DATE "$v"
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-01 PV-04 PV-13` prints three `SIGNED`; `case "$POV_GATE_LIST" in *G1*|*G10*|*SUPER*|*P-SA*) echo "FAIL: the POV claims no super-admin gate line";; *) echo ok;; esac` prints `ok`; `python3 -c 'import sys,datetime as d; d.date.fromisoformat(sys.argv[1]); print("date ok")' "$POV_END_DATE"` prints `date ok`.
- **ROLLBACK:** a superseding record. Starting Track B is a superseding PV-04, never an edit.
- **EVIDENCE:** `evidence_add PD-4.1 pov-scope E-03 1.4.1 "platform-repo:decisions/<file>"` with the file name from the tracker; checkpoint DONE. E-03; TISAX 1.4.1.

#### PD-4.2 Sign the inherited setup records with setup/03's own steps

- **WHO:** as each setup/03 step: the platform owner, ITSEC, ISMS, finance with the billing administrator, person 2 for SD-48.
- **WHERE:** [setup/03](../setup/03-decisions-and-people.md) DC-4.1, DC-4.3, DC-4.5 and DC-8.1, run as written with the differences below.
- **ACTION:**
  1. **DC-4.1 unchanged**: SD-01, SD-13, SD-17, SD-22, SD-35, SD-37, SD-38, SD-40, SD-41, SD-44, SD-45. SD-01 is the dated bootstrap exception under which 03 builds by hand (PV-D-01).
  2. **DC-4.3 unchanged**: P22, SD-14, M-7, and the values `GIT_HOST`, `GIT_OIDC_ISSUER`. If file 01 already signed this record, run only its VERIFY.
  3. **DC-4.5, billing half only**: a record `billing-account` with ids P31 and SD-16, signatories FIN, BA, PO, and the `gcloud billing accounts describe` read run by the billing administrator. P10, P11 and SD-15 are not carried: nothing is bought (PV-D-10, PV-D-02). The full build signs DC-4.5 with those three ids and its record supersedes this one for P31 and SD-16.
  4. **Two privilege rules the POV needs before 05 and 07**, as a record `pov-inherited-privilege-rules` with ids SD-19 and SD-48, signatories PO, ITSEC, ISMS, SH, quoting DC-6.1's SD-19 text and DC-8.1's SD-48 text verbatim. The full build's DC-6.1 and DC-8.1 records supersede it.
- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" SD-01 SD-13 SD-17 SD-22 SD-35 SD-37 SD-38 SD-40 SD-41 SD-44 SD-45 P22 SD-14 M-7 P31 SD-16 SD-19 SD-48` prints eighteen `SIGNED` lines; `grep -c 'no multi-party approval admin role' "$PLATFORM_REPO_DIR"/decisions/*-pov-inherited-privilege-rules.md` is at least `1`.
- **ROLLBACK:** superseding records, as setup/03.
- **EVIDENCE:** one `evidence_add` per record, E-05 (DC-4.1, DC-4.3), E-11 (billing), E-08 (privilege rules); TISAX 1.4.1, 5.2.1, 6.1, 4.1.3.

#### PD-4.3 PV-01 superseded in POV-2: the doer's scope hash, operation catalogue, backup retention and K4 line - **BLOCKED on PB-04 and PB-05**

- **WHO:** the platform owner drafts; person 2 signs; person 3 signs as SR (the catalogue and the scopes are security rows); ISMS signs. The author of PB-04 supplies the proof below and does not sign.
- **WHERE:** block D, slug `pov-doer-catalogue-scopes-and-k4`, title `PV-01 doer catalogue, scopes and K4 line`, with a `Supersedes:` line naming PD-4.1's record. Runs in POV-2, after PB-04's author has proved one operation and its inverse and PB-05 has committed the scope file, and **before** [07](07-the-doer-tier-w-and-the-optional-tier-p.md) PW-2.3 creates the doer's Firestore backup schedule and PW-3.1 opens the consent sitting. PD-4.1 cannot carry these values in week 1: the catalogue is not knowable until the proof exists (07's Unverified table).
- **ACTION:** **BLOCKED** until both exist: (a) PB-04's proof, in nonprod-shaped data, of one add and its exact inverse for each candidate operation pair, recorded as `<date>-PD-4.3-catalogue-proof-v1.md` by PB-04's author; (b) `agents/<AGENT_ID_DOER>/config/scopes.txt` merged on `main` by PB-05 under two human approvals. The code is PB-04 and PB-05 in the doer's code repository (README §8; `Assumption:` 22 to 35 and 2 to 4 engineer-days, counted there, not here). No console step replaces either. Then the record body copies PD-4.1's PV-01 text unchanged and adds:
  - **Values:** `POV_GATE_LIST` and `POV_END_DATE` restated with PD-4.1's signed values (a superseding record carries every value, so `decision-value.sh PV-01 POV_GATE_LIST` still answers); `DOER_SCOPES_SHA256` = the SHA-256 of the merged `scopes.txt`; `DOER_OPERATION_CATALOGUE` = exactly six entries written as three `operation:inverse` pairs on resources the robot itself owns or manages, each pair cited to the proof record; `DOER_FIRESTORE_BACKUP_RETENTION` = `14d` (`Assumption:` 07 PW-2.3's figure; the signers may choose another, and 07 reads this value); `DOER_K4_SCHEDULE` = `once at commissioning (07 PW-6.5), then on incident only` (`Assumption:` 07's schedule; any other schedule is signed here, not improvised); `K4_RESIDUE_MAX_SECONDS` = the longest measured residue, in whole seconds, between the K4 revoke and the first refused read that still passes the kill (read by [09](09-the-demonstration-deviations-and-the-hand-over.md) PX-1.7 and meant as 07 PW-6.5's pass criterion; `Assumption:` `3600`, the 60-minute read of PX-1.7, until the signers set a tighter figure).
  - **Gates:** 07 PW-2.3 (backup retention), PW-3.1 and PW-3.3 (scope hash), PW-4.1 (catalogue), PW-6.5 (K4 line); 09 PX-1.7 (`K4_RESIDUE_MAX_SECONDS`).
  - **Consequences:** widening the scope file after the sitting is a new consent and a new supersession of PV-01; an operation without a proven inverse is not catalogued.

```bash
source "$HOME/.platform-env"; penv_guard
need PLATFORM_REPO_DIR AGENT_ID_DOER
checkpoint PD-4.3 START - - "PV-01 supersession: scopes, catalogue, K4"
git -C "$PLATFORM_REPO_DIR" fetch -q origin
git -C "$PLATFORM_REPO_DIR" show "origin/main:agents/$AGENT_ID_DOER/config/scopes.txt" | shasum -a 256
git -C "$PLATFORM_REPO_DIR" show "origin/main:agents/$AGENT_ID_DOER/config/scopes.txt" | grep -c 'cloud-platform'
```

  The first printed hash is the value to write; the `grep -c` must print `0`, otherwise the record is not drafted.
- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-01` prints `SIGNED`; then

```bash
for n in POV_GATE_LIST POV_END_DATE DOER_SCOPES_SHA256 DOER_OPERATION_CATALOGUE DOER_FIRESTORE_BACKUP_RETENTION DOER_K4_SCHEDULE K4_RESIDUE_MAX_SECONDS; do "$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 "$n" >/dev/null && echo "$n present" || echo "MISSING $n"; done
test "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 DOER_SCOPES_SHA256)" = "$(git -C "$PLATFORM_REPO_DIR" show "origin/main:agents/$AGENT_ID_DOER/config/scopes.txt" | shasum -a 256 | awk '{print $1}')" && echo "scope hash matches main"
"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 DOER_OPERATION_CATALOGUE | tr ',' '\n' | awk -F: 'NF==2 && $1!="" && $2!=""' | wc -l
test "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 POV_GATE_LIST)" = "$POV_GATE_LIST" && echo "gate list unchanged"
```

  Expect seven `present` lines, `scope hash matches main`, `3` (three pairs, six operations), `gate list unchanged`. The reviewer confirms each pair against the proof record; the signers confirm the record's signature table has no row for PB-04's author.
- **ROLLBACK:** a further superseding record, possible only before 07 PW-3.1's sitting uses the hash. **After the consent sitting the scope set is IRREVERSIBLE** (07 PW-3.3's rollback); confirm first that the hash matches `main` and that no scope is `cloud-platform`.
- **EVIDENCE:** the record and signature mails; the proof record `<date>-PD-4.3-catalogue-proof-v1.md` in `$BUILD_LOG_DIR/records/`; `evidence_add PD-4.3 pov-doer-catalogue-scopes-and-k4 E-03 1.4.1 "platform-repo:decisions/<file>" "$PLATFORM_REPO_DIR/decisions/<file>"`; `evidence_add PD-4.3 catalogue-proof E-05 5.2 "build-log:records/<file>" "$BUILD_LOG_DIR/records/<file>"`; checkpoint DONE. E-03, E-05; TISAX 1.4.1, 5.2.

## 5. Data protection, the population, classification and the optional Tier P step

#### PD-5.1 PV-08 and SD-11: Eve's POV shape and the DPO's record on monitoring administrators (blocking)

- **WHO:** the DPO signs; the platform owner and person 2 co-sign; HR signs the works-council half.
- **WHERE:** block D, slug `monitoring-of-administrators`, title `PV-08 SD-11 monitoring of named administrators`. Counterpart: setup/03 DC-3.2.
- **ACTION:** the record holds the DPO's answer to PD-2.1 point 1 and HR's answer to point 7(b): legal basis, purpose, data, subjects (every super admin and admin-role holder, persons 1 and 2 included), retention (PV-10), recipients (never the subject). It fixes Eve's POV shape: **no Workspace credential** (PV-D-07); it reads only the audit streams Google shares into Cloud Logging for this edition ([08-data-logging-retention-sovereignty.md](../08-data-logging-retention-sovereignty.md) row R5); its scheduled queries block nothing (PV-D-06); and **no report of the POV calls Eve independent**, because person 2 owns it and receives its reports (PV-D-03).
- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-08 SD-11` prints two `SIGNED` lines. **Every step of file 06 opens with this command and stops without it.** Built before this record, Eve's dataset would hold identified administrators without a basis and would have to be deleted.
- **ROLLBACK:** a superseding record. If the DPO withdraws the basis after 06 has run, 06's schedules are paused the same day and the DPO decides the data's fate in writing.
- **EVIDENCE:** `evidence_add PD-5.1 monitoring-of-administrators E-12 7.1 "platform-repo:decisions/<file>"`; checkpoint DONE. E-12; TISAX 7.1.

#### PD-5.2 PV-10: retention floors, ceilings and lock values (P13, E-14, M-5, P52, SD-20)

- **WHO:** the DPO signs; the platform owner, the Mo owner and person 2 co-sign; HR for the user-notice rule.
- **WHERE:** block D, slug `retention`. Counterpart: setup/03 DC-4.8, whose body is copied, plus the `RECORD_RETENTION_DAYS` value [setup/42](../setup/42-gates-drills-and-evidence.md) GD-3.1 needs and DC-4.8 does not yet set.
- **ACTION:** the proposal the DPO answers is [08-data-logging-retention-sovereignty.md](../08-data-logging-retention-sovereignty.md) §5.2: 400 days for evidence stores (rows R2, R3), 400 days `Assumption:` for the identity log bucket (row R5, where the DPO's number most plausibly differs), 10 years for records (row R11). **The lock value of every locked store equals its ceiling**, because a locked retention policy can never be removed or reduced. The POV has two locks: `PLATFORM_EVIDENCE_BUCKET` in 03 (at `RECORD_RETENTION_DAYS`) and `EVE_EVIDENCE_BUCKET` in 06 (at `EVIDENCE_RETENTION_DAYS`). The Gemini Enterprise baseline never lowers the conversation retention 05 reads (P52, SD-20). Values: the three integers, or `*tbd*` while the DPO has not answered; nothing is filled with a plausible guess.

```bash
checkpoint PD-5.2 START - - "PV-10 retention"
for n in EVIDENCE_RETENTION_DAYS IDENTITY_RETENTION_DAYS RECORD_RETENTION_DAYS; do
  v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" P13 "$n") || { echo "STOP: no signed $n"; break; }
  penv_set "$n" "$v"
done
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-10 P13 E-14 M-5 P52 SD-20` prints six `SIGNED`; then

```bash
for n in EVIDENCE_RETENTION_DAYS IDENTITY_RETENTION_DAYS RECORD_RETENTION_DAYS; do v=$(printenv "$n"); case "$v" in ''|*[!0-9]*) echo "$n not an integer: every lock refuses";; *) echo "$n $v";; esac; done
[ "${RECORD_RETENTION_DAYS:-0}" -ge 400 ] && [ "${RECORD_RETENTION_DAYS:-0}" -le 3650 ] && echo "record value inside setup/42's 400..3650"
```

  An evidence value below 180 is refused by the reviewer: [10-eu-ai-act.md](../10-eu-ai-act.md) §5 row E-06 and Art. 19 need at least six months for the audit log.
- **ROLLBACK:** a superseding record, possible only before the first lock. **The locks are IRREVERSIBLE in 03 and 06 and are gated on this record.**
- **EVIDENCE:** `evidence_add PD-5.2 retention E-06 5.2.4 "platform-repo:decisions/<file>"`; checkpoint DONE. E-06, E-12; TISAX 5.2.4, 7.1.

#### PD-5.3 PV-06: the pilot population

- **WHO:** the platform owner drafts; the DPO, HR and person 2 sign.
- **WHERE:** block D, slug `pilot-population`.
- **ACTION:** Decision: `PILOT_OU` (path in NAMES) holds **synthetic accounts only**, created for the POV, owned by the platform, receiving no real mail and holding no real data. Three conditions, all required, before any real account enters: (1) the DPIA of PV-D-15 is complete and signed; (2) HR's written answer that works-council information or consultation for real accounts has been given; (3) the account holder's written consent and a signed PV-06 supersession naming the account. Values: `PILOT_POPULATION_COUNT` (`Assumption:` 5 to 10); `PILOT_OU` and `NONPROD_OU`, restated with exactly the paths the NAMES record (PD-3.2) signs, because 07 PW-1.2 reads both from this record.

```bash
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-06 PILOT_POPULATION_COUNT) && penv_set PILOT_POPULATION_COUNT "$v"
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-06` prints `SIGNED`; `case "$PILOT_POPULATION_COUNT" in ''|*[!0-9]*) echo FAIL;; *) [ "$PILOT_POPULATION_COUNT" -ge 1 ] && echo "count $PILOT_POPULATION_COUNT";; esac`; `for n in PILOT_OU NONPROD_OU; do test "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-06 "$n")" = "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES "$n")" && echo "$n equals NAMES" || echo "FAIL $n"; done` prints two `equals NAMES` lines. No `penv_set` of either OU here: 07 PW-1.2 sets them when it creates the OUs.
- **ROLLBACK:** a superseding record. A real account found in `PILOT_OU` without the three conditions is a severity-2 finding, removed the same day.
- **EVIDENCE:** `evidence_add PD-5.3 pilot-population E-12 7.1 "platform-repo:decisions/<file>"`; checkpoint DONE. E-12; TISAX 7.1.

#### PD-5.4 PV-11: EU AI Act classification, intended purpose and the Art. 4 briefing

- **WHO:** the AI compliance owner or legal's designate; the DPO; the platform owner.
- **WHERE:** block D, slug `ai-act-classification`; the briefing is a 30-minute meeting.
- **ACTION:** Values rows read with `decision-value.sh PV-11 <NAME>` (record values, not environment variables), under exactly the names the consuming steps read: for the doer, Eve and Mo, `AI_ACT_CLASS_DOER`, `AI_ACT_CLASS_EVE`, `AI_ACT_CLASS_MO`, `AI_ACT_ROLE_DOER`, `AI_ACT_ROLE_EVE`, `AI_ACT_ROLE_MO`, `PURPOSE_SHA256_DOER`, `PURPOSE_SHA256_EVE`, `PURPOSE_SHA256_MO` (04 PC-3.1 onwards); for the two Tier C helpers, whose `agent_id`s 05 chooses later, one class `AI_ACT_CLASS_TIER_C` and one role `AI_ACT_ROLE` shared by both, with each helper's intended-purpose paragraph in the record body (05 PG-6.1). If PV-07 (PD-5.5) is exercised, a superseding PV-11 adds the Tier P agent's three rows before 07 §7 writes its register row. Classes and roles come only from the schema's enums (`not_ai_system`, `minimal`, `limited_art50`, `annex_iii_adjacent`, `high_risk`; `provider`, `deployer`, `both`; [05-registry-and-autonomy-contract.md](../05-registry-and-autonomy-contract.md) §3). The purpose paragraph per agent is committed under `register/purpose/` and its SHA-256 is the value. A row classed `annex_iii_adjacent` also needs the dated Art. 6(4) assessment and an Art. 49 value before 04 can commit it. The record includes the Art. 5 negative determination (E-01). The Art. 4 briefing (capabilities, limits, automation bias, the ladder, the kill levers) is held for persons 1 to 3, attendance recorded.
- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-11` prints `SIGNED`; `for n in AI_ACT_CLASS_DOER AI_ACT_CLASS_EVE AI_ACT_CLASS_MO AI_ACT_ROLE_DOER AI_ACT_ROLE_EVE AI_ACT_ROLE_MO PURPOSE_SHA256_DOER PURPOSE_SHA256_EVE PURPOSE_SHA256_MO AI_ACT_CLASS_TIER_C AI_ACT_ROLE; do "$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-11 "$n" >/dev/null || echo "MISSING $n"; done` prints nothing; for each purpose file, `shasum -a 256` equals its `PURPOSE_SHA256_*` value; the briefing's attendance lists three role codes.
- **ROLLBACK:** a superseding record; a reclassification re-runs 04's row check.
- **EVIDENCE:** `evidence_add PD-5.4 ai-act-classification E-01 7.1 "platform-repo:decisions/<file>"`; `evidence_add PD-5.4 art4-briefing E-13 2.1.3 "build-log:records/<date>-PD-5.4-art4-briefing-v1.md"`. E-01, E-13; TISAX 7.1, 2.1.3.

#### PD-5.5 PV-07: the optional Tier P step, gated now so it is never improvised

- **WHO:** the platform owner drafts; person 2; person 3 as SR; ISMS.
- **WHERE:** block D, slug `pov-optional-tier-p`.
- **ACTION:** Decision: the step is optional and runs only if (a) Eve's POV live record `POV_EVE_H_LIVE_RECORD` exists (06) and the doer's `POV_TIER_W_RECORD` exists (07), (b) PV-06's population is synthetic, (c) person 3 is appointed. It is a **new project** in `fld-agents-p-prod` with a **new `agent_id`** and a new register row, tier P, `privilege: workspace_role:<name>`, `verifier: eve` (the schema's conditional). Exactly two delegated admin role assignments, both scoped to `PILOT_OU`: a read role and a writer role whose privilege list is written into the record and excludes every privilege that can grant roles, change security settings, reset an admin's credentials or act outside the organisational unit. No Super Admin, ever. The Tier P purchases (SIEM, penetration test) are deferred (PV-D-09, PV-D-10, PV-D-11); the step's K6-style drill does not close G11. **Values** (record values read by 07 §7, never set by this file): `PILOT_ADMIN_AGENT_ID` (`Assumption:` `pilot-admin`; legal under PD-3.1's pattern, distinct from `AGENT_ID_DOER` and every reserved id); `PILOT_ADMIN_ROLE_READ_ID` and `PILOT_ADMIN_ROLE_WRITER_ID` = `*tbd*` at signing, because a custom role's id exists only once 07 PW-7.3 creates the roles `Pilot Reader` and `Pilot Writer`; a superseding PV-07 record, with the same four signatories, carries the ids read back with `roles.list` before 07 PW-7.4 assigns either role. The NAMES rows `PILOT_ADMIN_PROJECT`, `PILOT_ADMIN_NONPROD_PROJECT` and `PILOT_ADMIN_ROBOT` are filled by a NAMES supersession under the same gate.
- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-07` prints `SIGNED`; `"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-07 PILOT_ADMIN_AGENT_ID` prints an id that is not `$AGENT_ID_DOER`; `grep -ci 'super admin' "$PLATFORM_REPO_DIR"/decisions/*-pov-optional-tier-p.md` is at least `1` and the reviewer confirms each hit is a prohibition.
- **ROLLBACK:** a superseding record. Not taking the step is a valid outcome and is recorded in 09.
- **EVIDENCE:** `evidence_add PD-5.5 pov-optional-tier-p E-03 1.4.1 "platform-repo:decisions/<file>"`. E-03; TISAX 1.4.1.

## 6. People

#### PD-6.1 Appoint the people with setup/03's appointment records

- **WHO:** ISMS names; each appointee accepts; the platform owner drafts. Finance names the billing administrator.
- **WHERE:** [setup/03](../setup/03-decisions-and-people.md) DC-2.1, DC-2.2 (PPL-IC half), DC-2.3 (PPL-SR only), DC-2.4 and DC-2.7 (PPL-BA; PPL-MO recorded as the platform owner), run as written.
- **ACTION:** seven records: six with full-set ids and full-set constraints, and one POV-only appointment for the engineer. POV mapping, stated in each record's body:

  | Id | POV holder | Variable |
  |---|---|---|
  | PPL-SH | person 2 | `SECOND_HUMAN_EMAIL` |
  | PPL-SO | person 3 | `SECOND_OPERATOR_EMAIL` |
  | PPL-SR | person 3 (PV-D-14) | `SECURITY_REVIEWER_EMAIL` |
  | PPL-BG | person 3, never owner of a graded playbook (PV-D-16) | `BLIND_GRADER_EMAIL` |
  | PPL-IC | IT security, not person 1, `Assumption:` not person 2 | `INCIDENT_COMMANDER_EMAIL` |
  | PPL-BA | finance | `BILLING_ADMIN_EMAIL` |
  | PPL-ENG | the engineer who writes PB-01 to PB-06: internal, or a contractor raised in PD-2.3; **may be person 1** (the one-person case, README §4: 26 to 34 weeks), **never person 2 or person 3** | `ENGINEER_EMAIL` |

  **The engineer (PPL-ENG) is POV-only.** The full build has no engineer appointment: each agent's owner commits that agent's code (setup/README §6, the Wall-E owner row), so the full build supersedes this record with its agent-owner appointments and never reads `ENGINEER_EMAIL`. The record uses setup/03 §4's template and states three separations, each of which follows from a rule already in the set: never the reviewer of a commit they wrote (PB-04 needs "a commit reviewed by someone other than its author"), so **not person 2**, who approves the deploy grant of that code (07 PW-4.3); **not person 3**, who blind-grades the doer and may not own what is graded (PV-D-16); and never a member of the doer's operator or approver groups. The record's Values carry `ENGINEER_EMAIL` and `ENGINEER_SOURCE` (`internal` or `contractor`); a `contractor` record names the contract line PD-2.3 raised. **Sign it in week 1 with the others**: README §8 says the code sets the calendar, and PB-01 to PB-03 start the day the engineer does.

  **Person 3 is appointed before [01](01-conventions-and-variables.md) Part B, not deferred to POV-2** (README §5.1a). 01 PP-5.1 runs `need` on `SECOND_OPERATOR_EMAIL`, and the protected repository it creates needs two human reviewers who are not the author; 04's first step runs `need` on `SECURITY_REVIEWER_EMAIL` and `BLIND_GRADER_EMAIL`. So PPL-SO, PPL-SR and PPL-BG are signed in this step, in week 1, before this file hands back to 01 Part B. If ISMS has not named person 3, this step stays open with a dated note of whom ISMS has asked, no placeholder is signed, and 01 Part B, 03 and 04 wait. The PPL-SH record also closes `BD-P01-1` (01 PP-4.1): it states that the reviewer named before the appointment is this appointee, and a Closures line naming PD-6.1 is added to `DEVIATION_REGISTER`. Then, per signed record:

```bash
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-SH SECOND_HUMAN_EMAIL) && penv_set SECOND_HUMAN_EMAIL "$v"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-SO SECOND_OPERATOR_EMAIL) && penv_set SECOND_OPERATOR_EMAIL "$v"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-SR SECURITY_REVIEWER_EMAIL) && penv_set SECURITY_REVIEWER_EMAIL "$v"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-BG BLIND_GRADER_EMAIL) && penv_set BLIND_GRADER_EMAIL "$v"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-IC INCIDENT_COMMANDER_EMAIL) && penv_set INCIDENT_COMMANDER_EMAIL "$v"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-BA BILLING_ADMIN_EMAIL) && penv_set BILLING_ADMIN_EMAIL "$v"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-ENG ENGINEER_EMAIL) && penv_set ENGINEER_EMAIL "$v"
need SECOND_HUMAN_EMAIL && checkpoint PP-3.4 DONE "$SECOND_HUMAN_EMAIL" - "correction: witness named by PPL-SH (02 PD-6.1)"
```

  The last line is the correcting checkpoint 01 asks for: PP-3.4 was witnessed by the second person before `SECOND_HUMAN_EMAIL` existed.

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PPL-SH PPL-SO PPL-SR PPL-BG PPL-IC PPL-BA PPL-ENG` prints seven `SIGNED` lines (an `UNSIGNED` person-3 id is the stop that holds 01 Part B, 03 and 04); `need SECOND_HUMAN_EMAIL SECOND_OPERATOR_EMAIL SECURITY_REVIEWER_EMAIL BLIND_GRADER_EMAIL` is silent; `grep -n 'BD-P01-1' "$DEVIATION_REGISTER"` shows the row above the `## Closures` line and a Closures line naming PD-6.1; the distinctness check:

```bash
op=$(git -C "$BUILD_LOG_DIR" config user.email)
printf '%s\n' "$op" "$SECOND_HUMAN_EMAIL" "${INCIDENT_COMMANDER_EMAIL:-ic-none}" "${SECOND_OPERATOR_EMAIL:-p3-none}" "${BILLING_ADMIN_EMAIL:-ba-none}" | sort | uniq -d
[ "${SECOND_OPERATOR_EMAIL:-x}" = "${SECURITY_REVIEWER_EMAIL:-x}" ] && [ "${SECOND_OPERATOR_EMAIL:-x}" = "${BLIND_GRADER_EMAIL:-x}" ] && echo "person 3 holds SO, SR and BG as PV-09 records"
[ "${ENGINEER_EMAIL:-e}" != "${SECOND_HUMAN_EMAIL:-h}" ] && [ "${ENGINEER_EMAIL:-e}" != "${SECOND_OPERATOR_EMAIL:-o}" ] && echo "engineer is neither person 2 nor person 3"
```

  Expect no duplicate line from `uniq -d` (the operator's git address is person 1's). `Assumption:` the operator commits the build log with a work address; if not, compare against person 1's work address by eye and note it.
- **ROLLBACK:** superseding appointment records; `penv_set --force` with a build-log line.
- **EVIDENCE:** one `evidence_add PD-6.1 appointment-<role> E-08 1.2.2 ...` per record; checkpoint DONE only once all seven ids are signed, before 01 Part B. E-08; TISAX 1.2.2.

#### PD-6.2 PV-09: separations, when person 3 becomes mandatory, the fallback approver, and SH-REPORTS

- **WHO:** ISMS signs; the platform owner and person 2 sign PV-09. SH-REPORTS is signed by ISMS, ITSEC and the platform owner, never by person 2, who is its subject.
- **WHERE:** block D twice: slug `people-and-separations` (PV-09) and slug `recipient-of-reports-about-second-human` (SH-REPORTS, setup/03 DC-2.2).
- **ACTION:** PV-09's body:
  - **Separations.** Person 1 never approves their own request or grant, never verifies their own evidence, never reviews their own commit. Person 2 is in no doer group and is never a doer operator. Person 3 is not person 1, not the author of what they review, not the owner of a playbook they grade, not a Mo identity. **No service identity is ever the second person** (SD-48). The consent sitting is exactly persons 1 and 2, no screen share. The full set's two super-admin accounts are kept: `sa-1-admin@` for person 1 and `sa-2-admin@` for person 2 ([setup/06](../setup/06-organisation-bootstrap-and-roster.md)); Tier W needs three distinct humans, as setup/03 DC-2.8 counts.
  - **Person 3 is appointed before 01 Part B**, in week 1 (PD-6.1), because the protected repository's two human reviewers, 01 PP-5.1's `SECOND_OPERATOR_EMAIL` and 04's first step already need them. Person 3's duties are, among others: the second human reviewer of every Mo merge (neither the author nor a Mo identity); the grader behind every L3 promotion citing graded evidence; the recipient of Eve's reports whose subject is person 2. If person 3 later leaves or is unavailable, those events are recorded, never waived: a Mo proposal is `REFUSED` and filed as evidence; a promotion is not made; a report about person 2 is `PENDING` unless SH-REPORTS routes it to the incident commander; ISMS appoints a successor by a superseding PPL record. PV-D-14.
  - **The fallback approver.** When person 2 is unavailable during a two-person or IRREVERSIBLE step: stop at the last `DONE` checkpoint and wait. For K0, K1 and K7 no approval is needed, by design. Where the wait itself is harmful (an interrupted lock, a half-done consent sitting), the fallback is person 3, then the incident commander; **never person 1 and never a service identity**. A fallback use is a build-log line and a dated note to person 2 the same day.
  - **Not provable in the POV**, stated so no report implies otherwise: Eve's independence from person 2; super-admin containment (G10, G11, G14, G20, Eve G-7); 24x7 acknowledgement (G2); evidence independent by construction (G1, G-2, G18); band B beyond refusal tests; the prospective toil baseline; anything about real employees.
  - **Values:** `ISMS_EMAIL`; `VERIFIER_OWNER_GROUP`, the address of the group that owns the platform verifier's two-person recomputation at Tier W (PV-D-13), chosen by ISMS, never `<AGENT_ID_DOER>-owners@` and never a group whose only member is person 1 (04 PC-3.2 refuses the doer's owners group, RP-1).
  
  SH-REPORTS body: reports whose subject is person 2 go to the security reviewer (person 3); until PPL-SR is signed, to the incident commander if PPL-IC is signed and the incident commander is not person 2; otherwise they are recorded `PENDING`. Never to person 2 or person 1.

```bash
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-09 ISMS_EMAIL) && penv_set ISMS_EMAIL "$v"
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-09 SH-REPORTS` prints two `SIGNED`; the SH-REPORTS record's signature table has no `SH` row: `grep -c '^| SH |' "$PLATFORM_REPO_DIR"/decisions/*-recipient-of-reports-about-second-human.md` prints `0`; `need ISMS_EMAIL` passes; `"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-09 VERIFIER_OWNER_GROUP` prints an address and `case "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-09 VERIFIER_OWNER_GROUP)" in "${AGENT_ID_DOER}-owners@"*) echo FAIL;; *) echo ok;; esac` prints `ok`; the record states that person 3 is appointed before 01 Part B: `grep -c '01 Part B' "$PLATFORM_REPO_DIR"/decisions/*-people-and-separations.md` is at least `1`.
- **ROLLBACK:** superseding records; the PPL-SR record supersedes SH-REPORTS's interim route as setup/03 DC-2.3 says.
- **EVIDENCE:** `evidence_add PD-6.2 people-and-separations E-08 1.2.2 ...`; `evidence_add PD-6.2 sh-reports E-08 1.6 ...`. E-08; TISAX 1.2.2, 1.6.

## 7. The model

#### PD-7.1 PV-12: pin the model on the `eu` endpoint (WDEC-6, SD-09)

- **WHO:** the platform owner; ITSEC; the DPO (processing location).
- **WHERE:** Google's model pages read on the signing day; block D, slug `model-pin`. Counterpart: setup/03 DC-8.3, whose acceptance rules are kept unchanged.
- **ACTION:** on the signing day, read the candidate's model page and Google's model endpoint locations page, and record in the body with URLs and retrieval date: model id; launch stage GA; served on the `eu` multi-region endpoint; ML-processing locations; retirement date. Accept only if GA on `eu`, retirement at least six months after `POV_END_DATE` **and** after the full build's planned Stage 1, and not a Gemini 2.5 model. The model client location is set to `eu` in agent code. The review's candidate on 2026-09-15 was `gemini-3.5-flash` (setup/03 DC-8.3); on 2026-09-16 Google's model-versions page listed later Flash versions in its navigation, so the signer compares candidates on the day rather than copying that id. Values: `MODEL_ID`.

```bash
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" WDEC-6 MODEL_ID) && penv_set MODEL_ID "$v"
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-12 WDEC-6 SD-09` prints three `SIGNED`; `need MODEL_ID`; `case "$MODEL_ID" in gemini-2.5*|gemini-2-5*) echo "REFUSED: 2.5 family";; *) echo ok;; esac` prints `ok`; the record carries at least two `https://` lines and a retrieval date.
- **ROLLBACK:** a superseding record (the re-pin procedure of setup/42).
- **EVIDENCE:** `evidence_add PD-7.1 model-pin E-11 6.1 "platform-repo:decisions/<file>"`. E-11; TISAX 6.1.

## 8. The toil baseline, taken backwards (PV-05, PV-D-05)

**Why this is not a shortcut.** The full build records four prospective ISO weeks by hand ([setup/02](../setup/02-toil-baseline.md)), gated on a works-council answer: the longest pole before anything starts. Admin log events already record, per event, what the Admin console did and when; Google keeps them for a fixed period that administrators cannot shorten or delete from. So **volume** can be counted backwards now. **Handling time** cannot: a log line has no minutes. The POV therefore takes volume from the logs and per-task medians from a small timed calibration sample, and writes both into setup/02's CSV contract unchanged. **What it may not be used to claim:** human minutes saved above L3. The minutes on retrospective rows are imputed, flagged by `recorder` = `retro`, and Mo's value report shows them as the weakest number (08). The full build still owes the four prospective weeks before a promotion claims time saved and before the S1 review.

**The CSV contract is setup/02's, byte for byte**: header `record_type,date,iso_week,task_id,handling_minutes,interrupted,recorder,month,hours`, UTF-8, LF. How the POV fills it:

| `record_type` | POV content |
|---|---|
| `instance` | one row per counted human-actor event: `date` and `iso_week` from the event; `task_id`; `handling_minutes` = that task's calibration median rounded up to a whole minute (imputed); `interrupted` = `no`, meaning "not observed"; `recorder` = `retro` |
| `task_median` | the same rounded-up calibration median, so the median recomputed over the instance rows equals it exactly |
| `operating_hours` | real programme hours per month per role code (`owner`, `second`, `third`), from the POV's first month onward, as setup/02 TB-3.3 |

No interruption rate is ever computed from `retro` rows; the exact calibration medians, sample sizes and spreads live in `TOIL_RETRO_RECORD`, not in the CSV.

#### PD-8.0 PV-05, first record: the basis for reading six months of Admin log events (blocking for PD-8.2)

- **WHO:** the platform owner drafts; the DPO signs the data-protection answer; HR (or the works-council contact) signs the works-council answer; person 2 signs as IT security. Person 3 does not sign this record; PD-8.3's superseding record adds SR.
- **WHERE:** block D, slug `pov-retrospective-log-reading-basis`, title `PV-05 basis for the retrospective log reading`.
- **ACTION:** the record holds, quoted from their own mails: the DPO's written answer to PD-2.1 point 2 (legal basis, purpose, who reads, the same-day reduction to counts, retention of the reduced counts at PV-10's values) and HR's written answer on whether information or consultation is required before an administrator's logged actions are counted, and, if required, the date it was given. It fixes how the export is handled, so the raw data never lands in a general download folder:
  - the export is saved only into an encrypted disk image created for the purpose and outside every repository, the build log and any Drive-synced folder; the passphrase is typed at the prompt and never written down, stored or shared;
  - the reduction runs the same day; the image is then detached and deleted, which leaves only ciphertext whose passphrase exists nowhere;
  - **the residual risk**, stated for the DPO to accept or refuse: while the image is mounted the export is readable by the logged-in platform owner and any process running as that user; APFS copy-on-write on an SSD means a deleted file's blocks are not overwritten (`rm -P` does not change this); a browser that saved the file elsewhere first (for example `~/Downloads`) would leave a plaintext copy, which PD-8.2's VERIFY looks for.
  - **Values:** `TOIL_RETRO_READ_BASIS` = the DPO's named legal basis; `TOIL_RETRO_RESIDUAL_RISK` = `accepted` or `refused`, as the DPO writes it. `refused` means PD-8.2 does not run and the POV takes setup/02's prospective path.
  - **Gates:** PD-8.2. **PV-D-05.**
- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-05` prints `SIGNED`; `"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-05 TOIL_RETRO_RESIDUAL_RISK` prints `accepted`; the record's signature table has `DPO` and `HR` rows: `grep -cE '^\| (DPO|HR) \|' "$PLATFORM_REPO_DIR"/decisions/*-pov-retrospective-log-reading-basis.md` prints `2`.
- **ROLLBACK:** a superseding record. If the DPO or HR withdraws the basis after PD-8.2 has run, the counts file is withdrawn from the evidence register the same day and the DPO decides its fate in writing.
- **EVIDENCE:** the record and the DPO's and HR's mails in `EVIDENCE_INTERIM_LOCATION`; `evidence_add PD-8.0 pov-retrospective-log-reading-basis E-12 7.1 "platform-repo:decisions/<file>" "$PLATFORM_REPO_DIR/decisions/<file>"`; checkpoint DONE. E-12; TISAX 7.1.

#### PD-8.1 Re-read Google's retention page and fix the window

- **WHO:** the platform owner. No witness.
- **WHERE:** Google Workspace Admin Help, "Data retention and lag times", https://knowledge.workspace.google.com/admin/reports/data-retention-and-lag-times.
- **ACTION:** read the page on the day. Record, quoted: the retention for Admin log events; the lag for Admin log events; the sentence on administrators' ability to delete log data or change retention; the page's "Last updated" date. On 2026-09-16 the page read: Admin log events retained "6 months"; lag "Near real time (couple of minutes)"; "Administrators cannot delete log event data or change the length of time that the data is available for."; last updated 2026-09-10. **Record what the page says on the day, not these words.** Then fix the window: start = the Monday of the first full ISO week inside the retention the page states, counted back from today; end = the Sunday of the last complete ISO week before today.

```bash
checkpoint PD-8.1 START - - "retention re-read and window"
python3 -c 'import sys,datetime as d
m=int(sys.argv[1]); t=d.date.today()
y,mo=t.year,t.month-m
while mo<1: mo+=12; y-=1
s=d.date(y,mo,min(t.day,28)); s=s+d.timedelta(days=(7-s.weekday())%7)
e=t-d.timedelta(days=t.weekday()+1)
print(f"{s.isoformat()}..{e.isoformat()}")' "<months the page states>"
```

  Store the printed value once the record of PD-8.3 is signed (PD-8.3 sets `TOIL_RETRO_WINDOW` from it). Until then write it in the build log.
- **VERIFY:** the printed start is a Monday and the end a Sunday: `python3 -c 'import sys,datetime as d; s,e=sys.argv[1].split(".."); print(d.date.fromisoformat(s).isoweekday()==1 and d.date.fromisoformat(e).isoweekday()==7)' "<the window>"` prints `True`. The build-log record quotes the page and its date.
- **ROLLBACK:** none needed; the step only reads. A re-read on a later day produces `-v2` and a new window.
- **EVIDENCE:** `<date>-PD-8.1-retention-reread-v1.md` in `$BUILD_LOG_DIR/records/`; `evidence_add PD-8.1 retention-reread E-09 5.2.4 "build-log:records/<file>" "$BUILD_LOG_DIR/records/<file>"`; checkpoint DONE with the window. E-09; TISAX 5.2.4.

#### PD-8.2 Count candidate tasks by event and rank them

- **WHO:** the platform owner exports and reduces, with the Audit & Investigation privilege. **Person 2 or person 3, never the platform owner, chooses the tasks kept in ACTION 1 and writes the automation list of ACTION 3**, so the person whose programme the baseline supports does not choose what it counts. No other witness. The volume half is recounted independently by PD-8.6 **in the same ISO week as this step**, while the window's first week is still inside Google's retention. **Waits for the recount route:** this step starts only in a week in which PD-8.6's recounter can act (03 PF-1.5 `DONE`, or PD-8.7's role assigned). **Waits for PD-8.0:** no search is exported before PV-05's basis record carries the DPO's and HR's signed answers and the DPO's acceptance of the residual risk.
- **WHERE:** Admin console: Menu > Reporting > Audit and investigation > Admin log events (Google Workspace Admin Help, "Admin log events", read 2026-09-16). Then shell, `~/.platform-env` sourced.
- **ACTION:**
  0. Gate, then create and mount the encrypted image the record prescribes (`hdiutil` prompts for the passphrase; it is typed, never passed on the command line, never stored):

```bash
source "$HOME/.platform-env"; penv_guard
need PLATFORM_REPO_DIR BUILD_LOG_DIR
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-05 || echo "STOP: PV-05's basis record is not signed; export nothing"
test "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-05 TOIL_RETRO_RESIDUAL_RISK)" = accepted || echo "STOP: the DPO has not accepted the residual risk; export nothing"
img="$HOME/.toil-retro-raw.dmg"; test ! -e "$img" || echo "STOP: $img exists from an earlier run; detach and delete it first"
hdiutil create -encryption AES-256 -size 200m -fs APFS -volname toil-retro-raw "$img"
hdiutil attach "$img"
ls -ld /Volumes/toil-retro-raw
```

  Set the browser to ask where to save each download before exporting, and save every export into `/Volumes/toil-retro-raw/`, nowhere else.
  1. The platform owner lists the admin tasks the team does by hand; person 2 or person 3 keeps only those a catalogue family of the doer's ladder could perform ([wall-e/05-autonomy-ladder.md](../../wall-e/05-autonomy-ladder.md)), with the reason for each removal. These are real Admin console tasks, and the POV doer holds no Workspace admin role, so a kept task may have no operation in PV-01's catalogue: [08](08-mo-and-the-value-report.md) PM-8.4 and [09](09-the-demonstration-deviations-and-the-hand-over.md) PX-1.1 stop where that overlap is empty. Name the ticket system and category field if one exists (`TICKET_SYSTEM`, `TICKET_CATEGORY_FIELD`, or `none`), as setup/02 does.
  2. For each kept task, choose the Admin log event name(s) that mark one instance. In Admin log events, add the filter **Date** with **After** set to the window start (the default shows only the last 7 days) and **Event** set to the event name; search; export the results as a CSV file (not Sheets, which would place a copy with actor addresses in the platform owner's Drive) into `/Volumes/toil-retro-raw/`. Google states an export limit of 100,000 rows on this page; a task at the limit is split into date slices.
  3. Person 2 or person 3 writes the automation actors to exclude (service identities, scripts, existing automation) into `$BUILD_LOG_DIR/records/<date>-PD-8.2-automation-actors-v1.txt`, one address per line. Their events are not human toil.
  4. Reduce each export the same day, reading it from the encrypted volume. The export's column headers are not documented on Google's page (see Unverified): print them first and pass the date and actor column names:

```bash
checkpoint PD-8.2 START - - "retrospective counts"
head -n 1 "<export.csv>"
python3 - "<export.csv>" "<task-id>" "<event name>" "<date column>" "<actor column>" "$BUILD_LOG_DIR/records/$(date -u +%F)-PD-8.2-automation-actors-v1.txt" "$BUILD_LOG_DIR/records/$(date -u +%F)-PD-8.2-retro-counts-v1.csv" <<'PY'
import csv, sys, re, os, collections
src, task, event, dcol, acol, auto, out = sys.argv[1:8]
if not re.fullmatch(r"[a-z0-9-]{3,40}", task): sys.exit("task_id must match ^[a-z0-9-]{3,40}$")
bots = {l.strip().lower() for l in open(auto, encoding="utf-8") if l.strip()}
n = collections.Counter()
for r in csv.DictReader(open(src, newline="", encoding="utf-8")):
    m = re.search(r"\d{4}-\d{2}-\d{2}", r[dcol])
    if not m: sys.exit(f"unparsed date: {r[dcol]!r}; convert the column to ISO dates and re-run")
    n[(m.group(0), "automation" if r[acol].strip().lower() in bots else "human")] += 1
new = not os.path.exists(out)
with open(out, "a", newline="", encoding="utf-8") as f:
    w = csv.writer(f, lineterminator="\n")
    if new: w.writerow(["date","task_id","event_name","actor_class","count"])
    for (d, c), k in sorted(n.items()): w.writerow([d, task, event, c, k])
print(task, "human", sum(k for (d,c),k in n.items() if c=="human"), "automation", sum(k for (d,c),k in n.items() if c=="automation"))
PY
```

  Here `<export.csv>` is always a path under `/Volumes/toil-retro-raw/`. No actor identity leaves the script: the counts file holds date, task, event name, actor class and a count. The raw exports are not kept, because the console holds the same data for the retention period and PD-8.6 recomputes from the console, not from a copy. The counts file holds no address and is kept: once every export is reduced, write its SHA-256 (`shasum -a 256` on the file) in the build log the same day, and copy the file into `PLATFORM_EVIDENCE_BUCKET` once [03](03-foundation-folders-logging-and-floors.md) PF-7.2 has locked the bucket's retention, checking the copy's SHA-256 against that build-log line.
  5. Rank by human monthly volume and keep the three highest, each with a non-zero count.
  6. The same day, once every export is reduced, destroy the raw data by destroying the image (crypto-erase: the passphrase exists nowhere, so the blocks left on the SSD are unreadable ciphertext):

```bash
hdiutil detach /Volumes/toil-retro-raw
rm "$HOME/.toil-retro-raw.dmg"
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-05` printed `SIGNED` before the first export (the checkpoint START line is later than the PD-8.0 DONE line); `test ! -e "$HOME/.toil-retro-raw.dmg" && ! test -d /Volumes/toil-retro-raw && echo "raw image destroyed"` prints `raw image destroyed`; `find "$HOME/Downloads" "$HOME/Desktop" "$BUILD_LOG_DIR" "$PLATFORM_REPO_DIR" -newer "$BUILD_LOG_DIR/checkpoints.tsv" -iname '*.csv' 2>/dev/null` lists no Admin log export (a stray plaintext copy is a finding: deleted the same day, reported to the DPO, logged); `awk -F, 'NR>1 && $4=="human" {s[$2]+=$5} END {for (t in s) print t, s[t]}' "$BUILD_LOG_DIR/records/<date>-PD-8.2-retro-counts-v1.csv"` prints one line per task with a non-zero human count; `grep -c '@' "$BUILD_LOG_DIR/records/<date>-PD-8.2-retro-counts-v1.csv"` prints `0`; `shasum -a 256` on the counts file prints the hash written in the build log; the automation list and the kept column of the ranking table are signed by person 2 or person 3, not by the platform owner; the ranking table in `<date>-PD-8.2-toil-candidates-v1.md` lists task, event name(s), human count, catalogue family and kept `yes`/`no`, and `grep -c '| yes |$'` on it prints `3`.
- **ROLLBACK:** nothing in Google changes; the step only reads. If the day ends before reduction, detach the image and delete it anyway, and export again on a later day. A recount before PD-8.3 is signed replaces the files as `-v2`.
- **EVIDENCE:** the counts file with its SHA-256 in the build log, and later its copy in the locked `PLATFORM_EVIDENCE_BUCKET`; the ranking table and the automation list (the automation list holds service-identity and script addresses only; an employee's own address is never an automation actor and never enters it), each with `evidence_add PD-8.2 <slug> E-09 1.5.1 "build-log:records/<file>" "$BUILD_LOG_DIR/records/<file>"`; checkpoint DONE. E-09; TISAX 1.5.1.

#### PD-8.3 PV-05 and D12: the retrospective baseline and the three tasks

- **WHO:** the platform owner decides; person 3 signs as SR; the DPO and HR sign again, because this record supersedes PD-8.0's and must carry their answers forward.
- **WHERE:** block D, slug `pov-retrospective-toil-baseline`, title `PV-05 D12 retrospective toil baseline`, with a `Supersedes:` line naming PD-8.0's record.
- **ACTION:** the record body quotes PD-8.0's basis, answers and residual-risk acceptance unchanged (and restates `TOIL_RETRO_READ_BASIS` and `TOIL_RETRO_RESIDUAL_RISK` in Values), then: Context (setup/02's four weeks and their gate; PD-8.1's quoted page and date); Options considered (prospective four weeks first; retrospective volume with calibration medians; no baseline); Decision (the second, with the contract table of §8 and what it may not claim); Values `TOIL_TASKS`, `TOIL_BASELINE_FILE` = `metrics/toil_baseline.csv`, `TOIL_RETRO_WINDOW`, `TICKET_SYSTEM`, `TICKET_CATEGORY_FIELD`, and `TOIL_START_DATE` = `*tbd*` (the prospective weeks the full build still owes); Gates (08's value report; the full build's setup/02 TB-3.1 and setup/22 §8); Consequences: the full build's setup/02 TB-1.2 supersedes this record to set `TOIL_START_DATE` and keeps the three tasks, so the prospective and retrospective series measure the same work. **PV-D-05.**

```bash
checkpoint PD-8.3 START - - "PV-05 D12"
for n in TOIL_TASKS TOIL_BASELINE_FILE TOIL_RETRO_WINDOW TICKET_SYSTEM TICKET_CATEGORY_FIELD; do
  v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-05 "$n") || { echo "STOP: no signed $n"; break; }
  penv_set "$n" "$v"
done
```

- **VERIFY:** `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-05 D12` prints two `SIGNED`; `python3 -c 'import sys,re; t=sys.argv[1].split(","); print("3 ids" if len(t)==3==len(set(t)) and all(re.fullmatch(r"[a-z0-9-]{3,40}",x) for x in t) else "FAIL")' "$TOIL_TASKS"` prints `3 ids`; `[ "$TOIL_BASELINE_FILE" = metrics/toil_baseline.csv ] && echo ok`; `"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-05 TOIL_START_DATE` prints `*tbd*`; `grep -cE '^\| (PO|SR|DPO|HR) \|' "$PLATFORM_REPO_DIR"/decisions/*-pov-retrospective-toil-baseline.md` prints `4`.
- **ROLLBACK:** a superseding record before PD-8.5 commits the CSV; after, a new CSV version with a new review (PD-8.6).
- **EVIDENCE:** `evidence_add PD-8.3 pov-retrospective-toil-baseline E-03 1.4.1 "platform-repo:decisions/<file>"`. E-03, E-09; TISAX 1.4.1.

#### PD-8.4 The timed calibration sample

- **WHO:** volunteers among the admins who do the three tasks, under codes `r01`, `r02` and so on; the platform owner holds the code key. **Waits for HR's written answer to PD-2.1 point 7(a)**; if HR requires consultation, the step waits for it and the build log says so.
- **WHERE:** a sheet `toil-calibration` in a restricted folder inside `EVIDENCE_INTERIM_LOCATION`, columns `date`, `task_id`, `handling_minutes`, `interrupted`, `recorder`, as setup/02 TB-2.1's `instances` tab; the code-to-person key in a separate document in the same folder, readable by the platform owner only, never in the repository or the build log.
- **ACTION:** brief the volunteers on setup/02's definitions (handling minutes from pick-up to close, waiting excluded, rounded up; interrupted when other work split it). Time real instances as they occur until each task has at least 10 (`Assumption:` the minimum for a stable median; the record states the number reached). No script, agent or prototype does any of the three tasks during the sample. Then compute per task: n, median, the rounded-up median, and the interquartile range, into `TOIL_RETRO_RECORD`:

```bash
checkpoint PD-8.4 START - - "calibration sample"
python3 - "<calibration.csv>" "$TOIL_TASKS" "$BUILD_LOG_DIR/records/$(date -u +%F)-PD-8.4-toil-calibration-v1.md" <<'PY'
import csv, sys, statistics, math
src, tasks, out = sys.argv[1], sys.argv[2].split(","), sys.argv[3]
v = {t: [] for t in tasks}
for r in csv.DictReader(open(src, newline="", encoding="utf-8")):
    if r["task_id"] in v: v[r["task_id"]].append(int(r["handling_minutes"]))
with open(out, "w", encoding="utf-8") as f:
    f.write("| task_id | n | median | median_rounded_up | q1 | q3 |\n|---|---|---|---|---|---|\n")
    for t, x in v.items():
        if len(x) < 2: sys.exit(f"{t}: fewer than 2 timed instances")
        q = statistics.quantiles(x, n=4)
        f.write(f"| {t} | {len(x)} | {statistics.median(x):g} | {math.ceil(statistics.median(x))} | {q[0]:g} | {q[2]:g} |\n")
print(open(out, encoding="utf-8").read())
PY
penv_set TOIL_RETRO_RECORD "build-log:records/$(date -u +%F)-PD-8.4-toil-calibration-v1.md"
```

- **VERIFY:** the printed table has three rows, each `n` at least the record's stated minimum; `grep -c '@' "$BUILD_LOG_DIR/records/<date>-PD-8.4-toil-calibration-v1.md"` prints `0`; `need TOIL_RETRO_RECORD` passes.
- **ROLLBACK:** extend the sample and write `-v2`; the sheet is never deleted while the POV runs, and the code key is never deleted.
- **EVIDENCE:** `evidence_add PD-8.4 toil-calibration E-09 1.5.1 "$TOIL_RETRO_RECORD" "$BUILD_LOG_DIR/records/<file>"`; the briefing date and codes (never names) in the build log, E-13, TISAX 2.1.3. E-09; TISAX 1.5.1.

#### PD-8.5 Assemble the CSV and verify it against the contract

- **WHO:** the platform owner. Person 3 watches the verify output when present; PD-8.6 is the check in any case.
- **WHERE:** shell, `~/.platform-env` sourced, in `PLATFORM_REPO_DIR` on a branch `toil-baseline`, with setup/02 TB-3.2's branch discipline (clean `main` before, `metrics/` only, back on `main` after).
- **ACTION:**

```bash
need PLATFORM_REPO_DIR BUILD_LOG_DIR TOIL_TASKS TOIL_BASELINE_FILE TOIL_RETRO_WINDOW
checkpoint PD-8.5 START - - "assemble retrospective CSV"
test -z "$(git -C "$PLATFORM_REPO_DIR" status --porcelain)" || echo "STOP: working tree dirty"
test "$(git -C "$PLATFORM_REPO_DIR" rev-parse --abbrev-ref HEAD)" = main || echo "STOP: not on main"
git -C "$PLATFORM_REPO_DIR" switch toil-baseline 2>/dev/null || git -C "$PLATFORM_REPO_DIR" switch -c toil-baseline
mkdir -p "$PLATFORM_REPO_DIR/metrics/reviews"
python3 - "$BUILD_LOG_DIR/records/<date>-PD-8.2-retro-counts-v1.csv" "$BUILD_LOG_DIR/records/<date>-PD-8.4-toil-calibration-v1.md" "<hours.csv with month,recorder,hours>" "$TOIL_TASKS" "$TOIL_RETRO_WINDOW" "$PLATFORM_REPO_DIR/$TOIL_BASELINE_FILE" <<'PY'
import csv, sys, datetime as dt
counts, calib, hours, tasks, window, out = sys.argv[1:7]
tasks = tasks.split(","); s, e = (dt.date.fromisoformat(x) for x in window.split(".."))
med = {}
for line in open(calib, encoding="utf-8"):
    c = [x.strip() for x in line.strip().strip("|").split("|")]
    if c and c[0] in tasks: med[c[0]] = int(c[3])
missing = [t for t in tasks if t not in med]
if missing: sys.exit(f"no calibration median for {missing}")
HEAD = ["record_type","date","iso_week","task_id","handling_minutes","interrupted","recorder","month","hours"]
rows = []
for r in csv.DictReader(open(counts, newline="", encoding="utf-8")):
    if r["actor_class"] != "human" or r["task_id"] not in tasks: continue
    d = dt.date.fromisoformat(r["date"])
    if not s <= d <= e: continue
    y, w, _ = d.isocalendar()
    rows += [["instance", d.isoformat(), f"{y}-W{w:02d}", r["task_id"], str(med[r["task_id"]]), "no", "retro", "", ""]] * int(r["count"])
rows.sort(key=lambda x: (x[1], x[3]))
rows += [["task_median", "", "", t, str(med[t]), "", "", "", ""] for t in sorted(tasks)]
for r in csv.DictReader(open(hours, newline="", encoding="utf-8")):
    rows.append(["operating_hours", "", "", "", "", "", r["recorder"].strip(), r["month"].strip(), f"{float(r['hours']):g}"])
with open(out, "w", newline="", encoding="utf-8") as f:
    wr = csv.writer(f, lineterminator="\n"); wr.writerow(HEAD); wr.writerows(rows)
print("rows", len(rows))
PY
```

  Then the verify, which applies setup/02 TB-4.2's contract checks with the POV's two differences (all instance rows are `retro`; the window replaces four consecutive weeks), with its output saved:

```bash
f="$BUILD_LOG_DIR/records/$(date -u +%F)-PD-8.5-toil-baseline-verify-v1.txt"
python3 - "$PLATFORM_REPO_DIR" "$TOIL_BASELINE_FILE" "$TOIL_TASKS" "$TOIL_RETRO_WINDOW" "${WIKI_DIR:-}" <<'PY' | tee "$f"
import csv, sys, os, statistics, datetime as dt
repo, rel, tasks, window, wiki = sys.argv[1], sys.argv[2], sys.argv[3].split(","), sys.argv[4], sys.argv[5]
s, e = (dt.date.fromisoformat(x) for x in window.split(".."))
HEAD = ["record_type","date","iso_week","task_id","handling_minutes","interrupted","recorder","month","hours"]
bad = []; rr = os.path.realpath(repo)
if wiki and os.path.commonpath([rr, os.path.realpath(wiki)]) == os.path.realpath(wiki): bad.append("repository is under the wiki")
if "/Library/CloudStorage/" in rr or "Google Drive" in rr: bad.append("repository is in a Drive-synced folder")
if rel != "metrics/toil_baseline.csv": bad.append("TOIL_BASELINE_FILE is not metrics/toil_baseline.csv")
p = os.path.join(repo, rel)
if next(csv.reader(open(p, newline="", encoding="utf-8"))) != HEAD: bad.append("header differs from setup/02's contract")
if b"\r\n" in open(p, "rb").read(): bad.append("CRLF line endings")
rows = list(csv.DictReader(open(p, newline="", encoding="utf-8")))
per, weeks = {t: [] for t in tasks}, set()
for r in rows:
    if r["record_type"] not in ("instance", "task_median", "operating_hours"): bad.append(f"unknown record_type {r['record_type']}")
    if r["record_type"] != "instance": continue
    d = dt.date.fromisoformat(r["date"]); y, w, _ = d.isocalendar()
    if r["iso_week"] != f"{y}-W{w:02d}": bad.append(f"iso_week wrong on {r['date']}")
    if not s <= d <= e: bad.append(f"date outside the window {r['date']}")
    if r["task_id"] not in per: bad.append(f"unknown task {r['task_id']}"); continue
    if int(r["handling_minutes"]) <= 0 or r["interrupted"] not in ("yes", "no"): bad.append(f"bad values on {r['date']}")
    if r["recorder"] != "retro": bad.append(f"recorder is not retro on {r['date']}")
    per[r["task_id"]].append(int(r["handling_minutes"])); weeks.add(r["iso_week"])
med = {r["task_id"]: float(r["handling_minutes"]) for r in rows if r["record_type"] == "task_median"}
for t, v in per.items():
    if not v: bad.append(f"no instances for {t}")
    elif t not in med or abs(med[t] - statistics.median(v)) > 0.01: bad.append(f"median wrong or missing for {t}")
if not [r for r in rows if r["record_type"] == "operating_hours" and float(r["hours"] or 0) > 0]: bad.append("no operating_hours row above 0")
print("FAIL:\n" + "\n".join(bad) if bad else f"OK weeks={len(weeks)} instances={sum(map(len, per.values()))} medians={med}")
sys.exit(1 if bad else 0)
PY
git -C "$PLATFORM_REPO_DIR" add "$TOIL_BASELINE_FILE"
git -C "$PLATFORM_REPO_DIR" commit -m "toil baseline: retrospective candidate $TOIL_RETRO_WINDOW"
git -C "$PLATFORM_REPO_DIR" switch main
```

- **VERIFY:** the verify prints `OK` and exits 0; `git -C "$PLATFORM_REPO_DIR" rev-parse --abbrev-ref HEAD` prints `main`; `git -C "$PLATFORM_REPO_DIR" log --oneline main..toil-baseline -- decisions/ | wc -l` prints `0`. Record the commit id, the blob id (`git -C "$PLATFORM_REPO_DIR" rev-parse "toil-baseline:$TOIL_BASELINE_FILE"`) and the SHA-256 of the file in the build log for PD-8.6.
- **ROLLBACK:** `git -C "$PLATFORM_REPO_DIR" switch toil-baseline && git -C "$PLATFORM_REPO_DIR" reset --soft HEAD~1 && git -C "$PLATFORM_REPO_DIR" switch main`, before PD-8.6 is signed and before any push.
- **EVIDENCE:** `evidence_add PD-8.5 toil-baseline-verify E-09 1.5.1 "build-log:records/$(basename "$f")" "$f"`; `evidence_add PD-8.5 toil-baseline-candidate E-09 1.5.1 "platform-repo:$TOIL_BASELINE_FILE@$(git -C "$PLATFORM_REPO_DIR" rev-parse toil-baseline)" "$PLATFORM_REPO_DIR/$TOIL_BASELINE_FILE"`; checkpoint DONE. E-09; TISAX 1.5.1.

#### PD-8.6 The independent recount, the signed review, and the merge

- **WHO:** by default person 2 recounts from `sa-2-admin@`, which holds the Audit & Investigation privilege as a super admin once [03](03-foundation-folders-logging-and-floors.md) has built the roster, with person 3 present; person 3 compares and signs. **Precondition for the default route:** [03](03-foundation-folders-logging-and-floors.md) PF-1.5 is `DONE` (`sa-2-admin@` proven): `awk -F'\t' '$2=="PF-1.5" && $3=="DONE"' "$BUILD_LOG_DIR/checkpoints.tsv"` prints a line. Without it, and without PD-8.7, PD-8.6 waits. Person 3 recounts alone only if ISMS chose that route and PD-8.7's time-boxed role is assigned. Person 1 does not do the checks and does not sign. Two human approvals on the pull request, neither the author, no bot or service identity (file 01's branch protection). **Deadline:** ACTION 1, the volume recount, runs in the same ISO week as PD-8.2, while the window's first week is still inside Google's retention, and its result is written that day as `<date>-PD-8.6-volume-recount-v1.md`, signed by the recounter and person 3. ACTIONs 2 to 4 follow PD-8.5. A volume recount missed in that week cannot be recomputed from the source, and the review record says so.
- **WHERE:** the Admin console, signed in as `sa-2-admin@` (default) or as person 3's own account holding PD-8.7's role; a private copy of the calibration sheet; then shell and the pull-request page. The recount reads on screen and exports nothing.
- **ACTION:**
  1. For one task chosen by person 3, and for two ISO weeks chosen by person 3 inside the window, the recounter repeats PD-8.2's search on screen, without exporting, and counts the human-actor events by hand against the automation list. Compare with PD-8.2's counts file for those weeks, after checking its SHA-256 against PD-8.2's build-log line. Once PD-8.5 has assembled the CSV, the `instance` rows for those weeks must equal the same counts.
  2. In the calibration copy, recompute each median with `=MEDIAN(FILTER(C:C, B:B="<task-id>"))` and compare with the calibration record and the `task_median` rows.
  3. Write `metrics/reviews/<date>-toil-baseline-review.md` with `commit id:`, `blob id:` and `sha256:` lines copied from PD-8.5's build-log entry, the two weeks and counts compared, the counts file's SHA-256 and the volume-recount record, the three medians, the window, the words "handling minutes on retro rows are imputed (PV-D-05)", and the result. Sign, scan, register.
  4. Commit the review record on `toil-baseline` (setup/02 TB-4.4), write `$BUILD_LOG_DIR/reviews/<sha>.md` for each branch commit (setup/02 TB-5.1's pre-push loop), push the branch, open the pull request, merge with `--squash` (never `--admin`), exactly as setup/02 TB-5.1.

> **IRREVERSIBLE**: the merge puts the baseline on protected `main`; it is corrected only by a new reviewed pull request, never by rewriting history, and setup/22's `bq load` reads the merged blob. Confirm first: the volume-recount record is dated in PD-8.2's ISO week; PD-8.5's verify printed `OK`; the review record's `blob id` equals `git rev-parse "toil-baseline:$TOIL_BASELINE_FILE"`; `grep -c '@' "$PLATFORM_REPO_DIR/$TOIL_BASELINE_FILE"` prints `0`; every branch commit has a review record. Gate: PV-05 signed (`decision-need.sh PV-05 D12`).

```bash
need PLATFORM_REPO_DIR PLATFORM_REPO_REMOTE TOIL_BASELINE_FILE SECOND_OPERATOR_EMAIL
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-05 D12
rec=$(ls "$PLATFORM_REPO_DIR"/metrics/reviews/*-toil-baseline-review.md | tail -n 1)
test "$(awk '/^blob id: /{print $3}' "$rec")" = "$(git -C "$PLATFORM_REPO_DIR" rev-parse "toil-baseline:$TOIL_BASELINE_FILE")" && echo "blob id matches"
checkpoint PD-8.6 START "$SECOND_OPERATOR_EMAIL" - "irreversible: merge the retrospective baseline"
```

- **VERIFY:** `blob id matches` printed before the merge; after it, `test "$(git -C "$PLATFORM_REPO_DIR" rev-parse "origin/main:$TOIL_BASELINE_FILE")" = "$(git -C "$PLATFORM_REPO_DIR" rev-parse "toil-baseline:$TOIL_BASELINE_FILE")" && echo "merged blob equals reviewed blob"` (after `git fetch origin`); the pull request shows two human approvals and no bypass.
- **ROLLBACK:** before the merge, a refused review means fix, repeat PD-8.5, sign `-v2`. After the merge, a reverting pull request under the same protection.
- **EVIDENCE:** the review record names which route recounted (person 2 by default, or person 3 under PD-8.7); `evidence_add PD-8.6 toil-baseline-review E-08 1.2.2 "build-log:records/<scan>" "<scan>"`; `evidence_add PD-8.6 toil-baseline-merged E-09 5.2.1 "platform-repo:$TOIL_BASELINE_FILE@<merge commit>"`; `printf 'PD-8.6\tmerged\t%s\t08 bq load\n' "<merge commit>" >> "$BUILD_LOG_DIR/rerun-index.tsv"`; checkpoint DONE with person 3 as witness. E-08, E-09; TISAX 1.2.2, 5.2.1, 5.3.1.

#### PD-8.7 Optional, run before PD-8.6 only if ISMS chooses person 3 as recounter: a time-boxed Audit & Investigation role

The default is that this step is **not run**: person 2 recounts in PD-8.6. The privilege exposes every admin and user log event of every employee, so it is granted only by a signed record, to one account, for the recount, and removed straight after. Workspace offers no expiring role assignment (Google Workspace Admin Help, "Create, edit, and delete custom administrator roles", read 2026-09-16), so the removal is a step, not a timer.

- **WHO:** ISMS and the DPO sign; the platform owner drafts and does not assign; person 2 assigns and unassigns from `sa-2-admin@` (creating a custom role needs a super administrator); person 3 receives the role and confirms its removal.
- **WHERE:** block D, slug `recount-audit-privilege-grant`, title `PV-09 time-boxed audit privilege for the baseline recount`, superseding PD-6.2's PV-09 record (its body quoted unchanged and `ISMS_EMAIL` restated in Values). Then Admin console: Menu > Account > Admin roles; and the Directory API reference page for `roleAssignments.list` with its "Try this method" panel, signed in as `sa-2-admin@`.
- **ACTION:**
  1. The record adds to PV-09: the single privilege, **Services > Security Center > This user has full administrative rights for Security Center > Audit & Investigation** (Google Workspace Admin Help, "Administrator privileges for the security center", read 2026-09-16), and no other; the account (person 3's own admin account, never person 1's, never a service identity); the purpose (PD-8.6's on-screen recount, no export); the DPO's basis (PD-8.0's, extended to this reader); Values `RECOUNT_ROLE_NAME` = `pov-baseline-recount` and `RECOUNT_GRANT_END` = a date no later than seven days after assignment and before the PD-8.6 deadline.
  2. After `decision-need.sh PV-09` prints `SIGNED`: Menu > Account > Admin roles > **Create new role**; name `pov-baseline-recount`; tick only the privilege above; **Create Role**; assign it to person 3's account.
  3. Straight after PD-8.6's volume-recount record is signed, and in any case by `RECOUNT_GRANT_END`: Admin roles > `pov-baseline-recount` > **Admins assigned** > select the admin > **Unassign role**; then delete the custom role, which Google allows only once no admin is assigned.

```bash
source "$HOME/.platform-env"; penv_guard
need PLATFORM_REPO_DIR SECOND_OPERATOR_EMAIL
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-09 || echo "STOP: no signed grant record"
"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-09 RECOUNT_ROLE_NAME
"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-09 RECOUNT_GRANT_END
checkpoint PD-8.7 START "$SECOND_HUMAN_EMAIL" - "time-boxed audit role for the recount"
```

- **VERIFY:** after assignment, `roleAssignments.list` (`GET https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roleassignments` with `userKey` = person 3's account and `includeIndirectRoleAssignments` = `true`, scope `admin.directory.rolemanagement.readonly`) returns exactly one assignment, whose `roleId` is the `pov-baseline-recount` role; the role's privilege page lists exactly one privilege. After unassignment, the same call returns no assignment for that role and the role is no longer listed under Admin roles. Person 3, not person 2, reads the after-state and confirms it by `confirm_manual`.
- **ROLLBACK:** unassign the role and delete it (ACTION 3). A role still assigned after `RECOUNT_GRANT_END` is a severity-2 finding, removed the same day and reported to the DPO; Eve's runs from [06](06-eve-over-the-human-super-admins.md) see the assignment and its removal in Admin log events.
- **EVIDENCE:** the record; the two `roleAssignments.list` responses (before removal and after) as `<date>-PD-8.7-role-assigned-v1.json` and `<date>-PD-8.7-role-removed-v1.json` in `$BUILD_LOG_DIR/records/`, holding the role id and assignment id only (the user key is redacted to `person-3`); `evidence_add PD-8.7 recount-audit-privilege-grant E-08 1.2.2 "build-log:records/<file>" "$BUILD_LOG_DIR/records/<file>"` for each; checkpoint DONE with person 3 as witness once the removal is verified. E-08; TISAX 1.2.2, 4.1.3.

## 9. Closing the part

#### PD-9.1 Prove every record parses and hand over

- **WHO:** the platform owner runs; person 2 reads the output.
- **WHERE:** shell, `~/.platform-env` sourced.
- **ACTION:**

```bash
checkpoint PD-9.1 START "${SECOND_HUMAN_EMAIL:--}" - "POV 02 closing check"
"$PLATFORM_REPO_DIR/tools/decision-need.sh" D7-LETTER PV-01 PV-02 PV-03 PV-04 PV-05 PV-06 PV-08 PV-09 PV-10 PV-11 PV-12 PV-13 NAMES KEYS SD-11 P13 WDEC-6 D12 SH-REPORTS PPL-SH PPL-SO PPL-SR PPL-BG PPL-IC PPL-BA
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-07
"$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 DOER_SCOPES_SHA256
"$PLATFORM_REPO_DIR/tools/decision-check.sh" "$PLATFORM_REPO_DIR"/decisions/20*.md | grep -vc '^OK'
need SECOND_HUMAN_EMAIL SECOND_OPERATOR_EMAIL SECURITY_REVIEWER_EMAIL BLIND_GRADER_EMAIL DPO_CONTACT ISMS_EMAIL INCIDENT_COMMANDER_EMAIL BILLING_ADMIN_EMAIL WORKS_COUNCIL_QUESTION_RECORD AGENT_ID_DOER AGENT_ID_EVE AGENT_ID_MO RESERVED_NAMES_RECORD NAMES_RECORD KEYS_RECORD EVIDENCE_RETENTION_DAYS IDENTITY_RETENTION_DAYS RECORD_RETENTION_DAYS MODEL_ID PILOT_POPULATION_COUNT POV_GATE_LIST POV_END_DATE TOIL_TASKS TOIL_BASELINE_FILE TOIL_RETRO_WINDOW TOIL_RETRO_RECORD && echo "POV-1 values present"
```

- **VERIFY:** the first `decision-need.sh` prints only `SIGNED` lines; the second may print `UNSIGNED` only for PV-07, which is optional and listed in the build-log entry as open (person 3's ids were signed in PD-6.1 before 01 Part B, so an `UNSIGNED` person-3 id here is a stop, not an open item); the `decision-value.sh PV-01 DOER_SCOPES_SHA256` line fails until PD-4.3 is signed in POV-2, which is expected at this point and listed as open, and 07 PW-3.1 refuses until it succeeds; the `grep -vc` prints `0`; `POV-1 values present`. `SECOND_OPERATOR_EMAIL`, `SECURITY_REVIEWER_EMAIL` and `BLIND_GRADER_EMAIL` are set: `need SECOND_OPERATOR_EMAIL SECURITY_REVIEWER_EMAIL BLIND_GRADER_EMAIL` is silent.
- **ROLLBACK:** none needed; the step only reads.
- **EVIDENCE:** the output as `<date>-PD-9.1-closing-check-v1.txt`, registered with `evidence_add PD-9.1 closing-check E-05 1.4.1 ...`; checkpoint DONE. E-05; TISAX 1.4.1.

## Verification checklist for the whole part

- [ ] Every step PD-1.1 to PD-9.1 has a `START` and a `DONE` line: `awk -F'\t' '$2 ~ /^PD-/ && $3=="DONE"' "$BUILD_LOG_DIR/checkpoints.tsv" | wc -l` prints `27`, or fewer with each missing step (PD-4.3 waiting on PB-04 and PB-05, PD-5.5, PD-8.4 waiting on HR, PD-8.6, PD-8.7 when ISMS kept the default route) named `PENDING` or `NOT RUN` in PD-9.1's entry.
- [ ] The letter left on day one and its date equals D7-LETTER's record date.
- [ ] Keys ordered, the seven-day wait figure re-read and recorded, and 03's first sitting booked after it.
- [ ] PV-02 and NAMES signed before any create step; the doer's id is legal and distinct; Wall-E's names and the witness and twin names are `*tbd*` and reserved.
- [ ] KEYS signed with `eve-eu` in `europe`.
- [ ] PV-08 and SD-11 signed before any step of 06.
- [ ] PV-10 carries three integers, the record value inside 400..3650, and was signed before any lock.
- [ ] PV-06 names synthetic accounts only and the three conditions.
- [ ] Every register-row value 04 needs is readable from PV-11.
- [ ] Person 1 and person 2 are distinct; person 3's three ids were signed before 01 Part B; SH-REPORTS is not signed by person 2.
- [ ] `MODEL_ID` is not a Gemini 2.5 model and the record carries page URLs and a retrieval date.
- [ ] The retention page was re-read on the day, and the record quotes the number it gave, not this file's.
- [ ] PV-05's basis record (PD-8.0), with DPO and HR signatures and the residual risk `accepted`, was signed before the first Admin log export; the encrypted image was destroyed the same day and no plaintext export remains on the workstation.
- [ ] If PD-8.7 ran, the role was assigned only after its record was signed and `roleAssignments.list` shows it removed; otherwise the review record names person 2 as recounter.
- [ ] Before 07 PW-3.1: PV-01's superseding record (PD-4.3) carries `DOER_SCOPES_SHA256`, the six-operation catalogue, the backup retention and the K4 line.
- [ ] `metrics/toil_baseline.csv` has setup/02's header exactly, every instance row is `retro`, the counts file and the CSV hold no address, and the merged blob equals the reviewed blob.
- [ ] No step of this file created a Google Cloud or Workspace resource, and `penv_guard` stayed silent.

## What the next file needs from this one

| Consumer | Needs | Form |
|---|---|---|
| [01](01-conventions-and-variables.md) Part B | PV-03 and PV-09 signed; record values `PLATFORM_REPO_NAME`, `BUILD_LOG_REPO_NAME`; `SECOND_HUMAN_EMAIL`, `SECOND_OPERATOR_EMAIL`; `BD-P01-1` closed; PP-3.4's correcting checkpoint | tracker rows, variables |
| [03](03-foundation-folders-logging-and-floors.md) | PV-02, PV-03, PV-10, PV-11 signed; `NAMES_RECORD`, `KEYS_RECORD`, `EVIDENCE_RETENTION_DAYS`, `RECORD_RETENTION_DAYS`; SD-01, SD-16, P31 signed; `BILLING_ADMIN_EMAIL`; `SECOND_HUMAN_EMAIL` for the lock witness; keys enrolled and past the wait | tracker rows, variables |
| [04](04-the-contract-register-agent-ids-and-schemas.md) | `AGENT_ID_DOER`, `AGENT_ID_EVE`, `AGENT_ID_MO`, `RESERVED_NAMES_RECORD`, `NAMES_RECORD` (with `DOER_AUDIT_DS`), PV-01, PV-02, PV-09's `VERIFIER_OWNER_GROUP`, PV-11 values `AI_ACT_CLASS_DOER`, `PURPOSE_SHA256_DOER`, `PURPOSE_SHA256_EVE`, `PURPOSE_SHA256_MO`, `MODEL_ID`, `SECURITY_REVIEWER_EMAIL`, `BLIND_GRADER_EMAIL` | variables; `decision-value.sh PV-11 ...` |
| [05](05-gemini-enterprise-and-tier-c.md) | PV-11 (record values `AI_ACT_CLASS_TIER_C`, `AI_ACT_ROLE`), PV-12, SD-19, `MODEL_ID`, `DPO_CONTACT` | tracker rows, variables |
| [06](06-eve-over-the-human-super-admins.md) | PV-08 and SD-11 (blocking), PV-09, SH-REPORTS, PV-10, `SECOND_HUMAN_EMAIL`, `SECURITY_REVIEWER_EMAIL` or the interim route, `DPO_CONTACT`, `KEYS_RECORD`, `NAMES_RECORD`, `EVIDENCE_RETENTION_DAYS` | tracker rows, variables |
| [07](07-the-doer-tier-w-and-the-optional-tier-p.md) | PV-01 as superseded by PD-4.3 (record values `DOER_SCOPES_SHA256`, `DOER_OPERATION_CATALOGUE`, `DOER_FIRESTORE_BACKUP_RETENTION`, `DOER_K4_SCHEDULE`, `K4_RESIDUE_MAX_SECONDS`), PV-02, PV-03 (`SERVICE_IDENTITY_OU`, `DOER_PROJECT`, `DOER_NONPROD_PROJECT`, `DOER_ROBOT`, `DOER_AUDIT_DS`, the `PILOT_ADMIN_*` names), PV-06 (`PILOT_OU`, `NONPROD_OU`), PV-07 (`PILOT_ADMIN_AGENT_ID`, the two role ids), PV-12, SD-48; `PILOT_POPULATION_COUNT`, `SECOND_OPERATOR_EMAIL`, `BLIND_GRADER_EMAIL`, `MODEL_ID` | tracker rows, variables |
| [08](08-mo-and-the-value-report.md) | PV-05, PV-09; `TOIL_BASELINE_FILE` merged, `TOIL_TASKS`, `TOIL_RETRO_RECORD`, `TOIL_RETRO_WINDOW`; `SECURITY_REVIEWER_EMAIL`, `BLIND_GRADER_EMAIL` | merged CSV at the re-run row; variables |
| [09](09-the-demonstration-deviations-and-the-hand-over.md) | PV-04, PV-13, `POV_END_DATE`, `POV_GATE_LIST`; PV-01's `K4_RESIDUE_MAX_SECONDS` (PD-4.3); the not-provable list of PV-09; the deviation ids cited here | records |
| The full build ([setup/03](../setup/03-decisions-and-people.md), [setup/02](../setup/02-toil-baseline.md), [setup/22](../setup/22-mo-foundations.md)) | the POV records under their full-set ids, to be read or superseded, never re-decided; `DPO_CONTACT` set from D7-LETTER's Values; `TOIL_START_DATE` still `*tbd*` | tracker |

Consumes: `PLATFORM_ENV_FILE`, `PLATFORM_REPO_DIR`, `BUILD_LOG_DIR`, `EVIDENCE_REGISTER`, `EVIDENCE_INTERIM_LOCATION` (signature mails and the calibration sheet), `PLATFORM_REPO_REMOTE` (PD-8.6 only), `WIKI_DIR` if file 01 set it (PD-8.5's location check only), and the helpers `penv_set`, `need`, `penv_guard`, `checkpoint`, `evidence_add` with the three decision tools, all from [01](01-conventions-and-variables.md).

Produces: PV-01 to PV-13; `SECOND_HUMAN_EMAIL`, `SECOND_OPERATOR_EMAIL`, `SECURITY_REVIEWER_EMAIL`, `BLIND_GRADER_EMAIL`, `DPO_CONTACT`, `ISMS_EMAIL`, `INCIDENT_COMMANDER_EMAIL`, `BILLING_ADMIN_EMAIL`, `WORKS_COUNCIL_QUESTION_RECORD`, `AGENT_ID_DOER`, `AGENT_ID_EVE`, `AGENT_ID_MO`, `RESERVED_NAMES_RECORD`, `NAMES_RECORD`, `KEYS_RECORD`, `EVIDENCE_RETENTION_DAYS`, `IDENTITY_RETENTION_DAYS`, `RECORD_RETENTION_DAYS`, `MODEL_ID`, `PILOT_POPULATION_COUNT`, `POV_GATE_LIST`, `POV_END_DATE`, `TOIL_TASKS`, `TOIL_BASELINE_FILE`, `TOIL_RETRO_WINDOW`, `TOIL_RETRO_RECORD`; also `TICKET_SYSTEM` and `TICKET_CATEGORY_FIELD` (setup/02's names), and the full-set records D7-LETTER, NAMES, KEYS, SD-11, P13, WDEC-6, D12, SH-REPORTS and the six PPL ids.

## Sources checked on 2026-09-16

- Google Workspace Admin Help, "Data retention and lag times", https://knowledge.workspace.google.com/admin/reports/data-retention-and-lag-times (last updated 2026-09-10): Admin log events retained "6 months"; lag "Near real time (couple of minutes)"; "Administrators cannot delete log event data or change the length of time that the data is available for."
- Google Workspace Admin Help, "Admin log events", https://knowledge.workspace.google.com/admin/reports/admin-log-events (last updated 2026-09-10): path Menu > Reporting > Audit and investigation > Admin log events; the Audit & Investigation administrator privilege; the last 7 days shown by default; Date filter with Before and After; filters on event and actor; export to Sheets or CSV with a 100,000-row limit (30 million with the security investigation tool).
- Google Workspace Admin Help, "Create, edit, and delete custom administrator roles", https://knowledge.workspace.google.com/admin/users/create-edit-and-delete-custom-admin-roles: Menu > Account > Admin roles; Create new role; Admins assigned > Unassign role; a custom role is deleted only once no admin is assigned; no time-limited assignment is described.
- Google Workspace Admin Help, "Administrator privileges for the security center", https://knowledge.workspace.google.com/admin/security/admin-privileges-for-the-security-center: the Audit & Investigation privilege under Services > Security Center.
- Google Workspace Admin SDK, Directory API, "Method: roleAssignments.list", https://developers.google.com/workspace/admin/directory/reference/rest/v1/roleAssignments/list: `GET .../customer/{customer}/roleassignments`, `userKey`, `roleId`, `includeIndirectRoleAssignments`; scopes `admin.directory.rolemanagement` or `.readonly`.
- macOS `hdiutil(1)` manual page on the workstation, read 2026-09-16: `create -encryption AES-256 -size -fs -volname`, `attach`, `detach`.
- Google Account Help, "Use a security key for 2-Step Verification", https://support.google.com/accounts/answer/6103523: "You may need to wait 7 days before a newly added security key is available at sign-in", faster with an already trusted passkey or security key.
- Google Cloud, "Model versions and lifecycle", https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions: the page exists and its navigation lists Gemini 3.5 to 3.8 Flash guides; its lifecycle table was not readable (see below).
- In the wiki: [setup/03](../setup/03-decisions-and-people.md) §4 (DC-1.1 to DC-1.4), §5, §8 (DC-5.1, DC-5.2), DC-3.1, DC-3.2, DC-4.8, DC-8.3, §11; [setup/02](../setup/02-toil-baseline.md) CSV contract, TB-2.1, TB-3.2, TB-4.2, TB-4.4, TB-5.1; [setup/04](../setup/04-purchases-and-lead-times.md) §4, PU-4.0 to PU-4.2; [setup/42](../setup/42-gates-drills-and-evidence.md) preconditions (`RECORD_RETENTION_DAYS` 400..3650); [05-registry-and-autonomy-contract.md](../05-registry-and-autonomy-contract.md) §3; [08-data-logging-retention-sovereignty.md](../08-data-logging-retention-sovereignty.md) §5.2; [10-eu-ai-act.md](../10-eu-ai-act.md) §5; [11-tisax.md](../11-tisax.md) §13.

## Unverified

- **The column headers and date format of the Admin log events CSV export** are not documented on Google's page. PD-8.2 prints the header and takes the column names as arguments, and stops on a date it cannot parse, rather than assuming them.
- **Whether a single event name maps to one task instance** is a judgement per task; Google does not document the event names as task units. PD-8.2 records the event names chosen and person 3 checks two weeks by hand.
- **The retention figure itself** is re-read on the day (PD-8.1); this file quotes it only as read on 2026-09-16.
- **The model lifecycle table**: on 2026-09-16 the fetched model-versions page did not expose its release and retirement dates, so no retirement date is stated here. PD-7.1 reads the page and the endpoint-locations page on the signing day.
- **The lead time for a dedicated EUR billing account** (2 to 5 business days) and the same-day licence assignment are assumptions, not Google statements.
- **Whether a custom role with only the Audit & Investigation privilege can be limited to Admin log events** rather than every audit log it covers: Google's privilege page does not describe a narrower privilege, so PD-8.7 treats the grant as exposing all log events and keeps person 2's recount as the default.
- **Where a CSV export from Admin log events lands**: Google's page says results can be exported "to Sheets or to a CSV file" but does not say whether the CSV is a browser download or a Drive file. PD-8.2 assumes a browser download saved into the encrypted image; if the console instead creates a Drive file, the step stops, the file is removed from Drive the same day and the DPO is told before a second attempt.
- **Deleting the raw export**: on APFS on an SSD, deleting a file (with or without `rm -P`) does not overwrite its blocks. PD-8.2 therefore keeps the export only inside an AES-256 encrypted disk image whose passphrase is never stored, and destroys the image the same day; the residual exposure while it is mounted is recorded in PD-8.0 as a risk the DPO accepts or refuses.
