# Angular: Forms

Official guides: [forms](https://angular.dev/guide/forms), [typed forms](https://angular.dev/guide/forms/typed-forms), [validation](https://angular.dev/guide/forms/form-validation), [signal forms](https://angular.dev/guide/forms/signals/overview).

## Which API

| Situation | API |
|---|---|
| The file already uses reactive forms | Stay. Typed `FormGroup` / `FormControl`. |
| The file already uses template-driven forms | Stay, unless the task is to replace that form. |
| New form, Angular **v16–v20** | Typed reactive forms. Signal forms do not exist yet. |
| New form, Angular **v21+**, and the project has adopted signal forms or has no form style yet | Signal forms are the current official recommendation for new signal-based apps. |
| New form, v21+, inside a reactive-forms codebase | Match the codebase. Do not introduce a second form system in one feature without a reason. |

The official prerequisites say signal forms require **Angular v21 or higher** and ship in `@angular/forms`. Import from `@angular/forms/signals` (`form`, `FormField`, validators such as `required` and `email`). The `FormField` directive must be in the component `imports`. Re-check the import list for the installed minor before writing it.

## Behavior every form needs

- Pending submit: disable the button or show progress so the user cannot double-submit.
- Errors next to the field, associated with it (`aria-describedby` or the control's error id), and `aria-invalid` when the field is invalid and the user has tried to submit or has touched it. Do not announce errors on the first keystroke unless the project already does.
- Values stay after a failed submit.
- Success is visible (message, navigation, or both).
- Client validation is a hint. The server still validates.
- Destructive actions ask for confirmation and say what will happen.

## Zoneless and reactive forms

`setValue`, `patchValue`, and `FormArray.push` update the model and **do not** schedule change detection. Bind through a signal, `AsyncPipe`, or call `markForCheck`. See `change-detection.md`.

## Types

- `FormControl<string>` not `FormControl<string | null>` unless the control can actually be null. Use `{ nonNullable: true }` when the project's TypeScript is strict.
- Do not type a form as `any` to silence a nested group.
