import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/models/recommendation_model.dart';
import 'package:snoozemate/shared/widgets/recommendation_bottom_sheet.dart';

Recommendation _rec() => Recommendation(
      recommendationId: 'r-1',
      userId: 'owner-1',
      recordId: 'rec-1',
      factor: 'Caffeine',
      title: 'Cut evening caffeine',
      description: 'Avoid coffee after 2 PM.',
      action: 'Switch to herbal tea.',
      priority: 'high',
      createdAt: DateTime(2026, 11, 13, 23, 0),
    );

Future<void> _open(
  WidgetTester tester, {
  required List<Recommendation> recs,
  int unavailableCount = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showRecommendationSheet(
              context,
              recs: recs,
              unavailableCount: unavailableCount,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty batch with no unavailable records shows empty state', (tester) async {
    await _open(tester, recs: const []);
    expect(find.text('No recommendations recorded for this assessment.'), findsOneWidget);
    expect(find.text('Some recommendations could not be displayed.'), findsNothing);
  });

  testWidgets('unavailable-only batch shows unavailable notice', (tester) async {
    await _open(tester, recs: const [], unavailableCount: 2);
    expect(find.text('No recommendations recorded for this assessment.'), findsNothing);
    expect(find.text('Some recommendations could not be displayed.'), findsOneWidget);
  });

  testWidgets('valid and unavailable records coexist', (tester) async {
    await _open(tester, recs: [_rec()], unavailableCount: 1);
    expect(find.text('Cut evening caffeine'), findsOneWidget);
    expect(find.text('Some recommendations could not be displayed.'), findsOneWidget);
  });
}