# Quickstart & Validation Guide: Conversor de Markdown da Vaga

**Feature**: `010-job-markdown-converter`  
**Date**: 2026-10-22  

---

## 1. Pré-Requisitos

- Flutter SDK ^3.9.2 instalado e configurado no PATH.
- Dependências instaladas (`flutter pub get`).
- Variável opcional `JINA_API_KEY` pode ser configurada no arquivo `.env` (opcional, o leitor público gratuito é usado por padrão).

---

## 2. Comandos de Validação e Testes Automatizados

### Validação de Análise Estática
```bash
flutter analyze
```
*Resultado esperado:* `No issues found!` (0 erros, 0 alertas).

### Execução dos Testes Automatizados
```bash
# Executa todos os testes unitários e de widget da feature
flutter test test/features/jobs/presentation/cubit/job_markdown_cubit_test.dart
flutter test test/features/jobs/data/datasources/job_markdown_remote_datasource_test.dart
flutter test test/features/jobs/presentation/widgets/job_details_modal_test.dart
```
*Resultado esperado:* Todos os testes passando com 100% de sucesso.

---

## 3. Cenários de Validação Manual End-to-End

### Cenário 1: Conversão e Cópia com Sucesso
1. Inicie o aplicativo:
   ```bash
   flutter run -d linux # ou chrome / android
   ```
2. No quadro Kanban, toque em qualquer cartão de vaga que possua link externo cadastrado para abrir o `JobDetailsModal`.
3. Verifique a presença do botão **"Copiar em Markdown"** (com ícone correspondente) ao lado do botão "Acessar vaga externa".
4. Toque em **"Copiar em Markdown"**:
   - O botão deve exibir um indicador circular de progresso (`CircularProgressIndicator`) e ficar desabilitado temporariamente.
   - Após 1 a 3 segundos, um SnackBar flutuante escuro deve ser exibido na tela: *"Markdown da vaga copiado com sucesso!"*.
5. Abra qualquer editor de texto ou campo de prompt de IA e execute `Ctrl+V` (ou Colar):
   - O conteúdo colado deve conter a descrição da vaga estruturada em Markdown (título, atribuições, requisitos e dados da empresa).

### Cenário 2: Tratamento de Falha de Rede ou URL Inválida
1. Abra uma vaga com URL inacessível ou desconecte temporariamente a rede do dispositivo.
2. Toque em **"Copiar em Markdown"**:
   - O indicador de progresso é exibido durante a tentativa.
   - O botão é restaurado ao seu estado normal.
   - Um SnackBar com fundo semântico de erro (`AppColors.kanbanRejected`) é exibido informando o erro de conexão de forma amigável.
   - O aplicativo não trava nem fecha inesperadamente.

### Cenário 3: Vaga sem URL
1. Visualize os detalhes de uma vaga sem `job_url`.
2. O botão **"Copiar em Markdown"** deve permanecer desabilitado.
