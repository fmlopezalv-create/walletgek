import '../../core/api_client.dart';
import '../../core/app_state.dart';

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String currency;
  final String country;
  final double? monthlyBudget;
  final bool isPremium;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.currency,
    required this.country,
    this.monthlyBudget,
    this.isPremium = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        currency: json['currency'] as String? ?? 'EUR',
        country: json['country'] as String? ?? 'ES',
        monthlyBudget: json['monthlyBudget'] != null
            ? double.parse(json['monthlyBudget'].toString())
            : null,
        isPremium: json['isPremium'] == true,
      );
}

class ProfileService {
  Future<UserProfile> getProfile() async {
    final data = await ApiClient.instance.get('/users/me');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    String? name,
    String? currency,
    String? country,
    double? monthlyBudget,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (currency != null) body['currency'] = currency;
    if (country != null) body['country'] = country;
    if (monthlyBudget != null) body['monthlyBudget'] = monthlyBudget;
    final data = await ApiClient.instance.patch('/users/me', body);
    return _apply(data as Map<String, dynamic>);
  }

  Future<UserProfile> activatePremium() async {
    final data = await ApiClient.instance.post('/users/me/premium', {});
    return _apply(data as Map<String, dynamic>);
  }

  UserProfile _apply(Map<String, dynamic> data) {
    final profile = UserProfile.fromJson(data);
    AppState.instance.setCurrency(profile.currency);
    AppState.instance.setCountry(profile.country);
    AppState.instance.setUserName(profile.name);
    AppState.instance.setUserEmail(profile.email);
    AppState.instance.setPremium(profile.isPremium);
    return profile;
  }
}
