# ntfy Notification Tuning

**Date:** 2026-02-17
**Source:** Claude Code
**Session:** Reconstructed from 1 compaction(s)

## Summary
Diagnosed and fixed duplicate ntfy notifications (Stop + idle_prompt firing in sequence), suppressed idle_prompt as redundant with Stop, and lowered the HIDIdleTime threshold from 60s to 1s for near-instant notifications when away from keyboard.

## Key Accomplishments
- Diagnosed root cause: both Stop and idle_prompt hooks pass guard rails (HIDIdleTime + debounce) when user is away, producing double notifications
- Suppressed `idle_prompt` notifications in hook script (4-line guard clause at lines 19-22)
- Lowered HIDIdleTime threshold from 60s to 1s — notifications fire unless user is actively typing
- Researched idle_prompt vs Stop redundancy: documented edge cases where idle_prompt is the only signal (e.g., idle after interruption)
- Updated docs with notification changes

## Changes Made
- Modified: `~/.claude/hooks/notify-stop.sh` (outside this repo — idle_prompt suppression + threshold change)
- Modified: `docs/claude-code-ntfy-notifications.md` (committed in compacted portion)

## Decisions
- Suppress idle_prompt entirely rather than using longer debounce: simpler, covers 95%+ of cases
- 1s idle threshold instead of 60s: "notify unless typing" semantics match user intent
- Keep the suppression easy to revert (4-line block, clearly commented)

## Next Steps
- [ ] Test idle_prompt suppression in practice — revert lines 19-22 of `notify-stop.sh` if important notifications are missed

## Repository State
- Committed: 56fbd9a, ac37885 (from compacted portion)
- Branch: claude/bye-session-reconstruction-stats
