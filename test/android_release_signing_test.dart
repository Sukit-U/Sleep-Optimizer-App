import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the invariants of `android/app/build.gradle.kts` around signing.
/// Gradle itself cannot run here (no Android SDK / JDK 17), so this checks the
/// wiring textually — enough to catch the regression that matters: a release
/// build silently signed with the debug key, or signing material being
/// committable.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final gitignore = File('.gitignore').readAsStringSync();

  test('release is never signed with the debug key', () {
    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
    expect(gradle, contains('signingConfigs.getByName("release")'));
  });

  test('release signing config is built from android/key.properties', () {
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(gradle, contains('keystoreProperties["storeFile"]'));
    expect(gradle, contains('keystoreProperties["keyAlias"]'));
    expect(gradle, contains('storePassword = storePasswordValue'));
    expect(gradle, contains('keyPassword = keyPasswordValue'));
  });

  test('keystore passwords can come from the environment, not a file', () {
    expect(gradle, contains('System.getenv(envName)'));
    expect(gradle, contains('signingValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")'));
    expect(gradle, contains('signingValue("ANDROID_KEY_PASSWORD", "keyPassword")'));
    expect(gradle, isNot(contains('storePassword = keystoreProperties')));
    expect(gradle, isNot(contains('keyPassword = keystoreProperties')));
  });

  test('a keystore without a password stays unsigned', () {
    expect(gradle, contains('keystoreProperties["storeFile"] != null && storePasswordValue != null'));
  });

  test('signing material can never be committed', () {
    final entries = gitignore.split(RegExp(r'\r?\n'));
    for (final entry in ['/android/key.properties', '*.jks', '*.keystore']) {
      expect(entries, contains(entry), reason: '.gitignore must ignore $entry');
    }
  });
}
