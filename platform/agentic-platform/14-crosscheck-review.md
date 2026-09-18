# 14. Cross-check review of the whole documentation

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-18
- Maturity: review, complete 2026-09-18. It records the cross-check of the whole documentation
  of the secure agentic platform — the objective, the design pages, the register, the brief, the
  three agent sets, the full build, the proof of value, the three-day build and the two decision
  records — held on 2026-09-18. It asked four questions: does the documentation, taken together,
  answer the objective of 2026-09-13; is it internally consistent; is its security position
  honest; and is there a dated path to the EU AI Act and to TISAX. It changes no design page,
  no procedure and no decision. The fixes of §6 were made in the pages they name on 2026-09-18
  (every high and medium row but one, X-33, which is part done); the low rows are still to be
  made. The three-day corrections carried on 2026-09-18 are recorded in
  [3-day/README.md §6.1](3-day/README.md#61-corrections-made-on-2026-09-18); §6 summarises those
  in one row.
- What it is not: it is not a re-argument of any decision (Wall-E's Super Admin, P33, is the
  owner's decision and is checked only for how it is contained); it is not a verification that
  anything works, because nothing is built; it is not a legal opinion, because the operating
  site's country is *tbd* and no page may name one; and it is not the fix. The status column of
  §6 was filled on 2026-09-18 from the fixes as made: 38 rows fixed, 27 open, none rejected.
- Revised 2026-09-18: status column of §6 filled from the fixes made the same day; §8 restated as
  what is still open.
- Inputs: the fact sheet and the five reports written on 2026-09-18 under
  `.agent-work/crosscheck/` (outside the wiki): the facts, the coherence check of objective
  against design against brief, the check of the three build paths against each other, the
  security review, the regulatory review, and the record of the three-day corrections. Every
  regulatory fact was re-read at its source on 2026-09-18; the sources are listed at the end.
- Conventions: British English; absolute dates; `Assumption:` marks an inferred fact; *tbd* stays
  *tbd*; roles, never people; no secrets. Where two pages disagree the design page wins over the
  brief, the day file over the three-day README, the setup file over its README on a command or
  a name, and [12-open-decisions.md](12-open-decisions.md) over every page for a decision's
  status. Findings are numbered X-01 upward, in severity order.

## 0. The verdict

The documentation answers the objective, and says so requirement by requirement: each of R1–R16
has a home in the HLD's traceability table and a chapter in the brief, the eight readings the
design declines or qualifies ("bulletproof", AGI-class hosting in 2026, "any super-admin action",
"any misbehaviour", structural independence inside the tenant, "hundreds", the detection desk
below Tier P, maturity 3 on least privilege) are declared in both places with the same reasons,
and no page claims that anything is built. It is internally consistent where it defines a fact:
the eight standing constraints are stated once and nowhere loosened, the two decision records
match register rows P33 and P34 in status, gate and dependents, and the three build paths form
one hand-over chain whose rules hold by construction — a smaller path's record can never satisfy
a full-build gate, and Eve is live before any doer exists in every path. The security position is
honest: every design page says that a super-admin robot moves the platform from "Google refuses"
to "code refuses and detection watches", that Eve's independence inside the tenant's organisation
is detective and only the witness organisation is structural, and that a leaked token is a tenant
compromise; the enforced-versus-detected grading is applied consistently and the three unverified
Google facts are kept out of the safety case. The path to the regulation is sound in structure
and correct in every date re-verified on 2026-09-18, and one open question closed in the design's
favour (Art. 49(2) registration survives the Omnibus). What was found is of three kinds: a map
layer (the README, the brief's summary, roadmap and document map, the three agent-set READMEs)
that stopped on 2026-09-14 and still describes thirteen pages, 143 decisions and four runbooks
that were retired on 2026-09-16; a three-day build whose names break the chain it promises (a
Tier P doer carrying the proof of value's Tier W agent id, project ids the proof of value's own
form check refuses) and whose Eve monitors every real administrator from day one with no
data-protection record; and a handful of places where two authorities describe one fact
differently (the second of the two lists, the owner of risk R-01, whether K6 is one person or
two, whether the DPIA is complete or started at the grant, the timing of works-council
information against Eve's first stream). None of these is a flaw in the stance. Each is a page
that must change before the stance is true of what would be built, and §8 lists which must change
before the documents go to HR, security, compliance, architecture and the board.

## 1. What was cross-checked

| Element | Checked against | Result on 2026-09-18 |
|---|---|---|
| The objective (`.agent-work/OBJECTIVE.md`, restated in [00 §1](00-objective-review.md#1-the-objective)) | R1–R16 on the review page; [01-hld §0.6](01-hld.md#06-traceability-the-objectives-sixteen-requirements-and-the-register-ids-not-cited-elsewhere); brief/03 | Sound. Every sentence of the objective has a row; every row is met, qualified or declined with a reason in both authorities. One qualification the brief declares and the HLD does not record: R3, the human prompt as origin rather than only trigger (X-08) |
| The HLD, [01-hld.md](01-hld.md) | Its own sections; pages 02–11; the register; the brief; the two decision records | Sound on every control, grade and gate. Three internal slips: the Tier X unmet count (four in §0.4, five by §11.5's own list, X-13); the register range still P1–P143 in §0.2 and §17 (X-52); "a dry run never mutates" absent from the Status list although both smaller build paths and the ladder treat it as absolute (X-46) |
| The detailed pages 02–11 | The HLD; the setup files that build them; each other | Sound. Two disagreements with the full build on what the pre-spike state is (06 §4.3 versus setup/33 on `--ingress=all`, X-24) and on whether K6 is a one-person or two-person act (04 §9.7 versus setup/38 GT-8.2, X-26); grades outside the two-word vocabulary on four rows of 11 §6.3 (X-59); the F5 derogation condition stated as (b) where (a) fits (X-27); worker information timed after Eve's first stream (X-28); DPIA "started" at a gate after which every employee's directory record is read (X-32) |
| The register, [12-open-decisions.md](12-open-decisions.md) | The HLD; page 11; the decision records; the setup and POV files that read it | Sound as a register: 204 rows, five states, one sequence, no id reused. Row P29 defines the second of the two lists differently from the HLD, the P33 record and Wall-E's guardrails page (X-15); row P129 gates worker information on Stage 1 only (X-29); row P136 omits two gate conditions and words the quarterly event differently from page 11 and the record (X-30) |
| The brief, [brief/README.md](brief/README.md), 33 chapters | Every design page it cites; the three build READMEs; the register | Sound in intent and precedence (the design page wins, and the brief says so). Its map layer is dated 2026-09-14: chapters 02, 29, 30, 32 and the front matter and glossary count thirteen pages, 143 decisions, four build procedures and effort figures from the retired SETUP.md (X-06, X-07, X-09, X-10, X-11, X-14, X-45); chapter 19 does not carry Eve's first job over the human super admins (X-14) |
| The three agent sets, [wall-e/](../wall-e/README.md), [eve/](../eve/README.md), [mo/](../mo/README.md) | Their pointer pages of 2026-09-16; setup/README §1; the HLD §18 | The relationship to the platform is right on all three (first tenants; P33 designed around; nothing built). All three READMEs still present a retired runbook as the executable build (X-16, X-17, X-18); eve/07's pointer text writes "she" and "her" (X-53) |
| The full build, [setup/README.md](setup/README.md) and 01–42 | The design pages; the POV; the three-day set; the register §6a | Sound: it alone owns the grant, the witness, the sandbox twin and every P-SA gate; setup/38 refuses without five named humans and the signed decisions. Its restatement of the standing constraints drops two of the HLD's eight and mixes in build rules (X-44); its description of the POV's team is loose and it does not mention the three-day set (X-57); gate day asks who can mint a token for the credential holders and not for the two approval-surface identities (X-25) |
| The proof of value, [pov/README.md](pov/README.md) and 01–09 | setup/; 3-day/; the register §6b; the design's non-goals | Sound: no Super Admin to any agent, no admin role on the doer, every deviation names its unwind, `HANDOVER_TABLE` maps every setup file, nothing is torn down (P204). It quotes a full-build total no setup page states (X-22); its Status is silent on the poller and the projects the three-day set leaves behind (X-20); it overclaims that everything long in the full build sits at Tier P-SA (X-51); it cites setup/README by line numbers that moved (X-45) |
| The three-day build, [3-day/README.md](3-day/README.md), day 1–3, code.md | pov/; setup/; 02-landing-zone §3.6; the design's non-goals; Google's documentation for every command the corrections introduced | Honest about what it is not; twenty-eight corrections carried on 2026-09-18 (X-64). What stands: the doer's agent id and project ids break the hand-over (X-01, X-02); Eve polls the production tenant for every actor with no DPO record (X-03); the halt lever is writable by the process it halts (X-33); the caller-account fallback collapses the two-person rule (X-34); the primary calling path depends on a gcloud behaviour setup/33 says does not work for user credentials (X-35); the poller reads every employee's sign-in, token and account streams (X-37); Mo's views are created in the wrong dataset (X-21); "nothing is exposed to the internet" overclaims (X-23) |
| The two decision records, [decisions/](../../decisions/README.md) | Register rows P33 and P34; page 11 §6.2 and §10; brief/32 | Sound. Status, gate, dependents and supersessions agree; the one wording difference ("accepted" versus "decided") is declared. Page 11 §10 names a different owner for R-01 from the record (X-31) |
| The shared pages, [../project-topology.md](../project-topology.md), [../gemini-enterprise.md](../gemini-enterprise.md), [../agents.md](../agents.md) | The HLD §2, §3; the register §7 | Sound; the five core projects and the four agent-set projects are as the register resolved them (row 6); every project id is *tbd* |
| The regulatory state | Primary and secondary sources read on 2026-09-18 (§Sources) | Every date, article and identifier re-verifies. Three rows of page 10 and one of page 11 need a dated update (X-55, X-56); one unverified row closes (Art. 49(2) retained) |

## 2. Objective, design and brief

**What holds.** The objective's sixteen requirements are quoted faithfully on the review page and
traced one by one in [01-hld §0.6](01-hld.md#06-traceability-the-objectives-sixteen-requirements-and-the-register-ids-not-cited-elsewhere)
and in brief/03. The two authorities agree on which readings are declined as worded (R12
AGI-class hosting in 2026; R14 "bulletproof"), which literal readings are declined and replaced
(R4 "any super-admin action", R8 structural independence inside the tenant), and which are
qualified for a stated reason (R6, R11, R13, R15). The decided premise — Wall-E holds Super Admin,
P33 — is stated as the owner's decision on the HLD, the README, the brief, the register and the
three agent-set READMEs, and no page re-argues it; each says only how it is contained. The eight
standing constraints of [01-hld Status](01-hld.md#status) are restated one for one by brief/05
§4.4, pointed at rather than paraphrased by pages 02–11 and the register, and restated more
strictly, never more loosely, by the three build sets. Nothing anywhere claims to exist; the one
existing resource, `GEMINI_PROJECT`, carries `Assumption:` where it matters.

**What disagreed.**

- The HLD's traceability table says R3 "Wall-E executes on a human prompt" is met by band A on the
  chat trigger and records no qualification, while its own §12.2 and the ladder let a band A
  family earn scheduled, event and inbox triggers; the brief declares this as unqualified and asks
  the owner to confirm the reading (X-08).
- Register row P29 defines the second of the two lists as "protected principals"; the HLD §13.1,
  the P33 record and wall-e/06 define it as the operations reachable only through band B at tier
  `SUPER` under the two-person rule. The owner is asked to sign lists two authorities describe
  differently (X-15).
- The HLD counts Tier X's unmet conditions as four in §0.4 and lists five in §11.5; the brief
  records the difference and the authority carries both (X-13).
- [00 §3.2](00-objective-review.md#32-other-reversals-the-lenses-found) still says the
  `eve-advisor` slot would be "able only to raise a refusal", the wording the P34 record removed on
  2026-09-13 because no model may produce a refusal (X-19).
- The map layer stopped on 2026-09-14: the README, brief/02, brief/29, brief/30, brief/32, the
  front matter and the glossary count thirteen pages and 143 decisions, name four build
  procedures, and send the builder to SETUP.md and PREREQUISITES.md, which were retired to pointer
  pages on 2026-09-16 (X-05, X-06, X-07, X-09, X-10, X-11, X-45). brief/02 and brief/19 do not carry
  the 2026-09-15 change by which Eve's first half watches every human super admin from its first
  run, before Wall-E exists (X-11, X-14). brief/29's builder order puts the tenant-app baseline
  first, where the build of record runs Tier R before Tier C by SD-13 (X-09).

**What was corrected on 2026-09-18.** Nothing on the design pages, the brief or the register: this
page records and does not edit. What was corrected on 2026-09-18 is the three-day set — its
README §6.1 listed twenty-eight corrections owed to the day files and the code, and all
twenty-eight were carried, with the timetables recomputed and every new command checked against
Google's documentation on that date ([3-day/README.md §6.1](3-day/README.md#61-corrections-made-on-2026-09-18);
summarised in X-64). Everything else in §6 is open.

## 3. The three build paths side by side

| | Three-day build, [3-day/](3-day/README.md) | Proof of value, [pov/](pov/README.md) | Full build, [setup/](setup/README.md) |
|---|---|---|---|
| People | Two, both Workspace super admins and owners of the four projects they create: person A builds, person B approves, witnesses and receives Eve's reports; a sponsor named in writing who does no work. No security reviewer, blind grader, incident commander, envelope witness or validator custodian | Three hands-on (person 1 the platform owner and operator; person 2 the second person, `sa-2-admin@`; person 3 second operator, security reviewer and blind grader) and one engineer (may be person 1, never 2 or 3); for a signature or an hour: the incident commander, an envelope witness, finance, the Cloud Logging owner, the DPO, HR and the works council through HR, the ISMS, legal's designate, the IT security lead, procurement | Five named humans at the grant, or four with a dated ISMS exception (SD-04); thirteen appointments (setup/03); the roster of [setup/README §6](setup/README.md#6-who-must-be-present-s069), from the two witness administrators and two sandbox super admins to the MDR desk lead |
| Elapsed time | Three business days (`Assumption:` 2026-09-22 to 2026-09-24) | POV-1 ends 6 to 9 weeks after day one; POV-2 ends week 16 to 20 with a dedicated engineer, 26 to 34 weeks if one person writes the code and runs the procedures (`Assumption:` every figure). A sponsor told "three weeks" has been misled about both stages | 6 to 7 months to Stage 0, not before 2027-03; 9 to 12 months to Mo's first merged proposal; Tier R 2026-11-10 to 2026-12-08, Tier C 2026-12-08 to 2027-01-19, Eve-H live 2026-12-22 to 2027-01-19 (`Assumption:` every date an earliest date, [setup/README §3.4](setup/README.md#34-parallel-sittings-and-the-critical-path)) |
| Person-days | Six, recomputed on 2026-09-18 with all twenty-eight owed corrections made (X-64): days 1 and 2 at 375 minutes allocated with 75 in reserve each, day 3 at 390 with 60; 38 person-hours allocated and 7 in reserve for two people | 20 to 26 of procedure plus 40 to 64 engineer-days of code, 60 to 90 in all | `Assumption:` 85 to 90 hands-on, a sum of [setup/README §3.2](setup/README.md#32-the-file-table)'s per-file cells that no setup page states as a total (X-22) |
| What it builds | Four projects; Eve polling the admin audit log through the Admin SDK Reports API and paging person B, live before any doer exists; a doer holding one organisational-unit-scoped Workspace admin privilege (Users > Update > Suspend, with Users > Read) over four synthetic accounts, a forced dry run, a two-person approved execution; K0 and K4 pulled and timed; Mo's scorecard against a retrospective volume baseline | Tiers C, R and W on the production tenant, 22 folders, the register, a Model Armor floor, the Agent Registry with its write alert drilled; Eve with no Workspace credential on the organisation sink, reporting on every human super admin to the second person; a doer with no Workspace admin role at all, its model holding no credential, every action written ahead to an audit dataset with alteration detected by fingerprint; Mo measuring the doer against a retrospective baseline; at most one optional Tier P step on a separate agent and a synthetic OU | The platform (folder, factory, register, gateways, logging, K7), Eve's first half over every human super admin with a witness organisation and the second human's independent proof, the sandbox twin, Wall-E's Workspace side to the grant, the super-admin grant under the gate, Stage 0, Mo's first merge, Eve S3 and S4, the standing gate, drill and evidence records |
| What it proves | That machinery can be built under control in three days: a controller live before the doer, a forced dry run that refuses a valid approval, a two-person execution, a write-ahead audit, two kill levers pulled. A demonstration, not compliance evidence and not a production grant | The claim statement of [pov/README §1.1](pov/README.md#1-the-claim-and-the-three-sentences-never-to-use): a governed Gemini Enterprise with admission as a register row, kill levers pulled during live work, a controller reporting on every human super admin to someone who is not the subject, a doer whose model holds no credential, an improver that measured against a baseline. A clause whose record is missing is struck, not softened | The super-admin grant with its thirteen compensations and four checklist rows green, Eve's structural independence through the witness, the separation of duties as a counted minimum, the penetration test, the Art. 6(4) file and Art. 49(2) registration, the deviation record with three signatures |
| What it can never say | "Wall-E is safe as a super admin"; "Eve is independent"; "Model Armor blocked the injection" (it produces no Model Armor evidence at all); "we saved *n* minutes of admin work" | "Wall-E is safe as a super admin", and no report may say the doer "does admin work"; "Eve is independent"; "Model Armor blocked the injection" — it produced evidence | "Bulletproof"; AGI containment; Eve's control path structurally unreachable by a super admin inside the tenant's organisation; a maturity-3 verdict on 4.2.1, which only the assessment gives |
| What it hands over to | [pov/](pov/README.md), once its standing IAM grants and custom admin role are removed and its synthetic accounts suspended (§10, day-3 T3-19 a to m); the four projects and Eve's poller are the open part of that hand-over (X-01, X-02, X-20) | [setup/](setup/README.md) through pov/09's `HANDOVER_TABLE` (43 rows, one per setup file) and the deviation register PV-D-01 to PV-D-16, each naming the setup file that unwinds it; a dated stop-or-continue record with three options, in every one of which nothing is deleted (P204) | Operation: Wall-E's Stage 1 and later stages, Eve's S3 and S4, Mo's cadence, the TISAX assessment order and the Art. 6 re-run after the final guidelines (setup/40–42) |
| What stands after it | The audit table, the evidence dataset, the deletion liens, the run log; the four projects; Eve polling and `eve-reader@` with its consented token, by a recorded decision (or stopped and recorded); the halt at `on` | Everything: the folders, the projects, the register, Eve watching the human super admins even on "stop", the evidence pack in the locked bucket | Everything, under the standing gate: any red checklist row is a severity-2 finding with a 30-day window, and rows 5, 6 or 11 red at all pull K6 until green |

**The hand-over chain.** 3-day → pov → setup → the grant. The rules of the chain hold by
construction and were verified in the files: the proof of value never sets a bare full-build
record name (`TIER_C_RECORD`, `EVE_H_LIVE_RECORD`, `TIER_W_RECORD` and the rest stay unset,
[pov/README §7.3](pov/README.md#73-a-pov-record-never-satisfies-a-full-set-gate)); setup/38
needs those bare names and refuses on any *tbd*; the three-day set has no `~/.platform-env` and
no checkpoint log at all, so it cannot write a line the resume rule would read. "Eve live before
the doer exists" is enforced in all three: day-2 block D2-B1 requires Eve to have paged the doer's
own role assignment, pov/07 opens with `need POV_EVE_H_LIVE_RECORD`, setup/30 starts on
`EVE_H_LIVE_RECORD`. Every one of the twenty-seven three-day cuts and the sixteen POV deviations
names the file and step that puts the piece back, and every cited step id exists. The three
sets' absolutes nest as required, with the one loosening (one reviewer on Mo's merge, C-09)
declared.

**What was found between them.** The chain breaks on names at its first link. The three-day
doer holds a delegated admin role, which the design and the POV make Tier P, and takes the agent
id `steward` that the POV fixes as its Tier W doer with no admin role; a team that runs the three
days spends `steward` at Tier P in `agp-p-steward-prod`, pov/02 PD-3.2 refuses `DOER_PROJECT`
unless it reads `agp-w-steward-prod`, and pov/07 creates a second `steward` — the rename by
collision the sets exist to avoid (X-01). Every three-day project id carries a `-d3` suffix that
[02 §3.6](02-landing-zone-and-tiers.md#36-naming-and-the-label-taxonomy-p37-p38) allows only as four hex characters on a
global-id collision and that the POV's form check refuses, so the four projects become orphans
the factory can never adopt, and "nothing is torn down to move on" is false for them (X-02). The
three-day README hands Eve's Reports API poll to pov/06, whose Eve holds no Workspace credential
and has no poll (X-20); misquotes the POV's elapsed time as 6 to 20 weeks (X-38); leaves Mo's
dataset unnamed where SD-33 fixes it (X-21); and the pov/README Status is silent on the poller
and the projects the three-day set leaves running (X-20). The POV quotes a full-build total no
setup page owns (X-22) and overclaims that everything long in the full build sits at Tier P-SA
(X-51). The counts inside each path are consistent; every disagreement found is one page quoting
another, not two pages computing different numbers.

## 4. Security

**The verdict a CISO could quote.** The design's central honesty holds on every page that
matters: a super-admin robot moves the platform from "Google refuses" to "code refuses and
detection watches"; Eve's independence inside the tenant's organisation is detective and only the
witness organisation is structural; a leaked token is a tenant compromise with a path into the
GCP organisation, including `EVE_PROJECT` and `MO_PROJECT`; the deviation is carried by thirteen
compensations of which several are organisational, not technical. The two grades are two words
used as two words, and the three open Google facts (P7 the Admin console access level, P8 the
deny-policy principal-set spelling, P60 the PAB on Cloud Run invoke) are named and kept out of the
safety case rather than counted.

- **Enforced** (Google or the platform refuses): the OAuth scope split and the absence of
  `cloud-platform`; no domain-wide delegation, ever; IAM-only invocation with no human or group on
  any credential holder; Binary Authorization on every Cloud Run credential holder in the full
  build; the folder deny policy, and the PAB for engine queries; a project-level service denial
  that keeps a model out of Eve's control path; PAM's approver-is-not-requester; Workspace
  multi-party approval on role assignment; the write-ahead audit, the forced dry run and the
  hard-denied list as code in the action services.
- **Detected** and nothing more: every use of the robot's credential outside the two action
  services; every act of a super admin against Eve, the sinks, the audit configuration or the
  evidence stores inside the tenant's organisation; Agent Runtime engine drift; secret access by a
  non-reader; row tampering in Eve's BigQuery tables (no insert-only permission exists, SD-43).
- **Accepted** and written down: risk row R-01, a tenant compromise on a leaked token, bounded by
  custody, scope split and detection latency, with a token valid for up to an hour after
  suspension (`Assumption:`); the one-batch "shows plan A, executes plan B" residual; a
  compromised Eve signing inside an existing envelope; Mo's truthful-but-tendentious pull request;
  Agent Runtime's lack of an admission hook; one region; invisible Google-side tenancy
  segregation; some stores on Google-managed keys; one model family across the fleet.
- **Refused today** by the security reviewer role this review stood in for: the deviation record
  itself, because rows 5 (SIEM with 24x7 acknowledgement, the witness), 8 (the P3 perimeter
  spike) and 11 (a second human outside the administration line) of the gate checklist are not
  green and rows 1, 2, 4, 9 and 10 cannot be proven while the service code does not exist; the
  gate-day check of who can mint a token for the credential holders, because it omits the two
  approval-surface identities whose impersonation forges an approver the action service trusts
  (X-25); and the three-day build's live block as written, because its halt lever is writable by
  the process it halts (X-33), its caller-account fallback lets one person request and approve
  (X-34), and its primary calling path depends on a gcloud behaviour the wiki's own full-build
  page says does not work for user credentials (X-35).

**Standing risks per path.**

| Path | The standing risk, stated plainly |
|---|---|
| Three-day | A tenant in which, for three days, two organisation-scoped Trusted OAuth clients, a robot with an OU-scoped suspend privilege and a read-only admin account with a consented Reports token exist, watched by six detections and two people. The unwind now reaches both clients, their credentials and the read-only credential (day-3 T3-19 a to m, carried 2026-09-18); Eve's poller stays by decision. No reconciliation rule joins robot events to the audit table (X-36); no time-boxing, no PAM, no penetration test, no SIEM; the "nothing is exposed to the internet" sentence must not be repeated (X-23). Nothing mutating touches a real account; reading every employee's login, token and account streams does (X-37) |
| Proof of value | No Super Admin to any agent and no admin role on the doer, so no super-admin containment is tested and none may be claimed. Eve lives inside the reach of the administrators it watches, with no witness (PV-D-03); no penetration test (PV-D-11, unwound on any external share or grant); the audit is append-only by convention with alteration detected, not prevented. Its residual is that of Tier W on a production tenant with synthetic targets only |
| Full build | R-01: a stolen robot credential is a Workspace tenant takeover and a route into the cloud organisation; custody, detection within minutes and people pulling K4–K6 meet it, nothing prevents it. Inside the organisation the controller watches a super admin and cannot structurally stop one until P15 relocates the control path to the witness. The safety of the design depends on people who do not exist on 2026-09-18 (no second super admin outside the administration line, no security reviewer, no SOC, no DPO engaged). The robot's gate is one process its build pipeline can rewrite; manipulated content will reach the model, and the ceilings, not the screen, are the enforcement |

**The findings.** X-04 (the unwind, carried), X-24 to X-26 (the design pages against the full
build), X-33 to X-37 (the three-day code and day files) and X-60 to X-63 (low, three-day) in
§6. What is sound is in §7.

## 5. The path to the regulation

### 5.1 The regulatory state on 2026-09-18, with corrections

Everything the pages state as fact re-verifies at its source on 2026-09-18: Regulation (EU)
2024/1689 in force 2024-08-01, Art. 4 and 5 since 2025-02-02, Chapter V since 2025-08-02, general
application 2026-08-02; Regulation (EU) 2026/1744 (the Digital Omnibus on AI) in the OJ
2026-07-24, in force 2026-07-27, Annex III high-risk obligations from 2027-12-02, Annex I from
2028-08-02, the new Art. 5 prohibitions and the end of the Art. 50(2) transition on 2026-12-02;
Art. 50 final guidelines adopted 2026-07-20; the Art. 6 classification guidelines still a draft
(2026-05-19, consultation closed 2026-07-23, final expected by the end of 2026); Annex III 4(b)
quoted verbatim; no harmonised standard cited in the OJ; VDA ISA2027 published 2026-07-01 and the
basis of assessments ordered from 2027-01-01, with ISA 6 still usable for orders placed by
2026-12-31; Google's TISAX result under scope SYN0NK per region with `europe-west1` inside it and
no service named. Three status changes are owed to the pages:

1. **Art. 49(2) registration**: the Commission proposed deleting it for systems claiming the Art.
   6(3) derogation; Council and Parliament rejected the deletion and it stands in streamlined form
   (Annex VIII Section B points 7 and 9 deleted). This closes [10 §9](10-eu-ai-act.md#9-unverified-on-2026-09-13-and-what-closes-each-item)'s
   unverified row in the design's favour: "registration before the first write" (05 §8.2, P75) is
   the right mechanism and needs no change (X-55).
2. **Harmonised standards**: EN 18286 is at formal vote, no EN is published and none is cited;
   "the first to reach final approval" overstates by one stage (X-55).
3. **The Art. 6 guidelines** are still draft; the 90-day re-run trigger (P132) stays armed. If the
   final text lands in December 2026 as expected, the re-run falls in the first quarter of 2027,
   before Wall-E's Stage 1 on the full build's own calendar — the assessment is signed once,
   against the final text.

Nothing in the Omnibus touched Art. 26(7), Art. 27, Art. 72 or Art. 73. ISA2027's supplier rule
has three routes where page 11 quotes two (X-56), and the page should ask the ISMS for a dated
decision on the 2026-12-31 ISA 6 cut-off (X-58).

### 5.2 The dated path: EU AI Act

`Assumption:` every date after 2026-09-24, because POV day one (2026-09-21) and the three-day run
(2026-09-22 to 2026-09-24) are planned, not fixed, and the full build's "6 to 7 months to Stage
0" is a plan figure. "First produced by" names the earliest build path whose pages produce the
artefact; "none" means no path produces it and it is an organisational act.

| Milestone | Date or gate | Obligation | Owner role | Evidence | First produced by |
|---|---|---|---|---|---|
| Today | 2026-09-18 | Art. 4, Art. 5 and Art. 50 bind now; Art. 99 exposure is real for Art. 5 (7 %) and Art. 50 (3 %) | AI compliance owner (to be named); DPO | none yet | — |
| Day one of any path | 2026-09-21 | Art. 4 briefing for everyone who operates or approves, attendance recorded | platform owner | E-13 (POV-grade) | pov/02 PD-5.4; setup/03 |
| POV-1 | 2026-10 to 2026-11 (earliest end 2026-11-06 to 2026-11-27) | PV-11: class and role per POV agent with the intended-purpose paragraph and its hash; Art. 5 negative determination. A row classed `annex_iii_adjacent` also needs a dated Art. 6(4) assessment and an Art. 49 value before its register row commits | AI compliance owner or legal's designate; platform owner | PV-11 record; `register/purpose/*`; E-01 (POV-grade) | pov/02 PD-5.4 (the full build's G16 is the super-admin purpose, re-signed at setup/38) |
| Omnibus dates bite | 2026-12-02 | Art. 5(1)(ba)/(bb) apply (no effect: nothing generates images, video or audio); the Art. 50(2) transition ends (no effect: nothing was on the market before 2026-08-02) | AI compliance owner | a dated note in 10 §1 | — |
| Final Art. 6 guidelines | end 2026, expected | Re-run every `annex_iii_adjacent` assessment within 90 days; rows `suspended` until re-signed (P132) | legal; AI compliance owner | E-01 new version | none until adopted; setup/42 GD-4.2 keeps the calendar |
| POV-2, the doer's first write at L1 on synthetic accounts | 2027-01 to 2027-02 | Before it: PV-11 signed; Art. 6(4) and Art. 49 value if `annex_iii_adjacent`; DPIA started with a dated completion (PV-D-15); no real account enters `PILOT_OU` without a complete DPIA, HR's written answer and the holder's consent (pov/02 PD-8.0) | DPO; HR; legal; platform owner | `POV_TIER_W_RECORD`; PV-D-15 | pov/07 |
| M/613 standardisation request expires | 2027-02-28 | Calendar item; check whether the Commission extended it | AI compliance owner | note in 10 §1 | — |
| Full-build decisions signed; Eve-H live | not before 2027-03 for the grant; Eve-H 2026-12-22 to 2027-01-19 | setup/03: P23 the entity, G16 the super-admin intended purpose signed with legal, SD-11, the D7 answer, retention (P13), the roster reduction; setup/23–28: Eve-H live and drilled with the DPO's SD-11 record before any feed | legal; DPO; HR; ISMS; the second human | `EVE_H_LIVE_RECORD`; SD-11; E-12 | setup/03, 24, 25, 28 |
| The grant | weeks to months after Eve-H | The deviation record's three signatures; DPIA complete for Eve's monitoring and the Stage 0 reads (X-32); the tabletop with the DPO, legal and HR or employee representatives; `PENTEST_RECORD` with no open critical or high | platform owner requests; the second human approves; security reviewer signs; ISMS enters | the deviation file; R-01 acceptance; E-10 | setup/37, 38 |
| Stage 0 | 3–4 weeks after the grant | Records-of-processing entry for the reads on every employee's directory record; DPIA for the reads complete before the first report | DPO; agent owner | 9.3.1 entry; DPIA | setup/39 |
| Stage 1, the first write (putting Wall-E into service) | about 2027-04 at the earliest (`Assumption:`) | E-01 Art. 6(4) assessment signed by legal, the profiling part by the DPO; E-02 Art. 49(2) registration id in the row; E-12 worker pack and employee notice dated, explanation log existing; E-13 Art. 4 records; E-07 instructions for use; E-05 the stage snapshot tag; E-15 the Art. 50 block and its CI content test. A count of zero on E-01, E-02, E-05, E-07, E-12 or E-13 blocks the stage (setup/42 GD-4.2) | legal; the P23 entity; HR and DPO; agent owner; platform owner | the six gating artefacts | setup/39, 42 (the POV signs purposes for its own agents only; the three-day build none) |
| Later stages straddle 2027-12-02 | 2027-10 to 2028-01 (`Assumption:` S5 at least 27–38 weeks after S0) | F5 at L4 only on the HR-system event (P127); every promotion record carries the Art. 9 residual-risk statement (E-03) | agent owner; security reviewer; DPO | E-03 | setup/40–42 |
| Annex III obligations bind | 2027-12-02 | For any `high_risk` row: Chapter III Sections 2 and 3, Art. 17, Art. 43/47/49(1), Art. 72, Art. 73 mandatory; Art. 26(7) mandatory (already done). For `annex_iii_adjacent` rows nothing new binds, but the classification file must be current against the final guidelines | AI compliance owner; legal; ISMS | E-01 refresh; E-14 only if `high_risk` | setup/42 GD-4.2 |

### 5.3 The dated path: TISAX

| Milestone | Date or gate | Obligation | Owner role | Evidence | First produced by |
|---|---|---|---|---|---|
| ISMS decision on the ISA 6 cut-off | by 2026-12-01 (proposed, X-58) | State whether any site assessment is ordered under ISA 6 by 2026-12-31. Recommendation: order nothing for the platform in 2026; if the site renews for its own reasons, list the platform out of scope and re-scope at the next order. Nothing built in 2026 can reach maturity 3 | ISMS | a dated line in the legal register (11 §11) | none (organisational) |
| ISA2027 mandatory for new orders | 2027-01-01 | The mapping of record is [11 §5](11-tisax.md#5-control-by-control-mapping) against ISA2027 with the 6.0.3 cross-reference | ISMS; platform owner | 11 §5 | setup/42 GD-4.3 (the §13 pack) |
| The grant day | not before 2027-03 | 4.2.1 deviation in force with its thirteen compensations and four checklist rows green; five named humans (SD-04) or four with a dated exception; reviewed quarterly with the roster; re-signed at each Wall-E stage transition (X-30) | platform owner decides; security reviewer signs; ISMS enters | the deviation file; `GATE_CHECKLIST_RECORD`; review log | setup/38 |
| After Stage 1 and the first internal audit | mid to late 2027 (`Assumption:`) | Before the order: the signed classification mapping (P109); every accepted risk with its acceptance file (P140); the ENX result share for SYN0NK filed and per-service coverage answered (P32); the legal register (P141); no open finding on 1.2.2 or 4.2.1 from the internal audit (P139); four distinct humans in the roles of [11 §7.2](11-tisax.md#72-the-minimum-per-stage) | ISMS; security reviewer; platform owner | the §13 evidence pack (setup/42 GD-4.3) | setup/42; the ENX share and the coverage answers are produced by no path |
| The assessment | when the ISMS orders it | AL2 (AL2.5 accepted), label Confidential (`Assumption:`), maturity 3 on every applicable control; an assessor may still refuse maturity 3 on 4.2.1 for a super-admin robot however good the compensation | ISMS | the result | — |
| Label expiry | three years after the result | Re-assessment; the deviation record expires with the result and is re-signed | ISMS; security reviewer | new result; new signature | — |

### 5.4 Employee data and the works council

Four groups of employees are data subjects: every tenant account (the identity log store copies
sign-ins; Stage 0 reads every directory record); the targets of F5 suspend and F7 licences; the
operators and approvers (prompts, audit rows, training records, the self-grading metric); and the
human super administrators whom Eve watches — roster diffs, the detection set, reports about the
administrator's own actions sent to the second human. The last group is the one the pages
under-weight. Eve's control path is rightly "not an AI system" under the Act, but that says
nothing about GDPR: Art. 88(2) names "monitoring systems at the work place" explicitly, and Eve
over the administrators is one.

- **Art. 35.** Systematic monitoring of employees in a position of imbalance meets the criteria
  for "likely high risk" at once (`Assumption:` the competent authority's Art. 35(4) list names
  employee monitoring, as most do). A DPIA is due *before* Eve's first feed and before the Stage 0
  reads, not "started" at the grant (X-32). The POV's SD-11 record with the DPO's signature is the
  right shape and timing; the full build has it at setup/24 EW-0.2; the three-day build has
  nothing (X-03).
- **Art. 22.** Defensible: the suspension decision is HR's or a named operator's, Wall-E executes
  it and records `decision_ref`; licence reclaim from active accounts takes a human-supplied list;
  the families that can run at L5 produce no legal or similarly significant effect. The point a
  works council will press: at L4 on the HR event the action executes without a human looking at
  *that* action. The honest answer, already on the pages, is the residual — a wrongful suspension
  can last the hold window plus the restore's approval, up to four business hours — and P127's
  caps.
- **Art. 88 and national law.** The jurisdiction is *tbd* (P23, P141), so what follows is
  `Assumption:` per country: where co-determination applies, the works council's consent is
  required before a technical device capable of monitoring behaviour or performance is
  introduced, usually through a works agreement whose lead time is months; elsewhere the
  employee representative body is informed and consulted before a monitoring technology is
  introduced. In every likely jurisdiction the design's default `Assumption:` of "information" is
  the weaker of the two possibilities; the pages should default to "consultation, and consent
  where co-determination applies", with information as the fallback if HR's answer says so
  (X-28). The POV's fallback — Eve's first run limited to persons 1 and 2 with written consent —
  is the right interim under every jurisdiction.
- **Timing.** P129 moves worker information to "before Stage 1 of any Tier W agent acting on
  employee accounts". On the full build's own order, Eve over the human administrators and the
  identity log store are live before the grant, before Stage 0, before Stage 1. The trigger must
  be Eve's first stream, not Wall-E's first write (X-28, X-29).
- **What the council is shown.** Decided with the council (brief/26 §22.7). Closest to them: the
  worker pack and notice, the explanation log, the fundamental-rights risk rows, the oversight
  roster, and the SD-11 record.

### 5.5 What none of the paths can evidence

**Only the full build produces:** the super-admin intended purpose signed with legal (setup/03
G16); Wall-E's Art. 49(2) registration and Art. 6(4) file (E-01, E-02); the deviation record with
three signatures and the risk register with acceptance files (setup/38); the four distinct humans
of 11 §7.2 and the CI separation check, the item most likely to stop an assessment (1.2.2); the
penetration test (setup/37); the witness organisation and Eve's structural independence; the Art.
12 log designated and locked at 400 days with a daily witness copy (E-06); the stage snapshot tag
and instructions for use (E-05, E-07); the Art. 50 injection and its CI content test (E-15); the
internal audit and management review (setup/42 GD-7); the TISAX §13 evidence pack.

**No path produces, because they are organisational or external:** the ENX result share for
SYN0NK and Google's per-service coverage answers (P32, P135); the Art. 25(4) written position with
Google; a completed DPIA (the DPO's programme; the paths supply inputs); HR's works-council answer
and, where required, the consultation or the works agreement; the legal entity (P23); the final
Art. 6 guidelines re-run; a harmonised standard and any presumption of conformity; a maturity-3
verdict on 4.2.1.

**What the smaller paths do yield, honestly:** the POV yields Tier R closed, Tier C and W partly,
PV-11 classification records for its own agents, the SD-11 DPO record with HR's works-council
half, a started DPIA, Eve reporting on every human super admin to someone who is not the subject,
the doer at L1–L3 on synthetic accounts, and a deviation register the full build reads. The
three-day build yields a demonstration of machinery under control and, correctly, claims nothing
else.

## 6. Findings register

Severity: **high** — following the page as written builds something unsafe, unlawful or
irreversible, or breaks the hand-over chain; **medium** — two authorities describe one fact
differently, or a page states a control or a figure that does not hold; **low** — a stale count,
a wrong pointer, a wording. Status was filled on 2026-09-18 from the fixes as made: `fixed
2026-09-18` where the page named was changed as the fix column says (a bracket records any part
of the fix that fell to a page not changed); `open` for every low row and for the one medium row
only partly made (X-33), each with what remains. Two rows (X-04, X-39) were written against the
three-day set before its corrections; the day-3 check of 2026-09-18 found the corrections in
place and closed them without a further edit. No row was rejected. Duplicates across the five
inputs are merged and the merge is stated.

| Id | Severity | File | Location | Problem | Fix | Status |
|---|---|---|---|---|---|---|
| X-01 | high | [3-day/README.md](3-day/README.md#5-the-four-projects-and-why-the-doers-project-is-not-called-walle) | §5 `DOER_PROJECT` row and "the doer's `agent_id` is `steward`"; §12 rows "The doer, its catalogue and its chain" and "`steward_audit.actions`" | The three-day doer holds a delegated Workspace admin role — Tier P by the design and the POV (P192) — and is given the agent id `steward`, which the POV fixes as its Tier W doer with no admin role in `agp-w-steward-prod` (pov/02 PD-3.2) and whose Tier P robot is a separate agent (P198). Running the three days spends `steward` at Tier P; the POV's form check refuses `DOER_PROJECT` and pov/07 creates a second `steward`, the rename by collision the sets exist to avoid. §12 also hands the doer to pov/07's Tier W doer, whose operations are group-membership changes and which cannot suspend a user. Merges the coherence report's C-23 and the paths report's F-01 | In §5 give the doer the POV's Tier P identity: `AGENT_ID` = the value PV-07 signs as `PILOT_ADMIN_AGENT_ID` (*tbd*; `Assumption:` `pilot-admin` until signed), `DOER_PROJECT` = `agp-p-<that id>-prod`, dataset `<that id>_audit`; add `steward`, the POV's `DOER_PROJECT` and `steward_audit` to the reserved list beside `walle`. In §12 point the two doer rows at pov/07 §7 (PW-7.1 to PW-7.5, PV-07) and pov/02 PD-5.5 and say pov/07's Tier W doer is a different agent the three-day build does not seed. Strike "every artefact carries the full build's name" for the doer's project either way. Add the change to §6.1 as owed to day-1 T1-1 and day 2 | fixed 2026-09-18 |
| X-02 | high | [3-day/README.md](3-day/README.md#5-the-four-projects-and-why-the-doers-project-is-not-called-walle) | §5 table, the four id cells; §1 "Every artefact carries the full build's name"; §12 "nothing is torn down to move on" | Every project id carries `-${SUFFIX}` = `-d3`. [02 §3.6](02-landing-zone-and-tiers.md#36-naming-and-the-label-taxonomy-p37-p38) allows a suffix only as four hex characters on a global-id collision, and pov/02 PD-3.2's form check refuses `agp-ctl-eve-prod-d3` and `agp-imp-mo-prod-d3`, so pov/06 and pov/08 create new `EVE_PROJECT` and `MO_PROJECT` beside the three-day ones; `agp-core-d3` has no `<name>`. Project ids are permanent and never move between folders (02 §1.5), so the four projects become orphans the factory can never adopt and the claim sentence is false for them | Drop `SUFFIX`. Use `agp-ctl-eve-prod`, `agp-imp-mo-prod`, `agp-p-<pilot-admin id>-prod` (X-01) and `agp-core-<name>` where `<name>` is the one PV-03 will sign for `CORE_PROJECT` (*tbd*; `Assumption:` `platform`). State PD-3.2's fallback: on a taken id, one four-hex suffix, applied and written into the run log. Add the T1-1 change to §6.1 | fixed 2026-09-18 |
| X-03 | high | [3-day/README.md](3-day/README.md#6-what-must-be-true-before-day-1-starts) | §6 rows 1–12; §7 item 9; §8 row C-12; §10 row 12 | Eve polls the production tenant's admin audit log for every actor (`activities.list`, `userKey=all`) from day one. That is monitoring of every real human administrator — employees — under GDPR Art. 88(2) and Art. 35, before any DPO record or HR/works-council answer exists. The page treats the missing DPIA and works-council information only as the reason nothing mutating may touch a real account, so a reader following §6 starts the monitoring unprepared. The POV gates the same monitoring behind the SD-11 DPO record with HR's works-council half (pov/06 PE-0.2, PV-08) | Add §6 row 13: "A DPO record on the monitoring of named administrators (purpose, subjects, retention, recipient) and HR's written answer on information or consultation exist (the POV's SD-11 and PV-08 form, pov/02 PD-2.1 and PD-5.1) — or the poll is limited to persons A and B, each with written consent, for the three days (the fallback pov/README §4 describes), and `userKey` names them rather than `all`." Reword §7 item 9 and C-12: "… no works-council information completed. Two consequences: nothing mutating touches a real account, and Eve's poll is limited to the two participants unless the DPO record and HR's answer exist." Add to §10 row 12 that a poll left standing is a standing monitoring system and names its DPO record | fixed 2026-09-18 |
| X-04 | high | [3-day/day-3-mo-demonstration-and-handover.md](3-day/day-3-mo-demonstration-and-handover.md#t3-19-the-unwind-today-from-1600-with-both-people-present) | §T3-19 | As read by the security review before the corrections, the unwind had steps a–g only and left both OAuth clients Trusted at organisation scope, both client secrets readable, `eve-reader@`'s token unreached, and the staging OU, the `stewardAuditWriter` role and the two `run.invoker` user bindings in place — a tenant left with two organisation-wide allowlisted apps and their credentials | Carried on 2026-09-18: T3-19 now has steps h (both clients Blocked in app access control), i (clients deleted, Eve's only if Eve is stopped), j (credentials destroyed), k (staging unit, writer role, dataset writer entry and invoker bindings removed), l (application-default credentials revoked), m (envelopes decided), and d loops over (secret, project) pairs with `eve-refresh-token` in `EVE_PROJECT` by decision. The later step verifies each read-back exists and closes this row | fixed 2026-09-18 (verified in place: T3-19 a to m and d, g as described; no further edit was needed) |
| X-05 | medium | [README.md](README.md#status) | Status "What this set is"; Documents row 12; Maturity row "The design"; Maturity row "Google Cloud"; the 3-day row | The map contradicts its own table: thirteen pages and 143 decisions while listing page 13, pov/ and 3-day/ and a register of 204 rows; `GEMINI_PROJECT` stated to exist without `Assumption:`; the 3-day row says the synthetic accounts are "unwound" where the set suspends them. Merges the coherence report's C-01 and C-21 and the paths report's F-15 | Status: "fifteen design pages (00–14), three build sets (setup/, pov/, 3-day/) and the brief; the register of record is P1–P204 (P144–P191 proposed by the setup procedures on 2026-09-15, P192–P204 by the proof of value on 2026-09-16)". Row 12: "all 204 decisions". Maturity: "decisions P1–P204 recorded" plus a row for the build sets ("written 2026-09-15 to 2026-09-17, corrected 2026-09-18, never executed"); "`GEMINI_PROJECT` exists as the tenant app's project (`Assumption:`; confirmed at GE-0)"; 3-day row "synthetic accounts suspended" | fixed 2026-09-18 |
| X-06 | medium | [README.md](README.md#reading-order-for-a-builder) | "Reading order for a builder", step 7 | The builder is told the Tier C runbook "needs no factory"; 03 §16 imports the app through the factory's `tenant-app` module and setup SD-13 runs Tier C after Tier R | Step 7: "the runbook to bring the tenant app to baseline (Tier C); it imports the app's project through the factory's `tenant-app` module, so it runs after the folder and core projects exist — in the build, after Tier R (setup/README §3.1, SD-13)" | fixed 2026-09-18 |
| X-07 | medium | [brief/32-document-map.md](brief/32-document-map.md#build-procedures) | "Build procedures"; "The agent sets — Wall-E"; "Reading paths — Builder"; chapter table rows 15 and 24 | Names four build procedures and sends the builder to SETUP.md and PREREQUISITES.md; three of the four were retired to pointer pages on 2026-09-16 and the one entry point is setup/README, with pov/ and 3-day/ beside it | Replace the section with: "One entry point: setup/README.md (42 files, order platform → Mo and Eve → Wall-E, 6–7 months to Stage 0); beside it the proof of value pov/README.md (Tiers C, R, W; no Super Admin to any agent) and the three-day build 3-day/README.md (two people, six person-days). SETUP.md, PREREQUISITES.md, eve/07 and mo/07 are pointer pages since 2026-09-16." Change the Wall-E bullets, the Builder reading path and rows 15 and 24 accordingly | fixed 2026-09-18 |
| X-08 | medium | [01-hld.md](01-hld.md#06-traceability-the-objectives-sixteen-requirements-and-the-register-ids-not-cited-elsewhere) | §0.6, row R3 | The traceability table says R3 is met by band A on the chat trigger and records no qualification, but the ladder lets band A families run on scheduled, event and inbox triggers once earned; the brief declares this as unqualified in the HLD and asks the owner to confirm it | Row R3, column "Declined or qualified": "qualified: the human prompt is the origin of Wall-E's mandate, not its only trigger — a band A family earns scheduled, event and inbox triggers (T1–T3) through the ladder, and only band A can; band B is chat only. The owner confirms this reading (new row at P205)" | fixed 2026-09-18 (the P205 row itself is still to be appended in 12-open-decisions.md) |
| X-09 | medium | [brief/29-roadmap-and-cost.md](brief/29-roadmap-and-cost.md#what-can-start-with-the-people-who-exist) | "What can start with the people who exist"; "The builder's order" steps 4–6; "The opening sequence" diagram | Makes the tenant-app baseline the first delivery, before the first nonprod project, and never mentions the setup set's block order or dated milestones; the build of record runs Tier R (09–18) before Tier C (19–20) by SD-13 and dates Tier R at 2026-11-10 to 2026-12-08, Tier C at 2026-12-08 to 2027-01-19, the grant not before 2027-03 | Rewrite "What can start" and the builder's order from setup/README §3.1 and §3.4 (day one 01–05 with the toil baseline first; organisation 06–08; Tier R 09–18; Tier C 19–20; sandbox 21; Mo and Eve 22–29; Wall-E 30–39); add the milestone table's earliest dates and the pov and 3-day alternatives with durations; redraw the diagram in that order | fixed 2026-09-18 |
| X-10 | medium | [brief/29-roadmap-and-cost.md](brief/29-roadmap-and-cost.md#which-runbook-creates-what-and-the-effort-shape) | "Which runbook creates what, and the effort shape"; "Day-one lead-time items" | Effort figures come from the retired SETUP.md §0.4 and the section says Wall-E's setup script keeps the Workspace-side phases; setup/README §3.2 found six of those figures under-booked and SD-37 makes `walle_setup.py` a helper only with the manual commands canonical | Take hands-on and elapsed figures from setup/README §3.2 and the totals from pov/README §4 (marked as X-22 asks); replace the script sentence with SD-37's; point the lead-time list at setup/04 instead of wall-e/PREREQUISITES §9 | fixed 2026-09-18 |
| X-11 | medium | [brief/02-executive-summary.md](brief/02-executive-summary.md#where-things-stand-on-2026-09-17) | "Where things stand on 2026-09-14"; "Eve's independence, stated honestly"; "Read next" | Does not carry the 2026-09-15 change by which Eve's first half watches every human super admin from its first run before Wall-E exists, nor that setup/, pov/ and 3-day/ now exist with durations, nor that the register runs to P204. A sponsor reading only this chapter, as the brief invites, misses the build's shape and Eve's first job | Retitle "Where things stand on 2026-09-18"; add one paragraph on Eve's first half over the human super admins with the second human's independent proof; one paragraph naming the three build sets with people, durations and what each may not claim; update the register count; add the three build READMEs to "Read next" | fixed 2026-09-18 |
| X-12 | medium | [00-objective-review.md](00-objective-review.md#32-other-reversals-the-lenses-found) | §3.2, row "Eve has no judgement anywhere", column "Consequence" | Says the `eve-advisor` slot may be built as a reporting path "able only to raise a refusal"; the P34 record removed that wording on 2026-09-13 and the standing constraint says no model produces a refusal; the row carries no dated line, so a reader takes it as current | Append to the cell: "— superseded 2026-09-13: the reporting path is report-only by construction and raises no refusal; nothing it writes is read by the gate or an action service (P34 record; 01-hld §13.2)" | fixed 2026-09-18 |
| X-13 | medium | [01-hld.md](01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens) | §0.4, row "X AGI-class" | Counts Tier X's unmet conditions as four; [§11.5](01-hld.md#115-the-honest-line) lists six conditions of which five are unmet; the brief records the difference but the authority still carries both | §0.4: "one (the sandbox stage) is met and five are not (§11.5)"; brief/29 and brief/16 then drop the recorded difference | fixed 2026-09-18 (brief/29 and brief/16 still record the four/five difference and should drop it) |
| X-14 | medium | [brief/19-eve.md](brief/19-eve.md#when-each-part-arrives) | The chapter's account of Eve's staging and first job | Does not carry the 2026-09-15 scope by which Eve's first half watches every human super admin from its first run before Wall-E exists, reports to the second human with a copy in the witness, and is proven by that person on a seeded super-admin action; the HLD carries it in §13.2 | Add a section "Eve's first job: the human super admins (2026-09-15)" summarising HLD §13.2 and setup 23–28's order (project and stores; identity and the six streams; detections deployed paused; reporting and witness export; witness grants and alarms; the second human's independent proof, `EVE_H_LIVE_RECORD`), and re-date the Status line | fixed 2026-09-18 |
| X-15 | medium | [12-open-decisions.md](12-open-decisions.md#4-before-the-super-admin-grant) | §4, row P29, column "Decision" | Defines the second of the two lists as "protected principals"; the HLD §13.1, the P33 decision record and wall-e/06 define it as the operations reachable only through band B at tier `SUPER` under a two-person rule; the owner is asked to sign lists two authorities describe differently | Row P29: "The two lists — (1) the hard-denied operations, refused in every lane including the band-C handoff; (2) the operations reachable only through band B at tier `SUPER` under the two-person rule — signed as decision 4 re-ratified. Protected principals are a separate invariant of the policy chain (wall-e/03), not one of the two lists." Add "wording aligned with 01-hld §13.1 and the P33 record on 2026-09-18" | fixed 2026-09-18 |
| X-16 | medium | [../wall-e/README.md](../wall-e/README.md#documents) | "Documents — Standalone documents" table; numbered table row 7 | Still presents PREREQUISITES.md ("Read it first"), SETUP.md ("executable by a Workspace super admin who owns four GCP projects") and setup/ ("The automation") as the build; all three were retired on 2026-09-16 and the script is a helper only under SD-37 | Replace the three rows with one: "Build: ../agentic-platform/setup/README.md, files 30–39, after the platform (09–20) and Eve's first half (23–28); PREREQUISITES.md, SETUP.md and setup/ are pointer pages since 2026-09-16; `walle_setup.py` is a helper under SD-37, never the procedure." Row 7: "pointer; the build is setup/ 30–39" | fixed 2026-09-18 |
| X-17 | medium | [../eve/README.md](../eve/README.md#documents) | Documents row 7; "Reading order — Building it"; "Maturity" table | Presents 07-build-runbook.md as "the ordered, runnable steps" and sends the builder to it although it was retired on 2026-09-16; the maturity digest still opens with Eve v0 over Wall-E's audit at S0 and does not carry the 2026-09-15 order in which Eve's first half watches the human super admins before Wall-E exists | Row 7: "pointer since 2026-09-16; the build is setup/ 23–29 (Eve's first half over the human super admins, ending at `EVE_H_LIVE_RECORD`), 36 (what needs Wall-E) and 41 (S3, S4)". Reading order: replace 07 with those files. Maturity: add a first row "Eve's first half (Eve-H): detections over every human super admin, reporting to the second human, witness export, independent proof — before Wall-E exists (setup 23–28; P153–P155)" | fixed 2026-09-18 |
| X-18 | medium | [../mo/README.md](../mo/README.md#documents) | Documents row 7; "Reading order — Building it"; "Maturity" rows 2–3 | Presents 07-build-runbook.md as Mo's phases with verify blocks and says Mo's resources are created by Mo's own runbook and its cross-project grants from Wall-E's and Eve's runbooks; all three runbooks were retired on 2026-09-16 and the makers are now setup 22, 29, 36, 40 | Row 7: "pointer since 2026-09-16; the build is setup/ 02 (the toil baseline, day one), 22 (foundations), 29 (the Eve quality pack), 36 (the Wall-E pack) and 40 (after Stage 0)". Reading order and Maturity rows: name those files and the grant makers (Eve's grants in 29 and 36, Wall-E's in 36) | fixed 2026-09-18 |
| X-19 | medium | [3-day/README.md](3-day/README.md#12-how-it-grows) | §12 row "Eve's Reports API poll"; §10 rows 11 and 12 | Hands the poll to pov/06, which "adds the fingerprint, the lock and the unannounced proof"; pov/06's Eve holds no Workspace credential and has no Reports poll (PV-D-07, P199) — the poll is what PV-D-07's unwind adds later. The three-day poller, `eve-reader@`, its refresh token and the `eve.ws_activities`, `eve.poll_runs` and `eve.watchlists` tables have no receiving step in the POV, yet §10 leaves them running | Rewrite the row: pov/06 does not continue the poll; it builds Eve on the organisation sink without a Workspace credential (PV-D-07), and the poll returns in setup/24 EW-1.x beside the sink. Then say what happens to the poller at the hand-over: either §10 row 11 becomes "stopped, token disabled, `eve-reader@` suspended, recorded" before pov/06 PE-0.2, or it is kept as PV-D-07's unwind exercised early, which pov/06 must record under the DPO record. Name one | fixed 2026-09-18 |
| X-20 | medium | [pov/README.md](pov/README.md#status) | Status, bullet "Smaller counterpart, added 2026-09-17" | Names three things unwound and is silent on the two the three-day set leaves running on purpose — `eve-reader@` with a live Reports-API token and a scheduled poller, and four projects whose ids the POV's own form check refuses (X-02). Kept, the poller contradicts P199 and PV-D-07 from the POV's first day; unaddressed, the projects are orphaned. "Unwound" also overstates row 8, which leaves the synthetic accounts suspended | Add one sentence: the three-day poller is stopped and `eve-reader@`'s token disabled before pov/06 PE-0.2, or recorded as PV-D-07's unwind exercised early under PV-08's DPO record; the three-day projects are adopted as `EVE_PROJECT`, `MO_PROJECT`, `CORE_PROJECT` and the Tier P project only if their ids satisfy PD-3.2's form check, otherwise they stay as history under PV-13's no-teardown clause. Change "synthetic accounts are unwound" to "synthetic accounts suspended" | fixed 2026-09-18 |
| X-21 | medium | [3-day/README.md](3-day/README.md#5-the-four-projects-and-why-the-doers-project-is-not-called-walle) | §5 "Mo's five views live in `MO_PROJECT`"; §12 row "Mo's five views and the scorecard"; §6.1 | Says where Mo's views live but never in which dataset; the 2026-09-18 correction moved code.md §5 into `MO_PROJECT.mo`. The POV and the full build fix Mo's dataset names as `platform_metrics`, `platform_metrics_views` and siblings, agent-neutral and irreversible (SD-33, P176). Views created anywhere else are not "the full build's name", and §12's hand-over of the views to pov/08 cannot proceed without renaming | In §5 name the datasets: the five views in `platform_metrics_views` and the retrospective volume table in `platform_metrics`, both in `MO_PROJECT`, per SD-33; change code.md §5 and day-3 T3-2 accordingly and record it in §6.1 | fixed 2026-09-18 (3-day/README §5 and §12; code.md §5 still creates the views in `MO_PROJECT.mo` and the move to `platform_metrics_views` is recorded in §6.1 as owed to code.md §5 and day-3 T3-2) |
| X-22 | medium | [pov/README.md](pov/README.md#4-pov_stage_dates-the-two-stages); [pov/09](pov/09-the-demonstration-deviations-and-the-hand-over.md#6-the-hand-over-map-handover_table) | pov/README §4 bullet "Against the full build"; pov/09 §6 "Cost remaining after the POV" | Both quote "85 to 90 person-days hands-on, thirteen appointments, thirteen purchase rows" as the full build's figures from setup pages that state no such totals; setup/README §3.2 gives per-file cells and §3.4 gives dates. The two thirteens are derivable (setup/03 §5; setup/04 PU-2.1 to PU-2.13) but not stated as totals. A sponsor comparing the paths is given a number no page owns. Merges the paths report's F-06 and F-07 | Mark the three figures `Assumption:` and say how they were obtained: "85 to 90 person-days, summed from the hands-on cells of setup/README §3.2 on 2026-09-16; thirteen appointment records (setup/03 §5); thirteen purchase steps (setup/04 PU-2.1 to PU-2.13)"; or ask setup/README §3.4 to carry the sum and cite it. Same edit in pov/09 §6 | fixed 2026-09-18 (pov/README §4; the same edit in pov/09 §6 is still to be made) |
| X-23 | medium | [3-day/README.md](3-day/README.md#7-what-three-days-cannot-buy) | §7 item 4; §8 row C-04 | "Nothing is exposed to the internet" overclaims. The action service is a Cloud Run service with a public URL; `--no-allow-unauthenticated` makes it refuse callers without an IAM identity, it does not make it unreachable. The POV's no-pentest deviation treats "any grant" as its unwind trigger. A sponsor could repeat the sentence as a security fact | "Nothing accepts an unauthenticated request: the action service's URL is reachable from the internet and relies on IAM (`run.invoker` to two named principals) alone, which is a reason a penetration test is owed, not a reason it is not needed" | fixed 2026-09-18 |
| X-24 | medium | [06-gateways-model-armor-perimeter.md](06-gateways-model-armor-perimeter.md#43-credential-holders-are-never-internet-reachable-as-a-folder-rule) | §4.3 table, rows "Mechanism (until then)" and "On failure" | Says a credential holder deployed with ingress `all` before spike 1 "is a severity 2 finding and the deploy is rolled back by CI", while the full build deploys every credential holder with `--ingress=all` on purpose and records it as deviation BD-33-2, because Agent Runtime egresses from a Google-managed project that Cloud Run treats as external and `internal` ingress blocks the engine. Two pages disagree on the pre-spike state | Rewrite the "until then" row: ingress `all` with IAM-only invoke and the audience check is the expected pre-spike state for engine-called services, recorded per project as a dated deviation; the custom module flags it as informational until the constraint is applied, and severity 2 applies only to a service whose `run.invoker` set holds anything but named service accounts | fixed 2026-09-18 |
| X-25 | medium | [setup/38-super-admin-gate-and-grant.md](setup/38-super-admin-gate-and-grant.md#4-gate-day-part-one-roster-ready) | §GT-4.7, the who-can-mint loop | The action service trusts the approver's identity as forwarded by the approval surface (setup/33 WS-5.8 item 3: the IAP claims are verified by the surface, not by the action service). Whoever can mint an ID token for `walle-approvals-super@` can post an approval naming `SA_2_ADMIN` as approver and satisfy every in-app check. GT-4.7 asks who can mint tokens for the two credential holders and never asks the same of the two surface identities, although setup/33 WS-5.2 granted exactly that ability to `SA_1_ADMIN` for a sitting and WS-9.0 is the only thing that withdrew it | Extend GT-4.7's loop to `SA_APPROVAL_A` and `SA_APPROVAL_SUPER` with the same five permissions and the same `NO HUMAN CAN MINT OR ACT AS THIS ACCOUNT` closing line; say in one sentence why: an impersonated surface is a forged approver. Separately, 07 §6.3 SG-07 should gain the two surface identities (a `setIamPolicy` or Token Creator grant on either is severity 1) | fixed 2026-09-18 (GT-4.7; the 07 §6.3 SG-07 addition is still to be made) |
| X-26 | medium | [04-identity-and-privileged-access.md](04-identity-and-privileged-access.md#97-how-k7-sits-with-each-agents-k0k6) | §9.7 table, K6 row; [§8.4](04-identity-and-privileged-access.md#84-workspace-multi-party-approval-the-two-person-rule-google-enforces) "What it does not buy" | Two pages disagree on whether K6 is a one-person or a two-person act. 04 §9.7 gives K6 to "a human super admin (`users.makeAdmin` false) … within 60 min"; setup/38 GT-8.2 says one requests and the other approves because multi-party approval covers it. 04 §8.4 records whether `makeAdmin` is covered as an `Assumption:`. If covered, the switch that survives a minted token waits for an approver at 03:00 and the rota must say who; if not, K6 is fast but the robot's own `makeAdmin` is refused by code and detection only | In §9.7's K6 row write "the on-duty human super admin requests; the other approves under multi-party approval (§8.4) — two people, `oncall.yaml` names the second; if the sandbox tenant shows `makeAdmin` is not covered, K6 is one person and §8.4's first row is re-graded to code plus detection for that method". Add the same sentence to §8.4's "What it does not buy" | fixed 2026-09-18 |
| X-27 | medium | [10-eu-ai-act.md](10-eu-ai-act.md#312-annex-iii-4b-family-by-family) | §3.1.2 row "F5 Suspend" and the "Result" paragraph; [§0](10-eu-ai-act.md#0-the-position-in-one-paragraph) | The suspension family's derogation is stated as resting primarily on Art. 6(3)(b) "improves the result of a previously completed human activity". Recital 53's examples for (b) are systems improving the language of previously drafted documents; executing a suspension carries a decision out rather than improving anything, so (a) narrow procedural task that does not materially influence the outcome fits better. The page's own §9 lists the fit as unverified, yet §3.1.2 and §0 present (b) as the claim | Swap the order in the F5 row: primary "(a) narrow procedural task: executes a decision recorded elsewhere (`decision_ref`), so the AI output does not materially influence the outcome"; secondary "(b), if legal reads 'result' as the tenant state". Rewrite §0's "condition (b) for the suspension family" to "condition (a), with (b) as a secondary reading". Keep the §9 row and add "Recital 53's examples for (b) are language improvement of drafted text" as the reason | fixed 2026-09-18 |
| X-28 | medium | [10-eu-ai-act.md](10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129) | §4.10 "Timing moves to before Stage 1" and the duty table | Worker information is gated on Stage 1 of any Tier W agent acting on employee accounts, but on the platform's own order (11 §6.3; HLD §0.4) Eve over the human super admins and the identity log store copying every account's sign-ins go live before the grant, which precedes Stage 0 and Stage 1. Both are "monitoring systems at the work place" under GDPR Art. 88(2) from their first stream; a reader following §4.10 informs the works council after the monitoring has started. The default `Assumption:` of "information" is the weaker of the two possibilities in the likely jurisdictions | Add a second trigger: "and, earlier, before Eve's observe-and-report layer copies its first stream about human administrators and before the identity log store's first copy — whichever comes first — with the DPO's SD-11 record as the companion artefact (setup/24 EW-0.2; pov/06 PE-0.2)". Change the default `Assumption:` from "information" to "consultation, and consent where co-determination applies; information only where HR's answer says so" | fixed 2026-09-18 |
| X-29 | medium | [12-open-decisions.md](12-open-decisions.md#5-before-wall-es-stage-1-and-its-later-stages) | Row P129, "Gate" column | Gates P129 on Stage 1 of a Tier W agent only — the same timing defect as X-28, and this row is what the setup and POV runbooks read | Gate column: "before Eve's observe-and-report layer goes live over human administrators and before the identity log store's first copy; and before Stage 1 of any Tier W agent acting on employee accounts" | fixed 2026-09-18 |
| X-30 | medium | [12-open-decisions.md](12-open-decisions.md#4-before-the-super-admin-grant) | Row P136 | Two disagreements with page 11 and the decision record: the gate-condition list omits the DPIA and the works-council information that 11 §6.3 carries as a "+" row and HLD §0.4 lists; and "re-signed quarterly" where 11 §6.2 and the record say reviewed quarterly and re-signed at each Wall-E stage transition. Brief 25 records both without resolving them | Add "the DPIA and the works-council information" to the gate-condition list; replace "re-signed quarterly, at every Wall-E stage transition and on any severity-1 credential incident" with "reviewed quarterly with the roster review; re-signed at every Wall-E stage transition, whenever a compensation's grade changes and on any severity-1 credential incident" | fixed 2026-09-18 |
| X-31 | medium | [11-tisax.md](11-tisax.md#10-the-risk-register-p140) | §10 row R-01, "Owner" and "Acceptance" columns; cross-check §6.3 row 12 | Names the platform owner as R-01's owner; the append-only decision record names the security reviewer, and page 11's own §6.3 row 12 also puts the security reviewer in the owner column. The assessor is handed both documents | Set §10 R-01 Owner to "security reviewer (owner and signatory, as the decision record states)" and Acceptance to "platform owner decides and accepts the residual; security reviewer signs; ISMS enters — [decisions/2026-09-13-wall-e-holds-super-admin.md](../../decisions/2026-09-13-wall-e-holds-super-admin.md)" | fixed 2026-09-18 |
| X-32 | medium | [11-tisax.md](11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads) | §6.3 "+" row "DPIA started; works-council information given"; [§12](11-tisax.md#12-documentation-task-versus-control-that-does-not-exist) second table, row "DPIA, records of processing …" (gate "Stage 1") | GDPR Art. 35(1) requires the assessment prior to the processing. After the grant, Stage 0 reads every employee's directory record, and Eve has copied the administrators' actions since before the grant; "DPIA started" at the grant and "Stage 1" in §12 put the assessment after the processing it must precede. HLD §0.4 says "the DPIA" (complete); brief 26 §22.9 flags the two readings | Change the §6.3 row to "DPIA complete and signed for Eve's monitoring of administrators, the identity log store and the Stage 0 reads; DPIA for the write families started with a dated completion before Stage 1; works-council information (or consultation) given". In §12 split the DPIA row into the two halves with gates "before Eve's first stream" and "Stage 1" | fixed 2026-09-18 |
| X-33 | medium | [3-day/day-1-platform-and-eve.md](3-day/day-1-platform-and-eve.md#t1-12a-the-doers-foundation-audit-dataset-two-tables-two-service-accounts-three-secrets); [3-day/day-2-the-doer.md](3-day/day-2-the-doer.md#t2-11-read-back-the-three-secrets); [3-day/code.md](3-day/code.md#3-doeractionspy) | day-1 T1-12a step 4 (the halt binding); day-2 T2-11 VERIFY and T2-25 UNDO; code.md §3 `set_halt` | The action service's own identity holds `roles/secretmanager.secretVersionAdder` on `steward-halt`, so the process being halted can add a version reading `off` and un-halt itself. "It only ever tightens" is a property of the code, not of the IAM; a compromised or redeployed service clears its own K0, inverting "machines lower, humans raise" for the one lever the build exists to demonstrate. T2-11 verifies both roles on the service identity, and T2-25 says clearing a halt "takes two people" with "no clear endpoint, on purpose", while the same service identity and either project owner can clear it alone in one command — a room rule, not a control, and the page does not say so. Merges the security report's F-03 and F-04 | Remove the `secretVersionAdder` binding from T1-12a. Have person B pull K0 with `printf 'on' \| gcloud secrets versions add steward-halt --data-file=- --project="$DOER_PROJECT"` from their own account, and delete `/control/halt` or make it read-only. Change T2-11's VERIFY to "`steward-actions@` holds `secretAccessor` only; no service identity holds `secretVersionAdder`"; make T2-25's K0 the `gcloud secrets versions add` by person B; replace "takes two people" with "is done by one person with the other initialling the line, because nothing in this build enforces the second person on a clear". State in code.md's two-facts preamble that the halt is written by a human identity only and read by the service | open: code.md §3 done 2026-09-18 (`set_halt` and `POST /control/halt` removed, the halt written by a human identity only, T1-12a's `secretVersionAdder` binding marked as must-not-exist in code.md §7) and day-2 T2-25's "takes two people" reworded; still to change — day-1 T1-12a line 554 binds `secretVersionAdder` to `steward-actions@`, day-2 T2-11 VERIFY keeps both roles and T2-25 (lines 331, 373, 386, 988) and day-3 line 589 still pull K0 through the removed endpoint |
| X-34 | medium | [3-day/README.md](3-day/README.md#11-the-eight-risks-and-what-to-do) | §11, last paragraph (the caller service-account fallback); §2 absolute 4 | The fallback "impersonate a dedicated caller service account holding `roles/run.invoker`" collapses the two-person rule: `actions.py` compares `approver == requester` by e-mail and never refuses a service identity as requester, so whoever can impersonate the caller account can approve as themselves and request as the account, and one person executes. Absolute 4 is then a procedure, not a control, and the page does not say so | In §11 state that under the fallback the approver must hold no `serviceAccountTokenCreator` on the caller account (bind it to person A only, read the policy back by person B, remove it in T3-19), and that the code must refuse a service-identity requester on `/act` at level 2 unless the caller account's only impersonator is not the approver. Add the binding to §10's unwind | fixed 2026-09-18 |
| X-35 | medium | [3-day/README.md](3-day/README.md#6-what-must-be-true-before-day-1-starts) | §6 row 12; §11 "Six things Google does not settle" | Two pages disagree on a fact the whole live block depends on: the README says whether `gcloud auth print-identity-token --audiences=<url>` works for a user credential is unverified, while setup/33 WS-3.6 states it is refused for user credentials — gcloud accepts the flag only for a service account or an impersonation. If setup/33 is right, every `TOK()` call in day 2 fails and the fallback of X-34 becomes the main path | Adopt setup/33's statement. Make the pre-flight of §6 row 12 mandatory the week before, and prepare the alternative in code before the run: accept in `caller_email` either the service URL or Google's gcloud client id as audience for a user token minted without `--audiences`, or make two caller service accounts (one per person, each impersonable by that person only) the designed path with the X-34 rule | fixed 2026-09-18 |
| X-36 | medium | [3-day/README.md](3-day/README.md#61-corrections-made-on-2026-09-18) | §6.1 row 3 (the `eve.watchlists` seed, now day-1 T1-9a); §7 item 5 and C-21 | The six detections contain no reconciliation rule (no SA-07 equivalent), so a use of the robot's refresh token outside `steward-actions` — by either project owner reading the secret, which no Data Access log records under C-26 — produces an admin event with no audit row and pages nobody if the robot is on the `admin_allowlist`. Whether it is on that list is now set by T1-9a and must be stated. The claim "whose every action is written ahead to an audit table" is true of the service and silent about the credential | Say in §6.1 row 3 and T1-9a that `steward-robot@` and `eve-reader@` are not on `admin_allowlist`, so every robot-attributed admin event fires R2 to person B, who reconciles it by hand against `steward_audit.actions` for the same minute; add to §7: "no automatic reconciliation of robot events against the audit table exists; credential use outside the service is caught only if person B reads every R2 page" | fixed 2026-09-18 |
| X-37 | medium | [3-day/code.md](3-day/code.md#1-evepollerpy) | §1 `poller.py` `APPS` default (the deploy no longer carries an `APPS` flag, so the default is what runs) | The poller reads the `login`, `token`, `user_accounts` and `groups_enterprise` streams with `userKey=all` — every real employee's sign-in, token and account activity — landed in BigQuery, with no DPO record and no works-council information (C-12). The design makes exactly that record a hard gate for Eve's polling (eve/01-hld "Scope from the first run"), and C-12's justification ("nothing mutating touches a real employee") does not cover reading. Companion of X-03 | Default `APPS` to `admin`; poll `login` with `userKey` set to each robot account only (R5 needs nothing wider); drop `token`, `user_accounts` and `groups_enterprise` unless a DPO record exists, and say in the deploy block that the widened set is a decision, not a default | fixed 2026-09-18 |
| X-38 | medium | [3-day/README.md](3-day/README.md#status) | Status, bullet "Counterparts, neither replaced"; §12 diagram line "three people, 6 to 20 weeks" | The POV's elapsed time is misquoted: six to nine weeks is POV-1 alone; the POV ends at week 16 to 20 with a dedicated engineer and week 26 to 34 if one person writes the code, and the POV itself warns that a shorter figure misleads a sponsor. "Three people" drops the engineer | Status: "(20 to 26 person-days of procedure and 40 to 64 engineer-days of code; 16 to 20 weeks elapsed with a dedicated engineer, 26 to 34 if one person does both)". §12: "three hands-on people and one engineer, 16 to 20 weeks" | fixed 2026-09-18 |
| X-39 | medium | [3-day/README.md](3-day/README.md#10-the-unwind-before-anything-real-is-touched); [3-day/day-3](3-day/day-3-mo-demonstration-and-handover.md#t3-19-the-unwind-today-from-1600-with-both-people-present) | README §10 row 1; §7 item 6; day-3 T3-11 row 6, T3-18 part 5, T3-19 step a | As read before the corrections, the README said no IAM binding is time-boxed (every one made with `--condition=None`) while day 3 told the next team "time-boxed IAM grants stood in" and T3-19a removed bindings with a `request.time` condition, which against an unconditional binding removes nothing; the hand-over note would have recorded a control never built. Merges the paths report's F-10 and the security report's F-02 | Carried on 2026-09-18: T3-19a now removes with `--condition=None` and reads back "the only `user:` bindings left are `roles/owner` for the two named owners", and T3-11 row 6 reads "no time-boxing; standing IAM grants stood in, removed the same day by hand". The later step verifies T3-18 part 5 says the same and closes this row | fixed 2026-09-18 (verified in place: T3-19a removes with `--condition=None` and reads back the owner-only bindings; T3-11 row 6 reads as stated; no further edit was needed) |
| X-40 | low | [brief/32-document-map.md](brief/32-document-map.md#the-platform-set); [brief/29](brief/29-roadmap-and-cost.md#the-registers-gate-groups-are-the-roadmap); [brief/30](brief/30-decisions-awaiting-owner.md#one-sequence-five-states); brief/00-front-matter.md line 78; brief/31-glossary.md row "P1–P143" | The page count, decision range, row count and next free id, wherever the brief states them | Stopped on 2026-09-14: "thirteen pages, 00 to 12"; "P1–P143 … new rows append at P144"; "The register holds 143 decisions"; "143 rows"; "a new row would take P144". Merges the coherence report's C-05, C-08 and C-28 | "fifteen pages, 00 to 14, and three build sets" with bullets for 13 (the setup review of 2026-09-15) and 14 (this review); "P1–P204 (P144–P191 proposed by the setup procedures, P192–P204 by the proof of value); new rows append at P205; §6a and §6b hold the rows the build sets proposed"; "204 decisions: 143 grouped by the gate each blocks, 48 from the setup procedures (§6a) and 13 from the proof of value (§6b)"; "204 rows"; "a new row would take P205" — each in its own file | open |
| X-41 | low | [brief/02-executive-summary.md](brief/02-executive-summary.md#what-was-asked-and-the-readings-the-design-declines-or-qualifies) | "What was asked, and the readings the design declines or qualifies" | Counts two declined readings; the HLD's traceability column uses "declined" for the literal reading of R4 and for structural independence inside the tenant under R8 as well, and brief/03 §R8 itself says "declined as unachievable" | "Two requirements are declined as worded (R12, R14); the literal readings of R4 and of R8's independence inside the tenant are declined and replaced by what the design delivers; R6, R11, R13 and R15 are qualified for stated reasons" | open |
| X-42 | low | [brief/02-executive-summary.md](brief/02-executive-summary.md#the-organisation-that-exists-and-what-the-platform-costs) | "The organisation that exists, and what the platform costs" | The staffing minimum at the grant is given as four; the build's SD-04 counts five named humans, or four with a dated ISMS exception, and brief/30 asks who the fifth is | "… and at the grant five (SD-04: the two witness administrators are neither tenant super admins nor the second human), or four with a dated ISMS exception" | open |
| X-43 | low | [brief/README.md](brief/README.md#what-this-is) | "What this is" | "Say what is built" reads as a claim of existence on a page whose Status says the design is not built | "say *what* is to be built" | open |
| X-44 | low | [setup/README.md](setup/README.md#1-what-the-set-builds-and-what-it-replaces) | §1 "Standing constraints that every file keeps" | Drops two of the HLD's eight constraints (the action service as the only credential holder; safety interlocks as plain authenticated REST) and mixes build rules into the same list, so a reader cannot tell fleet constraints from this set's rules; pov/README copies it as "the full set's standing constraints" | Quote the HLD's eight verbatim under "Standing constraints (01-hld Status)", then a second list "Rules of this set, stricter and never looser: no service identity is ever the second person (SD-48); a merged Mo proposal has two human reviewers (HLD §9); a dry run never mutates (wall-e/05 L1)" | open |
| X-45 | low | [pov/README.md](pov/README.md#2-the-absolutes-binding-on-every-pov-file) | §2, first paragraph | The quotation of the standing constraints cites line numbers of setup/README that moved in its revision 3 ("lines 60 to 66"; the list is at lines 74–80 on 2026-09-18) | Cite the section, not the lines: "quoted from setup/README §1, 'Standing constraints that every file keeps'" | open |
| X-46 | low | [01-hld.md](01-hld.md#status) | Status, "Standing constraints, unchanged" | "A dry run never mutates" is an absolute of the pov and 3-day sets and a ladder rule (L1 forces `dry_run`) but is absent from the HLD's standing constraints, so the restatements differ by one item and a page could loosen it without contradicting the HLD Status | Add to the Status list: "a dry run never mutates — L1 forces `dry_run` and refuses to execute even when handed a valid approval (wall-e/05 §2)"; brief/05 §4.4 then reads "Nine constraints" | open |
| X-47 | low | [3-day/README.md](3-day/README.md#2-the-nine-absolutes) | §2, after the nine absolutes; §8 row C-09 | C-09 keeps one reviewer on the Mo merge. The POV's absolute 4 requires two human reviewers who are neither the author nor a Mo identity, and setup/README §1 reads "two human reviewers"; the cut is honest and names its unwind, but §2 says the absolutes are restated verbatim and does not say this POV absolute is not carried, and C-09 cites only pov/08 PM-9.2. Merges the coherence report's C-17 and the paths report's F-16 | Add a tenth absolute: "Mo reaches production only through a pull request a human who is not its author merges (01-hld Status)"; after the absolutes add: "Not carried from the proof of value's absolutes: the two-reviewer clause on a Mo merge (pov/README §2 item 4; setup/README §1), cut as C-09 because two people cannot supply two reviewers who are not the author"; in C-09 cite setup/README §1 beside pov/08 PM-9.2 and say the cut is HLD §9's fleet rule, not the standing constraint | open |
| X-48 | low | [3-day/README.md](3-day/README.md#8-the-cut-list-c-01-to-c-27) | §8 row C-01, column "Where it comes back" | "setup/27 `WI-*`": `WI` is setup/34's prefix (identity spike and Model Armor); setup/27's is `WG` | `WG-*` | open |
| X-49 | low | [3-day/README.md](3-day/README.md#11-never-to-be-used-in-any-report-slide-or-message) | §1.1, opening line "Copied unchanged from pov/README §1.2, and one more" | The three sentences are adapted, not copied: sentence 1 drops the POV's clause that no report may say the doer "does admin work" (necessarily, since this doer does), and sentence 3 replaces "It produced evidence" with "no Model Armor evidence at all" | "Adapted from pov/README §1.2 and one more; sentences 1 and 3 differ because this doer holds a delegated role and Model Armor is set but never exercised" | open |
| X-50 | low | [3-day/README.md](3-day/README.md#5-the-four-projects-and-why-the-doers-project-is-not-called-walle) | §5 "Every artefact carries the full build's name"; §6.1 row 6; day-1 T1-1 | `names.env` exports `CUSTOMER_ID="my_customer"`, a name the full build retired (`DIRECTORY_CUSTOMER_ID`, setup/01 PR-2.6) and the POV lists among the names that must never appear. The value is a valid API alias; the name is not the full build's | `names.env` uses `DIRECTORY_CUSTOMER_ID`, read once at T1-1, and day-2 and day-3 preconditions read that name; record it in §6.1 | open |
| X-51 | low | [pov/README.md](pov/README.md#what-this-part-builds) | "What this part builds", last paragraph | Overclaim: everything that makes the full build take six to seven months is said to sit at Tier P-SA; the full build's own milestones put Tier R at 2026-11-10 to 2026-12-08 and Tier C at 2026-12-08 to 2027-01-19 before any P-SA work | "The long-lead items of the full build — the SIEM and MDR contract, the witness, the sandbox twin, the penetration test, the five named humans — sit at Tier P-SA; the platform, Tier R and Tier C take about three of the six to seven months by the full build's own milestones (setup/README §3.4), which the POV compresses by taking no long-lead purchase" | open |
| X-52 | low | [01-hld.md](01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded) | §0.2 ("never confused with the platform decisions P1–P143 of §17"); [§17](01-hld.md#17-open-decisions) | The HLD, reviewed 2026-09-15 and citing P153–P155 in §13.2, still gives the register's range as P1–P143 | §0.2: "P1–P204". §17: add "P144–P191 were proposed by the setup procedures on 2026-09-15 and P192–P204 by the proof of value on 2026-09-16 (12 §6a, §6b); new rows append at P205" | open |
| X-53 | low | [../eve/07-build-runbook.md](../eve/07-build-runbook.md#status); README.md line 149; 01-hld.md line 13; brief/02 lines 17 and 104 | eve/07 Status paragraph; the four other locations | The pointer page refers to Eve as "she" and "her"; the set's rule is roles and they/them, and every other page of the set writes "it" for Eve. The four other locations write "his own line" and "he asked" for the administrator | eve/07: "from the day it runs … its project and evidence stores (23), its Workspace identity"; the four others: "outside that person's own line" and "the owner asked", each in its own file | fixed 2026-09-18: README.md, 01-hld.md, brief/28, brief/30, page 13, eve/07 and six wall-e pages now write "the administrator" and "it"; the objective's own "She" stays as a quotation; setup/ still carries gendered pronouns for the operator, outside this review's scope |
| X-54 | low | [setup/README.md](setup/README.md#status) | Status, paragraph "A proof-of-value set exists (added 2026-09-16)" | Lists the POV's people as "the platform owner, the operator, the second person and one engineer" (four roles), where the POV's person 1 is the platform owner and operator in one, its third hands-on person is second operator, security reviewer and blind grader, and the engineer is a fourth. Does not mention the three-day set, which the two other entry points do | "for three hands-on people (the platform owner as operator, the second person, and a third who is second operator, security reviewer and blind grader) and one engineer". Add: "A three-day build, ../3-day/README.md, hands over to the POV, not to this set; nothing it produces is evidence here either" | open |
| X-55 | low | [10-eu-ai-act.md](10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13) | §1 rows "Art. 6(3) derogation, Art. 6(4) documentation, Art. 49(2) registration" and "Harmonised standards"; [§9](10-eu-ai-act.md#9-unverified-on-2026-09-13-and-what-closes-each-item) row 4; §0 last sentence; Status block | Three rows are stale on 2026-09-18: the Omnibus kept Art. 49(2) for derogation systems (the Commission proposed deletion; Council and Parliament rejected it), which closes the §9 row in the design's favour; EN 18286 is at formal vote with no EN published and none cited, not "final approval"; the verification date is 2026-09-13 with no later line. §0 also says the residual list holds seven items where §6 holds eleven (R1–R11), and brief/24 notes the mismatch instead of the page fixing it. Merges the regulatory report's F-07, F-08 and F-09 | §1 Art. 49 row: append "Re-verified 2026-09-18: the Commission's proposal to delete Art. 49(2) for derogation systems was rejected by Council and Parliament; the obligation stands in streamlined form (Annex VIII Section B points 7 and 9 deleted)". Standards row: "EN 18286 at formal vote; no EN published; none cited in the OJ (tracker read 2026-09-18)". Close §9 row 4 with that date and source. Add "re-verified 2026-09-18" to the Status block. §0: "the eleven things". Then in [brief/24](brief/24-eu-ai-act.md#what-bulletproof-can-and-cannot-mean) replace the seven-versus-eleven sentence with "The page's residual list holds eleven items, some closed by the organisation itself; this chapter follows it." | open |
| X-56 | low | [11-tisax.md](11-tisax.md#1-tisax-on-2026-09-13-verified) | §1 row "What ISA2027 changes"; [§8.3](11-tisax.md#83-the-onboarding-procedure-as-controls) step 2; §15 row 1 | ENX's own wording gives three routes for supplier verification (a TISAX label, an equivalent third-party assessment, or an appropriate supplier audit); the page quotes two and attributes its stricter two-route rule to ISA2027. A secondary source (2026-07-17) also counts "43 revised controls" against the page's "46 controls, 44 edited" | Quote the three routes in §1. In §8.3 step 2 add: "ISA2027 also admits an appropriate supplier audit; this platform accepts it only at high protection need, never at very high — a design choice stricter than the catalogue." In §15 row 1 add "one secondary source (2026-07-17) counts 43 revised controls; the ISMS confirms the count and numbering on the redline" | open |
| X-57 | low | [brief/25-tisax.md](brief/25-tisax.md#the-record-and-its-three-signatures) | "The record and its three signatures", last sentence; "Keeping the record honest over time", second sentence | Both sentences report the disagreements X-30 and X-31 resolve; once the register and page 11 are aligned they mislead | "The security reviewer owns and signs R-01; the platform owner accepts it; the ISMS enters it." and "The record is reviewed quarterly and re-signed at each Wall-E stage transition, on a grade change and on a severity-1 credential incident." | open |
| X-58 | low | [11-tisax.md](11-tisax.md#2-the-target--label-level-scope-catalogue-p133) | §1 "Three consequences"; §2 table row "Catalogue", "Fails when" | Assumes every relevant order falls in 2027 and leaves the 2026-12-31 ISA 6 cut-off as a "fails when" case. The ISMS may renew the site's label before 2026-12-31 for its own reasons; the page should ask for that decision by a date, state the trade-off, and say what the platform's scope statement then says | Add to §2 a dated line: "By 2026-12-01 the ISMS states whether any site assessment is ordered under ISA 6 by 2026-12-31. If yes, the platform is listed out of scope (or in scope at documentation maturity only, with this page as the statement) and re-scoped at the next ISA2027 order; nothing built in 2026 can reach maturity 3." Record the trade-off (known catalogue and renewal cycle versus ISA2027's supplier-verification rule, which Google's SYN0NK result already satisfies, and its rationale-per-item rule, which the rejected-alternatives style already meets) in the §11 legal-register row for the TISAX participation terms | open |
| X-59 | low | [11-tisax.md](11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads) | §6.3 table, "Grade" column | HLD §0.2 fixes two grades and says every grading table uses those two words; the gate checklist grades row 7 "enforcement (human)", rows 11 and 12 "organisational" and row 13 "documentation". Rows 11–13 are not controls in the CP sense but the people and paper the deviation rests on, and an assessor will ask which of the two grades "enforcement (human)" is | Grade row 7 "detection (a human act on a paging class; Google-enforced two-person under multi-party approval)"; grade rows 11, 12, 13 "precondition, not a control (outside §0.2's grading)"; add one sentence above the table saying rows 11–13 are the preconditions the technical rows assume and carry no grade | open |
| X-60 | low | [3-day/code.md](3-day/code.md#3-doeractionspy) | §3 `actions.py` constants and `caller_email` | Three configuration failures open rather than close: an empty `APPROVERS` admits any human invoker as approver (`if APPROVERS and approver not in APPROVERS`); an unset `SERVICE_URL` disables the audience check (`audience=SERVICE_URL or None`), the state between the first deploy and the update; an unset `ORG_DOMAIN` makes the tenant check a tautology. Cloud Run IAM and the synthetic-prefix check still bound each, but the pattern is the one absolute 9 forbids | Refuse at start-up when `APPROVERS`, `SERVICE_URL` or `ORG_DOMAIN` is empty; either set `SERVICE_URL` on the first deploy or accept the one-minute window and say so; add a selftest case for each | open |
| X-61 | low | [3-day/code.md](3-day/code.md#6-toolsconsentpy) | §6 "Undo, and this is K4" | The K4 path is written as the robot signing in at myaccount.google.com — a robot interactive login, which detection R5 (and the design's SA-04) treats as an incident. Day 2 T2-26 already uses the Admin console path; the code page still says the other | Replace with the admin path of day-2 T2-26 (Directory > Users > the robot > Security > Connected applications > Remove, or `tokens.delete` from an admin credential), and add "never by signing in as the robot" | open |
| X-62 | low | [3-day/day-2-the-doer.md](3-day/day-2-the-doer.md#t2-3-two-security-keys-counted-by-eye) | §T2-3, §T2-4, §T2-17, §T2-26 | The robot signs in interactively four times on day 2. Each is a login event by a watched service identity and fires R5 to person B, yet no step tells person B to expect and acknowledge it; T1-9a now seeds the doer's address into the `service_identity` watchlist, which makes the four pages certain. pov/07 PW-0.2 announces exactly this | Add to T2-1: announce the four expected robot sign-ins; add to T2-13's PROVES "and one `service_identity_login` finding per robot sign-in of T2-3 and T2-4, acknowledged against the run log" | open |
| X-63 | low | [3-day/day-2-the-doer.md](3-day/day-2-the-doer.md#t2-18-deploy-steward-actions-the-only-credential-holder) | §T2-18 PROVES | Nothing ties the running service to the code person B reviewed at T2-14: `--source` builds on Cloud Build from person A's working directory, and the run log never holds the image digest or a hash of `actions.py`. "What runs is what was reviewed" is then a statement of trust in person A | Add to T2-18 PROVES: `sha256sum actions.py` from person B's checkout of the commit T2-14 initialled, and `gcloud run services describe … --format='value(spec.template.spec.containers[0].image)'` (a digest), both written into the run log; T3-19 and the hand-over cite them | open |
| X-64 | low | [3-day/README.md §6.1](3-day/README.md#61-corrections-made-on-2026-09-18); day-1; day-2; day-3; code.md | The twenty-eight rows of §6.1 (six large, twenty-two smaller) | On 2026-09-17 the three-day README listed corrections owed to the day files and the code — one audit vocabulary; the doer's foundation and OAuth client built on day 1; Eve's three tables matching the code; one Directory-scoped credential with an HTTP status check; one spelling of every name; twenty-two smaller rows from a staging unit for `eve-reader@`'s keys to a one-millisecond watermark step and a single string literal in the scorecard — and none was carried. Summarised here in one row, not listed | Carried on 2026-09-18: all twenty-eight rows applied in the day files and code.md; the three timetables recomputed (1,140 allocated minutes per person, 210 in reserve; 38 person-hours and 7); every command, flag and console path a correction introduced checked against Google's documentation on 2026-09-18 and cited in the day file's sources; the four Python files compile and `actions.py --selftest` prints twelve results with no failure in a scratch environment. §6.1 is now a dated record and §6 row 11 requires the corrected revision. The later step verifies and closes | open (carried 2026-09-18 in the day files and code.md; the verification of the twenty-eight rows is still to be done) |
| X-65 | low | pitch/pitch.md | Line 133, the link to 3-day/README.md §6.1 | Outside the three-day set: the link targets the old heading anchor and the sentence says the corrections are owed and the run does not fit without them, which is no longer true after 2026-09-18 | Point the link at `../3-day/README.md#61-corrections-made-on-2026-09-18` and restate the sentence: the corrections were made on 2026-09-18 and the unwind (README §10, day-3 T3-19 a to m) now reaches both OAuth clients, their credentials and the controller's read-only credential | open |

Counts on 2026-09-18, after the fixes: 65 rows — 4 high, 35 medium, 26 low; 38 fixed (all four
high, 34 medium), 27 open (X-33 and the 26 low rows), none rejected. Eleven inputs were merged
into other rows and are named in the row that carries them.

## 7. What is sound

A sponsor may rely on these; the review found each right in more than one place and contradicted
nowhere.

- **The objective is answered requirement by requirement, and the refusals are written down.**
  Every one of R1–R16 has a section in the HLD and a chapter in the brief, and the two agree on
  which readings are qualified or declined and why. A sponsor is not being sold an outcome the
  design cannot deliver.
- **The decided premise is handled the same way everywhere.** Wall-E's Super Admin (P33) is the
  owner's decision on every page that mentions it, and no page re-argues it; each says how it is
  contained. The decision record, the register row, the TISAX deviation (P136) and risk row R-01
  point at one another, and the record lists what the choice costs without softening.
- **The loss table is written before the compensations.** [01-hld "What this reverses and what it
  costs"](01-hld.md#what-this-reverses-and-what-it-costs) lists what Super Admin removes — the
  Workspace-side gate, the bounded blast radius, Eve's structural independence, least privilege as
  a property — before it lists what compensates. A design that names its own losses first is one
  an assessor can work with.
- **Enforced and detected are two words, used as two words.** Every control table on the design
  pages carries a grade, a mechanism, an owner, a verification and a failure mode; the three open
  Google facts are named and excluded from the safety case; the PAB is graded as no fence for
  Cloud Run invoke and the gateway binding as detection until a throwaway engine has been refused.
- **The standing constraints are not loosened anywhere.** The HLD states eight; brief/05 restates
  them one for one; pages 02–11 and the register defer to the HLD; the three build sets restate
  them more strictly, never more loosely.
- **The credential story is complete and bounded.** No key anywhere; two OAuth clients, two
  services, one reader per secret, `cloud-platform` in neither and CI-checked; refresh tokens
  never backed up; K4 revokes, K5 suspends, K6 removes the role and is the only switch that
  survives a minted token; the sixty-minute access-token residue is carried as an assumption and
  every path measures it rather than quoting it.
- **The action services cannot approve themselves and the model cannot approve anything.** No
  human, group or domain is ever on `run.invoker`; the agent principal is refused by IAP on both
  surfaces and by code on every approval endpoint; setup/33 proves each with a command whose
  failure stops the sitting.
- **Eve's control path is model-free by absence, not by discipline.** No model client in the image
  (CI-scanned), no `aiplatform.*` permission on either identity, a project-level service denial on
  `EVE_PROJECT`, and a reporting path that holds no signer, no invoker and no secret and whose
  output nothing on the verdict path reads.
- **Silence is a halt.** `log_pipeline_silent` sets `no_autonomous` fleet-wide and `halt_all` on
  the super-admin lane; the absence alarm lives in a tenant the administrators do not administer;
  Eve's return clears nothing.
- **The grant is a gate, not a phase.** setup/38 makes the second human's multi-party approval the
  enforceable refusal, parses twenty-one green lines with freshness rules, rehearses recovery
  before turning self-recovery off, announces the expected alerts, and writes down what K6 does not
  undo.
- **The gate cannot be fooled by a smaller path.** The proof of value never sets a bare full-build
  record name; setup/38 needs those names and refuses on any *tbd* and without five named humans;
  the three-day set cannot write a line the resume rule would read. "A record never satisfies a
  gate whose conditions it lacks" is enforced by construction.
- **The one ordering rule is real in all three paths.** Eve is live before any doer exists, and
  each path proves it with a page Eve sent about the doer's own creation or role assignment.
- **Nothing is torn down, and every cut names its return.** P204's no-teardown clause binds the
  full build; every one of the twenty-seven three-day cuts and sixteen POV deviations names the
  file and step that puts the piece back, and every cited step id exists.
- **The smaller paths refuse the sentences that would mislead.** Both ban "Wall-E is safe as a
  super admin", "Eve is independent" and "Model Armor blocked the injection"; both keep every
  agent out of Super Admin; both say a clause whose record is missing is struck, not softened.
  The three-day doer's policy chain — halt read per request, catalogue, tenant, synthetic prefix,
  protected principal, write-ahead intent row, live read, exact-match OU, forced dry run that
  refuses a valid approval, nonce bound to the request hash with expiry, single use and
  not-the-requester — is correctly ordered and its offline results are the right ones.
- **Mo cannot move anything.** No credential, no invoker, no git credential; a drop box that
  rejects any diff outside the path allowlist before CI sees it; every number re-derived by an
  identity Mo cannot reach.
- **Every regulatory date and quotation re-verifies.** The Act's dates, the Omnibus's dates, the
  Art. 50 guidelines' date, the Art. 6 draft's dates, the Annex III 4(b) text, the ISA versions
  and their transition rule, Google's TISAX identifiers and regions — all correct on 2026-09-18.
  The one open legal question closed in the design's favour.
- **Classification is a gate, not a page.** A row without a class, a signed purpose and a
  registration cannot reach production; the reclassification triggers are armed against dated
  events, not an annual review that would miss them. The Eve determination is engineering (a CI
  check), not argument. Art. 50 is done the only way it can be trusted, by the action service and
  a CI test. The profiling boundary is built, not argued.
- **TISAX is treated as it is:** a site's label, not a platform's; Google as an external IT service
  with a per-control split; the public compliance page rejected as evidence in favour of the ENX
  result share; separation of duties as a counted minimum the gate enforces; and the sentence a
  sponsor should hear first — about half of the page is documentation written now, the other half
  is controls that do not exist and cannot be claimed by writing.

## 8. What must change before the documents are handed on

The short list as it stood on the morning of 2026-09-18 named 34 rows; by the end of the day all
but one were fixed in the pages they name (§6). What is still open before the documents are
handed on:

1. **Before HR and the works council:** nothing remains of the original list; X-03, X-28, X-29,
   X-32 and X-37 were fixed on 2026-09-18.
2. **Before the security team:** X-33, part done. The three-day halt is now written by a human
   identity only in code.md §3 and the "takes two people" claim is gone from day-2 T2-25, but
   day-1 T1-12a still binds `secretVersionAdder` to `steward-actions@`, day-2 T2-11 still
   verifies both roles, and day-2 T2-25 and day-3's drill step 9 still pull K0 through the
   endpoint code.md removed. Until those three pages match code.md, the service being halted can
   still clear its own K0. Also owed from X-25: 07 §6.3 SG-07 does not yet name the two
   approval-surface identities.
3. **Before compliance and regulation:** X-55, X-56, X-57, X-58 (low, open). Page 10 must carry
   the 2026-09-18 re-verification (Art. 49(2) retained; EN 18286 at formal vote) and "eleven"
   residual items; page 11 must quote ISA2027's three routes and ask the ISMS for the ISA 6
   decision by 2026-12-01; brief/25's two sentences on the R-01 owner and the review cadence now
   contradict the aligned register and page 11 and must change.
4. **Before enterprise architecture:** the follow-ons of fixed rows. The P205 row for the R3
   reading (X-08) is still to be appended in 12-open-decisions.md; code.md §5 and day-3 T3-2
   still create Mo's views in `MO_PROJECT.mo` rather than `platform_metrics_views` (X-21, owed in
   3-day/README §6.1); brief/29 and brief/16 still record the four/five Tier X difference the
   HLD no longer carries (X-13).
5. **Before the board:** X-42 (low, open): the executive summary's staffing minimum at the grant
   must read five, or four with a dated ISMS exception. Also owed from X-22: pov/09 §6 still
   quotes the 85 to 90 person-days and the two thirteens without `Assumption:`.

Everything else still open is low: the stale counts in the brief (X-40, X-41, X-43), the
constraint lists (X-44, X-45, X-46, X-47), the three-day pointers, names and code hardening
(X-48 to X-50, X-60 to X-63), the pronouns (X-53), the POV and setup README wording (X-51,
X-54), the grade column of 11 §6.3 (X-59), the verification of the twenty-eight carried
three-day rows (X-64) and the pitch link (X-65).

## Sources

Regulatory and standards sources read on 2026-09-18 for §5 and for findings X-27, X-28, X-32,
X-55, X-56 and X-58. Google documentation pages read on 2026-09-18 for the three-day corrections
are listed in each day file's own sources section and are not repeated here.

- artificialintelligenceact.eu/article/113/ — Art. 113 as amended: 2025-02-02 (Chapters I–II; Art.
  5(1)(ba), (bb) from 2026-12-02), 2025-08-02, 2026-08-02 general, 2027-12-02 (Art. 6(2) and Annex
  III); the Annex I date rendered as 2027-08-02 by the summariser and retained as 2028-08-02 on
  the strength of the three sources below. Read 2026-09-18.
- labs.cloudsecurityalliance.org — "EU AI Act's High-Risk Deadline: Deferred, Not Cancelled": OJ
  2026-07-24, in force 2026-07-27, Annex III 2027-12-02, Annex I 2028-08-02. Read 2026-09-18.
- klgates.com — "EU Digital Omnibus on AI Enters Into Force" (2026-07-31); whitecase.com — "EU AI
  Omnibus enters into force, amending the AI Act"; gibsondunn.com — the Omnibus agreement: Annex
  III 2027-12-02, Annex I 2028-08-02, Art. 4 softened, Art. 5 new prohibitions with transition to
  2026-12-02, Art. 50 unchanged with the 50(2) grace to 2026-12-02. Read 2026-09-18.
- artificialintelligenceact.eu/ai-act-explorer/digital-omnibus/ — Art. 4 replaced; Art. 5 new bans
  2026-12-02; Art. 50(2) transition; Annex VIII Section B points 7 and 9 deleted; Art. 6(1a)–(1c)
  on safety components; Art. 27 simplified for deployers using DPIAs. Read 2026-09-18.
- insideprivacy.com; whitecase.com (the Digital Omnibus deal); aiactblog.nl; kla.digital — Art.
  49(2) registration for Art. 6(3) systems: proposed for deletion, rejected by Council and
  Parliament, retained in streamlined form. Read 2026-09-18.
- artificialintelligenceact.eu/article/6/ — Art. 6(3)(a)–(d), the profiling subparagraph, Art.
  6(4), 6(5); artificialintelligenceact.eu/annex/3/ — Annex III 4(a), 4(b) verbatim;
  artificialintelligenceact.eu/article/49/ — Art. 49(2) "before placing on the market or putting
  into service". Read 2026-09-18.
- digital-strategy.ec.europa.eu — "Draft Commission guidelines on the classification of high-risk
  AI systems" (2026-05-19, still titled draft); dlapiper.com, osborneclarke.com, freshfields.com —
  consultation closed 2026-07-23, final expected end 2026. Read 2026-09-18.
- twobirds.com, faegredrinker.com, paulweiss.com — final Art. 50 guidelines adopted 2026-07-20, 51
  pages, applying from 2026-08-02. Read 2026-09-18.
- ai-act-standards.com — the JTC 21 tracker: no deliverable at publication stage, one at formal
  vote, none cited in the OJ; prEN 18286. cencenelec.eu for the Q4 2026 target as previously
  recorded; jtc21.eu unreachable on 2026-09-18. Read 2026-09-18.
- gdpr-info.eu/art-88-gdpr/ — Art. 88(1)–(2) verbatim. Read 2026-09-18.
- portal.enx.com/en-us/TISAX/downloads/ — ISA 6.0.3 (2024-04-25); ISA2027 (2026-07-01) "basis of
  TISAX Assessments ordered in 2027"; "assessments ordered before 2027-01-01 can still be
  performed with ISA6"; redline 2026-08-07. enx.com/en-US/news/isa2027/ — "ISA2027 will therefore
  apply to all TISAX Assessments ordered from January 1st, 2027 onwards"; supplier verification
  "through a TISAX label, an equivalent third-party assessment, or an appropriate supplier audit";
  the annual cycle. dqsglobal.com (2026-07-17) — "43 revised controls". Read 2026-09-18.
- cloud.google.com/security/compliance/tisax — the participant statement, SYN0NK, ATTRRN-1 and
  ATTRRN-2, the labels, "for data classified as secret", `europe-west1` among the labelled regions,
  no service named; read through its indexed text on 2026-09-18, the page itself not rendering in
  full.
- docusnap.com, cis-cert.com, goleadingit.com, schellman.com — labels, the AL2/AL3 mapping, the
  maturity scale. Read 2026-09-18.

## Related

- [README.md](README.md) — the map of this set
- [13-setup-procedure-review.md](13-setup-procedure-review.md) — the review of the setup
  procedures on 2026-09-15, whose form this page follows
- [12-open-decisions.md](12-open-decisions.md) — the register of record; X-08 asks for a new row
  at P205
- [3-day/README.md §6.1](3-day/README.md#61-corrections-made-on-2026-09-18) — the corrections
  carried on 2026-09-18, summarised in X-64
- [../../decisions/README.md](../../decisions/README.md) — the two decision records checked in §1
