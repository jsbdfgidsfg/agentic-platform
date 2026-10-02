# agp-platform: the platform setup, as a script

## Status
- Owner: the platform owner
- Last reviewed: 2026-10-02
- What this is: a bash script that runs the **platform layer** of the setup procedures in
  [../README.md](../README.md) as code: files 01, 03, 04, 05, 06, 07, 09 to 21, and 42 sections 1 to
  4. It sets up the platform only. It builds no agent: Mo, Eve and Wall-E (files 22 to 41) stay
  human-executed and continue from where the script stops.
- Maturity: written and tested offline on 2026-10-01 and 2026-10-02 against fake `gcloud`, `bq`,
  `curl` and `gh`. **It has never run against Google.** The first real run is a rehearsal, read step by step in plan mode first.
- The procedures stay canonical. Where the script and a page disagree, the page is right and the
  script is corrected.

## What it does, and what it leaves to people

The script registers every numbered step of every page in scope, with the page's own step id: **832
steps** in twenty phases. It puts each in one of five classes:

| Class | What the script does |
|---|---|
| `AUTO` | runs the page's commands, after checking the step is not already done |
| `AUTO-READ` | runs the page's read-only verification |
| `CONSOLE` | stops and prints the console path; a person does it and records it with `agp-platform done ID` |
| `HUMAN` | stops and prints what a person must decide, sign, buy or do; recorded the same way |
| `BLOCKED` | prints the `B-nn` row of [../README.md](../README.md) §8 (code nobody has written yet, or a person not yet appointed) and carries on |

On 2026-10-01 the count is 245 `AUTO` and 114 `AUTO-READ` (359 steps the script runs, 43 %), 355
`HUMAN` and 53 `CONSOLE` (408 steps a person does), and 65 `BLOCKED`. 69 steps are IRREVERSIBLE and 95
wait on a signed decision. The platform layer is mostly decisions, signatures, purchases, consoles and
a second person: the script removes the typing, not the people.

| Phase | Page | Steps | Run by the script | Done by a person | Blocked |
|---|---|---|---|---|---|
| 01 | Prerequisites and conventions | 20 | 14 | 6 | 0 |
| 03 | Decisions, people, the platform repository | 43 | 3 | 39 | 1 |
| 04 | Purchases and lead times | 22 | 1 | 21 | 0 |
| 05 | Gemini Enterprise inventory (read-only) | 39 | 23 | 16 | 0 |
| 06 | Organisation bootstrap and the roster | 50 | 13 | 37 | 0 |
| 07 | Billing account | 18 | 4 | 14 | 0 |
| 09 | Folders and Security Command Center | 33 | 24 | 9 | 0 |
| 10 | Core projects and CI identities | 39 | 28 | 10 | 1 |
| 11 | Keys and the validator custodian | 37 | 21 | 4 | 12 |
| 12 | Privileged access catalogue | 40 | 14 | 23 | 3 |
| 13 | Organisation policies, deny and PAB | 54 | 39 | 15 | 0 |
| 14 | Central logging and the billing export | 47 | 28 | 18 | 1 |
| 15 | Pager, SIEM and detections | 54 | 8 | 27 | 19 |
| 16 | The register and the shared registry | 43 | 13 | 23 | 7 |
| 17 | Factory module equivalents and the Tier R gate | 77 | 51 | 19 | 7 |
| 18 | Model Armor floor, spikes and the fleet kill switch | 37 | 16 | 13 | 8 |
| 19 | Gemini Enterprise import and baseline | 63 | 37 | 24 | 2 |
| 20 | The tenant gateway and the Tier C gate | 54 | 11 | 42 | 1 |
| 21 | Sandbox tenant and nonprod foundation | 44 | 5 | 37 | 2 |
| 42 | Gates and evidence, sitting 1 (§1 to §4) | 18 | 6 | 11 | 1 |

It does not cover file 02 (the toil baseline, which belongs to Wall-E's case), file 08 (the witness
organisation, which IT security administers so that the platform owner cannot), or files 22 onwards.
It never signs a decision, never buys anything, never handles a password, a refresh token, a client
secret or key material, and never opens a twin shell: those steps are `HUMAN` and say so.

## Who runs it, and with what authority

The platform owner, signed in to the dedicated gcloud configuration of setup/01 PR-3.1 as
`sa-1-admin@` (setup/06 OB-2.12). **Owner on a single project is not enough.** The platform is built at
the organisation: folders, organisation policies, deny policies, aggregated log sinks and Security
Command Center need the organisation-level exception setup/06 grants (Organization Administrator,
Folder Creator, Project Creator and Privileged Access Manager Admin, each with an expiry) and the
billing roles of setup/07. `agp-platform preflight` tests every permission the selected phases declare,
on the organisation and on the billing account, before `apply` changes anything, and lists what is
missing.

Run it from the workstation setup/01 prepares (macOS, bash 3.2 or later, gcloud with the beta
component, bq, git, python3, curl). Cloud Shell works for reading, but the procedures' sittings revoke
every credential at the end (`sitting_end`), which assumes the workstation.

## What you provide before the first run

1. **The values the pages leave to you**, from the signed NAMES and KEYS records (setup/03 DC-5.1,
   DC-5.2): `./agp-platform names --all` lists every one and which step sets it; you type each with
   `penv_set NAME VALUE` in a shell that has sourced `~/.platform-env`. The script never invents one.
2. **For the very first run of phase 01**, before the variables file exists: `AGP_PLATFORM_REPO_DIR`,
   `AGP_BUILD_LOG_DIR`, `AGP_GIT_EMAIL` and `AGP_GIT_NAME` in the environment (setup/01 PR-2.1 says
   choose the paths now, never later).
3. **The decisions**, signed under setup/03 (the gates read `tools/decision-need.sh`), **the people**
   (setup/03 DC-2.x: the second human, the security reviewer, the incident commander and the others),
   and **the purchases** of setup/04. Without them the script stops at the first step that needs one,
   and says which.
4. **A terminal**: IRREVERSIBLE steps ask for their id to be typed, and gcloud may ask a question.

## How to run it

```bash
cd <wiki>/platform/agentic-platform/setup/automation
./agp-platform plan --all --offline          # the whole procedure, no credential needed
./agp-platform names --all                   # every value the steps read, and which you must supply
./agp-platform sitting start                 # setup/01 PR-3.2, after gcloud auth login
./agp-platform preflight --all               # tools, variables, account, permissions
./agp-platform plan --phase 09               # what phase 09 would do, checked against the organisation
./agp-platform apply --phase 09              # do it; stops at the first step a person must do
./agp-platform done FS-2.3 --witness <email> # record a manual step a person has done
./agp-platform apply --phase 09 --from FS-2.4
./agp-platform status                        # progress per phase
./agp-platform sitting end
```

`apply` runs the steps that are not done, in order, and stops at the first one that needs a person,
an unsigned decision, a missing value or a failed check, saying exactly why and how to resume. It is
safe to re-run: every step checks first, and a second run changes nothing.

## The rules it keeps

- **Nothing changes without `apply`.** `plan` runs reads only; with `--offline` it runs nothing.
- **IRREVERSIBLE steps** (project ids, key rings, bucket locks, dataset locations,
  organisation-level enforcement) stop and ask for their id to be typed, or take
  `--confirm-irreversible ID,ID`.
- **Decision gates** are read with setup/03's `tools/decision-need.sh`; an unsigned decision stops
  the step.
- **Steps with a witness** need `--witness EMAIL`, and the email goes into the checkpoint.
- **No `--yes`, no `--quiet`, no default project**, and no removal in a step not declared to remove.
- **No credential in an argument or a log.** REST calls pass the access token to curl on standard
  input.
- **The same records as a run by hand**: values through `penv_set`, steps through `checkpoint`,
  evidence through `evidence_add`, all in the build log, which is committed.

## How it is tested

On 2026-10-02 every phase passes its own offline test: a throwaway HOME in which phase 01 runs for
real, every earlier phase is stood in for, and fake `gcloud`, `bq`, `curl` and `gh` answer. Each test
proves the phase parses and lints, registers every step of its page, plan changes nothing, apply
reaches the end stopping only where a person must act, and a second apply changes nothing. The runner's
own self-test passes. The end-to-end offline run, every phase in order, gets through phases 01 to 18
and into 19, where a value an earlier phase read from the fake (a folder id) no longer matches what a
later check expects: the fakes model projects, IAM bindings and their conditions, datasets and
removals, but not every value Google would return. **Nothing proves that Google accepts each command
until the first real run**, in plan mode first, against a sandbox organisation if one exists.

The procedures were rechecked on 2026-10-01 before the script was written
([../../15-documentation-recheck.md](../../15-documentation-recheck.md)). Turning them into code then
found further defects in the pages themselves (a record no step told anyone to register, a STOP with no
resume point, a command missing a required flag, deviation rows appended where the register forbids
them); 175 corrections were made in the pages, which stay canonical, and the script follows them.

To run them: `bash tests/run-tests.sh --only 09` (one phase, a few minutes), `bash tests/run-tests.sh`
(every phase in order, about half an hour), `bash tests/run-tests.sh --selftest` (the runner alone).
Set `AGP_SETUP_DIR` when this folder is not inside the wiki's `setup/`. The tests also check that the
files the script writes (the variables-file template, the decision tools, the policy files) are
byte-identical to the pages' heredocs, so a later edit of a page cannot leave the script behind.

## Files

| Path | What |
|---|---|
| `agp-platform` | the entry point |
| `lib/core.sh` | the runner: classes, gates, confirmations, helpers |
| `lib/preflight.sh` | tools, variables, account, permissions |
| `lib/agp_json.py` | JSON helpers, so no jq is needed |
| `lib/PHASES.md` | the contract every phase file keeps |
| `phases/NN-*.sh` | one per setup page |
| `assets/` | files copied byte for byte from the pages, with a manifest naming each source |
| `tests/` | the offline tests, the fakes of `gcloud`, `bq`, `curl` and `gh`, and `standins/`: what a person would produce at a manual step, for the tests only |

## Related
- [../README.md](../README.md), the setup procedures this script runs
- [../../15-documentation-recheck.md](../../15-documentation-recheck.md), the recheck of 2026-10-01 that corrected the pages first
