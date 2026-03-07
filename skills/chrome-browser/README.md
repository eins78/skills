# Chrome Browser Skill

Developer documentation for the dedicated Chrome browser automation skill.

## Purpose

Reusable setup guide for a dedicated Chrome instance with CDP for Playwright MCP browser automation. Persistent sessions, launchd-managed, multi-session safe.

## Tier

**Publishable** — works on any macOS machine with Chrome installed.

## Origin

Developed for qubert-config ([sessionlog](https://github.com/eins78/qubert-config/blob/main/docs/sessionlogs/2026-02-25-browser-automation-playwright-cdp.md)), then replicated on lima (home-workspace). Both setups validated and working.

## Key Insight

Chrome enforces a single-instance lock per user-data-dir. When the user's daily Chrome is running, CDP can't bind to the default profile. The solution is a **dedicated `~/.cache/chrome-cdp-profile`** that runs a second Chrome instance in parallel.

## Skill Structure

```
chrome-browser/
├── SKILL.md                      # Lean overview, architecture, decisions
├── README.md                     # This file
├── INSTALL.md                    # Full setup checklist
├── launch-chrome-cdp.sh          # Idempotent launch script
└── com.example.chrome-cdp.plist  # Template launchd plist
```

## Validated On

| Machine | Date | Status |
|---------|------|--------|
| qubert | 2026-02-25 | Working (launchd, multi-session tested) |
| lima | 2026-03-07 | Working (launchd, Playwright MCP verified) |

## Dependencies

- macOS (launchd, Chrome binary path)
- Google Chrome installed at `/Applications/Google Chrome.app`
- `npx` available (for `@playwright/mcp`)

## Limitations

- **macOS only** — launchd plist won't work on Linux (use systemd equivalent)
- **Chrome-specific** — could be adapted for Edge (Chromium-based) but not Firefox/Safari
- **Headed** — requires a display session (not suitable for headless servers without modification)

## Future Improvements

- Linux systemd unit file variant
- `--shared-browser-context` flag evaluation for tab-level login sharing
- Automated smoke test script (navigate + snapshot)
