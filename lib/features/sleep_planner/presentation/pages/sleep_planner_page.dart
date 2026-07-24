import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../data/repositories/sleep_planner_repository.dart';
import '../../domain/usecases/calculate_sleep_plan.dart';

class SleepPlannerPage extends StatefulWidget {
  const SleepPlannerPage({super.key});

  @override
  State<SleepPlannerPage> createState() => _SleepPlannerPageState();
}

class _SleepPlannerPageState extends State<SleepPlannerPage> {
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  final _planner = CalculateSleepPlan();
  final _plannerRepository = FirestoreSleepPlannerRepository();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final result = _submitted ? _planner.call(wakeUpTime: _wakeUpTime) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Planner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wake-up time'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickWakeUpTime,
              child: Text(_wakeUpTime.format(context)),
            ),
            const SizedBox(height: 16),
            const Text('Daily constraints (optional)'),
            const SizedBox(height: 8),
            const Text('Homework, projects, tutoring, late arrival, personal activities'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _submitted = true;
                });

                final plan = _planner.call(wakeUpTime: _wakeUpTime);
                await _plannerRepository.savePlan(
                  {
                    'userId': 'local-user',
                    'wakeUpTime': _wakeUpTime.format(context),
                    'sleepCycles': plan.sleepCycles,
                    'sleepDuration': plan.sleepDuration,
                    'suggestedBedtimes': plan.suggestedBedtimes,
                    'createdAt': DateTime.now().toIso8601String(),
                  },
                );
                await appStorage?.saveHistoryEntry(
                  'planner_history',
                  {
                    'title': 'Sleep Planner Result',
                    'subtitle': 'Wake-up ${_wakeUpTime.format(context)} · ${plan.suggestedBedtimes.length} options',
                    'dateLabel': DateTime.now().toIso8601String(),
                  },
                );
              },
              child: const Text('Calculate'),
            ),
            if (result != null) ...[
              const SizedBox(height: 24),
              Text('Sleep cycles: ${result.sleepCycles}'),
              Text('Sleep duration: ${result.sleepDuration}'),
              const SizedBox(height: 12),
              const Text('Suggested bedtimes:'),
              for (final bedtime in result.suggestedBedtimes)
                Text('- $bedtime'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickWakeUpTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeUpTime,
    );

    if (picked != null) {
      setState(() {
        _wakeUpTime = picked;
      });
    }
  }
}
