import '../models/job_markdown_content.dart';

/// Contract for fetching and converting job posting web pages into structured Markdown.
abstract class IJobMarkdownRepository {
  /// Converts the given [jobUrl] into Markdown and packages it into [JobMarkdownContent].
  ///
  /// Throws [JobMarkdownFailure] or its subclasses on network, rate-limiting or parsing errors.
  Future<JobMarkdownContent> convertJobToMarkdown({
    required String jobId,
    required String jobUrl,
    String? apiKey,
  });

  /// Copies the provided [markdown] text directly to the system clipboard.
  Future<void> copyToClipboard(String markdown);
}

/// Backwards-compatible alias for [IJobMarkdownRepository].
typedef JobMarkdownRepository = IJobMarkdownRepository;

/// Contract for the remote HTTP data source that communicates with the reader endpoint.
abstract class IJobMarkdownRemoteDataSource {
  /// Makes an HTTP GET request to convert [jobUrl] into Markdown.
  Future<String> fetchMarkdownFromUrl({
    required String jobUrl,
    String? apiKey,
  });
}
