# Next.js: Anti-patterns

Scan this list **before delivering** any implementation and in **every code review**. Each item: what to look for, why it hurts, how to fix.

Version notes refer to Next.js 16.x; confirm details in the bundled docs (`node_modules/next/dist/docs/`) for the installed version.

## Rendering and boundaries

### 1. Request-time APIs in the root layout

- **Look for:** `cookies()`, `headers()`, `searchParams` or uncached data read in `app/layout.tsx` (or a high-level layout).
- **Why:** request-time APIs opt the route into dynamic rendering. In the root layout this makes **every route** dynamic, losing prerendering and increasing TTFB everywhere.
- **Fix:** read them in the specific page or in a small component inside a Suspense boundary; move per-user UI (e.g. avatar) into a streamed component.

### 2. `"use client"` on a layout or an entire page

- **Look for:** `"use client"` at the top of `layout.tsx` or `page.tsx`.
- **Why:** everything the file imports enters the client bundle; data fetching moves to the client; hydration cost grows.
- **Fix:** keep the page/layout as a Server Component and extract only the interactive part into a small Client Component (see `rendering.md`, `examples/server-page-client-island.md`).

### 3. Context provider at the root with a frequently changing value

- **Look for:** providers in the root layout whose `value` changes often (timers, form state, mouse position) or is recreated every render.
- **Why:** every consumer re-renders on every change; INP suffers.
- **Fix:** place providers as deep as possible, split contexts by update frequency, keep fast-changing state local.

### 4. Large props crossing into Client Components

- **Look for:** full database records, large arrays or whole API responses passed as props to Client Components.
- **Why:** everything is serialized into the RSC payload (transfer + parse cost) and may leak fields the UI does not need.
- **Fix:** pass only the fields the component uses; paginate; keep heavy rendering on the server.

### 5. `next/dynamic` for above-the-fold content

- **Look for:** `dynamic(() => import(...))` for the hero, header, main content or the LCP element.
- **Why:** delays the content users see first; hurts LCP and may cause layout shift.
- **Fix:** import above-the-fold components normally; reserve `next/dynamic` for heavy, below-the-fold or interaction-triggered components.

### 6. Hydration-unsafe rendering

- **Look for:** `Date.now()`, `Math.random()`, locale-dependent formatting without a fixed locale/timezone, `window`/`localStorage` read during render, invalid HTML nesting.
- **Why:** hydration mismatches, flicker, console errors, extra client work.
- **Fix:** deterministic render; browser-only reads in effects or event handlers; `suppressHydrationWarning` only for unavoidable single-element differences.

## Data fetching and caching

### 7. `fetch` inside `useEffect` for data the server could fetch

- **Look for:** `useEffect(() => { fetch(...).then(setState) }, [])` in App Router pages.
- **Why:** empty HTML, extra round trip, loading flash, no SEO, more client JS, race conditions.
- **Fix:** fetch in a Server Component; if client-side behavior is really required, follow `data-fetching.md` (TanStack Query by criteria).

### 8. Sequential `await`s for independent data

- **Look for:** `const a = await getA(); const b = await getB();` where `b` does not depend on `a`, including across nested layouts and pages.
- **Why:** waterfall: TTFB and LCP become the sum of all latencies.
- **Fix:** start in parallel (`Promise.all`), or stream independent sections with Suspense.

### 9. Calling your own Route Handlers from Server Components

- **Look for:** `fetch('/api/...')` or `fetch('http://localhost:3000/api/...')` in Server Components.
- **Why:** an extra HTTP hop to yourself, fragile URLs, duplicated auth.
- **Fix:** call the data function directly.

### 10. Personalized data in a shared cache

- **Look for:** `"use cache"`, cached fetches or cached functions returning user-specific data (session, cart, permissions) without the user being part of the cache scope.
- **Why:** one user's data served to another. Critical security bug.
- **Fix:** keep personalized reads dynamic (streamed), or use the per-user variant documented for the installed version (e.g. `"use cache: private"` with Cache Components; read its constraints in the bundled docs).

### 11. Missing or deprecated invalidation after mutations

- **Look for:** mutations without invalidation; `revalidateTag(tag)` with a single argument (deprecated in Next.js 16).
- **Why:** users do not see their own changes; deprecated signatures may break on upgrade.
- **Fix:** in Server Actions, `updateTag(tag)` for read-your-own-writes; elsewhere `revalidateTag(tag, 'max')` (stale-while-revalidate) or `revalidatePath`. Confirm signatures in the bundled docs.

### 12. Deciding cache behavior from `next dev`

- **Look for:** conclusions about caching or performance based only on development mode.
- **Why:** dev mode disables or changes caching and prefetching and is much slower.
- **Fix:** reproduce with `next build` + `next start`.

## Security

### 13. Server Action or Route Handler without validation and authorization

- **Look for:** actions/handlers that use their arguments directly and do not check the session and permissions.
- **Why:** they are public endpoints; hiding the button is not authorization.
- **Fix:** validate input, authenticate and authorize **inside** every action/handler (see `examples/server-action.md`).

### 14. Secrets in `NEXT_PUBLIC_` variables or client modules

- **Look for:** API keys or tokens in `NEXT_PUBLIC_*`, or server modules imported by Client Components.
- **Why:** `NEXT_PUBLIC_` values are inlined into the client bundle.
- **Fix:** keep secrets in server-only env vars; mark server modules with `import 'server-only'`.

### 15. Authorization only in `proxy` (formerly `middleware`)

- **Look for:** access control implemented only in `proxy.ts` / `middleware.ts`.
- **Why:** proxy checks are coarse and can be bypassed by paths that do not match the `matcher`; data access is unprotected.
- **Fix:** keep proxy for redirects/coarse gating and enforce authorization in the data layer, Server Actions and Route Handlers. Note: `middleware` is deprecated and renamed to `proxy` in Next.js 16.

## React

### 16. Effects for derived state or event responses

- **Look for:** `useEffect` that sets state computed from props/state, or that reacts to something a user event already handles.
- **Why:** extra renders, flicker, bugs from stale synchronization.
- **Fix:** compute during render; act in the event handler; reset with `key` (see `react.md`).

### 17. Memoization without evidence (or redundant with the React Compiler)

- **Look for:** `useMemo`/`useCallback`/`memo` everywhere, especially when `reactCompiler` is enabled.
- **Why:** complexity with no measured gain.
- **Fix:** measure first; prefer structural fixes; rely on the compiler when enabled.

### 18. Copying server/query data into local state

- **Look for:** `useState(props.data)` or copying TanStack Query results into `useState`.
- **Why:** two sources of truth that drift apart.
- **Fix:** read from the source; keep only genuinely editable draft state locally.

## Images, fonts and scripts

### 19. Image priority misuse

- **Look for:** many images marked as high priority; the LCP image lazy-loaded; `priority` prop (deprecated since Next.js 16).
- **Why:** competing high-priority downloads, slower LCP.
- **Fix:** only the LCP image gets `fetchPriority="high"` or `loading="eager"` (the docs recommend these over `preload` in most cases); everything else stays lazy.

### 20. Images without dimensions or `sizes`

- **Look for:** `<Image>` without `width`/`height` (or `fill` without a sized parent); responsive images without `sizes`.
- **Why:** CLS; oversized downloads on mobile.
- **Fix:** always set dimensions; set `sizes` for responsive layouts.

### 21. Fonts and third-party scripts loaded ad hoc

- **Look for:** `<link>` to Google Fonts, the same `next/font` declared in many files, raw `<script>` tags for analytics/tag managers/embeds.
- **Why:** extra connections, CLS from font swaps, main-thread blocking.
- **Fix:** `next/font` declared once and reused; `next/script` with the right strategy; `@next/third-parties` for supported integrations.

## UX completeness

### 22. Missing states

- **Look for:** data views without loading, empty or error states; forms without pending state or field errors.
- **Why:** blank screens, double submissions, confusion. This is the most visible gap between a prototype and a product.
- **Fix:** follow the Definition of done in `agent.md` and the UX states in `ui.md`.
