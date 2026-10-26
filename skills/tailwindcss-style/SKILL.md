---
name: tailwindcss-style
description: Tailwind CSS conventions distilled from production web apps — semantic design tokens, cn() for conditional classes, when inline style is allowed. Use when writing or reviewing Tailwind classes, styling React components, or working with a design-token layer.
---

# Tailwind CSS style

Project CLAUDE.md/CONVENTIONS.md wins over anything here.

- Utility classes only; no component CSS files. The one sanctioned CSS location is the token layer (`@layer base` / theme config).
- Every conditional or merged class list goes through a `cn()` helper (clsx + tailwind-merge) — never string templates:
  ```tsx
  <tr className={cn('border-b', isExpanded && 'bg-surface-raised', isError && 'border-status-error')}>
  ```
  The repo usually already exports `cn()` (search before adding one, e.g. in a `utils` barrel). Surrounding code using raw `twMerge`, template strings, or `cond ? 'x' : ''` is legacy, not a pattern to copy — new and edited code uses `cn()` with `&&` conditionals, and converting a touched file fully to `cn()` is welcome.
- Semantic design tokens over raw palette utilities: `text-content-subtle`, `bg-surface-inset`, `border-status-error` — not `text-gray-500`, `bg-gray-100`, `border-red-500`. If the project has no token layer yet, propose one before scattering grays (docs-first).
- Two color sources only: the brand/design-system tokens for neutrals, surfaces, status and channel colors, and the product's own design-reference colors (declared in config with their source) for primary and accent. When a design file and the brand book disagree on a color, ask once up front which wins; never pick silently. Radius, shadow, spacing grid and typography follow the brand book regardless of the design file.
- Dark mode lives in the token definitions, not per-component `dark:` overrides — components reference tokens and stay theme-agnostic.
- Inline `style` only for genuinely non-class values (`<col style={{ width: 90 }} />`); never for anything a utility expresses.
- Arbitrary values (`bg-[#E5E7EB]`) are a smell — either it's a token that should exist, or it's the raw palette in disguise.
