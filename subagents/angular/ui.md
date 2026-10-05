# Angular: UI

Visual quality, the four UX states, spacing, type, and motion live in `~/.cursor/skills/frontend-agent/principles/css-ui.md` ("Estados de UX" and "Qualidade visual"). This file is how they show up in Angular.

## Follow the project

1. If the project already has a component library (Angular Material, CDK, PrimeNG, Spartan, a custom design system), use it. Do not add a second one.
2. A **new** Angular app with no design system: prefer **Angular Material** (and the CDK it needs). It matches the framework's theming and accessibility work. Confirm the current `ng add` schematic for the installed CLI before running it, and ask before adding the dependency.
3. Tailwind is appropriate when the project already uses it or the user asks. It is not the default the way it is for a new React app.

## Material and CDK

- Import only the components the template uses. A barrel of every Material module recreates the old bundle problem.
- Theme with the project's tokens (Material 3 theme when the installed version uses it). Do not hardcode a parallel palette.
- Keep Material's focus and keyboard behavior. Do not replace the inner button of a component to "simplify" the DOM.
- Overlay, dialog, and menu belong to the CDK or Material service the project uses, so focus moves and returns correctly.

## Angular Aria

Current docs include an Angular Aria guide for headless accessible widgets. The package and the import path are version-sensitive. Read [the guide](https://angular.dev/guide/aria/overview) for the installed version before adding a dependency. If the project already has Material, you usually do not need Aria for the same widget.

## States in Angular

- **Loading:** a skeleton that matches the final layout, shown from the request's loading flag (`resource.isLoading`, a signal, or an async-pipe snapshot). Do not flash it for a synchronous signal update.
- **Empty:** a branch in `@if` / `@empty` with one clear action.
- **Error:** the error branch plus a retry that calls the same load again. Do not render the raw `HttpErrorResponse`.
- **Success:** the content.

`@defer` placeholders are a loading state for **code**, not for data. A deferred component still needs its own data states.

## Accessibility

- Every control has a label (`<label for>` or Angular Material's `mat-label`).
- Icon-only buttons have an accessible name.
- Bind `[attr.aria-invalid]` and `[attr.aria-describedby]` when the form API does not do it for you.
- Respect `prefers-reduced-motion`. Angular's animation guide now prefers CSS. Do not add `@angular/animations` to a project that has migrated off it; confirm before importing the old animation module.
