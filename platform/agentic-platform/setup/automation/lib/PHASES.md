# How a phase file is written

## Status
- Owner: the platform owner
- Last reviewed: 2026-10-01
- What this is: the contract every file in `phases/` keeps, so the runner in `lib/core.sh` can
  plan, apply, resume and test any of them the same way. A phase file that breaks a rule below is
  a defect, whatever it does.

## One phase file per setup file

`phases/NN-<name>.sh` implements `setup/NN-<name>.md` and nothing else. It registers **every
numbered step** of that page, in the page's order, with the page's step id and heading. A step the
script cannot do is still registered, as `CONSOLE`, `HUMAN` or `BLOCKED`, so that `plan` shows the
whole procedure and `apply` stops where a person must act. Leaving a step out is the one error the
runner cannot see.

```bash
phase 09 "Folders and Security Command Center" "09-folders-and-security-command-center.md"
requires org "resourcemanager.folders.create resourcemanager.folders.get"
requires billing "billing.resourceAssociations.create"

step FS-1.1 AUTO "Create fld-agentic-platform" --needs "ORG_ID" --sets "FLD_PLATFORM_ID" --irreversible
s_FS_1_1_check() { ...; }
s_FS_1_1_apply() { ...; }
```

`requires` lists the IAM permissions the phase's commands need on the organisation or the billing
account; `agp-platform preflight` tests exactly these with `testIamPermissions` before `apply`.

## The five classes

| Class | Meaning | Functions |
|---|---|---|
| `AUTO` | deterministic commands the platform owner may run | `_check`, `_apply` |
| `AUTO-READ` | a read-only verification or inventory | `_check` (usually `ckpt_done ID`), `_apply` (the reads; returns non-zero when the verification fails) |
| `CONSOLE` | the Admin console or Cloud console, no usable API | `_check` (`ckpt_done ID`, plus a read of the end state where one exists), `_manual` |
| `HUMAN` | a decision, a signature, a purchase, a second person, a hardware key, a sitting, anything the separation of duties gives to someone other than the platform owner | `_check`, `_manual` |
| `BLOCKED` | depends on code that does not exist (a `B-nn` row of `setup/README.md` §8) | `_check` (`ckpt_done ID`), `_manual` |

Function names are `s_` plus the step id with `-` and `.` replaced by `_`: `FS-1.1` → `s_FS_1_1_check`.

## Step options

| Option | When |
|---|---|
| `--needs "A B"` | every name the step reads with `need` or uses in a command. The runner will not run a step whose input has no value |
| `--sets "C"` | every name the step writes with `penv_set` |
| `--gate "SD-13 P68"` | the decision ids the page checks with `tools/decision-need.sh` before the step |
| `--irreversible` | the page says IRREVERSIBLE, or the step fixes a name forever (a project id, a key ring, a bucket lock, a dataset location, an organisation-level enforcement). `apply` asks for the id to be typed |
| `--removes` | the step deletes, removes, disables or replaces a whole policy. Without it, `x` refuses those verbs |
| `--witness` | the page's WHO names a second person present for this step. `apply` then needs `--witness EMAIL` |
| `--on-unmet skip` | a manual or gated step later steps do not depend on. The default is `stop` (and `skip` for `BLOCKED`) |
| `--note "B-16"` | one line shown with a `BLOCKED` or manual step |

## The helpers, and the only ways to touch anything

| Helper | Use |
|---|---|
| `x CMD...` | every mutating command. Printed in plan mode, run and logged in apply mode. Refuses `--yes`, a default project, and removals in a step without `--removes` |
| `xw FILE [MODE]` | write standard input to a local file (a record, a register row file, a policy JSON) |
| `pset NAME VALUE` | every `penv_set` (`pset --force` only where the page itself uses `--force`) |
| `ev STEP SLUG E-ID TISAX LOCATION [FILE]` | every `evidence_add` |
| `api METHOD URL [BODY_FILE]` | REST calls with no gcloud equivalent. The token goes to curl on standard input, never in its arguments |
| `r CMD...` | a read whose output is used |
| `exists CMD...` | a `describe`: 0 present, 1 not found, 2 another error, 3 offline |
| `nonempty CMD...` | a filtered `list`: 0 when it prints something |
| `has_binding MEMBER ROLE CMD...` | an IAM binding on the policy `CMD --format=json` prints |
| `ckpt_done ID` | the step has a `DONE` line in `checkpoints.tsv` |
| `has_value NAME`, `v NAME` | a value is set; the value (`<NAME>` in plan mode) |
| `jget a.b.0.c` | a field of the JSON on standard input (no jq) |

Rules that follow from them:

1. **A check never changes anything** and never calls `x`, `xw`, `pset` or `ev`. It returns `0` done,
   `1` not done, `2` cannot tell, and passes `3` (offline) through.
2. **Commands are the page's commands**, copied from its ACTION block with values written as
   `"$(v NAME)"`. Every gcloud command names its scope explicitly (`--project`, `--organization`,
   `--folder` or `--billing-account`). No `--yes`, no `--quiet`: if gcloud asks, the operator answers.
3. **A value read from a command** is captured with `r` inside `_apply`, and written with `pset` only
   in apply mode; in plan mode `pset` announces it. Never write an empty value.
4. **The page's VERIFY becomes the check**, or the last lines of `_apply` returning non-zero when it
   fails. Prefer checks that are robust: `describe` exit status, or a `list --filter` that prints
   something; avoid parsing an unfiltered listing.
5. **A manual step's check is `ckpt_done ID`**, and a person records it with
   `agp-platform done ID [--witness EMAIL]`. Its `_manual` says, in at most twelve lines, WHO, WHERE
   (the exact console path), what to do, what to record (the `penv_set` lines, typed by the person),
   and the `done` command.
6. **No secret passes through the script.** A step that types, reads or stores a password, a refresh
   token, a client secret or key material is `HUMAN`, and its `_manual` points at the page.
7. **Steps that run in a twin or `walle` shell** (`twin_shell`, `walle_shell`) are `HUMAN`: the script
   never opens an interactive child shell.
8. **Bash 3.2**: no associative arrays, `mapfile`, `${var,,}`, `|&` or `declare -n`. The file passes
   `shellcheck -S warning`.
9. **No side effect at load time.** A phase file only registers steps and defines functions.

## How a phase is tested

`AGP_SETUP_DIR=<wiki>/platform/agentic-platform/setup bash tests/run-tests.sh --only 09` loads that
phase alone into a throwaway HOME with fake `gcloud`, `bq` and `curl`, supplies a fake value for
every name no step in it sets, and proves: it parses and lints; `plan` runs no mutating command;
`apply` reaches the end, stopping only at manual steps (which the test stands in for); and a second
`apply` changes nothing. `bash tests/run-tests.sh` runs every phase together.

## Files copied from a page

When a page writes a file with a heredoc (the variables-file template of setup/01 PR-2.2, the three
decision tools of setup/03 DC-1.2, a policy JSON), the phase does not retype it. The body is saved
once in `assets/`, the phase writes it with `xw` (`xw "$DEST" 600 < "$AGP_HOME/assets/NAME"`), and a
line in `assets/NN.manifest` names its source, tab-separated:

```
platform-env.template	01-prerequisites-and-conventions.md	cat > "$PLATFORM_REPO_DIR/env/platform-env.template" <<'PLATFORM_ENV_TEMPLATE'
```

The third field is the page's opening line, character for character. The tests extract the heredoc
from the page and fail when the asset differs, so a later edit of the page cannot leave the script
writing an older file.

## Which steps a phase covers

`phase NN "Title" "page.md"` covers every step of the page. A fourth argument limits it to the step
ids matching a regular expression, for a page only part of which is platform work:
`phase 42 "Gates, drills and evidence, sitting 1" "42-gates-drills-and-evidence.md" "GD-[1-4]\."`.
The tests compare the registered ids with the page's headings in that scope, both ways.

## Rules added on 2026-10-01, after the first test runs

1. **A manual step's check is `ckpt_done ID`.** It may also read the end state in Google, and it may
   print a warning when a local record the page asks for is missing, but it never returns `2` for a
   missing local record: the person's `agp-platform done` is the attestation, and the records are
   checked at the gates (17, 42) and by the security reviewer.
2. **An AUTO-READ verification may fail in the offline tests** because a fake cannot return a
   particular value; the tests note it and stand in. It must still never change anything.
3. **Before `~/.platform-env` exists** (phase 01 only), the runner writes DONE lines to
   `$(agp_pending_ckpt)`; PR-2.4 appends them to `checkpoints.tsv` in order and removes the file, as
   the page backfills them by hand.
4. **Decision tools are called as `"$(agp_tool decision-value.sh)"`** (and `decision-need.sh`,
   `decision-check.sh`), never by a hard-coded path. Only phase 03, which installs them, names
   `PLATFORM_REPO_DIR/tools/`.
5. **What a person types before the variables file exists** is read from `AGP_*` environment
   variables (`AGP_PLATFORM_REPO_DIR`, `AGP_BUILD_LOG_DIR`, `AGP_GIT_EMAIL`, `AGP_GIT_NAME`), with a
   clear refusal when unset.
6. **The test world.** `tests/run-tests.sh --only NN` runs phase 01 for real, stands in for every step
   of the phases before NN (a DONE line, fake values for the names they set), points the decision
   tools at stand-ins that read every decision as signed, and gives every name no step sets a fake
   value. Phase NN must then reach its end, stopping only at manual steps, and a second apply must
   change nothing.

## Added on 2026-10-01, second round

- **A check may return `5`: not applicable** (for example a per-project step when the organisation
  has no such project). The runner shows `[N/A]`, writes nothing, and goes on.
- **An AUTO step whose page says STOP until a person acts** returns `98` from `_apply` after printing
  what the person must do. The runner stops with "a person must act first … then resume". Use it only
  for a page's own STOP, never for a failed command (that is any other non-zero status).
- **A step found already done** in apply mode (its check passes) gets a DONE line "found done" if it
  has none, so `status` and the gates read the truth.
- **In apply mode an input counts only when it has a value.** A value a skipped step would set never
  satisfies a later step (that is plan mode only).
- **`agp-platform done` also records an AUTO-READ step**, with `--witness`, for a read only another
  person can make.

## Stand-ins: what a person produces, in the tests

A test can stand in for a person's `done`, but not for the files a person makes. Each phase owns
`tests/standins/NN.tsv` (see `tests/standin.py` for the format): when the test stands in for step
`ID`, it also applies that step's rows, so later AUTO steps find what they need: a value
(`value NAME VALUE`), a file (`file PATH CONTENT`), an evidence row (`evidence ...`), a file merged on
the platform repository's main branch (`commit RELPATH CONTENT`), or a shell line (`shell COMMAND`).
A `*` row is applied to the world before the phase runs. Stand-ins exist only in the tests; nothing in
`phases/` reads them.
- **Stand-in scope.** A `*` (world) row applies only when its own phase is under test (`--only`);
  a full run builds its world by running the earlier phases. A row keyed on a step id applies whenever
  the tests stand in for that step, whichever phase's file holds it, so a row for an earlier phase's
  step must leave that phase's own rules satisfied (for example: every commit before 03 DC-9.1 has its
  `reviews/<sha>.md` record). Rows of a manual step the run passes over (`--on-unmet skip`) are applied
  at the next stop, in order.
