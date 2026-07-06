import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/backup_helper.dart';
import '../../domain/models/product.dart';
import '../../providers/product_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/theme_provider.dart';

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
    final productsAsync = ref.watch(productListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Respaldo',
            onPressed: () => _showBackupOptions(context),
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
                hintText: 'Buscar producto...',
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
              data: (products) => _buildProductList(products, theme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products, ThemeData theme) {
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
                  ? 'No hay productos'
                  : 'Sin resultados para "$_searchQuery"',
              style: theme.textTheme.titleMedium,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Intenta con otro nombre', style: theme.textTheme.bodySmall),
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

  // Cierra el teclado y espera a que la animación de cierre termine
  // antes de continuar. Esto evita el ANR (congelamiento) que ocurre
  // en algunos dispositivos Android (ej. Motorola) cuando se hace
  // Navigator.pop() con un TextFormField todavía enfocado y el
  // teclado abierto.
  Future<void> _closeKeyboardSafely() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 150));
  }

  Future<void> _showProductForm(
    BuildContext context, {
    Product? product,
  }) async {
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
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final price = double.tryParse(v);
                  if (price == null || price < 0) return 'Precio inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Cerrar teclado ANTES de cerrar el diálogo
              await _closeKeyboardSafely();
              if (ctx.mounted) Navigator.pop(ctx, false);
            },
            child: const Text('Cancelar'),
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
                    const SnackBar(
                      content: Text('Precio inválido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              // Cerrar teclado ANTES de tocar la base de datos o cerrar
              // el diálogo. Esto evita el ANR observado en dispositivos
              // como Motorola cuando el campo de texto sigue enfocado.
              await _closeKeyboardSafely();

              // Validar nombre duplicado (case-insensitive, sin espacios extra)
              final existing = await datasource.getProductByName(name);
              if (existing != null &&
                  (isEditing ? existing.id != editingProduct!.id : true)) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ya existe un producto con el nombre "$name"',
                      ),
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
                // Cerrar el diálogo ANTES de invalidar para evitar
                // reconstrucción del widget mientras el diálogo está abierto
                if (ctx.mounted) Navigator.pop(ctx, true);
                ref.invalidate(productListProvider);
              } catch (e) {
                debugPrint('Error al guardar producto: $e');
                // Si hay error, cerrar el diálogo igual y mostrar el error
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getFriendlySaveError(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );

    nameController.dispose();
    priceController.dispose();
  }

  String _getFriendlySaveError(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('database is locked') ||
        message.contains('database_is_locked')) {
      return 'La base de datos está ocupada. Intenta nuevamente.';
    }
    if (message.contains('constraint') || message.contains('unique')) {
      return 'No se pudo guardar por una restricción de datos.';
    }
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  Future<void> _showBackupOptions(BuildContext context) async {
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
              title: const Text('Exportar respaldo'),
              subtitle: const Text('Compartir archivo .db'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await BackupHelper.exportDatabase();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al exportar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Restaurar respaldo'),
              subtitle: const Text('Seleccionar archivo .db'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await BackupHelper.restoreDatabase();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Respaldo restaurado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al restaurar: $e'),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
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
            content: Text('${product.name} eliminado'),
            action: SnackBarAction(
              label: 'Deshacer',
              textColor: const Color(0xFF4CAF50),
              onPressed: () async {
                // Reinsertar el producto con los mismos datos
                final restoredProduct = Product(
                  name: product.name,
                  price: product.price,
                );
                await datasource.insertProduct(restoredProduct);
                ref.invalidate(productListProvider);
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('${product.name} restaurado'),
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
