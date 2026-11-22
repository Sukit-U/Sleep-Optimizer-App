import 'package:shared_preferences/shared_preferences.dart';

class PendingThemeStorage {
  PendingThemeStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _pendingThemeKey = 'pending_settings_theme';
  static const _pendingThemeUserKey = 'pending_settings_user';

  Future<void> savePendingTheme(String userId, String theme) async {
    await _prefs.setString(_pendingThemeUserKey, userId);
    await _prefs.setString(_pendingThemeKey, theme);
  }

  Map<String, String>? loadPendingTheme(String userId) {
    final u = _prefs.getString(_pendingThemeUserKey);
    final t = _prefs.getString(_pendingThemeKey);
    if (u == userId && (t == 'light' || t == 'dark')) {
      return {'userId': u!, 'theme': t!};
    }
    return null;
  }

  Future<void> clearPendingTheme(String userId) async {
    final u = _prefs.getString(_pendingThemeUserKey);
    if (u == userId) {
      await _prefs.remove(_pendingThemeKey);
      await _prefs.remove(_pendingThemeUserKey);
    }
  }
}
