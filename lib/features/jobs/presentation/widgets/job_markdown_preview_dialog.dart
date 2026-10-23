import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Opens the responsive [JobMarkdownPreviewDialog] modal for viewing extracted Markdown.
Future<void> showJobMarkdownPreviewDialog(
  BuildContext context, {
  required String title,
  required String markdown,
  Future<void> Function(String)? onCopy,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => JobMarkdownPreviewDialog(
      title: title,
      markdown: markdown,
      onCopy: onCopy,
    ),
  );
}

/// Responsive modal dialog to read and inspect converted job Markdown.
class JobMarkdownPreviewDialog extends StatelessWidget {
  const JobMarkdownPreviewDialog({
    super.key,
    required this.title,
    required this.markdown,
    this.onCopy,
  });

  final String title;
  final String markdown;
  final Future<void> Function(String)? onCopy;

  Future<void> _handleCopy(BuildContext context) async {
    if (onCopy != null) {
      await onCopy!(markdown);
    } else {
      await Clipboard.setData(ClipboardData(text: markdown));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: ValueKey('markdown_preview_copied_snackbar'),
          content: Text('Markdown copiado para a área de transferência!'),
          backgroundColor: AppColors.slate800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.slate900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.slate700),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 680,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.article_outlined,
                    color: AppColors.terminalCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Markdown da Vaga: $title',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
              const Divider(color: AppColors.slate700, height: 1),
              const SizedBox(height: 12),

              // Scrollable Markdown content preview
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.slate850,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate700),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      markdown,
                      style: AppTypography.monoTag(
                        color: AppColors.textSlate300,
                        fontSize: 13,
                      ).copyWith(height: 1.5),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(color: AppColors.textSlate400),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    key: const ValueKey('markdown_preview_copy_button'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar Novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryIndigo,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _handleCopy(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
