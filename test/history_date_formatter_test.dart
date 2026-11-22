import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/shared/formatters/history_date_formatter.dart';

/// Pads a number the same way `AppLocalizations.formatTime` does.
String twoDigits(int value) => value.toString().padLeft(2, '0');

void main() {
  group('formatHistoryDate', () {
    final l10n = AppLocalizations(const Locale('en'));
    final now = DateTime.now();

    test('shows today with the time for a timestamp earlier today', () {
      final dateTime = now.subtract(const Duration(minutes: 30));

      expect(
        formatHistoryDate(dateTime, l10n),
        'Today, ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}',
      );
    });

    test('shows yesterday with the time for a timestamp one day old', () {
      final dateTime = now.subtract(const Duration(hours: 25));

      expect(
        formatHistoryDate(dateTime, l10n),
        'Yesterday, ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}',
      );
    });

    test('counts the days within the last week', () {
      final dateTime = now.subtract(const Duration(days: 3));

      expect(formatHistoryDate(dateTime, l10n), '3 days ago');
      expect(
        formatHistoryDate(dateTime, AppLocalizations(const Locale('th'))),
        '3 วันที่แล้ว',
      );
    });

    test('falls back to the full date beyond a week', () {
      expect(formatHistoryDate(DateTime(2025, 1, 5, 9, 15), l10n), '5/1/2025');
    });
  });
}
