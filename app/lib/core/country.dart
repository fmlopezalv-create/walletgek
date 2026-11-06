class Country {
  final String code;
  final String name;
  final String flag;
  final String currency;
  const Country(this.code, this.name, this.flag, this.currency);
}

const List<Country> countries = [
  Country('ES', 'España', '🇪🇸', 'EUR'),
  Country('MX', 'México', '🇲🇽', 'MXN'),
  Country('CO', 'Colombia', '🇨🇴', 'COP'),
  Country('AR', 'Argentina', '🇦🇷', 'ARS'),
  Country('PE', 'Perú', '🇵🇪', 'PEN'),
  Country('CL', 'Chile', '🇨🇱', 'CLP'),
  Country('EC', 'Ecuador', '🇪🇨', 'USD'),
  Country('US', 'Estados Unidos', '🇺🇸', 'USD'),
  Country('XX', 'Otro', '🌎', 'USD'),
];

Country countryByCode(String code) {
  return countries.firstWhere((c) => c.code == code,
      orElse: () => countries.last);
}

String currencyForCountry(String code) => countryByCode(code).currency;
