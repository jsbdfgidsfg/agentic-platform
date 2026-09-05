# 7. Decisions to make before build

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-05

Answer these, then record the answers as dated entries in `../../decisions/`.

| # | Decision | Why it matters | Recommendation |
|---|---|---|---|
| 1 | **Exact OAuth scope list** | Adding a scope later requires re-running the consent flow | Take the full read set now; add write scopes only for operations you will actually enable in v1 |
| 2 | **Does the robot get user create/delete?** | Determines whether offboarding is in scope | Not in v1. Suspend + group changes cover most value at a fraction of the risk |
| 3 | **Is `gmail.send` WRITE_LOW or WRITE_HIGH?** | WRITE_LOW means an injection could cause an internal email | WRITE_LOW for internal, confirmation for external (already implemented). Revisit after pilot |
| 4 | **Who is in `edge-ai-operators@` at launch?** | This is the set of people who can cause admin writes | You alone for the pilot |
| 5 | **Which model** | Cost vs. reliability on tool selection | Gemini 2.5 Pro for the pilot; measure before downgrading |
| 6 | **GCP region** | Data residency | `europe-west1`, subject to Agent Engine availability |
| 7 | **Is the robot's mailbox processed unattended?** | The riskiest flow in the design | Not in v1. If later, use a separate read-only operation set |
| 8 | **DPIA / works council needed?** | Long lead time; can block pilot | Ask Legal/DPO in week 1, in parallel with build |
| 9 | **Codename / final naming** | `edge-ai-v2` is a placeholder | Decide before the OAuth consent screen is created — the app name is user-visible |
| 10 | **Second front door: a Chat app?** | Better UX than Gemini Enterprise for quick asks | Out of scope for v1; the action service already supports it |

## Things I could not verify and you must check in-console

These change between Google releases; confirm during build and correct the docs:

1. How Gemini Enterprise propagates the **end-user identity** to a registered Agent
   Engine agent, and under what key it lands in ADK session state
   (`agent/agent.py::_actor`).
2. The current **registration flow** for a custom Agent Engine agent in Gemini Enterprise
   ([05-build-runbook.md](05-build-runbook.md) Phase 6).
3. Whether the **Chat API methods** you need are available to user credentials or only to
   Chat app identities ([04-flows.md](04-flows.md) Flow E).
4. Current **`google-adk` / `google-cloud-aiplatform` API surface** for
   `agent_engines.create()` (`agent/deploy.py`).
5. Availability of **Agent Engine in `europe-west1`**.
