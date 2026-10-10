# Feature Specification: 001 - Bootstrap e Arquitetura Frontend

**Feature Branch**: `001-bootstrap-and-architecture`  
**Created**: 2026-10-10  
**Status**: Ready for Review  
**Input**: User description: "Inicialização do frontend do projeto Job Hunter em Flutter com Clean Architecture simplificada (Feature-First), integração Supabase (.env), modelagem de dados (JobItem, SearchConfig, UserJobInteraction), design system com tokens Dark Mode Stitch e baseline de testes e análise estática."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Modelagem de Dados Resiliente e Deserialização (Priority: P1)

Como engenheiro e usuário da aplicação Job Hunter, necessito que as entidades do domínio e seus Data Transfer Objects (DTOs) representem com precisão o esquema de dados do backend Supabase (`v_user_jobs`, `search_configs`, `user_job_interactions`), permitindo deserialização e serialização seguras de dados, com tratamento gracioso de nulos e valores inesperados.

**Why this priority**:
É o alicerce fundamental de toda a camada de domínio e dados do aplicativo. Se os modelos falharem ao parsear dados do Supabase ou mutações forem mal formatadas, nenhuma interface (Kanban, listagem, filtros) funcionará de forma confiável.

**Independent Test**:
Pode ser testado de forma 100% isolada através de suíte de testes unitários em Dart (`test/features/jobs/...` e `test/features/search_configs/...`), alimentando mocks JSON representativos de cenários reais (sucesso, campos nulos, enums desconhecidos) e validando integridade de dados e mutações sem depender de rede ativa.

**Acceptance Scenarios**:

1. **Dado** um payload JSON da view `v_user_jobs` contendo campos completos (`job_id`, `title`, `company_name`, `platform`, `job_url`, `location`, `salary_text`, `status`, `notes`, `applied_at`, `created_at`),  
   **Quando** o método `JobItem.fromJson` for executado,  
   **Então** uma instância válida de `JobItem` deve ser retornada com todos os tipos primitivos e de data convertidos corretamente.

2. **Dado** um payload JSON de `v_user_jobs` onde `salary_text`, `notes` e `applied_at` são nulos,  
   **Quando** `JobItem.fromJson` for executado,  
   **Então** o modelo deve ser instanciado sem exceções, preservando esses campos como `null` e fornecendo fallbacks previsíveis para campos essenciais.

3. **Dado** um payload JSON de `search_configs` com `category` pertencente a (`keyword`, `excluded`, `location`, `company`),  
   **Quando** `SearchConfig.fromJson` for executado,  
   **Então** o enum `SearchConfigCategory` correspondente deve ser atribuído corretamente.

4. **Dado** uma mutação de interação do usuário sobre uma vaga,  
   **Quando** uma entidade `UserJobInteraction` for convertida via `toJson()`,  
   **Então** o payload resultante deve conter as chaves exatas esperadas para o upsert na tabela `user_job_interactions` (`job_id`, `status`, `notes`, `applied_at`).

---

### User Story 2 - Design System com Tokens do Protótipo Stitch Dark Mode (Priority: P1)

Como usuário do Job Hunter operando em múltiplos dispositivos (Web, Desktop Linux ou Android), desejo uma interface com estética Dark Mode de terminal moderno inspirada no protótipo Stitch (Slate escuro, realces Indigo/Cyan e paleta semântica Kanban), garantindo contraste, legibilidade e consistência visual imediata.

**Why this priority**:
Estabelece a identidade visual e os contratos de componentes visuais do aplicativo desde o dia zero, evitando retrabalho futuro de substituição de cores hardcoded e garantindo suporte consistente multiplataforma.

**Independent Test**:
Pode ser testado de forma independente via testes unitários de tema e testes de widget que instanciam o `AppTheme.darkTheme`, verificando a resolução exata dos tokens de cor, esquema de superfícies e `ThemeExtension` para os status do Kanban sem dependência de dados remotos.

**Acceptance Scenarios**:

1. **Dado** que a aplicação é iniciada,  
   **Quando** o tema base for aplicado,  
   **Então** o background da aplicação deve utilizar a cor Slate 900 (`#0F172A`), os cartões/superfícies utilizam Slate 800 (`#0F1E2E` / `#1E293B`), e as bordas utilizam Slate 700 (`#334155`).

2. **Dado** a necessidade de estilizar componentes de status de candidatura (Kanban),  
   **Quando** a extensão semântica de cores do tema for consultada para um status específico,  
   **Então** as cores retornadas devem ser:
     - `new`: Cyan terminal (`#38BDF8`)
     - `applied`: Violet (`#8B5CF6`)
     - `interview`: Amber (`#F59E0B`)
     - `offer`: Emerald (`#10B981`)
     - `rejected`: Rose (`#F43F5E`).

3. **Dado** elementos interativos primários e cabeçalhos de destaque,  
   **Quando** renderizados pelo tema,  
   **Então** devem apresentar variantes das cores primárias Indigo (`#6366F1`) e Cyan terminal (`#38BDF8`), com tipografia moderna e legível.

---

### User Story 3 - Inicialização do Supabase & Gestão Segura de Configuração (Priority: P2)

Como desenvolvedor e operador da plataforma, necessito que as credenciais do backend (Supabase URL e Anon Key) sejam carregadas via arquivo de ambiente `.env` e inicializadas através de um serviço singleton encapsulado em `core/services/`, prevenindo que chaves fiquem expostas no código-fonte e fornecendo mensagens de erro informativas caso as configurações estejam ausentes.

**Why this priority**:
Necessário para a comunicação segura com o banco de dados em produção e homologação, permitindo alternar ambientes facilmente via variáveis de configuração locais.

**Independent Test**:
Pode ser testado isoladamente carregando um arquivo mock de ambiente `.env.example` e validando o serviço de configuração `EnvConfig` / `SupabaseService` com injeção de dependência e tratamento de falhas em inicialização ausente.

**Acceptance Scenarios**:

1. **Dado** um arquivo `.env` preenchido com `SUPABASE_URL` e `SUPABASE_ANON_KEY` válidos,  
   **Quando** a rotina de bootstrap do app for executada,  
   **Então** as variáveis devem ser lidas com sucesso e o cliente Supabase inicializado e disponibilizado globalmente para injeção.

2. **Dado** um ambiente onde o arquivo `.env` não existe ou omite chaves obrigatórias,  
   **Quando** a rotina de bootstrap for executada,  
   **Então** o sistema deve lançar um erro descritivo (`ConfigurationException`), instruindo o desenvolvedor a configurar o `.env` a partir do template `.env.example`.

---

### User Story 4 - Estrutura Arquitetural Modular (Feature-First) e Baseline de Qualidade (Priority: P2)

Como equipe de engenharia, preciso que a árvore de diretórios do projeto siga o padrão Feature-First com Clean Architecture simplificada dividida em `core/` e `features/`, com suporte a Flutter BLoC / Cubit e análise estática rigorosa (`flutter analyze` sem alertas ou erros).

**Why this priority**:
Garante manutenibilidade, desacoplamento e escalabilidade do código à medida que novas telas e funcionalidades (Kanban board, listagem detalhada, gerenciador de tags de busca) forem desenvolvidas nas próximas specs.

**Independent Test**:
Pode ser testado via execução do comando `flutter analyze` e verificação da estrutura de pastas em conformidade com as regras arquiteturais estabelecidas.

**Acceptance Scenarios**:

1. **Dado** o repositório do projeto,  
   **Quando** a estrutura de diretórios for inspecionada,  
   **Então** deve conter:
     - `lib/core/constants/` e `lib/core/theme/` (design tokens, tema dark)
     - `lib/core/services/` (inicialização de supabase e ambiente)
     - `lib/core/errors/` (tratamento padronizado de exceções e falhas)
     - `lib/features/jobs/` com camadas `domain/`, `data/` e `presentation/`
     - `lib/features/search_configs/` com camadas `domain/`, `data/` e `presentation/`.

2. **Dado** o código implementado na spec 001,  
   **Quando** executado o linter oficial `flutter analyze`,  
   **Então** o resultado deve ser concluído com zero erros (`0 issues found`).

---

### Edge Cases

- **Nulos inesperados da view `v_user_jobs`**: O backend pode retornar vagas antigas com `location`, `salary_text` ou `platform` nulos. Os modelos Dart devem tratar todos esses campos como `String?` com getters utilitários para exibição amigável (e.g. `displaySalary` retornando "Não informado" ou string limpa).
- **Enums desconhecidos no backend**: Se uma nova categoria for inserida em `search_configs` ou um novo status for atribuído no banco que o frontend ainda não mapeou, o enum parser não deve lançar exceção não tratada; deve fazer fallback gracioso para `unknown` ou valor padrão seguro (`SearchConfigCategory.keyword` / `JobStatus.newJob`).
- **Data/Hora em fusos divergentes**: O campo `applied_at` e `created_at` trafega em ISO 8601 UTC. O parser deve garantir conversão correta para `DateTime` e formatação local sem quebras de timezone.
- **Ambiente Web e Desktop**: O carregamento de `.env` e persistência local deve ser compatível com Flutter Web e Linux Desktop sem falhas de I/O de plataforma.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001 (Arquitetura & Organização)**: O código da aplicação DEVE ser organizado no padrão Feature-First com Clean Architecture simplificada, segregado em `lib/core/` (compartilhado e infraestrutura) e `lib/features/` (módulos verticais de negócio: `jobs`, `search_configs`).
- **FR-002 (Gerenciamento de Estado)**: A fundação arquitetural DEVE adotar Flutter BLoC / Cubit (`flutter_bloc: ^9.1.1`) para fluxo unidirecional de dados e reatividade em todas as features.
- **FR-003 (Gestão de Ambiente)**: O sistema DEVE carregar chaves de configuração sensíveis (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) através do pacote `flutter_dotenv` via arquivo `.env`, fornecendo um arquivo de exemplo `.env.example` versionado no repositório.
- **FR-004 (Inicialização Supabase)**: O sistema DEVE fornecer um wrapper/serviço `SupabaseService` capaz de inicializar o `Supabase.initialize` no bootstrap da aplicação (`main.dart`).
- **FR-005 (Modelagem JobItem)**: O sistema DEVE implementar a entidade/modelo `JobItem` com mapeamento estrito dos campos da View `v_user_jobs`:
  - `jobId` (`String` / `int`, identificador único da vaga)
  - `title` (`String`)
  - `companyName` (`String`)
  - `platform` (`String`)
  - `jobUrl` (`String`)
  - `location` (`String?`)
  - `salaryText` (`String?`)
  - `status` (`JobStatus` enum: `new`, `applied`, `interview`, `offer`, `rejected`)
  - `notes` (`String?`)
  - `appliedAt` (`DateTime?`)
  - `createdAt` (`DateTime`)
- **FR-006 (Modelagem SearchConfig)**: O sistema DEVE implementar a entidade/modelo `SearchConfig` mapeando a tabela `search_configs`:
  - `id` (`int` / `String`)
  - `category` (`SearchConfigCategory` enum: `keyword`, `excluded`, `location`, `company`)
  - `value` (`String`)
  - `isActive` (`bool`)
- **FR-007 (Mutações de Interação)**: O sistema DEVE implementar o modelo `UserJobInteraction` para operações de upsert na tabela `user_job_interactions`:
  - `jobId`
  - `status` (`JobStatus`)
  - `notes` (`String?`)
  - `appliedAt` (`DateTime?`)
  - Método `toJson()` gerando o formato exato esperado pela API do Supabase.
- **FR-008 (Design Tokens de Tema)**: O sistema DEVE disponibilizar uma classe de tokens de design `AppColors` e uma configuração de tema `AppTheme.darkTheme` seguindo as especificações do protótipo Stitch:
  - Background: Slate 900 (`#0F172A`)
  - Surfaces & Cards: Slate 800 (`#0F1E2E` e `#1E293B`)
  - Borders: Slate 700 (`#334155`)
  - Primary / Accent: Indigo (`#6366F1`) e Terminal Cyan (`#38BDF8`)
  - Textos: White (`#FFFFFF`), Slate 300 (`#CBD5E1`), Slate 400 (`#94A3B8`).
- **FR-009 (Extensão de Cores Semânticas do Kanban)**: O tema DEVE expor um `ThemeExtension` (`KanbanStatusColors` ou equivalente) acessível pelo contexto do Flutter para coloração consistente dos status:
  - New: Cyan (`#38BDF8`)
  - Applied: Violet (`#8B5CF6`)
  - Interview: Amber (`#F59E0B`)
  - Offer: Emerald (`#10B981`)
  - Rejected: Rose (`#F43F5E`).
- **FR-010 (Tipografia)**: O tema DEVE configurar a tipografia utilizando a família de fontes Inter (via `google_fonts`) para corpo de texto e suporte monoespaçado (`JetBrains Mono` ou Roboto Mono) para códigos ou termos técnicos de terminal.
- **FR-011 (Imutabilidade & Métodos de Suporte)**: Todos os modelos de domínio DEVEM ser imutáveis e implementar `copyWith`, `==`, `hashCode` e métodos auxiliares para serialização (`fromJson` e `toJson`).
- **FR-012 (Qualidade de Código)**: Todo o código introduzido DEVE compilar e passar integralmente na análise estática `flutter analyze` sem nenhum erro ou advertência (zero warnings).
- **FR-013 (Cobertura de Testes Unitários)**: DEVEM ser fornecidos testes unitários cobrindo todos os métodos de serialização e parsing com fixtures/mocks JSON para `JobItem`, `SearchConfig`, `UserJobInteraction` e validação dos tokens de tema.

---

### Key Entities *(include if feature involves data)*

- **JobItem**: Representa uma vaga de emprego enriquecida com a interação individual do usuário, originária da view `v_user_jobs`.
  - Atributos: `jobId`, `title`, `companyName`, `platform`, `jobUrl`, `location`, `salaryText`, `status`, `notes`, `appliedAt`, `createdAt`.
  - Regras: `status` padroniza para `new` caso ausente; `createdAt` obrigatório; campos de texto adicionais suportam nulos com fallback seguro.
- **SearchConfig**: Representa um critério configurável de busca ou filtro cadastrado pelo usuário na tabela `search_configs`.
  - Atributos: `id`, `category` (`SearchConfigCategory`), `value`, `isActive`.
  - Regras: Categoria restrita ao conjunto `{keyword, excluded, location, company}`; `isActive` default `true`.
- **UserJobInteraction**: Representa a mutação enviada pelo usuário (candidatura, avanço no funil, anotações de entrevista) gravada na tabela `user_job_interactions`.
  - Atributos: `jobId`, `status`, `notes`, `appliedAt`.
  - Regras: Utilizado para operações de upsert; `appliedAt` é preenchido automaticamente quando o status transiciona para `applied` caso ainda não definido.
- **KanbanStatusColors & AppThemeTokens**: Estrutura de tokens visuais que mapeia paletas semânticas para o design system dark mode.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001 (Conformidade de Análise Estática)**: 100% dos arquivos Dart no projeto executam `flutter analyze` com 0 erros e 0 warnings.
- **SC-002 (Cobertura de Modelagem)**: 100% dos modelos de dados (`JobItem`, `SearchConfig`, `UserJobInteraction`) possuem testes unitários automatizados cobrindo parsing de JSON completo, tratamento de campos nulos e conversão reversa para JSON.
- **SC-003 (Fidelidade Visual do Tema)**: O tema Dark Mode configurado reflete 100% dos tokens de cores especificados (Slate 900, Slate 800, Slate 700, Indigo, Cyan e as 5 cores semânticas do Kanban), testado programaticamente via suíte de testes de tema.
- **SC-004 (Tempo de Inicialização de Ambiente)**: A rotina de bootstrap com leitura de `.env` e registro do cliente Supabase executa em menos de 100 milissegundos em ambiente local.
- **SC-005 (Multiplataforma)**: O código e as dependências compilam e resolvem sem erros nas plataformas alvo: Flutter Web, Desktop Linux e Android.

---

## Assumptions

- O projeto executará sobre Flutter 3.x com Dart SDK ^3.9.2 (conforme configurado em `pubspec.yaml`).
- O banco de dados Supabase já possui ou receberá a view `v_user_jobs`, a tabela `search_configs` e a tabela `user_job_interactions` compatíveis com os campos mapeados nesta spec.
- O arquivo `.env` conterá as chaves `SUPABASE_URL` e `SUPABASE_ANON_KEY`, enquanto um `.env.example` conterá instruções de preenchimento.
- A tela inicial nesta etapa inicial de bootstrap será um esqueleto funcional limpo exibindo o tema dark aplicado e o status de conexão/carregamento, preparando o terreno para a implementação das telas completas nas especificações subsequentes.
