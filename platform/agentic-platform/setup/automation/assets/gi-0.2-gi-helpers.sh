GI_DATE="$(date -u +%F)"
gi_path() { local dir="$1" step="$2" rec="$3" ext="$4" n=1; while [ -e "$dir/${GI_DATE}-${step}-${rec}-v${n}.${ext}" ]; do n=$((n+1)); done; printf '%s\n' "$dir/${GI_DATE}-${step}-${rec}-v${n}.${ext}"; }
gi_file() { gi_path "$GE_INVENTORY_DIR" "$@"; }
gi_rfile() { gi_path "$GE_INVENTORY_DIR/restricted" "$@"; }
ge_host() { case "$1" in eu) echo https://eu-discoveryengine.googleapis.com;; us) echo https://us-discoveryengine.googleapis.com;; global) echo https://global-discoveryengine.googleapis.com;; esac; }
ge_get() { curl -sS --fail-with-body -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "X-Goog-User-Project: ${GEMINI_PROJECT}" "$1"; }
# ge_list URL KEY SIZE: every page of a paged list as one object {KEY: [...], pagesRead: n}. Returns 0 when complete;
# 4 when a later page failed (the object then carries "truncated": true and the nextPageToken); 1 when the first
# page failed, with Google's error body printed instead.
ge_list() {
  _lt=""; _ln=0; _lf="$(mktemp)"; _ls='?'; case "$1" in *'?'*) _ls='&';; esac
  while :; do
    _lq="pageSize=$3"; [ -n "$_lt" ] && _lq="$_lq&pageToken=$(jq -rn --arg t "$_lt" '$t|@uri')"
    if ! _lr="$(ge_get "$1$_ls$_lq")"; then
      [ "$_ln" -eq 0 ] && { printf '%s\n' "$_lr"; rm -f "$_lf"; return 1; }
      break
    fi
    _ln=$((_ln+1)); printf '%s' "$_lr" | jq -c --arg k "$2" '.[$k][]?' >> "$_lf"
    _lt="$(printf '%s' "$_lr" | jq -r '.nextPageToken // empty')"; [ -z "$_lt" ] && break
  done
  jq -s --arg k "$2" --argjson n "$_ln" --arg t "$_lt" '{($k): ., pagesRead: $n} + (if $t == "" then {} else {truncated: true, nextPageToken: $t} end)' "$_lf"
  rm -f "$_lf"; [ -z "$_lt" ] || return 4
}
# gi_done STEP [NOTE]: a checkpoints.tsv line through 01's checkpoint; STOP: notes are BLOCKED, PENDING: notes are PENDING.
gi_done() { case "${2:-done}" in STOP:*) checkpoint "$1" BLOCKED - - "$2";; PENDING:*) checkpoint "$1" PENDING - - "$2";; *) checkpoint "$1" DONE - - "${2:-done}";; esac; }
# gi_evidence STEP FILE E_ID "TISAX <id>": one EVIDENCE_REGISTER row through 01's evidence_add (01 PR-4.2 columns).
gi_evidence() {
  _gt="${4#TISAX }"
  if [ -f "$2" ]; then
    _gb="$(basename "$2")"; _gs="${_gb#"${GI_DATE}-${1}-"}"; _gs="${_gs%.*}"; _gs="${_gs%-v[0-9]*}"
    _gs="$(printf '%s' "$_gs" | tr 'A-Z_.' 'a-z--' | tr -cd 'a-z0-9-')"
    evidence_add "$1" "${_gs:-ge-inventory}" "$3" "$_gt" "build-log:ge-inventory/$_gb" "$2"
  else
    evidence_add "$1" ge-inventory-restricted "$3" "$_gt" "interim:$2"
  fi
}
