# Angular: Verification

Run the checks that match the change. Use the project's `package.json` scripts and `angular.json` targets. Do not invent a runner.

## 1. Static checks

| Check | Command |
|---|---|
| Production build | the project's build script, or `ng build` for the affected project |
| Unit tests | the project's test script, or `ng test` with a watch mode disabled (`--watch=false` when that flag exists) |
| Lint | the project's lint script, when it has one |
| Types | the build already typechecks. A separate `tsc` is optional and must use the project's `tsconfig` |

A production build is required when the change can affect bundles, `@defer` chunks, route loading, SSR, or budgets. Read the budget warnings. If a `@defer` was supposed to split, confirm a separate chunk exists in the build output. HMR (`ng serve`) eager-loads those chunks and is not evidence.

## 2. Dev server

Use `ng serve` to see compile errors while editing. Do not treat a green dev server as a performance result.

If the Angular CLI MCP server is connected, `devserver.start`, `devserver.wait_for_build`, and `run_target` are valid ways to do the same checks. Prefer them when they are available. Stop the server when you are done.

## 3. Browser

When the change is visible and browser tools are available:

- Load the page in a production build (`ng build` then the project's serve target) when the bug is about loading, hydration, or chunks. Dev server is enough for layout and interaction.
- Viewports around 375px and 1280px. No horizontal overflow, no overlapping controls.
- Console: no hydration mismatch, no unhandled exception.
- Keyboard: reach the new controls, see focus, activate with Enter or Space.
- The four states, when this task created them: force an empty result and, if practical, an error.
- A filterable list: the query string matches the view, and reloading the URL restores it.

If browser tools are not available, write **`visual verification not run`** in the report and say what the Frontend Agent should check. Do not claim screenshots you did not take.

## 4. Zoneless

When the task changes bootstrap or a view that "does not update":

- State whether `zone.js` is still in the polyfills.
- Exercise the interaction that should refresh the view. A passing unit test that calls `detectChanges()` is not that exercise.
