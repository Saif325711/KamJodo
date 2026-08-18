import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamjodo_cap/main.dart';

void main() {
  testWidgets('KamJodo Cap smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KamJodoCapApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
