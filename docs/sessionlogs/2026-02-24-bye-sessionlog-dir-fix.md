# bye: fix sessionlog dir creation bug

**Date:** 2026-02-24
**Source:** Claude Code

## Summary
Fixed a bug where the bye skill was causing Claude to create sessionlog directories in projects that don't have one, instead of skipping sessionlog creation as intended.

## Key Accomplishments
- Identified root cause: structural priming in skill instructions overwhelmed the buried "skip" instruction
- Restructured `sessionlog-template.md` to lead with directory existence check (Step 1) and prominent STOP instruction
- Added gate check directly in SKILL.md step 4 checklist
- Made "Skip" a first-class option alongside Create/Update
- Created PR #12

## Changes Made
- Modified: `skills/bye/SKILL.md` — gate check in step 4, softened frontmatter description
- Modified: `skills/bye/sessionlog-template.md` — restructured with existence check as Step 1, Skip option first in decision tree

## Decisions
- Led with existence check rather than just strengthening the negative instruction — positive framing ("STOP and return to step 5") is more effective than "don't create directories"
- Made "Skip" the first option in the Create/Update/Skip decision to break the false binary

## Next Steps
- [ ] Merge PR #12 after manual testing
- [ ] Test `/bye` in a project without sessionlog directory to verify fix

## Repository State
- Committed: 67f1d57 - bye: fix sessionlog dir creation — skip when none exists
- Branch: fix-bye
- PR: https://github.com/eins78/skills/pull/12
