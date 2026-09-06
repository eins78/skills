#!/usr/bin/env bash
# Iterate every Mail.app account's INBOX and aggregate, because `messages of
# inbox` is unified in *membership* but grouped by account in *order* — it is
# not date-sorted, and a `whose` clause over it can exceed AppleScript's 120s
# event timeout on a large store. See SKILL.md, "Do not query `inbox` directly".
#
# Usage:
#   mail-across-accounts.sh accounts
#   mail-across-accounts.sh unread
#   mail-across-accounts.sh recent [N]        # newest N across all accounts (default 10)
#   mail-across-accounts.sh search TERM [N]   # subject match, N per account (default 20)
#
# Sequential by design: Mail's AppleScript bridge serializes, and issuing
# per-account calls in parallel causes most of them to time out. Each call
# gets its own shell-level timeout + retries (osascript's internal `with
# timeout of` does not kill a wedged process).
#
# Dates are the account's local wall-clock time (not UTC) — AppleScript's
# date-minus-date epoch idiom hits an osascript quirk where large integers
# print in scientific notation (`1.788707086E+9`), so this builds a
# zero-padded "YYYY-MM-DD HH:MM:SS" string from date components instead. It
# is fully sortable and readable; it is just not UTC.
#
# MAIL_OSASCRIPT overrides the osascript binary (tests inject a fake).
# MAIL_TIMEOUT_SECS overrides the per-call shell timeout (default 120).
# 120s is not conservative padding: measured against a ~2400-message IMAP
# INBOX, a single `count ... whose read status is false` took up to ~90s and
# combining it with a plain `count` in one call took ~103s. A large IMAP
# account can be this slow on its own, independent of the `inbox`-grouping
# bug this script exists to route around — budget for it, and let a real
# hang still get caught by the retry loop below.
#
# Read only: never sends, deletes, or modifies mail.

set -euo pipefail

OSASCRIPT="${MAIL_OSASCRIPT:-osascript}"
TIMEOUT_SECS="${MAIL_TIMEOUT_SECS:-120}"
RETRY_SLEEP="${MAIL_RETRY_SLEEP:-2}"
MAX_ATTEMPTS="${MAIL_MAX_ATTEMPTS:-3}"

# mail_query <applescript-source>
# Runs osascript with a shell timeout, retrying up to MAX_ATTEMPTS times.
# Prints the result on success; returns non-zero after exhausting retries.
mail_query() {
  local script="$1" attempt result
  for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
    if result=$(timeout "$TIMEOUT_SECS" "$OSASCRIPT" -e "$script" 2>&1); then
      printf '%s' "$result"
      return 0
    fi
    sleep "$RETRY_SLEEP"
  done
  return 1
}

# Emit one account name per line. osascript joins an AppleScript list as
# ", "-separated text, so this assumes account names contain no comma.
list_accounts() {
  local raw
  if ! raw=$(mail_query 'tell application "Mail" to get name of every account'); then
    echo "ERROR: could not list Mail accounts" >&2
    return 1
  fi
  local IFS=','
  read -ra parts <<<"$raw"
  local p
  for p in "${parts[@]}"; do
    p="${p#" "}"
    [[ -n "$p" ]] && printf '%s\n' "$p"
  done
}

# AppleScript snippet shared by every per-account query: given a message
# reference bound to variable `m`, builds a local-time sortable date string
# into `dateStr`. Inlined into each query below (osascript -e takes one script,
# no separate library file).
read -r -d '' DATE_HANDLER <<'EOF' || true
on pad2(n)
  set s to n as string
  if (length of s) < 2 then set s to "0" & s
  return s
end pad2
EOF

cmd_accounts() {
  list_accounts
}

cmd_unread() {
  printf 'account\tunread\ttotal\n'
  local acct total_unread=0 total_all=0 had_error=0
  while IFS= read -r acct; do
    local unread total
    # total and unread are two separate calls, not one combined query: on a
    # large IMAP account each one alone can take close to TIMEOUT_SECS, so
    # combining them risked losing both to one slow round trip. Split, a
    # slow or failing half is reported on its own and doesn't sink the other.
    if ! unread=$(mail_query "tell application \"Mail\" to count (messages of mailbox \"INBOX\" of account \"$acct\" whose read status is false)"); then
      echo "ERROR: account '$acct' unread count failed after $MAX_ATTEMPTS attempts — NOT counted as 0" >&2
      had_error=1
      unread=""
    fi
    if ! total=$(mail_query "tell application \"Mail\" to count (messages of mailbox \"INBOX\" of account \"$acct\")"); then
      echo "ERROR: account '$acct' total count failed after $MAX_ATTEMPTS attempts — NOT counted as 0" >&2
      had_error=1
      total=""
    fi
    printf '%s\t%s\t%s\n' "$acct" "${unread:-ERROR}" "${total:-ERROR}"
    [[ -n "$unread" ]] && total_unread=$((total_unread + unread))
    [[ -n "$total" ]] && total_all=$((total_all + total))
  done < <(list_accounts)
  printf 'TOTAL\t%s\t%s\n' "$total_unread" "$total_all"
  if [[ "$had_error" -ne 0 ]]; then
    echo "NOTE: TOTAL excludes the account(s) above that errored — it is a lower bound, not a full count." >&2
  fi
  [[ "$had_error" -eq 0 ]]
}

# recent_for_account <account> <n> — TSV rows: date, account, sender, subject
recent_for_account() {
  local acct="$1" n="$2"
  mail_query "$DATE_HANDLER

tell application \"Mail\"
  set outText to \"\"
  set msgCount to count (messages of mailbox \"INBOX\" of account \"$acct\")
  set n to $n
  if msgCount < n then set n to msgCount
  repeat with i from 1 to n
    set m to message i of mailbox \"INBOX\" of account \"$acct\"
    set d to date sent of m
    set t to time of d
    set hh to t div 3600
    set mm to (t mod 3600) div 60
    set ss to t mod 60
    set dateStr to (year of d as string) & \"-\" & my pad2(month of d as integer) & \"-\" & my pad2(day of d) & \" \" & my pad2(hh) & \":\" & my pad2(mm) & \":\" & my pad2(ss)
    set outText to outText & dateStr & tab & \"$acct\" & tab & (sender of m) & tab & (subject of m) & linefeed
  end repeat
  return outText
end tell"
}

cmd_recent() {
  local n="${1:-10}"
  local acct had_error=0
  local tmp
  tmp=$(mktemp)
  # No RETURN trap here: it stays registered shell-wide (it does not scope to
  # this function alone) and would fire again — against an already-unset
  # $tmp, under `set -u` — the next time ANY function returns. Clean up
  # explicitly instead.
  while IFS= read -r acct; do
    local out
    if ! out=$(recent_for_account "$acct" "$n"); then
      echo "ERROR: account '$acct' failed after $MAX_ATTEMPTS attempts — skipped" >&2
      had_error=1
      continue
    fi
    [[ -n "$out" ]] && printf '%s\n' "$out" >>"$tmp"
  done < <(list_accounts)
  printf 'date\taccount\tsender\tsubject\n'
  # Newest first across all accounts; date string sorts lexicographically
  # because it is zero-padded YYYY-MM-DD HH:MM:SS.
  sort -r "$tmp" | head -n "$n"
  rm -f "$tmp"
  [[ "$had_error" -eq 0 ]]
}

# search_for_account <account> <term> <n> — TSV rows: date, account, sender, subject
search_for_account() {
  local acct="$1" term="$2" n="$3"
  mail_query "$DATE_HANDLER

tell application \"Mail\"
  set outText to \"\"
  set foundMsgs to (messages of mailbox \"INBOX\" of account \"$acct\" whose subject contains \"$term\")
  set foundCount to count foundMsgs
  set n to $n
  if foundCount < n then set n to foundCount
  repeat with i from 1 to n
    set m to item i of foundMsgs
    set d to date sent of m
    set t to time of d
    set hh to t div 3600
    set mm to (t mod 3600) div 60
    set ss to t mod 60
    set dateStr to (year of d as string) & \"-\" & my pad2(month of d as integer) & \"-\" & my pad2(day of d) & \" \" & my pad2(hh) & \":\" & my pad2(mm) & \":\" & my pad2(ss)
    set outText to outText & dateStr & tab & \"$acct\" & tab & (sender of m) & tab & (subject of m) & linefeed
  end repeat
  return outText
end tell"
}

cmd_search() {
  local term="${1:?usage: mail-across-accounts.sh search TERM [N]}" n="${2:-20}"
  local acct had_error=0
  printf 'date\taccount\tsender\tsubject\n'
  while IFS= read -r acct; do
    local out
    if ! out=$(search_for_account "$acct" "$term" "$n"); then
      echo "ERROR: account '$acct' failed after $MAX_ATTEMPTS attempts — skipped" >&2
      had_error=1
      continue
    fi
    [[ -n "$out" ]] && printf '%s' "$out"
  done < <(list_accounts)
  [[ "$had_error" -eq 0 ]]
}

main() {
  local cmd="${1:-}"
  [[ $# -gt 0 ]] && shift || true
  case "$cmd" in
    accounts) cmd_accounts "$@" ;;
    unread) cmd_unread "$@" ;;
    recent) cmd_recent "$@" ;;
    search) cmd_search "$@" ;;
    *)
      echo "Usage: $(basename "$0") {accounts|unread|recent [N]|search TERM [N]}" >&2
      exit 2
      ;;
  esac
}

main "$@"
