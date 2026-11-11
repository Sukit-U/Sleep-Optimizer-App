import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../services/firestore_service.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/sqi_question_card.dart';
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

  static const _questions = [
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
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle(title: 'Sleep Quality Check-In'),
            const SizedBox(height: 8),
            ..._questions.map((question) => SQIQuestionCard(
              label: question.label,
              helper: question.helper,
              selectedValue: _responses[question.label],
              hasError: _unansweredTouched.contains(question.label),
              onSelected: (value) {
                setState(() {
                  _responses[question.label] = value;
                  _unansweredTouched.remove(question.label);
                });
              },
            )),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.assessment_rounded),
              label: const Text('Calculate SQI'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);

    final userId = await auth.ensureSignedIn();
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not sign in. Check your connection and try again.')),
      );
      return;
    }

    if (_responses.length != _questions.length) {
      final unanswered =
          _questions.where((q) => !_responses.containsKey(q.label)).toList();
      setState(() {
        _unansweredTouched.addAll(unanswered.map((q) => q.label));
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Please answer every SQI question before submitting.')),
      );
      return;
    }

    final result = const CalculateSqi().call(responses: _responses);
    final firestoreService = FirestoreService();

    try {
      final recordId = await _sqiRepository.saveRecord(
        {
          'userId': userId,
          'sqiScore': result.score,
          'sleepQualityLevel': result.level.name,
          'questionnaireResponses': _responses,
          'createdAt': DateTime.now(),
        },
      );

      final recommendations = const GenerateRecommendations().call(
        weakFactors: result.weakFactors,
        level: result.level.name,
        recordId: recordId,
        userId: userId,
      );
      for (final rec in recommendations) {
        await firestoreService.addRecommendation(rec);
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

    if (!mounted) return;

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
