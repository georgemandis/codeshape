load_config() {
  local self_dir; self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  # shellcheck disable=SC1091
  source "$self_dir/config.default"
  local override="${ROOT:-}/.codeshaperc"
  # Only source the override if it exists AND contains just KEY=value lines
  # (defense against executing arbitrary code from an analyzed repo).
  if [[ -f "$override" ]] && grep -qvE '^\s*(#.*)?$|^[A-Z_]+=[0-9.]+\s*$' "$override"; then
    :  # malformed line found → ignore override entirely
  elif [[ -f "$override" ]]; then
    # shellcheck disable=SC1090
    source "$override"
  fi
}
