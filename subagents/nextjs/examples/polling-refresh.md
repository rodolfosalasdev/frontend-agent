# Example: Periodic refresh (polling)

Validated with Next.js 16.3.4 (App Router, React 19) and TanStack Query 5: typecheck, lint, production build. Check the installed versions before copying (`versions.md`). The decision criteria are in `data-fetching.md` ("Simple periodic refresh: compare before choosing").

## When to use

A view that must reflect server changes without user action (deployment status, job progress, queue size) and where near-real-time (seconds) is enough. For true real-time or high-frequency updates, consider streaming (SSE/WebSocket) instead.

Two options. Compare them for the case at hand and state the choice in the report:

| | `router.refresh()` | TanStack Query `refetchInterval` |
|---|---|---|
| New dependency | No | Yes (unless already installed) |
| What refetches | The whole route (all Server Components) | Only that query |
| Endpoint | None (uses the page's data access) | Needs a Route Handler |
| Best for | A few pages, simple data, the page is dynamic anyway | Query already in the project, many live widgets, fine-grained control (retry, backoff, per-query intervals) |

## Option A: `router.refresh()` (no dependency)

### Files

```text
features/deployments/data.ts    # server-only data access
app/deployments/page.tsx        # dynamic Server Component
app/deployments/auto-refresh.tsx  # Client Component that triggers the refresh
```

### Page

```tsx
// app/deployments/page.tsx
import type { Metadata } from 'next';
import { connection } from 'next/server';
import { getDeployments } from '@/features/deployments/data';
import { AutoRefresh } from './auto-refresh';

export const metadata: Metadata = { title: 'Deployments' };

const REFRESH_INTERVAL_MS = 10_000;
const timeFormat = new Intl.DateTimeFormat('en-US', { timeStyle: 'medium', timeZone: 'UTC' });

export default async function DeploymentsPage() {
  await connection();
  const deployments = await getDeployments();
  const updatedAt = new Date();

  return (
    <main className="mx-auto max-w-3xl p-6">
      <AutoRefresh intervalMs={REFRESH_INTERVAL_MS} />
      <h1 className="text-2xl font-semibold">Deployments</h1>
      <p className="mt-1 text-sm text-neutral-600">
        Updates every {REFRESH_INTERVAL_MS / 1000}s. Last update:{' '}
        <time dateTime={updatedAt.toISOString()}>{timeFormat.format(updatedAt)} UTC</time>
      </p>

      {deployments.length === 0 ? (
        <p className="mt-6 text-neutral-600">No deployments yet.</p>
      ) : (
        <ul className="mt-6 divide-y">
          {deployments.map((deployment) => (
            <li key={deployment.id} className="flex justify-between py-3">
              <span className="font-mono text-sm">{deployment.branch}</span>
              <span className="text-sm">{deployment.status}</span>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
```

`connection()` marks the page as request-time. Without it (or another request-time API), a page with only static data access is prerendered at build and `router.refresh()` would keep returning the same HTML.

### Refresh trigger

```tsx
// app/deployments/auto-refresh.tsx
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export function AutoRefresh({ intervalMs }: { intervalMs: number }) {
  const router = useRouter();

  useEffect(() => {
    let timer: ReturnType<typeof setInterval> | undefined;

    const start = () => {
      timer ??= setInterval(() => router.refresh(), intervalMs);
    };
    const stop = () => {
      clearInterval(timer);
      timer = undefined;
    };
    const onVisibilityChange = () => {
      if (document.hidden) {
        stop();
      } else {
        router.refresh();
        start();
      }
    };

    if (!document.hidden) start();
    document.addEventListener('visibilitychange', onVisibilityChange);
    return () => {
      stop();
      document.removeEventListener('visibilitychange', onVisibilityChange);
    };
  }, [router, intervalMs]);

  return null;
}
```

## Option B: TanStack Query (when it is already in the project or justified)

Requires the `QueryClientProvider` setup described in `data-fetching.md` (a `QueryClient` per request on the server, a single one in the browser).

### Route Handler

```ts
// app/api/deployments/route.ts
import { getSession } from '@/lib/auth';
import { getDeployments } from '@/features/deployments/data';

export async function GET() {
  const session = await getSession();
  if (!session) return Response.json({ error: 'unauthenticated' }, { status: 401 });

  return Response.json(await getDeployments(), {
    headers: { 'Cache-Control': 'private, no-store' },
  });
}
```

### Client Component seeded by the server

```tsx
// app/deployments-live/deployments-live.tsx
'use client';

import { useQuery } from '@tanstack/react-query';
import type { Deployment } from '@/features/deployments/data';

async function fetchDeployments(): Promise<Deployment[]> {
  const response = await fetch('/api/deployments');
  if (!response.ok) throw new Error(`Failed to load deployments (${response.status})`);
  return response.json();
}

export function DeploymentsLive({ initialData }: { initialData: Deployment[] }) {
  const { data, isError, isFetching } = useQuery({
    queryKey: ['deployments'],
    queryFn: fetchDeployments,
    initialData,
    staleTime: 5_000,
    refetchInterval: 10_000,
    refetchIntervalInBackground: false,
  });

  return (
    <section aria-busy={isFetching}>
      {isError && (
        <p role="alert" className="text-sm text-red-700">
          Could not refresh. Showing the last known data.
        </p>
      )}
      <ul className="mt-4 divide-y">
        {data.map((deployment) => (
          <li key={deployment.id} className="flex justify-between py-3">
            <span className="font-mono text-sm">{deployment.branch}</span>
            <span className="text-sm">{deployment.status}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}
```

The Server Component page fetches `getDeployments()` and passes it as `initialData` (or prefetches and uses `HydrationBoundary` when several queries are involved, see `data-fetching.md`). `import type` from a `server-only` module is fine: types are erased at build.

## Why

- **Polling pauses when the tab is hidden** (Option A handles `visibilitychange`; Option B uses `refetchIntervalInBackground: false`) and refreshes immediately when the user comes back.
- **No blank screen during refresh:** `router.refresh()` keeps the current UI until the new payload arrives; Query keeps previous data and exposes `isFetching`.
- **Errors keep the last known data** instead of replacing the view.
- **"Last update" time** tells the user how fresh the data is.
- **The endpoint authorizes and disables shared caching** (`private, no-store`) for per-user data.

## Adapt

- Choose the interval from the product need and backend cost; add backoff on repeated errors for Option A if needed (Query retries by default).
- If only one small widget needs polling on an otherwise static page, prefer Option B (with or without `initialData`): only the widget polls, and the route can stay static.
- Do not announce every refresh to screen readers; announce only meaningful changes (e.g. "Deployment main is ready").
