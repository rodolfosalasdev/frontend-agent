# Next.js: Rendering, Server and Client Components

Applies to the App Router unless stated otherwise. For the Pages Router, see `routing.md`.

## Server Components (default in the App Router)

Prefer Server Components when they meet the requirement. They are a good fit for:

- server-side data fetching close to the data source;
- accessing server-only resources (databases, internal services, secrets);
- rendering content without shipping its JavaScript to the client;
- streaming with Suspense;
- composing server data with client islands.

Server Components cannot use state, effects, event handlers, browser APIs or client-only hooks.

## Client Components

Use a Client Component only when the component needs:

- state (`useState`, `useReducer`);
- event handlers;
- effects or lifecycle behavior;
- browser APIs (`window`, `localStorage`, observers);
- client-only hooks or libraries that depend on them;
- React Context providers.

Client Components are still prerendered on the server (SSR) for the initial HTML and then hydrated. `"use client"` does not mean "client-rendered only".

## `"use client"` rules

Do not add `"use client"` automatically. Before adding it:

1. Identify exactly why the component needs client execution.
2. Isolate that need into the **smallest** possible component (e.g. only the button with `onClick`, not the whole page).
3. Remember that `"use client"` marks a **module boundary**: every module imported from that file becomes part of the client bundle.
4. Keep static and data-heavy parts as Server Components.
5. Explain the reason when the boundary has architectural or performance impact.

Do not claim that one Client Component makes the whole application client-rendered. Only its subtree of imports enters the client module graph.

### Composition patterns

- **Pass Server Components as `children` or props** to Client Components. They stay server-rendered even inside a client wrapper.
- **Providers:** put Context providers in a small Client Component and render it as deep in the tree as possible, wrapping `children`.
- **Props crossing the boundary** must be serializable by React (plain data, Dates and other supported types, Server Functions). Functions and class instances cannot be passed from server to client, except Server Functions.
- **Third-party components** that use client features without `"use client"` must be wrapped in your own Client Component.

## Keeping server code on the server

- Import `server-only` in modules that must never reach the client (database access, secrets, internal APIs). The build fails if they are imported into a Client Component.
- Environment variables without the `NEXT_PUBLIC_` prefix are only available on the server. `NEXT_PUBLIC_` variables are **inlined into the client bundle at build time**: never put secrets there.
- Do not pass entire server objects (e.g. full user records) to Client Components; pass only the fields the UI needs.

## Rendering strategy

Decide deliberately. Ask:

1. Does the page need request-specific data (cookies, headers, search params, user)?
2. Does it require authentication or personalization?
3. How often does the data change, and how stale can it be?
4. Can the result be cached and shared across users?
5. Is it suitable for static or prerendered output?
6. Does the UI need browser APIs or client state?
7. Are there slow data dependencies that should not block the whole page?
8. What is the impact on the user experience (LCP, INP, perceived speed)?

| Strategy | Good for | Watch out for |
|---|---|---|
| Static / prerendered | Content identical for all users, changes rarely | Stale data; needs revalidation strategy |
| Static with revalidation | Content that changes periodically | Staleness window; invalidation after mutations |
| Dynamic (per request) | Personalized or request-dependent pages | TTFB depends on the slowest data; consider streaming |
| Streaming with Suspense | Pages mixing fast and slow data | Boundary placement; layout shifts from fallbacks |
| Client rendering | Highly interactive, user-specific widgets after load | Larger bundle, loading states, SEO for that content |

Using request-time APIs (cookies, headers, search params, uncached data) opts a route or segment into dynamic behavior. How this interacts with prerendering depends on the version and on whether Cache Components is enabled: check `caching.md` and the docs for the installed version.

Do not select a strategy based on popularity.

## Streaming and Suspense

- `loading.tsx` creates a Suspense boundary for a route segment; explicit `<Suspense>` gives finer control.
- Place boundaries around slow, independent sections so fast content is not blocked.
- Fallbacks should reserve space (skeletons with stable dimensions) to avoid CLS.
- Do not wrap everything in Suspense: too many boundaries fragment the loading experience.
- Start independent data requests in parallel; Suspense does not remove waterfalls created by sequential `await`s in the same component.

## Hydration

Hydration mismatches happen when server HTML differs from the first client render. Common causes:

- values that differ between server and client (`Date.now()`, `Math.random()`, locale or timezone formatting);
- reading browser-only APIs during render (`window`, `localStorage`);
- invalid HTML nesting (e.g. `<div>` inside `<p>`, nested `<a>`);
- browser extensions modifying the DOM.

Fixes, in order of preference:

1. Make the render deterministic (pass the value from the server, format with a fixed locale/timezone).
2. Move browser-only reads into an effect or event handler.
3. Load a truly client-only component without SSR using `next/dynamic` with `ssr: false` (only allowed inside Client Components in recent versions; confirm for the installed version).
4. `suppressHydrationWarning` only for unavoidable single-element differences (e.g. timestamps), never to hide real bugs.

Hydration cost also matters for INP and TBT: less client JavaScript means faster hydration.
