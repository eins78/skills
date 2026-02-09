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

## Conceptual Refinement (2026-02-09)

Extensive discussion refined Plot's identity from "AI-assisted planning" to "git-native planning for any team." Two implementation commits:

### Human-first framing, pacing model, RC verification loop (`4484593`)

Rewrote MANIFESTO.md and aligned all skills:
- **Opening/Core Belief:** Removed "AI-assisted" framing. Plans belong in git; AI is the designed-for sweet spot, not a requirement. Three roles: human decision-makers, AI/human facilitators, AI/human implementers. Decisions are always human.
- **Principle 1:** Added transparency paragraph — plans-as-files are more visible than backlog items.
- **Principle 3:** Added editorial note flagging the tension between skills (adaptive) and scripts (deterministic). Deferred full rewrite for later discussion.
- **Lifecycle:** Expanded with RC verification loop — RC tags, generated checklists (`docs/releases/v<version>-checklist.md`), endgame testing, human sign-off.
- **New Pacing section:** Three categories (automate ASAP, natural pause, human-paced) with examples. Meta-principle: don't over-complicate because AI doesn't feel friction.
- **Making Decisions:** Added question 6: "Could a human with basic git knowledge execute this manually?"
- **SKILL.md hub:** Pacing annotations on lifecycle Mermaid diagram, RC loop in Release subgraph, Transition Pacing column in phases table.
- **Spoke skills:** Execution notes (manual/AI/script), `gh` CLI softened from requirement to implementation detail.
- **plot-release:** Restructured into RC path (step 2A) and final release path (step 2B). RC cuts tag + generates verification checklist. Multiple RC iterations supported.
- **README.md:** Added Roles section, updated "Commands not code" principle with tension note.

### Small models welcome principle (`80ce013`)

New principle 9: facilitator tasks must work with smaller models (Sonnet, Haiku). Reviewed all skills for small-model friendliness:
- **plot-idea:** Explicit slug pattern `[a-z0-9-]+`, always ask for type (don't infer).
- **plot-approve:** Explicit before/after parsing examples, loop variable clarity for approval metadata.
- **plot-deliver:** Graceful degradation note on completeness check — smaller models skip diff review and ask user to confirm. Explicit if/elif/else chain for tooling discovery.
- **plot-release:** Version fallback to user input when inference fails. Graceful degradation on cross-check — present notes and ask user to review.
- **Dispatcher:** Explicit 7-day threshold for stale drafts (was "a long time").
- **README.md:** Added principle 9 to design principles list.

## Repository State

- Branch: `feature/generic-release-notes`
- Commits: `2949bba`, `1105589`, `db3b36d`, `c431e4e`, `4484593`, `80ce013`
- PR: #4 — "plot: human-first framing, pacing model, small-model principle"
- 8 files changed, +231/−74 lines (cumulative across all sessions)
