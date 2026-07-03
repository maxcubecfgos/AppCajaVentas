# Plan Arquitectónico — Micro-POS Offline-First

## 1. Esquema SQL Propuesto (sqflite)

```sql
-- Tabla: Products (Catálogo de productos)
CREATE TABLE products (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  price       REAL    NOT NULL CHECK(price >= 0),
  created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- Tabla: Transactions (Cabecera de venta)
CREATE TABLE transactions (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  total       REAL    NOT NULL CHECK(total >= 0),
  item_count  INTEGER NOT NULL CHECK(item_count > 0),
  created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- Tabla: Transaction_Items (Detalle de productos vendidos)
CREATE TABLE transaction_items (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id  INTEGER NOT NULL,
  product_id      INTEGER NOT NULL,
  product_name    TEXT    NOT NULL,  -- denormalizado para histórico
  unit_price      REAL    NOT NULL CHECK(unit_price >= 0),
  quantity        INTEGER NOT NULL CHECK(quantity > 0),
  subtotal        REAL    NOT NULL CHECK(subtotal >= 0),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id)     REFERENCES products(id)     ON DELETE RESTRICT
);

-- Índices para consultas de cuadre diario e histórico
CREATE INDEX idx_transactions_date ON transactions(created_at);
CREATE INDEX idx_transaction_items_transaction ON transaction_items(transaction_id);
CREATE INDEX idx_transaction_items_product ON transaction_items(product_id);
```

### Notas de diseño:
- `product_name` y `unit_price` se desnormalizan en `transaction_items` para preservar el histórico aunque el producto se modifique o elimine.
- `ON DELETE RESTRICT` en `product_id` evita borrar productos que ya tienen ventas.
- Fechas en ISO-8601 (TEXT) para compatibilidad y legibilidad directa.

---

## 2. Estructura de Directorios Propuesta

```
lib/
├── main.dart                          # Entry point con ProviderScope
├── app.dart                           # MaterialApp con routing y tema
│
├── core/
│   ├── database/
│   │   ├── app_database.dart          # Singleton de sqflite (open, migrate, close)
│   │   └── migrations.dart            # Scripts de migración versionados
│   ├── theme/
│   │   └── app_theme.dart             # Tema Material 3 (existente, extender)
│   └── utils/
│       ├── date_utils.dart            # Formateo de fechas
│       └── currency_formatter.dart    # Formateo monetario
│
├── data/
│   ├── datasources/
│   │   ├── local_storage_datasource.dart  # (existente, para Money Counter)
│   │   └── pos_database_datasource.dart   # NUEVO: operaciones sqflite POS
│   ├── models/
│   │   ├── product_model.dart         # Modelo DB → Map
│   │   ├── transaction_model.dart
│   │   └── transaction_item_model.dart
│   └── repositories/
│       ├── product_repository_impl.dart
│       ├── transaction_repository_impl.dart
│       └── denomination_repository_impl.dart  # (existente)
│
├── domain/
│   ├── models/
│   │   ├── product.dart               # Entidad pura
│   │   ├── transaction.dart
│   │   ├── transaction_item.dart
│   │   ├── daily_summary.dart         # Modelo de cuadre diario
│   │   ├── denomination.dart          # (existente)
│   │   ├── currency_type.dart         # (existente)
│   │   └── count_entry.dart           # (existente)
│   └── repositories/
│       ├── product_repository.dart    # Interfaz abstracta
│       └── transaction_repository.dart
│
├── presentation/
│   ├── screens/
│   │   ├── pos_screen.dart            # Pantalla principal de ventas
│   │   ├── catalog_screen.dart        # CRUD de productos
│   │   ├── daily_close_screen.dart    # Cuadre diario
│   │   ├── history_screen.dart        # Historial por fecha
│   │   ├── counting_screen.dart       # (existente) Money Counter
│   │   └── product_form_screen.dart   # Formulario crear/editar producto
│   ├── widgets/
│   │   ├── product_card.dart          # Tarjeta de producto en POS
│   │   ├── cart_summary_bar.dart      # Barra inferior del carrito
│   │   ├── daily_summary_card.dart    # Resumen en cuadre diario
│   │   ├── product_list_tile.dart     # Tile para CRUD
│   │   └── empty_state.dart           # Estado vacío genérico
│   └── theme/
│       └── app_theme.dart             # (existente)
│
└── providers/
    ├── product_providers.dart         # Riverpod providers para productos
    ├── transaction_providers.dart     # Providers para ventas y carrito
    ├── daily_summary_providers.dart   # Providers para cuadre diario
    ├── database_provider.dart         # Provider de la DB sqflite
    └── counting_providers.dart        # (existente) Money Counter
```

---

## 3. Entidades/Modelos de Datos en Dart

### Product (dominio)
```dart
class Product {
  final int? id;
  final String name;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    this.id,
    required this.name,
    required this.price,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Product copyWith({int? id, String? name, double? price}) => Product(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
```

### Transaction (dominio)
```dart
class Transaction {
  final int? id;
  final double total;
  final int itemCount;
  final DateTime createdAt;
  final List<TransactionItem> items;

  const Transaction({
    this.id,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    required this.items,
  });
}
```

### TransactionItem (dominio)
```dart
class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const TransactionItem({
    this.id,
    this.transactionId = 0,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });
}
```

### DailySummary (dominio — modelo de proyección)
```dart
class DailySummary {
  final DateTime date;
  final double totalIncome;
  final int transactionCount;
  final List<ProductBreakdown> breakdown;

  const DailySummary({
    required this.date,
    required this.totalIncome,
    required this.transactionCount,
    required this.breakdown,
  });
}

class ProductBreakdown {
  final int productId;
  final String productName;
  final int quantitySold;
  final double subtotal;

  const ProductBreakdown({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.subtotal,
  });
}
```

---

## 4. Arquitectura y Flujo de Datos

```
UI (Widgets)
    │  Lee/escribe mediante providers Riverpod
    ▼
Providers (Riverpod AsyncNotifier)
    │  Llama a repositorios (interfaces abstractas)
    ▼
Domain Repositories (Interfaces)
    │  Implementaciones en capa de datos
    ▼
Data Repositories (Implementaciones)
    │  Usan datasources
    ▼
Datasources (sqflite / SharedPreferences)
    │
    ▼
SQLite DB / SharedPrefs
```

### Principios:
- **Offline-first**: Toda la lógica opera localmente. Sin dependencia de red.
- **Clean Architecture**: Dominio no depende de Flutter ni de la DB.
- **Feature-First**: Cada funcionalidad (POS, Catálogo, Cuadre, Historial) tiene su propio conjunto de providers y screens.
- **Riverpod**: AsyncNotifier para operaciones DB asíncronas. Providers de estado para el carrito en tiempo real.

### Gestión de Estado del Carrito (POS):
- Un `AsyncNotifier` mantiene el carrito como `Map<int, int>` (productId → cantidad).
- Al registrar la venta, se inserta una transacción + items en una transacción SQL.
- El carrito se limpia post-venta con animación.
- SnackBar + HapticFeedback confirman cada adición.

---

## 5. Integración con el Módulo Existente (Money Counter)

- El Money Counter actual se conserva intacto en `lib/presentation/screens/counting_screen.dart`.
- Se accede desde un `Drawer` lateral o `BottomNavigationBar` como pestaña "Herramientas".
- Los providers existentes (`counting_providers.dart`) no se modifican.
- La pantalla de Cuadre Diario tendrá un FAB que abre el Money Counter para ayudar en el cierre manual.

---

## Resumen de Dependencias a Agregar en pubspec.yaml

```yaml
dependencies:
  sqflite: ^2.4.1
  path: ^1.9.0
  flutter_riverpod: ^2.6.1        # ya existe
  shared_preferences: ^2.3.4      # ya existe
  intl: ^0.19.0                   # formateo de fechas/moneda
```

---

¿Apruebas este plan arquitectónico para proceder con la generación de código?