#  Digital Workplace — Wiki

Working wiki of the platform owner — Digital Workplace Manager
Scope: agentic platform on **GCP** + **Google Workspace**, Gemini Enterprise admin, Workspace super admin.

> Maintained with Claude. To add or update anything, just say what happened —
> "note that X", "log the decision on Y", "update the Gemini Enterprise page".
>
> Published to Google Drive as native Google Docs: `python _sync/wiki_sync.py push`.
> See [_sync/README.md](_sync/README.md).

## Map

| Section | What lives here |
|---|---|
| [Inbox](inbox.md) | Unsorted capture. Anything not yet filed. Cleared regularly. |
| [Platform](platform/) | The systems themselves: GCP projects, Workspace, Gemini Enterprise, agents |
| [Runbooks](runbooks/) | Step-by-step procedures you repeat |
| [Decisions](decisions/) | Why things are the way they are (dated, immutable log) |
| [Meetings](meetings/) | Notes + actions, one file per meeting |
| [Reference](reference/) | Links, quotas, licence counts, external docs |
| [People](people/) | Teams, vendors, key contacts and who owns what |

## Current state

- **Platform overview** → [platform/overview.md](platform/overview.md)
- **GCP projects** → [platform/gcp-projects.md](platform/gcp-projects.md)
- **Google Workspace** → [platform/google-workspace.md](platform/google-workspace.md)
- **Gemini Enterprise** → [platform/gemini-enterprise.md](platform/gemini-enterprise.md)
- **Agents catalogue** → [platform/agents.md](platform/agents.md)
- **Wall-E, Eve & Mo (agentic Workspace ops)** → [platform/wall-e/](platform/wall-e/README.md)
- **Edge AI v2** (superseded by Wall-E) → [platform/edge-ai-v2/](platform/edge-ai-v2/README.md)
- **Open questions / backlog** → [backlog.md](backlog.md)
- **Agentic platform: design set** → [platform/agentic-platform/README.md](platform/agentic-platform/README.md)
- **Agentic platform: proof of value (POV build)** → [platform/agentic-platform/pov/README.md](platform/agentic-platform/pov/README.md)
- **Agentic platform: three-day build (2 people, 6 person-days, synthetic accounts)** → [platform/agentic-platform/3-day/README.md](platform/agentic-platform/3-day/README.md)
- **Agentic platform: architecture brief** → [platform/agentic-platform/brief/README.md](platform/agentic-platform/brief/README.md)
- **Agentic platform: in plain words, for any reader** → [platform/agentic-platform/plain/README.md](platform/agentic-platform/plain/README.md)
- **Agentic platform: documents per audience** (HR and works council, security, compliance, architecture, C-level deck, executive brief) → [platform/agentic-platform/audiences/README.md](platform/agentic-platform/audiences/README.md)
- **Agentic platform: sales presentation and pitch** → [platform/agentic-platform/pitch/sales-presentation.md](platform/agentic-platform/pitch/sales-presentation.md), [pitch.md](platform/agentic-platform/pitch/pitch.md)
- **Agentic platform: cross-check review (2026-09-18)** → [platform/agentic-platform/14-crosscheck-review.md](platform/agentic-platform/14-crosscheck-review.md)

## Conventions

- One topic per file, kebab-case filenames.
- Every page starts with a `## Status` block: owner, last reviewed, maturity.
- Dates are absolute (`2026-09-05`), never "last week".
- Decisions are append-only in `decisions/` — supersede, don't rewrite.
- **No secrets.** No keys, tokens, passwords, service-account JSON. Reference where a
  secret lives (Secret Manager path, vault entry), never the value.
