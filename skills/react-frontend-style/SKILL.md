---
name: react-frontend-style
description: React/TypeScript frontend code-style rules distilled from production web apps — component/hook structure, state shape, gate components, strict typing, data layering. Use when writing or reviewing React components, hooks, TypeScript frontend code, or .tsx files.
---

# React frontend style

Project CLAUDE.md/CONVENTIONS.md wins over anything here.

Concrete avoid/prefer code for every rule: see [EXAMPLES.md](EXAMPLES.md) — read it when a rule alone is ambiguous or before reviewing unfamiliar code.

## Components

- One component per file; PascalCase filename = component name.
- Orchestrator components compose hooks + render only; pure UI lives in `components/`.
- One feature hook per orchestrator (`const { guard, handleLogin } = useHome()`); the orchestrator never calls `useRouter`, `useState`, `useId` or reads env itself — the feature hook owns navigation, env and handlers.
- Use the project's UI kit primitives (shadcn via its CLI) composed or wrapped, never hand-written `<input>`, `<label>`, dividers, skeletons or alerts. After `shadcn add`, fix the generated `cn` import (it may misread the alias and add a `cn` package) and swap its icon library for the project's.
- No barrel `index.ts` — import concrete file paths.
- Co-locate skeletons and small private render helpers with their owner; split anything with a meaningful standalone name.

## Hooks

- `useXxx`, one file per hook. Generic domain-free hooks in shared `hooks/`; domain hooks in the feature.
- Return a named object of individual values, never a raw library result (`useQuery` object).
- Expose handlers (`handleX`, `selectValue`, `clear`), never raw setters.
- Compute derived flags/data in the hook (`isEmpty`, `hasRows`, `displayLabel`), not in JSX.
- Stateful UI primitives get a headless hook; the component only renders.

## State

- Group related state into one object with a single patch updater (`updateFilter(patch)`).
- Mutually-exclusive UI modes = one discriminated union, never N independent booleans; derive `shouldShowX` from the union.
- Prefer derived state over stored duplicates.
- One hook per concern; cross-concern wiring happens one level up via callbacks.
- Context only for state needed ≥3 levels deep: memoized value, consumer hook throws without a provider (optional `useOptionalX` variant for components rendered outside it).

## Rendering

- Loading/error/empty/guard branching = early-return ladder at the top of the orchestrator (or a gate component), each branch returning a pure component; orchestrators never see `isLoading`, they switch on one discriminated union (`guard.kind`).
- A cross-cutting precondition (session cookie, embed context) is a hook returning a discriminated union (`useRouteGuard()` → `loading | missing-context | redirecting | ready`) that performs its own redirect in an effect; never a wrapper component taking `skeleton` or render props.
- Every page owns a co-located skeleton that mirrors its real layout (same wrapper, same block sizes). Never one generic skeleton shared by all pages: it shifts the layout on load.
- Inline `&&` only for small optional JSX slices, never for state branching.

## TypeScript

- `interface` for object/prop shapes; `type` for unions/derived/mapped types.
- `import type { … }` for all type-only imports. No `any` in application code.
- Props interface `<Component>Props`, declared above the component, unexported unless reused.
- Optional props defaulted at destructuring, not coerced in JSX.
- String-literal sets as `as const` objects with the type derived from them.
- Strictest compiler config the project allows (`strict`, `noUncheckedIndexedAccess`, …).

## Data layer

- Three layers: wire types (match the API casing) → domain entity via pure mapper → service.
- One shared typed HTTP client with a typed error; features never call `fetch` directly.
- Services are injectable factories (`createXService(http)`) + default singleton; they unwrap the envelope and return mapped entities — consumers never touch `.data`.
- Guard closed-set enum fields with a `toXxx` mapper + fallback at the boundary.
- Values that do not vary by environment (store links, external contract URLs) are named constants in code; env vars only for what differs per environment.

## Styling, naming, tests

- Conditional classes through a `cn()` helper; semantic design tokens over raw palette utilities; inline `style` only for genuinely non-class values.
- Handlers `handleX`, callback props `onX`, booleans `is/has/should/can`.
- Name with the mainstream frontend term (`useRouteGuard`, `Skeleton`, `ProtectedRoute`), not a word coined for one repo (`frame`, `gate`). Helpers are files named after their main export (`resolveSessionRoute.ts`); entity types live in `src/entity/`; no product-name abbreviations (`MESSAGE_CENTER_…`, not `MC_…`). User-facing copy spells the product as the brand does; identifiers keep the code name.
- No comment that narrates a placeholder or a future ticket (`// until the API lands`): a `PLACEHOLDER_…` name already says it.
- Extract DOM-independent logic into pure functions and test those; the hook stays a thin binding. Test files co-located, named after the unit.
