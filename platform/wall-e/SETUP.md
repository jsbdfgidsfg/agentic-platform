# Wall-E setup runbook

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-15
- Status: **superseded on 2026-09-15**. Retired to a pointer page on 2026-09-16. Never executed. Nothing on this page is run again.
- Replaced by: the human-executed setup procedures in [../agentic-platform/setup/](../agentic-platform/setup/README.md), files [30](../agentic-platform/setup/30-wall-e-workspace-side.md) to [39](../agentic-platform/setup/39-wall-e-stage-0.md), with the twin rehearsal in [37](../agentic-platform/setup/37-wall-e-sandbox-rehearsal.md) and the standing drills in [42](../agentic-platform/setup/42-gates-drills-and-evidence.md).
- Review that retired it: [../agentic-platform/13-setup-procedure-review.md](../agentic-platform/13-setup-procedure-review.md) (S066 and the Wall-E findings of its §4).
- Helper script: [setup/README.md](setup/README.md) explains why `walle_setup.py` is not used either.

The 21-phase runbook that stood here (18 numbered phases plus 12b, 12c and 13b, 3,014 lines) was
written as a standalone build of Wall-E from nothing to Stage 0. The setup review of 2026-09-15
found that it is not standalone: it depends on the platform bootstrap (folders, core projects,
PAM, policies, central logging), on Eve, on Mo, on the witness organisation and on the sandbox
twin, none of which it builds, and it carried thirteen blocking defects (among them the engine
created before its identity and gateway were known, S025; the approval surface that no phase
built, S009; the spike that could not be run by hand, S116; a folder that nothing created, S019).
The owner's order of 2026-09-15 is the platform first, then Mo and Eve, then Wall-E, in one
ordered set with one entry point, [../agentic-platform/setup/README.md](../agentic-platform/setup/README.md).
That set salvages what was correct here (the shapes, the verifies and the arguments each new
file lists under "Salvaged") and never copies what the review showed wrong. Every step there
carries WHO, WHERE, ACTION, VERIFY, ROLLBACK and EVIDENCE; the phases below did not.

## Where each phase went

Step ids are those of the new files (prefix index: [setup README §5.1](../agentic-platform/setup/README.md#51-step-prefix-index)).
A cell that names a section of a new file means the whole of that section.

| Old phase or section | New file | Steps |
|---|---|---|
| §0.1, §0.2 what you end up with | [setup README](../agentic-platform/setup/README.md) §1; [39](../agentic-platform/setup/39-wall-e-stage-0.md) "What this part builds" | — |
| §0.3 what it costs | [04](../agentic-platform/setup/04-purchases-and-lead-times.md) §5; [setup README](../agentic-platform/setup/README.md) §3.2 | PU-5.* |
| §0.4 how long each phase takes | [setup README](../agentic-platform/setup/README.md) §3.2, Hands-on and Elapsed columns, taken from each file's own estimate | — |
| §1.1 decisions that must be closed first | [03](../agentic-platform/setup/03-decisions-and-people.md) §10 and §11 | DC-10.*, DC-11.* |
| §1.2, §1.3 the scope list and why it is close to irreversible | [32](../agentic-platform/setup/32-wall-e-consents.md) §1 | WC-1.* |
| §1.4 accounts and permissions | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §2 and §3; [12](../agentic-platform/setup/12-privileged-access-catalogue.md) (time-boxed grants replace standing roles, S059) | PR-2.*, PR-3.*, PA-* |
| §1.5 tools to install | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §4 | PR-4.* |
| §1.6, §1.7 placeholders and per-shell variables | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §5 (`~/.platform-env`, `penv_set`, `walle_shell`; `PROJECT` and `FOLDER_ID` are retired names) | PR-5.* |
| Phase 1 Workspace identity and groups | [30](../agentic-platform/setup/30-wall-e-workspace-side.md) §1, §2, §3, §6, §7 | WW-1.* to WW-3.*, WW-6.*, WW-7.* |
| Phase 2 the super-admin assignment and its gate | [38](../agentic-platform/setup/38-super-admin-gate-and-grant.md) in full | GT-0.* to GT-9.* |
| Phase 3 harden the robot account | [30](../agentic-platform/setup/30-wall-e-workspace-side.md) §4 and §5 | WW-4.*, WW-5.* |
| Phase 4 the login reporting rule | [30](../agentic-platform/setup/30-wall-e-workspace-side.md) §8 | WW-8.* |
| Phase 5 audit-log sharing into Cloud Logging | [14](../agentic-platform/setup/14-central-logging-and-billing-export.md) §1 owns the tenant toggle; [30](../agentic-platform/setup/30-wall-e-workspace-side.md) §9 verifies it | CL-1.3, WW-9.* |
| Phase 6 project, APIs, service accounts (factory call and manual fallback) | [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §1 to §3 (register row, `FM-AGENT` run, Access Approval) | WD-1.* to WD-3.* |
| Phase 7 Firestore, BigQuery, Pub/Sub, Cloud Tasks | [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §4, §5, §8 | WD-4.*, WD-5.*, WD-8.* |
| Phase 8 regional secrets, insert-only audit role, Eve's public-key pin | [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §6, §7, §9, §10 | WD-6.*, WD-7.*, WD-9.*, WD-10.* |
| Phase 9 the OAuth clients and the consent sitting | [32](../agentic-platform/setup/32-wall-e-consents.md) in full; the post-grant reads in [39](../agentic-platform/setup/39-wall-e-stage-0.md) §1 | WC-0.* to WC-9.*, S0-1.* |
| Phase 10 the action service | [33](../agentic-platform/setup/33-wall-e-action-services-and-approval-surfaces.md) §1 to §4 and §6 | WS-1.* to WS-4.*, WS-6.* |
| §7.10 the approval surface (moved from "before Stage 1" to before the grant) | [33](../agentic-platform/setup/33-wall-e-action-services-and-approval-surfaces.md) §5 | WS-5.* |
| Phase 11 the dispatcher, the trigger feed and the log view | [33](../agentic-platform/setup/33-wall-e-action-services-and-approval-surfaces.md) §7 | WS-7.* |
| Phase 12 the agent on Agent Runtime | [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §2 to §5 (one sequence, S025); the post-grant half in [39](../agentic-platform/setup/39-wall-e-stage-0.md) §2 | WE-2.* to WE-5.*, S0-2.* |
| Phase 12b steps 1 to 6, the agent's identity | [34](../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md) §1 to §5; the after-binding requirements are executed by [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §4 | WI-1.* to WI-4.*, WE-4.* |
| Phase 12b step 7, the deny policy | [34](../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md) §6 (read); [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §6 (verified) | WI-6.*, WE-6.* |
| Phase 12c Model Armor templates, ingress gateway, floor | [34](../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md) §7 | WI-7.* |
| Phase 13 register and share in Gemini Enterprise | [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §7 (GE-12 admission) and §8 (share and user tests); the live front-door verify in [39](../agentic-platform/setup/39-wall-e-stage-0.md) §3 | WE-7.*, WE-8.*, S0-3.* |
| Phase 13b Agent Registry and the egress gateway | [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §1 (gateway before the engine) and §9 (allow-list against the shared registry) | WE-1.*, WE-9.* |
| Phase 14 ladder v1 and paused schedulers | [39](../agentic-platform/setup/39-wall-e-stage-0.md) §4 | S0-4.* |
| Phase 15 the collected cross-project verify | [39](../agentic-platform/setup/39-wall-e-stage-0.md) §5 | S0-5.* |
| Phase 16 the Gmail watch and its renewal | [39](../agentic-platform/setup/39-wall-e-stage-0.md) §6 | S0-6.* |
| Phase 17 the denial suite and the kill-switch drill | [37](../agentic-platform/setup/37-wall-e-sandbox-rehearsal.md) §6 and §8 on the twin; [39](../agentic-platform/setup/39-wall-e-stage-0.md) §7 and §8 on production | WR-6.*, WR-8.*, S0-7.*, S0-8.* |
| Phase 18 Stage 0 entry | [39](../agentic-platform/setup/39-wall-e-stage-0.md) §11 to §13 | S0-11.* to S0-13.* |
| §4 the denial test suite (52 tests, five boundaries) | [37](../agentic-platform/setup/37-wall-e-sandbox-rehearsal.md) §5 and §6 | WR-5.*, WR-6.* |
| §5 the kill-switch drill (K0 to K5) | [37](../agentic-platform/setup/37-wall-e-sandbox-rehearsal.md) §8; [39](../agentic-platform/setup/39-wall-e-stage-0.md) §8; the calendar in [42](../agentic-platform/setup/42-gates-drills-and-evidence.md) §5 | WR-8.*, S0-8.*, GD-5.* |
| §6.1 the Stage 0 checklist | [39](../agentic-platform/setup/39-wall-e-stage-0.md) §11 (part A) and §12 (strict verify and the record) | S0-11.*, S0-12.* |
| §6.2 what must not be done next without a decision record | [39](../agentic-platform/setup/39-wall-e-stage-0.md) §12, the record's "What may not happen next without a further record" | S0-12.* |
| §7 troubleshooting | §7.1 and §7.2 in [32](../agentic-platform/setup/32-wall-e-consents.md) §8; §7.4 and §7.6 in [39](../agentic-platform/setup/39-wall-e-stage-0.md) §6; §7.9 in [39](../agentic-platform/setup/39-wall-e-stage-0.md) §9; §7.10 in [33](../agentic-platform/setup/33-wall-e-action-services-and-approval-surfaces.md) §5; the rest is carried by the ROLLBACK line of the step concerned | — |
| The `walle_setup.py` manual steps M0 to M10 | [setup/README.md](setup/README.md), "Which new steps each subcommand would correspond to" | — |

## Retired headings

The headings below are kept only because other pages link to them. Each carries one pointer and
nothing else.

### 0.3 What it costs

Moved to [04](../agentic-platform/setup/04-purchases-and-lead-times.md) §5 and the [setup README](../agentic-platform/setup/README.md) §3.2.

### 0.4 How long each phase takes

Moved to the [setup README](../agentic-platform/setup/README.md) §3.2; the per-phase figures given here were kept in brackets only where a new file quotes them.

## Phase 6 — GCP project, APIs, service accounts

Moved to [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §1 to §3 (WD-1.* to WD-3.*), as an `FM-AGENT` run under [17](../agentic-platform/setup/17-factory-module-equivalents-and-tier-r-gate.md).

## Phase 7 — Firestore, BigQuery, Pub/Sub, Cloud Tasks

Moved to [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §4, §5 and §8 (WD-4.*, WD-5.*, WD-8.*).

## Phase 8 — Regional secrets, insert-only audit role, and Eve's public-key pin

Moved to [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §6, §7, §9 and §10 (WD-6.*, WD-7.*, WD-9.*, WD-10.*).

## Phase 10 — The action service

Moved to [33](../agentic-platform/setup/33-wall-e-action-services-and-approval-surfaces.md) §1 to §4 and §6 (WS-1.* to WS-4.*, WS-6.*).

## Phase 11 — The dispatcher, the trigger feed and the log view

Moved to [33](../agentic-platform/setup/33-wall-e-action-services-and-approval-surfaces.md) §7 (WS-7.*).

## Phase 12 — The agent on Agent Runtime

Moved to [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §2 to §5 (WE-2.* to WE-5.*); the post-grant half is [39](../agentic-platform/setup/39-wall-e-stage-0.md) §2.

## Phase 12b — The agent's identity: Agent Identity, with a gated fallback

Moved to [34](../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md) §1 to §6 (WI-1.* to WI-6.*); step 7 is verified in [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §6 (WE-6.*).

## Phase 12c — Model Armor: templates, the ingress gateway, and the floor

Moved to [34](../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md) §7 (WI-7.*).

## Phase 13 — Register and share in Gemini Enterprise

Moved to [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §7 and §8 (WE-7.*, WE-8.*).

## Phase 13b — Agent Registry, and the egress gateway in dry-run

Moved to [35](../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §1 and §9 (WE-1.*, WE-9.*).

## Phase 15 — Retired on 2026-09-13; the collected cross-project verify

Moved to [39](../agentic-platform/setup/39-wall-e-stage-0.md) §5 (S0-5.*).

## Phase 17 — Run the denial suite and the kill-switch drill

Moved to [37](../agentic-platform/setup/37-wall-e-sandbox-rehearsal.md) §6 and §8 on the twin (WR-6.*, WR-8.*) and [39](../agentic-platform/setup/39-wall-e-stage-0.md) §7 and §8 on production (S0-7.*, S0-8.*).

## 4. The denial test suite

Moved to [37](../agentic-platform/setup/37-wall-e-sandbox-rehearsal.md) §5 and §6 (WR-5.*, WR-6.*).

## 5. The kill-switch drill

Moved to [37](../agentic-platform/setup/37-wall-e-sandbox-rehearsal.md) §8 (WR-8.*), [39](../agentic-platform/setup/39-wall-e-stage-0.md) §8 (S0-8.*) and the drill calendar of [42](../agentic-platform/setup/42-gates-drills-and-evidence.md) §5 (GD-5.*).

### 6.1 The checklist

Moved to [39](../agentic-platform/setup/39-wall-e-stage-0.md) §11 and §12 (S0-11.*, S0-12.*).

## Related documents

- [../agentic-platform/setup/README.md](../agentic-platform/setup/README.md), the one entry point
- [../agentic-platform/13-setup-procedure-review.md](../agentic-platform/13-setup-procedure-review.md), the review that retired this page
- [PREREQUISITES.md](PREREQUISITES.md), retired the same day
- [setup/README.md](setup/README.md), the helper script and why it is not used
- [README.md](README.md), the Wall-E design set; [ARCHITECTURE.md](ARCHITECTURE.md); [05-autonomy-ladder.md](05-autonomy-ladder.md)
