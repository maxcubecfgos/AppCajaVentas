class ReceivedReport {
  final int? id;
  final String reportDate;
  final double totalIncome;
  final int transactionCount;
  final String breakdownJson;
  final String receivedAt;

  ReceivedReport({
    this.id,
    required this.reportDate,
    required this.totalIncome,
    required this.transactionCount,
    required this.breakdownJson,
    required this.receivedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_date': reportDate,
      'total_income': totalIncome,
      'transaction_count': transactionCount,
      'breakdown_json': breakdownJson,
      'received_at': receivedAt,
    };
  }

  factory ReceivedReport.fromMap(Map<String, dynamic> map) {
    return ReceivedReport(
      id: map['id'] as int?,
      reportDate: map['report_date'] as String,
      totalIncome: (map['total_income'] as num).toDouble(),
      transactionCount: map['transaction_count'] as int,
      breakdownJson: map['breakdown_json'] as String,
      receivedAt: map['received_at'] as String,
    );
  }
}
