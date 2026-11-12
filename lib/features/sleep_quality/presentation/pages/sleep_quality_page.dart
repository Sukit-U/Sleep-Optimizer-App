import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/sqi_question_card.dart';
import '../../data/repositories/sqi_repository.dart';
import '../../domain/usecases/calculate_sqi.dart';
import '../../domain/usecases/submit_sqi_assessment.dart';
import '../../../recommendation/presentation/pages/recommendation_page.dart';

class SleepQualityPage extends StatefulWidget {
  const SleepQualityPage({super.key, this.repository, this.ensureSignedIn});

  /// Injectable for tests; production uses [FirestoreSqiRepository].
  final SqiRepository? repository;

  /// Injectable for tests; production signs in through [AuthService].
  final Future<String?> Function()? ensureSignedIn;

  @override
  State<SleepQualityPage> createState() => _SleepQualityPageState();
}

class _SleepQualityPageState extends State<SleepQualityPage> {
  late final SqiRepository _sqiRepository =
      widget.repository ?? FirestoreSqiRepository();

  /// Owns the record ID and createdAt of the assessment currently being
  /// written, so Retry reuses them instead of creating a second record.
  late final _submitAssessment = SubmitSqiAssessment(
    newRecordId: _sqiRepository.newRecordId,
    writeRecord: _sqiRepository.saveRecord,
    writeRecommendations: _sqiRepository.saveRecommendations,
  );

  bool _isSubmitting = false;

  /// Production path reads the signed-in user from [AuthService]; tests inject
  /// [SleepQualityPage.ensureSignedIn] instead. Called before the first await,
  /// so reading the context here is safe.
  Future<String?> _ensureSignedIn() {
    final injected = widget.ensureSignedIn;
    if (injected != null) return injected();
    return context.read<AuthService>().ensureSignedIn();
  }

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
              onPressed: _isSubmitting ? null : _submit,
              icon: const Icon(Icons.assessment_rounded),
              label: Text(_isSubmitting ? 'Saving…' : 'Calculate SQI'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _submit() async {
    // In-flight guard, taken before the first await. Setting the flag after
    // signing in left a window where the button stayed enabled, and a duplicate
    // tap from that window then cleared the flag while the first submission was
    // still writing — re-enabling the button mid-save.
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final userId = await _ensureSignedIn();
      if (userId == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not sign in. Check your connection and try again.')),
        );
        return;
      }

      if (_responses.length != _questions.length) {
        final unanswered =
            _questions.where((q) => !_responses.containsKey(q.label)).toList();
        if (!mounted) return;
        setState(() {
          _unansweredTouched.addAll(unanswered.map((q) => q.label));
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Please answer every SQI question before submitting.')),
        );
        return;
      }

      final result = const CalculateSqi().call(responses: _responses);
      final outcome = await _submitAssessment(userId: userId, result: result);
      if (!mounted) return;

      switch (outcome) {
        case SubmitSqiOutcome.busy:
          // Another submission is running; this tap was a duplicate.
          return;

        case SubmitSqiOutcome.saved:
          // The attempt is complete: a later submission is a new assessment and
          // must get its own record.
          _submitAssessment.reset();
          await appStorage?.saveHistoryEntry(
            'sqi_history',
            {
              'title': 'SQI Score',
              'subtitle':
                  'Score ${result.score} · Level ${result.level.name.toUpperCase()}',
              'dateLabel': DateTime.now().toIso8601String(),
            },
          );
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecommendationPage(result: result),
            ),
          );
          return;

        case SubmitSqiOutcome.recordSavedRecommendationsNotConfirmed:
          // The record is in Firestore; only the recommendations are missing.
          // Retry re-sends them with the same IDs, so nothing is duplicated.
          messenger.showSnackBar(
            SnackBar(
              content: const Text(
                'Your assessment was saved, but its recommendations could not be confirmed. Retry to finish it.',
              ),
              action: SnackBarAction(label: 'Retry', onPressed: _submit),
            ),
          );
          return;

        case SubmitSqiOutcome.unconfirmed:
          // Never claim the assessment was not saved: a write whose reply was
          // lost may still have been applied.
          messenger.showSnackBar(
            SnackBar(
              content: const Text(
                'Could not confirm the save. Check History before retrying — the assessment may already be there.',
              ),
              action: SnackBarAction(label: 'Retry', onPressed: _submit),
            ),
          );
          return;
      }
    } finally {
      // Only the call that took the lock reaches here, so only it releases it,
      // and never after the widget is gone.
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _Question {
  const _Question({required this.label, required this.helper});
  final String label;
  final String helper;
}
