import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A full-width save button for the sleep planner.
///
/// Shows a bookmark icon by default, or a checkmark when [saved] is true.
/// While [saving] is true the label reads "Saving…" and the button is dead.
class PlannerSaveButton extends StatelessWidget {
  final bool saved;
  final bool saving;
  final VoidCallback? onPressed;

  const PlannerSaveButton({
    super.key,
    this.saved = false,
    this.saving = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = saving
        ? 'Saving…'
        : saved
        ? 'Saved to history'
        : 'Save plan';
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: saving ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.60),
                blurRadius: 30,
                spreadRadius: -12,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                saved ? Icons.check : Icons.bookmark,
                size: 18,
                color: colors.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
