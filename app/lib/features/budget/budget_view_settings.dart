class BudgetViewSettings {
  bool showChart;
  String chartType;

  BudgetViewSettings({this.showChart = true, this.chartType = 'donut'});

  Map<String, dynamic> toJson() => {
        'showChart': showChart,
        'chartType': chartType,
      };

  factory BudgetViewSettings.fromJson(Map<String, dynamic> json) =>
      BudgetViewSettings(
        showChart: json['showChart'] ?? true,
        chartType: json['chartType'] ?? 'donut',
      );
}
