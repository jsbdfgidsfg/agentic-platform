# 2. Identity & authorisation

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Premise: the robot is a **super-admin user account** with two OAuth clients read by two services
  (`walle-actions` narrow, `walle-actions-super` broad) — platform register row **P33**,
  [../../decisions/2026-09-13-wall-e-holds-super-admin.md](../../decisions/2026-09-13-wall-e-holds-super-admin.md)
  (accepted; the TISAX deviation not yet signed), platform HLD §13.1 and §18 item 1. Decision 26 is
  closed for Wall-E by fact and stays open for Eve as E-16.
- Placement: [../project-topology.md](../project-topology.md) is the authority for every grant that
  crosses a project;
  [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md)
  owns the roster (§8.1), session facts (§8.2), key custodians (§8.3), multi-party approval (§8.4)
  and the K-switch order (§9.7), which this page applies to Wall-E. The platform's standing
  constraints are the [platform HLD Status](../agentic-platform/01-hld.md#status); Eve's key is not
  Wall-E's.

This is the core of the design. Read it before anything else.

## The problem, restated

Workspace APIs authorise against a *user*, and the usual bridge from a service account —
**domain-wide delegation** — is excluded, because it is a tenant-wide capability scoped only by
OAuth scopes with which a compromised service account can act as *anyone*, including a super
admin; so Wall-E acts as exactly one identity, the robot account, and every action it takes is
attributed to `walle@` in Google's own log, the property Eve's reconciliation depends on. Since the
objective of 2026-09-13 that identity holds Super Admin: a service account can hold any Workspace
admin role except Super Admin, so it is a **licensed user account** (decision 26 closed for Wall-E
by fact), and Super Admin cannot be limited to an organisational unit or a subset of privileges, so
the consented OAuth scope set is the only Google-enforced ceiling left — which is why this page
splits the credential into two clients. What that reverses and costs is
[platform HLD "What this reverses and what it costs"](../agentic-platform/01-hld.md#what-this-reverses-and-what-it-costs).

## Principals, and what each may do

Autonomy means machines now approve things, so who signs matters as much as who acts.

| Principal | Home project | Type | Holds | May do |
|---|---|---|---|---|
| `walle@<domain>` | — (Workspace) | Workspace user, **licensed, Super Admin** (P33) | Two OAuth refresh tokens, one per client, each in its own regional secret in `WALLE_PROJECT` | Anything a super admin can do through the scopes a client was consented with — Google enforces the scopes, not a role. Everything else is refused by the action services' code (the hard-denied list and the bands, [03](03-lld.md)). The only identity that touches Workspace. Never signs in interactively after bootstrap; never the only or the recovery super admin (§"The roster rule") |
| `walle-actions@WALLE_PROJECT` | `WALLE_PROJECT` | GCP service account | Reads the **narrow** refresh token, its OAuth client and the HMAC key | Runs `walle-actions` (band A, the catalogue, the ladder). The only reader of the narrow credential secrets. Holds **no** principal in `EVE_PROJECT` beyond the carve-outs of decision 48, and none in `MO_PROJECT`. Never reads the broad secrets |
| `walle-actions-super@WALLE_PROJECT` (name follows the one-account-per-duty rule, platform HLD §4.3) | `WALLE_PROJECT` | GCP service account | Reads the **broad** refresh token and its OAuth client, nothing else | Runs `walle-actions-super` (band B `/v1/execute-generic`, band C `/v1/handoff`). The only reader of the broad credential secrets. Never reads the narrow secrets or the HMAC key. No trigger, dispatcher or Mo identity can invoke it |
| `walle-agent@WALLE_PROJECT` | `WALLE_PROJECT` | GCP service account (Agent Identity replaces it at engine creation, [12](12-agent-identity.md)) | Nothing | Runs the Wall-E agent on Agent Runtime. Can call both action services (band A on one, bands B and C on the other). Cannot read any secret |
| `walle-dispatcher@WALLE_PROJECT` | `WALLE_PROJECT` | GCP service account | Nothing | Invokes the agent. Holds `aiplatform.reasoningEngines.query` on Wall-E's engine only (same project). Reads halt flags. Holds **no** invoker on `walle-actions-super`, so no trigger class but a human in chat can originate a band-B request |
| `walle-tasks@WALLE_PROJECT` | `WALLE_PROJECT` | GCP service account, the OIDC identity of the Cloud Tasks queue `walle-plan-items` | Nothing | Delivers one queued plan item back into the worker endpoint `POST /v1/tasks/item` of `walle-actions`, and nothing else; on the in-app allowlist for that endpoint only. Unverified which identity the build uses: [ARCHITECTURE.md](ARCHITECTURE.md) §3, [12](12-agent-identity.md) and [../project-topology.md](../project-topology.md) name `walle-tasks@`, while [SETUP.md](SETUP.md) Phase 6 does not create it and Phase 10 binds `walle-actions@` for the callback |
| `walle-operators-caller@WALLE_PROJECT` | `WALLE_PROJECT` | GCP service account, never a workload identity | Only the right to be **impersonated** by a human operator (`roles/iam.serviceAccountTokenCreator` held by the members of `walle-operators@`) | Lets a human mint an ID token with the right audience, which `gcloud auth print-identity-token --audiences=` refuses for user credentials. Holds `run.invoker` on `walle-actions` so the control endpoints (halt, demote, K4) have a terminal handle; the service keys its control allowlist on this email and re-checks the human separately through the operators-group check. It holds **no** `run.invoker` on `walle-actions-super`: operators halt that lane through the approval surfaces, or by halting `walle-actions`, because both services read the same Firestore control document ([03 §"The policy engine"](03-lld.md#the-policy-engine)). K4 on `walle-actions-super` is pulled from the approval page; which caller identity carries it is *tbd* until 03's endpoint table lists the revoke endpoint ([ARCHITECTURE.md §4.6](ARCHITECTURE.md#46-kill-switches)) |
| `eve-controller@EVE_PROJECT` (and `eve-verifier@`, halt only on `walle-actions-super`) | `EVE_PROJECT` | GCP service account | Signs with **Eve's own** Cloud KMS key `eve-approval` in `EVE_PROJECT`, and nothing of Wall-E's | Calls the control endpoints (approve, veto, halt, demote) on `walle-actions`, only halt on `walle-actions-super`, and reads `walle_audit`; the exact grants are [../project-topology.md §3](../project-topology.md#3-cross-project-grants) rows 3, 4 and 27, and the identities are [../eve/02-identity-and-auth.md](../eve/02-identity-and-auth.md). Cannot execute an operation |
| Human operators, `walle-operators@` | — (Workspace group) | Workspace group | Nothing | Approve, veto, halt, demote, grade — through the approval page or by impersonating `walle-operators-caller@`. **No human holds `run.invoker` on an action service directly** (platform rule, [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §6.4–6.5; [03](03-lld.md)); the andon cord keeps its handle through the caller identity |
| Deployers | `WALLE_PROJECT` | The release pipeline, impersonating `walle-deployer@WALLE_PROJECT` (the platform's `<agent>-deployer@` form, P142); a human only through the PAM entitlement `ent-deploy-credential-holder` | `run.developer` on `walle-actions` and `walle-actions-super`, and `iam.serviceAccountUser` on the attached runtime service accounts only ([12](12-agent-identity.md) lists them) | Ship a revision of a credential holder. A revision defines what every allowlist means |

The columns the table above leaves out — what each principal may read, whether it holds
`run.invoker`, and what it must never do:

| Principal | May read | `run.invoker` | Must never |
|---|---|---|---|
| `walle@` | Everything Super Admin allows — the whole tenant, bounded on the Google side only by each client's consented scopes | Not applicable: a Workspace identity, never a GCP caller | Be signed into interactively after bootstrap (by definition a severity-1 incident). Be the only or the recovery super admin. Hold any organisation-level IAM role (a drift row). Be the target of any write through Wall-E's own lanes (the protected-self rule) |
| `walle-actions@` | The narrow client's two secrets and the HMAC key, Firestore, BigQuery insert on `walle_audit`, Eve's public key from the pinned PEM | No: it runs `walle-actions`, it does not call it (but see the `walle-tasks@` row on the Cloud Tasks callback) | Read Eve's private key. Mint an Eve approval. Delete audit rows. Read the broad client's secrets |
| `walle-actions-super@` | The broad client's two secrets, its own audit rows, the pinned Discovery documents | No. On `walle-actions-super`, `run.invoker` is held by the agent's identity, the `walle-approvals-super` surface's own service account (name *tbd*), `eve-controller@` and `eve-verifier@` (halt only) and `platform-drift@CORE_PROJECT` (halt only) — never `walle-dispatcher@`, `walle-tasks@`, `eve-console@` or any Mo identity ([03](03-lld.md)) | Read the narrow client or the HMAC key. Execute anything at tier `SUPER` without the approval of a second human super admin. Serve any trigger but a human in chat. Appear on any `playbook.uses` path. Hold Eve's signing key |
| `walle-agent@` (or the agent principal) | No secret at all | **Yes**, on `walle-actions` (execute and plan endpoints) and on `walle-actions-super` (band B and C endpoints, chat only) | Read any secret. Reach any control or approval endpoint. Hold a Workspace token |
| `walle-dispatcher@` | Halt flags | **No.** It calls the agent and reads Firestore, never an action service | Call an action service at all. Hold any secret |
| `walle-tasks@` | Nothing | **Yes**, on `walle-actions`, narrowed to the worker endpoint by the in-app allowlist | Call any endpoint but the worker endpoint |
| `walle-operators-caller@` | Nothing | **Yes**, on `walle-actions` | Run as a workload. Hold any secret or any Workspace role |
| `eve-controller@EVE_PROJECT` | `walle_audit` (dataset-level), plans and runs through the read endpoints, and its **own** read-only Workspace credential stored in `EVE_PROJECT` | **Yes**, on `walle-actions`; halt only on `walle-actions-super` (topology §3 rows 3 and 27) | Execute any Workspace operation. Raise any level. Read any secret or signing key of Wall-E's. Hold any project-level role in `WALLE_PROJECT`, `walleEngineQuery` on the engine, any KMS role in `WALLE_PROJECT` or `datastore.viewer` — the anti-grants of topology §3 rows 12 and 13 and decision 44 |
| Human operators, `walle-operators@` | The control and read endpoints | Not directly — on `walle-actions` through `walle-operators-caller@` or the approval page; on `walle-actions-super` only through the approval surfaces | Also hold `run.developer` on an action service |
| Deployers | The services' image and configuration | Not the point: a revision defines what every allowlist means | Be an operator or an approver at the same time |

**The deploy grant is the largest control in the system.** A deploy to `walle-actions` or
`walle-actions-super` changes the credential holder and the policy engine in one act: the new
revision keeps the service account, reads the pinned secret version and can do anything at all
with it — a super-admin credential. That single grant defeats the policy
engine, the catalogue, the ladder, the in-app allowlist, the approval endpoints and the
insert-only audit rights at once. So deploys come only from a CI pipeline whose identity no
operator holds, from a branch requiring a second reviewer on the ceiling module, the policy chain
and the catalogue; **no human holds `run.developer` on either service in steady state**; the
break-glass path is the Privileged Access Manager entitlement `ent-deploy-credential-holder`
(1 h, approved by the second reviewer, never the agent's owner), a precondition of the Super Admin
grant ([../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §5.2;
[ARCHITECTURE.md](ARCHITECTURE.md) §11 weakness 12 records the residual).

Two Workspace groups carry policy rather than access: **`walle-readers@`**, whose members may
invoke READ operations only and who see nothing until the agent is also shared with them in
Gemini Enterprise, and **`walle-protected@`**, whose transitive members can never be the target of
a write.

Eve's and Mo's identities that touch Wall-E resources — `eve-v0@`, `eve-controller@`,
`eve-verifier@`, `eve-console@` and `eve-export@` in `EVE_PROJECT`; `mo-metrics@` and `mo-analyst@`
in `MO_PROJECT`, none of them on `walle-actions-super` except Eve's two halt-only grants — hold
exactly the grants of [../project-topology.md §3](../project-topology.md#3-cross-project-grants)
(rows 3–8, 12–14, 27 and 34), and nothing of Mo's lives in `WALLE_PROJECT`; their own pages are
[../eve/02-identity-and-auth.md](../eve/02-identity-and-auth.md) and
[../mo/02-identity-and-access.md](../mo/02-identity-and-access.md). Eve's Workspace account `eve@`
holds a read-only custom role and is **never** Super Admin; the objective requires it.

Human principals that matter to this page: the two human super admins'
**admin accounts** `sa-1-admin@` and `sa-2-admin@` (the latter outside the Wall-E administration
line), members of `walle-super-approvers@`, the audience of the band-B `SUPER` approval surface
`walle-approvals-super` ([../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §6.4).

Properties to preserve as you build:

1. **`walle-agent@` can read no secret.** Check this after every IAM change. It is
   boundary 3 in one sentence.
2. **`eve-controller@` and `walle-actions@` never share a key.** Eve signs approvals with
   the Cloud KMS key `eve-approval` (ring `eve`) in `EVE_PROJECT`, where no Wall-E
   principal exists to be granted `useToSign`; the action service verifies with Eve's
   public key **pinned as PEM in Wall-E's repository**, per key version, which needs no
   cross-project KMS grant at all. The optional fallback is `roles/cloudkms.publicKeyViewer`
   granted in `EVE_PROJECT` on that one CryptoKey to `walle-actions@WALLE_PROJECT` — never
   ring- or project-level ([../project-topology.md](../project-topology.md) §3 row 14). If
   they shared one, "Eve approved this" would mean nothing.
3. **Each credential has exactly one reader.** `walle-actions@` never reads the
   broad secrets; `walle-actions-super@` never reads the narrow ones. If one service could read
   both, the narrow client's scope ceiling would be decorative. Asserted by the platform drift job
   and by the denial suite.
4. **`cloud-platform` is in neither client.** With Super Admin behind the
   account, a `cloud-platform` token is a path into the GCP organisation. CI reads both consent
   screens and fails on it; the SIEM's token-stream rule pages on any authorisation of `walle@`
   from a third client id ([../agentic-platform/02-landing-zone-and-tiers.md](../agentic-platform/02-landing-zone-and-tiers.md) PSA3).

## How the robot account gets a credential

**Two clients, one account, one sitting.** The robot authorises each of our
two OAuth clients **once**, interactively, granting offline access. Google returns one
**refresh token** per client, each the platform's permanent proof that the robot consented to
that client's scopes. Each goes into its own secret and mints short-lived access tokens
thereafter, read by one service only.

```mermaid
sequenceDiagram
    participant G as Human super admin, key from the safe (once only)
    participant B as Clean browser profile
    participant O as Google OAuth
    participant S as Secret Manager (WALLE_PROJECT)
    participant CR as walle-actions (narrow)
    participant CRS as walle-actions-super (broad)
    participant W as Workspace APIs

    rect rgb(240,240,240)
    note over G,S: BOOTSTRAP — one witnessed sitting, both clients, ~30 minutes
    G->>B: sign in as walle@domain (hardware key; custody record opened)
    B->>O: authorization request, client 1 (narrow scopes, access_type=offline, prompt=consent)
    O->>B: consent screen listing the narrow scope set
    B->>O: approve
    B->>S: exchange code, store as walle-refresh-token (new version)
    B->>O: authorization request, client 2 (broad scopes, access_type=offline, prompt=consent)
    O->>B: consent screen listing the broad scope set
    B->>O: approve
    B->>S: exchange code, store as walle-super-refresh-token (new version)
    G->>B: sign out; key back in the safe; custody record closed
    end

    rect rgb(250,250,250)
    note over CR,W: RUNTIME — band A
    CR->>S: read walle-refresh-token (pinned version)
    CR->>O: refresh_token -> access_token (1 h)
    CR->>W: API call as walle@domain, narrow scopes only
    end

    rect rgb(250,250,250)
    note over CRS,W: RUNTIME — band B, after the two-person approval
    CRS->>S: read walle-super-refresh-token (pinned version)
    CRS->>O: refresh_token -> access_token (1 h)
    CRS->>W: API call as walle@domain, broad scopes
    end
```

### The one unavoidable human interaction

Exactly one interactive sign-in is unavoidable: the consent sitting that produces the refresh
tokens. There is no way to obtain user credentials for an account without that account
consenting, and the alternatives are the thing being avoided. Practical shape, for a super-admin
account:

1. Set a long random password on `walle@<domain>`, stored in the corporate vault under a
   custodian who does not hold either hardware key.
2. A human super admin takes key A from the safe under a witnessed custody record (key A:
   platform owner; key B: the second human; records copied to the witness bucket the same day —
   [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §8.3).
3. Sign in **in a clean browser profile**, not your own session, and consent both clients in the
   same sitting.
4. Lock the account down immediately afterwards (§"The account hygiene set") and never sign in
   again. The login-alert rule is armed **before** the sitting ends, so the next login pages.

Repeat only on credential rotation or a scope change to client 2. The sign-in itself appears in
the login stream; the witnessed custody record is what makes it an expected event rather than a
severity-1 page.

### What makes the refresh token stop working

Verified against Google's OAuth documentation, and each one is an operational rule. Every row
applies to **both** tokens independently unless stated.

| Cause | Rule it imposes |
|---|---|
| Refresh tokens expire after 7 days | The documented rule applies to **external** user type in Testing. An Internal app is exempt either way — but set Internal **and** In production on both clients, because the cost of being wrong is a dead agent every week. |
| More than 100 live tokens for the client | The oldest is invalidated **silently, with no warning**. The limit is per account per client, so two clients on one account are fine and the limit applies to each separately. One client, one token; never reuse either client for anything else, and never across bootstraps: a re-bootstrap because a scope list was wrong creates a **new** client for that lane. |
| Not used for six months | Each action service refreshes its own token at least monthly even when idle, and alerts on failure. `walle-actions-super` may be idle for months because band B is rare; the monthly refresh is mandatory for it. |
| Password change, when Gmail scopes are granted | Password rotation on the robot **invalidates the narrow token** (it carries Gmail scopes). Re-bootstrap is part of the rotation runbook, not a surprise. A password reset by another super admin has the same effect. By the documented rule the broad token, which carries no Gmail scope, is not invalidated; [SETUP.md](SETUP.md) Phase 3 says a reset invalidates both tokens — unverified until tested on the sandbox tenant. |
| Admin sets a requested service to "Restricted" in API controls | Mark **both** clients **Trusted** in Admin console → API controls, in the same sitting as the consent. Changing either client's trust is on the hard-denied list and a severity-1 detection. |
| GCP session-control length exceeded, for cloud-platform scopes | **Never request the `cloud-platform` scope** for the robot, in either client. It would bind the Workspace credential to your organisation's GCP session policy and, with Super Admin behind it, open a path into the GCP organisation. CI-checked. |
| User revocation | This is the kill switch K5 (§"Kill switches that live in the tenant"). Total, and it costs a re-bootstrap; revoking one grant leaves the other client's token valid. |
| Super Admin removed from the robot (K6) | `Assumption:` the tokens stay valid but every call needing admin privilege returns 403; verified in the sandbox tenant before the grant. The service treats a burst of 403s after a successful refresh as `role_assignment_missing`, a paging class. |

The action services must treat `invalid_grant` as a **paging incident**, never a retryable
error: it means the credential is gone and that lane is dead until a human re-bootstraps. The
rule holds per client: `invalid_grant` on the narrow token stops band A, on the broad token
bands B and C.

## The account hygiene set

Once the refresh tokens exist, the account should be hostile to interactive use. Every row below
is a precondition of the super-admin grant, not a "before S1" item (platform HLD §13.1 item 6);
the robot's OU still carries OU-scoped **settings** even though the **role** cannot be OU-scoped.

| Control | Where | Setting | Verified by |
|---|---|---|---|
| Own OU | `/Automation/Service Identities` (`Assumption:` creatable) | Lets every setting below apply without touching real users; shared with `eve@` | Directory API `users.get` `orgUnitPath` in Eve's roster check |
| 2-step verification | Admin console → Security → 2SV, on the robot OU | Enforced, **"Only security key"**, two keys (A and B) in the safe with named custodians; admin-generated backup codes sealed with the spare key. No "allow codes". **Order matters:** register both keys on the account first, then enforce key-only on the OU — enforcing on an account with no key registered blocks the next sign-in with every fallback already gone. Google's mandatory admin 2SV is a **gradual rollout scoped by edition** (on 2026-09-13: Education, Nonprofits, Cloud Identity, Android Enterprise, and Enterprise editions using third-party SSO, with 90 days' notice to super admins), not a universal rule, so the enforcement here is the tenant's own policy on the OU; if the tenant enters Google's scope, the 30-day web lockout applies to an unenrolled robot as to anyone | Cloud Identity Policy API read in the drift job; Eve reads `isEnrolledIn2Sv` |
| Password | `Assumption:` a corporate password vault exists | Long, random, never in the wiki, custodian ≠ key holder. Changing it breaks the narrow token — see above | vault access log |
| Recovery options | None — no recovery phone or email | Removes a social-engineering path. Google's general advice to add recovery options to admin accounts is deliberately not followed for a machine account: a recovery channel nobody monitors is a takeover channel | Directory API `users.get` recovery fields, daily |
| **Super-admin self-recovery** | Admin console → Account settings, **top organisational unit** | **Off.** The setting is per OU or configuration group, not tenant-wide, and defaults to On for most editions including Enterprise Standard/Plus; set Off at the top OU and drift-check that no child OU or configuration group re-enables it, since a super-admin robot with self-recovery on is a takeover path. Changing it is on the hard-denied list; the per-edition defaults are [platform 04 §8.2](../agentic-platform/04-identity-and-privileged-access.md#82-session-controls-on-the-privileged-tier) | Policy API read daily; admin stream (SIEM severity 1) |
| Less secure app access | Robot OU | Off | Policy API read |
| Login challenges | Admin console → Security, robot OU | The strictest available | Policy API read |
| Session length | Robot OU | The **Admin console session is one hour, fixed by Google** and not a tenant setting. What the OU controls is Google session control for other services (the shortest option offered, "remember this device" off) and **Google Cloud session control** at 1 h, method Security key | Policy API read |
| **Context-Aware Access on the Admin console** | Admin console → Security → Context-Aware Access, assigned to the Admin console for the robot OU | An access level no device satisfies. Graded **detection-plus-friction**: `Assumption:` it applies to a super admin — Google's page on assigning levels to the Admin console says a super admin "can define the context within which other admins can access" the console and is silent on super admins themselves, and the product page says CAA controls access from end-user accounts and is silent on user-account API tokens. There is no Admin SDK API access level. Until P7 is answered with Google it is never recorded as "impossible by policy" | Policy API read; P7 |
| **Gemini Enterprise service** | Admin console → Apps, robot OU | **Off** on `/Automation/Service Identities`; a `StreamAssist` call by `walle@` is severity 1 | Policy API read; SIEM rule ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §7.3) |
| **Workspace multi-party approval** (P66) | Admin console → Security, tenant | **On** for every covered setting, console and API, before the grant; the robot is never an MPA approver and "MPA off" is hard-denied. Covered settings, what MPA does not cover and the `Assumption:` on `users.makeAdmin` are [platform 04 §8.4](../agentic-platform/04-identity-and-privileged-access.md#84-workspace-multi-party-approval-the-two-person-rule-google-enforces) | Policy API read daily; MPA found off is severity 1 (platform 04 §8.4) |
| **Alert on interactive login** | Activity rule + SIEM severity-1 set | **After bootstrap, an interactive login to this account is by definition an incident.** Highest-value control in this table, and the one control that survives Super Admin unchanged: no browser or computer-use automation of the Admin console under the robot's session, ever | login stream; witness channels |
| **Alert on the robot acting on another admin** | Activity rule + SIEM | Any admin event whose actor is `walle@` and whose target is another admin account; any change by `walle@` to another admin's security settings, backup codes or recovery options (these are hard-denied, so a hit means the credential acted outside the service) | admin stream (SIEM SA-02) |
| **Role assignment drift, both directions** | Eve's roster check + SIEM | `role_assignment_missing` (someone removed Super Admin from the robot, or K6 was pulled unannounced) and `role_assignment_added` (a new admin anywhere) are both paging classes | Eve daily; SIEM SA-06 |

**There is no recovery path that preserves the credential.** No recovery email, no recovery
phone, no code fallback, no self-recovery; a password reset invalidates the narrow token (see
§"What makes the refresh token stop working"). If both keys in the safe are lost after the consent
sitting, Wall-E is down until a human super admin re-runs the sitting in full. That is why two keys
are registered, why they have different custodians (key A the platform owner, key B the second
human), and why no single person holds both. The step-by-step settings and their console paths
are [SETUP.md](SETUP.md) Phase 3.

## Admin rights: Super Admin, and what that removes

**Reversed 2026-09-13 (P33).** The robot holds **Super Admin**; the old rule "**Never Super Admin.**
A super admin can alter security policy, grant DWD, and escalate" is still true, and now describes
the risk the design accepts rather than a design choice (history in footnote [^old-role]). What
that costs the platform is
[platform HLD "What this reverses and what it costs"](../agentic-platform/01-hld.md#what-this-reverses-and-what-it-costs);
the Workspace privilege facts behind it are §["Workspace privilege facts"](#workspace-privilege-facts).

What Super Admin removes from Wall-E's controls, what replaces each one and its grade — none
silently deleted. This table owns that per-control mapping; the platform-level losses (the gate,
the blast radius, Eve's independence, least privilege, detection's role) are the platform HLD's
table, linked above, and rows here that overlap it state only the Wall-E replacement.

| Removed control | What it was | Replaced by | Grade |
|---|---|---|---|
| The Workspace-side gate | Google refusing any call outside the role or the pilot OU ([platform HLD](../agentic-platform/01-hld.md#what-this-reverses-and-what-it-costs) row "The Workspace-side gate") | The action services alone: the catalogue (band A), Discovery-pinned validation and the two-person rule (band B), the handoff that executes nothing (band C), and the **hard-denied list** in every lane ([03](03-lld.md) §"Operation catalogue", §"The policy engine") | enforcement (code) |
| "The role grows with the ladder" | A privilege was granted only when the stage that needed it opened, so an operation could not run by accident | The ladder per (family, trigger) as before; `SUPER` and `WRITE-generic` rows fixed at chat L3 / others L0 in code; the **narrow client's scope set** as the Google-enforced ceiling for everything unattended; decision 4 re-ratified as the two lists (P29) | enforcement (code) + enforcement (Google, by scope) |
| OU-scoped writes | `scopeType=ORG_UNIT` on the write assignment | The OU allow-list in the policy chain as a hard invariant, enforced **once, in code** — no OU-scoped role exists to back it — and tested by the denial suite; Eve's minute-latency reconciliation of every robot-attributed event against `walle_audit` | enforcement (code) + detection |
| Protected principals partly out of reach by privilege | The role could not touch other admins or its own assignment | The protected-self rule: the robot is on the committed **floor list** of protected principals, the computed protected set must be a superset of that list or every directory write is denied `protection_incomplete`, and the robot is a protected principal under its own N7 rule ([03](03-lld.md) §"Protected principals"; §"The roster rule" item 4) | enforcement (code) |
| Operator reach bounded by the role | Membership of `walle-operators@` could never exceed what the role allowed | Requester and approver entitlement, since otherwise every operator would hold the robot's whole reach (privilege escalation by proxy). Band A keeps the committed operator list, reconciled daily against `roleAssignments.list`; band B tier `SUPER` makes the live requester check mandatory and fail-closed — a human super admin requests, a **different** human super admin approves, both on the audit row, the approval bound to the canonical request hash (§["How the end user's identity reaches the policy engine"](#how-the-end-users-identity-reaches-the-policy-engine) item 3). No single human can make the robot do super-admin-class work; the per-act two-person table is [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §8.5 | enforcement (code) + organisational |
| Detection confirming what the role refused | Google refused; detection only confirmed (platform HLD row "Detection as a check on enforcement") | **Detection becomes the primary control.** Eve's minute-latency reconciliation: every event attributed to `walle@` in every stream Eve ingests (all six Cloud Logging Workspace streams, plus the Reports API polled by actor) must match a `walle_audit` row or a band-B audit row within five minutes, or it is a `reconciliation_gap`, a halt and a severity-1 page from the witness. The daily super-admin roster check from Eve's own credential (`roleAssignments.list`, `users.list isAdmin`) diffed against the committed roster. The evidence heartbeat, which pages when `admin.googleapis.com` events stop or Eve's token returns `invalid_grant`. The SIEM-hosted severity-1 set owned by IT security and hosted outside `WALLE_PROJECT` ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §7.3). Google writes the log and Wall-E cannot edit it; a super admin can switch off the sharing, which is what the absence alarm is for ([../eve/03-lld.md](../eve/03-lld.md) §14) | detection, minute latency, with absence alarms |
| The credential-leak bound | "Bounded by the role's privileges at the current stage" (platform HLD row "The blast radius") | Custody (one reader per secret, regional, pinned version, hardware keys under witnessed custody), the scope split, and detection latency; the residual, a **tenant compromise** as the platform HLD's blast-radius row states it, is entered in the accepted-risks table under P33 | detection, stated as the primary control |
| Admin-role management "never" | Not in the role, so self-escalation was impossible | `users.makeAdmin`, any `roleAssignments.insert` of Super Admin or of a role carrying admin-role management, and anything targeting the robot, `eve@`, the control groups or the two OAuth clients are **hard-denied** in every lane; multi-party approval (P66) makes role assignment and DWD Google-enforced two-person acts on top | enforcement (code) + enforcement (Google, MPA subset) |
| Security and domain settings "never" | Not in the role | The two lists, signed (P29): the [hard-denied list](03-lld.md#the-hard-denied-list) and the [tier-`SUPER` two-person list](03-lld.md#the-tier-super-two-person-list). Band C (console-only, executed by a human super admin under their own account) for what no API writes; band B at tier `SUPER` for what an API writes; the hard-denied list for other admins' security settings and backup codes, super-admin self-recovery and DWD | enforcement (code) |
| Vault / eDiscovery "never" | Not in the role | Not consented in either client (no `ediscovery` scope); Vault stays out of scope, per §"Rejected alternatives" | enforcement (Google, by scope) |

The separation between suspension and profile editing lives only in `SAFE_USER_FIELDS` and the
ladder levels, and `privileges.list` no longer defines Wall-E's role but still defines Eve's
read-only custom role ([../eve/02-identity-and-auth.md](../eve/02-identity-and-auth.md)); the
privilege facts themselves, with their current status, are
§["Workspace privilege facts"](#workspace-privilege-facts).

### Two role assignments, not one

**Reversed 2026-09-13 (P33).** There is one role — Super Admin, customer-wide by construction — and
no assignment ladder: the customer-scoped read-only role at S0 and the OU-scoped write role at S1
do not exist for Wall-E (history in footnote [^two-assignments]), and the setup script's role
creation and `isAdmin`-must-be-false checks invert (platform HLD §18 item 5). **When Super Admin is
granted:** at the platform's tier gate, never at a runbook phase, and the grant precedes Stage 0 —
before it the robot exists, is licensed and hardened, holds no admin role and reads nothing (no
interim read role is created; the retired `Wall-E — Reader` stays retired), nothing in band B or C
can run, and Eve's observe-and-report layer is the only watcher. The checklist the gate reads is
[platform 11 §6.3](../agentic-platform/11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads),
and the same order is in [05 §7](05-autonomy-ladder.md#7-the-six-stages), [SETUP.md](SETUP.md)
Phase 2 and [ARCHITECTURE.md](ARCHITECTURE.md) §0.

### The roster rule

With the robot counting as one account, the steady-state roster is **exactly three** super admins:
`sa-1-admin@` (platform owner), `sa-2-admin@` (outside the Wall-E administration line) and `walle@`,
which is **never the only or a recovery** super admin and whose own recovery is a human super admin
re-running the consent sitting with a key from the safe; `eve@` is on the committed roster as a
non-admin. Eve's daily roster check and the SIEM's SA-06 page in both directions on any change, a
third human super admin exists only as a dated hand-over exception, and the robot is on the
committed floor list of protected principals and protected under its own N7 rule
([03](03-lld.md#protected-principals)). The table and the rules are
[platform 04 §8.1](../agentic-platform/04-identity-and-privileged-access.md#81-the-roster)
(decision **P68**).

### Kill switches that live in the tenant

K4 (each action service revokes its own refresh token at Google, pulled on both `walle-actions`
and `walle-actions-super`), K5 (a human super admin revokes both clients' grants or suspends
`walle@`) and K6 (a human super admin removes Super Admin with `users.makeAdmin` `status: false`)
act on the tenant account; K6 is the switch that survives a token already minted, K5 and K6 stay
human on a two-person rota paged from the witness, and both are drilled quarterly in the sandbox
tenant. For a suspected credential or account compromise the order is **K0 `halt_all` → K4 on both
services → K7 (P-SA folder) → K5 → K6**, K4 before K7 because KF-1 makes the K4 endpoints
unreachable ([platform 04 §9.7](../agentic-platform/04-identity-and-privileged-access.md#97-how-k7-sits-with-each-agents-k0k6)).
Mechanisms, who pulls, target times and what each switch does not stop are
[ARCHITECTURE.md §4.6](ARCHITECTURE.md#46-kill-switches).

## OAuth client configuration

**Two clients, identical configuration, different scopes and readers.**
Decision 18 (split the control plane) lands now because the scope split needs two readers.

| Item | Client 1 — narrow (`walle-actions`) | Client 2 — broad (`walle-actions-super`) | Why |
|---|---|---|---|
| Home | `WALLE_PROJECT` | `WALLE_PROJECT` | Disabling a client is a P16 spike question, not a switch this page relies on |
| Consent screen user type | **Internal** | **Internal** | Critical. External apps in Testing expire refresh tokens after 7 days. |
| Publishing status | **In production** | **In production** | Same reason. |
| Client type | Desktop app | Desktop app | Simplest loopback flow for the one-time consent |
| API controls | Mark the client ID **Trusted** in Security → API controls → App access control | same | Stops a future org-wide scope restriction from silently killing Wall-E. Trust changes on either client are hard-denied and severity 1 |
| Scopes | §"Scopes" list 1 | §"Scopes" list 2 | The narrow list is the only Google-enforced ceiling on anything unattended |
| `cloud-platform` | never | never | CI reads both consent screens |
| Readers of the client secret and token | `walle-actions@` only | `walle-actions-super@` only | One reader each |
| Secrets (§"Where each secret lives") | `walle-oauth-client`, `walle-refresh-token` | `walle-super-oauth-client`, `walle-super-refresh-token` | Names fixed here; [SETUP.md](SETUP.md) Phase 9 uses them |
| App name on the consent screen | the name from D1 ([PREREQUISITES.md](PREREQUISITES.md)) | the name from D1 | Shown to the robot on the consent screen and awkward to change afterwards |
| Reuse | never; a new bootstrap after a wrong scope list gets a new client | same | The 100-token limit applies per client |

### Scopes

**Scopes are frozen at consent time.** Adding one later means re-running the bootstrap for that
client: an interactive sign-in to the robot, a new refresh token, a new secret version and a
changed pinned version number (a deploy), the trusted-client step again if a new client was
needed, and a change record explaining why the list was wrong. Each consented set is the true
maximum reach of that token if it leaks. [Decision 3](09-open-decisions.md) is **reopened 2026-09-13** (platform HLD §13.1 item 3):
it now decides two lists, and the broad list is itself a super-admin-signed decision. Adding a
scope later is a re-consent of **client 2 only**; client 1's list does not grow for band B.

**List 1 — narrow, client 1, `walle-actions`.** Unchanged from 2026-09-08 and still the proposal
for decision 3's first half:

```
https://www.googleapis.com/auth/admin.directory.user
https://www.googleapis.com/auth/admin.directory.group
https://www.googleapis.com/auth/admin.directory.orgunit.readonly
https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly
https://www.googleapis.com/auth/admin.reports.audit.readonly
https://www.googleapis.com/auth/admin.reports.usage.readonly
https://www.googleapis.com/auth/apps.licensing
https://www.googleapis.com/auth/gmail.readonly
https://www.googleapis.com/auth/gmail.labels
https://www.googleapis.com/auth/gmail.send
https://www.googleapis.com/auth/chat.messages
https://www.googleapis.com/auth/calendar.events
https://www.googleapis.com/auth/userinfo.email
openid
```

What each list-1 scope serves. Any scope with no catalogue operation against it is removed before
consent.

| Scope | Catalogue operations that require it |
|---|---|
| `admin.directory.user` | `directory.user.get`, `directory.user.list`, `directory.user.update`, `directory.user.suspend`, `directory.user.move_ou` |
| `admin.directory.group` | `directory.group.list`, `directory.group.members.list`, `directory.group.member.add`, `directory.group.member.remove` |
| `admin.directory.orgunit.readonly` | `directory.orgunit.list`, and the organisational-unit scope check |
| `admin.directory.rolemanagement.readonly` | `directory.admins.list`, the protected-principal set, and the group-classification job |
| `admin.reports.audit.readonly` | `reports.activities.list` for admin, login, group, token and SAML events |
| `admin.reports.usage.readonly` | `reports.usage.users`, which is `accounts:last_login_time` and therefore every inactivity report |
| `apps.licensing` | `licensing.assignments.list`, `licensing.assignment.delete`, `.insert`, `.patch` |
| `gmail.readonly` | `gmail.list`, `gmail.get` on the robot's own mailbox, which is the T3 inbox trigger |
| `gmail.labels` | `gmail.label` on the robot's own mailbox, family F9 |
| `gmail.send` | `gmail.send`, family F2b, and `notify.operators` when the notification is mail |
| `chat.messages` | `chat.message.send`, family F2b, and `notify.operators` when the notification is Chat |
| `calendar.events` | `calendar.event.create`, `calendar.events.list` on the robot's own calendar |
| `userinfo.email`, `openid` | None. Bootstrap only: the script verifies that the consenting account really is the robot |

Notes on list 1:

- `admin.directory.rolemanagement.readonly` is **required, not optional**: without it the
  service cannot learn which groups carry an admin role, and the group-classification
  control that stops privilege escalation has nothing to read.
- `userinfo.email` and `openid` are needed by the bootstrap script to verify that the
  consenting account really is the robot, and to refuse to store the token otherwise. Without
  them the most likely bootstrap failure, consenting as yourself, is undetectable.
- The list deliberately leaves out `gmail.modify` (full mailbox write), `calendar` (full,
  including calendar management) and `chat.spaces` (space administration), because the catalogue
  needs none of them: it reads the robot's own mail,
  labels it and sends, creates and lists events on the robot's own calendar, and sends Chat
  messages.
- Check the list against the operations the **whole ladder** will ever need, not just Stage 0:
  Stage 0 is read-only and would happily consent to a list that cannot reach Stage 4.
- `admin.directory.user` carries `users.makeAdmin` ("Makes a user a
  super administrator", verified). With a custom role that call was refused by Google; with Super
  Admin behind the account, the narrow token **can** mint super admins, and only the hard-denied
  list stops it. The scope stays because band A's user operations need it (the live `users.get isAdmin`
  requester check for tier `SUPER` runs on the broad client, which carries the same scope); the control is the hard-denied list, the MPA subset and SIEM SA-02.
- `drive` is **not** requested. Without DWD the robot can only see its own Drive, so the
  scope buys nothing and widens the blast radius of a token leak.
- `admin.directory.user.security` (sign-out, token revocation) is **not** in list 1. It moves to
  list 2, where every use is a two-person band-B request.
- Err wide on read scopes, narrow on write scopes. A read scope you did not need costs
  nothing; a write scope you did not need is standing risk. With Super Admin behind the account, "costs nothing" is no longer quite true for reads either — a read
  scope widens what a leaked token discloses tenant-wide — so list 1 stays as it is and grows only
  by decision.

**List 2 — broad, client 2, `walle-actions-super`. Proposal, *tbd* until decision 3 is signed.**
Every scope string below was checked against Google's OAuth scope reference on 2026-09-13
(Sources). The list is what band B's committed method table needs, not "everything". At build it
is held in the service config key `SUPER_SCOPES` and signed as `SUPER_SCOPES_DECISION`:

```
https://www.googleapis.com/auth/admin.directory.user
https://www.googleapis.com/auth/admin.directory.user.security
https://www.googleapis.com/auth/admin.directory.group
https://www.googleapis.com/auth/admin.directory.orgunit
https://www.googleapis.com/auth/admin.directory.rolemanagement
https://www.googleapis.com/auth/admin.directory.domain
https://www.googleapis.com/auth/admin.directory.customer
https://www.googleapis.com/auth/admin.datatransfer
https://www.googleapis.com/auth/apps.licensing
https://www.googleapis.com/auth/apps.groups.settings
https://www.googleapis.com/auth/chrome.management.policy
https://www.googleapis.com/auth/cloud-identity.policies.readonly
https://www.googleapis.com/auth/admin.reports.audit.readonly
https://www.googleapis.com/auth/userinfo.email
openid
```

Notes on list 2:

- `admin.reports.audit.readonly` is here for band C's handoff watch on `reports.activities.list`
  and for band B's verify-by-re-read of events; `cloud-identity.policies.readonly` for band C's
  "is it done" read of settings no API writes. `cloud-identity.policies` (write) is **not**
  requested: it mutates only DLP rules, DLP detectors and one v1beta1 provisioning setting, none of
  which is in the band-B method table on 2026-09-13.
- `admin.directory.rolemanagement` (write) and `admin.directory.user.security` exist here only for
  band-B `SUPER` requests below Super Admin (admin-role create or assign) and for token revocation
  on non-protected users; every target in the hard-denied list is refused before the call.
- **Not requested, in either list:** `cloud-platform`; `drive`; `ediscovery` (Vault); any Gmail,
  Chat or Calendar scope in list 2 (band B is administration, not messaging); any scope granting
  DWD management (none exists — DWD is console-only, and band C refuses it).
- `Assumption:` Google's scope reference lists `apps.groups.settings` on the Groups Settings API
  method pages rather than on the consolidated scopes page read on 2026-09-13; confirmed at
  build by reading the consent screen.

Gmail scopes are "restricted" in Google's classification. For an **Internal** app this
needs no Google verification, but your tenant's own API controls may block it until the
client is marked trusted.

## How the end user's identity reaches the policy engine

Verified: Gemini Enterprise calls the agent with `user_id` set to the signed-in user's
email address, which surfaces in ADK as the session user id. The agent passes it to the
action service as `principal.id`.

**That email is asserted, not proven.** It is trustworthy exactly to the extent that only
trusted callers can invoke the agent. So:

1. Grant `aiplatform.reasoningEngines.query` on Wall-E's engine to **two principals
   only** — the Discovery Engine service agent of `GEMINI_PROJECT` (the **app** project's number,
   never Wall-E's) and `walle-dispatcher@WALLE_PROJECT` — through the custom role
   `walleEngineQuery` bound on the engine, with decision 42's project-level fallback. Nothing
   else, ever; the lock is [12 §7](12-agent-identity.md#7-locking-aiplatformreasoningenginesquery).
2. The action service **re-checks** the asserted email against `walle-operators@` through
   the Directory API on every write, failing closed if it cannot check.
3. **The requester rule for band B** (platform HLD §13.1 item 4; closes decision 28 for this
   lane). Tier `WRITE`: a requester in `walle-operators@`, re-checked live, and one approver. Tier
   `SUPER`: a live, fail-closed check that the requester is a human super admin, run on
   `walle-actions-super`'s own credential, read-only, and a **different** human super admin
   approving on the `walle-approvals-super` IAP surface, with the approval bound to the canonical
   request hash, a change-ticket reference and a `hold_minutes` window; band A is unchanged, and a
   requester equal to `walle@` is `escalation_denied`
   ([03 §"Band B"](03-lld.md#band-b--the-generic-lane-discovery-pinned)).
4. Optional hardening for the highest-risk approvals: configure a Gemini Enterprise
   Authorization with the `userinfo.email` scope so the agent receives a real user access
   token, and have the action service verify it and bind the approval to the **verified**
   email. Wall-E must never receive a user token carrying Workspace *write* scopes — that
   would break the "acts only as the robot" guarantee. For band B the approval is bound to the
   IAP-asserted identity of the approver, which is verified by construction.

For autonomous runs there is no human, so `principal.type` is `scheduler`, `event` or
`inbox`, with `on_behalf_of` naming the playbook's owning human. A machine principal is
never a member of the operators group and is authorised only by the ladder level for its
trigger class. A machine principal can never reach `walle-actions-super`
(no invoker binding, and the lane accepts `principal.type == human` on trigger `chat` only), so no
autonomous run ever holds the broad credential.

## Where each secret lives

Values are never recorded here.

| Secret | Purpose | Readable by |
|---|---|---|
| `walle-oauth-client` | Client 1 (narrow) id and secret | `walle-actions@`, and the bootstrap operator once |
| `walle-refresh-token` | The robot's narrow credential | `walle-actions@` only |
| `walle-super-oauth-client` | Client 2 (broad) id and secret | `walle-actions-super@`, and the bootstrap operator once |
| `walle-super-refresh-token` | The robot's broad credential | `walle-actions-super@` only |
| `walle-confirm-hmac` | Signs `walle-actions`' own approval requests | `walle-actions@` only |

Five secrets, all in `WALLE_PROJECT`. Band-B approvals are bound to the
canonical request hash on the IAP surface and need no shared secret; if `walle-actions-super`
needs its own confirmation key at build, it is a sixth secret with one reader, never a second
reader on `walle-confirm-hmac`. Eve's signing key is **not a secret and not here**:
it is the Cloud KMS key `eve-approval` in `EVE_PROJECT`, and Eve's own secrets
(`eve-oauth-client`, `eve-refresh-token`) live in `EVE_PROJECT`'s Secret Manager —
[../eve/02-identity-and-auth.md](../eve/02-identity-and-auth.md). Wall-E holds only Eve's
public key, as a pinned PEM in its repository.

Create these as **regional secrets** (`projects/*/locations/europe-west1/secrets/*`, via
the regional endpoint), not global secrets with user-managed replication. Regional secrets
keep the data in the location at rest, in use and in transit; user-managed replication
pins only the payload at rest while the secret itself stays a global resource. Automatic
replication stores payloads worldwide and plainly contradicts the residency requirement.

**Pin the version number.** Each service reads `.../versions/7`, never `.../versions/latest`.
`latest` resolves to the newest *enabled* version, so disabling the newest silently falls
back to the previous, still-valid token and the credential kill switch does nothing.
Rotation is an explicit config change and a deploy.

Every `AccessSecretVersion` on the four credential secrets is a Data Access log entry; an access
by any principal other than the one named reader is severity 1 (platform deny policy R1's
exception principal is exactly that reader, [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §3).

## Rotation

| What | When | How |
|---|---|---|
| Refresh tokens (both) | Yearly, and immediately on any suspicion | Re-run the bootstrap sitting for the affected client (both, if the account is suspect), add a new secret version, disable the old — disable, never destroy. Note the narrow token also rotates involuntarily whenever the robot's password changes. |
| Broad token on a scope change | Whenever decision 3's list 2 changes | Re-consent client 2 only, in a witnessed sitting; the new scope set is a signed decision; CI re-reads the consent screen |
| HMAC keys | Yearly, independently of each other | Add a new version; the service accepts both for one overlap window, then the old is disabled. |
| Robot password | Yearly | **Breaks the narrow refresh token.** Always pair with a re-bootstrap in the same maintenance window. |
| Hardware keys | Re-enrolled annually; immediately if an envelope is found opened or a custodian changes | Witnessed; custody record in the witness bucket the same day |
| Roster review | Quarterly, with the platform privilege review | The security reviewer re-signs the committed roster file; Eve's daily check diffs against it |
| Eve's public key PEM | Whenever Eve rotates `eve-approval` in `EVE_PROJECT` | Eve's rotation is Eve's runbook; Wall-E's side is a commit of the new versioned PEM under `contracts/eve-public-keys/`, with the old version kept until its approvals have expired. No cross-project grant changes. |

## Rejected alternatives

| Alternative | Why not |
|---|---|
| Service account + domain-wide delegation | Excluded by requirement, and rightly: tenant-wide impersonation scoped only by OAuth scopes. Also on the hard-denied list: a super admin *can* grant DWD in the console, so granting it is refused in every lane and any DWD change is severity 1. |
| Private Workspace Marketplace app | Installs domain-wide and uses DWD underneath. Same objection. |
| Alert Center API as an event source | Google's documentation requires a service account with DWD. Dropped; Workspace audit-log sharing to Cloud Logging replaces it with no credential at all. |
| Vault API for retention or export | Reachable with the robot's user token if licensed, but that grants read access to all retained content in the tenant. Not worth it. Separate identity and separate ladder if ever needed. Super Admin does not change this; `ediscovery` is in neither scope list. |
| Gemini Enterprise "Authorizations" as the acting identity | Acts as the *requesting* user, so every operator's own privileges become the ceiling and every action is attributed to them. Wrong identity for admin operations. Useful only for the identity-binding hardening above. |
| Chat app identity | Works for Chat only, no path to Admin SDK. A possible second front door later, not a substitute. |
| A service account holding the admin role, no DWD (decision 26; [14](14-hld-challenge.md) C3, "pending") | **Closed for Wall-E by fact, 2026-09-13**: a service account can hold any Workspace admin role except Super Admin, and the objective requires Super Admin. The row's only remaining use is Eve's read-only role (E-16), where it would remove Eve's password, key and consent. |
| One OAuth client carrying every scope | Rejected: the narrow client is the only Google-enforced ceiling left on unattended work; one client in one process would make it decorative (platform HLD §13.1 item 3). |
| Generic Admin SDK proxy ([14](14-hld-challenge.md) C35, "rejected") | **Re-argued 2026-09-13 as band B** ([03 §"Band B"](03-lld.md#band-b--the-generic-lane-discovery-pinned)): C35 rejected it because the lane loses the inverse, the pre-state predicate and the taint declaration. True, and the lane needs none of them because it is permanently L3, chat only, two-person at `SUPER`, Discovery-validated, and never in a playbook. |
| Browser or computer-use automation of the Admin console under the robot's session | Rejected permanently: it would turn "an interactive login is an incident" — the one control that survives Super Admin — into a routine. Band C hands console work to a human super admin instead. |
| A machine that can suspend or demote `walle@` in the tenant | Not built now: one more credential for one administrator to guard. P16 keeps the door open (spikes on client disable and on whether a delegated admin can suspend a super admin, `Assumption:` it cannot). K5 and K6 stay human. |
| Agent Identity (SPIFFE) instead of `walle-agent@` | **Not rejected — deferred, and probably wrong to defer.** It went generally available on 2026-04-22, with the auth manager and its APIs GA on 2026-08-22 and VPC Service Controls integration on 2026-08-14. It is supported on Agent Runtime and Cloud Run, identities appear in IAM policies as `principal://…`, and credentials are auto-rotated 24-hour X.509 certificates over mTLS rather than a long-lived service-account identity. That is strictly better than what this design uses for boundary 2. Adopt it, at engine creation, per [12-agent-identity.md](12-agent-identity.md). The launch stage is settled; the one undocumented fact, whether the agent can present a Google-signed ID token that Cloud Run IAM accepts, is a one-day spike with `walle-agent@` as the fallback. **The platform mandates it** (platform HLD §4.1; the Cloud Run form is Preview, P5). |

## Sources

Read 2026-09-13. The full source list is
[../agentic-platform/00-objective-review.md](../agentic-platform/00-objective-review.md) §8; the
identity facts are cited in full in
[../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §15.

- https://knowledge.workspace.google.com/admin/users/assign-specific-admin-roles — any prebuilt or custom role except Super Admin may be assigned to a service account
- https://knowledge.workspace.google.com/admin/users/administrator-privilege-definitions — privileges that cannot be OU-limited; super-admin-only tasks
- https://developers.google.com/workspace/admin/directory/reference/rest/v1/users/makeAdmin — "Makes a user a super administrator"; body field `status` (boolean); scope `admin.directory.user`; page updated 2026-03-10
- https://developers.google.com/identity/protocols/oauth2/scopes — the scope strings of lists 1 and 2 (Admin SDK Directory, Data Transfer, Reports; Cloud Identity; Chrome Policy; Enterprise License Manager)
- https://developers.google.com/workspace/admin/groups-settings/v1/reference/groups/update — scope `apps.groups.settings`; page updated 2026-03-04
- https://developers.google.com/identity/protocols/oauth2 — 100 refresh tokens per account per client; six-month expiry; password change with Gmail scopes
- https://knowledge.workspace.google.com/admin/security/about-2sv-enforcement-for-admins — gradual, edition-scoped admin 2SV enforcement; notice periods; lockouts
- https://knowledge.workspace.google.com/admin/users/allow-super-administrators-to-recover-their-password — per OU or configuration group; defaults per edition
- https://knowledge.workspace.google.com/admin/security/set-session-length-for-google-services — the Admin console session is one hour and cannot be modified
- https://knowledge.workspace.google.com/admin/security/assign-context-aware-access-levels-to-the-admin-console — a super admin "can define the context within which other admins can access" the console; silent on super admins themselves; updated 2026-09-10
- https://knowledge.workspace.google.com/admin/security/multi-party-approval-for-sensitive-actions — covered settings incl. role assignment (console and API) and DWD
- https://knowledge.workspace.google.com/admin/apps/control-api-access-with-domain-wide-delegation — DWD authorisation is Admin console only
- https://docs.cloud.google.com/identity/docs/concepts/supported-policy-api-settings — Policy API mutates DLP rules, DLP detectors and (v1beta1) conflicting-accounts provisioning only

### Workspace privilege facts

Verified 2026-09-07/08 for the custom role Wall-E no longer holds, re-read against Google's
[administrator privilege definitions](https://knowledge.workspace.google.com/admin/users/administrator-privilege-definitions)
on 2026-09-13. Moot for Wall-E as Super Admin; still relevant to Eve's read-only custom role and
to any delegated admin role on the platform.

| Fact | Status | What it means now |
|---|---|---|
| Suspension has no standalone privilege; it is a sub-action of *Users → Update*, beside rename, move, password reset and aliases | **Stale.** Google's page now lists *Suspend users* among the Update sub-permissions that can be individually delegated | For Wall-E the separation was and remains `SAFE_USER_FIELDS` and the ladder levels, now as hard invariants in the policy chain |
| *License Management* is one indivisible privilege with no read-only half | Holds | Super Admin holds it; the narrow client's `apps.licensing` scope and the catalogue bound its use. For Eve's read-only role it decides its scope list (PREREQUISITES D2b) |
| Groups, Reports, Security settings, Domain settings, Billing, Data Transfer and Support privileges cannot be OU-scoped | Holds | Super Admin is tenant-wide by construction; group-management privileges not honouring OU scope is why group classification is its own control |
| An OU-scoped read of `directory.admins.list` returns only the admins inside that unit, often none, and an empty result reads as success | Holds | The reason the floor-list assertion exists and the reason Eve's role is customer-scoped |

[^old-role]: **History, as written until 2026-09-13.** "**Never Super Admin.** A super admin can
    alter security policy, grant DWD, and escalate. The difference between a custom role and Super
    Admin is the difference between a contained incident and a breach." The custom role
    `Wall-E — Workspace Operator` grew with the ladder: S0 Users → Read, Groups → Read,
    Organisational units → Read, Reports → Audit read and Usage read, Admin roles → Read; S1
    Groups → Update (members), Users → Update (indivisible), License Management (indivisible);
    **never** Users → Create / Delete (deletion irreversible after 20 days), Security settings and
    domain settings, Admin role management (assign), Vault / eDiscovery. Two privileges could not be
    sliced: there is no standalone suspend privilege (suspension is a sub-action of Users →
    Update — since superseded: Google's privilege definitions now list *Suspend users* among the
    individually delegable Update sub-permissions, §"Workspace privilege facts"), and License
    Management is a single undivided privilege with no read-only half, so a "licence read at S0"
    would have granted assign and revoke. The enumeration rule
    was: use `privileges.list`; Google publishes no complete catalogue.

[^two-assignments]: **History, as written until 2026-09-13.** `roleAssignments` support
    `scopeType=ORG_UNIT`, so Workspace itself could refuse an operation outside the pilot scope — a
    second enforcement point outside our own code. A single OU-scoped assignment did not work,
    because (1) several privileges cannot be OU-scoped at all — Groups, Reports, Security settings,
    Domain settings, Billing, Data Transfer and Support are customer-scoped only — and (2) Stage 0's
    value is tenant-wide reads, including `directory.admins.list` for the protected-principal cache.
    So the design used a customer-scoped read-only role at S0 and a separate OU-scoped write role
    at S1; group-management privileges do not honour OU scope, which is why group classification
    exists as its own control. The facts remain true for custom roles and for Eve; they do not
    apply to Super Admin.
