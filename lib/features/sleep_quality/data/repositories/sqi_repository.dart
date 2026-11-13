import '../../../../models/recommendation_model.dart';
import '../../../../models/sqi_record_model.dart';
import '../../../../services/firestore_service.dart';

abstract class SqiRepository {
  /// Allocates the record ID up front, so a retried submission reuses it
  /// instead of creating a second record.
  String newRecordId();

  /// Creates or overwrites the record with its already-allocated ID.
  Future<void> saveRecord(SQIRecord record);

  /// Writes an assessment's recommendations in one batch, by their own IDs.
  Future<void> saveRecommendations(List<Recommendation> recommendations);
}

class FirestoreSqiRepository implements SqiRepository {
  FirestoreSqiRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  @override
  String newRecordId() => _firestoreService.newSqiRecordId();

  @override
  Future<void> saveRecord(SQIRecord record) =>
      _firestoreService.saveSqiRecord(record);

  @override
  Future<void> saveRecommendations(List<Recommendation> recommendations) =>
      _firestoreService.saveRecommendations(recommendations);
}
