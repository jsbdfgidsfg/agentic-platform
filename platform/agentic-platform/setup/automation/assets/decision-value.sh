#!/usr/bin/env bash
# decision-value.sh ID VARIABLE prints VARIABLE from the Values table of the signed record of ID.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
"$here/tools/decision-need.sh" "$1" >/dev/null
rec=$(awk -F'|' -v id="$1" '{k=$2; gsub(/ /,"",k); if (k==id) {r=$4; gsub(/ /,"",r); print r}}' "$here/decisions/TRACKER.md" | head -n 1)
v=$(awk -F'|' -v n="$2" '/^## Values$/{s=1;next} /^## /{s=0} s {k=$2; gsub(/[ `]/,"",k); if (k==n) {x=$3; gsub(/^ +| +$/,"",x); gsub(/`/,"",x); print x}}' "$here/decisions/$rec" | head -n 1)
[ -n "$v" ] || { echo "no value for $2 in $rec" >&2; exit 1; }
printf '%s\n' "$v"
