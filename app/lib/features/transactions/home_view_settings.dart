class HomeViewSettings {
  bool showChart;
  String chartType;

  HomeViewSettings({this.showChart = true, this.chartType = 'donut'});

  Map<String, dynamic> toJson() => {
        'showChart': showChart,
        'chartType': chartType,
      };

  factory HomeViewSettings.fromJson(Map<String, dynamic> json) =>
      HomeViewSettings(
        showChart: json['showChart'] ?? true,
        chartType: json['chartType'] ?? 'donut',
      );
}
