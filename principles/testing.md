# Princípios: Testes e Code Review

## Estratégia de testes

Níveis de teste:

```text
Unit → Integration → Component → E2E
```

| Nível | Protege | Custo | Use para |
|---|---|---|---|
| **Unit** | Lógica isolada | Baixo | Regras de domínio, funções puras, formatadores, parsers, reducers |
| **Integration** | Colaboração entre módulos | Médio | API client + mapeamento, fluxos de caso de uso com dependências falsas |
| **Component** | Comportamento de UI isolada | Médio | Interação, estados de loading/erro/vazio, acessibilidade do componente |
| **E2E** | Fluxos reais no browser | Alto | Poucos fluxos críticos de negócio (login, checkout, cadastro) |

Regras:

- Escolha o nível mais barato que protege o comportamento em questão.
- Não crie testes apenas para aumentar cobertura. Cobertura alta com testes frágeis é custo, não segurança.
- Priorize testes que protejam: comportamento, regras de negócio, contratos, fluxos críticos e regressões.
- Ao corrigir um bug, escreva primeiro um teste que falha reproduzindo-o, quando viável.

## Como escrever bons testes

- **Teste comportamento, não implementação.** Evite acoplar a detalhes internos (métodos privados, estrutura de estado, número de chamadas internas).
- Consulte elementos como o usuário percebe: por **role e nome acessível**, label e texto, não por classes CSS ou estrutura do DOM.
- Um comportamento por teste, com nome que descreve o cenário e o resultado esperado.
- Estrutura clara: preparar, agir, verificar.
- **Mocks na fronteira** (rede, tempo, storage), não entre módulos internos. Para HTTP, prefira interceptar a camada de rede a mockar o API client inteiro.
- Controle o tempo com timers falsos em vez de esperas reais; evite `sleep` em testes.
- Testes devem ser determinísticos e independentes entre si.
- Use as ferramentas que o projeto já tem. Não introduza um novo test runner sem necessidade e sem confirmação.

## E2E

- Poucos testes, cobrindo os fluxos que mais doem se quebrarem.
- Dados de teste isolados e previsíveis.
- Espere por condições observáveis (elemento visível, requisição concluída), nunca por tempo fixo.
- Um E2E instável (flaky) deve ser corrigido ou removido; testes ignorados geram falsa confiança.

## Roteiro de code review

Quando receber código para análise:

1. **Objetivo:** o que o código deve fazer? Qual o contexto da mudança?
2. **Contexto técnico:** framework, versões, arquitetura do projeto.
3. **Arquitetura:** respeita camadas, regras de dependência e convenções? Responsabilidades estão bem separadas?
4. **Correctness:** funciona nos casos normais, de borda e de erro? Há race conditions, estados impossíveis, erros engolidos?
5. **Performance:** impacto em bundle, rede, rendering ou main thread? (`performance.md`)
6. **Segurança:** sinks perigosos, segredos, tokens, autorização no cliente? (`security.md`)
7. **Acessibilidade:** semântica, teclado, foco, labels, contraste? (`accessibility.md`)
8. **Tipagem:** `any`, casts, tipos que não representam o domínio? (`typescript.md`)
9. **Testabilidade e testes:** o comportamento novo está protegido? Os testes são frágeis?
10. **Manutenibilidade:** nomes claros, complexidade proporcional, duplicação, abstrações prematuras?

Formato do resultado, ordenado por severidade:

- **Crítico (deve corrigir):** bugs, vulnerabilidades, quebras de acessibilidade básica, violação de regra arquitetural obrigatória.
- **Importante (deveria corrigir):** problemas de performance mensuráveis, fragilidade, dívida técnica relevante.
- **Sugestão (considerar):** legibilidade, pequenas melhorias, alternativas.

Para cada item: onde (arquivo e trecho), qual o problema, por que importa e como corrigir, com código quando ajudar.

Não reescreva o código inteiro sem explicar os problemas relevantes. Reconheça também o que está bem feito quando for relevante para a decisão.
