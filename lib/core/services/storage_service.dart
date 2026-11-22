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

  static const _localeKey = 'app_locale';

  Future<void> saveLocale(String locale) async {
    await _prefs.setString(_localeKey, locale);
  }

  String? loadLocale() {
    return _prefs.getString(_localeKey);
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
  static const _deletedSleepPlanIdsKey = 'deleted_sleep_plan_ids';

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

  List<Map<String, dynamic>> loadLocalSleepPlans() {
    final deleted = loadDeletedSleepPlanIds();
    final raw = _prefs.getStringList(_localSleepPlansKey) ?? <String>[];
    final result = <Map<String, dynamic>>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, dynamic>) {
          final id = decoded['planId'];
          if (id is String && deleted.contains(id)) {
            continue;
          }
          result.add(decoded);
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> deleteLocalSleepPlan(String planId) async {
    final existing = loadLocalSleepPlans();
    final filtered = existing.where((e) => e['planId'] != planId).toList();
    await _prefs.setStringList(
      _localSleepPlansKey,
      filtered.map(jsonEncode).toList(),
    );
    await markSleepPlanDeleted(planId);
  }

  Future<void> markSleepPlanDeleted(String planId) async {
    final deleted = loadDeletedSleepPlanIds();
    deleted.add(planId);
    await _prefs.setStringList(_deletedSleepPlanIdsKey, deleted.toList());
  }

  Set<String> loadDeletedSleepPlanIds() {
    final raw = _prefs.getStringList(_deletedSleepPlanIdsKey) ?? <String>[];
    return raw.toSet();
  }

  static const _localSqiAssessmentsKey = 'local_sqi_assessments';

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

  List<Map<String, dynamic>> loadLocalSqiAssessments() {
    final raw = _prefs.getStringList(_localSqiAssessmentsKey) ?? <String>[];
    final result = <Map<String, dynamic>>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, dynamic>) {
          result.add(decoded);
        }
      } catch (_) {}
    }
    return result;
  }
}
