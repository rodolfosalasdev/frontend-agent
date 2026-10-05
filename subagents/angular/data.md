# Angular: HTTP and Data

Official guides: [HttpClient](https://angular.dev/guide/http), [interceptors](https://angular.dev/guide/http/interceptors), [httpResource](https://angular.dev/guide/http/http-resource).

General HTTP rules (verbs, status codes, retries, contracts) live in `~/.cursor/skills/frontend-agent/principles/http.md`.

## HttpClient

- Provide `HttpClient` once, the way the project already does (`provideHttpClient(withFetch())` when the version supports the fetch backend; confirm the options).
- Functional interceptors in new code. Keep class interceptors if the project uses them.
- Type the response (`http.get<Client[]>(url)`). Validate at the boundary when the payload is not fully trusted (the project's schema library, or a narrow check). Do not trust the generic as proof.
- Cancellation: pass an `HttpContext` or abort signal when the installed `HttpClient` supports it, and unsubscribe on destroy for a manual subscribe. Prefer `toSignal` or the async pipe over a manual subscribe. Use `resource` / `httpResource` only when the installed types are no longer `@experimental` (see `versions.md`).
- Errors: map to a value the UI can show (message + retry). Do not surface stack traces or raw backend payloads.
- Credentials and tokens stay in an interceptor the project already has. Do not log them. Do not put secrets in the repo.

## httpResource and resource

Use `httpResource` when **all** of these are true:

- the installed version documents it **and** the `.d.ts` is not `@experimental` (experimental in v20; in 21.2.25 `resource` / `rxResource` were still tagged experimental);
- the URL or the request depends on signals and should refetch when they change;
- the template needs loading and error as part of that same value.

Do not use it for a form submit, a one-shot command, or a websocket. Those stay `HttpClient` or RxJS.

`resource()` is the lower-level async primitive (experimental in v19). Reach for it when `httpResource` does not fit and a `computed` cannot express the async work. Read the installed guide for `params`, `loader`, and the status signals (`value`, `isLoading`, `error`, `status`). Names have moved; do not guess them.

## Where fetching lives

- A component may call a service. A component should not build URLs and headers inline if a service already owns that API.
- Do not fetch in the constructor. An `input()` change that should refetch belongs in `httpResource` / `resource`, or in an observable that depends on `toObservable(input)`.
- Parallel requests that do not depend on each other start together (`forkJoin`, or two resources). Do not await them in series by accident.
- Cache only when the project has a cache policy (what, where, key, lifetime, invalidation). Do not add a second cache beside one that exists.

## States

A data view this task creates exposes loading, empty, error, and success from the real request state, not from a boolean that is never set. See the Definition of done in `agent.md`.
