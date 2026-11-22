import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
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

Recommendation _recFor(String factor, String priority) => Recommendation(
  recommendationId: 'r-1',
  userId: 'owner-1',
  recordId: 'rec-1',
  factor: factor,
  title: 'title',
  description: 'desc',
  action: 'action',
  priority: priority,
  createdAt: DateTime(2026, 11, 13, 23, 0),
);

const _factors = <String>[
  'Sleep duration',
  'Sleep regularity',
  'Screen time',
  'Exercise',
  'Stress',
  'Caffeine',
  'General',
];

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
  testWidgets('empty batch with no unavailable records shows empty state', (
    tester,
  ) async {
    await _open(tester, recs: const []);
    expect(
      find.text('No recommendations recorded for this assessment.'),
      findsOneWidget,
    );
    expect(
      find.text('Some recommendations could not be displayed.'),
      findsNothing,
    );
  });

  testWidgets('unavailable-only batch shows unavailable notice', (
    tester,
  ) async {
    await _open(tester, recs: const [], unavailableCount: 2);
    expect(
      find.text('No recommendations recorded for this assessment.'),
      findsNothing,
    );
    expect(
      find.text('Some recommendations could not be displayed.'),
      findsOneWidget,
    );
  });

  testWidgets('valid and unavailable records coexist', (tester) async {
    await _open(tester, recs: [_rec()], unavailableCount: 1);
    expect(find.text('Cut back on late caffeine'), findsOneWidget);
    expect(
      find.text('Some recommendations could not be displayed.'),
      findsOneWidget,
    );
  });

  testWidgets('all seven known factors render localized labels', (
    tester,
  ) async {
    for (final factor in _factors) {
      await _open(tester, recs: [_recFor(factor, 'high')]);
      final l10n = AppLocalizations(const Locale('en'));
      expect(find.text(l10n.recFactorLabel(factor)!), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('unknown factor falls back to Thai generic label', (
    tester,
  ) async {
    await _open(tester, recs: [_recFor('UnknownFactor', 'high')]);
    expect(find.text('ปัจจัย'), findsOneWidget);
  });

  testWidgets('unknown priority falls back to Thai generic label', (
    tester,
  ) async {
    await _open(tester, recs: [_recFor('Caffeine', 'bogus')]);
    expect(find.text('ความสำคัญ'), findsOneWidget);
  });
}
