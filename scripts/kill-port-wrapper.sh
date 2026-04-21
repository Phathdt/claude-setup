# kill-port wrapper function — source this in your .zshrc or .bashrc
#
#   source /path/to/kill-port-wrapper.sh
#
# Then use: kp <port> [-f|--force]

KP_SCRIPT_DIR="${KP_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)}"

kp() {
  local script="$KP_SCRIPT_DIR/kill-port.sh"

  if [[ ! -f "$script" ]]; then
    echo "Error: kill-port.sh not found at $script" >&2
    return 1
  fi

  "$script" "$@"
}
