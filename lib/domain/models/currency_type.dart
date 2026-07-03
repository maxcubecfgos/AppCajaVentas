enum CurrencyType {
  usd(name: 'USD', symbol: '\$', locale: 'en_US'),
  eur(name: 'EUR', symbol: '€', locale: 'de_DE'),
  mxn(name: 'MXN', symbol: 'MX\$', locale: 'es_MX'),
  cop(name: 'COP', symbol: 'COL\$', locale: 'es_CO'),
  ars(name: 'ARS', symbol: 'AR\$', locale: 'es_AR'),
  gbp(name: 'GBP', symbol: '£', locale: 'en_GB');

  final String name;
  final String symbol;
  final String locale;

  const CurrencyType({
    required this.name,
    required this.symbol,
    required this.locale,
  });
}
