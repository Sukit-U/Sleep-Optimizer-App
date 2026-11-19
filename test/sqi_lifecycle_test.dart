import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/core/services/storage_service.dart';
import 'package:snoozemate/features/sleep_quality/data/repositories/local_sqi_repository.dart';
import 'package:snoozemate/features/sleep_quality/data/repositories/sqi_repository.dart';
import 'package:snoozemate/features/sleep_quality/domain/entities/local_sqi_assessment.dart';
import 'package:snoozemate/features/sleep_quality/presentation/pages/sleep_quality_page.dart';
import 'package:snoozemate/models/recommendation_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';

class _SucceedingSqiRepository implements SqiRepository {
  final recordAttempts = <SQIRecord>[];
  final recordWrites = <SQIRecord>[];
  final recommendationWrites = <List<Recommendation>>[];

  @override
  String newRecordId() => 'rec-succeed';

  @override
  Future<void> saveRecord(SQIRecord record) async {
    recordAttempts.add(record);
    recordWrites.add(record);
  }

  @override
  Future<void> saveRecommendations(List<Recommendation> recommendations) async {
    recommendationWrites.add(recommendations);
  }
}

class _FailOnceSqiRepository implements SqiRepository {
  int _calls = 0;
  final recordAttempts = <SQIRecord>[];
  final recordWrites = <SQIRecord>[];
  final recommendationWrites = <List<Recommendation>>[];

  @override
  String newRecordId() => 'rec-failonce';

  @override
  Future<void> saveRecord(SQIRecord record) async {
    recordAttempts.add(record);
    _calls++;
    if (_calls == 1) throw Exception('firestore unavailable');
    recordWrites.add(record);
  }

  @override
  Future<void> saveRecommendations(List<Recommendation> recommendations) async {
    recommendationWrites.add(recommendations);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'restore and retry after repository recreation uses original assessment id',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage1 = await StorageService.create();
      final localRepo1 = StorageLocalSqiRepository(storage1);
      final cloud = _FailOnceSqiRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: SleepQualityPage(
            repository: cloud,
            localSqiRepository: localRepo1,
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

      expect(cloud.recordAttempts, hasLength(1));
      final originalId = localRepo1.loadAll().single.assessmentId;
      expect(cloud.recordAttempts.single.recordId, originalId);
      expect(
        localRepo1.loadAll().single.syncStatus,
        isNot(LocalSqiSyncStatus.synced),
      );

      final storage2 = await StorageService.create();
      final localRepo2 = StorageLocalSqiRepository(storage2);

      await tester.pumpWidget(
        MaterialApp(
          home: SleepQualityPage(
            repository: cloud,
            localSqiRepository: localRepo2,
            ensureSignedIn: () async => 'owner-uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(localRepo2.loadAll().single.assessmentId, originalId);
      expect(localRepo2.loadAll().single.score, 60);

      await tester.tap(find.text('Calculate SQI'));
      await tester.pumpAndSettle();

      expect(cloud.recordWrites, hasLength(1));
      expect(cloud.recordWrites.single.recordId, originalId);
      expect(localRepo2.loadAll().single.syncStatus, LocalSqiSyncStatus.synced);
      expect(localRepo2.loadAll().single.cloudRecordId, originalId);
    },
  );

  testWidgets(
    'cloud success with interrupted local update retries to same document',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = await StorageService.create();
      final localRepo = StorageLocalSqiRepository(storage);
      final cloud = _SucceedingSqiRepository();

      // Seed a pending assessment (simulates the post-interruption state:
      // cloud may have succeeded, but local sync status is still pending).
      const originalId = 'interrupted-id';
      final assessment = LocalSqiAssessment(
        assessmentId: originalId,
        createdAt: DateTime(2026, 1, 1, 12, 0, 0),
        responses: const <String, int>{
          'Sleep duration': 3,
          'Sleep regularity': 3,
          'Screen time': 3,
          'Exercise': 3,
          'Stress': 3,
          'Caffeine': 3,
        },
        score: 60,
        level: 'good',
        factorScores: const <String, int>{
          'Sleep duration': 12,
          'Sleep regularity': 12,
          'Screen time': 12,
          'Exercise': 12,
          'Stress': 12,
          'Caffeine': 12,
        },
        weakFactors: const <String>['Caffeine'],
        syncStatus: LocalSqiSyncStatus.pending,
        userId: 'owner-uid',
      );
      await localRepo.save(assessment);

      await tester.pumpWidget(
        MaterialApp(
          home: SleepQualityPage(
            repository: cloud,
            localSqiRepository: localRepo,
            ensureSignedIn: () async => 'owner-uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calculate SQI'));
      await tester.pumpAndSettle();

      // Retry uses the original assessment id (no duplicate document).
      final uniqueIds = cloud.recordWrites.map((r) => r.recordId).toSet();
      expect(uniqueIds, {originalId});
      expect(uniqueIds.length, 1);
      expect(localRepo.loadAll().single.syncStatus, LocalSqiSyncStatus.synced);
      expect(localRepo.loadAll().single.cloudRecordId, originalId);
    },
  );

  testWidgets(
    'userId persists across repository recreation and retry payload',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage1 = await StorageService.create();
      final localRepo1 = StorageLocalSqiRepository(storage1);
      final cloud = _SucceedingSqiRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: SleepQualityPage(
            repository: cloud,
            localSqiRepository: localRepo1,
            ensureSignedIn: () async => 'user-U',
          ),
        ),
      );

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('3').at(i));
        await tester.pump();
      }
      await tester.tap(find.text('Calculate SQI'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      final storage2 = await StorageService.create();
      final localRepo2 = StorageLocalSqiRepository(storage2);

      await tester.pumpWidget(
        MaterialApp(
          home: SleepQualityPage(
            repository: cloud,
            localSqiRepository: localRepo2,
            ensureSignedIn: () async => 'user-U',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(localRepo2.loadAll().single.userId, 'user-U');

      await tester.tap(find.text('Calculate SQI'));
      await tester.pumpAndSettle();
      expect(cloud.recordWrites.last.userId, 'user-U');
    },
  );

  testWidgets('synced assessment is not unnecessarily resubmitted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = await StorageService.create();
    final localRepo = StorageLocalSqiRepository(storage);
    final cloud = _SucceedingSqiRepository();

    final assessment = LocalSqiAssessment(
      assessmentId: 'synced-id',
      createdAt: DateTime(2026, 1, 1, 12, 0, 0),
      responses: const <String, int>{
        'Sleep duration': 3,
        'Sleep regularity': 3,
        'Screen time': 3,
        'Exercise': 3,
        'Stress': 3,
        'Caffeine': 3,
      },
      score: 60,
      level: 'good',
      factorScores: const <String, int>{
        'Sleep duration': 12,
        'Sleep regularity': 12,
        'Screen time': 12,
        'Exercise': 12,
        'Stress': 12,
        'Caffeine': 12,
      },
      weakFactors: const <String>['Caffeine'],
      syncStatus: LocalSqiSyncStatus.synced,
      userId: 'owner-uid',
      cloudRecordId: 'synced-id',
    );
    await localRepo.save(assessment);

    await tester.pumpWidget(
      MaterialApp(
        home: SleepQualityPage(
          repository: cloud,
          localSqiRepository: localRepo,
          ensureSignedIn: () async => 'owner-uid',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calculate SQI'));
    await tester.pumpAndSettle();

    expect(cloud.recordWrites, isEmpty);
  });
}
