# Princípios: JavaScript

Ao explicar ou diagnosticar problemas de JavaScript, considere o comportamento real do runtime e do browser, não uma simplificação.

## Event loop e assincronia

- Microtasks (Promises, `queueMicrotask`, `MutationObserver`) rodam **todas** antes da próxima macrotask e antes da renderização. Um loop de microtasks pode travar a página tanto quanto um loop síncrono.
- Macrotasks (`setTimeout`, eventos, mensagens) intercalam com renderização. Use-as para ceder o main thread em trabalhos longos.
- `requestAnimationFrame` para trabalho visual sincronizado com o próximo frame.
- `requestIdleCallback` para trabalho de baixa prioridade (confirme o suporte nos navegadores-alvo).
- Ao diagnosticar "ordem estranha de execução", raciocine explicitamente sobre call stack, fila de microtasks e fila de macrotasks.

## Promises e async/await

- Toda Promise deve ter o erro tratado em algum ponto. Rejeições não tratadas geram `unhandledrejection`.
- Operações independentes devem rodar em paralelo (`Promise.all`, `Promise.allSettled`), não em sequência com vários `await`.
- Escolha o combinador pelo comportamento desejado: `all` (falha no primeiro erro), `allSettled` (quer todos os resultados), `race` (o primeiro a terminar), `any` (o primeiro sucesso).
- `await` dentro de loop é sequencial por definição. Só use quando a sequência for intencional.
- Não misture `.then()` e `async/await` no mesmo fluxo sem motivo.

## Cancelamento e race conditions

- Toda operação assíncrona disparada por interação ou navegação deve considerar cancelamento com `AbortController`: busca com digitação, troca de rota, componente removido.
- Race condition clássica: duas requisições em sequência, a primeira responde por último e sobrescreve o resultado correto. Resolva com cancelamento ou descartando respostas obsoletas.
- Passe o `signal` adiante: `fetch`, `addEventListener` e APIs próprias podem aceitar o mesmo `AbortSignal`.
- `AbortSignal.timeout()` e `AbortSignal.any()` simplificam timeouts e combinação de sinais (confirme o suporte nos navegadores-alvo).

## Módulos

- Prefira ESM (`import`/`export`). CommonJS apenas quando o ambiente exige.
- Imports nomeados facilitam tree shaking. Evite módulos com side effects no topo.
- `import()` dinâmico para carregar código sob demanda.
- Evite dependências circulares; elas geram valores `undefined` em tempo de inicialização difíceis de rastrear.

## Escopo, closures e `this`

- `const` por padrão, `let` quando há reatribuição, nunca `var` em código novo.
- Closures retêm referências: um handler que captura um objeto grande o mantém vivo enquanto o handler existir.
- Arrow functions não têm `this` próprio. Métodos passados como callback perdem o `this` se não forem arrow functions ou `bind`.
- Classes são adequadas quando há estado encapsulado e comportamento associado (ex.: Custom Elements). Funções e módulos resolvem a maioria dos outros casos.

## Memória e garbage collection

Em aplicações de longa duração (SPAs), vazamentos se acumulam. Causas comuns:

- event listeners não removidos (use `AbortController` com `{ signal }` para remover vários de uma vez);
- `setInterval`/`setTimeout` não limpos;
- observers (`IntersectionObserver`, `ResizeObserver`, `MutationObserver`) não desconectados;
- caches em `Map` que só crescem;
- referências a nós do DOM já removidos.

Use `WeakMap`/`WeakSet` para associar dados a objetos sem impedir sua coleta. `WeakRef` e `FinalizationRegistry` raramente são a resposta certa; o comportamento do GC não é determinístico.

Para diagnosticar, use heap snapshots no DevTools comparando antes e depois de repetir a ação suspeita.

## Iteradores e geradores

- Úteis para sequências preguiçosas, paginação (`async function*` com `for await`) e processamento em streaming.
- Não use geradores onde um array simples resolve com clareza.

## Recursos nativos antes de bibliotecas

Antes de adicionar dependência, verifique se o runtime já resolve: `structuredClone`, `Intl` (datas, números, plurais, listas, tempo relativo), `URL`/`URLSearchParams`, `Array.prototype.at`, `Object.groupBy`, `crypto.randomUUID`. Confirme sempre o suporte contra o `browserslist` do projeto.

## Tratamento de erros

- Use `Error` (ou subclasses) em `throw`, nunca strings; preserve a causa com `new Error(msg, { cause })`.
- Não engula erros com `catch` vazio. Trate, transforme em estado de UI ou relance com contexto.
- Em `catch`, o valor é `unknown` na prática: faça narrowing antes de acessar propriedades.
