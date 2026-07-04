import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/product.dart';
import 'database_provider.dart';

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final datasource = ref.watch(posDataSourceProvider);
  return datasource.getAllProducts();
});

final productByIdProvider = FutureProvider.family<Product?, int>((
  ref,
  id,
) async {
  final datasource = ref.watch(posDataSourceProvider);
  return datasource.getProductById(id);
});
