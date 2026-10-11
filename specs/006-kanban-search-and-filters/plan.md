# Implementation Plan: 006 - Pesquisa em Tempo Real e Filtros Rápidos no Kanban (`features/jobs`)

**Branch**: `006-kanban-search-and-filters`  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/006-kanban-search-and-filters/spec.md)  
**Status**: In Progress  

## Architecture Overview

A funcionalidade viabiliza busca em tempo real com debounce e filtragem rápida por modalidade no quadro Kanban:
1. **`lib/features/jobs/domain/models/job_modality.dart`**:
   - Criar enum `JobModalityFilter` (`all`, `remote`, `hybrid`, `onSite`) com labels amigáveis (`Todos`, `Remoto`, `Híbrido`, `Presencial`).
2. **`lib/features/jobs/domain/models/job_item.dart`**:
   - Implementar método `matchesModality(JobModalityFilter filter)` para checagem flexível baseada em `location` e `title`.
   - Adicionar getter opcional `detectedModality` para facilitar visualizações nos badges.
3. **`lib/features/jobs/presentation/cubit/jobs_state.dart`**:
   - Expandir `JobsLoaded` com propriedade `selectedModality` (default: `JobModalityFilter.all`).
   - Adicionar helper `bool get hasActiveFilter => (searchQuery != null && searchQuery!.isNotEmpty) || selectedModality != JobModalityFilter.all;`.
   - Atualizar `copyWith`, `operator ==` e `hashCode`.
4. **`lib/features/jobs/presentation/cubit/jobs_cubit.dart`**:
   - Ajustar `_applyFilter(List<JobItem> items, String? query, JobModalityFilter modality)` para aplicar a interseção de texto e modalidade.
   - Atualizar `filterJobs(String? query)` para preservar a modalidade selecionada.
   - Adicionar `setModalityFilter(JobModalityFilter modality)` para filtrar e emitir novo estado preservando a busca de texto.
   - Adicionar `resetFilters()` para restaurar a lista completa (`allJobs`), limpando a query de busca e definindo modalidade como `all`.
   - Garantir que `moveJobStatus`, `archiveJob` e `updateJobNotes` preservem tanto a query quanto a modalidade selecionada.
5. **`lib/features/jobs/presentation/pages/jobs_kanban_page.dart`**:
   - Introduzir `Timer? _debounceTimer` no estado para disparar `cubit.filterJobs` após 400ms ao alterar o `TextField`.
   - Exibir botão de limpar texto (`suffixIcon`) que cancela o timer, limpa o controller e dispara `cubit.filterJobs('')`.
   - Criar barra horizontal deslizante com os chips de filtro rápido de modalidade.
   - Adicionar estado vazio contextual (`KanbanEmptyFilteredView`) quando nenhum resultado for encontrado com filtros ativos, com botão "Redefinir filtros".
6. **Testes Unitários & Widget Tests**:
   - Unit tests em `JobsCubit`: busca com query, filtro por modalidade, interseção de ambos, reset de filtros e preservação durante ações de funil.
   - Widget tests em `JobsKanbanPage`: validação do debounce (antes e após 400ms), botão de limpar, toque nos chips de modalidade, renderização do estado vazio e ação do botão de redefinir.

## Testing Strategy
- Unit tests em `JobsCubit`:
  - `filterJobs` aplicando texto com preservação de modalidade.
  - `setModalityFilter` aplicando modalidade com preservação de texto.
  - Combinação de texto e modalidade.
  - `resetFilters` limpando todos os filtros.
- Widget tests em `JobsKanbanPage`:
  - Debounce de 400ms no campo de busca.
  - Ação do botão de limpar no campo de busca.
  - Interação com os chips de modalidade (`Todos`, `Remoto`, `Híbrido`, `Presencial`).
  - Exibição de `KanbanEmptyFilteredView` quando `state.jobs.isEmpty` em busca sem correspondência e clique em "Redefinir filtros".
