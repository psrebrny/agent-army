# frontend/AGENTS.md — laws for the SPA (authoritative for this subtree)

This nested standards file overrides the root for everything under `frontend/`.

## Laws

1. **Design-system primitives only.** Components import UI atoms from `src/ui/primitives/`
   (`Button`, `Input`, …). Raw `<button>`, `<input>`, or inline `style={}` in a feature
   component is a rejected PR. Proof: `src/components/TransferForm.tsx` uses `<Button>`.
2. **No fetch in components.** Network calls live in `src/api/`; components receive data
   via props/hooks. A `fetch(` inside a component is a bug.
3. **Test runner is Vitest**, component tests colocated as `*.test.tsx` next to the component.

## Commands

```bash
npm test          # vitest
npm run lint      # eslint
```
