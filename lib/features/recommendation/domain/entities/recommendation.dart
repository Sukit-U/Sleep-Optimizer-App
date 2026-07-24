enum RecommendationPriority { critical, high, medium, low }

class RecommendationEntity {
  const RecommendationEntity({
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
    required this.factor,
  });

  final String title;
  final String description;
  final String action;
  final RecommendationPriority priority;
  final String factor;
}
