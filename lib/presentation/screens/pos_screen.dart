import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/product.dart';
import '../../domain/models/transaction.dart';
import '../../providers/product_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/theme_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        centerTitle: true,
        actions: [
          if (cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Badge(
                label: Text('${cartNotifier.totalItems}'),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => _showCartSheet(context, cartNotifier),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Cambiar tema',
            onPressed: () {
              final current = Theme.of(context).brightness;
              final newMode = current == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).state = newMode;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Product grid
          Expanded(
            child: productsAsync.when(
              data: (products) => products.isEmpty
                  ? _emptyState(theme)
                  : _buildProductGrid(products, cartNotifier, theme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          // Cart summary bar
          if (cart.isNotEmpty)
            _CartSummaryBar(
              totalItems: cartNotifier.totalItems,
              totalAmount: cartNotifier.totalAmount,
              onCheckout: () => _checkout(context, cartNotifier),
              onViewCart: () => _showCartSheet(context, cartNotifier),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(height: 16),
        Text('No hay productos', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Agrega productos desde el catálogo',
          style: theme.textTheme.bodySmall,
        ),
      ],
    ),
  );

  Widget _buildProductGrid(
    List<Product> products,
    CartNotifier cartNotifier,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              onTap: () {
                cartNotifier.addProduct(product);
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} +1'),
                    duration: const Duration(milliseconds: 600),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCartSheet(BuildContext context, CartNotifier cartNotifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CartSheet(cartNotifier: cartNotifier),
    );
  }

  Future<void> _checkout(
    BuildContext context,
    CartNotifier cartNotifier,
  ) async {
    if (cartNotifier.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carrito vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Capture ScaffoldMessenger before any async gap
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Venta'),
        content: Text(
          'Total: ${CurrencyFormatter.format(cartNotifier.totalAmount)}\n'
          'Productos: ${cartNotifier.totalItems}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vender'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final datasource = ref.read(posDataSourceProvider);
      final items = cartNotifier.items;
      final total = cartNotifier.totalAmount;
      final itemCount = cartNotifier.totalItems;

      final transaction = Transaction(
        total: total,
        itemCount: itemCount,
        createdAt: DateTime.now(),
      );

      final transactionItems = items
          .map(
            (ci) => TransactionItem(
              productId: ci.product.id!,
              productName: ci.product.name,
              unitPrice: ci.product.price,
              quantity: ci.quantity,
              subtotal: ci.subtotal,
            ),
          )
          .toList();

      await datasource.insertTransactionWithItems(
        transaction,
        transactionItems,
      );
      cartNotifier.clear();
      ref.invalidate(productListProvider);

      if (context.mounted) {
        HapticFeedback.heavyImpact();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Venta registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error en checkout: $e');
      if (context.mounted) {
        final message = _getFriendlyErrorMessage(e);
        messenger.showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('database is locked') ||
        message.contains('database_is_locked')) {
      return 'La base de datos está ocupada. Intenta nuevamente.';
    }
    if (message.contains('constraint') || message.contains('unique')) {
      return 'No se pudo guardar la venta por una restricción de datos.';
    }
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }
}

// ─── Product Card ──────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(product.price),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cart Summary Bar ──────────────────────────────────────────

class _CartSummaryBar extends StatelessWidget {
  final int totalItems;
  final double totalAmount;
  final VoidCallback onCheckout;
  final VoidCallback onViewCart;

  const _CartSummaryBar({
    required this.totalItems,
    required this.totalAmount,
    required this.onCheckout,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onViewCart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalItems artículo(s)',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      CurrencyFormatter.format(totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onCheckout,
              icon: const Icon(Icons.payment),
              label: const Text('Cobrar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart Sheet (Bottom Sheet) ─────────────────────────────────

class _CartSheet extends ConsumerWidget {
  final CartNotifier cartNotifier;

  const _CartSheet({required this.cartNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Carrito de Ventas', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            if (cart.isEmpty)
              const Expanded(
                child: Center(child: Text('El carrito está vacío')),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: cartNotifier.items.length,
                  itemBuilder: (context, index) {
                    final item = cartNotifier.items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(item.product.name),
                      subtitle: Text(
                        '${CurrencyFormatter.format(item.product.price)} c/u',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.format(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'Eliminar producto',
                            onPressed: () {
                              cartNotifier.removeProduct(item.product);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
