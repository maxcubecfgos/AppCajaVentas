import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/backup_helper.dart';
import '../../domain/models/product.dart';
import '../../providers/product_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/theme_provider.dart';
import '../widgets/language_toggle.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final productsAsync = ref.watch(productListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.catalogTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: strings.backup,
            onPressed: () => _showBackupOptions(context),
          ),
          const LanguageToggle(),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: strings.switchTheme,
            onPressed: () {
              final current = Theme.of(context).brightness;
              final newMode = current == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).setMode(newMode);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: strings.searchProduct,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) => _buildProductList(products, theme, strings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${strings.error}: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(
    List<Product> products,
    ThemeData theme,
    AppStrings strings,
  ) {
    final filtered = _searchQuery.isEmpty
        ? products
        : products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? strings.noProducts
                  : strings.noResults(_searchQuery),
              style: theme.textTheme.titleMedium,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(strings.tryAnother, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                product.name[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(product.name),
            subtitle: Text(CurrencyFormatter.format(product.price)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showProductForm(context, product: product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, product),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _closeKeyboardSafely() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 150));
  }

  Future<void> _showProductForm(
    BuildContext context, {
    Product? product,
  }) async {
    final strings = AppStrings.of(context);
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product != null ? product.price.toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();
    final isEditing = product != null;
    final editingProduct = product;

    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? strings.editProduct : strings.newProduct),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: strings.productName,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? strings.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: strings.price,
                  border: const OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return strings.required;
                  final price = double.tryParse(v);
                  if (price == null || price < 0) return strings.invalidPrice;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _closeKeyboardSafely();
              if (ctx.mounted) Navigator.pop(ctx, false);
            },
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final currentState = formKey.currentState;
              if (currentState == null || !currentState.validate()) return;

              final datasource = ref.read(posDataSourceProvider);
              final name = nameController.text.trim();
              final priceText = priceController.text.trim();
              final price = double.tryParse(priceText);
              if (price == null || price < 0) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(strings.invalidPrice),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              await _closeKeyboardSafely();

              final existing = await datasource.getProductByName(name);
              if (existing != null &&
                  (isEditing ? existing.id != editingProduct!.id : true)) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(strings.duplicateName(name)),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              try {
                if (isEditing) {
                  await datasource.updateProduct(
                    editingProduct!.copyWith(name: name, price: price),
                  );
                } else {
                  await datasource.insertProduct(
                    Product(name: name, price: price),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
                ref.invalidate(productListProvider);
              } catch (e) {
                debugPrint('Error al guardar producto: $e');
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getFriendlySaveError(e, strings)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? strings.save : strings.create),
          ),
        ],
      ),
    );

    nameController.dispose();
    priceController.dispose();
  }

  String _getFriendlySaveError(dynamic error, AppStrings strings) {
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

  Future<void> _showBackupOptions(BuildContext context) async {
    final strings = AppStrings.of(context);
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(strings.exportBackup),
              subtitle: Text(strings.exportSub),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await BackupHelper.exportDatabase();
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
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(strings.restoreBackup),
              subtitle: Text(strings.restoreSub),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await BackupHelper.restoreDatabase();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.restoreSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
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
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final strings = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.deleteProduct),
        content: Text(strings.confirmDelete(product.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirm == true && product.id != null) {
      final datasource = ref.read(posDataSourceProvider);
      await datasource.deleteProduct(product.id!);
      ref.invalidate(productListProvider);
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(strings.deleted(product.name)),
            action: SnackBarAction(
              label: strings.undo,
              textColor: const Color(0xFF4CAF50),
              onPressed: () async {
                final restoredProduct = Product(
                  name: product.name,
                  price: product.price,
                );
                await datasource.insertProduct(restoredProduct);
                ref.invalidate(productListProvider);
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(strings.restored(product.name)),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
