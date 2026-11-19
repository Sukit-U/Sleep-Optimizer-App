import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/app/app.dart';
import 'package:snoozemate/app/bootstrap.dart';
import 'package:snoozemate/core/services/auth_service.dart';

/// The real [AuthService] must construct without a live Firebase app, because
/// the bootstrap now builds it before the (optional) cloud step.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bootDependencies returns local deps when cloud init throws (offline)',
    () async {
      SharedPreferences.setMockInitialValues({});

      final deps = await bootDependencies(
        createAuthService: AuthService.new,
        initializeCloud: (_) async => throw Exception('offline'),
      );

      expect(deps.authService, isNotNull);
      expect(deps.themeProvider, isNotNull);
      expect(
        appStorage,
        isNotNull,
        reason: 'local storage must be ready offline',
      );
      // No Firebase => no signed-in user, but the app still boots.
      expect(deps.authService.uid, isNull);
    },
  );

  test('bootDependencies runs the cloud step when it succeeds', () async {
    SharedPreferences.setMockInitialValues({});
    var cloudRan = false;

    final deps = await bootDependencies(
      createAuthService: AuthService.new,
      initializeCloud: (_) async => cloudRan = true,
    );

    expect(
      cloudRan,
      isTrue,
      reason: 'the cloud step must still run when online',
    );
    expect(deps.authService, isNotNull);
  });

  test('local state survives a cloud failure (theme still loads)', () async {
    SharedPreferences.setMockInitialValues({'theme': 'light'});

    await bootDependencies(
      createAuthService: AuthService.new,
      initializeCloud: (_) async => throw Exception('no connection'),
    );

    expect(appStorage, isNotNull);
    expect(appStorage!.loadTheme(), 'light');
  });
}
