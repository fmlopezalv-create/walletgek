class DebtViewSettings {
  bool showChart;
  String chartType;
  bool showInterest;
  bool showInstallments;
  bool showStatus;
  bool showInstitution;

  DebtViewSettings({
    this.showChart = true,
    this.chartType = 'donut',
    this.showInterest = true,
    this.showInstallments = true,
    this.showStatus = true,
    this.showInstitution = false,
  });

  Map<String, dynamic> toJson() => {
        'showChart': showChart,
        'chartType': chartType,
        'showInterest': showInterest,
        'showInstallments': showInstallments,
        'showStatus': showStatus,
        'showInstitution': showInstitution,
      };

  factory DebtViewSettings.fromJson(Map<String, dynamic> json) =>
      DebtViewSettings(
        showChart: json['showChart'] ?? true,
        chartType: json['chartType'] ?? 'donut',
        showInterest: json['showInterest'] ?? true,
        showInstallments: json['showInstallments'] ?? true,
        showStatus: json['showStatus'] ?? true,
        showInstitution: json['showInstitution'] ?? false,
      );
}
