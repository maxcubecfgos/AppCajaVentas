import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/local_storage_datasource.dart';

final localStorageDatasourceProvider = Provider<LocalStorageDatasource>((ref) {
  return LocalStorageDatasource();
});
