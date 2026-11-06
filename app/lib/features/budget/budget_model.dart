class BudgetCategory {
  final String id;
  final String name;
  final double budget;
  final double spent;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.budget,
    required this.spent,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        budget: double.parse(json['budget'].toString()),
        spent: double.parse(json['spent'].toString()),
      );
}

class BudgetSummary {
  final String month;
  final double totalBudget;
  final double totalSpent;
  final double? globalBudget;
  final List<BudgetCategory> categories;

  BudgetSummary({
    required this.month,
    required this.totalBudget,
    required this.totalSpent,
    this.globalBudget,
    required this.categories,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) => BudgetSummary(
        month: json['month'] as String,
        totalBudget: double.parse(json['totalBudget'].toString()),
        totalSpent: double.parse(json['totalSpent'].toString()),
        globalBudget: json['globalBudget'] != null
            ? double.parse(json['globalBudget'].toString())
            : null,
        categories: (json['categories'] as List)
            .map((e) => BudgetCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
