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
