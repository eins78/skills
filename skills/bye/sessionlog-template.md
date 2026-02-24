# Sessionlog Template

Format and logic for creating or updating sessionlogs. Called from [SKILL.md](./SKILL.md) step 4.

## Step 1: Find Sessionlog Directory

The sessionlog directory varies by project. Check these locations in order:
1. Project rules (CLAUDE.md / AGENTS.md) — if they define a sessionlog directory, use that
2. `docs/sessionlogs/`
3. `sessionlogs/`
4. `docs/changelogs/` (backwards-compat)
5. `changelogs/` (backwards-compat)

Use whichever exists first.

> **If NONE of these directories exist: STOP. Do not create a directory. Do not write a sessionlog. Return to SKILL.md and continue with step 5.**
> This is not optional — projects without a sessionlog directory do not get one created for them.

```bash
# Check which directory exists (if any)
ls -d docs/sessionlogs/ sessionlogs/ docs/changelogs/ changelogs/ 2>/dev/null
# If the above produces NO output → no sessionlog directory exists → STOP.
```

## Step 2: File Naming

`{sessionlog-dir}/YYYY-MM-DD-topic-slug.md` — use today's date via `date +%Y-%m-%d`.

## Step 3: Create, Update, or Skip

**Skip** — no sessionlog directory found (Step 1). Do not proceed.

**Create new** — directory exists, but no sessionlog exists for this work.

**Update existing** — a sessionlog was created earlier in this session (e.g., before compaction) and more work was done after. Steps:
1. Read the existing sessionlog
2. Append new accomplishments/changes
3. Update "Next Steps" and "Repository State"

When unsure, ask: "Should I create a new sessionlog or update `sessionlogs/[file].md`?"

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

## Finding Existing Sessionlogs

```bash
# List recent sessionlogs (use whichever dir exists)
ls -la docs/sessionlogs/ sessionlogs/ docs/changelogs/ changelogs/ 2>/dev/null | tail -5

# Find sessionlogs from today
ls docs/sessionlogs/ sessionlogs/ docs/changelogs/ changelogs/ 2>/dev/null | grep "$(date +%Y-%m-%d)"
```

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
