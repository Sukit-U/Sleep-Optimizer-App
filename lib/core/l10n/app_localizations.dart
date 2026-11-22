import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _pick(String en, String th) => locale.languageCode == 'th' ? th : en;

  // ===== App =====
  String get appTitle => _pick('Snoozemate', 'Snoozemate');

  // ===== Navigation =====
  String get navHome => _pick('Home', 'หน้าหลัก');
  String get navPlanner => _pick('Planner', 'จัดเวลานอน');
  String get navSqi => _pick('SQI', 'คะแนน SQI');
  String get navHistory => _pick('History', 'ประวัติ');
  String get navSettings => _pick('Settings', 'ตั้งค่า');

  // ===== Quality levels =====
  String sleepQualityLevel(String level) {
    switch (level) {
      case 'excellent':
        return 'ดีเยี่ยม';
      case 'good':
        return 'ดี';
      case 'fair':
        return 'ปานกลาง';
      case 'poor':
        return 'ควรปรับปรุง';
      default:
        return level;
    }
  }

  // ===== Bedtimes =====
  String bedtimeLabel(int index) => _pick('Bedtime #$index', 'เข้านอน #$index');

  // ===== Splash =====
  String get splashTitle => _pick('Snoozemate', 'Snoozemate');
  String get splashSubtitle => _pick(
      'Work out when to go to bed tonight, based on when you need to be up.',
      'คำนวณเวลาเข้านอนคืนนี้ให้พอดีกับเวลาที่คุณต้องตื่น');
  String get splashContinue => _pick('Continue', 'เริ่มต้นกันเลย');
  String get splashDisclaimer =>
      _pick('An educational tool, not a medical device.',
          'เป็นเครื่องมือเพื่อการเรียนรู้ ไม่ใช่อุปกรณ์ทางการแพทย์');

  // ===== Home =====
  String get homeGreetingLateNight => _pick('Still up?', 'ยังไม่นอนอีกเหรอ?');
  String get homeGreetingMorning => _pick('Good morning', 'อรุณสวัสดิ์');
  String get homeGreetingAfternoon => _pick('Good afternoon', 'สวัสดีตอนบ่าย');
  String get homeGreetingEvening => _pick('Good evening', 'สวัสดีตอนเย็น');
  String get homeHeading => _pick('Home', 'หน้าหลัก');

  String get tonightCardHeading => _pick('Tonight', 'คืนนี้');
  String get tonightCardTitle => _pick('Plan tonight', 'วางแผนนอนคืนนี้');
  String get tonightCardDescription => _pick(
      'Tell us when you need to wake up.',
      'บอกเวลาที่คุณต้องตื่น เพื่อคำนวณเวลาเข้านอนที่ดีที่สุด');
  String get tonightCardButton => _pick('Open Sleep Planner', 'เปิดตัวช่วยจัดเวลานอน');

  String get featurePlannerTitle => _pick('Sleep Planner', 'จัดเวลานอน');
  String get featurePlannerDesc => _pick('Find your best bedtime', 'หาเวลานอนที่เหมาะกับคุณ');
  String get featureQualityTitle => _pick('Sleep Quality', 'เช็คคุณภาพการนอน');
  String get featureQualityDesc => _pick('Take the assessment', 'ทำแบบประเมิน');

  String get latestScoreTitle => _pick('Latest score', 'คะแนนล่าสุด');
  String get sleepQualitySubtitle => _pick('Your sleep quality', 'คุณภาพการนอนของคุณ');
  String get sleepQualityPrompt => _pick(
      'Complete your first assessment to see your sleep quality score.',
      'ทำแบบประเมินครั้งแรกเพื่อดูคะแนนคุณภาพการนอนของคุณ');
  String get viewHistory => _pick('View history', 'ดูประวัติทั้งหมด');
  String get startAssessment => _pick('Start assessment', 'เริ่มทำแบบประเมิน');

  // ===== Sleep Planner =====
  String get plannerAppBarTitle => _pick('Sleep Planner', 'จัดเวลานอน');
  String get plannerWhenShouldISleep => _pick('When should I sleep?', 'ควรนอนกี่โมงดี?');
  String get plannerWakeUpTime => _pick('Wake-up time', 'เวลาที่ต้องตื่น');
  String get plannerTimeToFallAsleep => _pick('Time to fall asleep: ', 'เวลาที่ใช้กว่าจะหลับ: ');
  String get plannerTonightIAlsoHave =>
      _pick('Tonight I also have…', 'คืนนี้มีกิจกรรมอะไรเพิ่มเติมไหม…');
  String get constraintHomework => _pick('Homework', 'การบ้าน');
  String get constraintTutoring => _pick('Tutoring', 'เรียนพิเศษ');
  String get constraintProject => _pick('Project', 'ทำโปรเจกต์ / งานกลุ่ม');
  String get constraintLateArrival => _pick('Late arrival', 'กลับบ้านดึก');
  String get constraintPersonalActivity => _pick('Personal activity', 'กิจกรรมส่วนตัว');
  String get plannerSuggestedBedtimes =>
      _pick('Suggested bedtimes', 'เวลาเข้านอนที่แนะนำ');
  String plannerWakeAt(String time) => _pick('Wake at $time', 'ตื่นเวลา $time');

  String get errSelectWakeUpTime =>
      _pick('Please select a wake-up time first.', 'กรุณาเลือกเวลาที่ต้องตื่นก่อน');
  String get errSaveLocal =>
      _pick('Could not save plan locally', 'ไม่สามารถบันทึกแผนลงเครื่องได้');
  String get msgSavedLocalOnly => _pick(
      'Saved on this device only. It was not synced to the cloud — reconnect and save to sync.',
      'บันทึกในเครื่องนี้เท่านั้น ยังไม่ได้ซิงค์ขึ้นคลาวด์ — เชื่อมต่ออินเทอร์เน็ตแล้วกดบันทึกอีกครั้งเพื่อซิงค์');
  String get msgSyncFailed => _pick(
      'Could not sync to cloud. Saved on this device — tap Retry to sync.',
      'ซิงค์ขึ้นคลาวด์ไม่สำเร็จ บันทึกไว้ในเครื่องแล้ว — แตะ “ลองใหม่” เพื่อซิงค์');

  // Planner duration / cycles
  String plannerDurationZero() => _pick('0h', '0ชม.');
  String plannerDurationH(int h) => _pick('$h h', '$h ชม.');
  String plannerDurationM(int m) => _pick('$m m', '$m นาที');
  String plannerDurationHM(int h, int m) =>
      _pick('$h h $m m', '$h ชม. $m นาที');
  String plannerCycles(int cycles) => _pick('$cycles cycles', '$cycles รอบ');
  String get plannerRecommended => _pick('Recommended', 'แนะนำ');

  // Planner save button
  String get plannerBtnSaving => _pick('Saving…', 'กำลังบันทึก…');
  String get plannerBtnSaved => _pick('Saved to history', 'บันทึกในประวัติแล้ว');
  String get plannerBtnSave => _pick('Save plan', 'บันทึกแผน');

  String get plannerLatencyMin => _pick('min', 'นาที');

  String get retry => _pick('Retry', 'ลองใหม่');

  String get dialogDiscardChangesTitle =>
      _pick('Discard changes?', 'ละทิ้งการเปลี่ยนแปลงนี้ไหม?');
  String get dialogDiscardChangesContent => _pick(
      'You have unsaved planner changes. Do you want to discard them?',
      'คุณยังไม่ได้บันทึกแผนที่แก้ ต้องการละทิ้งใช่ไหม?');
  String get dialogStay => _pick('Stay', 'อยู่ต่อ');
  String get dialogDiscard => _pick('Discard', 'ละทิ้ง');

  // ===== Sleep Quality =====
  String get sqQualityPageTitle => _pick('Sleep Quality', 'คุณภาพการนอน');
  String get sqCheckInTitle => _pick('Sleep Quality Check-In', 'เช็กคุณภาพการนอน');

  String get qSleepDuration => _pick('Sleep duration', 'ระยะเวลานอน');
  String get qSleepDurationHelper =>
      _pick('How many hours did you sleep?', 'เมื่อคืนคุณนอนไปกี่ชั่วโมง?');
  String get qSleepRegularity =>
      _pick('Sleep regularity', 'ความสม่ำเสมอของเวลาเข้านอน');
  String get qSleepRegularityHelper =>
      _pick('How consistent was your bedtime?', 'คุณเข้านอนเวลาเดิมสม่ำเสมอแค่ไหน?');
  String get qScreenTime => _pick('Screen time', 'เล่นจอก่อนนอน');
  String get qScreenTimeHelper => _pick(
      'How much screen time before bed?',
      'คุณใช้หน้าจอมือถือหรือคอมพิวเตอร์ก่อนนอนนานแค่ไหน?');
  String get qExercise => _pick('Exercise', 'การออกกำลังกาย');
  String get qExerciseHelper =>
      _pick('How active were you during the day?',
          'วันนี้คุณได้ขยับร่างกายหรือออกกำลังกายไหม?');
  String get qStress => _pick('Stress', 'ความเครียด');
  String get qStressHelper => _pick(
      'How stressed did you feel before bed?',
      'ก่อนนอนคุณรู้สึกเครียดหรือกังวลมากแค่ไหน?');
  String get qCaffeine => _pick('Caffeine', 'คาเฟอีน');
  String get qCaffeineHelper => _pick(
      'How much caffeine did you consume?',
      'วันนี้คุณดื่มชา กาแฟ หรือน้ำอัดลมที่มีคาเฟอีนแค่ไหน?');

  String get sqDialogDiscardTitle => _pick('Discard answers?', 'ลบคำตอบที่ทำไว้ไหม?');
  String get sqDialogDiscardContent => _pick(
      'You have unanswered questions. Do you want to discard your answers?',
      'คุณยังมีคำถามที่ยังไม่ได้ตอบ ต้องการละทิ้งคำตอบทั้งหมดไหม?');

  String get sqPageTitle => _pick('Sleep Quality', 'คุณภาพการนอน');
  String get sqButtonSaving => _pick('Saving…', 'กำลังบันทึก…');
  String? sqHelperLabel(String factor) =>
      locale.languageCode == 'th' ? _sqHelperTh[factor] : _sqHelperEn[factor];
  static const Map<String, String> _sqHelperEn = {
    'Sleep duration': 'How many hours did you sleep?',
    'Sleep regularity': 'How consistent was your bedtime?',
    'Screen time': 'How much screen time before bed?',
    'Exercise': 'How active were you during the day?',
    'Stress': 'How stressed did you feel before bed?',
    'Caffeine': 'How much caffeine did you consume?',
  };
  static const Map<String, String> _sqHelperTh = {
    'Sleep duration': 'คุณนอนกี่ชั่วโมง?',
    'Sleep regularity': 'เวลาเข้านอนสม่ำเสมอไหม?',
    'Screen time': 'เล่นจอก่อนนอนมากแค่ไหน?',
    'Exercise': 'วันนี้คุณเคลื่อนไหวมากแค่ไหน?',
    'Stress': 'รู้สึกเครียดก่อนนอนไหม?',
    'Caffeine': 'ดื่มคาเฟอีนมากแค่ไหน?',
  };
  String get sqButtonCalculate => _pick('Calculate SQI', 'คำนวณคะแนน SQI');
  String get sqButtonViewLastResult => _pick('View last result', 'ดูผลลัพธ์ล่าสุด');

  String get sqSnackCouldNotSaveLocal => _pick(
      'Could not save assessment locally',
      'ไม่สามารถบันทึกแบบประเมินลงเครื่องได้');
  String get sqSnackAnswerEvery => _pick(
      'Please answer every SQI question before submitting.',
      'กรุณาตอบคำถามประเมิน SQI ให้ครบทุกข้อก่อนกดส่ง');

  String get sqOfflineDialogTitle => _pick('Calculated offline', 'คำนวณแบบออฟไลน์');
  String sqOfflineDialogContent(String score, String level) => _pick(
      'Your SQI is $score ($level).\n\nIt was not saved to the cloud because there is no connection. You can retry saving or view your result now.',
      'คะแนน SQI ของคุณคือ $score ($level)\n\nยังไม่ได้บันทึกขึ้นคลาวด์เพราะไม่มีอินเทอร์เน็ต คุณสามารถลองบันทึกใหม่หรือดูผลลัพธ์ตอนนี้ได้เลย');
  String get sqOfflineViewResult => _pick('View result', 'ดูผลลัพธ์');
  String get sqOfflineRetrySave => _pick('Retry save', 'ลองบันทึกอีกครั้ง');
  String sqOfflineSnack(String score) => _pick(
      'SQI $score calculated — not saved to the cloud.',
      'คำนวณ SQI $score แล้ว — ยังไม่ได้บันทึกขึ้นคลาวด์');

  String get sqSnackSavedButRecsFailed => _pick(
      'Your assessment was saved, but its recommendations could not be confirmed. Retry to finish it.',
      'บันทึกแบบประเมินแล้ว แต่ยังโหลดคำแนะนำไม่สำเร็จ กด “ลองใหม่” เพื่อทำให้เสร็จสมบูรณ์');
  String get sqSnackCouldNotConfirm => _pick(
      'Could not confirm the save. Check History before retrying — the assessment may already be there.',
      'ยังยืนยันการบันทึกไม่ได้ ลองเช็คในหน้า “ประวัติ” ก่อนกดลองใหม่อีกครั้ง — แบบประเมินอาจจะบันทึกไปแล้ว');

  // ===== Recommendations =====
  String get recYourResult => _pick('Your result', 'ผลลัพธ์ของคุณ');
  String get recSleepQualityIndex =>
      _pick('Sleep Quality Index', 'ดัชนีคุณภาพการนอน (SQI)');
  String get recScoreSuffix => _pick('/ 100', 'จาก 100');
  String get recFactorBreakdown => _pick('Factor breakdown', 'แยกตามปัจจัย');
  String get recRecommendations => _pick('Recommendations', 'คำแนะนำสำหรับคุณ');
  String get recEmptyNeedSQI => _pick(
      'Complete your SQI to receive personalized recommendations.',
      'ทำแบบประเมิน SQI ให้เสร็จเพื่อรับคำแนะนำเฉพาะคุณ');
  String get recEmptyGreatHabits =>
      _pick('Your habits look great — keep it up!', 'นิสัยการนอนของคุณยอดเยี่ยมมาก รักษาไว้เถอะ!');
  String recPriority(String priority) => _pick('Priority $priority', 'ความสำคัญระดับ $priority');
  String recAction(String action) => _pick('Action: $action', 'สิ่งที่ควรทำ: $action');
  String recFactor(String factor) {
    if (locale.languageCode == 'th') {
      final label = recFactorLabel(factor);
      return 'ปัจจัย: ${label ?? factor}';
    }
    return 'Factor: $factor';
  }

  // Recommendation display mappings (keyed by stable factor/priority)
  static const Map<String, String> _recTitleEn = {
    'Sleep duration': 'Aim for a consistent bedtime',
    'Sleep regularity': 'Keep a steady rhythm',
    'Screen time': 'Reduce late screen exposure',
    'Exercise': 'Add light activity earlier in the day',
    'Stress': 'Create a simple wind-down routine',
    'Caffeine': 'Cut back on late caffeine',
    'General': 'Keep up the great habits!',
  };
  static const Map<String, String> _recTitleTh = {
    'Sleep duration': 'เข้านอนให้เป็นเวลา',
    'Sleep regularity': 'รักษาจังหวะการนอนให้สม่ำเสมอ',
    'Screen time': 'ลดการใช้หน้าจอก่อนนอน',
    'Exercise': 'ขยับร่างกายเบาๆ ช่วงบ่าย',
    'Stress': 'สร้างกิจวัตรผ่อนคลายก่อนนอน',
    'Caffeine': 'ลดคาเฟอีนช่วงเย็น',
    'General': 'นิสัยการนอนยอดเยี่ยม',
  };
  static const Map<String, String> _recDescEn = {
    'Sleep duration': 'A stable sleep schedule helps your body recover more efficiently.',
    'Sleep regularity': 'Regular sleep timing strengthens your sleep quality over time.',
    'Screen time': 'Blue light can delay your sleep onset and reduce night-time rest.',
    'Exercise': 'Physical activity can improve your sleep readiness and energy balance.',
    'Stress': 'A calm routine can reduce stress and support better sleep.',
    'Caffeine': 'Caffeine can stay in your system and disrupt sleep.',
    'General':
        'Your sleep habits are excellent — maintaining them will help you stay rested and perform at your best.',
  };
  static const Map<String, String> _recDescTh = {
    'Sleep duration': 'เข้านอนเวลาเดิมทุกวันช่วยให้นาฬิกาชีวิตทำงานดีขึ้น',
    'Sleep regularity': 'เวลานอนสม่ำเสมอช่วยเพิ่มคุณภาพการนอน',
    'Screen time': 'หน้าจอก่อนนอนทำให้เมลาโทนินหลั่งช้าลง',
    'Exercise': 'การขยับร่างกายเบาๆ ช่วงบ่ายช่วยให้นอนหลับลึกขึ้น',
    'Stress': 'กิจวัตรผ่อนคลายก่อนนอนช่วยลดความตื่นตัว',
    'Caffeine': 'คาเฟอีนช่วงเย็นรบกวนการเริ่มหลับ',
    'General': 'รักษาพฤติกรรมการนอนที่ดีต่อไป',
  };
  static const Map<String, String> _recActionEn = {
    'Sleep duration': 'Set a fixed bedtime and wake-up time.',
    'Sleep regularity': 'Stick to the same wake-up time each day.',
    'Screen time': 'Put your phone away 30 minutes before bed.',
    'Exercise': 'Take a short walk or stretch earlier in the day.',
    'Stress': 'Try breathing exercises or journaling before bed.',
    'Caffeine': 'Avoid caffeine at least 6 hours before bed.',
    'General': 'Continue with your current sleep routine and share your good habits with friends.',
  };
  static const Map<String, String> _recActionTh = {
    'Sleep duration': 'ตั้งเวลาเข้านอนคงที่และทำตามทุกวัน',
    'Sleep regularity': 'ตื่นเวลาเดิมทุกวัน',
    'Screen time': 'หยุดใช้หน้าจอ 1 ชั่วโมงก่อนนอน',
    'Exercise': 'เดินหรือยืดเหยียดช่วงบ่าย',
    'Stress': 'ลองหายใจลึกๆ หรืออ่านหนังสือก่อนนอน',
    'Caffeine': 'เลี่ยงคาเฟอีนหลัง 14:00 น.',
    'General': 'รักษาวิถีการนอนปัจจุบัน',
  };
  String? recPriorityLabel(String priority) =>
      locale.languageCode == 'th' ? _recPriorityTh[priority] : _recPriorityEn[priority];
  static const Map<String, String> _recPriorityEn = {
    'critical': 'Critical',
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
  };
  static const Map<String, String> _recPriorityTh = {
    'critical': 'สำคัญมาก',
    'high': 'สูง',
    'medium': 'ปานกลาง',
    'low': 'ต่ำ',
  };

  String? recTitleFor(String factor) =>
      locale.languageCode == 'th' ? _recTitleTh[factor] : _recTitleEn[factor];
  String? recDescriptionFor(String factor) =>
      locale.languageCode == 'th' ? _recDescTh[factor] : _recDescEn[factor];
  String? recActionFor(String factor) =>
      locale.languageCode == 'th' ? _recActionTh[factor] : _recActionEn[factor];
  static const Map<String, String> _recFactorEn = {
    'Sleep duration': 'Sleep duration',
    'Sleep regularity': 'Sleep regularity',
    'Screen time': 'Screen time',
    'Exercise': 'Exercise',
    'Stress': 'Stress',
    'Caffeine': 'Caffeine',
    'General': 'General',
  };
  static const Map<String, String> _recFactorTh = {
    'Sleep duration': 'ระยะเวลานอน',
    'Sleep regularity': 'ความสม่ำเสมอการนอน',
    'Screen time': 'เล่นจอก่อนนอน',
    'Exercise': 'การออกกำลังกาย',
    'Stress': 'ความเครียด',
    'Caffeine': 'คาเฟอีน',
    'General': 'ทั่วไป',
  };

  String? recFactorLabel(String factor) =>
      locale.languageCode == 'th' ? _recFactorTh[factor] : _recFactorEn[factor];

  String get recButtonHome => _pick('Home', 'หน้าหลัก');
  String get recButtonViewHistory => _pick('View history', 'ดูประวัติ');

  // Recommendation bottom sheet
  String get recBottomSheetNoneRecorded => _pick(
      'No recommendations recorded for this assessment.',
      'ยังไม่มีคำแนะนำสำหรับการประเมินนี้');
  String get recBottomSheetSomeUnavailable => _pick(
      'Some recommendations could not be displayed.',
      'แสดงคำแนะนำบางรายการไม่สำเร็จ');

  // ===== History =====
  String get historyLoadFailed => _pick('Failed to load history', 'โหลดประวัติไม่สำเร็จ');

  String get historySignInFailed =>
      _pick('Could not sign in. Showing local plans only.',
          'ไม่สามารถเข้าสู่ระบบได้ แสดงเฉพาะแผนในเครื่องเท่านั้น');

  String get historyPageTitle => _pick('History', 'ประวัติ');
  String get historyTabSqi => _pick('SQI records', 'ประวัติ SQI');
  String get historyTabPlans => _pick('Sleep plans', 'แผนการนอน');

  String get historyEmptySqiLabel => _pick('No assessments yet.', 'ยังไม่มีประวัติการประเมิน');
  String get historyEmptySqiCta => _pick('Take assessment', 'ทำแบบประเมิน');
  String get historyEmptyPlansLabel =>
      _pick('No plans saved yet.', 'ยังไม่มีแผนการนอนที่บันทึกไว้');
  String get historyEmptyPlansCta => _pick('Open planner', 'เปิดตัวช่วยจัดเวลานอน');

  String historyUnreadableRecords(String count) => _pick(
      '$count record(s) could not be read and are hidden.',
      'ไม่สามารถอ่านข้อมูล $count รายการได้ จึงถูกซ่อนไว้');
  String historyUnreadablePlans(String count) => _pick(
      '$count plan(s) could not be read and are hidden.',
      'ไม่สามารถอ่านแผน $count รายการได้ จึงถูกซ่อนไว้');

  String get historyLegacyRecord => _pick('legacy record', 'ข้อมูลเดิม');
  String get historyQualityUnavailable => _pick('quality level unavailable', 'ไม่พบระดับคุณภาพ');
  String get historyQuestionnaireUnavailable => _pick(
      'Questionnaire details unavailable for this record.',
      'ไม่พบรายละเอียดแบบประเมินสำหรับรายการนี้');
  String get historyBedtimeUnavailable => _pick('bedtime unavailable', 'ไม่ระบุเวลานอน');
  String get historyDateUnavailable => _pick('date unavailable', 'ไม่ระบุวันที่');

  String historyDateToday(String time) => _pick('Today, $time', 'วันนี้, $time');
  String historyDateYesterday(String time) => _pick('Yesterday, $time', 'เมื่อวานนี้, $time');
  String historyDateDaysAgo(int days) => _pick('$days days ago', '$days วันที่แล้ว');

  // ===== Date / Time formatting (Thai) =====
  String formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  String formatDateFull(int day, int month, int year) =>
      '$day/$month/$year';

  String get historyDialogDeleteSqiTitle =>
      _pick('Delete this assessment?', 'ลบแบบประเมินนี้ไหม?');
  String get historyDialogDeleteSqiContent => _pick(
      'This deletes the assessment and every recommendation that belongs to it. It cannot be undone.',
      'การกระทำนี้จะลบแบบประเมินและคำแนะนำทั้งหมดที่เกี่ยวข้อง และไม่สามารถกู้คืนได้');
  String get historyDialogDeletePlanTitle =>
      _pick('Delete this plan?', 'ลบแผนการนอนนี้ไหม?');
  String get historyDialogDeletePlanContent => _pick(
      'This removes the plan from your history. It cannot be undone.',
      'การกระทำนี้จะลบแผนออกจากประวัติของคุณ และไม่สามารถกู้คืนได้');
  String get historyBtnCancel => _pick('Cancel', 'ยกเลิก');
  String get historyBtnDelete => _pick('Delete', 'ลบ');

  String get historySnackDeleteUnconfirmed => _pick(
      'Could not confirm the delete. Refresh the list to see what is left, then try again.',
      'ยืนยันการลบไม่สำเร็จ รีเฟรชรายการเพื่อดูว่าเหลืออะไรบ้าง แล้วลองใหม่อีกครั้ง');
  String get historySnackSignInFailed => _pick(
      'Could not sign in. Check your connection and try again.',
      'ไม่สามารถเข้าสู่ระบบได้ ตรวจสอบการเชื่อมต่อแล้วลองใหม่อีกครั้ง');
  String get historySnackCouldNotLoadRecs =>
      _pick('Could not load recommendations.', 'ไม่สามารถโหลดคำแนะนำได้');
  String historySnackDeleteLocalFailed(String error) => _pick(
      'Could not delete local plan: $error',
      'ไม่สามารถลบแผนในเครื่อง: $error');
  String historySnackPlanDeletedCloud(String error) => _pick(
      'Plan deleted from cloud. Local cleanup failed: $error',
      'ลบแผนจากคลาวด์แล้ว ทำความสะอาดเครื่องล้มเหลว: $error');

  // ===== Settings =====
  String get settingsPageTitle => _pick('Settings', 'ตั้งค่า');
  String get settingsThemeSection => _pick('Theme', 'ธีม');
  String get settingsDarkModeTitle => _pick('Dark theme', 'ธีมมืด');
  String get settingsDarkModeDesc =>
      _pick('Use dark theme for display', 'ใช้ธีมสีเข้มในการแสดงผล');
  String get settingsThemeSavedLocal => _pick(
      'Theme saved on this device only (offline).',
      'บันทึกธีมในเครื่องนี้เท่านั้น (ออฟไลน์)');

  String get settingsCloudError => _pick(
      'Could not connect to the cloud. Please try again.',
      'เชื่อมต่อคลาวด์ไม่ได้ โปรดลองใหม่อีกครั้ง');

  String get settingsCloudSyncTitle => _pick('Cloud sync', 'การซิงค์ข้อมูลคลาวด์');
  String get statusConnected => _pick('Connected', 'เชื่อมต่อแล้ว');
  String get statusConnecting => _pick('Connecting…', 'กำลังเชื่อมต่อ…');
  String get statusNotConnected => _pick('Not connected', 'ยังไม่เชื่อมต่อ');
  String get statusUnavailable => _pick('Unavailable', 'ไม่พร้อมใช้งาน');
  String get statusFirebaseReadyAppCheckPending => _pick(
      'Firebase ready, App Check pending', 'Firebase พร้อมแล้ว, รอตรวจสอบ App Check');
  String get statusCloudReadySignInPending => _pick(
      'Cloud ready, sign-in pending', 'คลาวด์พร้อมแล้ว, รอเข้าสู่ระบบ');

  String get settingsAboutTitle => _pick('About', 'เกี่ยวกับแอป');
  String get settingsAboutDesc => _pick(
       'Snoozemate helps students improve sleep habits through a planner, SQI, and personalized guidance.',
       'Snoozemate ช่วยให้นักเรียนพัฒนาพฤติกรรมการนอนผ่านตัวช่วยจัดเวลานอน แบบประเมิน SQI และคำแนะนำเฉพาะบุคคล');

  String get settingsBtnRetry => _pick('Retry', 'ลองใหม่');

  // ===== Shared / Errors =====
   String get errBootFailed => _pick("Snoozemate couldn't start", "Snoozemate เริ่มต้นไม่ได้");
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en' || locale.languageCode == 'th';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension L10n on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizations(const Locale('en'));
}

