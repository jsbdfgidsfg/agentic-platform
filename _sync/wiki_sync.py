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
WIKI_ROOT = Path(__file__).resolve().parent.parent
MANIFEST = Path(__file__).resolve().parent / "manifest.json"
TOKEN = Path.home() / ".config" / "wiki-sync" / "token.json"
CLIENT_SECRETS = Path(__file__).resolve().parent / "client_secret.json"

EXCLUDE_FILES = {"CLAUDE.md"}   # maintenance instructions for Claude, not team content

DOC_MIME = "application/vnd.google-apps.document"
FOLDER_MIME = "application/vnd.google-apps.folder"
ROOT_FOLDER_NAME = "Digital Workplace Wiki"


# --------------------------------------------------------------------------
# auth
# --------------------------------------------------------------------------

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
            TOKEN.write_text(creds.to_json())
            TOKEN.chmod(0o600)
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
    TOKEN.write_text(creds.to_json())
    TOKEN.chmod(0o600)
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
        return json.loads(MANIFEST.read_text())
    return {"root_folder_id": None, "folders": {}, "files": {}}


def save_manifest(m: dict) -> None:
    """Write atomically. The manifest is now saved after every created Doc, so an
    interrupted write is far likelier than it used to be — and a half-written
    manifest orphans every Doc it was supposed to record."""
    tmp = MANIFEST.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(m, indent=2, sort_keys=True) + "\n")
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
    """README.md in a subfolder becomes '<Folder> — Overview' so titles stay unique
    and readable in Drive search, which is flat."""
    stem = rel.stem.lstrip("_")
    section = _prettify(rel.parent.name) if rel.parent != Path(".") else ""
    if stem.lower() == "template" and section:
        return f"{section} — Template"
    if stem.upper() == "README":
        return "Wiki — Home" if not section else f"{section} — Overview"
    # Keep a numeric prefix as an ordering key: "01-hld" -> "01. HLD"
    m = re.match(r"^(\d+)[-_](.*)$", stem)
    if m:
        return f"{m.group(1)}. {_prettify(m.group(2))}"
    return _prettify(stem)


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
    r"\[([^\]]+)\]\(https://docs\.google\.com/document/d/([A-Za-z0-9_-]+)/edit\)")
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
            return f"[{label}](https://docs.google.com/document/d/{entry['file_id']}/edit)"
        # Unmapped target: keep the link intact rather than dissolving it to plain
        # words. Dropping it here made `pull` destroy the link permanently.
        return f"[{label}]({target}{anchor})"

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
        label, fid = m.group(1), m.group(2)
        target = by_id.get(fid)
        if not target:
            return m.group(0)   # a genuine Docs link someone added by hand: leave it
        return f"[{label}]({os.path.relpath(target, str(rel.parent))})"

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

def ensure_folder(svc, name: str, parent: str | None, manifest: dict, key: str) -> str:
    existing = manifest["folders"].get(key)
    if existing:
        try:
            svc.files().get(fileId=existing, fields="id,trashed").execute(num_retries=NUM_RETRIES)
            return existing
        except HttpError:
            pass  # deleted upstream; recreate below
    body = {"name": name, "mimeType": FOLDER_MIME}
    if parent:
        body["parents"] = [parent]
    fid = svc.files().create(body=body, fields="id").execute(num_retries=NUM_RETRIES)["id"]
    manifest["folders"][key] = fid
    return fid


def ensure_tree(svc, manifest: dict) -> None:
    root = ensure_folder(svc, ROOT_FOLDER_NAME, None, manifest, ".")
    manifest["root_folder_id"] = root
    for rel in {p.relative_to(WIKI_ROOT).parent for p in local_pages()}:
        if str(rel) == ".":
            continue
        parent = root
        acc = Path(".")
        for part in rel.parts:
            acc = acc / part
            parent = ensure_folder(svc, _prettify(part), parent,
                                   manifest, str(acc))


def remote_modified(svc, file_id: str) -> str | None:
    try:
        return svc.files().get(fileId=file_id, fields="modifiedTime").execute(num_retries=NUM_RETRIES)["modifiedTime"]
    except HttpError:
        return None


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

    # Pass 1 — every page must have an id before links can be rewritten.
    for path in pages:
        rel = str(path.relative_to(WIKI_ROOT))
        entry = manifest["files"].setdefault(rel, {})
        if entry.get("file_id"):
            continue
        parent = manifest["folders"][str(path.relative_to(WIKI_ROOT).parent)]
        created = svc.files().create(
            body={"name": doc_title(path.relative_to(WIKI_ROOT)),
                  "parents": [parent], "mimeType": DOC_MIME},
            fields="id").execute(num_retries=NUM_RETRIES)
        entry["file_id"] = created["id"]
        # Save after EVERY create. Saving once at the end of the loop meant a crash
        # or a network timeout mid-loop orphaned every Doc created so far, with no
        # local record of its id. That happened on 2026-09-08.
        save_manifest(manifest)
        print(f"created  {rel}")

    # Pass 2 — content, with links now resolvable.
    changed = skipped = 0
    for path in pages:
        rel = str(path.relative_to(WIKI_ROOT))
        entry = manifest["files"][rel]
        raw = path.read_text()
        local_hash = sha(raw)

        if entry.get("local_hash") == local_hash and not args.force:
            skipped += 1
            continue

        remote_ts = remote_modified(svc, entry["file_id"])
        if (entry.get("remote_modified") and remote_ts
                and remote_ts != entry["remote_modified"] and not args.force):
            print(f"CONFLICT {rel}: changed in Drive since last sync. "
                  f"Run 'pull' first, or push with --force to overwrite.")
            continue

        body = transform_for_docs(raw, Path(rel), manifest)
        with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as fh:
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
        print(f"pushed   {rel}")

    save_manifest(manifest)
    print(f"\n{changed} pushed, {skipped} unchanged.")
    print(f"Drive folder: https://drive.google.com/drive/folders/{manifest['root_folder_id']}")
    return 0


def cmd_pull(args) -> int:
    svc = drive()
    manifest = load_manifest()
    pulled = withheld = 0
    for rel, entry in sorted(manifest["files"].items()):
        fid = entry.get("file_id")
        if not fid:
            continue
        remote_ts = remote_modified(svc, fid)
        if remote_ts == entry.get("remote_modified") and not args.force:
            continue

        buf = io.BytesIO()
        downloader = MediaIoBaseDownload(
            buf, svc.files().export_media(fileId=fid, mimeType="text/markdown"))
        done = False
        while not done:
            _, done = downloader.next_chunk()
        text = transform_from_docs(buf.getvalue().decode("utf-8"), Path(rel), manifest)

        path = WIKI_ROOT / rel
        path.parent.mkdir(parents=True, exist_ok=True)

        # Refuse to overwrite the authoring copy with something we could not fully
        # reverse. Leftover Docs artefacts mean the inverse transform did not match,
        # and writing anyway would destroy diagrams or links that only exist here.
        residue = []
        if "docs.google.com/document/d/" in text:
            residue.append("unresolved Google Docs links")
        if "**Diagram (Mermaid).**" in text:
            residue.append("un-restored mermaid diagram")
        if residue:
            sidecar = path.with_suffix(".pulled.md")
            sidecar.write_text(text)
            print(f"WITHHELD {rel}: {', '.join(residue)}. "
                  f"Wrote {sidecar.relative_to(WIKI_ROOT)} instead; merge it by hand.")
            withheld += 1
            continue

        path.write_text(text)
        entry["local_hash"] = sha(text)
        entry["remote_modified"] = remote_ts
        pulled += 1
        print(f"pulled   {rel}")
        save_manifest(manifest)
    save_manifest(manifest)
    print(f"\n{pulled} pulled, {withheld} withheld. "
          f"Review with 'git diff' before committing.")
    return 0


def cmd_status(args) -> int:
    svc = drive()
    manifest = load_manifest()
    tracked = set(manifest["files"])
    local = {str(p.relative_to(WIKI_ROOT)) for p in local_pages()}

    for rel in sorted(local - tracked):
        print(f"new locally      {rel}")
    for rel in sorted(tracked - local):
        print(f"gone locally     {rel}  (doc still in Drive)")
    for rel in sorted(local & tracked):
        entry = manifest["files"][rel]
        local_changed = sha((WIKI_ROOT / rel).read_text()) != entry.get("local_hash")
        remote_changed = remote_modified(svc, entry["file_id"]) != entry.get("remote_modified")
        if local_changed and remote_changed:
            print(f"BOTH changed     {rel}")
        elif local_changed:
            print(f"local changed    {rel}")
        elif remote_changed:
            print(f"Drive changed    {rel}")
    print("\nnothing else differs.")
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
        text = path.read_text()
        if not round_trips(text, rel, manifest):
            bad.append(str(rel))
    for rel in bad:
        print(f"LOSSY    {rel}")
    print(f"\n{len(pages) - len(bad)}/{len(pages)} pages round-trip losslessly.")
    return 1 if bad else 0


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
    for name, fn in [("auth", cmd_auth), ("push", cmd_push), ("pull", cmd_pull),
                     ("status", cmd_status), ("open", cmd_open),
                     ("selftest", cmd_selftest)]:
        p = sub.add_parser(name)
        p.add_argument("--force", action="store_true",
                       help="ignore change detection and conflict guards")
        p.set_defaults(fn=fn)
    args = ap.parse_args()
    return args.fn(args)


if __name__ == "__main__":
    raise SystemExit(main())
