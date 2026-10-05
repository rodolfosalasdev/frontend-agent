# Princípios: Web Platform

Prefira recursos nativos da Web Platform quando eles resolvem o problema adequadamente. Menos dependências significam menos bundle, menos superfície de ataque e menos manutenção.

## Compatibilidade

- Antes de recomendar uma API, confirme o suporte nos navegadores-alvo definidos no `browserslist` do projeto (ou no `architecture.md`).
- Use o **Baseline** (web.dev/baseline) e o MDN como referência de disponibilidade. "Baseline Widely available" é seguro para a maioria dos projetos; "Newly available" exige checar o público-alvo.
- Quando uma API não é suportada por todos os alvos: use detecção de recurso (`'IntersectionObserver' in window`, `CSS.supports(...)`) e progressive enhancement, não detecção de user agent.
- Polyfills apenas quando necessários e carregados só para quem precisa.
- Se não tiver certeza sobre o suporte, diga isso e indique onde conferir.

## DOM

- Prefira `textContent` a `innerHTML` para inserir texto. `innerHTML` com dado não confiável é XSS (ver `security.md`).
- Para criar estruturas, use `document.createElement`, `<template>` com `content.cloneNode(true)` ou `DocumentFragment` para agrupar inserções.
- **Event delegation:** um listener no ancestral comum em vez de um por item em listas grandes ou dinâmicas.
- Use `{ passive: true }` em listeners de `touchstart`/`wheel` que não chamam `preventDefault()`.
- Remova listeners com `AbortController` (`{ signal }`) para limpar vários de uma vez.
- Evite ler layout logo após escrever estilos no mesmo frame (ver `performance.md`).

## Web Components

Bons para componentes reutilizáveis independentes de framework, design systems compartilhados entre stacks e widgets embutíveis.

- **Custom Elements:** use os lifecycle callbacks (`connectedCallback`, `disconnectedCallback`, `attributeChangedCallback`) e limpe recursos no `disconnectedCallback`.
- **Shadow DOM:** encapsula estilo e estrutura. Trade-offs: estilização externa só via custom properties, `::part` e slots; formulários exigem `ElementInternals` para participar de `<form>`; acessibilidade entre shadow roots (referências por id) tem limitações.
- Nem todo componente precisa de Shadow DOM. Light DOM é mais simples quando o encapsulamento não é necessário.
- Atributos para configuração serializável; propriedades para dados complexos; eventos (`CustomEvent` com `bubbles`/`composed` conforme necessário) para comunicação de saída.
- Registre o elemento uma vez e proteja contra redefinição (`customElements.get(name)`).

## Storage

| Mecanismo | Uso adequado | Cuidados |
|---|---|---|
| Cookies | Sessão e dados que o servidor precisa ler | Enviados em toda requisição; configure `HttpOnly`, `Secure`, `SameSite` (ver `security.md`) |
| `localStorage` | Preferências pequenas não sensíveis | Síncrono (bloqueia o main thread), só strings, acessível a qualquer script da origem (XSS lê tudo) |
| `sessionStorage` | Estado temporário por aba | Mesmas limitações do `localStorage` |
| IndexedDB | Volumes maiores, dados estruturados, offline | API assíncrona e verbosa; considere um wrapper mínimo |
| Cache Storage | Respostas HTTP para offline via Service Worker | Controle de versão e limpeza de caches antigos |

- Nunca armazene tokens ou dados sensíveis em `localStorage`/`sessionStorage` sem avaliar o risco de XSS.
- Storage pode falhar (modo privado, cota excedida): trate exceções.
- Valide dados lidos do storage; eles podem estar corrompidos ou em formato antigo.

## Workers

- **Web Workers:** processamento pesado de CPU (parsing, transformação de dados, compressão) fora do main thread. Comunicação por `postMessage`; transfira `ArrayBuffer` em vez de copiar quando o volume é grande.
- **Service Workers:** cache offline, estratégias de rede, push notifications. Adicionam complexidade real de ciclo de vida (instalação, ativação, atualização, cache obsoleto). Só use quando o requisito justificar.

## Comunicação em tempo real

| Tecnologia | Quando usar |
|---|---|
| Polling | Atualizações raras, simplicidade máxima |
| Server-Sent Events | Fluxo servidor → cliente, sobre HTTP, com reconexão automática |
| WebSockets | Comunicação bidirecional e de baixa latência |

Em todos os casos, trate reconexão, backoff, estado offline e limpeza ao sair da tela.

## Navegação e URL

- `URL` e `URLSearchParams` para ler e construir URLs; nunca concatene query strings manualmente.
- History API (`pushState`, `replaceState`, evento `popstate`) para roteamento no cliente. Estado relevante (filtros, página, aba) deve estar na URL para permitir compartilhamento, voltar e recarregar.
- Confirme o suporte antes de propor APIs mais novas de navegação.

## Observers

- **IntersectionObserver:** lazy loading, infinite scroll, analytics de visibilidade. Prefira a listeners de scroll.
- **ResizeObserver:** reagir ao tamanho de um elemento. Para ajustes puramente visuais, container queries em CSS costumam bastar (ver `css-ui.md`).
- **MutationObserver:** reagir a mudanças no DOM feitas por código que você não controla. Evite como mecanismo principal de fluxo de dados.
- Sempre desconecte (`disconnect()`) quando não forem mais necessários.

## Formulários

- Use a validação nativa (`required`, `type`, `pattern`, `min`, `max`) e a Constraint Validation API (`checkValidity`, `setCustomValidity`, `validity`) antes de criar um sistema próprio.
- Use `FormData` para ler os valores de um formulário.
- Validação no cliente é UX, não segurança: o servidor sempre valida.
- Mensagens de erro acessíveis (ver `accessibility.md`).
