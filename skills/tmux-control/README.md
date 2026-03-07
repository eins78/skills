# tmux Control Skill

Developer documentation for the tmux control patterns skill.

## Purpose

Encodes reliable patterns for programmatic tmux interaction — targeting panes, sending commands, reading output, and synchronizing. Prevents the most common bugs (wrong targets, race conditions, empty captures).

## Tier

**Publishable** — works on any system with tmux 3.x+. macOS-specific section covers FDA and PATH quirks.

## Origin

Extracted from:
- `docs/remote-tmux-execution.md` in home-workspace (original targeting docs)
- Session logs documenting tmux failures and workarounds (2026-01 through 2026-03)
- Web research on tmux scripting best practices, wait-for, pipe-pane, and control mode
- Claude Code GitHub issues (#23513 send-keys race, #23615 agent teams)

## Key Insights

1. **Pane IDs (`%N`) are the only reliable targeting method** — indexes shift when windows are reordered/closed
2. **`wait-for` replaces `sleep`** — channel-based sync is deterministic, sleep is a guess
3. **Pass commands to `new-window`/`split-window` directly** — avoids the shell-init race condition that plagues send-keys
4. **FDA is session-scoped on macOS** — SSH sessions can't access protected paths even via tmux, unless the tmux server was started from a GUI terminal

## Skill Structure

```
tmux-control/
├── SKILL.md      # Patterns and recipes for Claude
└── README.md     # This file
```

## Testing

Manual verification — run the key patterns in a live tmux session:

```bash
# 1. Verify targeting
tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index}'

# 2. Create pane and capture ID
PANE=$(tmux split-window -P -F '#{pane_id}')

# 3. Send command with wait-for
CHAN="test-$$"
tmux send-keys -t "$PANE" "echo 'skill works'; tmux wait-for -S $CHAN" Enter
tmux wait-for "$CHAN"

# 4. Capture output
tmux capture-pane -t "$PANE" -p -S -5

# 5. Clean up
tmux kill-pane -t "$PANE"
```

## Dependencies

- tmux 3.x+ (for `wait-for`, `pipe-pane -o`, format strings)
- Bash (recipes use bash syntax)

## Limitations

- **No control mode coverage** — `tmux -CC` provides async notifications and structured output but is complex to document as a skill pattern; may add in future
- **No tmux MCP server integration** — several exist (jonrad/tmux-mcp, bnomei/tmux-mcp) but not yet evaluated
- **monitor-silence/activity are window-level** — can't monitor individual panes in multi-pane layouts

## Future Improvements

- Control mode (`tmux -CC`) patterns for structured programmatic interaction
- Evaluate tmux MCP servers for native tool integration
- Script templates for common multi-pane agent workflows
- `libtmux` (Python) patterns for complex orchestration
