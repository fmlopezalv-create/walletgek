class Debt {
  final String id;
  final String name;
  final String type;
  final String? color;
  final double balance;
  final double interestRate;
  final double minimumPayment;
  final DateTime? dueDate;
  final String? institution;
  final String status;
  final int monthsLate;
  final String? paymentType;
  final int? totalInstallments;
  final int paidInstallments;
  final Map<String, dynamic>? details;

  Debt({
    required this.id,
    required this.name,
    required this.type,
    this.color,
    required this.balance,
    required this.interestRate,
    required this.minimumPayment,
    this.dueDate,
    this.institution,
    this.status = 'up_to_date',
    this.monthsLate = 0,
    this.paymentType,
    this.totalInstallments,
    this.paidInstallments = 0,
    this.details,
  });

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String? ?? 'other',
        color: json['color'] as String?,
        balance: double.parse(json['balance'].toString()),
        interestRate: double.parse(json['interestRate'].toString()),
        minimumPayment: double.parse(json['minimumPayment'].toString()),
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'] as String)
            : null,
        institution: json['institution'] as String?,
        status: json['status'] as String? ?? 'up_to_date',
        monthsLate: (json['monthsLate'] as num?)?.toInt() ?? 0,
        paymentType: json['paymentType'] as String?,
        totalInstallments: (json['totalInstallments'] as num?)?.toInt(),
        paidInstallments: (json['paidInstallments'] as num?)?.toInt() ?? 0,
        details: json['details'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
        'balance': balance,
        'interestRate': interestRate,
        'minimumPayment': minimumPayment,
        'dueDate': dueDate?.toIso8601String(),
        'institution': institution,
        'status': status,
        'monthsLate': monthsLate,
        'paymentType': paymentType,
        'totalInstallments': totalInstallments,
        'paidInstallments': paidInstallments,
        'details': details,
      };
}
