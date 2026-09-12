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


Before the first subcommand, work through [PREREQUISITES.md](../PREREQUISITES.md): the roles,
licences, keys, tools, organisation policies and product preconditions this tool assumes are already
in place, with the check that proves each one. `./walle preflight` tests only a small part of that list.

## Run it

```bash
cp walle.env.example ~/.walle-env && $EDITOR ~/.walle-env   # fill in every <...>
./walle preflight            # tools, permissions, config, manual step list
./walle workspace            # phases 1 and 2
./walle gcp                  # phases 6, 7, 8
./walle consent              # phase 9   — the one interactive step
./walle consent --eve        # phase 15
./walle armor                # phase 12c — Model Armor, inspect-only; BEFORE deploy
./walle spike                # phase 12b step 3 — the Agent Identity spike; BEFORE deploy
./walle rollback --phase 12b #   then delete the throwaway spike engine
./walle deploy               # phases 10, 11, 12, 12b, 14
./walle register             # phase 13
./walle registry             # phase 13b — Agent Registry, egress gateway in dry-run
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

`./walle rollback --phase N` undoes one phase (2, 9, 10, 11, 12, 12b or 14)
rather than everything. Phase 14's rollback pauses every playbook job but deliberately
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

## The identity, Model Armor and registry phases (12b, 12c, 13b)

Three subcommands implement the chapters
[11-prompt-security.md](../11-prompt-security.md),
[12-agent-identity.md](../12-agent-identity.md) and
[13-agent-interconnection.md](../13-agent-interconnection.md), as SETUP.md
Phases 12c, 12b and 13b carry them. The gcloud invocations are SETUP.md's,
verbatim. The config keys they need are documented in `walle.env.example`
with the subcommand that validates each: `AGENT_IDENTITY_MODE`,
`AGENT_IDENTITY_SPIKE_RESULT`, `INGRESS_GATEWAY`, `EGRESS_GATEWAY`, `FOLDER_ID`,
`CI_DEPLOYER`, `MO_PRINCIPAL`, `MODEL_ARMOR_ENFORCE_DECISION`,
`CONTENT_LOG_RETENTION_DAYS` (default 30).

**`walle armor`** (Phase 12c, before the first `deploy`). Enables the APIs;
creates the `walle-content-logs` bucket, the `walle-content-sink` sink and the
`_Default` exclusion **before any template exists**, because the sanitize logs
carry raw prompts and personal data; creates the two templates with
`gcloud beta`, `--template-metadata-enforcement-type=inspect-only` and the
exact filter flags; imports the `walle-ingress` gateway; grants both the
Reasoning Engine and the Service Extensions service agents (the pages
disagree on which is needed; remove the unnecessary one after a block is
proved); writes `config/armor/walle-ma-ext.yaml` into `WALLE_REPO` with
`failOpen: false` and `timeout: 1s` and imports it; imports the
`CONTENT_AUTHZ` policy; sets the folder conformance floor and the project
inline floor with logging. Every create is a get-or-create. It ends by telling
you to set `INGRESS_GATEWAY=walle-ingress` so `deploy` binds the engine to the
gateway at creation. **`walle armor --enforce`** performs the blocking flips
(both templates to `inspect-and-block`, the project floor to
`INSPECT_AND_BLOCK`) and is refused unless `MODEL_ARMOR_ENFORCE_DECISION`
names an existing file: the Stage 1 decision record, decision 24.

**`walle spike`** (Phase 12b step 3, before the first `deploy`). Creates a
throwaway engine named `walle-spike` with `identity_type AGENT_IDENTITY`,
binds its principal as `run.invoker` on `walle-actions` (12b-a), asks it over
`streamQuery` to mint an ID token for `ACTIONS_URL` and call
`/v1/operations` (12b-b, 12b-c), and writes the three results, pass or fail
with raw output, to `AGENT_IDENTITY_SPIKE_RESULT`. It never writes a token:
keys containing "token" and any JWT-shaped string are redacted before the
file is written. The contract with `agent/deploy.py` is `WALLE_SPIKE=1`: deploy
a spike agent whose one tool, `probe_identity(audience)`, returns
`token_returned`, `status` and the decoded claims. `walle rollback --phase 12b`
deletes the engine and its binding afterwards; `deploy` refuses to run while a
spike engine still exists.

**`walle deploy`** now carries Phase 12b. `AGENT_IDENTITY_MODE` defaults to
`AGENT_IDENTITY`: no `service_account` is passed to `deploy.py`, the Reasoning
Engine service agent is **not** granted `serviceAccountTokenCreator` on
`walle-agent@`, `identity_type` and (when `INGRESS_GATEWAY` is set) the
`agent_gateway_config` are passed, and the four telemetry variables go through
the same `^;^` escaped list as Cloud Run, with
`ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false`. After the deploy the script reads
`spec.effectiveIdentity` back through the Agent Runtime REST API and **fails
unless it starts with `agents.global.org-`**; the principal is built from the
value read back, never typed. Then the four baseline grants, the two automatic
roles described and refused on `secretmanager.` or `setIamPolicy`, `run.invoker`
on the principal, and the `walle-deny-agents` deny policy (`--skip-deny-policy`
is the escape while its permission names are verified against the deny-policy
supported list, which the research did not do). `AGENT_IDENTITY_MODE=SERVICE_ACCOUNT`
is the gated fallback: refused unless `AGENT_IDENTITY_SPIKE_RESULT` names an
existing file, and a spike file whose verdict is `fail` refuses the identity
path too. Before anything mutates, `deploy` also enables
`agentidentity.googleapis.com`, **fails if `agentidentitycredentials.googleapis.com`
is enabled** (it disables nothing), sets the two service-account-key
constraints explicitly, and refuses an agent package that mentions
`GOOGLE_API_PREVENT_AGENT_TOKEN_SHARING_FOR_GCP_SERVICES` or does not pin
`google-auth>=2.45.0`.

**`walle registry`** (Phase 13b, after `register`). Enables the APIs; grants
`agentregistry.admin` to `CI_DEPLOYER` only and `viewer` to `eve-controller@`
and `MO_PRINCIPAL`; lists and describes the automatic `wall-e` entry and fails
if it lacks `RuntimeIdentity` or `RuntimeReference`; prints the registry-write
audit filter to commit and wire to the operator channel; imports the
`walle-egress` gateway; registers `walle-actions` as a `NO_SPEC` endpoint and
the essential platform endpoints with exact hostnames; writes the
`roles/iap.egressor` access policy for the agent principal and applies it per
endpoint; writes and imports the IAP request-authorization extension and
policy in `iamEnforcementMode DRY_RUN`. **It never registers `secretmanager`,
`firestore`, `admin.googleapis.com`, any Workspace host or `bigquery`**: a
registration naming one is a refusal, not a warning, and `verify` re-checks the
live registry. `walle registry --card PATH` registers the hand-written card and
refuses while any `supportedInterfaces` url contains `tbd` or names a
forbidden host, or while a skill id advertises a write, approval or control.

**What remains manual after these three.** Reading which method the Gemini
Enterprise caller actually uses (`query` or `streamQuery`) from the Agent
Runtime request logs during the first operator session, and recording it in
SETUP.md with the date. Capturing each operator's principal at their first
sign-in for the external-IdP case (12-agent-identity.md 5.2): only a session
produces it. Running the injection regression suite against
`walle-ingress-prompt` and recording `filterVersionConfig`. Proving a block and
the fail-closed behaviour (a wrong template name must error the caller), then
removing whichever service-agent grant proves unnecessary. Granting readers on
`walle-content-logs` (operators and IT security, nobody else). Verifying the
deny policy's permission names against the supported list. Keying the agent's
`EXEC_CALLER_ALLOWLIST` row on the claim the spike recorded. Lifting
`iam.managed.disableAccessPolicyBindings` if it is enforced. Flipping the
egress gateway from `DRY_RUN` to enforced after the shadow-playbook verify, and
the two undocumented questions that gate it. The SPIFFE-id equality on the
Gemini Enterprise agent page, and adding it to the drift job.

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

Thirty-seven named checks, each pass/fail on its own, exit non-zero on any
failure. The nine from Phases 12b, 12c and 13b: `agent_identity_effective`
(`spec.effectiveIdentity` starts with `agents.global.org-`, or the recorded
fallback file exists); `engine_no_span_content`
(`ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS` is `false` on the deployed engine, and
absent counts as a failure because it defaults on);
`engine_no_token_sharing_optout`;
`agentidentitycredentials_disabled`; `extension_yaml_fail_closed` (the
committed `config/armor/walle-ma-ext.yaml` says `failOpen: false`, and the
live extension is not `failOpen: true`); `dispatcher_uses_stream_query` (no
`.query(` or `async_query(` under `dispatcher/`); `agent_no_dynamic_toolsets`
(none of `skill_registry`, `SkillToolset`, `McpToolset`, `RemoteA2aAgent` under
`agent/`); `egress_registry_no_forbidden_hosts`; and the pre-existing
`exactly_one_engine`, which the spike engine makes fail until it is rolled
back. The older twenty-eight: The security invariants among them: the agent service account can read
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
- **The Model Armor floor commands do not run `gcloud config set
  api_endpoint_overrides/modelarmor`.** That property is persistent, and once
  set it also redirects the regional `templates create` on the next re-run of
  `armor`. The script passes the same override as
  `CLOUDSDK_API_ENDPOINT_OVERRIDES_MODELARMOR`, gcloud's environment form of
  the property, on the floor commands only. The flags are SETUP.md's.
- **The template create carries SETUP.md Phase 12c's flag set**, not chapter
  11's, which adds the custom error code and message flags. They only matter
  once blocking is on; SETUP.md is authoritative.
- **The deny policy is read back with `gcloud iam policies get`** before the
  create, and `verify` reads the agent's `effectiveIdentity` over REST, because
  there is still no `gcloud ai reasoning-engines` group. The IAP
  request-authorization extension YAML uses the field names chapter 13 records
  (`iapPolicyVersion`, `iamEnforcementMode`); a live import is the first thing
  that proves their spelling.
- **The egress "Sessions URI" endpoint** is registered as the engine's
  `/sessions` collection on the regional aiplatform host, which is how the
  runtime-gateway page describes it; confirm the exact form on the first
  dry-run deny log.

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
- Phase 12c: `armor --dry-run` issues no mutating command; both templates are
  created on the beta track with `--template-metadata-enforcement-type=inspect-only`
  and nothing is flipped to blocking; the bucket, the sink and the `_Default`
  exclusion are issued **before** the first template; the committed extension
  YAML contains `failOpen: false` and `timeout: 1s` and is the file imported;
  the folder and project floors are set with logging; no persistent gcloud
  config change; `armor --enforce` is refused without a decision file and
  nothing runs
- Phase 12b, on the identity path: `deploy.py` receives `IDENTITY_TYPE=AGENT_IDENTITY`
  and **no `service_account`**; no `serviceAccountTokenCreator` grant to the
  reasoning-engine service agent; the telemetry env goes through the `^;^` list
  with `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false` and never the token-sharing
  opt-out; four baseline grants and `run.invoker` land on the read-back
  `principal://` member; the deny policy is created, and `--skip-deny-policy`
  skips it; `SERVICE_ACCOUNT` without a spike file is refused before anything
  runs, and with one it passes `walle-agent@` and restores the grant; a `fail`
  spike on file refuses the identity path; `spike --dry-run` mutates nothing
- Phase 13b: `registry --dry-run` mutates nothing; `agentregistry.admin` goes to
  `CI_DEPLOYER` and nobody else, viewer to Eve and Mo; `walle-actions` is a
  `NO_SPEC` endpoint; the essential endpoints are registered and **no forbidden
  host ever is**; the egressor policy is applied per endpoint; the IAP extension
  starts fail-closed in `DRY_RUN`; `--card` refuses a `tbd` url and a forbidden host
- the nine new `verify` checks pass on a good repo, and three of them are shown
  to fail: on `.query(` in the dispatcher, on `McpToolset` in the agent, and on
  `failOpen: true` in the committed YAML

Deploy, spike and registry reach the Agent Runtime REST API over HTTP, which
has no gcloud group to stub, so the self-test loads the script as a module and
replaces the three HTTP entry points with canned answers (one engine, an agent
identity, the telemetry env). Everything else still goes through the stubs.

```bash
cd setup/selftest && ./selftest.sh
```

Run it after any change. Seventy checks, and they should all pass.
