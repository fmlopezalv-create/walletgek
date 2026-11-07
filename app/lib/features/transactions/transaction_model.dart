import '../categories/category_model.dart';

class Transaction {
  final String id;
  final double amount;
  final String type; // income | expense
  final String? note;
  final DateTime date;
  final Category? category;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    this.note,
    required this.date,
    this.category,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        amount: double.parse(json['amount'].toString()),
        type: json['type'] as String,
        note: json['note'] as String?,
        date: DateTime.parse(json['date'] as String).toLocal(),
        category: json['category'] != null
            ? Category.fromJson(json['category'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'note': note,
        'date': date.toIso8601String(),
        'category': category?.toJson(),
      };
}
