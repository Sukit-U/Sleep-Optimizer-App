import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/app/app_check.dart';

void main() {
  test('a dev debug build registers the debug providers', () {
    final providers = appCheckProvidersFor(env: 'dev', isDebugBuild: true);

    expect(providers.android, isA<AndroidDebugProvider>());
    expect(providers.apple, isA<AppleDebugProvider>());
  });

  test('no production build registers a debug provider', () {
    for (final isDebugBuild in [true, false]) {
      final providers =
          appCheckProvidersFor(env: 'prod', isDebugBuild: isDebugBuild);

      expect(
        providers.usesDebugProvider,
        isFalse,
        reason: 'a production build must never accept a copyable debug token '
            '(isDebugBuild: $isDebugBuild)',
      );
      expect(providers.android, isA<AndroidPlayIntegrityProvider>());
      expect(providers.apple,
          isA<AppleAppAttestWithDeviceCheckFallbackProvider>());
    }
  });

  test('a dev release build proves the binary, not a token', () {
    final providers = appCheckProvidersFor(env: 'dev', isDebugBuild: false);

    expect(providers.usesDebugProvider, isFalse);
    expect(providers.android, isA<AndroidPlayIntegrityProvider>());
    expect(providers.apple,
        isA<AppleAppAttestWithDeviceCheckFallbackProvider>());
  });
}
