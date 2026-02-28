# Plot Skills Sprint Retrospective: Management Summary

**Date:** 2026-02-28
**Scope:** Analysis of all Plot skill usage from 2026-02-07 through 2026-02-28
**Reports synthesized:** 4 detailed reports (workflow retro, ralph loop, scrum master/rc, improvements)

---

## Executive Summary

Plot is a git-native planning system with 6 skills that was battle-tested in a real sprint ("steal-features" on the qubert project). The sprint produced **8 features + an SDK upgrade in ~80 minutes** of automated execution via a new `ralph-sprint.sh` loop script. The core architecture — plans merge before implementation, git as source of truth, hub-and-spoke skill composition — proved sound under real load. The automation layer needs hardening but validated a genuinely useful execution model.

**Overall grade: B+**. The lifecycle skills are mature (A-/A), the sprint management works (B+), but the automation layer (B-) and the scrum master pattern (D+ production readiness) need investment.

---

## Key Findings

### What Worked Exceptionally Well

1. **Plan-first architecture** — All 8 plan files landed on main before implementation. Every impl branch referenced a stable, approved document. This is the single strongest design decision.

2. **MoSCoW prioritization** — Must Have (4), Should Have (2), Could Have (2) all completed. The priority structure gave the automation loop a natural work order without human intervention.

3. **Self-review loop** — The "review in one iteration, fix in the next" pattern produced meaningful findings (10 inline issues + 6 test gaps in iteration 8). Separating review from fix prevents the agent from softening its own critique.

4. **Ralph loop execution model** — Stateless iterations with git as shared memory elegantly sidesteps the session compaction problem that killed the original orchestration approach. Each iteration gets the full context window.

5. **Overall velocity** — PRs #33-#41 created across 8 iterations. The system produced real, reviewable work at a pace impossible without structured automation.

### What Needs Improvement

| Problem | Severity | Fix Effort | Report |
|---------|----------|------------|--------|
| No cross-iteration state (re-reviews) | High | Low | Ralph Loop 4.1 |
| No iteration timeout/watchdog | High | Low | Ralph Loop 4.2 |
| Plan-only PRs endlessly critiqued | Medium | Low | Workflow Retro |
| Ctrl+C doesn't propagate | Medium | Medium | Ralph Loop 4.6 |
| No "next action" suggestions | Medium | Low | Improvements 1A |
| No machine-readable output for automation | Medium | Medium | Improvements 3A |
| Scrum master pattern not formalized | Low | Medium | Scrum Master |
| No automated tests for skills | Low | High | Workflow Retro |

---

## Three Execution Models: When to Use Each

| Model | Best For | Grade |
|-------|----------|-------|
| **Ralph Loop** | Bulk execution: fix-build-review cycles (5-15 iterations) | B+ |
| **Claude RC (Scrum Master)** | Sprint planning, triage, mid-sprint decisions from phone | C+ (beta infra) |
| **Single Orchestration** | Short, bounded tasks needing full context (3-4 subagent calls max) | C+ (compaction risk) |

**Recommended composite:** RC for planning/oversight, Ralph for execution, single sessions only for short coordination tasks.

---

## Priority Improvements

### Phase 1: Quick Wins (1-2 sessions)

These are all additive, no breaking changes, immediately improve experience:

1. **Next action suggestions** in every skill summary (~10 lines/skill)
2. **Progress indicator** (`Plan: [x] Draft > [*] Approved > [ ] Delivered > [ ] Released`)
3. **Flexibility principle** documentation (makes implicit behavior explicit)
4. **CLAUDE.md snippet template** for adopters
5. **Sprint scope change** documentation
6. **Skills vs CLAUDE.md table** (what goes where)

### Phase 2: Automation Hardening (2-3 sessions)

Build sequentially: #7 enables #8 enables #9.

7. **Machine-readable output mode** — JSON schema for automation consumption
8. **Sprint file as state machine** — HTML comment annotations on items
9. **Review tracking** with SHA comparison to prevent re-reviews

### Ralph-Sprint Script Fixes (1 session, can parallel Phase 1)

- Add reviewed-PR tracking (`.ralph-state/reviewed-prs.txt`)
- Add `timeout 900` per iteration
- Add mid-run instruction injection (watch `.ralph-state/instructions.md`)
- Fix Ctrl+C via background process + wait pattern
- Add per-iteration ntfy summaries
- Add cost tracking from JSON output

### Phase 3: Documentation (1-2 sessions, after Phase 1+2)

10. **Error recovery paths** (troubleshooting guide)
11. **Quickstart guide** for new adopters

---

## Skills vs CLAUDE.md Decision Framework

**Rule of thumb:** Same for every project = skill. Varies per project = CLAUDE.md. Critical behavior constraint = CLAUDE.md rule (always in context).

| In Skills | In Project CLAUDE.md |
|-----------|---------------------|
| Lifecycle phases, transitions | Project-specific directories |
| Branch naming conventions | Release tooling specifics |
| Progress indicators, next actions | Review criteria, CI expectations |
| MoSCoW definitions | Sprint cadence, approval authority |
| Flexibility principle | "Never merge without tests" |
| Automation output schema | ntfy topic, board name |
| Helper scripts | Output format preference |

**Ship a template:** `templates/claude-md-snippet.md` with Plot Config and Plot Rules sections that adopters paste into their CLAUDE.md and customize.

---

## Scrum Master / Phone Orchestration

**Status:** Promising experiment, not production-ready (D+ readiness).

**Concept is sound** (A-): separate monitoring from execution, phone-accessible status, git as shared communication channel. **Infrastructure is beta** (C+): `claude rc` stability issues, context compaction, no persistence across reconnections.

**Next steps:**
1. Write a `plot-monitor` skill (stateless status reports from git)
2. Wait for `claude rc` to stabilize
3. Consider alternative transports (webhook-triggered status, ntfy as bidirectional channel)

---

## Process Observations

### The Sprint as a Whole

The development arc from concept (Feb 7) through battle-testing (Feb 28) followed Plot's own principles. The meta-observation: **Plot was used to develop Plot**, and the workflow held up. The sprint support plan went through idea → approve → implement → deliver, and the sprint itself used those skills to execute.

### The Switch from Orchestrator to Ralph Loop

The mid-sprint pivot from a single orchestration session to the ralph loop was the most important tactical decision. Session compaction was degrading orchestration quality around iteration 3-4. The stateless loop eliminated this entirely. **This should be the default execution model for multi-task sprints.**

### Real-Time Skill Improvement

The user improved the ralph-sprint script 7 times during the live sprint run. This "improve the tool while using the tool" pattern is natural for skill development but not well-supported. The skill should document this: expect to iterate on automation scripts during first real usage.

---

## Detailed Reports

| Report | Focus | File |
|--------|-------|------|
| Workflow Retrospective | What worked, what didn't, grades per phase | `REPORT-workflow-retro.md` |
| Ralph Loop Analysis | Execution model comparison, script improvements | `REPORT-ralph-loop.md` |
| Scrum Master / RC | Phone orchestration pattern analysis | `REPORT-scrum-master-rc.md` |
| Improvements Proposal | Concrete changes, priority ranking, templates | `REPORT-improvements.md` |

---

## Bottom Line

Plot's core architecture is proven. The plan-first, git-native approach produces real results at real velocity. The gap is in the automation layer — reviewed-PR tracking, iteration timeouts, and machine-readable output would address 80% of the observed issues. The scrum master pattern should be formalized but can wait for `claude rc` to mature. Focus investment on Phase 1 (quick wins) and the ralph-sprint fixes — these deliver the most value for the least effort.
