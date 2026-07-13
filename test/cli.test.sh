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

# Envelope self-reconciliation: coverage/tiers/files must agree even when the
# tree contains a zero-LoC file (regression for the extension-leak + zero-LoC
# scored-file bugs).
if [[ -n "$(bash -c 'source "'"$DIR"'/lib/adapters.sh"; adapter_available')" ]]; then
  RECON="$(mktemp -d)"
  ( cd "$RECON" && git init -q && git config user.email t@t.co && git config user.name t \
    && printf 'def add(a, b):\n    return a + b\n\ndef sub(a, b):\n    return a - b\n' > main.py \
    && touch empty.py \
    && git add -A && git commit -qm init )
  recon="$(cd "$RECON" && "$DIR/codeshape" --json 2>/dev/null)"
  ok "reconcile: coverage.scored+skipped == total" \
    '[[ "$(printf "%s" "$recon" | jq -r "(.data.coverage.scored + .data.coverage.skipped) == .data.coverage.total")" == "true" ]]'
  ok "reconcile: tiers sum == coverage.scored" \
    '[[ "$(printf "%s" "$recon" | jq -r "(.data.tiers.green + .data.tiers.yellow + .data.tiers.red) == .data.coverage.scored")" == "true" ]]'
  ok "reconcile: files length == coverage.scored" \
    '[[ "$(printf "%s" "$recon" | jq -r "(.data.files | length) == .data.coverage.scored")" == "true" ]]'
  ok "reconcile: no skipped_languages entry contains a slash" \
    '[[ "$(printf "%s" "$recon" | jq -r "[.data.coverage.skipped_languages[] | select(contains(\"/\"))] | length == 0")" == "true" ]]'
  rm -rf "$RECON"
else
  echo "skip - no adapter installed; reconciliation assertions skipped"
fi

echo; echo "PASS=$PASS FAIL=$FAIL"; [[ "$FAIL" -eq 0 ]]
