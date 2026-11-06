class UpcomingPayment {
  final String id;
  final String name;
  final String? color;
  final String type;
  final DateTime? dueDate;
  final double minimumPayment;

  UpcomingPayment({
    required this.id,
    required this.name,
    this.color,
    required this.type,
    this.dueDate,
    required this.minimumPayment,
  });

  factory UpcomingPayment.fromJson(Map<String, dynamic> json) =>
      UpcomingPayment(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as String?,
        type: json['type'] as String? ?? 'other',
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'] as String)
            : null,
        minimumPayment: double.parse(json['minimumPayment'].toString()),
      );
}

class TopCategory {
  final String id;
  final String name;
  final double spent;
  final double budget;

  TopCategory({
    required this.id,
    required this.name,
    required this.spent,
    required this.budget,
  });

  factory TopCategory.fromJson(Map<String, dynamic> json) => TopCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        spent: double.parse(json['spent'].toString()),
        budget: double.parse(json['budget'].toString()),
      );
}

class HomeDashboard {
  final String month;
  final double balance;
  final double? variation;
  final double income;
  final double expense;
  final List<UpcomingPayment> upcomingPayments;
  final double debtTotal;
  final double debtMonthly;
  final int debtCount;
  final List<TopCategory> topCategories;

  HomeDashboard({
    required this.month,
    required this.balance,
    this.variation,
    required this.income,
    required this.expense,
    required this.upcomingPayments,
    required this.debtTotal,
    required this.debtMonthly,
    required this.debtCount,
    required this.topCategories,
  });

  factory HomeDashboard.fromJson(Map<String, dynamic> json) => HomeDashboard(
        month: json['month'] as String,
        balance: double.parse(json['balance'].toString()),
        variation: json['variation'] != null
            ? double.parse(json['variation'].toString())
            : null,
        income: double.parse(json['income'].toString()),
        expense: double.parse(json['expense'].toString()),
        upcomingPayments: (json['upcomingPayments'] as List)
            .map((e) => UpcomingPayment.fromJson(e as Map<String, dynamic>))
            .toList(),
        debtTotal: double.parse(json['debtTotal'].toString()),
        debtMonthly: double.parse(json['debtMonthly'].toString()),
        debtCount: (json['debtCount'] as num?)?.toInt() ?? 0,
        topCategories: (json['topCategories'] as List)
            .map((e) => TopCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
