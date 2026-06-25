import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meal_nudge/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows the login screen when no session is stored', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MealNudgeApp());
    await tester.pumpAndSettle();

    expect(find.text('MealNudge'), findsWidgets);
    expect(find.text('Log In'), findsOneWidget);
  });
}
