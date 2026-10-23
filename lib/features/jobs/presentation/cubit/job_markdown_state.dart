import 'package:equatable/equatable.dart';

import '../../domain/models/job_markdown_content.dart';

/// Base class for all states emitted by [JobMarkdownCubit].
sealed class JobMarkdownState extends Equatable {
  const JobMarkdownState();

  @override
  List<Object?> get props => [];
}

/// Initial or idle state when no conversion is running.
final class JobMarkdownInitial extends JobMarkdownState {
  const JobMarkdownInitial();
}

/// Conversion is in flight for [jobId].
final class JobMarkdownLoading extends JobMarkdownState {
  const JobMarkdownLoading({required this.jobId});

  final String jobId;

  @override
  List<Object?> get props => [jobId];
}

/// Conversion completed and text was copied to clipboard.
final class JobMarkdownSuccess extends JobMarkdownState {
  const JobMarkdownSuccess({
    required this.content,
    required this.copiedToClipboard,
    this.message = 'Markdown da vaga copiado com sucesso!',
  });

  final JobMarkdownContent content;
  final bool copiedToClipboard;
  final String message;

  @override
  List<Object?> get props => [content, copiedToClipboard, message];
}

/// Conversion or copy failed for [jobId].
final class JobMarkdownError extends JobMarkdownState {
  const JobMarkdownError({
    required this.jobId,
    required this.errorMessage,
  });

  final String jobId;
  final String errorMessage;

  @override
  List<Object?> get props => [jobId, errorMessage];
}
