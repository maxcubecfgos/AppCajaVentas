import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/currency_type.dart';
import '../../providers/counting_notifier.dart';
import '../../providers/counting_providers.dart';
import '../widgets/denomination_row.dart';
import '../widgets/total_sticky_bar.dart';
import 'settings_screen.dart';

class CountingScreen extends ConsumerWidget {
  const CountingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cargar configuración inicial
    ref.watch(denominationConfigProvider);
    final countingState = ref.watch(countingNotifierProvider);
    final countingNotifier = ref.watch(countingNotifierProvider.notifier);
    final currencyAsync = ref.watch(currencyTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Ajustes',
            onPressed: () => _openSettings(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con cantidad de denominaciones
          _buildHeader(context, countingState),
          // Lista de denominaciones
          Expanded(
            child: countingState.entries.isEmpty
                ? const Center(
                    child: Text('No hay denominaciones configuradas'),
                  )
                : ListView.builder(
                    itemCount: countingState.entries.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemBuilder: (context, index) {
                      final entry = countingState.entries[index];
                      return DenominationRow(
                        entry: entry,
                        index: index,
                        onQuantityChanged: (qty) {
                          countingNotifier.updateQuantity(index, qty);
                        },
                      );
                    },
                  ),
          ),
          // Sticky total bar
          currencyAsync.when(
            data: (currency) => TotalStickyBar(
              grandTotal: countingState.grandTotal,
              currencyType: currency,
              onReset: () => countingNotifier.resetAll(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => TotalStickyBar(
              grandTotal: countingState.grandTotal,
              currencyType: CurrencyType.usd,
              onReset: () => countingNotifier.resetAll(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CountingState state) {
    final theme = Theme.of(context);
    final activeCount = state.entries.where((e) => e.quantity > 0).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Text('Denominaciones', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${state.entries.length}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (activeCount > 0)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: activeCount > 0 ? 1.0 : 0.0,
              child: Text(
                '$activeCount activas',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openSettings(BuildContext context, WidgetRef ref) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    // Recargar denominaciones después de ajustes
    ref.invalidate(denominationConfigProvider);
    ref.invalidate(currencyTypeProvider);
  }
}
