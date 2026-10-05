# Angular: Anti-patterns

Scan the diff against this list before reporting. Each item is something to look for, why it hurts, and what to do instead. Skip an item that the installed version does not have (for example `@defer` on v16).

## Change detection

### 1. Mutable state the view never hears about

**Look for:** a template reading a field or object that the class mutates in place (`this.user.name = ...`, `this.items.push`).
**Why:** OnPush and zoneless do not refresh that view. Zone.js sometimes hides it, until it does not.
**Fix:** store the value in a `signal` and replace it (`update`), or call `markForCheck` after the write. Prefer the signal when the file already uses signals.

### 2. `effect` used as `computed`

**Look for:** an `effect` whose only job is to copy one signal into another.
**Why:** extra writes, extra refreshes, and easy loops.
**Fix:** `computed`, or `linkedSignal` when the value must stay writable.

### 3. Zone.js left on after zoneless bootstrap

**Look for:** `provideZonelessChangeDetection` (or a v21+ app) while `polyfills` still lists `zone.js`.
**Why:** the bundle still pays for Zone.js and the app can behave like both models at once.
**Fix:** remove it from the `build` and `test` polyfills. Ask before uninstalling the package.

### 4. `provideZoneChangeDetection` on a v21+ app

**Look for:** that provider added "to be safe".
**Why:** it turns the zoneless default off and brings Zone.js back.
**Fix:** delete it unless the task is explicitly to keep Zone.js.

### 5. Reactive form updates with no notification

**Look for:** `patchValue` / `setValue` and a template that reads `form.value` directly, in a zoneless or OnPush component, with no `AsyncPipe`, signal, or `markForCheck`.
**Why:** the model changes and the view does not.
**Fix:** bridge the form state into something the template tracks.

### 6. `detectChanges()` to paper over a missing notification

**Look for:** `ChangeDetectorRef.detectChanges()` after every write, or tests that only pass because of it.
**Why:** it hides the bug and can refresh more than the framework would.
**Fix:** notify Angular properly. Keep `detectChanges()` only where a test must force a specific pass and the reason is commented.

## Templates and loading

### 7. `@defer` on the LCP or the first viewport

**Look for:** the main heading, hero, or primary content inside `@defer`.
**Why:** the placeholder swap shifts layout and delays the largest paint.
**Fix:** keep that content eager. Defer what is below the fold.

### 8. `@defer` that does not split

**Look for:** the deferred component imported from a barrel, referenced outside the block, queried with `viewChild`, or declared in an NgModule instead of standalone.
**Why:** the compiler leaves it in the eager bundle.
**Fix:** standalone component, imported from its own file, referenced only inside the block.

### 9. Nested `@defer` with the same trigger

**Look for:** two blocks both `on viewport` or both `on idle` in the same view.
**Why:** they load together and waterfall.
**Fix:** different triggers, or prefetch on one and display on another.

### 10. `@for` without a stable `track`

**Look for:** `track $index` on a list that is sorted, filtered, or updated.
**Why:** DOM nodes are destroyed and recreated. Input focus and row state die with them.
**Fix:** `track item.id` (a stable identity).

### 11. Work in the template

**Look for:** `items.filter(...)`, `format(item)`, or `getLabel()` in a binding.
**Why:** it runs on every refresh.
**Fix:** a `computed` or a precomputed field.

## Data and forms

### 12. Bare `subscribe`

**Look for:** `.subscribe(` in a component with no `takeUntilDestroyed`, async pipe, or `toSignal`.
**Why:** the subscription outlives the view and holds memory. Errors are easy to drop.
**Fix:** one of those three. Handle the error path.

### 13. `httpResource` or signal forms on a version that does not have them

**Look for:** `@angular/forms/signals` below v21, or `httpResource` below the version that ships it.
**Why:** the build fails, or a preview API sneaks into an old app.
**Fix:** typed reactive forms and `HttpClient` until the version guide says otherwise.

### 14. Fetching in the constructor or in an `effect` that ignores cancellation

**Look for:** `http.get(...).subscribe` inside `constructor` or an `effect` with no abort.
**Why:** a fast input change leaves an old response able to overwrite the new one.
**Fix:** `resource` / `httpResource` when available, or `switchMap`.

## Security and structure

### 15. Trusting user HTML

**Look for:** `bypassSecurityTrustHtml` (or the other bypass methods) on content from the user or an API.
**Why:** that is an XSS hole.
**Fix:** bind as text. Sanitize with a real policy if HTML is a requirement, and say so in the report.

### 16. Heavy import in the root component

**Look for:** a chart, editor, or map library imported by `App` or a layout that wraps every route.
**Why:** it lands in the initial bundle.
**Fix:** `@defer` or a lazy route.

### 17. Second design system

**Look for:** Angular Material added next to an existing component library, or Tailwind added to a Material app, without being asked.
**Why:** two visual systems and two bundles.
**Fix:** use what the project uses (`ui.md`).
