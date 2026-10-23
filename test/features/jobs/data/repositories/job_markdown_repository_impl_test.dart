import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:job_hunter_app/features/jobs/data/repositories/job_markdown_repository_impl.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/job_markdown_repository.dart';

class MockJobMarkdownRemoteDataSource extends Mock
    implements IJobMarkdownRemoteDataSource {}

void main() {
  late MockJobMarkdownRemoteDataSource mockDataSource;
  late JobMarkdownRepositoryImpl repository;
  String? lastCopiedText;

  final fixedDate = DateTime.parse('2026-10-22T13:30:00Z');

  setUp(() {
    mockDataSource = MockJobMarkdownRemoteDataSource();
    lastCopiedText = null;
    repository = JobMarkdownRepositoryImpl(
      remoteDataSource: mockDataSource,
      clipboardSetter: (text) async {
        lastCopiedText = text;
      },
      nowProvider: () => fixedDate,
    );
  });

  group('JobMarkdownRepositoryImpl', () {
    const jobId = 'job-123';
    const jobUrl = 'https://jobs.lever.co/techcorp/abc';
    const sampleMarkdown = '# Senior Mobile Engineer\n\nJob description...';

    test('convertJobToMarkdown returns JobMarkdownContent with converted markdown', () async {
      when(
        () => mockDataSource.fetchMarkdownFromUrl(
          jobUrl: jobUrl,
          apiKey: any(named: 'apiKey'),
        ),
      ).thenAnswer((_) async => sampleMarkdown);

      final result = await repository.convertJobToMarkdown(
        jobId: jobId,
        jobUrl: jobUrl,
      );

      expect(result.jobId, equals(jobId));
      expect(result.jobUrl, equals(jobUrl));
      expect(result.markdown, equals(sampleMarkdown));
      expect(result.convertedAt, equals(fixedDate));
      verify(
        () => mockDataSource.fetchMarkdownFromUrl(
          jobUrl: jobUrl,
          apiKey: any(named: 'apiKey'),
        ),
      ).called(1);
    });

    test('copyToClipboard delegates to clipboard setter', () async {
      await repository.copyToClipboard(sampleMarkdown);

      expect(lastCopiedText, equals(sampleMarkdown));
    });
  });
}
