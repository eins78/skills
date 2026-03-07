#!/usr/bin/env bash
set -euo pipefail

# Ensure Chrome is running with CDP (Chrome DevTools Protocol) on port 9222.
# Idempotent — safe to call repeatedly.
# Uses a dedicated user-data-dir so CDP can bind even if Chrome was already open.

PORT=9222
CDP_URL="http://127.0.0.1:${PORT}"
USER_DATA_DIR="$HOME/.cache/chrome-cdp-profile"

if curl -s "${CDP_URL}/json/version" >/dev/null 2>&1; then
  echo "Chrome CDP already available on :${PORT}"
  curl -s "${CDP_URL}/json/version" | python3 -m json.tool
  exit 0
fi

echo "Launching Chrome with --remote-debugging-port=${PORT}..."
mkdir -p "${USER_DATA_DIR}"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port="${PORT}" \
  --user-data-dir="${USER_DATA_DIR}" \
  &>/dev/null &
disown

# Wait for CDP to become available
for _ in {1..30}; do
  if curl -s "${CDP_URL}/json/version" >/dev/null 2>&1; then
    echo "Chrome CDP ready on :${PORT}"
    curl -s "${CDP_URL}/json/version" | python3 -m json.tool
    exit 0
  fi
  sleep 0.5
done

echo "Error: Chrome started but CDP not responding on :${PORT}" >&2
exit 1
