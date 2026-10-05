# Angular: Performance

General Web Vitals and network rules live in `~/.cursor/skills/frontend-agent/principles/performance.md`. This file is the Angular-specific work. Change detection is in `change-detection.md`. `@defer` rules are in `templates.md`.

## Default budgets

Do not hardcode a Core Web Vitals number that will go stale. "Good" means the current [web.dev](https://web.dev/articles/vitals) thresholds, measured at the 75th percentile of real users when field data exists.

| Budget | Default until the project overrides it |
|---|---|
| LCP, INP, CLS | Within the current "good" thresholds on web.dev |
| Initial JS | No increase without a reason. A new heavy dependency or an eager import of a deferred component is a regression |
| Lazy chunks | A `@defer` or `loadComponent` that was supposed to split still produces a separate chunk in the **production** build |
| Route mode | An SSR or prerender route does not become client-only, and a static prerender does not become per-request, unless the task requires it |
| Change detection | A new view notifies Angular. It does not depend on a Zone.js sweep |

`angular.json` `budgets` are the project's contract. Stay inside them. If a necessary change crosses a budget, say so in the report instead of raising the budget silently.

## Initial load, in order

1. **Keep the first screen small.** The component that paints the LCP element stays eager. Everything heavy and below the fold is `@defer` (stable since v18) or a lazy `loadComponent` route.
2. **Do not defer the LCP.** A placeholder swap in the first viewport costs CLS. See `templates.md`.
3. **Images.** Use `NgOptimizedImage` (`ngSrc`) when the project is on a version that has it (v15+). Mark the **LCP image** as priority. Give width and height, or `fill` with a sized parent, so the layout does not jump. Do not priority-load a gallery. Confirm the inputs in the [image guide](https://angular.dev/guide/image-optimization) for the installed version.
4. **Routes.** Feature routes use `loadComponent` (standalone) or `loadChildren`. Do not import a feature component into `App` just to reference its type.
5. **Fonts.** Prefer a font setup that does not block rendering (the CLI's font optimization or a `<link rel="preload">` the project already uses). Do not add a new third-party font without a reason.
6. **Third-party scripts.** Load them after the first paint, or behind a defer trigger. They are a common INP cost.

## Runtime

- **Zoneless** (v20.2+ stable, v21+ default) removes Zone.js patches. That is the largest framework-level runtime win. Do not enable it as a drive-by. See `change-detection.md`.
- **OnPush-compatible components** skip refresh when nothing notified them. Mutating an object in place does not notify a signal.
- **`@for` track** keeps DOM nodes. A missing or unstable track re-creates lists and hurts INP on large tables.
- **No work in template expressions.** Filter, sort, and format in a `computed` or in the class. A method call in a binding runs every refresh.
- **Effects are not a render path.** An `effect` that writes a signal the template reads doubles the work. Use `computed`.
- **CDRef.detectChanges() in a loop** forces local refreshes and hides missing notifications. Fix the notification instead.

## Hydration and SSR

Read [hydration](https://angular.dev/guide/hydration) and [incremental hydration](https://angular.dev/guide/incremental-hydration) for the installed version.

- Client hydration avoids re-creating the server DOM. Do not destroy and recreate the app on bootstrap.
- A mismatch (different HTML on server and client) costs a full client render. Common causes: `Date`, `Math.random`, `window` during render, and locale formatting that differs by timezone. Keep the first render deterministic.
- Incremental hydration (stable in v20) combines `@defer` with `hydrate` triggers so JS for below-the-fold blocks loads when they are needed. Do not invent the trigger syntax. Copy it from the installed guide.
- Event replay (shipped with SSR around v18) records browser events that happen before hydration. Confirm `withEventReplay` (or the current equivalent) before adding it.
- Zoneless SSR uses `PendingTasks` so the server waits for real async work. See `change-detection.md`.

## Diagnosing

- Production build (`ng build`) shows bundles and budgets. `ng serve` with HMR does not: HMR eager-loads `@defer` chunks.
- Chrome Performance and Angular DevTools show change-detection time. A long task on every click in a Zone.js app is often a full-tree refresh.
- If a list is slow, check track, how many components are eager, and whether the template calls methods. Do not start by adding `OnPush` flags at random.

## Interaction responsiveness

- Debounce text filters that hit the network. Local filtering of a small list does not need a debounce.
- Do not run unrelated work inside an event binding. A click handler should update a signal and return.
- Large synchronous work (parsing a big file) belongs off the main thread (`Worker`) when it shows up in a profile, not by default.
