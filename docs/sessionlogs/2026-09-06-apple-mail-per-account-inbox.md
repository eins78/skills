# apple-mail: `inbox` is unified in membership, not order (issue #91, PR #92)

**Date:** 2026-09-06 (closed out 2026-09-11)
**Source:** Claude Code (Opus 5)
**Session:** Dispatched from a separate `home-workspace` session with a written brief; one plan-mode round, one mid-plan scope decision from Max, then implementation in a single pass.
One compaction · ~241k output tokens.

## Summary

Fixed issue #91: `SKILL.md` claimed `messages of inbox` returns "a unified inbox
across all accounts" and every recipe queried it directly. The brief that
kicked this off, and the issue itself, attributed the resulting bug (a morning
briefing missing ~40 unread Gmail messages) to `inbox` returning **only the
iCloud account**. That mechanism does not reproduce. This log is mostly about
what does.

## 1. The brief's diagnosis was wrong, and it was checkable in one command

Issue #91 measured that `messages of inbox` "missed" ~2318 Gmail messages and
concluded it returns only iCloud. The brief said to verify before fixing.
Measured 2026-09-06: `count (messages of inbox)` = 3353. Sum of five
per-account INBOX counts = 3354 (one message arrived between the two
measurements — expected drift, not disagreement). Unread matched exactly:
2193 = 491 (mfa) + 152 (iCloud) + 1550 (Gmail). Membership is unified. The
"only iCloud" theory is falsified by one arithmetic comparison that the
original report never ran.

The real defect is ordering, found by probing
`name of account of mailbox of message N of inbox` at several indices:

```
1.    iCloud     | 2026-09-03 14:33     <- "most recent" per the old SKILL.md
255.  iCloud     | 2025-05-30 11:13
256.  1 (Gmail)  | 2026-09-06 12:00     <- the actually-newest message
3353. mfa        | 2025-01-29 20:49
```

`inbox` is grouped contiguously by account, newest-first only *within* a
segment, in an order (iCloud, Gmail, mfa) unrelated to `get name of every
account`'s order (OFFICE, mfa, iCloud, Gmail, KTE). The boundary lands at
exactly message 255/256 — iCloud's own count. `message 1 of inbox` reads the
newest message of whichever account happens to sort first, which explains the
"only iCloud" symptom precisely: the briefing was reading positionally, and
every position it checked happened to still be inside the iCloud segment.

Two people wrote plausible mechanisms for the same real symptom and both were
wrong — the reporter (issue #91) and the brief author, who is the same person
(Max, via a separate session). Neither is a criticism; the distinguishing
measurement (a sum) is exactly the kind of check that's easy to skip when a
theory already explains the visible symptom. Max had already posted a
correction comment on #91 with this same membership/ordering finding before I
finished measuring it independently — the credit for catching this belongs
there; this session's comment supplements it with the fuller tables.

## 2. The brief also had two of its own small facts wrong, worth naming plainly

- **SKILL.md:311** ("Messages are indexed newest-first — message 1 = most
  recent") is false across accounts and is the more directly load-bearing of
  the two bad lines in the old Notes section. Neither the issue nor the brief
  flagged it; it surfaced only from directly probing message order.
- **`tests/test-emlx.sh` has 11 checks, not 12.** The brief said "12/12
  passing" — counted and ran it: 11 `check` calls, all passing. Small, but the
  kind of thing worth stating plainly rather than silently matching the wrong
  number in a PR description.

## 3. `osascript` renders large integers in scientific notation — kills the epoch-diff idiom

Wanted a UTC sortable date string per message for the new helper script. The
standard AppleScript trick is `(date sent of msg) - (date "1/1/1970")` for a
Unix epoch integer. Every variant — `as integer`, `round`, `as string` — came
back as `1.788707086E+9` from `osascript -e`. Confirmed it's not a coercion
bug: `osascript -e 'return 1788707086'` alone also prints in scientific
notation. This is `osascript`'s own stdout formatting for large numbers,
independent of the AppleScript-side type.

Avoided the whole problem rather than working around the formatting: pull
`year`, `month`, `day`, and `time of date` (seconds since midnight, always
< 100000) separately — all small integers, none of which trigger the
scientific-notation threshold — and assemble a zero-padded
`YYYY-MM-DD HH:MM:SS` string entirely inside AppleScript. That also sidesteps
timezone conversion (the string is local wall-clock time, not UTC — documented
as a deliberate simplification in the script's header, since sorting is what
matters here, not cross-machine comparability the way `emlx.py`'s archive
dates need).

## 4. A combined AppleScript call cost more than either half measured alone

First draft of `cmd_unread` issued one `tell` block computing both the total
count and the unread count per account, at the then-default 60s shell
timeout. Against the ~2400-message Gmail INBOX it failed all 3 retries. Timed
the combined call directly: **~103s**. Measured separately: unread-only ~40s
(light load) up to ~90s (heavier load) in different runs; total-only up to
~90s. Combining doesn't sum linearly, but it's still more than either half's
own worst case, and 60s wasn't enough margin.

Fixed two ways, not one: raised the default `MAIL_TIMEOUT_SECS` to 120 (with
the measurement in a script comment, not just a round number), and split the
combined query into two separate `mail_query` calls so a slow or failing half
doesn't sink the other — the total can still succeed and print even if the
unread count times out, and vice versa. Re-ran the full 5-account `unread`
live: all five accounts succeeded, 1m34s wall time, clean exit 0.

**Half of that rationale did not survive the week.** Max's follow-up commit
`811d23a` (his own session, landed on this branch before the merge) replaced
the unread query with the `unread count` *property* instead of
`count (... whose read status is false)`. The property is served from Mail's
index rather than walking the mailbox: 0.11s against the unified inbox,
versus no answer in 90s and a wedged Mail.app for the `whose` form. So the
cost measured here was largely self-inflicted — this session optimised the
call *pattern* (split the combined query, raise the timeout) without
questioning whether the query itself was the right AppleScript. The total
still enumerates, so the 120s budget stays for that half.

That commit also carves the one exception into this log's central rule:
`unread count of inbox` is fine, because the ban on `inbox` is about
enumeration and ordering and a property read does neither. Per-account
iteration is still required for the messages themselves.

## 5. `trap ... RETURN` inside a bash function is not function-scoped

`cmd_recent` used a temp file and `trap 'rm -f "$tmp"' RETURN` for cleanup.
First live run: correct data printed, then `line 195: tmp: unbound variable`
under `set -u`. The RETURN trap doesn't unregister when the function that set
it returns — it stays armed for the *shell*, and fires again the next time
*any* function returns (here, `main`), by which point `$tmp` is out of scope.
Replaced with an explicit `rm -f "$tmp"` at the end of the function instead of
relying on the trap. Documented inline as a gotcha since it's non-obvious and
would resurface for anyone extending the script with the "obvious" pattern.

## Design choice, and why

Max cut a scope question I was about to ask before I finished asking it: I'd
found that `whose` clauses over `inbox` *do* span every account correctly
(just slowly, per Finding 1), and asked whether to convert only the
positional recipes or all eight. Max's answer — "can we just ignore the
unified inbox if its slow?" — collapsed that into a cleaner rule than either
option I'd offered: drop `inbox` from every recipe rather than explaining the
membership-vs-ordering nuance in each one. `SKILL.md` gained one warning
section instead of eight inline caveats; the detailed measurements live in
`README.md` and the PR body as evidence, not as instructions callers need to
re-derive each time.

`scripts/mail-across-accounts.sh` (accounts/unread/recent/search) plus one
inline per-account AppleScript pattern per recipe, matching the plan's
helper-vs-inline rejection reasoning: inline-only repeats the merge-sort
hazard in eight places (exactly the failure that produced issue #91 — a
caller inventing the workaround itself); script-only would leave arbitrary
one-off queries without a documented per-account pattern to copy.

## Verification

- `tests/test-emlx.sh` — untouched, still 11/11.
- `tests/test-mail-accounts.sh` (new) — offline tier (fake `osascript`, no
  Mail.app needed) 19/19; `--live` tier adds the coverage invariant
  (sum of per-account INBOX counts == `count (messages of inbox)`) — 3369 ==
  3369, delta 0, against the real store.
- `mail-across-accounts.sh recent 10` live: today's Gmail message (12:00 PM)
  ranks first, correctly interleaved with an `mfa` message from 13:42 — the
  literal acceptance test for the bug, passing.
- `pnpm test`'s underlying command (`skills add . --list`) run via the main
  checkout's already-installed `node_modules/.bin/skills`, cwd in the
  worktree — exit 0, `apple-mail` parses. **Did not run `pnpm install` in
  this worktree**: its `postinstall` (`skills add . --global …`) copies the
  worktree's skills into `~/.claude/skills` unmerged, which is exactly the
  side effect the brief said to avoid (the deployed copy is out of scope,
  "do not edit it yourself"). Same avoidance as the 2026-08-07 archive-search
  session, for the same reason.

## Out of scope, flagged per the brief

`~/.claude/skills/apple-mail` is a copy, not a symlink, and nothing refreshes
it — it keeps the bug until re-synced by hand after this PR merges. Noted in
the PR body; not touched here. Now that #92 is merged this is actionable —
moved to Pending below.

## Pending

- [x] Max: merge or reject — merged 2026-09-11 as `414b166`, issue #91 closed
      as completed. Not self-merged, per the brief.
- [ ] **Max: `apple-mail` is double-bumped to 1.3.0 in release PR #88.** This
      session set `metadata.version` to `1.2.0` by hand *and* left
      `apple-mail: minor` in the changeset's `bumps:` block, so
      `bump-skill-versions.sh` applied a second minor on top. CLAUDE.md says
      not to edit those versions manually; the brief said to bump it, and this
      session did both rather than either. Fix is yours to pick: revert
      `SKILL.md` to `1.1.0` on main and let #88 regenerate 1.2.0, or accept
      1.3.0 and skip 1.2.0. Not touched here — it is a skill file on main with
      a live release PR attached.
- [ ] Max: re-sync the deployed `~/.claude/skills/apple-mail` copy by hand. It
      is a copy, not a symlink, and still carries the bug.
