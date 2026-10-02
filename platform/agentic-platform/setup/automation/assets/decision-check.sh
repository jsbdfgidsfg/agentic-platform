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
