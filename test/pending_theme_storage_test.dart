import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/core/services/pending_theme_storage.dart';

void main() {
  test('save/load/clear pending theme', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = PendingThemeStorage(prefs);

    await storage.savePendingTheme('u1', 'dark');
    expect(storage.loadPendingTheme('u1'), {'userId': 'u1', 'theme': 'dark'});

    await storage.clearPendingTheme('u1');
    expect(storage.loadPendingTheme('u1'), isNull);
  });

  test('load returns null for mismatched user', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = PendingThemeStorage(prefs);
    await storage.savePendingTheme('u1', 'light');
    expect(storage.loadPendingTheme('u2'), isNull);
  });

  test('load returns null for invalid theme value', () async {
    SharedPreferences.setMockInitialValues({
      'pending_settings_user': 'u1',
      'pending_settings_theme': 'blue',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = PendingThemeStorage(prefs);
    expect(storage.loadPendingTheme('u1'), isNull);
  });

  test('clear is no-op for mismatched user', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = PendingThemeStorage(prefs);
    await storage.savePendingTheme('u1', 'dark');
    await storage.clearPendingTheme('u2');
    expect(storage.loadPendingTheme('u1'), isNotNull);
  });
}
