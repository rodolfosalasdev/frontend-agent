# Next.js: Testing, Code Review, Refactoring and Observability

General testing strategy and the base code review checklist live in the Frontend Agent's `principles/testing.md`. This file covers Next.js specifics.

## Testing

Use the project's established tools and conventions. Do not introduce a new test runner without confirmation.

| What | Suitable level |
|---|---|
| Domain logic, formatters, data mappers, validation schemas | Unit |
| Client Components (interaction, states, accessibility) | Component tests with the project's runner and Testing Library-style queries by role and name |
| Synchronous Server Components | Component tests may work; check the tooling support |
| **Async Server Components** | Unit tooling support is limited; prefer E2E for their behavior (confirm current tooling support in the docs) |
| Server Actions and data layer | Test the underlying functions directly (validation, authorization, side effects) |
| Route Handlers | Call the handler with a `Request` and assert on the `Response` |
| Routing, streaming, caching, redirects, auth flows | E2E against a production build |

Rules:

- Cover loading, empty and error states, not only the happy path.
- Test authorization paths of Server Actions and Route Handlers (unauthenticated, forbidden, invalid input).
- Mock at the boundary (network, time), not internal modules.
- E2E tests run against `next build` + `next start` (or a preview deploy) to reflect production caching and rendering.
- Avoid tests coupled to implementation details (internal state, hook internals, class names).

## Code review (Next.js additions)

Apply the parent review checklist, and also check:

1. **Versions and router:** are the APIs correct for the installed Next.js / React versions and for the router of that file?
2. **Server/client boundaries:** unnecessary `"use client"`? Server-only code or secrets reachable from the client? Large objects passed as props to Client Components?
3. **Data fetching:** waterfalls, duplicate requests, fetching own Route Handlers from Server Components, client fetching that belongs on the server.
4. **Caching:** is it clear what is cached, where, for how long and how it is invalidated? Personalized data in a shared cache? Missing revalidation after mutations?
5. **Server Actions / Route Handlers:** input validation and authorization inside each one? Sensitive data returned? Errors leaking internals?
6. **Effects and memoization:** effects used for derived state or events? Memoization without evidence (or redundant with the React Compiler)?
7. **Rendering and UX:** Suspense boundaries, loading and error files, hydration risks, CLS from fallbacks or images.
8. **Metadata/SEO** where relevant.
9. **UI:** consistent with the project's design system; shared primitives modified without need; accessibility preserved.

Severity:

- **Critical:** security issues, broken functionality, data leaks, personalized data in shared caches, accessibility blockers.
- **Important:** measurable performance problems, fragile patterns, architecture violations.
- **Suggestion:** readability, minor improvements. Do not flag stylistic preferences as critical.

## Refactoring

- Preserve behavior unless a change is explicitly requested.
- Prefer incremental changes; keep each step buildable and testable.
- Typical Next.js refactors: pushing `"use client"` down, moving data fetching from client to server, extracting a data access layer, replacing effect-based derived state, splitting slow sections into Suspense boundaries.
- Use official codemods for version migrations and review their output.
- Explain meaningful architectural changes and their impact.

## Observability

- Report errors from both server and client (error boundaries, `global-error`, server logs) with route and release context.
- Use the framework's instrumentation hooks for the installed version when setting up tracing or monitoring.
- Collect Web Vitals from real users (Next.js provides a hook/utility for reporting them; confirm the API for the installed version).
- Correlate frontend requests with backend traces.
- Never send secrets, tokens or PII to logs or monitoring tools.
