import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/daily_summary.dart';

class DailyReportHelper {
  DailyReportHelper._();

  static pw.Document generateDailyReportPdf(DailySummary summary) {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Cuadre Diario',
                style: const pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                dateFormat.format(summary.date),
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Text(
                'Ingresos Totales: ${currencyFormat.format(summary.totalIncome)}',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Transacciones: ${summary.transactionCount}',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Desglose por Producto',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              ...summary.breakdown.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          item.productName,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ),
                      pw.Text(
                        '${item.quantitySold} vendido(s)',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Text(
                        currencyFormat.format(item.subtotal),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static Future<void> shareDailyReport(DailySummary summary) async {
    final pdf = generateDailyReportPdf(summary);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'cuadre_${DateFormat('yyyyMMdd').format(summary.date)}.pdf',
    );
  }
}
