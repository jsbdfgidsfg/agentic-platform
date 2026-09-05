# Digital Workplace — Wiki

Personal working wiki for the platform owner — Digital Workplace manager, the organisation.
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
- **Edge AI v2 (agentic Workspace ops)** → [platform/edge-ai-v2/](platform/edge-ai-v2/README.md)
- **Open questions / backlog** → [backlog.md](backlog.md)

## Conventions

- One topic per file, kebab-case filenames.
- Every page starts with a `## Status` block: owner, last reviewed, maturity.
- Dates are absolute (`2026-09-05`), never "last week".
- Decisions are append-only in `decisions/` — supersede, don't rewrite.
- **No secrets.** No keys, tokens, passwords, service-account JSON. Reference where a
  secret lives (Secret Manager path, vault entry), never the value.
