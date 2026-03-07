#!/usr/bin/env bash
# tmux-run.sh — Send a command to a tmux pane, wait for completion, return output.
#
# Usage: tmux-run.sh -t PANE_ID [-T TIMEOUT] [-q] COMMAND...
#
# Output: stdout = command output only; stderr = status messages
# Exit:   mirrors remote command's exit code; 128 = timeout; 2 = bad args/pane

set -euo pipefail

PANE=""
TIMEOUT=120
QUIET=false

usage() {
  echo "Usage: tmux-run.sh -t PANE_ID [-T TIMEOUT] [-q] COMMAND..." >&2
  exit 2
}

log() {
  $QUIET || echo "$*" >&2
}

while getopts "t:T:qh" opt; do
  case $opt in
    t) PANE="$OPTARG" ;;
    T) TIMEOUT="$OPTARG" ;;
    q) QUIET=true ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

COMMAND="$*"
[[ -z "$PANE" ]] && { echo "Error: -t PANE_ID is required" >&2; usage; }
[[ -z "$COMMAND" ]] && { echo "Error: COMMAND is required" >&2; usage; }
[[ "$PANE" =~ ^% ]] || { echo "Error: PANE_ID must start with % (got: $PANE)" >&2; exit 2; }

# Verify pane exists
if ! tmux list-panes -a -F '#{pane_id}' | grep -qx "$PANE"; then
  echo "Error: pane $PANE does not exist" >&2
  exit 2
fi

# Generate unique identifiers
MARKER="__TMUX_RUN_${$}_${RANDOM}__"
CHANNEL="tmux-run-${$}-${RANDOM}"
EXIT_FILE="/tmp/tmux-run-exit-${$}-${RANDOM}"
TIMEOUT_PID=""

# shellcheck disable=SC2329
cleanup() {
  rm -f "$EXIT_FILE"
  if [[ -n "$TIMEOUT_PID" ]]; then
    kill "$TIMEOUT_PID" 2>/dev/null || true
    wait "$TIMEOUT_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Start timeout watchdog — signals the channel if we exceed TIMEOUT
(
  sleep "$TIMEOUT"
  echo "TIMEOUT" > "$EXIT_FILE"
  tmux wait-for -S "$CHANNEL" 2>/dev/null
) &
TIMEOUT_PID=$!

# Construct the remote command:
#   1. Run user's command, capture exit code
#   2. Print end marker
#   3. Write exit code to temp file
#   4. Signal the wait-for channel
REMOTE_CMD="${COMMAND}; __ec=\$?; echo '${MARKER}'; echo \$__ec > '${EXIT_FILE}'; tmux wait-for -S '${CHANNEL}'"

log "Sending to $PANE (timeout: ${TIMEOUT}s)..."
tmux send-keys -t "$PANE" "$REMOTE_CMD" Enter

# Block until command completes (or timeout fires)
tmux wait-for "$CHANNEL"

# Kill the timeout watchdog (no longer needed)
kill "$TIMEOUT_PID" 2>/dev/null || true
wait "$TIMEOUT_PID" 2>/dev/null || true
TIMEOUT_PID=""

# Check for timeout
if [[ -f "$EXIT_FILE" ]] && grep -q "TIMEOUT" "$EXIT_FILE" 2>/dev/null; then
  echo "Error: command timed out after ${TIMEOUT}s" >&2
  exit 128
fi

# Capture pane output (full scrollback, joined wrapped lines)
OUTPUT=$(tmux capture-pane -t "$PANE" -p -S - -J)

# Extract output between the marker and the line before it that contains our channel
# Strategy: find the marker line, take everything between the command echo and it
# The command echo contains CHANNEL, and the end is MARKER
# sed: extract between command echo (contains CHANNEL) and marker, then strip both boundary lines
# Using sed instead of head -n -1 for macOS compatibility
RESULT=$(echo "$OUTPUT" | sed -n "/wait-for -S '${CHANNEL}'/,/${MARKER}/p" | tail -n +2 | sed '$ d')

if [[ -n "$RESULT" ]]; then
  echo "$RESULT"
fi

# Read and forward the remote exit code
if [[ -f "$EXIT_FILE" ]]; then
  REMOTE_EXIT=$(cat "$EXIT_FILE")
  if [[ "$REMOTE_EXIT" =~ ^[0-9]+$ ]]; then
    log "Remote exit code: $REMOTE_EXIT"
    exit "$REMOTE_EXIT"
  fi
fi

log "Warning: could not determine remote exit code"
exit 0
