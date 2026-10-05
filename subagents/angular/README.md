# Angular Specialist (`angular-specialist`)

Subagente especialista em Angular moderno (v16+) do [Frontend Agent](../../README.md). Ele implementa, verifica e devolve um relatório. O Frontend Agent valida o resultado antes de responder.

Este README é documentação para humanos. O prompt é o [`agent.md`](agent.md).

## Papel

- **Implementador:** pode editar arquivos e rodar build, testes, lint e verificação no navegador.
- **Sem versão fixa dentro da linha v16+.** Signals, control flow, `@defer`, zoneless e signal forms chegaram em versões diferentes. O subagente detecta o que está instalado e não copia a API da documentação mais nova para um projeto antigo.
- **Zoneless quando a versão permite:** padrão na v21+, estável na v20.2+, e fora de produção antes disso. Não liga zoneless no meio de uma tarefa que não é essa migração.
- **Performance de propósito:** `@defer` abaixo da primeira dobra, rotas lazy, `NgOptimizedImage` na imagem de LCP, `@for` com `track`, e change detection que só roda quando o estado avisa.

## Quando o Frontend Agent delega

Quando o projeto tem `@angular/core` nas dependências **e** a questão depende do framework:

- components, templates, signals, `computed`, `linkedSignal`, `resource`;
- change detection, OnPush, zoneless, Zone.js;
- `@defer`, control flow, hidratação, SSR;
- rotas, `HttpClient`, formulários tipados ou signal forms;
- Angular Material, CDK, performance de bundle.

CSS puro, TypeScript genérico, HTTP e acessibilidade de HTML ficam com o Frontend Agent.

## Contratos

**Entrada:**

```text
Framework / version:
Change detection:
Relevant architecture rules:
Problem:
Goal:
Constraints:
Files involved:
Workspace:
```

**Saída:**

```text
Context detected:
Diagnosis:
Solution:
Files changed:
Verification:
Impacts and trade-offs:
Open questions / uncertainties:
```

Sem browser, o relatório diz `visual verification not run`.

## Regras padrão

| Tema | Regra |
|---|---|
| Versão | A documentação em angular.dev é a do major atual. A versão instalada vence o exemplo. |
| Signals | Estado novo em código que já usa signals. `computed` para valor derivado. `effect` só para efeito colateral. |
| RxJS | Permanece onde o arquivo já é RxJS. Não reescrever um fluxo que funciona. |
| Zoneless | v21+ já é o padrão. v20.2+ pede confirmação antes de ligar num app existente. Antes disso, não usar em produção. |
| `@defer` | Só para o que não é LCP e não está na primeira tela. Import direto, sem barrel. Placeholder com tamanho. |
| Listas | `@for` com `track` estável. Filtros compartilháveis ficam na query string. |
| Formulários | Reativos tipados até a v20. Signal forms só na v21+, e só se o projeto não tiver outro padrão. |
| UI | A biblioteca que o projeto já usa. App novo sem design system: Angular Material, com confirmação. |
| Dependências | Nenhuma biblioteca nova sem confirmação. |

## Arquivos de referência

| Arquivo | Conteúdo |
|---|---|
| [`agent.md`](agent.md) | Prompt, fluxo, contratos, Definition of done |
| [`versions.md`](versions.md) | Detecção de versão, fontes de docs, mapa v16–atual, MCP |
| [`signals.md`](signals.md) | signal, computed, effect, linkedSignal, resource, RxJS |
| [`change-detection.md`](change-detection.md) | Zone.js, zoneless, OnPush, o que atualiza a view |
| [`templates.md`](templates.md) | Control flow e `@defer` |
| [`components.md`](components.md) | Standalone, inputs e outputs, lifecycle |
| [`di.md`](di.md) | `inject()` e providers |
| [`routing.md`](routing.md) | Lazy routes, query params, render mode |
| [`data.md`](data.md) | HttpClient, interceptors, `httpResource` |
| [`forms.md`](forms.md) | Formulários tipados e signal forms |
| [`performance.md`](performance.md) | Orçamentos, imagens, hidratação, bundle |
| [`ui.md`](ui.md) | Material, CDK, estados de UX |
| [`testing.md`](testing.md) | Testes, review, refactoring |
| [`anti-patterns.md`](anti-patterns.md) | Erros a conferir antes de reportar |
| [`verification.md`](verification.md) | Build, testes, browser |
| [`bootstrap.md`](bootstrap.md) | Projeto novo |
| [`examples/`](examples/) | Lista com signals, `@defer`, bootstrap zoneless, formulário tipado |
| [`detect`](detect) | Pacote que identifica um projeto Angular |

## Documentação e MCP

- [angular.dev](https://angular.dev) descreve o major estável atual. O índice para agentes está em [llms.txt](https://angular.dev/llms.txt).
- Majors antigos: site versionado (`https://v17.angular.dev` e equivalentes), quando existir.
- O [MCP do Angular CLI](https://angular.dev/ai/mcp) expõe `get_best_practices`, `search_documentation` e `onpush_zoneless_migration`. Use o CLI **do projeto** para as práticas baterem com a versão instalada. `npx @angular/cli mcp` sem versão fala do CLI mais novo.
- Guia de atualização: [angular.dev/update-guide](https://angular.dev/update-guide).

## Instalação

```bash
<clone>/scripts/install.sh --add angular
<clone>/scripts/install.sh --project --subagents angular
```

Em um projeto com `@angular/core` no `package.json`, o instalador sugere este subagente. Recarregue a janela do Cursor depois de instalar.

## Cenários de avaliação

Em [`evals/scenarios.md`](../../evals/scenarios.md):

| # | Cenário |
|---|---|
| 18 | `@defer` abaixo da dobra, sem adiar o LCP |
| 19 | Zoneless conforme a versão, sem migração de carona |
| 20 | Estado derivado com `computed`, não com `effect` |
| 21 | Lista nova com signals, busca e estados |
