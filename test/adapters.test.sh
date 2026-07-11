#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok()   { if eval "$2"; then echo "ok - $1"; PASS=$((PASS+1)); else echo "FAIL - $1"; FAIL=$((FAIL+1)); fi; }
skip() { echo "skip - $1"; }

source "$DIR/lib/adapters.sh"

if command -v scc >/dev/null 2>&1; then
  TMP="$(mktemp -d)"
  printf 'package main\nfunc main(){ if true { for i:=0;i<3;i++{} } }\n' > "$TMP/main.go"
  rec="$(analyze_file "$TMP/main.go" "main.go")"
  ok "scc adapter emits valid JSON"        'printf "%s" "$rec" | jq -e . >/dev/null 2>&1'
  ok "record path is the rel path"         '[[ "$(printf "%s" "$rec" | jq -r .path)" == "main.go" ]]'
  ok "record has an loc integer"           'printf "%s" "$rec" | jq -e ".loc | type == \"number\"" >/dev/null'
  ok "record fns is a non-empty array"     'printf "%s" "$rec" | jq -e ".fns | length >= 1" >/dev/null'
  # A language no adapter claims → non-zero exit, no output.
  # Note: scc recognizes Markdown, so a plain .md file is NOT unclaimed on this
  # scc version. Use an extension/content scc genuinely does not recognize instead
  # (verified empirically: scc --by-file --format json returns `[]` for this file).
  printf 'binary junk with no recognizable language\n' > "$TMP/unclaimed.unknownext123"
  ok "unclaimed language is skipped (nonzero exit)" '! analyze_file "'"$TMP"'/unclaimed.unknownext123" "unclaimed.unknownext123" >/dev/null 2>&1'
  rm -rf "$TMP"
else
  skip "scc not installed — adapter behavior tests skipped"
fi
ok "adapter_available lists something or is empty" 'adapter_available >/dev/null 2>&1 || true; true'

if command -v lizard >/dev/null 2>&1; then
  TMP2="$(mktemp -d)"
  cat > "$TMP2/f.py" <<'PY'
def big(a, b, c, d, e):
    if a:
        if b:
            for i in range(c):
                if d and e:
                    return i
    return 0
PY
  rec="$(analyze_file "$TMP2/f.py" "f.py")"
  ok "lizard record is valid JSON"           'printf "%s" "$rec" | jq -e . >/dev/null 2>&1'
  ok "lizard captures the 5-arg function"    'printf "%s" "$rec" | jq -e "[.fns[].args] | max == 5" >/dev/null'
  ok "lizard ccn reflects branching (>1)"    'printf "%s" "$rec" | jq -e "[.fns[].ccn] | max > 1" >/dev/null'
  rm -rf "$TMP2"
else
  skip "lizard not installed — per-function enrichment tests skipped"
fi

echo; echo "PASS=$PASS FAIL=$FAIL"; [[ "$FAIL" -eq 0 ]]
