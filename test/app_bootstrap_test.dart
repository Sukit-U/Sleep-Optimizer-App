import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/app/bootstrap.dart';

void main() {
  testWidgets('shows progress while booting, never the error screen',
      (tester) async {
    final boot = Completer<AppDependencies>();

    await tester.pumpWidget(AppBootstrap(boot: () => boot.future));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Snoozefriend couldn't start"), findsNothing);

    // A boot that never finishes must keep showing progress, not an error.
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    boot.completeError(Exception('firebase exploded'));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text("Snoozefriend couldn't start"), findsOneWidget);
    expect(find.textContaining('firebase exploded'), findsOneWidget);
  });

  testWidgets('a failed boot shows the error screen and Retry runs boot again',
      (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      AppBootstrap(
        boot: () async {
          attempts++;
          throw Exception('firebase exploded');
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Snoozefriend couldn't start"), findsOneWidget);
    expect(find.textContaining('firebase exploded'), findsOneWidget);
    expect(attempts, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
  });
}
