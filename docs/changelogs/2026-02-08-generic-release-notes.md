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

## Review Fixes (2026-02-09)

Code review identified 5 issues (2 critical, 1 high, 2 medium). All fixed in commit `c431e4e`:

- **Step numbering (critical):** Merged plot-release steps 2/2b into single "2. Generate Release Notes" with clear if/else — no more ambiguous fall-through
- **Inconsistent discovery (critical):** Standardized tooling discovery order across all 3 spokes: changesets → `CLAUDE.md`/`AGENTS.md` → `package.json` scripts
- **Missing summary reminder (high):** Added conditional release note reminder to plot-approve step 8 summary template
- **Stale PR description (high):** Trimmed PR description from 4 areas/17 files to actual scope (2 areas/5 files) — prior description included already-merged PR #3 work
- **Stale README counts (medium):** Updated plot/README.md line counts and step counts to match current state

## Repository State

- Branch: `feature/generic-release-notes`
- Commits: `2949bba`, `1105589`, `db3b36d`, `c431e4e`
- PR: #4 — "plot: generic release note discovery, manifesto"
- +214/−38 lines across 5 files (including review fixes)
