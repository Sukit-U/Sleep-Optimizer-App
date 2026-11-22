import 'package:snoozemate/core/l10n/app_localizations.dart';

/// Formats a history timestamp as a relative day label.
///
/// Shows "Today"/"Yesterday"/"N days ago" for the last week and a full date
/// beyond that.
String formatHistoryDate(DateTime dateTime, AppLocalizations l10n) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  if (difference.inDays == 0) {
    return l10n.historyDateToday(formatHistoryTime(dateTime, l10n));
  }
  if (difference.inDays == 1) {
    return l10n.historyDateYesterday(formatHistoryTime(dateTime, l10n));
  }
  if (difference.inDays < 7) {
    return l10n.historyDateDaysAgo(difference.inDays);
  }
  return l10n.formatDateFull(dateTime.day, dateTime.month, dateTime.year);
}

/// Formats the time of day for a history entry.
String formatHistoryTime(DateTime dateTime, AppLocalizations l10n) {
  return l10n.formatTime(dateTime.hour, dateTime.minute);
}
