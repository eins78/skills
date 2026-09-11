# @eins78/agent-skills

## 4.4.0

### Minor Changes

- [#92](https://github.com/eins78/agent-skills/pull/92) [`57afa23`](https://github.com/eins78/agent-skills/commit/57afa234fbd7f6e5e7d0c44bb263e2bb8183bd08) - **`apple-mail`** — recipes now iterate accounts instead of querying unqualified `inbox`.

  `messages of inbox` is unified in membership but grouped by account in order, not
  date-sorted, so a positional read like `message 1 of inbox` silently returns one
  account's mail and a `whose` clause over it can exceed AppleScript's event timeout.
  Every recipe now queries a named account's mailbox, backed by a new
  `mail-across-accounts.sh` helper for the common cross-account jobs.

  Unread counts also switch from `count (messages … whose read status is false)` to
  the `unread count` property. The `whose` form walks every message: measured on a
  five-account store it returned nothing in 90s and left Mail.app wedged, while the
  property answered in 0.11s with an identical result. One carve-out follows from
  this — `unread count of inbox` is safe to call unqualified, because the ordering
  problem above only affects reads that enumerate.

### Patch Changes

- [#87](https://github.com/eins78/agent-skills/pull/87) [`a50b460`](https://github.com/eins78/agent-skills/commit/a50b460641d5f01b7f111335b3bad9136f47dfc4) - **`apple-mail`** — the description now covers on-disk archive search, not just AppleScript.

  The skill has documented two access paths since 1.1.0, but its description named only Mail.app and AppleScript, so it under-triggered on requests to find old mail in a large or multi-account archive. It now names both paths and the attachment commands, and states that the on-disk path works with Mail.app closed.

- [#94](https://github.com/eins78/agent-skills/pull/94) [`9d77979`](https://github.com/eins78/agent-skills/commit/9d77979f95c0b3aed807425b5005b688e072b1b7) - **`chrome-browser`** — browser automation no longer breaks when the display sleeps.

  Chrome is now launched with `--disable-backgrounding-occluded-windows`, `--disable-renderer-backgrounding` and `--disable-background-timer-throttling`, in both the launchd plist and `launch-chrome-cdp.sh`. Without them, an asleep display or a covered window made every click time out on "visible, enabled and stable" — measured at 0 animation frames in 2 s, now 80. Troubleshooting gained an entry for the symptom, which looks like a selector bug and is not one.

  Existing installs need to re-run `install-cft.sh` (or reload the plist) to pick up the new flags.

- [#93](https://github.com/eins78/agent-skills/pull/93) [`2811dd6`](https://github.com/eins78/agent-skills/commit/2811dd6a28473283627a90136e937ad58f7bce9a) - **`chrome-browser`** — fixes `chrome-cdp-health`, `chrome-cdp-tabs` and `launch-chrome-cdp` reporting failure on hosts whose `python3` is a version-manager shim.

  Two independent bugs made all three helpers exit non-zero while CDP was in fact healthy:

  - **Availability was tested with `command -v python3`.** An asdf or pyenv shim is present on `PATH` but exits non-zero when no version is selected, so the scripts took the python3 branch and it failed. Availability is now probed by running `python3 -c ''`.
  - **The `chrome-cdp-health` fallback pattern had no whitespace tolerance.** Chrome pretty-prints `"webSocketDebuggerUrl": "ws://…"` with a space after the colon, so `grep -o '"webSocketDebuggerUrl":"[^"]*"'` matched nothing. `grep` then exited 1, and under `set -euo pipefail` that aborted the assignment — the script exited 1 ("CDP unreachable") instead of reaching its own "no webSocketDebuggerUrl in payload" branch. Extraction now uses `sed -n`, which tolerates the whitespace and exits 0 on no match.

  `launch-chrome-cdp` and `chrome-cdp-tabs` piped into `python3 -m json.tool` for pretty-printing; both now fall back to raw output instead of failing the script.

  Verified on a host with a broken asdf `python3` shim: all three helpers returned 0 with CDP live, and on a host with a working `python3` behaviour is unchanged.

## 4.3.1

### Patch Changes

- [#53](https://github.com/eins78/agent-skills/pull/53) [`c0b9eaa`](https://github.com/eins78/agent-skills/commit/c0b9eaa61ef0d469460ab8e26426c6006d71c256) - **`chrome-browser`** — documents the conflict with the official `claude-plugins-official/playwright` plugin.

  The official `playwright` plugin from Anthropic's marketplace registers `npx @playwright/mcp@latest` without `--cdp-endpoint`, which causes Playwright to spawn its own bundled Chromium instead of attaching to the CfT instance set up by this skill — defeating the persistent-session purpose entirely. Added a callout in INSTALL.md step 3 with two resolution paths (disable the plugin via `~/.claude/settings.json`, or patch the plugin's bundled `.mcp.json`) plus a verification command.

## 4.3.0

### Minor Changes

- [#77](https://github.com/eins78/agent-skills/pull/77) [`a18adb2`](https://github.com/eins78/agent-skills/commit/a18adb2b99798c08230440c90b0d9b97616b05e9) - **`dossier`** — a dossier has two genres, and the skill only knew one. Adds the research/decision genre split.

  Preflight now asks whether the reader wants to learn the state of a topic and conclude for themselves, or to be handed a ranked recommendation. The answer selects the template and switches EVALUATE and SYNTHESIZE, and the research genre keeps its assessment at the end — so a reader can take the survey and skip the opinion.

- [#77](https://github.com/eins78/agent-skills/pull/77) [`9a01ae1`](https://github.com/eins78/agent-skills/commit/9a01ae1ecc0087fbcd5a0315793e710504e8ee75) - **`dossier`** — adds an `## Insights` section for the interesting-but-not-load-bearing material research turns up.

  Three to six items per dossier, teased from the body so they get read, and held to the same evidence standard as findings. If removing an item would change a finding, it is not an insight — it is a buried finding, and it belongs in the body.

- [#77](https://github.com/eins78/agent-skills/pull/77) [`20d677e`](https://github.com/eins78/agent-skills/commit/20d677e63ee310a86dfc5a5fe8b2eedd762f1a76) - **`dossier`** — adds a REVIEW stage between SYNTHESIZE and DELIVER, run by three fresh-context subagents and enforced by a commit gate.

  The review checklist already existed as an instruction, and was ignorable enough that its own author shipped a dossier violating it about two hours after writing it. Reviewers now run without the research conversation, because a defect survives its author precisely when the author half-remembers the sources.

- [#78](https://github.com/eins78/agent-skills/pull/78) [`6376f89`](https://github.com/eins78/agent-skills/commit/6376f8901d0d504c634db56c8bf36d443b1febac) - **`pandoc`** — `md2kindle-epub.sh` no longer emits EPUBs without a title.

  `dc:title` is required EPUB metadata, but `--title` was optional and its absence produced a spec-invalid book silently. The script now derives a title from the first H1 of the first input, falling back to the output filename.

  **`send-to-kindle`** — adds delivery verification and documents the `E999` failure mode. Kindle ingress validates asynchronously, so every signal available at send time proves only that the mail left; the one real signal is no bounce after a few minutes.

- [#81](https://github.com/eins78/agent-skills/pull/81) [`6bc2e39`](https://github.com/eins78/agent-skills/commit/6bc2e39a9cb300f582f6f7d34d23f29c09d2115f) - **`apple-notes`** — a note's body is not its contents. Adds attachment listing, and the rule that stops a failed search becoming a false conclusion.

  Attachments are separate rows in the Notes database, so a body read cannot see them — which makes it possible to search a note, find nothing, and conclude the document was never there. New `scripts/list-attachments.sh` lists every attachment with its type, title and identifying text, and `--paths` resolves the file on disk.

- [#80](https://github.com/eins78/agent-skills/pull/80) [`c914ab7`](https://github.com/eins78/agent-skills/commit/c914ab7084c46b99f46798816c1ab72d7e45def5) - **`paprika-recipes`** — new skill for reading and creating recipes in Paprika Recipe Manager 3 on macOS.

  The point of it is turning **any** text source into a real recipe — a page the web clipper failed on, prose, a PDF, a photo of a cookbook page. The clipper handles URLs well and nothing else, and until now typing it in by hand was the only alternative.

## 4.2.0

### Minor Changes

- [#74](https://github.com/eins78/agent-skills/pull/74) [`46077b4`](https://github.com/eins78/agent-skills/commit/46077b4ece0c43c59b693ac8ded86e72c42b5f29) - **`apple-mail`** — documents archive search over `.emlx`, the preferred path for old mail or many accounts. Closes [#69](https://github.com/eins78/agent-skills/issues/69).

  A `ripgrep` recipe over `~/Library/Mail` with `scripts/emlx.py` for triage, because the store is not Spotlight-indexed: `mdfind` returns 0 for every query, which reads as "no such mail" but means "no index". Read-only throughout — nothing added sends, deletes or modifies mail.

- [#70](https://github.com/eins78/agent-skills/pull/70) [`5a066fb`](https://github.com/eins78/agent-skills/commit/5a066fbdbd8da3a23fe5acbfd8251c7ceb7e0dc3) - **`apple-mail`** — documents attachment extraction and two `tell`-block gotchas.

  Adds `List attachments` and `Save attachments` commands, plus the `POSIX file` failure inside a `tell application "Mail"` block (`-1728`) and the set of ordinary variable names that collide with Mail's own terminology.

## 4.1.0

### Minor Changes

- [#71](https://github.com/eins78/agent-skills/pull/71) [`b2f1969`](https://github.com/eins78/agent-skills/commit/b2f1969eed4754384bd1f05e662ca3063910991b) - **`send-to-kindle`** — new skill codifying the Kindle/EPUB pipeline, with the `pandoc` script that produces the EPUB.

  Delivery routes and their 2026 status, per-device addressing, size ceilings, and the approved-sender allowlist that drops mail silently. `pandoc` gains `scripts/md2kindle-epub.sh` (markdown → e-reader EPUB with a real TOC and chapter splitting); `dossier` gains a cross-reference in §DELIVER.

## 4.0.0

### Major Changes

- [#65](https://github.com/eins78/agent-skills/pull/65) [`38fb377`](https://github.com/eins78/agent-skills/commit/38fb3779c3d14e8e2d363ec8d5a98bc4d2f2a1f1) - **`text-to-speech`** — **breaking:** the L1 narrative rewrite no longer runs automatically. The driving agent must dispatch an isolated rewrite subagent.

  A nested `claude --print` inherits the calling session's output style and project `CLAUDE.md`, and can leak meta-commentary into the prose — an `★ Insight` block was observed rendered into audio. A bare invocation with no existing `narrative.txt` now fails loudly instead of falling back silently; headless callers opt in with `--allow-inline-llm-rewrite`.

### Minor Changes

- [#67](https://github.com/eins78/agent-skills/pull/67) [`75fc5a6`](https://github.com/eins78/agent-skills/commit/75fc5a6c4bf8e60059c878802e289e9b7387af10) - **`dossier`** — captures cited sources for offline verification.

  GATHER now archives each source as its URL is collected, into a `sources/` folder with an `index.md` mapping every file back to its citation ID, URL, access date and hash. Needs only `curl` and `awk`; `monolith` and `pandoc` improve quality when present. Save Page Now stays opt-in, because it publishes the author's reading list to a permanent public archive.

- [#68](https://github.com/eins78/agent-skills/pull/68) [`a41bd9c`](https://github.com/eins78/agent-skills/commit/a41bd9cacd8124fe4a267a270ae79855cab73c9c) - **`bye`** — removed. [quatico-solutions/agent-skills](https://github.com/quatico-solutions/agent-skills) is now its single maintained home.

  It lived in both repos under the same version label but with diverged content, so a fix to one copy silently left the other wrong.

## 3.2.0

### Minor Changes

- [#62](https://github.com/eins78/agent-skills/pull/62) [`8008cbc`](https://github.com/eins78/agent-skills/commit/8008cbc53eff19bbebf7147ad2a30a86dfadf893) - **`ai-council-review`** — new skill: convene ~4 frontier models through OpenRouter for independent parallel reviews of a PR, plan or files.

  Zero-runtime-dependency Node scripts with per-model retry and timeout handling, live-pricing cost estimates, and a two-tier budget gate that refuses outright above the cap — nothing is sent in either case. Requires `OPENROUTER_API_KEY`, and SKILL.md carries an explicit consent note because reviewed content leaves the machine for third-party providers.

- [#62](https://github.com/eins78/agent-skills/pull/62) [`ab95045`](https://github.com/eins78/agent-skills/commit/ab950457075eab57c477a9470356adc8a9ec9dd8) - **`ai-council-review`** — anonymises member identities during synthesis and adds correlated-error guardrails.

  Reviews, clusters and the manifest carry shuffled `member-A`… labels, with the label-to-model mapping read only at report time, to counter model brand and self-preference bias. Unanimity no longer grants a verification exemption.

## 3.1.0

### Minor Changes

- [#55](https://github.com/eins78/agent-skills/pull/55) [`8796c22`](https://github.com/eins78/agent-skills/commit/8796c229b25c687ee13571c9bc3d36a33abaafd4) - **`chrome-browser`** — hardens tool selection and cold-start behaviour, and ships recovery helpers on PATH.

  Names the lookalike browser MCPs as forbidden, so a cold agent does not silently switch to them when Playwright errors transiently, and adds an activation preflight — the audit found real failures cluster in the first 30–60 seconds after skill load. **Upgraders from v1.3 must unload and remove the old launchd plist first**; see INSTALL.md §2.

- [#54](https://github.com/eins78/agent-skills/pull/54) [`93d9673`](https://github.com/eins78/agent-skills/commit/93d967323973f840c4cb9bdbf0cb559b4496896a) - **`pandoc`** — adds a compact A4 print recipe and `scripts/md2pdf-print.sh`.

  Pipes markdown through pandoc into headless Chrome `--print-to-pdf`, replacing Marked 2's PDF export on macOS 26.x, which clips 5–10pt off the left edge in every style. Pandoc has no Chrome `--pdf-engine`, so a shell wrapper is the canonical pattern.

## 3.0.0

### Major Changes

- [#59](https://github.com/eins78/agent-skills/pull/59) [`1f82c67`](https://github.com/eins78/agent-skills/commit/1f82c6721d906cecf23b05f03d37552eb0a79318) - **`tracer-bullets`** and **`typescript-strict-patterns`** — removed; both moved to their proper homes.

  `tracer-bullets` → [plot-pm/plot](https://github.com/plot-pm/plot), which is where its companion commands live; `typescript-strict-patterns` → [quatico-solutions/agent-skills](https://github.com/quatico-solutions/agent-skills), the company-wide pool. Breaking for anyone installing them from this marketplace — reinstall from the new homes.

## 2.7.1

### Patch Changes

- [#57](https://github.com/eins78/agent-skills/pull/57) [`6267f10`](https://github.com/eins78/agent-skills/commit/6267f10c4d9a04648de95fc58614c04e1e6f4529) - **`dossier`** — collapses unpublished dossiers to a single current version ([#56](https://github.com/eins78/agent-skills/issues/56)).

  Mid-session corrections used to accumulate in the body as "Revision note" blocks, `rev. <date>` suffixes and "first draft framed X" phrasing. That edit history is noise to any reader who was not in the authoring session; it belongs in commit messages.

## 2.7.0

### Minor Changes

- [#51](https://github.com/eins78/agent-skills/pull/51) [`b48aaf1`](https://github.com/eins78/agent-skills/commit/b48aaf1fd42f32d1cde402b7083f4d1ac0a51b53) - **`chrome-browser`** — surfaces tool-selection rules and page-handling gotchas, and installs a stable `launch-chrome-cdp` symlink.

  Covers `innerText` rather than `textContent` for SPAs, batch crawling inside `browser_run_code`, the absent `require('fs')`, Cloudflare patience and rate-limit guidance, plus an expanded "running but hung" troubleshooting checklist.

## 2.6.0

### Minor Changes

- [#49](https://github.com/eins78/agent-skills/pull/49) [`89c204b`](https://github.com/eins78/agent-skills/commit/89c204bfa7c99850a6282adb63dc28962a4c9c3c) - **`text-to-speech`** and **`private-podcast-feed`** — two new skills extracted from the tts-shootout experiment.

  `text-to-speech` turns a text document into an MP3, currently backed by Kokoro-82M behind a swappable backend. `private-podcast-feed` builds a private RSS+MP3 feed for self-subscription, with `itunes:block`, token-prefixed URLs and ID3 chapters.

## 2.5.0

### Minor Changes

- [#43](https://github.com/eins78/agent-skills/pull/43) [`5a76700`](https://github.com/eins78/agent-skills/commit/5a7670028b0fb0e097cb36156d7b7a4e556e9711) - **`ballot`** — new skill for decisions that happen async, plus a preflight gate and clickable citations for **`dossier`**.

  `ballot` produces one decision file per reviewer, for decisions reviewed over chat, on a PR, or after the session ends. `dossier` gains a step-0 preflight that checks a research request is specific and unambiguous before starting, and reference-link citations that click through in GitHub, Obsidian, Bitbucket and Confluence.

- [#45](https://github.com/eins78/agent-skills/pull/45) [`bf78f1b`](https://github.com/eins78/agent-skills/commit/bf78f1b088aad959a9d74b4b4017a27b5681fcb3) - **`dossier`** and **`ballot`** — add an `evals/` harness for the reviewer checklists.

  16 scorers, 10 mechanical and 6 LLM-as-judge, cost-gated behind `EVAL_MODE=full`. Runs locally via `pnpm evals`; no CI wiring.

- [#48](https://github.com/eins78/agent-skills/pull/48) [`7134d48`](https://github.com/eins78/agent-skills/commit/7134d48be633e0c390f3c4af5dca1d1ef4582a61) - **`pdf-zine`** — new skill wrapping the [`pdf2zine`](https://github.com/eins78/pdf2zine) CLI, which turns a PDF into a fold-and-print booklet.

  A4 sheets, double-sided short-edge flip, folded to A5. Written discovery-first so agents reach for it instead of hand-rolling Ghostscript or `pdfjam` imposition.

## 2.4.1

### Patch Changes

- [`ec71cb1`](https://github.com/eins78/agent-skills/commit/ec71cb1ee54f5d1a8966fd665ebb93625aa06916) - **`dossier`** — adds commercial-bias flagging to source evaluation.

  Flag a source's commercial incentive explicitly in the output rather than silently down-weighting it. From a [`@young.mete` Threads post](https://www.threads.com/@young.mete/post/DXPjx_JDuMR).

## 2.4.0

### Minor Changes

- [#40](https://github.com/eins78/agent-skills/pull/40) [`549cfe3`](https://github.com/eins78/agent-skills/commit/549cfe36615e0353fd704c24b5622322fea0fc50) - **`chrome-browser`** — expands and consolidates the Chrome automation flags.

  Disables password checks, the AI mode badge, tab organisation, autofill, media routing and background networking, grouped by category with inline comments.

## 2.3.1

### Patch Changes

- [#38](https://github.com/eins78/agent-skills/pull/38) [`e27a458`](https://github.com/eins78/agent-skills/commit/e27a4584d58a241f03902b56df232e63ac27ffc3) - Release pipeline — the version now appears in the release commit message and PR title (`release: 2.3.0` rather than `chore: release`).

## 2.3.0

### Minor Changes

- [#33](https://github.com/eins78/agent-skills/pull/33) [`5b01b37`](https://github.com/eins78/agent-skills/commit/5b01b375ea74c21dc04413087e8d1fc8d1de465c) - **`typescript-strict-patterns`** — graduates from `1.0.0-beta.1` to stable `1.0.0`.

### Patch Changes

- [#36](https://github.com/eins78/agent-skills/pull/36) [`8dad438`](https://github.com/eins78/agent-skills/commit/8dad438e5717b4521b97a14ed869c396879de5bb) - **`bump-skill-versions.sh`** — fixes an unbound-variable error when no changeset carries a skill version bump.

## 2.2.0

### Minor Changes

- [#26](https://github.com/eins78/agent-skills/pull/26) [`a9a9ebc`](https://github.com/eins78/agent-skills/commit/a9a9ebcd22ad1758306862e96bd3baf84f3ffa6f) - **`lab-notes`** — new skill for structured experiment management.

  Rigorous and Freeform modes, append-only running logs, and formal verdicts.

- [#27](https://github.com/eins78/agent-skills/pull/27) [`ab6b1ec`](https://github.com/eins78/agent-skills/commit/ab6b1ec45915cc778cbaa4e29d8c200ede294c89) - **`pandoc`** — new skill teaching agents to use pandoc instead of writing ad-hoc conversion scripts.

  60+ input and 80+ output formats, with a curated manual reference, an installation guide, and advanced topics: Lua filters, citations, slides and templates.

### Patch Changes

- [#28](https://github.com/eins78/agent-skills/pull/28) [`eea8e9b`](https://github.com/eins78/agent-skills/commit/eea8e9becbf749fa538d69ab631ba0b7d61b59ca) - **`dossier`** — removes the Telegram-specific delivery instruction; delivery is the orchestrator's responsibility.
