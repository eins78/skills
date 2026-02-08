# Fix publishing prep: spec compliance and README sync

**Date:** 2026-02-07
**Source:** Claude Code

## Summary

Reviewed PR #3 (`prepare-for-publishing`), found spec violations and stale README. Fixed `version` field placement, added missing compatibility info, updated skills table, and added a sync rule.

## Key Accomplishments
- Thorough critical review of PR #3 identifying 6 issues across 3 priority levels
- Fixed agentskills.io spec violation: moved `version` from top-level to under `metadata` in all 7 SKILL.md files
- Added `git`/`gh` CLI requirement to `plot` dispatcher compatibility (was missing, all 4 spokes already had it)
- Updated root README.md skills table from 1 entry to all 7 skills
- Added CLAUDE.md rule requiring README sync when skills change

## Changes Made
- Modified: `skills/bye/SKILL.md` (version under metadata)
- Modified: `skills/plot/SKILL.md` (version under metadata + compatibility fix)
- Modified: `skills/plot-approve/SKILL.md` (version under metadata)
- Modified: `skills/plot-deliver/SKILL.md` (version under metadata)
- Modified: `skills/plot-idea/SKILL.md` (version under metadata)
- Modified: `skills/plot-release/SKILL.md` (version under metadata)
- Modified: `skills/typescript-strict-patterns/SKILL.md` (version under metadata)
- Modified: `README.md` (full skills table)
- Modified: `CLAUDE.md` (README sync rule)

## Decisions
- `version` belongs under `metadata`: agentskills.io spec only allows 6 top-level fields; `skills-ref` validator rejects unknown fields
- `globs` (also not in spec) left as-is: pre-existing field, tracked as known issue for follow-up

## Next Steps
- [ ] Merge PR #3 to main
- [ ] Consider moving `globs` under `metadata` or removing it (also not in agentskills.io spec)
- [ ] Consider squash-merging to clean up the 4-commit history

## Repository State
- Committed: 6d09485 - Fix spec compliance, update README skills table, add sync rule
- Branch: prepare-for-publishing
