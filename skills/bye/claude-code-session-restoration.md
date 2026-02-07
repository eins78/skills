# Claude Code Session Restoration

Detailed procedure for restoring full session history from Claude Code's data files. Called from [SKILL.md](./SKILL.md) step 1.

## Finding Session Data

Claude Code stores session data under `~/.claude/projects/` using an encoded project path:

```bash
# Derive the project path
PROJECT_PATH=$(pwd | tr '/' '-' | sed 's/^-//')
echo "Session data: ~/.claude/projects/$PROJECT_PATH/"

# Or find directly
ls -la ~/.claude/projects/ | grep "$(basename $(pwd))"
```

Session files are JSONL format: `~/.claude/projects/{PROJECT_PATH}/{session-id}.jsonl`

## Sources to Check (in order)

1. **This conversation** — read backward through all messages, including any compaction summaries
2. **Session logs** — check `~/.claude/logs/` for this session's activity
3. **Git history** — `git log --oneline -20` (beware: may include parallel session commits)

When reading logs, match timestamps and session IDs to THIS conversation. Do not assume all recent activity is from this session.

## Detecting Compaction

Compaction embeds prior conversation in summary messages. Look for messages containing:

- `"Context: This summary will be shown"` AND `"Please write a concise, factual summary of this conversation"` → single compaction
- `"Context: This summary will be shown"` AND `"synthesizes these part-summaries"` → multi-part synthesis
- `"Context: This summary will be shown"` AND `"summary of this part of a conversation"` → part summary
- Embedded `User:` / `Agent:` / `---` blocks → conversation transcript format

## Parsing Compaction Transcripts

When compaction is detected, extract the embedded conversation:

```
User: [their message]
Agent: [claude's response]
---
User: [next message]
Agent: [response]
...
```

From these transcripts, identify:
- Files created or modified
- Decisions made
- Tasks completed or deferred

If the compaction summary says "Here is a summary of our conversation so far" — that summarized work IS part of this session. Include it in your assessment.

## Detecting Session Type

Run these checks in order on the session file:

### 1. Subagent Check
- Session file is in a `subagents/` directory
- Session JSON contains `"isSidechain": true`
- If subagent → **STOP**. Do not proceed with /bye.

### 2. Metadata Session Check
- `messageCount <= 2` in sessions-index.json
- First message contains `"Context: This summary will be shown"`
- If metadata → **SKIP**. Not a real work session.

### 3. Plan Execution Check
- First messages reference a plan file or "execute the plan"
- System message references `~/.claude/plans/*.md`
- Session starts with implementation without prior planning discussion
- Recent plan file in `~/.claude/plans/` (modified in last 2 hours)

```bash
ls -lt ~/.claude/plans/ | head -5
```

If found → **Plan execution session**. Read the plan file to compare what was PLANNED vs what was DONE.

### 4. Plan Creation Check
- System message contains `"Plan mode is active"`
- Session focused on analysis and planning, not implementation
- If found → **Plan mode session**. The plan file IS the deliverable.

### 5. Normal Session
None of the above → standard session. Continue with wrap-up checklist.

## Parallel Session Filtering

When checking logs and git history, verify each item belongs to THIS session:

1. Check `$CLAUDE_SESSION_ID` environment variable (may be empty)
2. Match timestamps to this conversation's timeline
3. Confirm work was discussed in THIS conversation

If you find work you don't remember discussing, ASK:
> "I found [X] in the logs. Was this from our session or a parallel one?"
