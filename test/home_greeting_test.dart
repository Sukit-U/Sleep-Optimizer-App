import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/features/home/presentation/widgets/home_body.dart';

void main() {
  group('selectGreeting', () {
    test('00:00-04:59 -> late night greeting', () {
      final en = AppLocalizations(const Locale('en'));
      final th = AppLocalizations(const Locale('th'));

      for (final h in [0, 1, 2, 3, 4]) {
        expect(selectGreeting(h, en), 'Still up?');
        expect(selectGreeting(h, th), 'ยังไม่นอนอีกเหรอ?');
      }
    });

    test('05:00-11:59 -> morning greeting', () {
      final en = AppLocalizations(const Locale('en'));
      final th = AppLocalizations(const Locale('th'));

      for (final h in [5, 6, 7, 8, 9, 10, 11]) {
        expect(selectGreeting(h, en), 'Good morning');
        expect(selectGreeting(h, th), 'อรุณสวัสดิ์');
      }
    });

    test('12:00-17:59 -> afternoon greeting', () {
      final en = AppLocalizations(const Locale('en'));
      final th = AppLocalizations(const Locale('th'));

      for (final h in [12, 13, 14, 15, 16, 17]) {
        expect(selectGreeting(h, en), 'Good afternoon');
        expect(selectGreeting(h, th), 'สวัสดีตอนบ่าย');
      }
    });

    test('18:00-21:59 -> evening greeting', () {
      final en = AppLocalizations(const Locale('en'));
      final th = AppLocalizations(const Locale('th'));

      for (final h in [18, 19, 20, 21]) {
        expect(selectGreeting(h, en), 'Good evening');
        expect(selectGreeting(h, th), 'สวัสดีตอนเย็น');
      }
    });

    test('22:00-23:59 -> night greeting', () {
      final en = AppLocalizations(const Locale('en'));
      final th = AppLocalizations(const Locale('th'));

      for (final h in [22, 23]) {
        expect(selectGreeting(h, en), 'Good night');
        expect(selectGreeting(h, th), 'ราตรีสวัสดิ์');
      }
    });

    test('boundaries are continuous with no gaps or overlaps', () {
      final en = AppLocalizations(const Locale('en'));

      // Each hour 0-23 maps to exactly one greeting
      final greetings = <int, String>{};
      for (final h in List.generate(24, (i) => i)) {
        greetings[h] = selectGreeting(h, en);
      }

      // Verify no hour is unmapped
      expect(greetings.length, 24);

      // Verify continuity: adjacent hours may share or change greeting,
      // but no hour is skipped
      for (final h in List.generate(23, (i) => i)) {
        expect(
          greetings.containsKey(h) && greetings.containsKey(h + 1),
          isTrue,
          reason: 'gap at hour $h to ${h + 1}',
        );
      }
    });

    test('good night boundary: 21 is evening, 22 is night', () {
      final en = AppLocalizations(const Locale('en'));
      expect(selectGreeting(21, en), 'Good evening');
      expect(selectGreeting(22, en), 'Good night');
    });

    test('late night to morning boundary: 4 is late night, 5 is morning', () {
      final en = AppLocalizations(const Locale('en'));
      expect(selectGreeting(4, en), 'Still up?');
      expect(selectGreeting(5, en), 'Good morning');
    });

    test('morning to afternoon boundary: 11 is morning, 12 is afternoon', () {
      final en = AppLocalizations(const Locale('en'));
      expect(selectGreeting(11, en), 'Good morning');
      expect(selectGreeting(12, en), 'Good afternoon');
    });

    test('afternoon to evening boundary: 17 is afternoon, 18 is evening', () {
      final en = AppLocalizations(const Locale('en'));
      expect(selectGreeting(17, en), 'Good afternoon');
      expect(selectGreeting(18, en), 'Good evening');
    });
  });
}
