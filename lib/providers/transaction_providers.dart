import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/product.dart';
import '../domain/models/transaction.dart';
import 'database_provider.dart';

// ─── Order / Cart State ────────────────────────────────────────

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

class CartNotifier extends StateNotifier<Map<int, CartItem>> {
  CartNotifier() : super({});

  void addProduct(Product product) {
    final id = product.id!;
    final existing = state[id];
    if (existing != null) {
      state = {
        ...state,
        id: CartItem(product: product, quantity: existing.quantity + 1),
      };
    } else {
      state = {...state, id: CartItem(product: product, quantity: 1)};
    }
  }

  void removeProduct(Product product) {
    final id = product.id!;
    final existing = state[id];
    if (existing == null) return;
    if (existing.quantity > 1) {
      state = {
        ...state,
        id: CartItem(product: product, quantity: existing.quantity - 1),
      };
    } else {
      state = {
        for (final e in state.entries)
          if (e.key != id) e.key: e.value,
      };
    }
  }

  void updateQuantity(Product product, int quantity) {
    final id = product.id!;
    if (quantity <= 0) {
      state = {
        for (final e in state.entries)
          if (e.key != id) e.key: e.value,
      };
    } else {
      state = {...state, id: CartItem(product: product, quantity: quantity)};
    }
  }

  void clear() => state = {};

  int get totalItems =>
      state.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      state.values.fold(0.0, (sum, item) => sum + item.subtotal);
  List<CartItem> get items => state.values.toList();
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<int, CartItem>>(
  (ref) => CartNotifier(),
);

// ─── Transaction recording ─────────────────────────────────────

final salesListProvider = FutureProvider.autoDispose
    .family<List<Transaction>, DateTime>((ref, date) async {
      final datasource = ref.watch(posDataSourceProvider);
      return datasource.getTransactionsByDate(date);
    });
