# Tasks: 004 - Ações Rápidas, Transições de Estado e Mutações no Kanban (`features/jobs`)

**Branch**: `004-job-card-actions-and-transitions`  
**Plan**: [plan.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/004-job-card-actions-and-transitions/plan.md)  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/004-job-card-actions-and-transitions/spec.md)  

## Phase 1: State Management Updates
- [x] T01: Adicionar suporte a `successMessage` em `JobsLoaded` e método `clearSuccessMessage()` em `lib/features/jobs/presentation/cubit/jobs_state.dart` e `jobs_cubit.dart`
- [x] T02: Atualizar `archiveJob` em `JobsCubit` para emitir `successMessage: 'Vaga arquivada com sucesso.'` após confirmação do repositório
- [x] T03: Atualizar e adicionar testes unitários para o `JobsCubit` em `test/features/jobs/presentation/cubit/jobs_cubit_test.dart`

## Phase 2: UI Presentation & Feedback
- [x] T04: Assegurar que `JobCard` liste todas as opções de transição de status no menu contextual e a ação "Arquivar vaga" em `lib/features/jobs/presentation/widgets/job_card.dart`
- [x] T05: Atualizar `JobsKanbanPage` para escutar `successMessage` e exibir SnackBar de confirmação ao arquivar vaga em `lib/features/jobs/presentation/pages/jobs_kanban_page.dart`
- [x] T06: Expandir widget tests em `test/features/jobs/presentation/widgets/job_card_test.dart` e `test/features/jobs/presentation/pages/jobs_kanban_page_test.dart`

## Phase 3: Validation & Quality Gate
- [x] T07: Executar `flutter test` garantindo 100% de sucesso
- [x] T08: Executar `flutter analyze` garantindo 0 erros e 0 alertas
