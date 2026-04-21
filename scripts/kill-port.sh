#!/usr/bin/env bash
# Find process listening on a given port and kill it with confirmation.
# Usage: kill-port.sh <port> [-f|--force]

set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") <port> [-f|--force]" >&2
  echo "  <port>        TCP port number (1-65535)" >&2
  echo "  -f, --force   Skip confirmation prompt" >&2
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

PORT=""
FORCE=0

for arg in "$@"; do
  case "$arg" in
    -f|--force) FORCE=1 ;;
    -h|--help) usage ;;
    ''|*[!0-9]*)
      echo "Error: invalid argument '$arg'" >&2
      usage
      ;;
    *)
      if [[ -z "$PORT" ]]; then
        PORT="$arg"
      else
        echo "Error: unexpected argument '$arg'" >&2
        usage
      fi
      ;;
  esac
done

if [[ -z "$PORT" ]]; then
  usage
fi

if (( PORT < 1 || PORT > 65535 )); then
  echo "Error: port must be between 1 and 65535" >&2
  exit 1
fi

if ! command -v lsof >/dev/null 2>&1; then
  echo "Error: 'lsof' is required but not installed" >&2
  exit 1
fi

PIDS=$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null || true)

if [[ -z "$PIDS" ]]; then
  echo "No process is listening on port $PORT."
  exit 0
fi

echo "Processes listening on port $PORT:"
lsof -nP -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true
echo

if (( FORCE == 0 )); then
  read -r -p "Kill these process(es)? [y/N] " REPLY </dev/tty
  case "$REPLY" in
    y|Y|yes|YES) ;;
    *)
      echo "Aborted."
      exit 0
      ;;
  esac
fi

EXIT_CODE=0
for PID in $PIDS; do
  if kill -15 "$PID" 2>/dev/null; then
    echo "Sent SIGTERM to $PID"
  else
    echo "Failed to SIGTERM $PID" >&2
    EXIT_CODE=1
    continue
  fi

  for _ in 1 2 3 4 5; do
    if ! kill -0 "$PID" 2>/dev/null; then
      break
    fi
    sleep 0.2
  done

  if kill -0 "$PID" 2>/dev/null; then
    echo "PID $PID still alive, sending SIGKILL"
    if ! kill -9 "$PID" 2>/dev/null; then
      echo "Failed to SIGKILL $PID" >&2
      EXIT_CODE=1
    fi
  fi
done

exit "$EXIT_CODE"
