class DebtPlanItem {
  final String name;
  final int? paidOffMonth;
  DebtPlanItem({required this.name, this.paidOffMonth});

  factory DebtPlanItem.fromJson(Map<String, dynamic> json) => DebtPlanItem(
        name: json['name'] as String,
        paidOffMonth: json['paidOffMonth'] as int?,
      );
}

class DebtPlan {
  final String strategy;
  final int monthsToPayoff;
  final double totalInterest;
  final List<DebtPlanItem> schedule;

  DebtPlan({
    required this.strategy,
    required this.monthsToPayoff,
    required this.totalInterest,
    required this.schedule,
  });

  factory DebtPlan.fromJson(Map<String, dynamic> json) => DebtPlan(
        strategy: json['strategy'] as String,
        monthsToPayoff: json['monthsToPayoff'] as int? ?? 0,
        totalInterest: double.parse(json['totalInterest'].toString()),
        schedule: (json['schedule'] as List)
            .map((e) => DebtPlanItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
