import '../../core/api_client.dart';
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
    final data = await ApiClient.instance.get(path);
    return HomeDashboard.fromJson(data as Map<String, dynamic>);
  }
}
