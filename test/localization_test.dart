import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/core/providers/locale_provider.dart';
import 'package:snoozemate/core/services/storage_service.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

void main() {
  group('LocaleProvider', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late LocaleProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      provider = LocaleProvider(storageService: storage);
      await provider.loadLocale();
    });

    test('defaults to Thai on first launch', () {
      expect(provider.locale, const Locale('th'));
    });

    test('ignores persisted locale and stays Thai', () async {
      await provider.setLocale('en');
      final reloaded = LocaleProvider(storageService: storage);
      await reloaded.loadLocale();
      expect(reloaded.locale, const Locale('th'));
    });

    test('setLocale keeps Thai and notifies', () async {
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setLocale('en');

      expect(provider.locale, const Locale('th'));
      expect(notified, isTrue);
    });

    test('falls back to Thai for any locale code', () async {
      await provider.setLocale('xx');
      expect(provider.locale, const Locale('th'));
    });
  });

  group('AppLocalizations dictionary', () {
    test('returns English strings for en locale', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.appTitle, 'Snoozemate');
      expect(l10n.navHome, 'Home');
      expect(l10n.navPlanner, 'Planner');
      expect(l10n.navSqi, 'SQI');
      expect(l10n.navHistory, 'History');
      expect(l10n.navSettings, 'Settings');
      expect(l10n.sqQualityPageTitle, 'Sleep Quality');
      expect(l10n.sqButtonCalculate, 'Calculate SQI');
      expect(l10n.settingsPageTitle, 'Settings');
      expect(l10n.historyPageTitle, 'History');
      expect(l10n.recYourResult, 'Your result');
      expect(l10n.plannerAppBarTitle, 'Sleep Planner');
      expect(l10n.constraintLateArrival, 'Late arrival');
      expect(l10n.sleepQualityLevel('excellent'), 'ดีเยี่ยม');
      expect(l10n.sleepQualityLevel('good'), 'ดี');
      expect(l10n.sleepQualityLevel('fair'), 'ปานกลาง');
      expect(l10n.sleepQualityLevel('poor'), 'ควรปรับปรุง');
      expect(
        l10n.historySignInFailed,
        'Could not sign in. Showing local plans only.',
      );
      expect(
        l10n.settingsCloudError,
        'Could not connect to the cloud. Please try again.',
      );
    });

    test('returns Thai strings for th locale', () {
      final l10n = AppLocalizations(const Locale('th'));
      expect(l10n.appTitle, 'Snoozemate');
      expect(l10n.navHome, 'หน้าหลัก');
      expect(l10n.navPlanner, 'จัดเวลานอน');
      expect(l10n.navSqi, 'คะแนน SQI');
      expect(l10n.navHistory, 'ประวัติ');
      expect(l10n.navSettings, 'ตั้งค่า');
      expect(l10n.sqQualityPageTitle, 'คุณภาพการนอน');
      expect(l10n.sqButtonCalculate, 'คำนวณคะแนน SQI');
      expect(l10n.settingsPageTitle, 'ตั้งค่า');
      expect(l10n.historyPageTitle, 'ประวัติ');
      expect(l10n.recYourResult, 'ผลลัพธ์ของคุณ');
      expect(l10n.plannerAppBarTitle, 'จัดเวลานอน');
      expect(l10n.constraintLateArrival, 'กลับบ้านดึก');
      expect(l10n.sleepQualityLevel('excellent'), 'ดีเยี่ยม');
      expect(l10n.sleepQualityLevel('good'), 'ดี');
      expect(l10n.sleepQualityLevel('fair'), 'ปานกลาง');
      expect(l10n.sleepQualityLevel('poor'), 'ควรปรับปรุง');
      expect(
        l10n.historySignInFailed,
        'ไม่สามารถเข้าสู่ระบบได้ แสดงเฉพาะแผนในเครื่องเท่านั้น',
      );
      expect(
        l10n.settingsCloudError,
        'เชื่อมต่อคลาวด์ไม่ได้ โปรดลองใหม่อีกครั้ง',
      );
    });

    test('bedtime label is translated', () {
      final en = AppLocalizations(const Locale('en'));
      final th = AppLocalizations(const Locale('th'));

      expect(en.bedtimeLabel(1), 'Bedtime #1');
      expect(th.bedtimeLabel(1), 'เข้านอน #1');
      expect(en.bedtimeLabel(3), 'Bedtime #3');
      expect(th.bedtimeLabel(3), 'เข้านอน #3');
    });

    test('date/time formatting is Thai for th locale', () {
      final en = AppLocalizations(const Locale('en'));
      final th = AppLocalizations(const Locale('th'));

      expect(en.formatTime(19, 30), '19:30');
      expect(th.formatTime(19, 30), '19:30');
      expect(en.formatDateFull(13, 11, 2026), '13/11/2026');
      expect(th.formatDateFull(13, 11, 2026), '13/11/2026');
    });

    test('parameterized methods interpolate correctly', () {
      final en = AppLocalizations(const Locale('en'));
      final th = AppLocalizations(const Locale('th'));

      expect(en.plannerWakeAt('06:30'), 'Wake at 06:30');
      expect(th.plannerWakeAt('06:30'), 'ตื่นเวลา 06:30');

      expect(en.recPriority('1'), 'Priority 1');
      expect(th.recPriority('1'), 'ความสำคัญระดับ 1');

      expect(en.sqOfflineDialogContent('85', 'excellent').contains('85'), true);
      expect(th.sqOfflineDialogContent('85', 'ดีมาก').contains('85'), true);
    });

    test('offline dialog content contains newline separator', () {
      final l10n = AppLocalizations(const Locale('en'));
      final content = l10n.sqOfflineDialogContent('50', 'fair');
      expect(content.contains('\n\n'), true);
    });

    test('recommendation title mappings are translated for th locale', () {
      final th = AppLocalizations(const Locale('th'));
      expect(th.recTitleFor('Sleep duration'), 'เข้านอนให้เป็นเวลา');
      expect(
        th.recTitleFor('Sleep regularity'),
        'รักษาจังหวะการนอนให้สม่ำเสมอ',
      );
      expect(th.recTitleFor('Screen time'), 'ลดการใช้หน้าจอก่อนนอน');
      expect(th.recTitleFor('Exercise'), 'ขยับร่างกายเบาๆ ช่วงบ่าย');
      expect(th.recTitleFor('Stress'), 'สร้างกิจวัตรผ่อนคลายก่อนนอน');
      expect(th.recTitleFor('Caffeine'), 'ลดคาเฟอีนช่วงเย็น');
      expect(th.recTitleFor('General'), 'นิสัยการนอนยอดเยี่ยม');
    });

    test(
      'recommendation description mappings are translated for th locale',
      () {
        final th = AppLocalizations(const Locale('th'));
        expect(
          th.recDescriptionFor('Sleep duration'),
          'เข้านอนเวลาเดิมทุกวันช่วยให้นาฬิกาชีวิตทำงานดีขึ้น',
        );
        expect(
          th.recDescriptionFor('Screen time'),
          'หน้าจอก่อนนอนทำให้เมลาโทนินหลั่งช้าลง',
        );
        expect(
          th.recDescriptionFor('Caffeine'),
          'คาเฟอีนช่วงเย็นรบกวนการเริ่มหลับ',
        );
        expect(
          th.recDescriptionFor('General'),
          'รักษาพฤติกรรมการนอนที่ดีต่อไป',
        );
      },
    );

    test('recommendation action mappings are translated for th locale', () {
      final th = AppLocalizations(const Locale('th'));
      expect(
        th.recActionFor('Sleep duration'),
        'ตั้งเวลาเข้านอนคงที่และทำตามทุกวัน',
      );
      expect(th.recActionFor('Screen time'), 'หยุดใช้หน้าจอ 1 ชั่วโมงก่อนนอน');
      expect(th.recActionFor('Caffeine'), 'เลี่ยงคาเฟอีนหลัง 14:00 น.');
      expect(th.recActionFor('General'), 'รักษาวิถีการนอนปัจจุบัน');
    });

    test('recommendation priority labels are translated for th locale', () {
      final th = AppLocalizations(const Locale('th'));
      expect(th.recPriorityLabel('critical'), 'สำคัญมาก');
      expect(th.recPriorityLabel('high'), 'สูง');
      expect(th.recPriorityLabel('medium'), 'ปานกลาง');
      expect(th.recPriorityLabel('low'), 'ต่ำ');
    });

    test('recommendation factor labels are translated for th locale', () {
      final th = AppLocalizations(const Locale('th'));
      expect(th.recFactorLabel('Sleep duration'), 'ระยะเวลานอน');
      expect(th.recFactorLabel('Sleep regularity'), 'ความสม่ำเสมอการนอน');
      expect(th.recFactorLabel('Screen time'), 'เล่นจอก่อนนอน');
      expect(th.recFactorLabel('Exercise'), 'การออกกำลังกาย');
      expect(th.recFactorLabel('Stress'), 'ความเครียด');
      expect(th.recFactorLabel('Caffeine'), 'คาเฟอีน');
      expect(th.recFactorLabel('General'), 'ทั่วไป');
    });

    test('sqHelperLabel returns Thai for th locale', () {
      final th = AppLocalizations(const Locale('th'));
      expect(th.sqHelperLabel('Sleep duration'), 'คุณนอนกี่ชั่วโมง?');
      expect(th.sqHelperLabel('Screen time'), 'เล่นจอก่อนนอนมากแค่ไหน?');
      expect(th.sqHelperLabel('Caffeine'), 'ดื่มคาเฟอีนมากแค่ไหน?');
    });

    test('recFactor returns Thai label for th locale', () {
      final th = AppLocalizations(const Locale('th'));
      expect(th.recFactor('Sleep duration'), 'ปัจจัย: ระยะเวลานอน');
      expect(th.recFactor('Caffeine'), 'ปัจจัย: คาเฟอีน');
    });

    test('recAction prefixes action with Thai label', () {
      final th = AppLocalizations(const Locale('th'));
      expect(
        th.recAction('ดื่มน้ำเปล่ามากขึ้น'),
        'สิ่งที่ควรทำ: ดื่มน้ำเปล่ามากขึ้น',
      );
    });

    test('recPriority prefixes priority with Thai label', () {
      final th = AppLocalizations(const Locale('th'));
      expect(th.recPriority('สูง'), 'ความสำคัญระดับ สูง');
    });

    test('offline dialog content uses translated quality level', () {
      final th = AppLocalizations(const Locale('th'));
      final content = th.sqOfflineDialogContent('85', 'ดีมาก');
      expect(content.contains('85'), true);
      expect(content.contains('ดีมาก'), true);
    });

    test('no English user-facing strings leak for th locale', () {
      final th = AppLocalizations(const Locale('th'));

      // Navigation
      expect(th.navHome, isNot(equals('Home')));
      expect(th.navPlanner, isNot(equals('Planner')));
      expect(th.navSqi, isNot(equals('SQI')));
      expect(th.navHistory, isNot(equals('History')));
      expect(th.navSettings, isNot(equals('Settings')));

      // Home
      expect(th.homeGreetingLateNight, isNot(equals('Still up?')));
      expect(th.homeGreetingMorning, isNot(equals('Good morning')));
      expect(th.homeHeading, isNot(equals('Home')));

      // Planner
      expect(th.plannerAppBarTitle, isNot(equals('Sleep Planner')));
      expect(th.plannerSuggestedBedtimes, isNot(equals('Suggested bedtimes')));
      expect(
        th.errSelectWakeUpTime,
        isNot(equals('Please select a wake-up time first.')),
      );

      // Sleep Quality
      expect(th.sqPageTitle, isNot(equals('Sleep Quality')));
      expect(th.sqButtonCalculate, isNot(equals('Calculate SQI')));
      expect(th.sqButtonViewLastResult, isNot(equals('View last result')));

      // Recommendations
      expect(th.recYourResult, isNot(equals('Your result')));
      expect(th.recSleepQualityIndex, isNot(equals('Sleep Quality Index')));
      expect(th.recScoreSuffix, isNot(equals('/ 100')));
      expect(th.recFactorBreakdown, isNot(equals('Factor breakdown')));
      expect(th.recRecommendations, isNot(equals('Recommendations')));
      expect(
        th.recEmptyNeedSQI,
        isNot(
          equals('Complete your SQI to receive personalized recommendations.'),
        ),
      );
      expect(
        th.recEmptyGreatHabits,
        isNot(equals('Your habits look great — keep it up!')),
      );

      // History
      expect(th.historyPageTitle, isNot(equals('History')));
      expect(th.historyTabSqi, isNot(equals('SQI records')));
      expect(th.historyTabPlans, isNot(equals('Sleep plans')));

      // Settings
      expect(th.settingsPageTitle, isNot(equals('Settings')));
      expect(th.settingsThemeSection, isNot(equals('Theme')));
      expect(th.settingsDarkModeTitle, isNot(equals('Dark theme')));
    });
  });

  group('AppTypography', () {
    test('uses Kanit as the default font family', () {
      expect(AppTypography.fontFamilyHeader, 'Kanit');
      expect(AppTypography.fontFamilyBody, 'Kanit');
      expect(AppTypography.fontFamilyHeaderFallback, contains('Kanit'));
      expect(AppTypography.fontFamilyBodyFallback, contains('Kanit'));
    });

    test('all text styles use Kanit font family', () {
      expect(AppTypography.displayLarge.fontFamily, 'Kanit');
      expect(AppTypography.h1.fontFamily, 'Kanit');
      expect(AppTypography.h2.fontFamily, 'Kanit');
      expect(AppTypography.body.fontFamily, 'Kanit');
      expect(AppTypography.button.fontFamily, 'Kanit');
      expect(AppTypography.caption.fontFamily, 'Kanit');
      expect(AppTypography.navLabel.fontFamily, 'Kanit');
      expect(AppTypography.tabLabel.fontFamily, 'Kanit');
    });
  });
}
