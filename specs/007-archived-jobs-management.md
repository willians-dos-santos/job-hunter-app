# Feature Specification: 007 - Gestão e Recuperação de Vagas Arquivadas (`features/jobs`)

**Feature Branch**: `007-archived-jobs-management`  
**Created**: 2026-10-12  
**Status**: Implemented  
**Input**: User description: "Criar a tela de vagas arquivadas (ArchivedJobsScreen), permitindo auditar vagas descartadas (is_archived = true) e restaurá-las para o quadro Kanban via mutação no Supabase."

---

# Spec 007: Gestão e Recuperação de Vagas Arquivadas (`features/jobs`)

## 1. Contexto e Objetivos
Criar a tela de vagas arquivadas (`ArchivedJobsScreen`), permitindo auditar vagas descartadas (`is_archived = true`) e restaurá-las para o quadro Kanban via mutação no Supabase.

## 2. Requisitos Funcionais
1. **Navegação:**
   - Adicionar botão de acesso às vagas arquivadas no topo da tela principal (`AppBar`).
2. **Listagem:**
   - Buscar registros com `is_archived = true` vinculados ao usuário autenticado.
   - Tratar estados de loading, lista vazia e erro de conexão.
3. **Ações:**
   - Ação de "Restaurar" chamando `JobRepository.toggleJobArchived` com `isArchived: false` (usando `onConflict: 'user_id,job_id'`).
   - Tocar no cartão abre o modal de detalhes existente.
   - Sincronizar o estado do Kanban ao retornar à tela principal.
4. **Qualidade:**
   - Cobertura de testes unitários no Cubit e de widgets na nova tela.
   - Garantir 0 erros e 0 alertas em `flutter test` e `flutter analyze`.

---

## 3. User Scenarios & Acceptance Criteria

### User Story 1 - Acesso e Auditoria de Vagas Arquivadas (Priority: P1)
Como candidato organizando meu funil de candidaturas no Job Hunter, desejo acessar uma tela dedicada às vagas descartadas através de um botão no cabeçalho do Kanban, visualizando todas as vagas arquivadas com tratamento visual para carregamento, lista vazia e falhas de conexão.

**Why this priority**:
Permite que o usuário consulte vagas que foram anteriormente arquivadas sem poluir o fluxo ativo do Kanban, garantindo transparência e integridade das oportunidades descartadas.

**Acceptance Scenarios**:
1. **Dado** o quadro Kanban aberto,  
   **Quando** o usuário toca no botão de arquivo na `AppBar`,  
   **Então** o aplicativo deve navegar para a tela `ArchivedJobsScreen`.
2. **Dado** a tela `ArchivedJobsScreen` em processo de busca inicial,  
   **Quando** a requisição ao Supabase estiver em andamento,  
   **Então** deve ser exibido um indicador de carregamento coerente com o design system Slate.
3. **Dado** que o usuário não possui nenhuma vaga arquivada (`is_archived = true`),  
   **Quando** a consulta for concluída,  
   **Então** deve ser renderizado um estado vazio amigável informando a ausência de vagas arquivadas.
4. **Dado** uma falha de rede ou indisponibilidade do backend,  
   **Quando** a consulta falhar,  
   **Então** deve ser exibida uma mensagem de erro com botão de repetição ("Tentar novamente").

---

### User Story 2 - Recuperação e Restauração de Vagas para o Kanban (Priority: P1)
Como candidato que arquivou uma oportunidade por engano ou deseja reconsiderar um processo, desejo tocar na ação de "Restaurar" em um cartão arquivado para desarquivar a vaga no Supabase e vê-la novamente no funil ativo do Kanban.

**Why this priority**:
Evita perda definitiva de oportunidades e permite reversibilidade ágil no funil de processos seletivos.

**Acceptance Scenarios**:
1. **Dado** um cartão de vaga visível na lista de arquivadas,  
   **Quando** o usuário toca na ação "Restaurar",  
   **Então** a operação `JobRepository.toggleJobArchived` deve ser acionada com `isArchived: false` (utilizando `onConflict: 'user_id,job_id'`), removendo a vaga da lista de arquivadas e emitindo feedback visual via SnackBar.
2. **Dado** a restauração de uma ou mais vagas na tela de arquivadas,  
   **Quando** o usuário retorna para a tela principal (`JobsKanbanPage`),  
   **Então** o quadro Kanban deve sincronizar reativamente os dados e exibir a vaga restaurada na coluna correspondente ao seu status.

---

### User Story 3 - Consulta de Detalhes da Vaga Arquivada (Priority: P2)
Como candidato inspecionando uma vaga arquivada, desejo tocar no cartão para abrir o modal de detalhes existente (`JobDetailsModal`), podendo ler a descrição, anotações prévias e abrir o link externo original.

**Why this priority**:
Reutiliza a experiência consistente de detalhes e anotações sem duplicar componentes de interface.

**Acceptance Scenarios**:
1. **Dado** a lista de vagas arquivadas exibida na tela,  
   **Quando** o usuário toca sobre o cartão da vaga,  
   **Então** o modal bottom sheet responsivo `JobDetailsModal` deve ser aberto com todas as informações e notas da vaga.

---

## 4. Edge Cases
- **Tentativa de restaurar sem conexão**: Ao falhar a chamada remota de restauração, a vaga deve ser mantida na lista com mensagem clara de erro via SnackBar.
- **Restauração de todas as vagas arquivadas**: Ao restaurar a última vaga restante da lista, a tela deve alternar automaticamente para o estado vazio.
- **Retorno imediato via navegação (Back button)**: A tela do Kanban deve atualizar seus itens ao recuperar o foco após navegação.
- **Descarte de widget em transição**: Cancelar operações assíncronas pendentes sem emitir estados após `dispose`.

---

## 5. Functional Requirements
- **FR-001**: O `AppBar` de `JobsKanbanPage` deve conter um botão de navegação com ícone de arquivo para abrir a tela `ArchivedJobsScreen`.
- **FR-002**: A tela `ArchivedJobsScreen` deve listar vagas com `is_archived = true` filtradas pelo usuário autenticado.
- **FR-003**: Deve ser implementado o `ArchivedJobsCubit` gerenciando os estados `ArchivedJobsInitial`, `ArchivedJobsLoading`, `ArchivedJobsLoaded` e `ArchivedJobsError`.
- **FR-004**: O `IJobRemoteDataSource` e `IJobRepository` devem suportar busca explícita de vagas arquivadas (`getArchivedJobs`).
- **FR-005**: A ação de restaurar vaga deve invocar `JobRepository.toggleJobArchived` passando `isArchived: false` com resolução de conflito `onConflict: 'user_id,job_id'`.
- **FR-006**: Ao tocar no cartão da vaga na lista arquivada, deve ser aberto o modal responsivo `JobDetailsModal`.
- **FR-007**: Ao retornar para a tela principal (`JobsKanbanPage`), o estado do Kanban deve ser recarregado/sincronizado automaticamente.
- **FR-008**: O design deve respeitar a paleta de cores Dark Mode Slate (Slate 900, Slate 800, Slate 700) com tipografia Inter/mono.

---

## 6. Key Entities
- **`ArchivedJobsScreen`**: Página/tela de listagem e restauração de vagas arquivadas.
- **`ArchivedJobsCubit` & `ArchivedJobsState`**: Gerenciador de estado dedicado à listagem e ações nas vagas arquivadas.
- **`JobItem`**: Entidade de vaga contendo a propriedade booleana `isArchived`.
- **`JobDetailsModal`**: Componente compartilhado de visualização detalhada da oportunidade.

---

## 7. Success Criteria
- **SC-001**: 100% de sucesso nos testes unitários e de widgets (`flutter test`).
- **SC-002**: Análise estática com 0 erros e 0 alertas em `flutter analyze`.
- **SC-003**: Testes unitários no `ArchivedJobsCubit` cobrindo carregamento, lista vazia, falha, restauração otimista e rollback em caso de erro.
- **SC-004**: Testes de widgets na tela `ArchivedJobsScreen` cobrindo loading, listagem, estado vazio, acionamento de restauração e abertura do modal de detalhes.
- **SC-005**: Testes de widgets na `JobsKanbanPage` validando presença do botão de arquivadas e navegação.
