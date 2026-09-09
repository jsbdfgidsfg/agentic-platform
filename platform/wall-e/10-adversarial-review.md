# 10. Adversarial review

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-09
- Two independent reviews of the design as written, 2026-09-08: an **adversarial pass**
  (17 attacks) and a **consistency and fact pass** (contradictions between documents,
  guardrails with no mechanism, and every Google Cloud and Workspace claim checked against
  current documentation)

The design was attacked before being built. Seventeen attacks survived the first
draft; the ones that mattered changed the design, and the changes are in the numbered
documents. This page records what was attacked, what changed, and what is knowingly
accepted, so that nobody re-derives it and nobody assumes a control works because an
earlier draft said it did.

## Claims the first draft made that were not true

Each of these was stated somewhere in documents 01 to 09 and was wrong. They are listed
plainly because a design that quietly corrects itself teaches nothing.

| Claim | Where | Why it was false | Now |
|---|---|---|---|
| "The model cannot self-authorise" | 06, 05 R5 | The flow had the **agent** posting the approval and naming the approver. The service could verify the named person was an operator, never that they had said yes. | Fixed — see A1 below |
| Eve's approval is independent of Wall-E | 02, 08 | The runbook generated a **symmetric** key readable only by Eve, so the action service could not verify it at all. The natural fix — sharing the key — destroys the property. | Fixed — asymmetric KMS key |
| Trigger class bounds injection risk | 05 §3, 06 N5 | Trust was attached to *how a run started*, but injection arrives with *what a run reads*. A scheduled run reading a hostile group name has a WRITE_HIGH ceiling of L4. | Fixed — taint tracking |
| "There is no query-shaped write" | 03 | True of the write, false of the **selection**, which is what chooses the targets. Caps turned a mass action into a drip, not into a refusal. | Fixed — pinned selection |
| "A T2 run may not emit an event that starts another T2 run" | 05 §3, 06 | The runbook's log sink filter had no actor exclusion, so every write by the robot was a trigger. | Fixed — filter, cooldown, depth |
| Protected principals fail closed | 06 N7 | The admin enumeration runs under an **OU-scoped** role, so it returns admins inside the pilot OU — often none — and an empty result read as success. Nested groups were invisible. | Fixed — floor assertion |
| OU move cannot change security posture | 06 N1 | In Workspace the OU **is** the carrier of policy, and nothing validated the destination. | Fixed — own operation, destination allowlist |
| "Approval consumed in the same transaction as the execution" | 03 | No transaction spans Firestore and an Admin SDK call. Unbuildable as written. | Fixed — consume first, reconcile |
| Verify-by-re-read catches wrong writes | 05 R6 | It verifies the **effect**, never the **premise**. A correct write on a stale justification verifies clean. | Fixed — full policy re-run |
| "Last write at 16:00 so a human is still around" | 03 | Deferring a hold past the window moved the batch to 08:00 the next morning, with nobody watching. | Fixed — expire, never defer |
| K4 stops a running instance | 04 | The credential secret was read from `versions/latest`, which falls back to the previous **still-valid** version when the newest is disabled. | Fixed — pinned version, self-revoke |
| CI enforces the ceilings | 05 §10 | One pull request could change the ladder, the ceilings and the validator together, and CI validated them against each other. | Fixed — separate ownership |

## The attacks, and what each one changed

Severity is the damage if the design had been built as first written.

| # | Attack | Severity | Change made |
|---|---|---|---|
| A1 | Injected text in an audit row persuades the agent to post its own approval; the service checks the named human is an operator, not that they consented | **Critical** | Approval endpoint refuses the agent's service account outright. Human approval arrives out of band, carrying an identity the service verifies itself. [03](03-lld.md), [04](04-flows.md) Flow A |
| A2 | Eve's symmetric key must be shared with the action service for verification to work, so "Eve approved" becomes forgeable by the service | **Critical** | Cloud KMS asymmetric signing key. Eve signs, the service verifies with the public half and can never mint. Eve signs a hash it computed itself. [02](02-identity-and-auth.md), [07](07-build-runbook.md) |
| A3 | Attacker-authored group names, profile fields and audit parameters reach the model on a **scheduled** run, where ceilings are high | **Critical** | Per-run taint bit. Any attacker-writable field reaching the model forces the inbox ceiling for that run. [03](03-lld.md), [05](05-autonomy-ladder.md) §4 |
| A4 | Firestore outage; halt read throws, override read defaults to "no override", so every demoted family silently returns to its configured level | **Critical** | Any control-plane read failure denies and trips the breaker. Overrides fail to L0, never to L5. Halt epochs on every audit row. [03](03-lld.md) |
| A5 | Wall-E's own writes match the log sink filter, so each write triggers a run that writes again | **High** | Sink excludes the robot's principal, plus a per-principal 24-hour cooldown and a causation depth limit, which also closes the system-attributed second hop. [07](07-build-runbook.md) |
| A6 | Cloud Scheduler's attempt deadline expires during a long run; the job retries and produces duplicate runs and duplicate proposals | **High** | Dispatcher acks within a second and hands off to a queue. Deterministic trigger ids make the dedup transactional. Stale triggers dropped. [01](01-hld.md), [03](03-lld.md) |
| A7 | Admin enumeration under an OU-scoped role returns nothing; nested `super-admins@` inside the protected group protects the group's address, not its members | **High** | Transitive membership expansion, plus a committed floor list of known admins that the computed set must cover, or every directory write is denied. [03](03-lld.md) |
| A8 | A group innocently classified `low` is transitively inside `walle-operators@`; one membership write grants approval authority **and** access to the agent | **High** | Classification computed from the transitive closure, not declared. Agent access and approval authority split into two groups. [02](02-identity-and-auth.md), [03](03-lld.md) |
| A9 | An OU move sends a user to an OU with weaker 2SV and sharing policy, and out of Wall-E's own allowlist so the move cannot be undone | **High** | Its own catalogue operation with a separate destination allowlist, and a CI assertion that destinations are a subset of the family's scope | 
| A10 | A human restores a user between plan and approval; the membership pre-state is unchanged, so removals execute on an active account and verify clean | **High** | Every operation declares the pre-state fields its policy checks read. The **whole policy chain** re-runs per item, not a field compare. [03](03-lld.md) |
| A11 | The playbook pins the selection *operation*, not the *query*, so an injected query selects a whole OU one daily budget at a time | **High** | The query string is pinned and hashed into the playbook version. Novelty caps over 7 and 30 days. Budget saturation is itself an alert. [03](03-lld.md) |
| A12 | The item loop runs inside the approve request and exceeds Cloud Run's default timeout, leaving a half-applied plan with no terminal state | **High** | Approval releases the plan and returns immediately; a queue worker executes one item at a time. Nonce consumed before the call, with a reconciler against Google's own audit log. [03](03-lld.md) |
| A13 | Repeatedly suspending a test account makes runs collide and fail, tripping the breaker; the ratchet then keeps the family off for a week, twice, then permanently | **Medium-high** | Outcomes classified: an operation whose desired state already held is a no-op, not a failure. The breaker needs distinct error classes. Per-target leases stop collisions. [05](05-autonomy-ladder.md) §9 |
| A14 | An attacker times the triggering event so every hold expires past the window and the batch runs next morning unattended | **Medium-high** | Plans that cannot complete inside today's window are refused at plan time. All arithmetic in UTC. Approval TTL capped in wall-clock as well as business hours. [03](03-lld.md), [04](04-flows.md) |
| A15 | Google's error text echoes an attacker-set display name back into the model as a **system** message, which models are primed to obey | **Medium-high** | The service never returns upstream text. Errors are a closed enum plus an audit id. Attacker-writable strings are canonicalised before reaching a model or an approval card. [03](03-lld.md) |
| A16 | Disabling the newest secret version makes `versions/latest` resolve to the previous, still-valid token, so the kill switch does nothing | **Medium** | The version number is pinned in config. K4 is replaced by the service revoking its own refresh token at Google, which is instant and needs nobody. [02](02-identity-and-auth.md), [04](04-flows.md) |
| A17 | One pull request changes the ladder, the ceilings and the CI validator together and passes its own gate | **Medium** | Separate ownership on the ceiling module, the policy chain and the validator, enforced as a required check the pull request cannot modify. The running service stamps its ceiling hash on every row. [05](05-autonomy-ladder.md) §10 |

## Accepted risks

Named so they are decisions rather than oversights.

| Risk | Why it is accepted | What bounds it |
|---|---|---|
| An injection can still cause a **proposal** to appear in the operator queue | Removing it would mean never reading tenant data, which is most of Wall-E's value | It is visible, attributed, and cannot execute. Proposal precision is a tracked metric |
| A compromised Eve can approve within the current level's blast radius until the next sampled review | Full independence would need a second implementation of the policy engine | Hold windows, vetoes, per-run caps, and Eve's inability to raise a level |
| Workspace audit logs land in Cloud Logging at organisation level, and their storage region is not selectable | It is the only credential-free event source, and it is what makes Eve's verification independent | Documented for the data-protection assessment rather than worked around |
| The recovery path is slower than the failure path: suspension can reach L4, restore is capped at L3 forever | Re-granting access is a security decision | A batch rollback primitive means one human approval undoes a whole run, not N |

## What the consistency pass found

The adversarial pass asked "how do I break this". The second pass asked "does this build,
and is it true". It found a different and equally serious class of problem.

### Things that could not have been built as written

| Finding | Why it mattered |
|---|---|
| **Operators had no credential path at all.** `run.invoker` was granted to three service accounts and no human | Nobody could halt, demote, veto or approve. Every kill-switch timing in the design was unmeasurable because the switch was unreachable |
| **Cloud Run IAM is per service, not per path** | The promise that the agent "has no IAM on the control endpoints" was false as built — one grant covers every endpoint. It now needs an in-app allowlist, and ideally a second service |
| **The custom admin role cannot be sliced as described.** There is no standalone suspend privilege, and licence management has no read-only half | Granting profile editing at Stage 1 unavoidably grants suspension; granting "licence read" at Stage 0 would have granted assign and revoke during the read-only stage |
| **Organisational-unit scoping breaks Stage 0.** Groups and Reports privileges cannot be unit-scoped, and every Stage 0 report is tenant-wide | The design needs two role assignments, not one |
| **A missing scope.** Group classification depends on knowing which groups carry an admin role, and the frozen scope list had no way to read that | Scopes freeze at consent, so this would have been discovered after the one irreversible step |
| **Stage 0's zero write budget denied every shadow item** | The budget check runs before the level forces a dry run, so the stage whose entire purpose is generating evidence would have generated none |

### Contradictions between documents

The catalogue's families did not match the ladder's, and the mismatch would have made
free-text mail autonomous on a schedule — the one thing the outbound rule exists to
prevent. Stage 0 was described three different ways across two documents. A
protected-principal denial had three different blast radii, one of which halted the
programme for a month when an operator asked about an admin in chat. One flow was labelled
with a stage whose level cannot execute. Rollback needed three different approvals
depending on which page you read. Budgets went 50, then 10, then 25 as autonomy widened.

### Facts that were wrong

| Claim | Correction |
|---|---|
| Cloud Scheduler cannot call the agent directly | It can — it supports OAuth tokens precisely for Google API targets. The dispatcher is still right, for the two other reasons |
| Agent Identity is unverified | Generally available since April 2026, with its APIs GA in August. A build decision with a published answer |
| A Chat app is optional | Under user authentication the Chat API sends **text only**. The one-click approval and veto cards this design assumes need app authentication |
| The login alert is created in Alert Center | It is a reporting rule under Rules, and its availability depends on the edition. This is the highest-value control in the design, so the page matters |
| Secret Manager user-managed replication gives residency | Regional secrets are the current mechanism; replication pins only the payload at rest |
| Model Armor must live in agent code | Agent Gateway integration is GA and covers ADK on Agent Runtime, and floor settings apply with no code change. Both are better, because Wall-E's own code cannot switch them off |
| Disabling the credential secret is a kill switch | `versions/latest` falls back to the previous valid version, and an issued access token lives up to an hour regardless |

### Guardrails that had no mechanism

Named in the enablement plan, enforceable by nothing: the canary sampler, the
consecutive-failure breaker, drill-date storage that CI could read, the proposal queue,
shadow grade capture, plan lifecycle state, per-trigger budgets, and the denial-reason
vocabulary that every metric and alert keys on. All now have storage and a definition in
[03](03-lld.md). The audit-completeness metric had nothing to query, because the Workspace
logs went only to a Pub/Sub topic; it needs a second sink into BigQuery.

## What was not attacked

This pass covered the design as written. It did not cover: the implementation, which does
not exist; Eve and Mo, which are not designed; your tenant configuration, which is
unknown; and the data-protection position, including that of employee representative
bodies where your jurisdiction has them, which is a legal question
and is [decision 8](09-open-decisions.md).

**The single structural weakness that remains.** Every control — the credential, the
policy chain, approval minting and verification, plan hashing, execution, verification
and the audit write — runs in one Cloud Run service. The three agents cannot collapse
into one, but the service beneath them was never decomposed, and the threat model has no
row for a compromised action service. The asymmetric Eve key and a create-only plan store
are the minimum that make that single point survivable. Splitting it further is worth
considering before Stage 4, and is [decision 18](09-open-decisions.md).
