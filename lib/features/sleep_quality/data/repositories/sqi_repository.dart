import '../../../../services/firestore_service.dart';
import '../../../../models/sqi_record_model.dart';

abstract class SqiRepository {
  Future<String> saveRecord(Map<String, dynamic> payload);
}

class FirestoreSqiRepository implements SqiRepository {
  FirestoreSqiRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  @override
  Future<String> saveRecord(Map<String, dynamic> payload) async {
    final docId = await _firestoreService.addSQIRecord(SQIRecord(
      recordId: '',
      userId: payload['userId'] as String,
      sqiScore: payload['sqiScore'] as int,
      sleepQualityLevel: payload['sleepQualityLevel'] as String,
      questionnaireResponses:
          Map<String, dynamic>.from(payload['questionnaireResponses'] as Map),
      createdAt: payload['createdAt'] as DateTime,
    ));
    return docId;
  }
}
