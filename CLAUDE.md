# Maintaining this wiki

This is the platform owner's working wiki — Digital Workplace manager,
building an agentic platform on GCP + Google Workspace. The owner is Workspace super
admin and Gemini Enterprise admin, and owns several GCP projects.

No page in this wiki names the owner. Roles are named; people are not. Keep it that way:
write "the platform owner", "the second human", "the security reviewer", never a person.

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
- Nothing company-confidential that the owner hasn't explicitly said to write down.
- Don't state facts about the organisation's environment that you haven't been told. If you infer
  something, mark it clearly as an assumption.

## Drive sync

The wiki is mirrored to Google Drive as native Google Docs via `_sync/wiki_sync.py`.
Markdown here is the authoring surface; Drive is the reading and sharing surface.

- After editing pages, run `_sync/wiki push` yourself via Bash. It is
  non-interactive and safe to run unattended. If it reports it is not authorised,
  ask the owner to run `cd _sync && ./wiki auth` once — that is the only step
  that needs them.
- If they say they edited something in Google Docs, run `pull` **before** editing that
  page locally, or their changes will be flagged as a conflict. `pull` reverses
  everything `push` rewrote, and refuses to overwrite a page it cannot fully reverse
  (it leaves a `.pulled.md` sidecar to merge by hand instead).
- After changing `wiki_sync.py`, run `_sync/wiki selftest`. It checks offline that
  every page survives a push/pull round trip unchanged.
- Do **not** use the Drive MCP connector to update wiki pages: its update operation
  cannot change file content, only titles and parents. Replacing a Doc would destroy
  its id, comments, revision history and every link pointing at it.
- `_sync/manifest.json` is the path→doc-id mapping. Commit it. Losing it orphans every
  Doc in Drive.
