class Transaction {
  final int? id;
  final double total;
  final int itemCount;
  final DateTime createdAt;
  final List<TransactionItem> items;

  Transaction({
    this.id,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'total': total,
    'item_count': itemCount,
    'created_at': createdAt.toIso8601String(),
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'] as int?,
    total: (map['total'] as num).toDouble(),
    itemCount: map['item_count'] as int,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  @override
  String toString() => 'Transaction(id: $id, total: $total, items: $itemCount)';
}

class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  TransactionItem({
    this.id,
    this.transactionId = 0,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'transaction_id': transactionId,
    'product_id': productId,
    'product_name': productName,
    'unit_price': unitPrice,
    'quantity': quantity,
    'subtotal': subtotal,
  };

  factory TransactionItem.fromMap(Map<String, dynamic> map) => TransactionItem(
    id: map['id'] as int?,
    transactionId: map['transaction_id'] as int,
    productId: map['product_id'] as int,
    productName: map['product_name'] as String,
    unitPrice: (map['unit_price'] as num).toDouble(),
    quantity: map['quantity'] as int,
    subtotal: (map['subtotal'] as num).toDouble(),
  );

  @override
  String toString() =>
      'TransactionItem(product: $productName, qty: $quantity, subtotal: $subtotal)';
}
