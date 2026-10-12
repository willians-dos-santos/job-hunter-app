# Job Hunter App Constitution

## Core Principles

### I. Clean Architecture & Modular Presentation
- A camada de apresentação utiliza estritamente BLoC/Cubit com estados imutáveis (`Equatable` ou `Freezed`).
- Regras de negócio ficam encapsuladas em UseCases/Repositories na camada de domínio.
- O acesso a dados externos é isolado em `DataSources` (Supabase, local storage) implementando contratos da camada de domínio.

### II. Data Contracts & Database-First (NON-NEGOTIABLE)
- É estritamente proibido inventar nomes de colunas, criar aliases não documentados ou alterar payloads de banco sem consultar `specs/database-schema.md`.
- Toda consulta de leitura no Supabase deve se basear exclusivamente na view `public.v_user_jobs`.
- Mutações de interação de vagas devem ser gravadas em `public.user_job_interactions` utilizando a chave composta `(user_id, job_id)` via `upsert(..., onConflict: 'user_id,job_id')`.
- O isolamento multitenant por usuário (`auth.uid()`) é mandatório e nunca deve ser removido de queries ou views.

### III. Quality Gates & Test-First
- Nenhum commit ou PR é aceito sem passar com 0 erros e 0 alertas em `flutter analyze` e `flutter test`.
- Toda nova funcionalidade deve vir acompanhada de testes unitários para Cubits e testes de widgets para componentes visuais.

### IV. Responsive Tablet-First & Slate Theme Consistency
- A interface deve suportar layout responsivo otimizado para tablets e orientação horizontal/vertical sem estouro de layout (`RenderFlex overflowed`).
- Campos de entrada e telas com teclados virtuais devem tratar explicitamente a redução de espaço (`resizeToAvoidBottomInset` e scroll wrappers).
- A paleta de cores deve seguir estritamente o tema Slate escuro.

## Governance
- Esta constituição é a referência suprema para criação de novas specs e implementação de código pelo assistente.
- Qualquer alteração estrutural no banco de dados exige um arquivo `.sql` de migração auditável antes de qualquer mudança no código Dart.

**Version**: 1.0.0 | **Ratified**: 2026-10-12
