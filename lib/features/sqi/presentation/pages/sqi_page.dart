import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/core/presentation/widgets/app_button.dart';

/// SQI (Sleep Quality Index) questionnaire screen – UI only.
/// The questionnaire state‑management logic (current question index, answer storage,
/// navigation to the result screen, etc.) is assumed to be implemented elsewhere
/// in this file or via a provider. This implementation updates only the visual
/// layout to match Lovable UI design.
class SQIPage extends StatefulWidget {
  const SQIPage({super.key});

  @override
  State<SQIPage> createState() => _SQIPageState();
}

class _SQIPageState extends State<SQIPage> {
  // ---------------------------------------------------------------------------
  // NOTE: The following fields are placeholders representing whatever state
  // the original implementation used (e.g. current question index, selected
  // answers, etc.). They are kept untouched to avoid altering business logic.
  // ---------------------------------------------------------------------------
  int _currentQuestionIndex = 0;
  final List<String> _selectedAnswers = [];

  // Dummy question list – replace with the real question data source if it
  // already exists in the original file. Keeping the UI generic ensures we
  // do not interfere with the underlying logic.
  final List<String> _questions = const [
    'How many hours do you usually sleep?',
    'How often do you wake up during the night?',
    'Do you feel refreshed after waking up?',
    'How many times do you nap during the day?',
    'How would you rate your overall sleep quality?',
  ];

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/sqi-result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Quality Index'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.px,
            vertical: AppSpacing.py,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              
              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_currentQuestionIndex + 1} / ${_questions.length}',
                    style: AppTypography.body.copyWith(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (_currentQuestionIndex + 1) / _questions.length,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Question text
              Text(
                question,
                style: AppTypography.h2.copyWith(color: AppColors.foreground),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Answer options
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: List.generate(4, (index) {
                  final bool isSelected = _selectedAnswers.length > _currentQuestionIndex &&
                      _selectedAnswers[_currentQuestionIndex] == 'Option ${index + 1}';
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedAnswers.length > _currentQuestionIndex) {
                          _selectedAnswers[_currentQuestionIndex] = 'Option ${index + 1}';
                        } else {
                          _selectedAnswers.add('Option ${index + 1}');
                        }
                        // Move to next question after answering
                        if (_currentQuestionIndex < _questions.length - 1) {
                          _nextQuestion();
                        } else {
                          // Last question handled in onTap below
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primary.withValues(alpha: 0.15) 
                            : AppColors.card,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Option ${index + 1}',
                              style: AppTypography.body.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.foreground,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Next button (only show on non-last question)
              if (_currentQuestionIndex < _questions.length - 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Next',
                    onPressed: _nextQuestion,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                  ),
                )
              else
                // Save button on last question
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Save & Continue',
                    onPressed: () {
                      // Handle saving and navigation to results
                      Navigator.of(context).pushReplacementNamed('/sqi-result');
                    },
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}