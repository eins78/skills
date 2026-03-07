---
name: tracer-bullets
description: >-
  Use when facing technical uncertainty or building a large feature with a natural
  core-plus-extras decomposition. Guides building one thin vertical slice end-to-end
  before widening. Standalone strategy — works with or without Plot workflow.
globs: []
license: MIT
metadata:
  author: eins78
  repo: https://github.com/eins78/skills
  version: 1.0.0-beta.1
compatibility: Designed for Claude Code and Cursor. Works standalone or as a Plot sibling skill.
---

# Tracer Bullets

Build one thin vertical slice through all system layers end-to-end before widening. Tracer bullets are production code — not prototypes, not spikes. They validate architecture with real integration, then become the foundation that remaining work builds on.

Especially critical in AI-assisted development, where agents tend to build complete horizontal layers in isolation (all endpoints, then all UI, then integration) and discover fundamental issues late.

## When to Use

- Solution is NOT a well-trodden path — no established docs, tutorials, or prior art in the codebase
- Feature is large AND has a natural decomposition: MVP core + features on top + nice-to-haves
- Multiple system layers that haven't been integrated before in this codebase
- Uncertainty about whether the proposed architecture will actually work

## When NOT to Use

- Simple CRUD with well-documented patterns
- Single-layer changes (only touches API, only touches UI)
- Small scope where the whole feature IS the thin slice
- Technology and integration patterns are already proven in this codebase

## Process

### Step 1: Identify the Slice

Determine:
- Which layers does this feature touch? (e.g., DB → API → WebSocket → Client)
- What is the thinnest possible path through ALL of them?
- What does proving this path validate about the architecture?

The slice should be the smallest thing that exercises every layer. One request, one flow, one happy path.

### Step 2: Define the Tracer

Document the slice explicitly:

```
Tracer: <one-sentence description of what it does>
Layers: <layer> → <layer> → <layer>
Proves: <what this validates about the architecture>
```

Example:
```
Tracer: Single SSE connection with disconnect detection
Layers: API → WebSocket → EventSource → Client UI
Proves: Backpressure mechanism works across the full connection lifecycle
```

### Step 3: Build It

Implement the thin slice end-to-end:

- Touch every layer, but implement the minimum in each
- Prefer real code over mocks — the point is to prove real integration
- No error handling beyond what's needed to see if it works
- No edge cases, no validation, no polish
- Test it immediately — does one request flow through all layers?

### Step 4: Evaluate and Widen

After the tracer works:

1. **Record what you learned** — what worked, what surprised, what needs revision
2. **Decide next step:**
   - If pre-implementation (validating a design): refine the plan based on findings
   - If during implementation: merge the tracer, then build remaining features on top of it
3. **Widen** — add error handling, edge cases, additional features. Each widening step builds on the proven foundation.

## Anti-Patterns

| Anti-Pattern | Why It's Wrong |
|-------------|----------------|
| Building one layer completely first | Horizontal, not vertical — delays integration feedback |
| Treating the tracer as throwaway | Tracers are production code that carries forward |
| Over-engineering the tracer | If your tracer has error handling and edge cases, it's too wide |
| Skipping layers | A tracer that doesn't touch every layer proves nothing about integration |
| Mocking integration points | The entire point is real integration — mocks defeat the purpose |

## Plot Integration

When used within the Plot workflow, tracer bullets integrate at two lifecycle positions.

### Plan Template

Plans can define a tracer in the `## Branches` section:

```markdown
## Branches

### Tracer
- `feature/<slug>-tracer` — <thin slice description>
  Layers: <layer> → <layer> → <layer>
  Proves: <what this validates>

### Implementation
- `feature/<slug>` — <full description>
- `feature/<slug>-monitoring` — <description>
```

### Pre-Approval (Phase: Draft)

Use when there's high uncertainty about whether the plan's architecture will work.

- Stay on the `idea/<slug>` branch — tracer code lives alongside plan files
- After building the tracer, add a `## Tracer Results` section to the plan:
  - What worked as expected
  - What needed revision
  - What was learned
- Refine the plan based on findings, then proceed to review/approve
- Tracer code carries forward when the plan PR merges to main

### Post-Approval (Phase: Approved)

Use when the architecture is sound but the feature is large with a natural core.

- Create `feature/<slug>-tracer` branch from main
- Create a draft PR titled "Tracer: <thin slice description>"
- Implement the thin slice, merge it to main
- Remaining implementation branches build on top of the merged tracer

### Suggestion Heuristics

Plot's `/plot-approve` suggests a tracer bullet when:
- Plan has no `### Tracer` subsection AND
- The `## Design` section describes unfamiliar technology or experimental approaches, OR
- The plan has 3+ branches with a natural core-plus-extras shape

These suggestions are advisory — never blocking.
