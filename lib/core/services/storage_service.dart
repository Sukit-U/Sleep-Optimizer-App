import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveTheme(String theme) async {
    await _prefs.setString('theme', theme);
  }

  String? loadTheme() {
    return _prefs.getString('theme');
  }

  Future<void> saveHistoryEntry(String key, Map<String, dynamic> entry) async {
    final existing = _prefs.getStringList(key) ?? <String>[];
    existing.add(jsonEncode(entry));
    await _prefs.setStringList(key, existing);
  }

  List<Map<String, dynamic>> loadHistoryEntries(String key) {
    final existing = _prefs.getStringList(key) ?? <String>[];
    return existing
        .map((jsonEntry) => jsonDecode(jsonEntry) as Map<String, dynamic>)
        .toList();
  }

  static const _localSleepPlansKey = 'local_sleep_plans';

  /// Appends a sleep plan saved on this device only (offline fallback).
  ///
  /// Uses the same on-device list as [saveHistoryEntry], so a plan saved while
  /// offline survives an app restart.
  Future<void> saveLocalSleepPlan(Map<String, dynamic> plan) =>
      saveHistoryEntry(_localSleepPlansKey, plan);

  /// Every sleep plan saved on this device only, oldest first.
  List<Map<String, dynamic>> loadLocalSleepPlans() =>
      loadHistoryEntries(_localSleepPlansKey);

  static const _localSqiAssessmentsKey = 'local_sqi_assessments';

  /// Persists (or updates) a durable SQI assessment record on this device.
  ///
  /// Records are keyed by `assessmentId`, so saving an updated status for an
  /// existing assessment overwrites in place instead of appending a duplicate.
  Future<void> saveLocalSqiAssessment(Map<String, dynamic> assessment) async {
    final existing = loadLocalSqiAssessments();
    final id = assessment['assessmentId'];
    final idx = existing.indexWhere((e) => e['assessmentId'] == id);
    if (idx >= 0) {
      existing[idx] = assessment;
    } else {
      existing.add(assessment);
    }
    await _prefs.setStringList(
      _localSqiAssessmentsKey,
      existing.map(jsonEncode).toList(),
    );
  }

  /// Every durable SQI assessment saved on this device, oldest first.
  /// Malformed entries are skipped so one bad record cannot break loading.
  List<Map<String, dynamic>> loadLocalSqiAssessments() {
    final raw = _prefs.getStringList(_localSqiAssessmentsKey) ?? <String>[];
    final result = <Map<String, dynamic>>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, dynamic>) {
          result.add(decoded);
        }
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return result;
  }
}
