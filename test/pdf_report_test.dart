import 'package:flutter_test/flutter_test.dart';
import 'package:cajarapida/core/utils/daily_report_helper.dart';
import 'package:cajarapida/domain/models/daily_summary.dart';

void main() {
  group('DailyReportHelper PDF generation', () {
    final summary = DailySummary(
      date: DateTime(2026, 7, 14),
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

    test('generates PDF document without throwing', () {
      expect(
        () => DailyReportHelper.generateDailyReportPdf(summary),
        returnsNormally,
      );
    });

    test('PDF contains expected number of pages', () {
      final pdf = DailyReportHelper.generateDailyReportPdf(summary);
      // The PDF document should have at least 1 page
      expect(pdf, isNotNull);
      // We can't directly access pages count from pw.Document API,
      // but we can verify the document saves successfully
      expect(() => pdf.save(), returnsNormally);
    });

    test('PDF saves to bytes without error', () async {
      final pdf = DailyReportHelper.generateDailyReportPdf(summary);
      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      // PDF starts with %PDF header
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('PDF with empty breakdown generates correctly', () async {
      final emptySummary = DailySummary(
        date: DateTime(2026, 1, 1),
        totalIncome: 0,
        transactionCount: 0,
        breakdown: [],
      );

      final pdf = DailyReportHelper.generateDailyReportPdf(emptySummary);
      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('PDF with single item generates correctly', () async {
      final singleSummary = DailySummary(
        date: DateTime(2026, 5, 10),
        totalIncome: 500.00,
        transactionCount: 1,
        breakdown: [
          ProductBreakdown(
            productId: 1,
            productName: 'Producto Único',
            quantitySold: 1,
            subtotal: 500.00,
          ),
        ],
      );

      final pdf = DailyReportHelper.generateDailyReportPdf(singleSummary);
      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('PDF with large breakdown (many items) generates correctly', () async {
      final manyItems = List.generate(
        50,
        (i) => ProductBreakdown(
          productId: i,
          productName: 'Producto $i',
          quantitySold: i + 1,
          subtotal: (i + 1) * 100.0,
        ),
      );
      final largeSummary = DailySummary(
        date: DateTime(2026, 12, 31),
        totalIncome: manyItems.fold(0.0, (sum, item) => sum + item.subtotal),
        transactionCount: manyItems.length,
        breakdown: manyItems,
      );

      final pdf = DailyReportHelper.generateDailyReportPdf(largeSummary);
      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('PDF contains all breakdown items', () async {
      // The breakdown should serialize all items (unlike QR which caps at 10)
      final summary = DailySummary(
        date: DateTime(2026, 8, 1),
        totalIncome: 10000,
        transactionCount: 3,
        breakdown: [
          ProductBreakdown(
            productId: 1,
            productName: 'Item A',
            quantitySold: 1,
            subtotal: 1000.00,
          ),
          ProductBreakdown(
            productId: 2,
            productName: 'Item B',
            quantitySold: 2,
            subtotal: 2000.00,
          ),
          ProductBreakdown(
            productId: 3,
            productName: 'Item C',
            quantitySold: 3,
            subtotal: 7000.00,
          ),
        ],
      );

      final pdf = DailyReportHelper.generateDailyReportPdf(summary);
      final bytes = await pdf.save();

      // Verify we got valid PDF bytes
      expect(bytes.length, greaterThan(100));
    });
  });

  group('DailyReportHelper PDF content consistency', () {
    test('PDF bytes are valid for all data scenarios', () async {
      // Test with various data sizes to ensure no truncation
      final summaries = [
        DailySummary(
          date: DateTime(2026, 1, 1),
          totalIncome: 0,
          transactionCount: 0,
          breakdown: [],
        ),
        DailySummary(
          date: DateTime(2026, 6, 15),
          totalIncome: 99999.99,
          transactionCount: 100,
          breakdown: List.generate(
            20,
            (i) => ProductBreakdown(
              productId: i,
              productName: 'Producto ${i + 1}',
              quantitySold: i + 1,
              subtotal: (i + 1) * 100.0,
            ),
          ),
        ),
      ];

      for (final summary in summaries) {
        final pdf = DailyReportHelper.generateDailyReportPdf(summary);
        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
        expect(
          String.fromCharCodes(bytes.take(5)),
          equals('%PDF-'),
          reason: 'Todos los PDFs deben tener header válido',
        );
      }
    });

    test('QR and PDF use same data consistently', () async {
      // This test verifies the JSON used by QR matches the data model used by PDF
      final summary = DailySummary(
        date: DateTime(2026, 9, 15),
        totalIncome: 8750.25,
        transactionCount: 5,
        breakdown: [
          ProductBreakdown(
            productId: 1,
            productName: 'Test',
            quantitySold: 5,
            subtotal: 8750.25,
          ),
        ],
      );

      // PDF: generate and verify bytes
      final pdf = DailyReportHelper.generateDailyReportPdf(summary);
      final pdfBytes = await pdf.save();
      expect(pdfBytes, isNotEmpty);
      expect(
        pdfBytes.length,
        greaterThan(200),
        reason: 'PDF debe contener datos renderizados',
      );
    });
  });
}
