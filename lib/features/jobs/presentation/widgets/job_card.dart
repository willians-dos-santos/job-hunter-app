import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kanban_status_colors.dart';
import '../../domain/models/job_item.dart';
import '../../domain/models/job_status.dart';

/// Interactive card component representing a job vacancy inside the Kanban funnel.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onMoveStatus,
    this.onArchive,
    this.onOpenUrl,
    this.enableDrag = true,
  });

  final JobItem job;
  final VoidCallback? onTap;
  final ValueChanged<JobStatus>? onMoveStatus;
  final VoidCallback? onArchive;
  final VoidCallback? onOpenUrl;
  final bool enableDrag;

  String _sanitizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  Future<void> _handleOpenUrl(BuildContext context) async {
    if (onOpenUrl != null) {
      onOpenUrl!();
      return;
    }
    final rawUrl = job.jobUrl.trim();
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL da vaga não disponível.'),
          backgroundColor: AppColors.kanbanRejected,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final sanitizedUrl = _sanitizeUrl(rawUrl);
      final uri = Uri.parse(sanitizedUrl);

      // 1. Tentar abrir via Custom Tabs nativas (inAppBrowserView)
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: const BrowserConfiguration(showTitle: true),
        );
      } catch (_) {
        launched = false;
      }

      // 2. Fallback para externalApplication caso inAppBrowserView não abra
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o link da vaga externa.'),
            backgroundColor: AppColors.kanbanRejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir o link da vaga: $e'),
            backgroundColor: AppColors.kanbanRejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = context.kanbanColors.colorFor(job.status);

    final cardContent = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate700),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent strip & actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                // Indicador de Status com ponto colorido
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Badge de Plataforma
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.slate850,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.slate700),
                  ),
                  child: Text(
                    job.platform.isNotEmpty ? job.platform : 'Vaga',
                    style: AppTypography.monoTag(
                      color: AppColors.terminalCyan,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                // Menu de Ações Rápidas
                _buildActionMenu(context),
              ],
            ),
          ),

          // Título e Empresa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      size: 14,
                      color: AppColors.textSlate400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        job.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSlate300,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Localização e Modalidade
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSlate500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.displayLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSlate400,
                          fontSize: 12,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Tags e Badges complementares
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (job.salaryText != null &&
                    job.salaryText!.trim().isNotEmpty) ...[
                  _Badge(
                    icon: Icons.payments_outlined,
                    label: job.displaySalary,
                    color: AppColors.kanbanOffer,
                  ),
                ],
                if (_detectModality(job.location) != null) ...[
                  _Badge(
                    icon: Icons.work_outline_rounded,
                    label: _detectModality(job.location)!,
                    color: AppColors.primaryIndigo,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

    if (!enableDrag) return cardContent;

    return LongPressDraggable<JobItem>(
      data: job,
      hapticFeedbackOnStart: true,
      delay: const Duration(milliseconds: 200),
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 280,
          child: Opacity(opacity: 0.92, child: cardContent),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: cardContent,
      ),
      child: cardContent,
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      key: ValueKey('job_card_menu_${job.jobId}'),
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: AppColors.textSlate400,
      ),
      color: AppColors.slate850,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.slate700),
      ),
      tooltip: 'Ações da vaga',
      itemBuilder: (context) => [
        // Sub-opções de mudança de status
        for (final status in JobStatus.values)
          if (status != job.status)
            PopupMenuItem<String>(
              value: 'move_${status.value}',
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.kanbanColors.colorFor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mover para ${status.label}',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        const PopupMenuDivider(),
        if (job.jobUrl.isNotEmpty)
          const PopupMenuItem<String>(
            value: 'open_url',
            child: Row(
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: AppColors.terminalCyan,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Abrir link externo',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'archive',
          child: Row(
            children: [
              Icon(
                Icons.archive_outlined,
                size: 16,
                color: AppColors.kanbanRejected,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Arquivar vaga',
                  style: TextStyle(
                    color: AppColors.kanbanRejected,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (action) {
        if (action.startsWith('move_')) {
          final targetValue = action.replaceFirst('move_', '');
          final targetStatus = JobStatus.fromString(targetValue);
          onMoveStatus?.call(targetStatus);
        } else if (action == 'open_url') {
          _handleOpenUrl(context);
        } else if (action == 'archive') {
          onArchive?.call();
        }
      },
    );
  }

  String? _detectModality(String? location) {
    if (location == null) return null;
    final lower = location.toLowerCase();
    if (lower.contains('remoto') || lower.contains('remote')) {
      return 'Remoto';
    }
    if (lower.contains('híbrido') || lower.contains('hybrid')) {
      return 'Híbrido';
    }
    if (lower.contains('presencial') || lower.contains('on-site')) {
      return 'Presencial';
    }
    return null;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
