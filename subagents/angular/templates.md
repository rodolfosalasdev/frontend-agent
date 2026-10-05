# Angular: Templates, Control Flow, and `@defer`

`@defer` is the main template tool for initial-load performance. Control flow (`@if`, `@for`, `@switch`) replaces structural directives in new templates. Both require a version that has them (`versions.md`).

Official guides: [control flow](https://angular.dev/guide/templates/control-flow), [defer](https://angular.dev/guide/templates/defer).

## Control flow

Use `@if`, `@for`, and `@switch` in new templates when the project is on v17+ (stable in v18). Keep `*ngIf` / `*ngFor` / `*ngSwitch` when you are editing a template that still uses them and the task is not a migration. They were deprecated in v20; check whether the installed version still accepts them.

```html
@for (client of clients(); track client.id) {
  <li>{{ client.name }}</li>
} @empty {
  <li>No clients yet.</li>
}
```

- **`track` is required** and must identify the row. Tracking the object, or the loop index when rows are reordered, recreates DOM and costs time.
- `@for` track replaces `trackBy`. Do not allocate a new track function in the template (`track client.id` reads a property; do not call a method that returns a new object).
- `@empty` covers the empty collection. It is not the error state.
- Do not call methods or build arrays in template expressions (`{{ format(item) }}` that allocates, `items.filter(...)` in the binding). Compute them in a `computed` or a pipe the project already uses.

`@let` (v18.1+) names an intermediate value in the template. Do not use it as a place to hide expensive work.

## What `@defer` is for

`@defer` splits standalone components, directives, pipes, and their CSS into a separate chunk and loads that chunk when a trigger fires. The official guide ties this to a faster initial load and to LCP and TTFB. It does **not** make a non-standalone dependency lazy: NgModule-declared dependencies inside the block stay in the eager bundle.

Dependencies are deferred only when:

1. they are standalone, and
2. the same file does not reference them outside the `@defer` block or in a `ViewChild` query.

Transitive NgModule dependencies of a deferred standalone component can still be lazy.

## Triggers

Default trigger: **`idle`** (requestIdleCallback), with an optional timeout (`on idle(500)`).

| Trigger | Loads when |
|---|---|
| `idle` | the browser is idle |
| `viewport` | the placeholder, or a template ref, enters the viewport |
| `interaction` | click or keydown on the placeholder or a template ref |
| `hover` | mouseover or focusin |
| `immediate` | as soon as the rest of the template has rendered |
| `timer(500ms)` | after a duration (`ms` or `s`) |
| `when expr` | the expression becomes truthy, **once**. It does not go back to the placeholder if the expression becomes falsy |

Several `on` triggers separated by `;` are OR. `prefetch on idle` (or another trigger) loads the chunk earlier and still waits for the main trigger to render.

`viewport` and `interaction` need a `@placeholder` with a **single root element**, or an explicit template reference. Viewport can take an options object (`rootMargin`, `threshold`, `trigger`). `root` is not supported. Confirm the object form for the installed version; it is newer than the original trigger list.

## Sub-blocks

- `@placeholder` (optional `minimum`) shows before the trigger. Its dependencies are **eager**. Use it to reserve space.
- `@loading` (optional `after`, `minimum`) shows while the chunk loads. Also eager. `after` avoids a flash on fast networks.
- `@error` shows if loading fails. Also eager. Give the user a retry that the deferred component can recover from, or a way to trigger the block again if the installed version supports it. If a retry API is unclear, say so rather than inventing one.

## Performance rules

- **Do not defer the LCP content** or anything visible in the first viewport. Swapping a placeholder for real content shifts layout (CLS). If you must defer something in view, do not use `immediate`, `timer`, `viewport`, or a `when` that fires during the first render.
- **Reserve space** in the placeholder (a sized skeleton), so the swap does not move the page.
- **Import the deferred component from its own file.** A barrel (`index.ts`) pulls sibling exports into the same module and the chunk is not split. This is the usual reason `@defer` "does nothing" in the build output.
- **Nested `@defer` blocks need different triggers.** The same trigger loads them together and creates a waterfall.
- **Prefetch** when the user is likely to need the block soon (`on interaction; prefetch on idle`) so the click does not wait on the network.
- **HMR loads every deferred chunk eagerly.** Do not judge splitting from `ng serve` with HMR. Use a production build. `--no-hmr` restores triggers locally.
- **SSR and prerender** render the `@placeholder` (or nothing) and do not run triggers on the server. The client hydrates the placeholder and then honors triggers. To render the main content on the server, use incremental hydration and its `hydrate` triggers. Read [incremental hydration](https://angular.dev/guide/incremental-hydration) for the installed version before writing `hydrate`.

## Accessibility

A screen reader that lands on a deferred region reads the placeholder and may not notice the swap. Wrap the block in a polite live region when the change matters:

```html
<div aria-live="polite" aria-atomic="true">
  @defer (on viewport) {
    <app-reviews />
  } @placeholder {
    <p>Loading reviews…</p>
  } @error {
    <p>Reviews could not be loaded.</p>
  }
</div>
```

Do not put a live region on every decorative defer.

## Tests

`TestBed` plays defer blocks through by default. For step-by-step tests, set `deferBlockBehavior: DeferBlockBehavior.Manual`, then `fixture.getDeferBlocks()` and `render(DeferBlockState.Loading | Complete | ...)`. Confirm the enum members for the installed version.
