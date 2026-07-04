import 'package:sqflite/sqflite.dart' hide Transaction;
import '../../core/database/app_database.dart';
import '../../domain/models/product.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/daily_summary.dart';

class PosDatabaseDatasource {
  final AppDatabase _appDatabase;

  PosDatabaseDatasource(this._appDatabase);

  Future<Database> get database => _appDatabase.database;

  // ─── Products ───────────────────────────────────────────────────

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Transactions ───────────────────────────────────────────────

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return db.insert('transactions', transaction.toMap());
  }

  Future<void> insertTransactionWithItems(
    Transaction transaction,
    List<TransactionItem> items,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      final transactionId = await txn.insert(
        'transactions',
        transaction.toMap(),
      );
      for (final item in items) {
        await txn.insert('transaction_items', {
          ...item.toMap(),
          'transaction_id': transactionId,
        });
      }
    });
  }

  Future<List<Transaction>> getTransactionsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'transactions',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<List<TransactionItem>> getItemsByTransactionId(
    int transactionId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return maps.map((m) => TransactionItem.fromMap(m)).toList();
  }

  // ─── Reports ────────────────────────────────────────────────────

  Future<DailySummary?> getDailySummary(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final summaryMaps = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as transaction_count,
        COALESCE(SUM(total), 0) as total_income
      FROM transactions
      WHERE created_at >= ? AND created_at < ?
    ''',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    if (summaryMaps.isEmpty ||
        (summaryMaps.first['transaction_count'] as int) == 0) {
      return null;
    }

    final summary = summaryMaps.first;
    final transactionCount = summary['transaction_count'] as int;
    final totalIncome = (summary['total_income'] as num).toDouble();

    final breakdownMaps = await db.rawQuery(
      '''
      SELECT
        ti.product_id,
        ti.product_name,
        SUM(ti.quantity) as quantity_sold,
        SUM(ti.subtotal) as subtotal
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.created_at >= ? AND t.created_at < ?
      GROUP BY ti.product_id, ti.product_name
      ORDER BY quantity_sold DESC
    ''',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    final breakdown = breakdownMaps
        .map(
          (m) => ProductBreakdown(
            productId: m['product_id'] as int,
            productName: m['product_name'] as String,
            quantitySold: (m['quantity_sold'] as num).toInt(),
            subtotal: (m['subtotal'] as num).toDouble(),
          ),
        )
        .toList();

    return DailySummary(
      date: startOfDay,
      totalIncome: totalIncome,
      transactionCount: transactionCount,
      breakdown: breakdown,
    );
  }
}
