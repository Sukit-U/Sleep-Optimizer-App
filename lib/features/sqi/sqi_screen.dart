import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'models/sqi_models.dart';
import 'presentation/pages/sqi_result_page.dart';

class SQIScreen extends StatefulWidget {
  final String userId;

  const SQIScreen({super.key, required this.userId});

  @override
  State<SQIScreen> createState() => _SQIScreenState();
}

class _SQIScreenState extends State<SQIScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  // Questionnaire responses
  int _sleepDuration = 0;
  int _sleepRegularity = 0;
  int _screenTime = 0;
  int _exercise = 0;
  int _stress = 0;
  int _caffeine = 0;

  // Question texts
  final List<String> _sleepDurationQuestions = [
    'How many hours do you usually sleep on school nights?',
    'Less than 6 hours',
    '6-7 hours',
    '7-8 hours',
    '8-9 hours',
    'More than 9 hours'
  ];

  final List<String> _sleepRegularityQuestions = [
    'How consistent is your sleep schedule?',
    'Very irregular (bedtime varies by more than 2 hours)',
    'Somewhat irregular (bedtime varies by 1-2 hours)',
    'Fairly consistent (bedtime varies by less than 1 hour)',
    'Very consistent (same bedtime every night)'
  ];

  final List<String> _screenTimeQuestions = [
    'How often do you use electronic devices (phone, tablet, computer) within 1 hour before bed?',
    'Almost always',
    'Often',
    'Sometimes',
    'Rarely',
    'Never'
  ];

  final List<String> _exerciseQuestions = [
    'How often do you engage in physical activity or exercise?',
    'Rarely or never',
    '1-2 times per week',
    '3-4 times per week',
    '5-6 times per week',
    'Daily'
  ];

  final List<String> _stressQuestions = [
    'How would you rate your stress level before bed?',
    'Very high',
    'High',
    'Moderate',
    'Low',
    'Very low'
  ];

  final List<String> _caffeineQuestions = [
    'How often do you consume caffeine (coffee, tea, energy drinks, soda) after 3 PM?',
    'Daily',
    '4-6 times per week',
    '2-3 times per week',
    'Once a week or less',
    'Never'
  ];

  Future<void> _submitQuestionnaire() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Calculate SQI score (simplified calculation for now)
    final totalScore = _sleepDuration + _sleepRegularity + _screenTime + _exercise + _stress + _caffeine;
    final sqiScore = (totalScore / 24 * 100).round(); // 24 is max possible score

    // Determine sleep quality level
    String sleepQualityLevel;
    if (sqiScore >= 80) {
      sleepQualityLevel = 'Excellent';
    } else if (sqiScore >= 60) {
      sleepQualityLevel = 'Good';
    } else if (sqiScore >= 40) {
      sleepQualityLevel = 'Fair';
    } else {
      sleepQualityLevel = 'Poor';
    }

    // Create questionnaire responses map
    final questionnaireResponses = {
      'sleepDuration': _sleepDurationQuestions[_sleepDuration],
      'sleepRegularity': _sleepRegularityQuestions[_sleepRegularity],
      'screenTime': _screenTimeQuestions[_screenTime],
      'exercise': _exerciseQuestions[_exercise],
      'stress': _stressQuestions[_stress],
      'caffeine': _caffeineQuestions[_caffeine],
    };

    // Create SQI record
    final sqiRecord = SQIRecord(
      recordId: '', // Will be set by Firestore
      userId: widget.userId,
      sqiScore: sqiScore,
      sleepQualityLevel: sleepQualityLevel,
      questionnaireResponses: questionnaireResponses,
      createdAt: DateTime.now(),
    );

    // Save to Firestore
    final recordRef = await _firestore.collection('sqiRecords').add({
      'userId': widget.userId,
      'sqiScore': sqiScore,
      'sleepQualityLevel': sleepQualityLevel,
      'questionnaireResponses': questionnaireResponses,
      'createdAt': DateTime.now(),
    });
    final recordId = recordRef.id;

    // Generate recommendations
    final recommendations = _generateRecommendations(sqiRecord);

    // Save recommendations to Firestore
    for (final recommendation in recommendations) {
      await _firestore.collection('recommendations').add({
        'recordId': recordId,
        'factor': recommendation.factor,
        'title': recommendation.title,
        'description': recommendation.description,
        'action': recommendation.action,
        'priority': recommendation.priority,
      });
    }

    // Navigate to results screen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SQIResultPage(
          sqiRecord: sqiRecord.copyWith(recordId: recordId),
          recommendations: recommendations,
        ),
      ),
    );
  }

  List<Recommendation> _generateRecommendations(SQIRecord sqiRecord) {
    final recommendations = <Recommendation>[];
    final responses = sqiRecord.questionnaireResponses;

    // Generate recommendations based on lowest scoring factors
    if (sqiRecord.sqiScore < 60) {
      // Poor or Fair sleep quality - focus on most critical issues
      if (responses['sleepDuration'] == _sleepDurationQuestions[1]) {
        recommendations.add(Recommendation(
          recommendationId: '',
          recordId: sqiRecord.recordId,
          factor: 'Sleep Duration',
          title: 'Increase Sleep Duration',
          description: 'Getting less than 6 hours of sleep can significantly impact your health and academic performance.',
          action: 'Try to go to bed 30 minutes earlier each night until you reach at least 7 hours of sleep.',
          priority: 'Critical',
        ));
      }

      if (responses['screenTime'] == _screenTimeQuestions[1] || responses['screenTime'] == _screenTimeQuestions[2]) {
        recommendations.add(Recommendation(
          recommendationId: '',
          recordId: sqiRecord.recordId,
          factor: 'Screen Time',
          title: 'Reduce Screen Time Before Bed',
          description: 'Using electronic devices before bed can disrupt your body\'s production of melatonin, making it harder to fall asleep.',
          action: 'Avoid screens for at least 1 hour before bedtime. Try reading a book instead.',
          priority: 'High',
        ));
      }

      if (responses['stress'] == _stressQuestions[1] || responses['stress'] == _stressQuestions[2]) {
        recommendations.add(Recommendation(
          recommendationId: '',
          recordId: sqiRecord.recordId,
          factor: 'Stress',
          title: 'Manage Stress Before Bed',
          description: 'High stress levels can make it difficult to fall asleep and stay asleep.',
          action: 'Try relaxation techniques like deep breathing or meditation before bed.',
          priority: 'High',
        ));
      }
    } else if (sqiRecord.sqiScore < 80) {
      // Good sleep quality - focus on specific areas for improvement
      if (_sleepDuration < 3) {
        recommendations.add(Recommendation(
          recommendationId: '',
          recordId: sqiRecord.recordId,
          factor: 'Sleep Duration',
          title: 'Optimize Sleep Duration',
          description: 'While your sleep duration is good, you might benefit from a bit more sleep.',
          action: 'Try to gradually increase your sleep time by 15-30 minutes.',
          priority: 'Medium',
        ));
      }

      if (_screenTime < 3) {
        recommendations.add(Recommendation(
          recommendationId: '',
          recordId: sqiRecord.recordId,
          factor: 'Screen Time',
          title: 'Reduce Evening Screen Time',
          description: 'Even moderate screen time before bed can affect sleep quality.',
          action: 'Try to reduce screen time in the hour before bed.',
          priority: 'Medium',
        ));
      }
    } else {
      // Excellent sleep quality - positive reinforcement
      recommendations.add(Recommendation(
        recommendationId: '',
        recordId: sqiRecord.recordId,
        factor: 'General',
        title: 'Keep Up the Good Habits!',
        description: 'Your sleep habits are excellent! Maintaining these habits will help you feel rested and perform at your best.',
        action: 'Continue with your current sleep routine and share your good habits with friends.',
        priority: 'Low',
      ));
    }

    // Ensure we don't return more than 3 recommendations
    return recommendations.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Quality Score (SQI)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuestionCard(
                'Sleep Duration',
                _sleepDurationQuestions,
                _sleepDuration,
                (value) => setState(() => _sleepDuration = value),
              ),
              const SizedBox(height: 16),
              _buildQuestionCard(
                'Sleep Regularity',
                _sleepRegularityQuestions,
                _sleepRegularity,
                (value) => setState(() => _sleepRegularity = value),
              ),
              const SizedBox(height: 16),
              _buildQuestionCard(
                'Screen Time',
                _screenTimeQuestions,
                _screenTime,
                (value) => setState(() => _screenTime = value),
              ),
              const SizedBox(height: 16),
              _buildQuestionCard(
                'Exercise',
                _exerciseQuestions,
                _exercise,
                (value) => setState(() => _exercise = value),
              ),
              const SizedBox(height: 16),
              _buildQuestionCard(
                'Stress',
                _stressQuestions,
                _stress,
                (value) => setState(() => _stress = value),
              ),
              const SizedBox(height: 16),
              _buildQuestionCard(
                'Caffeine',
                _caffeineQuestions,
                _caffeine,
                (value) => setState(() => _caffeine = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitQuestionnaire,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Calculate SQI',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    String title,
    List<String> questions,
    int selectedValue,
    ValueChanged<int> onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questions[0], // First element is the question
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(questions.length - 1, (index) {
              return RadioListTile<int>(
                title: Text(questions[index + 1]), // Options start from index 1
                value: index + 1, // Values start from 1 (0 is reserved for unselected)
                groupValue: selectedValue,
                onChanged: (value) {
                  onChanged(value!);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class SQIResultScreen extends StatelessWidget {
  final SQIRecord sqiRecord;
  final List<Recommendation> recommendations;

  const SQIResultScreen({
    super.key,
    required this.sqiRecord,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQI Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Your SQI Score',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${sqiRecord.sqiScore}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sleep Quality: ${sqiRecord.sleepQualityLevel}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(sqiRecord.sleepQualityLevel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommendations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.map((recommendation) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Card(
                          color: _getPriorityColor(recommendation.priority),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recommendation.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(recommendation.description),
                                const SizedBox(height: 4),
                                Text(
                                  'Action: ${recommendation.action}',
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Fair':
        return Colors.orange;
      case 'Poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red[50]!;
      case 'High':
        return Colors.orange[50]!;
      case 'Medium':
        return Colors.yellow[50]!;
      case 'Low':
        return Colors.green[50]!;
      default:
        return Colors.grey[50]!;
    }
  }
}

extension on SQIRecord {
  SQIRecord copyWith({String? recordId}) {
    return SQIRecord(
      recordId: recordId ?? this.recordId,
      userId: this.userId,
      sqiScore: this.sqiScore,
      sleepQualityLevel: this.sleepQualityLevel,
      questionnaireResponses: this.questionnaireResponses,
      createdAt: this.createdAt,
    );
  }
}
