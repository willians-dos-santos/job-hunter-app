# Feature Specification: 010 - Conversão da Página da Vaga para Markdown e Cópia via Jina AI (`features/jobs`)

**Feature Branch**: `010-job-markdown-converter`  
**Created**: 2026-10-22  
**Status**: Implemented  
**Input**: User description: "Adicionar ao app um recurso para converter a página da vaga em markdown e copiar, utilizando jina.ai para conversão."

---

# Spec 010: Conversão da Página da Vaga para Markdown via Jina AI (`features/jobs`)

## 1. Contexto e Objetivos

Permitir que o usuário converta instantaneamente o conteúdo completo da página externa de uma vaga (`job_url`) em texto limpo no formato Markdown através do leitor do **Jina AI** (`https://r.jina.ai/<url>`), copiando o resultado diretamente para a área de transferência do dispositivo. Essa funcionalidade viabiliza que candidatos colem descrições completas e estruturadas de oportunidades diretamente em LLMs (ChatGPT, Claude, Gemini, etc.) para análise de aderência de perfil, geração de cartas de apresentação ou adequação de currículos, sem ruídos de layout, menus ou anúncios.

---

## 2. User Scenarios & Testing *(mandatory)*

### User Story 1 - Conversão da Vaga para Markdown e Cópia para Área de Transferência (Priority: P1)

Como candidato analisando oportunidades no aplicativo, desejo acionar a conversão da página externa da vaga para formato Markdown e copiá-la automaticamente para a área de transferência com um único toque no modal de detalhes, para que eu possa colar o texto da vaga diretamente em assistentes de IA e obter análises customizadas.

**Why this priority**:
Representa o valor central da funcionalidade solicitada. Elimina o atrito de acessar manualmente a página da vaga no navegador, selecionar o texto com formatação quebrada e limpar elementos desnecessários antes de alimentar uma IA.

**Independent Test**:
Pode ser testado de forma isolada abrindo o modal de detalhes `JobDetailsModal` para uma vaga com URL válida, clicando no botão "Copiar em Markdown", simulando o retorno da API Jina AI Reader e verificando se o conteúdo retornado foi depositado na área de transferência (`Clipboard`) e se a notificação de confirmação visual foi exibida.

**Acceptance Scenarios**:

1. **Dado** que o usuário abriu o modal de detalhes de uma vaga (`JobDetailsModal`) que possui uma `job_url` configurada,  
   **Quando** o usuário tocar no botão "Copiar em Markdown",  
   **Então** a aplicação deve realizar a requisição de conversão via leitor Jina AI (`https://r.jina.ai/<url>`), copiar o texto Markdown retornado para a área de transferência do dispositivo e exibir um SnackBar flutuante de sucesso informando que o Markdown foi copiado.

2. **Dado** que a conversão foi concluída e o Markdown copiado,  
   **Quando** o usuário colar o conteúdo copiado em qualquer outro campo ou aplicativo externo,  
   **Então** o texto colado deve corresponder ao conteúdo legível e estruturado em Markdown da página da vaga (títulos, requisitos, atribuições e benefícios).

---

### User Story 2 - Feedback de Carregamento e Tratamento Resiliente de Falhas (Priority: P1)

Como usuário acionando a conversão de uma vaga externa, desejo receber indicação visual clara de que a página está sendo convertida e obter mensagens de erro descritivas caso a operação não possa ser concluída (ex: falta de conexão, URL inválida ou site bloqueado), para que eu compreenda o estado da aplicação e saiba como agir.

**Why this priority**:
Operações de scraping/leitura externa via rede dependem de terceiros e podem apresentar latência ou falhas de disponibilidade. O feedback visual com tratamento robusto de erros previne múltiplos cliques acidentais e evita congelamento da interface.

**Independent Test**:
Pode ser testado simulando:
1. Latência na requisição (verificando spinner de carregamento e desabilitação do botão).
2. Erro de rede / timeout / HTTP 4xx ou 5xx (verificando restauração do botão e exibição de SnackBar de erro com mensagem compreensível).
3. Vaga com `job_url` ausente ou em branco (verificando desabilitação visual do botão ou aviso de impedimento).

**Acceptance Scenarios**:

1. **Dado** que a requisição de conversão foi disparada,  
   **Quando** a resposta da API Jina AI ainda estiver pendente,  
   **Então** o botão de ação deve exibir um indicador de progresso circular (spinner) e permanecer temporariamente desabilitado para evitar disparos concorrentes.

2. **Dado** uma falha durante o processo de conversão (ausência de internet, timeout ou resposta de erro do Jina AI),  
   **Quando** a exceção for capturada,  
   **Então** o estado de carregamento deve ser desativado, o botão deve retornar ao estado interativo e um SnackBar com estilo de erro deve informar a causa da falha ao usuário de forma amigável.

3. **Dado** uma vaga cuja `job_url` esteja vazia ou em branco,  
   **Quando** o modal de detalhes da vaga for renderizado,  
   **Então** o botão de conversão para Markdown deve estar visualmente desabilitado, impedindo requisições desnecessárias.

---

### User Story 3 - Visualização Opcional / Modal de Leitura do Conteúdo Convertido (Priority: P2)

Como candidato utilizando a aplicação, além de copiar o Markdown para a área de transferência, desejo ter a opção de inspecionar previamente o texto convertido ou visualizar o resumo gerado caso queira ler a descrição completa da vaga sem sair do aplicativo.

**Why this priority**:
Agrega conveniência aos usuários que desejam ler os requisitos da vaga diretamente no app com foco na leitura e sem a distração do design original da página externa.

**Independent Test**:
Pode ser testado verificando se o fluxo permite visualizar o conteúdo obtido em uma janela de pré-visualização com rolagem suave e atalho para copiar novamente o conteúdo a qualquer momento.

**Acceptance Scenarios**:

1. **Dado** que o conteúdo da vaga foi obtido e convertido com sucesso,  
   **Quando** o usuário optar por visualizar o Markdown gerado,  
   **Então** um diálogo ou painel responsivo com suporte a rolagem deve ser apresentado exibindo o texto formatado e um botão destacado para copiar o texto completo.

---

### Edge Cases

- **Página protegida por CAPTCHA, Cloudflare ou Paywall**: Sites com proteções anti-bot rígidas podem retornar mensagens de bloqueio no Jina Reader. A aplicação deve validar se o retorno possui conteúdo útil antes de confirmar o sucesso ou alertar que a página externa exigiu validação humana.
- **Vagas com URLs de redirecionamento ou links encurtados**: A requisição deve seguir redirecionamentos HTTP automaticamente para extrair a página final de destino.
- **Conteúdo Markdown muito extenso**: Textos longos devem ser processados sem estourar o limite de memória do Flutter ou provocar travamento na thread principal de renderização.
- **Perda de conectividade durante a requisição**: Se a conexão for interrompida no meio do carregamento, a aplicação deve cancelar a requisição após um tempo limite (timeout de 20s) e exibir feedback de erro de rede.

---

## 3. Requirements *(mandatory)*

### Functional Requirements

- **FR-001 (Ponto de Acesso Visual)**: O modal de detalhes da vaga (`JobDetailsModal`) DEVE disponibilizar um botão de ação proeminente ("Copiar Markdown" ou "Copiar em Markdown") posicionado junto às ações de link externo da vaga.
- **FR-002 (Integração com Jina AI Reader)**: O sistema DEVE utilizar o leitor da Jina AI enviando requisição GET para o endpoint canônico `https://r.jina.ai/<url_da_vaga>`, obtendo a transcrição limpa da página em Markdown.
- **FR-003 (Cópia Direta para a Área de Transferência)**: Ao receber a resposta com sucesso da Jina AI, o sistema DEVE gravar o texto Markdown diretamente na área de transferência do sistema operacional (`Clipboard.setData`).
- **FR-004 (Feedback de Sucesso e Erro)**: O sistema DEVE emitir um SnackBar flutuante confirmando a cópia ("Markdown da vaga copiado para a área de transferência!") com fundo coerente com o tema Dark. Em caso de falha, DEVE exibir SnackBar de alerta com tom semântico de erro (`AppColors.kanbanRejected`).
- **FR-005 (Estado de Carregamento)**: Durante a requisição de conversão, o botão de conversão DEVE exibir um indicador de progresso circular (`CircularProgressIndicator`) e bloquear novos cliques.
- **FR-006 (Timeout e Resiliência)**: A chamada HTTP DEVE possuir um tempo limite explícito (timeout padrão de 20 segundos) para evitar bloqueio indefinido caso o site de destino demore para responder.
- **FR-007 (Validação de URL)**: Caso a vaga não possua `job_url` válida cadastrada, o botão de conversão DEVE permanecer desabilitado.
- **FR-008 (Configuração Opcional de Token de Autenticação)**: O serviço DEVE suportar a leitura opcional de uma variável de ambiente `JINA_API_KEY` via `.env`, enviando o cabeçalho `Authorization: Bearer <token>` quando presente, mantendo o funcionamento gratuito por padrão quando omitida.
- **FR-009 (Arquitetura e Desacoplamento)**: A lógica de comunicação com o Jina AI DEVE ser encapsulada em um serviço/datasource dedicado na camada de infraestrutura/dados (`JobMarkdownService` ou `JobMarkdownDataSource`), com interface/contrato abstrato na camada de domínio, preservando a Clean Architecture do projeto.
- **FR-010 (Tema Slate Escuro)**: Toda interface visual, botões, ícones e diálogos DEVEM seguir rigorosamente a paleta Dark Slate (`Slate 900`, `Slate 800`, `Slate 700`, acentos em `terminalCyan` e `primaryIndigo`).

---

### Key Entities

- **JobItem**: Entidade de domínio já existente no aplicativo representando a vaga de emprego, fonte dos dados de `jobId`, `title`, `companyName` e `jobUrl`.
- **JobMarkdownContent**: Objeto de valor (Value Object) que encapsula o resultado da conversão da vaga:
  - `jobId` (`String`): Identificador único da vaga correspondente.
  - `url` (`String`): URL original convertida.
  - `markdown` (`String`): Conteúdo transcrito em formato Markdown.
  - `fetchedAt` (`DateTime`): Timestamp do momento em que a conversão foi obtida.

---

## 4. Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001 (Qualidade de Código)**: 100% dos novos arquivos e modificações compilam com 0 erros e 0 alertas em `flutter analyze`.
- **SC-002 (Cobertura de Testes)**: 100% dos novos componentes (serviço de conversão, Cubit e widgets do modal) possuem testes automatizados passando integralmente em `flutter test`.
- **SC-003 (Agilidade na Cópia)**: A gravação do Markdown na área de transferência e o acionamento do SnackBar ocorrem em menos de 250 milissegundos após o recebimento dos bytes da requisição.
- **SC-004 (Tratamento Universal de Falhas)**: 100% das condições de exceção (timeout, sem internet, HTTP 4xx/5xx, URL nula) são tratadas com mensagens claras sem causar crash ou congelamento do app.
- **SC-005 (Consistência de Design e Responsividade)**: O botão de ação e o modal adaptam-se perfeitamente a telas compactas (smartphones) e amplas (tablets) sem estouro de layout (`RenderFlex overflowed`).

---

## 5. Assumptions

- O serviço gratuito Jina AI Reader (`https://r.jina.ai/<target_url>`) atende à demanda habitual de conversões sob demanda sem necessidade compulsória de plano pago para uso pessoal.
- A biblioteca padrão do Flutter para acesso à área de transferência (`package:flutter/services.dart` via `Clipboard.setData`) é plenamente compatível com as plataformas suportadas pelo projeto (Android, Web e Linux).
- O aplicativo utiliza cliente HTTP resiliente (com timeout e tratamento de status codes).
- Nenhuma alteração de esquema no banco de dados Supabase é necessária para esta funcionalidade (o Markdown é gerado e consumido sob demanda pelo usuário, sem necessidade inicial de persistência remota).

---

## 6. Governança e Conformidade com a Constituição

- Em conformidade com o **Princípio I (Clean Architecture)**: A requisição à Jina AI é isolada em um serviço/datasource com contrato abstrato na camada de domínio.
- Em conformidade com o **Princípio II (Data Contracts)**: Nenhuma coluna de banco ou contrato da view `v_user_jobs` foi violado ou modificado.
- Em conformidade com o **Princípio III (Quality Gates & Test-First)**: Implementação acompanhada de testes unitários para o serviço/Cubit e testes de widget para o `JobDetailsModal`.
- Em conformidade com o **Princípio IV (Responsive Tablet-First & Slate Theme Consistency)**: Adoção estrita da paleta Slate escuro com proteção contra overflow de layout.
