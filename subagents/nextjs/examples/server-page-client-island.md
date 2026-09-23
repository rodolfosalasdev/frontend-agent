# Example: Server page with a client island

Validated with Next.js 16.3.4 (App Router, React 19): typecheck, lint, production build. Check the installed version before copying (`versions.md`) and adapt names, styling tokens and data access to the project.

## When to use

A page that is mostly content (list, detail, dashboard) with a small interactive part. The page and data fetching stay on the server; only the interactive control ships JavaScript.

## Files

```text
lib/auth.ts                          # session helper (project-specific)
features/products/data.ts            # server-only data access
features/cart/actions.ts             # Server Action used by the island
app/products/page.tsx                # Server Component
app/products/add-to-cart-button.tsx  # Client Component (the island)
app/products/loading.tsx             # loading state
app/products/error.tsx               # error state
```

## Data access (server-only)

```ts
// features/products/data.ts
import 'server-only';

export type ProductCard = {
  id: string;
  name: string;
  priceInCents: number;
};

const PRODUCTS: ProductCard[] = [
  { id: 'p1', name: 'Mechanical keyboard', priceInCents: 12900 },
  { id: 'p2', name: 'USB-C dock', priceInCents: 8900 },
];

// Return only the fields the UI needs: this shape is serialized to the client.
export async function getProducts(): Promise<ProductCard[]> {
  return PRODUCTS;
}
```

## Page (Server Component)

```tsx
// app/products/page.tsx
import type { Metadata } from 'next';
import { getProducts } from '@/features/products/data';
import { AddToCartButton } from './add-to-cart-button';

export const metadata: Metadata = { title: 'Products' };

const currency = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });

export default async function ProductsPage() {
  const products = await getProducts();

  return (
    <main className="mx-auto max-w-3xl p-6">
      <h1 className="text-2xl font-semibold">Products</h1>

      {products.length === 0 ? (
        <p className="mt-6 text-neutral-600">No products available yet.</p>
      ) : (
        <ul className="mt-6 divide-y">
          {products.map((product) => (
            <li key={product.id} className="flex items-center justify-between gap-4 py-4">
              <div>
                <p className="font-medium">{product.name}</p>
                <p className="text-sm tabular-nums text-neutral-600">
                  {currency.format(product.priceInCents / 100)}
                </p>
              </div>
              <AddToCartButton productId={product.id} productName={product.name} />
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
```

## Island (Client Component)

```tsx
// app/products/add-to-cart-button.tsx
'use client';

import { useState, useTransition } from 'react';
import { addToCart } from '@/features/cart/actions';

type Props = { productId: string; productName: string };

export function AddToCartButton({ productId, productName }: Props) {
  const [isPending, startTransition] = useTransition();
  const [message, setMessage] = useState('');

  function handleClick() {
    startTransition(async () => {
      const result = await addToCart(productId);
      setMessage(
        result.ok ? `${productName} added to cart.` : 'Could not add to cart. Try again.',
      );
    });
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <button
        type="button"
        onClick={handleClick}
        disabled={isPending}
        className="rounded-md bg-neutral-900 px-3 py-2 text-sm font-medium text-white hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 disabled:opacity-60"
      >
        {isPending ? 'Adding…' : 'Add to cart'}
        <span className="sr-only">: {productName}</span>
      </button>
      <p role="status" className="text-sm text-neutral-600">
        {message}
      </p>
    </div>
  );
}
```

The action follows the pattern in `server-action.md` (validate input, check the session, return a typed result):

```ts
// features/cart/actions.ts
'use server';

import { z } from 'zod';
import { getSession } from '@/lib/auth';

const productIdSchema = z.string().min(1).max(64);

export type AddToCartResult =
  | { ok: true }
  | { ok: false; error: 'invalid_input' | 'unauthenticated' };

export async function addToCart(productId: unknown): Promise<AddToCartResult> {
  const parsed = productIdSchema.safeParse(productId);
  if (!parsed.success) return { ok: false, error: 'invalid_input' };

  const session = await getSession();
  if (!session) return { ok: false, error: 'unauthenticated' };

  // await cart.add(session.userId, parsed.data);
  return { ok: true };
}
```

## Loading and error states

```tsx
// app/products/loading.tsx
export default function Loading() {
  return (
    <main className="mx-auto max-w-3xl p-6" aria-busy="true">
      <h1 className="text-2xl font-semibold">Products</h1>
      <ul className="mt-6 divide-y" aria-hidden="true">
        {Array.from({ length: 4 }, (_, i) => (
          <li key={i} className="flex items-center justify-between gap-4 py-4">
            <div className="space-y-2">
              <div className="h-4 w-40 animate-pulse rounded bg-neutral-200 motion-reduce:animate-none" />
              <div className="h-3 w-16 animate-pulse rounded bg-neutral-200 motion-reduce:animate-none" />
            </div>
            <div className="h-9 w-28 animate-pulse rounded-md bg-neutral-200 motion-reduce:animate-none" />
          </li>
        ))}
      </ul>
      <p className="sr-only" role="status">Loading products…</p>
    </main>
  );
}
```

```tsx
// app/products/error.tsx
'use client';

import { useEffect } from 'react';

export default function ProductsError({
  error,
  retry,
}: {
  error: Error & { digest?: string };
  retry: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className="mx-auto max-w-3xl p-6">
      <h1 className="text-2xl font-semibold">Products</h1>
      <div role="alert" className="mt-6 rounded-md border border-red-200 bg-red-50 p-4">
        <p className="font-medium">We couldn&apos;t load the products.</p>
        <button
          type="button"
          onClick={() => retry()}
          className="mt-3 rounded-md border px-3 py-2 text-sm font-medium"
        >
          Try again
        </button>
      </div>
    </main>
  );
}
```

**Version note:** `retry` is stable in 16.3 (`unstable_retry` in 16.2). In earlier versions the error component receives `reset` only. `reset` still exists but does not re-fetch; prefer `retry` when available. Check `error.md` in the bundled docs.

## Why

- Only the button is a Client Component; the list, formatting and data access stay on the server (smaller bundle).
- Props crossing the boundary are small and serializable (`id`, `name`), not the whole product.
- `server-only` prevents the data module from being imported into client code.
- All four states are covered: loading (skeleton with the final shape), empty, error (with retry) and success (with feedback announced by `role="status"`).
- The button's accessible name includes the product ("Add to cart: USB-C dock") so screen reader users can tell the buttons apart.

## Adapt

- Replace utility colors (`neutral-*`, `red-*`) with the project's tokens (e.g. shadcn `text-muted-foreground`, `bg-primary`) and components (`Button`, `Skeleton`).
- If the page reads per-user data, it becomes dynamic; keep personalized parts in a Suspense boundary so the rest can stay static (`rendering.md`).
