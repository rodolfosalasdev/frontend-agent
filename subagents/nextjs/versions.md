# Next.js: Versions and Verification

There is no fixed minimum version. Always detect the installed version and use the matching documentation.

## Detecting versions

1. Read the lockfile to get the **installed** versions of `next`, `react`, `react-dom`, `typescript`, `tailwindcss`, `@types/react`.
   - npm: `package-lock.json` → `packages["node_modules/next"].version`
   - pnpm: `pnpm-lock.yaml`
   - yarn: `yarn.lock`
   - bun: `bun.lock`
2. If there is no lockfile, use the range in `package.json` and state that the exact version is unknown.
3. When dependencies are installed, `node_modules/next/package.json` confirms the real version.
4. Node.js version: `engines` in `package.json`, `.nvmrc`, `.node-version`, CI config.

## Detecting the router

| Found | Router |
|---|---|
| `app/` or `src/app/` | App Router |
| `pages/` or `src/pages/` | Pages Router |
| Both | Hybrid (common during incremental migration). Identify which router owns the route being changed. |

Never apply App Router APIs (Server Components, `"use client"`, `generateMetadata`, Server Actions) to Pages Router files, or vice versa (`getServerSideProps` in `app/`).

## Detecting relevant configuration

In `next.config.{js,mjs,ts}`, look for:

- experimental flags (anything under `experimental`);
- `cacheComponents` (changes the caching and prerendering model; see `caching.md`);
- `reactCompiler` (changes memoization guidance; see `react.md`);
- `output` (`standalone`, `export`), `basePath`, `i18n`, `images`, `redirects`, `rewrites`, `headers`;
- custom webpack or Turbopack configuration.

Also check:

- the presence of `proxy.ts` or `middleware.ts` (see `routing.md`);
- the deployment target (Vercel, self-hosted Node, container, static export), which affects caching, image optimization and ISR behavior.

## Areas that changed across major versions

Treat these as **high risk for version mismatch**. Always confirm the behavior for the installed version before relying on it:

- default caching of `fetch`, GET Route Handlers and the client router cache;
- synchronous vs asynchronous request APIs (`cookies()`, `headers()`, `draftMode()`, `params`, `searchParams`);
- `middleware` vs `proxy` file convention and its runtime;
- Cache Components (`cacheComponents`, `"use cache"`, `cacheLife`, `cacheTag`) vs the previous caching model and older experimental flags;
- revalidation APIs and their signatures (`revalidateTag`, `revalidatePath`, and newer related functions);
- `next/image` props and defaults;
- default bundler for `dev` and `build`;
- linting integration (`next lint` availability);
- React major version features (Actions, `useActionState`, `useOptimistic`, `use`, ref as a prop).

## Verifying documentation

**Rule: verify before writing.** Version-sensitive APIs (caching, request APIs, revalidation, `next/image` props, config options, file conventions) must be checked in the documentation for the installed version before you write the code. "Unverified" is acceptable only when no documentation source is available.

### 1. Local bundled docs (Next.js 16.2 and later)

Next.js ships its full documentation, matching the installed version, inside the package:

```text
node_modules/next/dist/docs/
```

- It mirrors the structure of the docs site (`01-app/...`, `02-pages/...`). Search it instead of reading it whole:

```bash
rg -l "cacheLife" node_modules/next/dist/docs
rg -n "revalidateTag" node_modules/next/dist/docs/01-app/03-api-reference
```

- In monorepos, resolve `next` from the app's directory; it may not be visible from the repo root.
- Read the project's `AGENTS.md` if present. On 16.3 and later, `next dev` writes and maintains a managed block there pointing to the bundled docs; on 16.2 it may have been added manually. Content outside the managed block is project-specific guidance: follow it too.
- If `node_modules` is not installed, the bundled docs are unavailable. Do not install dependencies without confirmation; use the online docs (step 2) instead.

### 2. Online docs

- `https://nextjs.org/docs/...` is the latest stable. Previous majors are prefixed (`/docs/15/...`, `/docs/14/...`). Use the one matching the installed major.
- Official React docs: `https://react.dev`.

### 3. Next.js 16.1 and earlier

Docs are not bundled. Options:

- online docs for the installed major (step 2);
- the `agents-md` codemod, which downloads a version-matched copy to `.next-docs/` and indexes it in `AGENTS.md`. It **modifies the project**: propose it and get confirmation first.

### 4. Runtime diagnostics: `next-devtools-mcp` (Next.js 16+)

`next dev` exposes an MCP endpoint at `/_next/mcp`. The `next-devtools-mcp` package connects agents to it and exposes, among others:

- compilation issues and per-route compilation (check whether the code compiles without a full `next build`);
- routes, runtime errors and server logs;
- a docs gateway pointing to the bundled docs.

If the tools are available in your session, use them during implementation and verification. If they are not configured, you may suggest adding to the project's `.mcp.json` (requires confirmation):

```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

### 5. Upgrades and migrations

- Read the upgrade guides and release notes for every version between what the code targets and what is installed.
- Prefer the official codemods (`@next/codemod`) over manual mass edits, and review their output.
- Official agent skills for upgrade and Cache Components workflows may be available; use them when present in the environment.

If none of these sources can be consulted, state it in the report ("unverified for Next.js X.Y: no local or online docs available").

## Experimental and deprecated features

- **Experimental** (`experimental.*` flags, `unstable_` prefixed APIs): allowed only when the project already uses them or the user explicitly accepts the risk. Report status, risk of breaking changes and fallback.
- **Deprecated**: flag them when touching nearby code; suggest the replacement with a reference to the upgrade guide. Do not mass-migrate without being asked.
