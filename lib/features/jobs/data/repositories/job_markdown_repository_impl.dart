import 'package:flutter/services.dart';

import '../../domain/models/job_markdown_content.dart';
import '../../domain/repositories/job_markdown_repository.dart';

/// Concrete implementation of [IJobMarkdownRepository].
class JobMarkdownRepositoryImpl implements IJobMarkdownRepository {
  JobMarkdownRepositoryImpl({
    required IJobMarkdownRemoteDataSource remoteDataSource,
    Future<void> Function(String text)? clipboardSetter,
    DateTime Function()? nowProvider,
  })  : _remoteDataSource = remoteDataSource,
        _clipboardSetter = clipboardSetter ?? _defaultClipboardSetter,
        _nowProvider = nowProvider ?? DateTime.now;

  final IJobMarkdownRemoteDataSource _remoteDataSource;
  final Future<void> Function(String text) _clipboardSetter;
  final DateTime Function() _nowProvider;

  static Future<void> _defaultClipboardSetter(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Future<JobMarkdownContent> convertJobToMarkdown({
    required String jobId,
    required String jobUrl,
    String? apiKey,
  }) async {
    final markdown = await _remoteDataSource.fetchMarkdownFromUrl(
      jobUrl: jobUrl,
      apiKey: apiKey,
    );

    return JobMarkdownContent(
      jobId: jobId,
      jobUrl: jobUrl,
      markdown: markdown,
      convertedAt: _nowProvider(),
    );
  }

  @override
  Future<void> copyToClipboard(String markdown) async {
    await _clipboardSetter(markdown);
  }
}
