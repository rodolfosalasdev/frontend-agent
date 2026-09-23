# Next.js: UI with Tailwind CSS and shadcn/ui

General CSS, responsiveness and accessibility principles live in the Frontend Agent's `principles/css-ui.md` and `principles/accessibility.md`. This file covers React / Next.js specifics.

## Default configuration (parameterizable)

```yaml
ui:
  css_framework: tailwind
  component_library: shadcn/ui
```

- If the project uses another CSS framework or design system, **follow the project**. Never add Tailwind or shadcn/ui to a project that chose a different UI strategy.
- For new React / Next.js projects without a defined UI strategy, Tailwind + shadcn/ui is the default.

## Tailwind CSS

- Detect the installed major version first: configuration style (JS config file vs CSS-based configuration), directives and plugin setup differ significantly between majors.
- Prefer existing design tokens (theme colors, spacing, radius); avoid arbitrary values when a token exists.
- Follow the project's responsive conventions (mobile-first breakpoints).
- Merge conditional classes with the project's helper (commonly a `cn()` utility combining `clsx` and `tailwind-merge` in shadcn/ui projects).
- Avoid long duplicated class lists: extract a component, not a CSS abstraction, when the same pattern repeats.
- Do not build class names dynamically from string fragments (`bg-${color}-500`); Tailwind cannot detect them. Map to complete class names.
- Dark mode and themes through the project's token strategy (CSS variables), not duplicated class sets.

## shadcn/ui

- shadcn/ui components are **copied into the project** (usually `components/ui/`) and owned by it. Check `components.json` for paths, style and aliases.
- Before creating a component, check if an equivalent already exists in the project's `components/ui/`.
- To add a new component, use the official CLI for the installed setup, or the shadcn MCP when available to look up components and the exact add command. Do not write shadcn components from memory.
- Treat `components/ui/` as **shared primitives**: evaluate the impact before modifying them; prefer composition or a wrapper component for feature-specific variations.
- Variants through the project's existing pattern (commonly `class-variance-authority`).
- Many shadcn/ui components are Client Components because they rely on interactive primitives. Keep them as leaves and keep pages and data-heavy parents as Server Components.

## UX states

Every data-driven view and every form must handle all of its states. This is the most visible difference between a prototype and a product.

| State | Requirement |
|---|---|
| Loading | Skeleton with the same shape and size as the final content (no layout shift). For fast actions, avoid flicker (show the indicator only after a short delay or keep previous content with a pending style). |
| Empty | Clear message explaining why it is empty and, when possible, a primary action ("Create your first project", "Clear filters"). |
| Error | Human message without internal details, a retry action, and the rest of the page still usable. Route-level errors via `error.tsx`. |
| Success | The content; for mutations, visible confirmation (inline message or toast). |
| Partial / stale | When showing previous data while refreshing, indicate it subtly (e.g. reduced opacity or a small spinner) instead of blanking the view. |

Forms:

- submit button shows a pending state and prevents double submission;
- field errors appear next to the field and are associated with it;
- values are preserved after a failed submission;
- success feedback is explicit (message, toast or navigation);
- destructive actions ask for confirmation (e.g. shadcn `AlertDialog`) and say what will happen.

Toasts: use the project's solution (commonly `sonner` in shadcn/ui projects). Toasts complement, not replace, inline errors, and must not be the only place critical information appears.

## Visual quality

Aim for interfaces that look intentional, not generic. Follow the project's design system first; when it leaves room, apply:

- **Spacing:** use the spacing scale consistently (Tailwind tokens). Related elements closer together, groups separated by larger gaps. Generous whitespace over cramming.
- **Typography:** a small type scale (e.g. 3 to 5 sizes) with clear roles (page title, section title, body, caption). Limit weights. Comfortable line length for reading (roughly 60 to 80 characters).
- **Hierarchy:** one clear primary action per view; secondary actions visually quieter (`variant="outline"`, `ghost`). The most important information is the most prominent.
- **Color:** neutral base plus **one** accent color for primary actions and focus. Semantic colors (destructive, success, warning) only for their meaning. Always meet contrast requirements, in light and dark themes.
- **Consistency:** same radius, shadows, border and icon sizes across components (use tokens, not arbitrary values).
- **Interactive states:** every interactive element has distinct hover, focus-visible, active and disabled states.
- **Motion:** short, purposeful transitions (feedback, continuity) using `transform`/`opacity`; respect `prefers-reduced-motion`.
- **Alignment and density:** align to a grid; numbers in tables right-aligned with tabular figures (`tabular-nums`); avoid mixed alignments in the same column.
- **Starting points:** shadcn/ui components and blocks (when the project uses shadcn) instead of building layouts from scratch; check them through the shadcn MCP or registry.

**Self-review:** after implementing a visual change, take screenshots at mobile and desktop widths (see `verification.md`) and check them against this list. Fix misalignments, inconsistent spacing, overflow and missing states before reporting.

## Accessibility in React / Next.js

Accessibility is mandatory for user-facing UI. In addition to the parent principles:

- shadcn/ui primitives provide keyboard and ARIA behavior; do not break it by replacing the underlying elements or removing focus styles.
- Icon-only buttons need an accessible name (`aria-label` or visually hidden text).
- Use `htmlFor` (not `for`) and generate stable ids with `useId` for label/input and `aria-describedby` associations (avoid random ids that break hydration).
- **Route changes in the App Router:** make sure focus and announcements work for client-side navigations (page title updates, focus moved to the main heading or content when appropriate).
- Form errors from Server Actions must be associated with fields (`aria-invalid`, `aria-describedby`) and summarized or focused on submit.
- Loading states: communicate pending status (`aria-busy`, disabled with visible feedback, live region for async results).
- Respect `prefers-reduced-motion` in animations (Tailwind `motion-safe:` / `motion-reduce:` variants).

Do not sacrifice accessibility for visual or performance convenience without explicitly evaluating the trade-off.
