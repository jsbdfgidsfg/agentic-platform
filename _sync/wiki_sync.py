#!/usr/bin/env python3
"""Sync the local markdown wiki to Google Drive as native Google Docs.

Drive is the reading and sharing surface; the local markdown repo stays the
authoring surface and keeps git history. Content moves both ways.

    ./wiki auth      # one-time browser consent
    ./wiki push      # local markdown -> Google Docs
    ./wiki pull      # Google Docs -> local markdown
    ./wiki status    # what differs on each side
    ./wiki open      # print the Drive folder URL
    ./wiki selftest  # prove push/pull is lossless, offline
    ./wiki reconcile # baseline Docs whose sync point was lost

Why not the Drive MCP connector: its update operation can only change a file's
title and parent, not its content. Updating a page would mean replacing the
document and losing its id, comments, revision history and inbound links. The
Drive API's files.update *does* replace content in place, preserving all of that.

Scope is drive.file — per-file access limited to files this tool created. It
cannot see or touch anything else in the Drive, which is the correct blast
radius for a sync tool.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import re
import sys
import tempfile
import warnings
from pathlib import Path

# The Google libraries emit four EOL/TLS warnings per run on this Mac's system
# Python 3.9. They are real (see README: "Python version"), but repeating them on
# every sync buries the actual output. Silence them here, not the underlying issue.
warnings.filterwarnings("ignore", message=r".*Python version.*")
warnings.filterwarnings("ignore", message=r".*OpenSSL.*")

import httplib2
import google_auth_httplib2
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload, MediaIoBaseDownload

SCOPES = ["https://www.googleapis.com/auth/drive.file"]
HTTP_TIMEOUT = 120      # seconds; the default is the OS default, which hung a push
NUM_RETRIES = 5         # googleapiclient retries 5xx/429 with exponential backoff
EMPTY_DOC_MAX_CHARS = 8 # an untouched Doc exports as "&nbsp;", never real text
WIKI_ROOT = Path(__file__).resolve().parent.parent
MANIFEST = Path(__file__).resolve().parent / "manifest.json"
TOKEN = Path.home() / ".config" / "wiki-sync" / "token.json"
CLIENT_SECRETS = Path(__file__).resolve().parent / "client_secret.json"
SIDECAR_DIR = Path(__file__).resolve().parent / "pulled"   # withheld pulls, outside the synced tree

EXCLUDE_FILES = {"CLAUDE.md"}   # maintenance instructions for Claude, not team content

DOC_MIME = "application/vnd.google-apps.document"
FOLDER_MIME = "application/vnd.google-apps.folder"
ROOT_FOLDER_NAME = "Digital Workplace Wiki"


# --------------------------------------------------------------------------
# auth
# --------------------------------------------------------------------------

def _write_token(creds) -> None:
    """0600 from creation. write_text() then chmod() leaves a window where the
    refresh token is readable at the umask default."""
    fd = os.open(str(TOKEN), os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(creds.to_json())


def _client(creds):
    """One place to build the Drive client, so the timeout is never forgotten.
    Without an explicit timeout a stalled socket hangs the whole sync; that is how
    the first push died partway through creating documents."""
    return build("drive", "v3", cache_discovery=False,
                 http=google_auth_httplib2.AuthorizedHttp(
                     creds, http=httplib2.Http(timeout=HTTP_TIMEOUT)))


def drive(interactive: bool = False):
    """Build a Drive client from the cached token.

    Only `auth` may open a browser. push/pull/status are non-interactive by design:
    they are meant to be runnable unattended (by Claude, by cron), and a blocking
    consent prompt in a headless context would hang instead of failing.
    """
    TOKEN.parent.mkdir(parents=True, exist_ok=True)
    creds = None
    if TOKEN.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN), SCOPES)

    if creds and creds.valid:
        return _client(creds)

    if creds and creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
            _write_token(creds)
            return _client(creds)
        except Exception as exc:
            if not interactive:
                sys.exit(f"Drive token could not be refreshed ({exc}).\n"
                         "Re-authorise with: cd wiki/_sync && ./wiki auth")

    if not interactive:
        sys.exit("Not authorised yet. Run once, at a terminal:\n"
                 "    cd wiki/_sync && ./wiki auth")

    if not CLIENT_SECRETS.exists():
        sys.exit(f"Missing {CLIENT_SECRETS}.\n"
                 "Create an OAuth client (Desktop app) in any GCP project with the\n"
                 "Drive API enabled, download the JSON, and save it there.")
    flow = InstalledAppFlow.from_client_secrets_file(str(CLIENT_SECRETS), SCOPES)
    creds = flow.run_local_server(port=0)
    _write_token(creds)
    return _client(creds)


def cmd_auth(args) -> int:
    """One-time browser consent. Everything after this runs unattended."""
    svc = drive(interactive=True)
    about = svc.about().get(fields="user(emailAddress)").execute(num_retries=NUM_RETRIES)
    print(f"Authorised as {about['user']['emailAddress']}")
    print(f"Token cached at {TOKEN}")
    print("push / pull / status now run without a browser.")
    return 0


# --------------------------------------------------------------------------
# manifest
# --------------------------------------------------------------------------

def load_manifest() -> dict:
    if MANIFEST.exists():
        return json.loads(MANIFEST.read_text(encoding="utf-8"))
    return {"root_folder_id": None, "folders": {}, "files": {}}


def save_manifest(m: dict) -> None:
    """Write atomically. The manifest is now saved after every created Doc, so an
    interrupted write is far likelier than it used to be — and a half-written
    manifest orphans every Doc it was supposed to record."""
    tmp = MANIFEST.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(m, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, MANIFEST)


def sha(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


# --------------------------------------------------------------------------
# local discovery
# --------------------------------------------------------------------------

def skip(path: Path) -> bool:
    """Dot- or underscore-prefixed DIRECTORIES are tooling (_sync, .git) and never sync.
    Underscore-prefixed files (_template.md) are content and do sync."""
    rel = path.relative_to(WIKI_ROOT)
    if rel.name in EXCLUDE_FILES:
        return True
    return any(part.startswith((".", "_")) for part in rel.parts[:-1])


def local_pages() -> list[Path]:
    return sorted(p for p in WIKI_ROOT.rglob("*.md")
                  if p.is_file() and not skip(p))


# Words that must not be Title-Cased into mush ("Hld", "Gcp", "Api").
ACRONYMS = {"hld", "lld", "gcp", "ai", "dwp", "api", "iam", "ou", "adk", "hmac",
            "dwd", "sdk", "oauth", "mcp", "sso", "url", "id", "ui", "v2", "dpia"}


def _prettify(stem: str) -> str:
    words = stem.replace("-", " ").replace("_", " ").split()
    return " ".join(w.upper() if w.lower() in ACRONYMS else w.capitalize()
                    for w in words)


def doc_title(rel: Path) -> str:
    """Drive search is flat, so every page is prefixed with its section. Without that,
    wall-e/01-hld.md and edge-ai-v2/01-hld.md were both plain '01. HLD'."""
    stem = rel.stem.lstrip("_")
    section = _prettify(rel.parent.name) if rel.parent != Path(".") else ""
    if stem.upper() == "README":
        return "Wiki — Home" if not section else f"{section} — Overview"
    if stem.lower() == "template" and section:
        return f"{section} — Template"

    # A dated decision file keeps its date readable: the generic numeric rule below
    # turned "2026-09-05-drop-vertex-search" into "2026. 09 05 Drop Vertex Search".
    iso = re.match(r"^(\d{4}-\d{2}-\d{2})[-_](.*)$", stem)
    if iso:
        name = f"{iso.group(1)} — {_prettify(iso.group(2))}"
    else:
        # Keep a numeric prefix as an ordering key: "01-hld" -> "01. HLD"
        num = re.match(r"^(\d+)[-_](.*)$", stem)
        name = f"{num.group(1)}. {_prettify(num.group(2))}" if num else _prettify(stem)
    return f"{section} — {name}" if section else name


# --------------------------------------------------------------------------
# content transformation
# --------------------------------------------------------------------------

MERMAID_RE = re.compile(r"```mermaid\n(.*?)```", re.DOTALL)
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+\.md)(#[^)]*)?\)")

# Every push transform must have an inverse below, or `pull` silently destroys the
# authoring copy. The markers exist so the inverse can find its own output again.
MERMAID_NOTE = ("> **Diagram (Mermaid).** Renders in the markdown wiki. To view it here,\n"
                "> paste the source below into https://mermaid.live\n\n")
MERMAID_BACK_RE = re.compile(
    r"> \*\*Diagram \(Mermaid\)\.\*\*[^\n]*\n> [^\n]*\n\n```\n(.*?)```", re.DOTALL)
DOCLINK_RE = re.compile(
    r"\[([^\]]+)\]\(https://docs\.google\.com/document/d/([A-Za-z0-9_-]+)/edit(#[^)]*)?\)")
BANNER = ("*Synced from the markdown wiki. Edits made here are preserved — run "
          "`wiki_sync.py pull` to bring them back.*\n\n---\n\n")


def transform_for_docs(text: str, rel: Path, manifest: dict) -> str:
    """Rewrite what does not survive the trip into Google Docs.

    Every change here is undone by transform_from_docs(); see round_trips() and the
    self-test in `./wiki selftest`.
    """

    def link_sub(m):
        label, target, anchor = m.group(1), m.group(2), m.group(3) or ""
        resolved = os.path.normpath(str((rel.parent / target)))
        entry = manifest["files"].get(resolved)
        if entry and entry.get("file_id"):
            # The anchor rides along, or pull cannot put it back and silently
            # strips every deep link on the first round trip.
            return (f"[{label}](https://docs.google.com/document/d/"
                    f"{entry['file_id']}/edit{anchor})")
        # Unmapped target: keep the link intact rather than dissolving it to plain
        # words. Dropping it here made `pull` destroy the link permanently.
        return f"[{label}]({target}{anchor})"

    # Strip any banner already present, so a pushed-pulled-pushed page does not
    # accumulate one banner per cycle.
    text = strip_banner(text)
    text = LINK_RE.sub(link_sub, text)

    # Google Docs cannot render Mermaid. Keep the source, and say so plainly rather
    # than silently shipping a broken diagram.
    text = MERMAID_RE.sub(lambda m: MERMAID_NOTE + "```\n" + m.group(1) + "```", text)
    return BANNER + text


def transform_from_docs(text: str, rel: Path, manifest: dict) -> str:
    """Inverse of transform_for_docs. Without this, `pull` overwrites the local
    markdown with the Docs-flavoured copy: mermaid diagrams become inert code blocks
    and every relative wiki link becomes a docs.google.com URL."""
    by_id = {e["file_id"]: p for p, e in manifest["files"].items() if e.get("file_id")}

    text = strip_banner(text)
    text = MERMAID_BACK_RE.sub(lambda m: "```mermaid\n" + m.group(1) + "```", text)

    def unlink_sub(m):
        label, fid, anchor = m.group(1), m.group(2), m.group(3) or ""
        target = by_id.get(fid)
        if not target:
            return m.group(0)   # a genuine Docs link someone added by hand: leave it
        return f"[{label}]({os.path.relpath(target, str(rel.parent))}{anchor})"

    return DOCLINK_RE.sub(unlink_sub, text)


def round_trips(text: str, rel: Path, manifest: dict) -> bool:
    """True when a push followed by a pull returns the original bytes."""
    return transform_from_docs(transform_for_docs(text, rel, manifest), rel, manifest) == text


def strip_banner(text: str) -> str:
    marker = "---\n\n"
    if text.lstrip().startswith("*Synced from the markdown wiki"):
        idx = text.find(marker)
        if idx != -1:
            return text[idx + len(marker):]
    return text


# --------------------------------------------------------------------------
# drive helpers
# --------------------------------------------------------------------------

def _find_by_name(svc, name: str, parent: str, mime: str):
    """A file this tool created earlier under the same parent with the same name.
    Used to make Doc creation idempotent without pre-allocated ids, which Google
    Docs do not accept ("Generated IDs are not supported for Docs Editors formats")."""
    q = ("name = '%s' and '%s' in parents and mimeType = '%s' and trashed = false"
         % (name.replace("'", "\\'"), parent, mime))
    res = svc.files().list(q=q, fields="files(id,name)", pageSize=2,
                           spaces="drive").execute(num_retries=NUM_RETRIES)
    files = res.get("files", [])
    return files[0]["id"] if len(files) == 1 else None


def _create(svc, body: dict, manifest: dict, remember) -> str:
    """Create a Doc or folder idempotently.

    Retries on a create are dangerous: googleapiclient retries socket timeouts and
    connection errors, which are exactly the cases where the server may already have
    created the file. Retrying then makes a second one, and only the second id is
    recorded — the same orphan class as the 2026-09-08 incident. Two strategies:

    - Folders: reserve an id with generateIds, record it BEFORE the call, create with
      that id and never retry. A re-run adopts the reserved id.
    - Google Docs: Drive refuses pre-allocated ids for Docs Editors formats (403,
      "Generated IDs are not supported"). So: look for a Doc of the same name under
      the same parent first and adopt it; otherwise create with no retries, and
      record the id the moment the response arrives.
    """
    mime = body.get("mimeType")
    name, parents = body["name"], body.get("parents") or [None]
    if mime == DOC_MIME:
        existing = _find_by_name(svc, name, parents[0], mime) if parents[0] else None
        if existing:
            remember(existing); save_manifest(manifest)
            return existing
        created = svc.files().create(body=body, fields="id").execute(num_retries=0)
        remember(created["id"]); save_manifest(manifest)
        return created["id"]

    reserved = body.get("id")
    if not reserved:
        reserved = svc.files().generateIds(
            count=1, type="files").execute(num_retries=NUM_RETRIES)["ids"][0]
        body = dict(body, id=reserved)
    remember(reserved)          # persisted before the create can possibly succeed
    save_manifest(manifest)
    try:
        svc.files().create(body=body, fields="id").execute(num_retries=0)
    except HttpError as exc:
        if exc.resp.status != 409:      # 409 = we already created it on a prior try
            raise
    return reserved


def ensure_folder(svc, name: str, parent: str | None, manifest: dict, key: str) -> str:
    existing = manifest["folders"].get(key)
    if existing:
        try:
            got = svc.files().get(fileId=existing,
                                  fields="id,trashed").execute(num_retries=NUM_RETRIES)
            # A trashed folder still returns 200. Reusing its id would file every new
            # Doc inside the trash, invisible and auto-purged after 30 days.
            if not got.get("trashed"):
                return existing
        except HttpError as exc:
            if exc.resp.status != 404:
                raise   # 403/401 is not "deleted upstream"; creating a duplicate
                        # folder here would strand every Doc already inside the old one
    body = {"name": name, "mimeType": FOLDER_MIME}
    if parent:
        body["parents"] = [parent]
    return _create(svc, body, manifest,
                   lambda fid: manifest["folders"].__setitem__(key, fid))


def ensure_tree(svc, manifest: dict) -> None:
    root = ensure_folder(svc, ROOT_FOLDER_NAME, None, manifest, ".")
    manifest["root_folder_id"] = root
    # sorted(): a set gives a different creation order every run, so an interrupted
    # run leaves a different partial state each time and is harder to reason about.
    for rel in sorted({p.relative_to(WIKI_ROOT).parent for p in local_pages()},
                      key=str):
        if str(rel) == ".":
            continue
        parent = root
        acc = Path(".")
        for part in rel.parts:
            acc = acc / part
            parent = ensure_folder(svc, _prettify(part), parent,
                                   manifest, str(acc))


UNKNOWN = "<unknown>"       # distinct from None: "we could not find out", not "absent"


# Docs converts an uploaded body asynchronously, and a long page takes longer than a
# short one: a 1,500-line runbook was still settling after 15 s on 2026-09-12, which
# left its recorded timestamp stale and made the next push call it "Drive changed".
# Back off instead of polling at a fixed rate, and give up only after ~2 minutes.
SETTLE_BACKOFF_S = (2, 3, 5, 8, 13, 21, 34, 55)


def settle(svc, manifest, rels) -> int:
    """Re-reads modifiedTime for pages written this run until it stops moving.

    Docs converts an uploaded markdown body asynchronously: files.update returns,
    and modifiedTime moves again a few seconds later when the conversion lands.
    Recording the first value made the next push see "Drive changed" on 18 of
    43 pages (2026-09-11) and refuse them as conflicts. Returns how many entries
    were corrected."""
    import time
    pending = list(rels)
    corrected = 0
    for wait in SETTLE_BACKOFF_S:
        if not pending:
            break
        time.sleep(wait)
        still = []
        for rel in pending:
            entry = manifest["files"][rel]
            ts = remote_modified(svc, entry["file_id"])
            if ts in (None, UNKNOWN):
                continue                      # leave the guard to report it next run
            if ts != entry.get("remote_modified"):
                entry["remote_modified"] = ts
                corrected += 1
                still.append(rel)             # moved: confirm it is stable next round
        pending = still
        save_manifest(manifest)
    return corrected


def remote_modified(svc, file_id: str):
    """Returns the timestamp, None if the Doc is gone, or UNKNOWN on a transient
    failure. Collapsing all three into None disabled the conflict guard silently."""
    try:
        return svc.files().get(fileId=file_id,
                               fields="modifiedTime").execute(num_retries=NUM_RETRIES)["modifiedTime"]
    except HttpError as exc:
        return None if exc.resp.status == 404 else UNKNOWN


def upload_media(path: Path):
    return MediaFileUpload(str(path), mimetype="text/markdown", resumable=False)


# --------------------------------------------------------------------------
# commands
# --------------------------------------------------------------------------

def cmd_push(args) -> int:
    svc = drive()
    manifest = load_manifest()
    ensure_tree(svc, manifest)
    pages = local_pages()

    created_this_run = set()
    # Pass 1 — every page must have an id before links can be rewritten.
    live = {str(p.relative_to(WIKI_ROOT)) for p in pages}
    for path in pages:
        rel = str(path.relative_to(WIKI_ROOT))
        entry = manifest["files"].setdefault(rel, {})
        if entry.get("file_id"):
            continue

        # A renamed page is the same document. Creating a new Doc for it would
        # strand the original along with its comments, revision history and every
        # link pointing at it — the things this tool exists to preserve.
        local_hash = sha(path.read_text(encoding="utf-8"))
        adopted = next((old for old, e in sorted(manifest["files"].items())
                        if old not in live and e.get("file_id")
                        and e.get("local_hash") == local_hash), None)
        if adopted:
            manifest["files"][rel] = manifest["files"].pop(adopted)
            save_manifest(manifest)
            print(f"renamed  {adopted} -> {rel}")
            continue

        parent = manifest["folders"][str(path.relative_to(WIKI_ROOT).parent)]
        # _create saves the manifest BEFORE the call. Saving once at the end of the
        # loop meant a timeout mid-loop orphaned every Doc created so far, with no
        # local record of its id. That happened on 2026-09-08.
        fid = _create(svc,
                      {"name": doc_title(path.relative_to(WIKI_ROOT)),
                       "parents": [parent], "mimeType": DOC_MIME},
                      manifest,
                      lambda fid, e=entry: e.__setitem__("file_id", fid))
        # A Doc created here has no sync point by construction: record the empty
        # Doc's own timestamp as the baseline, or pass 2's fail-closed guard refuses
        # to fill a document this very run just created. Drive also bumps that
        # timestamp again a moment after creation, so the value recorded here can be
        # stale by the time pass 2 reads it: remember the path instead and let pass 2
        # skip the guard for it. A Doc this run created holds nobody's edits.
        entry["remote_modified"] = remote_modified(svc, fid)
        created_this_run.add(rel)
        save_manifest(manifest)
        print(f"created  {rel}")

    # Pass 2 — content, with links now resolvable.
    changed = skipped = conflicts = 0
    written = []
    for path in pages:
        rel = str(path.relative_to(WIKI_ROOT))
        entry = manifest["files"][rel]
        raw = path.read_text(encoding="utf-8")
        local_hash = sha(raw)

        if entry.get("local_hash") == local_hash and not args.force:
            skipped += 1
            continue

        # Fail closed. The old guard began `entry.get("remote_modified") and ...`,
        # so a missing or unreadable timestamp read as "no conflict" and pushed over
        # whatever was in Drive. Every entry in a hand-rebuilt manifest looks like
        # that, which is exactly when you least want a silent overwrite.
        remote_ts = remote_modified(svc, entry["file_id"])
        known = remote_ts if rel in created_this_run else entry.get("remote_modified")
        if not args.force:
            if remote_ts is UNKNOWN:
                print(f"CONFLICT {rel}: cannot read the Doc's state. Not overwriting.")
                conflicts += 1
                continue
            if known is None and remote_ts is not None:
                print(f"CONFLICT {rel}: no recorded sync point for this Doc. "
                      f"Run 'pull' first, or push with --force to overwrite.")
                conflicts += 1
                continue
            if known and remote_ts != known:
                print(f"CONFLICT {rel}: changed in Drive since last sync. "
                      f"Run 'pull' first, or push with --force to overwrite.")
                conflicts += 1
                continue

        body = transform_for_docs(raw, Path(rel), manifest)
        with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False,
                                         encoding="utf-8") as fh:
            fh.write(body)
            tmp = Path(fh.name)
        try:
            svc.files().update(fileId=entry["file_id"], media_body=upload_media(tmp),
                               body={"name": doc_title(Path(rel))}).execute(num_retries=NUM_RETRIES)
        finally:
            tmp.unlink(missing_ok=True)

        entry["local_hash"] = local_hash
        entry["remote_modified"] = remote_modified(svc, entry["file_id"])
        changed += 1
        written.append(rel)
        print(f"pushed   {rel}")

    save_manifest(manifest)
    if written:
        settle(svc, manifest, written)
    print(f"\n{changed} pushed, {skipped} unchanged, {conflicts} conflicted.")
    print(f"Drive folder: https://drive.google.com/drive/folders/{manifest['root_folder_id']}")
    # Non-zero on conflict: an agent running this unattended must not read "success"
    # from a run that quietly skipped half the wiki.
    return 1 if conflicts else 0


def cmd_pull(args) -> int:
    svc = drive()
    manifest = load_manifest()
    pulled = withheld = 0
    for rel, entry in sorted(manifest["files"].items()):
        fid = entry.get("file_id")
        if not fid:
            continue
        path = WIKI_ROOT / rel
        # A page deleted locally, on purpose, must stay deleted. Recreating it from
        # a Doc nobody touched turns `pull` into an undelete.
        if not path.exists() and not args.force:
            print(f"SKIPPED  {rel}: deleted locally. --force to restore it from Drive.")
            withheld += 1
            continue

        remote_ts = remote_modified(svc, fid)
        if remote_ts is UNKNOWN:
            print(f"SKIPPED  {rel}: cannot read the Doc's state.")
            withheld += 1
            continue
        if remote_ts == entry.get("remote_modified") and not args.force:
            continue

        # Never overwrite local edits that were never pushed. `pull` used to write
        # unconditionally, so running it — which CLAUDE.md tells Claude to do before
        # editing a page — destroyed uncommitted local work with no warning.
        local_text = path.read_text(encoding="utf-8") if path.exists() else None
        if (local_text is not None and entry.get("local_hash")
                and sha(local_text) != entry["local_hash"] and not args.force):
            print(f"WITHHELD {rel}: changed on BOTH sides. Merge by hand, "
                  f"or --force to take the Drive copy.")
            withheld += 1
            continue

        buf = io.BytesIO()
        downloader = MediaIoBaseDownload(
            buf, svc.files().export_media(fileId=fid, mimeType="text/markdown"))
        done = False
        while not done:
            _, done = downloader.next_chunk()
        text = transform_from_docs(buf.getvalue().decode("utf-8"), Path(rel), manifest)

        # Refuse to overwrite the authoring copy with something we could not fully
        # reverse. Counting fences rather than matching the note's exact wording
        # matters: if Docs reformats the note, the wording check passes while the
        # diagram is already flattened.
        residue = []
        if "docs.google.com/document/d/" in text:
            residue.append("unresolved Google Docs links")
        if local_text is not None and text.count("```mermaid") < local_text.count("```mermaid"):
            residue.append("lost a mermaid diagram")
        if "Diagram (Mermaid)" in text:
            residue.append("un-restored mermaid note")
        if text.lstrip().startswith("*Synced from the markdown wiki"):
            residue.append("banner not stripped")
        if residue:
            SIDECAR_DIR.mkdir(parents=True, exist_ok=True)
            sidecar = SIDECAR_DIR / rel.replace(os.sep, "__")
            sidecar.write_text(text, encoding="utf-8")
            print(f"WITHHELD {rel}: {', '.join(residue)}. "
                  f"Wrote _sync/pulled/{sidecar.name} instead; merge it by hand.")
            withheld += 1
            continue

        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        entry["local_hash"] = sha(text)
        entry["remote_modified"] = remote_ts
        pulled += 1
        print(f"pulled   {rel}")
        save_manifest(manifest)
    save_manifest(manifest)
    print(f"\n{pulled} pulled, {withheld} withheld. "
          f"Review with 'git diff' before committing.")
    return 1 if withheld else 0


def cmd_status(args) -> int:
    svc = drive()
    manifest = load_manifest()
    tracked = set(manifest["files"])
    local = {str(p.relative_to(WIKI_ROOT)) for p in local_pages()}

    for rel in sorted(local - tracked):
        print(f"new locally      {rel}")
    for rel in sorted(tracked - local):
        print(f"gone locally     {rel}  (doc still in Drive)")
    differing = 0
    for rel in sorted(local & tracked):
        entry = manifest["files"][rel]
        fid = entry.get("file_id")
        if not fid:
            print(f"untracked        {rel}  (manifest entry has no file id)")
            differing += 1
            continue
        local_changed = sha((WIKI_ROOT / rel).read_text(encoding="utf-8")) != entry.get("local_hash")
        remote_changed = remote_modified(svc, fid) != entry.get("remote_modified")
        if local_changed and remote_changed:
            print(f"BOTH changed     {rel}")
        elif local_changed:
            print(f"local changed    {rel}")
        elif remote_changed:
            print(f"Drive changed    {rel}")
        else:
            continue
        differing += 1
    print(f"\n{differing} differ." if differing else "\nnothing differs.")
    return 0


def cmd_selftest(args) -> int:
    """Prove push/pull is lossless, without touching the network.

    This is the regression guard for the bug that made `pull` rewrite every wiki
    link as a docs.google.com URL and flatten every mermaid diagram.
    """
    manifest = load_manifest()
    pages = local_pages()
    bad = []
    for path in pages:
        rel = path.relative_to(WIKI_ROOT)
        text = path.read_text(encoding="utf-8")
        if not round_trips(text, rel, manifest):
            bad.append(str(rel))
    for rel in bad:
        print(f"LOSSY    {rel}")

    # Drive search is flat, so two pages sharing a title are indistinguishable there.
    seen = {}
    dupes = []
    for path in pages:
        rel = path.relative_to(WIKI_ROOT)
        title = doc_title(rel)
        if title in seen:
            dupes.append(f"{title!r}: {seen[title]} and {rel}")
        seen[title] = rel
    for d in dupes:
        print(f"DUPLICATE TITLE  {d}")

    print(f"\n{len(pages) - len(bad)}/{len(pages)} pages round-trip losslessly, "
          f"{len(dupes)} duplicate titles.")
    return 1 if (bad or dupes) else 0


def cmd_reconcile(args) -> int:
    """Establish a sync point for manifest entries that have none.

    A hand-rebuilt manifest (or one recovered after a crash) knows a Doc's id but
    not when it was last in sync. `push` now treats that as a conflict and refuses
    to overwrite, which is right but leaves the wiki stuck. This records the current
    Drive state as the baseline — declaring that the Doc holds nothing worth keeping.
    It refuses to do that for a Doc that already has content, unless --force.
    """
    svc = drive()
    manifest = load_manifest()
    fixed = kept = 0
    for rel, entry in sorted(manifest["files"].items()):
        fid = entry.get("file_id")
        if not fid or entry.get("remote_modified"):
            continue
        buf = io.BytesIO()
        downloader = MediaIoBaseDownload(
            buf, svc.files().export_media(fileId=fid, mimeType="text/markdown"))
        done = False
        while not done:
            _, done = downloader.next_chunk()
        body = strip_banner(buf.getvalue().decode("utf-8")).strip("\ufeff\xa0 \r\n\t")
        # A never-written Google Doc does not export as an empty string: it comes
        # back as the six characters "&nbsp;" (observed 2026-09-11). Anything a
        # person typed is longer than that.
        if len(body) > EMPTY_DOC_MAX_CHARS and not args.force:
            print(f"HAS CONTENT {rel}: {len(body)} chars in Drive. "
                  f"Run 'pull' to keep it, or 'reconcile --force' to discard it.")
            kept += 1
            continue
        ts = remote_modified(svc, fid)
        if ts is UNKNOWN or ts is None:
            print(f"SKIPPED  {rel}: cannot read the Doc's state.")
            continue
        entry["remote_modified"] = ts
        fixed += 1
        save_manifest(manifest)
        print(f"baseline {rel}")
    save_manifest(manifest)
    print(f"\n{fixed} baselined, {kept} left alone. 'push' will now fill them.")
    return 1 if kept else 0


def cmd_open(args) -> int:
    manifest = load_manifest()
    if not manifest.get("root_folder_id"):
        sys.exit("Not synced yet — run 'push' first.")
    print(f"https://drive.google.com/drive/folders/{manifest['root_folder_id']}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    forceable = {
        "push": "overwrite Docs that changed in Drive since the last sync",
        "pull": "overwrite local pages, DISCARDING local edits and restoring deletions",
        "reconcile": "accept a Doc as the sync point even if it already has content",
    }
    for name, fn in [("auth", cmd_auth), ("push", cmd_push), ("pull", cmd_pull),
                     ("status", cmd_status), ("open", cmd_open),
                     ("selftest", cmd_selftest), ("reconcile", cmd_reconcile)]:
        p = sub.add_parser(name)
        if name in forceable:
            p.add_argument("--force", action="store_true", help=forceable[name])
        p.set_defaults(fn=fn, force=False)
    args = ap.parse_args()
    return args.fn(args)


if __name__ == "__main__":
    raise SystemExit(main())
