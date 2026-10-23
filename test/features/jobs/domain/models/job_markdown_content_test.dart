import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_markdown_content.dart';

void main() {
  group('JobMarkdownContent', () {
    final now = DateTime.parse('2026-10-22T13:00:00Z');

    test('supports value equality via Equatable', () {
      final content1 = JobMarkdownContent(
        jobId: 'job-123',
        jobUrl: 'https://boards.greenhouse.io/techcorp/jobs/1',
        markdown: '# TechCorp Senior Engineer\n\nRequirements...',
        convertedAt: now,
      );

      final content2 = JobMarkdownContent(
        jobId: 'job-123',
        jobUrl: 'https://boards.greenhouse.io/techcorp/jobs/1',
        markdown: '# TechCorp Senior Engineer\n\nRequirements...',
        convertedAt: now,
      );

      final differentContent = JobMarkdownContent(
        jobId: 'job-456',
        jobUrl: 'https://boards.greenhouse.io/techcorp/jobs/2',
        markdown: '# Other job',
        convertedAt: now,
      );

      expect(content1, equals(content2));
      expect(content1.hashCode, equals(content2.hashCode));
      expect(content1, isNot(equals(differentContent)));
      expect(content1.props, [
        'job-123',
        'https://boards.greenhouse.io/techcorp/jobs/1',
        '# TechCorp Senior Engineer\n\nRequirements...',
        now,
      ]);
    });
  });
}
