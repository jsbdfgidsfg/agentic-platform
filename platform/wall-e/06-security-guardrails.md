# 6. Security & guardrails

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- Placement updated on 2026-09-13 to the four-project topology; no control was added,
  softened or dropped. [../project-topology.md](../project-topology.md) is the authority
  for where each sink, key and secret lives.
- **Objective restated 2026-09-13; see the platform HLD**
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) "What this reverses and what
  it costs", §13.1, §7.3, §14; §18 item 4). Wall-E holds Super Admin (register row P33), so the
  Workspace role no longer refuses anything. Changes on this page: N1 and N2 are enforced as
  hard invariants in the policy chain, not by the role; the never-list becomes the **two
  lists** (hard-denied in every lane; reachable only through band B at tier `SUPER`), to be
  signed as decision 4 re-ratified (P29); the credential-leak threat row becomes
  "Robot credential leak — tenant compromise"; Monitoring gains the super-admin detection set;
  Compliance names the EU AI Act and TISAX. Every control that existed before is kept. Where
  one relied on the role, the compensating control that replaces it is named in the row.

## The honest risk statement

You are giving an LLM a path to admin operations on your organisation's Workspace tenant, and then
removing the human from that path one step at a time. That is a legitimate thing to build
and it is the highest-blast-radius system in your estate. Everything below exists so that
the answer to "what happens when the model is wrong, or manipulated, or the trigger fires
at the wrong moment" is *an audit row and a refused approval*, not an incident.

**Added 2026-09-13.** Since the objective of 2026-09-13 the path leads to a **super-admin**
account. The action service is now the only gate; the OAuth scope set is the only ceiling
Google enforces; and detection is the primary control, not a check on a role that already
refused. The platform HLD says this without softening in "What this reverses and what it
costs", and the rest of this page is written against it.

Three properties carry most of the weight:

1. **The model never holds the credential.** It lives in the action service, behind IAM.
   No tool returns it and no prompt reveals it.
2. **The model cannot self-authorise.** Approvals are minted by the service, released by a
   human or by Eve from a separate identity with a separate key — homed in `EVE_PROJECT`,
   where no Wall-E principal exists — bound to canonical parameters and pre-state,
   single-use.
3. **The model cannot change its own leash.** The ladder config, the overrides and the
   halt flags are unreachable from any catalogue operation, and `walle-agent@` has no IAM
   on them.

## The blast-radius ceiling: what must never happen

You have not yet ratified this list, so treat it as the proposal you sign off in
[decision 4](09-open-decisions.md). It is ordered worst first, and every row maps to a
mechanism in [03-lld.md](03-lld.md).

**Qualified 2026-09-13.** Decision 4 is re-opened as **P29**. What gets signed is no longer
these nine rows alone but the two lists in "The two lists" below (platform HLD §13.1 item 2).
The nine rows stay as the statement of what must not happen. What changed is the mechanism in
the last two columns of N1, N2 and N7.

| # | Must never happen | Why it is the ceiling | What prevents it | Enforced by |
|---|---|---|---|---|
| **N1** | **Wall-E changes tenant security posture** — 2SV, SSO, password policy, API controls, DWD, admin roles | A robot that can change the rules constraining it is not constrained. Recovery window is unbounded. | Not in the catalogue, and **not in the custom role**. *Reversed 2026-09-13: no custom role exists; the account is a super admin.* Now: a **hard invariant in the policy chain of every lane** (`posture_change_denied` / `escalation_denied`, breaker trip, severity 1) for everything on the hard-denied list. Other posture work is either band B at tier `SUPER` (two human super admins, never autonomous) or band C, where a human does it in the console. Workspace multi-party approval makes role assignment, DWD, 2SV, session control, login challenges, account recovery, SSO and Context-Aware Access Google-enforced two-person acts over the robot's credential (P66) | Policy chain hard invariants + catalogue registry + denial suite; Workspace multi-party approval for the settings it covers; SA-02/SA-03 detection (was: Workspace role + catalogue registry) |
| **N2** | **Permanent data loss** — a deleted user, group or mailbox | Restore is possible for 20 days only, and needs a spare licence. Rollback does not exist. | Not in the catalogue, not in the role. *Reversed 2026-09-13: the role no longer withholds deletion.* Now: deleting any admin or the tenant account is a **hard invariant** in every lane (a reason from the closed denial vocabulary of platform HLD §13.1 item 2, breaker trip, severity 1). Deleting a non-admin user or a group is reachable only through band B at tier `SUPER`: two-person, change ticket, `hold_minutes`, treated as irreversible, never in a playbook | Policy chain hard invariants + catalogue registry + the `SUPER` ceiling of [05](05-autonomy-ladder.md) §4 (was: same as N1) |
| **N3** | **Privilege escalation through a group** — adding anyone to a group that grants admin rights, GCP IAM, or control of Wall-E, Eve or Mo | The quiet path to N1 | Security-class groups blocked; unclassified groups treated as security | `_check_target` on `group_key`, group classification, fail closed |
| **N4** | **Mass action** — the same operation looped across an OU | The realistic shape of both an injection and a bug | Explicit enumerated targets only; per-run object cap; daily budget; novelty cap | Catalogue parameter models, durable Firestore counters |
| **N5** | **Acting on instructions found in content** — mail, Chat, documents, audit rows, **display names, group names, error text** | The one attack that will actually be attempted | The **taint bit**: any attacker-writable field reaching the model forces the inbox ceiling for that run, whatever the trigger. Plus the playbook `uses` allowlist, the pinned selection query, a closed error enum that never echoes upstream text, and canonicalisation of every attacker-writable string | Taint evaluation in the policy chain, ceilings in code, playbook validator ([03](03-lld.md)) |
| **N6** | **Outbound communication chosen by the model, unattended** | An admin account is trusted by every employee; a phishing mail from it is not recoverable | Templated notification (`notify.operators`, family F2) and free text (`gmail.send`, `chat.message.send`, family **F2b**) are different families with different ceilings. An earlier draft put them in one family, which would have made free-text mail autonomous at L4 on a schedule — the exact thing this row forbids | Family split in the catalogue; recipient domain check as an explicit policy step |
| **N7** | **Touching a protected principal** — super admins, delegated admins, itself, its own OU | Self-modification and lateral movement | Protected-principal check, fails closed. *Qualified 2026-09-13:* the robot is now a super admin itself, so the admin cache (`isAdmin`) includes it. It is also on the committed floor list, so it stays protected whatever the cache returns. Other admins' security settings and backup codes, `users.makeAdmin`, and any Super Admin assignment are on the hard-denied list in every lane. A second activity rule pages on any admin event whose actor is the robot and whose target is another admin | `_check_target`, background-refreshed admin cache, the committed floor list; SA-02 detection |
| **N8** | **An action nobody can see** | Undetected drift is worse than a visible failure | Write-ahead audit; writes refused when the audit sink is down; reconciliation against Workspace audit logs. That reconciliation needs an **organisation-level aggregated log sink into BigQuery** — an earlier draft routed those logs only to Pub/Sub, so the completeness metric had nothing to query. It also needs org-level permission to create the sink. Two sinks land in two projects: Wall-E's copy is `walle-audit-bq` → `walle_workspace_logs` in `WALLE_PROJECT`; Eve's own organisation-level sink `eve-workspace-audit` → `eve_workspace_logs` in `EVE_PROJECT` (already designed), so Eve's evidence is outside Wall-E's teardown reach | Audit module, aggregated sinks, Eve's completeness metric |
| **N9** | **Acting as a person** | Impossible by construction, and must stay impossible | No DWD, no user write tokens ever accepted by the action service | Architecture |

If you disagree with any row, say so before build — every one of them has cost the design
something, and N6 in particular cost the convenience of a chatty autonomous agent.

## Threat model

Rows marked **new** exist only because there is an autonomous path; a design with a human in every write path would not need them.

| Threat | Control | Residual risk |
|---|---|---|
| Prompt injection via mail, Chat or a document | T3 write ceiling of L2; playbook `uses` allowlist; explicit targets; untrusted-content tagging; approvals the model cannot mint | An injection can cause a **proposal** to appear in the operator queue. Accepted, and visible. |
| Model invents a destructive call | Catalogue allowlist; typed parameters; protected principals; level | Low |
| Credential exfiltration through the agent | Credential absent from the agent's process and context; IAM on the secret | Low |
| Compromised agent service account | It can only call the action service, which still enforces principal, level and approval | Attacker gains what the current level allows unattended — which is why levels rise slowly |
| Insider misuse by an operator | Group-gated, every action attributed, weekly `WRITE_HIGH` review | Operators can do operator things. By design. |
| **Robot credential leak — tenant compromise** (rewritten 2026-09-13; was "Robot credential leak — custom role, not Super Admin; OU-scoped role; revocation path; login alerting — bounded by the role's privileges at the current stage", which no longer holds) | Custody: two hardware keys with named custodians and a witnessed custody record; hardware-key-only 2SV on the robot OU; super-admin self-recovery Off at the top OU, drift-checked; no recovery channels; no interactive login ever (severity 1). Scope split: the narrow client for `walle-actions`, the broad client for `walle-actions-super`, each secret with one reader; `cloud-platform` in neither, checked in CI. Detection: a token from any client other than the two committed ones (SA-05); a robot event with no audit row (SA-07); Eve's minute-latency reconciliation and daily roster check; the absence alarm in the witness. Revocation path kept: K4/K5, and **K6** — a human super admin removes Super Admin from the robot, which is the switch that survives a token already minted (platform HLD §13.1 items 5–7) | **The whole tenant, and through the console's power to grant Organization Administrator, a path into the GCP organisation, including `EVE_PROJECT` and `MO_PROJECT`.** Bounded by custody, scope split and detection latency. Severity 1; the response includes Google support escalation (runbook RB-01 in [../agentic-platform/07-monitoring-detection-incident-response.md](../agentic-platform/07-monitoring-detection-incident-response.md) §11). Accepted as a signed deviation, risk register row R-01 (P33) |
| **new 2026-09-13** One human makes the robot do super-admin-class work alone | Band B at tier `SUPER`: a live, fail-closed check that the requester is a human super admin; the approver a **different** human super admin; both on the audit row; the approval bound to the canonical request hash on the IAP surface; a change-ticket reference and `hold_minutes` for the veto surface; permanently L3, chat only (platform HLD §13.1 item 4, decision 28) | Two colluding human super admins, who could do the same work without the robot. Eve's prompt-to-action divergence rule reports on the human prompt as well as on the robot's action |
| **new** Runaway loop or trigger storm | Dispatcher budget check before any model call; per-run and daily caps; dedup by event id; a T2 run may not emit a T2 event; breaker on consecutive failures | Bounded to one run's cap |
| **new** Poisoned upstream signal — a bad HR feed or forged event | Events only from Workspace audit logs signed by Google's own pipeline; suspend at L4 only when the trigger is a system of record; caps still apply | A valid-but-wrong upstream record produces up to one run's worth of changes, all reversible |
| **new** Stale state — a human admin acts between plan and execution | Pre-state hash bound into the approval; **every item re-read immediately before execution**; mismatch skips the item | Skipped item, reported. Not an incident. |
| **new** Eve unavailable | L4 items **wait**; over four hours sets `no_autonomous`; L5 without post-hoc verification within SLA demotes to L4 | Work stalls. Correct outcome. |
| **new** Eve compromised or rubber-stamping | Eve can only lower and approve, never raise; sampled human review of Eve verdicts; an overturned Eve approval demotes both the family and Eve's authority; Eve's key is separate, lives in `EVE_PROJECT` and rotates independently — a rotation reaches Wall-E as a PEM update in its repository, never as a grant | Eve could approve within the current level's blast radius until the next sample. Mitigated by hold windows and vetoes. |
| **new** Mo proposes a harmful change | Mo has no write path; its output is a pull request needing a human approver, CI validation and a decision record | A rubber-stamped pull request. Mitigated by the two-person rule on L4/L5. |
| **new** Ladder config tampering | Config in git with code ownership; **the ceiling module, policy chain and validator are owned separately and the check runs outside the repository**, so one pull request cannot move the ladder and the gate together; `config_version` and `ceilings_sha` on every row | Detected within one verification cycle |
| **new** The action service itself is compromised or buggy | Eve's asymmetric key, in `EVE_PROJECT` where no Wall-E principal can be granted `useToSign`, means the service cannot mint an Eve approval; plans are create-only so a signed plan cannot be rewritten; the Workspace audit log is written by Google, not by us | **Real and only partly mitigated.** Every control still runs in one process. See [10](10-adversarial-review.md) and [decision 18](09-open-decisions.md). *Qualified 2026-09-13:* that process now holds a super-admin credential, so decision 18 lands now, not before Stage 4. There are two services with two OAuth clients (`walle-actions`, `walle-actions-super`), each the only reader of its own secret (platform HLD §13.1 item 3) |
| **new** Operators cannot reach the control plane | `run.invoker` bound to the operator group, plus an out-of-band approval surface | If neither exists, every kill switch is theoretical. This was true of the first draft |
| **new** Quota exhaustion locking out human admins | Per-operation ceilings well below Google's limits; backoff; quota errors as a distinct outcome class | Wall-E throttles itself before the tenant does |
| **new** Credential revoked mid-run | `invalid_grant` treated as a paging incident, not a retry; run aborts at the current item | Partial run, reported |
| **new** Wrong-homonym targeting | Plans carry pre-state including OU and manager; proposals show it; explicit targets only | Human or Eve sees the wrong context before approving |
| **new** Licence reclaim causing data loss | Reclaim restricted to suspended accounts first; the retention consequence of removing a licence on your tenant's plan must be confirmed with Google before active accounts are in scope | Unquantified until that answer exists — see [decision 7](09-open-decisions.md) |
| **new** Timezone or business-hours error | Business hours in config with an explicit timezone; last write at 16:00; holds do not span the boundary; weekend suspensions blocked | A run waits until morning |

## Never in the catalogue

Not a level, not a stage, not a config flag. Adding any of these is a design change
needing a decision record and a security sign-off, and the default answer is no.

**Qualified 2026-09-13.** This table still says what is never in the **catalogue** (band A);
that is unchanged. What changed is that "never in the catalogue" no longer means "never
executed by the robot". Under the objective, a human can reach part of this table through
band B at tier `SUPER`, and part through band C. The last column, added 2026-09-13, points each
category at "The two lists" below. Where a category is not named on either list, it stays out
of the catalogue. Whether a human can reach it through band B then depends on the committed
method-to-tier table of [03](03-lld.md); where no API writes it, it is band C by fact.

| Category | Operations | Lane since 2026-09-13 (platform HLD §13.1 item 2) |
|---|---|---|
| Privilege and posture | Admin role create, assign or revoke · 2SV, password, session, login-challenge or recovery settings · API controls and OAuth app trust · domain-wide delegation · domain and DNS settings · SSO/SAML · DLP · context-aware access · data regions | **Hard-denied:** `users.makeAdmin`, any Super Admin assignment or assignment of a role carrying admin-role management, DWD, the super-admin self-recovery setting, other admins' security settings and backup codes, "Share data with Google Cloud services", the SecOps export setting, the activity rules that alert on the robot. **Band B `SUPER`:** admin-role create or assign below Super Admin, domain add. **Band C** (no API writes them): 2SV enforcement and methods, sign-in challenges, password policy, session control, API controls and app trust, data regions. DLP rules and detectors can be written through the Cloud Identity Policy API (v1), so they fall to the method table |
| Irreversible data | User delete or undelete · group delete · OU delete · mailbox purge · Vault matters, holds, exports and retention · tenant data export | **Hard-denied:** `users.delete` of any admin, deletion of the tenant account. **Band B `SUPER`:** user delete of non-admins, group delete. The rest: not on either list |
| Credentials | Password set or reset · app passwords · security keys · token revocation for other users | **Hard-denied:** other admins' security settings and backup codes. The rest: not on either list |
| Self-modification | Anything targeting the robot account, its OU, the `walle-*` control groups, the ladder config, the catalogue, the overrides or the halt flags | **Hard-denied**, widened: also `eve@`, Eve's role, `eve-owners@`, `ge-admins@`, `platform-approvers@`, the `mo-*` groups, the two OAuth clients and the organisation sinks |
| Structure | OU create, delete, rename or move. Moving a *user* into an allowlisted OU is F4; changing the tree is not. | **Band B `SUPER`:** OU create, rename, move. OU delete: not on either list |
| Money | Subscriptions, billing, edition changes, licence pool purchases | **Band B `SUPER`:** licence purchases where an API exists. **Band C:** billing |
| Outside Workspace | IAM and settings of any of the four projects (`GEMINI_PROJECT`, `WALLE_PROJECT`, `EVE_PROJECT`, `MO_PROJECT`), the folder `FOLDER_ID`, Gemini Enterprise configuration | Unchanged: no lane reaches it. `cloud-platform` is consented on neither client (CI-checked). `walle@` holding any organisation-level IAM role is a drift row, and `SetIamPolicy` by `walle@` is severity 1 |
| Other people's Drive | File mutations, ownership changes, sharing changes. Unreachable without DWD — and do not add DWD to reach them. | Unchanged. DWD is hard-denied |

### The two lists (added 2026-09-13)

Decision 4 re-ratified as **P29**, owner-signed before the super-admin grant. The authority is
platform HLD §13.1 item 2 and [01-hld.md](01-hld.md) §"The controls that replace role
scoping". They are repeated here only so this page can be read on its own.

| List | Contents | Mechanism |
|---|---|---|
| **1. Hard-denied in every lane** — band A, band B, and the band-C handoff, which refuses these rather than returning console steps | Anything targeting `walle@`, its OU, `eve@`, Eve's role, the control groups (`walle-operators@`, `walle-protected@`, `eve-owners@`, `ge-admins@`, `platform-approvers@`, the `mo-*` groups), the two OAuth clients, the activity rules that alert on the robot, "Share data with Google Cloud services", the SecOps export setting, the organisation sinks; `users.makeAdmin` and any `roleAssignments.insert` of Super Admin or of a role carrying admin-role management; `users.delete` of any admin and deletion of the tenant account; other admins' security settings and backup codes; the super-admin self-recovery setting; DWD; turning Workspace multi-party approval off (P66). The robot is on the committed floor list and is a protected principal under its own N7 rule | Denial reasons `self_modification_denied`, `escalation_denied`, `posture_change_denied`, `irreversible_denied`, `money_denied`; breaker trip; severity-1 page. Hard invariants in the policy chain of both services, tested by the denial suite. CI ownership sits outside the agent repository |
| **2. Reachable only through band B at tier `SUPER`** | Everything else on the old never-list: OU create, rename or move; user delete of non-admins; group delete; admin-role create or assign below Super Admin; domain add; data transfer; licence purchases where an API exists | `walle-actions-super` `/v1/execute-generic`. Requester a human super admin (live, fail-closed check), approver a different human super admin, change-ticket reference, `hold_minutes`. Permanently L3, chat only, never in a playbook ([05](05-autonomy-ladder.md) §4) |

The denial suite's exit checklist inverts to "`$ROBOT` is a super admin, on the floor list, and
every super-admin-class request is denied in the catalogue lane". It gains two tests: "write
targeting the robot itself" and "any `makeAdmin`" (platform HLD §13.1 item 10).

## What prompt-based defence cannot do

The system instruction tells the agent that retrieved content is data, never instruction.
That is worth having and it will sometimes fail. Design accordingly:

- Never promote an operation because "the prompt handles it".
- Never let an autonomous run choose a message recipient. This is why `notify.operators`
  exists as a separate operation, in its own family, with config-fixed recipients.
- Never let content decide a ceiling. The taint bit is the mechanism; the system
  instruction is the courtesy.
- Treat every ceiling in [05](05-autonomy-ladder.md) §4 as compensating for a prompt that
  has already failed. If a control only works when the prompt works, it is not a control.

## Forbidden configurations, checked in CI

Each of these is one line that removes a property the design depends on.

| Setting | Why it is forbidden | Check |
|---|---|---|
| `GOOGLE_API_PREVENT_AGENT_TOKEN_SHARING_FOR_GCP_SERVICES: False` in any engine config | Opts the agent out of certificate-bound tokens, so a stolen token becomes replayable | CI fails on the variable anywhere under the agent package |
| `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS` unset or `true` | Defaults on, and puts tool arguments and tool responses, which carry employee data, into Cloud Trace with a 30-day retention nobody controls | CI asserts `false`; the daily drift job reads the deployed environment |
| `failOpen: true` on the Model Armor authorization extension | Turns the one enforcement-grade prompt screen into a detection-grade one | CI asserts `false` in the committed extension YAML |
| Any caller of the engine on `query` or `asyncQuery` | The ingress gateway screens `streamQuery` only | CI greps the dispatcher and Eve's caller for the forbidden methods |
| Any import of `google.adk.integrations.skill_registry`, `SkillToolset`, `McpToolset` or `RemoteA2aAgent` in the agent package | Each is a channel through which the model chooses its own capabilities | CI fails on the import; the deployed tool list is compared to `/v1/operations` after every deploy |
| `identity_type` other than `AGENT_IDENTITY` in the deploy config, unless the recorded spike result says the fallback is in force | The decision is immutable at engine creation | CI check plus a post-deploy assertion on `spec.effectiveIdentity` |

Detail and mechanisms: [11-prompt-security.md](11-prompt-security.md), [12-agent-identity.md](12-agent-identity.md), [13-agent-interconnection.md](13-agent-interconnection.md).

## Monitoring

Alert on, at minimum (the content-screen, taint-rate, filter-version and span-capture alerts are specified in [11-prompt-security.md](11-prompt-security.md) section 6 and extend this table):

| Signal | Basis | Why |
|---|---|---|
| Any interactive login to the robot account | Workspace login audit | After bootstrap this is by definition an incident |
| Any hard-invariant denial | `walle_audit.actions` | Something is probing the boundary. Also trips the breaker automatically. |
| Any `WRITE_HIGH` executed autonomously | `actions` where `principal_type != human` | Rare enough to read every one until Stage 5 |
| Any verification `drift` | `verifications` | The write did not do what the plan said |
| Halt set or override written | Firestore audit, `walle-events` | Every andon pull visible within a minute |
| Config version applied | `config_versions` | The change trail, and drift detection |
| Approval from an identity not in the operators group | approvals | Spoofed approval |
| Eve signature invalid | action service | Eve impersonation |
| Audit insert failure | action service | Writes are already refused; someone must know why |
| Secret access by a non-service identity, on `WALLE_PROJECT`'s secrets — both client-and-token pairs (`walle-oauth-client`/`walle-refresh-token` and `walle-super-oauth-client`/`walle-super-refresh-token`) and the HMAC key; *was "three secrets" until the two-client split of 2026-09-13* | Cloud Audit Logs | Credential access outside the action service. Access to `eve-refresh-token` and `eve-oauth-client` is monitored by Eve's own drift job in `EVE_PROJECT`, which Wall-E's cannot read (decision 46) |
| Scheduled run missing two consecutive windows | dispatcher | A dead trigger looks exactly like a quiet week |
| `invalid_grant` from Google | action service | The credential is gone; Wall-E is down until re-bootstrap |

**The super-admin detection set (added 2026-09-13).** With a super-admin robot, detection is
the primary control (platform HLD §13.1 item 5, §7.3). The rows below are **hosted in the
SIEM, never in `WALLE_PROJECT`**, and owned by IT security. They are severity 1 and page the
second human outside the Wall-E line in parallel with the on-duty desk. The rule of record,
with its source, runbook and test fixture, is
[../agentic-platform/07-monitoring-detection-incident-response.md](../agentic-platform/07-monitoring-detection-incident-response.md)
§6.2 (Workspace side) and §6.3 (GCP organisation side). The rows above stay where they are.
The interactive-login row above is also SA-04 in the SIEM.

| Signal | Basis | Why |
|---|---|---|
| SA-01: any `admin.googleapis.com` method by `walle@` outside the committed allow-list derived from the catalogue, and not claimed by a band-B audit row within 5 minutes | Workspace admin stream; band-B audit rows | The credential acted outside both lanes |
| SA-02: any admin-role creation or assignment by `walle@`; any `users.makeAdmin` by anyone; any change by `walle@` to another admin's security settings, backup codes or recovery options | admin stream | Hard-denied escalation attempted or succeeded |
| SA-03: any change, by any actor, to sharing with Google Cloud services, the SecOps export, activity rules, API controls, OAuth app trust, DWD, 2SV policy, SSO, super-admin self-recovery or session settings | admin stream; the SecOps export; Security Command Center Event Threat Detection Workspace findings | Posture change, including self-silencing of monitoring |
| SA-04: any `login.googleapis.com` event for `walle@` or `eve@` | login stream | An interactive login is by definition an incident, and the one control that survives Super Admin |
| SA-05: an OAuth token authorised on `walle@` from a client id outside the two committed ones; a consent change on the two clients; a `tokens.delete` on `walle@` not attributed to K4/K5 | token stream | Leaked-token signature (runbook RB-01) |
| SA-06: daily roster diff — super admins and delegated admins from Eve's own `users.list` and `roleAssignments.list` against the committed roster | Eve's credential; the SIEM re-checks from admin events | A fourth super admin, or the robot's own role removed (`role_assignment_missing`, paging in both directions) |
| SA-07: a robot-attributed admin event with no matching `walle_audit` or band-B row within 5 minutes | join in the SIEM | Eve's completeness metric in near real time; a row-less action means the credential acted outside the service |
| SA-08: any event by `walle@` in an application outside the catalogue's families (Drive, Gmail, Calendar, Vault, Takeout, Data Studio…) | admin stream; Eve's Reports API poll by actor | Reach the families never needed |
| SA-09: a membership change on the control groups or the `eve-console` IAP audience group; a change to the two OAuth clients' consent or scopes | groups stream; reconciliation | Control-plane tampering |
| Organisation side: `SetIamPolicy` at organisation, folder or `EVE_PROJECT` by `walle@`; changes to the aggregated sinks, locked buckets, `auditConfigs`, org policies, floors, deny or PAB policies | Cloud Audit Logs | The robot's path into the GCP organisation |
| Absence: no `eve_workspace_logs` rows for 60 minutes in business hours; no Eve heartbeat for 15 minutes; Eve's token returning `invalid_grant` — halt reason `log_pipeline_silent` | the witness organisation and the SIEM | A super admin can switch the sharing off; silence is the signal |

## Compliance

- **Two named regimes (added 2026-09-13).** The platform is to be **EU AI Act** compliant
  (Regulation (EU) 2024/1689, as amended by the Digital Omnibus on AI, Regulation (EU) 2026/1744) and **TISAX**
  compatible. Neither is argued here. Platform HLD §14 carries both:
  - §14.1: Wall-E's declared intended purpose is the catalogue (band A). Band B is "execution
    of a fully specified administration request decided and approved by two human super
    administrators"; band C is instructions to a human. The hard-denied list is the Art. 6(3)
    boundary, enforced in code. The per-system classification and legal sign-off are in
    [../agentic-platform/10-eu-ai-act.md](../agentic-platform/10-eu-ai-act.md) §3.1 (P28, P125).
  - §14.2: Super Admin is a **signed TISAX deviation** on ISA 4.2.1, row R-01 of the risk
    register (P33). The control-by-control mapping is
    [../agentic-platform/11-tisax.md](../agentic-platform/11-tisax.md) §5. An assessor may still
    refuse maturity 3 on that deviation.
  This page's Monitoring and threat-model rows are part of the evidence both frames cite. They
  do not replace the frames.
- **Data protection, and `Assumption:` employee representative bodies with a say here, where your jurisdiction has them.** Wall-E reads directory data, usage reports and audit logs
  about employees, and acts on their accounts. Autonomous action is a **different
  processing activity** from human-requested action, so the assessment needs redoing at
  the stage where writes stop having a human in the path — realistically before Stage 3,
  and the question should be asked in week one because it has the longest lead time of
  anything in this plan.
  *Qualified 2026-09-13:* worker information and consultation move to **before Stage 1**, under
  GDPR and, voluntarily, EU AI Act Art. 26(7). DPO engagement is a precondition of the
  super-admin grant ([decision 8](09-open-decisions.md); P129; platform HLD §0.4, §14.1).
- **Data residency.** All four projects sit under `FOLDER_ID` in `europe-west1` with
  BigQuery in `EU`; in `WALLE_PROJECT`, Agent Runtime, Cloud Run, Firestore, Pub/Sub and
  BigQuery all in `europe-west1` or EU. Secret Manager **regional secrets**, not global secrets
  with user-managed replication. Two limits to record rather than discover: Agent Runtime
  **Code Execution has no EU at-rest residency** (do not enable it — Wall-E must not run
  arbitrary code anyway) — *corrected 2026-09-13 by platform HLD §11.4: Code Execution **is**
  EU-resident; it stays off fleet-wide for another reason: its launch stage is unverified, its
  isolation technology unnamed and its egress path undocumented (P121),* and **CMEK is unavailable** when the runtime uses a
  multi-regional endpoint or sessions use the global one. Confirm the Gemini Enterprise app in
  `GEMINI_PROJECT` is `eu` or `global` — an `eu` app fronts `europe-*` agents, a `global` app
  any region — and pin a model that has EU residency — not every current model does. One
  exception to accept knowingly: **Workspace audit logs land in Cloud Logging at
  organisation level and their storage region is not selectable.**
- **Retention.** Set a table expiry on every audit table. 400 days is a reasonable default
  pending your retention policy. *Qualified 2026-09-13:* the floor is the larger of the EU AI Act
  six months (Art. 26(6)) and the organisation standard; the ceiling is the DPO's. The schedule of
  record is platform HLD §7.5 and
  [../agentic-platform/08-data-logging-retention-sovereignty.md](../agentic-platform/08-data-logging-retention-sovereignty.md) §5.2.
- **Evidence.** The audit dataset is the answer to "what has the robot done", and it is
  the first thing an auditor will ask for. The action service holds insert-only rights on
  it, deliberately.
