import 'package:intl/intl.dart';

/// Formateador centralizado de montos monetarios.
///
/// Usa [NumberFormat.currency] de `intl` para dar formato consistente
/// a todos los precios y totales de la aplicación.
///
/// Símbolo: $ (dólar/peso)
/// Separador de miles: coma (,)
/// Decimales: 2 dígitos
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _format = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  /// Formatea un [amount] numérico como moneda.
  ///
  /// Ejemplo: `1234.5` → `"$1,234.50"`
  static String format(double amount) => _format.format(amount);
}
