import 'package:firebase_core/firebase_core.dart';

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

/// The [FirebaseOptions] belonging to [env].
///
/// `dev` and `prod` are the only targets the generated
/// `firebase_options*.dart` files describe; anything else is a build mistake
/// and fails loudly instead of silently falling back to a real project.
FirebaseOptions firebaseOptionsForEnv(String env) {
  switch (env) {
    case 'dev':
      return dev.DefaultFirebaseOptions.currentPlatform;
    case 'prod':
      return prod.DefaultFirebaseOptions.currentPlatform;
    default:
      throw StateError(
        "Unknown APP_ENV '$env'. Build with --dart-define=APP_ENV=dev or "
        '--dart-define=APP_ENV=prod.',
      );
  }
}
