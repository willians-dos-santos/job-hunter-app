import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/job_markdown_repository.dart';
import 'job_markdown_state.dart';

/// Cubit managing job web page conversion to Markdown and clipboard copy.
class JobMarkdownCubit extends Cubit<JobMarkdownState> {
  JobMarkdownCubit({required IJobMarkdownRepository repository})
      : _repository = repository,
        super(const JobMarkdownInitial());

  final IJobMarkdownRepository _repository;

  /// Converts the given [jobUrl] into Markdown via Jina Reader, copies the
  /// output into the system clipboard, and emits either [JobMarkdownSuccess]
  /// or [JobMarkdownError].
  Future<bool> convertAndCopy({
    required String jobId,
    required String jobUrl,
    String? apiKey,
  }) async {
    final trimmedUrl = jobUrl.trim();
    if (trimmedUrl.isEmpty) {
      emit(JobMarkdownError(
        jobId: jobId,
        errorMessage: 'URL da vaga não disponível.',
      ));
      return false;
    }

    emit(JobMarkdownLoading(jobId: jobId));

    try {
      final content = await _repository.convertJobToMarkdown(
        jobId: jobId,
        jobUrl: trimmedUrl,
        apiKey: apiKey,
      );

      await _repository.copyToClipboard(content.markdown);

      emit(JobMarkdownSuccess(
        content: content,
        copiedToClipboard: true,
        message: 'Markdown da vaga copiado com sucesso!',
      ));
      return true;
    } on AppException catch (e) {
      emit(JobMarkdownError(
        jobId: jobId,
        errorMessage: e.message,
      ));
      return false;
    } catch (e) {
      emit(JobMarkdownError(
        jobId: jobId,
        errorMessage: 'Erro inesperado ao converter a página da vaga: $e',
      ));
      return false;
    }
  }

  /// Resets state back to [JobMarkdownInitial].
  void reset() {
    emit(const JobMarkdownInitial());
  }
}
