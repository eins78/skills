# Sessionlog Template

Format and logic for creating or updating sessionlogs. Called from [SKILL.md](./SKILL.md) step 4.

## File Naming

`{sessionlog-dir}/YYYY-MM-DD-topic-slug.md` — use today's date via `date +%Y-%m-%d`.

The sessionlog directory varies by project. If project rules (CLAUDE.md / AGENTS.md) define a sessionlog directory, use that. Otherwise check these locations in order:
1. `docs/sessionlogs/`
2. `sessionlogs/`
3. `docs/changelogs/` (backwards-compat)
4. `changelogs/` (backwards-compat)

Use whichever exists first. If none exists, skip sessionlog creation.

## Template

```markdown
# [Topic]

**Date:** YYYY-MM-DD
**Source:** Claude Code

## Summary
[1-2 sentences: what was accomplished]

## Key Accomplishments
- [Concrete item 1]
- [Concrete item 2]

## Changes Made
- Created: `path/to/file`
- Modified: `path/to/file`

## Decisions
- [Decision 1]: [rationale]

## Next Steps
- [ ] [Pending task 1]
- [ ] [Pending task 2]

## Repository State
- Committed: [hash] - [message]
- Branch: [branch name]
```

## Create vs Update

**Create new** when no sessionlog exists for this work.

**Update existing** when a sessionlog was created earlier in this session (e.g., before compaction) and more work was done after. Steps:
1. Read the existing sessionlog
2. Append new accomplishments/changes
3. Update "Next Steps" and "Repository State"

## Finding Existing Sessionlogs

```bash
# Find the sessionlog directory
ls -d docs/sessionlogs/ sessionlogs/ docs/changelogs/ changelogs/ 2>/dev/null

# List recent sessionlogs (use whichever dir exists)
ls -la docs/sessionlogs/ sessionlogs/ docs/changelogs/ changelogs/ 2>/dev/null | tail -5

# Find sessionlogs from today
ls docs/sessionlogs/ sessionlogs/ docs/changelogs/ changelogs/ 2>/dev/null | grep "$(date +%Y-%m-%d)"
```

When unsure, ask: "Should I create a new sessionlog or update `sessionlogs/[file].md`?"

## Plan Session Handling

**Plan execution session:**
- Sessionlog documents what was EXECUTED, not what was planned
- Add a "Plan Reference" section:

```markdown
## Plan Reference
- Plan: `~/.claude/plans/{slug}.md`
- Planned: [summary from plan]
- Executed: [what was actually done]
```

**Plan creation session:**
- The plan file IS the deliverable
- Sessionlog documents the planning work, not implementation
- Reference the plan file location
