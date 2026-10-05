# Angular: Routing

Official guides: [routing](https://angular.dev/guide/routing), [loading strategies](https://angular.dev/guide/routing/loading-strategies), [route state](https://angular.dev/guide/routing/read-route-state), [rendering strategies](https://angular.dev/guide/routing/rendering-strategies).

## Routes

- Feature routes are lazy: `loadComponent` for a standalone page, `loadChildren` for a group. Eager imports of feature pages in the root route file defeat the split.
- Functional guards and resolvers (`CanActivateFn`) in new code. Class guards stay if the file already uses them.
- `withComponentInputBinding()` (when the installed router supports it) maps route params and query params onto component inputs. Confirm the function name for the version before adding it.
- Titles and meta: set `title` on the route or a `Title` strategy the project already has. Do not leave new pages with the default document title.
- Redirects and wildcards stay explicit. A new route does not swallow an existing path.

## Shareable list state

A list with filters, search, sort, or paging keeps that state in the **query string** (`?q=ada&status=open&page=2`) so a colleague can open the same view. Path params are for identity (`/clients/42`), not for filters.

- Read and validate params before using them (allow-list sort fields, clamp `page`, cap the length of free text).
- Omit defaults so the URL stays short.
- Update filters with `Router.navigate` / `navigateByUrl` and `queryParamsHandling` only when you mean to keep unrelated params. Replace the filter set deliberately.
- Reset `page` when a filter changes.
- Do not put secrets or unnecessary personal data in the query string. Free text can be a name; if that is sensitive in this product, say so in the report.
- The server, not the template, applies the filter when the list is large. The client filters only a list it already has.

## Rendering

SSR, prerender, and client-only are per route on versions that support route-level render modes (stable around v19–v20; confirm). A route that reads request-specific data cannot be prerendered at build time. Do not mark a personalized page as prerendered.

Hydration and incremental hydration: `performance.md`.
