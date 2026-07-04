import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../providers/product_providers.dart';
import '../../providers/database_provider.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context),
        child: const Icon(Icons.add),
      ),
      body: productsAsync.when(
        data: (products) => products.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay productos',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Presiona + para agregar',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
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
                      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _showProductForm(context, product: product),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _confirmDelete(context, product),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
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
                // Si hay error, cerrar el diálogo igual y mostrar el error
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al guardar: $e'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${product.name} eliminado')));
      }
    }
  }
}
