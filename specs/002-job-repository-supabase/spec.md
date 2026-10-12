# Feature Specification: 002 - Camada de Dados e Repositórios Supabase (`features/jobs`)

**Feature Branch**: `002-job-repository-supabase`  
**Created**: 2026-10-11  
**Status**: Ready for Implementation  
**Input**: User description: "Implementar a camada de dados da funcionalidade `jobs` para consumir a view `v_user_jobs` e persistir mutações na tabela `user_job_interactions` utilizando o cliente oficial do Supabase em Flutter."

---

## 1. Contexto e Objetivos

Implementar a camada de dados da funcionalidade `jobs` para consumir a view `v_user_jobs` e persistir mutações na tabela `user_job_interactions` utilizando o cliente oficial do Supabase em Flutter (`supabase_flutter`). O objetivo é prover interfaces padronizadas (`IJobRemoteDataSource`, `IJobRepository`), suportar consultas paginadas, filtradas e ordenadas, gerenciar o ciclo de vida de mutações de candidatos no funil Kanban e tratar erros de infraestrutura transformando-os em exceções tipadas de domínio.

---

## 2. User Scenarios & Testing *(mandatory)*

### User Story 1 - Leitura Paginada e Filtrada de Vagas (Priority: P1)

Como usuário e desenvolvedor do Job Hunter, necessito consultar vagas de emprego da view `v_user_jobs` através de um repositório centralizado, suportando paginação por offset, filtro por status do funil (`new`, `applied`, `interview`, `offer`, `rejected`), busca textual por palavras-chave em título ou empresa, e ordenação cronológica decrescente padrão.

**Why this priority**:
É o fluxo primário de dados da aplicação. Sem uma camada de leitura robusta, a exibição do Kanban e das listas de vagas não pode ser alimentada de maneira performática e flexível.

**Independent Test**:
Pode ser testado de forma isolada com mocks de `SupabaseClient` e `PostgrestFilterBuilder` via `mocktail`, simulando retorno de listas JSON completas, filtros combinados de status e busca, além de validação de parâmetros de range para paginação.

**Acceptance Scenarios**:

1. **Dado** uma solicitação de vagas com parâmetros padrão (`limit: 20, offset: 0`),  
   **Quando** o método `getJobs()` for chamado,  
   **Então** a query deve consultar `v_user_jobs`, ordenar por data de publicação/criação decrescente e retornar uma lista de instâncias `JobItem`.

2. **Dado** a aplicação de um filtro por status (ex: `'interview'`) e termo de busca (ex: `'Flutter'`),  
   **Quando** `getJobs(statusFilter: 'interview', query: 'Flutter')` for executado,  
   **Então** a query deve aplicar as cláusulas de igualdade em `status` e filtro OR via `ilike` em `title` e `company_name`.

3. **Dado** um identificador de vaga existente no banco,  
   **Quando** `getJobById(id)` for executado,  
   **Então** a entidade detalhada `JobItem` correspondente deve ser retornada.

4. **Dado** um identificador de vaga inexistente ou nulo,  
   **Quando** `getJobById(id)` for executado,  
   **Então** o sistema deve lançar a exceção de domínio `JobNotFoundFailure`.

---

### User Story 2 - Mutações de Interação e Transição de Funil (Priority: P1)

Como candidato gerenciando processos seletivos, necessito persistir alterações de estado de candidatura, notas pessoais e arquivamento de vagas na tabela `user_job_interactions` utilizando operações de upsert baseadas no `job_id`.

**Why this priority**:
Garante que as ações do usuário (mover cartão no Kanban, adicionar anotações de entrevista ou arquivar vagas irrelevantes) sejam sincronizadas de forma persistente com o backend Supabase.

**Independent Test**:
Pode ser testado de forma isolada validando os payloads gerados nas chamadas de upsert para a tabela `user_job_interactions` com mocks, verificando a presença das chaves obrigatórias e formatos corretos.

**Acceptance Scenarios**:

1. **Dado** a alteração de status de uma vaga para `'applied'`,  
   **Quando** `updateJobStatus(jobId: '123', newStatus: 'applied')` for chamado,  
   **Então** a operação de upsert deve incluir `job_id`, `status` e carimbo `applied_at` em UTC.

2. **Dado** a edição de notas de estudo ou entrevista,  
   **Quando** `updateJobNotes(jobId: '123', notes: 'Contato RH realizado')` for chamado,  
   **Então** a operação de upsert deve persistir as notas associadas ao `job_id`.

3. **Dado** o arquivamento ou desarquivamento de uma vaga,  
   **Quando** `toggleJobArchived(jobId: '123', isArchived: true)` for chamado,  
   **Então** o registro correspondente na tabela `user_job_interactions` deve ter `is_archived: true`.

---

### User Story 3 - Tratamento e Mapeamento Resiliente de Erros (Priority: P2)

Como engenheiro de software, necessito que erros de rede, indisponibilidade ou falhas de restrição do Postgrest sejam capturados e traduzidos para exceções tipadas de domínio (`JobFetchFailure`, `JobMutationFailure`, `JobNotFoundFailure`), garantindo desacoplamento de detalhes do SDK nos níveis superiores da arquitetura.

**Why this priority**:
Evita que exceções brutas do Postgrest ou de rede vazem para camadas de apresentação e blocos de regra de negócio, permitindo mensagens amigáveis e recuperação previsível.

**Independent Test**:
Pode ser testado simulando o lançamento de `PostgrestException` e `SocketException` pelos mocks do cliente e assegurando que as classes de repositório e data source re-lancem as falhas tipadas correspondentes.

**Acceptance Scenarios**:

1. **Dado** uma falha de conexão ou erro do Postgrest durante leitura,  
   **Quando** qualquer método de leitura for invocado,  
   **Então** uma exceção `JobFetchFailure` deve ser lançada contendo detalhes do erro.

2. **Dado** uma falha de restrição ou escrita durante uma mutação,  
   **Quando** qualquer método de mutação for invocado,  
   **Então** uma exceção `JobMutationFailure` deve ser lançada.

---

### Edge Cases

- **Nenhum resultado retornado**: Quando a busca não encontra nenhuma vaga correspondente aos filtros, `getJobs` deve retornar uma lista vazia `[]` sem lançar exceções.
- **Offsets negativos ou fora do limite**: O data source deve normalizar offsets menores que zero para 0.
- **Valores nulos em campos opcionais**: Campos como `salary_text`, `location`, `notes` e `published_at` continuam sendo tratados graciosamente através das proteções do modelo `JobItem`.
- **Falha de rede ou timeout**: Conexões instáveis devem resultar em `JobFetchFailure` ou `JobMutationFailure` com mensagens claras e rastreáveis.

---

## 3. Requirements *(mandatory)*

### Functional Requirements

- **FR-001 (Interface IJobRemoteDataSource)**: O sistema DEVE definir `IJobRemoteDataSource` contendo:
  - `getJobs({int limit = 20, int offset = 0, String? statusFilter, String? query})`
  - `getJobById(String id)`
  - `updateJobStatus({required String jobId, required String newStatus})`
  - `updateJobNotes({required String jobId, required String notes})`
  - `toggleJobArchived({required String jobId, required bool isArchived})`
  - `upsertInteraction(UserJobInteraction interaction)`
- **FR-002 (Interface IJobRepository)**: O sistema DEVE definir `IJobRepository` no módulo `features/jobs/domain/repositories/` com as operações correspondentes para consumo pela camada de apresentação.
- **FR-003 (Implementação JobRemoteDataSource)**: O sistema DEVE implementar `JobRemoteDataSource` consumindo o cliente oficial do Supabase:
  - Consulta à view `v_user_jobs`.
  - Ordenação decrescente padrão por `created_at` (ou `published_at`).
  - Suporte à paginação via `.range(offset, offset + limit - 1)`.
  - Suporte a filtro por igualdade em `status`.
  - Suporte a filtro de texto em `title` ou `company_name` via operador `.or(...)` com `ilike`.
- **FR-004 (Implementação JobRepository)**: O sistema DEVE implementar `JobRepository` delegando as operações à fonte de dados remota e coordenando contratos de domínio.
- **FR-005 (Mutações de Status, Notas e Arquivamento)**: As mutações DEVEM realizar operações de upsert na tabela `user_job_interactions` utilizando `job_id` como identificador de conflito (`onConflict: 'job_id'`).
- **FR-006 (Hierarquia de Exceções de Domínio)**: O sistema DEVE implementar em `lib/core/errors/`:
  - `JobFetchFailure` (para erros de busca de vagas)
  - `JobMutationFailure` (para erros de mutação/upsert)
  - `JobNotFoundFailure` (para busca de vaga individual inexistente)
- **FR-007 (Cobertura de Testes Automatizados)**: DEVEM ser implementados testes unitários com `mocktail` cobrindo cenários de sucesso, paginação, filtros, mutações e tratamento de erros para o data source e o repositório.
- **FR-008 (Qualidade de Código)**: Todo o código DEVE compilar com 0 erros e 0 advertências no `flutter analyze`.

---

### Key Entities

- **JobItem**: Entidade principal de vaga vinda de `v_user_jobs`.
- **UserJobInteraction**: Entidade de mutação persistida em `user_job_interactions`.
- **JobFetchFailure**: Exceção tipada para falhas de leitura no Supabase.
- **JobMutationFailure**: Exceção tipada para falhas de mutação no Supabase.
- **JobNotFoundFailure**: Exceção tipada quando um ID de vaga não é localizado.

---

## 4. Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001 (Conformidade de Análise Estática)**: 100% dos arquivos Dart no projeto executam `flutter analyze` com 0 erros e 0 warnings.
- **SC-002 (Suíte de Testes Automatizados)**: 100% dos testes unitários em `test/features/jobs/data/` e em todo o projeto passam com sucesso em `flutter test`.
- **SC-003 (Cobertura Funcional da Camada de Dados)**: Todos os métodos especificados (`getJobs`, `getJobById`, `updateJobStatus`, `updateJobNotes`, `toggleJobArchived`, `upsertInteraction`) possuem testes unitários dedicados.
- **SC-004 (Mapeamento Estrito de Erros)**: Nenhum erro não tratado de `PostgrestException` escapa das camadas de infraestrutura sem conversão para `JobFetchFailure` ou `JobMutationFailure`.

---

## 5. Assumptions

- A view `v_user_jobs` e a tabela `user_job_interactions` existem no schema público do Supabase configurado via `.env`.
- As credenciais de acesso anon possuem permissões adequadas de leitura em `v_user_jobs` e de upsert em `user_job_interactions` (com RLS configurado no backend).
- O cliente Supabase é acessado via `SupabaseService.client` ou injetado via construtor nos data sources para viabilizar injeção de dependência em testes.

---

## Database Schema & Data Contracts Reference
- **Contrato Canônico de Dados**: [specs/database-schema.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/database-schema.md)
  - Consultas em `JobRemoteDataSource` e mutações na tabela `user_job_interactions` devem seguir estritamente o contrato canônico estabelecido em [database-schema.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/database-schema.md).

