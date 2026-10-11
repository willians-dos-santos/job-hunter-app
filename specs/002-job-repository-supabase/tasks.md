# Tasks: 002 - Camada de Dados e Repositórios Supabase (`features/jobs`)

**Branch**: `002-job-repository-supabase`  
**Plan**: [plan.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/002-job-repository-supabase/plan.md)  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/002-job-repository-supabase/spec.md)  

## Phase 1: Core Domain Exceptions
- [x] T01: Implementar `JobFetchFailure`, `JobMutationFailure` e `JobNotFoundFailure` em `lib/core/errors/job_failure.dart`
- [x] T02: Re-exportar falhas em `lib/core/errors/app_exception.dart`

## Phase 2: Domain Contracts & Model Enhancements
- [x] T03: Suportar campos `isArchived` e `publishedAt` nos modelos `JobItem` e `UserJobInteraction`
- [x] T04: Criar interface `IJobRepository` em `lib/features/jobs/domain/repositories/job_repository.dart`

## Phase 3: Data Source & Repository Implementation
- [x] T05: Implementar interface `IJobRemoteDataSource` e classe `JobRemoteDataSource` com consumo Supabase em `lib/features/jobs/data/datasources/job_remote_datasource.dart`
- [x] T06: Implementar classe `JobRepository` em `lib/features/jobs/data/repositories/job_repository_impl.dart`
- [x] T07: Manter retrocompatibilidade de exports em `jobs_repository.dart`, `jobs_remote_datasource.dart` e `jobs_repository_impl.dart`

## Phase 4: Unit Testing & Mocks
- [x] T08: Criar helpers e fakes de teste para Supabase Postgrest Filter/Transform em `test/features/jobs/data/helpers/`
- [x] T09: Criar testes unitários para `JobRemoteDataSource` em `test/features/jobs/data/datasources/job_remote_datasource_test.dart`
- [x] T10: Criar testes unitários para `JobRepository` em `test/features/jobs/data/repositories/job_repository_test.dart`

## Phase 5: Verification & Validation
- [x] T11: Executar `flutter test` e assegurar 100% de testes passando (81 testes aprovados)
- [x] T12: Executar `flutter analyze` e garantir 0 erros e 0 advertências
