# Sprint Support Plan (Rebased onto PR #4)

**Date:** 2026-02-11
**Source:** Claude Code

## Summary

Rewrote the sprint support plan document to fit the current Plot system after PR #4 added MANIFESTO.md principles, Model Guidance tables, pacing model, RC verification, and third-person voice.

## Key Accomplishments

- Adapted all 7 conflict areas from the original plan (manifesto principle slot, non-goals wording, model guidance, pacing, RC verification, third-person voice, directory structure)
- Key design shift: dedicated `/plot-sprint` command instead of extending every existing spoke with sprint type detection
- Key design shift: sprints commit directly to main (no PR) — they're coordination artifacts, not implementation plans
- Key design shift: `docs/sprints/active/` and `docs/sprints/closed/` symlink directories replace the old `docs/archive/` approach

## Changes Made

- Created: `docs/plans/2026-02-11-plot-sprint-support.md`
- Created: `docs/plans/active/plot-sprint-support.md` (symlink)
- Recreated: `idea/plot-sprint-support` branch from `feature/generic-release-notes` (force-pushed, replacing stale pre-PR#4 version)

## Decisions

- Branch from `feature/generic-release-notes` instead of main: PR #4 not merged yet, but branch contains all the changes the plan depends on
- Dedicated `/plot-sprint` skill: sprints have different lifecycle, directory, and no branch fan-out — conditional paths in every spoke would add complexity without benefit
- No new manifesto principle: Principle 9 slot taken by "Small models welcome"; sprints get a `## Sprints` section instead
- All sprint ops are Small/Mid tier: no Frontier reasoning needed for structural coordination

## Next Steps

- [ ] Merge PR #4 to main
- [ ] Rebase `idea/plot-sprint-support` onto main after PR #4 merges
- [ ] Review and refine the plan
- [ ] Mark PR ready for review (`gh pr ready`)
- [ ] After review: `/plot-approve plot-sprint-support`

## Repository State

- Committed: 2650c82 - plot: add sprint support plan, rebased onto PR #4
- Branch: idea/plot-sprint-support (based on feature/generic-release-notes)
