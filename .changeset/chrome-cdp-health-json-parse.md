---
"@eins78/agent-skills": patch
---

**`chrome-browser`** — fixes `chrome-cdp-health`, `chrome-cdp-tabs` and `launch-chrome-cdp` reporting failure on hosts whose `python3` is a version-manager shim.

Two independent bugs made all three helpers exit non-zero while CDP was in fact healthy:

- **Availability was tested with `command -v python3`.** An asdf or pyenv shim is present on `PATH` but exits non-zero when no version is selected, so the scripts took the python3 branch and it failed. Availability is now probed by running `python3 -c ''`.
- **The `chrome-cdp-health` fallback pattern had no whitespace tolerance.** Chrome pretty-prints `"webSocketDebuggerUrl": "ws://…"` with a space after the colon, so `grep -o '"webSocketDebuggerUrl":"[^"]*"'` matched nothing. `grep` then exited 1, and under `set -euo pipefail` that aborted the assignment — the script exited 1 ("CDP unreachable") instead of reaching its own "no webSocketDebuggerUrl in payload" branch. Extraction now uses `sed -n`, which tolerates the whitespace and exits 0 on no match.

`launch-chrome-cdp` and `chrome-cdp-tabs` piped into `python3 -m json.tool` for pretty-printing; both now fall back to raw output instead of failing the script.

Verified on a host with a broken asdf `python3` shim: all three helpers returned 0 with CDP live, and on a host with a working `python3` behaviour is unchanged.

<!--
bumps:
  skills:
    chrome-browser: patch
-->
