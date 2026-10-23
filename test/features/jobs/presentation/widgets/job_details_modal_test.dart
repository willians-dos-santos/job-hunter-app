import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:job_hunter_app/core/theme/app_theme.dart';
import 'package:job_hunter_app/core/theme/app_typography.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_markdown_content.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/job_markdown_cubit.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/job_markdown_state.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/jobs_cubit.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/job_details_modal.dart';
import 'package:mocktail/mocktail.dart';

class MockJobsRepository extends Mock implements JobsRepository {}
class MockJobsCubit extends Mock implements JobsCubit {}
class MockJobMarkdownCubit extends Mock implements JobMarkdownCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const urlChannel = MethodChannel('plugins.flutter.io/url_launcher');
  String? lastLaunchedUrl;
  bool launchReturns = true;
  Exception? launchException;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTypography.useSystemFonts = true;
  });

  setUp(() {
    lastLaunchedUrl = null;
    launchReturns = true;
    launchException = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlChannel, (MethodCall call) async {
      if (call.method == 'launch') {
        if (launchException != null) throw launchException!;
        lastLaunchedUrl = call.arguments['url'] as String?;
        return launchReturns;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlChannel, null);
  });

  tearDownAll(() {
    AppTypography.useSystemFonts = false;
  });

  final sampleJob = JobItem(
    jobId: '101',
    title: 'Staff Flutter Engineer',
    companyName: 'Acme Corp',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/jobs/101',
    status: JobStatus.interview,
    location: 'Remoto - São Paulo, SP',
    salaryText: 'R\$ 25.000 / mês',
    publishedAt: DateTime(2026, 10, 11),
    notes: 'Preparar portfólio de arquitetura.',
  );

  Widget buildSubject({
    JobItem? job,
    JobsCubit? cubit,
    Future<void> Function(String notes)? onSaveNotes,
    VoidCallback? onOpenUrl,
    JobMarkdownCubit? markdownCubit,
    Future<void> Function(String url)? onConvertToMarkdown,
    VoidCallback? onPreviewMarkdown,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showJobDetailsModal(
                  context,
                  job: job ?? sampleJob,
                  cubit: cubit,
                  onSaveNotes: onSaveNotes,
                  onOpenUrl: onOpenUrl,
                  markdownCubit: markdownCubit,
                  onConvertToMarkdown: onConvertToMarkdown,
                  onPreviewMarkdown: onPreviewMarkdown,
                );
              },
              child: const Text('Abrir Detalhes'),
            ),
          ),
        ),
      ),
    );
  }

  group('JobDetailsModal Widget', () {
    testWidgets('renders job details and badges correctly in bottom sheet',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      // Verify Title, Company, Platform and Status
      expect(find.text('Staff Flutter Engineer'), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('LinkedIn'), findsOneWidget);
      expect(find.text('Entrevista'), findsOneWidget);

      // Verify meta information
      expect(find.text('Remoto - São Paulo, SP'), findsOneWidget);
      expect(find.text('Remoto'), findsOneWidget);
      expect(find.text('Salário: R\$ 25.000 / mês'), findsOneWidget);
      expect(find.text('Publicada em: 11/10/2026'), findsOneWidget);

      // Verify Action buttons and Notes section
      expect(find.text('Acessar vaga externa'), findsOneWidget);
      expect(find.text('Notas Pessoais'), findsOneWidget);
      expect(find.text('Preparar portfólio de arquitetura.'), findsOneWidget);
      expect(find.text('Salvar anotações'), findsOneWidget);
    });

    testWidgets('displays fallback values when salary or publication date are null',
        (tester) async {
      final jobWithFallbacks = JobItem(
        jobId: '102',
        title: 'Junior Developer',
        companyName: 'StartupXYZ',
        platform: '',
        jobUrl: '',
        status: JobStatus.newJob,
      );

      await tester.pumpWidget(buildSubject(job: jobWithFallbacks));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      expect(find.text('Junior Developer'), findsOneWidget);
      expect(find.text('StartupXYZ'), findsOneWidget);
      expect(find.text('Vaga'), findsOneWidget); // Fallback for empty platform
      expect(find.text('Salário: Não informado'), findsOneWidget);
      expect(find.text('Publicada em: Data não informada'), findsOneWidget);
    });

    testWidgets('triggers onOpenUrl callback when external button is tapped',
        (tester) async {
      bool openUrlCalled = false;

      await tester.pumpWidget(
        buildSubject(
          onOpenUrl: () => openUrlCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final openUrlButton = find.byKey(const ValueKey('job_details_open_url_button'));
      expect(openUrlButton, findsOneWidget);

      await tester.tap(openUrlButton);
      await tester.pumpAndSettle();

      expect(openUrlCalled, isTrue);
    });

    testWidgets('disables external link button when jobUrl is empty',
        (tester) async {
      final jobWithoutUrl = sampleJob.copyWith(jobUrl: '');

      await tester.pumpWidget(buildSubject(job: jobWithoutUrl));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final button = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('job_details_open_url_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows error SnackBar when both inAppBrowserView and external fallback fail',
        (tester) async {
      launchReturns = false;

      final jobWithSchemeLessUrl = sampleJob.copyWith(jobUrl: 'company.com/job');

      await tester.pumpWidget(
        buildSubject(
          job: jobWithSchemeLessUrl,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final openUrlButton = find.byKey(const ValueKey('job_details_open_url_button'));
      await tester.tap(openUrlButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('job_details_url_error_snackbar')),
        findsOneWidget,
      );
      expect(
        find.text('Não foi possível abrir o link da vaga externa.'),
        findsOneWidget,
      );
    });

    testWidgets('falls back to externalApplication when inAppBrowserView fails',
        (tester) async {
      int launchCallCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(urlChannel, (MethodCall call) async {
        if (call.method == 'launch') {
          launchCallCount++;
          lastLaunchedUrl = call.arguments['url'] as String?;
          if (launchCallCount == 1) {
            // First attempt (inAppBrowserView) fails
            return false;
          }
          // Second attempt (externalApplication fallback) succeeds
          return true;
        }
        return null;
      });

      final jobWithSchemeLessUrl = sampleJob.copyWith(jobUrl: 'company.com/job');

      await tester.pumpWidget(
        buildSubject(
          job: jobWithSchemeLessUrl,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final openUrlButton = find.byKey(const ValueKey('job_details_open_url_button'));
      await tester.tap(openUrlButton);
      await tester.pumpAndSettle();

      expect(launchCallCount, 2);
      expect(lastLaunchedUrl, 'https://company.com/job');
      expect(
        find.byKey(const ValueKey('job_details_url_error_snackbar')),
        findsNothing,
      );
    });

    testWidgets('shows exception SnackBar when launchUrl throws an error',
        (tester) async {
      launchException = PlatformException(code: 'ACTIVITY_NOT_FOUND', message: 'No activity found');

      final brokenJob = sampleJob.copyWith(jobUrl: 'broken.com/job');

      await tester.pumpWidget(
        buildSubject(
          job: brokenJob,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final openUrlButton = find.byKey(const ValueKey('job_details_open_url_button'));
      await tester.tap(openUrlButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('job_details_url_error_snackbar')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Erro ao abrir o link da vaga'),
        findsOneWidget,
      );
    });

    testWidgets('sanitizes url by adding https:// and launches via inAppBrowserView',
        (tester) async {
      launchReturns = true;

      final jobWithSchemeLessUrl = sampleJob.copyWith(jobUrl: 'company.com/job');

      await tester.pumpWidget(
        buildSubject(
          job: jobWithSchemeLessUrl,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final openUrlButton = find.byKey(const ValueKey('job_details_open_url_button'));
      await tester.tap(openUrlButton);
      await tester.pumpAndSettle();

      expect(lastLaunchedUrl, 'https://company.com/job');
    });

    testWidgets('saves notes via onSaveNotes callback and displays SnackBar feedback',
        (tester) async {
      String? savedNotes;

      await tester.pumpWidget(
        buildSubject(
          onSaveNotes: (notes) async {
            savedNotes = notes;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      // Enter new notes
      final notesField = find.byKey(const ValueKey('job_details_notes_field'));
      expect(notesField, findsOneWidget);
      await tester.enterText(notesField, 'Estudar System Design para o bate-papo.');
      await tester.pumpAndSettle();

      // Tap save
      final saveButton = find.byKey(const ValueKey('job_details_save_notes_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedNotes, 'Estudar System Design para o bate-papo.');
      expect(find.text('Anotações salvas com sucesso.'), findsOneWidget);
    });

    testWidgets('saves notes via cubit.updateJobNotes and displays SnackBar',
        (tester) async {
      final mockCubit = MockJobsCubit();
      when(() => mockCubit.updateJobNotes(
            jobId: '101',
            notes: 'Nova anotação via cubit',
          )).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildSubject(
          cubit: mockCubit,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final notesField = find.byKey(const ValueKey('job_details_notes_field'));
      await tester.enterText(notesField, 'Nova anotação via cubit');
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const ValueKey('job_details_save_notes_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verify(() => mockCubit.updateJobNotes(
            jobId: '101',
            notes: 'Nova anotação via cubit',
          )).called(1);
      expect(find.text('Anotações salvas com sucesso.'), findsOneWidget);
    });

    testWidgets('displays error SnackBar when saving notes throws an exception',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          onSaveNotes: (_) async => throw Exception('Falha no banco de dados'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const ValueKey('job_details_save_notes_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro ao salvar anotações'), findsOneWidget);
    });

    testWidgets('closes modal when close button is tapped', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      expect(find.text('Staff Flutter Engineer'), findsOneWidget);

      final closeButton = find.byTooltip('Fechar');
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.text('Staff Flutter Engineer'), findsNothing);
    });

    testWidgets('renders copy markdown button and triggers onConvertToMarkdown',
        (tester) async {
      String? convertedUrl;

      await tester.pumpWidget(
        buildSubject(
          onConvertToMarkdown: (url) async {
            convertedUrl = url;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final markdownButton = find.byKey(const ValueKey('job_details_copy_markdown_button'));
      expect(markdownButton, findsOneWidget);
      expect(find.text('Copiar em Markdown'), findsOneWidget);

      await tester.tap(markdownButton);
      await tester.pumpAndSettle();

      expect(convertedUrl, equals('https://example.com/jobs/101'));
    });

    testWidgets('disables copy markdown button when jobUrl is empty',
        (tester) async {
      final jobWithoutUrl = sampleJob.copyWith(jobUrl: '');

      await tester.pumpWidget(buildSubject(job: jobWithoutUrl));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final button = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('job_details_copy_markdown_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('converts to markdown via markdownCubit and displays success SnackBar',
        (tester) async {
      final mockMarkdownCubit = MockJobMarkdownCubit();
      final content = JobMarkdownContent(
        jobId: '101',
        jobUrl: 'https://example.com/jobs/101',
        markdown: '# Test Job Markdown',
        convertedAt: DateTime(2026, 10, 22),
      );

      when(() => mockMarkdownCubit.state).thenReturn(
        JobMarkdownSuccess(content: content, copiedToClipboard: true),
      );
      when(() => mockMarkdownCubit.convertAndCopy(
            jobId: '101',
            jobUrl: 'https://example.com/jobs/101',
          )).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildSubject(markdownCubit: mockMarkdownCubit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final markdownButton = find.byKey(const ValueKey('job_details_copy_markdown_button'));
      await tester.tap(markdownButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('job_details_markdown_saved_snackbar')),
        findsOneWidget,
      );
      expect(find.text('Markdown da vaga copiado com sucesso!'), findsOneWidget);
      expect(find.byKey(const ValueKey('job_details_view_markdown_button')), findsOneWidget);

      // Tap on view markdown button to open preview dialog
      await tester.tap(find.byKey(const ValueKey('job_details_view_markdown_button')));
      await tester.pumpAndSettle();

      expect(find.text('Markdown da Vaga: Staff Flutter Engineer'), findsOneWidget);
      expect(find.text('# Test Job Markdown'), findsOneWidget);
    });

    testWidgets('displays error SnackBar when markdown conversion fails via cubit',
        (tester) async {
      final mockMarkdownCubit = MockJobMarkdownCubit();

      when(() => mockMarkdownCubit.state).thenReturn(
        const JobMarkdownError(
          jobId: '101',
          errorMessage: 'Erro de conexão com o leitor da Jina AI.',
        ),
      );
      when(() => mockMarkdownCubit.convertAndCopy(
            jobId: '101',
            jobUrl: 'https://example.com/jobs/101',
          )).thenAnswer((_) async => false);

      await tester.pumpWidget(
        buildSubject(markdownCubit: mockMarkdownCubit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final markdownButton = find.byKey(const ValueKey('job_details_copy_markdown_button'));
      await tester.tap(markdownButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('job_details_markdown_error_snackbar')),
        findsOneWidget,
      );
      expect(
        find.text('Erro de conexão com o leitor da Jina AI.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'tapping Visualizar action in SnackBar opens markdown preview dialog without error',
        (tester) async {
      final mockMarkdownCubit = MockJobMarkdownCubit();
      final content = JobMarkdownContent(
        jobId: '101',
        jobUrl: 'https://example.com/jobs/101',
        markdown: '# Test Markdown Preview Content',
        convertedAt: DateTime(2026, 10, 22),
      );

      when(() => mockMarkdownCubit.state).thenReturn(
        JobMarkdownSuccess(content: content, copiedToClipboard: true),
      );
      when(() => mockMarkdownCubit.convertAndCopy(
            jobId: '101',
            jobUrl: 'https://example.com/jobs/101',
          )).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildSubject(markdownCubit: mockMarkdownCubit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      final markdownButton =
          find.byKey(const ValueKey('job_details_copy_markdown_button'));
      await tester.tap(markdownButton);
      await tester.pumpAndSettle();

      expect(find.text('Markdown da vaga copiado com sucesso!'), findsOneWidget);
      final visualizarAction = find.text('Visualizar');
      expect(visualizarAction, findsOneWidget);

      await tester.tap(visualizarAction);
      await tester.pumpAndSettle();

      expect(find.text('Markdown da Vaga: Staff Flutter Engineer'), findsOneWidget);
      expect(find.text('# Test Markdown Preview Content'), findsOneWidget);
    });

    testWidgets('tapping outside modal dismisses it, while tapping inside does not',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      expect(find.text('Staff Flutter Engineer'), findsOneWidget);

      // Tapping inside the modal card does not dismiss
      await tester.tap(find.text('Staff Flutter Engineer'));
      await tester.pumpAndSettle();
      expect(find.text('Staff Flutter Engineer'), findsOneWidget);

      // Tapping at top-left corner (outside the centered modal card)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Staff Flutter Engineer'), findsNothing);
    });
  });
}
