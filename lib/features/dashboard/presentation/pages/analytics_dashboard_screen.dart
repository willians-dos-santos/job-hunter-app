import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../jobs/data/repositories/job_repository_impl.dart';
import '../../../jobs/domain/repositories/job_repository.dart';
import '../cubit/analytics_dashboard_cubit.dart';
import '../cubit/analytics_dashboard_state.dart';
import '../widgets/analytics_empty_view.dart';
import '../widgets/analytics_error_view.dart';
import '../widgets/analytics_loading_view.dart';
import '../widgets/metric_kpi_card.dart';
import '../widgets/status_distribution_card.dart';

/// Screen displaying the application metrics dashboard, KPI cards, and funnel distribution.
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({
    super.key,
    this.cubit,
    this.repository,
  });

  final AnalyticsDashboardCubit? cubit;
  final IJobRepository? repository;

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  late final AnalyticsDashboardCubit _cubit;
  bool _ownsCubit = false;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
    } else {
      _cubit =
          AnalyticsDashboardCubit(widget.repository ?? JobRepository());
      _ownsCubit = true;
      _cubit.loadMetrics();
    }
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo.withAlpha(45),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: AppColors.primaryIndigo.withAlpha(120)),
              ),
              child: Text(
                'DASHBOARD',
                style: AppTypography.monoTag(color: AppColors.terminalCyan),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Dashboard e Métricas',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar métricas',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _cubit.refresh(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<AnalyticsDashboardCubit, AnalyticsDashboardState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state is AnalyticsDashboardLoading ||
              state is AnalyticsDashboardInitial) {
            return const AnalyticsLoadingView();
          }

          if (state is AnalyticsDashboardError) {
            return AnalyticsErrorView(
              message: state.message,
              onRetry: () => _cubit.loadMetrics(),
            );
          }

          if (state is AnalyticsDashboardLoaded) {
            if (state.isEmpty) {
              return AnalyticsEmptyView(
                onRefresh: () => _cubit.loadMetrics(),
              );
            }

            return RefreshIndicator(
              color: AppColors.terminalCyan,
              backgroundColor: AppColors.slate800,
              onRefresh: () => _cubit.refresh(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 900;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Grid responsivo de Cards de KPIs
                            _buildKpiSection(state, isTablet),
                            const SizedBox(height: 24),

                            // 2. Distribuição Visual por Status
                            StatusDistributionCard(metrics: state.metrics),
                            const SizedBox(height: 24),

                            // 3. Histórico e Resumo Geral
                            _buildHistorySummaryCard(state),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildKpiSection(AnalyticsDashboardLoaded state, bool isTablet) {
    final kpiCards = [
      MetricKpiCard(
        title: 'Total Ativo no Funil',
        value: '${state.metrics.totalActiveInFunnel}',
        icon: Icons.filter_alt_outlined,
        accentColor: AppColors.terminalCyan,
        subtitle: 'is_archived = false & != rejected',
        badgeText: 'FUNIL ATIVO',
      ),
      MetricKpiCard(
        title: 'Candidaturas Submetidas',
        value: '${state.metrics.totalSubmitted}',
        icon: Icons.send_outlined,
        accentColor: AppColors.kanbanApplied,
        subtitle: 'applied, interviewing, offer',
        badgeText: 'SUBMETIDAS',
      ),
      MetricKpiCard(
        title: 'Taxa de Conversão',
        value: state.metrics.formattedConversionRate,
        icon: Icons.pie_chart_outline_rounded,
        accentColor: AppColors.kanbanInterview,
        subtitle: '(Entrevistas + Ofertas) / Submetidas',
        badgeText: 'CONVERSÃO',
      ),
      MetricKpiCard(
        title: 'Ofertas Recebidas',
        value: '${state.metrics.offersReceived}',
        icon: Icons.emoji_events_outlined,
        accentColor: AppColors.kanbanOffer,
        subtitle: 'status = offer',
        badgeText: 'SUCESSO',
      ),
    ];

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < kpiCards.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: kpiCards[i]),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 480
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: kpiCards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildHistorySummaryCard(AnalyticsDashboardLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate850,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.slate700.withAlpha(80),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.textSlate400,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Histórico Geral e Auditoria',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total de registros: ${state.metrics.totalJobs} • Vagas arquivadas: ${state.metrics.totalArchived}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSlate400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
