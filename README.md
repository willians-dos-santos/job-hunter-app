# Job Hunter

<p align="center">
  <img src="assets/icons/app_icon.png" width="128" height="128" alt="Job Hunter Logo" style="border-radius: 24px;" />
</p>

<p align="center">
  <strong>Rastreador inteligente de vagas e gerenciador ágil de candidaturas focado em produtividade para profissionais de tecnologia.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9.2+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.9.2+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Architecture-Clean%20%2F%20Feature--First-7C3AED?style=for-the-badge" alt="Clean Architecture" />
  <img src="https://img.shields.io/badge/State-Bloc%20%2F%20Cubit-2563EB?style=for-the-badge" alt="Bloc/Cubit" />
  <img src="https://img.shields.io/badge/Tests-285%20Passing-10B981?style=for-the-badge" alt="Tests" />
  <img src="https://img.shields.io/badge/License-MIT-F59E0B?style=for-the-badge" alt="License MIT" />
</p>

---

## 📋 Sumário

- [Visão Geral](#-visão-geral)
- [Funcionalidades Principais](#-funcionalidades-principais)
- [Design System & Experiência Visual](#-design-system--experiência-visual)
- [Arquitetura & Engenharia de Software](#-arquitetura--engenharia-de-software)
- [Modelagem de Dados & Backend (Supabase)](#-modelagem-de-dados--backend-supabase)
- [Estrutura de Diretórios](#-estrutura-de-diretórios)
- [Guia de Instalação e Execução](#-guia-de-instalação-e-execução)
- [Qualidade de Código e Testes](#-qualidade-de-código-e-testes)
- [Licença](#-licença)

---

## 🔭 Visão Geral

O **Job Hunter** é um aplicativo mobile e tablet desenvolvido em Flutter para gerenciar e acompanhar processos seletivos de ponta a ponta. Ele atua em conjunto com crawlers automatizados que coletam oportunidades em múltiplos ATSs (*Applicant Tracking Systems* como Gupy, Greenhouse, Lever, Workable e portais corporativos).

Com uma interface moderna inspirada em painéis de alta produtividade (tema escuro *Slate*), o aplicativo permite que o usuário organize suas oportunidades em um funil Kanban interativo, registre anotações detalhadas de entrevistas, analise taxas de conversão por etapa e configure palavras-chave para refinar buscas futuras.

---

## ✨ Funcionalidades Principais

### 1. Quadro Kanban com Drag-and-Drop e Atualização Otimista
- **5 Colunas do Funil:**
  - 🔵 **Salva (`new`):** Oportunidades identificadas e salvas para avaliação.
  - 🟣 **Aplicada (`applied`):** Currículo enviado / candidatura submetida.
  - 🟡 **Entrevista (`interviewing`):** Etapas de triagem, entrevistas técnicas e testes práticos.
  - 🟢 **Oferta (`offer`):** Propostas formais recebidas.
  - 🔴 **Rejeitada (`rejected`):** Processos encerrados ou não selecionados.
- **Interação Fluida:** Suporte a arraste entre colunas (*Drag-and-Drop*) com animação nativa e menu de ações em cada card para mudança rápida de etapa.
- **Atualização Otimista:** A interface reflete imediatamente qualquer alteração de status. Em caso de falha de conexão com o banco, o estado anterior é restaurado automaticamente (*rollback*) com aviso descritivo via `SnackBar`.
- **Modal de Detalhes da Vaga:** Visualização completa da descrição, empresa, plataforma ATS, data de publicação, link direto para a candidatura externa e campo persistente para anotações personalizadas do usuário.

### 2. Busca e Filtros Contextuais
- **Busca com Debounce (~400ms):** Filtragem instantânea por cargo, nível ou nome da empresa sem travamentos na interface.
- **Chips de Modalidade:** Filtro rápido por tipo de jornada: **Remoto**, **Híbrido** e **Presencial**.
- **Contador Dinâmico:** Exibe a contagem exata de vagas visíveis em relação ao total ativo no funil.

### 3. Dashboard Analítico de Métricas (`AnalyticsDashboardScreen`)
- **Indicadores Chave (KPIs):**
  - **Total Ativo no Funil:** Quantidade de processos atualmente em andamento.
  - **Entrevistas & Ofertas:** Oportunidades em fases avançadas de contratação.
  - **Vagas Arquivadas:** Histórico de vagas guardadas fora do funil operacional.
  - **Taxa Geral de Conversão:** Percentual de candidaturas que evoluíram para entrevistas e propostas.
- **Funil Visual de Conversão:** Gráfico comparativo demonstrando a perda e passagem de candidatos por cada etapa do processo seletivo.
- **Resumo de Histórico:** Monitoramento de vagas encerradas e índice de sucesso.

### 4. Gestão de Configurações de Busca (`SearchConfigsScreen`)
- Interface dedicada para gerenciar parâmetros utilizados pelos crawlers e robôs de busca.
- Organização em categorias com chips temáticos:
  - 🔍 **Palavras-chave (`keyword`):** ex.: *Flutter*, *Mobile*, *Dart*.
  - 🚫 **Termos Excluídos (`excluded_keyword`):** ex.: *Presencial*, *Estágio*, *PHP*.
  - 🌐 **Filtros de ATS (`ats_filter`):** ex.: *greenhouse*, *lever*, *gupy*.
  - 📍 **Localização (`location`):** ex.: *Remoto*, *São Paulo*, *Brasil*.
  - 🏢 **Empresas (`company`):** ex.: *Nubank*, *Google*, *Mercado Livre*.
- Adição dinâmica com validação de campos vazios, alternância de status ativo/inativo e remoção instantânea.

### 5. Arquivamento e Histórico (`ArchivedJobsScreen`)
- Permite arquivar oportunidades sem excluí-las permanentemente, mantendo o quadro Kanban focado apenas em processos ativos.
- Ecrã dedicado para consulta do histórico de vagas arquivadas com opção de **Restauração Imediata** para o funil.

### 6. Conversão e Extração de Vagas em Markdown (Jina Reader AI)
- **Extração Inteligente via Reader:** Conversão instantânea da página externa da vaga (URL) em Markdown estruturado através da integração com o Jina AI Reader (`https://r.jina.ai/`).
- **Cópia Instantânea para a Área de Transferência:** Botão dedicado no modal de detalhes que extrai e copia a descrição da vaga com feedback visual flutuante.
- **Pré-visualização Interativa (`JobMarkdownPreviewDialog`):** Modal com visualização monoespaçada do Markdown, permitindo inspecionar o conteúdo na íntegra e acionar nova cópia.

---

## 🎨 Design System & Experiência Visual

O aplicativo segue uma estética moderna inspirada na paleta **Slate** com modo escuro nativo de alto contraste:

- **Cores Principais:**
  - Fundo principal: `AppColors.slate900` (`#0F172A`)
  - Superfícies e Cards: `AppColors.slate800` (`#1E293B`)
  - Bordas e divisores: `AppColors.slate700` (`#334155`)
  - Destaques tecnológicos: `AppColors.terminalCyan` (`#22D3EE`) e `AppColors.primaryIndigo` (`#6366F1`)
- **Cores do Funil:**
  - Salva: Azul Ciano (`#38BDF8`)
  - Aplicada: Roxo/Índigo (`#818CF8`)
  - Entrevista: Âmbar/Amarelo (`#FBBF24`)
  - Oferta: Esmeralda/Verde (`#34D399`)
  - Rejeitada: Rosa/Vermelho (`#F87171`)
- **Tipografia:** Google Fonts (`Inter` para leitura fluida de textos e `JetBrains Mono` para tags técnicas e metadados).
- **Proteção Visual com `SafeArea`:** Telas ajustadas com `SafeArea(top: false)` para garantir que cabeçalhos, barras de gestos inferiores e bordas laterais estejam protegidos contra recortes de câmera (*notch*/*punch-hole*) e barras de navegação virtuais, mantendo o fundo Slate estendido até as bordas físicas da tela em tablets e smartphones.

---

## 🏛 Arquitetura & Engenharia de Software

O projeto adota os princípios de **Clean Architecture** combinados com a abordagem modular **Feature-First**:

```
lib/
├── core/
│   ├── constants/             # Cores (AppColors) e tipografia (AppTypography)
│   ├── errors/                # Classes de exceções e falhas de domínio
│   ├── services/              # Inicialização do SupabaseClient e serviços globais
│   └── theme/                 # Configuração do ThemeData e extensões de cor
├── features/
│   ├── jobs/                  # Funcionalidade do Quadro Kanban e Vagas
│   │   ├── data/              # DataSources (Supabase) e Repositório Concreto
│   │   ├── domain/            # Modelos imutáveis (JobItem, JobStatus) e Interfaces
│   │   └── presentation/      # Cubits (JobsCubit, ArchivedJobsCubit), Telas e Widgets
│   ├── dashboard/             # Funcionalidade do Dashboard Analítico
│   │   ├── domain/            # Modelo de métricas calculadas (DashboardMetrics)
│   │   └── presentation/      # AnalyticsDashboardCubit, Gráficos e KPIs
│   └── search_configs/        # Gestão de Critérios de Busca para Crawlers
│       ├── data/              # SearchConfigsRemoteDataSource e Repositório
│       ├── domain/            # SearchConfigItem, Categorias e Interfaces
│       └── presentation/      # SearchConfigsCubit, Formulários e Chips de Filtro
└── main.dart                  # Ponto de entrada, injeção de dependências e inicialização
```

### Princípios Técnicos Aplicados:
1. **Separação de Responsabilidades:** Camadas de Domínio não possuem dependências de frameworks externos ou bibliotecas de UI.
2. **Gerenciamento de Estado Reativo:** Utilização de `flutter_bloc` com `Cubit`. Todos os estados são objetos imutáveis estendendo `Equatable`.
3. **Padrão Otimista:** Ações do usuário disparam mutações imediatas no estado da UI com salvamento em segundo plano e mecanismo de *reversão atômica* caso a camada de rede falhe.
4. **Debouncing e Descarte:** Controladores de texto e fluxos de busca são cancelados e reiniciados de forma limpa para evitar consumo excessivo de memória.

---

## 🗄 Modelagem de Dados & Backend (Supabase)

A persistência do aplicativo é suportada pelo **PostgreSQL** via **Supabase**:

### 1. View Otimizada: `public.v_user_jobs`
O aplicativo consome a view segura `public.v_user_jobs` (com flag `security_invoker = true`) que consolida os dados das vagas coletadas com as interações específicas do usuário:
- `job_id`, `title`, `company_name`, `platform`, `job_url`, `location`, `salary_text`
- `status` (`new`, `applied`, `interviewing`, `offer`, `rejected`)
- `notes`, `applied_at`, `published_at`, `created_at`, `is_archived`

### 2. Tabela de Interações: `public.user_job_interactions`
As alterações de status, anotações de texto e sinalizações de arquivamento são persistidas na tabela `public.user_job_interactions` através de operações **UPSERT** idempotentes:
```sql
-- Constraint de unicidade que garante idempotência:
UNIQUE (user_id, job_id)
```

### 3. Tabela de Configurações: `public.search_configs`
Armazena os critérios de busca configurados pelo usuário autenticado:
- `id` (UUID), `user_id` (UUID), `category` (TEXT), `value` (TEXT), `is_active` (BOOLEAN), `metadata` (JSONB).

---

## 🚀 Guia de Instalação e Execução

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) versão **3.9.2** ou superior.
- [Dart SDK](https://dart.dev/get-dart) versão **3.9.2** ou superior.
- Git instalado.
- Dispositivo Android/iOS físico ou emulador configurado.

### 1. Clonar o Repositório
```bash
git clone https://github.com/willians-dos-santos/job-hunter-app.git
cd job-hunter-app
```

### 2. Configurar Variáveis de Ambiente
Crie um arquivo `.env` na raiz do projeto com base no arquivo de exemplo [.env.example](.env.example):
```bash
cp .env.example .env
```

Edite o arquivo `.env` informando as credenciais do seu projeto Supabase:
```env
SUPABASE_URL=https://seu-projeto-id.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-aqui
SUPABASE_USER_ID=seu-uuid-de-usuario-aqui
```

### 3. Instalar Dependências
```bash
flutter pub get
```

### 4. Gerar Ícones Nativos do Aplicativo
O projeto utiliza o pacote `flutter_launcher_icons` configurado no `pubspec.yaml` com base na arte em `assets/icons/app_icon.png`:
```bash
dart run flutter_launcher_icons
```

### 5. Executar o Aplicativo
```bash
# Executar no primeiro dispositivo disponível
flutter run

# Ou listar dispositivos e executar em um alvo específico:
flutter devices
flutter run -d <DEVICE_ID>
```

---

## 🧪 Qualidade de Código e Testes

A integridade do código e a ausência de regressões são garantidas por uma ampla suíte de testes automatizados e análise estática rigorosa.

### Análise Estática de Código (Linter)
```bash
flutter analyze
```
> O projeto segue as regras do `package:flutter_lints/flutter.yaml` com conformidade de **0 erros e 0 alertas**.

### Execução da Suíte de Testes
```bash
flutter test
```

### Cobertura de Testes Automatizados (285 testes passando):
- **Testes Unitários de Domínio & Modelos:** Validação de serialização JSON, mapeamento de enums (`JobStatus`, `SearchConfigCategory`) e cálculo de métricas de conversão.
- **Testes Unitários de Repositórios & DataSources:** Verificação de chamadas ao Supabase utilizando mocks (`mocktail`) e fakes de resposta com simulação de cenários de sucesso e falhas de rede.
- **Testes de Conversão Markdown (Jina AI):** Testes unitários de cliente HTTP, parsing e repositório de conversão de vagas para Markdown.
- **Testes de Gerenciamento de Estado (Cubits):** Validação de transições de estado, conversão assíncrona, reversão otimista em falhas de API, debounce de busca e atualização de anotações.
- **Testes de Widget & Interface:** Testes de renderização do quadro Kanban, colunas, cards, navegação entre telas, modais de detalhes, prévia de Markdown e grupos de chips de filtro.

---

## 📄 Licença

Este projeto está licenciado sob a **Licença MIT** — consulte o arquivo de licença para obter mais detalhes.

---

<p align="center">
  Desenvolvido com foco em alta produtividade e arquitetura limpa.
</p>
