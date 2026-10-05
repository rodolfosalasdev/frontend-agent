# Princípios: CSS, UI e Design System

## Design system: siga o que o projeto já usa

A solução visual do projeto é **parametrizável**. A ordem de decisão é:

1. **O projeto já tem uma solução** (Angular Material, MUI, CSS Modules, Styled Components, Bootstrap, design system próprio, Tailwind etc.): use-a. Nunca introduza outra biblioteca de UI em paralelo.
2. **Projeto novo em React/Next.js:** o padrão preferencial é **Tailwind CSS + shadcn/ui**.
3. **Projeto novo sem framework (vanilla JS/TS):** CSS nativo com design tokens em custom properties. Tailwind é uma opção válida se o time preferir, mas não é obrigatória.

Observações:

- **shadcn/ui é baseado em React.** Não se aplica a projetos vanilla, Angular ou Vue. Para outras stacks, use a solução do ecossistema correspondente ou componentes próprios.
- Antes de adicionar um componente shadcn, verifique a configuração do projeto (`components.json`) e consulte o registro oficial (o MCP do shadcn, quando disponível) em vez de escrever o componente de memória.
- Tailwind mudou significativamente entre versões (configuração, diretivas, plugins). Confirme a versão instalada antes de propor configuração.

## Design tokens

Centralize decisões visuais em tokens, não em valores espalhados:

```css
:root {
  --color-bg: #ffffff;
  --color-fg: #111827;
  --color-accent: #2563eb;
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-4: 1rem;
  --radius-md: 0.5rem;
  --font-sans: system-ui, sans-serif;
}
```

- Tokens semânticos (`--color-danger`, `--color-surface`) acima de tokens brutos (`--red-600`) nos componentes.
- Temas (claro/escuro, marcas) trocam os valores dos tokens, não os componentes.

## CSS moderno

Prefira recursos nativos a soluções em JavaScript quando o suporte dos navegadores-alvo permitir (ver `web-platform.md` sobre Baseline):

- **Layout:** Flexbox para uma dimensão, Grid para duas; `gap` em vez de margens para espaçamento entre itens.
- **Container queries** (`@container`) para componentes que se adaptam ao espaço disponível, não à viewport.
- **`:has()`** para estilizar a partir do estado de descendentes (ex.: campo com erro), evitando classes controladas por JS.
- **Cascade layers** (`@layer`) para controlar a precedência entre reset, base, componentes e utilitários sem guerras de especificidade.
- **Propriedades lógicas** (`margin-inline`, `padding-block`, `inset-inline-start`) para suportar RTL automaticamente.
- **`clamp()`, `min()`, `max()`** para tipografia e espaçamento fluidos.
- **Nesting nativo** quando suportado pelos alvos; caso contrário, o pipeline de build deve tratar.
- **`aspect-ratio`** para reservar espaço e evitar CLS.

## Especificidade e organização

- Mantenha especificidade baixa e previsível; evite IDs para estilização e `!important` (exceto utilitários deliberados).
- Uma convenção clara e consistente (a do projeto, ou BEM, CSS Modules, utilitários) é mais importante do que qual convenção.
- Evite estilos globais que vazam para componentes.

## Responsividade

Interfaces devem funcionar em mobile, tablet e desktop, com touch, mouse e teclado, e em diferentes densidades de tela.

- **Mobile-first:** estilos base para telas pequenas, `min-width` para ampliar.
- Layouts fluidos antes de breakpoints; breakpoints definidos pelo conteúdo, não por dispositivos específicos.
- Meta viewport: `<meta name="viewport" content="width=device-width, initial-scale=1">`. Nunca bloqueie o zoom.
- **Alvos de toque** com tamanho adequado e espaçamento suficiente.
- `@media (hover: hover)` e `(pointer: coarse)` para adaptar interações a mouse ou toque.
- Imagens responsivas com `srcset`/`sizes` ou `<picture>`.
- Teste com zoom de texto a 200% e em larguras estreitas (reflow sem scroll horizontal).

## Preferências do usuário

- **`prefers-reduced-motion`:** reduza ou remova animações não essenciais.
- **`prefers-color-scheme`** e a propriedade **`color-scheme`**: suporte a tema escuro e controles nativos com as cores corretas.
- **`prefers-contrast`** e **`forced-colors`**: não esconda informação apenas com cor; teste em modo de alto contraste.

## Internacionalização visual

- Não assuma o comprimento de textos: traduções podem ser bem maiores. Evite larguras fixas em botões e labels.
- Suporte a RTL com propriedades lógicas e `dir="rtl"`.
- Formate datas, números e moedas com `Intl`, não manualmente.
- Declare `lang` no `<html>` e em trechos com idioma diferente.

## Animações

- Anime `transform` e `opacity`; evite animar propriedades de layout (`width`, `top`, `height`).
- Transições curtas e com propósito (feedback, continuidade espacial), não decorativas em excesso.
- Respeite `prefers-reduced-motion`.

## Estados de UX

Toda view que carrega dados e todo formulário que a tarefa cria ou altera precisa dos seus estados. Não acrescente esses estados numa edição que não mexe nessa tela.

| Estado | Requisito |
|---|---|
| Carregando | Indicador com o mesmo formato e tamanho do conteúdo final, sem deslocar o layout. Em ações rápidas, evite piscar a tela. |
| Vazio | Mensagem que explica por que está vazio e, quando fizer sentido, uma ação ("Criar o primeiro item", "Limpar filtros"). |
| Erro | Mensagem humana, sem detalhe interno, com uma ação de tentar de novo. O resto da página continua usável. |
| Sucesso | O conteúdo; em mutações, confirmação visível (mensagem inline, toast ou navegação). |
| Parcial / desatualizado | Ao mostrar o dado anterior enquanto atualiza, indique de forma sutil em vez de apagar a view. |

Formulários: botão de envio em estado pendente (sem envio duplo), erro ao lado do campo e associado a ele, valores preservados depois de uma falha, e feedback explícito de sucesso. Ações destrutivas pedem confirmação e dizem o que vai acontecer.

## Qualidade visual

Siga o design system do projeto. Quando ele deixar espaço, aplique:

- **Espaçamento:** a escala do projeto, de forma consistente. Itens relacionados mais perto; grupos separados por um espaço maior.
- **Tipografia:** poucos tamanhos, com papéis claros (título da página, título de seção, corpo, legenda). Comprimento de linha confortável para leitura.
- **Hierarquia:** uma ação primária por view; as secundárias visualmente mais quietas. A informação mais importante é a mais evidente.
- **Cor:** base neutra e **uma** cor de destaque para a ação primária e o foco. Cores semânticas (erro, sucesso, aviso) só no significado delas. Contraste suficiente nos temas claro e escuro.
- **Consistência:** o mesmo raio, sombra, borda e tamanho de ícone. Use tokens, não valores soltos.
- **Estados interativos:** hover, foco visível, ativo e desabilitado distintos em todo elemento interativo.
- **Movimento:** transições curtas e com propósito; respeite `prefers-reduced-motion`.
- **Alinhamento:** números em tabelas alinhados à direita, com algarismos tabulares.

**Auto-revisão:** depois de uma mudança visual, quando houver browser, confira em largura de celular e de desktop. Corrija desalinhamento, espaçamento inconsistente, overflow e estado faltando antes de reportar.
