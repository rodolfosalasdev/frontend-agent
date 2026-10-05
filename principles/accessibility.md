# Princípios: Acessibilidade

Acessibilidade faz parte da implementação, não é uma etapa posterior. A acessibilidade básica é **inegociável**.

Referência: WCAG (versão exigida pelo projeto; na ausência, use o nível AA da versão atual) e WAI-ARIA Authoring Practices para padrões de componentes.

## HTML semântico antes de ARIA

- A primeira regra do ARIA: se existe um elemento HTML nativo com a semântica e o comportamento necessários, use-o.
- `<button>` para ações, `<a href>` para navegação. Nunca `<div onclick>`.
- Landmarks: `<header>`, `<nav>`, `<main>` (um por página), `<aside>`, `<footer>`.
- Hierarquia de títulos (`h1`–`h6`) coerente, sem pular níveis por motivo visual.
- Listas com `<ul>`/`<ol>`, tabelas de dados com `<table>`, `<th>` e `scope`.
- ARIA errado é pior que nenhum ARIA: `role` e `aria-*` mudam o que o leitor de tela anuncia, não o comportamento.

## Teclado

- Todo elemento interativo deve ser alcançável e operável por teclado.
- Ordem de foco segue a ordem visual e lógica. Evite `tabindex` positivo.
- `tabindex="0"` apenas para tornar focável um elemento customizado; `tabindex="-1"` para foco programático.
- Widgets compostos (menus, tabs, listbox) seguem os padrões de teclado do WAI-ARIA APG (setas, Home/End, Escape).
- Ofereça um link "pular para o conteúdo" em páginas com navegação extensa.

## Foco

- **Foco sempre visível.** Nunca remova `outline` sem substituir por um indicador equivalente; prefira `:focus-visible`.
- Em navegação no cliente (SPA), mova o foco para o novo conteúdo principal ou título e anuncie a mudança de página.
- Ao remover um elemento focado, devolva o foco a um lugar lógico.

## Dialogs e overlays

- Prefira o elemento nativo `<dialog>` com `showModal()`: ele fornece foco inicial, isolamento do conteúdo de fundo e fechamento com Escape. Confirme o suporte nos navegadores-alvo.
- Ao fechar, devolva o foco ao elemento que abriu o dialog.
- Dialog precisa de nome acessível (`aria-labelledby` apontando para o título).
- Para popovers, avalie o atributo `popover` nativo, confirmando o suporte.

## Formulários

- Todo campo tem `<label>` associado (`for`/`id` ou envolvendo o campo). Placeholder não substitui label.
- Agrupe campos relacionados com `<fieldset>` e `<legend>`.
- Use `type`, `autocomplete` e `inputmode` corretos: melhoram teclado mobile e preenchimento automático.
- **Erros:**
  - associados ao campo com `aria-describedby`;
  - campo marcado com `aria-invalid="true"`;
  - mensagem que explica como corrigir, não apenas "campo inválido";
  - ao submeter com erros, leve o foco ao primeiro campo inválido ou a um resumo de erros.
- Não dependa apenas de cor para indicar erro ou obrigatoriedade.

## Conteúdo dinâmico

- Use live regions (`aria-live="polite"`, ou `role="status"` / `role="alert"`) para anunciar mudanças que não recebem foco: resultados de busca, confirmações, erros assíncronos.
- A live region deve existir no DOM **antes** do conteúdo ser inserido nela.
- Não abuse de `assertive`/`alert`: interrompe o usuário.

## Imagens e mídia

- `alt` descritivo para imagens informativas; `alt=""` para decorativas.
- Ícones sem texto em botões precisam de nome acessível (`aria-label` ou texto visualmente oculto).
- SVG decorativo com `aria-hidden="true"`.
- Vídeo com legendas; áudio com transcrição; sem autoplay com som.

## Visual

- **Contraste** mínimo conforme o nível WCAG exigido, para texto e para componentes de interface (bordas de campos, ícones, foco).
- Informação nunca transmitida apenas por cor.
- Conteúdo funcional com zoom de 200% e reflow em larguras estreitas.
- Respeite `prefers-reduced-motion` (ver `css-ui.md`).

## Nome acessível de componentes customizados

Quando criar um componente sem equivalente nativo:

- defina `role` adequado, nome acessível, estados (`aria-expanded`, `aria-selected`, `aria-checked`, `aria-pressed`) e relações (`aria-controls`);
- mantenha os estados ARIA sincronizados com o estado visual;
- implemente o comportamento de teclado esperado pelo padrão APG.

## Verificação

- Navegue pelo fluxo usando apenas o teclado.
- Use ferramentas automáticas (axe, Lighthouse) como primeira linha; elas detectam apenas parte dos problemas.
- Quando o fluxo for crítico, teste com leitor de tela (VoiceOver, NVDA).
- Em testes automatizados, prefira seletores por role e nome acessível: eles verificam a acessibilidade e o comportamento ao mesmo tempo.
