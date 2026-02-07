# Skills Repository

Agent Skills collection for Claude Code, following the [agentskills.io](https://agentskills.io/) spec.

Uses the [`skills`](https://www.npmjs.com/package/skills) CLI for validation.

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

## Validation

```bash
pnpm test        # runs: skills add . --list
```

This lists all discovered skills and exits non-zero if any skill fails to parse.

## Digraph Rendering

If SKILL.md contains ` ```dot ` blocks:
1. Create `diagrams/` directory in skill folder
2. Run `.dev/scripts/render-digraphs.sh SKILL.md ./diagrams`
3. Commit both .dot and .png files
4. Reference images in SKILL.md where helpful

Requires: `brew install graphviz`

## Key Principles

1. **Be concise** — Only add what Claude doesn't already know
2. **Progressive disclosure** — Overview in SKILL.md, details in referenced files
3. **Third person** — "Processes files" not "I help you process files"
4. **One level deep** — Reference files directly from SKILL.md, avoid nesting
5. **Use checklists** — Multi-step workflows benefit from copy-paste checklists
6. **Test across models** — Haiku may need more guidance than Opus

## Skill Composition

Skills can reference other skills by name in their instructions. Claude loads both skills when context matches — no formal import system, just mention by name.

## Adding and Editing Skills

- **Always use `/writing-skills` when planning, creating, editing, or reviewing skills**
- Keep skills generic — no account-specific data, API keys, or personal identifiers
- Skills should be self-contained: a single SKILL.md should cover a coherent topic
- Continuous improvement: after using a skill, note gaps and propose concrete improvements
- Installation: symlink from `~/.claude/skills/` to the skill directory

## Commit Conventions

Follow the existing commit style: `<skill-name>: <description>` for skill changes, plain descriptions for repo-level changes.
