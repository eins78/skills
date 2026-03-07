---
name: tmux-control
description: Use when sending commands to tmux panes, reading pane output, creating windows/panes, or monitoring tmux sessions. Covers reliable targeting, synchronization, and output capture patterns.
---

# tmux Control Patterns

Reliable patterns for programmatic tmux interaction. The #1 source of bugs is targeting — follow these rules strictly.

## Golden Rules

1. **Use unique IDs** for targeting: `%N` (pane), `@N` (window), `$NAME` (session) — never bare indexes
2. **Use `wait-for`** instead of `sleep` for synchronization
3. **Pass commands to `new-window`/`split-window`** directly — avoid send-keys to freshly created panes (race condition)
4. **Verify targets exist** before sending: `tmux has-session -t $SESSION 2>/dev/null`
5. **Use full binary paths** in commands sent to panes — aliases and shell functions are unavailable

## Targeting

The format is `SESSION:WINDOW.PANE`. All three parts are optional but be explicit.

### Discover targets first — always

```bash
# List all panes with their IDs and human-readable positions
tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'

# List sessions
tmux list-sessions -F '#{session_id} #{session_name}'

# List windows in current session
tmux list-windows -F '#{window_id} #{window_index} #{window_name}'
```

### Targeting syntax

| Target | Meaning | Reliability |
|--------|---------|-------------|
| `%42` | Pane ID (unique, stable) | Best |
| `@3` | Window ID (unique, stable) | Good |
| `$main` | Session by name | Good |
| `main:2.0` | Session:Window.Pane by index | Fragile — indexes shift |
| `:2` | Window 2 in current session | OK for interactive use |
| `-t 2` | Ambiguous (session? window?) | Avoid |

### Capture pane ID at creation

```bash
# Best pattern: capture the ID when you create the pane
PANE_ID=$(tmux split-window -P -F '#{pane_id}')
# or
PANE_ID=$(tmux new-window -P -F '#{pane_id}')

# Now use it reliably
tmux send-keys -t "$PANE_ID" 'echo hello' Enter
```

## Creating Panes and Windows

### Preferred: pass command directly (avoids race condition)

```bash
# Command runs as soon as shell is ready — no race
tmux new-window 'echo "hello from new window"; exec bash'
tmux split-window 'npm run dev; exec bash'

# Capture the ID too
PANE_ID=$(tmux new-window -P -F '#{pane_id}' 'npm test; exec bash')
```

### Why send-keys to new panes is fragile

`send-keys` fires immediately, but the shell in a new pane may not be initialized yet (especially with heavy shell configs like oh-my-zsh). The command arrives before the prompt is ready and gets lost.

If you must use send-keys on a new pane, add a brief delay:

```bash
PANE_ID=$(tmux split-window -P -F '#{pane_id}')
sleep 0.5  # let shell initialize — fragile but sometimes necessary
tmux send-keys -t "$PANE_ID" 'your command' Enter
```

## Sending Commands

### Basic pattern

```bash
tmux send-keys -t "$TARGET" 'your command here' Enter
```

### Quoting rules

- **Outer quotes**: use single quotes around the command to prevent local shell expansion
- **Inner quotes**: if the command itself needs quotes, use double quotes inside singles, or escape
- **Pipes and redirects**: work fine inside quotes

```bash
# Simple
tmux send-keys -t "$PANE" 'ls -la /tmp' Enter

# With pipes (single-quoted, so pipe is literal)
tmux send-keys -t "$PANE" 'ps aux | grep node' Enter

# With inner quotes
tmux send-keys -t "$PANE" 'echo "hello world" > /tmp/out.txt' Enter

# Complex: write to temp file and source it
echo 'complex command "with" pipes | and stuff' > /tmp/tmux-cmd.sh
tmux send-keys -t "$PANE" 'bash /tmp/tmux-cmd.sh' Enter
```

### Nested Claude Code sessions

Running `claude` inside an existing Claude Code session fails due to a guard variable. Workaround:

```bash
tmux send-keys -t "$PANE" 'env -u CLAUDECODE claude -p "your prompt"' Enter
```

## Reading Output

### capture-pane (visible buffer)

```bash
# Last screenful
tmux capture-pane -t "$PANE" -p

# Last N lines
tmux capture-pane -t "$PANE" -p -S -20

# Full scrollback, joined wrapped lines
tmux capture-pane -t "$PANE" -p -S - -J

# With ANSI colors preserved
tmux capture-pane -t "$PANE" -p -e
```

### File-based pattern (for long output)

When output exceeds scrollback or you need the complete result:

```bash
# Send command with output redirect
tmux send-keys -t "$PANE" 'your-command > /tmp/result.out 2>&1; tmux wait-for -S cmd-done' Enter
tmux wait-for cmd-done

# Read the complete output
cat /tmp/result.out
```

### Prompt detection (is the pane idle?)

```bash
tmux capture-pane -t "$PANE" -p | tail -1 | grep -qE '(\$|>|#|%)\s*$' && echo "idle" || echo "busy"
```

**Caution**: capture-pane returns empty if the pane hasn't rendered yet. Don't check immediately after creating a pane.

## Synchronization with wait-for

`wait-for` provides channel-based synchronization — far more reliable than `sleep`.

### Pattern: run command and wait for completion

```bash
# Generate a unique channel name
CHAN="done-$$-$RANDOM"

# Send command with signal on completion
tmux send-keys -t "$PANE" "your-command; tmux wait-for -S $CHAN" Enter

# Block until command completes
tmux wait-for "$CHAN"

# Now safely capture output or proceed
tmux capture-pane -t "$PANE" -p -S -20
```

### Pattern: timeout with wait-for

```bash
CHAN="done-$$"
tmux send-keys -t "$PANE" "long-command; tmux wait-for -S $CHAN" Enter

# Wait with timeout (background a killer)
( sleep 30 && tmux wait-for -S "$CHAN" ) &
TIMEOUT_PID=$!
tmux wait-for "$CHAN"
kill $TIMEOUT_PID 2>/dev/null
```

## Monitoring

### pipe-pane: stream output to file

```bash
# Start logging pane output to a file
tmux pipe-pane -t "$PANE" -o 'cat >> /tmp/pane-log.txt'

# Stop logging
tmux pipe-pane -t "$PANE"

# Stream through a filter (e.g., watch for errors)
tmux pipe-pane -t "$PANE" -o 'grep --line-buffered ERROR >> /tmp/errors.txt'
```

Note: only one pipe per pane. Setting a new pipe replaces the old one.

### monitor-silence: detect idle pane

```bash
# Alert after 10 seconds of no output (window-level option)
tmux set-option -t "$WINDOW" monitor-silence 10

# Check if silence alert triggered
tmux display-message -t "$WINDOW" -p '#{window_silence_flag}'
```

### monitor-activity: detect new output

```bash
# Flag when any output appears in a background window
tmux set-option -t "$WINDOW" monitor-activity on
```

## macOS-Specific

### Full Disk Access (FDA)

tmux sessions started from a GUI terminal (Terminal.app, iTerm2) inherit FDA. Sessions started over SSH do **not**. This matters for accessing `~/Documents/`, `~/Desktop/`, and NFS mounts.

**Rule**: for file system operations requiring FDA, send commands to a tmux pane that was created from a GUI terminal — never to an SSH-initiated session.

### PATH and environment

Commands sent via `send-keys` run in a non-interactive shell context:
- **Aliases are not loaded** — use full commands (e.g., `/opt/homebrew/bin/tmux` not `tmux`)
- **PATH may be incomplete** — use absolute paths for non-standard binaries
- **Shell functions are unavailable** — write scripts to temp files if needed

## Recipes

### Run command and get output

```bash
# 1. Discover target
PANE=$(tmux list-panes -F '#{pane_id}' | head -1)

# 2. Run with wait-for
CHAN="cmd-$$"
tmux send-keys -t "$PANE" "whoami; tmux wait-for -S $CHAN" Enter
tmux wait-for "$CHAN"

# 3. Capture result
tmux capture-pane -t "$PANE" -p -S -5
```

### Start long process and check later

```bash
# 1. Create dedicated window
PANE=$(tmux new-window -P -F '#{pane_id}' -n 'build')

# 2. Send the long-running command (with completion marker)
tmux send-keys -t "$PANE" 'npm run build > /tmp/build.out 2>&1; echo "BUILD_DONE" >> /tmp/build.out' Enter

# 3. Later: check if done
grep -q "BUILD_DONE" /tmp/build.out 2>/dev/null && echo "finished" || echo "still running"

# 4. Read full output
cat /tmp/build.out
```

### Monitor pane for completion

```bash
# 1. Start logging
tmux pipe-pane -t "$PANE" -o 'cat >> /tmp/pane-watch.txt'

# 2. Send command
tmux send-keys -t "$PANE" 'make all' Enter

# 3. Poll for completion marker (or use wait-for instead)
while ! grep -q '\$' <(tail -1 /tmp/pane-watch.txt 2>/dev/null); do
  sleep 2
done
echo "Command completed"

# 4. Clean up
tmux pipe-pane -t "$PANE"
```
