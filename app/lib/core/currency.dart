class Currency {
  final String code;
  final String symbol;
  final String name;
  const Currency(this.code, this.symbol, this.name);
}

const List<Currency> currencies = [
  Currency('EUR', '€', 'Euro'),
  Currency('USD', '\$', 'Dólar estadounidense'),
  Currency('MXN', '\$', 'Peso mexicano'),
  Currency('COP', '\$', 'Peso colombiano'),
  Currency('ARS', '\$', 'Peso argentino'),
  Currency('CLP', '\$', 'Peso chileno'),
  Currency('PEN', 'S/', 'Sol peruano'),
  Currency('GBP', '£', 'Libra esterlina'),
  Currency('BRL', 'R\$', 'Real brasileño'),
];

String currencySymbol(String code) {
  for (final c in currencies) {
    if (c.code == code) return c.symbol;
  }
  return '\$';
}
