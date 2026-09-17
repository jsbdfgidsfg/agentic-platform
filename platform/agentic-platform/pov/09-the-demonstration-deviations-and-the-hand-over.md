# POV 09. The demonstration, the deviations, the hand-over and Track B costed

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-17
- Last executed: never
- Part of: the proof-of-value (POV) set whose entry point is [README.md](README.md). Full-set
  counterparts: [../setup/42-gates-drills-and-evidence.md](../setup/42-gates-drills-and-evidence.md)
  (drills, tabletop, evidence pack), [../setup/README.md](../setup/README.md) §7 to §10 (gates,
  BLOCKED, re-run and decision indexes), and for Track B only
  [../setup/21](../setup/21-sandbox-tenant-and-nonprod-foundation.md),
  [37](../setup/37-wall-e-sandbox-rehearsal.md) and [38](../setup/38-super-admin-gate-and-grant.md).
- Step prefix: `PX` (not used by the full set, [../setup/README.md](../setup/README.md) §5.1).
  22 steps in nine parts.
- **BLOCKED (inherited, none opened here):** PX-1.2 to PX-1.7 wait on PB-04 and PB-05 (the doer's
  action service and consent bootstrap, file 07) and PB-01 (its audit tables); PX-1.9 waits on
  PB-02 and PB-03 (Eve's schemas and SQL, file 06); PX-1.10 waits on PB-06 (Mo's pack, file 08).
  Estimates are those of [README.md](README.md) §8, all `Assumption:`.
- **IRREVERSIBLE:** PX-1.7 (K4 consumes the doer's credential), PX-2.1 and PX-3.3 (objects written
  under a locked retention policy), PX-7.1 (a fourth `agent_id` is permanent), PX-9.1 (the signed
  stop-or-continue record is append-only).
- Hands-on: `Assumption:` 2 days across three people, 1 week elapsed (README §5.2).
- Consumes: everything produced by files 01 to 08 (named per step and in "Preconditions"),
  `POV_CLAIM_STATEMENT` and `POV_STAGE_DATES` (README), PV-04 and PV-13 (file 02).
- Produces: `POV_DEMO_DIR`, `POV_DEMO_RECORD`, `K0_DRILL_RECORD`, `K1_DRILL_RECORD`, `K4_DRILL_RECORD`,
  `K7_POV_DRILL_RECORD`, `POV_TABLETOP_RECORD`, `EVIDENCE_PACK_DIR`, `PV_DEVIATION_REGISTER`,
  `POV_GAP_STATEMENT`, `HANDOVER_TABLE`, `FOURTH_AGENT_RECORD`, `TRACK_B_ESTIMATE`,
  `POV_STOP_OR_CONTINUE_RECORD`, `POV_CLOSING_REPORT`.
- Commands and console paths checked against Google's documentation on 2026-09-16 ("Checked
  against Google's documentation"). What could not be settled is in "Could not verify".

## What this part builds

Nothing new in the cloud. This part **runs** what files 01 to 08 built, in front of the people
who must believe it, and then writes down honestly what it proved and what it did not:

1. One rehearsal and one recorded demonstration: a human prompt, the L1 record, an approved L3
   execution and its exact inverse; K0 pulled live by person 3 during that run; K1, K3, K4 and K7
   timed; Eve reporting a planted human super-admin action to person 2; Mo's digest.
2. A two-hour tabletop run by the incident commander.
3. The evidence pack, every record with its E-xx id ([../10-eu-ai-act.md](../10-eu-ai-act.md) §5)
   and TISAX control id ([../11-tisax.md](../11-tisax.md) §13), copied to the locked bucket.
4. The POV deviation register PV-D-01 to PV-D-16 in full (§4).
5. What was not proved, in the words a hostile reviewer would use (§5).
6. The hand-over map from the POV to setup/01 to 42 (§6), including the row that setup/30 to 39
   create Wall-E fresh in `WALLE_PROJECT`, reusing the POV's code, schemas, ladder, consent
   procedure and kill switch.
7. The fourth-agent test, timed (§7).
8. Track B costed with four humans (§8).
9. A dated stop-or-continue record, and the closing report. **Nothing is torn down in either
   outcome** (PV-13).

The absolutes of [README.md](README.md) §2 bind every step. In particular: the model holds no
credential and cannot approve; K0 and K1 need no approval to pull, but lifting a halt or an
override raises autonomy and is therefore a two-person act; no Track A result is reported as
evidence about a super admin.

## Preconditions

- [ ] `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-01 PV-04 PV-09 PV-10 PV-13` prints five
      `SIGNED` lines, and `decision-value.sh PV-01 K4_RESIDUE_MAX_SECONDS` prints a number (PX-1.7).
- [ ] Files 01 to 08 have a `DONE`, `BLOCKED` or `PENDING` checkpoint on their last step. A
      `BLOCKED` or `PENDING` line is carried into the gap statement (§5); it is never read as done.
- [ ] `need` is silent for: `BUILD_LOG_DIR`, `PLATFORM_REPO_DIR`, `EVIDENCE_REGISTER`,
      `DEVIATION_REGISTER`, `DRILL_CALENDAR`, `EVIDENCE_INTERIM_LOCATION`, `RETIRED_NAMES_CHECK`,
      `REGION` (01); `SECOND_HUMAN_EMAIL`, `SECOND_OPERATOR_EMAIL`, `SECURITY_REVIEWER_EMAIL`,
      `BLIND_GRADER_EMAIL`, `INCIDENT_COMMANDER_EMAIL`, `ISMS_EMAIL`, `DPO_CONTACT`,
      `AGENT_ID_DOER`, `POV_END_DATE`, `TOIL_TASKS` (02); `ORG_ID`, `FLD_AGENTIC_PLATFORM`,
      `FLD_AGENTS_W_NONPROD`, `PLATFORM_EVIDENCE_BUCKET`, `K7_POLICY_DIR`, `POV_K7_FIRST_DRILL_RECORD`,
      `PAM_ENTITLEMENTS`, `SA_1_ADMIN`, `SA_2_ADMIN` (03); `REGISTER_PATH`, `MANUAL_PARSE_RECORD`
      (04); `GEMINI_PROJECT`, `GEMINI_APP_ID`, `GE_INVENTORY_DIR`, `POV_TIER_C_RECORD`,
      `KILL_DRILL_RECORD_C` (05); `EVE_PROJECT`, `EVE_DS`, `EVE_CONFIG_REPO`,
      `POV_EVE_FIRST_RUN_RECORD`, `POV_EVE_H_LIVE_RECORD` (06); `DOER_PROJECT`,
      `DOER_NONPROD_PROJECT`, `DOER_AUDIT_DS`, `PILOT_OU`, `SERVICE_IDENTITY_OU`, `DOER_ACTIONS_URL`,
      `DOER_APPROVAL_A_URL`, `DOER_AGENT_PRINCIPAL`, `DOER_TOKEN_VERSION`,
      `DOER_CONSENT_SITTING_RECORD`, `DOER_RESTORE_DRILL_RECORD`, `POV_TIER_W_RECORD`,
      `KILL_DRILL_RECORD_W` (07); `MO_DIGEST_RECORD`, `POV_VALUE_REPORT`, `MO_PROPOSAL_1_OUTCOME`,
      `MO_PROPOSALS` (08). No bare full-set record name (`TIER_C_RECORD`, `TIER_W_RECORD`,
      `EVE_H_LIVE_RECORD` and the others of [README.md](README.md) §7.3) is read here: each is
      unset by the POV and is re-derived by the full-set file that owns it (§6).
- [ ] Every name this file `need`s is set by some POV file, so no `need` waits on a retired
      spelling. Person 3 runs the line below; for each name it prints, person 3 writes beside it
      the file and step that set it indirectly (a loop such as file 03's folder loop, a
      `decision-value.sh` read, or a setup step run unchanged such as setup/16's for
      `REGISTER_PATH`), or that this file sets it (`K4_DRILL_RECORD`); a name with neither is a
      stop:
      `P="$WIKI_DIR/platform/agentic-platform/pov"; grep -hoE '^(source [^;]*; )?need [A-Z0-9_ ]+' "$P/09-the-demonstration-deviations-and-the-hand-over.md" | sed 's/.*need //' | tr ' ' '\n' | sort -u | while read -r n; do [ -n "$n" ] && ! grep -qE "penv_set +(--force +)?$n\b" "$P"/0[1-9]-*.md && echo "$n"; done`
- [ ] `KILL_DRILL_RECORD_W` (which holds the K2 drill) and `POV_K7_FIRST_DRILL_RECORD` are younger than 30
      days on the demonstration day, the same window [../setup/42](../setup/42-gates-drills-and-evidence.md)
      GD-5.2 and GD-5.3 apply. Older: re-run them in their own files first.
- [ ] `need GRP_DOER_OPERATORS DOER_ROBOT` is silent (07) and person 2 is **not** a member of the
      doer's operators group, read on the demonstration day by person 3 (not person 1):
      `gcloud identity groups memberships check-transitive-membership --group-email="$GRP_DOER_OPERATORS" --member-email="$SECOND_HUMAN_EMAIL"`
      does not print `hasMembership: true`, and the direct list
      `gcloud identity groups memberships list --group-email="$GRP_DOER_OPERATORS" --format='value(preferredMemberKey.id)' | grep -ixc "$SECOND_HUMAN_EMAIL"`
      prints `0` (the transitive check's output field and licence requirement are in "Could not
      verify"; the direct list is the one that must pass). A match stops the file: it is a
      breach of PV-09, recorded as a finding, and the membership is removed before any beat.
- [ ] **The audit-stream catalogue exists.** Before PV-01's operation catalogue was signed, file 07
      recorded, for each of the doer's six operations, which Google audit stream and event name it
      produces, read from a real event (a membership change made by a group manager through the
      API is recorded in **Groups Enterprise log events**, not necessarily in Admin log events;
      Google's Groups Enterprise log events page, updated 2026-09-10). `Assumption:` the record is
      file 07's PV-01 catalogue with a `stream` and `event_name` column. If it does not exist,
      PX-1.3's write-ahead check cannot be run: record `checkpoint PX-1.3 PENDING - - "07: audit
      stream per operation"` and do not start the recorded run. File 06 PE-11.2's reconciliation
      reads the same catalogue, per operation.
- [ ] **The baseline's recount was in time.** File 02 PD-8.6 has a `DONE` line whose date is inside
      Google's 6-month retention of the first week of the PD-8.2 window, and the PD-8.2 counts file
      (address-free) with its SHA-256 is in `PLATFORM_EVIDENCE_BUCKET`. If either is missing, §5
      item 5 says the volume half is attested, not reproducible, and PV-D-05 records it.
- [ ] **The level the evidence allows is read, not assumed.** Person 3 reads the doer's merged
      `LADDER_FILE` (file 07 PW-6.2) for the family of the chosen operation and writes `L3` or `L2`
      into `$POV_DEMO_DIR/level.txt` before PX-1.3. `L2` means the family has fewer graded items
      than `promotion_floor_n: 35` (file 08's `gates.yaml`) with the 5 to 10 synthetic accounts of
      PV-06; the platform floor is not loosened, and PX-1.3 and PX-1.4 then run their **L2 form**
      below.
- [ ] **The hand-built agent projects can be imported without drift (PV-D-01).** Each project's
      run spec `factory/runs/<agent_id>-<env>.json` was merged before the project existed, and its
      last checker run printed `ZERO-DIFF` **without** `--accept-pending`: `EVE_PROJECT` (file 06
      PE-1.1a, then PE-9.1a), `DOER_PROJECT` and `DOER_NONPROD_PROJECT` (file 07 PW-1.7a, then
      PW-5.3a), `MO_PROJECT` (file 08 PM-1.1a, then PM-2.1a). Check:
      `for s in PE-9.1a PW-5.3a PM-2.1a; do grep -qE "${s//./\\.}[[:space:]]+DONE" "$BUILD_LOG_DIR/checkpoints.tsv" && echo "$s DONE" || echo "$s MISSING"; done`
      prints three `DONE` lines. A step that is not `DONE`, or a later `DIFF`, is carried into §5
      item 13 and §6 row 17 as rework, and PV-D-01's "import plans no changes" is struck for that
      project; the claim is made only for the projects that pass.
- [ ] The demonstration window is announced one business day ahead to IT security's desk and to
      person 2, as [../setup/18](../setup/18-model-armor-floor-spikes-and-kill-switch.md) KS-6.1
      does. **Person 2 is not told the time of PX-1.9's planted action** (DR-P06-1).

## People

| Role | Steps | Present |
|---|---|---|
| Person 1, the platform owner and operator | runs the sittings; prompts the doer; plants the Eve action (PX-1.9); writes records | throughout; verifies none of their own evidence |
| Person 2, the second person (IT security) | **witness and reader of the audit** for PX-1.3 to PX-1.7, never an approver on the doer's approval page (they are in no doer group, PV-09; the page's IAP admits `GRP_DOER_OPERATORS` only, file 07 PW-4.5); approves the PAM grants of PX-1.6 and PX-1.7 (IAM, not the page); witnesses K3, K4, K7; receives Eve's page alone (PX-1.9); co-signs the demo record, the register and the stop-or-continue record | throughout, except that they are not told when PX-1.9 happens |
| Person 3, second operator, blind grader, part-time security reviewer | member of `GRP_DOER_OPERATORS`; **approves person 1's L3 plan** (PX-1.3, PX-1.4), the halt clear (PX-1.4), the K1 lift (PX-1.5) and the inverse (PX-1.7), as file 07's People table assigns; **pulls K0 live with no approval** (PX-1.4) and K1 (PX-1.5); verifies the evidence pack (PX-3.2); co-signs the gap statement | PX-1.2 to PX-1.7, PX-2.1, PX-3.2, PX-5.1 |
| Incident commander | runs the tabletop, never the platform owner (PX-2.1) | PX-2.1 |
| ISMS | receives the evidence pack; signs PV-13's record | PX-3.3, PX-9.1 |
| DPO, AI compliance owner, works council or HR contact | tabletop participants; receive the closing report | PX-2.1, PX-9.2 |
| A colleague with no admin role and no `discoveryengine` role | the fourth-agent visibility test (PX-7.1) | about 30 minutes |

Two hands-on people plus a named third is PV-D-14. Nothing in this file needs persons 4 and 5;
they are costed in §8 only.

**Who approves on the doer's page.** The POV has exactly one operator who is not the requester:
person 3. Every two-person act on the approval page in §1 is therefore person 1 requesting and
person 3 approving; a requester never approves their own request (absolute 4). Person 3 pulling K0
or K1 and then approving its lift is allowed: pulling is a lowering that needs no approval, and the
lift is still two people (person 1 requests, person 3 approves). If an act would need two approvers
other than the requester, it needs a second operator who is neither person 1 nor person 2; the POV
has none, so that act is `BLOCKED` on PV-09, never given to person 2. Adding person 2 to any doer
group to make the demonstration run is a defect: it breaks PV-09's separation and makes them the
approver of actions Eve reports to them.

## 1. The demonstration

**Rules for the whole part.** One rehearsal on the doer's nonprod deployment, then one recorded
run on production against `PILOT_OU`'s synthetic accounts only (PV-06). Every timing is read from
a Google-written log or from the insert-only audit, never from a stopwatch alone. A target missed
is a finding recorded in the demo record, never a silent repeat. Every command in this part runs in
a sitting opened with POV 01 PP-2.2's block. The control levers K0, K1 and K4 are pulled from the
approval page, setup/33's primary path, and no terminal token is used for them; K3 is an IAM change
under a PAM grant (PX-1.6). File 07 derives `${A}-operators-caller@` for its own commissioning
drill (PW-6.3), but no variable names it, and no step here calls a control endpoint through it.

### PX-1.1 Open the drill rows and fix the script

**WHO:** Platform owner; person 2 reviews the script.
**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** Pick the operation for the run from file 08 PM-8.4's task-to-operation overlap record:
the operation matched to the highest-ranked matched task in `TOIL_TASKS`, with an exact inverse in
`DOER_ALLOWLIST_FILE` (file 07). **Stop rule, the same as PM-8.4's:** if the overlap record matches
no task (`MATCHED` is `0`), pick any catalogued operation with an exact inverse; the demonstration
then shows no minutes figure and claims no time saved for it, and PX-1.10 shows the stop-rule
sentence instead. Write the script, one line per beat, with who acts and which record proves it.

```bash
need BUILD_LOG_DIR DRILL_CALENDAR TOIL_TASKS AGENT_ID_DOER
checkpoint PX-1.1 START
DEMO="$(date -u +%F)-POV-DEMO"
penv_set POV_DEMO_DIR "$BUILD_LOG_DIR/records/$DEMO"   # writes once; every later sitting reads it back
source ~/.platform-env; need POV_DEMO_DIR; DD="$POV_DEMO_DIR"; mkdir -p "$DD"
printf '%s\n' "# POV demonstration script ($DEMO)" \
  "1 person 1 prompts the doer in Gemini Enterprise (operation from TOIL_TASKS; target in PILOT_OU)" \
  "2 the L1 shadow rows of the same operation are shown from the audit (file 07)" \
  "3 the L3 plan is frozen; person 3 approves on the approval page; execution; verification; person 2 witnesses and reads the audit" \
  "4 the used approval is replayed and must be refused" \
  "5 a multi-item L3 run starts (person 3 approves); person 3 pulls K0 during it; person 1 requests and person 3 approves the clear" \
  "6 person 3 pulls K1; person 1 requests and person 3 approves the lift" \
  "7 K3 on the agent principal, restored under a PAM grant person 2 approves" \
  "8 K4 revoke; warm check; re-consent sitting" \
  "9 K7 on fld-agents-w-nonprod" \
  "10 the inverse operation restores the target (person 3 approves)" \
  "11 Eve's report of the planted action reaches person 2 (unannounced)" \
  "12 Mo's digest and value report are walked through" > "$DD/script.md"
git -C "$BUILD_LOG_DIR" add "records/$DEMO/script.md" && git -C "$BUILD_LOG_DIR" commit -m "PX-1.1 demo script"
checkpoint PX-1.1 DONE "$SECOND_HUMAN_EMAIL" "build-log:records/$DEMO/script.md" "script reviewed"
```

**Resuming.** The demonstration spans several sittings (PX-1.7's consent sitting at least). Every
later step opens with `source ~/.platform-env; need POV_DEMO_DIR; DD="$POV_DEMO_DIR"` and follows
[README.md](README.md) §12: restart at the first PX-1.x step with no `DONE` line. PX-1.1 is never
re-run once `POV_DEMO_DIR` is set (a new directory would orphan `run-start.txt`).

K7 runs after K4, never before: KF-1 refuses every Cloud Run invocation in the folder, which would
make the K4 control unreachable ([../04-identity-and-privileged-access.md](../04-identity-and-privileged-access.md)
§9.7). The inverse (beat 10) runs after the credential is restored by PX-1.7.

**VERIFY:** `need POV_DEMO_DIR` is silent in a fresh shell; the chosen operation is the one
PM-8.4's overlap record matches to the highest-ranked matched task in `TOIL_TASKS`, or, when
`MATCHED` is `0`, a catalogued operation picked under the stop rule; it appears in
`DOER_ALLOWLIST_FILE` with an inverse; person 2's review comment names the
commit; no line of `script.md` names person 2 as an approver on the page; `DR-P09-1` and `DR-P09-2` exist in
`DRILL_CALENDAR` (`grep -c '^| DR-P09-' "$DRILL_CALENDAR"` prints `2`).

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD`; `penv_set --force POV_DEMO_DIR "*tbd*"` with a
build-log line, only before PX-1.2 has started.

**EVIDENCE:** `records/<date>-POV-DEMO/script.md`. E-08. TISAX 5.2.6.

### PX-1.2 The rehearsal, on nonprod

> **BLOCKED** while PB-04 or PB-05 is not `DONE` (the doer's action service, approval page,
> control endpoints and consent bootstrap; the doer's code repository, `DOER_CODE_COMMIT`;
> `Assumption:` 22 to 35 and 2 to 4 engineer-days, README §8). Gate waiting: `POV_DEMO_RECORD`. No manual
> path replaces the service. Until then: `checkpoint PX-1.2 BLOCKED - - "PB-04/PB-05"`.

**WHO:** Persons 1, 2 and 3. **WHERE:** Gemini Enterprise web app; the nonprod approval page of
file 07; shell.

**What nonprod can rehearse.** File 07 runs the nonprod service **credential-less**, failing closed
on any Workspace call (07, the nonprod secret note under PW-2.7; PV-D-04). So nonprod can show no
execution, no verification, no mid-run halt and no K4. **The first real execution and the first
mid-run K0 happen in the recorded run (PX-1.3, PX-1.4)**; the rehearsal does not pretend otherwise.

**ACTION:**

```bash
source ~/.platform-env; need POV_DEMO_DIR DOER_NONPROD_PROJECT DOER_AUDIT_DS AGENT_ID_DOER
DD="$POV_DEMO_DIR"
checkpoint PX-1.2 START "$SECOND_HUMAN_EMAIL" - "rehearsal on nonprod"
```

1. Beats 1 and 2 against `DOER_NONPROD_PROJECT`: person 1 prompts; the request is recorded and
   denied (fail-closed, no credential) or shadowed at L1.
2. Person 3 presses halt (`no_writes`) on the nonprod page; person 1 sends one more request, which
   must be denied `p:halted`; person 1 requests the clear and person 3 approves it.
3. Person 3 demotes the operation's cell to L0; person 1 sends one request, which must read `L0`,
   `p:level_off`; person 1 requests the lift and person 3 approves it.
4. K3 and K4 are **talked through, not pulled**; K7 is not pulled (PX-1.8). Each person points at
   the control they will use on the day.

**VERIFY:** Each person can find, without help, the control they pull in the run; on nonprod, one
`p:halted` row and one `p:level_off` row exist after the rehearsal start, each followed by a lift
row with two different surrogates (person 1 requester, person 3 approver); no row names person 2 as
approver; no row reads `ok` (a nonprod `ok` would mean a credential exists there: severity 1). The
rehearsal notes list every surprise. `checkpoint PX-1.2 DONE "$SECOND_HUMAN_EMAIL"`.

**ROLLBACK:** Clear any halt and lift any override on nonprod with the two-person lift above
(person 1 requests, person 3 approves).

**EVIDENCE:** `<date>-PX-1.2-rehearsal-notes-v1`. Not a drill record, no gate reads it. E-08.
TISAX 5.2.6.

### PX-1.3 The recorded run: prompt, L1 record, approved execution, replay refusal

> **BLOCKED** while PB-01, PB-04 or PB-05 is not `DONE` (as PX-1.2).

**WHO:** Person 1 prompts; **person 3 approves on the approval page** (the operator who is not the
requester, file 07 People); person 2 witnesses and reads the audit from their own session.
**WHERE:** Gemini Enterprise web app as a member of the doer's operators group (file 07); the
approval page at `DOER_APPROVAL_A_URL`; shell, `~/.platform-env` sourced.

**The L2 form.** If `$POV_DEMO_DIR/level.txt` reads `L2` (Preconditions), the family stayed at L2
because the promotion floor was not met, and at L2 **there is no execution path**: a well-formed
approval is refused with `p:level_no_execute` ([../../wall-e/05-autonomy-ladder.md](../../wall-e/05-autonomy-ladder.md)
"L2 PROPOSE"; file 07). Beats 3 and 4 then read: the doer writes the proposal with pre-state and
rationale; person 1 requests execution and person 3 approves; the service **refuses**
`p:level_no_execute` and nothing is written to Workspace. The run is recorded **at the level
reached**: the VERIFY below reads `proposal` then `denied p:level_no_execute` in place of
`approval_required`, `ok` and the replay refusal, and the write-ahead item is recorded as "not
reached at L2". The claim says **"L2"**, and its approved-execution clause is struck, not softened
([README.md](README.md) §4). The platform floor is never loosened to reach L3.

**ACTION:** Start the recording clock, then the prompt.

```bash
source ~/.platform-env; need POV_DEMO_DIR DOER_PROJECT DOER_AUDIT_DS AGENT_ID_DOER GRP_DOER_OPERATORS
DD="$POV_DEMO_DIR"; LEVEL="$(cat "$DD/level.txt")"; echo "level reached: $LEVEL"
gcloud identity groups memberships list --group-email="$GRP_DOER_OPERATORS" --format='value(preferredMemberKey.id)' | grep -ixc "$SECOND_HUMAN_EMAIL" | tee "$DD/px13-person2-not-operator.txt"
checkpoint PX-1.3 START "$SECOND_HUMAN_EMAIL"
test -s "$DD/run-start.txt" || date -u +%Y-%m-%dT%H:%M:%SZ > "$DD/run-start.txt"
RUN_START="$(cat "$DD/run-start.txt")"
```

1. Person 1 asks the doer, in plain words, for the chosen operation on one synthetic account.
2. Person 3 shows the L1 rows the doer wrote for the same operation during file 07's shadow
   period: decision `shadow`, the would-be verdict, and **no** `post_state_hash`.
3. The doer freezes an L3 plan and returns "approval required"; person 3 approves on the page;
   the service executes and verifies. Person 2 reads the audit row as it lands.
4. Person 1 asks the doer to execute again with the same approval id; the service refuses.

```bash
Q() { bq --project_id="$DOER_PROJECT" query --use_legacy_sql=false --format=csv "$1"; }
Q "SELECT ts, level, decision, denial_reason, approval_id, ARRAY_LENGTH(approver_surrogates) AS approvers, verification, halt_epoch, override_epoch FROM \`${DOER_PROJECT}.${DOER_AUDIT_DS}.actions\` WHERE agent_id='${AGENT_ID_DOER}' AND ts >= TIMESTAMP('${RUN_START}') ORDER BY ts" | tee "$DD/px13-actions.csv"
Q "SELECT decision, COUNT(*) AS n FROM \`${DOER_PROJECT}.${DOER_AUDIT_DS}.actions\` WHERE agent_id='${AGENT_ID_DOER}' AND level='L1' GROUP BY decision" | tee "$DD/px13-l1-decisions.csv"
```

**VERIFY:**
- `px13-l1-decisions.csv` holds `shadow` and nothing that executed at L1 (absolute 3). An L1 row
  with a `post_state_hash` or decision `ok` is a **severity 1** finding: pull K0, stop the file.
- `px13-person2-not-operator.txt` reads `0` (PV-09 holds on the day). Anything else: stop, finding.
- `px13-actions.csv` shows, in order: `approval_required`; `ok` with one approver surrogate that is
  person 3's and neither person 1's nor person 2's, and `verification` = `verified`; then `denied`
  with `a:approval_already_used` for the replay.
- Every row was written before its Workspace effect (write-ahead, absolute 8), checked in **the
  stream the catalogue names for this operation** (Preconditions; for a group-membership operation,
  Groups Enterprise log events, not Admin log events), in file 06's `EVE_WS_LOGS_DS`: the
  `ws_insert_ids` of the `ok` row match events of that stream and event name, and no event by
  `DOER_ROBOT` in that stream in the window lacks an audit row. **An empty match set is a failure,
  not a pass**: the `ok` row must match at least one Google-written event, or the check proved
  nothing and the finding is recorded (wrong stream, lag, or sharing not enabled).
- The model's service identity appears on no approval row (absolute 2).

`checkpoint PX-1.3 DONE "$SECOND_HUMAN_EMAIL" "build-log:records/<date>-PX-1.3-demo-execution-v1"`
once all four hold (with the note `level L2` if the L2 form ran).

**ROLLBACK:** The inverse operation runs as beat 10, after PX-1.7 restores the credential; until
then the target is left in its changed, verified state, which is a synthetic account.

**EVIDENCE:** `px13-actions.csv`, `px13-l1-decisions.csv`, the screen recording's path (no token is
visible on it), as `<date>-PX-1.3-demo-execution-v1`. E-06, E-08. TISAX 5.2.6, 1.5.1.

### PX-1.4 K0 pulled live by person 3 during an L3 run (`K0_DRILL_RECORD`)

> **BLOCKED** while PB-04 is not `DONE`.

**WHO:** **Person 3 pulls, with no approval** (the andon cord). Person 1 starts the run; person 3
approves the plan; person 1 requests the clear and person 3 approves it; person 2 witnesses and
reads the audit, and approves nothing on the page.
**WHERE:** The approval page at `DOER_APPROVAL_A_URL` (the halt control); Gemini Enterprise; shell.

**The L2 form.** If `level.txt` reads `L2`, the run is a live L2 run with its approval: person 1
asks for a multi-item proposal, person 3 approves it (the service refuses execution with
`p:level_no_execute`, as PX-1.3's L2 form), and person 1 keeps sending proposal requests while
person 3 pulls K0. The measure is then the time from the halt call to the first request denied
`p:halted`; `executed_after` must be `0`; the record states `level L2` and the claim says "kill
levers pulled during a live L2 run", never "L3".

**ACTION:** Person 1 asks the doer for a multi-item L3 plan over several synthetic accounts in
`PILOT_OU` (`Assumption:` at least five items, so that the halt lands mid-run); person 3 approves;
while items are executing, person 3 presses halt (`no_writes`) without warning anyone. Then:

```bash
source ~/.platform-env; need POV_DEMO_DIR DOER_PROJECT DOER_AUDIT_DS AGENT_ID_DOER REGION
DD="$POV_DEMO_DIR"; checkpoint PX-1.4 START "$SECOND_HUMAN_EMAIL"
RUN_START="$(cat "$DD/run-start.txt")"
K0_TS="$(gcloud logging read "resource.type=\"cloud_run_revision\" AND httpRequest.requestMethod=\"POST\" AND httpRequest.requestUrl:\"/v1/control/halt\" AND timestamp>=\"${RUN_START}\"" --project="$DOER_PROJECT" --freshness=1d --order=asc --limit=1 --format='value(timestamp)')"
echo "K0 call at $K0_TS" | tee "$DD/k0.txt"
bq --project_id="$DOER_PROJECT" query --use_legacy_sql=false --format=csv "SELECT MIN(ts) AS first_halted, TIMESTAMP_DIFF(MIN(ts), TIMESTAMP('${K0_TS}'), MILLISECOND) AS ms_to_first_denial, COUNTIF(decision='ok') AS executed_after FROM \`${DOER_PROJECT}.${DOER_AUDIT_DS}.actions\` WHERE agent_id='${AGENT_ID_DOER}' AND ts >= TIMESTAMP('${K0_TS}') AND (denial_reason='p:halted' OR decision='ok')" | tee -a "$DD/k0.txt"
```

Clearing: person 1 requests the clear on the page only after the query above has been read, and
person 3 approves it on their own device. Lifting a halt raises autonomy, so it is never done by one
person (README §2), and never by person 2, whom the page's IAP does not admit (file 07 PW-4.5).
Person 3 having pulled the halt does not bar them from approving its clear: the requester is
person 1.

**VERIFY:** `k0.txt` holds a call timestamp and a `first_halted` row; `ms_to_first_denial` is
under 60,000 (platform target, [../04-identity-and-privileged-access.md](../04-identity-and-privileged-access.md)
§9.7) and, for the endpoint itself, under 5,000 (design target); `executed_after` counts only
items whose write had already started before the halt (each such row has `ts` earlier than the
first `p:halted` row); the remaining items read `p:halted`; later rows carry an incremented
`halt_epoch`. Eve's queries over the doer's audit (file 06 §11) show the halt on their next
run. After the clear, one read-only request succeeds; the clear's audit row carries two different
surrogates, person 1's and person 3's.

**ROLLBACK:** The two-person clear above.

**EVIDENCE:** `k0.txt` and the Eve query output, written into `K0_DRILL_RECORD`:

```bash
REC="records/$(date -u +%F)-PX-1.4-k0-live-v1.md"
{ echo "# K0 live drill, POV demonstration"; echo "Level reached: $(cat "$DD/level.txt")"; echo "Pulled by: person 3 (${SECOND_OPERATOR_EMAIL}), no approval"; cat "$DD/k0.txt"; echo "Clear requested by person 1, approved by person 3 (${SECOND_OPERATOR_EMAIL}); witnessed by person 2 (${SECOND_HUMAN_EMAIL})"; } > "$BUILD_LOG_DIR/$REC"
penv_set K0_DRILL_RECORD "$REC"
evidence_add PX-1.4 k0-live E-08 5.2.6 "build-log:$REC" "$BUILD_LOG_DIR/$REC"
checkpoint PX-1.4 DONE "$SECOND_HUMAN_EMAIL" "build-log:$REC" "K0 live"
```

E-08. TISAX 5.2.6.

### PX-1.5 K1 demote, and the two-person lift (`K1_DRILL_RECORD`)

> **BLOCKED** while PB-04 is not `DONE`.

**WHO:** Person 3 pulls; person 1 requests the lift; person 3 approves it; person 2 witnesses and
reads the ladder events.
**WHERE:** The approval page's demote control; shell.

**ACTION:** Person 3 demotes the demonstration operation's (family, trigger) cell to L0. Person 1
then asks the doer for the same operation. Read the effect:

```bash
source ~/.platform-env; need POV_DEMO_DIR DOER_PROJECT DOER_AUDIT_DS AGENT_ID_DOER
DD="$POV_DEMO_DIR"; checkpoint PX-1.5 START "$SECOND_HUMAN_EMAIL"
K1_TS="$(gcloud logging read "resource.type=\"cloud_run_revision\" AND httpRequest.requestMethod=\"POST\" AND httpRequest.requestUrl:\"/v1/control/demote\" AND timestamp>=\"$(cat "$DD/run-start.txt")\"" --project="$DOER_PROJECT" --freshness=1d --order=asc --limit=1 --format='value(timestamp)')"
bq --project_id="$DOER_PROJECT" query --use_legacy_sql=false --format=csv "SELECT ts, level, decision, denial_reason, override_epoch FROM \`${DOER_PROJECT}.${DOER_AUDIT_DS}.actions\` WHERE agent_id='${AGENT_ID_DOER}' AND ts >= TIMESTAMP('${K1_TS}') ORDER BY ts LIMIT 5" | tee "$DD/k1.csv"
bq --project_id="$DOER_PROJECT" query --use_legacy_sql=false --format=csv "SELECT * FROM \`${DOER_PROJECT}.${DOER_AUDIT_DS}.ladder_events\` WHERE ts >= TIMESTAMP('${K1_TS}') ORDER BY ts" | tee "$DD/k1-ladder.csv"
```

The lift is a raise: person 1 requests it through file 07's override-lift procedure, person 3
approves; the service never lifts on one person's call, and person 2 is not an approver on the page.

**VERIFY:** The first request after `K1_TS` reads level `L0`, decision `denied`, reason
`p:level_off`, with `override_epoch` one higher than before; `k1-ladder.csv` holds the lowering
row (actor person 3's surrogate) and, later, the lift row with two different surrogates (requester
person 1, approver person 3; neither is person 2's); time from `K1_TS` to the first L0 row is
recorded against the 5-second design target. Then `checkpoint PX-1.5 DONE "$SECOND_HUMAN_EMAIL"`.

**ROLLBACK:** The two-person lift.

**EVIDENCE:** `k1.csv`, `k1-ladder.csv` in `K1_DRILL_RECORD` (`penv_set K1_DRILL_RECORD
records/<date>-PX-1.5-k1-v1.md`, registered with `evidence_add PX-1.5 k1 E-08 5.2.6 …` as PX-1.4
does). E-08. TISAX 5.2.6.

### PX-1.6 K3: cut the agent off the action service

> **BLOCKED** while PB-04 is not `DONE`.

**WHO:** Person 1 under a time-boxed grant **person 2 approves** (a project IAM change, never
standing); person 2 witnesses. **WHERE:** Shell.

**ACTION:** Activate the doer project's IAM repair entitlement exactly as file 07 does for its own
K3 drill (`KILL_DRILL_RECORD_W`, entitlement id from `PAM_ENTITLEMENTS`). Then:

```bash
source ~/.platform-env; need POV_DEMO_DIR DOER_PROJECT REGION DOER_ACTIONS_URL DOER_AGENT_PRINCIPAL
DD="$POV_DEMO_DIR"; checkpoint PX-1.6 START "$SECOND_HUMAN_EMAIL"
SVC="$(gcloud run services list --project="$DOER_PROJECT" --region="$REGION" --filter="status.url=${DOER_ACTIONS_URL}" --format='value(metadata.name)')"
test -n "$SVC" || { echo "STOP: no service for DOER_ACTIONS_URL"; false; }
gcloud run services get-iam-policy "$SVC" --region="$REGION" --project="$DOER_PROJECT" --format=json > "$DD/k3-before.json"
K3_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; echo "$K3_TS" > "$DD/k3-start.txt"
gcloud run services remove-iam-policy-binding "$SVC" --region="$REGION" --project="$DOER_PROJECT" --member="$DOER_AGENT_PRINCIPAL" --role=roles/run.invoker
```

Person 1 prompts the doer once a minute for a read. When the chat reports the tool failure:

```bash
gcloud logging read "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${SVC}\" AND httpRequest.status=403 AND timestamp>=\"${K3_TS}\"" --project="$DOER_PROJECT" --freshness=1d --order=asc --limit=1 --format='value(timestamp)' | tee "$DD/k3-first-403.txt"
gcloud run services add-iam-policy-binding "$SVC" --region="$REGION" --project="$DOER_PROJECT" --member="$DOER_AGENT_PRINCIPAL" --role=roles/run.invoker
```

**VERIFY:** `k3-first-403.txt` holds a timestamp; its difference from `K3_TS` is recorded against
the HLD's "about a minute" and Google's statement that allow-policy changes typically propagate in
2 minutes and can take 7 or more; no audit row with decision `ok` appears between the first 403 and
the restore; after the restore `get-iam-policy` equals `k3-before.json` except for `etag`; one read
succeeds. Revoke the grant. Then `checkpoint PX-1.6 DONE "$SECOND_HUMAN_EMAIL"`.

**ROLLBACK:** The `add-iam-policy-binding` line above.

**EVIDENCE:** The three files, in the demo record (PX-1.11). E-08. TISAX 5.2.6, 4.1.

### PX-1.7 K4: kill the credential, and the warm-instance check (`K4_DRILL_RECORD`)

> **BLOCKED** while PB-04 or PB-05 is not `DONE`.

**WHO:** Person 1 pulls through the page's revoke control; **person 2 present**; the re-consent is
file 07's sitting, exactly two people, no screen share.
**WHERE:** The approval page; Gemini Enterprise; shell; then the consent sitting of file 07.

> **IRREVERSIBLE in kind**: the credential is consumed at Google and only a new consent restores
> it. Confirm first: PX-1.3 to PX-1.6 are recorded; the hardware keys for the consent sitting are
> in the room; 45 minutes are free ([../setup/42](../setup/42-gates-drills-and-evidence.md) GD-5.5);
> the robot-login alert of file 07 is announced against this drill id so it is not trained to be
> ignored; person 2 says "go". Gate: PV-06 (synthetic targets) and `DOER_CONSENT_SITTING_RECORD` exist.

**ACTION:** Write the IRREVERSIBLE START **before** anything is pressed, with person 2 as witness,
so that an interrupted sitting falls under README §12's IRREVERSIBLE clause and K4 is never pulled
twice (a second pull costs another consent sitting):

```bash
source ~/.platform-env; need POV_DEMO_DIR DOER_PROJECT DOER_AUDIT_DS AGENT_ID_DOER PLATFORM_REPO_DIR
DD="$POV_DEMO_DIR"
awk -F'\t' '$2=="PX-1.7" && $3=="START" {f=1} END {exit !f}' "$BUILD_LOG_DIR/checkpoints.tsv" && { echo "STOP: PX-1.7 already started; read the credential state and ask person 2 (README §12)"; false; }
K4_MAX_S="$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-01 K4_RESIDUE_MAX_SECONDS)"; need K4_MAX_S
checkpoint PX-1.7 START "$SECOND_HUMAN_EMAIL" - "irreversible: K4 revoke of the doer credential"
```

Person 1 presses revoke. Immediately, then every 60 seconds from the same warm service, person 1
asks the doer for a read on a synthetic account until one is refused with a credential error class,
or until `K4_MAX_S` has passed (then once more at 60 minutes, as file 07 PW-6.5 does). Then:

```bash
K4_TS="$(gcloud logging read "resource.type=\"cloud_run_revision\" AND httpRequest.requestMethod=\"POST\" AND httpRequest.requestUrl:\"/v1/control/revoke-credential\" AND timestamp>=\"$(cat "$DD/run-start.txt")\"" --project="$DOER_PROJECT" --freshness=1d --order=asc --limit=1 --format='value(timestamp)')"
bq --project_id="$DOER_PROJECT" query --use_legacy_sql=false --format=csv "SELECT ts, operation, decision, denial_reason, error_class FROM \`${DOER_PROJECT}.${DOER_AUDIT_DS}.actions\` WHERE agent_id='${AGENT_ID_DOER}' AND ts >= TIMESTAMP('${K4_TS}') ORDER BY ts LIMIT 20" | tee "$DD/k4.csv"
bq --project_id="$DOER_PROJECT" query --use_legacy_sql=false --format=csv "SELECT TIMESTAMP_DIFF(MIN(ts), TIMESTAMP('${K4_TS}'), SECOND) AS residue_seconds, COUNTIF(decision='ok') AS reads_ok_after_revoke FROM \`${DOER_PROJECT}.${DOER_AUDIT_DS}.actions\` WHERE agent_id='${AGENT_ID_DOER}' AND ts >= TIMESTAMP('${K4_TS}') AND (decision='ok' OR error_class IS NOT NULL)" | tee "$DD/k4-residue.csv"
```

`residue_seconds` as queried is the time to the first read row of either kind; person 3 (not
person 1) reads `k4.csv` and writes the **seconds from `K4_TS` to the first refused read** into
the record.

Then open file 07's consent sitting, which writes a new secret version and redeploys the pin under
person 2's approval (PV-D-12), and record the new version number only:

```bash
penv_set --force DOER_TOKEN_VERSION "$(tr -dc '0-9' < "$DD/new-token-version.txt")"
```

(`new-token-version.txt` holds the number the consent bootstrap printed, typed by person 2 from
their own screen; never a token.)

**VERIFY (one criterion, the same as file 07 PW-6.5's measurement):** the measured residue, in
seconds from `K4_TS` to the first read refused with a credential error class, is recorded, and the
drill **passes when it is at or under `K4_MAX_S`**, the threshold signed in PV-01. A read that
succeeds before the first refusal is part of the measured residue, not by itself a failed kill; a
residue over `K4_MAX_S`, or no refusal by the 60-minute read, **fails** the drill and is a finding.
Neither Google's native-app page (revocation invalidates issued tokens) nor the design's "up to 60
minutes" ([../../wall-e/04-flows.md](../../wall-e/04-flows.md) Flow G) is written into the record
as fact; only the measured number is. If PV-01 carries no `K4_RESIDUE_MAX_SECONDS`, `need K4_MAX_S`
fails before the START line: record `checkpoint PX-1.7 PENDING - - "PV-01: K4 residue threshold"`
and do not pull K4. After the sitting, the service pins the new `DOER_TOKEN_VERSION` (no
`latest`), and one read succeeds. Then run beat 10: the inverse of PX-1.3's operation, requested by
person 1, **approved by person 3**, verified, witnessed by person 2. Then
`checkpoint PX-1.7 DONE "$SECOND_HUMAN_EMAIL" "build-log:<K4_DRILL_RECORD>" "residue <n> s"`.

**ROLLBACK:** The consent sitting is the restore; there is no other.

**EVIDENCE:** `k4.csv`, `k4-residue.csv`, the measured residue and `K4_MAX_S`, the consent-sitting record id, into
`K4_DRILL_RECORD` (`penv_set K4_DRILL_RECORD records/<date>-PX-1.7-k4-v1.md`,
`evidence_add PX-1.7 k4 E-08 5.2.6 …`).
E-08. TISAX 5.2.6, 1.4.1.

### PX-1.8 K7 on `fld-agents-w-nonprod` (`K7_POV_DRILL_RECORD`)

**WHO:** Person 1 pulls under the K7 human entitlements; **person 2 present** for the enforced half
and approver of the lift; the IT security desk on the line.
**WHERE:** Shell, the `§6` shell of setup/18.

**ACTION:** Run [../setup/18](../setup/18-model-armor-floor-spikes-and-kill-switch.md) KS-6.1 to
KS-6.5 **as file 03 ran them** for `POV_K7_FIRST_DRILL_RECORD`, with the selection narrowed to the one
folder that now holds a live Tier W deployment:

```bash
source ~/.platform-env; need FLD_AGENTS_W_NONPROD DOER_NONPROD_PROJECT K7_POLICY_DIR
checkpoint PX-1.8 START "$SECOND_HUMAN_EMAIL"
SEL="fld-agents-w-nonprod:$FLD_AGENTS_W_NONPROD"
```

The probes of KS-6.1 are pointed at the doer's nonprod action service as well as at the canary, so
"first refused invocation" is measurable for the first time. KF-4 follows setup/18's union rule:
`pab-agents` also binds `DOER_PROJECT` in production, so KF-4 is **skipped** and the record says
why. KF-2's scope check of KS-6.3 runs unchanged and must show no principal of `DOER_PROJECT`,
`EVE_PROJECT`, `MO_PROJECT` or `GEMINI_PROJECT`.

**VERIFY:** KS-6.3's pass criteria: KF-1 set to first refused call under 60 s; trigger to last
lever read back under 900 s on the human path (the job path's 300 s is not claimed, B-04); KS-6.4's
zero diff; the doer's **production** service answered throughout (a production refusal is a
severity 1 finding and the drill stops). Then `checkpoint PX-1.8 DONE "$SECOND_HUMAN_EMAIL"`.

**ROLLBACK:** KS-6.4, the two-person lift.

**EVIDENCE:** KS-6.5's record, written as `records/<date>-PX-1.8-k7-pov-v1.md`,
`penv_set K7_POV_DRILL_RECORD <path>`, `evidence_add PX-1.8 k7-pov E-08 5.2.6 …`. Does **not**
feed G20, which needs `fld-agents-p-sa-nonprod` with a live P-SA project (§8). E-08. TISAX 5.2.6,
1.6.3.

### PX-1.9 Eve reports a planted human super-admin action to person 2

> **BLOCKED** while PB-02 or PB-03 is not `DONE` (Eve's schemas and POV SQL; `EVE_CONFIG_REPO`;
> `Assumption:` 1 to 2 and 7 to 10 engineer-days). Gate waiting: `POV_DEMO_RECORD` line 11.

**WHO:** Person 3 picks the minute and tells person 1 only; **person 1 performs** the action as
`SA_1_ADMIN`; **person 2 confirms alone**, from their own device, before anyone tells them.
**WHERE:** Admin console, Menu > Account > Admin roles; person 2's mailbox and phone.

**ACTION:** Person 1 assigns a **delegated** pre-built role (never Super Admin) to one synthetic
account in `PILOT_OU` (Menu > Account > Admin roles > the role > Assign admin), waits five
minutes, then unassigns it (the same page, Unassign role). This is an ordinary, reversible admin
change to a synthetic account, not a mutating super-admin test (SD-35 is untouched). Person 1
types the times into:

```bash
checkpoint PX-1.9 START "$SECOND_OPERATOR_EMAIL" - "planted action; person 2 not told"
confirm_manual PX-1.9 "Which Admin log event ids did the assign and unassign produce (Reporting > Audit and investigation > Admin log events)?"
```

**VERIFY:** Person 2 records, before speaking to anyone, the time the report reached them, its
route, and the event it names; the report names person 1's admin account as actor; its arrival
minus the event time is within Eve's lag budget of file 06 (Admin log events lag "near real time
(couple of minutes)" on Google's page, plus the query schedule); **the recipient is not the
subject**. A report that did not arrive is the result, recorded as a failure, not re-staged.
Then `checkpoint PX-1.9 DONE "$SECOND_HUMAN_EMAIL"` (with the note `report not received` if so).

**ROLLBACK:** The unassign above; confirm in Admin roles that the synthetic account holds no role.

**EVIDENCE:** Person 2's signed note and Eve's `findings` row id from `EVE_DS`, in the demo record.
The word "independent" does not appear in it (README §1.2). E-06, E-08. TISAX 4.1.3, 1.5.1.

### PX-1.10 Mo's digest and the value report

> **BLOCKED** while PB-06 is not `DONE` (Mo's POV pack; `MO_CODE_COMMIT`; `Assumption:` 6 to 10
> person-days). Gate waiting: `POV_DEMO_RECORD` line 12.

**WHO:** Person 1 as Mo owner presents; person 3 answers "can you recompute it" from their own
recomputation of file 08. **WHERE:** The platform repository's pull request for
`MO_DIGEST_RECORD`; `POV_VALUE_REPORT`.

**ACTION:** Walk through, in this order: the retrospective baseline and its limit (PV-D-05); audit
counts for the demonstration operation; PM-8.4's projected human minutes for matched tasks only,
**stated as the weakest number and as a projection, never a saving**, or, when nothing matched,
the stop-rule sentence and no figure; every
rate with its `n` and its Wilson lower bound; `MO_PROPOSAL_1_OUTCOME` (merged by two humans who
are neither the author nor a Mo identity, or recorded `REFUSED`).

**VERIFY:** The digest's figures equal person 3's recomputation on the same watermark; no slide
or sentence claims time saved, or any promotion to L4 or L5 (no real minute of admin work was
saved, §5 item 16); the baseline is presented as
"volumes from Google's admin history and minutes from a timed sample", never as derived from
Google's history alone. `checkpoint PX-1.10 START` before the walk-through and
`checkpoint PX-1.10 DONE "$SECOND_OPERATOR_EMAIL"` after.

**ROLLBACK:** None; a presentation.

**EVIDENCE:** The pull request URL and person 3's recomputation id, in the demo record. E-09.
TISAX 1.5.1.

### PX-1.11 Write and sign `POV_DEMO_RECORD`

**WHO:** Person 1 writes; persons 2 and 3 co-sign; person 3 verifies the record against the raw
files, not person 1.
**WHERE:** Shell; `EVIDENCE_INTERIM_LOCATION` for the signed PDF.

**ACTION:**

```bash
source ~/.platform-env; need BUILD_LOG_DIR POV_DEMO_DIR K0_DRILL_RECORD K1_DRILL_RECORD K4_DRILL_RECORD K7_POV_DRILL_RECORD KILL_DRILL_RECORD_W
DD="$POV_DEMO_DIR"; checkpoint PX-1.11 START "$SECOND_OPERATOR_EMAIL"
REC="records/$(date -u +%F)-PX-1.11-pov-demo-v1.md"
{ echo "# POV demonstration record"; echo "Script: records/$(basename "$DD")/script.md"
  echo "| Beat | Record | Target | Measured | Pass |"; echo "|---|---|---|---|---|"
  for r in K0_DRILL_RECORD K1_DRILL_RECORD K4_DRILL_RECORD K7_POV_DRILL_RECORD KILL_DRILL_RECORD_W; do eval "echo \"| $r | \$$r | see record | see record | *tbd* |\""; done
  echo "K3: $(cat "$DD/k3-first-403.txt" 2>/dev/null || echo BLOCKED). Eve report: *tbd*. Mo digest: *tbd*."
  echo "Findings: *tbd*. Signed: platform owner; second person; second operator."; } > "$BUILD_LOG_DIR/$REC"
penv_set POV_DEMO_RECORD "$REC"
evidence_add PX-1.11 pov-demo E-05 1.5.1 "build-log:$REC" "$BUILD_LOG_DIR/$REC"
checkpoint PX-1.11 DONE "$SECOND_HUMAN_EMAIL" "build-log:$REC" "demo recorded"
```

Replace every `*tbd*` with the measured value or `BLOCKED <PB id>` before signing.

**VERIFY:** `grep -c 'tbd' "$BUILD_LOG_DIR/$POV_DEMO_RECORD"` prints `0`; every row reads a
measured value or a named BLOCKED id; the signed PDF's SHA-256 is in `EVIDENCE_REGISTER`.

**ROLLBACK:** A `-v2` record supersedes; nothing is overwritten.

**EVIDENCE:** The record and PDF. E-05, E-08. TISAX 1.5.1, 5.2.6.

## 2. The tabletop

### PX-2.1 Two hours, run by the incident commander (`POV_TABLETOP_RECORD`)

**WHO:** **The incident commander runs it**; persons 1, 2, 3, the DPO and the AI compliance owner
take part; the platform owner is a participant, never the facilitator.
**WHERE:** A room or a call; the record to `PLATFORM_EVIDENCE_BUCKET`.

**ACTION:** [../setup/42](../setup/42-gates-drills-and-evidence.md) GD-5.10's method, cut to two
scenarios the POV can actually suffer, 50 minutes each plus 20 for actions:

1. **The doer's refresh token is abused** to write to accounts in `PILOT_OU` at 02:00 on a
   Saturday. Page, acknowledge, declare, K0, K4, K7; the four "one request end to end" queries
   against `DOER_AUDIT_DS` and the Workspace audit with wall-clock times; the Art. 73 question on
   the real form. The business-hours acknowledgement of PV-D-10 is exercised honestly: who is
   actually reached, and when.
2. **A human super admin blinds Eve** by turning off Workspace data sharing (the self-silencing
   case, RB-04). Does the absence alarm of file 06 fire, to whom, and what does person 2 do if the
   actor is person 1; what does person 3 do if it is person 2.

**VERIFY:** GD-5.10's pass criteria applied to what exists: every acknowledgement and containment
target met or a dated action with an owner; **no participant discovered a lever they could not
pull**; the four queries completed (`Assumption:` 30 minutes for all four). Actions go to
`backlog.md`.

**ROLLBACK:** None; an exercise.

**EVIDENCE:** First write the record (scenario, participants by role, timings, findings, actions
with owners and dates) and have the incident commander and person 2 sign it. Only then:

> **IRREVERSIBLE**: `PLATFORM_EVIDENCE_BUCKET`'s retention policy is locked (file 03, PV-10); the
> copied object cannot be deleted or replaced before its retention expires. Confirm first: the
> record is complete and signed; `grep -c 'tbd'` prints `0`; the secret scan printed nothing;
> person 2 has read it for personal data and it names roles, not people, beyond admin roles and
> surrogates (no employee's name, no free-text about a person's conduct). A wrong record is
> superseded by a `-v2` object, never overwritten. Gate: PV-10 signed.

```bash
source ~/.platform-env; need PLATFORM_EVIDENCE_BUCKET BUILD_LOG_DIR SECOND_HUMAN_EMAIL
REC="records/$(date -u +%F)-PX-2.1-tabletop-v1.md"
test -s "$BUILD_LOG_DIR/$REC" || { echo "STOP: write and sign the record first"; false; }
grep -c 'tbd' "$BUILD_LOG_DIR/$REC"
grep -IiE 'password|secret|refresh_token|BEGIN PRIVATE' "$BUILD_LOG_DIR/$REC" && { echo "STOP: secret-like text"; false; }
checkpoint PX-2.1 START "$SECOND_HUMAN_EMAIL" - "irreversible: tabletop record to locked bucket"
penv_set POV_TABLETOP_RECORD "$REC"
evidence_add PX-2.1 tabletop E-10 1.6.2 "build-log:$REC" "$BUILD_LOG_DIR/$REC"
gcloud storage cp "$BUILD_LOG_DIR/$REC" "${PLATFORM_EVIDENCE_BUCKET}/evidence/tabletops/$(date -u +%F)/"
gcloud storage ls "${PLATFORM_EVIDENCE_BUCKET}/evidence/tabletops/$(date -u +%F)/"
checkpoint PX-2.1 DONE "$SECOND_HUMAN_EMAIL" "build-log:$REC" "tabletop recorded"
```

The record **is not G17's pre-grant tabletop** ([README.md](README.md) §7.3): setup/38 GT-2.3 runs
the P-SA crisis scenario and writes its own `TABLETOP_RECORD`, a name the POV never sets.
`POV_TABLETOP_RECORD` is history for that step, never its value.
E-10. TISAX 1.6.2, 1.6.3.

## 3. The evidence pack

### PX-3.1 Consolidate the register and count the E-xx producers

**WHO:** Person 1 runs; the AI compliance owner signs the E-xx table.
**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** Run [../setup/42](../setup/42-gates-drills-and-evidence.md) **GD-4.1's block
unchanged**, then GD-4.2's count loop, saving both outputs under `PX-3.1`.

**VERIFY:** GD-4.1 sections 2 to 4 empty; every name in section 5 is either a read with EVIDENCE
"none" or a missing record with an owner. For GD-4.2: E-14 is `0` by classification (PV-11). A `0`
for E-01, E-02, E-05, E-07, E-12 or E-13 does not block the POV, which opens no stage for real
employees, but **blocks any real account entering `PILOT_OU`** and is written into §5's gap
statement by id.

**ROLLBACK:** None; reads.

**EVIDENCE:** `<date>-PX-3.1-register-consolidation-v1`, signed E-xx table. E-05. TISAX 1.5.1,
7.1.1.

### PX-3.2 Assemble the pack (`EVIDENCE_PACK_DIR`)

**WHO:** Person 1 exports; **person 3 verifies** three groups by hand.
**WHERE:** Shell.

**ACTION:** GD-4.3's export, with the full set's value for the directory, so setup/42 later reads
it as a VERIFY:

```bash
need BUILD_LOG_DIR EVIDENCE_REGISTER
penv_set EVIDENCE_PACK_DIR "$BUILD_LOG_DIR/packs"
D="$EVIDENCE_PACK_DIR/pov-$(date -u +%F)"; mkdir -p "$D"
for g in 1.1 1.2 1.3 1.4 1.5 1.6 2.1 3.1 4.1 4.2 5.1 5.2 5.3 6.1 7.1; do
  mkdir -p "$D/$g"
  awk -F' *\\| *' -v g="$g" '/^\| 20/ && index($6, g)==1 {print $2"\t"$7}' "$EVIDENCE_REGISTER" > "$D/$g/index.tsv"
done
find "$D" -name index.tsv -size -2c -print | tee "$D/empty-groups.txt"
```

**VERIFY:** Every group listed in `empty-groups.txt` is one the POV does not reach and is named in
§5 (expected: 2.1 training, 6.1 supplier file unless PV-12's model record was filed). Person 3
cross-checks 3.1 (hardware-key custody from file 03), 4.1-4.2 (IAM exports, roster, Eve's roster
diff) and 5.2 (the drills of §1 and `DOER_RESTORE_DRILL_RECORD`) against the artefact, not the index.

**ROLLBACK:** `rm -r "$D"`; the pack is derived, never a source.

**EVIDENCE:** Index and person 3's three readings as `<date>-PX-3.2-evidence-pack-v1`. E-05.
TISAX 1.1.1, 1.5.1.

### PX-3.3 Copy the pack to the locked bucket and hand it to the ISMS

**WHO:** Person 1 copies; person 2 reads the objects back; ISMS acknowledges receipt.
**WHERE:** Shell.

> **IRREVERSIBLE**: `PLATFORM_EVIDENCE_BUCKET`'s retention policy is locked (file 03, PV-10), so
> no copied object can be deleted before its retention expires. Confirm first: `grep -rIiE
> 'password|secret|refresh_token|BEGIN PRIVATE' "$D"` prints nothing; the pack holds indexes and
> record paths, no personal data beyond admin roles and surrogates. Gate: PV-10 signed.

```bash
need PLATFORM_EVIDENCE_BUCKET EVIDENCE_PACK_DIR
D="$(ls -d "$EVIDENCE_PACK_DIR"/pov-* | tail -n 1)"
checkpoint PX-3.3 START "$SECOND_HUMAN_EMAIL" - "irreversible: copy to locked bucket"
gcloud storage cp --recursive "$D" "${PLATFORM_EVIDENCE_BUCKET}/packs/"
gcloud storage ls --recursive "${PLATFORM_EVIDENCE_BUCKET}/packs/$(basename "$D")/" | tee "$BUILD_LOG_DIR/records/$(date -u +%F)-PX-3.3-pack-listing-v1.txt"
```

**VERIFY:** Person 2's own listing, from their workstation, shows one object per `index.tsv`; the
ISMS acknowledgement names the prefix.

**ROLLBACK:** **None for the copied objects.** A wrong pack is superseded by a new dated prefix.

**EVIDENCE:** The listing and the ISMS acknowledgement. E-05. TISAX 1.1.1, 5.2.4.

## 4. The POV deviation register, PV-D-01 to PV-D-16 (`PV_DEVIATION_REGISTER`)

Each row: what the POV does; the full-set rule it departs from; why it is safe **at this tier and
not the next**; the trigger that unwinds it; the `setup/` file that unwinds it. Owner is the
platform owner unless named. Opened: the date PV-01 is signed (*tbd*). A deviation never loosens an
absolute of [README.md](README.md) §2; a step that did would be a defect, not a row here.
Build-time rows inside a file stay `BD-P<file>-<n>` in `DEVIATION_REGISTER`, each naming its PV-D.

<!-- PV_DEVIATION_REGISTER:BEGIN -->
| Id | The POV does | Full-set rule | Safe at this tier because | Not safe at the next because | Unwind trigger | Unwound by | Owner |
|---|---|---|---|---|---|---|---|
| PV-D-01 | Builds the foundation and the agent projects by hand, same names; labels, lien, budget and API set only as far as a committed run spec `factory/runs/<agent_id>-<env>.json` states them (Preconditions) | Projects are factory-made: setup/17 FM-0.2, README B-01; SD-01's dated exception | SD-01 is the full set's own exception; hand-built names equal factory names; where a run spec exists and `fm-zero-diff.py live` reads `ZERO-DIFF`, an import has nothing to change. Where it does not, the drift is known and listed as rework (§6 row 17), not claimed away | At Tier P and above, drift between hand state and code is where an unreviewed privilege hides | Every POV agent project reads `ZERO-DIFF` against its run spec, then B-01 lands with a `terraform import` that plans no changes | setup/17, setup/42 GD-7 | platform owner |
| PV-D-02 | SCC Standard; the Tier C gate row for Premium detections stays open | 01-hld §0.4 Tier C; SD-15; setup/09 FS-7 | No agent holds a Workspace or tenant-wide credential that Premium's threat detections would guard; the row is not marked green | Tier P puts a Workspace role on a robot; the detection Premium adds is part of that tier's price | Before a Tier P row touches a real account | setup/09 FS-7, setup/20 | platform owner; IT security |
| PV-D-03 | No witness organisation | setup/08, 27, 28; CP6; G1, G-2, G18 | Eve's evidence is written by Google into logs administrators cannot delete; the absence alarm, person 2's independent fingerprint recomputation and the unannounced proof still run; nobody calls Eve independent | Once a robot or an administrator can reach Eve's stores, only a copy outside the tenant is evidence they cannot quietly amend | Before any super-admin grant, or before Eve's evidence goes to a TISAX assessor | setup/08, 27, 28 | person 2 |
| PV-D-04 | No sandbox tenant, no twin, no `SANDBOX_OU` | SD-29, SD-35; 02-landing-zone-and-tiers §3.5 (line 488); setup/21 | No agent holds Super Admin, so no super-admin test exists to be run in the wrong place | Super Admin cannot be scoped to an organisational unit; only a second tenant contains it | G10, G11, G14, G20 or Eve G-7 requested, or Super Admin proposed | setup/21, 37 | platform owner |
| PV-D-05 | Toil baseline: **volumes** from up to six months of Admin console audit history, **minutes** imputed from a timed sample (at least 10 instances per task) | setup/02 TB-1 to TB-5, four prospective ISO weeks | Google writes the logs and administrators cannot delete them or change retention (read 2026-09-16); the nine-column CSV is unchanged; one task is recounted in the same ISO week as the count (02 PD-8.6); the counts file is hashed and kept in the locked bucket (02 PD-8.2); no promotion is claimed on it | Retention is a rolling 6 months and the raw export is deleted after reduction (02 PD-8.2), so once the window passes the volume is **attested, not reproducible**, by anyone including a TISAX assessor, unless the address-free counts file and its SHA-256 sit in the locked bucket; the minutes come from a small observed sample, not from Google; task selection and the automation-actor exclusion are made by person 2 or person 3, never by person 1, the Mo owner whose programme is being valued (02 PD-8.2), but both work inside that programme; time saved above L3 needs a measured prospective baseline | Before a promotion above L3 claims time saved, before the S1 review, and before the baseline is shown to an assessor | setup/02, setup/22 re-run load | platform owner; person 3 reviews |
| PV-D-06 | Eve's detections as scheduled BigQuery queries | setup/25; B-08 reconciler | Eve blocks nothing in the POV; the same `eve/config` files are read | A controller that must halt needs a job with a halt path, not a query | S3 entry, or anything needing the power to halt | setup/25, 41 | person 2 |
| PV-D-07 | Eve holds no Workspace credential; coverage depends on the edition | setup/24 EW-6, setup/25 EH-4.1; B-10; SD-03 | Nothing is polled by actor under a credential that could be abused; every stream the edition does not share is recorded in `EVE_EDITION_COVERAGE_RECORD` | G-4 needs the Reports poll by actor beside the sink | A needed stream is not shared; add the Reports API poll as an addition in the same project | setup/24 | person 2 |
| PV-D-08 | The doer is a separate agent (`AGENT_ID_DOER`); Wall-E's names reserved | setup/31 lines 26 and 434 (`WALLE_PROJECT` in `fld-agents-p-sa-prod`) | No permanent name is spent at the wrong tier; code, schemas, ladder, consent procedure and kill switch carry over | A project never moves tier (02 §1.5); Wall-E must be born in its P-SA folder | The P-SA gate opens | setup/30 to 39, run unchanged | platform owner |
| PV-D-09 | Optional Tier P row: two delegated roles scoped to synthetic `PILOT_OU`, never P-SA | 01-hld §0.4 P line; P33; setup/16 lines 250-345 (schema) | Google enforces the OU scope; targets are synthetic; risky privileges excluded; Eve is the verifier | Real accounts make every mistake a real change to a person | A real account enters `PILOT_OU`, a customer-scoped write is added, or P-SA proposed | setup/15 part B, 37, 38 | platform owner; person 3 |
| PV-D-10 | No SIEM, no 24x7 retainer; business-hours acknowledgement | G2; setup/15 part B | No record claims 24x7 cover; the worst credential is a Tier W token on synthetic accounts, killable by any operator | A Tier P or P-SA credential abused overnight is a tenant incident before anyone wakes | Before Tier P on real accounts, or the first severity-1 alert missed overnight | setup/15 part B | IT security |
| PV-D-11 | No penetration test | G8; GE-14; setup/37, setup/04 PU-2.2 | No tenant-wide credential exists and nothing is shared externally | A super-admin robot behind an approval page is exactly what a tester must attack | Any external share or any grant | setup/37 | IT security |
| PV-D-12 | No Binary Authorization; deploys need person 2's approval and an image digest comparison | Tier W control W5; G19; setup/42 GD-2.1 | Deploying still takes two people and a changed image is detected by digest | A second builder or a P-SA service makes a signed provenance chain the only scalable check | The full build's Tier W gate, or a second builder | setup/42 GD-2.2, setup/33 | platform owner |
| PV-D-13 | Platform verifier, register CI, ladder-raise rule and Mo's validator replaced by two-person signed recomputations | B-03; 05-registry lines 141 and 224; SD-36; setup/16 RG-3.6 | SD-36's manual parse is the full set's own fallback; a missing verifier only demotes L4 cells to L3 and the POV stops at L3 | A fourth agent or any L4 cell makes hand parsing the bottleneck and the error source | B-03 lands, an L4 cell is proposed, or an agent at Tier W or above is added beyond the doer. The two Tier C agents of file 05 and PX-7.1's Tier C agent do not fire it; the optional Tier P row of file 07 PW-7.2 does, so if it is built the trigger **is live** and PX-9.1 records it with a dated action | setup/16, 40 | platform owner; security reviewer |
| PV-D-14 | Two hands-on people and a named third who is mandatory on set occasions | SD-04; B-21; setup/38 GT-0 | Every two-person rule and SD-48 hold; reports about person 2 go to person 3 or are `PENDING` | The grant needs five humans (or four with a dated ISMS exception) | Tier P on real accounts, a proposed grant, or a booked TISAX assessment | setup/03, 38 | ISMS |
| PV-D-15 | DPIA started with a dated completion commitment; works council informed | G8; P129; setup/03 | The pilot accounts are synthetic; Eve's monitoring of named administrators has the SD-11 DPO record | Real employees' accounts are personal data processed by an AI system | A real account enters `PILOT_OU` | setup/03 | DPO |
| PV-D-16 | Person 3 is the blind grader; no Chrome Enterprise Premium device checks | W10, P25; P63 | The grader is not the playbook owner; operators use managed devices with hardware keys | More agents or levels make one grader a single point of bias; unmanaged devices reach approval pages | A second Tier W agent, a promotion above L3, or an unmanaged operator device | setup/40, 13 | platform owner |
<!-- PV_DEVIATION_REGISTER:END -->

**Departures that carry no PV-D row of their own.** Each is either covered by the PV-D named or is
the full set's behaviour; PX-4.1 checks that every `BD-P` row citing no PV-D id is on this list.

| Departure | Where | Carried by |
|---|---|---|
| The doer's audit schemas live in `<AGENT_ID_DOER>/schemas/` of the platform repository; setup/31 WD-4.5 reads Wall-E's from its own repository | 04 PC-2.4 | PV-D-08 (the doer is a separate agent); §6 row 31 |
| Eve's schemas and POV SQL in `EVE_CONFIG_REPO` | 06 | PV-D-06 |
| Mo's improver manifest drops the `eve_grades` read, which the POV does not create (`Assumption:`) | 04 PC-3.4 | PV-D-13 (grades recomputed by hand); §5 item 17 |
| `agp-env` created only when the NAMES record carries `TAG_KEY_ENV` | 03 | no deviation: same as the full set when the value is signed |
| `BD-P03-5`: organisation-policy dry run shortened from 14 to at least 7 days on folders that hold no project; closes when the first project is created in any of them | 03 PF-5.3 | **a build-time row, not a PV-D deviation.** setup/13's 14-day dry run exists to catch violations by running workloads, and these folders hold none, so an empty violation read after 7 days proves as much. The row closes itself inside the POV, when 06, 07 or 08 creates the first agent project, so it leaves nothing for the full build to unwind and §10's count of 16 stands |

### PX-4.1 Commit the register and cross-check it

**WHO:** Person 1 commits; person 2 reviews as code owner of `/decisions/`.
**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** Extract the table from this page, never retype it:

```bash
need WIKI_DIR PLATFORM_REPO_DIR DEVIATION_REGISTER
SRC="$WIKI_DIR/platform/agentic-platform/pov/09-the-demonstration-deviations-and-the-hand-over.md"
awk '/^<!-- PV_DEVIATION_REGISTER:END -->$/{p=0} p{print} /^<!-- PV_DEVIATION_REGISTER:BEGIN -->$/{p=1}' "$SRC" > "$PLATFORM_REPO_DIR/decisions/pov-deviations.md"
penv_set PV_DEVIATION_REGISTER "decisions/pov-deviations.md"
git -C "$PLATFORM_REPO_DIR" add decisions/pov-deviations.md
git -C "$PLATFORM_REPO_DIR" commit -m "PX-4.1 POV deviation register PV-D-01 to PV-D-16"
W="$(mktemp -d)"
grep -o 'PV-D-[0-9][0-9]' "$DEVIATION_REGISTER" | sort -u > "$W/used"
grep -o '^| PV-D-[0-9][0-9]' "$PLATFORM_REPO_DIR/decisions/pov-deviations.md" | tr -d '| ' | sort -u > "$W/defined"
comm -23 "$W/used" "$W/defined"; rm -r "$W"
grep -E '^\| *BD-P' "$DEVIATION_REGISTER" | grep -v 'PV-D-[0-9][0-9]' | tee /dev/stderr | wc -l
"$RETIRED_NAMES_CHECK" "$SRC"
```

**VERIFY:** The committed file has 18 lines (header, separator, 16 rows); the `comm` line prints
nothing (every PV-D cited by a `BD-P` row is defined); every `BD-P` row the last line prints
(cites no PV-D id) appears in the "Departures that carry no PV-D row" table above, and person 2
initials each; `grep -rho 'PV-D-[0-9][0-9]'
"$WIKI_DIR"/platform/agentic-platform/pov/*.md | sort -u | wc -l` prints `16`; the names check
exits 0; person 2 merges the pull request with a second reviewer.

**ROLLBACK:** Revert the commit.

**EVIDENCE:** Commit id. E-05. TISAX 1.4.1, 5.2.1.

## 5. What the POV did not prove (`POV_GAP_STATEMENT`)

Written as a hostile reviewer would say it, and published with the claim, never after it.

1. **"You have not tested a super-admin robot. You have tested a helpdesk script."** G10, G11,
   G14, G20 and Eve G-7 are untouched. **Super-admin behaviour was not tested at all.** Nothing
   here says Wall-E is safe as a super admin.
2. **"Your controller lives inside the house it watches."** No witness organisation (PV-D-03);
   G1, G-2 and G18 are open. Eve is not independent of person 2, who owns it, approves person 1's
   grants and receives its reports. Nothing watches person 3.
3. **"Nobody answers at 02:00."** No SIEM, no 24x7 retainer (PV-D-10); G2 is open. The tabletop
   measured business hours.
4. **"No one tried to break in."** No penetration test (PV-D-11); G8 is half open.
5. **"Your baseline is a guess from console clicks."** Six months of Admin log events counts
   events, not minutes (PV-D-05). The minutes are imputed from a small timed sample, not read from
   Google, and are the weakest number in the value report. The tasks and the automation actors
   excluded were chosen by person 2 or person 3, not by the platform owner, but both work inside the
   programme being valued. Once Google's rolling retention passes the window, the volumes cannot be
   recomputed from the source; they are attested by the one-task recount of 02 PD-8.6, run in the
   same ISO week as the count, and by the hashed counts file in the locked bucket, not reproducible.
   The four prospective weeks are still owed.
6. **"Your 'real work' was on fake people."** The pilot accounts are synthetic (PV-06); nothing is
   known about employees' acceptance, error tolerance or the works council's view in practice.
7. **"Model Armor 'caught' nothing that matters."** It is a probabilistic screen: its findings are
   evidence, never a boundary, whatever the injection suite scored.
8. **"Band B has never run."** It is built at L0 and refuses (`BAND_B_DENIAL_RECORD`); nothing more.
9. **"Your autonomy stops at L3 because your verifier does not exist."** No platform verifier,
   register CI or validator (PV-D-13); no evidence exists for L4 or L5.
10. **"Your gates were parsed by the people who built them."** Two-person signed recomputations,
    not CI (PV-D-13), and no Binary Authorization (PV-D-12).
11. **"This is not EU AI Act conformity or a TISAX label."** It is the opening of an assessment
    file: every E-xx at `0` in PX-3.1 and every empty TISAX group in PX-3.2 is listed here by id.
12. **"Your kill switch numbers are from one drill each."** K0, K1, K3, K4, K7 were each pulled
    once in the demonstration; K5 and K6 do not exist at Tier W; K7's job path is BLOCKED (B-04).
13. Every step of files 01 to 09 whose last checkpoint is `BLOCKED` or `PENDING`, listed by id.
14. **"Hundreds of agents is unpriced."** The fourth-agent test measured a Tier C addition by hand;
    the marginal cost of a second Tier W agent (a new project, robot, keys, consent sitting and
    fork or configuration of the action service) or a Tier P agent, and the "register row and a
    factory run" claim (no factory, PV-D-01), were not tested. Nor is every agent in the Agent
    Registry: the two no-code Tier C agents are not registered, because Google documents no way to
    register a no-code agent by hand and automatic registration stays inside the app's own project
    (05 PG-6.3a).
15. **"Your nonprod never executed anything."** The nonprod service is credential-less (PV-D-04),
    so the rehearsal could not exercise an execution or a mid-run halt; the first of each was the
    recorded run itself.
16. **"Your doer never touched the Admin console."** The doer did no Admin-console task: in Track A
    it holds no Workspace admin role, and its operations are group-membership changes on groups it
    manages. The distance to a super-admin doer is not measured by this POV. **No real minute of
    admin work was saved**: the doer acts only on synthetic accounts and holds no Workspace admin
    role, so the value report measures the machinery and the baseline, not time saved.
17. **"Mo never looked at Eve."** Mo neither measured nor improved Eve, and did not read Eve's
    findings: it measured the doer against the baseline, nothing more. The value report's section
    on Eve's findings about the doer is PENDING by design (08 PM-8.4), and the full build's
    setup/29 owns it.
18. **"Your audit can be edited."** The audit is append-only by convention of the writer's code. A
    holder of the writer's permission or of Eve's dataset owner role could alter rows; alteration
    is **detected** by fingerprint, **not prevented** ([README.md](README.md) §2 item 8).
19. **"'No long contract' is a hope."** "No new contract with a lead time longer than weeks" rests
    on Assumptions: hardware keys procured, the key wait, and a billing account in 2 to 5 days
    (files 02 and 03).
20. **"Your run stopped at L2."** Only if PX-1.3 and PX-1.4 ran their L2 form: the promotion floor
    (`promotion_floor_n: 35`) was not met on 5 to 10 synthetic accounts, no approved execution
    happened, and the claim says L2. Omitted when `level.txt` read `L3`.

### PX-5.1 Sign the gap statement

**WHO:** Person 1 drafts; **person 3 checks each item against the build log**; person 2 co-signs.
**WHERE:** Shell.

**ACTION:**

```bash
need BUILD_LOG_DIR
REC="records/$(date -u +%F)-PX-5.1-pov-gap-statement-v1.md"
{ echo "# POV gap statement"; echo "Items 1 to 12 and 14 to 20: as pov/09 section 5, each with its record or deviation id."
  echo "## Item 13: steps not DONE"
  awk -F'\t' '{s[$2]=$3} END {for (k in s) if (s[k]=="BLOCKED" || s[k]=="PENDING") print "- " k " " s[k]}' "$BUILD_LOG_DIR/checkpoints.tsv" | sort
  echo "## E-xx at zero and empty TISAX groups"; echo "(from PX-3.1 and PX-3.2)"; } > "$BUILD_LOG_DIR/$REC"
penv_set POV_GAP_STATEMENT "$REC"
evidence_add PX-5.1 gap-statement E-05 1.5.1 "build-log:$REC" "$BUILD_LOG_DIR/$REC"
```

**VERIFY:** Item 13 lists every step whose newest checkpoint is `BLOCKED` or `PENDING`; person 3
initials each of items 1 to 12 and 14 to 20 against a record; none of the three banned sentences of README §1.2
appears.

**ROLLBACK:** A `-v2` supersedes.

**EVIDENCE:** The signed record. E-05. TISAX 1.5.1, 1.4.1.

## 6. The hand-over map (`HANDOVER_TABLE`)

The full build continues from the POV. "VERIFY" means the setup step reads the value the POV set
and does not create it again (README §7.1). A POV record never satisfies a full-set gate whose
conditions it lacks (README §7.3). **Every `POV_` and `DOER_` record and value is re-derived by the
full-set file that owns the bare name, and is never promoted by renaming it**: setup/17 derives its
own `TIER_R_RECORD`, setup/28 its own `EVE_H_LIVE_RECORD`, setup/33 and 34 Wall-E's own
`ACTIONS_URL` and `AGENT_PRINCIPAL`, and so on; the POV value is read as history and evidence of
method only. Where a cell below says "APPEND", the setup step adds rows to what the POV wrote and
never rewrites it; "SKIP" names why.

| setup | What the POV already produced | What the full build still does | POV record that satisfies it, or none |
|---|---|---|---|
| 01 | `~/.platform-env`, helpers, build log, registers, repositories; PR-2.6's values (`DOMAIN`, `DIRECTORY_CUSTOMER_ID`, `WORKSPACE_EDITION`, `OWNER_DAILY_ACCOUNT`, `ORG_ID`) set by POV 03 PF-1.1 | PR-2.6 as VERIFY; PR-3.3, PR-5.2 | PP-6.1; POV 03 PF-1.1 |
| 02 | Retrospective baseline, same CSV (PV-D-05) | Four prospective ISO weeks, TB-1 to TB-5, after the works-council answer | none for promotions above L3 |
| 03 | PV-01 to PV-13; inherited SD records; persons 1 to 3; `decisions/`, the decision tools and `decisions/TRACKER.md` (POV 01 PP-4.1); the platform repository with its protection | DC-1.1 and DC-1.2 as VERIFY; **DC-1.3 APPENDs** its rows to `TRACKER.md` and never rewrites the header or the POV's rows; DC-9.1 to DC-9.8 and DC-9.10 as VERIFY of the existing repository, CODEOWNERS and protection; remaining D, E, M, P records; P13, P14; security reviewer, validator custodian, witness administrators, five humans | POV 02 PD steps for the inherited ids only |
| 04 | Keys, licences, billing account | The long rows: SIEM and MDR, penetration test, SCC Premium, witness domain, sandbox tenant | none |
| 05 | `GE_INVENTORY_DIR`, `GEMINI_APP_ID` | GI-9.4 re-check only | POV 05 inventory |
| 06 | Roster, two admin accounts, break-glass, G3 | VERIFY; G3 re-read at 38 | `ROSTER_FILE` |
| 07 | `BILLING_ACCOUNT_ID`, budgets | VERIFY; `BOOTSTRAP_BILLING_EXPIRY` | POV 03 |
| 08 | nothing (PV-D-03) | In full | none |
| 09 | Whole folder tree, tag keys, `register/folders.yaml` (POV 03 PF-3.1a), SCC Standard with `SCC_TIER=STANDARD/eu` | FS-4.1 and FS-4.2 as VERIFY; FS-7 SCC Premium (PV-D-02), whose FS-7.5 overwrites `SCC_TIER` with `penv_set --force` and a build-log line, because `penv_set` writes once. Until then setup/13, 15 and 20 test `SCC_TIER = PREMIUM/eu` and stop, which is the intended fail-closed behaviour | POV 03 folder steps |
| 10 | Core projects | CI identities and anything POV 03's Status does not list | POV 03 |
| 11 | Rings logging, gemini, engines, supply-chain; eve, eve-eu (POV 06) | §8 validator custodian (B-13) | POV 03, 06 |
| 12 | Entitlements for the POV's scope: POV 03's core rows; `ent-ge-admin` and `ent-project-repair-tenant-app` (05); `ent-project-repair-eve` (06); `ent-project-repair-<doer>` and `ent-deploy-credential-holder-<doer>` (07); `ent-bootstrap-module-improvers-prod` and `ent-project-repair-mo` (08) | VERIFY each against `PAM_ENTITLEMENTS`; full catalogue, P-SA singletons | none for P-SA rows |
| 13 | Folder policies, deny, PAB | VERIFY; rows for folders the POV left empty | POV 03 |
| 14 | Organisation sink, two log buckets, Workspace sharing | Billing export if POV 03 did not build it (`Assumption:` it did not) | POV 03 |
| 15 | Two notification channels | Part A paging service and subject escalation; part B SIEM (PV-D-10) | none |
| 16 | Register rows (the doer, Eve, Mo; the two Tier C agents of POV 05 PG-6.1; the optional Tier P row of POV 07 PW-7.2; PX-7.1's fourth agent), signed manual parse (PV-D-13); contract files `contract/1.0.0/audit.schema.json`, `ladder.schema.json`, `audit-actions.bq.json`, `ci/register-rules.md`, `register/reserved/names.yaml`, `mo/datasets.json` (POV 04) | RG steps as VERIFY of those files; register CI (B-03), shared registry; every row kept, none rewritten | `MANUAL_PARSE_RECORD` until B-03 |
| 17 | `POV_TIER_R_RECORD` by hand; run specs `factory/runs/<agent_id>-<env>.json` for `EVE_PROJECT`, `DOER_PROJECT`, `DOER_NONPROD_PROJECT` and `MO_PROJECT` where files 06, 07 and 08 committed them (Preconditions) | FM-1.2's `fm-zero-diff.py live` against each POV agent project must read `ZERO-DIFF` before the import; a `DIFF` or a missing spec is rework (labels, lien, budget, `--no-enable-cloud-apis`); factory runs and `terraform import` when B-01 lands; its own `TIER_R_RECORD` | none; `POV_TIER_R_RECORD` is history under PV-D-01 |
| 18 | Model Armor floors (`FLOOR_RECORD`); K7 human path (`K7_POLICY_DIR`) | Spikes KS-3, canary engine, K7 job path (B-04) | `POV_K7_FIRST_DRILL_RECORD` as history, not G20 |
| 19 | Gemini Enterprise baseline | VERIFY; the 14-day dry run if POV 05 did not run it | POV 05 |
| 20 | `POV_TIER_C_RECORD`, partly; the two Tier C agents of POV 05 PG-6 | The SCC Premium row; gateway steps POV 05 did not run; its own `TIER_C_RECORD`; the two agents re-admitted as VERIFY, never re-created | none for G21 until the row closes |
| 21 | nothing (Track B) | In full (§8) | none |
| 22 | Mo datasets on SD-33 names, `mo-metrics@`; the `IMP` register-schema amendment applied early by POV 04 PC-1.2 | **MO-1.1 becomes a VERIFY** of the merged schema values (its `jq` writes `$defs.row.properties.agent_id`, a path the POV deliberately did not use: read the merged value, never re-apply); the prospective baseline load; the Wall-E pack | POV 08; POV 04 PC-1.2 |
| 23 | `EVE_PROJECT`, datasets, locked bucket; the `CTL` register-schema amendment applied early by POV 04 PC-1.2 | VERIFY; **EP-1.1 becomes a VERIFY** of the merged values; `EVE_TWIN_PROJECT`; the rest of B-07 | POV 06; POV 04 PC-1.2 |
| 24 | `SERVICE_IDENTITY_OU` (POV 07) and `PILOT_OU` (POV 07); otherwise nothing (PV-D-07) | In full, after 08 and 21; the two OUs as VERIFY | none |
| 25 | SQL detections as scheduled queries `POV_EVE_H_QUERY_SET`, and `eve/config` in `EVE_CONFIG_REPO` (POV 06; PV-D-06) | `EVE_CONFIG_REPO` as VERIFY; reconciler B-08, reading the same config; the `POV_EVE_H_QUERY_SET` queries are retired once the reconciler's detections are proven, never renamed | none for G-5 |
| 26 | Routes to persons 2 and 3, first run (`POV_EVE_FIRST_RUN_RECORD`) | Witness export; route re-test; its own `EVE_FIRST_RUN_RECORD` | none; `POV_EVE_FIRST_RUN_RECORD` is history, read by ER-0.2 only to compare recipients |
| 27 | nothing | In full | none |
| 28 | `POV_EVE_H_LIVE_RECORD`, `POV_EVE_PROOF_RECORD`, `POV_ANTI_SILENCING_RECORD`, all without witness | Full proof with witness alarms; its own `EVE_H_LIVE_RECORD` | **none**: G1 needs the witness |
| 29 | Part of `eve_quality` (POV 08) | Full pack | none |
| 30 | Pattern: robot account, groups, DWD absence proof, for the doer; `SERVICE_IDENTITY_OU` and `PILOT_OU` (POV 07) | Creates `walle@` fresh, with the same procedure; the two OUs as VERIFY | none; the doer's robot stays the doer's |
| 31 | Nine audit schemas on `audit.schema` (PB-01), for `<agent_id>_audit`, committed in `<AGENT_ID_DOER>/schemas/` of the platform repository (POV 04 PC-2.4); WD-1.1's two amendments applied early by POV 04 PC-1.2 | **WD-1.1 becomes a VERIFY** of the merged values; creates `WALLE_PROJECT` in `fld-agents-p-sa-prod` and `walle_audit` **from the same schema files**, copied into the location WD-4.5 reads, which is Wall-E's own and not the doer's directory; B-22 becomes "apply" | none; B-22 shrinks |
| 32 | Consent bootstrap (PB-05) and the two-person sitting | Runs the same bootstrap for Wall-E's two clients; B-17 closes on the POV's code | none |
| 33 | Action service, ladder module, approval page, K0 to K4 endpoints (PB-04) | Forks the doer's code at `DOER_CODE_COMMIT`; adds the super lane, dispatcher and band-B surface; B-16 shrinks to those | none |
| 34 | `DOER_AGENT_IDENTITY_MODE`, `DOER_AGENT_PRINCIPAL` | The spike for Wall-E's engine; its own `AGENT_IDENTITY_MODE` and `AGENT_PRINCIPAL` | none |
| 35 | Engine, gateways (failOpen false) for the doer | Same for Wall-E; GE-12 admission | none |
| 36 | Eve v0 queries over `DOER_AUDIT_DS`, `DOER_EVE_V0_CONFIGS`, display names `eve-v0-agent-<agent_id>-m01` to `-m12` (POV 06 PE-11.2) | WJ-4.4 creates Wall-E's own twelve over `walle_audit` as `EVE_V0_CONFIGS`, display names `eve-v0-m01` to `-m12`, in the same `EVE_PROJECT`; its `startswith("eve-v0-m")` selector and its count of `12` do not see the doer's configs, which stay as the doer's v0; Mo's Wall-E pack | none |
| 37 | nothing (Track B) | In full (§8) | none |
| 38 | Tabletop method (POV grade) | The gate, the P-SA tabletop, the grant | **none** |
| 39 | Stage-0 shape at Tier W | Stage 0 on production | none |
| 40 | `POV_FIRST_MERGE_RECORD` (POV grade); the `MO_PROPOSALS` bucket; the grader list `mo/config/metrics/graders/<AGENT_ID_DOER>.yaml` in the platform repository (POV 08 PM-7.1) | `MO_PROPOSALS` as VERIFY; the grader list **copied across** into the agent's own repository as `config/metrics/graders.yaml`, where MA-5.4 reads it; first merge after Stage 0 with a deployed validator; its own `FIRST_MERGE_RECORD` | **none** |
| 41 | nothing | In full | none |
| 42a | `PLATFORM_EVIDENCE_BUCKET`, `RECORD_RETENTION_DAYS`, `EVIDENCE_PACK_DIR`, `POV_TIER_W_RECORD` (POV grade) | GD-2.2 writes its own `TIER_W_RECORD`, which the POV never set, once PV-D-12 and PV-D-13 unwind; GD-3 and GD-4 as VERIFY | bucket and pack dir only |
| 42b | `DR-P` drill rows and their records | Consolidation, re-pin, quarterly review | the drill history |

**Why setup/30 to 39 create Wall-E fresh.** This is the design's own thesis, not a compromise:
the four-hundredth agent costs a register row and a factory run because `agent_id`,
`audit.schema` and `ladder.schema` are shared ([../05-registry-and-autonomy-contract.md](../05-registry-and-autonomy-contract.md)
§9.3, §9.4). Wall-E is the second agent on the doer's code, not a rename of the first. The doer
keeps its Tier W row and its project; it is not deleted.

**Cost remaining after the POV.** `Assumption:` the full build's 85 to 90 person-days
([../setup/README.md](../setup/README.md) §3.2) less the POV's 20 to 26 gives 60 to 70
person-days of procedure; code remaining is the full Eve (36 to 45) and Mo (24 to 37) less PB-03
and PB-06, plus B-16's super lane and dispatcher (*tbd*, not estimated in the full set); calendar
to the grant is set by the long purchases, not by the POV.

### PX-6.1 Commit the hand-over table

**WHO:** Person 1; person 2 reviews. **WHERE:** Shell.

**ACTION:** Save this section's table to the platform repository and record the path.

```bash
need WIKI_DIR PLATFORM_REPO_DIR
SRC="$WIKI_DIR/platform/agentic-platform/pov/09-the-demonstration-deviations-and-the-hand-over.md"
awk '/^\*\*Why setup\/30 to 39 create/{p=0} p && /^\|/{print} /^## 6\. The hand-over map/{p=1}' "$SRC" > "$PLATFORM_REPO_DIR/decisions/pov-handover.md"
penv_set HANDOVER_TABLE "decisions/pov-handover.md"
git -C "$PLATFORM_REPO_DIR" add decisions/pov-handover.md && git -C "$PLATFORM_REPO_DIR" commit -m "PX-6.1 POV hand-over table"
```

Then list every name any POV file sets that the table does not mention, for person 2 to place:

```bash
H="$PLATFORM_REPO_DIR/decisions/pov-handover.md"
grep -hoE 'penv_set +(--force +)?[A-Z][A-Z0-9_]+' "$WIKI_DIR"/platform/agentic-platform/pov/0[1-9]-*.md | awk '{print $NF}' | sort -u |
  while read -r n; do grep -qw -- "$n" "$H" || echo "$n"; done | tee "$BUILD_LOG_DIR/records/$(date -u +%F)-PX-6.1-unmapped-names-v1.txt"
```

**VERIFY:** `grep -c '^| [0-9]' "$PLATFORM_REPO_DIR/decisions/pov-handover.md"` prints `43` (01
to 41, 42a, 42b); person 2's review confirms each "VERIFY" row names a value the POV set; every
name in `unmapped-names` is either covered by a row's scope (person 2 writes the row number beside
it) or gets a cell added before the merge; every file's "What the next file needs" row for setup
consumers is read against the table the same way; no cell promotes a `POV_` or `DOER_` value to a
bare full-set name.

**ROLLBACK:** Revert the commit.

**EVIDENCE:** Commit id. E-05. TISAX 1.3.1, 5.2.1.

## 7. The fourth-agent test

### PX-7.1 Add a Tier C agent and time it (`FOURTH_AGENT_RECORD`)

**WHO:** Person 1 performs; person 2 approves the register pull request and the admission; the AI
compliance owner signs the purpose statement; the non-admin colleague runs the visibility test.
**WHERE:** Platform repository (`REGISTER_PATH`); Gemini Enterprise web app, + Create agent > Chat
agent; the admin sharing controls of file 05.

> **IRREVERSIBLE**: the new `agent_id` is permanent and joins every record keyed on it. Confirm
> first: the id is in PV-03's names register form and is not reserved; the agent has a genuine,
> small read-only use (a throwaway row would spend a permanent id on nothing, so the row is kept);
> PV-11's classification applies. Gate:
> PV-03 and PV-11 signed.

**ACTION:** Start the clock, then follow **only** the procedures that already exist: file 04's
register-row steps for one Tier C row (the manual parse, PV-D-13), and file 05's Tier C admission
steps (Model Armor on, sharing restricted, injection suite subset).

```bash
need BUILD_LOG_DIR REGISTER_PATH
T0="$(date -u +%s)"; echo "$T0" > "$BUILD_LOG_DIR/records/$(date -u +%F)-PX-7.1-t0.txt"
```

At the end, record hands-on minutes per person and elapsed hours, and list **anything that had to
be invented** (a new variable, a new schema, a new project, a new entitlement, a new decision).

**VERIFY:** The row passes the manual parse; the agent answers in the web app for a member of the
intended group and is **invisible** to the non-admin colleague outside it; the invented list is
empty. A non-empty list is the most important finding of the POV: it names what is not yet "a
register row and a factory run" (01-hld line 90). `Assumption:` target under one person-day
hands-on and under one week elapsed, most of it signatures. **Limit:** this measures a Tier C
addition by hand only. It says nothing about a second Tier W or a Tier P agent, where "hundreds of
agents" is priced, and nothing about the factory (PV-D-01); the record says so, and §5 item 14
carries it. Optional: time a paper walk-through of a second Tier W register row against file 07's
step list and record the count of new projects, robots, keys, sittings and entitlements it names.

**ROLLBACK:** None for the id. The agent can be unshared and its row set to retired through a
superseding register change; it is never deleted.

**EVIDENCE:** `records/<date>-PX-7.1-fourth-agent-v1.md` with times and the invented list;
`penv_set FOURTH_AGENT_RECORD <path>`; `evidence_add PX-7.1 fourth-agent E-05 1.3.1 …`. E-05.
TISAX 1.3.1.

## 8. Track B costed (`TRACK_B_ESTIMATE`)

**The sentence that governs the POV:** nothing from Track B is smuggled into Track A, and no Track
A result is evidence about a super admin (PV-04).

Track B is the only route to the super-admin containment evidence: G10 (denial suite on the twin),
G11 (K6 on the twin robot), G14 (a band-B `SUPER` dry run with two humans), G20 (K7 on
`fld-agents-p-sa-nonprod` with a live P-SA project), Eve G-7, and the twin half of G13. It is not
started by the POV. Every figure below is the full set's own estimate, `Assumption:` unless the
file marks it measured.

| Item | Source | People | Hands-on | Elapsed | Purchase |
|---|---|---|---|---|---|
| Sandbox Workspace tenant, own domain, edition equal to production and at least Enterprise Standard, seats for two sandbox super admins, two twin robots and synthetic accounts | setup/04 PU-2.5 row 5 | procurement; finance; domain owner | 0.5 d | weeks (second customer contract) | subscription *tbd*; domain *tbd* |
| Tenant, organisation, keys, sharing, nonprod folder rules | [../setup/21](../setup/21-sandbox-tenant-and-nonprod-foundation.md) | **two sandbox super admins (persons 4 and 5)**; person 2 witnesses keys | 2 d over four sittings | 1 to 4 weeks (DNS up to 72 h, the up-to-7-day key wait, 24 h log wait) | 4 hardware keys, 4 envelopes (setup/04) |
| Twin Eve (identity and drills) | setup/23, 24, 28 | persons 2, 4, 5 | *tbd* | needs the witness (PV-D-03) for G-7's full form | none new |
| Twin Wall-E, denial suite, K0 to K6, band-B dry run, K7 on P-SA nonprod, restore | [../setup/37](../setup/37-wall-e-sandbox-rehearsal.md) | person 1; persons 4 and 5 (4 requests, 5 approves and pulls K6); person 2 witnesses | about 31 h over nine sittings | about four weeks, mostly the penetration test and B-16 | the penetration test (PV-D-11) |
| The gate, the P-SA tabletop, the grant | [../setup/38](../setup/38-super-admin-gate-and-grant.md) | five humans, or four with an ISMS exception (SD-04); incident commander; security reviewer; ISMS | tabletop half a day; gate day 90 min; checklist 1.5 d | weeks to months, bounded by G2 (SIEM and MDR, PV-D-10) | SIEM and MDR retainer |

**Four distinct humans minimum for Track B:** person 1, person 2, and two sandbox super admins who
are neither (setup/03 people rows, setup/21 WHO lines). The grant itself needs five.

**Code Track B needs beyond the POV:** B-16's super lane, dispatcher and band-B surface; B-17 for
the twin's External clients (the POV's PB-05 is the base); B-08 and B-10 for Eve's twin identity.
`Assumption:` not estimated in the full set; *tbd*.

**Earliest start:** `Assumption:` week 13, and not before PV-04 is superseded by a signed record.

### PX-8.1 Record the estimate

**WHO:** Person 1 drafts; IT security and the ISMS review. **WHERE:** Shell.

**ACTION:** Save the table above with a date and the current prices read on the day from the
reseller's quote (never from this page), then:

```bash
need BUILD_LOG_DIR
REC="records/$(date -u +%F)-PX-8.1-track-b-estimate-v1.md"
test -s "$BUILD_LOG_DIR/$REC" || { echo "STOP: write the dated estimate first"; false; }
penv_set TRACK_B_ESTIMATE "$REC"
evidence_add PX-8.1 track-b-estimate - 1.4.1 "build-log:$REC" "$BUILD_LOG_DIR/$REC"
```

**VERIFY:** The record names four distinct roles for persons 1, 2, 4 and 5, none repeated; every
price has a quote reference and a date, or reads *tbd*.

**ROLLBACK:** A `-v2` supersedes.

**EVIDENCE:** The record. E-xx: none. TISAX 1.4.1.

## 9. Stop or continue, and the closing report

### PX-9.1 The dated stop-or-continue record (`POV_STOP_OR_CONTINUE_RECORD`)

**WHO:** Person 1 drafts; **signatories per PV-13: platform owner, ISMS, person 2**; the DPO and
the works council or HR contact are informed.
**WHERE:** `decisions/` in the platform repository, in the format of
[../setup/03](../setup/03-decisions-and-people.md) lines 54 to 271.

> **IRREVERSIBLE**: decision records are append-only; a change is a new record whose Supersedes
> line names this one. Confirm first: the review date equals `POV_END_DATE`; `POV_DEMO_RECORD`,
> `POV_GAP_STATEMENT`, `POV_VALUE_REPORT` and `TRACK_B_ESTIMATE` exist. Gate: PV-13 signed.

**ACTION:** Write `decisions/<POV_END_DATE>-pov-stop-or-continue.md` with the seven headings.

- **Context:** the claim as it stands after striking; the demo record's measured table; the value
  report's baseline, counts and minutes with `n` and lower bounds; the gap statement; cost to date
  from the billing budget; the fourth-agent time.
- **Options considered:**
  - **A. Continue to the full build**, from the hand-over table, starting with the long purchases
    of setup/04 and the witness of setup/08.
  - **B. Hold at POV scope**: the doer stays at L3 on synthetic accounts; Eve and Mo keep running;
    the `DR-P` drills keep their cadence; re-review in a dated number of weeks.
  - **C. Stop**: the platform goes **dormant, not away**. K1 demotes every doer cell to L0 and K0
    halts writes (two-person record, since resuming later is a raise); schedules paused by the
    K2 procedure; Tier C agents unshared; **Eve keeps watching the human super admins**, because
    removing that watch is a regression the POV created no licence for; Mo's schedules paused;
    budgets and retention locks left as they are; register rows kept with a dated status note.
- **Decision:** A, B or C, with the named reason.
- **Values:** the review date; for B, the next review date; for C, the date the dormant state was
  verified.
- **Gates:** for A, PV-04 superseded before any Track B step; for any option, no real account
  enters `PILOT_OU` without PV-06's three conditions and PV-D-15's DPIA.
- **Consequences:** which PV-D unwind triggers are now live, each with a dated action and an
  owner (PV-D-13's is live if file 07 §7's Tier P row was built).
- **Signatures:** three.

**Nothing is deleted in any option**: no project, dataset, bucket, key ring, tag, register row or
record. Every name is permanent and belongs to the full build.

```bash
need PLATFORM_REPO_DIR POV_END_DATE
F="decisions/${POV_END_DATE}-pov-stop-or-continue.md"
"$PLATFORM_REPO_DIR/tools/decision-check.sh" "$PLATFORM_REPO_DIR/$F"
penv_set POV_STOP_OR_CONTINUE_RECORD "$F"
evidence_add PX-9.1 stop-or-continue E-03 1.4.1 "repo:$F" "$PLATFORM_REPO_DIR/$F"
```

**VERIFY:** `decision-check.sh` prints `OK` for the file; after merge,
`"$PLATFORM_REPO_DIR/tools/decision-need.sh"` on the record's id prints `SIGNED`; for option C, a
dormant-state read shows every doer cell at L0, `halt_epoch` incremented, Eve's last run under 24
hours old, and no resource deleted (`gcloud projects list --filter="parent.id=${FLD_AGENTS_W_NONPROD}"
--format="value(projectId)"` still lists `DOER_NONPROD_PROJECT`, and the same for each POV folder).

**ROLLBACK:** None; a superseding record.

**EVIDENCE:** The merged record. E-03. TISAX 1.4.1.

### PX-9.2 The closing report (`POV_CLOSING_REPORT`)

**WHO:** Person 1 writes; person 2 checks each clause of the claim against a record; ISMS, DPO,
AI compliance owner and the works council or HR contact receive it.
**WHERE:** Shell; the wiki.

**ACTION:** One page: `POV_CLAIM_STATEMENT` from [README.md](README.md) §1.1, word for word, with
the two dates filled and **every clause whose record is missing, BLOCKED or PENDING struck, not
softened**; below it, `POV_GAP_STATEMENT` in full; then the stop-or-continue decision; then both
calendar figures of `POV_STAGE_DATES` (POV-1 and POV-2), so no reader is told "three weeks" alone.
The sentence is this one, identical to README §1.1, and no other:

> Between `<start date>` and `<end date>`, on the production tenant, with three hands-on people, one
> engineer and the named approvers listed in the README's §5.2a, and no new contract for a product
> or service with a lead time longer than weeks, the platform's containment machinery was built
> and run: a governed Gemini Enterprise with admission as a register row, a Model Armor floor, an
> Agent Registry whose write alert was drilled and in which the doer's engine is registered, kill
> levers that were pulled during live work, a controller that reported on every human super admin
> to someone who is not the subject of the report, a doer that holds no Workspace admin role, whose
> model holds no credential and whose every action is written ahead to an audit dataset with one
> writer identity, where alteration is detected by fingerprint, not prevented, and an improver
> that measured the doer against a baseline of volumes from Google's own admin history and minutes
> from a timed sample. Every artefact created carries
> the full build's name, schema and folder.

```bash
need BUILD_LOG_DIR POV_DEMO_RECORD POV_GAP_STATEMENT POV_STOP_OR_CONTINUE_RECORD
REC="records/$(date -u +%F)-PX-9.2-pov-closing-report-v1.md"
test -s "$BUILD_LOG_DIR/$REC" || { echo "STOP: write the report first"; false; }
grep -niE 'safe as a super admin|is independent|blocked the injection' "$BUILD_LOG_DIR/$REC" && echo "FAIL: banned sentence" || echo "no banned sentence"
penv_set POV_CLOSING_REPORT "$REC"
evidence_add PX-9.2 closing-report E-05 1.5.1 "build-log:$REC" "$BUILD_LOG_DIR/$REC"
"$RETIRED_NAMES_CHECK" "$WIKI_DIR"/platform/agentic-platform/pov/*.md; echo "names exit $?"
checkpoint PX-9.2 DONE "$SECOND_HUMAN_EMAIL" "build-log:$REC" "POV closed"
git -C "$BUILD_LOG_DIR" push origin main
sitting_end
```

**VERIFY:** `no banned sentence`; `names exit 0`; person 2 has initialled each surviving clause
with its record id; the recipients' acknowledgements are filed; the remote build log equals the
local `HEAD`.

**ROLLBACK:** A `-v2` supersedes.

**EVIDENCE:** The report and acknowledgements. E-05, E-12 (worker information, for the works
council copy). TISAX 1.5.1.

## Verification checklist for part 09

- [ ] `POV_DEMO_DIR` persisted; every PX-1.x step has START and DONE (or BLOCKED/PENDING) lines;
      PX-1.7's START was written before the revoke.
- [ ] Person 2 is not a member of `GRP_DOER_OPERATORS` on the demonstration day, and approves
      nothing on the doer's approval page.
- [ ] PX-1.2 rehearsal done on nonprod (halt and demote against denied requests only) before any
      recorded beat; K4 not pulled there.
- [ ] `level.txt` read by person 3 before PX-1.3; if `L2`, PX-1.3 and PX-1.4 ran their L2 form,
      recorded at L2, and the claim says L2.
- [ ] Every POV agent project has a run spec reading `ZERO-DIFF`, or the gap is in §5 item 13 and
      §6 row 17.
- [ ] L1 rows are `shadow` only; the approved L3 execution names person 3, neither person 1 nor
      person 2; the replay is refused `a:approval_already_used`; the write-ahead check matched at
      least one event in the catalogued stream and no effect lacks an audit row.
- [ ] K0 pulled by person 3 with no approval during a live multi-item run, measured from logs;
      halt cleared by person 1 requesting and person 3 approving.
- [ ] K1, K3, K4 and K7 each timed from Google-written logs or the audit; K2's record younger than
      30 days; K4 before K7; K4's residue in seconds recorded and judged against PV-01's threshold.
- [ ] Eve's report of the planted action reached person 2, who was not told, within the lag budget.
- [ ] Mo's figures recomputed by person 3; no claim above L3.
- [ ] Tabletop run by the incident commander; `POV_TABLETOP_RECORD` marked as not G17.
- [ ] Evidence pack assembled, three groups hand-checked by person 3, copied to the locked bucket,
      ISMS acknowledged.
- [ ] `PV_DEVIATION_REGISTER` extracted, 16 rows, every inline PV-D defined, names check clean.
- [ ] `POV_GAP_STATEMENT` lists every `BLOCKED` and `PENDING` step, every zero E-xx by id, and
      README §1.1's named gaps (items 1, 14 and 16 to 19).
- [ ] `HANDOVER_TABLE` has 43 rows; no POV record claims a G line it lacks.
- [ ] Fourth agent timed; the invented list is recorded (empty or not).
- [ ] `TRACK_B_ESTIMATE` names four distinct humans and dated prices or *tbd*.
- [ ] `POV_STOP_OR_CONTINUE_RECORD` signed by the three PV-13 signatories; nothing deleted in any
      option.
- [ ] `POV_TABLETOP_RECORD` signed, scanned for secrets and personal data, then copied to the locked
      bucket.
- [ ] `POV_CLOSING_REPORT` quotes the claim of README §1.1 with struck clauses, and both stage
      figures.

## What the next file needs from this one

There is no POV file 10. The consumers are the full build and the people who decide:

| Consumer | Needs |
|---|---|
| [../setup/README.md](../setup/README.md) and the full build | `HANDOVER_TABLE` (where to start and which steps become VERIFY); `PV_DEVIATION_REGISTER` (each unwind trigger is a precondition of the setup file named); `EVIDENCE_PACK_DIR` (setup/42 GD-4.3 reads it as existing) |
| [../setup/38](../setup/38-super-admin-gate-and-grant.md) | the rule that `POV_TABLETOP_RECORD` and `POV_FIRST_MERGE_RECORD` satisfy no G line; GT-2.3 writes its own `TABLETOP_RECORD` and setup/40 its own `FIRST_MERGE_RECORD`, names the POV never sets |
| [../setup/42](../setup/42-gates-drills-and-evidence.md) GD-5 | `K0_DRILL_RECORD`, `K1_DRILL_RECORD`, `K4_DRILL_RECORD`, `K7_POV_DRILL_RECORD` as drill history, and the measured K4 residue for GD-5.5 |
| Wall-E owner (setup/30 to 36) | `DOER_CODE_COMMIT`, the audit DDL commit, `LADDER_FILE`, the consent bootstrap, the measured K4 residue |
| Sponsor, ISMS, works council | `POV_CLOSING_REPORT`, `POV_GAP_STATEMENT`, `POV_STOP_OR_CONTINUE_RECORD`, `TRACK_B_ESTIMATE`, `FOURTH_AGENT_RECORD` |
| [README.md](README.md) | §8's BLOCKED rows unchanged (this file opens none); §11's gate table re-read against the demo record |

## Checked against Google's documentation on 2026-09-16

- [Data retention and lag times](https://knowledge.workspace.google.com/admin/reports/data-retention-and-lag-times),
  last updated 2026-09-10: Admin and OAuth Token log events retained 6 months; Admin log events
  lag "near real time (couple of minutes)", OAuth Token events "a couple of hours";
  administrators cannot delete log event data or change retention (PX-1.9, PV-D-05).
- [Groups Enterprise log events](https://knowledge.workspace.google.com/admin/reports/groups-enterprise-log-events),
  last updated 2026-09-10: records actions on groups and group memberships from the Admin console,
  Google Cloud console, Admin SDK API, Cloud Identity API and the Groups interface, including by a
  group owner; the retention and lag page gives no lag for this stream (Preconditions, PX-1.3).
- [gcloud identity groups memberships check-transitive-membership](https://docs.cloud.google.com/sdk/gcloud/reference/identity/groups/memberships/check-transitive-membership):
  `--group-email`, `--member-email`; the page names no output fields (Preconditions).
- [Assign specific admin roles](https://knowledge.workspace.google.com/admin/users/assign-specific-admin-roles),
  last updated 2026-09-16: Menu > Account > Admin roles, select role, Assign admin; unassign from the
  same page with Unassign role (PX-1.9).
- [OAuth 2.0 for iOS and desktop apps](https://developers.google.com/identity/protocols/oauth2/native-app),
  "Revoking a token": POST to `https://oauth2.googleapis.com/revoke`; revoking an access token with
  a refresh token also revokes the refresh token; success is HTTP 200; revocation invalidates
  issued access and refresh tokens for the project's clients (PX-1.7).
- [OAuth 2.0 for web server applications](https://developers.google.com/identity/protocols/oauth2/web-server):
  `expires_in` is the access token's remaining lifetime (example 3920 s); no statement read on
  whether revoking a refresh token invalidates access tokens already issued from it.
- [gcloud run services remove-iam-policy-binding](https://docs.cloud.google.com/sdk/gcloud/reference/run/services/remove-iam-policy-binding):
  `SERVICE --member --role [--region]`, `--project` optional (PX-1.6); the add form is its pair.
- [Managing access (Cloud Run)](https://docs.cloud.google.com/run/docs/securing/managing-access):
  `gcloud run services get-iam-policy SERVICE_NAME`; no propagation time stated.
- [Access change propagation](https://docs.cloud.google.com/iam/docs/access-change-propagation):
  allow and deny policy changes typically 2 minutes, potentially 7 minutes or longer (PX-1.6).
- [gcloud run services list](https://docs.cloud.google.com/sdk/gcloud/reference/run/services/list):
  `--region`, `--filter`, `--format` (PX-1.6).
- [gcloud logging read](https://docs.cloud.google.com/sdk/gcloud/reference/logging/read):
  `--freshness` (default 1d), `--limit`, `--order` (`desc` default, `asc`), `--format`,
  `--project` (PX-1.4 to PX-1.7).
- [Cloud Run logging](https://docs.cloud.google.com/run/docs/logging): resource type
  `cloud_run_revision`; request log `run.googleapis.com%2Frequests` carries `httpRequest` (PX-1.4).
- [bq command-line reference](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference):
  global `--project_id`; `query --use_legacy_sql=false --format` (PX-1.3 to PX-1.7).
- [gcloud storage cp](https://docs.cloud.google.com/sdk/gcloud/reference/storage/cp):
  `--recursive` copies a directory tree (PX-2.1, PX-3.3).
- [Create a no-code agent (Gemini Enterprise)](https://docs.cloud.google.com/gemini/enterprise/docs/agent-designer/create-agent):
  web app menu, + Create agent > Chat agent; the page states no creator role or sharing-approval
  control (PX-7.1).
- K7 commands are not re-read here: they are setup/18 KS-6.1 to KS-6.5's, re-read there on
  2026-09-16.

## Could not verify

- **The K4 residue.** Google's native-app page says revocation invalidates issued access tokens;
  the design ([../../wall-e/04-flows.md](../../wall-e/04-flows.md) Flow G;
  [../setup/42](../setup/42-gates-drills-and-evidence.md) GD-5.5) says an issued access token stays
  valid up to 60 minutes. The two disagree, and PX-1.7 measures rather than asserts. Whether the
  statement applies to server-side web clients as well is not stated on the web-server page.
- The output field of `check-transitive-membership` (`hasMembership` is the API's field name,
  not shown on the gcloud page) and whether the transitive check needs a premium edition; the
  direct `memberships list` check is the one that must pass.
- Which stream and event name each of the doer's six operations produces; this is read from real
  events and recorded in file 07's catalogue (Preconditions), not asserted here. The Groups
  Enterprise stream's lag is not stated by Google; file 06 keeps 240 minutes as `Assumption:`.
- That `gcloud run services list --filter="status.url=…"` matches the service URL exactly; if it
  prints nothing, read the name from file 07's records instead.
- That `--member` accepts `DOER_AGENT_PRINCIPAL` in the `principal://agents…` form for a Cloud Run
  binding; file 07 recorded the form it bound, and PX-1.6 uses that value unchanged.
- That `DOER_AUDIT_DS` holds the dataset id alone and the audit tables and columns are exactly
  `actions` and `ladder_events` with the contract columns of [../05-registry-and-autonomy-contract.md](../05-registry-and-autonomy-contract.md)
  §9.4 as named in [../../wall-e/03-lld.md](../../wall-e/03-lld.md) "Storage" (PB-01 not written).
- That the doer's approval page offers halt, demote and revoke-credential controls: PB-04's scope in
  README §8 names the approval endpoint and the six operations, and setup/33 names the three
  control endpoints; the page's controls are an `Assumption:` until PB-04 is `DONE`.
- That `PLATFORM_EVIDENCE_BUCKET` holds a `gs://` URL, as setup/42 GD-5.10's usage implies.
- Gemini Enterprise's admin control for who may create and share agents: not stated on the page
  read; file 05 holds the settings it verified.
- Sandbox tenant and penetration-test prices: not read; *tbd* until quoted.
- Every hands-on, elapsed and code figure in this file is an `Assumption:`, the POV's or the full
  set's.

## Sources

- [README.md](README.md) §1 to §13: the claim, absolutes, stages, step prefixes, variable register
  and the rule that a POV record never satisfies a full-set gate (§7.3), BLOCKED index, PV and PV-D
  indexes.
- [01-conventions-and-variables.md](01-conventions-and-variables.md): helpers, `DR-P` drill rows,
  the POV E-xx and TISAX mapping (PP-3.2), `RETIRED_NAMES_CHECK`.
- [../setup/README.md](../setup/README.md) §3.2, §3.4, §5.1, §7 to §10.
- [../setup/42-gates-drills-and-evidence.md](../setup/42-gates-drills-and-evidence.md) GD-4.1 to
  GD-4.3, GD-5.2 to GD-5.5, GD-5.10.
- [../setup/18-model-armor-floor-spikes-and-kill-switch.md](../setup/18-model-armor-floor-spikes-and-kill-switch.md)
  KS-6.1 to KS-6.5.
- [../setup/21](../setup/21-sandbox-tenant-and-nonprod-foundation.md),
  [37](../setup/37-wall-e-sandbox-rehearsal.md), [38](../setup/38-super-admin-gate-and-grant.md)
  Status blocks; [../setup/04-purchases-and-lead-times.md](../setup/04-purchases-and-lead-times.md)
  PU-2.2, PU-2.5.
- [../setup/33-wall-e-action-services-and-approval-surfaces.md](../setup/33-wall-e-action-services-and-approval-surfaces.md):
  `/v1/control/halt`, `/v1/control/demote`, `/v1/control/revoke-credential`.
- [../04-identity-and-privileged-access.md](../04-identity-and-privileged-access.md) §9.6, §9.7.
- [../../wall-e/04-flows.md](../../wall-e/04-flows.md) Flow G; [../../wall-e/03-lld.md](../../wall-e/03-lld.md)
  "Storage" and "Denial reasons".
- [../10-eu-ai-act.md](../10-eu-ai-act.md) §5; [../11-tisax.md](../11-tisax.md) §13.
- [../01-hld.md](../01-hld.md) §0.1, §0.4; [../05-registry-and-autonomy-contract.md](../05-registry-and-autonomy-contract.md)
  §9.3, §9.4; [../02-landing-zone-and-tiers.md](../02-landing-zone-and-tiers.md) §1.5, §3.5.
- The Google pages listed above, read 2026-09-16.
