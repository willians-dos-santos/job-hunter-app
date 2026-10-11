# Implementation Plan: 005 - Detalhes da Vaga, Visualização Completa e Notas Pessoais (`features/jobs`)

**Branch**: `005-job-details-and-notes-modal`  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/005-job-details-and-notes-modal/spec.md)  
**Status**: In Progress  

## Architecture Overview

A funcionalidade consolida a visualização rica dos detalhes da vaga e o ciclo de edição de anotações pessoais do candidato:
1. **`lib/features/jobs/domain/models/job_item.dart`**:
   - Garantir suporte completo para atualização de `notes` no método `copyWith`, com flag opcional `clearNotes`.
2. **`lib/features/jobs/presentation/cubit/jobs_cubit.dart`**:
   - Adicionar método `updateJobNotes({required String jobId, required String notes})`.
   - Executar atualização otimista na lista de vagas do estado `JobsLoaded`.
   - Chamar `JobRepository.updateJobNotes(jobId: jobId, notes: notes)`.
   - Ao confirmar sucesso: emitir `JobsLoaded` com `successMessage: 'Anotações salvas com sucesso.'`.
   - Em caso de exceção: reverter a lista ao estado anterior e emitir `errorMessage: 'Erro ao salvar anotações: $e'`.
3. **`lib/features/jobs/presentation/widgets/job_details_modal.dart`**:
   - Criar o widget `JobDetailsModal` e a função auxiliar `showJobDetailsModal(BuildContext context, ...)`.
   - Bottom sheet responsivo (com `BoxConstraints(maxWidth: 640)` para telas amplas, bordas arredondadas e indicador de arraste).
   - Exibir título, empresa, status do funil, badges (plataforma, modalidade, salário) e data de publicação formatada.
   - Botão para acessar vaga externa (`job_url`) via `url_launcher`.
   - Campo multi-linha para anotações do candidato com botão "Salvar Anotações".
   - Estilização 100% aderente ao tema escuro Slate (Slate 900, Slate 850, Slate 800, Slate 700).
4. **`lib/features/jobs/presentation/widgets/job_card.dart` & `kanban_column.dart`**:
   - Adicionar callback `onTap` em `JobCard` envolvido em `InkWell` para abrir o modal de detalhes ao tocar no cartão.
   - Propagar `onJobTap` em `KanbanColumn`.
5. **`lib/features/jobs/presentation/pages/jobs_kanban_page.dart`**:
   - Conectar o callback `onJobTap` de cada coluna para abrir o `JobDetailsModal` passando o `cubit`.
6. **Testes Unitários & Widget Tests**:
   - Testes unitários para `JobsCubit.updateJobNotes` (sucesso e falha com rollback).
   - Widget tests para `JobDetailsModal` (renderização dos dados, botão de link externo, edição e salvamento de notas).
   - Widget tests em `JobCard` e `JobsKanbanPage` cobrindo o toque no card e abertura do modal.

## Testing Strategy
- Unit tests em `JobsCubit`:
  - `updateJobNotes` otimista e confirmação via repositório.
  - `updateJobNotes` com falha e reversão das anotações anteriores.
- Widget tests em `JobDetailsModal`:
  - Exibição de título, empresa, badges, salário e data.
  - Interação com link externo.
  - Edição de texto e acionamento de salvar notas com SnackBar.
- Widget tests em `JobCard` e `JobsKanbanPage`:
  - Disparo de `onTap` no `JobCard`.
  - Abertura do modal ao tocar no card na tela de Kanban.
