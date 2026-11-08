import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/app/bootstrap.dart';

void main() {
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
