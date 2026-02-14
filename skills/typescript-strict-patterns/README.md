# typescript-strict-patterns

Development notes for the TypeScript strict patterns skill.

## Purpose

Everyday TypeScript coding patterns: discriminated unions, branded types, Zod at boundaries, const arrays over enums, and safe access patterns. Project setup (tsconfig, ESLint, ts-reset) lives in reference files loaded on demand.

## Structure

| File | Content |
|---|---|
| `SKILL.md` | Everyday coding patterns (always loaded) |
| `project-setup.md` | tsconfig, ts-reset, type-fest guidance (loaded on demand) |
| `eslint.config.mjs` | Reference ESLint flat config (loaded on demand) |

## Tier

**Publishable** — Generic TypeScript patterns, useful across any TS project.

## Provenance

Extracted from conventions developed at Quatico Solutions AG, refined through real-world use across multiple TypeScript projects. Published as open-source patterns.

## Testing

- Validated with Claude Code (Opus, Sonnet) on TypeScript projects
- Patterns verified against `@total-typescript/tsconfig` and `typescript-eslint` strictTypeChecked

## Known Gaps

- No coverage for monorepo-specific tsconfig setups (project references)
- Could expand on Zod `.transform()` and `.pipe()` patterns
- No guidance on migrating existing projects to strict mode incrementally
