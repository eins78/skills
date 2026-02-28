# Analysis Report: The "Scrum Master" Orchestration Pattern via `claude rc`

**Date:** 2026-02-28
**Subject:** Using `claude rc` as a persistent monitoring session for sprint oversight from mobile
**Sessions analyzed:**
- `1a431c45-0022-41f9-96fb-6e3f1e9b035a` (qubert rc worktree, primary)
- `e6136a61-26f4-41fc-b151-66202b9a67c6` (continuation)

---

## 1. The Scrum Master Pattern

### What It Is

A persistent `claude rc` session that acts as a **read-only oversight layer** over parallel execution sessions. The user instructs the session to adopt a monitoring persona:

> "in this session i want you to act as a kind of scrum master. re-check the status regularly and give status updates, review the work done (was the process done correctly, is everything in its right state, do the commits and branch state match that, and does the implementation address everything from the feature). when agent work is done, guide me through reviewing the work, decisions, answering question, and so on."

Claude confirmed the role: "I'll act as scrum master for this sprint -- monitoring progress, reviewing work quality, and guiding you through decisions."

The pattern establishes a **separation of concerns** that mirrors Plot's existing role taxonomy:

| Plot Role | Execution Sessions | Scrum Master Session |
|-----------|-------------------|---------------------|
| Decision maker | -- | Human (via phone) |
| Process facilitator | -- | Claude (monitoring) |
| Implementer | Claude (coding) | -- |

The scrum master session does NOT do any implementation work. It reads git state, checks PR status, parses sprint files, and reports back to the human. This maps directly to the `/plot` dispatcher role but in a persistent, conversational form rather than a one-shot command.

### Why It Is Valuable

1. **Async oversight of automated work.** The human can walk away from the laptop while a ralph loop or parallel CLI sessions do implementation work. The monitoring session provides a way to check back in without sitting at the terminal.

2. **Phone-accessible.** `claude rc` exposes the session via a queue that the Claude mobile app can connect to. Status checks become as simple as texting "status update?" from a phone.

3. **Low-bandwidth human input.** The human does not need to read code diffs or parse git logs. The scrum master synthesizes that into a summary. The human's job is reduced to decisions: approve, reject, redirect, prioritize.

4. **Natural language interface to git state.** Instead of running multiple `gh` commands and reading JSON output, the human asks plain-language questions and gets structured answers.

### How It Differs from the Ralph Loop

The ralph loop (or parallel CLI sessions) **does work** -- it implements features, writes code, creates PRs, runs tests. The scrum master session **monitors work and coordinates the human**. They are complementary:

- Ralph loop: autonomous execution within defined boundaries
- Scrum master: awareness, status reporting, review guidance, decision support

The scrum master never creates branches, writes code, or pushes commits. It reads from the same git state that execution sessions write to. Git is the shared communication channel.

---

## 2. What Worked

### The Concept of Separate Monitoring

Having a dedicated session whose sole purpose is oversight is architecturally sound. It avoids the problem of a working session losing context about the broader sprint when it is deep in implementation details. The monitoring session maintains the "big picture" view that individual execution sessions cannot.

### Natural Language Status Queries

The interaction pattern was minimal and effective. The user sent short messages from a phone:
- "status update?"
- "note i switched to running a ralph loop. what the sprint status?"

These are exactly the kind of low-friction queries that make mobile oversight viable. No need to remember command syntax, branch names, or PR numbers.

### Git as the Shared Communication Channel

This is the most important architectural insight. The execution sessions and the monitoring session never communicate directly. They share state through git:

- Execution sessions push commits, create PRs, update plan files
- The monitoring session reads branches, PR states, sprint files, commit history

This is consistent with Plot's Principle 1 ("Git is the database") and extends it naturally into multi-session coordination. No custom IPC, no message passing, no shared files outside of git.

### Leveraging Existing Plot Infrastructure

The "steal-features" sprint on the qubert project had 8 plan files with MoSCoW prioritization -- exactly the kind of structured data that a monitoring session can parse and report on. The sprint file format (`docs/sprints/`) and the active plan index (`docs/plans/active/`) give the scrum master everything it needs to generate status reports without custom tooling.

### Phone as Command Center

The ability to check sprint status while away from the computer is genuinely useful for the solo developer / AI team composition that Plot targets. The human's decision-making role does not require a full development environment -- it requires information and the ability to say yes/no/redirect.

---

## 3. What Did Not Work (Technical Issues)

### `claude rc` Beta Stability

The user described "technical issues (beta feature)" that affected reliability. `claude rc` is experimental, and the queue-based communication system had friction:

- **Latency.** Messages are enqueued from the phone and dequeued by Claude. This is inherently asynchronous with unpredictable delays, unlike the near-real-time feel of a local CLI session.
- **Session continuity.** The user needed a second session (`e6136a61`), suggesting the first session may have ended or become unresponsive.
- **Queue-operation overhead.** Messages carry `"userType": "external"` marking and go through a queue infrastructure that adds mechanical complexity compared to direct terminal interaction.

### Context Compaction and Loss

Long-running monitoring sessions are particularly vulnerable to context compaction. A scrum master needs to remember:
- The full sprint scope (all 8 plan files in this case)
- Previous status reports (to detect changes)
- Decisions made earlier in the conversation
- Which execution sessions are running and what they are doing

When compaction removes earlier messages, the scrum master loses this accumulated state. It cannot reliably report "this changed since last check" if it has lost the record of the last check.

### No Structured Communication Protocol

There is no formal protocol for execution sessions to signal the monitoring session. The scrum master must actively poll git state. It has no way of knowing:
- When an execution session starts or finishes a task
- Whether a task failed or was abandoned
- If the human redirected an execution session mid-task

Everything must be inferred from git state, which introduces a detection lag. A PR that was force-pushed, a branch that was reset, or work that was done but not yet committed is invisible to the monitor.

### Plan Mode Limitations

The session ran in `"permissionMode": "plan"` mode, which restricts it to read-only operations. This is actually correct for a monitoring role -- the scrum master should NOT take actions. However, it means the session cannot even run helper scripts (`plot-pr-state.sh`, `plot-impl-status.sh`) without permission escalation, which adds friction to what should be frictionless status checks.

### No Persistent State Between Reconnections

If the `claude rc` session drops and the user reconnects, the new session starts without the accumulated context of the previous one. There is no mechanism to persist:
- Sprint state snapshots
- Previous status reports
- Decision history
- Execution session tracking

Each reconnection requires rebuilding context from scratch, which is expensive in tokens and time.

### Mid-Sprint Mode Switch

The user switched from parallel CLI sessions to a ralph loop mid-sprint ("note i switched to running a ralph loop"). The scrum master had to adapt its mental model of the execution environment. This worked because the user explicitly communicated the change, but it highlights the fragility: the monitoring session has no way to detect changes in the execution topology on its own.

---

## 4. Proposed Formalization

### A `plot-monitor` Skill

Formalize the scrum master pattern into a dedicated skill that can be activated in any persistent session (rc or otherwise). The skill would define:

**Inputs (all read from git, no custom state):**
- Active sprint file (`docs/sprints/active/*.md`)
- Active plan index (`docs/plans/active/`)
- Open PRs (`gh pr list`)
- Recent commits on main and active branches
- CI status on open PRs
- `monitor.log` if present (ralph loop output)

**Outputs (structured for phone consumption):**

```
## Sprint: steal-features
3 days remaining | Must: 5/8 | Should: 1/2 | Could: 0/1

### Completed Since Last Check
- [x] browser-automation -- PR #42 merged, CI green
- [x] channel-pairing -- PR #45 merged, CI green

### In Progress
- [ ] mcp-server-support -- PR #47 draft, 12 commits ahead of main
- [ ] seatbelt-sandbox -- PR #48 draft, CI failing (test timeout)

### Not Started
- [ ] file-upload-handling
- [ ] rate-limit-handling

### Needs Attention
- PR #48 CI failure: test timeout in sandbox tests (failing 2h)
- worktree-isolation has no PR yet (branch exists, no commits)

### Suggested Actions
1. Review PR #42 (browser-automation) -- ready for merge
2. Investigate CI failure on PR #48
3. Decide: start file-upload-handling or focus on fixing #48?
```

**Key design decisions for the skill:**

1. **Stateless by design.** Each status check rebuilds from git. No reliance on conversation history. This makes it robust against compaction and reconnection.

2. **Diff-aware when possible.** If the session has previous status in context, highlight changes. If not (post-compaction), generate a full report without diff markers. Degrade gracefully.

3. **Action-oriented.** Every status report ends with suggested next actions for the human, numbered for easy phone response ("reply 1 to review PR #42").

4. **Sprint-file-first.** The sprint file is the primary data source. Everything else (PRs, branches, CI) is supplementary evidence correlated against the sprint's MoSCoW items.

### Integration with Ralph Loop

The ralph loop automation produces artifacts that the monitoring session can consume:

| Ralph Artifact | Monitor Use |
|---------------|-------------|
| `monitor.log` | Execution trace -- what was attempted, what succeeded/failed |
| ntfy notifications | Event stream -- task starts, completions, errors |
| Git commits | State changes -- new code, updated files |
| PR state changes | Progress markers -- draft to ready, CI results |

The monitor skill should define how to read `monitor.log` if present:

```bash
# Last N entries from monitor log
tail -50 monitor.log 2>/dev/null
```

And how to check ntfy history if configured:

```bash
# Recent notifications for the project topic
curl -s "https://ntfy.sh/<topic>/json?since=1h" 2>/dev/null
```

### Phone-Optimized Output

The skill should define output formatting rules optimized for small screens and quick scanning:

1. **Short lines.** No line longer than 60 characters where possible.
2. **Status indicators at line start.** Checkmarks, crosses, and dashes as the first character for instant visual parsing.
3. **Numbers for actions.** Every suggested action gets a number. The human can reply with just "1" or "2, 3" to select.
4. **Progressive detail.** The first 5 lines tell you if everything is fine. Details follow only if there are issues or the human asks.
5. **Time-relative language.** "2h ago", "3 days remaining", not timestamps.

---

## 5. Recommended Architecture

### Component Diagram

```
+-------------------+         +-------------------+
|   Ralph Loop      |         |  Parallel CLI     |
|   (execution)     |         |  Sessions         |
|                   |         |  (execution)      |
|  - implements     |         |  - implements     |
|  - commits        |         |  - commits        |
|  - creates PRs    |         |  - creates PRs    |
+--------+----------+         +--------+----------+
         |                             |
         |        writes to            |
         +----------+------------------+
                    |
                    v
         +----------+----------+
         |       Git State     |
         |                     |
         |  - branches         |
         |  - commits          |
         |  - PRs (via forge)  |
         |  - sprint files     |
         |  - plan files       |
         |  - monitor.log      |
         +----------+----------+
                    |
                    |      reads from
         +----------+----------+
         |   Scrum Master      |
         |   (claude rc)       |
         |                     |
         |  - reads git state  |
         |  - generates status |
         |  - suggests actions |
         |  - guides reviews   |
         +----------+----------+
                    |
                    |   rc queue (enqueue/dequeue)
                    v
         +----------+----------+
         |   Human (phone)     |
         |                     |
         |  - reads status     |
         |  - makes decisions  |
         |  - approves/rejects |
         |  - redirects work   |
         +---------------------+

         +---------------------+
         |   ntfy              |
         |   (notification     |
         |    bridge)          |
         |                     |
         |  - push alerts for  |
         |    CI failures      |
         |  - task completions |
         |  - blocking issues  |
         +---------------------+
```

### Data Flow

1. **Execution to Git:** Ralph loop or parallel sessions push commits, create/update PRs, update sprint checkboxes.
2. **Git to Monitor:** The scrum master session reads branches, PRs, sprint files, commit history.
3. **Monitor to Human:** Status reports are sent through the rc queue to the phone.
4. **Human to Monitor:** The human sends queries and decisions through the rc queue.
5. **Human to Execution (indirect):** The human's decisions are communicated back to execution sessions by:
   - Updating sprint files on main (the scrum master could do this if given write permission)
   - Sending ntfy notifications to execution session topics
   - Closing/reopening PRs
   - Adding PR comments

### The Notification Bridge

ntfy serves as an out-of-band notification channel that does not depend on the rc queue:

- **Ralph loop to human:** "Task X completed", "CI failed on PR #Y", "Blocked: need decision on Z"
- **Human to ralph loop:** Not currently supported, but could be added (ntfy supports publish from phone)
- **Scrum master to human:** Could send urgent alerts via ntfy when the rc session is disconnected

This provides redundancy: if the rc session drops, the human still gets notifications about critical events.

---

## 6. What Belongs in CLAUDE.md vs Skills

### Skills (Reusable, Project-Agnostic)

| Component | Belongs In | Rationale |
|-----------|-----------|-----------|
| Status report format | `plot-monitor/SKILL.md` | Reusable across projects |
| Sprint file parsing | `plot-sprint/SKILL.md` (existing) | Already project-agnostic |
| PR review checklist | `plot-monitor/SKILL.md` | Reusable review criteria |
| Phone output formatting | `plot-monitor/SKILL.md` | Consistent UX |
| Git state reading logic | `plot/SKILL.md` (existing dispatcher) | Already defined |
| `monitor.log` parsing | `plot-monitor/SKILL.md` | Convention, not configuration |
| ntfy integration pattern | `plot-monitor/SKILL.md` | Generic notification bridge |

### CLAUDE.md (Project-Specific)

| Component | Belongs In | Rationale |
|-----------|-----------|-----------|
| Sprint-specific configuration | Project `CLAUDE.md` | Sprint names, dates, goals |
| Team composition | Project `CLAUDE.md` | Who is human, who is agent |
| Review criteria | Project `CLAUDE.md` | What "done" means for this project |
| ntfy topic name | Project `CLAUDE.md` | Project-specific channel |
| `monitor.log` location | Project `CLAUDE.md` | Project-specific path |
| CI/CD specifics | Project `CLAUDE.md` | Which CI system, what checks matter |
| Ralph loop configuration | Project `CLAUDE.md` | Loop parameters, worktree setup |

### Example Plot Config Extension

```markdown
## Plot Config
- **Project board:** qubert (#3)
- **Branch prefixes:** idea/, feature/, bug/, docs/, infra/
- **Plan directory:** docs/plans/
- **Active index:** docs/plans/active/
- **Delivered index:** docs/plans/delivered/
- **Sprint directory:** docs/sprints/

## Plot Monitor Config
- **ntfy topic:** qubert-sprint
- **Monitor log:** monitor.log
- **Check interval:** on-demand (human triggers via rc)
- **Execution mode:** ralph loop
```

---

## 7. Grading

### Concept: A-

The idea of separating monitoring from execution is architecturally sound and well-motivated. It maps cleanly to Plot's existing role taxonomy (decision maker / facilitator / implementer). The use of git as a shared communication channel avoids introducing new infrastructure. The phone-as-command-center idea is practical for the solo developer + AI agents workflow.

Deducted from A+ because the pattern does not yet address the "what happens when the monitor needs to take action" question -- for example, if the scrum master detects a CI failure, it currently cannot notify the execution session or create a bug branch. It can only report to the human and hope they act.

### Execution: C+

The experiment demonstrated the concept works in principle, but `claude rc` beta limitations significantly hampered the experience. Session instability, context compaction, lack of persistent state, and queue latency all degraded what should be a smooth interaction. The user needed two sessions to cover a single sprint, and the technical friction was noticeable enough to be called out explicitly.

The C+ rather than lower reflects that the core interaction pattern (short phone queries, structured status responses, decision guidance) did function when the session was stable. The problems are in the infrastructure, not the design.

### Integration with Plot: B

The scrum master pattern naturally extends Plot's existing infrastructure. Sprint files provide the status data. The dispatcher's decision tree provides the logic. The PR state scripts provide the mechanical data gathering. No new file formats or conventions were needed.

Deducted from A because:
- There is no formal `plot-monitor` skill yet -- the monitoring logic was ad-hoc
- The sprint file format does not include fields for tracking execution session state (which sessions are running, what they are working on)
- The monitor has no way to write back to git (update sprint checkboxes, add notes) without breaking the read-only principle
- Integration with ralph loop artifacts (`monitor.log`, ntfy) is not documented anywhere

### Readiness for Production: D+

This is firmly in the "promising experiment" category, not production-ready:

- **`claude rc` itself is beta** and the primary transport mechanism is unreliable
- **No skill definition exists** -- the monitoring behavior was conversational, not codified
- **No persistence mechanism** -- every session start requires rebuilding context
- **No automated testing** -- the pattern was tried once with one sprint
- **No failure modes documented** -- what happens when the monitor misreads state, when git is stale, when PRs are in unexpected states
- **No integration with ralph loop** beyond reading the same git state

The D+ rather than lower reflects that the underlying components (Plot skills, git state reading, sprint files) are well-established and the gap is primarily in formalization and infrastructure maturity, not in fundamental design.

### Summary Table

| Dimension | Grade | Key Factor |
|-----------|-------|------------|
| Concept | A- | Architecturally sound, maps to existing roles |
| Execution | C+ | Beta infrastructure hampered a good design |
| Integration with Plot | B | Natural extension, needs formalization |
| Readiness for Production | D+ | Promising experiment, needs skill + stable transport |

---

## 8. Recommended Next Steps

### Short Term (formalization)

1. **Write a `plot-monitor` skill** that codifies the monitoring logic: what to read, how to format status, what actions to suggest. This can be used in any session type, not just `claude rc`.

2. **Add a status snapshot section to sprint files.** When the monitor generates a status report, optionally append it to the sprint file's `## Notes` section with a timestamp. This provides persistence across session drops.

3. **Document the ralph loop integration points.** Where is `monitor.log`? What format? What ntfy topics? This belongs in Plot Monitor Config.

### Medium Term (infrastructure)

4. **Wait for `claude rc` to stabilize.** The transport layer is the weakest link. When it becomes reliable, the pattern becomes significantly more useful.

5. **Explore alternative transports.** Could the scrum master be a webhook-triggered script instead of a persistent session? A cron job that generates status and posts to ntfy? This would decouple the monitoring from session stability.

6. **Add write-back capability.** Let the monitor update sprint checkboxes, add notes, and create summary commits. This requires careful guardrails (the monitor should only update status metadata, never implementation files).

### Long Term (evolution)

7. **Event-driven monitoring.** Instead of polling, trigger status checks from git hooks or CI events. A push-based model would eliminate the detection lag.

8. **Multi-sprint support.** As projects run overlapping sprints, the monitor needs to track multiple contexts and report on the right one based on the human's query.

9. **Decision logging.** When the human makes a decision via the scrum master ("approve PR #42", "defer rate-limit-handling"), log it in the sprint file with a timestamp. This creates an audit trail of human decisions that is currently missing.
