import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/count_entry.dart';
import '../domain/models/denomination.dart';

/// Estado del contador: lista de entries con cantidad por denominación
class CountingState {
  final List<CountEntry> entries;
  final bool isLoading;

  const CountingState({required this.entries, this.isLoading = false});

  double get grandTotal =>
      entries.fold(0.0, (sum, entry) => sum + entry.subtotal);

  CountingState copyWith({List<CountEntry>? entries, bool? isLoading}) {
    return CountingState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CountingNotifier extends StateNotifier<CountingState> {
  CountingNotifier() : super(const CountingState(entries: []));

  /// Inicializa las denominaciones (llamar después de cargar desde storage)
  void initializeDenominations(List<Denomination> denominations) {
    state = CountingState(
      entries: denominations.map((d) => CountEntry(denomination: d)).toList(),
    );
  }

  /// Actualiza la cantidad de una denominación específica
  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= state.entries.length) return;

    final updatedEntries = [...state.entries];
    updatedEntries[index] = updatedEntries[index].copyWith(
      quantity: quantity < 0 ? 0 : quantity,
    );
    state = state.copyWith(entries: updatedEntries);
  }

  /// Resetea todas las cantidades a 0
  void resetAll() {
    state = state.copyWith(
      entries: state.entries.map((e) => e.copyWith(quantity: 0)).toList(),
    );
  }

  /// Actualiza la lista de denominaciones (desde settings)
  void updateDenominations(List<Denomination> denominations) {
    // Preservar cantidades existentes para denominaciones que coincidan
    final existingMap = <double, int>{};
    for (final entry in state.entries) {
      existingMap[entry.denomination.value] = entry.quantity;
    }

    state = CountingState(
      entries: denominations.map((d) {
        final existingQty = existingMap[d.value] ?? 0;
        return CountEntry(denomination: d, quantity: existingQty);
      }).toList(),
    );
  }
}
