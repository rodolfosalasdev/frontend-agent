# Angular: Testing, Review, and Refactoring

Official guides: [testing](https://angular.dev/guide/testing), [component harnesses](https://angular.dev/guide/testing/component-harnesses-overview). The review roadmap in `~/.cursor/skills/frontend-agent/principles/testing.md` still applies.

## Tests

- Use the project's runner (Jasmine/Karma, Jest, or Vitest). Do not add a second runner.
- Test behavior through the DOM and harnesses, not private fields.
- New tests in a zoneless app use `await fixture.whenStable()` so a missing notification fails. See `change-detection.md`. Do not convert an old suite as a side effect.
- `@defer`: `DeferBlockBehavior.Manual` when the test must step through placeholder, loading, and complete (`templates.md`).
- HTTP: `provideHttpClientTesting()` / `HttpTestingController` on versions that have them. Confirm the provider name. Do not hit the network.
- One example spec is enough when the task is a small component. Cover loading, empty, error, and the success path when the task created that view.

## Review additions

On top of the general roadmap, look for:

- a version API the installed Angular does not have;
- a signal the template never reads, or a mutable field the template reads under OnPush or zoneless;
- `@defer` of above-the-fold content, a barrel import, or a non-standalone dependency that will not split;
- a bare `subscribe` without `takeUntilDestroyed` or an async pipe;
- reactive form updates that do not notify change detection;
- `bypassSecurityTrust*` on user input;
- a new eager import of a heavy library in `App`.

## Refactoring

- Leave the behavior the same unless the task changes it.
- Do not combine a feature change with a control-flow migration, a zoneless migration, or a signal-input migration.
- If a schematic can do a mechanical migration and the task **is** that migration, run the project's `ng generate` schematic and review the diff. Do not hand-rewrite hundreds of files.
