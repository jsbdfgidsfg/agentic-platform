# Wall-E setup automation

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-15
- Status: **not to be used until aligned with the setup procedures** (decision SD-37, [../../agentic-platform/setup/03-decisions-and-people.md](../../agentic-platform/setup/03-decisions-and-people.md) §11; blocker B-18 in the [setup README](../../agentic-platform/setup/README.md) §8). Last aligned with: [SETUP.md](../SETUP.md) as it stood on 2026-09-14, which was superseded on 2026-09-15.
- Objective: 2026-09-13 — the robot holds **Super Admin** (P33); Wall-E's custom roles are retired and a second OAuth client and service (`walle-actions-super`) exist ([../../agentic-platform/01-hld.md](../../agentic-platform/01-hld.md) "What this reverses and what it costs", §13.1).
- Topology: 2026-09-13 — the script and the self-test implement the four-project placement of [../../project-topology.md](../../project-topology.md) ("The four-project placement", below).

## Do not run it: what it automates, and what replaced that

`walle_setup.py` automates parts of the 21-phase runbook that stood in [SETUP.md](../SETUP.md)
(18 numbered phases plus 12b, 12c and 13b). That runbook was superseded on 2026-09-15 by the
human-executed setup procedures in [../../agentic-platform/setup/](../../agentic-platform/setup/README.md),
files [30](../../agentic-platform/setup/30-wall-e-workspace-side.md) to
[39](../../agentic-platform/setup/39-wall-e-stage-0.md) for Wall-E, after the review
[../../agentic-platform/13-setup-procedure-review.md](../../agentic-platform/13-setup-procedure-review.md)
found blocking defects in both the runbook and this script. **The script is not aligned with the
new procedures.** It still creates `eve@` (which [24](../../agentic-platform/setup/24-eve-workspace-identity-and-audit-feeds.md)
alone creates, S088), reads its own `~/.walle-env` instead of the one variables file of
[01](../../agentic-platform/setup/01-prerequisites-and-conventions.md) §5, creates the project
under `FOLDER_ID` (S019) instead of the factory-module run of [17](../../agentic-platform/setup/17-factory-module-equivalents-and-tier-r-gate.md),
creates the production engine inside `deploy` before the identity spike (S015, S025), and
carries the further defects listed per subcommand below.

Under SD-37 the manual steps in files 30 to 39 are canonical. A subcommand may replace a manual
step only after its listed defects are fixed **and** `selftest/selftest.sh` gains a live
read-only mode (B-18, owner the Wall-E owner). Until then every step in those files that cites
the script reads BLOCKED for the script path and gives the manual commands, and the script runs
only inside `walle_shell` ([01](../../agentic-platform/setup/01-prerequisites-and-conventions.md) §5),
never with `PROJECT` set in an ordinary shell. Repairing it is adopted by a new decision record
under SD-37, not by a sentence in a runbook ([38](../../agentic-platform/setup/38-super-admin-gate-and-grant.md) §0).

### Which new steps each subcommand would correspond to

Each Wall-E file carries its own "How to execute this part" table with the same information at
step granularity; where this table and a file disagree, the file is right.

| Subcommand | Old SETUP.md phase | New file and steps it would correspond to | Why it cannot be used yet |
|---|---|---|---|
| `preflight` | §1.4, §1.5; PREREQUISITES §11 | [01](../../agentic-platform/setup/01-prerequisites-and-conventions.md) §4 and §11 (PR-4.*, PR-6.*); the sitting gate [30](../../agentic-platform/setup/30-wall-e-workspace-side.md) §0 (WW-0.*) | Tests a small part of a list that is itself superseded, against `~/.walle-env` |
| `workspace` (M0, M1, M2A, M2B, M3, M4) | 1, 3, 4, 5 | [30](../../agentic-platform/setup/30-wall-e-workspace-side.md) §2 to §5, §8 (WW-2.* to WW-5.*, WW-8.*); Phase 5 is owned by [14](../../agentic-platform/setup/14-central-logging-and-billing-export.md) CL-1.3 and verified by WW-9.* | Creates `eve@`, its licence and its role in the same run (S088); refuses while shipped placeholders stand (S171); M1 resets `EVE_ROBOT`'s password; the M2A gate passes on `isEnrolledIn2Sv` alone (S086); M2B and M3 omit rows (S103, S113); M4 would turn on a tenant feed 14 owns |
| `workspace` M2C, the grant | 2 | [38](../../agentic-platform/setup/38-super-admin-gate-and-grant.md) §4 to §6 (GT-4.* to GT-6.*); the twin grant [37](../../agentic-platform/setup/37-wall-e-sandbox-rehearsal.md) WR-2.3 | Reached only by re-running `workspace`, which walks M1 and M2A again after the consent and so destroys both refresh tokens (S014); gated by a file's existence, not the eighteen signed lines (S092). The repaired form is a separate `grant-gate` subcommand |
| `gcp` | 6, 7, 8 | [31](../../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §2 and §4 to §9 (WD-2.*, WD-4.* to WD-9.*) | `projects create --folder="$FOLDER_ID"` on a folder nothing creates (S019); commands without `--project` (S071); a standing creator Owner (S018); the project is an `FM-AGENT` run under 17, not a script call |
| `consent`, `consent --super` | 9 | [32](../../agentic-platform/setup/32-wall-e-consents.md) §3 to §6 (WC-3.* to WC-6.*) | No scope selector (S111); the granted-scope check always passes (S098); a plaintext operator token cache (S087); attestations taken before the event (S173); the two broad-client secrets are created nowhere (S020). 32 requires a rewritten consent command (B-17) |
| `armor`, `armor --enforce` | 12c | [34](../../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md) §7 (WI-7.*) | Writes the folder floor unconditionally (S096); basic-config templates with no custom error and no SDP step (S097); no regional endpoint override (S118); roles bound to service agents that do not exist yet (S174) |
| `spike` | 12b step 3 | [34](../../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md) §2 (WI-2.*); its claim reading is reproduced in WI-2.7 | Dies unless `walle-actions` was deployed by `deploy`, which also creates the production engine (S015) |
| `deploy` | 10, 11, 12, 12b, 14 | [33](../../agentic-platform/setup/33-wall-e-action-services-and-approval-surfaces.md) §3, §4, §7 (WS-3.*, WS-4.*, WS-7.*); [34](../../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md) §1 (WI-1.*); [35](../../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §2 to §4 (WE-2.* to WE-4.*); [39](../../agentic-platform/setup/39-wall-e-stage-0.md) §4 (S0-4.*) | One subcommand spans five phases and creates the engine before the spike and without its gateway (S015, S025, S075, S115); binds `group:$OPERATORS` as invoker (S095); omits Binary Authorization and the VPC flags (S006); two organisation sinks (S094); project-level Token Creator (S112); grants `expressUser` (S105); never rewrites `EXEC_CALLER_ALLOWLIST` (S016); the deny policy with unsourced names (S017); the super service fails on any third control-list entry (S076) |
| `register` | 13 | [35](../../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §7 and §8 (WE-7.*, WE-8.*) | Does not refuse a non-`eu` app (X-GE-13) and drives the console path (S056) |
| `registry` | 13b | [35](../../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) §1 and §9 (WE-1.*, WE-9.*) | Writes `registries` from `$PROJECT` (S057) and imports two YAML files that exist nowhere (S074) |
| `triggers` | 16 | [39](../../agentic-platform/setup/39-wall-e-stage-0.md) §6 (S0-6.*) | Not reviewed step by step; it shares the config, environment and `--yes` model of the rest and 39 §6 is manual and BLOCKED on B-16 |
| `verify` | every phase | [33](../../agentic-platform/setup/33-wall-e-action-services-and-approval-surfaces.md) §8 (WS-8.*); [39](../../agentic-platform/setup/39-wall-e-stage-0.md) S0-12.1, as `verify --strict` with SKIP as FAIL | The checks encode the defects above; it reads and refreshes the robot's refresh token on the operator's machine (S104); a check that cannot run passes as SKIP (S101) |
| `denials` | 17 | [37](../../agentic-platform/setup/37-wall-e-sandbox-rehearsal.md) §6 (WR-6.*) on the twin; [39](../../agentic-platform/setup/39-wall-e-stage-0.md) §7 (S0-7.*) on production | `HARD_DENIED` is an inline tuple no service loads (S078); check 48 passes when no event was generated (S100); `--yes` records human judgements as passed (S099) |
| `stage0` | 18 | [39](../../agentic-platform/setup/39-wall-e-stage-0.md) S0-12.2, BLOCKED on B-18 | Runs `verify` without `--strict` and proceeds on any number of SKIPs (S101); the grant record is a file's existence (S092) |
| `rollback --phase N` | 2, 9, 10, 11, 12, 12b, 14 | the ROLLBACK line of each step | Phases 1, 3, 4, 5, 13 and 13b have no scripted undo (S170); the Phase 10 undo deletes `walle-actions` only |
| `teardown` | — | [31](../../agentic-platform/setup/31-wall-e-project-and-data-plane.md) §10 (WD-10.*), a rollback that cannot destroy evidence | Unguarded against the audit and evidence stores |
| `status` | — | the checkpoint log of [01](../../agentic-platform/setup/01-prerequisites-and-conventions.md) §7 and the resume rule of the [setup README](../../agentic-platform/setup/README.md) §4 | Reads the script's own build log, not the checkpoint log |

## The script as it stood on 2026-09-14, for whoever repairs it (B-18)

Everything below this line describes the script as written against the superseded runbook. It
is kept so the repair can be scoped; "SETUP.md" in it means the retired page, whose phases map
to the new files in [SETUP.md](../SETUP.md) "Where each phase went".

**It stops at Stage 0, and no autonomous write is possible when it finishes.**
Every write family is at L1 (shadow) on chat and scheduled triggers and L0 on
event and inbox triggers, the daily write budget is 0, band B is permanently L3
with a two-person rule at tier `SUPER`, and band C only hands console steps to a
human.

**Workspace does not refuse a write the action service lets through.** Since
2026-09-13 the robot holds **Super Admin** (decision P33,
[../../agentic-platform/01-hld.md](../../agentic-platform/01-hld.md) §13.1 "Placement"), which cannot be
limited to an organisational unit and cannot be held by a service account, so
the action services are the only gate and the consented scopes the only
Google-enforced ceiling; the earlier property, a custom role with no write
privilege behind the action service, is gone. The script
creates no Wall-E role, **never grants Super Admin itself** (`users.makeAdmin` and
a Super Admin role assignment are on the hard-denied list), and offers the grant
only as manual step M2C once `SUPER_ADMIN_GRANT_DECISION` names the signed
record of the tier gate. Before that, `verify` asserts the robot is **not** a
super admin; after it, that it **is**, with the hygiene set and the roster rule.


The prerequisites it assumed were [PREREQUISITES.md](../PREREQUISITES.md), also superseded; the
platform prerequisites are now [01](../../agentic-platform/setup/01-prerequisites-and-conventions.md).
`./walle preflight` tested only a small part of that list.

## The subcommands, in the order the script expected them (historical, not to be run)

```bash
cp walle.env.example ~/.walle-env && $EDITOR ~/.walle-env   # fill in every <...>
./walle preflight            # tools, permissions, config, manual step list
./walle workspace            # phases 1 and 2 — Eve's read-only role; M2C (the Super Admin grant) only at the tier gate
./walle gcp                  # phases 6, 7, 8 — WALLE_PROJECT only; since 2026-09-13 the manual fallback of the factory call
./walle consent              # phase 9   — the one interactive sitting: client 1 (narrow)
./walle consent --super      # phase 9   — same sitting: client 2 (broad), refused without SUPER_SCOPES_DECISION
./walle armor                # phase 12c — Model Armor, inspect-only; BEFORE deploy
./walle spike                # phase 12b step 3 — the Agent Identity spike; BEFORE deploy
./walle rollback --phase 12b #   then delete the throwaway spike engine
./walle deploy               # phases 10, 11, 12, 12b, 14
./walle register             # phase 13
./walle registry             # phase 13b — Agent Registry, egress gateway in dry-run
./walle triggers             # phase 16
# There is no `grants` subcommand: the cross-project grants on Wall-E's resources are made
# by `gcp` (phase 7, dataset READER for Eve's and Mo's readers) and `deploy` (phase 10,
# run.invoker and the two caller allowlists); re-run either once the other runbook has
# created a principal that was reported PENDING.
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
Fill `~/.walle-env` in as each phase produces a value — `PROJECT_NUMBER` (Wall-E's
own), `GEMINI_PROJECT_NUMBER` (the app project's, at D8 / phase 6),
`REFRESH_TOKEN_VERSION`, `SUPER_REFRESH_TOKEN_VERSION`,
`ACTIONS_URL`, `SUPER_ACTIONS_URL`, `DISPATCHER_URL`, `ENGINE_ID` — because
a missing value expands to an empty string and produces a deployed resource that
is wrong rather than a command that fails.

`WALLE_REPO` must be a real, `git init`-ed path from Phase 1: `workspace` and
`gcp` both validate it, and Phase 1 step 5 writes and commits
`config/protected_floor.txt` into it. The *code* arrives later: Phase 7 reads
`schemas/*.json`, Phase 9 the three `bootstrap/` scripts, Phases 10 and 11 the
service sources, Phases 12 and 12b `agent/deploy.py`, Phase 14
`config/ladder.yaml` and `config/deploy_ladder.py`, and Phase 17 (`denials`)
`tests/denials.py` ([PREREQUISITES.md](../PREREQUISITES.md) §8). Phases 1 to 6
and 8 need no code, and doing them early surfaces the tenant surprises while the
code is being written.

**Since 2026-09-13 three things this script does by hand are the platform's** ([../SETUP.md](../SETUP.md) Phases 6, 11 and 12b):
Phase 6 is a factory call ([../../agentic-platform/02-landing-zone-and-tiers.md](../../agentic-platform/02-landing-zone-and-tiers.md#33-the-three-modules-and-the-topology-rows-they-consume) §3.3–§3.4), so
`walle gcp`'s project, API and service-account half is the manual fallback, used only while the factory does not exist and recorded as a dated exception;
Phase 11's two organisation sinks become the platform's aggregated sinks, `to-triggers-walle` and the view `platform_logs_views.walle_workspace_logs` in `LOGGING_PROJECT`
([../../agentic-platform/08-data-logging-retention-sovereignty.md](../../agentic-platform/08-data-logging-retention-sovereignty.md#32-the-sinks) §3.2), so the sinks `deploy` creates are the interim fallback, deleted before Stage 1;
and Phase 12b's project-level `walle-deny-agents` becomes the folder policy `deny-agents-platform`
([../../agentic-platform/04-identity-and-privileged-access.md](../../agentic-platform/04-identity-and-privileged-access.md) §3), so the deny policy `deploy` creates is the fallback too (`--skip-deny-policy` once the folder policy lists this project).

## The identity, Model Armor and registry phases (12b, 12c, 13b)

Three subcommands implement the chapters
[11-prompt-security.md](../11-prompt-security.md),
[12-agent-identity.md](../12-agent-identity.md) and
[13-agent-interconnection.md](../13-agent-interconnection.md), as SETUP.md
Phases 12c, 12b and 13b carried them. The gcloud invocations were SETUP.md's,
verbatim; the corrected forms are now [34](../../agentic-platform/setup/34-wall-e-identity-spike-and-model-armor.md)
and [35](../../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md). The config keys they need are documented in `walle.env.example`
with the subcommand that validates each: `AGENT_IDENTITY_MODE`,
`AGENT_IDENTITY_SPIKE_RESULT`, `INGRESS_GATEWAY`, `EGRESS_GATEWAY`, `FOLDER_ID`
(`armor`, and validated by `gcp` beside `WALLE_FOLDER_ID`, the numeric tier folder
`projects create --folder` actually uses, which must differ from it), `CORE_PROJECT` and
`REGISTRY_LOCAL_FALLBACK_DECISION` (`registry`), `CI_DEPLOYER` (the registry's local fallback only),
`MO_PRINCIPAL`, `GEMINI_ACCESS_SPIKE_RESULT` (decision 42's recorded result; empty
means no project-level fallback), `MODEL_ARMOR_ENFORCE_DECISION`,
`CONTENT_LOG_RETENTION_DAYS` (default 30). The four-project keys: `GEMINI_PROJECT`
and `GEMINI_PROJECT_NUMBER` (validated by `gcp`, `register` and by `deploy`'s engine
lock-down), `EVE_PROJECT` and `MO_PROJECT` (validated by `gcp` for the Phase 7
dataset readers and by `deploy` for the `run.invoker` loop and the allowlists).
`validate_config` refuses any two of the four project ids being equal,
`GEMINI_PROJECT_NUMBER` equal to `PROJECT_NUMBER`, and any of `SA_EVE`,
`SA_EVE_VERIFIER`, `SA_EVE_CONSOLE`, `SA_EVE_V0`, `SA_MO_METRICS`, `SA_MO_ANALYST`,
`SA_MO_NARRATOR` or `MO_PRINCIPAL` whose domain is `${PROJECT}.iam.gserviceaccount.com`
or is not its home project's: Eve's and Mo's identities live in their own projects and
appear in this config only as grantees on Wall-E's resources. `SA_MO_METRICS` is
derived from `MO_PROJECT` and is not a key of its own.

**`walle armor`** (Phase 12c, before the first `deploy`). Runs the steps of
[SETUP.md Phase 12c](../SETUP.md#phase-12c--model-armor-templates-the-ingress-gateway-and-the-floor)
in its order and with its flags, every create a get-or-create: the content-log
bucket, sink and `_Default` exclusion are issued **before any template exists**,
because the sanitize logs carry raw prompts and personal data, and both
templates start inspect-only. What is the script's own: it writes the extension
as `config/armor/walle-ma-ext.yaml` in `WALLE_REPO` (`failOpen: false`,
`timeout: 1s`) and imports that committed file, and it ends by telling you to
set `INGRESS_GATEWAY=walle-ingress` so `deploy` binds the engine to the gateway
at creation. **`walle armor --enforce`** performs the blocking flips (both
templates to `inspect-and-block`, the project floor to `INSPECT_AND_BLOCK`) and
is refused unless `MODEL_ARMOR_ENFORCE_DECISION` names an existing file: the
Stage 1 decision record, decision 24.

**`walle spike`** (Phase 12b step 3, before the first `deploy`; the three
results 12b-a to 12b-c are
[SETUP.md Phase 12b](../SETUP.md#phase-12b--the-agents-identity-agent-identity-with-a-gated-fallback)'s).
Creates a throwaway engine named `walle-spike` with `identity_type
AGENT_IDENTITY`, binds its principal as `run.invoker` on `walle-actions`, asks
it over `streamQuery` to mint an ID token for `ACTIONS_URL` and call
`/v1/operations`, and writes the three results, pass or fail with raw output,
to `AGENT_IDENTITY_SPIKE_RESULT`. It never writes a token: keys containing
"token" and any JWT-shaped string are redacted before the file is written. The
contract with `agent/deploy.py` is `WALLE_SPIKE=1`: deploy a spike agent whose
one tool, `probe_identity(audience)`, returns `token_returned`, `status` and
the decoded claims. `walle rollback --phase 12b` deletes the engine and its
binding afterwards; `deploy` refuses to run while a spike engine still exists.

**`walle deploy`** carries Phase 12b's steps 1, 2 and 4 to 6 and the manual
fallback of step 7 ([SETUP.md Phase 12b](../SETUP.md#phase-12b--the-agents-identity-agent-identity-with-a-gated-fallback)).
`AGENT_IDENTITY_MODE` defaults to `AGENT_IDENTITY`. Before anything mutates it
enables `agentidentity.googleapis.com`, **fails if
`agentidentitycredentials.googleapis.com` is enabled** (it disables nothing),
sets the two service-account-key constraints, and refuses an agent package that
mentions `GOOGLE_API_PREVENT_AGENT_TOKEN_SHARING_FOR_GCP_SERVICES` or does not
pin `google-auth>=2.45.0`. It passes `identity_type`, no `service_account`, and
(when `INGRESS_GATEWAY` is set) the `agent_gateway_config` to `deploy.py`, with
the four telemetry variables through the same `^;^` escaped list as Cloud Run,
`ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false` among them.
After the deploy it reads `spec.effectiveIdentity` back through the Agent
Runtime REST API, **fails unless it starts with `agents.global.org-`**, and
builds the principal from the value read back, never typed; then the baseline
grants (see "Where this differs from the documents" for the one SETUP.md does
not make), the two automatic roles described and refused on `secretmanager.` or
`setIamPolicy`, `run.invoker` on the principal, and the `walle-deny-agents`
deny policy (`--skip-deny-policy` skips it; its permission names are not yet
verified against the deny-policy supported list).
`AGENT_IDENTITY_MODE=SERVICE_ACCOUNT` is the gated fallback: refused unless
`AGENT_IDENTITY_SPIKE_RESULT` names an existing file, and a spike file whose
verdict is `fail` refuses the identity path too.

**`walle registry`** (Phase 13b, after `register`; the steps are
[SETUP.md Phase 13b](../SETUP.md#phase-13b--agent-registry-and-the-egress-gateway-in-dry-run)).
On the shared registry in `CORE_PROJECT` (P71) it enables only `iap`, `dns` and
`compute` in Wall-E's project and grants **no** registry role there; it reads
the factory-written `wall-e` entry and the essential endpoints in
`CORE_PROJECT`, recording a missing one as the factory's write; it prints the
registry-write audit filter, whose alert is the platform's; and it builds the
`walle-egress` gateway with `registries` naming `CORE_PROJECT`, plus the IAP
request-authorization extension and policy, written under `config/gateway/`, in
`iamEnforcementMode DRY_RUN`. Only when `REGISTRY_LOCAL_FALLBACK_DECISION`
names a record does it run the per-project steps: enable `agentregistry` and
`apphub` too, grant `agentregistry.admin` to `CI_DEPLOYER` only, fail if the
automatic `wall-e` entry lacks `RuntimeIdentity` or `RuntimeReference`,
register `walle-actions` as a `NO_SPEC` endpoint and the essential platform
endpoints with exact hostnames, and write the `roles/iap.egressor` access
policy for the agent principal and apply it per endpoint. On either path it
grants **nothing to Eve or Mo** (decision 43). **It never registers
`secretmanager`, `firestore`, `admin.googleapis.com`, any Workspace host or
`bigquery`**: a registration naming one is a refusal, not a warning, and
`verify` re-checks the live registry. `walle registry --card PATH` registers
the hand-written card and refuses while any `supportedInterfaces` url contains
`tbd` or names a forbidden host, or while a skill id advertises a write,
approval or control.

**What remains manual after these three.** Reading which method the Gemini
Enterprise caller actually uses (`query` or `streamQuery`) from the Agent
Runtime request logs during the first operator session, and recording it in
the build log of [35](../../agentic-platform/setup/35-wall-e-engine-registration-and-gateways.md) with the date. Capturing each operator's principal at their first
sign-in for the external-IdP case (12-agent-identity.md 5.2): only a session
produces it. Running the injection regression suite against
`walle-ingress-prompt` and recording `filterVersionConfig`. Proving a block and
the fail-closed behaviour (a wrong template name must error the caller), then
removing whichever service-agent grant proves unnecessary. Granting readers on
`walle-content-logs` (operators and IT security, nobody else). Verifying the
deny policy's permission names against the supported list. Keying the agent's
`EXEC_CALLER_ALLOWLIST` row on the claim the spike recorded. Lifting
`iam.managed.disableAccessPolicyBinding` (Google's id is singular) with an explicit
override policy on the project: Google enforces it by default in every organisation. Flipping the
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
| M2C | 2 (gate) | **The Super Admin grant**, offered only when `SUPER_ADMIN_GRANT_DECISION` names the signed P33 record: the platform's P-SA tier gate green, at least two human super admins (one outside the Wall-E administration line) with the robot on `SUPER_ADMIN_ROSTER`, multi-party approval on, self-recovery Off at the top OU. One human super admin assigns, a different one approves under multi-party approval. Never done by this script or by the robot's credential; the reverse is K6, also human-only. | yes, the robot's `isAdmin` and its role assignments against the roster (`verify_super_admin_grant`) |
| M2B | 3 | 2SV enforcement, security key only, scoped to the service OU. Split from M2A because the order matters and only a split step makes it enforceable: enforcing hardware-key-only on an account with no key registered locks it out permanently, and by then every fallback is gone. | yes, `isEnforcedIn2Sv` |
| M3 | 4 | The login reporting rule, under **Rules**, not Alert Center. The Alert Center API needs domain-wide delegation, which this design does not do, anywhere, ever. | **no API exists.** Check by eye |
| M4 | 5 | "Share data with Google Cloud services" is a tenant-wide console toggle. Prompted by `walle workspace`, not `walle deploy`: SETUP.md puts Phase 5 before Phase 6, the toggle takes up to 24 h to produce rows, and the login half must be resolved before Phase 9. | yes, by querying the org-level log for both `admin.googleapis.com` and `login.googleapis.com`. Neither log visible yet is `SKIP` (probably enabled less than 24 h ago); one visible and one missing is a failure |
| M5 | 9 | The OAuth consent screen and the OAuth client are console objects. Internal + In production, or refresh tokens expire after seven days. | **no** |
| M5S | 9 | The robot's **second** OAuth client (client 2, broad) for `walle-actions-super`, on the same consent screen, in the same sitting; its JSON goes to `walle-super-oauth-client` through `consent --super --store-client PATH`. `SUPER_SCOPES` must equal the signed broad list named by `SUPER_SCOPES_DECISION`; `cloud-platform` is refused. | **no** |
| M6 | 9 | Marking both clients Trusted in API controls. The Gmail scopes are "restricted" and your tenant's own API controls can cut an untrusted client off weeks later, with an error that looks nothing like the cause. | **no** |
| M7 | 9 | The consent itself is interactive by design. The script drives it but **prints the URL and waits**: a desktop OAuth flow opens the machine's *default* browser, which is signed in as you, and the grant then lands on your own admin account. Since 2026-09-13 the robot has the same privilege, so the damage is to **attribution and detection**: every action is logged under your name, and the reconciliation and the super-admin detection set, which key on the robot and its two client ids, see nothing. That is SETUP.md §7.1, the most likely single mistake in the runbook. The script calls `userinfo` afterwards and refuses to store the token if the account that consented is not the robot. | partly: the consent flow itself checks the account through `userinfo` and the exact scope set, and prints the version number. The manual block is operator-attested |
| M8 | 13 | Gemini Enterprise agent registration. It happens **in `GEMINI_PROJECT`** (`GEMINI_APP_ID`, `GEMINI_APP_LOCATION`), not in `PROJECT`. The REST surface for it is `v1alpha` and its shape is not stable, so SETUP.md's console steps are what this prints. The engine-level `walleEngineQuery` binding for `service-${GEMINI_PROJECT_NUMBER}@gcp-sa-discoveryengine` in `WALLE_PROJECT` is made by `deploy` (`lock_engine_iam`, Phase 12), not by `register`, which only tells the operator it must already be in place; Google's documented project-level `roles/discoveryengine.serviceAgent` fallback is applied by `deploy` only when the config key `GEMINI_ACCESS_SPIKE_RESULT` points at a recorded `{"verdict":"fail"}` from the decision-42 spike, and `verify`'s `engine_two_principals` then tolerates that one binding. | yes where the alpha listing answers, targeting `GEMINI_PROJECT` and the app's location, never `PROJECT`; otherwise it says it cannot |
| M9 | 16 | A monitoring notification channel. An alert policy with no channel is a dashboard. | yes |
| M10 | 18 | The Stage 0 decision record is a document, and writing it is the point. Printed by `walle verify` and gated by `walle stage0`. | no |
| — | 14 | Not a console step, but a human judgement the machine cannot make: after the forced shadow run, `walle deploy` asks whether the operator notification **actually arrived**. It is the one answer that proves `notify.operators` is really outside the ladder; if the report never arrives, F2-notify is back on the ladder at L1 and Stage 0 collects evidence nobody sees. | no |

## What `verify` asserts

Forty-two named checks on 2026-09-13 (`CHECKS` in the script is the authority), each pass/fail on its own, exit non-zero on any
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
back. The security invariants among the older checks: the agent service account can read
no secret and no KMS key, counting bindings inherited from the key ring and the
project; **Eve's** role holds nothing beyond its resolved read set
(`eve_role_is_read_only`), and the robot holds **no** role before the tier gate and
**exactly one**, Super Admin, after it, with no retired Wall-E role still assigned
(`role_assignments`; before P33 on 2026-09-13 it asserted one customer-scoped reader role and the Stage 1
write role assigned to nobody; it does not assert Eve's role while her role or account is absent — FAIL
after the grant, a stated gap before it); the secrets are regional and the service pins a
version **number** that still exists and is `ENABLED`, never `latest`; every
committed PEM under `contracts/eve-public-keys/` carries a `BEGIN PUBLIC KEY`
header (`kms_separation`: a header check, not a parse — a real EC P-256 parse is
not implemented; the directory is empty until S4 and the check passes vacuously
then) and `walle-actions@` holds **no** `cloudkms` role in `WALLE_PROJECT` — the
key itself is in `EVE_PROJECT`, where `verify` may not be able to read it, so its
shape is Eve's runbook's assertion; `project_roles`: no identity from
`EVE_PROJECT` or `MO_PROJECT` holds any project-level role in `WALLE_PROJECT`,
and no `eve-*` or `mo-*` service account exists there (both assertions live in
that one check; the decision-42 fallback for the Gemini project's service agent
is tolerated by `engine_two_principals`, not here); the action service cannot delete BigQuery audit data; the
trigger sink excludes the robot principal and the log copy does not (`sink_actor_exclusion`; on the
interim organisation sinks until the platform's `to-triggers-walle` replaces them);
exactly **two** principals can query the engine — `service-${GEMINI_PROJECT_NUMBER}@gcp-sa-discoveryengine`
(the app project's number, never `PROJECT_NUMBER`) and `walle-dispatcher@`,
no Eve identity (SETUP.md Phase 12, C10) — and no project- or
organisation-level binding confers query on a third; `walle_audit`'s access
array carries dataset-level `READER` for the Eve and Mo identities Phase 7
names (`cross_project_dataset_access`) and **no** `view` entry; the four foreign `run.invoker` members on
`walle-actions` carry `EVE_PROJECT` or `MO_PROJECT` domains; the engine
runs as `walle-agent@` with `min_instances 0`, no Memory Bank and no Code
Execution; every playbook scheduler is paused and the watch-renewal job is
running; the ladder has no `notify.operators` family, has `ou_allowlist` in
`defaults`, stamps a `ceilings_sha` and reads `config_version 2026.09.0-1`; the
control caller allowlist holds the operators as well as Eve's controller and
verifier at their full cross-project addresses and neither read-only caller
(`control_caller_allowlist`); the read caller allowlist holds `eve-console@` and
`mo-analyst@` at theirs and neither of them is on the control list
(`read_caller_allowlist`); and both Cloud Run services require authentication.

**The super-admin checks (P33)** ([../../agentic-platform/01-hld.md](../../agentic-platform/01-hld.md) §13.1 items 2, 3, 6 and 10):
`robot_hardening_and_roster` — inverted by P33 on 2026-09-13 (before, it failed if the robot was a super admin): the
super-admin state must match the tier gate (a super admin once `SUPER_ADMIN_GRANT_DECISION` is on file, not
one before), the hygiene set holds (no recovery email or phone, 2SV enrolled and enforced, in the robot OU),
and the roster rule holds (at least two human super admins, Eve's robot never one, the robot never a recovery
address, the live roster equal to `SUPER_ADMIN_ROSTER` in both directions; after the grant, a human super admin
without enrolled and enforced 2SV FAILs). Self-recovery Off, multi-party
approval and session control are not readable with this script's scopes and are the platform drift job's
Policy API read. `robot_credentials_scoped` — each token's granted scopes equal its client's list: it
refreshes each token **without** a `scope` parameter (`refresh_unnarrowed`) and compares the `scope` field of
Google's refresh response with the reviewed list, because passing the expected list to google-auth narrows the
token to it and an extra or `cloud-platform` scope could never be seen; an empty `SUPER_SCOPES` with a stored
broad token FAILs up front;
`no_cloud_platform_scope` — neither client's list carries `cloud-platform` (the CI assertion);
`hard_denied_list` — the hard-denied list is data with a closed reason vocabulary and every target resolves;
`secret_readers_split` — the narrow pair is read by `walle-actions@` only and the broad pair
(`walle-super-oauth-client`, `walle-super-refresh-token`) by `walle-actions-super@` only;
`super_service_allowlists` — `walle-actions-super` pins a version number, reads only the broad pair, has no
dispatcher and no Mo, and its lists compare both ways: `EXEC_CALLER_ALLOWLIST` is the agent only (plus the
agent-identity claim once the spike is on file), `CONTROL_CALLER_ALLOWLIST` is exactly `eve-controller@` and
`eve-verifier@` (halt only, [../../project-topology.md](../../project-topology.md#3-cross-project-grants)
row 27), and `run.invoker` is exactly the agent, those two and `SUPER_EXTRA_INVOKERS`; any extra or missing
member FAILs.

**Related checks and refusals.** HD-15 adds `directory.users.update`/`patch` on an admin target when the body touches a password
or recovery field or `suspended` (`Assumption:` confirmed by the P29 signature). `walle denials` requires
`DOMAIN`, `SVC_OU`, `EVE_ROBOT` and `PROTECTED` and refuses an unresolved target. A non-empty
`SUPER_ADMIN_GRANT_DECISION` or `SUPER_SCOPES_DECISION` naming a missing file is a config error. `walle
workspace` refuses to offer M2C unless `SUPER_ADMIN_ROSTER` already lists the robot.

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
refusing. Those checks report `SKIP` with a loud INCONCLUSIVE message
instead of a green PASS on a broken system.

**SETUP.md Phase 9's fourth check is retired (P33, 2026-09-13).** Before P33 `verify`
built the robot's credential from the pinned secret version, confirmed the
account, proved a `users.list` succeeded, and proved a `users.update` against a
**sandbox** account was refused 403, because the custom role was read-only. Under
Super Admin that write succeeds, so the probe would be an unaudited robot write
that proves nothing; the Workspace layer is no longer a second enforcement point
and `robot_credentials_scoped` checks the granted scopes instead. When it ran, that probe was the only Workspace
write `verify` ever attempted, it only ever names a sandbox account, it asks
first unless `--yes`, and it is skipped entirely under `--dry-run` — it is a
real Admin SDK write, and a robot-attributed admin event would also break the
Phase 18 checklist's "zero rows attributed to $ROBOT" box. (Phases 1 and 2 make
Workspace writes by design, and `teardown --include-workspace` deletes what they
made; `verify` is the subcommand this sentence is about.)

**One secret is written to disk, deliberately.** The robot's refresh token never
is: it goes from the token exchange straight into Secret Manager. The operator's
*own* OAuth token is cached 0600 at `OPERATOR_TOKEN_CACHE` so phases 1 and 2
do not re-consent on every run (Phase 15 no longer consents anything here). It is your own super-admin credential, it is
re-consentable at zero cost, and setting `OPERATOR_TOKEN_CACHE=""` disables the
cache entirely.

A check that could not run reports `SKIP`, not `PASS`. `--strict` makes skips
failures.

## Where this differs from the documents

Historical. Both sides of every comparison below are superseded: SETUP.md by files 30 to 39 of
the setup procedures, and the script's behaviour by the defect list per subcommand above. The
list is kept because several of its items became review findings, and the repair must not
reintroduce them.

- **SETUP.md Phase 10 lists the environment variables by name** (nineteen since
  2026-09-13, with `EVE_PUBLIC_KEY_PEM` and `READ_CALLER_ALLOWLIST`). The script
  asserts the exact name set, not a count.
- **SETUP.md Phase 8's BigQuery `DELETE` check runs as the operator**, who is
  normally a project owner, so it succeeds and reads as a control failure that
  is not one. The script runs it impersonating `walle-actions@`, which is the
  only way it proves anything.
- **ARCHITECTURE.md §4.2 and §7.5 give the Cloud Tasks worker its own service
  account, `walle-tasks@`.** SETUP.md Phase 6 creates four service accounts
  (`eve-controller@` is Eve's runbook's, in `EVE_PROJECT`) and has
  `walle-actions@` call itself back. SETUP.md wins; the split is worth doing
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
- **The `--set-env-vars` delimiter is `;`, not `@`.** `gcloud topic escaping`
  requires the delimiter to appear in no value, and eight of the seventeen values
  are email addresses, so an `^@^` list splits `ROBOT_ACCOUNT=walle-bot@example.com`
  in two and gcloud aborts with `Bad syntax for dict arg`. SETUP.md and the script
  both use `^;^`, and the script validates names *and* values against it.
- **There is no `gcloud ai reasoning-engines` command group**, in GA, beta or
  alpha. Listing engines, the two-principal IAM lock, `getIamPolicy` and the
  engine delete all use the Agent Runtime REST API on
  `$REGION-aiplatform.googleapis.com`, which is the escape hatch SETUP.md
  Phase 12 already names. SETUP.md Phase 12's command blocks still run
  `gcloud beta ai reasoning-engines set-iam-policy`, `get-iam-policy`, `list`
  and `delete`; follow the REST form.
- **Notification channels are `gcloud beta monitoring channels`**, not
  `gcloud monitoring channels`, which does not exist. `gcloud monitoring
  policies` is GA and is used as-is. SETUP.md uses the same.
- **Phase order.** `deploy` runs phases 10, 11, 12 and 14, and `register` runs
  13, so 14 lands before 13. Nothing depends on the order, but SETUP.md Phase
  13's verify distinguishes the pre-14 denial reason `control_plane_unavailable`
  from the post-14 `level_off`; after this reordering only `level_off` is
  observable, which is the reason SETUP.md wants it recorded either way.
- **Eve's `Eve — Verifier` Workspace role is still created in `workspace`, and
  `consent --eve` is retired.** The role is a tenant-level object, not a GCP
  resource, so creating it in `workspace` (alone, since P33 retired Wall-E's roles) still means one pass over
  the privilege catalogue and one console sitting; Eve's runbook Phase 8 then
  finds it present. Everything else the old Phase 15 did — Eve's OAuth client,
  consent, `eve-refresh-token` and `eve-oauth-client` — is a GCP resource and
  belongs in `EVE_PROJECT`, built by Eve's runbook Phase 9 with Eve's tooling.
  `consent --eve` would create those secrets in `WALLE_PROJECT`; it is removed,
  and a config whose `PROJECT` equals `EVE_PROJECT` is refused rather than
  treated as a way to run it.
- **The floor list carries the two robot accounts**, which SETUP.md Phase 1
  step 5 does not ask for. Denial test 17 requires a write targeting `$ROBOT` or
  anything in `$SVC_OU` to be refused as `protected_principal`, so the runtime
  protected set has to cover them. Deliberate, and wider than the runbook says.
- **Write privileges are classified by an allowlist, not a denylist**, and since
  P33 only for **Eve's** read-only role: Wall-E has no custom role to
  classify. A substring denylist misses `USERS_ALL`, `GROUPS_ALL`,
  `ORGANIZATION_UNITS_ALL`, `ADMIN_APIS_ALL`, `SUPER_ADMIN` and `USER_SECURITY`
  — the whole-service and total grants, none of which carries a write-shaped
  marker. Anything not on the resolved read list counts as a write, and a
  write privilege resolved into Eve's role stops the run. (Before P33 the
  list was "the resolved Stage 0 read list" of `Wall-E — Reader`.)
- **A pre-existing admin role with different privileges is a refusal**, not a
  warning; a warning would let `phase_2_roles` hand a wrong role on. Since P33 this
  applies to Eve's role: `phase_2_roles` creates no Wall-E role, and the two
  retired role names are kept only so `verify`, `status`, `teardown` and
  `rollback` can find a leftover. A leftover `Wall-E — Reader` or `Wall-E — Operator (Stage 1)` is
  reported, never deleted by `workspace`, and `role_assignments` fails while it is
  assigned (`rollback --phase 2` removes the assignment).
- **The floor list and the roster (P33).** The robot is on the floor
  list (as before) and, after the grant, on `SUPER_ADMIN_ROSTER` too: it is a
  protected principal under its own N7 rule, and a write targeting it is
  `self_modification_denied` in every lane. The script never grants Super Admin,
  never calls `users.makeAdmin`, and never makes the robot an approver.
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
- **The repository is needed from Phase 1, which no document says.** SETUP.md
  §0.4 names Phase 7 (schemas) and Phase 9 (bootstrap scripts);
  `walle.env.example` says Phases 7, 10, 11, 12 and 14 and that Phases 1 to 6
  and 8 do not need it. The script validates `WALLE_REPO` and `FLOOR_LIST_PATH`
  in `workspace` and `gcp`, and Phase 1 step 5 commits the floor list into it.
  Neither SETUP.md §0.4 nor `walle.env.example` mentions `tests/denials.py`,
  which Phase 17 needs.
- **SETUP.md hard-codes one repository path; the script reads `$WALLE_REPO`.**
  SETUP.md writes `~/Claude/wall-e` in §1.5 (the venv), §1.6, Phase 1 step 5,
  Phases 10, 11 and 12 and the Phase 18 checks, and has no `WALLE_REPO` export in
  §1.7, while `walle.env.example` derives `FLOOR_LIST_PATH` and
  `AGENT_IDENTITY_SPIKE_RESULT` from `WALLE_REPO`. A clone elsewhere makes the
  pasted runbook commands build from a path that does not exist, or a stale one.
- **The spike exists only in the script.** SETUP.md Phase 12b step 3 binds
  `--member="$SPIKE_PRINCIPAL"` on `walle-actions`, but defines that variable
  nowhere (§1.6, §1.7 or an earlier phase) and has no step that creates the
  throwaway engine. `walle spike` creates the engine and derives the principal
  from its `effectiveIdentity`; until SETUP.md gains those steps, step 3 is
  `walle spike` only.
- **`AGENT_BASELINE_ROLES` still carries `roles/aiplatform.expressUser`.** The
  script grants it to the agent principal in Phase 12b; SETUP.md Phase 12b step 6
  deliberately does not, because at project level it carries
  `reasoningEngines.query` on every engine and would make the agent a caller of
  its own engine. SETUP.md is authoritative and the constant must drop it; no
  self-test assertion covers it.
- **`EXEC_CALLER_ALLOWLIST` is never updated after Phase 12b.** `deploy` sets it
  to `walle-agent@` in Phase 10 and, after the 12b baseline grants, only prints
  and records a note to key the agent's row on the claim the spike recorded (an
  agent identity has no email). No subcommand runs the update, and SETUP.md has
  no step for it, so under the default `AGENT_IDENTITY_MODE=AGENT_IDENTITY`
  `/v1/execute` refuses the agent from Phase 12b onward, failing Phase 17 and
  Stage 0 entry. The fix is a Phase 12b step 6b, `gcloud run services update
  walle-actions --region="$REGION" --update-env-vars="EXEC_CALLER_ALLOWLIST=<the
  claim from $AGENT_IDENTITY_SPIKE_RESULT>"`, written by the script rather than
  printed. Under `SERVICE_ACCOUNT` the Phase 10 value is already right.
- **The access-policy constraint id is plural in the script.**
  `check_access_policy_bindings_allowed` queries
  `iam.managed.disableAccessPolicyBindings`, as SETUP.md Phase 13b and
  [13](../13-agent-interconnection.md) §2 spell it; Google's id is
  `constraints/iam.managed.disableAccessPolicyBinding`, singular, so the describe
  returns NOT_FOUND ([PREREQUISITES.md](../PREREQUISITES.md) §4.2).
- **`CI_DEPLOYER` has no creating phase and two names.** `registry` requires it
  on the local fallback, no phase creates it, and
  [12](../12-agent-identity.md) §6 calls the deploy identity `walle-deployer@`
  (*tbd* there), so an operator cannot tell whether they are one account. The
  Workload Identity Federation pool §6 expects the pipeline to use is created
  nowhere either.
- **The M2A verifier still requires Eve's robot.** `verify_2sv_enrolled` checks
  `isEnrolledIn2Sv` on both `ROBOT` and `EVE_ROBOT` and fails until both have a
  key, although Eve's robot account is hardened by Eve's runbook since
  2026-09-13. `EVE_ROBOT` is a `workspace` key, so the check cannot be skipped by
  leaving it empty.
- **`walle.env.example` states the placeholder rule wrongly.** Its header says the
  script validates only the keys the subcommand uses. `validate_config` scopes
  only the *missing or empty* check that way; a surviving `<placeholder>` in any
  key outside `REQUIRED_CONFIG_KEYS` refuses every subcommand. The shipped
  placeholders outside that set are `GEMINI_APP_ID`, `FOLDER_ID`,
  `WALLE_FOLDER_ID` and `CI_DEPLOYER`, and `AGENT_IDENTITY_SPIKE_RESULT` and
  `MO_PRINCIPAL` inherit one from `WALLE_REPO` and `MO_PROJECT`. The escape is to
  set them to `""` ([PREREQUISITES.md](../PREREQUISITES.md) §7.2).
- **The band-B service's environment names are the script's.**
  `walle-actions-super`'s variables are `SUPER_ENV_NAMES` in the script, which
  `deploy` asserts exactly; SETUP.md Phase 10 does not list them yet. The other
  second-service names (`walle-actions-super@`, `walle-super-oauth-client`,
  `walle-super-refresh-token`, `SUPER_REFRESH_TOKEN_VERSION`,
  `SUPER_ACTIONS_URL`, `SUPER_SCOPES`, `SUPER_SCOPES_DECISION`,
  `SUPER_ADMIN_ROSTER`, `SUPER_ADMIN_GRANT_DECISION`) agreed across SETUP.md,
  `walle.env.example`, the script and [03-lld.md](../03-lld.md) on 2026-09-13.
- **`EVE_SCOPES` still carries Eve's older scope list.** The constant in the
  script, kept as the frozen reference Eve's runbook must request verbatim and
  read by no subcommand, lists nine scopes with `apps.licensing`; Eve's consented
  set is ten read-only scopes with `apps.licensing` dropped and
  `admin.directory.domain.readonly` and `admin.directory.customer.readonly` added
  ([../../eve/02-identity-and-auth.md](../../eve/02-identity-and-auth.md#the-scopes-and-the-one-that-was-dropped)).

## The four-project placement

The script and `selftest/selftest.sh` implement the four-project placement of [../../project-topology.md](../../project-topology.md), whose [§3](../../project-topology.md#3-cross-project-grants) owns every cross-project grant and [§7.1](../../project-topology.md#7-which-runbook-creates-what) what Wall-E's runbook and this script create; the self-test asserts it ("Checking the script before you trust it", below). In the script: `SERVICE_ACCOUNT_IDS` holds Wall-E's four service accounts only and `EVE_PROJECT_ROLES` is empty, so no `eve-*` or `mo-*` account and no project-level role for an Eve or Mo identity exists here (`project_roles` fails on either); `gcp` creates the project with `--folder="$WALLE_FOLDER_ID"` (validated as numeric, refused when equal to `FOLDER_ID`), enables neither `discoveryengine` nor `cloudkms`, reads `GEMINI_PROJECT`'s number for the build log and makes the Phase 7 dataset `READER` entries (`grant_cross_project_dataset_readers`), while `deploy` emits `EVE_KMS_KEY` under `EVE_PROJECT` (ring `eve`), binds `run.invoker` on `walle-actions` for the three Eve identities and `MO_PRINCIPAL`, and locks the engine as "What `verify` asserts" describes, recording a not-yet-created principal as PENDING on both grant paths. There is no `ensure_kms`, no `consent --eve`, no `EVE_TOKEN_VERSION` and no `teardown --destroy-key-versions`, and every cross-project read goes through `gcloud_probe_json_in`, which refuses Wall-E's own project id.

**Still open, by design:** decision 42 (whether the engine-scoped role suffices cross-project, recorded through `GEMINI_ACCESS_SPIKE_RESULT`) and decision 44 (Eve's Firestore read — an IAM Condition on the database, or Eve's CC-33 list endpoint; nothing is granted until one lands).

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
  `licensing.licenseAssignments.listForProduct` call with the robot's credential.
  Since 2026-09-13 the expectation is rows after the grant (Super Admin holds
  License Management); until then it was 403, because License Management was
  indivisible and withheld from the custom role until Stage 1. It is one call and it closes "still to verify" item 1 in
  [09-open-decisions.md](../09-open-decisions.md). It is not implemented here,
  but `walle consent` prints the exact command at the one moment it is
  cheap — while the credential is in hand — and records a note to carry the
  answer into the build log. After the grant, a 403 means the scope or the grant
  is not what was consented.
- **The runbook's remaining behavioural verify steps.** Phase 12's smoke
  tool-count match, Phase 11's verify steps 1, 2, 4 and 5, and the K0–K5
  stopwatch drills are still done by hand from SETUP.md. Phase 13's
  `principal_id` gate, Phase 14's forced shadow run with the
  notification-arrival question, Phase 16's steps 1 to 3 (step 3 behind
  `walle triggers --drill-watch-alert`) and Phase 17's check 48 are implemented.
  Several of the unimplemented ones are Stage 0 exit criteria in §6.1.
- **Most of the pre-build checklist, in `preflight`.** It checks `gcloud`, `bq`
  and `git` on the path, Python 3.9 or later, the beta component, that gcloud is
  authenticated (a blocker), the config, that the gcloud account equals
  `OPERATOR_EMAIL` (a warning), organisation `resourcemanager.projects.create` and
  `logging.sinks.create`, and billing `billing.resourceAssociations.create` and
  `billing.budgets.create`. It does not check `openssl`, `jq` (Phase 12b step 2) or
  `curl` (Phases 10, 12b, 12c); a minimum gcloud version for the
  `agent-gateways`, `authz-extensions` and `agent-registry` groups (none is
  published); Application Default Credentials, which Phase 12's `agent/deploy.py`
  needs and `gcloud auth login` does not provide, and neither the script nor
  SETUP.md tells the operator to create them; `orgpolicy.policy.set`,
  `iam.denypolicies.create` or `modelarmor.floorSettings.update`; APIs, licences,
  security keys, the vault, the clean browser profile, the M0 host project or
  organisation policy constraints. Its beta warning says only "phase 12 needs
  it", although Phases 12c (`gcloud beta model-armor`) and 16 (`gcloud beta
  monitoring channels`) need it too. Its organisation `logging.sinks.create`
  test is a blocker although no agent runbook needs the role since 2026-09-13;
  it should become a warning naming Phase 11's interim fallback. The hand checks
  are [PREREQUISITES.md](../PREREQUISITES.md) §11.

## Checking the script before you trust it

Under SD-37 this self-test **is not evidence** that any Google command works: it stubs `gcloud`,
`bq` and `gsutil` and asserts only the shape of what the script emits. B-18 requires, on top of
the fixes above, a live read-only mode that runs the read probes against a real project and is
recorded in the build log before any subcommand replaces a manual step.

`selftest/selftest.sh` exercises the script with no credentials, no project and no
network. It puts stubs for `gcloud`, `bq` and `gsutil` on the path, records every
invocation, and asserts the properties that must hold before this runs against a real
tenant:

- an unedited config is refused, and nothing runs
- `--dry-run` issues no mutating command, only reads
- global flags work before or after the subcommand
- the corrections that were expensive to find are still in the emitted commands: no
  `--paused` on scheduler create, no non-existent role or command group, regional
  secrets, project roles on the service accounts; and the four-project invariants:
  no `gcloud kms` command at all, no `eve-controller` create, no `datastore.viewer`
  for a foreign principal, `projects create` carries `--folder` and never
  `--organization` (with `WALLE_FOLDER_ID` validated as numeric and refused when equal to `FOLDER_ID`), the engine policy names `service-${GEMINI_PROJECT_NUMBER}@` and
  never `service-${PROJECT_NUMBER}@gcp-sa-discoveryengine`, and no
  `projects add-iam-policy-binding` names a member outside
  `${PROJECT}.iam.gserviceaccount.com` except `CI_DEPLOYER`, the Google service
  agents and the recorded decision-42 fallback
- no Wall-E admin role is created and no manual step asks to confirm the robot is "NOT a super admin"
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
  `CI_DEPLOYER` and nobody else, and **no** `agentregistry.viewer` is granted to
  any `EVE_PROJECT` or `MO_PROJECT` principal (decision 43); `walle-actions` is a
  `NO_SPEC` endpoint; the essential endpoints are registered and **no forbidden
  host ever is**; the egressor policy is applied per endpoint; the IAP extension
  starts fail-closed in `DRY_RUN`; `--card` refuses a `tbd` url and a forbidden host
- The four-project paths: `phase10 --dry-run` and `phase12 --dry-run`
  issue no mutating command and no engine `setIamPolicy`; the deployed env carries
  `READ_CALLER_ALLOWLIST` with `eve-console@${EVE_PROJECT}` and `mo-analyst@${MO_PROJECT}`
  and `EVE_PUBLIC_KEY_PEM` naming the pinned-PEM directory; `validate_config` refuses an
  Eve or Mo key spelled in `${PROJECT}` or in the wrong home, and `GEMINI_PROJECT_NUMBER`
  equal to `PROJECT_NUMBER`; a foreign principal BigQuery or IAM reports as absent is a
  PENDING note and exit 0 on both grant paths, while any other error stops the run;
  `run_invoker_handles` is SKIP (not PASS) while the cross-project invokers are unbound;
  `control_caller_allowlist` and `read_caller_allowlist` pass on the right lists and fail
  on the old placement, on a read-only caller on the control list, on a missing
  `mo-analyst@` and on a missing read list; `gcloud_probe_json_in` refuses Wall-E's own
  project id; `register` reads the app under `GEMINI_PROJECT`, never `PROJECT`
- the nine Phase 12b, 12c and 13b `verify` checks pass on a good repo, and three of them are shown
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
