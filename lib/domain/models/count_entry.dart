import 'denomination.dart';

class CountEntry {
  final Denomination denomination;
  final int quantity;

  const CountEntry({required this.denomination, this.quantity = 0});

  double get subtotal => denomination.value * quantity;

  CountEntry copyWith({Denomination? denomination, int? quantity}) {
    return CountEntry(
      denomination: denomination ?? this.denomination,
      quantity: quantity ?? this.quantity,
    );
  }
}
