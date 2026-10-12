# Feature Specification: 009 - Gestão de Critérios e Filtros de Busca (`features/search_configs`)

**Feature Branch**: `009-search-configs-management`  
**Created**: 2026-10-12  
**Status**: Ready for Review  
**Input**: User description: "Implementação da Spec 009 (funcionalidade final do MVP) para gerenciamento completo dos critérios de busca na tabela public.search_configs, com Cubit Equatable, interface SearchConfigsScreen categorizada em Chips ('keyword', 'excluded_keyword', 'ats_filter', 'location'), atalho no AppBar do Kanban e proteção contra overflow de teclado virtual sob o tema Slate."

---

# Spec 009: Gestão de Critérios de Busca (`features/search_configs`)

## 1. Contexto e Objetivos
Permitir que o candidato configure e personalize as regras automatizadas de busca e filtragem de vagas através da tabela `public.search_configs`, organizando os critérios em categorias semânticas ('keyword', 'excluded_keyword', 'ats_filter', 'location'), possibilitando inclusão rápida, ativação/desativação pontual e exclusão de termos.

## 2. Contrato de Dados & Persistência (Governança)
- **Tabela Física Canônica:** `specs/database-schema.md#public.search_configs`
  - `id` (uuid, PK)
  - `user_id` (uuid, FK auth.users(id) ON DELETE CASCADE)
  - `category` (text, check: `'keyword'`, `'excluded_keyword'`, `'location'`, `'company'`, `'ats_filter'`)
  - `value` (text, not null)
  - `is_active` (bool, default true)
  - `metadata` (jsonb, nullable)
- **Regras Mandatórias de Isolamento:**
  - Multi-tenancy restrito por `auth.uid()` / `user_id`.
  - Valores de `category` devem obedecer estritamente a restrição de integridade do PostgreSQL.
  - Ao inserir um novo critério sem ID prévio, o banco gera o identificador UUID padrão.

## 3. Requisitos Funcionais
- **Ponto de Entrada (Kanban AppBar):**
  - Ícone de configuração (`Icons.tune_rounded` ou equivalente) na AppBar principal do quadro Kanban navegando para `SearchConfigsScreen`.
- **Categorização em Grupos de Chips:**
  - `keyword` ("Palavras-chave"): Termos obrigatórios para busca de vagas (ex: Flutter, Dart, Tech Lead).
  - `excluded_keyword` ("Termos Excluídos"): Termos indesejados para filtragem negativa (ex: Presencial, PHP Sênior).
  - `ats_filter` ("Filtros ATS"): Plataformas de recrutamento aceitas ou filtradas (ex: Greenhouse, Lever, Gupy).
  - `location` ("Localizações"): Cidades, estados ou modalidades geográficas (ex: Remoto, São Paulo, Híbrido).
- **Ações no Ecrã `SearchConfigsScreen`:**
  - **Adicionar Novo Termo:** Formulário com seleção da categoria alvo e campo de texto com botão de submissão.
  - **Alternar Estado Ativo:** Toque no Chip alterna entre ativo (`is_active: true`) e inativo (`is_active: false`), persistindo a alteração no banco e atualizando o feedback visual.
  - **Remover Registro:** Ícone de remoção no Chip remove o registro correspondente da tabela `public.search_configs`.
  - **Atualizar Dados:** Botão de recarregamento manual na AppBar.
- **Proteção de Layout & Design System:**
  - Proteção contra teclado virtual utilizando `SingleChildScrollView` e `resizeToAvoidBottomInset: true` no Scaffold, prevenindo qualquer ocorrência de `RenderFlex overflowed`.
  - Aderência estrita à paleta Slate escuro (`Slate 900`, `Slate 850`, `Slate 800`, `Slate 700`) e realces Indigo/Cyan.
  - Estados contextuais de Loading, Error e Empty perfeitamente tratados.

## 4. Testes e Validação
- Testes unitários para `SearchConfigsCubit` cobrindo carregamento, inserção, alteração de status ativo e exclusão.
- Testes de DataSource e Repository validando conformidade com o esquema de dados.
- Testes de widget para `SearchConfigsScreen` cobrindo renderização, agrupamento de chips, alternância de estado ativo, exclusão, submissão de formulário e imunidade a overflow com teclado aberto.
- 0 erros e 0 alertas em `flutter analyze` e `flutter test`.
