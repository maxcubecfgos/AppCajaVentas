import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Money Counter shows app bar and denomination list', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MoneyCounterApp()));

    // Esperar a que se complete la carga asíncrona
    await tester.pumpAndSettle();

    // Verificar que se muestra el título del AppBar
    expect(find.text('Money Counter'), findsOneWidget);

    // Verificar que se muestra el header de denominaciones
    expect(find.text('Denominaciones'), findsOneWidget);

    // Verificar que hay un botón de ajustes
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
  });

  testWidgets('Money Counter shows total bar when data loads', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MoneyCounterApp()));

    // Esperar a que se complete la carga asíncrona
    await tester.pumpAndSettle();

    // Verificar que se muestra el total
    expect(find.text('TOTAL'), findsOneWidget);
  });
}
