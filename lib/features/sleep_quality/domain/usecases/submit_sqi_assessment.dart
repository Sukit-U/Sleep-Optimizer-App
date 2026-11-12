import '../../../../models/recommendation_model.dart';
import '../../../../models/sqi_record_model.dart';
import '../../../recommendation/domain/usecases/generate_recommendations.dart';
import '../entities/sqi_result.dart';

/// Result of one submission attempt.
enum SubmitSqiOutcome {
  /// The record and every recommendation were confirmed written.
  saved,

  /// The record was confirmed written, but the recommendation batch was not.
  /// A retry sends only the recommendations.
  recordSavedRecommendationsNotConfirmed,

  /// Nothing was confirmed. The write may still have landed (for example when
  /// the reply to a successful commit was lost), so the caller must not tell
  /// the user that nothing was saved.
  unconfirmed,

  /// A submission was already running; this attempt did nothing.
  busy,
}

typedef WriteSqiRecord = Future<void> Function(SQIRecord record);
typedef WriteSqiRecommendations = Future<void> Function(
  List<Recommendation> recommendations,
);

/// Writes one SQI assessment in the two steps the Firestore rules allow.
///
/// The rules validate a recommendation's parent with `exists()`, so a batch
/// that creates the record and its recommendations together is rejected.
/// Instead the record is written first by an ID allocated once, and the
/// recommendations follow in their own batch with IDs derived from that record
/// ID.
///
/// Both steps are idempotent, which is what makes Retry safe: the record ID and
/// the recommendation IDs are reused, so a retry overwrites instead of
/// duplicating, and a retry after a confirmed record skips the record write.
class SubmitSqiAssessment {
  SubmitSqiAssessment({
    required this.newRecordId,
    required this.writeRecord,
    required this.writeRecommendations,
    this.generateRecommendations = const GenerateRecommendations(),
  });

  /// Allocates the record ID for a new attempt.
  final String Function() newRecordId;

  /// Creates or overwrites the record at its already-allocated ID.
  final WriteSqiRecord writeRecord;

  /// Writes the assessment's recommendations in one batch.
  final WriteSqiRecommendations writeRecommendations;

  /// Builds the recommendations for a result.
  final GenerateRecommendations generateRecommendations;

  String? _recordId;
  DateTime? _createdAt;
  bool _recordSaved = false;
  bool _inFlight = false;

  /// True while a submission is running, so the UI can refuse re-entry.
  bool get isSubmitting => _inFlight;

  /// The record document this attempt writes to, once allocated.
  String? get recordId => _recordId;

  /// Whether the record write has been confirmed.
  bool get recordSaved => _recordSaved;

  /// Forgets the current attempt, so the next submission creates a new record.
  /// Call this only after a submission was confirmed saved.
  void reset() {
    _recordId = null;
    _createdAt = null;
    _recordSaved = false;
  }

  /// Recommendation document IDs are derived from the record ID, so a retry
  /// targets the same documents instead of adding new ones.
  static String recommendationId(String recordId, int index) =>
      '$recordId-r$index';

  Future<SubmitSqiOutcome> call({
    required String userId,
    required SqiResult result,
  }) async {
    if (_inFlight) return SubmitSqiOutcome.busy;
    _inFlight = true;
    try {
      // Allocated once per attempt and reused by every retry: the same record
      // and the same createdAt keep the retried write an in-place update that
      // the rules accept.
      final recordId = _recordId ??= newRecordId();
      final createdAt = _createdAt ??= DateTime.now();

      if (!_recordSaved) {
        try {
          await writeRecord(
            SQIRecord(
              recordId: recordId,
              userId: userId,
              sqiScore: result.score,
              sleepQualityLevel: result.level.name,
              questionnaireResponses:
                  Map<String, dynamic>.from(result.responses),
              createdAt: createdAt,
            ),
          );
          _recordSaved = true;
        } catch (_) {
          // Unconfirmed: the write may have been applied even though it threw.
          return SubmitSqiOutcome.unconfirmed;
        }
      }

      final generated = generateRecommendations.call(
        weakFactors: result.weakFactors,
        level: result.level.name,
        recordId: recordId,
        userId: userId,
      );
      final recommendations = <Recommendation>[
        for (var i = 0; i < generated.length; i++)
          generated[i].copyWith(
            recommendationId: recommendationId(recordId, i),
          ),
      ];

      try {
        await writeRecommendations(recommendations);
      } catch (_) {
        return SubmitSqiOutcome.recordSavedRecommendationsNotConfirmed;
      }

      return SubmitSqiOutcome.saved;
    } finally {
      _inFlight = false;
    }
  }
}
