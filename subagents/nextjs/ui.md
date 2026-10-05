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

The four states, form feedback and when they apply are in `~/.cursor/skills/frontend-agent/principles/css-ui.md` ("Estados de UX"). Apply them only to a data view or form the task creates or changes. In Next.js, implement them as:

- **Loading:** `loading.tsx` or a `<Suspense>` fallback whose skeleton matches the final layout. Do not add a root `loading.tsx` unless the whole app should suspend.
- **Error:** `error.tsx` for the segment, with a retry. On 16.3+ the prop is `retry` (re-fetches); `reset` still exists but does not re-fetch. Check `error.md` in the bundled docs for the installed version.
- **Empty and success:** rendered by the page or the component that owns the data.
- **Forms:** pending via `useActionState` or `useTransition`; field errors from the Server Action associated with inputs. See `examples/form-with-pending-and-errors.md`.
- **Destructive actions:** confirm with the project's dialog (commonly shadcn `AlertDialog`).
- **Toasts:** the project's solution (commonly `sonner` in shadcn/ui). Toasts complement inline errors; they must not be the only place critical information appears.

## Visual quality

Follow "Qualidade visual" in `~/.cursor/skills/frontend-agent/principles/css-ui.md`, then the project's tokens. Next.js additions:

- Prefer the project's shadcn/ui components and blocks over layouts built from scratch. Look them up through the shadcn MCP or registry instead of writing them from memory.
- Secondary actions use the quieter variant the project already has (`outline`, `ghost`).
- Respect `prefers-reduced-motion` with Tailwind `motion-safe:` / `motion-reduce:` when the project uses Tailwind.

**Self-review:** after a visual change, take screenshots at mobile and desktop widths (see `verification.md`) and check them against that principle. Fix misalignment, inconsistent spacing, overflow and a missing state before reporting.

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
