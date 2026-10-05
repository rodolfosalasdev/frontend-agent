# Example: Zoneless bootstrap

Validated against Angular 21.2.25: `ng new --zoneless` produced `app.config.ts` with `provideBrowserGlobalErrorListeners` and `provideRouter` only. There is no `provideZonelessChangeDetection()` and no `zone.js` dependency.

Stable in Angular 20.2. The default in v21+, where this provider is unnecessary. Experimental or preview before 20.2: do not enable it in production unless the user accepts that status. Guide: [zoneless](https://angular.dev/guide/zoneless).

## When to use

A new app whose CLI is v20.2 through v20.x, or an existing app whose task is the migration. On v21+, only check that nothing turned Zone.js back on.

## Bootstrap (v20.2+)

```ts
import {bootstrapApplication} from '@angular/platform-browser';
import {provideZonelessChangeDetection} from '@angular/core';
import {App} from './app/app';

bootstrapApplication(App, {
  providers: [provideZonelessChangeDetection()],
});
```

On v21+ omit `provideZonelessChangeDetection`. Delete `provideZoneChangeDetection` if it is only there to force Zone.js.

## Polyfills

Remove `zone.js` from the `build` and `test` `polyfills` arrays in `angular.json`, and remove `import 'zone.js'` from a `polyfills.ts` if the project has one. Uninstall the package only after the build no longer references it, and only with confirmation.

## Why

- Change detection runs when a signal, an async pipe, or a template listener notifies Angular, not after every patched task.
- The Zone.js payload and its startup cost leave the bundle.
- Components must already notify Angular. A field mutation will stop updating the view the moment Zone.js is gone. Migrate those call sites first (or use `onpush_zoneless_migration` in the CLI MCP when the task is the migration).

## Adapt

- SSR: register `PendingTasks` for async work that is not `HttpClient` or the router.
- Tests: `TestBed` is already zoneless by default. Add `provideZoneChangeDetection()` only in a test that must mimic a Zone.js app.
- `NgZone.onStable` stops emitting. Use `afterNextRender` or `afterEveryRender`.
