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

  /// Persists (or updates) a durable sleep plan record on this device.
  ///
  /// Plans are keyed by `planId`, so saving an updated status for an
  /// existing plan overwrites in place instead of appending a duplicate.
  Future<void> saveLocalSleepPlan(Map<String, dynamic> plan) async {
    final existing = loadLocalSleepPlans();
    final id = plan['planId'];
    final idx = existing.indexWhere((e) => e['planId'] == id);
    if (idx >= 0) {
      existing[idx] = plan;
    } else {
      existing.add(plan);
    }
    await _prefs.setStringList(
      _localSleepPlansKey,
      existing.map(jsonEncode).toList(),
    );
  }

  /// Every durable sleep plan saved on this device, oldest first.
  /// Malformed entries are skipped so one bad record cannot break loading.
  List<Map<String, dynamic>> loadLocalSleepPlans() {
    final raw = _prefs.getStringList(_localSleepPlansKey) ?? <String>[];
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

  /// Deletes a local sleep plan by planId.
  Future<void> deleteLocalSleepPlan(String planId) async {
    final existing = loadLocalSleepPlans();
    final filtered = existing.where((e) => e['planId'] != planId).toList();
    await _prefs.setStringList(
      _localSleepPlansKey,
      filtered.map(jsonEncode).toList(),
    );
  }

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
