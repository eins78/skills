# bye

Session wrap-up skill for Claude Code.

## Purpose

Provides a structured `/bye` command that cleanly ends a session: reconstructs full session history (including compacted context), creates changelogs, commits changes, and summarizes next steps.

## Structure

| File | Purpose | Target |
|------|---------|--------|
| `SKILL.md` | Main skill — checklist and decision tables | ~450 words |
| `claude-code-session-restoration.md` | Claude Code session file analysis and history recovery | ~500 words |
| `cursor-session-restoration.md` | Cursor session restoration (placeholder) | ~80 words |
| `changelog-template.md` | Changelog format, naming, create-vs-update logic | ~250 words |
| `subagent-tasks.md` | 4 subagent task templates for long sessions | ~400 words |

Session restoration is a **critical gate** — the first step in SKILL.md, blocking all other steps until full history is reconstructed.

## Tier

**Reusable / Publishable** — project-agnostic session management. Works in any repository with a `changelogs/` directory.

## Testing

- Validated across normal sessions, compacted sessions, plan execution sessions, and plan creation sessions.
- Tested with parallel sessions to verify session isolation logic.
- Verified subagent detection (correctly refuses to run in child sessions).

## Provenance

Originally authored as a project-local slash command at `~/OPS/home-workspace/.claude/commands/bye.md`. Migrated to a skill, then refactored from a 1,843-word monolith into a hub-and-spoke structure with progressive disclosure.

## Known Gaps

- Relies on `changelogs/` directory convention — projects without it need manual adaptation.
- Session file parsing heuristics (compaction detection) may need updates as Claude Code internals evolve.
- Cursor session restoration not yet implemented.
- No automated test suite; validation is manual/observational.

## Planned Improvements

- Implement Cursor session restoration guide.
- Add support for project-specific changelog directories (configurable path).
- Improve compaction transcript parsing for multi-part syntheses.
