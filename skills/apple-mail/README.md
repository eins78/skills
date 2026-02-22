# Apple Mail Skill

Developer documentation for the Apple Mail read-only skill.

## Purpose

Project-specific skill for reading email via Mail.app AppleScript integration.

## Tier

**Project-specific** — relies on macOS Mail.app and personal account configuration.

## Architecture

Uses AppleScript via `osascript` to interact with Mail.app. This is the only reliable way to access Apple Mail programmatically on macOS without third-party dependencies.

### Why AppleScript?

| Approach | Pros | Cons |
|----------|------|------|
| **AppleScript** (chosen) | Zero dependencies, full Mail.app access | Verbose syntax, requires Mail.app running |
| **IMAP direct** | Works headless, more portable | Requires credentials, no unified inbox |
| **mailutil CLI** | Simpler syntax | Limited functionality |

## Skill Structure

```
apple-mail/
├── SKILL.md    # User-facing skill reference
└── README.md   # This file
```

## Origin

Extracted from [clawd-workspace TOOLS.md](https://github.com/eins78/clawd-workspace/blob/main/TOOLS.md#apple-mail-tachikoma-vm), adapted for direct macOS use (not VM-based).

## Dependencies

- macOS with Mail.app
- Automation permissions for the calling terminal app

## Limitations

- **Read only** — cannot send, delete, or modify emails
- **Requires Mail.app** — must be running and logged in
- **Permission dialogs** — first access may trigger macOS permission prompt
- **Performance** — searching large mailboxes can be slow

## Testing

```bash
# Verify Mail.app is accessible
osascript -e 'tell application "Mail" to get name of every account'

# Verify inbox access
osascript -e 'tell application "Mail" to count messages of inbox'
```

## Future Improvements

- Script for structured JSON output from mail queries
- Mailbox-specific search helpers
- Unread count per account
