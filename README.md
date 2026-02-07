# eins78/skills

Personal collection of [Agent Skills](https://agentskills.io/) for Claude Code and compatible AI coding agents.

## Skills

| Skill | Description |
|-------|-------------|
| [typescript-strict-patterns](skills/typescript-strict-patterns/) | TypeScript strict mode patterns — Zod at boundaries, const arrays over enums, no `!`/`as`, safe indexed access, `@total-typescript/tsconfig` |

## Installation

Copy or symlink a skill into your Claude Code skills directory:

```bash
# Symlink a single skill
ln -s ~/CODE/skills/skills/typescript-strict-patterns ~/.claude/skills/typescript-strict-patterns

# Or copy it
cp -r ~/CODE/skills/skills/typescript-strict-patterns ~/.claude/skills/
```

Skills are picked up automatically by Claude Code based on their `globs` frontmatter.

## Format

Each skill follows the [Agent Skills](https://agentskills.io/) spec — a `SKILL.md` file with YAML frontmatter (`name`, `description`, `globs`) and markdown instructions.

## License

MIT
