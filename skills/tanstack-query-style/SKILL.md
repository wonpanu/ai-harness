---
name: tanstack-query-style
description: TanStack Query (react-query) conventions distilled from production web apps — query key factories, domain hooks wrapping useQuery, invalidation by prefix, debounce rules. Use when writing or reviewing useQuery/useMutation code, query keys, cache invalidation, or data-fetching hooks.
---

# TanStack Query style

Project CLAUDE.md/CONVENTIONS.md wins over anything here. Pairs with `react-frontend-style` (hook return shape) — read that too when writing the surrounding hook.

- Never use `useQuery`/`useMutation` directly in components — wrap each in a domain hook that returns a named object with derived flags (`orders`, `isEmpty`, `hasRows`), not the raw query result.
- Query key built by an exported function living next to the query hook; export the prefix constant for invalidation:
  ```ts
  export const ORDER_LIST_KEY_PREFIX = 'orders'
  export const orderListKey = (filters: Filters) =>
    [ORDER_LIST_KEY_PREFIX, filters.status, filters.page] as const
  ```
- Key parts depend on individual fields, never the whole filter object — object identity churn causes refetch storms.
- `queryFn` calls the service layer only; it never `fetch`es or unwraps wire envelopes itself.
- Mutations invalidate by prefix (`queryClient.invalidateQueries({ queryKey: [ORDER_LIST_KEY_PREFIX] })`), not by rebuilding exact keys.
- Cross-concern wiring goes one level up: the mutation hook accepts a callback (`onReviewed`) instead of knowing about other hooks' caches.
- Debounce only free-text search inputs before they reach the key; discrete filters (selects, toggles, pagination) update immediately.
- `enabled:` guards dependent queries; never simulate it with conditional hook calls.
