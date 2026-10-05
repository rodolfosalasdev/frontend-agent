# Next.js: Performance

General performance principles (diagnostic rule, Core Web Vitals, network, rendering) live in `~/.cursor/skills/frontend-agent/principles/performance.md`. This file covers what is specific to Next.js and React.

## Diagnostic rule

```text
Symptom → Measurement → Hypothesis → Root cause → Solution → Validation
```

- Do not recommend an optimization without naming the problem and the metric it addresses.
- Distinguish lab data, real user monitoring (RUM), development behavior and production behavior.
- **Measure production builds** (`next build` + `next start` or a deployed preview). `next dev` is slower and behaves differently.
- Do not claim a change improved performance without evidence.

## Default budgets (parameterizable)

Unless the project's `architecture.md` defines its own, aim for:

| Budget | Target |
|---|---|
| LCP, INP, CLS | Within the "good" thresholds published on web.dev (check the current values there; measure at the 75th percentile of real users when field data exists) |
| Client JavaScript per route | No regression: measure the affected routes before and after with the bundle analyzer; justify any increase in the report |
| Request waterfalls on the critical path | None introduced |
| Route rendering mode | Unchanged unless intended (a static route must not silently become dynamic) |

Measure with `pnpm next experimental-analyze` (Turbopack, Next.js 16.1+) or `@next/bundle-analyzer` (webpack), and with Lighthouse or the browser performance panel against a production build. Report numbers, not impressions.

## Client JavaScript

The largest lever in Next.js is usually **how much JavaScript ships to the client**.

- Keep `"use client"` boundaries small and low in the tree (see `rendering.md`).
- Check what a client module imports: a heavy library imported in a Client Component ships to every user of that route.
- Move data transformation, formatting libraries and markdown/syntax highlighting to the server when the output is static.
- Use `next/dynamic` or `import()` for heavy client-only components that are not needed for the initial view (charts, editors, maps, modals).
- Analyze the bundle with the analyzer available for the project's bundler and version before cutting.
- Prefer native or lightweight alternatives to large dependencies.
- **Barrel-file libraries** (icon sets, utility libraries exporting thousands of modules): Next.js optimizes some popular packages automatically; for others, `experimental.optimizePackageImports` loads only the modules actually used. It is an experimental option: check the bundled docs and report it as such.

## Hydration cost

- Hydration runs the client code for every Client Component in the initial view; large client trees hurt INP and TBT.
- Server Components do not hydrate. Converting static parts to Server Components reduces hydration work.
- Avoid rendering large lists entirely as Client Components when only a small part is interactive.

## Data and TTFB

- Waterfalls in Server Components directly increase TTFB and LCP (see `data-fetching.md`).
- Stream slow sections with Suspense instead of blocking the entire page.
- Cache what can be shared (see `caching.md`); dynamic rendering of cacheable content wastes server time.
- Keep serialized props to Client Components small: large RSC payloads increase transfer and parse time.
- **Non-blocking side effects:** use `after()` for logging, analytics, audit trails and webhooks that must run but should not delay the response. It works in Server Components, Server Functions, Route Handlers and Proxy.
- **Static shell for new projects:** when the installed version supports Cache Components and the project is new (or the team agrees to migrate), prefer it: cached content becomes part of a prerendered static shell and request-time parts stream in behind Suspense. For existing projects, migration changes `next.config` and caching behavior: propose it, do not apply it silently (see `caching.md`).
- **Runtime and region:** use the default Node.js runtime. `export const runtime = 'edge'` is deprecated in recent versions; check the bundled docs before using it. Latency to the data source usually matters more than the runtime: deploy functions close to the database (`preferredRegion` where the platform supports it).

## Images (`next/image`)

- Always provide dimensions (`width`/`height`) or use `fill` with a sized parent to prevent CLS.
- Set `sizes` for responsive images so the browser does not download oversized files.
- **Mark only the LCP image** as high priority. In Next.js 16 the `priority` prop is deprecated; the docs recommend `fetchPriority="high"` or `loading="eager"` in most cases (and `preload` only when needed). Confirm for the installed version. Never mark many images this way.
- Images below the fold are lazy by default; do not lazy-load the LCP image.
- Configure `images.remotePatterns` narrowly for remote images.
- Meaningful `alt` text for informative images, empty `alt` for decorative ones.
- Image optimization behavior depends on the deployment target (self-hosted needs the optimizer available; static export needs a loader or unoptimized images).

## Fonts (`next/font`)

- Use `next/font` to self-host fonts with automatic size-adjusted fallbacks (reduces CLS and removes third-party connections).
- Load fonts once (root layout or a shared module) and reuse the instance; defining the same font in many files duplicates work.
- Limit families, weights and subsets; prefer variable fonts.
- Expose fonts as CSS variables to integrate with Tailwind.

## Scripts

- Use `next/script` with an appropriate loading strategy for third-party scripts; defer everything non-essential.
- For supported integrations (Google Tag Manager, Google Analytics, YouTube and Google Maps embeds, among others), prefer `@next/third-parties`, which loads them in a performance-optimized way. It is a new dependency: confirm before adding.
- Measure each third-party script's impact; they are frequently the largest INP and TBT cost.

## Interaction responsiveness

- `useDeferredValue` for search inputs that filter large lists on the client: the input stays responsive while the list re-renders.
- `useTransition` around navigations and non-urgent updates (e.g. URL filter changes) to show a pending state without blocking input.
- Break long client work into smaller chunks or move it to a Web Worker.

## React-level performance

See `react.md`: state placement, component boundaries, effects, memoization and React Compiler.

## Core Web Vitals in Next.js, quick map

| Metric | Common Next.js causes | Direction |
|---|---|---|
| LCP | Slow server data (waterfalls), LCP image not prioritized, client-rendered hero, render-blocking fonts/CSS | Parallel/cached data, stream the rest, prioritize the LCP image, server-render the hero |
| INP | Large hydration, heavy client handlers, re-render cascades, third-party scripts | Smaller client boundaries, transitions for non-urgent updates, move work off the main thread |
| CLS | Images without dimensions, Suspense fallbacks with different size, font swaps, injected banners | Dimensions and `sizes`, skeletons with stable size, `next/font`, reserved space |
| TTFB | Dynamic rendering of cacheable content, slow upstreams, proxy / middleware work | Caching, streaming, lighter proxy logic, closer data sources |
