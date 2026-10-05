# Next.js: Caching and Revalidation

Caching is where Next.js behavior changed the most across versions. **Always confirm the behavior for the installed version and configuration** before stating it.

## Never say "Next.js caches this"

For every caching claim, answer:

1. **What** is cached? (fetch response, function result, rendered route output, RSC payload, HTTP response, asset)
2. **Where**? (browser, CDN, Next.js server / data cache, client router cache, in-memory per request)
3. **What is the cache key?**
4. **What is the lifetime?**
5. **When and how is it invalidated?**
6. **Is the data personalized?** If so, is it safe to share?
7. **Is the cache shared across requests and users?**
8. **Does the behavior depend on the version or configuration** (`cacheComponents`, route segment config, `fetch` options)?
9. **Does the deployment infrastructure change it?** (Vercel vs self-hosted, multiple instances, custom cache handlers)

## Layers to distinguish

| Layer | Scope | Notes |
|---|---|---|
| Browser HTTP cache | Per user | Controlled by `Cache-Control` headers |
| CDN cache | Shared | Depends on headers and the hosting platform |
| Request memoization | Single server render | Deduplicates identical reads during one request (`React.cache`, and `fetch` memoization where applicable) |
| Data cache / cached functions | Shared across requests on the server | Persistent server-side caching of data or function results |
| Full route / prerendered output | Shared | Static or prerendered HTML and RSC payload |
| Client router cache | Per browser session | RSC payloads of visited/prefetched routes; affects back/forward and navigation freshness |
| Client query cache (TanStack Query, when used) | Per browser tab, in memory | Freshness by `staleTime`, removal by `gcTime`, invalidation after mutations. Does not reduce API load across users (see `data-fetching.md`) |
| Application-level cache | Depends | Your own caches (e.g. Redis, in-memory), outside the framework |

Defaults for these layers changed across major versions (for example, whether `fetch` and GET Route Handlers are cached by default, and how long the client router cache keeps pages). Do not assume the defaults of one version apply to another.

## Two caching models

Projects may use one of two models. **Do not mix their assumptions.**

### Cache Components (when enabled and supported)

Enabled via the `cacheComponents` option in `next.config` in the versions that support it. Key concepts:

- `"use cache"` directive on functions, components or files marks cacheable work;
- `cacheLife` defines lifetime profiles;
- `cacheTag` attaches tags used for invalidation;
- dynamic (request-time) data must be inside Suspense boundaries so the rest can be prerendered;
- prerendering produces a static shell with dynamic holes streamed at request time.

Before introducing it: confirm the installed version supports it, check the project configuration, understand the migration impact on existing routes, and get confirmation (it changes `next.config`).

### Previous model (Cache Components disabled)

- `fetch` options (`cache`, `next.revalidate`, `next.tags`);
- route segment config (`dynamic`, `revalidate`, and related exports);
- `unstable_cache` for non-fetch data (legacy API; check status for the installed version);
- time-based and on-demand revalidation.

Some route segment options are incompatible with or replaced by Cache Components. Check the docs for the installed version before combining them.

## Revalidation

- **Time-based:** acceptable staleness window defined up front.
- **On-demand:** after a mutation, invalidate by tag or path. Prefer tags for data used in many routes; paths for page-specific content.
- The exact functions and their signatures differ across versions. **Verify the signature for the installed version** before writing the call. In Next.js 16.x:
  - `updateTag(tag)`: only in Server Actions; expires immediately for read-your-own-writes;
  - `revalidateTag(tag, 'max')`: stale-while-revalidate; the single-argument form is deprecated;
  - `revalidatePath(path)`: page-specific invalidation;
  - `refresh()`: refresh the client router from a Server Action.
- After a Server Action mutation, invalidate the affected data so the UI reflects the change; consider how the client router cache is refreshed.

## Personalized data

- Never cache personalized or authorization-dependent data in a shared cache.
- Reading cookies or headers inside a cached scope is either disallowed or makes the result user-specific depending on the model; check the rules for the installed version.
- Separate the shared part (cacheable) from the user-specific part (dynamic, streamed).

## Diagnosing cache issues

1. Reproduce with a production build (`next build` + `next start`), not `next dev`.
2. Identify which layer serves the stale or unexpected data (browser, CDN, server, client router cache).
3. Inspect response headers and build output (which routes were prerendered vs dynamic).
4. Check route segment config, `fetch` options, `"use cache"` usage and revalidation calls.
5. Consider infrastructure: multiple instances without a shared cache handler serve different cache states.
