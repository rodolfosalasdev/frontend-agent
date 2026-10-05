# Next.js: Data Fetching, Server Functions and API Integration

General HTTP and API principles live in `~/.cursor/skills/frontend-agent/principles/http.md`. This file covers the Next.js-specific parts.

## Where to fetch

| Location | Use when |
|---|---|
| Server Component | Data needed for the initial render; access to secrets or internal services; SEO-relevant content |
| Route Handler (`app/**/route.ts`) | A public HTTP endpoint is needed (webhooks, third-party consumers, client fetches, non-React clients) |
| Server Function / Server Action | Mutations triggered by the UI (forms, buttons) |
| Client Component | Data that depends on client interaction after load (live search, polling, infinite scroll), or user-specific data that should not block the page. See "Server state on the client" below |
| Pages Router data functions | `getServerSideProps` / `getStaticProps` in Pages Router projects |

Rules:

- Do not fetch in a Client Component when a server-side solution fits better.
- Do not force everything onto the server when the requirement is client-driven.
- **Do not call your own Route Handlers from Server Components.** Call the underlying data function directly; an HTTP round trip to yourself adds latency and failure modes.
- Respect the project's API integration conventions (API clients, BFF, data layer). Do not bypass them.

## Avoiding waterfalls

- Start independent requests in parallel (`Promise.all` or initiate promises before awaiting).
- Sequential `await`s across nested layouts and pages create waterfalls; evaluate hoisting, parallel fetching, or passing promises down and resolving them with `use` / Suspense (check support for the installed React version).
- Deduplicate repeated reads of the same data within a request with `React.cache` (or rely on the framework's request memoization where it applies for the installed version).

## Server state on the client (TanStack Query)

TanStack Query (formerly React Query) is the **preferred library** for server state on the client, **used by criteria, not by default**.

### When to use

- Data that changes on the client after load: polling, live dashboards, refetch on window focus.
- Infinite scroll and cursor-based "load more".
- Mutations with cache invalidation and optimistic updates.
- Tables filtered on the client with frequent parameter changes (see `tables.md`).
- Pages Router or SPA-style sections without Server Components.

### When not to use

- Data that Server Components already render and Next.js already caches. Adding Query there only ships more client JavaScript and a second cache.
- One-off reads with no client-side refresh needs.

### Simple periodic refresh: compare before choosing

For a server-rendered page that only needs to refresh periodically, a zero-dependency option exists: a small Client Component calling `router.refresh()` on an interval (paused while the tab is hidden). Compare:

| | `router.refresh()` polling | TanStack Query polling |
|---|---|---|
| Dependency | None | New dependency (needs confirmation) |
| What is refetched | The whole route's server render (RSC payload) | Only the specific query's data |
| Granularity | Entire page | Per widget, with independent intervals |
| Secrets / tokens | Stay on the server | Client needs an endpoint it can call (Route Handler or BFF) |
| Best for | Small dashboards, one data source, low frequency | Several independently refreshing widgets, high frequency, mutations with optimistic updates, infinite scroll |

Recommend the simpler option when it meets the requirement, and state the alternative with its trade-off.

### Introduction rules

- It is a new dependency: **ask for confirmation** before installing.
- If the project already uses it, follow its existing setup (provider location, `QueryClient` defaults, key conventions).
- If the project uses another server-state library (e.g. SWR), use that one. Do not add a second.
- Check the installed major version: the API changed between v4 and v5 (e.g. `cacheTime` renamed to `gcTime`, `keepPreviousData` option replaced by `placeholderData: keepPreviousData`, single object signature for hooks). Use the docs for the installed version.

### One owner per piece of data

| Cache | Where | Shared across users | Reduces load on the API across users |
|---|---|---|---|
| Next.js server caching (`caching.md`) | Server | Yes (for non-personalized data) | Yes |
| TanStack Query cache | Browser memory | No, per user and tab | No, only avoids duplicate requests from the same browser |

For each piece of data, decide which layer owns freshness. Two layers refreshing the same data independently produce stale-data bugs that are hard to trace.

### Configuration

- **`staleTime` defaults to 0**: data is considered stale immediately and refetched on mount, window focus and reconnect. Set it deliberately per query or per `QueryClient` according to how fresh the data must be.
- With SSR and hydration, use a `staleTime` above 0 so the client does not refetch immediately after hydrating.
- `refetchInterval` for polling; pause it when the tab is hidden unless real-time is required.
- Keep retries sensible; do not retry `4xx` validation or authorization errors.

### Integration with Server Components (App Router)

- **Prefetch on the server, hydrate on the client:** in a Server Component, create a `QueryClient`, `prefetchQuery`, then pass `dehydrate(queryClient)` to a `HydrationBoundary` wrapping the Client Components that call `useQuery` with the same key. The first render has data and no loading flash.
- **A new `QueryClient` per request on the server**, never a module-level singleton: a shared server client leaks data between users.
- **A single `QueryClient` in the browser**, created once (e.g. lazily in the provider) so it survives re-renders and suspensions.
- The provider (`QueryClientProvider`) is a small Client Component placed as deep as possible, wrapping `children`.
- The query function should call the same data layer or API client used on the server, respecting the project's API boundaries.

### Query keys

- Include **every parameter that affects the result** in the `queryKey` (filters, page, sort, user scope). A missing parameter returns wrong cached data.
- For tables, the parsed URL search params go into the key; the URL stays the source of truth (see `tables.md`).
- Centralize key construction (query key factories or `queryOptions`) so invalidation targets the right entries.

### Mutations

- Invalidate or update the affected queries after a successful mutation.
- Optimistic updates only for low-risk, high-frequency actions, always with rollback on error.
- If the mutation goes through a Server Action, it still enforces validation and authorization server-side (see "Security rules" below).

### Rendering performance

- Structural sharing and tracked properties are on by default and already avoid many re-renders.
- Use `select` to subscribe to a derived slice only when a measurable re-render cost exists.
- Do not copy query data into `useState`; read it from the query.

### Prefetching

- Prefetch on hover/focus of a link or before opening a screen **only for likely flows**; indiscriminate prefetching wastes requests and server capacity.
- In the App Router, prefer server-side prefetch + hydration for the initial view.

## Data layer

For non-trivial apps, prefer a server-side data access layer:

- centralizes data access, authorization checks and DTO mapping;
- marked with `import 'server-only'`;
- returns only the fields the UI needs (avoid leaking full records to Client Components);
- keeps DTO, domain and view models separate when they diverge.

## Server Functions / Server Actions

Semantics depend on the installed Next.js and React versions. Before using them, evaluate:

- whether the operation really belongs on the server;
- input validation (the payload comes from the client and can be forged);
- authentication and **authorization inside the function**;
- error handling and what is returned to the client;
- serialization of arguments and return values;
- side effects and idempotency;
- cache invalidation after the mutation (see `caching.md`);
- progressive enhancement for forms when relevant.

### Security rules (non-negotiable)

- **Every Server Action is a public endpoint.** Anyone can call it with arbitrary arguments, regardless of whether the UI shows the button. Validate input and check authorization inside every action.
- Proxy / middleware checks are not sufficient on their own. Verify the session and permissions close to the data access.
- Do not return sensitive data or internal error details.
- Values captured in closures of inline Server Actions are sent to the client (encrypted by the framework in recent versions), so avoid closing over sensitive data.
- Check the configuration for allowed origins and body size limits when relevant for the installed version.

### When not to use Server Actions

- Public APIs consumed by other clients → Route Handlers or the backend API.
- Data reads for rendering → Server Components.
- High-frequency reads from the client → a proper endpoint with caching.

Never treat Server Actions as a replacement for the whole API architecture.

### Form ergonomics

- Use the React form hooks available for the installed version (e.g. pending state and action state hooks) instead of hand-rolled loading flags.
- Return validation errors as data mapped to fields; keep them accessible (see `ui.md` and the parent `accessibility.md`).

## Route Handlers

- Use Web `Request` / `Response` APIs (and `NextRequest` / `NextResponse` helpers when needed).
- Validate input, authenticate and authorize as in any public endpoint.
- Set caching headers explicitly for public responses.
- Default caching of GET handlers differs across versions: confirm for the installed version.

## Error handling

- **Route-level:** `error.tsx` (must be a Client Component) for segment errors, `global-error.tsx` for the root layout, `not-found.tsx` with `notFound()`.
- **Redirects:** `redirect()` / `permanentRedirect()` work by throwing; do not wrap them in `try/catch` that swallows the throw.
- **Expected errors** (validation, not found, forbidden): return them as values or render specific UI. Do not rely on error boundaries for expected cases.
- **Unexpected errors:** let them reach error boundaries; log them server-side with context; never expose stack traces or internal messages to users.
- Handle loading, empty and error states explicitly for every data dependency.
- Distinguish authentication failures (redirect to login) from authorization failures (forbidden UI). Check whether the installed version offers dedicated helpers for these before building custom ones.

## External APIs and BFF

- Secrets and third-party tokens stay on the server (Server Components, Server Actions, Route Handlers).
- Timeouts and cancellation: server-side `fetch` has no default timeout; use `AbortSignal.timeout()` for slow upstreams.
- Retries only for idempotent operations and transient failures.
- Consider whether Next.js is acting as a BFF; if so, keep the contract with the backend explicit and versioned.
