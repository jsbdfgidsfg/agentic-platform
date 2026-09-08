# 6. Security & guardrails

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-08

## The honest risk statement

You are giving an LLM a path to admin operations on the organisation's Workspace tenant, and then
removing the human from that path one step at a time. That is a legitimate thing to build
and it is the highest-blast-radius system in your estate. Everything below exists so that
the answer to "what happens when the model is wrong, or manipulated, or the trigger fires
at the wrong moment" is *an audit row and a refused approval*, not an incident.

Three properties carry most of the weight:

1. **The model never holds the credential.** It lives in the action service, behind IAM.
   No tool returns it and no prompt reveals it.
2. **The model cannot self-authorise.** Approvals are minted by the service, released by a
   human or by Eve from a separate identity with a separate key, bound to canonical
   parameters and pre-state, single-use.
3. **The model cannot change its own leash.** The ladder config, the overrides and the
   halt flags are unreachable from any catalogue operation, and `walle-agent@` has no IAM
   on them.

## The blast-radius ceiling: what must never happen

You have not yet ratified this list, so treat it as the proposal you sign off in
[decision 4](09-open-decisions.md). It is ordered worst first, and every row maps to a
mechanism in [03-lld.md](03-lld.md).

| # | Must never happen | Why it is the ceiling | What prevents it | Enforced by |
|---|---|---|---|---|
| **N1** | **Wall-E changes tenant security posture** — 2SV, SSO, password policy, API controls, DWD, admin roles | A robot that can change the rules constraining it is not constrained. Recovery window is unbounded. | Not in the catalogue, and **not in the custom role** | Workspace role + catalogue registry |
| **N2** | **Permanent data loss** — a deleted user, group or mailbox | Restore is possible for 20 days only, and needs a spare licence. Rollback does not exist. | Not in the catalogue, not in the role | Same |
| **N3** | **Privilege escalation through a group** — adding anyone to a group that grants admin rights, GCP IAM, or control of Wall-E, Eve or Mo | The quiet path to N1 | Security-class groups blocked; unclassified groups treated as security | `_check_target` on `group_key`, group classification, fail closed |
| **N4** | **Mass action** — the same operation looped across an OU | The realistic shape of both an injection and a bug | Explicit enumerated targets only; per-run object cap; daily budget; novelty cap | Catalogue parameter models, durable Firestore counters |
| **N5** | **Acting on instructions found in content** — mail, Chat, documents, audit rows, **display names, group names, error text** | The one attack that will actually be attempted | The **taint bit**: any attacker-writable field reaching the model forces the inbox ceiling for that run, whatever the trigger. Plus the playbook `uses` allowlist, the pinned selection query, a closed error enum that never echoes upstream text, and canonicalisation of every attacker-writable string | Taint evaluation in the policy chain, ceilings in code, playbook validator ([03](03-lld.md)) |
| **N6** | **Outbound communication chosen by the model, unattended** | An admin account is trusted by every employee; a phishing mail from it is not recoverable | Templated notification (`notify.operators`, family F2) and free text (`gmail.send`, `chat.message.send`, family **F2b**) are different families with different ceilings. An earlier draft put them in one family, which would have made free-text mail autonomous at L4 on a schedule — the exact thing this row forbids | Family split in the catalogue; recipient domain check as an explicit policy step |
| **N7** | **Touching a protected principal** — super admins, delegated admins, itself, its own OU | Self-modification and lateral movement | Protected-principal check, fails closed | `_check_target`, background-refreshed admin cache |
| **N8** | **An action nobody can see** | Undetected drift is worse than a visible failure | Write-ahead audit; writes refused when the audit sink is down; reconciliation against Workspace audit logs. That reconciliation needs an **organisation-level aggregated log sink into BigQuery** — an earlier draft routed those logs only to Pub/Sub, so the completeness metric had nothing to query. It also needs org-level permission to create the sink | Audit module, aggregated sink, Eve's completeness metric |
| **N9** | **Acting as a person** | Impossible by construction, and must stay impossible | No DWD, no user write tokens ever accepted by the action service | Architecture |

If you disagree with any row, say so before build — every one of them has cost the design
something, and N6 in particular cost the convenience of a chatty autonomous agent.

## Threat model

Rows marked **new** did not exist for Edge AI v2 because it had no autonomous path.

| Threat | Control | Residual risk |
|---|---|---|
| Prompt injection via mail, Chat or a document | T3 write ceiling of L2; playbook `uses` allowlist; explicit targets; untrusted-content tagging; approvals the model cannot mint | An injection can cause a **proposal** to appear in the operator queue. Accepted, and visible. |
| Model invents a destructive call | Catalogue allowlist; typed parameters; protected principals; level | Low |
| Credential exfiltration through the agent | Credential absent from the agent's process and context; IAM on the secret | Low |
| Compromised agent service account | It can only call the action service, which still enforces principal, level and approval | Attacker gains what the current level allows unattended — which is why levels rise slowly |
| Insider misuse by an operator | Group-gated, every action attributed, weekly `WRITE_HIGH` review | Operators can do operator things. By design. |
| Robot credential leak | Custom role, not Super Admin; OU-scoped role; revocation path; login alerting | Bounded by the role's privileges at the current stage |
| **new** Runaway loop or trigger storm | Dispatcher budget check before any model call; per-run and daily caps; dedup by event id; a T2 run may not emit a T2 event; breaker on consecutive failures | Bounded to one run's cap |
| **new** Poisoned upstream signal — a bad HR feed or forged event | Events only from Workspace audit logs signed by Google's own pipeline; suspend at L4 only when the trigger is a system of record; caps still apply | A valid-but-wrong upstream record produces up to one run's worth of changes, all reversible |
| **new** Stale state — a human admin acts between plan and execution | Pre-state hash bound into the approval; **every item re-read immediately before execution**; mismatch skips the item | Skipped item, reported. Not an incident. |
| **new** Eve unavailable | L4 items **wait**; over four hours sets `no_autonomous`; L5 without post-hoc verification within SLA demotes to L4 | Work stalls. Correct outcome. |
| **new** Eve compromised or rubber-stamping | Eve can only lower and approve, never raise; sampled human review of Eve verdicts; an overturned Eve approval demotes both the family and Eve's authority; Eve's key is separate and rotates independently | Eve could approve within the current level's blast radius until the next sample. Mitigated by hold windows and vetoes. |
| **new** Mo proposes a harmful change | Mo has no write path; its output is a pull request needing a human approver, CI validation and a decision record | A rubber-stamped pull request. Mitigated by the two-person rule on L4/L5. |
| **new** Ladder config tampering | Config in git with code ownership; **the ceiling module, policy chain and validator are owned separately and the check runs outside the repository**, so one pull request cannot move the ladder and the gate together; `config_version` and `ceilings_sha` on every row | Detected within one verification cycle |
| **new** The action service itself is compromised or buggy | Eve's asymmetric key means the service cannot mint an Eve approval; plans are create-only so a signed plan cannot be rewritten; the Workspace audit log is written by Google, not by us | **Real and only partly mitigated.** Every control still runs in one process. See [10](10-adversarial-review.md) and [decision 18](09-open-decisions.md) |
| **new** Operators cannot reach the control plane | `run.invoker` bound to the operator group, plus an out-of-band approval surface | If neither exists, every kill switch is theoretical. This was true of the first draft |
| **new** Quota exhaustion locking out human admins | Per-operation ceilings well below Google's limits; backoff; quota errors as a distinct outcome class | Wall-E throttles itself before the tenant does |
| **new** Credential revoked mid-run | `invalid_grant` treated as a paging incident, not a retry; run aborts at the current item | Partial run, reported |
| **new** Wrong-homonym targeting | Plans carry pre-state including OU and manager; proposals show it; explicit targets only | Human or Eve sees the wrong context before approving |
| **new** Licence reclaim causing data loss | Reclaim restricted to suspended accounts first; the retention consequence of removing a licence on the organisation's plan must be confirmed with Google before active accounts are in scope | Unquantified until that answer exists — see [decision 7](09-open-decisions.md) |
| **new** Timezone or business-hours error | Business hours in config with an explicit timezone; last write at 16:00; holds do not span the boundary; weekend suspensions blocked | A run waits until morning |

## Never in the catalogue

Not a level, not a stage, not a config flag. Adding any of these is a design change
needing a decision record and a security sign-off, and the default answer is no.

| Category | Operations |
|---|---|
| Privilege and posture | Admin role create, assign or revoke · 2SV, password, session, login-challenge or recovery settings · API controls and OAuth app trust · domain-wide delegation · domain and DNS settings · SSO/SAML · DLP · context-aware access · data regions |
| Irreversible data | User delete or undelete · group delete · OU delete · mailbox purge · Vault matters, holds, exports and retention · tenant data export |
| Credentials | Password set or reset · app passwords · security keys · token revocation for other users |
| Self-modification | Anything targeting the robot account, its OU, the `walle-*` control groups, the ladder config, the catalogue, the overrides or the halt flags |
| Structure | OU create, delete, rename or move. Moving a *user* into an allowlisted OU is F4; changing the tree is not. |
| Money | Subscriptions, billing, edition changes, licence pool purchases |
| Outside Workspace | GCP IAM, Gemini Enterprise configuration, project settings |
| Other people's Drive | File mutations, ownership changes, sharing changes. Unreachable without DWD — and do not add DWD to reach them. |

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

## Monitoring

Alert on, at minimum:

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
| Secret access by a non-service identity | Cloud Audit Logs | Credential access outside the action service |
| Scheduled run missing two consecutive windows | dispatcher | A dead trigger looks exactly like a quiet week |
| `invalid_grant` from Google | action service | The credential is gone; Wall-E is down until re-bootstrap |

## Compliance

- **Data protection, and `Assumption:` a works council with a say here.** Wall-E reads directory data, usage reports and audit logs
  about employees, and acts on their accounts. Autonomous action is a **different
  processing activity** from human-requested action, so the assessment needs redoing at
  the stage where writes stop having a human in the path — realistically before Stage 3,
  and the question should be asked in week one because it has the longest lead time of
  anything in this plan.
- **Data residency.** Project, Agent Runtime, Cloud Run, Firestore, Pub/Sub and BigQuery
  all in `europe-west1` or EU. Secret Manager **regional secrets**, not global secrets
  with user-managed replication. Two limits to record rather than discover: Agent Runtime
  **Code Execution has no EU at-rest residency** (do not enable it — Wall-E must not run
  arbitrary code anyway), and **CMEK is unavailable** when the runtime uses a
  multi-regional endpoint or sessions use the global one. Confirm the Gemini Enterprise app is in the `eu`
  multi-region and pin a model that has EU residency — not every current model does. One
  exception to accept knowingly: **Workspace audit logs land in Cloud Logging at
  organisation level and their storage region is not selectable.**
- **Retention.** Set a table expiry on every audit table. 400 days is a reasonable default
  pending the organisation policy.
- **Evidence.** The audit dataset is the answer to "what has the robot done", and it is
  the first thing an auditor will ask for. The action service holds insert-only rights on
  it, deliberately.
