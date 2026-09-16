# 2026-09-13 — Wall-E holds Super Admin

- **Status:** accepted — decided by the platform owner on 2026-09-13 (platform register row
  **P33**, [../platform/agentic-platform/12-open-decisions.md](../platform/agentic-platform/12-open-decisions.md)).
  The TISAX deviation this record also is (P136) is **not yet signed**: the security reviewer's
  and the ISMS's signatures are pending, and the grant itself stays blocked until every
  precondition below is green. Nothing is built.
- **Deciders:** the platform owner (decides). Signs the deviation: the security
  reviewer (decision 37 role; a person who is not the platform owner). Enters it in the risk
  register: the ISMS.
- **Date:** 2026-09-13
- **Register row:** P33. Depends on it: P29 (the two lists), P125 (Wall-E's Art. 6 path), P136
  (this file as the deviation record), P140 (risk register row R-01).
- **Gate it blocks:** the super-admin grant on `walle@` (the Tier P / P-SA gate of the platform
  HLD §0.4).
- Append-only. Never edit this file's decision; supersede it with a new dated record.

This file has the sections [../platform/agentic-platform/11-tisax.md](../platform/agentic-platform/11-tisax.md)
§6.2 requires, in that order (Decision, Deviation statement, Residual risk, Compensating
controls, Precondition rule, Review, Signatures), preceded by the decision log's Context and
Options and followed by Consequences and Supersedes.

## Context

The objective stated by the owner on 2026-09-13 says Wall-E, the doer, has "a dedicated user
account, with a google license and super admin roles" and may perform any super-admin-level
action of Google Workspace on a human's prompt. The Wall-E set as written up to 2026-09-12 was
designed for the opposite: a narrow custom admin role, customer-scoped read plus OU-scoped write,
"Never Super Admin" on nineteen pages, and a setup script whose hardening check fails when the
robot is a super admin.

Two Google facts fix the shape of the decision and are not negotiable:

1. A service account can be assigned any Workspace admin role **except** Super Admin, so the
   account is a user account and Wall-E decision 26 (keyless service account holding the admin
   role) closes for Wall-E by fact. Source:
   https://knowledge.workspace.google.com/admin/users/assign-specific-admin-roles (read
   2026-09-13 by the review's super-admin lens).
2. Super Admin cannot be limited to an organisational unit or to a privilege subset. Source:
   https://knowledge.workspace.google.com/admin/users/administrator-privilege-definitions (same
   date).

A super admin can also grant Organization Administrator on the tenant's GCP organisation
(https://docs.cloud.google.com/resource-manager/docs/super-admin-best-practices, read 2026-09-13),
so the credential reaches every project of the platform, `EVE_PROJECT` included.

Constraints in play and unchanged: no domain-wide delegation; the language model holds no
credential and cannot approve; the action service is the only holder of a Workspace credential;
humans raise autonomy and machines lower it; no model on Eve's approval path; Mo reaches
production only through a pull request a human merges; safety interlocks are plain authenticated
REST.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| Keep the narrow custom role (the design of 2026-09-12) | Two enforcement points (the action service and Google refusing out-of-role or out-of-OU calls); least privilege shown by an enumerated role | Does not meet the objective: "any super-admin-level action" is impossible under a custom role; overruled by the owner |
| Super Admin on a keyless service account | No password, no hardware key, no refresh token to steal | Impossible: Google refuses Super Admin on a service account |
| **Super Admin on a dedicated, licensed user account, contained by the platform (chosen)** | Meets the objective; keeps the catalogue as the declared intended purpose; every control that read "not in the role" moves into code the CI owns outside the agent repository | One enforcement point left in the action service; a leaked token or an interactive login is a tenant compromise; least privilege becomes a signed deviation; detection becomes the primary control |

## Decision

**Wall-E holds Super Admin**, on the dedicated licensed user account `walle@`, decided by the
platform owner on 2026-09-13. The decision:

- **supersedes Wall-E decision 26 for Wall-E** (closed by fact; decision 26 survives only as
  Eve's E-16, Eve's own credential chapter);
- **re-ratifies Wall-E decision 4** (the must-never list) as **the two lists** of platform HLD
  §13.1 item 2 — the hard-denied list refused in every lane, and the list reachable only through
  band B at tier `SUPER` under a two-person rule — to be signed as P29;
- enters the residual below in the **accepted-risks table** with the owner's signature, as a
  **TISAX deviation** from ISA 4.2.1 signed by the security reviewer (P136), and as **row R-01**
  of the platform risk register (P140);
- is designed around, not re-argued: no page of the set re-opens whether the account holds the
  role, only how it is contained.

Evidence pointer: the two lists as committed in the action-service repository, with the CI
check's hash — *tbd* (not yet written; recorded here on the day they are).

## Deviation statement

From ISA **4.2.1 least privilege**: a machine account holds Super Admin, which cannot be scoped
to an organisational unit or a privilege subset; the Workspace-side refusal that bounded the old
custom role is gone. What carries the control instead: the typed catalogue (band A), the
Discovery-validated, permanently-L3 generic lane (band B), the console handoff (band C); the two
lists in code with CI ownership outside the agent repository; the OAuth scope split as the only
Google-enforced ceiling; the autonomy ladder; Eve; the quarterly roster review; K6. ISA 4.1.2
(privileged authentication) and 5.2.4 (privileged-activity logging) are met, not deviated
([../platform/agentic-platform/11-tisax.md](../platform/agentic-platform/11-tisax.md) §6.1).

The safety the platform loses, as the platform HLD states it without softening
([../platform/agentic-platform/01-hld.md](../platform/agentic-platform/01-hld.md) "What this
reverses and what it costs"):

| Lost | What it was | What it is now |
|---|---|---|
| The Workspace-side gate | The action service **and** Google refusing an operation outside the pilot OU or the role | One enforcement point: the action service; the consented scope set is the only Google-enforced ceiling left |
| The blast radius | A leaked token bounded by the role's privileges at the current ladder stage | A tenant compromise, and a path into the GCP organisation including `EVE_PROJECT`, `MO_PROJECT` and the core projects |
| Eve's structural independence | Eve's project, credential, key and halt authority out of Wall-E's reach by construction | Inside the organisation Eve's independence is detective, not structural; what leaves the organisation (evidence, incident record, pager, in the witness) is structural |
| The catalogue as a ceiling | "Nothing executes that is not registered" | The catalogue stays the declared intended purpose and the only band that can be autonomous; bands B and C carry the breadth |
| Least privilege as a property | Shown by an enumerated role | This signed deviation; an assessor may still refuse maturity 3 on it |
| The narrow-task argument under the EU AI Act | Rested on the role and the catalogue | Rests on the declared intended purpose, the hard-denied list enforced in code, and audit logs (P125) |
| Detection as a check on enforcement | Alerts confirmed what the role refused | Detection is the primary control for the super-admin tier |

## Residual risk

A leaked token or an interactive login on `walle@` is a **tenant compromise** with a path into
the GCP organisation, including `EVE_PROJECT`. The perimeter is **custody, scope split, a split
control plane and detection latency**, with the witness organisation holding the evidence, the
incident record and the pager outside the tenant super admins' reach. Severity 1; the response
includes Google support escalation. The Wall-E threat row becomes "Robot credential leak —
tenant compromise; bounded by custody, scope split and detection latency; severity 1; response
includes Google support escalation". A super admin who reaches Organization Administrator can
redeploy `eve-gate`; the witness sees the deletion of `EVE_PROJECT` and the absence of evidence,
not the forgery of an approval — the end state that closes that gap is P15.

Risk register: row R-01 (P140), owner the security reviewer; acceptance signature pending.

## Compensating controls

The thirteen compensations of platform HLD §13.1 as a checklist, each with its enforcement grade
and its status **on the day of signing**. On 2026-09-13 nothing is built, so every row is
**not green**; the gate checklist of
[../platform/agentic-platform/11-tisax.md](../platform/agentic-platform/11-tisax.md) §6.3 is
where each row's "green means" and verification live.

| # | Compensation (HLD §13.1) | Grade | Status on 2026-09-13 |
|---|---|---|---|
| 1 | Three bands: A catalogued autonomous work on `walle-actions`; B the generic Discovery-validated lane `/v1/execute-generic`, permanently L3; C the console handoff `/v1/handoff`; no automation of the Admin console under the robot's session | enforcement (code) | not built |
| 2 | Two lists (hard-denied in every lane; band-B `SUPER` only, two-person), decision 4 re-ratified (P29) | enforcement (code) | not signed |
| 3 | Two OAuth clients read by two services (`walle-actions` narrow, `walle-actions-super` broad); `cloud-platform` in neither, checked in CI | enforcement (Google, by scope) | not built |
| 4 | Band-B requester rule: tier `SUPER` requester a live-checked human super admin, approver a different human super admin, approval bound to the request hash | enforcement (code) | not built |
| 5 | Detection as the primary control: Eve's minute-latency reconciliation over every stream, daily roster check from Eve's credential, evidence heartbeat, SIEM-hosted severity-1 set | detection, minute latency, with absence alarms | not built |
| 6 | Account hygiene: hardware-key-only 2SV on the robot OU; super-admin self-recovery Off at the top OU with a child-OU drift check; no recovery channels; the robot never the only or the recovery super admin; at least two human super admins; Workspace multi-party approval on (P66) | enforcement (Google) plus detection; the Admin console CAA level detection-plus-friction (`Assumption:`, P7) | not built |
| 7 | Kill switches K0–K5, **K6** (a human super admin removes Super Admin from the robot), **K7** the fleet kill; K5/K6 on a two-person rota paged from the witness | enforcement (human) | not drilled |
| 8 | The perimeter: P3 spike 1 passed, ingress policy applied (P90); Access Approval on `WALLE_PROJECT`; PAM on the deploy grant with a second reviewer | enforcement (IAM now; ingress policy after P3) | spike not run |
| 9 | A permanent ceiling: no super-admin-class operation is ever autonomous, stated in the same sentence as "`WRITE_HIGH` never reaches L5" | enforcement (code) | not built |
| 10 | The controls that replace the lost role scoping (OU allow-list, N1/N2, `SAFE_USER_FIELDS`, the credential-leak bound) as hard invariants in the policy chain; the denial suite's inverted exit checklist | enforcement (code) | not built |
| 11 | A second human outside the Wall-E administration line, owner of `eve-owners@` and witness administrator | organisational | not named |
| 12 | This signed record | organisational | decided; deviation not signed |
| 13 | EU AI Act position: the catalogue is the declared intended purpose; Super Admin is a credential fact (P28, P125) | documentation | not signed with legal |
| + | Penetration test done; crisis tabletop run; hardware-key custody witnessed (HLD §0.4; 11 §6.3) | — | not done |

## Precondition rule

"The role is granted only when every item marked *precondition* is green; the grant day is the
day 'the four owner groups are one person' expires" (platform HLD §0.4). The grant runbook step
refuses to proceed while any row of
[../platform/agentic-platform/11-tisax.md](../platform/agentic-platform/11-tisax.md) §6.3 is not
green. After the grant: any row red is a severity-2 finding with a 30-day window; two rows red at
once, or row 5, 6 or 11 red at all, is severity 1 and the on-duty human super admin pulls **K6**
until the row is green again.

## Consequences

- Wall-E's set is rewritten around a super-admin user account (platform HLD §18 items 1–10):
  every "never Super Admin", "OU-scoped" and "Google refuses at its end" line is rewritten or
  dated; `walle_setup.py`'s `isAdmin` hardening check inverts.
- The Tier P / P-SA gate cannot open until the witness organisation (P14), a SIEM with 24x7
  acknowledgement (P10, P92), two human super admins with the robot never the recovery one, the
  second human outside the Wall-E line, the perimeter decision (P3 spike 1, P90), the penetration
  test, DPIA start and works-council information exist ([../backlog.md](../backlog.md) items
  18–22).
- Eve's observe-and-report layer (all-stream sinks, Reports API polling, tenant-integrity rules,
  witness mirror and paging, `eve.incidents`) is live and drilled **before** the grant, not at
  Stage 3.
- A pre-production credential holder is a separate sandbox Workspace tenant, never an OU of the
  production tenant (Wall-E decision 29 re-cut; P40).
- The register's CI refuses a second `super_admin` row while one is not `retired`: the target
  count of P-SA agents is one.
- Rules out: any autonomous super-admin-class operation, ever; a machine holder of a Workspace
  privilege over `walle@` for now (P16 revisits); browser or computer-use automation of the
  Admin console under the robot's session.
- Revisit: quarterly with the roster review; at every Wall-E stage transition; whenever a
  compensation's grade changes; on any severity-1 incident involving the credential; when P15
  (Eve's control path relocated to the witness) is built.

## Supersedes

| Record | Effect |
|---|---|
| Wall-E decision 26 ([../platform/wall-e/09-open-decisions.md](../platform/wall-e/09-open-decisions.md)) | **Superseded for Wall-E** — closed by the Google fact that a service account cannot hold Super Admin; survives only as Eve's E-16 ([../platform/eve/09-open-decisions.md](../platform/eve/09-open-decisions.md)) |
| Wall-E decision 4 (the must-never list) | **Re-ratified** as the two lists of platform HLD §13.1 item 2; signature under P29 |
| Wall-E decisions 3, 5, 18, 27, 28, 29 | Re-cut, not superseded, by the platform HLD: 3 (scopes split across two clients), 5 (the OU allow-list survives only in code), 18 (control-plane split lands now), 27 (breadth becomes "which lane"), 28 (requester rule for band B), 29 (a sandbox tenant before Stage 1) — each carries its own dated line in the Wall-E register |
| The "Never Super Admin" design intent across the Wall-E set | Reversed 2026-09-13; see the platform HLD "What this reverses and what it costs" |

## Review

Quarterly with the super-admin roster review; re-signed at every stage transition of Wall-E and
whenever a compensation's grade changes; expires with the TISAX assessment result (three years)
or earlier on any severity-1 incident involving the credential. Review log: *tbd* (the evidence
bucket path is fixed when the evidence register exists, platform HLD §14.3).

## Signatures

| Role | Duty | Signed |
|---|---|---|
| Platform owner | decides | decided 2026-09-13 |
| Security reviewer (decision 37; not the platform owner) | signs the deviation and accepts R-01 | *tbd* — the role is not yet filled by a second person |
| ISMS | enters the deviation in the site's risk register | *tbd* — register id *tbd* |
| Legal (for item 13 only, P28 / P125) | signs the intended-purpose statement | *tbd* |
