# Phase 1: Data Model & State Specifications

**Feature**: `010-job-markdown-converter`  
**Date**: 2026-10-22  
**Status**: Ready  

---

## 1. Domain Entities & Value Objects

### `JobMarkdownContent`
Objeto de valor imutável representando a resposta convertida da página externa de uma vaga.

```dart
class JobMarkdownContent extends Equatable {
  const JobMarkdownContent({
    required this.jobId,
    required this.jobUrl,
    required this.markdown,
    required this.convertedAt,
  });

  /// Identificador único da vaga associada (JobItem.jobId)
  final String jobId;

  /// URL canônica original enviada para conversão
  final String jobUrl;

  /// Conteúdo integral da vaga formatado em Markdown pelo Jina AI Reader
  final String markdown;

  /// Timestamp da conversão
  final DateTime convertedAt;

  @override
  List<Object?> get props => [jobId, jobUrl, markdown, convertedAt];
}
```

#### Validation Rules:
- `jobId`: Não pode ser vazio.
- `jobUrl`: Deve ser uma URL HTTP/HTTPS válida.
- `markdown`: Não pode ser nulo ou vazio após a conversão. Se o Jina retornar vazio, o DataSource deve lançar `JobMarkdownEmptyFailure`.

---

## 2. Presentation State Models (`JobMarkdownState`)

Hierarquia de estados imutáveis do Cubit baseada em `Equatable`:

```dart
sealed class JobMarkdownState extends Equatable {
  const JobMarkdownState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial ou ocioso
final class JobMarkdownInitial extends JobMarkdownState {
  const JobMarkdownInitial();
}

/// Conversão em andamento via rede
final class JobMarkdownLoading extends JobMarkdownState {
  const JobMarkdownLoading({required this.jobId});

  final String jobId;

  @override
  List<Object?> get props => [jobId];
}

/// Conversão e cópia concluídas com êxito
final class JobMarkdownSuccess extends JobMarkdownState {
  const JobMarkdownSuccess({
    required this.content,
    required this.copiedToClipboard,
    this.message = 'Markdown da vaga copiado com sucesso!',
  });

  final JobMarkdownContent content;
  final bool copiedToClipboard;
  final String message;

  @override
  List<Object?> get props => [content, copiedToClipboard, message];
}

/// Falha na conversão ou na cópia
final class JobMarkdownFailure extends JobMarkdownState {
  const JobMarkdownFailure({
    required this.jobId,
    required this.errorMessage,
  });

  final String jobId;
  final String errorMessage;

  @override
  List<Object?> get props => [jobId, errorMessage];
}
```

---

## 3. Exceptions & Failures

Encapsuladas sob o padrão de falhas do projeto (`core/errors/failures.dart` ou `features/jobs/domain/errors/`):

- `JobMarkdownFailure` (base para falhas de domínio)
- `JobMarkdownNetworkFailure` (problemas de conexão/timeout HTTP)
- `JobMarkdownInvalidUrlFailure` (URL nula ou malformada)
- `JobMarkdownEmptyFailure` (página retornou vazia ou bloqueada por bot check)
- `JobMarkdownRateLimitFailure` (HTTP 429 da Jina AI)
