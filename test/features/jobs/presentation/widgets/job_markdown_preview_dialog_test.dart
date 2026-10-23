import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/job_markdown_preview_dialog.dart';

void main() {
  Widget buildTestWidget({
    required String title,
    required String markdown,
    Future<void> Function(String)? onCopy,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showJobMarkdownPreviewDialog(
              context,
              title: title,
              markdown: markdown,
              onCopy: onCopy,
            ),
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('JobMarkdownPreviewDialog', () {
    testWidgets('renders title and markdown content correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          title: 'Senior Developer',
          markdown: '# Flutter Developer\n\nRequirements and benefits',
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Markdown da Vaga: Senior Developer'), findsOneWidget);
      expect(
        find.text('# Flutter Developer\n\nRequirements and benefits'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('markdown_preview_copy_button')),
        findsOneWidget,
      );
    });

    testWidgets('triggers copy callback when copy button is pressed', (tester) async {
      String? copiedText;

      await tester.pumpWidget(
        buildTestWidget(
          title: 'Senior Developer',
          markdown: '# Job Markdown Content',
          onCopy: (text) async {
            copiedText = text;
          },
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('markdown_preview_copy_button')));
      await tester.pump();

      expect(copiedText, equals('# Job Markdown Content'));
    });
  });
}
