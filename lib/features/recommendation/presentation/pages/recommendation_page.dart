import 'package:flutter/material.dart';

import '../../domain/entities/recommendation.dart';
import '../../domain/usecases/generate_recommendations.dart';
import '../../../sleep_quality/domain/entities/sqi_result.dart';

class RecommendationPage extends StatelessWidget {
  const RecommendationPage({super.key, this.result});

  final SqiResult? result;

  @override
  Widget build(BuildContext context) {
    final recommendations = result == null
        ? <RecommendationEntity>[]
        : const GenerateRecommendations().call(weakFactors: result!.weakFactors);

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (result != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SQI Score: ${result!.score}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sleep Quality Level: ${result!.level.name.toUpperCase()}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Weak factors: ${result!.weakFactors.join(', ')}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (recommendations.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Complete your SQI to receive personalized recommendations.'),
                ),
              )
            else ...[
              Text(
                'Recommended actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...recommendations.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(item.description),
                        const SizedBox(height: 8),
                        Text(
                          'Action: ${item.action}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
