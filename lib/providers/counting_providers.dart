import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/currency_type.dart';
import 'counting_notifier.dart';
import 'repository_provider.dart';

/// Provider del StateNotifier para el conteo
final countingNotifierProvider =
    StateNotifierProvider<CountingNotifier, CountingState>((ref) {
      return CountingNotifier();
    });

/// Provider asíncrono que carga las denominaciones desde storage
/// y las inyecta en el CountingNotifier
final denominationConfigProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(denominationRepositoryProvider);
  final notifier = ref.watch(countingNotifierProvider.notifier);

  final denominations = await repository.getDenominations();
  notifier.initializeDenominations(denominations);
});

/// Provider para la moneda actual
final currencyTypeProvider = FutureProvider<CurrencyType>((ref) async {
  final repository = ref.watch(denominationRepositoryProvider);
  return repository.getCurrencyType();
});
