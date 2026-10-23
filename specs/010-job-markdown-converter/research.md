# Phase 0: Research & Technical Analysis

**Feature**: `010-job-markdown-converter`  
**Date**: 2026-10-22  
**Status**: Completed  

---

## 1. Jina AI Reader API Integration

### Decision
Utilizar o endpoint público canônico do **Jina AI Reader** via requisição HTTP GET:
`https://r.jina.ai/{target_url}`

Com cabeçalhos padronizados:
- `Accept: text/plain`
- `User-Agent: JobHunterApp/1.0`
- `Authorization: Bearer {JINA_API_KEY}` (enviado condicionalmente se configurado em `.env`).

### Rationale
- O Jina AI Reader é um serviço de proxy web especializado para modelos de linguagem (LLMs) que processa páginas modernas (incluindo SPAs com React/Vue como Lever, Greenhouse, Gupy e Workday).
- Executa a renderização no lado do servidor, remove automaticamente menus, rodapés, anúncios e banners de consentimento de cookies, entregando apenas o conteúdo semântico essencial no formato Markdown.
- Oferece acesso gratuito sem obrigatoriedade de API key para volume moderado de consultas individuais.
- Fornece suporte opcional a `JINA_API_KEY` para rate limits maiores e maior prioridade de requisição.

### Alternatives Considered
1. **Parsing HTML Local com Regex ou html2md**:
   - *Rejeitado*: Plataformas modernas de vagas (Greenhouse, Lever, Gupy) renderizam a descrição dinamicamente via JavaScript. Um parser local em Dart receberia apenas o HTML esqueleto inicial sem o texto da vaga.
2. **WebView Invisível / Headless Browser Local**:
   - *Rejeitado*: Extremamente pesado para execução em dispositivos móveis e desktop Linux, consome memória excessiva e exige manutenção complexa de scripts de injeção.
3. **Endpoint Supabase Edge Function intermediário**:
   - *Rejeitado para v1*: Adiciona camada de infraestrutura e dependência de deploy sem necessidade imediata, já que a chamada direta do Flutter para o Jina AI Reader funciona de forma autônoma e eficiente.

---

## 2. Cliente HTTP e Mockabilidade

### Decision
Adicionar a dependência explícita `http: ^1.6.0` em `pubspec.yaml` (já presente transitivamente no projeto) e injetar `http.Client` no `JobMarkdownRemoteDataSource`.

### Rationale
- Permite configurar timeouts explícitos (`timeout(const Duration(seconds: 20))`).
- Permite mocking determinístico e isolado em testes unitários via `mocktail` (`when(() => mockHttpClient.get(...)).thenAnswer(...)`).
- Compatível nativamente com Android, Web e Desktop Linux sem requisições adicionais de permissões nativas além de acesso à internet.

### Alternatives Considered
1. **`dart:io` HttpClient diretamente**:
   - *Rejeitado*: Não é compatível com Flutter Web (`dart:io` não compila na web).
2. **`Dio`**:
   - *Rejeitado*: Desnecessariamente pesado para a necessidade atual de uma chamada GET simples com timeout e headers.

---

## 3. Acesso à Área de Transferência (Clipboard)

### Decision
Utilizar o serviço nativo do Flutter `package:flutter/services.dart`:
```dart
await Clipboard.setData(ClipboardData(text: markdown));
```

### Rationale
- Já faz parte do SDK do Flutter (`flutter/services.dart`).
- Suporte garantido em todas as plataformas alvo (Android, Linux, Web).
- Execução assíncrona com tratamento seguro de exceções de sistema.

---

## 4. Gestão de Estado da Conversão (BLoC / Cubit)

### Decision
Criar o `JobMarkdownCubit` com estados imutáveis (`JobMarkdownInitial`, `JobMarkdownLoading`, `JobMarkdownSuccess`, `JobMarkdownFailure`) estendendo `Equatable`, em conformidade estrita com o **Princípio I da Constituição**.

### Rationale
- Mantém o `JobsCubit` focado na governança do pipeline Kanban e persistência de anotações no Supabase.
- Isola o ciclo de vida da conversão (loading, sucesso, erro e cópia), facilitando testes unitários isolados e testes de widget no modal.
- Permite reutilizar o `JobMarkdownCubit` tanto no `JobDetailsModal` quanto em futuros atalhos (ex: cards do Kanban ou menus de contexto).

---

## 5. Resumo de Diretrizes Arquiteturais

| Camada | Componente | Responsabilidade |
|---|---|---|
| **Domain** | `JobMarkdownContent` | Entidade de valor com o conteúdo Markdown e metadados. |
| **Domain** | `IJobMarkdownRepository` | Contrato abstrato da operação de conversão. |
| **Data** | `JobMarkdownRemoteDataSource` | Comunicação HTTP com `https://r.jina.ai/{url}` e headers. |
| **Data** | `JobMarkdownRepository` | Implementação do contrato de domínio utilizando o DataSource. |
| **Presentation** | `JobMarkdownCubit` / `JobMarkdownState` | Gerenciamento de estado de conversão, cópia para o Clipboard e emissão de eventos. |
| **Presentation** | `JobDetailsModal` | Botão visual "Copiar em Markdown", spinner de loading e acionamento de SnackBar. |
