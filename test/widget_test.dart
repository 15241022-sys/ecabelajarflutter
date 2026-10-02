import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecabelajarflutter/main.dart';

void main() {
  testWidgets('Aplikasi tampil dengan splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CoffeeShopApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
