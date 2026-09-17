# POV 01. Conventions, the one variables file, the helpers and the evidence layout

## Status

- Owner: the platform owner
- Last reviewed: 2026-09-17
- Part of: the proof-of-value (POV) set whose entry point is [README.md](README.md). Full-set
  counterpart: [../setup/01-prerequisites-and-conventions.md](../setup/01-prerequisites-and-conventions.md)
  (1,752 lines), plus the decision tools of [../setup/03-decisions-and-people.md](../setup/03-decisions-and-people.md)
  §4 and the platform repository of the same page's §12.
- Step prefix: `PP`. 20 steps in two parts; one BLOCKED (PP-5.5).
- Part A runs on day one, before [02](02-decisions-people-and-the-retrospective-baseline.md).
  Part B (the git host) runs after 02 has signed PV-03 and PV-09 and set `SECOND_HUMAN_EMAIL` and
  `SECOND_OPERATOR_EMAIL`, and before [03](03-foundation-folders-logging-and-floors.md).
- **Person 3 (the second operator) is appointed before Part B, not later** (README §5.1a).
  PP-5.1 runs `need` on `SECOND_OPERATOR_EMAIL`, which refuses `*tbd*`, and the protected platform
  repository needs two human reviewers who are not the author (PP-5.4). Without person 3 there is no
  push, no `PLATFORM_REPO_REMOTE`, and so no file from 03 onward.
- No checkpoint line is written from this file until PP-1.5's prefix-collision refusal prints
  nothing (README §6.2): 02 is `PD`, 04 is `PC`, and neither may collide with the full
  set's `PS` (setup/15) or `PR` (setup/01).
- Commands checked against Google's and GitHub's documentation on 2026-09-16 (Sources). The
  extraction commands, `pov-names-check.sh` and its fixtures were run against the wiki's setup
  files on 2026-09-16. That run checks shell logic only; it is not evidence (setup/01 PR-2.5, S177).

## What this part builds

The POV reuses the full build's conventions **unchanged**, so that the full build continues from
the same laptop, the same variables file, the same logs and the same repository. This part:

- installs the full set's variables-file template and the three decision tools **by extracting
  them byte for byte from the wiki**, not by retyping them, and records their SHA-256 so the
  second person can recompute it;
- creates `~/.platform-env` once (never committed, no secret), with the same fixed values as
  setup/01 PR-2.3 plus `POV_TRACK` and `POV_STAGE`;
- proves the dedicated gcloud configuration has no default project (`penv_guard`);
- starts the build log (`checkpoints.tsv`, `rerun-index.tsv`, `variables-changes.tsv`) and opens
  the three registers in their full-set formats: `DEVIATION_REGISTER`, `EVIDENCE_REGISTER`,
  `DRILL_CALENDAR`, with the POV's drill rows;
- adds two small POV tools: `confirm_manual` (a typed identifier for every human judgement) and
  `pov-names-check.sh` (`RETIRED_NAMES_CHECK`), which extends the retired-names rule so that no POV
  step can spend a Wall-E name;
- has the second person create `EVIDENCE_INTERIM_LOCATION`;
- in Part B, puts the platform repository **and the build log** on the git host with CODEOWNERS
  and branch protection, closing the full set's own "build log has no remote" residual risk
  (setup/01 §7.1) with the name it proposed, `BUILD_LOG_REMOTE`.

**Why `PLATFORM_EVIDENCE_BUCKET` is not here, and moves forward to 03.** In the full set the
bucket is created by setup/42 GD-3.1, which README §4 orders "straight after 14", because until it
exists the rule "copy every record to the evidence bucket" has no destination. The POV is twelve
weeks long and produces its first lock and its first K7 drill record in 03, so 03 creates the
bucket with setup/42 GD-3.1's own commands and the NAMES value signed in PV-03. It needs
`ORG_ID`, the core project, the logging key ring and the PV-10 retention values, none of which
exist in 01. The name and the lock value are the full build's, so this is a change of order, not a
deviation: nothing is renamed and no control is loosened.

## Preconditions

- [ ] A managed macOS workstation with FileVault available (setup/01 P-01).
- [ ] The second person (IT security) is known by name, even though 02 records the appointment.
      PP-3.4 and PP-6.1 wait for that person in Part A.
- [ ] Person 3 (second operator) is identified on day one and appointed by 02 before Part B
      (README §5.1a). Part B cannot start while `SECOND_OPERATOR_EMAIL` is `*tbd*`.
- [ ] Nothing has been created in the tenant or in Google Cloud by any procedure of either set.
- [ ] Part B only: `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-03 PV-09` prints two `SIGNED`
      lines, and `need SECOND_HUMAN_EMAIL SECOND_OPERATOR_EMAIL` is silent (person 3 appointed).
- [ ] Before the first checkpoint (PP-1.5): the README §6.2 check prints nothing, so no POV file
      carries the full set's `PS` or `PR` prefix (02 is `PD`, 04 is `PC`).

## People

| Role | Steps | Present with the platform owner? |
|---|---|---|
| Platform owner (person 1, the operator) | every step except PP-3.4 | not applicable |
| Second person (person 2, IT security) | PP-3.4 creates the interim location; PP-5.3 witnesses the push; PP-5.4 witnesses protection; PP-5.5 runs the weekly audit; PP-6.1 recomputes the hashes and signs | PP-5.3 and PP-5.4 on screen; the rest asynchronous |
| Second operator (person 3), appointed before Part B | PP-5.1 confirms the exempt list; PP-5.4 negative test: approves once; reviews every later pull request | asynchronous |

The platform owner never verifies their own evidence: PP-6.1's hash recomputation is the second
person's, on their own workstation. Two hands-on people plus a named third is PV-D-14
([09](09-the-demonstration-deviations-and-the-hand-over.md)).

## 1. What is reused unchanged, and from where

| Convention | Defined in | POV use |
|---|---|---|
| The seven-field step format: Id, WHO, WHERE, ACTION, VERIFY, ROLLBACK, EVIDENCE; the **IRREVERSIBLE** and **BLOCKED** forms | setup/01 §1; setup/README §5 | Every POV step. A BLOCKED step names the code, the repository, the gate and a POV-sized estimate marked `Assumption:` |
| `~/.platform-env`, its template and helpers `penv_set`, `need`, `exists_or_pending`, `twin_shell`, `walle_shell`, `penv_guard`, `checkpoint`, `evidence_add`, `sitting_end` | setup/01 PR-2.2 | Extracted verbatim (PP-1.3). `twin_shell` and `walle_shell` are present but never called in Track A |
| Variable names | setup/README §5.2 | One name per variable; the POV adds only `POV_TRACK`, `POV_STAGE`, `RETIRED_NAMES_CHECK` and the `POV_*`/`PV-*` records listed in the README (§7.1, §9) |
| Checkpoint line and resume rule, standing fallback approver | setup/README §4; setup/01 §1 | Unchanged |
| Sitting rules: no default project, `--project`/`--folder`/`--organization` on every command, no admin token between sittings, no domain-wide delegation client ever | setup/01 §6.1 | Unchanged (absolutes 1 and 9) |
| Change patterns: access arrays with etag and read-back, secrets piped with `--data-file=-`, foreign principals through `exists_or_pending` | setup/01 §8.1 to §8.3 | Unchanged |
| Record naming `<date>-<step-id>-<slug>-v<n>`, never overwritten; evidence homes | setup/01 §7.1 | Unchanged, except that the bucket copy starts after POV 03 |
| E-xx and TISAX mapping of build records | setup/01 §7.2, from [../10-eu-ai-act.md](../10-eu-ai-act.md) §5 and [../11-tisax.md](../11-tisax.md) §13 | Unchanged, plus the POV rows of §3 below |
| Decision record format and `decision-check.sh`, `decision-need.sh`, `decision-value.sh` | setup/03 §4, DC-1.1 to DC-1.4 | Extracted verbatim (PP-4.1); records PV-01 to PV-13 are made in 02 |
| Repository on the git host: humans-only write, CODEOWNERS, two-reviewer protection, negative tests, bypass audit | setup/03 DC-9.2 to DC-9.9 | Compressed into PP-5.1 to PP-5.5 |

**The absolutes.** setup/README.md:60-66 and the nine absolutes restated in [README.md](README.md)
bind every POV step. Nothing in this file loosens one.

## Part A. Day one

### PP-1.1 Workstation, tools and browser profiles

**WHO:** Platform owner. **WHERE:** macOS terminal; Chrome.

**ACTION:** Run setup/01 **PR-1.1, PR-1.2 and PR-1.3 as written** (Cloud CLI with `beta`, Python
3.12, `jq`, `git`; FileVault on; working area `$HOME/platform` outside every synced folder; Chrome
profiles `daily` and `sa-1-admin`, the second signed in to nothing). Then:

```bash
mkdir -p "$HOME/platform/tmp-records"
{ date -u +%Y-%m-%dT%H:%M:%SZ; gcloud version; bq version; python3.12 --version; jq --version; git --version; perl -v | sed -n 2p; fdesetup status; } > "$HOME/platform/tmp-records/tools.txt" 2>&1
gcloud components list --only-local-state --format='value(id)' | grep -qx beta && echo "beta OK"
```

**VERIFY:** `tools.txt` shows gcloud 563.0.0 or later (setup/01 PR-1.1's floor), `perl` present
(PP-3.5 needs it; it ships with macOS), `FileVault is On.`; `beta OK` printed.

**ROLLBACK:** Uninstall the tools; nothing outside the workstation is touched.

**EVIDENCE:** `tools.txt`, registered in PP-3.2 as `<date>-PP-1.1-workstation-tools-v1`. E-05.
TISAX 5.3.1.

### PP-1.2 The two local repositories

**WHO:** Platform owner. **WHERE:** macOS terminal.

**ACTION:** `Assumption:` the paths below, which are setup/01 PR-2.1's. Choose now, never later.

```bash
PLATFORM_REPO_DIR="$HOME/platform/agentic-platform"
BUILD_LOG_DIR="$HOME/platform/build-log"
WIKI_DIR="$HOME/Claude/wiki"
git init -b main "$PLATFORM_REPO_DIR"
git init -b main "$BUILD_LOG_DIR"
git -C "$PLATFORM_REPO_DIR" config user.email "<the platform owner's email>"
git -C "$BUILD_LOG_DIR" config user.email "$(git -C "$PLATFORM_REPO_DIR" config user.email)"
mkdir -p "$PLATFORM_REPO_DIR/env" "$PLATFORM_REPO_DIR/tools" "$PLATFORM_REPO_DIR/decisions" "$BUILD_LOG_DIR/registers" "$BUILD_LOG_DIR/records"
mv "$HOME/platform/tmp-records/tools.txt" "$BUILD_LOG_DIR/records/" && rmdir "$HOME/platform/tmp-records"
```

**VERIFY:** `git -C "$PLATFORM_REPO_DIR" rev-parse --is-inside-work-tree` and the same for
`BUILD_LOG_DIR` print `true`; neither path contains `Library/CloudStorage`, `Mobile Documents`,
`/Desktop/`, `/Documents/` or `/Claude/wiki` (setup/01 PR-2.1 VERIFY).

**ROLLBACK:** `rm -rf` both directories before the first commit.

**EVIDENCE:** Build-log line under PP-1.2 (backfilled at PP-1.5). E-05. TISAX 5.3.1.

### PP-1.3 The POV library and the template, extracted from the wiki

**WHO:** Platform owner; the second person recomputes the hashes in PP-6.1.
**WHERE:** Same shell as PP-1.2.

**ACTION:** `pov_extract FILE START END` prints the lines strictly between the heredoc opener
`START` and its terminator `END`. It is the only way the POV obtains full-set code, so nothing is
retyped. `confirm_manual` is the shell form of the SD-37 rule quoted in setup/37 (S099): a human
judgement is a typed identifier, never a yes, never non-interactive.

```bash
cat > "$PLATFORM_REPO_DIR/tools/pov-lib.sh" <<'EOF'
# pov-lib.sh: POV helpers. Source after ~/.platform-env. Holds no value and no secret.
# pov_extract FILE START END: the lines between the heredoc opener START and its terminator END.
pov_extract() {
  [ $# -eq 3 ] && [ -f "$1" ] || { echo "usage: pov_extract FILE START END" >&2; return 2; }
  awk -v s="$2" -v e="$3" 'p && $0==e {f=1; exit} p {print} index($0,s)==1 {p=1} END {exit !f}' "$1"
}
# confirm_manual STEP_ID QUESTION: records the identifier a human read on screen, or fails.
confirm_manual() {
  [ $# -eq 2 ] || { echo "usage: confirm_manual STEP_ID QUESTION" >&2; return 2; }
  case "$1$2" in *--y*) echo "confirm_manual: an automatic yes is refused" >&2; return 2;; esac
  [ -t 0 ] && [ -t 1 ] || { echo "confirm_manual: needs an interactive terminal" >&2; return 2; }
  need BUILD_LOG_DIR || return 2
  printf '%s\nType the identifier you read (message id, audit id, commit, record id): ' "$2"
  IFS= read -r _cmi
  case "$_cmi" in ''|[Yy]|[Yy][Ee][Ss]|[Oo][Kk]|[Nn]|[Nn][Oo]|*'<'*'>'*|*"$_PENV_TAB"*)
    echo "confirm_manual: NOT CONFIRMED; a yes is not an identifier" >&2; return 1;; esac
  printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$(git -C "$BUILD_LOG_DIR" config user.email)" "$2" "$_cmi" >> "$BUILD_LOG_DIR/confirmations.tsv" \
    && git -C "$BUILD_LOG_DIR" add confirmations.tsv && git -C "$BUILD_LOG_DIR" commit -q -m "confirm $1" && echo "CONFIRMED $1 $_cmi"
}
EOF
. "$PLATFORM_REPO_DIR/tools/pov-lib.sh"
pov_extract "$WIKI_DIR/platform/agentic-platform/setup/01-prerequisites-and-conventions.md" "cat > \"\$PLATFORM_REPO_DIR/env/platform-env.template\" <<'PLATFORM_ENV_TEMPLATE'" PLATFORM_ENV_TEMPLATE > "$PLATFORM_REPO_DIR/env/platform-env.template"
shasum -a 256 "$WIKI_DIR/platform/agentic-platform/setup/01-prerequisites-and-conventions.md" "$PLATFORM_REPO_DIR/env/platform-env.template" "$PLATFORM_REPO_DIR/tools/pov-lib.sh" | tee "$BUILD_LOG_DIR/records/$(date -u +%F)-PP-1.3-extraction-hashes-v1.txt"
git -C "$PLATFORM_REPO_DIR" add env/platform-env.template tools/pov-lib.sh
git -C "$PLATFORM_REPO_DIR" commit -m "PP-1.3 platform-env template (verbatim from setup/01 PR-2.2) and pov-lib"
```

**VERIFY:**

```bash
bash -n "$PLATFORM_REPO_DIR/env/platform-env.template" && zsh -n "$PLATFORM_REPO_DIR/env/platform-env.template" && echo "syntax OK"
head -n 1 "$PLATFORM_REPO_DIR/env/platform-env.template"
grep -c '^export ' "$PLATFORM_REPO_DIR/env/platform-env.template"
grep -n '^# ---- end of values ----$' "$PLATFORM_REPO_DIR/env/platform-env.template"
```

Expected: `syntax OK`; the first line `# ~/.platform-env: the variables file of the agentic platform
setup procedures.`; `1`; one marker line. On 2026-09-16 the extraction gave 255 lines. An empty
file means the opener in setup/01 changed: stop, do not retype the template.

**ROLLBACK:** `git -C "$PLATFORM_REPO_DIR" revert HEAD` before any value is written.

**EVIDENCE:** Commit id and `<date>-PP-1.3-extraction-hashes-v1`. E-05. TISAX 5.3.1.

### PP-1.4 Install `~/.platform-env` once and write the fixed values

**WHO:** Platform owner. **WHERE:** Same shell.

**ACTION:** setup/01 PR-2.3, with the POV's two values added, and `OWNER_DAILY_ACCOUNT` set here
as setup/01 PR-2.6 sets it, because PP-3.4 needs the address on day one. Replace the placeholder
with the address before running. 03 PF-1.1 sets the same name again; with the same value
`penv_set` prints `unchanged`.

```bash
if [ -e "$HOME/.platform-env" ]; then echo "STOP: ~/.platform-env exists; check it holds no secret, move it to $BUILD_LOG_DIR/records/retired/, re-run. Do not source it."; else install -m 600 "$PLATFORM_REPO_DIR/env/platform-env.template" "$HOME/.platform-env"; fi
source "$HOME/.platform-env"
penv_set PLATFORM_ENV_FILE "$HOME/.platform-env"
penv_set GCLOUD_CONFIG_NAME platform-bootstrap
penv_set PLATFORM_REPO_DIR "$PLATFORM_REPO_DIR"
penv_set BUILD_LOG_DIR "$BUILD_LOG_DIR"
penv_set WIKI_DIR "$WIKI_DIR"
penv_set REGION europe-west1
penv_set BQ_LOCATION EU
penv_set GE_LOCATION eu
penv_set MODEL_LOCATION eu
penv_set OWNER_DAILY_ACCOUNT "<the operator's daily address>"
penv_set DEVIATION_REGISTER "$BUILD_LOG_DIR/registers/bootstrap-deviation-register.md"
penv_set EVIDENCE_REGISTER "$BUILD_LOG_DIR/registers/evidence-register.md"
penv_set DRILL_CALENDAR "$BUILD_LOG_DIR/registers/drill-calendar.md"
penv_set POV_TRACK A
penv_set POV_STAGE POV-1
source "$PLATFORM_ENV_FILE"
```

The second `source` prints `GUARD: configuration platform-bootstrap does not exist yet; 01 PR-3.1
creates it`. That line is expected here and only here; PP-2.1 creates the configuration.

`POV_TRACK` is `A` for the whole POV (PV-04); Track B never writes it, it writes the full set's
`SANDBOX_*` and `*TWIN*` names through `twin_shell`. `POV_STAGE` moves to `POV-2` exactly once, in
the first step of [07](07-the-doer-tier-w-and-the-optional-tier-p.md), with `penv_set --force`,
which logs the change in `variables-changes.tsv`. Never source the file from `~/.zshrc`.

**VERIFY:**

```bash
ls -l "$PLATFORM_ENV_FILE" | cut -c1-10
need PLATFORM_ENV_FILE GCLOUD_CONFIG_NAME PLATFORM_REPO_DIR BUILD_LOG_DIR WIKI_DIR REGION BQ_LOCATION GE_LOCATION MODEL_LOCATION OWNER_DAILY_ACCOUNT DEVIATION_REGISTER EVIDENCE_REGISTER DRILL_CALENDAR POV_TRACK POV_STAGE && echo "values OK"
penv_set REGION europe-west4; echo "exit $?"
git -C "$PLATFORM_REPO_DIR" ls-files | grep -c 'platform-env$'
```

Expected: `-rw-------`; `values OK`; `penv_set: REFUSED: REGION is already 'europe-west1'` and
`exit 1`; `0` (the live file is never committed, only the template).

**ROLLBACK:** `rm "$HOME/.platform-env"` and repeat from the template.

**EVIDENCE:** Build-log line listing the names set, never the file. E-05. TISAX 5.3.1.

### PP-1.5 Start the checkpoint log, the re-run index and the change log

**WHO:** Platform owner. **WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** First the prefix-collision refusal of README §6.2, with the README's own check
command, run from the wiki's `pov/` folder in a subshell: it fails while any POV prefix appears in
setup/README §5.1 or any POV file writes a `PS-` or `PR-` checkpoint or `evidence_add`
(README §6.2). Nothing in this file writes a checkpoint line before it prints `prefix refusal clean`.
Then setup/01 **PR-2.4's ACTION block** unchanged except for the backfill list, which names this
file's steps. Every creation is guarded, so a resumed run destroys nothing.

```bash
need BUILD_LOG_DIR WIKI_DIR
pp_prefix_refusal() {
  _r="$BUILD_LOG_DIR/records/$(date -u +%F)-PP-1.5-prefix-refusal-v1.txt"
  ( cd "$WIKI_DIR/platform/agentic-platform/pov" || { echo "STOP: pov folder not found"; exit 2; }
    setup_prefixes=$(grep -oE '\| `[A-Z0-9]{2}` \| [0-9]{2} ' ../setup/README.md | grep -oE '`[A-Z0-9]{2}`' | tr -d '`' | sort -u)
    [ -n "$setup_prefixes" ] || echo "STOP: no prefix read from setup/README section 5.1"
    for p in PP PD PF PC PG PE PW PM PX; do echo "$setup_prefixes" | grep -qx "$p" && echo "COLLISION $p"; done
    grep -lE '(checkpoint|evidence_add) P[SR]-[0-9]' 0*.md
  ) > "$_r" 2>&1
  if [ -s "$_r" ]; then cat "$_r"; echo "STOP PP-1.5: prefix collision; no checkpoint is written (README 6.2)" >&2; return 1; fi
  echo "prefix refusal clean"
}
pp_1_5() {
pp_prefix_refusal || return 1
[ -e "$BUILD_LOG_DIR/checkpoints.tsv" ] || printf 'utc_timestamp\tstep_id\tstatus\toperator\twitness\tevidence\tnote\n' > "$BUILD_LOG_DIR/checkpoints.tsv"
[ -e "$BUILD_LOG_DIR/rerun-index.tsv" ] || printf 'date\tstep_id\tmember\twhat_to_rerun\tstatus\tdetail\n' > "$BUILD_LOG_DIR/rerun-index.tsv"
[ -e "$BUILD_LOG_DIR/variables-changes.tsv" ] || printf 'utc_timestamp\taction\tname\told_value\tnew_value\n' > "$BUILD_LOG_DIR/variables-changes.tsv"
[ -e "$BUILD_LOG_DIR/confirmations.tsv" ] || printf 'utc_timestamp\tstep_id\toperator\tquestion\tidentifier\n' > "$BUILD_LOG_DIR/confirmations.tsv"
git -C "$BUILD_LOG_DIR" add checkpoints.tsv rerun-index.tsv variables-changes.tsv confirmations.tsv records
git -C "$BUILD_LOG_DIR" diff --cached --quiet || git -C "$BUILD_LOG_DIR" commit -m "build log: headers and PP-1 records"
for step in PP-1.1 PP-1.2 PP-1.3 PP-1.4; do
  awk -F'\t' -v s="$step" '$2==s && $3=="DONE"{f=1} END{exit !f}' "$BUILD_LOG_DIR/checkpoints.tsv" || checkpoint "$step" DONE - - "backfilled at PP-1.5"
done
awk -F'\t' '$2=="PP-1.5" && $3=="DONE"{f=1} END{exit !f}' "$BUILD_LOG_DIR/checkpoints.tsv" || checkpoint PP-1.5 DONE - "build-log:checkpoints.tsv" "log started"
}; pp_1_5
```

**VERIFY:** `prefix refusal clean` printed and the `PP-1.5-prefix-refusal-v1.txt` record is empty
(a record that lists a file means a collision: the step then stops, as intended).
`awk -F'\t' '$3=="DONE"{print $2}' "$BUILD_LOG_DIR/checkpoints.tsv"` prints PP-1.1 to
PP-1.5 once each; running the whole ACTION again leaves that output identical.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD`; never rewrite history.

**EVIDENCE:** The commits and the empty, dated `<date>-PP-1.5-prefix-refusal-v1` record, registered
in PP-3.2. E-05. TISAX 5.2.1.

### PP-1.6 Check the helpers on a throwaway copy

**WHO:** Platform owner. **WHERE:** A new terminal; the real file is not touched.

**ACTION:** Run setup/01 **PR-2.5** exactly as written, in `bash -c` and then in `zsh -c`.

**VERIFY:** The output lines listed in setup/01 PR-2.5 VERIFY, in order, in both shells.

**ROLLBACK:** None; the copy is deleted by the step.

**EVIDENCE:** Build-log line "helper check passed in bash and zsh". A check of shell logic, not
evidence; no gate may cite it (S177). E-xx: none. TISAX: none.

### PP-2.1 The dedicated gcloud configuration, with no default project

**WHO:** Platform owner. **WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** setup/01 PR-3.1. `~/.platform-env` points `CLOUDSDK_CONFIG` at
`$HOME/.config/gcloud-platform-bootstrap` and exports `CLOUDSDK_ACTIVE_CONFIG_NAME`, so the
configuration is active in this shell only.

```bash
need GCLOUD_CONFIG_NAME
env -u CLOUDSDK_ACTIVE_CONFIG_NAME gcloud config configurations create "$GCLOUD_CONFIG_NAME" --no-activate
gcloud config unset project
```

`--no-activate` is required: Google documents that `create` activates the new configuration by
default.

**VERIFY:**

```bash
gcloud config configurations list --format='value(name,is_active)'
gcloud config get project 2>&1
gcloud auth list --format='value(account)'
penv_guard && echo "guard clean"
```

Expected: `platform-bootstrap` with `True`; no project value (empty or `(unset)`, an assumption
setup/01 records because Google does not document it); no account; `guard clean`. From here every
`source ~/.platform-env` runs `penv_guard`, and any `GUARD:` line is a stop.

**ROLLBACK:** Activate another configuration, `gcloud config configurations delete
"$GCLOUD_CONFIG_NAME"`, then `rm -rf "$CLOUDSDK_CONFIG"`.

**EVIDENCE:** VERIFY output under PP-2.1. E-xx: none. TISAX 5.2.2.

### PP-2.2 The start and end of every sitting

**WHO:** Platform owner. **WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** setup/01 PR-3.2's blocks, used by every sitting of files 02 to 09. The sitting id is
computed once and carried in `SITTING_ID`.

```bash
source "$HOME/.platform-env"
. "$PLATFORM_REPO_DIR/tools/pov-lib.sh"
penv_guard && echo "guard clean"
gcloud auth list --format='value(account)'
SITTING_ID="SITTING-$(date -u +%Y%m%d%H%M)"; export SITTING_ID
checkpoint "$SITTING_ID" START - - "present: platform owner alone; POV_STAGE=$POV_STAGE"
```

End of the same sitting, in the same shell:

```bash
sitting_end
checkpoint "$SITTING_ID" DONE - - "credentials revoked"
[ -z "${BUILD_LOG_REMOTE-}" ] || git -C "$BUILD_LOG_DIR" push origin main
```

A witnessed sitting passes the witness's address as the third argument and names everyone present
in the note. The push line is a no-op until PP-5.3 sets `BUILD_LOG_REMOTE`; until then the interim
copy of setup/01 §7.1 applies (a `git bundle` of the build log uploaded to
`EVIDENCE_INTERIM_LOCATION` at the end of each sitting, a copy and not a protection).

**VERIFY:** `awk -F'\t' '$2 ~ /^SITTING-/ {print $2, $3}' "$BUILD_LOG_DIR/checkpoints.tsv" | tail -n 2`
prints the **same** id twice, `START` then `DONE`; `sitting_end` printed `SITTING-END OK`.

**ROLLBACK:** None.

**EVIDENCE:** The two checkpoint lines. E-xx: none. TISAX 4.1.2.

### PP-3.1 Open the deviation register

**WHO:** Platform owner. **WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** Run setup/01 **PR-4.1's ACTION block unchanged**: the same thirteen columns, the same
`Closures` table, kinds `EXC`, `MOD`, `DEV`. The full build appends to this very file.

POV rows use one id grammar, `BD-P<file>-<n>` with the two-digit file number (for example `BD-P01-1`,
`BD-P08-3`), so they can never collide with the full set's `BD-<file>-<n>`, whose file part is
digits only. Every POV file writes this form (checked 2026-09-16: 01, 03, 05, 06, 07 and 08 write
rows; 02 cites 01's; 04 and 09 write none), so the register carries one grammar. Every POV id must
match the check below:

```bash
need DEVIATION_REGISTER
grep -oE '^\| BD-P[A-Z0-9]*-[^ ]*' "$DEVIATION_REGISTER" | grep -vE '^\| BD-P[0-9]{2}-[0-9]+$'
```

The "Module or exception" cell of a POV row names its PV-D id; the
reasoning for each PV-D lives in
[09](09-the-demonstration-deviations-and-the-hand-over.md) (`PV_DEVIATION_REGISTER`), and this
register holds only the dated operational row.

**VERIFY:** `grep -c '^| Id |' "$DEVIATION_REGISTER"` prints `2`; the file is in the last commit;
the id check above prints nothing.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD` while no row exists.

**EVIDENCE:** `<date>-PP-3.1-deviation-register-v1`. E-05. TISAX 5.2.1, 1.4.1.

### PP-3.2 Open the evidence register

**WHO:** Platform owner. **WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** Run setup/01 **PR-4.2's ACTION block**, with its closing lines replaced by:

```bash
evidence_add PP-1.1 workstation-tools E-05 5.3.1 "build-log:records/tools.txt" "$BUILD_LOG_DIR/records/tools.txt"
f="$(ls "$BUILD_LOG_DIR"/records/*-PP-1.3-extraction-hashes-v1.txt | tail -n 1)"
evidence_add PP-1.3 extraction-hashes E-05 5.3.1 "build-log:records/$(basename "$f")" "$f"
f="$(ls "$BUILD_LOG_DIR"/records/*-PP-1.5-prefix-refusal-v1.txt | tail -n 1)"
[ ! -s "$f" ] && evidence_add PP-1.5 prefix-refusal E-05 5.2.1 "build-log:records/$(basename "$f")" "$f"
checkpoint PP-3.2 DONE - "build-log:registers/evidence-register.md"
```

The E-xx and TISAX ids come from setup/01 §7.2. The POV adds these mappings, each taken from the
closest §7.2 row as that section requires:

| POV record | E-xx | TISAX |
|---|---|---|
| Retrospective toil baseline and its calibration sample (02) | E-09 | 1.5.1 |
| Tier C, R and W gate records (04, 05, 07) | E-03 | 1.1-1.2 |
| Register rows, `audit.schema`, `ladder.schema`, the signed manual parse (04) | E-05 | 1.3.1; 5.2.1 |
| Eve's roster diff, reports and fingerprint recomputation (06) | E-06 | 4.1.3; 1.5.1 |
| Kill drills K0 to K4, K7, restore drill (03, 05, 07, 09) | E-08 | 5.2.6; 5.2.9 for restore |
| Value report and Mo digest (08) | E-09 | 1.5.1 |
| Demonstration record, gap statement, stop-or-continue record (09) | E-05; E-03 for the decision | 1.5.1; 1.4.1 |
| `confirmations.tsv` lines | as the step that asked | as the step that asked |

**VERIFY:** `tail -n 3 "$EVIDENCE_REGISTER"` shows three rows with 64-character SHA-256 values.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert` the commits while they are the only rows.

**EVIDENCE:** The commits. E-05. TISAX 1.5.1.

### PP-3.3 Open the drill calendar with the POV's drills

**WHO:** Platform owner. **WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** Run setup/01 **PR-4.3's ACTION block** (header and the full-set rows DR-06-1 to
DR-38-1, left unopened for the full build), then append the POV rows before committing:

```bash
need DRILL_CALENDAR
cat >> "$DRILL_CALENDAR" <<'ROWS'
| DR-P01-1 | Git host bypass audit and humans-only access listing (setup/03 DC-9.8, DC-9.9 interim) | weekly | second person | none | POV 01 PP-5.5 | *tbd* | | | PV-D-13 |
| DR-P03-1 | Break-glass envelope opened, signed in, nothing activated, re-sealed | quarterly | custodian | other administration line | POV 03 | *tbd* | | | setup DR-06-1 |
| DR-P03-2 | K7 fleet lever, dry run then enforced, on a nonprod tier folder, pulled by a person | before POV 05, then younger than 30 days at the demonstration | platform owner | second person for the enforced pull | POV 03 | *tbd* | | | K7; PB none (B-04 by hand) |
| DR-P05-1 | K1, K2, K3 and K7 on the two Tier C rows, timed; the token residue measured in POV 07 PW-6.5 recorded | once, then before the demonstration | platform owner | second person | POV 05 | *tbd* | | | POV_TIER_C_RECORD |
| DR-P06-1 | Unannounced seeded super-admin action reported by Eve | once in POV-1, then after every eve/config change | second person records the result | third person | POV 06 | *tbd* | | | POV_EVE_PROOF_RECORD |
| DR-P06-2 | Eve configuration fingerprint recomputed independently | weekly (Assumption) | second person | none | POV 06 | *tbd* | | | PV-D-03 |
| DR-P07-1 | K0 pulled during a live L3 run, then K1 | once before the demonstration | any operator | second person | POV 07 | *tbd* | | | POV_TIER_W_RECORD |
| DR-P07-2 | Restore of the doer's audit dataset and Firestore | once before `POV_TIER_W_RECORD` | platform owner | third person | POV 07 | *tbd* | | | POV_TIER_W_RECORD |
| DR-P07-3 | K6-style drill on the optional Tier P row (does not close G11) | once, optional | platform owner | second and third persons | POV 07 part 7 | *tbd* | | | PV-D-09 |
| DR-P09-1 | Demonstration drills: K0 by the third person, K1, K3, K4, K7 timed | once | as named in 09 | second person | POV 09 | *tbd* | | | POV_DEMO_RECORD |
| DR-P09-2 | Two-hour tabletop | once | incident commander | security reviewer or third person | POV 09 | *tbd* | | | POV_TABLETOP_RECORD |
ROWS
git -C "$BUILD_LOG_DIR" add "$DRILL_CALENDAR"
git -C "$BUILD_LOG_DIR" commit -m "registers: drill calendar with POV rows"
checkpoint PP-3.3 DONE - "build-log:registers/drill-calendar.md"
```

**VERIFY:** `grep -c '^| DR-' "$DRILL_CALENDAR"` prints `20` (9 full-set rows, 11 POV rows);
`grep -c '^| DR-P' "$DRILL_CALENDAR"` prints `11`.

**ROLLBACK:** `git -C "$BUILD_LOG_DIR" revert HEAD` before any file opens a row.

**EVIDENCE:** The commit. E-08. TISAX 5.2.6.

### PP-3.4 The interim evidence location

**WHO:** Second person creates and manages it; the platform owner is Contributor only.
**WHERE:** drive.google.com signed in as the second person → Shared drives → New; then the drive
→ its name menu → Manage members.

**ACTION:** setup/01 **PR-4.4 as written**: shared drive `agentic-platform-evidence-interim`; the
second person Manager; `OWNER_DAILY_ACCOUNT` (set in PP-1.4) Contributor; external and non-member access
off. The platform owner records the id:

```bash
penv_set EVIDENCE_INTERIM_LOCATION "<shared drive id>"
confirm_manual PP-3.4 "Which member list did the second person read back on Manage members? Type the two addresses separated by a comma"
checkpoint PP-3.4 DONE "<second person's name until 02 sets SECOND_HUMAN_EMAIL>" - "created by the second person"
```

Type the real name in place of the placeholder; `checkpoint` refuses a `<placeholder>`. 02 appends
a correcting line with `SECOND_HUMAN_EMAIL` once it exists.

**VERIFY:** The platform owner uploads a one-line test PDF and finds "Move to trash" absent or
refused: Google documents that Contributors cannot move files to trash or delete them.

**ROLLBACK:** The second person deletes the drive while it is empty.

**EVIDENCE:** `<date>-PP-3.4-interim-location-members-v1`, a dated screenshot in the drive,
registered with `evidence_add`. E-08. TISAX 5.2.4, 3.1.1-3.1.4.

### PP-3.5 The retired and reserved names check (`RETIRED_NAMES_CHECK`)

**WHO:** Platform owner; the second person reviews the commit in PP-6.1.
**WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** The full set's rule (setup/README §5) names retired variables; the POV extends it with
the names PV-02 reserves for Wall-E, so that a POV step cannot spend a permanent name at the wrong
tier. The check reads only `bash` fences, where a name would be created or used. A step that must
**assert** a reserved name's absence, or record a reservation (02, 04, 07, 08), wraps those lines
between `# names-check: off PV-02` and `# names-check: on`; the check counts exempted lines so a
reviewer sees how many there are. The check reads only the Markdown files it is given, so
`register/reserved/names.yaml` (04) needs no allow-list: it is never passed to the check.
The block below is the only other user of that marker, because it holds the patterns themselves.

```bash
# names-check: off PV-02
cat > "$PLATFORM_REPO_DIR/tools/pov-names-check.sh" <<'EOF'
#!/usr/bin/env bash
# pov-names-check.sh FILE...: exits 1 when a bash fence of a POV file names a retired or reserved name.
set -uo pipefail
[ $# -ge 1 ] || { echo "usage: pov-names-check.sh FILE..." >&2; exit 2; }
perl -e '
  my @pat = (
    [qr/\bwalle/,                    "reserved for Wall-E (PV-02)"],
    [qr/\bWALLE_/,                   "reserved for Wall-E (PV-02)"],
    [qr/\bwall-e\b/i,                "reserved for Wall-E (PV-02)"],
    [qr/\bEVE_WITNESS_PROJECT\b/,    "reserved, no witness organisation (PV-D-03)"],
    [qr/\bSA_WALLE_CI\b/,            "retired (setup/README 5)"],
    [qr/\bLOGS_DATASET\b/,           "retired (setup/README 5)"],
    [qr/\bFOLDER_ID\b/,              "retired (setup/README 5)"],
    [qr/\bBILLING\b/,                "retired (setup/README 5)"],
    [qr/\bPROJECT\b/,                "retired outside walle_shell (setup/README 5)"],
    [qr/\bCUSTOMER_ID\b/,            "retired; use DIRECTORY_CUSTOMER_ID (setup/01 PR-2.2)"],
    [qr/my_customer/,                "retired in policies (setup/README 5)"],
    [qr/(^|\s)--yes\b/,              "never --yes (absolute 9)"],
    [qr/gcloud\s+config\s+set\s+project/, "no default project (absolute 9)"],
    [qr/CLOUDSDK_CORE_PROJECT=/,     "no default project (absolute 9)"],
  );
  my ($rc, $hits, $off) = (0, 0, 0);
  for my $f (@ARGV) {
    open(my $h, "<", $f) or do { print "UNREADABLE $f\n"; $rc = 2; next };
    my ($in, $skip) = (0, 0);
    while (my $l = <$h>) {
      if (!$in && $l =~ /^```bash\s*$/) { $in = 1; next }
      if ($in && $l =~ /^```\s*$/) { $in = 0; $skip = 0; next }
      next unless $in;
      if ($l =~ /^# names-check: off PV-02$/) { $skip = 1; next }
      if ($l =~ /^# names-check: on$/)        { $skip = 0; next }
      if ($skip) { $off++; next }
      for my $p (@pat) { if ($l =~ $p->[0]) { chomp $l; print "HIT $f:$.: $p->[1]: $l\n"; $hits++; $rc = 1 if $rc == 0; last } }
    }
    print "UNCLOSED $f: a fence is not closed\n", $rc = 1 if $in;
  }
  print "names-check: $hits hit(s), $off exempted line(s), ", scalar(@ARGV), " file(s)\n";
  exit $rc;
' "$@"
EOF
chmod +x "$PLATFORM_REPO_DIR/tools/pov-names-check.sh"
t="$(mktemp -d)"
printf '%s\n' '```bash' 'bq ls "$WALLE_PROJECT"' 'echo walle_audit' 'penv_set CUSTOMER_ID x' 'gcloud x --yes' '```' > "$t/bad.md"
# names-check: on
printf '%s\n' '```bash' 'penv_set BILLING_ACCOUNT_ID x' 'need DIRECTORY_CUSTOMER_ID' '```' > "$t/good.md"
"$PLATFORM_REPO_DIR/tools/pov-names-check.sh" "$t/bad.md"; echo "bad exit $?"
"$PLATFORM_REPO_DIR/tools/pov-names-check.sh" "$t/good.md"; echo "good exit $?"
rm -rf "$t"
penv_set RETIRED_NAMES_CHECK "$PLATFORM_REPO_DIR/tools/pov-names-check.sh"
git -C "$PLATFORM_REPO_DIR" add tools/pov-names-check.sh
git -C "$PLATFORM_REPO_DIR" commit -m "PP-3.5 POV retired and reserved names check"
```

**VERIFY:** `bad exit 1` after four `HIT` lines (Wall-E project, `walle_audit`, `CUSTOMER_ID`,
`--yes`); `good exit 0`. Then the check over the POV files that exist on the day:

```bash
"$RETIRED_NAMES_CHECK" "$WIKI_DIR"/platform/agentic-platform/pov/*.md; echo "exit $?"
```

Expected `exit 0`, and an exempted-line count of 44 for this file (the PP-3.5 block between its
markers, counted on 2026-09-16) plus the lines 02, 04, 07 and 08 wrap. 02 to 09 each run it in
their closing step.

**Lines the other files wrap.** The reserved-name lines in the other files are assertions or
reservations, not uses, and each sits between the markers: the doer-id check in 02 PD-3.1; in 04,
the doer-id check in PC-0.1, the reservation heredoc in PC-1.3, the reserved dataset count in
PC-2.5 and the manifest count in PC-3.4; and the preflight grep in 08 PM-0.1. This file does not
loosen a pattern to make the run pass. If the check exits non-zero, PP-3.5 and PP-6.1 are not
`DONE`: write a `PENDING` checkpoint for PP-3.5 whose note gives the hit count and the files, typed
from the output (`checkpoint` refuses a placeholder), and re-run the check when those files change.
The exempted-line count is read on the day and written in the record, not taken from this page.

**ROLLBACK:** `git -C "$PLATFORM_REPO_DIR" revert HEAD`; `penv_set --force RETIRED_NAMES_CHECK "*tbd*"`.

**EVIDENCE:** The commit and the VERIFY output, `<date>-PP-3.5-names-check-v1`. E-15 (content
test). TISAX 5.3.1.

### PP-4.1 The three decision tools and the POV tracker

**WHO:** Platform owner; the second person is the bootstrap reviewer of setup/03 DC-1.2 and
reviews the commit. **WHERE:** Shell, `~/.platform-env` sourced.

**ACTION:** Extract setup/03 DC-1.1's template and DC-1.2's three tools verbatim, then create the
tracker with one row per POV decision. 02 fills the records.

```bash
. "$PLATFORM_REPO_DIR/tools/pov-lib.sh"
S3="$WIKI_DIR/platform/agentic-platform/setup/03-decisions-and-people.md"
pov_extract "$S3" "cat > \"\$PLATFORM_REPO_DIR/decisions/_template.md\" <<'EOF'" EOF > "$PLATFORM_REPO_DIR/decisions/_template.md"
for t in check need value; do pov_extract "$S3" "cat > \"\$PLATFORM_REPO_DIR/tools/decision-$t.sh\" <<'EOF'" EOF > "$PLATFORM_REPO_DIR/tools/decision-$t.sh"; done
chmod +x "$PLATFORM_REPO_DIR"/tools/decision-*.sh
{ printf '| Id | Title | Record | Gates | Signatories | Status |\n|---|---|---|---|---|---|\n'
  for i in 01 02 03 04 05 06 07 08 09 10 11 12 13; do printf '| PV-%s | see POV 02 | *tbd* | see POV README | see POV 02 | open |\n' "$i"; done; } > "$PLATFORM_REPO_DIR/decisions/TRACKER.md"
shasum -a 256 "$S3" "$PLATFORM_REPO_DIR"/decisions/_template.md "$PLATFORM_REPO_DIR"/tools/decision-*.sh >> "$BUILD_LOG_DIR/records/$(date -u +%F)-PP-1.3-extraction-hashes-v1.txt"
git -C "$PLATFORM_REPO_DIR" add decisions tools
git -C "$PLATFORM_REPO_DIR" commit -m "PP-4.1 decision tools (verbatim from setup/03 DC-1.1, DC-1.2) and POV tracker"
```

Rows for full-set decisions the POV inherits (SD-xx, NAMES, KEYS, P22) are added by 02 when it
signs PV-03 and records which full-set records it adopts; the tools read any id the same way.

**VERIFY:** Run setup/03 **DC-1.2's VERIFY fixtures** unchanged: `OK   2026-09-15-fixture.md
<hash>`, then two `signed a different body` failures and `exit=1`. Then
`"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-01; echo "exit $?"` prints `UNSIGNED PV-01` and
`exit 1`; `grep -c '^## ' "$PLATFORM_REPO_DIR/decisions/_template.md"` prints `7`.

**ROLLBACK:** `git -C "$PLATFORM_REPO_DIR" revert HEAD` before any record exists.

**EVIDENCE:** Commit id, fixture output, the appended hash lines, the reviewer's mail quoting the
commit in `EVIDENCE_INTERIM_LOCATION` as `<date>-PP-4.1-review-v1`. The reviewer named but not yet
appointed is row `BD-P01-1` (the POV form of setup/03's `BD-03-1`), opened here and closed by 02's
appointment record. E-03, E-05. TISAX 1.1-1.2, 5.2.1.

## Part B. The git host (after 02 has signed PV-03 and PV-09)

`Assumption:` the git host is GitHub, as setup/03 §12 is written; if the inherited P22 record
names GitLab, setup/03 §12.1 gives the settings and this part is re-issued as a dated revision
first. Every step opens with `source ~/.platform-env` and
`"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-03 PV-09`.

### PP-5.1 Review list and the two private repositories

**WHO:** Platform owner as organisation owner on the git host; the second operator confirms the
exempt list. **WHERE:** Shell; `gh auth status` signed in.

**ACTION:** setup/03 DC-9.1 (every local commit has a `reviews/<sha>.md` record or sits in
`BD-P01-1`'s exempt list), then DC-9.2 for both repositories. Names come only from the signed
PV-03 record.

**Person 3 must be appointed before this step** (README §5.1a). The `need` below refuses
`SECOND_OPERATOR_EMAIL` while it is `*tbd*`, and PP-5.4's protection needs two human approvers who
are not the author. If 02 has not appointed person 3, stop here: Part B, the push, and every file
from 03 onward wait. Do not lower the approval count to proceed.

```bash
need PLATFORM_REPO_DIR BUILD_LOG_DIR SECOND_HUMAN_EMAIL SECOND_OPERATOR_EMAIL
org="<git-host-organisation>"
case "$org" in ''|*'<'*'>'*) echo "STOP: type the organisation";; *) penv_set GIT_ORG "$org";; esac
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-03 PLATFORM_REPO_NAME) && penv_set PLATFORM_REPO_SLUG "$GIT_ORG/$v"
v=$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PV-03 BUILD_LOG_REPO_NAME) && penv_set BUILD_LOG_REPO_SLUG "$GIT_ORG/$v"
need GIT_ORG PLATFORM_REPO_SLUG BUILD_LOG_REPO_SLUG
gh repo create "$PLATFORM_REPO_SLUG" --private --disable-wiki --description "Agentic platform: register, schemas, ladder, decisions"
gh repo create "$BUILD_LOG_REPO_SLUG" --private --disable-wiki --description "Agentic platform build log and registers"
```

**VERIFY:** `gh repo view "$PLATFORM_REPO_SLUG" --json visibility --jq .visibility` and the same
for `BUILD_LOG_REPO_SLUG` print `PRIVATE`; DC-9.1's `03-prepush-unreviewed.txt` (named
`P01-prepush-unreviewed.txt` here) is empty.

**ROLLBACK:** Before any push, `gh repo delete` each (it asks for confirmation; answer by typing
the name, never with a flag).

**EVIDENCE:** Build-log line with both slugs; the exempt list and confirmation mail. E-05. TISAX
5.2.1, 1.4.1.

### PP-5.2 Humans-only write access and CODEOWNERS

**WHO:** Platform owner writes; the second person reviews and confirms their verified address.
**WHERE:** Shell; git host organisation settings.

**ACTION:** setup/03 **DC-9.3 and DC-9.4 as written**, for the platform repository: write access
through a team of named humans only (platform owner, second person, second operator); no bot,
machine user or app with write. CODEOWNERS puts `SECOND_HUMAN_EMAIL` (or `@<login>` where the
address cannot be proven verified) on `/roster/`, `/control-groups/`, `/eve/`, `/oncall/`,
`/ladder/`, `/decisions/`, `/tools/decision-*` and `/.github/`. The POV adds two lines, under the
same owner, for the paths that decide what the POV may create:

```bash
need SECOND_HUMAN_EMAIL
printf '%s\n' "/register/          $SECOND_HUMAN_EMAIL" "/tools/pov-*       $SECOND_HUMAN_EMAIL" >> "$PLATFORM_REPO_DIR/.github/CODEOWNERS"
git -C "$PLATFORM_REPO_DIR" add .github/CODEOWNERS
git -C "$PLATFORM_REPO_DIR" commit -m "PP-5.2 CODEOWNERS: register and POV tools"
```

The build-log repository gets write for the platform owner and the second person only.

**VERIFY:** `grep -c "$SECOND_HUMAN_EMAIL" "$PLATFORM_REPO_DIR/.github/CODEOWNERS"` prints `10`;
DC-9.3's `awk` over the collaborator listing prints nothing for either repository.

**ROLLBACK:** Revert the commit; remove a grant with `gh api -X DELETE`.

**EVIDENCE:** Dated collaborator listings, the two verification replies, the commit. E-xx: none
(repository configuration, setup/01 §7.2). TISAX 4.1.3, 5.2.1, 5.3.1.

### PP-5.3 Push both histories

**WHO:** Platform owner; witness: the second person on screen. **WHERE:** Shell.

> **IRREVERSIBLE**: pushed history. Once `main` exists on the git host it is the base of every
> later pull request and PP-5.4 forbids force-push and deletion; a mistake is corrected by a
> reverting commit, never by a rewrite. Confirm before running: PP-5.1's unreviewed list is empty
> and `BD-P01-1` is in the register; both repositories read `PRIVATE`; `git log --oneline` of each
> repository is read aloud; `grep -rIiE 'password|secret|token' "$PLATFORM_REPO_DIR" "$BUILD_LOG_DIR"`
> shows only prose and names, never a value. Gate: PV-03 and PV-09 signed (`decision-need.sh`).

```bash
"$PLATFORM_REPO_DIR/tools/decision-need.sh" PV-03 PV-09 || echo "STOP: gate records missing; do not push"
checkpoint PP-5.3 START "$SECOND_HUMAN_EMAIL" - "irreversible: initial push of both repositories"
git -C "$PLATFORM_REPO_DIR" remote add origin "https://github.com/$PLATFORM_REPO_SLUG.git"
git -C "$PLATFORM_REPO_DIR" push -u origin main
git -C "$BUILD_LOG_DIR" remote add origin "https://github.com/$BUILD_LOG_REPO_SLUG.git"
git -C "$BUILD_LOG_DIR" push -u origin main
penv_set PLATFORM_REPO_REMOTE "https://github.com/$PLATFORM_REPO_SLUG.git"
penv_set BUILD_LOG_REMOTE "https://github.com/$BUILD_LOG_REPO_SLUG.git"
checkpoint PP-5.3 DONE "$SECOND_HUMAN_EMAIL" - "BD-P01-2 opened"
```

Open `BD-P01-2` (initial push without a pull request, superseded by PP-5.4) in the first table of
`DEVIATION_REGISTER` with setup/03 DC-9.5's `awk` insertion, then commit and push the build log.

**VERIFY:** For each repository, `git rev-parse HEAD` equals
`gh api "repos/<slug>/branches/main" --jq .commit.sha`; `need PLATFORM_REPO_REMOTE BUILD_LOG_REMOTE`
is silent; the `BD-P01-2` row's line number is smaller than the `## Closures` line's.

**ROLLBACK:** **None for pushed history.**

**EVIDENCE:** Push output, the sha pairs, the witness line, `BD-P01-2`. E-05. TISAX 5.2.1, 1.4.1.

### PP-5.4 Branch protection and the negative tests

**WHO:** Platform owner applies; the second person witnesses; the second operator approves once in
the negative test. **WHERE:** Shell.

**ACTION:** Platform repository: setup/03 **DC-9.6** exactly (precondition
`codeowners/errors?ref=main` length `0`; body with `required_approving_review_count: 2`,
`require_code_owner_reviews`, `dismiss_stale_reviews`, `require_last_push_approval`,
`enforce_admins: true`, `allow_force_pushes: false`, `allow_deletions: false`,
`required_linear_history: true`). Two approvals are kept, not reduced to one: GitHub does not let
authors approve their own pull requests, so with the platform owner authoring, the second person
and the second operator approve; a pull request waiting on the second operator is recorded
`PENDING`, never merged on one approval (PV-D-14 keeps the two-person rules intact).

Build-log repository: the `checkpoint` helper commits directly, so the protection forbids rewrite
and deletion without requiring pull requests, as setup/01 §7.1 proposes:

```bash
need BUILD_LOG_REPO_SLUG
p="$(mktemp)"
printf '%s\n' '{"required_status_checks": null, "enforce_admins": true, "required_pull_request_reviews": null, "restrictions": null, "allow_force_pushes": false, "allow_deletions": false}' > "$p"
gh api -X PUT "repos/$BUILD_LOG_REPO_SLUG/branches/main/protection" --input "$p"
rm "$p"
```

Then setup/03 **DC-9.7**'s negative tests on the platform repository.

**VERIFY:** DC-9.6's `jq` read prints `reviews` 2, `codeowners` true, `lastpush` true, `admins`
true, `force` false, `deletions` false. On the build log,
`gh api "repos/$BUILD_LOG_REPO_SLUG/branches/main/protection" --jq '[.enforce_admins.enabled, .allow_force_pushes.enabled, .allow_deletions.enabled]'`
prints `[true,false,false]`, and `git push --force origin main` from a scratch clone is refused.
DC-9.7: the direct push fails and the one-approval pull request reads `BLOCKED` and
`REVIEW_REQUIRED`.

**ROLLBACK:** Removing protection only under a signed superseding record; the removal is audited
by PP-5.5.

**EVIDENCE:** Both protection reads, the refusal texts, the witness line; close `BD-P01-2` with a
Closures line naming PP-5.4. E-xx: none (branch protection, setup/01 §7.2). TISAX 5.2.1, 5.3.1.

### PP-5.5 Bypass audit and the bot-approval rule

**WHO:** The second person runs the weekly audit from their own workstation; the platform owner never
runs it alone. **WHERE:** Shell as a git-host organisation owner.

> **BLOCKED**: Needs: the bot-approval CI rule of setup/03 DC-9.9, which fails a pull request
> approved by any account not on an appointment record. Commit it in: the platform repository,
> `.github/workflows/bot-approval.yml`. Unblocked by: its commit with a green run on a test pull
> request, recorded with `penv_set BOT_APPROVAL_RULE_COMMIT <sha>`, then added to PP-5.4's
> `required_status_checks`. Gate waiting: the first Mo merge in
> [08](08-mo-and-the-value-report.md), where "two humans who are neither the author nor a Mo
> identity" must be provable. Estimate, `Assumption:` 0.5 to 1 engineer-day. Until then:
> `checkpoint PP-5.5 BLOCKED - - "bot-approval rule not committed"`, and a row in README's BLOCKED
> index beside B-03 (PV-D-13).

**ACTION (the interim control, run now):** setup/03 **DC-9.8's block** for `PLATFORM_REPO_SLUG`
and `BUILD_LOG_REPO_SLUG`, and DC-9.3's collaborator listing, weekly, as drill `DR-P01-1`.

**VERIFY:** `gh api "orgs/$GIT_ORG" --jq .login` prints the organisation (an empty audit log from a
mistyped name reads like a clean week); after the set-up day the audit file has `0` lines; every
collaborator row has type `User`. Any override or `destroy` line is raised to the incident
commander the same day.

**ROLLBACK:** None; read only.

**EVIDENCE:** The dated audit and listing files, kept even when empty; the `DR-P01-1` record id.
E-06. TISAX 5.2.1, 1.5.1.

### PP-6.1 The second person's recomputation and the close of part 01

**WHO:** Second person recomputes and signs, on their own workstation, without the platform owner;
the platform owner then closes. **WHERE:** The second person's shell with a fresh clone of `PLATFORM_REPO_REMOTE`
and the wiki; then the platform owner's shell, `~/.platform-env` sourced.

**ACTION:** The second person extracts the template, the record template and the three tools from
the wiki themselves with the `pov_extract` function of `tools/pov-lib.sh`, computes their SHA-256, and
compares them with the committed files and with `<date>-PP-1.3-extraction-hashes-v1`. They read
`tools/pov-names-check.sh` line by line and run it over `pov/*.md`. They sign a one-page record
`<date>-PP-6.1-conventions-recomputation-v1` ("hashes match: yes/no; names check reviewed:
agreed/corrections") and uploads it as PDF to `EVIDENCE_INTERIM_LOCATION`. The platform owner then:

```bash
need PLATFORM_ENV_FILE PLATFORM_REPO_DIR BUILD_LOG_DIR WIKI_DIR REGION BQ_LOCATION EVIDENCE_REGISTER DEVIATION_REGISTER DRILL_CALENDAR EVIDENCE_INTERIM_LOCATION RETIRED_NAMES_CHECK POV_TRACK POV_STAGE PLATFORM_REPO_REMOTE BUILD_LOG_REMOTE
penv_guard && echo "guard clean"
"$RETIRED_NAMES_CHECK" "$WIKI_DIR"/platform/agentic-platform/pov/*.md; echo "names exit $?"
evidence_add PP-6.1 conventions-recomputation E-05 5.3.1 "interim:<file name>.pdf" "$HOME/Downloads/<file name>.pdf"
rm -f "$HOME/Downloads/<file name>.pdf"
grep -n '<[^>]*>' "$BUILD_LOG_DIR/checkpoints.tsv" && echo "FAIL: placeholder in the log" || echo "no placeholder in the log"
checkpoint PP-6.1 DONE "$SECOND_HUMAN_EMAIL" "interim:<file name>.pdf" "part 01 complete"
git -C "$BUILD_LOG_DIR" push origin main
sitting_end
```

**VERIFY:** `need` silent; `guard clean`; `names exit 0`; the second person's record says "hashes
match: yes"; the DONE list holds PP-1.1 to PP-6.1 once each (PP-5.5 as `BLOCKED` plus its interim
lines); PP-3.4, PP-5.3 and PP-6.1 carry a witness other than `-`; `no placeholder in the log`;
`SITTING-END OK`; the build log's remote `main` equals the local `HEAD`.

**ROLLBACK:** None; a changed view is a `v2` record.

**EVIDENCE:** `<date>-PP-6.1-conventions-recomputation-v1`. E-05, E-08. TISAX 5.3.1, 1.2.2.

## Verification checklist for part 01

- [ ] Tools recorded; FileVault on; working area and both repositories outside synced folders.
- [ ] `env/platform-env.template`, `decisions/_template.md` and the three `decision-*.sh` tools are
      byte-identical to the wiki's heredocs, recomputed by the second person, not the operator.
- [ ] `~/.platform-env` is mode 600, not committed, holds no secret, and `need` passes for every
      name in "What the next file needs".
- [ ] `penv_guard` clean: no gcloud project, no `CLOUDSDK_CORE_PROJECT`, no `PROJECT`, no bq
      default project; no credential left after `sitting_end`.
- [ ] `checkpoints.tsv`, `rerun-index.tsv`, `variables-changes.tsv`, `confirmations.tsv` exist
      and are committed; PP-1.5 re-run changes nothing.
- [ ] `DEVIATION_REGISTER` in setup/01 PR-4.1's form, with `BD-P01-1` open until 02 and
      `BD-P01-2` closed by PP-5.4.
- [ ] `EVIDENCE_REGISTER` in setup/01 PR-4.2's form, with the POV mapping rows applied.
- [ ] `DRILL_CALENDAR` has 20 rows, 11 of them `DR-P`.
- [ ] `EVIDENCE_INTERIM_LOCATION`: the second person Manager, the platform owner Contributor.
- [ ] `RETIRED_NAMES_CHECK` fails its bad fixture, passes its good one, and exits 0 over `pov/`
      (the reserved-name assertions of 02 PD-3.1, 04 PC-0.1, PC-1.3, PC-2.5, PC-3.4 and 08 PM-0.1
      sit between the `# names-check` markers).
- [ ] PP-1.5's prefix-collision refusal printed nothing before the first checkpoint line.
- [ ] Person 3 was appointed before PP-5.1; `SECOND_OPERATOR_EMAIL` is not `*tbd*`.
- [ ] Every POV row id in `DEVIATION_REGISTER` passes PP-3.1's id check.
- [ ] `decision-need.sh PV-01` refuses before 02; the tamper fixture fails.
- [ ] Both repositories private, humans-only write, pushed, protected; the platform repository
      needs two approvals including a code owner; the build log refuses force-push and deletion.
- [ ] PP-5.5 is `BLOCKED` with its weekly interim audit on the calendar.

## What the next file needs from this one

| File | Needs |
|---|---|
| [02](02-decisions-people-and-the-retrospective-baseline.md) | `PLATFORM_ENV_FILE`, `PLATFORM_REPO_DIR`, `BUILD_LOG_DIR`, `OWNER_DAILY_ACCOUNT`, `EVIDENCE_REGISTER`, `EVIDENCE_INTERIM_LOCATION`, `DEVIATION_REGISTER`, the decision tools and `decisions/TRACKER.md` with rows PV-01 to PV-13, `confirm_manual`. **02 must also:** carry the `PD` prefix before 01 writes its first checkpoint (PP-1.5); appoint person 3 and set `SECOND_OPERATOR_EMAIL` before 01 Part B (README §5.1a); wrap PD-3.1's reserved-name assertion in the `# names-check` markers; put `PLATFORM_REPO_NAME` and `BUILD_LOG_REPO_NAME` in PV-03's Values table (Part B reads both); close `BD-P01-1` with the appointment record; append correcting checkpoint lines for PP-3.4 with `SECOND_HUMAN_EMAIL` |
| 01 Part B | returns here after 02; then `PLATFORM_REPO_REMOTE`, `BUILD_LOG_REMOTE`, `GIT_ORG`, `PLATFORM_REPO_SLUG`, `BUILD_LOG_REPO_SLUG` exist |
| [03](03-foundation-folders-logging-and-floors.md) | `REGION`, `BQ_LOCATION`, `OWNER_DAILY_ACCOUNT` (PF-1.1's `penv_set` of the same value prints `unchanged`), `DRILL_CALENDAR` rows DR-P03-1 and DR-P03-2; creates `PLATFORM_EVIDENCE_BUCKET` with setup/42 GD-3.1's commands (reason above). 03 sets the tenant identifiers with their full-set names: `DIRECTORY_CUSTOMER_ID`, **never `CUSTOMER_ID`**, which `penv_set` refuses and the names check fails |
| [04](04-the-contract-register-agent-ids-and-schemas.md), [07](07-the-doer-tier-w-and-the-optional-tier-p.md) | the `PC` prefix in 04 before 01 writes its first checkpoint; the `# names-check: off PV-02` marker for reserved-name assertions (04 PC-0.1, PC-1.3, PC-2.5, PC-3.4); person 3 appointed before 01 Part B, because 04 PC-0.1 needs `SECURITY_REVIEWER_EMAIL` and `BLIND_GRADER_EMAIL`; CODEOWNERS on `/register/` and `/ladder/`; 07's first step moves `POV_STAGE` to `POV-2` with `--force` |
| [05](05-gemini-enterprise-and-tier-c.md), [06](06-eve-over-the-human-super-admins.md), [07](07-the-doer-tier-w-and-the-optional-tier-p.md), [09](09-the-demonstration-deviations-and-the-hand-over.md) | `GE_LOCATION`, `MODEL_LOCATION`; their `DR-P` rows; `confirm_manual` for every human judgement |
| [08](08-mo-and-the-value-report.md) | the two-approval protection and PP-5.5's BLOCKED rule for the first merge; the `# names-check` markers around PM-0.1's reserved-name grep |
| Every file | the step format, the helpers, the sitting blocks of PP-2.2, a closing run of `RETIRED_NAMES_CHECK` |
| Full build | the same `~/.platform-env`, logs, registers and repositories; setup/01 is not re-run, only its steps not covered here (PR-2.6, PR-3.3, PR-5.2) |

## Sources, checked on 2026-09-16

- `gcloud config configurations create`; `--activate` is enabled by default, `--no-activate`
  disables it: https://docs.cloud.google.com/sdk/gcloud/reference/config/configurations/create
- `CLOUDSDK_ACTIVE_CONFIG_NAME`, `CLOUDSDK_CONFIG`, `gcloud config unset project`:
  https://docs.cloud.google.com/sdk/docs/configurations
- `gcloud config get` prints the property from the active configuration; unset behaviour not
  documented: https://docs.cloud.google.com/sdk/gcloud/reference/config/get
- `gcloud auth revoke --all`: https://docs.cloud.google.com/sdk/gcloud/reference/auth/revoke
- `gcloud auth application-default revoke` deletes the local ADC file:
  https://docs.cloud.google.com/sdk/gcloud/reference/auth/application-default/revoke
- Shared drive Contributors cannot move files to trash or delete them:
  https://support.google.com/a/users/answer/12380484
- GitHub "Update branch protection" body parameters (`required_status_checks`, `enforce_admins`,
  `required_pull_request_reviews`, `restrictions` required, may be null; `allow_force_pushes`,
  `allow_deletions`, `required_linear_history` optional):
  https://docs.github.com/en/rest/branches/branch-protection#update-branch-protection
- GitHub "List CODEOWNERS errors", `ref` defaults to the default branch:
  https://docs.github.com/en/rest/repos/repos#list-codeowners-errors
- "Pull request authors cannot approve their own pull requests":
  https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/approving-a-pull-request-with-required-reviews
- Everything else is cited from the full set, which records its own sources: setup/01 §14 and
  setup/03 §12.

## Unverified

- Whether `gcloud config get project` prints an empty line or `(unset)` for an unset property:
  Google does not document it; `penv_guard` handles both and checks the exit status (setup/01).
- That the git host is GitHub and that the organisation's plan exposes the audit-log API used by
  PP-5.5 (setup/03 DC-9.8 carries the same assumption).
- That `gh repo create` and `gh api` behave as setup/03 §12 records; the GitHub CLI manual was not
  re-read on 2026-09-16.
- That a build-log protection with `required_pull_request_reviews: null` still refuses force-push
  and deletion for administrators when `enforce_admins` is true: the parameter page lists the
  fields but does not state their interaction; PP-5.4's scratch-clone force push is the test.
- `confirm_manual`'s `[ -t 0 ]` interactivity test under zsh and bash on macOS: run it once in
  each shell before 03 relies on it.
- `perl` shipping with the current macOS release: PP-1.1 records its presence rather than assuming it.
