# Tasks: 005 - Detalhes da Vaga, Visualização Completa e Notas Pessoais (`features/jobs`)

**Branch**: `005-job-details-and-notes-modal`  
**Plan**: [plan.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/005-job-details-and-notes-modal/plan.md)  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/005-job-details-and-notes-modal/spec.md)  

## Phase 1: State Management & Domain Model
- [x] T01: Ajustar `JobItem.copyWith` para suportar limpeza/substituição flexível de `notes` em `lib/features/jobs/domain/models/job_item.dart`
- [x] T02: Implementar método `updateJobNotes` com otimismo e rollback em `lib/features/jobs/presentation/cubit/jobs_cubit.dart`
- [x] T03: Adicionar testes unitários para `updateJobNotes` em `test/features/jobs/presentation/cubit/jobs_cubit_test.dart`

## Phase 2: UI Presentation & Modal Component
- [x] T04: Criar `JobDetailsModal` e helper `showJobDetailsModal` em `lib/features/jobs/presentation/widgets/job_details_modal.dart`
- [x] T05: Integrar evento `onTap` no `JobCard` e propagar através de `KanbanColumn` em `lib/features/jobs/presentation/widgets/job_card.dart` e `kanban_column.dart`
- [x] T06: Conectar abertura do modal ao tocar no card em `lib/features/jobs/presentation/pages/jobs_kanban_page.dart`

## Phase 3: Tests & Quality Validation
- [x] T07: Implementar widget tests para `JobDetailsModal` em `test/features/jobs/presentation/widgets/job_details_modal_test.dart`
- [x] T08: Atualizar widget tests de `JobCard`, `KanbanColumn` e `JobsKanbanPage` cobrindo o toque e abertura do modal
- [x] T09: Executar `flutter test` garantindo 100% de sucesso
- [x] T10: Executar `flutter analyze` garantindo 0 erros e 0 alertas
