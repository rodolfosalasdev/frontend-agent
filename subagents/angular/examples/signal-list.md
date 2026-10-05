# Example: Filterable list with signals

Validated with Angular 21.2.25 (CLI 21.2.25, zoneless, no `zone.js`): production `ng build` succeeded.

The control-flow template needs Angular 17+ (`@for` is stable in 18). The class uses `signal` and `computed`, which exist as a preview from v16 and are stable long before v20. Confirm both against the installed docs before copying. This is a snapshot of the [signals](https://angular.dev/guide/signals) and [control flow](https://angular.dev/guide/templates/control-flow) guides, not a guarantee for every minor.

## When to use

A component that already holds its list in memory and filters it locally. For a server-backed list, keep the query in the URL (`routing.md`) and filter on the server.

## Component

```ts
import {ChangeDetectionStrategy, Component, computed, signal} from '@angular/core';

export type Client = { id: string; name: string };

@Component({
  selector: 'app-client-list',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './client-list.html',
})
export class ClientList {
  protected readonly query = signal('');
  private readonly clients = signal<Client[]>([
    { id: 'c1', name: 'Ada Lovelace' },
    { id: 'c2', name: 'Grace Hopper' },
  ]);

  protected readonly visible = computed(() => {
    const term = this.query().trim().toLowerCase();
    const all = this.clients();
    if (!term) return all;
    return all.filter((client) => client.name.toLowerCase().includes(term));
  });

  protected onQuery(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.query.set(value);
  }
}
```

`OnPush` is explicit so the example is valid on versions that do not default to it. If the installed enum uses `Eager` instead of `Default`, leave this `OnPush` line as it is.

## Template

```html
<label for="client-query">Search</label>
<input id="client-query" type="search" [value]="query()" (input)="onQuery($event)" />

<p aria-live="polite">
  {{ visible().length }}
  {{ visible().length === 1 ? 'client' : 'clients' }}
</p>

<ul>
  @for (client of visible(); track client.id) {
    <li>{{ client.name }}</li>
  } @empty {
    <li>No clients match this search.</li>
  }
</ul>
```

On v17.2+ a signal can be bound two ways. The `(input)` handler above also works on v16, with `*ngFor` and `trackBy` instead of `@for` if control flow is not available.

## Why

- `computed` derives the visible rows. An `effect` that writes a second signal would be the anti-pattern.
- `track client.id` keeps row DOM stable.
- The input is a signal the template reads, so zoneless and OnPush refresh without Zone.js.
- `@empty` is the empty state. Loading and error are absent because this list is local. A remote list needs those two as well.

## Adapt

- Put `q` in the query string when the view must be shareable (`routing.md`).
- Debounce only if the filter hits the network.
- Use the project's form control instead of a raw `<input>` when one exists.
