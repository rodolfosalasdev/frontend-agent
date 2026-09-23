# Princípios: Arquitetura

Estes princípios valem quando o `architecture.md` do projeto não define regra própria. Havendo conflito, o projeto vence.

## Separação de responsabilidades

Camadas de referência, aplicadas **na proporção da complexidade** do sistema:

```text
Presentation → Application → Domain → Infrastructure
```

- **Presentation:** renderização, eventos de UI, formatação para exibição.
- **Application:** casos de uso, orquestração, coordenação de estado.
- **Domain:** regras de negócio puras, sem dependência de UI, rede ou framework.
- **Infrastructure:** HTTP clients, storage, SDKs externos, adapters.

Regras:

- Dependências apontam para dentro: Presentation depende de Application; Domain não depende de ninguém.
- Um script de 200 linhas não precisa de quatro camadas. Comece simples e separe quando a mistura começar a causar dor real (dificuldade de testar, mudanças que se espalham, duplicação).
- Não crie abstrações por antecipação.

## Componentização

Componentes (sejam Web Components, funções de render, módulos de UI ou componentes de framework) devem ter responsabilidade clara.

Evite:

- componentes gigantes que misturam fetch, regra de negócio e renderização;
- componentes excessivamente genéricos, com dezenas de opções para cobrir casos hipotéticos;
- duplicação significativa (três ocorrências parecidas justificam extrair; duas, geralmente não).

Quando a complexidade justificar, separe:

```text
UI → Behavior → Application Logic → Domain Logic
```

## Interfaces e contratos

- Interfaces pequenas e específicas por contexto, em vez de uma interface gigante que atende vários contextos.
- Não trate automaticamente como o mesmo objeto:

| Modelo | Propósito |
|---|---|
| API Response / DTO | Formato do transporte. Pertence ao contrato com o backend. |
| Domain Model | Representa o negócio. Estável, independente do transporte. |
| View Model | Pronto para exibição (datas formatadas, labels, flags de UI). |
| Component Model | Props/atributos que um componente recebe. |
| Form Model | Estado editável do formulário, incluindo valores parciais e inválidos. |

- Faça o mapeamento DTO → Domain na borda (camada de infraestrutura/API client). Assim, mudanças no backend ficam contidas em um lugar.
- Quando os formatos forem idênticos e o sistema for simples, reutilizar o tipo é aceitável. Separe quando divergirem.

## Design patterns

Use quando houver benefício concreto, não para sofisticar o código.

| Pattern | Quando faz sentido no frontend |
|---|---|
| Composition | Padrão de construção de UI. Prefira a herança. |
| Adapter | Isolar SDKs externos ou formatos de API. |
| Strategy | Variações de comportamento selecionadas em runtime (ex.: formas de pagamento). |
| Facade | Simplificar um subsistema complexo para a camada de UI. |
| Observer / Pub-Sub | Eventos desacoplados. Na Web Platform, `EventTarget` e `CustomEvent` já resolvem. |
| Factory | Criação com lógica condicional não trivial. |
| Repository | Abstrair a origem dos dados quando há mais de uma (API, cache, IndexedDB). |
| State | Fluxos com estados e transições explícitas (wizards, players, conexões). |
| Command | Undo/redo, filas de ações, atalhos de teclado. |
| Dependency Injection | Substituir dependências em testes. Parâmetros de função costumam bastar. |

## Refactoring

```text
Preservar comportamento → Reduzir complexidade → Melhorar separação → Melhorar testabilidade → Melhorar performance quando necessário
```

- Garanta uma rede de segurança (testes existentes ou novos) antes de refatorar código crítico.
- Prefira mudanças incrementais e revisáveis a reescritas grandes.
- Não misture refactoring e mudança de comportamento no mesmo passo.

## Performance como decisão arquitetural

Fronteiras definem performance. Avalie o impacto de cada decisão em:

- fronteiras de componentes e localidade do estado;
- fronteiras de bundle e de lazy loading;
- fronteiras server/client e de API;
- fronteiras de cache;
- fronteiras de Micro Frontends.

Uma otimização local não deve criar um problema arquitetural maior.

## Avaliação de uma solução

- **Correctness:** funciona, incluindo casos de borda e erro?
- **Architecture:** está alinhada à arquitetura do projeto?
- **Performance:** impacto em runtime, bundle, rede ou rendering?
- **Security:** introduz algum risco?
- **Accessibility:** é acessível?
- **Maintainability:** será fácil de entender e modificar?
- **Scalability:** continua funcionando quando o sistema crescer?
- **Complexity:** é proporcional ao problema?

## Micro Frontends

Não recomende Micro Frontends só porque o sistema é grande. Eles resolvem principalmente um problema **organizacional** (times independentes com deploy independente), com custo técnico alto.

Quando o projeto já usa ou está avaliando, considere:

- bounded contexts e ownership claro por time;
- independência de deploy e versionamento;
- dependências compartilhadas (duplicação de bundles, conflitos de versão);
- comunicação entre MFEs (preferir contratos explícitos e eventos, evitar estado global compartilhado);
- roteamento, autenticação e sessão compartilhadas;
- observabilidade distribuída;
- performance (custo de múltiplos runtimes e bundles);
- isolamento de falhas (um MFE quebrado não deve derrubar a página).

## WebView

Quando a aplicação roda dentro de uma WebView nativa, considere:

- comunicação Native ↔ Web: contrato explícito e versionado de mensagens, validação das mensagens recebidas;
- lifecycle: pausa/retomada do app, WebView recriada, estado perdido;
- performance: dispositivos mais fracos, cold start, memória limitada;
- rede e offline/online;
- autenticação: como o token chega à WebView e como é renovado;
- deep links e navegação entre nativo e web;
- segurança: restringir origens carregadas e pontes expostas ao JavaScript;
- storage: comportamento e persistência variam por plataforma;
- compatibilidade: versão do engine da WebView (Android System WebView, WKWebView).

## Observabilidade

Uma aplicação frontend deve ser observável em produção. Quando relevante, considere:

- **Error tracking:** erros não tratados (`error`, `unhandledrejection`), com source maps e contexto (rota, versão, usuário anonimizado).
- **Performance monitoring:** Core Web Vitals de usuários reais (RUM), não só de laboratório.
- **Logging e tracing:** correlação de requisições frontend ↔ backend (ex.: propagar um trace/request ID).
- **Métricas de produto e UX:** fluxos críticos, taxas de erro por etapa.
- Nunca envie dados sensíveis ou PII para ferramentas de observabilidade sem tratamento.
