# Example: Secure Server Action

Validated with Next.js 16.3.4 (App Router, React 19) and Zod 4: typecheck, lint, production build. Check the installed versions before copying (`versions.md`) and adapt validation, auth and data access to the project.

## When to use

Any mutation triggered from the UI. A Server Action is a public HTTP endpoint: anyone can call it with any arguments, so it must validate, authenticate and authorize **inside** the action, regardless of what the UI shows.

## Files

```text
lib/auth.ts                   # session helper (project-specific)
features/projects/data.ts     # server-only data access + cache tag
features/projects/schemas.ts  # validation schemas and state types (shared with the form)
features/projects/actions.ts  # Server Actions
```

## Data access

```ts
// features/projects/data.ts
import 'server-only';

export const PROJECTS_TAG = 'projects';

export type Project = { id: string; name: string; description: string; ownerId: string };

const projects = new Map<string, Project>();

export async function findProject(id: string): Promise<Project | undefined> {
  return projects.get(id);
}

export async function insertProject(input: Omit<Project, 'id'>): Promise<Project> {
  const project = { ...input, id: crypto.randomUUID() };
  projects.set(project.id, project);
  return project;
}

export async function removeProject(id: string): Promise<void> {
  projects.delete(id);
}
```

## Schemas and result types

```ts
// features/projects/schemas.ts
import { z } from 'zod';

export const createProjectSchema = z.object({
  name: z
    .string()
    .trim()
    .min(3, 'Name must have at least 3 characters.')
    .max(80, 'Name must have at most 80 characters.'),
  description: z.string().trim().max(500, 'Description must have at most 500 characters.'),
});

export type CreateProjectFields = keyof z.infer<typeof createProjectSchema>;

export type CreateProjectState = {
  status: 'idle' | 'error' | 'success';
  message?: string;
  fieldErrors?: Partial<Record<CreateProjectFields, string[]>>;
  values?: Record<CreateProjectFields, string>;
};
```

## Actions

```ts
// features/projects/actions.ts
'use server';

import { updateTag } from 'next/cache';
import { z } from 'zod';
import { getSession } from '@/lib/auth';
import { findProject, insertProject, removeProject, PROJECTS_TAG } from './data';
import { createProjectSchema, type CreateProjectState } from './schemas';

function readText(formData: FormData, key: string): string {
  const value = formData.get(key);
  return typeof value === 'string' ? value : '';
}

export async function createProject(
  _prevState: CreateProjectState,
  formData: FormData,
): Promise<CreateProjectState> {
  const values = { name: readText(formData, 'name'), description: readText(formData, 'description') };

  const session = await getSession();
  if (!session) {
    return { status: 'error', message: 'Your session expired. Sign in again.', values };
  }

  const parsed = createProjectSchema.safeParse(values);
  if (!parsed.success) {
    return {
      status: 'error',
      message: 'Fix the highlighted fields.',
      fieldErrors: z.flattenError(parsed.error).fieldErrors,
      values,
    };
  }

  try {
    await insertProject({ ...parsed.data, ownerId: session.userId });
  } catch {
    return { status: 'error', message: 'Could not create the project. Try again.', values };
  }

  updateTag(PROJECTS_TAG);
  return { status: 'success', message: `Project "${parsed.data.name}" created.` };
}

const projectIdSchema = z.string().min(1).max(64);

export type DeleteProjectResult =
  | { ok: true }
  | { ok: false; error: 'invalid_input' | 'unauthenticated' | 'forbidden' | 'not_found' };

export async function deleteProject(projectId: unknown): Promise<DeleteProjectResult> {
  const session = await getSession();
  if (!session) return { ok: false, error: 'unauthenticated' };

  const parsed = projectIdSchema.safeParse(projectId);
  if (!parsed.success) return { ok: false, error: 'invalid_input' };

  const project = await findProject(parsed.data);
  if (!project) return { ok: false, error: 'not_found' };
  if (project.ownerId !== session.userId && session.role !== 'admin') {
    return { ok: false, error: 'forbidden' };
  }

  await removeProject(project.id);
  updateTag(PROJECTS_TAG);
  return { ok: true };
}
```

## Why

- **Arguments are untyped at runtime.** `projectId: unknown` and `readText` make that explicit; Zod turns input into trusted data.
- **Authentication and authorization inside the action.** Ownership is checked against the stored record, never against data sent by the client. Hiding a button is not authorization.
- **Typed results instead of thrown errors** for expected failures, so the UI can render specific messages. Unexpected errors still throw and reach `error.tsx`.
- **Errors do not leak internals** (no stack traces or database messages in the returned state).
- **Submitted values are returned on error** so the form can preserve what the user typed.
- **Cache invalidation after the write.** `updateTag(tag)` expires the tag and makes the next read wait for fresh data (read-your-own-writes). It only works inside Server Actions.

## Version and configuration notes

- `updateTag` requires reads tagged with that tag (`cacheTag` inside `'use cache'`, or `fetch(..., { next: { tags } })`). Without tagged reads, use `revalidatePath` for the affected route.
- Outside Server Actions (e.g. Route Handlers, webhooks) use `revalidateTag(tag, 'max')`; the single-argument form is deprecated in 16.
- Check `updateTag.md`, `revalidateTag.md` and the `server-actions` / `data-security` guides in the bundled docs for the installed version.
- Zod 4 uses `z.flattenError(error)`; Zod 3 used `error.flatten()`.

## Adapt

- Use the project's validation library and auth helper if they differ; keep the order: authenticate, validate, authorize, mutate, invalidate.
- Add rate limiting for sensitive or expensive actions.
- For the form that calls `createProject`, see `form-with-pending-and-errors.md`.
