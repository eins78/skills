# Refactor `bye` skill: hub-and-spoke structure

**Date:** 2026-02-07
**Source:** Claude Code

## Summary

Refactored the `bye` skill from a 1,843-word monolith into a ~450-word hub (SKILL.md) with 4 reference files. Session restoration is now a critical gate that blocks all other steps.

## Key Accomplishments

- Reduced SKILL.md from 1,843 to 448 words (76% reduction)
- Elevated session history restoration to a blocking gate (addresses #1 failure mode)
- Replaced prose walls with decision tables for session type detection and git handling
- Extracted detail into progressive-disclosure reference files
- Added `docs/changelogs/` as a changelog directory search path

## Changes Made

- Rewritten: `skills/bye/SKILL.md`
- Created: `skills/bye/claude-code-session-restoration.md`
- Created: `skills/bye/cursor-session-restoration.md` (placeholder)
- Created: `skills/bye/changelog-template.md`
- Created: `skills/bye/subagent-tasks.md`
- Updated: `skills/bye/README.md`

## Decisions

- **Hub-and-spoke over inline**: Smaller models (Sonnet, Haiku) struggled with 7-step nested prose; concise checklist + linked files fixes this
- **Session restoration as gate**: Log analysis of 39 invocations showed agents skipping history restoration was the #1 failure
- **Parallel session safety once**: Was repeated 4 times; single prominent callout suffices
- **Changelog dir search order**: Check `changelogs/` then `docs/changelogs/` to support both conventions

## Next Steps

- [ ] Implement Cursor session restoration guide
- [ ] Test refactored skill across Haiku/Sonnet for improved compliance
- [ ] Add automated validation that reference file links stay in sync

## Repository State

- Committed: c57896b - bye: refactor into hub-and-spoke structure with progressive disclosure
- Branch: main
