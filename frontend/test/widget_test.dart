import 'package:flutter_test/flutter_test.dart';
import 'package:kamjodo_frontend/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KamJodoApp());
    expect(find.byType(KamJodoApp), findsOneWidget);
  });
}
