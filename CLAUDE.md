# Skills Repository

Agent Skills collection for Claude Code, following the [agentskills.io](https://agentskills.io/) spec.

This is a documentation/specification repository — there is no build system, no tests, and no lint commands.

## Skill Format

Each skill lives in its own directory under `skills/` and consists of:

```
skills/<skill-name>/
├── SKILL.md      # The skill itself (frontmatter + instructions)
└── README.md     # Development documentation (REQUIRED)
```

### SKILL.md

YAML frontmatter followed by markdown instructions:

```yaml
---
name: skill-name
description: When to activate and what the skill covers.
globs: ["**/*.ts", "**/*.tsx"]
license: MIT
---
```

The markdown body contains patterns, rules, and examples that Claude follows when the skill is active.

### README.md (required)

Every skill directory must contain a README.md with development documentation:

- Purpose and scope of the skill
- Skill tier (publishable/reusable vs project-specific)
- How the skill was tested and validated
- Provenance (where patterns originated)
- Known gaps and planned improvements

## Adding and Editing Skills

- **Always use `/writing-skills` when planning, creating, editing, or reviewing skills**
- Keep skills generic — no account-specific data, API keys, or personal identifiers
- Skills should be self-contained: a single SKILL.md should cover a coherent topic
- Continuous improvement: after using a skill, note gaps and propose concrete improvements
- Installation: symlink from `~/.claude/skills/` to the skill directory

## Commit Conventions

Follow the existing commit style: `<skill-name>: <description>` for skill changes, plain descriptions for repo-level changes.
