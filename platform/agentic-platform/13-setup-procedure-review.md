# 13. Setup procedure review

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-15
- Maturity: review, complete 2026-09-15. It records the review of the manual setup procedures
  for the agentic platform and its three agents, held on 2026-09-15. It asked one question:
  what goes wrong if the platform owner builds everything by hand, alone at first, following
  the written procedures. It changes no procedure. Every fix below is still to be made in the
  page it names.
- Procedures reviewed:
  - Platform: the ten design pages [01](01-hld.md) to [12](12-open-decisions.md),
    [../project-topology.md](../project-topology.md) §7, and the one step list that exists,
    [03 §16](03-gemini-enterprise-environment.md#16-runbook-bringing-the-environment-to-baseline)
    GE-0 to GE-14.
  - Wall-E: [../wall-e/PREREQUISITES.md](../wall-e/PREREQUISITES.md) (460 lines),
    [../wall-e/SETUP.md](../wall-e/SETUP.md) (3,014 lines, 21 phases),
    [../wall-e/setup/README.md](../wall-e/setup/README.md),
    [../wall-e/setup/walle.env.example](../wall-e/setup/walle.env.example) and
    [../wall-e/setup/walle_setup.py](../wall-e/setup/walle_setup.py) (10,013 lines; its offline
    self-test passes 220 of 220 against stubs).
  - Eve: [../eve/07-build-runbook.md](../eve/07-build-runbook.md) (2,182 lines).
  - Mo: [../mo/07-build-runbook.md](../mo/07-build-runbook.md) (1,744 lines).
- How the review was run:
  - Nine finders read the procedures against the design and Google's documentation. Their
    findings were merged into one register of 213 findings, S001 to S213.
  - Each of the 155 blocking and major findings then went to two adversarial lenses. The facts
    lens re-checked the text and Google's pages. The context lens looked for places where the
    procedures already handle the problem.
  - Outcome rules:
    - **refuted**: both lenses refuted the finding.
    - **stands**: neither lens refuted it.
    - **partially stands**: one lens refuted it. The claim is narrowed to what survived.
    - Where the lenses corrected the severity differently, the higher of the two severities
      that did not refute the finding is kept.
  - The 58 minor findings were not adversarially verified.
  - A completeness critic then found three areas that had only been recorded as "no
    procedure". A second round examined them: the sandbox tenant and the witness organisation,
    the Gemini Enterprise app side, and region, quota and billing. Its 46 findings are **not
    verified**. They are marked as such in §4.6 and counted apart.
  - Working files are outside the wiki, under `.agent-work/setup-review/` relative to the
    working directory: `register.json`, `verdicts-facts-*.json`, `verdicts-context-*.json`,
    `find-extra-*.json`, `master-order.md` and `completeness-gaps.json`.
- Severity:
  - **blocking**: following the procedure as written fails, cannot be done by the stated
    person, or produces an unsafe or irreversible outcome.
  - **major**: the procedure completes but builds something wrong, insecure, or out of order
    with another procedure.
  - **minor**: clarity, a missing verify, or an avoidable trap.
- Counts on 2026-09-15:

  | Set | Blocking | Major | Minor | Refuted |
  |---|---|---|---|---|
  | Verified register, standing or partially standing | **43** | **99** | 12 (downgraded by the lenses) | 1 |
  | Register minor findings, not verified | — | — | 58 | — |
  | Second round, not verified | 11 | 23 | 12 | — |

  All 43 blocking findings stand in full. Of the 99 major findings, 2 stand only partially
  (S072, S089). Of the 12 downgraded minor findings, 4 stand only partially (S023, S060,
  S068, S129).

## 1. Verdict

**The owner can start today, but not by building anything.**

**What to start today.** These are the items that have no dependency and long lead times:
- stage 1, decisions: close the decisions in §2 stage 1 and send the data-protection question
  (D7);
- stage 2, the toil baseline: start [Mo-0](../mo/07-build-runbook.md)'s four-week
  measurement, which cannot be taken later;
- stage 3, purchases: start them in lead-time order;
- stage 4, the Gemini Enterprise inventory: run
  [03 §16](03-gemini-enterprise-environment.md#16-runbook-bringing-the-environment-to-baseline)
  GE-0 and GE-1 read-only, extended as X-GE-01 to X-GE-03 ask.

**Do not create a folder, project, policy or account in any procedure yet.** There is no
executable platform procedure (S001, verified on 2026-09-15). Across the eleven platform pages
and the topology, every code fence is a mermaid diagram except two illustrative YAML schemas
in 05. No bash, gcloud or HCL block exists, and no `.tf` file exists. 03 §16 is a table of
steps. Topology §7.4 to §7.6 name only who makes what.

The consequences:
- No procedure makes the organisation bootstrap, the folder tree, the factory, PAM, the
  organisation-policy baseline, central logging, the shared registry, SCC, the SIEM, K7, the
  witness or the sandbox tenant.
- Every agent procedure assumes they exist. Its "manual fallbacks" would build projects under
  the wrong parent, with standing Owner, no PAM, no drift job, no deny policy and no central
  logging.
- The Tier R gate therefore cannot open. The super-admin grant can never be made in the way
  the design requires.

**What must be fixed or written before each stage:**

| Before | What must exist | Findings |
|---|---|---|
| Stage 5 (the first GCP resource) | A platform bootstrap runbook (§3, M1), with the billing account and its roles, and the logging storage location set on the folder before the first project | S001, S002, S019, S051, X-RQB-03, X-RQB-05 |
| Stage 17 (the first change to the live Gemini Enterprise app) | 03 §16 rewritten as a live-app-safe procedure. As written, GE-3 to GE-10 can delete chat history, remove today's users' access, cut services the app uses, and route all app traffic through a default-deny gateway with no documented unbind | S047, S049, S053, X-GE-01 to X-GE-04 |
| Stage 21 (Wall-E on production) | The 13 blocking Wall-E defects fixed in SETUP.md and walle_setup.py, a model pinned on the eu endpoint, and the gate split so that a project can be created before the grant | S008, S009, S011, S015 to S026, S105, X-RQB-01 |
| Stage 24 (Eve v0) and stage 30 (Eve's observe-and-report sitting) | Eve's schemas, SQL and service code committed. Eve Phases 1 and 7 to 10b corrected | S027 to S041 |
| Stage 25 (Mo) | Mo's inputs committed, the dataset names made agent-neutral, and Mo-1 rewritten as a factory call | S042 to S046, S144 |
| Stage 32 and stage 33 (the gate) | The sandbox-twin and witness procedures written, after their design contradictions are resolved | S004, S005, S039, X-ORG-01, X-ORG-02, X-ORG-05 to X-ORG-07 |

**The five most consequential problems:**
1. **No platform bootstrap procedure exists** (S001, S002, S003). Every agent runbook stops at
   its first project (SETUP Phase 6, Eve Phase 1, Mo-1). The only way forward is a fallback
   that builds exactly what the tier model forbids.
2. **The super-admin gate cannot go green as designed.**
   - The gate refuses the register row that creates the project whose services the gate lines
     test (S008).
   - Eve's G-4 needs robot activity that only exists after the grant (S039).
   - No procedure builds the sandbox twin or the witness (S004, S005).
   - The second round, not verified, finds the design itself unbuildable in four places:
     - an Internal OAuth client in the organisation's project refuses a sandbox robot
       (org_internal, X-ORG-01);
     - the sandbox tenant's audit logs never reach the organisation's sinks (X-ORG-02);
     - the witness excludes tenant super admins, yet names the second human, a tenant super
       admin, as its administrator (X-ORG-05);
     - a 26-hour absence alarm exceeds Cloud Monitoring's 23.5-hour maximum (X-ORG-06).
3. **The Gemini Enterprise baseline would damage the live, tenant-wide app** (second round,
   not verified, but irreversible):
   - GE-6 sets 30-day retention, which deletes older chats with no rollback (X-GE-01);
   - GE-5 removes today's access grants before anyone is in `ge-users@` (X-GE-02);
   - GE-4's service allow-list refuses services the app may use (X-GE-03);
   - GE-10's binding routes all traffic through a default-deny gateway, has no dry-run mode on
     the binding, and has no documented unbind (X-GE-04).
4. **Wall-E's security-critical steps do not run, or build the wrong thing:**
   - the engine IAM lock uses a gcloud group that does not exist (S024);
   - the script's baseline role breaks the two-principal engine lock while verify still
     passes (S105);
   - `walle-actions-super` has no deploy commands and its secrets are never created (S020,
     S021);
   - no phase builds the approval surface G14 needs (S009);
   - on the Agent Identity path, the agent is refused by its own action service (S016).
5. **Eve and Mo are specifications of code and inputs that do not exist yet**, and no model is
   pinned.
   - Eve's schemas, twelve SQL files and all service code are missing (S028, S029, S030).
     Mo's 20 schemas, 19 SQL files and two images are missing (S043).
   - No procedure names a Gemini model. The `europe-west1` endpoint serves only the Gemini 2.5
     family, retiring 2026-10-20. Every successor is served only on `global`, `eu` or `us`
     (X-RQB-01, not verified).

## 2. The master setup order

The sequence runs from an empty Cloud organisation to Mo's first merged proposal.
- It corrects `.agent-work/setup-review/master-order.md` with the verified findings and with
  the second-round findings (marked "2nd round").
- **NO PROCEDURE** means that no executable steps exist today.
- "Gate" is the tier gate of [01-hld.md](01-hld.md) §0.4, or the milestone the stage makes
  true.

Two reminders on the order:
- The grant comes before Wall-E Stage 0 ([11-tisax.md](11-tisax.md) §6.3).
- Tier C opens before Tier R in the HLD. In practice, however, GE-2 needs the factory's
  `tenant-app` module, so the Gemini Enterprise baseline cannot run before the factory exists
  (S047, S050).

### Part A — Before anything is built (can start on 2026-09-15)

| # | Stage | Procedure and phase | Preconditions | Gate opened |
|---|---|---|---|---|
| 1 | Decisions and people. Wall-E D1–D8 and D10–D12; Eve E-1, E-14, E-16 and decision 44 or CC-33 (S035); Mo M-1, M-5 and the agent-neutral dataset names (S144); P13 retention ceiling; P14 closed on domain, edition, billing and the two witness administrators (X-ORG-05, X-ORG-08, X-ORG-09); P10 SIEM; P11 SCC payer (X-RQB-04); P22 moved to before Tier R (S051); P31 billing account (X-RQB-05); decision 6 model pin (X-RQB-01); decision 29 moved to before the grant (X-ORG-14). Send D7 in week one | PREREQUISITES §1; eve/07 Prerequisites; mo/07 Prerequisites; 12-open-decisions. **No single platform checklist** (S083) | none | written, dated answers |
| 2 | Toil baseline, four consecutive weeks | mo/07 Mo-0 (= PREREQUISITES D12) | the top three admin tasks picked | Wall-E Phase 1 may start. Mo-0 cannot be redone later (S084) |
| 3 | Buy and collect, longest lead time first: SecOps and MDR; penetration test; SCC Premium contract or payer; sandbox Workspace tenant (edition Enterprise Standard or higher, domain, seats, two super admins); witness Cloud Identity tenant with its own domain, billing account and support tier; Chrome Enterprise Premium; billing sub-account, roles and project quota; Gemini Enterprise licences and Gmail-bearing seats; hardware keys (robot twins add eight) | PREREQUISITES §3.1 and §9 (an unsorted list). **NO PROCEDURE** for the sorted list (X-RQB-09, X-ORG-04) | 1, budget | items in hand |
| 4 | Gemini Enterprise inventory, read-only: edition, licences, location (stop unless `eu`), CMEK, current retention, project and app IAM policies and the "Manage users" export, enabled services, inherited roles, data stores and connectors, per-OU service status and Workspace data access | 03 §16 GE-0, GE-1 (steps without commands; extend as X-GE-01, X-GE-02, X-GE-03, X-GE-10, X-GE-18, X-GE-19) | D8 | facts recorded before any GE write |

### Part B — Platform bootstrap to Tier R

| # | Stage | Procedure and phase | Preconditions | Gate opened |
|---|---|---|---|---|
| 5 | Billing: account named, Billing Account User and Costs Manager granted to the bootstrap operator (with an expiry) and later to `factory-apply@`, currency checked, project-link quota raised to at least 20 | **NO PROCEDURE** (X-RQB-05) | 1, 3 | projects can be linked |
| 6 | Organisation bootstrap: Organization Administrator and Folder Creator to `sa-1-admin@` under a dated exception; break-glass `brk-gcp-1@` and `brk-gcp-2@`; security groups `platform-owners@`, `platform-security@`, `platform-approvers@`, `ge-admins@`, `eve-owners@`; `factory-groups@` with Groups Admin; human super-admin roster `sa-1-admin@`/`sa-2-admin@` with keys | **NO PROCEDURE** (S002, S049, S079). Design: 04 §2.4, §5.1, §7.1, §8.2 | 1, 3, 5 | first privileged principals exist |
| 7 | Witness W-1 and W-2: tenant, two IT security super admins, billing account, project, `eve_mirror`, retention bucket, and the records step, all before the first key enrolment | **NO PROCEDURE** (S005). Moved earlier by X-ORG-11 and X-ORG-14 (2nd round). Owner: IT security | P14, 3 | custody records have a home |
| 8 | Folder tree of 02 §2.1, numeric ids recorded. Cloud Logging and Observability default storage location set on `fld-agentic-platform` **before the first project** | **NO PROCEDURE** (S001; X-RQB-03, 2nd round) | 6 | tier folder ids exist |
| 9 | SCC Premium activated with EU residency, before any location policy | **NO PROCEDURE** (S003; X-RQB-04, 2nd round) | P11, 6 | Tier C detection desk |
| 10 | Core projects `CICD_PROJECT`, `CORE_PROJECT`, `LOGGING_PROJECT`, `KMS_PROJECT`, `VALIDATOR_PROJECT`: state bucket, WIF pool and `factory-apply@`, Artifact Registry, Cloud Build, Binary Authorization attestor, `platform-drift@`, validator custodian | **NO PROCEDURE** (S001, S051). Design: 02 §3.4, §5; 09 §1–§2 | 8, P22 | factory identities exist |
| 11 | PAM catalogue: `ent-platform-policy`, `ent-folder-admin`, `ent-project-repair`, `ent-factory-singleton`, `ent-ge-admin` (no-approval at Tier C, X-GE-12), `ent-project-move`, `ent-k7-*`, and an organisation-scoped sink entitlement (S142) | **NO PROCEDURE** (S002). Design: 04 §5.2 | 6, 8, 10 | every later privileged step has a lawful path |
| 12 | Organisation-policy baseline B1–B22 and the allow-lists. Dry run only where Google supports it (custom and managed constraints, `gcp.restrictServiceUsage`, `gcp.restrictEndpointUsage`, the two TLS constraints); legacy constraints applied first on a nonprod folder. Deny policies with the documented principal form (S072); PAB | **NO PROCEDURE** (S001 as corrected by the facts lens). Design: 02 §4; 04 §3–§4 | 8, 9, 11 | folder baseline (Tier R item) |
| 13 | Central logging: Workspace "Share data with Google Cloud services" (today only in SETUP Phase 5, S159); S-org, S-folder, fan-out sinks; locked buckets after P13; `platform_logs_views`; Data Access audit config; billing export enabled by the billing administrator | **NO PROCEDURE** except the Workspace toggle. Design: 08 §3–§5 | 10, 12, P13 | central logging (Tier R item) |
| 14 | Register repository and CI checks, shared Agent Registry in `CORE_PROJECT`, drift and reconciliation jobs | **NO PROCEDURE** (S001, S048). Design: 05 §2–§7 | 10, P22 | shared registry (Tier R item) |
| 15 | Factory code: `agent-project`, `verifier-project`, `improver-project`, `tenant-app`, `revoke`, and the undefined `platform-core` (S048); negative test | **NO PROCEDURE**. Design: 01 §3.2; 02 §3.2–§3.4 | 10–14 | **Tier R open**. No page records or checks this gate (S085) |
| 16 | Nonprod spikes (perimeter, principal-set spelling, cross-project registry) and K7: `k7-executor` built, `canary-r`, first drill per nonprod tier folder | **NO PROCEDURE** (S052). Design: 04 §9; 06 §4.3 | 12, 15 | K7 proven |

### Part C — Gemini Enterprise baseline (Tier C)

| # | Stage | Procedure and phase | Preconditions | Gate opened |
|---|---|---|---|---|
| 17 | GE-2 `tenant-app` import. GE-3 move, only after the allow-list is the union of enabled services and the design list and has run in dry run (X-GE-03), and after inherited roles are re-granted | 03 §16 GE-2, GE-3 (no commands) | 4, 11, 12, 15 | `GEMINI_PROJECT` in `fld-gemini-enterprise` |
| 18 | GE-4 to GE-9: constraints with exact `enforcedProjects` forms (X-GE-10), CMEK as its own decided step (X-GE-05), groups filled **before** grants are removed (X-GE-02), no retention reduction (X-GE-01), Model Armor template in `eu` (X-GE-14), the unreachable-template test only on the throwaway app (X-GE-08), registry and gateway import | 03 §16 GE-4 to GE-9 (rewrite first) | 13, 17 | front door configured |
| 19 | GE-10 binding, only after the authz extension in DRY_RUN, the import of every existing agent and endpoint, and a proven unbind on a throwaway app (X-GE-04). GE-11 enforce not before the first agent row is admitted | 03 §16 GE-10, GE-11 | 18 | — |
| 20 | GE-13, GE-14: detections re-scoped to SCC at Tier C (S050), penetration test moved to Tier P | 03 §16 GE-13, GE-14 | 9, 19 | **Tier C gate** |

### Part D — Agent infrastructure, before the grant

| # | Stage | Procedure and phase | Preconditions | Gate opened |
|---|---|---|---|---|
| 21 | Wall-E Workspace side: Phase 1; Phase 3 without the tenant-wide self-recovery and multi-party-approval rows (S012) and without creating `eve@` (S088); Phase 4; Phase 5 as a verify | SETUP Phases 1, 3, 4, 5; `./walle workspace` | 2, 3, 6, `WALLE_REPO` initialised (S163) | robot exists, hardened, no role |
| 22 | Register rows and factory runs: Mo (`improver-project`), Eve (`verifier-project`), Wall-E (`agent-project` under `ent-factory-singleton`, two named approvers, S011). The P-SA row merges with `gate_checklist` pending (S008) | SETUP Phase 6. Eve Phase 1 and Mo-1 step 0 must first be rewritten as factory calls (S027, S042) | Tier R, 11, 20 | `WALLE_PROJECT`, `EVE_PROJECT`, `MO_PROJECT` |
| 23 | Wall-E Phases 7 and 8 (nine audit tables, S093; both writer entries, S109) | SETUP Phases 7–8; `./walle gcp` | 22, schemas | Wall-E data plane |
| 24 | Eve S0: Phase 2, then a `walle gcp` re-run, then Phases 3, 4, 5 | eve/07 Phases 2–5 (need committed schemas and SQL, S028, S029) | 23 | Eve v0 queries |
| 25 | Mo S0: Mo-1 to Mo-5, with a `walle gcp` re-run after Mo-2 | mo/07 Mo-1 to Mo-5 (need inputs, S043; fixes S044, S045) | 23, 13 | Mo metrics |
| 26 | Wall-E Phase 9: both clients, one consent sitting. Tenant reads return 403 until stage 34 | SETUP Phase 9; `./walle consent`, `consent --super` (secrets S020) | 21, 23 | tokens stored |
| 27 | Wall-E 12b spike, then 12c, then Phase 10 (both services, S021; built in CICD with Binary Authorization, S006, S022), then Phase 11 (platform sink, S094), then Phase 12 (engine created once, with identity type, gateways and model client location `eu`: S025, S075, X-RQB-01), then 12b step 7, then 13b. Approval surfaces | SETUP Phases 10–13b; `./walle armor`, `spike`, `deploy`, `registry`. Approval surface **NO PROCEDURE** (S009) | 26, 12, 13, 14, service code | Wall-E services deployed, fail-closed |
| 28 | SIEM, MDR, pager; SA-01 to SA-09 and SG-01 to SG-07 with fixtures | **NO PROCEDURE** (S003) | 13, P10 | G2 (Tier P) |
| 29 | Witness W-3 (managed member constraint, then legacy reset: X-ORG-10) after `eve-export@` exists; W-4 alarms after the first heartbeat (X-ORG-06) | **NO PROCEDURE** (S005, S061) | 7, 30 (step 4) | witness live |
| 30 | Eve's observe-and-report sitting: Phase 7 (organisation sink via PAM, S142), then Phase 8 (`eve@` created outside the enforced OU, S038; consent command, S040), then Phase 9 (grants S032, S033; bucket gated, S041), then a `walle deploy` re-run, then Phase 10 and Phase 10b (export job, S037) | eve/07 Phases 7–10b; SETUP Phase 10 re-run | 24, 27, 28, decision 44 or CC-33, Eve code (S030) | Eve observe-and-report live |
| 31 | Mo-6, then a `walle deploy` re-run | mo/07 Mo-6 (harness S007) | 25, 27 | Mo read endpoints |
| 32 | Sandbox tenant and P-SA twin: sandbox Workspace side; sandbox-organisation sinks (X-ORG-02); twin clients External, In production and Trusted (X-ORG-01); nonprod factory runs; denial suite G10, K6 drill G11, band-B dry run G14; Eve drill G-5 and G-7 | **NO PROCEDURE** (S004). SETUP l.383: "how that copy is built is *tbd*" | 3, 22, 27, 30 patterns | G10, G11, G14 evidence |
| 33 | Human and organisational gate lines G3 to G18, plus the Tier W rows and a K7 P-SA drill younger than 30 days (S085) | SETUP Phase 2 gate table (a checklist); 11 §6.3 | 16, 28, 29, 32; four or five named humans (X-ORG-05) | **P-SA tier gate** |

### Part E — The grant, Stage 0, and after

| # | Stage | Procedure and phase | Preconditions | Gate opened |
|---|---|---|---|---|
| 34 | Super-admin grant: roster committed, G1–G18 signed and parsed (S092), Super Admin assigned under multi-party approval | SETUP Phase 2 step 5; `./walle workspace` M2C (split into its own subcommand, S014) | 33 | **the grant** |
| 35 | Post-grant verification (S122); Phases 12 to 17 on production, non-mutating tests only (S091); interim sinks deleted; GE-11 enforced once Wall-E's row is admitted | SETUP Phases 9 (verify), 12–17 | 34, 19 | Stage 0 checklist green |
| 36 | Stage 0 record, schedules resumed, verify strict (S101) | SETUP Phase 18; `./walle stage0` | 35 | **Wall-E Stage 0** |
| 37 | Stage 1: approval surface, works council, Mo-7 (watermark writer, S152) and Mo-8 | wall-e/05 §7; mo/07 Mo-7, Mo-8. Approval surface **NO PROCEDURE** | 36 | Stage 1 |
| 38 | Stage 2: threshold calibration (E-18) | eve/05 S2 (no runbook phase) | 37 | S2 |
| 39 | Mo-9 at S2 exit: drop box, CI ingestion identity from the `CICD_PROJECT` pool, validator recompute, branch protection on both repositories; then the first real bundle, pull request, validator, two reviewers, merge | mo/07 Mo-9 (S046); first merge **NO PROCEDURE** | 10, 30, 37 | **Mo's first merged proposal** |
| 40 | Eve S3 entry: invariant-class halt and demote live | eve/07 Phases 8–12 (verify) | 38 | Eve's first enforcing window |

```mermaid
flowchart TD
  S1["1 Decisions and people"] --> S3["3 Buy by lead time"]
  S2["2 Mo-0 toil baseline, 4 weeks"] --> S21
  S1 --> S4["4 GE-0/GE-1 read-only inventory"]
  S3 --> S5["5 Billing account and roles (NO PROCEDURE)"]
  S5 --> S6["6 Organisation bootstrap and roster (NO PROCEDURE)"]
  S1 --> S7["7 Witness W-1/W-2 (NO PROCEDURE)"]
  S6 --> S8["8 Folders and log location (NO PROCEDURE)"]
  S6 --> S9["9 SCC Premium (NO PROCEDURE)"]
  S8 --> S10["10 Core projects and WIF (NO PROCEDURE)"]
  S10 --> S11["11 PAM catalogue (NO PROCEDURE)"]
  S9 --> S12["12 Org-policy baseline and deny (NO PROCEDURE)"]
  S11 --> S12
  S12 --> S13["13 Central logging (NO PROCEDURE)"]
  S10 --> S14["14 Register and shared registry (NO PROCEDURE)"]
  S13 --> S15["15 Factory code: Tier R open (NO PROCEDURE)"]
  S14 --> S15
  S15 --> S16["16 Spikes and K7 drill (NO PROCEDURE)"]
  S4 --> S17["17 GE-2/GE-3 import and move"]
  S15 --> S17
  S17 --> S18["18 GE-4 to GE-9"]
  S18 --> S19["19 GE-10 dry run after throwaway spike"]
  S19 --> S20["20 GE-13/GE-14: Tier C gate"]
  S6 --> S21["21 Wall-E Workspace Phases 1, 3, 4, 5"]
  S20 --> S22["22 Factory runs: Mo, Eve, Wall-E"]
  S22 --> S23["23 Wall-E Phases 7-8"]
  S23 --> S24["24 Eve S0 Phases 2-5"]
  S23 --> S25["25 Mo S0 Mo-1 to Mo-5"]
  S21 --> S26["26 Wall-E Phase 9 consent"]
  S23 --> S26
  S26 --> S27["27 Wall-E Phases 10-13b and approval surface"]
  S13 --> S28["28 SIEM, MDR, pager (NO PROCEDURE)"]
  S24 --> S30["30 Eve observe-and-report sitting"]
  S27 --> S30
  S28 --> S30
  S30 --> S29["29 Witness W-3/W-4 (NO PROCEDURE)"]
  S7 --> S29
  S25 --> S31["31 Mo-6"]
  S27 --> S31
  S30 --> S32["32 Sandbox tenant and P-SA twin (NO PROCEDURE)"]
  S16 --> S33["33 Gate lines G1-G18: P-SA gate"]
  S29 --> S33
  S32 --> S33
  S33 --> S34["34 Super-admin grant"]
  S34 --> S35["35 Post-grant verification"]
  S35 --> S36["36 Wall-E Stage 0"]
  S36 --> S37["37 Stage 1, Mo-7/Mo-8"]
  S37 --> S38["38 Stage 2"]
  S38 --> S39["39 Mo-9: first merged proposal"]
  S38 --> S40["40 Eve S3: first enforcing window"]
```

**Cross-runbook re-run points.** Each is missing from the runbook that needs it (S070, S107).
- `walle gcp` after:
  - Eve Phase 2 (`eve-v0@`);
  - Mo-2 (`mo-metrics@`);
  - Eve 10b step 4 (`eve-export@`, whose `walle_audit` READER has no maker, S054);
  - creation of the validator custodian identity (S055).
- `walle deploy` after Eve Phase 9 (`eve-controller@`, `eve-verifier@`, `eve-console@`) and
  after Mo-6 (`mo-analyst@`).
- Eve Phase 9's `ladder/` binding: after the ladder publisher is named (S130) and before the
  retention lock.

## 3. What is missing entirely

| # | Missing procedure | What it must contain | Design that already specifies it | Findings |
|---|---|---|---|---|
| M1 | **Platform bootstrap runbook** (to be written as a new page, for example `14-platform-bootstrap-runbook.md`, and listed in [../../runbooks/README.md](../../runbooks/README.md) and [README.md](README.md) "Reading order for a builder") | Phases B0 to B12 in the order of §2 stages 5–16. Each phase needs commands or a Terraform module path, a verify, a rollback or an "irreversible" banner, an owner, hands-on and elapsed time, and a resume checkpoint. Contents: billing account and roles; organisation roles under a dated exception; break-glass; control groups and `factory-groups@`; folder tree and logging default location; core projects, WIF and state; PAM catalogue including an organisation sink entitlement; B1–B22 with dry run only where supported; deny policies and PAB; central logging and the billing export; register repository and shared registry; factory modules including `platform-core`; negative test; a Tier R gate record | [01-hld.md](01-hld.md) §0.4, §3.2; [02-landing-zone-and-tiers.md](02-landing-zone-and-tiers.md) §2–§4; [04-identity-and-privileged-access.md](04-identity-and-privileged-access.md) §2.4, §3–§5, §7.1; [05-registry-and-autonomy-contract.md](05-registry-and-autonomy-contract.md) §2–§7; [08-data-logging-retention-sovereignty.md](08-data-logging-retention-sovereignty.md) §3–§5; [09-supply-chain-secrets-recovery.md](09-supply-chain-secrets-recovery.md) §1–§2 | S001, S002, S019, S048, S049, S051, S083, S085, S142, S159, X-RQB-03, X-RQB-05 |
| M2 | **Platform prerequisites and build order**: one entry page | A PREREQUISITES-shaped table for the platform (requirement, why, verify, needed by, holder, lead time). One ordered table of sittings across platform, GE, Wall-E, Eve and Mo (§2 of this page). "Who must be present" per phase. One build-log and evidence location mapped to E-xx and TISAX ids | [01-hld.md](01-hld.md) §0.3–§0.5; [11-tisax.md](11-tisax.md) §6.3; `.agent-work/setup-review/master-order.md` | S066, S067, S068, S069, S083, S084, X-RQB-09 |
| M3 | **SCC Premium activation and SIEM, MDR and pager onboarding** | Tier C: SCC Premium activation with EU residency and a notification config, with the payer decided (the organisation-level pay-as-you-go option bills every project in the organisation). Tier P: SIEM feed from `LOGGING_PROJECT`, SA-01 to SA-09 and SG-01 to SG-07 with CI fixtures, a 24x7 acknowledgement test, pager routing, and the SIEM principal allowed to run `k7-executor` | [07-monitoring-detection-incident-response.md](07-monitoring-detection-incident-response.md) §2–§4, §6; [01-hld.md](01-hld.md) §0.3, §0.5 | S003, S050, X-RQB-04, X-ORG-15 |
| M4 | **K7 fleet kill switch build and drill** | Build and attest `k7-executor`; commit `k7/*`; both entitlements; `canary-r`; a dry-run drill, then an enforced drill, on each nonprod tier folder including `fld-agents-p-sa-nonprod`; times recorded; a gate line for a drill younger than 30 days | [04-identity-and-privileged-access.md](04-identity-and-privileged-access.md) §9; [01-hld.md](01-hld.md) §11.4 | S052, S085 |
| M5 | **Witness organisation runbook** (owner IT security) | W-1: separately registered domain outside the organisation's DNS, tenant, two super admins who are not tenant super admins, self-recovery off, own billing account. W-2: project, `eve_mirror`, locked bucket, Access Transparency and Access Approval. W-3: managed member constraint admitting only `eve-export@`, then legacy reset, then rows 32–33. W-4: hourly heartbeat and 6-hourly export alarms within 23.5 hours; channels; billing-status alarm. A records step for custody, rota and drill records | [../project-topology.md](../project-topology.md) §7.5; [01-hld.md](01-hld.md) §13.2; [../eve/07-build-runbook.md](../eve/07-build-runbook.md) Phase 10b; [12-open-decisions.md](12-open-decisions.md) P14 | S005, S061, X-ORG-05 to X-ORG-12, X-RQB-06 |
| M6 | **Sandbox tenant and P-SA nonprod twin runbook** | Purchase: edition, domain, seats, two sandbox super admins, eight keys. Sandbox Workspace side (SETUP Phases 1, 3, 4, 5 against the sandbox). Sandbox-organisation sinks to nonprod destinations. Twin OAuth clients External, In production and Trusted in the sandbox. Nonprod factory runs under the P1-pending rule. Wall-E Phases 10–17 and Eve Phases 7–10b against the twin. Drills G10, G11, G14, G-5 and G-7, re-run so they are under 30 days old at the grant | [02-landing-zone-and-tiers.md](02-landing-zone-and-tiers.md) §1.3, §3.5; [../wall-e/SETUP.md](../wall-e/SETUP.md) Phase 2; [../eve/05-stages.md](../eve/05-stages.md) G-4 to G-7 | S004, S039, X-ORG-01 to X-ORG-04, X-ORG-13 |
| M7 | **Wall-E approval surfaces** (band A and `walle-approvals-super`) | IAP-fronted Cloud Run services, their service accounts, audiences, canonical-request-hash binding, invoker on the action services, and their email addresses in the generated allowlists | `wall-e/03-lld.md` approval surfaces; SETUP §7.10; PREREQUISITES §10 item 17 | S009, S076 |
| M8 | **Validator custodian** | `VALIDATOR_PROJECT` identity; `grades_eve` with an insert-only grader role; READER on `walle_audit` (row 21) and for `mo-metrics@` (rows 45–46) | [../project-topology.md](../project-topology.md) rows 21, 45–46; [01-hld.md](01-hld.md) §0.3 | S055 |
| M9 | **Mo's first merged proposal** | CI ingestion identity from the `CICD_PROJECT` pool; ingestion workflow; branch protection on the Wall-E and `eve/config` repositories; the first passing bundle through the validator to merge | [../mo/04-artefacts-and-proposals.md](../mo/04-artefacts-and-proposals.md); [12-open-decisions.md](12-open-decisions.md) P22 | S046, S153, S206 |
| M10 | **Eve advisor path** (deferred on purpose until P34 and P19) | Factory `verifier-project` run for `EVE_ADVISOR_PROJECT`, `eve-advisor@`, a project Model Armor floor, authorised views, rows 30–31 | [../project-topology.md](../project-topology.md) §2 rows 30–31 | S129 (minor), X-RQB-08 |
| M11 | **Inputs the runbooks execute but nobody has written** | The Terraform factory repository; Wall-E service code and images; Eve schemas (9), SQL (12), `thresholds.yaml`, reconciler and console code, CI gates; Mo schemas (20), SQL (19), reporter and narrator images, `gates.yaml` | the LLD pages of each agent; brief `29-roadmap-and-cost.md` (engineer-day estimates) | S001, S028, S029, S030, S043 |

## 4. Findings that stand

The findings are grouped by the procedure the register assigned. Within each group, blocking
findings come first. "Stands" means both lenses upheld the finding. "Partial" gives the claim
as narrowed by the lens that refuted part of it. Line numbers are those of the files on
2026-09-15.

### 4.1 Platform

| Id | Severity | Location | What goes wrong | Fix |
|---|---|---|---|---|
| S001 | blocking | agentic-platform 00–12, README l.6–12 and l.108–139; project-topology §7.4–§7.6; 03 §16 | No executable platform procedure exists (no bash, gcloud or HCL block, no `.tf`). No page makes the factory, folder tree, B1–B22, core projects, sinks, shared registry, deny policy, PAB, PAM, K7, drift job, SCC, SIEM, break-glass or witness. SETUP Phase 6, Eve Phase 1 and Mo-1 stop, or take fallbacks that keep Tier R red for good | Write M1 before any agent runbook runs, and mark SETUP Phase 6, Eve Phase 1 and Mo-1 step 0 not runnable until it exists. Correction from the facts lens: dry run is supported only for custom constraints, managed constraints, `gcp.restrictServiceUsage`, `gcp.restrictEndpointUsage` and the two TLS constraints. Legacy constraints such as `gcp.resourceLocations` and `iam.allowedPolicyMemberDomains` cannot be dry-run, so apply them on a nonprod folder first |
| S002 | blocking | 02 §3.4 l.462, §2.2 l.321–322; 04 §5.1 l.377, §5.2 l.389–401, §2.4 l.166; P69 | No procedure performs the first privileged acts: Organization Administrator, Folder Creator, PAM admin, the control groups that PAM entitlements name, the break-glass accounts, the first folder. A folder-scoped entitlement cannot exist before its folder, so "through PAM" is impossible for the first step | Bootstrap phase B0 under a dated standing exception: organisation roles to `sa-1-admin@` and break-glass accounts; control groups as security groups; PAM admin to `platform-owners@`; exception withdrawn once PAM exists |
| S003 | blocking | 01 §0.4 P row l.160, §0.3; 07 §2–§3, §6.2–§6.3; P10; SETUP G2 l.394, §6.1 | Nothing buys, provisions or connects the SIEM, MDR, pager or `LOGGING_PROJECT` feed, and nothing activates SCC Premium and its notification config. G2 cannot go green, so the grant is blocked, and auto-K7 has no caller | Close P10. Write M3: SCC activation and notification config at Tier C; SIEM feed, rule deployment with fixtures, acknowledgement test and pager routing at Tier P |
| S047 | major | 03 §16 l.445–470; README l.126–127 | The one existing platform procedure needs the factory from GE-2 onward, contrary to its own index. Its console steps give no path, no values and no place to record the GE-0 facts, so Tier C cannot be opened from the text | Correct README step 7. Expand each GE row into a sub-procedure with console path, exact values, command, PAM holder, time and evidence id. See also X-GE-01 to X-GE-22 |
| S048 | major | topology §7.6 l.543–546 rows 36, 40, 41, 44; Mo-2 l.492–496; 01 §3.2; 02 §3.3 | `platform-core` is not one of the five factory modules. `platform_logs_views` readers, the drift job's securityReviewer role and the SDP row are made by nobody, so Mo metric 9/9b and the drift job have no working grant | Add `platform-core` to 01 §3.2 and 02 §3.3 with its resources, or assign rows 36, 40, 41, 44 to named M1 phases with command and verify |
| S049 | major | 03 §16 GE-5 l.458; 04 §2.4 l.166, l.170–173 | `ge-admins@`, the requester group of `ent-ge-admin`, and `factory-groups@` have no maker. GE-5's PAM check fails, so GE-6, GE-7 and GE-10 cannot run | GE-5: `ge-admins@` created by hand by a super admin. Other `ge-*` groups by `factory-groups@`. A bootstrap step creates `factory-groups@` with Groups Admin |
| S050 | major | 03 §16 header l.447–449, GE-2 l.455, GE-7 l.460, GE-13 l.466, GE-14 l.467; 01 §0.4 C, §0.3; P10 | The Tier C gate needs a SIEM, a security reviewer and SCC Premium, which arrive only at Tier P/W or have no procedure. Tier C cannot close before Tier P. README tells the builder §16 needs no factory | Re-scope GE-13 at Tier C to SCC findings routed with a test finding. Move SIEM rules and the penetration test to Tier P. Add SCC activation. Correct README l.127 |
| S051 | major | P22 l.184 (gate Tier W); 02 P35, P36 l.383, l.433–442; B19 l.616 | The factory WIF provider needs the git host's issuer and repository ids, but P22 (git host) is due only at Tier W. Tier R cannot open on schedule | Move P22's gate to before Tier R |
| S052 | major | 04 §9.2–§9.6 l.730–811; 01 §11.4; SETUP §5 K7 l.2645, l.2661, §6.1 | Nothing builds `k7-executor`, its files, `canary-r`, the entitlements or the first drill, and no gate list checks K7. The fleet kill switch is silently absent at the grant | Write M4 and a gate line "K7 drill on the P-SA folder younger than 30 days" |
| S053 | major | 03 §16 GE-3, GE-4 | The live tenant-wide app inherits the baseline, deny policy, floor and `restrictServiceUsage` in one move with no dry run. A hand edit of a folder IAM policy can drop folder bindings for every child project | Before GE-3, list effective constraints and run the folder policy as dryRunSpec where supported. For GE-4, save the policy, merge only auditConfigs keeping etag and bindings, show the diff, apply under PAM, keep the file as rollback |

### 4.2 Cross-procedure

| Id | Severity | Location | What goes wrong | Fix |
|---|---|---|---|---|
| S004 | blocking | SETUP Phase 2 l.383, G1, G10, G11, G14 l.393–406; eve/05 G-5, G-7; Eve 10b drill l.1598 | No procedure creates the sandbox tenant, the robot twin, the `fld-agents-p-sa-nonprod` Wall-E build or the `fld-controllers-nonprod` Eve build. Four gate lines and two Eve rows can never go green. Substituting the production sandbox OU gives records the gate refuses, or drills K6 on the production robot | Write M6 (with the design corrections of X-ORG-01 to X-ORG-04) |
| S005 | blocking | topology §7.5 W-1..W-4; Eve 10b l.1426–1430, l.1466–1470, l.1508–1518; P14; SETUP G1, G11, G18 | No procedure creates `org-witness`, its project, `eve_mirror`, the locked bucket, rows 32–33, the domain restriction, channels, absence alarm, export job or heartbeat. G1 and 11 §6.3 row 5 stay red | Close P14. Write M5 (with X-ORG-05 to X-ORG-12) |
| S006 | blocking | Eve Phase 9 l.911–915, Phase 10 l.1246, l.1303–1312; SETUP Phase 10 l.1225–1239, 11.2 l.1370–1379; 02 B18 l.615, §4.2 l.645, CC-3 l.668 | Under the folder baseline, Eve Phase 9's API enablement (`cloudbuild`, `artifactregistry`) is refused by `restrictServiceUsage`. Every `gcloud run deploy` without `--binary-authorization=default` is refused. Builds in agent projects contradict "builds run in `CICD_PROJECT`" | Remove `cloudbuild` and `artifactregistry` from Eve Phase 9. Build and attest in `CICD_PROJECT` and deploy by digest. Add `--binary-authorization=default` and the Direct VPC flags to every deploy |
| S007 | blocking | Mo l.1102 (Mo-6 verify), l.1630–1652 `as_sa`, l.1666–1677 `call_actions`, l.1614 MD-9 | The negative tests impersonate `walle-actions@`, `eve-controller@` and other accounts. No runbook grants token-creator, and the platform forbids it on those accounts. Calls fail at `getAccessToken`, curl sends an empty bearer and gets 401, which is neither the expected 200 nor 403 | Run negative BigQuery tests as jobs executing as each identity, or use a time-boxed PAM token-creator on `mo-*` accounts only. For forbidden accounts use Policy Troubleshooter or testIamPermissions |
| S008 | blocking | 02 §1.3 P1 l.174, P4; SETUP Phase 2 l.389, Phase 6 step 1 l.567; 11 §6.3 l.371–373 | Circular: `WALLE_PROJECT` cannot be created until every gate line is green, and G10, G12, G13 and G14 need `WALLE_PROJECT`'s services deployed. The Phase 6 pull request never merges | Split the gate. The register row merges with `gate_checklist` pending and privilege `super_admin_pending`. The gate refuses only the Super Admin assignment and the Stage 0 record. X-ORG-13: the alternative "twin first" fix loops, so do not use it |
| S054 | major | SETUP Phase 7 l.846–860; `CROSS_PROJECT_DATASET_READERS` l.~324–330; SETUP §1.7; Eve 10b step 4 l.1508–1509 | Topology row 34 (READER for `eve-export@` on `walle_audit`) is made by nobody. The daily export and the witness push of Wall-E's audit fail with accessDenied | Add `SA_EVE_EXPORT` to §1.7, the reader line to Phase 7, the row to the script table and to Phase 15 verify 1 |
| S055 | major | SETUP Phase 7 l.859–860; `walle_setup.py` l.324; Mo-9 l.1426–1431; Mo-1, Mo-4 | Row 21 (validator READER) and rows 45–46 (`grades_eve`) have no maker. The validator recompute cannot read `walle_audit`, and Mo computes Eve's numbers without the source rule | Write M8. Replace the comment in Phase 7 with a gated reader line. Add the `grades_eve` source and assertion to Mo-4 |
| S056 | major | SETUP l.2004–2020 (Phase 13); topology l.503–521; 03 §16 GE-5, GE-12 | Registration is a hand-made console object that reconciliation treats as unmatched. The share uses standing rights. Wall-E's endpoint is absent from `gemini-registry` and `gemini-egress`, so after GE-11 the verify fails or the gateway is left in dry run | Rewrite Phase 13 as GE-12 for Wall-E: register row `publish_to_gemini`, CI import and registration, share by `ge-admins@` via PAM. Keep the console path only as a dated fallback |
| S057 | major | SETUP 13b step 5 l.2104, step 4 l.2078–2089; Eve and Mo runbooks | The gateway command resolves a per-project registry that cannot exist (`agentregistry` is not allowed in the tier). Wall-E's card meta line is never written. Eve, eve-advisor and Mo have no register row before they exist in a project | Use `$CORE_PROJECT` in 13b and move the local registry to a fallback. Verify the entry's meta line. Add "merge the register row and manifest" as the first step of Eve 07 and Mo 07 |
| S058 | major | Eve Phase 3 l.403–418; SETUP Phase 7 l.781, l.793; Eve Phase 11 step 4 l.1843–1847 | Eve mirrors at most six `walle_audit` tables and never names `generic_requests`, so the off-project copy lacks the super-admin generic lane and EVE-20 cannot tell a missing band-B row from a gap | One mirror table per source table (nine), one transfer each, and a verify that the counts match |
| S059 | major | PREREQUISITES §4.1 l.138–150, §11 l.450; Eve l.80, l.642–645; Mo l.100; 04 §5.2 l.404–408 | The prerequisites leave the builder with standing organisation-level policy, deny and sink administration, the levers of K7 and evidence silencing, with no approval or expiry. This is a TISAX privilege-review finding on day one | Name the PAM entitlement per phase. Keep standing roles only for the pre-bootstrap fallback, as a dated exception removed before the drift job runs |
| S061 | major | Eve 10b step 4 l.1508–1514, l.2093 | A customer id in `iam.allowedPolicyMemberDomains` admits every identity and service account of the tenant, so the witness admits the whole tenant | Use `iam.managed.allowedPolicyMembers` with `eve-export@` only. X-ORG-10 (unverified) adds that the legacy default on a new organisation must also be reset |
| S062 | major | Mo l.491–496, l.542–553, l.786–797, l.809–810, env l.120–146 | Metrics 9 and 9b read `walle_workspace_logs`, an interim dataset deleted before Wall-E Stage 1. From then on their transfers fail hourly, and `${LOGGING_PROJECT}` expands empty | Export `LOGGING_PROJECT`. Read `platform_logs_views.walle_workspace_logs` from the start. Add a hand-off verify for row 40 |
| S063 | major | Mo-6 l.988–1003, Mo-7 l.1184–1188; 02 l.330, l.416 | `deny-improvers` forbids run.invoker for improver principals on credential holders, but Mo-6 grants `mo-analyst@` invoker on `walle-actions`. Once the factory applies the deny, MD-3 and plan-hash recompute get 403. The two pages cannot both be executed | Decide in the register: read plan hashes from `walle_audit.plans` and drop the binding, or record a named exception on decision 48 |
| S064 | major | Mo-8 step 2 l.1296–1304, l.1316, l.1702; `wiki/_sync/wiki_sync.py` l.62, l.168–179 | Artefacts committed under `platform/wall-e/mo/` and `platform/eve/mo/` are pushed to Google Drive on the next `wiki push`, widening readers of personal-data-derived content. The runbook says this step has no rollback | Use underscore-prefixed directories, or add an exclusion list with a self-test. Verify with a dry-run push |
| S065 | major | Mo-11 l.1527–1528 | `aiplatform` and `modelarmor` are added to the `fld-improvers` allow-list only at S4 by a dated PR. Run before it, the enable is refused, and the runbook neither names nor gates on the PR | Precondition: the PR is merged. Verify the effective `restrictServiceUsage` |
| S066 | major | runbooks/README l.5–7; agentic-platform README l.108–139; wall-e README l.65–66; SETUP l.20; Eve l.21–27; Mo l.29–35 | There is no single entry point and no master sequence across four interleaved procedures. Starting at SETUP Phase 1 misses the baseline, the factory and the cross-runbook re-runs | Write M2 (build-order page, from §2 of this page). Replace SETUP l.20 "standalone" with a link to it |
| S067 | major | SETUP l.348, l.518, l.604, l.1154, l.409, l.450, l.2726, l.2472, l.2623, l.2500; PREREQUISITES l.16; Eve; Mo | Evidence (decisions, stage snapshot tag, drill and custody records, tabletop) has no defined home and no mapping to E-xx or TISAX ids. The witness and evidence buckets do not exist during the build | One build-log location per runbook, an interim custody location, and a "Record" line per phase with E-xx, control id and path |
| S069 | major | SETUP l.450, l.1101, l.569, l.418, l.2659–2660; setup/README l.246–248; Eve l.2071–2090 | Steps the owner cannot do alone are not marked: key B custodian, envelope witness, two singleton approvers, multi-party approval, K5 and K6 rota, M2A in one sitting, IT security's witness steps | Add "Who must be present" to every phase and a Who column to the M-step and Eve manual tables |
| S070 | major | SETUP Phase 7 l.829–861, Phase 10 l.1266–1271, Phase 6 l.570; Eve Phase 2, Phase 9; Mo | The three runbooks depend on each other. The manual bash has no PENDING handling, so foreign grants error. A factory apply that includes Eve and Mo principals fails its bindings. The context lens notes that SETUP l.829 and Phase 15 do state a PENDING re-run for the script path, so the gap is the manual path and the other two runbooks | State the interleaving (§2 stages 22–31) in each runbook. Wrap each foreign grant in an existence check that prints PENDING |
| S071 | major | SETUP l.581 and every later command without `--project` (Phases 7, 8.2, 10, 11) | `gcloud config set project` is global to the machine. After an Eve session that set `EVE_PROJECT`, Wall-E's Firestore, topics, queue, secrets and services are created in `EVE_PROJECT`, silently | Export `CLOUDSDK_CORE_PROJECT` in §1.7 and add `--project="$PROJECT"` to every command |
| S072 | major (partial) | SETUP 12b step 7 l.1804–1832; §6.1 l.2752 | Narrowed claim: with no platform deny policy, the fallback is the only path. It still uses three permission names the text itself calls unchecked, and a principal string `principalSet://agents.global.org-${ORG_ID}.system.id.goog/*` documented nowhere. Google's IAM principals page says deny policies do not support agent identity sets. A rejected or empty deny policy leaves the invariants unenforced, and the §6.1 box demands folder policy entries. Refuted by the context lens: the denyAdmin contradiction (PREREQUISITES l.145 covers it) and the §6.1 wording | Copy R1–R6 from 04 §3. Use the deny form `principal://agents.global.org-${ORG_ID}.system.id.goog/resources/aiplatform/projects/${PROJECT_NUMBER}`. Prove it with a denied call and Policy Troubleshooter. Apply the same spelling correction to 04 §3 and the factory. Let §6.1 accept a proven fallback with a dated exception |
| S073 | major | SETUP 12c step 7 l.1977–1990 | Google says a project floor overrides a conflicting folder floor. "A stricter project floor wins" is false, so any project floor written by Eve or Mo replaces the folder floor. Wall-E's manual project floor sets no filters and no enforcement | State Google's rule. Give the full project floor command with filters, enforcement and `--vertex-ai-enforcement-type` |
| S074 | major | SETUP Phase 13b l.2048–2139 | Neither 13b path runs for one person with no factory, no `CORE_PROJECT` and no CI identity. The two IAP YAML files are never written on the manual path, and `AGENT_PRINCIPAL` is unset on the service-account branch. The context lens notes that `walle_setup.py` generates the YAML files, so the manual path is what fails | Mark 13b not executable until the platform exists and outside Stage 0, or make the fallback runnable by the operator under PAM with inline YAML |

### 4.3 Wall-E

| Id | Severity | Location | What goes wrong | Fix |
|---|---|---|---|---|
| S009 | blocking | SETUP G14 l.406 vs §7.10 l.2983–2993; `walle_setup.py` `SUPER_ENV_NAMES`, `phase_10_super` | `/v1/generic/{id}/approve` accepts only the `walle-approvals-super` IAP surface, which no phase builds. No band-B request can be approved or dry-run, G14 cannot go green, and operator halts on the super lane have no carrier | Write M7 as a SETUP phase between Phase 10 and the gate |
| S010 | blocking | SETUP l.3, l.383, l.387–410, l.2713; Eve l.968–985 | The Stage 0 that SETUP promises is unreachable from any written procedure: no sandbox twin, no approval surface, no SIEM, witness or penetration test procedure, and Eve's G1 sitting stops at Phase 9. One lens rated it major because SETUP says the build stops at the gate; the misleading end state and the missing twin procedure remain | Restate SETUP as two milestones, "Stage 0-pre" (reachable by the owner and the key B custodian) and "Stage 0" (after the gate). Add a gate tracker per G line with owner, procedure link or "no procedure yet", lead time and evidence |
| S011 | blocking | SETUP Phase 6 steps 3–4 l.569–570; 04 §5.2 l.400; 01 §0.3 | The owner cannot approve the `ent-factory-singleton` grant alone: it needs two approvers, one a security reviewer who does not exist before Tier W. The fallback is allowed only while the factory does not exist, so once it exists the build is stuck | State the two approvers in Phase 6 and PREREQUISITES §2 and order Phase 6 after their appointment, or define a dated no-approval variant for `fld-agents-p-sa-nonprod` only |
| S015 | blocking | setup/README l.47–50; `cmd_spike` l.5340–5344; `cmd_deploy` l.5628–5634; `phase_12_agent` | `walle spike` needs `walle-actions` deployed, which only `walle deploy` does, and that also creates the production engine with an immutable identity type before any spike result. A failed spike forces an engine recreate and rebinding | Add `walle deploy --phase 10` (or `walle actions`). Order: deploy phase 10, spike, rollback 12b, deploy. Refuse `AGENT_IDENTITY` without a passing spike file |
| S016 | blocking | `actions_env_pairs` l.4006–4069; `phase_12b_identity` l.5236–5240; `super_env_pairs` l.4071–4100 | Under the default Agent Identity mode, the engine's token carries the agent principal, not `walle-agent@`, so `/v1/execute` refuses the agent as `foreign_actor`. Phases 12, 13, 14 and 17 fail as if the application were broken | After binding, read the spike claim and update `EXEC_CALLER_ALLOWLIST` on both services. Refuse to continue without claims. Add as 12b step 6b with a verify |
| S017 | blocking | `phase_12b_identity` before `lock_engine_iam` l.4734–4735, l.5242–5247; `ensure_deny_policy` l.5146–5188 | The deny policy needs `roles/iam.denyAdmin` at the organisation, which preflight does not test. When the create fails, the subcommand stops after the engine exists and the agent holds `expressUser` and invoker, but before the two-principal lock. The context lens refuted the "unsupported permission names" part | Call `lock_engine_iam` right after engine creation. Create the project deny policy only with an explicit flag and only when the folder policy is absent |
| S018 | blocking | `check_engine_principals` l.7356–7390; `cmd_verify` l.8890–8944; `cmd_stage0` l.9737–9741; `ensure_project` l.2875–2885 | On the manual path the creator holds `roles/owner`, so `walle verify` reports the engine lock broken forever and `walle stage0` refuses. Removing Owner breaks the script's own later reads, since no PAM entitlement replaces it | Replace the creator's Owner with a narrow custom bundle without `reasoningEngines.query`, or accept a recorded Owner exception in the check on the fallback path only |
| S019 | blocking | SETUP l.580, §1.7 l.247, l.561–573, §6.1 l.2753 | Nothing creates `fld-agentic-platform`, `fld-agents-p-sa-prod`, `CICD_PROJECT`, `factory-apply@` or the PAM entitlements, so the factory path cannot be followed. §1.7's comment says all projects sit under `FOLDER_ID`. The context lens notes that PREREQUISITES §7.2 gives the `WALLE_FOLDER_ID` lookup, but the folder it looks up does not exist | Make M1 a stated precondition of Phase 6. Add `WALLE_FOLDER_ID` to SETUP §1.6 and §1.7 and correct the `FOLDER_ID` comment |
| S020 | blocking | SETUP 8.2 l.948–971, Phase 9 step 3 l.1118–1121, l.1134–1141, Phase 10 l.1296 | `walle-super-oauth-client` and `walle-super-refresh-token` are never created or granted by the manual path. Phase 9 step 3 fails with NOT_FOUND mid-consent, with the robot signed in and the key out of the safe | Create all five secrets in 8.2. Grant the two super secrets to `walle-actions-super@` only |
| S021 | blocking | SETUP Phase 10 l.1296 | `walle-actions-super` has no build, deploy, environment list or invoker loop in SETUP. G10, G12 and G13 can never go green by hand, and Phase 10 verify and rollback cover one service only | Add the full block: build, `gcloud run deploy walle-actions-super` with the 13 variables of `super_env_pairs`, invokers per 03-lld, `SUPER_ACTIONS_URL` export, verify and rollback |
| S022 | blocking | SETUP Phase 10 l.1225–1227, Phase 11 l.1370 | `gcloud builds submit` without flags stages source in a US multi-region bucket, which B1 (`in:eu-locations`) refuses. New projects' default build identity is the Compute default service account, which does not exist while Compute is disabled | Build in `CICD_PROJECT` (S006), or add a build service account, `--region`, `--default-buckets-behavior=regional-user-owned-bucket` and `--service-account` |
| S024 | blocking | SETUP l.1650–1653, l.1701–1702, l.1727, l.1785, l.1836 | `gcloud … reasoning-engines` does not exist in GA, beta or alpha. The engine two-principal lock, the "exactly one engine" check and the rollback cannot run. The script already uses REST | Replace the four forms with the REST `setIamPolicy`, `getIamPolicy`, list and delete calls the script uses |
| S026 | blocking | SETUP l.1536–1546, l.1573, l.1710–1711, l.709–710, l.1773 | On the service-account path the agent needs model-invoke rights. `roles/aiplatform.user` at project level would grant `reasoningEngines.query` on every engine and break the lock; without it every model turn returns 403 | Custom role `walleAgentInference` with only the model-call permissions, bound to `walle-agent@`, never `aiplatform.user`. Verify both effects |
| S105 | blocking (raised by the facts lens) | `AGENT_BASELINE_ROLES` l.445–450; l.5227–5228; `check_engine_principals` l.7359–7362; setup/README l.505–510 | `roles/aiplatform.expressUser` in the baseline confers `reasoningEngines.query`, so the agent can query itself and any engine. `engine_two_principals` still passes, because its conferring list omits that role. The lock is lost silently | Remove `expressUser` from the baseline. Detect conferring roles by included permissions. Add a self-test |
| S012 | major (from blocking) | SETUP Phase 3 l.465 (self-recovery off at top OU), l.468 (multi-party approval on); Phase 2 l.383; M2B | Both settings apply to every super admin, including the owner. With one person, a lost key is recoverable only through Google Support, and every covered change waits for a second super admin who does not exist. The context lens notes that the script applies MPA only at M2C | Move both rows into Phase 2 as gate-day steps after a "roster ready" check (two admin accounts with two keys each, sealed backup codes, the second human present, a rehearsed recovery) |
| S025 | major (from blocking) | SETUP Phase 12 l.1534–1589 before 12b l.1734, l.1759, l.1773 and 12c l.1934–1973 | In document order the production engine is created first, with a service-account identity and no gateway. 12b and 12c then need a recreate: new id, new principal, bindings lost, an orphan engine. PREREQUISITES does require the spike first, so the problem is the missing instruction at Phase 12 | State at the top of Phase 12 one sequence: 12b steps 1–3, then 12c steps 1–4, then Phase 12 with final config in one create |
| S075 | major | SETUP 13b step 5 l.2101–2128, 12c step 5 l.1973; script registry l.~6509, l.~6612 | The engine's outbound traffic never traverses `walle-egress`, so the dry-run to enforced flip governs nothing and PR3 (default-deny egress) is not delivered. The binding must exist at create time | Import `walle-egress` and its dry-run policy before the engine. Add `agent_to_anywhere_config` to the deploy. Verify `spec.agentGatewayConfig` |
| S076 | major | `phase_10_super`; SETUP l.1296; §5 K4 l.2658 | `walle-actions-super` admits neither `platform-drift@` nor the approval surface on `/v1/control/halt`, and `walle-operators-caller@` has no invoker. K4 on the broad client cannot be pulled by a human | Generate invokers and the CONTROL list from `control_invokers[]`. Make K4 reachable through the approval surface or a halt-only invoker, and write it into §5 |
| S077 | major | SETUP l.1239, l.1266–1271; script actions env | `platform-drift@` has no invoker and is not on the halt row, so reconciliation cannot halt Wall-E. The allowlists are hand-typed, not generated from the manifest. The context lens assigns the IAM half to row 36 (see S048) | Add `platform-drift@` to the loop and the halt entry. Generate env lists from `agent-manifest.yaml`. Add a Phase 15 verify |
| S078 | major | `HARD_DENIED` l.~627–744; SETUP 12c step 2b l.1897–1902 | The denial suite tests a list that differs from the signed one. `walle-owners@`, Eve client trust and spend are untested. HD-15 and HD-18 reasons are wrong. HD-10 protects sinks the platform no longer builds | Generate `HARD_DENIED` from one committed file the service also loads, align to 03-lld, retarget HD-10 |
| S079 | major | SETUP Phase 1 step 4 l.334, G3 l.395, Phase 2 step 1 l.414, Phase 3 l.446–468 | No procedure creates `sa-1-admin@` and `sa-2-admin@`, removes Super Admin from daily accounts, hardens an admin OU or commits the roster. G3 and EVE-21 fail on day one | Add Phase 1b "Privileged roster" (or M1 B0) with verify |
| S080 | major | SETUP 12c step 1 l.1851; Phase 12 l.1561–1578 | The content-log bucket (raw prompts) is created with Google-managed encryption, and CMEK can be set only at bucket creation. The engine has no CMEK key. SK-7 raises severity 2 | Create the HSM key first, grant the bucket's KMS account, create with `--cmek-kms-key-name`, add `encryption_spec` to the engine |
| S081 | major | SETUP 12c step 2 l.1864–1873, step 2b l.1886–1917 | The P-SA prompt template lacks advanced SDP with the fleet de-identify template, so the sanitize-log copy stores unmasked employee names and CI's tier diff fails | Create both templates with inspect and de-identify templates. Grant DLP roles to the Model Armor agent. Add a verify case |
| S082 | major | SETUP l.20, l.1650–1727, l.2048, l.2059, l.3; setup/README l.9–12, l.38–61, l.384–470 | Nothing says which of SETUP or the script to follow per phase. The literal path fails at Phase 12 and 13b, and mixing paths creates Eve's account twice and a different floor list and order | Add a "How to execute" table (phase, path, M-steps, who). Replace the Phase 12 gcloud forms with REST. Collapse the 13b fallback |
| S083 | major | PREREQUISITES l.1–12, l.111, l.404–413; Eve l.70–84; Mo l.96–108; 03 §16 | Prerequisites are complete only for Wall-E. No verified list exists for organisation roles, SCC, SIEM, witness tenant, sandbox tenant, break-glass or keys. The key count is wrong | Write M2 platform prerequisites. Give Eve and Mo the same table. Correct the key count |
| S085 | major | SETUP G1–G18 l.391–410, §6.1; 01 §0.4 R, W, P; 04 §9.6 l.806; Eve, Mo | Nothing checks the Tier R gate before Phase 6, Eve Phase 1 or Mo-1, nor the Tier W rows or a recent K7 drill before the grant. G1–G18 can be green while the HLD P line is not | Add G19 (Tier W rows) and G20 (K7 drill under 30 days) to SETUP and 11 §6.3. Add a "Tier R record exists" precondition to the three first phases |
| S087 | major | `walle.env.example` l.142; `operator_credentials` l.2075–2114 | A human super admin's refresh token (users, groups, roles) persists in plaintext on the laptop for the months-long build, outside key sign-in and robot detection | Default the cache to empty. If set, delete and revoke it at the end of `walle workspace`. Make verify and stage0 fail while it exists |
| S088 | major | `phase_1_accounts` l.2524–2529, `phase_2_roles` l.2788–2807, M1/M2A/M3; SETUP Phase 1 rollback l.371 | The script creates a licensed `eve@` with a tenant-wide custom admin role months before Eve's runbook fixes its privileges and hardening. Eve Phase 8 then collides with the existing account | Remove `EVE_ROBOT` from `walle workspace`. Make Eve Phase 8 the single creator, with Wall-E only reading its state |
| S089 | major (partial) | SETUP Phase 7 rollback l.898–903; `cmd_teardown` l.9458–9460; Phase 6 rollback l.735 | Narrowed claim: Phase 7 rollback and teardown delete `walle_audit` with no row check, no export check and no evidence warning. Eve's daily mirror copies only the `actions` table, not runs, plans, approvals, verifications, grades or `generic_requests`. BigQuery can undelete within the time-travel window only if no dataset of the same id was recreated, which the normal rollback-then-rebuild does. Refuted by the context lens: that Eve's mirror leaves no evidence copy at all | Refuse delete when tables have rows unless exports are confirmed and a decision record is supplied. Print "irreversible after time travel". Warn not to re-run Phase 7 until recovery is ruled out |
| S090 | major | SETUP 12b step 1 l.1742–1749, step 7 l.1821–1832, 12c step 7 l.1979–1987 | Folder policy, project deny and folder floor changes that affect other projects, possibly the live GE app, are made by one person with no PAM, approver, dry run or saved state. The persistent endpoint override redirects later regional calls | Mark these steps "platform owner under `ent-platform-policy`". On the fallback, save state, dry-run where supported, give the exact restore, unset the override |
| S091 | major | SETUP §4 l.2517–2526, l.2626; Phase 17 l.2472; G10 l.402 | The mutating fixtures in production assign admin roles, which fires SA-06 and breaks G3. A failing control turns a test into a real Super Admin write. Phase 17 names no tenant | Mutating tests only on the sandbox twin. Production runs only non-mutating tests with `no_writes` halt and an audit re-read |
| S092 | major | PREREQUISITES D13 l.60; `super_admin_grant_on_file` l.2729–2738; `cmd_workspace` l.2837–2847 | The grant is gated by the existence of a file, not by 18 dated, signed lines. D13 says G1–G11, skipping G12–G18 | D13 to G1–G18. The script parses the checklist and refuses M2C while any line is empty |
| S093 | major | `AUDIT_TABLES` l.349–356; `ensure_audit_tables` l.3292–3319; `check_audit_tables` l.7836–7862 | `walle gcp` creates six tables, not nine: `ladder_events`, `grades` and `generic_requests` are missing. Demotes and every band-B request fail their audit write, which is a hard invariant. Verify is green | `AUDIT_TABLES` to nine, with a self-test against SETUP's list |
| S094 | major | `phase_11_dispatcher` l.4342–4392 calling `phase_11_sinks` l.4395–4420; `cmd_deploy`; SETUP 11.3 l.1403–1409, §6.1 | Once `to-triggers-walle` exists, `walle deploy` adds a second organisation sink. Every trigger starts two runs (dedup keys on message id), and the sink is one HD-10 names | Add `LOGGING_PROJECT`. Detect the platform sink and create nothing. Create interim sinks only by explicit flag |
| S095 | major | `phase_10_actions` l.4250–4256; `check_run_invoker_handles` l.7731–7738; selftest l.620–630 | The script gives `group:OPERATORS` invoker on `walle-actions`, bypassing the impersonation path and its audit. Hand-built projects fail the check. The two procedures build different IAM | Remove the group invoker. Fail on any `group:` or `user:` invoker. Fix the fixture |
| S096 | major | `apply_floor_settings` l.6053–6088, called by `cmd_armor` l.6187; `armor_enforce` l.6091–6120 | `walle armor` writes the platform-owned folder floor with a role only PAM should hold, and can loosen PI confidence to HIGH for Eve, Mo and the GE app. On a factory project it overrides the project floor | Make floor writes opt-in and refused when a custom floor exists. By default read both floors and fail when either is looser |
| S097 | major | `armor_template_create_argv`, `ensure_armor_template` l.5899–5927; `ARMOR_TEMPLATES` l.486; setup/README l.473–475 | Wall-E ends Stage 0 on the generic response template without its SDP detectors, and get-or-create never replaces it. Blocked callers get Google's default error | Add the SDP keys to the env example, implement step 2b, add custom-error flags, replace a non-conforming template |
| S098 | major | `run_consent` l.3777–3800; google_auth_oauthlib 1.3.1 helpers l.147–148 | The missing and extra scope checks compare the requested list with itself, so they always pass. Granular consent can untick scopes, and a narrowed robot token is stored and pinned. Recovery is another robot sign-in with the safe keys | Compare `granted_scopes`. Refuse when absent. Add a self-test with a narrowed token response |
| S099 | major | `phase_14_forced_shadow_run` l.5541–5547; `phase_16_verification` l.6710–6716; `cmd_register` l.5758; `phase_17_actor_exclusion` l.9047; `confirm()` l.1561–1581 | With `--yes`, Phase 14's mail check is recorded as passed unread, the 90-minute absence drill resumes in one second but prints success, and check 48 proceeds with no event. Stage 0 evidence is recorded for work not done | Use `confirm_manual` (typed id, refused by `--yes`). Poll for the real incident up to 90 minutes and record its id |
| S100 | major | `phase_17_actor_exclusion` l.9034–9076; `_assert_no_robot_admin_events` l.8384–8425; SETUP Phase 17 l.2474–2490, §0.2, §6.1 | At Phase 17 no admin event can be produced through the service, so the behavioural half of actor exclusion is recorded as held with nothing seen. If an event is produced, stage0 fails for 24 hours | Specify how the event is produced (a recorded sandbox write). Return failure when nothing is seen. Accept exactly the recorded event |
| S101 | major | `cmd_stage0` l.9737–9753; `cmd_verify` l.8890–8944; `super_admin_grant_on_file` | Stage 0 opens with invariants that skipped (delete probe, invokers, log sharing) and without checking that the grant is real, so scheduled reads get 403 | In `cmd_stage0` require the grant and verify it. Treat SKIP as FAIL, listing the command that makes each check runnable |
| S103 | major | M2B l.1765–1812; M3 l.1843–1860 | The script's printed blocks omit the Admin console CAA level and the Gemini Enterprise service-off setting for the service OU, and the second activity rule (SA-02 mirror). All are G6 preconditions, and none is machine-verified | Add both settings to M2B and the second rule to M3 |
| S104 | major | `robot_credential_fields` l.8121–8143; `check_robot_credentials_scoped` l.8192–8259 | Every verify pulls the super-admin robot's refresh tokens and client secrets to the laptop and produces robot token events from a non-Cloud Run IP. It needs the human to hold secretAccessor | Expose the granted scopes on an authenticated service endpoint and compare there. Keep the laptop path behind an explicit flag in a change window |
| S106 | major | SETUP l.1239 vs Phase 10 verify l.1329–1345 | The operator token's email is `walle-operators-caller@`, which is not on the control list (only the group is). The halt smoke test gets 403 and every §5 timing is unmeasurable | Add `SA_OPS_CALLER` to `CONTROL_CALLER_ALLOWLIST` in SETUP and the script, record it in 03-lld, add a negative test |
| S107 | major | SETUP l.832–857, l.1266–1271 | Run before Eve and Mo exist, each foreign grant is refused and the bash has no PENDING handling. Run after Eve, it grants S3 identities READER at S0 | Grant only S0 principals at Phase 7, with an existence check printing PENDING. Move S3 and invoker lines to a Phase 15 re-run |
| S108 | major | SETUP Phase 8 verify 4 l.1069–1070 | The `DELETE` test runs as the operator, not `walle-actions@`. It succeeds, suggesting the control is missing, or fails for the wrong reason. The script impersonates correctly | Replace with testIamPermissions on the table as `walle-actions@`, expecting only `updateData` |
| S109 | major | `ensure_audit_writer_role` l.3497–3506; SETUP 8.4 l.1004–1016, verify 4 l.1065–1066, 8.5 l.1025, Phase 15 l.2320–2322 | By hand, `walle-actions-super@` gets no `walleAuditWriter` entry. Every band-B audit write fails, so the super service refuses all work and G10 cannot pass. The script grants both | Add the second writer entry in 8.4 and expect exactly two in verify |
| S111 | major | SETUP Phase 9 step 5 l.1133–1141, l.1099 | The bootstrap interface has no scope-list flag. Repeating it for the broad client consents to the wrong list, and scopes freeze at consent | Add `--scopes-file` with committed, hashed narrow and super lists and a typed confirmation. Write out the second invocation |
| S112 | major | SETUP Phase 11 l.1394–1398 | Token Creator is granted to the Pub/Sub service agent at project level, not on the push identity only. The context lens notes that the agent's own role already carries these permissions, so the gap is conformance with Google's narrower instruction and a flag in review | Grant on `walle-dispatcher@` only. Verify that no project-level token-creator binding exists |
| S113 | major | SETUP Phase 1 step 3 l.324, Phase 4 step 4 l.497, verify l.512 | The group's posting setting rejects or moderates Google's alert sender, so the second operator never receives the login alert. Verify passes because the alert reaches the owner directly | List individual recipients, or allow the alert sender. Require the second operator's confirmation in verify |
| S115 | major | SETUP l.1550–1589, l.1594 | `extra_packages` and the import path disagree when run from `~/Claude/wall-e`, and the printed value is the full resource name, not the id. The context lens refuted the AdkApp half: the SDK wraps a raw ADK agent itself | Align `extra_packages` with the import path. Export the id from `api_resource.name` |
| S116 | major | SETUP 12b step 3 l.1759–1771, rollback l.1838 | The spike is not executable by hand: no engine-create config, `SPIKE_PRINCIPAL` defined nowhere, no ID-token code. If completed, its invoker binding on production `walle-actions` is never removed. setup/README says step 3 is `walle spike` only | Add `deploy_spike.py` and the principal export, or make `walle spike` the only path. Remove the spike binding as a normal step |
| S117 | major | SETUP 12b verify l.1834, step 6 l.1800–1801, l.1239, tests 4, 5, 51 l.2534–2539, K3 l.2657 | Same defect as S016 on the manual path. With `walle-agent@` still bound, K3 removes a binding the agent does not use, and tests 4, 5 and 51 test the wrong identity | Update the allowlist in 12b step 6. K3 and the tests use `AGENT_PRINCIPAL` |
| S118 | major | SETUP 12c step 2 l.1859–1884, 2b l.1906–1916, step 7 l.1979–1988, l.1996 | Regional template creates need the regional endpoint override. Step 7 then writes the global override permanently, redirecting later regional calls | Per-command endpoint override variables. Delete or unset the persistent setting |
| S119 | major | SETUP 12c l.1849, 13b l.2059, Phase 6 l.604 | Google's Agent Gateway page lists 22 required APIs; nine are enabled by no phase, and the P-SA allow-list may refuse them. PREREQUISITES l.255 does warn with a check loop | Enable the full list in 12c step 1. Resolve the conflict with Phase 6's omission of discoveryengine. Add the names to the P-SA allow-list |
| S120 | major | SETUP 12b "Failed" l.1773; 12c l.1842, l.1932, l.1973 | Gateway-mediated Model Armor needs Agent Identity. On the service-account fallback the engine binds but the fail-closed screen does not apply, and the runbook does not say so. Lens correction: the binding is not refused | State in the Failed branch: ingress Model Armor floor-only, fail-open, recorded in decision 24, in-process plugin mandatory at S0 |
| S122 | major | SETUP l.36, l.80, l.1678, l.2026, l.2268–2286, l.2447, l.2474–2482, §4 tests 12–18; 11 §6.3; Phase 9 verify l.1177, l.1198 | Phases 11–14 and 16 sit after Phase 10 but their verifies need the grant. A follower in document order hits "stop and fix" failures, or grants early. Phase 2 l.383 states the order in prose | Tag each verify "pre-grant: expect 403" or "post-grant". Add a post-grant verification section after Phase 2 step 5 |
| S123 | major | SETUP Phase 16 l.2392–2443, verify 3 l.2449–2456 | A metric written once a day fires the 90-minute absence alert daily on a healthy system. Before the first run the absence never triggers, so the break test shows nothing | Emit the metric every 10 minutes from a probe. Keep the absence condition. Set the threshold condition's missing-data behaviour to inactive |
| S124 | major | SETUP §4 l.2521–2525, tests 2–9, 51 l.2532–2549; Phase 6 l.668–670 | The tester can impersonate only `walle-operators-caller@`. Tests 4, 5, 6b, 6c, 7, 9 and 51 cannot run, or pass because impersonation fails. The script's remedy gives a human a path to a Super Admin token | A `walle-denialtest@` fixture account. Time-boxed PAM on `walle-agent@` only. testIamPermissions or Policy Analyzer instead of impersonating credential holders |
| S125 | major | SETUP §4 l.2521–2525 vs §6.1 l.2761, tests 17b–17e l.2562–2565 | `walle-actions-super` is never scaled to two instances nor tested. Tests 17b–17d have no URL. The box is ticked on half the system | Duplicate the block for the super service. List test ids per service |
| S126 | major | SETUP §5 K2 l.2656, restore l.2690 | K2 detaches the push subscriptions. A detached subscription cannot be reattached, so after the first monthly drill the triggers are permanently dead and restore does not recreate them | Drill with `modify-push-config --push-endpoint=""`. Restore the endpoint. Add the create commands to restore |
| S127 | major | SETUP §5 K4 l.2658, restore l.2690–2698 | After K4 the broad client's new token version is never exported or deployed, so band B/C and the super halt stay pinned to a destroyed version | Add `SUPER_REFRESH_TOKEN_VERSION` export and the `walle-actions-super` update to restore, §7.1 and §7.4 |

### 4.4 Eve

| Id | Severity | Location | What goes wrong | Fix |
|---|---|---|---|---|
| S027 | blocking | Eve l.78, l.91, l.183–199, l.219–246 (Phase 1) | `EVE_PROJECT` belongs under `fld-controllers-prod`, made by the factory's `verifier-project` module with its deny, PAB, datasets, locked bucket and key ring. Phase 1 creates it by hand under `FOLDER_ID`, and there is no factory | Rewrite Phase 1 as "the `verifier-project` run has completed". Eve's runbook records the ids and verifies the parent (`CONTROLLERS_FOLDER_ID`), the policies and the datasets |
| S028 | blocking | Eve Phase 3 l.367–376 | No `schemas/eve_*.json` exists anywhere and 03-lld leaves columns *tbd*. `bq` reads the missing path as an inline schema and fails, so no Eve table is created | Commit the nine schema files with typed columns before Phase 3. Add a presence pre-check |
| S029 | blocking | Eve Phase 4 l.444–492, l.1200 | None of the twelve SQL files nor `thresholds.yaml` exists, and only m01's command is shown. Metric 10 cannot be a BigQuery query (Firestore). Metrics 9 and 11 have no source Eve can read before Phase 7 | Commit the files and one command per file. Redefine metric 10 over `walle_audit.config_versions` or move it to S3. Mark 9 and 11 as starting at Phase 7 |
| S030 | blocking | Eve Phase 10 l.1215–1229, l.1246, l.1303; Phase 11 verify 7 l.1951 | No Eve source, Dockerfile, CI script or test exists. `gcloud builds submit` from the current directory builds nothing or the wrong thing. Phases 10–11 specify code still to be written | Precondition: the Eve repository at a named commit with green CI. Name the source path in each build. Mark Phases 10–11 not executable until then |
| S031 | blocking | Eve Phase 1 l.192–195, Phase 9 l.910–915, Phase 8 verify l.882–892, 10b step 1 l.1450–1458 | `admin.googleapis.com` is never enabled in `EVE_PROJECT`, which owns Eve's client, so every Directory and Reports call returns SERVICE_DISABLED. Phase 8's verify reads a secret before Phase 9 enables Secret Manager | Enable `admin.googleapis.com` before Phase 8 step 6. Move Phase 8's verify after Phase 9's secret versions |
| S032 | blocking | Eve Phase 9 l.945–951, l.1013–1018, l.1043–1052; Phase 10 l.1299–1336; Phase 11 l.1737–1747 | No step grants `eve-verifier@` or `eve-controller@` WRITER on `eve`, READER on the log datasets, objectViewer on `ladder/`, nor `eve-console@` any dataset role or jobUser. Reconciler, gate and console fail on first access | Add the dataset, table, bucket and jobUser grants to Phase 9 with verify |
| S033 | blocking | Eve Phase 10 l.1266–1291; Phase 11 l.1749–1760 | Scheduler's token identity needs `run.jobs.run` (with overrides). Neither Eve account gets a Cloud Run role, so all five reconciler schedules and `eve-gate-poll` get 403. Verify 3 hides this by running as the owner | Add `roles/run.jobsExecutorWithOverrides` on each job. Change verify 3 to `gcloud scheduler jobs run` |
| S034 | blocking | Eve Phase 10 l.1305 | `gcloud services identity create` exists only in beta. The IAP service agent is not created, so the invoker binding fails and `eve-console` is unreachable | Use `gcloud beta services identity create --service=iap.googleapis.com` |
| S035 | blocking | Eve Phase 9 l.963–981, Phase 11 l.1766–1769, l.794–799 | The consent (Phase 8) happens before a mid-Phase-9 stop on decision 44 or CC-33, so the sitting ends with a live Eve credential and no working Eve. Phase 11's Firestore read has no grant | Make decision 44 or CC-33 a prerequisite gating Phase 8. Rewrite Phase 11's discovery sentence to the closed option |
| S036 | blocking | Eve Phase 11 l.1787–1789, verify 5 l.1935–1939 | The receipt view selects `verdict_ts`, but the verdicts table has `ts`. View creation fails, and the authorised view and Wall-E's staleness sweeper have no source | `ts AS verdict_ts`, and fix the committed schema |
| S037 | blocking | Eve 10b steps 1, 4, 5 l.1432–1453, l.1479–1518, l.1520–1557 | The phase that gates the grant has no command for the export job (image, deploy, scheduler, grants), no DDL for `eve_workspace_reports`, one of six views, and a literal placeholder principal that makes `bq update` fail | Write step 4 in full. Add the table DDL, all six views with access entries, and gate step 5 on its identities |
| S038 | blocking | Eve Phase 8 l.819–835, l.2084; SETUP Phase 3 l.446–453; `walle_setup.py` l.2527, l.8294–8319 | `eve@` is created in an OU that already enforces security-key-only 2SV with no enrolment period, so it cannot sign in to register its key. On the script path, `walle workspace` blocks at M2A waiting on Eve's key | Create `eve@` in a staging OU (or with a one-day enrolment period), register both keys with custodians, verify, then move it. Remove `eve@` from the script (S088) |
| S039 | blocking | eve/05 G-4 l.310; Eve 10b verify 1 l.1570–1574; SETUP l.383, §0.2 | Circular: the grant needs G-4, G-4 needs robot shadow runs, and shadow runs need the grant and Stage 0. The admin audit log also records changes only, so a shadow run leaves no row | Rewrite G-4's evidence: a seeded admin change by the sandbox twin in both Eve datasets within the lag budget, plus the production robot's consent login event. Move "walle@ rows" to post-grant |
| S040 | blocking | Eve Phase 8 l.845–892, l.150, Phase 9 l.936–946; `cmd_consent` l.3851–3858 | No executable consent step exists for Eve. The obvious improvisation opens the owner's own super-admin browser (SETUP §7.1 failure), nothing checks the signed-in account, and the token of a tenant-wide reader is left in a local file | Add an Eve consent command: prints the URL, never opens a browser, refuses unless userinfo is `eve@`, refuses a scope mismatch, writes straight to the secret |
| S041 | blocking | Eve Phase 9 bucket l.1042–1048; half-fail row l.2111; Phase 11 key ring l.1623–1631 | An irreversible retention lock with a permanent lien is applied with no gate, preview or second person, on a bucket in the EU multi-region with Google-managed encryption, while the design needs the HSM key `eve-evidence`. None of it can be corrected afterwards | Refuse unless the signed E-14 file exists. Create the key first. Create the bucket with location, CMEK, uniform access and public-access prevention. Set retention, verify, then lock as a separate step with a second person |
| S128 | major | Eve Phase 10 l.1253, Phase 11 l.1747 | The reconciler has no address for `walle-actions-super`, so super-lane halts reach only `walle-actions`. EVE-19 and the 10b drill fail, and band B/C keeps running during an incident | Add `SUPER_ACTIONS_URL` to both environments and a verify 6b |
| S130 | major | Eve l.107–110, l.236–243, l.1110, l.1054–1061; PREREQUISITES l.95, l.346 | On the default path `SA_WALLE_CI` is empty. The Phase 1 filter matches everything, the `ladder/` grant goes to `serviceAccount:` and fails, and a literal `<walle-deployer-group>` proves nothing | Name the ladder publisher (`walle-deployer@`) in topology, PREREQUISITES and Eve. Guard against empty variables |
| S131 | major | Eve Phase 4 verify 1–2 l.496–513 | TransferConfig has no `serviceAccountName` field (only `ownerInfo`, on get), so every row prints "human credentials". Check 2 matches a string no schedule contains | Use `bq show` per config and assert `ownerInfo.email`. Test schedule strings in Python |
| S132 | major | Eve Phase 5 l.537–584 | The absence alert counts every DTS log entry including errors, so a query failing hourly keeps the series alive while `eve.findings` stops | Alert on data freshness (`MAX(ts)`) or on success entries per config, plus an alert on errors |
| S133 | major | Eve Phase 5 verify l.574–581 | `bq update` has no `--disable_auto_scheduling`, so the pause command errors and the one v0 detection is never observed firing | Pause and resume via the console or a REST `PATCH` of `disabled` |
| S134 | major | Eve Phase 12 l.1980–2030 | The guarded key-destroy subcommand and `_pem_archive_present` no longer exist in `walle_setup.py`. Destroying an Eve key version is an unguarded manual command | Restore the guarded command with a self-test, or add an Eve-side tool that refuses without the archived public key |
| S135 | major | Eve Phase 9 l.1043–1048 | The locked bucket is created in the EU multi-region while 08 S5 says `europe-west1`. Location is immutable and the lock irreversible. The facts lens notes Eve's own HLD says EU, so the conflict is between design pages | Decide one location across 08 and eve/01. Add a pre-lock location check |
| S136 | major | Eve Phase 10 l.1252, l.1256–1263 | The Scheduler header goes to the Run Admin API, not the container, so the reconciler has no idempotency key. A retried task writes verdicts, findings or halts twice | Derive the key from the execution and the schedule window. `MERGE` on it. `--max-retries=0` for halting passes |
| S137 | major | Eve Phase 11 verify 3 l.1913–1918 | The negative KMS test impersonates `eve-verifier@` without token-creator, so it fails at impersonation and reads as the expected denial: a false pass | Use Policy Troubleshooter for `useToSign`, expecting not granted |
| S138 | major | Eve Phase 3 l.384–402; Phase 11 l.1871–1877 | WRITER maps to `dataEditor`, which can delete and rewrite the mirror, findings and `grades_blind`; nothing is append-only. Tables expire at 400 days with no locked export until 10b. The grant follows Eve's design pages | Custom insert-only role per table, and an earlier locked export. Otherwise record the gap as an accepted S0–S2 limit |
| S139 | major | Eve Phase 9 l.936–943 | `shred` does not exist on macOS. The plaintext refresh token and client secret stay in the working directory | Pipe straight into `gcloud secrets versions add --data-file=-`, or use `rm -P` on a temporary file outside synced folders. Check the file is gone |
| S140 | major | Eve l.27, l.39–41, E-18 l.56, Phase 9 l.973–980, 10b l.1450–1451; eve/05 S2 l.46 | The page says both to hold Phases 8–11 until L3 to L4 and to run them before the grant. Decisions 44 and CC-33 are missing from its decision table | Supersede l.40–41. Add decision 44, CC-33 and CC-25 rows. Add a stop check at the top of Phase 8 |
| S141 | major | Eve Phase 7 verify 4 l.758–782, l.636–637 | Before the grant the robot makes no admin change, so check 4 cannot pass when run where the gate requires. The follower may delete and recreate the sink, losing un-backfillable history | Split check 4: pre-grant, consent login events and a human test change; post-grant, the Phase 17 robot event |
| S142 | major | Eve l.80; Phase 7 l.642–645, l.678–683; 04 §5.2 l.394 | An organisation sink needs `logging.configWriter` at the organisation. No entitlement grants it there, and a standing grant is a severity 1 drift finding | Add `ent-org-sink` to 04 §5.2, or create `eve-workspace-audit` in M1's logging phase |
| S143 | major | Eve Phase 10 l.1266–1272, Phase 11 l.1749–1753, Phase 2 l.~270–285 | The owner, who is also Wall-E's deployer, keeps standing actAs on `eve-controller@` (signer) and `eve-verifier@`. One person can produce a valid Eve L4 approval or read Eve's token | Time-boxed conditional binding or PAM, removed after job creation. Verify no user holds `serviceAccountUser` or token-creator |

### 4.5 Mo

| Id | Severity | Location | What goes wrong | Fix |
|---|---|---|---|---|
| S042 | blocking | Mo l.100, l.214–241, l.254–256 (Mo-1 step 0), l.448–466 | Under the platform design no human holds projectCreator or standing Owner. Done anyway with an org-admin role, `MO_PROJECT` lands under `fld-agentic-platform`, outside `improver-project`: no `deny-improvers`, no deny-platform entry, no nonprod twin | Replace step 0 with the factory call (`fld-improvers-prod` plus nonprod). Name the PAM entitlement per phase |
| S043 | blocking | Mo l.335–338, l.358–379, l.722–760, l.1160, l.1545–1552; prerequisites l.96–108 | The 20 schema files, 19+ SQL files, two images and `gates.yaml` do not exist and no repository is named. Mo-1's loop fails on the first schema, Mo-4 on the first SQL | "Build inputs" prerequisite block. Gate Mo-1 on the file count |
| S044 | blocking | Mo-3 fixture l.671, l.683; mo/03 l.241, l.282 | The Wilson lower bound for k=35, n=38 is 0.7920, not 0.7921. The fixture fails every time and blocks every metric pull request | Change the constant in the three places. Compare with a tolerance |
| S045 | blocking | Mo-5 A5 l.872–875, A7 l.881–883, l.853 | A5 references columns that aggregate rows lack, and A7 uses an undeclared alias, so the script stops and A6–A9 never run. A5 also tests the wrong invariant (grades join actions) | Rewrite A5 over `walle_audit.grades` and `actions`. Declare the alias. Guard A9 |
| S046 | blocking | Mo-9 l.1382–1388, l.1420–1438; l.247–250, l.1171–1174; Mo-8; P22 | The CI identity, pool, ingestion workflow, allowlist, validator and branch protection have no executable step, and a literal placeholder member. The WIF pool "in `MO_PROJECT`" contradicts the single pool in `CICD_PROJECT`. The context lens notes Mo-9 is a documented stop at S2 exit | Close M-7 and decision 50 before Mo-7. Principal from the `CICD_PROJECT` pool. Write the bindings and ingestion job. Drop the Mo pool. Write M9 |
| S152 | blocking (raised by the facts lens) | Mo-7 l.1212–1251, verify l.1268–1277, l.1700–1701 | No watermark writer exists, `mo-analyst@` lacks `metricWriter`, and no notification channel exists in `MO_PROJECT`. The alert policy cannot be created (or fires permanently) and `<CHANNEL_ID>` has no value | Add the writer job, its role, the metric descriptor and a channel before the policy. Break-test by pausing the writer |
| S144 | major | Mo-1 l.308–379 | The design requires agent-neutral Mo dataset names before Stage 0. BigQuery datasets cannot be renamed, so building as written fixes Wall-E names into the archive that promotions cite | Close the rename before Mo-1 and change all pages in one pass |
| S145 | major | Mo-5 l.842–846, l.853–897, l.900–908 | The assertions run once interactively and never again. No transfer, no alert and no freeze exist, and A10 is never created | Append the asserts to the scorecard SQL or schedule an `mo-assertions` transfer. Alert on failed runs |
| S146 | major | Mo `call_actions` l.1666–1671, l.1675–1677 | Without `--include-email` the token has no email claim, so the positive call returns 403 and the negative tests pass for the wrong reason | Add `--include-email` and print the claims once |
| S147 | major | Mo-2 l.474–511, Mo-6 l.999–1003 | Cross-owner grants on Wall-E and Eve resources sit uncommented in Mo's bash. `grant_dataset` has no error handling and a fixed `/tmp` file | Move cross-owner lines to a "made elsewhere" table. Add error checks, de-duplication and `mktemp` |
| S148 | major | Mo-4 verify l.802–806 | Same TransferConfig field error as S131: every config prints "user credentials" and the operator is told to recreate them all, which changes nothing | `bq show` per config and print `ownerInfo.email` |
| S150 | major | Mo l.198–200, l.364, l.750 | A scheduled query cannot read a CSV in git, so the toil baseline is never loaded, and partition expiry would delete it after 400 days | Explicit `bq load` on merge, no expiration, a copy in the archive |
| S151 | major | Mo-2 verify l.566–579, MD-10 l.1616 | Without `--location` the regional secrets are "not found" and print nothing, which reads as the expected result. The super secrets are omitted. `secrets list` in `MO_PROJECT` fails silently | List with `--location`, fail on non-zero exit, assert Secret Manager is disabled in `MO_PROJECT` |
| S153 | major | Mo-7 l.1151–1166, l.1265–1266 vs Mo-9 l.1343–1366; mo/04 l.64 | At S1 the reporter has no drop box, no objectCreator and no ingestion, so it cannot write any artefact. The image cannot be pushed without the CI identity | Move the drop box and objectCreator into Mo-7. State how S1 artefacts reach humans |
| S154 | major | Mo-10 l.1473–1507 | The linked trace dataset lives in `europe-west1` while `walle_audit` is in EU. The cost and latency joins fail at runtime, and the `_Trace` location is set nowhere | Read the bucket location first. Set trace storage at project creation (see X-RQB-03). Verify the actual join |
| S155 | major | Mo l.297, l.510, l.1038–1053, l.1127–1133 | Views are created as the human, so `mo-metrics@`'s WRITER is unused yet lets it place raw tables in the dataset the narrator reads. Verify ignores non-view objects | Create views under `mo-metrics@` and verify `table_type = VIEW` only |

### 4.6 Second-round findings (not verified)

These come from the three second-round finders of 2026-09-15. They cite Google pages checked
that day, but no adversarial lens has tested them. Treat them as strong leads, and verify each
before acting on it.
- Ids X-ORG-nn: `find-extra-second-and-third-organisations.json`.
- Ids X-GE-nn: `find-extra-gemini-enterprise-app-side.json`.
- Ids X-RQB-nn: `find-extra-region-quota-billing.json`.

#### Sandbox tenant and witness organisation

| Id | Severity | Location | What goes wrong | Fix |
|---|---|---|---|---|
| X-ORG-01 | blocking | 02 §3.5 row 4 l.487, §2.2 l.327; SETUP Phase 9 l.1099; Eve Phase 8 l.845–892 | An Internal OAuth client in a project in the organisation admits only members of that organisation. The sandbox robot gets `org_internal`, so no twin token is ever stored and G10, G11, G14, G-5 and G-7 cannot go green. Testing status expires tokens after 7 days. Moving the twin project to the sandbox's Cloud organisation removes it from the folder controls the gate is meant to evidence | Twin clients External, In production (never Testing), each trusted in the sandbox Admin console (exempt from verification). Record that the `org_internal` refusal is not reproduced in the twin |
| X-ORG-02 | blocking | Eve Phase 7 l.630–784, 10b drill l.1598–1603; eve/05 G-5, G-7; 08 §3 S-org l.194; 07 §6.2 l.395–401 | Workspace audit logs go to the tenant's own Cloud organisation. The organisation's sinks, S-org, the SIEM and SA-01 to SA-09 see no sandbox event, so the G-5 and G-7 drills and the SA fixtures cannot be evidenced | Add a "sandbox organisation logging" phase to M6: sandbox Share data on, sinks created in the sandbox organisation to nonprod destinations, writer identities granted, seeded event verified |
| X-ORG-05 | blocking | topology §2 l.188, §1.2 l.108 vs §7.5 l.533; 01 §13.2 l.1072–1085; eve/05 G-1 l.307; 04 §8.1 l.572; 11 §7.2 l.456 | The witness excludes tenant super admins, but the second human (a tenant super admin) is named its administrator. G3, G-1 and the exclusion cannot all be true. The owner can do none of W-1 to W-4 | Witness super admins: two IT security people who are not tenant super admins. The second human gets a non-admin witness account. Count them in P137 |
| X-ORG-06 | blocking | 07 §7 H-1 l.475, H-4 l.479; eve/01 l.302; eve/03 l.473; Eve 10b steps 2, 4 l.1466–1470; 08 §5.4; SETUP G1 l.393 | Cloud Monitoring has no "rows arrived in BigQuery" metric. A metric-absence window is at most 23.5 hours, so a 26-hour policy cannot be created. A 60-minute alarm cannot evaluate daily data. Absence never fires before the first data point, so G1's "fired once on purpose" cannot be produced | Hourly heartbeat plus a 6-hourly export under the same identity. Log-based metrics in the witness on `eve-export@`'s inserts. Absence policies of 90 minutes and 23.5 hours. Drill only after the first heartbeat |
| X-ORG-07 | blocking | eve/03 §15 l.792; Eve 10b step 3 l.1474–1476, drill l.1598–1602; eve/05 G-6 l.312; 07 §8 RP-3, RP-5 l.529–531 | Notification channels are project resources usable only by policies in the same project. Eve cannot page "through the witness channels", and the witness learns of a severity 1 up to a day later | Primary route: Eve pages directly through IT security's paging service. Witness backstop: an incident-mode export and a log-based alert in the witness. Rewrite G-6 |
| X-ORG-03 | major | 02 B5 l.602, PSA6 l.186, §3.5 row 5 l.488; topology l.189; wall-e/03-lld l.651–660 | `fld-controllers-nonprod` does not admit the sandbox customer. The logging writer identity needs an explicit exception. Twin services cannot check an organisation group from a sandbox token. IAP's managed client refuses outside users. The new sandbox organisation refuses every organisation service account by default | Admit the sandbox on the controllers nonprod folder with the managed member constraint and exact writer identities. Sandbox groups and approvers. Custom IAP OAuth client for the twin. Record differences in G14 |
| X-ORG-04 | major | PREREQUISITES D3 l.50, §3.1 l.108, l.111; 04 §8.3 l.641–648; P59; SETUP G3–G6 | The sandbox has no edition, domain, seats, admins or keys. Multi-party approval, activity rules and log sharing need Enterprise Standard or higher. A domain can belong to one Google account only. Two sandbox super admins are needed. Eight more keys | "Sandbox tenant" block in PREREQUISITES. Key counts corrected. Long-lead procurement rows. "Two humans required" on G10, G11, G14 |
| X-ORG-08 | major | topology §2 l.173, l.188; P14 l.232; eve/01 l.298 | Funded by the organisation's billing account, the witness can be switched off by anyone who reaches Billing Account Administrator through Organization Administrator. Billing disabled stops the project and may delete resources. Linking also needs a witness principal on an organisation resource. Duplicate of X-RQB-06 | Separate billing account inside the witness, administered only by the witness admins, with a budget alert |
| X-ORG-09 | major | P14 l.232; topology W-1 l.528; eve/01 l.298 | Whoever controls the witness domain's DNS has a documented super-admin recovery path. A subdomain, DNS zone or registrar held on the organisation's side breaks the independence. Multi-party approval needs Cloud Identity Premium | Separately registered domain and DNS outside the organisation, administered by the witness admins, registrar lock, self-recovery off. Decide Free or Premium |
| X-ORG-10 | major | topology W-3 l.530, row 32 l.264; Eve 10b step 4 l.1508–1514; B5 | New organisations enforce legacy `iam.allowedPolicyMemberDomains` with only their own domain. Adding the managed constraint (S061's fix) does not lift the legacy one, so rows 32–33 fail | Set the managed constraint, then set the legacy one to not enforced (dated decision), then grant, then verify that another account is refused |
| X-ORG-11 | major | 04 §8.3 l.629–633, §7.1 l.535; SETUP G11 l.403, G18 l.410, Phase 3 l.450; Eve 10b l.1602; eve/03 l.808–810; topology l.188 | Keys are enrolled before the witness exists, so "same day" custody copies cannot exist. No identity can write custody, rota or drill records to the witness. Locked objects cannot be corrected | A records step in M5 (prefixes, versioned names, uploaded by a witness admin). Move W-1 and W-2 before the first enrolment |
| X-ORG-12 | major | Eve 10b drill l.1598–1602; eve/05 G-2, G-5, G-7; 01 §13.2 l.1073–1075; topology row 32 | A sandbox drill that reaches the witness needs a third and fourth cross-organisation grant, and pollutes the locked production evidence | Split the drill: sandbox part with nonprod channels only; witness part with production `eve-export@` withheld before the grant |
| X-ORG-13 | major | 02 PSA1 l.163, P1 l.174, §3.5 row 2 l.485; S008 fix alternative | The twin project comes from the same P-SA row, which P1 refuses until G10, G11 and G14 are green. S008's "twin first" alternative loops | P1 gates only the production credential. The nonprod project applies with the checklist pending. Delete S008's alternative |
| X-ORG-14 | major | master-order stages 1, 3, 27, 30, 31; 02 §3.5 row 5; wall-e/09 decision 29; PREREQUISITES D3 | Decision 29 dates the sandbox "before Stage 1", after the grant that needs it. Long-lead items start too late. The witness is too late for custody records. A K6 drill can expire before the grant | Change decision 29. Reorder as §2 of this page (stages 1, 3, 7, 29, 32) |

#### Gemini Enterprise app side

| Id | Severity | Location | What goes wrong | Fix |
|---|---|---|---|---|
| X-GE-01 | blocking | 03 §16 GE-6 l.459, §5.4 l.200–204; 08 R8 l.390; P52 l.191 | Setting Assistant retention to 30 days deletes every chat older than 30 days without warning, irreversibly, on an interim assumption before the DPO decision. GE-0 does not record the current value | Record the current value. Only raise it in GE-6. Any reduction becomes its own post-P13 step with user notice, marked irreversible |
| X-GE-02 | blocking | 03 §16 GE-5 l.458, §4 l.136–144, §7 l.240, §15 l.426 | GE-5 creates `ge-users@` empty, binds it at app level and removes basic and project-level roles, which take precedence today. Every current user, operators included, loses access | Export current IAM and "Manage users". Fill the group, then bind, then test, then remove old bindings one at a time with the saved policy as rollback |
| X-GE-03 | blocking | 03 §16 GE-3, GE-4 l.456–457, §3 l.115; 02 §4.2 l.639 | `restrictServiceUsage` applies at runtime to existing resources. The allow-list omits `bigquery`, `bigquerydatatransfer`, `dialogflow`, `aiplatform` and `cloudaicompanion`, so connectors and agents that use them stop. The move drops roles granted on the old parent | List enabled services, assets and inherited roles first. Allow-list = union. Dry run 14 days (supported for this constraint). Re-grant before the move |
| X-GE-04 | blocking | 03 §16 GE-9 to GE-11 l.462–464, §11.1 l.337, §11.2 l.349–353 | DRY_RUN is a property of the authz extension, which no step creates, not of the binding. Binding routes all app traffic through the gateway immediately. Egress is denied by default, and only imported resources are reachable. Google documents no unbind | Full gateway and extension YAML. Import every existing agent, endpoint and MCP server. Prove dry run and unbind on a throwaway app. Bind in a change window with a user test |
| X-GE-05 | major | 03 GE-4 l.457, §5.2 l.174–186; P50; 09 l.252, l.284 | A default CmekConfig moves new end-user data of the live app under `gemini-cmek`, contrary to the recorded position. Google requires manual rotation, but the factory sets 90 days. Key disable stops the app in 15 minutes and deletes data after 30 days. Unsetting removes protection. CI lacks the permission. Owner mismatch | CMEK as its own decided step by `ge-admins@` via PAM. Manual rotation. Storage agent grant. Key-availability runbook row. Correct P50 and 09 |
| X-GE-06 | major | 03 §4 l.140, §7 l.240, §15 l.426, GE-5, GE-14 | `discoveryengine.editor` lacks `engines.setIamPolicy`, `engines.update` and `assistants.update`, so every CI-owned binding and restore fails, or CI is quietly given admin | Owner `ge-admins@` via PAM with CI verifying, or a custom CI role recorded as a P49 amendment |
| X-GE-07 | major | 03 GE-7 verify l.460, §13 l.394; 06 §3.5 l.429, l.434; 08 §4.1 | SCC findings exist for floor violations, not for sanitisation matches on the assistant path. The documented record is the Model Armor Data Access log, which is not enabled | Enable Model Armor Data Access on `GEMINI_PROJECT`. Verify on SanitizeUserPrompt entries. Correct 06 §3.5 |
| X-GE-08 | major | 03 GE-7 verify l.460 | Making the fail-closed template unreachable on the production app blocks every user's assistant for the test | Run that test only on the throwaway app. On production read `failureMode` |
| X-GE-09 | major | 03 §3 l.112, §15 l.436, GE-4, GE-11 | Google publishes a custom constraint on `Engine.agentGatewaySetting`, so the gateway binding can be enforced, yet the design builds only detection | Add a custom constraint pinning the binding to `gemini-egress`, dry-run then enforce. Update rollback |
| X-GE-10 | major | 03 GE-4 l.457, §3 l.111, §12; 02 l.325; P48 | The two managed constraints document different `enforcedProjects` formats. A wrong form matches nothing and provisioning is allowed. Only one is verified. Existing connectors are untouched | Exact value per page. A second verify for egress FQDNs. List existing data stores and decide each |
| X-GE-11 | major | 03 §13 l.390–392, GE-13, GE-14, §10.1 l.307; 06 l.434; 08 l.293 | Agent sharing has no documented audit method. Get and List reads are ADMIN_READ (not enabled). Retention changes are `UpdateEngine`, not `UpdateAssistant`. Several detections have no source | Enable ADMIN_READ. Use direct API reads for drift. Key rules on `UpdateEngine`. Scheduled agent IAM reads for over-wide shares |
| X-GE-12 | major | 04 l.396; 03 §4 l.146–150; P49 l.135, l.314; GE-6, GE-7, GE-10 | Three approval models for `ent-ge-admin`. With an approver who is the requester, PAM refuses (no self-approval), so the only admin cannot run the GE steps once standing admin is removed | At Tier C, no-approval with justification, 1 hour. Creation command in GE-5. Verify a grant before removing standing access |
| X-GE-13 | major | SETUP §1.1 D8 l.129, Phase 13 step 5 l.2020; PREREQUISITES D8 l.55, l.252 vs 03 GE-0 l.453 | Wall-E accepts a `global` app, which GE-0 stops on. A global app cannot bind a `europe-west1` gateway or use CMEK | D8 "eu only" in SETUP, PREREQUISITES and `cmd_register` |

#### Region, quota and billing

| Id | Severity | Location | What goes wrong | Fix |
|---|---|---|---|---|
| X-RQB-01 | blocking | SETUP Phase 12 l.1530–1589; wall-e/03-lld l.1211–1214, l.1435; wall-e/09 decision 6; Mo-11 l.1545–1557; 02 l.538; 08 DL-7.3 l.545; eve/02 l.30 | No model is pinned. The engine's model client inherits `europe-west1`, which serves only Gemini 2.5, retiring 2026-10-20. GA successors are served on `global`, `eu` and `us` only. Pin 2.5: stop in five weeks. Pin 3.x: model-not-found. Use global: the EU processing claim is false | Close decision 6 before Phase 12 and Mo-11 with a GA model on the `eu` endpoint. Set the model client location explicitly to `eu`. Verify a call on the eu endpoint |
| X-RQB-05 | blocking | 02 l.461, l.476–478, l.572; P31 l.122; PREREQUISITES l.142; SETUP §0.3 l.53; Eve l.189; Mo l.225; master-order stage 4 | Nobody named can grant Billing Account User or Costs Manager on "the platform billing account", so the first project link fails. The export covers the whole account. Project quota per billing account may need a request of about two business days | Prerequisite before stage 5: a dedicated EUR sub-account and its administrator, roles with expiry, quota increase, export by the billing admin, `billing_project` on Terraform |
| X-RQB-03 | major | 08 R9 l.391, DL-7.1 l.542, S11 l.104; 02 B1 l.598; master-order 5–9; SETUP 12c; Mo-10 | New projects get `_Default` and `_Required` log buckets in `global` unless the folder default storage location is set, and bucket location cannot be changed. Observability buckets inherit their location, and B1 may refuse their creation, silently dropping traces | Set Logging and Observability defaults on `fld-agentic-platform` right after the folder tree, before any project. Verify on the first project |
| X-RQB-04 | major | 01 §0.5 l.174; P11, P94; 07 §3; master-order stages 3, 12 | Organisation pay-as-you-go SCC Premium is charged to every project's billing account in the organisation. The subscription is a contract (5% of spend, minimum 15,000 USD, 12 months). Activation needs organisation SCC admin. A location policy after activation can deactivate SCC | Name both options and payers. Close P11 at stage 1. Activate with EU residency before the location policy |
| X-RQB-06 | major | topology W-1, W-2 l.528–529; P14; 01 l.1441; 08 DL-7.6; Eve 10b | Same billing threat as X-ORG-08. Also, Access Approval is listed on Google's pricing page as included with Standard, Enhanced or Premium Customer Care (checked 2026-09-15), which does not carry over to a new organisation | Own billing account and support tier for the witness. Billing-status alarm in W-4 |
| X-RQB-07 | major | 02 §2.2 l.319–330, §3.7 l.566–573; 01 §0.5 l.175; SETUP §0.3 l.53–70, l.684–694; 07 PL-07 l.430 | Agent-project budgets (200–500 EUR) will essentially never fire, so PL-07 means nothing. `LOGGING_PROJECT`'s 300 EUR likely fires at about 650 GiB a month of tenant audit ingestion, a volume nobody has measured. The costs that dominate the gates sit on no budget | Measure 30 days of ingestion before P31. Set budgets from priced components. Add a "costs outside Cloud budgets" table |
| X-RQB-08 | major | Mo-11 l.1527–1557; SETUP 12c step 7 l.1977–1990; 02 l.646 | Model Armor screening of `generateContent` needs a project-level floor with `VERTEX_AI` and `modelarmor.user` for the Agent Platform service agent. Mo-11 creates neither, so narrator prompts go unscreened while recorded as screened | Enable the API, grant the agent, set the project floor, verify with an injection string. Same for the Eve advisor module |

#### Second-round minor findings (not verified)

| Id | Location | What goes wrong | Fix |
|---|---|---|---|
| X-ORG-15 | 07 §6.2 l.395–401, F1 l.72; 02 PSA4 l.166–167; eve/05 G-5 l.311 | SA rules match the production robot's address and receive no sandbox events, so twin fixtures pass vacuously | Run fixtures against the sandbox tenant's own SecOps export. Rules take a robot list with the twin tagged nonprod |
| X-GE-14 | 03 GE-7 l.460; 06 §3.3 vs §3.5 l.427 | The "platform standard" creates templates in `europe-west1`, but an `eu` app needs `eu` templates, and a region cannot be changed | GE-7 names project `GEMINI_PROJECT`, location `eu` and the endpoint. Record the exception in 06 §3.3 |
| X-GE-15 | 03 GE-6 verify l.459, §8 l.258–279, §15 l.431–432; 08 l.635 | Console toggle names do not map to `Engine.features` keys, and some have no API. "Model selector off" plus a pinned set is not configurable. `sensitiveLoggingEnabled` is absent. Retention is `sessionConfig.sessionTtl` | Commit the baseline as Engine fields with a console-name mapping. Add `sensitiveLoggingEnabled=false`. Store GET before and after |
| X-GE-16 | 03 §4 l.138–139, §10.2 l.322, GE-5 | `agentspaceUser` holds `agents.create` and `agents.update`, so every licensed user can create agents by API | Record it. Test in the throwaway app. Count private user-created agents |
| X-GE-17 | 03 GE-6, §5.3 l.193–195; 06 §3.5 | Banned phrases block any query containing the substring (for example control group names). A PATCH of `customerPolicy` overwrites both banned phrases and Model Armor | List only strings no user types, with word-boundary match. Read then write both fields together |
| X-GE-18 | 03 GE-0 l.453; ../gemini-enterprise.md l.23–24 | Editions now include Pay-as-you-go, Frontline and Business (Business is administered elsewhere). The Assistant tab needs Plus. "Licence count" is ambiguous | Branch on edition. Record seats, distributed and assigned licences separately |
| X-GE-19 | 03 GE-1 l.454, §6 l.228–230, §7 l.239 | Context-Aware Access for Gemini Enterprise is rolling out until 2026-09-23, and the per-OU "access Workspace data" setting is never read. Group settings override OUs | Record service status and Workspace data access per OU and group. Re-check CAA after 2026-09-23 |
| X-GE-20 | 03 GE-10 l.463, §11.1 l.334 | An `eu` app needs the `eu-discoveryengine` host. The gateway name format is ambiguous. No `updateMask` or GET verify is given | Write the full PATCH with the regional host, project-number name and `updateMask`, then GET and check |
| X-GE-21 | 03 GE-8 l.461; 06 l.430 | 1,200 QPM per project is correct, but no metric or project is named for "assistant QPM", and GE system quotas also apply | Name the quota page and the SanitizeUserPrompt log count |
| X-GE-22 | SETUP Phase 13 step 4 l.2016, verify l.2024–2029; PREREQUISITES l.109 | Sharing needs a role choice, and group members also need `agentspaceUser` at app level. An operator outside `ge-users@` fails with no hint. An admin sees every agent | Name the role. Check assignment and group membership first. The test colleague holds no admin role |
| X-RQB-02 | PREREQUISITES §6.1 l.238, §6.2 l.250, l.256; wall-e/12 §11; 01 l.392–393 | Agent Gateway in `europe-west1` is still *tbd* in the page. It is supported (GA 2026-06-18, per Google's locations page checked 2026-09-15). The Model Armor quota comparison uses Admin SDK reads. Agent Runtime quotas are blank | Replace the *tbd*. Record Agent Runtime quotas (90 queries per minute, 100 engines, revision limits). Model Armor need = 2 × model calls + gateway requests |
| X-RQB-09 | master-order stage 3; PREREQUISITES §9 l.402–413; 01 §0.5 | Purchases are listed in no lead-time order and several are missing (billing sub-account, witness tenant and support tier, CEP, pen test, SecOps residency, throughput) | Stage 3 as a table sorted by lead time with owner and blocked gate (§2 of this page) |

### 4.7 Minor findings verified by the lenses (downgraded from blocking or major)

| Id | Procedure | Location | Narrowed claim | Fix |
|---|---|---|---|---|
| S014 | Wall-E | `cmd_workspace` l.2815–2858 | On gate day, re-running `walle workspace` to reach M2C re-prints M1 (password reset) and M2A (robot sign-in). Typed confirmation protects against accidental action, but it is a trap | Split M2C into its own subcommand. Skip M1 and M2A when already done |
| S023 | Wall-E (partial) | SETUP Phase 6 l.684–689 | Refuted: the 403 for missing quota project (gcloud bills the current project). Remains: `--budget-amount=200EUR` fails if the billing account is not EUR | Check currency with `gcloud billing accounts describe` first |
| S060 | cross (partial) | Eve Phase 8 l.851–875; `walle_setup.py` l.166–183 | Refuted: that the operator consents with the wrong set (Eve's list and verify are correct). Remains: stale `EVE_SCOPES` constant with a wrong phase reference | Land CC-27 or delete the constant |
| S068 | cross (partial) | SETUP §0.4 l.72–101; Eve l.801–803; Mo l.19, l.1705; 03 §16 | Refuted: that the operator sees only "a working week". Remains: no end-to-end critical path and no per-phase times for Eve, Mo and GE | Hands-on, elapsed and Who cells in Eve, Mo and GE. Critical path on the build-order page |
| S084 | Wall-E | PREREQUISITES l.18–26, l.43, l.59; Mo l.178–210 | The ordered list's step 1 omits starting Mo-0's four-week baseline, which gates Phase 1 | Step 1: start Mo-0 today |
| S086 | Wall-E | `verify_2sv_enrolled` l.8294–8319; SETUP Phase 3 l.448–474 | `isEnrolledIn2Sv` is method-agnostic, so the gate passes without a security key and the message overstates it | Attest the key count by eye. Reword the message |
| S102 | Wall-E | `phase_6_project` l.3061–3108; `ensure_project`; `walle.env.example` l.218–232 | No factory mode. The dated exception text is never recorded. `groupssettings` is enabled in `WALLE_PROJECT` | `FACTORY_BUILT` flag with read-only assertions. Print the exception |
| S110 | Wall-E | SETUP Phase 6 l.590–600 | `groupssettings`, `chromepolicy`, `cloudidentity` and `iam` are never enabled, so band-B calls on those surfaces fail | Add them to the enable list and compare in verify |
| S114 | Wall-E | SETUP §0.4 l.103 | "Run 1–6 and 8 before the repository exists" fails, because 8.4 edits the dataset Phase 7 creates | Include Phase 7's dataset parts, or move dataset creation into Phase 6 |
| S121 | Wall-E | SETUP l.1677–1678, l.2026, l.1682–1685, l.2029, l.628 | Before Phase 14's ladder, reads are denied `control_plane_unavailable`, so Phase 12 and 13 "a read works" cannot pass | Deploy the ladder document before Phase 12, or state the expected denial |
| S129 | Eve (partial) | Eve 10b l.1429–1430, l.1559–1565 | Documented deferral until P34 and P19. Once signed, rows 30–31 have prose and no commands | Write M10 when P34 is signed |
| S149 | Mo | Mo-4 l.726–735, l.794–797 vs Mo-5 l.849–853 | Two conventions for project ids in committed SQL, one of which leaves `__WALLE_PROJECT__` in scheduled queries | Pick one convention. `sed` in `create_metric`. Grep for leftover tokens |

### 4.8 Register minor findings (not adversarially verified)

#### Platform and cross-procedure

| Id | Location | What goes wrong | Fix |
|---|---|---|---|
| S156 | topology §7.4 l.505–522; SETUP §1.1 l.122, §1.7 l.247; Eve l.91 | Superseded steps 1–5 still read as current, and they create a standing per-person grant | Collapse them into a history note. Correct the `FOLDER_ID` comments |
| S157 | SETUP Phase 7 l.771–779, 11.3 l.1409–1468; script readers; Mo-2 l.491; Eve Phase 7 l.668–705 | Retired rows are rebuilt. Interim sinks have no deletion checklist line. Eve's writer grant is made outside its module | §6.1 line for interim deletion. Drop `LOGS_DATASET` once `LOGGING_PROJECT` exists |
| S158 | Mo-1 l.244; SETUP Phase 6 l.684–692; Eve | Mo's budget covers the whole billing account. Eve has no budget | Filter to the project, or leave budgets to the factory |
| S159 | SETUP Phase 5 l.522–555; 08 §3.2 l.194; Eve Phase 7 | If logging is built before Wall-E Phase 5, sinks route nothing and up to 24 hours are lost | Put the Workspace toggle in M1's logging phase. Keep the rest as verifies |
| S160 | SETUP l.832–844, l.1004–1016, l.1450–1462; Eve l.316–325; Mo-2 | Access-array edits use shared fixed temporary files with no etag check, so parallel or stale edits drop entries | `mktemp`, de-duplicate, etag check, read back and diff |
| S161 | SETUP Phase 15 verify 3 l.2333–2337, §6.1 l.2749 | Row 27 and `platform-drift@` invokers on the super service are never verified | Read the super service's policy. Reword the box |

#### Wall-E

| Id | Location | What goes wrong | Fix |
|---|---|---|---|
| S162 | SETUP l.611, l.658; script SA ids; README l.393–397 | `walle-actions@` invokes its own `/v1/tasks/item`, and `walle-tasks@` is not built | Create `walle-tasks@` as the queue's OIDC identity. Restrict the route |
| S163 | SETUP l.217, l.233, l.336–344, l.1134, l.2505, l.2721; Eve l.842–843 | `~/Claude/wall-e` does not exist and is never `git init`. Manual and script paths write to different repositories. Commits carry a fixed date | Use `$WALLE_REPO`, a Phase 0 init and dynamic dates. The Eve edit goes through Wall-E's review |
| S164 | SETUP Phase 4 l.484–499, l.80; Eve l.836–841, l.2085 | Menu labels are out of date ("reporting rule" is now "activity rule") | Update paths and names. Close PREREQUISITES gap 23 |
| S165 | SETUP §1.7 l.235–303; PREREQUISITES l.28, l.318; setup/README l.41 | Two different contents prescribed for `~/.walle-env` | Copy `walle.env.example` only |
| S166 | SETUP Phase 9 l.1114–1121; `run_consent` l.3717–3748; env l.138 | The client JSON is downloaded to Downloads, not `./client.json`. The pasted code is echoed. The operator client file persists | Explicit move, `getpass`, delete after use |
| S167 | SETUP §1.7 l.285–303, Phase 9 l.1143–1156 | A re-run after a lost shell mints a second live token. There are no resume checkpoints | Refuse existing versions without `--rotate`. Checkpoint per phase |
| S168 | `phase_14_forced_shadow_run` l.5549–5552; `phase_16_verification` l.6676–6719; README l.592–597 | The no-write check can pass before audit events land. Phase 16 verify fails until the first watch run | Re-check after 1 hour. Run the renew job once |
| S169 | `check_scheduler_states` l.7401–7422; `cmd_stage0` | After Stage 0 every verify fails on scheduler state | Expect paused or enabled by stage |
| S170 | `cmd_rollback` l.9756–9855, l.9918–9923; README l.75 | No scripted rollback for 7, 8, 12c, 13b, 16 | Add them, or document which are manual |
| S171 | `walle.env.example` l.24–27, l.148, l.224, l.232, l.240; `validate_config` l.1182–1188 | Day-one `walle workspace` refuses on placeholders it does not use | Ship them empty, or validate per subcommand |
| S172 | `walle.env.example`; `derive_config` l.1065–1123 | Platform handles and defaults are absent from the example | Add "platform handles" and "defaults" blocks |
| S173 | `confirm_manual` l.1583–1605; `cmd_consent` l.3903–3904; M7 l.1936–1960 | Consent is attested before it happens, and a re-run walks through attestations first | Check existing versions first. Attest afterwards |
| S174 | `grant_armor_service_agents` l.5944–5963 | Unprovisioned service agents stop `walle armor` mid-way; the stubs hide it | `gcloud beta services identity create` first. PENDING instead of stop |
| S175 | script l.4250–4256, l.4144, l.5231–5235 | On the identity path, `walle-agent@` keeps invoker on both services | Remove it after binding the principal |
| S176 | `cmd_consent` l.3928–3943; SETUP Phase 9 verify l.1161–1198 | The printed verify script does not exist | `walle consent --verify` |
| S177 | `selftest.sh`; setup/README l.690 | 220/220 against stubs is read as evidence the build works. No real flag, API or OAuth behaviour is exercised | Reword the claim. Add a live read-only mode against a sandbox |
| S178 | SETUP §1.7 guard l.299–303 | The guard warns on every source in Phases 1–9, and re-sourcing wipes in-shell values | A per-phase `need` helper. Write values into the file |
| S179 | SETUP Phase 1 verify l.356 | The verify fails once `eve@` exists in the OU | Expect `$ROBOT` and `$EVE_ROBOT` |
| S180 | SETUP Phase 3 l.457–468, G4, G5 | The Less secure apps row cannot be performed (retired 2025-05-01), and three console paths are wrong | Delete the row. Correct the paths |
| S181 | SETUP Phase 5 verify l.537–551 | Login events need `privateLogViewer`, which no prerequisite lists | Add the role, via PAM |
| S182 | SETUP Phase 9 rollback l.1200–1211, §7.1; `cmd_rollback` 9 | Rollback requires a robot sign-in, which is itself an incident | Revoke the grant from an admin account |
| S183 | SETUP Phase 8 rollback l.1088, Phase 7 l.899–910 | A deleted custom role blocks a re-run for up to 44 days. Phase 7 rollback deletes the project | `roles undelete`. `firestore databases delete` |
| S184 | SETUP Phase 11 l.1428–1432, l.1512–1513 | No `--use-partitioned-tables`, so sharded tables appear and the expected name never does | Add the flag. Fix the expectation |
| S185 | SETUP Phase 11 verify 5 l.1515 | No way to publish with a chosen message id | Snapshot and seek |
| S186 | SETUP Phase 6 verify l.699–720, Phase 10 rollback l.1352 | The super and dispatcher roles are never read back. Rollback leaves the super service and repository | Add reads and deletes |
| S187 | SETUP 12b l.1781, l.1798 | `exit 1` closes the sourced shell and loses variables | `false` or `return 1` |
| S188 | SETUP 12b step 2 l.1755 vs l.1567–1571 | The check reads a requirements file the deploy does not use | Deploy from `agent/requirements.txt` |
| S189 | SETUP 12c l.1874–1884, l.1905–1919 | Step 2b fails with ALREADY_EXISTS | Drop the response template from step 2 |
| S190 | SETUP Phase 12 verify 6 l.1706–1711 | Inherited and non-aiplatform conferring roles are not shown | `gcloud asset analyze-iam-policy` on the engine |
| S191 | SETUP Phase 16 l.2394–2405, l.2447 | Verify runs before `users.watch` was ever called | Run the renew job first |
| S192 | SETUP Phase 16 l.2383–2389 | Dead-letter forwarding for inbox messages lacks the subscriber grant | Add the binding |
| S193 | SETUP §4 test 2 l.2532 | Cloud Run rejects a bad audience with 401 before the app runs | Expect 401 at Cloud Run |
| S194 | SETUP §4 l.2621–2624 | The recorded run lacks flags and runs at one instance | `tee` the first run |
| S195 | SETUP §5 l.2654, l.2685 | Two pass targets for K0 | One target from ARCHITECTURE 4.6 |
| S196 | SETUP l.2496, l.2706, l.2758, l.2776 | Circular Stage 0 exit condition | Split §6.1 before and after the record |
| S197 | SETUP §7.1 l.2837–2847, §7.9 l.2972–2979 | The broad client is omitted from the wrong-account fix. The loop fix uses interim sinks | Add the broad client. Platform form first |

#### Eve

| Id | Location | What goes wrong | Fix |
|---|---|---|---|
| S198 | Eve Phase 10 l.1319–1325 | The console audience is `walle-operators@`, outside Eve's line and outside the severity 1 rule | `eve-console-readers@` owned by `eve-owners@` |
| S199 | Eve Phase 9 verify 1 l.1097–1105 | Checks three of Wall-E's five secrets, missing the super ones | Loop over all five |
| S200 | Eve l.1148–1151, l.1930–1933 | The camelCase projection prints empty, so the lock is never confirmed | `default(retention_policy)` and assert `isLocked` |
| S201 | Eve l.1064–1067, l.1180–1183, l.1676–1679, l.2020–2022 | An owner can remove the lien. The text says deletion is impossible | Reword. Alert on `DeleteLien` |
| S202 | Eve Phase 3 verify l.431–434 | `ROWS` is a reserved word | `COUNT(*) AS row_count` |
| S203 | Eve Phase 8 verify l.882–896 | The 403 proves the scopes, not the role | Add a `roles.get` privilege check |
| S204 | Eve Phase 11 step 4 l.1838–1847 | `--target_dataset` does nothing for DML configs | Update the query parameter. Repoint readers |
| S205 | Eve Phase 11 l.1688–1732 | The signer binding comes before audit logging, and a whole-policy write can drop bindings | Audit config first, with etag and diff |

#### Mo

| Id | Location | What goes wrong | Fix |
|---|---|---|---|
| S206 | Mo-9 l.1398–1418, l.1440–1443 | `eve/config` branch protection and validator read access are not configured | Per-repository steps and MD tests |
| S207 | Mo l.526–530 | `dataEditor` lacks `datasets.update` for target-dataset configs | Correct the sentence. Keep DML only |
| S208 | Mo l.254–260, l.268–272, l.276–281 | The service count regex matches extra services. The floor check has no command. Rollback deletes a factory project | Exact names. Inline the command. Roll back through the register |
| S209 | Mo-7 l.1207–1210 | Scheduler headers do not reach the job, so there is no idempotency | Key on the ISO week in the object name |
| S210 | Mo-9 l.1348–1352, l.145 | The bucket is in EU, not `europe-west1`, and the global name may be taken | `--location=$REGION`. Project-prefixed name |
| S211 | Mo l.1614–1616, l.1654–1663 | `GEMINI_PROJECT` is not exported. Legs have no command. Group entries are uninspected | Export. Write the lines. Assert the access count |
| S212 | Mo l.243–245, l.762–767, l.718–720 | Hand budget duplicates the factory's. Wrong metric count. `MERGE` key lacks `agent_id` | Drop the budget. Correct the count. Add `agent_id` |
| S213 | Mo-9 l.1367–1379 | Hand edit of the whole project IAM policy for audit config | Scripted merge with etag and diff |

## 5. Findings refuted

Only one register finding was refuted by both lenses. The second table lists claims refuted
inside findings that otherwise stand, so that nobody re-raises them.

| Id | Claim | Why it was refuted |
|---|---|---|
| S013 | `walle workspace` fails on day one because the operator OAuth client's project is unnamed and has no Admin SDK or Groups Settings API | [../wall-e/PREREQUISITES.md](../wall-e/PREREQUISITES.md) §5.1 row 1 (l.206) requires an existing project for the M0 client with both APIs enabled, and gives the check. The hand-check table (l.455–456) repeats it. Residue only: the printed M0 block does not repeat the requirement |

| Id | Claim refuted | Reason |
|---|---|---|
| S001 (fix) | Dry-run all of B1–B22 for 14 days | Google's dry-run page (checked 2026-09-15) supports dry run only for custom constraints, managed constraints and four legacy ones (`restrictServiceUsage`, `restrictEndpointUsage`, TLS versions, TLS cipher suites). Other constraints error in dry run |
| S017 (part) | The three deny-policy permission names are unsupported | They are on the list verified in 04 §3 on 2026-09-13 |
| S019 (part) | The manual fallback has no source for its parent folder id | PREREQUISITES §7.2 l.345 gives the `WALLE_FOLDER_ID` lookup. The folder itself does not exist, which stands |
| S023 (part) | The budget command fails with 403 for a missing quota project | gcloud's `billing/quota_project` defaults to the current project, where the API is enabled |
| S060 (part) | The operator consents to Eve's wrong scope set | Eve Phase 8 lists the ten scopes and its verify enforces them. Only the stale script constant remains |
| S068 (part) | The only programme-level figure is "a working week" | SETUP §0.4 names the critical path, "weeks to months" for the gate, and code "measured in weeks" |
| S072 (part) | The fallback contradicts itself on denyAdmin, and §6.1 cannot accept a fallback | PREREQUISITES l.145 covers denyAdmin for the fallback. §6.1 l.2752 allows a recorded exception. The principal form and unverified names stand |
| S074 (part) | The IAP YAML files are never written | `walle_setup.py` generates them. Only the hand path lacks them |
| S089 (part) | Deleting `walle_audit` leaves no evidence copy | Eve's daily mirror holds `actions`. The other eight tables and the undelete trap stand |
| S112 (part) | The project-level grant creates a new path to the refresh tokens | `roles/pubsub.serviceAgent` already carries those permissions. Conformance with Google's narrower instruction stands |
| S115 (part) | Passing a raw ADK agent yields an engine without ADK methods | The SDK wraps `BaseAgent` in `AdkApp` itself |
| S120 (part) | The ingress gateway binding is refused on a service-account engine | The binding is accepted. Gateway-mediated Model Armor does not apply without Agent Identity |
| S129 (part) | Eve is built with one path by mistake | A documented deferral on P34 and P19 |
| Second round, not raised | Access Transparency needs a support package | Documented as a default control of every organisation (checked 2026-09-15). The Access Approval support requirement is still unresolved (§7) |
| Second round, not raised | External sandbox clients need Google verification | Exempt when trusted in the tenant's Admin console (Google Cloud Help 13464323, checked 2026-09-15) |
| Second round, not raised | Agent Gateway may be unavailable in `europe-west1` | Supported, GA 2026-06-18 (Google's agent locations page, updated 2026-09-14) |
| Second round, not raised | A quota defaults to zero for a service the procedures use | None found. Model Armor, Agent Runtime, Admin SDK, Logging, KMS, Cloud Run and Budget API limits were all checked |

## 6. The fix plan

The fix plan is in order. The first items unblock the first stages. Effort is writing effort
by one person, and elapsed time is shown where it differs.

| # | Work | Files | Effort | Unblocks |
|---|---|---|---|---|
| 1 | **Start the long-lead items and close the stage-1 decisions.** P10, P11 (SCC payer), P13, P14 (domain, edition, billing, two witness admins), P22 moved to before Tier R, P31 (billing sub-account and administrator), decision 6 (a GA model on the `eu` endpoint), decision 29 moved to before the grant, decision 44 or CC-33, M-7, Mo dataset rename. Send D7. Start Mo-0. Open purchases in lead-time order | [12-open-decisions.md](12-open-decisions.md); [../wall-e/PREREQUISITES.md](../wall-e/PREREQUISITES.md) §1, §3.1, §9; `wall-e/09-open-decisions.md`; `eve/09-open-decisions.md`; `mo/08-open-decisions.md` | 2–3 days; weeks to months elapsed | Stages 1–3; every later stage's inputs |
| 2 | **Resolve the design contradictions the procedures would inherit.** Gate split: the P-SA row merges with the checklist pending; P1 gates only the credential; nonprod exempt (S008, X-ORG-13). G-4 evidence from the twin (S039). Witness admin rule (X-ORG-05). Twin OAuth form (X-ORG-01). Witness alarm cadence and severity 1 route (X-ORG-06, X-ORG-07). `deny-improvers` vs Mo-6 (S063). `ent-ge-admin` approval model (X-GE-12). D8 eu only (X-GE-13). Deny-policy principal form (S072). Evidence bucket location (S135). SCC activation order (X-RQB-04) | [01-hld.md](01-hld.md) §13.2; [02-landing-zone-and-tiers.md](02-landing-zone-and-tiers.md) §1.3, §3.5, B5; [03](03-gemini-enterprise-environment.md) §4; [04](04-identity-and-privileged-access.md) §3, §5.2; [07](07-monitoring-detection-incident-response.md) §7–§8; [08](08-data-logging-retention-sovereignty.md) §5.4; [11-tisax.md](11-tisax.md) §6.3; [../project-topology.md](../project-topology.md); `eve/03-lld.md`, `eve/05-stages.md` | 3–4 days | Items 3, 5, 8, 9 can be written without contradiction |
| 3 | **Write the platform bootstrap runbook (M1) and its prerequisites (M2).** B0 billing and organisation roles; roster; break-glass; groups; folders and log location; core projects and WIF; PAM with `ent-org-sink`; B1–B22 with supported dry runs; deny and PAB; central logging and billing export; registry and drift; factory modules including `platform-core`; negative test; Tier R record. Plus the Terraform factory repository | new `agentic-platform/14-platform-bootstrap-runbook.md`; [README.md](README.md) builder order; [../../runbooks/README.md](../../runbooks/README.md); [02](02-landing-zone-and-tiers.md) §3.3; [01](01-hld.md) §3.2; Terraform repository (to be created) | 2–3 weeks for the runbook; the factory code is additional build work | Stages 5–16; Tier R; SETUP Phase 6, Eve Phase 1, Mo-1 |
| 4 | **Publish the build-order page** from §2 of this page, with Who, hands-on and elapsed per sitting, build-log and evidence locations, and the cross-runbook re-run points. Mark SETUP Phase 6, Eve Phase 1 and Mo-1 step 0 "not runnable until M1" | new `platform/BUILD-ORDER.md`; top of SETUP.md, eve/07, mo/07 | 1–2 days | Single-operator planning; S066, S067, S069, S070 |
| 5 | **Rewrite 03 §16 as a live-app-safe procedure.** Inventory first. Allow-list = union with dry run. Groups filled before grants are removed. No retention reduction. CMEK as a decided step. Exact constraint values. `eu` templates. Throwaway-app spike for the gateway extension, import and unbind. SCC-based Tier C detections. CI permissions | [03-gemini-enterprise-environment.md](03-gemini-enterprise-environment.md) §3–§16; [06](06-gateways-model-armor-perimeter.md) §3.3, §3.5; [08](08-data-logging-retention-sovereignty.md) §4.1; [09](09-supply-chain-secrets-recovery.md) l.252, l.284; P49, P50 | 1 week plus a throwaway-app spike | Stages 17–20; Tier C |
| 6 | **Fix Wall-E's blocking and security-critical defects.** REST engine lock (S024). Remove `expressUser` (S105). Lock before deny (S017). Owner on the fallback (S018). Five secrets and the super deploy (S020, S021). Build in CICD with Binary Authorization (S006, S022). Phase 12 order and gateways (S025, S075). Spike subcommand (S015). Allowlist update (S016, S117). Model-invoke role and `eu` model client (S026, X-RQB-01). Factory approvers (S011). Tenant-wide Phase 3 rows to gate day (S012). Nine audit tables and two writers (S093, S109). No group invoker (S095). Platform sink detection (S094). Floors read-only (S096). Strict stage0 (S101). Granted-scopes check (S098). Token cache (S087). No `eve@` (S088). `--project` everywhere (S071). Two milestones (S010) | [../wall-e/SETUP.md](../wall-e/SETUP.md); [../wall-e/PREREQUISITES.md](../wall-e/PREREQUISITES.md); [../wall-e/setup/walle_setup.py](../wall-e/setup/walle_setup.py); [../wall-e/setup/walle.env.example](../wall-e/setup/walle.env.example); [../wall-e/setup/README.md](../wall-e/setup/README.md); selftest | 1.5–2 weeks | Stages 21–27, 34–36 |
| 7 | **Write the Wall-E approval surfaces (M7)** and fix the kill-switch drills (S076, S106, S126, S127), the denial suite fixtures (S091, S124, S125) and the pre-grant or post-grant verify tags (S122) | [../wall-e/SETUP.md](../wall-e/SETUP.md) new phase, §4, §5, §7; `wall-e/03-lld.md` | 1 week, plus service code | G12–G14; §5 drills |
| 8 | **Fix Eve's runbook and commit its inputs.** Factory Phase 1 (S027). Schemas, SQL, `thresholds.yaml` and code prerequisites (S028–S030). API enablement (S031). Grants (S032, S033). Beta command (S034). Decision gate before Phase 8 (S035, S140). View column (S036). Export job (S037). `eve@` creation order (S038). Consent command (S040). Gated bucket with CMEK (S041). Majors S128–S143 | [../eve/07-build-runbook.md](../eve/07-build-runbook.md); `eve/03-lld.md` §9; `eve/05-stages.md` G-4; Eve repository (to be created) | 1 week for the runbook; Eve code per the brief's estimate (36–45 engineer-days) | Stages 24, 30; G1 |
| 9 | **Write the witness runbook (M5)**, owner IT security, using item 2's rules: domain, tenant, admins, billing and support; W-2 bucket and dataset; W-3 managed plus legacy constraint order; W-4 heartbeat, export alarms and billing alarm; records step | new witness runbook page; [../project-topology.md](../project-topology.md) §7.5; [../eve/07-build-runbook.md](../eve/07-build-runbook.md) 10b | 3–5 days; weeks elapsed (domain, billing, people) | Stages 7, 29; G1, G18; the grant |
| 10 | **Write SCC, SIEM and pager onboarding (M3) and K7 (M4)**, and add G19 and G20 to the gate | [07-monitoring-detection-incident-response.md](07-monitoring-detection-incident-response.md); [04](04-identity-and-privileged-access.md) §9; SETUP Phase 2; [11-tisax.md](11-tisax.md) §6.3 | 1 week; SIEM and MDR contracts take months | Stages 9, 16, 28; G2; the P line |
| 11 | **Write the sandbox tenant and P-SA twin runbook (M6)** with sandbox-organisation logging, External-trusted twin clients, nonprod folder member constraints and split drills | new twin runbook page; [02](02-landing-zone-and-tiers.md) §3.5; SETUP Phase 2; `eve/05-stages.md` | 1–2 weeks; weeks elapsed (purchase, domain) | Stage 32; G10, G11, G14, G-5, G-7 |
| 12 | **Fix Mo's runbook and commit its inputs.** Factory call (S042). Inputs (S043). Wilson constant (S044). Assertions (S045, S145). CI identity from the `CICD_PROJECT` pool (S046). Watermark writer (S152). Agent-neutral names (S144). Majors S146–S155. Model Armor project floor (X-RQB-08). Validator custodian (M8). First merged proposal (M9) | [../mo/07-build-runbook.md](../mo/07-build-runbook.md); `mo/03-metrics-contract.md`; `mo/04-artefacts-and-proposals.md`; `wiki/_sync/wiki_sync.py` (S064) | 1 week for the runbook; Mo code per the brief's estimate (24–37 person-days) | Stages 25, 31, 37, 39 |
| 13 | **Sweep the minor findings and the cross-runbook re-runs**, and add a live read-only mode to the self-test against a sandbox project (S177) | all four procedures | 3–4 days | Fewer traps at the keyboard; real error texts for PENDING handling |
| 14 | **Verify the 46 second-round findings** with the two-lens method before items 5, 9 and 11 act on them | this page §4.6 | 1–2 days | Confidence in items 2, 5, 9, 11 |

## 7. What this review did not cover

- **Nothing was run against a live tenant, organisation or project.** No credentials were used.
  Every "fails with" is read from Google's documentation or from code, not observed. The
  self-test's 220 of 220 exercises stubs, not real commands (S177).
- **Code and configuration that do not exist** could not be reviewed: the Terraform factory,
  the Wall-E, Eve and Mo service code and images, the Eve and Mo schemas and SQL.
- **The design pages were read for what the procedures need, not re-reviewed.** The
  correctness of the EU AI Act and TISAX positions, of the threat model and of the brief's cost
  and effort figures is out of scope.
- **Unverified items:**
  - The 46 second-round findings (§4.6), and the 58 register minor findings (§4.8).
  - Access Approval prerequisites are contradictory. Google's pricing page (checked
    2026-09-15) says Access Approval "is included with" Standard, Enhanced or Premium Customer
    Care. The Access Approval overview (updated 2026-09-03) names only Access Transparency.
    Ask Google before W-2 is written.
  - Whether a Workspace customer id in the legacy domain constraint admits another
    organisation's logging writer identity (X-ORG-03). Test with a dry-run grant.
  - Whether Directory API reads of another customer's users and groups fail (X-ORG-03).
  - The purchase route for a second Workspace customer and for the witness billing account
    (reseller or account team, finance). Vendor lead times for MDR and the penetration test
    are assumptions.
  - Dry-run support for the Gemini Enterprise managed constraints was not confirmed on their
    own pages.
  - The custom MCP managed constraint is documented only by display name.
  - Context-Aware Access for Gemini Enterprise is in rollout until 2026-09-23.
  - The BigQuery Data Transfer Service limits page returned 404, so DTS quotas were not
    checked.
  - Cost figures in X-RQB-04 and X-RQB-07 come from Google pricing pages checked on
    2026-09-15, in USD. Tenant log volume is unmeasured.
  - Model endpoint availability (X-RQB-01) changes often. Re-check on the day decision 6 is
    closed.
- **Resume after interruption and the kill-switch drills** were covered only in part (S014,
  S160, S167, S170; S052, S126, S127, S182, S195). A full resumability pass over each phase was
  not done.
- **Human availability** was checked for the gate lines only. The rota, training records and
  incident commander duties of [01-hld.md](01-hld.md) §0.3 were not examined against the
  procedures.
