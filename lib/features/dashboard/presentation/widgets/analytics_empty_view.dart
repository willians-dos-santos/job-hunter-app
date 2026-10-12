import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Contextual empty state displayed when the funnel has no jobs.
class AnalyticsEmptyView extends StatelessWidget {
  const AnalyticsEmptyView({
    super.key,
    required this.onRefresh,
  });

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate700),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryIndigo.withAlpha(35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryIndigo.withAlpha(90),
                  ),
                ),
                child: const Icon(
                  Icons.bar_chart_outlined,
                  size: 40,
                  color: AppColors.terminalCyan,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nenhuma vaga no funil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Suas métricas e taxas de conversão aparecerão aqui assim que você adicionar vagas ao quadro Kanban.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSlate400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryIndigo,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Atualizar métricas',
                  style: AppTypography.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
