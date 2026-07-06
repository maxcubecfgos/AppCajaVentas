import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/daily_summary.dart';
import 'database_provider.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final dailySummaryProvider = FutureProvider.autoDispose
    .family<DailySummary?, DateTime>((ref, date) async {
      final datasource = ref.watch(posDataSourceProvider);
      return datasource.getDailySummary(date);
    });
