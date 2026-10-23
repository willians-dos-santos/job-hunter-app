# Implementation Plan: 010 - Conversão da Página da Vaga para Markdown e Cópia via Jina AI (`features/jobs`)

**Branch**: `010-job-markdown-converter` | **Date**: 2026-10-22 | **Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/010-job-markdown-converter/spec.md)  
**Input**: Feature specification from `/specs/010-job-markdown-converter/spec.md`

---

## Summary

Implementar a funcionalidade de conversão da página externa de uma oportunidade de emprego (`job_url`) em texto estruturado no formato Markdown utilizando o leitor público da **Jina AI** (`https://r.jina.ai/<url>`), com ação direta de cópia para a área de transferência do dispositivo no modal de detalhes da vaga ([`JobDetailsModal`](file:///home/willians/workspace/flutter/job_hunter_app/lib/features/jobs/presentation/widgets/job_details_modal.dart)). A arquitetura adota Clean Architecture desacoplada, gerenciamento de estado dedicado via `JobMarkdownCubit`, resiliência com timeout e feedback visual alinhado ao tema escuro Slate.

---

## Technical Context

**Language/Version**: Dart SDK ^3.9.2 (Flutter 3.x)  
**Primary Dependencies**: `flutter_bloc: ^9.1.1`, `equatable: ^3.0.0`, `http: ^1.6.0`, `flutter/services.dart` (`Clipboard`)  
**Storage**: N/A (conversão sob demanda e persistência local temporária na área de transferência)  
**Testing**: `flutter_test`, `mocktail: ^1.0.5`  
**Target Platform**: Android, Linux Desktop, Web  
**Project Type**: Mobile & Desktop Flutter Application  
**Performance Goals**: Latência de cópia pós-requisição < 250ms; tempo de resposta vinculado à API Jina AI com timeout de 20s  
**Constraints**: 0 erros/alertas em `flutter analyze`, tema estrito Slate 900/800/700, layout responsivo livre de overflows  
**Scale/Scope**: Módulo `features/jobs`, interagindo com o modal de detalhes e endpoints externos de vagas  

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Princípio I (Clean Architecture & Modular Presentation)**: A camada de apresentação utiliza estritamente Cubit imutável (`JobMarkdownCubit` com `Equatable`). As regras de negócio ficam encapsuladas na camada de domínio (`IJobMarkdownRepository` e `JobMarkdownContent`). Acesso externo HTTP isolado no `JobMarkdownRemoteDataSource`.
- [x] **Princípio II (Data Contracts & Database-First)**: Nenhuma alteração de esquema no Supabase é requerida. O campo canônico `job_url` existente no contrato `JobItem` é consumido como fonte de dados.
- [x] **Princípio III (Quality Gates & Test-First)**: Planejamento inclui suíte completa de testes unitários para Cubit, Repository e DataSource com mocks (`mocktail`), além de testes de widget para o `JobDetailsModal`. Critério de 0 erros em `flutter analyze` e `flutter test`.
- [x] **Princípio IV (Responsive Tablet-First & Slate Theme Consistency)**: A interface preserva a paleta Slate escuro (`Slate 900`, `Slate 800`, `Slate 700`, `terminalCyan`), com layout flexível e botões responsivos.

---

## Project Structure

### Documentation (this feature)

```text
specs/010-job-markdown-converter/
├── spec.md                  # Especificação funcional e requisitos
├── plan.md                  # Este plano de implementação arquitetural
├── research.md              # Pesquisa técnica e decisões de integração
├── data-model.md            # Entidades de domínio e modelos de estado
├── quickstart.md            # Guia de validação e comandos de teste
├── contracts/               # Contratos de interfaces
│   ├── jina-reader-api.md   # Contrato da API externa Jina Reader
│   └── job-markdown-repository-contract.md # Contrato Dart do repositório
└── checklists/
    └── requirements.md      # Validação de qualidade da especificação
```

### Source Code (repository root)

```text
pubspec.yaml                 # Adição da dependência explícita http: ^1.6.0

lib/
└── features/
    └── jobs/
        ├── domain/
        │   ├── models/
        │   │   └── job_markdown_content.dart   # Value Object com conteúdo e metadados
        │   └── repositories/
        │       └── job_markdown_repository.dart# Contrato abstrato IJobMarkdownRepository
        ├── data/
        │   ├── datasources/
        │   │   └── job_markdown_remote_datasource.dart # Chamada HTTP para https://r.jina.ai/{url}
        │   └── repositories/
        │       └── job_markdown_repository_impl.dart   # Implementação do repositório de conversão
        └── presentation/
            ├── cubit/
            │   ├── job_markdown_cubit.dart     # Gerenciamento de estado da conversão e cópia
            │   └── job_markdown_state.dart     # Estados imutáveis (Initial, Loading, Success, Failure)
            └── widgets/
                └── job_details_modal.dart      # Botão "Copiar em Markdown", loading spinner e feedback

test/
└── features/
    └── jobs/
        ├── data/
        │   └── datasources/
        │       └── job_markdown_remote_datasource_test.dart # Testes do DataSource com mocktail
        ├── domain/
        │   └── models/
        │       └── job_markdown_content_test.dart           # Teste de integridade do Value Object
        └── presentation/
            ├── cubit/
            │   └── job_markdown_cubit_test.dart             # Testes do Cubit (sucesso, timeout, erro)
            └── widgets/
                └── job_details_modal_test.dart              # Teste de widget cobrindo o botão e estados
```

**Structure Decision**: Adoção estrita da arquitetura Feature-First existente em `lib/features/jobs/`, segregada nas camadas `domain/`, `data/` e `presentation/`.

---

## Architecture Overview

### 1. Camada de Domínio (`domain`)
- **`JobMarkdownContent`**: Entidade imutável encapsulando `jobId`, `jobUrl`, `markdown` e `convertedAt`.
- **`IJobMarkdownRepository`**: Interface com métodos:
  - `Future<JobMarkdownContent> convertJobToMarkdown({required String jobId, required String jobUrl, String? apiKey})`
  - `Future<void> copyToClipboard(String markdown)`

### 2. Camada de Dados (`data`)
- **`JobMarkdownRemoteDataSource`**:
  - Recebe uma instância de `http.Client`.
  - Executa requisição GET para `https://r.jina.ai/{sanitizedUrl}` com timeout de 20 segundos.
  - Injeta cabeçalho `Authorization: Bearer <token>` se configurado em `dotenv.env['JINA_API_KEY']`.
  - Trata status codes (200 = sucesso; 429 = rate limit; outros = falha de rede/servidor) e retorno vazio.
- **`JobMarkdownRepositoryImpl`**:
  - Implementa `IJobMarkdownRepository`.
  - Conecta o `JobMarkdownRemoteDataSource` e invoca `Clipboard.setData(ClipboardData(text: markdown))`.

### 3. Camada de Apresentação (`presentation`)
- **`JobMarkdownCubit`**:
  - Estados: `JobMarkdownInitial`, `JobMarkdownLoading`, `JobMarkdownSuccess`, `JobMarkdownFailure`.
  - Método: `Future<void> convertAndCopyJobMarkdown({required String jobId, required String jobUrl})`.
- **`JobDetailsModal`**:
  - Adiciona o botão OutlinedButton *"Copiar em Markdown"* posicionado abaixo ou adjacente ao botão de link externo.
  - Exibe `CircularProgressIndicator` quando `isConverting` estiver ativo.
  - Bloqueia cliques adicionais durante o carregamento.
  - Exibe SnackBar escuro Slate com mensagem de sucesso ou erro semântico via `AppColors.kanbanRejected`.

---

## Testing Strategy

1. **Testes Unitários de DataSource**:
   - Resposta HTTP 200 com Markdown válido.
   - Resposta HTTP com erro ou corpo vazio.
   - Timeout de requisição após 20 segundos.
   - Envio de token de autorização opcional quando presente no ambiente.
2. **Testes Unitários de Cubit**:
   - Emissão de `[JobMarkdownLoading, JobMarkdownSuccess]` ao converter e copiar com êxito.
   - Emissão de `[JobMarkdownLoading, JobMarkdownFailure]` ao capturar erro de rede ou URL inválida.
3. **Testes de Widgets no `JobDetailsModal`**:
   - Renderização do botão "Copiar em Markdown" quando a vaga possui `job_url`.
   - Botão desabilitado quando a vaga não possui URL.
   - Transição do botão para estado de loading ao ser pressionado.
   - Exibição de SnackBar flutuante de sucesso e erro.
4. **Análise Estática e Regressão**:
   - `flutter analyze` com 0 erros e 0 alertas.
   - `flutter test` executando toda a suíte existente sem regressões.

---

## Complexity Tracking

*Nenhuma violação aos princípios da Constituição foi identificada.*
