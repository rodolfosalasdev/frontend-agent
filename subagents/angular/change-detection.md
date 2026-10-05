# Angular: Change Detection and Zoneless

Zoneless is the performance default **when the installed version supports it and the app is compatible**. It is not a refactor you apply in the middle of an unrelated task.

Official guide: [zoneless](https://angular.dev/guide/zoneless).

## What the version does

| Installed version | Zoneless |
|---|---|
| v16–v17 | Not available. Stay on Zone.js. Performance work is OnPush, `trackBy` / later `@for` track, and not running change detection more than the app needs. |
| v18–v20.1 | Experimental, then developer preview. Do not enable it in production unless the user explicitly accepts preview status. |
| v20.2+ | **Stable.** Enable with `provideZonelessChangeDetection()` at bootstrap. Ask before flipping an existing Zone.js app. |
| v21+ | **Default** for new applications. Do not add the provider. Check that `provideZoneChangeDetection` is not overriding the default. New apps should not include `zone.js`. |

Confirm this table against the installed guide before changing bootstrap.

## Why zoneless is faster

Zone.js patches browser APIs and schedules change detection when a task finishes, whether or not state changed. That costs bundle size, startup, and extra cycles, and it makes stack traces harder to read. Zoneless schedules change detection only from Angular notifications.

## What actually refreshes a view

Angular refreshes a view when one of these happens:

- a **signal read in the template** is updated;
- `AsyncPipe` receives a value (`markForCheck`);
- `ComponentRef.setInput` or a signal `input()` updates;
- a **bound** host or template listener runs;
- a view marked dirty by one of the above is attached, or a view is removed;
- a render hook does one of the above.

These do **not** refresh a zoneless or OnPush view:

- mutating a field or an object in place;
- `setTimeout` / `Promise` / an observable emission that nobody marks;
- `FormControl.setValue` / `patchValue` by themselves (see below).

`OnPush` is the recommended step toward zoneless compatibility. It is not strictly required if the component always notifies Angular. In Angular 21.2 the enum members are `OnPush` and `Eager`; `Default` is deprecated as an alias of `Eager`. Do not write `Eager` unless that member exists on the installed version. A v21+ CLI app is zoneless by default; it does not automatically set `OnPush` on every component.

A library component that hosts arbitrary user views via `ViewContainerRef.createComponent` may have to stay on the eager strategy so those children still refresh. Content projection is not that case.

## Enabling zoneless (v20.2+, not the default yet)

```ts
bootstrapApplication(App, {
  providers: [provideZonelessChangeDetection()],
});
```

Then remove Zone.js from the build:

- drop `zone.js` and `zone.js/testing` from the `polyfills` of the `build` and `test` targets in `angular.json`;
- remove `import 'zone.js'` from `polyfills.ts` if the project has one;
- uninstall `zone.js` only after the build no longer references it, and only with confirmation.

## APIs that break or change

- `NgZone.onMicrotaskEmpty`, `onUnstable`, `onStable`, and `isStable` do not tell you that change detection finished. `isStable` stays `true`. Replace a "wait until stable" with `afterNextRender` (once) or `afterEveryRender` (spans several cycles), or with a direct DOM API such as `MutationObserver`.
- `NgZone.run` and `NgZone.runOutsideAngular` can stay. Removing them from a library can make Zone.js apps slower.
- SSR without Zone.js must use `PendingTasks` (`run` or `add`) so serialization waits for async work. `HttpClient` and the router already register pending tasks. `pendingUntilEvent()` covers observables.

## Forms

Reactive form model updates emit on the form observables and **do not** schedule change detection. If the template reads `form.value` or `form.status` as plain fields, connect the stream (`AsyncPipe`, `toSignal`, or `markForCheck`). Signal forms (v21+) are a different API. See `forms.md`.

## Tests

`TestBed` is zoneless by default, even when `zone.js` is in the polyfills. To force Zone.js behavior in a test, add `provideZoneChangeDetection()`.

Prefer `await fixture.whenStable()` in **new** tests so a missing notification fails the test. `fixture.detectChanges()` forces a refresh and hides that bug. Do not rewrite an existing suite to `whenStable` as a side effect.

`provideCheckNoChangesConfig({ exhaustive: true, interval })` throws if a binding changed without a notification. Use it while migrating, not as a permanent production tax, and confirm the API for the installed version.

## Deciding for this task

- **New project on v21+:** zoneless is already the default. Write components that notify Angular. Do not add `zone.js`.
- **New project on v20.2+:** include zoneless in the creation plan (`bootstrap.md`) and ask.
- **Existing Zone.js app:** leave it unless the task is the migration. New components should still be OnPush-compatible (signals or `AsyncPipe`) so a later migration is local.
- **A view that does not update:** first check whether the write notifies Angular. Do not "fix" it by turning Zone.js back on.
