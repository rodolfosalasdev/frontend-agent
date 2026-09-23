# Architecture — <Nome do Projeto>

> Modelo de `architecture.md` para projetos frontend.
> Copie para a raiz do projeto (ou para `docs/architecture.md`) e preencha.
> O Frontend Agent trata este arquivo como **fonte de verdade**: as regras daqui vencem os princípios gerais do agente.
> Remova as seções que não se aplicam. Seja específico: regras vagas não orientam decisões.

## 1. Visão geral

- **Propósito do produto:**
- **Tipo de aplicação:** (SPA, MPA, site estático, widget embutível, WebView, Micro Frontend, ...)
- **Público e dispositivos principais:**

## 2. Stack e versões

| Tecnologia | Versão | Observação |
|---|---|---|
| Linguagem (TypeScript/JavaScript) | | |
| Framework (ou "nenhum") | | |
| Bundler | | |
| Gerenciador de pacotes | | |
| Test runner | | |
| Solução de UI / CSS | | |

### Framework (opcional)

Preencha quando o projeto usa um framework. Os especialistas de framework leem esta seção.

- **Router / modelo de rotas:** (ex.: Next.js App Router, Pages Router ou ambos)
- **Estratégia padrão de renderização:** (ex.: Server Components por padrão; Client Components só nas folhas interativas)
- **Estratégia de cache:** (ex.: Cache Components habilitado; tags por entidade; revalidação após mutações)
- **Mutações:** onde ficam Server Actions / Server Functions e quais regras de validação e autorização seguem
- **Endpoints:** quando usar Route Handlers vs chamar o backend diretamente
- **Proxy / middleware:** responsabilidades permitidas
- **Estado de tabelas e listas:** na URL via search params (padrão) ou outra estratégia; nomes de parâmetros padronizados (ex.: `q`, `page`, `sort`, filtros)
- **Server state no cliente:** biblioteca usada (ex.: TanStack Query, SWR ou nenhuma), onde fica o provider e o `staleTime` padrão
- **Flags experimentais em uso:**

## 3. Navegadores suportados

- `browserslist`:
- Nível de suporte (ex.: Baseline Widely available, últimas 2 versões, WebView mínima):
- Política de polyfills:

## 4. Estrutura de pastas

```text
src/
  ...
```

## 5. Camadas e regras de dependência

- **Camadas:** (ex.: presentation, application, domain, infrastructure)
- **Quem pode depender de quem:**
- **Proibido:** (ex.: componentes de UI chamando `fetch` diretamente)

## 6. Padrões obrigatórios

- Componentização:
- Integração com API (onde ficam clients, DTOs, mapeamentos):
- Tratamento de erros:
- Formulários e validação:

## 7. Nomenclatura

- Arquivos e pastas:
- Componentes / elementos customizados:
- Funções, variáveis, tipos:
- Testes:

## 8. Tecnologias

- **Permitidas:**
- **Proibidas ou desencorajadas (e por quê):**
- **Processo para adicionar uma dependência:**

## 9. UI e design system

- Solução adotada:
- Onde ficam os tokens:
- Regras de tema (claro/escuro, marcas):
- Breakpoints:

## 10. Estado

- Estratégia para estado local, compartilhado, server state, URL e persistente:
- Bibliotecas usadas (se houver):

## 11. Testes

- Níveis utilizados e o que cada um cobre:
- Onde ficam os testes:
- Requisitos mínimos por PR:

## 12. Performance

- Orçamentos (bundle, LCP, INP, CLS):
- Estratégias obrigatórias (ex.: lazy loading por rota, imagens otimizadas):

## 13. Segurança

- Modelo de autenticação e armazenamento de sessão:
- CSP:
- Regras para conteúdo HTML externo:

## 14. Acessibilidade

- Nível WCAG exigido:
- Ferramentas de verificação:

## 15. Observabilidade

- Error tracking:
- RUM / Web Vitals:
- Logging e correlação com o backend:

## 16. Build, CI/CD e ambientes

- Scripts principais (`dev`, `build`, `lint`, `typecheck`, `test`):
- Etapas do pipeline:
- Ambientes e variáveis de ambiente públicas:

## 17. Decisões arquiteturais (ADRs)

| Data | Decisão | Motivo | Alternativas descartadas |
|---|---|---|---|
| | | | |
