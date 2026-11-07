import '../../core/api_client.dart';
import 'receivable_model.dart';

class ReceivableService {
  Future<List<Receivable>> listReceivables() async {
    final data = await ApiClient.instance.get('/receivables') as List;
    return data
        .map((e) => Receivable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Receivable> createReceivable({
    required String person,
    required double amount,
    String? note,
    DateTime? dueDate,
  }) async {
    final body = <String, dynamic>{
      'person': person,
      'amount': amount,
      'note': note,
      'dueDate': dueDate?.toIso8601String(),
    };
    final data = await ApiClient.instance.post('/receivables', body);
    return Receivable.fromJson(data as Map<String, dynamic>);
  }

  Future<Receivable> collectReceivable(String id, double amount) async {
    final data = await ApiClient.instance
        .post('/receivables/$id/collect', {'amount': amount});
    return Receivable.fromJson(data as Map<String, dynamic>);
  }

  Future<Receivable> updateReceivable(
    String id, {
    String? person,
    double? amount,
    String? note,
    DateTime? dueDate,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (person != null) body['person'] = person;
    if (amount != null) body['amount'] = amount;
    if (note != null) body['note'] = note;
    if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();
    if (status != null) body['status'] = status;
    final data = await ApiClient.instance.patch('/receivables/$id', body);
    return Receivable.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteReceivable(String id) async {
    await ApiClient.instance.delete('/receivables/$id');
  }
}
