GG_DIR="$BUILD_LOG_DIR/ge-gateway"
GG_DATE="$(date -u +%F)"
GG_HOST="https://eu-discoveryengine.googleapis.com"
GG_ENGINES="${GG_HOST}/v1/projects/${GEMINI_PROJECT_NUMBER}/locations/eu/collections/default_collection/engines"
gg_file() { local d="$GG_DIR" n=1; [ "${4-}" = restricted ] && d="$GG_DIR/restricted"; while [ -e "$d/${GG_DATE}-$1-$2-v${n}.$3" ]; do n=$((n+1)); done; printf '%s\n' "$d/${GG_DATE}-$1-$2-v${n}.$3"; }
gg_answer() { case "$3" in PASS|FAIL|RECORDED) : ;; *) echo "STOP: gg_answer result must be PASS, FAIL or RECORDED"; return 1;; esac
  printf '| %s | %s | %s | %s |\n' "$1" "$2" "$3" "$(date -u +%FT%TZ)" >> "$GG_SPIKE"
  R="${GG_SPIKE}.results"; touch "$R"; grep -v "^RESULT $1 " "$R" > "$R.tmp" 2>/dev/null || :; printf 'RESULT %s %s\n' "$1" "$3" >> "$R.tmp"; mv "$R.tmp" "$R"
  git -C "$BUILD_LOG_DIR" add "$GG_SPIKE" "$R" && git -C "$BUILD_LOG_DIR" commit -q -m "spike $1 $3"; }
gg_result() { grep -qx "RESULT $1 PASS" "${GE_SPIKE_RECORD:-$GG_SPIKE}.results"; }
gg_engine_view() { ge_call GET "${GG_ENGINES}/$1" | jq '{name, displayName, agentGatewaySetting, associatedAgentRegistry}'; }
