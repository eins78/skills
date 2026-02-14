// eslint.config.mjs — baseline expected by typescript-strict-patterns
//
// This is the reference ESLint flat config for projects using this skill.
// Copy and adapt to your project. Requires:
//   pnpm add -D eslint typescript-eslint
//
// Key rules enforced:
// - No `enum` (use const arrays or z.enum())
// - Exhaustive switch statements
// - No unnecessary conditions (leverages strict tsconfig)
// - No `!` / `as` in production code (relaxed in tests)

import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.strictTypeChecked,
  {
    languageOptions: {
      parserOptions: { projectService: true },
    },
    rules: {
      "@typescript-eslint/switch-exhaustiveness-check": "error",
      "@typescript-eslint/no-unnecessary-condition": "error",
      "no-restricted-syntax": [
        "error",
        {
          selector: "TSEnumDeclaration",
          message: "Use const arrays or z.enum()",
        },
      ],
    },
  },
  {
    files: ["**/*.test.ts", "**/*.spec.ts"],
    rules: {
      "@typescript-eslint/no-non-null-assertion": "off",
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-unsafe-assignment": "off",
    },
  },
);
