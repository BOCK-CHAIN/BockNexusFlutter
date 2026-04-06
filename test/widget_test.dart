import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:commerce_app/main.dart';

void main() {
  testWidgets('App builds and renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NexusCommerceApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
