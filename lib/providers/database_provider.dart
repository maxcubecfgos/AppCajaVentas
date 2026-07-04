import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../data/datasources/pos_database_datasource.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final posDataSourceProvider = Provider<PosDatabaseDatasource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PosDatabaseDatasource(db);
});
