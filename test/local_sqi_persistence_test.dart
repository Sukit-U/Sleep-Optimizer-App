import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/core/services/storage_service.dart';
import 'package:snoozemate/features/sleep_quality/data/repositories/local_sqi_repository.dart';
import 'package:snoozemate/features/sleep_quality/data/repositories/sqi_repository.dart';
import 'package:snoozemate/models/recommendation_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';
import 'package:snoozemate/features/sleep_quality/domain/entities/local_sqi_assessment.dart';
import 'package:snoozemate/features/sleep_quality/domain/entities/sqi_result.dart';
import 'package:snoozemate/features/sleep_quality/presentation/pages/sleep_quality_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local SQI persistence (storage backend)', () {
    late StorageService storage;
    late StorageLocalSqiRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      storage = await StorageService.create();
      repo = StorageLocalSqiRepository(storage);
    });

    LocalSqiAssessment makeAssessment({
      String? id,
      LocalSqiSyncStatus status = LocalSqiSyncStatus.pending,
    }) {
      return LocalSqiAssessment(
        assessmentId: id ?? repo.newAssessmentId(),
        createdAt: DateTime(2026, 1, 1, 12, 0, 0),
        responses: const <String, int>{
          'Sleep duration': 3,
          'Sleep regularity': 4,
          'Screen time': 2,
          'Exercise': 5,
          'Stress': 3,
          'Caffeine': 1,
        },
        score: 60,
        level: 'good',
        factorScores: const <String, int>{
          'Sleep duration': 12,
          'Sleep regularity': 16,
          'Screen time': 6,
          'Exercise': 15,
          'Stress': 9,
          'Caffeine': 3,
        },
        weakFactors: const <String>['Caffeine', 'Screen time'],
        syncStatus: status,
      );
    }

    test('save and load assessment', () async {
      final a = makeAssessment();
      await repo.save(a);

      final loaded = repo.loadAll();
      expect(loaded.length, 1);
      expect(loaded.first.assessmentId, a.assessmentId);
      expect(loaded.first.score, 60);
      expect(loaded.first.level, 'good');
      expect(loaded.first.responses, a.responses);
      expect(loaded.first.factorScores, a.factorScores);
      expect(loaded.first.weakFactors, a.weakFactors);
      expect(loaded.first.syncStatus, LocalSqiSyncStatus.pending);
    });

    test('reconstruct SqiResult from persisted data', () async {
      final a = makeAssessment();
      await repo.save(a);

      final loaded = repo.loadAll().first;
      final level = SleepQualityLevel.values.firstWhere(
        (l) => l.name == loaded.level,
      );
      final result = SqiResult(
        score: loaded.score,
        level: level,
        weakFactors: List<String>.from(loaded.weakFactors),
        factorScores: Map<String, int>.from(loaded.factorScores),
        responses: Map<String, int>.from(loaded.responses),
      );
      expect(result.score, 60);
      expect(result.level, SleepQualityLevel.good);
      expect(result.factorScores['Exercise'], 15);
    });

    test('multiple assessments have unique ids', () async {
      final a1 = makeAssessment();
      final a2 = makeAssessment();
      expect(a1.assessmentId, isNot(equals(a2.assessmentId)));
      await repo.save(a1);
      await repo.save(a2);
      expect(repo.loadAll().length, 2);
    });

    test('update sync status without modifying assessment/result', () async {
      final a = makeAssessment();
      await repo.save(a);

      await repo.updateSyncStatus(
        a.assessmentId,
        LocalSqiSyncStatus.synced,
        cloudRecordId: 'cloud-123',
        attemptTime: DateTime(2026, 1, 2),
      );

      final loaded = repo.loadAll().first;
      expect(loaded.syncStatus, LocalSqiSyncStatus.synced);
      expect(loaded.cloudRecordId, 'cloud-123');
      expect(loaded.score, 60);
      expect(loaded.responses, a.responses);
      expect(loaded.lastSyncError, isNull);
    });

    test('update sync status to failed stores error', () async {
      final a = makeAssessment();
      await repo.save(a);

      await repo.updateSyncStatus(
        a.assessmentId,
        LocalSqiSyncStatus.failed,
        error: 'network error',
      );

      final loaded = repo.loadAll().first;
      expect(loaded.syncStatus, LocalSqiSyncStatus.failed);
      expect(loaded.lastSyncError, 'network error');
    });

    test('malformed stored records are skipped', () async {
      // Inject a malformed entry directly into storage.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final s2 = await StorageService.create();
      await s2.saveLocalSqiAssessment(makeAssessment().toJson());
      // Append a malformed json string manually.
      // Re-encode with a garbage entry by writing through prefs is not exposed;
      // simulate by saving a second valid assessment and a bad map via saveLocalSqiAssessment
      // (validates tryParse rejects bad maps).
      await s2.saveLocalSqiAssessment(<String, dynamic>{'foo': 'bar'});
      // The bad entry must be skipped on repository load.
      final r = StorageLocalSqiRepository(s2);
      expect(r.loadAll().length, 1);
    });

    test('data remains after repository recreation (same storage)', () async {
      final a = makeAssessment();
      await repo.save(a);

      final repo2 = StorageLocalSqiRepository(storage);
      final loaded = repo2.loadAll();
      expect(loaded.length, 1);
      expect(loaded.first.assessmentId, a.assessmentId);
    });

    test('saving same assessment id updates in place (no duplicate)', () async {
      final a = makeAssessment();
      await repo.save(a);
      final updated = a.copyWith(syncStatus: LocalSqiSyncStatus.synced);
      await repo.save(updated);

      final loaded = repo.loadAll();
      expect(loaded.length, 1);
      expect(loaded.first.syncStatus, LocalSqiSyncStatus.synced);
    });
  });

  group('Local SQI persistence (widget lifecycle)', () {
    testWidgets('local save occurs before cloud save', (tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = await StorageService.create();
      final cloudOrder = <String>[];
      final fakeRepo = _OrderTrackingSqiRepository(cloudOrder);
      final localRepo = _OrderTrackingLocalRepo(storage, cloudOrder);

      await tester.pumpWidget(
        MaterialApp(
          home: SleepQualityPage(
            repository: fakeRepo,
            localSqiRepository: localRepo,
            ensureSignedIn: () async => 'owner-uid',
          ),
        ),
      );

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('3').at(i));
        await tester.pump();
      }

      await tester.tap(find.text('Calculate SQI'));
      await tester.pumpAndSettle();

      // Local save happened before cloud write (initial + userId update).
      expect(cloudOrder, <String>['local', 'local', 'cloud']);
      // A durable local record exists.
      expect(localRepo.loadAll().length, 1);
    });
  });
}

class _OrderTrackingLocalRepo implements LocalSqiRepository {
  _OrderTrackingLocalRepo(this._storage, this.order);
  final StorageService _storage;
  final List<String> order;
  StorageLocalSqiRepository _inner(StorageService s) =>
      StorageLocalSqiRepository(s);

  @override
  String newAssessmentId() => 'rec-order';

  @override
  Future<void> save(LocalSqiAssessment assessment) async {
    order.add('local');
    await _inner(_storage).save(assessment);
  }

  @override
  List<LocalSqiAssessment> loadAll() => _inner(_storage).loadAll();

  @override
  Future<void> updateSyncStatus(
    String assessmentId,
    LocalSqiSyncStatus status, {
    String? userId,
    String? cloudRecordId,
    String? error,
    DateTime? attemptTime,
  }) async {
    await _inner(_storage).updateSyncStatus(
      assessmentId,
      status,
      userId: userId,
      cloudRecordId: cloudRecordId,
      error: error,
      attemptTime: attemptTime,
    );
  }
}

class _OrderTrackingSqiRepository implements SqiRepository {
  _OrderTrackingSqiRepository(this.order);
  final List<String> order;

  @override
  String newRecordId() => 'rec-order';

  @override
  Future<void> saveRecord(SQIRecord record) async {
    order.add('cloud');
  }

  @override
  Future<void> saveRecommendations(
    List<Recommendation> recommendations,
  ) async {}
}
