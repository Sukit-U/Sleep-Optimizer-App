import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/sqi_question_card.dart';
import '../../../recommendation/presentation/pages/recommendation_page.dart';
import '../../data/repositories/local_sqi_repository.dart';
import '../../data/repositories/sqi_repository.dart';
import '../../domain/entities/local_sqi_assessment.dart';
import '../../domain/entities/sqi_result.dart';
import '../../domain/usecases/calculate_sqi.dart';
import '../../domain/usecases/submit_sqi_assessment.dart';

class SleepQualityPage extends StatefulWidget {
  const SleepQualityPage({
    super.key,
    this.repository,
    this.localSqiRepository,
    this.ensureSignedIn,
  });

  /// Injectable for tests; production uses [FirestoreSqiRepository].
  final SqiRepository? repository;

  /// Injectable for tests; production uses a storage-backed repository.
  final LocalSqiRepository? localSqiRepository;

  /// Injectable for tests; production signs in through [AuthService].
  final Future<String?> Function()? ensureSignedIn;

  @override
  State<SleepQualityPage> createState() => _SleepQualityPageState();
}

class _SleepQualityPageState extends State<SleepQualityPage> {
  late final SqiRepository _sqiRepository =
      widget.repository ?? FirestoreSqiRepository();

  late final LocalSqiRepository _localSqiRepository =
      widget.localSqiRepository ?? StorageLocalSqiRepository(appStorage);

  /// Owns the record ID and createdAt of the assessment currently being
  /// written, so Retry reuses them instead of creating a second record.
  late final _submitAssessment = SubmitSqiAssessment(
    newRecordId: _sqiRepository.newRecordId,
    writeRecord: _sqiRepository.saveRecord,
    writeRecommendations: _sqiRepository.saveRecommendations,
  );

  bool _isSubmitting = false;

  /// The most recently calculated result. Kept so a cloud-save failure (or an
  /// offline assessment) never discards the user's score.
  SqiResult? _lastResult;

  /// The durable local record backing the current submission attempt, if any.
  /// Retained across retries and restored after a restart so the original
  /// assessment identity (and its calculated result) is reused instead of a
  /// new record being created.
  LocalSqiAssessment? _currentAssessment;

  /// Production path reads the signed-in user from [AuthService]; tests inject
  /// [SleepQualityPage.ensureSignedIn] instead. Called before the first await,
  /// so reading the context here is safe.
  Future<String?> _ensureSignedIn() {
    final injected = widget.ensureSignedIn;
    if (injected != null) return injected();
    return context.read<AuthService>().ensureSignedIn();
  }

  @override
  void initState() {
    super.initState();
    _restoreLastAssessment();
  }

  Future<void> _restoreLastAssessment() async {
    try {
      final all = _localSqiRepository.loadAll();
      if (all.isEmpty) return;
      final latest = all.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
      );
      if (!mounted) return;
      setState(() {
        _lastResult = _reconstructResult(latest);
        _currentAssessment = latest;
        // Restore the original answers so a failed/synced assessment can be
        // retried without re-entering them.
        _responses
          ..clear()
          ..addAll(latest.responses);
      });
    } catch (_) {
      // Ignore malformed storage; local result simply unavailable.
    }
  }

  SqiResult _reconstructResult(LocalSqiAssessment a) {
    final level = SleepQualityLevel.values.firstWhere(
      (l) => l.name == a.level,
      orElse: () => SleepQualityLevel.fair,
    );
    return SqiResult(
      score: a.score,
      level: level,
      weakFactors: List<String>.from(a.weakFactors),
      factorScores: Map<String, int>.from(a.factorScores),
      responses: Map<String, int>.from(a.responses),
    );
  }

  static const _questions = [
    _Question(label: 'Sleep duration', helper: 'How many hours did you sleep?'),
    _Question(
      label: 'Sleep regularity',
      helper: 'How consistent was your bedtime?',
    ),
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
            content: const Text(
              'You have unanswered questions. Do you want to discard your answers?',
            ),
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
              ..._questions.map(
                (question) => SQIQuestionCard(
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
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.assessment_rounded),
                label: Text(_isSubmitting ? 'Saving…' : 'Calculate SQI'),
              ),

              // A calculated result is kept even when the cloud save fails or
              // the device is offline, so it stays reachable for review/retry.
              if (_lastResult != null && !_isSubmitting) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    final result = _lastResult!;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecommendationPage(result: result),
                      ),
                    );
                  },
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('View last result'),
                ),
              ],
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

    // Validate locally first: answering the questionnaire needs no connection,
    // so a partially answered assessment never reaches the network.
    if (_responses.length != _questions.length) {
      final unanswered = _questions
          .where((q) => !_responses.containsKey(q.label))
          .toList();
      setState(() {
        _unansweredTouched.addAll(unanswered.map((q) => q.label));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer every SQI question before submitting.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      // Local calculation: always available, online or offline.
      final result = const CalculateSqi().call(responses: _responses);
      setState(() => _lastResult = result);

      // Reuse an existing assessment when the answers match, so a retry (in the
      // same session or after a restart) keeps the original identity instead of
      // creating a duplicate local/cloud record.
      final reuse =
          _currentAssessment != null &&
          _mapsEqual(_currentAssessment!.responses, _responses);

      LocalSqiAssessment assessment;
      String assessmentId;
      if (reuse) {
        assessment = _currentAssessment!;
        assessmentId = assessment.assessmentId;
      } else {
        // Durable local save FIRST (Local Save First, Cloud Sync Second).
        // The assessment must exist on device before any cloud attempt.
        assessmentId = _localSqiRepository.newAssessmentId();
        assessment = LocalSqiAssessment(
          assessmentId: assessmentId,
          createdAt: DateTime.now(),
          responses: Map<String, int>.from(result.responses),
          score: result.score,
          level: result.level.name,
          factorScores: Map<String, int>.from(result.factorScores),
          weakFactors: List<String>.from(result.weakFactors),
          syncStatus: LocalSqiSyncStatus.pending,
        );
        try {
          await _localSqiRepository.save(assessment);
        } catch (e) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          messenger.showSnackBar(
            SnackBar(content: Text('Could not save assessment locally: $e')),
          );
          return;
        }
        _currentAssessment = assessment;
        // A genuinely new assessment must not reuse a cached cloud record id
        // left over from a previous (possibly failed) attempt.
        _submitAssessment.reset();
      }

      final userId = await _ensureSignedIn();

      // Persist the (possibly resolved) userId into the local record.
      if (userId != null && assessment.userId != userId) {
        assessment = assessment.copyWith(userId: userId);
        await _localSqiRepository.save(assessment);
        _currentAssessment = assessment;
      }

      // Offline / not signed in: the score is still calculated and durably
      // saved locally. Keep it and let the user retry the cloud save or view
      // the full result locally.
      if (userId == null) {
        if (!mounted) return;
        // Release the guard so "Retry save" can re-enter _submit.
        setState(() => _isSubmitting = false);
        await _promptOfflineResult(result);
        return;
      }

      // Already synced: nothing to write, avoid a duplicate cloud record.
      if (reuse && assessment.syncStatus == LocalSqiSyncStatus.synced) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RecommendationPage(result: result)),
        );
        return;
      }

      final outcome = await _submitAssessment(
        userId: userId,
        result: result,
        recordId: assessment.assessmentId,
        createdAt: assessment.createdAt,
      );
      if (!mounted) return;

      switch (outcome) {
        case SubmitSqiOutcome.busy:
          // Another submission is running; this tap was a duplicate.
          return;

        case SubmitSqiOutcome.saved:
          // The attempt is complete: a later submission is a new assessment
          // and must get its own record.
          final cloudRecordId = _submitAssessment.recordId;
          _submitAssessment.reset();
          await _localSqiRepository.updateSyncStatus(
            assessmentId,
            LocalSqiSyncStatus.synced,
            userId: userId,
            cloudRecordId: cloudRecordId,
            attemptTime: DateTime.now(),
          );
          _currentAssessment = assessment.copyWith(
            syncStatus: LocalSqiSyncStatus.synced,
            userId: userId,
            cloudRecordId: cloudRecordId,
          );
          await appStorage?.saveHistoryEntry('sqi_history', {
            'title': 'SQI Score',
            'subtitle':
                'Score ${result.score} · Level ${result.level.name.toUpperCase()}',
            'dateLabel': DateTime.now().toIso8601String(),
          });
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
          await _localSqiRepository.updateSyncStatus(
            assessmentId,
            LocalSqiSyncStatus.failed,
            userId: userId,
            cloudRecordId: _submitAssessment.recordId,
            error: 'recommendations not confirmed',
            attemptTime: DateTime.now(),
          );
          _currentAssessment = assessment.copyWith(
            syncStatus: LocalSqiSyncStatus.failed,
            userId: userId,
            cloudRecordId: _submitAssessment.recordId,
            lastSyncError: 'recommendations not confirmed',
          );
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
          await _localSqiRepository.updateSyncStatus(
            assessmentId,
            LocalSqiSyncStatus.failed,
            userId: userId,
            error: 'unconfirmed',
            attemptTime: DateTime.now(),
          );
          _currentAssessment = assessment.copyWith(
            syncStatus: LocalSqiSyncStatus.failed,
            userId: userId,
            lastSyncError: 'unconfirmed',
          );
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

  bool _mapsEqual(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  /// (offline, or not signed in). Keeps the result and offers a cloud-save retry
  /// or a local view of the score.
  Future<void> _promptOfflineResult(SqiResult result) async {
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calculated offline'),
        content: Text(
          'Your SQI is ${result.score} (${result.level.name}).\n\n'
          'It was not saved to the cloud because there is no connection. '
          'You can retry saving or view your result now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('View result'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Retry save'),
          ),
        ],
      ),
    );

    if (choice == true) {
      // Retry the cloud save; while still offline this shows the dialog again.
      await _submit();
      return;
    }
    if (choice == false && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RecommendationPage(result: result)),
      );
      return;
    }
    if (choice == null && mounted) {
      // Dismissed without choosing: keep the result recoverable from a snackbar.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'SQI ${result.score} calculated — not saved to the cloud.',
          ),
          action: SnackBarAction(label: 'Retry', onPressed: _submit),
        ),
      );
    }
  }
}

class _Question {
  const _Question({required this.label, required this.helper});
  final String label;
  final String helper;
}
