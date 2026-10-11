# Implementation Plan: 002 - Camada de Dados e Repositórios Supabase (`features/jobs`)

**Branch**: `002-job-repository-supabase`  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/002-job-repository-supabase/spec.md)  
**Status**: In Progress  

## Architecture Overview

A funcionalidade `jobs` expande a arquitetura Feature-First implementando as interfaces e serviços da camada de dados:
- **`lib/core/errors/job_failure.dart`**: Declaração das exceções de domínio `JobFetchFailure`, `JobMutationFailure` e `JobNotFoundFailure`.
- **`lib/features/jobs/domain/repositories/job_repository.dart`**: Contrato `IJobRepository` expondo os métodos de leitura e escrita para blocos superiores.
- **`lib/features/jobs/data/datasources/job_remote_datasource.dart`**: Interface `IJobRemoteDataSource` e implementação `JobRemoteDataSource` consumindo `supabase_flutter`.
- **`lib/features/jobs/data/repositories/job_repository_impl.dart`**: Implementação `JobRepository` coordenando data sources remotos.

## Query & Mutation Design

1. **Leitura Paginada e Filtrada (`v_user_jobs`)**:
   - `client.from(AppConstants.userJobsView).select()`
   - Filtro de status: `.eq('status', statusFilter)` se fornecido.
   - Filtro de texto: `.or('title.ilike.%$query%,company_name.ilike.%$query%')` se fornecido.
   - Ordenação: `.order('created_at', ascending: false)`.
   - Paginação: `.range(offset, offset + limit - 1)`.
   - Busca por ID: `.select().eq('job_id', id).maybeSingle()`, lançando `JobNotFoundFailure` caso nulo.

2. **Mutações de Interação (`user_job_interactions`)**:
   - `updateJobStatus`: Upsert com `{'job_id': jobId, 'status': newStatus}`, incluindo `applied_at` em ISO 8601 UTC caso `newStatus == 'applied'`.
   - `updateJobNotes`: Upsert com `{'job_id': jobId, 'notes': notes}`.
   - `toggleJobArchived`: Upsert com `{'job_id': jobId, 'is_archived': isArchived}`.
   - `upsertInteraction`: Upsert com `interaction.toJson()`.
   - Todas as operações de upsert utilizam `onConflict: 'job_id'`.

3. **Mapeamento de Erros**:
   - Captura de `PostgrestException` e `Exception` genéricas.
   - Mapeamento transparente para `JobFetchFailure` ou `JobMutationFailure`.

## Testing Strategy
- Testes unitários para `JobRemoteDataSource` utilizando mocks/fakes do `SupabaseClient` e `PostgrestFilterBuilder` com `mocktail`.
- Testes unitários para `JobRepository` validando delegação e integridade de chamadas.
- Validação estática contínua com `flutter test` e `flutter analyze`.
