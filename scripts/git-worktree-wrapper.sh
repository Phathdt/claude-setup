# git-worktree wrapper function — source this in your .zshrc or .bashrc
#
#   source /path/to/git-worktree-wrapper.sh
#
# Then use: gw add|cd|root|remove|ls [args]

GW_SCRIPT_DIR="${GW_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)}"

gw() {
  local script="$GW_SCRIPT_DIR/git-worktree.sh"

  if [[ ! -f "$script" ]]; then
    echo "Error: git-worktree.sh not found at $script" >&2
    return 1
  fi

  local cmd="${1:-}"

  case "$cmd" in
    add|cd|root|remove)
      local output
      output=$("$script" "$@") || return $?
      # script outputs path as the last line of stdout
      local target
      target=$(echo "$output" | tail -1)
      if [[ -n "$target" && -d "$target" ]]; then
        cd "$target" || return $?
        echo "Now in: $(pwd)"
      fi
      ;;
    ls|list)
      "$script" "$@"
      ;;
    *)
      "$script" "$@"
      ;;
  esac
}
