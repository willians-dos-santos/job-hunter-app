import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_hunter_app/core/theme/app_colors.dart';
import 'package:job_hunter_app/core/theme/app_theme.dart';
import 'package:job_hunter_app/core/theme/app_typography.dart';
import 'package:job_hunter_app/core/theme/kanban_status_colors.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTypography.useSystemFonts = true;
  });

  tearDownAll(() {
    AppTypography.useSystemFonts = false;
  });
  group('AppColors & Dark Mode Stitch Tokens', () {
    test('background and surface tokens match Stitch specification', () {
      expect(AppColors.slate900, const Color(0xFF0F172A));
      expect(AppColors.slate800, const Color(0xFF1E293B));
      expect(AppColors.slate850, const Color(0xFF0F1E2E));
      expect(AppColors.slate700, const Color(0xFF334155));
    });

    test('primary and terminal highlight accents match specification', () {
      expect(AppColors.primaryIndigo, const Color(0xFF6366F1));
      expect(AppColors.terminalCyan, const Color(0xFF38BDF8));
    });

    test('Kanban semantic status palette matches specification', () {
      expect(AppColors.kanbanNew, const Color(0xFF38BDF8));
      expect(AppColors.kanbanApplied, const Color(0xFF8B5CF6));
      expect(AppColors.kanbanInterview, const Color(0xFFF59E0B));
      expect(AppColors.kanbanOffer, const Color(0xFF10B981));
      expect(AppColors.kanbanRejected, const Color(0xFFF43F5E));
    });
  });

  group('AppTheme.darkTheme', () {
    late ThemeData theme;

    setUp(() {
      theme = AppTheme.darkTheme;
    });

    test('has dark brightness and Slate 900 background', () {
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0F172A));
      expect(theme.cardColor, const Color(0xFF1E293B));
    });

    test('color scheme matches design tokens', () {
      expect(theme.colorScheme.primary, AppColors.primaryIndigo);
      expect(theme.colorScheme.secondary, AppColors.terminalCyan);
      expect(theme.colorScheme.surface, AppColors.slate800);
      expect(theme.colorScheme.outline, AppColors.slate700);
      expect(theme.colorScheme.error, AppColors.kanbanRejected);
    });

    test('registers KanbanStatusColors ThemeExtension', () {
      final extension = theme.extension<KanbanStatusColors>();
      expect(extension, isNotNull);
      expect(extension!.newJob, const Color(0xFF38BDF8));
      expect(extension.applied, const Color(0xFF8B5CF6));
      expect(extension.interview, const Color(0xFFF59E0B));
      expect(extension.offer, const Color(0xFF10B981));
      expect(extension.rejected, const Color(0xFFF43F5E));
    });
  });

  group('KanbanStatusColors Extension', () {
    const colors = KanbanStatusColors.dark;

    test('colorFor maps all JobStatus values correctly', () {
      expect(colors.colorFor(JobStatus.newJob), AppColors.kanbanNew);
      expect(colors.colorFor(JobStatus.applied), AppColors.kanbanApplied);
      expect(colors.colorFor(JobStatus.interview), AppColors.kanbanInterview);
      expect(colors.colorFor(JobStatus.offer), AppColors.kanbanOffer);
      expect(colors.colorFor(JobStatus.rejected), AppColors.kanbanRejected);
    });

    test('supports copyWith and equality', () {
      final modified = colors.copyWith(newJob: Colors.white);
      expect(modified.newJob, Colors.white);
      expect(modified.applied, colors.applied);
      expect(modified == colors, isFalse);
      expect(colors == KanbanStatusColors.dark, isTrue);
      expect(colors.hashCode, KanbanStatusColors.dark.hashCode);
    });

    test('supports lerp interpolation', () {
      final target = colors.copyWith(newJob: Colors.white);
      final interpolated = colors.lerp(target, 0.5);
      expect(interpolated, isNotNull);
      expect(interpolated.applied, colors.applied);
    });

    testWidgets('context.kanbanColors resolves from widget tree', (tester) async {
      late KanbanStatusColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              resolved = context.kanbanColors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.newJob, AppColors.kanbanNew);
      expect(resolved.applied, AppColors.kanbanApplied);
    });
  });
}
