# Implementation Plan: 003 - Gestão de Estado & Quadro Kanban de Vagas (`features/jobs`)

**Branch**: `003-job-kanban-board-and-state`  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/003-job-kanban-board-and-state/spec.md)  
**Status**: In Progress  

## Architecture Overview

A funcionalidade `jobs` ganha sua camada completa de apresentação reativa:
- **`lib/features/jobs/presentation/cubit/jobs_state.dart`**: Estrutura robusta dos estados `JobsInitial`, `JobsLoading`, `JobsLoaded` e `JobsError`, com suporte a listagem ativa, termo de pesquisa e rollback.
- **`lib/features/jobs/presentation/cubit/jobs_cubit.dart`**: Gerência de estado via BLoC/Cubit com orquestração do `IJobRepository` / `JobsRepository`:
  - `loadJobs()`: Carrega e emite vagas ativas (não arquivadas).
  - `moveJobStatus({required String jobId, required String newStatus})`: Atualização otimista imediata com rollback e notificação em caso de falha.
  - `archiveJob(String jobId)`: Remoção da visualização ativa com persistência remota e rollback em erro.
  - `filterJobs(String? query)`: Filtro textual em memória preservando as vagas base.
- **`lib/features/jobs/presentation/widgets/job_card.dart`**: Card de vaga de alta fidelidade visual (Slate 800, bordas Slate 700) com badges semânticas, tags, e menu contextual de ações (Mover status, Arquivar, Abrir link externo).
- **`lib/features/jobs/presentation/widgets/kanban_column.dart`**: Coluna do funil com cabeçalho contendo indicador colorido (`KanbanStatusColors`), badge com contagem de cards, scroll vertical independente e empty state estilizado.
- **`lib/features/jobs/presentation/widgets/kanban_loading_skeleton.dart`**: Skeletons elegantes no tema escuro Slate simulando as colunas e cards durante o carregamento.
- **`lib/features/jobs/presentation/widgets/kanban_error_view.dart`**: Exibição amigável de erro com botão de Retry.
- **`lib/features/jobs/presentation/pages/jobs_kanban_page.dart`**: Tela completa do quadro Kanban com barra superior de pesquisa e ações, layout responsivo adaptável a mobile (rolagem horizontal) e telas largas (Desktop/Web).
- Integração e rota/acesso no app principal (`lib/main.dart`).

## Testing Strategy
- Testes unitários para `JobsCubit`:
  - Transições `JobsInitial` -> `JobsLoading` -> `JobsLoaded`.
  - Falha em `loadJobs()` emitindo `JobsError`.
  - Atualização otimista e rollback em falha de `moveJobStatus`.
  - Remoção e persistência em `archiveJob`.
  - Filtragem dinâmica em `filterJobs`.
- Widget Tests:
  - Renderização de `JobCard` (título, empresa, badges, menu de ações).
  - Estrutura de `KanbanColumn` (cabeçalho, contador, cores do tema, empty state).
  - Exibição do `JobKanbanPage` em estados Loading, Error e Loaded.
- Verificação final:
  - `flutter test` com 100% de aprovação.
  - `flutter analyze` com 0 erros e 0 warnings.
