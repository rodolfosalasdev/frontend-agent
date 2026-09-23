# Example: Table with state in the URL

Validated with Next.js 16.3.4 (App Router, React 19): typecheck, lint, production build, and in the browser (filtering updates the URL, the result count is announced by a live region that persists across filter changes). Check the installed version before copying (`versions.md`). Rules and rationale are in `tables.md`.

## When to use

Any list or table with filters, search, sorting or pagination. Everything that defines what the user sees lives in the URL search params, so the link can be shared ("send the filtered view to a colleague"), bookmarked, and restored with back/forward.

## Files

```text
features/orders/search-params.ts  # parse + serialize (shared by server and client)
features/orders/data.ts           # server-only query (filter, sort, paginate)
app/orders/page.tsx               # reads searchParams, keyed Suspense
app/orders/orders-filters.tsx     # Client Component: updates the URL
app/orders/orders-table.tsx       # Server Component: table, sort links, pagination
app/orders/results-announcer.tsx  # persistent live region
```

## Parse and serialize

Never trust search params: allow-list values, clamp numbers, cap lengths, fall back to defaults.

```ts
// features/orders/search-params.ts
export const ORDER_STATUSES = ['pending', 'paid', 'cancelled'] as const;
export const ORDER_SORT_FIELDS = ['createdAt', 'total'] as const;
export const ORDERS_PAGE_SIZE = 10;

export type OrderStatus = (typeof ORDER_STATUSES)[number];
export type OrderSortField = (typeof ORDER_SORT_FIELDS)[number];
export type SortDir = 'asc' | 'desc';

export type OrdersQuery = {
  status?: OrderStatus;
  q?: string;
  sort: { field: OrderSortField; dir: SortDir };
  page: number;
};

export type RawSearchParams = Record<string, string | string[] | undefined>;

const DEFAULT_SORT = { field: 'createdAt', dir: 'desc' } as const;
const MAX_PAGE = 1000;
const MAX_QUERY_LENGTH = 100;

const first = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);

export function parseOrdersSearchParams(params: RawSearchParams): OrdersQuery {
  const status = ORDER_STATUSES.find((s) => s === first(params.status));
  const q = first(params.q)?.trim().slice(0, MAX_QUERY_LENGTH) || undefined;

  const rawSort = first(params.sort) ?? '';
  const field = ORDER_SORT_FIELDS.find((f) => f === rawSort.replace(/^-/, ''));
  const sort = field
    ? { field, dir: rawSort.startsWith('-') ? ('desc' as const) : ('asc' as const) }
    : DEFAULT_SORT;

  const parsedPage = Number.parseInt(first(params.page) ?? '1', 10) || 1;
  const page = Math.max(1, Math.min(MAX_PAGE, parsedPage));

  return { status, q, sort, page };
}

/** Serializes a query to search params, omitting defaults so links stay canonical. */
export function serializeOrdersQuery(query: OrdersQuery): URLSearchParams {
  const params = new URLSearchParams();
  if (query.status) params.set('status', query.status);
  if (query.q) params.set('q', query.q);
  const isDefaultSort =
    query.sort.field === DEFAULT_SORT.field && query.sort.dir === DEFAULT_SORT.dir;
  if (!isDefaultSort) {
    params.set('sort', `${query.sort.dir === 'desc' ? '-' : ''}${query.sort.field}`);
  }
  if (query.page > 1) params.set('page', String(query.page));
  return params;
}

export function ordersHref(query: OrdersQuery): string {
  const search = serializeOrdersQuery(query).toString();
  return search ? `/orders?${search}` : '/orders';
}
```

## Data access

Filtering, sorting and pagination happen on the server (in a real app, in the database query). The in-memory version below only illustrates the contract.

```ts
// features/orders/data.ts (excerpt)
import 'server-only';

import { ORDERS_PAGE_SIZE, type OrderStatus, type OrdersQuery } from './search-params';

export type Order = {
  id: string;
  customerName: string;
  status: OrderStatus;
  totalCents: number;
  createdAt: string;
};

export type OrdersPage = { items: Order[]; totalCount: number; page: number; pageCount: number };

export async function getOrders(query: OrdersQuery): Promise<OrdersPage> {
  // Check the session and authorization here; apply filters, sort and
  // pagination in the database query; clamp the page to the last page.
}
```

## Page

```tsx
// app/orders/page.tsx
import { Suspense } from 'react';
import type { Metadata } from 'next';
import {
  parseOrdersSearchParams,
  serializeOrdersQuery,
  type RawSearchParams,
} from '@/features/orders/search-params';
import { OrdersFilters } from './orders-filters';
import { OrdersTable, OrdersTableSkeleton } from './orders-table';
import { ResultsAnnouncer } from './results-announcer';

export const metadata: Metadata = { title: 'Orders' };

export default async function OrdersPage({
  searchParams,
}: {
  searchParams: Promise<RawSearchParams>;
}) {
  const query = parseOrdersSearchParams(await searchParams);

  return (
    <main className="mx-auto max-w-5xl p-6">
      <h1 className="text-2xl font-semibold">Orders</h1>
      <ResultsAnnouncer>
        <OrdersFilters status={query.status} q={query.q} />
        <Suspense key={serializeOrdersQuery(query).toString()} fallback={<OrdersTableSkeleton />}>
          <OrdersTable query={query} />
        </Suspense>
      </ResultsAnnouncer>
    </main>
  );
}
```

## Filters (Client Component)

```tsx
// app/orders/orders-filters.tsx
'use client';

import { useEffect, useOptimistic, useRef, useState, useTransition } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { ORDER_STATUSES, type OrderStatus } from '@/features/orders/search-params';

const SEARCH_DEBOUNCE_MS = 300;

const STATUS_LABELS: Record<OrderStatus, string> = {
  pending: 'Pending',
  paid: 'Paid',
  cancelled: 'Cancelled',
};

export function OrdersFilters({ status, q }: { status?: OrderStatus; q?: string }) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  const [search, setSearch] = useState(q ?? '');
  const [syncedQ, setSyncedQ] = useState(q);
  if (q !== syncedQ) {
    // The URL changed from outside this input (back/forward, a shared link).
    setSyncedQ(q);
    if ((q ?? '') !== search.trim()) setSearch(q ?? '');
  }
  const [optimisticStatus, setOptimisticStatus] = useOptimistic(status);

  const debounceRef = useRef<ReturnType<typeof setTimeout>>(undefined);
  useEffect(() => () => clearTimeout(debounceRef.current), []);

  function updateParam(key: 'status' | 'q', value: string, onStart?: () => void) {
    const params = new URLSearchParams(searchParams);
    if (value) params.set(key, value);
    else params.delete(key);
    params.delete('page');
    const next = params.toString();
    startTransition(() => {
      onStart?.();
      router.replace(next ? `${pathname}?${next}` : pathname, { scroll: false });
    });
  }

  function onStatusChange(value: string) {
    const nextStatus = ORDER_STATUSES.find((s) => s === value);
    updateParam('status', value, () => setOptimisticStatus(nextStatus));
  }

  function onSearchChange(value: string) {
    setSearch(value);
    clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => updateParam('q', value.trim()), SEARCH_DEBOUNCE_MS);
  }

  return (
    <form
      role="search"
      aria-label="Filter orders"
      onSubmit={(e) => e.preventDefault()}
      className="mt-6 flex flex-wrap items-end gap-4"
    >
      <div className="flex flex-col gap-1">
        <label htmlFor="orders-status" className="text-sm font-medium">
          Status
        </label>
        <select
          id="orders-status"
          value={optimisticStatus ?? ''}
          onChange={(e) => onStatusChange(e.target.value)}
          className="rounded-md border px-3 py-2"
        >
          <option value="">All</option>
          {ORDER_STATUSES.map((s) => (
            <option key={s} value={s}>
              {STATUS_LABELS[s]}
            </option>
          ))}
        </select>
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="orders-search" className="text-sm font-medium">
          Customer
        </label>
        <input
          id="orders-search"
          type="search"
          value={search}
          maxLength={100}
          autoComplete="off"
          onChange={(e) => onSearchChange(e.target.value)}
          className="rounded-md border px-3 py-2"
        />
      </div>

      <span className="pb-2 text-sm text-neutral-600" aria-hidden="true">
        {isPending ? 'Updating…' : ''}
      </span>
    </form>
  );
}
```

## Table (Server Component)

```tsx
// app/orders/orders-table.tsx
import Link from 'next/link';
import { getOrders } from '@/features/orders/data';
import { ordersHref, type OrderSortField, type OrdersQuery } from '@/features/orders/search-params';
import { AnnounceResults } from './results-announcer';

const currency = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });
const dateFormat = new Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeZone: 'UTC' });

const STATUS_LABELS = { pending: 'Pending', paid: 'Paid', cancelled: 'Cancelled' } as const;

export async function OrdersTable({ query }: { query: OrdersQuery }) {
  const { items, totalCount, page, pageCount } = await getOrders(query);
  const current = { ...query, page };
  const summary = totalCount === 1 ? '1 order found' : `${totalCount} orders found`;

  return (
    <section className="mt-6">
      <AnnounceResults message={summary} />
      <p className="text-sm text-neutral-600">{summary}</p>

      {items.length === 0 ? (
        <div className="mt-4 rounded-md border border-dashed p-8 text-center">
          <p className="font-medium">No orders match these filters.</p>
          <Link href="/orders" className="mt-2 inline-block text-sm underline">
            Clear filters
          </Link>
        </div>
      ) : (
        <div className="mt-4 overflow-x-auto">
          <table className="w-full min-w-[40rem] text-left text-sm">
            <caption className="sr-only">
              Orders, page {page} of {pageCount}
            </caption>
            <thead className="border-b">
              <tr>
                <th scope="col" className="px-3 py-2">Order</th>
                <th scope="col" className="px-3 py-2">Customer</th>
                <th scope="col" className="px-3 py-2">Status</th>
                <SortableHeader field="createdAt" label="Date" query={current} />
                <SortableHeader field="total" label="Total" query={current} align="right" />
              </tr>
            </thead>
            <tbody className="divide-y">
              {items.map((order) => (
                <tr key={order.id}>
                  <td className="px-3 py-2 font-mono">{order.id}</td>
                  <td className="px-3 py-2">{order.customerName}</td>
                  <td className="px-3 py-2">{STATUS_LABELS[order.status]}</td>
                  <td className="px-3 py-2">
                    <time dateTime={order.createdAt}>
                      {dateFormat.format(new Date(order.createdAt))}
                    </time>
                  </td>
                  <td className="px-3 py-2 text-right tabular-nums">
                    {currency.format(order.totalCents / 100)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {pageCount > 1 && (
        <nav aria-label="Orders pagination" className="mt-4 flex items-center justify-between text-sm">
          {page > 1 ? (
            <Link href={ordersHref({ ...current, page: page - 1 })} scroll={false}>
              Previous
            </Link>
          ) : (
            <span aria-disabled="true" className="text-neutral-400">Previous</span>
          )}
          <span>
            Page {page} of {pageCount}
          </span>
          {page < pageCount ? (
            <Link href={ordersHref({ ...current, page: page + 1 })} scroll={false}>
              Next
            </Link>
          ) : (
            <span aria-disabled="true" className="text-neutral-400">Next</span>
          )}
        </nav>
      )}
    </section>
  );
}

function SortableHeader({
  field,
  label,
  query,
  align = 'left',
}: {
  field: OrderSortField;
  label: string;
  query: OrdersQuery;
  align?: 'left' | 'right';
}) {
  const active = query.sort.field === field;
  const nextDir = active && query.sort.dir === 'desc' ? 'asc' : 'desc';
  const href = ordersHref({ ...query, sort: { field, dir: nextDir }, page: 1 });

  return (
    <th
      scope="col"
      className={align === 'right' ? 'px-3 py-2 text-right' : 'px-3 py-2'}
      aria-sort={active ? (query.sort.dir === 'asc' ? 'ascending' : 'descending') : undefined}
    >
      <Link href={href} scroll={false} className="hover:underline">
        {label}
        <span aria-hidden="true">{active ? (query.sort.dir === 'asc' ? ' ▲' : ' ▼') : ''}</span>
      </Link>
    </th>
  );
}

export function OrdersTableSkeleton() {
  return (
    <div className="mt-6 space-y-3" aria-busy="true">
      <div className="h-4 w-32 animate-pulse rounded bg-neutral-200 motion-reduce:animate-none" />
      {Array.from({ length: 6 }, (_, i) => (
        <div key={i} className="h-8 animate-pulse rounded bg-neutral-100 motion-reduce:animate-none" />
      ))}
    </div>
  );
}
```

## Persistent live region

```tsx
// app/orders/results-announcer.tsx
'use client';

import { createContext, use, useEffect, useState, type ReactNode } from 'react';

const AnnounceContext = createContext<(message: string) => void>(() => {});

// Owns the live region so it survives the keyed Suspense remounting the table.
export function ResultsAnnouncer({ children }: { children: ReactNode }) {
  const [message, setMessage] = useState('');

  return (
    <AnnounceContext value={setMessage}>
      {children}
      <p role="status" className="sr-only">
        {message}
      </p>
    </AnnounceContext>
  );
}

export function AnnounceResults({ message }: { message: string }) {
  const announce = use(AnnounceContext);

  useEffect(() => {
    announce(message);
  }, [announce, message]);

  return null;
}
```

## Why

- **Shareable state:** `status`, `q`, `sort` and `page` are in the URL; defaults are omitted so links stay short and canonical.
- **Server does the work:** the page parses params and the table queries with them; no client-side fetching or duplicated state.
- **`router.replace` for filters** (no history entry per keystroke), **`<Link>` for sort and pagination** (real links: open in new tab, copy link, work without JavaScript).
- **Debounced search built from the current params**, and **page reset** whenever a filter changes.
- **Keyed Suspense** shows the skeleton for a new query instead of stale rows; `useTransition` + `useOptimistic` keep the controls responsive.
- **External URL changes** (back/forward, shared link) resync the search input during render, without an effect.
- **Persistent live region:** the keyed Suspense remounts the table, so the announcement lives in `ResultsAnnouncer`, outside it. Verified in the browser: the same DOM node stays mounted and its text changes from "57 orders found" to "19 orders found" after filtering.
- **Accessible table:** `<caption>`, `scope="col"`, `aria-sort`, labeled filters, a `role="search"` form, `tabular-nums` right-aligned amounts, horizontal scroll on narrow screens.
- **Empty state with a way out** ("Clear filters").

## Adapt

- If the project uses a search-params library (e.g. `nuqs`), follow it; keep the same rules (validation, defaults omitted, page reset).
- Replace utility colors with project tokens and shadcn `Table`, `Select`, `Input` components.
- For client-side caching of pages (e.g. instant back to a previous filter), see the TanStack Query integration in `tables.md`.
- Do not put sensitive free text in the URL if it can contain personal data (`tables.md`, Security).
