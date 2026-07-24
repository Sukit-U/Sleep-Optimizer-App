import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/sleep_plan_model.dart';

class SleepPlannerScreen extends StatefulWidget {
  final String userId;

  const SleepPlannerScreen({super.key, required this.userId});

  @override
  State<SleepPlannerScreen> createState() => _SleepPlannerScreenState();
}

class _SleepPlannerScreenState extends State<SleepPlannerScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime? _wakeUpTime;
  final List<String> _constraints = [
    'Homework',
    'School projects',
    'Tutoring',
    'Late arrival home',
    'Personal activities'
  ];
  final List<bool> _selectedConstraints = List.filled(5, false);

  Future<void> _selectWakeUpTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _wakeUpTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _calculateSleepPlan() async {
    if (_wakeUpTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wake-up time')),
      );
      return;
    }

    // Calculate sleep cycles (90 minutes each)
    final now = DateTime.now();
    final durationToWakeUp = _wakeUpTime!.difference(now);
    final totalMinutes = durationToWakeUp.inMinutes;
    final sleepCycles = (totalMinutes / 90).floor();

    // Calculate suggested bedtimes (3 options)
    final suggestedBedtimes = List.generate(3, (index) {
      final bedtime = _wakeUpTime!.subtract(Duration(minutes: 90 * (sleepCycles - index)));
      return DateFormat('hh:mm a').format(bedtime);
    });

    // Create sleep plan
    final sleepPlan = SleepPlan(
      planId: '', // Will be set by Firestore
      userId: widget.userId,
      wakeUpTime: _wakeUpTime!,
      createdAt: now,
      sleepCycles: sleepCycles,
      suggestedBedtimes: suggestedBedtimes,
    );

    // Save to Firestore
    final planId = await _firestoreService.addSleepPlan(sleepPlan);

    // Navigate to results screen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SleepPlannerResultScreen(
          sleepPlan: sleepPlan.copyWith(planId: planId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Planner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wake-up Time',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _selectWakeUpTime(context),
                      child: Text(
                        _wakeUpTime == null
                            ? 'Select Time'
                            : DateFormat('hh:mm a').format(_wakeUpTime!),
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
                      'Daily Constraints',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_constraints.length, (index) {
                      return CheckboxListTile(
                        title: Text(_constraints[index]),
                        value: _selectedConstraints[index],
                        onChanged: (value) {
                          setState(() {
                            _selectedConstraints[index] = value!;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculateSleepPlan,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Calculate',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SleepPlannerResultScreen extends StatelessWidget {
  final SleepPlan sleepPlan;

  const SleepPlannerResultScreen({super.key, required this.sleepPlan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Plan Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wake-up Time',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('hh:mm a').format(sleepPlan.wakeUpTime),
                      style: const TextStyle(fontSize: 24),
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
                      'Suggested Bedtimes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...sleepPlan.suggestedBedtimes.map((bedtime) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          bedtime,
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    }).toList(),
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
                      'Sleep Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sleep Cycles: ${sleepPlan.sleepCycles}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Sleep Duration: ${sleepPlan.sleepCycles * 90} minutes',
                      style: const TextStyle(fontSize: 16),
                    ),
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
}

extension on SleepPlan {
  SleepPlan copyWith({String? planId}) {
    return SleepPlan(
      planId: planId ?? this.planId,
      userId: userId,
      wakeUpTime: wakeUpTime,
      createdAt: createdAt,
      sleepCycles: sleepCycles,
      suggestedBedtimes: suggestedBedtimes,
    );
  }
}