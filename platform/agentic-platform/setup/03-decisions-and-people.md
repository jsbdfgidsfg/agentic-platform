# 3. Decisions, people and the platform repository

## Status
- Owner: the platform owner
- Last reviewed: 2026-09-15
- Stage: review §2 stage 1. Every later file gates on a row of this page.
- Step prefix: `DC`.
- Replaces: [../../wall-e/PREREQUISITES.md](../../wall-e/PREREQUISITES.md) §1 and §2 (the decision and people tables), the "Decisions that must be closed" tables of [../../eve/07-build-runbook.md](../../eve/07-build-runbook.md) and [../../mo/07-build-runbook.md](../../mo/07-build-runbook.md). Salvaged with corrections: D8 reads `eu` only (X-GE-13), D12 starts on day one in [02-toil-baseline.md](02-toil-baseline.md) (S084), D13 reads G1-G21 (S092). Not copied: decision 29 "before Stage 1" (X-ORG-14), decision 6 "at Stage 1" (X-RQB-01), P22 "Tier W" (S051), P52's 30 days as a value to set (X-GE-01).
- Review findings closed here: S035, S051, S063, S130, S135, S140, S144, X-GE-12, X-GE-13, X-ORG-05, X-ORG-08, X-ORG-09, X-ORG-14, X-RQB-01, X-RQB-04, X-RQB-05 (§15). None deferred.
- BLOCKED here: DC-9.9 (the bot-approval CI rule, code of file 16).
- Last executed: never.

## 1. What this part builds

Three things, in this order:

1. **A decision mechanism that later files can test.** Every decision the set needs is a Markdown record under `decisions/` in the platform repository, append-only, with a signature table whose rows each carry the SHA-256 of the record body the signer approved. Three small scripts (`tools/decision-check.sh`, `tools/decision-need.sh`, `tools/decision-value.sh`) let any later step refuse to run on an unsigned or altered record, and read a variable's value only from a signed record.
2. **The signed decisions and the named people.** The checklist of §11, signed through the steps of §5 to §10: setup decisions SD-01 to SD-48, Wall-E D1-D8 and D10-D13, Eve E-1, E-2, E-14, E-16, E-18 and topology decision 44 or CC-33, Mo M-1, M-5, M-7 and the dataset names, platform P1, P10, P11, P13, P14, P22, P29, P31, P49, P52, P137, Wall-E decisions 6, 15 and 29, and the added rows (G3 roster reduction, names register, key table, the recipient of reports about the second human, the penetration-test window, the tabletop date). The data-protection letter goes out in week one. Twelve people are appointed with dates.
3. **The platform repository on the git host** (once P22 is signed, SD-14): two human reviewers, code owners on the control files, administrators bound by the rules and audited, and the local history pushed with its review records.

Where the records live, and why not in the wiki: the wiki is mirrored to Google Drive and holds no employee data beyond name, team and remit; the records carry work email addresses because CODEOWNERS, the roster and IAM need them. So the records are committed to `decisions/` in `PLATFORM_REPO_DIR` (local git until DC-9 pushes it). No procedure writes to `WIKI_DIR`. The two 2026-09-13 records already in the wiki's `decisions/` stay there as design records; the super-admin record is re-signed in [38-super-admin-gate-and-grant.md](38-super-admin-gate-and-grant.md).

## 2. Preconditions

- [ ] [01-prerequisites-and-conventions.md](01-prerequisites-and-conventions.md) done: `~/.platform-env` exists with `penv_set` and `need`; `PLATFORM_REPO_DIR`, `BUILD_LOG_DIR`, `EVIDENCE_INTERIM_LOCATION`, `EVIDENCE_REGISTER`, `DEVIATION_REGISTER`, `DOMAIN`, `ORG_ID`, `OWNER_DAILY_ACCOUNT` are set.
- [ ] `PLATFORM_REPO_DIR` is a git repository with at least one commit (created by 01; 02's first commit may already be there).
- [ ] Workstation has `git`, `bash`, `awk`, `shasum`, `jq`; for DC-9 on GitHub, `gh` signed in as the platform owner's git-host account.
- [ ] The platform owner can send mail from `OWNER_DAILY_ACCOUNT` and write to `EVIDENCE_INTERIM_LOCATION`.
- [ ] Nothing in this file creates a Google Cloud or Workspace resource. The only Google commands are reads.

## 3. People needed

| Role | Short id | In this file | Constraint (from [../11-tisax.md](../11-tisax.md) §7.1, SD-04, SD-12) |
|---|---|---|---|
| Platform owner | PO | drafts every record, runs every step | never the IT security lead, security reviewer, second human, incident commander or Eve owner |
| Second human outside the Wall-E line (IT security) | SH | co-signs SD-10, SD-11, SD-12 and the Eve rows; required code owner | holds `sa-2-admin@` from 06; member of no `walle-*` group; not a witness administrator (SD-04) |
| IT security lead or named delegate | ITSEC | signs security rows until the security reviewer exists | not the platform owner |
| Security reviewer | SR | signs when appointed; ratifies ITSEC rows (DC-8.4) | not the platform owner; not Mo's CI operator |
| ISMS | ISMS | names people (P137), signs deviations and the count | — |
| Data protection officer | DPO | receives D7; signs SD-11, P13, P52 | — |
| Legal | LEGAL | signs D7 answer where the DPO asks, G16 later | — |
| HR / works council contact | HR | confirms works-council information for SD-11 | — |
| Finance, with the billing administrator | FIN | signs P31, P11 cost side, witness billing, sandbox purchase | billing administrator is not the platform owner |
| Incident commander (IT security) | IC | signs SD-08, the tabletop date; stands in for SR as recipient of reports about SH | not the platform owner |
| Mo owner | MOO | signs Mo rows | the platform owner until DC-2.7 names another; never Eve's second reviewer |
| Witness administrators 1 and 2 (IT security) | WA1, WA2 | sign P14 and SD-27 | not tenant super admins; not PO, SH or the second operator (SD-04) |

Signatures are collected by mail or in one sitting; nobody needs to be in the room except for DC-4.4's roster inventory, where SH is present.

## 4. How a record is made, signed and checked

### 4.1 Record shape

One record may carry several decision ids when they share signatories and a gate. The body that is hashed runs from the line `## Context` to the line before `## Signatures`. The status line sits above it, so turning `proposed` into `accepted` does not change what was signed. Append-only: a signed record is never edited; a change is a new record whose `Supersedes:` line names the old one, and the tracker row moves to the new file.

### 4.2 Tracker

`decisions/TRACKER.md` has one row per decision id: `| Id | Title | Record | Gates | Signatories | Status |`. `Record` is `*tbd*` until signed. Later files call `tools/decision-need.sh <id>...` before a gated step; it fails on `*tbd*`, on a record that does not list the id, or on a record that does not parse. On this page, `tools/...` in a VERIFY line is short for `"$PLATFORM_REPO_DIR/tools/..."`, run with `~/.platform-env` sourced.

#### DC-1.1 Create `decisions/`, `tools/` and the record template

- WHO: platform owner. No witness.
- WHERE: shell with `~/.platform-env` sourced.
- ACTION:

```bash
source ~/.platform-env
need PLATFORM_REPO_DIR BUILD_LOG_DIR
test -z "$(gcloud config get project 2>/dev/null)"
mkdir -p "$PLATFORM_REPO_DIR/decisions" "$PLATFORM_REPO_DIR/tools"
cat > "$PLATFORM_REPO_DIR/decisions/_template.md" <<'EOF'
# YYYY-MM-DD — Title

- **Status:** proposed
- **Decision ids:** ID-1, ID-2
- **Required signatories:** PO, SH
- **Deciders:** names, team and role only
- **Supersedes:** none

## Context
What forced the choice; the review findings answered.

## Options considered
| Option | Pros | Cons |
|---|---|---|

## Decision
What was chosen, in sentences a later reader can execute.

## Values
| Variable | Value |
|---|---|

## Gates
| File | Step | What waits |
|---|---|---|

## Consequences
What this commits to, rules out, and when it is revisited.

## Signatures
| Role | Name | Date | Body SHA-256 | Evidence |
|---|---|---|---|---|
EOF
echo "$(date -u +%FT%TZ) DC-1.1 done" >> "$BUILD_LOG_DIR/03-decisions-and-people.log"
```

- VERIFY: `grep -c '^## ' "$PLATFORM_REPO_DIR/decisions/_template.md"` prints `7`.
- ROLLBACK: `rm -r "$PLATFORM_REPO_DIR/decisions" "$PLATFORM_REPO_DIR/tools"` before any record exists.
- EVIDENCE: the template commit (DC-1.3); build-log line. E-05; TISAX 1.1-1.2.

#### DC-1.2 Write the three decision tools and prove they refuse

- WHO: platform owner; the second operator (or the second human until DC-2.4) reviews the commit.
- WHERE: shell with `~/.platform-env` sourced.
- ACTION:

```bash
cat > "$PLATFORM_REPO_DIR/tools/decision-check.sh" <<'EOF'
#!/usr/bin/env bash
# decision-check.sh FILE... exits 0 only if every record parses and every required signature matches its body.
set -uo pipefail
rc=0
for f in "$@"; do
  b=$(basename "$f"); ok=1
  bad() { echo "FAIL $b: $1"; ok=0; }
  [[ "$b" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+\.md$ ]] || bad "file name"
  head -n 1 "$f" | grep -Eq "^# ${b:0:10} — .+" || bad "title line"
  grep -Eq '^- \*\*Status:\*\* accepted$' "$f" || bad "status is not accepted"
  grep -Eq '^- \*\*Decision ids:\*\* [A-Za-z0-9]' "$f" || bad "no decision ids"
  grep -Eq '^## Gates$' "$f" || bad "no Gates section"
  req=$(sed -n 's/^- \*\*Required signatories:\*\* //p' "$f" | tr -d ' ')
  [ -n "$req" ] || bad "no required signatories"
  h=$(awk '/^## Context$/{p=1} /^## Signatures$/{p=0} p' "$f" | shasum -a 256 | cut -d' ' -f1)
  for r in ${req//,/ }; do
    row=$(awk -F'|' -v r="$r" '/^## Signatures$/{s=1;next} s && NF>=7 {k=$2; gsub(/ /,"",k); if (k==r) print}' "$f" | head -n 1)
    if [ -z "$row" ]; then bad "missing signature $r"; continue; fi
    d=$(printf '%s' "$row" | awk -F'|' '{x=$4; gsub(/ /,"",x); print x}')
    s=$(printf '%s' "$row" | awk -F'|' '{x=$5; gsub(/ /,"",x); print x}')
    e=$(printf '%s' "$row" | awk -F'|' '{x=$6; gsub(/ /,"",x); print x}')
    [[ "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || bad "signature $r date"
    [ "$s" = "$h" ] || bad "signature $r signed a different body"
    [ -n "$e" ] || bad "signature $r has no evidence reference"
  done
  if [ "$ok" -eq 1 ]; then echo "OK   $b $h"; else rc=1; fi
done
exit "$rc"
EOF
cat > "$PLATFORM_REPO_DIR/tools/decision-need.sh" <<'EOF'
#!/usr/bin/env bash
# decision-need.sh ID... exits 0 only when each id has a signed, parsing record in decisions/TRACKER.md.
set -uo pipefail
here=$(cd "$(dirname "$0")/.." && pwd); rc=0
for id in "$@"; do
  rec=$(awk -F'|' -v id="$id" '{k=$2; gsub(/ /,"",k); if (k==id) {r=$4; gsub(/ /,"",r); print r}}' "$here/decisions/TRACKER.md" | head -n 1)
  if [ -z "$rec" ] || [ "$rec" = "*tbd*" ]; then echo "UNSIGNED $id"; rc=1; continue; fi
  sed -n 's/^- \*\*Decision ids:\*\* //p' "$here/decisions/$rec" | tr -d ' ' | tr ',' '\n' | grep -qx "$id" || { echo "MISMATCH $id not in $rec"; rc=1; continue; }
  "$here/tools/decision-check.sh" "$here/decisions/$rec" >/dev/null || { echo "INVALID $id ($rec)"; rc=1; continue; }
  echo "SIGNED $id $rec"
done
exit "$rc"
EOF
cat > "$PLATFORM_REPO_DIR/tools/decision-value.sh" <<'EOF'
#!/usr/bin/env bash
# decision-value.sh ID VARIABLE prints VARIABLE from the Values table of the signed record of ID.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
"$here/tools/decision-need.sh" "$1" >/dev/null
rec=$(awk -F'|' -v id="$1" '{k=$2; gsub(/ /,"",k); if (k==id) {r=$4; gsub(/ /,"",r); print r}}' "$here/decisions/TRACKER.md" | head -n 1)
v=$(awk -F'|' -v n="$2" '/^## Values$/{s=1;next} /^## /{s=0} s {k=$2; gsub(/[ `]/,"",k); if (k==n) {x=$3; gsub(/^ +| +$/,"",x); gsub(/`/,"",x); print x}}' "$here/decisions/$rec" | head -n 1)
[ -n "$v" ] || { echo "no value for $2 in $rec" >&2; exit 1; }
printf '%s\n' "$v"
EOF
chmod +x "$PLATFORM_REPO_DIR"/tools/decision-*.sh
```

- VERIFY: a fixture that must pass and one that must fail, in a temporary directory outside the repository:

```bash
t=$(mktemp -d)
sed -e '1s/.*/# 2026-09-15 — Fixture/' -e 's/proposed/accepted/' "$PLATFORM_REPO_DIR/decisions/_template.md" > "$t/2026-09-15-fixture.md"
h=$(awk '/^## Context$/{p=1} /^## Signatures$/{p=0} p' "$t/2026-09-15-fixture.md" | shasum -a 256 | cut -d' ' -f1)
printf '| PO | Fixture | 2026-09-15 | %s | fixture-po |\n| SH | Fixture | 2026-09-15 | %s | fixture-sh |\n' "$h" "$h" >> "$t/2026-09-15-fixture.md"
"$PLATFORM_REPO_DIR/tools/decision-check.sh" "$t/2026-09-15-fixture.md"
sed 's/^What forced the choice.*/Changed after signing./' "$t/2026-09-15-fixture.md" > "$t/2026-09-15-tampered.md"
"$PLATFORM_REPO_DIR/tools/decision-check.sh" "$t/2026-09-15-tampered.md"; echo "exit=$?"
rm -r "$t"
```

  Expect `OK   2026-09-15-fixture.md <hash>`, then two `FAIL 2026-09-15-tampered.md: signature PO/SH signed a different body` lines and `exit=1`.
- ROLLBACK: `rm "$PLATFORM_REPO_DIR"/tools/decision-*.sh`.
- EVIDENCE: the verify output pasted into the build log under DC-1.2; the commit and its review record (DC-1.3). E-05; TISAX 5.2.

#### DC-1.3 Create the tracker and commit with a review record

- WHO: platform owner commits; the reviewer of DC-1.2 signs the review record.
- WHERE: shell with `~/.platform-env` sourced.
- ACTION: write `decisions/TRACKER.md` with the header and one row per id of §5 and §11 (`Record` and `Status` set to `*tbd*` and `open`; each appointment id of §5 gets its own row), then:

```bash
git -C "$PLATFORM_REPO_DIR" add decisions/_template.md decisions/TRACKER.md tools/decision-check.sh tools/decision-need.sh tools/decision-value.sh
git -C "$PLATFORM_REPO_DIR" commit -m "DC-1.3 decision records, tracker and checks"
c=$(git -C "$PLATFORM_REPO_DIR" rev-parse HEAD)
mkdir -p "$BUILD_LOG_DIR/reviews"
printf 'commit %s\nreviewer: <name, role>\ndate: %s\nresult: approved\nevidence: %s-DC-1.3-review-v1\n' "$c" "$(date +%F)" "$(date +%F)" > "$BUILD_LOG_DIR/reviews/$c.md"
```

  The reviewer's approval (a mail from their own account quoting the commit hash) is saved to `EVIDENCE_INTERIM_LOCATION` under the evidence name. Until DC-9 creates the remote, every commit to the platform repository gets such a review record; DC-9.1 refuses to push without one.
- VERIFY: no id is listed twice and every id of §11 is present:

```bash
awk -F'|' 'NR>2 && NF>=7 {k=$2; gsub(/ /,"",k); print k}' "$PLATFORM_REPO_DIR/decisions/TRACKER.md" | sort | uniq -d
for id in SD-01 SD-24 SD-48 D8 D13 WDEC-6 WDEC-29 E-16 TD-44 M-1 P22 P137 NAMES KEYS SH-REPORTS PPL-SH; do grep -q "^| $id |" "$PLATFORM_REPO_DIR/decisions/TRACKER.md" || echo "missing $id"; done
test -f "$BUILD_LOG_DIR/reviews/$(git -C "$PLATFORM_REPO_DIR" rev-parse HEAD).md" && echo reviewed
```

  Expect no duplicate, no `missing` line (the sample spans every table of §5 and §11; the reviewer compares the full list by eye), and `reviewed`.
- ROLLBACK: `git -C "$PLATFORM_REPO_DIR" revert HEAD` (local only).
- EVIDENCE: commit hash, review record path, reviewer mail in the interim location. E-05; TISAX 1.1-1.2, 5.2.

#### DC-1.4 The signing procedure every record follows

- WHO: platform owner drafts and collects; each required signatory signs from their own account.
- WHERE: shell with `~/.platform-env` sourced; mail from each signatory's own account.
- ACTION:

```bash
cd "$PLATFORM_REPO_DIR"
rec="decisions/$(date +%F)-<slug>.md"
cp decisions/_template.md "$rec"
sed -i '' "1s/.*/# $(date +%F) — <title>/" "$rec"
```

  (`sed -i ''` is the macOS form; on Linux use `sed -i`.) Fill ids, required signatories, every body section, the Values and Gates tables. Then compute the body hash:

```bash
awk '/^## Context$/{p=1} /^## Signatures$/{p=0} p' "$rec" | shasum -a 256 | cut -d' ' -f1
```

  Send the record to each signatory. Each replies from their own account: "I sign `<file name>`, body SHA-256 `<hash>`, as `<role id>`." Save each reply to `EVIDENCE_INTERIM_LOCATION` as `<date>-<step-id>-<slug>-<role>-v1`. Add one signature row per reply. When every required row is present, set `- **Status:** accepted`, set the tracker rows' `Record` and `Status`, commit with a review record as in DC-1.3.
- VERIFY: `tools/decision-check.sh "$rec"` prints `OK`; `tools/decision-need.sh <every id in the record>` prints `SIGNED` for each.
- ROLLBACK: before acceptance, edit freely and re-send (a changed body invalidates earlier signatures, which the check shows). After acceptance: never edit; write a superseding record.
- EVIDENCE: the record commit; signature mails; one `EVIDENCE_REGISTER` line per record naming the step id, file, E-xx and TISAX ids. E-03, E-05; TISAX 1.1-1.2.

## 5. People, appointed with dates

Each appointment is its own record (`<date>-appointment-<role>.md`) signed by ISMS (who names people under P137), the appointee (acceptance of the role and its constraints) and the platform owner. The Values table holds the email the variables file receives. A role not yet filled stays `*tbd*` in the tracker and in `~/.platform-env`; the gated files refuse through `need` and `decision-need.sh`.

| Id | Role | Needed by (file: step) | Signatories | Sets |
|---|---|---|---|---|
| PPL-SH | Second human outside the Wall-E line; owner of `eve-owners@`; E-2 | 06: first step (custody of keys, roster merge); 23: first step | ISMS, SH, PO | `SECOND_HUMAN_EMAIL` |
| PPL-IC | Incident commander | 15: part A escalation; 24: eve@ second key custodian while no SR (SD-12 item 11); 26: first step | ISMS, IC, PO | `INCIDENT_COMMANDER_EMAIL` |
| PPL-SR | Security reviewer | 11: validator custodian part; 31: P-SA prod entitlement; 38: gate. Tier W at the latest | ISMS, SR, PO | `SECURITY_REVIEWER_EMAIL` |
| PPL-VC | Validator custodian (security reviewer's line) | 11: custodian part; 40: recompute check | ISMS, VC, SR | `VALIDATOR_CUSTODIAN_EMAIL` |
| PPL-SO | Second operator in `walle-operators@` (D5) | 02: review of the baseline commit; 30: operators group; 39: alert check | ISMS, SO, PO | `SECOND_OPERATOR_EMAIL` |
| PPL-BG | Blind grader, not owner of the graded playbooks | 40: graders | ISMS, BG, MOO | `BLIND_GRADER_EMAIL` |
| PPL-WA1 | Witness administrator 1 | 08: W-1 | ISMS, WA1, ITSEC | `WITNESS_ADMIN_1_EMAIL` |
| PPL-WA2 | Witness administrator 2 | 08: W-1 | ISMS, WA2, ITSEC | `WITNESS_ADMIN_2_EMAIL` |
| PPL-SB1 | Sandbox super admin 1 | 21: first tenant step | ISMS, SB1, PO | `SANDBOX_SA_1_EMAIL` |
| PPL-SB2 | Sandbox super admin 2 | 21: first tenant step | ISMS, SB2, PO | `SANDBOX_SA_2_EMAIL` |
| PPL-BA | Billing administrator (finance) | 07: first step | FIN, BA, PO | `BILLING_ADMIN_EMAIL` |
| PPL-MO | Mo owner | 22: first step | ISMS, MOO, PO | `MO_OWNER_EMAIL` |
| SH-REPORTS | Recipient of reports whose subject is the second human | 26: first step. **26 is BLOCKED while neither SR nor IC is named** | ISMS, ITSEC, PO | the role id recorded, no variable |

#### DC-2.1 Appoint the second human (PPL-SH, E-2)

- WHO: ISMS names; the appointee accepts; the platform owner drafts.
- WHERE: record per DC-1.4; shell for the variable.
- ACTION: record body states: the person is in IT security, outside the Wall-E administration line; will hold `sa-2-admin@` (06), own `eve-owners@` (06), perform eve@'s consent sign-in (24), be required code owner on the control files (DC-9.4), receive every severity 1 and 2 page in parallel, be sole recipient of reports about the platform owner, lead the independent proof (28), and never be a witness administrator (SD-04) nor a member of any `walle-*` group. Values: `SECOND_HUMAN_EMAIL`. After acceptance:

```bash
penv_set SECOND_HUMAN_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-SH SECOND_HUMAN_EMAIL)"
```

- VERIFY: `"$PLATFORM_REPO_DIR/tools/decision-need.sh" PPL-SH E-2` prints two `SIGNED` lines; `need SECOND_HUMAN_EMAIL` passes; the address differs from `OWNER_DAILY_ACCOUNT`: `[ "$SECOND_HUMAN_EMAIL" != "$OWNER_DAILY_ACCOUNT" ] && echo distinct`.
- ROLLBACK: a superseding appointment record; `penv_set --force SECOND_HUMAN_EMAIL <new>` with a build-log line.
- EVIDENCE: the record; ISMS role-register entry reference. E-08; TISAX 1.1-1.2, 2.1.

#### DC-2.2 Appoint the incident commander and fix the recipient of reports about the second human (PPL-IC, SH-REPORTS)

- WHO: ISMS names; IC accepts; ITSEC signs SH-REPORTS.
- WHERE: two records per DC-1.4.
- ACTION: PPL-IC per the table. SH-REPORTS body: reports whose subject is the second human go to the security reviewer; until PPL-SR is signed they go to the incident commander; never to the second human or the platform owner (SD-10). The record names which role applies today and that the switch to SR happens in the same record that appoints SR (DC-2.3).

```bash
penv_set INCIDENT_COMMANDER_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-IC INCIDENT_COMMANDER_EMAIL)"
```

- VERIFY: `tools/decision-need.sh PPL-IC SH-REPORTS` both `SIGNED`; `[ "$INCIDENT_COMMANDER_EMAIL" != "$OWNER_DAILY_ACCOUNT" ] && [ "$INCIDENT_COMMANDER_EMAIL" != "$SECOND_HUMAN_EMAIL" ] && echo distinct`. The incident commander may be the second human only if the ISMS record says so; then SH-REPORTS cannot point at IC and 26 stays BLOCKED until SR is named.
- ROLLBACK: superseding record.
- EVIDENCE: records. E-08, E-10; TISAX 1.6.

#### DC-2.3 Appoint the security reviewer and the validator custodian (PPL-SR, PPL-VC)

- WHO: ISMS; appointees; the platform owner.
- WHERE: records per DC-1.4.
- ACTION: if the person is not available, commit the tracker rows as `*tbd*` with a dated note of who ISMS has asked; do not sign a placeholder. On appointment, the PPL-SR record also supersedes SH-REPORTS to point at SR.

```bash
penv_set SECURITY_REVIEWER_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-SR SECURITY_REVIEWER_EMAIL)"
penv_set VALIDATOR_CUSTODIAN_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-VC VALIDATOR_CUSTODIAN_EMAIL)"
```

- VERIFY: `tools/decision-need.sh PPL-SR PPL-VC`; `[ "$SECURITY_REVIEWER_EMAIL" != "$OWNER_DAILY_ACCOUNT" ] && echo distinct`. Until signed, `need SECURITY_REVIEWER_EMAIL` fails, which is the intended stop for 11's custodian part, 31's production entitlement and 38.
- ROLLBACK: superseding record.
- EVIDENCE: records. E-08; TISAX 1.1-1.2, 1.4.

#### DC-2.4 Appoint the second operator and the blind grader (PPL-SO, PPL-BG, D5)

- WHO: ISMS; appointees; the platform owner; Mo owner for the grader.
- WHERE: records per DC-1.4.
- ACTION: PPL-SO also closes D5's first half (second operator); D5's second half (IT security second approver) is the security reviewer (DC-2.3). The blind grader record states the playbooks the grader must not own.

```bash
penv_set SECOND_OPERATOR_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-SO SECOND_OPERATOR_EMAIL)"
penv_set BLIND_GRADER_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-BG BLIND_GRADER_EMAIL)"
```

- VERIFY: `tools/decision-need.sh PPL-SO PPL-BG D5`; SO differs from PO and SH.
- ROLLBACK: superseding record.
- EVIDENCE: records. E-08; TISAX 1.1-1.2, 2.1.

#### DC-2.5 Appoint the two witness administrators (PPL-WA1, PPL-WA2)

- WHO: ISMS names two IT security people; ITSEC co-signs; appointees accept.
- WHERE: records per DC-1.4.
- ACTION: each record states: not a tenant super admin now or later, not the platform owner, the second human or the second operator; administers the witness organisation from their own workstation copy of the witness section; is the other administrator's recovery path (self-recovery Off in the witness, SD-28); holds two hardware keys (04). The tenant email is for contact only; witness accounts are created in 08.

```bash
penv_set WITNESS_ADMIN_1_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-WA1 WITNESS_ADMIN_1_EMAIL)"
penv_set WITNESS_ADMIN_2_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-WA2 WITNESS_ADMIN_2_EMAIL)"
```

- VERIFY: `tools/decision-need.sh PPL-WA1 PPL-WA2`; the two addresses differ from each other and from `OWNER_DAILY_ACCOUNT`, `SECOND_HUMAN_EMAIL` and `SECOND_OPERATOR_EMAIL`:

```bash
printf '%s\n' "$WITNESS_ADMIN_1_EMAIL" "$WITNESS_ADMIN_2_EMAIL" "$OWNER_DAILY_ACCOUNT" "$SECOND_HUMAN_EMAIL" "${SECOND_OPERATOR_EMAIL:-none}" | sort | uniq -d
```

  Expect no output. The "not a tenant super admin" half is proven in 06, where the roster is committed, and in 08 before W-1.
- ROLLBACK: superseding record.
- EVIDENCE: records. E-08; TISAX 1.1-1.2, 4.1-4.2.

#### DC-2.6 Appoint the two sandbox super admins (PPL-SB1, PPL-SB2)

- WHO: ISMS; appointees; the platform owner.
- WHERE: records per DC-1.4.
- ACTION: two distinct humans, each with a sandbox-domain account created in 21 (the email is recorded once `SANDBOX_DOMAIN` exists from 04; until then the record names the person and the Values cell reads `*tbd*`, and a superseding record adds the address). They are the twin's band-A and band-B requester and approver, so approver differs from requester (SD-25). Assumption: the platform owner and the second operator may hold these roles; the record says who.
  Once the superseding record carries both addresses:

```bash
penv_set SANDBOX_SA_1_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-SB1 SANDBOX_SA_1_EMAIL)"
penv_set SANDBOX_SA_2_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-SB2 SANDBOX_SA_2_EMAIL)"
```

- VERIFY: `tools/decision-need.sh PPL-SB1 PPL-SB2`; `need SANDBOX_SA_1_EMAIL SANDBOX_SA_2_EMAIL`; `[ "$SANDBOX_SA_1_EMAIL" != "$SANDBOX_SA_2_EMAIL" ] && echo distinct`.
- ROLLBACK: superseding record.
- EVIDENCE: records. E-08; TISAX 1.1-1.2.

#### DC-2.7 Appoint the billing administrator and the Mo owner (PPL-BA, PPL-MO)

- WHO: finance names BA; ISMS names MOO (default: the platform owner, recorded as such).
- WHERE: records per DC-1.4.
- ACTION:

```bash
penv_set BILLING_ADMIN_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-BA BILLING_ADMIN_EMAIL)"
penv_set MO_OWNER_EMAIL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" PPL-MO MO_OWNER_EMAIL)"
```

- VERIFY: `tools/decision-need.sh PPL-BA PPL-MO`; `[ "$BILLING_ADMIN_EMAIL" != "$OWNER_DAILY_ACCOUNT" ] && echo distinct`.
- ROLLBACK: superseding record.
- EVIDENCE: records. E-08; TISAX 1.1-1.2.

#### DC-2.8 Count the people and sign the separation (P137, SD-04 count)

- WHO: ISMS signs; platform owner drafts; ITSEC co-signs.
- WHERE: record per DC-1.4 (`<date>-separation-and-count.md`, ids P137).
- ACTION: the record contains the incompatibility table of [../11-tisax.md](../11-tisax.md) §7.1 with a name in every filled cell and the count at each gate. The count the procedures adopt, correcting P137 for SD-04:

  | Gate | Minimum distinct humans | Why |
  |---|---|---|
  | Tier R, Stage 0-pre build | 2 | platform owner and second human (Eve-H needs someone outside the line from 06) |
  | Tier W | 3 | adds the second operator; SR may be ITSEC until appointed, recorded |
  | The super-admin grant | **5** | PO, SH, SO, and two witness administrators who are neither PO, SH nor SO. SR and IC may be the two witness administrators. The four-with-an-ISMS-exception floor of P137 (SR = SH) does not reduce the count: the witness pair must still be two people other than SH, so the floor stays five |

  A manual check of the matrix against the appointment records is signed here; the daily CI separation check is file 16's. Values: `GRANT_MIN_HUMANS` = `5`, `TIER_W_MIN_HUMANS` = `3` (record values, not environment variables).
- VERIFY: `"$PLATFORM_REPO_DIR/tools/decision-value.sh" P137 GRANT_MIN_HUMANS` prints `5`.
- ROLLBACK: superseding record.
- EVIDENCE: record; ISMS role register reference. E-08; TISAX 1.1-1.2 (1.2.2 separation).

## 6. Week one: the data-protection letter

#### DC-3.1 Send the D7 letter, covering Wall-E and the monitoring of named administrators (D7-LETTER)

- WHO: platform owner sends; DPO and HR receive; legal in copy.
- WHERE: mail from `OWNER_DAILY_ACCOUNT`; record per DC-1.4 with required signatory PO only (it records that the letter left, not an answer).
- ACTION: send by 2026-09-21 at the latest. The letter asks for a written answer on:
  1. Wall-E's processing (decisions 8 and 25; P129): autonomous administrative action on employee accounts, the organisation-level audit logs whose storage region cannot be chosen, the content log bucket and telemetry content.
  2. Eve's monitoring of named administrator accounts from Eve's first run (SD-11): purpose, detection of misuse of tenant-wide privilege; data, admin, login, token, SAML, groups and Reports activity metadata, no content; subjects, every account on the super-admin roster and every live admin-role holder; retention, `eve_workspace_*` at the value P13 sets and the witness copy; recipients, the second human, the security reviewer, the incident commander; never the subject.
  3. Retention floor and ceiling per store (P13, E-14, M-5) and conversation retention (P52), with the rule that the Gemini Enterprise baseline never lowers today's value.
  4. Whether works-council information is required before 25 and before Wall-E's Stage 1, and who gives it.

  Values: `DPO_CONTACT` (a role mailbox where one exists).

```bash
penv_set DPO_CONTACT "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" D7-LETTER DPO_CONTACT)"
```

- VERIFY: `tools/decision-need.sh D7-LETTER`; the sent mail saved as `<date>-DC-3.1-d7-letter-v1` in the interim location; the record date is on or before 2026-09-21.
- ROLLBACK: none needed; a correction is a second letter recorded the same way.
- EVIDENCE: sent letter. E-12; TISAX 7.1.

#### DC-3.2 Record the DPO's answer on administrator monitoring (SD-11, D7)

- WHO: DPO signs; SH and PO co-sign; HR signs the works-council half.
- WHERE: record per DC-1.4 (`<date>-monitoring-of-administrators.md`, ids SD-11, D7).
- ACTION: the record holds the legal basis, purpose, data, retention, recipients and the works-council answer. If the DPO answers D7 for Wall-E later than SD-11, D7 gets its own record and SD-11 is signed alone.
- VERIFY: `tools/decision-need.sh SD-11`. **25's reconciler and poll jobs are BLOCKED until this prints `SIGNED`** (SD-11).
- ROLLBACK: superseding record.
- EVIDENCE: record; DPO's record of processing reference. E-12; TISAX 7.1.

## 7. Decisions before the organisation is touched (files 04 to 09)

#### DC-4.1 Sign the setup conventions and the bootstrap deviation

- WHO: platform owner drafts; ITSEC and ISMS sign.
- WHERE: record per DC-1.4 (`<date>-setup-conventions-and-bootstrap-deviation.md`).
- ACTION: ids SD-01, SD-13, SD-17, SD-22, SD-35, SD-37, SD-38, SD-40, SD-41, SD-44, SD-45; body quotes each resolution of the plan's §6 verbatim, with the dated organisation exception's expiry left to 06 (`BOOTSTRAP_EXCEPTION_EXPIRY`).
- VERIFY: `tools/decision-need.sh SD-01 SD-13 SD-17 SD-22 SD-35 SD-37 SD-38 SD-40 SD-41 SD-44 SD-45`.
- ROLLBACK: superseding record.
- EVIDENCE: record. E-05; TISAX 1.1-1.2, 1.4 (the deviation).

#### DC-4.2 Sign the Gemini Enterprise app location: `eu` only (D8, SD-21)

- WHO: platform owner. No second signatory.
- WHERE: record per DC-1.4.
- ACTION: body: "The app location must be `eu`. A `global` or `us` app stops the build at 05 and opens a decision record for a new `eu` app; chat history and data stores do not move." The earlier "eu or global" of Wall-E D8 is superseded (X-GE-13): a global app binds only a `us-central1` gateway and cannot use CMEK.
- VERIFY: `tools/decision-need.sh D8 SD-21`. **05 checks this before recording the location.**
- ROLLBACK: superseding record.
- EVIDENCE: record. E-11; TISAX 7.1 (residency table).

#### DC-4.3 Sign the git host and admin-bypass rule (P22, SD-14, M-7)

- WHO: platform owner; ITSEC.
- WHERE: record per DC-1.4 (`<date>-git-host-and-repository.md`).
- ACTION: body: the git host; that P22's gate moves from Tier W to **before Tier R**, because 10's WIF provider and 13's B19 need the issuer (S051); that the repository has two human reviewers, code owners on the control files, administrators bound by the rules and bypass events audited (M-7); that approvals by service accounts or bot users do not count; the CI deployer is P142's. Values:

  | Variable | Value if the host is GitHub | Value if the host is GitLab SaaS |
  |---|---|---|
  | `GIT_HOST` | `github.com` | `gitlab.com` |
  | `GIT_OIDC_ISSUER` | `https://token.actions.githubusercontent.com/` | `https://gitlab.com` |

  Both issuer strings are as Google's page "Configure Workload Identity Federation with deployment pipelines" shows them on 2026-09-15 (the GitHub one with its trailing slash). A self-managed host is not covered by that page; its issuer is `*tbd*` and 10 stops.

```bash
penv_set GIT_HOST "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" P22 GIT_HOST)"
penv_set GIT_OIDC_ISSUER "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" P22 GIT_OIDC_ISSUER)"
```

- VERIFY: `tools/decision-need.sh P22 SD-14 M-7`; `need GIT_HOST GIT_OIDC_ISSUER`; `case "$GIT_OIDC_ISSUER" in https://*) echo ok;; esac`.
- ROLLBACK: superseding record before 10 creates the provider; after that, 10's provider is updated in the same change.
- EVIDENCE: record. E-05; TISAX 5.2.

#### DC-4.4 Inventory the admin roles and sign the G3 roster reduction, custody and recovery timing (G3-ROSTER, SD-27, SD-30)

- WHO: platform owner reads as a current super admin with the second human present; ITSEC signs; SH co-signs.
- WHERE: Admin console, `Menu > Account > Admin roles`; record per DC-1.4 (`<date>-roster-reduction-and-custody.md`).
- ACTION: read only. For **Super Admin** and then for every other role listed, select the role and click **View admins**; write each account and role into the build log (`$BUILD_LOG_DIR/03-roster-inventory-<date>.md`), never into the wiki. The record's decision: after 06 proves `sa-1-admin@` and `sa-2-admin@`, every other current super admin, including the platform owner's and the second human's daily accounts, is moved to a named delegated role (or none), one row per account with its target role and owner; no service identity keeps Super Admin; the change is executed in 06. It also signs SD-27 (paper custody records and same-day scans until W-2) and SD-30 (tenant-wide self-recovery Off and multi-party approval are set on the gate day in 38, not in 06).
- VERIFY: `tools/decision-need.sh G3-ROSTER SD-27 SD-30`; the inventory file lists at least one Super Admin row and its line count matches the record's table.
- ROLLBACK: nothing was changed; a new inventory supersedes the old one if 06 is more than 30 days later (Assumption: 30 days; the record states it).
- EVIDENCE: inventory in the build log; record. E-08; TISAX 4.1-4.2.

#### DC-4.5 Sign the billing account, the SCC payer and the SIEM (P31, SD-16, P11, SD-15, P10)

- WHO: finance and the billing administrator for P31; ITSEC and finance for P11; ITSEC for P10; platform owner drafts.
- WHERE: shell for the billing read (run by the billing administrator, who holds a role on the account); record per DC-1.4 (`<date>-billing-scc-and-siem.md`).
- ACTION: the billing administrator reads the candidate account (the id is typed, not stored here; 07 sets `BILLING_ACCOUNT_ID`):

```bash
gcloud billing accounts describe "<candidate-billing-account-id>" --format="value(open,currencyCode,masterBillingAccount,parent)"
```

  Stop if `open` is not `True`, if `masterBillingAccount` is non-empty (a reseller sub-account), or if the currency is not EUR without the record stating the currency every budget uses. Body:
  - P31, SD-16: a dedicated standard billing account, its administrator (PPL-BA), Billing Account User (`roles/billing.user`) and Billing Account Costs Manager (`roles/billing.costsManager`) on that account only to `sa-1-admin@` with an expiry and later to `factory-apply@`; the project-quota request for about 20 projects filed in 07; the export by the billing administrator in 14. Closes X-RQB-05. P31's quota and budget numbers keep HLD §3.1 and §3.4's assumptions.
  - P11, SD-15: Premium at the organisation with `eu` data residency, activated in 09 before any location policy. The payer is named: `payg-org` charges every project's billing account in the organisation (finance signs and notifies cost-centre owners) or `subscription` (a 12-month sales contract through Google). Closes X-RQB-04.
  - P10: `secops` (Google SecOps in the EU) or `existing` (the organisation's SIEM), and the MDR partner; purchases in 04.

  Values: `SCC_BILLING_MODEL`, `SIEM_KIND`.

```bash
penv_set SCC_BILLING_MODEL "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" P11 SCC_BILLING_MODEL)"
penv_set SIEM_KIND "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" P10 SIEM_KIND)"
```

- VERIFY: `tools/decision-need.sh P31 SD-16 P11 SD-15 P10`; `case "$SCC_BILLING_MODEL" in payg-org|subscription) echo ok;; esac`; `case "$SIEM_KIND" in secops|existing) echo ok;; esac`.
- ROLLBACK: superseding record before 04 places an order or 09 activates.
- EVIDENCE: the describe output (no id redaction needed; it is not a secret) in the build log; record. E-11 (supplier file); TISAX 6.1.

#### DC-4.6 Sign the witness organisation (P14, SD-04, SD-28)

- WHO: ITSEC, ISMS, finance, WA1, WA2 and SH sign; platform owner drafts.
- WHERE: record per DC-1.4 (`<date>-witness-organisation.md`).
- ACTION: body, closing X-ORG-05, X-ORG-08 and X-ORG-09:
  - Administrators: the two witness super admins are PPL-WA1 and PPL-WA2 (§5), not tenant super admins; the second human holds a non-administrator witness account as owner of record and receives witness alarms; self-recovery Off; recovery by the other witness administrator and support-assisted recovery through domain ownership.
  - Domain: separately registered, not a subdomain of any tenant domain, in a registrar account and DNS outside the tenant's Cloud organisation and outside the Digital Workplace line, registrar lock and 2SV, administrators the two witness administrators only.
  - Edition: Cloud Identity Free or Premium, chosen on grounds other than multi-party approval (stated).
  - Billing: a billing account parented by the witness organisation, administered only by the witness administrators, no tenant principal on it, budget alert to the witness email channel. The platform billing account is refused: a tenant Organization Administrator could disable billing on the witness project, which stops its services.
  - Support: a Customer Care subscription on the witness organisation, or Access Approval recorded as unavailable after asking Google (04).
- VERIFY: `tools/decision-need.sh P14 SD-04 SD-28`; the record's signature table has rows WA1 and WA2.
- ROLLBACK: superseding record before 04 registers the domain.
- EVIDENCE: record. E-06 (witness copy); TISAX 6.1, 1.1-1.2.

#### DC-4.7 Sign the sandbox tenant: timing and edition (decision 29, SD-29, D3)

- WHO: platform owner; ITSEC; finance.
- WHERE: record per DC-1.4 (`<date>-sandbox-tenant.md`, ids WDEC-29, SD-29, D3).
- ACTION: body: the sandbox Workspace tenant exists **before the super-admin grant** (G10, G11, G14 and Eve G-7 need it) and, in this set, before Eve (21 precedes 24); "before Stage 1" is superseded (X-ORG-14). Edition equal to production, at least Enterprise Standard (Enterprise Plus if the Access Transparency stream is drilled); a domain on no other account, with TXT and MX; seats; the two sandbox super admins of DC-2.6; P59 closed; whether twin robots use hardware-key 2SV (adds four keys to 04). D3's pilot OU and production sandbox OU are named in the names register (DC-5.1).
- VERIFY: `tools/decision-need.sh WDEC-29 SD-29 D3`.
- ROLLBACK: superseding record before 04's purchase order.
- EVIDENCE: record. E-04; TISAX 5.2.

#### DC-4.8 Sign retention: ceilings, locks and no reduction (P13, E-14, M-5, P52, SD-20)

- WHO: DPO signs; platform owner, Mo owner and SH co-sign; HR for the user notice rule.
- WHERE: record per DC-1.4 (`<date>-retention.md`).
- ACTION: body:
  - P13 and E-14: floor and ceiling per store, starting from [../08-data-logging-retention-sovereignty.md](../08-data-logging-retention-sovereignty.md) §5.2 as the proposal. The lock value of every locked store equals the ceiling, because a locked Cloud Storage retention policy cannot be removed or reduced.
  - M-5: Mo's window clamp uses the same floor; the owner of the off-project copy is named before 40.
  - P52 and SD-20: the Gemini Enterprise baseline keeps or raises the retention value 05 records (`GE_RETENTION_CURRENT_DAYS`); no value is set from P52's interim 30 days; any reduction is its own step after this record, with user notice at least one retention period ahead and rollback "none: no documented recovery".

  Values: `EVIDENCE_RETENTION_DAYS`, `IDENTITY_RETENTION_DAYS` (integers, or `*tbd*` while the DPO has not answered).

```bash
penv_set EVIDENCE_RETENTION_DAYS "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" P13 EVIDENCE_RETENTION_DAYS)"
penv_set IDENTITY_RETENTION_DAYS "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" P13 IDENTITY_RETENTION_DAYS)"
```

- VERIFY: `tools/decision-need.sh P13 E-14 M-5 P52 SD-20`; `case "$EVIDENCE_RETENTION_DAYS" in ''|*[!0-9]*) echo "not an integer: every lock in 08, 14 and 23 refuses";; *) echo "lock value $EVIDENCE_RETENTION_DAYS";; esac`.
- ROLLBACK: superseding record, possible only before the first lock (08 W-2, 14, 23). **The locks themselves are IRREVERSIBLE in their files and gated on this record.**
- EVIDENCE: record. E-06, E-12; TISAX 5.2, 7.1.

## 8. Names and keys: the permanent choices

Project ids are permanent and are never reusable, even after deletion; key rings cannot be deleted and deleted key names cannot be reused; a BigQuery dataset's name and location cannot be changed after creation; a tag key's short name cannot be changed. Every create step for these in 09, 10, 11, 21, 22, 23 and 31 is **IRREVERSIBLE** as a name and runs only after `tools/decision-need.sh NAMES` (and `KEYS` for key rings) prints `SIGNED`.

#### DC-5.1 Sign the names register (NAMES, D1, SD-23, SD-33)

- WHO: platform owner drafts; SH signs the Eve and witness names; Mo owner signs the Mo names; WA1 and WA2 sign the witness names; ITSEC signs.
- WHERE: record per DC-1.4 (`<date>-names-register.md`).
- ACTION: the Values table carries every permanent name below. Project ids are 6 to 30 characters of lowercase letters, digits and hyphens, starting with a letter, not ending with a hyphen. Availability of a project id or bucket name is proven only at creation; the record signs a fallback rule (one suffix, stated) that the create step applies and records.

  | Kind | Variable or name | Value | Created in |
  |---|---|---|---|
  | Project | `CICD_PROJECT`, `CORE_PROJECT`, `LOGGING_PROJECT`, `KMS_PROJECT`, `VALIDATOR_PROJECT` | *tbd* (signed here) | 10 |
  | Project | `CANARY_R_PROJECT` | *tbd* | 18 |
  | Project | `WALLE_TWIN_PROJECT`, `EVE_TWIN_PROJECT` | *tbd* | 21 (reserved), 23 and 37 |
  | Project | `MO_PROJECT`, `MO_TWIN_PROJECT` (only if P40 requires it) | *tbd* | 22 |
  | Project | `EVE_PROJECT` | *tbd* | 23 |
  | Project | `WALLE_PROJECT` | *tbd* | 31 |
  | Project | `EVE_WITNESS_PROJECT` | *tbd* (witness administrators sign) | 08 |
  | Tag key | `agp-tier`, `agp-tisax-scope` | as named | 09 |
  | Dataset | `PLATFORM_LOGS_DS`, `PLATFORM_LOGS_VIEWS_DS` | `platform_logs`, `platform_logs_views` | 14 |
  | Dataset | `BILLING_EXPORT_DS` | *tbd* | 14 |
  | Dataset | `GRADES_EVE_DS` | `eve_grades` | 11 |
  | Dataset | `MO_METRICS_DS`, `MO_ARCHIVE_DS`, `MO_PRIVATE_DS`, `MO_VIEWS_DS` | `platform_metrics`, `platform_metrics_archive`, `platform_metrics_private`, `platform_metrics_views` (SD-33, every table keyed on `agent_id`) | 22 |
  | Dataset | `EVE_DS`, `EVE_WS_LOGS_DS`, `EVE_QUALITY_DS` | `eve`, `eve_workspace_logs`, `eve_quality` | 23 |
  | Dataset | `EVE_WS_REPORTS_DS` | *tbd* | 23 |
  | Dataset | `WITNESS_MIRROR_DS` | `eve_mirror` | 08 |
  | Dataset | `WALLE_AUDIT_DS`, `EVE_MIRROR_DS`, `EVE_RECEIPTS_DS` | `walle_audit`, `eve_audit_mirror`, `eve_receipts` | 31, 36, 41 |
  | Bucket | `EVE_EVIDENCE_BUCKET` and its location `EVE_EVIDENCE_LOCATION` | `gs://<EVE_PROJECT>-eve-evidence`, `europe-west1` (SD-23) | 23 |
  | Bucket | `MO_PROPOSALS` | `gs://mo-proposals` | 40 |
  | Bucket | `TF_STATE_BUCKET`, `WITNESS_BUCKET` | *tbd* | 10, 08 |
  | Log bucket | `platform-evidence-logs`, `platform-identity-logs` | as named | 14 |
  | Workspace | robot addresses `walle@`, `eve@`; OU paths `ADMIN_OU`, `BREAK_GLASS_OU`, `SERVICE_IDENTITY_OU`, `PILOT_OU`, `SANDBOX_OU`; group addresses of 06 and 30 | as in the plan's variables table; OU paths *tbd* where not given | 06, 24, 30 |
  | OAuth | Wall-E and Eve OAuth app names shown at consent (D1) | *tbd* | 24, 32 |

  SD-23 closes S135: Eve's locked bucket is in `europe-west1`, not the EU multi-region; 23 checks the location before the lock. SD-33 closes S144: no `walle_metrics*` dataset is ever created. Retired names that must not appear: `walle_metrics*`, `LOGS_DATASET`, `FOLDER_ID`.

```bash
for v in MO_METRICS_DS MO_ARCHIVE_DS MO_PRIVATE_DS MO_VIEWS_DS EVE_EVIDENCE_LOCATION; do
  penv_set "$v" "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" NAMES "$v")"
done
```

- VERIFY: `tools/decision-need.sh NAMES D1 SD-23 SD-33`; `[ "$EVE_EVIDENCE_LOCATION" = europe-west1 ] && echo ok`; every Mo dataset value is a legal, agent-neutral dataset name:

```bash
for v in MO_METRICS_DS MO_ARCHIVE_DS MO_PRIVATE_DS MO_VIEWS_DS; do printenv "$v" | grep -Eq '^platform_metrics[A-Za-z0-9_]*$' && echo "$v ok"; done
```

  Expect four `ok` lines.

- ROLLBACK: superseding record, only for names not yet created. **IRREVERSIBLE once a create step has used the name.**
- EVIDENCE: record. E-05; TISAX 1.3 (asset register).

#### DC-5.2 Sign the key table (KEYS, SD-47)

- WHO: platform owner; SH (Eve's rings); ITSEC.
- WHERE: record per DC-1.4 (`<date>-key-table.md`).
- ACTION: the record reproduces [../09-supply-chain-secrets-recovery.md](../09-supply-chain-secrets-recovery.md) §2.4 with one correction (SD-47): Eve gets two explicit HSM keys in `EVE_PROJECT`, neither from Autokey — `eve-evidence` in ring `eve` (`europe-west1`) for the locked bucket, and `eve-evidence-eu` in ring `eve-eu` (location `europe`) for the `eve.*` datasets, because a BigQuery dataset in `EU` needs a key from a `europe` key ring. Key rings signed:

  | Ring | Project | Location | Keys | Created in |
  |---|---|---|---|---|
  | `logging` | `KMS_PROJECT` | `europe-west1` | `platform-logs-europe-west1`, per-agent `-content-logs` | 11 |
  | `gemini` | `KMS_PROJECT` | `europe` | `gemini-cmek` (HSM availability in `europe` confirmed at creation) | 11 |
  | `engines` | `KMS_PROJECT` | `europe-west1` | `<agent>-engine-cmek` | 11 |
  | `supply-chain` | `CICD_PROJECT` | `europe-west1` | `binauthz-vuln-gated`, `binauthz-promoted` | 11 |
  | `eve` | `EVE_PROJECT` | `europe-west1` | `eve-evidence`, `eve-approval` (41) | 23 |
  | `eve-eu` | `EVE_PROJECT` | `europe` | `eve-evidence-eu` | 23 |

- VERIFY: `tools/decision-need.sh KEYS SD-47`; `grep -c 'eve-eu' <record>` is at least `1`.
- ROLLBACK: superseding record before 11 or 23 creates a ring. **IRREVERSIBLE once a ring exists.**
- EVIDENCE: record. TISAX 5.1 (the cryptography table).

## 9. Platform model, privilege and the Eve and Mo decisions

#### DC-6.1 Sign the platform model and privilege rows

- WHO: platform owner; ITSEC; ISMS; SH for SD-34, SD-43 and SD-46.
- WHERE: record per DC-1.4 (`<date>-platform-model-and-privilege.md`).
- ACTION: ids P1, P49, SD-19, SD-18, SD-42, SD-46, SD-02, SD-25, SD-05, SD-06, SD-34, SD-43. Body highlights:
  - P1: the tier model and gates C, R, W, P(-SA), X are adopted.
  - P49 and SD-19 (closes X-GE-12): at Tier C `ent-ge-admin` is created with approval not required, requester `ge-admins@`, 1 hour, justification required, because PAM refuses self-approval; the switch to security-reviewer approval is a dated change once PPL-SR is signed; a grant is obtained before any standing `agentspaceAdmin` is removed; P49's "security-reviewer approval" text and 03 §4's "the approver is the same person" are superseded.
  - SD-34 (closes S130): the ladder publisher is `walle-deployer@` in `CICD_PROJECT`, created in 10, granted on `ladder/` in 23 before the lock; it publishes only files from merged commits with two human approvals.
  - SD-43: the accepted limit (a row deletion between two heartbeats is detected, not undone) is signed now by SH and ratified by SR in DC-8.4.
- VERIFY: `tools/decision-need.sh P1 P49 SD-19 SD-18 SD-42 SD-46 SD-02 SD-25 SD-05 SD-06 SD-34 SD-43`.
- ROLLBACK: superseding record before 10 (SD-34) and 12 (entitlements).
- EVIDENCE: record. E-08; TISAX 4.1-4.2.

#### DC-7.1 Sign Eve-H: scope, independence and the consent prerequisites

- WHO: platform owner drafts; **SH co-signs**; ITSEC; IC for SD-08.
- WHERE: record per DC-1.4 (`<date>-eve-h-scope-and-independence.md`).
- ACTION: ids SD-10, SD-12, SD-03, SD-07, SD-08, SD-26, SD-31, SD-32, E-1, E-16, TD-44, CC-33, E-18, WDEC-15. Body:
  - SD-10 (closes S140): Eve is built in two halves; Eve-H (23-28) before Wall-E monitors every roster human and live admin-role holder, and Eve-W (36, 41) after. Eve's page line "none of phases 8 to 11 should be executed until an L3 to L4 promotion" is superseded; only the signing key (41) waits for S4.
  - SD-12 items 1 to 13, including that Eve-H counts as live only after 12 withdraws the organisation exception and the break-glass envelopes are sealed.
  - E-1: Eve lives in `EVE_PROJECT` (answered 2026-09-13; this is its record).
  - E-16 and D2b: eve@'s read-only privilege set and scope list, resolved with `privileges.list`, no content scope, fixed before the consent.
  - TD-44 and CC-33, with SD-31 (closes S035): Eve-H needs no Firestore read. The working choice is CC-33's list endpoint; topology decision 44 option (a) is spiked in 36 when Wall-E's Firestore exists; the final form is signed before 41. Because this is signed before 24, the consent is never followed by a step that is blocked on it.
  - E-18: thresholds of [../../eve/03-lld.md](../../eve/03-lld.md) are signed as **provisional** for 25 and 26, recalibrated from the sandbox drills (28) and at S2 through a reviewed change.
  - Decision 15 (WDEC-15): business-hours time zone and window for H-1.

  Values: `BUSINESS_TZ`, `BUSINESS_HOURS` (or `*tbd*`, in which case H-1 runs flat windows).

```bash
penv_set BUSINESS_TZ "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" WDEC-15 BUSINESS_TZ)"
penv_set BUSINESS_HOURS "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" WDEC-15 BUSINESS_HOURS)"
```

- VERIFY: `tools/decision-need.sh SD-10 SD-12 SD-03 SD-07 SD-08 SD-26 SD-31 SD-32 E-1 E-16 TD-44 CC-33 E-18 WDEC-15`; the record's signature table has a row `SH`. **23 refuses its first step without SD-10 and SD-12; 24 refuses its first step without SD-31, E-16 and TD-44.**
- ROLLBACK: superseding record before 24's consent. The consent itself is irreversible in 24.
- EVIDENCE: record. E-08; TISAX 1.5, 4.1-4.2.

#### DC-7.2 Sign the Mo rows (M-1, SD-24, SD-39)

- WHO: platform owner; Mo owner; ITSEC for SD-24.
- WHERE: record per DC-1.4 (`<date>-mo-decisions.md`).
- ACTION: body:
  - M-1: no byte Mo writes is read by anything that enforces; MD-9 asserts no enforcement identity holds a binding in `MO_PROJECT`.
  - SD-24 (closes S063): Mo reads plan hashes from `walle_audit.plans`; `mo-analyst@` gets no `run.invoker` on `walle-actions`; topology row 8 is retired; MD-3 becomes a denial test that expects refusal; `deny-improvers` needs no exception.
  - SD-39: the toil baseline starts on day one (02), lives in `metrics/` of the platform repository, and 22 loads it with an explicit `bq load`, no expiry. D12's own record is 02's; its tracker row points there.
- VERIFY: `tools/decision-need.sh M-1 SD-24 SD-39 D12`.
- ROLLBACK: superseding record before 22.
- EVIDENCE: record. E-09; TISAX 5.2.

## 10. Wall-E, the gate and the model

#### DC-8.1 Sign Wall-E's scope rows (D2, D4, D6, D10, D11, P29, SD-48)

- WHO: platform owner decides; SR (or ITSEC until appointed) and ISMS sign; SH for SD-48.
- WHERE: record per DC-1.4 (`<date>-wall-e-scope.md`).
- ACTION: D2 is answered here and final before 32's consent; D10 before D2 is final; D4 ratifies the nine blast-radius rows and, with P29, the two lists (hard-denied; band B at tier `SUPER` only); D6 lists other automation writing the same Workspace objects, each with an owner, before 39's Stage 0 record; D11 states that Stage 0 provisions only what Stage 0 uses; SD-48 states that no multi-party approval admin role is ever delegated to `walle@` and that Eve raises severity 1 on any approval action whose actor is a service identity.
- VERIFY: `tools/decision-need.sh D2 D4 D6 D10 D11 P29 SD-48`. D2 may be signed twice: a first answer before 30 and a superseding final list before 32; 32 checks the latest.
- ROLLBACK: superseding record before 32's consent.
- EVIDENCE: record; the two lists' hash. E-01, E-05; TISAX 1.4.

#### DC-8.2 Sign the gate, the penetration-test window and the tabletop date (D13, SD-36, G8-WINDOW, G17-DATE)

- WHO: platform owner; SH; ITSEC (G8); IC (G17); ISMS.
- WHERE: record per DC-1.4 (`<date>-super-admin-gate.md`).
- ACTION: body: the gate lines are **G1-G21** (G1-G18 of SETUP Phase 2, G19 Tier W rows, G20 K7 drill on `fld-agents-p-sa-nonprod` younger than 30 days, G21 Tier C gate closed), not G1-G11; the enforceable gate is the second human's multi-party approval given only against a merged, parsed checklist (38). G8: the penetration-test window (start and end dates, supplier from 04), run in 37 against the sandbox twin before 38. G17: the crisis-scenario tabletop date, run in 38 with the incident commander. Dates may be *tbd* at signing; a superseding record fixes them, and 37 and 38 refuse without a date.
- VERIFY: `tools/decision-need.sh D13 SD-36 G8-WINDOW G17-DATE`; `grep -c 'G21' <record>` at least `1`.
- ROLLBACK: superseding record.
- EVIDENCE: record. E-10; TISAX 1.6, 5.2.

#### DC-8.3 Pin the model on the `eu` endpoint (decision 6, SD-09)

- WHO: platform owner; ITSEC; DPO (processing location).
- WHERE: Google's model pages read on the pin date; record per DC-1.4 (`<date>-model-pin.md`, ids WDEC-6, SD-09).
- ACTION: close **before 35 and before 40's Mo-11**, not at Stage 1. On the pin date, read the candidate's model page and the "Google model endpoint locations" table and record in the body, with the page URLs and the retrieval date: model id; launch stage GA; served on the `eu` multi-region endpoint; ML-processing locations; Standard PayGo locations; retirement date. Accept only if GA on `eu`, retirement at least 6 months after the planned Stage 1 date, and not a Gemini 2.5 model (the 2.5 family on `europe-west1` retires on 2026-10-16 by the Vertex AI release note of 2026-04-02; plan for that date). The review's candidate on 2026-09-15 was `gemini-3.5-flash`. The body also states: the model client location is set to `eu` in agent code; `GOOGLE_CLOUD_LOCATION` is never set in engine `env_vars`; CI refuses a pin retiring within 90 days; 35 verifies one call on the `eu` endpoint. Values: `MODEL_ID`.

```bash
penv_set MODEL_ID "$("$PLATFORM_REPO_DIR/tools/decision-value.sh" WDEC-6 MODEL_ID)"
```

- VERIFY: `tools/decision-need.sh WDEC-6 SD-09`; `need MODEL_ID`; `case "$MODEL_ID" in gemini-2.5*|gemini-2-5*) echo "REFUSED: 2.5 family";; *) echo ok;; esac`.
- ROLLBACK: superseding record (re-pin procedure in 42).
- EVIDENCE: record with page URLs and retrieval date. E-11; TISAX 6.1.

#### DC-8.4 Security reviewer ratification (RATIFY-SR)

- WHO: security reviewer. Runs once PPL-SR is signed, and before 30 (Tier W).
- WHERE: record per DC-1.4 (`<date>-security-reviewer-ratification.md`).
- ACTION: the reviewer lists every record signed by ITSEC in place of SR (DC-4.1, DC-4.3, DC-6.1, DC-8.1) by file name and body hash, and either ratifies each or opens a superseding record; signs SD-43's accepted limit; confirms the SH-REPORTS switch (DC-2.3).
- VERIFY: `tools/decision-need.sh RATIFY-SR`; every file name in the record exists: `awk -F'|' '/^## Values/{s=1} s && /\.md/ {gsub(/ /,"",$3); print $3}' <record> | while read f; do test -f "$PLATFORM_REPO_DIR/decisions/$f" || echo "missing $f"; done` prints nothing.
- ROLLBACK: superseding record.
- EVIDENCE: record. E-03; TISAX 1.4.

## 11. The checklist: every decision, its gate and its signatories

`Close before` names the file and the step that refuses without the record. Record paths are `decisions/YYYY-MM-DD-<slug>.md` in the platform repository; the slug is given, the date is the drafting date.

### 11.1 Setup decisions SD-01 to SD-48

| Id | Short title | Close before (file: step) | Signatories | Record slug |
|---|---|---|---|---|
| SD-01 | Bootstrap deviation from the factory | 06: first step | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-02 | Gate split; env=nonprod P-SA row | 16: register CI rules | PO, ITSEC, ISMS | platform-model-and-privilege |
| SD-03 | G-4 evidence from pre-grant events | 28: proof | PO, SH, ITSEC | eve-h-scope-and-independence |
| SD-04 | Witness administrators are not tenant super admins | 04: witness purchase; 08: W-1 | ITSEC, ISMS, FIN, WA1, WA2, SH, PO | witness-organisation |
| SD-05 | Twin OAuth clients External, In production, Trusted | 24: twin consent | PO, ITSEC, ISMS | platform-model-and-privilege |
| SD-06 | Sandbox organisation's own sinks | 21: sandbox logging; 24: twin sink | PO, ITSEC, ISMS | platform-model-and-privilege |
| SD-07 | Hourly heartbeat, 90-minute and 23.5-hour windows | 26: export jobs | PO, SH, ITSEC | eve-h-scope-and-independence |
| SD-08 | Severity 1 on the paging service plus witness backstop | 15: part A | PO, SH, ITSEC, IC | eve-h-scope-and-independence |
| SD-09 | Model pinned on `eu` | 35: engine; 40: Mo-11 | PO, ITSEC, DPO | model-pin |
| SD-10 | Eve-H before Wall-E | 23: first step | PO, **SH**, ITSEC | eve-h-scope-and-independence |
| SD-11 | Monitoring named administrators | 25: reconciler and poll jobs (BLOCKED until signed) | DPO, PO, **SH**, HR | monitoring-of-administrators |
| SD-12 | The monitored administrator installs Eve | 06: `eve-owners@`; 23: first step | PO, **SH**, ITSEC | eve-h-scope-and-independence |
| SD-13 | Gemini Enterprise baseline after Tier R | 19: first step | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-14 | Git host before Tier R; repository in 03 | DC-9.2; 10: WIF provider | PO, ITSEC | git-host-and-repository |
| SD-15 | SCC payer and activation order | 04: SCC purchase; 09: activation | ITSEC, FIN, PO | billing-scc-and-siem |
| SD-16 | Dedicated EUR billing account | 07: first step | FIN, BA, PO | billing-scc-and-siem |
| SD-17 | Observability location, no Logging folder default | 09: location step | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-18 | Missing makers; `ent-org-sink` approved by SH | 12: `ent-org-sink` | PO, ITSEC, ISMS, SH | platform-model-and-privilege |
| SD-19 | `ent-ge-admin` no-approval at Tier C | 12: `ent-ge-admin`; 19 | PO, ITSEC, ISMS | platform-model-and-privilege |
| SD-20 | Live-app safety; never lower retention | 19: first write | DPO, PO, MOO, SH, HR | retention |
| SD-21 | App location `eu` only | 05: location record | PO | gemini-app-location |
| SD-22 | Deny-policy principal form | 13: deny policies | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-23 | Eve's bucket in `europe-west1` | 23: bucket create (IRREVERSIBLE location) | PO, SH, MOO, WA1, WA2, ITSEC | names-register |
| SD-24 | No `run.invoker` for `mo-analyst@` | 22: first step; 36: Mo-6 | PO, MOO, ITSEC | mo-decisions |
| SD-25 | Sandbox customer id on nonprod folders | 21: folder admission | PO, ITSEC, ISMS | platform-model-and-privilege |
| SD-26 | Drill split sandbox and witness | 28: drills | PO, SH, ITSEC, IC | eve-h-scope-and-independence |
| SD-27 | Paper custody records until W-2 | 06: first key enrolment | ITSEC, PO, SH | roster-reduction-and-custody |
| SD-28 | Witness billing, support, domain, constraints | 04: witness purchase; 08: W-1 | ITSEC, ISMS, FIN, WA1, WA2, SH, PO | witness-organisation |
| SD-29 | Sandbox before the grant; edition | 04: sandbox purchase; 21 | PO, ITSEC, FIN | sandbox-tenant |
| SD-30 | Self-recovery Off and multi-party approval on gate day | 06 (not set there); 38 | ITSEC, PO, SH | roster-reduction-and-custody |
| SD-31 | Decision 44 or CC-33 before Eve's consent | 24: first step | PO, SH, ITSEC | eve-h-scope-and-independence |
| SD-32 | 24 is eve@'s only creator; staging OU | 24: eve@ create | PO, SH, ITSEC | eve-h-scope-and-independence |
| SD-33 | Mo dataset names `platform_metrics*` | 22: dataset creates (IRREVERSIBLE) | PO, SH, MOO, WA1, WA2, ITSEC | names-register |
| SD-34 | Ladder publisher `walle-deployer@` | 10: identity create; 23: `ladder/` grant | PO, ITSEC, ISMS, SH | platform-model-and-privilege |
| SD-35 | Mutating tests only on the twin | 37; 39 | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-36 | Gate G1-G21; Stage 0-pre and Stage 0 | 38: assignment | PO, SH, ITSEC, IC, ISMS | super-admin-gate |
| SD-37 | setup/ is canonical; script only when fixed | 30: first step | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-38 | Evidence home during the build | 06: first evidence | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-39 | Toil baseline in the platform repository | 22: baseline load | PO, MOO, ITSEC | mo-decisions |
| SD-40 | No interim organisation sinks | 14: sinks | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-41 | Model Armor floor precedence | 18: floor | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-42 | Singleton entitlement variants | 12: `ent-factory-singleton-*` | PO, ITSEC, ISMS | platform-model-and-privilege |
| SD-43 | Eve's stores: tamper detection, accepted limit | 23: writer roles; SR ratifies before S2 | PO, ITSEC, ISMS, SH; SR in RATIFY-SR | platform-model-and-privilege |
| SD-44 | `exists_or_pending` for foreign grants | 10: first grant | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-45 | The owner's order | 06: first step | PO, ITSEC, ISMS | setup-conventions-and-bootstrap-deviation |
| SD-46 | `ent-bootstrap-module` per non-singleton folder | 12: entitlements; 18; 22 | PO, ITSEC, ISMS, SH | platform-model-and-privilege |
| SD-47 | Eve's second key ring `eve-eu` | 23: ring creates (IRREVERSIBLE) | PO, SH, ITSEC | key-table |
| SD-48 | The robot never approves multi-party requests | 25: catalogue; 38 | PO, SR or ITSEC, ISMS, SH | wall-e-scope |

### 11.2 Wall-E decisions

| Id | Decision (corrected) | Close before (file: step) | Signatories | Record slug |
|---|---|---|---|---|
| D1 | Names, including OAuth app names | 10 (projects); 32 (app name at consent) | as NAMES | names-register |
| D2 | Two frozen scope lists, `cloud-platform` in neither | answer before 30; final before 32: consent | PO, SR or ITSEC, ISMS | wall-e-scope |
| D3 | Sandbox OU, pilot OU, sandbox tenant | 21; 30: OUs | PO, ITSEC, FIN | sandbox-tenant |
| D4 | Nine blast-radius rows and the two lists | 38: G7 | PO, SR or ITSEC, ISMS | wall-e-scope |
| D5 | Second operator; IT security second approver | 30: operators group | ISMS, SO, PO | appointment-second-operator |
| D6 | Inventory of other writers with owners | 39: Stage 0 record | PO, SR or ITSEC, ISMS | wall-e-scope |
| D7 | Data-protection answer | letter by 2026-09-21 (DC-3.1); answer before 39's Stage 1 entry; SD-11 half before 25 | DPO, HR, LEGAL, PO | monitoring-of-administrators or d7-answer |
| D8 | App location **`eu` only** | 05: location record | PO | gemini-app-location |
| D10 | Operations per band A, B, C | before D2's final list | PO, SR or ITSEC, ISMS | wall-e-scope |
| D11 | Stage 0 provisions only what Stage 0 uses | 30: first step | PO, SR or ITSEC, ISMS | wall-e-scope |
| D12 | The three toil tasks; baseline **starts on day one** | 02: first step (its own record) | PO | 02's record |
| D13 | Gate **G1-G21** | 38: assignment | PO, SH, ITSEC, IC, ISMS | super-admin-gate |
| WDEC-6 | Model pin (decision 6) **before 35**, not at Stage 1 | 35: engine; 40: Mo-11 | PO, ITSEC, DPO | model-pin |
| WDEC-15 | Business hours and time zone (decision 15) | 25: H-1 | PO, SH, ITSEC, IC | eve-h-scope-and-independence |
| WDEC-29 | Sandbox tenant **before the super-admin grant** (decision 29) | 04: purchase; 21 | PO, ITSEC, FIN | sandbox-tenant |

### 11.3 Eve decisions

| Id | Decision | Close before (file: step) | Signatories | Record slug |
|---|---|---|---|---|
| E-1 | Eve in `EVE_PROJECT` | 23: first step | PO, SH, ITSEC | eve-h-scope-and-independence |
| E-2 | Owner: the second human outside the line | 06: `eve-owners@`; 38 | ISMS, SH, PO | appointment-second-human |
| E-14 | Retention floor and ceiling | 23: table expiry and lock | DPO, PO, MOO, SH, HR | retention |
| E-16 | eve@'s privilege and scope set (with D2b) | 24: consent | PO, SH, ITSEC | eve-h-scope-and-independence |
| E-18 | Thresholds, provisional for Eve-H | 25: `thresholds.yaml` | PO, SH, ITSEC | eve-h-scope-and-independence |
| TD-44 | Topology decision 44: Eve's Firestore read form | 24: first step (working choice); 41 (final) | PO, SH, ITSEC | eve-h-scope-and-independence |
| CC-33 | List endpoint `GET /v1/plans?state=pending_eve` | as TD-44 | PO, SH, ITSEC | eve-h-scope-and-independence |

### 11.4 Mo decisions

| Id | Decision | Close before (file: step) | Signatories | Record slug |
|---|---|---|---|---|
| M-1 | No byte Mo writes is read by enforcement | 22: first step | PO, MOO, ITSEC | mo-decisions |
| M-5 | Retention floor; owner of the off-project copy | 22: partition expiry; 40 (copy owner) | DPO, PO, MOO, SH, HR | retention |
| M-7 | Git host and admin bypass audited | DC-9 | PO, ITSEC | git-host-and-repository |
| SD-33 | Agent-neutral dataset names | 22: dataset creates | as NAMES | names-register |

### 11.5 Platform decisions

| Id | Decision (corrected) | Close before (file: step) | Signatories | Record slug |
|---|---|---|---|---|
| P1 | Tier model and gates | 09: first step | PO, ITSEC, ISMS | platform-model-and-privilege |
| P10 | SIEM kind and MDR | 04: purchase; 15: part B | ITSEC, FIN, PO | billing-scc-and-siem |
| P11 | SCC Premium payer, closed at stage 1 | 04: purchase; 09: activation | ITSEC, FIN, PO | billing-scc-and-siem |
| P13 | Retention ceilings and lock values | 08: W-2 lock; 14: locks; 23: lock | DPO, PO, MOO, SH, HR | retention |
| P14 | Witness domain, edition, billing, administrators | 04: witness purchase; 08: W-1 | ITSEC, ISMS, FIN, WA1, WA2, SH, PO | witness-organisation |
| P22 | Git host, **before Tier R** | DC-9.2; 10: WIF provider; 13: B19 | PO, ITSEC | git-host-and-repository |
| P29 | The two lists | 38: G7 | PO, SR or ITSEC, ISMS | wall-e-scope |
| P31 | Billing account and its administrator | 07: first step | FIN, BA, PO | billing-scc-and-siem |
| P49 | Gemini Enterprise administration model | 12: `ent-ge-admin` | PO, ITSEC, ISMS | platform-model-and-privilege |
| P52 | Conversation retention: **never lowered by the baseline**; no value set from 30 days | 19: retention step | DPO, PO, MOO, SH, HR | retention |
| P137 | Five humans at the grant (§5, DC-2.8) | 30 (three at Tier W); 38 (five) | ISMS, ITSEC, PO | separation-and-count |

### 11.6 Added rows

| Id | Decision | Close before (file: step) | Signatories | Record slug |
|---|---|---|---|---|
| D7-LETTER | Letter sent in week one | by 2026-09-21 | PO | d7-letter |
| G3-ROSTER | Every super admin other than `sa-1-admin@`, `sa-2-admin@` moved to a delegated role | 06: reduction step | ITSEC, PO, SH | roster-reduction-and-custody |
| NAMES | Project ids, datasets, buckets, OU and app names | 09 (tag keys), 10, 11, 21, 22, 23, 31: every IRREVERSIBLE naming step | PO, SH, MOO, WA1, WA2, ITSEC | names-register |
| KEYS | Key table with `eve-eu` | 11 and 23: ring creates | PO, SH, ITSEC | key-table |
| SH-REPORTS | Reports about SH go to SR, or IC until SR is named | 26: first step (**BLOCKED while neither is named**) | ISMS, ITSEC, PO | recipient-of-reports-about-second-human |
| G8-WINDOW | Penetration-test window | 04: purchase; 37: test | ITSEC, PO | super-admin-gate |
| G17-DATE | Tabletop date | 38: tabletop | IC, PO | super-admin-gate |
| RATIFY-SR | Security reviewer ratifies ITSEC-signed rows | 30: first step | SR | security-reviewer-ratification |
| PPL-* | The twelve appointments of §5 | as §5 | as §5 | appointment-<role> |

## 12. The platform repository

Runs once DC-4.3 is signed and before 06 commits the roster. DC-9.2 to DC-9.7 run in one shell sitting that holds `repo`; any later shell re-derives it with `repo=$(printf '%s' "$PLATFORM_REPO_REMOTE" | sed -E 's#^https://github.com/##; s#\.git$##')`. The steps are written for GitHub. If P22 chooses GitLab, §12.1 gives the equivalent settings and DC-9.2 to DC-9.8 are re-issued as a dated revision of this page before execution; nothing is improvised at the keyboard.

#### DC-9.1 Prove every local commit has a review record

- WHO: platform owner; second operator (or SH) confirms the list.
- WHERE: shell with `~/.platform-env` sourced.
- ACTION:

```bash
source ~/.platform-env
need PLATFORM_REPO_DIR BUILD_LOG_DIR GIT_HOST
"$PLATFORM_REPO_DIR/tools/decision-need.sh" P22 SD-14 M-7
git -C "$PLATFORM_REPO_DIR" rev-list --reverse HEAD > "$BUILD_LOG_DIR/03-prepush-commits.txt"
while read -r c; do test -f "$BUILD_LOG_DIR/reviews/$c.md" || echo "NO REVIEW $c"; done < "$BUILD_LOG_DIR/03-prepush-commits.txt"
```

- VERIFY: the loop prints nothing. A commit without a record gets one now (the reviewer reads the diff with `git -C "$PLATFORM_REPO_DIR" show <sha>`) or is reverted before the push.
- ROLLBACK: none; read only.
- EVIDENCE: `03-prepush-commits.txt` and the review records. E-05; TISAX 5.2.

#### DC-9.2 Create the repository on the git host

- WHO: platform owner as organisation owner on the git host; ITSEC witnesses the settings in DC-9.6.
- WHERE: shell; `gh` signed in (`gh auth status`).
- ACTION: the repository name is the one in NAMES (`*tbd*` until signed).

```bash
repo="<git-org>/<name-from-NAMES>"
gh repo create "$repo" --private --description "Agentic platform: register, policies, rosters, decisions" --disable-wiki
```

- VERIFY: `gh repo view "$repo" --json visibility,defaultBranchRef --jq '.visibility'` prints `PRIVATE`.
- ROLLBACK: before any push, `gh repo delete "$repo"` (asks for confirmation; permanent). After the push, not rolled back: the protected history is evidence.
- EVIDENCE: build-log line with the repository URL. E-05; TISAX 5.2.

#### DC-9.3 Write access for humans only

- WHO: platform owner; ITSEC confirms.
- WHERE: shell; git host organisation settings.
- ACTION: grant write only to the named humans' accounts (platform owner, second human, second operator; the security reviewer and Mo owner when appointed), through a team whose members are those accounts. No bot account, machine user or app installation receives write or maintain. Then list:

```bash
gh api "repos/$repo/collaborators?affiliation=all" --paginate --jq '.[] | [.login, .type, .role_name] | @tsv'
```

- VERIFY: every row has type `User`; every login with a role other than `read` or `triage` is on the appointment records. App installations with write access are read by eye in the organisation settings under GitHub Apps; none may have repository write on this repository, and the finding is written to the build log.
- ROLLBACK: remove the grant (`gh api -X DELETE "repos/$repo/collaborators/<login>"`).
- EVIDENCE: the listing in the build log. TISAX 4.1-4.2, 5.2.

#### DC-9.4 Commit CODEOWNERS with the second human on the control files

- WHO: platform owner writes; SH reviews the commit (review record).
- WHERE: shell with `~/.platform-env` sourced.
- ACTION: CODEOWNERS identifies owners by the email verified on their git-host account. Only one owner is listed on each control path, because any listed owner's approval satisfies the rule. Paths are fixed here; 06, 15 and 16 place `ROSTER_FILE`, `CONTROL_GROUPS_FILE`, `ONCALL_FILE` and the ladder under them.

```bash
need SECOND_HUMAN_EMAIL OWNER_DAILY_ACCOUNT
mkdir -p "$PLATFORM_REPO_DIR/.github"
cat > "$PLATFORM_REPO_DIR/.github/CODEOWNERS" <<EOF
*                  $OWNER_DAILY_ACCOUNT
/roster/           $SECOND_HUMAN_EMAIL
/control-groups/   $SECOND_HUMAN_EMAIL
/eve/              $SECOND_HUMAN_EMAIL
/oncall/           $SECOND_HUMAN_EMAIL
/ladder/           $SECOND_HUMAN_EMAIL
/decisions/        $SECOND_HUMAN_EMAIL
/tools/decision-*  $SECOND_HUMAN_EMAIL
/.github/          $SECOND_HUMAN_EMAIL
EOF
git -C "$PLATFORM_REPO_DIR" add .github/CODEOWNERS
git -C "$PLATFORM_REPO_DIR" commit -m "DC-9.4 CODEOWNERS: second human on control files"
```

  Then the review record as in DC-1.3, reviewer SH.
- VERIFY: `grep -c "$SECOND_HUMAN_EMAIL" "$PLATFORM_REPO_DIR/.github/CODEOWNERS"` prints `8`; after the push (DC-9.5), the git host shows no CODEOWNERS errors: `gh api "repos/$repo/codeowners/errors" --jq '.errors | length'` prints `0`.
- ROLLBACK: revert the commit (reviewed).
- EVIDENCE: commit, review record. TISAX 4.1-4.2, 5.2.

#### DC-9.5 Push the local history and set the remote

- WHO: platform owner.
- WHERE: shell with `~/.platform-env` sourced.
- ACTION: the push is the one moment a commit reaches `main` without a pull request; each such commit already has a signed review record (DC-9.1) and the push is a bootstrap deviation entry.

```bash
remote="https://github.com/$repo.git"
git -C "$PLATFORM_REPO_DIR" branch -M main
git -C "$PLATFORM_REPO_DIR" remote add origin "$remote"
git -C "$PLATFORM_REPO_DIR" push -u origin main
penv_set PLATFORM_REPO_REMOTE "$remote"
printf '%s|DC-9.5|initial push of %s commits with review records|%s\n' "$(date +%F)" "$(wc -l < "$BUILD_LOG_DIR/03-prepush-commits.txt" | tr -d ' ')" "$remote" >> "$DEVIATION_REGISTER"
```

- VERIFY: `git -C "$PLATFORM_REPO_DIR" rev-parse HEAD` equals `gh api "repos/$repo/branches/main" --jq .commit.sha`; `need PLATFORM_REPO_REMOTE`.
- ROLLBACK: none for pushed history; mistakes are reverted through pull requests after DC-9.6.
- EVIDENCE: deviation register line; build log. E-05; TISAX 5.2.

#### DC-9.6 Branch protection: two human reviewers, code owners, administrators included

- WHO: platform owner applies; ITSEC witnesses on screen.
- WHERE: shell.
- ACTION: status checks are added by 16 when the register CI exists.

```bash
p=$(mktemp)
cat > "$p" <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "require_code_owner_reviews": true,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true
}
EOF
gh api -X PUT "repos/$repo/branches/main/protection" --input "$p"
rm "$p"
```

- VERIFY:

```bash
gh api "repos/$repo/branches/main/protection" --jq '{reviews: .required_pull_request_reviews.required_approving_review_count, codeowners: .required_pull_request_reviews.require_code_owner_reviews, lastpush: .required_pull_request_reviews.require_last_push_approval, admins: .enforce_admins.enabled, force: .allow_force_pushes.enabled, deletions: .allow_deletions.enabled}'
```

  Expect `reviews` 2, `codeowners` true, `lastpush` true, `admins` true, `force` false, `deletions` false.
- ROLLBACK: `gh api -X DELETE "repos/$repo/branches/main/protection"` only under a reviewed decision; the deletion itself is audited (DC-9.8).
- EVIDENCE: the verify JSON in the build log; ITSEC's witness line. TISAX 5.2.

#### DC-9.7 Negative tests: a direct push and a one-approval merge are refused

- WHO: platform owner attempts; SH observes the pull request.
- WHERE: shell in a scratch clone.
- ACTION:

```bash
w=$(mktemp -d)
git clone "$PLATFORM_REPO_REMOTE" "$w/r"
git -C "$w/r" commit --allow-empty -m "DC-9.7 negative test: direct push"
git -C "$w/r" push origin HEAD:main; echo "direct push exit=$?"
git -C "$w/r" reset --hard origin/main
git -C "$w/r" checkout -b dc-9-7-negative-test
mkdir -p "$w/r/roster"
printf 'negative test\n' > "$w/r/roster/DC-9.7-test.txt"
git -C "$w/r" add roster/DC-9.7-test.txt
git -C "$w/r" commit -m "DC-9.7 negative test: roster path"
git -C "$w/r" push origin dc-9-7-negative-test
gh pr create --repo "$repo" --head dc-9-7-negative-test --title "DC-9.7 negative test (do not merge)" --body "Expect: blocked without the second human and a second approval."
```

  The second operator approves once (not SH). Then:

```bash
gh pr view dc-9-7-negative-test --repo "$repo" --json mergeStateStatus,reviewDecision --jq '[.mergeStateStatus, .reviewDecision] | @tsv'
gh pr close dc-9-7-negative-test --repo "$repo" --delete-branch
rm -rf "$w"
```

- VERIFY: the direct push prints a protected-branch refusal and `exit=1` (non-zero); the pull request shows `BLOCKED` and `REVIEW_REQUIRED` after one approval.
- ROLLBACK: the pull request is closed and its branch deleted in the action.
- EVIDENCE: refusal text and PR state in the build log. TISAX 5.2.

#### DC-9.8 Audit administrator bypass

- WHO: ITSEC runs weekly until 15 part B puts the query in the SIEM; the platform owner never runs it alone.
- WHERE: shell as a git-host organisation owner. Assumption: the organisation is on a GitHub plan that exposes the organisation audit-log API.
- ACTION:

```bash
for a in protected_branch.policy_override protected_branch.review_policy_override protected_branch.update_admin_enforced protected_branch.destroy repository_ruleset.update repository_ruleset.destroy; do
  gh api "orgs/<git-org>/audit-log?phrase=action:$a+repo:$repo" --paginate --jq '.[] | [.["@timestamp"], .action, .actor] | @tsv'
done
```

- VERIFY: on the day of DC-9.6 the output is empty apart from the protection set-up itself; any later `policy_override` is a severity 2 finding to the incident commander.
- ROLLBACK: none; read only.
- EVIDENCE: dated output in the build log; the weekly entry in `DRILL_CALENDAR` until 15 takes it over. TISAX 5.2, 1.5.

#### DC-9.9 Refuse approvals by service accounts and bot users — **BLOCKED**

- WHO: platform owner writes the rule; security reviewer (or ITSEC) reviews.
- WHERE: platform repository CI.
- ACTION: **BLOCKED until the bot-approval CI rule is committed to the platform repository by file [16-register-and-shared-registry.md](16-register-and-shared-registry.md)** (plan §8, "gate-checklist parser, bot-approval and ladder-raise CI rules"). The git host counts any approval from an account with write access; it does not tell humans from machine users. The rule must fail a pull request whose approvals include any account not on the appointment records, and must be a required status check added to DC-9.6's protection. Interim control, until committed: DC-9.3 keeps write access to named humans only, and ITSEC repeats DC-9.3's listing weekly with DC-9.8.
- VERIFY: once committed: a test pull request approved by a non-human account fails the check.
- ROLLBACK: remove the required check through a reviewed change.
- EVIDENCE: the weekly DC-9.3 listing until then. TISAX 5.2.

#### DC-9.10 Merge the bootstrap review records through the protected path

- WHO: platform owner opens the pull request; the second human (code owner of `/decisions/`) and the second operator approve.
- WHERE: shell in a clone of `PLATFORM_REPO_REMOTE`.
- ACTION: the review records of the commits pushed in DC-9.5 join the repository they describe, under review, so the pushed history and its approvals travel together.

```bash
w=$(mktemp -d)
git clone "$PLATFORM_REPO_REMOTE" "$w/r"
git -C "$w/r" checkout -b dc-9-10-bootstrap-reviews
mkdir -p "$w/r/decisions/bootstrap-reviews"
while read -r c; do cp "$BUILD_LOG_DIR/reviews/$c.md" "$w/r/decisions/bootstrap-reviews/$c.md"; done < "$BUILD_LOG_DIR/03-prepush-commits.txt"
git -C "$w/r" add decisions/bootstrap-reviews
git -C "$w/r" commit -m "DC-9.10 review records of the bootstrap push"
git -C "$w/r" push origin dc-9-10-bootstrap-reviews
gh pr create --repo "$repo" --head dc-9-10-bootstrap-reviews --title "DC-9.10 bootstrap review records" --body "One review record per commit pushed in DC-9.5."
```

  After two approvals, one of them the second human's, merge in the git host's interface; then `rm -rf "$w"`.
- VERIFY: `gh pr view dc-9-10-bootstrap-reviews --repo "$repo" --json state --jq .state` prints `MERGED`; the file count under `decisions/bootstrap-reviews/` on `main` equals the line count of `03-prepush-commits.txt`.
- ROLLBACK: before merge, close the pull request; after merge, a reverting pull request under the same protection.
- EVIDENCE: the merged pull request URL with its two approvals. E-05; TISAX 5.2.

### 12.1 GitLab equivalents, if P22 chooses GitLab

| Requirement | GitLab setting (API attribute), per GitLab's API pages read 2026-09-15 |
|---|---|
| No direct push, no force push | `POST /projects/:id/protected_branches` with `name=main`, `push_access_level=0`, `allow_force_push=false` |
| Merge only by maintainers | `merge_access_level=40` |
| Code owners required | `code_owner_approval_required=true` (Premium or Ultimate) |
| Two approvals | `POST /projects/:id/approval_rules` with `approvals_required=2` |
| Author and committers cannot approve | `POST /projects/:id/approvals` with `merge_requests_author_approval=false`, `merge_requests_disable_committers_approval=true` |
| Rules not editable per merge request; approvals reset on push | `disable_overriding_approvers_per_merge_request=true`, `reset_approvals_on_push=true` |
| Issuer for 10 | `https://gitlab.com` (GitLab SaaS only) |
| Bypass audit | audit event names *tbd*: read on the day of the re-issue |

## 13. Verification checklist for the whole part

- [ ] `tools/decision-check.sh decisions/20*.md` prints only `OK` lines (every record parses, every signature matches).
- [ ] `tools/decision-need.sh` over the ids gating 04 to 09 prints `SIGNED` for each: `D7-LETTER PPL-SH E-2 PPL-IC SH-REPORTS PPL-WA1 PPL-WA2 PPL-BA SD-01 SD-04 SD-12 SD-13 SD-14 SD-15 SD-16 SD-17 SD-21 SD-27 SD-28 SD-29 SD-30 SD-38 SD-45 D8 P1 P10 P11 P14 P22 P31 WDEC-29 G3-ROSTER NAMES`.
- [ ] The D7 letter left on or before 2026-09-21.
- [ ] `need MODEL_ID` is expected to fail until DC-8.3; every other variable in §14's list is set or deliberately `*tbd*` with its tracker row open.
- [ ] `PLATFORM_REPO_REMOTE` is set; DC-9.6's verify JSON matches; DC-9.7's refusals are recorded.
- [ ] No wiki page, no build-log line and no record contains a secret; `grep -rIiE 'password|secret|token' "$PLATFORM_REPO_DIR/decisions"` shows only prose about secrets, never a value.
- [ ] Every record's evidence mails are in `EVIDENCE_INTERIM_LOCATION` and each has an `EVIDENCE_REGISTER` line.
- [ ] The count record (DC-2.8) says five humans at the grant.

## 14. What the next files need from this one

| Variable or record | Consumed by | Refuse when |
|---|---|---|
| `tools/decision-need.sh`, `tools/decision-value.sh`, `decisions/TRACKER.md` | every later file, first step | a gated id is not `SIGNED` |
| `SECOND_HUMAN_EMAIL` | 06, 15, 23, 24, 26, 28 | empty |
| `INCIDENT_COMMANDER_EMAIL`, SH-REPORTS | 15, 24, 26 | 26 BLOCKED while neither SR nor IC named |
| `SECURITY_REVIEWER_EMAIL`, `VALIDATOR_CUSTODIAN_EMAIL` | 11, 24, 26, 31, 38, 40 | `*tbd*` stops the custodian part and the P-SA production entitlement |
| `SECOND_OPERATOR_EMAIL`, `BLIND_GRADER_EMAIL` | 02, 30, 39, 40 | empty at 30 |
| `WITNESS_ADMIN_1_EMAIL`, `WITNESS_ADMIN_2_EMAIL` | 08, 27 | empty |
| `SANDBOX_SA_1_EMAIL`, `SANDBOX_SA_2_EMAIL` | 21, 24, 37 | empty at 21 |
| `BILLING_ADMIN_EMAIL` | 07, 14 | empty |
| `MO_OWNER_EMAIL` | 22, 29, 40 | empty |
| `DPO_CONTACT` | 19, 25 | empty |
| `GIT_HOST`, `GIT_OIDC_ISSUER`, `PLATFORM_REPO_REMOTE` | 06, 10, 13, 15, 16 | empty; 06 and 16 also check that `ROSTER_FILE`, `CONTROL_GROUPS_FILE`, `ONCALL_FILE` and the ladder sit under `/roster/`, `/control-groups/`, `/oncall/`, `/ladder/` so CODEOWNERS covers them |
| `SIEM_KIND`, `SCC_BILLING_MODEL` | 04, 09, 15 | not one of the listed values |
| `EVIDENCE_RETENTION_DAYS`, `IDENTITY_RETENTION_DAYS` | 08, 14, 23 | not an integer at a lock |
| `BUSINESS_TZ`, `BUSINESS_HOURS` | 25 | `*tbd*` means flat windows, recorded |
| `MO_METRICS_DS`, `MO_ARCHIVE_DS`, `MO_PRIVATE_DS`, `MO_VIEWS_DS` | 22, 29, 36, 40 | differ from NAMES |
| `EVE_EVIDENCE_LOCATION` | 23 | not `europe-west1` |
| `MODEL_ID` | 35, 40 | empty or a 2.5 model |
| NAMES, KEYS records | 09, 10, 11, 21, 22, 23, 31 | unsigned before an IRREVERSIBLE create |
| Signed decision records | README tracker; 42 evidence register | — |

## 15. Review findings closed

| Finding | How this file closes it | Step |
|---|---|---|
| S035 | Decision 44 or CC-33 and E-16 are signed before 24's consent; Eve-H needs no Firestore read | DC-7.1 |
| S051 | P22 moved before Tier R; issuer and host set; repository created before 06 | DC-4.3, DC-9 |
| S063 | SD-24 signed: no `run.invoker` for `mo-analyst@`; MD-3 expects refusal | DC-7.2 |
| S130 | SD-34 signed: `walle-deployer@` in `CICD_PROJECT` is the ladder publisher | DC-6.1 |
| S135 | SD-23 signed: `EVE_EVIDENCE_LOCATION=europe-west1`, gating 23's bucket | DC-5.1 |
| S140 | SD-10 supersedes "hold phases 8 to 11"; decision 44 row and provisional E-18 added before the consent | DC-7.1 |
| S144 | SD-33 signed: `platform_metrics*` names, `MO_*_DS` set before 22 | DC-5.1 |
| X-GE-12 | P49 aligned with 04: no-approval at Tier C, security-reviewer approval later as a dated change | DC-6.1 |
| X-GE-13 | D8 reads `eu` only; global or us stops 05 | DC-4.2 |
| X-ORG-05 | Two witness administrators named who are not tenant super admins; SH is owner of record; count is five | DC-2.5, DC-2.8, DC-4.6 |
| X-ORG-08 | Witness billing account parented by the witness organisation | DC-4.6 |
| X-ORG-09 | Separately registered witness domain outside the tenant and the line | DC-4.6 |
| X-ORG-14 | Decision 29 reads "before the super-admin grant"; sandbox edition, domain, seats and admins decided in stage 1 | DC-4.7, DC-2.6 |
| X-RQB-01 | Decision 6 closed before 35 and Mo-11 on the `eu` endpoint, no 2.5 model | DC-8.3 |
| X-RQB-04 | P11 payer closed at stage 1 by IT security and finance; activation before any location policy | DC-4.5 |
| X-RQB-05 | Dedicated EUR billing account, named administrator, scoped roles | DC-4.5, DC-2.7 |

Deferred: none. The executing halves of these findings are in the gated files (05, 07, 08, 09, 21, 22, 23, 24, 35, 36, 40), each of which refuses to run on an unsigned record.

## 16. Facts checked on 2026-09-15

| Fact used | Source |
|---|---|
| Project ids are permanent and cannot be reused after deletion; 6-30 characters | Resource Manager, "Creating and managing projects" |
| Key rings cannot be deleted; deleted key names cannot be reused | Cloud KMS, "Resource hierarchy" |
| Dataset names and locations cannot be changed; name characters | BigQuery, "Introduction to datasets" |
| An `EU` dataset needs a key ring in `europe` | BigQuery, "Customer-managed Cloud KMS keys" |
| A tag key's short name cannot be changed | Resource Manager, "Creating and managing tags" |
| A locked retention policy cannot be removed or reduced | Cloud Storage, "Bucket Lock" |
| `roles/billing.user`, `roles/billing.costsManager`; `gcloud billing accounts describe` is GA; `currencyCode`, `masterBillingAccount`, `open` fields | Cloud Billing access control; gcloud reference; Billing API `billingAccounts` |
| Disabling billing stops a project's services; some resources may be non-recoverable | Cloud Billing, "Enable, disable, or change billing for a project" |
| SCC data residency chosen at first activation; a location policy after automatic Standard activation may deactivate SCC | Security Command Center, "Data residency support" |
| PAM: "You can't approve your own request." | IAM, "Approve or deny grants" |
| Admin roles: `Menu > Account > Admin roles`, select the role, **View admins** | Workspace Admin Help, "Assign specific admin roles" |
| WIF issuers: `https://token.actions.githubusercontent.com/`, `https://gitlab.com` | IAM, "Configure Workload Identity Federation with deployment pipelines" |
| Branch protection body fields; approvals count from write access or code owners; administrators exempt unless enforced | GitHub REST "Branch protection"; GitHub Docs "About protected branches" |
| CODEOWNERS location, email owners, write access needed, any owner's approval suffices | GitHub Docs "About code owners" |
| `gh repo create` flags | GitHub CLI manual |
| Audit events `protected_branch.policy_override` and related; `GET /orgs/{org}/audit-log` needs an organisation owner | GitHub Enterprise Cloud audit-log events; REST "Get the audit log for an organization" |
| GitLab protected-branch and approval attributes | GitLab API "Protected branches", "Merge request approvals" |

Not verified by this page on 2026-09-15 (the pages did not render for the writer): the Gemini model page and endpoint-locations table and the SCC pricing page. The model and pricing facts above come from the review's verified findings X-RQB-01 and X-RQB-04 (2026-09-15); DC-8.3 and DC-4.5 re-read them on the signing day.
