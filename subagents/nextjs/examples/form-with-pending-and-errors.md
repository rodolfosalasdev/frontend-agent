# Example: Form with pending state and errors

Validated with Next.js 16.3.4 (App Router, React 19): typecheck, lint, production build, and in the browser (server-side error, preserved values, success message, form reset). Check the installed version before copying (`versions.md`).

## When to use

Any form that submits to a Server Action and must show field errors, a pending state and a result message. It uses the `createProject` action and schemas from `server-action.md`.

## Files

```text
app/projects/new/page.tsx                 # Server Component page
app/projects/new/create-project-form.tsx  # Client Component form
```

## Page

```tsx
// app/projects/new/page.tsx
import type { Metadata } from 'next';
import { CreateProjectForm } from './create-project-form';

export const metadata: Metadata = { title: 'New project' };

export default function NewProjectPage() {
  return (
    <main className="mx-auto max-w-3xl p-6">
      <h1 className="text-2xl font-semibold">New project</h1>
      <CreateProjectForm />
    </main>
  );
}
```

## Form

```tsx
// app/projects/new/create-project-form.tsx
'use client';

import { useActionState } from 'react';
import { createProject } from '@/features/projects/actions';
import type { CreateProjectState } from '@/features/projects/schemas';

const initialState: CreateProjectState = { status: 'idle' };

export function CreateProjectForm() {
  const [state, formAction, isPending] = useActionState(createProject, initialState);
  const nameError = state.fieldErrors?.name?.[0];
  const descriptionError = state.fieldErrors?.description?.[0];

  return (
    <form action={formAction} className="mt-6 max-w-md space-y-5">
      <div className="flex flex-col gap-1">
        <label htmlFor="project-name" className="text-sm font-medium">
          Name
        </label>
        <input
          id="project-name"
          name="name"
          required
          minLength={3}
          maxLength={80}
          defaultValue={state.values?.name}
          aria-invalid={nameError ? true : undefined}
          aria-describedby={nameError ? 'project-name-error' : undefined}
          className="rounded-md border px-3 py-2 aria-invalid:border-red-600"
        />
        {nameError && (
          <p id="project-name-error" className="text-sm text-red-700">
            {nameError}
          </p>
        )}
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="project-description" className="text-sm font-medium">
          Description <span className="font-normal text-neutral-600">(optional)</span>
        </label>
        <textarea
          id="project-description"
          name="description"
          rows={4}
          maxLength={500}
          defaultValue={state.values?.description}
          aria-invalid={descriptionError ? true : undefined}
          aria-describedby={descriptionError ? 'project-description-error' : undefined}
          className="rounded-md border px-3 py-2 aria-invalid:border-red-600"
        />
        {descriptionError && (
          <p id="project-description-error" className="text-sm text-red-700">
            {descriptionError}
          </p>
        )}
      </div>

      <p
        role="status"
        className={state.status === 'error' ? 'text-sm text-red-700' : 'text-sm text-green-700'}
      >
        {state.message}
      </p>

      <button
        type="submit"
        disabled={isPending}
        className="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 disabled:opacity-60"
      >
        {isPending ? 'Creating…' : 'Create project'}
      </button>
    </form>
  );
}
```

## Why

- **`useActionState`** gives the action result and `isPending` without manual state. The action signature receives `prevState` first (see the `forms` guide in the bundled docs).
- **Progressive enhancement:** `action={formAction}` works before hydration.
- **Native constraints as hints, server as the source of truth:** `required`/`minLength` give instant feedback; the server re-validates (in the browser test, `"  ab"` passes native validation but fails the server's trimmed check and shows the field error).
- **Preserved values:** React resets uncontrolled forms after an action. Returning `values` on error and using them as `defaultValue` keeps what the user typed; on success no values are returned, so the form clears.
- **Accessible errors:** each error is linked with `aria-describedby`, the field has `aria-invalid`, and the summary message sits in a persistent `role="status"` region, so it is announced.
- **No double submission:** the button is disabled and relabeled while pending.

## Adapt

- With shadcn/ui, use its form field components (`Field`/`Form`, `Input`, `Textarea`, `Button`) and project tokens instead of raw utility colors; keep the same ARIA wiring.
- For long forms, move focus to the first invalid field after a failed submission.
- For success, you can `redirect()` inside the action (e.g. to the new project page) or show a toast (`sonner`) in addition to the inline message.
