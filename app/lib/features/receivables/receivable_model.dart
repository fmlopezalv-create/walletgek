class Receivable {
  final String id;
  final String person;
  final double amount;
  final String? note;
  final DateTime? dueDate;
  final String status; // pending | collected

  Receivable({
    required this.id,
    required this.person,
    required this.amount,
    this.note,
    this.dueDate,
    this.status = 'pending',
  });

  factory Receivable.fromJson(Map<String, dynamic> json) => Receivable(
        id: json['id'] as String,
        person: json['person'] as String,
        amount: double.parse(json['amount'].toString()),
        note: json['note'] as String?,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'] as String)
            : null,
        status: json['status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'person': person,
        'amount': amount,
        'note': note,
        'dueDate': dueDate?.toIso8601String(),
        'status': status,
      };
}
