# 7. Build runbook

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-14
- Status: **superseded** by [SETUP.md](SETUP.md); kept as a pointer so inbound links stay valid.

This page was the design-set build runbook for Wall-E, from nothing to Stage 0 of the ladder.
[SETUP.md](SETUP.md) superseded it as the one executable procedure: every phase here maps to a
SETUP phase (Phase 1 to SETUP Phases 1-5, 2 to 6-8, 3 to 9, 4 to 10 and §4, 5 to 11, 6 to 12,
12b and 12c, 7 to 13 and 13b, 8 to 14, 8b to 16 and [../eve/07-build-runbook.md](../eve/07-build-runbook.md)
Phases 8-9, 9 to §5 and Phase 17, 10 to Phase 18 and §6.1, the gotchas to §7, §1.2 and §0.3), and
SETUP carries the corrected commands and grants this page still lacked (two OAuth clients and the
super-admin action service, regional secrets, the full caller allowlist, the 52-test denial suite,
the corrected scheduler and deploy flags). The facts that existed only here (denial tests for
foreign callers and the catalogue lane, the consequence of deleting `WALLE_PROJECT` for Eve, Mo and
the Gemini Enterprise registration, and the K7 drill row) now live in SETUP. For the build, use
[SETUP.md](SETUP.md); for the checklist to clear before it, [PREREQUISITES.md](PREREQUISITES.md);
for the design it builds, [ARCHITECTURE.md](ARCHITECTURE.md).
