#!/usr/bin/env bash
set -euo pipefail

# AI Code Review via Gemini CLI (or OpenAI Codex)
# Usage: review.sh [--staged|--branch|--context "..."|--plan PATH|--no-context] [file ...]
#
# Pipes code via stdin to avoid ARG_MAX limits with large diffs.
# Auto-includes project context (CLAUDE.md, plans, file tree) for better reviews.
# Timeout: 1 hour (quality over speed — never skip reviews).
# Exit codes: 0=success, 1=no code/bad args, 2=timeout (ask human for help)

PROVIDER="${REVIEW_PROVIDER:-gemini}"
CONTEXT=""
MODE="diff"
FILES=()
TIMEOUT_SECONDS=3600  # 1 hour
SKIP_CONTEXT=0
PLAN_PATH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged)
      MODE="staged"
      shift
      ;;
    --branch)
      MODE="branch"
      shift
      ;;
    --context)
      if [[ $# -lt 2 ]]; then
        echo "Error: --context requires a value" >&2
        exit 1
      fi
      CONTEXT="$2"
      shift 2
      ;;
    --plan)
      if [[ $# -lt 2 ]]; then
        echo "Error: --plan requires a path" >&2
        exit 1
      fi
      PLAN_PATH="$2"
      shift 2
      ;;
    --no-context)
      SKIP_CONTEXT=1
      shift
      ;;
    --provider)
      if [[ $# -lt 2 ]]; then
        echo "Error: --provider requires a value" >&2
        exit 1
      fi
      PROVIDER="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      FILES+=("$1")
      MODE="files"
      shift
      ;;
  esac
done

# Fail fast: check provider availability before doing any work
case "$PROVIDER" in
  gemini)
    if ! command -v gemini &>/dev/null; then
      echo "Error: gemini CLI not found. Install: npm install -g @google/gemini-cli" >&2
      exit 1
    fi
    ;;
  codex)
    if ! command -v codex &>/dev/null; then
      echo "Error: codex CLI not found. Install: brew install codex" >&2
      exit 1
    fi
    ;;
  *)
    echo "Unknown provider: $PROVIDER. Supported: gemini, codex" >&2
    exit 1
    ;;
esac

# Resolve repo root early (needed for file headers and gemini sandbox access)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Gather project context for the reviewer (plan, instructions, file tree)
gather_context() {
  local ctx=""
  local max_file_bytes=10000

  # 1. Implementation plan (what the code should do)
  local plan_file=""
  if [[ -n "$PLAN_PATH" ]]; then
    plan_file="$PLAN_PATH"
  elif [[ -f "$REPO_ROOT/PLAN.md" ]]; then
    plan_file="$REPO_ROOT/PLAN.md"
  else
    # Most recently modified Claude Code plan
    local plans_dir="$REPO_ROOT/.claude/plans"
    if [[ -d "$plans_dir" ]]; then
      plan_file="$(ls -t "$plans_dir"/*.md 2>/dev/null | head -1)"
    fi
  fi
  if [[ -n "$plan_file" && -f "$plan_file" ]]; then
    local plan_name
    plan_name="$(basename "$plan_file")"
    ctx+="--- IMPLEMENTATION PLAN ($plan_name) ---"$'\n'
    ctx+="$(head -c "$max_file_bytes" "$plan_file")"$'\n\n'
  fi

  # 2. Project instructions (conventions, architecture, design decisions)
  for candidate in CLAUDE.md GEMINI.md AGENTS.md; do
    local fpath="$REPO_ROOT/$candidate"
    if [[ -f "$fpath" ]]; then
      ctx+="--- PROJECT INSTRUCTIONS ($candidate) ---"$'\n'
      ctx+="$(head -c "$max_file_bytes" "$fpath")"$'\n\n'
      break  # use only the first found
    fi
  done

  # 3. File tree (structural awareness)
  local tree_output
  tree_output="$(find "$REPO_ROOT" -maxdepth 3 \
    -not -path '*/.git/*' \
    -not -path '*/node_modules/*' \
    -not -path '*/.build/*' \
    -not -path '*/build/*' \
    -not -path '*/.swiftpm/*' \
    -not -path '*/.claude/*' \
    -not -name '.DS_Store' \
    -type f 2>/dev/null | sed "s|$REPO_ROOT/||" | sort | head -200)" || true
  if [[ -n "$tree_output" ]]; then
    ctx+="--- PROJECT FILE TREE ---"$'\n'
    ctx+="$tree_output"$'\n\n'
  fi

  printf '%s' "$ctx"
}

# Tempfiles and process cleanup
CODEFILE="$(mktemp /tmp/ai-review-code.XXXXXX)"
OUTFILE="$(mktemp /tmp/ai-review-out.XXXXXX)"
chmod 600 "$CODEFILE" "$OUTFILE"
REVIEW_PID=""
WATCHDOG_PID=""
# shellcheck disable=SC2329 # invoked by trap
cleanup() {
  if [[ -n "$REVIEW_PID" ]]; then
    kill "$REVIEW_PID" 2>/dev/null || true
    wait "$REVIEW_PID" 2>/dev/null || true
  fi
  if [[ -n "$WATCHDOG_PID" ]]; then
    kill "$WATCHDOG_PID" 2>/dev/null || true
    # Also kill the sleep child inside the watchdog subshell
    pkill -P "$WATCHDOG_PID" 2>/dev/null || true
    wait "$WATCHDOG_PID" 2>/dev/null || true
  fi
  rm -f "$CODEFILE" "$OUTFILE"
}
trap cleanup EXIT

# Verify git repo for diff modes
if [[ "$MODE" != "files" ]] && ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: Not a git repository. Use file paths instead." >&2
  exit 1
fi

case "$MODE" in
  diff)
    git diff > "$CODEFILE" 2>/dev/null || true
    if [[ ! -s "$CODEFILE" ]]; then
      echo "No unstaged changes found. Use --staged, --branch, or specify files." >&2
      exit 1
    fi
    DESCRIPTION="unstaged changes"
    ;;
  staged)
    git diff --cached > "$CODEFILE" 2>/dev/null || true
    if [[ ! -s "$CODEFILE" ]]; then
      echo "No staged changes found." >&2
      exit 1
    fi
    DESCRIPTION="staged changes"
    ;;
  branch)
    BASE="${REVIEW_BASE_BRANCH:-main}"
    git diff "$BASE"...HEAD > "$CODEFILE" 2>/dev/null || true
    if [[ ! -s "$CODEFILE" ]]; then
      echo "No differences from $BASE found." >&2
      exit 1
    fi
    DESCRIPTION="branch changes vs $BASE"
    ;;
  files)
    BASENAMES=()
    for f in "${FILES[@]}"; do
      if [[ -f "$f" ]]; then
        # Repo-relative paths disambiguate (src/index.ts vs tests/index.ts)
        # without triggering gemini's agent mode on absolute paths
        bn="$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$f" "$REPO_ROOT" 2>/dev/null || basename "$f")"
        BASENAMES+=("$bn")
        printf '\n--- FILE: %s ---\n' "$bn" >> "$CODEFILE"
        cat "$f" >> "$CODEFILE"
      else
        echo "Warning: file not found: $f" >&2
      fi
    done
    if [[ ! -s "$CODEFILE" ]]; then
      echo "No valid files to review." >&2
      exit 1
    fi
    DESCRIPTION="files: ${BASENAMES[*]}"
    ;;
esac

# Prepend project context (plan, instructions, file tree)
if [[ "$SKIP_CONTEXT" -eq 0 ]]; then
  PROJECT_CONTEXT="$(gather_context)"
  if [[ -n "$PROJECT_CONTEXT" ]]; then
    CTXFILE="$(mktemp /tmp/ai-review-ctx.XXXXXX)"
    printf '%s\n' "$PROJECT_CONTEXT" > "$CTXFILE"
    cat "$CODEFILE" >> "$CTXFILE"
    mv "$CTXFILE" "$CODEFILE"
  fi
fi

# Build context line
CONTEXT_LINE=""
if [[ -n "$CONTEXT" ]]; then
  CONTEXT_LINE="Project context: $CONTEXT
"
fi

# Check total size (context + code)
CODE_SIZE=$(wc -c < "$CODEFILE")
if [[ $CODE_SIZE -gt 400000 ]]; then
  echo "Warning: review payload is very large (${CODE_SIZE} bytes). Consider --no-context or reviewing fewer files." >&2
fi

# The review instruction (small, safe as -p argument)
CONTEXT_PREAMBLE=""
if [[ "$SKIP_CONTEXT" -eq 0 ]]; then
  CONTEXT_PREAMBLE="The code is preceded by project context (implementation plan, project instructions, and file tree). Use this context to understand conventions and architecture — do not flag intentional design decisions as issues.

"
fi

INSTRUCTION="You are a code reviewer. Review the following ${DESCRIPTION}.

${CONTEXT_PREAMBLE}${CONTEXT_LINE}Review criteria:
1. Correctness — bugs, logic errors, edge cases
2. Security — injection, auth issues, data exposure
3. Performance — unnecessary allocations, blocking calls
4. Idiomatic patterns — language/framework conventions
5. Maintainability — naming, structure, complexity

For each issue found, output:
- Severity: ERROR | WARNING | INFO
- File and line (if identifiable)
- Description
- Suggested fix

End with: VERDICT: APPROVE | REQUEST_CHANGES | COMMENT_ONLY
and a 1-2 sentence summary.

Code to review:"

# Run the review provider. Explicit stdin redirect (< "$CODEFILE") inside
# the function ensures it works correctly when backgrounded with &.
run_review() {
  case "$PROVIDER" in
    gemini)
      gemini --include-directories "$REPO_ROOT" -p "$INSTRUCTION" < "$CODEFILE" > "$OUTFILE" 2>&1
      ;;
    codex)
      codex -p "$INSTRUCTION" < "$CODEFILE" > "$OUTFILE" 2>&1
      ;;
  esac
}

# Run with timeout (quality over speed — never skip)
run_review &
REVIEW_PID=$!

# Background watchdog
(
  sleep "$TIMEOUT_SECONDS"
  if kill -0 "$REVIEW_PID" 2>/dev/null; then
    echo "" >&2
    echo "ERROR: Review timed out after $((TIMEOUT_SECONDS / 60)) minutes." >&2
    echo "The review provider may be experiencing extended rate limits or outages." >&2
    echo "Ask your human partner for help — do NOT skip the review." >&2
    kill "$REVIEW_PID" 2>/dev/null
  fi
) &
WATCHDOG_PID=$!

# Wait for the review
if wait "$REVIEW_PID" 2>/dev/null; then
  kill "$WATCHDOG_PID" 2>/dev/null
  pkill -P "$WATCHDOG_PID" 2>/dev/null || true
  wait "$WATCHDOG_PID" 2>/dev/null || true
  cat "$OUTFILE"
  exit 0
else
  EXIT_CODE=$?
  kill "$WATCHDOG_PID" 2>/dev/null
  pkill -P "$WATCHDOG_PID" 2>/dev/null || true
  wait "$WATCHDOG_PID" 2>/dev/null || true
  # If killed by timeout (signal 143 = SIGTERM or 137 = SIGKILL), exit with code 2
  if [[ $EXIT_CODE -eq 143 ]] || [[ $EXIT_CODE -eq 137 ]]; then
    cat "$OUTFILE"  # show any partial output
    exit 2
  fi
  cat "$OUTFILE"
  exit "$EXIT_CODE"
fi
