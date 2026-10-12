# Implementation Plan: 007 - Gestão e Recuperação de Vagas Arquivadas (`features/jobs`)

**Branch**: `007-archived-jobs-management`  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/007-archived-jobs-management/spec.md)  
**Status**: Completed  

## Architecture Overview

A funcionalidade viabiliza a tela dedicada para auditoria e recuperação de vagas descartadas (`is_archived = true`):
1. **Data Layer (`IJobRemoteDataSource`, `JobRemoteDataSource`)**:
   - Adicionar método `getArchivedJobs({int limit = 50, int offset = 0, String? userId})` que filtra `is_archived = true` e `user_id = effectiveUserId` na view `v_user_jobs`.
   - Adicionar parâmetro opcional `bool? isArchived` no método existente `getJobs` para máxima flexibilidade e compatibilidade retroativa.
2. **Domain Layer (`IJobRepository`, `JobRepository`)**:
   - Expor `getArchivedJobs` na interface `IJobRepository` e implementação `JobRepository`.
   - Reutilizar `toggleJobArchived(jobId: jobId, isArchived: false)` (com `onConflict: 'user_id,job_id'`) já testado.
3. **State Management (`ArchivedJobsCubit`, `ArchivedJobsState`)**:
   - Criar `ArchivedJobsState` com variantes: `ArchivedJobsInitial`, `ArchivedJobsLoading`, `ArchivedJobsLoaded(List<JobItem> jobs, {String? errorMessage, String? successMessage})`, e `ArchivedJobsError(String message)`.
   - Criar `ArchivedJobsCubit` gerenciando busca inicial (`loadArchivedJobs`), restauração otimista com rollback (`restoreJob`), e limpeza de mensagens de feedback.
   - Adicionar getter `repository` em `JobsCubit` para facilitar injeção de dependência na navegação.
4. **Presentation Layer (`ArchivedJobsScreen`, `JobsKanbanPage`)**:
   - Criar `ArchivedJobsScreen` (com alias `ArchivedJobsPage`) em `lib/features/jobs/presentation/pages/archived_jobs_screen.dart`:
     - `AppBar` com badge "ARQUIVO" / "ARCHIVED" e botão de atualizar.
     - Indicador de loading (compatível com o tema Slate).
     - Componente de estado vazio estilizado caso não haja vagas arquivadas.
     - Componente de erro com botão "Tentar novamente".
     - Lista de cards de vagas arquivadas, com ação de "Restaurar" (`Icons.unarchive_rounded`) e toque no card para abrir `JobDetailsModal`.
   - Atualizar `JobsKanbanPage`:
     - Adicionar botão de arquivo no `AppBar` com tooltip "Vagas arquivadas" (`Icons.archive_outlined`).
     - Ao retornar da navegação (`await Navigator.push(...)`), invocar `cubit.loadJobs()` para sincronizar o Kanban.
5. **Testing & Quality Assurance**:
   - Testes unitários para `JobRemoteDataSource` e `JobRepository` cobrindo `getArchivedJobs`.
   - Testes unitários para `ArchivedJobsCubit` cobrindo loading, loaded, empty, error, restore com sucesso e rollback em erro.
   - Testes de widgets para `ArchivedJobsScreen` cobrindo renderização, loading, empty state, erro com retry, ação de restaurar e abertura do modal de detalhes.
   - Testes de widgets na `JobsKanbanPage` validando navegação para `ArchivedJobsScreen` e sincronização pós-retorno.
   - Validação com `flutter test` e `flutter analyze` garantindo 0 erros e 0 alertas.

## Testing Strategy
- **Data & Repository Unit Tests**:
  - `getArchivedJobs` filtra `is_archived = true` e usuário autenticado.
- **Cubit Unit Tests**:
  - `ArchivedJobsCubit.loadArchivedJobs` emite `[ArchivedJobsLoading, ArchivedJobsLoaded]`.
  - `ArchivedJobsCubit.loadArchivedJobs` emite `[ArchivedJobsLoading, ArchivedJobsError]` em falha.
  - `ArchivedJobsCubit.restoreJob` remove item otimisticamente e emite `successMessage`.
  - `ArchivedJobsCubit.restoreJob` reverte lista e emite `errorMessage` em falha do repositório.
- **Widget Tests**:
  - `ArchivedJobsScreen` exibe loading ao iniciar.
  - `ArchivedJobsScreen` exibe estado vazio quando não há vagas.
  - `ArchivedJobsScreen` exibe lista de cartões com botão "Restaurar".
  - Toque no botão "Restaurar" dispara `cubit.restoreJob`.
  - Toque no cartão abre `JobDetailsModal`.
  - `JobsKanbanPage` possui botão no AppBar que navega para `ArchivedJobsScreen`.
