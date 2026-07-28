/// Lightweight value objects used by the Home screen to render
/// "Tonight's suggestion" and "Latest score" populated states.
///
/// These mirror the shape consumed by the Lovable home route, so when a real
/// data source is wired in we only need to map it onto these types.
library;

/// Summary of the most recent saved sleep plan.
class HomePlanSummary {
  final String wakeUpTime; // "07:00"
  final List<String> bedtimes; // ["9:30 PM", "11:00 PM", ...]

  const HomePlanSummary({required this.wakeUpTime, required this.bedtimes});
}

/// Summary of the most recent saved SQI record.
class HomeSqiSummary {
  final int totalScore;
  final String qualityLevel; // "Excellent" | "Good" | "Fair" | "Poor"
  final DateTime createdAt;

  const HomeSqiSummary({
    required this.totalScore,
    required this.qualityLevel,
    required this.createdAt,
  });
}