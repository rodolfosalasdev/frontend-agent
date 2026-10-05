# Angular: Signals and Reactivity

Signals are the reactivity model for modern Angular. Use them for **new state in files that already use signals**, and for new code when the project has adopted them. Do not rewrite a working RxJS stream because signals exist.

Official guides: [signals](https://angular.dev/guide/signals), [linkedSignal](https://angular.dev/guide/signals/linked-signal), [resource](https://angular.dev/guide/signals/resource), [RxJS interop](https://angular.dev/ecosystem/rxjs-interop).

## Choose the primitive

| Need | Use | Do not use |
|---|---|---|
| State that changes | `signal` | a mutable field the template reads, on a zoneless or OnPush view |
| Value derived from other signals | `computed` | `effect` that writes another signal |
| Writable state that resets when a source changes | `linkedSignal` (v19+, stable in v20) | `effect` that copies one signal into another |
| Async data that refetches when signals change | `resource` / `httpResource` when the version has them and the UI needs that graph | `effect` + manual `HttpClient` subscribe |
| One-shot or event stream (websocket, form events, interval) | RxJS, bridged with `toSignal` when the template needs a value | a signal updated from an unmanaged `subscribe` |
| React to a change with a side effect (log, analytics, imperative DOM) | `effect` | `effect` as a way to derive state |

## Rules

- **Read signals in the template** (`{{ count() }}`, `@if (visible())`). A signal that the template never reads does not refresh that view.
- **`computed` is lazy and cached.** It reruns when a signal it read changes. Do not put side effects in it.
- **`effect` runs for side effects.** It reruns when a signal it read changes. Writing a signal it also reads loops. Prefer `computed` or `linkedSignal`.
- **`linkedSignal`** is a writable signal whose value resets from a computation. Use the `source` + `computation` form when the user's edit should survive if their current value is still valid, and reset otherwise. Verify the signature for the installed version before writing the options object (`equal`, `set`).
- **Equality:** signals use `Object.is` by default. Replacing an object or array with a new one notifies. Mutating the same object does not. Update with `update` or replace the value.
- **Do not pass the signal itself into a plain function and expect tracking.** Call it (`count()`) inside a reactive context (`computed`, `effect`, or the template).

## RxJS interop

- `toSignal(source, { initialValue })` when a template needs the latest value of an observable. Without `initialValue`, the signal can throw until the first emit; check the installed signature.
- `toObservable(signal)` when an existing RxJS API must consume a signal.
- `takeUntilDestroyed()` (injection context, or pass a `DestroyRef`) for subscriptions that outlive a single call. Do not leave a bare `subscribe` in a component.
- `pendingUntilEvent()` (from `rxjs-interop`) keeps SSR unstable until an observable settles, on zoneless server rendering. See `change-detection.md`.

## Async: resource and httpResource

These are **not** v16 APIs. `resource` started as experimental in v19. `httpResource` started as experimental in v20 and was later called developer stable. Read `data.md` and the installed guide before using either.

Use them when the request's inputs are signals and the template should see `value`, `isLoading`, and `error` without a hand-rolled `effect`. For a single submit or a request that is not reactive, `HttpClient` is the right tool.

## Effects to avoid

- Copying a signal into another signal.
- Fetching in an `effect` when `resource` / `httpResource` (or a service the project already uses) expresses the same dependency.
- Writing to the DOM when a binding can do it.
- Nesting `effect` so that one write retriggers the next.
