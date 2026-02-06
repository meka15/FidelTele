class AppSettings {
  AppSettings({
    required this.ethioEnabled,
    required this.safaricomEnabled,
    required this.alertsEnabled,
    required this.lowBalanceThresholdPct,
    required this.expiryWarningHours,
    this.showInGb = true,
  });

  final bool ethioEnabled;
  final bool safaricomEnabled;
  final bool alertsEnabled;
  final double lowBalanceThresholdPct;
  final int expiryWarningHours;
  final bool showInGb;

  AppSettings copyWith({
    bool? ethioEnabled,
    bool? safaricomEnabled,
    bool? alertsEnabled,
    double? lowBalanceThresholdPct,
    int? expiryWarningHours,
    bool? showInGb,
  }) {
    return AppSettings(
      ethioEnabled: ethioEnabled ?? this.ethioEnabled,
      safaricomEnabled: safaricomEnabled ?? this.safaricomEnabled,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      lowBalanceThresholdPct:
          lowBalanceThresholdPct ?? this.lowBalanceThresholdPct,
      expiryWarningHours: expiryWarningHours ?? this.expiryWarningHours,
      showInGb: showInGb ?? this.showInGb,
    );
  }
}
