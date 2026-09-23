# Next.js: Tables and Lists with URL State

**Default rule (parameterizable):** tables and lists with filters, sorting, pagination, search or a selected tab keep that state in the URL **search params**, so a copied link opens the exact same view for a colleague.

- Use **search params** (query string), not path params: `/orders?status=paid&sort=-createdAt&page=2`. Path params identify resources (`/orders/[id]`).
- The project's `architecture.md` may define a different strategy; follow it.
- If the project already uses a URL-state library, use it. Do not add one.

## When to apply

Any state the user would expect to survive **sharing the link, reloading or pressing back**: filters, sort column and direction, page, page size, search text, active tab or view mode.

Transient UI state (an open dropdown, hover, a half-typed value before debounce) stays in component state.

## Server side (App Router)

1. The `page` receives `searchParams`. It is synchronous or a Promise depending on the installed version (see `versions.md`).
2. Parse and validate with a dedicated function, e.g. `parseOrdersSearchParams`:
   - apply defaults for missing values;
   - clamp `page` and `pageSize` to valid ranges;
   - accept only sort columns from an allowlist;
   - accept only known enum values for filters;
   - ignore unknown or malformed values instead of throwing.
3. Fetch the filtered data on the server with the parsed values, so the shared link renders already filtered.
4. Reading `searchParams` makes the route dynamic. This is intentional; mention it in the report.
5. Wrap the table in `<Suspense key={serializedParams}>` (or use `loading.tsx`) so changing filters shows a loading state instead of stale rows.

Keep the parser and its types in one place and reuse them on the server and in client controls.

```ts
const SORTABLE = ['createdAt', 'total', 'status'] as const;
const STATUSES = ['pending', 'paid', 'cancelled'] as const;

type OrdersQuery = {
  status?: (typeof STATUSES)[number];
  q?: string;
  sort: { field: (typeof SORTABLE)[number]; dir: 'asc' | 'desc' };
  page: number;
};

export function parseOrdersSearchParams(
  params: Record<string, string | string[] | undefined>,
): OrdersQuery {
  const first = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);

  const status = STATUSES.find((s) => s === first(params.status));
  const q = first(params.q)?.trim().slice(0, 100) || undefined;

  const rawSort = first(params.sort) ?? '-createdAt';
  const dir = rawSort.startsWith('-') ? 'desc' : 'asc';
  const field = SORTABLE.find((f) => f === rawSort.replace(/^-/, '')) ?? 'createdAt';

  const page = Math.max(1, Math.min(1000, Number.parseInt(first(params.page) ?? '1', 10) || 1));

  return { status, q, sort: { field, dir }, page };
}
```

## Client controls

- Small Client Components (`"use client"`) for filter inputs, search box and page size. Keep the table itself a Server Component when it has no interactivity.
- Read with `useSearchParams`, build the next URL from `new URLSearchParams(searchParams)`, and navigate with `useRouter` + `usePathname`.
- **`router.replace`**, not `push`, for filter and search changes, so the history is not flooded. `push` is acceptable for page changes when back-button-per-page is desired.
- **Debounce** text search (around 300 ms) before updating the URL. When the timer fires, build the URL from the **current** params (e.g. `window.location.search` or a ref updated on each render), not from the `searchParams` captured when the timer started; otherwise a filter changed during the debounce window is overwritten.
- **Reset `page` to 1** whenever a filter, search or sort changes.
- Use `{ scroll: false }` when the table should keep the scroll position.
- Wrap navigation in `useTransition` to show a pending indicator.
- `useSearchParams` in a Client Component may require a Suspense boundary above it on statically rendered routes; confirm for the installed version.

## Links for pagination and sort headers

Prefer `<Link href={...}>` with the URL already built for pagination and sortable column headers:

- works without JavaScript;
- can be opened in a new tab or copied;
- benefits from prefetching.

## URL conventions

- **Omit defaults** from the URL (`page=1`, default sort): shorter, canonical links.
- Short, stable parameter names. Once links are shared, **parameter names are a public contract**; renaming breaks bookmarks.
- One convention for multi-value filters in the project: repeated keys (`?status=paid&status=pending`) or comma-separated (`?status=paid,pending`).
- Sort as `sort=field` (ascending) / `sort=-field` (descending), unless the project defines another format.

## Client-side server state

When the table needs client-side data behavior (polling, very frequent filter changes without a full server render, optimistic edits) and the project uses TanStack Query (see `data-fetching.md`):

- the URL remains the **source of truth**; the Query cache is only a cache;
- include every parsed search param in the `queryKey` (e.g. `['orders', parsedQuery]`);
- use `placeholderData: keepPreviousData` (v5 API; check the installed version) so rows do not flash empty when changing page or filters;
- prefetch the next page when it is likely to be requested.

## Security

- Search params are **untrusted input**: validate them and never interpolate into queries without parameterization.
- Never put sensitive data or PII in the URL (it goes to server logs, browser history, analytics and the `Referer` header). Free-text search may contain personal data (e.g. customer names): keeping it shareable is a product decision; state the trade-off in the report and keep a `Referrer-Policy` that strips query strings cross-origin.
- Sharing a link does not grant access: the server still enforces authorization for the data behind it.

## Accessibility

- `aria-sort` on sortable column headers (`ascending`, `descending`, or omitted on unsorted columns); sort controls are buttons or links with clear names.
- Announce the result count after filtering in a live region (e.g. "24 orders found"). The live region must be **persistent**: place it outside the keyed Suspense boundary (e.g. next to the filters). A live region that remounts with each change may not be announced.
- Filter inputs have labels; the search input has an accessible name.
- On page change, keep focus in a predictable place (e.g. the table caption or the pagination control that was used).
- Use a real `<table>` with `<caption>` or an accessible name, `<th scope="col">` for headers.

## Review checklist

- Does the copied link reproduce exactly the same view (filters, sort, page, search)?
- Do back and reload preserve the state?
- Do invalid or tampered params fall back to defaults without breaking the page?
- Is `page` reset when filters change?
- Is the history not flooded while typing?
- Is nothing sensitive in the URL?
