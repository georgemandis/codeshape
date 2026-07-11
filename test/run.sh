#!/usr/bin/env bash
# codeshape/test/run.sh — run every codeshape/test/*.test.sh suite.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
fail=0
for t in "$DIR"/*.test.sh; do
  echo "== $t =="
  bash "$t" || fail=1
done
exit "$fail"
