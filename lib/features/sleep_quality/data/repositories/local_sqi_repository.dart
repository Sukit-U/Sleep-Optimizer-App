import 'dart:math';

import 'package:snoozemate/core/services/storage_service.dart';

import '../../domain/entities/local_sqi_assessment.dart';

abstract class LocalSqiRepository {
  String newAssessmentId();

  Future<void> save(LocalSqiAssessment assessment);

  List<LocalSqiAssessment> loadAll();

  Future<void> updateSyncStatus(
    String assessmentId,
    LocalSqiSyncStatus status, {
    String? userId,
    String? cloudRecordId,
    String? error,
    DateTime? attemptTime,
  });
}

class StorageLocalSqiRepository implements LocalSqiRepository {
  StorageLocalSqiRepository(this._storage);

  final StorageService? _storage;

  @override
  String newAssessmentId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 31);
    return 'sqi_${now}_$rand';
  }

  @override
  Future<void> save(LocalSqiAssessment assessment) async {
    final storage = _storage;
    if (storage == null) return;
    await storage.saveLocalSqiAssessment(assessment.toJson());
  }

  @override
  List<LocalSqiAssessment> loadAll() {
    final storage = _storage;
    if (storage == null) return <LocalSqiAssessment>[];
    final raw = storage.loadLocalSqiAssessments();
    final result = <LocalSqiAssessment>[];
    for (final m in raw) {
      final parsed = LocalSqiAssessment.tryParse(m);
      if (parsed != null) result.add(parsed);
    }
    return result;
  }

  @override
  Future<void> updateSyncStatus(
    String assessmentId,
    LocalSqiSyncStatus status, {
    String? userId,
    String? cloudRecordId,
    String? error,
    DateTime? attemptTime,
  }) async {
    final storage = _storage;
    if (storage == null) return;
    final all = loadAll();
    final idx = all.indexWhere((a) => a.assessmentId == assessmentId);
    if (idx < 0) return;
    final updated = all[idx].copyWith(
      syncStatus: status,
      userId: userId,
      cloudRecordId: cloudRecordId,
      lastSyncAttempt: attemptTime ?? DateTime.now(),
      lastSyncError: error,
      clearLastSyncError: error == null,
    );
    await storage.saveLocalSqiAssessment(updated.toJson());
  }
}
