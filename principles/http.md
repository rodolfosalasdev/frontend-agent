# Princípios: HTTP, APIs e Data Flow

## Visão de ponta a ponta

```text
Frontend → Network → HTTP → BFF/API → Backend
```

Não atribua automaticamente um problema de API ao frontend. Antes de concluir, verifique na aba Network: status, headers, timing, payload de request e response.

## Semântica HTTP

- **Métodos:** `GET` (leitura, seguro, cacheável), `POST` (criação/ação), `PUT` (substituição, idempotente), `PATCH` (alteração parcial), `DELETE` (idempotente).
- **Idempotência** define o que pode ser repetido com segurança em retry. `POST` não é idempotente, a menos que a API suporte chave de idempotência.
- **Status codes:** trate por faixa e pelos casos relevantes para a UX:
  - `2xx` sucesso (`204` sem corpo);
  - `3xx` redirecionamento (`304` revalidação de cache);
  - `400` entrada inválida, `401` não autenticado, `403` sem permissão, `404` inexistente, `409` conflito, `422` validação, `429` rate limit (respeite `Retry-After`);
  - `5xx` falha do servidor, possivelmente transitória.
- `401` e `403` são diferentes: o primeiro pede autenticação, o segundo informa falta de permissão (ver `security.md`).

## Headers relevantes

- `Content-Type` e `Accept`: declare o formato enviado e o esperado.
- `Authorization`: tokens em header, nunca em query string (query strings vão para logs e histórico).
- `Cache-Control`, `ETag`, `Last-Modified`: controle de cache e revalidação.
- Compressão (`Content-Encoding`): verifique se respostas grandes estão comprimidas.

## Cache

- **Assets com hash no nome:** `Cache-Control: public, max-age=31536000, immutable`.
- **HTML e dados que mudam:** `no-cache` (revalida sempre) com `ETag`/`Last-Modified`, ou `max-age` curto.
- **Dados privados:** `private` ou `no-store` para conteúdo sensível.
- `no-cache` não significa "não armazenar"; significa "revalide antes de usar". `no-store` é que impede o armazenamento.
- Cache no cliente (em memória ou storage) é uma camada adicional; defina a estratégia de invalidação antes de criar um.

## CORS

- CORS é aplicado pelo **navegador** e configurado pelo **servidor**. O frontend não "resolve" CORS; ele só pode ajustar a requisição (headers, credenciais) ou usar um proxy/BFF na mesma origem.
- Requisições com headers customizados, métodos diferentes de GET/POST/HEAD ou `Content-Type: application/json` disparam **preflight** (`OPTIONS`), com custo de latência.
- `credentials: 'include'` exige `Access-Control-Allow-Credentials: true` e origem explícita (sem `*`).
- Um erro de CORS no console muitas vezes esconde outro problema (servidor retornando 500 sem os headers CORS).

## Camadas de integração

```text
UI → Presentation → Application → API Client → BFF/API
```

- **API Client:** único lugar que conhece URLs, headers, serialização e o formato bruto das respostas. Converte DTO em modelo de domínio e erros HTTP em erros da aplicação.
- **Application:** orquestra chamadas, decide retry, combina dados.
- **Presentation/UI:** consome estados prontos (loading, erro, vazio, sucesso), sem conhecer HTTP.
- Não misture automaticamente **API response** com **UI state**. A resposta é um dado; o estado da tela inclui também carregamento, erro, seleção, filtros e rascunhos.

## Estados que toda integração deve tratar

- **Loading:** indique progresso sem causar layout shift; para ações rápidas, considere atrasar o indicador para evitar flicker.
- **Empty:** diferente de erro; comunique e, se possível, ofereça uma ação.
- **Error:** mensagem útil ao usuário, ação de recuperação (tentar novamente), sem expor detalhes técnicos sensíveis.
- **Success**, incluindo dados parciais quando aplicável.

## Resiliência

- **Timeout:** `fetch` não tem timeout padrão. Use `AbortSignal.timeout()` ou um `AbortController` com timer.
- **Cancelamento:** cancele requisições obsoletas (ver `javascript.md`).
- **Retry:** apenas para falhas transitórias (rede, `5xx`, `429`) e operações idempotentes; use backoff exponencial com jitter e limite de tentativas. Nunca faça retry de `4xx` de validação.
- `fetch` só rejeita por falha de rede ou abort. Um `404` ou `500` **resolve** normalmente: verifique `response.ok`.
- Trate respostas que não são JSON válido (páginas de erro HTML de proxies e gateways).

## Paginação, validação e otimismo

- **Paginação:** cursor é mais estável que offset para dados que mudam; mantenha a página na URL quando for navegável.
- **Validação:** no cliente para UX; no servidor para segurança. Mapeie erros de validação do servidor (`400`/`422`) para os campos correspondentes do formulário.
- **Optimistic updates:** melhoram a percepção de velocidade, mas exigem rollback em caso de falha e cuidado com conflitos. Use em ações de baixo risco e alta frequência.

## BFF / BFA

Um Backend for Frontend faz sentido quando:

- o frontend precisa agregar várias APIs e isso gera waterfalls no cliente;
- é preciso adaptar payloads para reduzir o volume transferido;
- segredos ou tokens de terceiros não podem ir para o browser;
- a sessão deve ficar em cookie `HttpOnly` gerenciado no servidor.

Custo: mais um serviço para operar, versionar e observar. Não crie um BFF só para repassar chamadas sem transformação.

## Contratos Frontend ↔ Backend

- Defina contratos explícitos (OpenAPI, JSON Schema ou tipos compartilhados) em vez de inferir o formato pelas respostas.
- Formato de erro consistente entre endpoints.
- Datas em ISO 8601 com timezone; valores monetários sem ponto flutuante (centavos ou string decimal).
- Mudanças no contrato devem ser retrocompatíveis ou versionadas.
