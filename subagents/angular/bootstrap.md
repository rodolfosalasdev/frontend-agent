# Angular: Bootstrapping a New Project

Use this only when creating an application **from scratch**. Never apply it wholesale to an existing repo.

## Step 0: plan, then confirm

Creating a project installs dependencies and writes many files. Before running anything, send the Frontend Agent a short plan:

- name and directory;
- the CLI version you will run (`ng version` or the `ng new --help` you checked);
- zoneless or Zone.js, and why (see the table below);
- routing, styles, SSR or not;
- the test runner the current CLI offers;
- UI: Angular Material, or none until the user decides;
- anything marked **(proposed)**.

Wait for confirmation.

## Baseline

| Area | Default |
|---|---|
| CLI | The current stable `ng new`, flags taken from **that** CLI's `--help`, not from memory |
| Language | TypeScript, `strict` |
| Components | Standalone (the default on v19+) |
| Routing | On |
| Change detection | Zoneless when the CLI version's default is zoneless (v21+). On v20.2+, propose `provideZonelessChangeDetection()` and removing `zone.js`. On v16–v20.1, Zone.js |
| Styles | The CLI default, unless the user asked for another |
| SSR | Off, unless the user asked. SSR changes hydration, `PendingTasks`, and deploy |
| UI | Angular Material **(proposed)** |
| Tests | Whatever `ng new` configures. Do not swap it afterwards |
| Formatting | The project's default. Do not add Prettier unless the user asks **(proposed)** |

## Step 1: scaffold

```bash
ng new <name>
```

Add only flags you read in `ng new --help` for this CLI (`--routing`, `--style`, `--ssr`, `--zoneless`, package-manager flags). Package manager: pnpm when the user or the Frontend Agent uses pnpm and the CLI supports it.

## Step 2: zoneless check

After scaffold, open `src/app/app.config.ts` (or the equivalent bootstrap):

- v21+: confirm `provideZoneChangeDetection` is absent and `zone.js` is not in `polyfills`.
- v20.2+ and the plan chose zoneless: add `provideZonelessChangeDetection()` and remove `zone.js` from polyfills.
- Older: leave Zone.js.

## Step 3: structure

Follow the CLI layout. A feature folder is enough:

```text
src/app/
  app.config.ts
  app.routes.ts
  core/            # singletons: interceptors, auth
  shared/          # presentational components used by more than one feature
  features/
    <feature>/
      <feature>.ts
      <feature>.html
```

Match names to the CLI schematic (`ng generate component`). Do not invent a second convention.

## Step 4: app shell

- Router outlet, a skip link, and a document title strategy.
- `provideHttpClient` only if the app calls HTTP.
- Global error page and a not-found route.
- No data fetching in the root component.

## Step 5: verify

`ng build` and the test target. Then `verification.md`. Report the CLI version, whether the app is zoneless, and every decision the user still has to make.
