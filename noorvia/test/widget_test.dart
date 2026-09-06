import 'package:flutter_test/flutter_test.dart';
import 'package:noorvia/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});

    await tester.pumpWidget(const MuslimViewApp());
    expect(find.byType(MuslimViewApp), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
