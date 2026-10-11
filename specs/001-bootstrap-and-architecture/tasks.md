# Tasks: 001 - Bootstrap e Arquitetura Frontend

**Branch**: `001-bootstrap-and-architecture`  
**Plan**: [plan.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/001-bootstrap-and-architecture/plan.md)  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/001-bootstrap-and-architecture/spec.md)  

## Phase 1: Setup & Environment
- [x] T01: Criar template `.env.example` e registrar `.env` nos assets do `pubspec.yaml`
- [x] T02: Implementar hierarquia de exceções em `lib/core/errors/` (`AppException`, `ConfigurationException`)
- [x] T03: Implementar constantes em `lib/core/constants/` (`AppConstants`, `EnvConstants`)
- [x] T04: Implementar serviço seguro de ambiente `EnvConfig` em `lib/core/services/`
- [x] T05: Implementar wrapper de inicialização `SupabaseService` em `lib/core/services/`

## Phase 2: Design System & Dark Theme (Stitch Terminal)
- [x] T06: Definir tokens de cores `AppColors` em `lib/core/theme/`
- [x] T07: Implementar `KanbanStatusColors` como `ThemeExtension` para os status semânticos do Kanban
- [x] T08: Configurar tipografia com Inter e JetBrains Mono em `AppTypography`
- [x] T09: Configurar `AppTheme.darkTheme` com tokens Slate 900, Slate 800, Slate 700 e realces Indigo/Cyan

## Phase 3: Domain Models & DTOs
- [x] T10: Implementar enum `JobStatus` com fallback gracioso para `JobStatus.newJob`
- [x] T11: Implementar entidade/modelo `JobItem` com parsing resiliente de `v_user_jobs` e helpers de display
- [x] T12: Implementar modelo `UserJobInteraction` para mutações de upsert em `user_job_interactions`
- [x] T13: Implementar enum `SearchConfigCategory` e modelo `SearchConfig` mapeando `search_configs`

## Phase 4: Clean Architecture Layer Structure
- [x] T14: Configurar camadas `domain/`, `data/` e `presentation/` para `features/jobs/` (Repository, DataSource, Cubit)
- [x] T15: Configurar camadas `domain/`, `data/` e `presentation/` para `features/search_configs/` (Repository, DataSource, Cubit)
- [x] T16: Atualizar `lib/main.dart` com rotina resiliente de bootstrap e tela diagnóstica informativa

## Phase 5: Verification & Quality Assurance
- [x] T17: Criar testes unitários para tokens de tema e `KanbanStatusColors`
- [x] T18: Criar testes unitários para `EnvConfig`, `ConfigurationException` e `SupabaseService`
- [x] T19: Criar testes unitários com mocks JSON para `JobItem`, `UserJobInteraction` e `SearchConfig`
- [x] T20: Criar testes unitários para arquitetura (Repository, Cubit) e testes de widget (`JobHunterApp`)
- [x] T21: Validar execução de `flutter test` com 100% de sucesso (46 testes aprovados)
- [x] T22: Validar execução de `flutter analyze` com 0 erros e 0 advertências
