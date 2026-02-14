# bye: Rename changelogs to sessionlogs

**Date:** 2026-02-11
**Source:** Claude Code

## Summary
Renamed "changelogs" to "sessionlogs" throughout the bye skill to better reflect what these files are. Added backwards-compatibility for repos still using `changelogs/` directories and project-rules override for custom paths.

## Key Accomplishments
- Renamed `changelog-template.md` → `sessionlog-template.md`
- Updated all "changelog" references to "sessionlog" across SKILL.md, README.md, and root README.md
- New directory lookup: `docs/sessionlogs/` → `sessionlogs/` → `docs/changelogs/` → `changelogs/`
- Added CLAUDE.md / AGENTS.md override for project-specific sessionlog directories
- Created PR #6

## Changes Made
- Renamed: `skills/bye/changelog-template.md` → `skills/bye/sessionlog-template.md`
- Modified: `skills/bye/SKILL.md`
- Modified: `skills/bye/README.md`
- Modified: `README.md`

## Decisions
- Directory lookup order: preferred paths first (`docs/sessionlogs/`, `sessionlogs/`), backwards-compat last (`docs/changelogs/`, `changelogs/`)
- Project rules (CLAUDE.md / AGENTS.md) can override the default directory — no need for a separate config mechanism

## Next Steps
- [x] Merge PR #6
- [x] Rename `docs/changelogs/` → `docs/sessionlogs/` in this repo (done 2026-02-14, commit 79e6aec)

## Repository State
- Committed: 845a1ef - bye: Rename changelogs to sessionlogs
- Branch: bye-rename-changelogs-to-sessionlogs
- PR: https://github.com/eins78/skills/pull/6
