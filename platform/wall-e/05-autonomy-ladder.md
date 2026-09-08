# 5. The autonomy ladder

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-08

This is the step-by-step enablement plan and the control that goes with it. Every number
here is an opinionated default meant to be tuned in the decision record that opens each
stage — but the *shape* is the design, and the shape is not negotiable without redoing
[06-security-guardrails.md](06-security-guardrails.md).

## 1. The eight rules

| # | Rule | Consequence |
|---|---|---|
| R1 | **Autonomy belongs to a pair, never to the agent.** A level attaches to (operation family, trigger class). | "Wall-E is autonomous" is never true. It is L5 for reading and L0 for suspending from mail, at the same moment. |
| R2 | **Humans raise, machines lower.** Raising needs a pull request and a dated decision record. Lowering is one API call by any operator, Eve, or a breaker, and the paperwork follows. | The asymmetry is the safety story. |
| R3 | **One notch, one family, on evidence.** No skipping levels. Minimum dwell at each. A new operation enters at L0 whatever stage the programme has reached. | "We are at Stage 4, so the new thing is autonomous" cannot happen. |
| R4 | **Reversibility outranks risk tier.** Only operations with an exact inverse can reach the top levels. | Sending mail is low-risk and irreversible, so it is capped. Suspending is high-risk and reversible, so it can climb. |
| R5 | **Every level is enforced in the action service.** The agent is told `ok`, `shadow`, `proposal`, `approval_required` or `denied`, and never learns why. | Same argument as the approval token: nothing the model can set. |
| R6 | **Verify every write by re-reading.** A write whose observed post-state does not match the plan is a `drift`, which demotes the family and opens an incident. | This is the signal Eve audits and Mo learns from. |
| R7 | **No silent level.** There is no level above execute-and-report. Every autonomous write appears in a run report and a daily digest. | If nobody would notice it happening, it does not happen. |
| R8 | **Evidence, not calendar.** Minimum durations exist only so evidence can accumulate. Time alone promotes nothing. | Stages have floors, not schedules. |

## 2. The six levels

| Level | Name | What the action service does | Who is asked | Who is told |
|---|---|---|---|---|
| **L0** | **OFF** | Runs the full policy chain, then denies with `level_off`. The operation stays in the catalogue so re-enabling is config, not a deploy. | nobody | run report |
| **L1** | **SHADOW** | Forces `dry_run`. Runs allowlist, parameters, protected principals, scope, budgets — so denials are observed for real. Captures pre-state and the would-be verdict. **Never executes**, even if handed a valid approval. | nobody | run report, graded by an operator |
| **L2** | **PROPOSE** | As L1, plus writes a proposal to the operator queue with pre-state and rationale. **There is no execution path at L2**: a well-formed approval is refused with `level_no_execute`. A human who wants it done does it themselves, or in chat. | operator, for a verdict | operators |
| **L3** | **HUMAN** | Policy passes → `pending_human`. A named operator approves on the approval endpoint; the service verifies their group membership live, consumes the nonce, executes, verifies, records the approver. TTL 4 business hours, then `skipped`. | operator, for execution | operators, Eve |
| **L4** | **EVE** | Policy passes → `pending_eve`. Eve approves with **its own signing key** from its own service account. A **hold window** then opens during which any operator can veto with one click. Then execute and verify. | Eve, blocking; humans may veto | operators |
| **L5** | **AUTO** | Executes immediately within scope. The service verifies; **Eve verifies independently within 60 minutes**. Humans read a digest. | nobody | digest |

There is deliberately no L6. "Execute and tell nobody" is not a level, it is a defect.

Two parameters travel with each level assignment and are part of the config version:
`hold_minutes` (L4) and `notify` (`per_step` / `per_run` / `daily_digest`). Moving `notify`
from per-step to a digest *before* raising a level is a legitimate intermediate step and
often the right one.

## 3. Trigger classes

| Class | Trigger | Principal recorded | Trust | Note |
|---|---|---|---|---|
| **T0 chat** | Operator in Gemini Enterprise | the human's email | High — an authenticated operator asked | The only class Edge AI v2 had |
| **T1 scheduled** | Cloud Scheduler → dispatcher | `job:<playbook>`, `on_behalf_of` = owner | Medium — input is Wall-E's own reads | Business hours enforced |
| **T2 event** | Workspace audit log → Cloud Logging sink → Pub/Sub → dispatcher | `event:<rule>` | Medium-low — the payload is Google's, but the *cause* may be an attacker's action | A T2 run may not emit an event that starts another T2 run |
| **T3 inbox** | The robot's own mailbox | `inbox` | **Low — attacker-controlled text** | Read-only operation set. Writes derived from it are **proposals only, permanently.** |

Each class climbs **independently**. A family at L5 on `scheduled` is still L1 on `event`
until `event` has done its own progression. A new trigger is a new deployment, and new
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

Three permanent statements, said plainly:

- **`WRITE_HIGH` never reaches L5 on any trigger, at any stage.** A suspended user or a
  changed group membership is exactly the case where a second independent signature costs
  minutes and prevents incidents. If a case genuinely needs it later, the honest path is a
  decision record that re-tiers that one operation, not raising the ceiling.
- **T3 never produces a write.** Anything derived from mailbox content is a proposal.
- **Free-text outbound is never autonomous.** Autonomous runs may use `notify.operators`,
  whose recipients come from config and whose body is a template. `gmail.send` with a
  model-chosen recipient stays on the chat trigger. This closes the residual injection
  risk Edge AI v2 accepted.

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
| **F8 Later** | data transfer, archive, group create, user create | mostly no | enters at L0, own mini-ladder | decide per operation |

**F6 deserves its explanation.** Restoring access is a security decision, not hygiene. It
is the rollback path for F5, and a system that can suspend autonomously but needs a human
to un-suspend is the right asymmetry. Making restore autonomous would let a loop suspend
and restore repeatedly without anyone noticing.

## 6. Who may raise, who may lower

| Actor | Raise | Lower | Clear an override | Change a ceiling |
|---|---|---|---|---|
| Ladder owner (the platform owner) | Yes, one notch, with a decision record and a config version. **A second named human is required for any L4 or L5 promotion.** | Yes | Yes, in a new config version referencing the incident | No — code review, two humans, security sign-off |
| Any operator | No | **Yes, instantly, alone.** Anyone may pull the andon cord. | No | No |
| Eve | **Never.** Eve *attests* that criteria are met; it cannot act on its own attestation. | Yes, to any level, including halt | No | No |
| Breaker in the action service | No | Yes, to L0 for the family, synchronously | No | No |
| Mo | No — opens the pull request with evidence | No | No | No |
| Wall-E | **Never.** No catalogue operation touches config, overrides or halt flags; `walle-agent@` has no IAM on any of them. | Only by refusing its own run | No | No |

**The ratchet.** After any automatic demotion: minimum five business days at the lower
level, a written root cause, and a fresh decision record before re-raising. No exception
for "it was a false positive" — if it was, that is a finding about Eve or the metric, and
it belongs in the root cause.

**Minimum dwell before raising:** L1→L2 two weeks, L2→L3 two weeks, L3→L4 four weeks,
L4→L5 six weeks. The dwell clock restarts after any demotion of that family.

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

### S0 — Eyes

| | |
|---|---|
| **Purpose** | Deliver read-only value immediately, and start generating the evidence that every later promotion will be argued from. |
| **Value on day one** | Weekly digests that today are a spreadsheet or nothing: admin changes last week, accounts with no sign-in for 90 days by OU, licences by SKU, suspended-but-still-licensed accounts, groups with external members or no owner, admin-role holders versus a signed list. Plus ad-hoc directory questions in chat. |
| **Levels** | F1 L5 on chat and scheduled. Every write family L1 everywhere. `notify.operators` L5 to a fixed operator address. |
| **Scope** | Reads: whole tenant, rate-limited. Shadow write plans: pilot OU only. Daily write budget: 0. |
| **Operators** | the platform owner alone. |
| **Controls that must be live first** | Custom role, read-only privileges only, OU-scoped · robot account hardened, interactive-login alert firing · action service with catalogue, policy chain, durable budgets, write-ahead audit · ladder config v1 with everything at L1 · halt flags and the K0–K5 chain, drilled once with times recorded · dispatcher with per-job enable and budget · shadow grading sheet. |
| **Exit criteria** | ≥ 20 shadow runs covering every write family, each item graded, **≥ 95 % graded correct** · **zero** hard-invariant denials from autonomous runs (`protected_principal`, `operation_not_allowed`, bad approval) · zero requests without an audit row, verified by reconciling Cloud Logging against BigQuery · injection regression suite passes · K0 measured under 60 s, K5 measured · DPO or works-council question formally asked · decision record for S1 signed. |

### S1 — Hands held

| | |
|---|---|
| **Purpose** | Real writes, every one confirmed by a human in chat. Prove the write path, the pre-state capture, the verification and the inverses before anything unattended touches Workspace. |
| **Value** | Leaver and joiner actions from chat with pre-state shown. Licence reclaim on suspended accounts, on request — the first measurable saving. |
| **Levels** | F3, F4, F5, F7 at **L3 on chat**; the same families stay L1 on scheduled. |
| **Scope** | Writes only inside the pilot OU allowlist. Max 20 objects per request. Business hours. Daily write budget 50. |
| **Operators** | the platform owner plus one or two named DWP admins. |
| **Controls first** | Pre-state capture on every write · the inverse table implemented and **every inverse exercised on test accounts in a game day** · verification by re-read · group classification list published · role extended with update privileges only. |
| **Exit criteria** | ≥ 50 executions across ≥ 3 families by ≥ 2 operators · **zero unintended changes**, defined as a change reverted within 7 days and attributed to Wall-E error rather than changed intent · zero executions against a protected principal (denials are fine, executions are not) · a rollback deliberately exercised end to end · for each family to be promoted, shadow precision ≥ 95 % over four consecutive weekly runs · decision record. |

### S2 — Proposals

| | |
|---|---|
| **Purpose** | Let scheduled runs execute reads and templated notifications unattended, and put the writes that matter in front of humans as proposals so precision can be measured before anyone lets them execute. |
| **Levels** | Scheduled: F1 L5, F2 L4 (templated notification is the first autonomous write in the whole programme), write families L2. Event trigger opens at L1 shadow. |
| **Scope** | Proposals capped at 20 objects per run, pilot OU. Daily write budget 10, and templated notifications only. |
| **Controls first** | Run and plan tables · proposal queue with verdict reason codes · plan freeze and hash · Workspace audit-log sharing enabled and the Cloud Logging sink to Pub/Sub working · dead-letter topic · event dedup store. |
| **Exit criteria** | ≥ 30 proposals graded per family to be promoted, **precision ≥ 95 %**, drawn from at least three distinct runs · median time-to-verdict under one business day · ≥ 50 events processed in shadow with zero denials · zero drift on the F2 notifications actually executed · decision record. |

### S3 — Batch approval

| | |
|---|---|
| **Purpose** | The first autonomous `WRITE_HIGH` — with a human approving the batch. This is where the toil genuinely goes away, and it is the stage to sit in longest. |
| **Levels** | Scheduled write families at **L3 batch**: the run plans, freezes, and waits; one operator approves the whole plan; each item is re-read before it executes. Event: F1 L5, F2 L2. Inbox opens at L1 for reads. |
| **Scope** | Max 10 objects per run rising to 25 after 20 clean runs · OU allowlist · group class `low` only · business hours, last write at 16:00 · daily write budget 25 · canary: a new family applies to 20 % of targets for its first 10 runs. |
| **Controls first** | Batch approval bound to the plan hash · per-item re-read and skip-on-change · rollback plan generated at plan time and covered by the same approval for 7 days · **Eve running in observe mode**, producing verdicts that are logged and graded but not enforced. This is Eve's own shadow stage. |
| **Exit criteria** | ≥ 50 approved `WRITE_HIGH` items, ≤ 2 % rejected for Wall-E error, verification ≥ 99.5 % with **zero drift** · **Eve acceptance test passed**: Eve observed ≥ 30 days, agreed with human verdicts ≥ 95 %, and caught ≥ 95 % of deliberately seeded faults in a chaos exercise · approval SLA met ≥ 80 % of the time, otherwise the rota is not ready and S4 would just build a queue · kill-switch drill within 30 days · decision record signed by **two humans**. |

### S4 — Eve gates

| | |
|---|---|
| **Purpose** | Replace the per-item human with Eve for the families that have earned it. The operator's job becomes reading a notification and, rarely, vetoing. |
| **Levels** | Scheduled: F3, F4, F7 at **L4** with a 30-minute hold; F5 suspend at L3. Event: F2 L4, F3 L3. Inbox: F1 L5, writes L2 — its permanent ceiling. |
| **Controls first** | Eve's approval key, readable only by `eve-controller@` · signature verification · hold window and veto surface · **Eve-unreachable degrades to waiting, never to executing**, tested · Eve's independent read credential · post-hoc verification SLA measured. |
| **Exit criteria** | ≥ 100 Eve-gated executions, human vetoes ≤ 1 %, zero drift · Eve availability ≥ 99 % in business hours · Eve verdicts still agreeing with a sampled human review ≥ 98 % · zero severity-1 or severity-2 events · a rollback drill passed at this level · decision record, two humans plus Eve's attestation. |

### S5 — Steady state

| | |
|---|---|
| **Levels** | F5 suspend reaches L4 with a 2-hour hold, **and only when the trigger is a system of record** — an HR feed or a human admin's own suspension event, never free text and never inbox. Everything else sits at its earned level. |
| **Rhythm** | Weekly: read every `WRITE_HIGH` row, five minutes well spent. Monthly: kill-switch drill, rollback drill, regenerate the ladder-state page. Quarterly: Mo's proposals reviewed, budgets and OU scope re-decided, and **privileges the catalogue no longer needs are removed from the custom role**. |
| **What never changes** | The ceilings in §4 · the never-list in [06](06-security-guardrails.md) · humans raise, machines lower · a new operation enters at L0 and walks its own mini-ladder. |

## 8. Metrics the ladder is argued from

Thirty-day rolling window, evaluated hourly. Until Eve exists these are BigQuery scheduled
queries — call that Eve v0 and do not skip it.

| Metric | Definition | Target | Breach → |
|---|---|---|---|
| **Hard-invariant denials** | `protected_principal`, `operation_not_allowed`, bad approval, level bypass, from autonomous runs | **0** | Any one: family → L0 synchronously, incident |
| **Plan precision** | items accepted ÷ items graded | ≥ 95 % | < 95 % over 20 graded: one level down. < 90 %: L1 |
| **Verification success** | `verified` ÷ executed writes | ≥ 99.5 % | Any `drift`: one level down plus incident. `unverifiable` > 2 %: one level down |
| **Invalid parameters** | share of autonomous steps denied for bad parameters | < 1 % | > 1 %: promotions frozen. > 5 %: one level down |
| **Run reliability** | runs reaching a terminal state within budget | ≥ 99 % | < 97 %: `no_autonomous` for that playbook |
| **Eve post-hoc latency** | time to independent verification of an L5 write | ≤ 60 min p99 | Breach: promotions frozen. > 4 h: L5 cells drop to L4 |
| **Approval latency** | human time-to-verdict | p50 < 4 business hours | Not a Wall-E demotion; it blocks stage exit |
| **Audit completeness** | Workspace admin-audit events by the robot with a matching audit row | 100 % | < 100 %: halt writes until reconciled |
| **Drill freshness** | days since the last kill-switch drill | ≤ 30 | Stale: CI refuses every promotion |

**The error budget for a wrong autonomous write is zero.** It is an incident and a
demotion, not budget consumption. The metrics that behave like classic error budgets are
precision, verification and reliability: exhausting one freezes promotions for the rest of
the window; burning at twice the sustainable rate demotes a level; two demotions of the
same family in 90 days force a redesign of the playbook before re-entry.

## 9. Severity and automatic response

| Sev | Definition | Automatic | Human follow-up |
|---|---|---|---|
| **1** | Any effect on a protected principal, a security-class group, or a target outside the OU allowlist. Any interactive login to the robot. Any forged or invalid approval. Any operation executed that was not in the frozen plan. | **Halt writes**, all autonomous triggers off, every write family to L0 | Root cause in 5 working days; promotions frozen 30 days; decision record to resume |
| **2** | Verification drift on a write. A budget cap hit. An Eve approval later overturned. A run executed outside its window. | Family to L0; the trigger class that produced it paused | Root cause in 10 days; promotions frozen 14 days |
| **3** | A proposal rejected for a policy reason. An unexplained run failure. An audit gap. | Family down one level | Noted on the ladder-state page, reviewed weekly |

## 10. Recording a promotion

Config lives in `walle/config/ladder.yaml`. CI refuses the merge if a level went up
without a link to an `accepted` decision file, if the level exceeds a ceiling, if a
WRITE_HIGH promotion lacks a second named approver, if an override for that cell exists
and the pull request does not reference its incident, or if the last drill is older than
30 days.

One file per promotion, using the wiki decision template plus five mandatory lines:

```
wiki/decisions/YYYY-MM-DD-walle-promote-<family>-<trigger>-L<n>.md

- Config version: 2026.09.0-1 → 2026.10.0-1
- Evidence: <metric values, the query used, the window>
- Drill: <date of last kill-switch drill>
- Approvers: the platform owner; <second human, required for L4/L5>
- Demote if: <the thresholds from §8 that apply to this cell>
```

Automatic demotions do **not** write decision files — machines do not decide. They write
an incident note under `platform/wall-e/incidents/`, and the re-promotion decision
references it. A stage transition is one decision file bundling every cell it promotes,
with the previous stage's exit evidence attached.

A generated page, `platform/wall-e/ladder-state.md`, shows the current matrix, active
overrides, config version and last drill date. Mo owns regenerating it once Mo exists;
until then it is a scheduled query pasted in weekly.

## 11. Assumptions in this document

Everything here about the organisation was inferred, not told. Each one is a
[decision](09-open-decisions.md) and each changes numbers in the tables above.

| Assumption | Where it bites | Decision |
|---|---|---|
| A sandbox OU with synthetic accounts can be created, plus one small real pilot OU | Every stage's scope limit, and S1 in particular — without a sandbox the first real writes land on real users | 5 |
| Business hours are Europe/Paris, Mon–Fri, last write 16:00 | Every autonomous gate, hold windows, the weekend suspension block | 15 |
| At least one more DWP admin joins `walle-operators@` by S1, and a second approver is named by S3 | S3 and every L4/L5 promotion. A one-person rota also makes approval latency the binding constraint | 11 |
| Google Chat is available as the approval and digest surface | The proposal queue and hold-window veto | 14 |
| The example playbooks reflect real toil | S0's shadow evidence is only useful if it shadows work you actually want done | 12 |
| The Workspace edition supports sharing the audit events the event trigger needs | S2's event trigger class | verify in console |
| An HR system of record exists and is reachable | S5's autonomous suspension. If not, F5 stops at L3 permanently, which is acceptable | 13 |
