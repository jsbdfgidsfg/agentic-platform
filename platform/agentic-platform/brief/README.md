# Architecture brief — Secure Agentic Platform on Gemini Enterprise

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-15
- Maturity: complete first edition; the design it explains is not built

## What this is

The architecture document and project brief for the platform: about 200 A4 pages that explain the
**intent** behind the design. The design pages in this set and in the three agent sets say *what* is built;
this brief says *why*, for whom, at what cost, against which risks, and what the platform deliberately does
not do. It never copies a design table: it explains the idea and links to the canonical page that defines it.

The printed edition is [dist/secure-agentic-platform-brief.pdf](dist/secure-agentic-platform-brief.pdf),
built from these chapters. Edit the chapters here; rebuild the PDF from them.

## Reading paths

| Reader | Read |
|---|---|
| Executive sponsor | Chapter 1, then Part V |
| Security architect | Part I, Part II, Chapter 19 |
| Builder of the platform or of an agent | Parts II and III, then the document map |
| Data protection officer, works council | Chapters 1, 16, 20 and 22 |
| TISAX assessor | Chapters 1, 19, 21 and 23, then the document map |

## Contents

| Chapter |
|---|
| [0. About this document](00-front-matter.md) |
| **[Part I — Intent](01-part-i.md)** |
| [1. Executive summary](02-executive-summary.md) |
| [2. The objective and what it demands](03-objective.md) |
| [3. The problem and its risks](04-problem-and-risks.md) |
| [4. The principles](05-principles.md) |
| **[Part II — The platform](06-part-ii.md)** |
| [5. Architecture overview](07-architecture-overview.md) |
| [6. The Gemini Enterprise environment](08-gemini-enterprise-environment.md) |
| [7. Landing zone and the tier model](09-landing-zone-and-tiers.md) |
| [8. Identity, privileged access and the fleet kill switch](10-identity-and-privileged-access.md) |
| [9. Registry, governance and the autonomy contract](11-registry-and-autonomy-contract.md) |
| [10. Agent Gateway, Model Armor and the perimeter](12-gateways-model-armor-perimeter.md) |
| [11. Monitoring, detection and incident response](13-monitoring-detection-incident-response.md) |
| [12. Data, logging, retention and sovereignty](14-data-logging-retention-sovereignty.md) |
| [13. Supply chain, keys and recovery](15-supply-chain-keys-recovery.md) |
| [14. Scale and AGI readiness](16-scale-and-agi-readiness.md) |
| **[Part III — The agents](17-part-iii.md)** |
| [15. Wall-E, the doer](18-wall-e.md) |
| [16. Eve, the independent controller](19-eve.md) |
| [17. Mo, continuous improvement](20-mo.md) |
| [18. How the three work together](21-three-agents-together.md) |
| **[Part IV — Proof: threats, compliance and people](22-part-iv.md)** |
| [19. Threat model and residual risk](23-threat-model-and-residual-risk.md) |
| [20. EU AI Act](24-eu-ai-act.md) |
| [21. TISAX](25-tisax.md) |
| [22. Personal data, employees and the works council](26-personal-data-and-employees.md) |
| **[Part V — Delivery](27-part-v.md)** |
| [23. Operating model](28-operating-model.md) |
| [24. Roadmap and cost](29-roadmap-and-cost.md) |
| [25. Decisions awaiting the owner](30-decisions-awaiting-owner.md) |
| [A. Glossary](31-glossary.md) |
| [B. Document map](32-document-map.md) |

## Related
- [../README.md](../README.md) — the platform design set this brief explains
- [../01-hld.md](../01-hld.md) — the platform high-level design
- [../12-open-decisions.md](../12-open-decisions.md) — the decisions the brief says are still open
