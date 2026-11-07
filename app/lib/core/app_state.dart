import 'package:flutter/foundation.dart';

import 'currency.dart';
import 'storage.dart';

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  String currencyCode = 'EUR';
  String countryCode = 'ES';
  String themeMode = 'dark'; // 'system' | 'light' | 'dark' — oscuro como base
  String userName = '';
  String userEmail = '';
  bool hideAmounts = false;
  bool isPremium = false;
  String profilePhotoPath = '';
  final ValueNotifier<String> themeModeNotifier = ValueNotifier('dark');
  final ValueNotifier<bool> hideAmountsNotifier = ValueNotifier(false);
  final ValueNotifier<String> profilePhotoNotifier = ValueNotifier('');
  final ValueNotifier<bool> premiumNotifier = ValueNotifier(false);

  /// Señal global de "los datos cambiaron". Cada mutación exitosa
  /// (crear/editar/borrar/pagar/cobrar) debe llamar a [notifyDataChanged]
  /// para que todas las pantallas abiertas se recarguen en tiempo real.
  final ValueNotifier<int> dataVersionNotifier = ValueNotifier<int>(0);

  void notifyDataChanged() {
    dataVersionNotifier.value++;
  }

  String get symbol => currencySymbol(currencyCode);

  Future<void> load() async {
    final code = await TokenStorage.readCurrency();
    if (code != null) currencyCode = code;
    final country = await TokenStorage.readCountry();
    if (country != null) countryCode = country;
    final mode = await TokenStorage.readThemeMode();
    if (mode != null) themeMode = mode;
    themeModeNotifier.value = themeMode;
    final name = await TokenStorage.readName();
    if (name != null) userName = name;
    final email = await TokenStorage.readEmail();
    if (email != null) userEmail = email;
    final hide = await TokenStorage.readHideAmounts();
    if (hide != null) hideAmounts = hide;
    hideAmountsNotifier.value = hideAmounts;
    final photo = await TokenStorage.readProfilePhoto();
    if (photo != null) profilePhotoPath = photo;
    profilePhotoNotifier.value = profilePhotoPath;
  }

  Future<void> setCurrency(String code) async {
    currencyCode = code;
    await TokenStorage.saveCurrency(code);
  }

  Future<void> setCountry(String code) async {
    countryCode = code;
    await TokenStorage.saveCountry(code);
  }

  Future<void> setThemeMode(String mode) async {
    themeMode = mode;
    themeModeNotifier.value = mode;
    await TokenStorage.saveThemeMode(mode);
  }

  Future<void> setUserName(String name) async {
    userName = name;
    await TokenStorage.saveName(name);
  }

  Future<void> setUserEmail(String email) async {
    userEmail = email;
    await TokenStorage.saveEmail(email);
  }

  Future<void> setHideAmounts(bool hide) async {
    hideAmounts = hide;
    hideAmountsNotifier.value = hide;
    await TokenStorage.saveHideAmounts(hide);
  }

  Future<void> setProfilePhoto(String path) async {
    profilePhotoPath = path;
    profilePhotoNotifier.value = path;
    await TokenStorage.saveProfilePhoto(path);
  }

  void setPremium(bool value) {
    isPremium = value;
    premiumNotifier.value = value;
  }

  String formatAmount(double v) {
    final sign = v < 0 ? '-' : '';
    return '$sign$symbol${v.abs().toStringAsFixed(2)}';
  }
}
