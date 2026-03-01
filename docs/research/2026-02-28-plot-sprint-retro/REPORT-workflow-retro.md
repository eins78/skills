# Plot Workflow Retrospective

A retrospective on the Plot skills system based on real development and usage data from 2026-02-07 through 2026-02-28.

---

## Timeline

| Date | Event | Artifacts |
|------|-------|-----------|
| 2026-02-07 | Plot created across 5 sessions in a private project | 5 skills, 2 helper scripts, 771 lines |
| 2026-02-07 | Imported to eins78/skills repo | PR #1 |
| 2026-02-08 to 2026-02-10 | Manifesto, release note discovery, model tiers, RC verification loop, full code review | PR #4 (6 sessions) |
| 2026-02-11 | Sprint support plan: designed, refined with 8 improvements, approved | PR #5 (plan), PR #7 (impl draft) |
| 2026-02-14 | Sprint review: 3 parallel explore agents found 9 issues, 6 code fixes merged | PR #7 merged |
| 2026-02-28 | ralph-sprint.sh developed (14 commits), imported with 7 bug fixes | Skills repo commits |
| 2026-02-28 | Live sprint run: `ralph-sprint.sh` against qubert (4 runs) | 18 iterations, PRs #33-40 open (review-clean), #41 merged |

---

## What Worked Well

### 1. The plan-first architecture (idea -> approve -> implement -> deliver -> release)

The core insight -- plans merge to main before implementation begins -- proved its worth under real load. During the qubert sprint, all 8 plan files landed on main first. Every implementation branch referenced a stable, approved document. No one had to guess what a feature was supposed to do or chase down scattered issue comments. The changelog section written at planning time gave release notes a head start.

This is the single strongest design decision in Plot. The system has other flaws, but this one is right.

### 2. MoSCoW prioritization in sprints

The steal-features sprint had clear tiers: 4 Must Have (MCP support, channel memory, file uploads, rate limits), 2 Should Have (channel pairing, browser automation), 2 Unblocked (SDK upgrade, seatbelt sandbox, worktree isolation), and 2 Could Have items. All items across all tiers were completed -- 100% completion. The MoSCoW structure gave ralph-sprint a natural priority order -- work on must-haves first, then should-haves, then could-haves. The sprint also unblocked and completed items that were initially waiting on the SDK upgrade, demonstrating the system's ability to handle mid-sprint dependency resolution.

### 3. The self-review loop

The design where one iteration posts review comments and the next iteration fixes them worked remarkably well. The pattern was visible across all 18 iterations in 4 runs:

- Run 2, iter 3: fixed 6 review comments on PR #33, added 8 unit tests
- Run 2, iter 4: resolved all threads on #33, then reviewed #34 with 3 parallel agents
- Run 3, iter 8: fixed 7 findings on PR #36, reviewed #37, posted 7 findings
- Run 4, iter 13: reviewed PR #40 with 4 parallel agents, posted 10 inline comments + 6 test gaps

The review quality was meaningful -- 53+ review comments addressed across all 8 PRs, with 31 unit tests added across 4 test files. The specialized multi-agent review approach was used repeatedly and produced real findings every time. These are not rubber-stamp reviews.

### 4. Worktree isolation per sprint

The `--worktree "sprint-$SLUG"` flag in ralph-sprint gave each sprint run its own working directory. This meant the main repo stayed clean. The rebase step (step 0 in the prompt) kept the worktree fresh as other iterations merged PRs. This was essential -- without it, iteration 4 would have been working against stale code after iteration 3 had merged changes.

### 5. Git as source of truth

No external tracker was needed. The qubert sprint was managed entirely through:
- `docs/sprints/` for the sprint file
- `docs/plans/active/` and `docs/plans/delivered/` for plan status
- PR state for implementation progress
- Review comments for quality feedback

Anyone with repo access could see the full state. No dashboard logins, no sync problems.

### 6. The hub-and-spoke skill composition

The 6-skill architecture (plot hub + 5 spokes) scaled well. Each spoke is self-contained with clear entry/exit criteria. The dispatcher reads state and suggests the next spoke command. During automated sprint execution, the agent naturally followed the lifecycle without getting confused about which command to run next.

### 7. Model tier guidance tables

Every skill includes a table mapping steps to model tiers (Small/Mid/Frontier). This was prescient -- during the automated sprint, the agent running ralph-sprint was effectively operating at the level described in the tables. Mechanical steps (git commands, template filling) ran fast. Judgment steps (completeness verification, review) took the expected extra time.

### 8. Helper scripts for structured output

`plot-pr-state.sh` and `plot-impl-status.sh` output JSON, which any model tier can parse. This separation -- "skills interpret and adapt; scripts collect and report" (from the manifesto) -- meant the agent never had to scrape `gh pr list` output. It just parsed JSON. This is a small design choice with outsized impact on reliability.

### 9. Overall velocity

8 features plus an SDK upgrade, completed across 18 automated iterations in 4 runs. PRs #33-40 created with all review threads resolved (53+ comments addressed, 31 unit tests added), SDK upgrade (#41) merged to main. All 8 feature PRs are review-clean and awaiting human merge review. The system produced real, reviewable work at a pace that would be impossible without the structure Plot provides. The structure did not slow things down -- it channeled effort effectively.

---

## What Did Not Work Well

### 1. Plan-only PRs getting endlessly critiqued

Iteration 6 re-reviewed PR #38 (worktree-isolation), which contains only a plan document -- no implementation code. The agent found 5 documentation issues. Iteration 7 fixed those 3 remaining comments. The fundamental problem: prose can always be improved, so a review loop on docs-only PRs may never converge. Code has objective correctness criteria (tests pass, types check). Prose does not.

The monitor log flags this as "may never reach 'clean' state since there's always something to critique in prose." This is correct and is a design gap.

### 2. No mechanism to skip review for docs-only PRs

The ralph-sprint prompt tells the agent to self-review "any open PR that has not been reviewed yet." It does not distinguish between implementation PRs (which need code review) and plan-only PRs (which need at most a cursory check). The agent treated PR #38 with the same thoroughness as a code PR, which wasted an entire iteration.

### 3. Re-review of already-reviewed PRs

Iteration 6 re-reviewed PR #38, which was already reviewed in iteration 5. The monitor log notes this as a concern, though it resolved itself in iteration 7 (the agent fixed comments and moved on). The root cause: there is no tracking of which PRs have been reviewed. The agent has to infer this from comment state, which is fragile -- a PR with resolved comments looks the same as a PR that was never reviewed.

### 4. Ctrl+C propagation issues

The ralph-sprint script uses command substitution (`$()`) to capture JSON output from claude. This is necessary for parsing the session ID and result, but it means Ctrl+C does not propagate to the inner process. The operator had to `kill <pid>` directly. From the monitor log: "Known issue, not fixable without changing the buffering approach."

This is a real operational problem. When an iteration goes sideways, the operator needs a clean abort mechanism, not a process hunt.

### 5. No timeout or watchdog per iteration

Each iteration took roughly 10 minutes, but nothing enforced this. If an iteration hung (network timeout, infinite loop, model failure), the script would wait indefinitely. The `set -e` flag catches exit code failures but not hangs. For a script designed to run 100 iterations unattended, this is a significant reliability gap.

### 6. REVIEW signal confusion

The original ralph-sprint prompt had three signals: COMPLETE, BLOCKED, and REVIEW. The REVIEW signal was removed during development (bug fix #3 in the monitor log) because the agent misused it -- it would output REVIEW after posting comments, which the script interpreted as "stop the sprint." Simplifying to two signals (COMPLETE and BLOCKED) with "no signal = continue" was the right fix, but the fact that three signals caused confusion in the first place reveals a design sensitivity: the prompt boundary between "I did work and there is more to do" and "I need to tell the orchestrator something" is fragile.

### 7. Session compaction forced the shift from orchestrator to loop

The original plan was to run the sprint as a single long orchestration session with sub-agents. This failed because Claude Code sessions compact their context over time, and the orchestration state (which PRs were reviewed, what the sprint status is) degraded. The solution was ralph-sprint.sh -- a stateless loop where each iteration starts fresh by reading git state. This works, but it means the system has no cross-iteration memory except what is in git. Every iteration re-discovers the sprint state from scratch.

This is arguably fine for the current design (git is the source of truth), but it means the system cannot learn from patterns across iterations. Iteration 6's re-review problem is a direct consequence.

### 8. Relative script paths

From the README known gaps: "Helper script paths are relative (`./scripts/`) -- works when skill is installed via symlink but may need adjustment for other installation methods." This was encountered during the qubert sprint setup and is a recurring friction point.

### 9. No automated tests for the skills themselves

The validation command (`pnpm test`) only checks that skills parse -- it does not verify that the workflow produces correct results. All testing was manual end-to-end. This means regressions can only be caught by running the full lifecycle, which takes significant time and a real repo.

---

## Concrete Improvements

### 1. Add "already reviewed" tracking

Create a `.ralph-sprint-state.json` file in the worktree that records which PRs have been reviewed and in which iteration. The prompt should instruct the agent to read this file at the start of each iteration and skip PRs that were reviewed in the previous iteration (unless new commits have been pushed since the review).

### 2. Add PR type awareness

Classify PRs as `code` (has implementation changes) or `plan-only` (only markdown in `docs/`). For plan-only PRs, the review step should be limited to a single pass: check for factual errors and structural issues, then move on. No multi-iteration review loop for prose.

Implementation: check the file list of each PR (`gh pr view <n> --json files --jq '.files[].path'`). If all files are under `docs/`, it is plan-only.

### 3. Add watchdog timeout per iteration

Wrap each iteration in a `timeout` command or use the shell `TMOUT` variable. A reasonable default: 15 minutes per iteration (50% headroom over the observed 10-minute average). If an iteration times out, log it, notify via ntfy, and continue to the next iteration.

### 4. Improve Ctrl+C handling

Replace command substitution with a temp file approach:

```bash
tmpfile=$(mktemp)
$RALPH_SPRINT_CLAUDE ... > "$tmpfile" &
pid=$!
trap "kill $pid 2>/dev/null; rm -f $tmpfile; exit 130" INT
wait $pid
json_result=$(cat "$tmpfile")
rm -f "$tmpfile"
```

This keeps the child process in the foreground process group, allowing Ctrl+C to propagate naturally.

### 5. Add end-to-end automated test suite

Create a test script that:
1. Initializes a temp git repo with the Plot config
2. Runs each skill command in sequence (idea -> approve -> deliver)
3. Asserts expected file states (plan file exists, symlinks correct, phase fields updated)
4. Cleans up

This does not need to test the LLM interpretation -- it tests the structural invariants (files in the right places, phases in the right state).

### 6. Formalize the "batch feature files on one branch" pattern

The qubert sprint created 8 plan files, all committed to main before implementation began. This "batch planning" pattern (create all sprint plans at once, then start implementing) is not documented in the skills. It should be: add a section to plot-sprint describing how to create multiple plan files for a sprint in a single planning session.

### 7. Add explicit "next action" suggestions after each skill completes

Every skill's summary section says "Next:" but the suggestions are generic. In a sprint context, the next action should be specific: "Next: implement `feature/mcp-support` (highest priority unstarted Must Have)." This would reduce the agent's decision overhead at the start of each iteration.

### 8. Add sprint-level PR dashboard

After each iteration, the agent should produce a compact status table:

```
| PR | Status | Review | CI |
|----|--------|--------|----|
| #33 | merged | clean  | pass |
| #34 | open   | 3 comments | pass |
| #35 | open   | clean  | fail |
```

This would make the monitor log more useful and give the operator a quick view of sprint health without checking GitHub.

---

## Grades

### Planning (idea/approve): A-

The plan-first architecture is the strongest part of the system. Plans merge before implementation, the template is well-structured, and the approval flow (draft -> ready -> merge -> fan out) works cleanly. The duplicate detection (hard gate on slug, soft warning on title similarity) is a good guardrail.

Deductions: The "batch planning" pattern for sprints emerged organically but is not documented. The plan template could benefit from a "Definition of Done" section so completeness verification in `/plot-deliver` has clearer criteria to check against.

### Implementation: A

Implementation is deliberately outside Plot's scope -- Plot creates the branches and PRs, then gets out of the way. This is the right call. The approval metadata on each branch (timestamp, approver, assignee) provides traceability. The one-plan-many-branches model enabled parallel work during the qubert sprint.

No deductions. The system correctly treats implementation as the natural pause where real work happens.

### Review: B

The self-review loop design is clever and worked well in practice (iterations 2-5 were productive). The use of specialized review agents in iteration 8 was impressive.

Deductions: The lack of "already reviewed" tracking caused iteration 6 to re-review PR #38. Plan-only PRs get the same deep review as code PRs, wasting cycles. The review step has no awareness of PR type or previous review state. These are solvable problems, but they burned real time in the live sprint.

### Delivery: B+

The delivery flow (verify all PRs merged, completeness check, move symlink) is solid. The subagent delegation model in step 5 (frontier orchestrator + small subagents gathering PR diffs) is well-designed for the model tier system.

Deductions: Completeness verification relies entirely on LLM judgment comparing plan deliverables against PR diffs. There is no structural check -- if a plan says "add rate limiting" and the PR adds a file called `rate-limiter.ts`, that is encouraging but not proof. The release note check (step 6) is a good idea but was not exercised in the live sprint.

### Sprint Management: B+

MoSCoW prioritization worked exactly as intended. The sprint lifecycle (Planning -> Committed -> Active -> Closed) is clean. Direct-to-main commits for sprint files is the right decision -- sprints are coordination artifacts, not implementation.

Deductions: No cross-sprint item tracking. The sprint file format does not clearly indicate which items are plan-backed (`[slug]`) versus lightweight tasks, making automated progress tracking harder. The close subcommand's retrospective prompting was not tested in the live run (the sprint was still active at observation time).

### Automation (ralph-sprint): B

The script achieved something remarkable: 18 iterations across 4 runs of autonomous fix-build-review cycles, producing real, mergeable work -- all 8 PRs review-clean with 53+ comments addressed and 31 unit tests added. The rebase step, ntfy notifications, and wrap-up session are well-designed. The simplification from 3 signals to 2 was a critical fix that kept the run going. The 4-run structure (implementation, first review cycle, mid review cycle, final review cycle + completion) emerged organically and showed the script handles restart/resume gracefully.

Deductions: No Ctrl+C propagation. No iteration timeout. No cross-iteration state tracking (reviewed PRs, sprint progress). The command substitution approach for JSON capture creates operational fragility. Seven bug fixes were needed during the first live run -- the script was shipped undertested. The plan-only PR re-review problem and the lack of PR type awareness are automation-specific gaps that would not matter in manual usage.

### Overall: B+

Plot is a strong system with a clear philosophy and a solid core architecture. The plan-first design, git-as-database approach, and model tier system are genuine innovations in the AI-assisted development workflow space. The live sprint proved the system can produce real output at significant velocity.

The gaps are concentrated in the automation layer (ralph-sprint) and the review loop, both of which are relatively recent additions. The core lifecycle (idea -> approve -> deliver -> release) is mature and well-tested. The system's weaknesses are the kind that emerge only under real load -- re-review loops, plan-only PR confusion, signal semantics -- which is exactly the kind of feedback a first live sprint should produce.

The most important next steps are: (1) add cross-iteration state tracking to ralph-sprint, (2) add PR type awareness to the review step, and (3) add a watchdog timeout. These three changes would address the majority of the problems observed in the live sprint run.

---

## Summary Table

| Phase | Grade | Key Strength | Key Weakness |
|-------|-------|-------------|--------------|
| Planning | A- | Plans merge before implementation | Batch planning pattern undocumented |
| Implementation | A | One plan, many branches; stays out of the way | (None significant) |
| Review | B | Self-review loop produces real findings | No "already reviewed" tracking; plan-only PR confusion |
| Delivery | B+ | Subagent delegation model; clean symlink flow | Completeness verification is pure LLM judgment |
| Sprint Mgmt | B+ | MoSCoW worked perfectly; clean lifecycle | No cross-sprint tracking; close/retro untested |
| Automation | B | 18 iters / 4 runs; 53+ comments fixed; 31 tests added | No timeout; no Ctrl+C; no cross-iteration state |
| **Overall** | **B+** | **Plan-first architecture; git-native; real velocity** | **Automation layer needs hardening** |
