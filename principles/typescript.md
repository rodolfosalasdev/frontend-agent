# Princípios: TypeScript

A tipagem deve representar corretamente o domínio e reduzir erros. Não use TypeScript apenas para satisfazer o compilador.

## Regras

- **`any` só com justificativa explícita.** Para valores realmente desconhecidos (JSON externo, `catch`, mensagens de `postMessage`), use `unknown` e faça narrowing.
- **Tipos precisos:** literais e unions em vez de `string` genérico quando o conjunto de valores é conhecido.
- **Narrowing seguro** em vez de casts: `typeof`, `instanceof`, `in`, discriminantes e type guards (`value is T`).
- **Casts (`as`)** só quando você tem uma garantia que o compilador não consegue enxergar, e de preferência isolados em uma função de fronteira. Evite `as unknown as T`.
- **Non-null assertion (`!`)** apenas quando a garantia é evidente no próprio código.
- **Generics** quando há reutilização real com relação entre tipos de entrada e saída. Evite generics que só repassam o tipo sem restringir nada.
- **Tipagem explícita** em fronteiras públicas (funções exportadas, contratos de módulo, retorno de funções de API). Inferência é suficiente em variáveis locais óbvias.
- **`satisfies`** para validar que um objeto atende a um tipo sem perder a inferência literal (confirme que a versão do TypeScript do projeto suporta).
- Prefira `readonly` e `as const` para dados que não devem mudar.

## Modelar estados impossíveis como tipos

Prefira discriminated unions a vários booleanos independentes:

```ts
// Evite: permite combinações inválidas (isLoading && error && data)
type RequestState<T> = {
  isLoading: boolean;
  error?: Error;
  data?: T;
};

// Prefira: cada estado carrega só o que faz sentido nele
type RequestState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };
```

Use verificação de exaustividade com `never` em `switch` sobre discriminantes, para que um novo estado force a atualização dos pontos que o tratam.

## Dados externos

Tipos TypeScript não existem em runtime. Dados vindos de API, storage, URL ou mensagens externas precisam de validação na fronteira quando a confiabilidade importa:

- valide e converta na borda (API client, adapter), entregando um tipo confiável para o resto da aplicação;
- use uma biblioteca de schema **somente se o projeto já usa uma** ou se a necessidade justificar a dependência; para casos simples, type guards manuais bastam.

## Configuração

- Recomende `strict: true` em projetos novos. Em projetos existentes, respeite a configuração atual e proponha endurecimento incremental se fizer sentido.
- Verifique `target`, `module`, `moduleResolution` e `lib` antes de usar recursos que dependem deles.
- Considere `noUncheckedIndexedAccess` quando acessos por índice forem fonte recorrente de bugs.

## Evite

- Tipos utilitários encadeados que ninguém consegue ler. Se precisar de três níveis de mapped/conditional types, reconsidere o design.
- Enums quando uma union de literais resolve (unions não geram código em runtime). Respeite a convenção do projeto se ele já usa enums.
- Interfaces gigantes com dezenas de campos opcionais representando vários contextos. Separe por contexto.
- Duplicar manualmente tipos que podem ser derivados (`Pick`, `Omit`, `ReturnType`, indexed access), quando a derivação deixa a relação explícita.
