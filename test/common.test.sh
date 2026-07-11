#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { if eval "$2"; then echo "ok - $1"; PASS=$((PASS+1)); else echo "FAIL - $1"; FAIL=$((FAIL+1)); fi; }

# emit_json builds an envelope with metric/repo/window_days/generated_at/data and NO team field.
out="$(bash -c 'source "'"$DIR"'/lib/_common.sh"; REPO=acme/widget; emit_json codeshape 90 "{\"x\":1}"')"
ok "emit_json is valid JSON"            'printf "%s" "$out" | jq -e . >/dev/null 2>&1'
ok "emit_json metric is codeshape"      '[[ "$(printf "%s" "$out" | jq -r .metric)" == "codeshape" ]]'
ok "emit_json carries data through"     '[[ "$(printf "%s" "$out" | jq -r .data.x)" == "1" ]]'
ok "emit_json window_days is numeric"   '[[ "$(printf "%s" "$out" | jq -r .window_days)" == "90" ]]'
ok "emit_json has NO team field"        '[[ "$(printf "%s" "$out" | jq -r "has(\"team\")")" == "false" ]]'

# json_error prints {error,code} and exits non-zero.
err="$(bash -c 'source "'"$DIR"'/lib/_common.sh"; json_error BAD_ARGS "bad"' 2>/dev/null)"
ok "json_error code is BAD_ARGS"        '[[ "$(printf "%s" "$err" | jq -r .code)" == "BAD_ARGS" ]]'
ok "json_error exits non-zero"          '! bash -c '"'"'source "'"$DIR"'/lib/_common.sh"; json_error X y'"'"' >/dev/null 2>&1'

echo; echo "PASS=$PASS FAIL=$FAIL"; [[ "$FAIL" -eq 0 ]]
