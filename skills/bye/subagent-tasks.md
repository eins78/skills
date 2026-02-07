# Subagent Tasks

Task templates for delegating session analysis to subagents. Use these when the conversation is too long to analyze directly. Called from [SKILL.md](./SKILL.md) step 1.

## Analyze Session File

Use when you need to determine session type from raw session data.

```
Use Task tool with subagent_type=Explore:
prompt: |
  Analyze the session file to determine session type.

  Session file location:
  ~/.claude/projects/{project-path-encoded}/{session-id}.jsonl

  To find the project path:
  PROJECT_PATH=$(pwd | tr '/' '-' | sed 's/^-//')
  ls ~/.claude/projects/$PROJECT_PATH/

  Steps:
  1. Find the session file using the project path above
  2. Read first 10 lines of the JSONL file
  3. Look for these patterns:
     - "Context: This summary will be shown" → compaction
     - "Plan mode is active" → plan mode
     - "isSidechain": true → subagent (skip)
  4. If compaction found, extract the embedded conversation:
     - Format is "User: [text]" and "Agent: [text]" separated by "---"
     - List what work was discussed
  5. Return:
     - session_type: "compaction" | "plan_mode" | "plan_execution" | "normal" | "subagent"
     - work_summary: 2-3 sentences of what happened
     - files_mentioned: list of file paths discussed
```

## Detect Plan Execution Session

Use when you suspect context was auto-cleared after plan approval.

```
Use Task tool with subagent_type=Explore:
prompt: |
  Determine if this is a plan EXECUTION session (auto-cleared after plan approval).

  Steps:
  1. List ~/.claude/plans/ - find files modified in the last 2 hours
  2. Check first few messages of current conversation:
     - Do they reference executing/implementing a plan?
     - Is there implementation work without prior planning discussion?
  3. If plan file found, read it and extract:
     - Verification checklist items
     - Files to be modified
  4. Return:
     - is_plan_execution: true/false
     - plan_path: path to plan file (if found)
     - plan_summary: what was planned
     - verification_items: checklist from plan
```

## Find Plan File

Use when you need to locate and read the relevant plan.

```
Use Task tool with subagent_type=Explore:
prompt: |
  Find and read the plan file for this session.

  Steps:
  1. List ~/.claude/plans/ directory, sorted by modification time
  2. Check if any plan slug is mentioned in the conversation
  3. Look for system messages referencing plan files
  4. If found, read the plan file
  5. Return:
     - plan_path: full path to plan file
     - plan_summary: what the plan intends to accomplish
     - files_to_modify: list from the plan
     - was_executed: compare plan items to git diff to see what was done
```

## Parse Compaction Transcript

Use when you need to extract work from a compaction summary.

```
Use Task tool with subagent_type=Explore:
prompt: |
  Parse the compaction summary transcript.

  The compaction message contains conversation in this format:
  User: [their message]
  Agent: [claude's response]
  ---
  User: [next message]
  ...

  Steps:
  1. Extract each User/Agent exchange
  2. Identify: files created, files modified, decisions made
  3. Return:
     - exchanges_count: number of User/Agent pairs
     - files_created: list of new files
     - files_modified: list of changed files
     - key_decisions: list of choices made
```
