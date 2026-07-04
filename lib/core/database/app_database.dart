import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;
  static Completer<Database>? _initCompleter;

  AppDatabase._internal();

  factory AppDatabase() => _instance;

  Future<Database> get database async {
    // Si ya está abierta, devolverla directamente
    if (_database != null) return _database!;

    // Si ya hay una apertura en curso, esperar a que termine
    // en lugar de disparar otra llamada a openDatabase()
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<Database>();

    try {
      final db = await _initDatabase();
      _database = db;
      _initCompleter!.complete(db);
      return db;
    } catch (e, st) {
      _initCompleter!.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'pos_database.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL CHECK(price >= 0),
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total REAL NOT NULL CHECK(total >= 0),
        item_count INTEGER NOT NULL CHECK(item_count > 0),
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL CHECK(unit_price >= 0),
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        subtotal REAL NOT NULL CHECK(subtotal >= 0),
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_items_transaction ON transaction_items(transaction_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_items_product ON transaction_items(product_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Índice único case-insensitive y sin espacios extra para evitar
      // duplicados de nombre de producto a nivel de base de datos.
      await db.execute('''
        CREATE UNIQUE INDEX idx_products_name_unique
        ON products (LOWER(TRIM(name)))
      ''');
    }
    if (oldVersion < 3) {
      // Tabla para almacenar cuadres diarios recibidos vía QR
      await db.execute('''
        CREATE TABLE received_reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          report_date TEXT NOT NULL,
          total_income REAL NOT NULL,
          transaction_count INTEGER NOT NULL,
          breakdown_json TEXT NOT NULL,
          received_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _initCompleter = null;
  }
}
