---
name: typescript-strict-patterns
description: Use when writing or reviewing TypeScript in projects with erasableSyntaxOnly, noUncheckedIndexedAccess, or strict non-null policies
globs: ["**/*.ts", "**/*.tsx"]
license: MIT
---

# TypeScript Strict Patterns

## Zod Schemas at System Boundaries

Use Zod schemas as the canonical type definitions for data crossing system boundaries (disk I/O, env vars, YAML config). Derive TypeScript types with `z.infer<>` — never duplicate a hand-written interface alongside a schema.

```typescript
// src/schemas.ts — single source of truth
export const sessionMetaSchema = z.object({
  token: z.string(),
  status: z.enum(["running", "completed", "error"]),
  // ...
});

// src/types.ts — derived, never hand-written
export type SessionMeta = z.infer<typeof sessionMetaSchema>;
```

**`safeParse()` vs `parse()`:**
- Use `safeParse()` for data that may be corrupt (disk reads, JSONL lines) — skip gracefully, never crash
- Use `parse()` (or `safeParse` + `process.exit`) for startup validation (env vars) where failure is fatal

**When NOT to use Zod:**
- Internal function arguments between trusted modules — plain TS types suffice
- SDK messages from `@anthropic-ai/claude-code` — the SDK owns those types
- Hot paths where validation overhead matters (e.g., per-SSE-event broadcasting)

**Prefer `z.enum()` over `as const` + guards** at system boundaries where Zod already validates (see "Const Arrays Over Enums" below for internal-only unions).

## Const Arrays Over Enums

Never use `enum`. Use `as const` arrays with derived types and runtime guards:

```typescript
const STATUSES = ['pending', 'active', 'done'] as const;
type Status = (typeof STATUSES)[number];

function isStatus(value: string): value is Status {
  return (STATUSES as readonly string[]).includes(value);
}

function ensureStatus(value: string, fallback: Status = 'pending'): Status {
  return isStatus(value) ? value : fallback;
}
```

This gives you runtime validation, type narrowing, and iterable values — none of which `enum` provides cleanly.

## No `!` or `as` in Production Code

Non-null assertions (`!`) and type assertions (`as`) are banned in production code. They are allowed in test files (`*.test.ts`, `*.spec.ts`) where the tradeoff is acceptable.

Replacements:

- **Destructuring with defaults** instead of `obj.prop!`:
  ```typescript
  const { name = '' } = config;
  ```
- **`.at()` + nullish coalescing** instead of `arr[0]!`:
  ```typescript
  const first = arr.at(0) ?? defaultValue;
  ```
- **Guard clause with early return** instead of `value as Foo`:
  ```typescript
  if (!isStatus(value)) return;
  // value is now narrowed to Status
  ```

## Safe Indexed Access

With `noUncheckedIndexedAccess`, array indexing (`arr[0]`) and object property access (`obj[key]`) return `T | undefined`. Always narrow:

- Use `.at(index)` which explicitly returns `T | undefined` (clearer intent than bracket access)
- Use `if (item !== undefined)` or `??` to handle the undefined case
- Use `.find()`, `.filter()`, or destructuring instead of index access where possible

## tsconfig: Use @total-typescript/tsconfig

Always use `@total-typescript/tsconfig` as the base. Pick the right base from the decision tree:

1. **Build tool:** `tsc/` (transpiling with tsc) or `bundler/` (Vite, esbuild, etc.)
2. **Runtime:** `dom/` (browser) or `no-dom/` (Node.js)
3. **Project type:** `app`, `library`, or `library-monorepo`

Example for a Node.js app compiled with tsc:
```json
{
  "extends": "@total-typescript/tsconfig/tsc/no-dom/app",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  }
}
```

The base sets: `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride`, `verbatimModuleSyntax`, `isolatedModules`, `moduleDetection: "force"`, and appropriate `module`/`lib` for the target. Add project-specific overrides only (e.g., `erasableSyntaxOnly`, `declaration`, `outDir`).

Read the source bases in `node_modules/@total-typescript/tsconfig/` to see exact options before overriding.

## Custom Type Helpers

Do not add `type-fest` or similar packages for a few utility types. If you need a helper like `SetRequired` or `Simplify`, copy the single type definition into a local `src/types/` file with attribution. Keep the dependency graph small.
