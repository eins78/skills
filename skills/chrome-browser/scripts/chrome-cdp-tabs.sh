#!/usr/bin/env bash
set -euo pipefail

# List open tabs in the CDP-attached Chrome — read-only.
#
# Sanctioned alternative to ad-hoc `curl :9222/json` calls when Playwright MCP
# is unavailable or you want a quick out-of-band peek at browser state. Output
# is JSON (pretty-printed if jq or python3 is present).
#
# Filtered to actual page targets (CDP /json also returns service workers and
# background pages — those are hidden by default). Pass --all to see everything.
#
# This script NEVER closes, navigates, or otherwise mutates browser state — for
# tab manipulation use Playwright MCP `browser_tabs`.
#
# Exit codes:
#   0 — tabs listed
#   1 — CDP unreachable

PORT=9222
URL="http://127.0.0.1:${PORT}/json"

SHOW_ALL=false
case "${1:-}" in
  --all) SHOW_ALL=true ;;
  -h|--help)
    sed -n '/^# List/,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^#$//;s/^# //;/^$/d'
    exit 0
    ;;
  "") ;;
  *)
    echo "Unknown flag: $1" >&2
    echo "Usage: chrome-cdp-tabs [--all]" >&2
    exit 2
    ;;
esac

response="$(curl -fsS --max-time 2 "${URL}" 2>/dev/null)" || {
  echo "CDP unreachable on 127.0.0.1:${PORT} — run launch-chrome-cdp" >&2
  exit 1
}

if command -v jq >/dev/null 2>&1; then
  if [[ "${SHOW_ALL}" == true ]]; then
    printf '%s' "${response}" | jq '[.[] | {id, type, title, url}]'
  else
    printf '%s' "${response}" | jq '[.[] | select(.type == "page") | {id, type, title, url}]'
  fi
else
  # A version-manager python3 shim can exist on PATH yet exit non-zero, so try it
  # and fall back to raw output rather than testing with `command -v`.
  printf '%s' "${response}" | python3 -m json.tool 2>/dev/null || printf '%s\n' "${response}"
fi
