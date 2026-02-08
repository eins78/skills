# Generic release note discovery in plot skills

**Date:** 2026-02-08
**Source:** Claude Code session in qubert repo

## Summary

While implementing `@changesets/cli` in the qubert project, updated plot skills to discover and adapt to project-specific release note tooling instead of hardcoding any particular tool. Also created a MANIFESTO.md capturing Plot's founding principles, distilled from real-world usage across multiple sessions.

## Context

Work originated from a `/plot-idea changesets` session in qubert. The key design question: should skills learn about changesets directly? Decision: **no** — skills stay project-agnostic and discover conventions from CLAUDE.md, config files, and package.json scripts at runtime.

## Key Accomplishments

- Made plot-release discover release tooling generically (changeset configs, CLAUDE.md rules, package.json scripts) instead of manual changelog collection
- Added release note awareness to plot-approve (reminder after creating impl PRs) and plot-deliver (non-blocking check for entries)
- Created MANIFESTO.md (86 lines) codifying 8 principles, lifecycle, non-goals, and decision framework
- Collected 6 real-world issues in GitHub issue #2 during end-to-end testing

## Changes Made

- Modified: `skills/plot-release/SKILL.md` — replaced manual changelog step with tooling discovery + cross-check verification
- Modified: `skills/plot-approve/SKILL.md` — added step 6: check for release note requirements
- Modified: `skills/plot-deliver/SKILL.md` — added step 6: check for release note entries (non-blocking)
- Created: `skills/plot/MANIFESTO.md` — founding principles and design boundaries

## Decisions

- **Skills stay project-agnostic**: no hardcoded tool references (changesets, semantic-release, etc.). Skills discover project conventions at runtime.
- **Plot is a release participant, not driver**: `/plot-release` handles plot bookkeeping (checking delivered plans, cross-referencing changelogs) while actual release mechanics belong to project tooling.
- **Release note checks are non-blocking in deliver**: missing entries produce warnings, not errors, since some changes legitimately don't need user-facing notes.

## Issues Collected (#2)

1. Agent doesn't mark impl PR as ready after completing work
2. PR not moved to "In Progress" on project board after `/plot-approve`
3. Wrong plan type inference (defaults to `feature` for `infra` work)
4. Squash-merge loses plan refinement history (should offer merge strategy choice)
5. Archiving plans breaks links in implementation PR bodies
6. `/plot-release` tries to own entire release process instead of participating

## Repository State

- Branch: `feature/generic-release-notes`
- Commits: `2949bba`, `1105589`
- PR: #4 (draft) — "Generic release note discovery in plot skills"
- +144/−15 lines across 4 files
