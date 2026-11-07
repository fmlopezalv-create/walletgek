import '../../core/api_client.dart';

class EmergencyFund {
  final int months;
  final double saved;
  final double essentialMonthly;
  final double goal;
  final double progress; // 0..1

  EmergencyFund({
    required this.months,
    required this.saved,
    required this.essentialMonthly,
    required this.goal,
    required this.progress,
  });

  factory EmergencyFund.fromJson(Map<String, dynamic> json) => EmergencyFund(
        months: (json['months'] as num?)?.toInt() ?? 3,
        saved: double.parse(json['saved'].toString()),
        essentialMonthly: double.parse(json['essentialMonthly'].toString()),
        goal: double.parse(json['goal'].toString()),
        progress: double.parse(json['progress'].toString()),
      );
}

class EmergencyFundService {
  Future<EmergencyFund> getEmergencyFund() async {
    final data = await ApiClient.instance.get('/users/me/emergency-fund');
    return EmergencyFund.fromJson(data as Map<String, dynamic>);
  }

  Future<EmergencyFund> updateEmergencyFund({
    int? months,
    double? saved,
  }) async {
    final body = <String, dynamic>{};
    if (months != null) body['months'] = months;
    if (saved != null) body['saved'] = saved;
    final data = await ApiClient.instance.patch('/users/me/emergency-fund', body);
    return EmergencyFund.fromJson(data as Map<String, dynamic>);
  }
}
