# Chrome Browser Setup

Full setup checklist for the dedicated Chrome CDP browser.

## Prerequisites

- macOS with Google Chrome at `/Applications/Google Chrome.app`
- `npx` available (for `@playwright/mcp`)

## 1. Install the launch script

Copy `launch-chrome-cdp.sh` from this skill directory to your project's `scripts/` or `~/.local/bin/`:

```bash
chmod +x launch-chrome-cdp.sh
```

The script is idempotent — safe to call repeatedly. It checks if CDP is already running before launching.

## 2. Create a launchd plist

Use `com.example.chrome-cdp.plist` as a template. Customize:

- **Label** — change `com.example.chrome-cdp` to something unique (e.g. `com.yourname.chrome-cdp`)
- **user-data-dir** — replace `/Users/USERNAME/` with your actual home directory

Install:

```bash
# Copy customized plist to LaunchAgents
cp com.yourname.chrome-cdp.plist ~/Library/LaunchAgents/

# Load the agent (auto-starts on login from now on)
launchctl load ~/Library/LaunchAgents/com.yourname.chrome-cdp.plist
```

## 3. Start Chrome now

```bash
./launch-chrome-cdp.sh
```

## 4. Configure Playwright MCP

```bash
claude mcp add -s user playwright -- npx @playwright/mcp --cdp-endpoint http://127.0.0.1:9222
```

Restart Claude Code to pick up the new MCP server.

## 5. Verify

```bash
# CDP responding
curl -s http://127.0.0.1:9222/json/version | python3 -m json.tool

# launchd agent loaded
launchctl list | grep chrome-cdp

# After restarting Claude Code, test Playwright MCP tools:
# browser_navigate, browser_snapshot, browser_tabs should all work
```

## Post-setup

- **Disable old browser extensions** (e.g. claude-in-chrome) in Claude Code settings to avoid conflicts
- **Log into sites** in the dedicated Chrome window — cookies persist across restarts
- **Verify after reboot** — `launchctl list | grep chrome-cdp` and `curl -s http://127.0.0.1:9222/json/version`
