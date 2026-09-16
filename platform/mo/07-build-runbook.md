# 7. Building Mo

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-15
- Status: **superseded on 2026-09-15**. Retired to a pointer page on 2026-09-16. Never executed. Nothing on this page is run again.
- Replaced by: [02](../agentic-platform/setup/02-toil-baseline.md), [22](../agentic-platform/setup/22-mo-foundations.md), [29](../agentic-platform/setup/29-mo-eve-quality-pack.md), [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) and [40](../agentic-platform/setup/40-mo-after-stage-0.md) of the human-executed setup procedures in [../agentic-platform/setup/](../agentic-platform/setup/README.md).
- Review that retired it: [../agentic-platform/13-setup-procedure-review.md](../agentic-platform/13-setup-procedure-review.md) (S043, S055, S084, S144 and the Mo findings of its §4).

This runbook brought Mo into existence phase by phase (Mo-0 to Mo-12, 1,744 lines), against
`MO_PROJECT`, with the cross-project grants left to Wall-E's and Eve's runbooks. The setup review
of 2026-09-15 found that it could not be run: the 20 schema files, the SQL, the two images and
`gates.yaml` it loops over do not exist and no repository was named (S043); the validator's
reader and the `grades_eve` source had no maker (S055); the toil baseline of Mo-0 cannot be taken
later and so belongs on day one, before anything else in the programme (S084); and the dataset
names were agent-specific where the design says agent-neutral (S144). The owner's order of
2026-09-15 is the platform first, then Mo and Eve as one block, then Wall-E. Mo's steps now sit
in that order, in one set with one entry point,
[../agentic-platform/setup/README.md](../agentic-platform/setup/README.md): the toil baseline is
the first act of the set (02), Mo's foundations run beside Eve's first half (22), the Eve
quality pack once Eve's views exist (29), the Wall-E pack when Wall-E exists (36), and the
reporter, graders and first merged proposal after Stage 0 (40). Each new file lists under
"Salvaged" what it kept from here and under "Not copied" what the review showed wrong. Steps
that need code not yet committed are marked BLOCKED there and indexed in the
[setup README](../agentic-platform/setup/README.md) §8; nothing here was executable without it either.

## Where each phase went

Step ids are those of the new files (prefix index: [setup README §5.1](../agentic-platform/setup/README.md#51-step-prefix-index)).

| Old phase or section | New file | Steps |
|---|---|---|
| What already exists, and what does not | the BLOCKED index of the [setup README](../agentic-platform/setup/README.md) §8 (B-xx rows) | — |
| Prerequisites: upstream schema work | [22](../agentic-platform/setup/22-mo-foundations.md) §5, the build-inputs gate | MO-5.* |
| Prerequisites: decisions | [03](../agentic-platform/setup/03-decisions-and-people.md) §9 | DC-9.* |
| Prerequisites: access | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §2; [12](../agentic-platform/setup/12-privileged-access-catalogue.md) | PR-2.*, PA-* |
| Set these once per shell | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §5 (`~/.platform-env`) | PR-5.* |
| Mo-0 the toil baseline | [02](../agentic-platform/setup/02-toil-baseline.md) in full; the load into BigQuery in [22](../agentic-platform/setup/22-mo-foundations.md) §8 | TB-1.* to TB-5.*, MO-8.* |
| Mo-1 step 0, the project | [22](../agentic-platform/setup/22-mo-foundations.md) §1 and §2 (register row, `FM-IMPROVER` run) | MO-1.*, MO-2.* |
| Mo-1 the four datasets | [22](../agentic-platform/setup/22-mo-foundations.md) §6, under the agent-neutral `MO_*_DS` names | MO-6.* |
| Mo-2 `mo-metrics@` and its grants | [22](../agentic-platform/setup/22-mo-foundations.md) §3, §9 and §10; the `walle_audit` reader on Wall-E's side in [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §8; the `eve_quality` reader in [29](../agentic-platform/setup/29-mo-eve-quality-pack.md) §2 | MO-3.*, MO-9.*, MO-10.*, WD-8.*, MQ-2.* |
| Mo-3 `gates.yaml`, the UDFs and the golden fixtures | [22](../agentic-platform/setup/22-mo-foundations.md) §4 and §7 | MO-4.*, MO-7.* |
| Mo-4 the metric queries (Wall-E pack) | [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §7 | WJ-7.* |
| Mo-4 the Eve pack | [29](../agentic-platform/setup/29-mo-eve-quality-pack.md) §3 and §4 | MQ-3.*, MQ-4.* |
| Mo-5 assertion queries and the daily snapshot | [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §8 | WJ-8.* |
| Mo-6 `mo-analyst@`, the authorised views, the surrogate keys | [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §9 | WJ-9.* |
| Mo-7 `mo-reporter`, its schedule and the absence alert | [40](../agentic-platform/setup/40-mo-after-stage-0.md) §1 to §4 | MA-1.* to MA-4.* |
| Mo-8 artefact paths, readers and the grader list | [40](../agentic-platform/setup/40-mo-after-stage-0.md) §5 | MA-5.* |
| Mo-9 the drop box, CI ingestion and the recompute check | [40](../agentic-platform/setup/40-mo-after-stage-0.md) §6 to §8 | MA-6.* to MA-8.* |
| Mo-10 the linked Spans dataset (S3) | [40](../agentic-platform/setup/40-mo-after-stage-0.md) §9 | MA-9.* |
| Mo-11 `mo-narrator@` (S4, optional) | [40](../agentic-platform/setup/40-mo-after-stage-0.md) §10 | MA-10.* |
| Mo-12 the denial tests | [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §10 (identity and dataset negatives); [40](../agentic-platform/setup/40-mo-after-stage-0.md) §11 (MD-5 to MD-8, MD-14, the drop-box half of MD-15) | WJ-10.*, MA-11.* |
| The manual steps, collected | the Who column of the [setup README](../agentic-platform/setup/README.md) §3.2 and its role table §6 | — |
| What this runbook forces on Wall-E's own set | [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) (the joins) and [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §8 | WJ-*, WD-8.* |

## Retired headings

The headings below are kept only because other pages link to them. Each carries one pointer and
nothing else.

## Phase Mo-1 — step 0, the project **NEW**

Moved to [22](../agentic-platform/setup/22-mo-foundations.md) §1 and §2 (MO-1.*, MO-2.*).

## Phase Mo-1 — the four Mo datasets **NEW**

Moved to [22](../agentic-platform/setup/22-mo-foundations.md) §6 (MO-6.*).

## Phase Mo-2 — `mo-metrics@` and its grants **NEW**

Moved to [22](../agentic-platform/setup/22-mo-foundations.md) §3, §9 and §10 (MO-3.*, MO-9.*, MO-10.*); the foreign readers to [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §8 and [29](../agentic-platform/setup/29-mo-eve-quality-pack.md) §2.

## Phase Mo-6 — `mo-analyst@`, the authorised views, and the surrogate keys **NEW**

Moved to [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §9 (WJ-9.*).

## Phase Mo-9 — The drop box, CI ingestion, and the validator's recompute check (S2 exit)

Moved to [40](../agentic-platform/setup/40-mo-after-stage-0.md) §6 to §8 (MA-6.* to MA-8.*).

## Phase Mo-10 — The linked Spans dataset (S3)

Moved to [40](../agentic-platform/setup/40-mo-after-stage-0.md) §9 (MA-9.*).

## Phase Mo-11 — `mo-narrator@` (S4, optional)

Moved to [40](../agentic-platform/setup/40-mo-after-stage-0.md) §10 (MA-10.*).

## Phase Mo-12 — The denial tests, authored from Mo's side

Moved to [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §10 (WJ-10.*) and [40](../agentic-platform/setup/40-mo-after-stage-0.md) §11 (MA-11.*).

## Related documents

- [../agentic-platform/setup/README.md](../agentic-platform/setup/README.md), the one entry point
- [../agentic-platform/13-setup-procedure-review.md](../agentic-platform/13-setup-procedure-review.md), the review that retired this page
- [README.md](README.md), the Mo design set; [01-hld.md](01-hld.md); [02-identity-and-access.md](02-identity-and-access.md); [08-open-decisions.md](08-open-decisions.md)
- [../project-topology.md](../project-topology.md), the authority for placement and cross-project grants
