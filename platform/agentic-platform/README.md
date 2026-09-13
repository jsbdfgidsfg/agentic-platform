# Agentic platform

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Maturity: **design — nothing built.** No folder, no factory run, no project made by the
  factory, no gateway, no registry entry, no sink, no SIEM, no witness organisation, no robot
  account with Super Admin. The four projects of [../project-topology.md](../project-topology.md)
  are decided and not created. Every page in this set is a design of something that does not
  exist on 2026-09-13, written so that a security reviewer can find what is enforced and what
  is only detected, and so that whoever builds it can start from the factory and the register
  without re-deriving a decision.
- What this set is: thirteen pages (00–12). [01-hld.md](01-hld.md) is the parent; pages 02–11
  each detail one part of it and record their decisions; [12-open-decisions.md](12-open-decisions.md)
  is the register of record, P1–P141.
- Objective: `.agent-work/OBJECTIVE.md` (outside the wiki), restated in
  [00-objective-review.md](00-objective-review.md) §1. Standing constraints that no page
  loosens: no domain-wide delegation; the language model holds no credential and cannot
  approve; humans raise autonomy, machines lower it; no model produces an Eve approval; Mo
  reaches production only through a merged pull request; safety interlocks are plain
  authenticated REST; Wall-E holds Super Admin (the owner's decision of 2026-09-13, P33 —
  designed around, not re-argued).
- Conventions on every page: `Assumption:` marks inferred facts; *tbd* marks values nobody has
  decided; every Google product, launch stage, IAM role, organisation-policy constraint, API,
  article and date carries a source verified on 2026-09-13 or says "unverified"; no company
  names, no secrets, no person named for a role; every control names its owner (a role), the
  resource it sits on, how it is verified and what happens when it fails.

## What the platform is

A Google Cloud landing zone — one folder tree, one factory, one register — on which an
organisation can run hundreds of agents, classical or autonomous, with the same six containment
primitives applied to every one of them by the tier it belongs to: a trust boundary the agent
cannot redraw (folders, organisation policy, a factory-made project, a folder deny policy); its
autonomy held as data that only a human raises and any machine lowers; a capability ceiling
outside the agent's process (the model holds no credential; an action service holds it and
decides); a fleet kill switch outside every agent project, drilled; a model-free monitor with
halt authority; and evidence the judged thing cannot forge or silence. Every agent gets a
project of its own with a Google-issued keyless identity, an egress gateway that is default-deny
with Model Armor at the edge, sinks it cannot delete and an absence alarm if they go quiet, a
register row that fixes its owner, tier, purpose, data classes, EU AI Act class and TISAX class
before it exists, and an admission gate that refuses it without them. The Gemini Enterprise
tenant app is the one front door, itself bound to a gateway so it can reach only registered
engines. Tiers are lettered — C classical, R read tools, W write agents, P privileged (P-SA the
super-admin singleton), X AGI-class — and a tier does not open until the people and the bought
services it needs exist; on 2026-09-13 that is one administrator, so Tiers C and R can open and
everything above them is gated on hiring, buying and signing. The three agents — Wall-E, the
doer with Super Admin; Eve, the deterministic controller with a witness outside the tenant; Mo,
the improver that never touches production — are the first three tenants of the platform and
the proof that its rules can be met, not its definition.

## What it deliberately is not

The full list is [01-hld.md](01-hld.md) §16. The lines a reader most needs before reading on:

- It does not narrow a super-admin account; nothing in Workspace or GCP can. The perimeter
  around Wall-E is custody, a scope split, a split control plane, detection latency and the
  witness, and the pages say so rather than claim otherwise.
- It does not let any model produce an approval, a signature, a halt, a veto or a refusal. A
  model may narrate and may page a human at severity 2; nothing it writes is read by the gate.
- It does not make Eve's control path structurally unreachable by a super admin inside the
  tenant's organisation; it moves the evidence, the incident record and the pager outside, and
  records the control-path relocation as the end state (P15).
- It does not evaluate model capabilities, detect deception or claim AGI containment. Tier X
  is designed ([09](09-supply-chain-secrets-recovery.md) §4–§5) and closed.
- It does not run a SOC; it buys acknowledgement for Tier P and runs Google's detections for
  the rest. It does not place the folder in Assured Workloads while Agent Gateway, Registry
  and Identity are outside the package ([08](08-data-logging-retention-sovereignty.md) §7.1).
- It does not host a second super-admin agent, a third-party agent without a supplier row, or
  an agent without a register row; it does not train or modify models; it grants domain-wide
  delegation to nothing; it does not back up Workspace.
- It does not promise EU AI Act or TISAX outcomes. It promises the mechanisms and the evidence
  and lists, per regime, what the regulator or the assessor still decides.
- It does not automate the Admin console under any robot session, by browser or computer use.

## Documents

| Page | What it is | Decisions |
|---|---|---|
| [00-objective-review.md](00-objective-review.md) | The objective verbatim, the verdict on the documentation that existed before it, the gap register (110 gaps, 24 blocking), the 82-item brief the HLD had to answer, and the two compliance frames | — |
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
| [12-open-decisions.md](12-open-decisions.md) | The register of record: all 141 decisions in one sequence, grouped by the gate they block, with why each matters, the recommendation, owner, where it is recorded, the disagreements between pages, and the index into Wall-E's, Eve's and Mo's registers | P1–P141 |

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
   to bring the tenant app to baseline (Tier C), which needs no factory.
8. [06-gateways-model-armor-perimeter.md](06-gateways-model-armor-perimeter.md) §2–§3 — the
   first agent project's gateway and templates; §4.3 — the two spikes to run in nonprod before
   any Tier W project.
9. [07-monitoring-detection-incident-response.md](07-monitoring-detection-incident-response.md)
   §4 — the monitoring baseline module every project instantiates.
10. [12-open-decisions.md](12-open-decisions.md) §2 — every decision the folder and the first
    factory run depend on; anything `open` there is a factory input that does not exist yet.

The Wall-E, Eve and Mo runbooks (`../wall-e/SETUP.md`, `../eve/07-build-runbook.md`,
`../mo/07-build-runbook.md`) are per-agent and come after the platform; the propagation stage
(HLD §18) rewrites the phases the platform now performs (the factory call, folder-level deny
policy, the log view instead of an organisation sink).

## Maturity: what exists on 2026-09-13

| Thing | State |
|---|---|
| The design | complete for pages 00–12; decisions P1–P141 recorded; the reconcile pass over the platform pages (page-to-page claims in each page's "claims other pages must match" section, and §7 of the register) run on 2026-09-13 — every HLD correction carries a dated line; the agent-set changes it names are the propagation stage of HLD §18, not yet run |
| The organisation | one administrator, no SOC, no second super admin outside his own line, no security reviewer, no Eve owner, no DPO engaged, no ISMS names supplied (HLD §0.3) |
| Google Cloud | no `fld-agentic-platform`, no factory, no project of the four; `GEMINI_PROJECT` exists as the tenant app's project and is to be imported |
| Google Workspace | the tenant exists with Gemini Enterprise licences; no robot account, no robot OU, no multi-party approval, no sandbox tenant |
| Verification | every Google and regulatory fact cited on pages 02–11 was checked against its URL on 2026-09-13; items that could not be verified are listed per page under "Unverified" and stay *tbd* |
| Spikes | none run; P3 (perimeter), P4/P42 (custom constraints), P57 (tenant gateway binding), P61 (deny-policy principal spelling) are the ones the first nonprod project exists to run |
| Gates | Tier C and Tier R can open with the people who exist; Tier W needs a second operator, a security reviewer and a blind grader; the super-admin grant needs the §4 group of the register green; Tier X is closed |

## How the three agent sets relate to this one

The three sets were written before the platform and before the objective made Wall-E a super
admin. They stand as the designs of the first three tenants; the platform lifted their
platform-grade content to fleet rules and left their agent-specific content where it was.

| Set | What it is on the platform | What the platform took from it | What it must change (HLD §18) |
|---|---|---|---|
| [../wall-e/README.md](../wall-e/README.md) | The Tier P-SA singleton: a super-admin robot account, an action service in two halves (`walle-actions`, `walle-actions-super`), a catalogue in three bands, the autonomy ladder | Chapters 11 (prompt security), 12 (agent identity), 13 (agent interconnection) and `project-topology.md` are the seeds of pages 06, 04, 05 and 02 — referenced, never copied (P47); the ladder's numbers became the fleet defaults (P77); its deny policy became the folder's (P61); its sinks became the platform's (P104) | Identity chapter rewritten around a super-admin account; bands and the hard-denied list; SETUP phases that the factory now performs; every "never Super Admin" line (HLD §18 items 1–7) |
| [../eve/README.md](../eve/README.md) | The dedicated, deterministic controller for Tier P: a control path with no model, a reporting path that may reason (`eve-advisor`, P34), a witness outside the tenant, an owner outside the Wall-E line | The verifier pattern, generalised as the platform verifier for Tier W (P79); the reporting path as the platform's RP-1..RP-6 (P98); the heartbeats and silence halt (P97); the export and the witness (P107) | Observe-and-report before the grant; the witness; the second human; `eve-advisor` as a new component; the sink filter widened (HLD §18 items 9–17) |
| [../mo/README.md](../mo/README.md) | One Mo per platform: metric packs per agent, proposals as pull requests, no credential anywhere | The validator custodian as a platform service (`VALIDATOR_PROJECT`, P45); the metric pack as the per-tier measurement row; the blind-grading capacity as the Tier W cap (P25); the SOC metrics it does not produce (P103) | Mo rows for Eve; the git host and CI identity (P22); the narrator's Art. 50 label (P128) (HLD §18 items 18–24) |

The relation in one sentence: the platform is the set of rules an agent inherits by being in a
folder; Wall-E, Eve and Mo are the three agents whose designs proved the rules were needed, and
they now have to obey them like any other tenant. Their open decisions (Wall-E 1–52, Eve
E-1..E-20, Mo M-1..M-11) stay in their own registers; [12-open-decisions.md](12-open-decisions.md)
§8 indexes which platform row supersedes, generalises or depends on each.

## Related

- [../project-topology.md](../project-topology.md) — the four projects and the cross-project grants, now factory inputs
- [../gemini-enterprise.md](../gemini-enterprise.md) — the tenant facts, filled at GE-0
- [../wall-e/README.md](../wall-e/README.md), [../eve/README.md](../eve/README.md), [../mo/README.md](../mo/README.md) — the three agent sets
- `.agent-work/review/*.md` — the nine lens reports behind [00-objective-review.md](00-objective-review.md) (outside the wiki)
