import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Loading view with smooth indicators and Slate theme styling.
class AnalyticsLoadingView extends StatelessWidget {
  const AnalyticsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.terminalCyan),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Carregando métricas do funil...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSlate400,
            ),
          ),
        ],
      ),
    );
  }
}
