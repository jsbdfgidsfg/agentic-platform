# 14. Scale and AGI readiness

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14

## What you will understand by the end

What "hundreds of agents" costs once the factory has removed the hand work, and why the limit is the people who grade agents' work blind rather than the number of projects. How agents, MCP servers, Marketplace apps, connectors and models the organisation did not write come in and go out. Why code execution does not exist below the top tier, and how that absence is enforced when Google offers no switch for it. And why a future AGI-class agent is a closed tier with written opening conditions rather than a promise.

The chapter answers three risk themes of Chapter 3, The problem and its risks: autonomy outrunning evidence, because the fleet cannot grow faster than humans can grade it; shadow and third-party agents, because nothing external binds without a supplier row; and staffing that makes two-person rules notional, because the cap is written in named people. Nothing described here is built on 2026-09-14.

## Two readings of "hundreds of agents"

The design accepts that hundreds of agents can be made, placed, screened, watched and removed without a runbook per agent. It declines the reading that hundreds of autonomous agents can be supervised by the people who exist. Requirement R11 is met with that qualification: the cap is grading capacity, not projects ([HLD §0.6](../01-hld.md#06-traceability-the-objectives-sixteen-requirements-and-the-register-ids-not-cited-elsewhere)).

### What scales with the factory

Everything a machine can make from a register row scales with the factory: the project, identity, gateway, budget, labels, groups, resource-level grants, registry card and monitoring baseline (Chapter 9, Registry, governance and the autonomy contract). A factory run makes the project in under an hour (Chapter 7, Landing zone and the tier model) for about half an hour of the platform owner's time ([landing zone §1.3](../02-landing-zone-and-tiers.md#the-tier-profile-across-all-controls)), and the first heartbeat at the detection desk is an admission condition, so a registered agent is a watched agent (Chapter 11, Monitoring, detection and incident response). None of this needs a new person per agent.

### What hundreds of projects multiply

Project-per-agent is forced by Google (Chapter 7), and a factory removes the effort, not the volume. Every project has its own budget, IAM policy, API list and owner group; every crossing between projects is a grant on a resource and a drift-job row; BigQuery bills the project that runs the query ([project topology §1.4](../../project-topology.md#14-the-cost)). From Tier W each agent has a nonprod twin. Some Google limits bite at fleet size: log views are capped at 30 per bucket, so a tier folder needs another evidence bucket past about 25 agents (P114, proposed; Chapter 12, Data, logging, retention and sovereignty), and the shared Agent Registry holds 100 entries per project, with an increase requested at 60 % occupancy — a request, not a right ([HLD §3.4](../01-hld.md#34-labels-budgets-contacts-quotas)). Organisation-sink ingestion is the largest cost line. Budget and quota amounts are open (P31); cost figures are Chapter 24, Roadmap and cost.

Findings multiply too: below Tier P a hundred projects' findings page one person, the platform owner, by next business morning (Chapter 11).

### What scales only with people

A factory cannot make a grader, a second operator for L3 approvals who is not the agent's owner, a security reviewer for ladder raises and privileged factory phases, or, at Tier P, a bought desk, a second human super admin and an Eve owner outside the agent's administration line. Register rows carry a review date at most 90 days ahead, privileged rows are reviewed quarterly and supplier rows annually; each is a human reading something.

The steady-state human cost per tier shows the shape ([landing zone §1.3](../02-landing-zone-and-tiers.md#the-tier-profile-across-all-controls)): nothing for Tier C, about half an hour a month for Tier R, about three hours a week plus a bought desk for Tier P. For Tier W, Chapter 23, Operating model, quotes about one hour a week of blind grading per agent, about two hours a week for the second operator and two hours a month for the security reviewer, with at least two hours a week of grading for Wall-E at its S4 volume; Chapter 17, Mo, continuous improvement, derives the grading figure. Hundreds of Tier C and R agents are within reach of the people who exist; hundreds of Tier W agents are a staffing decision; hundreds of Tier P agents are not a goal.

### The cap is grading capacity (P25)

Grading binds because it cannot be removed without destroying what it measures. Precision at the upper autonomy levels is a human-graded quantity; the sample floor is per cell, so thinning it marks the cell not ready; and a model grading would replace the evidence with the thing under test ([Mo metrics contract §13.3](../../mo/03-metrics-contract.md#133-coverage-is-itself-a-metric)). If nobody grades, no cell reaches its promotion sample and the programme stalls on attention rather than on safety ([Mo staging](../../mo/05-staging.md#run-human--the-real-number-and-the-one-that-decides-whether-the-programme-survives)). That is the right failure: an ungraded agent does not become dangerous, it stays at the autonomy it has.

The design makes this an admission rule: a Tier W register row must name a blind grader with capacity, or the gate refuses it ([HLD §11.1](../01-hld.md#111-tiers-and-mandatory-controls)). The number of Tier W agents per grader is P25, and it is open: *tbd*, measured after the first Tier W agent's first quarter, owned by Mo's owner and the ISMS, blocking the second Tier W agent, and dependent on a second grader nobody has found (E-13, M-4; [register §3](../12-open-decisions.md#3-before-any-tier-w-agent-writes)). By arithmetic, not design, a hundred Tier W agents need about a hundred grading hours a week.

### Tier P stays rare

Each Tier P agent is a licensed Workspace user on the admin-role review, paid by its owner's cost centre and reviewed quarterly; the target number of super-admin agents is one ([HLD §3.4](../01-hld.md#34-labels-budgets-contacts-quotas)). The singleton rule is Chapter 7's. It belongs in a scaling argument because the compensations for a super-admin robot, from the witness organisation to the detection set, are written for one actor; a second is not another instance of the design but a design not yet done.

## Agents the organisation did not write

The platform cannot test a supplier's code, so assurance comes from the supplier's evidence, a contract and a technical position that assumes the worst about what comes back. One procedure covers every external agent, MCP server, Marketplace app, connector and model (P138, proposed; [TISAX page §8.1](../11-tisax.md#81-the-rule)), and Wall-E's position — no MCP server consumed or exposed, no skill loaded at runtime — is the default for every Tier P agent.

### Onboarding

The dependency is declared on the consuming agent's register row before anything is bound; an allow-list entry, install or endpoint with no supplier row is a reconciliation finding and is removed ([§8.3](../11-tisax.md#83-the-onboarding-procedure-as-controls)). The platform owner assesses what it is, who runs it, the data classes it will see, its residency and its evidence: at very high protection need a TISAX label or an equivalent independent assessment such as an ISO/IEC 27001 certificate with scope or a SOC 2 Type II report, questionnaires alone being rejected; at high need the same or a risk assessment the ISMS accepts. Personal data brings a processing agreement and sub-processor list; a model brings no-training and retention terms and its EU AI Act Art. 25 position. The ISMS accepts, and a contract follows with an exit clause, a deletion commitment and duties to notify sub-processor changes and incidents.

Technical admission reuses the platform's rules. An MCP server enters only as a registered, gateway-governed endpoint of a Tier R or higher agent, never as a Gemini Enterprise data store, with an explicit tool filter, confirmation where it applies and no elicitation callbacks, since a server that can ask for input mid-call has a channel the declared tool list does not describe. An external agent is an `agent` principal: L0 for every write, tainted on receipt, bound only to manifest-named entries — Chapter 9's peer rule applied to strangers. A Marketplace app's OAuth scopes are reviewed in the Workspace API-controls list, and no connector holds a Workspace write scope. A model's pin is recorded and re-qualified on change. The one-run admission gate then checks "supplier row approved".

### In service and exit

Supplier rows are reviewed annually; label expiry is tracked, and an expired label at very high need disables the dependency at the gateway. A change notice or incident reopens the assessment.

Exit is written before entry is needed ([§8.4](../11-tisax.md#84-the-exit-procedure-533)). A supplier's binding is revoked, its data returned or deleted, the deletion confirmation filed and the row's entry retired. A platform agent is unshared, deregistered, halted if it writes, its evidence export confirmed, and only then its project deleted. Export before delete is the rule that matters: a deletion before its export confirmation is severity 1 and restored from the witness copy, and a supplier unable to confirm deletion leaves a residual the ISMS records. The procedure is rehearsed yearly on a throwaway nonprod project, covers the end of the contract with Google, and states that the Workspace tenant is not the platform's to delete. P138 must exist by the super-admin grant at the latest ([register §4](../12-open-decisions.md#4-before-the-super-admin-grant)), and in practice by the first connector beyond first-party sources. How an assessor reads the supplier controls is Chapter 21, TISAX.

## Code execution

Code execution turns an injected prompt into an arbitrary program, so below Tier X it must be impossible, not merely unconfigured (P121, proposed).

### None below Tier X, and how "none" is enforced

On 2026-09-13 Google offered no organisation-policy constraint disabling Agent Runtime code execution, and the engine resource is not a custom-constraint resource type ([supply-chain page §4.1](../09-supply-chain-secrets-recovery.md#41-what-google-offers-on-2026-09-13-verified)). "Off" is built runtime by runtime, with different grades ([§4.2](../09-supply-chain-secrets-recovery.md#42-the-rule-below-tier-x-and-how-none-is-enforced-per-runtime-p121)). GKE is enforced: its service is missing from every tier folder's allow-list except the Tier X folder's, which is empty, and Cloud Functions, Compute Engine, Batch and Dataflow are absent likewise. Agent Runtime sandboxes are enforced by permission — no agent identity may create one, CI refuses packages that import the code-execution tool or call the sandbox API — with a severity-1 alert and a daily listing expecting zero for the residual, a human elevated through Privileged Access Manager; the alert's method name stays *tbd* until a first nonprod attempt logs it. Cloud Run sandboxes, Pre-GA with an unverified enabling field, are detection-grade through an image scan. Over all three, `capabilities.code_execution: false` is the only manifest value the validator accepts outside Tier X.

### The Tier X sandbox, recorded in advance

A sandbox designed on the day someone asks for one is designed in a hurry, so it is written now (P122, proposed; [§4.3](../09-supply-chain-secrets-recovery.md#43-the-tier-x-sandbox-design-recorded-now-so-it-is-not-designed-in-a-hurry)): a GKE Autopilot cluster per Tier X project in `europe-west1` with private nodes; the Agent Sandbox add-on with gVisor; one sandbox claim per tool call, living minutes; the add-on's default egress blocks plus a network policy allowing only the agent's egress gateway; no identity or token inside; an attested base image; executed code logged to the 30-day content class; and the kill switch's first lever stopping it with everything else.

GKE Agent Sandbox has been generally available since Google's announcement of 2026-05-21, which meets P27's stage condition (P27 proposed: stage met, tier closed). Residency no longer decides, because Agent Runtime Code Execution is also available in `europe-west1` and the `eu` multi-region. GKE is chosen for a named isolation technology, a documented egress block the gateway can extend, a sandbox with no identity, and GA; Agent Runtime Code Execution is the recorded second option, not adopted while its launch stage, isolation and egress path are unverified. The cost is a Kubernetes estate for a team that is one person on 2026-09-14; if GKE proves unoperable, the written fallback is no code execution in the EU.

## Containing the top tier

### Eight properties, three labels

Eight containment properties are graded enforcement or detection and labelled exists, buildable or research-grade ([§5.1](../09-supply-chain-secrets-recovery.md#51-the-eight-properties-graded-and-labelled)); "exists" means designed in the agent sets and generalised by the factory, not running. Existing: a capability ceiling enforced outside the agent, in the action service and validator; no credential in the model's process; default-deny egress, whose sandbox part is buildable. Buildable from GA products: the fleet kill switch K7, pulled by a human or a deterministic job and never a model (Chapter 8, Identity, privileged access and the fleet kill switch); EU-resident sandboxing; no self-modification, meaning no agent principal writes a repository, registry, deploy identity, its ladder or its ceilings. Partly buildable and detection-grade: capability-drift monitoring through behavioural baselines over audit data. Research-grade and provider-side: evaluation gates before a capability grant — the ladder gates operational capability, and nothing on Google Cloud gates dangerous capability. Beside the eight, [HLD §11.4](../01-hld.md#114-the-fleet-kill-switch-k7-and-the-containment-primitives-for-the-top-tier) lists the model-free monitor, re-qualification on model change, monoculture, transitive capability through peers (held by peers being L0 for writes and tainted) and deception-robust monitoring, the last research-grade.

### The AI-control primitive

The one control a compromised, deceptive or more capable model cannot argue with is one containing nothing that reads its arguments ([§5.2](../09-supply-chain-secrets-recovery.md#52-the-platforms-ai-control-primitive-a-model-free-monitor-with-halt-authority)). The authority path — approve, halt, demote, veto, stop the fleet — holds no model by construction: the gate evaluates typed predicates over plan inputs stated in advance, the halt is a plain authenticated REST call, the fleet stop is an organisation policy. The absence is enforced: the model API is denied at project level on Eve's project and every verifier project, CI forbids a model client in the gate's image, and the supply chain of Chapter 13, Supply chain, keys and recovery, makes that image the only one that runs. Halts go to the insert-only audit log as well as the control database, so a restore cannot lose one; machines only lower autonomy. A model may narrate and page on the advisory path, and no gate reads what it writes (Chapter 16, Eve, the independent controller).

What it is not: it does not detect a capable model that behaves well while observed and badly otherwise. It bounds what any behaviour can reach and stops the fleet on a signal a human or a rule chose. That is control, not evaluation.

### What the platform cannot buy

Dangerous-capability evaluation is the model provider's responsibility ([§5.3](../09-supply-chain-secrets-recovery.md#53-research-grade-and-provider-side-stated-honestly)). Google DeepMind's Frontier Safety Framework (version 3.0 of 2025-09-22, additions on 2026-04-17) defines critical capability levels and governs Google's launches; no deployer operates it and no Google Cloud product exposes a result per model. So the platform points at the evidence: each register row carries `capability_eval_ref` per model pin, a pointer to the provider's model card or framework-derived report, optional below Tier X and required for it by a CI check (P124, proposed), and the EU AI Act risk file already says the platform gates on measured behaviour within a catalogue (Chapter 20, EU AI Act).

Deception-robust monitoring, a trusted monitor over an untrusted more capable model, is research; nothing packages it, and Google's Semantic Governance page says its verdicts "may not be accurate", which is why it sits on no authority path. The platform uses an honest subset — the model-free monitor plus blind human grading of a sample. Interpretability and alignment guarantees are claimed nowhere.

### Model changes and monoculture

Evidence earned on one model says nothing about the next, so re-qualification on every model pin change is charter demand D9 ([HLD §1](../01-hld.md#1-the-platform-charter)): a fingerprint change — prompt hash, model id, framework version, filter version — returns every autonomy cell above L3 to its entry level at the next deploy, and the validator refuses evidence carrying a different fingerprint. Eve's advisor is re-qualified too, its paging thresholds reset on a new pin (P123, proposed). The scaling consequence: a fleet-wide model upgrade demotes many agents at once and hands the whole grading load back, so upgrades are scheduled against grading capacity.

Every agent and Mo's narrator run Gemini; the gate runs no model. For Tier X, advisory monitors must use a second model family so the watcher does not share the watched model's failure modes (P26, open, platform owner; [register §6](../12-open-decisions.md#6-later)); the family must satisfy the EU residency allow-list for model pins (P113, proposed).

## Tier X: a closed tier with written opening conditions

### A tier, not a new design

The tier is the platform's unit — folder, factory module, monitoring baseline, metric pack, staffing, compliance gate — so a future AGI agent is a tier, not a new design, and proposing one means meeting conditions already written ([HLD §11](../01-hld.md#11-the-tier-model)). The admission test asks the Tier X question first — code it wrote, goals it set, capabilities its designers cannot enumerate — and refuses a yes with `tier_x_closed` (Chapter 7).

`fld-agents-x` exists with an empty service allow-list, so Google refuses every API in it, and a non-empty value without a numbered decision is severity 1 ([landing zone, Tier X](../02-landing-zone-and-tiers.md#tier-x--agi-class-closed)). Each opening condition must become a dated line in the folder's decision file before the list gains a service, and every containment primitive must be live and drilled for six months before the first Tier X row; a missed month resets the clock. "Host future AGI agent" is declined for 2026, replaced by something Google enforces today.

### The opening conditions on 2026-09-13

From [HLD §11.5](../01-hld.md#115-the-honest-line) and [supply-chain page §5.4](../09-supply-chain-secrets-recovery.md#54-the-honest-line-restated-with-what-changed-on-2026-09-13):

| Condition | Owner | State on 2026-09-13 |
|---|---|---|
| Sandbox tier in the EU at general availability | Platform owner (P27, P122) | Met: GKE Agent Sandbox, GA since 2026-05-21 |
| Provider capability-evaluation report per model pin | Platform owner; AI-safety reviewer once the role exists (P124) | Not met: the field is designed, nothing fills it |
| AI-safety reviewer role exists | Not named (*tbd*) | Not met |
| K7 drilled for six months | Platform owner; security reviewer | Not met: K7 is not built |
| Advisory monitor on an independent model family running | Platform owner (P26) | Not met: P26 open |
| Every buildable containment property live | Platform owner; security reviewer and Mo's owner for K7 and drift monitoring | Not met: properties 4, 6, 7 and 8 named not live; nothing is built |

The pages count differently: HLD §0.4 and the supply-chain page's §4.1 and §5.3 say one met and four unmet, while HLD §11.5 and §5.4 enumerate five unmet, as above. The register also names Tier X as the gate of P15, relocating Eve's control path to the witness organisation, which §11.5 does not list. None of the unmet conditions is in reach in 2026.

## What remains open

P25 has no number until a Tier W agent has run a quarter, and its second grader does not exist. P26 is undecided; nobody is named to create the AI-safety reviewer role. Agent Runtime Code Execution's stage, isolation and egress path, the Cloud Run sandbox field and the sandbox-creation method name are unverified. Registry quota increases may be refused; budget and quota amounts are P31, open.

Other limits are accepted facts: a model that behaves well under observation defeats every detection-grade control, and only enforcement outside it and a kill switch it cannot reach bound it; a supplier's assurance rests on its evidence and contract; a fleet without graders stops growing. Chapter 19, Threat model and residual risk, carries these as residuals under the autonomy, third-party and staffing themes; Chapter 23 turns the hours into roles and Chapter 24 places the tiers in time.

## Key decisions and what to read next

### Key decisions

States on 2026-09-14:

- **Open:** P25, the Tier W cap by named grading capacity; P26, the second model family; P31, budget and quota amounts.
- **Proposed:** P27, GKE Agent Sandbox (stage met, tier closed); P121, no code execution below Tier X; P122, the Tier X sandbox; P123, re-qualification of the reporting path; P124, `capability_eval_ref`; P138, the supplier procedure; P114, an evidence bucket per tier folder.
- **Charter demand:** D9, re-qualification on every model pin change.

Chapter 25, Decisions awaiting the owner, lists who decides each open row.

### Canonical pages to read next

- [HLD §11, the tier model](../01-hld.md#11-the-tier-model), [§11.4](../01-hld.md#114-the-fleet-kill-switch-k7-and-the-containment-primitives-for-the-top-tier) and [§11.5](../01-hld.md#115-the-honest-line)
- [Landing zone §1.3, the tier profile](../02-landing-zone-and-tiers.md#the-tier-profile-across-all-controls)
- [Supply chain, secrets, recovery and AGI-class containment §4–§5](../09-supply-chain-secrets-recovery.md#4-the-code-execution-tier)
- [TISAX §8, supplier onboarding and exit](../11-tisax.md#8-supplier-onboarding-and-exit--third-party-agents-mcp-servers-marketplace-apps-models-p138)
- [Project topology §1.4](../../project-topology.md#14-the-cost) and [Mo's metrics contract §13.3](../../mo/03-metrics-contract.md#133-coverage-is-itself-a-metric)
- [Open decisions §3](../12-open-decisions.md#3-before-any-tier-w-agent-writes), [§4](../12-open-decisions.md#4-before-the-super-admin-grant) and [§6](../12-open-decisions.md#6-later)
