# Interface Contract: Jina AI Reader API

**External Service**: Jina AI Reader  
**Base URL**: `https://r.jina.ai/`  
**Protocol**: HTTPS  

---

## 1. Endpoint Specification

### `GET https://r.jina.ai/{target_url}`

Converte a página da web apontada por `{target_url}` em Markdown semântico pronto para consumo por LLMs.

#### Request Headers
| Header | Valor | Obrigatório | Descrição |
|---|---|---|---|
| `Accept` | `text/plain` | Sim | Solicita o corpo limpo em formato Markdown. |
| `User-Agent` | `JobHunterApp/1.0` | Não | Identificação da aplicação solicitante. |
| `Authorization` | `Bearer {apiKey}` | Opcional | Token opcional (`JINA_API_KEY`) para usuários com plano registrado. |
| `X-Timeout` | `20` | Opcional | Timeout em segundos solicitado ao crawler da Jina. |

#### Request URL Example
```http
GET https://r.jina.ai/https://boards.greenhouse.io/company/jobs/123456 HTTP/1.1
Host: r.jina.ai
Accept: text/plain
```

---

## 2. Response Specifications

### Success Response (`200 OK`)
- **Content-Type**: `text/plain; charset=utf-8` ou `text/markdown`
- **Body**: Texto em formato Markdown contendo o título da vaga, descrição, requisitos e atribuições.

```markdown
Title: Senior Flutter Engineer - TechCorp
URL Source: https://boards.greenhouse.io/company/jobs/123456

Markdown Content:
# Senior Flutter Engineer

TechCorp is looking for a Senior Flutter Engineer to lead mobile initiatives.

## Responsibilities
- Architect high-performance mobile apps
- Implement BLoC/Cubit state management

## Requirements
- 4+ years Dart & Flutter experience
- Solid understanding of REST APIs and Clean Architecture
```

### Error Responses

#### `400 Bad Request`
- URL fornecida é inválida ou inacessível.
- **Tratamento**: Lançar `JobMarkdownInvalidUrlFailure`.

#### `429 Too Many Requests`
- Limite de taxa excedido na API pública do Jina AI.
- **Tratamento**: Lançar `JobMarkdownRateLimitFailure` com instrução ao usuário para aguardar alguns instantes ou fornecer chave de API.

#### `500 / 502 / 504 Gateway / Server Error`
- O leitor da Jina não conseguiu alcançar o servidor da vaga ou o site bloqueou o acesso do crawler.
- **Tratamento**: Lançar `JobMarkdownNetworkFailure` informando que o site da vaga está temporariamente inacessível para leitura automatizada.
