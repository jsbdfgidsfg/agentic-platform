# A. Glossary

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14

## What this appendix gives you

By the end you can look up any identifier, term, product or abbreviation in one line, with the chapter that explains it ("Ch. N"), and tell apart families that share letters. Facts are the design pages' on 2026-09-14, launch stages as recorded on 2026-09-13; where they disagree with this appendix, the design page is right.

## Identifier families

| Family | What it numbers | Ch. |
|---|---|---|
| R1–R16 | The sixteen requirements drawn from the objective of 2026-09-13 | 2 |
| CP1–CP6 | The six containment primitives | 4 |
| PR1–PR9, D1–D12 | Charter promises to every agent; demands on every agent | 4 |
| B1–B7 | Trust-boundary template; B6 and B7 are fleet boundaries | 5 |
| GE-0..GE-14 | Tenant-app baseline runbook; GE-14 closes the Tier C gate | 6 |
| C, R, W, P, P-SA, X | Tiers: classical, read tools, write agents, privileged, the super-admin singleton, AGI-class (closed) | 7 |
| CC-1..CC-12 | Folder custom constraints; the brief cites CC-3, CC-6, CC-8 and CC-11 | 24 |
| SA-1..SA-7 | Service-account policy rules | 8 |
| R1–R6 | Rules of the folder deny policy `deny-agents-platform` | 8 |
| K7, KF-1..KF-4 | Fleet kill switch; its levers, applied in the order KF-1, KF-3, KF-4, KF-2 | 8 |
| L0–L5 | Ladder levels, from off to autonomous with independent verification | 9 |
| T0–T3 | Trigger classes: chat, scheduled, event, inbox | 9 |
| F1–F4 | Organisation-owned SIEM feeds | 11 |
| SA-01..SA-09, SG-01..SG-07 | Super-admin detection rules, Workspace and GCP-organisation side | 11 |
| PL-01..PL-15 | Platform-wide detection rules | 11 |
| H-1..H-4 | Pipeline heartbeats | 11 |
| S1–S9 | Clauses of the SIEM contract (P92) | 11 |
| RB-01..RB-11 | Incident runbooks; RB-10 and RB-11 are the regulatory clocks | 11 |
| R-A, R-B, R-C, R-D, R-K, R-W | Recovery classes | 13 |
| Bands A, B, C | Wall-E's lanes: catalogue, generic request approved by two human super admins, console handoff | 15 |
| F1–F10 | Wall-E's operation families | 15 |
| S0–S5 | Stages, keyed to Wall-E and used by Eve and Mo; durations in Ch. 24 | 15 |
| Phase 1..Phase 18 | Build phases of Wall-E's setup runbook, SETUP.md; never stages | 23 |
| K0–K6 | Wall-E's kill switches, K0 halt to K6 remove Super Admin | 15 |
| G-1..G-7 | Checklist rows for Eve's observe-and-report layer before the grant | 16 |
| T0–T2 (Mo) | Mo's tiers: metric queries, `mo-reporter`, optional `mo-narrator` | 17 |
| MD-1..MD-15 | Mo's denial tests | 17 |
| R1–R6 (Mo) | Mo's accepted residual risks | 17 |
| CC-1..CC-37 | Contract changes Eve's design forces on Wall-E's set | 18 |
| N1–N9 | Wall-E's must-never-happen statements, the blast-radius ceiling | 19 |
| R-01..R-17 | Platform risk-register rows; R-01 is the super-admin deviation (P140) | 19 |
| E-01..E-15 | EU AI Act evidence register | 20 |
| P1–P143 | Platform decisions, one sequence; new ids from P144 | 25 |
| Wall-E 1–52, E-1..E-21, M-1..M-11 | Agent-set decisions; 42–52 are recorded on the project topology page, so "topology decision 42" in Ch. 5 is Wall-E decision 42 | 25 |

## Families that share letters

- **T.** T0–T3 are always trigger classes. Tiers are letters because an earlier numbering, T0–TX, would have shared those symbols; it maps to C, R, W, P or P-SA, and X. Mo's T0–T2 are Mo's components, never tiers or triggers.
- **R.** A bare letter is Tier R. R1–R16 are requirements (Ch. 2). R1–R6 are deny rules in Ch. 8 and Mo's residuals in Ch. 17. A hyphen and a letter (R-A..R-W) marks a recovery class. A hyphen and two digits (R-01..R-17) marks a risk row.
- **P.** P and P-SA are tiers. P with a number is a decision: P3 is a spike, not a tier.
- **S.** S0–S5 are stages. S1–S9 are SIEM contract clauses (Ch. 11). `S-org` and `S-folder` are the two aggregated log sinks. A Phase is a build step of Wall-E's setup runbook, not a stage.
- **F, SA, CC, E.** F1–F10 are families, F1–F4 are feeds. SA-1..SA-7 (one digit) are service-account rules, SA-01..SA-09 (two digits) are detections. CC-1..CC-12 are folder custom constraints (Ch. 24), CC-1..CC-37 are Eve's contract changes (Ch. 16; Ch. 18). E-1..E-21 are Eve's decisions, E-01..E-15 are evidence rows. Eve's own register runs to E-21, while the platform pages cite E-1..E-20 ([../../eve/09-open-decisions.md](../../eve/09-open-decisions.md), [../12-open-decisions.md](../12-open-decisions.md)).
- **K.** K0–K6 stop one agent, Wall-E. K7 stops the fleet, and KF-1..KF-4 are its levers.

## Platform terms

- **Action service.** Deterministic Cloud Run service. From Tier W it is the only holder of the credential to the system of record, and it decides, audits write-ahead and verifies (Ch. 5; Wall-E's two in Ch. 15).
- **Admission gate.** The one CI run an agent must pass before it reaches prod, the registry, a gateway list or the tenant app (Ch. 9).
- **Assumption: / tbd / Unverified.** An inferred value kept as marked, including every cost figure / a value nobody has decided / a fact not checked against its source on 2026-09-13 (Ch. 0).
- **Blind sample, blind grader.** A weekly seeded sample per cell, graded by a named human who is not the playbook owner. Grading capacity caps Tier W (P25, open) (Ch. 17; Ch. 14).
- **Data class.** A store's label, which drives retention, readers and integrity: `evidence`, `content`, `control`, `record`, `secret`, `ops`. The page's heading says five classes and its table lists six (Ch. 12).
- **Decision states.** `decided`, `closed`, `proposed`, `open`, `spike`, exactly as the register defines them (Ch. 25).
- **Detection desk.** Whoever acknowledges pages. "Next business morning" below Tier P; bought SecOps with MDR, or the organisation's SOC, at Tier P (Ch. 23).
- **Deterministic by absence.** Eve's control path has no model because dependency, permission and API are absent (Ch. 16).
- **Dispatcher.** `walle-dispatcher`, band A only. It checks halt, owns `run_id` and budget before the agent runs (Ch. 15).
- **Drop box.** The `mo-proposals` bucket, where Mo may only create objects. CI turns each bundle into a pull request under a bot author that is not Mo (Ch. 17).
- **Enforcement-grade / detection-grade.** An enforcement-grade control refuses the action from outside the agent's process and stops on failure. A detection-grade control only produces evidence and never stands alone (Ch. 4).
- **eve_authority.** Setting per ladder cell, `advisory` or `binding`; absent means advisory. It is only ever lowered automatically (Ch. 16).
- **eve-advisor.** Eve's report-only reporting path. It may reason, but nothing it writes reaches a verdict (P34, proposed) (Ch. 16).
- **Factory.** Cloud Foundation Fabric modules with thin platform wrappers, run by Cloud Build from the register row and manifest (P35) (Ch. 7).
- **Fingerprint.** Prompt hash, model pin, framework version and Model Armor template version. A change resets cells above L3 (demand D9, Ch. 4); the fingerprint and its scoping rule are explained in Ch. 17.
- **halt_all.** Posture in which an action service executes nothing. A restored control plane boots into it (P120) (Ch. 15; Ch. 13).
- **Hard-denied list.** Operations refused in every band however many people approve. Together with the tier-SUPER two-person list it forms "the two lists" (P29, open; the register row words the second list differently, Ch. 25) (Ch. 15).
- **log_pipeline_silent.** Halt reason set when evidence goes silent. Every agent Eve verifies loses autonomy, both Wall-E action services go to `halt_all`, and one human call clears it (P97) (Ch. 11).
- **Manifest.** `agent-manifest.yaml`: what an agent is allowed to be, hashed into its register row (Ch. 9).
- **Observe-and-report layer.** Eve's detective layer, live and drilled before the grant. Eve's gate layer follows: halting and demoting at S3 entry, signing at S4 entry (Ch. 16).
- **Platform verifier.** Tier W verifier in Eve's deterministic shape, compiled from the manifest. It catches code bugs, not a wrong specification (P79, proposed) (Ch. 9).
- **Protected principals.** Principals no write may target: administrators, the robot, its unit, `walle-protected@` and the control groups (Ch. 15).
- **reconciliation_gap.** A robot-attributed Google event with no matching audit row. It halts Wall-E and pages severity 1 (Ch. 16).
- **Register / registry.** The register is one git YAML file per agent, the inventory of record. The registry is Google's Agent Registry, written only by CI, a discovery view that never authorises (Ch. 9).
- **Second human.** A human super admin in IT security, outside the Wall-E administration line. Eve owner and sole recipient of reports about the administrator (Ch. 23; Ch. 16).
- **Shadow agent.** An agent observed running with no register row. Severity 2 at Tiers C–W, 1 at P (Ch. 9).
- **Signed deviation.** The TISAX 4.2.1 least-privilege exception for the robot, recorded in P33's file. Awaits the security reviewer's signature and ISMS entry (P136) (Ch. 21).
- **Super-admin grant.** The day `walle@` receives Super Admin. It is a gate with its own checklist, and comes before Wall-E's S0 (Ch. 24).
- **Taint bit.** Set when attacker-writable content reaches a run's model. The run takes the inbox ceiling for life (Ch. 15; injection surface in Ch. 10).
- **Tier gate.** Rule that a tier opens only when the people and bought services it needs exist (Ch. 24).
- **Validator custodian.** Runs the one platform validator in `VALIDATOR_PROJECT` (the security reviewer from Tier W). Refuses any cited number it cannot recompute (Ch. 9).
- **walle@.** The dedicated licensed Workspace user account holding Super Admin. P33 was decided on 2026-09-13; deviation signatures pending (Ch. 15).
- **Witness organisation (`org-witness`).** Separate Cloud Identity organisation run by IT security, holding Eve's evidence copy and alarms beyond the tenant's super admins (P14, open) (Ch. 16).

## Google products and features

- **Agent Gateway.** Managed ingress and egress proxy with IAM access policies and Model Armor; GA 2026-06-18 (Ch. 10).
- **Agent Identity.** Keyless, Google-issued agent principal with daily certificates. GA on Agent Runtime, Preview on Cloud Run (P5, open) (Ch. 8).
- **Agent Registry.** Catalogue of agents, MCP servers and endpoints; GA 2026-06-18, standalone skills Preview (Ch. 9).
- **Agent Runtime.** Google's managed runtime for agent engines. Its code-execution sandbox is off across the fleet (P121) (Ch. 8; Ch. 14).
- **Assured Workloads.** EU Data Boundary package not adopted (P110) (Ch. 12).
- **Binary Authorization.** Attestation policy per agent project (P115). On Cloud Run, breakglass is the only bypass (Ch. 13).
- **Cloud KMS Autokey.** Folder-level automatic CMEK keys created in `KMS_PROJECT`; Firestore unsupported (Ch. 13).
- **Context-Aware Access.** Access levels. On the robot's Admin console access it counts as detection plus friction until Google confirms it binds super admins (P7, open) (Ch. 8).
- **Gemini Enterprise.** The tenant app in `GEMINI_PROJECT`, the one human front door. Workflow Builder, formerly Agent Designer, builds Tier C agents (Ch. 6).
- **GKE Agent Sandbox.** gVisor-isolated sandbox, GA since 2026-05-21; the recorded Tier X sandbox (P122) (Ch. 14).
- **Google SecOps.** Google's SIEM. Proposed default is an instance in the Europe multi-region with at least 400 days of retention (P93); the choice itself is P10, open (Ch. 11).
- **Model Armor.** Prompt and response screen; its gateway integration went GA on 2026-06-24. As a probabilistic screen it is never a trust boundary (Ch. 10).
- **Multi-party approval.** Workspace setting requiring a second admin for covered changes. It is the only Google-enforced two-person rule over the robot (P66) (Ch. 8).
- **Principal Access Boundary.** Enforcement-grade for engine queries, secrets, keys, storage, BigQuery and Pub/Sub; no fence for Cloud Run invocation (P60) (Ch. 8).
- **Privileged Access Manager.** Time-boxed, justified, logged elevation: at most 7 days, no self-approval (Ch. 8).
- **Security Command Center Premium.** Organisation-wide findings, including AI Protection. Funding is P11, open (Ch. 11).
- **Semantic Governance.** Preview gateway policy judged by an LLM. It may add a refusal but is never an approval or evidence (Ch. 9).
- **Sensitive Data Protection.** Folder discovery, plus the de-identified copy `content_deid` (P108) (Ch. 12).

## Regulatory terms

- **The Act.** Regulation (EU) 2024/1689. The Digital Omnibus on AI, Regulation (EU) 2026/1744, defers Annex III obligations to 2027-12-02 (Ch. 20).
- **Provider / deployer.** The provider builds a system and puts it into service under its own name; the deployer uses it. The organisation is both for Wall-E and Mo; which legal entity is P23, open (Ch. 20).
- **Annex III.** The high-risk use list. Point 4(b) covers task allocation and monitoring in work relationships (Ch. 20).
- **Art. 6(3) derogation.** An Annex III system is not high-risk if a narrow condition holds and no profiling occurs. Wall-E's register class is `annex_iii_adjacent` (Ch. 20).
- **General-purpose AI.** The model provider's regime. The platform hosts third-party models and never trains or substantially modifies them (Ch. 20).
- **Serious incident.** Art. 3(49) event with Art. 73 deadlines of 15, 10 and 2 days, run voluntarily until a row is high-risk (P101) (Ch. 11).
- **TISAX label / assessment level.** A site earns a label by assessment, never a platform. The target is Confidential (Assumption) at AL2 (Ch. 21).
- **ISA2027.** The questionnaire used for assessments ordered from 2027. ISA 6.0.3 is in force until then (Ch. 21).
- **Maturity level.** Score on the ISA 0–5 scale. The target for most controls is 3, "established" (Ch. 21).

## Abbreviations

CAA Context-Aware Access (Ch. 8) · CMEK customer-managed encryption keys (Ch. 13) · DPIA data protection impact assessment (Ch. 22) · DPO data protection officer (Ch. 22) · DWD domain-wide delegation, never used (Ch. 8) · HSM hardware security module (Ch. 13) · ISMS information security management system (Ch. 21) · MDR managed detection and response (Ch. 11) · MPA multi-party approval (Ch. 8) · PSC Private Service Connect (Ch. 10) · RACI responsible, accountable, consulted, informed (Ch. 23) · SCC Security Command Center (Ch. 11) · SHA Secure Hash Algorithm, SHA-256 throughout (Ch. 13) · SIEM security information and event management (Ch. 11) · SLSA Supply-chain Levels for Software Artifacts, Build Level 3 (Ch. 13) · SOC security operations centre (Ch. 23) · VPC-SC VPC Service Controls, perimeter model (a) (Ch. 10) · WIF Workload Identity Federation (Ch. 7).

## Key decisions and what to read next

This appendix decides nothing; the states it quotes (P33 decided; P34, P79, P93 proposed; P5, P7, P10, P11, P14, P23, P25, P29 open) are the register's (Ch. 25).

- Families and states: [../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded](../01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded), [../12-open-decisions.md#1-how-this-register-works](../12-open-decisions.md#1-how-this-register-works)
- Collisions: [../02-landing-zone-and-tiers.md#11-letters-not-numbers-and-how-the-briefs-t0tx-map](../02-landing-zone-and-tiers.md#11-letters-not-numbers-and-how-the-briefs-t0tx-map), [../../mo/01-hld.md#the-three-tiers-and-the-seam-between-them](../../mo/01-hld.md#the-three-tiers-and-the-seam-between-them), [../04-identity-and-privileged-access.md#3-the-folder-deny-policy-deny-agents-platform-with-verified-permission-names](../04-identity-and-privileged-access.md#3-the-folder-deny-policy-deny-agents-platform-with-verified-permission-names)
- Vocabulary: [../05-registry-and-autonomy-contract.md#1-vocabulary-four-things-that-are-not-each-other](../05-registry-and-autonomy-contract.md#1-vocabulary-four-things-that-are-not-each-other), [../../wall-e/13-agent-interconnection.md#1-seven-things-with-confusable-names](../../wall-e/13-agent-interconnection.md#1-seven-things-with-confusable-names)
- Products and law: [../01-hld.md#19-sources](../01-hld.md#19-sources), [../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer](../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer), [../11-tisax.md#2-the-target--label-level-scope-catalogue-p133](../11-tisax.md#2-the-target--label-level-scope-catalogue-p133)
