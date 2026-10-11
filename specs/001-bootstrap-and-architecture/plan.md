# Implementation Plan: 001 - Bootstrap e Arquitetura Frontend

**Branch**: `001-bootstrap-and-architecture`  
**Spec**: [spec.md](file:///home/willians/workspace/flutter/job_hunter_app/specs/001-bootstrap-and-architecture/spec.md)  
**Status**: Completed  

## Architecture Overview

O projeto adota Clean Architecture simplificada estruturada no padrão Feature-First:
- **`lib/core/`**: Infraestrutura transversal compartilhada (tema Dark Mode Stitch, tokens, constantes de banco, serviços de ambiente e Supabase, hierarquia de exceções).
- **`lib/features/jobs/`**: Módulo de vagas (`domain`, `data`, `presentation` com BLoC/Cubit), modelando a view `v_user_jobs` e mutações em `user_job_interactions`.
- **`lib/features/search_configs/`**: Módulo de critérios de busca e filtros configuráveis (`domain`, `data`, `presentation`).

## Design Tokens & Theme (Stitch Dark Mode)
- **Background**: Slate 900 (`#0F172A`)
- **Surfaces & Cards**: Slate 800 (`#1E293B`) e Slate 850 (`#0F1E2E`)
- **Borders & Dividers**: Slate 700 (`#334155`)
- **Accents**: Primary Indigo (`#6366F1`) e Terminal Cyan (`#38BDF8`)
- **ThemeExtension**: `KanbanStatusColors` para coloração semântica dos estágios do funil:
  - `new`: Cyan (`#38BDF8`)
  - `applied`: Violet (`#8B5CF6`)
  - `interview`: Amber (`#F59E0B`)
  - `offer`: Emerald (`#10B981`)
  - `rejected`: Rose (`#F43F5E`)
- **Tipografia**: Família Inter para interface e tipografia monoespaçada (JetBrains Mono) para códigos e badges de terminal.

## Data Schema & Models
- `JobItem`: Mapeia view `v_user_jobs` com getters utilitários para fallbacks amigáveis (`displaySalary`, `displayLocation`, `displayNotes`) e fallback em status desconhecidos para `JobStatus.newJob`.
- `SearchConfig`: Mapeia tabela `search_configs` com enum `SearchConfigCategory` (`keyword`, `excluded`, `location`, `company`).
- `UserJobInteraction`: Mapeia mutações para upsert na tabela `user_job_interactions` (`toJson()`), preenchendo automaticamente `appliedAt` ao transicionar para `applied`.

## Quality & Test Gates
- Análise estática rigorosa via `flutter analyze` com zero erros e zero advertências.
- Suíte completa de testes unitários e de widget com mocks e fixtures JSON.
