# 3. The problem and its risks

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14

## What this chapter explains

By the end of this chapter the reader knows what the design looked like on 2026-09-12, before the objective of 2026-09-13, and which parts of it survive into the platform. They know the three Google facts that make a super-admin robot a different kind of problem from a narrowly scoped one, exactly which safety properties the Super Admin choice removes, and the other reversals the objective forces on Eve, Mo and the project layout. They can name the five hardest problems in the order of their weight, including the two that are not technical at all: one person holds every role, and the declared purpose of the robot decides its legal classification. The chapter closes with seven risk themes. Every chapter in Parts II and III opens by naming the themes it answers, and Chapter 19, Threat model and residual risk, tests every answer and records what remains.

The objective, its requirements and the readings the design declines are Chapter 2, The objective and what it demands; the principles derived from this problem are Chapter 4, The principles. This chapter states the problem, so that every later answer can be judged against it.

## The design before the objective

### What it was on 2026-09-12

On 2026-09-12 the design described one privileged Workspace agent and two companions bolted to it. It did not describe a platform.

Wall-E was a narrow operator. Its robot account held two Workspace role assignments: a customer-scoped read role and a custom write role scoped to a pilot organisational unit. The design called the second assignment "a second enforcement point outside our own code": if every control in Wall-E's action service failed, Workspace would still refuse any call outside the role or outside the pilot unit. The role grew with the autonomy ladder. Wall-E could run a fixed catalogue of about twenty typed operations and nothing else. "Never Super Admin" was written as design intent on nineteen pages and enforced by the setup script. The never-list excluded changes to security posture and permanent data loss twice over: they were in neither the catalogue nor the role. The threat model bounded a leaked credential "by the role's privileges at the current stage". Decision 26 sought a keyless service account for the administrative half; decision 27 recorded that Wall-E was not a stand-in for a super admin.

Eve was a deterministic verifier of catalogued plans. Its verdict was a pure function of six plan inputs, the word "judgement" did not appear in its design, and "no model anywhere in Eve v1 or v2" was a settled row. Eve gated nothing in the pilot, received its own Workspace account at Stage 3 and began signing approvals at Stage 4.

Mo measured Wall-E and nothing else. Every number was re-derivable from Wall-E's audit table alone, and its grants, path allowlist and validator reached Wall-E's data only.

Above the three agents there was nothing. There was no landing zone, no project factory, no organisation-policy baseline above the project, no tier model, no Security Command Center, no SIEM, no incident-response roles, no retention schedule, no supply-chain control, no privileged access mechanism, no backup policy, no register of agents and no compliance classification. Compliance meant data protection: a DPIA and employee representatives "before Stage 3". The words "hundreds", "AGI", "TISAX" and "AI Act" appeared nowhere. Every control that existed was configured by Wall-E's runbook, in Wall-E's project, for Wall-E's engine, and the runbooks still placed Eve's and Mo's identities, and Eve's signing key, inside that project ([project-topology §1.1](../../project-topology.md#11-what-one-project-lets-happen-today)). A fourth agent would have re-implemented the security chapters by hand ([objective review §2](../00-objective-review.md#2-verdict)).

### What of it stands

The earlier design was careful, and much of its shape generalises. Seven elements are lifted into the platform unchanged, and Chapter 4, The principles, states them as platform rules.

- **The credential split.** The model never holds a credential; one action service does, and it is the only place authorisation is decided.
- **A deterministic gate before every write.** Code the model cannot talk its way past stands between generated text and any Admin SDK call.
- **Autonomy as data with permanent ceilings.** Each (operation family, trigger class) pair carries a level in versioned configuration; humans raise it, machines lower it, and some ceilings are code that no promotion can move.
- **A model-free authority path for Eve.** Whatever approves, halts, demotes or vetoes contains no model — deterministic by absence, not by discipline.
- **Re-derivable numbers for Mo.** Every figure Mo publishes can be recomputed by a validator Mo cannot reach.
- **Resource-level cross-project grants.** A principal in one project reaches a resource in another only through a grant on that resource, never through a project-level role.
- **The three separation rules.** No agent both decides and acts; no agent grades its own work; only humans loosen anything ([wall-e 08](../../wall-e/08-team-eve-mo.md#the-separation-that-makes-a-team-worth-having)).

The design's pages on prompt security and Model Armor, agent identity, agent interconnection and project topology were already platform-grade in substance and are promoted rather than rewritten. Eve's own credential, project, key, halt authority and "not a super admin, ever" are exactly what the objective asks of Eve. The standing constraints also hold unchanged (Chapter 4). The list of pages that need no change is [objective review §7](../00-objective-review.md#7-what-does-not-change).

## The Google facts that fix the problem

Three facts about Google's products, verified on 2026-09-13, turn the owner's choice into a structural problem rather than a configuration choice ([wall-e HLD, the Google facts behind Super Admin](../../wall-e/01-hld.md#the-google-facts-behind-super-admin-verified-2026-09-13)).

**A service account cannot hold Super Admin.** A service account can hold any Workspace administrator role except that one. The robot must therefore be a user account — licensed, with a password, able in principle to sign in interactively — and decision 26's keyless service account closes for Wall-E by fact, not by preference.

**Super Admin cannot be limited to an organisational unit or to a subset of privileges.** There is no scoped Super Admin and no way to grow it step by step with the autonomy ladder. Once the role is granted, Workspace enforces nothing on the account except the OAuth scopes consented for the client that holds its token. One consequence is specific and severe: the API call that makes a user an administrator sits under the ordinary directory-user scope that the narrow client already needs, so only Wall-E's own hard-denied list stops the robot minting further super admins.

**A super admin can grant itself Organization Administrator on the GCP organisation.** Google's pages say a super admin "can grant" that role and is the organisation's point of contact for recovery. The console mechanism is carried as an Assumption, as is the standing recovery right, to be verified or refuted before the grant; Google does not call the reach irrevocable and neither does the design ([eve HLD, choice 1](../../eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness)). The consequence is that every project in the tenant's GCP organisation — Eve's and Mo's included — is within a super admin's reach.

Everything else in this chapter follows from those three lines. The objective is not re-argued: Super Admin for Wall-E is the owner's decision of 2026-09-13, register row P33, and the platform is designed around it ([decision record](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)).

## What the Super Admin choice costs

The platform HLD states the loss "without softening" in seven rows ([HLD, what this reverses and what it costs](../01-hld.md#what-this-reverses-and-what-it-costs)). Each is explained here, because the rest of the brief is a response to them.

```mermaid
flowchart TB
  subgraph before["Before 2026-09-13 - custom role scoped to a pilot unit"]
    b1["Operator prompt"] --> b2["Agent names a catalogued operation"]
    b2 --> b3["Action service policy engine - enforcement point one"]
    b3 -->|"permitted"| b4["Workspace checks role and organisational unit - enforcement point two"]
    b3 -->|"denied"| b8["Refused in code"]
    b4 -->|"inside the role"| b5["Change applied"]
    b4 -->|"outside the role"| b6["Refused at Google's end"]
    b5 --> b7["Detection confirms what the role already bounded"]
  end
  subgraph after["After 2026-09-13 - Super Admin on a licensed user account"]
    a1["Operator prompt"] --> a2["Agent names an operation or composes a generic request"]
    a2 --> a3["Action service - bands, two lists, two-person rule - the only enforcement point"]
    a3 -->|"denied"| a8["Refused in code"]
    a3 -->|"permitted"| a4["Workspace enforces consented OAuth scopes and nothing else"]
    a4 --> a5["Change applied"]
    a5 --> a6["Detection - Eve reconciliation, SIEM super-admin set, witness - the primary control"]
    a6 -->|"misbehaviour seen"| a7["A human halts, demotes or pulls a kill switch"]
  end
```

### The Workspace-side gate

Before, there were two enforcement points: the action service, and Google refusing any call outside the role or the pilot unit. The design could promise that even a total failure of the action service would leave Workspace refusing the call. After, there is one. The pilot-unit allow-list, the never-list rows on posture and permanent loss, the role that grew with the ladder, the bound on a leaked credential and the split between safe and sensitive user fields are all now enforced by code inside the component under audit. The only Google-enforced ceiling left is the consented scope set of each OAuth client, which is why the design splits the robot's credential into a narrow client for everything unattended and a broad client for human-approved work, with the broad scopes absent from anything that runs alone. The sentence promising refusal at Google's end is deleted from the setup pages; keeping it would be a false statement in the safety case.

### The blast radius

Before, a leaked token was bounded by the role's privileges at the current ladder stage. After, a leaked refresh token or an interactive login on the robot account is a compromise of the tenant, and — through the power to grant Organization Administrator, or through a token carrying the cloud-platform scope — a path into the GCP organisation, including Eve's project, Mo's project and the platform's core projects. Nothing in Workspace or Google Cloud narrows the account. The perimeter becomes token custody, key custody, the scope split and detection latency. Only what has already left the organisation — evidence exported to the witness organisation, its alarms, its paging channels — is out of reach. How a leaked token travels through each path is Chapter 19.

### Eve's structural independence

Before, Eve's project, credential, key and halt authority were out of Wall-E's reach by construction. After, the robot's credential can make users administrators, suspend Eve's account, revoke Eve's token, remove Eve's role, switch off the setting that shares Workspace data with Google Cloud, and re-filter the organisation's log sinks. Inside the tenant's organisation, Eve's independence is detective, not structural: code and detection stop an abuse, nothing prevents it. What leaves the organisation — the evidence, the incident record, the pager — can still be structurally independent, which is the reason for the witness organisation described in Chapter 16, Eve, the independent controller.

### The catalogue as a ceiling

Before, nothing executed that was not registered in the catalogue. After, "any super-admin action on a human's prompt" cannot be delivered by twenty operations, so the catalogue stops being the ceiling and becomes the declared purpose: the only band that can ever become autonomous, beside a two-person generic lane and a console handoff to a human ([wall-e HLD, the three action bands](../../wall-e/01-hld.md#the-three-action-bands)). The cost is that the ceiling is now a rule in code rather than a limit of what exists. Decision 27 moves from "whether" to "which lane". How the literal reading of R4 is qualified is Chapter 2, The objective and what it demands; the bands are Chapter 15, Wall-E, the doer.

### Least privilege as a property

Before, TISAX control 4.2.1 could be shown by an enumerated role. After, least privilege becomes a signed deviation — row one of the platform risk register, carried entirely by the bands, the two lists, the ladder, Eve and a split control plane. An assessor may still refuse maturity 3 on it. The deviation record and its signatures are Chapter 21, TISAX.

### The narrow-task argument under the EU AI Act

Before, the argument that Wall-E performs narrow procedural tasks rested on the role and the catalogue. After, it rests on the declared intended purpose, on the hard-denied list enforced in code with its CI ownership outside the agent's repository, and on audit logs showing no out-of-catalogue operation outside band B under approval. The account's privilege is the fact most likely to be held against the argument. The classification is Chapter 20, EU AI Act.

### Detection moves from a check to the primary control

Before, alerts confirmed what the role had already refused. After, for the super-admin tier, detection is the primary control and the design says so rather than pretending the catalogue still is. The platform's grading rule makes the consequence sharp: a detection-grade control produces evidence, never a boundary, and nothing detection-grade may stand alone in a safety argument (Chapter 4, The principles). For the super-admin tier the design therefore has to pair detection with enforcement it can still own — the action service, the scope split, the kill switches — and has to make detection fast, independent and staffed. Monitoring is Chapter 11; the thirteen compensations that must be green before the grant, as a design argument, are Chapter 15.

## The other reversals the objective forces

Super Admin is the loudest reversal but not the only one. Eight more follow from the same objective, and each changes a sentence the earlier design held as settled ([objective review §3.2](../00-objective-review.md#32-other-reversals-the-lenses-found)).

**The catalogue is purpose, not ceiling.** The breadth of Super Admin is carried by lanes with permanent ceilings rather than by growing the catalogue, as described above.

**Eve gains a reporting path that may reason.** "Report anything wrong" cannot be enumerated in a closed vocabulary, so the earlier "no model anywhere in Eve" row is reopened, but only for a separate, report-only path; the model-free rule stands for approval, halt, demotion and veto. Why "any misbehaviour" is qualified this way is Chapter 2; the path is Chapter 16. The platform HLD records this reversal as decided on its own page, while the register carries P34 as proposed; this brief carries it as proposed ([HLD](../01-hld.md#what-this-reverses-and-what-it-costs), [register](../12-open-decisions.md)).

**Eve detects misbehaviour instead of verifying plans.** A verifier of catalogued plans sees only the plans it is shown. The objective asks Eve to control and report misbehaviour, so Eve's core becomes a versioned, deterministic detection catalogue over every ingested stream — privilege changes, out-of-family writes, deviations from baselines, divergence between what was prompted and what was done.

**Mo improves both agents.** Mo reads Eve's quality data through dataset-level grants made by Eve's own runbook and proposes changes to Eve's configuration through a closed set of change types. Eve reads nothing Mo writes, and Mo is never Eve's grader, so improvement does not become a path to weakening the controller.

**Four projects become a factory pattern.** The earlier topology counted four projects for four things. For hundreds of agents, one project per agent is a pattern produced by a factory under tier folders, and the counts of four become "pattern, not count".

**Decision 26 closes by fact.** The keyless service account for Wall-E's administrative half is impossible under Super Admin. The idea survives only in Eve's register as E-16, where a service account could still remove Eve's password, key and consent.

**Compliance becomes two regimes.** Data protection alone no longer covers the objective: the EU AI Act and TISAX are named, classified and mapped, and worker consultation moves from before Stage 3 to before Stage 1 under both the GDPR and the Act.

**Eve arrives before the grant.** Eve's observe-and-report layer must be live and drilled before the robot holds Super Admin, so the grant becomes a gate with its own checklist rather than a step in a runbook. Eve's gating and signing layers keep their later stages.

## Why agents are a distinct risk

A conventional administration script does what its author wrote. An agent does what a model infers, and that changes where risk lives. Tool arguments are generated text: the same process that summarises an email can compose a call that suspends a user, and under Super Admin that call could name an administrator-role assignment and Google would execute it. The content that steers the model does not come only from the operator. It arrives through the mailbox the agent reads, through the results its tools return, and through peer agents it talks to — any of which an attacker can write to. The design therefore treats no prompt instruction as a boundary, for the reason Chapter 19, Threat model and residual risk, gives under what prompt-based defence cannot do, and keeps the action service a separate process with the only credential and the hard-denied list in the gate ([wall-e HLD](../../wall-e/01-hld.md#why-the-action-service-stays-separate-from-the-agent)). The injection surface and its screens are Chapter 10, Agent Gateway, Model Armor and the perimeter.

## The five hardest problems

The distance between the earlier design and the objective reduces to five problems, in order of weight ([objective review §2](../00-objective-review.md#2-verdict)).

### 1. Super Admin cannot be scoped, so Workspace stops enforcing anything

This is the loss described above. Three controls the earlier design had deferred to "before Stage 1" — a network perimeter around the credential holder, the control-plane split into two services, and privileged access on the deploy grant — become preconditions of granting the role. The problem is not that any one control is missing; it is that the only gate left is code the platform itself writes and deploys, so the deploy path, the code's owners and the speed of detection all become part of the security boundary.

### 2. Eve's independence is no longer structural

Beyond the loss of structural independence described above, Eve read only one of the many streams a super admin acts in, and reported through a page budget whose conditions were empty, addressed to the person who administers Wall-E. The design had to decide where Eve's trust root sits and what "report to the human" means before the role is granted. It answers with a witness organisation outside the tenant and a second human outside the Wall-E administration line; relocating Eve's control path to the witness, the only mechanism that would stop a super admin forging an approval, is the end state, proposed and not built (P15). Chapter 16 explains both.

### 3. There was no platform — the scale problem

One project per agent is forced by Google rather than chosen, for reasons Chapter 7, Landing zone and the tier model, sets out ([project-topology §1](../../project-topology.md#1-why-four-projects)), so hundreds of agents means hundreds of projects. Google's resource limits make that routine; the earlier design did not. It offered a hand-run runbook, 26 hand-made cross-project grants, organisation-level log sinks built per agent and alert channels whose configuration read "paste yours". It had no fleet kill switch outside any agent's own project, which matters most for the most capable agents. The tier model, landing zone, factory, shared services, SIEM, Security Command Center and monitoring baseline had to be designed from nothing; they are Part II, and the scaling argument is Chapter 14, Scale and AGI readiness.

### 4. "Any super-admin action" collides with the must-never list and with the Act — the regulatory problem

Read literally, "any super-admin action" includes what the never-list existed to exclude and silencing Eve, which contradicts the objective's own Eve requirement (Chapter 2 sets out how the design qualifies that reading). The same words decide Wall-E's legal class. Under the EU AI Act, classification follows the intended purpose the provider declares, not the privileges an account holds. If "any admin action on a prompt" is the declared purpose, the Art. 6(3) derogation for narrow procedural tasks collapses and Wall-E becomes a high-risk system under Annex III 4(b), with the full Chapter III programme — risk management, technical documentation, conformity assessment, registration, post-market monitoring — due by 2027-12-02 and no harmonised standard to lean on ([EU AI Act page §3.1](../10-eu-ai-act.md#31-wall-e-wall-e)). The design recommends declaring the catalogue as the purpose, with band B as execution of requests two human super admins have specified and approved, and band C as instructions to a human. That line is the owner's to draw and sign: the purpose text is proposed (P28, content via P125, signature open) and the two lists are open (P29). Chapter 20 carries the classification.

### 5. One person holds every role — the organisational problem

On 2026-09-13 the platform owner, deployer, operator, approver, grader, security reviewer, Eve's owner, Mo's owner and the recipient of Eve's pages are one person, and that person will also prompt a super-admin robot ([HLD §0.3](../01-hld.md#03-who-exists-on-2026-09-13-and-the-roles-the-platform-needs)). Three consequences follow. TISAX control 1.2.2 on roles and separation of duties will not be rated at maturity 3 in that state, and it is the item most likely to stop an assessment. Eve's reports about the administrator have nowhere independent to go, because the administrator is the one who receives them. And every two-person rule in the design is notional: a second approval given by the same human is not a second approval. This problem is organisational, not technical, and no amount of code answers it. The design's response is a tier gate — Tier W, Tier P and the super-admin grant do not open until the people and bought services they need exist ([HLD §0.4](../01-hld.md#04-the-tier-gate-what-must-exist-before-a-tier-opens)) — and the recorded state "the four owner groups are one person" expires on the grant date. The roles, the minimum number of distinct humans per stage and the hours are Chapter 23, Operating model.

## The risk themes the rest of the brief answers

The problems above condense into seven risk themes. They are stated at the level of intent — what could go wrong and why it matters — and each names the chapters that answer it.

| Risk theme | What could go wrong | Answered in |
|---|---|---|
| Tenant compromise through the robot credential | A leaked refresh token, an interactive login or a compromised super-admin lane gives an attacker the tenant and a path into the GCP organisation, with nothing in Google to narrow it | Chapter 8, Identity, privileged access and the fleet kill switch; Chapter 11, Monitoring, detection and incident response; Chapter 15, Wall-E, the doer |
| Manufactured silence | The actor being watched switches off data sharing, re-filters sinks, deletes evidence or suspends the watcher, so that absence of alerts looks like calm | Chapter 11, Monitoring, detection and incident response; Chapter 12, Data, logging, retention and sovereignty |
| Autonomy outrunning evidence | A level is raised, or a fleet grows, faster than graded and independently re-derivable evidence supports | Chapter 9, Registry, governance and the autonomy contract; Chapter 17, Mo, continuous improvement |
| A controller reachable by what it controls | Eve's account, key, project, rules or pages are within reach of the super-admin credential or of the administrator Eve reports on | Chapter 16, Eve, the independent controller |
| Shadow and third-party agents | Agents reach the tenant or the Gemini Enterprise app without a register row, a gateway, a screen or a classification, including agents built or hosted by suppliers | Chapter 9, Registry, governance and the autonomy contract; Chapter 14, Scale and AGI readiness |
| Classification collapse | What an agent does, or how it is positioned, contradicts its declared purpose, and a system claimed as narrow is treated as high-risk — or an agent enters service with no classification at all | Chapter 20, EU AI Act |
| Staffing that makes two-person rules notional | Approvals, reviews, grading and pages that need a second person are given by the same person, so the control exists on paper only | Chapter 23, Operating model |

Every answer is tested in one place. Chapter 19, Threat model and residual risk, takes each theme, names the enforcement-grade control that stops it and the detection that sees it, states the residual that remains, and records whether that residual is accepted in writing, mitigated or blocks a gate. None of the themes is closed by this chapter, and some are not closed by the design either: a leaked robot credential remains a tenant compromise met by detection and kill switches rather than prevented, and Eve inside the tenant's organisation sees a super admin but cannot structurally stop one.

These risks are accepted only in exchange for a gain that has not yet been measured. Chapter 1, Executive summary, states the administrative work Wall-E is meant to remove, why no benefit figure exists until four weeks of toil have been measured before Wall-E's first phase, and the two exits: the stop-or-continue review at the end of S1, which ends the programme if the saving does not cover the cost including human hours, and human approval of each action (L3) as a legitimate permanent end state.

## Key decisions and what to read next

### Key decisions

- **P33 — decided** by the owner on 2026-09-13: Wall-E holds Super Admin on a dedicated licensed user account; deviation signatures pending ([decision record](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)).
- **Decision 26 — closed for Wall-E by fact**: a service account cannot hold Super Admin; the idea survives as Eve's E-16.
- **P28 — proposed content (via P125), signature open**: Wall-E's declared intended purpose, the catalogue plus bands B and C, against "any admin action" with the full Chapter III programme.
- **P29 — open**, owner signs: the two lists, decision 4 re-ratified (Chapter 2 notes how the register and the HLD describe them).
- **P34 — proposed**: Eve's reporting path may reason, report-only ([decision record](../../../decisions/2026-09-13-eve-reporting-path-may-reason.md)).
- **P15 — proposed**: relocation of Eve's control path to the witness organisation as the end state.
- **P25 — open**: the Tier W cap expressed as grading capacity rather than project count.
- **P10 — open**, IT security: the SIEM and managed detection partner that the super-admin tier's primary control depends on.

States are the register's on 2026-09-14; who decides each is Chapter 25, Decisions awaiting the owner.

### Canonical pages to read next

- [Objective review §2, verdict](../00-objective-review.md#2-verdict), [§3.1, Wall-E holds Super Admin](../00-objective-review.md#31-wall-e-holds-super-admin), [§3.2, other reversals](../00-objective-review.md#32-other-reversals-the-lenses-found) and [§7, what does not change](../00-objective-review.md#7-what-does-not-change)
- [Platform HLD, what this reverses and what it costs](../01-hld.md#what-this-reverses-and-what-it-costs) and [§13.1, the super-admin singleton](../01-hld.md#131-wall-e--the-super-admin-singleton-in-tier-p-sa)
- [Wall-E HLD, the Google facts behind Super Admin](../../wall-e/01-hld.md#the-google-facts-behind-super-admin-verified-2026-09-13) and [why the action service stays separate](../../wall-e/01-hld.md#why-the-action-service-stays-separate-from-the-agent)
- [Eve HLD, choice 1: detective inside the organisation, structural through the witness](../../eve/01-hld.md#1-eves-independence-detective-inside-the-organisation-structural-through-the-witness)
- [Project topology §1, why one project per agent](../../project-topology.md#1-why-four-projects)
- [EU AI Act page §3.1, Wall-E](../10-eu-ai-act.md#31-wall-e-wall-e) and [TISAX page §10, the risk register](../11-tisax.md#10-the-risk-register-p140)
- Next in the brief: Chapter 4, The principles.
