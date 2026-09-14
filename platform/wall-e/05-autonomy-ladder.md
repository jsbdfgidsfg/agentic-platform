# 5. The autonomy ladder

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Written against the platform objective of 2026-09-13 (Wall-E holds Super Admin, register row
  P33; [../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §12.1, §13.2); placement
  per [../project-topology.md](../project-topology.md).

This is the step-by-step enablement plan and the control that goes with it. Every number
here is an opinionated default meant to be tuned in the decision record that opens each
stage — but the *shape* is the design, and the shape is not negotiable without redoing
[06-security-guardrails.md](06-security-guardrails.md).

## 1. The eight rules

| # | Rule | Consequence |
|---|---|---|
| R1 | **Autonomy belongs to a pair, never to the agent.** A level attaches to (operation family, trigger class). | "Wall-E is autonomous" is never true. It is L5 for reading and L0 for suspending from mail, at the same moment. |
| R2 | **Humans raise, machines lower.** Raising needs a pull request and a dated decision record. Lowering is one API call by any operator, Eve, or a breaker, and the paperwork follows. | The asymmetry is the safety story. |
| R3 | **One notch, one family, on evidence.** Above L3, no skipping and a minimum dwell at each level. At or below L3 a level may be skipped when evidence from another trigger class already covers it, and only when the scorecard cites that evidence by fingerprint and sample size — L1 and L2 never execute, so skipping them risks nothing, and the citation makes that claim checkable. A new operation enters at L0 whatever stage the programme has reached. | "We are at Stage 4, so the new thing is autonomous" cannot happen. The stage table skips only below L3, and CI enforces exactly this rule. |
| R4 | **Reversibility outranks risk tier.** Only operations with an exact inverse can reach the top levels. | Sending mail is low-risk and irreversible, so it is capped. Suspending is high-risk and reversible, so it can climb. |
| R5 | **Every level is enforced in the action service.** The agent is told `ok`, `shadow`, `proposal`, `approval_required` or `denied`, and never learns why. | Same argument as the approval token: nothing the model can set. |
| R6 | **Verify every write by re-reading.** A write whose observed post-state does not match the plan is a `drift`, which demotes the family and opens an incident. | This is the signal Eve audits and Mo learns from. |
| R7 | **No silent level.** There is no level above execute-and-report. Every autonomous write appears in a run report and a daily digest. | If nobody would notice it happening, it does not happen. |
| R8 | **Evidence, not calendar.** Minimum durations exist only so evidence can accumulate. Time alone promotes nothing. | Stages have floors, not schedules. |

## 2. The six levels

| Level | Name | What the action service does | Who is asked | Who is told |
|---|---|---|---|---|
| **L0** | **OFF** | Runs the full policy chain, then denies with `level_off`. The operation stays in the catalogue so re-enabling is config, not a deploy. | nobody | run report |
| **L1** | **SHADOW** | Forces `dry_run`. Runs allowlist, parameters, protected principals, scope, budgets — so denials are observed for real. Shadow items **evaluate** budgets without consuming them: otherwise a stage whose write budget is zero would deny every shadow item for budget before the level could force the dry run, and the evidence the whole ladder is argued from would never be produced. Captures pre-state and the would-be verdict. **Never executes**, even if handed a valid approval. | nobody | run report, graded by an operator |
| **L2** | **PROPOSE** | As L1, plus writes a proposal to the operator queue with pre-state and rationale. **There is no execution path at L2**: a well-formed approval is refused with `level_no_execute`. A human who wants it done does it themselves, or in chat. | operator, for a verdict | operators |
| **L3** | **HUMAN** | Policy passes → `pending_human`. A named operator approves on the approval endpoint; the service verifies their group membership live, consumes the nonce, executes, verifies, records the approver. TTL 4 business hours, then `skipped`; an expired approval is never executed late. | operator, for execution | operators, Eve |
| **L4** | **EVE** | Policy passes → `pending_eve`. Eve approves with **its own signing key** (Cloud KMS `eve-approval`, in `EVE_PROJECT`) from its own service account (`eve-controller@EVE_PROJECT`); the action service verifies against a pinned PEM. A **hold window** then opens during which any operator can veto with one click. Then execute and verify. | Eve, blocking; humans may veto | operators |
| **L5** | **AUTO** | Executes immediately within scope. The service verifies; **Eve verifies independently within 60 minutes**. Humans read a digest. | nobody | digest |

There is deliberately no L6. "Execute and tell nobody" is not a level, it is a defect.

Two parameters travel with each level assignment and are part of the config version:
`hold_minutes` (L4) and `notify` (`per_step` / `per_run` / `daily_digest`). Moving `notify`
from per-step to a digest *before* raising a level is a legitimate intermediate step and
often the right one.

## 3. Trigger classes

| Class | Trigger | Principal recorded | Trust | Note |
|---|---|---|---|---|
| **T0 chat** | Operator in Gemini Enterprise | the human's email | High — an authenticated operator asked | The only class an interactive-only agent has |
| **T1 scheduled** | Cloud Scheduler → dispatcher | `job:<playbook>`, `on_behalf_of` = owner | Medium — input is Wall-E's own reads | Business hours enforced |
| **T2 event** | Workspace audit log → Cloud Logging sink → Pub/Sub → dispatcher | `event:<rule>` | Medium-low — the payload is Google's, but the *cause* may be an attacker's action | A T2 run may not emit an event that starts another T2 run |
| **T3 inbox** | The robot's own mailbox | `inbox` | **Low — attacker-controlled text** | Read-only operation set. Writes derived from it are **proposals only, permanently.** |

Each class climbs **independently**. A family at L5 on `scheduled` is still L1 on `event`
until `event` has done its own progression. Independence governs how autonomy is earned, not
how evidence of a defect is scoped: a demotion on any trigger restarts dwell for the family on
every trigger (§6). A new trigger is a new deployment, and new
deployments get canaried.

## 4. Ceilings that are code, not config

Config may set any level at or below these. Raising a ceiling is a code change with the
same review as a change to the protected-principal check, plus a security sign-off.

| Risk tier | T0 chat | T1 scheduled | T2 event | T3 inbox |
|---|---|---|---|---|
| READ | L5 | L5 | L5 | L5 |
| WRITE_LOW, reversible | L5 | L5 | L4 | **L2** |
| WRITE_LOW, irreversible (mail, Chat) | L5 templated / L3 free text | **L4 templated only** | **L4 templated only** | **L2** |
| WRITE_HIGH, reversible | **L3** | **L4** | **L4** | **L0** |
| WRITE_HIGH, irreversible | **L3** | **L2** | **L2** | **L0** |
| External recipients, any operation | **L3** | **L2** | **L2** | **L0** |
| `SUPER` — band B at tier `SUPER`, uncatalogued super-admin-class work | **L3, two-person** | **L0** | **L0** | **L0** |
| `WRITE-generic` — band B at tier `WRITE` | **L3** | **L0** | **L0** | **L0** |

The last two rows (platform HLD §12.1, §13.1 items 1 and 9) are not
catalogue families; they are the generic lane `/v1/execute-generic` on `walle-actions-super`
(band B), whose Admin SDK methods a committed table maps to `READ` / `WRITE` / `SUPER`
([01-hld.md](01-hld.md) §"The three action bands"). Band B takes the `chat` trigger only
(`principal.type == human`), so every other trigger is L0. At `SUPER` the requester is a
human super admin and the approver a **different** human super admin, with a change-ticket
reference and `hold_minutes` before execution. Unlike the rows above, these two cannot be
raised by a code change and a security sign-off: they are fixed by `ladder.schema` as
`code: true` rows (spelled `WRITE_GENERIC` in the schema,
[../agentic-platform/05-registry-and-autonomy-contract.md](../agentic-platform/05-registry-and-autonomy-contract.md)
§9.2 and §9.5), and the platform validator refuses a config in which they differ. CI also
asserts that no operation of either row appears in any playbook's `uses`, so neither can be
reached by a scheduled, event or inbox run. Band C (console-only work) has no row: nothing
executes there, and a human does the work.

Three permanent statements, said plainly:

- **`WRITE_HIGH` never reaches L5 on any trigger, at any stage, and no super-admin-class
  operation is ever autonomous: `SUPER` and `WRITE-generic` stay at L3 on chat and L0
  everywhere else, permanently, in code.** A suspended user or a
  changed group membership is exactly the case where a second independent signature costs
  minutes and prevents incidents. If a case genuinely needs it later, the honest path is a
  decision record that re-tiers that one operation, not raising the ceiling. No such path
  exists for the two band-B rows.
- **T3 never produces a write.** Anything derived from mailbox content is a proposal.
- **Free-text outbound is never autonomous.** Autonomous runs may use `notify.operators`,
  whose recipients come from config and whose body is a template. `gmail.send` with a
  model-chosen recipient stays on the chat trigger. This closes the residual injection
  risk that a design allowing model-chosen recipients would accept.

## 5. Operation families

| Family | Operations | Reversible | Autonomous ceiling | Rollback primitive |
|---|---|---|---|---|
| **F1 Observe** | all READ operations | — | L5 | none needed |
| **F2 Notify** | `notify.operators` (templated, fixed recipients) | no | L4 | correction message |
| **F2b Free notify** | `gmail.send`, `chat.message.send`, calendar create | no | L2 autonomous | correction message |
| **F3 Membership** | group member add / remove, class `low` | yes, exact | L4 | inverse from pre-state |
| **F3b Access groups** | same, class `access` | yes | L3 | inverse |
| **F4 Profile & OU** | `directory.user.update` within `SAFE_USER_FIELDS` | yes | L4 (profile), L3 (OU move) | restore captured fields |
| **F5 Suspend** | `directory.user.suspend(true)` | yes | **L4**, and not before Stage 5 | restore |
| **F6 Restore** | `directory.user.suspend(false)` | — | **L3, permanently** | — |
| **F7 Licences** | licence assignment delete / insert / patch | yes, same SKU | L4 for suspended targets, L3 for active | re-insert the recorded SKU |
| **F4b OU move** | `directory.user.move_ou` | yes, if the destination is in scope | **L3** | move back, only if the destination stays inside the allowlist |
| **F9 Own mailbox** | `gmail.label` | yes | L5 | inverse label |
| **F10 Rollback** | `run.rollback` | — | **L3 permanently** | — |
| **F8 Later** | data transfer, archive, group create | mostly no | enters at L0, own mini-ladder | decide per operation |

**Work outside these families** (platform HLD §13.1, "The three bands").
The families above are band A: the declared intended purpose and the only band that can
climb. F8 stays the hook through which a new operation joins the catalogue, at L0, on its own
mini-ladder. Until an operation is catalogued, super-admin-level work a human asks for goes
through band B at the tier the committed method table gives it (the §4 `SUPER` and
`WRITE-generic` rows: chat L3, never autonomous), or through band C, where Wall-E returns
console steps to a human super admin and watches for the matching admin event. The
hard-denied list ([03](03-lld.md) §"The hard-denied list") is refused in all three bands.

**F6 deserves its explanation.** Restoring access is a security decision, not hygiene. It
is the rollback path for F5, and a system that can suspend autonomously but needs a human
to un-suspend is the right asymmetry. Making restore autonomous would let a loop suspend
and restore repeatedly without anyone noticing.

## 6. Who may raise, who may lower

| Actor | Raise | Lower | Clear an override | Change a ceiling |
|---|---|---|---|---|
| Ladder owner | Yes, one notch, with a decision record and a config version. **A second named human is required for any L4 or L5 promotion.** | Yes | Yes, in a new config version referencing the incident | No — code review, two humans, security sign-off |
| Any operator | No | **Yes, instantly, alone.** Anyone may pull the andon cord. | No | No |
| Eve | **Never.** Eve *attests* that criteria are met; it cannot act on its own attestation. | Yes, to any level, including halt | No | No |
| Breaker in the action service | No | Yes, to L0 for the family, synchronously | No | No |
| Mo | No — opens the pull request with evidence | No | No | No |
| Wall-E | **Never.** No catalogue operation touches config, overrides or halt flags; `walle-agent@` has no IAM on any of them. | Only by refusing its own run | No | No |

**The ratchet.** After any automatic demotion: minimum five business days at the lower
level, a written root cause — an incident note committed in git, whose existence the
validator checks — and a fresh decision record before re-raising. No exception
for "it was a false positive" — if it was, that is a finding about Eve or the metric, and
it belongs in the root cause.

**Minimum dwell before raising:** L1→L2 two weeks, L2→L3 two weeks, L3→L4 four weeks,
L4→L5 six weeks. The dwell clock restarts after any demotion of that family, and the restart
is family-wide: **a demotion on any trigger restarts dwell for the family on every trigger**.
What a demotion reveals is a defect in the playbook and its platform, which the trigger
classes share; R3's independence is about how autonomy is earned. Being wrong in this
direction costs a slower promotion; being wrong in the other would let a cell climb on one
trigger while the same code fails on another.

How dwell, the ratchet and the one-notch rule are computed (from `ladder_events` only, which
reads `not_computable` until the table exists; the business-day calendar in `gates.yaml`; the
validator's `incident_ref` check; the false-positive review and its rate) is
[../mo/03-metrics-contract.md](../mo/03-metrics-contract.md) §9.

## 7. The six stages

Every stage carries the previous stage's controls forward. Durations are floors.

### Stage overview

| Stage | Name | Chat | Scheduled | Event | Inbox | Floor |
|---|---|---|---|---|---|---|
| **S0** | Eyes | F1 L5 · writes L1 | all L1 | L0 | L0 | 3–4 weeks |
| **S1** | Hands held | F1 L5 · writes **L3** | all L1 | L0 | L0 | 4–6 weeks |
| **S2** | Proposals | as S1 | F1 **L5** · F2 **L4** · writes **L2** | F1 **L1** | L0 | 6–8 weeks |
| **S3** | Batch approval | as S1 | writes **L3** batch | F1 **L5** · F2 **L2** | F1 **L1** | 6–8 weeks |
| **S4** | Eve gates | as S1 | F3/F4/F7 **L4** · F5 **L3** | F2 **L4** · F3 **L3** | F1 **L5** · writes **L2** | 8–12 weeks |
| **S5** | Steady state | as S1 | F5 **L4** · rest at earned level | F3 **L4** | ceiling reached | ongoing |

Read it as a canary rollout: each family enters a trigger class at L1, sits at each level
for at least its dwell, and never skips. `event` lags `scheduled` by one stage; `inbox`
lags by two and stops at proposals.

### The super-admin grant — a gate, not a stage

The day `walle@` receives Super Admin (register row P33) is **not** a row in the table above and
not a runbook phase but a gate: every row of the checklist in
[../agentic-platform/11-tisax.md](../agentic-platform/11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads)
§6.3 must be green, Eve's own rows G-1..G-7 are
[../eve/05-stages.md](../eve/05-stages.md#the-super-admin-grant--the-observe-and-report-layer-and-its-checklist),
and the register orders it before Wall-E's Stage 1
([../agentic-platform/12-open-decisions.md](../agentic-platform/12-open-decisions.md#4-before-the-super-admin-grant) §4).
The order is Eve's observe-and-report layer live and drilled → the grant → S0 on the narrow
client, with every write family at L1 → S1, because S0's F1 reads need an admin privilege, no
interim read role exists, and a Tier P-SA agent runs nothing against the tenant until its tier
line is green; before the grant the robot exists, is licensed and hardened, holds no admin role
and reads nothing ([02](02-identity-and-auth.md) "When Super Admin is granted").
The layer that must exist before the grant is the one that **reports** misbehaviour; Eve's
**gate** layer, which approves plans, comes later: observe mode at S3, load-bearing at S4, with
the seeded-fault exit.

### S0 — Eyes

| | |
|---|---|
| **Purpose** | Deliver read-only value immediately, and start generating the evidence that every later promotion will be argued from. |
| **Value on day one** | Weekly digests. `Assumption:` these are produced by hand today, or not at all — admin changes last week, accounts with no sign-in for 90 days by OU, licences by SKU, suspended-but-still-licensed accounts, groups with external members or no owner, admin-role holders versus a signed list. Plus ad-hoc directory questions in chat. |
| **Levels** | F1 at L5 on chat and scheduled. Every write family at L1 on every trigger. |
| **What actually touches Workspace** | Reads, plus `notify.operators`. No directory write, no group change, no licence change, no suspension. |
| **Autonomy ceiling of the pilot** | Nothing executes at S0; L3, human approval per action, is the most the pilot can deliver, and only from S1. Eve and Mo are designed but not built, so every level that depends on Eve's gate (L4, L5, the Eve-gated flow) is a target state, and until Eve exists the §8 metrics are BigQuery scheduled queries read by a human. |
| **Explicitly not in scope** | Autonomous writes of any kind · Eve · Mo · the event and inbox trigger classes · any write outside the pilot OU allowlist · any operation not in the catalogue · band B (`/v1/execute-generic`) and band C (`/v1/handoff`) on `walle-actions-super`, which exist only after the super-admin grant. |
| **Pilot population** | *tbd*. `Assumption:` synthetic accounts in the sandbox plus one small real pilot OU. The sandbox is a separate Workspace tenant, never an OU (decision 29, P40; §11). The account count in each is *tbd* and must be an absolute number in the decision record that opens S0. |
| **Employee attributes the reads touch** | Name, primary address and aliases, OU, manager and relations, group memberships, admin-role holding, licence assignment by SKU, last sign-in time, and admin, login, group, token and SAML audit events. |
| **The reporting channel is not on the ladder** | `notify.operators`, sending a templated message to a config-fixed operator address, is how a run reports at all — including a shadow run. Putting it inside F2 and then setting F2 to L1 would have meant Stage 0 could not tell anyone what it had shadowed. It is therefore **outside the ladder and outside the write budget**, and its recipients are config, never model output. Stage 2's "first autonomous write" is F2 to a *space or list*, which is a different thing. |
| **Scope** | Reads: whole tenant, rate-limited at 120 reads per minute — not a pilot-sized read, which matters for the data-protection assessment. Shadow write plans: pilot OU only. Daily write budget: 0 — and shadow items **evaluate** that cap without consuming it, or every shadow item would be denied for budget before its level could force a dry run, and Stage 0 would generate no evidence at all. |
| **Operators** | The ladder owner alone (`Assumption:`). A second named Workspace admin is required before S1, and a second approver from IT security before any high-risk promotion. |
| **Controls that must be live first** | Read-only at S0 is enforced by the ladder (every write family L1), by the hard-denied list in the policy chain, and by the narrow OAuth client's scopes on `walle-actions` — not by an OU-scoped read-only custom role, which cannot exist for a super-admin robot (reversed 2026-09-13, P33). What the robot's account holds before the grant is fixed in [02](02-identity-and-auth.md) · the super-admin grant passed (§7 "The super-admin grant"), so Eve's observe-and-report layer is live and drilled · robot account hardened, interactive-login alert firing · action service with catalogue, policy chain, durable budgets, write-ahead audit · ladder config v1 with everything at L1 · halt flags and the K0–K5 chain, drilled once with times recorded · dispatcher with per-job enable and budget · shadow grading sheet · the approval surface specified in [ARCHITECTURE.md](ARCHITECTURE.md) §3, which must exist before the first real write rather than before the first execution · the data-protection question formally asked. |
| **Exit criteria** | ≥ 20 shadow runs covering every write family, each item graded by an operator · for each family to be promoted, plan precision read by a human against the promote gate of [../mo/03-metrics-contract.md](../mo/03-metrics-contract.md) §4 (Wilson 95 % lower bound and conservative lower bound both ≥ 0.90, at least 35 decided items; [14](14-hld-challenge.md) C18, [decision 33](09-open-decisions.md)). No S0 or S1 exit criterion cites Mo's `verdict`: a human reads the numbers and signs. Unverified: whether S0's shadow volume reaches 35 decided items per family at all — [../mo/05-staging.md](../mo/05-staging.md) expects every cell to report `insufficient_data` at S0 · **zero** hard-invariant denials from autonomous runs (`protected_principal`, `operation_not_allowed`, bad approval) · zero requests without an audit row, verified by reconciling Cloud Logging against BigQuery · injection regression suite passes · K0 measured under 60 s, K5 measured · question formally put to the DPO and to employee representative bodies, where your jurisdiction has them, and their positions answered · decision record for S1 signed. |
| **Abort criteria** | Any of these stops the pilot rather than demoting one family: any execution against Workspace during S0, because nothing at L1 may execute · any severity-1 event (§9): an effect on a protected principal, an operation executed that was not in the frozen plan, a forged or agent-posted approval, any interactive login to the robot account · audit completeness below 100 % that cannot be reconciled · an `invalid_grant` from Google not explained within one working day · K0 missing its 60-second target in a drill · a data-protection objection to the reads, or an objection from employee representative bodies where your jurisdiction has them. Aborting means pulling K2 and K4 ([ARCHITECTURE.md](ARCHITECTURE.md) §4.6), not changing a level. |

### S1 — Hands held

| | |
|---|---|
| **Purpose** | Real writes, every one confirmed by a human in chat. Prove the write path, the pre-state capture, the verification and the inverses before anything unattended touches Workspace. |
| **Value** | Leaver and joiner actions from chat with pre-state shown. Licence reclaim on suspended accounts, on request — the first measurable saving. |
| **Levels** | F3, F4, F5, F7 at **L3 on chat**; the same families stay L1 on scheduled. |
| **Scope** | Writes only inside the pilot OU allowlist. Max 10 objects per request. Business hours. Daily write budget 10. |
| **Operators** | The ladder owner plus one or two named Workspace admins. |
| **Controls first** | Pre-state capture on every write · the inverse table implemented and **every inverse exercised on test accounts in a game day** · verification by re-read · group classification list published · the super-admin grant gate above is passed (no role extended with update privileges: reversed 2026-09-13, P33). Nothing on Google's side narrows the write privilege, so the pilot OU allow-list, `SAFE_USER_FIELDS` and the hard-denied list are hard invariants in the policy chain, tested by the denial suite. The gate change first executes in the sandbox Workspace tenant ([decision 29](09-open-decisions.md), platform HLD §3.1 nonprod row) · the band-B two-person surface live before any band-B request is accepted. |
| **Exit criteria** | ≥ 50 executions across ≥ 3 families by ≥ 2 operators · **zero unintended changes**, defined as a change reverted within 7 days and attributed to Wall-E error rather than changed intent · zero executions against a protected principal (denials are fine, executions are not) · a rollback deliberately exercised end to end · for each family to be promoted, shadow plan precision over four consecutive weekly runs clears the promote gate of [../mo/03-metrics-contract.md](../mo/03-metrics-contract.md) §4 (Wilson lower bounds ≥ 0.90, ≥ 35 decided items) · decision record. |

### S2 — Proposals

| | |
|---|---|
| **Purpose** | Let scheduled runs execute reads and templated notifications unattended, and put the writes that matter in front of humans as proposals so precision can be measured before anyone lets them execute. |
| **Levels** | Scheduled: F1 L5, F2 L4 (templated notification is the first autonomous write in the whole programme), write families L2. Event trigger opens at L1 shadow. |
| **Scope** | Proposals capped at 20 objects per run, pilot OU. Daily write budget 10, and templated notifications only. (Budgets rise monotonically across stages: 10, 10, 25, 50, then reviewed quarterly, so no cap ever tightens while autonomy widens.) |
| **Controls first** | Run and plan tables · proposal queue with verdict reason codes · plan freeze and hash · Workspace audit-log sharing enabled and the Cloud Logging sink to Pub/Sub working · dead-letter topic · event dedup store. |
| **Exit criteria** | ≥ 35 proposals decided per family to be promoted, clearing the promote gate of [../mo/03-metrics-contract.md](../mo/03-metrics-contract.md) §4 (Wilson 95 % lower bound and conservative lower bound ≥ 0.90; the sample floor and the gate are one decision, [14](14-hld-challenge.md) C18), drawn from at least three distinct runs · median time-to-verdict under one business day · ≥ 50 events processed in shadow with zero denials · zero drift on the F2 notifications actually executed · decision record. |

### S3 — Batch approval

| | |
|---|---|
| **Purpose** | The first autonomous `WRITE_HIGH` — with a human approving the batch. This is where the toil genuinely goes away, and it is the stage to sit in longest. |
| **Levels** | Scheduled write families at **L3 batch**: the run plans, freezes, and waits; one operator approves the whole plan; each item is re-read before it executes. Event: F1 L5, F2 L2. Inbox opens at L1 for reads. |
| **Scope** | Max 10 objects per run rising to 25 after 20 clean runs · OU allowlist · group class `low` only · business hours, last write at 16:00 · daily write budget 25 · canary: a new family applies to 20 % of targets for its first 10 runs. |
| **Controls first** | Batch approval bound to the plan hash · per-item re-read and skip-on-change · rollback plan generated at plan time, but executed only on a **fresh** human approval against **fresh** pre-state — a week-old approval is bound to a pre-state hash that is stale by definition · **Eve running in observe mode**, producing verdicts that are logged and graded but not enforced. This is the shadow stage of Eve's gate layer only; Eve's observe-and-report layer has been live since before the grant (see "The super-admin grant — a gate, not a stage"). |
| **Exit criteria** | ≥ 50 approved `WRITE_HIGH` items, ≤ 2 % rejected for Wall-E error, verification ≥ 99.5 % with **zero drift** · **Eve acceptance test passed**: Eve observed ≥ 30 days, agreed with human verdicts ≥ 95 %, and caught ≥ 95 % of deliberately seeded faults in a chaos exercise · approval SLA met ≥ 80 % of the time, otherwise the rota is not ready and S4 would just build a queue · kill-switch drill within 30 days · decision record signed by **two humans**. |

### S4 — Eve gates

| | |
|---|---|
| **Purpose** | Replace the per-item human with Eve for the families that have earned it. The operator's job becomes reading a notification and, rarely, vetoing. |
| **Levels** | Scheduled: F3, F4, F7 at **L4** with a 30-minute hold; F5 suspend at L3. Event: F2 L4, F3 L3. Inbox: F1 L5, writes L2 — its permanent ceiling. |
| **Controls first** | Eve's approval key in `EVE_PROJECT`, signable only by `eve-controller@EVE_PROJECT`, with Wall-E holding only the pinned public PEM · signature verification · hold window and veto surface · **Eve-unreachable degrades to waiting, never to executing**, tested · Eve's independent read credential · post-hoc verification SLA measured. |
| **Exit criteria** | ≥ 100 Eve-gated executions, human vetoes ≤ 1 %, zero drift · Eve availability ≥ 99 % in business hours · Eve verdicts still agreeing with a sampled human review ≥ 98 % · zero severity-1 or severity-2 events · a rollback drill passed at this level · decision record, two humans plus Eve's attestation. |

### S5 — Steady state

| | |
|---|---|
| **Levels** | F5 suspend reaches L4 with a 2-hour hold, **and only when the trigger is a system of record** — an HR feed or a human admin's own suspension event, never free text and never inbox. Everything else sits at its earned level. |
| **Rhythm** | Weekly: read every `WRITE_HIGH` row, five minutes well spent. Monthly: kill-switch drill, rollback drill, regenerate the ladder-state page. Quarterly: Mo's proposals reviewed, budgets and OU scope re-decided, and a pruning of three checks (it replaced removing unused privileges from the custom role on 2026-09-13, because a super admin has no privilege to prune; P33). Catalogue operations and band-B method-table rows unused in the quarter are removed. The two OAuth clients' scope sets are compared with what the catalogue and band B used. The super-admin roster is reviewed against the committed roster (a roster check, not a role diff; platform HLD §13.1 item 5, P68). |
| **What never changes** | The ceilings in §4, including the `SUPER` and `WRITE-generic` rows · the two lists (hard-denied; band B only, [03](03-lld.md) §"The hard-denied list"), which replaced the never-list in [06](06-security-guardrails.md) on 2026-09-13 (P29) · humans raise, machines lower · a new operation enters at L0 and walks its own mini-ladder. |

## 8. Metrics the ladder is argued from

The ladder is argued from ten metrics — hard-invariant denials, plan precision, verification
success, breaker trips, invalid parameters, run reliability, Eve post-hoc latency, approval
latency, audit completeness (the headline) and drill freshness — over a thirty-day rolling window
evaluated hourly; until Eve exists they are BigQuery scheduled queries (Eve v0, not skipped), run
in `EVE_PROJECT` and `MO_PROJECT` and never as jobs in Wall-E's project. The canonical
definitions, targets and breach responses of all ten, and of metric 9b, are
[../mo/03-metrics-contract.md](../mo/03-metrics-contract.md#72-wall-es-pack--the-ten-metrics-audit-completeness-first)
§7.2, and plan precision is judged by the interval gates of
[../mo/03-metrics-contract.md](../mo/03-metrics-contract.md#4-the-gates) §4, not by point
thresholds. **The error budget for a wrong autonomous write is zero**: it is an incident and a
demotion, never budget consumption
([../mo/03-metrics-contract.md](../mo/03-metrics-contract.md#8-error-budget-semantics) §8).

The breach responses the ladder's enforcement leans on most, in digest (mo/03 §7.2 wins on any
difference):

| Metric | Target | Breach → |
|---|---|---|
| Hard-invariant denials, autonomous runs | 0 | Any one: family to L0 synchronously, incident |
| Verification success | ≥ 99.5 % | Any `drift`: one level down plus incident. `unverifiable` above 2 %: one level down |
| Breaker trips | — | 2 or more distinct `error_class` values in a run aborts it, no-ops (desired state already held) excluded. More than 3 automatic demotions in an hour is severity 2 |
| Audit completeness (the headline) | 100 %; uncatalogued robot admin events 0 | Below 100 %: halt writes until reconciled. Any uncatalogued event: severity 1 |
| Drill freshness | ≤ 30 days | Stale: CI refuses every promotion |

## 9. Severity and automatic response

| Sev | Definition | Automatic | Human follow-up |
|---|---|---|---|
| **1** | Any **effect** on a protected principal, a security-class group, or a target outside the allowlist. Any interactive login to the robot. Any forged approval, or one posted by the agent. Any operation executed that was not in the frozen plan. | **Halt writes**, all autonomous triggers off, every write family to L0 | Root cause in 5 working days; promotions frozen 30 days; decision record to resume |
| — | **Not severity 1:** a protected-principal *denial* on a human chat request. An operator asking about someone who turns out to be a delegated admin is the control working. It is an audit row and nothing else. | none | none |
| **2** | Verification drift on a write. A budget cap hit. An Eve approval later overturned. A run executed outside its window. | Family to L0; the trigger class that produced it paused | Root cause in 10 days; promotions frozen 14 days |
| **3** | A proposal rejected for a policy reason. An unexplained run failure. An audit gap. | Family down one level | Noted on the ladder-state page, reviewed weekly |

## 10. Recording a promotion

Config lives in `walle/config/ladder.yaml`. CI refuses the merge if a level went up
without a link to an `accepted` decision file, if the level exceeds a ceiling, if a
WRITE_HIGH promotion lacks a second named approver, if an override for that cell exists
and the pull request does not reference its incident, if the dwell rule in §6 is not
satisfied, or if the last drill recorded in Firestore is older than 30 days. CI also refuses
the merge (platform HLD §13.1 item 9) if any operation of the
`SUPER` or `WRITE-generic` rows appears in any playbook's `uses`, or if either row in
`ladder.yaml` differs from its schema-fixed value.

**The gate cannot be part of what it gates.** One pull request could otherwise change the
ladder, the ceiling module and the validator together, and CI would happily check the new
ladder against the new ceilings. So: separate code ownership requiring a security approver
on the ceiling module, the policy chain, the catalogue's risk tiers and the validator; the
validator runs as a required check owned outside the repository; and the running service
publishes `ceilings_sha` on its ladder endpoint and stamps it on every audit row, with the
deploy tool refusing a config whose declared hash does not match what is running. A ceiling
change then costs a deploy, and the deploy is separately approved.

One file per promotion, using the wiki decision template plus five mandatory lines:

```
wiki/decisions/YYYY-MM-DD-walle-promote-<family>-<trigger>-L<n>.md

- Config version: 2026.09.0-1 → 2026.10.0-1
- Evidence: <metric values, the query used, the window>
- Drill: <date of last kill-switch drill>
- Approvers: <ladder owner>; <second human, required for L4/L5>
- Demote if: <the breach thresholds of mo/03 §7.2 that apply to this cell>
```

Automatic demotions do **not** write decision files — machines do not decide. They write
an incident note under `platform/wall-e/incidents/`, and the re-promotion decision
references it. A stage transition is one decision file bundling every cell it promotes,
with the previous stage's exit evidence attached.

A generated page, `platform/wall-e/ladder-state.md`, shows the current matrix, active
overrides, config version and last drill date. Mo owns regenerating it once Mo exists, as a
job in `MO_PROJECT`; until then it is a scheduled query in `EVE_PROJECT` (Eve v0) pasted in
weekly.

## 11. Assumptions in this document

Everything here about your organisation is assumed, not verified. Each one is a
[decision](09-open-decisions.md) and each changes numbers in the tables above.

**User creation is not on this list and not in F8.** Since 2026-09-13 the account holds
Super Admin (P33; platform HLD §13.1), so it **does** have the privilege — which the retired
custom role withheld — and Google refuses nothing. Only the catalogue and the ladder
hold user creation back. Deleting an admin is on the hard-denied list and refused in every
lane. Deleting a non-admin user is reachable only through band B at tier `SUPER`. Creating a
user is not a catalogue family. Until a decision record catalogues it through F8 at L0, a
human can ask for it only through band B, at the tier the committed method table in
[03](03-lld.md) assigns. It is never a promotion.

| Assumption | Where it bites | Decision |
|---|---|---|
| A sandbox with synthetic accounts can be created, plus one small real pilot OU. The sandbox is a separate Workspace tenant, never an OU, because Super Admin cannot be limited to an OU (decision 29; P40). The pilot OU is an allow-list enforced in code | Every stage's scope limit, and S1 in particular — without a sandbox the first real writes land on real users | 5, 29 |
| Business hours are Europe/Paris, Mon–Fri, last write 16:00 | Every autonomous gate, hold windows, the weekend suspension block | 15 |
| At least one more Workspace admin joins `walle-operators@` by S1, and a second approver is named by S3 | S3 and every L4/L5 promotion. A one-person rota also makes approval latency the binding constraint | 11 |
| Google Chat is available as the approval and digest surface | The proposal queue and hold-window veto | 14 |
| The example playbooks reflect real toil | S0's shadow evidence is only useful if it shadows work you actually want done | 12 |
| The Workspace edition supports sharing the audit events the event trigger needs | S2's event trigger class | verify in console |
| An HR system of record exists and is reachable | S5's autonomous suspension. If not, F5 stops at L3 permanently, which is acceptable | 13 |
