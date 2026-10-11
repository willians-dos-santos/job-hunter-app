import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_hunter_app/core/theme/app_theme.dart';
import 'package:job_hunter_app/core/theme/app_typography.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/job_card.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/kanban_column.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTypography.useSystemFonts = true;
  });

  tearDownAll(() {
    AppTypography.useSystemFonts = false;
  });

  final testJob1 = JobItem(
    jobId: '1',
    title: 'Flutter Developer',
    companyName: 'Company A',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/1',
    status: JobStatus.interview,
    createdAt: DateTime.now(),
  );

  final testJob2 = JobItem(
    jobId: '2',
    title: 'Senior Dart Engineer',
    companyName: 'Company B',
    platform: 'Gupy',
    jobUrl: 'https://example.com/2',
    status: JobStatus.interview,
    createdAt: DateTime.now(),
  );

  Widget buildSubject({
    required JobStatus status,
    required List<JobItem> jobs,
    void Function(JobItem)? onJobTap,
    void Function(JobItem, JobStatus)? onMoveJobStatus,
    void Function(JobItem)? onArchiveJob,
    void Function(JobItem, JobStatus)? onJobDropped,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 600,
            child: KanbanColumn(
              status: status,
              jobs: jobs,
              onJobTap: onJobTap,
              onMoveJobStatus: onMoveJobStatus,
              onArchiveJob: onArchiveJob,
              onJobDropped: onJobDropped,
            ),
          ),
        ),
      ),
    );
  }

  group('KanbanColumn Widget', () {
    testWidgets('triggers onJobTap when a job card in the column is tapped',
        (tester) async {
      JobItem? tappedJob;
      await tester.pumpWidget(
        buildSubject(
          status: JobStatus.interview,
          jobs: [testJob1],
          onJobTap: (job) => tappedJob = job,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flutter Developer'));
      await tester.pumpAndSettle();

      expect(tappedJob, equals(testJob1));
    });
    testWidgets('renders column header with status label and card count',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          status: JobStatus.interview,
          jobs: [testJob1, testJob2],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entrevista'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byType(JobCard), findsNWidgets(2));
    });

    testWidgets('renders empty state when jobs list is empty', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          status: JobStatus.offer,
          jobs: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Proposta'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Nenhuma vaga nesta etapa'), findsOneWidget);
      expect(find.byType(JobCard), findsNothing);
    });

    testWidgets('triggers onMoveJobStatus when action selected from child card',
        (tester) async {
      JobItem? movedJob;
      JobStatus? targetStatus;

      await tester.pumpWidget(
        buildSubject(
          status: JobStatus.interview,
          jobs: [testJob1],
          onMoveJobStatus: (job, status) {
            movedJob = job;
            targetStatus = status;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mover para Proposta'));
      await tester.pumpAndSettle();

      expect(movedJob?.jobId, '1');
      expect(targetStatus, JobStatus.offer);
    });

    testWidgets('allows vertical scrolling of multiple cards while keeping header fixed',
        (tester) async {
      final manyJobs = List.generate(
        20,
        (i) => JobItem(
          jobId: 'job_$i',
          title: 'Vaga número $i',
          companyName: 'Empresa $i',
          platform: 'LinkedIn',
          jobUrl: 'https://example.com/$i',
          status: JobStatus.newJob,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildSubject(
          status: JobStatus.newJob,
          jobs: manyJobs,
        ),
      );
      await tester.pumpAndSettle();

      // Header is visible with count 20
      expect(find.text('Nova'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      // Card 0 is initially visible, card 19 is offstage
      expect(find.text('Vaga número 0'), findsOneWidget);

      // Scroll the ListView vertically down
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      await tester.drag(listView, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Header remains fixed and still visible
      expect(find.text('Nova'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      // Can scroll until reaching later cards
      await tester.scrollUntilVisible(
        find.text('Vaga número 15'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Vaga número 15'), findsOneWidget);
      expect(find.text('Nova'), findsOneWidget);
    });

    testWidgets('triggers onJobDropped when a JobItem is dropped onto the DragTarget',
        (tester) async {
      JobItem? droppedJob;
      JobStatus? droppedStatus;

      await tester.pumpWidget(
        buildSubject(
          status: JobStatus.offer,
          jobs: const [],
          onJobDropped: (job, status) {
            droppedJob = job;
            droppedStatus = status;
          },
        ),
      );
      await tester.pumpAndSettle();

      final dragTargetFinder = find.byType(DragTarget<JobItem>);
      expect(dragTargetFinder, findsOneWidget);

      final dragTarget =
          tester.widget<DragTarget<JobItem>>(dragTargetFinder);

      // Accepts different status
      final willAccept = dragTarget.onWillAcceptWithDetails!(
        DragTargetDetails<JobItem>(
          data: testJob1,
          offset: Offset.zero,
        ),
      );
      expect(willAccept, isTrue);

      // Rejects same status
      final willReject = dragTarget.onWillAcceptWithDetails!(
        DragTargetDetails<JobItem>(
          data: testJob1.copyWith(status: JobStatus.offer),
          offset: Offset.zero,
        ),
      );
      expect(willReject, isFalse);

      // Triggers drop callback
      dragTarget.onAcceptWithDetails!(
        DragTargetDetails<JobItem>(
          data: testJob1,
          offset: Offset.zero,
        ),
      );
      await tester.pumpAndSettle();

      expect(droppedJob?.jobId, '1');
      expect(droppedStatus, JobStatus.offer);
    });

    testWidgets('falls back to onMoveJobStatus when onJobDropped is not provided',
        (tester) async {
      JobItem? movedJob;
      JobStatus? movedStatus;

      await tester.pumpWidget(
        buildSubject(
          status: JobStatus.offer,
          jobs: const [],
          onMoveJobStatus: (job, status) {
            movedJob = job;
            movedStatus = status;
          },
        ),
      );
      await tester.pumpAndSettle();

      final dragTarget =
          tester.widget<DragTarget<JobItem>>(find.byType(DragTarget<JobItem>));

      dragTarget.onAcceptWithDetails!(
        DragTargetDetails<JobItem>(
          data: testJob1,
          offset: Offset.zero,
        ),
      );
      await tester.pumpAndSettle();

      expect(movedJob?.jobId, '1');
      expect(movedStatus, JobStatus.offer);
    });

    testWidgets('supports drag and drop gesture from child card to another column',
        (tester) async {
      JobItem? droppedJob;
      JobStatus? targetStatus;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 300,
                  height: 600,
                  child: KanbanColumn(
                    status: JobStatus.newJob,
                    jobs: [testJob1.copyWith(status: JobStatus.newJob)],
                  ),
                ),
                SizedBox(
                  width: 300,
                  height: 600,
                  child: KanbanColumn(
                    status: JobStatus.applied,
                    jobs: const [],
                    onJobDropped: (job, status) {
                      droppedJob = job;
                      targetStatus = status;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.text('Flutter Developer');
      expect(cardFinder, findsOneWidget);

      // Start drag gesture on the card
      final gesture = await tester.startGesture(tester.getCenter(cardFinder));
      await tester.pump(const Duration(milliseconds: 300)); // Trigger long press drag

      // Move over to the second column (offset around x = 450, y = 200)
      await gesture.moveTo(const Offset(450, 200));
      await tester.pump();

      // Release drop over the second column
      await gesture.up();
      await tester.pumpAndSettle();

      expect(droppedJob?.jobId, '1');
      expect(targetStatus, JobStatus.applied);
    });
  });
}
