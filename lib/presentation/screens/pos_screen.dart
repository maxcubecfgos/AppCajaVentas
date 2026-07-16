import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snack_bar_helper.dart';
import '../../domain/models/product.dart';
import '../../domain/models/transaction.dart';
import '../../providers/product_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/daily_summary_providers.dart';
import '../widgets/app_drawer.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  /// Margen extra para que los SnackBars no tapen el botón "Cobrar"
  /// del `_CartSummaryBar`. Coincide con la altura aproximada del bar
  /// (padding vertical + Row con FilledButton.icon).
  static const double _cartBarClearance = 90;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final productsAsync = ref.watch(productListProvider);
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.salesTitle),
        centerTitle: true,
        actions: [
          if (cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Badge(
                label: Text('${cartNotifier.totalItems}'),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  tooltip: strings.cartTitle,
                  onPressed: () => _showCartSheet(context, cartNotifier),
                ),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: productsAsync.when(
              data: (products) => products.isEmpty
                  ? _emptyState(theme, strings)
                  : _buildProductGrid(products, cartNotifier, theme, strings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${strings.error}: $e')),
            ),
          ),
          if (cart.isNotEmpty)
            _CartSummaryBar(
              totalItems: cartNotifier.totalItems,
              totalAmount: cartNotifier.totalAmount,
              onCheckout: () => _checkout(context, cartNotifier),
              onViewCart: () => _showCartSheet(context, cartNotifier),
              strings: strings,
            ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme, AppStrings strings) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(height: 16),
        Text(strings.noProducts, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(strings.addFromCatalog, style: theme.textTheme.bodySmall),
      ],
    ),
  );

  Widget _buildProductGrid(
    List<Product> products,
    CartNotifier cartNotifier,
    ThemeData theme,
    AppStrings strings,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              onTap: () {
                cartNotifier.addProduct(product);
                HapticFeedback.lightImpact();
                SnackBarHelper.showBrief(
                  context,
                  strings.itemAdded(product.name),
                  extraMargin: _cartBarClearance,
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCartSheet(BuildContext context, CartNotifier cartNotifier) {
    final strings = AppStrings.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _CartSheet(cartNotifier: cartNotifier, strings: strings),
    );
  }

  Future<void> _checkout(
    BuildContext context,
    CartNotifier cartNotifier,
  ) async {
    final strings = AppStrings.of(context);
    if (cartNotifier.items.isEmpty) {
      SnackBarHelper.showWarning(context, strings.cartEmpty);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.confirmSale),
        content: Text(
          '${strings.totalLabel}: ${CurrencyFormatter.format(cartNotifier.totalAmount)}\n'
          '${strings.productsLabel}: ${cartNotifier.totalItems}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.sell),
          ),
        ],
      ),
    );    if (confirm != true) return;

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
      final today = ref.read(selectedDateProvider);
      ref.invalidate(dailySummaryProvider(today));

      if (context.mounted) {
        HapticFeedback.heavyImpact();
        SnackBarHelper.show(
          context,
          strings.saleSuccess,
          extraMargin: _cartBarClearance,
        );
      }
    } catch (e) {
      debugPrint('Error en checkout: $e');
      if (context.mounted) {
        final message = _getFriendlyErrorMessage(e, strings);
        SnackBarHelper.showError(
          context,
          message,
          extraMargin: _cartBarClearance,
        );
      }
    }
  }

  String _getFriendlyErrorMessage(dynamic error, AppStrings strings) {
    final message = error.toString().toLowerCase();
    if (message.contains('database is locked') ||
        message.contains('database_is_locked')) {
      return strings.dbLocked;
    }
    if (message.contains('constraint') || message.contains('unique')) {
      return strings.constraintError;
    }
    return strings.errorOccurred;
  }
}

// Product Card
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

// Cart Summary Bar
class _CartSummaryBar extends StatelessWidget {
  final int totalItems;
  final double totalAmount;
  final VoidCallback onCheckout;
  final VoidCallback onViewCart;
  final AppStrings strings;

  const _CartSummaryBar({
    required this.totalItems,
    required this.totalAmount,
    required this.onCheckout,
    required this.onViewCart,
    required this.strings,
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
                      strings.items(totalItems),
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
              label: Text(strings.checkout),
            ),
          ],
        ),
      ),
    );
  }
}

// Cart Sheet
class _CartSheet extends ConsumerWidget {
  final CartNotifier cartNotifier;
  final AppStrings strings;

  const _CartSheet({required this.cartNotifier, required this.strings});

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
            Text(strings.cartTitle, style: theme.textTheme.titleMedium),
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
                        '${CurrencyFormatter.format(item.product.price)} ${strings.perUnit}',
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
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            tooltip: strings.removeProduct,
                            onPressed: () =>
                                cartNotifier.removeProduct(item.product),
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
