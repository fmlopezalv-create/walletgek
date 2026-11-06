import '../../core/api_client.dart';
import '../categories/category_model.dart';
import 'transaction_model.dart';

class TransactionService {
  Future<List<Transaction>> listTransactions() async {
    final data = await ApiClient.instance.get('/transactions') as List;
    return data
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Transaction> createTransaction({
    required double amount,
    required String type,
    String? note,
    String? categoryId,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
    };
    if (note != null && note.isNotEmpty) {
      body['note'] = note;
    }
    final data = await ApiClient.instance.post('/transactions', body);
    return Transaction.fromJson(data as Map<String, dynamic>);
  }

  Future<Transaction> updateTransaction(
    String id, {
    required double amount,
    required String type,
    String? note,
    String? categoryId,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
    };
    if (note != null && note.isNotEmpty) {
      body['note'] = note;
    }
    final data = await ApiClient.instance.patch('/transactions/$id', body);
    return Transaction.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(String id) async {
    await ApiClient.instance.delete('/transactions/$id');
  }

  Future<List<Category>> listCategories() async {
    final data = await ApiClient.instance.get('/categories') as List;
    return data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> createCategory({
    required String name,
    required String type,
    double? monthlyBudget,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'type': type,
      'monthlyBudget': monthlyBudget,
    };
    final data = await ApiClient.instance.post('/categories', body);
    return Category.fromJson(data as Map<String, dynamic>);
  }

  Future<Category> updateCategory(String id, {double? monthlyBudget}) async {
    final data = await ApiClient.instance.patch('/categories/$id', {
      'monthlyBudget': monthlyBudget,
    });
    return Category.fromJson(data as Map<String, dynamic>);
  }
}
