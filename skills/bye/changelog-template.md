# Changelog Template

Format and logic for creating or updating changelogs. Called from [SKILL.md](./SKILL.md) step 4.

## File Naming

`{changelog-dir}/YYYY-MM-DD-topic-slug.md` — use today's date via `date +%Y-%m-%d`.

The changelog directory varies by project. Check these locations in order:
1. `changelogs/`
2. `docs/changelogs/`

Use whichever exists. If neither exists, skip changelog creation.

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

**Create new** when no changelog exists for this work.

**Update existing** when a changelog was created earlier in this session (e.g., before compaction) and more work was done after. Steps:
1. Read the existing changelog
2. Append new accomplishments/changes
3. Update "Next Steps" and "Repository State"

## Finding Existing Changelogs

```bash
# Find the changelog directory
ls -d changelogs/ docs/changelogs/ 2>/dev/null

# List recent changelogs (use whichever dir exists)
ls -la docs/changelogs/ changelogs/ 2>/dev/null | tail -5

# Find changelogs from today
ls docs/changelogs/ changelogs/ 2>/dev/null | grep "$(date +%Y-%m-%d)"
```

When unsure, ask: "Should I create a new changelog or update `changelogs/[file].md`?"

## Plan Session Handling

**Plan execution session:**
- Changelog documents what was EXECUTED, not what was planned
- Add a "Plan Reference" section:

```markdown
## Plan Reference
- Plan: `~/.claude/plans/{slug}.md`
- Planned: [summary from plan]
- Executed: [what was actually done]
```

**Plan creation session:**
- The plan file IS the deliverable
- Changelog documents the planning work, not implementation
- Reference the plan file location
