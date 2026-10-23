import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:job_hunter_app/core/errors/job_failure.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_markdown_content.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/job_markdown_repository.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/job_markdown_cubit.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/job_markdown_state.dart';

class MockJobMarkdownRepository extends Mock implements IJobMarkdownRepository {}

void main() {
  late MockJobMarkdownRepository mockRepository;
  late JobMarkdownCubit cubit;

  final fixedDate = DateTime.parse('2026-10-22T13:00:00Z');
  final testContent = JobMarkdownContent(
    jobId: 'job-123',
    jobUrl: 'https://example.com/jobs/1',
    markdown: '# Flutter Developer\n\nRequirements...',
    convertedAt: fixedDate,
  );

  setUp(() {
    mockRepository = MockJobMarkdownRepository();
    cubit = JobMarkdownCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('JobMarkdownCubit', () {
    test('initial state is JobMarkdownInitial', () {
      expect(cubit.state, equals(const JobMarkdownInitial()));
    });

    test('convertAndCopy emits [Loading, Success] when successful', () async {
      when(
        () => mockRepository.convertJobToMarkdown(
          jobId: 'job-123',
          jobUrl: 'https://example.com/jobs/1',
        ),
      ).thenAnswer((_) async => testContent);

      when(
        () => mockRepository.copyToClipboard(testContent.markdown),
      ).thenAnswer((_) async {});

      final states = <JobMarkdownState>[];
      cubit.stream.listen(states.add);

      final result = await cubit.convertAndCopy(
        jobId: 'job-123',
        jobUrl: 'https://example.com/jobs/1',
      );
      await pumpEventQueue();

      expect(result, isTrue);
      expect(states, [
        const JobMarkdownLoading(jobId: 'job-123'),
        JobMarkdownSuccess(
          content: testContent,
          copiedToClipboard: true,
          message: 'Markdown da vaga copiado com sucesso!',
        ),
      ]);
      verify(() => mockRepository.copyToClipboard(testContent.markdown)).called(1);
    });

    test('convertAndCopy emits JobMarkdownError when URL is empty', () async {
      final states = <JobMarkdownState>[];
      cubit.stream.listen(states.add);

      final result = await cubit.convertAndCopy(
        jobId: 'job-123',
        jobUrl: '   ',
      );
      await pumpEventQueue();

      expect(result, isFalse);
      expect(states, [
        const JobMarkdownError(
          jobId: 'job-123',
          errorMessage: 'URL da vaga não disponível.',
        ),
      ]);
      verifyZeroInteractions(mockRepository);
    });

    test('convertAndCopy emits [Loading, Error] on JobMarkdownNetworkFailure', () async {
      when(
        () => mockRepository.convertJobToMarkdown(
          jobId: 'job-123',
          jobUrl: 'https://example.com/jobs/1',
        ),
      ).thenThrow(const JobMarkdownNetworkFailure('Tempo limite esgotado.'));

      final states = <JobMarkdownState>[];
      cubit.stream.listen(states.add);

      final result = await cubit.convertAndCopy(
        jobId: 'job-123',
        jobUrl: 'https://example.com/jobs/1',
      );
      await pumpEventQueue();

      expect(result, isFalse);
      expect(states, [
        const JobMarkdownLoading(jobId: 'job-123'),
        const JobMarkdownError(
          jobId: 'job-123',
          errorMessage: 'Tempo limite esgotado.',
        ),
      ]);
    });

    test('reset emits JobMarkdownInitial', () {
      cubit.emit(const JobMarkdownLoading(jobId: 'job-123'));
      cubit.reset();
      expect(cubit.state, equals(const JobMarkdownInitial()));
    });
  });
}
