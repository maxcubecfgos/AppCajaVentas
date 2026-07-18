import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cajarapida/main.dart';
import 'package:cajarapida/providers/database_provider.dart';
import 'mock_datasource.dart';

void main() {
  final mockDatasource = MockPosDatabaseDatasource();

  testWidgets('CajaRápida shows bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [posDataSourceProvider.overrideWithValue(mockDatasource)],
        child: const MicroPOSApp(),
      ),
    );
    // Pump once to start building, then let the FutureProvider resolve
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify bottom navigation is present with 4 tabs
    expect(find.text('Ventas'), findsAtLeastNWidgets(1));
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Cuadre'), findsOneWidget);
    expect(find.text('Contador'), findsOneWidget);
  });

  testWidgets('POS screen shows app bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [posDataSourceProvider.overrideWithValue(mockDatasource)],
        child: const MicroPOSApp(),
      ),
    );
    // Pump once to start building, then let the FutureProvider resolve
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify the POS screen title is shown
    expect(find.text('Ventas'), findsAtLeastNWidgets(1));
  });
}
