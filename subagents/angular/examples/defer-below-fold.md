# Example: Defer a below-the-fold block

Validated with Angular 21.2.25: production `ng build` succeeded and emitted a separate lazy chunk named `reviews`.

`@defer` is stable in Angular 18 (preview in 17). Do not use it on v16. Confirm triggers in the [defer guide](https://angular.dev/guide/templates/defer) for the installed version. The `viewport` options object is newer than the original triggers; omit it if the installed guide does not show it.

## When to use

A heavy standalone component that is **not** the LCP and is not visible on the first screen (reviews, a chart, a rich editor). The hero and the primary heading stay eager.

## Import

Import the component from its own file. A barrel file keeps it in the main bundle.

```ts
import {Component} from '@angular/core';
import {Reviews} from './reviews';

@Component({
  selector: 'app-product',
  imports: [Reviews],
  templateUrl: './product.html',
})
export class Product {}
```

`Reviews` must be standalone. On versions before standalone-by-default (v19), set `standalone: true`.

## Template

```html
<article>
  <h1>Mechanical keyboard</h1>
  <p>In stock. Ships tomorrow.</p>
</article>

<div aria-live="polite">
  @defer (on viewport; prefetch on idle) {
    <app-reviews />
  } @placeholder {
    <p class="reviews-skeleton">Loading reviews…</p>
  } @loading (after 100ms; minimum 300ms) {
    <p>Loading reviews…</p>
  } @error {
    <p>Reviews could not be loaded.</p>
  }
</div>
```

Give `.reviews-skeleton` a height close to the real block so the swap does not shift the page.

## Why

- The product title paints immediately. Reviews load when the placeholder nears the viewport.
- `prefetch on idle` fetches the chunk early so the scroll does not wait on the network.
- Placeholder and loading dependencies are eager, so they must stay tiny.
- The live region announces the swap. Skip it when the deferred block is decorative.
- Nested defers in `Reviews` need a different trigger (`templates.md`).

## Adapt

- Production `ng build` is the check that a separate chunk exists. `ng serve` with HMR loads defer chunks eagerly.
- SSR renders the placeholder unless incremental hydration is configured. Do not invent a `hydrate` trigger; copy it from the installed guide.
