import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_hunter_app/core/constants/app_constants.dart';
import 'package:job_hunter_app/core/theme/app_typography.dart';
import 'package:job_hunter_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTypography.useSystemFonts = true;
  });

  tearDownAll(() {
    AppTypography.useSystemFonts = false;
  });

  testWidgets('JobHunterApp bootstrap screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const JobHunterApp());
    await tester.pumpAndSettle();

    // Verify app title and terminal badge
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('JH-CORE'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);

    // Verify foundational modules card
    expect(find.text('Spec 001: Bootstrap & Arquitetura Frontend'), findsOneWidget);
    expect(find.text('core/theme'), findsOneWidget);
    expect(find.text('core/services'), findsOneWidget);
    expect(find.text('features/jobs'), findsOneWidget);

    // Verify Kanban status chips
    expect(find.textContaining('Nova (new)'), findsOneWidget);
    expect(find.textContaining('Candidatado (applied)'), findsOneWidget);
    expect(find.textContaining('Entrevista (interview)'), findsOneWidget);
    expect(find.textContaining('Proposta (offer)'), findsOneWidget);
    expect(find.textContaining('Rejeitada (rejected)'), findsOneWidget);
  });

  testWidgets('JobHunterApp displays diagnostic warning when bootstrap error occurs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const JobHunterApp(
        bootstrapError: 'Variável SUPABASE_URL não configurada no .env',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONFIG REQUIRED'), findsOneWidget);
    expect(find.text('Atenção: Configuração de Ambiente Pendente'), findsOneWidget);
    expect(
      find.text('Variável SUPABASE_URL não configurada no .env'),
      findsOneWidget,
    );
  });
}
