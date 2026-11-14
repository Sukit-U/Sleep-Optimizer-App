import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/app/firebase_environment.dart';
import 'package:snoozemate/firebase_options.dart' as prod;
import 'package:snoozemate/firebase_options_dev.dart' as dev;

void main() {
  test('APP_ENV is dev unless the build passes --dart-define=APP_ENV', () {
    // This test binary is compiled without any dart-define, so it sees the
    // compile-time default.
    expect(appEnv, 'dev');
  });

  test('dev options target sleep-optimizer-dev, not production', () {
    expect(dev.DefaultFirebaseOptions.android.projectId, 'sleep-optimizer-dev');
    expect(prod.DefaultFirebaseOptions.android.projectId,
        isNot(dev.DefaultFirebaseOptions.android.projectId));
  });

  group('firebaseOptionsForEnv', () {
    // The generated options expose `currentPlatform`, which only resolves the
    // Android entry we care about once the platform is Android.
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('dev selects the dev project', () {
      expect(firebaseOptionsForEnv('dev').projectId, 'sleep-optimizer-dev');
    });

    test('prod selects the production project', () {
      expect(firebaseOptionsForEnv('prod').projectId, 'sleep-optimizer-59c83');
    });

    test('any other value throws instead of falling back', () {
      expect(() => firebaseOptionsForEnv('staging'), throwsStateError);
    });
  });

  group('iOS release builds must name their environment', () {
    test('an implicit APP_ENV fails an iOS release build', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(
        () => rejectImplicitEnvOnIos(
          env: 'dev',
          envWasProvided: false,
          isReleaseBuild: true,
        ),
        throwsA(isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('--dart-define=APP_ENV=prod'),
        )),
      );
    });

    test('an explicit APP_ENV=prod is accepted', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(
        () => rejectImplicitEnvOnIos(
          env: 'prod',
          envWasProvided: true,
          isReleaseBuild: true,
        ),
        returnsNormally,
      );
    });

    test('debug iOS builds keep the dev default', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(
        () => rejectImplicitEnvOnIos(
          env: 'dev',
          envWasProvided: false,
          isReleaseBuild: false,
        ),
        returnsNormally,
      );
    });

    test('Android release builds are untouched', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(
        () => rejectImplicitEnvOnIos(
          env: 'dev',
          envWasProvided: false,
          isReleaseBuild: true,
        ),
        returnsNormally,
      );
    });
  });
}
