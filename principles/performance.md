# Princípios: Performance

Performance é considerada desde a arquitetura, mas não justifica complexidade desnecessária. Seja **performance-aware**, não performance-at-all-costs.

## Regra de diagnóstico

Não recomende otimizações porque são populares. Antes de otimizar, identifique:

```text
Problema → Causa → Métrica afetada → Impacto → Otimização
```

- Meça antes e depois. Sem medição, é suposição.
- Diferencie dados de laboratório (Lighthouse, DevTools, WebPageTest) de dados de campo (RUM, CrUX). Decisões importantes devem considerar dados de campo quando existirem.
- Evite micro-otimizações sem impacto mensurável.

## Core Web Vitals

| Métrica | Mede | Causas comuns | Direções de correção |
|---|---|---|---|
| **LCP** | Tempo até o maior elemento visível renderizar | TTFB alto, recurso LCP descoberto tarde, imagem pesada, render-blocking CSS/JS, renderização no cliente | Servir o recurso LCP no HTML inicial, `fetchpriority="high"`, preload quando descoberto tarde, imagens otimizadas e dimensionadas, reduzir CSS/JS bloqueante |
| **INP** | Latência das interações | Long tasks no main thread, handlers pesados, re-render excessivo, layout thrashing | Quebrar tarefas longas, adiar trabalho não urgente, mover processamento para Web Worker, reduzir trabalho por interação, dar feedback visual imediato |
| **CLS** | Estabilidade visual | Imagens/iframes sem dimensões, conteúdo injetado acima do existente, fontes trocando, anúncios | `width`/`height` ou `aspect-ratio`, reservar espaço, `font-display` adequado e fallback com métricas ajustadas, animar só `transform`/`opacity` |

Métricas de apoio quando relevantes: **TTFB**, **FCP**, **TBT** (proxy de laboratório para INP).

Não afirme valores de limiar ("bom", "ruim") sem conferir a documentação atual em web.dev, pois eles podem ser revisados.

## JavaScript

- **Bundle size:** analise o que entra no bundle (ferramenta de análise do bundler) antes de propor cortes.
- **Code splitting e dynamic imports:** divida por rota ou por funcionalidade usada sob demanda, não em pedaços minúsculos que criam waterfalls.
- **Tree shaking:** depende de ESM e de imports nomeados; bibliotecas CommonJS ou com side effects podem impedir.
- **Dependências:** questione bibliotecas grandes para problemas pequenos. A Web Platform frequentemente já resolve (`Intl`, `URL`, `structuredClone`, `fetch`).
- **Main thread:** tarefas acima de ~50 ms são long tasks e prejudicam a responsividade. Divida o trabalho e ceda ao event loop entre partes.
- **Memória:** listeners, timers, observers e referências não liberadas causam vazamentos em SPAs de longa duração.

## Network

- Reduza o número de requisições no caminho crítico e elimine **waterfalls** (recurso que só é descoberto depois de outro carregar).
- Payload: compressão (Brotli/gzip), formatos modernos de imagem (AVIF/WebP), imagens responsivas (`srcset`, `sizes`).
- Cache HTTP correto (ver `http.md`): assets com hash no nome podem ter cache longo e `immutable`; HTML precisa de revalidação.
- **Resource hints**, com parcimônia:
  - `preconnect` para origens críticas de terceiros;
  - `preload` para recursos críticos descobertos tarde (fonte, imagem LCP);
  - `prefetch` para recursos prováveis da próxima navegação.
  Excesso de hints compete por banda e piora o resultado.
- CDN para assets estáticos; HTTP/2 e HTTP/3 reduzem o custo de múltiplas requisições, mas não eliminam waterfalls.
- Scripts de terceiros costumam ser o maior custo: carregue com `defer`/`async`, adie os não essenciais e meça o impacto de cada um.

## Rendering

- **Critical Rendering Path:** CSS bloqueia renderização; JS síncrono no `<head>` bloqueia parsing. Use `defer` ou `type="module"` para scripts.
- **DOM size:** DOMs muito grandes deixam estilo, layout e memória mais caros. Para listas longas, considere paginação ou virtualização.
- **Layout thrashing:** evite intercalar leituras (`offsetHeight`, `getBoundingClientRect`) e escritas de estilo no mesmo frame. Agrupe leituras, depois escritas.
- **Animações:** prefira `transform` e `opacity` (compositor). Use `requestAnimationFrame` para trabalho visual. Respeite `prefers-reduced-motion`.
- **Conteúdo fora da tela:** `content-visibility: auto` e `loading="lazy"` em imagens/iframes abaixo da dobra. **Nunca** use lazy loading na imagem LCP.
- **Frequência de renderização:** agrupe atualizações; aplique debounce/throttle em eventos de alta frequência (scroll, resize, input) quando apropriado.

## Fontes

- Limite famílias e pesos; prefira fontes variáveis quando substituem vários arquivos.
- `font-display: swap` ou `optional` conforme a prioridade entre conteúdo visível e estabilidade.
- Preload apenas da fonte usada acima da dobra.
- Self-hosting evita conexão extra a terceiros.

## Checklist de auditoria

Use quando o pedido for "está lento" ou "melhore a performance":

1. Qual métrica ou sintoma? Em que página, dispositivo e rede?
2. Existe dado de campo? Se não, reproduza em laboratório com throttling de CPU e rede.
3. Grave um trace de performance e identifique: recurso LCP, long tasks, layout shifts, waterfalls.
4. Levante hipóteses ordenadas por impacto provável e custo de correção.
5. Corrija uma causa por vez e meça novamente.
6. Reporte: métrica antes/depois, causa, correção aplicada e trade-offs.
