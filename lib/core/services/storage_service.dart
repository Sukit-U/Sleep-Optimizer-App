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
}
