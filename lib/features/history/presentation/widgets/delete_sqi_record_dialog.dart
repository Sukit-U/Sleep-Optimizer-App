import 'package:flutter/material.dart';

/// Shown when the delete batch cannot be confirmed.
///
/// Deliberately avoids claiming that nothing was removed: a commit whose
/// response never arrived may still have been applied, so the honest
/// instruction is to refresh the list and look before retrying.
const String sqiDeleteUnconfirmedMessage =
    'Could not confirm the delete. Refresh the list to see what is left, then try again.';

/// Asks the user to confirm deleting an SQI assessment together with every
/// recommendation that belongs to it.
///
/// Returns `true` only when the user explicitly confirms. Cancelling, tapping
/// outside the dialog or dismissing it with the system back gesture all count
/// as "no", so the caller must not start deleting unless this returns `true`.
Future<bool> confirmDeleteSqiRecord(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete this assessment?'),
      content: const Text(
        'This deletes the assessment and every recommendation that belongs to it. '
        'It cannot be undone.',
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
