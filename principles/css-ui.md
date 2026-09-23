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
