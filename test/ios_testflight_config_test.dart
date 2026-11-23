import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins the repository-side requirements for iOS TestFlight beta distribution:
///
/// 1. `ios/Runner/Runner.entitlements` declares the App Attest environment
///    key (`com.apple.developer.devicecheck.appattest-environment` =
///    `production`) required by `AppleAppAttestWithDeviceCheckFallbackProvider`
///    when signed for TestFlight / App Store distribution.
/// 2. `ios/Runner.xcodeproj/project.pbxproj` registers `Runner.entitlements`
///    and wires `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` across
///    all three `Runner` build configurations (`Debug`, `Release`, `Profile`).
/// 3. `ios/scripts/verify_app_env.sh` documents both `APP_ENV=dev` (TestFlight
///    beta) and `APP_ENV=prod` (App Store production).
/// 4. `codemagic.yaml` targets `sleep-optimizer-dev` (`APP_ENV: "dev"`) for
///    beta distribution, derives a numeric `MAJOR.MINOR.PATCH` `--build-name`
///    and monotonically increasing `--build-number` (never reusing static
///    `1.0.0+1`), exports the IPA, and enables `submit_to_testflight: true`
///    with `submit_to_app_store: false`.
void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  test(
    'Runner.entitlements is a well-formed plist with App Attest production env',
    () {
      final file = File('ios/Runner/Runner.entitlements');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'ios/Runner/Runner.entitlements must exist for App Attest',
      );

      final body = read('ios/Runner/Runner.entitlements');
      expect(body, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(body, contains('<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0'));
      expect('<plist'.allMatches(body), hasLength(1));
      expect('</plist>'.allMatches(body), hasLength(1));
      expect('<dict>'.allMatches(body), hasLength(1));
      expect('</dict>'.allMatches(body), hasLength(1));

      final match = RegExp(
        r'<key>com\.apple\.developer\.devicecheck\.appattest-environment</key>\s*<string>([^<]+)</string>',
      ).firstMatch(body);
      expect(
        match,
        isNotNull,
        reason:
            'Runner.entitlements must declare com.apple.developer.devicecheck.appattest-environment',
      );
      expect(match!.group(1), 'production');
    },
  );

  test(
    'project.pbxproj wires CODE_SIGN_ENTITLEMENTS across Debug, Release, Profile on Runner',
    () {
      final pbxproj = read('ios/Runner.xcodeproj/project.pbxproj');

      // Balanced braces sanity check so surgical pbxproj edits never corrupt
      // the Xcode project file structure.
      final openBraces = '{'.allMatches(pbxproj).length;
      final closeBraces = '}'.allMatches(pbxproj).length;
      expect(openBraces, closeBraces);

      expect(
        pbxproj,
        contains(
          '/* Runner.entitlements */ = {isa = PBXFileReference; '
          'lastKnownFileType = text.plist.entitlements; '
          'path = Runner.entitlements; sourceTree = "<group>"; };',
        ),
      );

      // Runner PBXGroup includes Runner.entitlements.
      final runnerGroup = RegExp(
        r'97C146F01CF9000F007C117D /\* Runner \*/ = \{\n\t*isa = PBXGroup;[\s\S]*?\n\t*\};',
      ).firstMatch(pbxproj);
      expect(runnerGroup, isNotNull);
      expect(runnerGroup!.group(0), contains('/* Runner.entitlements */'));

      // Every Runner target XCBuildConfiguration (Profile, Debug, Release) must
      // wire CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;.
      final runnerConfigIds = [
        '249021D4217E4FDB00AE95B9 /* Profile */',
        '97C147061CF9000F007C117D /* Debug */',
        '97C147071CF9000F007C117D /* Release */',
      ];
      for (final configHeader in runnerConfigIds) {
        final escaped = RegExp.escape(configHeader);
        final block = RegExp(
          '$escaped = \\{\\n\\t*isa = XCBuildConfiguration;[\\s\\S]*?\\n\\t*\\};',
        ).firstMatch(pbxproj);
        expect(block, isNotNull, reason: 'Missing $configHeader in pbxproj');
        expect(
          block!.group(0),
          contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'),
          reason: '$configHeader must set CODE_SIGN_ENTITLEMENTS',
        );
        expect(
          block.group(0),
          contains('PRODUCT_BUNDLE_IDENTIFIER = com.snoozefriend.snoozemate;'),
          reason: '$configHeader must preserve PRODUCT_BUNDLE_IDENTIFIER',
        );
      }

      // Exactly 3 CODE_SIGN_ENTITLEMENTS entries (on Runner only, not RunnerTests).
      expect(
        RegExp(
          r'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;',
        ).allMatches(pbxproj),
        hasLength(3),
      );
    },
  );

  test(
    'verify_app_env.sh enforces exact last-wins APP_ENV and documents dev and prod',
    () {
      final script = read('ios/scripts/verify_app_env.sh');
      expect(script, contains('--dart-define=APP_ENV=dev'));
      expect(script, contains('--dart-define=APP_ENV=prod'));
      expect(script, contains('no --dart-define=APP_ENV'));
      expect(script, contains('APP_ENV=*) last_app_env='));
      expect(script, isNot(contains('*APP_ENV=dev*')));
    },
  );

  test(
    'RunnerTests.swift verifies bundle identifier and version keys in Info.plist',
    () {
      final swiftTests = read('ios/RunnerTests/RunnerTests.swift');
      expect(swiftTests, contains('com.snoozefriend.snoozemate'));
      expect(swiftTests, contains('CFBundleShortVersionString'));
      expect(swiftTests, contains('CFBundleVersion'));
    },
  );

  test(
    'codemagic.yaml ios-workflow targets dev Firebase, increments build number, and enables TestFlight',
    () {
      final codemagic = read('codemagic.yaml');

      // Extract ios-workflow block (up to ios-verify-archive-guard).
      final iosWorkflowMatch = RegExp(
        r'  ios-workflow:[\s\S]*?(?=\n  ios-verify-archive-guard:)',
      ).firstMatch(codemagic);
      expect(
        iosWorkflowMatch,
        isNotNull,
        reason: 'ios-workflow section must exist in codemagic.yaml',
      );
      final iosWorkflow = iosWorkflowMatch!.group(0)!;

      // Signing & bundle identifier.
      expect(iosWorkflow, contains('app_store_connect: codemagic'));
      expect(iosWorkflow, contains('distribution_type: app_store'));
      expect(
        iosWorkflow,
        contains('bundle_identifier: com.snoozefriend.snoozemate'),
      );
      expect(iosWorkflow, contains('xcode-project use-profiles'));

      // Target environment must be dev for beta safety, and vars must not
      // shadow Codemagic UI APP_STORE_APPLE_ID with an empty string.
      expect(iosWorkflow, contains('APP_ENV: "dev"'));
      expect(iosWorkflow, isNot(contains('APP_STORE_APPLE_ID: ""')));
      expect(iosWorkflow, contains('APP_STORE_APPLE_ID'));

      // Build name (numeric MAJOR.MINOR.PATCH) & monotonic build number with
      // fail-fast error handling on ASC CLI failures.
      expect(
        iosWorkflow,
        contains('app-store-connect get-latest-testflight-build-number'),
      );
      expect(iosWorkflow, contains('ASC_STATUS=0'));
      expect(iosWorkflow, contains('--dart-define=APP_ENV=\$APP_ENV'));
      expect(iosWorkflow, contains('--build-name="\$BUILD_NAME"'));
      expect(iosWorkflow, contains('--build-number="\$BUILD_NUM"'));
      expect(
        iosWorkflow,
        contains('--export-options-plist=/Users/builder/export_options.plist'),
      );

      // TestFlight submission enabled; App Store submission remains disabled.
      expect(iosWorkflow, contains('submit_to_testflight: true'));
      expect(iosWorkflow, contains('submit_to_app_store: false'));
    },
  );

  test(
    'codemagic.yaml android-workflow defaults to dev beta environment and passes build version flags',
    () {
      final codemagic = read('codemagic.yaml');
      final androidWorkflowMatch = RegExp(
        r'  android-workflow:[\s\S]*?(?=\n  ios-workflow:)',
      ).firstMatch(codemagic);
      expect(androidWorkflowMatch, isNotNull);
      final androidWorkflow = androidWorkflowMatch!.group(0)!;

      expect(androidWorkflow, contains('APP_ENV: "dev"'));
      expect(
        androidWorkflow,
        contains('PACKAGE_NAME: "com.snoozefriend.snoozemate.dev"'),
      );
      expect(
        androidWorkflow,
        contains('sh scripts/android-release-version.sh --allow-beta'),
      );
      expect(androidWorkflow, contains('--flavor dev --release'));
      expect(androidWorkflow, contains('--build-name="\$BUILD_NAME"'));
      expect(
        androidWorkflow,
        contains('--build-number="\$ANDROID_VERSION_CODE"'),
      );
    },
  );

  test(
    'iOS TestFlight distribution runbook documents external requirements',
    () {
      final doc = File('docs/IOS_TESTFLIGHT_DISTRIBUTION.md');
      expect(doc.existsSync(), isTrue);
      final body = read('docs/IOS_TESTFLIGHT_DISTRIBUTION.md');

      expect(body, contains('sleep-optimizer-dev'));
      expect(body, contains('com.snoozefriend.snoozemate'));
      expect(body, contains('Runner.entitlements'));
      expect(
        body,
        contains('com.apple.developer.devicecheck.appattest-environment'),
      );
      expect(body, contains('DEVELOPMENT_TEAM'));
      expect(body, contains('APP_STORE_APPLE_ID'));
      expect(body, contains('UNKNOWN'));
    },
  );
}
