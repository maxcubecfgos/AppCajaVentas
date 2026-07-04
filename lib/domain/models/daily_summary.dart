class DailySummary {
  final DateTime date;
  final double totalIncome;
  final int transactionCount;
  final List<ProductBreakdown> breakdown;

  DailySummary({
    required this.date,
    required this.totalIncome,
    required this.transactionCount,
    this.breakdown = const [],
  });
}

class ProductBreakdown {
  final int productId;
  final String productName;
  final int quantitySold;
  final double subtotal;

  ProductBreakdown({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.subtotal,
  });
}
