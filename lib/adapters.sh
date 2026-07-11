# Normalized record shape:
#   { path, lang, loc, fns:[{name,ccn,len,args,nesting}], dup_ratio }

adapter_available() {
  local a
  for a in scc lizard radon gocyclo; do command -v "$a" >/dev/null 2>&1 && echo "$a"; done
}

# analyze_file <abs_path> <rel_path> → one JSON record, or nonzero exit if unclaimed.
analyze_file() {
  local abs="$1" rel="$2"
  # Try scc first (broadest language coverage). scc emits per-file JSON with
  # Language, Lines, Complexity when given a single file via --by-file --format json.
  if command -v scc >/dev/null 2>&1; then
    local out
    out="$(scc --by-file --format json "$abs" 2>/dev/null)" || out=""
    # scc groups by language; find the single file entry.
    local rec
    rec="$(printf '%s' "$out" | jq -c --arg p "$rel" '
      [ .[] as $lang | $lang.Files[] | {lang:$lang.Name, loc:.Lines, ccn:.Complexity} ]
      | .[0] // empty
      | select(. != null)
      | { path:$p, lang:.lang, loc:.loc,
          fns:[ {name:"<file>", ccn:.ccn, len:.loc, args:0, nesting:0} ],
          dup_ratio:0 }' 2>/dev/null)"
    if [[ -n "$rec" && "$rec" != "null" ]]; then printf '%s\n' "$rec"; return 0; fi
  fi
  return 1  # no adapter claimed this file
}
