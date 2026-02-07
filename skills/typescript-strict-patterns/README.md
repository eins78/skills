# typescript-strict-patterns

Development notes for the TypeScript strict patterns skill.

## Purpose

Covers tsconfig setup (`@total-typescript/tsconfig`), ESLint strict config, Zod at boundaries, discriminated unions, branded types, template literal types, and safe access patterns.

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
