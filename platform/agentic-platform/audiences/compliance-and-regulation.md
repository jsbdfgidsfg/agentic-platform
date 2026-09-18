# Compliance and regulation — the EU AI Act, TISAX and GDPR position of the agentic platform

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-18
- Who it is for: compliance, legal, the data protection officer (DPO), the information security management system's owner (the ISMS) and the AI compliance owner — a role the design creates and that nobody yet holds.
- What it asks of them: name the AI compliance owner; sign the DPO record on monitoring named administrators before any monitoring starts; answer the D7 letter's fourth question — information, consultation or consent, and by when — within the DPO's and HR's own turnaround, and before any Eve feed; decide by 2026-12-01 whether any assessment is ordered under the outgoing TISAX catalogue; sign Wall-E's intended purpose with legal before its first write; supply the legal entity; and accept the calendar in section 13 as the compliance calendar of the programme.
- What is true on 2026-09-18: nothing is built, nothing is registered, no legal entity has signed anything, and no price is quoted anywhere in the design ([../README.md#status](../README.md#status)). Every date after 2026-09-24 in this document is `Assumption:` — a plan figure, not a commitment.

---

## 1. What this document is, and the honesty it keeps

The platform is a design for a secure Gemini Enterprise environment on Google Cloud and Google Workspace hosting three agents: Wall-E, an administration assistant that acts on a human's prompt through a dedicated licensed Workspace user account holding Super Admin — the Workspace role with every administrative power, which Google cannot limit to part of the organisation or to a subset of its powers; Eve, a controller that watches Wall-E and every human super admin and reports to a human, without Super Admin; and Mo, an improver that measures both and proposes changes ([../01-hld.md#13-the-three-agents-on-the-platform](../01-hld.md#13-the-three-agents-on-the-platform)). Giving a robot Super Admin is the platform owner's decision of 2026-09-13 (P33); this document designs around it and does not re-argue it ([../../../decisions/2026-09-13-wall-e-holds-super-admin.md](../../../decisions/2026-09-13-wall-e-holds-super-admin.md)).

Three things the objective asked for are declined or qualified, and a compliance reader should know them first. "EU AI Act bulletproof" is declined as a promise: the design gives mechanisms and evidence and lists what the regulator or the guidelines still decide ([../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean)). "TISAX compatible" is qualified: an assessor may refuse the target maturity on the least-privilege control because a machine holds Super Admin, however good the compensation ([../11-tisax.md#0-what-this-page-decides-in-one-paragraph](../11-tisax.md#0-what-this-page-decides-in-one-paragraph)). "Eve independent" is qualified: inside the organisation's own Google Cloud organisation Eve's independence is detective, not structural; only the witness organisation — a second, separate Google organisation run by IT security that holds Eve's evidence copy, incident record and pager — makes it structural ([../01-hld.md#132-eve--independent-controller-two-paths-a-witness-outside-the-tenant-a-second-human](../01-hld.md#132-eve--independent-controller-two-paths-a-witness-outside-the-tenant-a-second-human)).

The standing constraints no document may loosen, restated exactly: no domain-wide delegation, ever; no model holds a credential or produces an approval, a signature, a halt, a veto or a refusal; the action service is the only credential holder; a dry run never mutates; humans raise autonomy and machines lower it; Mo reaches production only through a merged pull request ([../01-hld.md#status](../01-hld.md#status)). The action service is the deterministic code that holds the credential, decides, audits and executes; the model never touches the credential. A dry run is an execution mode that records what would have happened and never mutates, even when handed a valid approval.

Two numbers do not exist and this document does not invent them: no benefit figure exists until four weeks of toil on the top three administrative tasks are measured before Wall-E's first phase, and no price exists because the pricing pages have not been read ([../brief/02-executive-summary.md#why-build-it-and-how-the-programme-can-stop](../brief/02-executive-summary.md#why-build-it-and-how-the-programme-can-stop); [../01-hld.md#05-cost-classes](../01-hld.md#05-cost-classes)).

---

## 2. The EU AI Act: the regulatory state on 2026-09-18

The EU AI Act is Regulation (EU) 2024/1689 ("the Act"), amended by Regulation (EU) 2026/1744, the Digital Omnibus on AI ("the Omnibus"). The design pages verified the state on 2026-09-13; [the cross-check review of 2026-09-18](../14-crosscheck-review.md#51-the-regulatory-state-on-2026-09-18-with-corrections) (section 5.1) re-verified every date and quotation at its source and changed the status of three rows, marked below. Article numbers are the Act's as amended ([../10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13](../10-eu-ai-act.md#1-the-regulatory-state-on-2026-09-13)).

| Item | State on 2026-09-18 | Change on re-verification |
|---|---|---|
| The Act | In force 2024-08-01; general application 2026-08-02; Chapters I–II (Art. 4 literacy, Art. 5 prohibitions) since 2025-02-02; Chapter V (general-purpose AI), governance and penalties since 2025-08-02 | confirmed |
| The Omnibus | Adopted 2026-07-08, published 2026-07-24, in force 2026-07-27; **Annex III high-risk obligations apply from 2027-12-02**; Annex I product-embedded systems from 2028-08-02; the deferral is a fixed date, not conditional on standards | confirmed; legal reads the Official Journal text once for the Annex I date, which one secondary summary rendered differently |
| Art. 4 AI literacy | "Measures to support the development of AI literacy" of staff operating AI systems; an obligation since 2025-02-02 | confirmed |
| Art. 5 prohibitions | Since 2025-02-02; the Omnibus adds a prohibition on non-consensual intimate material and child sexual abuse material from 2026-12-02 | confirmed |
| Art. 50 transparency | Applies since 2026-08-02; a transition to 2026-12-02 for Art. 50(2) marking of systems already on the market; final Commission guidelines 2026-07-20 | confirmed; the guidelines' exact wording on agents disclosing their principal is still unread by anyone |
| Art. 6(3) derogation, Art. 6(4) documentation, Art. 49(2) registration | Unchanged in substance; profiling of natural persons removes the derogation; registration in the EU database (Art. 71, since 2026-08-02) before putting into service; Annex VIII Section B points 7 and 9 deleted | **status changed**: the Commission proposed deleting the Art. 49(2) registration for derogation systems and the co-legislators rejected the deletion, so the design's rule "registration before the first write" stands and the page's "unverified" row closes with the date 2026-09-18 |
| Commission guidelines on Art. 6 classification | **Draft**, published 2026-05-19; consultation closed 2026-07-23; final expected end 2026 | confirmed still draft; the 90-day re-run trigger (P132) stays armed |
| Harmonised standards | **None cited in the Official Journal**; no presumption of conformity exists; EN 18286 is at formal vote and no EN is published | **wording corrected**: the page's "first to reach final approval" overstates by one stage |
| Penalties (Art. 99) | Art. 5 up to EUR 35 M or 7 % of worldwide turnover; other operator obligations including Art. 50 up to EUR 15 M or 3 %; incorrect information to authorities up to EUR 7.5 M or 1 % | confirmed |
| GDPR interplay | Art. 4(4) profiling; Art. 22 solely automated decisions; Art. 88(2) names "monitoring systems at the work place" | confirmed and quoted |

Nothing in the Omnibus touched Art. 26(7) (worker information), Art. 27 (fundamental-rights impact assessment, which the design reads as not applying to a private organisation), Art. 72 or Art. 73. If the final Art. 6 guidelines land in December 2026 as expected, the 90-day re-run falls in the first quarter of 2027 — before Wall-E's first write on the full build's own calendar, so the assessment is signed once, against the final text.

---

## 3. Provider and deployer

Under the Act the provider puts a system into service under its own name and the deployer uses it under its authority. The organisation is both for Wall-E and Mo; Google is provider of the Gemini models and of the Gemini Enterprise application and the organisation their deployer; Eve's control path is not an AI system ([../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer](../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer)).

| System | Provider | Deployer | Note |
|---|---|---|---|
| Wall-E | the organisation | the organisation | provider **and** deployer; one owner reports |
| Mo | the organisation | the organisation | minimal risk; no registration |
| Eve control path | — | — | not an AI system; recorded as an oversight measure |
| `eve-advisor` (report-only narration, if built) | the organisation | the organisation | class *tbd* (P19, legal) |
| Gemini models | Google, as general-purpose AI model provider | the organisation | the platform never trains, fine-tunes or modifies a model |
| Gemini Enterprise application | Google | the organisation | deployer duties only |

The legal entity that signs and registers is P23 (*tbd*, legal; `Assumption:` the employing entity). Two role traps are recorded: any model modification reopens Chapter V and Art. 25; publishing an agent through Gemini Enterprise does not make the organisation the provider of Gemini Enterprise ([../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer](../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer)).

---

## 4. Classification of each system

The register — one file in version control that every agent needs a row in before it may exist — carries a class per row from a fixed vocabulary: `not_ai_system`, `minimal`, `limited_art50`, `annex_iii_adjacent`, `high_risk`. The admission gate refuses production without a class, a role, a signed purpose and, per class, the Art. 6(4) assessment and the Art. 49 registration id (P75) ([../10-eu-ai-act.md#36-the-platform-and-every-future-agent--the-gate-not-a-page-platform](../10-eu-ai-act.md#36-the-platform-and-every-future-agent--the-gate-not-a-page-platform)).

| System | Class | Basis |
|---|---|---|
| Wall-E | `annex_iii_adjacent`, role `both`, registration `pending` | the Art. 6(3) derogation claimed on the declared purpose; CI refuses `status: prod` while registration is pending ([../10-eu-ai-act.md#31-wall-e-wall-e](../10-eu-ai-act.md#31-wall-e-wall-e)) |
| Eve control path | `not_ai_system` | rules defined solely by humans; CI forbids a model client; the Vertex AI service is denied in Eve's project — an invariant, not an argument ([../10-eu-ai-act.md#32-eve-control-path--not-an-ai-system-as-an-invariant-eve](../10-eu-ai-act.md#32-eve-control-path--not-an-ai-system-as-an-invariant-eve)) |
| `eve-advisor` | *tbd* (P19) | interim rules: no registration, pages at severity 2 only, no finding about a named human without the deterministic rule that triggered it ([../10-eu-ai-act.md#33-eve-advisor--class-tbd-p19-interim-rules-eve-advisor](../10-eu-ai-act.md#33-eve-advisor--class-tbd-p19-interim-rules-eve-advisor)) |
| Mo | `minimal`, role `both` | it grades plans, not people; model-drafted prose carries the "agent-authored" label ([../10-eu-ai-act.md#34-mo--minimal-risk-mo](../10-eu-ai-act.md#34-mo--minimal-risk-mo)) |
| Gemini Enterprise and the models | deployer duties | the Art. 25(4) written position with Google is P32, open ([../10-eu-ai-act.md#35-gemini-enterprise-app-and-the-gemini-models--deployer-duties-and-the-gpai-one-liner-gemini](../10-eu-ai-act.md#35-gemini-enterprise-app-and-the-gemini-models--deployer-duties-and-the-gpai-one-liner-gemini)) |
| The platform itself | infrastructure, not an AI system | every future agent is its own Art. 6 question and register row ([../10-eu-ai-act.md#36-the-platform-and-every-future-agent--the-gate-not-a-page-platform](../10-eu-ai-act.md#36-the-platform-and-every-future-agent--the-gate-not-a-page-platform)) |

### 4.1 Wall-E's Art. 6 argument, in plain words

Annex III of the Act lists the high-risk uses; point 4(b) covers systems intended to make decisions affecting terms of work-related relationships, termination, task allocation by behaviour, and the monitoring and evaluation of persons at work. Art. 6(3) exempts a system in an Annex III area that does not pose a significant risk because it performs a narrow procedural task (condition (a)), improves the result of a completed human activity (b), detects patterns without replacing human assessment (c) or performs a preparatory task (d) — unless it profiles natural persons ([../10-eu-ai-act.md#312-annex-iii-4b-family-by-family](../10-eu-ai-act.md#312-annex-iii-4b-family-by-family)).

The Act classifies a system by what its provider says it is *for*, not by what its account *could* do. Wall-E's declared intended purpose is the catalogue: on a named operator's request or a catalogued trigger it executes explicitly-targeted administration operations — group membership, profile and organisational-unit fields, licences, templated notices, and the suspension or restoration of an account only when HR or a named operator has already decided that. It never decides who leaves, who is promoted, who is monitored or how anyone performs, and never selects persons by behaviour ([../10-eu-ai-act.md#311-the-declared-intended-purpose-the-sentence-the-assessment-rests-on](../10-eu-ai-act.md#311-the-declared-intended-purpose-the-sentence-the-assessment-rests-on)). So it sits next to, not inside, 4(b); the provider claims the derogation, writes the Art. 6(4) assessment before the first write, registers under Art. 49(2), and adopts Art. 9–15 voluntarily so that a change of reading costs a document, not a programme. Super Admin does not change the classification — purpose is declared by the provider — but it changes the evidence burden: the draft guidelines refuse a purpose the positioning contradicts, and an account that can do everything is a positioning fact ([../10-eu-ai-act.md#315-two-things-super-admin-does-and-does-not-change](../10-eu-ai-act.md#315-two-things-super-admin-does-and-does-not-change)). The purpose paragraph is therefore identical in five places — register row, manifest, agent card, Gemini Enterprise description, operator instructions — one paragraph, one hash, compared by CI (P125).

The one family that could carry profiling, licence reclaim by inactivity, is redesigned so that **no AI output selects a person by behaviour**: the inactivity report is a read artefact for a human; `F7-inactive` targets come only from ids a human supplied; CI and the action service refuse report-derived targets; if legal answers "profiling" (P18) the design recommends removing the family rather than reclassifying Wall-E high-risk (P126) ([../10-eu-ai-act.md#314-the-profiling-question-answered-by-design-p126](../10-eu-ai-act.md#314-the-profiling-question-answered-by-design-p126)).

### 4.2 The weakest point

The account can do everything, and the draft guidelines (paragraph 12) require a purpose described coherently across all materials and no narrower than the positioning. Band B — "any Admin SDK method, fully specified by one human super admin and approved by another" — is inside the declared purpose. A market surveillance authority could read that as "the intended purpose is any administration action, with supervision", which collapses the narrow-task reading. The design's answers are real — the hard-denied list in code owned outside the agent repository, band B permanently at level L3 with two humans and a mandatory decision reference on natural-person targets, the reconciled count of robot admin events outside the catalogue with target zero — but they are evidence of *behaviour*, and the guidelines test *purpose as stated*. The design itself names the Super Admin grant as the fact most likely to be held against the narrow-task reading ([../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean), R4).

Two smaller weaknesses sit behind it. The suspension family F5 is stated as resting primarily on condition (b), "improves the result of a previously completed human activity", whose examples in Recital 53 are language improvement of drafted documents; executing a suspension improves nothing, it carries a decision out, which fits condition (a) better. Legal should sign the assessment with (a) primary for F5 and (b) at most secondary. And the whole claim is signed against draft guidelines, which the page says itself ([../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean](../10-eu-ai-act.md#6-what-bulletproof-can-and-cannot-mean), R1).

---

## 5. The obligations that bite now, and from the dates the pages state

| When | Obligation | Mechanism on the platform | Evidence |
|---|---|---|---|
| Now (since 2025-02-02) | Art. 4 literacy: a one-page briefing per role, attendance recorded, refreshed at each stage transition; one record with TISAX training | ISMS training records | E-13 |
| Now (since 2025-02-02) | Art. 5: the dated negative determination of 2026-09-13, re-signed by legal, re-run per family addition; nothing generates images, video or audio | part of the Art. 6(4) file | E-01 |
| Now (since 2026-08-02) | Art. 50: the action service, never the model, prepends a fixed disclosure line and appends a signature block to every free-text message and sets a fixed mail header; a message without the line is refused; marking of model text is provider-side and unverified (P128) | CI content test | E-15 |
| Before Wall-E's first write (Stage 1) | Art. 6(4) assessment signed by legal, the profiling part by the DPO; Art. 49(2) registration id in the row; no signed assessment ⇒ no `prod` ⇒ no write | the admission gate | E-01, E-02 |
| Before Stage 1 | Art. 26(7), 26(11), Art. 86: worker information pack and employee notice dated, the explanation log existing (P129) — under GDPR Art. 88 and national law now, Art. 26(7) voluntarily now | the Stage 1 checklist | E-12 |
| Before each stage | Art. 11: the documentation freeze (section 7) | the stage snapshot tag | E-05 |
| Continuous, voluntary | Art. 9–15: risk management with a fundamental-rights column, testing data governance, logging at 400 days, instructions for use, oversight caps per family, accuracy and robustness | the ladder, Mo, Eve | E-03 to E-09 |
| Voluntary until any row is `high_risk` | Art. 72 post-market monitoring (Mo's artefacts are the plan); Art. 73 serious-incident reporting at 15, 10 and 2 days, assessed by the incident commander and legal within 24 hours (P101) | the case system | E-09, E-10 |
| 2026-12-02 | Art. 5 additions and the end of the Art. 50(2) transition: no effect on this platform | a note on the page | — |
| End 2026 (expected) | Final Art. 6 guidelines: every `annex_iii_adjacent` assessment re-run within 90 days; rows `suspended` until re-signed (P132) | the reclassification trigger list | E-01 new version |
| 2027-12-02 | Annex III obligations bind: for any `high_risk` row the full Chapter III programme becomes mandatory; for `annex_iii_adjacent` rows nothing new binds but the classification file must be current against the final guidelines | the same trigger list | E-01 refresh; E-14 only if `high_risk` |

Level caps the compliance position sets and that the ladder enforces (P127): F5 suspend at most L4 and only on the HR-system event, with holds that never expire outside business hours; F5 on chat or schedule at most L3; F6 restore L3 permanently; `F7-inactive` L3 until P18 is answered and the selection never automated at any level; band B permanently L3 ([../10-eu-ai-act.md#312-annex-iii-4b-family-by-family](../10-eu-ai-act.md#312-annex-iii-4b-family-by-family)). Levels are the autonomy ladder's six steps L0 (off) to L5 (autonomous with independent verification); stages S0 to S5 are the calendar of earning them; humans raise, machines lower ([../../wall-e/05-autonomy-ladder.md#stage-overview](../../wall-e/05-autonomy-ladder.md#stage-overview)).

---

## 6. The evidence register

What an authority, an assessor or the works council is shown, where it lives, who produces it and for how long ([../10-eu-ai-act.md#5-evidence-register](../10-eu-ai-act.md#5-evidence-register)). A missing E-01, E-02, E-05, E-07, E-12 or E-13 blocks the stage it belongs to; the rest are findings.

| Id | Evidence | Produced by | Kept |
|---|---|---|---|
| E-01 | Art. 6(4) assessment per `annex_iii_adjacent` system, with the Art. 5 and Art. 27 determinations and the profiling answer | legal, DPO, AI compliance owner | 10 years |
| E-02 | Art. 49 registration id and the Annex VIII fields | the provider entity; platform owner | 10 years |
| E-03 | Promotion records with the Art. 9 residual-risk statement; the fundamental-rights rows of the risk register | agent owner, security reviewer | 10 years |
| E-04 | Testing data and fixtures with the bias note | Mo owner, agent owner | 400 days; 10 years in the snapshot |
| E-05 | Technical documentation: the stage snapshot tag and bundle, the Annex IV index | platform owner | 10 years |
| E-06 | The Art. 12 log: the audit dataset plus frozen plans, daily export, witness copy | the action service | 400 days |
| E-07 | Instructions for use with declared accuracy; the scorecard history | agent owner; Mo | 10 years; 400 days |
| E-08 | Oversight roster with training records; kill-switch drill records; veto-window statistics | ISMS; platform owner; Mo | 10 years; 400 days |
| E-09 | Post-market monitoring artefacts; the audit-completeness metric | Mo | 10 years |
| E-10 | Incident cases with the Art. 73 flag, reports filed, tabletop records | incident commander; AI compliance owner | 10 years; 400 days |
| E-11 | Supplier file: Google's model documentation per pin, the Art. 25(4) position | platform owner, legal | 10 years |
| E-12 | Worker information pack and its date; employee notice; explanation-request log | HR, DPO | 10 years; 400 days |
| E-13 | Art. 4 briefing content per role and attendance | AI compliance owner, ISMS | 10 years |
| E-14 | Only if `high_risk`: the Annex VI record, the EU declaration of conformity, the quality-management mapping | legal, ISMS | 10 years |
| E-15 | Art. 50 block per agent; the CI content-test result | agent owner; platform owner | 400 days; 10 years |

Who owns the register: the AI compliance owner, who walks the table quarterly and opens one item per missing artefact. The full build proves each id has a producer and applies the blocking rule ([../setup/42-gates-drills-and-evidence.md#gd-42-the-eu-ai-act-mapping-every-e-xx-has-a-producer](../setup/42-gates-drills-and-evidence.md#gd-42-the-eu-ai-act-mapping-every-e-xx-has-a-producer)).

---

## 7. The documentation freeze, the registration, and the high-risk fallback held ready

**The freeze (P130).** Art. 11 needs the documentation as put into service, not a live wiki. Before a stage opens, CI tags the wiki `compliance/<agent>/S<n>/<date>` and copies the tagged tree to the evidence bucket as a locked ten-year record; the Annex IV crosswalk on the EU AI Act page is its index. The autonomy ladder is declared the Annex IV 2(f) record of pre-determined changes, so a promotion within manifest ceilings is not a substantial modification. Art. 11 is **not met** until the three agent sets carry the platform's values: on 2026-09-18 they still carry unapplied edits (P143), and a documentation set that diverges from the system is a finding in itself ([../10-eu-ai-act.md#43-art-11--the-annex-iv-crosswalk-and-the-documentation-freeze-p130](../10-eu-ai-act.md#43-art-11--the-annex-iv-crosswalk-and-the-documentation-freeze-p130)). In the full build the first tag is made by hand and recorded as a dated deviation, because no platform CI exists yet ([../setup/42-gates-drills-and-evidence.md#gd-44-the-stage-snapshot-tag-by-hand-e-05--partly-blocked-on-b-03](../setup/42-gates-drills-and-evidence.md#gd-44-the-stage-snapshot-tag-by-hand-e-05--partly-blocked-on-b-03)).

**The registration.** Art. 49(2) registration in the EU database by the P23 entity, with the Annex VIII Section B fields as amended, before putting into service — for Wall-E the first write. The EU database has no API the platform reads, so a registration id that stops resolving is a quarterly review item ([../10-eu-ai-act.md#313-art-64-assessment--the-document-its-content-its-owner](../10-eu-ai-act.md#313-art-64-assessment--the-document-its-content-its-owner)).

**The fallback held ready.** If legal reads band B as widening the purpose, or the final guidelines do, Wall-E becomes `high_risk` and the full Chapter III programme applies by 2027-12-02: Annex VI internal control, an EU declaration of conformity kept ten years, a digital CE marking on the operator surface, Art. 49(1) registration, and the quality management system built on the ISMS (Art. 17), which the design keeps mapped but unbuilt until a row needs it ([../10-eu-ai-act.md#49-art-17--the-quality-management-system-held-ready](../10-eu-ai-act.md#49-art-17--the-quality-management-system-held-ready)). What cannot be leaned on in that case: a harmonised standard, since none is cited.

---

## 8. TISAX

TISAX is the automotive industry's information-security assessment, governed by the ENX Association on behalf of the VDA; the questionnaire is the VDA ISA. A label is earned by a site's assessment, never by a platform; the design makes the platform assessable inside the site's ISMS at maturity 3 ("established": defined, documented, followed) on every applicable control ([../11-tisax.md#2-the-target--label-level-scope-catalogue-p133](../11-tisax.md#2-the-target--label-level-scope-catalogue-p133)).

### 8.1 Catalogue and version in force, and the ISA 6 versus ISA2027 timing

| Fact | Value on 2026-09-18 |
|---|---|
| Catalogue in force | VDA ISA 6.0.3, published 2024-04-25 |
| Successor | VDA ISA2027, published 2026-07-01; the basis of assessments ordered from 2027-01-01; assessments ordered before 2027-01-01 may still run on ISA 6; the last order date under ISA 6 is 2026-12-31; a redline was published 2026-08-07 |
| What ISA2027 changes | supplier verification for high protection needs "through a TISAX label, an equivalent third-party assessment, or an appropriate supplier audit" (three routes; the design accepts a supplier audit only at high protection need, never at very high — a design choice stricter than the catalogue); a rationale per "aspects considered" item; annual versions effective each 1 January |
| Control numbering | `Assumption:` unchanged in the information-security module ("same 46 controls, 44 edited" on the page; one secondary source counts 43 revised controls); the ISMS confirms on the redline when it orders |
| Validity of a result | three years |

Sources: [../11-tisax.md#1-tisax-on-2026-09-13-verified](../11-tisax.md#1-tisax-on-2026-09-13-verified), re-verified on the ENX pages by [the cross-check review of 2026-09-18](../14-crosscheck-review.md#51-the-regulatory-state-on-2026-09-18-with-corrections) (section 5.1).

**The decision the ISMS owes by 2026-12-01.** The design assumes every assessment covering the platform is ordered in 2027 or later and maps against ISA2027 with a 6.0.3 cross-reference. The ISMS may renew the site's label under ISA 6 before 2026-12-31 for its own reasons. Trade-off: ISA 6 is the known catalogue and keeps a site renewal on its current cycle, but the platform has no built controls in 2026 and would fail maturity 3 on almost every row; ISA2027 adds the supplier-verification rule, which Google's own TISAX result already satisfies for Google, and the rationale rule, which the design's recorded rejected alternatives already meet. Recommendation: order nothing for the platform in 2026; if the site renews before 2026-12-31 for its own reasons, list the platform out of scope (or in scope at documentation maturity only, with the TISAX page as the statement) and re-scope it at the next ISA2027 order. The decision is a dated line in the legal register ([../11-tisax.md#11-the-legal-and-contractual-register-p141](../11-tisax.md#11-the-legal-and-contractual-register-p141)).

### 8.2 Label, level, module scope, shared responsibility

| Element | Decision (P133, P134, P135) |
|---|---|
| Label | **Confidential** (`Assumption:`; Strictly confidential only if the ISMS classes the audit dataset, the content logs, the identity logs or conversation history as secret, which also raises the level to AL3 and reopens the encryption and sovereignty decisions); no availability label |
| Assessment level | **AL2** — plausibility check with evidence review and a web-conference interview; AL2.5 (full remote) accepted if the audit provider proposes it |
| Scope location | *tbd* — the ISMS of the site that operates the platform; Google Cloud, the witness organisation and every third party are external IT services of that scope, never scope locations |
| Module scope | the Information Security module in full; the Data Protection module (9.x) is **not** an assessment objective — the organisation is controller and the platform its internal processing — but is the DPO's checklist; it becomes an objective for any hosted agent processing a customer's or OEM's data as processor, enforced by a register field `tisax_dp_scope`; Prototype Protection does not apply (negative determination dated 2026-09-13) |
| Google | one external IT service with two contractual halves; a TISAX participant under ENX scope id SYN0NK and assessment ids ATTRRN-1 and -2, retrievable only over the ENX portal, with labels for data classified as secret, per region with `europe-west1` inside; **no individual Google service is named**, so per-service coverage is *tbd* and is closed only from the ENX result share the ISMS requests, never from the public page (P32, P135) |
| NIS2 | applicability *tbd* — the ISMS's determination; recorded in the legal register |

Sources: [../11-tisax.md#2-the-target--label-level-scope-catalogue-p133](../11-tisax.md#2-the-target--label-level-scope-catalogue-p133); [../11-tisax.md#3-module-scope--data-protection-and-prototype-protection-p134](../11-tisax.md#3-module-scope--data-protection-and-prototype-protection-p134); [../11-tisax.md#43-the-supplier-file--google](../11-tisax.md#43-the-supplier-file--google). The per-control split — which of Google, the platform or the ISMS the assessor asks first — is a dated table re-dated within 30 days of any Google service change ([../11-tisax.md#42-the-responsibility-split-per-control-group](../11-tisax.md#42-the-responsibility-split-per-control-group)).

### 8.3 The super-admin deviation record, and what it says

A machine account holds Super Admin, which cannot be scoped, so control **4.2.1 least privilege** is deviated from; 4.1.2 privileged authentication and 5.2.4 privileged-activity logging are met, not deviated ([../11-tisax.md#61-what-the-deviation-is-in-isa-terms](../11-tisax.md#61-what-the-deviation-is-in-isa-terms)). The deviation record is one file — the decision record of 2026-09-13 — with sections Decision, Deviation statement, Residual risk, Compensating controls, Precondition rule, Review and Signatures, and three signatories: the platform owner decides, the security reviewer signs (a person who is not the platform owner; control 1.2.2 forbids self-signature), the ISMS enters it in the site's risk register. It expires with the assessment result, three years ([../11-tisax.md#62-the-record--decisions2026-09-13-wall-e-holds-super-adminmd](../11-tisax.md#62-the-record--decisions2026-09-13-wall-e-holds-super-adminmd)).

What it says, in substance: a leaked token or an interactive login on the robot account is a tenant compromise with a path into the Google Cloud organisation, including Eve's project; the perimeter is custody, scope split, detection latency and the witness; the thirteen compensations are preconditions of the grant, none deferred, and four checklist rows are added — the penetration test with no open critical or high finding, the DPIA and works-council information, the crisis tabletop, witnessed hardware-key custody ([../11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads](../11-tisax.md#63-compensations-as-preconditions--the-checklist-the-gate-reads)). After the grant any row turning red is a severity-2 finding with a 30-day window; two rows red at once, or the detection, hygiene or second-human row red at all, is severity 1 and a human removes Super Admin from the robot until green — "the role exists only while its compensations do".

Three alignments the register row P136 and the pages need, resolved in favour of the decision record, which is append-only: the record is *reviewed* quarterly with the roster review and *re-signed* at every Wall-E stage transition, whenever a compensation's grade changes and on any severity-1 credential incident (P136's "re-signed quarterly" is the looser wording); the gate-condition list in P136 carries the DPIA and the works-council information that the checklist already carries; and risk row R-01's owner and signatory is the security reviewer, the platform owner decides and accepts the residual, the ISMS enters it (the TISAX page names the platform owner as owner) ([../../../decisions/2026-09-13-wall-e-holds-super-admin.md](../../../decisions/2026-09-13-wall-e-holds-super-admin.md); [../11-tisax.md#10-the-risk-register-p140](../11-tisax.md#10-the-risk-register-p140)).

On 2026-09-18 the signatures are pending: the security reviewer role is not filled by a second person, and no ISMS entry exists.

### 8.4 Separation of duties as a counted minimum

Control 1.2.2 asks for separated roles; on 2026-09-13 every role on the platform is one person, the finding most likely to stop an assessment. The design answers with a count the tier gate enforces, not a promise (P137) ([../11-tisax.md#72-the-minimum-per-stage](../11-tisax.md#72-the-minimum-per-stage)):

| Stage or gate | Distinct humans (minimum) | Bought |
|---|---|---|
| Stage 0 — read-only, Tier R | **1**, with self-review recorded as such | — |
| Stage 1 — first write, Tier W | **3**: a second operator who is also the blind grader, and a security reviewer from IT security | the build-time signing pipeline, no licence |
| The super-admin grant | **4**: as Stage 1 plus a second human super admin outside the Wall-E line as Eve owner; the full build raises this to **five named humans, or four with a dated ISMS exception** | a security information and event management service (SIEM) in the EU, a managed detection and response retainer, paging, hardware keys, the witness organisation |
| Stage 3 — autonomous band A | **4 plus a bought detection desk** with 24x7 acknowledgement | as the grant |

Five humans is the clean state; the security reviewer may equal the Eve owner at the first grant only as a temporary exception the ISMS dates. A CI check evaluates the incompatibility matrix against group memberships and the roster daily and on every merge; a collision refuses promotions above the stage that pair is legal at; a role holder without a training record for the current stage is not counted ([../11-tisax.md#71-the-roles](../11-tisax.md#71-the-roles); [../setup/README.md#8-blocked-index](../setup/README.md#8-blocked-index), row B-21, a BLOCKED row of the full build — a step that cannot run until the people it names exist).

### 8.5 The assurance cadence (P139)

A penetration test, grey-box with the source, scoped on the approval surface and the action service before the first Tier W agent's Stage 1 and full before the super-admin grant, then annually and on any new lane; owned by IT security, never by the platform owner or the agent owner. An internal audit annually by the ISMS's auditor — never the platform owner nor the deviation's signatory — with the first slot before the assessment order; a finding open on 1.2.2 or 4.2.1 at the order stops the order. A management review quarterly with the roster review, annually into the ISMS's review, minutes kept ten years ([../11-tisax.md#9-penetration-test-internal-audit-management-review-p139](../11-tisax.md#9-penetration-test-internal-audit-management-review-p139)). The assessment order itself waits on the label, the scope, the signed classification mapping, every accepted risk's acceptance file, the ENX result share and the legal register ([../12-open-decisions.md#6-later](../12-open-decisions.md#6-later)).

---

## 9. GDPR touchpoints

The organisation is the controller; the platform administers its own tenant and employees' accounts, so the frame is the existing GDPR programme, not a separate AI regime ([../brief/26-personal-data-and-employees.md#221-the-position-controller-and-internal-processing](../brief/26-personal-data-and-employees.md#221-the-position-controller-and-internal-processing)). Four groups of employees are data subjects: every tenant account (the identity log store copies sign-ins; Stage 0 reads every directory record); the targets of suspension and licence reclaim; the operators and approvers; and the human super administrators whom Eve watches from its first run ([../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191](../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191), P154).

**The DPIA (Art. 35).** The data protection impact assessment is the DPO's programme; the platform supplies inputs and it is the longest lead item in the plan. Eve over the administrators is a monitoring system at the workplace and the Stage 0 reads touch every employee, so two of the "likely high risk" criteria are met at once (`Assumption:` the competent authority's Art. 35(4) list names employee monitoring, as most do). Art. 35(1) requires the assessment *prior to* the processing. The design pages disagree on the gate — the HLD lists "the DPIA" among the grant preconditions, the checklist asks that it has "started" — and GDPR Art. 35(1) points to the stricter reading: this document recommends that the DPIA for Eve's monitoring of administrators, the identity log store and the Stage 0 reads be complete before each starts, and the DPIA for the write families started with a dated completion before Stage 1; the DPO and the platform owner decide and record it ([../brief/26-personal-data-and-employees.md#229-still-open](../brief/26-personal-data-and-employees.md#229-still-open); [the cross-check review of 2026-09-18](../14-crosscheck-review.md#54-employee-data-and-the-works-council), section 5.4, reads Art. 35(1) the same way). The DPO record on monitoring named administrators (SD-11; P154 and P199) — purpose, subjects, retention, recipients who are never the subject — is signed before any Eve job is deployed, in every build path.

**Transfers and Google's terms.** Residency is `europe-west1` for services, BigQuery `EU` and the Gemini Enterprise app location `eu` ([../../project-topology.md#2-the-four-projects](../../project-topology.md#2-the-four-projects)). Assured Workloads EU Data Boundary — Google's package that confines a folder to EU regions and EU-supported products — is not adopted, because three products the platform is built around (Agent Gateway, Agent Registry and Agent Identity) sit outside it (P110), with a compensating set and a revisit trigger (P12) ([../08-data-logging-retention-sovereignty.md#71-assured-workloads-eu-data-boundary-for-the-agents-folder-no-not-now-p110](../08-data-logging-retention-sovereignty.md#71-assured-workloads-eu-data-boundary-for-the-agents-folder-no-not-now-p110)). The transfer inputs the DPO works from are page 08's six dated exception rows, not the TISAX page's "two"; the DPO's own assessment of the residency exceptions, the model's processing location and Google's sub-processors is still to be made ([../brief/26-personal-data-and-employees.md#222-what-the-platform-owes-the-dpo-and-where-each-input-stands](../brief/26-personal-data-and-employees.md#222-what-the-platform-owes-the-dpo-and-where-each-input-stands)). The Google Cloud and Google Workspace agreements and their data-processing terms are rows of the legal and contractual register with exact titles and versions *tbd*; legal and the ISMS supply them, and the internal audit reads the register against the supplier file ([../11-tisax.md#11-the-legal-and-contractual-register-p141](../11-tisax.md#11-the-legal-and-contractual-register-p141)).

**Retention (P13, P106).** `evidence` 400 days floor; `record` 10 years; `content` 30 days ceiling; `ops` 30 days; conversation history 30 days interim. The DPO's ceiling per class is due before Stage 1 of any Tier W agent; locked stores are created unlocked at the floor and locked only on the day the ceiling is recorded, because a lock cannot be shortened. A data-subject request against a locked store is answered by disclosure, not deletion; minimisation keeps that lawful ([../12-open-decisions.md#3-before-any-tier-w-agent-writes](../12-open-decisions.md#3-before-any-tier-w-agent-writes)).

**Art. 22 (solely automated decisions).** No decision on the platform is solely automated: the suspension decision is HR's or a named operator's and Wall-E executes it with a decision reference; licence reclaim from active accounts takes a human-supplied list; families that can run at L5 produce no legal or similarly significant effect. The point a works council will press: at L4 on the HR event the *action* executes without a human looking at *that* action. The honest answer, on the page: a wrongful suspension can last the hold window plus the restore's human approval, up to four business hours, and the caps of P127 keep chat and scheduled suspensions at L3 ([../brief/26-personal-data-and-employees.md#224-the-actions-that-affect-employees-and-how-they-are-bounded](../brief/26-personal-data-and-employees.md#224-the-actions-that-affect-employees-and-how-they-are-bounded)). The explanation path (Art. 86) runs through HR; every request is logged and one unanswered past the deadline is a finding ([../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129](../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129)).

**Art. 88 and the works council.** Art. 88(2) names "monitoring systems at the work place" explicitly; Eve over the administrators and the identity log store are both one, whatever the AI Act says about Eve. `Assumption:` the jurisdiction is unknown — the operating site's country is *tbd* and no document may name one. Where national law makes the introduction of a monitoring device subject to co-determination, the council's consent and a works agreement are required, with a lead time of months (`Assumption:`); the design's default of "information before putting into service" is the weaker of the possibilities and should read "consultation, and consent where co-determination applies; information only where HR's answer says so". The trigger moves one step earlier than P129 states: not Stage 1 of a writing agent but Eve's first stream about human administrators and the identity log store's first copy, whichever comes first, with the SD-11 record as companion. The interim in every jurisdiction: Eve's first run limited to the two participants with their written consent ([../11-tisax.md#11-the-legal-and-contractual-register-p141](../11-tisax.md#11-the-legal-and-contractual-register-p141); [../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129](../10-eu-ai-act.md#410-art-267-2611-art-86--workers-and-the-explanation-path-p129)). The detail for HR is in [hr-and-works-council.md](hr-and-works-council.md).

---

## 10. The dated path

The three build paths: the **full build** (files setup/01–42, human-executed, 6 to 7 months to Stage 0 and not before 2027-03, the only path that owns the super-admin grant); the **proof of value** (pov/01–09, three hands-on people and one engineer, Tiers C, R and W on the production tenant, the doer holding no Workspace admin role at all); and the **three-day build** (two people, three business days, a demonstration of machinery under control) ([../setup/README.md#status](../setup/README.md#status); [../pov/README.md#status](../pov/README.md#status); [../3-day/README.md#status](../3-day/README.md#status)). `Assumption:` every date after 2026-09-24. "First produced by" names the earliest path whose pages produce the artefact; "none" means an organisational act no path produces.

| Milestone | Date or gate | Obligation | Owner | Evidence | First produced by |
|---|---|---|---|---|---|
| Today | 2026-09-18 | Art. 4, Art. 5 and Art. 50 bind the organisation now as deployer of the Gemini Enterprise application it already licenses ([../01-hld.md#111-tiers-and-mandatory-controls](../01-hld.md#111-tiers-and-mandatory-controls); [../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer](../10-eu-ai-act.md#2-roles--which-legal-entity-is-provider-and-which-is-deployer)), and bind any agent from its first day; the platform itself creates no exposure until something exists. GDPR binds always. Art. 99 exposure is real for Art. 5 and Art. 50 on that existing use | AI compliance owner (to be named); DPO | none yet | — |
| Day one of the POV and of the full build | 2026-09-21 | Send the D7 letter to the DPO and the works-council question to HR, covering Wall-E **and the monitoring of named administrators**; ask whether information, consultation or consent is required and by when | platform owner sends; DPO and HR answer; legal in copy | the works-council question record (E-12) | pov/02; setup/03 |
| Three-day build | 2026-09-22 to 2026-09-24 | Demonstration only. Eve polls the production tenant's admin audit log for every actor from day one — monitoring of every human administrator under Art. 88(2) and Art. 35. Required before day one: a DPO record on monitoring named administrators and HR's answer, or the poll limited to the two participants with written consent — a precondition the three-day pages do not yet carry ([the cross-check review of 2026-09-18](../14-crosscheck-review.md#54-employee-data-and-the-works-council), section 5.4) | platform owner; DPO; HR | run log; not compliance evidence | 3-day (the run log); the DPO record and HR's answer by pov/02 and pov/06 |
| Full-build decisions and people signed | 2026-09-29 to 2026-10-27 | The entity (P23); the super-admin purpose signed with legal; SD-11; the D7 answer; retention (P13); the roster reduction — other people's time and the D7 answer bound it | legal; DPO; HR; ISMS; the second human | the setup/03 records | setup/03 |
| Before Eve's first run on the real tenant | 2026-10 (POV weeks 2–5) | The SD-11 DPO record: purpose, subjects (roster and live admin-role holders), retention, recipient; HR signs the works-council half. No feed before it | DPO; HR; platform owner and the second human co-sign | SD-11 record; E-12 | pov/06; setup/24 |
| POV-1 | 2026-10 to 2026-11 (earliest end 2026-11-06 to 2026-11-27) | Class and role per POV agent with the purpose paragraph and its hash; Art. 5 negative determination; Art. 4 briefing for the three people; an `annex_iii_adjacent` row also needs a dated Art. 6(4) assessment and an Art. 49 value before it commits | AI compliance owner or legal's designate; DPO; platform owner | the PV-11 record — PV-11 is a proof-of-value decision (P202) binding on the full build; E-01 (POV-grade), E-13 | pov/02 |
| ISA 6 cut-off decision | 2026-12-01 at the latest | Whether any site assessment is ordered under ISA 6 by 2026-12-31 (section 8.1) | ISMS | a dated line in the legal register | none |
| Omnibus dates bite | 2026-12-02 | Art. 5 additions; end of the Art. 50(2) transition — no effect | AI compliance owner | note on the page | — |
| Final Art. 6 guidelines | end 2026 (expected) | Re-run every `annex_iii_adjacent` assessment within 90 days; rows `suspended` until re-signed | legal; AI compliance owner | E-01 new version | none until adopted; setup/42 keeps the calendar |
| Eve's observe-and-report layer (Eve-H) live and drilled | 2026-12-22 to 2027-01-19 (`Assumption:`; *tbd* on Eve code) | The first monitoring of human administrators on the full build. Before the first stream about human administrators and before the identity log store's first copy: the SD-11 DPO record; the DPIA for Eve's monitoring and the identity log store complete; worker information or consultation given. Bounded by Eve's code and schemas, the SD-11 record and the witness | DPO; HR; the second human; platform owner | the Eve-H live record; SD-11; E-12 | setup/24, 25, 28 |
| ISA2027 mandatory for new orders | 2027-01-01 | The mapping of record is the TISAX page against ISA2027 with the 6.0.3 cross-reference | ISMS; platform owner | the mapping | setup/42 |
| POV-2: the doer's first write at L1 on synthetic accounts | 2027-01 to 2027-02 (weeks 16–20 with a dedicated engineer; plan on 2027-01-29 or later) | Before it: PV-11 signed; the DPIA started with a dated completion; no real account enters the pilot OU until the DPIA is complete, HR's written answer exists and the holder consents | DPO; HR; legal; platform owner | the Tier W record; PV-D-15, the proof-of-value deviation that records the DPIA as started, not complete | pov/07 |
| M/613, the Commission's standardisation request to the European standards bodies, expires | 2027-02-28 | Calendar item: check whether the Commission extended it | AI compliance owner | note on the page | — |
| Pre-grant Wall-E built and the penetration test | 2027-02-02 to 2027-03-16 (`Assumption:`; *tbd* on Wall-E code) | Penetration test with no open critical or high finding — full scope, on the approval surface and the action services | IT security | the penetration-test record | setup/37 |
| Before the grant | not before 2027-03; the grant itself *tbd*, bounded by the SIEM and MDR contract (months), the penetration test, K6 and K7 drill freshness and five named humans | The tabletop with the DPO, legal and HR or employee representatives; the gate checklist signed by the security reviewer and the ISMS; the deviation record's three signatures; the DPIA covering the Stage 0 reads complete | incident commander; security reviewer; ISMS; DPO | E-10; the deviation file; R-01 acceptance | setup/38 |
| The grant day | *tbd*, not before 2027-03 | Super Admin on the robot account; the 4.2.1 deviation in force; quarterly review with the roster; re-signature at each stage transition | platform owner requests; the second human approves; security reviewer signs | the deviation file; review log | setup/38 |
| Stage 0 | one to two weeks after the grant; 3 to 4 weeks long | Reads on every employee's directory data: the records-of-processing entry; the DPIA for the reads complete before the first report | DPO; agent owner | the records-of-processing entry (TISAX control 9.3.1); DPIA | setup/39 |
| Stage 1 — the first write | about 2027-04 at the earliest | Putting Wall-E into service: E-01 signed by legal and the DPO; E-02 registration id; E-12 pack and notice dated with the explanation log existing; E-13 records; E-07 instructions; E-05 the stage tag; E-15 the Art. 50 block. A count of zero on E-01, E-02, E-05, E-07, E-12 or E-13 blocks the stage | legal; the P23 entity; HR and DPO; agent owner; platform owner | the six gating artefacts | setup/39, 42 |
| TISAX assessment order under ISA2027 | after Stage 1 and the first internal audit (mid to late 2027) | The signed classification mapping; every accepted risk with its acceptance file; the ENX result share filed and per-service coverage answered; the legal register; no open finding on 1.2.2 or 4.2.1; four distinct humans | ISMS; security reviewer; platform owner | the evidence pack of the TISAX page's §13 | setup/42; the ENX share and the coverage answers by none |
| Wall-E's later stages straddle 2027-12-02 | 2027-10 to 2028-01 (S5 at least 27 to 38 weeks after S0) | F5 at L4 only on the HR-system event; every promotion record carries the Art. 9 residual-risk statement | agent owner; security reviewer; DPO | E-03 | setup/40–42 |
| Annex III obligations bind | 2027-12-02 | For any `high_risk` row the full programme; for `annex_iii_adjacent` rows the classification file current against the final guidelines; Art. 26(7) information becomes mandatory (already done) | AI compliance owner; legal; ISMS | E-01 refresh; E-14 only if `high_risk` | setup/42 |
| Label expiry | three years after the result | Re-assessment; the deviation re-signed | ISMS; security reviewer | new result; new signature | — |

Sources for the dates: [../setup/README.md#34-parallel-sittings-and-the-critical-path](../setup/README.md#34-parallel-sittings-and-the-critical-path); [../pov/README.md#4-pov_stage_dates-the-two-stages](../pov/README.md#4-pov_stage_dates-the-two-stages); [../brief/29-roadmap-and-cost.md#stage-floors-across-the-three-agents](../brief/29-roadmap-and-cost.md#stage-floors-across-the-three-agents).

---

## 11. The decisions compliance owns, and what to sign first

The register of record holds every platform decision as P1–P204 in five states: `decided`, `closed`, `proposed` (stands until the owner overturns it in writing), `open` (the gate stays red), `spike` ([../12-open-decisions.md#1-how-this-register-works](../12-open-decisions.md#1-how-this-register-works)). The rows below are the ones a compliance, legal, DPO or ISMS signature closes.

| Row | What it decides | State on 2026-09-18 | Who acts | Gate |
|---|---|---|---|---|
| P125 | Wall-E's Art. 6 path: the catalogue as purpose, one paragraph in five places, the fallback held ready | proposed (content of P28) | owner and legal | first write |
| P28 | The signature on that purpose | signature open | owner with legal | first write |
| P126 | The F7 split and the profiling boundary | proposed | DPO and legal (P18); platform owner | F7 above L3; the Art. 6(4) signature |
| P18 | Is inactivity reclaim profiling | open | DPO and legal | F7 above L3 |
| P127 | Art. 14 caps and overseers; the automation-bias sample | proposed | agent owner, ISMS, Mo owner | Stage 4 |
| P128 | Art. 50 mechanics — already due | proposed | platform owner; agent owner; legal (text) | Stage 1 of any agent that sends |
| P129 | Worker information before Stage 1 — to be re-gated on Eve's first stream (section 9) | proposed | HR, DPO, legal | Eve's first stream; Stage 1 |
| P130 | The documentation freeze and the Annex IV index | proposed | platform owner; AI compliance owner | Stage 1 |
| P131 | The AI compliance owner role; the Art. 4 measure; the negative determinations | proposed | ISMS (names); legal | the super-admin grant; any `annex_iii_adjacent` production row |
| P132 | The reclassification triggers | proposed (continuous) | AI compliance owner; platform owner | armed at Stage 1 |
| P19 | `eve-advisor`'s class | open | legal | any paging right or registration for it |
| P23 | The legal entity | open | legal | every Art. 26 obligation and the registration |
| P32 | The Art. 25(4) position with Google; per-service TISAX coverage | open | platform owner; ISMS | Stage 1; the assessment order |
| P13 | Retention floor and ceiling per store | open | DPO | Stage 1 of any Tier W agent |
| P133 | Label Confidential, AL2, scope *tbd*, ISA2027 | proposed (the ISMS confirms) | ISMS | the assessment order |
| P134 | Module scope | proposed | DPO; ISMS | the assessment order; the first processor-role agent |
| P135 | The mapping page and the supplier file; the ENX result share | proposed | platform owner; ISMS | the assessment order |
| P136 | The deviation record, its gate conditions and cadence (aligned as in section 8.3) | proposed; signatures pending | security reviewer signs; ISMS enters | the super-admin grant |
| P137 | Separation of duties as a counted minimum | proposed | ISMS (names) | Tier W; the grant |
| P138 | One supplier procedure for every external agent, server, app and model | proposed | platform owner; ISMS | the first external dependency |
| P139 | The assurance cadence | proposed | IT security; ISMS | Stage 1; the grant; the assessment order |
| P140 | The risk register with acceptance files | proposed | security reviewer; ISMS | the assessment order |
| P141 | The legal and contractual register | proposed | ISMS; legal | the assessment order |
| P101 | The Art. 73 taxonomy and the GDPR breach path | proposed | legal, DPO | Stage 1 (DPO path); the grant |
| P75 | The registration gate in CI | proposed | legal, DPO, platform owner | first write of any such agent |
| P145 (SD-02) | The split gate: everything but the Super Admin assignment may be built | pending signature | platform owner; IT security; ISMS | register CI rules |
| P147 (SD-04) | Witness administrators; five named humans or four with a dated ISMS exception | pending signature | IT security; ISMS | the witness purchase |
| P154 (SD-11) | Monitoring named administrators is employee monitoring: the DPO record blocks every Eve job | pending signature | DPO; second human; HR | Eve's reconciler and poll jobs |
| P155 (SD-12) | The monitored administrator installs Eve: the second human owns and approves Eve's build | pending signature | second human; IT security | Eve's first step |
| P179 (SD-36) | The gate lines G1–G21; the enforceable gate is the second human's refusal on the day | pending signature | second human; ISMS | the assignment |
| P199 (PV-08) | Binds the full build for the DPO record; POV-only for Eve's POV shape | pending signature | DPO signs; second person co-signs | every Eve step of the POV |
| P202 (PV-11) | Classification of every POV register row; binds the full build | pending signature | AI compliance owner or legal's designate; DPO | every POV register row |

Sources: [../12-open-decisions.md#5-before-wall-es-stage-1-and-its-later-stages](../12-open-decisions.md#5-before-wall-es-stage-1-and-its-later-stages); [../12-open-decisions.md#4-before-the-super-admin-grant](../12-open-decisions.md#4-before-the-super-admin-grant); [../12-open-decisions.md#6-later](../12-open-decisions.md#6-later); [../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191](../12-open-decisions.md#6a-proposed-by-the-setup-procedures-p144p191); [../12-open-decisions.md#6b-proposed-by-the-proof-of-value-set-p192p204](../12-open-decisions.md#6b-proposed-by-the-proof-of-value-set-p192p204).

**What to sign first, in order.**

1. **Name the AI compliance owner (P131).** Nothing below can be signed lawfully without them: "a classification signed by the platform owner is self-assessment in the sense an auditor rejects" ([../12-open-decisions.md#4-before-the-super-admin-grant](../12-open-decisions.md#4-before-the-super-admin-grant)).
2. **Sign the DPO record on monitoring named administrators (SD-11; P154, P199)** and answer the D7 letter's works-council question — information, consultation or consent, and by when — which the platform owner sends on day one. The record gates the first Eve job of every path and is the longest lead item.
3. **Decide the ISA 6 cut-off by 2026-12-01** (section 8.1).
4. **Sign Wall-E's intended purpose with legal (P28 on P125's content)**, with F5 on condition (a) primary, before the first write — and early enough that the 90-day re-run after the final guidelines is a re-signature, not a first signature.
5. **Supply the entity (P23)** and the retention ceiling (P13); answer P18 and P19.
6. **The deviation record (P136) and R-01** need a security reviewer who is not the platform owner; that person does not exist on 2026-09-18, so the signature waits on an appointment, not on a document.

---

## 12. What no build path evidences, what only the full build does, and the sentences never to be used

**Only the full build produces:** the super-admin intended purpose signed with legal; Wall-E's Art. 49(2) registration and Art. 6(4) file (the POV registers only its own rows); the deviation record with three signatures and the risk register with acceptance files; the four distinct humans and the CI separation check; the penetration test; the witness organisation and Eve's structural independence; the Art. 12 log locked at 400 days with a daily witness copy; the stage snapshot tag and the instructions for use; the Art. 50 injection and its CI content test; the internal audit and management review; the TISAX evidence pack ([../setup/README.md#status](../setup/README.md#status); [../setup/42-gates-drills-and-evidence.md#gd-43-the-tisax-13-pack](../setup/42-gates-drills-and-evidence.md#gd-43-the-tisax-13-pack)). The POV claims no line of the super-admin gate and a POV record never satisfies a full-set gate whose conditions it lacks ([../pov/README.md#73-a-pov-record-never-satisfies-a-full-set-gate](../pov/README.md#73-a-pov-record-never-satisfies-a-full-set-gate)).

**No path produces, because they are organisational or external:** the ENX result share for Google's scope and Google's per-service coverage answers (P32, P135); the Art. 25(4) written position with Google; a completed DPIA (the DPO's programme; the paths supply inputs); HR's works-council answer and, where required, the consultation or the works agreement; the legal entity (P23); the final Art. 6 guidelines re-run; a harmonised standard and any presumption of conformity; a maturity-3 verdict on 4.2.1 for a super-admin robot — only the assessment gives that, and nothing on any page can settle it ([../11-tisax.md#12-documentation-task-versus-control-that-does-not-exist](../11-tisax.md#12-documentation-task-versus-control-that-does-not-exist)).

**What the smaller paths yield, honestly.** The POV yields Tier R closed and Tiers C and W partly, classification records for its own agents, the SD-11 record with HR's works-council half, a started DPIA, Eve reporting on every human super admin to someone who is not the subject, the doer at L1–L3 on synthetic accounts, and a deviation register the full build reads; it does not claim a tamper-proof audit (append-only by convention, alteration detected) ([../pov/README.md#11-pov_claim_statement](../pov/README.md#11-pov_claim_statement)). The three-day build yields a demonstration of machinery under control and, correctly, claims nothing else: no DPIA, no works-council information, no super admin for any agent, no witness, no SIEM, no penetration test — "a demonstration of machinery under control, not compliance evidence and not a production grant" ([../3-day/README.md#7-what-three-days-cannot-buy](../3-day/README.md#7-what-three-days-cannot-buy)).

**The sentences never to be used**, copied from the pages that forbid them, each with its reason:

| Sentence | Path | Why it is forbidden |
|---|---|---|
| "Wall-E is safe as a super admin." | POV; three-day | Nothing in the POV's Track A touches super-admin containment; nor may any report say or imply that the doer "does admin work" — it holds no Workspace admin role. No agent holds Super Admin at any moment of the three days |
| "Eve is independent." | POV; three-day | Independence in the design is structural: a witness organisation, a second tenant. Neither path has one, and its Eve lives inside the reach of the administrators it watches |
| "Model Armor blocked the injection." | POV; three-day | A probabilistic content screen is never a trust boundary, whatever its grade; in the POV it produced evidence; the three days send nothing through the floor and produce no Model Armor evidence at all |
| "We saved `<n>` minutes of admin work." | three-day | The doer acted only on synthetic accounts; no human minute was saved, and Mo's scorecard says so in bold |

Sources: [../pov/README.md#12-never-to-be-used-in-any-report-slide-or-message-about-the-pov](../pov/README.md#12-never-to-be-used-in-any-report-slide-or-message-about-the-pov); [../3-day/README.md#11-never-to-be-used-in-any-report-slide-or-message](../3-day/README.md#11-never-to-be-used-in-any-report-slide-or-message).

---

## 13. The calendar for the next fifteen months

Compliance-owned dates and gates, 2026-09 to 2027-12. `Assumption:` every date after 2026-09-24; gates without a date are ordered by the paths' own sequence.

| Month | Compliance milestone |
|---|---|
| 2026-09 | Day one 2026-09-21: the D7 letter to the DPO and the works-council question to HR, covering Eve's monitoring of named administrators. Before the three-day run (2026-09-22 to 2026-09-24): the DPO record and HR's answer, or Eve's poll limited to the two participants with written consent. Name the AI compliance owner |
| 2026-10 | The SD-11 DPO record signed before Eve's first run on the real tenant; HR signs the works-council half. The Art. 4 briefing for the POV's three people. The full build's decisions and people signed (2026-09-29 to 2026-10-27): the entity (P23), the super-admin purpose signed with legal, SD-11, the D7 answer, retention (P13) |
| 2026-11 | POV-1 ends (2026-11-06 to 2026-11-27): PV-11 classification records for the POV rows; the Art. 5 negative determination; the DPIA started with a dated completion |
| 2026-12 | 2026-12-01: the ISMS's ISA 6 cut-off decision. 2026-12-02: the Omnibus dates bite, no effect. 2026-12-31: last day to order an ISA 6 assessment. Expected: the final Art. 6 guidelines — the 90-day clock starts on adoption. From 2026-12-22 (earliest; *tbd* on Eve code): Eve's observe-and-report layer live on the full build, only after the SD-11 record is signed, the DPIA for its monitoring and the identity log store is complete and worker information or consultation is given |
| 2027-01 | 2027-01-01: ISA2027 mandatory for new orders. Eve's observe-and-report layer live and drilled by 2027-01-19 at the earliest. POV-2 planning: no real account in the pilot OU without a complete DPIA, HR's written answer and the holder's consent |
| 2027-02 | POV-2 ends (2027-01-15 to 2027-02-12 with a dedicated engineer; plan on 2027-01-29 or later): the doer's first write at L1 on synthetic accounts. 2027-02-02 to 2027-03-16 (*tbd* on Wall-E code): pre-grant Wall-E built and the full penetration test. 2027-02-28: M/613 expiry check |
| 2027-03 | Before the grant, not before 2027-03: the penetration test with no open critical or high finding, the tabletop with the DPO, legal and employee representatives, the gate checklist and the deviation record's three signatures, the DPIA covering the Stage 0 reads complete; the Art. 6(4) re-run against the final guidelines if adopted in December. The grant itself *tbd*; Stage 0 one to two weeks after it |
| 2027-04 | Earliest Stage 1 on the full build, subject to the grant and Stage 0's 3-to-4-week floor: the six gating artefacts (E-01, E-02, E-05, E-07, E-12, E-13); the Art. 49(2) registration id in the row; the reclassification triggers armed |
| 2027-05 to 2027-06 | The first quarterly management review after Stage 1, with the roster review and the deviation record's quarterly review |
| 2027-07 to 2027-09 | The first internal audit by the ISMS's auditor; the signed classification mapping; acceptance files for every accepted risk; the ENX result share requested and filed; the TISAX assessment order under ISA2027 if the audit leaves no finding open on 1.2.2 or 4.2.1 |
| 2027-10 to 2027-11 | Wall-E's later stages: every promotion record with the Art. 9 residual-risk statement; F5 at L4 only on the HR-system event; the quarterly review and re-signature of the deviation record at each stage transition |
| 2027-12 | 2027-12-02: Annex III obligations bind; the classification file current against the final guidelines; E-14 only if any row is `high_risk` |

The next documents for this reader: [hr-and-works-council.md](hr-and-works-council.md) for the works-council pack and the explanation path; [security-team.md](security-team.md) for the enforced-versus-detected verdict the deviation rests on; [enterprise-architecture.md](enterprise-architecture.md) for the register, the tiers and the factory; [executive-brief.md](executive-brief.md) for the sponsor's one page; [README.md](README.md) for the set; and [../plain/README.md](../plain/README.md) for the plain-language set.

---

## Where this is defined

- The EU AI Act position, classification, crosswalk, evidence register and residual list: [../10-eu-ai-act.md](../10-eu-ai-act.md) (§0–§9).
- The TISAX target, module scope, shared responsibility, deviation record, separation of duties, assurance cadence, risk register, legal register and evidence pack: [../11-tisax.md](../11-tisax.md) (§0–§13).
- The decision of 2026-09-13 and the deviation record's sections, review cadence and signatures: [../../../decisions/2026-09-13-wall-e-holds-super-admin.md](../../../decisions/2026-09-13-wall-e-holds-super-admin.md).
- The register rows P125–P141, P28, P131, P136 and the setup and proof-of-value rows: [../12-open-decisions.md](../12-open-decisions.md).
- Personal data, the DPO's engagement points and the works council: [../brief/26-personal-data-and-employees.md](../brief/26-personal-data-and-employees.md); the brief's EU AI Act and TISAX chapters [../brief/24-eu-ai-act.md](../brief/24-eu-ai-act.md), [../brief/25-tisax.md](../brief/25-tisax.md).
- The evidence mapping, the TISAX pack export and the hand-made stage tag: [../setup/42-gates-drills-and-evidence.md](../setup/42-gates-drills-and-evidence.md); the critical path and blocked index: [../setup/README.md](../setup/README.md).
- What the proof of value and the three-day build claim and never claim: [../pov/README.md](../pov/README.md); [../3-day/README.md](../3-day/README.md).
- The objective, its sixteen requirements and what is declined or qualified: [../00-objective-review.md](../00-objective-review.md); [../01-hld.md](../01-hld.md).
- The re-verification of the regulatory state on 2026-09-18, the dated path and the employee-data reading this document follows: [../14-crosscheck-review.md](../14-crosscheck-review.md) (§5, "The path to the regulation"; §4, "Security", for the enforced-versus-detected verdict the deviation rests on).
