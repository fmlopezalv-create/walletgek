import 'dart:convert';

import '../../core/api_client.dart';
import '../../core/connectivity.dart';
import '../../core/offline_store.dart';
import 'debt_model.dart';
import 'debt_plan_model.dart';

class DebtService {
  Future<List<Debt>> listDebts() async {
    if (!ConnectivityService.instance.online.value) {
      final raw = await OfflineStore.instance.loadDebts();
      if (raw != null) {
        return (jsonDecode(raw) as List)
            .map((e) => Debt.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
    try {
      final data = await ApiClient.instance.get('/debts') as List;
      await OfflineStore.instance.saveDebts(jsonEncode(data));
      return data
          .map((e) => Debt.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final raw = await OfflineStore.instance.loadDebts();
      if (raw != null) {
        return (jsonDecode(raw) as List)
            .map((e) => Debt.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }

  Future<Debt> createDebt({
    required String name,
    required String type,
    required double balance,
    required double interestRate,
    required double minimumPayment,
    String? color,
    String? institution,
    String? status,
    int? monthsLate,
    String? paymentType,
    int? totalInstallments,
    int? paidInstallments,
    Map<String, dynamic>? details,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'type': type,
      'balance': balance,
      'interestRate': interestRate,
      'minimumPayment': minimumPayment,
      'color': color,
      'institution': institution,
      'status': status,
      'monthsLate': monthsLate,
      'paymentType': paymentType,
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'details': (details != null && details.isNotEmpty) ? details : null,
    };
    final data = await ApiClient.instance.post('/debts', body);
    return Debt.fromJson(data as Map<String, dynamic>);
  }

  Future<Debt> payDebt(String id, double amount, {int cuotas = 1}) async {
    final data = await ApiClient.instance
        .post('/debts/$id/payments', {'amount': amount, 'cuotas': cuotas});
    return Debt.fromJson(data as Map<String, dynamic>);
  }

  Future<Debt> updateDebt(
    String id, {
    String? name,
    String? type,
    double? balance,
    double? interestRate,
    double? minimumPayment,
    String? color,
    String? institution,
    String? status,
    int? monthsLate,
    String? paymentType,
    int? totalInstallments,
    int? paidInstallments,
    Map<String, dynamic>? details,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (balance != null) body['balance'] = balance;
    if (interestRate != null) body['interestRate'] = interestRate;
    if (minimumPayment != null) body['minimumPayment'] = minimumPayment;
    if (color != null) body['color'] = color;
    if (institution != null) body['institution'] = institution;
    if (status != null) body['status'] = status;
    if (monthsLate != null) body['monthsLate'] = monthsLate;
    if (paymentType != null) body['paymentType'] = paymentType;
    if (totalInstallments != null) body['totalInstallments'] = totalInstallments;
    if (paidInstallments != null) body['paidInstallments'] = paidInstallments;
    if (details != null) body['details'] = details;
    final data = await ApiClient.instance.patch('/debts/$id', body);
    return Debt.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteDebt(String id) async {
    await ApiClient.instance.delete('/debts/$id');
  }

  Future<DebtPlan> getPlan({
    required String strategy,
    required double monthlyBudget,
  }) async {
    final data = await ApiClient.instance
        .get('/debts/plan?strategy=$strategy&monthlyBudget=$monthlyBudget');
    return DebtPlan.fromJson(data as Map<String, dynamic>);
  }
}
