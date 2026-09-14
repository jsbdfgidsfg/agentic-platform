# Google Workspace

## Status
- Owner: the platform owner (super admin)
- Last reviewed: 2026-09-14
- Maturity: skeleton. The tenant carries a super-admin robot account for Wall-E (register row
  P33), so two tenant facts gate platform controls and are asked below: the **Workspace edition**
  and the **identity provider** (platform HLD
  [agentic-platform/01-hld.md](agentic-platform/01-hld.md) §18 item 26).

## Tenant

| Item | Value |
|---|---|
| Primary domain | *tbd* |
| Edition / licences | *tbd* (see "Questions the platform asks of this tenant" below) |
| Identity provider for Workspace sign-in | *tbd* (see below) |
| Approx. seats | *tbd* |
| Admin console | https://admin.google.com |

## Questions the platform asks of this tenant

Asked by the platform HLD §18 item 26. Each is answered by the platform owner reading the
Admin console; the answer is written into the Tenant table above with the date it was read.

| Question | What the answer gates | Answer | Pages that ask it |
|---|---|---|---|
| Which Workspace edition (and which Gemini Enterprise edition) does the tenant run? | Whether Google's mandatory admin 2-step verification rollout covers the tenant or the OU policy is the only enforcement; eligibility for **multi-party approval** (P66, a gate on the super-admin grant); availability of **Context-Aware Access** and Google session control; which audit events are shared to Google Cloud (OAuth and SAML events, Access Transparency) and so the completeness of Eve's evidence and the SIEM; BigQuery export; whether the Gemini Enterprise assistant retention setting is exposed (Plus) | *tbd* | [agentic-platform/04-identity-and-privileged-access.md](agentic-platform/04-identity-and-privileged-access.md) §8.1, §8.4 and its unverified table; [agentic-platform/08-data-logging-retention-sovereignty.md](agentic-platform/08-data-logging-retention-sovereignty.md) R5, R8, DL-7.4; [agentic-platform/03-gemini-enterprise-environment.md](agentic-platform/03-gemini-enterprise-environment.md) §5.4, GE-0; [wall-e/SETUP.md](wall-e/SETUP.md) Phase 2 G4 |
| Which identity provider signs users in to Workspace: Google Identity, or a third-party SAML provider (Workspace SSO)? | Whether sign-in events for the robots and the human super admins are Google's login events or the provider's; whether the edition's admin 2SV enforcement applies (it names editions using third-party SSO); the Gemini Enterprise app's provider, which is decided separately as Google Identity (P51) and must not change after the first user | *tbd* | [agentic-platform/03-gemini-enterprise-environment.md](agentic-platform/03-gemini-enterprise-environment.md) §6; [agentic-platform/12-open-decisions.md](agentic-platform/12-open-decisions.md) P51; [gemini-enterprise.md](gemini-enterprise.md) |

## OU structure

*(how organisational units are laid out and what that drives)*

## Groups that matter

*(security groups used for licensing, IAM binding, feature rollout)*

## Rollout / feature-flag practice

*(how new features are piloted: which OU, which group, how long)*

## Integrations

*(third-party apps, Marketplace allowlist, OAuth app controls, domain-wide delegation
— and who approved each)*

## Recurring admin tasks
→ see [../runbooks/](../runbooks/)
