class HealthSummary {
  final String month;
  final double income;
  final double expense;
  final double? savingsRate;
  final double monthlyDebt;
  final double? dti;

  HealthSummary({
    required this.month,
    required this.income,
    required this.expense,
    this.savingsRate,
    required this.monthlyDebt,
    this.dti,
  });

  factory HealthSummary.fromJson(Map<String, dynamic> json) => HealthSummary(
        month: json['month'] as String,
        income: double.parse(json['income'].toString()),
        expense: double.parse(json['expense'].toString()),
        savingsRate: json['savingsRate'] != null
            ? double.parse(json['savingsRate'].toString())
            : null,
        monthlyDebt: double.parse(json['monthlyDebt'].toString()),
        dti: json['dti'] != null
            ? double.parse(json['dti'].toString())
            : null,
      );
}
