# Database Schema & Data Contracts (Supabase / PostgreSQL)

## 1. Tabelas Físicas

### `public.jobs`
Tabela com as vagas coletadas pelos crawlers/scrapers.
- `id` (text, PK)
- `ats` (text, not null)
- `external_id` (text, not null)
- `title` (text, not null)
- `company` (text, not null)
- `location` (text, nullable)
- `url` (text, not null)
- `published_at` (timestamptz, nullable)
- `created_at` (timestamptz, default now())
- `dedup_key` (text, unique)

### `public.user_job_interactions`
Interações, anotações e status definidos pelo usuário autenticado.
- `id` (uuid, PK, gen_random_uuid())
- `user_id` (uuid, FK auth.users(id) ON DELETE CASCADE)
- `job_id` (text, FK public.jobs(id) ON DELETE CASCADE)
- `status` (text, check: 'new', 'applied', 'interviewing', 'offer', 'rejected', 'archived')
- `notes` (text, nullable)
- `applied_at` (timestamptz, nullable)
- `is_archived` (bool, default false, not null)
- `created_at` (timestamptz, default now())
- `updated_at` (timestamptz, trigger tr_user_job_interactions_updated_at)
- **Constraint única:** `UNIQUE (user_id, job_id)`

### `public.search_configs`
Configurações e termos de busca cadastrados pelo usuário.
- `id` (uuid, PK)
- `user_id` (uuid, FK auth.users(id) ON DELETE CASCADE)
- `category` (text, check: 'keyword', 'excluded_keyword', 'location', 'company', 'ats_filter')
- `value` (text)
- `is_active` (bool, default true)
- `metadata` (jsonb)

---

## 2. Views de Consulta

### `public.v_user_jobs` (Fonte de Leitura do App)
View otimizada para o Flutter consumida pelo `JobRemoteDataSource`.
- `job_id` (text)
- `title` (text)
- `company_name` (text, origin: `jobs.company`)
- `platform` (text, origin: `jobs.ats`)
- `job_url` (text, origin: `jobs.url`)
- `location` (text)
- `salary_text` (text, nullable, origin: NULL::text)
- `status` (text, default: 'new')
- `notes` (text, nullable)
- `applied_at` (timestamptz, nullable)
- `published_at` (timestamptz, nullable)
- `created_at` (timestamptz)
- `user_id` (uuid, nullable)
- `is_archived` (bool, default: false)
- `interaction_updated_at` (timestamptz, nullable)
- **Multi-Tenancy:** Junção com `user_job_interactions` filtrada estritamente por `auth.uid()`.

---

## 3. Regras Mandatórias para Novas Specs e Código Dart
1. Qualquer consulta ao Supabase no `JobRemoteDataSource` deve utilizar exatamente as colunas listadas em `public.v_user_jobs`.
2. Mutações de interação (status, notas, arquivamento) devem gravar na tabela `user_job_interactions` utilizando a chave composta `(user_id, job_id)` no `upsert(..., onConflict: 'user_id,job_id')`.
3. Nunca renomeie ou presuma colunas fora deste documento sem gerar a migração SQL correspondente.
