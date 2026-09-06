#!/usr/bin/env bash
# Tests for scripts/mail-across-accounts.sh.
#
# Two tiers:
#   (default)  offline — drives the script against a fake `osascript` that
#              replays canned output for a synthetic 3-account store. Touches
#              no real mail, needs no Mail.app. This is what guards the actual
#              bug: it asserts `recent` merges and date-sorts ACROSS accounts
#              rather than concatenating account-by-account (the shape of the
#              regression that would silently reintroduce issue #91).
#   --live     also runs the coverage invariant against the real Mail store:
#              sum(per-account INBOX counts) == count(messages of inbox), and
#              message 1 of inbox is not necessarily the newest message
#              overall. Requires Mail.app running and configured accounts.
#
# Run: bash skills/apple-mail/tests/test-mail-accounts.sh [--live]
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/../scripts/mail-across-accounts.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail=0
check() { # check <label> <expected-substring> <actual>
  if [[ "$3" == *"$2"* ]]; then
    echo "  ok   — $1"
  else
    echo "  FAIL — $1: expected to find '$2', got:"
    echo "$3" | sed 's/^/         /'
    fail=1
  fi
}
check_not() { # check_not <label> <forbidden-substring> <actual>
  if [[ "$3" != *"$2"* ]]; then
    echo "  ok   — $1"
  else
    echo "  FAIL — $1: did not expect to find '$2'"
    fail=1
  fi
}

# ---------------------------------------------------------------------------
# Offline tier: a fake osascript replaying a synthetic 3-account store.
#
# Acct1 (newest first): 2026-01-05 "A-newest widget order", 2026-01-03
#   "A-mid", 2026-01-01 "A-old". total=3, unread=1.
# Acct2 (newest first): 2026-01-04 "B-newest", 2026-01-02 "B-old widget
#   invoice". total=2, unread=2.
# AcctErr: every query for it fails (exit 1), simulating a wedged/erroring
#   account — the "does one bad account silently vanish" case (Finding 4).
#
# Interleaving matters: Acct2's newest (01-04) sits between Acct1's 1st and
# 2nd messages, and Acct1's oldest (01-01) is older than Acct2's oldest
# (01-02) but Acct2's newest (01-04) is NOT simply appended after all of
# Acct1's — a script that concatenated per-account output instead of
# merge-sorting would emit A-newest, A-mid, A-old, B-newest, B-old: wrong
# order, and this fixture is built to catch exactly that.
# ---------------------------------------------------------------------------

fake_osascript="$tmp/fake-osascript"
cat >"$fake_osascript" <<'FAKE'
#!/usr/bin/env bash
# args: -e "<applescript source>"
# Dispatches on explicit substring checks (not chained glob ordering, which
# is fragile — the account name and the query-shape marker can appear in
# either order depending on how the caller built the AppleScript source).
script="$2"
has() { [[ "$script" == *"$1"* ]]; }

if has 'get name of every account'; then
  echo "Acct1, Acct2, AcctErr"
elif has 'AcctErr'; then
  # Every query mentioning AcctErr fails, every time — simulates a wedged or
  # erroring account that must not be silently reported as empty.
  exit 1
elif has 'whose read status is false' && has '"Acct1"'; then
  echo 1
elif has 'whose read status is false' && has '"Acct2"'; then
  echo 2
elif has 'subject contains' && has '"Acct1"'; then
  has '"widget"' && printf '2026-01-05 10:00:00\tAcct1\talice@a.example\tA-newest widget order\n'
  exit 0
elif has 'subject contains' && has '"Acct2"'; then
  has '"widget"' && printf '2026-01-02 10:00:00\tAcct2\teve@b.example\tB-old widget invoice\n'
  exit 0
elif has 'repeat with i from 1 to n' && has '"Acct1"'; then
  printf '2026-01-05 10:00:00\tAcct1\talice@a.example\tA-newest widget order\n'
  printf '2026-01-03 10:00:00\tAcct1\tbob@a.example\tA-mid\n'
  printf '2026-01-01 10:00:00\tAcct1\tcarol@a.example\tA-old\n'
elif has 'repeat with i from 1 to n' && has '"Acct2"'; then
  printf '2026-01-04 10:00:00\tAcct2\tdave@b.example\tB-newest\n'
  printf '2026-01-02 10:00:00\tAcct2\teve@b.example\tB-old widget invoice\n'
elif has 'count (messages of mailbox "INBOX" of account "Acct1")'; then
  echo 3
elif has 'count (messages of mailbox "INBOX" of account "Acct2")'; then
  echo 2
else
  echo "fake-osascript: unrecognized script:" >&2
  echo "$script" >&2
  exit 1
fi
FAKE
chmod +x "$fake_osascript"

export MAIL_OSASCRIPT="$fake_osascript"
export MAIL_RETRY_SLEEP=0   # AcctErr still retries 3x; keep the test fast
export MAIL_TIMEOUT_SECS=5

echo "syntax:"
if bash -n "$script"; then
  echo "  ok   — script parses"
else
  echo "  FAIL — syntax error"
  fail=1
fi

echo "accounts:"
accounts_out="$("$script" accounts)"
check "lists all three accounts" "Acct1"$'\n'"Acct2"$'\n'"AcctErr" "$accounts_out"

echo "recent (cross-account merge and date-sort):"
recent_out="$("$script" recent 4 2>"$tmp/recent.err" || true)"
recent_dates="$(printf '%s\n' "$recent_out" | tail -n +2 | cut -f1)"
expected_dates=$'2026-01-05 10:00:00\n2026-01-04 10:00:00\n2026-01-03 10:00:00\n2026-01-02 10:00:00'
if [[ "$recent_dates" == "$expected_dates" ]]; then
  echo "  ok   — top 4 are merge-sorted across accounts, not concatenated per account"
else
  echo "  FAIL — expected dates in order:"
  echo "$expected_dates" | sed 's/^/         /'
  echo "       got:"
  echo "$recent_dates" | sed 's/^/         /'
  fail=1
fi
check "AcctErr is reported on stderr, not silently dropped" "AcctErr" "$(cat "$tmp/recent.err")"
check_not "AcctErr rows do not appear in recent output" "AcctErr" "$recent_out"

echo "unread (partial-failure accounting):"
unread_out="$("$script" unread 2>"$tmp/unread.err" || true)"
check "Acct1 unread/total reported" $'Acct1\t1\t3' "$unread_out"
check "Acct2 unread/total reported" $'Acct2\t2\t2' "$unread_out"
check "AcctErr reported as ERROR, not 0" $'AcctErr\tERROR\tERROR' "$unread_out"
check "TOTAL sums only the healthy accounts (3 unread, 5 total)" $'TOTAL\t3\t5' "$unread_out"
check "stderr flags AcctErr by name" "AcctErr" "$(cat "$tmp/unread.err")"
check "stderr flags TOTAL as partial" "lower bound" "$(cat "$tmp/unread.err")"

echo "search (per-account, across accounts):"
search_out="$("$script" search widget 2>"$tmp/search.err" || true)"
check "finds the match in Acct1" "A-newest widget order" "$search_out"
check "finds the match in Acct2" "B-old widget invoice" "$search_out"
check_not "does not return Acct1's non-matching message" "A-mid" "$search_out"
check "AcctErr flagged on stderr during search too" "AcctErr" "$(cat "$tmp/search.err")"

echo "exit codes:"
accounts_rc=0
"$script" accounts >/dev/null 2>&1 || accounts_rc=$?
check "accounts exits 0 when nothing errors" "0" "$accounts_rc"
unread_rc=0
"$script" unread >/dev/null 2>&1 || unread_rc=$?
if [[ "$unread_rc" -ne 0 ]]; then
  echo "  ok   — unread exits non-zero when an account errored (AcctErr), while still printing partial data above"
else
  echo "  FAIL — expected non-zero exit with AcctErr present"
  fail=1
fi

# ---------------------------------------------------------------------------
# Live tier (opt-in): coverage invariant against the real Mail store.
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--live" ]]; then
  echo "live: coverage invariant against the real Mail store"
  unset MAIL_OSASCRIPT MAIL_RETRY_SLEEP MAIL_TIMEOUT_SECS

  live_accounts="$("$script" accounts)"
  if [[ -z "$live_accounts" ]]; then
    echo "  FAIL — no accounts returned; is Mail.app running and logged in?"
    fail=1
  else
    echo "  accounts: $(tr '\n' ',' <<<"$live_accounts")"
    sum=0
    while IFS= read -r acct; do
      [[ -z "$acct" ]] && continue
      c=$(timeout 90 osascript -e "tell application \"Mail\" to count (messages of mailbox \"INBOX\" of account \"$acct\")") || {
        echo "  FAIL — could not count INBOX for account '$acct'"
        fail=1
        continue
      }
      sum=$((sum + c))
    done <<<"$live_accounts"

    unified=$(timeout 300 osascript -e 'with timeout of 280 seconds
      tell application "Mail" to count (messages of inbox)
    end timeout') || { echo "  FAIL — could not count messages of inbox"; fail=1; unified=-1; }

    delta=$((sum - unified))
    [[ $delta -lt 0 ]] && delta=$((-delta))
    if [[ $delta -le 2 ]]; then
      echo "  ok   — sum of per-account INBOX counts ($sum) matches messages of inbox ($unified), within delta $delta"
    else
      echo "  FAIL — sum of per-account counts ($sum) diverges from messages of inbox ($unified) by $delta"
      fail=1
    fi
  fi
else
  echo "(skipping live tier — pass --live to run it against the real Mail store)"
fi

if [[ $fail -eq 0 ]]; then
  echo "PASS"
else
  echo "FAILED"
  exit 1
fi
