import 'dart:convert';

import '../../core/api_client.dart';
import '../../core/connectivity.dart';
import '../../core/offline_store.dart';
import 'dashboard_model.dart';
import 'home_dashboard_model.dart';

class DashboardService {
  Future<HealthSummary> getHealth() async {
    final data = await ApiClient.instance.get('/dashboard/health');
    return HealthSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<HomeDashboard> getHome({String? month}) async {
    final path =
        month != null ? '/dashboard/home?month=$month' : '/dashboard/home';
    if (!ConnectivityService.instance.online.value) {
      final raw = await OfflineStore.instance.loadDashboard();
      if (raw != null) {
        return HomeDashboard.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      }
      throw Exception('Sin conexión y sin datos guardados');
    }
    try {
      final data = await ApiClient.instance.get(path) as Map<String, dynamic>;
      await OfflineStore.instance.saveDashboard(jsonEncode(data));
      return HomeDashboard.fromJson(data);
    } catch (_) {
      final raw = await OfflineStore.instance.loadDashboard();
      if (raw != null) {
        return HomeDashboard.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      }
      rethrow;
    }
  }
}
