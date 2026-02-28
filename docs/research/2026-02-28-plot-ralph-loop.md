# Ralph Loop Analysis Report

An analysis of the `ralph-sprint.sh` execution model, its interaction with Plot skills, and comparisons against alternative orchestration approaches. Written for the skill author to improve both the script and the Plot skill suite.

---

## 1. Execution Model Comparison

Three distinct execution models were used across the sprint support development and live sprint runs. Each trades off context continuity, compaction risk, and human oversight differently.

### a) Single Orchestration Session with Subagents

**Model:** One long-running Claude session orchestrates the entire sprint. It dispatches subagents (via the Task tool) for mechanical work — PR creation, test runs, review posting — while maintaining a unified context of the sprint's state, decisions made, and work remaining.

**Strengths:**
- Full context continuity across the entire sprint
- The orchestrator remembers what was reviewed, what failed, and why
- Can make intelligent priority decisions based on accumulated knowledge
- Subagent delegation matches Plot's model guidance tiers (frontier orchestrator, small subagents)

**Weaknesses:**
- Compaction is the fatal flaw. As the session grows, earlier context is compressed, and the orchestrator loses track of its own decisions. For a sprint spanning 8+ task iterations, compaction begins degrading quality around iteration 3-4.
- A single crash or network disconnect loses the entire session state.
- Cost scales with context window size — later iterations pay for the full accumulated context even when most of it is irrelevant.
- No clean restart point. If something goes wrong at iteration 6, there is no way to resume from a known-good state.

**Grade: C+**
Good theory, poor practice. The compaction problem makes this model unreliable for any multi-hour agentic workflow. It works well for short orchestration tasks (3-4 subagent calls), but degrades for sustained sprint execution.

**When appropriate:** Short coordination tasks where the full context fits comfortably in a single session. Planning sessions, one-off multi-file refactors, or quick triage runs where the orchestrator needs to see everything at once.

### b) Ralph Loop (ralph-sprint.sh)

**Model:** A bash script loops N iterations of `claude -p` (non-interactive pipe mode). Each iteration starts with a completely fresh context window, receiving only the static prompt and whatever it can read from git state (branches, PRs, sprint file). Promise signals (`<promise>COMPLETE</promise>`, `<promise>BLOCKED</promise>`) control loop termination. No signal means continue.

**Strengths:**
- Zero compaction risk. Each iteration gets the full context window.
- Crash-resilient. If iteration 5 fails, iteration 6 starts fresh and picks up from git state.
- Simple to reason about. The loop is ~210 lines of bash with no external dependencies beyond `jq` and `curl`.
- The separation of review and fix across iterations is a genuine design insight — it forces honest self-review because the agent cannot soften its critique knowing it will immediately fix the issues.
- ntfy notifications give the human a lightweight monitoring channel.
- Wrap-up session via `/bye` creates documentation automatically.

**Weaknesses:**
- No memory across iterations. The agent cannot learn from its own mistakes.
- Static prompt. Priorities cannot shift mid-run without killing the script.
- Output is fully buffered. The human sees nothing during a 10-minute iteration.
- No cost tracking. API usage per iteration is invisible.

**Grade: B+**
Practical, robust, and surprisingly effective for a first implementation. The stateless-by-design approach turns the compaction weakness of Model A into a strength. The live run data (8+ iterations, ~80 minutes, all sprint features implemented) validates the approach.

**When appropriate:** Multi-task sprints where each task is self-contained and discoverable from git state. The sweet spot is 5-15 iterations of moderate complexity — enough to justify automation, not so many that the lack of cross-iteration memory becomes costly.

### c) Claude RC (Scrum Master from Phone)

**Model:** A human uses Claude on a mobile device (via the Claude app or similar) as a scrum master — reading sprint status, deciding what to work on next, then dispatching work via Claude Code sessions or direct commands. The human provides the memory and priority judgment; Claude provides the execution.

**Strengths:**
- Human judgment in the loop at every decision point.
- Can adapt priorities instantly based on external information (customer feedback, production incidents, team availability).
- No compaction risk because each interaction is short.
- Natural oversight — the human sees what happened before deciding what happens next.

**Weaknesses:**
- Bottlenecked on human attention. If the human is away for an hour, no progress happens.
- Higher latency per iteration. A human reading a status update and deciding next steps takes minutes, not milliseconds.
- Requires the human to maintain mental context across sessions.
- Not suitable for overnight or weekend automation.

**Grade: B**
The right model when judgment matters more than throughput. Excellent for the first few iterations of a sprint (when priorities are uncertain) and for the final iterations (when quality matters most). Poor for the mechanical middle — the 5-10 iterations of fix-build-review that the ralph loop handles well.

**When appropriate:** Sprint kickoff and close. Triage and prioritization decisions. Any situation where the next action is ambiguous or the stakes of a wrong decision are high.

### Composite Recommendation

The three models are complementary, not competing. The optimal sprint execution would use:

1. **Claude RC** for sprint planning, commitment, and initial priority setting.
2. **Ralph Loop** for the bulk execution phase — fix, build, review cycles.
3. **Claude RC** for mid-sprint reprioritization when ntfy signals a BLOCKED state.
4. **Single orchestration** only for short, bounded tasks within the sprint (e.g., a complex refactor that needs to see multiple files simultaneously).

---

## 2. Ralph Loop Strengths

### Stateless Iterations Eliminate Compaction Risk

This is the core insight. By treating each `claude -p` invocation as an independent agent, the script sidesteps the fundamental limitation of long-running LLM sessions. Each iteration gets the full 200K context window. Iteration 8 has exactly the same reasoning capacity as iteration 1. This is not a workaround — it is a genuinely better architecture for sustained agentic work.

### Git as Shared Memory

The script uses git itself as the inter-iteration communication channel. PRs, review comments, CI status, and the sprint file are all readable by any iteration. This is elegant because it requires no custom state management — the same tools the agent uses to do its work are also the tools it uses to understand what work remains.

### Promise Signal Protocol

The `<promise>` XML tag wrapping is a small but critical design choice. The development history shows that bare keyword detection (`grep '^COMPLETE'`) produced false positives when the agent echoed the prompt or discussed completion criteria. The XML tags create an unambiguous signal channel within the otherwise unstructured text output. The three-state protocol (COMPLETE, BLOCKED, no-signal-continue) is minimal and correct.

### Separation of Review and Fix

The prompt explicitly instructs the agent to self-review in one iteration and fix in the next. This forces review comments to be committed as real PR comments before the agent addresses them — preventing the common failure mode where an agent reviews its own code, finds issues, and silently fixes them without documenting the findings. The monitor log confirms this works: iteration 2 reviewed PR #36 and posted 7 findings, iteration 3 fixed those 7 findings.

### Minimal Dependencies

The script requires only bash, `jq`, `curl`, and `claude`. No Node.js runtime, no Python, no database. This makes it portable and debuggable. The entire control flow is visible in 210 lines.

### ntfy for Human-in-the-Loop

Push notifications via ntfy give the human three actionable signals: COMPLETE (celebrate), BLOCKED (intervene), and iterations-exhausted (investigate). The notifications include a summary extracted from the agent's output, providing enough context to decide whether to intervene immediately or wait.

### Wrap-up Session

The `/bye` wrap-up session that collects all iteration session IDs and creates a combined sessionlog is a thoughtful addition. It turns ephemeral pipe-mode sessions into documented history, which is important for retrospectives and debugging.

---

## 3. Ralph Loop Weaknesses

### No Memory Across Iterations

The most significant limitation. Each iteration starts completely fresh — it cannot know that iteration 4 already reviewed PR #38, or that iteration 3 encountered a flaky test that resolved on retry. The monitor log shows this materializing: iteration 6 re-reviewed PR #38 despite iteration 5 having already reviewed it. While the loop self-corrected (iteration 7 just fixed the comments and moved on), it wasted an entire iteration's worth of API calls on redundant work.

### No Iteration-to-Iteration Context

Related but distinct from memory: the agent has no way to pass structured information to the next iteration. If iteration 5 discovers that a particular test is flaky, iteration 6 has no way to know this. Each iteration must re-derive the full state of the sprint from git, which is expensive and occasionally incomplete (e.g., PR review state is not always obvious from `gh` CLI output).

### Ctrl+C Propagation

The monitor log notes this explicitly: Ctrl+C does not work when `claude` is inside a command substitution `$()`. The user had to `kill <pid>` directly. This is a bash limitation — command substitution runs in a subshell that does not receive the parent's terminal signals. For a script intended to run for hours, reliable interruption is essential.

### No Timeout or Watchdog

If a `claude -p` invocation hangs (network issue, API outage, infinite loop in the agent's reasoning), the script blocks indefinitely. There is no timeout, no health check, and no way to detect a stalled iteration. The user's only recourse is to notice the silence and manually kill the process.

### Static Prompt

The prompt is composed once at script start and reused for every iteration. If the human realizes mid-sprint that a different task should be prioritized, or that a particular PR should be abandoned, there is no way to communicate this to the running loop without killing it and restarting with a modified prompt.

### No Progress Visibility During Iteration

Because `claude -p` buffers all output, the human sees nothing during the ~10 minutes each iteration takes. They receive an ntfy notification when the sprint ends (COMPLETE or BLOCKED) or when iterations are exhausted, but have no visibility into what the agent is currently doing. This makes debugging and monitoring difficult.

### No Cost Tracking

The script uses `--output-format json` to extract the result and session ID, but does not read or log the cost-related fields (`input_tokens`, `output_tokens`, `cost_usd` if available). Over 8+ iterations at ~10 minutes each, the total API cost could be substantial, and the user has no visibility into it.

### Plan-Only PR Problem

The monitor log documents a real issue: PR #38 (worktree-isolation) was a plan-only PR with no implementation code. The agent kept finding documentation issues in the plan prose, which is a legitimate but unproductive review target. The current prompt has no way to distinguish plan PRs from implementation PRs, leading to wasted review cycles.

---

## 4. Improvements to the Script

### 4.1 Add Reviewed-PR Tracking

**Problem:** The agent re-reviews PRs it already reviewed in prior iterations.

**Solution:** Maintain a local file in the worktree (e.g., `.ralph-state/reviewed-prs.txt`) that records which PRs have been reviewed and in which iteration. Prepend this information to the prompt for each iteration.

```bash
REVIEW_LOG=".ralph-state/reviewed-prs.txt"
mkdir -p .ralph-state

# Before each iteration, add to prompt:
EXTRA_CONTEXT=""
if [ -f "$REVIEW_LOG" ]; then
  EXTRA_CONTEXT="
Previously reviewed PRs (do NOT re-review these unless they have new commits):
$(cat "$REVIEW_LOG")
"
fi

# After each iteration, parse output for reviewed PRs and append
```

This is the single highest-impact improvement. It eliminates redundant review cycles without requiring cross-iteration memory.

### 4.2 Add Per-Iteration Timeout

**Problem:** Hung iterations block the script indefinitely.

**Solution:** Wrap the `claude -p` invocation in a `timeout` command.

```bash
json_result=$(timeout 900 $RALPH_SPRINT_CLAUDE --worktree "sprint-$SLUG" \
  -p "$PROMPT" --output-format json) || {
  if [ $? -eq 124 ]; then
    echo "Iteration $i timed out after 15 minutes."
    notify "Iteration Timeout" "Iteration $i of sprint '$SLUG' timed out." "hourglass"
    continue
  fi
  json_result=""
}
```

A 15-minute timeout (with the observed ~10-minute average) gives enough headroom for complex iterations while catching genuine hangs.

### 4.3 Add Cost Tracking

**Problem:** No visibility into API costs across iterations.

**Solution:** Extract cost fields from the JSON output and maintain a running total.

```bash
TOTAL_INPUT_TOKENS=0
TOTAL_OUTPUT_TOKENS=0

# After each iteration:
input_tokens=$(echo "$json_result" | jq -r '.input_tokens // 0' 2>/dev/null) || input_tokens=0
output_tokens=$(echo "$json_result" | jq -r '.output_tokens // 0' 2>/dev/null) || output_tokens=0
TOTAL_INPUT_TOKENS=$((TOTAL_INPUT_TOKENS + input_tokens))
TOTAL_OUTPUT_TOKENS=$((TOTAL_OUTPUT_TOKENS + output_tokens))

echo "Iteration $i: ${input_tokens} in / ${output_tokens} out (total: ${TOTAL_INPUT_TOKENS} in / ${TOTAL_OUTPUT_TOKENS} out)"
```

Include totals in the ntfy notification at sprint completion.

### 4.4 Add Mid-Run Instruction Injection

**Problem:** The prompt is static and cannot adapt to changing priorities.

**Solution:** Watch a file (e.g., `.ralph-state/instructions.md`) and prepend its contents to the next iteration's prompt if it exists.

```bash
INSTRUCTIONS_FILE=".ralph-state/instructions.md"

# Before building prompt for each iteration:
INJECTED=""
if [ -f "$INSTRUCTIONS_FILE" ]; then
  INJECTED="
HUMAN OVERRIDE (from .ralph-state/instructions.md):
$(cat "$INSTRUCTIONS_FILE")
---
"
  # Optionally archive: mv "$INSTRUCTIONS_FILE" ".ralph-state/instructions-iter-$i.md"
fi

FULL_PROMPT="${INJECTED}${PROMPT}"
```

The human can then write instructions at any time: `echo "Skip PR #38, it is plan-only" > .ralph-state/instructions.md`. The next iteration picks them up.

### 4.5 Add Iteration Summary to ntfy

**Problem:** ntfy notifications only fire on sprint-level events (COMPLETE, BLOCKED, exhausted). The human has no per-iteration visibility.

**Solution:** Send a brief ntfy notification after each iteration with the first few lines of the agent's summary.

```bash
# After extracting result:
iter_summary=$(echo "$result" | tail -5 | head -3)
notify "Iteration $i/$ITERATIONS" "$iter_summary" "arrow_forward"
```

Use a lower priority than sprint-level notifications so the human can configure notification filtering.

### 4.6 Better Ctrl+C Handling

**Problem:** Ctrl+C does not propagate to `claude` inside command substitution.

**Solution:** Run `claude` in the background and use `wait` with a trap.

```bash
CLAUDE_PID=""

interrupt_handler() {
  if [ -n "$CLAUDE_PID" ]; then
    kill "$CLAUDE_PID" 2>/dev/null
    wait "$CLAUDE_PID" 2>/dev/null
  fi
  INTERRUPTED=true
}
trap interrupt_handler INT

# In the loop:
tmpfile=$(mktemp)
$RALPH_SPRINT_CLAUDE --worktree "sprint-$SLUG" \
  -p "$PROMPT" --output-format json > "$tmpfile" 2>&1 &
CLAUDE_PID=$!
wait "$CLAUDE_PID"
CLAUDE_PID=""
json_result=$(cat "$tmpfile")
rm -f "$tmpfile"

if [ "$INTERRUPTED" = true ]; then
  break
fi
```

This trades the simplicity of command substitution for reliable signal handling.

### 4.7 Dry-Run Mode

**Problem:** No way to test prompt changes without running a full iteration.

**Solution:** A `--dry-run` flag that prints the prompt and exits.

```bash
if [ "$DRY_RUN" = true ]; then
  echo "=== DRY RUN: Prompt for iteration 1 ==="
  echo "$PROMPT"
  echo "=== END ==="
  EXITING_NORMALLY=true
  exit 0
fi
```

### 4.8 Iteration Log File

**Problem:** The monitor log in the repository was maintained manually during the live run.

**Solution:** Automatically append a structured log entry after each iteration.

```bash
LOG_FILE=".ralph-state/iterations.log"

# After each iteration:
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | iter=$i | session=$session_id | tokens_in=$input_tokens | tokens_out=$output_tokens | signal=$(echo "$result" | grep -o '<promise>[^<]*</promise>' || echo 'none')" >> "$LOG_FILE"
```

---

## 5. Improvements to Plot Skills for Better Loop Integration

### 5.1 Machine-Readable Sprint Status

**Current state:** `/plot-sprint` (status subcommand) outputs human-readable markdown. The ralph loop prompt tells the agent to run `/plot-sprint <slug>` to understand sprint state, but the agent must parse prose to extract actionable information.

**Improvement:** Add a `--json` or `--machine` flag to the status subcommand that outputs structured data.

```json
{
  "slug": "steal-features",
  "phase": "Active",
  "days_remaining": 3,
  "must_have": {"done": 2, "total": 4, "items": [...]},
  "should_have": {"done": 1, "total": 2, "items": [...]},
  "could_have": {"done": 0, "total": 1, "items": [...]},
  "open_prs": [{"number": 35, "title": "...", "ci_status": "passing", "unresolved_comments": 0}]
}
```

This is not trivial since Plot skills are markdown instructions interpreted by an agent, not programs. But the sprint SKILL.md could include a "machine-readable output" template that the agent follows when it detects it is running in pipe mode or when a `--json` flag is present.

### 5.2 Next Suggested Action

**Current state:** The loop prompt hardcodes the priority order (fix PRs, build next task, self-review). The agent must re-derive what to do from the full sprint state.

**Improvement:** The sprint status output should include a `next_action` field:

```
### Suggested Next Action
> Fix 3 unresolved comments on PR #36, then self-review PR #37.
```

This would allow the ralph loop prompt to be shorter and more adaptive — it could reference the sprint file's suggestion rather than encoding all priority logic in the static prompt.

### 5.3 First-Class Review Tracking

**Current state:** Review state is implicit. The agent must query `gh api` to discover which PRs have unresolved comments. There is no sprint-level view of review status.

**Improvement:** Add a `## Review Status` section to sprint files (or a separate tracking file) that records:

```markdown
## Review Status

| PR | Last Reviewed | Findings | Status |
|----|--------------|----------|--------|
| #35 | 2026-02-28 iter 1 | 6 comments | Fixed (iter 1) |
| #36 | 2026-02-28 iter 2 | 7 comments | Fixed (iter 3) |
| #37 | 2026-02-28 iter 3 | 7 comments | Fixed (iter 4) |
| #38 | 2026-02-28 iter 5 | 5 comments | Fixed (iter 7) |
```

This section would be updated by the agent after each review and fix cycle, and would serve as the reviewed-PR tracking that section 4.1 proposes at the script level — but integrated into the sprint file itself.

### 5.4 Distinguish Plan-Only PRs from Implementation PRs

**Current state:** The sprint file lists items as `- [ ] [slug] description` or `- [ ] description`. There is no distinction between PRs that contain implementation code and PRs that contain only plan documents.

**Improvement:** Add a type annotation to sprint items:

```markdown
- [ ] [worktree-isolation] Plan: Worktree isolation for parallel sprints
- [ ] [file-uploads] Impl: File upload support with streaming
```

Or more practically, add guidance to the sprint SKILL.md that plan PRs (those on `idea/` branches or containing only `docs/plans/` changes) should be reviewed with different criteria than implementation PRs. The self-review step in the ralph loop prompt could then skip or lighten review of plan-only PRs.

### 5.5 Sprint File as Priority Source

**Current state:** The ralph loop prompt hardcodes the priority order (MoSCoW tiers). The sprint file contains MoSCoW sections, but the agent must read and interpret them.

**Improvement:** The prompt should explicitly reference the sprint file as the priority source:

```
Read docs/sprints/active/$SLUG.md for task priorities.
Work on Must Have items first, then Should Have, then Could Have.
Skip any items marked [x] (already done) or moved to ### Deferred.
```

This is already implicit in the current prompt's "pick the highest-priority unblocked task" instruction, but making the sprint file the explicit authority (rather than the prompt's own priority logic) would allow the human to reprioritize by editing the sprint file directly — which is a lighter-weight alternative to the instruction injection mechanism proposed in section 4.4.

---

## 6. Grading

### Design: A-

The core insight — stateless iterations with git as shared memory — is elegant and correct. The promise signal protocol is minimal and well-designed. The separation of review and fix across iterations is a genuine contribution to agentic workflow design. The deduction is for the lack of any cross-iteration state mechanism. Even a simple "reviewed PRs" file would have prevented the re-review problem observed in the live run.

### Implementation: B+

Clean, readable bash. Good use of EXIT traps, proper error handling with `|| true` guards, shellcheck compliance. The JSON extraction with `jq` fallbacks handles malformed output gracefully. The deductions are for: (a) the Ctrl+C propagation issue, which is a known limitation of the command substitution approach; (b) no timeout or watchdog; (c) no cost tracking despite using `--output-format json` which likely provides the data.

### Robustness: B-

The script handles the happy path well and degrades gracefully on errors (EXIT trap, ntfy notification, wrap-up session). But it lacks defensive measures against the unhappy paths that matter most for a long-running automation tool: hung processes (no timeout), stalled network (no retry with backoff), interrupted sessions (Ctrl+C issue), and runaway costs (no budget limit). The EXITING_NORMALLY flag pattern is clever but adds complexity that a simpler approach (explicit exit calls with cleanup as a function, not a trap) might avoid.

### Integration with Plot: B

The script uses `/plot-sprint` for status and dispatches work according to the sprint file's MoSCoW priorities. The wrap-up session uses `/bye` for documentation. But the integration is shallow — the script and the skills do not share a structured data format, the prompt duplicates priority logic that already exists in the sprint file, and there is no feedback loop from the sprint skill back to the script (e.g., "these PRs have already been reviewed" or "this is the next suggested action"). The script and the skills are aware of each other but do not deeply collaborate.

### Overall: B+

A strong first implementation that validates a genuinely useful execution model. The ralph loop solves a real problem (compaction in long-running sessions) with a simple, maintainable approach. The live run data confirms it works in practice: 8+ productive iterations with no crashes, correct signal handling, and a useful wrap-up session. The weaknesses are addressable without redesigning the core architecture — they are missing features, not design flaws.

The most impactful improvements would be (in priority order):

1. **Reviewed-PR tracking** (section 4.1) — eliminates the most visible waste from the live run.
2. **Per-iteration timeout** (section 4.2) — essential for unattended operation.
3. **Mid-run instruction injection** (section 4.4) — enables human steering without restart.
4. **Machine-readable sprint status** (section 5.1) — deepens the Plot integration.
5. **Ctrl+C fix** (section 4.6) — quality-of-life for the operator.

---

## Appendix: File References

| File | Purpose |
|------|---------|
| `skills/plot-sprint/ralph-sprint.sh` | The loop script (212 lines) |
| `skills/plot-sprint/ralph-sprint-monitor.log` | Manual observations from the live run |
| `skills/plot-sprint/SKILL.md` | Sprint lifecycle skill |
| `skills/plot-sprint/README.md` | Development documentation |
| `skills/plot-sprint/install.sh` | Symlink installer |
| `skills/plot/SKILL.md` | Plot dispatcher (references sprints) |
| `skills/plot/MANIFESTO.md` | Design principles |
| `docs/plans/2026-02-11-plot-sprint-support.md` | Sprint support plan |
