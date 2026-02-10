# PR #4 review fixes

**Date:** 2026-02-10
**Source:** Claude Code

## Summary

Executed all review fixes from `docs/reviews/pr-4-review.md` for PR #4 (`feature/generic-release-notes`). Addressed 15 of 18 items; 3 deferred by decision (commit history rewrites not worth the risk).

## Plan Reference
- Plan: `~/.claude/plans/quirky-cooking-hanrahan.md`
- Planned: Fix top 5 review items, then extend to all non-decision items
- Executed: All planned fixes plus additional polish items and a final reconciliation pass

## Key Accomplishments

- Resolved Principle 3 ("Commands, not code") tension — clarified skills-vs-scripts distinction, removed editorial note
- Standardized MANIFESTO.md and all spoke skills to third-person voice (6 instances fixed)
- Standardized tooling discovery format in plot-deliver to match plot-approve/plot-release
- Fixed changelog diffstats (+231/-74 corrected to +390/-56)
- Stripped invented severity ratings from changelog
- Tightened prose: passive voice, needless words, colon splices
- Added sync comments to 4 spoke Setup sections for maintainability
- Synced plot/README.md Principle 1 with resolved MANIFESTO.md
- Removed drifting line counts from README Structure table
- Added missing "helper script" to plot-approve Model Guidance table

## Changes Made

- Modified: `skills/plot/MANIFESTO.md` — Principle 3 rewrite, voice standardization, prose tightening
- Modified: `skills/plot/README.md` — Principle 1 sync, line counts removed
- Modified: `skills/plot-approve/SKILL.md` — sync comment, Model Guidance fix
- Modified: `skills/plot-approve/README.md` — colon splice fix
- Modified: `skills/plot-deliver/SKILL.md` — tooling discovery format, sync comment, voice fix
- Modified: `skills/plot-deliver/README.md` — colon splice fix
- Modified: `skills/plot-idea/SKILL.md` — sync comment
- Modified: `skills/plot-release/SKILL.md` — sync comment
- Modified: `docs/changelogs/2026-02-08-generic-release-notes.md` — diffstats, severity ratings

## Decisions

- **B4 (vague language):** Keep — manifesto principles can be aspirational
- **B7 (emoji in Mermaid):** Keep — functional legend symbols, not decorative
- **A3/D1 (commit messages):** Skip — not worth rewriting pushed history
- **C2 (Setup duplication):** Keep duplicated for standalone use, add sync comments

## Repository State

- Branch: `feature/generic-release-notes`
- PR: #4 — marked ready for review
- Commits: `3221be2`, `b81b087`, `09a95be`, `69fc88c`, `f640986`, `58815a7`, `5e7c267`
