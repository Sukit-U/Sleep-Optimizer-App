import 'package:firebase_app_check/firebase_app_check.dart';

/// The App Check providers one build registers.
///
/// App Check proves the request comes from this app binary. The provider that
/// does that differs per platform, and only the debug provider is a stand-in
/// that anyone with the token could copy.
class AppCheckProviders {
  const AppCheckProviders({required this.android, required this.apple});

  final AndroidAppCheckProvider android;
  final AppleAppCheckProvider apple;

  /// True when either platform registers a debug provider. A build that
  /// returns true accepts tokens anyone can mint, so no released app may use it.
  bool get usesDebugProvider =>
      android is AndroidDebugProvider || apple is AppleDebugProvider;
}

/// Picks the providers for this build.
///
/// The debug provider exists only for `dev` debug builds, where the token is
/// pasted into the console once. Everything else proves the binary: Play
/// Integrity on Android, App Attest with a DeviceCheck fallback on iOS. A
/// production build gets the real providers even in debug mode, so a stray
/// `flutter run --dart-define=APP_ENV=prod` cannot test against a token it could
/// ship.
AppCheckProviders appCheckProvidersFor({
  required String env,
  required bool isDebugBuild,
}) {
  if (env == 'dev' && isDebugBuild) {
    return const AppCheckProviders(
      android: AndroidDebugProvider(),
      apple: AppleDebugProvider(),
    );
  }
  return const AppCheckProviders(
    android: AndroidPlayIntegrityProvider(),
    apple: AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
}

/// Activates App Check with the providers [appCheckProvidersFor] selects.
///
/// Call this right after [Firebase.initializeApp] and before the first
/// Firestore or Auth call, so those requests already carry a token.
Future<void> activateAppCheck({
  required String env,
  required bool isDebugBuild,
}) async {
  final providers = appCheckProvidersFor(env: env, isDebugBuild: isDebugBuild);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: providers.android,
    providerApple: providers.apple,
  );
}
