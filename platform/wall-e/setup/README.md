# Wall-E setup automation

Executes [SETUP.md](../SETUP.md), the 18-phase runbook, as far as a script
honestly can. SETUP.md is authoritative: where it and ARCHITECTURE.md disagree,
this follows SETUP.md, and the disagreements are listed at the bottom of this
page.

**It stops at Stage 0, and no autonomous write is possible when it finishes.**
Every write family is at L1 (shadow) on chat and scheduled triggers and L0 on
event and inbox triggers, the daily write budget is 0, and the custom admin role
this creates contains no write privilege at all. The Stage 1 write role is
created and assigned to nobody, so even a total failure of every control in the
action service leaves Workspace refusing the call at Google's end. Assigning it
needs a dated decision record, not a command.

## Run it

```bash
cp walle.env.example ~/.walle-env && $EDITOR ~/.walle-env   # fill in every <...>
./walle preflight            # tools, permissions, config, manual step list
./walle workspace            # phases 1 and 2
./walle gcp                  # phases 6, 7, 8
./walle consent              # phase 9   — the one interactive step
./walle consent --eve        # phase 15
./walle deploy               # phases 10, 11, 12, 14
./walle register             # phase 13
./walle triggers             # phase 16
./walle verify               # every invariant, as a pass/fail table
./walle denials              # phase 17
./walle stage0               # phase 18 — verify, attest M10, resume the schedules
```

The global flags work **before or after** the subcommand: `walle gcp --config X
--yes` and `walle --config X --yes gcp` are the same command.

`--dry-run` issues read-only probes only — no mutating command, no Admin SDK
write, and the two checks whose *probe* is itself a write (the Workspace
`users.update` probe and the BigQuery `DELETE` probe) return `SKIP` rather than
running. `--yes` skips confirmations on writes **this script makes**; it can
never attest a manual console step, which always blocks for a human. `--verbose`
shows command output, except where that output is a secret. `./walle status`
prints where the build actually is, which is what you want after an
interruption.

`./walle rollback --phase N` undoes one phase (2, 9, 10, 11, 12 or 14) rather
than everything. Phase 14's rollback pauses every playbook job but deliberately
leaves `walle-gmail-watch-renew` running: pausing it as collateral damage
produces SETUP.md §7.6 exactly — no T3 runs, no errors, everything looks healthy
while the Gmail watch quietly dies.

The config is validated **per subcommand**, against only the keys that
subcommand uses, and a refusal names which subcommands want the missing key.
`walle gcp` does not need `OPERATOR_OAUTH_CLIENT_FILE` or `SANDBOX_ACCOUNTS`.

Every subcommand is independently re-runnable: each create is a get-or-create,
and nothing is deleted outside `teardown`, which makes you type the project id.
Fill `~/.walle-env` in as each phase produces a value — `PROJECT_NUMBER`,
`REFRESH_TOKEN_VERSION`, `ACTIONS_URL`, `DISPATCHER_URL`, `ENGINE_ID` — because
a missing value expands to an empty string and produces a deployed resource that
is wrong rather than a command that fails.

Phases 10 to 14 need the Wall-E repository at `WALLE_REPO` (schemas, the two
service sources, `agent/deploy.py`, `config/ladder.yaml`,
`config/deploy_ladder.py`, `tests/denials.py`). Phases 1 to 8 do not, and doing
them early surfaces the tenant surprises while the code is being written.

## What it cannot do, in the order you meet it

Each of these prints an exact ordered instruction block, blocks until you
confirm, and is verified afterwards where an API can see the result. The block
is not a `[y/N]`: it asks you to type the step's identifier, and **`--yes` does
not satisfy it**. `--yes` covers writes this script makes; it must never record
that somebody created a reporting rule or registered a security key. A step with
no verifier (M3, M5, M6, M10) is therefore the only thing standing between
`--yes` and a build log describing work nobody did.

| # | Phase | Manual, because | Verified afterwards |
|---|---|---|---|
| M0 | addition | This script needs its own OAuth client to reach the Admin SDK as you. SETUP.md does phases 1 and 2 in the console, so it never needs one. It must never be the robot's client: one client, one token. | yes, the file is read |
| M1 | 1 | The account passwords. This script never prints or writes a secret, so it creates accounts with a random password it forgets. You set the real one in the console and it goes straight to the vault. | partly: recovery email and phone absence |
| M2A | 3 | Security-key registration, on its own. Prompted by `walle workspace`. | yes, `isEnrolledIn2Sv`, **before M2B is printed** |
| M2B | 3 | 2SV enforcement, security key only, scoped to the service OU. Split from M2A because the order matters and only a split step makes it enforceable: enforcing hardware-key-only on an account with no key registered locks it out permanently, and by then every fallback is gone. | yes, `isEnforcedIn2Sv` |
| M3 | 4 | The login reporting rule, under **Rules**, not Alert Center. The Alert Center API needs domain-wide delegation, which this design does not do, anywhere, ever. | **no API exists.** Check by eye |
| M4 | 5 | "Share data with Google Cloud services" is a tenant-wide console toggle. Prompted by `walle workspace`, not `walle deploy`: SETUP.md puts Phase 5 before Phase 6, the toggle takes up to 24 h to produce rows, and the login half must be resolved before Phase 9. | yes, by querying the org-level log for both `admin.googleapis.com` and `login.googleapis.com`. Neither log visible yet is `SKIP` (probably enabled less than 24 h ago); one visible and one missing is a failure |
| M5 | 9 | The OAuth consent screen and the OAuth client are console objects. Internal + In production, or refresh tokens expire after seven days. | **no** |
| M6 | 9 | Marking the client Trusted in API controls. The Gmail scopes are "restricted" and your tenant's own API controls can cut an untrusted client off weeks later, with an error that looks nothing like the cause. | **no** |
| M7 | 9 | The consent itself is interactive by design. The script drives it but **prints the URL and waits**: a desktop OAuth flow opens the machine's *default* browser, which is signed in as you, and the grant then lands on a super admin with none of the role constraints. That is SETUP.md §7.1, the most likely single mistake in the runbook. The script calls `userinfo` afterwards and refuses to store the token if the account that consented is not the robot. | partly: the consent flow itself checks the account through `userinfo` and the exact scope set, and prints the version number. The manual block is operator-attested |
| M8 | 13 | Gemini Enterprise agent registration. The REST surface for it is `v1alpha` and its shape is not stable, so SETUP.md's console steps are what this prints. | yes where the alpha listing answers; otherwise it says it cannot |
| M9 | 16 | A monitoring notification channel. An alert policy with no channel is a dashboard. | yes |
| M10 | 18 | The Stage 0 decision record is a document, and writing it is the point. Printed by `walle verify` and gated by `walle stage0`. | no |
| — | 14 | Not a console step, but a human judgement the machine cannot make: after the forced shadow run, `walle deploy` asks whether the operator notification **actually arrived**. It is the one answer that proves `notify.operators` is really outside the ladder; if the report never arrives, F2-notify is back on the ladder at L1 and Stage 0 collects evidence nobody sees. | no |

## What `verify` asserts

Twenty-eight named checks, each pass/fail on its own, exit non-zero on any
failure. The security invariants among them: the agent service account can read
no secret and no KMS key, counting bindings inherited from the key ring and the
project; the Stage 0 role holds nothing beyond the resolved read set; the robot
holds **exactly one** role assignment, customer-scoped, and the Stage 1 write
role is assigned to nobody; the secrets are regional and the service pins a
version **number** that still exists and is `ENABLED`, never `latest`; the KMS
key is `ASYMMETRIC_SIGN`/`EC_SIGN_P256_SHA256` with Eve signing and the action
service holding only `publicKeyViewer` at every level; the action service cannot
delete BigQuery audit data; the Pub/Sub sink excludes the robot principal and
the BigQuery sink does not; exactly three principals can query the engine, and
no project- or organisation-level binding confers query on a fourth; the engine
runs as `walle-agent@` with `min_instances 0`, no Memory Bank and no Code
Execution; every playbook scheduler is paused and the watch-renewal job is
running; the ladder has no `notify.operators` family, has `ou_allowlist` in
`defaults`, stamps a `ceilings_sha` and reads `config_version 2026.09.0-1`; the
control caller allowlist holds the operators as well as Eve; and both Cloud Run
services require authentication.

One check asks Google rather than Wall-E: `no_robot_writes_at_google` queries
the organisation-level Workspace admin audit log for rows attributed to the
robot. That log records changes only, so any row is a write. It is the check
SETUP.md names three times (Phase 12 verify check 4, Phase 14's forced shadow
run, and the Stage 0 checklist), and every other write check here asks Wall-E's
own configuration.

**A check that cannot fail is worse than no check.** The two "the service
account is refused" proofs — the BigQuery `DELETE` and the refresh-token read —
first prove the operator can actually impersonate the account. Nothing here
grants the operator `roles/iam.serviceAccountTokenCreator` on `walle-actions@`
or `walle-agent@`, so on a normal run the *impersonation* fails with a message
containing "permission" and "denied" that reads exactly like the resource
refusing. Those checks now report `SKIP` with a loud INCONCLUSIVE message
instead of a green PASS on a broken system.

It also runs SETUP.md Phase 9's fourth check, the one people skip: it builds the
robot's credential from the pinned secret version, confirms the account, proves
a `users.list` succeeds, and proves a `users.update` against a **sandbox**
account is refused 403. At Stage 0 the role is read-only, so a write must fail
at Google's end; if it succeeds, the Workspace layer is not the second
enforcement point the design claims it is. That probe is the only Workspace
write `verify` ever attempts, it only ever names a sandbox account, it asks
first unless `--yes`, and it is skipped entirely under `--dry-run` — it is a
real Admin SDK write, and a robot-attributed admin event would also break the
Phase 18 checklist's "zero rows attributed to $ROBOT" box. (Phases 1 and 2 make
Workspace writes by design, and `teardown --include-workspace` deletes what they
made; `verify` is the subcommand this sentence is about.)

**One secret is written to disk, deliberately.** The robot's refresh token never
is: it goes from the token exchange straight into Secret Manager. The operator's
*own* OAuth token is cached 0600 at `OPERATOR_TOKEN_CACHE` so phases 1, 2 and 15
do not re-consent on every run. It is your own super-admin credential, it is
re-consentable at zero cost, and setting `OPERATOR_TOKEN_CACHE=""` disables the
cache entirely.

A check that could not run reports `SKIP`, not `PASS`. `--strict` makes skips
failures.

## Where this differs from the documents

- **SETUP.md Phase 10 says "all sixteen environment variables" and lists
  seventeen.** The script asserts the exact name set, not a count.
- **SETUP.md Phase 8's BigQuery `DELETE` check runs as the operator**, who is
  normally a project owner, so it succeeds and reads as a control failure that
  is not one. The script runs it impersonating `walle-actions@`, which is the
  only way it proves anything.
- **ARCHITECTURE.md §4.2 and §7.5 give the Cloud Tasks worker its own service
  account, `walle-tasks@`.** SETUP.md Phase 6 creates five service accounts and
  has `walle-actions@` call itself back. SETUP.md wins; the split is worth doing
  before Stage 4, alongside open decision 18.
- **ARCHITECTURE.md §4.2 says `walle-dispatcher@` never calls the action
  service.** SETUP.md Phases 10 and 16 give it `run.invoker` and make it the
  sole `INTERNAL_CALLER_ALLOWLIST` entry, because the Gmail watch renewal is a
  Scheduler job calling the action service as the dispatcher. SETUP.md wins.
- **ARCHITECTURE.md §7.5 says `GET /v1/ladder` is never reachable by the
  agent**; SETUP.md Phase 10 says any authorised caller. SETUP.md wins, and the
  narrower reading is worth adopting in the service: the effective matrix tells
  a steered model which family and trigger pair executes unattended right now.
- **Group access settings** ("only administrators can join, only members can
  post") are set through the Groups Settings API, which means
  `groupssettings.googleapis.com` is enabled on top of SETUP.md Phase 6's list.
  If the call is refused the script stops and prints the console steps.
- **SETUP.md §1.5 asks for Python 3.12.** This script is written to run on 3.9
  as well; on 3.9 `google-auth` prints an end-of-life warning, which is noise,
  not a fault.
- **The `--set-env-vars` delimiter is `;`, not `@`.** SETUP.md carried `^@^`
  and this script copied it. That cannot work: `gcloud topic escaping` requires
  the delimiter to appear in no value, and eight of the seventeen values are
  email addresses, so gcloud split `ROBOT_ACCOUNT=walle-bot@example.com` in two
  and aborted with `Bad syntax for dict arg`. Both documents now say `^;^`, and
  the script validates names *and* values against it.
- **There is no `gcloud ai reasoning-engines` command group**, in GA, beta or
  alpha. Listing engines, the three-principal IAM lock, `getIamPolicy` and the
  engine delete all use the Agent Runtime REST API on
  `$REGION-aiplatform.googleapis.com`, which is the escape hatch SETUP.md
  Phase 12 already names.
- **Notification channels are `gcloud beta monitoring channels`**, not
  `gcloud monitoring channels`, which does not exist. `gcloud monitoring
  policies` is GA and is used as-is. SETUP.md is corrected to match.
- **Phase order.** `deploy` runs phases 10, 11, 12 and 14, and `register` runs
  13, so 14 lands before 13. Nothing depends on the order, but SETUP.md Phase
  13's verify distinguishes the pre-14 denial reason `control_plane_unavailable`
  from the post-14 `level_off`; after this reordering only `level_off` is
  observable, which is the reason SETUP.md wants it recorded either way.
- **Eve's admin role is created in `workspace`, not `consent --eve`.** SETUP.md
  puts it in Phase 15 ("repeat phases 1, 2, 3 and 9"); doing it alongside
  Wall-E's roles means one pass over the privilege catalogue and one console
  sitting. `consent --eve` still does Phase 15's credential half.
- **The floor list carries the two robot accounts**, which SETUP.md Phase 1
  step 5 does not ask for. Denial test 17 requires a write targeting `$ROBOT` or
  anything in `$SVC_OU` to be refused as `protected_principal`, so the runtime
  protected set has to cover them. Deliberate, and wider than the runbook says.
- **Write privileges are classified by an allowlist, not a denylist.** A
  substring denylist misses `USERS_ALL`, `GROUPS_ALL`,
  `ORGANIZATION_UNITS_ALL`, `ADMIN_APIS_ALL`, `SUPER_ADMIN` and `USER_SECURITY`
  — the whole-service and total grants, none of which carries a write-shaped
  marker. Anything not on the resolved Stage 0 read list counts as a write.
- **A pre-existing admin role with different privileges is a refusal**, not a
  warning. `ensure_role` used to warn and then hand the role to `phase_2_roles`,
  which assigned it to the robot customer-scoped.

## Not implemented

- **Phases 17 and 18.** The 52-test denial suite and the kill-switch drill are
  the repository's `tests/denials.py` and `drills/record.py`; `walle denials`
  runs the suite between the `min-instances=2` and `min-instances=0` updates that
  make test 27 meaningful, and adds five infrastructure denials of its own
  (tests 1, 2, 7, 9 and 52) that can be proved at Google's end. K0 to K5 are
  measured by a human with a stopwatch, which is the point of a drill.
- **`ladder.yaml` is linted textually, not parsed.** No YAML library is in the
  dependency set. The authoritative check is `GET /v1/ladder` on the deployed
  service, in `verify`.
- **Phase 12's agent deploy** delegates to the repository's `agent/deploy.py`,
  passing `WALLE_ENGINE_NAME` so it can call `update()` instead of `create()`.
  The script counts engines before and after and fails loudly if a second one
  appears, which catches a `deploy.py` that ignores the contract.
- **The licence probe from Phase 9's verification.** SETUP.md asks for one
  `licensing.licenseAssignments.listForProduct` call with the robot's credential,
  expecting 403 because License Management is indivisible and is withheld until
  Stage 1. It is one call and it closes "still to verify" item 1 in
  [09-open-decisions.md](../09-open-decisions.md). It is not implemented here,
  but `walle consent` now prints the exact command at the one moment it is
  cheap — while the credential is in hand — and records a note to carry the
  answer into the build log. If it returns rows, the Phase 2 role carries a
  privilege it should not.
- **The runbook's remaining behavioural verify steps.** Phase 12's smoke
  tool-count match, Phase 11's verify steps 1, 2, 4 and 5, and the K0–K5
  stopwatch drills are still done by hand from SETUP.md. Phase 13's
  `principal_id` gate, Phase 14's forced shadow run with the
  notification-arrival question, Phase 16's steps 1 to 3 (step 3 behind
  `walle triggers --drill-watch-alert`) and Phase 17's check 48 are implemented.
  Several of the unimplemented ones are Stage 0 exit criteria in §6.1.

## Checking the script before you trust it

`selftest/selftest.sh` exercises the script with no credentials, no project and no
network. It puts stubs for `gcloud`, `bq` and `gsutil` on the path, records every
invocation, and asserts the properties that must hold before this runs against a real
tenant:

- an unedited config is refused, and nothing runs
- `--dry-run` issues no mutating command, only reads
- global flags work before or after the subcommand
- the corrections that were expensive to find are still in the emitted commands: no
  `--paused` on scheduler create, no non-existent role or command group, regional
  secrets, an asymmetric key for Eve, project roles on the service accounts
- the Cloud Run environment flag survives email-shaped values, which is the bug that
  would otherwise have stopped the first deploy

```bash
cd setup/selftest && ./selftest.sh
```

Run it after any change. Sixteen checks, and they should all pass.
