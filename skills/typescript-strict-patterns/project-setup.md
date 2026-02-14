# Project Setup

One-time setup guidance for TypeScript projects using these patterns.

## tsconfig: Use @total-typescript/tsconfig

Always extend `@total-typescript/tsconfig`. Pick a base by: **build tool** (`tsc/` or `bundler/`), **runtime** (`dom/` or `no-dom/`), **project type** (`app`, `library`, `library-monorepo`).

```json
{
  "extends": "@total-typescript/tsconfig/tsc/no-dom/app",
  "compilerOptions": { "outDir": "./dist", "rootDir": "./src" }
}
```

The base enables `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride`, `verbatimModuleSyntax`, `isolatedModules`, and correct `module`/`lib` for the target. Read the source bases before adding overrides.

## ESLint

See [`eslint.config.mjs`](./eslint.config.mjs) for the reference flat config.

Install:

```bash
pnpm add -D eslint typescript-eslint
```

## ts-reset

Install `@total-typescript/ts-reset` in application code (not libraries) to fix built-in return types (`.filter(Boolean)`, `.json()`, `Map.get`, etc.). Import once in a global `.d.ts`.
