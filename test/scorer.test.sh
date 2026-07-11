#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { if eval "$2"; then echo "ok - $1"; PASS=$((PASS+1)); else echo "FAIL - $1"; FAIL=$((FAIL+1)); fi; }
sc() { bash -c 'source "'"$DIR"'/config.default"; source "'"$DIR"'/lib/scorer.sh"; score_record "$@"' _ "$@"; }

# Clean file (all under threshold, no dup) → perfect 10.0
ok "clean file scores 10.0"        '[[ "$(sc 5 30 2 1 0)" == "10.0" ]]'
# ccn 20 → over=10, penalty 0.30*10=3.0 → 7.0
ok "high ccn deducts correctly"    '[[ "$(sc 20 30 2 1 0)" == "7.0" ]]'
# nesting 6 → over=3, penalty 1.00*3=3.0 → 7.0
ok "deep nesting deducts"          '[[ "$(sc 5 30 2 6 0)" == "7.0" ]]'
# Everything terrible → clamps at floor 1.0, never below
ok "catastrophic file clamps to 1.0" '[[ "$(sc 200 2000 20 40 1)" == "1.0" ]]'
# dup_ratio 0.4 → penalty 5.0*0.4=2.0 → 8.0
ok "duplication deducts"           '[[ "$(sc 5 30 2 1 0.4)" == "8.0" ]]'

echo; echo "PASS=$PASS FAIL=$FAIL"; [[ "$FAIL" -eq 0 ]]
