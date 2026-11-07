import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Estado global de conectividad. Expone [online] para que la UI reaccione.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final ValueNotifier<bool> online = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> init() async {
    try {
      final results = await Connectivity().checkConnectivity();
      online.value = _isOnline(results);
    } catch (_) {
      online.value = true;
    }
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      online.value = _isOnline(results);
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}
