# Platform overview

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-08
- Maturity: skeleton — to be filled

## What this is

The the organisation agentic platform: internal AI agents for employees, built on Google Cloud
and integrated into Google Workspace, with Gemini Enterprise as the primary
end-user surface.

## Building blocks

| Layer | Product | Page |
|---|---|---|
| End-user surface | Gemini Enterprise | [gemini-enterprise.md](gemini-enterprise.md) |
| Identity & collaboration | Google Workspace | [google-workspace.md](google-workspace.md) |
| Compute / data / models | GCP | [gcp-projects.md](gcp-projects.md) |
| The agents themselves | — | [agents.md](agents.md) |
| First build | **Wall-E** (+ Eve, Mo) | [wall-e/](wall-e/README.md) |
| Superseded | Edge AI v2 | [edge-ai-v2/](edge-ai-v2/README.md) |

## Architecture

*(to document: how requests flow from a the organisation user to an agent and back — surface,
auth, data sources, model, guardrails, logging)*

## Constraints

*(to document: data residency, EU hosting, GDPR/works council, security review gates,
budget owner)*
