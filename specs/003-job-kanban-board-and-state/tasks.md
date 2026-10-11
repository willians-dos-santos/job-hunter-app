# Tasks: 003 - Gestão de Estado & Quadro Kanban de Vagas (`features/jobs`)

**Branch**: `003-job-kanban-board-and-state`  
**Plan**: [plan.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/003-job-kanban-board-and-state/plan.md)  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/003-job-kanban-board-and-state/spec.md)  

## Phase 1: State Management (JobsCubit & JobsState)
- [x] T01: Refinar `JobsState` com campos de lista ativa, filtro de busca e suporte completo a comparabilidade em `lib/features/jobs/presentation/cubit/jobs_state.dart`
- [x] T02: Implementar métodos `loadJobs()`, `moveJobStatus()` (com otimismo e rollback), `archiveJob()` e `filterJobs()` em `lib/features/jobs/presentation/cubit/jobs_cubit.dart`
- [x] T03: Expandir testes unitários do `JobsCubit` para cobrir carregamento, rollback em erro de movimentação, arquivamento e filtragem em `test/features/jobs/presentation/cubit/jobs_cubit_test.dart`

## Phase 2: UI Components (JobCard, KanbanColumn, Skeleton & Error)
- [x] T04: Implementar `JobCard` com badges visuais, tags e menu de ações em `lib/features/jobs/presentation/widgets/job_card.dart`
- [x] T05: Implementar `KanbanColumn` com cabeçalho semântico, contador de cards, indicador de cor e empty state elegante em `lib/features/jobs/presentation/widgets/kanban_column.dart`
- [x] T06: Implementar `KanbanLoadingSkeleton` e `KanbanErrorView` em `lib/features/jobs/presentation/widgets/`
- [x] T07: Implementar `JobsKanbanPage` responsivo (mobile com scroll horizontal e Desktop/Web fluido) com barra de busca em `lib/features/jobs/presentation/pages/jobs_kanban_page.dart`
- [x] T08: Integrar acesso/navegação ao quadro Kanban no app (`lib/main.dart`) preservando retrocompatibilidade

## Phase 3: Widget Tests & Quality Verification
- [x] T09: Criar widget tests para `JobCard` em `test/features/jobs/presentation/widgets/job_card_test.dart`
- [x] T10: Criar widget tests para as colunas do Kanban em `test/features/jobs/presentation/widgets/kanban_column_test.dart`
- [x] T11: Criar widget tests para `JobsKanbanPage` em `test/features/jobs/presentation/pages/jobs_kanban_page_test.dart`
- [x] T12: Executar `flutter test` garantindo 100% de sucesso (98 testes aprovados)
- [x] T13: Executar `flutter analyze` garantindo 0 erros e 0 warnings
