# Next.js: Verification

Verification turns "I think it works" into "I saw it work". Run what applies to the change, in this order, and **report exactly what ran and what did not**.

Always prefer the project's scripts in `package.json`. The commands below use `pnpm`; use the project's package manager.

## 1. Static checks

| Check | Command (Next.js 16.x; confirm in the bundled CLI docs) |
|---|---|
| Route types + typecheck | `pnpm next typegen && pnpm tsc --noEmit` (or the project's `typecheck` script) |
| Lint | the project's `lint` script (Next.js 16 uses the ESLint CLI directly; `next lint` is not the default) |
| Unit / component tests | the project's `test` script, scoped to the affected files when possible |

## 2. Compilation feedback during development

If `next-devtools-mcp` tools are available in your session and `next dev` is running, use them to check compilation issues, compile specific routes, and read runtime errors and server logs. This is faster than a full build for iterating.

## 3. Production build

Run `pnpm build` when the change can affect routing, rendering mode, caching, config, or the bundle.

Check in the output:

- the build succeeds without new warnings;
- each route's rendering mode (prerendered/static vs dynamic) is what you intended. A route becoming dynamic unexpectedly usually means a request-time API leaked into a layout or page (see `anti-patterns.md` #1).

For bundle size questions: `pnpm next experimental-analyze` (Turbopack analyzer, Next.js 16.1+) or `@next/bundle-analyzer` (webpack). Compare before and after for the affected routes.

## 4. Browser verification

Run against a production server (`pnpm build && pnpm start`) when behavior depends on caching, prefetching or performance; `next dev` is acceptable for pure layout and interaction checks.

If you have browser tools (e.g. the Cursor browser), verify:

1. **Visual:** screenshots at **375px** (mobile) and **1280px** (desktop) widths. Check alignment, spacing, overflow, text wrapping, empty/error/loading states.
2. **Console:** no hydration errors, no React warnings, no uncaught errors.
3. **Keyboard:** Tab through the page. Every interactive element is reachable, the order is logical, focus is always visible, dialogs trap and restore focus, Escape closes overlays.
4. **Network:** no request waterfalls on load, no duplicate requests, no unexpectedly large payloads, correct cache headers for public assets.
5. **States:** force the empty and error states (e.g. mock data, invalid params) and confirm they render correctly.
6. **URL state (tables/lists):** copy the URL after filtering, open it in a new tab, confirm the same view (see `tables.md`).

Self-review the screenshots against `ui.md` ("Visual quality") and fix issues before reporting.

## 5. When verification is not possible

If dependencies are not installed, the build cannot run, or you have no browser tools:

- do not install dependencies without confirmation;
- list in the report which checks were **not run** and why, e.g. `visual verification not run: no browser tools in this session`;
- the Frontend Agent is responsible for the visual verification fallback when it has browser tools.

Never claim a check passed unless it actually ran.
