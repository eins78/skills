#!/usr/bin/env bash
set -euo pipefail

# Ensure Chrome is running with CDP (Chrome DevTools Protocol) on port 9222.
# Idempotent — safe to call repeatedly.
# Uses a dedicated user-data-dir so CDP can bind even if Chrome was already open.
# Prefers Chrome for Testing (distinct icon, no auto-update), falls back to regular Chrome.

PORT=9222
CDP_URL="http://127.0.0.1:${PORT}"
USER_DATA_DIR="$HOME/.cache/chrome-cdp-profile"
CFT_BIN="$HOME/.local/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# shellcheck disable=SC2054  # commas inside --disable-features=... value are intentional Chrome syntax
CHROME_FLAGS=(
  # Core CDP / Profile
  --remote-debugging-port="${PORT}"
  --user-data-dir="${USER_DATA_DIR}"

  # First-run / Default Browser
  --no-default-browser-check
  --no-first-run

  # UI Suppression
  --disable-infobars
  --disable-search-engine-choice-screen
  --disable-popup-blocking
  --disable-prompt-on-repost
  --disable-hang-monitor

  # Frame throttling — keep rendering when the display sleeps or the window is
  # occluded. macOS marks an occluded/asleep window hidden; Chrome then stops
  # firing requestAnimationFrame, and Playwright's actionability check (which
  # waits for two stable animation frames) can never pass. Measured on a VM:
  # display asleep went from 0 frames/2s to 80.
  --disable-backgrounding-occluded-windows
  --disable-renderer-backgrounding
  --disable-background-timer-throttling

  # Background Activity Reduction
  --disable-breakpad
  --disable-background-networking
  --disable-client-side-phishing-detection
  --disable-component-update
  --disable-sync
  --metrics-recording-only

  # Password / Keychain
  --password-store=basic
  --use-mock-keychain

  # Disabled Features
  --disable-features=Translate,TranslateUI,PasswordCheck,PasswordManagerOnboarding,AutofillServerCommunication,MediaRouter,DialMediaRouteProvider,OptimizationHints,GlobalMediaControls,TabOrganization,AiModeOmniboxEntryPoint,OmniboxAiModeEntryPointVariations
)

if curl -s "${CDP_URL}/json/version" >/dev/null 2>&1; then
  echo "Chrome CDP already available on :${PORT}"
  curl -s "${CDP_URL}/json/version" | python3 -m json.tool
  exit 0
fi

mkdir -p "${USER_DATA_DIR}"

if [[ -x "${CFT_BIN}" ]]; then
  echo "Launching Chrome for Testing with --remote-debugging-port=${PORT}..."
  "${CFT_BIN}" "${CHROME_FLAGS[@]}" &>/dev/null &
else
  echo "Launching Chrome with --remote-debugging-port=${PORT}..."
  "${CHROME_BIN}" "${CHROME_FLAGS[@]}" &>/dev/null &
fi
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
