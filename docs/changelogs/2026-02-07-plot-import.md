# Import Plot skill from private project

**Date:** 2026-02-07
**Source:** Claude Code
**PR:** #1

## Summary

Imported the Plot workflow system — a lean, git-native planning system with 5 commands and 4 lifecycle phases — from a private project into this skills repo. Researched diagram formats (Mermaid vs Graphviz/dot), chose Mermaid for native GitHub rendering and LLM compatibility. Wrote extensive development notes and a complete changelog covering the system's evolution across 5 Claude Code sessions.

## Key Accomplishments

- Imported 5 plot skills + 2 helper scripts (771 lines of instructions)
- Restructured from 5 separate skill directories to 1 hub-and-spoke skill
- Added 3 Mermaid lifecycle diagrams (render natively on GitHub)
- Stripped duplicate Setup sections from spoke files
- Wrote README.md with 8 design principles, provenance, testing history
- Wrote changelog.md documenting all 5 development sessions with commit references
- Removed all project-specific references (project name, hardcoded paths)

## Changes Made

- Created: `skills/plot/SKILL.md` (hub: overview, diagrams, dispatcher)
- Created: `skills/plot/plot-idea.md` (create plan command)
- Created: `skills/plot/plot-approve.md` (approve and fan out command)
- Created: `skills/plot/plot-deliver.md` (verify and archive command)
- Created: `skills/plot/plot-release.md` (version bump and tag command)
- Created: `skills/plot/scripts/plot-pr-state.sh` (plan PR state helper)
- Created: `skills/plot/scripts/plot-impl-status.sh` (impl PR states helper)
- Created: `skills/plot/README.md` (development docs)
- Created: `skills/plot/changelog.md` (evolution history)

## Decisions

- **Mermaid over Graphviz/dot**: Renders natively on GitHub (no build step), better LLM training coverage. Existing render-digraphs.sh stays for other skills.
- **Hub-and-spoke consolidation**: 5 separate skill directories in source project consolidated into 1 skill with spoke files, following the `bye` skill pattern.
- **3-commit sequence**: verbatim import, then adaptation, then documentation — clean git history for reviewability.
- **Dispatcher in SKILL.md**: The `/plot` smart dispatcher logic stays inline in SKILL.md (it IS the hub's purpose), while the 4 action commands become spoke files.

## Next Steps

- [ ] Merge PR #1
- [ ] Verify Mermaid diagrams render on GitHub
- [ ] Install skill in a project and test full lifecycle

## Repository State

- Branch: feature/plot-skill
- PR: #1 (https://github.com/eins78/skills/pull/1)
