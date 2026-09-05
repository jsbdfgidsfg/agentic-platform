# Maintaining this wiki

This is the platform owner's working wiki — Digital Workplace manager at the organisation,
building an agentic platform on GCP + Google Workspace. He is Workspace super admin
and Gemini Enterprise admin, and owns several GCP projects.

## How to update it

- **Capture first, file second.** If something arrives mid-conversation and there's no
  obvious home, append it to `inbox.md` with a date. Don't invent a new page for a
  one-liner.
- **Prefer editing an existing page** over creating one. New pages only when a topic
  has outgrown its section.
- Update the `## Status` block (`Last reviewed:`) on any page you meaningfully change.
- Keep tables as tables. Keep `*tbd*` placeholders until there's a real value —
  never fill them with plausible-sounding guesses.
- Dates absolute (`2026-09-05`). Relative dates rot.
- Decisions go in `decisions/YYYY-MM-DD-title.md` and are **append-only** — supersede,
  never rewrite.
- After a meeting note, promote its actions into `backlog.md`.
- Commit after each substantive change: `git -C <wiki> add -A && git commit -m "..."`.

## Hard rules

- **No secrets.** No API keys, tokens, passwords, service-account JSON, no personal
  data about employees beyond name/team/remit. Record *where* a secret lives, not what
  it is.
- Nothing the organisation-confidential that the platform owner hasn't explicitly said to write down.
- Don't state facts about the organisation's environment that you haven't been told. If you infer
  something, mark it clearly as an assumption.
