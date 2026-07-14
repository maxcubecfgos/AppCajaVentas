import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/daily_report_helper.dart';
import '../../core/utils/qr_report_helper.dart';
import '../../domain/models/daily_summary.dart';
import '../../providers/daily_summary_providers.dart';
import '../widgets/app_drawer.dart';
import 'receive_report_screen.dart';

class DailyCloseScreen extends ConsumerStatefulWidget {
  const DailyCloseScreen({super.key});

  @override
  ConsumerState<DailyCloseScreen> createState() => _DailyCloseScreenState();
}

class _DailyCloseScreenState extends ConsumerState<DailyCloseScreen> {
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(dailySummaryProvider(selectedDate));
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(strings.dailyCloseTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: strings.receiveReport,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReceiveReportScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: strings.generateQr,
            onPressed: () async {
              final selectedDate = ref.read(selectedDateProvider);
              final summaryAsync = ref.read(dailySummaryProvider(selectedDate));
              final summary = summaryAsync.value;
              if (summary == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.noDataQr),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }
              if (context.mounted) {
                _showQrDialog(context, summary);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: strings.exportPdf,
            onPressed: () async {
              final selectedDate = ref.read(selectedDateProvider);
              final summaryAsync = ref.read(dailySummaryProvider(selectedDate));
              final summary = summaryAsync.value;
              if (summary == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.noDataQr),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }
              try {
                await DailyReportHelper.shareDailyReport(summary);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${strings.error}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) {
          if (summary == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${strings.noDataForDate} ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final selectedDate = ref.read(selectedDateProvider);
              ref.invalidate(dailySummaryProvider(selectedDate));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  DateFormat(
                    'EEEE, dd \'de\' MMMM \'del\' yyyy',
                    'es',
                  ).format(summary.date).toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: strings.totalIncome,
                        value: CurrencyFormatter.format(summary.totalIncome),
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: strings.transactions,
                        value: '${summary.transactionCount}',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  strings.breakdownByProduct,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (summary.breakdown.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          strings.noProductData,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
                else
                  ...summary.breakdown.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Text(
                            '${item.quantitySold}',
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(item.productName),
                        subtitle: Text(strings.sold(item.quantitySold)),
                        trailing: Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${strings.error}: $e')),
      ),
    );
  }

  void _showQrDialog(BuildContext context, DailySummary summary) {
    final strings = AppStrings.of(context);
    try {
      final qrData = QrReportHelper.serializeSummary(summary);
      final qrImage = QrReportHelper.buildQr(qrData);

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(strings.qrTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: qrImage),
              const SizedBox(height: 16),
              Text(
                DateFormat('dd/MM/yyyy').format(summary.date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${strings.totalLabel}: ${CurrencyFormatter.format(summary.totalIncome)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(strings.close),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error generando QR: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.errorQr}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final currentDate = ref.read(selectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      final newDate = DateTime(picked.year, picked.month, picked.day);
      ref.read(selectedDateProvider.notifier).state = newDate;
      ref.invalidate(dailySummaryProvider(newDate));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
