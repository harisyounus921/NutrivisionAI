import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_diet/main.dart';

void main() {
  setUpAll(() {
    // Avoid network font fetches during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows the login screen when no session is stored', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const NutrivisionApp());
    await tester.pumpAndSettle();

    expect(find.text('Nutrivision AI'), findsWidgets);
    expect(find.text('Log In'), findsOneWidget);
  });
}
