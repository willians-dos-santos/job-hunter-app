# Tasks: 010 - Conversão da Página da Vaga para Markdown e Cópia via Jina AI (`features/jobs`)

**Branch**: `010-job-markdown-converter`  
**Plan**: [plan.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/010-job-markdown-converter/plan.md)  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/010-job-markdown-converter/spec.md)  

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Inicialização de dependências e configuração básica para requisições HTTP

- [x] T001 [P] Adicionar a dependência explícita `http: ^1.6.0` na seção `dependencies` de `pubspec.yaml`
- [x] T002 Executar `flutter pub get` a partir da raiz do projeto para sincronizar os pacotes

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Modelos de domínio, contratos abstratos e hierarquia de falhas que bloqueiam a implementação das histórias de usuário

**⚠️ CRITICAL**: Nenhuma tarefa das histórias de usuário pode iniciar antes da conclusão desta fase.

- [x] T003 [P] Criar o Value Object imutável `JobMarkdownContent` com campos `jobId`, `jobUrl`, `markdown` e `convertedAt` em `lib/features/jobs/domain/models/job_markdown_content.dart`
- [x] T004 [P] Criar as interfaces abstratas `IJobMarkdownRepository` e `IJobMarkdownRemoteDataSource` em `lib/features/jobs/domain/repositories/job_markdown_repository.dart`
- [x] T005 [P] Implementar subclasses de falha `JobMarkdownFailure`, `JobMarkdownNetworkFailure`, `JobMarkdownInvalidUrlFailure`, `JobMarkdownEmptyFailure` e `JobMarkdownRateLimitFailure` em `lib/core/errors/failures.dart`
- [x] T006 [P] Criar testes unitários para validação e integridade do modelo `JobMarkdownContent` em `test/features/jobs/domain/models/job_markdown_content_test.dart`

**Checkpoint**: Fundação pronta - implementação das histórias de usuário desbloqueada.

---

## Phase 3: User Story 1 - Conversão da Vaga para Markdown e Cópia (Priority: P1) 🎯 MVP

**Goal**: Permitir que o usuário converta a página da vaga em Markdown pelo leitor da Jina AI e copie diretamente para o Clipboard através do modal de detalhes.

**Independent Test**: Abrir o modal de detalhes de uma vaga com URL válida, disparar a ação de conversão, validar a chamada ao leitor Jina AI, confirmar a gravação na área de transferência (`Clipboard`) e verificar a emissão do estado de sucesso com SnackBar.

### Tests for User Story 1 ⚠️

- [x] T007 [P] [US1] Criar testes unitários para `JobMarkdownRemoteDataSource` com `mocktail` cobrindo chamada HTTP GET e parsing em `test/features/jobs/data/datasources/job_markdown_remote_datasource_test.dart`
- [x] T008 [P] [US1] Criar testes unitários para `JobMarkdownRepositoryImpl` cobrindo conversão e chamada a `Clipboard.setData` em `test/features/jobs/data/repositories/job_markdown_repository_impl_test.dart`
- [x] T009 [P] [US1] Criar testes unitários para `JobMarkdownCubit` cobrindo o fluxo de emissão `[JobMarkdownLoading, JobMarkdownSuccess]` em `test/features/jobs/presentation/cubit/job_markdown_cubit_test.dart`

### Implementation for User Story 1

- [x] T010 [US1] Implementar `JobMarkdownRemoteDataSource` executando GET para `https://r.jina.ai/{sanitizedUrl}` com injeção de `http.Client` e suporte opcional a `dotenv.env['JINA_API_KEY']` em `lib/features/jobs/data/datasources/job_markdown_remote_datasource.dart`
- [x] T011 [US1] Implementar `JobMarkdownRepositoryImpl` implementando `IJobMarkdownRepository` e gravando o texto retornado no `Clipboard` em `lib/features/jobs/data/repositories/job_markdown_repository_impl.dart`
- [x] T012 [US1] Implementar `JobMarkdownCubit` e os estados imutáveis `JobMarkdownState` em `lib/features/jobs/presentation/cubit/job_markdown_cubit.dart` e `lib/features/jobs/presentation/cubit/job_markdown_state.dart`
- [x] T013 [US1] Adicionar o botão de ação "Copiar em Markdown" e conectar o disparo ao `JobMarkdownCubit` em `lib/features/jobs/presentation/widgets/job_details_modal.dart`

**Checkpoint**: User Story 1 (MVP) completamente funcional e testável de forma isolada.

---

## Phase 4: User Story 2 - Feedback de Carregamento e Tratamento Resiliente de Falhas (Priority: P1)

**Goal**: Fornecer indicador de progresso (spinner) no botão e desativação temporária durante a requisição, desabilitar o botão quando a vaga não tiver URL e exibir mensagens informativas em caso de erro (timeout, offline ou bloqueio) sem travar o app.

**Independent Test**: Executar widget tests em `JobDetailsModal` simulando cenários de lentidão na rede (verificando spinner), falhas de conexão/HTTP (verificando SnackBar de erro `AppColors.kanbanRejected`) e vaga sem URL (verificando botão desabilitado).

### Tests for User Story 2 ⚠️

- [x] T014 [P] [US2] Adicionar testes unitários no `JobMarkdownCubit` para timeout de 20s, URL vazia e emissão de `JobMarkdownFailure` em `test/features/jobs/presentation/cubit/job_markdown_cubit_test.dart`
- [x] T015 [P] [US2] Criar widget tests para `JobDetailsModal` cobrindo o spinner de loading, desabilitação com URL ausente e exibição de SnackBars em `test/features/jobs/presentation/widgets/job_details_modal_test.dart`

### Implementation for User Story 2

- [x] T016 [US2] Configurar timeout de 20 segundos e tratamento de status codes de erro (4xx, 5xx, corpo vazio) no `JobMarkdownRemoteDataSource` em `lib/features/jobs/data/datasources/job_markdown_remote_datasource.dart`
- [x] T017 [US2] Atualizar o botão de conversão no `JobDetailsModal` para renderizar `CircularProgressIndicator` quando em carregamento e desabilitar quando `job.jobUrl` estiver vazia em `lib/features/jobs/presentation/widgets/job_details_modal.dart`
- [x] T018 [US2] Implementar exibição de SnackBar flutuante para confirmação de cópia (estilo escuro Slate) e aviso de falha (com cor `AppColors.kanbanRejected`) em `lib/features/jobs/presentation/widgets/job_details_modal.dart`

**Checkpoint**: User Story 1 e 2 integradas com tratamento resiliente de falhas e feedback visual completo.

---

## Phase 5: User Story 3 - Visualização / Diálogo de Leitura do Markdown (Priority: P2)

**Goal**: Disponibilizar um diálogo modal responsivo com rolagem para leitura do conteúdo convertido em Markdown diretamente no aplicativo, com atalho para copiar novamente o texto.

**Independent Test**: Acionar a abertura da pré-visualização do Markdown e validar que o conteúdo estruturado é renderizado com barra de rolagem e botão funcional de cópia.

### Tests for User Story 3 ⚠️

- [x] T019 [P] [US3] Criar widget tests para `JobMarkdownPreviewDialog` cobrindo a renderização do texto, scroll e botão de cópia em `test/features/jobs/presentation/widgets/job_markdown_preview_dialog_test.dart`

### Implementation for User Story 3

- [x] T020 [US3] Criar o widget `JobMarkdownPreviewDialog` com layout responsivo Slate, `SingleChildScrollView`, exibição monoespaçada/Markdown e botão "Copiar Novamente" em `lib/features/jobs/presentation/widgets/job_markdown_preview_dialog.dart`
- [x] T021 [US3] Adicionar ação/opção no `JobDetailsModal` para abrir o `JobMarkdownPreviewDialog` caso o usuário queira visualizar o texto convertido em `lib/features/jobs/presentation/widgets/job_details_modal.dart`

**Checkpoint**: Todas as 3 histórias de usuário concluídas e operantes de forma independente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validações de integridade, documentação de ambiente e garantia de qualidade total

- [x] T022 [P] Atualizar `.env.example` documentando a variável opcional `JINA_API_KEY` em `.env.example`
- [x] T023 Executar `flutter analyze` em todo o repositório garantindo 0 erros e 0 alertas
- [x] T024 Executar `flutter test` executando 100% da suíte de testes garantindo zero falhas ou regressões
- [x] T025 Executar validação ponta a ponta dos cenários descritos em `specs/010-job-markdown-converter/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências - inicia imediatamente.
- **Foundational (Phase 2)**: Depende da conclusão do Setup - BLOQUEIA todas as histórias de usuário.
- **User Story 1 (Phase 3)**: Depende da Phase 2 (Foundational). Representa o MVP.
- **User Story 2 (Phase 4)**: Depende da Phase 3 (US1) para aprimorar resiliência, loading e feedback de erro.
- **User Story 3 (Phase 5)**: Depende da Phase 3 (US1) para exibir o Markdown gerado.
- **Polish (Phase 6)**: Depende da conclusão das histórias de usuário desejadas.

### User Story Dependencies

- **User Story 1 (P1)**: Autossuficiente após Foundational. Não depende de US2 ou US3.
- **User Story 2 (P1)**: Constrói sobre os componentes de US1 (`JobMarkdownRemoteDataSource` e `JobDetailsModal`).
- **User Story 3 (P2)**: Constrói sobre os dados de `JobMarkdownContent` gerados em US1.

### Within Each User Story

1. Testes unitários/widget escritos primeiro (devem falhar antes da implementação).
2. Modelos e DataSources implementados antes dos Repositórios.
3. Repositório implementado antes do Cubit.
4. Cubit implementado antes da integração com os Widgets visuais.
5. Validação de independência da história antes de avançar.

---

## Parallel Example: User Story 1

```bash
# Executar a criação de testes da história 1 em paralelo:
Task: "T007 [P] [US1] Criar testes unitários para JobMarkdownRemoteDataSource em test/features/jobs/data/datasources/job_markdown_remote_datasource_test.dart"
Task: "T008 [P] [US1] Criar testes unitários para JobMarkdownRepositoryImpl em test/features/jobs/data/repositories/job_markdown_repository_impl_test.dart"
Task: "T009 [P] [US1] Criar testes unitários para JobMarkdownCubit em test/features/jobs/presentation/cubit/job_markdown_cubit_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Concluir **Phase 1** (Setup de dependência `http`).
2. Concluir **Phase 2** (Foundational: modelos, interfaces e falhas).
3. Concluir **Phase 3** (User Story 1: conversão e cópia direta no modal).
4. **Validar MVP**: Executar `flutter test test/features/jobs/presentation/cubit/job_markdown_cubit_test.dart` e validar a cópia de Markdown.

### Incremental Delivery

1. Setup + Foundation prontos → Estrutura sólida.
2. Adicionar User Story 1 → Entrega MVP de valor imediato (converter e copiar).
3. Adicionar User Story 2 → Proteção robusta contra timeouts, erros de conexão e múltiplos cliques.
4. Adicionar User Story 3 → Visualizador de leitura interna do Markdown.
5. Polish → Análise estática impecável e suíte completa verde.
