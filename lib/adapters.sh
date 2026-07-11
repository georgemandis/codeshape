# Normalized record shape:
#   { path, lang, loc, fns:[{name,ccn,len,args,nesting}], dup_ratio }

adapter_available() {
  local a
  for a in scc lizard radon gocyclo; do command -v "$a" >/dev/null 2>&1 && echo "$a"; done
}

# analyze_file <abs_path> <rel_path> → one JSON record, or nonzero exit if unclaimed.
analyze_file() {
  local abs="$1" rel="$2"
  # Try lizard first when it claims the file: it yields real per-function
  # ccn/length/param, richer than scc's file-level complexity. scc is the
  # fallback for languages/files lizard doesn't support.
  if command -v lizard >/dev/null 2>&1; then
    # lizard --csv emits one row per function, no header, columns:
    #   nloc,ccn,token,param,length,location,file,function,long_name,start,end
    local csv
    csv="$(lizard --csv "$abs" 2>/dev/null)" || csv=""
    if [[ -n "$csv" ]]; then
      local rec
      rec="$(printf '%s\n' "$csv" | awk -F, 'NF>=5{print $2"\t"$5"\t"$4}' \
        | jq -R -s --arg p "$rel" '
            [ split("\n")[] | select(length>0) | split("\t")
              | { ccn:(.[0]|tonumber), len:(.[1]|tonumber), args:(.[2]|tonumber),
                  name:"fn", nesting:0 } ] as $fns
            | select(($fns|length) > 0)
            | { path:$p, lang:"lizard", loc:([$fns[].len]|add),
                fns:$fns, dup_ratio:0 }' 2>/dev/null)"
      if [[ -n "$rec" && "$rec" != "null" ]]; then printf '%s\n' "$rec"; return 0; fi
    fi
  fi
  # Try scc next (broadest language coverage). scc emits per-file JSON with
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
