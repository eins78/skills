#!/usr/bin/env bash
set -euo pipefail

# Install dependencies for the ai-review skill
# Usage: ./install-dependencies.sh

echo "=== AI Review Skill — Dependency Check ==="
echo ""

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js is required but not installed."
  echo "  Install: brew install node"
  exit 1
fi
echo "Node.js: $(node --version)"

# Check/install gemini CLI
if command -v gemini &>/dev/null; then
  echo "gemini CLI: $(gemini --version 2>&1 | tail -1) (already installed)"
else
  echo "Installing gemini CLI..."
  npm install -g @google/gemini-cli
  echo "gemini CLI: $(gemini --version 2>&1 | tail -1)"
fi

# Check python3 (needed for repo-relative paths)
if command -v python3 &>/dev/null; then
  echo "python3: $(python3 --version)"
else
  echo "WARNING: python3 not found. File reviews will use basename instead of repo-relative paths."
fi

# Check gemini auth
echo ""
if [[ -f "$HOME/.gemini/settings.json" ]]; then
  echo "gemini config: found (~/.gemini/settings.json)"
else
  echo "gemini config: not found"
  echo ""
  echo "  Run 'gemini' interactively to complete Google Account OAuth."
  echo "  This opens a browser for one-time authentication."
fi

# Optional: check codex
echo ""
if command -v codex &>/dev/null; then
  echo "codex CLI: installed (optional secondary provider)"
else
  echo "codex CLI: not installed (optional — install with: brew install codex)"
fi

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. If first time: run 'gemini' to complete OAuth in browser"
echo "  2. Symlink skill: ln -s $(cd "$(dirname "$0")/.." && pwd) ~/.claude/skills/ai-review"
echo "  3. Use /ai-review in any Claude Code session"
