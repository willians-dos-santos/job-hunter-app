# Tasks: 006 - Pesquisa em Tempo Real e Filtros Rápidos no Kanban (`features/jobs`)

**Branch**: `006-kanban-search-and-filters`  
**Plan**: [plan.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/006-kanban-search-and-filters/plan.md)  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/006-kanban-search-and-filters/spec.md)  

## Phase 1: Domain & State Management
- [x] T01: Criar `JobModalityFilter` enum em `lib/features/jobs/domain/models/job_modality.dart`
- [x] T02: Adicionar método `matchesModality` e getter `detectedModality` em `lib/features/jobs/domain/models/job_item.dart`
- [x] T03: Atualizar `JobsLoaded` state para suportar `selectedModality` e `hasActiveFilter` em `lib/features/jobs/presentation/cubit/jobs_state.dart`
- [x] T04: Implementar métodos `setModalityFilter`, `resetFilters` e atualizar `filterJobs` em `lib/features/jobs/presentation/cubit/jobs_cubit.dart`
- [x] T05: Adicionar testes unitários para busca, modalidade, combinação de filtros e reset em `test/features/jobs/presentation/cubit/jobs_cubit_test.dart`

## Phase 2: UI Presentation & Components
- [x] T06: Adicionar debounce (~400ms) e botão de limpar no campo de busca em `lib/features/jobs/presentation/pages/jobs_kanban_page.dart`
- [x] T07: Implementar barra deslizante horizontal com chips de modalidade (`Todos`, `Remoto`, `Híbrido`, `Presencial`) em `lib/features/jobs/presentation/pages/jobs_kanban_page.dart`
- [x] T08: Criar componente de estado vazio contextual com botão de redefinir filtros em `lib/features/jobs/presentation/pages/jobs_kanban_page.dart`

## Phase 3: Tests & Quality Validation
- [x] T09: Adicionar widget tests em `test/features/jobs/presentation/pages/jobs_kanban_page_test.dart` cobrindo debounce, chips de modalidade e estado vazio
- [x] T10: Executar `flutter test` garantindo 100% de sucesso
- [x] T11: Executar `flutter analyze` garantindo 0 erros e 0 alertas
