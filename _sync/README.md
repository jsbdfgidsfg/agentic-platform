# Drive sync

Publishes the markdown wiki to Google Drive as native Google Docs, and pulls Doc
edits back down. `manifest.json` maps each markdown path to its Drive file id — it is
committed to git, so the mapping survives and doc ids stay stable.

## One-time setup

1. In any GCP project you own, enable the **Google Drive API**.
2. APIs & Services → Credentials → Create credentials → **OAuth client ID** →
   **Desktop app**. Download the JSON.
3. Save it as `client_secret.json` in this folder (git-ignored).
4. `pip install -r requirements.txt`
5. `python wiki_sync.py push` — a browser opens once for consent.

Scope is `drive.file`: this tool can only see and touch files it created itself.
It has no visibility into the rest of your Drive.

## Daily use

```
python wiki_sync.py status   # what differs on each side
python wiki_sync.py push     # local markdown -> Docs
python wiki_sync.py pull     # Doc edits -> local markdown
python wiki_sync.py open     # print the Drive folder URL
```

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
