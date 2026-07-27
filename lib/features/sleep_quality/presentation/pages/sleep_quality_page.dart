import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../data/repositories/sqi_repository.dart';
import '../../domain/usecases/calculate_sqi.dart';
import '../../../recommendation/presentation/pages/recommendation_page.dart';

class SleepQualityPage extends StatefulWidget {
  const SleepQualityPage({super.key});

  @override
  State<SleepQualityPage> createState() => _SleepQualityPageState();
}

class _SleepQualityPageState extends State<SleepQualityPage> {
  final _sqiRepository = FirestoreSqiRepository();
  final List<_Question> _questions = const [
    _Question(label: 'Sleep duration', helper: 'How many hours did you sleep?'),
    _Question(label: 'Sleep regularity', helper: 'How consistent was your bedtime?'),
    _Question(label: 'Screen time', helper: 'How much screen time before bed?'),
    _Question(label: 'Exercise', helper: 'How active were you during the day?'),
    _Question(label: 'Stress', helper: 'How stressed did you feel before bed?'),
    _Question(label: 'Caffeine', helper: 'How much caffeine did you consume?'),
  ];

  final Map<String, int> _responses = <String, int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Quality')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle(title: 'Sleep Quality Check-In'),
          const SizedBox(height: 8),
          ..._questions.map((question) => _buildQuestionCard(question)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.assessment_rounded),
            label: const Text('Calculate SQI'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(_Question question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(question.helper, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(5, (index) {
                final value = index + 1;
                final selected = _responses[question.label] == value;
                return ChoiceChip(
                  label: Text('$value'),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _responses[question.label] = value;
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_responses.length != _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer every SQI question before submitting.')),
      );
      return;
    }

    final result = const CalculateSqi().call(responses: _responses);

    await _sqiRepository.saveRecord(
      {
        'userId': 'local-user',
        'sqiScore': result.score,
        'sleepQualityLevel': result.level.name,
        'questionnaireResponses': _responses,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );

    await appStorage?.saveHistoryEntry(
      'sqi_history',
      {
        'title': 'SQI Score',
        'subtitle': 'Score ${result.score} · Level ${result.level.name.toUpperCase()}',
        'dateLabel': DateTime.now().toIso8601String(),
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecommendationPage(result: result),
      ),
    );
  }
}

class _Question {
  const _Question({required this.label, required this.helper});

  final String label;
  final String helper;
}

