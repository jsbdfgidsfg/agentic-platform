# 6. Security & guardrails

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-05

## The honest risk statement

You are giving an LLM a path to admin operations on the organisation's Workspace tenant. That is a
legitimate thing to build, and it is also the highest-blast-radius system in your estate.
Everything below exists so that the answer to "what happens when the model is wrong or
manipulated" is *"an audit row and a declined confirmation"* rather than *"an incident"*.

Two properties carry most of the weight:

1. **The model never holds the credential.** It is in Cloud Run, behind IAM, read from
   Secret Manager. There is no tool that returns it and no prompt that reveals it.
2. **The model cannot self-authorise.** High-risk operations require an HMAC token the
   service issues, bound to the exact operation, parameters and actor. Generated text
   cannot produce one.

## Threat model

| Threat | Control | Residual risk |
|---|---|---|
| Prompt injection via email/Chat/doc content | WRITE_HIGH confirmation; content flagged untrusted; system prompt; audit | Model performs an unwanted **WRITE_LOW** action (sends an email, posts a message). Real. Accept or promote those to HIGH. |
| Model hallucinates a destructive call | Operation allowlist; confirmation; protected principals | Low |
| Credential exfiltration through the agent | Credential absent from agent process; Cloud Run internal ingress | Low |
| Compromised agent service account | It can only call the action service, which still enforces actor group and confirmation | Attacker needs a valid actor in the operator group |
| Insider misuse via Gemini Enterprise | Group-gated access, full audit with actor attribution | Operator-group members can do operator things — by design |
| Robot account credential leak | Custom role not Super Admin; revocation path; login alerting | Bounded by the role's privileges |
| Self-escalation | Role excludes admin-role management and security settings; protected-principal check refuses writes against admins | Low |

## Controls that must not be weakened

1. **WRITE_HIGH confirmation.** Removing it turns every injection into a live admin action.
2. **Protected principals.** The service refuses Directory writes against super admins,
   itself, and `edge-ai-protected@`. It **fails closed** — if it cannot enumerate admins,
   directory writes are refused entirely.
3. **`SAFE_USER_FIELDS` allowlist** in `ops/directory.py`. `directory.user.update` cannot
   touch passwords, admin status, 2SV or aliases regardless of what is asked.
4. **Internal-only ingress and IAM on Cloud Run.** The action service must never be
   reachable from the internet.
5. **Custom admin role, not Super Admin.**

## Where prompt-based defence is not enough

The system prompt tells the agent that retrieved content is data, not instruction. This
is worth having and it will sometimes fail. Design accordingly:

- Never promote an operation to WRITE_LOW because "the prompt handles it".
- Treat `gmail.send` as the real exposure at WRITE_LOW: an injection could get the agent
  to email someone. It cannot reach external recipients without confirmation (the policy
  engine forces confirmation for any recipient outside the domain), but internal mail
  from the robot account is reachable. Decide whether that is acceptable
  ([07-open-decisions.md](07-open-decisions.md)).

## Monitoring

Alert on, at minimum:

| Signal | Query basis | Why |
|---|---|---|
| Any interactive login to the robot account | Workspace login audit | After bootstrap this is by definition an incident |
| `decision = 'denied'` spike | `edge_audit.actions` | Something is probing the boundary |
| `denial_reason = 'protected_principal'` | `edge_audit.actions` | Someone or something tried to touch an admin |
| `denial_reason = 'bad_confirmation_token'` | `edge_audit.actions` | Token forgery attempt |
| Any WRITE_HIGH execution | `edge_audit.actions` | Should be rare enough to read every one |
| Secret version access anomaly | Cloud Audit Logs | Credential access outside the action service |

Weekly review of every WRITE_HIGH row is a five-minute habit worth keeping for the first
few months.

## Compliance notes for the organisation

- **Works council / GDPR:** the agent reads employee mailbox content (the robot's own)
  and Directory data, and its audit log records who asked for what. Confirm whether this
  needs a DPIA and works council information before pilot. This is likely the longest
  lead-time item in the whole project — start it in parallel with Phase 1.
- **Data residency:** pin the project, Agent Engine, Cloud Run and BigQuery to an EU
  region and confirm the Gemini Enterprise data region matches.
- **Retention:** set a table expiry on `edge_audit.actions` consistent with the organisation policy.
