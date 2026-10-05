# Angular: Dependency Injection

Official guide: [dependency injection](https://angular.dev/guide/di).

## Rules

- **`inject()` in new code** when the project has adopted it. It works in field initializers, `computed`, and factory functions, as long as it runs in an injection context.
- Constructor DI stays when the file already uses it. Do not convert a constructor just because you opened the file.
- **`providedIn: 'root'`** for stateless or app-wide services. Provide on a component or a route when the instance must be scoped (a form helper, a page-local store).
- Do not provide the same service in `root` and again on every component unless a new instance is the point.
- **Injection tokens** for values that are not classes (`InjectionToken`), with a factory when there is a sensible default. Lightweight tokens matter in libraries; read the [token guide](https://angular.dev/guide/di/lightweight-injection-tokens) before inventing a token pattern for an app.
- **`DestroyRef`** and `takeUntilDestroyed()` need an injection context. In a callback that lost it, pass the `DestroyRef` you captured earlier.
- Route-level providers and lazy-loaded services: a service provided in a lazy route is not the root instance. Do not expect a lazy service to be a singleton for the whole app.

## What does not belong in a service

- Reaching into a component's view.
- Storing UI-only state that no other component reads (that is a signal on the component).
- Caching HTTP data with no invalidation story. If the project has a cache, use it. If it does not, do not add a global cache as a side effect.
