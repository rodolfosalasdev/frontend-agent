# Princípios: Segurança

Segurança é considerada desde o design e é **inegociável**. O frontend roda em um ambiente controlado pelo usuário: tudo que está no browser pode ser lido e alterado.

## Regras fundamentais

- **Nunca confie no cliente.** Validação, autorização e regras de negócio críticas acontecem no servidor. O frontend apenas reflete essas decisões na UX.
- **Nenhum segredo no bundle.** Variáveis de ambiente embutidas no build são públicas. Chaves privadas de APIs, segredos de OAuth e credenciais ficam no servidor (ou em um BFF).
- **Authentication ≠ Authorization.**
  - Authentication: quem é o usuário.
  - Authorization: o que esse usuário pode fazer.
  - Esconder um botão não é autorização. O servidor deve negar a ação (`403`) independentemente da UI.

## XSS (Cross-Site Scripting)

É a vulnerabilidade mais relevante no frontend, porque um XSS dá acesso a tudo que a página acessa.

- Insira texto com `textContent`, `setAttribute` ou APIs equivalentes, que não interpretam HTML.
- **Sinks perigosos:** `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, `eval`, `new Function`, `setTimeout`/`setInterval` com string, atributos de evento (`onclick`) montados com dados.
- Quando for realmente necessário renderizar HTML vindo de fonte externa (conteúdo rico, markdown), sanitize com uma biblioteca estabelecida e mantida, nunca com regex própria.
- **URLs dinâmicas:** valide o protocolo antes de usar em `href`, `src` ou `location` (bloqueie `javascript:` e `data:` quando não esperados). Use `URL` para fazer o parsing.
- Dados de URL, `postMessage`, storage e respostas de API são **não confiáveis**.
- Em `postMessage`, sempre verifique `event.origin` e valide o formato da mensagem; ao enviar, especifique a origem de destino, nunca `'*'` para dados sensíveis.

## CSP (Content Security Policy)

- Recomende CSP como defesa em profundidade contra XSS.
- Prefira políticas com nonce ou hash e `strict-dynamic` a listas extensas de domínios.
- Evite `unsafe-inline` e `unsafe-eval`; código que depende deles é um sinal de risco.
- Implante primeiro em modo `Content-Security-Policy-Report-Only` para identificar quebras.
- Trusted Types pode bloquear sinks perigosos na origem; confirme o suporte nos navegadores-alvo.

## Tokens e sessão

| Armazenamento | Risco principal | Observação |
|---|---|---|
| Cookie `HttpOnly; Secure; SameSite` | CSRF (mitigado por `SameSite` e tokens anti-CSRF) | Inacessível ao JavaScript, protege contra roubo via XSS. Preferido para sessão. |
| Memória (variável JS) | Perdido no reload; exposto a XSS enquanto a página está aberta | Útil para access tokens de vida curta com refresh via cookie `HttpOnly`. |
| `localStorage`/`sessionStorage` | Qualquer XSS lê e exfiltra o token | Evite para tokens de sessão ou de longa duração. |

- Tokens de vida curta, com renovação controlada.
- Nunca coloque tokens em query string (vão para logs, histórico e `Referer`).
- Logout deve invalidar a sessão no servidor, não apenas apagar dados locais.

## Cookies

- `Secure`: somente HTTPS.
- `HttpOnly`: inacessível ao JavaScript (use para sessão).
- `SameSite=Lax` (padrão razoável) ou `Strict`; `None` exige `Secure` e só quando o uso cross-site for necessário.
- Escopo mínimo de `Domain` e `Path`.

## CSRF

- Relevante quando a autenticação usa cookies enviados automaticamente.
- Mitigações: `SameSite`, token anti-CSRF em requisições que alteram estado, verificação de `Origin` no servidor.
- Nunca altere estado com `GET`.

## CORS

- CORS não é mecanismo de autenticação nem de proteção do servidor: ele controla o que o **navegador** deixa uma página ler.
- `Access-Control-Allow-Origin: *` com credenciais não é permitido; refletir qualquer origem recebida equivale a desativar a proteção.

## Clickjacking

- Impeça que a aplicação seja embutida por origens não autorizadas com `frame-ancestors` na CSP (ou `X-Frame-Options` como fallback).

## Exposição de dados sensíveis

- Não logue tokens, senhas ou PII no console nem envie para ferramentas de observabilidade sem mascaramento.
- Não exponha stack traces ou mensagens internas do servidor ao usuário.
- Source maps públicos expõem o código-fonte; avalie se devem ser enviados apenas para a ferramenta de error tracking.
- Desative `autocomplete` apenas quando houver motivo real; gerenciadores de senha aumentam a segurança.

## Dependências e supply chain

- Cada dependência é código de terceiros executando com os mesmos privilégios da aplicação. Adicione só o necessário.
- Mantenha o lockfile versionado e use instalações determinísticas no CI.
- Verifique vulnerabilidades conhecidas (auditoria do gerenciador de pacotes ou ferramenta do projeto).
- Scripts de terceiros carregados de CDN: use Subresource Integrity (`integrity`) quando a versão for fixa.

## Injection e entradas

- Nunca construa HTML, CSS, URLs ou expressões com concatenação de dados não confiáveis.
- Valide e normalize entradas na fronteira, mas lembre que a validação no cliente pode ser contornada.

## Ao revisar código, procure

- uso de sinks perigosos com dados externos;
- segredos ou chaves no código ou em variáveis de ambiente públicas;
- tokens em `localStorage` ou em URLs;
- decisões de autorização feitas apenas no frontend;
- `postMessage` sem verificação de origem;
- `target="_blank"` em links externos sem `rel="noopener"` quando os navegadores-alvo não aplicarem isso por padrão;
- dependências novas sem justificativa.
