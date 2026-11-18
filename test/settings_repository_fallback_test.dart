import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/core/services/storage_service.dart';
import 'package:snoozemate/features/settings/data/repositories/settings_repository.dart';

void main() {
  test('loadSettings does not return a tampered theme from local fallback', () async {
    SharedPreferences.setMockInitialValues({'theme': 'malicious'});
    final repo = FirestoreSettingsRepository();
    final result = await repo.loadSettings('uid-1');
    expect(result == null || result['theme'] == 'light' || result['theme'] == 'dark', isTrue);
    if (result != null) {
      expect(result['theme'], isNot('malicious'));
    }
  });

  test('loadSettings returns a valid theme from local fallback', () async {
    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    final repo = FirestoreSettingsRepository();
    final result = await repo.loadSettings('uid-1');
    expect(result, isNotNull);
    expect(result!['theme'], 'dark');
  });
}