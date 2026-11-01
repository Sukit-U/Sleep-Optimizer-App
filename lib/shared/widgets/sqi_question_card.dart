import 'package:flutter/material.dart';

/// A question card for the Sleep Quality Index assessment.
///
/// Shows a question label, helper text, and 5 choice chips for rating.
class SQIQuestionCard extends StatelessWidget {
  final String label;
  final String helper;
  final int? selectedValue;
  final bool hasError;
  final ValueChanged<int>? onSelected;

  const SQIQuestionCard({
    super.key,
    required this.label,
    required this.helper,
    this.selectedValue,
    this.hasError = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasError
            ? BorderSide(color: colors.error, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(helper, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(5, (index) {
                final value = index + 1;
                final selected = selectedValue == value;
                return ChoiceChip(
                  label: Text('$value'),
                  selected: selected,
                  onSelected: onSelected != null ? (_) => onSelected!(value) : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
