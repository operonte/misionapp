// Verifica que la app principal esté definida y sea un widget válido.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misionapp/main.dart';

void main() {
  test('MisionApp está definida', () {
    expect(MisionApp, isNotNull);
  });

  testWidgets('MisionApp es un StatelessWidget válido', (WidgetTester tester) async {
    expect(const MisionApp(), isA<StatelessWidget>());
  });
}
