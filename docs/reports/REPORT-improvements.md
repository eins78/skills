# Plot Improvements Proposal

Concrete improvements to the Plot skill system based on real sprint usage with automated execution (ralph-sprint.sh). Two improvement axes: more "on rails" (happy path always clear, next action suggested) and keep/improve flexibility (realtime adaptation, ad-hoc instructions work naturally).

---

## Table of Contents

1. ["On Rails" Improvements](#1-on-rails-improvements)
2. [Flexibility Improvements](#2-flexibility-improvements)
3. [Automation Integration Improvements](#3-automation-integration-improvements)
4. [Documentation Improvements](#4-documentation-improvements)
5. [Skills vs CLAUDE.md: What Goes Where](#5-skills-vs-claudemd-what-goes-where)
6. [Template Files to Create](#6-template-files-to-create)
7. [Priority Ranking](#7-priority-ranking)

---

## 1. "On Rails" Improvements

### A. Next Action Suggestions

Every skill should end its summary step with a concrete `### Suggested Next Actions` block. The dispatcher (`/plot`) already suggests actions but the spoke commands currently leave the user to figure out what comes next.

**Proposed additions per skill:**

**After `/plot-idea`:**
```
### Suggested Next Actions

1. Refine the plan (especially the **Branches** section)
2. When satisfied: `gh pr ready <number>`
3. After human review: `/plot-approve <slug>`

Alternative: If this is a small docs/infra task, skip the plan review and run
`/plot-approve <slug>` directly (the PR will be merged as-is).
```

**After `/plot-approve`:**
```
### Suggested Next Actions

1. Check out an implementation branch: `git checkout feature/<slug>`
2. Implement the plan, commit, push
3. When branch is ready: `gh pr ready <number>`
4. After all impl PRs are merged: `/plot-deliver <slug>`

Alternative: If multiple branches exist, work them in parallel (separate
worktrees or sessions). Each merges independently.
```

**After `/plot-deliver`:**
```
### Suggested Next Actions

- If feature/bug: Run `/plot-release` when ready to cut a versioned release
- If docs/infra: Done! Live on main, no release needed.

Tip: Run `/plot` to see all delivered plans awaiting release.
```

**After `/plot-release rc`:**
```
### Suggested Next Actions

1. Test against the verification checklist: `docs/releases/v<version>-checklist.md`
2. If bugs found: fix via normal `bug/` branches, merge, then `/plot-release rc` for next RC
3. When all items pass: `/plot-release` to cut the final release
```

**After `/plot-release` (final):**
```
### Suggested Next Actions

1. Close any related sprint items: `/plot-sprint <slug> close`
2. Check for remaining active plans: `/plot`

Release complete. No further Plot actions needed.
```

**After `/plot-sprint create`:**
```
### Suggested Next Actions

1. Add items to the sprint file (Must/Should/Could tiers)
2. Set Start and End dates
3. When scope is agreed: `/plot-sprint <slug> commit`
```

**After `/plot-sprint start`:**
```
### Suggested Next Actions

Work sprint items. For plan-backed items, use the normal Plot lifecycle:
- `/plot-idea` for new plans
- `/plot-approve` to start implementation
- `/plot-deliver` when done

When timebox ends: `/plot-sprint <slug> close`
```

**After `/plot-sprint close`:**
```
### Suggested Next Actions

Sprint closed. Consider:
- Review the retrospective with the team
- Carry deferred items to the next sprint: `/plot-sprint <new-slug>: <goal>`
- Cut a release if deliverables are ready: `/plot-release`
```

**Implementation:** Add a `### Suggested Next Actions` subsection to each skill's final Summary step (step 8 in most skills). The content is context-aware -- the skill fills in actual slug, PR number, and branch names. When multiple valid paths exist, list the primary path first, then alternatives.

**Skill change:** Each of the 6 SKILL.md files gets an addition to its Summary step. Estimated: ~10 lines per skill.

### B. Happy Path Visualization

Add a progress indicator to every skill's summary output. The indicator shows all lifecycle phases with the current phase marked.

**Plan progress (shown by plot-idea, plot-approve, plot-deliver, plot-release):**
```
Plan: [*] Draft > [ ] Approved > [ ] Delivered > [ ] Released
```

After approve:
```
Plan: [x] Draft > [*] Approved > [ ] Delivered > [ ] Released
```

After deliver:
```
Plan: [x] Draft > [x] Approved > [*] Delivered > [ ] Released
```

After release:
```
Plan: [x] Draft > [x] Approved > [x] Delivered > [*] Released
```

**Sprint progress (shown by plot-sprint):**
```
Sprint: [*] Planning > [ ] Committed > [ ] Active > [ ] Closed
```

**Implementation:** Add a "Progress" line to each skill's Summary step. The indicator is built from the plan file's Phase field. Use ASCII characters (`[x]`, `[*]`, `[ ]`) for terminal compatibility -- no Unicode required.

**Template for skills to include in their Summary step:**

```markdown
#### Progress Indicator

Build and display a progress line based on the plan's current Phase field:

| Current Phase | Display |
|--------------|---------|
| Draft | `Plan: [*] Draft > [ ] Approved > [ ] Delivered > [ ] Released` |
| Approved | `Plan: [x] Draft > [*] Approved > [ ] Delivered > [ ] Released` |
| Delivered | `Plan: [x] Draft > [x] Approved > [*] Delivered > [ ] Released` |
| Released | `Plan: [x] Draft > [x] Approved > [x] Delivered > [*] Released` |

For docs/infra plans, omit the Released phase:
`Plan: [x] Draft > [x] Approved > [*] Delivered (live)`
```

### C. Error Recovery Paths

Add a `## Troubleshooting` section to the hub skill (`plot/SKILL.md`) that documents recovery procedures. Currently, skills detect errors but don't guide recovery.

**Proposed content for `plot/SKILL.md`:**

```markdown
## Troubleshooting

### Plan PR has merge conflicts

The `idea/<slug>` branch has diverged from main.

```bash
git checkout idea/<slug>
git fetch origin main
git rebase origin/main
# Resolve conflicts
git push --force-with-lease
```

Then retry `/plot-approve <slug>`.

### Implementation PR fails CI

1. Check CI logs: `gh pr checks <number>`
2. Fix on the implementation branch, push
3. Wait for CI to pass, then merge normally

If CI is flaky or irrelevant to this PR, the human decides whether to merge anyway.

### Delivery check finds incomplete work

`/plot-deliver` reports partial/missing deliverables. Options:

1. **Hold off** -- go finish the work, then re-run `/plot-deliver`
2. **Deliver anyway** -- accept the gap (the skill asks for confirmation)
3. **Update the plan** -- if scope changed, edit the plan file on main to match
   what was actually built, then re-run `/plot-deliver`

### Plan file Phase is out of sync

If the Phase field doesn't match reality (e.g., plan says "Draft" but PR is merged):

```bash
# Edit the plan file directly on main
git checkout main && git pull
# Fix the Phase field in docs/plans/YYYY-MM-DD-<slug>.md
git add docs/plans/YYYY-MM-DD-<slug>.md
git commit -m "plot: fix phase for <slug>"
git push
```

### Orphan implementation branch

`/plot` warns about impl branches with no approved plan. Options:

1. **Create the plan retroactively** -- `/plot-idea <slug>: <title>`, approve it
2. **Just merge it** -- if the work is small, skip the plan and merge directly
3. **Delete the branch** -- if the work is abandoned

### Release check finds missing release notes

`/plot-release` cross-check reports gaps. Options:

1. **Add the missing entries** -- update CHANGELOG.md or add changeset files
2. **Proceed anyway** -- if the gap is intentional (internal change, no user impact)
3. **Go back to deliver** -- if a plan was missed entirely

### Sprint past end date with incomplete must-haves

`/plot-sprint close` shows incomplete must-haves. Options:

1. **Close anyway** -- must-haves stay unchecked in place as a record
2. **Move to Deferred** -- explicitly acknowledge they didn't make the timebox
3. **Extend the sprint** -- edit the End date (but consider: is this hiding a scope problem?)
```

### D. Batch Operations

Formalize the "batch" pattern that already worked as an ad-hoc instruction during the ralph sprint. The key insight: "lets do feature files in batch on one branch" just worked because Plot skills are interpreted by an agent, not executed as rigid scripts. Formalizing it means documenting the pattern so agents apply it consistently.

**Add to `plot-idea/SKILL.md` after step 1 (Parse Input):**

```markdown
### Batch Mode

If the user provides multiple slugs (comma-separated, or as a list), or asks
to create multiple plans "in batch" or "together":

1. Parse each `<slug>: <title>` pair
2. Create a single branch: `idea/batch-<first-slug>` (or a name the user provides)
3. Create all plan files on that branch
4. Create a single PR titled "Plan: <title1>, <title2>, ..."
5. Each plan gets its own file and active symlink as normal

This is a convenience -- the plans are still independent after approval.
`/plot-approve` processes each slug separately from the batch PR.

**Detection:** Look for:
- Multiple `:` separated entries in $ARGUMENTS
- Words like "batch", "together", "all at once" in conversation context
- Explicit list of slugs
```

**Add to `plot-approve/SKILL.md` after step 1 (Parse Input):**

```markdown
### Batch Mode

If the user asks to approve multiple plans at once:

1. Verify all plan PRs are non-draft or merged
2. Merge each plan PR sequentially
3. Create all implementation branches
4. Print a combined summary

This works naturally -- just loop the single-plan flow. No special syntax needed.
```

---

## 2. Flexibility Improvements

### A. Ad-Hoc Instruction Compatibility

Document the principle that skills are designed to be overridden by natural language. This is a strength, not a gap -- but it should be explicit so agents (especially smaller models) know to honor overrides.

**Add to `plot/SKILL.md` in a new section after Guardrails:**

```markdown
## Flexibility Principle

Plot skills describe the standard workflow. Natural language overrides are
expected and should be honored. Examples:

- "Do X in batch" -- group multiple operations on one branch
- "Skip the review" -- bypass `gh pr ready` / human review step
- "Use this branch instead" -- substitute a different branch name
- "Just merge it directly" -- skip the plan step for small changes
- "Combine these into one PR" -- merge multiple branches into one

When an override conflicts with a guardrail (e.g., "deliver without merging
PRs"), explain the guardrail and ask for confirmation rather than silently
complying. Guardrails protect; flexibility serves. Both matter.

### Detection

Skills should look for override signals in conversation context:
- Explicit instructions: "skip step 2", "don't create a PR"
- Batch signals: "do these together", "all at once", "in one branch"
- Scope changes: "also include X", "actually, drop Y"
- Branch overrides: "use feature/custom-name instead"

When detected, acknowledge the override ("Skipping review step as requested")
and proceed.
```

### B. Sprint Scope Changes

Make mid-sprint changes a first-class operation. Currently, editing the sprint file directly works but isn't documented.

**Add to `plot-sprint/SKILL.md` as a new subcommand section:**

```markdown
### Scope Change (during Active phase)

Sprint scope changes happen naturally -- the sprint file is a plain markdown
file on main. Any edit is valid. However, for traceability:

#### Adding items mid-sprint

1. Edit the sprint file, add the item to the appropriate MoSCoW tier
2. Add a note in `## Notes`: `- YYYY-MM-DD: Added [slug] to Must Have (reason)`
3. Commit: `git commit -m "sprint: add <item> to <slug>"`

#### Removing or moving items

1. Move the item to `### Deferred` (don't delete -- preserve the record)
2. Add a note: `- YYYY-MM-DD: Moved [slug] from Must to Deferred (reason)`
3. Commit: `git commit -m "sprint: defer <item> from <slug>"`

#### Changing MoSCoW tier

1. Move the checkbox line between tier sections
2. Add a note: `- YYYY-MM-DD: Moved [slug] from Must to Should (reason)`
3. Commit: `git commit -m "sprint: reprioritize <item> in <slug>"`
```

**Update the sprint file template** to include a Scope Changes subsection in Notes:

```markdown
## Notes

### Scope Changes

<!-- Log mid-sprint additions, removals, and tier changes here -->

### Session Log

<!-- Session log, decisions, links -->
```

### C. Parallel Execution Awareness

When multiple agents (or ralph-sprint sessions) work simultaneously, they can conflict on shared files (sprint file, plan files on main).

**Add to `plot/SKILL.md` in a new section:**

```markdown
## Parallel Execution

When multiple agents or sessions work simultaneously:

### Sprint file conflicts

The sprint file is a shared coordination artifact on main. To minimize
conflicts:

1. Pull before editing: `git pull --rebase origin main`
2. Make targeted edits (change one checkbox, not rewrite the file)
3. Push immediately after committing
4. If push fails (someone else pushed): `git pull --rebase && git push`

### Branch creation conflicts

Before creating a branch, check if it already exists:

```bash
git ls-remote --heads origin <branch-name>
```

If it exists, either:
- Check it out and continue work there
- Pick a different name (e.g., `feature/<slug>-2`)

### Status awareness

The `/plot` dispatcher shows work-in-progress from all sessions. Run it
frequently to avoid duplicate work. The helper scripts query the remote,
so they reflect the latest state regardless of local checkout.
```

---

## 3. Automation Integration Improvements

### A. Machine-Readable Output Mode

Skills should support structured output for consumption by automation scripts like ralph-sprint.sh. The key: when invoked by an automation loop, the agent should append a structured JSON block after the human-readable summary.

**Add to `plot/SKILL.md` in a new section:**

```markdown
## Automation Output

When the conversation context indicates automation (e.g., invoked by a script,
or user says "machine-readable output"), append a fenced JSON block after
the summary:

```json
{
  "skill": "plot-deliver",
  "slug": "sse-backpressure",
  "status": "delivered",
  "phase": "Delivered",
  "plan_type": "feature",
  "next_actions": [
    {"action": "/plot-release", "description": "Cut a versioned release"},
    {"action": "/plot", "description": "Check overall status"}
  ],
  "blockers": [],
  "progress": {
    "draft": true,
    "approved": true,
    "delivered": true,
    "released": false
  }
}
```

### Output Schema

| Field | Type | Description |
|-------|------|-------------|
| `skill` | string | Which skill produced this output |
| `slug` | string | The plan/sprint slug |
| `status` | string | Result: "created", "approved", "delivered", "released", "error" |
| `phase` | string | Current phase after this action |
| `plan_type` | string | "feature", "bug", "docs", "infra" |
| `next_actions` | array | Ordered list of suggested next actions |
| `next_actions[].action` | string | Command to run |
| `next_actions[].description` | string | Why this action |
| `blockers` | array | Issues preventing progress |
| `progress` | object | Boolean flags for each phase |
| `sprint` | string? | Sprint slug if plan is in a sprint |
| `prs` | array? | PR numbers and states (for approve/deliver) |

Detection: Look for "automation", "machine-readable", "json output", or
"ralph" in conversation context. Also honor a `## Plot Config` setting:

    - **Output format:** json  <!-- automation mode -->
```

### B. Sprint File as State Machine

The sprint file should be the single source of truth for automation. Currently, ralph-sprint has to query git and gh independently. Enriching the sprint file with live state reduces API calls and makes the automation loop simpler.

**Proposed sprint file additions (tracked in the Items section):**

```markdown
### Must Have

- [x] [auth-improvements] Implement OAuth refresh token handling
  <!-- pr: #45, status: merged, reviewed_at: 2026-02-15T10:30:00Z -->
- [ ] [api-rate-limits] Add rate limiting to public endpoints
  <!-- pr: #47, status: draft, branch: feature/api-rate-limits -->
- [ ] [error-pages] Custom error pages for 4xx/5xx
  <!-- pr: none, status: not-started -->
```

**Implementation approach:**

Skills that modify plan state (approve, deliver) should also update the sprint file if the plan has a Sprint field. Specifically:

1. **`/plot-approve`** -- after creating impl PRs, update the sprint file item:
   ```
   <!-- pr: #<number>, status: draft, branch: <branch-name> -->
   ```

2. **`/plot-deliver`** -- after delivering, check the sprint item box and update:
   ```
   - [x] [slug] description
     <!-- pr: #<number>, status: merged, reviewed_at: <timestamp> -->
   ```

3. **`/plot-sprint status`** -- read these annotations to show enriched status without querying gh.

**Add to each skill's workflow steps where sprint membership is detected.** The edit is small: after the main action, check if `Sprint:` is set in the plan's Status section, and if so, update the sprint file.

### C. Review Tracking

Add review status tracking to prevent re-reviewing unchanged PRs. This was a real pain point in the ralph sprint.

**Proposed addition to sprint file item comments:**

```markdown
- [ ] [slug] description
  <!-- pr: #45, status: open, last_review: 2026-02-15T10:30:00Z, review_sha: abc1234, findings: 3 -->
```

| Field | Purpose |
|-------|---------|
| `last_review` | Timestamp of most recent review |
| `review_sha` | HEAD SHA at time of review |
| `findings` | Number of issues found (for convergence detection) |

**How automation uses this:**

```bash
# Get current HEAD of PR branch
CURRENT_SHA=$(gh pr view $PR_NUMBER --json headRefName --jq '.headRefName' \
  | xargs -I{} git ls-remote origin {} | cut -f1)

# Compare to last reviewed SHA from sprint file
# If same: skip review
# If different: review again
```

**Add a helper script `scripts/plot-review-status.sh`:**

```bash
#!/usr/bin/env bash
# Plot helper: Get review status for sprint items
# Usage: plot-review-status.sh <sprint-slug>
# Output: JSON array of items with review freshness

set -euo pipefail
SLUG="${1:?Usage: plot-review-status.sh <sprint-slug>}"

SPRINT_FILE=$(ls docs/sprints/*-${SLUG}.md 2>/dev/null | head -1)
if [ -z "$SPRINT_FILE" ]; then
  echo '{"error": "Sprint file not found"}'
  exit 0
fi

# Parse items with PR comments, check if PR HEAD has changed since last review
# Output: {items: [{slug, pr, needs_review: true/false, reason: "new commits"}]}
```

The full script implementation would parse the HTML comment annotations and compare SHAs. This keeps review decisions mechanical (small-model capable) rather than requiring judgment about what changed.

---

## 4. Documentation Improvements

### A. Hub-and-Spoke Documentation

The current structure is good but missing quickstart and reference docs for adopters. Proposed additions:

```
skills/plot/
  SKILL.md              # Hub: overview, lifecycle, dispatcher (exists)
  MANIFESTO.md          # Principles (exists)
  changelog.md          # Evolution history (exists)
  README.md             # Development docs (exists)
  scripts/              # Helper scripts (exists)
    plot-pr-state.sh
    plot-impl-status.sh
    plot-review-status.sh   # NEW
  docs/                     # NEW directory
    quickstart.md           # NEW: 5-minute getting started
    lifecycle.md            # NEW: detailed phase reference with examples
    automation.md           # NEW: ralph-sprint integration guide
    troubleshooting.md      # NEW: common issues and fixes (from section 1C)
  templates/                # NEW directory
    plan.md                 # NEW: plan file template
    sprint.md               # NEW: sprint file template
    retrospective.md        # NEW: retro template
    claude-md-snippet.md    # NEW: CLAUDE.md config block for adopters

skills/plot-idea/SKILL.md       # (exists)
skills/plot-approve/SKILL.md    # (exists)
skills/plot-deliver/SKILL.md    # (exists)
skills/plot-release/SKILL.md    # (exists)
skills/plot-sprint/SKILL.md     # (exists)
```

**`docs/quickstart.md` outline:**

```markdown
# Plot Quickstart

Get started with Plot in 5 minutes.

## 1. Install the skills

Symlink Plot skills into your Claude Code skills directory:

    ln -s /path/to/skills/plot ~/.claude/skills/plot
    ln -s /path/to/skills/plot-idea ~/.claude/skills/plot-idea
    ln -s /path/to/skills/plot-approve ~/.claude/skills/plot-approve
    ln -s /path/to/skills/plot-deliver ~/.claude/skills/plot-deliver
    ln -s /path/to/skills/plot-release ~/.claude/skills/plot-release
    ln -s /path/to/skills/plot-sprint ~/.claude/skills/plot-sprint

## 2. Add Plot Config to your project

Add this to your project's CLAUDE.md (see templates/claude-md-snippet.md).

## 3. Create your first plan

    /plot-idea my-feature: Add user authentication

## 4. Follow the workflow

    /plot          # See what's next
    /plot-approve  # After review
    /plot-deliver  # After implementation
    /plot-release  # When ready

That's it. Run `/plot` anytime to see where you are.
```

**`docs/lifecycle.md` outline:**

Detailed reference for each phase transition, with real examples from the test lifecycle runs documented in changelog.md. Include the mermaid diagrams from SKILL.md plus concrete examples of what each command does to the filesystem.

**`docs/automation.md` outline:**

Guide for building automation loops (like ralph-sprint) on top of Plot:
- Reading sprint files programmatically
- Parsing machine-readable output
- Review tracking and convergence detection
- Error handling and retry patterns
- Example loop pseudocode

### B. CLAUDE.md Snippet for Adopters

**`templates/claude-md-snippet.md`:**

```markdown
## Plot Config

- **Branch prefixes:** idea/, feature/, bug/, docs/, infra/
- **Plan directory:** docs/plans/
- **Active index:** docs/plans/active/
- **Delivered index:** docs/plans/delivered/
- **Sprint directory:** docs/sprints/
<!-- Uncomment and configure as needed: -->
<!-- - **Project board:** my-project (#1) -->
<!-- - **Output format:** json -->

## Plot Rules

- Never merge implementation PRs before the plan PR is merged
- Always run tests before marking implementation PRs ready for review
- Sprint scope changes require human approval
- Release sign-off is always human (agents suggest, humans decide)
<!-- Add project-specific rules below: -->
```

---

## 5. Skills vs CLAUDE.md: What Goes Where

| Concern | Where | Why |
|---------|-------|-----|
| Lifecycle phases and transitions | Skill (`SKILL.md`) | Universal to all Plot users |
| Branch naming conventions | Skill (`SKILL.md`) | Convention, not configuration |
| Progress indicator format | Skill (`SKILL.md`) | Consistent across projects |
| Next action suggestions | Skill (`SKILL.md`) | Workflow logic, not project-specific |
| Troubleshooting procedures | Skill (`docs/troubleshooting.md`) | Universal recovery patterns |
| Model tier guidance | Skill (`SKILL.md`) | Capability tiers are model-dependent, not project-dependent |
| MoSCoW definitions | Skill (`SKILL.md`) | Universal meaning |
| Plan/sprint file templates | Skill (`templates/`) | Standard structure |
| Flexibility principle | Skill (`SKILL.md`) | Core design philosophy |
| Batch operation patterns | Skill (`SKILL.md`) | Workflow pattern, not config |
| Automation output schema | Skill (`SKILL.md`) | Standard interface |
| Helper scripts | Skill (`scripts/`) | Reusable tooling |
| Project-specific directories | CLAUDE.md (project) | Varies per project |
| Release tooling specifics | CLAUDE.md (project) | Project uses changesets, custom scripts, etc. |
| Review criteria | CLAUDE.md (project) | Team-specific quality bar |
| CI pipeline expectations | CLAUDE.md (project) | Infrastructure-specific |
| "Never merge without tests" | CLAUDE.md (project) | Critical behavior rule, team-specific |
| Sprint cadence / duration | CLAUDE.md (project) | Team rhythm |
| Approval authority | CLAUDE.md (project) | Who can approve plans |
| Project board name | CLAUDE.md (project) | GitHub Projects board reference |
| Output format preference | CLAUDE.md (project) | json for automation, default for humans |
| Custom branch prefixes | CLAUDE.md (project) | If project uses non-standard prefixes |
| Release note tooling | CLAUDE.md (project) | Changesets config, custom scripts |

**Rule of thumb:** If it would be the same for every project using Plot, it goes in the skill. If it varies per project, it goes in CLAUDE.md. If it is a critical behavior constraint (not just workflow), it goes in CLAUDE.md as a rule.

---

## 6. Template Files to Create

### 1. `templates/claude-md-snippet.md`

Plot config block for adopting project's CLAUDE.md. Content shown in section 4B above. Includes both the `## Plot Config` section and a `## Plot Rules` section with sensible defaults that teams can customize.

### 2. `templates/plan.md`

Extracted from `plot-idea/SKILL.md` step 4. Currently the template is inline in the skill instructions. Externalizing it means:
- Easier to customize per project (copy template, modify, reference in CLAUDE.md)
- Skill references the template instead of embedding it
- Template includes all sections with helpful comments

```markdown
# <title>

> <one-line summary>

## Status

- **Phase:** Draft
- **Type:** feature | bug | docs | infra
- **Sprint:** <!-- optional, filled when plan is added to a sprint -->

## Changelog

<!-- Release note entry. Written during planning, refined during implementation. -->

- <user-facing change description>

## Motivation

<!-- Why does this matter? What problem does it solve? -->

## Design

### Approach

<!-- How will this be implemented? Key architectural decisions. -->

### Open Questions

- [ ] ...

## Branches

<!-- Branches to create when approved: -->

- `feature/<slug>` -- <description>

## Notes

<!-- Session log, decisions, links -->
```

### 3. `templates/sprint.md`

Extracted from `plot-sprint/SKILL.md` step 5. Enhanced with the Scope Changes subsection and item annotation format for automation.

```markdown
# Sprint: <title>

> <sprint goal>

## Status

- **Phase:** Planning
- **Start:** YYYY-MM-DD
- **End:** YYYY-MM-DD

## Sprint Goal

<expanded goal description>

### Must Have

- [ ] <items>

### Should Have

<!-- add items here -->

### Could Have

<!-- add items here -->

### Deferred

<!-- Items moved here during sprint when they won't make the timebox -->

## Retrospective

<!-- Filled during /plot-sprint close -->

## Notes

### Scope Changes

<!-- Log mid-sprint additions, removals, and tier changes -->
<!-- Format: - YYYY-MM-DD: Added/Moved/Removed [slug] reason -->

### Session Log

<!-- Session log, decisions, links -->
```

### 4. `templates/retrospective.md`

Template for the retrospective section, usable standalone or as the structure that `/plot-sprint close` fills in.

```markdown
## Retrospective

### What went well

- <items>

### What could improve

- <items>

### Action items

- [ ] <actionable improvement for next sprint>

### Metrics

- **Must-haves completed:** N/M
- **Should-haves completed:** N/M
- **Could-haves completed:** N/M
- **Deferred items:** N
- **Scope changes during sprint:** N
```

---

## 7. Priority Ranking

### Quick Wins (high impact, low effort)

| # | Improvement | Impact | Effort | Section |
|---|------------|--------|--------|---------|
| 1 | **Next action suggestions** in every skill summary | High -- eliminates "what now?" friction | Low -- ~10 lines per skill, 6 skills | 1A |
| 2 | **Progress indicator** in every skill summary | High -- instant orientation | Low -- template addition, ~5 lines per skill | 1B |
| 3 | **Flexibility principle** documentation | High -- makes implicit behavior explicit | Low -- one new section in hub SKILL.md | 2A |
| 4 | **CLAUDE.md snippet template** | High -- removes adoption friction | Low -- one template file | 4B, 6.1 |
| 5 | **Sprint scope change documentation** | Medium -- formalizes existing pattern | Low -- new subsection in plot-sprint | 2B |
| 6 | **Skills vs CLAUDE.md table** | Medium -- reduces confusion for adopters | Low -- one table in hub SKILL.md or docs | 5 |

### Strategic Investments (high impact, high effort)

| # | Improvement | Impact | Effort | Section |
|---|------------|--------|--------|---------|
| 7 | **Machine-readable output mode** | High -- enables reliable automation | Medium -- schema design, detection logic, output generation in each skill | 3A |
| 8 | **Sprint file as state machine** | High -- single source of truth for automation | Medium -- update all skills that touch plans to also update sprint file | 3B |
| 9 | **Review tracking** with SHA comparison | High -- eliminates redundant reviews | Medium -- new helper script, sprint file annotation format, automation integration | 3C |
| 10 | **Error recovery paths** (troubleshooting) | High -- reduces manual intervention | Medium -- substantial documentation, needs real-world validation | 1C |
| 11 | **Quickstart guide** | High -- critical for adoption | Medium -- requires writing, testing with fresh user | 4A |

### Nice to Haves (lower impact, low effort)

| # | Improvement | Impact | Effort | Section |
|---|------------|--------|--------|---------|
| 12 | **Batch mode formalization** | Low -- already works as ad-hoc instruction | Low -- document existing behavior | 1D |
| 13 | **Plan template externalization** | Low -- current inline template works fine | Low -- extract to file, update reference | 6.2 |
| 14 | **Sprint template externalization** | Low -- same as above | Low -- extract to file | 6.3 |
| 15 | **Retrospective template** | Low -- structure already in skill | Low -- extract to standalone file | 6.4 |

### Defer (lower impact, high effort)

| # | Improvement | Impact | Effort | Section |
|---|------------|--------|--------|---------|
| 16 | **Parallel execution awareness** (locking, conflict detection) | Medium -- rare in practice, git handles most conflicts | High -- lock mechanism design, testing, edge cases | 2C |
| 17 | **Lifecycle reference doc** (`docs/lifecycle.md`) | Low -- SKILL.md already covers this | Medium -- substantial writing, maintaining two sources of truth | 4A |
| 18 | **Automation guide** (`docs/automation.md`) | Medium -- useful but ralph-sprint is the only consumer today | High -- guide requires stable automation output schema first (depends on #7) | 4A |

### Recommended Implementation Order

**Phase 1 -- Quick wins (1-2 sessions):**
Items 1-6. These are additive (no breaking changes), can be done in any order, and immediately improve the experience for both human and automated users.

**Phase 2 -- Automation foundation (2-3 sessions):**
Items 7, 8, 9. These build on each other: machine-readable output (#7) enables sprint-as-state-machine (#8), which enables review tracking (#9). Do them in order.

**Phase 3 -- Documentation (1-2 sessions):**
Items 10, 11. Error recovery paths and quickstart guide. These require real-world testing to validate -- write them after Phase 1 and 2 changes are in use.

**Phase 4 -- Polish (as needed):**
Items 12-15. Template extraction and batch formalization. Do these when touching the relevant files for other reasons.

**Defer indefinitely:**
Items 16-18. Parallel execution locking is over-engineering for the current use case. Lifecycle and automation docs should wait until the automation interface (#7) stabilizes.
