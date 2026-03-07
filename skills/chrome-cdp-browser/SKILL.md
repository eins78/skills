---
name: chrome-cdp-browser
description: Use when setting up browser automation with Playwright MCP, when Chrome CDP is needed for persistent sessions, or when replacing unreliable browser extensions with a dedicated Chrome instance.
---

# Dedicated Chrome CDP Browser

Set up a dedicated headed Chrome instance with CDP (Chrome DevTools Protocol) for Playwright MCP browser automation. Persistent profile, launchd-managed, multi-session safe.

## Why

- Browser extensions (claude-in-chrome) are unreliable — disconnections, multi-instance confusion
- Playwright MCP needs a CDP endpoint for persistent sessions (cookies, logins survive restarts)
- Chrome's single-instance lock prevents CDP when default profile is in use — **dedicated user-data-dir required**

## Architecture

```
Chrome (dedicated CDP instance, port 9222)
  └── ~/.cache/chrome-cdp-profile (persistent, isolated from daily Chrome)
      │
      ├── Claude session 1 → Playwright MCP → CDP
      ├── Claude session 2 → Playwright MCP → CDP
      └── User can log into sites manually (headed)
```

## Setup Checklist

### 1. Create launch script

Create an idempotent script (e.g. `scripts/launch-chrome-cdp.sh`):

```bash
#!/usr/bin/env bash
set -euo pipefail

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
```

### 2. Create launchd plist

Create a plist (adapt `Label` and `user-data-dir` path for the machine):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.chrome-cdp</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/Google Chrome.app/Contents/MacOS/Google Chrome</string>
        <string>--remote-debugging-port=9222</string>
        <string>--user-data-dir=/Users/USERNAME/.cache/chrome-cdp-profile</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/chrome-cdp.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/chrome-cdp.stderr.log</string>
</dict>
</plist>
```

### 3. Install and start

```bash
# Make script executable
chmod +x scripts/launch-chrome-cdp.sh

# Symlink plist to LaunchAgents
ln -sf /path/to/com.example.chrome-cdp.plist ~/Library/LaunchAgents/

# Start Chrome now
./scripts/launch-chrome-cdp.sh

# Load launchd agent (auto-start on login)
launchctl load ~/Library/LaunchAgents/com.example.chrome-cdp.plist
```

### 4. Configure Playwright MCP

```bash
claude mcp add -s user playwright -- npx @playwright/mcp --cdp-endpoint http://127.0.0.1:9222
```

### 5. Verify

```bash
# CDP responding
curl -s http://127.0.0.1:9222/json/version | python3 -m json.tool

# After restarting Claude Code, test Playwright MCP tools
# browser_navigate, browser_snapshot, browser_tabs should all work
```

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Isolated profile | Avoids Chrome single-instance lock, doesn't interfere with daily browsing |
| Direct binary launch | `open -a` unreliably passes `--args`; binary + `disown` is reliable |
| Headed (not headless) | User can log into sites manually, cookies persist for automation |
| launchd KeepAlive on crash only | Restart on crash, but intentional quit stays quit |
| User-scope MCP (`-s user`) | Available across all projects, not just one workspace |

## Verification After Reboot

```bash
# Check launchd started Chrome
launchctl list | grep chrome-cdp

# Check CDP is responding
curl -s http://127.0.0.1:9222/json/version
```

## Disabling Old Browser Extensions

After setup, disable any replaced browser MCP extensions (e.g. claude-in-chrome plugin) in Claude Code settings to avoid conflicts.
