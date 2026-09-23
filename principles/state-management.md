# Princípios: State Management

Não trate todo estado como global. Escolha a estratégia **mais simples** que resolve o problema.

## Classifique o estado antes de escolher a solução

| Tipo | Exemplo | Onde deve viver |
|---|---|---|
| **Local UI State** | dropdown aberto, hover, valor digitado ainda não enviado | No próprio elemento/componente |
| **Component State** | aba selecionada dentro de um widget | No componente dono |
| **Shared UI State** | item selecionado usado por lista e painel de detalhes | No ancestral comum mais próximo |
| **Server State** | dados vindos da API | Cache de dados do servidor, não em store de UI |
| **URL State** | filtros, página, busca, aba principal | Na URL (`URLSearchParams`) |
| **Global Application State** | usuário autenticado, tema, feature flags | Módulo/store global pequeno |
| **Persistent State** | preferências que sobrevivem ao reload | Storage apropriado (ver `web-platform.md`) |

## Regras

- **Coloque o estado o mais perto possível de quem usa.** Suba de nível apenas quando dois consumidores precisarem dele.
- **Estado derivado não é estado:** calcule a partir da fonte (total a partir dos itens, lista filtrada a partir de lista + filtro). Guardar derivações cria inconsistência.
- **Uma única fonte de verdade** para cada dado. Cópias sincronizadas manualmente divergem.
- **Server state é cache**, com problemas próprios: expiração, revalidação, deduplicação de requisições, invalidação após mutações. Não o trate como estado de UI comum.
- **URL é estado.** O que o usuário esperaria preservar ao compartilhar o link, recarregar ou voltar deve estar na URL.
- **Modele estados explícitos** (ver discriminated unions em `typescript.md`) em vez de combinações de booleanos.

## Sem framework

Na maioria das aplicações sem framework, estes recursos bastam:

- variáveis no escopo do módulo, expostas por funções (`getState`, `setState`) em vez de mutação direta;
- notificação de mudanças com `EventTarget` e `CustomEvent`, ou um observer mínimo;
- estado no DOM quando ele já é a fonte de verdade (atributos, `aria-*`, valores de formulário);
- URL para estado navegável.

Exemplo de store mínimo tipado:

```ts
type Listener<T> = (state: T) => void;

export function createStore<T>(initial: T) {
  let state = initial;
  const listeners = new Set<Listener<T>>();

  return {
    get: (): T => state,
    set(update: (prev: T) => T): void {
      const next = update(state);
      if (Object.is(next, state)) return;
      state = next;
      listeners.forEach((listener) => listener(state));
    },
    subscribe(listener: Listener<T>): () => void {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
  };
}
```

Considere uma biblioteca de estado apenas quando houver necessidade concreta (muitos consumidores, devtools, persistência, middleware) e depois de verificar o que o projeto já usa.

## Sinais de problema

- Store global contendo estado de um único componente.
- Mesmo dado armazenado em dois lugares.
- Efeitos encadeados para manter estados sincronizados.
- Resposta da API guardada tal como veio e usada diretamente como estado da tela.
- Filtros e paginação perdidos ao recarregar a página.
