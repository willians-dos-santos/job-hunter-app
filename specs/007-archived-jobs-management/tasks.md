# Tasks: 007 - Gestão e Recuperação de Vagas Arquivadas (`features/jobs`)

**Branch**: `007-archived-jobs-management`  
**Plan**: [plan.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/007-archived-jobs-management/plan.md)  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/007-archived-jobs-management/spec.md)  

## Phase 1: Data & Domain Layer
- [x] T01: Adicionar `getArchivedJobs` à interface `IJobRemoteDataSource` e implementar em `JobRemoteDataSource` (`lib/features/jobs/data/datasources/job_remote_datasource.dart`)
- [x] T02: Adicionar `getArchivedJobs` à interface `IJobRepository` e implementar em `JobRepository` (`lib/features/jobs/domain/repositories/job_repository.dart` e `lib/features/jobs/data/repositories/job_repository_impl.dart`)
- [x] T03: Adicionar testes de unidade para `getArchivedJobs` no remote datasource e repositório

## Phase 2: State Management (ArchivedJobsCubit)
- [x] T04: Criar `ArchivedJobsState` com variantes `Initial`, `Loading`, `Loaded` e `Error` (`lib/features/jobs/presentation/cubit/archived_jobs_state.dart`)
- [x] T05: Criar `ArchivedJobsCubit` com métodos `loadArchivedJobs`, `restoreJob`, `clearErrorMessage` e `clearSuccessMessage` (`lib/features/jobs/presentation/cubit/archived_jobs_cubit.dart`)
- [x] T06: Adicionar getter `repository` em `JobsCubit` (`lib/features/jobs/presentation/cubit/jobs_cubit.dart`)
- [x] T07: Implementar suíte de testes unitários para `ArchivedJobsCubit` (`test/features/jobs/presentation/cubit/archived_jobs_cubit_test.dart`)

## Phase 3: Presentation Layer (ArchivedJobsScreen & Navigation)
- [x] T08: Criar a tela `ArchivedJobsScreen` (`lib/features/jobs/presentation/pages/archived_jobs_screen.dart`) com AppBar, tratamento de loading, lista vazia, erro com retry, listagem de cards, botão "Restaurar" e abertura de `JobDetailsModal`
- [x] T09: Adicionar botão de navegação para `ArchivedJobsScreen` no AppBar de `JobsKanbanPage` (`lib/features/jobs/presentation/pages/jobs_kanban_page.dart`) com sincronização do Kanban ao retornar

## Phase 4: Quality & Validation
- [x] T10: Adicionar testes de widgets para `ArchivedJobsScreen` (`test/features/jobs/presentation/pages/archived_jobs_screen_test.dart`)
- [x] T11: Adicionar testes de widgets na `JobsKanbanPage` validando presença do botão e navegação (`test/features/jobs/presentation/pages/jobs_kanban_page_test.dart`)
- [x] T12: Executar `flutter test` garantindo 100% de sucesso
- [x] T13: Executar `flutter analyze` garantindo 0 erros e 0 alertas
