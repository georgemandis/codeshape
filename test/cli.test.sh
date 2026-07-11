#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { if eval "$2"; then echo "ok - $1"; PASS=$((PASS+1)); else echo "FAIL - $1"; FAIL=$((FAIL+1)); fi; }

# Outside a git repo, --json emits a NOT_FOUND envelope on stdout.
NON="$(mktemp -d)"
out="$(cd "$NON" && "$DIR/codeshape" --json 2>/dev/null)"
ok "outside repo → parseable JSON" 'printf "%s" "$out" | jq -e . >/dev/null 2>&1'
ok "outside repo → NOT_FOUND"      '[[ "$(printf "%s" "$out" | jq -r .code)" == "NOT_FOUND" ]]'
rm -rf "$NON"

# Bad --since → BAD_ARGS envelope.
REPO="$(mktemp -d)"
( cd "$REPO" && git init -q && git config user.email t@t.co && git config user.name t \
  && echo 'package main' > m.go && git add -A && git commit -qm init )
bad="$(cd "$REPO" && "$DIR/codeshape" --since abc --json 2>/dev/null)"
ok "bad --since → BAD_ARGS" '[[ "$(printf "%s" "$bad" | jq -r .code)" == "BAD_ARGS" ]]'

# Happy path (only if an adapter is installed): envelope has the KPI + coverage keys.
if [[ -n "$(cd "$REPO" && bash -c 'source "'"$DIR"'/lib/adapters.sh"; adapter_available')" ]]; then
  good="$(cd "$REPO" && "$DIR/codeshape" --json 2>/dev/null)"
  ok "envelope metric is codeshape"     '[[ "$(printf "%s" "$good" | jq -r .metric)" == "codeshape" ]]'
  ok "data has average_health"          'printf "%s" "$good" | jq -e ".data.average_health != null" >/dev/null'
  ok "data has coverage.total"          'printf "%s" "$good" | jq -e ".data.coverage.total >= 1" >/dev/null'
  ok "data has tiers object"            'printf "%s" "$good" | jq -e ".data.tiers | has(\"green\")" >/dev/null'
else
  echo "skip - no adapter installed; happy-path assertions skipped"
fi
rm -rf "$REPO"

echo; echo "PASS=$PASS FAIL=$FAIL"; [[ "$FAIL" -eq 0 ]]
