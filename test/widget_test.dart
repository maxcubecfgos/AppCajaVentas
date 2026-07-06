import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cajarapida/main.dart';

void main() {
  testWidgets('CajaRápida shows bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MicroPOSApp()));
    await tester.pumpAndSettle();

    // Verify bottom navigation is present with 4 tabs
    expect(find.text('Ventas'), findsOneWidget);
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Cuadre'), findsOneWidget);
    expect(find.text('Contador'), findsOneWidget);
  });

  testWidgets('POS screen shows app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MicroPOSApp()));
    await tester.pumpAndSettle();

    // Verify the POS screen title is shown
    expect(find.text('Ventas'), findsOneWidget);
  });
}
