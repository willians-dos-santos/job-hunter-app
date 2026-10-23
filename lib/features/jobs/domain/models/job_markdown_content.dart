import 'package:equatable/equatable.dart';

/// Immutable value object representing the converted markdown representation of a job posting.
class JobMarkdownContent extends Equatable {
  const JobMarkdownContent({
    required this.jobId,
    required this.jobUrl,
    required this.markdown,
    required this.convertedAt,
  });

  /// The unique identifier of the job vacancy.
  final String jobId;

  /// The original public canonical URL that was converted.
  final String jobUrl;

  /// The full semantic markdown text extracted by the reader.
  final String markdown;

  /// Timestamp when the conversion took place.
  final DateTime convertedAt;

  @override
  List<Object?> get props => [jobId, jobUrl, markdown, convertedAt];
}
