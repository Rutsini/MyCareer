class CareerProgressSummary {
  const CareerProgressSummary({
    required this.generalAverage,
    required this.electiveObtained,
    required this.electiveInProgress,
    required this.electiveRequired,
  });

  final double? generalAverage;
  final double electiveObtained;
  final double electiveInProgress;
  final double? electiveRequired;

  double? get electiveRemaining => electiveRequired == null
      ? null
      : (electiveRequired! - electiveObtained).clamp(0, double.infinity);

  double? get electiveProgress =>
      electiveRequired == null || electiveRequired! <= 0
          ? null
          : electiveObtained / electiveRequired!;
}
