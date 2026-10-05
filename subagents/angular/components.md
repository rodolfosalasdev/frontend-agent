# Angular: Components

Official guides: [components](https://angular.dev/guide/components), [inputs](https://angular.dev/guide/components/inputs), [outputs](https://angular.dev/guide/components/outputs), [lifecycle](https://angular.dev/guide/components/lifecycle).

## Shape

- One component, one job. Smart components load data and compose children. Presentational components take inputs and emit outputs.
- Follow the project's prefix (`angular.json`), file names, and `standalone` style.
- From v19, standalone is the default. On older versions set `standalone: true` when the component must be imported or deferred.
- Put the template and styles where the project puts them (inline or separate files). Do not reformat a whole folder to a new style.

## Inputs and outputs

Prefer signal APIs **when the installed version has them and the file already uses that style**:

- `input()` and `input.required()` instead of `@Input()` on new components in a signal codebase.
- `output()` instead of `@Output()` + `EventEmitter` on those same components.
- `model()` for a two-way input, when the version documents it.

Do not mix `@Input()` and `input()` in one component without a reason. Do not migrate every decorator in a file you only needed to touch for a bugfix.

Signal queries (`viewChild`, `viewChildren`, `contentChild`, `contentChildren`) replace decorator queries when the version has them. A `viewChild` of a deferred component keeps that component eager (`templates.md`).

## State and lifecycle

- Local UI state is a `signal` or a `linkedSignal` (see `signals.md`).
- `computed` for derived template values.
- `ngOnInit` is for work that needs inputs to be set. In a signal component, reading an `input()` inside a `computed` or `effect` often replaces `ngOnInit`.
- `afterNextRender` / `afterEveryRender` for DOM measurement. They replace `NgZone.onStable` (see `change-detection.md`).
- Unsubscribe with `takeUntilDestroyed()` or by using a signal / `resource` that ends with the component. `ngOnDestroy` is the escape hatch, not the default.

## Change detection

New components are OnPush-compatible: the template reads signals or `AsyncPipe`, and listeners are declared in the template. See `change-detection.md`. Set `changeDetection: ChangeDetectionStrategy.OnPush` explicitly when the project's version does not default to it and the surrounding components set it.

## Host and projection

- Host bindings live in the `host` object of the decorator when the project uses that form. Confirm before using the newer host-binding syntax; it moved across versions.
- Project content with `<ng-content>` and, when needed, `select`. Do not reach into projected content with `document.querySelector`.

## Templates and styles

- Keep styles encapsulated (the project's default). Do not pierce encapsulation with `::ng-deep` unless the project already does and there is no public API.
- Global tokens (color, spacing, type) come from the design system, not from one component. See `ui.md` and `principles/css-ui.md`.
