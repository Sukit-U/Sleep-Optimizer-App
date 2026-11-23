import 'bedtime_option.dart';

class BedtimeFeasibilityResult {
  const BedtimeFeasibilityResult({
    required this.option,
    required this.isFeasible,
    required this.reason,
  });

  final BedtimeOption option;
  final bool isFeasible;
  final String reason;
}
