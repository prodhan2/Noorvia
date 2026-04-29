import 'package:flutter_test/flutter_test.dart';
import 'package:noorvia/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NoorviaApp());
    expect(find.byType(NoorviaApp), findsOneWidget);
  });
}
