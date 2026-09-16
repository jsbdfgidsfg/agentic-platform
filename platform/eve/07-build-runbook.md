# 7. Eve onboarding

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-15
- Status: **superseded on 2026-09-15**. Retired to a pointer page on 2026-09-16. Never executed. Nothing on this page is run again.
- Replaced by: [23](../agentic-platform/setup/23-eve-project-and-evidence-stores.md) to [29](../agentic-platform/setup/29-mo-eve-quality-pack.md), [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) and [41](../agentic-platform/setup/41-eve-s3-and-s4.md) of the human-executed setup procedures in [../agentic-platform/setup/](../agentic-platform/setup/README.md).
- Review that retired it: [../agentic-platform/13-setup-procedure-review.md](../agentic-platform/13-setup-procedure-review.md) (S038, S130, S134 and the Eve findings of its §4).

This runbook brought Eve's stages into existence in three sittings (Eve v0 at S0, the sink at
S2, onboarding at S3 entry; Phases 1 to 12, 2,182 lines), each dependent on Wall-E already
existing. The setup review of 2026-09-15 found blocking defects (`eve@` created inside an OU
that already enforced hardware-key 2SV, so it could never register its key, S038; a ladder
publisher that was empty on the default path, S130; a key-destruction guard that referred to
code no longer in the helper script, S134) and, above all, the wrong order: the owner's
instruction of 2026-09-15 is that **Eve monitors the human super admins from the day she runs,
before Wall-E exists**. Eve's first half (Eve-H) therefore now comes after the platform and
before Wall-E: her project and evidence stores (23), her Workspace identity and the six audit
streams (24), the detections over every human super admin (25), the reporting contract to a
human outside the administration line and the export to the witness organisation (26 and 27),
and the second human's independent proof on a seeded super-admin action, which produces
`EVE_H_LIVE_RECORD` (28). Everything that needs Wall-E (Eve v0's queries over `walle_audit`,
the mirror, the halt path) is joined in 36, and S3 and S4 in 41. Each new file lists under
"Salvaged" what it kept from here and under "Not copied" what the review showed wrong. Steps
that need Eve's code are marked BLOCKED there and indexed in the
[setup README](../agentic-platform/setup/README.md) §8.

## Where each phase went

Step ids are those of the new files (prefix index: [setup README §5.1](../agentic-platform/setup/README.md#51-step-prefix-index)).

| Old phase or section | New file | Steps |
|---|---|---|
| Prerequisites: decisions | [03](../agentic-platform/setup/03-decisions-and-people.md) §9 | DC-9.* |
| Prerequisites: access | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §2; [12](../agentic-platform/setup/12-privileged-access-catalogue.md) (every elevation on `EVE_PROJECT` approved by the second human) | PR-2.*, PA-* |
| Set these once per shell | [01](../agentic-platform/setup/01-prerequisites-and-conventions.md) §5 (`~/.platform-env`) | PR-5.* |
| Phase 1 Eve's GCP project | [23](../agentic-platform/setup/23-eve-project-and-evidence-stores.md) §1 and §2 (register row, `FM-VERIFIER` run for `EVE_PROJECT` and `EVE_TWIN_PROJECT`) | EP-1.*, EP-2.* |
| Phase 2 `eve-v0@` and the two dataset grants | [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §1 and §2 | WJ-1.*, WJ-2.* |
| Phase 3 the `eve` dataset, its tables and the daily mirror | [23](../agentic-platform/setup/23-eve-project-and-evidence-stores.md) §4 and §5 (datasets and tables from committed schemas); the mirror in [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §3 | EP-4.*, EP-5.*, WJ-3.* |
| Phase 4 the twelve scheduled queries | [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §4 | WJ-4.* |
| Phase 5 the absence alert on the metric series | [25](../agentic-platform/setup/25-eve-human-super-admin-detections.md) §6 (H-1, an absence alarm on the data) | EH-6.* |
| Phase 6 what Wall-E's repository must carry from its first commit | [31](../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §9 (the `contracts/eve-public-keys/` pin, empty until S4); the PEM handover in [41](../agentic-platform/setup/41-eve-s3-and-s4.md) §4 | WD-9.*, E3-4.* |
| Phase 7 Eve's organisation-level admin-log sink | [24](../agentic-platform/setup/24-eve-workspace-identity-and-audit-feeds.md) §1 (the six-stream sink) and §2 (the sandbox twin sink) | EW-1.*, EW-2.* |
| Phase 8 the Workspace half (`eve@`, the read-only role, the consent) | [24](../agentic-platform/setup/24-eve-workspace-identity-and-audit-feeds.md) §3 to §6; `eve@` is created there and only there (SD-32, S088) | EW-3.* to EW-6.* |
| Phase 9 identities, secrets, bucket | [24](../agentic-platform/setup/24-eve-workspace-identity-and-audit-feeds.md) §5 and §7 (client, secrets, `eve-verifier@`); [23](../agentic-platform/setup/23-eve-project-and-evidence-stores.md) §3 and §7 (keys, the locked bucket) | EW-5.*, EW-7.*, EP-3.*, EP-7.* |
| Phase 9 the grants and the cross-project paragraph | [25](../agentic-platform/setup/25-eve-human-super-admin-detections.md) §1 (the grants Eve's identities never had); the Wall-E half in [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §5 and §6 | EH-1.*, WJ-5.*, WJ-6.* |
| Phase 10 `eve/config`, `eve-reconciler`, `eve-console`, the fixtures | [25](../agentic-platform/setup/25-eve-human-super-admin-detections.md) §2 to §5, §7 and §8 (config, image, jobs, paused schedules, console behind IAP, fingerprint) | EH-2.* to EH-5.*, EH-7.*, EH-8.* |
| Phase 10b the observe-and-report layer, steps 1 to 4 | [26](../agentic-platform/setup/26-eve-reporting-and-witness-export.md) §1 to §4 and §7 (reporting tables, routing contract, route 1, `eve-export@`, the first run); the witness side in [27](../agentic-platform/setup/27-witness-grants-and-alarms.md) | ER-1.* to ER-4.*, ER-7.*, WG-* |
| Phase 10b step 5 the `eve_quality` readers | [26](../agentic-platform/setup/26-eve-reporting-and-witness-export.md) §5 (the views); [29](../agentic-platform/setup/29-mo-eve-quality-pack.md) §1 and §2 (the two readers) | ER-5.*, MQ-1.*, MQ-2.* |
| Phase 10b the drill paragraph | [28](../agentic-platform/setup/28-eve-independent-proof-and-sandbox-drills.md) in full: the blind proof, the anti-silencing drill, the witness part, the sandbox part, `EVE_H_LIVE_RECORD` | EV-0.* to EV-9.* |
| Phase 11 the key, the PEM, `eve-gate`, Wall-E's edits | [41](../agentic-platform/setup/41-eve-s3-and-s4.md) §4 to §7 (`eve-gate` is BLOCKED on B-19) | E3-4.* to E3-7.* |
| Phase 12 the teardown guard and the denial suite | [41](../agentic-platform/setup/41-eve-s3-and-s4.md) §8 and §9 | E3-8.*, E3-9.* |
| The manual console steps, in one list | the Who column of the [setup README](../agentic-platform/setup/README.md) §3.2 and its role table §6; each file's "People needed" | — |
| What to do when a step half-fails | the resume rule of the [setup README](../agentic-platform/setup/README.md) §4; each file's "If something goes wrong in the middle" | — |
| Verified facts used in this runbook | each file's "Sources checked" and "Unverified" sections | — |

## Retired headings

The headings below are kept only because other pages link to them. Each carries one pointer and
nothing else.

### Phase 1 — Eve's GCP project

Moved to [23](../agentic-platform/setup/23-eve-project-and-evidence-stores.md) §1 and §2 (EP-1.*, EP-2.*).

### Phase 2 — `eve-v0@` and the two dataset grants

Moved to [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §1 and §2 (WJ-1.*, WJ-2.*).

### Phase 4 — The twelve scheduled queries, pinned and off the hour

Moved to [36](../agentic-platform/setup/36-wall-e-joins-to-eve-and-mo.md) §4 (WJ-4.*).

### Phase 7 — Eve's organisation-level admin-log sink

Moved to [24](../agentic-platform/setup/24-eve-workspace-identity-and-audit-feeds.md) §1 and §2 (EW-1.*, EW-2.*).

### Phase 8 — The Workspace half

Moved to [24](../agentic-platform/setup/24-eve-workspace-identity-and-audit-feeds.md) §3 to §6 (EW-3.* to EW-6.*).

### Phase 10 — `eve/config`, `eve-reconciler`, `eve-console`, and the fixtures

Moved to [25](../agentic-platform/setup/25-eve-human-super-admin-detections.md) §2 to §8 (EH-2.* to EH-8.*).

### Phase 10b — The observe-and-report layer, before the super-admin grant

Moved to [26](../agentic-platform/setup/26-eve-reporting-and-witness-export.md) (ER-*), [27](../agentic-platform/setup/27-witness-grants-and-alarms.md) (WG-*), [28](../agentic-platform/setup/28-eve-independent-proof-and-sandbox-drills.md) (EV-*) and, for step 5, [29](../agentic-platform/setup/29-mo-eve-quality-pack.md) (MQ-1.*, MQ-2.*).

### Phase 11 — The key, the PEM, `eve-gate`, and Wall-E's edits

Moved to [41](../agentic-platform/setup/41-eve-s3-and-s4.md) §4 to §7 (E3-4.* to E3-7.*).

### Phase 12 — The teardown guard and the denial suite

Moved to [41](../agentic-platform/setup/41-eve-s3-and-s4.md) §8 and §9 (E3-8.*, E3-9.*).

## Related

- [../agentic-platform/setup/README.md](../agentic-platform/setup/README.md), the one entry point
- [../agentic-platform/13-setup-procedure-review.md](../agentic-platform/13-setup-procedure-review.md), the review that retired this page
- [README.md](README.md), the Eve design set; [01-hld.md](01-hld.md); [02-identity-and-auth.md](02-identity-and-auth.md); [05-stages.md](05-stages.md); [09-open-decisions.md](09-open-decisions.md)
- [../project-topology.md](../project-topology.md), the authority for placement and cross-project grants
