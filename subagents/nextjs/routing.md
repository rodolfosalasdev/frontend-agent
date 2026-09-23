# Next.js: Routing, Proxy / Middleware, Metadata and SEO

## App Router vs Pages Router

Do not assume a Pages Router project should migrate to the App Router.

When a project uses the Pages Router:

1. Understand the existing architecture and the actual requirement.
2. Solve it within the Pages Router when possible (`getServerSideProps`, `getStaticProps`, `getStaticPaths`, ISR, API routes, `_app`, `_document`).
3. Evaluate migration only if the requirement truly needs App Router capabilities.
4. If migration is justified, propose it incrementally (both routers can coexist) with cost, risks and compatibility notes, and get confirmation.

When a project uses the App Router, apply the official patterns for the installed version.

## App Router file conventions

Use them for their purpose, not by default:

- `layout.tsx`: shared UI that persists across navigations in a segment (does not re-render on navigation between children).
- `template.tsx`: like a layout but remounts on navigation (use only when that behavior is needed).
- `page.tsx`: the route UI.
- `loading.tsx`: Suspense fallback for the segment.
- `error.tsx`: error boundary for the segment (Client Component).
- `not-found.tsx`: UI for `notFound()`.
- `route.ts`: Route Handler (cannot coexist with `page.tsx` in the same segment).
- `default.tsx`: fallback for parallel route slots.

Request APIs (`params`, `searchParams`, `cookies()`, `headers()`) are synchronous or asynchronous depending on the version: check `versions.md`.

## Routing structure

Choose structure based on domain boundaries, user flows, shared layouts, loading and error behavior, SEO and performance.

- **Route groups** `(group)`: organize routes or apply different layouts without affecting the URL.
- **Dynamic segments** `[id]`, catch-all `[...slug]`, optional catch-all `[[...slug]]`.
- **Parallel routes** `@slot`: independent sections rendered simultaneously (dashboards, split views).
- **Intercepting routes** `(.)`, `(..)`: show a route in the current context (e.g. modal) while keeping a shareable URL.
- **Private folders** `_folder`: colocate non-route files.

Do not introduce parallel or intercepting routes without a clear requirement; they add real complexity.

Keep route-relevant state in the URL (search params) when users expect to share, reload or go back. For tables and lists, follow `tables.md`.

## Navigation and prefetching

- Use `next/link` for internal navigation; prefetching behavior differs between development and production and across versions.
- For programmatic navigation, use the router hook from `next/navigation` (App Router) or `next/router` (Pages Router). Do not mix them.
- Consider disabling prefetch only for links where prefetching is wasteful (very large lists, rarely visited routes), based on evidence.

## Redirects and rewrites

- Static redirects/rewrites: `next.config` (`redirects`, `rewrites`).
- Conditional, request-based logic: proxy / middleware.
- Inside rendering or Server Actions: `redirect()` / `permanentRedirect()`, `notFound()`.

## Proxy / Middleware

The file convention and runtime changed across versions (`middleware.ts` vs `proxy.ts`). Detect which one the installed version uses and which one the project has.

Use it for lightweight, request-level concerns: redirects, rewrites, header manipulation, locale detection, coarse auth gating (e.g. redirect unauthenticated users).

Rules:

- Keep it fast: it runs on matching requests before rendering. Use a `matcher` to limit where it runs.
- **It is not a complete authorization layer.** Always enforce authorization again in the data layer, Server Actions and Route Handlers.
- Avoid heavy data fetching or database access in it.

## Metadata and SEO

- Use the Metadata API for the installed version: static `metadata` export or `generateMetadata` for dynamic values, in Server Components only (layouts and pages).
- Metadata is merged from the root layout down; define defaults (title template, base URL for absolute URLs) in the root layout.
- Canonical URLs, Open Graph, Twitter cards and robots directives through metadata fields.
- File conventions for `sitemap`, `robots`, `icon`, `opengraph-image` when supported by the installed version.
- Structured data (JSON-LD) rendered in a `<script type="application/ld+json">`; serialize safely to avoid injection.
- `generateMetadata` that fetches data should reuse the same (memoized/cached) data function as the page to avoid duplicate requests.
- Dynamic metadata makes the route depend on that data; make sure it is compatible with the rendering and caching strategy.
- SEO also depends on semantic HTML, server-rendered content for indexable pages and performance.

Do not prioritize SEO work without considering the app's real requirements (an authenticated dashboard rarely needs it).

## Pages Router specifics

- `getServerSideProps`: per-request data; increases TTFB.
- `getStaticProps` + `revalidate`: static with ISR.
- `getStaticPaths`: which dynamic paths to prerender and the `fallback` behavior.
- API routes (`pages/api`): Node.js request handlers; apply the same security rules as Route Handlers.
- `_app`: global layout, providers, global CSS. `_document`: HTML shell only (no data fetching, no event handlers).
- Metadata via `next/head`.
