import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/core/theme/app_theme.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

void main() {
  test('default typography uses Kanit', () {
    expect(AppTypography.fontFamilyHeader, 'Kanit');
    expect(AppTypography.fontFamilyBody, 'Kanit');
    expect(
      AppTheme.lightTheme.textTheme.bodyMedium?.fontFamily,
      contains('Kanit'),
    );
  });

  testWidgets('About page displays Snoozemate and not transliteration', (
    tester,
  ) async {
    final l10n = AppLocalizations(const Locale('th'));
    expect(l10n.settingsAboutDesc, contains('Snoozemate'));
    expect(l10n.settingsAboutDesc, isNot(contains('ซูซูเมท')));
  });
}
