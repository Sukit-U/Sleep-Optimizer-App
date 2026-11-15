import 'package:flutter/material.dart';

/// Shown when a sleep plan delete cannot be confirmed.
///
/// Same reasoning as the SQI message: a request whose reply never arrived may
/// still have been applied, so the honest instruction is to refresh the list
/// and look before trying again.
const String sleepPlanDeleteUnconfirmedMessage =
    'Could not confirm the delete. Refresh the list to see what is left, then try again.';

/// Asks the user to confirm deleting a saved sleep plan.
///
/// Returns `true` only when the user explicitly confirms. Cancelling, tapping
/// outside the dialog or dismissing it with the system back gesture all count
/// as "no", so the caller must not start deleting unless this returns `true`.
Future<bool> confirmDeleteSleepPlan(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete this plan?'),
      content: const Text(
        'This removes the plan from your history. It cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
