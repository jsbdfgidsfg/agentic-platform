# Backlog & open questions

Things to decide, chase, or find out. Move to a real page once resolved.

| # | Item | Context | Status | Opened |
|---|---|---|---|---|
| 1 | Fill in the GCP project inventory | [platform/gcp-projects.md](platform/gcp-projects.md) is a skeleton | open | 2026-09-05 |
| 2 | Document the Gemini Enterprise tenant setup | [platform/gemini-enterprise.md](platform/gemini-enterprise.md) | open | 2026-09-05 |
| 3 | ~~Answer the 10 Edge AI v2 build decisions~~ | Superseded — reopened as Wall-E decisions | closed | 2026-09-05 |
| 4 | Ask Legal/DPO about DPIA + works council for **Wall-E** | Longest lead time in the plan. Two parts: reads now, autonomous writes before Stage 3 | open | 2026-09-05 |
| 5 | Verify the 7 console-dependent unknowns in the Wall-E design | [platform/wall-e/09-open-decisions.md](platform/wall-e/09-open-decisions.md) — 9 earlier unknowns are now closed | open | 2026-09-05 |
| 6 | Create the Drive OAuth client and run the first `wiki_sync.py push` | [_sync/README.md](_sync/README.md) | open | 2026-09-05 |
| 7 | Reconnect the Google Drive connector in Claude settings | Lets Claude read the published Docs directly | open | 2026-09-05 |
| 8 | **Answer the 5 blocking Wall-E decisions** | [platform/wall-e/09-open-decisions.md](platform/wall-e/09-open-decisions.md) — build cannot start without them | open | 2026-09-08 |
| 9 | Name a second operator and a second approver for Wall-E | Needed before any L4/L5 promotion; also removes the single-person approval bottleneck | open | 2026-09-08 |
| 10 | Ask Google account team: data retention after removing a licence on our plan | Gates licence reclaim from active accounts | open | 2026-09-08 |
| 11 | ~~Design Eve (controller)~~ | Done 2026-09-12: [platform/eve/](platform/eve/README.md), ten pages. Deterministic, no model in the authority path, observe-only until Wall-E Stage 4 | closed | 2026-09-08 |
| 12 | ~~Design Mo (continuous improvement)~~ | Done 2026-09-12: [platform/mo/](platform/mo/README.md), nine pages. No credential, no write path, every number re-derived by the merge gate | closed | 2026-09-08 |
| 13 | **Spike: can a keyless service account hold the Wall-E custom admin role?** | [platform/wall-e/14-hld-challenge.md](platform/wall-e/14-hld-challenge.md) decision 26. Google documents that any role but Super Admin can be assigned to a service account. If it covers Directory, Licensing and Reports, the password, hardware key, consent and stealable refresh token all disappear. Must run **before** the Phase 9 consent, which is irreversible. | open | 2026-09-12 |
| 14 | Ratify the catalogue breadth, and decide whether a request must fall inside the requester's own admin scope | [platform/wall-e/14-hld-challenge.md](platform/wall-e/14-hld-challenge.md) decisions 27 and 28. Both blocking: 27 before the scope list freezes, 28 before any operator who is not a super admin | open | 2026-09-12 |
| 16 | Reconcile Wall-E's set with the Eve and Mo designs | [platform/eve/08-contract-changes.md](platform/eve/08-contract-changes.md) — about twenty contradictions found inside Wall-E's own documents while designing Eve, including a signing key specified two ways and a query permission the challenge removed | open | 2026-09-12 |
| 17 | Decide whether Eve gets its own GCP project, and who the second person on it is | [platform/eve/09-open-decisions.md](platform/eve/09-open-decisions.md) — the project boundary is built now, but it is notional while one person holds both sides | open | 2026-09-12 |
| 15 | Apply the challenge's edit list to the Wall-E design set | [platform/wall-e/14-hld-challenge.md](platform/wall-e/14-hld-challenge.md) §8, about 40 edits across 12 pages. None changes the architecture | open | 2026-09-12 |
