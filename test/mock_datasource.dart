import 'package:cajarapida/data/datasources/pos_database_datasource.dart';
import 'package:cajarapida/domain/models/product.dart';
import 'package:cajarapida/domain/models/transaction.dart';
import 'package:cajarapida/domain/models/daily_summary.dart';
import 'package:cajarapida/domain/models/received_report.dart';

/// Mock datasource that returns empty data without touching sqflite.
/// Use this in widget tests to avoid MissingPluginException from
/// path_provider and sqflite.
class MockPosDatabaseDatasource extends PosDatabaseDatasource {
  MockPosDatabaseDatasource() : super(null);
}
