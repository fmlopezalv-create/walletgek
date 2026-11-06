import '../../core/api_client.dart';
import 'budget_model.dart';

class BudgetService {
  Future<BudgetSummary> getSummary({String? month}) async {
    final path =
        month != null ? '/budget/summary?month=$month' : '/budget/summary';
    final data = await ApiClient.instance.get(path);
    return BudgetSummary.fromJson(data as Map<String, dynamic>);
  }
}
