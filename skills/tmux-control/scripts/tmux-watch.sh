#!/usr/bin/env bash
# tmux-watch.sh — Monitor a tmux pane until a pattern appears in its output.
#
# Usage: tmux-watch.sh -t PANE_ID [-T TIMEOUT] [-i INTERVAL] PATTERN
#
# Output: stdout = matching line(s); stderr = status messages
# Exit:   0 = pattern found; 1 = timeout; 2 = bad args/pane

set -euo pipefail

PANE=""
TIMEOUT=300
INTERVAL=2
QUIET=false

usage() {
  echo "Usage: tmux-watch.sh -t PANE_ID [-T TIMEOUT] [-i INTERVAL] [-q] PATTERN" >&2
  echo "" >&2
  echo "  -t PANE_ID   Target pane (required, %N format)" >&2
  echo "  -T TIMEOUT   Seconds before giving up (default: 300)" >&2
  echo "  -i INTERVAL  Poll interval in seconds (default: 2)" >&2
  echo "  -q           Quiet mode (suppress status on stderr)" >&2
  echo "  PATTERN      Extended regex to match (grep -E)" >&2
  exit 2
}

log() {
  $QUIET || echo "$*" >&2
}

while getopts "t:T:i:qh" opt; do
  case $opt in
    t) PANE="$OPTARG" ;;
    T) TIMEOUT="$OPTARG" ;;
    i) INTERVAL="$OPTARG" ;;
    q) QUIET=true ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

PATTERN="${1:-}"
[[ -z "$PANE" ]] && { echo "Error: -t PANE_ID is required" >&2; usage; }
[[ -z "$PATTERN" ]] && { echo "Error: PATTERN is required" >&2; usage; }
[[ "$PANE" =~ ^% ]] || { echo "Error: PANE_ID must start with % (got: $PANE)" >&2; exit 2; }

# Verify pane exists
if ! tmux list-panes -a -F '#{pane_id}' | grep -qx "$PANE"; then
  echo "Error: pane $PANE does not exist" >&2
  exit 2
fi

log "Watching $PANE for /$PATTERN/ (timeout: ${TIMEOUT}s, interval: ${INTERVAL}s)..."

DEADLINE=$((SECONDS + TIMEOUT))

while (( SECONDS < DEADLINE )); do
  # Capture recent output (last 50 lines)
  CONTENT=$(tmux capture-pane -t "$PANE" -p -S -50 2>/dev/null) || {
    echo "Error: pane $PANE no longer exists" >&2
    exit 2
  }

  # Check for pattern match
  MATCH=$(echo "$CONTENT" | grep -E "$PATTERN" 2>/dev/null) || true
  if [[ -n "$MATCH" ]]; then
    log "Pattern matched!"
    echo "$MATCH"
    exit 0
  fi

  sleep "$INTERVAL"
done

echo "Error: timed out after ${TIMEOUT}s waiting for /$PATTERN/" >&2
exit 1
