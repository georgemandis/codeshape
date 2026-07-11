#!/usr/bin/env bash
# Shared helpers for codeshape scripts (envelope + local-repo resolution).

emit_json() {
  local metric="$1" window="$2" data="$3"
  local generated
  generated=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq -n \
    --arg metric "$metric" \
    --arg repo "${REPO:-}" \
    --arg generated "$generated" \
    --argjson window "$window" \
    --argjson data "$data" \
    '{ metric: $metric, repo: $repo, window_days: $window,
       generated_at: $generated, data: $data }'
}

json_error() {
  local code="$1" message="$2"
  jq -n --arg code "$code" --arg message "$message" '{ error: $message, code: $code }'
  exit 1
}

json_preflight_local() {
  command -v jq  >/dev/null 2>&1 || json_error DEP_MISSING "jq is not installed"
  command -v git >/dev/null 2>&1 || json_error DEP_MISSING "git is not installed"
}

require_git_repo() {
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null) && return 0
  [[ "${JSON:-false}" == "true" ]] && \
    json_error NOT_FOUND "not inside a git repository (codeshape analyzes the local working tree)"
  echo "Error: not inside a git repository" >&2
  return 1
}

resolve_local_repo() {
  local url
  url=$(git remote get-url origin 2>/dev/null || true); url="${url%.git}"
  if [[ "$url" =~ github\.com[:/]([A-Za-z0-9._-]+/[A-Za-z0-9._-]+)$ ]]; then
    REPO="${BASH_REMATCH[1]}"
  elif [[ -n "${ROOT:-}" ]]; then REPO="$(basename "$ROOT")"; else REPO=""; fi
}
