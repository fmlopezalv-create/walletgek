import '../../core/api_client.dart';
import '../../core/app_state.dart';
import '../../core/storage.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiClient.instance
        .post('/auth/login', {'email': email, 'password': password});
    await _apply(data as Map<String, dynamic>);
    return data;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String country,
    String currency,
  ) async {
    final data = await ApiClient.instance.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'country': country,
      'currency': currency,
    });
    await _apply(data as Map<String, dynamic>);
    return data;
  }

  Future<void> _apply(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    ApiClient.instance.token = token;
    await TokenStorage.save(token);
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      if (user['currency'] != null) {
        await AppState.instance.setCurrency(user['currency'] as String);
      }
      if (user['country'] != null) {
        await AppState.instance.setCountry(user['country'] as String);
      }
      if (user['name'] != null) {
        await AppState.instance.setUserName(user['name'] as String);
      }
      if (user['email'] != null) {
        await AppState.instance.setUserEmail(user['email'] as String);
      }
    }
  }

  Future<void> updateCurrency(String currency) async {
    await ApiClient.instance.patch('/users/me', {'currency': currency});
    await AppState.instance.setCurrency(currency);
  }

  Future<void> updateMonthlyBudget(double? monthlyBudget) async {
    await ApiClient.instance
        .patch('/users/me', {'monthlyBudget': monthlyBudget});
  }

  Future<void> logout() async {
    ApiClient.instance.token = null;
    await TokenStorage.clear();
  }
}
