# React: Components, Effects, Memoization and State

General TypeScript and state principles live in the Frontend Agent's `principles/typescript.md` and `principles/state-management.md`. This file covers React-specific rules.

## Component architecture

Prefer:

- composition (children, slots via props) over configuration-heavy components;
- small, focused components with explicit, typed props;
- state as local as possible, lifted only when shared;
- predictable, one-directional data flow.

Avoid:

- monolithic components mixing data fetching, business rules and presentation;
- premature generic components with dozens of props for hypothetical cases;
- global state for local concerns;
- unnecessary wrappers and client boundaries;
- deep prop drilling without evaluating composition first (often better than Context).

Separate, when complexity justifies it and following the project architecture:

```text
Presentation → UI behavior (hooks) → Application logic → Domain logic → Infrastructure / API
```

Custom hooks extract reusable **behavior**; they are not a place to hide business rules that should be plain, testable functions.

## Effects

Follow the React docs guidance "You Might Not Need an Effect". Effects are for **synchronizing with external systems** (subscriptions, browser APIs, non-React widgets, network connections), not for data flow.

Do not use effects to:

- compute derived data → compute it during render;
- respond to user events → do it in the event handler;
- reset state when a prop changes → use a `key` or derive it;
- chain state updates → compute the final state in one place;
- fetch data that could be fetched on the server (App Router) or with the project's data-fetching solution.

When an effect is justified: always clean up (subscriptions, timers, listeners, `AbortController` for fetches) and handle race conditions.

## Memoization and React Compiler

First, check whether the **React Compiler** is enabled (`reactCompiler` in `next.config` or the corresponding Babel/SWC setup). With it enabled, the compiler memoizes automatically and manual `useMemo` / `useCallback` / `memo` are usually unnecessary; follow its guidance on when manual memoization still makes sense.

Without the compiler, do not add `useMemo`, `useCallback` or `React.memo` automatically. Before recommending them, evaluate:

1. Is there a measurable performance problem (React DevTools Profiler, INP)?
2. Is the computation or render cost significant?
3. Are the dependencies stable (otherwise memoization never hits)?
4. Does it add complexity or bugs (stale closures)?
5. Would a better state placement or component split solve it structurally?

Prefer structural fixes: move state down, split components, pass children to avoid re-rendering static subtrees, split contexts by update frequency.

## Re-render causes to check

- State stored higher than needed.
- Context value recreated on every render or one context holding unrelated values.
- New object/array/function props on every render passed to memoized children.
- Derived data stored in state and synchronized with effects.
- Large lists without keys or with unstable keys (index keys for reorderable lists cause bugs, not only slowness).

## Concurrent features

- `useTransition` / `startTransition` for non-urgent updates (filtering large lists, tab switches) to keep input responsive.
- `useDeferredValue` to defer rendering of expensive derived UI.
- Suspense for data and code loading boundaries.
- Check availability of newer APIs (`use`, `useActionState`, `useOptimistic`, `useFormStatus`, ref as a prop) for the installed React version before using them.

## State in React / Next.js

Classify first (see the parent `state-management.md`), then:

| State | React / Next.js approach |
|---|---|
| Local / component | `useState`, `useReducer` |
| Shared UI | Lift to the nearest common ancestor; composition; small Context if needed |
| URL state | Search params and dynamic segments (source of truth for filters, pagination, tabs; see `tables.md`) |
| Server state | Server Components in the App Router. On the client, the project's server-state library if it has one; otherwise TanStack Query is the preferred choice when a client-side need exists (criteria in `data-fetching.md`) |
| Form state | Native forms with Server Actions and React form hooks, or the project's form library |
| Global client state | Only when truly global (auth user on the client, theme); evaluate the existing solution before adding a store |
| Persistent | Cookies (if the server needs it) or browser storage, read without breaking hydration |

Do not introduce a new state management library without evaluating the existing solution and getting confirmation.

## TypeScript in React

- Explicit props types; avoid `React.FC` unless the project uses it.
- Use the React and Next.js types that match the installed versions (`@types/react` must match the React major).
- Type page and layout props according to the installed version's conventions (e.g. `params` / `searchParams` may be Promises).
- Discriminated unions for component variants and async states.
- Separate API contracts (DTOs) from component props.
