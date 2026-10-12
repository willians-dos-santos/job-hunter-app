import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/errors/configuration_exception.dart';
import 'core/services/env_config.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/kanban_status_colors.dart';
import 'features/jobs/data/repositories/job_repository_impl.dart';
import 'features/jobs/domain/models/job_status.dart';
import 'features/jobs/presentation/cubit/jobs_cubit.dart';
import 'features/jobs/presentation/pages/jobs_kanban_page.dart';
import 'features/dashboard/presentation/pages/analytics_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? bootstrapError;

  try {
    await EnvConfig.init();
    await SupabaseService.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
  } on ConfigurationException catch (e) {
    bootstrapError = e.message;
  } catch (e) {
    bootstrapError = 'Erro inesperado na inicialização: $e';
  }

  runApp(JobHunterApp(bootstrapError: bootstrapError));
}

/// Root widget of the Job Hunter application.
class JobHunterApp extends StatelessWidget {
  const JobHunterApp({super.key, this.bootstrapError});

  final String? bootstrapError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: BootstrapHomeScreen(bootstrapError: bootstrapError),
    );
  }
}

/// Initial landing screen for Spec 001 showcasing the design system tokens
/// and operational environment diagnostics.
class BootstrapHomeScreen extends StatelessWidget {
  const BootstrapHomeScreen({super.key, this.bootstrapError});

  final String? bootstrapError;

  @override
  Widget build(BuildContext context) {
    final isConfigured = bootstrapError == null;
    final kanbanColors = context.kanbanColors;

    return Scaffold(
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primaryIndigo.withAlpha(120)),
              ),
              child: Text(
                'JH-CORE',
                style: AppTypography.monoTag(color: AppColors.terminalCyan),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Dashboard e Métricas',
            icon: const Icon(
              Icons.insights_outlined,
              color: AppColors.terminalCyan,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AnalyticsDashboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Abrir Quadro Kanban',
            icon: const Icon(
              Icons.view_kanban_rounded,
              color: AppColors.terminalCyan,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => JobsCubit(JobRepository())..loadJobs(),
                    child: const JobsKanbanPage(),
                  ),
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isConfigured
                  ? AppColors.kanbanOffer.withAlpha(35)
                  : AppColors.kanbanInterview.withAlpha(35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConfigured
                    ? AppColors.kanbanOffer
                    : AppColors.kanbanInterview,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isConfigured
                      ? AppColors.kanbanOffer
                      : AppColors.kanbanInterview,
                ),
                const SizedBox(width: 6),
                Text(
                  isConfigured ? 'ONLINE' : 'CONFIG REQUIRED',
                  style: AppTypography.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isConfigured
                        ? AppColors.kanbanOffer
                        : AppColors.kanbanInterview,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner de Status
                if (!isConfigured) ...[
                  Card(
                    color: AppColors.slate800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.kanbanInterview),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.kanbanInterview,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Atenção: Configuração de Ambiente Pendente',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            bootstrapError!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.slate850,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.slate700),
                            ),
                            child: SelectableText(
                              'cp .env.example .env\n# Edite com SUPABASE_URL e SUPABASE_ANON_KEY',
                              style: AppTypography.mono(
                                fontSize: 12,
                                color: AppColors.terminalCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Card de Boas-vindas e Arquitetura
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryIndigo.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.rocket_launch_rounded,
                                color: AppColors.primaryIndigo,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spec 001: Bootstrap & Arquitetura Frontend',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Clean Architecture Simplificada • Feature-First • Dark Mode Stitch',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        Text(
                          'Módulos Fundacionais Ativos:',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _FeatureBadge(
                              label: 'core/theme',
                              desc: 'Dark Mode Stitch Tokens',
                            ),
                            _FeatureBadge(
                              label: 'core/services',
                              desc: 'Supabase & EnvConfig',
                            ),
                            _FeatureBadge(
                              label: 'core/errors',
                              desc: 'ConfigurationException',
                            ),
                            _FeatureBadge(
                              label: 'features/jobs',
                              desc: 'JobItem & Funnel Domain',
                            ),
                            _FeatureBadge(
                              label: 'features/search_configs',
                              desc: 'SearchConfig Models',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Card de Acesso ao Quadro Kanban (Spec 003)
                Card(
                  color: AppColors.slate800,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryIndigo.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryIndigo.withAlpha(100),
                            ),
                          ),
                          child: const Icon(
                            Icons.view_kanban_rounded,
                            color: AppColors.terminalCyan,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spec 003: Quadro Kanban de Vagas',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textWhite,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Visualização do funil em 5 colunas, atualização otimista com rollback e filtros.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) =>
                                      JobsCubit(JobRepository())..loadJobs(),
                                  child: const JobsKanbanPage(),
                                ),
                              ),
                            );
                          },
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('Abrir Kanban'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryIndigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Card de Paleta Semântica Kanban
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Design System: Tokens Semânticos do Kanban',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estágios do funil de candidatura mapeados via ThemeExtension:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _KanbanChip(
                              status: JobStatus.newJob,
                              color: kanbanColors.newJob,
                              code: '#38BDF8',
                            ),
                            _KanbanChip(
                              status: JobStatus.applied,
                              color: kanbanColors.applied,
                              code: '#8B5CF6',
                            ),
                            _KanbanChip(
                              status: JobStatus.interview,
                              color: kanbanColors.interview,
                              code: '#F59E0B',
                            ),
                            _KanbanChip(
                              status: JobStatus.offer,
                              color: kanbanColors.offer,
                              code: '#10B981',
                            ),
                            _KanbanChip(
                              status: JobStatus.rejected,
                              color: kanbanColors.rejected,
                              code: '#F43F5E',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.label, required this.desc});

  final String label;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.slate850,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.monoTag(color: AppColors.terminalCyan),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _KanbanChip extends StatelessWidget {
  const _KanbanChip({
    required this.status,
    required this.color,
    required this.code,
  });

  final JobStatus status;
  final Color color;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(140)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${status.label} (${status.value})',
            style: TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            code,
            style: AppTypography.mono(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}
