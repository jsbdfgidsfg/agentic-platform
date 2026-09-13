# 14. HLD challenge and revalidation

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-13
- 2026-09-13: dated placement notes added under C50, C14, C11, the alternatives table, decisions 29, 31 and 36, and the accepted-risks table, because the four-project topology of [../project-topology.md](../project-topology.md) changes where Eve's trust root and evidence live. No verdict changed.
- Subject: [01-hld.md](01-hld.md), challenged on 2026-09-11 with the design set complete and
  nothing built; product facts re-verified 2026-09-12, sources at the end of this page
- Method: machine-run adversarial review, eleven reviewer lenses, 54 deduplicated
  challenges, then a refutation stage of up to three refuter lenses per challenge. Every
  one of the 54 was attacked by at least one refuter; none was left un-attacked. Coverage
  tracks severity by design: the minor challenges drew the already-addressed lens alone,
  the contested ones three to five verdicts. See "The review that ran".
- Relationship to [10-adversarial-review.md](10-adversarial-review.md): that page attacked
  the design as first drafted and its 17 attacks are closed. This page attacks the design
  as it now stands, including the fixes 10 made.

## Verdict

**Yes, with changes. The architecture is the correct path. The document is not yet
correct, and four things must be settled — one before the irreversible consent step, the
rest before Stage 1's first write.**

The shape of the design survived eleven independent attacks without a single reviewer
proposing a different architecture. Nobody argued for domain-wide delegation, for putting
the credential in the model's process, for a generic Admin SDK proxy, for a bought
platform, or for policy-as-code without an evidence gradient. Four lenses that exist
specifically to find a cheaper path — buy-versus-build, simplicity, requirements-fit,
autonomy-control — each concluded the expensive core earns its place.

Five reasons the path is right:

1. **The credential split is load-bearing and nothing cheaper reproduces it.** One process
   holds the credential, the reasoning layer holds nothing, and a deterministic gate sits
   between generated text and an Admin SDK call. The minimal alternatives undo it:
   approvals in chat reinstate attack A1 and hit the Chat text-only limit, one merged
   service breaks trust boundary 3.
2. **No Google-native or bought option clears the standing constraints as of 2026-09-11.**
   Gemini in the Admin console advises rather than acts. Workflow Builder scheduled agents
   and Workspace Studio flows both run as the creating user, whose own admin rights become
   the ceiling; Workflow Builder schedules additionally carry user credentials that Google
   expires every 14 days. Bought SaaS-management platforms hold a
   tenant-wide grant outside the no-DWD rule. None puts a deterministic gate in front of
   the write.
3. **Autonomy as data attached to (family, trigger) is better than every alternative
   tested.** Policy-as-code alone gives `WRITE_HIGH` an on/off switch with no evidence
   gradient; "always a human" is already L3; dual control is L3; automatic rollback is
   unsafe because a Workspace rollback is itself a write on fresh pre-state.
4. **The limit on breadth is the identity, not the design.** With no DWD and no super
   admin, super-admin-only and DWD-only APIs are unreachable whatever sits in front of
   them. A generic proxy would add reach only in Directory, Licensing, Data Transfer,
   Chrome Policy and shared drives, and would lose the per-operation inverse, pre-state
   predicate, taint declaration and readable approval card that everything above L2
   depends on.
5. **The 17 earlier attacks were fixed properly.** The refuters repeatedly found that a
   new challenge was already bounded by A3 taint, A10 full-chain re-run, A11 pinned
   selection, A12 consume-then-reconcile or A16 pinned secret version. That is evidence
   the fixes were structural rather than cosmetic.

**What must change.** Two blocking challenges stand, joined by one major challenge whose
deadline sits with them (C41, narrowed by its own refuters to *before S1 and before the
first operator who is not a super admin*). All three are about things the HLD does not say
rather than things it gets wrong:

- **No environment exists in which a change to the gate runs before it runs as the holder
  of the production credential against the production tenant** (C50). The sandbox OU is a
  target inside production reached with the production credential, and Workspace cannot
  OU-scope group privileges at all, so group-family writes have no containment but the
  code under test. This needs an offline harness and a decision on a pre-production
  credential holder before Stage 1's first write. All three refuter lenses ran and none
  could dismiss it; two of them narrowed the severity to *blocking before any F3 or F3b
  cell leaves L1* rather than blocking before build, because Workspace — not our code —
  contains the OU-scopable families.
- **Nobody checks what the human behind a request is allowed to do** (C41, *major*, due
  before S1 and before the first operator who is not a super admin). The design is
  meticulous about the robot's reach and silent about the requester's. Membership of
  `walle-operators@` currently grants the robot's whole allowlisted reach to whoever is in
  it. This is harmless while the only operator is a super admin, and becomes a
  privilege-escalation path the day [decision 11](09-open-decisions.md) is answered — which
  [SETUP.md](SETUP.md) Phase 1 may already have pre-empted, since it lists a second operator
  in `$OPERATORS` while [ARCHITECTURE.md](ARCHITECTURE.md) section 0 assumes the ladder owner
  alone. The refuters found that contradiction; it has to be settled either way.
- **The requirement was narrowed from "any action a human admin can do" to a fixed
  catalogue, and the HLD never says so or asks for sign-off** (C1). Scopes freeze at
  consent, so breadth has to be decided before [decision 3](09-open-decisions.md), not
  discovered afterwards.

**One headline change that is not a gap but a premise.** [02-identity-and-auth.md](02-identity-and-auth.md)
builds the whole credential story on a Workspace user because a service account cannot
become one. That sentence is true; the conclusion drawn from it is not. Google documents
that any prebuilt or custom admin role except Super Admin can be assigned to a service
account, which then calls admin APIs as itself with no DWD and no subject (C3). If that
covers the Directory, Licensing and Reports calls Wall-E needs, it removes the password,
the recovery path, the hardware key in a safe, the interactive consent, the frozen scope
set and the stealable refresh token in one move. That is a one-day spike before Phase 9,
not a rewrite — but Phase 9 is irreversible, so the spike has to happen first.

**What does not change.** No trust boundary is removed or replaced, the layer
responsibilities and the no-DWD rule all stand, and every standing challenge is fixable with
edits inside the existing design. Two boundaries are reworded rather than kept verbatim:
C41 restates what boundary 1 grants and adds a "How it can still fail" column to boundaries
1 and 4, and C8 tightens how boundary 1 is enforced — T0 requires both live group membership
and the committed operator list. Two qualifications on the component map: C37's refresh adds the components
01 omits, and C30 demotes `walle-events` and its two edges to target state. One more is
contingent — if the decision 26 spike passes, design intent 1's "one Workspace identity"
becomes two principals and the `RB` node splits.

## Method

### The review that ran

On 2026-09-11, with the design set complete and nothing built, eleven reviewer lenses
attacked [01-hld.md](01-hld.md) independently, each reading the whole set for context but
judging the HLD. They produced 63 raw challenges, deduplicated to 54 (C1–C54). Each
challenge carried a claim, its evidence with document and line references, the alternative
it proposed, and the exact change it wanted.

Each challenge was then attacked by **refuter** lenses, and every one of the 54 drew at
least one. C1–C28 were attacked by three lenses each. C29–C40, all minor, drew the
already-addressed lens alone, by design, as did the minor C44, C48 and C49. The second
half was re-run after an interrupted first pass, and its coverage is: C45, C46, C47, C50
and C51, three lenses each; C41, C42, C43 and C52, four verdicts each; C53 and C54, five
each. A lens that ran twice on one challenge counts as two verdicts, which is why some
challenges carry more verdicts than there are lenses. The per-challenge entries below say
which ran on each.

| Refuter | The question it asks |
|---|---|
| **already-addressed** | Does the design set already answer this somewhere the challenger did not read? |
| **factual** | Is the claim true of Google's products and of the documents as written, as of 2026-09-11? |
| **engineering-judgment** | Granting the facts, is the proposed change the right engineering call at this stage, or is it over-correction? |

### How an outcome was decided

| Outcome | Rule |
|---|---|
| **Stands** | No refuter could dismiss it. Every refuter either conceded it or narrowed it without defeating it. |
| **Partially stands** | Some refuters dismissed it; a substantive part survived. |
| **Refuted** | A majority of refuters dismissed it. |

A refuter that concedes the claim but narrows its scope, its severity or its deadline does
**not** refute it. Several challenges below stand in a materially narrower form than they
were raised, and the narrowed form is what is recorded.

### Counts

| Outcome | Blocking | Major | Minor | Total |
|---|---|---|---|---|
| **Stands** | 2 | 27 | 10 | **39** |
| **Partially stands** | 0 | 6 | 0 | **6** |
| **Refuted** | 0 | 4 | 5 | **9** |
| **Total** | **2** | **37** | **15** | **54** |

Severity is booked in the narrowed form, per the rule above: C41 was raised as blocking and
is recorded as major, because both already-addressed passes and the engineering lens narrowed
it to *before S1 and before the first operator who is not a super admin* without defeating it.
Both blocking challenges stand. No challenge proposed a different architecture; the
two that came closest (a generic Admin SDK proxy, a bought platform) were raised in order
to be rejected on the record.

### What this was, and what it does not replace

This was a **machine-run review**. Eleven model-driven lenses read the documents and
Google's public documentation, and argued with each other. It is good at what it did:
finding contradictions between thirteen documents, finding controls with no mechanism,
finding claims that Google's documentation does not support, and finding assumptions that
were never written down.

It does not replace, and must not be cited in place of:

| Not replaced | Why |
|---|---|
| A human security review | Nothing here was reviewed by a person who is accountable for the tenant. The findings are arguments, not sign-off. |
| The data-protection assessment, and employee representative bodies where the jurisdiction has them | [Decision 8](09-open-decisions.md). A legal and social question no review pass can answer. |
| Testing against the tenant | Every statement about the tenant is still `Assumption:` or `tbd`. Two challenges cannot be settled at all until [decision 5](09-open-decisions.md) records an absolute account count for the pilot OU: C19, major, which partially stands, and C27, major, which was refuted but leaves the same unowned question. Neither is blocking; both verdicts are provisional until the count exists. |
| A code review | There is no application code — no agent, no action service, no dispatcher — and several findings (C50, C51, C52) are precisely about the fact that none of it has ever run. The setup automation in [`setup/walle_setup.py`](setup/walle_setup.py) does exist (about 7,950 lines, including `cmd_gcp`, `cmd_denials` and `cmd_teardown`) and several findings prescribe edits to it; it has not been code-reviewed here either. |
| Verification of every product fact | The refuters checked most claims against Google's documentation, and the factual lens ran on every contested challenge. The minor band — C29–C40, C44, C48 and C49 — drew the already-addressed lens alone by design, so its product facts rest on one lens. Agent Gateway's `europe-west1` availability (C29, C37) **could not be verified** from Google's pages and stays `tbd`. |

Where a lens disagreed with another lens, the disagreement is recorded rather than
averaged. Where the review's own completeness critic found a verdict weaker than its
evidence, that too is recorded, in "Residual risks knowingly accepted".

## Per-lens view

| Lens | Raised | Overall view, in one line |
|---|---|---|
| Threat model and attack surface | 6 | Yes — the right path; its blind spot is that it models the LLM as almost the only adversary and understates code running beside the refresh token, Firestore write access, stolen operator sessions and unsigned triggers. |
| Autonomy and control model | 6 | Yes — the ladder's shape beats every alternative; the weakness is the evidence behind it, which is untied to the platform that produced it and rests on small-sample point estimates. |
| Buy versus build and Google-native alternatives | 5 | Yes — as of 2026-09-11 nothing Google offers executes Workspace admin changes through an agent without DWD or a live super-admin session; the build rationale just needs writing down and dating. |
| Credential and identity model | 6 | No, not as written — the structure around the credential is right, but the principal type was chosen on a premise Google's documentation contradicts, and the robot user is the weakest link as designed. |
| Fit to the stated requirement | 6 | Right architecture, wrong document — the narrowing from "any action a human can do" to about ten write operations is never stated, sized or signed off, and scopes freeze before anyone asks. |
| Requester entitlement and the confused deputy | 6 | No, not as written — the design asks what the robot may do and never what the person behind the request may do; it needs an added check, not a new architecture. |
| Simplicity and over-engineering | 5 | Yes on the core, no on how much of it is scheduled for Stage 0 — a model on pinned scheduled runs, Eve's infrastructure months early, and a ladder specified well above what the pilot can reach. |
| Release engineering and change safety of the gate | 6 | No, not yet — the runtime architecture is sound but has no release-safety layer beneath it; every change to the gate first runs as the production credential holder. |
| Disaster recovery, state durability and evidence retention | 5 | Yes on the architecture, no on the document — fail-closed handles unavailability correctly, but nothing protects Firestore or the evidence from loss, and a restore silently rolls back the andon cord. |
| Operational and lifecycle risk | 6 | Sound safety architecture, wrong exposure to churn — the fastest-moving products sit on the autonomous path, the first Eve-gated write is about a year out and never stated, and there is no value baseline or stop rule. |
| The three-agent team and its interfaces | 6 | The doer/controller/analyst split is right as separation of duties, not as three language models — say plainly that Eve is a deterministic verifier, and stop provisioning Eve at Stage 0. |

## What stands

Forty-five challenges stand or partly stand. They are ordered by consequence if the design
were built as written: the two blocking ones and C41, the major finding whose deadline sits
with them, first, then integrity of the gate and the
credential, state and evidence durability, the controller, the evidence behind the ladder,
change safety, and finally fit and proportionality.

Each carries **the decision**: *change now*, *accept with a stated reason*, or *open a
decision*. "Change now" means the edit belongs in the design set before the build starts;
it does not always mean the mechanism is built now.

---

### C50 — There is no pre-production credential holder (blocking, stands)

**Claim.** The safety case rests on deterministic code in `walle-actions`, but there is one
project, one action service, one robot and one tenant. The first process ever to run a
changed policy chain, catalogue handler, inverse or verifier holds the production refresh
token. The sandbox OU is not an environment: it is a target inside the production tenant,
reached with the production credential, kept safe only by the code under test.

**Why the refuters could not dismiss it.** All three ran and none refuted it. The
already-addressed lens found no second environment anywhere in the set: one project, one
subgraph, and a grep across all eighteen documents returning only the Agent Runtime
artefact *staging bucket*, an unrelated use of the word. It found the design moving the
other way — [SETUP.md](SETUP.md) Phase 12b grants `run.invoker` on the **production**
`walle-actions` to the throwaway spike principal, and section 6.1 requires exactly one
reasoning engine in the region, so a staging engine cannot coexist. The factual lens
verified every platform fact at high confidence: Groups privileges are absent from the list
of privileges an OU-scoped custom role may carry, `isOuScopable` is a real per-privilege
field on `privileges.list`, and Binary Authorization on Cloud Run takes
`--binary-authorization=default`. The engineering lens, at medium confidence, agreed the
gap is real and unwritten — "nothing anywhere says where a changed policy chain, catalogue
handler, inverse or verifier first executes, and the answer today is in the process holding
the production refresh token" — while rejecting the three-environment remedy as heavier
than this situation justifies.

**Narrowed to**, by the already-addressed and engineering lenses jointly. Both corrected
the same load-bearing sentence: "only the policy chain and the OU-scoped role keep writes
inside it — which is exactly the code under test" conflates two things, because the
`scopeType=ORG_UNIT` assignment is enforced by Workspace independently of our code, as
[09](09-open-decisions.md)'s closed rows record. Through Stage 0 the robot holds `Wall-E —
Reader`, which carries no write privilege at all, so no code defect of any kind can write
to Workspace before a human makes the Stage 1 role assignment. What is left is group-family
writes (F3, F3b) and every other privilege `privileges.list` reports as not OU-scopable:
Workspace cannot fence those off at all — [SETUP.md](SETUP.md) Phase 2 already records that
Groups and Reports privileges cannot be organisational-unit scoped — so for those families
the only containment is the code under test, and F3b is exactly the escalation path attack
A8 exists to stop. The correct severity is *blocking before any F3 or F3b cell leaves L1*,
not blocking before build, since Stage 0 executes no writes. One correction to the
containment argument from the factual lens: the **user** half is established, the
**licence** half is not — licence management appears on no published list of OU-assignable
privileges, and [SETUP.md](SETUP.md)'s own non-scopable list does not mention it either
way, so whether licence writes are OU-contained is unresolved and must be settled with
`privileges.list` `isOuScopable` before it is relied on.

**Decision: open a decision, and change 01 now.** New decision 29 (environments and
promotion), due before Stage 1's first write. Edit: add a short **"Environments and
promotion"** section to [01-hld.md](01-hld.md) stating that (a) the default first execution
of any changed gate is an offline harness with no credential, (b) whether a second
credential holder exists is decision 29, and (c) until it is answered no F3 or F3b cell
leaves L1. The proportionate build is an offline harness (C52) plus a second robot scoped
to the sandbox OU and holding no customer-scoped Reader, fronted by a second Cloud Run
service in Wall-E's project (`WALLE_PROJECT`) — not a second Agent Runtime engine, because
what is under test is deterministic Python. The factual lens corrected the cost of the separate-tenant option
the decision has to weigh: Cloud Identity Free raises the user cap by 50 at no cost and
supports custom administrator roles, and the Directory API works against it, so users, OUs,
groups and custom-role behaviour — the F3/F3b families, which are the only ones Workspace
cannot contain — can be exercised in a genuinely separate tenant for free. What it cannot
exercise is anything needing Workspace services: Gmail, Chat, Calendar, licence SKU
assignment and the service-specific reports. Frame decision 29's tenant sub-question as
"free identity-only tenant now, paid tenant only if those families need it". Binary
Authorization is deferred: a custom attestor adds key custody to a one-person rota.


*Note of 2026-09-13.* The four-project topology ([../project-topology.md](../project-topology.md))
separates Eve, Mo and the Gemini Enterprise app from Wall-E's project but adds no
pre-production credential holder: there is still one `WALLE_PROJECT`, one action service,
one robot and one tenant. C50 stands unchanged; "in the same project" above reads "in
`WALLE_PROJECT`".
---

### C41 — The requester's own entitlement is never checked (raised blocking, recorded major, stands)

**Claim.** The action service decides what the robot may do and never what the person
asking may do. Policy step 5 checks group membership; step 6 checks the target against the
family's OU allowlist, not against the requester's admin scope. A delegated admin whose own
role covers one OU, or none, can request — and at L3 approve alone — a suspension, a licence
removal or a membership change in any allowlisted OU, recorded by Google as `walle@`.

**Why the refuters could not dismiss it.** Four verdicts — the already-addressed lens twice,
the factual lens and the engineering lens — all at high confidence, and none refuted it. Both
already-addressed passes conceded the gap outright. The second one greps the whole set for
"entitle", "own admin role", "roleAssignments" and "requester" and finds three hits, none of
them a requester check: two are about the *robot's* own OU-scoped role assignment, one is
about the robot not editing its own role. It confirms that the only two-person rule in the
set is for ladder *promotions*, not for per-action T0/L3 approvals, and that the playbook
owner is checked only for membership (`must be in walle-operators@ at run time`) with no
scope comparison. The nearest existing text is the [06](06-security-guardrails.md) threat
row "Insider misuse by an operator — operators can do operator things. By design", whose
reason is circular because "operator things" is never defined, and which does not hold for a
delegated admin whose role is narrower than the family's allowlist. The factual lens
verified the product claims the challenge rests on: `roleAssignments.list` accepts `userKey`
and `includeIndirectRoleAssignments` under `admin.directory.rolemanagement.readonly`, which
[02](02-identity-and-auth.md) already calls "required, not optional" in the frozen scope
list; the `RoleAssignment` resource carries `scopeType` (`CUSTOMER` or `ORG_UNIT`) with
`orgUnitId`; and the robot's Stage 0 role already holds `Admin roles → Read`. So the check
is buildable with no new scope, no new role and no DWD — the part that lens could have
killed.

**What the engineering lens rejected, and what it put in its place.** It granted the factual
core and refused the mechanism. Live entitlement step 5b as specified is (a) inert today and
for the likely second operator, since the only operator is a super admin whose assignment is
`scopeType=CUSTOMER` and [decision 11](09-open-decisions.md) asks for another Workspace
admin, so the intersection is vacuous for every person currently planned; (b) in direct
conflict with a reasoned position already in the set — [ARCHITECTURE.md](ARCHITECTURE.md)
section 7.5, "Operator authorisation is not circular, deliberately. The control and approval
endpoints authorise against a committed operator list carried in the deployed configuration,
never against a live Directory read" — because 5b puts a fail-closed live Directory read on
the approval path, so a Directory outage stalls approvals on a one-person rota; (c) built on
a privilege-name-to-operation mapping the set twice records as unverified; and (d) the
opposite of least privilege in practice, because a hard "the requester must already hold the
privilege" rule means nobody can be given capped, catalogued, budgeted, reversible reach
through Wall-E without first being given the broader console privilege. Its replacement is
the challenger's own cheaper option: record each operator's admin role, families and OU
scope in the committed operator list, reconcile it daily against `roleAssignments.list`, and
alert on divergence — no new scope, no privilege table, no live read on the request path,
git-reviewed. It also found, and none of the other lenses disputes, that
[04-flows.md](04-flows.md) Flow A checks "approver in operators" and `approver_is_agent` but
carries no approver-is-not-requester rule, which becomes a real separation-of-duty gap the
day decision 11 adds a second operator.

**Narrowed to**, by both already-addressed passes and by the engineering lens. Severity is
*major, due before the first operator who is not a super admin and before S1*, rather than
blocking-before-build: at S0 no write executes, every write family sits at L1 shadow, and
the design has not been built. One corrected fact sharpens the deadline rather than
softening it. The set contradicts itself about how many operators exist at S0:
[SETUP.md](SETUP.md) Phase 1 lists `$OPERATORS` as "you, plus `<second-operator>`", while
[ARCHITECTURE.md](ARCHITECTURE.md) section 0 assumes "the ladder owner alone at S0". On
SETUP's version the read-side exposure is already live, because reads run at L5, so a second
operator added in Phase 1 gets tenant-wide login, token and admin audit reads whatever their
own role. That contradiction has to be settled either way. One constraint on the remedy,
from the factual lens: Google states
that Groups and Reports privileges cannot be limited to organisational units, so for those
families an entitlement check can only be privilege-level, never OU-level. The full
intersection is available only for OU-scopable families (Users, Organizational Units, User
Security Management). The self-approval sub-point is a separate defect and is carried on
C8.

**Decision: change now, and open a decision.** Edits, all now:
- [01-hld.md](01-hld.md) trust-boundary table, rows 1 and 4: say plainly that group
  membership grants the right to *use* Wall-E and is not a bound on reach, and add the
  "How it can still fail" column that [ARCHITECTURE.md](ARCHITECTURE.md) section 6 already
  uses.
- [06-security-guardrails.md](06-security-guardrails.md): define "operator things".
- [09-open-decisions.md](09-open-decisions.md) [decision 11](09-open-decisions.md): before
  any operator is added, record their admin role and their intended family and OU reach in
  the committed operator list, and reconcile it daily against `roleAssignments.list` with
  divergence alerting. This is the engineering lens's counter-proposal and it is what lands
  now: it reuses the committed list [ARCHITECTURE.md](ARCHITECTURE.md) section 7.5 already
  keeps, needs no new scope and puts no live Directory read on the request or approval path.
- [04-flows.md](04-flows.md) Flow A: an approver must differ from the requester, from the
  moment a second operator exists. (Carried on C8, which owns the self-approval defect.)
- [03-lld.md](03-lld.md): policy step 5b — for human principals, intersect the request with
  the requester's own role assignments and privileges, read through the already-frozen
  `rolemanagement.readonly` scope — is recorded as the **stronger version, not built now**.
  It is buildable, as the factual lens confirmed, but the engineering lens rejected it at
  this stage for the four reasons above, and the set should carry the reasons rather than
  the bare option. Revisit it when an operator exists whose own admin scope is narrower than
  a family's OU allowlist.
New decision 28 records the rule, its deadline, and 5b as the deferred stronger form.

---

### C1 — The requirement was narrowed and never signed off (blocking, stands)

**Claim.** The requirement is an agent that can do any action a human admin does. 01 never
quotes it; the README keeps the autonomy half and drops the breadth half. What is left is
seven write operations plus notifications inside a catalogue of about sixteen typed
operations. Wall-E will never touch security settings, SSO, DLP, devices, Chrome, Drive,
Vault, billing, third-party apps, user creation, passwords or admin roles. Each exclusion
is argued somewhere in [06](06-security-guardrails.md) or
[ARCHITECTURE.md](ARCHITECTURE.md) section 10; the total is never set against the
requirement, and scopes freeze at consent.

**Why the refuters could not dismiss it.** All three conceded. The typed catalogue is the
right safety choice and no product safely offers any-action admin agents without DWD or a
live super-admin session — but that is an argument for the design, not a reason the owner
should not be told. The factual lens added that 01 never separates exclusions *forced* by
the standing constraints (Devices and Alert Center are DWD-only; Policy API writes are
limited to DLP) from exclusions *chosen* for safety. The already-addressed lens found a
live contradiction: [02](02-identity-and-auth.md) and [SETUP.md](SETUP.md) say "err wide on
reads" while [ARCHITECTURE.md](ARCHITECTURE.md) section 4.3 says any scope with no catalogue
operation is removed.

**Decision: change now, and open a decision ordered before decision 3.** Edit: add a
**"Requirement fit"** section to [01-hld.md](01-hld.md) sorting admin work into three
bands — (A) in the catalogue, (B) reachable with a custom-role token and no DWD but
deliberately excluded with the reason, (C) unreachable under the standing constraints and
therefore permanently human — and state in design intent that write coverage is the
catalogue, not the Admin console. New decision 27 puts bands B and C to the owner and must
be answered **before** [decision 3](09-open-decisions.md) closes. Widen
[decision 4](09-open-decisions.md) to ratify the whole "Never in the catalogue" table, not
only the nine N-rows. Resolve the read-breadth contradiction in favour of one rule, stated
in one place.

---

### C5 — Firestore is the integrity root and its IAM cannot enforce the rules the design claims (stands)

**Claim.** The HLD puts ladder config, halt flags, counters and approvals in Firestore.
Server client libraries bypass Security Rules, and Firestore IAM is per database, not per
collection. [SETUP.md](SETUP.md) grants project-level `roles/datastore.user` to both
`walle-actions@` and `walle-dispatcher@`. So the dispatcher — which parses trigger payloads —
can raise ladder levels to the code ceilings, clear halt flags, reset budgets and novelty
counters, delete dedup records, and move a plan to `released`. "Plans are create-only" has
no mechanism.

**Why the refuters could not dismiss it.** Unanimous at high confidence. Two narrowings
were granted and neither defeats it: a Firestore write cannot push a level above the code
ceilings in the image, and raising a level needs both `ladder/current` and the override
document rewritten because an absent override reads as L0. Both remain reachable with
`datastore.user`. The realistic harm is silently clearing a halt, resetting a budget, or
deleting a dedup record — none of which needs a level change.

**Unresolved limb, settled here.** Whether a Firestore writer can cause an *unapproved
execution* depends on whether the Cloud Tasks worker re-verifies the approval, and the
design does not say. [03-lld.md](03-lld.md) says the worker "repeats the whole policy
chain", whose step 11 is "approval verification … nonce not yet consumed" — but the nonce is
consumed once, before the first Workspace call, so that test cannot hold for items 2..N of a
released plan. Either the worker re-verifies the stored signed envelope without the
nonce-freshness test, or it trusts the Firestore `released` state. If it trusts `released`,
a `datastore.user` writer can cause execution of a plan nobody approved, and this limb is
blocking.

**Decision: change now.** Edits:
- [03-lld.md](03-lld.md) and [04-flows.md](04-flows.md): state that the worker re-verifies
  the stored approval envelope — signature over `plan_hash`, `config_version` and key
  version, plus the recorded per-human assertion — on **every** item, and that the
  `released` lifecycle state is a cache, never the authorisation.
- [SETUP.md](SETUP.md) Phase 6 and 7: remove project-level `roles/datastore.user` from
  `walle-dispatcher@`; give it a custom role limited to reading halt flags and writing
  dedup and cooldown documents.
- [03-lld.md](03-lld.md), [ARCHITECTURE.md](ARCHITECTURE.md) section 7.1 and weakness 1, and
  the [06](06-security-guardrails.md) "Ladder config tampering" row: replace "create-only"
  with a real mechanism — an immutable plan body in its own database or under a custom role
  with `entities.create` and `get` only, with lifecycle state in a separate collection — or
  say that create-only is a convention, not a control.
- The strongest structural option, worth recording as rejected-for-now rather than
  ignored: CI compiles ladder levels into the action-service image beside the ceilings, so
  `config_version` is part of the signed image and Firestore holds only halt flags and
  demote-only overrides. Promotion then becomes pull request plus deploy, which is what
  design intent 4 already claims it is.

---

### C3 — A service account can hold a Workspace admin role without DWD (stands)

**Claim.** 01 design intent 1 and [02](02-identity-and-auth.md) build everything on a user
account because "without DWD a service account cannot become a Workspace user". True, but
it does not follow that a user is needed. Google's Admin Help, updated 2026-09-10, states
that any prebuilt or custom role except Super Admin can be assigned to a service account,
which then calls admin APIs with its own token, no subject and no DWD, appearing as itself
in the admin audit log.

**Why the refuters could not dismiss it.** All three conceded; the factual lens at high
confidence, verified again on 2026-09-12 against
`knowledge.workspace.google.com/admin/users/assign-specific-admin-roles`, which says
plainly: any prebuilt or custom role except Super Admin can be assigned to a service
account.

**Narrowed to.** The title overstates it: 02's actual sentence is true, and it is the
*implication* that is false. And coverage beyond the Groups APIs is not documented, so this
is a spike, not a rewrite. What is certain is that 02 omits a documented, DWD-free option
for the admin half of the credential, and lists it nowhere in its rejected alternatives.

**Decision: open a decision, spike before Phase 9.** New decision 26. Edit
[02-identity-and-auth.md](02-identity-and-auth.md) to add "service account holding the
custom admin role, no DWD" to the alternatives table as **pending**, not rejected. The
spike runs on a throwaway service account with the reader role, through ADC, with no key and
no subject, and tests: `users.list`, `orgunits.list`, `roleAssignments.list`,
`privileges.list`, Reports `activities.list` and usage reports, `licenseAssignments`, a
sandbox `users.update`, and whether an `ORG_UNIT`-scoped assignment is accepted. Record the
result in the decision either way. If it passes, the design loses the password, the recovery
path, the hardware key, the interactive consent, the frozen scope set and the stealable
refresh token for the admin half — and C4, C6, C9, C32, C33 and C47 shrink or disappear with
it.

---

### C4 — The refresh token is a portable, unbound bearer credential the login alert cannot see (stands)

**Claim.** [02](02-identity-and-auth.md) and [SETUP.md](SETUP.md) call the interactive-login
reporting rule the highest-value control, and [06](06-security-guardrails.md) lists login
alerting against "Robot credential leak". Using a refresh token is not a login, so that
alert never fires on theft: it detects account takeover, not credential use. The token and
the Desktop OAuth client secret sit together and work from any host — `gmail.send` as the
tenant's admin robot, tenant-wide directory and audit reads, and every write the role
allows. The agent, which holds nothing, gets certificate-bound tokens; the credential
holder does not.

**Why the refuters could not dismiss it.** Unanimous, two at high confidence. The factual
lens confirmed the design has no control that detects or limits replay of the token from
another host, no egress restriction and no dependency pinning on the only credential
holder. So the [06](06-security-guardrails.md) residual "bounded by the role's privileges"
is bounded in *scope* but not in *place*.

**Decision: change now.** Edits:
- [02](02-identity-and-auth.md), [SETUP.md](SETUP.md) and
  [06-security-guardrails.md](06-security-guardrails.md): re-label the login reporting rule
  as a control against **interactive takeover only**.
- [06](06-security-guardrails.md) "Robot credential leak" residual: rewrite as "a replayed
  refresh token works from any host, for the full frozen scope set, until detected".
- [06](06-security-guardrails.md) Monitoring: add a severity-1 row for robot or Wall-E
  OAuth-client activity originating outside `walle-actions`, gated on a spike before Phase 9
  on whether `ipAddress` and `oauthClientId` are reliably present on the relevant admin and
  token audit events.
- [ARCHITECTURE.md](ARCHITECTURE.md) section 4: pin `walle-actions` dependencies by hash and
  restrict its egress (Direct VPC egress, firewall denying all but Google API ranges, Cloud
  NAT static IP) so that the same code that holds the credential cannot freely reach the
  internet.

---

### C7 — T2 events are unsigned Pub/Sub messages the action service may itself publish (stands)

**Claim.** The design trusts T2 events as Google's record, and at Stage 5 lets "a human
admin's own suspension event" be the system-of-record trigger for L4 suspension. Log entries
routed to Pub/Sub carry no signature; authenticity rests entirely on who may publish to
`walle-triggers`. [SETUP.md](SETUP.md) grants `roles/pubsub.publisher` to `walle-actions@` at
**project** level, covering every topic. Pub/Sub writes no Data Access audit log for
Publish, so a forged event leaves no Google trace.

**Why the refuters could not dismiss it.** Unanimous, the factual lens at high confidence
calling the whole challenge sound. The [06](06-security-guardrails.md) "Poisoned upstream
signal" row asserts a signature that does not exist. One narrowing on impact: a fully
compromised action service already holds the robot's token and can call the Admin SDK
directly, so for that attacker a forged trigger adds *laundering* rather than reach — the
write looks like a legitimate leaver run, and Eve co-signs an L4 suspension she would
otherwise question.

**Decision: change now.** Edits:
- [06-security-guardrails.md](06-security-guardrails.md): correct the control wording.
  Messages are unsigned; authenticity rests on topic-level publish rights held only by the
  sink writer identity, the Gmail push identity on `walle-inbox`, and the Pub/Sub service
  agent on the dead-letter topic.
- [SETUP.md](SETUP.md) Phase 6 and `setup/walle_setup.py`: drop project-level
  `roles/pubsub.publisher` from `walle-actions@` and bind it at topic level on
  `walle-events` only. This also protects the A5 no-loop property against an action-service
  bug.
- [03-lld.md](03-lld.md): before opening a T2 run, corroborate the trigger against Google's
  own copy — the BigQuery row by `insertId`, or `reports.activities.list` by a unique
  qualifier. An uncorroborated event opens no run.

---

### C8 — One stolen operator session can both request and approve (stands)

**Claim.** A T0 `WRITE_HIGH` request is gated at L3 by an approval on the IAP page,
authenticated by the same browser session that uses Gemini Enterprise. No rule requires the
approver to differ from the requester, and there is no step-up at the approval surface. With
a one-person rota, self-approval is structurally required. Separately, the T0 write path
authorises by live membership of `walle-operators@`; Groups privileges are customer-scoped
only, so every admin with Groups rights can create an operator.

**Why the refuters could not dismiss it.** Unanimous. Partial credit was given:
[ARCHITECTURE.md](ARCHITECTURE.md) section 7.5 and
[12-agent-identity.md](12-agent-identity.md) section 5.4 already authorise *approvals*
against the committed operator list rather than live membership, so a newly added group
member cannot approve. But the T0 **request** path and the group-bound grants (agent
sharing, content logs, call path) still key on live membership, caught only by a daily
divergence check.

**Decision: change now.** Edits:
- [01-hld.md](01-hld.md) T0 path and trust boundary 1, and [03-lld.md](03-lld.md) policy
  step 5: require **both** live group membership and presence in the committed operator
  list.
- [04-flows.md](04-flows.md) Flow A: an approver must be a verified identity different from
  the requester, from the first real write. While the rota is one person, record
  self-approval as a named exception covered by step-up.
- [SETUP.md](SETUP.md): set IAP `reauthSettings` on `walle-approvals` — `SECURE_KEY`,
  `maxAge` 300s, `policyType` `MINIMUM`. Workforce-identity operators need an equivalent IdP
  step-up, which is `tbd`.
- [06-security-guardrails.md](06-security-guardrails.md) Monitoring: add a row for any
  membership or ownership change on `walle-operators@`, from the Groups audit log.

---

### C6 — The Trusted OAuth client is a consent-phishing vehicle (stands)

**Claim.** The runbook marks the robot's Desktop OAuth client Trusted in API controls with
no OU selected, so it applies organisation-wide: the client may access all Google services,
restricted ones included, for every user. The consent screen is Internal, so any user can
authorise it with no unverified-app warning, under the tenant's own app name. A Desktop
client secret is not confidential. Anyone holding it can send an admin a Wall-E
authorisation URL for directory and Gmail scopes and coax back the loopback code.

**Why the refuters could not dismiss it.** All three conceded the narrowed form: the client
is trusted tenant-wide when only the robot needs the trust, and where API controls restrict a
service or block unconfigured apps, Wall-E's trusted client becomes the way past those
restrictions under a known app name. Nothing alerts on another user authorising it. Three
limits were recorded and none defeats it: the mechanism is not unique to Wall-E; it needs
the client secret; and [SETUP.md](SETUP.md) Phase 9 already shreds the local `client.json`
after storing it in Secret Manager.

**Decision: change now, in the Phase 9 sitting.** Edits:
- [02-identity-and-auth.md](02-identity-and-auth.md) OAuth client table and
  [SETUP.md](SETUP.md) Phase 9 step 4 and section 7.2: mark the client Trusted for the
  robot's OU only, and Blocked at the top-level OU. `Assumption:` a child-OU override of a
  Blocked root inherits like other API-control settings — verify before consent.
- [06-security-guardrails.md](06-security-guardrails.md) Monitoring: add a row for any token
  authorize event on Wall-E's `client_id` by an identity other than the robot. Whether OAuth
  token events reach Wall-E's Cloud Logging sinks is not verified and must be checked in
  Phase 5.
- Also add the monitoring row the review's critic found missing: access to
  `walle-oauth-client` by a non-service identity. The severity downgrade this challenge
  received assumed such an alert exists, and it does not.

---

### C32 — For admin APIs the role is the ceiling, not the scope set (stands)

**Claim.** The irreversibility of the scope freeze is acceptable, but the design overweights
it and misstates its mechanics. For admin APIs a consented write scope grants nothing the
role lacks — [SETUP.md](SETUP.md) Phase 9's own 403 probe proves it. "Narrow on writes"
matters for user-data scopes (Gmail, Chat, Calendar), not admin scopes. Keeping
`admin.directory.user.security` out "pending decision 3" buys no safety while the role lacks
the privilege, and guarantees a re-bootstrap if leaver hygiene is wanted. Separately,
[SETUP.md](SETUP.md) justifies "never reuse a client" with the 100-token limit, which is per
Google Account per OAuth client.

**Why the single refuter could not dismiss it.** One refuter ran, the already-addressed lens,
at high confidence. Verified again on 2026-09-12 for this page: Google documents "a limit of
100 refresh tokens per Google Account per OAuth 2.0 client ID".

**Decision: change now, and it feeds decision 26.** Edits:
- [02-identity-and-auth.md](02-identity-and-auth.md), [ARCHITECTURE.md](ARCHITECTURE.md)
  section 4.4 and [SETUP.md](SETUP.md) Phase 9 rollback and troubleshooting: correct the
  token-limit wording to "at most 100 live refresh tokens per Google Account per OAuth
  client; a new one silently invalidates the oldest", and remove the claim that reuse across
  clients is the likely cause of `invalid_grant`.
- [ARCHITECTURE.md](ARCHITECTURE.md) section 4.3 and [02](02-identity-and-auth.md): state
  the two-enforcement-point rule plainly — the role is the ceiling for admin APIs, the scope
  is the ceiling for user-data APIs.
- Reframe [decision 3](09-open-decisions.md): consent now to every admin scope the ladder
  could plausibly use, including `admin.directory.user.security` and `admin.datatransfer`,
  because the staged role is the gate; keep user-data scopes narrow. If decision 26 moves
  the admin half to a service account, the admin-scope question disappears entirely.

---

### C45 — A Firestore restore silently rolls back the andon cord (stands)

**Claim.** The HLD makes Firestore the live safety state, and [03](03-lld.md) covers
Firestore being *unavailable*, never Firestore being *lost or corrupted*. A restore brings
back the database as it was at an earlier minute; every halt, override, consumed nonce,
dedup record, cooldown and counter written after that minute is gone. The "absent reads as
L0" sentinel does not help, because the restored documents are present, just older.

**Why the refuters could not dismiss it.** Three lenses ran — already-addressed, factual and
engineering — all at high confidence, and all three conceded. The already-addressed lens
greps the whole set and finds no hit on Firestore durability at all: every "restore" in the
set is about restoring a suspended *user* or a fallback IAM grant. Attack A4 covers
unavailability only; A12's reconciler *assumes* the consumed nonce and the `in_flight`
record survive, which is exactly what a restore removes — and worse, the reconciler reads
`in_flight/{run_id}#{item}` **from Firestore**, so after a restore it is itself working from
rolled-back state. It also names the sentence a restore falsifies:
[ARCHITECTURE.md](ARCHITECTURE.md)'s "the andon cord cannot un-pull itself during an outage"
is an unavailability claim and is untrue of a restore. The factual lens verified every
Firestore product fact as cited: PITR retains seven days when enabled and one hour when not,
at whole-minute granularity beyond the past hour; a backup restore "writes the data from a
backup to a new Firestore database" and needs an unused database id; backup retention runs
to fourteen weeks; and `--delete-protection` exists on both `databases create` and `update`.
It confirmed the design-side allegation literally: [SETUP.md](SETUP.md) Phase 7 is a bare
`gcloud firestore databases create --location --type` with none of the three. The
engineering lens called it the strongest of the durability findings on effort-to-benefit,
and supplied the argument the challenge does not make: a restore is a *machine* action that
raises an autonomy level and clears the andon cord, which inverts the set's own rule that
only humans loosen anything. It also found the boot check nearly free, because
[03-lld.md](03-lld.md) already stamps monotone `halt_epoch` and `override_epoch` counters on
every audit row — BigQuery already holds the high-water mark; the design just never compares
it live.

**Narrowed to**, by the already-addressed and engineering lenses, which narrowed the same
thing independently: the illustration should change. A restore does not by itself re-drive
an executed item, because its Cloud Tasks task was acked and is gone. The airtight replay
path is the one the challenge lists but does not lead with: `dedup/{trigger_id}` and
`idempotency/{key}` are rolled back too, so a redelivered Pub/Sub message or the next
scheduler window re-runs a job that already ran, with the 24-hour per-principal cooldown and
the durable budget counters also reset. One corrected fact strengthens the claim rather than
weakening it: "PITR and backups restore into a new database" holds for a backup restore and
for a clone, but a PITR **export can be imported into the existing database**, and Google's
own documentation notes that import overwrites existing documents — so the rollback can also
happen in place, on the live database id, with no config change for anyone to notice.

**Decision: change now, at Phase 7.** Edits:
- [SETUP.md](SETUP.md) Phase 7: create the database with PITR and delete protection enabled,
  plus a daily backup schedule; `walle verify` reads `pointInTimeRecoveryEnablement` and
  `deleteProtectionState` from the Firestore Admin API Database resource rather than
  asserting a `gcloud describe` column spelling.
- [03-lld.md](03-lld.md): log every halt, override and breaker demotion as a row in
  `walle_audit`, not only ladder changes, so BigQuery holds a high-water mark for
  `halt_epoch` and `override_epoch`.
- [03-lld.md](03-lld.md) and [01-hld.md](01-hld.md): **a restored control plane starts at
  `halt_all`**; at boot the service compares Firestore's epochs against the BigQuery
  high-water mark and denies with a new `control_plane_rolled_back` reason until an operator
  clears it.
- [05-autonomy-ladder.md](05-autonomy-ladder.md) Stage 1: the full reconstruction script
  (recomputing cooldowns and counters from 30 days of `actions`, reconciling `in_flight`
  against the Workspace log copy) and a quarterly restore drill, recorded in the existing
  `drills/{date}` machinery.
- Note for the runbook: recovery normally lands in a **new** database id — a clone or a
  backup restore both require an unused one — so the existing database id is a config value
  the boot check must be able to compare against. But the id changing is not a reliable
  signal on its own: Firestore documents an in-place restore that deletes the source
  database first and is irreversible, and a PITR export re-imported into the live database
  overwrites existing documents. Both roll the control plane back under the same id. The
  epoch comparison, not the database id, is what has to catch it.

New decision 30 records the RPO and RTO per store.

---

### C46 — The promotion evidence is not durable (stands)

**Claim.** `walle_audit` is what every promotion is argued from, and its protection is a
single insert-only rule binding one service account. `walle teardown` runs `bq rm -r -f -d`
on both `walle_audit` and `walle_workspace_logs` after one typed project id, and Phase 7
rollback does the same. BigQuery's undelete works only inside the time-travel window and is
lost the moment a dataset with the same id is created again — which is exactly what
re-running `walle gcp` does. Grades, proposal verdicts and drill results exist only in
Firestore.

**Why the refuters could not dismiss it.** Three lenses ran — already-addressed, factual and
engineering — all at high confidence, and none refuted it. The already-addressed lens found
that every existing protection binds exactly one principal: the insert-only grant on
`walle-actions@` and the dataset split constraining the sink writer. Neither touches
teardown, project owners, dataset-id recreation or project deletion. It confirmed both
deletion paths in the code — `cmd_teardown` loops `bq rm -r -f -d` over the audit and log
datasets behind one typed project id, and Phase 7 rollback does the same — and confirmed
that `grades/{run_id}#{item}`, `proposals/{id}` and `drills/{date}` appear in the Firestore
list and in no BigQuery table. The factual lens verified the BigQuery facts the challenge
rests on: time travel is two to seven days, configurable with `bq mk
--max_time_travel_hours` in the range 48 to 168; fail-safe adds seven days that only Cloud
Customer Care can reach; "if you delete a dataset and then create a new dataset with the
same ID, you lose the ability to undelete the original dataset"; Bucket Lock applies a lien
on the project and a locked policy can be lengthened but never shortened or removed; and
Reports retention is six months. The engineering lens put the finding on stronger ground
than disaster recovery — it is an internal inconsistency the design already carries.
[05-autonomy-ladder.md](05-autonomy-ladder.md) section 8 says the ladder metrics are
BigQuery scheduled queries and defines plan precision as items accepted ÷ items graded, but
the grades are Firestore-only: the evidence every promotion is argued from cannot be read by
the thing the design says reads it, before any teardown happens.

**Narrowed to**, by the factual and engineering lenses. The Firestore-durability half is
cheaper than the challenge assumed, because Firestore has scheduled backups and PITR (C45) —
"Firestore has no backup" is true of this design, not of the product, and should be written
as "no backup is configured". What survives untouched is the teardown-and-recreate path and
the fact that the Workspace-side copy ages out after six months. The engineering lens
refused the heavy half: a separate evidence project, a project lien and a locked retention
policy as a new **blocking** pre-build decision are not clearly better here, because against
a single all-powerful owner only a locked policy is a real control, and the challenge itself
defers that lock behind decisions 8 and 17 — so what would actually ship is an unlocked copy
the same owner can delete, while a lien fights a runbook that expects teardown and rebuild
during the build phase. The realistic loss path is the owner's own teardown-then-rebuild,
and the teardown precondition plus the refusal to recreate an undeletable dataset id buys
nearly all of that protection at a fraction of the cost. One correction from the
already-addressed lens: the in-project `walle_workspace_logs` copy is not the only
Google-authored record after six months. Both Workspace sinks are already
**organisation-level**, and the second carries no principal filter by design, so a third
copy may exist at org level with retention `tbd` — unknown rather than absent. The accurate
sentence is "the only copy this project controls". It also makes the off-project copy
cheaper than proposed: repointing an already-org-level sink's destination is a destination
change, not a new sink architecture.

**Decision: change now, plus a Stage-1 item.** Edits:
- [03-lld.md](03-lld.md) storage: grades, proposal verdicts and drill results are written
  **write-ahead to `walle_audit`** as first-class tables, with Firestore as a cache. This is
  a schema decision, cheap now and expensive later; without it
  [05](05-autonomy-ladder.md) section 8's scheduled queries cannot compute plan precision or
  drill freshness at all.
- `setup/walle_setup.py`: teardown refuses to drop `walle_audit` without an explicit
  evidence-abandoned flag and an export; `walle gcp` refuses to recreate a dataset id still
  inside its time-travel window.
- [09-open-decisions.md](09-open-decisions.md): move [decision 17](09-open-decisions.md)
  (audit retention) from "Stage 3 onward" to **before Stage 1**, and word it as a minimum
  *and* a maximum, because evidence starts accruing at Stage 0 and the data-protection
  assessment may impose both.
- New decision 31 records an off-project copy of `walle_audit` and the Workspace log copy,
  owner `tbd`, locked only once decisions 8 and 17 are answered. A separate evidence project
  with a project lien is the strong form and is **not** required before build.

---

### C47 — The robot account has no lifecycle detection and no recovery objective (stands)

**Claim.** The design protects the robot from Wall-E and from interactive logins. It does
not protect it from other administrators. Removing the role assignment returns 403, not
`invalid_grant`, so the one paging rule does not fire and the breaker sees a generic
`forbidden`. A password reset revokes the token because Gmail scopes are on the grant. A
deletion is restorable for 20 days only; past that a same-address account is a new user.

**Why the refuters could not dismiss it.** Three lenses ran — already-addressed, factual and
engineering — all at high confidence, and none refuted it. The already-addressed lens found
the detection half load-bearing and unanswered: there is exactly one Workspace rule in the
whole set and its condition is on the **actor** — "`Actor` (user email) **is** `$ROBOT`" on
the Login audit log — so another super admin suspending, renaming or deleting the robot, or
removing a role assignment, is an admin-activity event with a different actor and that rule
cannot fire. The events *are* captured, because Phase 5 shares admin audit logs to Cloud
Logging and the second sink carries no principal filter, so the data sits in
`walle_workspace_logs` and nothing reads it — which makes the gap cheap to close rather than
excusable. The factual lens verified the platform facts: deleted Workspace users are
restorable for twenty days and not after; Google's own list of refresh-token revocation
causes includes a password change when the token carries Gmail scopes, which this grant
does; and suspension and deletion are *not* on that list, so the challenge's "plan as if they
do not survive" is the right posture rather than a verified fact. The engineering lens
supplied the decisive argument, from the design's own error vocabulary:
[SETUP.md](SETUP.md) section 7.4 enumerates seven causes of a dead credential and every one
surfaces as `invalid_grant`, which is a paging incident — but a removed role assignment, a
suspension or a rename produces an authorisation failure, and the closed error enum has one
bucket for that, `forbidden`, shared with ordinary policy outcomes. So the single paging
rule provably does not fire on the most likely administrator mistake, and the breaker sees a
generic error storm.

**Two premises corrected, in the design's favour.** The already-addressed and factual lenses
both struck out the recovery-material half as the challenge stated it.
[SETUP.md](SETUP.md) Phase 3 step 1 already requires a second hardware key registered at the
same time, both in the safe, separately labelled, with a witnessed record of who has access,
both recorded in the vault entry — and PREREQUISITES.md requires three keys, two of them for
the robot. The re-bootstrap objective is not absent either: section 5's K4 budgets 45
minutes for a full Phase 9 re-run. What is genuinely single-point is narrower than claimed:
the same safe, and one vault entry with no second named owner. The engineering lens argued
the bus-factor point from the summary page at [02](02-identity-and-auth.md) and so read it
as one key; that disagreement is recorded rather than averaged, and the runbook is the
authority. One naming correction from the factual lens: Google renamed reporting rules to
**activity rules** through September 2025, so the control to write is an activity rule on
admin log events. Its edition dependency is the same one the existing login alert already
carries, so the assumption is safe rather than speculative, and detection within minutes is
achievable without an `Assumption:` marker on the lag itself — admin log events arrive near
real time.

**Narrowed to**, by the engineering lens. Drop the RTO framing as the headline — Wall-E being
down is a safe state by design, which is what every kill switch produces, so "half a day to
re-bootstrap" is a cost, not a service-level breach. What matters is detection and bus
factor.

**Decision: change now, and open a decision.** Edits:
- [SETUP.md](SETUP.md) Phase 4: an **activity rule** — Google's current name for a reporting
  rule — on admin log events whose **target** is the robot: suspend, delete, rename,
  password change, 2SV change, role-assignment removal, paging like the login rule. The
  existing rule keys on `Actor is $ROBOT`, which is the wrong half. Edition support is the
  same dependency the login rule already carries, so it belongs with
  [09](09-open-decisions.md)'s existing "still to verify in console" item rather than as a
  new assumption. Detection in minutes needs no `Assumption:` marker: admin log events
  arrive near real time.
- [03-lld.md](03-lld.md) denial reasons: add `role_assignment_missing` as a distinct paging
  class, so a previously working call now returning `forbidden` is a signal rather than a
  generic bucket. The action service can detect its own loss; this does not wait for Eve.
- [SETUP.md](SETUP.md) section 7.4: add a rebuild checklist for a deletion past 20 days, and
  a second named custodian on the vault entry.
New decision 39 records the detection rule, the paging class, the second custodian and the
rebuild checklist, due before S0 opens.

---

### C48 — Destroying Eve's key version makes past approvals unverifiable (stands)

**Claim.** Teardown's optional `--destroy-key-versions` destroys Eve's signing key version;
once it is finally gone, no stored Eve signature in `walle_audit` can be re-verified. That
weakens the one record proving an Eve approval was genuine.

**Why the refuter could not dismiss it.** This is a minor challenge, so it drew the
already-addressed lens alone, by design; it ran at high confidence and conceded the Eve
half. Nothing in the set answers it: the action service holds only `publicKeyViewer` and
verifies **locally** against the live key, the `approvals` table records only "who, when, how
long they took, verdict, reason code", a KMS signature carries no version identifier of its
own, and no public key is archived anywhere — a grep for public key across every page returns
only IAM grants. So once a version is destroyed you cannot re-verify a stored signature and
cannot even establish which version signed it. That matters precisely because
[ARCHITECTURE.md](ARCHITECTURE.md) lists "mint an Eve approval" among the things
`walle-actions@` must never be able to do, and the stored signature is the only artefact that
proves it did not. The refuter confirmed the teardown paths in the code, and confirmed that
A2 and C11 are about who can *mint* an approval, not about verifiability after destruction.

**Narrowed to**, by the refuter. The Eve key only. Drop the `--version-destroy-ttl`
proposal: the challenge itself concedes that deleting a whole secret is immediate
regardless, so the flag gives no protection against the `gcloud secrets delete` loop in
teardown that the claim opens with; it protects only the version-destroy rotation path,
which the pinned-version warnings in [SETUP.md](SETUP.md) section 7.4 already cover. The
proposed HLD row for Secret Manager is documentation of what section 7.4 already does, not a
new control. One corrected fact, which changes the urgency and not the gap: **KMS
destruction is not immediate.** The default scheduled-for-destruction duration is 30 days
and a scheduled version is restorable throughout it, which the set already knows — "KMS keys
cannot be deleted, only their versions destroyed after a scheduled delay". After that window
the material is permanently gone and no public key was ever archived. The window is a month,
not a moment.

**Decision: change now.** Edit [03-lld.md](03-lld.md) `approvals` schema to carry
`eve_key_version`, and [SETUP.md](SETUP.md) to export each Eve public key version at
creation, so an approval stays verifiable after its key version is destroyed. Teardown
checks the export exists before offering `--destroy-key-versions`.

---

### C49 — Single region is right and unrecorded, and the self-halt is not sticky (stands)

**Claim.** Everything but BigQuery lives in `europe-west1`, and that is acceptable: a
regional outage stops every write, K5 works from the Admin console outside the region, and
the non-goals already exclude replacing the console in an emergency. Two gaps: nothing says
single region is a decision with an RTO equal to Google's regional recovery, and the
in-process self-halt after 30 seconds without Firestore is not specified as sticky.

**Why the refuter could not dismiss it.** This is a minor challenge, so it drew the
already-addressed lens alone, by design; it ran at high confidence and found both gaps real
and neither answered. A grep across the whole set for single region, failover, RTO, RPO and
disaster returns nothing: the only nearby rows are [01-hld.md](01-hld.md)'s corrections table
and [09](09-open-decisions.md)'s closed "Agent Engine in `europe-west1`? Yes", both about the
product being *available* there, not about what a regional outage costs. On stickiness, the
self-halt sentence appears three times across [03](03-lld.md) and
[ARCHITECTURE.md](ARCHITECTURE.md) with no clearing condition and no persistence anywhere,
and denial test 38 tests that the self-halt fires, not that it clears correctly. The refuter
found the challenge **understating its own case**: because the halt is described as
in-*process*, a Cloud Run instance recycled during or after the outage starts clean, so the
halt does not even survive to the recovery moment. It confirmed the product figures —
regional Firestore at 99.99 % across at least three zones against 99.999 % multi-region, and
Pub/Sub's seven-day message retention matching the residency table — and noted that "no
documented cross-region failover for Agent Runtime" is correctly carried as an `Assumption:`
rather than asserted. It also endorsed the challenge's recommendation to keep the single
region.

**Narrowed to**, by the refuter. The consequence of a non-sticky halt is smaller than stated
for a long outage, because approval TTLs expire (four business hours), step 8 gates machine
principals on business hours, and A14 refuses plans that cannot complete inside today's
window. The real exposure is an outage longer than 30 seconds and shorter than the approval
TTL, inside business hours. Still worth the flag — and the design's own drill checklist makes
the opposite point in the other direction: "a drill that leaves writes halted is a drill that
becomes an outage on Monday", so the clearing condition has to be specified alongside the
stickiness.

**Decision: accept the single region with a stated reason; change the halt.** New decision
41 records single-region acceptance with RTO equal to Google's regional recovery. Edit
[03-lld.md](03-lld.md): a self-halt caused by a control-plane outage persists as `no_writes`
until an operator clears it, and on clearing, any plan whose hold window passed during the
outage is expired rather than resumed.

---

### C10 — Eve's streamQuery channel can assert any operator's identity (stands)

**Claim.** `eve-controller@` is one of three principals holding
`aiplatform.reasoningEngines.query` on Wall-E's engine "so it can run its own read-only
verification playbooks through the agent". Two defects. Those playbooks run through
`walle-actions` on Wall-E's robot token, which is exactly "Eve verifies through the thing it
is verifying" — the thing [decision 10](09-open-decisions.md) exists to prevent. And a query
principal sets `user_id`, which the design trusts only because the callers are trusted.

**Why the refuters could not dismiss it.** Unanimous at **high** confidence, all three
finding it addressed nowhere as an identity-assertion problem.
[12-agent-identity.md](12-agent-identity.md) section 7 makes exactly this argument for the
agent's own principal and never extends it to `eve-controller@`.
[13](13-agent-interconnection.md) section 4.4 already concedes the channel is "never for any
evidence", so no verification purpose remains.

**Narrowed to.** Impact is bounded by the stage plan: chat writes sit at L3 from S1 through
S5 and A1 stops the agent releasing an approval. A compromised or buggy `eve-controller@`
can read the tenant through the agent in a real operator's name, create L3 approval requests
and audit rows falsely naming that operator, and get `WRITE_LOW` reversible operations
executed up to their T0 ceiling. That still breaks
[08](08-team-eve-mo.md) rule 1 ("Eve never acts on Workspace").

**Decision: change now.** Edit [13-agent-interconnection.md](13-agent-interconnection.md)
section 4.4, [12-agent-identity.md](12-agent-identity.md) and
[ARCHITECTURE.md](ARCHITECTURE.md): remove `reasoningEngines.query` from `eve-controller@`.
Two query principals remain — the Discovery Engine service agent and `walle-dispatcher@`.
Eve's inputs are `GET /v1/plans`, `GET /v1/runs`, BigQuery, Pub/Sub, its own Workspace reads
and Google's audit log. A future consumer needing narration gets its own principal on a
separate A2A service where the principal type `agent` is established rather than asserted —
which is also the open question C40's refuter deferred, and it is settled here rather than
left hanging.

---

### C12 — Eve is drawn as an LLM controller and everything it must do is deterministic (partially stands)

**Claim.** 01 draws "Eve — controller / approves · verifies · halts";
[08](08-team-eve-mo.md) lists "halting, on its own judgement"; the
[05](05-autonomy-ladder.md) acceptance test reads like a test for an LLM judge. Yet every
item in 08's "what Eve must do" is mechanical: compare pre-state, check `expects`, recompute
a hash, reconcile audit rows, detect drift, apply thresholds, bundle evidence.

**Why it only partly stands.** The factual lens refuted the framing: "no LLM approves" is
**already decided** in [12-agent-identity.md](12-agent-identity.md) section 1.8 — a
deterministic controller signs, and no LLM loop may produce an Eve signature. So this is a
consistency defect, not a missing design decision. What survives is that the pages handed to
Eve's designer (01, 05, 06, 08) never say it, and
[13](13-agent-interconnection.md) section 4.3 leaves an LLM hop upstream of the approve call
to "Eve's design", which contradicts 12 section 1.8.

**Decision: change now.** Edits:
- [01-hld.md](01-hld.md) component map and layer table, and
  [08-team-eve-mo.md](08-team-eve-mo.md): state that Eve's approve/refuse decision and the
  signature over it are deterministic code, with at most an advisory model beside them.
- [08-team-eve-mo.md](08-team-eve-mo.md) item 5: halting on **declared thresholds with a
  reason code**, not "its own judgement".
- [05-autonomy-ladder.md](05-autonomy-ladder.md) S3 exit: seeded invariant-class faults must
  be caught at **100 %**; agreement with human verdicts is reported for information only. A
  95 % catch rate on invariants is not an acceptable gate for a deterministic checker.
- [13-agent-interconnection.md](13-agent-interconnection.md) section 4.3: remove the
  sentence leaving an LLM hop before approve to Eve's design.
New decision 34 records the constraint so Eve's designer inherits it.

---

### C13 — Eve's "read-only" credential is either blind to licences or can write them (stands)

**Claim.** The Eve role in [SETUP.md](SETUP.md) Phase 15 lists no License Management
privilege, yet the grant carries `apps.licensing`, justified as "Eve needs to read
assignments". License Management is indivisible with no read-only half, as the design itself
documents. Either Eve's role lacks it and every licence read 403s, or someone grants it and
the controller that "never acts on Workspace" can assign and revoke licences.

**Why the refuters could not dismiss it.** Unanimous at high confidence.

**Narrowed to.** Only the "can read" half. The "or it can write" half is not the design as
written: Eve's role carries no License Management privilege, a consented scope grants nothing
without the privilege, and `walle verify` fails the build if Eve's role holds any privilege
outside the read allowlist. So the defect is a contradiction plus a silent gap in
independence, not a latent write path.

**Decision: change now.** Edits: remove "Eve needs to read assignments" from
[SETUP.md](SETUP.md) Phase 15 and drop `apps.licensing` from Eve's grant; record in
[08-team-eve-mo.md](08-team-eve-mo.md) that Eve verifies licence changes from **licence
events in the admin audit log** written by Google, and that licence verification is
therefore partial — a named limit on independence for F7 at L4.

---

### C14 — Stage 0 provisions Stage 2–5 machinery, including a dormant Eve credential (stands)

**Claim.** [08](08-team-eve-mo.md) wants seams from the first commit;
[SETUP.md](SETUP.md) turns that into live infrastructure for features months away. Phase 15
creates Eve's robot user, customer-scoped read role, hardware key, login rule, licence,
Trusted OAuth client, consented refresh token and regional secret, and the setup code adds
`SA_EVE` to the control-endpoint allowlist, the KMS signer and the engine query grant: a
standing tenant-wide admin read credential and an allowlisted principal with no consumer.
Google expires a refresh token unused for six months.

**Why the refuters could not dismiss it.** Unanimous. The six-month rule is confirmed —
Google lists "the refresh token has not been used for six months" among the reasons a token
stops working, and a successful token exchange, not an API call, resets the clock.

**Narrowed to.** "Will likely expire" is an inference. The S0–S2 floors total 13–18 weeks,
under six months, so the token dies only if stages overrun or Eve's design and build lag S3
entry. Both are plausible, since Eve has no design and no date. A monthly refresh by
`walle status` would defeat the expiry — at the cost of keeping a tenant-wide admin read
credential warm for a consumer that does not exist.

**Decision: open a decision.** New decision 36: what Stage 0 provisions. The
recommendation is that Stage 0 provisions only what Stage 0 uses, and that Phase 15, the KMS
key, the `eve-controller@` allowlisting and `walle-events` move to an "Eve onboarding" step
opened by the S3 entry decision record. Seams stay in **code** — the
[08](08-team-eve-mo.md) endpoint contracts, the audit columns, and a CI-only stub caller
identity for negative tests — which is what "the right seams from the first commit" actually
requires. Either way, replace Phase 15's "Why now" (cost of repeating consent) with the
six-month expiry and scope-freeze reasons, which are the real ones.

*Note of 2026-09-13.* Phase 15, the KMS key `eve-approval` and Eve's two secrets are now
provisioned in `EVE_PROJECT` by Eve's own setup ([../eve/07-build-runbook.md](../eve/07-build-runbook.md)),
not by Wall-E's Stage 0 at all. What remains for decision 36 inside `WALLE_PROJECT` is the
`eve-controller@EVE_PROJECT` allowlist entry and the cross-project bindings on Wall-E's
resources — `run.invoker` on `walle-actions`, dataset-level `dataViewer` on `walle_audit` —
plus `walle-events` ([../project-topology.md](../project-topology.md) §7.1).

---

### C39 — The contract fixed for later teams is not precise enough to build against (stands)

**Claim.** Pub/Sub events, BigQuery evidence and REST interlocks are the right shapes, and
REST rather than A2A for halt and approve should be kept. But [08](08-team-eve-mo.md),
written "to be handed to whoever designs them", is not buildable. It contradicts itself on
Mo: the identities table and item 6 say Mo cannot call the action service, while the
interface table, [ARCHITECTURE.md](ARCHITECTURE.md) section 7.5,
[12](12-agent-identity.md) section 1.8 and [13](13-agent-interconnection.md) section 4.4
grant Mo `GET /v1/plans` and `GET /v1/runs`. And no canonical plan serialisation, hash
algorithm or signed envelope is defined, although Eve "signs a hash it computed itself".

**Why the single refuter could not dismiss it.** One refuter ran, the already-addressed lens,
at high confidence; addressed nowhere for the canonical plan form or the event schema.

**Decision: change now for the contradiction, define before the endpoint is built.** Edits:
- [08-team-eve-mo.md](08-team-eve-mo.md): correct the Mo identities row and item 6 to "the
  two read endpoints only", matching 08's own interfaces table.
- [03-lld.md](03-lld.md) and [08-team-eve-mo.md](08-team-eve-mo.md): define, before the
  approve endpoint and its stub caller are built, the canonical serialisation of the frozen
  plan body (RFC 8785 canonical JSON, SHA-256), the exact signed field list (`plan_id`,
  `plan_hash`, `config_version`, expiry, nonce, KMS key version), and a Pub/Sub schema for
  `walle-events` with a `contract_version` attribute and at-least-once semantics keyed on
  `event_id`. Put them under the same required reviewers as `ladder.yaml`.

---

### C16 — Evidence for replacing the human is inflated at L3 and missing at L4 (stands)

**Claim.** Trust boundary 5 promises execution "at this level of proven reliability". Three
gaps. S3 batch approval is one action for the whole batch bound to the plan hash, so an
operator cannot reject one item without rejecting the plan — a 14-item plan with one doubtful
item records 14 accepts. At L4 and L5, precision has no input except vetoes and "a sampled
human review" whose rate, owner and storage are defined nowhere. And Eve's acceptance test
can be passed by an Eve that always approves.

**Why the refuters could not dismiss it.** Unanimous, one at high confidence. Partial
credit: the S3 seeded-fault exercise does defeat an always-yes Eve *at S3*, and A10's
per-item re-run of the policy chain checks policy — not the operator's judgement.

**Decision: change now.** Edits:
- [03-lld.md](03-lld.md), [04-flows.md](04-flows.md) and
  [05-autonomy-ladder.md](05-autonomy-ladder.md): batch approval records a per-item
  accept/reject **vector** bound to `plan_hash`; rejected items become
  `skipped_by_operator`.
- [05-autonomy-ladder.md](05-autonomy-ladder.md) section 8: define the sampled human review
  — a minimum rate of `max(10 %, 5 items/week)` of executing items, graded **without seeing
  Eve's verdict**, stored in `grades/`, and the only input to precision at L4 and L5. This is
  what bounds the "compromised Eve" accepted risk, which currently rests on a measurement
  that does not exist.
- [05-autonomy-ladder.md](05-autonomy-ladder.md) S4 exit: "human vetoes ≤ 1 %" measures
  whether humans intervened, not whether the action was right; pair it with the blind-sample
  precision.

---

### C18 — Promotion and demotion use point thresholds on small samples (stands)

**Claim.** [05](05-autonomy-ladder.md) section 8 applies 95 % to both tests. Promotion needs
≥ 30 graded items, so at most 1 wrong; demotion triggers at "< 95 % over 20 graded", so 2
wrong in 20. By exact binomial, a true-90 % playbook passes the 30-item gate about 18 % of
the time, and a true-95 % playbook trips the 20-item demotion about 26 % of windows, 12 % at
97 %. [04](04-flows.md) Flow B counts "unsure" as wrong. With the ratchet and "two demotions
of the same family in 90 days force a redesign", noise alone forces good playbooks into
redesign.

**Why the refuters could not dismiss it.** Unanimous at high confidence, the factual lens
calling the whole claim sound. Nothing anywhere addresses the statistics;
[05](05-autonomy-ladder.md) section 6 acknowledges false positives only to say they get no
exception.

**Decision: change now, before the first item is graded.** Edit
[05-autonomy-ladder.md](05-autonomy-ladder.md) section 8: replace point estimates with
interval gates and hysteresis. Promote when the Wilson 95 % lower bound ≥ 0.90; demote one
level when the Wilson 95 % upper bound < 0.95 (3 or more wrong in the last 20), and drop to
L1 when the upper bound < 0.90. Take `unsure` out of the precision ratio and report it
separately, capped.

The interval gate forces the sample floor up, and the two must be decided together.
[05](05-autonomy-ladder.md) section 7 requires "≥ 30 proposals graded per family to be
promoted". At n = 30 even a flawless record gives a Wilson 95 % lower bound of 0.886, below
0.90 — so adopting the interval gate without touching the floor makes **no cell promotable at
all**, and the ratchet plus "two demotions in 90 days force a redesign" would still fire. The
smallest perfect sample that clears 0.90 is **35**, and a sample that admits even one wrong
item does not clear it until **53** (52/53 → 0.901; 39/40 gives only 0.871). Raise the
section 7 minimum to ≥ 35 as the floor, and say in section 8 that the minimum sample and the
interval gate are one decision, not two — whoever sets the gate at 0.90 is also choosing how
long a family must run before it can ever be promoted.

New decision 33 records the numbers, since they interact with
[decision 16](09-open-decisions.md).

---

### C17 — The evidence is graded by the playbook's author, and the two-person rule is a name in a file (stands)

**Claim.** [08](08-team-eve-mo.md) rule 2, "no agent grades its own work", is applied only to
agents. At S0 the ladder owner alone writes the playbooks, grades every shadow item, writes
the decision record and merges the pull request; at T0 on L3 the requester is also the
approver; Mo's readiness scorecard is computed from those same grades. The "second named
human" is enforced only as a line in the decision file, tied to no authenticated identity,
and the two-human threshold is worded three different ways.

**Why the refuters could not dismiss it.** Unanimous, one at high confidence. Existing
mitigations bound it without closing it: the S3 Eve acceptance test and the S4 sampled
review both come later than the grades that gate them.

**Decision: change now.** Edits:
- [05-autonomy-ladder.md](05-autonomy-ladder.md) section 10: the external validator matches
  the `Approvers:` line against **two distinct authenticated approving reviewers** on the
  pull request, neither of whom authored it. Record the git host and its admin-bypass
  setting as `tbd`.
- [05-autonomy-ladder.md](05-autonomy-ladder.md) and [08-team-eve-mo.md](08-team-eve-mo.md):
  make the two-human predicate **one** rule, level-based — L4 and L5.
- [05-autonomy-ladder.md](05-autonomy-ladder.md) section 8: for a `WRITE_HIGH` cell, grades
  count towards promotion only if at least 20 % of items are blind double-graded by someone
  other than the playbook owner, with agreement reported. Until a second grader exists,
  `WRITE_HIGH` cells cannot pass L2. This is the human counterpart of rule 2 and the design
  currently exempts humans from it.

---

### C20 — A second human is needed during the build, not "before Stage 1" (partially stands)

**Claim.** [Decision 11](09-open-decisions.md) puts the second operator in "needed before
Stage 1" and S0 says "the ladder owner alone". The design's own controls need other people
earlier: a CI deploy identity no operator holds, a second reviewer on the ceiling module, and
a validator owned outside the repository — all from the first deploy in Phase 10, before S0.
Recovery after K4, K5 or any `invalid_grant` needs the vault password, a hardware key from
the safe and a clean profile, and no pager, rota or second trained person exists.

**Why it only partly stands.** The engineering lens refuted the framing that this blocks the
build: [SETUP.md](SETUP.md) D5 already says the second person "should be named now", before
Phase 1, and [ARCHITECTURE.md](ARCHITECTURE.md) weakness 10 names the one-person rota. The
separation-of-duties half survives intact: Phase 10 deploys the credential holder by hand
*after* Phase 9 has made the credential live, and nothing says when "steady state" starts.

**Decision: change now — split decision 11.** New decision 37 (11a): before Phase 10, name a
security reviewer holding code ownership on the ceiling module, policy chain, catalogue and
validator; a custodian of the external validator; and a second person **trained and witnessed
on the Phase 9 re-bootstrap**, with the location of vault and hardware-key access recorded
and no values. [Decision 11](09-open-decisions.md) keeps its current content as 11b, before
S1. Add to [ARCHITECTURE.md](ARCHITECTURE.md) section 4.2 the rule that when neither the
deployer nor the operator role can be separated, the exception is recorded per deploy rather
than assumed.

---

### C15 — A level's evidence is not bound to the behaviour and platform that produced it (stands)

**Claim.** A level attaches to (family, trigger), but the evidence behind it comes from one
playbook version, selection query, prompt, pinned model, ADK version, Model Armor filter
version and engine resource. Nothing re-qualifies a cell when any of those change, and
[05](05-autonomy-ladder.md) restarts dwell only after a demotion. Gaming path: prove 95 % on
a narrow selection, then merge a Mo pull request widening it, and the cell keeps its level on
evidence earned by a different selector.

**Why the refuters could not dismiss it.** Unanimous. Existing mitigations are close but do
not connect: the injection regression suite reruns on model, ADK or playbook change, and
`model_id` is recorded for attribution — but nothing ties any of those changes to the
**level**. The ADK pin is inconsistent across [03](03-lld.md), [SETUP.md](SETUP.md),
[11](11-prompt-security.md) and [13](13-agent-interconnection.md), and no page states a model
retirement procedure. What is overstated: that Google retires pinned models on a cycle
shorter than the ladder floors — that is not established.

**Decision: change now.** Edits:
- [05-autonomy-ladder.md](05-autonomy-ladder.md) section 10: CI refuses a change to a
  playbook's pinned selection query, its `uses` list or its scope when that playbook serves a
  cell above L2 unless the change links a decision record; the changed playbook then reruns
  the canary at its current level or lower.
- [03-lld.md](03-lld.md): stamp the full fingerprint on every audit row — playbook version
  with selection hash, `prompt_hash`, `model_id`, catalogue version, ADK version, Model Armor
  filter version, engine resource. Most are already there; the rule that any change is
  material is not.
- Pin the ADK **exactly**, in one place, and make the six pages that currently restate a
  version — [01](01-hld.md) ("ADK 2.8" on the agent node), [03](03-lld.md),
  [SETUP.md](SETUP.md), [11](11-prompt-security.md), [12](12-agent-identity.md) ("ADK
  2.8.0") and [13](13-agent-interconnection.md) — reference that pin rather than restate it.
- Add a model-retirement and engine-recreation procedure to [SETUP.md](SETUP.md), noting
  that recreating the engine is an identity change (see C53).

---

### C19 — Programme-wide stages with conjunctive exits let the lowest-volume family set the pace (partially stands)

**Claim.** The ladder already gates each cell with dwell and ceilings, and R8 says "evidence,
not calendar". Stages add programme-wide floors with conjunctive exits: S0 needs shadow runs
"covering every write family"; S1 needs "≥ 50 executions across ≥ 3 families by ≥ 2
operators". A low-volume family in a small pilot OU holds back families with plenty, and S3
needs ≥ 50 approved `WRITE_HIGH` items in an OU [decision 5](09-open-decisions.md) calls
"small".

**Why it only partly stands.** The engineering lens refuted the structural remedy —
demoting stages to milestones — because S2 and S4 exits are already per family and the stage
table is already "a canary rollout". What survives: the S0 exit "covering every write family"
is a genuine conjunctive gate, nothing says whether sandbox synthetic items count towards it,
S1's "≥ 2 operators" ties an exit to headcount, and nobody has sized the pilot OU against any
of the counts.

**Decision: change now, and it depends on decision 5.** Edits:
- [05-autonomy-ladder.md](05-autonomy-ladder.md) S0: say explicitly whether sandbox synthetic
  items count towards "covering every write family".
- [09-open-decisions.md](09-open-decisions.md) [decision 5](09-open-decisions.md): record the
  pilot OU's **absolute account count** and the expected `WRITE_HIGH` items per month per
  family, as an `Assumption:` to be checked against the S0 coverage, the S2 and S3 counts and
  the 20 % canary. If it falls short, widen the OU or accept a longer stage explicitly.
- Automatic demotions later judged false should be routed to a named review rather than
  simply absorbed by the ratchet.
This challenge and C27 cannot be closed at all until that count exists.

---

### C34 — Nothing requires the higher levels to be worth their cost (stands)

**Claim.** Against alternatives the ladder holds. What is missing is a benefit test. Every
exit criterion is a safety criterion, so S4 — Eve as approver, the KMS key, decision 18's
split, a Chat app, 99 % Eve availability, the accepted "compromised Eve" risk — is entered on
safety evidence alone. For one admin approving a daily batch card, the minutes saved may not
justify any of it.

**Why the single refuter could not dismiss it.** One refuter ran, the already-addressed lens,
at medium confidence. [Decision 13](09-open-decisions.md)
already accepts a permanent L3 for F5, which is the same reasoning applied to one family; the
general rule is not written.

**Decision: change now.** Edits: add a required **"Why worth it"** line to the promotion
decision template in [05-autonomy-ladder.md](05-autonomy-ladder.md) section 10 for any
L3→L4 `WRITE_HIGH` promotion, quantifying the approval burden avoided from the approvals
table and `approval_latency_ms`. State in [05](05-autonomy-ladder.md) section 7 or the
[01](01-hld.md) non-goals that **L3 batch is an acceptable permanent steady state** for a
`WRITE_HIGH` family. Drop "SLA missed" as an entry trigger: an operator too slow to approve
is not evidence that the machine should decide.

---

### C52 — No recorded or fake Workspace harness (stands)

**Claim.** The promise that Wall-E undoes what it does, and that verify-by-re-reading catches
bad writes, depends on three pieces of code per catalogue entry: the inverse, the pre-state
reader and the post-state predicate. The design gives them production metrics and a monthly
rollback drill. It gives them no test that runs before a deploy. The defects the design
itself records were response-shape bugs — pagination at 200, empty admin enumeration under an
OU-scoped role, no-op versus failure — visible only against specific API responses.

**Why the refuters could not dismiss it.** Four verdicts — the factual lens twice, the
already-addressed lens and the engineering lens — all at high confidence, and none refuted
it. Every CI gate in the set is a static or configuration assertion; none exercises a
catalogue entry's behaviour against an API response. The only existing backstops — the floor
assertion, the closed error enum, no-op classification — are runtime, in production, which is
the gap. The already-addressed lens found the defect class corroborated by the design's own
history: the pagination-at-200 truncation, A7's empty admin enumeration under an OU-scoped
role reading as success, and A13's no-op-versus-failure are three response-shape bugs, all of
which a recorded-response fixture would catch with no credential and no tenant. Both factual
passes confirmed the proposed tooling exists in the stack the design already installs —
`HttpMock` and `HttpMockSequence` in `google-api-python-client`, which the documentation
itself recommends using with saved API responses. The engineering lens was the strongest of
the four and said it could not construct a case against the alternative. Its sharpest point
is one the challenge does not make: the promotion machinery is self-graded without this
test, because [05-autonomy-ladder.md](05-autonomy-ladder.md) section 8 gates every promotion
on verification success at or above 99.5 % while the verifier *is* the post-state predicate
under test — a wrong predicate reports "verified" and the metric that unlocks L4 and L5 is
measuring itself. Offline fixtures are the only place that circularity is broken before a
write happens. It added that `F10 run.rollback` is itself code with an inverse that has never
been executed, and that nothing is built yet, so this is the cheapest moment the test will
ever have.

**Narrowed to.** Three narrowings, none defeating. From the factual lens: recorded responses
catch response-shape and error-mapping regressions, but cannot catch defects that depend on
which role the robot runs under — the OU-scoped empty enumeration is a *privilege* behaviour,
so fixtures have to be recorded per role assignment and do not replace the in-tenant rollback
drill. Also from the factual lens: `HttpMockSequence` supplies the response and asserts
nothing about the outgoing request, so a fixture test proves response handling, inverse logic
and error-class mapping, not that the correct request URI, page token or body was issued —
request-level assertions are a separate check on top. And because the 2.x client builds from
the discovery document bundled in the library by default, fixtures are pinned to a
version-pinned client shape, which makes a library upgrade as much a re-recording trigger as
a Google-side change (C54). From the already-addressed and factual lenses jointly, the claim
"no test before deploy" is too broad: [SETUP.md](SETUP.md) section 4 *is* a CI-required
pre-promotion suite and it does exercise the error-class enum and some policy-chain
behaviour — but it runs against a deployed service, needs the production credential, and
contains no per-entry apply/verify/inverse/restore property test. The engineering lens took
the opposite view on the same sentence, and the disagreement is recorded rather than
averaged: it held the challenge "exactly right as written", because the denial suite in
[07](07-build-runbook.md) Phase 4 / [SETUP.md](SETUP.md) Phase 17 runs against an already
deployed `walle-actions` and is therefore a post-deploy check, not a pre-deploy gate. Both
readings converge on the same residual — no pre-deploy test exercises handler, inverse or
verifier behaviour.

**Decision: change now.** Edit [03-lld.md](03-lld.md) and
[05-autonomy-ladder.md](05-autonomy-ladder.md): every catalogue entry carries a required
property test — pre-state read, apply, post-state predicate true, inverse, pre-state hash
restored — plus error-class-to-closed-enum mapping and the no-op path, run in CI with no
credential. Start with recorded fixtures scrubbed from the sandbox OU by the sandbox
administrator; an in-memory fake directory ages better across the re-recordings C54 will
force. Make it a required status owned by the same code owners as the ceiling module — but
that part is ordinary CI hygiene, already implied by [ARCHITECTURE.md](ARCHITECTURE.md)
section 4.2's second-reviewer rule, and the engineering lens was explicit that the change
should not be argued on it. The non-negotiable part is the per-entry property test itself,
which turns "verify by re-reading" and "Wall-E undoes what it does" from assertions into
checked properties.

---

### C51 — The denial suite can only run in production by breaking production (stands)

**Claim.** [SETUP.md](SETUP.md) section 4 makes the 52-test suite the gate "before every
future promotion, at every stage, forever", running against the deployed production service.
Several tests can only pass by inducing failure in the live control plane: Firestore
unreachable for more than 30 seconds self-halts writes; test 52 sets a real halt; test 18
needs a truncated protected-principal computation; test 27 changes production
min-instances. At S3 to S5 that either interrupts live autonomy or requires a test-mode
switch compiled into `walle-actions`.

**Why the refuters could not dismiss it.** Three lenses ran — already-addressed, factual and
engineering — all at **medium** confidence, and none refuted it, but all three struck out the
challenge's central dichotomy. The production-only framing is textually correct and all
three confirmed it: section 4 makes the suite the gate "before every future promotion, at
every stage, forever", `cmd_denials` resolves the target as the production
`walle-actions` URL, the run flips that live service's `--min-instances`, and the only word
anywhere on fixtures is "the suite must construct its own fixtures". What does **not** stand
is "can only ... by breaking production or by shipping fault hooks into the credential
holder". The already-addressed lens found a data- or platform-level induction path for every
named test: test 18 fires by adding one bogus entry to the committed protected-floor file,
since the floor assertion trips whenever the computed set is not a superset of that file; the
BigQuery and Firestore tests fire by temporarily removing an IAM grant, which is an act the
suite already contemplates re-running around; test 39 fires with a bogus group key; and test
52's halt is already a deliberate recurring production act, drilled every 30 days as K0, with
promotion gated on drill freshness anyway. The factual lens added a third path neither the
challenge nor the other lenses had: a Cloud Run **tagged zero-traffic revision** of the same
image, which gets its own URL, its own service identity, its own environment variables and
its own minimum instances — so the dependency tests come from denying *that* revision's
service account, test 18 from running it under the OU-scoped read rather than the
customer-scoped one, which genuinely truncates the computed set instead of faking it, and
test 27 from setting min-instances on the tagged revision while the serving revision stays
at zero.

**The lenses disagreed on one test, and the disagreement is recorded rather than averaged.**
The already-addressed lens holds that test 18 needs no seam because the protected-floor file
is a committed fixture. The engineering lens holds that test 18's *truncated* computation,
and any malformed or partial API response, genuinely cannot be induced from outside — and
that a seam inside the admitted image is exactly what must not exist, since one revision of
that process defeats every other control. Both conclusions point the same way: decide the
injected Firestore, BigQuery and Directory clients now, while nothing is built, and run the
seam-needing tests in the offline harness (C52) rather than in the deployed image.

**Narrowed to**, by all three lenses. The suite is production-disruptive and its induction
procedure is unwritten. That is the residual, and it is real: a builder reaching the
fail-closed tests at S3–S5 has no sanctioned procedure. The engineering lens added that for
an admin automation whose safe state is "stopped", a scheduled few-minute write halt during a
promotion window is not a production incident — [05](05-autonomy-ladder.md) section 9 does not
classify a deliberate halt as a severity at all. And routing the suite to a staging project
does not stand: it inherits C50's cost, and test 52 *is* the kill-switch drill and must stay
in production.

**Decision: change now.** Edits:
- [SETUP.md](SETUP.md) section 4: tag each test **platform** or **application**. Platform
  tests re-run in production after every IAM change, as test 7 already demands. For every
  fail-closed test, write the induction procedure — including the Cloud Run tagged
  zero-traffic revision path, which gives per-revision service identity, environment
  variables and min-instances and needs neither a staging project nor a fault hook.
- [06-security-guardrails.md](06-security-guardrails.md) forbidden configurations: add a row
  banning **any fault-injection or test-mode path reachable in the admitted `walle-actions`
  image**, checked by a CI import test. Weakness 12 makes such a switch a bypass in the one
  process that must be trusted.
- [05-autonomy-ladder.md](05-autonomy-ladder.md) section 10: keep a production-side gate —
  the platform subset green in production, with the running digest and `ceilings_sha`
  matching — or the gate stops proving the production wiring is correct.

---

### C53 — Neither deployable has a rollback plan (stands)

**Claim.** [Decision 21](09-open-decisions.md) fixes a gateway on the engine, which removes
Agent Runtime revisions and traffic split; Google's remaining answer is an in-place update
whose behaviour is undocumented. Re-creating the engine is an identity change. For
`walle-actions`, Cloud Run does support tagged no-traffic revisions and instant traffic
rollback, but [SETUP.md](SETUP.md)'s only Phase 10 rollback is `gcloud run services delete`,
and the dispatcher is deployed from a mutable `:latest` tag.

**Why the refuters could not dismiss it.** Five verdicts — the factual lens twice, the
already-addressed lens twice and the engineering lens — all at high confidence, and none
refuted it. The "Rollback" headings in Phases 10, 11 and 12 are teardown of a failed build
step, not reversal of a bad release. Both factual passes re-fetched the Google pages on
2026-09-11 and found the restriction the challenge turns on still in force, verbatim: "Agent
Gateway isn't supported for Agent Runtime agents that are using revisions", with in-place
update as the page's only remedy; revisions are still Preview and that page does not present
them as a rollback mechanism; and the SDK page gives `agent_engines.update` syntax and says
nothing about downtime, atomicity, in-flight requests or package retention — so "whose
behaviour is undocumented" is verified rather than asserted. The engineering lens supplied
the two arguments the challenge does not make. First, deleting `walle-actions` is materially
worse than rolling traffic back *in this design specifically*: Phase 10 binds `run.invoker`
to five service accounts plus the operator group in a loop, and `AUDIENCE` is set in a second
pass because the service URL does not exist until the service does — so a delete-and-recreate
under incident pressure, by the one person who holds the runbook, has to rebuild all of that
correctly or the andon cord loses its handle, since a `CONTROL_CALLER_ALLOWLIST` missing
`OPERATORS` means no human can halt. `update-traffic --to-revisions PREV=100` touches none
of it and is instant. Second, the no-split rule is not generic advice but a deduction from
the design's own machinery: the running service publishes `ceilings_sha` and stamps it on
every audit row, and a percentage split would let one frozen plan's item callbacks and its
approval land on revisions with different `ceilings_sha`, breaking the
one-config-version-per-run property the audit schema and every promotion argument rest on.

**One corrected fact that changes the procedure.** A Cloud Run revision keeps its environment
variables, `REFRESH_TOKEN_VERSION` among them. After any Phase 9 re-run or K4/K5 drill the
previous revision is pinned to a secret version that no longer exists, so
`update-traffic --to-revisions PREV=100` would bring back an `invalid_grant` outage. The
rollback procedure must first check the target revision's environment, or redeploy the
previous image digest with the current environment. A second correction bounds the no-split
rule: the design never traffic-splits today — `gcloud run deploy` sends 100 % to the new
revision, and the "canary" in [05](05-autonomy-ladder.md) S3 samples *targets*, not traffic —
so the mixed-`ceilings_sha` hazard is one to write down before anyone reaches for a split,
not a defect in the design as written.

**Narrowed to**, by both factual passes and both already-addressed passes. The mutable-tag
defect is the **dispatcher's alone** — `walle-actions` is already built and deployed by
git-sha tag, and the challenge's own evidence line says so, so it should not be read more
broadly. It survives in weaker form: a short-sha tag is still overwritable unless the
repository carries `--immutable-tags` or the deploy uses a digest. And the engine's forward
path is documented: [SETUP.md](SETUP.md) Phase 12 already says "redeploying is update, never
create", and Phase 12b already carries the rule that a recreate is an identity change — so
the change to make is *promoting an existing rule*, not recording a new finding. But Phase
12's own Rollback still says `reasoning-engines delete`, so the set contradicts itself on
exactly this point. Two cautions the refuters attached. The `~=2.8` pin fixes the 2.x series
from 2.8 upwards, not an exact patch, so the previous agent build is genuinely not
reproducible and the challenge's point holds. And because Google documents
`agent_engines.update` only as syntax, "roll back by updating with the previous package" is
an untested plan until K6 rehearses it — which is the whole of the available answer while a
bound gateway removes revisions.

**Decision: change now.** Edits:
- [SETUP.md](SETUP.md) Phase 12 Rollback: delete the `reasoning-engines delete` instruction
  and promote the Phase 12b rule — never recreate the engine to roll back, it changes
  identity — into [01-hld.md](01-hld.md) or
  [ARCHITECTURE.md](ARCHITECTURE.md).
- Every agent release is a locked, hashed package (wheel plus fully pinned requirements) kept
  in Artifact Registry, so `agent_engines.update` with the previous package is a real
  rollback rather than a plan. During any engine update the dispatcher holds `no_autonomous`.
- [SETUP.md](SETUP.md): deploy both Cloud Run services by **digest**; the dispatcher's
  `:latest` tag goes. Add the Cloud Run traffic-rollback procedure and a no-split rule. The
  procedure must check the target revision's environment first — a revision keeps the
  `REFRESH_TOKEN_VERSION` it was deployed with, so rolling traffic back to a revision that
  predates a Phase 9 re-run or a K4/K5 drill restores an `invalid_grant` outage. Where the
  environment has moved, redeploy the previous image digest with the current environment
  instead of shifting traffic.
- [06-security-guardrails.md](06-security-guardrails.md) forbidden configurations: a mutable
  tag in any deploy. (The version-range half of this rule belongs to C15's ADK pin.)
- Add K6 to the drills: a rehearsed, timed rollback of each deployable, recorded in
  `drills/{date}` — run wherever decision 29 lands the pre-production environment.

---

### C54 — Google-side contract drift is watched for Model Armor but not for the Workspace APIs (stands)

**Claim.** The design accepts that Google changes behaviour with no config change, and for
the Model Armor filter version it has an alert and a mandatory regression re-run. The APIs
the gate actually writes through get nothing. A renamed privilege, a renamed SKU, an admin
audit event name a playbook `trigger` keys on, or a changed field default would first show
up in a scheduled production run — and at L4 a human only vetoes during the hold window
rather than grading the plan.

**Why the refuters could not dismiss it.** Five verdicts — the already-addressed lens twice,
the factual lens twice and the engineering lens — and none refuted it. `dump_privileges` runs
once; the daily drift job covers GCP IAM and engine settings only; the quarterly privilege
review is a hygiene prune, not a change detector. The high-confidence already-addressed pass
put it plainly: the set has a recurring contract detector on the LLM path and on the GCP
path, and none on the Workspace path — the fourteen rows of the daily identity drift job are
every one of them a GCP IAM, engine-config or org-policy check, and [06](06-security-guardrails.md)'s
Monitoring table has no upstream-contract row at all. It is not a knowingly accepted weakness
either: it appears in neither [ARCHITECTURE.md](ARCHITECTURE.md)'s thirteen accepted
weaknesses nor [10](10-adversarial-review.md)'s seventeen attacks. It is simply absent. Both
factual passes verified the external facts, including the one doing the most work: the
December 2025 rename of a licence SKU's display name is real, dated and in the exact API
family F7 writes through; the release-notes feed exists at the URL given; and
`privileges.list` returns the fields a probe would diff, from a GA read method needing no new
privilege. The engineering lens, at medium confidence, made the consistency argument the
sharpest one: the design already accepts "Google changes behaviour under you with no config
change" for Model Armor and answers it with an alert plus a mandatory regression re-run, so
applying the identical rule to the write path is a smaller change than justifying why the
write path deserves less. It also found the dependency unusually fragile by the design's own
admission — [SETUP.md](SETUP.md) Phase 2 concedes that Google publishes no complete privilege
catalogue and that names differ between editions, while two "still to verify" items are open
on privilege names — and judged the "each catalogue entry declares its upstream contract" half
the more durable contribution, cheapest now while the catalogue is still being written.

**Narrowed to**, and two limbs of the challenge struck out. Two dependencies fail
**silently** and are the sharp residual: (a) the admin audit event names that playbook
`trigger` fields and the T2 dispatcher key on — a rename stops an event-driven playbook with
no error, and the "missing two consecutive windows" alert only covers scheduled runs; (b) the
robot's actually-assigned privilege set versus what the catalogue needs, for reads other than
the admin enumeration. Loud breaks (a renamed privilege producing 403s) are already caught by
the closed error enum, verification and the breaker — and the one genuinely silent privilege
variant, a degraded read returning an empty set that reads as success, is exactly the A7
failure the floor assertion already fixes with a daily reconciliation against a committed
file that hard-denies every directory write on divergence. That is the challenge's own
proposed mechanism, already in place for the highest-consequence read. What does not stand:
the **SKU limb**, twice over. Google renames SKU display names while the ids stay stable, and
the Licensing API takes `productId` and `skuId`, not display names — the December 2025 rename
the challenge cites is of that kind. And there is no "F7 table of SKU ids" to diff: a grep
across the whole set returns no SKU id anywhere, and F7's row says the pre-state records the
SKU, so the id comes from live pre-state and a display-name rename cannot touch it. The
challenge also mis-locates the event-name dependency: the T2 log sink filters on
`protoPayload.serviceName="admin.googleapis.com"` plus the robot exclusion, so a renamed
event cannot silently empty the sink — it breaks the playbook trigger match one layer down,
which is where the risk actually lives. The discovery-document revision diff should be
**informational only**: the Python client builds from the bundled static discovery document
by default, so a live revision change does not alter the running client at all, and wiring it
fail-closed would give a one-person rota recurring false halts to clear.

**Decision: change now.** Edits: extend the existing daily drift job
([12-agent-identity.md](12-agent-identity.md) section 10) to diff, against a committed
snapshot taken at build, the `privileges.list` tree, the robot's assigned-role privileges,
and the admin audit event names the playbook `trigger` fields declare. Drop the SKU-id diff:
there is no committed SKU list to diff against, the id comes from live pre-state, and only
display names churn. Have each [03-lld.md](03-lld.md) catalogue entry declare its upstream
contract, so a diff maps to families — that is the part that ages best, and it is what lets
C52's fixtures be re-recorded against a known dependency set rather than by guesswork. A
privilege or event-name diff sets `no_autonomous` for the affected families; a
discovery-revision bump alerts and freezes promotions until fixtures are re-recorded. Add to
[06-security-guardrails.md](06-security-guardrails.md) Monitoring a row
for an **event trigger going quiet**, alongside the existing scheduled-window row. Subscribe
an operator to the Admin SDK release-notes feed. New decision 40.

---

### C2 — Scheduled and event playbooks no longer need a model (stands)

**Claim.** 01 says the agent "runs the named playbook, producing a plan of explicit
targets". After attacks A3 and A11 every choice is pinned: the playbook, the operations, the
hashed selection query, the per-run cap and the projection of attacker-writable fields. What
the model still does is join a pinned read to a pinned write, filter against a prose
`expects` string, and add a line of rationale. A few dozen lines of Python do that
identically every time with no injection surface, and keeping the model there costs the job
envelope, agent job mode, machine-traffic Model Armor and the T1/T2 taint machinery.

**Why the refuters could not dismiss it.** Unanimous. All three found that nothing in the set
ever asks whether the model belongs on T1/T2; A3 and A11 contain it there without justifying
it. The [01](01-hld.md) dispatcher rationale covers halt, `run_id` and ack deadlines, not the
model's presence.

**One refuter argument to discount.** The already-addressed refuter reasoned that the
injection surface on untainted T1/T2 is "close to nil by projection", citing
[11](11-prompt-security.md) section 2's identifier-only T2 envelope. [11-prompt-security.md](11-prompt-security.md)
section 1 lists audit-row parameters — group names, OAuth app names — as hostile channels, so
T2 event playbooks read attacker-set fields **by construction**. The projection argument
holds for T1 selections over pinned fields; it does not hold for T2.

**Decision: open a decision, before S0 shadow evidence.** New decision 32. The recommendation
is deterministic by default: a typed **predicate** replaces the prose `expects`, the pinned
selection stays, and the plan is built by the dispatcher or the action service.
`requires_model` becomes a per-playbook exception that enters at L0, is tainted, and must
state the judgement the model adds. The dispatcher, `run_id`, halt check and ack behaviour
are unaffected — this removes the model from plan construction, not the dispatcher from the
path.

---

### C21 — The flagship journeys cannot be finished by Wall-E (stands)

**Claim.** [04](04-flows.md) Flow A's example is "suspend jdoe, he left today" and S1
promises "leaver and joiner actions from chat". Joiners are impossible: `Users → Create` is
"never". Leavers are only partly covered — suspension, group removal and licence reclaim are
in; sign-out and token revocation are out pending [decision 3](09-open-decisions.md); Drive
and Calendar data transfer is parked in F8 with **no scope in the frozen list**; device wipe
has neither scope nor operation. A human finishes every leaver in the console.

**Why the refuters could not dismiss it.** Unanimous. The sharpest finding: F8 says data
transfer "enters at L0", which contradicts the frozen scope list that has no
`admin.datatransfer` — so adding it later means a re-bootstrap.

**Decision: change now, and it feeds decision 3.** Edits:
- [05-autonomy-ladder.md](05-autonomy-ladder.md) S1 "Value": reword to "leaver actions, plus
  group and licence changes for joiners whose accounts a human or another tool creates;
  account creation is never in scope".
- [09-open-decisions.md](09-open-decisions.md) [decision 3](09-open-decisions.md): add
  `admin.datatransfer` as an explicit question alongside `admin.directory.user.security`,
  naming its cost — the privilege is customer-scoped only and a transfer to the robot is a
  content read path. If it is excluded, say in [05](05-autonomy-ladder.md) F8 that data
  transfer is permanently out, not "later".
- [01-hld.md](01-hld.md) requirement-fit section (C1): show the leaver journey step by step
  with each step marked Wall-E or human, and order it correctly — suspend, sign out,
  transfer, then reclaim the licence.

---

### C22 — The catalogue grows too slowly, and refused requests leave no trace (partially stands)

**Claim.** A human admin's work has a long tail and the only answer to a missing task is a new
catalogue entry: typed parameter model, handler, pre-state reader, post-state predicate,
inverse, attacker-writable field declarations, risk tier under separate security ownership. A
new API needs a new scope, so a re-bootstrap. R3 then starts the operation at L0 on every
trigger including chat, so at least two weeks each at L1 and L2 before a human can approve it
on request. Refused requests leave no record, so Mo has no demand data.

**Why it only partly stands.** The engineering lens refuted the R3 change: L1 and L2 on chat
do add something, and relaxing R3 weakens gate integrity that A17 exists to protect. The
`capability_gap` record survived every lens as a cheap, correct addition.

**Decision: change now for the record; leave R3 alone.** Edit [03-lld.md](03-lld.md): when a
chat request maps to no catalogue operation, write a `capability_gap` audit row carrying a
**closed-enum intent class and nothing else** — no payload, no parameters — through its own
non-executing path, without relaxing `operation_not_allowed`. Mo ranks them. Record in
[05-autonomy-ladder.md](05-autonomy-ladder.md) that a new operation's L0 start on chat is a
deliberate cost, so nobody reads it as an oversight.

---

### C23 — "Other people's Drive is unreachable without DWD" is wrong for shared drives (stands)

**Claim.** [02](02-identity-and-auth.md), [06](06-security-guardrails.md) and
[ARCHITECTURE.md](ARCHITECTURE.md) section 10 exclude the `drive` scope because without
delegation the robot sees only its own Drive. Google documents `useDomainAdminAccess=true` on
`drives` and `permissions`: an admin with the Drive and Docs privilege can list every shared
drive and manage members without belonging to them. Shared-drive hygiene and leaver file
transfer are routine and reachable without DWD.

**Why the refuters could not dismiss it.** Unanimous at high confidence, addressed nowhere,
and not among the claims [10](10-adversarial-review.md) already corrected. The exclusion may
still be right — the same privilege lets the robot add itself to any shared drive and read
content — but the **stated reason is false** and
[decision 3](09-open-decisions.md) rests on it.

**Decision: change now — a documentation and decision-framing correction.** Replace the
premise in [02-identity-and-auth.md](02-identity-and-auth.md) Scopes,
[SETUP.md](SETUP.md) section 1.3 and [ARCHITECTURE.md](ARCHITECTURE.md) section 10 and its
rejected-alternatives table. Split the [06](06-security-guardrails.md) row into *other users'
My Drive* (genuinely unreachable) and *shared drives* (reachable, excluded by choice).
Reword [decision 3](09-open-decisions.md) to the real trade-off. Add a row to
[10-adversarial-review.md](10-adversarial-review.md)'s corrected-claims table. The built scope
set most likely stays unchanged.

---

### C42 — walle-readers@ gives non-admins raw per-person audit data (stands)

**Claim.** [03](03-lld.md) presents the readers group as the safe way to widen reporting
because readers "cannot cause any write". The risk is disclosure, not writes. READ is L5 on
every trigger, the catalogue returns raw `reports.activities.list` rows and per-user
last-login times for the whole tenant, and the model narrates them into the reader's Gemini
Enterprise conversation history — which sits outside `walle_audit` retention and outside the
[decision 25](09-open-decisions.md) content bucket.

**Why the refuters could not dismiss it.** Four verdicts — the already-addressed lens twice,
the factual lens and the engineering lens — all at high confidence, and none refuted it. Both
already-addressed passes found the disclosure question answered nowhere: [03](03-lld.md)
justifies the readers group purely on the write axis ("without being able to cause any
write"), and it gates readers at the *group*, not at the operation, so a reader may call any
READ entry, tenant-wide. The catalogue contains no aggregate operation at all — every F1 entry
is a raw read — so "widen reporting safely" is not buildable as written, and no page anywhere
proposes a minimum cell size, an aggregate-only family, or a rule on who may receive
per-person output. The factual lens verified the comparison the challenge draws: the Reports
privilege is an administrator privilege, and Google states of it that "these actions can't be
limited to specific organizational units", so the console's own answer for Reports is
all-or-nothing at tenant scope — a delegated admin without it sees none of this. It confirmed
the two catalogue rows as raw per-person operations, and confirmed the mismatch as real in
the text: [ARCHITECTURE.md](ARCHITECTURE.md) weakness 11 describes the reads as "aggregated
per organisational unit" while the catalogue that implements them is per-person and
tenant-wide. The engineering lens conceded two of the three threads as documentation and
sequencing defects — the DPIA would be written from a sentence the build does not match,
which is the real harm here, and conversation history is a further copy of employee data
nobody has listed — while rejecting the third: that `walle-readers@` is a live disclosure path
today, and that the F1a/F1b split must be built now. Building aggregate operations with a
suppression threshold is real work for a tenant with one operator and no readers, and the
threshold is an *output* of [decision 8](09-open-decisions.md), which has not happened; the
challenge itself has to mark it an assumption. That inverts the set's own order: ask decision
8 first, then build what the answer requires.

**Narrowed to**, by all four lenses, which converged on the same narrowing. Latent, not live:
readers see nothing until the agent is also shared with them, which is a second deliberate
act the design withholds twice in writing, so "walle-readers@ turns people with no admin role
into readers of raw audit events" is not true of the design as written. The accurate claim is
that **the design commits to widening the audience with no mechanism to make that safe**, and
that
[03](03-lld.md)'s justification is on the wrong axis. Two concrete defects:
[ARCHITECTURE.md](ARCHITECTURE.md) weakness 11 says "aggregated per organisational unit",
which the raw per-person catalogue contradicts, and the data-protection assessment must be
told that; and Gemini Enterprise conversation history is an unlisted copy of employee data
with retention `tbd` — the factual lens could not establish the actual retention period from
Google's documentation, so it must stay `tbd` rather than be asserted. Two further
qualifications from the lenses. "Major" describes the end state, not the design as deployed:
`$READERS` contains only the owner today. And the A2A limb — the `agent` principal inheriting
L5 for READ — has no live consumer, because [decision 23](09-open-decisions.md) opens no A2A
through Stage 2, so it belongs on that decision as a Stage-3 condition rather than here as a
present hole. A lighter alternative to the F1a/F1b split was also recorded: make "readers are
not shared, and the group has no members besides the owner, until the data-protection
assessment has answered who may receive per-person output" a recorded gate, or apply C41's
entitlement check — at the Reports privilege level, since that privilege cannot be OU-scoped —
to readers. The minimum cell size is a data-protection decision, not a design constant.

**Decision: change now, and open a decision.** Edits:
- [ARCHITECTURE.md](ARCHITECTURE.md) weakness 11: correct "aggregated" to per-person, and add
  conversation history as a further copy with retention `tbd`.
- [03-lld.md](03-lld.md) catalogue: mark each READ row that returns per-person personal data,
  so the split is visible without building anything.
- [SETUP.md](SETUP.md) Gemini Enterprise phase: do not share the agent with
  `walle-readers@` until [decision 8](09-open-decisions.md) has an answer for reads.
New decision 35 asks who beyond the owner may receive per-person output, and whether an
aggregate-only family (counts per OU or SKU, with a minimum cell size below which the count
is suppressed) is required before the first reader is onboarded.

---

### C43 — Google's log names the robot, never the human (stands)

**Claim.** Every human-requested write appears in Google's admin audit log with `walle@` as
the actor and the OAuth client in `applicationInfo`; there is no field for the person behind
it. Three accountability processes break: admin-role access reviews list one robot and miss
everyone who effectively holds its role through the two groups; an investigator working from
Google's log or a SIEM sees an automation account; and the design cites Google's log as
independent evidence while the human's name exists only in `walle_audit`, written by the
component weakness 1 says cannot be trusted.

**Why the refuters could not dismiss it.** Four verdicts — the already-addressed lens twice
(once at **medium** confidence, once at high), the factual lens and the engineering lens — and
none refuted it. The factual lens verified the Activity resource field by field: `actor.email`,
`profileId`, `callerType`, `key`, and `applicationInfo` with `oauthClientId`, `applicationName`
and `impersonation`. With no DWD the robot never impersonates, so `impersonation` is always
false and `actor.email` is always `walle@`. It also confirmed the access-review limb: neither
group carries a Workspace admin role at all — they are a Gemini Enterprise share plus a
membership check — so an admin-role review reading the console genuinely cannot see them. The
engineering lens conceded at high confidence and found each of the four fixes cheap and
already aligned with controls in the set: the forensic join is nearly free because the second
organisation-level sink deliberately carries no principal filter, so Google's admin events
already land beside `walle_audit`, with `in_flight/{run_id}#{item}` as the join key; the
retention alignment is one line in [decision 17](09-open-decisions.md), which is explicitly
only a default; and storing the raw signed assertion is the genuine delta, because a stored
claim is the service's own word while a stored Google-signed blob is evidence a compromised
service cannot fabricate.

**The sharpest correction cuts in the design's favour and against it at once.** The
already-addressed and factual lenses both found that the human **is** recoverable from a
Google-written log for IAP approvals, because IAP writes Cloud Audit Logs data-access entries
naming the authenticated principal — but **Data Access audit logging is enabled nowhere in the
set**; the runbook only ever reads IAP *request* logs for a dry-run check. So the challenge's
"no Google-written record can contradict it" is wrong for approvals, and the actionable
consequence is a line the challenge does not write: enable Data Access audit logs for
`iap.googleapis.com`, or the Google-side approver record does not exist to be joined. For T0
chat requests, where the requester email is merely asserted by the Discovery Engine service
agent, no Google-written record binds the human to the action at all.

**What the refuters took off the claim.** Three things, none defeating it. First, the design
never cites Google's log as evidence of *who asked* — [06](06-security-guardrails.md)'s
compromised-service row and weakness 1 use it as proof that the **robot** acted, and Eve's
reconciliation runs in both directions; the defect is that neither page states the limit.
Second, the stored-raw-JWT proposal proves less than claimed: the IAP assertion carries
`iss`, `aud`, `sub`, `email`, `hd`, `iat` and `exp` but no `plan_hash`, so a compromised
service could pair a valid assertion from that human with a different plan, and re-verifying
the signature later means archiving IAP's rotating public keys. Half of it is also already
built — [ARCHITECTURE.md](ARCHITECTURE.md) already requires the service to verify the
assertion against IAP's keys with the audience checked and to bind the verified identity and
asserting surface into the approval record; only storing it **verbatim** is new, and even
then it gives Google-signed provenance against a *buggy* service rather than a *compromised*
one, becoming independent evidence only once a second party validates it against the
insert-only dataset. Third, the challenge's own field list omits
`actor.applicationInfo.impersonation`, which does exist; the point survives because it is a
boolean asserting the app acted for the user already named in `actor.email`, and Wall-E never
impersonates, so it is always false and names nobody. The claim should say so rather than
omit the field.

**Decision: change now.** Edits:
- [SETUP.md](SETUP.md): enable Data Access audit logging for IAP, so the approver is
  recoverable from a Google-written record independent of `walle-actions`. Add the same for
  KMS `AsymmetricSign`, so every accepted Eve approval matches a Google-written signing
  record.
- [03-lld.md](03-lld.md) `approvals`: store the raw signed assertion **and which surface
  produced it**, written surface-agnostically because [decision 14](09-open-decisions.md) is
  still open between an IAP page and a Chat app.
- [06-security-guardrails.md](06-security-guardrails.md) "the action service is compromised"
  row and [ARCHITECTURE.md](ARCHITECTURE.md) weakness 1: state that Google's log proves the
  **robot** acted, not **who asked**, and that human attribution rests on `walle_audit` for
  T0 chat.
- Publish a saved BigQuery view joining Google's admin events (from the organisation-level
  sink, which already exists for the N8 completeness metric) to `walle_audit` requester and
  approver. It is one view over data the design already collects, but name the dependency the
  engineering lens named: that sink needs organisation-level log configuration rights, which
  are a separate approval. Add `walle-operators@` and `walle-readers@` to the organisation's
  periodic admin-role access review. `Assumption:` such a review exists — the refuters could
  not confirm one, and nothing in the set mentions one.

---

### C24 — The first playbooks and Stage 5 suspension duplicate native features (partially stands)

**Claim.** Two of the three guessed first playbooks, and the end state for suspension,
duplicate what Workspace or a standard identity provider already does. Dynamic groups can
exclude suspended users by condition. Where an HR system of record exists, the identity
provider's provisioning connector suspends Google users as a matter of course. Stage 5 plans
to let Wall-E suspend at L4 from that same system of record after 27–38 weeks of ladder,
creating the second writer [decision 1](09-open-decisions.md) warns about.

**Why it only partly stands.** "Leaver group hygiene" as a whole playbook is not duplicated
by native features — dynamic groups cover attribute-defined groups only, and static groups
remain. What stands: S5's autonomous F5 suspension from an HR feed duplicates a
deprovisioning connector wherever one exists, and neither
[decision 1](09-open-decisions.md) nor [decision 13](09-open-decisions.md) concludes that
Wall-E should defer to it; and [decision 12](09-open-decisions.md)'s candidates get no
native-first check.

**Decision: change now.** Edit [09-open-decisions.md](09-open-decisions.md)
[decision 13](09-open-decisions.md) and [05](05-autonomy-ladder.md) S5: if an HR or
identity-provider connector already suspends Google accounts from the system of record,
suspension belongs to that connector — F5 stays at L3 for chat permanently, and Wall-E
handles the resulting `USER_SUSPENDED` event with F3 and F7 cleanup, which is work the
connector does not do. Add a one-line native-first check to
[decision 12](09-open-decisions.md), naming dynamic groups where the edition allows them.

---

### C25 — No build-versus-buy record (partially stands)

**Claim.** Neither the HLD nor [ARCHITECTURE.md](ARCHITECTURE.md) explains why this is built
rather than bought or assembled from Google's agent products.
[02](02-identity-and-auth.md)'s rejected alternatives cover DWD, Marketplace apps and Gemini
Enterprise Authorizations — not what a sponsor, a security reviewer or a data-protection
assessment will raise in September 2026: Gemini in the Admin console, Workflow Builder
agents, Workspace Studio flows, Workspace MCP servers, the `gws` CLI, SaaS management
platforms with AI agents.

**Why it only partly stands.** Two lenses found the build is *not* unjustified: every option
listed falls into a class the design already excludes with reasons, and those reasons are
correct as of 2026-09-11. What survives is the absence of a **dated, per-product table with
"re-evaluate when" triggers**, and the fact that [decision 8](09-open-decisions.md)'s
assessment will need a necessity argument naming less intrusive options.

**Decision: change now.** Add a dated "Alternatives considered" section to
[01-hld.md](01-hld.md) (or rows to [02](02-identity-and-auth.md)'s rejected-alternatives
table), mirrored into [ARCHITECTURE.md](ARCHITECTURE.md) section 10 and fed into the decision
8 input. The table in section 7 of this page is the content. Each row carries the constraint
the option fails, the source, and a "re-evaluate when" condition.

---

### C28 — No value baseline, no stop rule, and an incomplete cost table (stands)

**Claim.** The HLD has no cost or value section. [SETUP.md](SETUP.md) section 0.3 leaves unit
prices blank and assumes "low tens of euros per month", omits Agent Gateway, Model Armor,
Sessions, the approval surface and operator Gemini Enterprise seats, and names BigQuery as
the larger line while Phase 5 calls Cloud Logging ingestion "the largest single cost line".
The dominant cost — a senior administrator's time across 21 phases and weekly evidence — is
uncounted. Value is equally unmeasured: [decision 12](09-open-decisions.md) admits the
playbooks are guesses.

**Why the refuters could not dismiss it.** Unanimous, one at high confidence.

**Decision: change now, and open a decision.** Edits: complete the
[SETUP.md](SETUP.md) section 0.3 table with rows for Agent Gateway ingress and egress, Model
Armor, Sessions, the approval surface, operator seats and **human operating hours per
month**, with prices `tbd` until verified at the first billing cycle, and reconcile the
BigQuery row with Phase 5. New decision 38: measure baseline toil for the top three admin
tasks over four weeks before Phase 1 as the value denominator, and set a dated
**stop-or-continue review at S1 exit** — if toil saved at S1 plus projected S3 saving is below
operating cost, the programme stops at S1 rather than continuing by momentum.

---

### C35 — A generic Admin SDK proxy would not have been better, but nothing records why (stands)

**Claim.** The typed catalogue is the right core; what limits "any action a human can do" is
the identity. Under the same robot, a generic Discovery-driven proxy adds reach only in
Directory, Licensing, Data Transfer, Chrome Policy and shared drives, at the price of the
per-operation inverse, pre-state predicate, taint declaration and readable approval card the
ladder depends on. Nothing records that reasoning, and nothing is offered for work no
identity can reach.

**Why the single refuter could not dismiss it.** One refuter ran, the already-addressed lens,
at medium confidence. The nearest text is a non-goal and the DWD exclusion, neither of which
is this argument.

**Decision: change now.** Add one rejected-alternatives row in
[02-identity-and-auth.md](02-identity-and-auth.md) or
[ARCHITECTURE.md](ARCHITECTURE.md) section 10 recording why a generic Discovery-driven
executor behind the action service was rejected: no per-operation inverse, pre-state
predicate, attacker-writable field declaration or readable approval card, all four of which
the ladder above L2 depends on. Separately, for band C work (C1), add a read-only **handoff
lane** on chat: Wall-E returns the exact console steps for a human super admin and opens a
watch via `reports.activities.list`, already in F1, for the matching admin audit event,
reporting "verified" or "not seen within N hours". No new credential, no new write.

---

### C29 — The ingress gateway may screen no production traffic (stands)

**Claim.** [Decision 21](09-open-decisions.md) makes Agent Gateway a pre-Stage-1
requirement, and [SETUP.md](SETUP.md) 12c and 13b build ingress Model Armor, an egress
allowlist and registry alerting at Stage 0 — none of it on the HLD component map, although it
adds a fail-closed dependency to every turn. The design's own grading says the value is thin:
egress Model Armor "screens nothing for Wall-E as designed", ingress screens `streamQuery`
only, and Google says Client-to-Agent mode is not supported for Gemini Enterprise.

**Why the refuter could not dismiss it.** The single refuter conceded and proposed the same
split. Verified again on 2026-09-12, and this is now a quoted product fact rather than an
inference: Google's own page states that Agent Gateway supports Gemini Enterprise in
Agent-to-Anywhere (egress) mode only, and that ingress traffic is not supported. So for the
pilot's only production caller, the ingress screen is not on the path.

**Decision: change now.** Keep [decision 21](09-open-decisions.md) and the egress dry-run at
S0. Move only the **ingress** half — [SETUP.md](SETUP.md) 12c steps 4 and 5: the
Client-to-Agent gateway, the fail-closed Model Armor extension and the engine binding —
behind two conditions: the Gemini Enterprise invoke method measured from the Agent Runtime
request logs, and the [decision 24](09-open-decisions.md) flip to blocking. Record the quoted
limitation in [13-agent-interconnection.md](13-agent-interconnection.md) section 7 and in
[decision 21](09-open-decisions.md) so nobody re-derives it. Create the engine with
`identity_type=AGENT_IDENTITY` regardless — that is immutable and cheap to decide now.

---

### C30 — The walle-events topic has no consumer BigQuery does not already serve (stands)

**Claim.** The HLD draws `CR --> PS`, `PS --> EVE` and `PS --> MO` as part of the evidence
plane, and [08](08-team-eve-mo.md) lists `walle-events` as a surface Eve and Mo subscribe
to — but every duty 08 assigns them is satisfied by BigQuery. The only
latency-sensitive Eve duty is L5 post-hoc verification within 60 minutes; L5 is unreachable in
the pilot, and polling the partitioned `actions` table meets a 60-minute SLA anyway. The
topic, its publisher role, its event vocabulary and its maintenance are a contract with no
reader.

**Why the refuter could not dismiss it.** Conceded; addressed nowhere.
[ARCHITECTURE.md](ARCHITECTURE.md) sections 6 and 7.3 assert the stream and never argue it
against BigQuery.

**Decision: change now.** Mark `walle-events` in [01-hld.md](01-hld.md),
[ARCHITECTURE.md](ARCHITECTURE.md) and [08-team-eve-mo.md](08-team-eve-mo.md) as **added with
Eve's design**, not at Stage 0 — 08 matters most, because it is the page handed to Eve's and
Mo's designers and it currently promises them the topic in both its shared-data-plane table
and its "the place they meet" sentence. Remove the `PS --> EVE` and `PS --> MO` edges from
the pilot component map, or label them target state.
Adding a publish call to the audit writer later is additive and cheap; keeping an unread event
vocabulary consistent for months is not. Folded into new decision 36.

---

### C36 — Four contradictions that make on-request use worse than intended (stands)

**Claim.** (1) [01](01-hld.md)'s non-goals cap irreversible operations at "propose" or
exclude them, but [05](05-autonomy-ladder.md) section 4 lets irreversible `WRITE_HIGH` run at
L3 on chat and irreversible mail and Chat reach L5 templated — the ceiling table is right for
fit, the non-goal is stricter than the code. (2) [04](04-flows.md) Flow A still says
suspending a delegated admin trips the breaker and drops the family to L0, while
[03](03-lld.md) and [05](05-autonomy-ladder.md) section 9 give an ordinary refusal; the fix
recorded in [10](10-adversarial-review.md) never reached 04. (3) S1's joiner promise. (4)
[05](05-autonomy-ladder.md) section 5 F4 still carries "L3 (OU move)" although the OU move is
its own family F4b.

**Why the single refuter could not dismiss it.** One refuter ran, the already-addressed lens,
at high confidence, conceding items 1, 2 and 4; item 3 stands as ambiguous wording and is
carried on C21. A fifth was found:
[06](06-security-guardrails.md)'s "Never in the catalogue" Structure row says F4 where it
means F4b. And [10-adversarial-review.md](10-adversarial-review.md) wrongly reports item 2 as
resolved.

**Decision: change now.** Align [01-hld.md](01-hld.md), [04-flows.md](04-flows.md),
[05-autonomy-ladder.md](05-autonomy-ladder.md) and
[06-security-guardrails.md](06-security-guardrails.md) with [03](03-lld.md) and
[05](05-autonomy-ladder.md) section 4, which are what the service actually enforces. Correct
[10](10-adversarial-review.md)'s contradictions list, which currently claims a fix that was
never applied.

---

### C37 — The HLD is behind its own design set (stands)

**Claim.** [01-hld.md](01-hld.md), last reviewed 2026-09-09, shows seven GCP components. The
set actually operates at minimum: Agent Gateway ingress and egress, Model Armor templates and
floor settings, Agent Identity, a KMS key, Cloud Tasks, a queue worker and reconciler, an
approval surface, two organisation sinks and a second BigQuery dataset, an Agent Registry
entry and Eve's robot account. The corrections table says the region is "decision closed",
while [12](12-agent-identity.md) lists Agent Gateway availability in `europe-west1` as `tbd`
and [decision 21](09-open-decisions.md) makes the gateway the chosen control.

**Why the refuter could not dismiss it.** Conceded; [ARCHITECTURE.md](ARCHITECTURE.md)
section 3's service inventory already lists what 01 omits, which proves the staleness rather
than excusing it. I could not verify Agent Gateway's `europe-west1` availability from
Google's supported-locations page on 2026-09-12 either, so that question stays genuinely
open.

**Decision: change now.** Refresh [01-hld.md](01-hld.md)'s component map and corrections
table against [11](11-prompt-security.md), [12](12-agent-identity.md),
[13](13-agent-interconnection.md) and [SETUP.md](SETUP.md) phases 12b, 12c and 13b, marking
each component GA or Preview. Narrow the "region — decision closed" row to the components it
was actually verified for (Agent Runtime, Sessions, Memory Bank) and add Agent Gateway's
region as `tbd` with the open question named once, in one place. Fix
[`setup/README.md`](setup/README.md) line 3: it says "the 18-phase runbook" and
[SETUP.md](SETUP.md) section 0.4 lists 21 phases.

## What was refuted

All nine, none dropped. Several leave a documentation residual, recorded after the table.

| # | Title | Why it does not stand | Where the design already answers it |
|---|---|---|---|
| **C9** | The admin identity and the attacker-facing mailbox are the same principal | The phishing framing fails: the robot has no interactive login, hardware-key-only 2SV, no recovery options, and nothing uses the mailbox until S3, by which time T3 is L0 through S2. What survives is operational coupling, not exposure. | [02](02-identity-and-auth.md) "locking down the robot account" and "what makes the refresh token stop working"; [SETUP.md](SETUP.md) Phase 3; [04](04-flows.md) Flow F; [06](06-security-guardrails.md) N6 |
| **C11** | Eve's trust root is administered from inside Wall-E's project | Two of three refuters found this belongs to Eve's own design and [decision 18](09-open-decisions.md), due before S4, not to the HLD now. The deploy-grant concentration is already named as weakness 12 and knowingly accepted. *Note of 2026-09-13:* the verdict stands, and the premise no longer holds — Eve's key, secrets, evidence mirror and jobs are in `EVE_PROJECT` ([../project-topology.md](../project-topology.md) §2). | [ARCHITECTURE.md](ARCHITECTURE.md) section 4.2 and weaknesses 1, 10 and 12; [12](12-agent-identity.md) section 10 drift job; [10](10-adversarial-review.md) accepted risks |
| **C26** | The ladder over-specifies six levels for a pilot capped at L3 | Merging L1 and L2, collapsing T1 and T2, and cutting the ladder to what is reachable would each lose something real: L2's proposal queue is the evidence source, and the trigger classes climb independently by design. [ARCHITECTURE.md](ARCHITECTURE.md) section 0 already labels L4/L5 target state. | [ARCHITECTURE.md](ARCHITECTURE.md) section 0 and 12; [05](05-autonomy-ladder.md) sections 3–4; [08](08-team-eve-mo.md) intro |
| **C27** | The HLD never states time-to-first-autonomous-write | Two refuters found the design deliberately refuses calendar commitments — R8 is "evidence, not calendar" — and that the README already frames autonomy as per-pair and never global. The fix is two corrected sentences, not a milestone plan. | [README.md](README.md) lines on progressive autonomy; [05](05-autonomy-ladder.md) R8; [ARCHITECTURE.md](ARCHITECTURE.md) section 0; [SETUP.md](SETUP.md) sections 0.2 and 0.4 |
| **C31** | T0 single-object writes add little over the Admin console | S1's purpose is explicitly ladder evidence and guardrails, not efficiency, and the flows already carry pre-state capture and one-approval rollback that the console does not. | [05](05-autonomy-ladder.md) S1 purpose and value; [04](04-flows.md) Flow A; [01](01-hld.md) non-goals |
| **C33** | The strongest credential guards the component that holds nothing | Correct as an observation and already the design's position: [12](12-agent-identity.md) rejects the auth manager for the robot token with reasons, and [ARCHITECTURE.md](ARCHITECTURE.md) forbids the agent holding a Workspace token. | [12](12-agent-identity.md) sections 1.3 and 2; [ARCHITECTURE.md](ARCHITECTURE.md) section 4.2 agent row; [06](06-security-guardrails.md) "robot credential leak" |
| **C38** | Inbox-derived proposals lose provenance when re-issued from chat | T3 is out of pilot scope entirely, chat writes are capped at L3 through S5, and A1 stops the agent releasing anything. The laundering path needs a human who chooses to act, in a class with per-item approval. | [05](05-autonomy-ladder.md) stage overview and L2; [ARCHITECTURE.md](ARCHITECTURE.md) section 8.4; [10](10-adversarial-review.md) accepted risks |
| **C40** | Agent Registry, the A2A card and the `agent` ceiling column are ahead of any consumer | The `agent` type already hard-denies writes at policy step 5 and taints at run open, the card is not registered before A2A, and the egress-gateway work the challenge wanted kept is the part that is justified. | [13](13-agent-interconnection.md) sections 2.4, 5.4 and 5.5; [SETUP.md](SETUP.md) Phase 13b |
| **C44** | Make a verified requester token a prerequisite for the entitlement check | The challenge argued *against* its own alternative and the refuter agreed: approvals are already bound to an IAP-verified identity ([12](12-agent-identity.md) section 5.3), and [02](02-identity-and-auth.md) already keeps the Authorization as optional hardening that may never carry Workspace write scopes. The refuter corrected the challenge on one point — a token limited to `userinfo.email` is not an admin credential and does not contradict boundary 3; the real costs are a user token passing through the agent process and a consent prompt per operator. | [02](02-identity-and-auth.md) "how the end user's identity reaches the policy engine"; [12](12-agent-identity.md) section 5.3 |

**Residuals from refuted challenges.** A refutation of the claim is not a refutation of every
sentence in it. These edits are carried into the consolidated list:

- **C9**: [decision 3](09-open-decisions.md) should state explicitly whether the `gmail.*`
  scopes belong on the same grant as the admin scopes, since a password change or super-admin
  reset kills the admin credential only because they do. The mailbox restrictions
  ([SETUP.md](SETUP.md) Phase 16) are specified but not implemented anywhere.
- **C11**: add three rows to the drift job — `cloudkms.signer` on `eve-approval`, accessors of
  `eve-refresh-token`, and IAM on the evidence dataset — and record as an input to
  [decision 18](09-open-decisions.md) that Eve's evidence copy should live where Wall-E's
  deployers cannot rewrite it. *As of 2026-09-13:* those three rows belong to **Eve's** drift
  job in `EVE_PROJECT`, whose IAM Wall-E's job cannot read (decision 46); the evidence-copy
  requirement is met by Eve's `walle_audit` mirror in `EVE_PROJECT`; and Wall-E's drift job
  instead watches the cross-project grants it made — `dataViewer` on its datasets,
  `run.invoker` on `walle-actions`, the absence of authorised-view entries, and
  `walleEngineQuery` on the engine ([12](12-agent-identity.md) section 10).
- **C26 and C27, jointly**: both refuters found the same unowned contradiction, and it belongs
  to nobody today. [05](05-autonomy-ladder.md) section 7 puts **scheduled F2 at L4 in S2**,
  and calls it "the first autonomous write in the whole programme", while L4 means Eve
  approves ([05](05-autonomy-ladder.md) section 2), [ARCHITECTURE.md](ARCHITECTURE.md)
  section 0 says L4 cannot be delivered in the pilot, and [SETUP.md](SETUP.md) section 0.2
  says unattended writes start at Stage 3 at the earliest. One of those three is wrong and the
  set does not say which. Fix it in [05](05-autonomy-ladder.md). Also correct
  [ARCHITECTURE.md](ARCHITECTURE.md) line 34: "roughly nine months of stages" is the sum of
  the [05](05-autonomy-ladder.md) floors from S0 entry to S5 and excludes the code build,
  Eve's design and build, and the data-protection lead time — say so.
- **C31**: record in [01-hld.md](01-hld.md) that T0 writes are attributed to `walle@` in
  Google's admin audit log, with the human recoverable only by joining `walle_audit`. That is
  a real forensic cost and it is currently written down nowhere (it is also C43's subject).
- **C38**: before T3 opens at S3, carry `proposal_id` onto the operator's follow-up request
  and the approval card, and show the canonicalised sender with its authentication result.
- **C40**: state in [03](03-lld.md) and [13](13-agent-interconnection.md) **which principal
  type a non-A2A peer calling over `streamQuery` receives, and how that type is established
  rather than asserted**. C10 settles it by removing Eve from that channel; if any other peer
  is ever added, the question returns.
- **C44**: [02](02-identity-and-auth.md) should say which identity each path's check uses —
  asserted email on chat, IAP-verified on approval — and when to revisit the Authorization
  binding.

## Alternatives considered

Every alternative path raised across the eleven lenses, with its verdict. Product facts as of
2026-09-11, re-verified 2026-09-12 where marked.

| Alternative | What it would gain | What it would lose | Verdict |
|---|---|---|---|
| **Gemini Enterprise no-code agent, or Gemini in the Admin console** | No build. Google-operated. | Gemini in the Admin console advises super admins, it does not act. A no-code agent makes the operator's own admin rights the ceiling and puts no deterministic gate between model output and the Admin SDK. | **Rejected.** Already rejected correctly in [02](02-identity-and-auth.md); the reason now needs dating and a re-evaluation trigger (C25). |
| **Workflow Builder scheduled agents / Workspace Studio flows** | Native, no GCP project, no credential of our own. | They run on the creating user's credentials — Workflow Builder schedules expire every 14 days; Workspace Studio flows run with the user's identity with no documented expiry — cannot act on other people, and custom steps are in limited preview. | **Rejected.** Re-evaluate when a flow can run as a non-user principal with admin privileges. |
| **A service account with domain-wide delegation** | Any API, any user, no robot account. | The standing constraint, and the over-broad grant and unreadable audit trail that constraint exists to avoid. | **Rejected permanently.** Not reopened by any lens. |
| **A service account holding the custom admin role, no DWD** | Removes the password, recovery path, hardware key, interactive consent, frozen scope set and stealable refresh token for the admin half. Keyless tokens from the metadata server. The role becomes the ceiling. | Coverage beyond the Groups APIs is undocumented; Gmail, Chat and Calendar still need a user. Splits the identity in two. | **Pending a spike before Phase 9** — new decision 26 (C3). Verified 2026-09-12: Google documents that any prebuilt or custom role except Super Admin can be assigned to a service account. |
| **A generic Discovery-driven Admin SDK proxy** | Wider reach without hand-typing each operation; off-the-shelf executors exist. | The per-operation inverse, pre-state predicate, attacker-writable field declaration and readable approval card — all four of which the ladder above L2 depends on. Reach gained only in Directory, Licensing, Data Transfer, Chrome Policy and shared drives. | **Rejected, and the reason must be recorded** (C35). |
| **Buying a SaaS-management platform with AI agents** | No build, vendor-operated, broad coverage. | Every such platform holds a tenant-wide grant outside the no-DWD rule; at least one vendor's exact auth model could not be verified. | **Rejected.** Re-evaluate if a vendor documents least-privilege, no-DWD operation. |
| **No Eve — human approval only, permanently** | Removes a whole agent, its credential, its project and its acceptance test. L3 is already dual control. | Nothing at L4 or L5, so no unattended write ever. | **Not rejected — it is the honest pilot.** The pilot is capped at L3, Eve has no design and no date, and new decision 34 makes "Eve v0" deterministic BigQuery queries read by a human. This is the operating assumption until an Eve design record exists. |
| **An LLM Eve** | A second opinion on judgement, not just invariants. | Reproduces Wall-E's own failure modes at the one gate that replaces a human. Contradicts [12](12-agent-identity.md) section 1.8. | **Rejected** (C12). Advisory model beside the deterministic controller is permitted; it may not produce a signature. |
| **Policy-as-code without stages** | Far less machinery: one allowlist, one on/off switch per operation. | No evidence gradient. `WRITE_HIGH` becomes a boolean nobody can justify flipping. | **Rejected** by the autonomy lens as strictly worse than the ladder. |
| **Always human, forever (L3 batch as the end state)** | All the safety with none of the Eve machinery. | Nothing, for `WRITE_HIGH`. | **Accepted as a legitimate steady state** (C34). The design must say so rather than treating S4 as inevitable. |
| **Canary with automatic rollback instead of a ladder** | Fast, familiar from software deploys. | A Workspace rollback is itself a write needing fresh pre-state, which is why F10 is capped at L3. Automatic rollback would be an unapproved write. | **Rejected** on mechanism, not taste. |
| **Deterministic playbooks with no model on T1/T2** | Removes the A3/A11 injection class, the job envelope, agent job mode and machine-traffic screening from the autonomous path. | A prose `expects` becomes a typed predicate, which is less flexible; genuinely judgement-bearing playbooks need an exception. | **Recommended** — new decision 32 (C2). Deterministic by default, `requires_model` by exception. |
| **Merging the action service into the agent** | One service, one deploy, one hop less. | Trust boundary 3. The refresh token would sit in the LLM's process. | **Rejected permanently.** |
| **Approvals in Google Chat instead of an IAP page** | Native, no second surface. | Reinstates attack A1, and under user authentication the Chat API sends text only, so one-click cards need a Chat app anyway. | **Open as [decision 14](09-open-decisions.md)**, unchanged by this review; C43 requires only that whichever surface is chosen produces a verifiable assertion that is stored. |
| **A separate staging project (`walle-stg`) with its own robot** | A real pre-production credential holder; the denial suite and rollback drills run without touching production. | A second consented robot, a second OAuth client, a second hardware key, and a second tenant-wide reader before the data-protection assessment. | **Deferred in favour of a cheaper form**: offline harness plus a sandbox-OU-scoped second robot holding no customer-scoped Reader, in Wall-E's project (`WALLE_PROJECT`). New decision 29 (C50). |
| **A separate tenant for pre-production** | The only thing that contains group-family writes, since Groups privileges cannot be OU-scoped. | Cost, and a second tenant to administer. | **Open, due before any F3 or F3b cell leaves L1** — folded into new decision 29. |
| **A separate evidence project with a project lien** | Puts the promotion evidence outside Wall-E's teardown reach. | One more project and one more IAM boundary to maintain. | **Deferred to Stage 1**, with the cheap half (write-ahead grades to BigQuery, teardown guards) done now — new decision 31 (C46). *As of 2026-09-13* Eve's `walle_audit` mirror in `EVE_PROJECT` exists as an off-project copy, and its locked bucket carries a lien; whether it satisfies decision 31 is decision 51 in [../project-topology.md](../project-topology.md). Decision 31 unchanged. |
| **Gemini Enterprise Authorizations to bind the requester's identity** | The entitlement check would run on a verified token instead of an asserted email. | A user token passing through the agent process, a consent screen per operator, and dependence on an under-documented binding — not a boundary-3 violation, which the refuter explicitly rejected: a token limited to `userinfo.email` is not an admin credential. | **Rejected** (C44). Keep the IAP-verified approver as the strong binding. |
| **Exposing `walle-actions` as an MCP server** | The egress gateway's Model Armor would screen tool results. | A second protocol on the credential holder. | **Unchanged: no**, per [decision 22](09-open-decisions.md). No lens reopened it. |

## What this changes in the design

### Consolidated edit list

Ordered by file. Each row is a change this review recommends. No row removes or replaces a
trust boundary and none touches the no-DWD rule, but two rows do reach the boundaries: C41
rewords boundaries 1 and 4, and C8 tightens how boundary 1 is enforced. Two touch the
component map: the refresh in C37 adds the
components 01 omits, and C30 demotes `walle-events` and its two edges to target state. One
more is contingent — if the decision 26 spike passes, design intent 1's "one Workspace
identity" becomes two principals and the `RB` node splits.

| File | Section | Change | From |
|---|---|---|---|
| [01-hld.md](01-hld.md) | new: Requirement fit | Bands A/B/C table; state that write coverage is the catalogue, not the Admin console; separate constraint-forced from chosen exclusions; show the leaver journey step by step marked Wall-E or human | C1, C21 |
| [01-hld.md](01-hld.md) | Trust boundaries, rows 1 and 4 | Group membership grants the right to *use* Wall-E, not a bound on reach; add the "How it can still fail" column | C41 |
| [01-hld.md](01-hld.md) | The request path | T0 requires both live group membership and the committed operator list | C8 |
| [01-hld.md](01-hld.md) | new: Environments and promotion | Offline harness is the default first execution; pre-production credential holder is decision 29; no F3/F3b cell leaves L1 until it is answered; never recreate the engine to roll back | C50, C53 |
| [01-hld.md](01-hld.md) | new: State, recovery and evidence | Per-store RPO and RTO; a restored control plane starts at `halt_all` | C45, C49 |
| [01-hld.md](01-hld.md) | new: Alternatives considered | The dated table in section 7 of this page, with re-evaluate-when triggers | C25 |
| [01-hld.md](01-hld.md) | new: Cost and value | Complete cost lines including human hours; the S1 stop-or-continue review | C28 |
| [01-hld.md](01-hld.md) | Component map | Refresh against 11/12/13 and SETUP phases 12b/12c/13b; mark GA or Preview; `walle-events` and the `PS --> EVE`/`PS --> MO` edges become target state | C30, C37 |
| [01-hld.md](01-hld.md) | Component map | Replace the agent node's "ADK 2.8" with a reference to the single exact pin | C15 |
| [01-hld.md](01-hld.md) | Corrections table | Narrow "region — decision closed" to Agent Runtime, Sessions and Memory Bank; Agent Gateway region `tbd` | C37 |
| [01-hld.md](01-hld.md) | Component map, layer table | Eve is a deterministic verifier; its approve decision and signature are code | C12 |
| [01-hld.md](01-hld.md) | Non-goals | Reconcile the irreversible-operation non-goal with the [05](05-autonomy-ladder.md) section 4 ceilings; state that L3 batch is an acceptable permanent steady state; record that T0 writes are attributed to `walle@` in Google's log | C31, C34, C36 |
| [02-identity-and-auth.md](02-identity-and-auth.md) | Rejected alternatives | Add service-account-holding-the-role as **pending**; add the generic Discovery proxy as rejected with its reason; add the September 2026 Google-native and bought options with dates | C3, C25, C35 |
| [02-identity-and-auth.md](02-identity-and-auth.md) | Scopes | Correct the shared-drive premise; state the role-is-the-ceiling rule for admin APIs; correct the 100-token wording; say which identity each path's entitlement check uses | C23, C32, C44 |
| [02-identity-and-auth.md](02-identity-and-auth.md) | Robot lockdown | Re-label the login rule as detecting interactive takeover only | C4 |
| [02-identity-and-auth.md](02-identity-and-auth.md) | OAuth client | Trusted for the robot's OU only; Blocked at the top-level OU | C6 |
| [03-lld.md](03-lld.md) | Policy chain | Record step 5b — requester and approver entitlement intersection via `rolemanagement.readonly` — as the stronger form, deferred with its reasons; the committed operator list carries each operator's role and OU reach instead, reconciled daily | C41 |
| [03-lld.md](03-lld.md) | Policy chain, step 5 | Require both live membership and the committed operator list | C8 |
| [03-lld.md](03-lld.md) | Queue worker | Re-verify the stored approval envelope on **every** item; `released` is a cache, never the authorisation | C5 |
| [03-lld.md](03-lld.md) | Firestore / storage | Grades, proposal verdicts and drill results written write-ahead to `walle_audit`; halts, overrides and breaker demotions logged as rows; `control_plane_rolled_back` denial reason and boot-time epoch comparison | C45, C46 |
| [03-lld.md](03-lld.md) | Denial reasons | Add `role_assignment_missing`; add the `capability_gap` record with a closed-enum intent class only | C22, C47 |
| [03-lld.md](03-lld.md) | Approvals schema | Per-item accept/reject vector bound to `plan_hash`; `eve_key_version`; the raw signed human assertion and which surface produced it | C16, C43, C48 |
| [03-lld.md](03-lld.md), [04-flows.md](04-flows.md) | Proposal follow-up | Before T3 opens at S3, carry `proposal_id` onto the operator's follow-up request and onto the approval card, and show the canonicalised sender with its authentication result | C38 |
| [03-lld.md](03-lld.md) | Catalogue | Mark READ rows that return per-person personal data; required property test per entry (pre-state, apply, predicate, inverse, restore) and error-mapping test; declare each entry's upstream contract | C42, C52, C54 |
| [03-lld.md](03-lld.md) | Audit rows | Stamp the full platform fingerprint; any change to it is material | C15 |
| [03-lld.md](03-lld.md) | T2 handling | Corroborate every trigger against Google's own copy before opening a run | C7 |
| [03-lld.md](03-lld.md) | Halt | A self-halt from a control-plane outage is sticky until an operator clears it | C49 |
| [03-lld.md](03-lld.md), [08-team-eve-mo.md](08-team-eve-mo.md) | Contract | Canonical plan serialisation, hash algorithm, signed field list, event schema with `contract_version`; principal type for a `streamQuery` peer | C39, C40 |
| [04-flows.md](04-flows.md) | Flow A | Approver must differ from requester; correct the protected-principal branch to an ordinary refusal | C8, C36 |
| [04-flows.md](04-flows.md) | Flow C | Per-item verdicts; `skipped_by_operator` | C16 |
| [05-autonomy-ladder.md](05-autonomy-ladder.md) | §7 stage table | Resolve the S2 scheduled-F2-at-L4 contradiction; say whether sandbox items count towards S0 coverage; state that volume gates are expected to bind before the floors | C19, C26, C27 |
| [05-autonomy-ladder.md](05-autonomy-ladder.md) | §7 stage table | Raise the per-family graded-item minimum from 30 to 35, so the Wilson gate is reachable at all; state that the minimum sample and the interval gate are one decision | C18 |
| [05-autonomy-ladder.md](05-autonomy-ladder.md) | §8 metrics | Wilson interval gates with hysteresis; `unsure` excluded from the ratio; blind sampled review at `max(10 %, 5/week)`; 20 % blind double-grading for `WRITE_HIGH` | C16, C17, C18 |
| [05-autonomy-ladder.md](05-autonomy-ladder.md) | §10 promotion | Validator matches two distinct authenticated reviewers; re-qualify a cell when the platform fingerprint or selection changes; required "Why worth it" line for L3→L4 `WRITE_HIGH`; keep a production-side platform-test gate | C15, C17, C34, C51 |
| [05-autonomy-ladder.md](05-autonomy-ladder.md) | §5, §11, S1, S3, S5 | F4/F4b wording; S1 value wording; 100 % seeded-invariant catch at S3; F5 defers to an existing connector; Stage 1 restore drill and reconstruction script | C12, C21, C24, C36, C45 |
| [06-security-guardrails.md](06-security-guardrails.md) | Threat model | Rewrite the "robot credential leak" residual; correct the "poisoned upstream signal" control; state that Google's log proves the robot acted, not who asked; define "operator things" | C4, C7, C41, C43 |
| [06-security-guardrails.md](06-security-guardrails.md) | Monitoring | New rows: robot or client activity outside `walle-actions`; token authorize on Wall-E's client by a non-robot; access to `walle-oauth-client` by a non-service identity; membership or ownership change on `walle-operators@`; admin action targeting the robot; event trigger gone quiet | C4, C6, C8, C47, C54 |
| [06-security-guardrails.md](06-security-guardrails.md) | Forbidden configurations | No fault-injection or test-mode path in the admitted image; no mutable tag in any deploy; correct the F4/F4b row; split the Drive row into My Drive and shared drives | C23, C36, C51, C53 |
| [08-team-eve-mo.md](08-team-eve-mo.md) | Shared data plane | Mark the `walle-events` row and the "the place they meet" sentence as target state, added with Eve's design, not at Stage 0 | C30 |
| [08-team-eve-mo.md](08-team-eve-mo.md) | Mo | Correct the identities row and item 6 to the two read endpoints only | C39 |
| [08-team-eve-mo.md](08-team-eve-mo.md) | Eve | Deterministic approve and halt with reason codes; licence verification is audit-log-only and partial | C12, C13 |
| [09-open-decisions.md](09-open-decisions.md) | Decisions 3, 4, 5, 11, 12, 13, 17, 21 | Reframe 3 (admin scopes wide, `admin.datatransfer`, `gmail.*` on the admin grant, corrected Drive premise); widen 4 to the whole Never table; add an absolute pilot-OU count to 5; split 11 into 11a/11b; native-first check on 12; connector deference on 13; move 17 to before Stage 1; record the gateway ingress limitation on 21 | C1, C9, C19, C20, C21, C23, C24, C29, C46 |
| [09-open-decisions.md](09-open-decisions.md) | New rows | Decisions 26–41 below | — |
| [10-adversarial-review.md](10-adversarial-review.md) | Contradictions, corrected claims | Correct the claim that the Flow A protected-principal contradiction was resolved; add the shared-drive premise to the corrected-facts table; link this page | C23, C36 |
| [11-prompt-security.md](11-prompt-security.md), [12-agent-identity.md](12-agent-identity.md), [13-agent-interconnection.md](13-agent-interconnection.md) | Pins, drift job, Eve channel | One exact ADK pin referenced everywhere; drift job gains Workspace-contract rows plus `cloudkms.signer`, `eve-refresh-token` accessors and evidence-dataset IAM; remove `reasoningEngines.query` from `eve-controller@`; remove the LLM-hop-before-approve sentence; record the Agent Gateway ingress limitation | C10, C11, C12, C15, C29, C54 |
| [ARCHITECTURE.md](ARCHITECTURE.md) | §0, §4, §10, weaknesses 1 and 11 | "Nine months" is the sum of stage floors and excludes the build, Eve and the data-protection lead time; pin dependencies and restrict `walle-actions` egress; correct the shared-drive and generic-proxy rows; weakness 11 says per-person, not aggregated, and adds conversation history | C4, C23, C27, C35, C42, C43 |
| [SETUP.md](SETUP.md) | Phases 2, 3, 4, 5, 6, 7, 9, 10, 12, 12c, 15, 16, §0.3, §1.3, §4, §7.4, Gemini Enterprise phase | Topic-level publisher binding; dispatcher custom Firestore role; Firestore PITR, delete protection and backups; teardown and dataset-recreate guards; OU-scoped Trusted client; deploy by digest; Phase 12 rollback correction; Data Access logs for IAP and KMS; Eve provisioning moved out of Stage 0; robot-targeted activity rule and second custodian; completed cost table; denial-suite induction procedures and platform/application tags; re-label the Phase 4 login rule as detecting interactive takeover only; correct the shared-drive premise in §1.3; correct the token-limit wording in Phase 9 rollback and troubleshooting; export each Eve public key version at creation, and have teardown check the export exists before offering `--destroy-key-versions`; remove "Eve needs to read assignments" from Phase 15 and drop `apps.licensing` from Eve's grant; implement the Phase 16 mailbox restrictions or record them as unimplemented; move the 12c ingress half (steps 4 and 5) behind the measured invoke method and the [decision 24](09-open-decisions.md) flip; do not share the agent with `walle-readers@` until [decision 8](09-open-decisions.md) has an answer for reads | C4, C5, C6, C7, C9, C13, C14, C23, C28, C29, C32, C42, C43, C45, C46, C47, C48, C51, C53 |
| [`setup/README.md`](setup/README.md) | line 3 | "18-phase runbook" → 21 phases | C37 |
| [README.md](README.md) | Documents table | Add this page as document 14 | — |

### New open decisions for [09-open-decisions.md](09-open-decisions.md)

| # | Decision | Why | Recommendation | Gate |
|---|---|---|---|---|
| **26** | **Is the admin principal a keyless service account holding the custom role, rather than the robot user?** | Google documents that any role except Super Admin can be assigned to a service account with no DWD. If it covers Directory, Licensing and Reports, the password, recovery path, hardware key, consent, frozen scope set and stealable token all disappear. | Spike on a throwaway service account with the reader role through ADC. If it passes, the admin half moves; Gmail, Chat and Calendar stay on a user with no admin role. | **Blocking — before Phase 9 consent, which is irreversible** |
| **27** | **Catalogue breadth: ratify bands B and C** | The requirement was narrowed and never signed off, and scopes freeze at consent. | Wall-E is a narrow operator, not a stand-in for a super admin. Read the bands table and say which band-B exclusions you disagree with. | **Blocking — before [decision 3](09-open-decisions.md)** |
| **28** | **Does a human request or approval have to fall inside the requester's own admin scope?** | Group membership currently grants the robot's whole allowlisted reach. Harmless with one super-admin operator, a privilege-escalation path the day a second operator is added — and [SETUP.md](SETUP.md) Phase 1 already names one. | Yes, but through the committed operator list rather than a live check: record each operator's admin role, families and OU reach before they are added, and reconcile daily against `roleAssignments.list`. Live policy step 5b — privilege-level for Groups and Reports, which Google does not OU-scope, full OU intersection for the rest — is the stronger form and is deferred, because it would put a fail-closed live Directory read on the approval path of a one-person rota and rests on a privilege mapping the set records as unverified. | Before S1 and **before any operator who is not a super admin** |
| **29** | **Where does a change to the gate first execute?** | Today: as the production credential holder, against the production tenant. Group-family writes have no containment but the code under test. | Offline harness by default; a second robot scoped to the sandbox OU with no customer-scoped Reader, in Wall-E's project (`WALLE_PROJECT`). A separate tenant only if F3/F3b autonomy is wanted. | Before Stage 1's first write; the tenant sub-question before any F3/F3b cell leaves L1 |
| **30** | **Control-plane durability: RPO, RTO and the restore protocol** | A restore silently rolls back halts, overrides, nonces, dedup records and counters. | PITR, delete protection and daily backups at Phase 7; a restored control plane starts at `halt_all` and is reconciled against BigQuery before it resumes. | Before Phase 7 completes |
| **31** | **Evidence durability and retention** | `walle_audit` is inside teardown's blast radius, recreation destroys undelete, and grades live only in Firestore. | Write-ahead grades to BigQuery and teardown guards now; an off-project copy at Stage 1 — Eve's `walle_audit` mirror in `EVE_PROJECT` is the natural candidate (decision 51, [../project-topology.md](../project-topology.md)). Moves [decision 17](09-open-decisions.md) earlier and makes it a minimum *and* a maximum. | Before Stage 1 |
| **32** | **Do fully pinned T1/T2 playbooks need a model at all?** | Everything the model would decide is already pinned; keeping it there carries the A3/A11 class and all the platform churn. | Deterministic by default with a typed predicate; `requires_model` per playbook by exception, entering at L0 and tainted. | Before S0 shadow evidence is collected |
| **33** | **Promotion and demotion statistics** | Point thresholds on 20–30 items promote a 90 % playbook about one time in five and demote an on-target one about one window in four. | Wilson interval gates with hysteresis; `unsure` reported separately. The gate forces the sample floor up and cannot be decided apart from it: at n = 30 even a flawless record gives a Wilson 95 % lower bound of 0.886, so [05](05-autonomy-ladder.md) §7's "≥ 30 proposals graded per family" must rise to ≥ 35 or no cell is ever promotable. | Before the first item is graded |
| **34** | **Eve is a deterministic verifier; no LLM produces an approval** | Already decided in [12](12-agent-identity.md) section 1.8 and contradicted in four other pages. Eve's designer will inherit whichever version they read. | State it in 01, 05, 06 and 08. Until an Eve design record exists, "Eve v0" is BigQuery scheduled queries read by a human. | Now for the wording; before S3 for the design record |
| **35** | **Who may receive per-person reporting output?** | `walle-readers@` is specified on the write axis only, and there is no aggregate-only operation to give a non-admin. | Answer inside [decision 8](09-open-decisions.md): aggregate-only family with a minimum cell size (`Assumption:` 5), or no readers beyond admins. | Before the first reader is onboarded |
| **36** | **What does Stage 0 actually provision?** | Phase 15 and the KMS key are Eve's, provisioned in `EVE_PROJECT` by Eve's setup (2026-09-13); what Wall-E's Stage 0 could still provision early — the `eve-controller@EVE_PROJECT` allowlist entries, the cross-project bindings on Wall-E's resources, and `walle-events` — has no consumer; a consented Eve token dies after six months unused. | Stage 0 provisions what Stage 0 uses; seams stay in code as contracts, audit columns and a CI-only stub caller. | Before Phase 1 |
| **37** | **Second pair of hands during the build (splits [decision 11](09-open-decisions.md) into 11a)** | Separation of duties, the external validator and credential recovery all need another person before Phase 10, not before S1. | Name a security reviewer with code ownership on the ceiling module, policy chain, catalogue and validator; a validator custodian; and a second person trained and witnessed on the Phase 9 re-bootstrap. | Before Phase 10 |
| **38** | **Value baseline and stop rule** | No baseline, no stop rule, and a cost table missing its largest line — human time. | Measure four weeks of baseline toil before Phase 1; dated stop-or-continue review at S1 exit. | Baseline before Phase 1; review at S1 exit |
| **39** | **Robot account lifecycle: detection, custody and rebuild** | No detection of another administrator acting on the robot, no paging class for a removed role assignment, no rebuild path past the 20-day deletion window. | Activity rule (Google's current name for a reporting rule) on admin events targeting the robot; `role_assignment_missing` as a paging class; second vault custodian; rebuild checklist. | Before S0 opens |
| **40** | **Google-side contract drift probe** | Two dependencies fail silently on the autonomous path: the admin audit event names the playbook `trigger` fields key on, and the robot's actually-assigned privilege set for reads other than the admin enumeration. Loud breaks, such as a renamed privilege returning 403, are already caught by the closed error enum, verification and the breaker. | Extend the existing daily drift job: privilege-name and event-name diffs set `no_autonomous`; discovery-revision bumps are informational and freeze promotions. No SKU diff — Google renames SKU display names while the ids stay stable, and the Licensing API takes ids ([C54](#c54--google-side-contract-drift-is-watched-for-model-armor-but-not-for-the-workspace-apis-stands)). | Before Stage 1 |
| **41** | **Single region, accepted** | Everything but BigQuery is in one region and nothing records that as a decision. | Accept, with RTO equal to Google's regional recovery, because multi-region would cost a residency analysis and duplicated engines for a system that is not business-critical. | Record now; non-blocking |

## Residual risks knowingly accepted

These are not defects to fix. They are things this review could not settle, or settled
against the challenger, and they are recorded so nobody assumes otherwise.

| Risk | Why it is accepted | What bounds it |
|---|---|---|
| **This was a machine-run review** | It is cheap, thorough on contradictions, and available before a human reviewer is. It is not accountable for the tenant. | Every finding names its evidence and its document. Nothing here is sign-off. |
| **Two challenges cannot be closed until the pilot OU is sized** | C19 and C27 both turn on whether volume gates bind before the stage floors, and [decision 5](09-open-decisions.md) leaves the account count `tbd`. | Decision 5 must record an absolute number and expected monthly items per family before S0 opens. Until then both verdicts are provisional. |
| **The `walle-actions` single point remains** | Decomposing it is [decision 18](09-open-decisions.md), due before Stage 4. Splitting it now would delay every other control. | The asymmetric Eve key, a genuinely create-only plan store (C5) and the per-endpoint allowlist are the minimum that make it survivable. C5's fix is the part that must land early. |
| **The cross-project grants Wall-E's owner makes into and out of `WALLE_PROJECT`** (rewritten 2026-09-13; previously "Eve's trust root stays inside Wall-E's project through the pilot") | Eve's trust root — key, secrets, evidence mirror, jobs — is in `EVE_PROJECT` from the first commit ([../project-topology.md](../project-topology.md)), so the original residual is gone. What remains is the set of resource-level grants that cross: `run.invoker` on `walle-actions` and dataset-level `dataViewer` on `walle_audit` for Eve's and Mo's identities, `walleEngineQuery` on the engine for the app's service agent, and the optional `publicKeyViewer` on `eve-approval` — and the fact that whoever can edit `WALLE_PROJECT`'s IAM can rewrite the first three. | The pilot is capped at L3, where Eve gates nothing. Every crossing is a named row with a drift check in the resource's project; no foreign principal holds a project-level role in `WALLE_PROJECT` (decisions 43 and 44 close the two that did); and the one grant that could be forced project-wide, decision 42's fallback, is a recorded exception rather than a default. |
| **A compromised action service can still launder a forged trigger** | Fixing the topic-level bindings (C7) does not help against an attacker who already holds the credential — such an attacker can call the Admin SDK directly. | The value of the fix is against a bug, a project Editor and the A5 loop, not against total compromise. The trigger corroboration against Google's own copy is what narrows the laundering path. |
| **Human attribution for T0 chat rests on a record the action service writes** | Acting as the requester was considered and rejected for good reasons: it makes every operator's own privileges the ceiling and is the wrong identity for admin operations. | Enabling IAP Data Access logs makes the **approver** recoverable from a Google-written record. The T0 chat requester is not, and that is a stated cost (C43). |
| **The catalogue will never cover a human admin's long tail** | The limit is the identity, not the design. No architecture reachable without DWD closes it. | Band C work gets a handoff-and-verify lane (C35) rather than a pretence of coverage, and `capability_gap` records make the demand visible (C22). |
| **Irreversible operations are a matter of degree** | The non-goal says Wall-E does nothing it cannot undo; a sent mail and a Chat message are not undoable, and both sit in the catalogue. | The ceiling table, not the non-goal, is what the service enforces. C36 requires the two to be reconciled in writing rather than reconciled by the reader. |

## Reopen when

This challenge should be re-run, in whole or in part, when any of these becomes true.

| Trigger | Re-run |
|---|---|
| The decision-26 spike returns a result | The whole credential chapter. C1, C4, C6, C9, C21, C32, C33, C47 and [decision 3](09-open-decisions.md)'s framing were all judged on the premise that admin scopes freeze at the robot's consent. A keyless service account changes that premise for every admin API. |
| [Decision 5](09-open-decisions.md) records an absolute pilot-OU account count | C19 and C27, which cannot be settled without it, and the S0, S2 and S3 exit criteria that depend on those volumes. |
| A second operator is added, or the first non-super-admin operator is added | C41 and C8. Both are latent today only because the rota is one super admin. |
| The agent is shared with `walle-readers@` | C42 and decision 35. The disclosure is latent until that act and live immediately afterwards. |
| An Eve design record exists | C10, C11, C12, C13, C14, C16, C30, C34 and C39. Everything about Eve in this review is judged against an Eve that has no design. |
| Any F3 or F3b cell is proposed to leave L1 | C50's tenant sub-question. Workspace cannot OU-scope group privileges, so that is the moment containment runs out. |
| Google ships an Admin console Gemini panel that can act, or a no-code flow that runs as a non-user principal with admin privileges | The alternatives table, and C31 in particular: single-object T0 writes would become redundant. |
| An identity-provider deprovisioning connector is found or installed | C24 and [decision 13](09-open-decisions.md). Suspension should then belong to the connector, with Wall-E doing the cleanup. |
| The pinned model is retired, the ADK line has a breaking release, or the Model Armor filter version changes | C15. Evidence earned on the old platform tuple should not carry forward silently. |
| Agent Gateway's `europe-west1` availability is confirmed or denied | C29 and C37, and [decision 21](09-open-decisions.md). |
| Cost exceeds the completed estimate by a factor, or the S1 stop-or-continue review is due | C28 and C34. |
| Any severity-1 event, or the first automatic demotion later judged false | C18 and C19: if the statistics were not fixed, this is what a false demotion looks like. |

## Sources

Google documentation read on 2026-09-11 by the review lenses, and the following re-verified
on 2026-09-12 for this page:

- Assigning an admin role to a service account, including the exclusion of Super Admin:
  `https://knowledge.workspace.google.com/admin/users/assign-specific-admin-roles`
- Service accounts with Google Groups APIs without domain-wide delegation:
  `https://workspaceupdates.googleblog.com/2020/08/use-service-accounts-google-groups-without-domain-wide-delegation.html`
- Refresh token expiry — six months unused, 100 tokens per Google Account per OAuth client,
  and password change with Gmail scopes: `https://developers.google.com/identity/protocols/oauth2`
- Agent Gateway supports Gemini Enterprise in egress mode only; ingress traffic is not
  supported: `https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/gateways/agent-gateway-ge-deploy`
- Agent Gateway overview and Agent Runtime ingress/egress modes:
  `https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/gateways/agent-gateway-overview`
- Supported locations for agents — consulted for Agent Gateway in `europe-west1`, which could
  not be confirmed from the page and remains `tbd`:
  `https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/agent-locations`
- Firestore point-in-time recovery, scheduled backups and in-place restore:
  `https://docs.cloud.google.com/firestore/native/docs/use-pitr`,
  `https://firebase.google.com/docs/firestore/backups`,
  `https://firebase.google.com/docs/firestore/restore-in-place`
- Cloud KMS audit logging, for matching accepted Eve approvals to Google-written signing
  records: `https://docs.cloud.google.com/kms/docs/audit-logging`
- IAP audit logging, for recovering the approver from a Google-written record:
  `https://docs.cloud.google.com/iap/docs/audit-log-howto`
- Cloud Run tagged zero-traffic revisions and per-revision minimum instances:
  `https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration`
- Administrator privilege definitions, including privileges that cannot be limited to
  organisational units: `https://knowledge.workspace.google.com/admin/users/administrator-privilege-definitions`
- Gemini Enterprise agent schedules run on the creator's user credentials, which expire
  every 14 days, and cannot act on other people:
  `https://docs.cloud.google.com/gemini/enterprise/docs/agent-designer/schedule-agent`
- Workspace Studio flows continue to run with the user's identity, least-privileged, with no
  credential-expiry statement on the page:
  `https://workspaceupdates.googleblog.com/2026/08/new-enterprise-security-controls-for-Workspace-Studio-enable-expanded-collaboration-use-cases.html`
