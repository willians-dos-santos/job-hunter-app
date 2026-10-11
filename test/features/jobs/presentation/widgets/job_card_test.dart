import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_hunter_app/core/theme/app_theme.dart';
import 'package:job_hunter_app/core/theme/app_typography.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/job_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTypography.useSystemFonts = true;
  });

  tearDownAll(() {
    AppTypography.useSystemFonts = false;
  });

  final testJob = JobItem(
    jobId: 'job_42',
    title: 'Senior Flutter Architect',
    companyName: 'Stitch Labs',
    platform: 'LinkedIn',
    jobUrl: 'https://stitchlabs.example.com/flutter',
    status: JobStatus.newJob,
    location: 'Remoto - Brasil',
    salaryText: 'R\$ 18.000 - 22.000',
    createdAt: DateTime.now(),
  );

  Widget buildSubject({
    JobItem? job,
    VoidCallback? onTap,
    ValueChanged<JobStatus>? onMoveStatus,
    VoidCallback? onArchive,
    VoidCallback? onOpenUrl,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: JobCard(
              job: job ?? testJob,
              enableDrag: false,
              onTap: onTap,
              onMoveStatus: onMoveStatus,
              onArchive: onArchive,
              onOpenUrl: onOpenUrl,
            ),
          ),
        ),
      ),
    );
  }

  group('JobCard Widget', () {
    testWidgets('triggers onTap callback when card is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildSubject(
          onTap: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Senior Flutter Architect'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
    testWidgets('renders job details and badges correctly', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Senior Flutter Architect'), findsOneWidget);
      expect(find.text('Stitch Labs'), findsOneWidget);
      expect(find.text('Remoto - Brasil'), findsOneWidget);
      expect(find.text('LinkedIn'), findsOneWidget);
      expect(find.text('R\$ 18.000 - 22.000'), findsOneWidget);
      expect(find.text('Remoto'), findsOneWidget);
    });

    testWidgets('triggers onMoveStatus callback when moving status from action menu',
        (tester) async {
      JobStatus? movedTo;

      await tester.pumpWidget(
        buildSubject(
          onMoveStatus: (status) => movedTo = status,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on popup menu button
      final menuButton = find.byType(PopupMenuButton<String>);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Expect options to move to other statuses
      expect(find.text('Mover para Candidatado'), findsOneWidget);
      expect(find.text('Mover para Entrevista'), findsOneWidget);
      expect(find.text('Mover para Proposta'), findsOneWidget);
      expect(find.text('Mover para Rejeitada'), findsOneWidget);

      // Select 'Mover para Entrevista'
      await tester.tap(find.text('Mover para Entrevista'));
      await tester.pumpAndSettle();

      expect(movedTo, JobStatus.interview);
    });

    testWidgets('triggers onArchive callback when selecting archive from menu',
        (tester) async {
      bool archivedCalled = false;

      await tester.pumpWidget(
        buildSubject(
          onArchive: () => archivedCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Arquivar vaga'), findsOneWidget);
      await tester.tap(find.text('Arquivar vaga'));
      await tester.pumpAndSettle();

      expect(archivedCalled, isTrue);
    });

    testWidgets('triggers onOpenUrl callback when selecting open url from menu',
        (tester) async {
      bool openUrlCalled = false;

      await tester.pumpWidget(
        buildSubject(
          onOpenUrl: () => openUrlCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Abrir link externo'), findsOneWidget);
      await tester.tap(find.text('Abrir link externo'));
      await tester.pumpAndSettle();

      expect(openUrlCalled, isTrue);
    });
  });
}
