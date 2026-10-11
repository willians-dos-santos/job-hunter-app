# Feature Specification: 004 - Ações Rápidas, Transições de Estado e Mutações no Kanban (`features/jobs`)

**Feature Branch**: `004-job-card-actions-and-transitions`  
**Created**: 2026-10-11  
**Status**: Ready for Implementation  
**Input**: User description: "Habilitar a interatividade completa nos cartões de vagas do quadro Kanban, permitindo a transição entre colunas (`new`, `applied`, `interview`, `offer`, `rejected`) e a ação de arquivar vagas através de mutações com atualização otimista na tabela `user_job_interactions` do Supabase."

---

# Spec 004: Ações Rápidas, Transições de Estado e Mutações no Kanban (`features/jobs`)

## 1. Contexto e Objetivos
Habilitar a interatividade completa nos cartões de vagas do quadro Kanban, permitindo a transição entre colunas (`new`, `applied`, `interview`, `offer`, `rejected`) e a ação de arquivar vagas através de mutações com atualização otimista na tabela `user_job_interactions` do Supabase.

## 2. Requisitos Funcionais

### 2.1 Transição de Coluna / Estado
- **Menu de Ações Rápidas no Cartão (`JobCard`):**
  - No menu contextual (ícone de 3 pontos), listar as opções para mover a vaga para os demais estados do funil.
  - Conectar ao `JobRepository.updateJobStatus` com atualização otimista na gerência de estado.
  - Em caso de erro, reverter a posição do cartão e exibir SnackBar de erro.

### 2.2 Ação de Arquivar / Descartar
- Incluir a opção "Arquivar Vaga" no menu do cartão.
  - Remover o cartão do quadro atual chamando `JobRepository.toggleJobArchived`.
  - Exibir SnackBar de confirmação.

## 3. Testes Unitários e Validação
- Testes no Cubit/BLoC para transição com sucesso, rollback em falha e arquivamento.
- Testes de widgets no `JobCard` cobrindo as opções do menu contextual.
- Garantir `flutter test` e `flutter analyze` sem erros ou avisos.

---

## 4. User Scenarios & Acceptance Criteria

### User Story 1 - Transição Rápida entre Etapas do Funil pelo Card (Priority: P1)
Como usuário visualizando o quadro Kanban de vagas, desejo clicar no menu de ações rápidas de qualquer cartão e selecionar uma nova etapa do funil (`new`, `applied`, `interview`, `offer`, `rejected`), para que o cartão seja movido instantaneamente de forma otimista e persistido no Supabase via `user_job_interactions`.

**Acceptance Scenarios**:
1. **Dado** um cartão de vaga na coluna "Nova",  
   **Quando** o usuário abrir o menu de 3 pontos do cartão,  
   **Então** o menu deve listar as opções para mover para as demais 4 etapas: "Mover para Candidatado", "Mover para Entrevista", "Mover para Proposta" e "Mover para Rejeitada".
2. **Dado** a seleção de uma das opções de movimentação,  
   **Quando** o evento for acionado,  
   **Então** o `JobsCubit` deve atualizar o estado local instantaneamente (otimismo) e invocar `JobRepository.updateJobStatus`.
3. **Dado** uma falha de conexão ou erro no Supabase durante a atualização,  
   **Quando** a exceção for capturada,  
   **Então** o cartão deve ser revertido à sua coluna original e um SnackBar com mensagem de erro deve ser exibido.

### User Story 2 - Arquivamento de Vagas com Feedback de Confirmação (Priority: P1)
Como usuário filtrando oportunidades de emprego, desejo arquivar vagas irrelevantes diretamente pelo menu contextual do cartão, para que ela desapareça do funil ativo e um SnackBar de confirmação seja exibido.

**Acceptance Scenarios**:
1. **Dado** um cartão de vaga visível em qualquer coluna,  
   **Quando** o usuário selecionar a opção "Arquivar vaga" no menu de 3 pontos,  
   **Então** a vaga é removida imediatamente do quadro, `JobRepository.toggleJobArchived(jobId, isArchived: true)` é chamado e um SnackBar de confirmação ("Vaga arquivada com sucesso.") é apresentado ao usuário.
2. **Dado** que a persistência remota do arquivamento falhe,  
   **Quando** o erro for interceptado,  
   **Então** a vaga deve ser restaurada ao quadro ativo e um SnackBar de erro deve ser apresentado.

---

## 5. Functional Requirements
- **FR-001**: O `JobCard` deve dispor de um botão de menu popup (`PopupMenuButton`) com ícone de 3 pontos listando dinamicamente todos os status de `JobStatus.values` exceto o status corrente da vaga.
- **FR-002**: A seleção de qualquer status deve disparar o callback `onMoveStatus(targetStatus)` conectado ao método `moveJobStatus` do `JobsCubit`.
- **FR-003**: O `JobsCubit` deve aplicar atualização otimista na lista de vagas do estado `JobsLoaded` e reverter a lista em caso de exceção, preenchendo `errorMessage`.
- **FR-004**: O menu contextual do `JobCard` deve incluir a opção "Arquivar vaga", que dispara o callback `onArchive` conectado ao método `archiveJob` do `JobsCubit`.
- **FR-005**: O método `archiveJob` do `JobsCubit` deve remover a vaga otimisticamente do quadro, persistir via `JobRepository.toggleJobArchived(jobId, isArchived: true)` e, em caso de sucesso, emitir `successMessage`. Em caso de erro, reverter e emitir `errorMessage`.
- **FR-006**: A tela `JobsKanbanPage` deve escutar as mudanças de estado do `JobsCubit` e exibir SnackBars flutuantes tanto para erros (com cor de alerta) quanto para confirmações (ex: arquivamento bem-sucedido).

---

## 6. Success Criteria
- **SC-001**: 100% dos testes unitários e de widgets passando com `flutter test`.
- **SC-002**: Análise estática com 0 erros e 0 avisos em `flutter analyze`.
- **SC-003**: Cobertura de testes unitários para o fluxo de arquivamento com confirmação e transições de status com rollback em falha.
- **SC-004**: Cobertura de widget tests no `JobCard` e `JobsKanbanPage` para todas as opções do menu contextual e exibição dos SnackBars.
