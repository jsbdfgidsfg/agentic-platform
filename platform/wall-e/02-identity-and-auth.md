# 2. Identity & authorisation

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- **Objective restated 2026-09-13; see the platform HLD**
  ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §13.1 and §18 item 1). This page
  is rewritten around a **super-admin user account**: two OAuth clients on that one account, read by
  two services (`walle-actions` narrow, `walle-actions-super` broad), the account hygiene set, K6,
  and the roster rule. What the objective overturns is marked "Reversed 2026-09-13" where it
  stands; the text it replaces is kept as history where the wiki rules ask for it. Decision 26 is
  **closed for Wall-E by fact** (a service account cannot hold Super Admin) and stays open for Eve
  as E-16. The decision of record is platform register row **P33**, file
  `decisions/2026-09-13-wall-e-holds-super-admin.md` (to be written by the owner; qualified
  2026-09-13: written, status accepted, the TISAX deviation not yet signed —
  [../../decisions/2026-09-13-wall-e-holds-super-admin.md](../../decisions/2026-09-13-wall-e-holds-super-admin.md)).
- Placement updated on 2026-09-13 to the four-project topology. Home projects are now
  explicit on every principal; [../project-topology.md](../project-topology.md) is the
  authority for every grant that crosses a project. The platform's identity page
  [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md)
  owns the roster (§8.1), session facts (§8.2), key custodians (§8.3), multi-party approval (§8.4)
  and the K-switch order (§9.7); this page applies them to Wall-E and does not restate their
  sources.
- Unchanged by the objective and kept below: no domain-wide delegation; the language model holds
  no credential and cannot approve; the action service is the only holder of a Workspace
  credential; humans raise, machines lower; Eve's key is not Wall-E's.

This is the core of the design. Read it before anything else.

## The problem, restated

Workspace APIs authorise against a *user*. A GCP service account is not a Workspace user.
The normal bridge is **domain-wide delegation** — the tenant grants a service account the
right to impersonate users. That is excluded, for a good reason: DWD is a tenant-wide
capability scoped only by OAuth scopes, so a compromised service account can act as
*anyone*, including a super admin.

Without DWD a service account cannot become a Workspace user. So we do not try. Wall-E
acts as exactly one identity — the robot account — and can never act as anyone else.

**Added 2026-09-13.** The objective gives that one identity Super Admin. Two Google facts decide
the shape of everything below, and neither is negotiable:

1. "You can assign any prebuilt or custom role except Super Admin to a service account"
   (Google's admin-role assignment page, Sources). The super-admin identity is therefore a
   **licensed user account**, and decision 26's keyless-service-account path is closed for
   Wall-E by fact.
2. Super Admin **cannot be limited to an organisational unit or a subset of privileges**. Nothing
   in Workspace narrows what the credential can do. The consented OAuth scope set is the only
   Google-enforced ceiling left, which is why this page splits the credential into two clients.

"Acts as exactly one identity" matters more now, not less: without DWD the super-admin account
still cannot become anyone else, so every action it takes is attributed to `walle@` in Google's own
log — the property Eve's reconciliation depends on.

## Principals, and what each may do

Autonomy means machines now approve things, so who signs matters as much as who acts. The table
had five rows until 2026-09-13; `walle-actions-super@` is the sixth, added by the credential split.

| Principal | Home project | Type | Holds | May do |
|---|---|---|---|---|
| `walle@<domain>` | — (Workspace) | Workspace user, **licensed, Super Admin** (reversed 2026-09-13; was "custom admin role") | Two OAuth refresh tokens, one per client, each in its own regional secret in `WALLE_PROJECT` | Anything a super admin can do through the scopes a client was consented with — Google enforces the scopes, not a role. Everything else is refused by the action services' code (the hard-denied list and the bands, [03](03-lld.md)). The only identity that touches Workspace. Never signs in interactively after bootstrap; never the only or the recovery super admin (§"The roster rule") |
| `walle-actions@WALLE_PROJECT` | `WALLE_PROJECT` | GCP service account | Reads the **narrow** refresh token, its OAuth client and the HMAC key | Runs `walle-actions` (band A, the catalogue, the ladder). The only reader of the narrow credential secrets. Holds **no** principal in `EVE_PROJECT` beyond the carve-outs of decision 48, and none in `MO_PROJECT`. Never reads the broad secrets |
| `walle-actions-super@WALLE_PROJECT` (added 2026-09-13; name follows the one-account-per-duty rule, platform HLD §4.3) | `WALLE_PROJECT` | GCP service account | Reads the **broad** refresh token and its OAuth client, nothing else | Runs `walle-actions-super` (band B `/v1/execute-generic`, band C `/v1/handoff`). The only reader of the broad credential secrets. Never reads the narrow secrets or the HMAC key. No trigger, dispatcher or Mo identity can invoke it |
| `walle-agent@WALLE_PROJECT` | `WALLE_PROJECT` | GCP service account (Agent Identity replaces it at engine creation, [12](12-agent-identity.md)) | Nothing | Runs the Wall-E agent on Agent Runtime. Can call both action services (band A on one, bands B and C on the other). Cannot read any secret |
| `walle-dispatcher@WALLE_PROJECT` | `WALLE_PROJECT` | GCP service account | Nothing | Invokes the agent. Holds `aiplatform.reasoningEngines.query` on Wall-E's engine only (same project). Reads halt flags. Holds **no** invoker on `walle-actions-super`, so no trigger class but a human in chat can originate a band-B request |
| `eve-controller@EVE_PROJECT` | `EVE_PROJECT` | GCP service account | Signs with **Eve's own** Cloud KMS key `eve-approval` in `EVE_PROJECT`, and nothing of Wall-E's | Calls the control endpoints: approve, veto, halt, demote, over `roles/run.invoker` bound **on the `walle-actions` service** in `WALLE_PROJECT`; since 2026-09-13 also `roles/run.invoker` **on `walle-actions-super`**, halt path only — the in-app control list carries no other endpoint for it (platform HLD §18 item 25). Extended 2026-09-13 (review-findings pass): `eve-verifier@EVE_PROJECT` holds the same halt-only grant, because Eve's reconciler limb raises the super-admin-lane halts ([../project-topology.md](../project-topology.md) row 27). Reads audit over dataset-level `roles/bigquery.dataViewer` **on `walle_audit`**, jobs run in `EVE_PROJECT`. Never a project-level role in `WALLE_PROJECT`. Cannot execute an operation |

Eve's other identities — `eve-v0@` (S0), `eve-verifier@` and `eve-console@` (S3) — are
also homed in `EVE_PROJECT`; which of them holds which cross-project binding is
[../project-topology.md](../project-topology.md) §3 rows 3–5. Eve's Workspace account `eve@`
holds a read-only custom role and is **never** Super Admin; the objective requires it
([../eve/02-identity-and-auth.md](../eve/02-identity-and-auth.md)).

Mo has three identities, all in `MO_PROJECT` (designed 2026-09-12,
[../mo/02-identity-and-access.md](../mo/02-identity-and-access.md)): `mo-metrics@` holds
dataset-level `roles/bigquery.dataViewer` on `walle_audit` and `walle_workspace_logs` in
`WALLE_PROJECT`; `mo-analyst@` holds `roles/run.invoker` on `walle-actions` for the two read
endpoints only, and **nothing on `walle-actions-super`**; `mo-narrator@` (S4) touches nothing of
Wall-E's. Nothing of Mo's lives in `WALLE_PROJECT`.

Human principals that matter to this page, since 2026-09-13: the two human super admins'
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
3. **Added 2026-09-13: each credential has exactly one reader.** `walle-actions@` never reads the
   broad secrets; `walle-actions-super@` never reads the narrow ones. If one service could read
   both, the narrow client's scope ceiling would be decorative. Asserted by the platform drift job
   and by the denial suite.
4. **Added 2026-09-13: `cloud-platform` is in neither client.** With Super Admin behind the
   account, a `cloud-platform` token is a path into the GCP organisation. CI reads both consent
   screens and fails on it; the SIEM's token-stream rule pages on any authorisation of `walle@`
   from a third client id ([../agentic-platform/02-landing-zone-and-tiers.md](../agentic-platform/02-landing-zone-and-tiers.md) PSA3).

## How the robot account gets a credential

**Updated 2026-09-13: two clients, one account, one sitting.** The robot authorises each of our
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
consenting, and the alternatives are the thing being avoided. Practical shape, updated
2026-09-13 for a super-admin account:

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
| More than 100 live tokens for the client | The oldest is invalidated **silently, with no warning**. The limit is per account per client, so two clients on one account are fine. One client, one token; never reuse either client for anything else. |
| Not used for six months | Each action service refreshes its own token at least monthly even when idle, and alerts on failure. `walle-actions-super` may be idle for months because band B is rare; the monthly refresh is mandatory for it. |
| Password change, when Gmail scopes are granted | Password rotation on the robot **invalidates the narrow token** (it carries Gmail scopes). Re-bootstrap is part of the rotation runbook, not a surprise. A password reset by another super admin has the same effect. |
| Admin sets a requested service to "Restricted" in API controls | Mark **both** clients **Trusted** in Admin console → API controls, in the same sitting as the consent. Changing either client's trust is on the hard-denied list and a severity-1 detection. |
| GCP session-control length exceeded, for cloud-platform scopes | **Never request the `cloud-platform` scope** for the robot, in either client. It would bind the Workspace credential to your organisation's GCP session policy and, with Super Admin behind it, open a path into the GCP organisation. CI-checked. |
| User revocation | This is the kill switch K5 (§"Kill switches that live in the tenant"). |
| Super Admin removed from the robot (K6, added 2026-09-13) | `Assumption:` the tokens stay valid but every call needing admin privilege returns 403; verified in the sandbox tenant before the grant. The service treats a burst of 403s after a successful refresh as `role_assignment_missing`, a paging class. |

The action services must treat `invalid_grant` as a **paging incident**, not a retryable
error: it means the credential is gone and that lane is dead until a human re-bootstraps.

## The account hygiene set

**Rewritten 2026-09-13** (was "Locking down the robot account", written for a non-admin robot).
Once the refresh tokens exist, the account should be hostile to interactive use. Every row below
is a precondition of the super-admin grant, not a "before S1" item (platform HLD §13.1 item 6);
the robot's OU still carries OU-scoped **settings** even though the **role** cannot be OU-scoped.

| Control | Where | Setting | Verified by |
|---|---|---|---|
| Own OU | `/Automation/Service Identities` (`Assumption:` creatable) | Lets every setting below apply without touching real users; shared with `eve@` | Directory API `users.get` `orgUnitPath` in Eve's roster check |
| 2-step verification | Admin console → Security → 2SV, on the robot OU | Enforced, **"Only security key"**, two keys (A and B) in the safe with named custodians; admin-generated backup codes sealed with the spare key. Corrected 2026-09-13: Google's mandatory admin 2SV is a **gradual rollout scoped by edition** (on 2026-09-13: Education, Nonprofits, Cloud Identity, Android Enterprise, and Enterprise editions using third-party SSO, with 90 days' notice to super admins), not a universal rule, so the enforcement here is the tenant's own policy on the OU; if the tenant enters Google's scope, the 30-day web lockout applies to an unenrolled robot as to anyone | Cloud Identity Policy API read in the drift job; Eve reads `isEnrolledIn2Sv` |
| Password | `Assumption:` a corporate password vault exists | Long, random, never in the wiki, custodian ≠ key holder. Changing it breaks the narrow token — see above | vault access log |
| Recovery options | None — no recovery phone or email | Removes a social-engineering path. Google's general advice to add recovery options to admin accounts is deliberately not followed for a machine account: a recovery channel nobody monitors is a takeover channel | Directory API `users.get` recovery fields, daily |
| **Super-admin self-recovery** (added 2026-09-13) | Admin console → Account settings, **top organisational unit** | **Off.** The setting is per OU or configuration group, not tenant-wide, and defaults to On for most editions including Enterprise Standard/Plus; set Off at the top OU and drift-check that no child OU or configuration group re-enables it. Changing it is on the hard-denied list | Policy API read daily; admin stream (SIEM severity 1) |
| Less secure app access | Off | — | Policy API read |
| Session length | Robot OU | Corrected 2026-09-13: the **Admin console session is one hour, fixed by Google** and not a tenant setting. What the OU controls is Google session control for other services (the shortest option offered, "remember this device" off) and **Google Cloud session control** at 1 h, method Security key | Policy API read |
| **Context-Aware Access on the Admin console** (added 2026-09-13) | Admin console → Security → Context-Aware Access, assigned to the Admin console for the robot OU | An access level no device satisfies. Graded **detection-plus-friction**: `Assumption:` it applies to a super admin — Google's page on assigning levels to the Admin console says a super admin "can define the context within which other admins can access" the console and is silent on super admins themselves, and the product page says CAA controls access from end-user accounts and is silent on user-account API tokens. There is no Admin SDK API access level. Until P7 is answered with Google it is never recorded as "impossible by policy" | Policy API read; P7 |
| **Gemini Enterprise service** (added 2026-09-13) | Admin console → Apps, robot OU | **Off** on `/Automation/Service Identities`; a `StreamAssist` call by `walle@` is severity 1 | Policy API read; SIEM rule ([../agentic-platform/01-hld.md](../agentic-platform/01-hld.md) §7.3) |
| **Workspace multi-party approval** (added 2026-09-13, P66) | Admin console → Security, tenant | **On** for every covered setting, console and API, before the grant: role assignment and custom-role privilege updates, DWD, 2SV, session control, login challenges, account recovery, SSO, Context-Aware Access become Google-enforced two-person acts over the robot's credential. The robot is never an MPA approver (an approval event whose actor is `walle@` is severity 1); "MPA off" is hard-denied. `Assumption:` `users.makeAdmin` counts as a role assignment under MPA — verified in the sandbox tenant | Policy API read daily; MPA found off is severity 1 and K0 `no_writes` on `walle-actions-super` |
| **Alert on interactive login** | Activity rule + SIEM severity-1 set | **After bootstrap, an interactive login to this account is by definition an incident.** Highest-value control in this table, and since 2026-09-13 the one control that survives Super Admin unchanged: no browser or computer-use automation of the Admin console under the robot's session, ever | login stream; witness channels |
| **Alert on the robot acting on another admin** (added 2026-09-13) | Activity rule + SIEM | Any admin event whose actor is `walle@` and whose target is another admin account; any change by `walle@` to another admin's security settings, backup codes or recovery options (these are hard-denied, so a hit means the credential acted outside the service) | admin stream (SIEM SA-02) |
| **Role assignment drift, both directions** (added 2026-09-13) | Eve's roster check + SIEM | `role_assignment_missing` (someone removed Super Admin from the robot, or K6 was pulled unannounced) and `role_assignment_added` (a new admin anywhere) are both paging classes | Eve daily; SIEM SA-06 |

## Admin rights: Super Admin, and what that removes

**Reversed 2026-09-13** (platform HLD "What this reverses and what it costs", §13.1; P33). The
robot holds **Super Admin**. The section this replaces was titled "Admin rights: a custom role,
scoped to an OU" and opened "**Never Super Admin.** A super admin can alter security policy,
grant DWD, and escalate." That sentence was true, and still is: it is now the description of the
risk the design accepts, not of a design choice. Its text and the privilege-by-stage table are
kept as history in footnote [^old-role].

What Super Admin removes, and what replaces each removed control — none silently deleted:

| Removed control | What it was | Replaced by | Grade |
|---|---|---|---|
| The Workspace-side gate | Google refusing any call outside the role or the pilot OU — a second enforcement point outside our code | The action services alone: the catalogue (band A), Discovery-pinned validation and the two-person rule (band B), the handoff that executes nothing (band C), and the **hard-denied list** in every lane ([03](03-lld.md) §"Operation catalogue", §"The policy engine") | enforcement (code) |
| "The role grows with the ladder" | A privilege was granted only when the stage that needed it opened, so an operation could not run by accident | The ladder per (family, trigger) as before; `SUPER` and `WRITE-generic` rows fixed at chat L3 / others L0 in code; the **narrow client's scope set** as the Google-enforced ceiling for everything unattended; decision 4 re-ratified as the two lists (P29) | enforcement (code) + enforcement (Google, by scope) |
| OU-scoped writes | `scopeType=ORG_UNIT` on the write assignment | The OU allow-list in the policy chain, now **code only**; Eve's minute-latency reconciliation of every robot-attributed event against `walle_audit` | enforcement (code) + detection |
| The credential-leak bound | "Bounded by the role's privileges at the current stage" | Custody (one reader per secret, regional, pinned version, hardware keys under witnessed custody), the scope split, and detection latency; the residual — a leaked token or an interactive login is a **tenant compromise** with a path into the GCP organisation — entered in the accepted-risks table under P33 | detection, stated as the primary control |
| Admin-role management "never" | Not in the role, so self-escalation was impossible | `users.makeAdmin`, any `roleAssignments.insert` of Super Admin or of a role carrying admin-role management, and anything targeting the robot, `eve@`, the control groups or the two OAuth clients are **hard-denied** in every lane; multi-party approval (P66) makes role assignment and DWD Google-enforced two-person acts on top | enforcement (code) + enforcement (Google, MPA subset) |
| Security and domain settings "never" | Not in the role | Band C (console-only, executed by a human super admin under their own account) for what no API writes; band B at tier `SUPER` for what an API writes; the hard-denied list for other admins' security settings and backup codes, super-admin self-recovery and DWD | enforcement (code) |
| Vault / eDiscovery "never" | Not in the role | Not consented in either client (no `ediscovery` scope); Vault stays out of scope, per §"Rejected alternatives" | enforcement (Google, by scope) |

Two facts this section used to lean on still hold and are kept:

- **Users → Update is indivisible**, and so is suspension from profile editing. Separation between
  them exists only in `SAFE_USER_FIELDS` and the ladder levels — which, since 2026-09-13, is where
  every separation lives.
- **Enumerate the real privilege names with `privileges.list`.** It no longer defines Wall-E's
  role; it still defines Eve's read-only custom role ([../eve/02-identity-and-auth.md](../eve/02-identity-and-auth.md)).

### Two role assignments, not one

**Reversed 2026-09-13.** There is one role — Super Admin, customer-wide by construction — and no
assignment ladder. The design used to hold "a customer-scoped read-only role granted at S0, and a
separate OU-scoped write role granted at S1"; neither assignment exists for Wall-E, and the
setup script's role creation and `isAdmin`-must-be-false checks invert (platform HLD §18 item 5).
The reasoning is kept in footnote [^two-assignments] because two of its facts are still load-bearing
elsewhere: group-management privileges do not honour OU scope (why group classification is its
own control, [06-security-guardrails.md](06-security-guardrails.md)), and `directory.admins.list`
must run customer-wide to feed the protected-principal cache — which a super admin now does by
construction.

**When Super Admin is granted.** Not at a runbook phase: at the platform's tier gate, on the day
every row of the P-SA line is green (platform HLD §0.4) — Eve's observe-and-report layer live and
drilled, the witness organisation, the SIEM with 24x7 acknowledgement, the roster below, MPA on,
the two lists signed, P3's engine-reach spike passed. Until then the robot exists, is licensed and
holds no admin role, and nothing in band B or C can run. **Stated 2026-09-13 (review-findings
pass): the grant precedes Stage 0.** Stage 0's reads need an admin privilege and no interim read
role is created for Wall-E (the retired `Wall-E — Reader` stays retired), so before the grant the
robot reads nothing and no Wall-E run touches the tenant; Eve's observe-and-report layer is the
only watcher. The same order is in [05-autonomy-ladder.md](05-autonomy-ladder.md) §7,
[SETUP.md](SETUP.md) Phase 2 and §6.1, and [ARCHITECTURE.md](ARCHITECTURE.md) §0.

### The roster rule

Added 2026-09-13 from [../agentic-platform/04-identity-and-privileged-access.md](../agentic-platform/04-identity-and-privileged-access.md) §8.1 (decision **P68**). With the robot counting as one account, the steady-state roster of super admins is **exactly three**:

| Account | Kind | Recovery for this account | Pulls |
|---|---|---|---|
| `sa-1-admin@` | human super admin, admin account separate from the daily account, platform owner | `sa-2-admin@` resets it; support-assisted recovery last | K5, K6, MPA approvals, band-B `SUPER` requests |
| `sa-2-admin@` | human super admin **outside the Wall-E administration line** (the second human of platform HLD §13.2) | `sa-1-admin@` resets it | K5, K6, MPA approvals, band-B `SUPER` approvals; sole recipient of reports about the administrator |
| `walle@` | robot, licensed user, Super Admin (P33) | **never** the recovery of anyone; its own recovery is a human super admin re-running the consent sitting with a key from the safe | nothing by hand — its credential is driven by the two action services only |

`eve@` is on the committed roster file as a **non-admin**: a role on it beyond its read-only
custom role is severity 1.

Rules, each owned by the platform owner and verified daily by Eve's roster check
(`roleAssignments.list` and `users.list` `isAdmin` from Eve's own credential, diffed against the
committed roster signed by the security reviewer) and by the SIEM's SA-06:

1. The robot is **never the only** super admin and **never a recovery** super admin; at least two
   human super admins hold the role at all times.
2. A fourth super admin, a role change on any roster account, a new admin-role holder anywhere, or
   a change to any admin's security settings, backup codes or recovery options is severity 1 to
   the second human and the desk in parallel, **in both directions**.
3. A third human super admin exists only as a dated hand-over exception; the roster check fails
   while it exists beyond its date.
4. The robot is on the committed **floor list** of protected principals and is a protected
   principal under its own N7 rule ([03](03-lld.md) §"Protected principals"). It appears in
   `directory.admins.list` because it is a super admin; the floor assertion requires it there.

### Kill switches that live in the tenant

Added 2026-09-13. K0–K3 are Wall-E's GCP-side switches ([ARCHITECTURE.md](ARCHITECTURE.md) §4.6);
K7 is the platform's fleet stop. The switches that act on the account itself are these, with the
containment targets of [../agentic-platform/07-monitoring-detection-incident-response.md](../agentic-platform/07-monitoring-detection-incident-response.md) §9.2:

| Switch | What it does | Who pulls | Time | What it does not stop |
|---|---|---|---|---|
| **K4** kill the credential | Each action service **revokes its own refresh token at Google** on one operator call; since 2026-09-13 there are two, so K4 is pulled on **both** `walle-actions` and `walle-actions-super` | any operator, through the approval page or the operators' caller identity | seconds | an access token already issued, for up to 60 minutes |
| **K5** revoke the grant / suspend the robot | `tokens.delete` for both client ids, or `users.update` `suspended: true` on `walle@` | a human super admin, Admin console, on the two-person rota paged from the witness | ≤ 30 min of a severity-1 acknowledgement (`Assumption:`) | a token already minted, until expiry |
| **K6** remove Super Admin from the robot | `users.makeAdmin` with `status: false` on `walle@` (the method "makes a user a super administrator" and takes a boolean `status`) — **the switch that survives a token already minted**, because the token outlives the privilege | a human super admin, on the same two-person rota; never a machine (P16 keeps the door open, nothing is built) | ≤ 60 min | nothing Workspace-side; GCP-side reach already obtained, if any, is K7's and the incident's |
| **K7** fleet stop | stops compute and invocation in the tier folders; revokes nothing | `platform-approvers@`, the SIEM rule, the K7 job | < 5 min | the credential — which is why K4 comes first |

Order for a suspected credential or account compromise (platform HLD §7.6 tabletop default):
**K0 `halt_all` → K4 on both services → K7 (P-SA folder) → K5 → K6** if the account itself is
suspect → evidence preservation → the incident commander. K4 before K7, because KF-1 makes the K4
endpoints unreachable. K5 and K6 are drilled quarterly (platform HLD §11.2), in the sandbox tenant.

## OAuth client configuration

**Updated 2026-09-13: two clients, identical configuration, different scopes and readers.**
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

### Scopes

**Scopes are frozen at consent time.** Adding one later means re-running the bootstrap for that
client. [Decision 3](09-open-decisions.md) is **reopened 2026-09-13** (platform HLD §13.1 item 3):
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

Notes on list 1:

- `admin.directory.rolemanagement.readonly` is **required, not optional**: without it the
  service cannot learn which groups carry an admin role, and the group-classification
  control that stops privilege escalation has nothing to read. An earlier draft omitted
  it while depending on it.
- `userinfo.email` and `openid` are needed by the bootstrap script to verify that the
  consenting account really is the robot. An earlier draft of the bootstrap script omitted
  them and would have failed on that check.
- The scopes above are **narrower than the first draft**, which asked for `gmail.modify`
  (full mailbox write), `calendar` (full) and `chat.spaces` (space management) while the
  catalogue needs none of them.
- **Qualified 2026-09-13:** `admin.directory.user` carries `users.makeAdmin` ("Makes a user a
  super administrator", verified). With a custom role that call was refused by Google; with Super
  Admin behind the account, the narrow token **can** mint super admins, and only the hard-denied
  list stops it. The scope stays because band A's user operations and the live `users.get isAdmin`
  requester check need it; the control is the hard-denied list, the MPA subset and SIEM SA-02.
- `drive` is **not** requested. Without DWD the robot can only see its own Drive, so the
  scope buys nothing and widens the blast radius of a token leak.
- `admin.directory.user.security` (sign-out, token revocation) is **not** in list 1. It moves to
  list 2, where every use is a two-person band-B request.
- Err wide on read scopes, narrow on write scopes. A read scope you did not need costs
  nothing; a write scope you did not need is standing risk. **Qualified 2026-09-13:** with Super
  Admin behind the account, "costs nothing" is no longer quite true for reads either — a read
  scope widens what a leaked token discloses tenant-wide — so list 1 stays as it is and grows only
  by decision.

**List 2 — broad, client 2, `walle-actions-super`. Proposal, *tbd* until decision 3 is signed.**
Every scope string below was checked against Google's OAuth scope reference on 2026-09-13
(Sources). The list is what band B's committed method table needs, not "everything":

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
   only**: the Gemini Enterprise Discovery Engine service agent of `GEMINI_PROJECT`,
   `service-GEMINI_PROJECT_NUMBER@gcp-sa-discoveryengine.iam.gserviceaccount.com` — the
   **app** project's number, never Wall-E's — through the custom role `walleEngineQuery`
   bound **on the engine** (a resource-level binding to a principal homed in another
   project; whether it suffices cross-project is decision 42's spike, with Google's
   documented project-level `roles/discoveryengine.serviceAgent` on `WALLE_PROJECT` as the
   fallback), and `walle-dispatcher@WALLE_PROJECT`. Nothing else, ever. An earlier draft
   listed `eve-controller@` as a third; [C10](14-hld-challenge.md) removed it, and
   [../project-topology.md](../project-topology.md) §3 row 13 records the absence.
2. The action service **re-checks** the asserted email against `walle-operators@` through
   the Directory API on every write, failing closed if it cannot check.
3. **Added 2026-09-13 — the requester rule for band B** (platform HLD §13.1 item 4; closes
   decision 28 for this lane). Tier `WRITE`: requester a member of `walle-operators@`, re-checked
   live against the committed operator list, one approver. Tier `SUPER`: a **live, fail-closed**
   check that the requester is a human super admin (`users.get` `isAdmin` through the **narrow**
   token), the approver a **different** human super admin on the `walle-approvals-super` IAP
   surface, both recorded on the audit row, the approval bound to the canonical request hash, a
   change-ticket reference and a `hold_minutes` window mandatory. The live super-admin check runs
   for `SUPER` only, never for `WRITE`. Band A is unchanged. The robot itself never satisfies the
   requester check: a requester equal to `walle@` is `escalation_denied`.
4. Optional hardening for the highest-risk approvals: configure a Gemini Enterprise
   Authorization with the `userinfo.email` scope so the agent receives a real user access
   token, and have the action service verify it and bind the approval to the **verified**
   email. Wall-E must never receive a user token carrying Workspace *write* scopes — that
   would break the "acts only as the robot" guarantee. For band B the approval is bound to the
   IAP-asserted identity of the approver, which is verified by construction.

For autonomous runs there is no human, so `principal.type` is `scheduler`, `event` or
`inbox`, with `on_behalf_of` naming the playbook's owning human. A machine principal is
never a member of the operators group and is authorised only by the ladder level for its
trigger class. **Added 2026-09-13:** a machine principal can never reach `walle-actions-super`
(no invoker binding, and the lane accepts `principal.type == human` on trigger `chat` only), so no
autonomous run ever holds the broad credential.

## Where each secret lives

Values are never recorded here.

| Secret | Purpose | Readable by |
|---|---|---|
| `walle-oauth-client` | Client 1 (narrow) id and secret | `walle-actions@`, and the bootstrap operator once |
| `walle-refresh-token` | The robot's narrow credential | `walle-actions@` only |
| `walle-super-oauth-client` (added 2026-09-13) | Client 2 (broad) id and secret | `walle-actions-super@`, and the bootstrap operator once |
| `walle-super-refresh-token` (added 2026-09-13) | The robot's broad credential | `walle-actions-super@` only |
| `walle-confirm-hmac` | Signs `walle-actions`' own approval requests | `walle-actions@` only |

Five secrets, all in `WALLE_PROJECT` (three until 2026-09-13). Band-B approvals are bound to the
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
replication — what an earlier draft's script used — stores payloads worldwide and plainly
contradicts the residency requirement.

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
| Hardware keys (added 2026-09-13) | Re-enrolled annually; immediately if an envelope is found opened or a custodian changes | Witnessed; custody record in the witness bucket the same day |
| Roster review (added 2026-09-13) | Quarterly, with the platform privilege review | The security reviewer re-signs the committed roster file; Eve's daily check diffs against it |
| Eve's public key PEM | Whenever Eve rotates `eve-approval` in `EVE_PROJECT` | Eve's rotation is Eve's runbook; Wall-E's side is a commit of the new versioned PEM under `contracts/eve-public-keys/`, with the old version kept until its approvals have expired. No cross-project grant changes. |

## Rejected alternatives

| Alternative | Why not |
|---|---|
| Service account + domain-wide delegation | Excluded by requirement, and rightly: tenant-wide impersonation scoped only by OAuth scopes. Since 2026-09-13 also on the hard-denied list: a super admin *can* grant DWD in the console, so granting it is refused in every lane and any DWD change is severity 1. |
| Private Workspace Marketplace app | Installs domain-wide and uses DWD underneath. Same objection. |
| Alert Center API as an event source | Google's documentation requires a service account with DWD. Dropped; Workspace audit-log sharing to Cloud Logging replaces it with no credential at all. |
| Vault API for retention or export | Reachable with the robot's user token if licensed, but that grants read access to all retained content in the tenant. Not worth it. Separate identity and separate ladder if ever needed. **Kept 2026-09-13:** Super Admin does not change this; `ediscovery` is in neither scope list. |
| Gemini Enterprise "Authorizations" as the acting identity | Acts as the *requesting* user, so every operator's own privileges become the ceiling and every action is attributed to them. Wrong identity for admin operations. Useful only for the identity-binding hardening above. |
| Chat app identity | Works for Chat only, no path to Admin SDK. A possible second front door later, not a substitute. |
| A service account holding the admin role, no DWD (decision 26; [14](14-hld-challenge.md) C3, "pending") | **Closed for Wall-E by fact, 2026-09-13**: a service account can hold any Workspace admin role except Super Admin, and the objective requires Super Admin. The row's only remaining use is Eve's read-only role (E-16), where it would remove Eve's password, key and consent. |
| One OAuth client carrying every scope (added 2026-09-13) | Rejected: the narrow client is the only Google-enforced ceiling left on unattended work; one client in one process would make it decorative (platform HLD §13.1 item 3). |
| Generic Admin SDK proxy ([14](14-hld-challenge.md) C35, "rejected") | **Re-argued 2026-09-13 as band B** ([03](03-lld.md) §"Band B"): C35 rejected it because the lane loses the inverse, the pre-state predicate and the taint declaration. True, and the lane needs none of them because it is permanently L3, chat only, two-person at `SUPER`, Discovery-validated, and never in a playbook. |
| Browser or computer-use automation of the Admin console under the robot's session (added 2026-09-13) | Rejected permanently: it would turn "an interactive login is an incident" — the one control that survives Super Admin — into a routine. Band C hands console work to a human super admin instead. |
| A machine that can suspend or demote `walle@` in the tenant (added 2026-09-13) | Not built now: one more credential for one administrator to guard. P16 keeps the door open (spikes on client disable and on whether a delegated admin can suspend a super admin, `Assumption:` it cannot). K5 and K6 stay human. |
| Agent Identity (SPIFFE) instead of `walle-agent@` | **Not rejected — deferred, and probably wrong to defer.** It went generally available on 2026-04-22, with the auth manager and its APIs GA on 2026-08-22 and VPC Service Controls integration on 2026-08-14. It is supported on Agent Runtime and Cloud Run, identities appear in IAM policies as `principal://…`, and credentials are auto-rotated 24-hour X.509 certificates over mTLS rather than a long-lived service-account identity. That is strictly better than what this design uses for boundary 2. Adopt it, at engine creation, per [12-agent-identity.md](12-agent-identity.md). The launch stage is settled; the one undocumented fact, whether the agent can present a Google-signed ID token that Cloud Run IAM accepts, is a one-day spike with `walle-agent@` as the fallback. **Since 2026-09-13 the platform mandates it** (platform HLD §4.1; the Cloud Run form is Preview, P5). |

## Sources for the 2026-09-13 rewrite

Read 2026-09-13. The platform lens reports' full list is
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

[^old-role]: **History, as written until 2026-09-13.** "**Never Super Admin.** A super admin can
    alter security policy, grant DWD, and escalate. The difference between a custom role and Super
    Admin is the difference between a contained incident and a breach." The custom role
    `Wall-E — Workspace Operator` grew with the ladder: S0 Users → Read, Groups → Read,
    Organisational units → Read, Reports → Audit read and Usage read, Admin roles → Read; S1
    Groups → Update (members), Users → Update (indivisible), License Management (indivisible);
    **never** Users → Create / Delete (deletion irreversible after 20 days), Security settings and
    domain settings, Admin role management (assign), Vault / eDiscovery. Two privileges could not be
    sliced: there is no standalone suspend privilege (suspension is a sub-action of Users →
    Update; corrected 2026-09-13: Google's privilege definitions list *Suspend users* among the Update sub-permissions that can be individually delegated ([privilege definitions](https://knowledge.workspace.google.com/admin/users/administrator-privilege-definitions)); moot for Wall-E as Super Admin, still relevant to any delegated admin role on the platform.), and License Management is a single undivided privilege with no read-only half, so an
    earlier draft's "licence read at S0" would have granted assign and revoke. The enumeration rule
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
