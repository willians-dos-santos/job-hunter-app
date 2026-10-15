# Database Schema & Data Contracts (Supabase / PostgreSQL)

## 1. Tabelas Físicas

### `public.jobs`
Tabela canônica com as oportunidades coletadas pelos crawlers/scrapers.
- `id` (`text`, PK) - Identificador composto canônico (`{ats}:{external_id}` ou `solides_{id}`)
- `ats` (`text`, not null) - Plataforma de origem (`greenhouse`, `lever`, `gupy`, `solides`)
- `external_id` (`text`, not null) - Identificador original na API de origem
- `title` (`text`, not null) - Título da vaga
- `company` (`text`, not null) - Nome da empresa contratante
- `location` (`text`, nullable) - Localização normalizada ou nulo
- `url` (`text`, not null) - URL pública canônica da vaga
- `published_at` (`timestamptz`, nullable) - Data de publicação original
- `created_at` (`timestamptz`, default `now()`) - Data de persistência no banco
- `dedup_key` (`text`, unique) - Hash semântico SHA-256 para controle de duplicatas

### `public.user_job_interactions`
Interações, anotações e status do usuário autenticado no funil Kanban.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `user_id` (`uuid`, FK `auth.users(id)` ON DELETE CASCADE)
- `job_id` (`text`, FK `public.jobs(id)` ON DELETE CASCADE)
- `status` (`text`, check: `'applied'`, `'interviewing'`, `'offer'`, `'rejected'`, `'archived'`)
- `notes` (`text`, nullable) - Anotações livres sobre o processo
- `applied_at` (`timestamptz`, nullable) - Data de candidatura informada
- `is_archived` (`bool`, default `false`, not null) - Flag para arquivamento
- `created_at` (`timestamptz`, default `now()`)
- `updated_at` (`timestamptz`)
- **Restrição Única:** `UNIQUE (user_id, job_id)`

### `public.search_configs`
Configurações dinâmicas de busca, filtros de ATS e termos excluídos por usuário.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `user_id` (`uuid`, FK `auth.users(id)` ON DELETE CASCADE)
- `category` (`text`, check: `'keyword'`, `'excluded_keyword'`, `'location'`, `'company'`, `'ats_filter'`)
- `value` (`text`, not null) - Termo ou identificador (ex: `'python'`, `'solides'`)
- `is_active` (`bool`, default `true`, not null) - Habilita/desabilita no ciclo de crawling
- `metadata` (`jsonb`, default `'{}'::jsonb`) - Configurações extras
- `created_at` (`timestamptz`, default `now()`)

---

## 2. Views de Consulta (Fontes de Leitura do App Flutter)

Ambas as views retornam exatamente o mesmo contrato de campos do `JobModel` no Flutter e filtram os dados automaticamente pelo usuário logado (`auth.uid()`):

### Contrato de Colunas Compartilhado
- `job_id` (`text`)
- `title` (`text`)
- `company_name` (`text`)
- `platform` (`text`)
- `job_url` (`text`)
- `location` (`text`, nullable)
- `salary_text` (`text`, nullable)
- `status` (`text`)
- `notes` (`text`, nullable)
- `applied_at` (`timestamptz`, nullable)
- `published_at` (`timestamptz`, nullable)
- `created_at` (`timestamptz`)
- `user_id` (`uuid`, nullable)
- `is_archived` (`bool`)
- `interaction_updated_at` (`timestamptz`, nullable)

---

### `public.v_new_jobs` (Inbox de Triagem)
- **Finalidade:** Alimenta a coluna **"Nova"** do quadro Kanban.
- **Regra:** Retorna oportunidades da tabela `public.jobs` que **não possuem** nenhum registro em `public.user_job_interactions` para o `auth.uid()`.
- **Status:** Sempre `'new'`.
- **Modo de Consulta:** Suporta paginação dedicada com `limit` e `range` no Flutter.

### `public.v_active_pipeline_jobs` (Funil Ativo)
- **Finalidade:** Alimenta as colunas em andamento do Kanban (`applied`, `interviewing`, `offer`, `rejected`).
- **Regra:** Retorna as vagas com `INNER JOIN` em `public.user_job_interactions` onde `is_archived = false` para o `auth.uid()`.
- **Status:** O status real da interação do usuário.
- **Modo de Consulta:** Consulta sem limite restritivo de paginação (traz o pipeline ativo em andamento).

---

## 3. Regras Mandatórias de Persistência e Consumo

1. **Leitura Padronizada:** O `JobRemoteDataSource` no Flutter deve buscar as novas vagas exclusivamente em `v_new_jobs` (com paginação) e as vagas em andamento em `v_active_pipeline_jobs`.
2. **Mutações:** Arrastar cards ou alterar anotações grava diretamente na tabela física `public.user_job_interactions` via `upsert` com a chave composta `(user_id, job_id)`.
3. **Imutabilidade de Colunas:** Nenhuma coluna deve ser renomeada ou omitida das views para não quebrar a desserialização do `JobModel.fromJson`.