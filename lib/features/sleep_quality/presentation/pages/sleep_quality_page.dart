import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../../../services/firestore_service.dart';
import '../../../../models/recommendation_model.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../data/repositories/sqi_repository.dart';
import '../../domain/usecases/calculate_sqi.dart';
import '../../../recommendation/domain/usecases/generate_recommendations.dart';
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
  final Set<String> _unansweredTouched = <String>{};

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _responses.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard answers?'),
            content: const Text('You have unanswered questions. Do you want to discard your answers?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Quality'),
        leading: const BackButton(),
      ),
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
      ),
    );
  }

  Widget _buildQuestionCard(_Question question) {
    final hasError = _unansweredTouched.contains(question.label);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasError
            ? BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5)
            : BorderSide.none,
      ),
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
                      _unansweredTouched.remove(question.label);
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
      final unanswered =
          _questions.where((q) => !_responses.containsKey(q.label)).toList();
      setState(() {
        _unansweredTouched.addAll(unanswered.map((q) => q.label));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer every SQI question before submitting.')),
      );
      return;
    }

    final result = const CalculateSqi().call(responses: _responses);
    final firestoreService = FirestoreService();

    try {
      // Save SQI record via repository (uses FirestoreService)
      final recordId = await _sqiRepository.saveRecord(
        {
          'userId': 'default_user',
          'sqiScore': result.score,
          'sleepQualityLevel': result.level.name,
          'questionnaireResponses': _responses,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Generate and persist recommendations (linked to SQI record)
      final recommendations = const GenerateRecommendations().call(
        weakFactors: result.weakFactors,
        level: result.level.name,
      );
      for (final rec in recommendations) {
        await firestoreService.addRecommendation(
          Recommendation(
            recommendationId: '',
            recordId: recordId,
            factor: rec.factor,
            title: rec.title,
            description: rec.description,
            action: rec.action,
            priority: rec.priority.name,
            createdAt: DateTime.now(),
          ),
        );
      }

      await appStorage?.saveHistoryEntry(
        'sqi_history',
        {
          'title': 'SQI Score',
          'subtitle': 'Score ${result.score} · Level ${result.level.name.toUpperCase()}',
          'dateLabel': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save results. Check your connection and try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _submit,
          ),
        ),
      );
      return;
    }

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

