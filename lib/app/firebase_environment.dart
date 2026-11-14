import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart' as prod;
import '../firebase_options_dev.dart' as dev;

/// Which Firebase project this build talks to, chosen at compile time:
///
/// ```bash
/// flutter run --flavor dev --dart-define=APP_ENV=dev
/// flutter build appbundle --release --flavor prod --dart-define=APP_ENV=prod
/// ```
///
/// Defaults to `dev` so a build that forgets the define cannot reach
/// production data.
const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

/// Whether the build passed `--dart-define=APP_ENV` at all.
const bool appEnvWasProvided = bool.hasEnvironment('APP_ENV');

/// The [FirebaseOptions] belonging to [env].
///
/// `dev` and `prod` are the only targets the generated
/// `firebase_options*.dart` files describe; anything else is a build mistake
/// and fails loudly instead of silently falling back to a real project.
///
/// A platform the selected environment has no Firebase app for (today: iOS on
/// `dev`) also fails loudly, with the owner steps to fix it, instead of the
/// generated file's generic "run the FlutterFire CLI again" message.
FirebaseOptions firebaseOptionsForEnv(String env) {
  rejectImplicitEnvOnIos(
    env: env,
    envWasProvided: appEnvWasProvided,
    isReleaseBuild: kReleaseMode || kProfileMode,
  );

  final FirebaseOptions Function() resolve;
  switch (env) {
    case 'dev':
      resolve = () => dev.DefaultFirebaseOptions.currentPlatform;
    case 'prod':
      resolve = () => prod.DefaultFirebaseOptions.currentPlatform;
    default:
      throw StateError(
        "Unknown APP_ENV '$env'. Build with --dart-define=APP_ENV=dev or "
        '--dart-define=APP_ENV=prod.',
      );
  }

  try {
    return resolve();
  } on UnsupportedError catch (error) {
    throw StateError(_missingPlatformConfig(env, error));
  }
}

/// Fails an iOS release/profile build that never named its environment.
///
/// `appEnv` defaults to `dev`, and Xcode does not see `--dart-define`, so an
/// archive produced by `Product → Archive` without first running
/// `flutter build ios --config-only --release --dart-define=APP_ENV=prod` would
/// ship a release binary pointed at the dev project. Android is unaffected: its
/// flavor already picks `google-services.json`, so this guard is iOS-only.
void rejectImplicitEnvOnIos({
  required String env,
  required bool envWasProvided,
  required bool isReleaseBuild,
}) {
  if (!isReleaseBuild || envWasProvided) return;
  if (defaultTargetPlatform != TargetPlatform.iOS) return;

  throw StateError(
    'This iOS release/profile build was not given --dart-define=APP_ENV, so it '
    'fell back to the default "$env" environment. A release binary must name '
    'its Firebase project: build with --dart-define=APP_ENV=prod, and before '
    'archiving in Xcode run flutter build ios --config-only --release '
    '--dart-define=APP_ENV=prod. See docs/ENVIRONMENTS.md.',
  );
}

String _missingPlatformConfig(String env, UnsupportedError error) {
  final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
  return 'No Firebase app is configured for $platform in the "$env" '
      'environment (APP_ENV=$env): the generated firebase_options file has no '
      'entry for this platform. Registering that app is a project-owner step '
      'in the Firebase console, followed by regenerating the config — an app '
      'id cannot be invented. See docs/ENVIRONMENTS.md.\n\n$error';
}
