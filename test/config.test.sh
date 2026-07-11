#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { if eval "$2"; then echo "ok - $1"; PASS=$((PASS+1)); else echo "FAIL - $1"; FAIL=$((FAIL+1)); fi; }

# Defaults load from config.default when no override is present.
eval "$(bash -c 'source "'"$DIR"'/lib/config.sh"; ROOT=/nonexistent load_config; \
  echo T_CCN=$T_CCN; echo T_LEN=$T_LEN; echo TIER_GREEN=$TIER_GREEN; echo CHURN_FLOOR=$CHURN_FLOOR')"
ok "default T_CCN is 10"      '[[ "$T_CCN" == "10" ]]'
ok "default T_LEN is 60"      '[[ "$T_LEN" == "60" ]]'
ok "default TIER_GREEN is 8"  '[[ "$TIER_GREEN" == "8" ]]'
ok "default CHURN_FLOOR is 3" '[[ "$CHURN_FLOOR" == "3" ]]'

# A repo-root .codeshaperc overrides a default.
OV="$(mktemp -d)"; echo 'T_CCN=25' > "$OV/.codeshaperc"
eval "$(bash -c 'source "'"$DIR"'/lib/config.sh"; ROOT="'"$OV"'" load_config; echo T_CCN=$T_CCN')"
ok ".codeshaperc overrides T_CCN" '[[ "$T_CCN" == "25" ]]'
rm -rf "$OV"

echo; echo "PASS=$PASS FAIL=$FAIL"; [[ "$FAIL" -eq 0 ]]
