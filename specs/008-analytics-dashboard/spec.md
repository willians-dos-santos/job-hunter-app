# Feature Specification: 008 - Dashboard e Métricas de Candidaturas (`features/dashboard`)

**Feature Branch**: `008-analytics-dashboard`  
**Created**: 2026-10-12  
**Status**: Implemented  
**Input**: User description: "Fornecer ao usuário uma visão executiva e agregada do funil de vagas, permitindo acompanhar o progresso das candidaturas através de métricas de conversão e distribuição por status."

---

# Spec 008: Dashboard e Métricas de Candidaturas (`features/dashboard`)

## 1. Contexto e Objetivos
Fornecer ao usuário uma visão executiva e agregada do funil de vagas, permitindo acompanhar o progresso das candidaturas através de métricas de conversão e distribuição por status.

## 2. Contrato de Dados & Persistência (Governança)
- **Fonte Canônica de Leitura:** `specs/database-schema.md#public.v_user_jobs`
- **Campos Utilizados:** `status`, `is_archived`, `applied_at`, `created_at`.
- **Regras:**
  - O cálculo das métricas deve ser computado com base nas entidades da view (`JobEntity`), respeitando o isolamento do usuário.
  - Vagas com `is_archived = true` são excluídas das métricas ativas do funil, mas podem constar no histórico geral.

## 3. Requisitos Funcionais
- **Ponto de Entrada:** Ícone no AppBar principal (`Icons.insights_outlined` ou `Icons.bar_chart_outlined`) que navega para `AnalyticsDashboardScreen`.
- **Cards de KPIs:**
  - Total Ativo no Funil (`is_archived = false` e `status != 'rejected'`).
  - Total de Candidaturas Submetidas (`status IN ('applied', 'interviewing', 'offer')`).
  - Taxa de Conversão para Entrevista: `(Entrevistas + Ofertas) / (Candidaturas Totais) * 100`.
  - Ofertas Recebidas (`status = 'offer'`).
- **Distribuição Visual:**
  - Barras horizontais ou lista comparativa detalhando a contagem por cada status ('new', 'applied', 'interviewing', 'offer', 'rejected').
- **Interface e Tema:**
  - Seguir rigorosamente a paleta Slate escuro (`Slate 900`, `Slate 800`, `Slate 700`).
  - Layout responsivo adaptado para tablet e tratamento de loading/empty states.

## 4. Testes e Validação
- Testes unitários para o Cubit/cálculo de métricas.
- Testes de widget para a tela `AnalyticsDashboardScreen`.
- 0 erros e 0 alertas em `flutter analyze` e `flutter test`.
