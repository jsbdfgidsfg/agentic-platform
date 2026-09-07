# Drive sync

Publishes the markdown wiki to Google Drive as native Google Docs, and pulls Doc
edits back down. `manifest.json` maps each markdown path to its Drive file id — it is
committed to git, so the mapping survives and doc ids stay stable.

## One-time setup

1. In any GCP project you own, enable the **Google Drive API**.
2. APIs & Services → Credentials → Create credentials → **OAuth client ID** →
   **Desktop app**. Download the JSON.
3. Save it as `client_secret.json` in this folder (git-ignored).
4. Dependencies are already installed in `.venv/` (created 2026-09-07).
   To rebuild it: `python3 -m venv .venv && .venv/bin/python -m pip install -r requirements.txt`
5. `./wiki auth` — a browser opens once for consent.

That is the only step that needs you. `push`, `pull` and `status` never open a
browser: they use the cached token and refresh it silently, so Claude can run them
directly, and they exit with a clear message rather than hanging if the token dies.

Scope is `drive.file`: this tool can only see and touch files it created itself.
It has no visibility into the rest of your Drive.

## Daily use

```
./wiki auth     # one-time, needs a browser
./wiki status   # what differs on each side
./wiki push     # local markdown -> Docs
./wiki pull     # Doc edits -> local markdown
./wiki open     # print the Drive folder URL
```

`./wiki` is a wrapper that always uses `.venv/bin/python`, so these work from any
shell without activating anything.

## Python version

This Mac has only Apple's Command Line Tools Python **3.9.6**, which is past end of
life. The Google libraries work but warn about it on every import; those warnings are
filtered in `wiki_sync.py` so they do not bury the output. Nothing here needs a newer
Python, but if you install one (Homebrew, uv), rebuild `.venv` against it.

`push` skips unchanged files and refuses to overwrite a Doc that changed in Drive
since the last sync — pull first, or `--force` to overwrite deliberately.

## What survives the round trip

| | |
|---|---|
| Headings, bold/italic, lists, tables, code blocks, links | Clean both ways |
| Cross-page links | Rewritten to Drive doc URLs on push |
| Mermaid diagrams | **Not rendered in Docs.** Source is kept with a note pointing to mermaid.live |
| Comments, suggestions, revision history in Docs | Preserved — push updates content in place, it never replaces the file |

Not synced: `CLAUDE.md`, anything under `_`- or `.`-prefixed directories.
