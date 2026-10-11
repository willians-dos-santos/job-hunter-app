# Feature Specification: 003 - Gestão de Estado & Quadro Kanban de Vagas (`features/jobs`)

**Feature Branch**: `003-job-kanban-board-and-state`  
**Created**: 2026-10-11  
**Status**: Ready for Implementation  
**Input**: User description: "Implementar a camada de apresentação da funcionalidade `jobs`: gerenciamento de estado conectado ao `JobRepository` e interface do quadro Kanban para visualização, filtragem e transição de status das vagas de emprego."

---

# Spec 003: Gestão de Estado & Quadro Kanban de Vagas (`features/jobs`)

## 1. Contexto e Objetivos

Implementar a camada de apresentação da funcionalidade `jobs`: gerenciamento de estado conectado ao `JobRepository` e interface do quadro Kanban para visualização, filtragem e transição de status das vagas de emprego. O objetivo é prover uma experiência fluida, reativa e interativa, aderente ao design system Dark Mode Stitch, suportando atualizações otimistas com rollback automático em falhas, pesquisa textual instantânea e ações ágeis nos cards de vagas.

---

## 2. Requisitos de Apresentação & Estado

### 2.1 Gerência de Estado (Cubit / BLoC)
- Implementar `JobsCubit` (ou `JobsBloc`) com os seguintes estados:
  - `JobsInitial`, `JobsLoading`, `JobsLoaded`, `JobsError`.
- Métodos/Ações principais:
  - `loadJobs()`: Carrega as vagas usando `JobRepository.getJobs`.
  - `moveJobStatus({required String jobId, required String newStatus})`: Atualização otimista do estado local da vaga no funil e chamada a `JobRepository.updateJobStatus` com rollback em caso de falha.
  - `archiveJob(String jobId)`: Remove a vaga da visualização atual e persiste via `JobRepository.toggleJobArchived`.
  - `filterJobs(String? query)`: Filtro em memória ou requisição filtrada por busca textual.

### 2.2 Quadro Kanban (Interface de Usuário)
- **Estrutura por Colunas do Funil:**
  - 5 colunas correspondentes aos status: `Nova (new)`, `Candidatado (applied)`, `Entrevista (interview)`, `Proposta (offer)`, `Rejeitada (rejected)`.
  - Header de cada coluna com contador de cards e cor do indicador baseada na `KanbanStatusColors` `ThemeExtension`.
  - Suporte a rolagem horizontal entre colunas (em mobile) e visualização fluida em telas largas (Desktop/Web).
- **Card de Vaga (`JobCard`):**
  - Exibir título da vaga, nome da empresa e localidade/modalidade (remoto/híbrido).
  - Badges de tecnologias e tags.
  - Menu de ações rápidas: mover para outro status, arquivar/descartar, e abrir link externo da vaga.
- **Estados Visuais de Tela:**
  - Shimmer ou skeletons no padrão do tema escuro Slate para o estado `Loading`.
  - Empty state elegante para colunas vazias.
  - Exibição de mensagens de erro amigáveis com botão de tentar novamente (`Retry`).

---

## 3. Diretrizes de Design & Tema
- Respeitar 100% os design tokens do projeto: fundo Slate 900 (`#0F172A`), superfícies de cards Slate 800 (`#1E293B`), bordas Slate 700 (`#334155`), tipografia Inter e acentos Cyan/Indigo.
- Responsividade garantida para Desktop Linux nativo, Web e Android.

---

## 4. Testes Unitários & Widget Tests
- Testes unitários para o Cubit/BLoC cobrindo emissão de estados (`Loading` -> `Loaded`), atualização otimista com rollback em erro, e arquivamento.
- Widget tests para `JobCard` e a estrutura das colunas do Kanban.
- Validação final garantindo que `flutter test` e `flutter analyze` finalizem com 0 erros e 0 avisos.

---

## 5. User Scenarios & Acceptance Criteria

### User Story 1 - Carregamento e Visualização do Quadro Kanban (Priority: P1)
Como usuário do Job Hunter, desejo visualizar minhas vagas organizadas em 5 colunas conforme a etapa do processo de candidatura (`Nova`, `Candidatado`, `Entrevista`, `Proposta`, `Rejeitada`) com contadores atualizados e tema escuro consistente.

**Acceptance Scenarios**:
1. **Dado** o acionamento da visualização do Kanban,  
   **Quando** o carregamento é iniciado,  
   **Então** o estado `JobsLoading` deve exibir skeletons/shimmer no estilo Slate 800/700.
2. **Dado** o término com sucesso do carregamento de vagas,  
   **Quando** as vagas forem distribuídas no quadro,  
   **Então** cada card deve ser renderizado em sua coluna de status correspondente, omitindo vagas arquivadas.
3. **Dado** que uma coluna não possua vagas ativas,  
   **Quando** a coluna for renderizada,  
   **Então** um empty state discreto e elegante ("Nenhuma vaga nesta etapa") deve ser exibido.

### User Story 2 - Transição Otimista de Funil e Rollback em Falhas (Priority: P1)
Como usuário gerenciando candidaturas, desejo mover vagas entre as colunas do funil de forma instantânea (atualização otimista), tendo a garantia de que o estado retornará à posição original caso ocorra falha de conexão ou erro no repositório.

**Acceptance Scenarios**:
1. **Dado** uma vaga na coluna `Nova`,  
   **Quando** o usuário selecionar mover para `Entrevista`,  
   **Então** a interface deve mover o card imediatamente para a coluna `Entrevista` e disparar a atualização persistente.
2. **Dado** a falha na chamada `updateJobStatus` no repositório,  
   **Quando** o erro for interceptado,  
   **Então** o `JobsCubit` deve executar rollback do estado local, restaurando a vaga ao status anterior e informando a falha.

### User Story 3 - Busca e Filtragem Dinâmica (Priority: P2)
Como usuário com dezenas de vagas cadastradas, desejo filtrar rapidamente pelo título, empresa ou palavras-chave na barra de busca.

**Acceptance Scenarios**:
1. **Dado** uma consulta digitada pelo usuário,  
   **Quando** `filterJobs(query)` for executado,  
   **Então** apenas as vagas cujo título, empresa ou tags correspondam ao termo de busca devem ser apresentadas nas colunas.
2. **Dado** a limpeza do campo de busca,  
   **Quando** `filterJobs('')` for chamado,  
   **Então** todas as vagas não arquivadas devem reaparecer nas respectivas colunas.

### User Story 4 - Ações Rápidas no JobCard (Priority: P2)
Como usuário visualizando um card de vaga, desejo acessar rapidamente as opções de mover status, arquivar a vaga ou abrir seu link original.

**Acceptance Scenarios**:
1. **Dado** um card de vaga,  
   **Quando** o usuário acionar o menu de ações e selecionar "Arquivar",  
   **Então** a vaga é removida do quadro e o repositório persiste `toggleJobArchived(jobId, isArchived: true)`.
2. **Dado** a seleção da ação "Abrir vaga",  
   **Quando** acionada,  
   **Então** a URL externa da vaga deve ser aberta no navegador padrão do sistema.

---

## 6. Functional Requirements

- **FR-001**: O `JobsCubit` deve implementar a máquina de estados reativa composta por `JobsInitial`, `JobsLoading`, `JobsLoaded` e `JobsError`.
- **FR-002**: O método `loadJobs()` deve requisitar vagas ativas através de `JobRepository.getJobs()` e emitir `JobsLoaded` contendo a lista não arquivada.
- **FR-003**: O método `moveJobStatus({required String jobId, required String newStatus})` deve aplicar atualização otimista local imediata e realizar rollback completo da lista anterior em caso de exceção no repositório.
- **FR-004**: O método `archiveJob(String jobId)` deve remover a vaga da visualização atual e persistir via `JobRepository.toggleJobArchived`.
- **FR-005**: O método `filterJobs(String? query)` deve filtrar os cards em memória pelo termo pesquisado (título, empresa, badges).
- **FR-006**: O componente `JobKanbanBoard` deve exibir 5 colunas estruturadas para os status `newJob`, `applied`, `interview`, `offer` e `rejected`, com contadores e cores da extensão `KanbanStatusColors`.
- **FR-007**: O componente `JobCard` deve exibir título, empresa, localização, badges de plataforma/modalidade e menu de ações contextuais.
- **FR-008**: O layout do Kanban deve ser responsivo, com rolagem horizontal em telas compactas (mobile) e visualização proporcional em telas amplas (desktop e web).
- **FR-009**: Estados de carregamento com esqueletos (skeleton shimmer) e empty states refinados devem ser fornecidos.

---

## 7. Success Criteria

- **SC-001**: 100% de aprovação na suíte de testes com `flutter test`.
- **SC-002**: 0 erros e 0 warnings no `flutter analyze`.
- **SC-003**: Testes unitários para `JobsCubit` validando transições de estado, otimismo com rollback e arquivamento.
- **SC-004**: Widget tests para `JobCard` e colunas do Kanban com cobertura dos elementos visuais obrigatórios.
- **SC-005**: Design system 100% fiel à paleta Slate 900, Slate 800, Slate 700, tipografia e cores semânticas do Kanban.
