# Feature Specification: 006 - Pesquisa em Tempo Real e Filtros Rápidos no Kanban (`features/jobs`)

**Feature Branch**: `006-kanban-search-and-filters`  
**Created**: 2026-10-11  
**Status**: Ready for Implementation  
**Input**: User description: "Ativar a barra de pesquisa superior com debounce e implementar chips de filtros rápidos (Remoto, Híbrido, Presencial) para filtrar as vagas exibidas no Kanban de forma reativa."

---

# Spec 006: Pesquisa em Tempo Real e Filtros Rápidos no Kanban (`features/jobs`)

## 1. Contexto e Objetivos
Ativar a barra de pesquisa superior com debounce (~400ms) e implementar chips de filtros rápidos (`Todos`, `Remoto`, `Híbrido`, `Presencial`) para filtrar as vagas exibidas no Kanban de forma reativa, com feedback de estado vazio contextual e suporte a redefinição de filtros.

## 2. Requisitos Funcionais
1. **Barra de Pesquisa:**
   - Ativar o campo de texto existente com debounce (~400ms) para evitar refiltragens excessivas a cada caractere digitado.
   - Botão para limpar a pesquisa quando preenchida (ícone limpar `suffixIcon`).
   - Filtrar vagas em memória por título, empresa e localização (além de compatibilidade com notas e plataforma).
2. **Chips de Filtro:**
   - Adicionar barra deslizante horizontal com opções de modalidade: `Todos`, `Remoto`, `Híbrido`, `Presencial`.
   - Atualizar reativamente as colunas e os contadores de vagas conforme filtros aplicados.
3. **Estado Vazio:**
   - Indicar mensagem contextual quando nenhum resultado corresponder à pesquisa/filtro, com opção clara para redefinir filtros.
4. **Tema e Testes:**
   - Estilo 100% alinhado à paleta Slate (Slate 900, 800, 700 e acentos Indigo/Cyan).
   - Testes unitários no Cubit e testes de widgets nos componentes de busca e filtros.
   - 0 erros e 0 alertas em `flutter test` e `flutter analyze`.

---

## 3. User Scenarios & Acceptance Criteria

### User Story 1 - Pesquisa em Tempo Real com Debounce e Limpeza (Priority: P1)
Como candidato com dezenas de vagas cadastradas no funil, desejo digitar termos de busca (cargo, empresa ou localização) e ver os resultados filtrados suavemente após uma breve pausa de digitação (~400ms), podendo limpar o texto rapidamente com um toque.

**Why this priority**: Permite localização ágil de oportunidades específicas sem sobrecarregar a UI durante a digitação.

**Acceptance Scenarios**:
1. **Dado** a lista de vagas carregada no Kanban,  
   **Quando** o usuário digita um termo no campo de busca (ex: "Flutter"),  
   **Então** a filtragem só deve ser disparada após o debounce de ~400ms, exibindo apenas as vagas correspondentes e atualizando o contador total.
2. **Dado** o campo de busca preenchido,  
   **Quando** o usuário toca no botão de limpar (`Icons.clear_rounded`),  
   **Então** o texto deve ser apagado imediatamente, a busca cancelada e todas as vagas aplicáveis restauradas.

---

### User Story 2 - Filtragem Rápida por Modalidade via Chips Deslizantes (Priority: P1)
Como candidato focado em modalidades específicas (ex: apenas vagas 100% remotas ou híbridas), desejo alternar filtros rápidos em chips horizontais para restringir o funil instantaneamente.

**Why this priority**: A modalidade de trabalho é o principal critério de triagem para a grande maioria dos desenvolvedores.

**Acceptance Scenarios**:
1. **Dado** o quadro Kanban exibindo vagas diversas,  
   **Quando** o usuário seleciona o chip "Remoto",  
   **Então** apenas vagas com modalidade remota devem permanecer visíveis nas colunas e os contadores devem refletir a nova contagem.
2. **Dado** o filtro "Remoto" ativo com um termo de busca digitado,  
   **Quando** ambos estão definidos,  
   **Então** o Kanban deve exibir a interseção lógica (vagas que atendem simultaneamente ao termo E à modalidade selecionada).
3. **Dado** um filtro de modalidade diferente de "Todos" selecionado,  
   **Quando** o usuário toca no chip "Todos",  
   **Então** o filtro de modalidade é removido e todas as vagas (respeitando a eventual busca de texto) voltam a ser exibidas.

---

### User Story 3 - Visualização de Estado Vazio Contextual e Ação de Redefinir (Priority: P2)
Como usuário que aplicou filtros muito restritivos ou termos inexistentes, desejo ser informado visualmente de forma clara e amigável que não há resultados, tendo um botão de ação imediato para redefinir os filtros.

**Why this priority**: Evita que o usuário pense que o aplicativo quebrou ou perdeu seus dados quando um filtro não retorna registros.

**Acceptance Scenarios**:
1. **Dado** que uma busca ou filtro ativo não retorna nenhuma vaga em nenhuma das colunas,  
   **Quando** o estado filtrado for vazio (`state.jobs.isEmpty`),  
   **Então** a área do quadro deve apresentar uma mensagem contextual ("Nenhuma vaga encontrada") acompanhada de botão "Redefinir filtros".
2. **Dado** a exibição do estado vazio com botão "Redefinir filtros",  
   **Quando** o usuário aciona o botão de redefinir,  
   **Então** a barra de pesquisa é limpa, a modalidade retorna para "Todos" e a lista completa de vagas ativas volta a ser renderizada nas colunas.

---

## 4. Edge Cases
- **Digitação rápida consecutiva**: Vários caracteres digitados dentro da janela de 400ms devem reiniciar o timer sem disparar emissões intermediárias de estado.
- **Caracteres especiais e acentuação**: A busca deve ser case-insensitive e tolerante a termos em maiúsculas/minúsculas.
- **Interações do Kanban durante filtro**: Ao mover status ou arquivar vaga durante uma busca/filtro ativo, a vaga deve ser atualizada preservando a query de busca e o filtro de modalidade corrente.
- **Descarte de widget**: Ao fechar ou reconstruir a tela antes do timer de debounce expirar, o `Timer` deve ser cancelado sem vazamento de memória (`memory leak`).

---

## 5. Functional Requirements
- **FR-001**: O `JobsCubit` deve suportar filtragem combinada por busca de texto (`searchQuery`) e modalidade (`JobModalityFilter`).
- **FR-002**: O `JobItem` deve expor lógica de detecção e correspondência de modalidade (`matchesModality`) para identificar vagas remotas, híbridas e presenciais com base em `location` e `title`.
- **FR-003**: O `JobsLoaded` state deve conter `selectedModality` (com valor padrão `JobModalityFilter.all`) e helpers como `hasActiveFilter`.
- **FR-004**: O campo de busca em `JobsKanbanPage` deve utilizar debounce de ~400ms para disparar `JobsCubit.filterJobs`.
- **FR-005**: O campo de busca deve exibir ícone de limpar quando houver texto digitado, limpando o texto e a query imediatamente ao ser tocado.
- **FR-006**: A barra de filtros deve renderizar chips horizontais deslizantes para `Todos`, `Remoto`, `Híbrido` e `Presencial`, com destaque visual para o chip selecionado alinhado ao tema Slate e Cyan.
- **FR-007**: Quando nenhum registro corresponder aos filtros ativos (`state.jobs.isEmpty`), o Kanban deve exibir mensagem contextual com botão "Redefinir filtros" que restaura a visão completa.
- **FR-008**: O contador total de vagas e os contadores de cada coluna devem atualizar reativamente de acordo com a lista filtrada.

---

## 6. Key Entities
- **`JobModalityFilter`**: Enum representando as modalidades de filtro (`all`, `remote`, `hybrid`, `onSite`) com rótulos amigáveis (`Todos`, `Remoto`, `Híbrido`, `Presencial`).
- **`JobsLoaded`**: Estado estendido com `selectedModality` e método `copyWith` suportando limpeza e alteração de filtros.
- **`KanbanEmptyFilteredView`**: Widget apresentando o estado vazio quando a busca/filtro não encontra resultados, provendo callback `onReset`.

---

## 7. Success Criteria
- **SC-001**: 100% de sucesso nos testes unitários e de widgets (`flutter test`).
- **SC-002**: Análise estática com 0 erros e 0 avisos em `flutter analyze`.
- **SC-003**: Testes unitários no `JobsCubit` cobrindo debounce, busca por texto, filtragem por modalidade, combinação de filtros e reset.
- **SC-004**: Testes de widgets em `JobsKanbanPage` cobrindo o comportamento do debounce, botão de limpar, alternância de chips de modalidade e exibição/ação do estado vazio.
- **SC-005**: Fidelidade visual rigorosa com o tema Slate (Slate 900 de fundo, Slate 800 nos chips, Slate 700 nas bordas e Indigo/Cyan nos acentos).
