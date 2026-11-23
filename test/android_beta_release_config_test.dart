import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies Android beta distribution and release build guardrails:
/// - Build-time Gradle flavor vs `--dart-define=APP_ENV` mismatch check.
/// - `scripts/android-release-version.sh` support for `--allow-beta` and
///   `vMAJOR.MINOR.PATCH-beta.N` tags routed to `dev`.
/// - `.github/workflows/release.yml` support for `dev` beta builds, signature
///   and package verification, `if: always()` keystore cleanup, and secret
///   hygiene.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final releaseWorkflow = File(
    '.github/workflows/release.yml',
  ).readAsStringSync();
  final versionScript = File(
    'scripts/android-release-version.sh',
  ).readAsStringSync();
  final signingDoc = File('docs/RELEASE_SIGNING.md').readAsStringSync();
  final betaDoc = File('docs/ANDROID_BETA_DISTRIBUTION.md').readAsStringSync();

  group('Gradle flavor vs APP_ENV build-time guard', () {
    test('decodes dart-defines and extracts APP_ENV in build.gradle.kts', () {
      expect(gradle, contains('findProperty("dart-defines")'));
      expect(gradle, contains('Base64.getDecoder().decode'));
      expect(gradle, contains('startsWith("APP_ENV=")'));
    });

    test('fails build when flavor and APP_ENV disagree', () {
      expect(
        gradle,
        contains(
          'Flavor \'\$flavorName\' does not match --dart-define=APP_ENV=\$dartAppEnv',
        ),
      );
      expect(
        gradle,
        contains(
          'Production release build requires explicit --dart-define=APP_ENV=prod',
        ),
      );
    });
  });

  group('Android release and beta version script', () {
    test('supports --allow-beta for vMAJOR.MINOR.PATCH-beta.N tags', () {
      expect(versionScript, contains('--allow-beta'));
      expect(versionScript, contains('derive_allow_beta'));
      expect(versionScript, contains('release_channel="beta"'));
      expect(versionScript, contains('target_env="dev"'));
      expect(versionScript, contains('base_version_name='));
    });

    test('self-test covers valid and invalid beta tags', () {
      expect(versionScript, contains('v1.0.0-beta.1'));
      expect(versionScript, contains('v1.2.3-beta.12'));
      expect(versionScript, contains('check_beta_rejected "v1.0.0-beta.0"'));
      expect(versionScript, contains('check_beta_rejected "v1.0.0-beta.01"'));
      expect(versionScript, contains('check_beta_rejected "v1.0.0-beta.100"'));
    });
  });

  group('GitHub Actions release.yml beta & secret hygiene invariants', () {
    test(
      'supports beta tags and workflow_dispatch with dev default target_env',
      () {
        expect(releaseWorkflow, contains('target_env:'));
        expect(releaseWorkflow, contains("default: 'dev'"));
        expect(
          releaseWorkflow,
          contains(
            'sh scripts/android-release-version.sh --allow-beta "\$TAG_TO_USE"',
          ),
        );
        expect(
          releaseWorkflow,
          contains('EXPECTED_PACKAGE="com.snoozefriend.snoozemate.dev"'),
        );
        expect(
          releaseWorkflow,
          contains('FIREBASE_PROJECT="sleep-optimizer-dev"'),
        );
      },
    );

    test(
      'verifies signatures, package badging, and cleans up temporary keystore',
      () {
        expect(releaseWorkflow, contains('apksigner" verify --print-certs'));
        expect(releaseWorkflow, contains('jarsigner -verify'));
        expect(releaseWorkflow, contains('dump badging'));
        expect(releaseWorkflow, contains('*"name=\'\$EXPECTED_PACKAGE\'"*'));
        expect(releaseWorkflow, contains('Clean up temporary keystore files'));
        expect(releaseWorkflow, contains('if: always()'));
        expect(
          releaseWorkflow,
          contains('rm -f android/upload-keystore.jks android/key.properties'),
        );
      },
    );

    test('never echoes signing secrets or uploads keystore files', () {
      expect(
        releaseWorkflow,
        isNot(contains('echo "\$ANDROID_KEYSTORE_PASSWORD"')),
      );
      expect(releaseWorkflow, isNot(contains('echo "\$ANDROID_KEY_PASSWORD"')));
      expect(
        releaseWorkflow,
        isNot(contains('echo "\$ANDROID_KEYSTORE_BASE64"')),
      );
      expect(releaseWorkflow, contains('-storepass:env'));
      expect(releaseWorkflow, contains('-keypass:env'));
    });
  });

  group('Android beta and signing documentation', () {
    test('documents canonical keystore path and beta build verification', () {
      expect(signingDoc, contains('android/upload-keystore.jks'));
      expect(signingDoc, contains('storeFile=upload-keystore.jks'));
      expect(betaDoc, contains('com.snoozefriend.snoozemate.dev'));
      expect(betaDoc, contains('sleep-optimizer-dev'));
      expect(betaDoc, contains('apksigner'));
      expect(betaDoc, contains('sha256sum'));
    });
  });
}
