import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'connectivity.dart';
import 'offline_store.dart';

/// Coordina la cola de movimientos pendientes: cuando vuelve la conexión,
/// los envía al backend y refresca la cache.
class OfflineSync {
  OfflineSync._();
  static final OfflineSync instance = OfflineSync._();

  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  bool _syncing = false;

  Future<void> init() async {
    await _refreshPendingCount();
    ConnectivityService.instance.online.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (ConnectivityService.instance.online.value) {
      sync();
    }
  }

  Future<void> _refreshPendingCount() async {
    final list = await OfflineStore.instance.pendingTransactions();
    pendingCount.value = list.length;
  }

  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final pending = await OfflineStore.instance.pendingTransactions();
      if (pending.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];
      for (final payload in pending) {
        try {
          await ApiClient.instance.post('/transactions', payload);
        } catch (_) {
          remaining.add(payload);
        }
      }

      if (remaining.isEmpty) {
        await OfflineStore.instance.clearPendingTransactions();
      } else {
        // Vuelve a guardar solo los que fallaron.
        final sp = OfflineStore.instance;
        await sp.clearPendingTransactions();
        for (final p in remaining) {
          await sp.addPendingTransaction(p);
        }
      }
      await _refreshPendingCount();
    } finally {
      _syncing = false;
    }
  }

  /// Devuelve la lista de movimientos en cache (usada cuando no hay red).
  Future<List<Map<String, dynamic>>> cachedTransactions() async {
    final raw = await OfflineStore.instance.loadTransactions();
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> cachedDashboard() async {
    final raw = await OfflineStore.instance.loadDashboard();
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> cachedDebts() async {
    final raw = await OfflineStore.instance.loadDebts();
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> cachedCategories() async {
    final raw = await OfflineStore.instance.loadCategories();
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }
}
