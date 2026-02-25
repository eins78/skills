# bye: Add Reconstruction Stats to Session Summary

**Date:** 2026-02-17
**Source:** Claude Code
## Summary
Added optional session reconstruction stats (compaction count and token usage) to the bye skill's final summary and sessionlog templates. Data is collected during the existing subagent pass over the JSONL session file at zero extra cost.

## Key Accomplishments
- Extended subagent task template to return `compaction_count`, `total_input_tokens`, `total_output_tokens`
- Added conditional `**Session:**` line to Final Summary Template (only shown when compactions > 0)
- Added matching `**Session:**` metadata to sessionlog template
- Validated all 8 skills pass `pnpm test`
- Opened PR #10

## Changes Made
- Modified: `skills/bye/subagent-tasks.md`
- Modified: `skills/bye/SKILL.md`
- Modified: `skills/bye/sessionlog-template.md`

## Decisions
- Token counting piggybacks on existing subagent JSONL pass: no new file reads needed
- Report `input_tokens` and `output_tokens` (not cache tokens): keeps the summary line simple
- Conditional display: omit the line entirely for sessions without compactions

## Next Steps
- [ ] Merge PR #10
- [ ] Test `/bye` on a session with compactions to verify the line renders correctly
- [ ] Test `/bye` on a short session to verify the line is omitted

## Repository State
- Committed: 1cce425 - bye: show reconstruction stats in session summary
- Branch: claude/bye-session-reconstruction-stats
- PR: https://github.com/eins78/skills/pull/10
