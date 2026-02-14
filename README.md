# eins78/skills

Personal collection of [Agent Skills](https://agentskills.io/) for Claude Code and compatible AI coding agents.

## Skills

| Skill | Description |
|-------|-------------|
| [bye](skills/bye/) | Session wrap-up — reconstructs history, creates sessionlog, commits, summarizes next steps |
| [plot](skills/plot/) | Git-native planning dispatcher with 4-phase workflow (idea → approve → deliver → release) |
| [plot-idea](skills/plot-idea/) | Create a plan: idea branch, plan file, and draft PR |
| [plot-approve](skills/plot-approve/) | Merge approved plan, fan out into implementation branches |
| [plot-deliver](skills/plot-deliver/) | Verify implementation complete, archive the plan |
| [plot-release](skills/plot-release/) | Create versioned release from delivered plans |
| [plot-sprint](skills/plot-sprint/) | Time-boxed sprint coordination with MoSCoW prioritization |
| [typescript-strict-patterns](skills/typescript-strict-patterns/) | TypeScript patterns — tsconfig, ESLint strict, Zod, discriminated unions, branded types |

## Installation

### One-liner (all skills)

```bash
pnpx skills add https://github.com/eins78/skills.git --global --agent claude-code --all --yes
```

### Manual (single skill)

```bash
# Symlink a single skill
ln -s ~/CODE/skills/skills/typescript-strict-patterns ~/.claude/skills/typescript-strict-patterns

# Or copy it
cp -r ~/CODE/skills/skills/typescript-strict-patterns ~/.claude/skills/
```

Skills are picked up automatically by Claude Code based on their `globs` frontmatter.

## Format

Each skill follows the [Agent Skills](https://agentskills.io/) spec — a `SKILL.md` file with YAML frontmatter (`name`, `description`, `globs`) and markdown instructions.

## Creating Skills

### Quick Start

```
my-skill/
├── SKILL.md          # Required: frontmatter + instructions
├── README.md         # Required: development notes, design decisions, testing history
└── REFERENCE.md      # Optional: detailed reference material (>100 lines)
```

### SKILL.md Template

```yaml
---
name: my-skill-name     # lowercase, hyphens, max 64 chars, must match directory
description: What it does and when to use it. Include trigger keywords. (max 1024 chars)
# Optional fields per agentskills.io spec:
compatibility: claude-code, cursor
license: MIT
metadata:
  source: https://github.com/your-org/your-repo
  version: "1.0"
---

# My Skill Name

[Instructions here — keep under 500 lines]

See [REFERENCE.md](REFERENCE.md) for details.
```

**Note:** Reference files over 100 lines should include a table of contents.

### Key Principles

1. **Be concise** — Only add what Claude doesn't already know
2. **Progressive disclosure** — Overview in SKILL.md, details in referenced files
3. **Third person** — "Processes files" not "I help you process files"
4. **One level deep** — Reference files directly from SKILL.md, avoid nesting
5. **Use checklists** — Multi-step workflows benefit from copy-paste checklists
6. **Test across models** — Haiku may need more guidance than Opus

### Skill Composition

Skills can reference other skills by name in their instructions:

```markdown
## Committing Your Fix

When ready to commit, use the **commit-notation** skill:
- Bugfixes use `B` intention
- Risk level depends on test coverage
```

Claude loads both skills when context matches. No formal import system — just mention by name.

### Official Resources

**Specification & Docs:**

- [Agent Skills Specification](https://agentskills.io) — Open standard format
- [Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — Anthropic's authoring guide
- [Claude Code Skills](https://code.claude.com/docs/en/skills) — Claude Code integration

**Example Skills & Tools:**

- [Anthropic Skills Repository](https://github.com/anthropics/skills) — Official example skills
- [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) — Scaffolding tool for new skills

## License

MIT
