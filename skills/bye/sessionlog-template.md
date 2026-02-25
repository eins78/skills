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

## Step 3: Skip, Create, or Update

**Skip** if any of these apply:
- No sessionlog directory found (Step 1) — do not proceed
- Session produced a plan file and nothing else worth documenting
- Only Q&A happened with no file changes or decisions to preserve
- All changes are straightforward and fully explained by commit messages

**Create** when the session produced context not captured in committed artifacts:
- Decisions that aren't obvious from the code alone
- Multiple approaches tried; rationale for the final choice matters
- Research, intent, or sources that informed the work
- Plan execution that diverged from the plan or was only partially completed

**Update existing** when a sessionlog was created earlier in this session (e.g., before compaction) and more work was done after:
1. Read the existing sessionlog
2. Append new accomplishments/changes
3. Update "Next Steps" and "Repository State"

**Calibration examples:**
- Session created `~/.claude/plans/refactor-auth.md` and nothing else → **Skip** (plan file is the artifact)
- Session added auth feature across 8 files, tried two approaches, chose one → **Create** (decisions and alternatives not in the code)
- Session added `docs/adr/003-caching.md`, informed by research and rejected options → **Create** (the *why* isn't fully in the doc)

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
- The plan file IS the deliverable — **usually no sessionlog needed**
- Only create a sessionlog if significant context exists beyond the plan (e.g., research, rejected approaches, stakeholder input)
- If skipping, reference the plan file path in the final summary instead
