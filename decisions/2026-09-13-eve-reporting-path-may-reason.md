# 2026-09-13 — Eve's reporting path may reason

- **Status:** proposed — recorded 2026-09-13 as platform register row **P34**
  ([../platform/agentic-platform/12-open-decisions.md](../platform/agentic-platform/12-open-decisions.md)),
  recommended by the platform HLD §13.2. It becomes accepted when the Eve owner and the security
  reviewer sign below. Nothing is built.
- **Deciders:** the Eve owner (on 2026-09-13 the platform owner holds the role until the second
  human outside the Wall-E administration line is named, platform HLD §0.3), with the security
  reviewer.
- **Date:** 2026-09-13
- **Register row:** P34. Depends on it: P19 (`eve-advisor`'s EU AI Act class, legal), P123
  (re-qualification of the reporting path on a model-pin change).
- **Gate it blocks:** the `eve-advisor` build (Wall-E Stage 1 group of the register, §5).
- Append-only. Never edit this file's decision; supersede it with a new dated record.

## Context

The objective of 2026-09-13 says Eve "needs to control & report any misbehaviour of Wall-E",
"should work independantly & autonomous" and "needs to report to the human anything wrong".

Eve's set as written on 2026-09-12 is deterministic end to end: its settled row "No model
anywhere in Eve v1 or v2" ([../platform/eve/09-open-decisions.md](../platform/eve/09-open-decisions.md)),
the row "`eve-advisor` is not built", and Wall-E's challenge alternative "An LLM Eve — Rejected"
([../platform/wall-e/14-hld-challenge.md](../platform/wall-e/14-hld-challenge.md)), all resting
on Wall-E decision 34 ("Eve is a deterministic verifier; no LLM produces an approval",
[../platform/wall-e/09-open-decisions.md](../platform/wall-e/09-open-decisions.md)) and on C12.
The argument was right for the **approval** path — a controller whose approval can be talked
into existence is not a control — and was generalised to all of Eve's output.

Under the objective, Eve reports misbehaviour, not only breaches of a closed invariant list, and
with a super-admin Wall-E (P33) the operator prompting is itself the escalation. "Anything wrong"
cannot be enumerated in a closed vocabulary; the deterministic detection catalogue is where the
enumeration ends. The `eve-advisor` slot was left named and empty precisely so that filling it
would be a decision record, not an implementation detail — this is that record.

Standing constraints this decision may not loosen: no model produces an Eve approval, veto,
halt, demote or signature; the language model holds no credential; humans raise autonomy and
machines lower it; safety interlocks are plain authenticated REST.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| No reporting path; "anything wrong" stays the deterministic catalogue only | Eve stays entirely outside the EU AI Act's Art. 3(1) AI-system definition; nothing to classify | The objective's "report anything wrong" is met only as far as rules were foreseen; novel misbehaviour is invisible until a human writes a rule |
| A model inside Eve's control path (gate or reconciler) | One component | Forbidden by the standing constraint: a model output on the authority path; voids the control path's not-an-AI-system determination ([../platform/agentic-platform/10-eu-ai-act.md](../platform/agentic-platform/10-eu-ai-act.md) §3.2) |
| **A separate, report-only reasoning path `eve-advisor` in its own project (chosen, recommended)** | Covers what the catalogue cannot enumerate; the control path stays model-free and deterministic by absence | A second Eve project; a classification question for legal (P19); paging budget to protect; the path reads administrator-action logs that concern human administrators too |

## Decision

**Eve's reporting path may reason.** The settled row "No model anywhere in Eve v1 or v2" and
"An LLM Eve — Rejected" are **reopened for the reporting path only**, limited to `eve-advisor`
as a report-only path, exactly as platform HLD §13.2 specifies:

- **Placement.** `eve-advisor` runs in `EVE_ADVISOR_PROJECT` under `fld-controllers`, identity
  `eve-advisor@`. The `aiplatform.googleapis.com` denylist stays on `EVE_PROJECT` **at project
  level** (not on `fld-controllers`, which would also deny the reporting path), so Eve's control
  path remains model-free by absence and CI-checked.
- **Reads.** `eve.*`, `eve_workspace_logs` and the report tables through authorised views with
  no free-text columns, never the source datasets.
- **Writes.** Only `eve.incidents.narrative` and `eve.advice`, through the dedicated dataset
  `eve_advice` in `EVE_PROJECT` with `roles/bigquery.dataEditor` on that dataset only
  ([../platform/project-topology.md](../platform/project-topology.md) §3).
- **Holds nothing else.** No signer, no `run.invoker`, no secret access, no write to
  `eve/config`.
- **Report-only by construction.** Nothing it writes is read by `eve-gate`, `eve-reconciler`,
  `walle-actions` or `walle-actions-super`; the gate reads `eve.*` control tables and
  `eve/config`, never `eve.advice`. No model output enters a verdict.
- **What it may do.** Page at **severity 2 only**, inside the page budget, citing the
  deterministic findings that triggered it. A human who agrees with a "wrong accept" finding
  halts or demotes through the existing human path and tightens Eve's rules through a
  human-merged `thresholds.yaml` change (Mo's `eve_threshold_tighten` type, platform HLD §13.3).
- **What it may not do until P19 is answered.** Produce a finding about a named human without the
  deterministic rule that triggered it; be registered; be built without a class (the admission
  gate refuses).

Wall-E decision 34 **stands** for approve, halt, demote and veto. Wall-E `08-team-eve-mo.md`
item 5 ("halting, on its own judgement") narrows to the reporting path's *reporting*, not to a
halt.

## Consequences

- A fifth agent-set project, `EVE_ADVISOR_PROJECT`, with its cross-project rows in
  [../platform/project-topology.md](../platform/project-topology.md) §3 (the authorised-view
  reader and the `eve_advice` writer), made by Eve's runbook.
- Eve's control path keeps its EU AI Act determination as **not an AI system** and an Art. 14
  oversight measure; `eve-advisor` gets its own class under P19 (the likely outcome recorded as
  `annex_iii_adjacent` is legal's call, not this record's —
  [../platform/agentic-platform/10-eu-ai-act.md](../platform/agentic-platform/10-eu-ai-act.md) §3.3).
- A model-pin change on `eve-advisor` resets its paging thresholds to defaults and re-runs the
  seeded-fault set before it may page again (P123).
- Eve's set is edited per platform HLD §18 items 11–12: structural choice 1, `03-lld.md` line
  12, `04-flows.md` judgement lines, `06-failure-modes.md` line 21 and `README.md` "Not a model"
  are narrowed to the authority path; the `eve-advisor` row "Never, on current evidence" is
  replaced by a dated pointer to this file.
- Rules out: any wire, grant or reader by which an `eve-advisor` output reaches the gate or an
  action service (an earlier draft's "can raise a refusal through the existing wire" was removed
  on 2026-09-13 for that reason); severity-1 paging by the reporting path.
- Revisit: when P19 is answered; on the first seeded-fault run of the reporting path; if Eve's
  control path relocates to the witness (P15).

## Supersedes

| Record | Effect |
|---|---|
| Eve settled row "No model anywhere in Eve v1 or v2" ([../platform/eve/09-open-decisions.md](../platform/eve/09-open-decisions.md)) | **Reopened for the reporting path only**; stands for the control path |
| Eve settled row "`eve-advisor` is not built" | **Superseded**: the slot may be filled under the limits above, after P19 |
| Wall-E challenge alternative "An LLM Eve — Rejected" ([../platform/wall-e/14-hld-challenge.md](../platform/wall-e/14-hld-challenge.md)) | **Qualified**: stands for an Eve that approves; not for a report-only path |
| Wall-E decision 34 | **Stands** for approve, halt, demote, veto; its reporting half reopened |
| Eve E-7 (halting bias; "own judgement" void) | **Stands** for halting; moot for a report-only path |

Added 2026-09-13 (review-findings pass; the decision above is unchanged): every effect in this
table takes effect **on acceptance**. While the status is *proposed*, the row "`eve-advisor` is
not built" is **reopened (pending acceptance)**, not superseded, and the other rows stand as
written in Eve's and Wall-E's sets.

## Signatures

| Role | Duty | Signed |
|---|---|---|
| Eve owner (the second human outside the Wall-E administration line; held by the platform owner until named) | decides | *tbd* |
| Security reviewer (decision 37) | co-signs | *tbd* |
| Legal | answers P19 (the class), which gates paging rights and any registration | *tbd* |
