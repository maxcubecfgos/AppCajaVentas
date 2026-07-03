import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/denomination_repository_impl.dart';
import '../domain/repositories/denomination_repository.dart';
import 'datasource_provider.dart';

final denominationRepositoryProvider = Provider<DenominationRepository>((ref) {
  final datasource = ref.watch(localStorageDatasourceProvider);
  return DenominationRepositoryImpl(datasource);
});
