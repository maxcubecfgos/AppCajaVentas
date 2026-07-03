class Denomination {
  final double value;
  final String label;
  final String symbol;

  const Denomination({
    required this.value,
    required this.label,
    this.symbol = '\$',
  });

  Denomination copyWith({double? value, String? label, String? symbol}) {
    return Denomination(
      value: value ?? this.value,
      label: label ?? this.label,
      symbol: symbol ?? this.symbol,
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'label': label,
    'symbol': symbol,
  };

  factory Denomination.fromJson(Map<String, dynamic> json) => Denomination(
    value: (json['value'] as num).toDouble(),
    label: json['label'] as String,
    symbol: json['symbol'] as String? ?? '\$',
  );

  @override
  String toString() => 'Denomination(value: $value, label: $label)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Denomination &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label;

  @override
  int get hashCode => value.hashCode ^ label.hashCode;
}
