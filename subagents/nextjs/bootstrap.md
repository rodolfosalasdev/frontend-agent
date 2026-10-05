# Next.js: Bootstrapping a New Project

Use this only when creating a project **from scratch**. For existing projects, never apply this baseline wholesale: follow the project.

## Step 0: present the plan and get confirmation

Creating a project installs dependencies and writes many files. Before running anything, present a short creation plan to the Frontend Agent (as a blocking question in the report) with:

- project name and location;
- the baseline below, highlighting any deviation;
- the items marked **(proposed)**, which need explicit confirmation;
- anything the user must decide (auth provider, database, deployment target).

Only proceed after confirmation.

## Baseline

| Area | Default |
|---|---|
| Package manager | **pnpm** |
| Scaffolding | `create-next-app` of the current stable version |
| Language | TypeScript, `strict: true` |
| Router | App Router |
| Styling | Tailwind CSS (version installed by `create-next-app`) with design tokens |
| Components | shadcn/ui, initialized with its CLI |
| Lint / format | **ESLint + Prettier** |
| Unit / component tests | **Vitest + Testing Library** |
| E2E | **Playwright** |
| Env validation | **Zod** schema validated at startup **(proposed)** |
| Agent support | `AGENTS.md` pointing to the bundled docs; `.mcp.json` with `next-devtools-mcp` **(proposed)** |
| Architecture | `architecture.md` created from the Frontend Agent template |

## Step 1: scaffold

Check the flags in the bundled or online `create-next-app` docs for the version being installed. For Next.js 16.x:

```bash
pnpm create next-app@latest <name> --ts --tailwind --eslint --app --src-dir --import-alias "@/*" --use-pnpm --agents-md
```

- `--react-compiler` only if the team wants the React Compiler (discuss; it changes memoization guidance, see `react.md`).
- After scaffolding, read the generated `AGENTS.md` and use the bundled docs in `node_modules/next/dist/docs/` for every following step.

## Step 2: TypeScript and tooling

- Confirm `strict: true` in `tsconfig.json`; consider `noUncheckedIndexedAccess`.
- Scripts in `package.json`:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint .",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "typecheck": "next typegen && tsc --noEmit",
    "test": "vitest run",
    "test:e2e": "playwright test"
  }
}
```

- Prettier: add `prettier` and `eslint-config-prettier` (so ESLint does not fight formatting); if the project uses Tailwind, `prettier-plugin-tailwindcss` for class ordering.
- Add `.prettierrc` and `.prettierignore` (ignore `.next`, `node_modules`, generated files).

## Step 3: structure

Organize by feature; keep shared primitives separate:

```text
src/
  app/                    # routes only: layouts, pages, loading, error, route handlers
  features/
    <feature>/
      components/         # feature UI (server and client)
      actions.ts          # Server Actions of the feature
      data.ts             # server-side data access ('server-only')
      schemas.ts          # validation schemas
      types.ts
  components/
    ui/                   # shadcn/ui primitives (shared)
  lib/                    # cross-cutting utilities (env, utils, auth helpers)
tests/
  e2e/                    # Playwright specs
```

Adapt names to the team's preference, but keep the separation: routes thin, data access server-only, UI primitives shared.

## Step 4: UI foundation

- Initialize shadcn/ui with its CLI (check the current command in the shadcn docs or MCP); confirm `components.json` paths match the structure.
- Define tokens (colors, radius, fonts) as CSS variables through the shadcn theme.
- Dark mode following the shadcn/ui documentation for Next.js.
- Fonts with `next/font`, declared once in the root layout and exposed as CSS variables.
- Toasts with the shadcn-recommended solution (commonly `sonner`), mounted once in the root layout.

## Step 5: app shell and resilience

- `app/layout.tsx`: `<html lang>`, fonts, providers (as deep as possible), `metadata` with `metadataBase` and a title template.
- `app/error.tsx`, `app/global-error.tsx`, `app/not-found.tsx`, and a root `loading.tsx` only if it makes sense for the UX.
- Keep the root layout free of request-time APIs (`anti-patterns.md` #1).

## Step 6: security baseline

- `import 'server-only'` in data access and secret-handling modules (add the `server-only` package).
- Env validation in `src/lib/env.ts` **(proposed: Zod)**: parse `process.env` once, fail fast with a clear message, export typed values. Keep server-only and `NEXT_PUBLIC_` variables in separate schemas.
- Security headers via `headers()` in `next.config.ts`: `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` as needed, and `frame-ancestors` in a CSP (or `X-Frame-Options`).
- **CSP:** a nonce-based CSP requires **dynamic rendering** of every page it applies to (per the Next.js CSP guide). Decide consciously: nonce CSP for apps that are dynamic anyway; a static-compatible policy for content sites. Record the decision in `architecture.md`.
- Server Actions follow `examples/server-action.md` (validation + authorization inside).

## Step 7: testing

- Vitest + Testing Library following the Next.js Vitest guide (bundled docs `02-guides/testing/vitest.md`): jsdom environment, React plugin, path alias support.
- Playwright following the Next.js Playwright guide: `webServer` pointing to `pnpm build && pnpm start` so E2E runs against production behavior.
- One example test of each kind to establish the pattern.

## Step 8: CI

GitHub Actions (or the team's CI) running on pull requests:

```yaml
name: ci
on: [pull_request]
jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck
      - run: pnpm lint
      - run: pnpm format:check
      - run: pnpm test
      - run: pnpm build
```

Verify action versions when writing the workflow. Add `.nvmrc` with the Node.js version supported by the installed Next.js. Playwright can run in a separate job (it needs browsers installed).

## Step 9: agent support and documentation

- `AGENTS.md`: keep the Next.js managed block; add project-specific guidance outside it.
- `.mcp.json` with `next-devtools-mcp` **(proposed)**, see `versions.md`.
- `architecture.md` from the Frontend Agent template (`~/.cursor/skills/frontend-agent/architecture/architecture.md`), filled with the decisions above.
- `README.md` with setup, scripts and conventions.

## Step 10: verify

Run `pnpm typecheck`, `pnpm lint`, `pnpm test` and `pnpm build`, then follow `verification.md`. Report what was created, the decisions taken and anything left for the user.
