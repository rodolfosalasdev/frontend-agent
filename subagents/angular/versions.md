# Angular: Versions and Documentation

There is no single API set for "v16+". Detect the installed version and use only what that version has. `https://angular.dev` documents the **latest** stable major. Copying from it into an older project is the most common way to ship code that does not compile.

## Detecting the version

1. Read the lockfile for the installed `@angular/core` (and `@angular/cli`, `@angular/forms`, `@angular/material`, `rxjs`, `zone.js` when present).
   - npm: `package-lock.json` → `packages["node_modules/@angular/core"].version`
   - pnpm: `pnpm-lock.yaml`
   - yarn: `yarn.lock`
   - bun: `bun.lock`
2. If dependencies are installed, `node_modules/@angular/core/package.json` is the version that actually runs.
3. If there is no lockfile, use the `package.json` range and say the exact version is unknown.
4. Node.js: `engines`, `.nvmrc`, `.node-version`.

## Where to read docs

Use the first source that matches the installed version:

1. **Project CLI best practices.** When the Angular CLI MCP server is available, call `get_best_practices` with the workspace path. It is written to follow the CLI that serves it. Prefer the project's own CLI (`ng mcp` from `node_modules`) over `npx @angular/cli mcp` with no version: the unversioned `npx` command tracks the latest CLI and can describe APIs this project does not have. Setup: [Angular CLI MCP](https://angular.dev/ai/mcp).
2. **Versioned site** for older majors, when it exists (`https://v17.angular.dev`, `https://v18.angular.dev`, and so on). These sites do not always publish `llms.txt`.
3. **Current docs** at [angular.dev](https://angular.dev) when the project is on the current major. The [llms.txt index](https://angular.dev/llms.txt) lists the guides. `search_documentation` also searches this site, so treat its answers as latest-major unless you confirmed the version.
4. **Update guide** for "when did this land?": [angular.dev/update-guide](https://angular.dev/update-guide).

If none of these can be checked, write `unverified for Angular X.Y` in the report and do not guess the signature.

## Features that moved

Confirm the row against the installed docs before using the feature. Dates below are from the official release notes and guides; they are a map, not a substitute for that check.

| Feature | What to assume until you verify |
|---|---|
| `signal`, `computed` | Developer preview in v16. Stable well before v20. Fine as the default reactivity in v16+ **after** you confirm the import and options for that minor. |
| `effect`, `linkedSignal`, `toSignal` | `effect` existed earlier; `linkedSignal` arrived with v19. The three are **stable in v20**. On 16–19, check the guide before using them. |
| `input()`, `output()`, signal queries | Signal inputs and queries became stable before v20. `output()` is stable in current docs. Do not use them on a version whose API reference does not list them. |
| Built-in control flow (`@if`, `@for`, `@switch`) | Compiler accepts them from v17. **Stable in v18.** `@empty` is part of `@for`. |
| `@defer` | Preview in v17, **stable in v18.** See `templates.md`. |
| `@let` | v18.1+. |
| Two-way binding to a signal | v17.2+. |
| Standalone by default | v19+. Older versions need `standalone: true` to defer or to import a component. |
| `resource` | Experimental in v19. The Angular 21.2.25 `.d.ts` still tags `resource` / `rxResource` as `@experimental`. Do not use them in production on a version whose types still say experimental. |
| `httpResource` | Experimental in v20, then developer stable. Not a default for every request. See `data.md`. |
| Signal forms (`@angular/forms/signals`) | **Require v21+** per the official prerequisites. Do not import them on v16–v20. |
| Zoneless | Experimental in v18, developer preview in v20, **stable in v20.2**, **default in v21+**. See `change-detection.md`. |
| Incremental hydration | Developer preview in v19, **stable in v20**. |
| `*ngIf`, `*ngFor`, `*ngSwitch` | Deprecated in v20. The v20 announcement said the deprecation policy allows removal in v22. Check whether the installed version still compiles them. Do not mass-migrate unless asked. |
| `ChangeDetectionStrategy.Default` renamed to `Eager` | Confirmed in Angular 21.2: `Eager` exists and `Default` is deprecated. `OnPush` is unchanged. Do not write `Eager` on a version whose API reference only lists `Default`. |

## CLI

- Prefer the project's `ng` (`npx ng` or `node_modules/.bin/ng`) so schematics match the installed framework.
- Read `ng new --help` and `ng generate --help` before inventing flags. Flags move between minors.
- Useful migrations, when the installed CLI provides them: control flow, standalone, signal inputs, signal queries, `inject()`. Run a migration only when it is the task, and review the diff.
- `onpush_zoneless_migration` in the CLI MCP plans an OnPush/zoneless migration one step at a time. Use it when the task is that migration. Do not apply a workspace-wide migration as a side effect of a feature.

## Experimental and preview APIs

Name the status in the report. Ask for confirmation before adding a developer-preview API to production code. Stable zoneless (v20.2+) and stable `@defer` (v18+) do not need that extra confirmation when the project is already on a version where they are stable and the change is local. Turning zoneless **on** for an existing Zone.js app is still a structural change: ask first.
