# Next.js Specialist (`nextjs-specialist`)

Subagente especialista em React e Next.js do [Frontend Agent](../../README.md). Ele recebe do agente principal as tarefas que dependem do comportamento do framework, implementa, verifica e devolve um relatório. O Frontend Agent valida o resultado antes de responder ao usuário.

Este README é documentação para humanos. O prompt do subagente é o [`agent.md`](agent.md).

## Papel

- **Implementador:** pode editar arquivos e rodar typecheck, lint, testes, build e verificação no navegador.
- **Sem versão fixa:** sempre detecta a versão instalada (`package.json` + lockfile) e usa APIs compatíveis com ela.
- **Documentação da versão instalada primeiro:** a partir do Next.js 16.2, a documentação vem junto do pacote em `node_modules/next/dist/docs/`. O subagente consulta esses arquivos antes de escrever código sensível à versão.
- **Respeita o projeto:** o `architecture.md` do projeto vence os padrões gerais; convenções existentes vencem preferências.

## Quando o Frontend Agent delega

Quando o projeto tem `next` nas dependências **e** a questão depende do framework:

- Server e Client Components, `"use client"`, estratégia de renderização, streaming e Suspense;
- data fetching, cache e revalidação, Cache Components, Server Actions, Route Handlers, proxy/middleware;
- rotas, metadata e SEO, `next/image`, `next/font`, hidratação, performance de React;
- tabelas e listas com filtros, busca, ordenação e paginação;
- TanStack Query, Tailwind CSS e shadcn/ui dentro do projeto;
- criação de projeto Next.js do zero.

Questões independentes de framework (CSS puro, lógica TypeScript, HTTP, acessibilidade de HTML, segurança geral) ficam com o Frontend Agent.

## Contratos

**Entrada** (enviada pelo Frontend Agent, autossuficiente porque o subagente não vê a conversa):

```text
Framework / version:
Router:
Relevant architecture rules:
Problem:
Goal:
Constraints:
Files involved:
Workspace:
```

O que faltar e puder ser descoberto no repositório, o subagente descobre sozinho.

**Saída** (relatório final):

```text
Context detected:
Diagnosis:
Solution:
Files changed:
Verification:
Impacts and trade-offs:
Open questions / uncertainties:
```

Se não conseguir fazer a verificação no navegador, o relatório diz `visual verification not run`, e o Frontend Agent faz essa verificação como fallback.

## Regras padrão

| Tema | Regra |
|---|---|
| Server vs Client | Server Components por padrão; `"use client"` só nas ilhas interativas, o mais fundo possível na árvore. |
| Dados | Buscar no servidor, em paralelo; sem `fetch` em `useEffect` para dados iniciais; sem Route Handler para consumo interno de Server Components. |
| Server Actions | São endpoints públicos: validar, autenticar e autorizar dentro da action; retornar resultados tipados. |
| Cache | Para cada dado: o quê, onde, chave, tempo de vida e invalidação. `updateTag` em Server Actions, `revalidateTag(tag, 'max')` fora delas. |
| Tabelas | Estado em **search params** da URL (`?status=paid&q=ana&sort=-total&page=2`), para compartilhar o link já filtrado. Validação no servidor, defaults omitidos, `<Link>` para ordenação e paginação. |
| TanStack Query | **Por critério**, não por padrão: quando há estado de servidor no cliente que justifica (polling granular, mutations otimistas, muitos widgets). Pede confirmação antes de instalar. |
| UX | A view de dados ou o formulário que a tarefa cria ou altera cobre os quatro estados (loading, vazio, erro, sucesso) e, no formulário, pending, erros por campo e valores preservados. Não acrescentar isso numa tela que a tarefa não mexe. |
| Qualidade visual | Escala de espaçamento e tipografia, hierarquia clara, uma cor de destaque, estados de hover/foco/ativo, `prefers-reduced-motion`, auto-revisão por screenshot. |
| Performance | Orçamentos: LCP, INP e CLS dentro dos limites "good" do web.dev (valores conferidos na fonte, não fixados no prompt); sem regressão de JS; sem waterfalls; modo da rota (estático/dinâmico) não muda sem motivo. |
| Dependências | Nenhuma biblioteca nova sem justificativa e confirmação. |
| Projeto novo | Apresenta o plano e pede confirmação antes. Base: pnpm, TypeScript strict, App Router, Tailwind + shadcn/ui, ESLint + Prettier, Vitest + Testing Library, Playwright, CI. |

## Definition of done

Uma tarefa só é reportada como concluída quando:

- a view de dados que a tarefa cria ou altera tem os quatro estados;
- o formulário que a tarefa cria ou altera tem pending, erros acessíveis e valores preservados;
- o básico de acessibilidade está coberto (labels, foco visível, teclado, contraste);
- o layout funciona no mobile e no desktop;
- o [`anti-patterns.md`](anti-patterns.md) foi conferido;
- a verificação do [`verification.md`](verification.md) foi executada, ou o relatório diz o que não foi executado e por quê.

## Arquivos de referência

O subagente carrega só o que a tarefa precisa, a partir do índice na seção 6 do `agent.md`.

| Arquivo | Conteúdo |
|---|---|
| [`agent.md`](agent.md) | Prompt: identidade, fluxo, índice, contratos, Definition of done |
| [`versions.md`](versions.md) | Detecção de versão e router, flags experimentais, APIs depreciadas, fontes de documentação, `next-devtools-mcp` |
| [`rendering.md`](rendering.md) | Server vs Client Components, estratégias de renderização, streaming, hidratação |
| [`data-fetching.md`](data-fetching.md) | Data fetching, Server Actions, Route Handlers, segurança, TanStack Query, polling |
| [`tables.md`](tables.md) | Tabelas e listas com estado na URL |
| [`caching.md`](caching.md) | Camadas de cache, revalidação, Cache Components vs modelo anterior |
| [`routing.md`](routing.md) | App Router vs Pages Router, convenções de arquivos, proxy, metadata e SEO |
| [`performance.md`](performance.md) | Orçamentos, Core Web Vitals, bundle, imagens, fontes, responsividade de interação |
| [`react.md`](react.md) | Arquitetura de componentes, effects, memoização, React Compiler, estado |
| [`ui.md`](ui.md) | Tailwind, shadcn/ui, estados de UX, qualidade visual, acessibilidade em React |
| [`testing.md`](testing.md) | Testes, code review, refactoring |
| [`anti-patterns.md`](anti-patterns.md) | 22 erros comuns de Next.js, cada um com o que procurar, por que é problema e como corrigir |
| [`verification.md`](verification.md) | Checks estáticos, build e modo das rotas, verificação no navegador |
| [`bootstrap.md`](bootstrap.md) | Criação de projeto do zero |
| [`examples/`](examples/) | Implementações de referência validadas |
| [`detect`](detect) | Pacotes que identificam um projeto Next.js (usado pelo instalador para sugerir este subagente) |

Princípios gerais (TypeScript, HTTP, segurança, acessibilidade etc.) não são duplicados aqui: o subagente lê os `principles/` do Frontend Agent.

## Exemplos

Cada exemplo diz com qual versão foi validado. Todos passaram por typecheck, lint e build no Next.js 16.3.4, e os marcados com navegador também foram testados no browser.

| Exemplo | O que mostra |
|---|---|
| [`server-page-client-island.md`](examples/server-page-client-island.md) | Página server com ilha client, `loading.tsx` e `error.tsx` com `retry` |
| [`server-action.md`](examples/server-action.md) | Server Action segura: validação com Zod, autenticação, autorização, invalidação |
| [`form-with-pending-and-errors.md`](examples/form-with-pending-and-errors.md) | Formulário com `useActionState`, pending, erros por campo e valores preservados (navegador) |
| [`table-url-state.md`](examples/table-url-state.md) | Tabela com filtros, busca, ordenação e paginação na URL, região `aria-live` persistente (navegador) |
| [`polling-refresh.md`](examples/polling-refresh.md) | Atualização periódica com `router.refresh()` ou TanStack Query, com a comparação entre os dois |

## Documentação local e MCP

- **Next.js 16.2+:** documentação da versão instalada em `node_modules/next/dist/docs/`. O `AGENTS.md` gerado pelo `create-next-app` aponta para ela.
- **Versões anteriores:** documentação online da versão (ex.: `/docs/15/`) ou o codemod `agents-md` (≤ 16.1).
- **`next-devtools-mcp`:** diagnóstico em tempo de execução (erros, rotas, logs) com o `next dev` rodando. Configuração em [`versions.md`](versions.md).

## Instalação

Pelo instalador do repositório:

```bash
<clone>/scripts/install.sh --add nextjs        # em uma instalação existente
<clone>/scripts/install.sh --project --subagents nextjs
```

Em projetos com `next` no `package.json`, o instalador já sugere este subagente. Detalhes no [README principal](../../README.md#instalação).

Também é possível chamar o subagente diretamente ("Use the nextjs-specialist subagent to ..."), mas nesse caso a validação pelo Frontend Agent não acontece.

## Cenários de avaliação

Os cenários ficam em [`evals/scenarios.md`](../../evals/scenarios.md). Os deste subagente são:

| # | Cenário |
|---|---|
| 6 | Pergunta de framework (delegação) |
| 9 | `"use client"` desnecessário |
| 10 | Waterfall em Server Component |
| 11 | Server Action sem autorização |
| 12 | Pergunta de cache precisa |
| 13 | Tabela com estado na URL |
| 14 | Polling (`router.refresh()` vs TanStack Query) |
| 15 | Projeto novo (bootstrap) |
| 16 | Review com `cookies()` no layout raiz |
| 17 | Tela nova com estados e verificação visual |

Depois de alterar um arquivo de referência, rode os cenários afetados.
