# Example: Typed reactive form

Validated with Angular 21.2.25: production `ng build` succeeded with `ReactiveFormsModule` and `@if` field errors.

Use this on Angular v16 through v20, and on later versions when the surrounding feature already uses reactive forms. Signal forms (`@angular/forms/signals`) require v21+ and are documented in `forms.md`. Do not import them here.

## When to use

A new form in a reactive-forms project: pending submit, a field error tied to the control, and the value kept after a failed submit.

## Component

```ts
import {ChangeDetectionStrategy, Component, signal} from '@angular/core';
import {FormControl, FormGroup, ReactiveFormsModule, Validators} from '@angular/forms';

@Component({
  selector: 'app-create-project',
  imports: [ReactiveFormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './create-project.html',
})
export class CreateProject {
  protected readonly submitted = signal(false);
  protected readonly form = new FormGroup({
    name: new FormControl('', { nonNullable: true, validators: [Validators.required, Validators.minLength(3)] }),
  });

  protected async submit(): Promise<void> {
    this.submitted.set(true);
    if (this.form.invalid) return;
    // await api.create(this.form.getRawValue());
  }
}
```

On versions that are not standalone by default, add `standalone: true` or declare the component in the project's NgModule and import `ReactiveFormsModule` there. Drop `imports` if the module already imports it.

## Template

```html
<form [formGroup]="form" (ngSubmit)="submit()">
  <label for="project-name">Name</label>
  <input id="project-name" type="text" formControlName="name" [attr.aria-invalid]="submitted() && form.controls.name.invalid" [attr.aria-describedby]="submitted() && form.controls.name.invalid ? 'project-name-error' : null" />
  @if (submitted() && form.controls.name.hasError('minlength')) {
    <p id="project-name-error">Name must have at least 3 characters.</p>
  }
  <button type="submit">Create project</button>
</form>
```

`@if` needs v17+. On v16, use `*ngIf` and import `NgIf`, or the project's equivalent.

## Why

- `nonNullable` keeps `getRawValue().name` a `string` under strict templates.
- The error is associated with the input. The value stays because the form is not reset on failure.
- `submitted` is a signal, so zoneless change detection refreshes the error. Reading `form.controls.name.invalid` in the template does **not** by itself subscribe to form events. If the error fails to appear after `patchValue` in a zoneless app, bridge status with `toSignal(form.statusChanges)` or `markForCheck` (`change-detection.md`).

## Adapt

- Disable the button while the request is in flight.
- On v21+ in a signal-forms codebase, use `form` and `FormField` from `@angular/forms/signals` instead of this example. Re-read the installed guide first.
