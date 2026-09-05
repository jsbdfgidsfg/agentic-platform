# Edge AI v2 — agentic Workspace operations

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-05
- Maturity: design — not yet built
- Codename: `edge-ai-v2` (rename before rollout)

## One-line summary

A single Google Workspace robot user holds admin rights. A GCP-hosted agent acts **as**
that user to operate Workspace — read and send mail, post to Chat, run Directory admin
operations — and the only human entry point is a chat with an agent published in
Gemini Enterprise. **No domain-wide delegation anywhere.**

## Documents

| # | Document | What it answers |
|---|---|---|
| 1 | [High-level design](01-hld.md) | What the components are and why |
| 2 | [Identity & authorisation](02-identity-and-auth.md) | How we act as the robot user without DWD |
| 3 | [Low-level design](03-lld.md) | Interfaces, data shapes, policy engine, tool contracts |
| 4 | [Flows](04-flows.md) | End-to-end sequences for mail, Chat, and admin actions |
| 5 | [Build runbook](05-build-runbook.md) | Every command, in order, to stand it up |
| 6 | [Security & guardrails](06-security-guardrails.md) | Blast-radius control, audit, failure modes |
| 7 | [Decisions to make](07-open-decisions.md) | What the platform owner must choose before build starts |

Code scaffold: `~/Claude/edge-ai-v2/`

## The load-bearing constraint

No domain-wide delegation means the platform cannot mint credentials for arbitrary users.
It can only ever act as **one** identity: the robot account itself. Everything in this
design follows from that. See [02-identity-and-auth.md](02-identity-and-auth.md).
