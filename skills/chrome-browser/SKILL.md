---
name: chrome-browser
description: Use when setting up a dedicated Chrome browser for Playwright MCP with session persistence, or when encountering Cloudflare challenges during browser automation. Covers CDP setup, launchd auto-start, and persistent login sessions.
---

# Dedicated Chrome Browser

A dedicated headed Chrome instance with CDP for Playwright MCP. Persistent profile (cookies/logins survive restarts), launchd-managed, multi-session safe.

## Why

- Chrome's single-instance lock prevents CDP when the default profile is in use — **dedicated user-data-dir required**
- Headed so the user can log into sites manually; Playwright shares the session
- launchd auto-starts on login, restarts on crash

## Architecture

```
Chrome (dedicated CDP instance, port 9222)
  └── ~/.cache/chrome-cdp-profile (persistent, isolated from daily Chrome)
      ├── Claude session 1 → Playwright MCP → CDP
      ├── Claude session 2 → Playwright MCP → CDP
      └── User can log into sites manually (headed)
```

## Quick Reference

```bash
# Check CDP
curl -s http://127.0.0.1:9222/json/version

# Configure Playwright MCP (user-scope, one-time)
claude mcp add -s user playwright -- npx @playwright/mcp --cdp-endpoint http://127.0.0.1:9222

# Manual launch (if not using launchd)
./launch-chrome-cdp.sh
```

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Isolated profile (`~/.cache/chrome-cdp-profile`) | Avoids single-instance lock, doesn't interfere with daily browsing |
| Direct binary launch | `open -a` unreliably passes `--args`; binary + `disown` is reliable |
| Headed (not headless) | User can log into sites manually, cookies persist for automation |
| launchd KeepAlive on crash only | Restart on crash, but intentional quit stays quit |
| User-scope MCP (`-s user`) | Available across all projects |

## Troubleshooting

- **Cloudflare challenges:** If a site shows a Cloudflare challenge/waiting page, just wait — the browser MCP can usually handle it. We are very rarely actually blocked.
- **CDP not responding:** Run `launch-chrome-cdp.sh` to start or check status.
- **Profile conflicts:** If Chrome complains about profile lock, check for zombie Chrome processes: `ps aux | grep chrome-cdp-profile`

## Setup

See [INSTALL.md](INSTALL.md) for the full setup checklist, including the launch script and launchd plist.
