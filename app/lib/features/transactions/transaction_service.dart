import 'dart:convert';

import '../../core/api_client.dart';
import '../../core/connectivity.dart';
import '../../core/offline_store.dart';
import '../categories/category_model.dart';
import 'transaction_model.dart';

class TransactionService {
  Future<List<Transaction>> listTransactions({String? month}) async {
    final path = month != null ? '/transactions?month=$month' : '/transactions';
    if (!ConnectivityService.instance.online.value) {
      return _fromCache(month);
    }
    try {
      final data = await ApiClient.instance.get(path);
      // El backend devuelve { transactions, total, page, limit }
      final list = (data as Map<String, dynamic>)['transactions'] as List;
      await OfflineStore.instance.saveTransactions(jsonEncode(list));
      return list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fromCache(month);
    }
  }

  Future<List<Transaction>> _fromCache(String? month) async {
    final raw = await OfflineStore.instance.loadTransactions();
    final list = <Transaction>[];
    if (raw != null) {
      list.addAll((jsonDecode(raw) as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>)));
    }
    // Añade los movimientos pendientes de sincronizar.
    final pending = await OfflineStore.instance.pendingTransactions();
    for (final p in pending) {
      list.insert(
        0,
        Transaction(
          id: 'pending-${list.length}',
          amount: double.parse(p['amount'].toString()),
          type: p['type'] as String,
          note: p['note'] as String?,
          date: DateTime.now(),
          category: null,
        ),
      );
    }
    if (month == null) return list;
    return list.where((t) {
      final ym = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      return ym == month;
    }).toList();
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

    // Sin conexión: se encola para sincronizar luego.
    if (!ConnectivityService.instance.online.value) {
      await OfflineStore.instance.addPendingTransaction(body);
      return _pendingTransaction(amount, type, note, categoryId);
    }

    try {
      final data = await ApiClient.instance.post('/transactions', body);
      return Transaction.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      // La red cayó justo al enviar: encolar como pendiente.
      await OfflineStore.instance.addPendingTransaction(body);
      return _pendingTransaction(amount, type, note, categoryId);
    }
  }

  Transaction _pendingTransaction(
      double amount, String type, String? note, String? categoryId) {
    return Transaction(
      id: 'pending-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: type,
      note: note,
      date: DateTime.now(),
      category: null,
    );
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
    if (!ConnectivityService.instance.online.value) {
      final raw = await OfflineStore.instance.loadCategories();
      if (raw != null) {
        return (jsonDecode(raw) as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
    try {
      final data = await ApiClient.instance.get('/categories') as List;
      await OfflineStore.instance.saveCategories(jsonEncode(data));
      return data
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final raw = await OfflineStore.instance.loadCategories();
      if (raw != null) {
        return (jsonDecode(raw) as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
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

  Future<void> deleteCategory(String id) async {
    await ApiClient.instance.delete('/categories/$id');
  }
}
