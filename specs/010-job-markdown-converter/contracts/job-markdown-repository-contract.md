# Domain Interface Contract: `IJobMarkdownRepository`

**Layer**: Domain (`lib/features/jobs/domain/repositories/job_markdown_repository.dart`)  

---

## 1. Abstract Contract

```dart
import '../models/job_markdown_content.dart';

/// Contrato para o serviço/repositório de conversão de vagas em Markdown via Jina AI.
abstract class IJobMarkdownRepository {
  /// Converte a página web apontada por [jobUrl] para Markdown estruturado.
  ///
  /// Lança [JobMarkdownFailure] e suas subclasses em caso de erro de rede,
  /// URL inválida ou recusa pelo serviço.
  Future<JobMarkdownContent> convertJobToMarkdown({
    required String jobId,
    required String jobUrl,
    String? apiKey,
  });

  /// Copia o [markdown] fornecido diretamente para a área de transferência do sistema.
  Future<void> copyToClipboard(String markdown);
}
```

---

## 2. Remote Data Source Contract

**Layer**: Data (`lib/features/jobs/data/datasources/job_markdown_remote_datasource.dart`)

```dart
/// Contrato do DataSource remoto que realiza as chamadas HTTP para o Jina Reader.
abstract class IJobMarkdownRemoteDataSource {
  /// Executa chamada HTTP GET para https://r.jina.ai/{jobUrl} com timeout de 20s.
  Future<String> fetchMarkdownFromUrl({
    required String jobUrl,
    String? apiKey,
  });
}
```
