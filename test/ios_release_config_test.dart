import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/app/firebase_environment.dart';
import 'package:snoozemate/firebase_options.dart' as prod;
import 'package:snoozemate/firebase_options_dev.dart' as dev;

/// iOS installs one bundle id per Xcode configuration, and Firebase only
/// accepts a bundle id it holds a registered iOS app for. These checks pin
/// everything the repository itself can prove — Xcode, Gradle, `firebase.json`
/// and the generated Dart options. Whether the Console really holds that app id
/// cannot be read from here; docs/ENVIRONMENTS.md lists the owner steps.
void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  final xcodeProject = read('ios/Runner.xcodeproj/project.pbxproj');
  final androidGradle = read('android/app/build.gradle.kts');

  final runnerBundleIds = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
      .allMatches(xcodeProject)
      .map((match) => match.group(1)!.trim())
      .where((id) => !id.endsWith('.RunnerTests'))
      .toList();
  final xcodeBundleId = runnerBundleIds.first;

  final firebaseJson =
      jsonDecode(read('firebase.json')) as Map<String, dynamic>;
  final recordedIosAppId = firebaseJson['flutter']['platforms']['dart']
      ['lib/firebase_options.dart']['configurations']['ios'] as String;

  test('every Runner configuration shares one non-placeholder bundle id', () {
    expect(runnerBundleIds, hasLength(3));
    expect(runnerBundleIds.toSet(), {xcodeBundleId});
    expect(xcodeBundleId, isNot(startsWith('com.example')));

    // iOS and Android ship as one product, so the bundle id root must match.
    final androidApplicationId = RegExp(r'applicationId = "([^"]+)"')
        .firstMatch(androidGradle)!
        .group(1)!;
    expect(xcodeBundleId, androidApplicationId);
  });

  test('prod iOS app id in Dart matches firebase.json and the prod project',
      () {
    final ios = prod.DefaultFirebaseOptions.ios;
    expect(ios.appId, recordedIosAppId);
    expect(ios.projectId, 'sleep-optimizer-59c83');
    expect(ios.projectId, prod.DefaultFirebaseOptions.android.projectId);
  });

  test('prod resolves on an iOS target to the app recorded in firebase.json',
      () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final options = firebaseOptionsForEnv('prod');
    expect(options.projectId, 'sleep-optimizer-59c83');
    expect(options.appId, recordedIosAppId);
  });

  test('iOS dev has its own Firebase app, or fails with the owner steps', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    FirebaseOptions? devIos;
    try {
      devIos = dev.DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError {
      devIos = null;
    }

    if (devIos == null) {
      // Recorded gap: sleep-optimizer-dev has no iOS app yet, so a dev iOS
      // build cannot start. It must fail with the documented steps rather
      // than fall back to the production project.
      expect(
        () => firebaseOptionsForEnv('dev'),
        throwsA(isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('docs/ENVIRONMENTS.md'),
        )),
      );
      return;
    }

    expect(devIos.projectId, 'sleep-optimizer-dev');
    expect(devIos.appId, isNot(recordedIosAppId));
    expect(devIos.iosBundleId, xcodeBundleId);
  });

  test('no committed plist pins the one shared iOS config path to a project',
      () {
    // `ios/Runner/GoogleService-Info.plist` is a single path used by every iOS
    // build, so a committed copy would pin dev or prod for all of them. The
    // app boots from the Dart options instead, so the file must stay ignored.
    expect(read('.gitignore'), contains('/ios/Runner/GoogleService-Info.plist'));

    // A local copy (for example the dev app downloaded from the console) is
    // allowed, but it must still name this app and one of the two projects.
    final plist = File('ios/Runner/GoogleService-Info.plist');
    if (!plist.existsSync()) return;

    final content = plist.readAsStringSync();
    String value(String key) =>
        RegExp('<key>$key</key>\\s*<string>([^<]*)</string>')
            .firstMatch(content)!
            .group(1)!;

    expect(value('BUNDLE_ID'), xcodeBundleId);
    final senderIds = {
      prod.DefaultFirebaseOptions.android.messagingSenderId,
      dev.DefaultFirebaseOptions.android.messagingSenderId,
    };
    expect(senderIds, contains(value('GOOGLE_APP_ID').split(':')[1]));
  });

  test('the storyboards Xcode compiles are well-formed XIB documents', () {
    // `flutter build ios` fails inside Xcode with "Extra content at the end of
    // the document" when a storyboard carries a duplicated closing tag, and
    // nothing else in the repository parses these files.
    for (final path in [
      'ios/Runner/Base.lproj/Main.storyboard',
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    ]) {
      final body = read(path);
      expect('<document'.allMatches(body), hasLength(1), reason: path);
      expect('</document>'.allMatches(body), hasLength(1), reason: path);
      expect(body.trimRight(), endsWith('</document>'), reason: path);

      // `resources` is a sibling of `scenes`, never a child of it.
      final scenes = RegExp(r'<scenes>[\s\S]*?</scenes>').firstMatch(body);
      expect(scenes, isNotNull, reason: path);
      expect(scenes!.group(0), isNot(contains('<resources')), reason: path);
    }
  });

  test('Xcode checks APP_ENV before Flutter builds a Release/Profile app', () {
    final phase = RegExp(
      r'([0-9A-F]{24}) /\* Verify APP_ENV \*/ = \{\n\t*isa = PBXShellScriptBuildPhase;[\s\S]*?shellScript = ("[^\n]*");\n\t*\};\n',
    ).firstMatch(xcodeProject);
    expect(phase, isNotNull, reason: 'the Verify APP_ENV phase is missing');
    final phaseId = phase!.group(1)!;
    expect(phase.group(2), contains('scripts/verify_app_env.sh'));

    // Attached to the Runner target, ahead of Flutter's own script phase, so a
    // Release/Profile archive stops before any Dart code is built.
    final runnerTarget = RegExp(
      r'97C146ED1CF9000F007C117D /\* Runner \*/ = \{\n\t*isa = PBXNativeTarget;[\s\S]*?\n\t*\};\n',
    ).firstMatch(xcodeProject);
    expect(runnerTarget, isNotNull, reason: 'the Runner target is missing');
    final target = runnerTarget!.group(0)!;
    expect(target, contains(phaseId));
    expect(
      target.indexOf(phaseId),
      lessThan(target.indexOf('/* Run Script */')),
    );

    final script = File('ios/scripts/verify_app_env.sh');
    expect(script.existsSync(), isTrue);
    final body = script.readAsStringSync();
    expect(body, contains('DART_DEFINES'));
    expect(body, contains('Release | Profile'));
  });
}
