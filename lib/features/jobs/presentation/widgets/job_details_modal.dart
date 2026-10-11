import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kanban_status_colors.dart';
import '../../domain/models/job_item.dart';
import '../cubit/jobs_cubit.dart';

/// Opens the responsive [JobDetailsModal] bottom sheet for the given [job].
Future<void> showJobDetailsModal(
  BuildContext context, {
  required JobItem job,
  JobsCubit? cubit,
  Future<void> Function(String notes)? onSaveNotes,
  VoidCallback? onOpenUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => JobDetailsModal(
      job: job,
      cubit: cubit,
      onSaveNotes: onSaveNotes,
      onOpenUrl: onOpenUrl,
    ),
  );
}

/// Responsive details and personal notes modal for a job vacancy.
class JobDetailsModal extends StatefulWidget {
  const JobDetailsModal({
    super.key,
    required this.job,
    this.cubit,
    this.onSaveNotes,
    this.onOpenUrl,
  });

  final JobItem job;
  final JobsCubit? cubit;
  final Future<void> Function(String notes)? onSaveNotes;
  final VoidCallback? onOpenUrl;

  @override
  State<JobDetailsModal> createState() => _JobDetailsModalState();
}

class _JobDetailsModalState extends State<JobDetailsModal> {
  late final TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.job.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _sanitizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  Future<void> _handleOpenUrl() async {
    if (widget.onOpenUrl != null) {
      widget.onOpenUrl!();
      return;
    }
    final rawUrl = widget.job.jobUrl.trim();
    if (rawUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: ValueKey('job_details_url_error_snackbar'),
            content: Text('URL da vaga não disponível.'),
            backgroundColor: AppColors.kanbanRejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: ValueKey('job_details_url_error_snackbar'),
            content: Text('Não foi possível abrir o link da vaga externa.'),
            backgroundColor: AppColors.kanbanRejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const ValueKey('job_details_url_error_snackbar'),
            content: Text('Erro ao abrir o link da vaga: $e'),
            backgroundColor: AppColors.kanbanRejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveNotes() async {
    final notesText = _notesController.text;
    setState(() => _isSaving = true);
    try {
      if (widget.onSaveNotes != null) {
        await widget.onSaveNotes!(notesText);
      } else if (widget.cubit != null) {
        await widget.cubit!.updateJobNotes(
          jobId: widget.job.jobId,
          notes: notesText,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: ValueKey('job_details_saved_snackbar'),
            content: Text('Anotações salvas com sucesso.'),
            backgroundColor: AppColors.slate800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar anotações: $e'),
            backgroundColor: AppColors.kanbanRejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Data não informada';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String? _detectModality(String? location) {
    if (location == null) return null;
    final lower = location.toLowerCase();
    if (lower.contains('remoto') || lower.contains('remote')) return 'Remoto';
    if (lower.contains('híbrido') || lower.contains('hybrid')) return 'Híbrido';
    if (lower.contains('presencial') || lower.contains('on-site')) {
      return 'Presencial';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = context.kanbanColors.colorFor(widget.job.status);
    final modality = _detectModality(widget.job.location);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.slate900,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.slate700),
              left: BorderSide(color: AppColors.slate700),
              right: BorderSide(color: AppColors.slate700),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Top row with status badge and close button
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withAlpha(140)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.job.status.label,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Platform Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate850,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.slate700),
                      ),
                      child: Text(
                        widget.job.platform.isNotEmpty
                            ? widget.job.platform
                            : 'Vaga',
                        style: AppTypography.monoTag(
                          color: AppColors.terminalCyan,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Close Button
                    IconButton(
                      tooltip: 'Fechar',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSlate400,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Job Title
                Text(
                  widget.job.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 8),

                // Company Name
                Row(
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      size: 16,
                      color: AppColors.textSlate400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.job.companyName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textSlate300,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Meta Info & Badges
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.slate850,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location / Modality
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textSlate400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.job.displayLocation,
                              style: const TextStyle(
                                color: AppColors.textSlate300,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (modality != null) ...[
                            const SizedBox(width: 8),
                            _Badge(
                              icon: Icons.work_outline_rounded,
                              label: modality,
                              color: AppColors.primaryIndigo,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Salary
                      Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color: AppColors.kanbanOffer,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Salário: ${widget.job.displaySalary}',
                              style: const TextStyle(
                                color: AppColors.textSlate300,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Published Date
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: AppColors.textSlate400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Publicada em: ${_formatDate(widget.job.publishedAt ?? widget.job.createdAt)}',
                            style: const TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // External Link Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('job_details_open_url_button'),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.terminalCyan,
                    ),
                    label: const Text(
                      'Acessar vaga externa',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.slate800,
                      side: const BorderSide(color: AppColors.slate700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: widget.job.jobUrl.isNotEmpty
                        ? () => _handleOpenUrl()
                        : null,
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(color: AppColors.slate700, height: 1),
                const SizedBox(height: 16),

                // Personal Notes Section
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: AppColors.terminalCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Notas Pessoais',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Anotações e impressões particulares sobre esta vaga:',
                  style: TextStyle(
                    color: AppColors.textSlate400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                // Multi-line Notes TextField
                TextField(
                  key: const ValueKey('job_details_notes_field'),
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Ex: Contato com o recrutador, data da entrevista técnica, tópicos a estudar...',
                    hintStyle: const TextStyle(
                      color: AppColors.textSlate500,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.slate800,
                    contentPadding: const EdgeInsets.all(12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.slate700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.primaryIndigo),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Save Notes Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const ValueKey('job_details_save_notes_button'),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isSaving ? 'Salvando...' : 'Salvar anotações',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primaryIndigo,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSaving ? null : () => _handleSaveNotes(),
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
