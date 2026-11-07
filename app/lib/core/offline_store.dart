import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Almacén local para el modo offline: cachea los datos del usuario como JSON
/// y guarda la cola de movimientos pendientes de sincronizar.
class OfflineStore {
  OfflineStore._();
  static final OfflineStore instance = OfflineStore._();

  static const _kTransactions = 'offline_transactions';
  static const _kDebts = 'offline_debts';
  static const _kCategories = 'offline_categories';
  static const _kDashboard = 'offline_dashboard';
  static const _kPending = 'offline_pending_tx';

  Future<void> saveTransactions(String json) =>
      _set(_kTransactions, json);

  Future<String?> loadTransactions() => _get(_kTransactions);

  Future<void> saveDebts(String json) => _set(_kDebts, json);

  Future<String?> loadDebts() => _get(_kDebts);

  Future<void> saveCategories(String json) => _set(_kCategories, json);

  Future<String?> loadCategories() => _get(_kCategories);

  Future<void> saveDashboard(String json) => _set(_kDashboard, json);

  Future<String?> loadDashboard() => _get(_kDashboard);

  /// Cola de movimientos creados sin conexión.
  Future<void> addPendingTransaction(Map<String, dynamic> payload) async {
    final list = await _pendingList();
    list.add(payload);
    await _set(_kPending, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> _pendingList() async {
    final raw = await _get(_kPending);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> pendingTransactions() => _pendingList();

  Future<void> clearPendingTransactions() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kPending);
  }

  Future<void> _set(String key, String value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, value);
  }

  Future<String?> _get(String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(key);
  }
}
