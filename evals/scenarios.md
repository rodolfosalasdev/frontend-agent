# Cenários de avaliação

Teste manual do Frontend Agent. Rode cada cenário em um projeto de teste com `/frontend-agent <prompt>` e compare com o comportamento esperado.

Depois de alterar `agent.md` ou algum arquivo de `principles/`, rode novamente os cenários afetados.

---

## 1. Componente vanilla acessível

**Prompt:**
> Crie um componente de tabs em TypeScript sem framework.

**Esperado:**
- Verifica se existe `architecture.md`, `package.json`, `tsconfig` e `browserslist` antes de escrever.
- Lê `principles/accessibility.md` e, possivelmente, `principles/web-platform.md`.
- Segue o padrão WAI-ARIA de tabs: `role="tablist"`, `tab`, `tabpanel`, `aria-selected`, `aria-controls`, navegação por setas, Home/End.
- Não introduz dependências.
- Não sugere shadcn/ui (é React).

## 2. Review com XSS

**Prompt:**
> Revise este código:
> ```ts
> const params = new URLSearchParams(location.search);
> document.querySelector('#greeting')!.innerHTML = `Olá, ${params.get('name')}`;
> localStorage.setItem('token', response.accessToken);
> ```

**Esperado:**
- Lê `principles/testing.md` (roteiro de review) e `principles/security.md`.
- Aponta como **crítico**: XSS por `innerHTML` com dado da URL; token em `localStorage`.
- Propõe `textContent` e discute alternativas de armazenamento de sessão (cookie `HttpOnly`).
- Menciona a non-null assertion como ponto menor.
- Resultado organizado por severidade.

## 3. LCP ruim

**Prompt:**
> A home está com LCP de 4.5s no mobile. O que fazer?

**Esperado:**
- Lê `principles/performance.md`.
- Não sai recomendando otimizações genéricas: pergunta ou investiga qual é o elemento LCP, se há dado de campo, TTFB e como o recurso é descoberto.
- Separa hipóteses de fatos.
- Não afirma limiares de métrica sem indicar a fonte.

## 4. Projeto com `architecture.md` restritivo

**Preparação:** crie um `architecture.md` no projeto de teste com a regra "componentes de UI não podem chamar `fetch` diretamente; toda chamada passa por `src/api/`".

**Prompt:**
> Adicione uma lista de produtos que busca de /api/products.

**Esperado:**
- Lê o `architecture.md` do projeto e respeita a regra, criando ou reutilizando um client em `src/api/`.
- Separa DTO de modelo usado na UI quando fizer sentido.
- Trata loading, vazio, erro e cancelamento.

## 5. Pedido simples

**Prompt:**
> Como centralizo uma div horizontal e verticalmente?

**Esperado:**
- Resposta curta e direta (Grid ou Flexbox), sem arquitetura, sem checklist, sem varrer o projeto.

## 6. Pergunta de framework (delegação)

**Preparação:** projeto Next.js de teste.

**Prompt:**
> Como faço cache de dados em uma rota do Next.js?

**Esperado:**
- O Frontend Agent identifica `next` nas dependências, a versão instalada e o router.
- Delega ao `nextjs-specialist` com o bloco de contexto completo (versão, router, problema, objetivo, restrições, workspace).
- O especialista informa se o projeto usa Cache Components ou o modelo anterior e responde "o quê, onde, chave, tempo de vida, invalidação".
- O Frontend Agent responde em PT-BR, sem colar o relatório bruto.

Variação sem projeto: o agente pergunta a versão ou responde sinalizando que o comportamento depende dela.

**Variação Angular. Preparação:** projeto com `@angular/core` nas dependências.

**Prompt:**
> Como faço a detecção de mudanças sem Zone.js?

**Esperado:**
- Identifica `@angular/core`, a versão instalada e se a app é zoneless ou usa Zone.js (`angular.json` polyfills, `provideZonelessChangeDetection` / `provideZoneChangeDetection`).
- Delega ao `angular-specialist` com o bloco de contexto (versão, change detection, problema, objetivo, restrições, workspace).
- O especialista responde conforme a versão: v21+ já é o padrão; v20.2+ estável com confirmação num app existente; antes disso, não liga em produção.
- O Frontend Agent responde em PT-BR, sem colar o relatório bruto.

## 7. Refactoring

**Prompt:**
> Refatore este módulo de 400 linhas que faz fetch, valida formulário e renderiza a tabela.

**Esperado:**
- Lê `principles/architecture.md`.
- Propõe separação incremental (API client, validação, renderização), preservando comportamento.
- Sugere garantir testes antes de refatorar.
- Não cria camadas ou patterns além do necessário.

## 8. Dependência nova

**Prompt:**
> Preciso formatar datas relativas ("há 3 dias"). Instala uma lib pra isso?

**Esperado:**
- Sugere `Intl.RelativeTimeFormat` antes de uma biblioteca, conferindo o suporte com o `browserslist`.
- Não instala nada sem confirmação.

---

# Cenários Next.js

Rode em um projeto Next.js de teste (App Router). Em todos, o esperado comum é: o Frontend Agent delega ao `nextjs-specialist`, o especialista detecta as versões antes de agir, devolve o relatório no formato do contrato e o Frontend Agent valida o diff antes de responder.

## 9. `"use client"` desnecessário

**Preparação:** uma página `app/products/page.tsx` com `"use client"` no topo, que busca dados com `useEffect` + `fetch` e tem um único botão "Adicionar ao carrinho" interativo.

**Prompt:**
> Revise e melhore a página de produtos.

**Esperado:**
- Aponta que a página inteira virou Client Component só por causa do botão.
- Move a busca de dados para o servidor e isola o botão em um Client Component pequeno.
- Trata loading (Suspense ou `loading.tsx`), vazio e erro.
- Roda typecheck/lint (e build, se relevante) e informa o resultado real.

## 10. Waterfall em Server Component

**Preparação:** um Server Component com três `await` sequenciais para dados independentes (usuário, pedidos, recomendações).

**Prompt:**
> A página de dashboard está lenta. Por quê?

**Esperado:**
- Identifica o waterfall como hipótese principal e separa fato de hipótese.
- Propõe requisições em paralelo e/ou Suspense para a seção lenta.
- Recomenda medir em build de produção, não em `next dev`.

## 11. Server Action sem autorização

**Preparação:** uma Server Action `deleteProject(id)` que apaga no banco sem checar sessão nem permissão; o botão só aparece para admins.

**Prompt:**
> Revise essa action de deletar projeto.

**Esperado:**
- Classifica como **crítico**: Server Action é um endpoint público; esconder o botão não é autorização.
- Adiciona validação do `id` e checagem de sessão e permissão dentro da action.
- Não retorna detalhes internos de erro.
- Invalida o cache dos dados afetados após a mutação, com a API correta para a versão.

## 12. Pergunta de cache precisa

**Prompt:**
> Por que minha página continua mostrando dados antigos depois que eu atualizo o banco?

**Esperado:**
- Não responde "o Next.js cacheia isso".
- Identifica qual camada pode estar servindo o dado (servidor, cache de rotas no cliente, CDN, browser) e para cada uma: o quê, onde, chave, tempo de vida e invalidação.
- Verifica se o projeto usa Cache Components ou o modelo anterior.
- Recomenda reproduzir com `next build` + `next start`.

## 13. Tabela com estado na URL

**Prompt:**
> Crie a página de pedidos com uma tabela filtrável por status, busca por cliente, ordenação por data e total, e paginação. Quero poder mandar o link já filtrado para um colega.

**Esperado:**
- Lê `tables.md`.
- Estado em **search params** (não path params): `?status=paid&q=ana&sort=-total&page=2`.
- A `page` lê e valida os params no servidor (allowlist de ordenação, enum de status, página limitada, defaults) e busca os dados já filtrados.
- Controles de filtro e busca em Client Components pequenos, com `router.replace`, debounce na busca e volta para a página 1 quando o filtro muda.
- Paginação e cabeçalhos de ordenação com `<Link>`; `aria-sort` nos cabeçalhos; contagem de resultados anunciada.
- Valores padrão omitidos da URL.
- Nenhuma biblioteca nova instalada.

## 14. Polling com TanStack Query

**Preparação:** projeto sem TanStack Query instalado.

**Prompt:**
> O dashboard de pedidos precisa atualizar sozinho a cada 30 segundos.

**Esperado:**
- Compara as duas opções da seção "Simple periodic refresh" do `data-fetching.md`: `router.refresh()` em intervalo (sem dependência) vs TanStack Query.
- Para um dashboard simples com uma fonte de dados, recomendar `router.refresh()` é aceitável, desde que cite o Query como alternativa e o trade-off (payload da rota inteira vs só os dados).
- Se recomendar o Query: **pede confirmação** antes de instalar; propõe prefetch no servidor com `dehydrate` + `HydrationBoundary`, `QueryClient` novo por requisição no servidor e único no navegador; define `staleTime` e `refetchInterval`; confere a versão (v4 vs v5).
- Em qualquer opção: pausa o polling com a aba oculta e trata erro sem quebrar a tela.

**Variação que exige o Query:**
> O dashboard tem 4 widgets com intervalos diferentes (5s, 30s, 1min, 5min) e ações de marcar pedido como enviado com atualização otimista.

**Esperado:** recomenda TanStack Query (granularidade por widget e mutations otimistas), pedindo confirmação para instalar.

**Variação:**
> Mostre a página "Sobre nós" com dados da empresa vindos da API.

**Esperado:** **não** propõe TanStack Query; usa Server Component com o cache do Next.js.

## 15. Projeto novo (bootstrap)

**Preparação:** pasta vazia.

**Prompt:**
> Crie um projeto Next.js novo para um painel administrativo.

**Esperado:**
- Lê `bootstrap.md` e **apresenta o plano de criação antes de executar** qualquer comando, pedindo confirmação.
- Usa **pnpm** e o `create-next-app` da versão estável atual (confere as flags na documentação).
- Base proposta: TypeScript `strict`, App Router, Tailwind + shadcn/ui, ESLint + Prettier, Vitest + Testing Library, Playwright, estrutura por feature, `server-only`, `error`/`global-error`/`not-found`, `metadataBase`, cabeçalhos de segurança.
- Marca como **propostos** (precisam de confirmação): validação de env com Zod e `.mcp.json` com `next-devtools-mcp`.
- Explica a decisão de CSP (nonce exige renderização dinâmica).
- CI com `pnpm install --frozen-lockfile`, typecheck (`next typegen && tsc --noEmit`), lint, format check, testes e build.
- Cria `architecture.md` a partir do template e mantém o `AGENTS.md` gerado.

## 16. Review com `cookies()` no layout raiz

**Preparação:** `app/layout.tsx` chama `await cookies()` para ler o tema e passar para o `<html>`; as outras páginas são estáticas.

**Prompt:**
> Revise o layout raiz. O site ficou mais lento depois da última mudança.

**Esperado:**
- Consulta `anti-patterns.md` e identifica que uma API de request-time no layout raiz torna **todas as rotas dinâmicas**.
- Confirma com `pnpm build` e compara os símbolos de modo de rota (estático vs dinâmico) na saída.
- Propõe alternativa: ler o tema no cliente (script inline pequeno ou `class` aplicada por um componente client), mover a leitura para o segmento que precisa dela, ou isolar a parte dinâmica em um Suspense.
- Mostra o impacto esperado (rotas voltam a ser estáticas) e o trade-off (possível flash de tema, como evitar).

## 17. Tela nova com estados e verificação visual

**Prompt:**
> Crie a tela de lista de clientes com busca, carregando do nosso banco.

**Esperado:**
- Parte de `examples/` (página server + ilha client e tabela com estado na URL) e adapta ao projeto.
- Cobre os quatro estados: loading (skeleton com o formato final), vazio (com ação), erro (com retry via `error.tsx`) e sucesso.
- Segue a seção "Visual quality" do `ui.md` (hierarquia, espaçamento, estados de foco e hover, responsivo).
- Roda a verificação do `verification.md`: typecheck, lint, build, e verificação no navegador (screenshots em 375px e 1280px, console, teclado) quando houver ferramentas de browser.
- Se não tiver browser, escreve `visual verification not run` no relatório, e o Frontend Agent faz o fallback.
- O relatório segue o contrato (seção 10), com a seção "Verification" preenchida.

## 18. `@defer` abaixo da dobra

**Preparação:** projeto Angular 18+ com uma página de produto. O título e o preço estão no primeiro viewport. Um bloco de avaliações, componente standalone pesado, está abaixo da dobra.

**Prompt:**
> A página de produto está com o LCP ruim. O bloco de avaliações puxa um componente grande.

**Esperado:**
- Lê `templates.md` e `performance.md`.
- Não coloca título, preço ou a imagem de LCP dentro de `@defer`.
- O bloco de avaliações fica em `@defer` com trigger de viewport (ou equivalente justificado), placeholder com espaço reservado, e import direto do arquivo do componente, sem barrel.
- Confere na documentação da versão instalada antes de escrever o trigger.
- Pede build de produção para ver o chunk, e não conclui a divisão só com `ng serve`.

## 19. Zoneless conforme a versão

**Variação A. Preparação:** Angular 21+, sem `provideZoneChangeDetection`.

**Prompt:**
> Deixa essa aplicação zoneless para ficar mais rápida.

**Esperado:**
- Detecta que zoneless já é o padrão na v21+.
- Não adiciona `provideZonelessChangeDetection` nem remove Zone.js se ele já não está nos polyfills.
- Procura `provideZoneChangeDetection` e `zone.js` nos polyfills. Se não houver, diz que não há o que migrar.

**Variação B. Preparação:** Angular 17, com Zone.js.

**Prompt:**
> Liga o zoneless nesse projeto.

**Esperado:**
- Não aplica `provideZonelessChangeDetection`.
- Explica que zoneless estável começa na 20.2 e que nesta versão o caminho é OnPush e notificações corretas, ou atualizar o Angular.
- Não desinstala `zone.js`.

**Variação C. Preparação:** Angular 20.2+, ainda com Zone.js, app existente.

**Prompt:**
> Quero zoneless.

**Esperado:**
- Pede confirmação antes de mudar o bootstrap.
- Descreve `provideZonelessChangeDetection()`, a remoção de `zone.js` dos polyfills, e o risco de views que mutam campo sem signal ou `markForCheck`.

## 20. Estado derivado

**Preparação:** componente Angular 18+ que já usa signals. Um `effect` copia `items` filtrados para outro signal.

**Prompt:**
> Esse filtro reaplica a lista inteira a cada tecla e às vezes entra em loop.

**Esperado:**
- Lê `signals.md` e o item 2 de `anti-patterns.md`.
- Troca o `effect` por `computed`.
- Não reescreve o resto do componente para outra API.

## 21. Lista nova

**Preparação:** aplicação Angular 19+ zoneless, sem biblioteca de UI além do que já está no projeto.

**Prompt:**
> Cria a lista de clientes com busca, carregando do nosso serviço HTTP.

**Esperado:**
- Parte de `examples/signal-list.md` e adapta: a busca vai para a query string (`routing.md`), o filtro de uma lista remota não fica só no cliente se o serviço já pagina.
- A view nova tem loading, vazio, erro e sucesso. Não adiciona isso em outras rotas.
- Não instala Angular Material, Tailwind nem signal forms se a versão for menor que 21.
- Roda a verificação de `verification.md`. Sem browser, o relatório diz `visual verification not run`.
