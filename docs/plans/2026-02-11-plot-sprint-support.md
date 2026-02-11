# Add sprint support to Plot

> Time-boxed planning for Plot: sprints group work by schedule, not scope, using MoSCoW prioritization.

## Status

- **Phase:** Draft
- **Type:** feature

## Changelog

- Add sprint support: time-boxed plans with MoSCoW priority tiers, dedicated `/plot-sprint` command, sprint lifecycle (Planning/Committed/Active/Closed), and optional retrospectives

## Motivation

Plot plans are scope-boxed ("what to build"). There is no way to express "what we will achieve this week/month" — a time-boxed grouping of work items with a shared goal and deadline. Sprints fill this gap: they have a goal, start/end dates, and sub-items grouped by priority (Must Have, Should Have, Could Have, Deferred). When time runs short, stretch goals move to Deferred rather than being deleted.

The manifesto already distinguishes time-awareness from effort tracking (Principle 9: "Small models welcome" occupies the slot the original plan assumed was available). Sprints operate as a temporal lens over plans — they don't add a new founding principle, they add an optional coordination layer.

## Design

### Sprint Concept

A sprint is a time-boxed coordination artifact that groups work by schedule. It contains:
- A sprint goal (narrative purpose)
- Start and end dates (time is the constraint)
- Sub-items grouped by MoSCoW priority
- Mixed item types: full Plot plan references (`[slug]`) and lightweight task checkboxes

Sprints are **not plans**. Plans track *what* to build; sprints track *when* to ship it. This distinction matters: Principle 2 ("Plans merge before implementation") does not apply to sprints. Sprint files are committed directly to main — no PR, no review gate. They are coordination artifacts, not implementation plans.

### Sprint Lifecycle

Distinct from the plan lifecycle (Draft/Approved/Delivered/Released):

| Phase | Meaning | Trigger | Pacing |
|-------|---------|---------|--------|
| Planning | Sprint being drafted, items selected | `/plot-sprint <slug>: <goal>` | ⏸ natural pause |
| Committed | Team agreed on sprint contents | `/plot-sprint commit <slug>` | ⏳ human-paced |
| Active | Sprint running, work in progress | `/plot-sprint start <slug>` | ⚡ automate ASAP |
| Closed | Timebox ended, retro captured | `/plot-sprint close <slug>` | ⏳ human-paced |

### Sprint File Template

Lives in `docs/sprints/<slug>.md`. Active and closed sprints are indexed via symlink directories:

- `docs/sprints/active/<slug>.md` — symlinks to active sprints
- `docs/sprints/closed/<slug>.md` — symlinks to closed sprints

```markdown
# Sprint: <title>

> <sprint goal - one sentence>

## Status

- **Phase:** Planning | Committed | Active | Closed
- **Start:** YYYY-MM-DD
- **End:** YYYY-MM-DD

## Sprint Goal

<Why this sprint matters. What the team is trying to achieve.>

### Must Have

- [ ] [slug] Plan-backed item description
- [ ] Lightweight task description

### Should Have

- [ ] ...

### Could Have

- [ ] ...

### Deferred

<!-- Items moved here during sprint when they won't make the timebox -->

## Retrospective

<!-- Optional. Filled during /plot-sprint close. -->

## Notes

<!-- Session log, decisions, links -->
```

Item format: `- [ ] [slug] description` (plan reference) or `- [ ] description` (lightweight task).

### Key Design Decisions

1. **Dedicated `/plot-sprint` command** — Sprints get their own skill, not conditional paths in every existing spoke. Sprints have a different lifecycle, directory, and no branch fan-out. Existing spokes get light sprint-awareness only (membership field in plans, sprint gating in release).

2. **Direct to main** — Sprint files are committed directly to main, no PR. Sprints are coordination artifacts, not implementation plans. Principle 2 does not apply.

3. **Minimal manifesto expansion** — Add `## Sprints` paragraph, adjust non-goals, add 1 decision question. ~15 lines total. Sprint lifecycle details live in the `/plot-sprint` SKILL.md.

4. **Adaptation, not deletion** — Items are never deleted from a sprint; they move to `### Deferred`. Scope changes are direct edits on main.

5. **MoSCoW completeness on close** — The close step checks must-haves vs delivered. If must-haves are incomplete, the user chooses: close anyway, move to Deferred, or hold off.

6. **Symlink directories** — `docs/sprints/active/` and `docs/sprints/closed/` mirror the plan pattern (`docs/plans/active/`, `docs/plans/delivered/`). No `docs/archive/` — closed sprints stay in place.

### Approach

#### NEW: `skills/plot-sprint/SKILL.md` — Dedicated Sprint Command

New skill directory. Handles full sprint lifecycle: create, commit, activate, close.

Subcommands (argument-based routing):
- `/plot-sprint <slug>: <goal>` — create sprint (Planning phase)
- `/plot-sprint commit <slug>` — team agrees on contents (Planning → Committed)
- `/plot-sprint start <slug>` — sprint begins (Committed → Active)
- `/plot-sprint close <slug>` — timebox ended, retro (Active → Closed)
- `/plot-sprint` (no args) — show active sprint status

Includes:
- Sprint file template (MoSCoW tiers, dates, goal, retro)
- `docs/sprints/active/` and `docs/sprints/closed/` symlink pattern
- Direct-to-main commits (no PR)
- MoSCoW completeness check on close (must-haves vs should/could/deferred)
- Optional retrospective on close

**Model Guidance** (for the new skill):

| Steps | Min. Tier | Notes |
|-------|-----------|-------|
| Create, commit, start, status | Small | Git commands, templates, file ops |
| Close — MoSCoW completeness | Small | Checkbox parsing, plan ref lookup |
| Close — cross-plan lookup | Mid | Reading multiple plan files to check delivery status of `[slug]` refs |

All sprint operations are structural (Small or Mid). No Frontier needed.

**Pacing annotations:**
- Creation (`/plot-sprint <slug>: <goal>`) — ⏸ natural pause (drafting)
- Commitment (`/plot-sprint commit`) — ⏳ human-paced (team agreement)
- Activation (`/plot-sprint start`) — ⚡ automate ASAP (mechanical transition)
- Scope changes (direct edit) — ⏳ human-paced
- Closure/retro (`/plot-sprint close`) — ⏳ human-paced (retrospective)

#### NEW: `skills/plot-sprint/README.md`

Standard README per repo conventions: purpose, structure, tier (reusable/publishable), testing, provenance, known gaps.

#### MANIFESTO.md (~15 lines added)

**New `## Sprints` section** (after Pacing, before "What Plot Is Not"):

> Sprints are an optional temporal lens over plans. A sprint groups work by schedule — start date, end date, MoSCoW priorities. Plans track *what* to build; sprints track *when* to ship it. Sprint files live in `docs/sprints/`, managed by `/plot-sprint`, committed directly to main. Sprints are coordination artifacts, not implementation plans — Principle 2 does not apply to them.

**Adjusted non-goals** (line 98, "Not a time or effort tracker" becomes):

> Not an effort tracker. No story points, no burndown charts, no estimates. Sprints use deadlines as constraints, not time as a metric — Plot tracks *what* is planned and *whether* it shipped, not *how long* it took.

**New decision question** 8 (renumber existing 7 questions, insert before the closing paragraph):

> 8\. Does it stay focused on scheduling, or creep into effort tracking?

#### plot/SKILL.md (Hub/Dispatcher) — Light-to-moderate additions

- **Plot Config:** add `Sprint directory: docs/sprints/` line
- **Step 1 (Read State):** add `ls docs/sprints/active/ 2>/dev/null` to the parallel state-gathering block
- **Step 2 (Detect Context, on main):** show active sprints with date range and must-have progress
- **Step 3 (Detect Issues):** warn on sprints past end date, multiple active sprints
- **Phases section:** new sprint phases table alongside existing plan phases table
- **Lifecycle section:** sprint lifecycle Mermaid diagram with pacing emoji
- **Spoke commands list:** add `/plot-sprint`
- **Model Guidance:** 2 new rows (Small — sprint listing is mechanical)

#### plot-approve/SKILL.md (Light Touch)

- **Step 4 (Read Plan):** if plan has `Sprint: <name>` field in Status, note membership in approval metadata
- **Step 8 (Summary):** mention sprint membership if present
- **Model Guidance:** no new rows (sprint field is just a string read)

#### plot-deliver/SKILL.md (Light Touch)

- **Step 3 (Read Plan):** extract `Sprint:` field if present
- **Step 8 (Summary):** if plan was in a sprint, note sprint progress ("3/5 sprint items delivered")
- **Model Guidance:** 1 new row (Small — sprint item counting)

#### plot-release/SKILL.md (Light Touch)

- **Step 1 (Determine Version):** when listing delivered plans, show sprint membership alongside
- **Step 2A (RC Path):** tag sprint items in verification checklist
- **Step 3 (Cross-check):** sprint completion is informational, not blocking
- **Model Guidance:** 1 new row (Mid — sprint grouping across plans)

#### plan-idea/SKILL.md (Template Addition)

- **Step 4 template:** add optional `- **Sprint:** <sprint-name>` field to Status section (empty by default, filled when a plan is added to a sprint)

#### Documentation Updates

- **plot/README.md:** add plot-sprint to spoke list and structure table
- **Root README.md:** add plot-sprint row to skills table

### Edge Cases

| Case | Handling |
|------|----------|
| Sprint with only lightweight tasks | Supported. Completeness check reads checkbox state only |
| Plan ref `[slug]` doesn't exist yet | Valid during Planning/Committed. Warn during Active. Report as "not started" at closure |
| Must-haves incomplete at closure | Warn + 3 options: close anyway / move to Deferred / hold off |
| Multiple active sprints | Allowed but warned by dispatcher |
| Same slug for sprint and plan | Disambiguated by file path (`docs/sprints/` vs `docs/plans/`); ask user if ambiguous |
| Sprint with no end date | Valid during Planning. Required before commit transition |

### Open Questions

- [ ] Should sprint creation auto-discover unreleased plans and suggest adding them?
- [ ] Should the dispatcher show a countdown ("3 days remaining") for active sprints?

## Branches

- `feature/plot-sprint-support` — Implement sprint support: new skill, manifesto additions, spoke modifications

## Notes

- Rebased from commit 848811e (pre-PR#4) onto current system with manifesto, model guidance, pacing, RC verification, third-person voice, and sync comments
- Key adaptation: original plan proposed Principle 9 "Time is a constraint, not a metric" — that slot is now taken by "Small models welcome". Sprints are an optional feature, not a founding belief, so they get a manifesto section instead of a principle.
- Key adaptation: original plan extended existing commands (`/plot-idea`, `/plot-approve`, etc.) with sprint type detection. Current design uses a dedicated `/plot-sprint` command — sprints have a different lifecycle, directory, and no branch fan-out, so conditional paths in every spoke would add complexity without benefit.
- Key adaptation: original plan had no model guidance or pacing. All sprint operations are Small or Mid tier; no Frontier needed. Pacing follows the same three categories as the rest of Plot.
- Key adaptation: `docs/archive/` replaced with `docs/sprints/closed/` symlink directory, mirroring the plan convention of symlink-indexed views.
