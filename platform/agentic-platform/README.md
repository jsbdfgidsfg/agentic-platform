# Agentic platform

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-18
- 2026-09-18: the page counts corrected to fifteen pages (00–14) and the register of record to
  P1–P204 (Status, Documents row 12, Maturity, with a Maturity row for the three build sets);
  the builder's step 7 no longer says the Tier C runbook needs no factory — it imports the app's
  project through the factory's `tenant-app` module and runs after Tier R (setup/README §3.1,
  SD-13).
- Maturity: **design — nothing built.** No folder, no factory run, no project made by the
  factory, no gateway, no registry entry, no sink, no SIEM, no witness organisation, no robot
  account with Super Admin. The four projects of [../project-topology.md](../project-topology.md)
  are decided and not created. Every page in this set is a design of something that does not
  exist on 2026-09-13, written so that a security reviewer can find what is enforced and what
  is only detected, and so that whoever builds it can start from the factory and the register
  without re-deriving a decision.
- What this set is: fifteen design pages (00–14), three build sets (setup/, pov/, 3-day/) and
  the brief. [01-hld.md](01-hld.md) is the parent; pages 02–11 each detail one part of it and
  record their decisions; [12-open-decisions.md](12-open-decisions.md) is the register of record,
  P1–P204 (P144–P191 proposed by the setup procedures on 2026-09-15, P192–P204 by the proof of
  value on 2026-09-16).
- Objective: `.agent-work/OBJECTIVE.md` (outside the wiki), restated in
  [00-objective-review.md](00-objective-review.md) §1. No page loosens the platform's standing
  constraints — no domain-wide delegation, no credential in the model, humans raise autonomy,
  and Wall-E's Super Admin (P33) designed around rather than re-argued — stated in full in
  [01-hld.md Status](01-hld.md#status).
- Cross-checked on 2026-09-18: [14-crosscheck-review.md](14-crosscheck-review.md) reviewed the
  whole set — objective, design pages, register, brief, the three agent sets, setup/, pov/,
  3-day/ and the two decision records — and lists 65 findings (4 high, 35 medium, 26 low); 38
  of them, every high and medium row, were fixed in their pages the same day, the twenty-eight
  three-day corrections were carried, and 27 low rows stay open; its §8 names what must still
  change before the documents are handed to HR, security, compliance, architecture and the board.
- Added 2026-09-18, written from the same review: [plain/](plain/README.md), the platform in
  plain words for any reader; [audiences/](audiences/README.md), one document each for HR and the
  works council, the security team, compliance and regulation, enterprise architecture, the board
  (a deck with speaker notes) and the sponsor (the executive brief); and [pitch/](pitch/sales-presentation.md),
  the sales presentation and the pitch scripts. None of them defines a fact; every number in them
  links to the page that does.
- Conventions on every page: `Assumption:` marks inferred facts; *tbd* marks values nobody has
  decided; every Google product, launch stage, IAM role, organisation-policy constraint, API,
  article and date carries a source verified on 2026-09-13 or says "unverified"; no company
  names, no secrets, no person named for a role; every control names its owner (a role from HLD
  §0.3), the resource it sits on, how it is verified (a job, a drill or a CI check, with a
  cadence) and what happens when it fails (fail-closed, fail-open with a page, or a detection
  with a latency) — a control that cannot fill those four cells is not on the page; controls are
  graded enforcement or detection by the rule of [01-hld.md](01-hld.md) §0.2.

## What the platform is

A Google Cloud landing zone — one folder tree, one factory, one register — on which an
organisation can run hundreds of agents, classical or autonomous, behind the Gemini Enterprise
tenant app as the one front door ([01-hld.md §0.1](01-hld.md#01-thesis)). Every agent gets the
six containment primitives CP1–CP6 ([§0.2](01-hld.md#02-the-six-containment-primitives-and-how-each-is-graded))
by the lettered tier it belongs to — C, R, W, P (P-SA the super-admin singleton), X — and a tier
does not open until the people and bought services it needs exist ([§11](01-hld.md#11-the-tier-model),
[§0.4](01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens)). Wall-E (the doer with
Super Admin), Eve (the deterministic controller with a witness outside the tenant) and Mo (the
improver that never touches production) are its first three tenants and the proof that its rules
can be met, not its definition.

## What it deliberately is not

It does not narrow a super-admin account, since nothing in Workspace or GCP can, and it does not
let any model produce an approval, a signature, a halt, a veto or a refusal. It does not make
Eve's control path structurally unreachable by a super admin inside the tenant's organisation,
does not run a SOC, and does not claim AGI containment (Tier X is closed). It does not promise EU
AI Act or TISAX outcomes, only the mechanisms and the evidence; the full list is
[01-hld.md §16](01-hld.md#16-what-the-platform-does-not-do).

## Documents

**Start here if you want the intent rather than the specification:** the architecture brief, [brief/README.md](brief/README.md), explains in about 200 A4 pages why the platform and its three agents are designed the way they are, and links to the pages below for every definition.

| Page | What it is | Decisions |
|---|---|---|
| [00-objective-review.md](00-objective-review.md) | The objective verbatim, the verdict on the documentation that existed before it, the gap register (111 gaps, 24 blocking), the 82-item brief the HLD had to answer (indexed to the register rows that answer it), and pointers to the two compliance frames | — |
| [01-hld.md](01-hld.md) | The parent: thesis and six primitives, the RACI and tier gate, the charter (promises and demands), the secure Gemini Enterprise environment, landing zone, identity, registry, gateways and Model Armor, monitoring, perimeter and sovereignty, supply chain, recovery, the tier model and fleet kill switch, the autonomy contract, the three agents, EU AI Act and TISAX frames, trust boundaries, what it does not do, and what it requires of the three agent sets (§18) | P1–P34 |
| [02-landing-zone-and-tiers.md](02-landing-zone-and-tiers.md) | The tier model in full, every folder named, project-per-agent and the factory (Fabric modules, CI identity, naming, labels, budgets, nonprod), the organisation-policy baseline and custom constraints, what is shared in `platform-core` and what stays per agent, and what is promoted from the Wall-E chapters | P35–P47 |
| [03-gemini-enterprise-environment.md](03-gemini-enterprise-environment.md) | The tenant app as the one front door: project and folder placement, administration through PAM, `eu` location and CMEK, identity provider, the user population's three gates, the feature baseline, console Model Armor, agent admission and revocation, the tenant egress gateway `gemini-egress`, connectors, audit logging, and the runbook to baseline | P48–P59 |
| [04-identity-and-privileged-access.md](04-identity-and-privileged-access.md) | The principal set of the fleet, the folder deny policy with verified permission names, the Principal Access Boundary and what it can fence, the PAM entitlement catalogue, IAP on every control surface, break-glass custody, the super-admin roster and multi-party approval, and the fleet kill switch K7 with its executor and drill calendar | P60–P70 |
| [05-registry-and-autonomy-contract.md](05-registry-and-autonomy-contract.md) | The register of record versus the Agent Registry, card metadata per tier, governance policies, the invariant "registered ⇒ feeding the SIEM", reconciliation against independent inventories, admission and revocation, the two compliance registers derived from the register, and the autonomy contract (manifest, schemas, validator, platform verifier, fleet defaults, peer rule) | P71–P80 |
| [06-gateways-model-armor-perimeter.md](06-gateways-model-armor-perimeter.md) | The gateway binding standard, gateway versus threat detection, the availability domain, Model Armor floors and the template standard per tier, tool-result screening, the perimeter models and the two spikes that decide between them, and how `wall-e/11` and `wall-e/13` are promoted | P81–P91 |
| [07-monitoring-detection-incident-response.md](07-monitoring-detection-incident-response.md) | Feeds, the SIEM contract and default instance, SCC Premium, the monitoring baseline module, the correlation contract, the detection catalogue as code, pipeline heartbeats and the silence halt, the platform reporting path, incident roles and targets, one incident record, runbooks per scenario, the regulatory clocks, tabletops and SOC metrics | P92–P103 |
| [08-data-logging-retention-sovereignty.md](08-data-logging-retention-sovereignty.md) | Every platform store classified, the central logging project and its two aggregated sinks, Data Access audit logging, the retention schedule and the lock rule, Sensitive Data Protection, sovereignty (Assured Workloads refused with reasons, Access Transparency and Approval, the EU model-pin rule), asset owners per project, and the key stance for its stores | P104–P114 |
| [09-supply-chain-secrets-recovery.md](09-supply-chain-secrets-recovery.md) | Binary Authorization and attested images, the vulnerability gate, HSM everywhere and the key project, secrets, CMEK exceptions, recovery classes and the restore-boots-halted mechanism, the code-execution tier, and AGI-class containment (what Tier X would be and why it stays closed) | P115–P124 |
| [10-eu-ai-act.md](10-eu-ai-act.md) | The regulatory state as amended, provider and deployer roles, the classification of every system (Wall-E's Art. 6 path, F7's profiling boundary, Eve, `eve-advisor`, Mo, the tenant app), the obligation crosswalk with owner and evidence per article, the evidence register, and what "bulletproof" can mean | P125–P132 |
| [11-tisax.md](11-tisax.md) | The target (label, level, scope), module scope, shared responsibility with Google and the supplier file, the control-by-control mapping, the super-admin deviation record, separation of duties as a counted minimum per stage, supplier onboarding and exit, assurance cadence, the risk register and the legal register | P133–P141 |
| [12-open-decisions.md](12-open-decisions.md) | The register of record: all 204 decisions in one sequence, grouped by the gate they block, with why each matters, the recommendation, owner, where it is recorded, the disagreements between pages, and the index into Wall-E's, Eve's and Mo's registers | P1–P204 |
| [13-setup-procedure-review.md](13-setup-procedure-review.md) | The review of the manual setup procedures (platform, Wall-E, Eve, Mo) on 2026-09-15: the verdict on whether setup can start, one master setup order across every procedure with the stages that have no procedure yet, the verified findings per procedure, and the ordered fix plan | — |
| [14-crosscheck-review.md](14-crosscheck-review.md) | The cross-check of the whole documentation on 2026-09-18: the verdict on whether the set answers the objective, every element checked against the others, objective against design against brief, the three build paths side by side with their hand-over chain, the security verdict and the standing risk per path, the dated path to the EU AI Act and to TISAX with the employee-data and works-council angle, the findings register X-01 to X-65 (4 high, 35 medium, 26 low), what is sound, and the short list that must change before the documents are handed to HR, security, compliance, architecture and the board | — |
| [pov/README.md](pov/README.md) | The proof-of-value build (added 2026-09-16): nine human-executed files that stand the platform and the three agents up at Tier C, R and W on the production tenant, with no Super Admin to any agent and no long-lead purchase, using the full build's names and schemas so that [setup/README.md](setup/README.md) continues from it and keeps the super-admin grant | — |
| [3-day/README.md](3-day/README.md) | The three-day build (added 2026-09-17): four human-executed files that two IT experts run in three business days and six person-days, standing up four projects, Eve over the admin audit log through the Reports API, a doer holding one organisational-unit-scoped Workspace admin privilege over four synthetic accounts with a forced dry run and a two-person approved execution, and Mo's scorecard. A demonstration of machinery under control, not compliance evidence and not a production grant; it hands over to [pov/README.md](pov/README.md) once its grants, custom admin role and synthetic accounts are unwound | — |
| [plain/README.md](plain/README.md) | The platform in plain words (added 2026-09-18): ten short pages for any reader — what is being built, the three agents, how it is kept safe, people and decisions, the law and the standards, three ways to start, what it costs and what you get, a glossary and the questions people ask; every term defined where it is used, every number linked to the page that defines it, nothing claimed beyond the source | — |
| [audiences/README.md](audiences/README.md) | The audience documents (added 2026-09-18): HR and the works council, the security team, compliance and regulation, enterprise architecture, the board and C-level presentation (seventeen slides and four backup slides with speaker notes, printed in [audiences/dist/](audiences/dist/)) and the executive brief; each written for an expert in their own field, defining nothing and linking to the page that does | — |
| [pitch/sales-presentation.md](pitch/sales-presentation.md) | The sales presentation (added 2026-09-18): seventeen slides and four backup slides with speaker notes for an audience outside the programme, printed in [pitch/dist/](pitch/dist/), with [pitch/pitch.md](pitch/pitch.md): the thirty-second, two-minute and ten-minute scripts, the demonstration storyboard, the objections with grounded answers, and the words never to use | — |

Two pages outside this folder are part of the design and are pointed at, not copied:
[../project-topology.md](../project-topology.md) (the four projects and every cross-project
grant, now factory inputs) and [../gemini-enterprise.md](../gemini-enterprise.md) (the tenant
facts runbook step GE-0 records).

## Reading order for a security reviewer

The question a reviewer asks is "what is enforced, what is only detected, and who can change
it". Read in this order and stop where the answer is enough:

1. [01-hld.md](01-hld.md) Status, "What this reverses and what it costs", §0.2 (the six
   primitives and their grade), §15 (trust boundaries), §16 (what it does not do). One sitting.
2. [01-hld.md](01-hld.md) §13.1 (Wall-E with Super Admin: the two lists, the thirteen
   compensations) and §13.2 (Eve, the witness, the second human). This is where the residual
   risk lives.
3. [04-identity-and-privileged-access.md](04-identity-and-privileged-access.md) — the deny
   policy with verified names (§3), what the PAB does and does not fence (§4), no standing
   owner anywhere (§5), the roster and multi-party approval (§8), K7 (§9).
4. [06-gateways-model-armor-perimeter.md](06-gateways-model-armor-perimeter.md) §2 and §4 — the
   gateway rule and why the perimeter is a spike, not a claim.
5. [07-monitoring-detection-incident-response.md](07-monitoring-detection-incident-response.md)
   §6 (the catalogue), §7 (silence halts), §8 (who is told when the report is about the
   administrator).
6. [08-data-logging-retention-sovereignty.md](08-data-logging-retention-sovereignty.md) §3–§5 —
   whether the evidence can be silenced or shortened, and by whom.
7. [09-supply-chain-secrets-recovery.md](09-supply-chain-secrets-recovery.md) §1 and §3 — what
   runs is what was signed; a restore cannot un-halt.
8. [11-tisax.md](11-tisax.md) §6 (the deviation record) and §7 (separation of duties as a
   count), then [10-eu-ai-act.md](10-eu-ai-act.md) §3.1 (the Art. 6 argument).
9. [12-open-decisions.md](12-open-decisions.md) §4 — every row that must be green before the
   super-admin grant, and which are still `open`.

Every control table on pages 02–11 names the owner, the resource, the verification and the
failure mode; a reviewer who wants one control's evidence path goes to that table, not to the
prose.

## Reading order for a builder

The builder's question is "what do I create first, and what does the factory refuse". Read:

1. [01-hld.md](01-hld.md) §0.4 (the tier gate — what can be built with the people who exist),
   §1 (the charter), §3 (the landing zone diagram).
2. [02-landing-zone-and-tiers.md](02-landing-zone-and-tiers.md) end to end — the folder tree,
   the factory and its modules, the CI identity, naming, labels, budgets, the baseline
   constraints, the shared/per-agent split. The first factory run is this page.
3. [05-registry-and-autonomy-contract.md](05-registry-and-autonomy-contract.md) §1–§4 and §7 —
   the register row is the input to everything; the admission gate is what refuses.
4. [08-data-logging-retention-sovereignty.md](08-data-logging-retention-sovereignty.md) §3 and
   §9 — the logging project and the buckets are created once and cannot be changed in the
   direction that matters (CMEK, the lock); build them right at Stage 0.
5. [09-supply-chain-secrets-recovery.md](09-supply-chain-secrets-recovery.md) §2 — the key
   project and the HSM constraints precede the first factory run.
6. [04-identity-and-privileged-access.md](04-identity-and-privileged-access.md) §3–§5 — the deny
   policy, the PAB and the PAM catalogue are folder-level and go in with the folder.
7. [03-gemini-enterprise-environment.md](03-gemini-enterprise-environment.md) §16 — the runbook
   to bring the tenant app to baseline (Tier C); it imports the app's project through the
   factory's `tenant-app` module, so it runs after the folder and core projects exist — in the
   build, after Tier R ([setup/README.md](setup/README.md) §3.1, SD-13).
8. [06-gateways-model-armor-perimeter.md](06-gateways-model-armor-perimeter.md) §2–§3 — the
   first agent project's gateway and templates; §4.3 — the two spikes to run in nonprod before
   any Tier W project.
9. [07-monitoring-detection-incident-response.md](07-monitoring-detection-incident-response.md)
   §4 — the monitoring baseline module every project instantiates.
10. [12-open-decisions.md](12-open-decisions.md) §2 — every decision the folder and the first
    factory run depend on; anything `open` there is a factory input that does not exist yet.

To build rather than read, start at [setup/README.md](setup/README.md) (2026-09-15): the one
entry point to the human-executed setup procedures for the platform, Mo, Eve and Wall-E. It
supersedes the per-agent runbooks (`../wall-e/SETUP.md`, `../wall-e/PREREQUISITES.md`,
`../eve/07-build-runbook.md`, `../mo/07-build-runbook.md`), which are kept for reference only.

## Maturity: what exists on 2026-09-13

| Thing | State |
|---|---|
| The design | complete for pages 00–12; decisions P1–P204 recorded; page-to-page disagreements resolved in [12-open-decisions.md](12-open-decisions.md) §7, whose rows 10–14 stay open until the agent sets carry them; the agent-set changes are the propagation stage of HLD §18 (P143), not yet run |
| The build sets | [setup/](setup/README.md), [pov/](pov/README.md) and [3-day/](3-day/README.md) written 2026-09-15 to 2026-09-17, never executed; their decisions P144–P204 are proposed, none signed |
| The organisation | one administrator, no SOC, no second super admin outside the administrator's own line, no security reviewer, no Eve owner, no DPO engaged, no ISMS names supplied (HLD §0.3) |
| Google Cloud | no `fld-agentic-platform`, no factory, no project of the four; `GEMINI_PROJECT` exists as the tenant app's project and is to be imported |
| Google Workspace | the tenant exists with Gemini Enterprise licences; no robot account, no robot OU, no multi-party approval, no sandbox tenant |
| Verification | every Google and regulatory fact cited on pages 02–11 was checked against its URL on 2026-09-13; items that could not be verified are listed per page under "Unverified" and stay *tbd* |
| Spikes | none run; P3 (perimeter), P4/P42 (custom constraints), P57 (tenant gateway binding), P61 (deny-policy principal spelling) are the ones the first nonprod project exists to run |
| Gates | Tier C and Tier R can open with the people who exist; Tier W, Tier P and the super-admin grant wait on people, bought services and the register's §4 group; Tier X is closed ([01-hld.md §0.4](01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens)) |

## How the three agent sets relate to this one

The sets ([Wall-E](../wall-e/README.md), [Eve](../eve/README.md), [Mo](../mo/README.md)) were
written before the platform and stand as the designs of its first three tenants: the platform
lifted their platform-grade content to fleet rules (for example chapters 11–13 and
`project-topology.md` as seeds, P47) and left their agent-specific content where it was. The
edits each set must make, with owners and gates, are
[01-hld.md §18](01-hld.md#18-what-this-hld-requires-of-the-wall-e-eve-and-mo-sets) (P143). Their
open decisions (Wall-E 1–52, Eve E-1..E-20, Mo M-1..M-11) stay in their own registers, and
[12-open-decisions.md §8](12-open-decisions.md#8-index-agent-set-decisions-and-the-platform-rows-that-touch-them)
indexes which platform row supersedes, generalises or depends on each.

## Related

- [../project-topology.md](../project-topology.md) — the four projects and the cross-project grants, now factory inputs
- [../gemini-enterprise.md](../gemini-enterprise.md) — the tenant facts, filled at GE-0
- [../wall-e/README.md](../wall-e/README.md), [../eve/README.md](../eve/README.md), [../mo/README.md](../mo/README.md) — the three agent sets
- `.agent-work/review/*.md` — the nine lens reports behind [00-objective-review.md](00-objective-review.md) (outside the wiki)
