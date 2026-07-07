import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../../core/i18n/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/received_report.dart';
import '../../providers/database_provider.dart';

class ReceiveReportScreen extends ConsumerStatefulWidget {
  const ReceiveReportScreen({super.key});

  @override
  ConsumerState<ReceiveReportScreen> createState() =>
      _ReceiveReportScreenState();
}

class _ReceiveReportScreenState extends ConsumerState<ReceiveReportScreen> {
  bool _isScanning = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.receiveTitle), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: _isScanning
                ? MobileScanner(
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode != null && barcode.rawValue != null) {
                        _processQrData(barcode.rawValue!);
                      }
                    },
                  )
                : _buildResultView(theme, strings),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultView(ThemeData theme, AppStrings strings) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(strings.scanQr, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            strings.scanHint,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _processQrData(String qrData) async {
    setState(() {
      _isScanning = false;
      _errorMessage = null;
    });

    try {
      final decoded = jsonDecode(qrData) as Map<String, dynamic>;
      final reportDate = decoded['d'] as String;
      final totalIncome = (decoded['t'] as num).toDouble();
      final transactionCount = decoded['c'] as int;
      final breakdown = decoded['b'] as List<dynamic>?;
      final breakdownJson = jsonEncode(breakdown ?? []);

      final report = ReceivedReport(
        reportDate: reportDate,
        totalIncome: totalIncome,
        transactionCount: transactionCount,
        breakdownJson: breakdownJson,
        receivedAt: DateTime.now().toIso8601String(),
      );

      final datasource = ref.read(posDataSourceProvider);
      await datasource.insertReceivedReport(report);

      if (mounted) {
        _showSuccessDialog(context, report);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${AppStrings.of(context).errorProcessing}: $e';
        _isScanning = true;
      });
    }
  }

  void _showSuccessDialog(BuildContext context, ReceivedReport report) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(strings.reportReceived),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${strings.dateLabel}: ${report.reportDate}'),
            const SizedBox(height: 8),
            Text(
              '${strings.totalLabel}: ${CurrencyFormatter.format(report.totalIncome)}',
            ),
            const SizedBox(height: 8),
            Text('${strings.transactions}: ${report.transactionCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isScanning = true);
            },
            child: Text(strings.accept),
          ),
        ],
      ),
    );
  }
}
