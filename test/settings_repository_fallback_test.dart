import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/features/settings/data/repositories/settings_repository.dart';

void main() {
  test(
    'loadSettings does not return a tampered theme from local fallback',
    () async {
      SharedPreferences.setMockInitialValues({'theme': 'malicious'});
      final repo = FirestoreSettingsRepository();
      final result = await repo.loadSettings('uid-1');
      expect(
        result == null ||
            result['theme'] == 'light' ||
            result['theme'] == 'dark',
        isTrue,
      );
      if (result != null) {
        expect(result['theme'], isNot('malicious'));
      }
    },
  );

  test('loadSettings returns a valid theme from local fallback', () async {
    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    final repo = FirestoreSettingsRepository();
    final result = await repo.loadSettings('uid-1');
    expect(result, isNotNull);
    expect(result!['theme'], 'dark');
  });

  test('loadSettings accepts light from local fallback', () async {
    SharedPreferences.setMockInitialValues({'theme': 'light'});
    final result = await FirestoreSettingsRepository().loadSettings('uid-1');
    expect(result, isNotNull);
    expect(result!['theme'], 'light');
  });

  test('loadSettings rejects a theme with the wrong case', () async {
    SharedPreferences.setMockInitialValues({'theme': 'Dark'});
    final result = await FirestoreSettingsRepository().loadSettings('uid-1');
    expect(result, isNull);
  });

  test('loadSettings rejects an empty theme', () async {
    SharedPreferences.setMockInitialValues({'theme': ''});
    final result = await FirestoreSettingsRepository().loadSettings('uid-1');
    expect(result, isNull);
  });
}
