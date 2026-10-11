# Implementation Plan: 004 - Ações Rápidas, Transições de Estado e Mutações no Kanban (`features/jobs`)

**Branch**: `004-job-card-actions-and-transitions`  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/004-job-card-actions-and-transitions/spec.md)  
**Status**: In Progress  

## Architecture Overview

A funcionalidade de interatividade e mutações das vagas consolida a integração entre `JobCard`, `JobsCubit` e `JobRepository`:
- **`lib/features/jobs/presentation/cubit/jobs_state.dart`**:
  - `JobsLoaded`: Adicionar campo `successMessage` para notificações de sucesso (ex: confirmação de arquivamento), com suporte a `copyWith(clearSuccessMessage: true)` e comparação de igualdade.
- **`lib/features/jobs/presentation/cubit/jobs_cubit.dart`**:
  - `moveJobStatus`: Realiza a mutação otimista de transição de status de funil (`new`, `applied`, `interview`, `offer`, `rejected`), dispara `updateJobStatus` no repositório e, em caso de erro, reverte e preenche `errorMessage`.
  - `archiveJob`: Remove a vaga otimisticamente do quadro, chama `toggleJobArchived(jobId, isArchived: true)` e, ao confirmar o sucesso, emite `successMessage: 'Vaga arquivada com sucesso.'`. Em caso de erro, reverte ao estado anterior com `errorMessage`.
  - `clearSuccessMessage()`: Reseta o `successMessage` após exibição na UI.
- **`lib/features/jobs/presentation/widgets/job_card.dart`**:
  - O menu contextual (ícone de 3 pontos) lista dinamicamente todos os status alternativos do funil (`JobStatus.values`), opção "Abrir link externo" (se houver url) e "Arquivar vaga".
  - Invoca os callbacks `onMoveStatus` e `onArchive`.
- **`lib/features/jobs/presentation/pages/jobs_kanban_page.dart`**:
  - No `BlocConsumer.listener`, intercepta `successMessage` e `errorMessage` emitidos pelo cubit e apresenta SnackBars flutuantes formatados.
- **Testes Unitários & Widget Tests**:
  - Atualizar e expandir a suíte de testes do cubit, widget test do `JobCard` e testes de fluxo no `JobsKanbanPage`.

## Testing Strategy
- Unit tests em `JobsCubit`:
  - Transição de status com sucesso.
  - Transição de status com falha e rollback para estado original.
  - Arquivamento com sucesso emitindo `successMessage`.
  - Arquivamento com falha e rollback emitindo `errorMessage`.
- Widget tests em `JobCard`:
  - Abertura do menu popup e acionamento de cada opção de mudança de status.
  - Acionamento da opção "Arquivar vaga".
- Widget tests em `JobsKanbanPage`:
  - Exibição de SnackBar de confirmação quando uma vaga é arquivada com sucesso.
  - Exibição de SnackBar de erro quando uma transição falha.
