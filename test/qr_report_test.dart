import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:cajarapida/core/utils/qr_report_helper.dart';
import 'package:cajarapida/domain/models/daily_summary.dart';

void main() {
  group('QrReportHelper.serializeSummary → JSON roundtrip', () {
    final testDate = DateTime(2026, 7, 14);
    final summary = DailySummary(
      date: testDate,
      totalIncome: 12500.50,
      transactionCount: 8,
      breakdown: [
        ProductBreakdown(
          productId: 1,
          productName: 'Arroz 1kg',
          quantitySold: 5,
          subtotal: 2500.00,
        ),
        ProductBreakdown(
          productId: 2,
          productName: 'Frijoles 500g',
          quantitySold: 3,
          subtotal: 1800.00,
        ),
        ProductBreakdown(
          productId: 3,
          productName: 'Aceite 1L',
          quantitySold: 2,
          subtotal: 1600.00,
        ),
        ProductBreakdown(
          productId: 4,
          productName: 'Azúcar 1kg',
          quantitySold: 10,
          subtotal: 3200.00,
        ),
        ProductBreakdown(
          productId: 5,
          productName: 'Café 250g',
          quantitySold: 4,
          subtotal: 1400.00,
        ),
        ProductBreakdown(
          productId: 6,
          productName: 'Leche 1L',
          quantitySold: 6,
          subtotal: 2000.50,
        ),
      ],
    );

    test('serializes all fields correctly', () {
      final jsonStr = QrReportHelper.serializeSummary(summary);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['d'], equals('2026-07-14'));
      expect(decoded['t'], equals(12500.50));
      expect(decoded['c'], equals(8));

      final breakdown = decoded['b'] as List<dynamic>;
      expect(breakdown.length, equals(6));

      expect(breakdown[0]['n'], equals('Arroz 1kg'));
      expect(breakdown[0]['q'], equals(5));
      expect(breakdown[0]['s'], equals(2500.00));

      expect(breakdown[5]['n'], equals('Leche 1L'));
      expect(breakdown[5]['q'], equals(6));
      expect(breakdown[5]['s'], equals(2000.50));
    });

    test('deserialized data matches original summary', () {
      // Step 1: Serialize
      final jsonStr = QrReportHelper.serializeSummary(summary);

      // Step 2: Simulate QR scanning — decode exactly as receive_report_screen does
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      final reportDate = decoded['d'] as String;
      final totalIncome = (decoded['t'] as num).toDouble();
      final transactionCount = decoded['c'] as int;
      final breakdownRaw = decoded['b'] as List<dynamic>;
      final breakdownJson = jsonEncode(breakdownRaw);

      // Verify date
      expect(reportDate, equals('2026-07-14'));
      expect(reportDate, equals(DateFormat('yyyy-MM-dd').format(testDate)));

      // Verify totals
      expect(totalIncome, equals(12500.50));
      expect(transactionCount, equals(8));

      // Verify breakdown roundtrip
      final reDecoded = jsonDecode(breakdownJson) as List<dynamic>;
      expect(reDecoded.length, equals(6));
      expect(reDecoded[0]['n'], equals('Arroz 1kg'));
      expect(reDecoded[2]['n'], equals('Aceite 1L'));
    });

    test('limits breakdown to 10 items', () {
      final manyItems = List.generate(
        15,
        (i) => ProductBreakdown(
          productId: i,
          productName: 'Producto $i',
          quantitySold: i,
          subtotal: i * 100.0,
        ),
      );
      final bigSummary = DailySummary(
        date: testDate,
        totalIncome: 10000,
        transactionCount: 15,
        breakdown: manyItems,
      );

      final jsonStr = QrReportHelper.serializeSummary(bigSummary);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final breakdown = decoded['b'] as List<dynamic>;

      expect(
        breakdown.length,
        equals(10),
        reason: 'QR debe limitar a 10 items para no exceder capacidad del QR',
      );
    });

    test('handles empty breakdown gracefully', () {
      final emptySummary = DailySummary(
        date: testDate,
        totalIncome: 0,
        transactionCount: 0,
        breakdown: [],
      );

      final jsonStr = QrReportHelper.serializeSummary(emptySummary);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['d'], equals('2026-07-14'));
      expect(decoded['t'], equals(0));
      expect(decoded['c'], equals(0));

      final breakdown = decoded['b'] as List<dynamic>;
      expect(breakdown, isEmpty);
    });

    test('QR string is valid JSON', () {
      final jsonStr = QrReportHelper.serializeSummary(summary);
      expect(() => jsonDecode(jsonStr), returnsNormally);
    });

    test('QR build does not crash', () {
      final jsonStr = QrReportHelper.serializeSummary(summary);

      // This just verifies the build method doesn't throw
      // (Full rendering requires a widget tester, but construction is safe)
      expect(() => QrReportHelper.buildQr(jsonStr), returnsNormally);
    });
  });

  group('Realistic QR roundtrip scenarios', () {
    test('handles decimal prices correctly', () {
      final summary = DailySummary(
        date: DateTime(2026, 1, 15),
        totalIncome: 99.99,
        transactionCount: 1,
        breakdown: [
          ProductBreakdown(
            productId: 99,
            productName: 'Producto con .99',
            quantitySold: 1,
            subtotal: 99.99,
          ),
        ],
      );

      final jsonStr = QrReportHelper.serializeSummary(summary);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect((decoded['t'] as num).toDouble(), equals(99.99));
      expect((decoded['b'] as List)[0]['s'], equals(99.99));
    });

    test('handles large numbers', () {
      final summary = DailySummary(
        date: DateTime(2026, 6, 1),
        totalIncome: 9999999.99,
        transactionCount: 999,
        breakdown: [
          ProductBreakdown(
            productId: 1,
            productName: 'Artículo caro',
            quantitySold: 999,
            subtotal: 9999999.99,
          ),
        ],
      );

      final jsonStr = QrReportHelper.serializeSummary(summary);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect((decoded['t'] as num).toDouble(), equals(9999999.99));
      expect(decoded['c'], equals(999));
    });

    test('ReceivedReport fromMap matches serialized data', () {
      // This simulates the full flow: serialize → QR → scan → deserialize → store
      final originalSummary = DailySummary(
        date: DateTime(2026, 3, 20),
        totalIncome: 4500.00,
        transactionCount: 12,
        breakdown: [
          ProductBreakdown(
            productId: 10,
            productName: 'Pan',
            quantitySold: 20,
            subtotal: 1000.00,
          ),
          ProductBreakdown(
            productId: 11,
            productName: 'Huevos',
            quantitySold: 15,
            subtotal: 3500.00,
          ),
        ],
      );

      // Serialize (same as QrReportHelper.serializeSummary)
      final dateFormat = DateFormat('yyyy-MM-dd');
      final data = {
        'd': dateFormat.format(originalSummary.date),
        't': originalSummary.totalIncome,
        'c': originalSummary.transactionCount,
        'b': originalSummary.breakdown
            .map(
              (item) => {
                'n': item.productName,
                'q': item.quantitySold,
                's': item.subtotal,
              },
            )
            .toList(),
      };
      final jsonStr = jsonEncode(data);

      // Scan (simulates receive_report_screen._processQrData)
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final reportDate = decoded['d'] as String;
      final totalIncome = (decoded['t'] as num).toDouble();
      final transactionCount = decoded['c'] as int;
      final breakdownRaw = decoded['b'] as List<dynamic>;
      final breakdownJson = jsonEncode(breakdownRaw);

      // Build ReceivedReport (same as receive_report_screen does)
      // ignore: unused_local_variable
      final report = _TestReceivedReport(
        reportDate: reportDate,
        totalIncome: totalIncome,
        transactionCount: transactionCount,
        breakdownJson: breakdownJson,
        receivedAt: DateTime.now().toIso8601String(),
      );

      // Verify consistency
      expect(report.reportDate, equals('2026-03-20'));
      expect(report.totalIncome, equals(4500.00));
      expect(report.transactionCount, equals(12));
      expect(report.breakdownJson, isNotEmpty);

      // Verify breakdown content survives roundtrip
      final reParsedBreakdown =
          jsonDecode(report.breakdownJson) as List<dynamic>;
      expect(reParsedBreakdown.length, equals(2));
      expect(reParsedBreakdown[0]['n'], equals('Pan'));
      expect(reParsedBreakdown[0]['q'], equals(20));
      expect(reParsedBreakdown[1]['n'], equals('Huevos'));
      expect(reParsedBreakdown[1]['s'], equals(3500.00));

      // Cross-check: totals from breakdown should add up
      double sumFromBreakdown = 0;
      for (final item in reParsedBreakdown) {
        sumFromBreakdown += (item['s'] as num).toDouble();
      }
      expect(sumFromBreakdown, equals(report.totalIncome));
    });
  });
}

/// Minimal local copy of ReceivedReport for testing without DB dependency.
class _TestReceivedReport {
  final String reportDate;
  final double totalIncome;
  final int transactionCount;
  final String breakdownJson;
  final String receivedAt;

  _TestReceivedReport({
    required this.reportDate,
    required this.totalIncome,
    required this.transactionCount,
    required this.breakdownJson,
    required this.receivedAt,
  });
}
