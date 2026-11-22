import 'package:flutter/material.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';

/// Shown when the delete batch cannot be confirmed.
const String sleepPlanDeleteUnconfirmedMessage =
    'Could not confirm the delete. Refresh the list to see what is left, then try again.';

/// Asks the user to confirm deleting a saved sleep plan.
///
/// Returns `true` only when the user explicitly confirms. Cancelling, tapping
/// outside the dialog or dismissing it with the system back gesture all count
/// as "no", so the caller must not start deleting unless this returns `true`.
Future<bool> confirmDeleteSleepPlan(BuildContext context) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.historyDialogDeletePlanTitle),
      content: Text(l10n.historyDialogDeletePlanContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.historyBtnCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.historyBtnDelete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

