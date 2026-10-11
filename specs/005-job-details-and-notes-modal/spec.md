# Feature Specification: 005 - Detalhes da Vaga, Visualização Completa e Notas Pessoais (`features/jobs`)

**Feature Branch**: `005-job-details-and-notes-modal`  
**Created**: 2026-10-11  
**Status**: Ready for Implementation  
**Input**: User description: "Implementar o modal responsivo (Bottom Sheet) de detalhes da vaga, acionado ao tocar num `JobCard`, com visualização dos dados completos, ligação externa e edição de notas pessoais salvas no Supabase."

---

# Spec 005: Detalhes da Vaga, Visualização Completa e Notas Pessoais (`features/jobs`)

## 1. Contexto e Objetivos
Implementar o modal responsivo (Bottom Sheet) de detalhes da vaga, acionado ao tocar num `JobCard`, com visualização dos dados completos, ligação externa e edição de notas pessoais salvas no Supabase.

## 2. Requisitos Funcionais
1. **Modal Responsivo:**
   - Abrir ao tocar no `JobCard`.
   - Exibir título, empresa, badges de modalidade/plataforma, salário e data de publicação.
   - Botão para abrir o link da vaga externa (`job_url`) usando `url_launcher`.
2. **Edição e Persistência de Notas:**
   - Campo multi-linha para anotações pessoais do candidato.
   - Conectar ao `JobRepository.updateJobNotes` (com `onConflict: 'user_id,job_id'`) para persistir alterações no Supabase.
   - Feedback visual via SnackBar ao guardar.
3. **Estilo e Tema:**
   - Manter 100% de coerência com o tema escuro Slate (Slate 900/800/700).

## 3. Testes e Validação
- Testes de Cubit para alteração e persistência de anotações.
- Widget tests para o modal de detalhes.
- Garantir 0 erros e 0 avisos em `flutter test` e `flutter analyze`.

---

## 4. User Scenarios & Acceptance Criteria

### User Story 1 - Abertura e Visualização Completa da Vaga via Modal Responsivo (Priority: P1)
Como candidato acompanhando oportunidades no Kanban, desejo tocar no cartão de uma vaga para visualizar seus detalhes completos em um modal/bottom sheet responsivo, com informações de remuneração, modalidade, plataforma, data de postagem e acesso direto ao link externo da vaga.

**Acceptance Scenarios**:
1. **Dado** um cartão de vaga visível no quadro Kanban,  
   **Quando** o usuário toca no `JobCard`,  
   **Então** o modal bottom sheet responsivo de detalhes deve abrir exibindo título, empresa, badges de plataforma/modalidade, remuneração e data de publicação formatada.
2. **Dado** uma vaga com `job_url` configurado,  
   **Quando** o usuário tocar no botão de link externo,  
   **Então** a aplicação deve abrir o link no navegador externo via `url_launcher`.

### User Story 2 - Edição e Persistência de Anotações Pessoais com Feedback (Priority: P1)
Como candidato em processo seletivo, desejo adicionar ou atualizar minhas anotações pessoais sobre a oportunidade (ex: contatos, feedback de entrevistas, impressões) diretamente pelo modal, persistindo no Supabase e recebendo confirmação visual.

**Acceptance Scenarios**:
1. **Dado** o modal de detalhes aberto para uma vaga com ou sem notas prévias,  
   **Quando** o usuário editar o campo multi-linha de anotações e acionar "Salvar",  
   **Então** a alteração deve ser enviada via `JobRepository.updateJobNotes` (com `onConflict: 'user_id,job_id'`), o estado local no `JobsCubit` deve refletir as novas notas e um SnackBar de confirmação deve ser exibido.
2. **Dado** que a operação de persistência remota falhe,  
   **Quando** a exceção ocorrer,  
   **Então** o estado local deve manter a integridade, emitir mensagem de erro e exibir SnackBar de erro ao usuário.

---

## 5. Functional Requirements
- **FR-001**: O `JobCard` deve expor evento de toque `onTap` e abrir o modal responsivo de detalhes `JobDetailsModal`.
- **FR-002**: O `JobDetailsModal` deve ser renderizado como um Bottom Sheet responsivo com cantos arredondados, barra de arrasto/fechamento e largura contida em telas maiores.
- **FR-003**: O modal deve apresentar de forma clara: título, empresa, badges (plataforma, modalidade de trabalho, salário/remuneração), data de publicação e botão de ação para abrir o link externo (`job_url`) via `url_launcher`.
- **FR-004**: O modal deve conter um campo de texto multi-linha para anotações do candidato pré-preenchido com `job.notes`.
- **FR-005**: Ao clicar no botão de salvar notas, o `JobsCubit.updateJobNotes` deve ser disparado, acionando `JobRepository.updateJobNotes` no Supabase e atualizando o `JobItem` na lista de vagas ativas.
- **FR-006**: Ao salvar as notas com sucesso, um SnackBar de confirmação visual deve ser exibido. Em caso de falha, exibir SnackBar de erro.
- **FR-007**: Todo o design do modal deve seguir estritamente o tema escuro Slate (Slate 900 de fundo, Slate 800 de superfície/cards, Slate 700 de bordas e tipografia Inter/mono).

---

## 6. Success Criteria
- **SC-001**: 100% dos testes unitários e de widgets passando com `flutter test`.
- **SC-002**: Análise estática com 0 erros e 0 avisos em `flutter analyze`.
- **SC-003**: Testes unitários no `JobsCubit` cobrindo alteração de notas com sucesso e tratamento de rollback/erro.
- **SC-004**: Widget tests para `JobDetailsModal` cobrindo renderização dos dados, botão de link externo e edição/salvamento de notas com SnackBar.
- **SC-005**: Widget tests no `JobCard` e `JobsKanbanPage` validando abertura do modal ao tocar no cartão.
