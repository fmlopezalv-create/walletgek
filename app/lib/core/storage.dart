import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'auth_token';
  static const _currencyKey = 'currency_code';
  static const _countryKey = 'country_code';
  static const _debtViewKey = 'debt_view_settings';
  static const _budgetViewKey = 'budget_view_settings';
  static const _homeViewKey = 'home_view_settings';
  static const _themeModeKey = 'theme_mode';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _hideAmountsKey = 'hide_amounts';
  static const _photoKey = 'profile_photo_path';
  static const _sectionOrderKey = 'home_section_order';
  static const _sectionHiddenKey = 'home_section_hidden';

  static Future<void> save(String token) =>
      _storage.write(key: _key, value: token);

  static Future<String?> read() => _storage.read(key: _key);

  static Future<void> saveCurrency(String code) =>
      _storage.write(key: _currencyKey, value: code);

  static Future<String?> readCurrency() => _storage.read(key: _currencyKey);

  static Future<void> saveCountry(String code) =>
      _storage.write(key: _countryKey, value: code);

  static Future<String?> readCountry() => _storage.read(key: _countryKey);

  static Future<void> saveDebtView(String json) =>
      _storage.write(key: _debtViewKey, value: json);

  static Future<String?> readDebtView() => _storage.read(key: _debtViewKey);

  static Future<void> saveBudgetView(String json) =>
      _storage.write(key: _budgetViewKey, value: json);

  static Future<String?> readBudgetView() => _storage.read(key: _budgetViewKey);

  static Future<void> saveHomeView(String json) =>
      _storage.write(key: _homeViewKey, value: json);

  static Future<String?> readHomeView() => _storage.read(key: _homeViewKey);

  static Future<void> saveThemeMode(String mode) =>
      _storage.write(key: _themeModeKey, value: mode);

  static Future<String?> readThemeMode() => _storage.read(key: _themeModeKey);

  static Future<void> saveName(String name) =>
      _storage.write(key: _nameKey, value: name);

  static Future<String?> readName() => _storage.read(key: _nameKey);

  static Future<void> saveEmail(String email) =>
      _storage.write(key: _emailKey, value: email);

  static Future<String?> readEmail() => _storage.read(key: _emailKey);

  static Future<void> saveHideAmounts(bool hide) =>
      _storage.write(key: _hideAmountsKey, value: hide ? '1' : '0');

  static Future<bool?> readHideAmounts() async {
    final v = await _storage.read(key: _hideAmountsKey);
    if (v == null) return null;
    return v == '1';
  }

  static Future<void> saveProfilePhoto(String path) =>
      _storage.write(key: _photoKey, value: path);

  static Future<String?> readProfilePhoto() => _storage.read(key: _photoKey);

  static Future<void> saveSectionOrder(String json) =>
      _storage.write(key: _sectionOrderKey, value: json);

  static Future<String?> readSectionOrder() =>
      _storage.read(key: _sectionOrderKey);

  static Future<void> saveSectionHidden(String json) =>
      _storage.write(key: _sectionHiddenKey, value: json);

  static Future<String?> readSectionHidden() =>
      _storage.read(key: _sectionHiddenKey);

  static Future<void> clear() => _storage.delete(key: _key);
}
